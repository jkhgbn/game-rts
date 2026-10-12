# Harness guards shared by tools/error_lab/error_lab.ps1 and tools/ci/ci.ps1 (dot-source it). Windows PowerShell 5.1.
# Why (2026-10-12, docs/plan/error-lab.md "3g"): two CI runs started in the same minute got the same run name
# (yyyy-MM-dd_HHmm), so the same docs/ci/<run>/ folder and the same log files. `cmd /c ... > log` of the second run
# could not open a log the first run's cmd still held ("used by another process"): cmd exited 1 in ~0.1 s without
# starting the gate or Godot, and the lab then read the OTHER run's log (PASS / victory=true) with exit 1.
# A full disk gives the same signature (cmd cannot create the log). These helpers make every run folder unique, check
# a log is writable and the disk has room before a run, and name the reason when a run failed outside Godot.
$HarnessMinFreeMB = 300   # below this on the log / project drive: report DISK FULL (Godot also writes user:// and .godot)

function Get-FreeMB([string]$path) {
	try {
		$drive = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($path))
		return [math]::Floor((New-Object IO.DriveInfo($drive)).AvailableFreeSpace / 1MB)
	} catch { return -1 }
}

# Claim a run folder that no other run uses: <parent>\<base>, else <base>_2, _3... The claim is atomic (a marker file
# created with CreateNew), so two runs started in the same second cannot share a folder. Returns the run name.
function New-UniqueRun([string]$parent, [string]$base) {
	New-Item -ItemType Directory -Force $parent | Out-Null
	for ($k = 1; $k -lt 100; $k++) {
		$name = if ($k -eq 1) { $base } else { "${base}_$k" }
		$dir = Join-Path $parent $name
		New-Item -ItemType Directory -Force $dir | Out-Null
		try {
			$fs = [IO.File]::Open((Join-Path $dir ".run_owner"), [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
			$b = [Text.Encoding]::ASCII.GetBytes("pid $PID $(Get-Date -Format s)")
			$fs.Write($b, 0, $b.Length); $fs.Close()
			return $name
		} catch [System.IO.IOException] { continue }
	}
	return "${base}_$PID"
}

# "" when the log can be (re)created now; else the reason (locked by another process / disk full / other IO error).
function Test-LogWritable([string]$log) {
	try {
		$fs = [IO.File]::Open($log, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
		$fs.Close()
		return ""
	} catch {
		$m = $_.Exception.Message
		$free = Get-FreeMB $log
		if ($free -ge 0 -and $free -lt $HarnessMinFreeMB) { return "DISK FULL: $free MB free on $([IO.Path]::GetPathRoot($log)) (cannot create the log)" }
		if ($m -match 'used by another process') { return "log locked by another process (a parallel run writing the same log path)" }
		return "cannot create the log: $m"
	}
}

# After a run with a non-zero exit: "" when Godot wrote the log, else why the run failed outside Godot.
function Get-HarnessReason([string]$log, [datetime]$start, $exit) {
	if ($null -eq $exit -or $exit -eq 0) { return "" }
	$free = Get-FreeMB $log
	$disk = if ($free -ge 0 -and $free -lt $HarnessMinFreeMB) { "DISK FULL: $free MB free on $([IO.Path]::GetPathRoot($log))" } else { "" }
	if (-not (Test-Path $log)) { return (@("log never created (cmd could not open it)", $disk) | Where-Object { $_ }) -join "; " }
	$fi = Get-Item $log
	if ($fi.LastWriteTime -lt $start.AddSeconds(-1)) { return (@("log not written by this run (older than its start: locked by a parallel run?)", $disk) | Where-Object { $_ }) -join "; " }
	if ($fi.Length -eq 0) { return (@("empty log: the gate / Godot never started", $disk) | Where-Object { $_ }) -join "; " }
	return $disk
}

# Failure kind + hint of one failed test ($s = its status: note, timed_out, harness, crashed, fail_line, script_errors,
# exit, cap). "harness" only on runner evidence ($s.harness: log locked / missing / empty / older than the run, or a
# full disk); a PASS log with exit != 0 and a fresh log stays "exit code" (quit(1) after PASS is a real bug).
function Get-FailKind([string]$t, $s) {
	$kind = ""; $hint = ""
	if ($s.note -eq "missing test file") { $kind = "missing"; $hint = "tests/$t.gd does not exist (renamed or removed): drop it from the list." }
	elseif ($s.timed_out) { $kind = "timeout"; $hint = "Wall-clock kill ($($s.note)): the run hung (an await that never resolves, a modal wait) or the PC was saturated; rerun alone with a larger -TimeoutSec to tell." }
	elseif ($s.harness) { $kind = "harness"; $hint = "The run failed outside Godot ($($s.harness)): not a game / test bug. Free disk space or stop the run sharing this log folder, then rerun this test." }
	elseif ($s.crashed) { $kind = "crash"; $hint = "Godot crashed (see the backtrace in the tail): engine crash or a native call on a freed object; rerun alone to confirm." }
	elseif ($s.fail_line) { $kind = "assert"; $hint = "The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed)." }
	elseif ($s.script_errors -gt 0) { $kind = "script error"; $hint = "A script error stopped the test before its PASS line: fix the first FAIL-class error listed for this test." }
	elseif ($null -ne $s.exit -and $s.exit -ne 0) { $kind = "exit code"; $hint = "Godot exited with $($s.exit) and no FAIL line: quit(1) from a guard, a parse error at load, or a crash; read the tail." }
	elseif ($null -eq $s.exit) { $kind = "no PASS line"; $hint = "No PASS line in the log (parse mode, exit code unknown): cap reached, crash, or the test prints no PASS; read the tail." }
	else { $kind = "cap reached"; $hint = "Exit 0 but no PASS / FAIL line: the test did not finish within --quit-after $($s.cap) frames. If it is only slow, raise its cap (`$Caps in tools/error_lab/error_lab.ps1, or '# error_lab: quit-after=N' in the test); else the tail shows where it stalls." }
	return @($kind, $hint)
}
