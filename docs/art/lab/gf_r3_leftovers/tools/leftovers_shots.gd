extends SceneTree
## G-F round 3 leftovers shots (docs/art/gf_r3_leftovers.md). WINDOWED only; pass the tier.
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_r3_leftovers/tools/leftovers_shots.gd --resolution 1920x1080 --quit-after 200000 '--' --gfx=high --tag=after
## Fire vs Fire skirmish; by the player's keep: an Ember Hall built, Ember Hall sites at 0 / 30 / 50 %.
## Shots (JPG, docs/art/lab/gf_r3_leftovers/<tag>/): chimney close-up of the built hall (z10), the sites at z12, and a
## z9 close-up of the 0 % site edge (grass vs the pad). ~300 frames after every camera move.

const OUT := "res://docs/art/lab/gf_r3_leftovers"
const SKIRMISH := "res://scenes/skirmish.tscn"
const STAGES := [1.0, 0.0, 0.3, 0.5]

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
	print("LEFTOVERS SHOTS DONE ", tag)
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	Input.warp_mouse(Vector2(960, 540))
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
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"fire")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 300000:
			print("LEFTOVERS ERROR: skirmish never started")
			return
	await _frames(60)
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
	var keep_pos: Vector3 = main.call(&"base_center", 0)
	var kp: Variant = main.call(&"keep_of", 0)
	if kp is Node3D:
		keep_pos = (kp as Node3D).global_position
	var d := Vector3(-keep_pos.x, 0.0, -keep_pos.z).normalized()
	var pp := Vector3(-d.z, 0.0, d.x)
	var hall_t := BuildingType.find("fire_barracks")
	var halls: Array = []
	for i: int in STAGES.size():
		var want := keep_pos + d * 26.0 + pp * (float(i) - 1.5) * 11.0
		var h := bg.spawn_site(hall_t, bg.find_spot(hall_t, want, 0), 0)
		halls.append(h)
		if h:
			_set_progress(h, STAGES[i])
	await _frames(120)
	var names := ["hall_built", "hall00", "hall30", "hall50"]
	for i: int in STAGES.size():
		var h: Variant = halls[i]
		if not (h is Node3D):
			continue
		var p := (h as Node3D).global_position
		if i == 0:
			var at := p
			var mdl: Variant = (h as Node).call(&"model")
			if mdl is Node3D:
				var ch := (mdl as Node3D).find_child("Chimney", true, false) as Node3D
				if ch:
					at = ch.global_position
			_cam(Vector3(at.x, 0.0, at.z - 4.0), 20.0)
			await _frames(300)
			await _shot("chimney_built_z20")
		_cam(p, 12.0)
		await _frames(300)
		await _shot("%s_z12" % names[i])
		if i == 1:
			_cam(p + Vector3(3.0, 0.0, -3.0), 8.0)
			await _frames(300)
			await _shot("hall00_edge_z8")


func _set_progress(b: Building, p: float) -> void:
	b.set(&"_progress", p)
	# HP follows the build like the real site (else a hall set straight to 1.0 keeps its site HP and shows the
	# < 25 % damage: crown hidden, roof holes).
	b.hp = b.max_hp * lerpf(0.1, 1.0, p)
	var mdl: Variant = b.call(&"model")
	if mdl is Node and (mdl as Node).has_method(&"set_health_ratio"):
		(mdl as Node).call(&"set_health_ratio", b.hp / maxf(b.max_hp, 1.0))
	if b.has_method(&"_update_look"):
		b.call(&"_update_look")
