extends SceneTree
## G-C champions (docs/art/gc_champions.md): the hired champions' hero pass keeps every contract and budget.
## - The 4 champions (both variants, every class): authored meshes <= 26, draw instances <= 17 (16 + Face), 0 lights,
##   vertices inside the G-C caps below, set_weapon_class works for every class and gives a weapon tip.
## - Oathwall: the hero armour folds into the palette (brass entry present, no 6th material file), the layered cape and
##   the front tabard carry the team colour (recoloured by set_team_color, restored by the kingdom colour).
## - Weapon kit: every piece <= 1400 vertices, one glow surface in the whole kit (the staff crystal), the sword and
##   greatsword guards are really there (bevelled guard outlines triangulate), the spear has its brass fittings.
## - ChampionShapes: plates, lathes and tubes face outward; cloth UVs stay in 0..1 (banner shader).
## Run: $GODOT --headless --path . -s tests/test_gc_champions.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS gc_champions" or "FAIL gc_champions: <reasons>".

const TASK_ID := "gc_champions"
const IDS: Array[String] = ["oathwall", "wayfinder", "coin_cutter", "mender"]
## Total vertices (body + face + held archetype weapon) per champion after the G-C pass (measured 2026-10-15 + margin).
const VERT_CAP := {"oathwall": 6100, "wayfinder": 7300, "coin_cutter": 4350, "mender": 8750}
const CLASSES: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard", &""]
const BLUE := Color(0.25, 0.45, 0.90)

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	_world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 6, 9), Vector3.ZERO)   # close: tier 0
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_shapes_checks()
	_weapon_checks()
	for id: String in IDS:
		for v: int in 2:
			await _champion(id, v)
	await _oathwall_team()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _spawn(id: String, v: int) -> Node3D:
	var m := (load("res://art/units/champions/%s/%s.tscn" % [id, id]) as PackedScene).instantiate() as Node3D
	if m.has_method("set_variant"):
		m.call("set_variant", v)
	_world.add_child(m)
	return m


func _champion(id: String, v: int) -> void:
	var m := _spawn(id, v)
	for i: int in 3:
		await process_frame
	var tag := "%s v%d" % [id, v]
	_check(m is CharacterModel, tag + " extends CharacterModel")
	if m.has_method("authored_mesh_count"):
		_check(int(m.call("authored_mesh_count")) <= 26, "%s authored meshes %d <= 26" % [tag, int(m.call("authored_mesh_count"))])
	var c := _count(m)
	print("  %s: verts %d, draws %d, lights %d" % [tag, c[0], c[1], c[2]])
	_check(c[0] <= int(VERT_CAP[id]), "%s vertices %d <= %d" % [tag, c[0], int(VERT_CAP[id])])
	_check(c[1] <= 17, "%s draw instances %d <= 17" % [tag, c[1]])
	_check(c[2] == 0, "%s no lights" % tag)
	if v == 0:
		for cls: StringName in CLASSES:
			m.call("set_weapon_class", cls, false)
			await process_frame
			_check(m.call("weapon_class") == cls, "%s class %s taken" % [tag, cls])
			if cls != &"":
				_check(m.call("get_weapon_tip") is Vector3, "%s %s weapon tip" % [tag, cls])
				var cc := _count(m)
				_check(cc[1] <= 17, "%s %s draw instances %d <= 17" % [tag, cls, cc[1]])
	m.queue_free()
	await process_frame


## [vertices, draw instances, lights] of the visible geometry.
func _count(m: Node) -> Array[int]:
	var out: Array[int] = [0, 0, m.find_children("*", "Light3D", true, false).size()]
	for gi: Node in m.find_children("*", "GeometryInstance3D", true, false):
		if not (gi as GeometryInstance3D).is_visible_in_tree():
			continue
		out[1] += 1
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var mesh := (gi as MeshInstance3D).mesh
			for s: int in mesh.get_surface_count():
				out[0] += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return out


func _oathwall_team() -> void:
	var m := _spawn("oathwall", 0)
	await process_frame
	await process_frame
	var chest := m.get_node_or_null(^"Root/Chest/Merged") as MeshInstance3D
	_check(chest != null, "oathwall Chest merged node")
	if chest:
		var brass := false
		var own_files: Dictionary = {}
		for s: int in chest.mesh.get_surface_count():
			var mat := chest.mesh.surface_get_material(s)
			if mat and mat.has_meta(&"pal_srcs"):
				for src: Variant in mat.get_meta(&"pal_srcs"):
					if src is Material:
						if (src as Material).resource_name == "oathwall_brass":
							brass = true
						if (src as Material).resource_path != "":
							own_files[(src as Material).resource_path] = true
		_check(brass, "oathwall brass trims fold into the palette")
		for p: String in own_files:
			_check(p.begins_with("res://art/units/champions/oathwall/materials/"), "oathwall folds only its own files (%s)" % p)
	var before := _team_overrides(m)
	m.call("set_team_color", BLUE)
	var after := _team_overrides(m)
	_check(after >= 2 and after > before, "oathwall cape + sash / tabard recoloured (%d -> %d overrides)" % [before, after])
	m.call("set_team_color", m.get("kingdom_color"))
	_check(_team_overrides(m) == before, "oathwall kingdom colour restores the authored cape")
	m.queue_free()
	await process_frame


func _team_overrides(m: Node) -> int:
	var n := 0
	for mi: Node in m.find_children("*", "MeshInstance3D", true, false):
		var gi := mi as MeshInstance3D
		if gi.mesh == null:
			continue
		for s: int in gi.mesh.get_surface_count():
			var o := gi.get_surface_override_material(s)
			if o and o.resource_name.contains("cape"):
				n += 1
			elif o and gi.material_override == null and String(o.resource_path).is_empty() and o is ShaderMaterial \
					and (o as ShaderMaterial).shader and (o as ShaderMaterial).shader.resource_path.ends_with("banner.gdshader"):
				n += 1
	return n


func _weapon_checks() -> void:
	var glows := 0
	for p: StringName in [&"spear", &"quiver", &"javelin", &"sword", &"round_shield", &"greatsword", &"staff"]:
		var mesh := ChampionWeaponKit.piece_mesh(p)
		var nv := ChampionWeaponKit.piece_vertices(p)
		_check(nv > 40 and nv <= 1400, "%s vertices %d in 40..1400" % [p, nv])
		var has_brass := false
		for s: int in mesh.get_surface_count():
			var mat := mesh.surface_get_material(s) as ShaderMaterial
			if mat and mat.shader and mat.shader.resource_path.ends_with("unit_glow.gdshader"):
				glows += 1
				_check(p == &"staff", "%s has no glow surface (the kit's one glow is the staff crystal)" % p)
			if mat and mat.resource_path.ends_with("weapon_brass.tres"):
				has_brass = true
		if p in [&"spear", &"sword", &"round_shield", &"greatsword", &"staff"]:
			_check(has_brass, "%s has brass fittings" % p)
	_check(glows == 1, "one glow surface in the kit (%d)" % glows)
	_check(ChampionWeaponKit.piece_mesh(&"sword").get_aabb().size.x >= 0.40, "sword cross-guard present (aabb x %.3f)"
		% ChampionWeaponKit.piece_mesh(&"sword").get_aabb().size.x)
	_check(ChampionWeaponKit.piece_mesh(&"greatsword").get_aabb().size.x >= 0.70, "greatsword cross-guard present")


func _shapes_checks() -> void:
	var st := ChampionShapes.begin()
	ChampionShapes.plate(st, PackedVector2Array([Vector2(-0.2, -0.1), Vector2(0.2, -0.1), Vector2(0.2, 0.1), Vector2(-0.2, 0.1)]),
		0.05, 0.015, Transform3D.IDENTITY, true)
	_check(_outward(ChampionShapes.commit(st), Vector3.ZERO) > 0.99, "plate faces outward")
	st = ChampionShapes.begin()
	ChampionShapes.lathe(st, PackedVector2Array([Vector2(0.0, -0.3), Vector2(0.25, -0.2), Vector2(0.3, 0.1), Vector2(0.0, 0.3)]), 10)
	_check(_outward(ChampionShapes.commit(st), Vector3.ZERO) > 0.99, "lathe faces outward")
	st = ChampionShapes.begin()
	ChampionShapes.tube(st, PackedVector3Array([Vector3(0, -0.5, 0), Vector3(0.05, 0, 0.02), Vector3(0, 0.5, 0)]),
		PackedFloat32Array([0.1, 0.12, 0.08]), 8, false)
	var tm := ChampionShapes.commit(st)
	_check(_outward_axis(tm) > 0.99, "tube faces outward")
	# welded seam: 3 rings x 8 sides
	_check(tm.surface_get_array_len(0) == 24, "tube rings welded (%d vertices)" % tm.surface_get_array_len(0))
	st = ChampionShapes.begin()
	ChampionShapes.cloth(st, ChampionShapes.arc(Vector3(0, 1.5, 0), 0.4, 0.3, PI - 1.0, PI + 1.0, 5), 1.0, 1.3, 0.2, 4, 4)
	var cm := ChampionShapes.commit(st)
	var uv: PackedVector2Array = cm.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	var ok := true
	for u: Vector2 in uv:
		ok = ok and u.x >= -0.001 and u.x <= 1.001 and u.y >= -0.001 and u.y <= 1.001
	_check(ok and uv.size() > 0, "cloth UVs in 0..1")


## Share of triangles whose geometric front (Godot: clockwise) points away from `c`, weighted by area.
func _outward(m: ArrayMesh, c: Vector3) -> float:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var good := 0.0
	var total := 0.0
	for k: int in range(0, ix.size(), 3):
		var a := v[ix[k]]
		var b := v[ix[k + 1]]
		var cc := v[ix[k + 2]]
		var n := (cc - a).cross(b - a)   # clockwise front
		var area := n.length()
		total += area
		if n.dot((a + b + cc) / 3.0 - c) > 0.0:
			good += area
	return good / maxf(total, 1e-9)


## Like _outward but from the tube's axis (the Y axis through the closest point).
func _outward_axis(m: ArrayMesh) -> float:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var good := 0.0
	var total := 0.0
	for k: int in range(0, ix.size(), 3):
		var a := v[ix[k]]
		var b := v[ix[k + 1]]
		var cc := v[ix[k + 2]]
		var n := (cc - a).cross(b - a)
		var area := n.length()
		total += area
		var mid := (a + b + cc) / 3.0
		if n.dot(Vector3(mid.x, 0.0, mid.z) - Vector3(0.05 * (1.0 - absf(mid.y) * 2.0), 0.0, 0.02 * (1.0 - absf(mid.y) * 2.0))) > 0.0:
			good += area
	return good / maxf(total, 1e-9)
