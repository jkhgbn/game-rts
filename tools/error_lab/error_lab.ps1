# Error Lab: run tests through the Godot gate (or read existing logs), collect every runtime / script error,
# dedupe them into unique errors, map each to its file and owner (CLAUDE.md "Who owns what"), flag NEW errors
# vs the previous run and write scorecard.md / scorecard.json + one fix-agent brief per owner.
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
	[int]$TimeoutSec = 2400,
	[switch]$NoHistory,
	[switch]$ListOnly,
	[string]$HistoryFile = ""
)
$ErrorActionPreference = "Stop"
$LabVersion = "1.0"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not $Run) { $Run = Get-Date -Format "yyyy-MM-dd_HHmm" }
if (-not $OutDir) { $OutDir = Join-Path $Root "docs\errors\lab\$Run" }
if (-not $HistoryFile) { $HistoryFile = Join-Path $Root "docs\errors\lab\history.jsonl" }
$Gate = Join-Path $Root "tools\godot_run.ps1"

# CI caps (--quit-after frames at --fixed-fps 60). Default for every other test: 40000.
$DefaultCap = 40000
$Caps = @{ "test_9_c9" = 150000; "test_10_a3" = 150000; "test_8_a1" = 200000; "test_12_a1" = 60000; "test_8_a2" = 100000; "test_20_a2" = 60000; "test_20_a3" = 80000; "test_9_c11" = 95000 }
function Get-Cap([string]$name) {
	if ($Caps.ContainsKey($name)) { return $Caps[$name] }
	if ($name -match "bot_vs_bot") { return 116000 }
	return $DefaultCap
}

# ---------- classification ----------
$CollectRx = 'SCRIPT ERROR|ERROR:|Parse Error|Invalid call|Nonexistent function|freed object|leaked'
$FailRx = 'SCRIPT ERROR|Parse Error|Invalid call|Nonexistent function|freed object|Failed to load script'
# Known exit-time noise: INFO, never FAIL.
$InfoRx = 'resources still in use at exit|ObjectDB instances (were )?leaked at exit|RID allocations of type .* were leaked at exit|RIDs? of type .* (was|were) leaked|Leaked instance:|Orphan StringName'

# Expected lines from intended negative checks, per test: never collected.
$ExpectedRx = @{ "test_art_lab" = '^ART LAB ERROR: scene not found: res://nope\.tscn' }

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
$claude = Join-Path $Root "CLAUDE.md"
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
function Get-Owner([string]$file) {
	if (-not $file -or $file -notmatch '^res://') { return "" }
	$rel = $file.Substring(6)
	$best = ""; $bestLen = -1
	foreach ($o in $OwnerMap) {
		if ($rel.StartsWith($o.prefix) -and $o.prefix.Length -gt $bestLen) { $best = $o.owner; $bestLen = $o.prefix.Length }
	}
	if ($best) { return $best }
	if ($rel -match '^tests/test_([^/]+)\.gd$') { return "task agent of test_$($Matches[1])" }
	if ($rel -match '^tools/([^/]+)/') { return "$($Matches[1]) owner (lab)" }
	return "lead (unmapped: $rel)"
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
	if ($ListOnly) { Write-Host "ERROR LAB: would run $($names.Count) tests"; $names | ForEach-Object { Write-Host ("  {0} (cap {1})" -f $_, (Get-Cap $_)) }; exit 0 }
	New-Item -ItemType Directory -Force $logDir | Out-Null
	if ($names.Count -eq 0) { Write-Host "ERROR LAB: no tests picked"; }
	Write-Host "ERROR LAB: running $($names.Count) tests, $Parallel at a time (gate: tools/godot_run.ps1)"
	$queue = New-Object System.Collections.Queue
	foreach ($n in $names) { $queue.Enqueue($n) }
	$running = @()
	while ($queue.Count -gt 0 -or $running.Count -gt 0) {
		while ($queue.Count -gt 0 -and $running.Count -lt $Parallel) {
			$n = $queue.Dequeue()
			if (-not (Test-Path (Join-Path $Root "tests\$n.gd"))) { $testStatus[$n] = @{ exit = -2; seconds = 0; cap = 0; note = "missing test file" }; continue }
			$cap = Get-Cap $n
			$log = Join-Path $logDir "$n.log"
			$cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$Gate`" --headless --path `"$Root`" -s tests/$n.gd --fixed-fps 60 --quit-after $cap > `"$log`" 2>&1"
			$p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$cmd`"" -WorkingDirectory $Root -WindowStyle Hidden -PassThru
			$null = $p.Handle  # PS 5.1: keep the handle so ExitCode is readable later
			$running += [pscustomobject]@{ name = $n; proc = $p; start = Get-Date; cap = $cap }
		}
		Start-Sleep -Milliseconds 500
		$still = @()
		foreach ($r in $running) {
			$secs = ((Get-Date) - $r.start).TotalSeconds
			if ($r.proc.HasExited) {
				$testStatus[$r.name] = @{ exit = $r.proc.ExitCode; seconds = [math]::Round($secs, 1); cap = $r.cap; note = "" }
				Write-Host ("  {0,-28} exit {1}  {2:N0} s" -f $r.name, $r.proc.ExitCode, $secs)
			} elseif ($secs -gt $TimeoutSec) {
				& taskkill.exe /T /F /PID $r.proc.Id | Out-Null   # our own cmd -> gate -> Godot tree only
				$testStatus[$r.name] = @{ exit = -1; seconds = [math]::Round($secs, 1); cap = $r.cap; note = "killed after $TimeoutSec s" }
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
	$lines = @(Get-Content $lf.FullName -Encoding UTF8)
	$passLine = @($lines | Where-Object { $_ -match '^\s*PASS\b' }).Count -gt 0
	$failLine = @($lines | Where-Object { $_ -match '^\s*FAIL\b' }).Count -gt 0
	if (-not $testStatus.ContainsKey($test)) { $testStatus[$test] = @{ exit = $null; seconds = $null; cap = $null; note = "" } }
	$testStatus[$test].pass_line = $passLine
	$testStatus[$test].fail_line = $failLine
	$testStatus[$test].log = $lf.FullName
	for ($i = 0; $i -lt $lines.Count; $i++) {
		$line = $lines[$i]
		if ($line -notmatch $CollectRx) { continue }
		if ($ExpectedRx.ContainsKey($test) -and $line -match $ExpectedRx[$test]) { continue }
		if ($line -match '^\s*(at:|\[\d+\]|GDScript backtrace)') { continue }
		# The frame: first res:// frame in the next lines (at: or backtrace), else the first at: frame.
		$file = ""; $ln = 0; $frame = ""; $engine = ""
		for ($j = $i + 1; $j -lt [math]::Min($lines.Count, $i + 10); $j++) {
			$l2 = $lines[$j]
			if ($l2 -notmatch '^\s*(at:|\[\d+\]|GDScript backtrace)') { break }
			if ($l2 -match '\((res://[^()]+?):(\d+)\)\s*$') { $file = $Matches[1]; $ln = [int]$Matches[2]; $frame = $l2.Trim(); break }
			if (-not $engine -and $l2 -match '\(([^()]+?):(\d+)\)\s*$') { $engine = "$($Matches[1]):$($Matches[2])" }
		}
		if (-not $file -and $line -match '(res://[^\s"'':]+\.(gd|tscn|tres|gdshader))(:(\d+))?') { $file = $Matches[1]; if ($Matches[4]) { $ln = [int]$Matches[4] } }
		$norm = Get-Norm $line
		$sev = "WARN"
		if ($line -match $InfoRx) { $sev = "INFO" } elseif ($line -match $FailRx) { $sev = "FAIL" }
		$loc = if ($file) { "${file}:$ln" } elseif ($engine) { "engine $engine" } else { "(no frame)" }
		$key = "$norm @ " + $(if ($file) { "${file}:$ln" } else { "(engine)" })
		if (-not $errors.ContainsKey($key)) {
			$errors[$key] = [pscustomobject]@{ key = $key; severity = $sev; message = $norm; example = $line.Trim(); file = $file; line = $ln
				location = $loc; owner = (Get-Owner $file); count = 0; tests = New-Object System.Collections.ArrayList; new = $false }
		}
		$e = $errors[$key]; $e.count++
		if (-not $e.tests.Contains($test)) { [void]$e.tests.Add($test) }
	}
}
foreach ($e in $errors.Values) {
	if (-not $e.owner) { $e.owner = "task agent of " + (($e.tests | ForEach-Object { $_ }) -join " / ") + " (engine error, no script frame)" }
}

# ---------- NEW vs previous run ----------
$prev = $null
if (Test-Path $HistoryFile) {
	$hl = @(Get-Content $HistoryFile -Encoding UTF8 | Where-Object { $_.Trim() })
	if ($hl.Count -gt 0) { $prev = $hl[$hl.Count - 1] | ConvertFrom-Json }
}
foreach ($e in $errors.Values) {
	if ($e.severity -ne "INFO" -and ($null -eq $prev -or -not (@($prev.keys) -contains $e.key))) { $e.new = $true }
}

# ---------- tests pass / fail ----------
$testRows = @()
foreach ($t in ($testStatus.Keys | Sort-Object)) {
	$s = $testStatus[$t]
	$ok = $true; $why = ""
	if ($null -ne $s.exit -and $s.exit -ne 0) { $ok = $false; $why = "exit $($s.exit)" }
	if ($s.fail_line) { $ok = $false; $why = (($why, "FAIL line") -ne "") -join "; " }
	if (-not $s.pass_line) { $ok = $false; $why = (($why, "no PASS line") -ne "") -join "; " }
	if ($s.note) { $why = (($why, $s.note) -ne "") -join "; " }
	$testRows += [pscustomobject]@{ test = $t; ok = $ok; why = $why; exit = $s.exit; seconds = $s.seconds; cap = $s.cap }
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

# ---------- write scorecard ----------
function Esc([string]$s) { return ($s -replace '\|', '\|' -replace '[^\x20-\x7E]', '?') }
function Repro([string[]]$ts) {
	$ts = @($ts | Select-Object -First 3)
	return @($ts | ForEach-Object { "& tools\godot_run.ps1 --headless --path . -s tests/$_.gd --fixed-fps 60 --quit-after $(Get-Cap $_)" })
}
$now = Get-Date -Format "yyyy-MM-dd HH:mm"
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Error Lab scorecard: $Run"); $md.Add("")
$md.Add("$now - lab v$LabVersion - $($testRows.Count) tests ($($failedTests.Count) failed) - logs: ``$logDir``"); $md.Add("")
$md.Add("## Result: **$result** - score **$score / 100**"); $md.Add("")
$md.Add("$uF unique FAIL errors - $uW unique WARN errors - $uI INFO (exit noise) - $uNew NEW vs previous run" + $(if ($prev) { " ($($prev.run))" } else { " (no previous run)" })); $md.Add("")
$md.Add("Score = 100 - 8 per unique FAIL error - 3 per unique WARN error - 10 per failed test (min 0)."); $md.Add("")
$md.Add("## Improve next")
$k = 1
foreach ($e in ($ranked | Select-Object -First 3)) {
	$md.Add("$k. **$(Esc $e.location)** ($($e.severity)$(if ($e.new) { ', NEW' })) - owner **$(Esc $e.owner)**: $(Esc $e.message) _(x$($e.count) in $($e.tests.Count) tests: $(($e.tests | Select-Object -First 4) -join ', '))_"); $k++
}
foreach ($t in ($failedTests | Select-Object -First ([math]::Max(0, 4 - $k)))) { $md.Add("$k. **tests/$($t.test).gd** failed ($($t.why)) - owner **task agent of $($t.test)**: read its log"); $k++ }
if ($k -eq 1) { $md.Add("1. Nothing: no errors, every test passed.") }
$md.Add("")
$md.Add("## Tests")
$md.Add("| Test | Result | Why | Exit | Seconds | Cap |"); $md.Add("|---|---|---|---|---|---|")
foreach ($t in $testRows) { $md.Add("| $($t.test) | $(if ($t.ok) { 'PASS' } else { '**FAIL**' }) | $($t.why) | $($t.exit) | $($t.seconds) | $($t.cap) |") }
$md.Add("")
$md.Add("## Unique errors")
$md.Add("| # | Sev | New | Location | Owner | Count | Tests | Message |"); $md.Add("|---|---|---|---|---|---|---|---|")
$k = 1
foreach ($e in $ranked) { $md.Add("| $k | $($e.severity) | $(if ($e.new) { 'NEW' }) | $(Esc $e.location) | $(Esc $e.owner) | $($e.count) | $(($e.tests | Select-Object -First 5) -join ', ')$(if ($e.tests.Count -gt 5) { ' +' + ($e.tests.Count - 5) }) | $(Esc $e.message) |"); $k++ }
if ($ranked.Count -eq 0) { $md.Add("| - | - | - | - | - | - | - | none |") }
$md.Add("")
$md.Add("## INFO (known exit noise, never FAIL)")
foreach ($e in @($errors.Values | Where-Object { $_.severity -eq "INFO" } | Sort-Object key)) { $md.Add("- $(Esc $e.message) - x$($e.count) in $($e.tests.Count) tests") }
$md.Add("")
$md.Add("## Fix-agent briefs (one per owner; the lead's rule: any failure -> launch a fix agent)")
$groups = @{}
foreach ($e in $ranked) { if (-not $groups.ContainsKey($e.owner)) { $groups[$e.owner] = @() }; $groups[$e.owner] += $e }
foreach ($t in $failedTests) {
	$o = "task agent of $($t.test)"
	if (-not $groups.ContainsKey($o)) { $groups[$o] = @() }
	$groups[$o] += [pscustomobject]@{ severity = "FAIL"; location = "tests/$($t.test).gd"; message = "test failed ($($t.why)); read $($logDir)\$($t.test).log"; count = 1; tests = @($t.test); new = $false }
}
foreach ($o in ($groups.Keys | Sort-Object)) {
	$list = @($groups[$o])
	$md.Add(""); $md.Add("### $(Esc $o) ($($list.Count) errors)")
	$md.Add('```text')
	$md.Add("Task: fix the runtime errors the Error Lab found (run $Run) in the Four Wizards RTS at $Root.")
	$md.Add("Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.")
	$md.Add("Errors (location - message - hits):")
	$n = 1; $allT = @()
	foreach ($e in $list) {
		$md.Add("$n. [$($e.severity)$(if ($e.new) { ', NEW' })] $($e.location) - $($e.message) - x$($e.count) in: $(($e.tests | Select-Object -First 5) -join ', ')"); $n++
		$allT += @($e.tests)
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
	lab = "error_lab"; version = $LabVersion; run = $Run; time = $now; result = $result; score = $score
	unique_fail = $uF; unique_warn = $uW; info = $uI; new = $uNew; previous_run = $(if ($prev) { $prev.run } else { "" })
	tests = $testRows; failed_tests = @($failedTests | ForEach-Object { $_.test })
	errors = @($ranked + @($errors.Values | Where-Object { $_.severity -eq "INFO" }) | ForEach-Object {
		[pscustomobject]@{ severity = $_.severity; new = $_.new; location = $_.location; file = $_.file; line = $_.line; owner = $_.owner
			message = $_.message; example = $_.example; count = $_.count; tests = @($_.tests); key = $_.key } })
	improve_next = @($ranked | Select-Object -First 3 | ForEach-Object { "$($_.location) ($($_.owner)): $($_.message)" })
}
[System.IO.File]::WriteAllText((Join-Path $OutDir "scorecard.json"), ($json | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))

if (-not $NoHistory) {
	$h = [pscustomobject]@{ run = $Run; time = $now; result = $result; score = $score; tests = $testRows.Count; failed_tests = $failedTests.Count
		unique_fail = $uF; unique_warn = $uW; new = $uNew; keys = @($real | ForEach-Object { $_.key }) }
	New-Item -ItemType Directory -Force (Split-Path $HistoryFile) | Out-Null
	[System.IO.File]::AppendAllText($HistoryFile, ($h | ConvertTo-Json -Depth 4 -Compress) + "`n", (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "ERROR LAB: $result score $score / 100 ($uF FAIL, $uW WARN, $uI info unique errors; $uNew NEW; $($failedTests.Count) / $($testRows.Count) tests failed)"
foreach ($e in ($ranked | Select-Object -First 3)) { Write-Host "  $($e.severity) $($e.location) [$($e.owner)] $($e.message)" }
Write-Host "  scorecard: $(Join-Path $OutDir 'scorecard.md')"
if ($result -eq "FAIL") { exit 1 }
exit 0
