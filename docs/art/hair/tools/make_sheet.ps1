# Hair review sheet: one row per character (head 3/4 | body 3/4 | 25 m game view | 40 m game view | score).
# Usage: .\docs\art\hair\tools\make_sheet.ps1 -Dir docs\art\hair\before -Out docs\art\hair\before\sheet.png -Title "..." [-Scores scores.csv] [-Names a,b]
# scores.csv columns: name,label,score,status,note   (status: green / yellow / red / n/a)
param(
	[string]$Dir,
	[string]$Out,
	[string]$Title = "Hair review",
	[string]$Scores = "",
	[string[]]$Names = @("vessa","malrik","torvald","ysolde","cinder_hand","gloom_thrall","rime_hauler","sprigling")
)
Add-Type -AssemblyName System.Drawing
$tile = 300; $zt = 300; $pad = 8; $labelW = 330; $head = 70
$rows = $Names.Count
$w = $labelW + 4 * ($tile + $pad) + $pad
$h = $head + $rows * ($tile + $pad) + $pad + 34
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear([System.Drawing.Color]::FromArgb(27, 26, 31))
$fT = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$fN = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$fS = New-Object System.Drawing.Font("Segoe UI", 10)
$fB = New-Object System.Drawing.Font("Segoe UI", 26, [System.Drawing.FontStyle]::Bold)
$white = [System.Drawing.Brushes]::WhiteSmoke; $grey = [System.Drawing.Brushes]::Silver
$g.DrawString($Title, $fT, $white, 10, 8)
$cols = @("head close-up 3/4", "full body 3/4", "game cam 25 m (1080p crop, x1.4)", "game cam 40 m (1080p crop, x1.9)")
for ($c = 0; $c -lt 4; $c++) { $g.DrawString($cols[$c], $fS, $grey, $labelW + $c * ($tile + $pad) + 4, 46) }
$sc = @{}
if ($Scores -ne "" -and (Test-Path $Scores)) { Import-Csv $Scores | ForEach-Object { $sc[$_.name] = $_ } }
$colors = @{ green = [System.Drawing.Color]::FromArgb(70, 170, 90); yellow = [System.Drawing.Color]::FromArgb(220, 180, 40);
	red = [System.Drawing.Color]::FromArgb(210, 60, 50); "n/a" = [System.Drawing.Color]::FromArgb(110, 110, 120) }
for ($r = 0; $r -lt $rows; $r++) {
	$n = $Names[$r]; $y = $head + $r * ($tile + $pad)
	$label = $n; $note = ""; $score = ""; $status = ""
	if ($sc.ContainsKey($n)) { $label = $sc[$n].label; $note = $sc[$n].note; $score = $sc[$n].score; $status = $sc[$n].status }
	$g.DrawString($label, $fN, $white, 10, $y + 6)
	if ($status -ne "") {
		$br = New-Object System.Drawing.SolidBrush $colors[$status]
		$g.FillRectangle($br, 10, $y + 40, 130, 56)
		$txt = if ($score -ne "") { "$score" } else { "-" }
		$g.DrawString($txt, $fB, [System.Drawing.Brushes]::Black, 16, $y + 46)
		$g.DrawString($status.ToUpper(), $fS, [System.Drawing.Brushes]::Black, 84, $y + 62)
	}
	if ($note -ne "") { $g.DrawString($note, $fS, $grey, (New-Object System.Drawing.RectangleF 10, ($y + 104), ($labelW - 16), ($tile - 104))) }
	$shots = @("head", "body", "z25", "z40")
	for ($c = 0; $c -lt 4; $c++) {
		$p = Join-Path $Dir ("{0}_{1}.png" -f $n, $shots[$c])
		$x = $labelW + $c * ($tile + $pad)
		if (Test-Path $p) {
			$img = [System.Drawing.Image]::FromFile((Resolve-Path $p))
			if ($c -ge 2) { $g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half' } else { $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'Default' }
			$side = [Math]::Min($img.Width, $img.Height)
			$src = New-Object System.Drawing.Rectangle ([int](($img.Width - $side) / 2)), ([int](($img.Height - $side) / 2)), $side, $side
			if ($c -ge 2) { $half = [int]($side / 2); $src = New-Object System.Drawing.Rectangle ([int](($img.Width - $half) / 2)), ([int](($img.Height - $half) / 2)), $half, $half }
			$g.DrawImage($img, (New-Object System.Drawing.Rectangle $x, $y, $tile, $tile), $src, [System.Drawing.GraphicsUnit]::Pixel)
			$img.Dispose()
		} else { $g.DrawString("(missing)", $fS, $grey, $x + 8, $y + 8) }
	}
}
$g.DrawString("Score = hair rubric in docs/art/hair-redesign-plan.md (25 m read 25, silhouette hook 20, shape craft 25, palette / contrast 15, fit / clipping 15). Green >= 70, yellow 50-69, red < 50.", $fS, $grey, 10, $h - 28)
$g.Dispose()
$bmp.Save((Join-Path (Get-Location) $Out), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"sheet -> $Out"

