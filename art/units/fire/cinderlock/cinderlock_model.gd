class_name CinderlockModel
extends FireModel
## 13b.V1 Cinderlock Musketeer (tier3-extras.md 4 / 12): the Fire tier-3 musket line. Scene built by
## build_cinderlock.gd on the Fire kit (FireModel, the Ember Archer body, the Flame Guard's bronze), so walk flavour,
## hit, level-up and the ember burn-away death are the Fire army's. What this script adds:
##
## Hooks (all safe before _ready: the last call is kept and applied then, like the kit's):
##   attack_style &"musket_volley" (play_attack): shoulder the musket in 0.15 s (release = attack_windup = 0.15:
##     the shot), recoil kick (chest and muzzle jump, a step back), hold, back to port arms; 0.80 s. The shot unloads
##     the musket (the muzzle ember flares then drops to a dull coal).
##   play_reload(seconds: float) -> void: the butt swings out and is planted on the ground at the right, the right hand
##     works the ramrod down the bell mouth (loop, period RAM_PERIOD), back to port arms at the end; loaded at the end.
##     Any other action (attack, cast, death) cancels it. seconds < 0.6 is played as 0.6.
##   set_loaded(on: bool) -> void / is_loaded() -> bool: the muzzle ember glows when loaded, a dull coal when not.
##   get_muzzle_point() -> Vector3: world position of the bell mouth (for the 13b.V6 muzzle flash / smoke).
##   get_muzzle_xf() -> Transform3D: world frame of the bell: origin = the mouth, basis.z = out of the muzzle.
##   get_weapon_tip() -> Variant: the muzzle point (the kit's generic "working end" query).
##   play_cast(any other id): "Present!" - shoulder the musket and hold it (0.6 s), no shot.
##
## Glow points: the row of powder flasks on the bandolier (kit glow, veterancy / haste boosted) and the ember in the
## bell mouth (own_glow: driven here, x glow_level()). 0 lights.
##
## The musket is its own node under the Chest (keep_separate, 3 surfaces), posed per frame only while an action
## plays; the arms are solved once per scene type (static) so the fists sit on the stock and barrel in every key pose
## (_build_poses: minimal-arc rotation of each rigid arm + a small shoulder shift). No allocation per frame.

## Model-space rig constants (feet origin, face +Z, ArmR at +X), shared with build_cinderlock.gd.
const CHEST_POS := Vector3(0.0, 0.64, 0.0)
const NECK_POS := Vector3(0.0, 1.20, 0.0)
const SHOULDER_R := Vector3(0.34, 1.14, 0.0)
const SHOULDER_L := Vector3(-0.34, 1.14, 0.0)
## The right fist centre = the musket's local origin at rest (port arms, stock wrist in the fist).
const GRIP := Vector3(0.22, 0.78, 0.31)
## Port-arms musket axis (butt at the right hip, bell up past the left shoulder), normalised in musket_rest().
const PORT_DIR := Vector3(-0.88, 0.44, 0.14)
## Musket local frame: origin = right fist, +Z toward the muzzle, +Y = the top of the gun (barrel side).
const BUTT_S := -0.32
const MUZZLE_S := 1.03          # bell rim
const BORE_Y := 0.038           # barrel axis height over the stock line
const MOUTH_S := 1.025          # the ember / the muzzle point (in the bell mouth)
const LEFT_REST := Vector3(0.0, -0.05, 0.30)   # left fist under the forestock at rest
const ROD_LEN := 0.70
const ROD_KNOB := 0.07          # the knob sits this far above the right fist on the rod
const ROD_LOW := 0.16           # fist height over the bell rim at the bottom / top of a ramrod stroke
const ROD_HIGH := 0.34

const RELOAD_ID := &"reload"
const VOLLEY_STYLE := &"musket_volley"
const SHOULDER_T := 0.15
const ATTACK_LEN := 0.80
const PRESENT_LEN := 0.60
const RAM_PERIOD := 0.55
const EMBER_LOADED := 1.0
const EMBER_EMPTY := 0.12
const EMBER_FLASH := 3.5
const EMBER_FLASH_LEN := 0.35

enum { PS_PORT, PS_AIM, PS_KICK, PS_HOLD, PS_TOP }
# Pose record fields.
enum { K_CHEST_R, K_CHEST_P, K_HEAD, K_ROOT, K_AR_R, K_AR_P, K_AL_R, K_AL_P, K_MUSKET, K_ROD, K_LEG_L, K_LEG_R }

static var _P: Array = []          # PS_* -> pose record (built once per run, shared by every instance)
static var _residual: PackedFloat32Array = PackedFloat32Array()   # |shoulder shift| per pose and arm (R, L), for tests

var _musket: Node3D
var _ember: GeometryInstance3D
var _rod: Node3D
var _mk_xf: Transform3D
var _mk_written: Transform3D
var _rod_r: float = ROD_LOW
var _rod_on: bool = false
var _loaded: bool = true
var _flash_t: float = -1.0
var _reload_len: float = 0.0
var _reload_pending: float = -1.0
var _ember_v: float = -1.0
var _ember_charge: float = -1.0   # >= 0 while the end of a reload lights the ember (0-1)


# ================================================================ static poses

## Port-arms musket transform in model space (the rest pose the scene is built in).
static func musket_rest() -> Transform3D:
	return _frame(GRIP, PORT_DIR, Vector3(0, 0, 1))


## Model-space rest centre of the left fist.
static func fist_l_rest() -> Vector3:
	return musket_rest() * LEFT_REST


## Orthonormal musket frame: origin o, +Z along dir, +Y toward up_hint.
static func _frame(o: Vector3, dir: Vector3, up_hint: Vector3) -> Transform3D:
	var z: Vector3 = dir.normalized()
	var y: Vector3 = (up_hint - z * up_hint.dot(z)).normalized()
	return Transform3D(Basis(y.cross(z), y, z), o)


## The key poses (model-space musket placements; arms solved in the chest frame of each pose).
static func poses() -> Array:
	if _P.is_empty():
		_build_poses()
	return _P


## |shoulder shift| of the solved arms: [PS_x * 2] right, [PS_x * 2 + 1] left (m). Small = the fists reach.
static func pose_residuals() -> PackedFloat32Array:
	poses()
	return _residual


static func _build_poses() -> void:
	_P.resize(5)
	_residual.resize(10)
	var grip_l := Vector4(0.0, LEFT_REST.y, LEFT_REST.z, LEFT_REST.z)
	# Port arms (rest): every offset 0 by construction.
	_P[PS_PORT] = _pose(PS_PORT, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, musket_rest(), Vector3.ZERO,
		grip_l, ROD_LOW, Vector2.ZERO)
	# Aim: side-on (left shoulder forward 50 deg), the head turned back to the target, butt in the right shoulder
	# pocket, barrel level along +Z (a hair down), the left hand slides to its natural reach under the barrel.
	var aim_dir := Vector3(0.0, -0.03, 1.0)
	var butt_aim := Vector3(0.13, 1.17, -0.09)
	_P[PS_AIM] = _pose(PS_AIM, Vector3(-3.0, 50.0, 0.0), Vector3.ZERO, Vector3(6.0, -46.0, 7.0), Vector3(0, -0.03, 0),
		_frame(butt_aim + aim_dir.normalized() * -BUTT_S, aim_dir, Vector3.UP), Vector3.ZERO,
		Vector4(0.0, -0.05, 0.22, 0.70), ROD_LOW, Vector2(-14.0, 10.0))
	# Recoil kick: the muzzle jumps 16 deg, the butt drives 6 cm back, the chest rocks back, a half step back.
	var kick_dir := Vector3(0.0, tan(deg_to_rad(16.0)) - 0.03, 1.0)
	var butt_kick := butt_aim + Vector3(0.0, 0.03, -0.06)
	_P[PS_KICK] = _pose(PS_KICK, Vector3(-12.0, 50.0, -3.0), Vector3(0, 0.01, -0.03), Vector3(-4.0, -46.0, 7.0),
		Vector3(0, -0.02, -0.08), _frame(butt_kick + kick_dir.normalized() * -BUTT_S, kick_dir, Vector3.UP),
		Vector3.ZERO, Vector4(0.0, -0.05, 0.22, 0.70), ROD_LOW, Vector2(-10.0, 16.0))
	# Reload: the musket leans in, butt planted on the ground out at the right, bell mouth by the right shoulder;
	# the right fist on the ramrod over the bell (low / high stroke), the left hand on the hip.
	var ld := Vector3(-0.40, 0.91, 0.05).normalized()
	var mouth := Vector3(0.36, 1.25, 0.46)
	var rld: Transform3D = _frame(mouth - ld * MUZZLE_S, ld, Vector3(0.3, 0.0, 1.0))
	var hip_l := Vector3(-0.31, 0.76, 0.12)
	_P[PS_HOLD] = _pose(PS_HOLD, Vector3(6.0, -10.0, 0.0), Vector3.ZERO, Vector3(10.0, 12.0, 0.0), Vector3.ZERO, rld,
		Vector3(0.0, BORE_Y, MUZZLE_S + ROD_LOW), hip_l, ROD_LOW, Vector2(-6.0, 4.0))
	_P[PS_TOP] = _pose(PS_TOP, Vector3(3.0, -10.0, 0.0), Vector3(0, 0.02, 0), Vector3(2.0, 12.0, 0.0), Vector3.ZERO, rld,
		Vector3(0.0, BORE_Y, MUZZLE_S + ROD_HIGH), hip_l, ROD_HIGH, Vector2(-6.0, 4.0))


## One pose record. mm = musket in model space; r_local = right fist target in musket space; left = a Vector3 model
## point on the chest-rest frame (hip, belt) or a Vector4(x, y, s0, s1): the left fist slides along the barrel
## (musket space z in s0..s1 at x / y) to the point its rigid arm reaches best.
static func _pose(id: int, chest_deg: Vector3, chest_pos: Vector3, head_deg: Vector3, root_pos: Vector3,
		mm: Transform3D, r_local: Vector3, left: Variant, rod_r: float, legs: Vector2) -> Array:
	var tc := Transform3D(Basis.from_euler(chest_deg * DEG), CHEST_POS + chest_pos)
	var mc: Transform3D = tc.affine_inverse() * mm
	var sr: Vector3 = SHOULDER_R - CHEST_POS
	var sl: Vector3 = SHOULDER_L - CHEST_POS
	var fr: Vector3 = GRIP - CHEST_POS
	var fl: Vector3 = fist_l_rest() - CHEST_POS
	var ar: Array = _solve(sr, fr, mc * r_local)
	var tl: Vector3
	if left is Vector4:
		var l4: Vector4 = left
		var want: float = (fl - sl).length()
		var best: float = INF
		for i: int in 49:
			var s: float = lerpf(l4.z, l4.w, float(i) / 48.0)
			var p: Vector3 = mc * Vector3(l4.x, l4.y, s)
			var err: float = absf((p - sl).length() - want)
			if err < best:
				best = err
				tl = p
	else:
		tl = (left as Vector3) - CHEST_POS
	var al: Array = _solve(sl, fl, tl)
	_residual[id * 2] = (ar[1] as Vector3).length()
	_residual[id * 2 + 1] = (al[1] as Vector3).length()
	return [chest_deg * DEG, chest_pos, head_deg * DEG, root_pos, ar[0], ar[1], al[0], al[1], mc, rod_r,
		legs.x * DEG, legs.y * DEG]


## Rigid arm: pivot a (chest frame), rest fist f, target t -> [euler offset, pivot shift] so the fist lands on t.
static func _solve(a: Vector3, f: Vector3, t: Vector3) -> Array:
	var u: Vector3 = (f - a).normalized()
	var v: Vector3 = (t - a).normalized()
	if u.dot(v) > 0.99999:
		return [Vector3.ZERO, t - f]
	var q := Quaternion(u, v)
	var b := Basis(q)
	return [b.get_euler(), (t - a) - b * (f - a)]


# ================================================================ hooks

func play_reload(seconds: float) -> void:
	if not _ready_done:
		_reload_pending = seconds
		_loaded = false
		return
	if _dead:
		return
	_reload_len = maxf(seconds, 0.6)
	_loaded = false
	_flash_t = -1.0
	_ember_charge = -1.0
	play_cast(RELOAD_ID)


func set_loaded(on: bool) -> void:
	_loaded = on
	_flash_t = -1.0 if on else _flash_t
	_ember_charge = -1.0
	if _ready_done:
		_write_ember()


func is_loaded() -> bool:
	return _loaded


func get_muzzle_xf() -> Transform3D:
	var local := Transform3D(Basis.IDENTITY, Vector3(0.0, BORE_Y, MOUTH_S))
	if _musket and _musket.is_inside_tree():
		return _musket.global_transform * local
	var base: Transform3D = global_transform if is_inside_tree() else transform
	return base * musket_rest() * local


func get_muzzle_point() -> Vector3:
	return get_muzzle_xf().origin


func get_weapon_tip() -> Variant:
	return get_muzzle_point()


func play_death() -> void:
	var was: bool = _dead
	super()
	if not was:
		_reset_gun()


# ================================================================ kit subclass hooks

func _after_ready() -> void:
	super()
	var chest := get_node_or_null(^"Root/Chest")
	if chest:
		_musket = chest.get_node_or_null(^"Musket") as Node3D
	if _musket:
		_ember = _musket.get_node_or_null(^"MuzzleEmber") as GeometryInstance3D
		_rod = _musket.get_node_or_null(^"Ramrod") as Node3D
		_mk_written = _musket.transform
	_mk_xf = poses()[PS_PORT][K_MUSKET]
	if _rod:
		_rod.visible = false
	_write_ember()
	if _reload_pending >= 0.0:
		var s: float = _reload_pending
		_reload_pending = -1.0
		play_reload(s)


func _on_revive() -> void:
	super()
	_loaded = true
	_flash_t = -1.0
	_ember_charge = -1.0
	_reset_gun()
	_write_ember()


func _on_action_event(ev: StringName) -> void:
	super(ev)
	match ev:
		&"attack_start", &"cast_start":
			_show_rod(false)
		&"release":
			if _action == &"attack":
				_loaded = false
				_flash_t = 0.0
				_ember_charge = -1.0
		&"cast_end":
			_show_rod(false)
			if _cast_id == RELOAD_ID:
				_loaded = true
				_ember_charge = -1.0
		&"death_glow_off":
			_show_rod(false)


func _extra_process(dt: float) -> void:
	super(dt)
	if _flash_t >= 0.0:
		_flash_t += dt
		if _flash_t > EMBER_FLASH_LEN:
			_flash_t = -1.0
	_write_ember()


func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s: float = sin(TAU * _walk_p)
	# Both hands stay on the musket: cancel the kit's opposite arm swing; the chest carries arms and gun together.
	rot(P_ARM_L, Vector3(18.0 * DEG * s * w, 0, 0))
	rot(P_ARM_R, Vector3(-8.0 * DEG * s * w, 0, 0))
	if _tier > 0:
		return
	var c: float = cos(TAU * _walk_p)
	rot(P_ROOT, Vector3(5.0 * DEG * w, 0, 0))
	rot(P_HIPS, Vector3(0, 7.0 * DEG * s * w, 0))
	rot(P_CHEST, Vector3(1.5 * DEG * c * w, -5.0 * DEG * s * w, 0))
	rot(P_HEAD, Vector3(0, 4.0 * DEG * s * w, 0))


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != VOLLEY_STYLE:
		return super(prev, t)
	# 0 -> 0.15 shoulder (snappy) | 0.15 shot | 0.15 -> 0.20 kick | -> 0.40 settle on aim | hold | 0.52 -> 0.80 port.
	if t < SHOULDER_T:
		_blend(PS_PORT, PS_AIM, _ease_out(t / SHOULDER_T))
	elif t < 0.20:
		_blend(PS_AIM, PS_KICK, _ease_out((t - SHOULDER_T) / 0.05))
	elif t < 0.40:
		_blend(PS_KICK, PS_AIM, smoothstep(0.0, 1.0, (t - 0.20) / 0.20))
	elif t < 0.52:
		_blend(PS_AIM, PS_AIM, 0.0)
	else:
		_blend(PS_AIM, PS_PORT, smoothstep(0.0, 1.0, clampf((t - 0.52) / (ATTACK_LEN - 0.52), 0.0, 1.0)))
	if prev < SHOULDER_T and t >= SHOULDER_T:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	if spell == RELOAD_ID:
		return _pose_reload(t)
	# "Present!": shoulder and hold, no shot.
	var k: float = _ease_out(clampf(t / SHOULDER_T, 0.0, 1.0)) * (1.0 - smoothstep(PRESENT_LEN - 0.2, PRESENT_LEN, t))
	_blend(PS_PORT, PS_AIM, k)
	return PRESENT_LEN


# ================================================================ reload

func _pose_reload(t: float) -> float:
	var n: float = _reload_len
	var tin: float = minf(0.28, n * 0.25)
	var tout: float = minf(0.30, n * 0.25)
	var t_end: float = n - tout
	if t < tin:
		_blend(PS_PORT, PS_HOLD, _ease_out(t / tin))
		_show_rod(false)
	elif t < t_end:
		# Ramrod strokes: start low (fist on the bell), up, down... and settle low before the swing back.
		var u: float = (t - tin) / RAM_PERIOD
		var w: float = 0.5 - 0.5 * cos(TAU * u)
		w *= clampf((t_end - t) / 0.12, 0.0, 1.0)
		_blend(PS_HOLD, PS_TOP, w)
		_show_rod(t > tin + 0.03 and t < t_end - 0.05)
		if _rod_on:
			_rod.position = Vector3(0.0, BORE_Y, MUZZLE_S + _rod_r + ROD_KNOB - ROD_LEN)
	else:
		var k: float = clampf((t - t_end) / tout, 0.0, 1.0)
		_blend(PS_HOLD, PS_PORT, smoothstep(0.0, 1.0, k))
		_show_rod(false)
		_ember_charge = k   # the charge is rammed home: the ember wakes up on the way back
	return n


# ================================================================ helpers

## Writes the blend of two key poses (offsets on top of idle / walk) and places the musket.
func _blend(a: int, b: int, w: float) -> void:
	var pa: Array = _P[a]
	var pb: Array = _P[b]
	var near: bool = _tier == 0
	rot(P_CHEST, (pa[K_CHEST_R] as Vector3).lerp(pb[K_CHEST_R], w))
	pos(P_CHEST, (pa[K_CHEST_P] as Vector3).lerp(pb[K_CHEST_P], w))
	pos(P_ROOT, (pa[K_ROOT] as Vector3).lerp(pb[K_ROOT], w))
	rot(P_ARM_R, (pa[K_AR_R] as Vector3).lerp(pb[K_AR_R], w))
	pos(P_ARM_R, (pa[K_AR_P] as Vector3).lerp(pb[K_AR_P], w))
	rot(P_ARM_L, (pa[K_AL_R] as Vector3).lerp(pb[K_AL_R], w))
	pos(P_ARM_L, (pa[K_AL_P] as Vector3).lerp(pb[K_AL_P], w))
	rot(P_HEAD, (pa[K_HEAD] as Vector3).lerp(pb[K_HEAD], w))
	if near:
		rot(P_LEG_L, Vector3(lerpf(pa[K_LEG_L], pb[K_LEG_L], w), 0, 0))
		rot(P_LEG_R, Vector3(lerpf(pa[K_LEG_R], pb[K_LEG_R], w), 0, 0))
	_rod_r = lerpf(pa[K_ROD], pb[K_ROD], w)
	if w <= 0.0:
		_mk_xf = pa[K_MUSKET]
	elif w >= 1.0:
		_mk_xf = pb[K_MUSKET]
	else:
		_mk_xf = (pa[K_MUSKET] as Transform3D).interpolate_with(pb[K_MUSKET], w)
	_write_musket()


func _write_musket() -> void:
	if _musket and _mk_xf != _mk_written:
		_mk_written = _mk_xf
		_musket.transform = _mk_xf


func _reset_gun() -> void:
	if _P.is_empty():
		poses()
	_mk_xf = _P[PS_PORT][K_MUSKET]
	_rod_r = ROD_LOW
	_show_rod(false)
	_write_musket()


func _show_rod(on: bool) -> void:
	if _rod == null or on == _rod_on:
		return
	_rod_on = on
	_rod.visible = on


## Muzzle ember brightness (glow_boost of its own node): loaded 1.0, empty 0.12, the shot flares it, the end of a
## reload lights it back up; x glow_level() (veterancy, haste, 0 once dead). Quantised, written only on change.
func _write_ember() -> void:
	if _ember == null:
		return
	var base: float = EMBER_LOADED if _loaded else EMBER_EMPTY
	if _ember_charge >= 0.0 and not _loaded:
		base = lerpf(EMBER_EMPTY, EMBER_LOADED, _ember_charge)
	if _flash_t >= 0.0:
		base += EMBER_FLASH * (1.0 - _flash_t / EMBER_FLASH_LEN)
	var v: float = snappedf(base * glow_level(), 0.02)
	if v == _ember_v:
		return
	_ember_v = v
	_ember.set_instance_shader_parameter(&"glow_boost", v)
