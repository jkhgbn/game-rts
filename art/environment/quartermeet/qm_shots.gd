extends SceneTree
## G-F Quartermeet identity shots (docs/art/gf_quartermeet.md). WINDOWED only; pass the tier:
##   tools\godot_run.ps1 --path . -s res://art/environment/quartermeet/qm_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --map=quartermeet --tag=after
##   ... '--' --gfx=high --map=quartermeet --tag=before --before      (QuartermeetLook.disabled: the map as it was)
##   ... '--' --gfx=high --map=ashwind_reach --tag=ashwind              (Wave Strike: must look as before)
## JPGs (1600x900) in docs/art/lab/gf_quartermeet/<tag>/ (the folder has a .gdignore): ingame_z32, overview,
## centre_z35, ford_z30, field_z36, edge_z40 (Ashwind: the same names at its own lane spots).

const OUT := "res://docs/art/lab/gf_quartermeet"
const LOOK := "res://art/environment/quartermeet/quartermeet_look.gd"

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
		DisplayServer.window_set_size(Vector2i(1600, 900))
		for f in 4:
			await process_frame
	if args.has("before") and ResourceLoader.exists(LOOK):
		(load(LOOK) as Script).set(&"disabled", true)
	await _run_map(StringName(String(args.get("map", "quartermeet"))))
	print("QM SHOTS DONE ", tag)
	quit(0)


func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	Input.warp_mouse(Vector2(800, 450))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_jpg(ProjectSettings.globalize_path("%s/%s/%s.jpg" % [OUT, tag, name]), 0.92)
	print("shot ", name, " fps=", Engine.get_frames_per_second())


func _cam(at: Vector3, zoom: float) -> void:
	if _ov_cam:
		_ov_cam.queue_free()
		_ov_cam = null
	var c := main.get(&"camera_rig") as Node3D
	if c == null:
		return
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
	for key: StringName in [&"hud", &"ws_hud"]:
		var hud: Variant = main.get(key) if key in main else null
		if hud is CanvasLayer:
			(hud as CanvasLayer).visible = on


func _fog(on: bool) -> void:
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", on)


## Skirmish levels: match_started; Wave Strike: its director and camera exist.
func _started() -> bool:
	if &"match_started" in main:
		return bool(main.get(&"match_started"))
	return main.get(&"director") != null and main.get(&"camera_rig") != null


func _run_map(map_id: StringName) -> void:
	var cat := MapCatalog.load_default()
	main = cat.instantiate_level(map_id)
	if &"player_kingdom" in main:
		main.set(&"player_kingdom", &"fire")
		main.set(&"enemy_kingdom", &"shadow")
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not _started():
		await process_frame
		if Time.get_ticks_msec() - t0 > 300000:
			print("QM ERROR: map never started ", map_id)
			return
	await _wait(2.0)
	_close_picker()
	_hud(true)
	var ws := map_id == &"ashwind_reach"
	var home := Vector3(-110.0, 0.0, 0.0) if ws else Vector3(-71.6, 0.0, 32.4)
	var kp: Variant = main.call(&"keep_of", 0) if main.has_method(&"keep_of") else null
	if kp is Node3D:
		home = (kp as Node3D).global_position
	_cam(home + Vector3(0, 0, -6), 32.0)
	await _wait(0.8)
	await _shot("ingame_z32")
	_hud(false)
	_fog(false)
	await _wait(0.5)
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.05, 62.0)
	await _wait(0.8)
	await _shot("overview")
	var views: Array = [
		["centre_z35", Vector3.ZERO, 35.0],
		["ford_z30", Vector3(-6.0, 0.0, 34.9), 30.0],
		["field_z36", Vector3(-46.0, 0.0, 44.0), 36.0],
		["edge_z40", Vector3(-80.0, 0.0, -10.0), 40.0],
	]
	if ws:
		views = [
			["centre_z35", Vector3.ZERO, 35.0],
			["ford_z30", Vector3(-50.0, 0.0, 0.0), 30.0],
			["field_z36", Vector3(-70.0, 0.0, 26.0), 36.0],
			["edge_z40", Vector3(50.0, 0.0, -30.0), 40.0],
		]
	for v: Array in views:
		_cam(v[1], v[2])
		await _wait(0.7)
		await _shot(v[0])
