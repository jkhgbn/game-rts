<#
.SYNOPSIS
  Wave Strike Bot Lab-style batch (docs/design/wave-strike.md 9.2, M1): N bot-vs-bot matches on Ashwind Reach through
  tests/test_ws_match.gd, equal personalities by default; even seeds put Fire on the west seat, odd seeds Shadow, so the
  seat split and the kingdom split are both measured. Every run goes through tools\godot_run.ps1 (the Godot gate).
.EXAMPLE
  tools\wave_strike\run_ws_batch.ps1 -Games 20 -Parallel 2 -P0 hammer -P1 hammer
#>
param([int]$Games = 20, [int]$Parallel = 2, [string]$P0 = "hammer", [string]$P1 = "hammer", [int]$Limit = 1800,
	[string]$Name = "", [int]$FirstSeed = 1)
$proj = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ($Name -eq "") { $Name = "batch_{0}_{1}_{2}" -f $P0, $P1, (Get-Date -Format "yyyyMMdd_HHmm") }
$out = Join-Path $proj "docs\tools\wave_strike\$Name"
New-Item -ItemType Directory -Force $out | Out-Null
$gate = Join-Path $proj "tools\godot_run.ps1"
$jobs = @()
for ($s = $FirstSeed; $s -lt $FirstSeed + $Games; $s++) {
	while (@($jobs | Where-Object { $_.State -eq "Running" }).Count -ge $Parallel) { Start-Sleep -Seconds 3 }
	$west = if ($s % 2 -eq 0) { "fire" } else { "shadow" }
	$json = Join-Path $out "seed_$s.json"
	$log = Join-Path $out "seed_$s.log"
	$jobs += Start-Job -ArgumentList $proj, $gate, $s, $west, $P0, $P1, $Limit, $json, $log -ScriptBlock {
		param($proj, $gate, $s, $west, $p0, $p1, $limit, $json, $log)
		Set-Location $proj
		& $gate --headless --path . -s tests/test_ws_match.gd --fixed-fps 60 --quit-after 130000 '--' "--seed=$s" "--west=$west" "--p0=$p0" "--p1=$p1" "--limit=$limit" "--out=$json" *> $log
	}
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
$rows = @()
$errors = 0
for ($s = $FirstSeed; $s -lt $FirstSeed + $Games; $s++) {
	$json = Join-Path $out "seed_$s.json"
	$log = Join-Path $out "seed_$s.log"
	if (Test-Path $log) { $errors += @(Select-String -Path $log -Pattern "SCRIPT ERROR").Count }
	if (Test-Path $json) { $rows += (Get-Content $json -Raw | ConvertFrom-Json) } else { Write-Host "seed ${s}: no result (see $log)" }
}
$seat = @(0, 0, 0); $kw = @{ fire = 0; shadow = 0; draw = 0 }; $reasons = @{}; $times = @(); $stalls = 0; $peak = 0
foreach ($r in $rows) {
	if ($r.winner -ge 0) { $seat[$r.winner]++; $k = if ($r.winner -eq 0) { $r.west } else { $r.east }; $kw[$k]++ } else { $seat[2]++; $kw["draw"]++ }
	$reasons[$r.reason] = 1 + [int]$reasons[$r.reason]
	$times += [double]$r.time
	$stalls += [int]$r.stalls
	$peak = [Math]::Max($peak, [int]$r.peak_units)
}
$sorted = $times | Sort-Object
$median = if ($sorted.Count -gt 0) { $sorted[[int][Math]::Floor($sorted.Count / 2)] } else { 0 }
$reasonText = ($reasons.GetEnumerator() | ForEach-Object { "$($_.Key) $($_.Value)" }) -join ", "
$summary = @"
# Wave Strike batch $Name
$($rows.Count) / $Games games, personalities $P0 (west seat) vs $P1 (east seat), limit $Limit s, Ashwind Reach
- Seat wins: west $($seat[0]) / east $($seat[1]) / draw $($seat[2])
- Kingdom wins: fire $($kw.fire) / shadow $($kw.shadow) / draw $($kw.draw)
- End reasons: $reasonText
- Median end time: $([Math]::Round($median / 60.0, 1)) min
- Stalled lane units (total): $stalls;  script errors: $errors;  peak lane units: $peak

| seed | west | winner | reason | time | Bastion HP west / east | value killed w / e |
|---|---|---|---|---|---|---|
"@
foreach ($r in $rows) {
	$summary += "`n| $($r.seed) | $($r.west) | $(if ($r.winner -eq 0) { 'west' } elseif ($r.winner -eq 1) { 'east' } else { 'draw' }) | $($r.reason) | $([Math]::Round($r.time / 60.0, 1)) min | $([Math]::Round($r.ratios[0] * 100))% / $([Math]::Round($r.ratios[1] * 100))% | $($r.value_killed[0]) / $($r.value_killed[1]) |"
}
$summary | Set-Content -Encoding utf8 (Join-Path $out "summary.md")
Write-Host $summary
if ($errors -gt 0 -or $stalls -gt 0) { exit 1 }
exit 0
