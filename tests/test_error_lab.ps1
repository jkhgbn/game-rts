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

Remove-Item -Recurse -Force $tmp -Confirm:$false
if ($fails.Count -eq 0) { Write-Host "PASS error_lab"; exit 0 }
Write-Host "FAIL error_lab: $($fails.Count) checks"; exit 1
