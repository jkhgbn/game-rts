extends SceneTree
## G-F review 3 item 5 shots (docs/art/gf_r3_autumn.md; trimmed copy of gf_review3/tools/gf3_shots.gd _run_map).
## WINDOWED only:
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_r3_autumn/tools/r3_autumn_shots.gd --resolution 1920x1080
##       --quit-after 20000 '--' --gfx=high --map=ashwind_reach --tag=before
## PNGs in docs/art/lab/gf_r3_autumn/<tag>/<map>_<shot>.png (overview with fog of war off, centre z45 with the HUD).

const OUT := "res://docs/art/lab/gf_r3_autumn"
const WS_SCENE := "res://scenes/wave_strike.tscn"

var args := {}
var tag := "x"
var main: Node
var _ov_cam: Camera3D


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	tag = String(args.get("tag", "x"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [OUT, tag]))
	for i in 3:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		for f in 4:
			await process_frame
	await _run_map(StringName(String(args.get("map", "ashwind_reach"))))
	print("R3 AUTUMN SHOTS DONE ", tag)
	quit(0)


func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	Input.warp_mouse(Vector2(960, 540))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(ProjectSettings.globalize_path("%s/%s/%s.png" % [OUT, tag, name]))
	print("shot ", name)


func _cam(at: Vector3, zoom: float) -> void:
	if _ov_cam:
		_ov_cam.queue_free()
		_ov_cam = null
	var cam: Variant = main.get(&"camera_rig")
	if not (cam is Node3D):
		return
	var c := cam as Node3D
	c.set(&"edge_pan_enabled", false)
	c.rotation = Vector3.ZERO
	c.call(&"focus_on", at)
	c.set(&"_zoom", zoom)
	c.set(&"_target_zoom", zoom)
	c.call(&"_apply_zoom")
	var cam3 := c.get(&"camera") as Camera3D
	if cam3:
		cam3.make_current()


func _overview(center: Vector3, dist: float, pitch_deg: float) -> void:
	if _ov_cam == null:
		_ov_cam = Camera3D.new()
		_ov_cam.fov = 50.0
		_ov_cam.far = 3000.0
		main.add_child(_ov_cam)
	var p := deg_to_rad(pitch_deg)
	_ov_cam.global_position = center + Vector3(0.0, sin(p) * dist, cos(p) * dist)
	_ov_cam.rotation = Vector3(-p, 0.0, 0.0)
	_ov_cam.make_current()


func _close_picker() -> void:
	var hero: Variant = main.get(&"hero")
	if hero is Node:
		var sp := StrIntPath.of(hero as Node)
		if sp and not sp.is_locked():
			sp.choose(sp.default_pick())
	for n in root.find_children("*", "", true, false):
		if n is StrIntPanel:
			n.set(&"visible", false)


func _hud(on: bool) -> void:
	var hud: Variant = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = on


func _fog(on: bool) -> void:
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", on)


func _wait_level(max_s: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if float(Time.get_ticks_msec() - t0) / 1000.0 > max_s:
			return false
	return true


func _run_map(map_id: StringName) -> void:
	var cat := MapCatalog.load_default()
	var e := cat.entry(map_id)
	var ws := String(e.get("mode", "")) == "wave_strike"
	if ws:
		main = (load(WS_SCENE) as PackedScene).instantiate()
		if &"autopilot_player" in main:
			main.set(&"autopilot_player", true)
	else:
		main = cat.instantiate_level(map_id)
		main.set(&"player_kingdom", &"fire")
		main.set(&"enemy_kingdom", &"shadow")
	root.add_child(main)
	current_scene = main
	if ws:
		await _wait(20.0)
	elif not await _wait_level(300.0):
		print("R3 ERROR: map never started ", map_id)
		return
	await _wait(2.0)
	_close_picker()
	var env := _env()
	if env:
		print("env fog density %.3f aerial %.3f colour %s" % [env.fog_density, env.fog_aerial_perspective, env.fog_light_color])
	_hud(true)
	_cam(Vector3.ZERO, 45.0)
	await _wait(0.8)
	await _shot("%s_centre_z45" % map_id)
	_hud(false)
	_fog(false)
	await _wait(0.5)
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.05, 62.0)
	await _wait(0.8)
	await _shot("%s_overview" % map_id)


func _env() -> Environment:
	for n in root.find_children("*", "WorldEnvironment", true, false):
		return (n as WorldEnvironment).environment
	return null
