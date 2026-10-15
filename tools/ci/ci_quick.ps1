# Quick CI for everyday runs: import + 1 smoke + perf + every test EXCEPT the long bot/AI simulations listed in
# tools/ci/slow_tests.txt (the milestone CI runs them: tools\ci\ci.ps1 -Dir .).
#   tools\ci\ci_quick.ps1                        # every test but the slow ones
#   tools\ci\ci_quick.ps1 -Parallel 3            # PC shared with agents / renders
#   tools\ci\ci_quick.ps1 -Changed               # changed-only: tests that reach the uncommitted changes + the core set
#   tools\ci\ci_quick.ps1 -Changed -Base HEAD~3  # ... the changes since HEAD~3 (or a branch, a hash, last-green)
#   tools\ci\ci_quick.ps1 -Changed -ListOnly     # print the pick and, per test, the changed file + the chain to it
#   tools\ci\ci_quick.ps1 -Changed -Mode reach   # every test that reaches a changed file (safest, ~2x slower)
# Changed-only (docs/plan/error-lab.md "Fast CI"): tools/ci/select_tests.ps1 builds a static dependency index
# (tools/ci/dep_index.ps1: res:// loads, scenes, `Foo.new()`, static calls, constants, data ids; cached by file hash)
# and picks the tests within -NearHops (3) dependency hops of a changed file (-Mode near, default; -Mode reach = all
# reaching tests), plus the core set (test_save_metas, test_i18n, test_tiers, test_ui_card_hotkeys, test_casters,
# test_stables; smoke and perf are the CI's own steps). Only project.godot and the Godot gate still mean "the full
# list"; a core script (unit.gd, command_card.gd...) picks its own tests, and a file whose tests exceed -WideShare
# (50 %) of the suite is reported as WIDE with its count.
param(
	[int]$Parallel = 4,
	[switch]$SkipPerf,
	[switch]$Changed,
	[string]$Base = "",          # -Changed: git ref to diff against (default HEAD = uncommitted changes; last-green)
	[string[]]$Files = @(),      # -Changed without git: an explicit changed-file list
	[switch]$IncludeSlow,        # -Changed: also run picked tests from slow_tests.txt
	[double]$WideShare = 0.5,    # -Changed: share of the tests above which a changed file is "wide"
	[ValidateSet("near", "reach")][string]$Mode = "near",   # -Changed: tests within -NearHops hops of a change, or every reaching test
	[int]$NearHops = 3,
	[switch]$ListOnly
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not (Test-Path (Join-Path $root "project.godot"))) {
	# A staged copy (docs/handoff/...): the repo is the first folder up with a project.godot.
	$d = $PSScriptRoot
	while ($d -and -not (Test-Path (Join-Path $d "project.godot"))) { $d = Split-Path $d -Parent }
	$root = $d
}
$slowFile = Join-Path $root "tools\ci\slow_tests.txt"
$slow = @(Get-Content $slowFile | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ })
if ($Changed -or $Files.Count -gt 0) {
	$sel = & (Join-Path $PSScriptRoot "select_tests.ps1") -Base $Base -Files $Files -IncludeSlow:$IncludeSlow -Root $root `
		-Explain:$ListOnly -WideShare $WideShare -Mode $Mode -NearHops $NearHops
	$tests = @($sel.tests)
	Write-Host ("ci_quick -Changed: {0} tests{1}" -f $tests.Count, $(if ($sel.full) { " (full list: project.godot / the Godot gate changed)" } else { "" }))
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
