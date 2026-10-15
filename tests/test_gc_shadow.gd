extends SceneTree
## Task G-C Shadow units (docs/art/gc_shadow_units.md): the Hall units + Gloom Thrall reshaped by ShadowUnitDress /
## ShadowGeo at _build_parts, plus the smooth-tube rebuild of the Barrow Ghoul / Hollow Oathsworn limbs.
## Run: $GODOT --headless --path . -s tests/test_gc_shadow.gd --fixed-fps 60 --quit-after 4000
## Checks:
##  A geometry: ShadowGeo lathes / tubes / blades / capes wind every triangle with its front face along the vertex
##    normals (culling matches the shading), lathe and tube normals point away from the axis, capes carry UVs (top edge
##    v = 0, hem v ~ 1);
##  B contract per scene, on 2 instances (build + merge cache): every pivot / keep_separate node / emitter the scenes
##    had (named static parts such as Heart / Fuller merge into the pivot meshes, as before G-C), the
##    face rig, the same draw instances on both, budgets (soldier / worker <= 14 draws and <= 2500 body vertices +
##    the 800 face allowance, knight <= 16 / 6000), the replaced keep_separate meshes are shared (lantern cage, hound
##    jaw / tail, capes), the old box feet are gone (no BoxMesh drawn), team colour reaches the merged cloth;
##  C hooks: walk, attack, hit, level-up, death (death_finished once, body faded), revive (body back);
##  D wisps: none at the real (Low) tier; forced High: a SoulWisps emitter on the knight and the thrall only, emitting
##    with a camera 6 m away (kit tier 0), off when the camera is 80 m away, off when the camera stays 6 m away but
##    looks away (off-screen, model frozen; kit offscreen_freeze on), on again when it looks back, off while dead;
##  E the Barrow Ghoul / Hollow Oathsworn instantiate and stay inside their budgets.
## Prints "PASS gc_shadow" or "FAIL gc_shadow: <reasons>".

const TASK_ID := "gc_shadow"
const SCENES: Array[String] = [
	"res://art/units/shadow/gloom_thrall.tscn",
	"res://art/units/shadow/shade.tscn",
	"res://art/units/shadow/nightbolt.tscn",
	"res://art/units/shadow/grave_hound.tscn",
	"res://art/units/shadow/shadow_knight.tscn",
]
const T2: Array[String] = [
	"res://art/units/shadow/barrow_ghoul/barrow_ghoul.tscn",
	"res://art/units/shadow/hollow_oathsworn/hollow_oathsworn.tscn",
]
const COMMON: Array[String] = ["Root", "Fx", "Fx/DeathMotes", "Fx/DeathSmoke", "Shadow"]
const BIPED: Array[String] = ["Root/Hips", "Root/Hips/LegL", "Root/Hips/LegR", "Root/Chest", "Root/Chest/Head",
	"Root/Chest/ArmL", "Root/Chest/ArmR"]
const NAMED := {
	"gloom_thrall": ["Root/Chest/ArmR/Lantern", "Root/Chest/ArmR/Lantern/LanternOrb", "Root/Chest/ArmR/Lantern/MeshInstance3D",
		"Root/Chest/Crystals", "Root/Chest/Crystals/Crystal0", "Root/Chest/ArmR/MineSparks"],
	"shade": ["Root/Chest/Cape", "Root/Chest/Head/GoldTrim"],
	"nightbolt": ["Root/Chest/ArmR/Bolt", "Root/Chest/ArmR/FirePuff", "Root/Chest/Head/GoldTrim"],
	"grave_hound": ["Root/Mount", "Root/Mount/Body", "Root/Mount/Head", "Root/Mount/Head/Jaw",
		"Root/Mount/Head/Jaw/MeshInstance3D", "Root/Mount/Tail", "Root/Mount/Tail/MeshInstance3D", "Root/Mount/LegFL",
		"Root/Mount/LegFR", "Root/Mount/LegBL", "Root/Mount/LegBR", "Root/Mount/Head/GoldTrim"],
	"shadow_knight": ["Root/Chest/Cape", "Root/Chest/ArmR/Sparks", "Root/Chest/ArmR/Slam", "Root/Chest/Head/GoldTrim"],
}
const SHARED := {
	"gloom_thrall": ["Root/Chest/ArmR/Lantern/MeshInstance3D"],
	"shade": ["Root/Chest/Cape"],
	"grave_hound": ["Root/Mount/Head/Jaw/MeshInstance3D", "Root/Mount/Tail/MeshInstance3D"],
	"shadow_knight": ["Root/Chest/Cape"],
}
const FACE_ALLOW := 800

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _frame := 0
var _models: Array[Node3D] = []
var _deaths: Array[int] = []
var _cam: Camera3D
var _wisp_models: Array[Node3D] = []


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	ShadowModel.wisp_quality_override = -1
	_geometry_checks()
	for i: int in SCENES.size():
		for k: int in 2:
			var m := _spawn(SCENES[i], Vector3(i * 4.0, 0, k * 4.0))
			if m == null:
				continue
			_models.append(m)
			_deaths.append(0)
			var idx := _deaths.size() - 1
			m.connect(&"death_finished", func() -> void: _deaths[idx] += 1)
	for i: int in T2.size():
		_spawn(T2[i], Vector3(i * 4.0, 0, 20.0))


func _spawn(path: String, pos: Vector3) -> Node3D:
	var ps := load(path) as PackedScene
	if ps == null:
		_fails.append("cannot load " + path)
		return null
	var m := ps.instantiate() as Node3D
	m.position = pos
	_world.add_child(m)
	return m


func _name(m: Node) -> String:
	return m.scene_file_path.get_file().get_basename()


# ---------------------------------------------------------------- A geometry

func _geometry_checks() -> void:
	var meshes := {
		"lathe": ShadowGeo.lathe([Vector3(0.0, 1.0, 0), Vector3(0.3, 0.8, 0), Vector3(0.4, 0.4, 0.02), Vector3(0.45, 0.0, 0)], 12,
			{"jag": 0.1, "cap_bot": true}),
		"lathe_flat_arc": ShadowGeo.lathe([Vector3(0.3, 1.0, 0), Vector3(0.4, 0.5, 0), Vector3(0.35, 0.0, 0)], 10,
			{"flat": true, "arc": Vector2(-100, 100), "keel": 0.1}),
		"tube": ShadowGeo.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(0.1, 0.5, 0.1), Vector3(0.3, 0.8, 0.0),
			Vector3(0.5, 0.9, -0.2)]), PackedFloat32Array([0.08, 0.06, 0.04, 0.0]), {"seg": 7, "cap_start": true}),
		"tube_caps": ShadowGeo.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0, 0.5)]), PackedFloat32Array([0.1, 0.08]),
			{"seg": 6, "cap_start": true, "cap_end": true, "ell": Vector2(0.6, 1.0)}),
		"blade": ShadowGeo.blade(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0.5, 0), Vector3(0, 1.0, 0.05),
			Vector3(0, 1.3, 0.1)]), PackedFloat32Array([0.1, 0.12, 0.08, 0.0]), Vector3.BACK, Vector3.RIGHT, 0.03, 0.4),
	}
	for key: String in meshes:
		var m: ArrayMesh = meshes[key]
		var arr := m.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var bad := 0
		for t: int in range(0, ix.size(), 3):
			var fn := (v[ix[t + 2]] - v[ix[t]]).cross(v[ix[t + 1]] - v[ix[t]])
			if fn.length() < 0.0000001:
				continue
			var avg := n[ix[t]] + n[ix[t + 1]] + n[ix[t + 2]]
			if fn.dot(avg) <= 0.0:
				bad += 1
		_check(bad == 0, "%s: %d of %d triangles wound against their normals" % [key, bad, ix.size() / 3])
	# Lathe normals point away from the axis on the side wall.
	var lm: ArrayMesh = meshes["lathe"]
	var la := lm.surface_get_arrays(0)
	var lv: PackedVector3Array = la[Mesh.ARRAY_VERTEX]
	var ln: PackedVector3Array = la[Mesh.ARRAY_NORMAL]
	var inward := 0
	for i: int in lv.size():
		var radial := Vector3(lv[i].x, 0, lv[i].z)
		if radial.length() > 0.2 and ln[i].dot(radial) < 0.0:
			inward += 1
	_check(inward == 0, "lathe: %d normals point inward" % inward)
	var cape := ShadowGeo.cloth(0.8, 1.1, 1.8, 6, 8, 0.15, 0.3, 3)
	var ca := cape.surface_get_arrays(0)
	var uv: PackedVector2Array = ca[Mesh.ARRAY_TEX_UV]
	var cv: PackedVector3Array = ca[Mesh.ARRAY_VERTEX]
	var cn: PackedVector3Array = ca[Mesh.ARRAY_NORMAL]
	var top_ok := true
	var vmax := 0.0
	var back := 0
	for i: int in uv.size():
		if cv[i].y > 0.89 and uv[i].y > 0.01:
			top_ok = false
		vmax = maxf(vmax, uv[i].y)
		if cn[i].z < 0.0:
			back += 1
	_check(uv.size() == cv.size() and top_ok and vmax > 0.95, "cape UVs: top edge v 0, hem v ~1 (max %.2f)" % vmax)
	_check(back == 0, "cape normals face +Z like the PlaneMesh they replace (%d backwards)" % back)


# ---------------------------------------------------------------- B contract / budgets

func _draws(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


## [body vertices, face vertices] of everything drawn (the blob excluded).
func _verts(m: Node) -> Vector2i:
	var body := 0
	var face := 0
	for g: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or mi.name == "Shadow":
			continue
		var c := ShadowGeo.vert_count(mi.mesh)
		if mi.name == "Face" or mi.get_parent().name == "Face":
			face += c
		else:
			body += c
	return Vector2i(body, face)


func _box_drawn(m: Node) -> bool:
	for g: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh is BoxMesh and mi.is_visible_in_tree():
			return true
	return false


func _contract_checks() -> void:
	var by_name := {}
	for m: Node3D in _models:
		var nm := _name(m)
		_check(m is ShadowModel, "%s: not a ShadowModel" % nm)
		for p: String in COMMON:
			_check(m.get_node_or_null(p) != null, "%s: node %s missing" % [nm, p])
		if nm != "grave_hound":
			for p: String in BIPED:
				_check(m.get_node_or_null(p) != null, "%s: node %s missing" % [nm, p])
		for p: String in NAMED.get(nm, []):
			_check(m.get_node_or_null(p) != null, "%s: node %s missing" % [nm, p])
		_check(m.find_children("Face", "", true, false).size() >= 1, "%s: no face rig" % nm)
		_check(m.get_node_or_null("Root/Chest/Merged") != null or m.get_node_or_null("Root/Mount/Merged") != null,
			"%s: no merged body" % nm)
		_check(not _box_drawn(m), "%s: a BoxMesh is still drawn (blocky primitive)" % nm)
		var draws := _draws(m)
		var vv := _verts(m)
		var heavy := nm == "shadow_knight"
		var draw_cap: int = 16 if heavy else 14
		var vert_cap: int = 6000 if heavy else 2500
		var body: int = vv.x + maxi(vv.y - FACE_ALLOW, 0)
		_check(draws <= draw_cap, "%s: %d draw instances > %d" % [nm, draws, draw_cap])
		_check(body <= vert_cap, "%s: %d vertices > %d" % [nm, body, vert_cap])
		if not by_name.has(nm):
			by_name[nm] = []
		(by_name[nm] as Array).append(m)
		print("%s: draws %d, body vertices %d, face %d" % [nm, draws, vv.x, vv.y])
	for nm: String in by_name:
		var pair: Array = by_name[nm]
		if pair.size() < 2:
			continue
		var a: Node3D = pair[0]
		var b: Node3D = pair[1]
		_check(_draws(a) == _draws(b), "%s: draw instances differ between the build and the cached instance (%d / %d)" % [
			nm, _draws(a), _draws(b)])
		_check(_verts(a) == _verts(b), "%s: vertices differ between instances" % nm)
		for p: String in SHARED.get(nm, []):
			var ma := a.get_node_or_null(p) as MeshInstance3D
			var mb := b.get_node_or_null(p) as MeshInstance3D
			_check(ma != null and mb != null and ma.mesh == mb.mesh and ma.mesh is ArrayMesh,
				"%s: %s not the shared reshaped mesh" % [nm, p])
	# Team colour: the merged chest (or mount) cloth takes a red variant.
	for m: Node3D in _models:
		m.call(&"set_team_color", Color(0.8, 0.1, 0.1))
	for m: Node3D in _models:
		var mi := m.get_node_or_null("Root/Chest/Merged") as MeshInstance3D
		if mi == null:
			mi = m.get_node_or_null("Root/Mount/Merged") as MeshInstance3D
		var tinted := false
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				var o := mi.get_surface_override_material(s)
				if o and o.has_meta(&"team_base"):
					tinted = true
		_check(tinted, "%s: team colour does not reach the merged body cloth" % _name(m))


func _t2_checks() -> void:
	for g: Node in _world.get_children():
		var nm := _name(g)
		if not nm in ["barrow_ghoul", "hollow_oathsworn"]:
			continue
		var vv := _verts(g)
		var body: int = vv.x + maxi(vv.y - FACE_ALLOW, 0)
		print("%s: draws %d, body vertices %d, face %d" % [nm, _draws(g), vv.x, vv.y])
		_check(body <= 2500, "%s: %d vertices > 2500" % [nm, body])
		_check(_draws(g) <= 14, "%s: %d draw instances > 14" % [nm, _draws(g)])


# ---------------------------------------------------------------- C hooks, D wisps

func _body_alpha(m: Node) -> float:
	var n := m.get_node_or_null(^"Root/Chest/Merged") as GeometryInstance3D
	if n == null:
		n = m.get_node_or_null(^"Root/Mount/Merged") as GeometryInstance3D
	return n.transparency if n else -1.0


func _wisp_setup() -> void:
	for m: Node3D in _models:
		_check(m.find_child("SoulWisps", true, false) == null, "%s: wisps built at the Low tier" % _name(m))
	ShadowModel.wisp_quality_override = 2
	for i: int in SCENES.size():
		var m := _spawn(SCENES[i], Vector3(i * 4.0, 0, -40.0))
		if m:
			m.set(&"offscreen_freeze", true)   # as Unit sets it
			_wisp_models.append(m)
	_cam = Camera3D.new()
	_world.add_child(_cam)
	_cam.global_position = Vector3(8.0, 4.0, -34.0)


func _wisp(m: Node) -> GPUParticles3D:
	return m.find_child("SoulWisps", true, false) as GPUParticles3D


func _process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		3:
			_contract_checks()
			_t2_checks()
			for m: Node3D in _models:
				m.call(&"set_moving", float(m.get(&"stride_speed")))
		40:
			for m: Node3D in _models:
				m.call(&"set_moving", 0.0)
				m.call(&"play_attack")
		70:
			for m: Node3D in _models:
				m.call(&"play_hit")
				m.call(&"play_level_up")
		100:
			for m: Node3D in _models:
				m.call(&"play_death")
		200:
			for i: int in _models.size():
				_check(_deaths[i] == 1, "%s: death_finished %d times" % [_name(_models[i]), _deaths[i]])
				_check(_body_alpha(_models[i]) > 0.95, "%s: body still visible after death" % _name(_models[i]))
				_models[i].call(&"revive")
		215:
			for m: Node3D in _models:
				_check(absf(_body_alpha(m)) < 0.001, "%s: revive did not restore the body" % _name(m))
			_wisp_setup()
		260:
			for m: Node3D in _wisp_models:
				var nm := _name(m)
				var w := _wisp(m)
				if nm in ["shadow_knight", "gloom_thrall"]:
					_check(w != null, "%s: no SoulWisps at High" % nm)
					if w:
						_check(w.emitting, "%s: wisps not emitting with the camera 6 m away" % nm)
						_check(w.amount <= 10, "%s: %d wisps > 10" % [nm, w.amount])
				else:
					_check(w == null, "%s: unexpected SoulWisps" % nm)
			_cam.global_position = Vector3(8.0, 60.0, 30.0)
		320:
			for m: Node3D in _wisp_models:
				var w := _wisp(m)
				if w:
					_check(not w.emitting, "%s: wisps still emitting with the camera 80 m away" % _name(m))
			# Back within 30 m (kit tier 0) but looking away (+Z): the units are behind the camera, off-screen.
			_cam.global_position = Vector3(8.0, 4.0, -34.0)
			_cam.rotation = Vector3(0.0, PI, 0.0)
		350:
			for m: Node3D in _wisp_models:
				var w := _wisp(m)
				if w:
					_check(int(m.get(&"_tier")) == 0, "%s: not kit tier 0 for the off-screen check" % _name(m))
					_check(not w.emitting, "%s: wisps still emitting off-screen within 30 m" % _name(m))
					_check(not bool(m.call(&"wisps_should_emit")), "%s: wisps gate open off-screen" % _name(m))
			_cam.rotation = Vector3.ZERO
		380:
			for m: Node3D in _wisp_models:
				var w := _wisp(m)
				if w:
					_check(w.emitting, "%s: wisps not back on when on-screen again" % _name(m))
		385:
			for m: Node3D in _wisp_models:
				m.call(&"play_death")
		415:
			for m: Node3D in _wisp_models:
				var w := _wisp(m)
				if w:
					_check(not w.emitting, "%s: wisps still emitting while dead" % _name(m))
			ShadowModel.wisp_quality_override = -1
			if _fails.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
			return true
	return false
