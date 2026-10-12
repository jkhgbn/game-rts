# Self-check of tools/ci/select_tests.ps1 (no Godot, no git: -Files mode). Windows PowerShell 5.1.
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ci\test_select_tests.ps1
# Root-cause pass 2026-10-12: the 10-11 balance commits (data/units/*.tres) left 6 unit-pin tests red for a day.
# Each case: changed files -> tests that MUST be picked (and, for some, tests that must NOT be).
$ErrorActionPreference = "Stop"
$sel = Join-Path $PSScriptRoot "select_tests.ps1"
$cases = @(
	@{ files = @("data/units/flame_guard.tres"); must = @("test_1_g1", "test_1_g3", "test_3_g2a", "test_10_c6", "test_unit_guide", "test_12_c9") },
	@{ files = @("data/units/rimeshield.tres"); must = @("test_7_g2", "test_unit_guide") },
	@{ files = @("data/units/bramblehorn.tres"); must = @("test_8_g1") },
	@{ files = @("data/units/shade.tres"); must = @("test_1_g1", "test_3_g2a", "test_10_c6") },
	@{ files = @("data/units/shadow_knight.tres", "data/units/blaze_rider.tres"); must = @("test_1_g1", "test_1_g3") },
	@{ files = @("docs/balance/notes.md"); must = @("test_tiers", "test_casters"); never = @("test_1_g1", "test_7_g2") },
	@{ files = @("scripts/units/unit.gd"); must = @("test_1_g1", "test_7_g2", "test_8_g1"); full = $true }
)
$fail = 0
foreach ($c in $cases) {
	$r = & $sel -Files $c.files 6>$null
	$picked = @($r.tests)
	$miss = @($c.must | Where-Object { $picked -notcontains $_ })
	$extra = @()
	if ($c.never) { $extra = @($c.never | Where-Object { $picked -contains $_ }) }
	$fullBad = ($c.full -and -not $r.full)
	$ok = ($miss.Count -eq 0 -and $extra.Count -eq 0 -and -not $fullBad)
	if (-not $ok) { $fail++ }
	$line = "{0} {1} -> {2} tests" -f $(if ($ok) { "PASS" } else { "FAIL" }), ($c.files -join ","), $picked.Count
	if ($miss.Count -gt 0) { $line += "; missing: " + ($miss -join ", ") }
	if ($extra.Count -gt 0) { $line += "; should not pick: " + ($extra -join ", ") }
	if ($fullBad) { $line += "; expected the full list" }
	Write-Host $line
}
if ($fail -gt 0) { Write-Host "test_select_tests: FAIL ($fail of $($cases.Count) cases)"; exit 1 }
Write-Host "test_select_tests: PASS ($($cases.Count) cases)"
exit 0
