<#
.SYNOPSIS
  Install the 3-level agent harness into a project (PowerShell version of init-project.sh).

.DESCRIPTION
  Run with no parameters to answer questions interactively. Any parameter you pass
  skips its question. The first run for a project records its AI policy; nothing is
  installed until the project lead has signed it off.

  Without an interactive console (e.g. in CI) every value must come from parameters,
  and the project's AI policy record must already be approved.

.PARAMETER Mode
  in-repo: files go into the project repo (default when the client allows it).
  external: files stay in this harness repo under projects/<name>/; the project gets an
  untracked CLAUDE.local.md that imports them.

.PARAMETER CI
  CI template to add: github, gitlab, azure, jenkins, bitbucket, circleci, or none.

.PARAMETER Force
  Overwrite the project's rules and CLAUDE.md.

.EXAMPLE
  pwsh scripts/init-project.ps1
  pwsh scripts/init-project.ps1 -Project ..\client-app -Name "Client App" -Kit go -Client Acme -Lead "Project lead"
#>
param(
  [string]$Project = "",
  [string]$Name = "",
  [string]$Kit = "",
  [string]$Client = "",
  [string]$Lead = "",
  [string]$Division = "",
  [string]$DivisionName = "",
  [ValidateSet("", "in-repo", "external")][string]$Mode = "",
  [ValidateSet("", "github", "gitlab", "azure", "jenkins", "bitbucket", "circleci", "none")][string]$CI = "",
  [switch]$Force
)
$ErrorActionPreference = "Stop"
$DivisionAsked = $PSBoundParameters.ContainsKey("Division")

# HARNESS_INTERACTIVE=1 forces question mode with redirected input (used for testing).
$Interactive = (-not [Console]::IsInputRedirected) -or ($env:HARNESS_INTERACTIVE -eq "1")

$HarnessRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Level1 = Join-Path $HarnessRoot "level1-company/AGENTS.md"
$TplDir = Join-Path $HarnessRoot "level3-project"
$Today = Get-Date -Format "yyyy-MM-dd"
$Utf8 = New-Object System.Text.UTF8Encoding($false)

# ---- output and question helpers ---------------------------------------------
function Die([string]$msg) { [Console]::Error.WriteLine(""); [Console]::Error.WriteLine("error: $msg"); exit 1 }
function Info([string]$msg) { Write-Host "  $msg" }
function Section([string]$msg) { Write-Host ""; Write-Host "== $msg ==" }

if (-not (Test-Path -LiteralPath $Level1 -PathType Leaf)) { Die "Level 1 file not found: $Level1" }

function Read-Answer([string]$prompt) {
  [Console]::Error.Write($prompt)
  $line = [Console]::In.ReadLine()
  if ($null -eq $line) { Die "input ended before all questions were answered" }
  return $line
}

# Returns $current when already set (by a parameter); otherwise asks.
function Ask([string]$current, [string]$question, [string]$default = "") {
  if ($current) { return $current }
  if (-not $Interactive) { Die "missing value: $question (run in a terminal, or pass it as a parameter)" }
  $prompt = if ($default) { "$question [$default]: " } else { "${question}: " }
  $answer = Read-Answer $prompt
  if ($answer) { return $answer } else { return $default }
}

function Ask-Required([string]$current, [string]$question, [string]$default = "") {
  while ($true) {
    $value = Ask $current $question $default
    if ($value) { return $value }
    [Console]::Error.WriteLine("  An answer is required.")
  }
}

# Returns "y" or "n". An empty default means the question has no default.
function Ask-YesNo([string]$question, [string]$default) {
  if (-not $Interactive) { Die "missing answer: $question (run in a terminal)" }
  $hint = if ($default -eq "y") { "Y/n" } elseif ($default -eq "n") { "y/N" } else { "y/n" }
  while ($true) {
    $answer = Read-Answer "$question ($hint): "
    if (-not $answer) { $answer = $default }
    switch ($answer.ToLowerInvariant()) {
      { $_ -in "y", "yes" } { return "y" }
      { $_ -in "n", "no" } { return "n" }
      default { [Console]::Error.WriteLine("  Please answer y or n.") }
    }
  }
}

function Choose([string]$current, [string]$question, [string[]]$options) {
  if ($current) { return $current }
  if ($options.Count -eq 1) { Info "${question}: $($options[0]) (only option)"; return $options[0] }
  if (-not $Interactive) { Die "missing value: $question (run in a terminal, or pass it as a parameter)" }
  [Console]::Error.WriteLine($question)
  for ($i = 0; $i -lt $options.Count; $i++) { [Console]::Error.WriteLine("  $($i + 1)) $($options[$i])") }
  while ($true) {
    $answer = Read-Answer "Choose 1-$($options.Count): "
    $n = 0
    if ([int]::TryParse($answer, [ref]$n) -and $n -ge 1 -and $n -le $options.Count) { return $options[$n - 1] }
    [Console]::Error.WriteLine("  Enter a number from the list.")
  }
}

# ---- file helpers -------------------------------------------------------------
function Read-Text([string]$path) { return ([IO.File]::ReadAllText((Resolve-Path -LiteralPath $path).Path) -replace "`r", "") }
function Write-Text([string]$path, [string]$text) {
  $dir = Split-Path -Parent $path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [IO.File]::WriteAllText([IO.Path]::GetFullPath($path), $text, $Utf8)
}
function Version-Of([string]$path) {
  $m = [regex]::Match((Read-Text $path), "(?m)^Version: (\S+)")
  if ($m.Success) { return $m.Groups[1].Value } else { return "" }
}
# Copy a template, replacing placeholders; empty values keep the placeholder.
function Render([string]$template, [string]$out, [hashtable]$values) {
  $text = Read-Text $template
  foreach ($key in $values.Keys) { if ($values[$key]) { $text = $text.Replace($key, $values[$key]) } }
  Write-Text $out $text
}
function Cell([string]$value) { return ($value -replace "\|", "/" -replace "`n", " ") }
function Has-Line([string]$path, [string]$pattern) {
  return (Test-Path -LiteralPath $path -PathType Leaf) -and ([regex]::IsMatch((Read-Text $path), "(?m)$pattern"))
}
function Is-GitRepo([string]$dir) {
  & git -C $dir rev-parse --git-dir *> $null
  return ($LASTEXITCODE -eq 0)
}
# Path as Claude Code expects it in an import: forward slashes, spaces escaped.
function Import-Path([string]$path) { return ([IO.Path]::GetFullPath($path) -replace "\\", "/" -replace " ", "\ ") }

# ---- 1. project ---------------------------------------------------------------
Section "Project"

while ($true) {
  $Project = Ask-Required $Project "Project folder" (Get-Location).Path
  if (Test-Path -LiteralPath $Project -PathType Container) { break }
  if (-not $Interactive) { Die "project folder not found: $Project" }
  [Console]::Error.WriteLine("  Folder not found: $Project"); $Project = ""
}
$Project = (Resolve-Path -LiteralPath $Project).Path

$Name = Ask-Required $Name "Project name" (Split-Path -Leaf $Project)
$Slug = ($Name.ToLowerInvariant() -replace "[^a-z0-9]+", "-").Trim("-")
if (-not $Slug) { Die "project name must contain letters or digits" }
$RecordDir = Join-Path $HarnessRoot "projects/$Slug"
$Policy = Join-Path $RecordDir "AI-POLICY.md"
$ExcludedPattern = '^- \[[xX]\] \*\*Excluded:\*\*'
$ApprovedPattern = '^- \[[xX]\] \*\*Approved:\*\*'
if (Has-Line $Policy $ExcludedPattern) {
  Write-Host "The client forbids AI. $Name is excluded from the harness; nothing was installed."
  Write-Host "Record: $Policy"
  exit 3
}

$Client = Ask-Required $Client "Client name"
$Lead = Ask-Required $Lead "Project lead (signs off the AI policy)"

# Kits are folders under kits/ with an AGENTS.md; folders starting with "_" are templates.
$Kits = @(Get-ChildItem -LiteralPath (Join-Path $HarnessRoot "kits") -Directory |
  Where-Object { -not $_.Name.StartsWith("_") -and (Test-Path -LiteralPath (Join-Path $_.FullName "AGENTS.md")) } |
  Sort-Object Name | ForEach-Object { $_.Name })
if ($Kits.Count -eq 0) { Die "no stack kits yet. Copy kits/_template/ to kits/<your-stack>/, fill it in, then run this script again." }
$Kit = Choose $Kit "Stack kit" $Kits
if ($Kits -notcontains $Kit) { Die "no kit `"$Kit`"; available: $($Kits -join ' ')" }
$KitFile = Join-Path $HarnessRoot "kits/$Kit/AGENTS.md"
if ((Read-Text $KitFile).Contains("<Stack name>")) { Die "kits/$Kit/AGENTS.md is still the blank template; fill it in first" }

if (-not $DivisionAsked -and $Interactive) {
  while ($true) {
    $Division = Read-Answer "Path to the division's filled DIVISION.md (blank to skip): "
    if (-not $Division) { break }
    if (-not (Test-Path -LiteralPath $Division -PathType Leaf)) { [Console]::Error.WriteLine("  File not found.") }
    elseif ((Read-Text $Division).Contains("<Division name>")) { [Console]::Error.WriteLine("  That is still the blank template.") }
    else { break }
  }
}
if ($Division) {
  if (-not (Test-Path -LiteralPath $Division -PathType Leaf)) { Die "division file not found: $Division" }
  if ((Read-Text $Division).Contains("<Division name>")) { Die "division file is still the blank template: $Division" }
  if (-not $DivisionName) {
    $m = [regex]::Match((Read-Text $Division), "(?m)^# Division rules \(Level 2\): *(.+)$")
    if ($m.Success) { $DivisionName = $m.Groups[1].Value.Trim(); Info "Division: $DivisionName (from the division file)" }
  }
}
if ($Interactive) { $DivisionName = Ask $DivisionName "Division name (blank if none)" $DivisionName }

# ---- 2. AI policy ---------------------------------------------------------------
Section "AI policy"

function Write-Policy([string]$approved, [string]$excluded, [hashtable]$p) {
  $a = " "; $e = " "; $date = "<pending>"
  if ($approved -eq "y") { $a = "x"; $date = $Today }
  if ($excluded -eq "y") { $e = "x"; $date = $Today }
  $div = if ($DivisionName) { $DivisionName } else { "<Division>" }
  $src = Cell $p.Source
  $lines = @(
    "# AI policy record: $Name",
    "",
    "Client: $Client · Division: $div · Signed off by: $Lead · Date: $date",
    "",
    "No agent touches client code until this record is complete and signed off. Re-check it when the contract or client policy changes.",
    "",
    "## Answers",
    "",
    "| Question | Answer | Source |",
    "| --- | --- | --- |",
    "| Does the client allow AI coding tools at all? | $(Cell $p.Allow) | $src |",
    "| Which tools are allowed? | $(Cell $p.Tools) | $src |",
    "| May client code be sent to external AI services? | $(Cell $p.External) | $src |",
    "| Data-residency or hosting limits? | $(Cell $p.Residency) | $src |",
    "| May agent files (AGENTS.md, CLAUDE.md) live in the client repo? | $(Cell $p.Files) | $src |",
    "| Must agent-assisted work be disclosed or labelled? | $(Cell $p.Disclose) | $src |",
    "| Domain rules stricter than the division's? | $(Cell $p.Domain) | $src |",
    "",
    "## Result",
    "",
    "- [$a] **Approved:** agents may be used within the answers above. Continue with the project AGENTS.md.",
    "- [$e] **Excluded:** the client forbids AI. This project is outside the harness and no agents are used."
  )
  Write-Text $Policy (($lines -join "`n") + "`n")
}

function Policy-Answer([string]$question) {
  foreach ($line in (Read-Text $Policy).Split("`n")) {
    $cols = $line.Split("|")
    if ($cols.Count -ge 4 -and $cols[1].Contains($question)) { return $cols[2].Trim() }
  }
  return ""
}

if (Test-Path -LiteralPath $Policy -PathType Leaf) {
  Info "Using the existing record: $Policy"
} else {
  Write-Host "Answer from the contract, NDA or client emails. These answers become the project's AI policy record."
  $p = @{}
  $allow = Ask-YesNo "Does the client allow AI coding tools at all?" ""
  $p.Allow = if ($allow -eq "y") { "yes" } else { "no" }
  $p.Source = Ask-Required "" "Where do these answers come from (contract clause, NDA, email)?"
  if ($allow -eq "n") {
    $p.Tools = "none"; $p.External = "no"; $p.Residency = "n/a"; $p.Files = "no"; $p.Disclose = "n/a"; $p.Domain = "n/a"
    Write-Policy "n" "y" $p
    Write-Host ""
    Write-Host "The client forbids AI. Recorded $Name as excluded: $Policy"
    Write-Host "Nothing was installed."
    exit 3
  }
  $p.Tools = Ask-Required "" "Which AI tools are allowed?" "Claude Code"
  $p.External = Ask-Required "" "May client code be sent to external AI services? (yes / no / only <service>)" "yes"
  $p.Residency = Ask-Required "" "Data-residency or hosting limits?" "none"
  $files = Ask-YesNo "May agent files (AGENTS.md, CLAUDE.md) live in the client repo?" ""
  $p.Files = if ($files -eq "y") { "yes" } else { "no" }
  $p.Disclose = Ask-Required "" "Must agent-assisted work be disclosed or labelled? (yes / no / per PR)" "yes"
  $p.Domain = Ask-Required "" "Domain rules stricter than the division's?" "none"
  Write-Policy "n" "n" $p
  Info "Record written: $Policy"
}

if (Has-Line $Policy $ExcludedPattern) {
  Write-Host "The client forbids AI. $Name is excluded from the harness; nothing was installed."
  exit 3
}
if (-not (Has-Line $Policy $ApprovedPattern)) {
  if (-not $Interactive) { Die "the AI policy record is not approved yet: $Policy" }
  $signed = Ask-YesNo "Has $Lead reviewed and signed off this record?" "n"
  if ($signed -eq "n") {
    Write-Host ""
    Write-Host "Stopped before installing. Get the record signed off, then run this script again:"
    Write-Host "  $Policy"
    exit 2
  }
  $text = (Read-Text $Policy) -replace '(?m)^- \[ \] \*\*Approved:\*\*', '- [x] **Approved:**'
  $text = $text.Replace("Date: <pending>", "Date: $Today")
  Write-Text $Policy $text
  Info "Record approved."
}

# The policy decides whether files may live in the client repo.
if ((Policy-Answer "May agent files").ToLowerInvariant().StartsWith("y")) {
  if (-not $Mode) { $Mode = "in-repo" }
} else {
  if ($Mode -eq "in-repo") { Die "the AI policy record does not allow agent files in the client repo; use -Mode external" }
  $Mode = "external"
}

# CI checks need files in the client repo, so they only apply in in-repo mode.
if ($Mode -eq "external") {
  if ($CI -and $CI -ne "none") { Info "CI checks skipped: external mode keeps all harness files out of the client repo." }
  $CI = "none"
} elseif (-not $CI) {
  if ($Interactive) {
    $labels = [ordered]@{ "GitHub Actions" = "github"; "GitLab CI" = "gitlab"; "Azure Pipelines" = "azure"; "Jenkins" = "jenkins";
      "Bitbucket Pipelines" = "bitbucket"; "CircleCI" = "circleci"; "None or decide later" = "none" }
    $label = Choose "" "Which CI runs this project's pull requests?" ([string[]]$labels.Keys)
    $CI = $labels[$label]
  } else {
    $CI = "none"
  }
}

# ---- 3. confirm -----------------------------------------------------------------
Section "Summary"
Info "Project:   $Name  ($Project)"
Info "Client:    $Client"
Info "Lead:      $Lead"
$divInfo = if ($DivisionName) { $DivisionName } else { "none" }
if ($Division) { $divInfo += "  ($Division)" }
Info "Division:  $divInfo"
Info "Stack kit: $Kit $(Version-Of $KitFile)"
Info "Mode:      $Mode"
Info "CI:        $CI"
if ($Interactive) {
  if ((Ask-YesNo "Install the harness?" "y") -ne "y") { Write-Host "Cancelled; nothing was installed."; exit 0 }
}

# ---- 4. install the levels ------------------------------------------------------
Section "Install"
$Dest = if ($Mode -eq "in-repo") { $Project } else { $RecordDir }
$H = Join-Path $Dest ".harness"
foreach ($d in "level1", "kit", "project", "checks") { New-Item -ItemType Directory -Force -Path (Join-Path $H $d) | Out-Null }

Copy-Item -LiteralPath $Level1 -Destination (Join-Path $H "level1/AGENTS.md") -Force; Info "Level 1     .harness/level1/AGENTS.md"
Copy-Item -LiteralPath $KitFile -Destination (Join-Path $H "kit/AGENTS.md") -Force; Info "Stack kit   .harness/kit/AGENTS.md ($Kit)"
$kitChecks = Join-Path $H "kit/checks"
if (Test-Path -LiteralPath $kitChecks) { Remove-Item -LiteralPath $kitChecks -Recurse -Force }
$srcChecks = Join-Path $HarnessRoot "kits/$Kit/checks"
if (Test-Path -LiteralPath $srcChecks -PathType Container) {
  Copy-Item -LiteralPath $srcChecks -Destination $kitChecks -Recurse -Force
  Info "Kit checks  .harness/kit/checks/ (linter configs and architecture tests to adopt)"
}
$installedDivision = Join-Path $H "division/DIVISION.md"
if ($Division) {
  New-Item -ItemType Directory -Force -Path (Join-Path $H "division") | Out-Null
  Copy-Item -LiteralPath $Division -Destination $installedDivision -Force; Info "Level 2     .harness/division/DIVISION.md"
} elseif (Test-Path -LiteralPath $installedDivision) {
  Info "Level 2     kept the installed division file"
} else {
  Info "Level 2     skipped (no division file)"
}
foreach ($f in "build-agents-md.sh", "build-agents-md.ps1") {
  Copy-Item -LiteralPath (Join-Path $HarnessRoot "scripts/$f") -Destination (Join-Path $H $f) -Force
}
Copy-Item -LiteralPath (Join-Path $HarnessRoot "checks/protected-tests.sh") -Destination (Join-Path $H "checks/protected-tests.sh") -Force
Info "Scripts     .harness/build-agents-md.sh (.ps1), .harness/checks/protected-tests.sh"

$HarnessVersion = "unversioned"
if (Is-GitRepo $HarnessRoot) {
  $described = & git -C $HarnessRoot describe --tags --always --dirty 2>$null
  if ($LASTEXITCODE -eq 0 -and $described) { $HarnessVersion = "$described".Trim() }
}
$KitVersion = Version-Of $KitFile
$DivVersion = "none"
if ($Division) { $DivVersion = Version-Of $Division; if (-not $DivVersion) { $DivVersion = "unversioned" } }
Write-Text (Join-Path $H "harness.lock") ((@(
  "# Versions installed by init-project.sh. Upgrade by re-running it on purpose.",
  "harness: $HarnessVersion",
  "level1: $(Version-Of $Level1)",
  "division: $DivVersion",
  "kit: $Kit $KitVersion",
  "ci: $CI",
  "installed: $Today"
) -join "`n") + "`n")
Info "Lock file   .harness/harness.lock"

# Project rules live in .harness/project/AGENTS.md; the root AGENTS.md is generated.
$RootAgents = Join-Path $Dest "AGENTS.md"
$ProjectRules = Join-Path $H "project/AGENTS.md"
$isGenerated = (Test-Path -LiteralPath $RootAgents) -and (Read-Text $RootAgents).StartsWith("<!-- GENERATED by build-agents-md.sh")
if ((Test-Path -LiteralPath $RootAgents) -and -not $isGenerated) {
  if (Test-Path -LiteralPath $ProjectRules) {
    Die "both AGENTS.md and .harness/project/AGENTS.md exist in $Dest. Merge AGENTS.md into the project rules file, delete AGENTS.md, then run this script again."
  }
  Move-Item -LiteralPath $RootAgents -Destination $ProjectRules
  Info "Project     moved the existing AGENTS.md to .harness/project/AGENTS.md"
}
if ((Test-Path -LiteralPath $ProjectRules) -and -not $Force) {
  Info "Project     kept .harness/project/AGENTS.md"
} else {
  Render (Join-Path $TplDir "AGENTS.template.md") $ProjectRules @{
    "<Project name>" = $Name; "<kit name>" = $Kit; "<x.y.z>" = $KitVersion; "<Project lead>" = $Lead }
  Info "Project     .harness/project/AGENTS.md created from template; fill it in"
}

& (Join-Path $H "build-agents-md.ps1") -Path $Dest | Out-Null
if ($LASTEXITCODE -ne 0) { Die "could not generate AGENTS.md in $Dest" }
Info "AGENTS.md   generated from all levels (read by every agent)"

# CLAUDE.md only needs to import the generated AGENTS.md.
$ClaudeMd = Join-Path $Dest "CLAUDE.md"
if (-not (Test-Path -LiteralPath $ClaudeMd) -or $Force -or (Read-Text $ClaudeMd).Contains("@.harness/level1/AGENTS.md")) {
  Copy-Item -LiteralPath (Join-Path $TplDir "CLAUDE.template.md") -Destination $ClaudeMd -Force
  Info "CLAUDE.md   imports AGENTS.md"
} elseif (Has-Line $ClaudeMd '^@AGENTS\.md$') {
  Info "CLAUDE.md   kept existing file (already imports AGENTS.md)"
} else {
  Write-Text $ClaudeMd ((Read-Text $ClaudeMd) + "`n@AGENTS.md`n")
  Info "CLAUDE.md   kept your content and added an import of AGENTS.md at the end"
}

# CI template for the protected-test and AGENTS.md checks.
$CiNext = ""
$ciSources = @{ gitlab = "gitlab-ci.yml"; azure = "azure-pipelines.yml"; jenkins = "Jenkinsfile.groovy"; bitbucket = "bitbucket-pipelines.yml"; circleci = "circleci-config.yml" }
$ciHints = @{
  github    = "Create the 'test-change-approved' label in GitHub, and make the 'agent-harness' check required on your main branch."
  gitlab    = "Add to .gitlab-ci.yml:  include: { local: '.harness/ci/gitlab-ci.yml' }"
  azure     = "Create a pipeline from .harness/ci/azure-pipelines.yml and add it as a build validation policy on your main branch."
  jenkins   = "Copy the stage from .harness/ci/Jenkinsfile.groovy into your Jenkinsfile."
  bitbucket = "Merge .harness/ci/bitbucket-pipelines.yml into the pull-requests section of your bitbucket-pipelines.yml."
  circleci  = "Merge the job and workflow from .harness/ci/circleci-config.yml into .circleci/config.yml."
}
if ($CI -eq "github") {
  $workflow = Join-Path $Dest ".github/workflows/agent-harness.yml"
  if ((Test-Path -LiteralPath $workflow) -and -not $Force) {
    Info "CI          kept .github/workflows/agent-harness.yml"
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $workflow) | Out-Null
    Copy-Item -LiteralPath (Join-Path $HarnessRoot "ci/github-actions.yml") -Destination $workflow -Force
    Info "CI          .github/workflows/agent-harness.yml"
  }
} elseif ($ciSources.ContainsKey($CI)) {
  New-Item -ItemType Directory -Force -Path (Join-Path $H "ci") | Out-Null
  Copy-Item -LiteralPath (Join-Path $HarnessRoot "ci/$($ciSources[$CI])") -Destination (Join-Path $H "ci/$($ciSources[$CI])") -Force
  Info "CI          .harness/ci/$($ciSources[$CI])"
}
if ($ciHints.ContainsKey($CI)) { $CiNext = $ciHints[$CI] }

# External mode: link the project without committing anything to it.
if ($Mode -eq "external") {
  $importLine = "@" + (Import-Path (Join-Path $Dest "CLAUDE.md"))
  $local = Join-Path $Project "CLAUDE.local.md"
  if ((Test-Path -LiteralPath $local) -and ((Read-Text $local).Split("`n") -ccontains $importLine)) {
    Info "CLAUDE.local.md already imports the harness"
  } else {
    $existing = if (Test-Path -LiteralPath $local) { Read-Text $local } else { "# Local agent harness (not committed)`n`n" }
    Write-Text $local ($existing + $importLine + "`n")
    Info "CLAUDE.local.md imports $(Join-Path $Dest 'CLAUDE.md')"
  }
  if (Is-GitRepo $Project) {
    $exclude = (& git -C $Project rev-parse --git-path info/exclude).Trim()
    if (-not [IO.Path]::IsPathRooted($exclude)) { $exclude = Join-Path $Project $exclude }
    $current = if (Test-Path -LiteralPath $exclude) { Read-Text $exclude } else { "" }
    if ($current.Split("`n") -ccontains "CLAUDE.local.md") {
      Info "git         CLAUDE.local.md already in .git/info/exclude"
    } else {
      if ($current -and -not $current.EndsWith("`n")) { $current += "`n" }
      Write-Text $exclude ($current + "CLAUDE.local.md`n")
      Info "git         CLAUDE.local.md added to .git/info/exclude"
    }
  } else {
    Info "warning     project is not a git repo; make sure CLAUDE.local.md is never committed"
  }
}

Write-Host ""
Write-Host "Done. Next:"
Write-Host "  - Fill in $(Join-Path $H 'project/AGENTS.md') (commands, client conventions, boundaries),"
Write-Host "    then regenerate AGENTS.md: pwsh $(Join-Path $H 'build-agents-md.ps1')"
Write-Host "  - Open Claude Code in $Project and run /memory to check AGENTS.md is loaded."
if ($Mode -eq "external") {
  Write-Host "    Claude Code asks once to approve the import from outside the project; approve it."
} else {
  if ($CiNext) { Write-Host "  - CI: $CiNext" }
  if (Test-Path -LiteralPath $kitChecks) { Write-Host "  - Adopt the kit's checks from .harness/kit/checks/ (see its README)." }
  Write-Host "  - Commit .harness/, AGENTS.md, CLAUDE.md and any CI file in one PR for review."
}
exit 0
