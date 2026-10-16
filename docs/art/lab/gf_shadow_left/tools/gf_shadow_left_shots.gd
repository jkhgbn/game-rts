extends SceneTree
## G-F Shadow leftovers (docs/art/gf_shadow_leftovers.md): Night Spire slate crown + calm site outline. WINDOWED only.
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_shadow_left/tools/gf_shadow_left_shots.gd --resolution 1600x900 --quit-after 300000 '--' --gfx=high --tag=after
## `--legacy_outline` puts the old outline back at run time (energy 2, 1 Hz pulse, full glow, old bar width) for
## the "before" shots. Helpers copied from docs/art/lab/gf_r2_fs/tools/gf_r2_fs_shots.gd. JPGs in <OUT>/<tag>/.

const OUT := "res://docs/art/lab/gf_shadow_left"
const SKIRMISH := "res://scenes/skirmish.tscn"
const BAD := ["Outside the map", "Not on walkable ground", "Blocked", "Too close to a crystal node", "Can't build on water",
		"Too close to a crossing", "Too close to a monster camp", "Can't build that"]

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
		DisplayServer.window_set_size(Vector2i(1600, 900))
		for f in 4:
			await process_frame
	await _run()
	print("GF SHADOW LEFT SHOTS DONE ", tag)
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


func _start(pk: String, ek: String) -> bool:
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
			print("GF ERROR: skirmish never started")
			return false
	await _wait(1.0)
	_close_picker()
	for team in [0, 1]:
		var eco := Economy.for_team(team)
		if eco:
			eco.add(100000)
	return true


func _place_building(id: String, team: int, want: Vector3, site: bool = false) -> Building:
	var t := BuildingType.find(id)
	if t == null:
		print("no building ", id)
		return null
	var bg: BuildGrid = main.get(&"build_grid")
	for r in [0.0, 2.0, 4.0, 6.0, 8.0, 10.0]:
		var steps := 1 if r == 0.0 else 12
		for k in steps:
			var a := TAU * float(k) / float(steps)
			var p := want + Vector3(cos(a) * r, 0.0, sin(a) * r)
			var c := bg.snap(p, t.footprint) if bg else p
			var why := bg.check(t, c, team) if bg else ""
			if why in BAD:
				continue
			var b := BuildGrid.create_building(t)
			b.team = team as Unit.Team
			if site:
				b.make_site()
			main.add_child(b)
			b.global_position = c
			if site:
				b.set_physics_process(false)   # no worker advances a shot site
			return b
	print("no spot for ", id, " near ", want)
	return null


## Keep + Hall + Hovel + 2 towers (the buildings are the subject).
func _build_base(team: int) -> Dictionary:
	var keep_pos: Vector3 = main.call(&"base_center", team)
	var kp: Variant = main.call(&"keep_of", team)
	if kp is Node3D:
		keep_pos = (kp as Node3D).global_position
	var d := Vector3(-keep_pos.x, 0.0, -keep_pos.z).normalized()
	var p := Vector3(-d.z, 0.0, d.x)
	var at := func(f: float, s: float) -> Vector3: return keep_pos + d * f + p * s
	_place_building("shadow_barracks", team, at.call(6.0, 12.0))
	_place_building("shadow_hovel", team, at.call(-6.0, 11.0))
	var t1 := _place_building("shadow_tower", team, at.call(15.0, -6.0))
	_place_building("shadow_tower", team, at.call(13.0, 14.0))
	return {"keep": keep_pos, "dir": d, "side": p, "tower": t1}


## The old outline (before this task): energy 2, 1 Hz pulse, full team glow, bars 0.2 / 0.25 m wide.
func _legacy_outline(m: Node) -> void:
	if not args.has("legacy_outline") or not (&"outline_calm" in m):
		return
	m.set(&"outline_calm", false)
	var mat: Variant = m.get(&"_outline_mat")
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter(&"pulse_speed", TAU)
	var ol: Variant = m.get(&"_outline")
	if ol is MultiMeshInstance3D:
		var mm := (ol as MultiMeshInstance3D).multimesh
		var old := mm.mesh as BoxMesh
		if old:
			var nb := BoxMesh.new()
			nb.size = Vector3(old.size.x, old.size.y, 0.25 if old.size.x > 7.0 else 0.2)
			if old.size.x <= 7.0:
				nb.size.x = old.size.x - old.size.z + 0.2
			mm.mesh = nb
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", m.get(&"_team_color"))


func _set_prog(b: Building, p: float) -> void:
	var m: Node3D = b.model()
	if m == null:
		return
	_legacy_outline(m)
	if m.has_method(&"set_construction_progress"):
		m.call(&"set_construction_progress", p)


func _run() -> void:
	if not await _start("shadow", "shadow"):
		return
	var info := {}
	for team: int in [0, 1]:
		info[team] = _build_base(team)
	var ek: Vector3 = info[0]["keep"]
	var ed: Vector3 = info[0]["dir"]
	var es: Vector3 = info[0]["side"]
	# Shadow construction sites (the player's, kingdom violet) near the player base: a Gloom Hall at 0 and 0.35, a Hovel at 0, Night Spires at 0 / 0.5.
	var sites: Array = []   # [Building, progress, shot name]
	var h0 := _place_building("shadow_barracks", 0, ek + ed * 26.0 + es * -8.0, true)
	if h0:
		sites.append([h0, 0.0, "site_hall_p000_z18", 18.0])
	var h1 := _place_building("shadow_barracks", 0, ek + ed * 26.0 + es * 2.0, true)
	if h1:
		sites.append([h1, 0.35, "site_hall_p035_z18", 18.0])
	var hv := _place_building("shadow_hovel", 0, ek + ed * 33.0 + es * 8.0, true)
	if hv:
		sites.append([hv, 0.0, "site_hovel_p000_z14", 14.0])
	var s0 := _place_building("shadow_tower", 0, ek + ed * 33.0 + es * -4.0, true)
	if s0:
		sites.append([s0, 0.0, "site_tower_p000_z12", 12.0])
	var s1 := _place_building("shadow_tower", 0, ek + ed * 33.0 + es * 0.5, true)
	if s1:
		sites.append([s1, 0.5, "site_tower_p050_z12", 12.0])
	await _wait(4.0)
	for s: Array in sites:
		_set_prog(s[0] as Building, float(s[1]))
	await _wait(1.0)
	_hud(false)
	_fog(false)
	for team: int in ([] if args.has("only_sites") else [0, 1]):
		var nm := "p" if team == 0 else "e"
		var tw: Variant = info[team]["tower"]
		if tw is Node3D:
			var tp: Vector3 = (tw as Node3D).global_position
			_cam(tp + Vector3(0, 3.5, 0), 6.0)
			await _wait(0.5)
			await _shot("tower_%s_z6" % nm)
			_cam(tp, 12.0)
			await _wait(0.5)
			await _shot("tower_%s_z12" % nm)
	_cam(ek + ed * 7.0, 30.0)
	await _wait(0.6)
	await _shot("base_shadow_p_z30")
	if sites.size() > 0:
		_cam((sites[0][0] as Node3D).global_position.lerp(ek + ed * 30.0, 0.6), 24.0)
		await _wait(0.5)
		await _shot("sites_shadow_z24")
	for s: Array in sites:
		_set_prog(s[0] as Building, float(s[1]))   # again: the Building may have re-sent its own 0
		_cam((s[0] as Node3D).global_position, float(s[3]))
		await _wait(0.5)
		await _shot(String(s[2]))
