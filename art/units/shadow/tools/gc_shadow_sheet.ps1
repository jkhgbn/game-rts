# G-C Shadow units: one before | after contact sheet JPG (quality 85) from docs/art/lab/gc_shadow/shots/<tag>_<shot>.png
# (gc_shadow_shots.gd). Usage: powershell -NoProfile -File art\units\shadow\tools\gc_shadow_sheet.ps1 [-Shots a,b,...]
param([string[]]$Shots = @("hall_z30", "hall_z10", "row_z7", "portrait_left", "portrait_right", "dark_z30"))
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$dir = Join-Path $root "docs\art\lab\gc_shadow\shots"
$w = 960; $h = 540
$sheet = New-Object System.Drawing.Bitmap ($w * 2), ($h * $Shots.Count)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object System.Drawing.Font "Arial", 16, ([System.Drawing.FontStyle]::Bold)
for ($i = 0; $i -lt $Shots.Count; $i++) {
	$col = 0
	foreach ($tag in "before", "after") {
		$p = Join-Path $dir ("{0}_{1}.png" -f $tag, $Shots[$i])
		if (Test-Path $p) {
			$img = [System.Drawing.Image]::FromFile($p)
			$g.DrawImage($img, $col * $w, $i * $h, $w, $h)
			$img.Dispose()
		}
		$g.DrawString(("{0} {1} (High)" -f $tag, $Shots[$i]), $font, [System.Drawing.Brushes]::White, ($col * $w + 10), ($i * $h + 8))
		$col++
	}
}
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 85L
$out = Join-Path (Split-Path -Parent $dir) "contact_sheet.jpg"
$sheet.Save($out, $enc, $ep)
$g.Dispose(); $sheet.Dispose()
Write-Output "sheet: $out"
