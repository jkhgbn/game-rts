extends SceneTree
## G-F review 2 item 9 shots (docs/art/gf_thornwater.md). WINDOWED only; pass the tier:
##   tools\godot_run.ps1 --path . -s res://art/environment/thornwater/tw_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --map=thornwater --tag=after
##   ... '--' --gfx=high --map=thornwater --tag=before --before        (ThornwaterLook.disabled: the look as it was)
##   ... '--' --gfx=high --map=crown_hollow --tag=crown
## JPGs (1600x900) in docs/art/lab/gf_thornwater/<tag>/ (the folder has a .gdignore): overview, centre_z35 (crown isle),
## river_z30 (the south-west ford reach), edge_z40 (the west border), ingame_z32.

const OUT := "res://docs/art/lab/gf_thornwater"
const LOOK := "res://art/environment/thornwater/thornwater_look.gd"

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
	if args.has("before"):
		(load(LOOK) as Script).set(&"disabled", true)
	await _run_map(StringName(String(args.get("map", "thornwater"))))
	print("TW SHOTS DONE ", tag)
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
	var hud: Variant = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = on


func _fog(on: bool) -> void:
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", on)


func _run_map(map_id: StringName) -> void:
	var cat := MapCatalog.load_default()
	main = cat.instantiate_level(map_id)
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 300000:
			print("TW ERROR: map never started ", map_id)
			return
	await _wait(2.0)
	_close_picker()
	_hud(true)
	var kp: Variant = main.call(&"keep_of", 0) if main.has_method(&"keep_of") else null
	if kp is Node3D:
		_cam((kp as Node3D).global_position + Vector3(0, 0, -6), 32.0)
		await _wait(0.6)
		await _shot("ingame_z32")
	_hud(false)
	_fog(false)
	await _wait(0.5)
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.05, 62.0)
	await _wait(0.8)
	await _shot("overview")
	_cam(Vector3.ZERO, 35.0)
	await _wait(0.6)
	await _shot("centre_z35")
	# The south-west river reach with its ford (Thornwater ford_a, Crown Hollow's ford at (-8.5, -34)).
	var river_at := Vector3(-13.0, 0.0, -36.0) if map_id == &"thornwater" else Vector3(-9.0, 0.0, -32.0)
	_cam(river_at, 30.0)
	await _wait(0.6)
	await _shot("river_z30")
	_cam(Vector3(-46.0, 0.0, 6.0), 40.0)
	await _wait(0.6)
	await _shot("edge_z40")
