# Expected wall time of a Bot Lab / Balance Lab batch (dot-sourced by run_lab.ps1 and run_balance.ps1).
# A rough model from the measured runs in docs/plan/bot-lab.md "Speed" (2026-09-26), shown BEFORE a batch starts so
# nobody launches a 10-hour run by accident. Not a perf number: it only sizes the batch.
#   quiet PC : sim x3.0 game s per real s (5.5 ms/frame at 1:00), sim off x2.0, start-up + exit 25 s,
#              every -Parallel slot free (at most the gate's FW_GODOT_SLOTS).
#   busy PC  : sim x0.8 (first batch: ~1000 s per 13-min match with 4 in parallel and other agents' Godot runs),
#              sim off x0.6, start-up + exit 45 s, only 2 slots of the shared gate.
#   tick 30  : x1.7 on both.   Early stop on: a match lasts min(limit, 14:00) (first batch median 14:22).
function Get-LabEta {
	param([int]$Games, [int]$Limit, [bool]$EarlyOn, [bool]$SimOn, [int]$Tick, [int]$Parallel)
	$slots = 4; if ($env:FW_GODOT_SLOTS) { $slots = [int]$env:FW_GODOT_SLOTS }
	$game = if ($EarlyOn) { [Math]::Min($Limit, 840) } else { $Limit }
	$tickGain = if ($Tick -le 30) { 1.7 } else { 1.0 }
	$quietSpeed = $(if ($SimOn) { 3.0 } else { 2.0 }) * $tickGain
	$busySpeed = $(if ($SimOn) { 0.8 } else { 0.6 }) * $tickGain
	$quietPar = [Math]::Max(1, [Math]::Min($Parallel, $slots))
	$busyPar = [Math]::Max(1, [Math]::Min($Parallel, 2))
	$quietMatch = 25 + $game / $quietSpeed
	$busyMatch = 45 + $game / $busySpeed
	return @{
		QuietMin = [Math]::Ceiling($Games / $quietPar) * $quietMatch / 60.0
		BusyMin = [Math]::Ceiling($Games / $busyPar) * $busyMatch / 60.0
		GameS = $game
	}
}

function Format-LabMinutes([double]$m) {
	if ($m -lt 90) { return ("{0:N0} min" -f $m) }
	return ("{0:N1} h" -f ($m / 60.0))
}
