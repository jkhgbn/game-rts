extends SceneTree
## Task G1 screenshots + fps per graphics tier (docs/art/lighting.md "Quality tiers", docs/art/lab/g1_lighting/).
## Loads the real skirmish map, bot off, fog off, HUD hidden, stages the centre fight (as light_preview.gd), applies
## each tier through GameSettings.apply_graphics (viewport AA / LOD + every LightingRig), saves
## docs/art/lab/g1_lighting/<tag>_q<q>_<shot>.png, then measures the frame times over a fresh centre fight.
## Every tier runs in the same process and the perf rounds are interleaved (0 1 2 3 0 1 2 3), so a busy PC (other
## Godot runs) skews all tiers alike; the summary keeps each tier's best round.
## Windowed only (headless has no renderer):
##   tools\godot_run.ps1 --path . -s res://art/environment/lighting/g1_preview.gd --resolution 1920x1080
##       --quit-after 60000 -- tiers=0,1,2,3 tag=warm [rounds=2] [player=ice] [rig=ice] [only=fight_z30]
##       [perf=0] [shots=0] [frames=900] [env:ssao_intensity=2.0] [sun:light_angular_distance=2.0]

const OUT_DIR := "res://docs/art/lab/g1_lighting"
const SHOTS: Array = [
	# [name, zoom, focus]
	["fight_z10", 10.0, Vector3(0.0, 0.0, 3.0)],
	["fight_z30", 30.0, Vector3(0.0, 0.0, 3.0)],
	["fight_z50", 50.0, Vector3(0.0, 0.0, 3.0)],
	["base_z30", 30.0, Vector3(-40.0, 0.0, 41.0)],
]

var main: Node
var _tag := "warm"
var _tiers: Array[int] = [0, 1, 2, 3]
var _rounds := 2
var _staged: Array = []
var _results := {}               ## tier -> Array of [avg_fps, low1_fps]
var _rig_id := ""
var _player := ""
var _only := ""
var _perf := true
var _shots := true
var _frames := 900
var _overrides: Array = []
var _rig_only := false          ## rigonly=1: tiers on the LightingRig only (viewport AA / LOD stay Low)
var _rig: LightingRig
var _cam: Node3D


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var k := arg.get_slice("=", 0)
		var v := arg.substr(k.length() + 1)
		match k:
			"tag": _tag = v
			"q", "tiers":
				_tiers.clear()
				for t: String in v.split(","):
					_tiers.append(int(t))
			"rounds": _rounds = int(v)
			"rig": _rig_id = v
			"player": _player = v
			"only": _only = v
			"perf": _perf = v != "0"
			"shots": _shots = v != "0"
			"frames": _frames = int(v)
			"rigonly": _rig_only = v != "0"
			_:
				if arg.begins_with("env:") or arg.begins_with("sun:"):
					_overrides.append(arg)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	if _player != "":
		main.set(&"player_kingdom", StringName(_player))
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	_rig = main.get_node_or_null(^"LightingRig") as LightingRig
	if _rig and _rig_id == "night":
		EmberfallNight.apply_to(main, EmberfallNight.night())
	elif _rig and _rig_id != "":
		_rig.apply(LightingRig.load_preset(StringName(_rig_id)))
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_cam = main.get(&"camera_rig")
	_cam.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	print("G1 tag=%s size=%s tiers=%s" % [_tag, str(root.get_visible_rect().size), str(_tiers)])
	if _shots:
		for q in _tiers:
			_set_tier(q)
			_restage(false)   # idle armies: the same picture in every tier
			for s: Array in SHOTS:
				if _only != "" and not _only.split(",").has(s[0]):
					continue
				_frame_cam(s[1], s[2])
				for i in 45:
					await process_frame
				await RenderingServer.frame_post_draw
				var img: Image = root.get_texture().get_image()
				var path := "%s/%s_q%d_%s.png" % [OUT_DIR, _tag, q, s[0]]
				img.save_png(ProjectSettings.globalize_path(path))
				print("saved %s" % path)
	if _perf:
		for r in _rounds:
			for q in _tiers:
				_set_tier(q)
				await _measure(q)
		for q in _tiers:
			var best: Array = [0.0, 0.0, 0.0, 0.0]
			for res: Array in _results.get(q, []):
				if float(res[0]) > float(best[0]):
					best = res
			print("G1 BEST q=%d tag=%s avg_fps=%.1f low1_fps=%.1f gpu_ms_med=%.2f gpu_ms_p99=%.2f" % [q, _tag, best[0], best[1],
					best[2], best[3]])
	print("G1 DONE")
	quit()


func _set_tier(q: int) -> void:
	if _rig_only:   # lighting cost alone: the viewport stays on Low (project AA / LOD)
		GameSettings.apply_graphics(self, 0)
		_rig.set_quality(q)
	else:
		GameSettings.apply_graphics(self, q)
	_apply_overrides()


func _frame_cam(zoom: float, focus: Vector3) -> void:
	paused = false   # the skirmish start (STR / INT pick) pauses the tree: the fight and the camera must run
	_cam.call(&"fly_to", focus, 0.0, zoom, 0.0)


## Frame times over a fresh centre fight at zoom 30 (avg fps, 1 % low = 1 / 99th percentile frame time).
func _measure(q: int) -> void:
	_frame_cam(30.0, Vector3(0.0, 0.0, 3.0))
	_restage()
	for i in 90:
		await process_frame
	var times: Array[float] = []
	var gpu: Array[float] = []
	var vp_rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var last := Time.get_ticks_usec()
	for i in _frames:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - last))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp_rid))
		last = now
	gpu.sort()
	var gpu_med := gpu[gpu.size() / 2]
	var gpu_p99 := gpu[maxi(int(gpu.size() * 0.99) - 1, 0)]
	var total := 0.0
	for t in times:
		total += t
	times.sort()
	var p99 := times[maxi(int(times.size() * 0.99) - 1, 0)]
	var avg_fps := 1e6 * times.size() / total
	var low1 := 1e6 / p99
	if not _results.has(q):
		_results[q] = []
	(_results[q] as Array).append([avg_fps, low1, gpu_med, gpu_p99])
	print("G1 PERF q=%d tag=%s avg_fps=%.1f low1_fps=%.1f gpu_ms_med=%.2f gpu_ms_p99=%.2f frames=%d draws=%d vram_mb=%.0f" % [
			q, _tag, avg_fps, low1, gpu_med, gpu_p99, times.size(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])


func _apply_overrides() -> void:
	for o: String in _overrides:
		var head := o.get_slice(":", 0)
		var kv := o.substr(head.length() + 1)
		var key := kv.get_slice("=", 0)
		var value: Variant = str_to_var(kv.substr(key.length() + 1))
		var target: Object = null
		if head == "env" and _rig:
			target = _rig.world_environment.environment
		elif head == "sun" and _rig:
			target = _rig.sun
		if target:
			target.set(key, value)


## Frees the last staged fight and stages a new one (same 16 units every time).
func _restage(fight := true) -> void:
	for u: Variant in _staged:
		if is_instance_valid(u):
			(u as Node).queue_free()
	_staged.clear()
	_stage_fight(fight)


## Two small armies meet in the centre (as light_preview.gd).
func _stage_fight(fight: bool) -> void:
	var p_ids: Array = ["flame_guard", "flame_guard", "flame_guard", "flame_guard", "ember_archer",
			"ember_archer", "ember_archer", "blaze_rider"]
	var e_ids: Array = ["shade", "shade", "shade", "shade", "shadow_knight", "nightbolt", "nightbolt",
			"grave_hound"]
	if _player == "ice":
		p_ids = ["rimeshield", "rimeshield", "rimeshield", "shardcaster", "shardcaster", "rime_seer",
				"rime_colossus", "shardcaster"]
	var gap := 0.0 if fight else 5.0   # idle armies out of each other's aggro range
	var mine: Array = []
	var theirs: Array = []
	for i in p_ids.size():
		var u: Node3D = main.call(&"make_unit", p_ids[i])
		if u == null:
			continue
		u.set(&"team", 0)
		main.add_child(u)
		u.global_position = Vector3(-7.0 + (i % 4) * 1.6, 0.0, 9.0 + gap + (i / 4) * 1.8)
		mine.append(u)
	for i in e_ids.size():
		var u: Node3D = main.call(&"make_unit", e_ids[i])
		if u == null:
			continue
		u.set(&"team", 1)
		main.add_child(u)
		u.global_position = Vector3(3.0 + (i % 4) * 1.6, 0.0, -3.0 - gap - (i / 4) * 1.8)
		theirs.append(u)
	if fight:
		for u: Node in mine:
			u.call(&"command_attack_move", Vector3(4.0, 0.0, -2.0))
		for u: Node in theirs:
			u.call(&"command_attack_move", Vector3(-4.0, 0.0, 8.0))
	_staged.append_array(mine)
	_staged.append_array(theirs)
