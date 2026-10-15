class_name NatureSpireModel
extends SmallBuildingModel
## Nature tower "Bramble Spire" (kingdom-nature.md 4 + 7.1: 1 x 1 cell = 2 x 2 m, height 5, aura r 8). Task 8.V2,
## epic pass A2.6 in the Heartwood's language (art/buildings/nature_keep*). Read from the RTS camera: three bark
## strands braided into a twisted thorn trunk (glowing sap in the furrows, dark thorns spiralling up it), rooted
## into a chamfered mossy plinth over which the roots pour into the ground; at the top a cup of team leaves and
## glowing petals holding the glowing bud (the orb: a living seed-heart that beats, and flares on each shot while the
## cup flexes open), two curled bramble tendrils rising above it (dominant vertical). Asymmetric secondary: a
## leaning rune stone at the back-left, a thorny vine hooking out of the foot at the front-left, a side twig with a
## leaf tuft and a team pennant at the right. A slow green ring pulses out on the ground to r 8 every 4 s (the aura).
## Hooks: SmallBuildingModel's plus play_shot() (the Tower script calls it on each shot). No active light (emissive
## + bloom only); the ambient pollen only runs near the camera. States: < 50 % HP part of the cup is torn off and
## smoke rises, < 25 % the bud dims and races, withered leaves pour down; the aura ring shows only while built.

const SHOT_HOLD := 0.1
const SHOT_FADE := 0.18
const ORB_Y := 5.22
const CROWN_Y := 4.72
const AURA_RADIUS := 8.0
const AURA_PERIOD := 4.0
const AURA_GROW := 2.6
const KEY := "nature_spire/"
const ORB_ENERGY := 2.7
const NEAR_ON := 42.0
const NEAR_OFF := 47.0

var _mats: Dictionary = {}
var _ground_mat: ShaderMaterial
var _orb: MeshInstance3D
var _crown: MeshInstance3D
var _crown_lost: MeshInstance3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _ring_col: Color = NatureKit.GLOW
var _shot_left: float = 0.0
var _flex: float = 0.0
var _ambient: Array[GPUParticles3D] = []
var _ambient_on: bool = false
var _cam_check: float = 0.0
var _glow_ramps: Array = []
var _dying: bool = false


func _setup() -> void:
	kingdom_color = NatureKit.TEAM
	glow_color = NatureKit.GLOW
	stone_color = Color(0.5, 0.47, 0.37)
	dark_color = Color(0.26, 0.24, 0.17)
	trim_color = Color(0.40, 0.28, 0.16)
	smoke_color = Color(0.24, 0.22, 0.17)
	stain_color = Color(0.20, 0.35, 0.12, 0.45)
	footprint = 2.0
	plinth_top = 0.42
	wreck_top = 1.1
	smoke_points = [Vector3(0.25, 3.0, 0.2)]
	blaze_points = [Vector3(-0.1, 4.4, -0.1)]


func _make_materials() -> void:
	_mats = NatureKit.make_materials()
	_m_stone = _mats["Stone"]
	_m_dark = _mats["Dark"]
	_m_trim = _mats["Bark"]
	_m_team = _mats["Leaves"]
	_m_hole = _mats["Black"]
	_painted = NatureKit.surface_materials(_mats)
	_glows = [_mats["Heart"], _mats["Gate"], _mats["Blossom"], _mats["Petal"]] as Array[ShaderMaterial]
	_team_glows = [_mats["Heart"], _mats["Gate"]] as Array[ShaderMaterial]
	(_mats["Heart"] as ShaderMaterial).set_shader_parameter(&"energy", ORB_ENERGY)


func _build_parts() -> void:
	var plinth := _tier("Plinth", "plinth", _mesh_plinth)
	_no_collapse.append(plinth)
	_tier("Trunk", "trunk", _mesh_trunk)
	var pen := _tier("Pennant", "pennant", _mesh_pennant, false)
	_crown = _tier("Crown", "crown", _mesh_crown.bind(false))
	_crown.position = Vector3(0, CROWN_Y, 0)
	_crown_lost = _tier("CrownLost", "crown_lost", _mesh_crown.bind(true))
	_crown_lost.position = Vector3(0, CROWN_Y, 0)
	# The bud (the orb): a beating seed-heart, egg-shaped, floating in the cup.
	_orb = _tier("Orb", "bud", _mesh_bud, false)
	_orb.position = Vector3(0, ORB_Y, 0)
	_floaters.append(_orb)
	_hide_on_collapse.append_array([_crown, _crown_lost, pen])
	_build_ambient()
	_build_scaffold_nature()
	_build_wreck_nature()
	_build_aura_ring()


func _tier(nm: String, key: String, build: Callable, shadow: bool = true) -> MeshInstance3D:
	return NatureKit.node(nm, KEY + key, build, _mats, _body, shadow)


func _mesh_plinth(mb: NatureKit.MB) -> void:
	mb.loft("Dark", [NatureKit.chamfer(1.1, 0.34), NatureKit.chamfer(1.05, 0.32)], [0.0, 0.3])
	mb.loft("Stone", [NatureKit.chamfer(0.92, 0.28), NatureKit.chamfer(0.88, 0.27)], [0.3, 0.42])
	# A leaning rune stone at the back-left, a broken one at the front-right.
	NatureKit.menhir(mb, Vector3(-0.72, 0.36, 0.7), Vector3(-0.7, 0, 0.7).normalized(), 1.7, 0.24, 9.0)
	NatureKit.menhir(mb, Vector3(0.78, 0.3, -0.62), Vector3(0.75, 0, -0.65).normalized(), 0.7, 0.2, 14.0, false)


func _mesh_trunk(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2621
	var strands: Array = []
	# Three strands twisting 220 deg around a core, flaring at the foot.
	for k: int in 3:
		var phase: float = deg_to_rad(120.0 * float(k) + 30.0)
		var pts: Array[Vector3] = []
		var rad: Array[float] = []
		for i: int in 12:
			var t: float = float(i) / 11.0
			var a: float = phase + deg_to_rad(220.0) * t
			var flare: float = 0.2 * (1.0 - smoothstep(0.0, 0.25, t))
			var bulge: float = 0.05 * sin(t * PI * 2.0 + float(k))
			var off: float = lerpf(0.4, 0.15, pow(t, 0.8)) + flare + bulge
			pts.append(Vector3(sin(a) * off, lerpf(0.3, CROWN_Y + 0.05, t), -cos(a) * off))
			rad.append(lerpf(0.31, 0.15, t) + flare * 0.5)
		mb.tube("Bark", pts, rad, 8, 2.0, 0.09, float(k) * 1.9, false, true)
		strands.append(pts)
	mb.tube("Bark", [Vector3(0, 0.3, 0), Vector3(0, 2.4, 0), Vector3(0, CROWN_Y, 0)] as Array[Vector3],
		[0.38, 0.27, 0.17] as Array[float], 8, 2.0, 0.05, 0.3, false, true)
	# Roots pouring over the plinth steps into the ground.
	for k: int in 4:
		var d: Vector3 = NatureKit.dir_deg(45.0 + 90.0 * float(k) + rng.randf_range(-12.0, 12.0))
		NatureKit.root(mb, d * 0.35 + Vector3(0, 0.62, 0), d * 0.95 + Vector3(0, 0.55, 0), d * 1.4 + Vector3(0, -0.25, 0),
			0.16, 0.06, float(k) * 2.3)
	# Dark thorns spiralling up the strands.
	for k: int in 3:
		var pts: Array = strands[k]
		for i: int in range(1, 11):
			if (i + k) % 2 == 1:
				continue
			var p: Vector3 = pts[i]
			var out := Vector3(p.x, 0.0, p.z).normalized()
			var t: float = float(i) / 11.0
			var d: Vector3 = (out + Vector3.UP * 0.35 + out.cross(Vector3.UP) * 0.3).normalized()
			mb.spike("Thorn", p + out * lerpf(0.2, 0.1, t), d, lerpf(0.42, 0.26, t), lerpf(0.07, 0.045, t), float(i))
	# The bramble vine hooking out of the foot at the front-left, thorny.
	var v: Array[Vector3] = [Vector3(-0.28, 0.55, -0.22), Vector3(-0.78, 1.05, -0.55), Vector3(-0.98, 1.8, -0.6),
		Vector3(-0.8, 2.35, -0.42), Vector3(-0.52, 2.42, -0.3)]
	mb.tube("Bark", v, [0.12, 0.1, 0.085, 0.07, 0.05] as Array[float], 6, 1.0, 0.1, 3.0, false, true)
	for i: int in range(1, 4):
		var d: Vector3 = (v[i] - v[i - 1]).cross(Vector3.UP).normalized()
		mb.spike("Thorn", v[i], (d + Vector3.UP * 0.4).normalized(), 0.3, 0.05, float(i))
		mb.spike("Thorn", v[i] + (v[i + 1] - v[i]) * 0.5, (-d + Vector3.UP * 0.2).normalized(), 0.26, 0.045, float(i) + 1.0)
	# Two curled bramble tendrils rising above the crown (the silhouette's tip).
	for s: float in [-1.0, 1.0]:
		var c: Array[Vector3] = [Vector3(s * 0.14, CROWN_Y - 0.1, 0.05 * s), Vector3(s * 0.34, CROWN_Y + 0.6, 0.12 * s),
			Vector3(s * 0.42, CROWN_Y + 1.25, 0.0), Vector3(s * 0.25, CROWN_Y + 1.7, -0.1 * s),
			Vector3(s * 0.02, CROWN_Y + 1.78, -0.05 * s), Vector3(-s * 0.06, CROWN_Y + 1.58, 0.0)]
		if s > 0.0:
			for i: int in c.size():
				c[i] = c[i] * Vector3(1, 0.85, 1) + Vector3(0, CROWN_Y * 0.15, 0)
		mb.tube("Bark", c, [0.075, 0.065, 0.055, 0.045, 0.035, 0.025] as Array[float], 5, 1.0, 0.05, s)
		mb.spike("Thorn", c[2], Vector3(s, 0.4, 0).normalized(), 0.22, 0.04)
	# A side twig at the right ending in a spray of leaves (the pennant hangs from it).
	var tw: Array[Vector3] = [Vector3(0.2, 2.95, 0.0), Vector3(0.62, 3.22, 0.02), Vector3(1.04, 3.3, 0.04)]
	mb.tube("Bark", tw, [0.09, 0.07, 0.05] as Array[float], 6, 1.0, 0.05, 1.0)
	for k: int in 5:
		var d: Vector3 = (Vector3(1.0, 0.0, 0.0) + NatureKit.dir_deg(72.0 * float(k)) * 0.9 + Vector3.UP * 0.45).normalized()
		var base: Vector3 = tw[2] + Vector3(0, 0.02, 0)
		var bend: Vector3 = (d + Vector3.DOWN * 0.6).normalized()
		var nn: Vector3 = (Vector3.UP + d * 0.3).normalized()
		mb.strip("LeafCard", [base, base + d * 0.3, base + d * 0.3 + bend * 0.3] as Array[Vector3],
			d.cross(Vector3.UP).normalized(), 0.34, [nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())


func _mesh_pennant(mb: NatureKit.MB) -> void:
	mb.banner(Vector3(0.64, 3.16, 0.0), Vector3.FORWARD, 0.5, 1.3, 2.3)


## The crown cup (built at the origin, placed at CROWN_Y): a bark collar, five team sepal leaves curling out, six
## glowing petals cupping the bud. `lost` = two petals and a sepal torn off below 50 % HP.
func _mesh_crown(mb: NatureKit.MB, lost: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2622
	if not lost:
		mb.lathe("Bark", Vector3.ZERO, [Vector2(0.12, -0.12), Vector2(0.24, 0.02), Vector2(0.33, 0.14),
			Vector2(0.28, 0.22), Vector2(0.14, 0.26)] as Array[Vector2], 8, 1.0)
	if not lost:
		for k: int in 5:
			var a: float = TAU * float(k) / 5.0 - 0.5
			var d := Vector3(cos(a), 0, sin(a))
			var pts: Array[Vector3] = [d * 0.22 + Vector3(0, 0.12, 0), d * 0.72 + Vector3(0, 0.36, 0),
				d * 1.2 + Vector3(0, 0.26, 0), d * 1.45 + Vector3(0, -0.06, 0)]
			var nn: Vector3 = (Vector3.UP + d * 0.3).normalized()
			mb.strip("LeafCard", pts, Vector3(-d.z, 0, d.x), 0.78, [nn, nn, nn, nn] as Array[Vector3], rng.randf(),
				rng.randf())
	for k: int in 6:
		if (k == 1 or k == 2) != lost:
			continue
		var a: float = TAU * (float(k) + 0.5) / 6.0 - 0.5
		var d := Vector3(cos(a), 0, sin(a))
		var pts: Array[Vector3] = []
		var nrm: Array[Vector3] = []
		for s: int in 5:
			var t: float = float(s) / 4.0
			pts.append(d * (0.17 + 0.62 * t - 0.12 * t * t) + Vector3(0, 0.18 + 0.9 * t - 0.14 * t * t, 0))
			nrm.append((Vector3.UP * 0.7 - d * 0.4 + d * t * 0.7).normalized())
		mb.strip("Petal", pts, Vector3(-d.z, 0, d.x), 0.56, nrm, float(k) / 6.0, rng.randf())


## The bud: an egg-shaped beating seed-heart (nature_keep_seed.gdshader) with a few stamens around it.
func _mesh_bud(mb: NatureKit.MB) -> void:
	mb.sphere("Heart", Vector3.ZERO, 0.37, 1.25, 12, 8)
	for k: int in 5:
		var a: float = TAU * float(k) / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		var tip: Vector3 = d * 0.4 + Vector3(0, 0.48, 0)
		mb.tube("Heart", [d * 0.12 + Vector3(0, 0.1, 0), d * 0.26 + Vector3(0, 0.3, 0), tip] as Array[Vector3],
			[0.03, 0.025, 0.02] as Array[float], 4, 1.0)
		mb.sphere("Heart", tip + Vector3(0, 0.04, 0), 0.06, 1.0, 6, 4)


# ============================================================ aura, ground, scaffold, wreck

## The aura pulse (not part of Body: never rises, squashes or counts in the height).
func _build_aura_ring() -> void:
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_mat.disable_fog = true  # G-E 5: an additive quad must not fog
	_ring_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_ring_mat.albedo_texture = NatureKit.ring_texture()
	_ring_mat.albedo_color = Color(_ring_col, 0.0)
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * AURA_RADIUS * 2.0 / 0.94   # the bright band of the texture sits at 94 % radius
	_ring = MeshInstance3D.new()
	_ring.name = "AuraRing"
	_ring.mesh = pm
	_ring.material_override = _ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = Vector3(0, 0.06, 0)
	add_child(_ring)


## Moss patch (chamfered plinth, fairy ring r 1.55) instead of the plain stain; ground dressing instead of cubes.
func _build_ground() -> void:
	super()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.2, 5.2)
	_decal.mesh = pm
	_ground_mat = NatureKit.ground_material(5.2, 1.1, 1.52, 0.4, 1.6, 12.0, 3.3)
	_decal.material_override = _ground_mat
	var rubble := get_node_or_null(^"Rubble") as Node3D
	if rubble:
		rubble.visible = false
	var mi: MeshInstance3D = NatureKit.node("GroundDressing", KEY + "dressing", _mesh_dressing, _mats, self, false)
	mi.set_instance_shader_parameter(&"ao_bottom", -0.3)
	mi.set_instance_shader_parameter(&"ao_height", 1.2)


func _mesh_dressing(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2624
	NatureKit.dressing(mb, rng, 3, 2, 0, 1.35, 1.75, _dress_blocked, 0.7)


static func _dress_blocked(p: Vector3) -> bool:
	return p.distance_to(Vector3(-0.95, 0, -0.6)) < 0.55


func _build_scaffold_nature() -> void:
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	add_child(_scaffold)
	NatureKit.node("ScaffoldParts", KEY + "scaffold", _mesh_scaffold, _mats, _scaffold)
	_scaffold.visible = false


func _mesh_scaffold(mb: NatureKit.MB) -> void:
	var h: float = 1.15
	var top: float = 4.4
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var b := Vector3(c.x * h, 0.0, c.y * h)
		mb.tube("Wood", [b, b + Vector3(0.02 * c.x, top * 0.5, 0), b + Vector3(0, top, 0)] as Array[Vector3],
			[0.07, 0.065, 0.055] as Array[float], 6, 1.0, 0.1, c.x + c.y)
	for y: float in [2.0, 3.7]:
		for s: float in [-1.0, 1.0]:
			mb.box("Wood", Vector3(0, y, s * h), Vector3(h * 2.0 + 0.2, 0.07, 0.34), Basis(Vector3.BACK, s * 0.05))
			mb.box("Wood", Vector3(s * h, y, 0), Vector3(0.34, 0.07, h * 2.0 + 0.2), Basis(Vector3.RIGHT, s * 0.05))
	for p: Vector3 in [Vector3(1.5, 0.18, -1.3), Vector3(1.3, 0.18, -1.55)]:
		mb.box("Stone", p, Vector3(0.34, 0.34, 0.34), Basis(Vector3.UP, p.x))


func _build_wreck_nature() -> void:
	_wreck = Node3D.new()
	_wreck.name = "Wreck"
	add_child(_wreck)
	NatureKit.node("WreckParts", KEY + "wreck", _mesh_wreck, _mats, _wreck)
	_wreck.visible = false


## The snapped trunk: a jagged stump, splintered strands lying on the plinth, thorns, sap embers.
func _mesh_wreck(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2625
	mb.loft("Wood", [NatureKit.ring_n(8, 0.34), NatureKit.ring_n(8, 0.3)], [1.2, 1.3], true)
	mb.tube("Bark", [Vector3(0, 0.3, 0), Vector3(0, 1.25, 0)] as Array[Vector3], [0.42, 0.36] as Array[float], 8, 2.0, 0.1,
		0.0, false, false)
	for k: int in 6:
		var a: float = TAU * float(k) / 6.0 + rng.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var b: Vector3 = d * rng.randf_range(0.18, 0.3) + Vector3(0, 1.2, 0)
		var h: float = rng.randf_range(0.3, 0.8)
		mb.tube("Bark", [b, b + d * 0.05 + Vector3(0, h * 0.6, 0), b + d * 0.09 + Vector3(0, h, 0)] as Array[Vector3],
			[rng.randf_range(0.08, 0.13), 0.06, 0.0] as Array[float], 5, 1.0, 0.0, 0.0, false, false)
	for k: int in 3:
		var s := Vector3(rng.randf_range(-0.5, 0.5), 0.5, rng.randf_range(-0.5, 0.5))
		var e: Vector3 = s + NatureKit.dir_deg(rng.randf_range(0.0, 360.0)) * rng.randf_range(0.9, 1.3)
		mb.tube("Bark", [s, s.lerp(e, 0.5) + Vector3(0, 0.06, 0), e + Vector3(0, -0.1, 0)] as Array[Vector3],
			[0.13, 0.11, 0.07] as Array[float], 6, 1.0, 0.1, float(k), true, true)
		mb.spike("Thorn", s.lerp(e, 0.5), Vector3.UP, 0.25, 0.05)
	for k: int in 3:
		mb.box("Gate", Vector3(rng.randf_range(-0.6, 0.6), 0.46, rng.randf_range(-0.6, 0.6)), Vector3.ONE * 0.16,
			Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, 0.3))


# ============================================================ particles, states, hooks

func _build_ambient() -> void:
	var glow_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.15, 0.7, 1.0], [Color(glow_color, 0.0),
		Color(glow_color, 1.0), Color(glow_color, 0.8), Color(glow_color, 0.0)], _glow_ramps)
	var po := NatureKit.process(Vector3.UP, 60.0, 0.15, 0.4, Vector3(0, 0.1, 0), 0.08, 0.035, glow_ramp)
	po.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	po.emission_sphere_radius = 0.6
	po.color = NatureKit.MOTE_DIM
	po.turbulence_enabled = true
	po.turbulence_noise_strength = 0.3
	_ambient = [_particles("Pollen", _body, Vector3(0, ORB_Y, 0), 10, 2.2, po, true, false)] as Array[GPUParticles3D]


func _build_state_nodes() -> void:
	super()
	for b: GPUParticles3D in _blaze:
		NatureKit.make_withering(b, 0.7, 12)


## The tower fired: the bud flares (boost x3.5, +30 % size) for 0.1 s, then fades in 0.18 s; the cup flexes open.
func play_shot() -> void:
	if _destroyed or _progress < 1.0:
		return
	_shot_left = SHOT_HOLD + SHOT_FADE
	_flex = 1.0


func _idle(delta: float) -> void:
	var k: float = 0.0
	var heart: ShaderMaterial = _mats["Heart"]
	if _shot_left > 0.0:
		_shot_left = maxf(_shot_left - delta, 0.0)
		k = 1.0 if _shot_left > SHOT_FADE else _shot_left / SHOT_FADE
		heart.set_shader_parameter(&"boost", _sel_boost() * (1.0 + 2.5 * k))
		if _shot_left <= 0.0:
			heart.set_shader_parameter(&"boost", _sel_boost())
	_orb.position.y = ORB_Y + 0.06 * sin(_t * 2.2)
	if _float_appear >= 1.0:
		_orb.scale = Vector3.ONE * (1.0 + 0.3 * k)
	_orb.rotation.y += delta * 0.6
	# The cup turns slowly, breathes, and flexes open on a shot (droops when nearly dead).
	_flex = maxf(_flex - delta * 3.0, 0.0)
	var open: float = 1.0 + 0.16 * _flex + 0.03 * sin(_t * 1.3)
	var droop: float = 0.9 if _dying else 1.0
	var b := Basis(Vector3.UP, _t * deg_to_rad(8.0)).scaled(Vector3(open, droop * (1.0 - 0.08 * _flex), open))
	if _crown.visible and _progress >= 1.0:
		_crown.basis = b
		_crown_lost.basis = b
	# The aura pulse (only while built).
	var kk: float = clampf(fmod(_t, AURA_PERIOD) / AURA_GROW, 0.0, 1.0)
	var s: float = lerpf(0.12, 1.0, 1.0 - pow(1.0 - kk, 2.0))
	_ring.scale = Vector3(s, 1.0, s)
	var a: float = smoothstep(0.0, 0.12, kk) * (1.0 - smoothstep(0.72, 1.0, kk))
	_ring_mat.albedo_color = Color(_ring_col, a * 0.6)
	_cam_check -= delta
	if _cam_check <= 0.0:
		_cam_check = 0.5
		var d: float = NatureKit.camera_distance(self, global_position + Vector3(0, 3.0, 0))
		_set_ambient(d < (NEAR_OFF if _ambient_on else NEAR_ON) and _progress >= 1.0)


func _set_ambient(on: bool) -> void:
	if on == _ambient_on:
		return
	_ambient_on = on
	for p: GPUParticles3D in _ambient:
		p.emitting = on


func _on_progress(building: bool) -> void:
	_ring.visible = not building
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"build", _progress)
	if building:
		_set_ambient(false)
		if _progress <= 0.0:
			for part: GeometryInstance3D in _parts:
				part.visible = false   # at 0 only the glowing outline shows (art-keep.md 8.2)
	else:
		_cam_check = 0.0


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	if _progress >= 1.0:
		_crown_lost.visible = not smoke_on
	NatureKit.apply_health(_mats, _health_ratio, smoke_on, fire_on)
	(_mats["Heart"] as ShaderMaterial).set_shader_parameter(&"energy", ORB_ENERGY * 0.55 if fire_on else ORB_ENERGY)
	_dying = fire_on
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"damage", 1.0 if fire_on else (0.5 if smoke_on else 0.0))


func _on_team_color(g: Color) -> void:
	NatureKit.apply_team(_mats, _team_color)
	_ring_col = g
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"glow_color", g)
	for gr: Gradient in _glow_ramps:
		for i: int in gr.get_point_count():
			gr.set_color(i, Color(g, gr.get_color(i).a))


func _on_destroy_start() -> void:
	_shot_left = 0.0
	_ring.visible = false
	_set_ambient(false)


func _on_destroy(t_now: float) -> void:
	if _decal.material_override != _ground_mat:
		_decal.material_override = _ground_mat
	var k: float = clampf((t_now - 1.2) / 1.0, 0.0, 1.0)
	_ground_mat.set_shader_parameter(&"scorch", k)
	if t_now >= 0.5:
		NatureKit.apply_wreck(_mats, k)


func _apply_rim_and_glow() -> void:
	super()
	if _ready_done and _body != null and not _mats.is_empty():
		NatureKit.apply_rim(_mats, _team_color, _sel_k, _progress < 1.0 and not _destroyed)
		NatureKit.apply_boost(_mats, _sel_boost())
