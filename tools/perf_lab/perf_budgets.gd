extends RefCounted
## Perf Lab (docs/plan/perf-lab.md): every number the lab judges against, in one place, with its source.
## A row's hard limit is a spec number (going over = FAIL); `warn` is the stricter spec / stretch number or a lab
## default (going over = WARN). Rows whose `src` starts with "lab default" have no spec number: they only WARN.
## Reached through preload:  const Budgets := preload("res://tools/perf_lab/perf_budgets.gd")
##
## Units: ms unless the key says otherwise. "logic" = headless frame (no rendering), "gpu" = windowed frame.

const HITCH_MS := 33.3            ## A frame over this is a hitch (2 frames at 60 fps).
const FRAME_60_MS := 16.667
const FRAME_120_MS := 8.333

## Logic frame (headless) per scenario: avg / p95 / p99 / max / hitches per minute.
## Base rule: 8 ms per 100 units (waves.md:82), stretch 5.5 ms per 100 (waves.md:226, 5.P1); 200 units <= 16 / 11 ms.
const LOGIC := {
	"early": {"src": "waves.md:82 (8 ms / 100 units, scaled to the early-game unit count, floor 3 ms); warn 5.5 / 100 (waves.md:226)",
		"per100": 8.0, "per100_warn": 5.5, "floor": 3.0},
	"mid100": {"src": "waves.md:82 (100 units <= 8 ms), warn waves.md:226 (5.P1: <= 5.5 ms)", "avg": 8.0, "avg_warn": 5.5},
	"late200": {"src": "waves.md:82-83 (200 units: 16 ms scaled), warn waves.md:226 (5.P1: <= 11 ms)", "avg": 16.0,
		"avg_warn": 11.0},
	"vfx_storm": {"src": "waves.md:82 (8 ms / 100 units, scaled) + lab default 1 ms VFX allowance; warn 5.5 / 100",
		"per100": 8.0, "per100_warn": 5.5, "floor": 3.0, "extra": 1.0},
	"menu": {"src": "lab default (the menu has no game logic: 2 ms, warn 1 ms)", "avg": 2.0, "avg_warn": 1.0},
}
## Frame shape rules (lab defaults, every scenario): p95 <= 1.5x the avg budget, p99 <= 2x (WARN only);
## hitches per minute of measured time (FAIL above `hitch_fail`).
const SHAPE := {"src": "lab default (docs/plan/perf-lab.md 'Budgets')", "p95_x": 1.5, "p99_x": 2.0, "hitch_warn": 0.5,
	"hitch_fail": 3.0}

## Windowed (GPU) frame: 60 fps at 1600x900 and at 3440x1440 on the GTX 1660 (cinematics.md:316, map-fill.md:406);
## warn at the user's 120 Hz (lab default).
const GPU := {"src": "cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)",
	"avg": FRAME_60_MS, "avg_warn": FRAME_120_MS, "p99": 33.3}
## Render counters (lab defaults: the specs budget per-model instances, not the whole frame). Draw calls from
## RENDER_TOTAL_DRAW_CALLS_IN_FRAME; objects = RENDER_TOTAL_OBJECTS_IN_FRAME.
const RENDER := {
	"early": {"draw_calls": 1500, "objects": 2500, "primitives": 2500000},
	"mid100": {"draw_calls": 2500, "objects": 4000, "primitives": 3500000},
	"late200": {"draw_calls": 4000, "objects": 6500, "primitives": 5000000},
	"vfx_storm": {"draw_calls": 3000, "objects": 5000, "primitives": 4000000},
	"menu": {"draw_calls": 800, "objects": 1500, "primitives": 1500000},
	"src": "lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)",
}

## Per-system logic (avg ms per measured frame, from the band profiler). `match` = substrings of the script path.
## Order matters: the first row whose match hits a script wins.
const SYSTEMS: Array[Dictionary] = [
	{"id": "ai_commander", "label": "AI commanders", "match": ["scripts/ai/commander", "scripts/ai/ai_"], "avg": 0.6,
		"max": 1.5, "median_warn": 0.1,
		"src": "ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target"},
	{"id": "champion_brains", "label": "Champion brains", "match": ["scripts/ai/champion", "scripts/ai/brain",
		"scripts/units/champion"], "avg": 0.1, "src": "champions.md:228 (all champion brains + senses < 0.1 ms)"},
	{"id": "beast_brains", "label": "Epic beast brains", "match": ["scripts/ai/beast_brain", "scripts/world/epic_beasts"],
		"avg": 0.03, "src": "map-fill.md:403 (8 beasts < 0.03 ms)"},
	{"id": "map_fill", "label": "Map fill services", "match": ["scripts/world/river_system", "scripts/world/capture_point",
		"scripts/world/camp_manager", "scripts/world/neutral_camp", "scripts/ai/ai_mapfill"], "avg": 0.2,
		"src": "map-fill.md:398 (map fill < 0.2 ms: river 0.03, points 0.03, camps 0.02)"},
	{"id": "critters", "label": "Critters (game + cosmetic)", "match": ["scripts/world/game_critter", "scripts/world/critter_herds",
		"art/environment/critters"], "avg": 0.11, "src": "map-fill.md:398 + :404 (CritterSystem < 0.08, game critters < 0.03)"},
	{"id": "trade", "label": "Trade", "match": ["scripts/world/trade", "scripts/world/thie", "scripts/world/hunters",
		"scripts/economy/gold_bank", "scripts/units/caravan", "scripts/world/loot_sack", "scripts/ai/tracker"], "avg": 0.1,
		"src": "market-trade.md:128 (all trade logic < 0.1 ms)"},
	{"id": "fog", "label": "Fog of war", "match": ["scripts/world/fog", "scripts/world/sight_marker"], "avg": 0.3,
		"src": "lab default (fog-of-war.md:42-47: 5 Hz, < 10 000 byte writes per update)"},
	{"id": "vfx", "label": "VFX managers", "match": ["scripts/vfx/", "art/vfx/"], "avg": 0.5,
		"src": "lab default (for-lead.md:94: MapFillVfx 15-150 us; pools, no runtime instancing)"},
	{"id": "ui", "label": "HUD / minimap / UI", "match": ["scripts/ui/"], "avg": 0.5, "src": "lab default"},
	{"id": "unit_models", "label": "Unit / building models (art scripts)", "match": ["art/units/", "art/buildings/"],
		"per100": 0.5, "src": "art-units.md:633 (<= +0.5 ms per 100 units of animation CPU)"},
	{"id": "units", "label": "Units (gameplay)", "match": ["scripts/units/", "scripts/spells/", "scripts/economy/worker",
		"scripts/items/"], "src": "part of the 8 ms / 100 units logic budget (waves.md:82)"},
	{"id": "buildings", "label": "Buildings", "match": ["scripts/buildings/"], "src": "part of the logic budget"},
	{"id": "world", "label": "Level / world", "match": ["scripts/world/", "scripts/core/", "scripts/campaign/", "scripts/economy/"],
		"src": "part of the logic budget"},
	{"id": "art_other", "label": "Other art scripts", "match": ["art/"], "src": "part of the logic budget"},
]

## Census rules (scene counts, checked once the scenario is set up).
const CENSUS := {
	"lights": {"limit": 15, "src": "step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)"},
	"shadow_lights": {"limit": 1, "src": "art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)"},
	"decor_instances": {"limit": 12000, "src": "map-fill.md:400 (<= 12 000 decor instances)"},
	"draw_nodes_decor": {"limit": 140, "hard": false, "src": "map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)"},
	"vfx_nodes_created": {"limit": 0, "src": "art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)"},
	"orphan_nodes": {"limit": 0, "hard": false, "src": "lab default (orphans = leaked nodes)"},
	"node_growth_pct": {"limit": 10.0, "hard": false, "src": "lab default (nodes after warm-up vs the end, units excluded)"},
}

const SCENARIO_UNITS := {"early": 0, "mid100": 100, "late200": 200, "vfx_storm": 80, "menu": 0}


## Logic avg budget {limit, warn, src} for a scenario with `units` living units.
static func logic_budget(scenario: String, units: int) -> Dictionary:
	var r: Dictionary = LOGIC.get(scenario, {})
	if r.is_empty():
		return {"limit": 8.0, "warn": 5.5, "src": "lab default"}
	if r.has("per100"):
		var n := float(maxi(units, 0))
		var lim := maxf(float(r["floor"]), float(r["per100"]) * n / 100.0) + float(r.get("extra", 0.0))
		var w := maxf(float(r["floor"]) * 0.7, float(r["per100_warn"]) * n / 100.0) + float(r.get("extra", 0.0)) * 0.7
		return {"limit": lim, "warn": w, "src": r["src"]}
	return {"limit": float(r["avg"]), "warn": float(r["avg_warn"]), "src": r["src"]}


## The SYSTEMS row a script path belongs to (the last catch-all "other" when none matches).
static func system_of(script_path: String) -> Dictionary:
	var p := script_path.trim_prefix("res://")
	for row: Dictionary in SYSTEMS:
		for m: String in row["match"]:
			if p.begins_with(m) or p.contains(m):
				return row
	if script_path.begins_with("["):
		return {"id": "engine_nodes", "label": "Built-in nodes (" + script_path + ")", "src": "engine"}
	return {"id": "other", "label": "Other scripts", "src": ""}


## The budget table as Markdown (perf-lab.md keeps a copy; `perf_report.gd -- --table` prints it).
static func markdown_table() -> String:
	var s := "| Scenario / system | Rule | FAIL above | WARN above | Source |\n|---|---|---|---|---|\n"
	for k: String in LOGIC:
		var r: Dictionary = LOGIC[k]
		if r.has("per100"):
			s += "| %s | logic frame avg | %.1f ms / 100 units (floor %.0f)%s | %.1f / 100 | %s |\n" % [k, r["per100"],
				r["floor"], (" + %.1f" % r["extra"]) if r.has("extra") else "", r["per100_warn"], r["src"]]
		else:
			s += "| %s | logic frame avg | %.1f ms | %.1f ms | %s |\n" % [k, r["avg"], r["avg_warn"], r["src"]]
	s += "| all | p95 / p99 | - | %.1fx / %.1fx the avg budget | %s |\n" % [SHAPE["p95_x"], SHAPE["p99_x"], SHAPE["src"]]
	s += "| all | hitches (> %.0f ms) per minute | %.1f | %.1f | %s |\n" % [HITCH_MS, SHAPE["hitch_fail"],
		SHAPE["hitch_warn"], SHAPE["src"]]
	s += "| all (windowed) | frame avg | %.1f ms (60 fps) | %.1f ms (120 fps) | %s |\n" % [GPU["avg"], GPU["avg_warn"],
		GPU["src"]]
	s += "| all (windowed) | frame p99 | %.1f ms | - | %s |\n" % [GPU["p99"], GPU["src"]]
	for k2: String in ["early", "mid100", "late200", "vfx_storm", "menu"]:
		var rr: Dictionary = RENDER[k2]
		s += "| %s (windowed) | draw calls / objects / primitives | - | %d / %d / %d | %s |\n" % [k2, rr["draw_calls"],
			rr["objects"], rr["primitives"], RENDER["src"]]
	for row: Dictionary in SYSTEMS:
		var parts: Array[String] = []
		if row.has("avg"):
			parts.append("avg %.2f ms" % row["avg"])
		if row.has("max"):
			parts.append("max frame %.1f ms" % row["max"])
		if row.has("per100"):
			parts.append("%.1f ms / 100 units" % row["per100"])
		var warn := ("median %.2f ms" % row["median_warn"]) if row.has("median_warn") else "-"
		if parts.is_empty():
			continue
		s += "| system: %s | per-frame logic | %s | %s | %s |\n" % [row["label"], ", ".join(parts), warn, row["src"]]
	for k3: String in CENSUS:
		var c: Dictionary = CENSUS[k3]
		var hard: bool = bool(c.get("hard", true))
		s += "| census: %s | count | %s | %s | %s |\n" % [k3, str(c["limit"]) if hard else "-",
			"-" if hard else str(c["limit"]), c["src"]]
	return s
