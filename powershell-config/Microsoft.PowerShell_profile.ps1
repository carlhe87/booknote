# PowerShell profile ($PROFILE). Developed in proj\powershell-config; each machine's
# Documents\WindowsPowerShell is a clone that pulls updates. Edit the dev repo, not the clone.
# conda is loaded lazily below, not by `conda init`'s hook in profile.ps1 (which cost ~2 s per startup).

# --- Config locations ------------------------------------------------------
$NvimConfigDir = Join-Path $env:LOCALAPPDATA 'nvim'
$NvimConfig    = Join-Path $NvimConfigDir 'init.lua'
$EmacsConfigDir    = Join-Path $HOME 'emacs-config'          # live clone of emacs-config
$EmacsConfigDevDir = Join-Path $HOME 'proj\emacs-config'     # dev repo

# --- Updates ---------------------------------------------------------------
# Pull the latest profile from GitHub into this clone. Restart PowerShell afterwards.
function Update-Profile { git -C $PSScriptRoot pull --ff-only }
# Pull the latest Neovim config into its live clone. Then :restart nvim; see the
# nvim-config README for syncing plugins to a changed lockfile.
function Update-NvimConfig { git -C $NvimConfigDir pull --ff-only }
# Pull the latest own Emacs config into its live clone. Then restart emacs-own.
function Update-EmacsConfig { git -C $EmacsConfigDir pull --ff-only }

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

# --- Aliases ---------------------------------------------------------------
Set-Alias v nvim

# Editor for tools that shell out to one (Claude Code's Ctrl+G, git, ...).
$env:EDITOR = 'nvim'

# Run Neovim with the dev config (%LOCALAPPDATA%\nvim-dev, a junction to
# ~/proj/nvim-config; see its README). The live config is not touched.
function nvim-dev {
    $env:NVIM_APPNAME = 'nvim-dev'
    try { nvim @args } finally { Remove-Item Env:NVIM_APPNAME }
}

# My own Emacs config (emacs-config, built up from vanilla), alongside Doom (plain `emacs`).
# runemacs starts the GUI without blocking the terminal.
function emacs-own     { runemacs "--init-directory=$($EmacsConfigDir -replace '\\', '/')" @args }
function emacs-own-dev { runemacs "--init-directory=$($EmacsConfigDevDir -replace '\\', '/')" @args }

# --- Config snapshot -------------------------------------------------------
# Copy the dev configs into booknote\<name>-config\ with each dev repo's publish.ps1
function sync-config-to-booknote {
  foreach ($name in 'nvim-config', 'powershell-config') {
    $script = Join-Path $HOME "proj\$name\publish.ps1"
    if (Test-Path $script) { & $script }
  }
}

# --- Bookmarks -------------------------------------------------------------
# Jump to a folder or open a file by name. Bookmarks come from two files next to this one:
#   bookmarks.psd1        shared by all machines (tracked in git)
#   bookmarks-local.psd1  this machine only (git-ignored); wins on duplicate names.
#                         Created from bookmarks-local-template.psd1 on first use.
#   j <name>  -> folder: cd there | file: cd to its folder (so nvim's :e / pickers are
#                relative to it) and open it in nvim. Run `popd` to return.
#   j         -> list all bookmarks sorted by path, with type (folder / file / missing)
#                and the file each comes from (shared / local)
#   j marks   -> edit this machine's bookmarks-local.psd1
# The files are re-read on every call, so edits take effect without reloading the profile.
$LocalBookmarkTemplate = Join-Path $PSScriptRoot 'bookmarks-local-template.psd1'
# Layers in load order; a later layer overrides an earlier one on duplicate names.
$BookmarkLayers = [ordered]@{
    shared = Join-Path $PSScriptRoot 'bookmarks.psd1'
    local  = Join-Path $PSScriptRoot 'bookmarks-local.psd1'
}

# Returns name -> @{ Path; Source }, merged from all layers.
function Get-Bookmarks {
    if (-not (Test-Path $BookmarkLayers.local) -and (Test-Path $LocalBookmarkTemplate)) {
        Copy-Item $LocalBookmarkTemplate $BookmarkLayers.local
    }
    $marks = @{}
    foreach ($layer in $BookmarkLayers.GetEnumerator()) {
        if (-not (Test-Path $layer.Value)) { continue }
        $data = Import-PowerShellDataFile $layer.Value
        foreach ($key in $data.Keys) {
            $source = if ($marks.ContainsKey($key)) { "$($layer.Name) (overrides $($marks[$key].Source))" } else { $layer.Name }
            $marks[$key] = @{ Path = $data[$key]; Source = $source }
        }
    }
    $marks
}

function j {
    param([string]$Name)
    $marks = Get-Bookmarks
    if (-not $Name) {
        # Sorted by expanded path, so bookmarks in the same area are listed together
        $marks.GetEnumerator() | ForEach-Object {
            $full = [Environment]::ExpandEnvironmentVariables($_.Value.Path).TrimEnd('\')
            $type = if (Test-Path $full -PathType Container) { 'folder' }
                    elseif (Test-Path $full -PathType Leaf)  { 'file' }
                    else                                     { 'missing' }
            [pscustomobject]@{ Name = $_.Name; Type = $type; Source = $_.Value.Source; Path = $_.Value.Path; Full = $full }
        } | Sort-Object Full, Name | Format-Table Name, Type, Source, Path -AutoSize
        return
    }
    if (-not $marks.ContainsKey($Name)) { Write-Warning "No bookmark '$Name'"; return }

    $path = [Environment]::ExpandEnvironmentVariables($marks[$Name].Path)
    if     (Test-Path $path -PathType Container) { Push-Location $path }
    elseif (Test-Path $path -PathType Leaf)      { Push-Location (Split-Path $path); nvim $path }
    else   { Write-Warning "Path not found: $path" }
}

# Tab completion reads names from all bookmark files, so new entries need no code change
Register-ArgumentCompleter -CommandName j -ParameterName Name -ScriptBlock {
    param($cmd, $param, $word)
    (Get-Bookmarks).Keys | Where-Object { $_ -like "$word*" } | Sort-Object |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}
