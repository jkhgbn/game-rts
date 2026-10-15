extends CharacterModel
## Gloomcap Sprout (map-fill.md 5.1 / 10, task 12.V22): the knee-high melee mushrooms of the Gloomcap Hollow (3 per
## camp around the Elder). 0.7 m to the top of the cap (selection radius 0.35). Read at 40 m as small blue-grey BUTTON
## CAPS with pale spots (the Elder's cap in miniature, rounder and proportionally bigger: the cap is ~60 % of the
## height), bobbing around the Elder. Close up: a chubby pale stalk body with round faint-teal eyes and a small dark
## "o" mouth, two stumpy root feet with root toes, two tiny root arms.
## Every Sprout is a little different: a per-instance size (0.9-1.08) and a tilted, turned cap (fixed at spawn).
## Neutral: no team colour (set_team_color is a no-op), 0 lights, glow by emission only (the eyes, hidden from the
## game camera by the cap).
## Motion (procedural, kit rules):
##  - idle: bouncy squash-and-stretch breathing, the cap jiggling; every ~hop_every s at close range a little HOP in
##    place (crouch, jump, arms flapping, squash on landing); `play_hop()` starts one now;
##  - walk: a quick waddle (short legs, big roll, bounce with squash / stretch, cap lagging, arms swinging);
##  - attack `cap_bonk` (melee, 0.5 s, strike 0.12 s = the kit strike frame): leans back and squashes, then hops
##    forward and head-butts with the cap (a small spore puff at the strike);
##  - cast (the spec lists no Sprout ability; any id is safe, e.g. `spore_burst`): squeezes down, then pops up
##    puffing a spore cloud out of its cap;
##  - hit: the kit flinch (pushed back) + flash, a squash and a few spores;
##  - death (1.0 s): a shudder, it squashes flat with a spore puff (glows off) and sinks away.
## Budget (soldier budget: <= 18 authored meshes, <= 10 draw instances, 0 lights): 6 authored meshes + the blob;
## 6 merged pivots + blob + 1 pre-built one-shot emitter (Puff) = 8 draw instances; materials shared with the Elder.

const GM := preload("res://art/units/neutral/gloomcap/gloomcap_mesh.gd")

const CAP_R := 0.3
const CAP_RIM_Y := 0.43
const CAP_DOME := 0.27
const CAP_SEG := 20
const CAP_FRONT := Vector3(0.0, 0.58, 0.22)   # model space: where the bonk / hit puffs leave
const CAP_TOP := Vector3(0.0, 0.64, 0.0)      # model space: the cast / death cloud
const BONK_LEN := 0.5
const BONK_HIT := 0.12
const CAST_LEN := 0.8
const CAST_POP := 0.33
const HOP_LEN := 0.7
const DEATH_POP := 0.28

# Keyframe tracks [t, value, ease, ...] (GM.trk). Degrees / metres; SQ = squash (+ stretches up, - squashes flat).
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.06, 1, 0.12, 0.22, 2, 0.25, 0.15, 0, 0.5, 0.0, 0])
static var A_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.03, 1, 0.12, 0.06, 2, 0.25, 0.02, 0, 0.5, 0.0, 0])
static var A_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -18.0, 1, 0.12, 30.0, 2, 0.26, 12.0, 0, 0.5, 0.0, 0])
static var A_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -12.0, 1, 0.13, 20.0, 2, 0.3, 4.0, 0, 0.5, 0.0, 0])
static var A_SQ := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.12, 1, 0.12, 0.1, 2, 0.16, -0.1, 1, 0.3, 0.0, 0, 0.5, 0.0, 0])
static var A_ARM := PackedFloat32Array([0.0, 0.0, 0, 0.07, 30.0, 1, 0.12, -45.0, 2, 0.3, -10.0, 0, 0.5, 0.0, 0])
static var A_LEG := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.12, 22.0, 2, 0.3, 6.0, 0, 0.5, 0.0, 0])
static var C_SQ := PackedFloat32Array([0.0, 0.0, 0, 0.25, -0.2, 1, 0.33, 0.16, 2, 0.45, -0.05, 0, 0.8, 0.0, 0])
static var C_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.25, 8.0, 1, 0.33, -12.0, 2, 0.5, 2.0, 0, 0.8, 0.0, 0])
static var C_ARMS := PackedFloat32Array([0.0, 0.0, 0, 0.25, 10.0, 1, 0.33, 50.0, 2, 0.55, 15.0, 0, 0.8, 0.0, 0])
static var H_SQ := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.14, 1, 0.2, 0.12, 2, 0.42, 0.0, 0, 0.5, -0.12, 2, 0.7, 0.0, 0])
static var H_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.02, 1, 0.2, 0.02, 2, 0.31, 0.16, 1, 0.44, 0.0, 2, 0.7, 0.0, 0])

## Idle hop interval (s, randomised +-40 % per unit); 0 = never. Only within 30 m of the camera.
@export var hop_every: float = 6.0

var _authored: int = 0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig
var _puff_fx: GPUParticles3D
var _hop_wait: float = 0.0
var _strikes: int = 0
var _puffs: int = 0
var _last_puff: float = -9.0
var _cast_last: float = -1.0
## G-D signature emitter (High / Ultra only; null otherwise).
var _sig: GPUParticles3D


func _ready() -> void:
	# Per-instance look, fixed at spawn: size and a tilted, turned cap (the kit reads the rest pose after this).
	var h: int = absi(hash(get_instance_id()))
	var r1: float = float(h % 1000) / 1000.0
	var r2: float = float((h / 1000) % 1000) / 1000.0
	var r3: float = float((h / 1000000) % 1000) / 1000.0
	scale = Vector3.ONE * lerpf(0.9, 1.08, r1)
	var head := get_node_or_null(^"Root/Chest/Head") as Node3D
	if head:
		head.rotation = Vector3((r2 - 0.5) * 14.0, r3 * 360.0, (r3 - 0.5) * 16.0) * DEG
	super()


# ================================================================ public (tests, preview, camp idle)

## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Cap-bonk strikes played so far (the strike frame of each attack), for tests.
func strike_count() -> int:
	return _strikes


## Full spore puffs so far (cast pop, death), for tests.
func puff_count() -> int:
	return _puffs


## Starts the idle hop now (it also plays by itself every ~hop_every s close to the camera).
func play_hop() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"hop"
		_action_t = 0.0


## Neutral creature: no team colour.
func set_team_color(_c: Color) -> void:
	pass


# ================================================================ parts

func _part(pivot: Node3D, mesh: Mesh) -> MeshInstance3D:
	_authored += 1
	return add_part(pivot, mesh, null, Vector3.ZERO)


func _build_parts() -> void:
	_authored = 0
	_part($Root/Hips/LegL, _leg_mesh(-1.0))
	_part($Root/Hips/LegR, _leg_mesh(1.0))
	_part($Root/Chest, _body_mesh())
	_face = CreatureFaceRig.attach(self, $Root/Chest, "gloomcap_sprout", face_spec())
	_part($Root/Chest/Head, _cap_mesh())
	_part($Root/Chest/ArmL, _arm_mesh(-1.0))
	_part($Root/Chest/ArmR, _arm_mesh(1.0))
	_puff_fx = $Fx/Puff
	ensure_shadow_blob(0.35, Color(0.03, 0.04, 0.05, 0.45))


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	for i: int in [P_LEG_L, P_LEG_R, P_ARM_L]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
	_hop_wait = _next_hop() * 0.5
	if _face:
		_face.set_host(_merged_nodes.get(P_CHEST))
	# G-D signature (High+): a few glowing spores drifting up off the cap.
	var head: Node3D = $Root/Chest/Head
	_sig = CreatureSignature.attach(self, head, Vector3(0.0, 0.66, 0.0) - model_origin(head), &"spores", 0.7)


func _on_revive() -> void:
	if _face:
		_face.reset()
	_cast_last = -1.0


## G-D signature gate (CreatureSignature, High / Ultra only): near tier, animating, alive.
func signature_should_emit() -> bool:
	return _tier == 0 and not _offscreen and not _frozen and not _dead


# ================================================================ hooks

func play_hit() -> void:
	var before := _hit_t
	super.play_hit()
	if _hit_t == 0.0 and before != 0.0 and _tier == 0 and _t - _last_puff > 0.5:
		_last_puff = _t
		_puff(CAP_FRONT, P_HEAD, 0.3)


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start":
		_cast_last = -1.0
	elif ev == &"release" and _action == &"attack":
		_strikes += 1
		if _tier < 2:
			_puff(CAP_FRONT, P_HEAD, 0.35)


## Restarts the Puff emitter at a model-space rest point carried by pivot i (its current pose), `ratio` of its
## particles.
func _puff(model_pt: Vector3, i: int, ratio: float) -> void:
	if _puff_fx == null or not is_inside_tree():
		return
	var p: Node3D = _piv[i] if _piv[i] else self
	_puff_fx.position = to_local(p.global_transform * (model_pt - model_origin(p)))
	_puff_fx.amount_ratio = ratio
	_puff_fx.restart()


static func _sq(s: float) -> Vector3:
	return Vector3(1.0 - 0.5 * s, 1.0 + s, 1.0 - 0.5 * s)


# ================================================================ idle / walk

func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var sc := _sq(0.035 * sin(2.0 * ph))
	if _piv[P_ROOT]:
		_piv[P_ROOT].scale = sc
		_last_root_scale = sc
	if _tier == 0:
		_write_rot(P_HEAD, _rest_rot[P_HEAD] + _idle_head(ph))


func _idle_head(ph: float) -> Vector3:
	return Vector3(3.0 * sin(2.0 * ph + 0.6), 5.0 * sin(0.5 * ph), 2.5 * sin(ph + 1.0)) * DEG


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph: float = (_t + _phase_off) * TAU / idle_period
	_root_scale *= _sq(0.035 * sin(2.0 * ph) * w)
	rot(P_HEAD, _idle_head(ph) * w)


## Quick waddle: short legs, a big roll onto the planted foot, high at the passing point (stretched) and low with the
## feet apart (squashed), the cap lagging, the little arms swinging.
func _pose_walk(w: float, _rate: float) -> void:
	var ph: float = TAU * _walk_p
	var s: float = sin(ph)
	var c: float = cos(ph)
	var a: float = 36.0 * DEG * w
	rot(P_LEG_L, Vector3(-a * s, 0, 0))
	rot(P_LEG_R, Vector3(a * s, 0, 0))
	pos(P_LEG_L, Vector3(0, 0.03 * maxf(0.0, c) * w, 0))
	pos(P_LEG_R, Vector3(0, 0.03 * maxf(0.0, -c) * w, 0))
	pos(P_ROOT, Vector3(0, walk_bounce * (1.0 - absf(s)) * w, 0))
	_root_scale *= _sq(0.07 * (0.5 - absf(s)) * w)
	rot(P_ROOT, Vector3(5.0 * DEG * w, 0, 8.0 * DEG * c * w))
	rot(P_HEAD, Vector3(4.0 * cos(2.0 * ph - 1.0), 0, -6.0 * cos(ph - 0.8)) * DEG * w)
	if _action != &"attack":
		rot(P_ARM_L, Vector3(35.0 * DEG * s * w, 0, 0))
		rot(P_ARM_R, Vector3(-35.0 * DEG * s * w, 0, 0))


# ================================================================ attack / cast / hop

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"cap_bonk":
		return super._pose_attack(prev, t)
	pos(P_ROOT, Vector3(0, GM.trk(t, A_ROOT_Y), GM.trk(t, A_ROOT_Z)))
	rot(P_CHEST, Vector3(GM.trk(t, A_CHEST_X), 0, 0) * DEG)
	rot(P_HEAD, Vector3(GM.trk(t, A_HEAD_X), 0, 0) * DEG)
	_root_scale *= _sq(GM.trk(t, A_SQ))
	var arm: float = GM.trk(t, A_ARM) * DEG
	rot(P_ARM_L, Vector3(arm, 0, 0))
	rot(P_ARM_R, Vector3(arm, 0, 0))
	rot(P_LEG_L, Vector3(GM.trk(t, A_LEG) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(-0.6 * GM.trk(t, A_LEG) * DEG, 0, 0))
	if prev < BONK_HIT and t >= BONK_HIT:
		_on_action_event(&"release")
	return t < BONK_LEN


## Any cast id: squeezes down, then pops up and puffs a spore cloud out of its cap (arms thrown out).
func _pose_cast(_spell: StringName, t: float) -> float:
	_root_scale *= _sq(GM.trk(t, C_SQ))
	rot(P_HEAD, Vector3(GM.trk(t, C_HEAD_X), 0, 0) * DEG)
	var arms: float = GM.trk(t, C_ARMS) * DEG
	rot(P_ARM_L, Vector3(0, 0, -arms))
	rot(P_ARM_R, Vector3(0, 0, arms))
	if t < _cast_last:
		_cast_last = -1.0
	if _cast_last < CAST_POP and t >= CAST_POP:
		_puffs += 1
		if _tier < 2:
			_puff(CAP_TOP, P_HEAD, 1.0)
	_cast_last = t
	return CAST_LEN


## The idle hop (0.7 s): crouch, jump (arms flapping out, cap lagging), squash on landing.
func _pose_hop(t: float) -> void:
	_root_scale *= _sq(GM.trk(t, H_SQ))
	var y: float = GM.trk(t, H_Y)
	pos(P_ROOT, Vector3(0, y, 0))
	var air: float = clampf(y / 0.16, 0.0, 1.0)
	rot(P_ARM_L, Vector3(0, 0, -45.0 * air * DEG))
	rot(P_ARM_R, Vector3(0, 0, 45.0 * air * DEG))
	rot(P_LEG_L, Vector3(-12.0 * air * DEG, 0, 0))
	rot(P_LEG_R, Vector3(10.0 * air * DEG, 0, 0))
	rot(P_HEAD, Vector3(-8.0 * air - 60.0 * GM.trk(t, H_SQ), 0, 0) * DEG)


# ================================================================ death (1.0 s)

func _pose_death(dt: float) -> void:
	var prev: float = _death_t
	_death_t += dt
	var t: float = _death_t
	var shud: float = sin(t * 55.0) * (1.0 - smoothstep(0.1, 0.2, t))
	var flat: float = _ease_out(clampf((t - 0.15) / 0.18, 0.0, 1.0))
	var sink: float = _ease_in(clampf((t - 0.5) / 0.5, 0.0, 1.0))
	rot(P_HEAD, Vector3(15.0 * flat, 0, 10.0 * shud + 10.0 * flat) * DEG)
	rot(P_ARM_L, Vector3(0, 0, -50.0 * flat * DEG))
	rot(P_ARM_R, Vector3(0, 0, 50.0 * flat * DEG))
	_root_scale *= Vector3(1.0 + 0.3 * flat, 1.0 - 0.62 * flat, 1.0 + 0.3 * flat) * (1.0 - 0.4 * sink)
	pos(P_ROOT, Vector3(0, -0.25 * sink, 0))
	if prev < DEATH_POP and t >= DEATH_POP:
		_puffs += 1
		if _tier < 2:
			_puff(CAP_TOP, P_HEAD, 0.9)
		_glows_dead()
	if _shadow:
		_shadow.transparency = clampf((t - 0.55) / 0.4, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


# ================================================================ per frame extras

func _extra_process(dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if _dead:
		return
	if _action == &"hop":
		if _speed >= 0.3 or _action_t >= HOP_LEN:
			_action = &""
		else:
			_pose_hop(_action_t)
	elif hop_every > 0.0 and _action == &"" and _speed < 0.3 and _tier == 0:
		_hop_wait -= dt
		if _hop_wait <= 0.0:
			_hop_wait = _next_hop()
			play_hop()
	if _hit_t < HIT_LEN:
		var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
		_root_scale *= _sq(-0.12 * k)
		rot(P_HEAD, Vector3(-10.0 * k, 0, 8.0 * k) * DEG)


func _next_hop() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return hop_every * (0.6 + 0.8 * h)


# ================================================================ meshes (static, built once per game, model space)

static func _cap_shape(a: float, r: float, _y: float) -> Vector3:
	var u: float = clampf(r / CAP_R, 0.0, 1.0)
	return Vector3(1.0 + 0.045 * sin(3.0 * a + 0.5) * u, -0.022 * u * u * u * sin(2.0 * a + 1.0), 0.0)


static func _cap_top_y(r: float) -> float:
	var u: float = clampf(r / CAP_R, 0.0, 1.0)
	return CAP_RIM_Y + CAP_DOME * pow(1.0 - u * u, 0.45)


static func _cap_point(a: float, r: float) -> Vector3:
	var s := _cap_shape(a, r, 0.0)
	return Vector3(sin(a) * r * s.x, _cap_top_y(r) + s.y, cos(a) * r * s.x)


static func _cap_normal(a: float, r: float) -> Vector3:
	var dr := _cap_point(a, r + 0.005) - _cap_point(a, r - 0.005)
	var da := _cap_point(a + 0.02, r) - _cap_point(a - 0.02, r)
	var n := da.cross(dr).normalized()
	return n if n.y > 0.0 else -n


## The button cap (Head): a plump blue-grey dome, dark gills, big pale spots.
static func _cap_mesh() -> Mesh:
	const KEY := "sprout_cap_v3"
	if GM.cached(KEY):
		return GM.cached(KEY)
	var cap := GM.bucket()
	var gills := GM.bucket()
	var spots := GM.bucket()
	var shape := func(a: float, r: float, y: float) -> Vector3: return _cap_shape(a, r, y)
	var top := PackedVector2Array()
	for r: float in [0.3, 0.295, 0.28, 0.25, 0.21, 0.16, 0.1, 0.05, 0.0]:
		top.append(Vector2(r, _cap_top_y(r)))
	GM.lathe(cap, top, CAP_SEG, Vector3.ZERO, shape)
	GM.lathe(gills, PackedVector2Array([Vector2(0.08, 0.48), Vector2(0.16, 0.47), Vector2(0.225, 0.455),
		Vector2(0.275, 0.432), Vector2(0.3, CAP_RIM_Y)]), CAP_SEG, Vector3.ZERO, shape)
	for sp: Vector3 in [Vector3(0.4, 0.1, 0.062), Vector3(1.8, 0.2, 0.056), Vector3(3.0, 0.13, 0.06),
			Vector3(4.3, 0.22, 0.05), Vector3(5.4, 0.18, 0.052), Vector3(2.5, 0.265, 0.04)]:
		var n := _cap_normal(sp.x, sp.y)
		GM.warts(spots, _cap_point(sp.x, sp.y), n, sp.z * 0.85, sp.x, 0.62 + 0.3 * absf(sin(sp.x * 3.1)))
	return GM.commit(KEY, [[cap, GM.mat(&"gloomcap_cap")], [gills, GM.mat(&"gloomcap_gills")],
		[spots, GM.mat(&"gloomcap_spots")]])


## The chubby stalk body (Chest): round eyes (faint glow in dark sockets), a small dark "o" mouth.
static func _body_mesh() -> Mesh:
	const KEY := "sprout_body_v2"
	if GM.cached(KEY):
		return GM.cached(KEY)
	var stalk := GM.bucket()
	var gills := GM.bucket()
	var glow := GM.bucket()
	var lump := func(a: float, _r: float, y: float) -> Vector3:
		return Vector3(1.0 + 0.04 * sin(2.0 * a + y * 9.0), 0.0, 0.0)
	GM.lathe(stalk, PackedVector2Array([Vector2(0.0, 0.07), Vector2(0.1, 0.085), Vector2(0.15, 0.13),
		Vector2(0.165, 0.2), Vector2(0.155, 0.28), Vector2(0.134, 0.37), Vector2(0.118, 0.45), Vector2(0.075, 0.5)]),
		12, Vector3.ZERO, lump)
	# the dark eye sockets; the glowing eyes and the little "o" mouth are the sprout's CreatureFaceRig (faces pass
	# 2026-09-28)
	for sx: float in [-1.0, 1.0]:
		GM.ellipsoid(gills, Vector3(0.054 * sx, 0.365, 0.116), Vector3(0.038, 0.042, 0.02), 6, 3)
	return GM.commit(KEY, [[stalk, GM.mat(&"gloomcap_stalk")], [gills, GM.mat(&"gloomcap_gills")]])


## A stumpy root foot (LegL / LegR) with two root toes.
static func _leg_mesh(sx: float) -> Mesh:
	var key := "sprout_leg_v1_%s" % sx
	if GM.cached(key):
		return GM.cached(key)
	var rt := GM.bucket()
	var hip := Vector3(0.07 * sx, 0.13, 0.0)
	var foot := Vector3(0.085 * sx, 0.03, 0.02)
	GM.tube(rt, PackedVector3Array([hip, hip.lerp(foot, 0.5), foot]), PackedFloat32Array([0.048, 0.043, 0.04]), 6)
	GM.ellipsoid(rt, foot + Vector3(0, 0.0, 0.015), Vector3(0.05, 0.034, 0.062), 6, 3)
	for d: Vector3 in [Vector3(0.04 * sx, -0.02, 0.1), Vector3(0.09 * sx, -0.02, -0.03)]:
		GM.root(rt, foot, foot + d, 0.025, 0.006, 3, 0.01, d.x * 11.0, 4)
	return GM.commit(key, [[rt, GM.mat(&"gloomcap_root")]])


## A tiny root arm (ArmL / ArmR) with a nub hand and two root fingers.
static func _arm_mesh(sx: float) -> Mesh:
	var key := "sprout_arm_v1_%s" % sx
	if GM.cached(key):
		return GM.cached(key)
	var rt := GM.bucket()
	var sh := Vector3(0.13 * sx, 0.29, 0.0)
	var hd := Vector3(0.205 * sx, 0.2, 0.05)
	GM.tube(rt, PackedVector3Array([sh, sh.lerp(hd, 0.5) + Vector3(0.01 * sx, 0.0, 0.0), hd]),
		PackedFloat32Array([0.032, 0.028, 0.024]), 5)
	GM.ellipsoid(rt, hd, Vector3(0.03, 0.028, 0.03), 5, 3)
	for d: Vector3 in [Vector3(0.02 * sx, -0.05, 0.03), Vector3(0.035 * sx, -0.04, -0.01)]:
		GM.root(rt, hd, hd + d, 0.014, 0.004, 3, 0.006, d.z * 30.0, 4)
	return GM.commit(key, [[rt, GM.mat(&"gloomcap_root")]])


## The face (faces pass 2026-09-28): big round faint-teal glowing eyes in the dark sockets, little brows and the small
## dark "o" mouth (a tiny round open mouth at rest; it grins on a level-up, grimaces on the attack). Drawn inside the
## merged Chest (CreatureFaceRig host mode: no extra draw instance).
static func face_spec() -> Dictionary:
	var gills := Color(0.20, 0.20, 0.28)
	return CreatureFaceRig.beast_spec(Vector3(0, 0.365, 0.0), 0.137, {"c": Vector2(0.053, 0.0), "hw": 0.026, "top": 0.024,
		"bot": 0.020, "ir": 0.016, "lash": 0.9, "flick": 0.0}, Color(0.62, 0.58, 0.50), Color(0.42, 0.95, 0.82), 0.8,
		Vector2(0.0, -0.066), {"head_mesh": CharacterModel.sphere(0.137, 12, 6), "lift": 0.008, "preset": &"bright",
		"brow": {"inner": Vector2(0.034, 0.036), "mid": Vector2(0.054, 0.042), "outer": Vector2(0.074, 0.034),
			"w": Vector3(0.004, 0.005, 0.002)},
		"mouth": {"c": Vector2(0.0, 0.0), "hw": 0.020, "lip": 0.0022},
		"mouth_canvas": FaceKit.canvas(Vector3(0, 0.30, 0.0), 0.16, CharacterModel.sphere(0.16, 12, 6), Vector3.ONE,
			Vector3.INF, Basis.IDENTITY, 0.004),
		"palette": {"sclera": Color(0.10, 0.10, 0.14), "brow": gills, "lash": Color(0.10, 0.10, 0.14), "lip_line": gills,
			"lip": Color(0.50, 0.46, 0.44), "mouth_in": Color(0.10, 0.10, 0.14), "teeth": Color(0.70, 0.68, 0.62),
			"tongue": Color(0.40, 0.30, 0.34)},
		"x": {&"neutral": {"mouth": {"kind": "shout", "w": 0.55, "depth": 0.9}}}})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
