extends SceneTree
## G-E fixes B shots (docs/art/ge_fixes_b.md): night mission, Ice mission snow, depth fog on map overviews.
## WINDOWED only; pass the tier. Same views as the G-E review tool (docs/art/lab/ge_review/tools/ge_shots.gd).
##   tools\godot_run.ps1 --path . -s docs/art/lab/ge_fixes_b/tools/gb_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --mode=mission --mission=res://missions/mission_00.tscn --name=m00_night --tag=after
##   ... '--' --gfx=high --mode=mission --mission=res://missions/mission_02.tscn --name=m02_ice --tag=after [--dress]
##   ... '--' --gfx=high --mode=map --map=crown_hollow --tag=after
## --dress: calls FrozenLook.dress_level(level) when the mission has not (stands in for the mission_02 hook requested in
## docs/handoff/for-systems-coder.md). JPGs (1600x900) in docs/art/lab/ge_fixes_b/<tag>/ (the folder has a .gdignore).

const OUT := "res://docs/art/lab/ge_fixes_b"
const FROZEN_LOOK := "res://art/environment/snow/frozen_look.gd"

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
	var mode := String(args.get("mode", "mission"))
	if mode == "map":
		await _run_map(StringName(String(args.get("map", "crown_hollow"))))
	else:
		await _run_mission(String(args.get("mission", "")), String(args.get("name", "mission")))
	print("GB SHOTS DONE ", tag)
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
			print("GB ERROR: map never started ", map_id)
			return
	await _wait(2.0)
	_close_picker()
	_hud(false)
	_fog(false)
	var kp: Variant = main.call(&"keep_of", 0) if main.has_method(&"keep_of") else null
	var k := (kp as Node3D).global_position if kp is Node3D else Vector3.ZERO
	await _wait(0.5)
	_cam(k * 0.6, 55.0)
	await _wait(0.6)
	await _shot("%s_z55" % map_id)
	_cam(k * 0.5, 40.0)
	await _wait(0.6)
	await _shot("%s_mid_z40" % map_id)
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.05, 62.0)
	await _wait(0.8)
	await _shot("%s_overview" % map_id)


func _run_mission(path: String, name: String) -> void:
	main = (load(path) as PackedScene).instantiate()
	main.set(&"show_briefing", false)
	main.set(&"save_campaign_on_victory", false)
	main.set(&"cinematics_enabled", false)
	root.add_child(main)
	current_scene = main
	var t := 0
	while not (main.get(&"hero") != null and bool(main.get(&"match_started"))):
		await process_frame
		t += 1
		if t > 20000:
			print("GB ERROR: mission never started ", path)
			return
	if args.has("dress") and ResourceLoader.exists(FROZEN_LOOK):
		var fl := load(FROZEN_LOOK) as Script
		print("dress_level: ", fl.call(&"dress_level", main))
	await _wait(3.0)
	var hero := main.get(&"hero") as Node3D
	_hud(true)
	_cam(hero.global_position, 30.0)
	await _wait(0.6)
	await _shot("%s_ingame_z30" % name)
	_hud(false)
	_cam(hero.global_position, 14.0)
	await _wait(0.6)
	await _shot("%s_hero_z14" % name)
	_fog(false)
	_cam(hero.global_position + Vector3(0, 0, -12), 45.0)
	await _wait(0.6)
	await _shot("%s_nofog_z45" % name)
	if args.has("lake"):
		_cam(Vector3(-14.0, 0.0, 6.0), 30.0)
		await _wait(0.6)
		await _shot("%s_lake_z30" % name)
		_cam(Vector3(-20.0, 0.0, 14.0), 14.0)
		await _wait(0.6)
		await _shot("%s_bank_z14" % name)
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.0, 62.0)
	await _wait(0.8)
	await _shot("%s_overview" % name)
