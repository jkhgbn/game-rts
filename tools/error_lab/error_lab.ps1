# Error Lab: run tests through the Godot gate (or read existing logs), collect every runtime / script error,
# dedupe them into unique errors, map each to its file and owner (CLAUDE.md "Who owns what"), flag NEW errors
# vs the previous runs, diagnose every failed test (timeout / cap reached / crash / script error / FAIL line, with
# its log tail) and write scorecard.md / scorecard.json + one fix-agent brief per owner.
# Docs: docs/plan/error-lab.md. Windows PowerShell 5.1. Never runs git.
#
#   tools\error_lab\error_lab.ps1                          # every tests/test_*.gd
#   tools\error_lab\error_lab.ps1 -Tests test_16a,test_12_c2
#   tools\error_lab\error_lab.ps1 -Changed (git diff --name-only)   # tests touching the changed files
#   tools\error_lab\error_lab.ps1 -Logs docs\errors\lab\2026-09-26_2310\logs   # parse only
param(
	[string[]]$Tests = @(),
	[string[]]$Changed = @(),
	[string]$Logs = "",
	[string]$OutDir = "",
	[string]$Run = "",
	[int]$Parallel = 3,
	[int]$TimeoutSec = 2400,   # wall-clock kill per test: at least this, more for big caps (Get-TestTimeout)
	[switch]$NoHistory,
	[switch]$ListOnly,
	[string]$HistoryFile = "",
	[string]$ProjectDir = "",   # run the tests of another checkout (the CI copy); default = this repo
	[int]$TailLines = 15,       # log lines quoted per failed test in the scorecard and the briefs
	[string[]]$FullTests = @()  # these tests get `-- --full` (early stops off: the whole match; tools\ci\ci.ps1 -Full)
)
$ErrorActionPreference = "Stop"
$LabVersion = "1.3"
$LabRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Root = $LabRoot
if ($ProjectDir) {
	if (-not (Test-Path (Join-Path $ProjectDir "project.godot"))) { Write-Host "ERROR LAB: no project.godot in $ProjectDir"; exit 2 }
	$Root = (Resolve-Path $ProjectDir).Path
}
. (Join-Path $PSScriptRoot "harness.ps1")   # unique run folders, log / disk checks, HARNESS reasons (3g)
if (-not $Run) {
	$Run = Get-Date -Format "yyyy-MM-dd_HHmm"
	# Two labs started in the same minute must not share a folder (their cmd redirects fight over the same logs).
	if (-not $OutDir -and -not $ListOnly -and -not $Logs) { $Run = New-UniqueRun (Join-Path $LabRoot "docs\errors\lab") $Run }
}
if (-not $OutDir) { $OutDir = Join-Path $LabRoot "docs\errors\lab\$Run" }
if (-not $HistoryFile) { $HistoryFile = Join-Path $LabRoot "docs\errors\lab\history.jsonl" }
# .NET file calls use the process folder, not the PowerShell location: make every path absolute.
$OutDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutDir)
$HistoryFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($HistoryFile)
if ($Logs) { $Logs = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Logs) }
$Gate = Join-Path $LabRoot "tools\godot_run.ps1"
$NewWindow = 10   # an error is NEW when none of the last N history rows had it

# Caps (--quit-after frames at --fixed-fps 60). ONE table for the Error Lab and tools/ci/ci.ps1 (the CI runs its
# tests through this lab). A test can also declare its own cap in its first 40 lines: "# error_lab: quit-after=95000".
$DefaultCap = 40000
$Caps = @{ "test_9_c9" = 150000; "test_10_a3" = 150000; "test_8_a1" = 200000; "test_12_a1" = 60000; "test_8_a2" = 100000
	"test_20_a2" = 60000; "test_20_a3" = 80000; "test_9_c11" = 95000; "test_2_a1_attack" = 95000; "test_8_b3" = 95000 }
function Get-Cap([string]$name) {
	$f = Join-Path $Root "tests\$name.gd"
	if (Test-Path $f) {
		$decl = @(Get-Content $f -TotalCount 40 -ErrorAction SilentlyContinue | Where-Object { $_ -match '^#\s*error_lab:.*quit-after\s*=\s*\d+' })
		if ($decl.Count -gt 0 -and $decl[0] -match 'quit-after\s*=\s*(\d+)') { return [int]$Matches[1] }
	}
	if ($Caps.ContainsKey($name)) { return $Caps[$name] }
	if ($name -match "bot_vs_bot") { return 116000 }
	# Mission sims (2026-10-13): 20-35 min of game. Use the "--quit-after N" of their own "Run:" header line, else 140000.
	if ($name -match "_sim$") {
		if (Test-Path $f) {
			$run = @(Get-Content $f -TotalCount 20 -ErrorAction SilentlyContinue | Where-Object { $_ -match '--quit-after\s+\d+' })
			if ($run.Count -gt 0 -and $run[0] -match '--quit-after\s+(\d+)') { return [Math]::Max([int]$Matches[1], 60000) }
		}
		return 140000
	}
	return $DefaultCap
}

# Wall-clock kill per test (v1.3, fast CI 2026-10-02): the larger of -TimeoutSec and 1.5 wall s per game second of
# the cap plus the gate's longest wait (900 s; the clock starts before the gate grants a slot). A flat 2400 s killed
# test_20_a3 (57600 frames) on a loaded PC although it was still running.
function Get-TestTimeout([int]$cap) {
	return [int][math]::Max($TimeoutSec, [math]::Ceiling($cap / 60.0 * 1.5) + 900)
}

# Longest-first (v1.3): the slow bot / AI simulations listed in tools/ci/slow_tests.txt start first, so a full run
# does not end on a 30-minute test that was queued last (alphabetical order put test_8_a1 near the end).
$SlowFile = Join-Path $LabRoot "tools\ci\slow_tests.txt"
$SlowList = @()
if (Test-Path $SlowFile) { $SlowList = @(Get-Content $SlowFile | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ }) }
function Sort-SlowFirst([string[]]$names) {
	$slow = @($SlowList | Where-Object { $names -contains $_ })
	$rest = @($names | Where-Object { $SlowList -notcontains $_ } | Sort-Object)
	return @($slow + $rest)
}

# Verdict mode (lab v1.2). Default: any line starting with FAIL fails the test. Tests that print planted / inner
# "FAIL ..." lines on purpose (lab-on-lab tests) use "last": only the LAST PASS / FAIL line decides (so the test's
# own final "PASS <id>" / "FAIL <id>: ..." line wins). Exit code, script errors and crashes still fail such tests,
# and the ignored inner FAIL lines are counted in the scorecard. Declared in the test's first 20 lines:
# "# error_lab: verdict=last", or listed here (so an older CI copy of the test is judged the same way).
$VerdictLast = @("test_art_lab", "test_art_lab_calibration")
function Get-VerdictMode([string]$name) {
	$f = Join-Path $Root "tests\$name.gd"
	if (Test-Path $f) {
		$decl = @(Get-Content $f -TotalCount 20 -ErrorAction SilentlyContinue | Where-Object { $_ -match '^#\s*error_lab:.*verdict\s*=\s*(last|any)\b' })
		if ($decl.Count -gt 0 -and $decl[0] -match 'verdict\s*=\s*(last|any)\b') { return $Matches[1] }
	}
	if ($VerdictLast -contains $name) { return "last" }
	return "any"
}

# ---------- classification ----------
$CollectRx = 'SCRIPT ERROR|ERROR:|Parse Error|Invalid call|Nonexistent function|freed object|leaked'
$FailRx = 'SCRIPT ERROR|Parse Error|Invalid call|Nonexistent function|freed object|Failed to load script'
# Known exit-time noise: INFO, never FAIL.
$InfoRx = 'resources still in use at exit|ObjectDB instances (were )?leaked at exit|RID allocations of type .* were leaked at exit|RIDs? of type .* (was|were) leaked|Leaked instance:|Orphan StringName|Pages in use exist at exit|PagedAllocator'
$FrameRx = '^\s*(at:|\[\d+\]|GDScript backtrace)'
$CrashRx = 'Program crashed with signal|CrashHandlerException|Dumping the backtrace|Unhandled exception'

# Expected lines from intended negative checks, per test: never collected (no ^ anchor: Godot may prefix the line).
$ExpectedRx = @{ "test_art_lab" = 'ART LAB ERROR: (scene not found: res://nope\.tscn|sweep=bogus:)' }

# Windows PowerShell 5.1 wraps the FIRST stderr line of a native exe it runs (tools/godot_run.ps1 runs Godot) as an
# error record: "Godot_...exe : ERROR: x" + "At ...godot_run.ps1:20 char:2" + "+ & $g @args" + CategoryInfo lines.
# Clean that back to the plain Godot line so the same error is not counted twice and its "at:" frame is found.
function Clean-Lines([string[]]$raw) {
	$out = New-Object System.Collections.Generic.List[string]
	$skipBlank = $false
	foreach ($l in $raw) {
		if ($skipBlank -and -not $l.Trim()) { $skipBlank = $false; continue }   # the blank line PS prints after the record
		$skipBlank = $false
		if ($l -match '^At [^\r\n]*\.ps1:\d+ char:\d+\s*$') { continue }
		if ($l -match '^\s+\+ FullyQualifiedErrorId\s*:') { $skipBlank = $true; continue }
		if ($l -match '^\+ ' -or $l -match '^\s+\+ CategoryInfo\s*:' -or $l -match '^\s*\+\s+~+\s*$') { continue }
		$l = $l -replace '^\S*Godot_v[^:]*?\.exe : ', ''
		$out.Add($l)
	}
	return $out.ToArray()
}

function Get-Norm([string]$m) {
	$m = $m.Trim()
	$m = $m -replace '^(USER )?(SCRIPT ERROR|ERROR|WARNING):\s*', ''
	$m = $m -replace '0x[0-9a-fA-F]+', '0x#'
	$m = $m -replace '<([A-Za-z0-9_]+)#-?\d+>', '<$1#>'
	$m = $m -replace '(@[A-Za-z0-9_]+@)\d+', '$1#'
	$m = $m -replace '(res://[^\s:"'']+):\d+', '$1'
	$m = $m -replace '(?<![A-Za-z_])-?\d+(\.\d+)?(e-?\d+)?', 'N'
	$m = $m -replace '\s+', ' '
	return $m
}

# ---------- owners from CLAUDE.md ----------
$OwnerMap = New-Object System.Collections.ArrayList
$claude = Join-Path $LabRoot "CLAUDE.md"
if (Test-Path $claude) {
	$inTable = $false
	foreach ($line in (Get-Content $claude -Encoding UTF8)) {
		if ($line -match '^## Who owns what') { $inTable = $true; continue }
		if ($inTable -and $line -match '^## ') { break }
		if (-not $inTable -or $line -notmatch '^\|') { continue }
		$cells = $line.Trim('|').Split('|')
		if ($cells.Count -lt 2) { continue }
		$owner = ($cells[1] -replace '\(.*$', '' -replace ';.*$', '' -replace '`', '').Trim()
		if (-not $owner -or $owner -match '^-+$' -or $owner -eq 'Owner') { continue }
		# docs/design/ui-*.md goes to ui-designer (the cell names it after the ';').
		foreach ($mm in [regex]::Matches($cells[0], '`([^`]+)`')) {
			$p = $mm.Groups[1].Value
			if ($p -match '[<|*]') { continue }
			[void]$OwnerMap.Add([pscustomobject]@{ prefix = $p; owner = $owner })
		}
	}
	[void]$OwnerMap.Add([pscustomobject]@{ prefix = "docs/design/ui-"; owner = "ui-designer" })
}
# Owner of a test from its task id (docs/plan/waves.md letters: G gameplay, S systems, U ui, A ai, I items,
# V tech-artist, D designer). C / B / P... vary per step, so those stay "task agent of test_x".
$TaskLetterOwner = @{ "g" = "gameplay-coder"; "s" = "systems-coder"; "u" = "ui-coder"; "a" = "ai-coder"; "i" = "items-coder"; "v" = "tech-artist"; "d" = "game-designer" }
$LabOwner = @{ "art_lab" = "lab group A (visual)"; "visual_diff_lab" = "lab group A (visual)"; "ui_lab" = "lab group A (visual)"
	"perf_lab" = "lab group B (simulation)"; "bot_lab" = "lab group B (simulation)"; "balance_lab" = "lab group B (simulation)"; "replay_lab" = "lab group B (simulation)"
	"error_lab" = "lab group C (checks)"; "ci" = "lab group C (checks)"; "data_lab" = "lab group C (checks)"; "build_lab" = "lab group C (checks)"; "audio_lab" = "lab group C (checks)" }
function Get-LabOwner([string]$lab) {
	if ($LabOwner.ContainsKey($lab)) { return $LabOwner[$lab] }
	return "$lab owner (lab)"
}
function Get-TestOwner([string]$test) {
	if ($test -match '^test_(.+_lab)$') { return (Get-LabOwner $Matches[1]) }
	if ($test -match '^test_(m?\d+[a-z]?)_([a-z])\d') {
		$l = $Matches[2]
		if ($TaskLetterOwner.ContainsKey($l)) { return $TaskLetterOwner[$l] }
	}
	return "task agent of $test"
}
function Get-Owner([string]$file) {
	if (-not $file -or $file -notmatch '^res://') { return "" }
	$rel = $file.Substring(6)
	$best = ""; $bestLen = -1
	foreach ($o in $OwnerMap) {
		if ($rel.StartsWith($o.prefix) -and $o.prefix.Length -gt $bestLen) { $best = $o.owner; $bestLen = $o.prefix.Length }
	}
	if ($best) { return $best }
	if ($rel -match '^tests/(test_[^/]+)\.gd$') { return (Get-TestOwner $Matches[1]) }
	if ($rel -match '^tools/([^/]+)/') { return (Get-LabOwner $Matches[1]) }
	return "lead (unmapped: $rel)"
}
function Join-Short([object[]]$items, [int]$n = 3) {
	$items = @($items)
	$s = ($items | Select-Object -First $n) -join ", "
	if ($items.Count -gt $n) { $s += " +$($items.Count - $n) more" }
	return $s
}

# ---------- pick tests ----------
function Get-ChangedTests([string[]]$files) {
	if ($files.Count -eq 1 -and $files[0] -match '\.txt$' -and (Test-Path $files[0])) { $files = Get-Content $files[0] }
	$files = @($files | ForEach-Object { $_ -split ',' })
	$all = Get-ChildItem (Join-Path $Root "tests") -Filter "test_*.gd"
	$picked = New-Object System.Collections.Generic.HashSet[string]
	foreach ($f in $files) {
		$f = ($f -replace '\\', '/').Trim()
		if (-not $f) { continue }
		if ($f -match '(^|/)tests/(test_[^/]+)\.gd$') { [void]$picked.Add($Matches[2]); continue }
		if ($f -notmatch '\.(gd|tscn|tres|gdshader|json)$') { continue }
		$needles = @("res://$f")
		$abs = Join-Path $Root $f
		if ($f -match '\.gd$' -and (Test-Path $abs)) {
			$cn = Select-String -Path $abs -Pattern '^class_name\s+(\w+)' | Select-Object -First 1
			if ($cn) { $needles += $cn.Matches[0].Groups[1].Value }
		}
		foreach ($t in $all) {
			foreach ($n in $needles) {
				if (Select-String -Path $t.FullName -SimpleMatch -Pattern $n -Quiet) { [void]$picked.Add($t.BaseName); break }
			}
		}
	}
	return @($picked | Sort-Object)
}

if ($Logs -and -not (Test-Path $Logs -PathType Container)) { Write-Host "ERROR LAB: logs folder not found: $Logs"; exit 2 }
if (-not $ListOnly) { New-Item -ItemType Directory -Force $OutDir | Out-Null }
$testStatus = @{}   # name -> @{ exit; pass; seconds; cap; log }
$logDir = $Logs
if (-not $Logs) {
	$logDir = Join-Path $OutDir "logs"
	$names = @()
	if ($Tests.Count -gt 0) { $names = @($Tests | ForEach-Object { $_ -split ',' } | ForEach-Object { ($_.Trim() -replace '\.gd$', '' -replace '^.*[\\/]', '') } | Where-Object { $_ }) }
	elseif ($Changed.Count -gt 0) { $names = Get-ChangedTests $Changed }
	else { $names = @(Get-ChildItem (Join-Path $Root "tests") -Filter "test_*.gd" | ForEach-Object { $_.BaseName } | Sort-Object) }
	$names = Sort-SlowFirst $names
	$fullSet = @($FullTests | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() -replace '\.gd$', '' } | Where-Object { $_ })
	if ($fullSet.Count -gt 0) { Write-Host "ERROR LAB: --full (whole match, no early stop) for: $(@($names | Where-Object { $fullSet -contains $_ }) -join ', ')" }
	if ($ListOnly) { Write-Host "ERROR LAB: would run $($names.Count) tests (slow ones first)"; $names | ForEach-Object { Write-Host ("  {0} (cap {1}, timeout {2} s, owner {3})" -f $_, (Get-Cap $_), (Get-TestTimeout (Get-Cap $_)), (Get-TestOwner $_)) }; exit 0 }
	New-Item -ItemType Directory -Force $logDir | Out-Null
	if ($names.Count -eq 0) { Write-Host "ERROR LAB: no tests picked"; }
	if (-not (Test-Path $Gate)) { Write-Host "ERROR LAB: Godot gate not found: $Gate"; exit 2 }
	$freeMB = Get-FreeMB $logDir
	if ($freeMB -ge 0 -and $freeMB -lt $HarnessMinFreeMB) { Write-Host "ERROR LAB: DISK FULL: $freeMB MB free on $([IO.Path]::GetPathRoot($logDir)) (need $HarnessMinFreeMB MB): free space, then rerun"; exit 3 }
	Write-Host "ERROR LAB: running $($names.Count) tests of $Root, $Parallel at a time (gate: tools/godot_run.ps1)"
	$queue = New-Object System.Collections.Queue
	foreach ($n in $names) { $queue.Enqueue($n) }
	$running = @()
	$done = 0; $runStart = Get-Date
	while ($queue.Count -gt 0 -or $running.Count -gt 0) {
		while ($queue.Count -gt 0 -and $running.Count -lt $Parallel) {
			$n = $queue.Dequeue()
			if (-not (Test-Path (Join-Path $Root "tests\$n.gd"))) { $testStatus[$n] = @{ exit = -2; seconds = 0; cap = 0; note = "missing test file" }; $done++; continue }
			$cap = Get-Cap $n
			$log = Join-Path $logDir "$n.log"
			$why = Test-LogWritable $log   # a locked log / full disk: cmd would exit 1 in 0.1 s without running Godot
			if ($why) { $testStatus[$n] = @{ exit = -3; seconds = 0; cap = $cap; note = "harness: $why"; harness = $why }; $done++; Write-Host "  $n HARNESS: $why"; continue }
			# "++" = Godot's other user-args separator ("--" would be eaten by powershell -File on the way to the gate).
			$userArgs = if ($fullSet -contains $n) { " ++ --full" } else { "" }
			$cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$Gate`" --headless --path `"$Root`" -s tests/$n.gd --fixed-fps 60 --quit-after $cap$userArgs > `"$log`" 2>&1"
			$p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$cmd`"" -WorkingDirectory $Root -WindowStyle Hidden -PassThru
			$null = $p.Handle  # PS 5.1: keep the handle so ExitCode is readable later
			$running += [pscustomobject]@{ name = $n; proc = $p; start = Get-Date; cap = $cap; timeout = (Get-TestTimeout $cap) }
		}
		Start-Sleep -Milliseconds 500
		$still = @()
		foreach ($r in $running) {
			$secs = ((Get-Date) - $r.start).TotalSeconds
			if ($r.proc.HasExited) {
				$done++
				$hw = Get-HarnessReason (Join-Path $logDir "$($r.name).log") $r.start $r.proc.ExitCode
				$testStatus[$r.name] = @{ exit = $r.proc.ExitCode; seconds = [math]::Round($secs, 1); cap = $r.cap; note = $(if ($hw) { "harness: $hw" } else { "" }); harness = $hw }
				$el = ((Get-Date) - $runStart).TotalMinutes
				$eta = if ($done -gt 0) { $el / $done * ($names.Count - $done) } else { 0 }
				Write-Host ("  [{0}/{1}] {2,-28} exit {3}  {4:N0} s  (ETA ~{5:N0} min)" -f $done, $names.Count, $r.name, $r.proc.ExitCode, $secs, $eta)
			} elseif ($secs -gt $r.timeout) {
				& taskkill.exe /T /F /PID $r.proc.Id | Out-Null   # our own cmd -> gate -> Godot tree only
				$done++
				$testStatus[$r.name] = @{ exit = -1; seconds = [math]::Round($secs, 1); cap = $r.cap; note = "killed after $($r.timeout) s"; timed_out = $true }
				Write-Host "  $($r.name) TIMEOUT (killed)"
			} else { $still += $r }
		}
		$running = $still
	}
}

# ---------- parse logs ----------
$errors = @{}   # key -> object
$logFiles = @(Get-ChildItem $logDir -Filter "*.log" | Sort-Object Name)
foreach ($lf in $logFiles) {
	$test = $lf.BaseName
	$lines = @(Clean-Lines @(Get-Content $lf.FullName -Encoding UTF8))
	$passLine = @($lines | Where-Object { $_ -match '^\s*PASS\b' }).Count -gt 0
	$failLines = @($lines | Where-Object { $_ -match '^\s*FAIL\b' } | ForEach-Object { $_.Trim() })
	if (-not $testStatus.ContainsKey($test)) { $testStatus[$test] = @{ exit = $null; seconds = $null; cap = $null; note = "" } }
	$st = $testStatus[$test]
	$st.verdict = Get-VerdictMode $test
	$st.inner_fail = 0
	if ($st.verdict -eq "last") {
		$verdicts = @($lines | Where-Object { $_ -match '^\s*(PASS|FAIL)\b' } | ForEach-Object { $_.Trim() })
		if ($verdicts.Count -gt 0 -and $verdicts[-1] -match '^PASS\b') {
			$passLine = $true
			$st.inner_fail = $failLines.Count
			$failLines = @()
		} elseif ($verdicts.Count -gt 0) {
			$passLine = $false
			$failLines = @(@($verdicts[-1]) + @($failLines | Where-Object { $_ -ne $verdicts[-1] }))   # the deciding line first
		} else { $passLine = $false }
		if ($st.inner_fail -gt 0) { $st.note = (($st.note, "verdict=last: $($st.inner_fail) inner FAIL line(s) ignored") -ne "") -join "; " }
	}
	$st.pass_line = $passLine
	$st.fail_line = ($failLines.Count -gt 0)
	$st.fail_lines = @($failLines | Select-Object -First 3)
	$st.log = $lf.FullName
	$st.crashed = @($lines | Where-Object { $_ -match $CrashRx }).Count -gt 0
	$st.script_errors = 0
	# Tail: the last lines that are not exit noise (the leak lines and their frames say nothing about the failure).
	$tail = New-Object System.Collections.Generic.List[string]
	for ($i = $lines.Count - 1; $i -ge 0 -and $tail.Count -lt $TailLines; $i--) {
		$l = $lines[$i]
		if (-not $l.Trim()) { continue }
		if ($l -match $InfoRx) { continue }
		if ($l -match '^\s*at: (cleanup|clear) \(core/' -or $l -match '^Godot Engine v') { continue }
		$tail.Insert(0, $l.TrimEnd())
	}
	$st.tail = $tail.ToArray()
	for ($i = 0; $i -lt $lines.Count; $i++) {
		$line = $lines[$i]
		if ($line -cnotmatch $CollectRx) { continue }   # case-sensitive: a test status line "0 script errors" is not a Godot error
		if ($ExpectedRx.ContainsKey($test) -and $line -match $ExpectedRx[$test]) { continue }
		if ($line -match $FrameRx) { continue }
		# The frame: first res:// frame in the next lines (at: or backtrace), else the first at: frame.
		$file = ""; $ln = 0; $func = ""; $engine = ""
		for ($j = $i + 1; $j -lt [math]::Min($lines.Count, $i + 10); $j++) {
			$l2 = $lines[$j]
			if ($l2 -notmatch $FrameRx) { break }
			if ($l2 -match '(?:at:|\[\d+\])\s*([^\s(]*)\s*\((res://[^()]+?):(\d+)\)\s*$') { $func = $Matches[1]; $file = $Matches[2]; $ln = [int]$Matches[3]; break }
			if (-not $engine -and $l2 -match '\(([^()]+?):(\d+)\)\s*$') { $engine = "$($Matches[1]):$($Matches[2])" }
		}
		if (-not $file -and $line -match '(res://[^\s"'':]+\.(gd|tscn|tres|gdshader))(:(\d+))?') { $file = $Matches[1]; if ($Matches[4]) { $ln = [int]$Matches[4] } }
		$norm = Get-Norm $line
		$sev = "WARN"
		if ($line -match $InfoRx) { $sev = "INFO" } elseif ($line -cmatch $FailRx) { $sev = "FAIL" }
		if ($sev -eq "FAIL") { $st.script_errors++ }
		$loc = if ($file) { "${file}:$ln" } elseif ($engine) { "engine $engine" } else { "(no frame)" }
		# The key uses the function, not the line number, so an edit above the bug does not make it "NEW".
		$where = if ($file -and $func) { "${file}::$func" } elseif ($file) { "${file}:$ln" } else { "(engine)" }
		$key = "$norm @ $where"
		if (-not $errors.ContainsKey($key)) {
			$errors[$key] = [pscustomobject]@{ key = $key; severity = $sev; message = $norm; example = $line.Trim(); file = $file; line = $ln; func = $func
				location = $loc; owner = (Get-Owner $file); count = 0; tests = New-Object System.Collections.ArrayList; new = $false }
		}
		$e = $errors[$key]; $e.count++
		if (-not $e.tests.Contains($test)) { [void]$e.tests.Add($test) }
	}
}
foreach ($e in $errors.Values) {
	if ($e.owner) { continue }
	if ($e.tests.Count -eq 1) { $e.owner = (Get-TestOwner $e.tests[0]) + " (engine error, no script frame)" }
	else {
		$owners = @($e.tests | ForEach-Object { Get-TestOwner $_ } | Select-Object -Unique)
		if ($owners.Count -eq 1) { $e.owner = "$($owners[0]) (engine error, no script frame)" }
		else { $e.owner = "lead (engine error in $($e.tests.Count) tests of $($owners.Count) owners, no script frame)" }
	}
}

# ---------- NEW vs previous runs ----------
$prev = $null
$seenKeys = New-Object 'System.Collections.Generic.HashSet[string]'
if (Test-Path $HistoryFile) {
	$hl = @(Get-Content $HistoryFile -Encoding UTF8 | Where-Object { $_.Trim() })
	if ($hl.Count -gt 0) {
		$prev = $hl[$hl.Count - 1] | ConvertFrom-Json
		foreach ($row in @($hl | Select-Object -Last $NewWindow)) { foreach ($k in @(($row | ConvertFrom-Json).keys)) { if ($k) { [void]$seenKeys.Add([string]$k) } } }
	}
}
foreach ($e in $errors.Values) {
	if ($e.severity -ne "INFO" -and -not $seenKeys.Contains($e.key)) { $e.new = $true }
}

# ---------- tests pass / fail + diagnosis ----------
$testRows = @()
foreach ($t in ($testStatus.Keys | Sort-Object)) {
	$s = $testStatus[$t]
	$ok = $true; $why = ""
	if ($null -ne $s.exit -and $s.exit -ne 0) { $ok = $false; $why = "exit $($s.exit)" }
	if ($s.fail_line) { $ok = $false; $why = (($why, "FAIL line") -ne "") -join "; " }
	if (-not $s.pass_line) { $ok = $false; $why = (($why, "no PASS line") -ne "") -join "; " }
	if ($s.note) { $why = (($why, $s.note) -ne "") -join "; " }
	# What kind of failure, and what to do about it.
	$kind = ""; $hint = ""
	if (-not $ok) {
		$fk = Get-FailKind $t $s; $kind = $fk[0]; $hint = $fk[1]
	}
	$testRows += [pscustomobject]@{ test = $t; ok = $ok; why = $why; kind = $kind; hint = $hint; exit = $s.exit; seconds = $s.seconds; cap = $s.cap
		owner = (Get-TestOwner $t); verdict = $s.verdict; inner_fail = $s.inner_fail; fail_lines = @($s.fail_lines | Where-Object { $null -ne $_ }); tail = @($s.tail | Where-Object { $null -ne $_ }); log = $s.log }
}
$failedTests = @($testRows | Where-Object { -not $_.ok })

# ---------- score ----------
$real = @($errors.Values | Where-Object { $_.severity -ne "INFO" })
$uF = @($real | Where-Object { $_.severity -eq "FAIL" }).Count
$uW = @($real | Where-Object { $_.severity -eq "WARN" }).Count
$uI = @($errors.Values | Where-Object { $_.severity -eq "INFO" }).Count
$uNew = @($real | Where-Object { $_.new }).Count
$score = [math]::Max(0, 100 - 8 * $uF - 3 * $uW - 10 * $failedTests.Count)
$result = if ($uF -gt 0 -or $failedTests.Count -gt 0) { "FAIL" } elseif ($uW -gt 0) { "WARN" } else { "PASS" }
$sevRank = @{ "FAIL" = 0; "WARN" = 1; "INFO" = 2 }
$ranked = @($real | Sort-Object @{ e = { $sevRank[$_.severity] } }, @{ e = { if ($_.new) { 0 } else { 1 } } }, @{ e = { -$_.tests.Count } }, @{ e = { -$_.count } }, @{ e = { $_.key } })
$gone = @()
if ($prev) { $cur = @($real | ForEach-Object { $_.key }); $gone = @(@($prev.keys) | Where-Object { $_ -and $cur -notcontains $_ }) }

# ---------- groups per owner ----------
$groups = [ordered]@{}
foreach ($e in $ranked) {
	if (-not $groups.Contains($e.owner)) { $groups[$e.owner] = @{ errors = @(); tests = @() } }
	$groups[$e.owner].errors += $e
}
foreach ($t in $failedTests) {
	if (-not $groups.Contains($t.owner)) { $groups[$t.owner] = @{ errors = @(); tests = @() } }
	$groups[$t.owner].tests += $t
}
$ownerOrder = @($groups.Keys | Sort-Object @{ e = { -(@($groups[$_].errors | Where-Object { $_.severity -eq "FAIL" }).Count + @($groups[$_].tests).Count) } }, @{ e = { -@($groups[$_].errors).Count } }, @{ e = { $_ } })

# ---------- write scorecard ----------
function Esc([string]$s) { return ($s -replace '\|', '\|' -replace '[\r\n]+', ' ' -replace '[^\x20-\x7E]', '?') }
function Plain([string]$s) { return ($s -replace '```', "'''" -replace '[^\x09\x20-\x7E]', '?') }
function Repro([string[]]$ts) {
	$ts = @($ts | Select-Object -First 3)
	$p = if ($Root -eq $LabRoot) { "." } else { "`"$Root`"" }
	return @($ts | ForEach-Object { "& tools\godot_run.ps1 --headless --path $p -s tests/$_.gd --fixed-fps 60 --quit-after $(Get-Cap $_)" })
}
$now = Get-Date -Format "yyyy-MM-dd HH:mm"
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Error Lab scorecard: $Run"); $md.Add("")
$md.Add("$now - lab v$LabVersion - $($testRows.Count) tests ($($failedTests.Count) failed) - project ``$Root`` - logs: ``$logDir``"); $md.Add("")
$md.Add("## Result: **$result** - score **$score / 100**"); $md.Add("")
$md.Add("$uF unique FAIL errors - $uW unique WARN errors - $uI INFO (exit noise) - $uNew NEW (not in the last $NewWindow history rows)" + $(if ($prev) { " - previous run $($prev.run): $($prev.result) $($prev.score)" } else { " (no previous run)" })); $md.Add("")
$md.Add("Score = 100 - 8 per unique FAIL error - 3 per unique WARN error - 10 per failed test (min 0)."); $md.Add("")
$md.Add("## Improve next")
$k = 1
# Real bugs first (a FAIL line, a script error, a crash), then harness-looking ones (cap reached, timeout).
$kindRank = @{ "harness" = 3; "assert" = 0; "script error" = 0; "crash" = 1; "exit code" = 1; "cap reached" = 2; "timeout" = 2; "no PASS line" = 2; "missing" = 3 }
$failedTests = @($failedTests | Sort-Object @{ e = { $kindRank[$_.kind] } }, @{ e = { $_.test } })
foreach ($t in ($failedTests | Select-Object -First 2)) { $md.Add("$k. **tests/$($t.test).gd** failed: **$($t.kind)** ($($t.why)) - owner **$(Esc $t.owner)**. $(Esc $t.hint)"); $k++ }
foreach ($e in ($ranked | Select-Object -First ([math]::Max(1, 4 - $k)))) {
	$md.Add("$k. **$(Esc $e.location)** ($($e.severity)$(if ($e.new) { ', NEW' })) - owner **$(Esc $e.owner)**: $(Esc $e.message) _(x$($e.count) in $($e.tests.Count) tests: $(Join-Short $e.tests 4))_"); $k++
}
foreach ($t in ($failedTests | Select-Object -Skip 2 | Select-Object -First ([math]::Max(0, 4 - $k)))) { $md.Add("$k. **tests/$($t.test).gd** failed: **$($t.kind)** - owner **$(Esc $t.owner)**"); $k++ }
if ($k -eq 1) { $md.Add("1. Nothing: no errors, every test passed.") }
$md.Add("")
$md.Add("## By owner (who has work)")
$md.Add("| Owner | FAIL errors | WARN errors | Failed tests | Tests to re-run |"); $md.Add("|---|---|---|---|---|")
foreach ($o in $ownerOrder) {
	$g = $groups[$o]
	$allT = @(@($g.errors | ForEach-Object { $_.tests }) + @($g.tests | ForEach-Object { $_.test }) | Select-Object -Unique)
	$md.Add("| $(Esc $o) | $(@($g.errors | Where-Object { $_.severity -eq 'FAIL' }).Count) | $(@($g.errors | Where-Object { $_.severity -eq 'WARN' }).Count) | $(Join-Short @($g.tests | ForEach-Object { "$($_.test) ($($_.kind))" }) 4) | $(Join-Short $allT 5) |")
}
if ($groups.Count -eq 0) { $md.Add("| - | 0 | 0 | - | - |") }
$md.Add("")
if ($failedTests.Count -gt 0) {
	$md.Add("## Failed tests (diagnosis + log tail)")
	foreach ($t in $failedTests) {
		$md.Add(""); $md.Add("### $($t.test) - $($t.kind) - owner $(Esc $t.owner)")
		$md.Add("$(Esc $t.why); $($t.seconds) s, cap $($t.cap). $(Esc $t.hint)")
		if ($t.fail_lines.Count -gt 0) { $md.Add(""); $md.Add("FAIL line: ``$(Esc $t.fail_lines[0])``") }
		$md.Add(""); $md.Add("Log tail ($($t.log)):"); $md.Add('```text')
		foreach ($l in $t.tail) { $md.Add((Plain $l)) }
		$md.Add('```')
	}
	$md.Add("")
}
$md.Add("## Tests")
$md.Add("| Test | Result | Why | Exit | Seconds | Cap |"); $md.Add("|---|---|---|---|---|---|")
foreach ($t in $testRows) { $md.Add("| $($t.test) | $(if ($t.ok) { 'PASS' } else { '**FAIL** (' + $t.kind + ')' }) | $($t.why) | $($t.exit) | $($t.seconds) | $($t.cap) |") }
$md.Add("")
$md.Add("## Unique errors")
$md.Add("| # | Sev | New | Location | Owner | Count | Tests | Message |"); $md.Add("|---|---|---|---|---|---|---|---|")
$k = 1
foreach ($e in $ranked) { $md.Add("| $k | $($e.severity) | $(if ($e.new) { 'NEW' }) | $(Esc $e.location) | $(Esc $e.owner) | $($e.count) | $(Join-Short $e.tests 5) | $(Esc $e.message) |"); $k++ }
if ($ranked.Count -eq 0) { $md.Add("| - | - | - | - | - | - | - | none |") }
$md.Add("")
if ($gone.Count -gt 0) {
	$md.Add("## Gone vs the previous run ($($prev.run)): fixed, or their test did not run this time")
	foreach ($g in ($gone | Select-Object -First 20)) { $md.Add("- $(Esc $g)") }
	$md.Add("")
}
$md.Add("## INFO (known exit noise, never FAIL)")
foreach ($e in @($errors.Values | Where-Object { $_.severity -eq "INFO" } | Sort-Object key)) { $md.Add("- $(Esc $e.message) - x$($e.count) in $($e.tests.Count) tests") }
$md.Add("")
$md.Add("## Fix-agent briefs (one per owner; the lead's rule: any failure -> launch a fix agent)")
foreach ($o in $ownerOrder) {
	$g = $groups[$o]
	$list = @($g.errors); $ft = @($g.tests)
	$md.Add(""); $md.Add("### $(Esc $o) ($($list.Count) errors, $($ft.Count) failed tests)")
	$md.Add('```text')
	$md.Add("Task: fix what the Error Lab found (run $Run) in the Four Wizards RTS at $Root.")
	$md.Add("Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.")
	$allT = @()
	if ($list.Count -gt 0) {
		$md.Add("Errors (location - message - hits):")
		$n = 1
		foreach ($e in $list) {
			$md.Add("$n. [$($e.severity)$(if ($e.new) { ', NEW' })] $($e.location) - $(Plain $e.message) - x$($e.count) in: $(Join-Short $e.tests 5)"); $n++
			$allT += @($e.tests)
		}
	}
	if ($ft.Count -gt 0) {
		$md.Add("Failed tests:")
		foreach ($t in $ft) {
			$md.Add("- $($t.test): $($t.kind) ($($t.why)). $($t.hint)")
			if ($t.fail_lines.Count -gt 0) { $md.Add("  FAIL line: $(Plain $t.fail_lines[0])") }
			$md.Add("  Log tail ($($t.log)):")
			foreach ($l in ($t.tail | Select-Object -Last 10)) { $md.Add("    " + (Plain $l)) }
			$allT += $t.test
		}
	}
	$allT = @($allT | Select-Object -Unique)
	$md.Add("Repro:")
	foreach ($r in (Repro $allT)) { $md.Add("  $r") }
	$md.Add("Done when: tools\error_lab\error_lab.ps1 -Tests $(($allT | Select-Object -First 8) -join ',') -NoHistory shows none of these errors and those tests print PASS.")
	$md.Add("Report: files changed, root cause per error, the new Error Lab result line.")
	$md.Add('```')
}
if ($groups.Count -eq 0) { $md.Add(""); $md.Add("No briefs: nothing to fix.") }
[System.IO.File]::WriteAllLines((Join-Path $OutDir "scorecard.md"), $md, (New-Object System.Text.UTF8Encoding($false)))

$json = [pscustomobject]@{
	lab = "error_lab"; version = $LabVersion; run = $Run; time = $now; project = $Root; result = $result; score = $score
	unique_fail = $uF; unique_warn = $uW; info = $uI; new = $uNew; previous_run = $(if ($prev) { $prev.run } else { "" })
	tests = @($testRows | Select-Object test, ok, why, kind, hint, exit, seconds, cap, owner, verdict, inner_fail, fail_lines, tail, log)
	failed_tests = @($failedTests | ForEach-Object { $_.test })
	owners = @($ownerOrder | ForEach-Object { [pscustomobject]@{ owner = $_; fail = @($groups[$_].errors | Where-Object { $_.severity -eq "FAIL" }).Count
		warn = @($groups[$_].errors | Where-Object { $_.severity -eq "WARN" }).Count; failed_tests = @($groups[$_].tests | ForEach-Object { $_.test }) } })
	errors = @($ranked + @($errors.Values | Where-Object { $_.severity -eq "INFO" }) | ForEach-Object {
		[pscustomobject]@{ severity = $_.severity; new = $_.new; location = $_.location; file = $_.file; line = $_.line; func = $_.func; owner = $_.owner
			message = $_.message; example = $_.example; count = $_.count; tests = @($_.tests); key = $_.key } })
	gone = @($gone)
	improve_next = @(@($failedTests | Select-Object -First 2 | ForEach-Object { "tests/$($_.test).gd ($($_.owner)): $($_.kind)" }) + @($ranked | Select-Object -First 3 | ForEach-Object { "$($_.location) ($($_.owner)): $($_.message)" }) | Select-Object -First 3)
}
[System.IO.File]::WriteAllText((Join-Path $OutDir "scorecard.json"), ($json | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))

if (-not $NoHistory) {
	$h = [pscustomobject]@{ run = $Run; time = $now; result = $result; score = $score; tests = $testRows.Count; failed_tests = $failedTests.Count
		failed = @($failedTests | ForEach-Object { $_.test }); unique_fail = $uF; unique_warn = $uW; new = $uNew; keys = @($real | ForEach-Object { $_.key }) }
	New-Item -ItemType Directory -Force (Split-Path $HistoryFile) | Out-Null
	[System.IO.File]::AppendAllText($HistoryFile, ($h | ConvertTo-Json -Depth 4 -Compress) + "`n", (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "ERROR LAB: $result score $score / 100 ($uF FAIL, $uW WARN, $uI info unique errors; $uNew NEW; $($failedTests.Count) / $($testRows.Count) tests failed)"
foreach ($t in ($failedTests | Select-Object -First 5)) { Write-Host "  TEST $($t.test): $($t.kind) [$($t.owner)]$(if ($t.fail_lines.Count -gt 0) { ' ' + $t.fail_lines[0] })" }
foreach ($e in ($ranked | Select-Object -First 3)) { Write-Host "  $($e.severity) $($e.location) [$($e.owner)] $($e.message)" }
Write-Host "  scorecard: $(Join-Path $OutDir 'scorecard.md')"
if ($result -eq "FAIL") { exit 1 }
exit 0
