#!/usr/bin/env bash
# protected-tests.sh: fail a pull request that deletes, skips or weakens tests.
#
# Usage: protected-tests.sh [--base <branch-or-commit>]
#
# Finds the pull request's base automatically on GitHub Actions, GitLab CI,
# Azure Pipelines, Jenkins and Bitbucket Pipelines. Elsewhere (e.g. CircleCI),
# set BASE_BRANCH or pass --base. Outside a pull request it does nothing.
#
# It reports, for test files only:
#   - deleted test files, or test files moved out of test folders
#   - new skip, ignore or focus markers (e.g. @Disabled, [Ignore], it.skip, it.only, t.Skip)
#   - files where more assertion lines were removed than added
#   - new trivial assertions (e.g. assertTrue(true), expect(true).toBe(true))
#
# A reviewer approves an intended change by:
#   - GitHub / GitLab: adding the label "test-change-approved" (or $APPROVAL_LABEL)
#   - any CI: re-running with the variable ALLOW_TEST_CHANGES=true
# Exit codes: 0 pass or approved, 1 findings, 2 setup error.
set -euo pipefail

APPROVAL_LABEL="${APPROVAL_LABEL:-test-change-approved}"
BASE_INPUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE_INPUT="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

# ---- find the base of the pull request ---------------------------------------
if [ -z "$BASE_INPUT" ]; then
  BASE_INPUT="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-}"                       # GitLab
  [ -z "$BASE_INPUT" ] && BASE_INPUT="${GITHUB_BASE_REF:-}"              # GitHub Actions
  [ -z "$BASE_INPUT" ] && BASE_INPUT="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}"
  [ -z "$BASE_INPUT" ] && BASE_INPUT="${SYSTEM_PULLREQUEST_TARGETBRANCH:-}" # Azure Pipelines
  [ -z "$BASE_INPUT" ] && BASE_INPUT="${CHANGE_TARGET:-}"                # Jenkins
  [ -z "$BASE_INPUT" ] && BASE_INPUT="${BITBUCKET_PR_DESTINATION_BRANCH:-}" # Bitbucket
  [ -z "$BASE_INPUT" ] && BASE_INPUT="${BASE_BRANCH:-}"                  # anything else
fi
if [ -z "$BASE_INPUT" ]; then
  echo "protected-tests: not a pull request build (no base branch found); nothing to check."
  exit 0
fi
BASE_INPUT="${BASE_INPUT#refs/heads/}"

git rev-parse --git-dir >/dev/null 2>&1 || { echo "protected-tests: not inside a git repository" >&2; exit 2; }
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo false)" = true ]; then
  git fetch --quiet --no-tags --unshallow origin 2>/dev/null || true
fi

resolve_ref() {
  local b="$1"
  if git rev-parse --verify -q "$b^{commit}" >/dev/null; then printf '%s' "$b"; return 0; fi
  if git rev-parse --verify -q "origin/$b^{commit}" >/dev/null; then printf '%s' "origin/$b"; return 0; fi
  git fetch --quiet --no-tags origin "+refs/heads/$b:refs/remotes/origin/$b" 2>/dev/null || return 1
  printf '%s' "origin/$b"
}
BASE_REF="$(resolve_ref "$BASE_INPUT")" || { echo "protected-tests: cannot find base '$BASE_INPUT'. Fetch full history in CI, or pass --base." >&2; exit 2; }
BASE="$(git merge-base HEAD "$BASE_REF")" || { echo "protected-tests: no common history with '$BASE_REF'. Fetch full history in CI." >&2; exit 2; }

# ---- what counts as a test --------------------------------------------------
TEST_PATH='(^|/)(tests?|__tests__|specs?|androidTest|[^/]*Tests?)/|(Tests?|_test|\.test|\.spec)\.[A-Za-z]+$|(^|/)test_[^/]*\.py$'
IGNORE_PATH='(^|/)(node_modules|vendor|\.harness|build|dist|Pods)/'

# Markers that stop tests from running, by language.
# Word boundaries are spelled out (B = before, E = after) instead of \b, which
# BSD grep on macOS does not guarantee.
B='(^|[^A-Za-z0-9_.])'
E='([^A-Za-z0-9_]|$)'
SKIP_RE="@Disabled$E|@Ignore$E|\[Ignore|\[Explicit|Skip *= *\"|pytest\.mark\.(skip|skipif|xfail)|unittest\.skip|pytest\.skip\(|@skip$E"
SKIP_RE+="|$B(it|test|describe|context|suite)\.(skip|only|todo)\(|$B(xit|xtest|xdescribe|xcontext|fit|fdescribe)\("
SKIP_RE+="|${B}t\.Skip(f|Now)?\(|markTestSkipped\(|markTestIncomplete\(|->skip\(|->todo\(|skip: *(true|'|\")|XCTSkip|\.disabled\("

ASSERT_RE="[Aa]ssert|expect\(|\.Should\(|${B}Should\.|${B}require\.|${B}t\.(Error|Errorf|Fatal|Fatalf)\(|${B}verify\("
TRIVIAL_RE="assert(True)?\( *true *\)|assertTrue\( *true *\)|Assert\.(True|IsTrue)\( *true *\)|assert +True$E|expect\( *true *\)\.(toBe|toEqual)\( *true *\)|XCTAssertTrue\( *true *\)|expect\( *true *, *(isTrue|true) *\)"

is_test() { printf '%s' "$1" | grep -Eq "$TEST_PATH" && ! printf '%s' "$1" | grep -Eq "$IGNORE_PATH"; }
count() { grep -Ec "$1" || true; }

FINDINGS=()
add() { FINDINGS+=("$1"); }

# Diff lines of one file between base and head; args: <old path> <new path>.
file_diff() {
  if [ "$1" = "$2" ]; then git diff -U0 --no-color "$BASE" HEAD -- "$2"
  else git diff -U0 --no-color "$BASE:$1" "HEAD:$2"; fi
}

inspect() { # inspect <old path> <new path>
  local d added removed
  d="$(file_diff "$1" "$2" | grep -Ev '^(\+\+\+|---) ' || true)"
  added="$(printf '%s\n' "$d" | grep -E '^\+' || true)"
  removed="$(printf '%s\n' "$d" | grep -E '^-' || true)"

  local s_add s_rem
  s_add="$(printf '%s\n' "$added" | count "$SKIP_RE")"
  s_rem="$(printf '%s\n' "$removed" | count "$SKIP_RE")"
  if [ "$s_add" -gt "$s_rem" ]; then
    add "$2: new skip, ignore or focus marker(s):"
    while IFS= read -r line; do add "      ${line:1}"; done < <(printf '%s\n' "$added" | grep -E "$SKIP_RE" | head -n 5)
  fi

  local a_add a_rem
  a_add="$(printf '%s\n' "$added" | count "$ASSERT_RE")"
  a_rem="$(printf '%s\n' "$removed" | count "$ASSERT_RE")"
  if [ "$a_rem" -gt "$a_add" ]; then add "$2: $a_rem assertion line(s) removed, $a_add added"; fi

  if printf '%s\n' "$added" | grep -Eq "$TRIVIAL_RE"; then
    add "$2: new trivial assertion(s) that always pass:"
    while IFS= read -r line; do add "      ${line:1}"; done < <(printf '%s\n' "$added" | grep -E "$TRIVIAL_RE" | head -n 5)
  fi
  return 0
}

while IFS=$'\t' read -r status p1 p2; do
  [ -n "$status" ] || continue
  case "$status" in
    D)  if is_test "$p1"; then add "$p1: test file deleted"; fi ;;
    R*) if is_test "$p1"; then
          if is_test "$p2"; then inspect "$p1" "$p2"; else add "$p1: test file moved out of tests to $p2"; fi
        fi ;;
    A|M|C*) target="${p2:-$p1}"; if is_test "$target"; then inspect "$target" "$target"; fi ;;
  esac
done < <(git diff --name-status -M --no-color "$BASE" HEAD)

# ---- result -----------------------------------------------------------------
echo "protected-tests: compared $(git rev-parse --short HEAD) with base $(git rev-parse --short "$BASE") ($BASE_INPUT)"
if [ ${#FINDINGS[@]} -eq 0 ]; then
  echo "protected-tests: no deleted, skipped or weakened tests."
  exit 0
fi

echo
echo "This pull request deletes, skips or weakens tests:"
for f in "${FINDINGS[@]}"; do printf '  - %s\n' "$f" | sed 's/^  -       /        /'; done
echo

APPROVED=""
[ "${ALLOW_TEST_CHANGES:-}" = true ] && APPROVED="variable ALLOW_TEST_CHANGES=true"
case ",${CI_MERGE_REQUEST_LABELS:-}," in *",$APPROVAL_LABEL,"*) APPROVED="label $APPROVAL_LABEL" ;; esac
if [ -n "$APPROVED" ]; then
  echo "protected-tests: approved by $APPROVED. Passing."
  exit 0
fi

cat <<EOF
If an agent made these changes to get a check passing, fix the code instead.
If the change is intended, a reviewer approves it:
  - GitHub or GitLab: add the label "$APPROVAL_LABEL" to the pull request
  - any CI: re-run the pipeline with the variable ALLOW_TEST_CHANGES=true
EOF
exit 1
