extends RefCounted
## Procedural meshes of the cosmetic critters (task 12.V16): bird, butterfly, firefly, dragonfly, frog, splash.
## One small indexed mesh per kind, <= 300 triangles, faces +Z, y up, metres. The vertex data each shader reads is
## documented at the top of its .gdshader (bone / part / side in UV and UV2; colours come from the shader palettes, so
## COLOR stays white). Baked to meshes/*.res by tools/build_critters.gd; CritterSystem builds them here at runtime
## only if a .res is missing. Deterministic (fixed seed), no class_name: `preload(...).new().build(&"bird")`.

var _st: SurfaceTool
var _bone := 0.0
var _part := 0.0
var _side := 0.0
var _rng := RandomNumberGenerator.new()


## The mesh of a kind id (&"bird", &"butterfly", &"firefly", &"dragonfly", &"frog", &"splash"), or null.
func build(kind: StringName) -> ArrayMesh:
	match kind:
		&"bird": return bird()
		&"butterfly": return butterfly()
		&"firefly": return firefly()
		&"dragonfly": return dragonfly()
		&"frog": return frog()
		&"splash": return splash()
	return null


static func triangle_count(mesh: Mesh) -> int:
	var tris := 0
	for s: int in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			tris += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		else:
			tris += idx.size() / 3
	return tris


# ---------------------------------------------------------------- kinds

## ~0.5 m songbird / crow, wings spread in the rest pose (the shader folds them on the ground).
func bird() -> ArrayMesh:
	_begin()
	_bone = 0.0
	var r0 := _ring(Vector3(0, 0.080, -0.10), 0.045, 0.038, 6)
	var r1 := _ring(Vector3(0, 0.088, -0.01), 0.074, 0.064, 6)
	var r2 := _ring(Vector3(0, 0.098, 0.07), 0.064, 0.060, 6)
	_loft_split([r0, r1, r2], 0.0, 1.0, 0.078)
	_fan_split(r0, Vector3(0, 0.082, -0.15), 0.0, 1.0, 0.078)
	_fan_split(r2, Vector3(0, 0.112, 0.118), 0.0, 1.0, 0.078)
	# Head + beak (bone 3: pecks about the neck).
	_bone = 3.0
	_part = 6.0
	_octa(Vector3(0, 0.132, 0.135), 0.044, 0.044, 0.054)
	_part = 4.0
	var bc := Vector3(0, 0.126, 0.178)
	var tip := Vector3(0, 0.118, 0.24)
	var h := 0.018
	var q: Array[Vector3] = [bc + Vector3(-h, h, 0), bc + Vector3(h, h, 0), bc + Vector3(h, -h, 0), bc + Vector3(-h, -h, 0)]
	for i: int in 4:
		_tri(q[i], q[(i + 1) % 4], tip)
	# Tail (bone 4: flicks up).
	_bone = 4.0
	_part = 5.0
	var tl := Vector3(-0.03, 0.086, -0.115)
	var tr := Vector3(0.03, 0.086, -0.115)
	var fl := Vector3(-0.07, 0.094, -0.285)
	var fr := Vector3(0.07, 0.094, -0.285)
	var fm := Vector3(0, 0.092, -0.255)
	_tri(tl, fl, fm)
	_tri(tl, fm, tr)
	_tri(tr, fm, fr)
	# Wings: inner panel (bone 1) + pointed outer panel (bone 2, darker tips).
	for sd: float in [-1.0, 1.0]:
		_side = sd
		var rl := Vector3(sd * 0.04, 0.105, 0.05)
		var rt := Vector3(sd * 0.04, 0.10, -0.075)
		var el := Vector3(sd * 0.18, 0.11, 0.035)
		var et := Vector3(sd * 0.18, 0.105, -0.095)
		var wtip := Vector3(sd * 0.35, 0.11, -0.05)
		var wm := Vector3(sd * 0.28, 0.105, -0.12)
		_bone = 1.0
		_part = 2.0
		_quad(rl, el, et, rt)
		_bone = 2.0
		_part = 3.0
		_tri(el, wtip, wm)
		_tri(el, wm, et)
	_side = 0.0
	return _finish()


## ~0.44 m wingspan: thin body, fan-shaped fore / hind wings flat in XZ (the shader raises them about the body axis).
func butterfly() -> ArrayMesh:
	_begin()
	_bone = 0.0
	_part = 0.0
	_tube(Vector3(0, 0, -0.075), Vector3(0, 0, 0.055), 0.016, 0.012, 4, 0.0)
	_octa(Vector3(0, 0, 0.07), 0.016, 0.016, 0.016)
	for sd: float in [-1.0, 1.0]:
		_side = sd
		_bone = 1.0
		_part = 1.0
		var root := Vector3(sd * 0.008, 0, 0.025)
		var fore: Array[Vector3] = [Vector3(0.05, 0, 0.105), Vector3(0.13, 0, 0.14), Vector3(0.205, 0, 0.12),
			Vector3(0.22, 0, 0.065), Vector3(0.175, 0, 0.02), Vector3(0.08, 0, 0.005)]
		_wing_fan(root, fore, sd)
		_bone = 2.0
		_part = 2.0
		var root2 := Vector3(sd * 0.008, 0, 0.0)
		var hind: Array[Vector3] = [Vector3(0.085, 0, 0.0), Vector3(0.15, 0, -0.03), Vector3(0.155, 0, -0.085),
			Vector3(0.115, 0, -0.135), Vector3(0.06, 0, -0.14), Vector3(0.02, 0, -0.085)]
		_wing_fan(root2, hind, sd)
	_side = 0.0
	return _finish()


## A unit quad (the shader turns it to the camera and sizes it).
func firefly() -> ArrayMesh:
	_begin()
	var uvs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var pts: Array[Vector3] = [Vector3(-1, -1, 0), Vector3(1, -1, 0), Vector3(1, 1, 0), Vector3(-1, 1, 0)]
	for t: Array in [[0, 1, 2], [0, 2, 3]]:
		for k: int in t:
			_st.set_color(Color.WHITE)
			_st.set_uv(uvs[k])
			_st.set_uv2(Vector2.ZERO)
			_st.add_vertex(pts[k])
	return _finish()


## ~0.42 m long: thorax, big eyes, long ringed abdomen, 4 long wings (bone 1 fore, 2 hind).
func dragonfly() -> ArrayMesh:
	_begin()
	_bone = 0.0
	_part = 0.0
	var t0 := _ring(Vector3(0, 0, -0.035), 0.02, 0.02, 5)
	var t1 := _ring(Vector3(0, 0.004, 0.015), 0.03, 0.032, 5)
	var t2 := _ring(Vector3(0, 0.002, 0.06), 0.022, 0.022, 5)
	_loft([t0, t1, t2])
	_fan(t2, Vector3(0, 0.0, 0.07))
	_part = 3.0
	_octa(Vector3(-0.022, 0.012, 0.082), 0.024, 0.022, 0.022)
	_octa(Vector3(0.022, 0.012, 0.082), 0.024, 0.022, 0.022)
	# Abdomen: 4 segments, alternating colour / dark ring.
	var z := -0.035
	var r := 0.013
	for i: int in 4:
		_part = 1.0 if i % 2 == 0 else 2.0
		var z1 := z - 0.08
		var r1 := r - 0.0012
		_tube(Vector3(0, 0, z), Vector3(0, 0, z1), r, r1, 4, 0.0, i == 3)
		z = z1
		r = r1
	# Wings.
	_part = 4.0
	for sd: float in [-1.0, 1.0]:
		_side = sd
		_bone = 1.0
		_span_fan([Vector3(0.015, 0.02, 0.045), Vector3(0.12, 0.02, 0.06), Vector3(0.24, 0.02, 0.052),
			Vector3(0.252, 0.02, 0.037), Vector3(0.12, 0.02, 0.024), Vector3(0.015, 0.02, 0.03)], sd)
		_bone = 2.0
		_span_fan([Vector3(0.015, 0.02, 0.012), Vector3(0.11, 0.02, 0.02), Vector3(0.232, 0.02, 0.013),
			Vector3(0.238, 0.02, -0.006), Vector3(0.11, 0.02, -0.028), Vector3(0.015, 0.02, -0.006)], sd)
	_side = 0.0
	return _finish()


## ~0.3 m frog sitting up: body, eye bumps, folded hind legs (thigh / shin + webbed foot), front legs, throat.
func frog() -> ArrayMesh:
	_begin()
	_rng.seed = 12016
	_bone = 0.0
	var ra := _ring(Vector3(0, 0.055, -0.105), 0.05, 0.04, 6)
	var rb := _ring(Vector3(0, 0.08, -0.04), 0.085, 0.062, 6)
	var rc := _ring(Vector3(0, 0.092, 0.035), 0.082, 0.056, 6)
	var rd := _ring(Vector3(0, 0.08, 0.10), 0.06, 0.038, 6)
	var rings: Array = [ra, rb, rc, rd]
	for i: int in rings.size() - 1:
		_frog_band(rings[i], rings[i + 1])
	_frog_cap(ra, Vector3(0, 0.05, -0.13))
	_frog_cap(rd, Vector3(0, 0.072, 0.148))
	# Eyes.
	_bone = 0.0
	_part = 2.0
	for sd: float in [-1.0, 1.0]:
		_side = sd
		_octa(Vector3(sd * 0.048, 0.126, 0.072), 0.026, 0.026, 0.026)
	# Legs.
	_part = 3.0
	for sd: float in [-1.0, 1.0]:
		_side = sd
		var right := 1.0 if sd > 0.0 else 0.0
		var hip := Vector3(sd * 0.06, 0.06, -0.07)
		var knee := Vector3(sd * 0.115, 0.045, 0.015)
		var ankle := Vector3(sd * 0.085, 0.02, -0.095)
		_bone = 1.0 + right
		_tube(hip, knee, 0.03, 0.022, 5, 0.0)
		_bone = 3.0 + right
		_tube(knee, ankle, 0.02, 0.014, 4, 0.0)
		var t1 := Vector3(sd * 0.105, 0.004, 0.02)
		var t2 := Vector3(sd * 0.14, 0.004, 0.005)
		var t3 := Vector3(sd * 0.07, 0.004, 0.01)
		_tri(ankle, t1, t2)
		_tri(ankle, t3, t1)
		_bone = 5.0 + right
		var sh := Vector3(sd * 0.055, 0.06, 0.06)
		var hand := Vector3(sd * 0.07, 0.008, 0.10)
		_tube(sh, hand, 0.014, 0.011, 4, 0.0)
		_tri(hand, Vector3(sd * 0.05, 0.003, 0.13), Vector3(sd * 0.095, 0.003, 0.125))
	_side = 0.0
	return _finish()


## Splash kit: 2 ripple events (each 2 concentric rings), 2 x 6 droplets, and a small fish.
func splash() -> ArrayMesh:
	_begin()
	_bone = 0.0
	for ev: int in 2:
		_part = 1.0 + float(ev)
		_annulus(1.0, 0.84, 18)
		_annulus(0.58, 0.47, 14)
	for ev: int in 2:
		_part = 3.0 + float(ev)
		for i: int in 6:
			_bone = float(i)   # UV.x = droplet index
			var top := Vector3(0, 0.06, 0)
			var bot := Vector3(0, -0.03, 0)
			var lf := Vector3(-0.024, 0.012, 0)
			var rt := Vector3(0.024, 0.012, 0)
			_tri(top, rt, bot)
			_tri(top, bot, lf)
	_bone = 0.0
	_part = 5.0
	var f0 := _ring(Vector3(0, 0, -0.12), 0.02, 0.028, 5)
	var f1 := _ring(Vector3(0, 0.004, 0.0), 0.034, 0.05, 5)
	var f2 := _ring(Vector3(0, 0.002, 0.1), 0.028, 0.04, 5)
	_loft([f0, f1, f2])
	_fan(f0, Vector3(0, 0, -0.15))
	_fan(f2, Vector3(0, 0, 0.18))
	_tri(Vector3(0, 0, -0.14), Vector3(0, 0.07, -0.235), Vector3(0, -0.07, -0.235))
	_tri(Vector3(0, 0.045, 0.03), Vector3(0, 0.088, -0.025), Vector3(0, 0.04, -0.065))
	return _finish()


# ---------------------------------------------------------------- helpers

func _begin() -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st.set_smooth_group(-1)   # flat faces: chunky painted facets
	_bone = 0.0
	_part = 0.0
	_side = 0.0


func _finish() -> ArrayMesh:
	_st.generate_normals()
	_st.index()
	return _st.commit()


func _v(p: Vector3, uvy: float) -> void:
	_st.set_color(Color.WHITE)
	_st.set_uv(Vector2(_bone, uvy))
	_st.set_uv2(Vector2(_part, _side))
	_st.add_vertex(p)


func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	_v(a, a.y)
	_v(b, b.y)
	_v(c, c.y)


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(a, b, c)
	_tri(a, c, d)


## A ring of n points around `c` in the plane z = c.z (vertex 0 on top).
func _ring(c: Vector3, rx: float, ry: float, n: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i: int in n:
		var a := TAU * float(i) / float(n)
		out.append(c + Vector3(sin(a) * rx, cos(a) * ry, 0.0))
	return out


func _loft(rings: Array) -> void:
	for k: int in rings.size() - 1:
		var a: PackedVector3Array = rings[k]
		var b: PackedVector3Array = rings[k + 1]
		var n := a.size()
		for i: int in n:
			var j := (i + 1) % n
			_quad(a[i], a[j], b[j], b[i])


func _fan(ring: PackedVector3Array, apex: Vector3) -> void:
	var n := ring.size()
	for i: int in n:
		_tri(ring[i], ring[(i + 1) % n], apex)


## Loft / fan whose faces below `split_y` take the belly part.
func _loft_split(rings: Array, top_part: float, belly_part: float, split_y: float) -> void:
	for k: int in rings.size() - 1:
		var a: PackedVector3Array = rings[k]
		var b: PackedVector3Array = rings[k + 1]
		var n := a.size()
		for i: int in n:
			var j := (i + 1) % n
			var cy := (a[i].y + a[j].y + b[i].y + b[j].y) * 0.25
			_part = belly_part if cy < split_y else top_part
			_quad(a[i], a[j], b[j], b[i])


func _fan_split(ring: PackedVector3Array, apex: Vector3, top_part: float, belly_part: float, split_y: float) -> void:
	var n := ring.size()
	for i: int in n:
		var j := (i + 1) % n
		_part = belly_part if (ring[i].y + ring[j].y + apex.y) / 3.0 < split_y else top_part
		_tri(ring[i], ring[j], apex)


## Frog body band: back (with a few dark spots) above the flank line, belly below; belly faces near the chin = throat.
func _frog_band(a: PackedVector3Array, b: PackedVector3Array) -> void:
	var n := a.size()
	for i: int in n:
		var j := (i + 1) % n
		var cy := (a[i].y + a[j].y + b[i].y + b[j].y) * 0.25
		var cz := (a[i].z + b[i].z) * 0.5
		var mid_y := (a[0].y + a[n / 2].y + b[0].y + b[n / 2].y) * 0.25
		if cy < mid_y - 0.008:
			_part = 1.0
			_bone = 7.0 if cz > 0.03 else 0.0
		else:
			_part = 4.0 if _rng.randf() < 0.3 else 0.0
			_bone = 0.0
		_quad(a[i], a[j], b[j], b[i])
	_bone = 0.0


func _frog_cap(ring: PackedVector3Array, apex: Vector3) -> void:
	var n := ring.size()
	var mid_y := (ring[0].y + ring[n / 2].y) * 0.5
	for i: int in n:
		var j := (i + 1) % n
		var cy := (ring[i].y + ring[j].y + apex.y) / 3.0
		_part = 1.0 if cy < mid_y - 0.006 else 0.0
		_bone = 7.0 if _part == 1.0 and apex.z > 0.0 else 0.0
		_tri(ring[i], ring[j], apex)
	_bone = 0.0


func _octa(c: Vector3, rx: float, ry: float, rz: float) -> void:
	var px := c + Vector3(rx, 0, 0)
	var nx := c - Vector3(rx, 0, 0)
	var py := c + Vector3(0, ry, 0)
	var ny := c - Vector3(0, ry, 0)
	var pz := c + Vector3(0, 0, rz)
	var nz := c - Vector3(0, 0, rz)
	for pair: Array in [[px, pz], [pz, nx], [nx, nz], [nz, px]]:
		_tri(py, pair[0], pair[1])
		_tri(ny, pair[1], pair[0])


## A tube of n sides from a to b (radii r0 -> r1), capped at both ends (or only the start when open_end is false).
func _tube(a: Vector3, b: Vector3, r0: float, r1: float, n: int, twist: float, cap_end := true) -> void:
	var axis := (b - a).normalized()
	var ref := Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var u := axis.cross(ref).normalized()
	var w := axis.cross(u).normalized()
	var ra := PackedVector3Array()
	var rb := PackedVector3Array()
	for i: int in n:
		var ang := TAU * float(i) / float(n) + twist
		var d := u * cos(ang) + w * sin(ang)
		ra.append(a + d * r0)
		rb.append(b + d * r1)
	_loft([ra, rb])
	_fan(ra, a - axis * r0 * 0.4)
	if cap_end:
		_fan(rb, b + axis * r1 * 0.6)


## Butterfly wing fan: root -> rim points (mirrored by sd); UV.y = 0 at the root, 1 on the rim.
func _wing_fan(root: Vector3, rim: Array[Vector3], sd: float) -> void:
	for i: int in rim.size() - 1:
		var a := Vector3(rim[i].x * sd, rim[i].y, rim[i].z)
		var b := Vector3(rim[i + 1].x * sd, rim[i + 1].y, rim[i + 1].z)
		_v(root, 0.0)
		_v(a, 1.0)
		_v(b, 1.0)


## Dragonfly wing outline (first point = the root): a fan from the root; UV.y = the span fraction.
func _span_fan(pts: Array, sd: float) -> void:
	var root: Vector3 = pts[0]
	root.x *= sd
	for i: int in range(1, pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		a.x *= sd
		b.x *= sd
		_v(root, 0.0)
		_v(a, absf(a.x) / 0.25)
		_v(b, absf(b.x) / 0.25)


func _annulus(r_out: float, r_in: float, n: int) -> void:
	for i: int in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		var o0 := Vector3(cos(a0) * r_out, 0, sin(a0) * r_out)
		var o1 := Vector3(cos(a1) * r_out, 0, sin(a1) * r_out)
		var i0 := Vector3(cos(a0) * r_in, 0, sin(a0) * r_in)
		var i1 := Vector3(cos(a1) * r_in, 0, sin(a1) * r_in)
		# UV.y across the ring: 0 on the inner edge, 1 on the outer (the shader softens both edges).
		for v: Array in [[o0, 1.0], [o1, 1.0], [i1, 0.0], [o0, 1.0], [i1, 0.0], [i0, 0.0]]:
			_v(v[0], v[1])
