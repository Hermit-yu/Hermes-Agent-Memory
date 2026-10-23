# Takes a PNG screenshot of the primary display.
# NOTE: Requires an interactive desktop session (won't work if run as a background service without access to the logged-in desktop).

param(
  [string]$OutPath = "E:\OpenClawAI_bot\workspace\media\desktop_screenshot.png"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$graphics = [System.Drawing.Graphics]::FromImage($bmp)

try {
  $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
  $dir = Split-Path -Parent $OutPath
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Output $OutPath
}
finally {
  $graphics.Dispose()
  $bmp.Dispose()
}
