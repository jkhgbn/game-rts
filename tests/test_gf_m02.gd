extends SceneTree
## G-F review 2 item 11 (docs/art/gf_m02.md): the m02 frozen Emberguard art and the snow border.
## Builds real MissionFrozenEmberguard blocks (no mission), dresses them with FrozenBlockArt and checks: the faceted
## crystal (size, outward normals, ice shader), the figures inside, the old box hidden, the rime mound, the shatter
## on lit_up (shards, ice gone, teeth once IceBlock hides), a quiet load of a thawed block, idempotence, a Sentinel
## shell, and FrozenLook.add_snow_border (snow-capped cliffs + plateau, 120 m only).
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gf_m02.gd --fixed-fps 60 --quit-after 1200

const TASK_ID := "gf_m02"

var _fails: Array[String] = []
var _frame := 0
var _world: Node3D
var _a: Node3D   ## thawed during the run
var _b: Node3D   ## loaded as thawed after the dress
var _c: Node3D   ## loaded as thawed before the dress


func _initialize() -> void:
	_world = Node3D.new()
	_world.name = "World"
	root.add_child(_world)
	_a = _make_block("EmberguardWest", Vector3(-6.0, 0.0, 0.0))
	_b = _make_block("EmberguardSouth", Vector3(0.0, 0.0, 0.0))
	_c = _make_block("EmberguardNorth", Vector3(6.0, 0.0, 0.0))


func _make_block(n: String, at: Vector3) -> Node3D:
	var b := MissionFrozenEmberguard.new()
	b.name = n
	_world.add_child(b)
	b.position = at
	return b


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_step_build()
	elif _frame == 4:
		_a.call(&"light")
		_check(not (_a.get_node(^"IceBlock/IceArt") as Node3D).visible, "the ice hides at once on lit_up")
		var fx := _a.get_node_or_null(^"ShatterFx")
		_check(fx != null and fx.get_child_count() == FrozenBlockArt.SHARDS[FrozenBlockArt.tier()] + 1,
				"shatter: %d shards + 1 puff" % FrozenBlockArt.SHARDS[FrozenBlockArt.tier()])
		_b.call(&"load_row", [true])
		_check((_b.get_node(^"IceStump") as Node3D).visible, "a block loaded thawed shows its teeth")
	elif _frame == 120:
		_check(not (_a.get_node(^"IceBlock") as Node3D).visible, "IceBlock hidden after the thaw tween")
		_check((_a.get_node(^"IceStump") as Node3D).visible, "teeth shown after the thaw")
	elif _frame == 420:
		_check(_a.get_node_or_null(^"ShatterFx") == null, "shatter fx freed after ~4.5 s")
		_finish()
		return true
	return false


func _step_build() -> void:
	_c.call(&"load_row", [true])
	for b: Node3D in [_a, _b, _c]:
		_check(FrozenBlockArt.dress_block(b), "dress_block(%s)" % b.name)
	_check(FrozenBlockArt.dress_block(_a), "dress_block twice is ok")
	_check(_a.find_children("IceArt", "", true, false).size() == 1, "idempotent: one IceArt")
	# Old placeholder hidden.
	for c: Node in _a.get_node(^"IceBlock").get_children():
		if c is MeshInstance3D:
			_check(not (c as MeshInstance3D).visible, "old placeholder mesh %s hidden" % c.name)
	var stump := _a.get_node_or_null(^"Stump") as MeshInstance3D
	_check(stump == null or not stump.visible, "old stump hidden")
	# Crystal.
	var cr := _a.get_node_or_null(^"IceBlock/IceArt/Crystal") as MeshInstance3D
	_check(cr != null, "Crystal exists")
	if cr:
		var aabb := cr.mesh.get_aabb()
		_check(aabb.size.x > 1.9 and aabb.size.x < 3.1 and aabb.size.z > 1.9 and aabb.size.z < 3.1,
				"crystal footprint ~2.4 m (%s)" % aabb.size)
		_check(aabb.end.y > 1.9 and aabb.end.y < 2.7 and aabb.position.y < 0.0, "crystal height ~2.2 m, sunk base (%s)" % aabb)
		var sm := cr.material_override as ShaderMaterial
		_check(sm != null and sm.shader.resource_path.ends_with("frozen_ice.gdshader"), "crystal uses frozen_ice")
		_check(_outward(cr.mesh) > 0.95, "crystal faces wound outward (%.2f)" % _outward(cr.mesh))
		for v in 4:
			_check(_outward(FrozenBlockArt.shard_mesh(v)) > 0.9, "shard %d faces wound outward" % v)
	var figs := _a.get_node_or_null(^"IceBlock/IceArt/Figures")
	_check(figs != null and figs.get_child_count() == 2, "two frozen figures inside")
	if figs and figs.get_child_count() > 0:
		var f0 := figs.get_child(0) as Node3D
		_check(f0.process_mode == Node.PROCESS_MODE_DISABLED, "figure frozen (process off)")
		var overlays := 0
		for g: Node in f0.find_children("*", "GeometryInstance3D", true, false):
			if (g as GeometryInstance3D).material_overlay != null:
				overlays += 1
		_check(overlays > 0, "figure has the cold overlay")
		_check(f0.scale.x > 0.2 and f0.scale.x < 3.0, "figure scaled to fit (%.2f)" % f0.scale.x)
	_check(_a.get_node_or_null(^"RimeMound") != null, "rime mound")
	_check(not (_a.get_node(^"IceStump") as Node3D).visible, "teeth hidden while frozen")
	_check(not (_c.get_node(^"IceBlock/IceArt") as Node3D).visible, "loaded-thawed before dress: no ice")
	_check((_c.get_node(^"IceStump") as Node3D).visible, "loaded-thawed before dress: teeth")
	# Sentinel shell.
	var unit := Node3D.new()
	unit.name = "Sentinel1"
	_world.add_child(unit)
	unit.position = Vector3(0.0, 0.0, 10.0)
	var shell := MeshInstance3D.new()
	shell.name = "IceShell"
	var box := BoxMesh.new()
	box.size = Vector3(2.6, 3.6, 2.6)
	shell.mesh = box
	shell.position.y = 1.8
	unit.add_child(shell)
	_check(FrozenBlockArt.dress_shell(shell), "dress_shell")
	var sa := shell.mesh.get_aabb()
	_check(absf(sa.get_center().y) < 0.5 and sa.size.y > 3.5, "shell mesh centred, ~3.9 m (%s)" % sa)
	_check(shell.get_node_or_null(^"RimeMound") != null, "shell rime mound")
	# Snow border (MapInfo default = 120 m).
	var lvl := Node3D.new()
	lvl.name = "Level"
	_world.add_child(lvl)
	var border := FrozenLook.add_snow_border(lvl)
	_check(border != null and border.get_node_or_null(^"Cliffs") != null and border.get_node_or_null(^"Plateau") != null,
			"snow border built")
	if border:
		var cm := (border.get_node(^"Cliffs") as MeshInstance3D).material_override as ShaderMaterial
		_check(cm != null and float(cm.get_shader_parameter(&"cliff_snow")) == 1.0, "cliffs snow-capped")
		var pm := (border.get_node(^"Plateau") as MeshInstance3D).material_override as ShaderMaterial
		_check(pm != null and float(pm.get_shader_parameter(&"snow_mode")) == 1.0, "plateau in snow mode")
		_check(FrozenLook.add_snow_border(lvl) == border, "snow border idempotent")


## Fraction of triangles whose winding (and normal) points away from the mesh centre (the shapes are near convex).
func _outward(m: Mesh) -> float:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var c := m.get_aabb().get_center()
	var good := 0
	var total := 0
	var count := idx.size() if idx.size() > 0 else v.size()
	for i in range(0, count, 3):
		var ia := idx[i] if idx.size() > 0 else i
		var ib := idx[i + 1] if idx.size() > 0 else i + 1
		var ic := idx[i + 2] if idx.size() > 0 else i + 2
		var mid := (v[ia] + v[ib] + v[ic]) / 3.0
		var wound := (v[ic] - v[ia]).cross(v[ib] - v[ia]).normalized()   # Godot front face = clockwise
		var out := mid - c
		if out.length() < 0.05:
			continue
		total += 1
		if wound.dot(out) > 0.0 and nn[ia].dot(out) > 0.0:
			good += 1
	return float(good) / float(maxi(total, 1))


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  - ", f)
		print("FAIL %s: %d check(s)" % [TASK_ID, _fails.size()])
