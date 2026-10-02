# Quick CI for everyday runs: import + 1 smoke + perf + every test EXCEPT the long bot/AI simulations (each >5 min).
# The slow ones (about 2.9 of the 4.9 test-hours) are meant for milestones: tools\ci\ci.ps1 -Dir . -Parallel 4
#   tools\ci\ci_quick.ps1            # about 20-30 min on the dedicated laptop
#   tools\ci\ci_quick.ps1 -Parallel 6
param([int]$Parallel = 4, [switch]$SkipPerf)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$slow = @("test_20_a3", "test_8_a1", "test_4_i1", "test_9_c11", "test_4_u1b", "test_9_c9", "test_10_a3", "test_4_i2", "test_8_b3", "test_8_a2", "test_2_a1_bot_vs_bot", "test_casters_bots")
$tests = Get-ChildItem (Join-Path $root "tests") -Filter "test_*.gd" | ForEach-Object { $_.BaseName } | Where-Object { $slow -notcontains $_ } | Sort-Object
Write-Host ("ci_quick: {0} tests (skipping {1} slow ones)" -f $tests.Count, $slow.Count)
$a = @("-Dir", $root, "-SmokeRuns", "1", "-Parallel", "$Parallel", "-NoHistory", "-Tests", ($tests -join ","))
if ($SkipPerf) { $a += "-SkipPerf" }
& (Join-Path $PSScriptRoot "ci.ps1") @a
exit $LASTEXITCODE
