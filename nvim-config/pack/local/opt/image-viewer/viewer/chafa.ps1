# Image viewer pane for Windows Terminal: draws images as sixel with chafa.
# Started by ../lua/image-viewer.lua in a WT split. Reads the image path from
# <StateDir>\current.txt; ':quit' exits, and WT closes the pane.
param([Parameter(Mandatory)][string]$StateDir)
$state   = Join-Path $StateDir 'current.txt'
$pidFile = Join-Path $StateDir 'viewer.pid'
Set-Content -Path $pidFile -Value $PID
$last = ''
try {
    while ($true) {
        if (Test-Path $state) {
            $stamp = (Get-Item $state).LastWriteTimeUtc.Ticks
            $img = "$(Get-Content $state -Raw)".Trim()
            if ($img -eq ':quit') { break }
            $key = "$img|$stamp"
            if ($key -ne $last -and $img -and (Test-Path $img)) {
                $last = $key
                Clear-Host
                $w = $Host.UI.RawUI.WindowSize
                chafa -f sixels -s "$($w.Width)x$($w.Height - 2)" $img
                Write-Host (Split-Path $img -Leaf) -ForegroundColor DarkGray
            }
        }
        Start-Sleep -Milliseconds 150
    }
} finally {
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}
exit 0
