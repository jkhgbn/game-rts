extends SceneTree
## G-F crown isle variants shots (docs/art/gf_crown_isle.md). WINDOWED only; pass the tier:
##   tools\godot_run.ps1 --path . -s res://art/environment/crown_variants/ci_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --map=thornwater --tag=thornwater_after
##   ... --before          (CrownIsleLook.disabled: the isle as it was)
## JPGs (1600x900) in docs/art/lab/gf_crown_isle/<tag>/ (the folder has a .gdignore): isle_z24 (game camera, HUD on),
## isle_z36 (game camera), isle_low (oblique from the south-west), pedestal (close).

const OUT := "res://docs/art/lab/gf_crown_isle"
const LOOK := "res://art/environment/crown_variants/crown_isle_look.gd"

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
	await _run_map(StringName(String(args.get("map", "thornwater"))))
	print("CI SHOTS DONE ", tag)
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


## A free camera looking at `at` from `dist` metres, `pitch_deg` down, `yaw_deg` round (0 = from +z).
func _orbit(at: Vector3, dist: float, pitch_deg: float, yaw_deg: float, fov: float = 50.0) -> void:
	if _ov_cam == null:
		_ov_cam = Camera3D.new()
		_ov_cam.far = 3000.0
		main.add_child(_ov_cam)
	_ov_cam.fov = fov
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	var off := Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * dist
	_ov_cam.global_position = at + off
	_ov_cam.look_at(at, Vector3.UP)
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
	var hud: Variant = main.get(&"hud") if &"hud" in main else null
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = on


func _fog(on: bool) -> void:
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", on)


func _run_map(map_id: StringName) -> void:
	var cat := MapCatalog.load_default()
	main = cat.instantiate_level(map_id)
	if &"player_kingdom" in main:
		main.set(&"player_kingdom", &"fire")
		main.set(&"enemy_kingdom", &"shadow")
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 300000:
			print("CI ERROR: map never started ", map_id)
			return
	await _wait(2.0)
	_close_picker()
	var crown := Vector3.ZERO
	var cr: Variant = main.get(&"crown")
	if cr is Node3D:
		crown = (cr as Node3D).global_position
	crown.y = 0.0
	_fog(false)
	_hud(true)
	_cam(crown + Vector3(0, 0, 2), 24.0)
	await _wait(0.9)
	await _shot("isle_z24")
	_hud(false)
	_cam(crown, 36.0)
	await _wait(0.7)
	await _shot("isle_z36")
	_orbit(crown, 26.0, 34.0, -40.0)
	await _wait(0.6)
	await _shot("isle_low")
	_orbit(crown + Vector3(0, 1.2, 0), 10.5, 24.0, 20.0)
	await _wait(0.6)
	await _shot("pedestal")
