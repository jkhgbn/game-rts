class_name IceShapes
extends RefCounted
## Mesh kit shared by the Ice buildings (tasks 7.V2, A2.4): faceted crystals like the Rime Keep's, flat-shaded
## battered prisms (square / hex / octagonal / 10-sided), the keep's "tombstone" gate arch, icicle fringes, snow
## mounds. Every mesh is cached by its parameters so all instances (and BuildingMerge bakes) share it. Static only.
## Winding follows ice_keep_build.gd (clockwise seen from outside = Godot front face); flat facets
## (smooth group -1) for the chunky hand-painted read.

## G-B Ice (docs/art/gb_ice_buildings.md): the Ice paint layer (art/buildings/ice/ice_paint.gdshaderinc).
const ICE_VC: Shader = preload("res://art/buildings/ice/ice_painted_vc.gdshader")
const ICE_PAINTED: Shader = preload("res://art/buildings/ice/ice_painted.gdshader")
const PAINTED_VC: Shader = preload("res://art/shaders/painted_vc.gdshader")
const PAINTED: Shader = preload("res://art/shaders/painted.gdshader")
## Surface kinds of ice_painted.gdshader (IK_* in the include).
const K_STONE := 0
const K_DARK := 1
const K_METAL := 2
const K_ICE := 3
const K_SNOW := 4
const K_FROST := 5
## Warm interior light in windows / lanterns (against the cold blues; the team colour stays on crystals and banners).
const WARM_WINDOW := Color(1.0, 0.71, 0.38)

static var _cache: Dictionary = {}
## Shots / labs only: true = the pre-G-B look (no Ice layer, cold windows, no new particles, no tier look) for
## before / after pairs.
static var legacy := false


## The graphics tier (GameSettings.effective_graphics_quality(): 0 Low .. 3 Ultra; Low in headless / -s runs).
static func gfx_tier() -> int:
	return clampi(GameSettings.effective_graphics_quality(), 0, 3)


## The window / lantern glow: warm (G-B), or `cold` in the legacy look.
static func window_color(cold: Color) -> Color:
	return cold if legacy else WARM_WINDOW


## High / Ultra ambience on (never in the legacy look).
static func high_fx() -> bool:
	return not legacy and gfx_tier() >= 2


## The paint layer's `gb_detail`: 0 Low, 1 Medium, 2 High / Ultra.
static func detail_tier() -> int:
	return mini(gfx_tier(), 2)


## Switches a PaintedVC body material (painted_vc.gdshader, after PaintedVC.convert) to the Ice one-material shader
## (same vertex data and uniforms). `masonry` 0 = the parts are already modelled blocks (Ice Wall). No-op otherwise.
static func ice_vc(body: ShaderMaterial, masonry: float = 1.0) -> void:
	if legacy or body == null or not (body.shader == PAINTED_VC or body.shader == ICE_VC):
		return
	body.shader = ICE_VC
	body.set_shader_parameter(&"gb_detail", float(detail_tier()))
	body.set_shader_parameter(&"ip_masonry", masonry)


## True for the merged body shaders (painted_vc or its Ice version): the B8 code paths compare against these.
static func is_vc(m: ShaderMaterial) -> bool:
	return m != null and (m.shader == PAINTED_VC or m.shader == ICE_VC)


## High / Ultra ambience: slow snowflakes drifting down over a `radius` m square (emitter at the top, local coords),
## a shared process material per radius. Use with a MIX quad, ~10-16 flakes, lifetime ~4.5 s.
static func snowfall_pm(radius: float) -> ParticleProcessMaterial:
	var key: String = "snowfall_%.2f" % radius
	if _cache.has(key):
		return _cache[key]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(radius, 0.4, radius)
	pm.direction = Vector3(0.3, -1.0, 0.15).normalized()
	pm.spread = 25.0
	pm.initial_velocity_min = 0.45
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0.12, -0.25, 0.05)
	pm.angular_velocity_min = -90.0
	pm.angular_velocity_max = 90.0
	pm.scale_min = 0.035
	pm.scale_max = 0.06
	var g := Gradient.new()
	g.set_color(0, Color(0.92, 0.96, 1.0, 0.0))
	g.set_color(1, Color(0.85, 0.92, 1.0, 0.0))
	g.add_point(0.15, Color(0.95, 0.98, 1.0, 0.85))
	g.add_point(0.85, Color(0.88, 0.94, 1.0, 0.7))
	var tex := GradientTexture1D.new()
	tex.gradient = g
	pm.color_ramp = tex
	_cache[key] = pm
	return pm


## Switches a per-part painted.gdshader material to ice_painted.gdshader with surface kind `kind` (K_*).
static func ice_part(m: ShaderMaterial, kind: int, masonry: float = 1.0) -> void:
	if legacy or m == null or not (m.shader == PAINTED or m.shader == ICE_PAINTED):
		return
	m.shader = ICE_PAINTED
	m.set_shader_parameter(&"ip_kind", kind)
	m.set_shader_parameter(&"gb_detail", float(detail_tier()))
	m.set_shader_parameter(&"ip_masonry", masonry)


## A row of `count` downward icicles (4-sided pyramids) along local X, centred, hanging from y 0.
## Lengths vary between 0.55 and 1.0 x `h` (fixed seed). One mesh, one draw call.
static func icicle_strip(length: float, count: int, h: float, r: float, seed: int) -> Mesh:
	var key: String = "ici_%.2f_%d_%.2f_%.2f_%d" % [length, count, h, r, seed]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var step: float = length / float(count)
	for i: int in count:
		var x: float = -length * 0.5 + step * (float(i) + 0.5) + rng.randf_range(-0.2, 0.2) * step
		var hh: float = h * rng.randf_range(0.55, 1.0)
		var rr: float = r * rng.randf_range(0.8, 1.15)
		var tip := Vector3(x, -hh, 0.0)
		var c: Array[Vector3] = [Vector3(x - rr, 0, -rr), Vector3(x + rr, 0, -rr), Vector3(x + rr, 0, rr),
			Vector3(x - rr, 0, rr)]
		for k: int in 4:
			st.add_vertex(c[(k + 1) % 4])  # clockwise seen from outside (Godot front face)
			st.add_vertex(c[k])
			st.add_vertex(tip)
	st.generate_normals()
	st.index()   # indexed like the primitives: BuildingMerge mixes both in one surface
	var m: Mesh = st.commit()
	_cache[key] = m
	return m


## Dome: a hemisphere of radius r, flat side at y 0, top at y r.
static func dome(r: float) -> Mesh:
	var key: String = "dome_%.3f" % r
	if _cache.has(key):
		return _cache[key]
	var m := SphereMesh.new()
	m.radius = r
	m.height = r
	m.is_hemisphere = true
	m.radial_segments = 16
	m.rings = 6
	_cache[key] = m
	return m


## Snow drift / mound: a low hemisphere of radius 1 (scale it per item), flat side at y 0.
static func mound() -> Mesh:
	if _cache.has("mound"):
		return _cache["mound"]
	var m := SphereMesh.new()
	m.radius = 1.0
	m.height = 1.0
	m.is_hemisphere = true
	m.radial_segments = 10
	m.rings = 3
	_cache["mound"] = m
	return m


## Faceted crystal (the Rime Keep's): a `sides`-sided prism of corner radius r from y 0 to `body`, a point `top`
## above it and, if `bot` > 0, a point `bot` below y 0 (else a flat base). Flat-shaded.
static func crystal(r: float, body: float, top: float, bot: float, sides: int = 6) -> Mesh:
	var key: String = "cry_%.3f_%.3f_%.3f_%.3f_%d" % [r, body, top, bot, sides]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var ring: Array[Vector3] = []
	for i: int in sides:
		var a: float = TAU * float(i) / float(sides) + PI / float(sides)
		ring.append(Vector3(cos(a) * r, 0, sin(a) * r))
	var up := Vector3(0, body, 0)
	var apex := Vector3(0, body + top, 0)
	var low := Vector3(0, -bot, 0)
	for i: int in sides:
		var a0: Vector3 = ring[i]
		var a1: Vector3 = ring[(i + 1) % sides]
		var b0: Vector3 = a0 + up
		var b1: Vector3 = a1 + up
		var u0: float = float(i) / float(sides)
		var u1: float = float(i + 1) / float(sides)
		if body > 0.0:
			st.set_uv(Vector2(u0, 1)); st.add_vertex(a0)
			st.set_uv(Vector2(u1, 1)); st.add_vertex(a1)
			st.set_uv(Vector2(u1, 0)); st.add_vertex(b1)
			st.set_uv(Vector2(u0, 1)); st.add_vertex(a0)
			st.set_uv(Vector2(u1, 0)); st.add_vertex(b1)
			st.set_uv(Vector2(u0, 0)); st.add_vertex(b0)
		st.set_uv(Vector2(u0, 0)); st.add_vertex(b0)
		st.set_uv(Vector2(u1, 0)); st.add_vertex(b1)
		st.set_uv(Vector2(0.5, 0)); st.add_vertex(apex)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(a0)
		st.set_uv(Vector2(0.5, 1)); st.add_vertex(low)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(a1)
	st.generate_normals()
	st.index()   # indexed like the primitives: BuildingMerge mixes both in one surface
	var m: Mesh = st.commit()
	_cache[key] = m
	return m


## Battered prism: `sides` flat faces, apothem (centre to a face) `ab` at y 0 and `at` at y `h`, flat caps.
## Sides 4 / 8: faces look along +-X and +-Z (a square block; scale it per item for a rectangle). Sides 6: faces
## look along +-Z (a gate face). Flat-shaded.
static func prism(ab: float, at: float, h: float, sides: int) -> Mesh:
	var key: String = "pri_%.3f_%.3f_%.3f_%d" % [ab, at, h, sides]
	if _cache.has(key):
		return _cache[key]
	var k: float = 1.0 / cos(PI / float(sides))
	var off: float = PI / float(sides)
	if sides == 6:
		off = 0.0
	var bot: Array[Vector3] = []
	var top: Array[Vector3] = []
	for i: int in sides:
		var a: float = TAU * float(i) / float(sides) + off
		bot.append(Vector3(cos(a) * ab * k, 0.0, sin(a) * ab * k))
		top.append(Vector3(cos(a) * at * k, h, sin(a) * at * k))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var ct := Vector3(0, h, 0)
	for i: int in sides:
		var j: int = (i + 1) % sides
		st.add_vertex(bot[i]); st.add_vertex(bot[j]); st.add_vertex(top[j])
		st.add_vertex(bot[i]); st.add_vertex(top[j]); st.add_vertex(top[i])
		st.add_vertex(top[i]); st.add_vertex(top[j]); st.add_vertex(ct)
		st.add_vertex(bot[i]); st.add_vertex(Vector3.ZERO); st.add_vertex(bot[j])
	st.generate_normals()
	st.index()   # indexed like the primitives: BuildingMerge mixes both in one surface
	var m: Mesh = st.commit()
	_cache[key] = m
	return m


## "Tombstone" arch (the Rime Keep's gate): rectangle half-width hw, straight height h, topped by a half disc of
## radius hw, extruded `depth` along z (centred). Bottom at y 0. Flat-shaded.
static func arch(hw: float, h: float, depth: float) -> Mesh:
	var key: String = "arch_%.3f_%.3f_%.3f" % [hw, h, depth]
	if _cache.has(key):
		return _cache[key]
	var outline: Array[Vector2] = [Vector2(hw, 0)]
	var segs: int = 10
	for i: int in segs + 1:
		var a: float = PI * float(i) / float(segs)
		outline.append(Vector2(cos(a) * hw, h + sin(a) * hw))
	outline.append(Vector2(-hw, 0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var zf: float = -depth * 0.5
	var zb: float = depth * 0.5
	var centre := Vector2(0, h * 0.6)
	var n: int = outline.size()
	for i: int in n:
		var p0: Vector2 = outline[i]
		var p1: Vector2 = outline[(i + 1) % n]
		st.add_vertex(Vector3(centre.x, centre.y, zf)); st.add_vertex(Vector3(p0.x, p0.y, zf)); st.add_vertex(Vector3(p1.x, p1.y, zf))
		st.add_vertex(Vector3(centre.x, centre.y, zb)); st.add_vertex(Vector3(p1.x, p1.y, zb)); st.add_vertex(Vector3(p0.x, p0.y, zb))
		st.add_vertex(Vector3(p0.x, p0.y, zf)); st.add_vertex(Vector3(p0.x, p0.y, zb)); st.add_vertex(Vector3(p1.x, p1.y, zb))
		st.add_vertex(Vector3(p0.x, p0.y, zf)); st.add_vertex(Vector3(p1.x, p1.y, zb)); st.add_vertex(Vector3(p1.x, p1.y, zf))
	st.generate_normals()
	st.index()   # indexed like the primitives: BuildingMerge mixes both in one surface
	var m: Mesh = st.commit()
	_cache[key] = m
	return m


## The Rime Keep's idle rim (cold, a bit stronger than the base 0.25) on every painted material; selection / a
## rising site blend it toward the team colour like the base classes do.
static func apply_ice_rim(mats: Array[ShaderMaterial], team: Color, sel_k: float, building: bool) -> void:
	var k: float = maxf(sel_k, 0.65) if building else sel_k
	var col: Color = Color(0.70, 0.86, 1.00).lerp(team.lightened(0.2), k)
	var strength: float = lerpf(0.35, 0.9, k)
	for m: ShaderMaterial in mats:
		m.set_shader_parameter(&"rim_color", col)
		m.set_shader_parameter(&"rim_strength", strength)


## A new Ice team banner material (art/shaders/banner.gdshader, the Rime Keep's settings) in `cloth`.
static func banner_material(cloth: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://art/shaders/banner.gdshader") as Shader
	m.set_shader_parameter(&"cloth_color", cloth)
	m.set_shader_parameter(&"stripe_color", Color(0.15, 0.35, 0.60))
	m.set_shader_parameter(&"glyph_color", Color(0.75, 0.92, 1.00))
	m.set_shader_parameter(&"glyph_shape", 1)
	m.set_shader_parameter(&"amplitude", 0.08)
	m.set_shader_parameter(&"speed", 1.6)
	return m


## Recolours an Ice banner material for team colour `c` (the default kingdom colour keeps the dark blue stripe).
static func tint_banner(m: ShaderMaterial, c: Color, kingdom: Color, glow: Color) -> void:
	m.set_shader_parameter(&"cloth_color", c)
	m.set_shader_parameter(&"stripe_color", Color(0.15, 0.35, 0.60) if c.is_equal_approx(kingdom) else c.darkened(0.55))
	m.set_shader_parameter(&"glyph_color", glow)


## Banner cloth: a vertical PlaneMesh (FACE_Z, top edge = UV.y 0) of `size`, subdivided for the wave.
static func banner_mesh(size: Vector2) -> Mesh:
	var key: String = "ban_%.2f_%.2f" % [size.x, size.y]
	if _cache.has(key):
		return _cache[key]
	var pm := PlaneMesh.new()
	pm.size = size
	pm.orientation = PlaneMesh.FACE_Z
	pm.subdivide_width = 2
	pm.subdivide_depth = 10
	_cache[key] = pm
	return pm


## Basis leaning `deg` degrees away from the centre toward the horizontal direction `dir` (tilts +Y outward).
static func lean(dir: Vector3, deg: float) -> Basis:
	var d := Vector3(dir.x, 0.0, dir.z)
	if d.length() < 0.001:
		return Basis.IDENTITY
	var axis: Vector3 = Vector3.UP.cross(d.normalized())
	return Basis(axis, deg_to_rad(deg))
