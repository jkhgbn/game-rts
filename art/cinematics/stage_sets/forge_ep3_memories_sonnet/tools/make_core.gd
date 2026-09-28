extends SceneTree
## forge_ep3_memories_sonnet generator core (tech-art tool): baked-light low-poly helpers (0 real lights).
## Chain: make_core -> make_g03 -> make_g04 -> make_g09 -> make_parts (run this one).

const DIR := "res://art/cinematics/stage_sets/forge_ep3_memories_sonnet"
const PARTS := DIR + "/parts"
const MATS := PARTS + "/materials"
const FSet := preload("res://tools/world_forge/forge_set.gd")

var mats := {}
var sts := {}
var off := Vector3.ZERO
var lights: Array = []
var occ: Array = []
var moon_dir := Vector3(-0.35, 0.42, -0.83).normalized()
var moon_col := Color(0.5, 0.65, 1.0)
var fill_dir := Vector3(-0.3, 0.5, 0.8).normalized()
var fill_col := Color(0.1, 0.12, 0.2)
var amb_top := Color(0.3, 0.36, 0.55)
var amb_bot := Color(0.14, 0.16, 0.26)
var grime := 0.0
var cell := 0.32
var seedv := 1
var mounds: Array = []


func _sm(sh: String, prio := 0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(MATS + "/" + sh)
	m.render_priority = prio
	return m


func _materials() -> void:
	var lit := StandardMaterial3D.new()
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lit.vertex_color_use_as_albedo = true
	ResourceSaver.save(lit, MATS + "/ep3_lit.tres")
	mats["lit"] = load(MATS + "/ep3_lit.tres")
	var defs := {"glow": _sm("ep3_glow.gdshader"), "pulse": _sm("ep3_pulse.gdshader"), "halo": _sm("ep3_halo.gdshader", 2),
		"hpulse": _sm("ep3_halo_pulse.gdshader", 2), "mist": _sm("ep3_mist.gdshader", 1)}
	for k: String in defs:
		ResourceSaver.save(defs[k], "%s/ep3_%s.tres" % [MATS, k])
		mats[k] = load("%s/ep3_%s.tres" % [MATS, k])


func _light_preset() -> void:
	var p: LightingPreset = FSet.mood_preset("nightfall")
	var sky := p.environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = Color(0.015, 0.025, 0.07)
	sky.sky_horizon_color = Color(0.09, 0.11, 0.22)
	sky.ground_horizon_color = Color(0.05, 0.06, 0.12)
	sky.ground_bottom_color = Color(0.02, 0.02, 0.05)
	var env := p.environment
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 0.5
	env.fog_depth_begin = 14.0
	env.fog_depth_end = 70.0
	env.fog_depth_curve = 1.4
	env.fog_light_color = Color(0.06, 0.08, 0.16)
	env.fog_sky_affect = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 1.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.1
	p.sun_color = Color(0.5, 0.62, 1.0)
	p.sun_energy = 0.7
	p.sun_rotation_degrees = Vector3(-35.0, 160.0, 0.0)
	p.fill_color = Color(1.0, 0.7, 0.5)
	p.fill_energy = 0.35
	p.fill_rotation_degrees = Vector3(-15.0, -10.0, 0.0)
	p.vignette_color = Color(0.0, 0.0, 0.02)
	p.vignette_strength = 0.55
	ResourceSaver.save(p, MATS + "/ep3_night.tres")


func _st(key: String) -> SurfaceTool:
	if not sts.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts[key] = st
	return sts[key]


func _part(name: String, build: Callable) -> void:
	sts.clear()
	lights = []
	occ = []
	mounds = []
	off = Vector3.ZERO
	grime = 0.0
	build.call()
	var mesh := ArrayMesh.new()
	var tris := 0
	for key: String in ["lit", "glow", "pulse", "mist", "halo", "hpulse"]:
		if not sts.has(key):
			continue
		var arr := (sts[key] as SurfaceTool).commit_to_arrays()
		tris += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mats[key])
	var mp := "%s/%s.res" % [PARTS, name]
	ResourceSaver.save(mesh, mp, ResourceSaver.FLAG_COMPRESS)
	mesh.take_over_path(mp)
	var n := Node3D.new()
	n.name = name
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	n.add_child(mi)
	mi.owner = n
	var ps := PackedScene.new()
	ps.pack(n)
	ResourceSaver.save(ps, "%s/%s.tscn" % [PARTS, name])
	n.free()
	print("PART %s surfaces=%d tris=%d aabb=%s" % [name, mesh.get_surface_count(), tris, mesh.get_aabb()])


static func h01(a: float, b: float, s: int) -> float:
	var h := int(floor(a * 131.0)) * 73856093 ^ int(floor(b * 137.0)) * 19349663 ^ s * 83492791
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0


# ------------------------------------------------------------------ baked lighting

func add_light(p: Vector3, c: Color, e: float, r: float, sh := true) -> void:
	lights.append({"p": p + off, "c": c, "e": e, "r": r, "sh": sh, "occ": []})


func occl(c: Vector3, h: Vector3) -> void:
	var hh := (h - Vector3(0.03, 0.03, 0.03)).max(Vector3(0.01, 0.01, 0.01))
	occ.append(AABB(c + off - hh, hh * 2.0))


func prep() -> void:
	for L: Dictionary in lights:
		var lst: Array = []
		for bb: AABB in occ:
			if bb.get_center().distance_to(L["p"]) < L["r"] + 1.0:
				lst.append(bb)
		L["occ"] = lst


func _hit(a: Vector3, b: Vector3, list: Array) -> bool:
	for bb: AABB in list:
		if bb.intersects_segment(a, b):
			return true
	return false


func shade(p: Vector3, n: Vector3, base: Color) -> Color:
	var c := amb_bot.lerp(amb_top, n.y * 0.5 + 0.5)
	var mk := n.dot(moon_dir) * 0.85 + 0.15
	if mk > 0.0:
		var q := p + n * 0.05
		if not _hit(q, q + moon_dir * 12.0, occ):
			c += moon_col * mk * 0.55
	c += fill_col * maxf(n.dot(fill_dir), 0.0)
	c *= 0.58
	for L: Dictionary in lights:
		var d: Vector3 = L["p"] - p
		var dist := d.length()
		if dist >= L["r"]:
			continue
		var lam := clampf(n.dot(d / dist) * 0.65 + 0.35, 0.0, 1.0)
		if lam <= 0.0:
			continue
		var f := 1.0 - dist / float(L["r"])
		var k: float = lam * f * f * float(L["e"])
		if L["sh"] and k > 0.02:
			var q := p + n * 0.06
			if _hit(q, L["p"], L["occ"]):
				k *= 0.1
		c += (L["c"] as Color) * k
	var g := 1.0
	if grime > 0.0:
		g = lerpf(1.0 - 0.45 * grime, 1.0, clampf(p.y / 0.5, 0.0, 1.0))
	var m := 0.84 + 0.3 * h01(p.x * 2.3 + p.y * 1.7, p.z * 2.1 + p.y * 2.9, seedv)
	c = c.clamp(Color(0, 0, 0), Color(1.7, 1.7, 1.7))
	return Color(base.r * c.r * m * g, base.g * c.g * m * g, base.b * c.b * m * g, base.a)


func _emit(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, n: Vector3) -> void:
	for pv: Array in [[a, ca], [c, cc], [b, cb]]:
		st.set_color(pv[1])
		st.set_normal(n)
		st.add_vertex(pv[0])


func tg(key: String, a: Vector3, b: Vector3, c: Vector3, base: Color, nfix := Vector3.ZERO) -> void:
	var cr := (b - a).cross(c - a)
	if cr.length() < 1e-7:
		return
	var n := cr.normalized() if nfix == Vector3.ZERO else nfix
	_emit(_st(key), a, b, c, shade(a, n, base), shade(b, n, base), shade(c, n, base), cr.normalized())


func qg(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, base: Color) -> void:
	var cr := (b - a).cross(c - a)
	if cr.length() < 1e-7:
		cr = (c - a).cross(d - a)
		if cr.length() < 1e-7:
			return
	var n := cr.normalized()
	var nu := clampi(ceili(a.distance_to(b) / cell), 1, 30)
	var nv := clampi(ceili(a.distance_to(d) / cell), 1, 30)
	var pts := PackedVector3Array()
	var cols := PackedColorArray()
	for j in nv + 1:
		for i in nu + 1:
			var u := float(i) / nu
			var v := float(j) / nv
			var p := a.lerp(b, u).lerp(d.lerp(c, u), v)
			pts.append(p)
			cols.append(shade(p, n, base))
	var st := _st(key)
	for j in nv:
		for i in nu:
			var i0 := j * (nu + 1) + i
			var i1 := i0 + 1
			var i2 := i0 + nu + 2
			var i3 := i0 + nu + 1
			_emit(st, pts[i0], pts[i1], pts[i2], cols[i0], cols[i1], cols[i2], n)
			_emit(st, pts[i0], pts[i2], pts[i3], cols[i0], cols[i2], cols[i3], n)


## Quad oriented to face `towards`.
func qo(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, base: Color, towards: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.dot(towards - a) < 0.0:
		qg(key, a, d, c, b, base)
	else:
		qg(key, a, b, c, d, base)


# ------------------------------------------------------------------ primitives

func T(x: float, y: float, z: float, yaw := 0.0, tilt := Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(tilt.x, yaw, tilt.z)), Vector3(x, y, z) + off)


func box(xf: Transform3D, c: Vector3, h: Vector3, col: Color, key := "lit") -> void:
	var p := func(x: float, y: float, z: float) -> Vector3: return xf * (c + Vector3(x * h.x, y * h.y, z * h.z))
	qg(key, p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1), col)
	qg(key, p.call(1, -1, -1), p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(1, 1, -1), col)
	qg(key, p.call(1, -1, 1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(1, 1, 1), col)
	qg(key, p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1), col)
	qg(key, p.call(-1, 1, 1), p.call(1, 1, 1), p.call(1, 1, -1), p.call(-1, 1, -1), col)
	if (xf * (c - Vector3(0, h.y, 0))).y > off.y + 0.08:
		qg(key, p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, -1, 1), p.call(-1, -1, 1), col)


func cyl(xf: Transform3D, c: Vector3, r0: float, r1: float, h: float, sides: int, col: Color, caps := true, key := "lit") -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector3(sin(a0), 0, cos(a0))
		var d1 := Vector3(sin(a1), 0, cos(a1))
		var b0 := xf * (c + d0 * r0)
		var b1 := xf * (c + d1 * r0)
		var t0 := xf * (c + d0 * r1 + Vector3(0, h, 0))
		var t1 := xf * (c + d1 * r1 + Vector3(0, h, 0))
		qg(key, b0, b1, t1, t0, col)
		if caps and r1 > 0.001:
			tg(key, xf * (c + Vector3(0, h, 0)), t0, t1, col)


func blob(xf: Transform3D, c: Vector3, r: Vector3, col: Color, sd := 0, rings := 4, segs := 7, jit := 0.28, half := true, key := "lit") -> void:
	var maxk := rings if not half else int(rings * 0.6)
	var grid: Array = []
	for k in maxk + 1:
		var phi := PI * k / rings
		var row: Array = []
		for i in segs:
			var th := TAU * i / segs
			var j := 1.0 + jit * (h01(float(i), float(k), sd) - 0.5) * 2.0
			if k == 0:
				j = 1.0
			row.append(xf * (c + Vector3(sin(phi) * sin(th) * r.x, cos(phi) * r.y, sin(phi) * cos(th) * r.z) * j))
		grid.append(row)
	for k in maxk:
		for i in segs:
			var i2 := (i + 1) % segs
			var a: Vector3 = grid[k + 1][i]
			var b: Vector3 = grid[k + 1][i2]
			var cc: Vector3 = grid[k][i2]
			var d: Vector3 = grid[k][i]
			var tone := col.lerp(col.darkened(0.25), h01(float(i), float(k), sd + 9))
			tg(key, a, b, cc, tone)
			tg(key, a, cc, d, tone)


func _by(d: Vector3) -> Basis:
	var y := d.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	return Basis(x, y, x.cross(y))


func limb(p0: Vector3, dir: Vector3, len: float, r0: float, r1: float, col: Color, sd: int, depth: int) -> void:
	var segs := 3
	var p := p0
	var d := dir
	var r := r0
	for i in segs:
		d = (d + Vector3(h01(float(i), float(depth), sd) - 0.5, 0.06, h01(float(depth), float(i), sd + 3) - 0.5) * 0.7).normalized()
		var rr := lerpf(r0, r1, float(i + 1) / segs)
		var sl := len / segs
		cyl(Transform3D(_by(d), p + off), Vector3.ZERO, r, rr, sl, 5, col, false)
		p += d * sl
		r = rr
		if depth < 2 and i > 0 and h01(float(i), float(depth), sd + 7) > 0.35:
			var side := Vector3(h01(float(i), 1.0, sd + depth) - 0.5, 0.35, h01(float(i), 2.0, sd + depth) - 0.5).normalized()
			limb(p, (d + side * 1.1).normalized(), len * 0.55, r * 0.7, r * 0.2, col, sd + 11 * (i + 1), depth + 1)


func halo(c: Vector3, s: float, col: Color, mode := 0.0, key := "halo") -> void:
	var st := _st(key)
	var p := c + off
	var corners := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i: int in [0, 2, 1, 0, 3, 2]:
		st.set_color(col)
		st.set_normal(Vector3.UP)
		st.set_uv(corners[i])
		st.set_uv2(Vector2(s, mode))
		st.add_vertex(p)


func mist(c: Vector3, s: float, col: Color, drift := 0.3) -> void:
	halo(c, s, col, drift, "mist")


func pool(c: Vector3, r: float, col: Color, key := "halo") -> void:
	var st := _st(key)
	var corners := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i: int in [0, 2, 1, 0, 3, 2]:
		var uv: Vector2 = corners[i]
		st.set_color(col)
		st.set_normal(Vector3.UP)
		st.set_uv(uv)
		st.set_uv2(Vector2(r, 2.0))
		st.add_vertex(c + off + Vector3((uv.x * 2.0 - 1.0) * r, 0, (uv.y * 2.0 - 1.0) * r))


func gh(x: float, z: float) -> float:
	var y := 0.05 * (h01(x * 0.8, z * 0.8, seedv + 5) - 0.5) + 0.04 * sin(x * 0.55 + z * 0.35)
	for m: Array in mounds:
		var d := Vector2(x - m[0], z - m[1]).length()
		if m[4] == 0:
			y += m[3] * exp(-d * d / (m[2] * m[2] * 0.6))
		else:
			y += m[3] * exp(-d * d / (m[2] * m[2] * 0.5)) - m[3] * 0.4 * exp(-pow(d - m[2] * 1.15, 2.0) / 0.6)
	return y


func ground(x0: float, z0: float, x1: float, z1: float, step: float, colfn: Callable, edge: Color) -> void:
	var nx := int((x1 - x0) / step)
	var nz := int((z1 - z0) / step)
	var pts := PackedVector3Array()
	var cols := PackedColorArray()
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	for j in nz + 1:
		for i in nx + 1:
			var x := x0 + i * step
			var z := z0 + j * step
			var n := Vector3(gh(x - 0.2, z) - gh(x + 0.2, z), 0.4, gh(x, z - 0.2) - gh(x, z + 0.2)).normalized()
			var p := Vector3(x, gh(x, z), z) + off
			var col: Color = shade(p, n, colfn.call(x, z))
			var fx := absf(x - cx) / ((x1 - x0) * 0.5)
			var fz := absf(z - cz) / ((z1 - z0) * 0.5)
			col = col.lerp(edge, smoothstep(0.62, 1.0, maxf(fx, fz)))
			pts.append(p + Vector3(0, 0.02, 0))
			cols.append(col)
	var st := _st("lit")
	for j in nz:
		for i in nx:
			var i0 := j * (nx + 1) + i
			var i1 := i0 + 1
			var i2 := i0 + nx + 2
			var i3 := i0 + nx + 1
			_emit(st, pts[i0], pts[i3], pts[i2], cols[i0], cols[i3], cols[i2], Vector3.UP)
			_emit(st, pts[i0], pts[i2], pts[i1], cols[i0], cols[i2], cols[i1], Vector3.UP)


func blades(x0: float, z0: float, x1: float, z1: float, n: int, col: Color, sd: int, hmax := 0.28, avoid := Callable()) -> void:
	for i in n:
		var x := lerpf(x0, x1, h01(float(i), 1.0, sd))
		var z := lerpf(z0, z1, h01(float(i), 2.0, sd))
		if avoid.is_valid() and avoid.call(x, z):
			continue
		var hh := hmax * (0.5 + h01(float(i), 3.0, sd))
		var a := h01(float(i), 4.0, sd) * TAU
		var side := Vector3(cos(a), 0, sin(a)) * 0.035
		var lean := Vector3(sin(a), 0, -cos(a)) * hh * 0.35
		var base := Vector3(x, gh(x, z), z) + off
		var tone := col.lerp(col.lightened(0.35), h01(float(i), 5.0, sd))
		tg("lit", base - side, base + side, base + Vector3(0, hh, 0) + lean, tone, Vector3.UP)
		tg("lit", base - side, base + Vector3(0, hh, 0) + lean, base + side, tone, Vector3.UP)
