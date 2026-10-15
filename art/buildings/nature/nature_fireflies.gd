class_name NatureFireflies
extends RefCounted
## G-B Nature: fireflies around a Nature building (High / Ultra only; the caller checks NatureKit.gfx_rich()).
## Tiny additive yellow-green specks drifting slowly in a box, each blinking twice in its life. Looping, so the
## building adds it to its "ambient" list (emits only while a camera is near, like the pollen). Shared materials.

static var _quad: Mesh
static var _materials: Dictionary = {}   # half extents -> ParticleProcessMaterial (shared by every building of a size)


## A GPUParticles3D named "Fireflies" centred at `center` (local), drifting in a box of half-extents `half`.
static func make(center: Vector3, half: Vector3, amount: int) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Fireflies"
	p.set_meta(&"no_ghost", true)   # never copied into the fog-of-war ghost (Building.make_ghost)
	p.position = center
	p.amount = amount
	p.lifetime = 5.5
	p.preprocess = 3.0
	p.randomness = 0.6
	p.local_coords = true
	p.emitting = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(-half - Vector3.ONE, (half + Vector3.ONE) * 2.0)
	if not _materials.has(half):
		_materials[half] = _material(half)
	p.process_material = _materials[half]
	p.draw_pass_1 = _mesh()
	return p


static func _material(half: Vector3) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = half
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.08
	pm.initial_velocity_max = 0.3
	pm.gravity = Vector3(0.0, 0.03, 0.0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 2.5
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.12
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	var g := Gradient.new()
	# Two blinks per life (alpha), warm yellow-green.
	g.offsets = PackedFloat32Array([0.0, 0.12, 0.2, 0.32, 0.55, 0.64, 0.74, 1.0])
	var c := Color(1.3, 1.7, 0.6)   # HDR: a faint bloom on each speck
	g.colors = PackedColorArray([Color(c, 0.0), Color(c, 1.0), Color(c, 0.9), Color(c, 0.0), Color(c, 0.0),
		Color(c, 1.0), Color(c, 0.85), Color(c, 0.0)])
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = true
	pm.color_ramp = t
	return pm


static func _mesh() -> Mesh:
	if _quad:
		return _quad
	var q: QuadMesh = (NatureKit.soft_quad(true) as QuadMesh).duplicate() as QuadMesh
	q.size = Vector2(0.16, 0.16)
	_quad = q
	return q
