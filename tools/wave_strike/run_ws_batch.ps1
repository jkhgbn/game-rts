<#
.SYNOPSIS
  Wave Strike Bot Lab-style batch (docs/design/wave-strike.md 9.2): bot-vs-bot matches on Ashwind Reach through
  tests/test_ws_match.gd. Every run goes through tools\godot_run.ps1 (the Godot gate).
  Default (M1): N games Fire vs Shadow, even seeds Fire on the west seat, odd seeds Shadow.
  -Kingdoms fire,shadow,ice,nature: every ORDERED pair of different kingdoms (12 pairs = both seats of each matchup)
  x -SeedsPerPair seeds (-Mirrors adds the 4 mirrors). -Rules "base_income=120;bastion_hp_mult=1.8" = WaveStrikeRules
  knobs in memory (Balance Lab style; the .tres is not touched). -Cards res://...tres = a candidate price table
  (tools/wave_strike/reprice_cards.gd --save=...).
.EXAMPLE
  tools\wave_strike\run_ws_batch.ps1 -Games 20 -Parallel 2 -P0 hammer -P1 hammer
  tools\wave_strike\run_ws_batch.ps1 -Kingdoms fire,shadow,ice,nature -SeedsPerPair 2 -Parallel 4 -Name pace_a -Rules "bastion_hp_mult=1.8"
#>
param([int]$Games = 20, [int]$Parallel = 2, [string]$P0 = "hammer", [string]$P1 = "hammer", [int]$Limit = 1800,
	[string]$Name = "", [int]$FirstSeed = 1, [string[]]$Kingdoms = @(), [int]$SeedsPerPair = 2, [switch]$Mirrors,
	[string]$Rules = "", [string]$Cards = "")
$proj = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ($Name -eq "") { $Name = "batch_{0}_{1}_{2}" -f $P0, $P1, (Get-Date -Format "yyyyMMdd_HHmm") }
$out = Join-Path $proj "docs\tools\wave_strike\$Name"
New-Item -ItemType Directory -Force $out | Out-Null
$gate = Join-Path $proj "tools\godot_run.ps1"
# Kingdoms may come as one comma string ("fire,shadow") from the command line.
$Kingdoms = @($Kingdoms | ForEach-Object { $_ -split "," } | Where-Object { $_ -ne "" })
$ruleArgs = @($Rules -split ";" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { "--rule.$($_.Trim())" })
if ($Cards -ne "") { $ruleArgs += "--cards=$Cards" }

# The game list: seed, west kingdom, east kingdom.
$plan = @()
if ($Kingdoms.Count -ge 2) {
	$s = $FirstSeed
	for ($r = 0; $r -lt $SeedsPerPair; $r++) {
		foreach ($a in $Kingdoms) {
			foreach ($b in $Kingdoms) {
				if ($a -eq $b -and -not $Mirrors) { continue }
				$plan += [pscustomobject]@{ seed = $s; west = $a; east = $b }
				$s++
			}
		}
	}
} else {
	for ($s = $FirstSeed; $s -lt $FirstSeed + $Games; $s++) {
		$w = if ($s % 2 -eq 0) { "fire" } else { "shadow" }
		$plan += [pscustomobject]@{ seed = $s; west = $w; east = $(if ($w -eq "fire") { "shadow" } else { "fire" }) }
	}
}

$jobs = @()
foreach ($g in $plan) {
	while (@($jobs | Where-Object { $_.State -eq "Running" }).Count -ge $Parallel) { Start-Sleep -Seconds 3 }
	$json = Join-Path $out "seed_$($g.seed).json"
	$log = Join-Path $out "seed_$($g.seed).log"
	$jobs += Start-Job -ArgumentList $proj, $gate, $g.seed, $g.west, $g.east, $P0, $P1, $Limit, $json, $log, $ruleArgs -ScriptBlock {
		param($proj, $gate, $s, $west, $east, $p0, $p1, $limit, $json, $log, $ruleArgs)
		Set-Location $proj
		& $gate --headless --path . -s tests/test_ws_match.gd --fixed-fps 60 --quit-after 130000 '--' "--seed=$s" "--west=$west" "--east=$east" "--p0=$p0" "--p1=$p1" "--limit=$limit" "--out=$json" @ruleArgs *> $log
	}
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
$rows = @()
$errors = 0
foreach ($g in $plan) {
	$json = Join-Path $out "seed_$($g.seed).json"
	$log = Join-Path $out "seed_$($g.seed).log"
	if (Test-Path $log) { $errors += @(Select-String -Path $log -Pattern "SCRIPT ERROR").Count }
	if (Test-Path $json) { $rows += (Get-Content $json -Raw | ConvertFrom-Json) } else { Write-Host "seed $($g.seed): no result (see $log)" }
}
$seat = @(0, 0, 0); $kw = @{}; $kg = @{}; $reasons = @{}; $times = @(); $stalls = 0; $peak = 0; $timeouts = 0
foreach ($r in $rows) {
	foreach ($k in @($r.west, $r.east)) { $kg[$k] = 1 + [int]$kg[$k] }
	if ($r.winner -ge 0) {
		$seat[$r.winner]++
		$k = if ($r.winner -eq 0) { $r.west } else { $r.east }
		$kw[$k] = 1 + [int]$kw[$k]
	} else { $seat[2]++ }
	$reasons[$r.reason] = 1 + [int]$reasons[$r.reason]
	if ($r.reason -eq "time") { $timeouts++ }
	$times += [double]$r.time
	$stalls += [int]$r.stalls
	$peak = [Math]::Max($peak, [int]$r.peak_units)
}
$sorted = $times | Sort-Object
$median = if ($sorted.Count -gt 0) { $sorted[[int][Math]::Floor($sorted.Count / 2)] } else { 0 }
$reasonText = ($reasons.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key) $($_.Value)" }) -join ", "
# Kingdom win rate counts mirrors as one game for that kingdom (it always wins it).
$kText = ($kg.GetEnumerator() | Sort-Object Key | ForEach-Object {
	$w = [int]$kw[$_.Key]; "$($_.Key) $w / $($_.Value) ($([Math]::Round(100.0 * $w / [Math]::Max(1, $_.Value)))%)" }) -join ", "
$pct = [Math]::Round(100.0 * $timeouts / [Math]::Max(1, $rows.Count))
$summary = @"
# Wave Strike batch $Name
$($rows.Count) / $($plan.Count) games, personalities $P0 (west seat) vs $P1 (east seat), limit $Limit s, Ashwind Reach$(if ($Rules -ne '') { ", rules: $Rules" })$(if ($Cards -ne '') { ", cards: $Cards" })
- Seat wins: west $($seat[0]) / east $($seat[1]) / draw $($seat[2])
- Kingdom wins (wins / games): $kText
- End reasons: $reasonText (time rule: $pct %)
- Median end time: $([Math]::Round($median / 60.0, 1)) min
- Stalled lane units (total): $stalls;  script errors: $errors;  peak lane units: $peak

| seed | west | east | winner | reason | time | Bastion HP west / east | value killed w / e |
|---|---|---|---|---|---|---|---|
"@
foreach ($r in $rows) {
	$wk = if ($r.winner -eq 0) { "west ($($r.west))" } elseif ($r.winner -eq 1) { "east ($($r.east))" } else { 'draw' }
	$summary += "`n| $($r.seed) | $($r.west) | $($r.east) | $wk | $($r.reason) | $([Math]::Round($r.time / 60.0, 1)) min | $([Math]::Round($r.ratios[0] * 100))% / $([Math]::Round($r.ratios[1] * 100))% | $($r.value_killed[0]) / $($r.value_killed[1]) |"
}
$summary | Set-Content -Encoding utf8 (Join-Path $out "summary.md")
Write-Host $summary
if ($errors -gt 0 -or $stalls -gt 0) { exit 1 }
exit 0
