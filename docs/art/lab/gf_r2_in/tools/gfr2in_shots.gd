extends SceneTree
## G-F round 2, Ice / Nature buildings (docs/art/gf_r2_buildings_in.md): items 6 (Ice Hall roof) and 7 (white motes).
## Trimmed copy of docs/art/lab/gf_review2/tools/gf2_shots.gd (bases only, buildings, extra z18 / house shots). WINDOWED.
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_r2_in/tools/gfr2in_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --tag=before
## Debug: --inspect (print the Ice Hall's emitters), --hide=<emitter name> [--hidein=hall] (find what draws a blob).
## JPGs in docs/art/lab/gf_r2_in/<tag>/ (the folder has a .gdignore).

const OUT := "res://docs/art/lab/gf_r2_in"
const SKIRMISH := "res://scenes/skirmish.tscn"
const HOUSES := {"fire": "fire_hearth", "ice": "ice_lodge", "nature": "nature_hollow", "shadow": "shadow_hovel"}
const BAD := ["Outside the map", "Not on walkable ground", "Blocked", "Too close to a crystal node", "Can't build on water",
		"Too close to a crossing", "Too close to a monster camp", "Can't build that"]

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
	await _run_bases()
	print("GFR2IN SHOTS DONE ", tag)
	quit(0)


# ---------------------------------------------------------------- helpers

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


## A free camera high over the map (overviews beyond the RTS zoom range).
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


func _wait_level(max_s: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if float(Time.get_ticks_msec() - t0) / 1000.0 > max_s:
			return false
	return true


func _kingdom_types(kingdom: String) -> Array[String]:
	var names: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/units/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres"):
			names.append(fn.get_basename())
	names.sort()
	var workers: Array[String] = []
	var rest: Array[String] = []
	for id: String in names:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or String(t.get(&"faction")) != kingdom:
			continue
		if bool(t.get(&"is_caravan")) or float(t.get(&"lifetime")) > 0.0:
			continue
		if bool(t.get(&"is_worker")):
			workers.append(id)
		else:
			rest.append(id)
	return workers + rest


func _unit(id: String, team: int, pos: Vector3, face: float) -> Unit:
	var u := Worker.make_unit(UnitType.find(id))
	if u == null:
		return null
	u.team = team as Unit.Team
	main.add_child(u)
	if u.has_method(&"set_down"):
		u.set_down(pos)
	else:
		u.global_position = pos
	u.command_stop()
	u.rotation.y = face
	return u


func _place_building(id: String, team: int, want: Vector3) -> Building:
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
			main.add_child(b)
			b.global_position = c
			return b
	print("no spot for ", id, " near ", want)
	return null


# ---------------------------------------------------------------- bases

func _run_bases() -> void:
	var pk := String(args.get("pk", "ice"))
	var ek := String(args.get("ek", "nature"))
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", StringName(pk))
	main.set(&"enemy_kingdom", StringName(ek))
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	for team in [0, 1]:
		var eco := Economy.for_team(team)
		if eco:
			eco.add(100000)
	var kingdoms := {0: pk, 1: ek}
	var info := {}
	for team: int in [0, 1]:
		info[team] = _build_base(team, String(kingdoms[team]))
	await _wait(4.0)
	if args.has("inspect") and info[0]["hall"] != null:   # debug: the hall's emitters as drawn
		for n: Node in (info[0]["hall"] as Node).find_children("*", "GPUParticles3D", true, false):
			var gp := n as GPUParticles3D
			var ppm := gp.process_material as ParticleProcessMaterial
			print("EMIT ", gp.name, " gscale=", gp.global_transform.basis.get_scale(), " scale=", ppm.scale_min, "-",
				ppm.scale_max, " pass=", gp.draw_pass_1, " size=", gp.draw_pass_1.get(&"size"), " vis=", gp.is_visible_in_tree(),
				" emit=", gp.emitting)
	if args.has("hide"):   # debug: hide every emitter with this name (find what draws a blob)
		var scope: Node = root
		if args.has("hidein") and info[0]["hall"] != null:
			scope = info[0]["hall"]
		for n: Node in scope.find_children(String(args["hide"]), "GPUParticles3D", true, false):
			print("hide ", n.get_path())
			(n as GPUParticles3D).visible = false
	var k0: Vector3 = info[0]["keep"]
	var d0: Vector3 = info[0]["dir"]
	_hud(true)
	_cam(k0 + d0 * 6.0, 32.0)
	await _wait(0.6)
	await _shot("ingame_%s_z32" % pk)
	_hud(false)
	_fog(false)
	await _wait(0.5)
	for team: int in [0, 1]:
		var kname := "%s_%s" % [kingdoms[team], "p" if team == 0 else "e"]
		var k: Vector3 = info[team]["keep"]
		var d: Vector3 = info[team]["dir"]
		_cam(k + d * 7.0, 30.0)
		await _wait(0.6)
		await _shot("base_%s_z30" % kname)
		_cam(k, 10.0)
		await _wait(0.5)
		await _shot("keep_%s_z10" % kname)
		_cam(k, 18.0)
		await _wait(0.5)
		await _shot("keep_%s_z18" % kname)
		if info[team]["hall"] != null:
			var hp := (info[team]["hall"] as Node3D).global_position
			_cam(hp, 10.0)
			await _wait(0.5)
			await _shot("hall_%s_z10" % kname)
			_cam(hp, 18.0)
			await _wait(0.5)
			await _shot("hall_%s_z18" % kname)
		if info[team]["house"] != null:
			_cam((info[team]["house"] as Node3D).global_position, 12.0)
			await _wait(0.5)
			await _shot("house_%s_z12" % kname)


## Keep + Hall + 3 houses + 2 towers + Stables + Forge (no army: buildings only).
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
	return {"keep": keep_pos, "dir": d, "hall": hall, "house": house}
