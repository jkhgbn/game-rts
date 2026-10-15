extends SceneTree
## G-E fixes C shots (docs/art/ge_fixes_c.md). WINDOWED only; pass the tier.
##   tools\godot_run.ps1 --path . -s docs/art/lab/ge_fixes_c/tools/gec_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --mode=m03 --tag=after
##   modes: m03 (Sighing Wood), ashwind (Wave Strike lane), crown (Crown Hollow centre + tavern), all
##   "Before" = the G-E review shots (docs/art/lab/ge_review/high_missions, high_maps).
## JPGs (1600x900) in docs/art/lab/ge_fixes_c/<tag>/ (the folder has a .gdignore).

const OUT := "res://docs/art/lab/ge_fixes_c"
const M03 := "res://missions/mission_03.tscn"
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
		DisplayServer.window_set_size(Vector2i(1600, 900))
		for f in 4:
			await process_frame
	var mode := String(args.get("mode", "all"))
	if mode == "m03" or mode == "all":
		await _run_m03()
		await _free_main()
	if mode == "ashwind" or mode == "all":
		await _run_ashwind()
		await _free_main()
	if mode == "crown" or mode == "all":
		await _run_crown()
		await _free_main()
	print("GEC SHOTS DONE ", tag)
	quit(0)


func _free_main() -> void:
	if main:
		main.queue_free()
		main = null
		_ov_cam = null
		for i in 6:
			await process_frame


func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	Input.warp_mouse(Vector2(800, 450))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var p := ProjectSettings.globalize_path("%s/%s/%s.jpg" % [OUT, tag, name])
	img.save_jpg(p, 0.92)
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


func _hud(on: bool) -> void:
	var hud: Variant = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = on
	var ws := main.get_node_or_null(^"WaveStrikeHud")
	if ws:
		for c in ws.find_children("*", "CanvasLayer", true, false):
			(c as CanvasLayer).visible = on
		if ws is CanvasLayer:
			(ws as CanvasLayer).visible = on


func _fog(on: bool) -> void:
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", on)




# ---------------------------------------------------------------- m03

func _run_m03() -> void:
	main = (load(M03) as PackedScene).instantiate()
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
			print("GEC ERROR: m03 never started")
			return
	await _wait(3.0)
	var hero := main.get(&"hero") as Node3D
	_hud(true)
	_cam(hero.global_position, 30.0)
	await _wait(0.8)
	await _shot("m03_ingame_z30")
	_hud(false)
	_fog(false)
	await _wait(0.6)
	_cam(Vector3(0, 0, 4), 24.0)
	await _wait(0.8)
	await _shot("m03_oldroot_z24")
	_cam(Vector3(0, 0, 2), 14.0)
	await _wait(0.6)
	await _shot("m03_oldroot_z14")
	_cam(Vector3(-30, 0, -34), 16.0)
	await _wait(0.6)
	await _shot("m03_gate_z16")
	_cam(Vector3(-14, 0, 14), 40.0)
	await _wait(0.8)
	await _shot("m03_wood_z40")
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.0, 62.0)
	await _wait(0.8)
	await _shot("m03_overview")


# ---------------------------------------------------------------- Ashwind Reach

func _run_ashwind() -> void:
	main = (load(WS_SCENE) as PackedScene).instantiate()
	if &"autopilot_player" in main:
		main.set(&"autopilot_player", true)
	root.add_child(main)
	current_scene = main
	await _wait(6.0)
	_hud(false)
	_fog(false)
	await _wait(0.5)
	_cam(Vector3.ZERO, 45.0)
	await _wait(0.8)
	await _shot("ashwind_centre_z45")
	_cam(Vector3(-40, 0, 2), 32.0)
	await _wait(0.6)
	await _shot("ashwind_lane_z32")
	_cam(Vector3(30, 0, -6), 40.0)
	await _wait(0.6)
	await _shot("ashwind_east_z40")
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.05, 62.0)
	await _wait(0.8)
	await _shot("ashwind_overview")


# ---------------------------------------------------------------- Crown Hollow centre (taverns)

func _run_crown() -> void:
	var cat := MapCatalog.load_default()
	main = cat.instantiate_level(&"crown_hollow")
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 300000:
			print("GEC ERROR: crown never started")
			return
	await _wait(2.0)
	var hero: Variant = main.get(&"hero")
	if hero is Node:
		var sp := StrIntPath.of(hero as Node)
		if sp and not sp.is_locked():
			sp.choose(sp.default_pick())
	for n in root.find_children("*", "", true, false):
		if n is StrIntPanel:
			n.set(&"visible", false)
	_hud(false)
	_fog(false)
	await _wait(0.5)
	_cam(Vector3.ZERO, 45.0)
	await _wait(0.8)
	await _shot("crown_centre_z45")
	_cam(Vector3(-15, 0, -13), 20.0)
	await _wait(0.6)
	await _shot("crown_tavern_z20")
