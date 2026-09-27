class_name WardenModel
extends CharacterModel
## Ruin Warden (art-units.md 5.6, polished in task A2.7): an ancient guardian golem of hewn, mossy ruin stone bound in
## old bronze, hunched like a great ape. Read from the RTS camera by a wide stone yoke of shoulders (a bronze pauldron
## on the left, a moss cap with a sapling on the right), long arms with bronze bracers and huge fists, and a broken
## COLUMN DRUM on a bronze haft as a maul, its head resting on the ground. The head is a heavy brow block with an amber
## eye slit and a bronze circlet, hovering over the torso on a disc of amber light (the "floating gap").
## Glow points: the chest core (keystone diamond, 3.2, pulses and flares), the eye slit + gap light (2.0), the rune
## band of the maul (flashes on each slam), glowing amber veins in the light stone (crack shader).
## Motion (all procedural, kit rules): slow breathing and a look-around idle with the head bobbing on its light;
## a heavy stomping walk with rolling shoulders, knuckle swing and dust at the footfalls; the attack is an overhead
## two-arm SLAM (wind-up 0.07 s, impact at 0.12 s = the kit strike frame, damage stays instant) with the core charging,
## a dust shockwave, stone chips and amber sparks where the maul lands; the hit knocks the head and chips stone off;
## the death (1.0 s, `crumble`) rears up as the core flares, the knees give, the head topples off, the arms fall away
## and the body collapses into a burst of rubble and dust while an amber soul rises out of it.
## Hooks: those of CharacterModel, unchanged (set_team_color is a no-op: no team colour on the warden).
## Draw instances: 7 merged pivots + Core, GapLight, MaulRune + blob + motes (+ one-shot emitters while they play).

## Kept for tests / tools that read it (the Shadow army script used the same field).
@export var unit_kind: StringName = &"warden"
## Per-unit multiplier on the glow parts (the palette energies are material-wide), times veterancy / haste.
@export var glow_gain: float = 1.15

const NEUTRAL_MATS := "res://art/units/neutral/materials/"
const AMBER := Color(1.0, 0.78, 0.32)
const DUST := Color(0.40, 0.37, 0.30)
const SHOULDER_L := Vector3(-0.60, 1.44, 0.02)
const SHOULDER_R := Vector3(0.60, 1.44, 0.02)
const GRIP := Vector3(0.66, 0.68, 0.10)        # right fist (model space): the maul's grip
const MAUL_TILT := -40.0                        # deg about x at rest: the head rests on the ground, front-right
const MAUL_HEAD := 0.54                         # grip -> head centre (m, along -Y of the maul)
const ATTACK_LEN := 0.66
const STRIKE := 0.12

static var _nmats: Dictionary = {}
static var _wmesh: Dictionary = {}
static var _wfx: Dictionary = {}

var _core: MeshInstance3D
var _gap: MeshInstance3D
var _rune: MeshInstance3D
var _maul_tip: Node3D
var _slam_at: Node3D
var _ring: MeshInstance3D
var _slam_dust: GPUParticles3D
var _slam_chips: GPUParticles3D
var _slam_sparks: GPUParticles3D
var _step_dust: Array[GPUParticles3D] = []
var _hit_chips: GPUParticles3D

var _body: Array[GeometryInstance3D] = []
var _body_alpha: PackedFloat32Array = PackedFloat32Array()
var _slam_t: float = 99.0
var _death_glow: float = 1.0
var _core_written: float = -1.0
var _rune_written: float = -1.0
var _fade_written: float = 0.0
var _ring_written: float = -1.0
var _last_step: float = 0.0
var _step_i: int = 0


static func _nmat(name: StringName) -> Material:
	if not _nmats.has(name):
		_nmats[name] = load(NEUTRAL_MATS + String(name) + ".tres")
	return _nmats[name]


# ================================================================ parts

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var fx: Node3D = $Fx
	var stone := _nmat(&"warden_granite")        # light veined stone (warden_stone with finer, calmer veins)
	var dark := palette(&"warden_stone_dark")
	var moss := palette(&"warden_moss")
	var glow := palette(&"warden_glow")
	var bronze := _nmat(&"warden_bronze")

	# ---- Legs: short stone pillars, bronze knee guards and ankle rings, flat slab feet.
	for side: int in [-1, 1]:
		var leg: Node3D = $Root/Hips/LegL if side < 0 else $Root/Hips/LegR
		var s := float(side)
		add_part(leg, rough(box(Vector3(0.30, 0.32, 0.34)), 0.035, 3.0 + s), dark, Vector3(0.28 * s, 0.50, 0.0),
			Vector3(0, 0, -4.0 * s))
		add_part(leg, box(Vector3(0.22, 0.13, 0.10)), bronze, Vector3(0.29 * s, 0.36, 0.18), Vector3(-12, 0, 0))
		add_part(leg, rough(box(Vector3(0.28, 0.30, 0.30)), 0.03, 5.0 + s), dark, Vector3(0.30 * s, 0.25, 0.03))
		add_part(leg, cyl(0.175, 0.175, 0.07, 8), bronze, Vector3(0.30 * s, 0.13, 0.03))
		add_part(leg, rough(box(Vector3(0.36, 0.14, 0.48)), 0.03, 7.0 + s), dark, Vector3(0.31 * s, 0.07, 0.08))

	# ---- Hips: pelvis block, bronze belt with a round buckle, a hanging moss apron.
	add_part(hips, rough(box(Vector3(0.66, 0.26, 0.44)), 0.04, 11.0), dark, Vector3(0, 0.74, 0))
	add_part(hips, box(Vector3(0.72, 0.09, 0.50)), bronze, Vector3(0, 0.86, 0))
	add_part(hips, cyl(0.13, 0.13, 0.06, 8), bronze, Vector3(0, 0.85, 0.26), Vector3(90, 0, 0))
	add_part(hips, rough(box(Vector3(0.34, 0.30, 0.06)), 0.03, 12.0), moss, Vector3(0, 0.66, 0.245), Vector3(6, 0, 0))

	# ---- Chest: a hewn hexagonal keg of light stone (amber veins), split pectoral slabs around the keystone core,
	# bronze band and gorget, stacked stones down the back under a moss mantle, two shoulder boulders.
	add_part(chest, rough(cyl(0.36, 0.30, 0.32, 6), 0.03, 13.0), stone, Vector3(0, 0.99, 0.02), Vector3(0, 30, 0),
		Vector3(1, 1, 0.8))
	add_part(chest, rough(cyl(0.56, 0.40, 0.62, 6), 0.045, 14.0), stone, Vector3(0, 1.30, 0.04), Vector3(10, 30, 0),
		Vector3(1, 1, 0.74))
	add_part(chest, cyl(0.47, 0.45, 0.09, 6), bronze, Vector3(0, 1.08, 0.03), Vector3(8, 30, 0), Vector3(1, 1, 0.78))
	for side: int in [-1, 1]:
		var s := float(side)
		add_part(chest, rough(box(Vector3(0.34, 0.32, 0.16)), 0.03, 15.0 + s), dark, Vector3(0.20 * s, 1.38, 0.31),
			Vector3(10, -12.0 * s, 4.0 * s))
	add_part(chest, torus(0.10, 0.155, 10), bronze, Vector3(0, 1.36, 0.365), Vector3(100, 0, 0))
	add_part(chest, torus(0.24, 0.34, 12), bronze, Vector3(0, 1.60, 0.10), Vector3(14, 0, 0))
	add_part(chest, rough(box(Vector3(0.28, 0.24, 0.20)), 0.03, 16.0), dark, Vector3(0.02, 1.50, -0.30), Vector3(20, 10, 8))
	add_part(chest, rough(box(Vector3(0.32, 0.26, 0.20)), 0.03, 17.0), dark, Vector3(-0.04, 1.27, -0.35), Vector3(-8, -12, 5))
	add_part(chest, rough(box(Vector3(0.26, 0.22, 0.18)), 0.03, 18.0), dark, Vector3(0.05, 1.05, -0.31), Vector3(6, 14, -6))
	add_part(chest, sphere(0.30, 10, 5), moss, Vector3(0.06, 1.58, -0.20), Vector3(0, 20, 0), Vector3(1.25, 0.30, 0.75))
	add_part(chest, rough(box(Vector3(0.14, 0.26, 0.05)), 0.02, 19.0), moss, Vector3(-0.22, 1.44, -0.41), Vector3(-10, 0, 6))
	add_part(chest, rough(box(Vector3(0.12, 0.34, 0.05)), 0.02, 20.0), moss, Vector3(0.20, 1.40, -0.42), Vector3(-12, 0, -4))
	# A broken column fragment grown into its back (the ruin it was carved from): the tall vertical accent.
	add_part(chest, cyl(0.19, 0.21, 0.10, 8), bronze, Vector3(-0.26, 1.55, -0.30), Vector3(-16, 0, 26))
	add_part(chest, fluted(0.15, 0.125, 0.66, 6, 42.0), stone, Vector3(-0.405, 1.835, -0.38), Vector3(-16, 0, 26))
	add_part(chest, sphere(0.13, 8, 4), moss, Vector3(-0.53, 2.12, -0.46), Vector3(-16, 0, 26), Vector3(1.2, 0.45, 1.2))
	# Left shoulder: boulder under a bronze pauldron with an amber rune line.
	add_part(chest, rough(box(Vector3(0.42, 0.40, 0.42)), 0.05, 21.0), dark, Vector3(-0.60, 1.50, 0.0), Vector3(8, 18, 12))
	add_part(chest, sphere(0.24, 10, 5), bronze, Vector3(-0.64, 1.65, 0.02), Vector3(0, 0, 16), Vector3(1.0, 0.5, 1.05))
	add_part(chest, box(Vector3(0.20, 0.05, 0.05)), glow, Vector3(-0.64, 1.70, 0.22), Vector3(0, 0, 14))
	# Right shoulder: boulder, moss cap and a sapling that took root on it (the asymmetric accent).
	add_part(chest, rough(box(Vector3(0.40, 0.38, 0.40)), 0.05, 22.0), dark, Vector3(0.60, 1.48, 0.0), Vector3(-6, -14, -12))
	add_part(chest, sphere(0.26, 10, 5), moss, Vector3(0.60, 1.68, 0.0), Vector3.ZERO, Vector3(1.0, 0.42, 1.0))
	add_part(chest, cyl(0.025, 0.045, 0.42, 5), palette(&"fire_wood"), Vector3(0.63, 1.88, -0.06), Vector3(-8, 0, -12))
	add_part(chest, sphere(0.15, 8, 4), moss, Vector3(0.68, 2.08, -0.09), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	add_part(chest, sphere(0.11, 8, 4), moss, Vector3(0.55, 1.99, -0.02), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	# Keystone core (own glow: pulses, charges on the wind-up, flares at death) and the gap light under the head.
	_core = add_part(chest, _octa(), _nmat(&"warden_core_glow"), Vector3(0, 1.36, 0.39), Vector3(90, 0, 0),
		Vector3(1.0, 1.0, 1.0), true, "Core")
	_core.set_meta(&"own_glow", true)
	_gap = add_part(chest, sphere(0.10, 10, 5), glow, Vector3(0, 1.53, 0.16), Vector3.ZERO, Vector3(2.3, 0.45, 2.1),
		true, "GapLight")

	# ---- Head: heavy block, overhanging brow, jaw, amber eye slit, bronze circlet with a crest, moss tuft.
	add_part(head, rough(box(Vector3(0.44, 0.30, 0.40)), 0.035, 23.0), stone, Vector3(0, 1.70, 0.20))
	add_part(head, rough(box(Vector3(0.52, 0.12, 0.22)), 0.025, 24.0), dark, Vector3(0, 1.83, 0.31), Vector3(-12, 0, 0))
	add_part(head, rough(box(Vector3(0.36, 0.13, 0.30)), 0.025, 25.0), dark, Vector3(0, 1.57, 0.24))
	add_part(head, box(Vector3(0.34, 0.085, 0.06)), glow, Vector3(0, 1.71, 0.405))
	add_part(head, torus(0.215, 0.285, 12), bronze, Vector3(0, 1.79, 0.19), Vector3(-10, 0, 0))
	for side: int in [-1, 1]:   # two stubby broken horns of stone on the brow corners
		add_part(head, cyl(0.03, 0.075, 0.20, 5), dark, Vector3(0.21 * side, 1.92, 0.24), Vector3(-20, 0, -28.0 * side))

	# ---- Arms: long stone arms, bronze bracers, huge fists; the right one holds the column maul.
	for side: int in [-1, 1]:
		var arm: Node3D = $Root/Chest/ArmL if side < 0 else $Root/Chest/ArmR
		var s := float(side)
		add_part(arm, rough(box(Vector3(0.26, 0.38, 0.28)), 0.03, 30.0 + s), stone, Vector3(0.63 * s, 1.25, 0.02),
			Vector3(0, 0, 5.0 * s))
		add_part(arm, sphere(0.14, 8, 4), dark, Vector3(0.65 * s, 1.06, 0.04))
		add_part(arm, rough(cyl(0.16, 0.21, 0.34, 6), 0.025, 32.0 + s), stone, Vector3(0.66 * s, 0.90, 0.06))
		add_part(arm, cyl(0.225, 0.225, 0.15, 8), bronze, Vector3(0.66 * s, 0.87, 0.06))
		add_part(arm, rough(box(Vector3(0.34, 0.30, 0.34)), 0.04, 34.0 + s), dark, Vector3(0.66 * s, 0.66, 0.08))
	var arm_r: Node3D = $Root/Chest/ArmR
	add_part(arm_r, box(Vector3(0.05, 0.11, 0.04)), glow, Vector3(0.66, 0.87, 0.29))
	_build_maul(arm_r, stone, bronze)

	# ---- FX: amber motes from the veins (looping, < 45 m); one-shot slam / step / hit / death emitters.
	var motes := make_motes(AMBER, 6, 2.0, 0.35, 0.28, 0.07)
	motes.name = "Motes"
	motes.position = Vector3(0, 1.15, 0.05)
	fx.add_child(motes)
	_slam_at = Node3D.new()
	_slam_at.name = "SlamAt"
	_slam_at.position = Vector3(0.45, 0.04, 1.0)
	fx.add_child(_slam_at)
	_slam_dust = _burst("SlamDust", _slam_at, 22, 1.0, _ppm_ring_dust(), _smoke_draw(0.9))
	_slam_chips = _burst("SlamChips", _slam_at, 10, 0.8, _ppm_chips(0.12, 2.6, 4.4, 55.0), _chip_draw(0.13))
	_slam_sparks = make_motes(AMBER, 12, 0.6, 0.12, 3.2, 0.08, false, true)
	_slam_sparks.name = "SlamSparks"
	_slam_at.add_child(_slam_sparks)
	_ring = MeshInstance3D.new()
	_ring.name = "SlamRing"
	_ring.mesh = torus(0.42, 0.52, 24)
	_ring.material_override = _ring_mat()
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	_ring.set_meta(&"keep_separate", true)
	_slam_at.add_child(_ring)
	for i: int in 2:
		var sd := _burst("StepDust%d" % i, fx, 5, 0.7, _ppm_step_dust(), _smoke_draw(0.45))
		sd.position = Vector3(0.3 * (i * 2 - 1), 0.05, 0.1)
		_step_dust.append(sd)
	_hit_chips = _burst("HitChips", chest, 6, 0.55, _ppm_chips(0.1, 1.4, 2.6, 40.0), _chip_draw(0.09))
	_hit_chips.position = Vector3(0, 1.36, 0.36) - model_origin(chest)
	var rubble := _burst("Rubble", fx, 14, 1.0, _ppm_rubble(), _chip_draw(0.17))
	rubble.position = Vector3(0, 1.0, 0.05)
	rubble.set_meta(&"death_fx", true)
	var dust := _burst("DeathDust", fx, 14, 1.4, _ppm_death_dust(), _smoke_draw(0.95))
	dust.position = Vector3(0, 0.45, 0.05)
	dust.set_meta(&"death_fx", true)
	var tmp := make_motes(AMBER, 1, 1.0, 0.1, 1.0, 0.11)   # only to get the shared additive mote quad
	var mote_quad := tmp.draw_pass_1
	tmp.free()
	var soul := _burst("Soul", fx, 16, 1.3, _ppm_soul(), mote_quad)
	soul.position = Vector3(0, 1.3, 0.2)
	soul.set_meta(&"death_fx", true)
	ensure_shadow_blob(0.64, Color(0.06, 0.05, 0.03, 0.5))


## The column maul in the right fist: a bronze haft with a pommel and a socket, a broken column drum as the head
## (bronze end caps) and an amber rune band (own glow, flashes on the slam). Built in a frame at GRIP tilted MAUL_TILT.
func _build_maul(arm_r: Node3D, stone: Material, bronze: Material) -> void:
	var frame := Transform3D(Basis(Vector3.RIGHT, MAUL_TILT * DEG), GRIP)
	var across := Basis(Vector3.BACK, PI * 0.5)         # cylinder axis Y -> X (the drum lies across the haft)
	_maul_part(arm_r, frame, cyl(0.075, 0.075, 0.09, 8), bronze, Vector3(0, 0.25, 0), Basis())
	_maul_part(arm_r, frame, cyl(0.05, 0.06, 0.72, 6), palette(&"warden_stone_dark"), Vector3(0, -0.12, 0), Basis())
	for y: float in [0.12, -0.10]:
		_maul_part(arm_r, frame, cyl(0.07, 0.07, 0.05, 8), bronze, Vector3(0, y, 0), Basis())
	_maul_part(arm_r, frame, cyl(0.10, 0.13, 0.10, 8), bronze, Vector3(0, -0.33, 0), Basis())
	_maul_part(arm_r, frame, fluted(0.21, 0.18, 0.40, 8, 40.0), stone, Vector3(0, -MAUL_HEAD, 0), across)
	for x: float in [-0.19, 0.19]:
		_maul_part(arm_r, frame, cyl(0.20, 0.20, 0.04, 8), palette(&"warden_stone_dark"), Vector3(x, -MAUL_HEAD, 0), across)
	_rune = add_part(arm_r, cyl(0.218, 0.218, 0.06, 8), palette(&"warden_glow"), frame * Vector3(0, -MAUL_HEAD, 0),
		_deg((frame.basis * across).get_euler()), Vector3.ONE, true, "MaulRune")
	_rune.set_meta(&"own_glow", true)
	_maul_tip = Node3D.new()
	_maul_tip.name = "MaulTip"
	_maul_tip.position = frame * Vector3(0, -MAUL_HEAD, 0) - model_origin(arm_r)
	arm_r.add_child(_maul_tip)


func _maul_part(pivot: Node3D, frame: Transform3D, mesh: Mesh, mat: Material, local: Vector3, b: Basis) -> void:
	add_part(pivot, mesh, mat, frame * local, _deg((frame.basis * b).get_euler()))


static func _deg(r: Vector3) -> Vector3:
	return r / DEG


func _after_ready() -> void:
	var root := get_node_or_null(^"Root")
	if root:
		_collect_body(root)
	_write_own_glows(true)


func _collect_body(n: Node) -> void:
	for c: Node in n.get_children():
		if c is MeshInstance3D and c != _ring:
			_body.append(c as GeometryInstance3D)
		if not c is GPUParticles3D:
			_collect_body(c)


# ================================================================ hooks

## No team colour on the warden (art-units.md 5.6).
func set_team_color(_c: Color) -> void:
	pass


func glow_level() -> float:
	return super.glow_level() * glow_gain


func play_hit() -> void:
	var before := _hit_t
	super.play_hit()
	if _hit_t == 0.0 and before != 0.0 and _hit_chips and _tier == 0:
		_hit_chips.restart()


func play_death() -> void:
	if _dead:
		return
	_body_alpha.resize(_body.size())
	for i: int in _body.size():
		_body_alpha[i] = _body[i].transparency
	_fade_written = 0.0
	_death_glow = 1.0
	super.play_death()


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		# The maul lands: move the slam emitters under its head (on the ground) and fire them.
		if _maul_tip and _slam_at and _slam_at.is_inside_tree():
			var p := _maul_tip.global_position
			_slam_at.global_position = Vector3(p.x, global_position.y + 0.04, p.z)
		_slam_t = 0.0
		if _tier < 2:
			_slam_dust.restart()
			_slam_chips.restart()
			_slam_sparks.restart()


func _on_revive() -> void:
	for i: int in _body.size():
		_body[i].transparency = _body_alpha[i] if i < _body_alpha.size() else 0.0
	_fade_written = 0.0
	_death_glow = 1.0
	_slam_t = 99.0
	if _ring:
		_ring.visible = false
	_write_own_glows(true)


# ================================================================ idle / walk / attack

func _scan_yaw() -> float:
	# Holds a look to one side, then turns its head slowly to the other (the head floats on its light).
	var a := sin(_t * 0.31 + _phase_off * 2.1)
	return 24.0 * DEG * (smoothstep(-0.55, 0.55, a) * 2.0 - 1.0)


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.012 * s, 0))
	_write_rot(P_CHEST, _rest_rot[P_CHEST] + Vector3(1.6 * DEG * s, 0, 0))
	if _tier == 0:
		_write_pos(P_HEAD, _rest_pos[P_HEAD] + Vector3(0, 0.024 * sin(ph + 1.3), 0))
		_write_rot(P_HEAD, _rest_rot[P_HEAD] + Vector3(-2.0 * DEG * s, _scan_yaw(), 0))


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	pos(P_ROOT, Vector3(0, 0.012 * s * w, 0))
	rot(P_CHEST, Vector3(1.6 * DEG * s * w, 0, 0))
	pos(P_HEAD, Vector3(0, 0.024 * sin(ph + 1.3) * w, 0))
	rot(P_HEAD, Vector3(-2.0 * DEG * s * w, _scan_yaw() * w, 0))


## Heavy stomp on top of the kit cycle: high at mid-stance, a hard dip on each footfall, rolling shoulders, the head
## counter-rolling to stay level, knuckles swinging.
func _pose_walk(w: float, rate: float) -> void:
	super._pose_walk(w, rate)
	var s: float = sin(TAU * _walk_p)
	var a: float = absf(s)
	pos(P_ROOT, Vector3(0, (-walk_bounce * a + 0.05 * (1.0 - a) - 0.08 * pow(a, 8.0)) * w, 0))
	rot(P_CHEST, Vector3(7.0 * DEG * w, 5.0 * DEG * s * w, 4.0 * DEG * s * w))
	rot(P_HEAD, Vector3(-6.0 * DEG * w, -5.0 * DEG * s * w, -4.0 * DEG * s * w))
	rot(P_ARM_L, Vector3(-10.0 * DEG * s * w, 0, 0))


## Overhead two-arm slam (replaces the kit's melee_swing; same strike frame 0.12 s, damage stays instant):
## 0-0.07 rear up, maul overhead, core charging Â· 0.07-0.12 slam down, the whole body behind it Â· hold Â· recover.
func _pose_attack(prev: float, t: float) -> bool:
	var sc := swing_scale
	rot(P_ARM_R, Vector3(_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, -150.0 * sc, -14.0) * DEG, 0,
		_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, -10.0, 6.0) * DEG))
	rot(P_ARM_L, Vector3(_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, -95.0 * sc, -30.0) * DEG, 0,
		_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, 12.0, -8.0) * DEG))
	rot(P_CHEST, Vector3(_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, -16.0, 26.0) * DEG,
		_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, 14.0, -10.0) * DEG, 0))
	rot(P_HEAD, Vector3(_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, -14.0, 12.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, 0.06, -0.13),
		_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, -0.04, 0.24)))
	rot(P_LEG_L, Vector3(_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, -6.0, -26.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_kf(t, 0.07, STRIKE, 0.30, ATTACK_LEN, 4.0, 18.0) * DEG, 0, 0))
	if prev < STRIKE and t >= STRIKE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## 0 -> v1 (0..t1) -> v2 (t1..t2), hold v2 (t2..t3), -> 0 (t3..t4). Ease-out in, smooth out.
static func _kf(t: float, t1: float, t2: float, t3: float, t4: float, v1: float, v2: float) -> float:
	if t <= 0.0 or t >= t4:
		return 0.0
	if t < t1:
		return v1 * _ease_out(t / t1)
	if t < t2:
		return lerpf(v1, v2, _ease_in((t - t1) / maxf(t2 - t1, 0.0001)))
	if t < t3:
		return v2
	return v2 * (1.0 - smoothstep(0.0, 1.0, (t - t3) / maxf(t4 - t3, 0.0001)))


# ================================================================ death (crumble, 1.0 s)

func _pose_death(dt: float) -> void:
	_death_t += dt
	var t := _death_t
	var a: float = smoothstep(0.0, 0.18, t)                          # jolt: rears up as the core flares
	var b: float = _ease_in(clampf((t - 0.18) / 0.34, 0.0, 1.0))     # knees give, head topples, arms fall
	var c: float = _ease_in(clampf((t - 0.45) / 0.55, 0.0, 1.0))     # collapse into rubble
	var rear: float = a * (1.0 - b)
	rot(P_CHEST, Vector3((-16.0 * rear + 34.0 * b) * DEG, 0, 7.0 * b * DEG))
	rot(P_HEAD, Vector3((-24.0 * rear + 85.0 * b) * DEG, 0, 30.0 * b * DEG))
	pos(P_HEAD, Vector3(0.12 * b, 0.06 * rear - 0.40 * b - 0.30 * c, 0.44 * b))
	rot(P_ARM_L, Vector3((-35.0 * rear - 8.0 * b) * DEG, 0, (-18.0 * rear - 50.0 * b) * DEG))
	rot(P_ARM_R, Vector3((-45.0 * rear + 28.0 * b) * DEG, 0, (18.0 * rear + 42.0 * b) * DEG))
	pos(P_ARM_L, Vector3(-0.10 * c, -0.32 * c, 0))
	pos(P_ARM_R, Vector3(0.10 * c, -0.32 * c, 0))
	rot(P_LEG_L, Vector3(-30.0 * b * DEG, 0, 0))
	rot(P_LEG_R, Vector3(55.0 * b * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, 0.06 * rear - 0.28 * b - 0.52 * c, -0.05 * rear))
	_root_scale *= Vector3(1.0 + 0.16 * c, 1.0 - 0.45 * c, 1.0 + 0.16 * c)
	if t < 0.3:
		_death_glow = 1.0 + 3.0 * smoothstep(0.0, 0.22, t)
		var g := glow_level() * _death_glow
		for gi: GeometryInstance3D in _glow_nodes:
			gi.set_instance_shader_parameter(&"glow_boost", g)
	else:
		_glows_dead()   # kit: glows to 0, restarts the death_fx emitters (Rubble, DeathDust, Soul)
	_write_fade(smoothstep(0.70, 1.0, t))
	if _shadow:
		_shadow.transparency = clampf((t - 0.7) / 0.3, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _write_fade(fade: float) -> void:
	if absf(fade - _fade_written) <= 0.004:
		return
	_fade_written = fade
	for i: int in _body.size():
		_body[i].transparency = lerpf(_body_alpha[i] if i < _body_alpha.size() else 0.0, 1.0, fade)


# ================================================================ per frame extras

func _extra_process(dt: float) -> void:
	if not _dead:
		if _hit_t < HIT_LEN:
			# The blow knocks the head sideways on its light and rocks the chest.
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_HEAD, Vector3(-10.0 * DEG * k, 0, 7.0 * DEG * k))
			rot(P_CHEST, Vector3(-5.0 * DEG * k, 0, 0))
		if _walk_w > 0.5 and _tier == 0:
			var s: float = absf(sin(TAU * _walk_p))
			if s >= 0.96 and _last_step < 0.96:
				var foot: Node3D = _piv[P_LEG_R] if sin(TAU * _walk_p) > 0.0 else _piv[P_LEG_L]
				var sd: GPUParticles3D = _step_dust[_step_i]
				_step_i = (_step_i + 1) % _step_dust.size()
				if foot and sd.is_inside_tree():
					var fp := foot.global_position
					sd.global_position = Vector3(fp.x, global_position.y + 0.05, fp.z)
					sd.restart()
			_last_step = s
	if _slam_t < 1.0:
		_slam_t += dt
		var u: float = clampf(_slam_t / 0.42, 0.0, 1.0)
		if u < 1.0:
			var r: float = 0.35 + 2.1 * _ease_out(u)
			_ring.scale = Vector3(r, 0.06, r)
			_ring_set(u)
		else:
			_ring_set(1.0)
	_write_own_glows(false)


func _ring_set(u: float) -> void:
	if u == _ring_written:
		return
	_ring_written = u
	_ring.visible = u < 1.0
	_ring.transparency = u * u


## Core: pulse from the material, charges on the wind-up, flares at death. Maul rune: flash on each slam.
func _write_own_glows(force: bool) -> void:
	var base := glow_level()
	var core := base
	var rune := base
	if _dead:
		core = base * _death_glow
		rune = base * _death_glow
	else:
		if _action == &"attack":
			core = base * (1.0 + 1.2 * _kf(_action_t, 0.07, STRIKE, 0.16, 0.45, 1.0, 0.6))
		if _slam_t < 1.0:
			rune = base * (1.0 + 3.0 * exp(-_slam_t * 7.0))
	if _core and (force or absf(core - _core_written) > 0.01):
		_core_written = core
		_core.set_instance_shader_parameter(&"glow_boost", core)
	if _rune and (force or absf(rune - _rune_written) > 0.01):
		_rune_written = rune
		_rune.set_instance_shader_parameter(&"glow_boost", rune)


# ================================================================ meshes

## A hewn stone version of a primitive: every vertex pushed by a seeded hash of its rest position (the copies of a
## corner move together, so the faces stay closed), then flat shaded. Cached per (primitive, amount, seed).
static func rough(prim: Mesh, amount: float, seed: float) -> Mesh:
	var key := "%s|%s|%s" % [prim.get_instance_id(), amount, seed]
	if _wmesh.has(key):
		return _wmesh[key]
	var arr := prim.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var jv := PackedVector3Array()
	jv.resize(v.size())
	for i: int in v.size():
		jv[i] = v[i] + _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.37, seed * 1.91)) * amount
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	for t: int in range(0, idx.size(), 3):
		var pa := jv[idx[t]]
		var pb := jv[idx[t + 1]]
		var pc := jv[idx[t + 2]]
		var fn := (pb - pa).cross(pc - pa)
		if fn.length_squared() < 1e-12:
			continue
		fn = fn.normalized()
		if fn.dot(n[idx[t]] + n[idx[t + 1]] + n[idx[t + 2]]) < 0.0:
			fn = -fn
		ov.append_array(PackedVector3Array([pa, pb, pc]))
		on.append_array(PackedVector3Array([fn, fn, fn]))
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = ov
	out[Mesh.ARRAY_NORMAL] = on
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	_wmesh[key] = am
	return am


## A fluted column drum (radius alternating r_out / r_in over 2 x flutes vertices), capped, flat shaded; the
## vertices get a small seeded push so it reads hewn and worn. Axis Y, centred, total height h.
static func fluted(r_out: float, r_in: float, h: float, flutes: int, seed: float) -> Mesh:
	var key := "flute%s_%s_%s_%d_%s" % [r_out, r_in, h, flutes, seed]
	if _wmesh.has(key):
		return _wmesh[key]
	var m: int = flutes * 2
	var ring: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
	for k: int in 2:
		var y: float = h * (float(k) - 0.5)
		for i: int in m:
			var a: float = TAU * float(i) / float(m)
			var r: float = r_out if i % 2 == 0 else r_in
			var p := Vector3(cos(a) * r, y, sin(a) * r)
			ring[k].append(p + _h3(p.snappedf(0.001) + Vector3(seed, 1.0, 2.0)) * r_out * 0.06)
	var tris: Array = []   # [a, b, c, outward hint]
	for i: int in m:
		var j: int = (i + 1) % m
		var a0 := ring[0][i]
		var a1 := ring[0][j]
		var b0 := ring[1][i]
		var b1 := ring[1][j]
		var out := Vector3((a0.x + a1.x) * 0.5, 0, (a0.z + a1.z) * 0.5)
		tris.append([a0, a1, b0, out])
		tris.append([a1, b1, b0, out])
		tris.append([Vector3(0, h * 0.5, 0), b0, b1, Vector3.UP])
		tris.append([Vector3(0, -h * 0.5, 0), a0, a1, Vector3.DOWN])
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	for t: Array in tris:
		var a: Vector3 = t[0]
		var b: Vector3 = t[1]
		var c: Vector3 = t[2]
		var fn := (b - a).cross(c - a).normalized()
		if fn.dot(t[3]) < 0.0:
			var tmp := b
			b = c
			c = tmp
			fn = -fn
		# (a, b, c) is counter-clockwise seen from outside; emit it in the primitives' front-face order.
		ov.append_array(PackedVector3Array([a, b, c] if _front_ccw() else [a, c, b]))
		on.append_array(PackedVector3Array([fn, fn, fn]))
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = ov
	arr[Mesh.ARRAY_NORMAL] = on
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_wmesh[key] = am
	return am


## True if Godot's own primitives wind their front faces counter-clockwise (cross product along the normal).
static func _front_ccw() -> bool:
	if not _wmesh.has("ccw"):
		var arr: Array = BoxMesh.new().get_mesh_arrays()
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		_wmesh["ccw"] = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]]).dot(n[idx[0]]) >= 0.0
	return _wmesh["ccw"]


static func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


static func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


## The keystone core: an octahedron (two 4-sided cones base to base), 0.26 m tall, 0.22 m wide.
static func _octa() -> Mesh:
	if _wmesh.has("octa"):
		return _wmesh["octa"]
	var up := CylinderMesh.new()
	up.top_radius = 0.0
	up.bottom_radius = 0.11
	up.height = 0.13
	up.radial_segments = 4
	up.rings = 0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(up, 0, Transform3D(Basis(), Vector3(0, 0.065, 0)))
	st.append_from(up, 0, Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, -0.065, 0)))
	var m := st.commit()
	_wmesh["octa"] = m
	return m


# ================================================================ particles (resources shared per process)

func _burst(nm: String, parent: Node3D, amount: int, life: float, ppm: ParticleProcessMaterial, draw: Mesh) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = nm
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.92
	p.randomness = 0.3
	p.fixed_fps = 30
	p.interpolate = true
	p.process_material = ppm
	p.draw_pass_1 = draw
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 5, 6))
	parent.add_child(p)
	return p


static func _fade_ramp(c: Color) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, c)
	g.set_color(1, Color(c.r, c.g, c.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt


static func _curve(points: Array) -> CurveTexture:
	var cv := Curve.new()
	for p: Vector2 in points:
		cv.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = cv
	return ct


static func _ppm_ring_dust() -> ParticleProcessMaterial:
	if _wfx.has("ring_dust"):
		return _wfx["ring_dust"]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.28
	pm.emission_ring_inner_radius = 0.18
	pm.emission_ring_height = 0.05
	pm.direction = Vector3.UP
	pm.spread = 20.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.9
	pm.radial_velocity_min = 2.2
	pm.radial_velocity_max = 3.4
	pm.damping_min = 3.0
	pm.damping_max = 4.5
	pm.gravity = Vector3(0, -0.6, 0)
	pm.scale_min = 0.7
	pm.scale_max = 1.2
	pm.scale_curve = _curve([Vector2(0, 0.55), Vector2(0.35, 1.0), Vector2(1, 1.25)])
	pm.color_ramp = _fade_ramp(Color(DUST.r, DUST.g, DUST.b, 0.8))
	_wfx["ring_dust"] = pm
	return pm


static func _ppm_step_dust() -> ParticleProcessMaterial:
	if _wfx.has("step_dust"):
		return _wfx["step_dust"]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.2
	pm.emission_ring_inner_radius = 0.1
	pm.emission_ring_height = 0.02
	pm.direction = Vector3.UP
	pm.spread = 30.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.4
	pm.radial_velocity_min = 0.6
	pm.radial_velocity_max = 1.0
	pm.damping_min = 2.0
	pm.damping_max = 3.0
	pm.gravity = Vector3.ZERO
	pm.scale_curve = _curve([Vector2(0, 0.6), Vector2(1, 1.2)])
	pm.color_ramp = _fade_ramp(Color(DUST.r, DUST.g, DUST.b, 0.55))
	_wfx["step_dust"] = pm
	return pm


static func _ppm_chips(radius: float, vmin: float, vmax: float, spread: float) -> ParticleProcessMaterial:
	var key := "chips%s_%s_%s_%s" % [radius, vmin, vmax, spread]
	if _wfx.has(key):
		return _wfx[key]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = radius
	pm.direction = Vector3.UP
	pm.spread = spread
	pm.initial_velocity_min = vmin
	pm.initial_velocity_max = vmax
	pm.gravity = Vector3(0, -11.0, 0)
	pm.angular_velocity_min = -540.0
	pm.angular_velocity_max = 540.0
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	_wfx[key] = pm
	return pm


static func _ppm_rubble() -> ParticleProcessMaterial:
	if _wfx.has("rubble"):
		return _wfx["rubble"]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.40, 0.40, 0.30)
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = 1.4
	pm.initial_velocity_max = 3.4
	pm.gravity = Vector3(0, -10.0, 0)
	pm.angular_velocity_min = -360.0
	pm.angular_velocity_max = 360.0
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	_wfx["rubble"] = pm
	return pm


static func _ppm_death_dust() -> ParticleProcessMaterial:
	if _wfx.has("death_dust"):
		return _wfx["death_dust"]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.50, 0.30, 0.40)
	pm.direction = Vector3.UP
	pm.spread = 80.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.1
	pm.radial_velocity_min = 0.5
	pm.radial_velocity_max = 1.2
	pm.damping_min = 1.0
	pm.damping_max = 2.0
	pm.gravity = Vector3(0, 0.15, 0)
	pm.scale_min = 0.8
	pm.scale_max = 1.3
	pm.scale_curve = _curve([Vector2(0, 0.5), Vector2(0.4, 1.0), Vector2(1, 1.3)])
	pm.color_ramp = _fade_ramp(Color(DUST.r, DUST.g, DUST.b, 0.75))
	_wfx["death_dust"] = pm
	return pm


static func _ppm_soul() -> ParticleProcessMaterial:
	if _wfx.has("soul"):
		return _wfx["soul"]
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.28
	pm.direction = Vector3.UP
	pm.spread = 28.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.3
	pm.damping_min = 0.4
	pm.damping_max = 0.8
	pm.gravity = Vector3.ZERO
	pm.scale_curve = _curve([Vector2(0, 1.0), Vector2(1, 0.2)])
	_wfx["soul"] = pm
	return pm


## Soft round MIX smoke quad (mask texture, keep_scale so the scale curve applies, colour from the ramp).
static func _smoke_draw(size: float) -> QuadMesh:
	var key := "smoke%s" % size
	if _wfx.has(key):
		return _wfx[key]
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.billboard_keep_scale = true
	sm.vertex_color_use_as_albedo = true
	sm.albedo_texture = mote_texture()
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = sm
	_wfx[key] = q
	return q


static func _chip_draw(size: float) -> BoxMesh:
	var key := "chip%s" % size
	if _wfx.has(key):
		return _wfx[key]
	var b := BoxMesh.new()
	b.size = Vector3(size, size * 0.8, size * 0.9)
	b.material = load(NEUTRAL_MATS + "warden_rubble.tres")
	_wfx[key] = b
	return b


static func _ring_mat() -> StandardMaterial3D:
	if _wfx.has("ring_mat"):
		return _wfx["ring_mat"]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.80, 0.72, 0.52, 0.75)
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_wfx["ring_mat"] = m
	return m
