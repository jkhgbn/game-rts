class_name CreatureSignature
extends RefCounted
## G-D creatures (docs/art/gd_creatures.md): one subtle looping "signature" emitter per neutral creature / beast, built
## only at High / Ultra (`GameSettings.effective_graphics_quality() >= QUALITY`; never at Low / Medium, never headless
## since headless runs are Low). Kinds: breath (warm snort puffs), frost_breath, mist (marsh vapour), spores (glowing
## fungus spores), pollen (forest motes), sparks (storm crackle), dusk_motes (violet motes drifting down),
## frost_motes, glints (gold sparkles), moss_dust (pale spores shaken off moss).
## The emitter is a child of a pivot of the model (FogOfWar hides it with the unit; world-space particles so puffs
## trail behind a moving creature). It starts off; its gate script (creature_signature_gate.gd) polls the model's
## `signature_should_emit()` 5x / s and `on_screen()`, because the kit's _extra_process stops while a model is frozen
## off-screen. Materials / meshes are shared per kind (static caches: zero runtime materials per instance).

const QUALITY := 2
const GATE := preload("res://art/units/neutral/creature_signature_gate.gd")
## Camera distance under which signatures may emit (the kit's tier-0 range).
const NEAR := 30.0

## Tests force a quality here (-1 = the game setting).
static var quality_override: int = -1

# kind -> [color, alpha, additive, amount, lifetime, emit radius, direction, speed, spread, gravity y, size, grow]
const KINDS := {
	&"breath": [Color(0.8, 0.8, 0.79), 0.16, false, 4, 1.5, 0.04, Vector3(0, -0.25, 1), 0.38, 14.0, 0.06, 0.15, 3.0],
	&"frost_breath": [Color(0.74, 0.85, 0.96), 0.22, false, 5, 1.6, 0.04, Vector3(0, -0.2, 1), 0.42, 16.0, -0.02, 0.15, 3.0],
	&"mist": [Color(0.66, 0.74, 0.62), 0.2, false, 6, 3.2, 0.5, Vector3(0, 1, 0), 0.06, 70.0, 0.0, 0.75, 1.7],
	&"spores": [Color(0.42, 0.95, 0.86), 1.0, true, 10, 3.2, 0.35, Vector3(0, 1, 0), 0.22, 55.0, -0.02, 0.1, 0.5],
	&"pollen": [Color(0.86, 0.95, 0.5), 1.0, true, 9, 3.6, 0.55, Vector3(0, 1, 0), 0.12, 80.0, 0.0, 0.055, 0.6],
	&"sparks": [Color(0.66, 0.84, 1.0), 1.0, true, 8, 0.32, 0.7, Vector3(0, 1, 0), 1.3, 180.0, 0.0, 0.05, 0.3],
	&"dusk_motes": [Color(0.58, 0.38, 1.0), 1.0, true, 8, 2.2, 0.8, Vector3(0, -1, 0), 0.12, 60.0, -0.15, 0.075, 0.4],
	&"frost_motes": [Color(0.7, 0.9, 1.0), 1.0, true, 10, 2.4, 0.9, Vector3(0, 1, 0), 0.16, 70.0, 0.02, 0.055, 0.5],
	&"glints": [Color(1.0, 0.84, 0.42), 1.0, true, 3, 0.7, 0.14, Vector3(0, 1, 0), 0.05, 90.0, 0.0, 0.08, 0.2],
	&"moss_dust": [Color(0.8, 0.86, 0.55), 0.55, false, 6, 2.6, 0.4, Vector3(0, -1, 0), 0.05, 60.0, -0.12, 0.05, 0.8],
}

static var _cache: Dictionary = {}


## True when signatures are built at the current graphics quality.
static func wanted() -> bool:
	var q: int = quality_override if quality_override >= 0 else GameSettings.effective_graphics_quality()
	return q >= QUALITY


## Builds the `kind` emitter under `parent` at the parent-local point `at` (named "Signature"), or null below High.
## `scale_k` scales the emit radius, sizes and speeds (big beasts). The model must have `signature_should_emit()`.
static func attach(model: Node3D, parent: Node3D, at: Vector3, kind: StringName, scale_k: float = 1.0) -> GPUParticles3D:
	if not wanted() or parent == null or not KINDS.has(kind):
		return null
	var k: Array = KINDS[kind]
	var p := GPUParticles3D.new()
	p.name = "Signature"
	p.amount = int(k[3])
	p.lifetime = float(k[4])
	p.randomness = 0.4
	p.emitting = false   # the gate turns it on at its first check
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var r: float = 2.5 * scale_k
	p.visibility_aabb = AABB(Vector3(-r, -r, -r), Vector3(r * 2.0, r * 2.0, r * 2.0))
	p.position = at
	p.process_material = _process_mat(kind, scale_k)
	p.draw_pass_1 = _quad(kind, scale_k)
	p.set_script(GATE)
	p.set(&"model", model)
	parent.add_child(p)
	return p


## Switches an attached emitter to another kind (variant swaps); null-safe.
static func restyle(p: GPUParticles3D, kind: StringName, scale_k: float = 1.0) -> void:
	if p == null or not KINDS.has(kind):
		return
	var k: Array = KINDS[kind]
	p.amount = int(k[3])
	p.lifetime = float(k[4])
	p.process_material = _process_mat(kind, scale_k)
	p.draw_pass_1 = _quad(kind, scale_k)


## True when `n` is inside the current camera's view (a 1.5 m margin) and within NEAR m of it.
static func on_screen(n: Node3D) -> bool:
	if n == null or not n.is_inside_tree():
		return false
	var cam := n.get_viewport().get_camera_3d()
	if cam == null:
		return false
	var p := n.global_position
	if cam.global_position.distance_to(p) > NEAR:
		return false
	for pl: Plane in cam.get_frustum():
		if pl.distance_to(p) > 1.5:
			return false
	return true


static func _process_mat(kind: StringName, s: float) -> ParticleProcessMaterial:
	var key := "pm_%s_%s" % [kind, s]
	if _cache.has(key):
		return _cache[key]
	var k: Array = KINDS[kind]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = float(k[5]) * s
	pm.direction = (k[6] as Vector3).normalized()
	pm.spread = float(k[8])
	pm.initial_velocity_min = float(k[7]) * 0.6 * s
	pm.initial_velocity_max = float(k[7]) * s
	pm.gravity = Vector3(0.0, float(k[9]) * s, 0.0)
	pm.damping_min = 0.2
	pm.damping_max = 0.5
	var sc := Curve.new()
	var big: float = maxf(1.0, float(k[11]))
	sc.add_point(Vector2(0.0, 1.0 / big))
	sc.add_point(Vector2(1.0, float(k[11]) / big))
	sc.max_value = 1.0
	var st := CurveTexture.new()
	st.curve = sc
	pm.scale_curve = st
	# Fade in fast, out slow.
	var g := Gradient.new()
	var a: float = float(k[1])
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.15, Color(1, 1, 1, a))
	g.add_point(0.55, Color(1, 1, 1, a * 0.8))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	_cache[key] = pm
	return pm


static func _quad(kind: StringName, s: float) -> QuadMesh:
	var key := "q_%s_%s" % [kind, s]
	if _cache.has(key):
		return _cache[key]
	var k: Array = KINDS[kind]
	var additive: bool = k[2]
	var c: Color = k[0]
	# The scale curve runs from the listed size to size x grow: the quad is the bigger end.
	var size: float = float(k[10]) * s * maxf(1.0, float(k[11]))
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	sm.disable_fog = additive  # G-E 5: an additive quad must not fog
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.billboard_keep_scale = true
	sm.vertex_color_use_as_albedo = true
	sm.albedo_texture = CharacterModel.mote_texture()
	sm.albedo_color = Color(c.r * 1.8, c.g * 1.8, c.b * 1.8, 1.0) if additive else c
	sm.disable_receive_shadows = true
	q.material = sm
	_cache[key] = q
	return q
