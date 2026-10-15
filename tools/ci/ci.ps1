# CI: full integration check of a project folder: import, smoke x3 (victory=true), perf 100 / 200 units (PERF OK),
# then every tests/test_*.gd through the Error Lab (parallel, caps, owners, log tails, fix-agent briefs).
# Every Godot run goes through tools/godot_run.ps1 (the Godot gate). Windows PowerShell 5.1. Never changes git (it only
# reads the HEAD commit for its history row, so tools\ci\ci_quick.ps1 -Changed -Base last-green can diff from it).
# Docs: docs/plan/error-lab.md section "CI".
#
#   tools\ci\ci.ps1                                  # the CI copy if it exists (desktop), else this repo in place
#   tools\ci\ci.ps1 -Dir .                           # this repo in place
#   tools\ci\ci.ps1 -Tests test_16a,test_12_c2       # import + smoke + perf + a test subset
#   tools\ci\ci.ps1 -SkipTests -SmokeRuns 1          # quick gate (import, 1 smoke, perf)
#   tools\ci\ci.ps1 -Parallel 3                      # default 4 (= the gate's slots; was 3 before 2026-10-02)
#   tools\ci\ci.ps1 -Full                            # also play the early-stop bot tests to the end (-- --full)
#   tools\ci\ci.ps1 -NoFull                          # a full-suite run WITHOUT the long tails
# Everyday runs: tools\ci\ci_quick.ps1 (no slow simulations) or ci_quick.ps1 -Changed (tests of the changed files).
# Milestone / nightly CI = `tools\ci\ci.ps1` with no -Tests: it runs the whole suite AND turns -Full on by itself, so the
# early-stop bot tests ($EarlyStopTests: they stop once their verdict is final) still play their late game once per
# milestone and a late-game SCRIPT ERROR fails the CI. -NoFull opts out; -Full also works with -Tests.
# History (docs/ci/history.jsonl): every row has `scope` = "full" (whole suite, with the long tails), "full-short"
# (whole suite, -NoFull), "subset" (-Tests) or "no-tests" (-SkipTests); ci_quick -Base last-green only trusts "full".
param(
	[string]$Dir = "",
	[string]$ResultFile = "",         # extra copy of the result lines (the old scratchpad ci_result.txt)
	[string]$OutDir = "",             # default docs/ci/<run>/ in this repo
	[string]$Run = "",
	[int]$SmokeRuns = 3,
	[int[]]$PerfUnits = @(100, 200),
	[string]$PerfScript = "tests/perf_test.gd",   # another perf script (a staged copy) for checking the gate itself
	[string[]]$Tests = @(),
	[switch]$SkipImport,
	[switch]$SkipSmoke,
	[switch]$SkipPerf,
	[switch]$SkipTests,
	[int]$Parallel = 4,
	[int]$RunTimeoutSec = 1800,
	[switch]$NoHistory,
	[switch]$Full,
	[switch]$NoFull
)
$ErrorActionPreference = "Stop"
$CiVersion = "2.3"
# Tests with an early stop (their verdict is final before the match ends); `-- --full` plays the whole match.
$EarlyStopTests = @("test_8_a1", "test_8_a2", "test_9_c11", "test_casters_bots")
$wholeSuite = (-not $SkipTests) -and $Tests.Count -eq 0
if ($wholeSuite -and -not $NoFull) { $Full = [switch]$true }   # milestone CI: the long tails run once per milestone
if ($NoFull) { $Full = [switch]$false }
$Scope = if ($SkipTests) { "no-tests" } elseif ($Tests.Count -gt 0) { "subset" } elseif ($Full) { "full" } else { "full-short" }
$LabRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
while ($LabRoot -and -not (Test-Path (Join-Path $LabRoot "project.godot"))) { $LabRoot = Split-Path $LabRoot -Parent }   # a staged copy
$Gate = Join-Path $LabRoot "tools\godot_run.ps1"
$ErrorLab = Join-Path $LabRoot "tools\error_lab\error_lab.ps1"
if (-not $Dir) {
	# Desktop: the dedicated CI worktree next to the repo; laptop (no worktree): this repo in place.
	$ciCopy = Join-Path (Split-Path $LabRoot) "four-wizards-rts-ci"
	if (Test-Path (Join-Path $ciCopy "project.godot")) { $Dir = $ciCopy } else { $Dir = $LabRoot }
}
if (-not (Test-Path (Join-Path $Dir "project.godot"))) { Write-Host "CI: no project.godot in $Dir"; exit 2 }
$Dir = (Resolve-Path $Dir).Path
. (Join-Path $LabRoot "tools\error_lab\harness.ps1")   # unique run folders, log / disk checks (error-lab.md 3g)
if (-not $Run) {
	# Unique per run: two CIs started in the same minute used to share docs/ci/<run>/ and fight over the same logs
	# (the loser's cmd exited 1 in 0.1 s without Godot and read the winner's PASS log).
	$Run = Get-Date -Format "yyyy-MM-dd_HHmm"
	if (-not $OutDir) { $Run = New-UniqueRun (Join-Path $LabRoot "docs\ci") $Run }
}
if (-not $OutDir) { $OutDir = Join-Path $LabRoot "docs\ci\$Run" }
$LogDir = Join-Path $OutDir "logs"
New-Item -ItemType Directory -Force $LogDir | Out-Null
$Utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($pd in @($LogDir, $Dir)) {
	$free = Get-FreeMB $pd
	if ($free -ge 0 -and $free -lt $HarnessMinFreeMB) { Write-Host "CI: DISK FULL: $free MB free on $([IO.Path]::GetPathRoot($pd)) (need $HarnessMinFreeMB MB): free space, then rerun"; exit 3 }
}

$Steps = New-Object System.Collections.ArrayList
function Add-Step([string]$name, [string]$status, [string]$detail, [string]$fix = "") {
	[void]$Steps.Add([pscustomobject]@{ step = $name; status = $status; detail = $detail; fix = $fix })
	$c = "Gray"; if ($status -eq "FAIL") { $c = "Red" } elseif ($status -eq "WARN") { $c = "Yellow" } elseif ($status -eq "PASS") { $c = "Green" }
	Write-Host ("  [{0}] {1}: {2}" -f $status, $name, $detail) -ForegroundColor $c
}
# One Godot run through the gate, stdout + stderr in one log; returns @{ exit; seconds; timed_out; lines; harness }.
# harness = why the run failed outside Godot (locked log, full disk, log not written by this run), else "".
function Invoke-Godot([string[]]$godotArgs, [string]$log) {
	$why = Test-LogWritable $log
	if ($why) { return @{ exit = -3; seconds = 0; timed_out = $false; lines = @(); harness = $why } }
	$q = @($godotArgs | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
	$cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$Gate`" $q > `"$log`" 2>&1"
	$start = Get-Date
	$p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$cmd`"" -WorkingDirectory $Dir -WindowStyle Hidden -PassThru
	$null = $p.Handle
	$timedOut = $false
	while (-not $p.HasExited) {
		if (((Get-Date) - $start).TotalSeconds -gt $RunTimeoutSec) { & taskkill.exe /T /F /PID $p.Id | Out-Null; $timedOut = $true; break }   # our own tree only
		Start-Sleep -Milliseconds 500
	}
	$p.WaitForExit(5000) | Out-Null
	$code = -1; if (-not $timedOut) { $code = $p.ExitCode }
	$hw = ""; if (-not $timedOut) { $hw = Get-HarnessReason $log $start $code }
	$lines = @(); if ((Test-Path $log) -and -not $hw) { $lines = @(Get-Content $log -Encoding UTF8) }   # never judge another run's log
	return @{ exit = $code; seconds = [math]::Round(((Get-Date) - $start).TotalSeconds, 1); timed_out = $timedOut; lines = $lines; harness = $hw }
}
function Count-Godot() { return @(Get-Process -Name "Godot_v4.7.2*" -ErrorAction SilentlyContinue).Count }

Write-Host "CI v$CiVersion run $Run on $Dir -> $OutDir"
$out = New-Object System.Collections.Generic.List[string]   # the classic result lines

# ---------- 1. import ----------
if (-not $SkipImport) {
	$r = Invoke-Godot @("--headless", "--path", $Dir, "--import") (Join-Path $LogDir "import.log")
	$errs = @($r.lines | Where-Object { $_ -match 'SCRIPT ERROR|Parse Error' } | Select-Object -First 5)
	foreach ($e in $errs) { $out.Add("IMPORT: $e") }
	if ($r.harness) { Add-Step "Import" "FAIL" "HARNESS (runner, not Godot): $($r.harness)" "Free disk space / stop the run sharing docs/ci/$Run, then rerun." }
	elseif ($r.timed_out) { Add-Step "Import" "FAIL" "timed out after $RunTimeoutSec s (logs/import.log)" }
	elseif ($errs.Count -gt 0) { Add-Step "Import" "FAIL" "$($errs.Count)+ script / parse errors, first: $($errs[0].Trim())" "Fix the script named in logs/import.log (owner: CLAUDE.md 'Who owns what')." }
	else { Add-Step "Import" "PASS" "no script / parse errors ($($r.seconds) s)" }
}

# ---------- 2. smoke ----------
if (-not $SkipSmoke -and $SmokeRuns -gt 0) {
	$wins = 0; $bad = @()
	foreach ($i in 1..$SmokeRuns) {
		$r = Invoke-Godot @("--headless", "--path", $Dir, "-s", "tests/smoke_test.gd", "--fixed-fps", "60", "--quit-after", "7000") (Join-Path $LogDir "smoke_$i.log")
		$go = @($r.lines | Where-Object { $_ -match 'GAME OVER|TIMEOUT|SCRIPT ERROR|^FAIL' } | Select-Object -First 2)
		foreach ($g in $go) { $out.Add("SMOKE: $($g.Trim())") }
		if (@($r.lines | Where-Object { $_ -match 'victory=true' }).Count -gt 0) { $wins++ }
		elseif ($r.harness) { $bad += "run $i`: HARNESS (runner, not Godot, exit $($r.exit)): $($r.harness)" }
		else { $bad += "run $i`: $(if ($go.Count) { $go[0].Trim() } elseif ($r.timed_out) { 'timed out' } else { 'no GAME OVER line' })" }
	}
	if ($wins -eq $SmokeRuns) { Add-Step "Smoke" "PASS" "$wins / $SmokeRuns victory=true" }
	else { Add-Step "Smoke" "FAIL" ("{0} / {1} victory=true; {2}" -f $wins, $SmokeRuns, ($bad -join '; ')) "Read logs/smoke_N.log; run the Error Lab with -Changed on the changed files." }
}

# ---------- 3. perf ----------
# Load-proof gate (2026-10-14): perf_test.gd times a fixed calibration slice every frame and judges the frame time
# divided by that load factor ("PERF load ... norm_ms_per_frame"), so other Godot runs / the slow cores no longer fail
# it while a real regression (game slower, calibration not) still does. A timing-only miss (stuck=0) is measured once
# more and the better run counts (a real regression misses twice). The raw line ("PERF units ... ms_per_frame") stays
# in the result lines for history. WARN instead of FAIL only when the machine was more than $PerfMaxLoad x slower than
# the quiet reference (the normalisation is then less trustworthy).
$PerfMaxLoad = 2.5
function Read-Perf([object]$r) {
	$pl = @($r.lines | Where-Object { $_ -match '^PERF units' } | Select-Object -First 1)
	$ll = @($r.lines | Where-Object { $_ -match '^PERF load' } | Select-Object -First 1)
	$norm = -1.0; $load = 1.0
	if ($ll.Count -and $ll[0] -match 'norm_ms_per_frame=([\d.]+)') { $norm = [double]$Matches[1] }
	if ($ll.Count -and $ll[0] -match ' load=([\d.]+)') { $load = [double]$Matches[1] }
	return @{ raw = $(if ($pl.Count) { $pl[0].Trim() } else { "" }); load_line = $(if ($ll.Count) { $ll[0].Trim() } else { "" })
		ok = (@($r.lines | Where-Object { $_ -match '^PERF OK' }).Count -gt 0); norm = $norm; load = $load
		stuck0 = ($pl.Count -gt 0 -and $pl[0] -match 'stuck=0') }
}
if (-not $SkipPerf) {
	foreach ($n in $PerfUnits) {
		$busy = Count-Godot
		$r = Invoke-Godot @("--headless", "--path", $Dir, "-s", $PerfScript, "--fixed-fps", "60", "--quit-after", "3000", "--", "units=$n") (Join-Path $LogDir "perf_$n.log")
		$pf = Read-Perf $r
		$tries = 1
		if (-not $pf.ok -and $pf.stuck0) {
			# Timing-only miss: measure once more, keep the better run.
			$r2 = Invoke-Godot @("--headless", "--path", $Dir, "-s", $PerfScript, "--fixed-fps", "60", "--quit-after", "3000", "--", "units=$n") (Join-Path $LogDir "perf_${n}_retry.log")
			$pf2 = Read-Perf $r2
			$tries = 2
			if ($pf2.raw -and ($pf2.ok -or ($pf2.norm -ge 0 -and ($pf.norm -lt 0 -or $pf2.norm -lt $pf.norm)))) { $pf = $pf2; $r = $r2 }
		}
		$busy = [math]::Max($busy, (Count-Godot))
		if ($pf.raw) { $out.Add($pf.raw) }
		if ($pf.load_line) { $out.Add($pf.load_line) }
		$detail = if ($pf.raw) { $pf.raw + $(if ($pf.norm -ge 0) { " | load x{0:N2}, normalised {1:N2} ms" -f $pf.load, $pf.norm } else { "" }) + $(if ($tries -gt 1) { " (2 runs, the better kept)" } else { "" }) } elseif ($r.harness) { "HARNESS (runner, not Godot, exit $($r.exit)): $($r.harness)" } else { "no PERF line (exit $($r.exit), logs/perf_$n.log)" }
		if ($pf.ok) { Add-Step "Perf $n units" "PASS" $detail }
		elseif ($pf.stuck0 -and $pf.load -gt $PerfMaxLoad) {
			Add-Step "Perf $n units" "WARN" "$detail - OVER BUDGET with the PC $("{0:N1}" -f $pf.load) x slower than the quiet reference ($busy Godot processes): too loaded to judge" "Re-run on a quieter PC (Perf Lab: tools\perf_lab\run_perf_lab.ps1 -WaitQuietS 600)."
		} else { Add-Step "Perf $n units" "FAIL" $detail "Read logs/perf_$n.log (stuck units = a pathing bug; normalised ms over budget = a real slowdown: the Perf Lab breakdown)." }
	}
}

# ---------- 4. tests through the Error Lab ----------
$el = $null
if (-not $SkipTests) {
	$elOut = Join-Path $OutDir "error_lab"
	$elArgs = @{ ProjectDir = $Dir; OutDir = $elOut; Run = "ci-$Run"; Parallel = $Parallel }
	if ($Tests.Count -gt 0) { $elArgs.Tests = @($Tests | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
	if ($NoHistory -or $Tests.Count -gt 0) { $elArgs.NoHistory = $true }   # only full runs go into the Error Lab history
	if ($Full) { $elArgs.FullTests = $EarlyStopTests }
	Write-Host "CI: tests through the Error Lab ($elOut)$(if ($Full) { ' with the long tails (--full: ' + ($EarlyStopTests -join ', ') + ')' })..."
	& $ErrorLab @elArgs | ForEach-Object { Write-Host $_ }
	$jf = Join-Path $elOut "scorecard.json"
	if (Test-Path $jf) {
		$el = Get-Content $jf -Raw -Encoding UTF8 | ConvertFrom-Json
		$nT = @($el.tests).Count; $nF = @($el.failed_tests).Count
		$nH = @($el.tests | Where-Object { $_.kind -eq "harness" }).Count
		$out.Add("tests run: $nT, failed: $nF")
		foreach ($t in @($el.tests | Where-Object { -not $_.ok })) { $out.Add("FAIL-> $($t.test): $($t.kind) ($($t.why)) [$($t.owner)]$(if (@($t.fail_lines).Count) { ' ' + @($t.fail_lines)[0] })") }
		$st = if ($nF -gt 0 -or $el.unique_fail -gt 0) { "FAIL" } elseif ($el.unique_warn -gt 0) { "WARN" } else { "PASS" }
		$fix = ""; if ($st -ne "PASS") { $fix = "Open error_lab/scorecard.md: 'By owner' + one fix-agent brief per owner." }
		Add-Step "Tests (Error Lab)" $st ("{0} / {1} tests pass; Error Lab {2} {3} / 100 ({4} FAIL, {5} WARN unique errors, {6} NEW)" -f ($nT - $nF), $nT, $el.result, $el.score, $el.unique_fail, $el.unique_warn, $el.new) $fix
		if ($nH -gt 0) { Add-Step "Harness" "FAIL" "$nH test(s) failed OUTSIDE Godot (kind harness: locked log / full disk / log of another run), first: $(@($el.tests | Where-Object { $_.kind -eq 'harness' })[0].why)" "Not a code bug: free disk space or stop the parallel run, then rerun those tests." }
	} else { Add-Step "Tests (Error Lab)" "FAIL" "the Error Lab wrote no scorecard ($jf)" }
}

# ---------- result ----------
$nFail = @($Steps | Where-Object { $_.status -eq "FAIL" }).Count
$nWarn = @($Steps | Where-Object { $_.status -eq "WARN" }).Count
$result = if ($nFail -gt 0) { "FAIL" } elseif ($nWarn -gt 0) { "WARN" } else { "PASS" }
$summary = "CI: $result - " + (($Steps | ForEach-Object { "$($_.step) $($_.status)" }) -join ", ")
$out.Insert(0, $summary)
$now = Get-Date -Format "yyyy-MM-dd HH:mm"
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# CI: $Run"); $md.Add("")
$md.Add("$now - ci v$CiVersion - project ``$Dir`` - scope **$Scope**"); $md.Add("")
$md.Add("## Result: **$result**"); $md.Add("")
$md.Add("| Step | Result | Detail | Fix |"); $md.Add("|---|---|---|---|")
foreach ($s in $Steps) { $md.Add("| $($s.step) | $(if ($s.status -eq 'FAIL') { '**FAIL**' } else { $s.status }) | $($s.detail -replace '\|', '\|') | $($s.fix -replace '\|', '\|') |") }
$md.Add("")
if ($el) {
	$md.Add("## Tests by owner (from the Error Lab)")
	$md.Add("| Owner | FAIL errors | WARN errors | Failed tests |"); $md.Add("|---|---|---|---|")
	foreach ($o in @($el.owners)) { $md.Add("| $($o.owner) | $($o.fail) | $($o.warn) | $(@($o.failed_tests) -join ', ') |") }
	if (@($el.owners).Count -eq 0) { $md.Add("| - | 0 | 0 | - |") }
	$md.Add(""); $md.Add("Full report, log tails and fix-agent briefs: ``error_lab/scorecard.md``."); $md.Add("")
}
$md.Add("## Result lines"); $md.Add('```text'); foreach ($l in $out) { $md.Add($l) }; $md.Add('```')
$md.Add(""); $md.Add("Logs: ``$LogDir``.")
[IO.File]::WriteAllLines((Join-Path $OutDir "ci.md"), $md, $Utf8)
[IO.File]::WriteAllLines((Join-Path $OutDir "ci_result.txt"), $out, $Utf8)
if ($ResultFile) { New-Item -ItemType Directory -Force (Split-Path $ResultFile) | Out-Null; [IO.File]::WriteAllLines($ResultFile, $out, $Utf8) }
if (-not $NoHistory) {
	# The tested commit (read only), for ci_quick.ps1 -Changed -Base last-green.
	$commit = ""
	try {
		$gitExe = "git"; if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $gitExe = "C:\Program Files\Git\cmd\git.exe" }
		$commit = (& $gitExe -C $Dir rev-parse HEAD 2>$null | Select-Object -First 1)
		if ($LASTEXITCODE -ne 0) { $commit = "" }
	} catch { $commit = "" }
	$h = [pscustomobject]@{ run = $Run; time = $now; dir = $Dir; commit = "$commit"; result = $result; scope = $Scope; steps =@($Steps | ForEach-Object { "$($_.step)=$($_.status)" })
		tests = $(if ($el) { @($el.tests).Count } else { 0 }); failed = $(if ($el) { @($el.failed_tests) } else { @() }) }
	[IO.File]::AppendAllText((Join-Path $LabRoot "docs\ci\history.jsonl"), ($h | ConvertTo-Json -Depth 4 -Compress) + "`n", $Utf8)
}
Write-Host ""
$out | ForEach-Object { Write-Host $_ }
Write-Host "  report: $(Join-Path $OutDir 'ci.md')"
if ($result -eq "FAIL") { exit 1 }
exit 0
