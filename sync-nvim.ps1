<#
.SYNOPSIS
  Copy my Neovim config from the nvim-config repo into booknote.

.DESCRIPTION
  Workflow after changing the config:
    1. Commit + push in $env:LOCALAPPDATA\nvim   (private repo carlhe87/nvim-config)
    2. .\sync-nvim.ps1                            copy files, show what changed
    3. Update neovim-setup-guide.md / neovim-packages-cheatsheet.md
    4. .\sync-nvim.ps1 -Commit                    commit everything + push booknote

  The commit message records the nvim-config commit the docs describe:
    "Sync from nvim-config@<hash>"
#>
param(
  [switch]$Commit   # commit all booknote changes and push
)

$ErrorActionPreference = 'Stop'
$src   = Join-Path $env:LOCALAPPDATA 'nvim'
$dst   = $PSScriptRoot
$files = @('init.lua', 'nvim-pack-lock.json')

# The source must be committed and pushed, so the recorded hash means something
$dirty = git -C $src status --porcelain
if ($dirty) {
  throw "nvim-config has uncommitted changes. Commit them first:`n$($dirty -join "`n")"
}
git -C $src fetch --quiet origin
$ahead = git -C $src rev-list --count '@{u}..HEAD'
if ([int]$ahead -gt 0) {
  throw "nvim-config has $ahead unpushed commit(s). Run 'git push' in $src first."
}
$hash = git -C $src rev-parse --short HEAD

foreach ($f in $files) {
  Copy-Item (Join-Path $src $f) (Join-Path $dst $f) -Force
}

Write-Host "Synced from nvim-config@$hash" -ForegroundColor Cyan
git -C $dst status --short
git -C $dst diff --stat -- $files

if ($Commit) {
  if (-not (git -C $dst status --porcelain)) {
    Write-Host 'Nothing to commit.'
    return
  }
  git -C $dst add -A
  git -C $dst commit -m "Sync from nvim-config@$hash"
  git -C $dst push
} else {
  Write-Host "`nNext: update the .md files, then run .\sync-nvim.ps1 -Commit"
}
