#!/usr/bin/env bash
# init-project.sh: install the 3-level agent harness into a project.
# Asks for anything not passed as a flag. Runs on macOS, Linux and Git Bash on Windows.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: init-project.sh [options]

Run with no options to answer questions interactively. Any option you pass
skips its question.

  --project <path>         Project repo to set up
  --name <name>            Project name
  --kit <stack>            Stack kit folder under kits/ (e.g. spring-boot)
  --client <name>          Client name
  --lead <name>            Project lead
  --division <file>        Filled DIVISION.md for the project's division
  --division-name <name>   Division name (read from --division if omitted)
  --mode <in-repo|external>
                           in-repo: files go into the project repo (default
                           when the client allows it).
                           external: files stay in this harness repo under
                           projects/<name>/; the project gets an untracked
                           CLAUDE.local.md that imports them.
  --ci <name>              CI template to add: github, gitlab, azure, jenkins,
                           bitbucket, circleci, or none
  --force                  Overwrite the project's rules and CLAUDE.md
  -h, --help               Show this help

Without a terminal (e.g. in CI) every value must come from flags, and the
project's AI policy record must already be approved.
EOF
}

die()     { printf '\nerror: %s\n' "$*" >&2; exit 1; }
info()    { printf '  %s\n' "$*"; }
section() { printf '\n== %s ==\n' "$*"; }

# ---- arguments --------------------------------------------------------------
PROJECT="" NAME="" KIT="" CLIENT="" LEAD="" DIVISION_FILE="" DIVISION_NAME=""
MODE="" FORCE=0 DIVISION_ASKED=0 CI=""

while [ $# -gt 0 ]; do
  case "$1" in
    --project)       PROJECT="${2:-}"; shift 2 ;;
    --name)          NAME="${2:-}"; shift 2 ;;
    --kit)           KIT="${2:-}"; shift 2 ;;
    --client)        CLIENT="${2:-}"; shift 2 ;;
    --lead)          LEAD="${2:-}"; shift 2 ;;
    --division)      DIVISION_FILE="${2:-}"; DIVISION_ASKED=1; shift 2 ;;
    --division-name) DIVISION_NAME="${2:-}"; shift 2 ;;
    --mode)          MODE="${2:-}"; shift 2 ;;
    --ci)            CI="${2:-}"; shift 2 ;;
    --force)         FORCE=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *)               usage >&2; die "unknown option: $1" ;;
  esac
done
case "$MODE" in ""|in-repo|external) ;; *) die "--mode must be in-repo or external" ;; esac
case "$CI" in ""|github|gitlab|azure|jenkins|bitbucket|circleci|none) ;;
  *) die "--ci must be one of: github, gitlab, azure, jenkins, bitbucket, circleci, none" ;; esac

# HARNESS_INTERACTIVE=1 forces question mode with piped input (used for testing).
INTERACTIVE=0
{ [ -t 0 ] || [ "${HARNESS_INTERACTIVE:-}" = 1 ]; } && INTERACTIVE=1

HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEVEL1="$HARNESS_ROOT/level1-company/AGENTS.md"
TPL_DIR="$HARNESS_ROOT/level3-project"
TODAY="$(date +%Y-%m-%d)"
[ -f "$LEVEL1" ] || die "Level 1 file not found: $LEVEL1"

# ---- question helpers -------------------------------------------------------
read_line() { # read_line <prompt> -> sets REPLY_LINE
  printf '%s' "$1" >&2
  IFS= read -r REPLY_LINE || die "input ended before all questions were answered"
}

# ask <var> <question> [default]   (skipped if <var> is already set by a flag)
ask() {
  local var="$1" q="$2" def="${3:-}"
  [ -n "${!var:-}" ] && return 0
  [ "$INTERACTIVE" -eq 1 ] || die "missing value: $q (run in a terminal, or pass it as a flag)"
  if [ -n "$def" ]; then read_line "$q [$def]: "; else read_line "$q: "; fi
  printf -v "$var" '%s' "${REPLY_LINE:-$def}"
}

# ask_required <var> <question> [default]
ask_required() {
  while :; do
    ask "$1" "$2" "${3:-}"
    [ -n "${!1:-}" ] && return 0
    printf '  An answer is required.\n' >&2
  done
}

# ask_yn <var> <question> <y|n|"" default>   -> sets <var> to y or n ("" = no default)
ask_yn() {
  local var="$1" q="$2" def="$3" hint="y/N"
  [ "$def" = y ] && hint="Y/n"
  [ -z "$def" ] && hint="y/n"
  [ "$INTERACTIVE" -eq 1 ] || die "missing answer: $q (run in a terminal)"
  while :; do
    read_line "$q ($hint): "
    case "$(printf '%s' "${REPLY_LINE:-$def}" | tr '[:upper:]' '[:lower:]')" in
      y|yes) printf -v "$var" y; return 0 ;;
      n|no)  printf -v "$var" n; return 0 ;;
      *)     printf '  Please answer y or n.\n' >&2 ;;
    esac
  done
}

# choose <var> <question> <option>...   (skipped if <var> is already set)
choose() {
  local var="$1" q="$2"; shift 2
  [ -n "${!var:-}" ] && return 0
  if [ $# -eq 1 ]; then printf -v "$var" '%s' "$1"; info "$q: $1 (only option)"; return 0; fi
  [ "$INTERACTIVE" -eq 1 ] || die "missing value: $q (run in a terminal, or pass it as a flag)"
  printf '%s\n' "$q" >&2
  local i=1 opt
  for opt in "$@"; do printf '  %d) %s\n' "$i" "$opt" >&2; i=$((i + 1)); done
  while :; do
    read_line "Choose 1-$#: "
    if [[ "$REPLY_LINE" =~ ^[0-9]+$ ]] && [ "$REPLY_LINE" -ge 1 ] && [ "$REPLY_LINE" -le $# ]; then
      printf -v "$var" '%s' "${!REPLY_LINE}"; return 0
    fi
    printf '  Enter a number from the list.\n' >&2
  done
}

# ---- other helpers ----------------------------------------------------------
esc_pat() { printf '%s' "$1" | sed -e 's/[]\/$*.^[|]/\\&/g'; }
esc_rep() { printf '%s' "$1" | sed -e 's/[\/&|]/\\&/g'; }

# render <template> <output> [placeholder value]...  (empty values keep the placeholder)
render() {
  local tpl="$1" out="$2"; shift 2
  local args=(-e 's/a/a/')
  while [ $# -ge 2 ]; do
    [ -n "$2" ] && args+=(-e "s|$(esc_pat "$1")|$(esc_rep "$2")|g")
    shift 2
  done
  sed "${args[@]}" "$tpl" > "$out"
}

version_of() { sed -n 's/^Version: \([^ ]*\).*/\1/p' "$1" | head -n 1; }
cell()       { printf '%s' "$1" | tr '|\n' '/ '; }   # keep answers from breaking the table
import_path() {
  local p="$1"
  command -v cygpath >/dev/null 2>&1 && p="$(cygpath -m "$p")"
  printf '%s' "$p" | sed 's/ /\\ /g'
}

# ---- 1. project -------------------------------------------------------------
section "Project"

while :; do
  ask_required PROJECT "Project folder" "$(pwd)"
  [ -d "$PROJECT" ] && break
  [ "$INTERACTIVE" -eq 1 ] || die "project folder not found: $PROJECT"
  printf '  Folder not found: %s\n' "$PROJECT" >&2; PROJECT=""
done
PROJECT="$(cd "$PROJECT" && pwd)"

ask_required NAME "Project name" "$(basename "$PROJECT")"

SLUG="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//')"
[ -n "$SLUG" ] || die "project name must contain letters or digits"
RECORD_DIR="$HARNESS_ROOT/projects/$SLUG"
POLICY="$RECORD_DIR/AI-POLICY.md"
if [ -f "$POLICY" ] && grep -Eq '^- \[[xX]\] \*\*Excluded:\*\*' "$POLICY"; then
  echo "The client forbids AI. $NAME is excluded from the harness; nothing was installed."
  echo "Record: $POLICY"
  exit 3
fi

ask_required CLIENT "Client name"
ask_required LEAD "Project lead (signs off the AI policy)"

# Kits are folders under kits/ with an AGENTS.md; folders starting with "_" are templates.
KITS=()
for d in "$HARNESS_ROOT"/kits/*/; do
  k="$(basename "$d")"
  case "$k" in _*) continue ;; esac
  [ -f "$d/AGENTS.md" ] && KITS+=("$k")
done
[ ${#KITS[@]} -gt 0 ] || die "no stack kits yet. Copy kits/_template/ to kits/<your-stack>/, fill it in, then run this script again."
choose KIT "Stack kit" "${KITS[@]}"
case " ${KITS[*]} " in *" $KIT "*) ;; *) die "no kit \"$KIT\"; available: ${KITS[*]}" ;; esac
KIT_FILE="$HARNESS_ROOT/kits/$KIT/AGENTS.md"
grep -q '<Stack name>' "$KIT_FILE" && die "kits/$KIT/AGENTS.md is still the blank template; fill it in first"

if [ "$DIVISION_ASKED" -eq 0 ] && [ "$INTERACTIVE" -eq 1 ]; then
  while :; do
    read_line "Path to the division's filled DIVISION.md (blank to skip): "
    DIVISION_FILE="$REPLY_LINE"
    [ -z "$DIVISION_FILE" ] && break
    if [ ! -f "$DIVISION_FILE" ]; then printf '  File not found.\n' >&2
    elif grep -q '<Division name>' "$DIVISION_FILE"; then printf '  That is still the blank template.\n' >&2
    else break; fi
  done
fi
if [ -n "$DIVISION_FILE" ]; then
  [ -f "$DIVISION_FILE" ] || die "division file not found: $DIVISION_FILE"
  grep -q '<Division name>' "$DIVISION_FILE" && die "division file is still the blank template: $DIVISION_FILE"
  if [ -z "$DIVISION_NAME" ]; then
    DIVISION_NAME="$(sed -n 's/^# Division rules (Level 2): *//p' "$DIVISION_FILE" | head -n 1)"
    [ -n "$DIVISION_NAME" ] && info "Division: $DIVISION_NAME (from the division file)"
  fi
fi
[ "$INTERACTIVE" -eq 1 ] && ask DIVISION_NAME "Division name (blank if none)" "${DIVISION_NAME:-}"

# ---- 2. AI policy -----------------------------------------------------------
section "AI policy"

write_policy() { # write_policy <approved y|n> <excluded y|n>
  local a=" " e=" " date="<pending>"
  [ "$1" = y ] && { a="x"; date="$TODAY"; }
  [ "$2" = y ] && { e="x"; date="$TODAY"; }
  mkdir -p "$RECORD_DIR"
  cat > "$POLICY" <<EOF
# AI policy record: $NAME

Client: $CLIENT · Division: ${DIVISION_NAME:-<Division>} · Signed off by: $LEAD · Date: $date

No agent touches client code until this record is complete and signed off. Re-check it when the contract or client policy changes.

## Answers

| Question | Answer | Source |
| --- | --- | --- |
| Does the client allow AI coding tools at all? | $(cell "$P_ALLOW") | $(cell "$P_SOURCE") |
| Which tools are allowed? | $(cell "$P_TOOLS") | $(cell "$P_SOURCE") |
| May client code be sent to external AI services? | $(cell "$P_EXTERNAL") | $(cell "$P_SOURCE") |
| Data-residency or hosting limits? | $(cell "$P_RESIDENCY") | $(cell "$P_SOURCE") |
| May agent files (AGENTS.md, CLAUDE.md) live in the client repo? | $(cell "$P_FILES") | $(cell "$P_SOURCE") |
| Must agent-assisted work be disclosed or labelled? | $(cell "$P_DISCLOSE") | $(cell "$P_SOURCE") |
| Domain rules stricter than the division's? | $(cell "$P_DOMAIN") | $(cell "$P_SOURCE") |

## Result

- [$a] **Approved:** agents may be used within the answers above. Continue with the project AGENTS.md.
- [$e] **Excluded:** the client forbids AI. This project is outside the harness and no agents are used.
EOF
}

policy_answer() { # policy_answer <question start> -> prints the Answer cell
  awk -F'|' -v q="$1" 'index($2, q) { gsub(/^ +| +$/, "", $3); print $3; exit }' "$POLICY"
}

if [ -f "$POLICY" ]; then
  info "Using the existing record: $POLICY"
else
  echo "Answer from the contract, NDA or client emails. These answers become the project's AI policy record."
  ask_yn P_ALLOW_YN "Does the client allow AI coding tools at all?" ""
  P_ALLOW="no"; [ "$P_ALLOW_YN" = y ] && P_ALLOW="yes"
  ask_required P_SOURCE "Where do these answers come from (contract clause, NDA, email)?"
  if [ "$P_ALLOW_YN" = n ]; then
    P_TOOLS="none" P_EXTERNAL="no" P_RESIDENCY="n/a" P_FILES="no" P_DISCLOSE="n/a" P_DOMAIN="n/a"
    write_policy n y
    echo
    echo "The client forbids AI. Recorded $NAME as excluded: $POLICY"
    echo "Nothing was installed."
    exit 3
  fi
  ask_required P_TOOLS "Which AI tools are allowed?" "Claude Code"
  ask_required P_EXTERNAL "May client code be sent to external AI services? (yes / no / only <service>)" "yes"
  ask_required P_RESIDENCY "Data-residency or hosting limits?" "none"
  ask_yn P_FILES_YN "May agent files (AGENTS.md, CLAUDE.md) live in the client repo?" ""
  P_FILES="no"; [ "$P_FILES_YN" = y ] && P_FILES="yes"
  ask_required P_DISCLOSE "Must agent-assisted work be disclosed or labelled? (yes / no / per PR)" "yes"
  ask_required P_DOMAIN "Domain rules stricter than the division's?" "none"
  write_policy n n
  info "Record written: $POLICY"
fi

if grep -Eq '^- \[[xX]\] \*\*Excluded:\*\*' "$POLICY"; then
  echo "The client forbids AI. $NAME is excluded from the harness; nothing was installed."
  exit 3
fi
if ! grep -Eq '^- \[[xX]\] \*\*Approved:\*\*' "$POLICY"; then
  [ "$INTERACTIVE" -eq 1 ] || die "the AI policy record is not approved yet: $POLICY"
  ask_yn SIGNED "Has $LEAD reviewed and signed off this record?" n
  if [ "$SIGNED" = n ]; then
    echo
    echo "Stopped before installing. Get the record signed off, then run this script again:"
    echo "  $POLICY"
    exit 2
  fi
  sed -e 's/^- \[ \] \*\*Approved:\*\*/- [x] **Approved:**/' -e "s/Date: <pending>/Date: $TODAY/" "$POLICY" > "$POLICY.tmp"
  mv "$POLICY.tmp" "$POLICY"
  info "Record approved."
fi

# The policy decides whether files may live in the client repo.
FILES_ALLOWED="$(policy_answer 'May agent files' | tr '[:upper:]' '[:lower:]')"
case "$FILES_ALLOWED" in
  y*) [ -z "$MODE" ] && MODE="in-repo" ;;
  *)  [ "$MODE" = "in-repo" ] && die "the AI policy record does not allow agent files in the client repo; use --mode external"
      MODE="external" ;;
esac

# CI checks need files in the client repo, so they only apply in in-repo mode.
if [ "$MODE" = "external" ]; then
  [ -n "$CI" ] && [ "$CI" != none ] && info "CI checks skipped: external mode keeps all harness files out of the client repo."
  CI="none"
elif [ -z "$CI" ]; then
  if [ "$INTERACTIVE" -eq 1 ]; then
    choose CI_LABEL "Which CI runs this project's pull requests?" \
      "GitHub Actions" "GitLab CI" "Azure Pipelines" "Jenkins" "Bitbucket Pipelines" "CircleCI" "None or decide later"
    case "$CI_LABEL" in
      "GitHub Actions") CI=github ;; "GitLab CI") CI=gitlab ;; "Azure Pipelines") CI=azure ;;
      "Jenkins") CI=jenkins ;; "Bitbucket Pipelines") CI=bitbucket ;; "CircleCI") CI=circleci ;; *) CI=none ;;
    esac
  else
    CI="none"
  fi
fi

# ---- 3. confirm -------------------------------------------------------------
section "Summary"
info "Project:   $NAME  ($PROJECT)"
info "Client:    $CLIENT"
info "Lead:      $LEAD"
info "Division:  ${DIVISION_NAME:-none}${DIVISION_FILE:+  ($DIVISION_FILE)}"
info "Stack kit: $KIT $(version_of "$KIT_FILE")"
info "Mode:      $MODE"
info "CI:        $CI"
if [ "$INTERACTIVE" -eq 1 ]; then
  ask_yn GO "Install the harness?" y
  [ "$GO" = y ] || { echo "Cancelled; nothing was installed."; exit 0; }
fi

# ---- 4. install the levels --------------------------------------------------
section "Install"
if [ "$MODE" = "in-repo" ]; then DEST="$PROJECT"; else DEST="$RECORD_DIR"; fi
H="$DEST/.harness"

mkdir -p "$H/level1" "$H/kit" "$H/project" "$H/checks"
cp "$LEVEL1" "$H/level1/AGENTS.md";  info "Level 1     .harness/level1/AGENTS.md"
cp "$KIT_FILE" "$H/kit/AGENTS.md";   info "Stack kit   .harness/kit/AGENTS.md ($KIT)"
rm -rf "$H/kit/checks"
if [ -d "$HARNESS_ROOT/kits/$KIT/checks" ]; then
  cp -R "$HARNESS_ROOT/kits/$KIT/checks" "$H/kit/checks"
  info "Kit checks  .harness/kit/checks/ (linter configs and architecture tests to adopt)"
fi
if [ -n "$DIVISION_FILE" ]; then
  mkdir -p "$H/division"
  cp "$DIVISION_FILE" "$H/division/DIVISION.md"; info "Level 2     .harness/division/DIVISION.md"
elif [ -f "$H/division/DIVISION.md" ]; then
  info "Level 2     kept the installed division file"
else
  info "Level 2     skipped (no division file)"
fi
cp "$HARNESS_ROOT/scripts/build-agents-md.sh" "$HARNESS_ROOT/scripts/build-agents-md.ps1" "$H/"
cp "$HARNESS_ROOT/checks/protected-tests.sh" "$H/checks/protected-tests.sh"
info "Scripts     .harness/build-agents-md.sh (.ps1), .harness/checks/protected-tests.sh"

HARNESS_VERSION="unversioned"
if git -C "$HARNESS_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  HARNESS_VERSION="$(git -C "$HARNESS_ROOT" describe --tags --always --dirty 2>/dev/null || echo unversioned)"
fi
KIT_VERSION="$(version_of "$KIT_FILE")"
DIV_VERSION="none"
[ -n "$DIVISION_FILE" ] && DIV_VERSION="$(version_of "$DIVISION_FILE")"
cat > "$H/harness.lock" <<EOF
# Versions installed by init-project.sh. Upgrade by re-running it on purpose.
harness: $HARNESS_VERSION
level1: $(version_of "$LEVEL1")
division: ${DIV_VERSION:-unversioned}
kit: $KIT $KIT_VERSION
ci: $CI
installed: $TODAY
EOF
info "Lock file   .harness/harness.lock"

is_generated() { [ -f "$1" ] && head -n 1 "$1" | grep -qF '<!-- GENERATED by build-agents-md.sh'; }

# Project rules live in .harness/project/AGENTS.md; the root AGENTS.md is generated.
PROJECT_RULES="$H/project/AGENTS.md"
if [ -f "$DEST/AGENTS.md" ] && ! is_generated "$DEST/AGENTS.md"; then
  [ -f "$PROJECT_RULES" ] && die "both AGENTS.md and .harness/project/AGENTS.md exist in $DEST. Merge AGENTS.md into the project rules file, delete AGENTS.md, then run this script again."
  mv "$DEST/AGENTS.md" "$PROJECT_RULES"
  info "Project     moved the existing AGENTS.md to .harness/project/AGENTS.md"
fi
if [ -f "$PROJECT_RULES" ] && [ "$FORCE" -eq 0 ]; then
  info "Project     kept .harness/project/AGENTS.md"
else
  render "$TPL_DIR/AGENTS.template.md" "$PROJECT_RULES" \
    '<Project name>' "$NAME" '<kit name>' "$KIT" '<x.y.z>' "$KIT_VERSION" '<Project lead>' "$LEAD"
  info "Project     .harness/project/AGENTS.md created from template; fill it in"
fi

bash "$H/build-agents-md.sh" "$DEST" >/dev/null
info "AGENTS.md   generated from all levels (read by every agent)"

# CLAUDE.md only needs to import the generated AGENTS.md.
if [ ! -f "$DEST/CLAUDE.md" ] || [ "$FORCE" -eq 1 ] || grep -qF '@.harness/level1/AGENTS.md' "$DEST/CLAUDE.md"; then
  cp "$TPL_DIR/CLAUDE.template.md" "$DEST/CLAUDE.md"
  info "CLAUDE.md   imports AGENTS.md"
elif grep -qxF '@AGENTS.md' "$DEST/CLAUDE.md"; then
  info "CLAUDE.md   kept existing file (already imports AGENTS.md)"
else
  printf '\n@AGENTS.md\n' >> "$DEST/CLAUDE.md"
  info "CLAUDE.md   kept your content and added an import of AGENTS.md at the end"
fi

# CI template for the protected-test and AGENTS.md checks.
CI_NEXT=""
case "$CI" in
  github)
    mkdir -p "$DEST/.github/workflows"
    if [ -f "$DEST/.github/workflows/agent-harness.yml" ] && [ "$FORCE" -eq 0 ]; then
      info "CI          kept .github/workflows/agent-harness.yml"
    else
      cp "$HARNESS_ROOT/ci/github-actions.yml" "$DEST/.github/workflows/agent-harness.yml"
      info "CI          .github/workflows/agent-harness.yml"
    fi
    CI_NEXT="Create the 'test-change-approved' label in GitHub, and make the 'agent-harness' check required on your main branch." ;;
  gitlab)    CI_SRC="gitlab-ci.yml"
    CI_NEXT="Add to .gitlab-ci.yml:  include: { local: '.harness/ci/gitlab-ci.yml' }" ;;
  azure)     CI_SRC="azure-pipelines.yml"
    CI_NEXT="Create a pipeline from .harness/ci/azure-pipelines.yml and add it as a build validation policy on your main branch." ;;
  jenkins)   CI_SRC="Jenkinsfile.groovy"
    CI_NEXT="Copy the stage from .harness/ci/Jenkinsfile.groovy into your Jenkinsfile." ;;
  bitbucket) CI_SRC="bitbucket-pipelines.yml"
    CI_NEXT="Merge .harness/ci/bitbucket-pipelines.yml into the pull-requests section of your bitbucket-pipelines.yml." ;;
  circleci)  CI_SRC="circleci-config.yml"
    CI_NEXT="Merge the job and workflow from .harness/ci/circleci-config.yml into .circleci/config.yml." ;;
esac
case "$CI" in gitlab|azure|jenkins|bitbucket|circleci)
  mkdir -p "$H/ci"
  cp "$HARNESS_ROOT/ci/$CI_SRC" "$H/ci/$CI_SRC"
  info "CI          .harness/ci/$CI_SRC" ;;
esac

# External mode: link the project without committing anything to it.
if [ "$MODE" = "external" ]; then
  IMPORT_LINE="@$(import_path "$DEST/CLAUDE.md")"
  LOCAL="$PROJECT/CLAUDE.local.md"
  if [ -f "$LOCAL" ] && grep -qxF "$IMPORT_LINE" "$LOCAL"; then
    info "CLAUDE.local.md already imports the harness"
  else
    [ -f "$LOCAL" ] || printf '# Local agent harness (not committed)\n\n' > "$LOCAL"
    printf '%s\n' "$IMPORT_LINE" >> "$LOCAL"
    info "CLAUDE.local.md imports $DEST/CLAUDE.md"
  fi
  if git -C "$PROJECT" rev-parse --git-dir >/dev/null 2>&1; then
    EXCLUDE="$(git -C "$PROJECT" rev-parse --git-path info/exclude)"
    case "$EXCLUDE" in /*|[A-Za-z]:*) ;; *) EXCLUDE="$PROJECT/$EXCLUDE" ;; esac
    mkdir -p "$(dirname "$EXCLUDE")"
    if grep -qxF 'CLAUDE.local.md' "$EXCLUDE" 2>/dev/null; then
      info "git         CLAUDE.local.md already in .git/info/exclude"
    else
      printf 'CLAUDE.local.md\n' >> "$EXCLUDE"
      info "git         CLAUDE.local.md added to .git/info/exclude"
    fi
  else
    info "warning     project is not a git repo; make sure CLAUDE.local.md is never committed"
  fi
fi

echo
echo "Done. Next:"
echo "  - Fill in $H/project/AGENTS.md (commands, client conventions, boundaries),"
echo "    then regenerate AGENTS.md: bash $H/build-agents-md.sh"
echo "  - Open Claude Code in $PROJECT and run /memory to check AGENTS.md is loaded."
if [ "$MODE" = "external" ]; then
  echo "    Claude Code asks once to approve the import from outside the project; approve it."
else
  [ -n "$CI_NEXT" ] && echo "  - CI: $CI_NEXT"
  [ -d "$H/kit/checks" ] && echo "  - Adopt the kit's checks from .harness/kit/checks/ (see its README)."
  echo "  - Commit .harness/, AGENTS.md, CLAUDE.md and any CI file in one PR for review."
fi
exit 0
