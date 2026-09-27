class_name StrIntVfx
extends Node3D
## Buff look of the STR / INT path abilities (docs/design/level-boons.md "STR / INT path"). One node per
## wizard, built once and shown / hidden (pooled: no allocation per activation). 0 lights: unshaded additive
## meshes + one GPU particle emitter. Must read at RTS zoom (40 m) and through the fog tint, and be distinct
## from the other auras:
## - STR "Vigor": a pulsing red-gold ground ring (r 2.0 m, the only red-gold double ring in the game) + a
##   red-gold fresnel glow shell on the body + rising embers.
## - INT "Snow Shield": a bright frost dome (hemisphere r 1.7 m) with moving frost bands + an icy ground ring +
##   drifting snow motes.
## set_active(true / false); is_showing() for tests.

const STR_COLOR := Color(1.0, 0.42, 0.08)
const STR_GOLD := Color(1.0, 0.78, 0.25)
const INT_COLOR := Color(0.55, 0.88, 1.0)
const INT_WHITE := Color(0.9, 0.97, 1.0)

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float intensity = 2.0;
uniform float fresnel_mix = 1.0;
uniform float base_alpha = 0.15;
uniform float band_speed = 2.0;
uniform float band_count = 0.0;
uniform float pulse = 1.0;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float bands = band_count > 0.0 ? 0.5 + 0.5 * sin(UV.y * band_count - TIME * band_speed) : 0.0;
	ALBEDO = tint.rgb * intensity * pulse;
	ALPHA = clamp(mix(1.0, f, fresnel_mix) * 0.85 + base_alpha + bands * 0.18, 0.0, 1.0);
}
"""

static var _shader: Shader = null

var kind: StringName = &""
var _parts: Array[GeometryInstance3D] = []
var _mats: Array[ShaderMaterial] = []
var _ring: MeshInstance3D = null
var _ring2: MeshInstance3D = null
var _particles: GPUParticles3D = null
var _t := 0.0


## Builds the look for `path_kind` (&"str" or &"int") once. `height` = the wizard's body height.
func setup(path_kind: StringName, height: float = 2.0) -> void:
	kind = path_kind
	name = "StrIntVfx"
	visible = false
	set_process(false)
	if kind == &"str":
		_ring = _add_ring(1.75, 2.05, STR_COLOR, 4.0)
		_ring2 = _add_ring(1.25, 1.4, STR_GOLD, 3.0)
		var shell := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.7
		cyl.bottom_radius = 0.85
		cyl.height = height + 0.6
		cyl.cap_top = false
		cyl.cap_bottom = false
		shell.mesh = cyl
		shell.position.y = (height + 0.6) * 0.5
		_add_part(shell, _make_mat(STR_GOLD, 2.2, 1.0, 0.0, 0.0))
		_particles = _add_particles(STR_GOLD, Vector3(0, 3.0, 0), 1.6, 28, 1.2)
	else:
		_ring = _add_ring(1.65, 1.9, INT_COLOR, 3.5)
		var dome := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 1.7
		sph.height = 1.7
		sph.is_hemisphere = true
		sph.radial_segments = 32
		sph.rings = 12
		dome.mesh = sph
		dome.scale = Vector3(1.0, 1.35, 1.0)   # tall enough to wrap the wizard (2 m)
		_add_part(dome, _make_mat(INT_COLOR, 2.4, 0.85, 0.12, 30.0))
		_particles = _add_particles(INT_WHITE, Vector3(0, -0.6, 0), 1.5, 32, 2.0)
		_particles.position.y = 2.4


## Shows / hides the buff. Cheap: only toggles visibility, the particle emitter and _process.
func set_active(on: bool) -> void:
	visible = on
	set_process(on)
	if _particles:
		_particles.emitting = on
	_t = 0.0


func is_showing() -> bool:
	return visible and is_visible_in_tree()


func _process(delta: float) -> void:
	_t += delta
	# STR pulses fast (heartbeat, 1.4 Hz), INT shimmers slowly: the two never read alike.
	var p: float
	if kind == &"str":
		p = 0.75 + 0.45 * absf(sin(_t * PI * 1.4))
		if _ring:
			_ring.scale = Vector3.ONE * (0.95 + 0.1 * p)
		if _ring2:
			_ring2.rotation.y = _t * 1.5
	else:
		p = 0.9 + 0.15 * sin(_t * 2.2)
		if _ring:
			_ring.rotation.y = -_t * 0.6
	for m in _mats:
		m.set_shader_parameter(&"pulse", p)


# ---------------------------------------------------------------- building

static func _get_shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	return _shader


func _make_mat(color: Color, intensity: float, fresnel: float, base_alpha: float, bands: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _get_shader()
	m.set_shader_parameter(&"tint", color)
	m.set_shader_parameter(&"intensity", intensity)
	m.set_shader_parameter(&"fresnel_mix", fresnel)
	m.set_shader_parameter(&"base_alpha", base_alpha)
	m.set_shader_parameter(&"band_count", bands)
	_mats.append(m)
	return m


func _add_part(mi: MeshInstance3D, mat: ShaderMaterial) -> void:
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_parts.append(mi)


func _add_ring(inner: float, outer: float, color: Color, intensity: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 48
	torus.ring_segments = 6
	mi.mesh = torus
	mi.position.y = 0.08
	var holder := Node3D.new()
	add_child(holder)
	holder.scale = Vector3(1.0, 0.25, 1.0)   # flat on the ground
	mi.material_override = _make_mat(color, intensity, 0.0, 0.0, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mi)
	_parts.append(mi)
	return mi


func _add_particles(color: Color, gravity: Vector3, radius: float, amount: int, life: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.emitting = false
	p.local_coords = true
	p.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 6, 6))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius
	pm.emission_ring_inner_radius = radius * 0.6
	pm.emission_ring_height = 0.1
	pm.gravity = gravity
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.4
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.albedo_color = color * 2.0
	quad.material = qm
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p
