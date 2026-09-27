extends RefCounted
## Perf Lab (docs/plan/perf-lab.md): turns measurements into concrete "Improve next" suggestions.
## - lint_script(path): scans a hot script's per-frame functions (_process, _physics_process, and anything named
##   *think* / *tick* / *update* / *scan* / *sense*) for costly patterns and returns them with line numbers.
## - for_script(path, lint, avg_ms, nodes): one suggestion for a hot script (its lint findings first, then the
##   per-system playbook below).
## - for_hitch / for_check / standing: suggestions from a hitch, a failing check, or the standing list.
## The lab never edits game code: these go to the owner agent (CLAUDE.md "Who owns what") as a handoff.

## Costly patterns inside per-frame functions: [regex, short name, fix].
const PATTERNS: Array = [
	["get_nodes_in_group\\(", "get_nodes_in_group every call",
		"cache the list (refresh on node_added / a died signal or every 0.25-0.5 s), or read a shared per-frame cache"],
	["find_children\\(|find_child\\(", "tree walk (find_children / find_child)",
		"cache the node references once in _ready"],
	["get_node\\(|\\$[A-Za-z\"]", "get_node / $ lookup", "use @onready vars or cache the node once"],
	["\\.new\\(\\)", "allocation (.new())", "pool the object / node, or reuse a member instead of allocating per frame"],
	["\\.duplicate\\(", "duplicate() copy", "iterate the original or keep a reusable buffer"],
	["instantiate\\(", "scene instancing", "pre-build and pool (art-units.md 8: no runtime instancing)"],
	["distance_to\\(", "distance_to (sqrt)", "compare distance_squared_to against a squared radius"],
	["intersect_ray\\(|intersect_shape\\(|intersect_point\\(", "physics query", "stagger the queries (a few per frame) or cache results"],
	["map_get_path\\(|query_path\\(|get_next_path_position", "navigation query", "cache paths / stagger repaths"],
	["create_tween\\(", "tween per frame", "tween once, or animate in _process with a lerp"],
	["set_shader_parameter\\(|set_instance_shader_parameter\\(", "shader parameter write",
		"write only when the value changes (compare first) or move the animation into the shader (TIME)"],
	["Image\\.|set_pixel|ImageTexture|\\.update\\(", "image / texture update", "update a smaller region, less often, or on the GPU"],
	["for [a-z_]+ in [a-z_.]*units|for [a-z_]+ in get_tree\\(\\)", "loop over all units",
		"use a spatial grid / bucket by cell, or stagger the loop over several frames"],
	["\"\\s*%\\s*\\[", "string formatting", "build strings only when the text changes"],
]
## Per-frame function names (the lint only looks inside these).
const FRAME_FUNCS := ["_process", "_physics_process", "_think", "_tick", "think", "tick", "_update", "_scan", "_sense",
	"_refresh", "_step"]

## The per-system playbook (script path substring -> {title, text}). Checked in order; `%s` = the script path.
const PLAYBOOK: Array = [
	["scripts/ai/commander", "Stagger the Commander's think steps",
		"`%s` `_think()` runs all 22 rule steps in one tick: spread the heavy steps (scan, economy, build, attack, mapfill_sense) over 2-4 ticks and cache group lists in an AIWorldCache refreshed once per physics frame (ai-2v2.md:334-338). The first tick (`_setup`) should preload its resources before the match (the 2.3 s spikes)."],
	["scripts/ai/", "Cheaper AI brains", "`%s`: think on a timer offset per instance (stagger), reuse target lists from a shared cache, avoid per-think path queries."],
	["scripts/units/unit", "Cheaper unit ticks", "`%s` `_physics_process`: run target acquisition / aggro scans every 0.2-0.3 s with a per-unit offset instead of every frame, use a spatial hash for nearest-enemy, and skip idle units."],
	["scripts/units/projectile", "Pool projectiles", "`%s`: pool projectile nodes (no `.new()` / `queue_free` per shot) and move them with one manager _physics_process (or a MultiMesh)."],
	["scripts/world/fog", "Fog of war update", "`%s`: keep the 5 Hz cadence (fog-of-war.md:42), stamp only the cells that changed, reuse the Image / PackedByteArray and update the texture with `update()` of one ImageTexture."],
	["scripts/ui/minimap", "Minimap redraw", "`%s`: redraw unit dots at 5-10 Hz, not every frame; draw static layers once into a texture."],
	["scripts/ui/", "HUD refresh", "`%s`: refresh labels / bars on signals or at 4-10 Hz instead of every _process, and only set text when it changed."],
	["scripts/vfx/", "VFX manager", "`%s`: keep effects pooled (pre-built, restarted) and let idle pools stop processing (set_process(false) while nothing plays)."],
	["art/units/kit/character_model", "Character model animation", "`%s` `_process`: apply the distance LOD tiers (every 2nd frame beyond 30 m, frozen beyond 45 m, art-units.md 6.10) also in headless runs, and stop processing idle models off-screen (VisibleOnScreenNotifier3D)."],
	["art/units/", "Unit model animation", "`%s`: animate at a reduced rate beyond 30 m and freeze off-screen (art-units.md 6.10); keep pivot writes <= 7 per frame."],
	["art/buildings/", "Building model animation", "`%s`: stop _process when idle / off-screen; use shader TIME for loops instead of per-frame writes."],
	["art/environment/critters", "Cosmetic critters", "`%s`: stay within 10 Hz and 50 m of the camera (map-fill.md:398); MultiMesh per kind."],
	["art/environment/", "Map art", "`%s`: move per-frame animation into shaders (TIME) and use visibility ranges."],
	["scripts/world/", "World service", "`%s`: tick at the design rate (1-5 Hz) with an accumulator, and cache group lists."],
	["scripts/buildings/", "Building logic", "`%s`: idle buildings should not process (set_process(false) until queued / attacked)."],
	["[NavigationAgent3D]", "Navigation agents", "NavigationAgent3D internal update: fewer avoidance agents (disable avoidance on idle units), larger path_desired_distance, and fewer repath requests."],
	["[AnimationPlayer]", "AnimationPlayers", "Pause AnimationPlayers of off-screen / far models (callback mode manual, advance at a lower rate)."],
]


## Per-frame functions = the FRAME_FUNCS names plus the same-file functions they call (one level deep).
static func lint_script(path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if path.begins_with("["):
		return out
	var p := path
	if not (p.begins_with("res://") or p.begins_with("user://") or p.contains(":/") or p.contains(":\\")):
		p = "res://" + p
	if not FileAccess.file_exists(p):
		return out
	var text := FileAccess.get_file_as_string(p)
	var lines := text.split("\n")
	var regs: Array[RegEx] = []
	for pat: Array in PATTERNS:
		var r := RegEx.new()
		r.compile(pat[0])
		regs.append(r)
	var func_re := RegEx.new()
	func_re.compile("^(static\\s+)?func\\s+([A-Za-z0-9_]+)")
	# Pass 1: function spans, then the frame set (+ callees one level deep).
	var starts := {}
	var order: Array[String] = []
	for i in lines.size():
		var m0 := func_re.search(lines[i])
		if m0:
			starts[m0.get_string(2)] = i
			order.append(m0.get_string(2))
	var frame := {}
	for fn: String in order:
		if _is_frame_func(fn):
			frame[fn] = true
	var call_re := RegEx.new()
	call_re.compile("\\b([A-Za-z_][A-Za-z0-9_]*)\\(")
	var first := frame.keys()
	for fn2: Variant in first:
		var s0: int = starts[fn2]
		var e0 := lines.size()
		var at := order.find(String(fn2))
		if at + 1 < order.size():
			e0 = starts[order[at + 1]]
		for j in range(s0 + 1, e0):
			for mm in call_re.search_all(lines[j]):
				var callee := mm.get_string(1)
				if starts.has(callee):
					frame[callee] = true
	var cur := ""
	var in_frame := false
	for i in lines.size():
		var line: String = lines[i]
		var m := func_re.search(line)
		if m:
			cur = m.get_string(2)
			in_frame = frame.has(cur)
			continue
		if not in_frame:
			continue
		var code := line.strip_edges()
		if code.begins_with("#") or code == "":
			continue
		var hash_at := code.find("#")
		if hash_at > 0:
			code = code.substr(0, hash_at)
		for k in regs.size():
			if regs[k].search(code):
				out.append({"line": i + 1, "func": cur, "pattern": PATTERNS[k][1], "fix": PATTERNS[k][2],
					"code": code.strip_edges().left(90)})
	return out


static func _is_frame_func(fname: String) -> bool:
	var f := fname.to_lower()
	for n: String in FRAME_FUNCS:
		if f == n or f.begins_with(n + "_") or f.ends_with(n):
			return true
	return f.contains("think") or f.contains("tick")


## One suggestion for a hot script. `lint` = lint_script() rows for it.
static func for_script(path: String, lint: Array, avg_ms: float, nodes: int) -> Dictionary:
	var play := {}
	for row: Array in PLAYBOOK:
		if path.contains(row[0]):
			play = {"title": row[1], "text": String(row[2]).replace("%s", path)}
			break
	var text := ""
	if not lint.is_empty():
		# The most frequent pattern, with up to 3 line references.
		var by := {}
		for l: Variant in lint:
			var d: Dictionary = l
			var k: String = d["pattern"]
			if not by.has(k):
				by[k] = []
			(by[k] as Array).append(d)
		var best := ""
		for k2: String in by:
			if best == "" or (by[k2] as Array).size() > (by[best] as Array).size():
				best = k2
		var refs: Array[String] = []
		for d2: Variant in (by[best] as Array).slice(0, 3):
			refs.append("%s:%d in `%s()`" % [path.get_file(), int((d2 as Dictionary)["line"]), (d2 as Dictionary)["func"]])
		text = "%s (%s). Fix: %s." % [best, ", ".join(refs), (by[best] as Array)[0]["fix"]]
	if play.is_empty() and text == "":
		return {}
	var title: String = play.get("title", "Hot script " + path.get_file())
	var body := ""
	if text != "":
		body = text + (" " + String(play.get("text", "")) if not play.is_empty() else "")
	else:
		body = String(play["text"])
	return {"title": title, "text": "%.3f ms / frame over %d nodes. %s" % [avg_ms, nodes, body],
		"source": "hot list: `%s`" % path}


static func for_hitch(key: String, frame_ms: float, band_ms: float, events: String) -> Dictionary:
	var t := "The worst frame (%.0f ms) spent %.1f ms in `%s`%s. " % [frame_ms, band_ms, key,
		(" (events: " + events + ")") if events != "" else ""]
	if key.contains("commander"):
		t += "Commander `_think()` spikes: split the tick (one rule group per tick), move the first-tick `_setup()` and resource loads before the match, and cap per-tick work (rule_usec_max in commander.gd says which rule)."
	elif key.begins_with("(engine") or key == "":
		t += "Engine-side spike (navmesh rebake, shader compile, physics burst): prewarm materials / VFX once at load, and keep navmesh rebakes on the thread (bake_navigation_mesh(true))."
	else:
		t += "Spread this work over several frames (a queue processed N items per frame), or do it once at load."
	return {"title": "Kill the worst hitch", "text": t, "source": "hitch list"}


## Commander think step (commander.gd STEP_NAMES) -> where its code lives.
const AI_STEP_FILES := {"champions": "scripts/ai/ai_champions.gd `tick()` (called from commander.gd `_rule_champions`)",
	"mapfill": "scripts/ai/ai_mapfill.gd (commander.gd `_rule_mapfill`)", "mapfill_sense": "scripts/ai/ai_mapfill.gd (commander.gd `_mapfill_sense`)",
	"trade": "scripts/ai/ai_trade.gd `tick()` (commander.gd `_rule_trade`)", "trade_sense": "scripts/ai/ai_trade.gd (commander.gd `_trade_sense`)",
	"exchange": "scripts/ai/ai_trade.gd (commander.gd `_trade_exchange`)", "scan": "commander.gd `_scan()`",
	"build": "commander.gd `_rule_build()`", "items": "commander.gd `_rule_items()` (AIItems)", "economy": "commander.gd `_rule_economy()`",
	"attack": "commander.gd `_rule_attack()`", "train": "commander.gd `_rule_train()`"}


static func for_check(id: String, check_name: String, value: String, mode: String) -> Dictionary:
	if id == "A1" or id == "A2":
		var step := ""
		var at := value.find("(step ")
		if at >= 0:
			step = value.substr(at + 6).trim_suffix(")")
		var where: String = AI_STEP_FILES.get(step, "commander.gd `_think()`")
		return {"title": "Split the Commander's worst think step", "text": "%s = %s. The worst step is `%s` in %s: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked." % [check_name, value, step, where],
			"source": "check " + id}
	if id == "G-draw_calls" or id == "G-objects":
		return {"title": "Fewer draw calls", "text": "%s = %s: merge static decor into MultiMeshes per chunk (map-fill.md:400), set visibility_range_end on small props (65 / 90 m), and merge unit parts (art-units.md 8: <= 14 instances per unit)." % [check_name, value],
			"source": "check " + id}
	if id == "G-primitives":
		return {"title": "Fewer triangles", "text": "Primitives %s: add mesh LODs / visibility ranges to trees and rocks (EnvProps), and cap decor density (map_detail Low halves it)." % value,
			"source": "check " + id}
	if id == "G1":
		return {"title": "Cut GPU time", "text": "GPU %s: the ground river shader (+15 %%) and biome decor (+16-24 %%) are the known costs (lead-status.md:115): make the river detail uniform scale with map_detail, drop shadow casting on small decor, and shorten decor visibility ranges." % value,
			"source": "check G1"}
	if id.begins_with("C") and check_name.contains("lights"):
		return {"title": "Fewer real lights", "text": "%s = %s: replace OmniLights with emission + a fake glow sprite (0 new real lights rule, step12-agent-rules.md:27)." % [check_name, value],
			"source": "check " + id}
	if id == "H1":
		return {"title": "Pool the VFX", "text": "nodes were created under a VFX manager during the measure window (%s): pre-build them in the manager's _ready and restart them (art-units.md 8)." % value,
			"source": "check H1"}
	if id == "H3" or id == "H2":
		return {"title": "Find the node leak", "text": "%s = %s: something adds nodes and never frees them; compare the node class counts at warm-up and at the end (scorecard json `health.node_classes`)." % [check_name, value],
			"source": "check " + id}
	if id == "F1" and mode == "cpu":
		return {"title": "Logic frame over budget", "text": "Frame avg %s: start with the top rows of the hot list; the unit tick and NavigationAgent3D avoidance scale with the unit count." % value,
			"source": "check F1"}
	return {}


## Standing ideas (when the measured list is short). Always concrete.
static func standing(mode: String, scenario: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append({"title": "Cache group lists", "text": "Many per-frame functions call `get_tree().get_nodes_in_group(&\"units\")`: a shared per-frame cache (one array per group, rebuilt once per physics frame) removes the repeated allocations (ai-2v2.md:336 AIWorldCache pattern).",
		"source": "standing idea", "rank": 1.0})
	out.append({"title": "Stagger periodic work", "text": "Give every timer-driven tick (commander, brains, capture points, camps) a random phase offset so they never all fire on the same frame (ai-2v2.md:334).",
		"source": "standing idea", "rank": 0.9})
	if mode == "gpu" or scenario == "late200" or scenario == "menu":
		out.append({"title": "Visibility ranges and shadows", "text": "Set visibility_range_end (with fade) on decor, critters and small props, and cast_shadow OFF on everything but trees / big rocks / buildings (map-fill.md:400).",
			"source": "standing idea", "rank": 0.8})
	out.append({"title": "MultiMesh the crowds", "text": "Far units (beyond 45 m, frozen anyway) could draw as one MultiMesh per unit type (impostor tier) instead of 8-14 instances each.",
		"source": "standing idea", "rank": 0.7})
	return out
