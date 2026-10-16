class_name NeutralBuildingLook
extends RefCounted
## Task G-B neutral (docs/art/gb_neutral_buildings.md): the shared look layer of the neutral / shared buildings (taverns,
## trading posts, watchtower / essence well / wayshrine, Magpie Den, Greywater Lodge, the Stables' shared shader).
##   detail()             the paint tier from GameSettings.effective_graphics_quality() (0 Low .. 3 Ultra; Low in tests)
##   set_detail(m)        writes it into a material that includes neutral_paint.gdshaderinc (`gb_detail`)
##   set_detail_all(ms)   same for a list (non-shader materials are skipped)
##   add_light(...)       a warm flickering point light (NeutralFlickerLight) at Ultra only; null below. The building
##                        budget (Art Lab B5, art-keep 0.4) is 0 real lights: the warm light is emission + bloom + the
##                        fake light pools, so Low / Medium / High keep it; Ultra is the opt-in "real lights" tier
##                        (pending a lead ruling, docs/art/gb_neutral_buildings.md). Low keeps the pre-G-B effect cost.
##   add_sparks(...)      ember sparks over a chimney / fire, High and Ultra
## Every model calls these from its own _ready (the tier is read once per build, like the other G-B kingdoms).

const MIN_LIGHT_TIER := 3


## The tier the neutral paint uses (0 Low, 1 Medium, 2 High, 3 Ultra).
static func detail() -> int:
	return clampi(GameSettings.effective_graphics_quality(), 0, 3)


static func set_detail(m: Material) -> void:
	var sm := m as ShaderMaterial
	if sm:
		sm.set_shader_parameter(&"gb_detail", float(detail()))


static func set_detail_all(mats: Array) -> void:
	for m: Variant in mats:
		if m is Material:
			set_detail(m as Material)


## A warm, shadowless, flickering point light under `parent` at `pos` (parent space). `flicker` 0..0.4 (share of the
## energy that wavers), `speed` the flicker rate. Returns null below MIN_LIGHT_TIER (and in Low headless runs).
static func add_light(parent: Node3D, nm: String, pos: Vector3, color: Color, energy: float, light_range: float,
		flicker: float = 0.15, speed: float = 1.0) -> NeutralFlickerLight:
	if parent == null or detail() < MIN_LIGHT_TIER:
		return null
	var l := NeutralFlickerLight.new()
	l.name = nm
	l.position = pos
	l.light_color = color
	l.base_energy = energy
	l.omni_range = light_range
	l.flicker = flicker
	l.speed = speed
	l.set_meta(&"no_ghost", true)   # never copied into a fog-of-war ghost (Building.make_ghost)
	parent.add_child(l)
	return l


static var _spark_pm: ParticleProcessMaterial
static var _spark_quad: QuadMesh


## A few glowing ember sparks rising from a chimney / fire (High and Ultra only; null below). 8 particles, additive, unshaded,
## shared process material and quad (one GPUParticles3D node per emitter).
static func add_sparks(parent: Node3D, nm: String, pos: Vector3, amount: int = 8) -> GPUParticles3D:
	if parent == null or detail() < 2:
		return null
	if _spark_pm == null:
		_spark_pm = ParticleProcessMaterial.new()
		_spark_pm.direction = Vector3(0.1, 1.0, 0.0)
		_spark_pm.spread = 18.0
		_spark_pm.initial_velocity_min = 0.9
		_spark_pm.initial_velocity_max = 1.7
		_spark_pm.gravity = Vector3(0.25, 0.15, 0.1)
		_spark_pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		_spark_pm.emission_sphere_radius = 0.18
		_spark_pm.turbulence_enabled = true
		_spark_pm.turbulence_noise_strength = 0.6
		_spark_pm.turbulence_noise_scale = 1.5
		var fade := Gradient.new()
		fade.set_color(0, Color(1.0, 0.85, 0.45, 1.0))
		fade.set_color(1, Color(0.9, 0.25, 0.05, 0.0))
		fade.add_point(0.4, Color(1.0, 0.55, 0.18, 0.9))
		var ft := GradientTexture1D.new()
		ft.gradient = fade
		_spark_pm.color_ramp = ft
		_spark_pm.scale_min = 0.6
		_spark_pm.scale_max = 1.0
		_spark_quad = QuadMesh.new()
		_spark_quad.size = Vector2(0.07, 0.07)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.disable_fog = true  # G-E 5: an additive quad must not fog
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true   # G-F billboard pass: the particle scale applies (docs/art/gf_billboard.md)
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color(1.0, 1.0, 1.0)
		_spark_quad.material = m
	var p := GPUParticles3D.new()
	p.name = nm
	p.set_meta(&"no_ghost", true)
	p.amount = amount
	p.lifetime = 1.6
	p.randomness = 0.5
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = false
	p.process_material = _spark_pm
	p.draw_pass_1 = _spark_quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 5, 4))
	p.position = pos
	parent.add_child(p)
	return p
