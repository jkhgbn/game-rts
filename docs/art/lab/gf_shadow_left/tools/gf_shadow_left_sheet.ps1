# G-F Shadow leftovers: before | after contact sheet JPG + key PNGs from docs/art/lab/gf_shadow_left/<tag>/<shot>.jpg.
# Usage: powershell -NoProfile -File docs\art\lab\gf_shadow_left\tools\gf_shadow_left_sheet.ps1
param(
	[string[]]$Shots = @("tower_p_z12", "tower_e_z12", "tower_p_z6", "base_shadow_p_z30", "sites_shadow_z24",
		"site_hall_p000_z18", "site_hall_p035_z18", "site_hovel_p000_z14", "site_tower_p000_z12", "site_tower_p050_z12"),
	[string[]]$Keys = @("tower_p_z12", "tower_e_z12", "site_tower_p000_z12", "site_hall_p000_z18")
)
Add-Type -AssemblyName System.Drawing
$dir = Split-Path -Parent $PSScriptRoot
$font = New-Object System.Drawing.Font "Arial", 16, ([System.Drawing.FontStyle]::Bold)

function Draw-Pair($g, [string]$shot, [int]$row, [int]$w, [int]$h) {
	$col = 0
	foreach ($tag in "before", "after") {
		$p = Join-Path $dir ("{0}\{1}.jpg" -f $tag, $shot)
		if (Test-Path $p) {
			$img = [System.Drawing.Image]::FromFile($p)
			$g.DrawImage($img, $col * $w, $row * $h, $w, $h)
			$img.Dispose()
		}
		$g.DrawString(("{0}  {1}" -f $tag, $shot), $font, [System.Drawing.Brushes]::White, ($col * $w + 10), ($row * $h + 8))
		$col++
	}
}

$w = 800; $h = 450
$sheet = New-Object System.Drawing.Bitmap ($w * 2), ($h * $Shots.Count)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
for ($i = 0; $i -lt $Shots.Count; $i++) { Draw-Pair $g $Shots[$i] $i $w $h }
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 85L
$out = Join-Path $dir "gf_shadow_left_contact_sheet.jpg"
$sheet.Save($out, $enc, $ep)
$g.Dispose(); $sheet.Dispose()
Write-Output "sheet: $out"

foreach ($k in $Keys) {
	$kb = New-Object System.Drawing.Bitmap ($w * 2), $h
	$kg = [System.Drawing.Graphics]::FromImage($kb)
	$kg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	Draw-Pair $kg $k 0 $w $h
	$kp = Join-Path $dir ("gf_shadow_left_key_{0}.png" -f $k)
	$kb.Save($kp, [System.Drawing.Imaging.ImageFormat]::Png)
	$kg.Dispose(); $kb.Dispose()
	Write-Output "key: $kp"
}
