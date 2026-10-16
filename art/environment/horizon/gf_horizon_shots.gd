extends SceneTree
## G-F per-map horizon shots (docs/art/gf_horizon.md). WINDOWED only; pass the tier:
##   tools\godot_run.ps1 --path . -s res://art/environment/horizon/gf_horizon_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --map=thornwater --tag=after
## --map = a MapCatalog id (crown_hollow, thornwater, quartermeet, ...). JPGs (1600x900) in
## docs/art/lab/gf_horizon/<tag>/<map>_<shot>.jpg (the folder has a .gdignore): overview (high oblique, the whole ring),
## east_z55 (the east edge: Crown Hollow's pond glade), west_z55 (the west edge: the aqueduct line), ne_z55 (the
## north-east corner: the watchtower knoll), ingame_z40 (the player's keep side).

const OUT := "res://docs/art/lab/gf_horizon"

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
	await _run_map(StringName(String(args.get("map", "crown_hollow"))))
	print("HZ SHOTS DONE ", tag)
	quit(0)


func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(map_id: StringName, name: String) -> void:
	Input.warp_mouse(Vector2(800, 450))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_jpg(ProjectSettings.globalize_path("%s/%s/%s_%s.jpg" % [OUT, tag, map_id, name]), 0.92)
	print("shot ", map_id, " ", name, " fps=", Engine.get_frames_per_second())


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


func _free_cam(at: Vector3, look: Vector3) -> void:
	if _ov_cam == null:
		_ov_cam = Camera3D.new()
		_ov_cam.fov = 50.0
		_ov_cam.far = 3000.0
		main.add_child(_ov_cam)
	_ov_cam.global_position = at
	_ov_cam.look_at(look, Vector3.UP)
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
			print("HZ ERROR: map never started ", map_id)
			return
	await _wait(2.0)
	_close_picker()
	var hz: Node = main.get_node_or_null(^"Horizon")
	print("map %s %s x %s horizon variant %s" % [map_id, MapInfo.size_x, MapInfo.size_z,
		str(hz.get(&"variant")) if hz != null and &"variant" in hz else "(none)"])
	_hud(false)
	_fog(false)
	var hx := MapInfo.half_x()
	var hz2 := MapInfo.half_z()
	var hm := MapInfo.half_max()
	await _wait(0.5)
	_free_cam(Vector3(0.0, hm * 2.5, hm * 2.9), Vector3(0.0, 0.0, -hm * 0.15))
	await _wait(0.8)
	await _shot(map_id, "overview")
	_cam(Vector3(hx - 12.0, 0.0, -32.0 * hz2 / 60.0), 55.0)
	await _wait(0.8)
	await _shot(map_id, "east_z55")
	_cam(Vector3(-(hx - 12.0), 0.0, -26.0 * hz2 / 60.0), 55.0)
	await _wait(0.8)
	await _shot(map_id, "west_z55")
	_cam(Vector3(hx - 14.0, 0.0, -(hz2 - 14.0)), 55.0)
	await _wait(0.8)
	await _shot(map_id, "ne_z55")
	_hud(true)
	var kp: Variant = main.call(&"keep_of", 0) if main.has_method(&"keep_of") else null
	if kp is Node3D:
		_cam((kp as Node3D).global_position + Vector3(0, 0, 4), 40.0)
		await _wait(0.6)
		await _shot(map_id, "ingame_z40")
