extends SceneTree
## Perf Lab (docs/plan/perf-lab.md): ONE deterministic scenario run, then one JSON line ("PERF_LAB_RESULT {...}",
## also written to --out). Headless = logic / CPU numbers; windowed (no --headless) = GPU + render counters too.
## Launched by tools/perf_lab/run_perf_lab.ps1 (sequentially, with the machine-noise guard); runnable alone:
##   godot --headless --path . -s tools/perf_lab/perf_lab.gd --fixed-fps 60 --quit-after 30000 -- \
##       --scenario=mid100 --seed=1 --profile=1 --out=C:/tmp/r.json
##   godot --path . -s tools/perf_lab/perf_lab.gd --fixed-fps 60 --resolution 1600x900 --quit-after 30000 -- --scenario=late200
## User args (after "--"):
##   --scenario=S   early | mid100 | late200 | vfx_storm | menu   (table SCENARIOS below)
##   --seed=N       seeds the global rng and every node rng (like the Bot Lab)
##   --pair=P:E     kingdoms (default fire:shadow)
##   --profile=1    band profiler on (hot list; ~1 us per marker per pass of overhead, listed in the result)
##   --warmup=S --measure=S   override the scenario's game seconds
##   --army=P:E     override the scenario's army sizes (player:enemy soldiers)
##   --upscaler=off|fsr1|fsr2 --render-scale=0.67   the game's 3D upscaler (default off = native, like before;
##                  the player's saved setting is never used here, so runs stay comparable)
##   --out=PATH     the JSON line is written there     --commit=ID  copied into the JSON     --run=N  repeat index
##   Physics-step split (perf-research-2026-10-12 P12; result key "phys_split", scorecard line):
##   --physsplit=1  times every unit's velocity_computed handler (Unit._on_velocity_computed = move_and_slide + _face +
##                  set_moving) through a lab wrapper; with --profile=1 the split also gives avoidance / nav server and
##                  model pose (the model-script bands)
##   --noavoid=1    variant: every unit's NavigationAgent3D avoidance off (units overlap). An agent without avoidance
##                  never emits velocity_computed, so the lab feeds each unit's handler its agent's velocity from the
##                  SceneTree's _physics_process (same handler, one frame later): delta vs a normal run = the RVO cost
##   --nopose=1     variant: every unit model script stops processing (no pose, no transform writes): delta = pose cost
## Test-script rules (CLAUDE.md): compiled before autoloads; game classes reached untyped / through groups.

const Stats := preload("res://tools/perf_lab/perf_stats.gd")
const Budgets := preload("res://tools/perf_lab/perf_budgets.gd")
const Probe := preload("res://tools/perf_lab/perf_probe.gd")
const Hints := preload("res://tools/perf_lab/perf_hints.gd")

const SKIRMISH := "res://scenes/skirmish.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
const COMMANDER_PATH := "res://scripts/ai/commander.gd"
const TICK := 60
## Scenario table. warmup / measure in game seconds from the scenario start (the match start for skirmish ones).
## army = [player, enemy] soldiers spawned at the fight spot; bots = 2 adds a player Commander (both sides AI).
const SCENARIOS := {
	"early": {"warmup": 20.0, "measure": 45.0, "bots": 2, "army": [0, 0],
		"what": "1v1 skirmish from 0:20 to 1:05, both sides normal Commanders, full art and map fill"},
	"mid100": {"warmup": 4.0, "measure": 30.0, "bots": 1, "army": [50, 50],
		"what": "50 v 50 mixed soldiers attack-move into each other on the west meadow, enemy Commander on"},
	"late200": {"warmup": 4.0, "measure": 30.0, "bots": 1, "army": [100, 100], "titans": 1, "beasts": true, "gpu_ablate": true,
		"what": "100 v 100 + 1 titan per side, every epic beast spawned, river / decor / critters on, camera sweep"},
	"vfx_storm": {"warmup": 3.0, "measure": 25.0, "bots": 1, "army": [40, 40], "storm": true,
		"what": "40 v 40 fight + both wizards casting every spell each 0.5 s + every VFX manager's effects round-robin"},
	"menu": {"warmup": 3.0, "measure": 20.0, "what": "main menu with the 3D diorama"},
}
## The west meadow fight spot (player bank, open ground; snapped to the navmesh).
const FIGHT_A := Vector3(-34.0, 0.0, 10.0)
const FIGHT_B := Vector3(-14.0, 0.0, 26.0)
const TITANS: Array[String] = ["res://art/units/titans/war_mammoth/war_mammoth.tscn",
	"res://art/units/titans/nightmare_knight/nightmare_knight.tscn"]
const TITAN_BASE_TYPE := "rime_colossus"
const VFX_GROUPS: Array[StringName] = [&"titan_vfx", &"titan_ground_vfx", &"mapfill_vfx", &"mapfill_beast_vfx",
	&"mapfill_wyrm_vfx", &"trade_vfx", &"unit_fire_gun_vfx", &"unit_ice_rifle_vfx", &"unit_nature_t3_vfx"]

var args := {}
var scenario := "mid100"
var spec: Dictionary = {}
var seed_value := 1
var kingdoms: Array[String] = ["fire", "shadow"]
var profile := false
var headless := true
var out_path := ""
## --upscaler / --render-scale (GameSettings.UPSCALER_*): set on the root viewport after the scene is added.
var upscaler := 0
var render_scale := 1.0
var main: Node
var probe: Node = null
var is_menu := false

var _t_init := 0
var _frames := 0
var _wait := 0
var _phase := "wait"          ## wait -> warmup -> measure -> done
var _phase_frame := 0
var _warm_frames := 0
var _measure_frames := 0
var _last_usec := 0
var _frame_ms := PackedFloat32Array()
var _gpu_ms := PackedFloat32Array()
var _band_frames := {}        ## band index -> PackedInt32Array (usec per measured frame)
var _eng_phys := 0
var _eng_other := 0
var _marks := 0
var _mon_sum := {}
var _mon_max := {}
var _units_samples: Array = []
var _nodes_samples: Array = []
var _hitches: Array[Dictionary] = []
var _events: Array[String] = []
var _added_this_frame := 0
var _vfx_created := 0
var _vfx_created_kinds := {}
var _census_start := {}
var _static_mem_start := 0.0
var _calib: Array[float] = []
var _mark_cost_us := 0.0
var _notes: Array[String] = []
var _rng_counter := 0
var _army: Array = [[], []]
var _titans: Array = []
var _cam_path: Array = []     ## [[t 0-1, Vector3, zoom]]
var _storm_next := 0.0
var _storm_i := 0
var _vfx_managers: Array = []
var _fight_center := Vector3.ZERO
var _was_baking := false
var _started_iso := ""
var _after_start := 0
var phys_split := false       ## --physsplit=1
var no_avoid := false         ## --noavoid=1
var no_pose := false          ## --nopose=1
var _vc_usec := 0             ## usec inside the units' velocity_computed handlers (measure window)
var _vc_calls := 0
var _vc_moving := 0           ## handler calls with a non-zero velocity
var _pose_nodes: Array[Node] = []   ## --nopose: the scripted model nodes kept frozen
var _variant_units := 0       ## unit count when the variant scan last ran (rescan trigger)
var _fed: Array[Node] = []    ## --noavoid: units whose handler the lab calls each physics frame


func _initialize() -> void:
	_t_init = Time.get_ticks_usec()
	_started_iso = Time.get_datetime_string_from_system(false, true)
	_parse_args()
	headless = DisplayServer.get_name() == "headless"
	seed(seed_value * 7919 + 17)
	Engine.physics_ticks_per_second = TICK
	Engine.max_fps = 0
	if not headless:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_calib.append(_calibrate())
	_mark_cost_us = _measure_mark_cost()
	node_added.connect(_on_node_added)
	if profile:
		probe = Probe.new()
		root.add_child(probe)
	is_menu = scenario == "menu"
	if is_menu:
		main = (load(MENU) as PackedScene).instantiate()
	else:
		main = (load(SKIRMISH) as PackedScene).instantiate()
		main.set(&"player_kingdom", StringName(kingdoms[0]))
		main.set(&"enemy_kingdom", StringName(kingdoms[1]))
		if &"time_limit_s" in main:
			main.set(&"time_limit_s", 0.0)
		if int(spec.get("bots", 1)) >= 2:
			var cs := load(COMMANDER_PATH) as Script
			var b: Node = cs.new()
			b.name = "LabBotPlayer"
			b.set(&"team", 0)
			b.set(&"difficulty", 1)
			main.add_child(b)
	root.add_child(main)
	current_scene = main
	# After the menus' GameSettings.ensure_loaded (it applies the player's saved upscaler): the lab's own choice wins.
	GameSettings.apply_render(root, upscaler, render_scale)
	_warm_frames = int(float(args.get("warmup", spec["warmup"])) * TICK)
	_measure_frames = int(float(args.get("measure", spec["measure"])) * TICK)
	print("PERF_LAB start %s seed %d %s profile %s %s" % [scenario, seed_value, ":".join(kingdoms), profile,
		"headless" if headless else "windowed %s" % str(DisplayServer.window_get_size())])


func _parse_args() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	scenario = String(args.get("scenario", "mid100"))
	if not SCENARIOS.has(scenario):
		push_error("PERF_LAB: unknown --scenario=%s (%s)" % [scenario, ", ".join(SCENARIOS.keys())])
		scenario = "mid100"
	spec = SCENARIOS[scenario]
	seed_value = String(args.get("seed", "1")).to_int()
	var pair := String(args.get("pair", "fire:shadow")).to_lower().split(":")
	if pair.size() == 2:
		kingdoms = [pair[0], pair[1]]
	profile = ["1", "true", "on"].has(String(args.get("profile", "0")))
	out_path = String(args.get("out", ""))
	upscaler = GameSettings.upscaler_from_id(String(args.get("upscaler", "off")))
	render_scale = clampf(String(args.get("render-scale", "1.0")).to_float(), GameSettings.RENDER_SCALE_MIN,
			GameSettings.RENDER_SCALE_MAX)
	phys_split = ["1", "true", "on"].has(String(args.get("physsplit", "0")))
	no_avoid = ["1", "true", "on"].has(String(args.get("noavoid", "0")))
	no_pose = ["1", "true", "on"].has(String(args.get("nopose", "0")))


## A fixed GDScript workload (ms): the same code on every run, so a slow result means a busy / throttled machine.
func _calibrate() -> float:
	var t0 := Time.get_ticks_usec()
	var acc := 0.0
	var arr: Array[float] = []
	for i in 200000:
		acc += sqrt(float(i)) * 0.5
		if i % 100 == 0:
			arr.append(acc)
	var d := {}
	for i in 20000:
		d[i % 997] = i
	return (Time.get_ticks_usec() - t0) / 1000.0 + 0.0 * acc


func _measure_mark_cost() -> float:
	var c := Probe.Clock.new()
	c.resize(4)
	var t0 := Time.get_ticks_usec()
	for i in 5000:
		c.mark(1 + i % 3, false, false)
	return float(Time.get_ticks_usec() - t0) / 5000.0 + 1.0   # + ~1 us for the node callback itself


# ---------------------------------------------------------------- seeding / tracking

func _on_node_added(node: Node) -> void:
	_added_this_frame += 1
	if &"class_rng" in node or &"_rng" in node or &"rng" in node:
		node.ready.connect(_seed_node_rngs.bind(node), CONNECT_ONE_SHOT)
	if _phase == "measure" and _is_vfx_child(node):
		_vfx_created += 1
		var k := node.get_class()
		_vfx_created_kinds[k] = int(_vfx_created_kinds.get(k, 0)) + 1


## True when a node is created under a VFX manager (scripts/vfx/, art/vfx/): pools should never do that.
func _is_vfx_child(node: Node) -> bool:
	var p := node.get_parent()
	for i in 6:
		if p == null or p == main or p == root:
			return false
		var s := p.get_script() as Script
		if s != null:
			var path := s.resource_path
			if path.begins_with("res://scripts/vfx/") or path.begins_with("res://art/vfx/"):
				return true
		p = p.get_parent()
	return false


func _seed_node_rngs(node: Node) -> void:
	for key: StringName in [&"class_rng", &"_rng", &"rng"]:
		if key in node:
			var r: Variant = node.get(key)
			if r is RandomNumberGenerator:
				_rng_counter += 1
				(r as RandomNumberGenerator).seed = hash([seed_value, _rng_counter, String(key)])


# ---------------------------------------------------------------- frames

func _process(_delta: float) -> bool:
	var now := Time.get_ticks_usec()
	var frame_us := now - _last_usec
	_last_usec = now
	_frames += 1
	var bands: Dictionary = probe.call(&"begin_frame") if probe else {}
	match _phase:
		"wait":
			if _ready_to_start():
				_start_scenario()
				_phase = "warmup"
				_phase_frame = 0
			else:
				_wait += 1
				if _wait > 9000:
					return _finish("level never became ready (navmesh bake?)")
		"warmup":
			_phase_frame += 1
			_drive()
			_variant_step()
			if _phase_frame == _warm_frames - 3:
				_census_start = _census()
				_static_mem_start = Performance.get_monitor(Performance.MEMORY_STATIC)
			if _phase_frame >= _warm_frames:
				_phase = "measure"
				_phase_frame = 0
				_vc_usec = 0
				_vc_calls = 0
				_vc_moving = 0
		"measure":
			if _phase_frame > 0:   # the first measured frame is the boundary: skip
				_record(frame_us / 1000.0, bands)
			_phase_frame += 1
			_drive()
			_variant_step()
			if _phase_frame > _measure_frames:
				if not headless and bool(spec.get("gpu_ablate", false)) and not args.has("no-ablate"):
					_ablate_begin()
					_phase = "ablate"
				else:
					return _finish("")
		"ablate":
			if _ablate_step():
				return _finish("")
	_added_this_frame = 0
	return false


func _ready_to_start() -> bool:
	if is_menu:
		return _frames > 30
	if not bool(main.get(&"match_started")):
		return false
	_after_start += 1   # a few frames so the navigation map has synced before the lab snaps spawn points
	return _after_start > 10


func _record(ms: float, bands: Dictionary) -> void:
	_frame_ms.append(ms)
	var i := _frame_ms.size() - 1
	if not headless:
		var g := RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		for vp: Node in _subviewports():
			g += RenderingServer.viewport_get_measured_render_time_gpu((vp as Viewport).get_viewport_rid())
		_gpu_ms.append(g)
	for m: Array in [["process_ms", Performance.TIME_PROCESS, 1000.0], ["physics_ms", Performance.TIME_PHYSICS_PROCESS, 1000.0],
			["navigation_ms", Performance.TIME_NAVIGATION_PROCESS, 1000.0], ["draw_calls", Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME, 1.0],
			["objects", Performance.RENDER_TOTAL_OBJECTS_IN_FRAME, 1.0], ["primitives", Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME, 1.0],
			["physics_active_objects", Performance.PHYSICS_3D_ACTIVE_OBJECTS, 1.0], ["physics_pairs", Performance.PHYSICS_3D_COLLISION_PAIRS, 1.0],
			["nav_agents", Performance.NAVIGATION_AGENT_COUNT, 1.0]]:
		var v := Performance.get_monitor(m[1]) * float(m[2])
		_mon_sum[m[0]] = float(_mon_sum.get(m[0], 0.0)) + v
		_mon_max[m[0]] = maxf(float(_mon_max.get(m[0], 0.0)), v)
	if i % 30 == 0:
		_units_samples.append(get_nodes_in_group(&"units").size())
		_nodes_samples.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var top: Array = []
	if not bands.is_empty():
		var pr: PackedInt64Array = bands["proc"]
		var ph: PackedInt64Array = bands["phys"]
		for k in pr.size():
			var u := int(pr[k] + (ph[k] if k < ph.size() else 0))
			if not _band_frames.has(k):
				var arr: Array = []   # a plain Array (reference type): a Packed array in a Dictionary copies on append
				arr.resize(i)
				arr.fill(0)           # zeros for the frames before the band existed
				_band_frames[k] = arr
			(_band_frames[k] as Array).append(u)
		_eng_phys += int(bands["engine_physics"])
		_eng_other += int(bands["engine_other"])
		_marks += (pr.size() + 1) * (1 + int(bands["physics_steps"]))
		if ms > Budgets.HITCH_MS:
			var idx: Array = []
			for k2 in pr.size():
				idx.append([int(pr[k2] + (ph[k2] if k2 < ph.size() else 0)), k2])
			idx.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
			for e: Array in idx.slice(0, 3):
				top.append({"key": _band_key(int(e[1])), "ms": snappedf(float(e[0]) / 1000.0, 0.01)})
			top.append({"key": "(engine physics/nav step)", "ms": snappedf(float(bands["engine_physics"]) / 1000.0, 0.01)})
			top.append({"key": "(engine render/idle)", "ms": snappedf(float(bands["engine_other"]) / 1000.0, 0.01)})
	if ms > Budgets.HITCH_MS:
		var ev: Array[String] = []
		ev.append_array(_events)
		if _added_this_frame > 0:
			ev.append("%d nodes added" % _added_this_frame)
		if not is_menu:
			var region: Variant = main.get(&"nav_region")
			if region is NavigationRegion3D and (region as NavigationRegion3D).is_baking():
				ev.append("navmesh rebaking")
		_hitches.append({"frame": i, "t": _clock(_game_time()), "ms": snappedf(ms, 0.1), "top": top, "events": ", ".join(ev)})
	_events.clear()


func _band_key(k: int) -> String:
	if probe == null:
		return ""
	var b: Array = probe.get(&"bands")
	return String(b[k]) if k < b.size() else "?"


func _game_time() -> float:
	if not is_menu and main.has_method(&"match_time"):
		return float(main.call(&"match_time"))
	return float(_frames) / TICK


func _subviewports() -> Array:
	var out: Array = []
	if is_menu:
		for n in main.find_children("*", "SubViewport", true, false):
			out.append(n)
	return out


# ---------------------------------------------------------------- scenario setup

func _start_scenario() -> void:
	if not headless:
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		for vp: Node in _subviewports():
			RenderingServer.viewport_set_measure_render_time((vp as Viewport).get_viewport_rid(), true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if is_menu:
		_notes.append("menu: diorama in its own SubViewport; GPU time = root + SubViewports")
		return
	_seed_services()
	var cam: Variant = main.get(&"camera_rig")
	if cam is Node:
		(cam as Node).set(&"edge_pan_enabled", false)
	var army: Array = spec.get("army", [0, 0])
	if args.has("army"):   # --army=P:E overrides the scenario's army sizes (unit-count sweeps, perf pass 2026-10-09)
		var pe := String(args["army"]).split(":")
		if pe.size() == 2:
			army = [pe[0].to_int(), pe[1].to_int()]
	if int(army[0]) + int(army[1]) > 0:
		_spawn_armies(int(army[0]), int(army[1]))
	if int(spec.get("titans", 0)) > 0:
		_spawn_titans(int(spec["titans"]))
	if bool(spec.get("beasts", false)):
		_spawn_beasts()
	if bool(spec.get("storm", false)):
		_setup_storm()
	_build_camera_path()
	_events.append("scenario setup")


func _seed_services() -> void:
	for group: StringName in [&"thieves_guild", &"camp_manager", &"epic_beasts", &"critter_herds"]:
		for n in get_nodes_in_group(group):
			var r: Variant = n.get(&"rng")
			if r is RandomNumberGenerator:
				(r as RandomNumberGenerator).seed = hash([seed_value, String(group)])


## Soldier types of a kingdom (not workers / caravans / summons), sorted by id: deterministic.
func _soldier_types(kingdom: String) -> Array:
	var out: Array = []
	var files := DirAccess.get_files_at("res://data/units/")
	var names: Array[String] = []
	for f: String in files:
		if f.ends_with(".tres"):
			names.append(f.get_basename())
	names.sort()
	for id: String in names:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or String(t.get(&"faction")) != kingdom or bool(t.get(&"is_worker")):
			continue
		if bool(t.get(&"is_caravan")) or float(t.get(&"lifetime")) > 0.0 or int(t.get(&"cost")) <= 0:
			continue
		out.append(id)
	return out


func _snap(p: Vector3) -> Vector3:
	var region: Variant = main.get(&"nav_region")
	if region is NavigationRegion3D:
		var map := (region as NavigationRegion3D).get_navigation_map()
		var q := NavigationServer3D.map_get_closest_point(map, p)
		if q.is_finite():
			return q
	return p


func _spawn_armies(n_player: int, n_enemy: int) -> void:
	_fight_center = (FIGHT_A + FIGHT_B) * 0.5
	for team in [0, 1]:
		var n: int = n_player if team == 0 else n_enemy
		var types := _soldier_types(kingdoms[team])
		if types.is_empty():
			types = ["flame_guard"] if team == 0 else ["shade"]
		var at: Vector3 = FIGHT_A if team == 0 else FIGHT_B
		var goal: Vector3 = FIGHT_B if team == 0 else FIGHT_A
		var cols := int(ceil(sqrt(float(n))))
		for i in n:
			var u: Node = main.call(&"make_unit", types[i % types.size()])
			if u == null:
				continue
			u.set(&"team", team)
			main.add_child(u)
			var off := Vector3((i % cols - cols * 0.5) * 1.2, 0.0, (floori(float(i) / cols) - cols * 0.5) * 1.2)
			(u as Node3D).global_position = _snap(at + off)
			u.call(&"command_stop")
			_army[team].append(u)
		for u2: Node in _army[team]:
			u2.call(&"command_attack_move", goal)
	var sel: Variant = main.get(&"selection")
	if sel is Node and (sel as Node).has_method(&"select_units"):
		var arr: Array = []
		arr.assign(_army[0])
		sel.call(&"select_units", arr)   # a real player has the army selected (selection panel cost)
	_events.append("armies %d v %d spawned" % [n_player, n_enemy])


## No gameplay titan exists yet (13.C3 pending): a rime_colossus stat block wearing a titan model (art/units/titans).
func _spawn_titans(per_side: int) -> void:
	var base: Resource = load("res://data/units/%s.tres" % TITAN_BASE_TYPE)
	if base == null:
		_notes.append("titans: %s missing, none spawned" % TITAN_BASE_TYPE)
		return
	for team in [0, 1]:
		for i in per_side:
			var path := TITANS[(team + i) % TITANS.size()]
			if not ResourceLoader.exists(path):
				continue
			var t: Resource = base.duplicate()
			t.set(&"model_scene", load(path))
			t.set(&"id", StringName("lab_titan_%d_%d" % [team, i]))
			t.set(&"max_hp", 3000.0)
			var u: Node = t.call(&"create_unit")
			u.set(&"team", team)
			main.add_child(u)
			(u as Node3D).global_position = _snap((FIGHT_A if team == 0 else FIGHT_B) + Vector3(0.0, 0.0, -6.0 if team == 0 else 6.0))
			u.call(&"command_attack_move", FIGHT_B if team == 0 else FIGHT_A)
			_titans.append(u)
	_notes.append("titans: %d (rime_colossus stats + %s models; no gameplay titan yet)" % [_titans.size(),
		", ".join(TITANS.map(func(p: String) -> String: return p.get_file().get_basename()))])


func _spawn_beasts() -> void:
	var n := 0
	for eb in get_nodes_in_group(&"epic_beasts"):
		if not eb.has_method(&"lairs"):
			continue
		for l: Variant in eb.call(&"lairs"):
			var id: Variant = (l as Dictionary).get("id", (l as Dictionary).get(&"id", null)) if l is Dictionary else null
			if id != null and eb.call(&"spawn_now", StringName(str(id))) != null:
				n += 1
	_notes.append("epic beasts spawned: %d" % n)
	_events.append("%d beasts spawned" % n)


# ---------------------------------------------------------------- the VFX storm

func _setup_storm() -> void:
	for team in [0, 1]:
		var w: Variant = main.call(&"wizard_of", team) if main.has_method(&"wizard_of") else null
		if w == null:
			continue
		(w as Node3D).global_position = _snap((FIGHT_A if team == 0 else FIGHT_B) + Vector3(-3.0 if team == 0 else 3.0, 0.0, 3.0 if team == 0 else -3.0))
		(w as Node).call(&"command_stop")
		var caster: Node = (w as Node).get_node_or_null(^"SpellCaster")
		if caster:
			for id: StringName in caster.call(&"spell_ids"):
				caster.call(&"set_rank", id, 3)
	for g: StringName in VFX_GROUPS:
		for m in get_nodes_in_group(g):
			if m.has_method(&"play"):
				var ids: Variant = m.get(&"EFFECTS")
				if ids == null:
					var consts := (m.get_script() as Script).get_script_constant_map()
					ids = consts.get("EFFECTS", [])
				if ids is Array and not (ids as Array).is_empty():
					_vfx_managers.append([m, ids])
	_notes.append("storm: %d VFX managers driven (%s)" % [_vfx_managers.size(),
		", ".join(_vfx_managers.map(func(e: Array) -> String: return String((e[0] as Node).name)))])


func _storm_step() -> void:
	var t := float(_phase_frame) / TICK + (float(_warm_frames) / TICK if _phase == "measure" else 0.0)
	if t < _storm_next:
		return
	_storm_next = t + 0.5
	for team in [0, 1]:
		var w: Variant = main.call(&"wizard_of", team)
		if w == null or not is_instance_valid(w) or not (w as Node).call(&"is_alive"):
			continue
		var caster: Node = (w as Node).get_node_or_null(^"SpellCaster")
		if caster == null:
			continue
		if &"mana" in w:
			(w as Node).set(&"mana", 9999.0)
		caster.call(&"reset_cooldowns")
		var foe: Node = _first_alive(_army[1 - team])
		var spot: Vector3 = (foe as Node3D).global_position if foe else _fight_center
		for id: StringName in caster.call(&"spell_ids"):
			var r: String = caster.call(&"cast", id, foe) if foe else "no target"
			if r != "":
				r = caster.call(&"cast", id, spot)
			if r == "":
				_events.append("cast %s" % id)
	# Every VFX manager: its next effect at the fight (target = a living unit).
	var target: Node = _first_alive(_army[_storm_i % 2])
	for e: Array in _vfx_managers:
		var m: Node = e[0]
		if not is_instance_valid(m):
			continue
		var ids: Array = e[1]
		var id: StringName = ids[_storm_i % ids.size()]
		var at: Vector3 = (target as Node3D).global_position if target else _fight_center
		m.call(&"play", id, at, target)
	_storm_i += 1


func _first_alive(list: Array) -> Node:
	for u: Variant in list:
		if is_instance_valid(u) and (u as Node).call(&"is_alive"):
			return u
	return null


# ---------------------------------------------------------------- physics-step split (P12)

## Every frame of warm-up + measure: wraps new units' velocity_computed handler (--physsplit), keeps avoidance off
## (--noavoid: a revive turns it back on) and the model scripts frozen (--nopose: the off-camera tiers wake them).
func _variant_step() -> void:
	if is_menu or not (phys_split or no_avoid or no_pose):
		return
	var units := get_nodes_in_group(&"units")
	var rescan := units.size() != _variant_units or _phase_frame % 30 == 0
	_variant_units = units.size()
	if rescan:
		_pose_nodes.clear()
		_fed.clear()
	for u: Node in units:
		if no_avoid:
			var ag: Variant = u.get(&"_agent")
			if ag is NavigationAgent3D and (ag as NavigationAgent3D).avoidance_enabled:
				(ag as NavigationAgent3D).avoidance_enabled = false
		if not rescan:
			continue
		if no_avoid and u.get(&"_agent") is NavigationAgent3D:
			_fed.append(u)
		if phys_split and not u.has_meta(&"perf_lab_vc"):
			_wrap_velocity_handler(u)
		if no_pose:
			var model: Variant = u.get(&"_model")
			if model is Node:
				var m := model as Node
				if m.get_script() != null:
					_pose_nodes.append(m)
				for c: Node in m.find_children("*", "", true, false):
					if c.get_script() != null:
						_pose_nodes.append(c)
	for n: Node in _pose_nodes:
		if is_instance_valid(n):
			n.set_process(false)
			n.set_physics_process(false)


## --noavoid: the agents no longer emit velocity_computed; hand every unit its own agent velocity instead (runs at
## the top of the physics pass, before the probe's first marker: still inside the "engine physics" gap).
func _physics_process(_delta: float) -> bool:
	if not no_avoid or _fed.is_empty():
		return false
	for u: Node in _fed:
		if not is_instance_valid(u) or not u.is_physics_processing():
			continue
		var v := (u.get(&"_agent") as NavigationAgent3D).velocity
		if phys_split:
			_timed_velocity_handler(v, u)
		else:
			u.call(&"_on_velocity_computed", v)
	return false


func _wrap_velocity_handler(u: Node) -> void:
	var ag: Variant = u.get(&"_agent")
	if not ag is NavigationAgent3D:
		return
	var orig := Callable(u, &"_on_velocity_computed")
	var sig := (ag as NavigationAgent3D).velocity_computed
	if not sig.is_connected(orig):
		return
	sig.disconnect(orig)
	sig.connect(_timed_velocity_handler.bind(u))
	u.set_meta(&"perf_lab_vc", true)


func _timed_velocity_handler(v: Vector3, u: Node) -> void:
	var t := Time.get_ticks_usec()
	u.call(&"_on_velocity_computed", v)
	_vc_usec += Time.get_ticks_usec() - t
	_vc_calls += 1
	if v.x * v.x + v.z * v.z > 1.0e-6:
		_vc_moving += 1


class NoopHandler:
	extends RefCounted
	func _on_velocity_computed(_v: Vector3) -> void:
		pass


## What one wrapped call adds inside the timed interval (a dynamic call of an empty handler + one clock read), in us.
func _measure_wrap_cost() -> float:
	var o := NoopHandler.new()
	var t0 := Time.get_ticks_usec()
	for i in 20000:
		o.call(&"_on_velocity_computed", Vector3.ONE)
	for i in 20000:
		var _t := Time.get_ticks_usec()
	return float(Time.get_ticks_usec() - t0) / 20000.0


func _phys_split_result(res: Dictionary) -> Dictionary:
	var n := maxf(float(_frame_ms.size()), 1.0)
	var wrap_us := _measure_wrap_cost()
	var vc_ms := maxf(0.0, (float(_vc_usec) - wrap_us * _vc_calls) / 1000.0 / n)
	var mon: Dictionary = res.get("monitors", {})
	var out := {"variant": "noavoid" if no_avoid else ("nopose" if no_pose else "normal"),
		"wrapped": phys_split, "frame_avg_ms": float((res.get("frame", {}) as Dictionary).get("avg", 0.0)),
		"units_avg": res.get("units_avg", 0),
		"physics_engine": str(ProjectSettings.get_setting("physics/3d/physics_engine", "?")),
		"physics_server": PhysicsServer3D.get_class(),
		"nav_monitor_ms": mon.get("navigation_ms", 0.0), "physics_monitor_ms": mon.get("physics_ms", 0.0)}
	if phys_split:
		out["slide_handler_ms"] = snappedf(vc_ms, 0.001)
		out["slide_handler_calls_per_frame"] = snappedf(_vc_calls / n, 0.1)
		out["slide_handler_moving_per_frame"] = snappedf(_vc_moving / n, 0.1)
		out["wrap_cost_us"] = snappedf(wrap_us, 0.01)
		out["handler_us_per_call"] = snappedf(vc_ms * 1000.0 * n / maxf(float(_vc_calls), 1.0), 0.01)
	var eng: Dictionary = res.get("engine", {})
	if not eng.is_empty():
		var gap := float(eng.get("physics_ms", 0.0))
		out["engine_physics_gap_ms"] = gap
		if phys_split:
			# The gap after the physics pass = nav server (avoidance + map sync) + the velocity handlers it fires +
			# the physics server step. Without the handlers: avoidance + sync + physics step.
			out["gap_minus_handlers_ms"] = snappedf(gap - vc_ms, 0.001)
	var sys: Dictionary = res.get("systems", {})
	for sid: String in sys:
		out["sys_%s_ms" % sid] = (sys[sid] as Dictionary).get("avg_ms", 0.0)
	for row: Variant in res.get("hot", []):
		var r: Dictionary = row
		var key := String(r.get("key", ""))
		if key == "scripts/units/unit.gd" or key == "[NavigationAgent3D]":
			out["band_%s_ms" % key.get_file().trim_suffix(".gd").trim_prefix("[").trim_suffix("]")] = r.get("avg_ms", 0.0)
	return out


# ---------------------------------------------------------------- camera paths (fixed, game-time driven)

func _build_camera_path() -> void:
	match scenario:
		"early":
			_cam_path = [[0.0, Vector3(-36, 0, 36), 30.0], [0.3, Vector3(-20, 0, 20), 40.0], [0.55, Vector3(0, 0, 0), 45.0],
				[0.8, Vector3(30, 0, -30), 30.0], [1.0, Vector3(-36, 0, 36), 30.0]]
		"late200":
			var c := _fight_center
			_cam_path = [[0.0, c, 30.0], [0.2, c, 45.0], [0.4, Vector3(-45, 0, -45), 55.0], [0.6, Vector3(0, 0, 0), 55.0],
				[0.8, Vector3(20, 0, -20), 45.0], [1.0, c, 30.0]]
		_:
			var c2 := _fight_center
			_cam_path = [[0.0, c2 + Vector3(-4, 0, 0), 30.0], [0.5, c2 + Vector3(4, 0, 0), 38.0], [1.0, c2 + Vector3(0, 0, 4), 32.0]]


func _drive() -> void:
	if is_menu:
		return
	if bool(spec.get("storm", false)):
		_storm_step()
	var cam: Variant = main.get(&"camera_rig")
	if not (cam is Node3D) or _cam_path.is_empty():
		return
	var total := float(_warm_frames + _measure_frames)
	var done := float(_phase_frame + (_warm_frames if _phase == "measure" else 0))
	var u := clampf(done / maxf(total, 1.0), 0.0, 1.0)
	for i in range(1, _cam_path.size()):
		var a: Array = _cam_path[i - 1]
		var b: Array = _cam_path[i]
		if u <= float(b[0]):
			var k := (u - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			(cam as Node).call(&"focus_on", (a[1] as Vector3).lerp(b[1], k))
			var z := lerpf(float(a[2]), float(b[2]), k)
			(cam as Node).set(&"_target_zoom", z)   # lab only: the rig has no public zoom setter
			(cam as Node).set(&"_zoom", z)
			return


# ---------------------------------------------------------------- GPU cost by layer (windowed late200)

## After the measure window: the tree is paused, the camera parked over the Crown Isle at zoom 55 (river, decor,
## armies in view), then each draw layer is hidden for ABLATE_FRAMES frames between baseline windows. Its GPU cost =
## baseline GPU ms - "hidden" GPU ms. Answers "what do the river / decor / critters / shadows cost" without editing
## the game. `--no-ablate` skips it.
const ABLATE_FRAMES := 90
const ABLATE_SETTLE := 15
var _abl_items: Array = []     ## [label, Array of [node, property, off value]]
var _abl_saved: Array = []     ## [node, property, old value] of the item hidden now
var _abl_w := 0                ## window: even = baseline, odd = item (w - 1) / 2 hidden
var _abl_f := 0
var _abl_acc: Array = []
var _abl_base := 0.0
var _abl_rows: Array = []


func _ablate_begin() -> void:
	paused = true
	var cam: Variant = main.get(&"camera_rig")
	if cam is Node3D:
		(cam as Node).call(&"focus_on", Vector3(-6.0, 0.0, 6.0))
		(cam as Node).set(&"_zoom", 55.0)          # lab only (no public zoom API)
		(cam as Node).set(&"_target_zoom", 55.0)
		(cam as Node).call(&"_apply_zoom")         # its _process is paused
	var add := func(label: String, targets: Array) -> void:
		if not targets.is_empty():
			_abl_items.append([label, targets])
	var dressing: Array = []
	var ground: Array = []
	var critters: Array = []
	for n in main.get_children():
		var s := n.get_script() as Script
		var p := s.resource_path if s else ""
		if p.contains("map_dressing"):
			dressing.append([n, &"visible", false])
		elif p.contains("critter_system"):
			critters.append([n, &"visible", false])
		elif n is MeshInstance3D and (n as MeshInstance3D).get_aabb().size.x > 100.0:
			ground.append([n, &"visible", false])
	add.call("map dressing (biome decor, cliffs, border)", dressing)
	var props: Variant = main.get(&"env_props")
	add.call("env props (trees, rocks, pillars)", [[props, &"visible", false]] if props is Node3D else [])
	var water: Array = []
	var river: Variant = main.get(&"river")
	if river is Node:
		for g in (river as Node).find_children("*", "GeometryInstance3D", true, false):
			water.append([g, &"visible", false])
	add.call("river meshes (water, riverbed, fords, bridges)", water)
	add.call("ground mesh (ground shader incl. river paint)", ground)
	add.call("cosmetic critters", critters)
	var units: Array = []
	for u in get_nodes_in_group(&"units"):
		if u is Node3D:
			units.append([u, &"visible", false])
	add.call("units, titans, beasts (%d)" % units.size(), units)
	var blds: Array = []
	for b in get_nodes_in_group(&"buildings"):
		if b is Node3D:
			blds.append([b, &"visible", false])
	add.call("buildings (%d)" % blds.size(), blds)
	var suns: Array = []
	for l in main.find_children("*", "DirectionalLight3D", true, false):
		suns.append([l, &"shadow_enabled", false])
	add.call("sun shadows", suns)
	var hud: Variant = main.get(&"hud")
	add.call("HUD", [[hud, &"visible", false]] if hud is CanvasLayer else [])
	_abl_w = 0
	_abl_f = 0
	_abl_acc = []
	_events.append("gpu ablation: %d layers" % _abl_items.size())


## One frame of the ablation; true when done.
func _ablate_step() -> bool:
	_abl_f += 1
	if _abl_f > ABLATE_SETTLE:
		_abl_acc.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	if _abl_f < ABLATE_SETTLE + ABLATE_FRAMES:
		return false
	var ms := Stats.mean(_abl_acc)
	if _abl_w % 2 == 0:
		_abl_base = ms
		var k := _abl_w / 2
		if k >= _abl_items.size():
			_restore_ablation()
			paused = false
			return true
		_abl_saved = []
		for t: Array in _abl_items[k][1]:
			var node: Variant = t[0]
			if is_instance_valid(node):
				_abl_saved.append([node, t[1], (node as Object).get(t[1])])
				(node as Object).set(t[1], t[2])
	else:
		var k2 := (_abl_w - 1) / 2
		_restore_ablation()
		_abl_rows.append({"layer": _abl_items[k2][0], "base_ms": snappedf(_abl_base, 0.001), "off_ms": snappedf(ms, 0.001),
			"cost_ms": snappedf(_abl_base - ms, 0.001), "cost_pct": snappedf(100.0 * (_abl_base - ms) / maxf(_abl_base, 0.001), 0.1)})
	_abl_w += 1
	_abl_f = 0
	_abl_acc = []
	return false


func _restore_ablation() -> void:
	for s: Array in _abl_saved:
		if is_instance_valid(s[0]):
			(s[0] as Object).set(s[1], s[2])
	_abl_saved = []


# ---------------------------------------------------------------- census

func _census() -> Dictionary:
	var c := {"nodes": 0, "nodes_non_unit": 0, "geometry_nodes": 0, "lights": 0, "shadow_lights": 0, "multimesh_nodes": 0,
		"decor_instances": 0, "particle_systems": 0, "shadow_casters": 0, "draw_nodes_decor": 0}
	var classes := {}
	var stack: Array[Node] = [main]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		c["nodes"] += 1
		var in_unit := n.is_in_group(&"units")
		if not in_unit:
			c["nodes_non_unit"] += 1
		var cls := n.get_class()
		classes[cls] = int(classes.get(cls, 0)) + 1
		if n is Light3D:
			var l := n as Light3D
			if l.is_visible_in_tree():
				if not (l is DirectionalLight3D):
					c["lights"] += 1
				if l.shadow_enabled:
					c["shadow_lights"] += 1
		elif n is GeometryInstance3D:
			var gi := n as GeometryInstance3D
			if gi.is_visible_in_tree():
				c["geometry_nodes"] += 1
				if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
					c["shadow_casters"] += 1
				if gi is GPUParticles3D or gi is CPUParticles3D:
					c["particle_systems"] += 1
				if gi is MultiMeshInstance3D:
					c["multimesh_nodes"] += 1
					var mm := (gi as MultiMeshInstance3D).multimesh
					if mm and not _under_script(gi, "critter_system"):
						var vis := mm.visible_instance_count
						c["decor_instances"] += mm.instance_count if vis < 0 else vis
				if _under_script(gi, "map_dressing"):
					c["draw_nodes_decor"] += 1
		if in_unit:
			continue   # unit subtrees counted once (as units)
		for ch in n.get_children():
			stack.append(ch)
	var top: Array = []
	for k: String in classes:
		top.append([int(classes[k]), k])
	top.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var tops := {}
	for e: Array in top.slice(0, 12):
		tops[e[1]] = e[0]
	c["node_classes"] = tops
	return c


func _under_script(n: Node, needle: String) -> bool:
	var p := n.get_parent()
	for i in 8:
		if p == null or p == main:
			return false
		var s := p.get_script() as Script
		if s != null and s.resource_path.contains(needle):
			return true
		p = p.get_parent()
	return false


# ---------------------------------------------------------------- the end

func _finish(error: String) -> bool:
	if _phase == "done":
		return true
	_phase = "done"
	_calib.append(_calibrate())
	var measured_s := float(_frame_ms.size()) / TICK
	var res := {"v": 1, "scenario": scenario, "what": spec.get("what", ""), "mode": "cpu" if headless else "gpu",
		"resolution": "" if headless else "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"seed": seed_value, "pair": ":".join(kingdoms), "profile": profile, "commit": String(args.get("commit", "")),
		"run": String(args.get("run", "1")).to_int(), "started": _started_iso,
		"measured_s": snappedf(measured_s, 0.01), "real_s": snappedf((Time.get_ticks_usec() - _t_init) / 1.0e6, 0.01),
		"calib_ms": [snappedf(_calib[0], 0.01), snappedf(_calib[-1], 0.01)], "cpu_count": OS.get_processor_count(),
		"upscaler": GameSettings.UPSCALER_IDS[upscaler], "render_scale": snappedf(
			GameSettings.effective_render_scale(upscaler, render_scale), 0.01)}
	if error != "":
		res["error"] = error
	var fl: Array = Array(_frame_ms)
	res["frame"] = Stats.frame_summary(fl, Budgets.HITCH_MS)
	res["units_avg"] = int(round(Stats.mean(_units_samples)))
	res["nodes_avg"] = int(round(Stats.mean(_nodes_samples)))
	var n := maxf(float(_frame_ms.size()), 1.0)
	var mon := {}
	for k: String in _mon_sum:
		mon[k] = snappedf(float(_mon_sum[k]) / n, 0.001)
		mon[k + "_max"] = snappedf(float(_mon_max[k]), 0.001)
	mon["nodes_end"] = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	mon["objects_end"] = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	mon["resources_end"] = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	mon["static_mem_mb"] = snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1)
	mon["video_mem_mb"] = snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1)
	res["monitors"] = mon
	if not headless:
		var gl: Array = Array(_gpu_ms)
		res["gpu"] = {"gpu_ms_avg": snappedf(Stats.mean(gl), 0.001), "gpu_ms_p95": snappedf(Stats.percentile(gl, 95.0), 0.001),
			"gpu_ms_max": snappedf(Stats.max_of(gl), 0.001), "draw_calls_avg": mon.get("draw_calls", 0.0),
			"draw_calls_max": mon.get("draw_calls_max", 0.0), "objects_avg": mon.get("objects", 0.0),
			"objects_max": mon.get("objects_max", 0.0), "primitives_avg": mon.get("primitives", 0.0),
			"primitives_max": mon.get("primitives_max", 0.0), "video_mem_mb": mon["video_mem_mb"]}
	var census_end := _census() if main and is_instance_valid(main) else {}
	res["census"] = _census_start if not _census_start.is_empty() else census_end
	var h := {"vfx_nodes_created": _vfx_created, "orphan_nodes": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"static_mem_growth_mb": snappedf((Performance.get_monitor(Performance.MEMORY_STATIC) - _static_mem_start) / 1048576.0, 0.1)}
	if not _vfx_created_kinds.is_empty():
		h["vfx_nodes_top"] = JSON.stringify(_vfx_created_kinds)
	if not _census_start.is_empty() and not census_end.is_empty():
		var a := float(_census_start["nodes_non_unit"])
		h["node_growth_pct"] = snappedf(100.0 * (float(census_end["nodes_non_unit"]) - a) / maxf(a, 1.0), 0.1)
		h["node_classes_end"] = census_end.get("node_classes", {})
	res["health"] = h
	res["ai"] = _ai_stats()
	if not _abl_rows.is_empty():
		res["gpu_ablation"] = _abl_rows
	if profile:
		_profile_result(res)
	if phys_split or no_avoid or no_pose:
		res["phys_split"] = _phys_split_result(res)
	_hitches.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["ms"]) > float(y["ms"]))
	res["hitch_list"] = _hitches.slice(0, 20)
	res["notes"] = _notes
	var line := JSON.stringify(res)
	print("PERF_LAB_RESULT " + line)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f:
			f.store_line(line)
			f.close()
		else:
			push_error("PERF_LAB: can't write %s" % out_path)
	return true


func _ai_stats() -> Dictionary:
	if is_menu:
		return {}
	var meds: Array = []
	var mx := 0
	var ticks := 0
	var worst_step := ""
	var worst := 0
	for n in main.get_children():
		var s := n.get_script() as Script
		if s == null or s.resource_path != COMMANDER_PATH:
			continue
		meds.append(float(n.call(&"tick_usec_median")))
		mx = maxi(mx, int(n.get(&"tick_usec_max")))
		ticks += int(n.get(&"tick_count"))
		var rmax: Variant = n.get(&"rule_usec_max")
		var names: Variant = s.get_script_constant_map().get("STEP_NAMES", [])
		if rmax is Dictionary:
			for k: Variant in rmax:
				if int(rmax[k]) > worst:
					worst = int(rmax[k])
					worst_step = String(names[int(k)]) if names is Array and int(k) < (names as Array).size() else str(k)
	if meds.is_empty():
		return {}
	return {"commanders": meds.size(), "ticks": ticks, "tick_median_ms": snappedf(Stats.median(meds) / 1000.0, 0.001),
		"tick_max_ms": snappedf(mx / 1000.0, 0.001), "worst_step": worst_step, "worst_step_ms": snappedf(worst / 1000.0, 0.001),
		"note": "commander.gd counters since the match start (first tick not counted)"}


func _profile_result(res: Dictionary) -> void:
	var bands: Array = probe.get(&"bands")
	var nodes: PackedInt32Array = probe.get(&"band_nodes")
	var n := _frame_ms.size()
	var frame_avg := float(res["frame"]["avg"])
	var rows: Array[Dictionary] = []
	var sys_frames := {}   # system id -> PackedFloat32Array (ms per frame)
	for k: int in _band_frames:
		var arr: Array = _band_frames[k]
		while arr.size() < n:
			arr.append(0)
		var total := 0
		var ms_list: Array = []
		for v in arr:
			total += int(v)
			ms_list.append(int(v) / 1000.0)
		var key: String = String(bands[k]) if k < bands.size() else "?"
		var sysrow: Dictionary = Budgets.system_of(key) if k > 0 else {"id": "unclassified", "label": "Unclassified nodes"}
		var avg := float(total) / 1000.0 / maxf(float(n), 1.0)
		rows.append({"key": key, "system": sysrow["label"], "system_id": sysrow["id"], "nodes": nodes[k] if k < nodes.size() else 0,
			"avg_ms": snappedf(avg, 0.0001), "median_ms": snappedf(Stats.median(ms_list), 0.0001),
			"p95_ms": snappedf(Stats.percentile(ms_list, 95.0), 0.0001), "max_ms": snappedf(Stats.max_of(ms_list), 0.001),
			"share_pct": snappedf(100.0 * avg / maxf(frame_avg, 0.001), 0.1)})
		var sid: String = sysrow["id"]
		if not sys_frames.has(sid):
			var z := PackedFloat32Array()
			z.resize(n)
			sys_frames[sid] = z
		var sf: PackedFloat32Array = sys_frames[sid]
		for i in n:
			sf[i] += int(arr[i]) / 1000.0
		sys_frames[sid] = sf
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["avg_ms"]) > float(b["avg_ms"]))
	var hot: Array = []
	for r: Dictionary in rows:
		if r["key"] == "(other: unclassified nodes)":
			continue
		hot.append(r)
		if hot.size() >= 25:
			break
	res["hot"] = hot
	var systems := {}
	for sid2: String in sys_frames:
		var l: Array = Array(sys_frames[sid2])
		systems[sid2] = {"avg_ms": snappedf(Stats.mean(l), 0.0001), "median_ms": snappedf(Stats.median(l), 0.0001),
			"p95_ms": snappedf(Stats.percentile(l, 95.0), 0.0001), "max_ms": snappedf(Stats.max_of(l), 0.001)}
	res["systems"] = systems
	var unc := 0.0
	for r2: Dictionary in rows:
		if r2["system_id"] == "unclassified":
			unc = float(r2["avg_ms"])
	res["engine"] = {"physics_ms": snappedf(_eng_phys / 1000.0 / maxf(n, 1.0), 0.001),
		"other_ms": snappedf(_eng_other / 1000.0 / maxf(n, 1.0), 0.001), "unclassified_ms": unc,
		"probe_overhead_ms": snappedf(_marks * _mark_cost_us / 1000.0 / maxf(n, 1.0), 0.001), "bands": bands.size(),
		"mark_cost_us": snappedf(_mark_cost_us, 0.01)}
	var lint := {}
	for r3: Variant in hot.slice(0, 10):
		var key2: String = (r3 as Dictionary)["key"]
		var found := Hints.lint_script(key2)
		if not found.is_empty():
			lint[key2] = found.slice(0, 12)
	res["lint"] = lint


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
