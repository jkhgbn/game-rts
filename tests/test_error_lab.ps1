# Test for tools/error_lab/error_lab.ps1 (parse mode only, no Godot). Prints "PASS error_lab" or "FAIL ..." and exits 0 / 1.
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_error_lab.ps1
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Lab = Join-Path $Root "tools\error_lab\error_lab.ps1"
$tmp = Join-Path $env:TEMP ("error_lab_test_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$logs = Join-Path $tmp "logs"
New-Item -ItemType Directory -Force $logs | Out-Null
$hist = Join-Path $tmp "history.jsonl"
$fails = New-Object System.Collections.ArrayList
function Check([bool]$ok, [string]$what) { if (-not $ok) { [void]$fails.Add($what); Write-Host "  fail: $what" } }

$a = @'
starting
SCRIPT ERROR: Invalid call. Nonexistent function 'fly' in base 'Node3D (unit.gd)'.
          at: _physics_process (res://scripts/units/unit.gd:120)
          GDScript backtrace (most recent call first):
              [0] _physics_process (res://scripts/units/unit.gd:120)
SCRIPT ERROR: Invalid call. Nonexistent function 'fly' in base 'Node3D (unit.gd)'.
          at: _physics_process (res://scripts/units/unit.gd:120)
ERROR: Index p_index = 7 is out of bounds (size() = 3).
   at: get (core/templates/cowdata.h:205)
   GDScript backtrace (most recent call first):
       [0] _tick (res://scripts/ai/ai_player.gd:55)
ERROR: Node not found: "/root/Main/@Node3D@1234" (relative to "/root/Main").
   at: get_node (scene/main/node.cpp:1907)
PASS a
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
ERROR: 1 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
'@
$b = @'
SCRIPT ERROR: Invalid call. Nonexistent function 'fly' in base 'Node3D (unit.gd)'.
          at: _physics_process (res://scripts/units/unit.gd:120)
ERROR: Index p_index = 9 is out of bounds (size() = 2).
   at: get (core/templates/cowdata.h:205)
   GDScript backtrace (most recent call first):
       [0] _tick (res://scripts/ai/ai_player.gd:55)
SCRIPT ERROR: Attempt to call function 'get_hp' in base 'previously freed' on a null instance.
          at: _draw (res://scripts/ui/hud.gd:77)
FAIL b: something broke
ERROR: 1 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
'@
[System.IO.File]::WriteAllText((Join-Path $logs "test_a.log"), $a)
[System.IO.File]::WriteAllText((Join-Path $logs "test_b.log"), $b)

& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -Logs $logs -OutDir (Join-Path $tmp "r1") -Run r1 -HistoryFile $hist | Out-Null
Check ($LASTEXITCODE -eq 1) "run 1 exit code 1 (FAIL) got $LASTEXITCODE"
$j = Get-Content (Join-Path $tmp "r1\scorecard.json") -Raw | ConvertFrom-Json
Check ($j.result -eq "FAIL") "result FAIL"
$real = @($j.errors | Where-Object { $_.severity -ne "INFO" })
Check ($real.Count -eq 4) "4 unique real errors (got $($real.Count))"
$fly = @($real | Where-Object { $_.message -match "fly" })
Check ($fly.Count -eq 1 -and $fly[0].count -eq 3 -and @($fly[0].tests).Count -eq 2) "fly error deduped x3 in 2 tests"
Check ($fly[0].owner -eq "gameplay-coder" -and $fly[0].location -eq "res://scripts/units/unit.gd:120") "fly owner gameplay-coder at unit.gd:120 (got $($fly[0].owner) $($fly[0].location))"
$idx = @($real | Where-Object { $_.message -match "out of bounds" })
Check ($idx.Count -eq 1 -and $idx[0].count -eq 2 -and $idx[0].owner -eq "ai-coder" -and $idx[0].severity -eq "WARN") "index error normalised, backtrace frame, ai-coder, WARN"
$freed = @($real | Where-Object { $_.message -match "freed" })
Check ($freed.Count -eq 1 -and $freed[0].owner -eq "ui-coder" -and $freed[0].severity -eq "FAIL") "freed error ui-coder FAIL"
$nn = @($real | Where-Object { $_.message -match "Node not found" })
Check ($nn.Count -eq 1 -and $nn[0].owner -match "test_a" -and $nn[0].message -match "@Node3D@#") "engine error -> test owner, instance id stripped"
$info = @($j.errors | Where-Object { $_.severity -eq "INFO" })
Check ($info.Count -eq 2) "2 INFO exit-noise errors (got $($info.Count))"
Check (@($real | Where-Object { -not $_.new }).Count -eq 0) "first run: every error NEW"
Check (@($j.failed_tests) -contains "test_b" -and -not (@($j.failed_tests) -contains "test_a")) "test_b failed, test_a passed"
Check ($j.score -eq [math]::Max(0, 100 - 8 * 2 - 3 * 2 - 10)) "score formula (got $($j.score))"
$md = Get-Content (Join-Path $tmp "r1\scorecard.md") -Raw
Check ($md -match "## Improve next" -and $md -match "### gameplay-coder" -and $md -match "### ai-coder" -and $md -match "Done when") "scorecard sections + briefs"

# Run 2: one new error; the old ones are not NEW.
Add-Content (Join-Path $logs "test_b.log") "`nSCRIPT ERROR: Parse Error: Identifier `"foo`" not declared in the current scope.`n          at: GDScript::reload (res://scripts/economy/gold_bank.gd:12)"
& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -Logs $logs -OutDir (Join-Path $tmp "r2") -Run r2 -HistoryFile $hist | Out-Null
$j2 = Get-Content (Join-Path $tmp "r2\scorecard.json") -Raw | ConvertFrom-Json
$new = @($j2.errors | Where-Object { $_.new })
Check ($new.Count -eq 1 -and $new[0].owner -eq "systems-coder" -and $new[0].message -match "Parse Error") "run 2: only the parse error is NEW (systems-coder)"
Check ($j2.previous_run -eq "r1") "previous run r1"
Check (@(Get-Content $hist).Count -eq 2) "history has 2 rows"

# Clean log -> PASS 100.
$clean = Join-Path $tmp "clean"; New-Item -ItemType Directory -Force $clean | Out-Null
[System.IO.File]::WriteAllText((Join-Path $clean "test_c.log"), "PASS c`nERROR: 1 resources still in use at exit (run with --verbose for details).`n   at: clear (core/io/resource.cpp:822)`n")
& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -Logs $clean -OutDir (Join-Path $tmp "r3") -Run r3 -NoHistory -HistoryFile $hist | Out-Null
$j3 = Get-Content (Join-Path $tmp "r3\scorecard.json") -Raw | ConvertFrom-Json
Check ($LASTEXITCODE -eq 0 -and $j3.result -eq "PASS" -and $j3.score -eq 100) "clean log PASS 100"
Check (@(Get-Content $hist).Count -eq 2) "-NoHistory writes no row"

# Run 4 (lab v1.1): a log written through tools/godot_run.ps1 on PS 5.1 (first stderr line wrapped in an error
# record), the same bug 11 lines lower (function-based key: not NEW), a test that never printed PASS (diagnosis +
# tail) and its owner guessed from the task id (U = ui-coder).
$wrapped = @'
Godot Engine v4.7.2.stable.official
Godot_v4.7.2-stable_win64_console.exe : SCRIPT ERROR: Invalid call. Nonexistent function 'fly' in base 'Node3D (unit.gd)'.
At C:\Users\x\four-wizards-rts\tools\godot_run.ps1:20 char:2
+     & $g @args
+     ~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (SCRIPT ERROR: I...de3D (unit.gd)'.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError

          at: _physics_process (res://scripts/units/unit.gd:131)
waiting for the raid, frame 900
waiting for the raid, frame 1800
'@
$l4 = Join-Path $tmp "logs4"; New-Item -ItemType Directory -Force $l4 | Out-Null
[System.IO.File]::WriteAllText((Join-Path $l4 "test_7_u9.log"), $wrapped)
& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -Logs $l4 -OutDir (Join-Path $tmp "r4") -Run r4 -NoHistory -HistoryFile $hist | Out-Null
$j4 = Get-Content (Join-Path $tmp "r4\scorecard.json") -Raw | ConvertFrom-Json
$r4 = @($j4.errors | Where-Object { $_.severity -ne "INFO" })
Check ($r4.Count -eq 1 -and $r4[0].count -eq 1) "PS-wrapped stderr line counted once (got $($r4.Count) errors)"
Check ($r4.Count -ge 1 -and $r4[0].location -eq "res://scripts/units/unit.gd:131" -and $r4[0].owner -eq "gameplay-coder") "wrapped line keeps its at: frame (got $($r4[0].location))"
Check ($r4.Count -ge 1 -and -not $r4[0].new) "same function, new line number: not NEW"
$t4 = @($j4.tests | Where-Object { $_.test -eq "test_7_u9" })
Check ($t4.Count -eq 1 -and -not $t4[0].ok -and $t4[0].owner -eq "ui-coder") "test_7_u9 failed, owner ui-coder (got $($t4[0].owner))"
Check ($t4.Count -eq 1 -and $t4[0].kind -eq "script error" -and @($t4[0].tail)[-1] -match "frame 1800") "diagnosis 'script error' + log tail (got $($t4[0].kind))"
$md4 = Get-Content (Join-Path $tmp "r4\scorecard.md") -Raw
Check ($md4 -match "## By owner" -and $md4 -match "## Failed tests" -and $md4 -match "waiting for the raid, frame 1800" -and $md4 -notmatch "CategoryInfo") "by-owner table, failed-test tail, no PS noise"
# Cap reached: exit unknown in parse mode, so only a clean log with no PASS: "no PASS line".
[System.IO.File]::WriteAllText((Join-Path $l4 "test_7_u9.log"), "Godot Engine v4.7.2`nwaiting, frame 900`n")
& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -Logs $l4 -OutDir (Join-Path $tmp "r5") -Run r5 -NoHistory -HistoryFile $hist | Out-Null
$j5 = Get-Content (Join-Path $tmp "r5\scorecard.json") -Raw | ConvertFrom-Json
Check (@($j5.tests)[0].kind -eq "no PASS line") "clean log without PASS: 'no PASS line' (got $(@($j5.tests)[0].kind))"

# Run 6 (lab v1.2): verdict=last. Lab-on-lab tests print planted "  FAIL ..." lines, then their own final line.
# Listed test (test_art_lab), final PASS: passes, inner FAIL lines counted. Same log in a normal test: still FAILS.
# A verdict=last test whose final line is FAIL, or with a script error, still fails (no real failure hidden).
# A directive "# error_lab: verdict=last" in a test file (via -ProjectDir) works like the list.
$planted = "ART LAB: planted cases`n  FAIL B4t Triangles: 2534`n  FAIL B8 Unique materials: 6`nPASS art_lab`n"
$l6 = Join-Path $tmp "logs6"; New-Item -ItemType Directory -Force $l6 | Out-Null
[System.IO.File]::WriteAllText((Join-Path $l6 "test_art_lab.log"), $planted)
[System.IO.File]::WriteAllText((Join-Path $l6 "test_plain.log"), $planted)
[System.IO.File]::WriteAllText((Join-Path $l6 "test_art_lab_calibration.log"), "  FAIL R9 Feet on the ground: lowest point 0.4 m`nPASS art_lab_calibration (12 cases)`nFAIL art_lab_calibration: case_x out of band`n")
& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -Logs $l6 -OutDir (Join-Path $tmp "r6") -Run r6 -NoHistory -HistoryFile $hist | Out-Null
$j6 = Get-Content (Join-Path $tmp "r6\scorecard.json") -Raw | ConvertFrom-Json
$al = @($j6.tests | Where-Object { $_.test -eq "test_art_lab" })
Check ($al.Count -eq 1 -and $al[0].ok -and $al[0].verdict -eq "last" -and $al[0].inner_fail -eq 2) "verdict=last: planted FAIL lines + final PASS -> PASS, 2 inner FAIL counted (got ok=$($al[0].ok) inner=$($al[0].inner_fail))"
$pl = @($j6.tests | Where-Object { $_.test -eq "test_plain" })
Check ($pl.Count -eq 1 -and -not $pl[0].ok -and $pl[0].kind -eq "assert") "default verdict: the same log in a normal test still FAILS"
$cal = @($j6.tests | Where-Object { $_.test -eq "test_art_lab_calibration" })
Check ($cal.Count -eq 1 -and -not $cal[0].ok -and @($cal[0].fail_lines)[0] -match '^FAIL art_lab_calibration') "verdict=last: final FAIL line after a PASS -> FAIL, deciding line shown first"
[System.IO.File]::WriteAllText((Join-Path $l6 "test_art_lab.log"), $planted + "SCRIPT ERROR: Invalid call. Nonexistent function 'x' in base 'Node'.`n          at: _run (res://tests/test_art_lab.gd:40)`n")
Remove-Item (Join-Path $l6 "test_plain.log"), (Join-Path $l6 "test_art_lab_calibration.log")
# Directive in a test file of another checkout (-ProjectDir): a fake project with one test.
$proj = Join-Path $tmp "proj"; New-Item -ItemType Directory -Force (Join-Path $proj "tests") | Out-Null
[System.IO.File]::WriteAllText((Join-Path $proj "project.godot"), "")
[System.IO.File]::WriteAllText((Join-Path $proj "tests\test_zz_lab.gd"), "extends SceneTree`n# error_lab: verdict=last`n")
[System.IO.File]::WriteAllText((Join-Path $l6 "test_zz_lab.log"), "  FAIL planted`nPASS zz_lab`n")
& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -Logs $l6 -ProjectDir $proj -OutDir (Join-Path $tmp "r7") -Run r7 -NoHistory -HistoryFile $hist | Out-Null
$j7 = Get-Content (Join-Path $tmp "r7\scorecard.json") -Raw | ConvertFrom-Json
$zz = @($j7.tests | Where-Object { $_.test -eq "test_zz_lab" })
Check ($zz.Count -eq 1 -and $zz[0].ok -and $zz[0].verdict -eq "last") "directive '# error_lab: verdict=last' in the test file -> PASS"
$se7 = @($j7.errors | Where-Object { $_.severity -eq "FAIL" -and @($_.tests) -contains "test_art_lab" })
Check ($j7.result -eq "FAIL" -and $se7.Count -eq 1) "verdict=last does not hide a script error (result $($j7.result), $($se7.Count) FAIL error)"

# Harness kind (tools/error_lab/harness.ps1, error-lab.md 3g): only on runner evidence, never on "PASS + exit != 0".
. (Join-Path $Root "tools\error_lab\harness.ps1")
$hl = Join-Path $tmp "h.log"
[System.IO.File]::WriteAllText($hl, "PASS h`n"); (Get-Item $hl).LastWriteTime = (Get-Date).AddMinutes(-5)
$stale = Get-HarnessReason $hl (Get-Date) 1
$k1 = (Get-FailKind "test_h" @{ exit = 1; harness = $stale; pass_line = $true; script_errors = 0 })[0]
Check ($stale -ne "" -and $k1 -eq "harness") "a log older than the run + exit 1 -> harness (reason '$stale', got $k1)"
[System.IO.File]::WriteAllText($hl, "PASS h`n")
$fresh = Get-HarnessReason $hl (Get-Date).AddSeconds(-5) 1
$k2 = (Get-FailKind "test_h" @{ exit = 1; harness = $fresh; pass_line = $true; script_errors = 0 })[0]
Check ($fresh -eq "" -and $k2 -eq "exit code") "PASS + exit 1 with a fresh log stays 'exit code' (reason '$fresh', got $k2)"
$k3 = (Get-FailKind "test_h" @{ exit = -1; timed_out = $true; note = "killed after 60 s"; pass_line = $true; script_errors = 0 })[0]
Check ($k3 -eq "timeout") "a timed-out run with a PASS line stays 'timeout' (got $k3)"

Remove-Item -Recurse -Force $tmp -Confirm:$false
if ($fails.Count -eq 0) { Write-Host "PASS error_lab"; exit 0 }
Write-Host "FAIL error_lab: $($fails.Count) checks"; exit 1
