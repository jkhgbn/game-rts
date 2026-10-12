# Godot "traffic light": run the Godot console exe only when a slot is free, so parallel agents / labs / CI
# don't pile 20-30 Godot processes on the PC (every run gets slower and perf numbers become noise).
# Usage (same arguments as the Godot exe):
#   & C:\Users\elzzo\Documents\four-wizards-rts\tools\godot_run.ps1 --headless --path . -s tests/test_x.gd --fixed-fps 60 --quit-after 6000
# Env: FW_GODOT_SLOTS (default 4) = max Godot runs through this gate at once; FW_GODOT_HARDCAP (default 6) = also wait
# while that many Godot engine processes of any origin are running. Waits at most FW_GODOT_MAXWAIT seconds (default 900),
# then runs anyway so nothing can hang forever. Output and exit code are the Godot run's.
# 2026-10-02 (fast CI): one named MUTEX per slot instead of one semaphore. A run killed by a timeout (Error Lab / CI
# taskkill) used to leak its semaphore slot for good (4 -> 3 -> 2 slots until every gate process closed); a killed
# mutex owner leaves it "abandoned" and the next waiter takes it over. The hard cap now counts engine processes only:
# each console run is 2 processes (the _console wrapper + the engine), so the old count of 6 allowed only 3 runs.
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
if ($env:FW_GODOT) { $g = $env:FW_GODOT }   # per-machine override (same path on the desktop and the laptop today)
$slots = 4; if ($env:FW_GODOT_SLOTS) { $slots = [int]$env:FW_GODOT_SLOTS }
$hardcap = 6; if ($env:FW_GODOT_HARDCAP) { $hardcap = [int]$env:FW_GODOT_HARDCAP }
$maxwait = 900; if ($env:FW_GODOT_MAXWAIT) { $maxwait = [int]$env:FW_GODOT_MAXWAIT }
$start = Get-Date
$held = $null
# Take the first free slot mutex (an abandoned one counts as free: its owner was killed).
while ($held -eq $null) {
	for ($i = 0; $i -lt $slots -and $held -eq $null; $i++) {
		$m = New-Object System.Threading.Mutex($false, "Local\FourWizardsGodotGateSlot$i")
		$got = $false
		try { $got = $m.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $got = $true }
		if ($got) { $held = $m } else { $m.Dispose() }
	}
	if ($held -eq $null) {
		if (((Get-Date) - $start).TotalSeconds -gt $maxwait) { break }
		Start-Sleep -Milliseconds (500 + (Get-Random -Maximum 1000))
	}
}
try {
	# Engine processes only (the _console wrapper is not counted, its child engine is).
	while (((Get-Process -Name "Godot_v4.7.2-stable_win64" -ErrorAction SilentlyContinue) | Measure-Object).Count -ge $hardcap) {
		if (((Get-Date) - $start).TotalSeconds -gt $maxwait) { break }
		Start-Sleep -Milliseconds (1500 + (Get-Random -Maximum 1500))
	}
	& $g @args
	$code = $LASTEXITCODE
} finally {
	if ($held -ne $null) { try { $held.ReleaseMutex() } catch {} ; $held.Dispose() }
}
exit $code
