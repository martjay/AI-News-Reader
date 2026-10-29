Add-Type -AssemblyName System.Drawing

function New-Mark([int]$size) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::FromArgb(31, 78, 90))
  $paper = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(244, 241, 234))
  $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(31, 78, 90))
  $line = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(31, 78, 90), [Math]::Max(1, $size / 42.0))
  $pad = [int]($size * 0.18)
  $g.FillRectangle($paper, $pad, $pad, $size - 2 * $pad, $size - 2 * $pad)
  $y1 = [int]($size * 0.38)
  $y2 = [int]($size * 0.50)
  $y3 = [int]($size * 0.62)
  $x1 = [int]($size * 0.30)
  $x2 = [int]($size * 0.70)
  $g.DrawLine($line, $x1, $y1, $x2, $y1)
  $g.DrawLine($line, $x1, $y2, [int]($size * 0.58), $y2)
  $g.DrawLine($line, $x1, $y3, $x2, $y3)
  $dot = [int]($size * 0.08)
  $g.FillEllipse($ink, [int]($size * 0.62), [int]($size * 0.66), $dot, $dot)
  $g.Dispose()
  $paper.Dispose()
  $ink.Dispose()
  $line.Dispose()
  return $bmp
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pngPath = Join-Path $root "app_icon.png"
$icoPath = Join-Path $root "app_icon.ico"
$bmp = New-Mark 1024
$bmp.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)

$iconBmp = New-Mark 256
$h = $iconBmp.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($h)
$fs = [System.IO.File]::Create($icoPath)
$icon.Save($fs)
$fs.Close()
$icon.Dispose()
$iconBmp.Dispose()
$bmp.Dispose()
Write-Host "[OK] Wrote $pngPath and $icoPath"
