# G-B Shadow: one before | after contact sheet JPG (quality 85) from docs/art/lab/gb_shadow/<tag>_q<q>_<shot>.png.
# Usage: powershell -NoProfile -File art\buildings\shadow_tools\gb_shadow_sheet.ps1 [-Q 2] [-Shots base_z10,base_z30,base_z50,tiers_z30]
param([int]$Q = 2, [string[]]$Shots = @("base_z10", "base_z30", "base_z50", "tiers_z30", "dmg_z10"))
Add-Type -AssemblyName System.Drawing
$dir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "docs\art\lab\gb_shadow"
$w = 960; $h = 528
$sheet = New-Object System.Drawing.Bitmap ($w * 2), ($h * $Shots.Count)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object System.Drawing.Font "Arial", 16, ([System.Drawing.FontStyle]::Bold)
for ($i = 0; $i -lt $Shots.Count; $i++) {
	$col = 0
	foreach ($tag in "before", "after") {
		$p = Join-Path $dir ("{0}_q{1}_{2}.png" -f $tag, $Q, $Shots[$i])
		if (Test-Path $p) {
			$img = [System.Drawing.Image]::FromFile($p)
			$g.DrawImage($img, $col * $w, $i * $h, $w, $h)
			$img.Dispose()
		}
		$g.DrawString(("{0} q{1} {2}" -f $tag, $Q, $Shots[$i]), $font, [System.Drawing.Brushes]::White, ($col * $w + 10), ($i * $h + 8))
		$col++
	}
}
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 85L
$out = Join-Path $dir ("contact_sheet_q{0}.jpg" -f $Q)
$sheet.Save($out, $enc, $ep)
$g.Dispose(); $sheet.Dispose()
Write-Output "sheet: $out"
