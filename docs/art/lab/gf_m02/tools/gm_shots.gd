extends SceneTree
## G-F review 2 item 11 shots (docs/art/gf_m02.md): mission 2 frozen Emberguard blocks, Sentinel shells, the thaw
## shatter and the snow border. WINDOWED only; pass the tier.
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_m02/tools/gm_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --tag=after
##   ... '--' --gfx=high --tag=before --undress   (removes this task's art after the start: the old boxes, no cliffs;
##       the ground's snow canopy shader change cannot be undone, so the before border is only "no cliffs")
## The Sentinel shells are dressed here with FrozenBlockArt.dress_shell (stands in for the mission_02 hook requested in
## docs/handoff/for-lead.md); the blocks are already dressed by the mission's FrozenLook.dress_level call.
## JPGs (1600x900) in docs/art/lab/gf_m02/<tag>/ (the folder has a .gdignore).

const OUT := "res://docs/art/lab/gf_m02"
const MISSION := "res://missions/mission_02.tscn"

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
	await _run()
	print("GM SHOTS DONE ", tag)
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


func _cam(at: Vector3, zoom: float, yaw: float = 0.0) -> void:
	if _ov_cam:
		_ov_cam.queue_free()
		_ov_cam = null
	var cam: Variant = main.get(&"camera_rig")
	if not (cam is Node3D):
		return
	var c := cam as Node3D
	c.set(&"edge_pan_enabled", false)
	c.rotation = Vector3(0.0, yaw, 0.0)
	c.call(&"focus_on", at)
	c.set(&"_zoom", zoom)
	c.set(&"_target_zoom", zoom)
	c.call(&"_apply_zoom")
	var cam3 := c.get(&"camera") as Camera3D
	if cam3:
		cam3.make_current()


func _free_cam(eye: Vector3, look: Vector3) -> void:
	if _ov_cam == null:
		_ov_cam = Camera3D.new()
		_ov_cam.fov = 50.0
		_ov_cam.far = 3000.0
		main.add_child(_ov_cam)
	_ov_cam.global_position = eye
	_ov_cam.look_at(look, Vector3.UP)
	_ov_cam.make_current()


func _overview(center: Vector3, dist: float, pitch_deg: float) -> void:
	var p := deg_to_rad(pitch_deg)
	_free_cam(center + Vector3(0.0, sin(p) * dist, cos(p) * dist), center)


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


## Before: this task's art taken off again (old box / capsules / stump back, no cliffs).
func _undress() -> void:
	var sb := main.get_node_or_null(^"SnowBorder")
	if sb:
		sb.free()
	for b: Node in main.get(&"blocks"):
		for n: String in ["IceBlock/IceArt", "RimeMound", "IceStump"]:
			var x := b.get_node_or_null(NodePath(n))
			if x:
				x.free()
		for c: Node in b.get_node(^"IceBlock").get_children():
			(c as Node3D).visible = true
		var st := b.get_node_or_null(^"Stump") as Node3D
		if st:
			st.visible = true


func _dress_shells() -> void:
	for s: Node in main.find_children("IceShell", "MeshInstance3D", true, false):
		FrozenBlockArt.dress_shell(s as MeshInstance3D)


func _run() -> void:
	main = (load(MISSION) as PackedScene).instantiate()
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
			print("GM ERROR: mission never started")
			return
	if args.has("undress"):
		_undress()
	else:
		_dress_shells()
	await _wait(2.0)
	_close_picker()
	_hud(false)
	_fog(false)
	var blocks: Array = main.get(&"blocks")
	var west := (blocks[0] as Node3D).global_position
	var south := (blocks[1] as Node3D).global_position
	var north := (blocks[2] as Node3D).global_position
	# Blocks close and at play zoom.
	_cam(west, 12.0)
	await _wait(0.8)
	await _shot("block_west_z12")
	_free_cam(west + Vector3(3.2, 2.6, 4.6), west + Vector3(0.0, 1.0, 0.0))
	await _wait(0.5)
	await _shot("block_west_close")
	_cam(south, 24.0)
	await _wait(0.8)
	await _shot("block_south_z24")
	_cam(north, 30.0)
	await _wait(0.8)
	await _shot("block_north_z30")
	# Sentinel shells.
	var sents: Array = main.get(&"sentinels")
	if not sents.is_empty():
		_cam((sents[0] as Node3D).global_position, 16.0)
		await _wait(0.8)
		await _shot("sentinels_z16")
	# The border: overview, the north cliff at play zoom, the west edge at max zoom.
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.0, 62.0)
	await _wait(1.0)
	await _shot("m02_overview")
	_cam(Vector3(0.0, 0.0, -50.0), 30.0)
	await _wait(0.8)
	await _shot("border_north_z30")
	_cam(Vector3(-48.0, 0.0, 10.0), 55.0)
	await _wait(0.8)
	await _shot("border_west_z55")
	_cam(Vector3(30.0, 0.0, 50.0), 40.0)
	await _wait(0.8)
	await _shot("border_south_z40")
	# Thaw (after only): shatter in flight, then the teeth left on the mound.
	if not args.has("undress"):
		_cam(south, 12.0)
		await _wait(0.6)
		(blocks[1] as Node).call(&"light")
		await _wait(0.22)
		await _shot("thaw_south_burst")
		await _wait(2.3)
		await _shot("thaw_south_after")
