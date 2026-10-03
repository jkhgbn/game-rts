# Test for tools/ci/select_tests.ps1 (file-list mode only: no git, no Godot). Prints "PASS select_tests" or
# "FAIL ..." and exits 0 / 1.
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_select_tests.ps1
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Sel = Join-Path $Root "tools\ci\select_tests.ps1"
$fails = New-Object System.Collections.ArrayList
function Check([bool]$ok, [string]$what) { if (-not $ok) { [void]$fails.Add($what); Write-Host "  fail: $what" } }
function Pick([string[]]$files) { return (& $Sel -Files ($files -join ',') -Root $Root 6>$null) }

# H4 (review-mission-ci.md): a base-class change runs its subclasses' tests even though a test names the base
# directly. MissionBase is named by test_mission_framework; Mission01 extends it and owns mission 1's regression net.
$r = Pick @("scripts/campaign/mission_base.gd")
$t = @($r.tests)
Check (-not $r.full) "mission_base.gd is not a full-list trigger"
Check ($t -contains "test_mission_framework") "mission_base.gd -> test_mission_framework (direct)"
# (test_m7_u1 drives MissionHud with a fake mission node: it never loads MissionBase, so it is not expected here.)
foreach ($m in @("test_m7_s1", "test_m7_s2", "test_m7_s3", "test_tier_path", "test_campaign_prologue")) {
	if (Test-Path (Join-Path $Root "tests\$m.gd")) { Check ($t -contains $m) "mission_base.gd -> $m (via the subclass Mission01)" }
}
Check (@($r.reasons["test_m7_s1"]) -join " " -match "subclass scripts/campaign/mission_01.gd") "the reason names the subclass"
foreach ($c in @("test_tiers", "test_ui_card_hotkeys", "test_casters", "test_stables")) { Check ($t -contains $c) "core set: $c" }

# A leaf script (nothing extends it) does not pull in mission 1's tests.
$r2 = Pick @("scripts/campaign/mission_skeleton.gd")
Check (@($r2.tests) -contains "test_mission_framework") "mission_skeleton.gd -> test_mission_framework"
Check (-not (@($r2.tests) -contains "test_m7_s1")) "mission_skeleton.gd (a leaf) does not select test_m7_s1"

# Full-list triggers and docs keep their old behaviour.
$r3 = Pick @("scripts/units/unit.gd")
Check ($r3.full) "unit.gd -> full list"
$r4 = Pick @("docs/reviews/review-mission-ci.md")
Check (-not $r4.full -and @($r4.tests).Count -eq 4) "a doc -> only the core set (got $(@($r4.tests).Count))"
# A test file selects itself.
$r5 = Pick @("tests/test_mission_framework.gd")
Check (@($r5.tests) -contains "test_mission_framework") "a changed test selects itself"

if ($fails.Count -eq 0) { Write-Host "PASS select_tests"; exit 0 }
Write-Host "FAIL select_tests: $($fails.Count) checks"; exit 1
