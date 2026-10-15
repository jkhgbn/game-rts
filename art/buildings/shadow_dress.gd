class_name ShadowDress
extends Node3D
## G-B Shadow buildings (docs/art/gb_shadow_buildings.md): the tier-scaled dressing every Shadow building model adds
## round itself, on top of its own geometry. Built once by `ShadowDress.attach(model, opts)` in the model's _ready
## (after its merge passes); the model forwards its state with `sync(progress, health, destroyed)` and its team glow
## with `set_glow(c)`. Nothing at Low (the look and cost before G1); then, by GameSettings.effective_graphics_quality():
##   Medium : dead ground (one shaded decal: ash, a crack network, soul-fire veins that breathe in the team glow).
##   High   : + drifting shadow mist round the plinth, rising soul wisps, violet embers from the damage points.
##   Ultra  : + more mist / wisps / embers and one soft violet light (no shadows) that breathes with the veins.
## Materials, meshes and process materials are shared by every building (static caches keyed by size / colour), so
## a base of 30 Shadow buildings adds one ground material and a handful of particle materials.

const GROUND_SHADER: Shader = preload("res://art/buildings/shadow_dead_ground.gdshader")
const MIST_COLOR := Color(0.15, 0.1, 0.2, 0.3)
const DEFAULT_GLOW := Color(0.7, 0.3, 1.0)

static var _ground_mat: ShaderMaterial
static var _planes: Dictionary = {}
static var _quads: Dictionary = {}
static var _pms: Dictionary = {}

var tier: int = 0
var _ground: MeshInstance3D
var _mist: GPUParticles3D
var _wisps: GPUParticles3D
var _embers: Array[GPUParticles3D] = []
var _light: OmniLight3D
var _light_energy: float = 0.0
var _glow: Color = DEFAULT_GLOW
var _alive_k: float = 1.0
var _wisp_r: float = 2.0
var _t: float = 0.0
var _opts: Dictionary = {}


## The graphics tier the dressing is built for (0 Low .. 3 Ultra).
static func quality() -> int:
	return clampi(GameSettings.effective_graphics_quality(), 0, 3)


## Adds the dressing under `model` (null at Low: nothing is added). Options (metres, model space):
##   radius (dead-ground half size), inner (plinth half size), top (wisps' height), mist (mist ring radius),
##   embers (Array of Vector3 damage points), light (Vector3: Ultra light position, omit for none), seed (float),
##   glow (Color: the team glow at build time), wisp_y (Vector2: wisps' emission height band), wisp_r (wisps' ring
##   radius), light_energy, light_range.
static func attach(model: Node3D, opts: Dictionary) -> ShadowDress:
	return attach_at(model, opts, quality())


## `attach` at a given tier (tests and tools; the models call `attach`).
static func attach_at(model: Node3D, opts: Dictionary, q: int) -> ShadowDress:
	if q <= 0:
		return null
	var d := ShadowDress.new()
	d.name = "ShadowDress"
	d.set_meta(&"no_ghost", true)   # Building.make_ghost skips it: the fog ghost keeps the building, not its dressing
	d.tier = q
	d._opts = opts
	d._glow = opts.get("glow", DEFAULT_GLOW)
	model.add_child(d)
	d._build()
	return d


## Forwards the building's state: construction 0..1, HP ratio 0..1, destroyed (the wreck).
func sync(progress: float, health: float, destroyed: bool) -> void:
	var built: bool = progress >= 1.0 and not destroyed
	if _ground:
		_ground.set_instance_shader_parameter(&"build", clampf(progress, 0.0, 1.0) if not destroyed else 1.0)
		var dmg: float = 0.0 if health >= 0.5 else (0.6 if health >= 0.25 else 1.0)
		_ground.set_instance_shader_parameter(&"damage", 1.0 if destroyed else dmg)
		_ground.set_instance_shader_parameter(&"scorch", 1.0 if destroyed else 0.0)
	if _mist:
		_mist.emitting = built
	if _wisps:
		_wisps.emitting = built and health >= 0.25
	for e: GPUParticles3D in _embers:
		e.emitting = (built and health < 0.5) or destroyed
	_alive_k = 0.0 if not built else clampf(0.35 + health, 0.0, 1.0)
	if _light:
		_light.visible = built


## The team glow (soul-fire veins, wisps, embers, light).
func set_glow(c: Color) -> void:
	_glow = c
	if _ground:
		_ground.set_instance_shader_parameter(&"glow_color", Color(c, 1.0))
	if _wisps:
		_wisps.process_material = _wisp_pm(c, _wisp_r)
	for e: GPUParticles3D in _embers:
		e.process_material = _ember_pm(c)
	if _light:
		_light.light_color = c


func _process(delta: float) -> void:
	_t += delta
	if _light and _light.visible:
		_light.light_energy = _light_energy * _alive_k * (0.7 + 0.3 * sin(_t * 1.4))


func _build() -> void:
	var radius: float = float(_opts.get("radius", 5.0))
	var inner: float = float(_opts.get("inner", 2.0))
	var seed_v: float = float(_opts.get("seed", 0.0))
	# Medium+: the dead ground.
	_ground = MeshInstance3D.new()
	_ground.name = "DeadGround"
	_ground.mesh = _plane(radius)
	_ground.material_override = _ground_material()
	_ground.position = Vector3(0.0, 0.045, 0.0)
	_ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ground.set_instance_shader_parameter(&"half_size", radius)
	_ground.set_instance_shader_parameter(&"inner", inner)
	_ground.set_instance_shader_parameter(&"seed", seed_v)
	_ground.set_instance_shader_parameter(&"glow_color", Color(_glow, 1.0))
	add_child(_ground)
	if tier < 2:
		set_process(false)
		return
	var ultra: bool = tier >= 3
	# High+: mist round the plinth, soul wisps, damage embers.
	var mist_r: float = float(_opts.get("mist", inner + 1.0))
	_mist = _particles("ShadowMist", Vector3(0.0, 0.25, 0.0), 16 if ultra else 10, 7.0, _mist_pm(mist_r), false)
	_mist.visibility_aabb = AABB(Vector3(-mist_r - 3.0, -1.0, -mist_r - 3.0), Vector3(mist_r * 2.0 + 6.0, 4.0, mist_r * 2.0 + 6.0))
	var top: float = float(_opts.get("top", 5.0))
	_wisp_r = float(_opts.get("wisp_r", inner + 0.4))
	var band: Vector2 = _opts.get("wisp_y", Vector2(0.6, top * 0.6))
	_wisps = _particles("SoulWisps", Vector3(0.0, band.x, 0.0), 14 if ultra else 8, 4.5,
		_wisp_pm(_glow, _wisp_r), true)
	_wisps.visibility_aabb = AABB(Vector3(-inner - 3.0, -1.0, -inner - 3.0), Vector3(inner * 2.0 + 6.0, top + 4.0, inner * 2.0 + 6.0))
	var pts: Array = _opts.get("embers", [])
	for p: Variant in pts:
		var e := _particles("SoulEmbers%d" % (_embers.size() + 1), p as Vector3, 22 if ultra else 14, 1.6, _ember_pm(_glow), true)
		_embers.append(e)
	if ultra and _opts.has("light"):
		_light = OmniLight3D.new()
		_light.name = "SoulLight"
		_light.position = _opts["light"]
		_light.light_color = _glow
		_light_energy = float(_opts.get("light_energy", 1.1))
		_light.light_energy = _light_energy
		_light.omni_range = float(_opts.get("light_range", 6.5))
		_light.shadow_enabled = false
		_light.light_specular = 0.15
		add_child(_light)
	else:
		set_process(false)


func _particles(nm: String, pos: Vector3, amount: int, life: float, pm: ParticleProcessMaterial, add: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = nm
	p.amount = amount
	p.lifetime = life
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = true
	p.process_material = pm
	p.draw_pass_1 = _quad(add)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 8, 8))
	p.position = pos
	p.emitting = false
	add_child(p)
	return p


# --- Shared resources (static caches) ------------------------------------------------------

static func _ground_material() -> ShaderMaterial:
	if _ground_mat == null:
		_ground_mat = ShaderMaterial.new()
		_ground_mat.shader = GROUND_SHADER
		_ground_mat.render_priority = -1   # under the building's own contact decal
	return _ground_mat


static func _plane(radius: float) -> PlaneMesh:
	var key: String = "%.2f" % radius
	if not _planes.has(key):
		var pm := PlaneMesh.new()
		pm.size = Vector2.ONE * radius * 2.0
		_planes[key] = pm
	return _planes[key]


## The soft dot quad: ADD for wisps / embers, MIX for the mist.
static func _quad(add: bool) -> QuadMesh:
	if _quads.has(add):
		return _quads[add]
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	if not add:
		g.add_point(0.45, Color(1, 1, 1, 0.55))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	if not add:
		m.proximity_fade_enabled = true   # the mist melts into the ground and the walls instead of cutting them
		m.proximity_fade_distance = 0.8
	var q := QuadMesh.new()
	q.material = m
	_quads[add] = q
	return q


static func _ramp3(a: Color, mid: Color, b: Color) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	g.add_point(0.35, mid)
	var tex := GradientTexture1D.new()
	tex.gradient = g
	return tex


static func _scale_curve(s0: float, s1: float) -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, s0))
	c.add_point(Vector2(1.0, s1))
	var ct := CurveTexture.new()
	ct.curve = c
	return ct


## Low drifting mist: big dark-violet puffs on a ring round the plinth, turning slowly.
static func _mist_pm(r: float) -> ParticleProcessMaterial:
	var key: String = "mist|%.2f" % r
	if _pms.has(key):
		return _pms[key]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = r
	pm.emission_ring_inner_radius = r * 0.6
	pm.emission_ring_height = 0.2
	pm.direction = Vector3(1, 0.05, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.22
	pm.orbit_velocity_min = 0.012
	pm.orbit_velocity_max = 0.025
	pm.gravity = Vector3(0, 0.015, 0)
	pm.scale_min = 2.6
	pm.scale_max = 3.6
	pm.scale_curve = _scale_curve(0.55, 1.0)
	pm.color_ramp = _ramp3(Color(MIST_COLOR, 0.0), MIST_COLOR, Color(MIST_COLOR, 0.0))
	_pms[key] = pm
	return pm


## Soul wisps: small team-glow motes spiralling up the walls and fading.
static func _wisp_pm(c: Color, r: float) -> ParticleProcessMaterial:
	var key: String = "wisp|%s|%.2f" % [c.to_html(), r]
	if _pms.has(key):
		return _pms[key]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = r
	pm.emission_ring_inner_radius = r * 0.6
	pm.emission_ring_height = 1.2
	pm.direction = Vector3.UP
	pm.spread = 18.0
	pm.initial_velocity_min = 0.35
	pm.initial_velocity_max = 0.75
	pm.orbit_velocity_min = 0.05
	pm.orbit_velocity_max = 0.1
	pm.gravity = Vector3(0, 0.08, 0)
	pm.scale_min = 0.16
	pm.scale_max = 0.24
	pm.scale_curve = _scale_curve(1.0, 0.25)
	pm.color_ramp = _ramp3(Color(c.lightened(0.4), 0.0), Color(c.lightened(0.25), 0.95), Color(c.darkened(0.3), 0.0))
	_pms[key] = pm
	return pm


## Damage embers: violet sparks boiling out of the hurt spots.
static func _ember_pm(c: Color) -> ParticleProcessMaterial:
	var key: String = "ember|%s" % c.to_html()
	if _pms.has(key):
		return _pms[key]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.45
	pm.direction = Vector3.UP
	pm.spread = 28.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.2
	pm.gravity = Vector3(0.15, 0.35, 0)
	pm.damping_min = 0.4
	pm.damping_max = 0.9
	pm.scale_min = 0.07
	pm.scale_max = 0.13
	pm.scale_curve = _scale_curve(1.0, 0.2)
	pm.color_ramp = _ramp3(Color(c.lightened(0.6), 1.0), Color(c.lightened(0.15), 0.9), Color(c.darkened(0.5), 0.0))
	_pms[key] = pm
	return pm
