extends SceneTree
## G-F billboard keep-scale pass (docs/art/gf_billboard.md): before / after shots of the building and unit emitters
## whose particles drew at the quad size. Based on docs/art/lab/gf_r2_in/tools/gfr2in_shots.gd. WINDOWED.
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_billboard/tools/gfbb_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --tag=before [--pk=fire --ek=shadow]
## Per kingdom: base z30, keep z12 idle, keep z18 damaged (smoke / flames), hall z12 idle, hall z18 damaged, forge z12,
## a hall site z14 (build dust / ring), a house z12 damaged, a unit line z12.
## JPGs in docs/art/lab/gf_billboard/<tag>/ (the folder has a .gdignore).

const OUT := "res://docs/art/lab/gf_billboard"
const SKIRMISH := "res://scenes/skirmish.tscn"
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
	await _run_bases()
	print("GFBB SHOTS DONE ", tag)
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
	var rest: Array[String] = []
	for id: String in names:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or String(t.get(&"faction")) != kingdom:
			continue
		if bool(t.get(&"is_caravan")) or float(t.get(&"lifetime")) > 0.0:
			continue
		rest.append(id)
	return rest


func _unit(id: String, team: int, pos: Vector3, face: float) -> Unit:
	var u := Worker.make_unit(UnitType.find(id))
	if u == null:
		return null
	u.team = team as Unit.Team
	main.add_child(u)
	u.set_down(pos)
	u.command_stop()
	u.rotation.y = face
	return u


func _place_building(id: String, team: int, want: Vector3) -> Building:
	var t := BuildingType.find(id)
	if t == null:
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


func _model(b: Node) -> Node:
	if b == null:
		return null
	var m: Variant = b.get(&"_model")
	return m as Node if m is Node else null


func _model_call(b: Node, method: StringName, a: Array) -> void:
	var m := _model(b)
	if m and m.has_method(method):
		m.callv(method, a)


func _run_bases() -> void:
	var pk := String(args.get("pk", "fire"))
	var ek := String(args.get("ek", "shadow"))
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", StringName(pk))
	main.set(&"enemy_kingdom", StringName(ek))
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GFBB ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	var kingdoms := {0: pk, 1: ek}
	var info := {}
	for team: int in [0, 1]:
		info[team] = _build_base(team, String(kingdoms[team]))
	await _wait(4.0)
	_hud(false)
	_fog(false)
	for team: int in [0, 1]:
		var kname := String(kingdoms[team])
		var I: Dictionary = info[team]
		var k: Vector3 = I["keep"]
		var d: Vector3 = I["dir"]
		_cam(k + d * 7.0, 30.0)
		await _wait(0.8)
		await _shot("%s_base_z30" % kname)
		_cam(k, 12.0)
		await _wait(0.6)
		await _shot("%s_keep_z12" % kname)
		if I["hall"] != null:
			var hp := (I["hall"] as Node3D).global_position
			_cam(hp, 12.0)
			await _wait(0.6)
			await _shot("%s_hall_z12" % kname)
		if I["forge"] != null:
			_cam((I["forge"] as Node3D).global_position, 12.0)
			await _wait(0.6)
			await _shot("%s_forge_z12" % kname)
		if I["site"] != null:
			_cam((I["site"] as Node3D).global_position, 14.0)
			await _wait(0.6)
			await _shot("%s_site_z14" % kname)
			_cam((I["site"] as Node3D).global_position, 30.0)
			await _wait(0.6)
			await _shot("%s_site_z30" % kname)
			_cam((I["site"] as Node3D).global_position, 14.0)
			await _wait(0.3)
			_model_call(I["site"], &"set_construction_progress", [1.0])   # completion settle: dust + glints
			await _wait(0.35)
			await _shot("%s_settle_z14" % kname)
		_cam(I["line"], 12.0)
		await _wait(0.6)
		await _shot("%s_units_z12" % kname)
		# damaged: keep, hall, house (smoke + flames)
		for key: String in ["keep_b", "hall", "house"]:
			var bb := I[key] as Building
			if bb:
				bb.take_damage(bb.max_hp * 0.8, null)
		await _wait(2.5)
		_cam(k, 18.0)
		await _wait(0.3)
		await _shot("%s_keep_dmg_z18" % kname)
		_cam(k + d * 7.0, 30.0)
		await _wait(0.4)
		await _shot("%s_base_dmg_z30" % kname)
		if I["hall"] != null:
			_cam((I["hall"] as Node3D).global_position, 18.0)
			await _wait(0.3)
			await _shot("%s_hall_dmg_z18" % kname)
		if I["house"] != null:
			_cam((I["house"] as Node3D).global_position, 12.0)
			await _wait(0.3)
			await _shot("%s_house_dmg_z12" % kname)


## Keep + Hall + house + Forge + a Hall site + a unit line.
func _build_base(team: int, kingdom: String) -> Dictionary:
	var keep_pos: Vector3 = main.call(&"base_center", team)
	var kp: Variant = main.call(&"keep_of", team)
	var keep_b: Node = null
	if kp is Node3D:
		keep_pos = (kp as Node3D).global_position
		keep_b = kp
	var d := Vector3(-keep_pos.x, 0.0, -keep_pos.z).normalized()
	var p := Vector3(-d.z, 0.0, d.x)
	var at := func(f: float, s: float) -> Vector3: return keep_pos + d * f + p * s
	var hall := _place_building("%s_barracks" % kingdom, team, at.call(6.0, 12.0))
	var house := _place_building(String(HOUSES[kingdom]), team, at.call(-6.0, 11.0))
	var forge := _place_building("%s_forge" % kingdom, team, at.call(-5.0, -12.0))
	var site := _place_building("%s_barracks" % kingdom, team, at.call(4.0, -14.0))
	if site:
		_model_call(site, &"set_construction_progress", [0.4])
	var line: Vector3 = at.call(12.0, 0.0)
	var ids := _kingdom_types(kingdom)
	for i: int in mini(ids.size(), 9):
		_unit(ids[i], team, line + p * (float(i) - 4.0) * 1.6, atan2(-d.x, -d.z))
	return {"keep": keep_pos, "keep_b": keep_b, "dir": d, "hall": hall, "house": house, "forge": forge, "site": site,
			"line": line}
