extends SceneTree
## G-F review 3 item 10 (docs/art/gf_thornwater_bridges.md): Thornwater's crown lane bridges as fen-timber trestles.
## Run: $GODOT --headless --path . -s tests/test_gf_thornwater_bridges.gd --fixed-fps 60 --quit-after 40000
## Checks: the timber mesh (3 surfaces like the stone bridge: timber on env_painted_mat, the source's gold / ember arrays
## and materials kept, braziers copied, deck tops low and never green, planks with gaps, cached); Crown Hollow keeps
## lane_bridge.res; Thornwater (through the real altar hook, `allow_headless`) at High and Low swaps both crown lane
## bridges to it with no new node / collider / draw; Quartermeet keeps stone; leaving puts lane_bridge.res back; the
## shared materials and source meshes equal the snapshot after every map.
## Prints "PASS gf_thornwater_bridges" or "FAIL gf_thornwater_bridges: <reasons>".

const TASK_ID := "gf_thornwater_bridges"
const LOOK := "res://art/environment/crown_variants/crown_isle_look.gd"
const TIMBER := "res://art/environment/bridges/timber_bridge_meshes.gd"
const LANE_MESH := "res://art/environment/bridges/lane_bridge.res"
const ENV_MAT := "res://art/environment/env_painted_mat.tres"
const SHARED_MATS: Array[String] = [
	"res://art/environment/nature_props/nature_mat.tres",
	"res://art/environment/env_painted_mat.tres",
	"res://art/environment/crown/crown_gold_mat.tres",
	"res://art/environment/bridges/lane_bridge_ember_mat.tres",
	"res://art/environment/water/water_mat.tres",
]
## Uniforms every level writes at runtime (tier, its own fords / foam rocks): left out of the snapshot.
const RUNTIME_KEYS: Array[String] = ["gd_detail", "detail", "quality", "foam_rocks", "foam_rock_count", "fords",
	"ford_count"]
const SHARED_MESHES: Array[String] = [
	"res://art/environment/bridges/lane_bridge.res",
	"res://art/environment/bridges/meshes/crown_steps_body.res",
]

var _fails := PackedStringArray()
var _notes := PackedStringArray()
var _cl: GDScript
var _held: Array[Resource] = []


func _initialize() -> void:
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_cl = load(LOOK)
	_cl.set(&"allow_headless", true)
	for p: String in SHARED_MATS + SHARED_MESHES:
		if ResourceLoader.exists(p):
			_held.append(load(p))
	var ref := _snapshot()
	_check_mesh()
	_same(ref, "building the timber mesh changed shared values")
	await _level_pass(&"crown_hollow", 2)
	_same(ref, "Crown Hollow changed shared values")
	await _level_pass(&"thornwater", 2)
	_same(ref, "Thornwater High changed shared values")
	await _level_pass(&"thornwater", 0)
	_same(ref, "Thornwater Low changed shared values")
	await _level_pass(&"quartermeet", 2)
	_same(ref, "Quartermeet changed shared values")
	await _level_pass(&"crown_hollow", 2)
	_same(ref, "Crown Hollow (after) changed shared values")
	_cl.set(&"quality_override", -1)
	_cl.set(&"allow_headless", false)
	(load(TIMBER) as Script).call(&"clear_cache")
	_held.clear()
	for n: String in _notes:
		print("  note: ", n)
	if _fails.is_empty():
		print("PASS " + TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _same(ref: Dictionary, what: String) -> void:
	var now := _snapshot()
	if now == ref:
		return
	_check(false, what)
	for p: Variant in ref:
		for k: Variant in ref[p]:
			if str(ref[p][k]) != str((now.get(p, {}) as Dictionary).get(k)):
				print("    %s %s: %s -> %s" % [String(p).get_file(), k, str(ref[p][k]).left(60),
					str((now.get(p, {}) as Dictionary).get(k)).left(60)])


func _check_mesh() -> void:
	var tb := load(TIMBER) as Script
	var src := load(LANE_MESH) as Mesh
	var m := tb.call(&"lane_bridge", src) as ArrayMesh
	_check(m != null, "no timber mesh")
	if m == null:
		return
	_check(tb.call(&"lane_bridge", src) == m, "timber mesh not cached")
	_check(m != src and m.resource_path == "", "timber mesh is (or is saved as) a shared resource")
	_check(m.get_surface_count() == src.get_surface_count(), "surfaces %d vs source %d" % [m.get_surface_count(),
		src.get_surface_count()])
	_check(m.surface_get_material(0) == load(ENV_MAT), "timber surface not on env_painted_mat")
	for s: int in range(1, mini(m.get_surface_count(), src.get_surface_count())):
		_check(m.surface_get_material(s) == src.surface_get_material(s), "surface %d material changed" % s)
		var a: Array = src.surface_get_arrays(s)
		var b: Array = m.surface_get_arrays(s)
		_check(a[Mesh.ARRAY_VERTEX] == b[Mesh.ARRAY_VERTEX] and a[Mesh.ARRAY_COLOR] == b[Mesh.ARRAY_COLOR],
			"gold / ember surface %d differs from the source" % s)
	var arr: Array = m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var c: PackedColorArray = arr[Mesh.ARRAY_COLOR]
	var aabb := m.get_aabb()
	_notes.append("timber: %d tris (source %d), aabb %s" % [v.size() / 3, _tris(src), aabb])
	_check(v.size() / 3 < 12000, "timber surface too heavy: %d tris" % (v.size() / 3))
	_check(absf(aabb.size.x - src.get_aabb().size.x) < 2.5 and absf(aabb.size.z - src.get_aabb().size.z) < 2.5,
		"footprint %s vs source %s" % [aabb.size, src.get_aabb().size])
	var brazier := 0
	var deck_high := 0
	var deck_green := 0
	var deck_tops := {}
	var below_water_dark := true
	for i: int in v.size():
		var p := v[i]
		var col := c[i]
		if p.y > 1.15 and absf(absf(p.x) - 4.62) < 0.5 and absf(absf(p.z) - 3.1) < 0.5:
			brazier += 1
		if absf(p.x) < 3.6 and absf(p.z) < 3.2 and p.y > -0.01:
			if p.y > 0.06:
				deck_high += 1
			if col.g > col.r + 0.01:
				deck_green += 1
		if absf(p.x) < 3.6 and absf(p.z) < 3.2 and absf(p.y - 0.036) < 0.01:
			deck_tops[snappedf(p.z, 0.01)] = true
		if p.y < -0.6 and maxf(col.r, maxf(col.g, col.b)) > 0.3:
			below_water_dark = false
	_check(brazier >= 4 * 24, "braziers not copied (%d verts)" % brazier)
	_check(deck_high == 0, "%d deck vertices above 6 cm (walkable deck)" % deck_high)
	_check(deck_green == 0, "%d green deck vertices (the carpet look)" % deck_green)
	_check(below_water_dark, "the wet foot is not dark")
	# Planks with gaps: plank top edges spread along the lane (> 30 distinct z edges over the 6.5 m deck).
	_check(deck_tops.size() > 30, "plank edges along the lane: %d" % deck_tops.size())


func _tris(m: Mesh) -> int:
	var t := 0
	for s: int in m.get_surface_count():
		var a: Array = m.surface_get_arrays(s)
		var idx: Variant = a[Mesh.ARRAY_INDEX]
		t += ((idx as PackedInt32Array).size() if idx is PackedInt32Array else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return t


func _level_pass(map_id: StringName, q: int) -> void:
	_cl.set(&"quality_override", q)
	var tag := "%s q%d" % [map_id, q]
	var lvl := MapCatalog.load_default().instantiate_level(map_id)
	_check(lvl != null, "%s did not instantiate" % map_id)
	if lvl == null:
		return
	root.add_child(lvl)
	await _wait_hero(lvl)
	var bridges := _lane_bridges(lvl)
	var timber := map_id == &"thornwater"
	_check(bridges.size() == 2 or map_id == &"quartermeet", "%s: %d crown lane bridges" % [tag, bridges.size()])
	var child_counts := {}
	for b: Node3D in bridges:
		child_counts[b] = b.get_child_count()
		_check(b.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s: collider on a bridge" % tag)
	var v := lvl.get_node_or_null(^"CrownIsleVariant")
	for b: Node3D in bridges:
		var mi := b.get_node(^"Mesh") as MeshInstance3D
		var is_timber := mi.mesh != null and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) == load(ENV_MAT)
		_check(is_timber == timber, "%s: bridge %s timber=%s" % [tag, b.name, is_timber])
		if timber:
			_check(mi.mesh.get_surface_count() <= (load(LANE_MESH) as Mesh).get_surface_count(), "%s: more surfaces" % tag)
			_check(b.get_child_count() == child_counts[b], "%s: nodes added to %s" % [tag, b.name])
		elif map_id == &"crown_hollow":
			_check(mi.mesh == load(LANE_MESH), "%s: lane bridge mesh changed" % tag)
	if timber:
		_check(v != null, "%s: no CrownIsleVariant" % tag)
		if v:
			var counts: Dictionary = v.get(&"counts")
			_check(int(counts.get("timber_bridges", 0)) == 2, "%s: timber_bridges %s" % [tag, counts.get("timber_bridges")])
			if q == 0:
				_check(int(v.call(&"draw_count")) == 0, "%s: Low added %d draws" % [tag, v.call(&"draw_count")])
			# Re-applying (a tier change) keeps the timber, then leaving puts the stone mesh back.
			v.call(&"set_quality", 1 if q == 0 else 0)
			for b: Node3D in bridges:
				_check((b.get_node(^"Mesh") as MeshInstance3D).mesh.surface_get_material(0) == load(ENV_MAT),
					"%s: timber lost on a tier change" % tag)
			v.get_parent().remove_child(v)
			for b: Node3D in bridges:
				_check((b.get_node(^"Mesh") as MeshInstance3D).mesh == load(LANE_MESH), "%s: stone mesh not restored on leave" % tag)
			v.free()
	elif map_id == &"crown_hollow":
		_check(v == null, "%s: has a CrownIsleVariant" % tag)
	await _free(lvl)


func _lane_bridges(lvl: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n: Node in lvl.find_children("*", "Node3D", true, false):
		if n.has_method(&"place_on_moat") and n.get_node_or_null(^"Mesh") is MeshInstance3D:
			out.append(n as Node3D)
	return out


func _wait_hero(lvl: Node) -> void:
	var n := 0
	while lvl.get(&"hero") == null and n < 6000:
		await process_frame
		n += 1
	_check(lvl.get(&"hero") != null, "%s never spawned its hero" % lvl.name)
	for k in 4:
		await process_frame


func _free(lvl: Node) -> void:
	MapInfo.release(lvl)
	lvl.queue_free()
	for k in 4:
		await process_frame


func _snapshot() -> Dictionary:
	var out := {}
	for p: String in SHARED_MATS:
		if not ResourceLoader.exists(p):
			continue
		var m := load(p) as Material
		var d := {}
		var sm := m as ShaderMaterial
		if sm and sm.shader:
			for u: Dictionary in sm.shader.get_shader_uniform_list():
				var k := String(u["name"])
				if not RUNTIME_KEYS.has(k):   # per-level runtime values (tier, fords, foam rocks): not art state
					d[k] = var_to_str(sm.get_shader_parameter(StringName(k)))
		out[p] = d
	for p: String in SHARED_MESHES:
		if not ResourceLoader.exists(p):
			continue
		var mesh := load(p) as Mesh
		var d := {}
		for s: int in mesh.get_surface_count():
			var a: Array = mesh.surface_get_arrays(s)
			d[s] = [hash(a[Mesh.ARRAY_COLOR]), hash(a[Mesh.ARRAY_VERTEX]), mesh.surface_get_material(s)]
		out[p] = d
	return out
