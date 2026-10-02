# Quick CI for everyday runs: import + 1 smoke + perf + every test EXCEPT the long bot/AI simulations listed in
# tools/ci/slow_tests.txt (the milestone CI runs them: tools\ci\ci.ps1 -Dir .).
#   tools\ci\ci_quick.ps1                        # every test but the slow ones
#   tools\ci\ci_quick.ps1 -Parallel 3            # PC shared with agents / renders
#   tools\ci\ci_quick.ps1 -Changed               # changed-only: tests that name the uncommitted changes + the core set
#   tools\ci\ci_quick.ps1 -Changed -Base HEAD~3  # ... the changes since HEAD~3 (or a branch, a hash, last-green)
#   tools\ci\ci_quick.ps1 -Changed -ListOnly     # print the pick and why, run nothing
# Changed-only (docs/plan/error-lab.md "Fast CI"): tools/ci/select_tests.ps1 maps each changed file to the tests that
# name it (res:// path, class_name, file or folder name), always adds the core set (test_tiers, test_ui_card_hotkeys,
# test_casters, test_stables; the smoke test is the CI's smoke step) and falls back to the full list when a core file
# changes (project.godot, scripts/core/, command_card.gd, main / skirmish scenes, unit.gd...).
param(
	[int]$Parallel = 4,
	[switch]$SkipPerf,
	[switch]$Changed,
	[string]$Base = "",          # -Changed: git ref to diff against (default HEAD = uncommitted changes; last-green)
	[string[]]$Files = @(),      # -Changed without git: an explicit changed-file list
	[switch]$IncludeSlow,        # -Changed: also run picked tests from slow_tests.txt
	[switch]$ListOnly
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$slowFile = Join-Path $PSScriptRoot "slow_tests.txt"
$slow = @(Get-Content $slowFile | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ })
if ($Changed -or $Files.Count -gt 0) {
	$sel = & (Join-Path $PSScriptRoot "select_tests.ps1") -Base $Base -Files $Files -IncludeSlow:$IncludeSlow -Root $root
	$tests = @($sel.tests)
	Write-Host ("ci_quick -Changed: {0} tests{1}" -f $tests.Count, $(if ($sel.full) { " (full list: a core file changed)" } else { "" }))
} else {
	$tests = Get-ChildItem (Join-Path $root "tests") -Filter "test_*.gd" | ForEach-Object { $_.BaseName } | Where-Object { $slow -notcontains $_ } | Sort-Object
	Write-Host ("ci_quick: {0} tests (skipping {1} slow ones)" -f @($tests).Count, $slow.Count)
}
if ($ListOnly) { exit 0 }
if (@($tests).Count -eq 0) { Write-Host "ci_quick: no test picked"; exit 0 }
$a = @{ Dir = $root; SmokeRuns = 1; Parallel = $Parallel; NoHistory = $true; Tests = @($tests) }
if ($SkipPerf) { $a["SkipPerf"] = $true }
& (Join-Path $PSScriptRoot "ci.ps1") @a
exit $LASTEXITCODE
