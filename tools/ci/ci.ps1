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
# Everyday runs: tools\ci\ci_quick.ps1 (no slow simulations) or ci_quick.ps1 -Changed (tests of the changed files).
param(
	[string]$Dir = "",
	[string]$ResultFile = "",         # extra copy of the result lines (the old scratchpad ci_result.txt)
	[string]$OutDir = "",             # default docs/ci/<run>/ in this repo
	[string]$Run = "",
	[int]$SmokeRuns = 3,
	[int[]]$PerfUnits = @(100, 200),
	[string[]]$Tests = @(),
	[switch]$SkipImport,
	[switch]$SkipSmoke,
	[switch]$SkipPerf,
	[switch]$SkipTests,
	[int]$Parallel = 4,
	[int]$RunTimeoutSec = 1800,
	[switch]$NoHistory
)
$ErrorActionPreference = "Stop"
$CiVersion = "2.1"
$LabRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Gate = Join-Path $LabRoot "tools\godot_run.ps1"
$ErrorLab = Join-Path $LabRoot "tools\error_lab\error_lab.ps1"
if (-not $Dir) {
	# Desktop: the dedicated CI worktree next to the repo; laptop (no worktree): this repo in place.
	$ciCopy = Join-Path (Split-Path $LabRoot) "four-wizards-rts-ci"
	if (Test-Path (Join-Path $ciCopy "project.godot")) { $Dir = $ciCopy } else { $Dir = $LabRoot }
}
if (-not (Test-Path (Join-Path $Dir "project.godot"))) { Write-Host "CI: no project.godot in $Dir"; exit 2 }
$Dir = (Resolve-Path $Dir).Path
if (-not $Run) { $Run = Get-Date -Format "yyyy-MM-dd_HHmm" }
if (-not $OutDir) { $OutDir = Join-Path $LabRoot "docs\ci\$Run" }
$LogDir = Join-Path $OutDir "logs"
New-Item -ItemType Directory -Force $LogDir | Out-Null
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Steps = New-Object System.Collections.ArrayList
function Add-Step([string]$name, [string]$status, [string]$detail, [string]$fix = "") {
	[void]$Steps.Add([pscustomobject]@{ step = $name; status = $status; detail = $detail; fix = $fix })
	$c = "Gray"; if ($status -eq "FAIL") { $c = "Red" } elseif ($status -eq "WARN") { $c = "Yellow" } elseif ($status -eq "PASS") { $c = "Green" }
	Write-Host ("  [{0}] {1}: {2}" -f $status, $name, $detail) -ForegroundColor $c
}
# One Godot run through the gate, stdout + stderr in one log; returns @{ exit; seconds; timed_out; lines }.
function Invoke-Godot([string[]]$godotArgs, [string]$log) {
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
	$lines = @(); if (Test-Path $log) { $lines = @(Get-Content $log -Encoding UTF8) }
	return @{ exit = $code; seconds = [math]::Round(((Get-Date) - $start).TotalSeconds, 1); timed_out = $timedOut; lines = $lines }
}
function Count-Godot() { return @(Get-Process -Name "Godot_v4.7.2*" -ErrorAction SilentlyContinue).Count }

Write-Host "CI v$CiVersion run $Run on $Dir -> $OutDir"
$out = New-Object System.Collections.Generic.List[string]   # the classic result lines

# ---------- 1. import ----------
if (-not $SkipImport) {
	$r = Invoke-Godot @("--headless", "--path", $Dir, "--import") (Join-Path $LogDir "import.log")
	$errs = @($r.lines | Where-Object { $_ -match 'SCRIPT ERROR|Parse Error' } | Select-Object -First 5)
	foreach ($e in $errs) { $out.Add("IMPORT: $e") }
	if ($r.timed_out) { Add-Step "Import" "FAIL" "timed out after $RunTimeoutSec s (logs/import.log)" }
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
		else { $bad += "run $i`: $(if ($go.Count) { $go[0].Trim() } elseif ($r.timed_out) { 'timed out' } else { 'no GAME OVER line' })" }
	}
	if ($wins -eq $SmokeRuns) { Add-Step "Smoke" "PASS" "$wins / $SmokeRuns victory=true" }
	else { Add-Step "Smoke" "FAIL" ("{0} / {1} victory=true; {2}" -f $wins, $SmokeRuns, ($bad -join '; ')) "Read logs/smoke_N.log; run the Error Lab with -Changed on the changed files." }
}

# ---------- 3. perf ----------
if (-not $SkipPerf) {
	foreach ($n in $PerfUnits) {
		$busy = Count-Godot
		$r = Invoke-Godot @("--headless", "--path", $Dir, "-s", "tests/perf_test.gd", "--fixed-fps", "60", "--quit-after", "3000", "--", "units=$n") (Join-Path $LogDir "perf_$n.log")
		$busy = [math]::Max($busy, (Count-Godot))
		$pl = @($r.lines | Where-Object { $_ -match '^PERF units' } | Select-Object -First 1)
		$ok = @($r.lines | Where-Object { $_ -match '^PERF OK' }).Count -gt 0
		foreach ($l in $pl) { $out.Add($l.Trim()) }
		$detail = if ($pl.Count) { $pl[0].Trim() } else { "no PERF line (exit $($r.exit), logs/perf_$n.log)" }
		if ($ok) { Add-Step "Perf $n units" "PASS" $detail }
		elseif ($pl.Count -gt 0 -and $pl[0] -match 'stuck=0' -and $busy -ge 2) {
			# Frame times are noise while other Godot runs share the CPU: never a FAIL, re-measure on a quiet PC.
			Add-Step "Perf $n units" "WARN" "$detail - OVER BUDGET while $busy Godot processes ran on the PC (noise, not a verdict)" "Re-run on a quiet PC (Perf Lab: tools\perf_lab\run_perf_lab.ps1 -WaitQuietS 600)."
		} else { Add-Step "Perf $n units" "FAIL" $detail "Read logs/perf_$n.log (stuck units = a pathing bug; ms over budget on a quiet PC = the Perf Lab breakdown)." }
	}
}

# ---------- 4. tests through the Error Lab ----------
$el = $null
if (-not $SkipTests) {
	$elOut = Join-Path $OutDir "error_lab"
	$elArgs = @{ ProjectDir = $Dir; OutDir = $elOut; Run = "ci-$Run"; Parallel = $Parallel }
	if ($Tests.Count -gt 0) { $elArgs.Tests = @($Tests | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
	if ($NoHistory -or $Tests.Count -gt 0) { $elArgs.NoHistory = $true }   # only full runs go into the Error Lab history
	Write-Host "CI: tests through the Error Lab ($elOut)..."
	& $ErrorLab @elArgs | ForEach-Object { Write-Host $_ }
	$jf = Join-Path $elOut "scorecard.json"
	if (Test-Path $jf) {
		$el = Get-Content $jf -Raw -Encoding UTF8 | ConvertFrom-Json
		$nT = @($el.tests).Count; $nF = @($el.failed_tests).Count
		$out.Add("tests run: $nT, failed: $nF")
		foreach ($t in @($el.tests | Where-Object { -not $_.ok })) { $out.Add("FAIL-> $($t.test): $($t.kind) ($($t.why)) [$($t.owner)]$(if (@($t.fail_lines).Count) { ' ' + @($t.fail_lines)[0] })") }
		$st = if ($nF -gt 0 -or $el.unique_fail -gt 0) { "FAIL" } elseif ($el.unique_warn -gt 0) { "WARN" } else { "PASS" }
		$fix = ""; if ($st -ne "PASS") { $fix = "Open error_lab/scorecard.md: 'By owner' + one fix-agent brief per owner." }
		Add-Step "Tests (Error Lab)" $st ("{0} / {1} tests pass; Error Lab {2} {3} / 100 ({4} FAIL, {5} WARN unique errors, {6} NEW)" -f ($nT - $nF), $nT, $el.result, $el.score, $el.unique_fail, $el.unique_warn, $el.new) $fix
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
$md.Add("$now - ci v$CiVersion - project ``$Dir``"); $md.Add("")
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
	$h = [pscustomobject]@{ run = $Run; time = $now; dir = $Dir; commit = "$commit"; result = $result; steps = @($Steps | ForEach-Object { "$($_.step)=$($_.status)" })
		tests = $(if ($el) { @($el.tests).Count } else { 0 }); failed = $(if ($el) { @($el.failed_tests) } else { @() }) }
	[IO.File]::AppendAllText((Join-Path $LabRoot "docs\ci\history.jsonl"), ($h | ConvertTo-Json -Depth 4 -Compress) + "`n", $Utf8)
}
Write-Host ""
$out | ForEach-Object { Write-Host $_ }
Write-Host "  report: $(Join-Path $OutDir 'ci.md')"
if ($result -eq "FAIL") { exit 1 }
exit 0
