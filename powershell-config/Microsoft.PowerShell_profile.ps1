# PowerShell profile ($PROFILE). Developed in proj\powershell-config; each machine's
# Documents\WindowsPowerShell is a clone that pulls updates. Edit the dev repo, not the clone.
# Load order: session settings here -> shared commands (Modules\HaseTools) -> local.ps1
# (this machine only, git-ignored), which runs last and can override anything above.
# conda is loaded lazily below, not by `conda init`'s hook in profile.ps1 (which cost ~2 s per startup).

# --- Config locations (read by HaseTools; override in local.ps1) -----------
$NvimConfigDir     = Join-Path $env:LOCALAPPDATA 'nvim'
$NvimConfig        = Join-Path $NvimConfigDir 'init.lua'
$EmacsConfigDir    = Join-Path $HOME 'emacs-config'          # live clone of emacs-config
$EmacsConfigDevDir = Join-Path $HOME 'proj\emacs-config'     # dev repo

# --- conda -----------------------------------------------------------------
# Load conda's PowerShell module the first time `conda` runs, not at startup: its hook
# starts conda.exe (Python) and took ~2 s of a ~2.4 s startup. Skipped where conda is absent.
# On a machine with conda, run `conda init --reverse powershell` so its eager hook is gone.
$CondaExe = Join-Path $HOME 'miniforge3\Scripts\conda.exe'
if (Test-Path $CondaExe) {
    function global:conda {
        Remove-Item Function:\conda
        $hook = (& $CondaExe shell.powershell hook | Out-String) -replace 'Import-Module ', 'Import-Module -Global '
        Invoke-Expression $hook
        conda @args
    }
}

# --- Session settings ------------------------------------------------------
Set-Alias v nvim

# Editor for tools that shell out to one (Claude Code's Ctrl+G, git, ...).
$env:EDITOR = 'nvim'

# --- Shared commands -------------------------------------------------------
# Imported by path, not autoloaded, so a dev run loads this repo's copy and `j`'s
# tab completion is registered at startup. -DisableNameChecking: `j`, `nvim-dev`, ...
# don't use approved verbs.
Import-Module (Join-Path $PSScriptRoot 'Modules\HaseTools') -DisableNameChecking

# --- This machine ----------------------------------------------------------
# local.ps1 (from local-template.ps1) is git-ignored; dot-sourced so it shares this scope.
$LocalProfile = Join-Path $PSScriptRoot 'local.ps1'
if (Test-Path $LocalProfile) { . $LocalProfile }
