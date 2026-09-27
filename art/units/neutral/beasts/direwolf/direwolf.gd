extends CharacterModel
## Direwolf (map-fill.md 5.5 / 10, task 12.V29): the epic beast of the two Greymane Hollows. ONE scene, two variants
## (`set_variant(v)`: 0 = Greymane Direwolf, 1 = Moonpelt Direwolf, the silver breed of every second spawn).
## A horse-sized wolf: withers ~1.45 m, ear tips ~1.85 m, ~2.8 m nose to tail. Read at 40 m by:
##  - A GREYMANE: a mid-grey coat with a charcoal saddle, and the SHAGGY GREY MANE: a thick ruff of long raked locks
##    round the neck swelling into a hump over the withers, a hackle crest down the spine, a bushy dark-tipped brush;
##    amber eyes (painted, no glow): a natural beast, its only glow is none.
##  - B MOONPELT: near-WHITE silver coat with a blue-silver saddle streak and a cool moonlit rim, leaner (body x0.86,
##    belly tucked, slimmer legs / neck / plume), a sleek pale collar instead of the mane, and a FAINT PALE-BLUE EYE
##    GLOW (1 glow point pair, flares on the pounce and the howl).
## Apart from the Grave Hound (Shadow, 1.0 m, near-black bone and spikes, purple glow) by size (x1.8), natural fur
## colours and the long-legged wolf silhouette (pricked ears, long muzzle, bushy tail).
## Neutral: no team colour (set_team_color is a no-op), 0 lights, glow by emission only (B eyes).
## Motion (procedural, kit rules):
##  - idle: breathing, a slow wary look around, panting jaw, the tail swaying; every ~fidget_every s close to the
##    camera a HOWL fidget (head thrown back, jaws open, a tremolo); `play_fidget()` starts one now;
##  - walk: a TROT (diagonal pairs) at patrol speed that turns into a rotary GALLOP (hinds then fronts, a
##    suspension, the body rocking, the tail streaming) from rate 0.8 (its fight speed = stride_speed);
##  - attack `hamstring_bite` (0.6 s, the kit strike frame 0.12 s: damage stays instant): drops the head low and to
##    the side with the jaws wide, lunges +0.34 m and snaps them shut at 0.12 s, then rips the head sideways (the
##    hamstring tear) and recovers;
##  - cast `pounce` (1.0 s; any id plays it): a coiled crouch (0.08 s), the LEAP (root arc to ~0.85 m at 0.26 s, fore
##    legs reaching, hind legs thrown back, jaws wide, tail streaming), the landing compression at 0.5 s and the pinning
##    bite at 0.56 s with a worrying shake; the gameplay moves the unit (CreatureAbilities, 16 m/s over 5-10 m);
##    the streak / claw marks are MapFillVfx's `pounce` (12.V31);
##  - hit: the kit push + flash, a snarl (head jerks up, jaw opens), the tail tucks;
##  - death (1.0 s): a yelp (head up, jaws open), the hind legs give way, it topples onto its left side with stiff legs
##    and a last kick, the eyes fade (B), then it sinks (the unit is freed at death_finished).
## Budget (map-fill.md 10 hero: <= 26 authored meshes, <= 16 draw instances, 0 lights): 14 authored meshes, all
## keep_separate (the variant swap replaces each part's mesh): Body, Neck, Skull (+ Jaw), Tail, 4 Thighs, 4 Shins, the
## blob = 14 draw instances, no emitters. 7 materials per variant (11 files in materials/). See tests/test_12_v29.gd.

const DM := preload("res://art/units/neutral/beasts/direwolf/direwolf_mesh.gd")
const BITE_LEN := 0.6
const BITE_HIT := 0.12
const POUNCE_LEN := 1.0
const POUNCE_BITE := 0.56
const HOWL_LEN := 2.4
const HOWL_PEAK := 0.6
const DEATH_GLOW_OFF := 0.5
const TOPPLE := 74.0                           # deg: the death roll onto its left side
const DEATH_LEG_LIFT := 18.0                   # deg: the legs swing up level with the ground once it lies
const FRONT_Z := 0.69                          # fore / hind paw z (the root pitches about them)
const HIND_Z := -0.87
const LEG_PIVOTS: Array[String] = ["Root/Mount/LegFL", "Root/Mount/LegFR", "Root/Mount/LegBL", "Root/Mount/LegBR"]
const JAW_MAX := 46.0

# Keyframe tracks [t, value, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth, 1 ease-out,
# 2 ease-in). Degrees / metres. Neck x (Head pivot): + = head down. Skull x: + = nose down. Jaw: + = open. Tail x:
# + = raised. Legs: + = paw forward. Folds (Lower): + = paw back (fronts), - = paw forward (hinds). Root pitch:
# + = nose down.
# ---- attack `hamstring_bite`
static var A_NECK := PackedFloat32Array([0.0, 0.0, 0, 0.07, 22.0, 1, 0.12, 30.0, 0, 0.24, 18.0, 1, 0.6, 0.0, 0])
static var A_NECK_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, -18.0, 1, 0.12, 6.0, 0, 0.22, -26.0, 1, 0.36, -8.0, 0,
	0.6, 0.0, 0])
static var A_SKULL := PackedFloat32Array([0.0, 0.0, 0, 0.07, -12.0, 1, 0.12, 8.0, 0, 0.6, 0.0, 0])
static var A_SKULL_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, 0.0, 0, 0.22, 18.0, 1, 0.4, 0.0, 0])
static var A_JAW := PackedFloat32Array([0.0, 0.0, 0, 0.07, 36.0, 1, 0.12, 0.0, 2, 0.3, 2.0, 0, 0.6, 0.0, 0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.08, 1, 0.12, 0.34, 2, 0.28, 0.16, 1, 0.6, 0.0, 0])
static var A_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.07, 1, 0.14, -0.04, 0, 0.6, 0.0, 0])
static var A_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, 5.0, 1, 0.12, 8.0, 0, 0.3, 2.0, 0, 0.6, 0.0, 0])
static var A_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.07, -6.0, 1, 0.12, 20.0, 2, 0.3, 6.0, 1, 0.6, 0.0, 0])
static var A_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.07, 10.0, 1, 0.12, -16.0, 1, 0.4, -4.0, 0, 0.6, 0.0, 0])
static var A_FOLD := PackedFloat32Array([0.0, 0.0, 0, 0.06, 40.0, 1, 0.12, 0.0, 2, 0.6, 0.0, 0])
static var A_TAIL := PackedFloat32Array([0.0, 0.0, 0, 0.07, 16.0, 1, 0.3, 8.0, 0, 0.6, 0.0, 0])
# ---- cast `pounce`
static var P_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.2, 1, 0.26, 0.85, 1, 0.46, 0.0, 2, 0.54, -0.16, 1,
	0.7, -0.04, 0, 1.0, 0.0, 0])
static var P_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.1, 1, 0.3, 0.15, 0, 0.54, 0.25, 1, 0.75, 0.05, 0,
	1.0, 0.0, 0])
static var P_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.08, 4.0, 1, 0.16, -16.0, 1, 0.3, -4.0, 0, 0.46, 12.0, 2,
	0.56, 8.0, 1, 0.8, 0.0, 0])
static var P_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.08, -18.0, 1, 0.2, 55.0, 1, 0.44, 40.0, 0, 0.52, 10.0, 2,
	0.7, 0.0, 0])
static var P_FOLD_F := PackedFloat32Array([0.0, 0.0, 0, 0.08, 40.0, 1, 0.2, 8.0, 1, 0.44, 0.0, 0, 1.0, 0.0, 0])
static var P_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.08, 22.0, 1, 0.18, -50.0, 1, 0.36, -35.0, 0, 0.5, 5.0, 1,
	0.75, 0.0, 0])
static var P_FOLD_B := PackedFloat32Array([0.0, 0.0, 0, 0.08, -35.0, 1, 0.16, 0.0, 1, 0.3, -20.0, 0, 0.5, -10.0, 0,
	0.8, 0.0, 0])
static var P_NECK := PackedFloat32Array([0.0, 0.0, 0, 0.08, 14.0, 1, 0.2, -10.0, 1, 0.44, 6.0, 0, 0.56, 26.0, 1,
	0.64, 20.0, 0, 0.76, -6.0, 1, 1.0, 0.0, 0])
static var P_NECK_Y := PackedFloat32Array([0.0, 0.0, 0, 0.56, 0.0, 0, 0.64, -18.0, 1, 0.72, 16.0, 1, 0.82, 0.0, 0])
static var P_SKULL := PackedFloat32Array([0.0, 0.0, 0, 0.2, -8.0, 1, 0.44, -12.0, 0, 0.56, 12.0, 1, 0.8, 0.0, 0])
static var P_JAW := PackedFloat32Array([0.0, 0.0, 0, 0.08, 10.0, 1, 0.3, 38.0, 1, 0.5, 40.0, 0, 0.56, 0.0, 2,
	0.8, 4.0, 0, 1.0, 0.0, 0])
static var P_TAIL := PackedFloat32Array([0.0, 0.0, 0, 0.08, -10.0, 1, 0.25, 40.0, 1, 0.5, 30.0, 0, 0.8, 0.0, 0])
static var P_FLARE := PackedFloat32Array([0.0, 0.0, 0, 0.1, 0.6, 1, 0.56, 1.0, 0, 1.0, 0.0, 0])
# ---- death
static var D_JOLT := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.32, 0.0, 0])

## Idle howl fidget interval (s, randomised +-40 % per unit); 0 = never. Only within 30 m of the camera.
@export var fidget_every: float = 12.0

var _variant: int = 0
var _authored: int = 0
var _parts: Array = []                 # [MeshInstance3D, key, front, sx] of every part (the variant swap)
var _skull: Node3D                     # Head/Skull pivot
var _skull_mi: MeshInstance3D          # its mesh (the B eyes glow on it)
var _jaw: Node3D
var _tail: Node3D
var _lowers: Array[Node3D] = []
var _lower_rest: Array[Vector3] = []
var _skull_rest: Vector3 = Vector3.ZERO
var _jaw_rest: Vector3 = Vector3.ZERO
var _tail_rest: Vector3 = Vector3.ZERO
var _skull_req: Vector3 = Vector3.ZERO                     # deg, this frame's skull offsets
var _jaw_req: float = 0.0                                  # deg, this frame's jaw opening
var _tail_req: Vector3 = Vector3.ZERO                      # deg, this frame's tail (x raise, y wag)
var _lower_req := PackedFloat32Array([0.0, 0.0, 0.0, 0.0]) # deg, this frame's folds (FL, FR, BL, BR)
var _skull_w: Vector3 = Vector3(999.0, 0.0, 0.0)
var _jaw_w: float = 999.0
var _tail_w: Vector3 = Vector3(999.0, 0.0, 0.0)
var _lower_w := PackedFloat32Array([999.0, 999.0, 999.0, 999.0])
var _jaw_now: float = 0.0              # last written jaw opening (deg)
var _flare: float = 0.0                # 0..1 eye flare (B): pounce, howl, hit
var _fade: float = 1.0                 # death fade of the eye glow
var _eye_w: float = -1.0
var _fidget_wait: float = 0.0
var _cast_last: float = -1.0
var _fidget_last: float = -1.0
var _bites: int = 0
var _pounces: int = 0
var _howls: int = 0


# ================================================================ public (EpicBeasts, tests, preview)

## 0 = Greymane (A), 1 = Moonpelt (B). Works before and after the model enters the tree; swaps every part's mesh.
func set_variant(v: int) -> void:
	_variant = clampi(v, 0, 1)
	if _ready_done:
		_apply_variant()


func get_variant() -> int:
	return _variant


## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Hamstring bites played so far (the `release` frame of each attack), for tests.
func strike_count() -> int:
	return _bites


## Pounces that reached their pinning bite, for tests.
func pounce_count() -> int:
	return _pounces


## Howls that reached their peak, for tests.
func howl_count() -> int:
	return _howls


## Current jaw opening (deg, 0 = shut).
func jaw_open() -> float:
	return _jaw_now


## Current flare (0 rest .. 1 full pounce flare).
func glow_flare() -> float:
	return _flare


## The glow_boost last written to the eyes (Moonpelt only; 0 for Greymane and once dead).
func eye_glow() -> float:
	return maxf(_eye_w, 0.0)


## Starts the idle howl now (it also plays by itself every ~fidget_every s close to the camera).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0
		_fidget_last = -1.0


## Neutral creature: no team colour.
func set_team_color(_c: Color) -> void:
	pass


# ================================================================ parts

func _part(pivot: Node3D, key: String, part_name: String, front: bool = false, sx: float = 1.0) -> MeshInstance3D:
	_authored += 1
	var mi := add_part(pivot, DM.part(key, _variant, front, sx), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true,
		part_name)
	_parts.append([mi, key, front, sx])
	return mi


func _build_parts() -> void:
	_authored = 0
	_parts.clear()
	_lowers.clear()
	_lower_rest.clear()
	var body := _part($Root/Mount, "body", "Body")
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var neck := _part($Root/Mount/Head, "neck", "Neck")
	neck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_skull = $Root/Mount/Head/Skull
	_skull_rest = _skull.position
	_skull_mi = _part(_skull, "skull", "Cranium")
	_skull_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_skull_mi.set_meta(&"own_glow", true)
	_jaw = $Root/Mount/Head/Skull/Jaw
	_jaw_rest = _jaw.position
	_part(_jaw, "jaw", "Mandible")
	_tail = $Root/Mount/Tail
	_tail_rest = _tail.position
	_part(_tail, "tail", "Brush")
	for k: int in 4:
		var leg: Node3D = get_node(LEG_PIVOTS[k])
		var front: bool = k < 2
		var sx: float = -1.0 if k % 2 == 0 else 1.0
		var th := _part(leg, "upper", "Thigh", front, sx)
		if not front:
			th.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var low: Node3D = leg.get_node("Lower")
		_part(low, "lower", "Shin", front, sx)
		_lowers.append(low)
		_lower_rest.append(low.position)
	ensure_shadow_blob(0.8, Color(0.03, 0.03, 0.04, 0.5))
	_shadow.scale = Vector3(1.3, 1.0, 2.9)
	_shadow.position = Vector3(0.0, 0.02, -0.08)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	# Every part flashes on hits (the kit only knows the humanoid chest / head / arm).
	for p: Array in _parts:
		var mi: MeshInstance3D = p[0]
		if mi and not _flash_hit_targets.has(mi):
			_flash_hit_targets.append(mi)
	_fidget_wait = _next_fidget() * 0.6
	_write_parts(true)
	_write_glow(true)


## Swaps every part to the current variant's meshes (cached per variant; materials are the variant's own).
func _apply_variant() -> void:
	for p: Array in _parts:
		var mi: MeshInstance3D = p[0]
		if mi:
			mi.mesh = DM.part(String(p[1]), _variant, bool(p[2]), float(p[3]))
	_eye_w = -1.0
	_write_glow(true)


# ================================================================ hooks

func _on_action_event(ev: StringName) -> void:
	if ev == &"release" and _action == &"attack":
		_bites += 1
		_flare = maxf(_flare, 0.4)
	elif ev == &"cast_start":
		_cast_last = -1.0


func _on_revive() -> void:
	_skull_req = Vector3.ZERO
	_jaw_req = 0.0
	_tail_req = Vector3.ZERO
	_lower_req.fill(0.0)
	_flare = 0.0
	_fade = 1.0
	_write_parts(true)
	_write_glow(true)


# ================================================================ idle / walk

func _idle_head(ph: float) -> Vector3:
	# A wary look around, head carried a little low.
	var y: float = 13.0 * sin(ph * 0.41 + 0.8 + _phase_off)
	var x: float = 3.0 + 3.0 * sin(ph * 0.6 + _phase_off * 2.0)
	return Vector3(x, y, 0.0) * DEG


## Idle extras: the tail sways, the jaw pants (only up close).
func _idle_parts(ph: float, w: float) -> void:
	_tail_req += Vector3(0.0, 6.0 * sin(ph * 0.8 + 1.3), 0.0) * w
	if _tier == 0:
		_jaw_req += (6.0 + 3.5 * sin(_t * 13.0 + _phase_off)) * w
	else:
		_jaw_req += 5.0 * w


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.007 * sin(ph), 0))
	_write_rot(P_MOUNT_HEAD, _rest_rot[P_MOUNT_HEAD] + _idle_head(ph))
	_idle_parts(ph, 1.0)


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph: float = (_t + _phase_off) * TAU / idle_period
	pos(P_ROOT, Vector3(0, 0.007 * sin(ph) * w, 0))
	rot(P_MOUNT_HEAD, _idle_head(ph) * w)
	_idle_parts(ph, w)


## Trot (diagonal pairs) blending into a rotary gallop (hinds, then fronts, one suspension) from rate 0.72 to 0.92.
func _pose_walk(w: float, rate: float) -> void:
	var g: float = smoothstep(0.72, 0.92, rate)
	var ph: float = TAU * _walk_p
	var offs_t: Array[float] = [0.0, 0.5, 0.5, 0.0]       # FL FR BL BR
	var offs_g: Array[float] = [0.5, 0.62, 0.0, 0.1]
	var amp_t: Array[float] = [30.0, 30.0, 27.0, 27.0]
	var amp_g: Array[float] = [46.0, 46.0, 40.0, 40.0]
	for k: int in 4:
		var pt: float = ph - TAU * offs_t[k]
		var pg: float = ph - TAU * offs_g[k]
		var ang: float = lerpf(amp_t[k] * sin(pt), amp_g[k] * sin(pg), g) * w
		var fold: float = lerpf(maxf(0.0, cos(pt)), maxf(0.0, cos(pg)), g) * w
		rot(P_LEG_FL + k, Vector3(-ang * DEG, 0, 0))
		_lower_req[k] += fold * (72.0 if k < 2 else -58.0)
	var bounce: float = lerpf(0.035 * (0.5 + 0.5 * cos(2.0 * ph)), 0.11 * (0.5 + 0.5 * cos(ph - TAU * 0.8)), g)
	pos(P_ROOT, Vector3(0, bounce * w, 0))
	var pitch: float = lerpf(1.0 * sin(2.0 * ph), 6.0 * sin(ph - TAU * 0.05), g)
	rot(P_ROOT, Vector3(pitch * DEG * w, 0, lerpf(1.5, 0.5, g) * sin(ph) * DEG * w))
	if _action == &"":
		var nx: float = lerpf(-2.0 + 2.5 * sin(2.0 * ph + 0.6), 6.0 + 7.0 * sin(ph - TAU * 0.55), g)
		rot(P_MOUNT_HEAD, Vector3(nx * DEG * w, 0, 0))
		_skull_req.x += -4.0 * sin(ph - TAU * 0.55) * g * w
		_jaw_req += lerpf(4.0, 14.0, g) * w
	_tail_req += Vector3(lerpf(8.0, 34.0, g) + lerpf(3.0 * sin(2.0 * ph), 6.0 * sin(ph), g),
		lerpf(7.0, 3.0, g) * sin(ph), 0.0) * w


func _leg(i: int, fwd: float, fold: float = 0.0, spread: float = 0.0) -> void:
	var sx: float = -1.0 if (i - P_LEG_FL) % 2 == 0 else 1.0
	rot(i, Vector3(-fwd * DEG, 0, sx * spread * DEG))
	_lower_req[i - P_LEG_FL] += fold


## Pitches the body about the paws that stay planted (+ nose down about the fore paws, - rears about the hind).
func _pitch_root(deg: float) -> void:
	var th: float = deg * DEG
	rot(P_ROOT, Vector3(th, 0, 0))
	var zp: float = FRONT_Z if th > 0.0 else HIND_Z
	pos(P_ROOT, Vector3(0, zp * sin(th), 0))


# ================================================================ attack / cast / fidget

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"hamstring_bite":
		return super._pose_attack(prev, t)
	rot(P_MOUNT_HEAD, Vector3(_trk(t, A_NECK), _trk(t, A_NECK_Y), 0) * DEG)
	_skull_req += Vector3(_trk(t, A_SKULL), 0.0, _trk(t, A_SKULL_Z))
	_jaw_req += _trk(t, A_JAW)
	pos(P_ROOT, Vector3(0, _trk(t, A_ROOT_Y), _trk(t, A_ROOT_Z)))
	_pitch_root(_trk(t, A_PITCH))
	var f: float = _trk(t, A_LEG_F)
	var b: float = _trk(t, A_LEG_B)
	_leg(P_LEG_FL, f, _trk(t, A_FOLD))
	_leg(P_LEG_FR, f * 0.5)
	_leg(P_LEG_BL, b)
	_leg(P_LEG_BR, b * 0.8)
	_tail_req.x += _trk(t, A_TAIL)
	if prev < BITE_HIT and t >= BITE_HIT:
		_on_action_event(&"release")
	return t < BITE_LEN


## Any cast id plays the Pounce: crouch, leap (root arc), landing, pinning bite + a worrying shake, recover.
func _pose_cast(_spell: StringName, t: float) -> float:
	pos(P_ROOT, Vector3(0, _trk(t, P_ROOT_Y), _trk(t, P_ROOT_Z)))
	_pitch_root(_trk(t, P_PITCH))
	rot(P_MOUNT_HEAD, Vector3(_trk(t, P_NECK), _trk(t, P_NECK_Y), 0) * DEG)
	_skull_req += Vector3(_trk(t, P_SKULL), 0.0, 0.0)
	_jaw_req += _trk(t, P_JAW)
	var f: float = _trk(t, P_LEG_F)
	var b: float = _trk(t, P_LEG_B)
	var ff: float = _trk(t, P_FOLD_F)
	var bf: float = _trk(t, P_FOLD_B)
	_leg(P_LEG_FL, f, ff)
	_leg(P_LEG_FR, f * 0.9 + 3.0, ff * 0.9)
	_leg(P_LEG_BL, b, bf)
	_leg(P_LEG_BR, b * 0.9 - 2.0, bf * 0.9)
	_tail_req.x += _trk(t, P_TAIL)
	_flare = maxf(_flare, _trk(t, P_FLARE))
	if _cast_last < POUNCE_BITE and t >= POUNCE_BITE:
		_pounces += 1
	_cast_last = t
	return POUNCE_LEN


## The howl (2.4 s): the head goes up and back, the jaws open, a tremolo, the front rises a little; B's eyes flare.
func _pose_fidget(t: float) -> void:
	var e: float = smoothstep(0.0, 0.5, t) * (1.0 - smoothstep(1.9, HOWL_LEN, t))
	var sing: float = smoothstep(0.45, 0.7, t) * (1.0 - smoothstep(1.75, 2.1, t))
	rot(P_MOUNT_HEAD, Vector3(-34.0 * e, 0, 0) * DEG)
	_skull_req.x += -26.0 * e
	_jaw_req += 24.0 * sing + 2.5 * sin(t * 30.0) * sing
	_pitch_root(-4.0 * e)
	_tail_req.x += -6.0 * e
	_flare = maxf(_flare, 0.55 * sing)
	if _fidget_last < HOWL_PEAK and t >= HOWL_PEAK:
		_howls += 1
	_fidget_last = t


# ================================================================ death (1.0 s)

func _pose_death(dt: float) -> void:
	var prev: float = _death_t
	_death_t += dt
	var t: float = _death_t
	var jolt: float = _trk(t, D_JOLT)
	var sag: float = smoothstep(0.06, 0.36, t)
	var top: float = _ease_in(clampf((t - 0.3) / 0.38, 0.0, 1.0))
	var sink: float = _ease_in(clampf((t - 0.8) / 0.2, 0.0, 1.0))
	# The hind legs give way (the rump drops, nose up), then it topples onto its left side.
	# (Greymane's mane holds it a little higher on its side.)
	var rest_y: float = 0.08 if _variant == 0 else -0.04
	rot(P_ROOT, Vector3(-7.0 * sag * (1.0 - top) * DEG, 0, TOPPLE * top * DEG))
	pos(P_ROOT, Vector3(0.52 * top, lerpf(-0.22 * sag, rest_y, top) - 0.45 * sink, -0.06 * sag * (1.0 - top)))
	var kick: float = 0.0
	if t > 0.7:
		kick = sin((t - 0.7) * 30.0) * exp(-(t - 0.7) * 6.0)
	# Legs: the hinds fold under while it sags, the fronts brace; then all stretch out stiff, swung up level with the
	# ground (a +z roll lifts every paw toward the sky side); a last kick of the hind legs.
	for i: int in [P_LEG_FL, P_LEG_FR]:
		_leg(i, -6.0 * sag * (1.0 - top) + 16.0 * top, 20.0 * sag * (1.0 - top) + 6.0 * top)
	_leg(P_LEG_BL, 24.0 * sag * (1.0 - top) - 14.0 * top - 12.0 * kick, -50.0 * sag * (1.0 - top) - 6.0 * top)
	_leg(P_LEG_BR, 24.0 * sag * (1.0 - top) - 18.0 * top + 10.0 * kick, -50.0 * sag * (1.0 - top) - 10.0 * top)
	for i: int in [P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		rot(i, Vector3(0, 0, (DEATH_LEG_LIFT + (6.0 if (i - P_LEG_FL) % 2 == 1 else 0.0)) * top * DEG))
	# Head: a yelp (up, jaws open), then it droops; the jaw hangs slack.
	rot(P_MOUNT_HEAD, Vector3((-22.0 * jolt + 16.0 * top) * DEG, 0, -12.0 * top * DEG))
	_skull_req += Vector3(-10.0 * jolt + 6.0 * top, 0.0, 0.0)
	_jaw_req += 30.0 * jolt + 10.0 * top
	_tail_req.x += -14.0 * sag
	_flare = maxf(_flare, jolt)
	_fade = 1.0 - smoothstep(0.2, DEATH_GLOW_OFF, t)
	if prev < DEATH_GLOW_OFF and t >= DEATH_GLOW_OFF:
		_glows_dead()
	if _shadow:
		_shadow.transparency = clampf((t - 0.6) / 0.4, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		_write_parts(false)
		_write_glow(true)
		death_finished.emit()
		set_process(false)


# ================================================================ per frame extras

func _extra_process(dt: float) -> void:
	if not _dead:
		if _action == &"fidget":
			if _speed >= 0.3 or _action_t >= HOWL_LEN:
				_action = &""
			else:
				_pose_fidget(_action_t)
		elif fidget_every > 0.0 and _action == &"" and _speed < 0.3 and _tier == 0:
			_fidget_wait -= dt
			if _fidget_wait <= 0.0:
				_fidget_wait = _next_fidget()
				play_fidget()
		if _hit_t < HIT_LEN:
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_MOUNT_HEAD, Vector3(-12.0 * k, 8.0 * k, 0) * DEG)
			_skull_req.z += 6.0 * k
			_jaw_req += 16.0 * k
			_tail_req.x -= 18.0 * k
			_flare = maxf(_flare, 0.3 * k)
	_write_parts(false)
	_write_glow(false)
	_flare = move_toward(_flare, 0.0, dt * 1.5)
	_skull_req = Vector3.ZERO
	_jaw_req = 0.0
	_tail_req = Vector3.ZERO
	_lower_req.fill(0.0)


## Writes the Skull / Jaw / Tail / shin transforms (skipped when they barely changed).
func _write_parts(force: bool) -> void:
	if _skull and (force or (_skull_req - _skull_w).length() > 0.25):
		_skull_w = _skull_req
		_skull.transform = Transform3D(Basis.from_euler(_skull_req * DEG), _skull_rest)
	var j: float = clampf(_jaw_req, 0.0, JAW_MAX)
	if _jaw and (force or absf(j - _jaw_w) > 0.3):
		_jaw_w = j
		_jaw_now = j
		_jaw.transform = Transform3D(Basis(Vector3.RIGHT, j * DEG), _jaw_rest)
	if _tail and (force or (_tail_req - _tail_w).length() > 0.3):
		_tail_w = _tail_req
		_tail.transform = Transform3D(Basis.from_euler(_tail_req * DEG), _tail_rest)
	for k: int in _lowers.size():
		var v: float = _lower_req[k]
		if force or absf(v - _lower_w[k]) > 0.3:
			_lower_w[k] = v
			_lowers[k].transform = Transform3D(Basis(Vector3.RIGHT, v * DEG), _lower_rest[k])


## Moonpelt eyes: steady x glow_level (0 once dead) x the death fade, + the flares. Greymane: 0 (painted eyes).
## Written only when they change enough.
func _write_glow(force: bool) -> void:
	if _skull_mi == null:
		return
	var g: float = 0.0
	if _variant == 1:
		g = glow_level() * _fade * (1.0 + 1.1 * _flare)
	if force or absf(g - _eye_w) > 0.03 or (g == 0.0 and _eye_w != 0.0):
		_eye_w = g
		_skull_mi.set_instance_shader_parameter(&"glow_boost", g)


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


## Keyframe track [t, v, ease, ...] (see the constants). A few float ops per call.
static func _trk(t: float, k: PackedFloat32Array) -> float:
	var n: int = k.size()
	if t >= k[n - 3]:
		return k[n - 2]
	if t <= 0.0:
		return k[1]
	var i: int = 3
	while t >= k[i]:
		i += 3
	var t0: float = k[i - 3]
	var u: float = (t - t0) / (k[i] - t0)
	var e: float = k[i + 2]
	if e == 1.0:
		u = u * (2.0 - u)
	elif e == 2.0:
		u = u * u
	else:
		u = u * u * (3.0 - 2.0 * u)
	return k[i - 2] + (k[i + 1] - k[i - 2]) * u
