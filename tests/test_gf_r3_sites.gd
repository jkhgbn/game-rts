extends SceneTree
## G-F round 3 sites (docs/art/gf_r3_sites.md; docs/art/gf_review3.md top-6 item 4 + the Shadow site regression).
## Run: godot --headless --path . -s tests/test_gf_r3_sites.gd --fixed-fps 60 --quit-after 2400
## Checks, for each kingdom's Hall and small building as a site at 0 % and 30 %:
## - a visible SitePad (lit painted_vc material, every vertex colour value >= 0.2: earth / stone, never black);
## - the scaffold shows from the first frame;
## - the calm outline (SiteOutline: energy <= 0.6, pulse <= 2 rad/s, saturation <= 0.4, value <= 0.7, thin bars);
## - at 0 % no Body mesh shows (no squashed black plinth);
## - nothing floats: every visible mesh piece (a connected component of a merged mesh, a MultiMesh instance) starts
##   <= 0.3 m above the ground or <= 0.3 m above a piece under it.
## Then built: pad and scaffold hidden, outline fades.

const TASK_ID := "gf_r3_sites"
const MODELS := {
	"fire_hall": "res://art/buildings/fire_hall.tscn",
	"ice_hall": "res://art/buildings/ice_hall.tscn",
	"nature_hall": "res://art/buildings/nature_hall.tscn",
	"shadow_hall": "res://art/buildings/shadow_hall.tscn",
	"hearth": "res://art/buildings/hearth.tscn",
	"ice_lodge": "res://art/buildings/ice_lodge.tscn",
	"nature_hollow": "res://art/buildings/nature_hollow.tscn",
	"hovel": "res://art/buildings/hovel.tscn",
}
const FLOAT_MAX := 0.3
const XZ_MARGIN := 0.15

var frame := 0
var world: Node3D
var _m: Dictionary = {}   # name -> model
var _errors: PackedStringArray = PackedStringArray()
var _uf := PackedInt32Array()   # union-find parents (_components)


func _initialize() -> void:
	world = Node3D.new()
	root.add_child(world)
	var x: float = 0.0
	for k: String in MODELS:
		var m := (load(MODELS[k]) as PackedScene).instantiate() as Node3D
		m.name = k
		m.position = Vector3(x, 0, 0)
		world.add_child(m)
		m.call(&"set_construction_progress", 0.0)
		_m[k] = m
		x += 20.0


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 4:
		_check_stage("0%", 0.0)
		for m: Node3D in _m.values():
			m.call(&"set_construction_progress", 0.3)
	if frame == 6:
		_check_stage("30%", 0.3)
		for m: Node3D in _m.values():
			m.call(&"set_construction_progress", 1.0)
	if frame == 60:
		for k: String in _m:
			var m: Node3D = _m[k]
			var pad := m.get_node_or_null(^"SitePad") as Node3D
			_check(pad != null and not pad.visible, "%s built: pad still shown" % k)
			var sc := m.get_node_or_null(^"Scaffold") as Node3D
			_check(sc == null or not sc.visible, "%s built: scaffold still shown" % k)
			var ol := m.get_node_or_null(^"BuildOutline") as Node3D
			_check(ol != null and not ol.visible, "%s built: outline still shown" % k)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		quit(0)
	return false


func _check_stage(stage: String, p: float) -> void:
	for k: String in _m:
		var m: Node3D = _m[k]
		_check_pad(k, m, stage)
		var sc := m.get_node_or_null(^"Scaffold") as Node3D
		_check(sc != null and sc.visible, "%s %s: no scaffold" % [k, stage])
		_check_outline(k, m, stage)
		if p <= 0.0:
			var shown: PackedStringArray = []
			for n: Node in (m.get_node(^"Body") as Node3D).find_children("*", "GeometryInstance3D", true, false):
				if (n is MeshInstance3D or n is MultiMeshInstance3D) and (n as Node3D).is_visible_in_tree():
					shown.append(String(n.name))
			_check(shown.is_empty(), "%s %s: body meshes shown %s" % [k, stage, shown])
		_check_floating(k, m, stage)


func _check_pad(k: String, m: Node3D, stage: String) -> void:
	var pad := m.get_node_or_null(^"SitePad") as Node3D
	_check(pad != null and pad.visible, "%s %s: no visible site pad" % [k, stage])
	if pad == null:
		return
	var meshes: Array[Node] = pad.find_children("*", "MeshInstance3D", true, false)
	if pad is MeshInstance3D:
		meshes.push_front(pad)
	_check(not meshes.is_empty(), "%s %s: site pad has no mesh" % [k, stage])
	for n: Node in meshes:
		var mi := n as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var mat: Material = mi.material_override
			if mat == null:
				mat = mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			var lit: bool = mat is ShaderMaterial and (mat as ShaderMaterial).shader != null \
				and (mat as ShaderMaterial).shader.resource_path.ends_with("painted_vc.gdshader")
			if mat is BaseMaterial3D:
				lit = (mat as BaseMaterial3D).shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED
			_check(lit, "%s %s: pad material is not lit painted (%s)" % [k, stage, mat])
			var cols: Variant = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_COLOR]
			_check(cols is PackedColorArray and (cols as PackedColorArray).size() > 0, "%s: pad has no vertex colours" % k)
			if not (cols is PackedColorArray):
				continue
			var lo: float = 1.0
			for c: Color in cols as PackedColorArray:
				lo = minf(lo, c.v)
			_check(lo >= 0.2, "%s %s: pad colour value %.2f < 0.2" % [k, stage, lo])


func _check_outline(k: String, m: Node3D, stage: String) -> void:
	var ol := m.get_node_or_null(^"BuildOutline") as GeometryInstance3D
	_check(ol != null and ol.visible, "%s %s: no visible outline" % [k, stage])
	var mat := m.get(&"_outline_mat") as ShaderMaterial
	if ol == null or mat == null:
		return
	var e: float = float(mat.get_shader_parameter(&"energy"))
	var ps: float = float(mat.get_shader_parameter(&"pulse_speed"))
	var g: Color = mat.get_shader_parameter(&"glow_color")
	_check(e <= 0.6, "%s %s: outline energy %.2f" % [k, stage, e])
	_check(ps <= 2.0, "%s %s: outline pulse %.2f" % [k, stage, ps])
	_check(g.s <= 0.41 and g.v <= 0.71, "%s %s: outline colour s %.2f v %.2f" % [k, stage, g.s, g.v])
	if ol is MultiMeshInstance3D and (ol as MultiMeshInstance3D).multimesh.mesh:
		var sz: Vector3 = (ol as MultiMeshInstance3D).multimesh.mesh.get_aabb().size
		_check(minf(sz.x, sz.z) <= 0.13, "%s %s: outline bar %.2f m wide" % [k, stage, minf(sz.x, sz.z)])


## Every visible piece in model space; a piece floating more than FLOAT_MAX above the ground and above every piece
## under it is an error.
func _check_floating(k: String, m: Node3D, stage: String) -> void:
	var pieces: Array = []   # [AABB, name]
	var inv: Transform3D = m.global_transform.affine_inverse()
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree() or g.name == &"ContactDecal":
			continue
		if g is MeshInstance3D and (g as MeshInstance3D).mesh:
			for b: AABB in _components((g as MeshInstance3D).mesh, inv * g.global_transform):
				pieces.append([b, String(g.name)])
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh:
			var mm: MultiMesh = (g as MultiMeshInstance3D).multimesh
			if mm.mesh == null:
				continue
			var cnt: int = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			for i: int in cnt:
				pieces.append([(inv * g.global_transform * mm.get_instance_transform(i)) * mm.mesh.get_aabb(), String(g.name)])
	var bad: PackedStringArray = []
	# Grounded = starts <= FLOAT_MAX above the ground, or rests on / hangs from a grounded piece (footprints touching,
	# its bottom at most FLOAT_MAX above that piece's top, that piece not wholly above it): an eave tile hangs on its
	# neighbour, the neighbour on the roof board, the board on the walls.
	var grounded: Array[bool] = []
	var left: Array[int] = []
	for i: int in pieces.size():
		var on: bool = (pieces[i][0] as AABB).position.y <= FLOAT_MAX
		grounded.append(on)
		if not on:
			left.append(i)
	var changed: bool = true
	while changed and not left.is_empty():
		changed = false
		var still: Array[int] = []
		for i: int in left:
			var ab: AABB = pieces[i][0]
			var ok: bool = false
			for j: int in pieces.size():
				if not grounded[j]:
					continue
				var bb: AABB = pieces[j][0]
				if bb.position.y > ab.end.y or ab.position.y - bb.end.y > FLOAT_MAX:
					continue
				if bb.position.x - XZ_MARGIN > ab.end.x or ab.position.x - XZ_MARGIN > bb.end.x:
					continue
				if bb.position.z - XZ_MARGIN > ab.end.z or ab.position.z - XZ_MARGIN > bb.end.z:
					continue
				ok = true
				break
			if ok:
				grounded[i] = true
				changed = true
			else:
				still.append(i)
		left = still
	for i: int in left:
		var ab: AABB = pieces[i][0]
		bad.append("%s@(%.1f,%.2f,%.1f)" % [pieces[i][1], ab.get_center().x, ab.position.y, ab.get_center().z])
	_check(bad.is_empty(), "%s %s: floating pieces %s" % [k, stage, bad.slice(0, 8)])


## AABBs (in `xf` space) of the connected components (shared indices) of every surface of `mesh`.
func _components(mesh: Mesh, xf: Transform3D) -> Array[AABB]:
	var out: Array[AABB] = []
	for s: int in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		var n: int = verts.size()
		_uf.resize(n)
		for i: int in n:
			_uf[i] = i
		var ind: PackedInt32Array = idx if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0 else PackedInt32Array()
		if ind.is_empty():
			ind.resize(n)
			for i: int in n:
				ind[i] = i
		for t: int in range(0, ind.size() - 2, 3):
			var r0: int = _find(ind[t])
			for j: int in [1, 2]:
				var r1: int = _find(ind[t + j])
				if r1 != r0:
					_uf[r1] = r0
		# Weld: a box's faces have their own vertices; the same position = one piece.
		var seen := {}
		for i: int in n:
			var key: Vector3 = verts[i].snapped(Vector3.ONE * 0.001)
			if seen.has(key):
				var r0: int = _find(int(seen[key]))
				var r1: int = _find(i)
				if r1 != r0:
					_uf[r1] = r0
			else:
				seen[key] = i
		var boxes := {}
		for i: int in n:
			var r: int = _find(i)
			var p: Vector3 = xf * verts[i]
			if boxes.has(r):
				var b: AABB = boxes[r]
				boxes[r] = b.expand(p)
			else:
				boxes[r] = AABB(p, Vector3.ZERO)
		for b: AABB in boxes.values():
			out.append(b)
	return out


func _find(i: int) -> int:
	var r: int = i
	while _uf[r] != r:
		r = _uf[r]
	while _uf[i] != r:   # path compression (on the member: a packed array argument would be a copy)
		var nx: int = _uf[i]
		_uf[i] = r
		i = nx
	return r
