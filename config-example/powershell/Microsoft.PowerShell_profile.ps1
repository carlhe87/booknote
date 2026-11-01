# PowerShell profile ($PROFILE). This folder (Documents\WindowsPowerShell) is a git repo.
# conda's hook lives in profile.ps1 next to this file (managed by `conda init`, not tracked).

# --- Aliases ---------------------------------------------------------------
Set-Alias v nvim

# --- Config locations ------------------------------------------------------
$NvimConfigDir = Join-Path $env:LOCALAPPDATA 'nvim'
$NvimConfig    = Join-Path $NvimConfigDir 'init.lua'

# --- Config snapshot -------------------------------------------------------
# Copy the current PowerShell + Neovim configs into booknote\config-example\
$BooknoteDir = Join-Path $HOME 'org\public\booknote'
function sync-config-to-booknote { & (Join-Path $BooknoteDir 'sync-config.ps1') @args }

# --- Bookmarks -------------------------------------------------------------
# Jump to a folder or open a file by name. Names/paths live in bookmarks.psd1 (next to this file).
#   j <name>  -> folder: cd there | file: cd to its folder (so nvim's :e / pickers are
#                relative to it) and open it in nvim. Run `popd` to return.
#   j         -> list all bookmarks
#   j marks   -> edit the bookmark file itself
$BookmarkFile = Join-Path $PSScriptRoot 'bookmarks.psd1'
function Get-Bookmarks { Import-PowerShellDataFile $BookmarkFile }

function j {
    param([string]$Name)
    $marks = Get-Bookmarks
    if (-not $Name) {
        $marks.GetEnumerator() | Sort-Object Name | Format-Table Name, Value -AutoSize
        return
    }
    if (-not $marks.ContainsKey($Name)) { Write-Warning "No bookmark '$Name'"; return }

    $path = [Environment]::ExpandEnvironmentVariables($marks[$Name])
    if     (Test-Path $path -PathType Container) { Push-Location $path }
    elseif (Test-Path $path -PathType Leaf)      { Push-Location (Split-Path $path); nvim $path }
    else   { Write-Warning "Path not found: $path" }
}

# Tab completion reads names from bookmarks.psd1, so new entries need no code change
Register-ArgumentCompleter -CommandName j -ParameterName Name -ScriptBlock {
    param($cmd, $param, $word)
    (Get-Bookmarks).Keys | Where-Object { $_ -like "$word*" } | Sort-Object |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}
