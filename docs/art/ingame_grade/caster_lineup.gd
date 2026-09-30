extends SceneTree
## Caster-units clarity lineup (read-only tool, CU.V1 / CU.V4 art check 2026-09-30): a real skirmish (lighting, ground,
## HUD hidden), the new casters (Kilnwarden, Gloom Deacon; no data .tres yet, so each is a pyre_adept / hexweaver type
## copy with its model_scene swapped) standing among their kingdom's infantry in two labelled rows, shot with the real
## RTS camera at zoom 30 (the default) and 18, at rest and mid-cast (the last caster of each row casts; the spell VFX
## families are played too when they exist). Units are on one team, on hold, far from aggro, so nothing fights.
## Run (windowed): tools\godot_run.ps1 --path . -s res://docs/art/ingame_grade/caster_lineup.gd --quit-after 100000 -- --tag=x
## Shots: docs/art/ingame_grade/shots/casters_<tag>_*.png

const SKIRMISH := "res://scenes/skirmish.tscn"
const OUT := "res://docs/art/ingame_grade/shots"
const KILN := "res://art/units/fire/kilnwarden/kilnwarden.tscn"
const DEACON := "res://art/units/shadow/gloom_deacon/gloom_deacon.tscn"
const FIRE_ROW := ["flame_guard", "ember_archer", "pyre_adept", "@kiln", "ashveil_saboteur", "ash_hurler", "scorchbow", "@kiln"]
const SHADOW_ROW := ["shade", "nightbolt", "hexweaver", "@deacon", "bleakbow", "hollow_oathsworn", "gloom_thrall", "@deacon"]

var main: Node = null
var tag := "x"
var _grid: Dictionary = {}   # "row:index" -> unit (row 0 fire, 1 shadow)


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var wd := create_timer(240.0, true, false, true)
	wd.timeout.connect(func() -> void:
		print("CASTERS ERROR watchdog")
		quit(3))
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	for i in 4:
		await process_frame
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
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
	var ts: Node = get_first_node_in_group(&"tier_systems")
	if ts:
		ts.call(&"set_tier", 0, 3)
		ts.call(&"set_tier", 1, 3)
	for c in main.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
	var center := Vector3(-26, 0, 36)
	var rows := [[FIRE_ROW, -3.0], [SHADOW_ROW, 3.0]]
	for row: Array in rows:
		var list: Array = row[0]
		var n := list.size()
		for i in n:
			var u := _make(String(list[i]))
			if u == null:
				continue
			u.set(&"team", 0)   # same team: no fighting; the model keeps its kingdom colour
			main.add_child(u)
			(u as Node3D).global_position = center + Vector3(1, 0, 0) * (float(i) - float(n - 1) * 0.5) * 2.3 + Vector3(0, 0, float(row[1]))
			u.call(&"command_stop")
			if u.has_method(&"command_hold"):
				u.call(&"command_hold")
			(u as Node3D).rotation.y = 0.0
			_grid["%d:%d" % [0 if float(row[1]) < 0.0 else 1, i]] = u
			print("CASTERS ", row[1], " ", i, " ", list[i])
	# the wizards far away (out of every unit's aggro: nobody turns to shoot)
	for team in [0, 1]:
		var w: Node3D = main.call(&"wizard_of", team)
		if w:
			w.global_position = center + Vector3(-3.0 if team == 0 else 3.0, 0, -34.0)
			w.call(&"command_stop")
	for i in 90:
		await process_frame
	await _shot("z30", center + Vector3(0, 0, -5), 30.0)
	await _shot("z18_left", center + Vector3(-5, 0, -3), 18.0)
	await _shot("z18_right", center + Vector3(5, 0, -3), 18.0)
	await _shot("z12_new", center + Vector3(-1.2, 0, -2.5), 12.0)
	# Casts with their spell VFX (UnitVfx hub of the skirmish, else the families on their own):
	# Kilnwarden A (fire 3) Mana Scalds Deacon A (shadow 3), who tithes the Hexweaver (shadow 2) draining the Pyre Adept
	# (fire 2); Kilnwarden B (fire 7) flings Slag Rain 6 m ahead; Deacon B (shadow 7) opens an Umbral Passage.
	var vfx: Object = _vfx_hub()
	var kiln_a: Node = _grid.get("0:3")
	var kiln_b: Node = _grid.get("0:7")
	var dea_a: Node = _grid.get("1:3")
	var dea_b: Node = _grid.get("1:7")
	_cast(kiln_a, &"mana_scald")
	_cast(kiln_b, &"slag_rain")
	_cast(dea_a, &"blood_tithe")
	_cast(dea_b, &"umbral_passage")
	if vfx and dea_a:
		vfx.call(&"play", &"blood_tithe", dea_a, {"to": _grid.get("1:2"), "drain": _grid.get("0:2"), "duration": 4.0})
	if vfx and dea_b:
		vfx.call(&"play", &"umbral_passage", (dea_b as Node3D).global_position + Vector3(-3.5, 0, 5.5), dea_b)
	for i in 11:
		await process_frame
	if vfx and kiln_a and dea_a:
		vfx.call(&"play", &"mana_scald", kiln_a, dea_a)
	for i in 15:
		await process_frame
	if vfx and kiln_b:
		vfx.call(&"play", &"slag_rain", (kiln_b as Node3D).global_position + Vector3(-1.0, 0, 6.0), kiln_b)
	await _shot("z14_cast_a", center + Vector3(-1.2, 0, -1.5), 14.0)
	await _shot("z30_cast", center + Vector3(0, 0, -5), 30.0)
	for i in 12:
		await process_frame
	await _shot("z14_cast_b", center + Vector3(7.0, 0, -1.0), 14.0)
	for i in 30:
		await process_frame
	await _shot("z14_cast_b2", center + Vector3(7.0, 0, -1.0), 14.0)
	await _shot("z30_cast2", center + Vector3(0, 0, -5), 30.0)
	# the slagged look on two Shadow units and a Vigil wisp into Deacon A
	if vfx:
		vfx.call(&"play", &"slagged", _grid.get("1:4"), 10.0)
		vfx.call(&"play", &"slagged", _grid.get("1:5"), 10.0)
		vfx.call(&"play", &"vigil", _grid.get("1:1"), dea_a)
		vfx.call(&"play", &"stoke", _grid.get("1:6"), kiln_b)
	for i in 24:
		await process_frame
	await _shot("z14_status", center + Vector3(3.0, 0, 1.0), 14.0)
	print("CASTERS done")
	quit(0)


func _make(id: String) -> Node:
	if id.begins_with("@"):
		var base := "pyre_adept" if id == "@kiln" else "hexweaver"
		var t: Resource = load("res://data/units/%s.tres" % base)
		if t == null:
			return null
		var copy: Resource = t.duplicate()
		copy.set(&"model_scene", load(KILN if id == "@kiln" else DEACON))
		copy.set(&"body_height", 1.95)
		return copy.call(&"create_unit")
	return main.call(&"make_unit", id)


func _unit_at(row: int, idx: int) -> Node:
	var list: Array = FIRE_ROW if row == 0 else SHADOW_ROW
	var want := String(list[idx])
	for u in get_nodes_in_group(&"units"):
		var ut: Variant = u.get(&"unit_type")
		if ut is Resource and String((ut as Resource).get(&"id")) == want:
			return u
	return null


func _cast(u: Node, id: StringName) -> void:
	if u == null or not u.has_method(&"get_model"):
		return
	var m: Variant = u.call(&"get_model")
	if m is Node and (m as Node).has_method(&"play_cast"):
		(m as Node).call(&"play_cast", id)


func _vfx_hub() -> Object:
	var hub := get_first_node_in_group(&"unit_vfx")
	if hub and hub.has_method(&"has_effect") and bool(hub.call(&"has_effect", &"slag_rain")):
		return hub
	# the families on their own (not wired in UnitVfx.MODULES yet)
	for path in ["res://art/vfx/caster_fire_vfx.gd", "res://art/vfx/caster_shadow_vfx.gd"]:
		if ResourceLoader.exists(path):
			var n: Node = (load(path) as Script).new()
			main.add_child(n)
	return _Multi.new(main)


class _Multi:
	extends RefCounted
	var _root: Node
	func _init(r: Node) -> void:
		_root = r
	func play(id: StringName, at: Variant, target: Variant = null) -> void:
		for c in _root.get_children():
			if c.has_method(&"handles") and bool(c.call(&"handles", id)):
				c.call(&"play", id, at, target)
				return


func _shot(id: String, at: Vector3, zoom: float) -> void:
	var cam: Node3D = main.get(&"camera_rig")
	cam.rotation = Vector3.ZERO
	cam.call(&"focus_on", at + Vector3(0, 0, zoom * 0.14))
	cam.set(&"_zoom", zoom)
	cam.set(&"_target_zoom", zoom)
	cam.call(&"_apply_zoom")
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var p := ProjectSettings.globalize_path("%s/casters_%s_%s.png" % [OUT, tag, id])
	img.save_png(p)
	print("CASTERS shot ", p)
