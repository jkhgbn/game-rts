# G3b (docs/art/g3b_materials.md): writes `shader_parameter/surface_kind = N` into every unit material on the kit's
# unit_painted.gdshader (art/units/**, except art/units/wizards/ = G3a's), from keywords in the material file name.
# Kinds (unit_paint.gdshaderinc): 0 plain, 1 cloth, 2 metal, 3 leather, 4 skin, 5 wood, 6 fur / hair / hide, 7 bone / horn / stone.
# No keyword = no line (the shader's auto: spec_strength >= 0.15 -> metal, else plain). Re-running replaces the line
# (safe). Keeps each file's line endings. Usage: powershell -NoProfile -File art\units\kit\tools\assign_surface_kinds.ps1 [-DryRun]
param([switch]$DryRun)
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$units = Join-Path $root "art\units"
# First match wins (order matters: "leaf_gold" is a leaf, "gold_trim" a metal).
$rules = @(
	@(0, 'eye|glass|crystal|wisp|smoke|ash_ball|leaf|blossom|moss|mud|earth|grave|spot|gills|cap_rim|mouth|nose|mask|string|frill|wither|thorn|burr'),
	@(2, 'gunmetal|metal|iron|steel|bronze|silver|gold|brass|copper|blade|rust|obsidian|plate|trim'),
	@(3, 'leather|oilskin|strap|belt|boot|saddle|scale'),
	@(4, 'skin|muzzle|belly'),
	@(5, 'wood|bark|oak|grain|shaft|_bow|stalk|root|hollow'),
	@(6, 'fur|hair|mane|ruff|bristle|fletch|wool|pelt|chestnut'),
	@(7, 'bone|ivory|tusk|horn|antler|teeth|claw|tip|shell|stone|granite|scar'),
	@(1, 'cloth|felt|wrap|burlap|padding|jerkin|shroud|robe|tabard|hood|hat|coat|sec_|burgundy|charcoal')
)
$beastDirs = '\\(mounts|neutral|titans)\\'
$n = 0
Get-ChildItem -Path $units -Recurse -Filter *.tres | Where-Object { $_.FullName -notmatch '\\art\\units\\wizards\\' } | ForEach-Object {
	$f = $_.FullName
	$text = [IO.File]::ReadAllText($f)
	if ($text -notmatch 'unit_painted\.gdshader') { return }
	# A garbled value line (seen 2026-10-15 on the stagrunner materials: `rim_strength = 0.95, 1.0, 0.8S`) stops the
	# loader there, so a line appended after it would be ignored: leave those files to their owner.
	if ($text -match '(?m)^shader_parameter/\w+ = [-\d.]+, ') { Write-Output "SKIP (garbled value line) $f"; return }
	$name = $_.BaseName.ToLower()
	# Match the PART of the name: drop the owner prefix (the unit folder: "tusker_hide" -> "hide") or a palette prefix.
	$dir = $_.Directory
	if ($dir.Name -eq "materials") { $dir = $dir.Parent }
	$part = $name
	if ($part.StartsWith($dir.Name.ToLower() + "_")) { $part = $part.Substring($dir.Name.Length + 1) }
	$part = $part -replace '^(fire|ice|nature|shadow|unit|warden|weapon)_', ''
	$kind = -1
	if ($part -match '^sec_') { $kind = 1 }
	else {
		foreach ($r in $rules) {
			if ($part -match $r[1]) { $kind = $r[0]; break }
		}
	}
	# Animal coats / hides are short fur, not clothes.
	if ($f -match $beastDirs -and $part -match 'coat|hide|pale|dark|chestnut') { if ($kind -eq 1 -or $kind -eq 3 -or $kind -eq -1) { $kind = 6 } }
	if ($part -match '(^|_)hide($|_)' -and $kind -eq -1) { $kind = 6 }
	$clean = [regex]::Replace($text, "\r?\nshader_parameter/surface_kind = -?\d+", "")
	if ($kind -ge 0) {
		$nl = "`n"
		if ($clean -match "\r\n\s*$") { $nl = "`r`n" }
		$trail = ""
		if ($clean -match "\n$") { $trail = $nl }
		$body = $clean.TrimEnd("`r", "`n")
		$new = $body + $nl + "shader_parameter/surface_kind = $kind" + $trail
	} else {
		$new = $clean
	}
	if ($new -ne $text) {
		$n++
		Write-Output ("{0,-2} {1}" -f $kind, $f.Substring($root.Length + 1))
		if (-not $DryRun) { [IO.File]::WriteAllText($f, $new) }
	}
}
Write-Output "assign_surface_kinds: $n file(s) changed"
