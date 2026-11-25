# HaseTools: the shared commands of this profile (bookmarks, config updates, launchers).
# Imported by Microsoft.PowerShell_profile.ps1; session settings (aliases, $env:EDITOR,
# the conda stub) stay in the profile. Machine-specific changes go in local.ps1.
#
# Config locations are read from global variables at call time, so local.ps1 can
# override them. Defaults (set in the profile):
#   $NvimConfigDir      live Neovim config        %LOCALAPPDATA%\nvim
#   $EmacsConfigDir     live clone of emacs-config  ~\emacs-config
#   $EmacsConfigDevDir  dev repo of emacs-config    ~\proj\emacs-config

# The repo (or live clone) this module sits in: <root>\Modules\HaseTools
$RepoRoot = Split-Path (Split-Path $PSScriptRoot)

# --- Updates ---------------------------------------------------------------
# Pull the latest profile from GitHub into this clone. Restart PowerShell afterwards.
function Update-Profile { git -C $RepoRoot pull --ff-only }
# Pull the latest Neovim config into its live clone. Then :restart nvim; see the
# nvim-config README for syncing plugins to a changed lockfile.
function Update-NvimConfig { git -C $NvimConfigDir pull --ff-only }
# Pull the latest own Emacs config into its live clone. Then restart emacs-own.
function Update-EmacsConfig { git -C $EmacsConfigDir pull --ff-only }

# --- Launchers -------------------------------------------------------------
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

# --- Bookmarks -------------------------------------------------------------
# Jump to a folder or open a file by name. Bookmarks come from two files in the repo root:
#   bookmarks.psd1        shared by all machines (tracked in git)
#   bookmarks-local.psd1  this machine only (git-ignored); wins on duplicate names.
#                         Created from bookmarks-local-template.psd1 on first use.
#   j <name>  -> folder: cd there | file: cd to its folder (so nvim's :e / pickers are
#                relative to it) and open it: text in nvim, binary (docx, xlsx, pdf,
#                images, ...) in the system's default app. Prints the full path.
#                Run `popd` to return.
#   j         -> list all bookmarks sorted by path, with type (folder / file / missing)
#                and the file each comes from (shared / local)
#   j marks   -> edit this machine's bookmarks-local.psd1
#   jp <name> -> output the bookmark's full path, nothing else, so it composes:
#                Copy-Item (jp report) D:\   |   jp report | Set-Clipboard
#   jp        -> output all bookmarks as objects (Name, Path), e.g. jp | Where-Object Path -like *.org
#   $jLastPath   full path of the last folder or file `j <name>` went to
# The files are re-read on every call, so edits take effect without reloading the profile.
$LocalBookmarkTemplate = Join-Path $RepoRoot 'bookmarks-local-template.psd1'
# Layers in load order; a later layer overrides an earlier one on duplicate names.
$BookmarkLayers = [ordered]@{
    shared = Join-Path $RepoRoot 'bookmarks.psd1'
    local  = Join-Path $RepoRoot 'bookmarks-local.psd1'
}

# Files `j` opens in the default app instead of nvim. Other extensions are checked by
# content (Test-BinaryFile); these are listed because they can pass as text (.rtf) or
# need not have a NUL byte near the start (.pdf).
$DefaultAppExtensions = '.pdf', '.rtf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
                        '.odt', '.ods', '.odp'

# True if the file looks binary: a NUL byte in its first 8000 bytes (git's test).
# UTF-16 text has NULs too, so a UTF-16 byte order mark counts as text.
function Test-BinaryFile([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    try {
        $buf = New-Object byte[] 8000
        $n = $stream.Read($buf, 0, $buf.Length)
    } finally { $stream.Dispose() }
    if ($n -ge 2 -and (($buf[0] -eq 0xFF -and $buf[1] -eq 0xFE) -or ($buf[0] -eq 0xFE -and $buf[1] -eq 0xFF))) { return $false }
    [Array]::IndexOf($buf, [byte]0, 0, $n) -ge 0
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
    # CmdletBinding gives $PSCmdlet, whose SessionState is the caller's. A plain
    # Push-Location here would push onto the module's own stack, out of reach of `popd`.
    [CmdletBinding()]
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

    $path = Resolve-BookmarkPath $marks[$Name].Path
    if (Test-Path $path) {
        # Full path of the last folder or file j went to, for later commands,
        # e.g. `Copy-Item $jLastPath D:\backup` or `Get-Item $jLastPath`.
        $global:jLastPath = $path
        # Shown, not output: j's job is to go there; jp is the one to compose with.
        Write-Host $path -ForegroundColor DarkGray
    }
    $caller = $PSCmdlet.SessionState.Path
    if     (Test-Path $path -PathType Container) { $null = $caller.PushCurrentLocation(''); Set-Location $path }
    elseif (Test-Path $path -PathType Leaf) {
        $null = $caller.PushCurrentLocation(''); Set-Location (Split-Path $path)
        if ($DefaultAppExtensions -contains [IO.Path]::GetExtension($path) -or (Test-BinaryFile $path)) {
            Invoke-Item $path   # default app, like a double-click in Explorer
        } else {
            nvim $path
        }
    }
    else   { Write-Warning "Path not found: $path" }
}

# Full path for a bookmark's stored path: %VAR% expanded, normalized.
function Resolve-BookmarkPath([string]$Path) {
    [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Path))
}

# Output a bookmark's full path (or, with no name, all bookmarks as objects).
# Writes only the path, so it can go in () or a pipeline. The path is output even if
# it doesn't exist yet, so it can be created: New-Item (jp todo).
function jp {
    param([string]$Name)
    $marks = Get-Bookmarks
    if (-not $Name) {
        $marks.GetEnumerator() | Sort-Object Name | ForEach-Object {
            [pscustomobject]@{ Name = $_.Name; Path = Resolve-BookmarkPath $_.Value.Path }
        }
        return
    }
    if (-not $marks.ContainsKey($Name)) { Write-Error "No bookmark '$Name'"; return }
    Resolve-BookmarkPath $marks[$Name].Path
}

# Tab completion reads names from all bookmark files, so new entries need no code change
Register-ArgumentCompleter -CommandName j, jp -ParameterName Name -ScriptBlock {
    param($cmd, $param, $word)
    (Get-Bookmarks).Keys | Where-Object { $_ -like "$word*" } | Sort-Object |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}
