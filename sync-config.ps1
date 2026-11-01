<#
.SYNOPSIS
  Copy my current PowerShell and Neovim configs into booknote\config-example\.

.DESCRIPTION
  Each run mirrors the live config folders into:
    config-example\powershell\   <- Documents\WindowsPowerShell
    config-example\nvim\         <- $env:LOCALAPPDATA\nvim
  Each target folder is rebuilt from scratch, so deleted/renamed files don't linger.
  Only files git does not ignore are copied (skips swap files, *.bak, conda's profile.ps1, ...).
  Nothing is committed; review with `git status` in booknote.

.EXAMPLE
  .\sync-config.ps1        # or `sync-config` from anywhere (function in $PROFILE)
#>
$ErrorActionPreference = 'Stop'

$dest = Join-Path $PSScriptRoot 'config-example'
$sources = [ordered]@{
  powershell = Split-Path $PROFILE            # Documents\WindowsPowerShell
  nvim       = Join-Path $env:LOCALAPPDATA 'nvim'
}

foreach ($name in $sources.Keys) {
  $src    = $sources[$name]
  $target = Join-Path $dest $name
  if (-not (Test-Path $src)) { Write-Warning "Skipping $name - not found: $src"; continue }

  # Files to copy: tracked + untracked-but-not-ignored if it's a git repo, else everything
  if (Test-Path (Join-Path $src '.git')) {
    $files = git -C $src ls-files --cached --others --exclude-standard
    if ($LASTEXITCODE) { throw "git ls-files failed in $src" }
  } else {
    $files = Get-ChildItem $src -Recurse -File |
      ForEach-Object { $_.FullName.Substring($src.Length + 1) }
  }

  # Rebuild the target folder so it exactly matches the source
  if (Test-Path $target) { Remove-Item $target -Recurse -Force }
  foreach ($rel in $files) {
    $from = Join-Path $src $rel
    if (-not (Test-Path $from -PathType Leaf)) { continue }   # deleted but not yet committed
    $to = Join-Path $target $rel
    New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
    Copy-Item $from $to -Force
  }
  Write-Host ("{0,-11} {1} file(s) from {2}" -f $name, @($files).Count, $src) -ForegroundColor Cyan
}

Write-Host "`nChanges in booknote:" -ForegroundColor Cyan
git -C $PSScriptRoot status --short -- config-example
