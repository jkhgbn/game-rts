extends SceneTree
## Task 10.V10: bakes the road waystone mesh art/environment/meshes/waystone.res (run once, headless is fine):
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://art/buildings/trade_post/build_waystone.gd
## Same format as the other environment props (art/environment/build_env.gd): ONE surface with the shared
## art/environment/env_painted_mat.tres, colour blocks in COLOR.rgb, height gradient in COLOR.a, UV = (sway 0,
## local height), flat shaded, indexed (so it can also be merged). The env shader adds a per-instance value shift from
## the world position, so a MultiMesh of them never looks copy-pasted.
## Look: a squat hand-hewn marker stone (~1.0 m, 0.5 x 0.34 m at the foot), a dark carved ring at two thirds of its
## height and an ochre-painted crown (the road colour of the minimap, so from the high camera the road reads as a row of
## small ochre dots), leaning a little, three half-sunk mossy stones at its foot. Origin = foot centre on the ground.

const MESH_PATH := "res://art/environment/meshes/waystone.res"
const MAT_PATH := "res://art/environment/env_painted_mat.tres"

const STONE := Color(0.57, 0.52, 0.44)
const STONE_D := Color(0.33, 0.31, 0.29)
const OCHRE := Color(0.84, 0.58, 0.22)
const MOSS := Color(0.28, 0.41, 0.17)

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _conv: float = 1.0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/environment/meshes/"))
	_detect_winding()
	_build()
	quit()


func _build() -> void:
	# Main stone: 6-sided tapered body in rings, a slight lean toward +x, a rounded pointed crown.
	var rings: Array = [
		# [y, half width x, half depth z, x shift, colour]
		[-0.10, 0.27, 0.18, 0.0, STONE_D],
		[0.12, 0.26, 0.175, 0.005, STONE],
		[0.60, 0.235, 0.16, 0.03, STONE],
		[0.64, 0.25, 0.172, 0.032, STONE_D],   # carved ring (sticks out a little: reads as a band)
		[0.72, 0.25, 0.172, 0.036, STONE_D],
		[0.76, 0.225, 0.155, 0.038, STONE],
		[0.86, 0.21, 0.145, 0.043, OCHRE],     # painted crown starts here
		[0.96, 0.15, 0.105, 0.048, OCHRE],
	]
	var sides: int = 6
	var pts: Array = []   # per ring: PackedVector3Array of `sides` points
	for r: Array in rings:
		var ring := PackedVector3Array()
		for i: int in sides:
			var a: float = TAU * float(i) / float(sides) + 0.26
			var j: float = 1.0 + (_h(Vector3(i, float(r[0]) * 7.0, 1.0)) - 0.5) * 0.12
			ring.append(Vector3(cos(a) * float(r[1]) * j + float(r[3]), float(r[0]), sin(a) * float(r[2]) * j))
		pts.append(ring)
	for k: int in rings.size() - 1:
		var col: Color = rings[k][4]
		if k == 3:
			col = STONE_D
		elif k == 6:
			col = OCHRE
		for i: int in sides:
			var i2: int = (i + 1) % sides
			var a0: Vector3 = pts[k][i]
			var b0: Vector3 = pts[k][i2]
			var a1: Vector3 = pts[k + 1][i]
			var b1: Vector3 = pts[k + 1][i2]
			var out := Vector3((a0.x + b0.x) * 0.5, 0.0, (a0.z + b0.z) * 0.5)
			_quad(a0, b0, b1, a1, out, col)
	# Crown: fan to an off-centre apex (a hewn point, not a pyramid).
	var top: PackedVector3Array = pts[rings.size() - 1]
	var apex := Vector3(0.07, 1.05, 0.015)
	for i: int in sides:
		var a: Vector3 = top[i]
		var b: Vector3 = top[(i + 1) % sides]
		var mid: Vector3 = (a + b) * 0.5
		_tri(a, b, apex, Vector3(mid.x - apex.x, 0.6, mid.z - apex.z), OCHRE)
	# Three half-sunk foot stones with moss on top.
	var feet: Array = [[Vector3(0.30, -0.02, 0.14), 0.15], [Vector3(-0.27, -0.03, 0.10), 0.12],
		[Vector3(0.02, -0.03, -0.26), 0.13]]
	for f: Array in feet:
		_rock(f[0], f[1])
	_commit()


## A low faceted rock (7 x 4 sphere squashed) at `c`, radius `r`: dark stone, mossy top.
func _rock(c: Vector3, r: float) -> void:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 7
	sph.rings = 4
	var arr: Array = sph.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var xf := Transform3D(Basis(Vector3.UP, c.x * 9.0).scaled(Vector3(1.25, 0.6, 1.0)), c)
	var tv := PackedVector3Array()
	tv.resize(v.size())
	for i: int in v.size():
		tv[i] = xf * v[i] + (Vector3(_h(v[i] + c), _h(v[i] * 1.7 + c), _h(v[i] * 2.3 + c)) - Vector3.ONE * 0.5) * r * 0.25
	for t: int in range(0, idx.size(), 3):
		var a: Vector3 = tv[idx[t]]
		var b: Vector3 = tv[idx[t + 1]]
		var d: Vector3 = tv[idx[t + 2]]
		var hint: Vector3 = xf.basis * (n[idx[t]] + n[idx[t + 1]] + n[idx[t + 2]])
		var fn: Vector3 = (b - a).cross(d - a)
		if fn.length_squared() < 1e-12:
			continue
		fn = fn.normalized()
		if fn.dot(hint) < 0.0:
			fn = -fn
		var col: Color = STONE_D.lerp(MOSS, 0.75) if fn.y > 0.6 else STONE_D
		_tri(a, b, d, hint, col)


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, out: Vector3, col: Color) -> void:
	_tri(a, b, c, out, col)
	_tri(a, c, d, out, col)


## Adds a flat triangle facing along `hint` (winding fixed like Godot's primitives), value-jittered per face.
func _tri(a: Vector3, b: Vector3, c: Vector3, hint: Vector3, col: Color) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if fn.length_squared() < 1e-12:
		return
	fn = fn.normalized()
	var s: float = 1.0 if fn.dot(hint) >= 0.0 else -1.0
	if s != _conv:
		var tmp: Vector3 = b
		b = c
		c = tmp
	fn *= s
	var k: float = 1.0 + (_h((a + b + c).snappedf(0.01)) - 0.5) * 0.12
	var fc := Color(col.r * k, col.g * k, col.b * k)
	for p: Vector3 in [a, b, c]:
		_v.append(p)
		_n.append(fn)
		_c.append(fc)


func _commit() -> void:
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span: float = maxf(maxy - miny, 0.01)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in _v.size():
		var cc: Color = _c[i]
		cc.a = (_v[i].y - miny) / span
		st.set_color(cc)
		st.set_normal(_n[i])
		st.set_uv(Vector2(0.0, _v[i].y))
		st.add_vertex(_v[i])
	st.index()
	var mesh: ArrayMesh = st.commit()
	var mat: Material = load(MAT_PATH) as Material
	mesh.surface_set_material(0, mat)
	mesh.resource_name = "waystone"
	var err: int = ResourceSaver.save(mesh, MESH_PATH, ResourceSaver.FLAG_CHANGE_PATH)
	print("waystone: %d tris, y %.2f..%.2f, save err %d" % [_v.size() / 3, miny, maxy, err])


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)
