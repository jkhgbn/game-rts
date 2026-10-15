class_name BuildSettle
extends RefCounted
## G-B leftovers (docs/art/gb_leftovers.md): the construction-complete effect of the hall / small-building models
## (FireHallModel, SmallBuildingModel and every model built on them). It replaces the old completion burst: 24-32
## additive glow-colour sparks, 0.35 m, raining from the roof top, which read as bright white puffs under the bloom
## (the Ice / Nature / Shadow glow colours are near white). Now the building "settles":
## - Dust: a low ring of soft MIX dust rolling out from the foot of the walls in the kingdom's earth tone (value capped
##   so a pale palette never turns it into white puffs), fading in, spreading, sinking.
## - Sparkle: a few small glints in the glow colour (x 0.8, under the bloom level), flavoured per kingdom:
##   Fire embers jump and fall, Ice frost glints drift down slowly, Nature pollen and Shadow soul motes rise.
## Fog-safe: `play` draws nothing for another team's building the local player does not see now (VfxFog rule), and
## both emitters carry the meta `no_ghost` (fog ghosts copy meshes only anyway). One-shot, pre-built at _ready (no
## allocation when it fires). Low tier: fewer particles than the old burst (cost before G1 or less), same look.

enum Style { EMBER, FROST, POLLEN, SOUL }

const DUST_LIFE := 1.5
const GLINT_LIFE := 1.2
const DUST_MAX_V := 0.5   ## dust colour value cap (no white puffs)
const GLINT_DIM := 0.8    ## glint colour factor (stays under the bloom threshold)

static var _dust_cache: Dictionary = {}   ## "radius|style|colour" -> ParticleProcessMaterial (shared by every model)


## Kingdom flavour from the model's glow colour (hue): orange = Fire embers, cyan / blue = Ice frost, green = Nature
## pollen, violet = Shadow motes.
static func style_of(glow: Color) -> int:
	var h: float = glow.h
	if h < 0.14 or h > 0.93:
		return Style.EMBER
	if h < 0.45:
		return Style.POLLEN
	if h < 0.68:
		return Style.FROST
	return Style.SOUL


## The dust tone: the model's dust colour pulled toward its stone, never brighter than DUST_MAX_V.
static func dust_color(dust: Color, stone: Color) -> Color:
	var c: Color = dust if dust.v <= DUST_MAX_V else dust.lerp(stone, 0.55)
	if c.v > DUST_MAX_V:
		c = Color.from_hsv(c.h, c.s, DUST_MAX_V)
	return c


static func dust_amount() -> int:
	return 10 if GameSettings.effective_graphics_quality() <= 0 else 16


static func glint_amount() -> int:
	return 10 if GameSettings.effective_graphics_quality() <= 0 else 18


## Dust ring at the foot of a building of half-size `radius` (m): rolls outward, rises a little, sinks, spreads.
static func dust_pm(radius: float, style: int) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius
	pm.emission_ring_inner_radius = radius * 0.8
	pm.emission_ring_height = 0.1
	pm.direction = Vector3.UP
	pm.spread = 25.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.6
	pm.radial_velocity_min = 0.7
	pm.radial_velocity_max = 1.5
	pm.damping_min = 0.6
	pm.damping_max = 1.0
	pm.gravity = Vector3(0, -0.3 if style != Style.FROST else -0.15, 0)
	var s0: float = 0.45 + radius * 0.06
	var s1: float = 1.1 + radius * 0.16
	pm.scale_min = s1
	pm.scale_max = s1
	pm.scale_curve = _curve([Vector2(0.0, s0 / s1), Vector2(1.0, 1.0)])
	pm.alpha_curve = _curve([Vector2(0.0, 0.0), Vector2(0.18, 1.0), Vector2(0.55, 0.7), Vector2(1.0, 0.0)])
	return pm


## The dust process material with its colour ramp (`color` fading in / out), shared by every model that asks for the
## same radius, style and colour (no per-instance material: Art Lab B9).
static func dust_pm_cached(radius: float, style: int, color: Color) -> ParticleProcessMaterial:
	var key: String = "%.2f|%d|%s" % [radius, style, color.to_html()]
	if _dust_cache.has(key):
		return _dust_cache[key]
	var pm := dust_pm(radius, style)
	var g := Gradient.new()
	g.set_color(0, Color(color, 0.5))
	g.set_color(1, Color(color, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = g
	pm.color_ramp = tex
	_dust_cache[key] = pm
	return pm


## Small glints over the building (box `half` x `half_h` x `half`), kingdom flavoured; `ramp` carries the glow
## colour (the model's team-tracked ramp), multiplied by GLINT_DIM.
static func glint_pm(half: float, half_h: float, style: int, ramp: Texture2D) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(half, half_h, half)
	pm.color_ramp = ramp
	pm.color = Color(GLINT_DIM, GLINT_DIM, GLINT_DIM, 1.0)
	var size: float = 0.09
	match style:
		Style.EMBER:
			pm.direction = Vector3.UP
			pm.spread = 45.0
			pm.initial_velocity_min = 1.0
			pm.initial_velocity_max = 2.2
			pm.gravity = Vector3(0, -3.2, 0)
			size = 0.08
		Style.FROST:
			pm.direction = Vector3.UP
			pm.spread = 180.0
			pm.initial_velocity_min = 0.1
			pm.initial_velocity_max = 0.45
			pm.gravity = Vector3(0, -0.45, 0)
			size = 0.07
		Style.POLLEN:
			pm.direction = Vector3.UP
			pm.spread = 70.0
			pm.initial_velocity_min = 0.25
			pm.initial_velocity_max = 0.7
			pm.gravity = Vector3(0.12, 0.3, 0.05)
			size = 0.08
		_:
			pm.direction = Vector3.UP
			pm.spread = 30.0
			pm.initial_velocity_min = 0.3
			pm.initial_velocity_max = 0.8
			pm.gravity = Vector3(0, 0.55, 0)
			size = 0.08
	pm.damping_min = 0.3
	pm.damping_max = 0.6
	pm.scale_min = size
	pm.scale_max = size * 1.3
	pm.scale_curve = _curve([Vector2(0.0, 0.4), Vector2(0.2, 1.0), Vector2(1.0, 0.25)])
	# Twinkle: two soft peaks, then out.
	pm.alpha_curve = _curve([Vector2(0.0, 0.0), Vector2(0.12, 1.0), Vector2(0.35, 0.35), Vector2(0.55, 0.9),
		Vector2(1.0, 0.0)])
	return pm


## Fires the settle (dust + glints) of `model` unless the fog hides it from the local player.
static func play(dust: GPUParticles3D, glint: GPUParticles3D, model: Node3D) -> void:
	if model == null or not model.is_inside_tree():
		return
	var owner_b: Node = building_of(model)
	var team: int = VfxFog.team_of(owner_b) if owner_b else -1
	if not VfxFog.ok(team, model.global_position):
		return
	for p: GPUParticles3D in [dust, glint]:
		if p:
			p.restart()
			p.emitting = true


## The Building (any ancestor with a `team` and `is_constructed`) of a model, or null (Art Lab, previews).
static func building_of(n: Node) -> Node:
	var p: Node = n.get_parent()
	while p != null:
		if p.has_method(&"is_constructed") and p.get(&"team") != null:
			return p
		p = p.get_parent()
	return null


## Marks the two emitters as dressing (never copied into a fog-of-war ghost).
static func mark(dust: Node, glint: Node) -> void:
	for n: Node in [dust, glint]:
		if n:
			n.set_meta(&"no_ghost", true)


static func _curve(pts: Array) -> CurveTexture:
	var c := Curve.new()
	for p: Vector2 in pts:
		c.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = c
	return ct
