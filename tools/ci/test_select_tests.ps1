# Self-check of tools/ci/select_tests.ps1 + tools/ci/dep_index.ps1 (no Godot, no git: -Files mode). Windows PowerShell 5.1.
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ci\test_select_tests.ps1
# Part 1, the real project: each case = changed files -> tests that MUST be picked (and some that must NOT be).
#   Root-cause pass 2026-10-12: the 10-11 balance commits (data/units/*.tres) left 6 unit-pin tests red for a day.
#   2026-10-14 (dependency index): core files no longer mean the full list; recent CI failures stay picked.
# Part 2, a tiny fake project in %TEMP%: the edge kinds of dep_index.ps1 (creation / static / constant / type hint /
# compared path / data id / level table) and the cache.
$ErrorActionPreference = "Stop"
$sel = Join-Path $PSScriptRoot "select_tests.ps1"
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "project.godot"))) { $root = Split-Path $root -Parent }
$nonSlow = @(Get-ChildItem (Join-Path $root "tests") -Filter "test_*.gd").Count - @(Get-Content (Join-Path $root "tools\ci\slow_tests.txt") | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ }).Count
$cases = @(
	@{ files = @("data/units/flame_guard.tres"); must = @("test_1_g1", "test_1_g3", "test_3_g2a", "test_10_c6", "test_unit_guide", "test_12_c9") },
	@{ files = @("data/units/rimeshield.tres"); must = @("test_7_g2", "test_unit_guide") },
	@{ files = @("data/units/bramblehorn.tres"); must = @("test_8_g1") },
	@{ files = @("data/units/shade.tres"); must = @("test_1_g1", "test_3_g2a", "test_10_c6") },
	@{ files = @("data/units/shadow_knight.tres", "data/units/blaze_rider.tres"); must = @("test_1_g1", "test_1_g3") },
	@{ files = @("docs/balance/notes.md"); must = @("test_tiers", "test_casters", "test_save_metas", "test_i18n"); never = @("test_1_g1", "test_7_g2"); max = 6 },
	# A core script: its tests, flagged WIDE, never the whole list by name.
	@{ files = @("scripts/units/unit.gd"); must = @("test_1_g1", "test_7_g2", "test_8_g1"); wide = "scripts/units/unit.gd"; less_than = $nonSlow },
	@{ files = @("scripts/ui/command_card.gd"); must = @("test_ui_card_hotkeys", "test_research_card"); less_than = $nonSlow },
	@{ files = @("project.godot"); full = $true },
	# Recent CI failures (2026-10-14: research block) stay picked by the files that broke them.
	@{ files = @("scripts/ai/ai_research.gd"); must = @("test_research_bot") },
	@{ files = @("scripts/buildings/unit_research.gd"); must = @("test_unit_upgrades", "test_research_card", "test_research_bot") },
	# A deleted script: nothing reaches it, no crash, the core set only.
	@{ files = @("scripts/units/removed_for_the_test.gd"); must = @("test_tiers"); max = 6 },
	# An image nothing loads by path: the name fallback (folder 'kilnwarden').
	@{ files = @("art/units/fire/kilnwarden/kilnwarden.png"); must = @("test_tiers"); min = 7 },
	# A changed test runs itself; its subclasses (slow sims) are listed as slow.
	@{ files = @("tests/test_e8_sim.gd"); must = @("test_e8_sim"); slow = @("test_e8m1_fire_sim") },
	# -Mode reach picks a superset of -Mode near.
	@{ files = @("scripts/ui/minimap.gd"); superset = $true }
)
$fail = 0
foreach ($c in $cases) {
	$r = & $sel -Files $c.files -Quiet
	$picked = @($r.tests)
	$why = @()
	if ($c.must) { $miss = @($c.must | Where-Object { $picked -notcontains $_ }); if ($miss.Count) { $why += "missing: " + ($miss -join ", ") } }
	if ($c.never) { $extra = @($c.never | Where-Object { $picked -contains $_ }); if ($extra.Count) { $why += "should not pick: " + ($extra -join ", ") } }
	if ($c.full -and -not $r.full) { $why += "expected the full list" }
	if (-not $c.full -and $r.full) { $why += "fell back to the full list" }
	if ($c.max -and $picked.Count -gt $c.max) { $why += "picked $($picked.Count) > $($c.max)" }
	if ($c.min -and $picked.Count -lt $c.min) { $why += "picked $($picked.Count) < $($c.min)" }
	if ($c.less_than -and $picked.Count -ge $c.less_than) { $why += "picked $($picked.Count), not fewer than the $($c.less_than) of the full list" }
	if ($c.wide -and -not (@($r.wide) | Where-Object { $_.file -eq $c.wide })) { $why += "$($c.wide) not reported WIDE" }
	if ($c.slow) { $ms = @($c.slow | Where-Object { @($r.slow_skipped) -notcontains $_ }); if ($ms.Count) { $why += "not listed slow: " + ($ms -join ", ") } }
	if ($c.must -and $r.reasons) {
		foreach ($t in $c.must) {
			if (-not $r.reasons.Contains($t)) { continue }
			if (-not (@($r.reasons[$t]) | Where-Object { $_ -match 'core set|itself|hop|nothing loads' })) { $why += "$t has no reason" }
		}
	}
	if ($c.superset) {
		$all = @((& $sel -Files $c.files -Quiet -Mode reach).tests)
		$lost = @($picked | Where-Object { $all -notcontains $_ })
		if ($lost.Count) { $why += "near picked what reach did not: " + ($lost -join ", ") }
		if ($all.Count -lt $picked.Count) { $why += "reach smaller than near" }
	}
	if ($why.Count) { $fail++ }
	Write-Host ("{0} {1} -> {2} tests{3}" -f $(if ($why.Count) { "FAIL" } else { "PASS" }), ($c.files -join ","), $picked.Count, $(if ($why.Count) { "; " + ($why -join "; ") } else { "" }))
}

# ---------- part 2: the edge kinds on a fake project ----------
. (Join-Path $PSScriptRoot "dep_index.ps1")
$fake = Join-Path $env:TEMP ("fw_dep_index_test_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
function Put([string]$rel, [string]$text) {
	$p = Join-Path $fake $rel
	New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
	[IO.File]::WriteAllText($p, $text.Replace("`r`n", "`n"))
}
try {
	Put "project.godot" "[autoload]`nEvents=`"*res://scripts/core/events.gd`"`n"
	Put "scripts/core/events.gd" "extends Node`nsignal unit_died(u: Unit)`n"
	Put "scripts/unit.gd" "class_name Unit`nextends Node`nconst TEAM := 1`nfunc f() -> void:`n`tKit.helper()`n"
	Put "scripts/kit.gd" "class_name Kit`nstatic func helper() -> void:`n`tDeep.go()`n"
	Put "scripts/deep.gd" "class_name Deep`nstatic func go() -> void:`n`tDeeper.go()`n"
	Put "scripts/deeper.gd" "class_name Deeper`nstatic func go() -> void:`n`tDeepest.go()`n"
	Put "scripts/deepest.gd" "class_name Deepest`nstatic func go() -> void:`n`tpass`n"
	Put "scripts/consts.gd" "class_name Consts`nconst X := 3`nfunc g() -> void:`n`tvar s := load(`"res://scenes/heavy.tscn`")`n"
	Put "scenes/heavy.tscn" "[gd_scene format=3]`n[ext_resource type=`"Script`" path=`"res://scripts/heavy.gd`" id=`"1`"]`n"
	Put "scripts/heavy.gd" "extends Node`n"
	Put "scripts/typed_only.gd" "class_name TypedOnly`nextends Node`n"
	Put "scripts/level.gd" "extends Node`nconst SELF_PATH := `"res://scripts/level.gd`"`nfunc is_me(n: Node) -> bool:`n`treturn n.get_script().resource_path == SELF_PATH`n"
	Put "scripts/table.gd" "class_name Table`nconst SCENES := {`"one`": `"res://missions/m1.tscn`"}`nstatic func scene(id: String) -> String:`n`treturn SCENES[id]`n"
	Put "missions/m1.tscn" "[gd_scene format=3]`n[ext_resource type=`"Script`" path=`"res://scripts/m1.gd`" id=`"1`"]`n"
	Put "scripts/m1.gd" "extends Node`n"
	Put "data/units/grunt.tres" "[gd_resource format=3]`n[resource]`ndisplay_name = `"Grunt Man`"`n"
	Put "scripts/kit_table.gd" "class_name KitTable`nconst IDS := [`"grunt`"]`nstatic func ids() -> Array:`n`treturn IDS`n"
	Put "tests/test_a.gd" "extends SceneTree`nfunc _init() -> void:`n`tvar u := Unit.new()`n`tprint(Consts.X)`n`tvar t: TypedOnly = null`n`tprint(Table.scene(`"one`"))`n`tprint(KitTable.ids())`n"
	Put "tests/test_b.gd" "extends SceneTree`nfunc _init() -> void:`n`tprint(`"Grunt Man`")`n`tprint(get_script().resource_path == `"res://scripts/level.gd`")`n"
	Put "tests/test_c.gd" "extends `"res://tests/test_a.gd`"`n"
	$ix = Get-DepIndex -Root $fake -Quiet
	$ix.Graph.MaxStatic = 2
	$checks = @(
		@{ f = "scripts/unit.gd"; must = @("test_a", "test_c"); why = "Unit.new() from the test; test_c extends test_a" },
		@{ f = "scripts/kit.gd"; must = @("test_a"); why = "a static call from a created class" },
		@{ f = "scripts/deep.gd"; must = @("test_a"); why = "two static hops (Unit -> Kit -> Deep)" },
		@{ f = "scripts/deeper.gd"; never = @("test_a"); why = "three static hops: past MaxStatic 2" },
		@{ f = "scripts/consts.gd"; must = @("test_a"); why = "Consts.X: a value read as the last hop" },
		@{ f = "scenes/heavy.tscn"; never = @("test_a"); why = "a constant read does not carry what Consts loads" },
		@{ f = "scripts/typed_only.gd"; never = @("test_a"); why = "a type hint is no edge" },
		@{ f = "scripts/level.gd"; never = @("test_a", "test_b"); why = "a compared path is no edge" },
		@{ f = "scripts/m1.gd"; never = @("test_a"); why = "a level scene in a table is a value, not a load" },
		@{ f = "data/units/grunt.tres"; must = @("test_b"); never = @("test_a"); why = "a test quoting the display name; a kit table quoting the id is not a reader" },
		@{ f = "scripts/core/events.gd"; must = @("test_a", "test_b", "test_c"); why = "the autoload runs in every test" }
	)
	foreach ($k in $checks) {
		$h = Get-ReachingTests $ix $k.f
		$got = @($h.Keys)
		$bad = @()
		if ($k.must) { $bad += @($k.must | Where-Object { $got -notcontains $_ } | ForEach-Object { "missing $_" }) }
		if ($k.never) { $bad += @($k.never | Where-Object { $got -contains $_ } | ForEach-Object { "should not reach $_ ($($h[$_].chain))" }) }
		if ($bad.Count) { $fail++ }
		Write-Host ("{0} dep-index {1}: {2}{3}" -f $(if ($bad.Count) { "FAIL" } else { "PASS" }), $k.f, $k.why, $(if ($bad.Count) { " -> " + ($bad -join "; ") } else { "" }))
	}
	# Cache: a second build re-reads nothing; touching a file's mtime without changing it re-reads nothing either (MD5).
	$ix2 = Get-DepIndex -Root $fake -Quiet
	(Get-Item (Join-Path $fake "scripts/unit.gd")).LastWriteTime = (Get-Date).AddMinutes(5)
	$ix3 = Get-DepIndex -Root $fake -Quiet
	Put "scripts/unit.gd" "class_name Unit`nextends Node`nconst TEAM := 2`n"
	$ix4 = Get-DepIndex -Root $fake -Quiet
	$cacheOk = ($ix2.Parsed -eq 0 -and $ix3.Parsed -eq 0 -and $ix4.Parsed -eq 1)
	if (-not $cacheOk) { $fail++ }
	Write-Host ("{0} dep-index cache: re-read {1} / {2} / {3} file(s) (want 0 / 0 after an mtime-only touch / 1 after an edit)" -f $(if ($cacheOk) { "PASS" } else { "FAIL" }), $ix2.Parsed, $ix3.Parsed, $ix4.Parsed)
	Remove-Item -Force (Get-DepCachePath (Resolve-Path $fake).Path) -ErrorAction SilentlyContinue
} finally {
	Remove-Item -Recurse -Force $fake -ErrorAction SilentlyContinue
}

$total = $cases.Count + 12
if ($fail -gt 0) { Write-Host "test_select_tests: FAIL ($fail of $total checks)"; exit 1 }
Write-Host "test_select_tests: PASS ($total checks)"
exit 0
