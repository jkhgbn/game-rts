extends SceneTree
## G-F round 3 sites shots (docs/art/gf_r3_sites.md). WINDOWED only; pass the tier.
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_r3_sites/tools/sites_shots.gd --resolution 1920x1080 --quit-after 200000 '--' --gfx=high --pk=fire --ek=shadow --tag=after
## Per team: a Hall site and a house site at 0 / 30 / 70 % in a row; one z24 overview of the row + a z12 close-up of
## each Hall stage. JPGs in docs/art/lab/gf_r3_sites/<tag>/ (the folder has a .gdignore).

const OUT := "res://docs/art/lab/gf_r3_sites"
const SKIRMISH := "res://scenes/skirmish.tscn"
const HOUSES := {"fire": "fire_hearth", "ice": "ice_lodge", "nature": "nature_hollow", "shadow": "shadow_hovel"}
const STAGES := [0.0, 0.3, 0.7]

var args := {}
var tag := "x"
var main: Node


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
	await _run()
	print("SITES SHOTS DONE ", tag)
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
	img.save_jpg(ProjectSettings.globalize_path("%s/%s/%s.jpg" % [OUT, tag, name]), 0.92)
	print("shot ", name)


func _cam(at: Vector3, zoom: float) -> void:
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


func _run() -> void:
	var pk := String(args.get("pk", "fire"))
	var ek := String(args.get("ek", "shadow"))
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", StringName(pk))
	main.set(&"enemy_kingdom", StringName(ek))
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 300000:
			print("SITES ERROR: skirmish never started")
			return
	await _wait(1.0)
	var hero: Variant = main.get(&"hero")
	if hero is Node:
		var sp := StrIntPath.of(hero as Node)
		if sp and not sp.is_locked():
			sp.choose(sp.default_pick())
	for n in root.find_children("*", "", true, false):
		if n is StrIntPanel:
			n.set(&"visible", false)
	var hud: Variant = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", false)
	var bg: BuildGrid = main.get(&"build_grid")
	var kingdoms := {0: pk, 1: ek}
	var rows := {}
	for team: int in [0, 1]:
		var keep_pos: Vector3 = main.call(&"base_center", team)
		var kp: Variant = main.call(&"keep_of", team)
		if kp is Node3D:
			keep_pos = (kp as Node3D).global_position
		var d := Vector3(-keep_pos.x, 0.0, -keep_pos.z).normalized()
		var pp := Vector3(-d.z, 0.0, d.x)
		var hall_t := BuildingType.find("%s_barracks" % kingdoms[team])
		var house_t := BuildingType.find(HOUSES[kingdoms[team]])
		var halls: Array = []
		for i: int in STAGES.size():
			var want := keep_pos + d * 30.0 + pp * (float(i) - 1.0) * 11.0
			var h := bg.spawn_site(hall_t, bg.find_spot(hall_t, want, team), team)
			var s := bg.spawn_site(house_t, bg.find_spot(house_t, want + d * 9.0, team), team)
			halls.append(h)
			for b: Building in [h, s]:
				if b:
					_set_progress(b, STAGES[i])
		rows[team] = {"halls": halls, "center": keep_pos + d * 34.0}
	await _wait(1.5)
	for team: int in [0, 1]:
		var kname := String(kingdoms[team])
		_cam(rows[team]["center"], 24.0)
		await _wait(0.7)
		await _shot("row_%s_z24" % kname)
		for i: int in STAGES.size():
			var h: Variant = rows[team]["halls"][i]
			if h is Node3D:
				_cam((h as Node3D).global_position, 12.0)
				await _wait(0.6)
				await _shot("hall%02d_%s_z12" % [int(STAGES[i] * 100.0), kname])


func _set_progress(b: Building, p: float) -> void:
	b.set(&"_progress", p)
	if b.has_method(&"_update_look"):
		b.call(&"_update_look")
