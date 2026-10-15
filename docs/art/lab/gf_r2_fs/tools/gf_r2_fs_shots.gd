extends SceneTree
## G-F round-2 Fire / Shadow building fixes (docs/art/gf_r2_buildings_fs.md): before / after shots. WINDOWED only.
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_r2_fs/tools/gf_r2_fs_shots.gd --resolution 1600x900 --quit-after 300000 '--' --gfx=high --mode=fs --tag=after
##   ... '--' --gfx=high --mode=mirror --tag=after      (Shadow vs Shadow: player / enemy Dusk Keep)
## Helpers copied from docs/art/lab/gf_review2/tools/gf2_shots.gd. JPGs in docs/art/lab/gf_r2_fs/<tag>/.

const OUT := "res://docs/art/lab/gf_r2_fs"
const SKIRMISH := "res://scenes/skirmish.tscn"
const CRUCIBLE := "res://art/buildings/fire/ember_crucible/ember_crucible.tscn"
const HOUSES := {"fire": "fire_hearth", "ice": "ice_lodge", "nature": "nature_hollow", "shadow": "shadow_hovel"}
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
	var mode := String(args.get("mode", "fs"))
	if mode == "fs":
		await _run_fs()
	elif mode == "mirror":
		await _run_mirror()
	print("GF R2 FS SHOTS DONE ", tag)
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
				b.set_physics_process(false)   # no worker (the enemy bot's) advances a shot site
			return b
	print("no spot for ", id, " near ", want)
	return null


## Keep + Hall + 3 houses + 2 towers + Stables + Forge (no army: the buildings are the subject).
func _build_base(team: int, kingdom: String) -> Dictionary:
	var keep_pos: Vector3 = main.call(&"base_center", team)
	var kp: Variant = main.call(&"keep_of", team)
	if kp is Node3D:
		keep_pos = (kp as Node3D).global_position
	var d := Vector3(-keep_pos.x, 0.0, -keep_pos.z).normalized()
	var p := Vector3(-d.z, 0.0, d.x)
	var at := func(f: float, s: float) -> Vector3: return keep_pos + d * f + p * s
	var hall := _place_building("%s_barracks" % kingdom, team, at.call(6.0, 12.0))
	var house: Building = null
	for o: Vector2 in [Vector2(-6.0, 11.0), Vector2(-10.0, 4.0), Vector2(-10.0, -4.0)]:
		var h := _place_building(String(HOUSES[kingdom]), team, at.call(o.x, o.y))
		if house == null:
			house = h
	_place_building("%s_tower" % kingdom, team, at.call(15.0, -6.0))
	_place_building("%s_tower" % kingdom, team, at.call(13.0, 14.0))
	_place_building("%s_stables" % kingdom, team, at.call(4.0, -12.0))
	_place_building("%s_forge" % kingdom, team, at.call(-5.0, -12.0))
	return {"keep": keep_pos, "dir": d, "side": p, "hall": hall, "house": house}


func _run_fs() -> void:
	if not await _start("fire", "shadow"):
		return
	var info := {}
	for team: int in [0, 1]:
		info[team] = _build_base(team, "fire" if team == 0 else "shadow")
	# Shadow construction sites (Gloom Hall at 0 / 0.04 / 0.35, a Hovel at 0) on open ground near the enemy base.
	var ek: Vector3 = info[1]["keep"]
	var ed: Vector3 = info[1]["dir"]
	var es: Vector3 = info[1]["side"]
	var sites: Array[Building] = []
	var prog := [0.0, 0.04, 0.35]
	for i in prog.size():
		var b := _place_building("shadow_barracks", 1, ek + ed * 26.0 + es * (-10.0 + 10.0 * float(i)), true)
		if b:
			sites.append(b)
	var hs := _place_building("shadow_hovel", 1, ek + ed * 33.0 + es * 6.0, true)
	# A lit Ember Crucible next to the player's keep (the Roost's annex, standalone).
	var k0: Vector3 = info[0]["keep"]
	var d0: Vector3 = info[0]["dir"]
	var crucible := (load(CRUCIBLE) as PackedScene).instantiate() as Node3D
	main.add_child(crucible)
	crucible.global_position = k0 + d0 * 18.0 + (info[0]["side"] as Vector3) * -8.0
	crucible.call(&"set_crucible", true, true)
	await _wait(4.0)
	for i in sites.size():
		var m: Node3D = sites[i].model()
		if m and m.has_method(&"set_construction_progress"):
			m.call(&"set_construction_progress", prog[i])
	await _wait(1.0)
	# In-game view: fog + HUD on, the player's Fire base at the default zoom.
	_hud(true)
	_cam(k0 + d0 * 6.0, 32.0)
	await _wait(0.8)
	await _shot("ingame_fire_z32")
	_hud(false)
	_fog(false)
	await _wait(0.5)
	_cam(k0 + d0 * 7.0, 30.0)
	await _wait(0.6)
	await _shot("base_fire_p_z30")
	_cam(k0, 14.0)
	await _wait(0.5)
	await _shot("keep_fire_p_z14")
	_cam(crucible.global_position, 8.0)
	await _wait(0.5)
	await _shot("crucible_z8")
	_cam(ek + ed * 7.0, 30.0)
	await _wait(0.6)
	await _shot("base_shadow_e_z30")
	_cam(ek, 14.0)
	await _wait(0.5)
	await _shot("keep_shadow_e_z14")
	if info[1]["hall"] != null:
		_cam((info[1]["hall"] as Node3D).global_position, 10.0)
		await _wait(0.5)
		await _shot("hall_shadow_e_z10")
	if info[1]["house"] != null:
		_cam((info[1]["house"] as Node3D).global_position, 8.0)
		await _wait(0.5)
		await _shot("hovel_shadow_e_z8")
	if sites.size() > 0:
		_cam(sites[sites.size() / 2].global_position, 22.0)
		await _wait(0.5)
		await _shot("sites_shadow_z22")
		for i in sites.size():
			var m: Node3D = sites[i].model()
			if m and m.has_method(&"set_construction_progress"):
				m.call(&"set_construction_progress", prog[i])   # again: the Building may have re-sent its own 0
			_cam(sites[i].global_position, 12.0)
			await _wait(0.5)
			await _shot("site_hall_p%03d_z12" % int(round(float(prog[i]) * 100.0)))
	if hs:
		_cam(hs.global_position, 10.0)
		await _wait(0.5)
		await _shot("site_hovel_z10")


func _run_mirror() -> void:
	if not await _start("shadow", "shadow"):
		return
	var info := {}
	for team: int in [0, 1]:
		info[team] = _build_base(team, "shadow")
	await _wait(4.0)
	_hud(false)
	_fog(false)
	for team: int in [0, 1]:
		var k: Vector3 = info[team]["keep"]
		var d: Vector3 = info[team]["dir"]
		var nm := "p" if team == 0 else "e"
		_cam(k + d * 7.0, 30.0)
		await _wait(0.6)
		await _shot("base_shadow_%s_z30" % nm)
		_cam(k, 14.0)
		await _wait(0.5)
		await _shot("keep_shadow_%s_z14" % nm)
