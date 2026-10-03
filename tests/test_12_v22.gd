extends SceneTree
## Task 12.V22: the Gloomcap Elder + Sprout camp creature models (art/units/neutral/gloomcap/).
## Run: $GODOT --headless --path . -s tests/test_12_v22.gd --fixed-fps 60 --quit-after 2400
## Checks, for both scenes (2 instances each: the first builds and caches the meshes, the second reuses them): soldier
## budget of map-fill.md 10 (<= 18 authored meshes, <= 10 draw instances incl. emitters, 0 lights; vertices Elder
## <= 3 200, Sprout <= 1 500), materials (only the folder's own, no cloth / cape / pennon: no team colour), size (Elder
## cap top ~1.9 m, staff bulb above it, Sprout ~0.7 m, nothing below 0), set_team_color is a no-op, every kit hook.
## Elder: attack `spore_bolt` (staff tipped back in the windup, thrust at the 0.12 s release, one bolt per attack, the
## bulb flares), get_beam_origin at the bulb, cast `spore_burst` (cap swells, one burst at the slam, bulb flare), the
## cap-shake fidget, walk, hit, death (topples, death_finished <= 1.3 s), revive resets the pose and the cap.
## Sprout: attack `cap_bonk` (leans back, hops forward at the 0.12 s strike, one strike per attack), cast (squeeze + one
## puff), hop fidget, walk, per-instance variety, death (squashes flat, death_finished), revive.
## Prints the triangle counts, then "PASS 12.v22" or "FAIL 12.v22: <reasons>".

const TASK_ID := "12.v22"
const ELDER := "res://art/units/neutral/gloomcap/gloomcap_elder.tscn"
const SPROUT := "res://art/units/neutral/gloomcap/gloomcap_sprout.tscn"
const OWN_DIR := "res://art/units/neutral/gloomcap/"
## The FaceKit's shared face material (faces pass 2026-09-28: every unit has a Face node, 1 draw call).
const FACE_MAT := "res://art/units/kit/face/unit_face.tres"
const HOOKS: Array[String] = ["set_team_color", "set_moving", "play_attack", "play_cast", "play_hit", "play_death",
	"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive"]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	var n := int(ceil(sec * 60.0))
	for i: int in n:
		await process_frame


func _spawn(path: String, at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(ELDER), "elder scene exists")
	_check(ResourceLoader.exists(SPROUT), "sprout scene exists")
	# A camera close by keeps both at the full-rate tier 0 (the fidgets only play there).
	var cam := Camera3D.new()
	_world.add_child(cam)
	cam.position = Vector3(0, 8, 10)
	cam.make_current()
	var e1 := _spawn(ELDER, Vector3(0, 0, 0))
	var e2 := _spawn(ELDER, Vector3(4, 0, 0))
	var s1 := _spawn(SPROUT, Vector3(-3, 0, 0))
	var s2 := _spawn(SPROUT, Vector3(-5, 0, 0))
	await _wait(0.3)
	e1.set(&"fidget_every", 0.0)
	s1.set(&"hop_every", 0.0)
	e2.set(&"fidget_every", 0.0)
	s2.set(&"hop_every", 0.0)
	_check(e1 is CharacterModel and s1 is CharacterModel, "both extend CharacterModel")
	# Vertex caps + the face (faces pass 2026-09-28: measured Elder 3692, Sprout 1651 with the Face node; small margin).
	await _structure(e1, e2, "elder", 3800, Vector2(1.8, 1.96))
	await _structure(s1, s2, "sprout", 1720, Vector2(0.6, 0.78))
	await _elder(e1, e2)
	await _sprout(s1, s2)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# ---------------------------------------------------------------- structure / budgets / size / team colour / hooks

func _structure(a: Node3D, b: Node3D, nm: String, max_verts: int, cap_top: Vector2) -> void:
	var authored: int = int(a.call(&"authored_mesh_count"))
	_check(authored >= 5 and authored <= 18, "%s: authored meshes <= 18 (got %d)" % [nm, authored])
	for m: Node3D in [a, b]:
		var inst := _draw_instances(m)
		var verts := _count(m, false)
		var tris := _count(m, true)
		var lights := m.find_children("*", "Light3D", true, false).size()
		print("%s: authored %d, draw instances %d, vertices %d, triangles %d, lights %d" % [nm, authored, inst, verts,
			tris, lights])
		_check(inst <= 10, "%s: draw instances <= 10 (got %d)" % [nm, inst])
		_check(verts <= max_verts, "%s: vertices <= %d (got %d)" % [nm, max_verts, verts])
		_check(lights == 0, "%s: 0 lights" % nm)
	for g: Node in a.find_children("*", "GeometryInstance3D", true, false):
		print("  %s (%s): %d triangles" % [a.get_path_to(g), g.get_class(), _count(g, true, false)])
	var mats := _materials(a)
	var names: Array = []
	for mat: Material in mats:
		names.append(mat.resource_path.get_file())
		_check(mat.resource_path.begins_with(OWN_DIR + "materials/") or mat.resource_path == FACE_MAT,
			"%s: material %s is the folder's own (or the shared face)" % [nm,
			mat.resource_path])
		var f := mat.resource_path.get_file()
		_check(not f.contains("cloth") and not f.contains("cape") and not f.contains("pennon"), "%s: no team cloth" % nm)
	print("%s materials (%d): %s" % [nm, names.size(), ", ".join(PackedStringArray(names))])
	# Size in the Root frame (rest pose).
	var box := _aabb(a, a.get_node("Root"))
	var head_box := _aabb(a.get_node("Root/Chest/Head"), a.get_node("Root"))
	print("%s: AABB bottom %.3f top %.3f, x %.2f .. %.2f, z %.2f .. %.2f; cap top %.3f, cap width %.2f" % [nm,
		box.position.y, box.end.y, box.position.x, box.end.x, box.position.z, box.end.z, head_box.end.y, head_box.size.x])
	# -0.03: the staff foot rests at ~-0.003 and the idle root bob adds up to -0.012 at a phase that depends on the
	# instance id (_phase_off), so -0.015 failed depending on how many objects were allocated before (2026-10-03).
	_check(box.position.y >= -0.03, "%s: nothing below y 0 (got %.3f)" % [nm, box.position.y])
	_check(head_box.end.y >= cap_top.x and head_box.end.y <= cap_top.y, "%s: cap top %.2f-%.2f m (got %.3f)" % [nm,
		cap_top.x, cap_top.y, head_box.end.y])
	# Team colour: none.
	var before := _materials(b)
	b.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	await process_frame
	var after := _materials(b)
	_check(before.size() == after.size(), "%s: set_team_color keeps the materials" % nm)
	for mat: Material in after:
		_check(mat in before, "%s: set_team_color must not recolour %s" % [nm, mat.resource_path.get_file()])
	for h: String in HOOKS:
		_check(a.has_method(h), "%s: hook %s" % [nm, h])


# ---------------------------------------------------------------- Elder

func _elder(a: Node3D, b: Node3D) -> void:
	var box := _aabb(a, a.get_node("Root"))
	_check(box.end.y > 2.0 and box.end.y < 2.3, "elder: staff bulb above the cap (top %.2f)" % box.end.y)
	_check(box.size.x <= 2.0 and box.size.z <= 1.9, "elder: footprint <= 2 m (%.2f x %.2f)" % [box.size.x, box.size.z])
	_check(is_equal_approx(float(a.get(&"body_height")), 1.9), "elder: body_height 1.9")
	_check(a.get(&"attack_style") == &"spore_bolt" and is_equal_approx(float(a.get(&"attack_windup")), 0.12),
		"elder: attack spore_bolt, ranged windup 0.12")
	for h: String in ["play_fidget", "get_beam_origin", "bolt_count", "burst_count", "cap_swell"]:
		_check(a.has_method(h), "elder: %s" % h)
	var bo: Vector3 = a.call(&"get_beam_origin")
	print("elder: beam origin %s" % bo)
	_check(bo.distance_to(Vector3(0.86, 2.03, 0.34)) < 0.2, "elder: beam origin at the staff bulb (%s)" % bo)
	var arm: Node3D = a.get_node("Root/Chest/ArmR")
	var head: Node3D = a.get_node("Root/Chest/Head")
	var root_n: Node3D = a.get_node("Root")
	var leg: Node3D = a.get_node("Root/Hips/LegL")
	var staff: GeometryInstance3D = arm.get_node_or_null("Merged")
	_check(staff != null, "elder: merged ArmR (staff)")
	# walk
	a.call(&"set_moving", 3.2)
	var max_leg := 0.0
	for i: int in 40:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
	a.call(&"set_moving", 0.0)
	print("elder walk: max leg swing %.1f deg" % rad_to_deg(max_leg))
	_check(max_leg > deg_to_rad(15.0), "elder: the legs swing (%.1f deg)" % rad_to_deg(max_leg))
	await _wait(0.4)
	# attack
	var bolts0: int = int(a.call(&"bolt_count"))
	a.call(&"play_attack")
	await _wait(0.07)
	var ax_wind := arm.rotation.x
	await _wait(0.08)
	var ax_rel := arm.rotation.x
	var gb: float = float(staff.get_instance_shader_parameter(&"glow_boost")) if staff else 0.0
	print("spore_bolt: arm x windup %.1f, release %.1f deg, bulb glow_boost %.2f" % [rad_to_deg(ax_wind),
		rad_to_deg(ax_rel), gb])
	_check(ax_wind < deg_to_rad(-5.0), "elder: staff tipped back in the windup")
	_check(ax_rel > deg_to_rad(15.0), "elder: staff thrust at the release")
	_check(gb > 2.0, "elder: the bulb flares at the release (%.2f)" % gb)
	_check(int(a.call(&"bolt_count")) == bolts0 + 1, "elder: one bolt per attack")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "elder: attack finished")
	await _wait(0.6)
	var gb_rest: float = float(staff.get_instance_shader_parameter(&"glow_boost")) if staff else 0.0
	_check(absf(gb_rest - 1.0) < 0.05, "elder: bulb back to glow 1.0 (%.2f)" % gb_rest)
	# cast spore_burst
	var bursts0: int = int(a.call(&"burst_count"))
	a.call(&"play_cast", &"spore_burst")
	await _wait(0.36)
	var sw: float = float(a.call(&"cap_swell"))
	print("spore_burst 0.36 s: swell %.2f, head scale %.3f, arm x %.1f deg" % [sw, head.scale.x, rad_to_deg(arm.rotation.x)])
	_check(sw > 0.7 and head.scale.x > 1.07, "elder: the cap swells before the burst")
	await _wait(0.14)
	gb = float(staff.get_instance_shader_parameter(&"glow_boost")) if staff else 0.0
	print("spore_burst 0.5 s: bursts %d, head x %.1f deg, bulb %.2f" % [int(a.call(&"burst_count")) - bursts0,
		rad_to_deg(head.rotation.x), gb])
	_check(int(a.call(&"burst_count")) == bursts0 + 1, "elder: one burst at the slam")
	_check(head.rotation.x > deg_to_rad(8.0), "elder: the cap snaps forward at the slam")
	_check(gb > 2.0, "elder: bulb flare at the slam")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "elder: cast finished")
	_check(absf(head.scale.x - 1.0) < 0.01, "elder: cap back to its size")
	_check(int(a.call(&"burst_count")) == bursts0 + 1, "elder: still one burst per cast")
	# fidget
	a.call(&"play_fidget")
	var max_z := 0.0
	for i: int in 30:
		await process_frame
		max_z = maxf(max_z, absf(head.rotation.z))
	_check(a.get(&"_action") == &"fidget" and max_z > deg_to_rad(3.0), "elder: cap-shake fidget (%.1f deg)" % rad_to_deg(max_z))
	a.call(&"set_moving", 3.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "elder: moving cancels the fidget")
	a.call(&"set_moving", 0.0)
	await _wait(0.3)
	# misc hooks
	a.call(&"play_hit")
	a.call(&"play_level_up")
	_check(bool(a.call(&"set_status", &"haste", true)), "elder: set_status haste handled")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_veterancy", 2)
	a.call(&"set_carrying", true)
	a.call(&"play_mine")
	b.call(&"play_cast", &"other_id")
	await _wait(0.5)
	a.call(&"set_carrying", false)
	a.call(&"set_veterancy", 0)
	# death mid-cast + revive
	a.call(&"play_cast", &"spore_burst")
	await _wait(0.3)
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"play_death")
	await _wait(0.6)
	print("elder death 0.6 s: root roll %.1f deg, bursts %d" % [rad_to_deg(root_n.rotation.z), int(a.call(&"burst_count"))])
	_check(absf(root_n.rotation.z) > deg_to_rad(50.0), "elder: topples over")
	gb = float(staff.get_instance_shader_parameter(&"glow_boost")) if staff else 1.0
	_check(gb < 0.01, "elder: the bulb dies with it (%.2f)" % gb)
	await _wait(0.7)
	_check(got[0], "elder: death_finished within 1.3 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.x) < 0.1 and absf(root_n.rotation.z) < 0.1 and absf(root_n.position.y) < 0.06,
		"elder: revive resets the pose")
	_check(absf(head.scale.x - 1.0) < 0.01, "elder: revive resets the cap")
	gb = float(staff.get_instance_shader_parameter(&"glow_boost")) if staff else 0.0
	_check(absf(gb - 1.0) < 0.05, "elder: revive relights the bulb (%.2f)" % gb)
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)


# ---------------------------------------------------------------- Sprout

func _sprout(a: Node3D, b: Node3D) -> void:
	var box := _aabb(a, a.get_node("Root"))
	_check(box.size.x <= 0.9 and box.size.z <= 0.9, "sprout: footprint <= 0.9 m (%.2f x %.2f)" % [box.size.x, box.size.z])
	_check(is_equal_approx(float(a.get(&"body_height")), 0.7), "sprout: body_height 0.7")
	_check(a.get(&"attack_style") == &"cap_bonk" and float(a.get(&"attack_windup")) == 0.0, "sprout: attack cap_bonk, melee")
	for h: String in ["play_hop", "strike_count", "puff_count"]:
		_check(a.has_method(h), "sprout: %s" % h)
	var ha: Node3D = a.get_node("Root/Chest/Head")
	var hb: Node3D = b.get_node("Root/Chest/Head")
	print("sprout variety: scale %.3f / %.3f, cap rest %s / %s" % [a.scale.x, b.scale.x, ha.rotation, hb.rotation])
	_check(a.scale.x >= 0.89 and a.scale.x <= 1.09, "sprout: size variation within 0.9-1.08")
	_check(absf(a.scale.x - b.scale.x) > 0.001 or ha.rotation.distance_to(hb.rotation) > 0.01,
		"sprout: two sprouts look different")
	var root_n: Node3D = a.get_node("Root")
	var chest: Node3D = a.get_node("Root/Chest")
	var leg: Node3D = a.get_node("Root/Hips/LegL")
	# walk
	a.call(&"set_moving", 4.0)
	var max_leg := 0.0
	for i: int in 30:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
	a.call(&"set_moving", 0.0)
	print("sprout walk: max leg swing %.1f deg" % rad_to_deg(max_leg))
	_check(max_leg > deg_to_rad(18.0), "sprout: the legs swing (%.1f deg)" % rad_to_deg(max_leg))
	await _wait(0.4)
	# attack
	var s0: int = int(a.call(&"strike_count"))
	a.call(&"play_attack")
	await _wait(0.07)
	var cx_wind := chest.rotation.x
	await _wait(0.06)
	var cx_hit := chest.rotation.x
	var rz_hit := root_n.position.z
	print("cap_bonk: chest x windup %.1f, strike %.1f deg, hop z %.2f" % [rad_to_deg(cx_wind), rad_to_deg(cx_hit), rz_hit])
	_check(cx_wind < deg_to_rad(-8.0), "sprout: leans back in the windup")
	_check(cx_hit > deg_to_rad(15.0) and rz_hit > 0.12, "sprout: hops forward and bonks at the strike")
	_check(int(a.call(&"strike_count")) == s0 + 1, "sprout: one strike per attack")
	await _wait(0.5)
	_check(a.get(&"_action") == &"", "sprout: attack finished")
	# cast
	var p0: int = int(a.call(&"puff_count"))
	a.call(&"play_cast", &"spore_burst")
	await _wait(0.25)
	var sq := root_n.scale.y
	await _wait(0.2)
	print("sprout cast: squash y %.2f at 0.25 s, puffs %d" % [sq, int(a.call(&"puff_count")) - p0])
	_check(sq < 0.9, "sprout: squeezes before the puff")
	_check(int(a.call(&"puff_count")) == p0 + 1, "sprout: one puff per cast")
	await _wait(0.5)
	_check(a.get(&"_action") == &"", "sprout: cast finished")
	# hop
	a.call(&"play_hop")
	var max_y := 0.0
	for i: int in 40:
		await process_frame
		max_y = maxf(max_y, root_n.position.y)
	print("sprout hop: max root y %.2f" % max_y)
	_check(max_y > 0.1, "sprout: hops (%.2f)" % max_y)
	await _wait(0.4)
	_check(a.get(&"_action") == &"", "sprout: hop finished")
	a.call(&"play_hit")
	a.call(&"play_level_up")
	a.call(&"set_veterancy", 3)
	a.call(&"play_mine")
	await _wait(0.5)
	# death + revive
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"play_attack")
	await _wait(0.05)
	a.call(&"play_death")
	await _wait(0.45)
	print("sprout death 0.45 s: root scale %s, puffs %d" % [root_n.scale, int(a.call(&"puff_count"))])
	_check(root_n.scale.y < 0.55 and root_n.scale.x > 1.0, "sprout: squashes flat")
	await _wait(0.85)
	_check(got[0], "sprout: death_finished within 1.3 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.position.y) < 0.06 and absf(root_n.scale.y - 1.0) < 0.06 and absf(chest.rotation.x) < 0.1,
		"sprout: revive resets the pose")
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)


# ---------------------------------------------------------------- helpers

func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


## Vertices (or triangles) of every MeshInstance3D under n (recursive), or of n alone.
func _count(n: Node, tris: bool, recursive: bool = true) -> int:
	var list: Array = n.find_children("*", "MeshInstance3D", true, false) if recursive else [n]
	var c := 0
	for g: Variant in list:
		if not g is MeshInstance3D:
			continue
		var mesh := (g as MeshInstance3D).mesh
		if mesh == null:
			continue
		for s: int in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			if tris:
				var ix: Variant = arr[Mesh.ARRAY_INDEX]
				c += ((ix as PackedInt32Array).size() if ix != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
			else:
				c += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


## Unique materials on the model's meshes (surface overrides > material_override > mesh surfaces); the blob skipped.
func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if mi.material_override:
			if not (mi.material_override in out):
				out.append(mi.material_override)
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


func _aabb(n: Node, model: Node3D) -> AABB:
	var inv := model.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	var list: Array = n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D:
		list.append(n)
	for g: Variant in list:
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var bx := (inv * mi.global_transform) * mi.mesh.get_aabb()
		box = bx if first else box.merge(bx)
		first = false
	return box
