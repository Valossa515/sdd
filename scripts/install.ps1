# install.ps1 - Install SDD skills into a project, natively on Windows
#
# Usage (one line, from your project folder):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.ps1))) -Stack dotnet
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/valossa515/sdd/main/scripts/install.ps1))) -Stack spring-boot -Ref v1.0.0
#
# Usage (from a local clone):
#   powershell -ExecutionPolicy Bypass -File C:\tmp\sdd\scripts\install.ps1 -Stack dotnet -Target .
#
# Runs on Windows PowerShell 5.1 and PowerShell 7+; needs only git (for remote installs).
# Mirrors scripts/install.sh: CI diffs the output of both installers, keep them in sync.
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.

[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string] $Stack,
  [Parameter(Position = 1)] [string] $Target = (Get-Location).Path,
  [Parameter(Position = 2)] [ValidateSet('agent', 'kiro')] [string] $Format = 'agent',
  [string] $Ref,     # tag or branch to clone, e.g. v1.0.0 (remote installs only)
  [string] $Source   # local SDD checkout; default: the repo this script is in, else a fresh clone
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SddRepo  = 'https://github.com/valossa515/sdd.git'
$Utf8     = New-Object System.Text.UTF8Encoding($false)
$CheckMk  = [char]0x2714
$Arrow    = [char]0x2192

# --- Helpers ------------------------------------------------------------------
function Write-Step([string] $Text) {
  Write-Host "  $Arrow " -ForegroundColor Cyan -NoNewline
  Write-Host $Text
}

function New-Directory([string] $Path) {
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Join-Child([string] $Base, [string] $Child) {
  [System.IO.Path]::Combine($Base, $Child)
}

# Equivalent of `cp -r <from>/. <to>/`: merge a directory tree into another
function Copy-Tree([string] $From, [string] $To) {
  $root = (Get-Item -LiteralPath $From).FullName.TrimEnd('\', '/')
  foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Force) {
    $dest = Join-Child $To $file.FullName.Substring($root.Length + 1)
    New-Directory (Split-Path -Parent $dest)
    Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
  }
}

function Get-MarkdownFiles([string] $Dir) {
  if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return @() }
  @(Get-ChildItem -LiteralPath $Dir -Filter '*.md' -File | Sort-Object Name)
}

# Project-owned files (SKILLS.md overrides, bootstrap context docs) are only
# created on first install; re-installs keep the project's version.
function Copy-IfMissing([string] $From, [string] $To, [System.Collections.Generic.List[string]] $Kept) {
  if (Test-Path -LiteralPath $To) { $Kept.Add($To.Substring($Target.Length + 1).Replace('\', '/')) }
  else { Copy-Item -LiteralPath $From -Destination $To -Force }
}

function Read-Lines([string] $Path) {
  [System.IO.File]::ReadAllText($Path) -split "`r?`n"
}

# The SDD version being installed, read from the plugin manifest
function Get-SddVersion([string] $Src) {
  $manifest = Join-Child $Src '.claude-plugin/plugin.json'
  if (-not (Test-Path -LiteralPath $manifest)) { return '' }
  [string] ([System.IO.File]::ReadAllText($manifest) | ConvertFrom-Json).version
}

# agents/<role>.md -> Copilot custom agent (.github/agents/<name>.agent.md).
# Byte-for-byte the same transformation as the grep/awk/sed pipeline in install.sh.
function ConvertTo-CopilotAgent([string] $Path) {
  $lines = Read-Lines $Path

  $name = ''
  foreach ($line in $lines) {
    if ($line -cmatch '^name:') { $name = $line -creplace '^name: *', ''; break }
  }

  # description: inline value and/or indented continuation lines, joined by single spaces
  $parts = New-Object System.Collections.Generic.List[string]
  $inDescription = $false
  foreach ($line in $lines) {
    if ($line -cmatch '^description:') {
      $inDescription = $true
      $value = $line -creplace '^description: *>? *', ''
      if ($value.Length -gt 0) { $parts.Add($value) }
      continue
    }
    if ($inDescription -and $line -cmatch '^  ') { $parts.Add(($line -replace '^ +', '')); continue }
    $inDescription = $false
  }
  $description = ((@($parts) | ForEach-Object { "$_ " }) -join '') -replace ' +', ' ' -replace ' $', ''

  # body: everything after the frontmatter (install.sh skips every line starting with ---)
  $body = New-Object System.Collections.Generic.List[string]
  $dashes = 0
  foreach ($line in $lines) {
    if ($line -cmatch '^---') { $dashes++; continue }
    if ($dashes -ge 2) { $body.Add($line) }
  }
  $bodyText = (@($body) -join "`n").TrimEnd("`n")

  $content = "---`nname: $name`ndescription: `"$description`"`n---`n`n" +
             "Read and follow all skills in .agent/SKILLS.md before any task.`n`n" +
             "$bodyText`n"
  @{ Name = $name; Content = $content }
}

# --- Get SDD source -----------------------------------------------------------
function Resolve-SddSource {
  if ($Source) {
    if (-not (Test-Path -LiteralPath (Join-Child $Source 'skills') -PathType Container)) {
      throw "Not an SDD checkout (no skills/ folder): $Source"
    }
    if ($Ref) { Write-Host "! -Ref is ignored when installing from a local source" -ForegroundColor Yellow }
    return @{ Path = (Resolve-Path -LiteralPath $Source).Path; Temporary = $false }
  }

  # Running from a clone of the sdd repo
  if ($PSScriptRoot) {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    if (Test-Path -LiteralPath (Join-Child $repoRoot 'skills') -PathType Container) {
      if ($Ref) { Write-Host "! -Ref is ignored when installing from a local clone (use git checkout $Ref)" -ForegroundColor Yellow }
      return @{ Path = $repoRoot; Temporary = $false }
    }
  }

  # Clone the repo to a temp directory (optionally pinned to a tag/branch)
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required to download SDD. Install Git for Windows: https://git-scm.com/download/win'
  }
  $refLabel = if ($Ref) { " (ref: $Ref)" } else { '' }
  Write-Host "> Fetching SDD from GitHub$refLabel..." -ForegroundColor Cyan
  $tmp = Join-Child ([System.IO.Path]::GetTempPath()) ('sdd-' + [guid]::NewGuid().ToString('N'))
  # autocrlf=false: install.sh-compatible LF files regardless of the user's git config
  $gitArgs = @('clone', '--depth=1', '--quiet', '-c', 'core.autocrlf=false')
  if ($Ref) { $gitArgs += @('--branch', $Ref) }
  & git @gitArgs $SddRepo $tmp | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "git clone of $SddRepo failed" }
  @{ Path = $tmp; Temporary = $true }
}

# --- Install in .agent/ format ------------------------------------------------
function Install-AgentFormat([string] $Src) {
  $dest = Join-Child $Target '.agent'

  New-Directory (Join-Child $dest 'skills/shared')
  New-Directory (Join-Child $dest 'adr')

  Write-Step '.agent/skills/shared/'
  Copy-Tree (Join-Child $Src 'skills/shared') (Join-Child $dest 'skills/shared')

  $kept = New-Object System.Collections.Generic.List[string]
  Write-Step '.agent/context docs'
  foreach ($doc in 'context', 'architecture', 'decisions', 'conventions', 'runbook', 'glossary', 'backlog_rules') {
    Copy-IfMissing (Join-Child $Src "templates/common/$doc.md") (Join-Child $dest "$doc.md") $kept
  }

  New-Directory (Join-Child $dest "skills/$Stack")
  Write-Step ".agent/skills/$Stack/"
  Copy-Tree (Join-Child $Src "skills/$Stack") (Join-Child $dest "skills/$Stack")
  $skillsFile = Join-Child $dest 'SKILLS.md'
  Copy-IfMissing (Join-Child $Src "templates/$Stack/SKILLS.md") $skillsFile $kept

  # Stamp the real SDD version so projects know what they installed (also on a
  # kept SKILLS.md: only that line changes, the overrides stay)
  $version = Get-SddVersion $Src
  if ($version) {
    $text = [System.IO.File]::ReadAllText($skillsFile)
    $text = [regex]::Replace($text, '(?m)^sdd-version: [^\r\n]*', "sdd-version: `"$version`"")
    [System.IO.File]::WriteAllText($skillsFile, $text, $Utf8)
  }

  Write-Step '.agent/SKILLS.md'

  # -- Agents ----------------------------------------------------------------
  $agents = @(Get-MarkdownFiles (Join-Child $Src 'agents'))
  if ($agents.Count -gt 0) {
    New-Directory (Join-Child $dest 'agents')
    Write-Step '.agent/agents/'
    foreach ($f in $agents) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Child $dest 'agents') -Force }

    # -- Copilot Custom Agents (.github/agents/*.agent.md) ------------------
    $agentsDir = Join-Child $Target '.github/agents'
    New-Directory $agentsDir
    Write-Step '.github/agents/'
    foreach ($f in $agents) {
      if ($f.Name -eq 'README.md') { continue }
      $agent = ConvertTo-CopilotAgent $f.FullName
      [System.IO.File]::WriteAllText((Join-Child $agentsDir "$($agent.Name).agent.md"), $agent.Content, $Utf8)
      Write-Host "     $($agent.Name).agent.md"
    }
  }

  # -- Prompts ---------------------------------------------------------------
  $prompts = @(Get-MarkdownFiles (Join-Child $Src 'prompts'))
  if ($prompts.Count -gt 0) {
    New-Directory (Join-Child $dest 'prompts')
    Write-Step '.agent/prompts/'
    foreach ($f in $prompts) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Child $dest 'prompts') -Force }
  }

  # -- Spec schemas ----------------------------------------------------------
  $specsSrc = Join-Child $Src 'specs'
  if (Test-Path -LiteralPath $specsSrc -PathType Container) {
    foreach ($d in 'features', 'acceptance', 'contracts') { New-Directory (Join-Child $dest "specs/$d") }
    Write-Step '.agent/specs/'
    foreach ($f in Get-MarkdownFiles $specsSrc) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Child $dest 'specs') -Force }
    $examples = Join-Child $specsSrc 'examples'
    if (Test-Path -LiteralPath $examples -PathType Container) {
      New-Directory (Join-Child $dest 'specs/examples')
      foreach ($f in Get-ChildItem -LiteralPath $examples -Filter '*.toon' -File) {
        Copy-Item -LiteralPath $f.FullName -Destination (Join-Child $dest 'specs/examples') -Force
      }
    }
  }

  # -- Spec validator --------------------------------------------------------
  $validator = Join-Child $Src 'scripts/validate-spec.sh'
  if (Test-Path -LiteralPath $validator) {
    New-Directory (Join-Child $dest 'scripts')
    Copy-Item -LiteralPath $validator -Destination (Join-Child $dest 'scripts') -Force
    Write-Step '.agent/scripts/validate-spec.sh'
  }

  # -- PR template -----------------------------------------------------------
  $prTemplate = Join-Child $Src 'templates/PULL_REQUEST_TEMPLATE.md'
  if (Test-Path -LiteralPath $prTemplate) {
    New-Directory (Join-Child $dest 'templates')
    Copy-Item -LiteralPath $prTemplate -Destination (Join-Child $dest 'templates') -Force
    Write-Step '.agent/templates/PULL_REQUEST_TEMPLATE.md'
  }

  if ($kept.Count -gt 0) {
    Write-Host ''
    Write-Host '  Kept your existing project files' -ForegroundColor Yellow -NoNewline
    Write-Host ' (delete one to reset it to the template):'
    foreach ($f in $kept) { Write-Host "     $f" }
  }

  Write-Host ''
  Write-Host "$CheckMk Installed to: $dest" -ForegroundColor Green
}

# --- Install in Kiro .kiro/steering/ format -----------------------------------
function Install-KiroFormat([string] $Src) {
  $dest = Join-Child $Target '.kiro/steering'
  New-Directory $dest

  # Shared skills (skills/shared/<name>/SKILL.md -> <name>.md, flattened)
  Write-Step '.kiro/steering/ (shared)'
  foreach ($d in Get-ChildItem -LiteralPath (Join-Child $Src 'skills/shared') -Directory | Sort-Object Name) {
    $skill = Join-Child $d.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skill)) { continue }
    Copy-Item -LiteralPath $skill -Destination (Join-Child $dest "$($d.Name).md") -Force
    Write-Host "     $($d.Name).md"
  }

  Write-Step ".kiro/steering/ ($Stack)"
  foreach ($f in Get-MarkdownFiles (Join-Child $Src "skills/$Stack")) {
    Copy-Item -LiteralPath $f.FullName -Destination (Join-Child $dest "$Stack-$($f.Name)") -Force
    Write-Host "     $Stack-$($f.Name)"
  }

  # Agents and prompts, flattened with a prefix
  foreach ($kind in @(@{ Dir = 'agents'; Prefix = 'agent-' }, @{ Dir = 'prompts'; Prefix = 'prompt-' })) {
    $files = @(Get-MarkdownFiles (Join-Child $Src $kind.Dir) | Where-Object { $_.Name -ne 'README.md' })
    if ($files.Count -eq 0) { continue }
    Write-Step ".kiro/steering/ ($($kind.Dir))"
    foreach ($f in $files) {
      Copy-Item -LiteralPath $f.FullName -Destination (Join-Child $dest "$($kind.Prefix)$($f.Name)") -Force
      Write-Host "     $($kind.Prefix)$($f.Name)"
    }
  }

  Write-Host ''
  Write-Host "$CheckMk Installed to: $dest" -ForegroundColor Green
}

# --- .gitignore hint ----------------------------------------------------------
function Show-GitignoreHint {
  $gitignore = Join-Child $Target '.gitignore'
  if ((Test-Path -LiteralPath $gitignore) -and -not (Select-String -LiteralPath $gitignore -SimpleMatch '.agent/' -Quiet)) {
    Write-Host ''
    Write-Host 'Tip: ' -ForegroundColor Yellow -NoNewline
    Write-Host 'Commit the .agent/ folder so your team shares the same conventions.'
    Write-Host "     (Don't add it to .gitignore)"
  }
}

# --- Post-install summary -----------------------------------------------------
function Show-Summary {
  $steps = if ($Format -eq 'kiro') {
    @('1. Open .kiro/steering/ and review the skills',
      "2. Edit $Stack-SKILL.md to add project conventions",
      '3. Commit the folder alongside your source code')
  } else {
    @('1. Open .agent/SKILLS.md and review the active skills',
      "2. Fill in the '## Project Overrides' section",
      '3. Review .agent/agents/ for the agent pipeline',
      '4. Review .agent/prompts/ for action templates',
      '5. Commit the folder alongside your source code',
      "6. Tell your agent: 'Read .agent/SKILLS.md before every task'",
      '   (or set up auto-context loading)')
  }
  Write-Host ''
  Write-Host '  What to do next' -ForegroundColor White
  foreach ($line in $steps) { Write-Host "    $line" }
  Write-Host ''
}

# --- Main ---------------------------------------------------------------------
Write-Host ''
Write-Host '  SDD - Skill-Driven Development' -ForegroundColor White
Write-Host '  Specialized skill files for AI coding agents'
Write-Host ''

if (-not $Stack) {
  throw 'Stack is required. Usage: install.ps1 -Stack <spring-boot|dotnet> [-Target <dir>] [-Format agent|kiro] [-Ref <tag>]'
}
if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
  throw "Target directory does not exist: $Target"
}
$Target = (Resolve-Path -LiteralPath $Target).Path

Write-Host "  Stack  : $Stack"
Write-Host "  Target : $Target"
Write-Host "  Format : $Format"
Write-Host ''

$sdd = Resolve-SddSource
try {
  # Stacks are the directories under skills/ (except shared); each stack needs
  # a matching templates/<stack>/SKILLS.md entry point.
  $stacks = @(Get-ChildItem -LiteralPath (Join-Child $sdd.Path 'skills') -Directory |
    Where-Object { $_.Name -ne 'shared' } | ForEach-Object { $_.Name } | Sort-Object)
  if ($stacks -cnotcontains $Stack) {
    throw "Unknown stack: $Stack. Available: $($stacks -join ' ')"
  }
  if ($Format -eq 'agent' -and -not (Test-Path -LiteralPath (Join-Child $sdd.Path "templates/$Stack/SKILLS.md"))) {
    throw "Stack '$Stack' has no templates/$Stack/SKILLS.md entry point."
  }

  Write-Host '> Installing skills...' -ForegroundColor Cyan
  Write-Host ''
  if ($Format -eq 'kiro') { Install-KiroFormat $sdd.Path } else { Install-AgentFormat $sdd.Path }

  Show-GitignoreHint
  Show-Summary
}
finally {
  if ($sdd.Temporary) { Remove-Item -LiteralPath $sdd.Path -Recurse -Force -ErrorAction SilentlyContinue }
}
