# Copy the configs in this repo to their live locations with robocopy.
#
#   .\deploy.ps1           # copy nvim-config and powershell-config
#   .\deploy.ps1 -DryRun   # list what would be copied, change nothing
#   .\deploy.ps1 -Force    # also copy into a live folder that is a git clone
#
# Uses /E (add and update), never /MIR: files only in the live folder, such as
# local.ps1, bookmarks.psd1 or profile.ps1, are left alone. /XO skips files
# whose live copy is newer.
# Runs on Windows PowerShell 5.1.

param(
    [switch]$DryRun,
    [switch]$Force
)

$documents = [Environment]::GetFolderPath('MyDocuments')

$targets = @(
    @{ Source = Join-Path $PSScriptRoot 'nvim-config'
       Dest   = Join-Path $env:LOCALAPPDATA 'nvim' },
    @{ Source = Join-Path $PSScriptRoot 'powershell-config'
       Dest   = Join-Path $documents 'WindowsPowerShell' }
)

$failed = $false

foreach ($t in $targets) {
    Write-Host "`n== $($t.Source) -> $($t.Dest)" -ForegroundColor Cyan

    if (-not (Test-Path $t.Source)) {
        Write-Warning "Source missing, skipped."
        continue
    }

    # A live folder that is a git clone updates with git pull; copied files
    # would make it dirty and block the next pull.
    if ((Test-Path (Join-Path $t.Dest '.git')) -and -not $Force) {
        Write-Warning "Destination is a git clone, skipped (update it with git pull, or use -Force)."
        continue
    }

    # /XO: never replace a live file that is newer than the copy here.
    $options = @('/E', '/XO', '/XD', '.git', '/NP', '/NDL')
    if ($DryRun) { $options += '/L' }

    Robocopy.exe $t.Source $t.Dest @options

    # robocopy: 0-7 is success (1 = files copied), 8 or higher is an error.
    if ($LASTEXITCODE -ge 8) {
        Write-Warning "robocopy failed with exit code $LASTEXITCODE."
        $failed = $true
    }
}

if ($failed) { exit 1 }
exit 0
