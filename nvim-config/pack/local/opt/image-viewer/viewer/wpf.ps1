# Image viewer window (WPF, built into Windows; nothing to install).
# Started by ../lua/image-viewer.lua. Reads the image path from <StateDir>\current.txt;
# ':quit' closes the window. Never takes focus; remembers position and size.
param([Parameter(Mandatory)][string]$StateDir)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$state   = Join-Path $StateDir 'current.txt'
$pidFile = Join-Path $StateDir 'viewer.pid'
$posFile = Join-Path $StateDir 'wpf.pos'   # Left,Top,Width,Height
Set-Content $pidFile $PID

$win = New-Object System.Windows.Window
$win.Title = 'image'
$win.WindowStyle = 'ToolWindow'      # thin frame, resizable, no taskbar button
$win.ShowInTaskbar = $false
$win.ShowActivated = $false          # don't steal focus from the terminal
$win.Topmost = $true
$win.Background = [System.Windows.Media.Brushes]::Black
$win.WindowStartupLocation = 'Manual'
$area = [System.Windows.SystemParameters]::WorkArea
$pos = if (Test-Path $posFile) { (Get-Content $posFile -Raw).Trim() -split ',' | ForEach-Object { [double]$_ } }
if ($pos.Count -eq 4 -and $pos[0] -lt $area.Right -and $pos[1] -lt $area.Bottom) {
    $win.Left, $win.Top, $win.Width, $win.Height = $pos
} else {
    $win.Width = 600; $win.Height = 500
    $win.Left = $area.Right - $win.Width; $win.Top = $area.Top
}

$img = New-Object System.Windows.Controls.Image
$img.Stretch = 'Uniform'
$win.Content = $img

$script:last = ''
function Show-Image($path) {
    # read fully into memory so the file stays free to be overwritten
    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
    $bmp.BeginInit()
    $bmp.CacheOption = 'OnLoad'
    $bmp.CreateOptions = 'IgnoreImageCache'
    $bmp.UriSource = New-Object System.Uri($path)
    $bmp.EndInit()
    $bmp.Freeze()
    $img.Source = $bmp
    $win.Title = Split-Path $path -Leaf
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(150)
$timer.Add_Tick({
    if (-not (Test-Path $state)) { return }
    $stamp = (Get-Item $state).LastWriteTimeUtc.Ticks
    $path = "$(Get-Content $state -Raw)".Trim()
    if ($path -eq ':quit') { $win.Close(); return }
    $key = "$path|$stamp"
    if ($key -eq $script:last -or -not $path -or -not (Test-Path $path)) { return }
    $script:last = $key
    try { Show-Image $path } catch { $win.Title = "error: $($_.Exception.Message)" }
})

$win.Add_Loaded({ $timer.Start() })
$win.Add_Closing({
    $timer.Stop()
    Set-Content $posFile ('{0},{1},{2},{3}' -f $win.Left, $win.Top, $win.Width, $win.Height)
})

try {
    $app = New-Object System.Windows.Application
    $app.ShutdownMode = 'OnMainWindowClose'
    [void]$app.Run($win)
} finally {
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}
exit 0
