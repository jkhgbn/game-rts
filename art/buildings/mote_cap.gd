class_name MoteCap
extends RefCounted
## G-F round 2 item 7 (docs/art/gf_review2.md, docs/art/gf_r2_buildings_in.md): ambient motes around the Ice and Nature
## buildings (snow motes, snowfall, pollen, spores, fireflies) rendered as big soft white discs when one drifted close
## to the camera ("dust on the lens"). Every such emitter now draws with a MoteCap quad:
##   * alpha-blended (MIX), so a stack never sums past its own colour (no additive white-out),
##   * a near-camera fade (distance fade, pixel alpha): invisible closer than FADE_NEAR m, full only from FADE_FULL m,
##     so a mote can never grow into a disc in front of the building,
##   * its colour ramp capped under VALUE_CAP (value / max channel), well under the glow threshold.
## Tier (GameSettings.effective_graphics_quality()): Low = none (hidden, amount_ratio 0: the pre-G1 cost or less),
## Medium = half the motes, High / Ultra = all. Static only; quads are cached (one material per kind for the game).
## Size: the root cause of the "discs" was size, not only brightness. A StandardMaterial3D in BILLBOARD_PARTICLES mode
## without billboard_keep_scale drops the particle's scale, so a mote meant to be 0.06 m (scale 0.06 on the kit's 1 m
## quad) drew as the whole 1 m soft quad. MoteCap therefore puts the world size in the QUAD (sized(): a copy of the
## mesh at that size, same material, so no new material) and normalises the process scale to <= 1 (a relative
## spread): the size is right with or without keep_scale.

const VALUE_CAP := 0.72   ## max channel of a mote's colour (sRGB); the Ice whites sit at ~0.75-0.8 (ge_value_pass.md)
const FADE_NEAR := 4.0    ## metres from the camera: a mote closer than this is invisible
const FADE_FULL := 9.0    ## metres from the camera: full alpha from here
const MEDIUM_RATIO := 0.5

static var _quads: Dictionary = {}


## The share of motes a looping ambient emitter shows at the current tier: 0 Low, 0.5 Medium, 1 High / Ultra.
static func ratio() -> float:
	var q: int = GameSettings.effective_graphics_quality()
	if q <= 0:
		return 0.0
	return MEDIUM_RATIO if q == 1 else 1.0


## `c` with its colour scaled so the brightest channel is at most `cap` (hue and alpha kept).
static func cap(c: Color, v: float = VALUE_CAP) -> Color:
	var mx: float = maxf(c.r, maxf(c.g, c.b))
	if mx <= v or mx <= 0.0:
		return c
	var k: float = v / mx
	return Color(c.r * k, c.g * k, c.b * k, c.a)


## Normalises a process material's scale range to a relative spread (scale_max 1): the size lives in the quad.
## Idempotent (shared materials are normalised once).
static func normalize_scale(pm: ParticleProcessMaterial) -> void:
	if pm == null or pm.scale_max <= 0.0:
		return
	pm.scale_min = pm.scale_min / pm.scale_max
	pm.scale_max = 1.0


## A copy of `mesh` (a QuadMesh or a one-surface ArrayMesh quad) at world size `size`, drawing with the same material
## (no new material: Art Lab B8). Cached per mesh and size.
static func sized(mesh: Mesh, size: float) -> Mesh:
	if mesh == null:
		return null
	var key: String = "sized_%d_%.3f" % [mesh.get_instance_id(), size]
	if _quads.has(key):
		return _quads[key]
	var out: Mesh
	if mesh is QuadMesh:
		var q := QuadMesh.new()
		q.size = Vector2(size, size)
		q.orientation = (mesh as QuadMesh).orientation
		q.material = (mesh as QuadMesh).material
		out = q
	else:
		var a: Array = mesh.surface_get_arrays(0)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var ext: float = maxf(mesh.get_aabb().size.x, mesh.get_aabb().size.y)
		var k: float = size / maxf(ext, 0.0001)
		for i: int in v.size():
			v[i] = v[i] * k
		a[Mesh.ARRAY_VERTEX] = v
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		am.surface_set_material(0, mesh.surface_get_material(0))
		out = am
	_quads[key] = out
	return out


## A two-stop ramp (fade in, hold, fade out) of `c` capped by cap(), peak alpha `alpha`.
static func ramp(c: Color, alpha: float, v: float = VALUE_CAP) -> GradientTexture1D:
	var cc: Color = cap(c, v)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.8, 1.0])
	g.colors = PackedColorArray([Color(cc, 0.0), Color(cc, alpha), Color(cc, alpha * 0.85), Color(cc, 0.0)])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


## Caps every stop of an existing gradient (in place: team-colour ramps keep being recoloured by their owner; call it
## again after a recolour). Alpha is multiplied by `alpha_k`.
static func cap_gradient(g: Gradient, alpha_k: float = 1.0, v: float = VALUE_CAP) -> void:
	if g == null:
		return
	var cols: PackedColorArray = g.colors
	for i: int in cols.size():
		var c: Color = cap(cols[i], v)
		cols[i] = Color(c, cols[i].a * alpha_k)
	g.colors = cols


## The soft round mote quad of world size `size` (billboard, MIX, near-camera fade, vertex colour = the ramp).
static func quad(size: float = 1.0) -> QuadMesh:
	var key: String = "mote_%.3f" % size
	if _quads.has(key):
		return _quads[key]
	if not _quads.has("mat"):
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 32
		tex.height = 32
		var m := StandardMaterial3D.new()
		m.resource_name = "MoteCap"
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = tex
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true   # the relative scale spread applies (the size itself is in the quad)
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		m.distance_fade_min_distance = FADE_NEAR
		m.distance_fade_max_distance = FADE_FULL
		_quads["mat"] = m
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = _quads["mat"]
	_quads[key] = q
	return q


## Gives an existing particle material the mote look's near-camera fade (idempotent). Used where a building already
## has a MIX soft-dot material (the Ice keep's ParticleMix, the Nature atlas / soft quads): reusing it keeps the
## building's unique-material count (Art Lab B8) unchanged; the other emitters on it fade near the camera too.
static func fade(m: Material) -> void:
	var bm := m as BaseMaterial3D
	if bm == null:
		return
	bm.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	bm.distance_fade_min_distance = FADE_NEAR
	bm.distance_fade_max_distance = FADE_FULL


## True when `m` draws like a mote: alpha-blended (MIX) with the near-camera fade (the MoteCap material or a faded
## building material; tests).
static func is_mote_like(m: Material) -> bool:
	var bm := m as BaseMaterial3D
	if bm == null or bm.blend_mode != BaseMaterial3D.BLEND_MODE_MIX:
		return false
	return bm.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA and bm.distance_fade_min_distance >= FADE_NEAR - 0.01


## The material a particle draw pass renders with (the mesh's own, or its first surface's).
static func draw_material(p: GPUParticles3D) -> Material:
	var mesh: Mesh = p.draw_pass_1
	if mesh == null:
		return null
	if mesh is PrimitiveMesh and (mesh as PrimitiveMesh).material != null:
		return (mesh as PrimitiveMesh).material
	return mesh.surface_get_material(0) if mesh.get_surface_count() > 0 else null


## Like apply(), but on a MIX soft-dot quad the building already owns (`quad`, or the emitter's current one) resized
## to `size` m (sized(); 0 = keep the mesh as it is): the quad's material gets the near-camera fade, the emitter the
## tier and a normalised scale. Returns `p`.
static func apply_own(p: GPUParticles3D, quad: Mesh = null, size: float = 0.0) -> GPUParticles3D:
	if p == null:
		return p
	var mesh: Mesh = quad if quad != null else p.draw_pass_1
	if size > 0.0:
		mesh = sized(mesh, size)
		normalize_scale(p.process_material as ParticleProcessMaterial)
	p.draw_pass_1 = mesh
	fade(draw_material(p))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_tier(p)
	return p


## True when `m` is the MoteCap material (tests).
static func is_mote_material(m: Material) -> bool:
	return m != null and _quads.has("mat") and m == _quads["mat"]


## Puts a looping ambient emitter on the mote quad (`size` m) and on the tier: Low hides it (amount_ratio 0),
## Medium keeps half. Its emitting flag stays its owner's business. Returns `p`.
static func apply(p: GPUParticles3D, size: float = 1.0) -> GPUParticles3D:
	if p == null:
		return p
	p.draw_pass_1 = quad(size)
	normalize_scale(p.process_material as ParticleProcessMaterial)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_tier(p)
	return p


## The tier part of apply() alone (emitters that keep their own draw pass).
static func set_tier(p: GPUParticles3D) -> void:
	var r: float = ratio()
	p.amount_ratio = r
	p.visible = r > 0.0
	p.set_meta(&"mote_cap", true)
