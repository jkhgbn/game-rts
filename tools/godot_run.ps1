# Godot "traffic light": run the Godot console exe only when a slot is free, so parallel agents / labs / CI
# don't pile 20-30 Godot processes on the PC (every run gets slower and perf numbers become noise).
# Usage (same arguments as the Godot exe):
#   & C:\Users\elzzo\Documents\four-wizards-rts\tools\godot_run.ps1 --headless --path . -s tests/test_x.gd --fixed-fps 60 --quit-after 6000
# Env: FW_GODOT_SLOTS (default 4) = max Godot runs through this gate at once; FW_GODOT_HARDCAP (default 6) = also wait
# while that many Godot processes of any origin are running. Waits at most FW_GODOT_MAXWAIT seconds (default 900),
# then runs anyway so nothing can hang forever. Output and exit code are the Godot run's.
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$slots = 4; if ($env:FW_GODOT_SLOTS) { $slots = [int]$env:FW_GODOT_SLOTS }
$hardcap = 6; if ($env:FW_GODOT_HARDCAP) { $hardcap = [int]$env:FW_GODOT_HARDCAP }
$maxwait = 900; if ($env:FW_GODOT_MAXWAIT) { $maxwait = [int]$env:FW_GODOT_MAXWAIT }
$sem = New-Object System.Threading.Semaphore($slots, $slots, "Local\FourWizardsGodotGate")
$start = Get-Date
$got = $sem.WaitOne([TimeSpan]::FromSeconds($maxwait))
try {
	while (((Get-Process -Name "Godot_v4.7.2*" -ErrorAction SilentlyContinue) | Measure-Object).Count -ge $hardcap) {
		if (((Get-Date) - $start).TotalSeconds -gt $maxwait) { break }
		Start-Sleep -Milliseconds (1500 + (Get-Random -Maximum 1500))
	}
	& $g @args
	$code = $LASTEXITCODE
} finally {
	if ($got) { [void]$sem.Release() }
	$sem.Dispose()
}
exit $code
