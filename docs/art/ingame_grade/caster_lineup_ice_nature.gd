extends SceneTree
## Caster models in a real skirmish (read-only art tool, task CU.V2 / CU.V3, 2026-09-30): the Rimecarver and the
## Bramblesage (no data .tres yet: their UnitTypes are built in memory from the Rime Seer / Bloomtender with the new
## model_scene) standing in two labelled rows with every other non-worker Ice and Nature unit type, shot with the real
## RTS camera at zoom 30 (the default) and 18; then their casts with the draw-only VFX families (caster_ice_vfx,
## caster_nature_vfx, added to the scene here since UnitVfx does not list them yet): a Rime Bulwark and a Scrying Rune
## in front of the Ice row, a Pollen Haze and a Snagroot on the Nature side. Fog off, HUD hidden, nobody fights.
## Run (windowed): tools\godot_run.ps1 --path . -s res://docs/art/ingame_grade/caster_lineup_ice_nature.gd --quit-after 200000 -- --tag=x
## Shots: docs/art/ingame_grade/shots/icenat_casters_<tag>_*.png

const SKIRMISH := "res://scenes/skirmish.tscn"
const OUT := "res://docs/art/ingame_grade/shots"
const NEW := {
	"rimecarver": ["res://data/units/rime_seer.tres", "res://art/units/ice/rimecarver/rimecarver.tscn", 1.7, "Rimecarver"],
	"bramblesage": ["res://data/units/bloomtender.tres", "res://art/units/nature/bramblesage/bramblesage.tscn", 1.8, "Bramblesage"],
}

## The casters and their nearest siblings (same role / size), in lineup order (the caster in the middle).
const ICE_ROW: Array[String] = ["frostbow", "rime_seer", "shardcaster", "rimecarver", "rimeshield", "hoarlight_magebow",
	"rimeling"]
const NATURE_ROW: Array[String] = ["thornling", "bloomtender", "burr_slinger", "bramblesage", "vinelasher", "wildwood_archer",
	"thistle_darter"]
const OLD_WOOD := Vector3(-44, 0, -40)

var main: Node = null
var tag := "x"
var ice_vfx: Node3D = null
var nature_vfx: Node3D = null
var units := {}


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var wd := create_timer(300.0, true, false, true)
	wd.timeout.connect(func() -> void:
		print("CASTERS ERROR watchdog")
		quit(3))
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	for i in 4:
		await process_frame
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"ice")
	main.set(&"enemy_kingdom", &"nature")
	main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var waited := 0
	while not bool(main.get(&"match_started")):
		await process_frame
		waited += 1
		if waited > 20000:
			quit(2)
			return
	for team in [0, 1]:
		var wz: Node = main.call(&"wizard_of", team)
		if wz:
			for c in wz.get_children():
				if c.has_method(&"default_pick") and not bool(c.call(&"is_locked")):
					c.call(&"choose", c.call(&"default_pick"))
	paused = false
	for i in 10:
		await process_frame
	var cam: Node = main.get(&"camera_rig")
	cam.set(&"edge_pan_enabled", false)
	Input.warp_mouse(Vector2(1598, 898))
	var fog: Variant = main.get(&"fog")
	if fog is Node:
		(fog as Node).set(&"enabled", false)
	for c in main.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
	ice_vfx = (load("res://art/vfx/caster_ice_vfx.gd") as GDScript).new()
	main.add_child(ice_vfx)
	nature_vfx = (load("res://art/vfx/caster_nature_vfx.gd") as GDScript).new()
	main.add_child(nature_vfx)
	var center := Vector3(-14, 0, 26)
	var rows := [[ICE_ROW, -3.0], [NATURE_ROW, 3.0]]
	var axis := Vector3(1, 0, 0)
	for row: Array in rows:
		var list: Array = row[0]
		var n := list.size()
		for i in n:
			var u: Node = _make(list[i])
			if u == null:
				continue
			u.set(&"team", 0)
			main.add_child(u)
			(u as Node3D).global_position = center + axis * (float(i) - float(n - 1) * 0.5) * 2.3 + Vector3(0, 0, float(row[1]))
			u.call(&"command_stop")
			if u.has_method(&"command_hold"):
				u.call(&"command_hold")
			(u as Node3D).rotation.y = 0.0
			units[list[i]] = u
			print("CASTERS ", row[1], " ", i, " ", list[i])
	for i in 90:
		await process_frame
	await _shot("z30", center + Vector3(0, 0, -5), 30.0)
	var rc: Node3D = units.get("rimecarver")
	var bs: Node3D = units.get("bramblesage")
	await _shot("z22_rows", center + Vector3(0, 0, -2), 22.0)
	await _shot("z18_ice", rc.global_position + Vector3(0, 0, -2), 18.0)
	await _shot("z18_nature", bs.global_position + Vector3(0, 0, -2), 18.0)
	await _shot("z30_casters", (rc.global_position + bs.global_position) * 0.5 + Vector3(0, 0, -3), 30.0)
	# Casts: the Rimecarver slams a Bulwark 3 m in front of the Ice row and throws a Scrying Rune; the Bramblesage
	# hazes a point beyond the Ice row and snags the Rime Seer.
	var rcm: Node = rc.call(&"get_model")
	var bsm: Node = bs.call(&"get_model")
	rcm.call(&"play_cast", &"rime_bulwark")
	var wall_at := rc.global_position + Vector3(0.0, 0.0, -3.4)
	await _wait(0.28)
	ice_vfx.call(&"play", &"rime_bulwark", wall_at, {"from": rc, "time": 8.0, "team": 0})
	await _wait(0.12)
	await _shot("z22_bulwark_slam", rc.global_position + Vector3(0, 0, -2), 22.0)
	await _wait(0.6)
	await _shot("z30_bulwark", rc.global_position + Vector3(0, 0, -3), 30.0)
	rcm.call(&"play_cast", &"scrying_rune")
	await _wait(0.3)
	ice_vfx.call(&"play", &"scrying_rune", rc.global_position + Vector3(4.5, 0, -7.0), {"from": rc, "team": 0})
	await _wait(0.6)
	await _shot("z30_rune", rc.global_position + Vector3(2.0, 0, -5.0), 30.0)
	bsm.call(&"play_cast", &"pollen_haze")
	var haze_at := center + Vector3(-4.0, 0, -9.0)
	nature_vfx.call(&"play", &"pollen_haze", haze_at, {"team": 0})
	await _wait(0.45)
	await _shot("z22_haze_cast", bs.global_position + Vector3(0, 0, -2), 22.0)
	await _wait(1.2)
	await _shot("z30_haze", haze_at + Vector3(0, 0, 3), 30.0)
	var seer: Node3D = units.get("rime_seer", null)
	bsm.call(&"play_cast", &"snagroot")
	await _wait(0.2)
	if seer:
		nature_vfx.call(&"play", &"snagroot", bs, seer)
	await _wait(0.2)
	await _shot("z22_snagroot", (bs.global_position + (seer.global_position if seer else bs.global_position)) * 0.5, 22.0)
	for u: Node in units.values():
		if u != rc and u != bs and is_instance_valid(u):
			nature_vfx.call(&"play", &"hazed", u, 2.0)
			break
	bsm.call(&"play_cast", &"seedcloak")
	nature_vfx.call(&"play", &"seedcloak", bs)
	await _wait(0.2)
	await _shot("z18_seedcloak", bs.global_position + Vector3(0, 0, -1.5), 18.0)
	# Deaths (the shatter / the leaf mound) and a level-up on the two casters.
	await _wait(1.0)
	rcm.call(&"play_death")
	bsm.call(&"play_death")
	await _wait(0.45)
	await _shot("z18_deaths", (rc.global_position + bs.global_position) * 0.5 + Vector3(0, 0, -1), 22.0)
	# The same two casters (fresh ones) with two siblings on the Old Wood floor (Nature's home ground, darker).
	var ow: Array[Node3D] = []
	var k := 0
	for id: String in ["rime_seer", "rimecarver", "bramblesage", "bloomtender"]:
		var u2: Node = _make(id)
		if u2 == null:
			continue
		u2.set(&"team", 0)
		main.add_child(u2)
		(u2 as Node3D).global_position = OLD_WOOD + Vector3(-3.3 + 2.2 * float(k), 0, 0)
		u2.call(&"command_stop")
		if u2.has_method(&"command_hold"):
			u2.call(&"command_hold")
		(u2 as Node3D).rotation.y = 0.0
		ow.append(u2)
		k += 1
	for i in 60:
		await process_frame
	await _shot("z30_old_wood", OLD_WOOD + Vector3(0, 0, -2), 30.0)
	await _shot("z18_old_wood", OLD_WOOD + Vector3(0, 0, -1.5), 18.0)
	print("CASTERS done")
	quit(0)


func _make(id: String) -> Node:
	if NEW.has(id):
		var spec: Array = NEW[id]
		var t: Resource = (load(spec[0]) as Resource).duplicate()
		t.set(&"id", StringName(id))
		t.set(&"display_name", spec[3])
		t.set(&"model_scene", load(spec[1]))
		t.set(&"body_height", float(spec[2]))
		if t.get(&"support_kind") != null:
			t.set(&"support_kind", &"")
		return Worker.make_unit(t)
	return main.call(&"make_unit", id)


func _types(kingdom: StringName, extra: String) -> Array[String]:
	var out: Array[String] = [extra]
	var names: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/units/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres"):
			names.append(fn.get_basename())
	names.sort()
	for id in names:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or StringName(t.get(&"faction")) != kingdom:
			continue
		if bool(t.get(&"is_caravan")) or float(t.get(&"lifetime")) > 0.0 or bool(t.get(&"is_worker")):
			continue
		out.append(id)
	return out


func _wait(sec: float) -> void:
	await create_timer(sec, true, false, true).timeout


func _shot(id: String, at: Vector3, zoom: float) -> void:
	var cam: Node3D = main.get(&"camera_rig")
	cam.rotation = Vector3.ZERO
	cam.call(&"focus_on", at + Vector3(0, 0, zoom * 0.14))
	cam.set(&"_zoom", zoom)
	cam.set(&"_target_zoom", zoom)
	cam.call(&"_apply_zoom")
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var p := ProjectSettings.globalize_path("%s/icenat_casters_%s_%s.png" % [OUT, tag, id])
	img.save_png(p)
	print("CASTERS shot ", p)
