extends SceneTree
## Task 12.V16: cosmetic critters + CritterSystem (docs/design/map-fill.md 3.3, 9, 10).
## Run:  godot --headless --path . -s tests/test_12_v16.gd --fixed-fps 60 --quit-after 9000
## Part A, a stub level (fog, fake river in group "river", fake units): counts and budgets (<= 120 critters, 6
## MultiMeshes, <= 300 triangles per mesh, 0 lights, no colliders, never in "units"), 50 m camera range and the
## 60-animated cap, fog (drawn only in VISIBLE cells), birds / frogs ignore hidden units and react to visible ones
## (take-off, circle 6-12 m up, land at another spot; jump, stay under ~10 s, come back), set_enabled, Map detail Low,
## no water critters without a river, logic cost per frame with 200 units. Part B, the real mission map (main.tscn)
## with the lead's glue: builds after the bake, no script errors.
## Prints "PASS 12.v16" or "FAIL 12.v16: <reason>".

const TASK_ID := "12.v16"
const CS_PATH := "res://art/environment/critters/critter_system.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const KINDS: Array[StringName] = [&"bird", &"butterfly", &"firefly", &"dragonfly", &"frog", &"splash"]
const EXPECT := {&"bird": 18, &"butterfly": 30, &"firefly": 40, &"dragonfly": 12, &"frog": 10, &"splash": 3}


class FakeRiver extends Node:
	var params: Dictionary = {}

	func shader_params() -> Dictionary:
		return params


class FakeUnit extends Node3D:
	var team := 1

	func is_alive() -> bool:
		return true


class FakeSight extends Node3D:
	var team := 0
	var sight_radius := 14.0

	func is_alive() -> bool:
		return true


class StubLevel extends Node3D:
	var river_enabled := true


var _fails: Array[String] = []
var _level: Node3D
var _fog: Node
var _cs: Node3D


func _initialize() -> void:
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  check failed: ", what)


func _wait(sec: float) -> void:
	for i: int in maxi(int(sec * 60.0), 1):
		await process_frame


func _run() -> void:
	var cs_script := load(CS_PATH) as GDScript
	if cs_script == null:
		_finish("critter_system.gd does not load")
		return
	cs_script.set(&"map_detail_override", &"high")
	# ---------------------------------------------------------------- stub level
	_level = StubLevel.new()
	_level.name = "StubLevel"
	root.add_child(_level)
	_fog = load("res://scripts/world/fog_of_war.gd").new()
	_fog.name = "FogOfWar"
	_level.add_child(_fog)
	_fog.set(&"enabled", false)
	var river := FakeRiver.new()
	river.params = (load(GP_PATH) as GDScript).call(&"skirmish_river")
	river.add_to_group(&"river")
	_level.add_child(river)
	_cs = cs_script.new()
	_cs.name = "CritterSystem"
	_level.add_child(_cs)
	_cs.call(&"set_focus_override", Vector3(-36, 0, 36))
	_cs.call(&"setup", _level)
	await _wait(0.2)
	_check(bool(_cs.call(&"is_built")), "built on a stub level (no hero property)")

	# Counts, budgets, draw-only.
	var total: int = _cs.call(&"critter_count")
	_check(total <= 120 and total == 113, "total %d (want 113, <= 120)" % total)
	for k: StringName in KINDS:
		var n: int = _cs.call(&"critter_count", k)
		_check(n == int(EXPECT[k]), "%s count %d (want %d)" % [k, n, EXPECT[k]])
	var mmis: Array[Node] = _cs.find_children("*", "MultiMeshInstance3D", false, false)
	_check(mmis.size() == 6, "one MultiMesh per kind (%d)" % mmis.size())
	var builder: RefCounted = (load("res://art/environment/critters/critter_meshes.gd") as GDScript).new()
	for m: Node in mmis:
		var mmi := m as MultiMeshInstance3D
		var tris: int = builder.call(&"triangle_count", mmi.multimesh.mesh)
		_check(tris > 0 and tris <= 300, "%s: %d triangles (<= 300)" % [mmi.name, tris])
		_check(mmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s casts no shadow" % mmi.name)
		_check(mmi.material_override is ShaderMaterial and mmi.material_override.resource_path.ends_with(".tres"),
				"%s uses its .tres material" % mmi.name)
	_check(_cs.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	_check(_cs.find_children("*", "CollisionObject3D", true, false).is_empty(), "no colliders / click areas")
	_check(not _cs.is_in_group(&"units") and _cs.find_children("*", "Node", true, false).all(
			func(n: Node) -> bool: return not n.is_in_group(&"units") and not n.is_in_group(&"fog_sources")),
			"never in units / fog_sources")

	# Water critters over / by the water.
	var gp := load(GP_PATH) as GDScript
	for e: Dictionary in _cs.call(&"critters_info", &"dragonfly"):
		var p: Vector3 = e["pos"]
		_check(float(gp.call(&"water_distance", river.params, Vector2(p.x, p.z))) < -0.5, "dragonfly over water %s" % p)
	for e: Dictionary in _cs.call(&"critters_info", &"frog"):
		var p: Vector3 = e["pos"]
		var wd := float(gp.call(&"water_distance", river.params, Vector2(p.x, p.z)))
		_check(wd > 0.2 and wd < 1.6, "frog on a bank %s (%.2f m from the water)" % [p, wd])

	# ---------------------------------------------------------------- range + cap (fog off)
	await _wait(0.3)
	var shown := _shown_list()
	_check(shown.size() > 0 and shown.size() <= 60, "animated %d at the player meadow (1..60)" % shown.size())
	for e: Dictionary in shown:
		var p: Vector3 = e["pos"]
		_check(Vector2(p.x + 36.0, p.z - 36.0).length() <= 50.5, "shown %s within 50 m of the focus" % e["kind"])
	for e: Dictionary in _cs.call(&"critters_info"):
		var p: Vector3 = e["pos"]
		if Vector2(p.x + 36.0, p.z - 36.0).length() > 50.5 and e["kind"] != &"splash":
			_check(not e["shown"], "%s at %s beyond 50 m is parked" % [e["kind"], p])
	_cs.call(&"set_focus_override", Vector3.ZERO)
	await _wait(0.3)
	var n_mid := _shown_list().size()
	_check(n_mid <= 60 and n_mid >= 50, "cap at the map centre: %d animated (50..60)" % n_mid)
	_cs.call(&"set_focus_override", Vector3(50, 0, 50))
	await _wait(0.3)
	for e: Dictionary in _shown_list():
		var p: Vector3 = e["pos"]
		_check(Vector2(p.x - 50.0, p.z - 50.0).length() <= 50.5, "focus moved: shown within range")

	# ---------------------------------------------------------------- fog
	_fog.set(&"enabled", true)
	_cs.call(&"set_focus_override", Vector3(-24, 0, 41))
	await _wait(0.5)
	_check(_shown_list().is_empty(), "fog with nothing seen: nothing drawn (%d)" % _shown_list().size())
	var sight := FakeSight.new()
	sight.add_to_group(&"fog_sources")
	_level.add_child(sight)
	sight.global_position = Vector3(-24, 0, 41)
	await _wait(0.5)
	var seen := _shown_list()
	_check(seen.size() >= 6, "the flock under a sight source is drawn (%d)" % seen.size())
	for e: Dictionary in seen:
		_check(bool(_fog.call(&"is_visible", 0, e["pos"])), "drawn %s only in a VISIBLE cell" % e["kind"])

	# ---------------------------------------------------------------- birds: hidden unit ignored, visible unit scares
	var flock0 := _flock_near(Vector3(-24, 0, 41))
	_check(flock0.size() == 6, "flock 0 sits at (-24, 41) (%d birds)" % flock0.size())
	var intruder := FakeUnit.new()
	intruder.add_to_group(&"units")
	_level.add_child(intruder)
	intruder.global_position = Vector3(-21, 0, 42)
	intruder.visible = false
	await _wait(1.0)
	_check(_states(flock0).all(func(s: StringName) -> bool: return s == &"ground"), "birds ignore a HIDDEN unit")
	intruder.visible = true
	await _wait(0.4)
	_check(_states(flock0).any(func(s: StringName) -> bool: return s == &"fly"), "birds take off from a visible unit")
	intruder.visible = false
	var t_air := 0.0
	var max_y := 0.0
	var landed := false
	while t_air < 16.0:
		await _wait(0.25)
		t_air += 0.25
		for i: int in flock0:
			max_y = maxf(max_y, (_info(i)["pos"] as Vector3).y)
		if t_air > 3.0 and _states(flock0).all(func(s: StringName) -> bool: return s == &"ground"):
			landed = true
			break
	_check(landed, "the flock landed again (%.1f s)" % t_air)
	_check(t_air >= 7.0 and t_air <= 15.0, "circled then landed in %.1f s (6-10 s + glide)" % t_air)
	_check(max_y >= 5.5 and max_y <= 12.8, "flight height %.1f m (6-12)" % max_y)
	var new_pos: Vector3 = _info(flock0[0])["pos"]
	_check(Vector2(new_pos.x + 24.0, new_pos.z - 41.0).length() > 10.0, "landed at another spot %s" % new_pos)
	intruder.queue_free()

	# ---------------------------------------------------------------- frogs
	var frogs: Array = _cs.call(&"critters_info", &"frog")
	var frog: Dictionary = frogs[0]
	var fi: int = frog["index"]
	var bank: Vector3 = frog["pos"]
	sight.global_position = bank
	_cs.call(&"set_focus_override", bank)
	await _wait(0.5)
	_check(bool(_info(fi)["shown"]), "a frog in a seen cell is drawn")
	var lurker := FakeUnit.new()
	lurker.add_to_group(&"units")
	_level.add_child(lurker)
	lurker.global_position = bank + Vector3(2.0, 0, 0.5)
	lurker.visible = false
	await _wait(1.0)
	_check(_info(fi)["state"] == &"sit", "a frog ignores a hidden unit (%s)" % _info(fi)["state"])
	lurker.visible = true
	await _wait(0.4)
	_check(_info(fi)["state"] == &"jump", "a frog jumps from a visible unit (%s)" % _info(fi)["state"])
	await _wait(1.6)
	_check(_info(fi)["state"] == &"under" and not bool(_info(fi)["shown"]), "the frog is under water and hidden")
	lurker.queue_free()
	var t_under := 0.0
	while t_under < 14.0 and _info(fi)["state"] != &"sit":
		await _wait(0.25)
		t_under += 0.25
	_check(_info(fi)["state"] == &"sit" and t_under >= 8.0, "the frog came back after ~10 s (%.1f s)" % t_under)
	await _wait(0.4)
	_check(bool(_info(fi)["shown"]), "the frog is drawn again")

	# ---------------------------------------------------------------- set_enabled
	_cs.call(&"set_enabled", false)
	await _wait(0.3)
	_check(_shown_list().is_empty(), "set_enabled(false) hides everything")
	_cs.call(&"set_enabled", true)
	await _wait(0.3)
	_check(not _shown_list().is_empty(), "set_enabled(true) shows them again")

	# ---------------------------------------------------------------- logic cost with 200 visible units
	_fog.set(&"enabled", false)
	_cs.call(&"set_focus_override", Vector3(-20, 0, 10))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k: int in 200:
		var u := FakeUnit.new()
		u.add_to_group(&"units")
		_level.add_child(u)
		u.global_position = Vector3(rng.randf_range(-55, 55), 0, rng.randf_range(-55, 55))
	await _wait(0.5)
	var us: float = _cs.call(&"benchmark", 600)
	print("  logic cost: %.1f us / frame (budget 80), %d animated" % [us, _shown_list().size()])
	_check(us < 80.0, "logic < 0.08 ms / frame (%.1f us)" % us)
	for u: Node in get_nodes_in_group(&"units"):
		u.queue_free()

	# ---------------------------------------------------------------- no river, Map detail Low
	river.remove_from_group(&"river")
	_level.set(&"river_enabled", false)
	_cs.call(&"setup", _level)
	await _wait(0.2)
	_check(int(_cs.call(&"critter_count", &"frog")) == 0 and int(_cs.call(&"critter_count", &"dragonfly")) == 0
			and int(_cs.call(&"critter_count", &"splash")) == 0, "no river: no water critters")
	_check(int(_cs.call(&"critter_count", &"firefly")) == 40 and int(_cs.call(&"critter_count", &"bird")) == 18,
			"no river: fireflies all in the Old Wood, birds unchanged")
	_level.set(&"river_enabled", true)
	_cs.call(&"setup", _level)
	await _wait(0.2)
	_check(int(_cs.call(&"critter_count", &"frog")) == 10, "river_enabled without a RiverSystem: fixed river spots")
	cs_script.set(&"map_detail_override", &"low")
	_cs.call(&"setup", _level)
	await _wait(0.2)
	_check(bool(_cs.call(&"is_built")) and int(_cs.call(&"critter_count")) == 0, "Map detail Low: no critters")
	_check(_cs.find_children("*", "MultiMeshInstance3D", false, false).is_empty(), "Map detail Low: no MultiMesh")
	# The settings store (ui-coder) when it has the field.
	var gs := load("res://scripts/ui/menus/game_settings.gd") as Script
	cs_script.set(&"map_detail_override", &"")
	if gs and gs.has_method(&"ensure_read"):
		gs.call(&"ensure_read")  # load settings.cfg first, or it resets map_detail to high later
	if gs and gs.get(&"map_detail") != null:
		var old: Variant = gs.get(&"map_detail")
		gs.set(&"map_detail", &"low")
		_check(cs_script.call(&"map_detail") == &"low", "reads GameSettings.map_detail")
		gs.set(&"map_detail", old)
	else:
		_check(cs_script.call(&"map_detail") == &"high", "no map_detail in the settings store yet: high")
		print("  (GameSettings.map_detail not there yet: read through map_detail_override only)")
	_level.queue_free()
	await _wait(0.1)

	# ---------------------------------------------------------------- Part B: the real map + the lead's glue
	cs_script.set(&"map_detail_override", &"high")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var critters: Node3D = cs_script.new()
	critters.name = "CritterSystem"
	main.add_child(critters)
	critters.call(&"setup", main)
	var w := 0
	while main.get(&"hero") == null and w < 5000:
		await process_frame
		w += 1
	await _wait(0.5)
	_check(bool(critters.call(&"is_built")), "built on main.tscn after the bake")
	var n_main: int = critters.call(&"critter_count")
	_check(n_main == 88, "mission map without a river: 88 critters (%d)" % n_main)
	var anim_main: int = critters.call(&"animated_count")
	_check(anim_main <= 60, "mission start: %d animated (<= 60)" % anim_main)
	for e: Dictionary in critters.call(&"critters_info"):
		if e["shown"]:
			_check(bool(main.get(&"fog").call(&"is_visible", 0, e["pos"])), "main: drawn only where seen")
	_finish("")


func _shown_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in _cs.call(&"critters_info"):
		if e["shown"]:
			out.append(e)
	return out


func _info(i: int) -> Dictionary:
	for e: Dictionary in _cs.call(&"critters_info"):
		if int(e["index"]) == i:
			return e
	return {}


func _flock_near(p: Vector3) -> Array[int]:
	var out: Array[int] = []
	for e: Dictionary in _cs.call(&"critters_info", &"bird"):
		var q: Vector3 = e["pos"]
		if Vector2(q.x - p.x, q.z - p.z).length() < 4.0:
			out.append(int(e["index"]))
	return out


func _states(list: Array[int]) -> Array[StringName]:
	var out: Array[StringName] = []
	for i: int in list:
		out.append(_info(i)["state"])
	return out


func _finish(err: String) -> void:
	if err != "":
		_fails.append(err)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails.slice(0, 6))])
	quit()
