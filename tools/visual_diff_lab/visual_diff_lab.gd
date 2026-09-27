extends SceneTree
## VISUAL DIFF LAB (docs/plan/visual-diff-lab.md is the manual): renders a fixed shot list (tools/visual_diff_lab/
## vdl_shots.gd) at 1600x900 in a frozen, deterministic state, then either records the goldens or diffs every shot
## against its golden (per pixel, tolerance + ignore masks) and writes heatmaps, a scorecard and a history row.
## Windowed only (a headless run has no pixels). Normally launched by run_visual_diff_lab.ps1; alone:
##   & tools\godot_run.ps1 --path . --resolution 1600x900 --position 0,0 -s res://tools/visual_diff_lab/visual_diff_lab.gd `
##       --fixed-fps 60 --quit-after 30000 '--' --mode=check
## User args (after '--'):
##   --mode=check|golden   check (default) diffs against docs/visual/golden/; golden (re)writes the goldens
##   --shots=a,b           only these shot ids (default: all)          --tolerance=N  per-channel 0-255 (default 12)
##   --golden=DIR --out=DIR   folders (default docs/visual/golden, docs/visual/lab)
##   --commit=ID           written into the scorecard / history        --no-history  no history row
## Freezing: the tree is paused, Engine.time_scale = 0 (process deltas, tweens and the shader TIME stop) and the shader
## TIME is reset to ~0 through rendering/limits/time/time_rollover_secs, so water / fog / glow shaders render the same
## frame every run. Each shot is captured twice 12 frames apart: pixels that still differ are "unstable" and ignored.
## Exit code: 0 all PASS / WARN / goldens written, 1 a FAIL, 2 bad arguments / no window / level never ready.
## Test-script rules (CLAUDE.md): compiled before autoloads; game classes reached untyped.

const Diff := preload("res://tools/visual_diff_lab/vdl_diff.gd")
const Shots := preload("res://tools/visual_diff_lab/vdl_shots.gd")
const Report := preload("res://tools/visual_diff_lab/vdl_report.gd")

const SKIRMISH := "res://scenes/skirmish.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
const ROLLOVER_KEY := "rendering/limits/time/time_rollover_secs"
const SETTLE_FRAMES := 8
const RECAPTURE_FRAMES := 12
const WATCHDOG_S := 600.0

var args := {}
var mode := "check"
var tolerance := 12
var golden_dir := ""
var out_dir := ""
var commit := ""
var seed_value := 1
var main: Node = null
var captures := {}          ## shot id -> {"img": Image, "unstable": Image, "unstable_px": int}
var notes: Array[String] = []
var _rng_counter := 0
var _rollover := 3600.0
var _t0 := 0


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	_t0 = Time.get_ticks_msec()
	var wd := create_timer(WATCHDOG_S, true, false, true)
	wd.timeout.connect(func() -> void:
		print("VISUAL_DIFF_LAB ERROR: watchdog (%d s)" % int(WATCHDOG_S))
		quit(3))
	_parse_args()
	if DisplayServer.get_name() == "headless":
		print("VISUAL_DIFF_LAB ERROR: needs a window (run without --headless, --resolution 1600x900)")
		quit(2)
		return
	var shots := _selected_shots()
	if shots.is_empty():
		print("VISUAL_DIFF_LAB ERROR: no shot matches --shots=%s (known: %s)" % [args.get("shots", ""), ", ".join(Shots.ids())])
		quit(2)
		return
	_rollover = float(ProjectSettings.get_setting(ROLLOVER_KEY, 3600.0))
	seed(seed_value * 7919 + 17)
	node_added.connect(_on_node_added)
	await _setup_window()
	print("VISUAL_DIFF_LAB start mode=%s shots=%d tolerance=%d window=%s" % [mode, shots.size(), tolerance,
		str(DisplayServer.window_get_size())])
	var menu_shots := shots.filter(func(s: Dictionary) -> bool: return s["kind"] == "menu")
	var level_shots := shots.filter(func(s: Dictionary) -> bool: return s["kind"] != "menu")
	for s: Dictionary in menu_shots:
		await _run_menu(s)
	if not level_shots.is_empty():
		var ok: bool = await _run_skirmish(level_shots)
		if not ok:
			print("VISUAL_DIFF_LAB ERROR: the skirmish never became ready")
			quit(2)
			return
	var code := 0
	if mode == "golden":
		Report.write_goldens(self, shots)
	else:
		code = Report.check_and_report(self, shots)
	print("VISUAL_DIFF_LAB done in %.1f s" % ((Time.get_ticks_msec() - _t0) / 1000.0))
	Engine.time_scale = 1.0
	paused = false
	quit(code)


func _parse_args() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	mode = String(args.get("mode", "check"))
	if args.has("golden") and String(args["golden"]) == "1":   # bare --golden = golden mode
		mode = "golden"
		args.erase("golden")
	tolerance = clampi(String(args.get("tolerance", "12")).to_int(), 0, 255)
	golden_dir = String(args.get("golden", ProjectSettings.globalize_path("res://docs/visual/golden"))).replace("\\", "/")
	out_dir = String(args.get("out", ProjectSettings.globalize_path("res://docs/visual/lab"))).replace("\\", "/")
	commit = String(args.get("commit", ""))
	seed_value = String(args.get("seed", "1")).to_int()


func _selected_shots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var want: PackedStringArray = []
	if args.has("shots"):
		want = String(args["shots"]).split(",", false)
	for s: Dictionary in Shots.SHOTS:
		if want.is_empty() or want.has(String(s["id"])):
			out.append(s)
	return out


func _setup_window() -> void:
	for i in 3:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(Shots.WIDTH, Shots.HEIGHT))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		for f in 4:
			await process_frame
		if root.get_texture().get_size() == Vector2(Shots.WIDTH, Shots.HEIGHT):
			return
	notes.append("viewport is %s, not %dx%d" % [str(root.get_texture().get_size()), Shots.WIDTH, Shots.HEIGHT])


# ---------------------------------------------------------------- determinism

## Node RNGs are seeded from the node's path (auto "@Class@123" ids stripped), not from the order nodes arrive in:
## threaded loads (menu diorama, camps) add nodes in a different order each run. Seeded when the node enters the tree
## (before its _ready uses the rng) and again after _ready for rngs created there.
func _on_node_added(node: Node) -> void:
	if &"class_rng" in node or &"_rng" in node or &"rng" in node:
		_seed_node_rngs(node)
		node.ready.connect(_seed_node_rngs.bind(node), CONNECT_ONE_SHOT)


var _id_strip := RegEx.create_from_string("@[A-Za-z0-9_]*@\\d+")


func _seed_node_rngs(node: Node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var path := _id_strip.sub(String(node.get_path()), "@", true)
	for key: StringName in [&"class_rng", &"_rng", &"rng"]:
		if key in node:
			var r: Variant = node.get(key)
			if r is RandomNumberGenerator:
				_rng_counter += 1
				(r as RandomNumberGenerator).seed = hash([seed_value, path, String(key)])


func _freeze() -> void:
	paused = true
	Engine.time_scale = 0.0
	# Shader TIME = accumulated scaled frame time modulo the rollover: a tiny rollover for two frames puts it at ~0,
	# and time_scale 0 keeps it there.
	ProjectSettings.set_setting(ROLLOVER_KEY, 0.000001)
	for i in 3:
		await process_frame
	ProjectSettings.set_setting(ROLLOVER_KEY, _rollover)


func _unfreeze() -> void:
	ProjectSettings.set_setting(ROLLOVER_KEY, _rollover)
	Engine.time_scale = 1.0
	paused = false


func _capture() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


## Two captures RECAPTURE_FRAMES apart; the second is the shot, their difference the unstable mask.
func _shoot(shot: Dictionary) -> void:
	for i in SETTLE_FRAMES:
		await process_frame
	var a: Image = await _capture()
	for i in RECAPTURE_FRAMES:
		await process_frame
	var b: Image = await _capture()
	var um: Array = Diff.unstable_mask(a, b, tolerance)
	captures[String(shot["id"])] = {"img": b, "unstable": um[0] if int(um[1]) > 0 else null, "unstable_px": int(um[1])}
	print("  shot %s: %dx%d, %d unstable px" % [shot["id"], b.get_width(), b.get_height(), int(um[1])])


# ---------------------------------------------------------------- menu

func _run_menu(shot: Dictionary) -> void:
	_unfreeze()
	# Loaded at time_scale 0 (the diorama may stream its models in: whenever they appear, they start at t = 0), then
	# exactly MENU_RUN_FRAMES frames of game time so the intro tweens finish, then frozen.
	Engine.time_scale = 0.0
	var menu: Node = (load(MENU) as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	for i in Shots.MENU_SETTLE_FRAMES:
		await process_frame
	Engine.time_scale = 1.0
	for i in Shots.MENU_RUN_FRAMES:
		await process_frame
	warp_mouse_away()
	await _freeze()
	await _shoot(shot)
	_unfreeze()
	menu.queue_free()
	current_scene = null
	for i in 3:
		await process_frame


func warp_mouse_away() -> void:
	# The pointer parks in the bottom-right corner so no button shows a hover state.
	Input.warp_mouse(Vector2(Shots.WIDTH - 2, Shots.HEIGHT - 2))


# ---------------------------------------------------------------- skirmish

func _run_skirmish(shots: Array) -> bool:
	_unfreeze()
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	# Game time stays at 0 while the level loads (time_scale 0: every delta is 0), so idle animations, portraits,
	# the fog and the minimap are at the same "t = 0" state however long the navmesh bake takes. The bake itself is
	# threaded and starts the match without a timer. Fallback: real time if the match did not start in 900 frames.
	Engine.time_scale = 0.0
	root.add_child(main)
	current_scene = main
	var waited := 0
	while not bool(main.get(&"match_started")):
		await process_frame
		waited += 1
		if waited == 900 and Engine.time_scale == 0.0:
			Engine.time_scale = 1.0
			notes.append("the skirmish did not start with time frozen: loaded in real time (idle poses may differ run to run)")
		if waited > 12000:
			return false
	for i in 10:   # the navigation map syncs before the lineup snaps its spots
		await process_frame
	for group: StringName in [&"thieves_guild", &"camp_manager", &"epic_beasts", &"critter_herds"]:
		for n in get_nodes_in_group(group):
			var r: Variant = n.get(&"rng")
			if r is RandomNumberGenerator:
				(r as RandomNumberGenerator).seed = hash([seed_value, String(group)])
	var cam: Variant = main.get(&"camera_rig")
	if cam is Node:
		(cam as Node).set(&"edge_pan_enabled", false)
	warp_mouse_away()
	await _freeze()
	for s: Dictionary in shots:
		if s["kind"] == "map":
			_place_camera(_focus_of(s), float(s.get("zoom", 30.0)))
			var fog: Variant = main.get(&"fog")
			var fog_off: bool = not bool(s.get("fog", true)) and fog is Node and &"enabled" in fog
			if fog_off:
				(fog as Node).set(&"enabled", false)   # FogOfWar.set_enabled: overlay hidden, every unit shown
			await _shoot(s)
			if fog_off:
				(fog as Node).set(&"enabled", true)
	for s: Dictionary in shots:
		if s["kind"] == "lineup":
			await _lineup_shot(s)
	_unfreeze()
	return true


func _focus_of(shot: Dictionary) -> Vector3:
	var f: Variant = shot.get("focus", Vector3.ZERO)
	if f is Vector3:
		return f
	var s := String(f)
	if s.begins_with("keep:"):
		var team := s.trim_prefix("keep:").to_int()
		for b in get_nodes_in_group(&"buildings"):
			var sc := b.get_script() as Script
			if int(b.get(&"team")) == team and sc != null and sc.resource_path.contains("keep"):
				return (b as Node3D).global_position
		for b in get_nodes_in_group(&"buildings"):
			if int(b.get(&"team")) == team:
				return (b as Node3D).global_position
	return Vector3.ZERO


func _place_camera(at: Vector3, zoom: float) -> void:
	var cam: Variant = main.get(&"camera_rig")
	if not (cam is Node3D):
		notes.append("no camera_rig on the level")
		return
	(cam as Node3D).rotation = Vector3.ZERO
	(cam as Node).call(&"focus_on", at)
	(cam as Node).set(&"_zoom", zoom)          # lab only: the rig has no public zoom setter
	(cam as Node).set(&"_target_zoom", zoom)
	(cam as Node).call(&"_apply_zoom")         # its _process is paused


## Every unit type of the kingdom, sorted by id (workers included; caravans and timed summons not).
func _kingdom_types(kingdom: String) -> Array[String]:
	var names: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/units/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres"):
			names.append(fn.get_basename())
	names.sort()
	var out: Array[String] = []
	for id: String in names:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or String(t.get(&"faction")) != kingdom:
			continue
		if bool(t.get(&"is_caravan")) or float(t.get(&"lifetime")) > 0.0:
			continue
		out.append(id)
	return out


func _lineup_shot(shot: Dictionary) -> void:
	var kingdom := String(shot.get("kingdom", "fire"))
	var types := _kingdom_types(kingdom)
	var hidden: Array = []
	for u in get_nodes_in_group(&"units"):
		if u is Node3D and (u as Node3D).visible:
			(u as Node3D).visible = false
			hidden.append(u)
	var hud: Variant = main.get(&"hud")
	var hud_was := false
	if hud is CanvasLayer:
		hud_was = (hud as CanvasLayer).visible
		(hud as CanvasLayer).visible = false
	var made: Array = []
	var n := types.size()
	for i in n:
		var u: Node = main.call(&"make_unit", types[i])
		if u == null:
			notes.append("%s: make_unit(%s) returned null" % [shot["id"], types[i]])
			continue
		u.set(&"team", 0)
		main.add_child(u)
		var x := (float(i) - float(n - 1) * 0.5) * Shots.LINEUP_SPACING
		var p: Vector3 = Shots.LINEUP_CENTER + Vector3(x, 0.0, 0.0)
		(u as Node3D).global_position = p
		(u as Node3D).rotation = Vector3.ZERO   # unit models face +Z: toward the camera
		if u.has_method(&"command_stop"):
			u.call(&"command_stop")
		made.append(u)
	var zoom := clampf(float(n) * Shots.LINEUP_SPACING * 0.95, 14.0, 40.0)
	_place_camera(Shots.LINEUP_CENTER + Vector3(0.0, 0.0, -0.8), zoom)
	await _shoot(shot)
	captures[String(shot["id"])]["units"] = ", ".join(types)
	for u2: Node in made:
		if is_instance_valid(u2):
			u2.queue_free()
	for i in 2:
		await process_frame
	for h: Node in hidden:
		if is_instance_valid(h):
			(h as Node3D).visible = true
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = hud_was
