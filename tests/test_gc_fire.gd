extends SceneTree
## G-C Fire units (docs/art/gc_fire_units.md): the Fire army's look pass keeps every contract.
## - Hall units + worker (build_fire_units.gd scenes): pivots, the nodes FireModel / tests read (String, DrawnString,
##   DrawnArrow, AshBall, MineSparks, Fx burn emitters, VetTrim), unit-facing exports (body_height, attack_style,
##   attack_windup, fire_kind, INFANTRY_SCALE), glow parts on their own keep_separate nodes.
## - Every Fire foot unit stays inside the Art Lab soldier budgets after _ready (body vertices <= 2500, the face apart;
##   draw instances <= 14), hit flash still lands on the merged body, set_team_color still recolours the cloth.
## - The code-built units sweep FireShapes tubes (no stacked-cylinder paths left) and the shared helpers produce
##   closed, outward-facing geometry; fire_iron is a metal (surface_kind 2) on the kit shader.
## Run: $GODOT --headless --path . -s tests/test_gc_fire.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS gc_fire" or "FAIL gc_fire: <reasons>".

const TASK_ID := "gc_fire"
const DIR := "res://art/units/fire/"
const HALL := {
	"flame_guard": {"body_height": 2.0, "attack_style": &"melee_swing", "attack_windup": 0.0, "fire_kind": &"guard"},
	"ember_archer": {"body_height": 1.9, "attack_style": &"bow_draw", "attack_windup": 0.15, "fire_kind": &"archer"},
	"ash_hurler": {"body_height": 1.8, "attack_style": &"sling_throw", "attack_windup": 0.15, "fire_kind": &"hurler"},
	"cinder_hand": {"body_height": 1.4, "attack_style": &"worker_pick", "attack_windup": 0.0, "fire_kind": &"worker"},
}
const NODES := {
	"flame_guard": ["Root/Hips/LegL", "Root/Hips/LegR", "Root/Chest/Head", "Root/Chest/ArmL", "Root/Chest/ArmR", "Fx",
		"Shadow", "Root/Chest/Head/VetTrim"],
	"ember_archer": ["Root/Chest/ArmL/String", "Root/Chest/ArmL/DrawnString", "Root/Chest/ArmL/DrawnArrow",
		"Root/Chest/Head/VetTrim", "Fx/BurnEmbers", "Fx/AshPuff"],
	"ash_hurler": ["Root/Chest/ArmR/AshBall", "Fx/PotSmoke", "Root/Chest/Head/VetTrim", "Fx/BurnEmbers"],
	"cinder_hand": ["Root/Chest/ArmR/MineSparks", "Root/Chest/Crystals", "Fx/BurnEmbers"],
}
const FOOT: Array[String] = ["flame_guard", "ember_archer", "ash_hurler", "cinder_hand", "scorchling/scorchling",
	"scorchbow/scorchbow", "pyre_adept/pyre_adept", "kilnwarden/kilnwarden", "cinderlock/cinderlock",
	"cinder_arbalest/cinder_arbalest", "ashveil_saboteur/ashveil_saboteur"]
const CODE_BUILT: Array[String] = ["scorchling/scorchling.gd", "scorchbow/scorchbow.gd", "pyre_adept/pyre_adept.gd",
	"kilnwarden/kilnwarden.gd", "cinder_arbalest/cinder_arbalest.gd", "ashveil_saboteur/ashveil_saboteur.gd"]
const VERT_BUDGET := 2500
const FACE_ALLOWANCE := 800
const DRAW_BUDGET := 14

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	_world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 9, 12), Vector3.ZERO)   # close: the models stay on LOD tier 0
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_static_checks()
	for id: String in HALL:
		await _hall(id)
	var x := -10.0
	for id: String in FOOT:
		await _budget(id, x)
		x += 2.0
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _static_checks() -> void:
	var iron := load(DIR + "materials/fire_iron.tres") as ShaderMaterial
	_check(iron != null and iron.shader.resource_path == "res://art/units/kit/unit_painted.gdshader",
		"fire_iron on the kit painted shader")
	_check(iron != null and int(iron.get_shader_parameter(&"surface_kind")) == 2, "fire_iron surface_kind 2 (metal)")
	_check(not String(iron.resource_name if iron else "").ends_with("_cloth"), "fire_iron is not a team-colour material")
	for f: String in CODE_BUILT:
		var src := FileAccess.get_file_as_string(DIR + f)
		_check(src.contains("FireShapes.tube("), "%s sweeps FireShapes tubes" % f)
		_check(not src.contains("append_from(c, 0, Transform3D(Basis(Quaternion(Vector3.UP, d.normalized()))"),
			"%s: no stacked-cylinder path left" % f)
	# FireShapes: a closed tube / lathe has outward normals (centroid test) and welds its seam.
	var t := FireShapes.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, 0.5, 0.05), Vector3(0, 1, 0)]),
		PackedFloat32Array([0.1, 0.12, 0.05]), 8, true)
	_check(_outward(t, Vector3(0, 0.5, 0.02)), "FireShapes.tube normals face outward")
	var tv := (t.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_check(tv <= 3 * 8 + 2 * 9, "FireShapes.tube welds its rings (%d vertices for 3 rings x 8 + 2 caps)" % tv)
	var l := FireShapes.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.2, 0.0), Vector2(0.2, 0.3), Vector2(0.0, 0.3)]), 10)
	_check(_outward(l, Vector3(0, 0.15, 0)), "FireShapes.lathe normals face outward")


## Every triangle's winding normal and vertex normals agree, and point away from an inside point.
func _outward(m: ArrayMesh, inside: Vector3) -> bool:
	var a := m.surface_get_arrays(0)
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var bad := 0
	for k: int in range(0, ix.size(), 3):
		var p0 := v[ix[k]]
		var c := (p0 + v[ix[k + 1]] + v[ix[k + 2]]) / 3.0
		var n := nr[ix[k]] + nr[ix[k + 1]] + nr[ix[k + 2]]
		# Godot front faces are clockwise: the cross product of (b - a, c - a) points INTO the surface
		var fn := (v[ix[k + 1]] - p0).cross(v[ix[k + 2]] - p0)
		if n.dot(c - inside) < 0.0 or fn.dot(n) > 0.0:
			bad += 1
	return bad == 0


func _hall(id: String) -> void:
	var p := DIR + id + ".tscn"
	var ps := load(p) as PackedScene
	_check(ps != null, "%s loads" % p)
	if ps == null:
		return
	var m := ps.instantiate() as Node3D
	_world.add_child(m)
	await process_frame
	await process_frame
	var want: Dictionary = HALL[id]
	for k: String in want:
		var got: Variant = m.get(k)
		var ok: bool = is_equal_approx(float(got), float(want[k])) if want[k] is float else got == want[k]
		_check(ok, "%s %s = %s (want %s)" % [id, k, got, want[k]])
	if id != "cinder_hand":
		_check(m.scale.is_equal_approx(Vector3(1.12, 1.12, 1.12)), "%s keeps INFANTRY_SCALE" % id)
	for path: String in NODES[id]:
		_check(m.get_node_or_null(NodePath(path)) != null, "%s has %s" % [id, path])
	for gi: Node in m.find_children("Glow*", "MeshInstance3D", true, false):
		_check(gi.has_meta(&"keep_separate"), "%s %s glow stays keep_separate" % [id, gi.name])
	# hit flash still reaches a merged painted body part
	m.call(&"play_hit")
	await process_frame
	var flashed := false
	for gi: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var v: Variant = (gi as GeometryInstance3D).get_instance_shader_parameter(&"hit_flash")
		if v != null and float(v) > 0.0:
			flashed = true
			break
	_check(flashed, "%s play_hit flashes the body" % id)
	m.queue_free()
	await process_frame


func _budget(id: String, x: float) -> void:
	var m := (load(DIR + id + ".tscn") as PackedScene).instantiate() as Node3D
	m.position = Vector3(x, 0, 0)
	_world.add_child(m)
	await process_frame
	await process_frame
	var c: Array[int] = [0, 0, 0]
	_count(m, c)
	var body: int = c[1] + maxi(c[2] - FACE_ALLOWANCE, 0)
	print("  %s: body %d verts (face %d), %d draw instances" % [id, c[1], c[2], c[0]])
	_check(body <= VERT_BUDGET, "%s body vertices %d <= %d" % [id, body, VERT_BUDGET])
	_check(c[0] <= DRAW_BUDGET, "%s draw instances %d <= %d" % [id, c[0], DRAW_BUDGET])
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", Color(0.2, 0.4, 0.9))
		await process_frame
		var blue := false
		for gi: Node in m.find_children("*", "MeshInstance3D", true, false):
			var mi := gi as MeshInstance3D
			var mats: Array[Material] = [mi.material_override]
			if mi.mesh:
				for s: int in mi.mesh.get_surface_count():
					mats.append(mi.get_surface_override_material(s))
			for mt: Material in mats:
				if mt is ShaderMaterial and mt.has_meta(&"team_base"):
					blue = true
		_check(blue, "%s set_team_color recolours its cloth" % id)
	m.queue_free()
	await process_frame


## c = [draw instances, body vertices, face vertices] of what is visible at rest.
func _count(n: Node, c: Array[int]) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is GPUParticles3D and (n as GPUParticles3D).emitting:
		c[0] += 1
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		var v := 0
		for s: int in mi.mesh.get_surface_count():
			v += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if String(n.name).containsn("face"):
			c[2] += v
		else:
			c[1] += v
		c[0] += 1
	for ch: Node in n.get_children():
		_count(ch, c)
