# Measures the changed-only test selection (select_tests.ps1) against the old name-based one (select_tests_legacy.ps1)
# on real change sets, and checks the picks against the tests that failed in the CI reports (docs/ci/*/error_lab).
# Windows PowerShell 5.1. Reads git (log / diff-tree only). No Godot run.
#
#   tools\ci\measure_selection.ps1                     # the last 10 commits (one change set per commit)
#   tools\ci\measure_selection.ps1 -Commits 20
#   tools\ci\measure_selection.ps1 -ChangeSets sets.json   # [{ "name": "...", "time": "2026-10-14 14:46", "files": [...] }]
# Per change set: tests picked by the old selection, by the new one in -Mode reach (every reaching test) and in -Mode near
# (the default: tests within -NearHops hops), plus the estimated test time (sum of each test's seconds in the latest full Error Lab scorecard).
# Failure check: every CI run with failed tests is matched to the last change set before it (and the one before that);
# a failed test the selection would not have picked is listed as a MISS (a test that fails on its own, flaky or already
# red, is a MISS for every selection: compare the columns).
param(
	[int]$Commits = 10,
	[string]$ChangeSets = "",
	[string]$Root = "",
	[double]$WideShare = 0.5,
	[int]$NearHops = 3,
	[string]$Out = ""
)
$ErrorActionPreference = "Stop"
if (-not $Root) {
	$d = $PSScriptRoot
	while ($d -and -not (Test-Path (Join-Path $d "project.godot"))) { $d = Split-Path $d -Parent }
	$Root = $d
}
$Root = (Resolve-Path $Root).Path.TrimEnd('\')
$sel = Join-Path $PSScriptRoot "select_tests.ps1"
$legacy = Join-Path $PSScriptRoot "select_tests_legacy.ps1"

function Invoke-Git([string[]]$a) {
	$git = "git"
	if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $git = "C:\Program Files\Git\cmd\git.exe" }
	$eap = $ErrorActionPreference; $ErrorActionPreference = "Continue"
	try { $o = @(& $git -C $Root @a 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" }); $code = $LASTEXITCODE }
	finally { $ErrorActionPreference = $eap }
	if ($code -ne 0) { throw "git $($a -join ' ') failed (exit $code)" }
	return @($o)
}

# ---------- change sets ----------
$sets = @()
if ($ChangeSets) {
	$arr = Get-Content $ChangeSets -Raw | ConvertFrom-Json   # PS 5.1: one array object, enumerated by foreach
	foreach ($s in $arr) {
		$sets += [pscustomobject]@{ name = $s.name; time = [datetime]$s.time; files = @($s.files) }
	}
} else {
	foreach ($l in (Invoke-Git @("log", "-$Commits", "--format=%H|%ct|%s"))) {
		$c = $l.Split('|', 3)
		$files = @(Invoke-Git @("diff-tree", "--no-commit-id", "--name-only", "-r", "--root", $c[0]))
		$t = ([datetime]'1970-01-01Z').AddSeconds([double]$c[1]).ToLocalTime()
		$subj = $c[2]; if ($subj.Length -gt 50) { $subj = $subj.Substring(0, 47) + "..." }
		$sets += [pscustomobject]@{ name = "$($c[0].Substring(0, 8)) $subj"; time = $t; files = $files }
	}
	[array]::Reverse($sets)   # oldest first
}
$sets = @($sets | Sort-Object time)

# ---------- test durations (latest Error Lab scorecard with the most tests) ----------
$dur = @{}
$cards = @(Get-ChildItem (Join-Path $Root "docs\ci") -Directory | ForEach-Object { Join-Path $_.FullName "error_lab\scorecard.json" } | Where-Object { Test-Path $_ })
$bestCard = $null; $bestN = 0
foreach ($cf in ($cards | Sort-Object { (Get-Item $_).LastWriteTime } -Descending | Select-Object -First 15)) {
	try { $j = Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
	if (@($j.tests).Count -gt $bestN) { $bestN = @($j.tests).Count; $bestCard = $j }
}
if ($bestCard) { foreach ($t in @($bestCard.tests)) { $dur[$t.test] = [double]$t.seconds } }
function Get-Secs([string[]]$tests) { $s = 0.0; foreach ($t in $tests) { if ($dur.ContainsKey($t)) { $s += $dur[$t] } else { $s += 30 } }; return $s }

# ---------- picks ----------
$rows = @()
foreach ($s in $sets) {
	$files = @($s.files | Where-Object { $_ })
	if ($files.Count -eq 0) { continue }
	$old = & $legacy -Files $files -Root $Root 6>$null
	$new = & $sel -Files $files -Root $Root -Quiet -WideShare $WideShare -Mode reach
	$near = & $sel -Files $files -Root $Root -Quiet -WideShare $WideShare -Mode near -NearHops $NearHops
	$rows += [pscustomobject]@{ name = $s.name; time = $s.time; files = $files.Count
		old = @($old.tests); old_full = [bool]$old.full; new = @($new.tests); near = @($near.tests); wide = @($new.wide).Count }
}

# ---------- failures from the CI reports ----------
$runs = @()
foreach ($dir in (Get-ChildItem (Join-Path $Root "docs\ci") -Directory)) {
	$cf = Join-Path $dir.FullName "error_lab\scorecard.json"
	if (-not (Test-Path $cf)) { continue }
	try { $j = Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
	$failed = @($j.failed_tests | Where-Object { $_ })
	if ($failed.Count -eq 0) { continue }
	$t = (Get-Item $cf).LastWriteTime
	if ($dir.Name -match '^(\d{4}-\d{2}-\d{2})_(\d{2})(\d{2})') { $t = [datetime]::ParseExact("$($Matches[1]) $($Matches[2]):$($Matches[3])", "yyyy-MM-dd HH:mm", $null) }
	$runs += [pscustomobject]@{ run = $dir.Name; time = $t; failed = $failed }
}
$first = if ($rows.Count) { ($rows | Select-Object -First 1).time } else { Get-Date }
$runs = @($runs | Where-Object { $_.time -ge $first } | Sort-Object time)
$miss = @{ old = 0; new = 0; near = 0 }; $nFail = 0
$failRows = @()
foreach ($r in $runs) {
	# The change set this run tested: the last one before it; the one before that too (a run on uncommitted work).
	$before = @($rows | Where-Object { $_.time -le $r.time } | Select-Object -Last 2)
	if ($before.Count -eq 0) { continue }
	$o = @(); $n = @(); $nn = @(); $full = $false
	foreach ($b in $before) { $o += $b.old; $n += $b.new; $nn += $b.near; if ($b.old_full) { $full = $true } }
	foreach ($t in $r.failed) {
		$nFail++
		$po = $o -contains $t; $pn = $n -contains $t; $pnn = $nn -contains $t
		if (-not $po) { $miss.old++ }; if (-not $pn) { $miss.new++ }; if (-not $pnn) { $miss.near++ }
		if (-not ($po -and $pn -and $pnn)) { $failRows += "  {0} {1,-28} old {2} reach {3} near {4}  (change sets: {5})" -f $r.run, $t, $(if ($po) { "yes" } else { "MISS" }), $(if ($pn) { "yes" } else { "MISS" }), $(if ($pnn) { "yes" } else { "MISS" }), (($before | ForEach-Object { $_.name.Split(' ')[0] }) -join ", ") }
	}
}

# ---------- report ----------
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("measure_selection: $($rows.Count) change set(s), durations from $bestN tests of the latest Error Lab scorecard (unknown test = 30 s)")
$lines.Add(("{0,-62} {1,5} {2,11} {3,11} {4,11} {5,5}" -f "change set", "files", "old", "reach", "near", "wide"))
$tot = @{ old = 0; new = 0; near = 0; olds = 0.0; news = 0.0; nears = 0.0 }
foreach ($r in $rows) {
	$os = Get-Secs $r.old; $ns = Get-Secs $r.new; $nns = Get-Secs $r.near
	$tot.old += $r.old.Count; $tot.new += $r.new.Count; $tot.near += $r.near.Count; $tot.olds += $os; $tot.news += $ns; $tot.nears += $nns
	$nm = $r.name; if ($nm.Length -gt 62) { $nm = $nm.Substring(0, 62) }
	$lines.Add(("{0,-62} {1,5} {2,4}{3} {4,4}m {5,4} {6,4}m {7,4} {8,4}m {9,5}" -f $nm, $r.files, $r.old.Count, $(if ($r.old_full) { "F" } else { " " }), [math]::Round($os / 60), $r.new.Count, [math]::Round($ns / 60), $r.near.Count, [math]::Round($nns / 60), $r.wide))
}
$lines.Add(("{0,-62} {1,5} {2,4}  {3,4}m {4,4} {5,4}m {6,4} {7,4}m" -f "TOTAL (tests, test-minutes; F = old fell back to the full list)", "", $tot.old, [math]::Round($tot.olds / 60), $tot.new, [math]::Round($tot.news / 60), $tot.near, [math]::Round($tot.nears / 60)))
$lines.Add("failures in docs/ci since the first change set: $nFail failed test(s) in $($runs.Count) run(s); not picked: old $($miss.old), reach $($miss.new), near $($miss.near)")
foreach ($f in $failRows) { $lines.Add($f) }
$lines | ForEach-Object { Write-Host $_ }
if ($Out) { [IO.File]::WriteAllLines($Out, $lines) }
