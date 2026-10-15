extends CharacterModel
## Grizzlemaw (map-fill.md 5.5 / 10, task 12.V30): the epic cave bear of the two Old Wood Dens, BOTH variants in one
## scene. A towering brown bear: ~2.15 m at the shoulder HUMP (rump lower), ~3.3 m nose to rump, a big round head held
## low with small round ears, radius 1.1, spec height 2.6. Rears to ~3.8 m for the Rending Roar. Read at 40 m by:
##  - the MASS: a round barrel with a high shoulder hump, the head lower than the hump, short thick legs, no horns /
##    tusks / trunk (the Ice War Mammoth has tusks + trunk, the Tusker tusks + a bristle ridge, the Bramblehorn big
##    pale horns + a leaf mane, the Direwolf is lean with long legs and a tail);
##  - variant A: warm BROWN with a green MOSS SADDLE over the hump and shoulders; a tan muzzle;
##  - the HUGE pale CLAWS ahead of the front paws (0.3 m, curved) and the amber glowing eyes (the one glow point, red
##    and brighter when enraged);
##  - variant B (Elder Grizzlemaw, set_variant(1)): x1.15, grey-brown fur raked with SILVER STREAKS, a WHITE muzzle and
##    brows, claw scars, a torn left ear, less moss, a RUSTED CHAIN collar (dangling broken end, lock plate, tooth
##    pendant) with old BONES tied on it (a small skull, two crossed long bones).
## Neutral: no team colour (set_team_color is a no-op), 0 lights, glow by emission only (the eyes).
## Motion (procedural, kit rules):
##  - idle: heavy breathing, a slow low look around; every ~fidget_every s at close range it STANDS UP on its hind legs
##    to sniff the air, then drops back down (dust); `play_fidget()` starts one now;
##  - walk: a heavy amble (lateral sequence), the shoulders rolling, the head swinging low, the forearms folding;
##  - attack `claw_swipe` (0.75 s, strike 0.12 s = the kit strike frame): alternating paws; rears a little, the paw goes
##    up and crashes down and across with a lunge, the head snaps in with the jaw open;
##  - cast `maul` (1.0 s): rears (-24 deg), the right paw crashes down at 0.12 s (the damage is instant at the cast),
##    the left paw follows at 0.38 s, two bites; eyes flare;
##  - cast `rending_roar` (1.8 s): REARS UP onto its hind legs (-60 deg about the hips, forelegs spread, claws out),
##    ROARS with the jaw wide open and the head shaking (a burst of breath mist at 0.28 s), then slams both forepaws
##    down at 1.24 s (dust); the shock ring is MapFillVfx `rending_roar` (12.V31); `enrage` (or any other id) plays a
##    short snarling head shake and turns the enrage look on;
##  - enrage look (below 30 % HP; CreatureAbilities adds the unit modifier `beast:enrage`, polled every 0.5 s, or
##    `set_enraged(on)` / `set_status(&"enraged", on)`): red, brighter eyes (mesh swap, no new material instance), head
##    carried low, a snarl (jaw ajar, trembling), faster breathing;
##  - hit: the kit push + flash, the head jerks, the jaw snaps open;
##  - death (1.0 s): a last roar (head up), the front legs buckle, it rolls onto its left side (dust), the legs stiffen,
##    the eyes die (0.55 s), then it sinks (the unit is freed at death_finished).
## Budget (map-fill.md 10 hero: <= 26 authored meshes, <= 16 draw instances, 0 lights; keep_separate <= 6): 11
## authored meshes (6 merged pivots: body, head, 4 upper legs; keep_separate Jaw + 4 Paws) + the blob = 12; 14 draw
## instances with the 2 one-shot emitters (Dust, Breath). Variant / enrage = cached mesh swaps on the same instances
## (0 extra draw instances). 13 own materials (materials/): 7 shared + moss (A mostly) + 4 Elder + 2 eye glows.
## See tests/test_12_v30.gd.

const GM := preload("res://art/units/neutral/beasts/grizzlemaw/grizzlemaw_mesh.gd")
const B_SCALE := 1.15
const BASE_HEIGHT := 2.6
const SWIPE_LEN := 0.75
const SWIPE_HIT := 0.12
const MAUL_LEN := 1.0
const MAUL_HIT := 0.12
const MAUL_HIT2 := 0.38
const ROAR_LEN := 1.8
const ROAR_BREATH := 0.28
const ROAR_SLAM := 1.24
const SNARL_LEN := 0.9
const SNIFF_LEN := 2.8
const SNIFF_LAND := 2.42
const DEATH_GLOW_OFF := 0.55
const DEATH_LAND := 0.66
const TOPPLE := 80.0                     # deg: the death roll onto its left side
const DEATH_LEG_LIFT := 20.0
const ENRAGE_POLL := 0.5
const ENRAGE_MODIFIER := &"beast:enrage"
const LEG_PIVOTS: Array[String] = ["Root/Mount/LegFL", "Root/Mount/LegFR", "Root/Mount/LegBL", "Root/Mount/LegBR"]

# Keyframe tracks [t, value, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth, 1 ease-out,
# 2 ease-in). Degrees / metres. Pitch: - = rears (nose up, about the hips), + = crashes forward. Legs "fwd": + = paw
# forward / up. Fold (Lower): + = the paw folds back, - = the forearm swings forward / up. Spread: + = out to the side.
# Neck x: + = head down. Jaw: + = open. Swipe tracks with a side: x s (+1 = right paw).
static var S_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.08, -10.0, 1, 0.15, 5.0, 2, 0.4, -1.0, 1, 0.75, 0.0, 0])
static var S_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.12, 1, 0.15, 0.32, 2, 0.4, 0.18, 1, 0.75, 0.0, 0])
static var S_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.08, 8.0, 1, 0.18, -10.0, 0, 0.5, 0.0, 0])
static var S_LEG := PackedFloat32Array([0.0, 0.0, 0, 0.08, 72.0, 1, 0.15, -6.0, 2, 0.4, 4.0, 1, 0.7, 0.0, 0])
static var S_FOLD := PackedFloat32Array([0.0, 0.0, 0, 0.08, -75.0, 1, 0.15, 18.0, 2, 0.45, 0.0, 0])
static var S_SPREAD := PackedFloat32Array([0.0, 0.0, 0, 0.08, 18.0, 1, 0.17, -26.0, 0, 0.5, 0.0, 0])
static var S_BRACE := PackedFloat32Array([0.0, 0.0, 0, 0.08, -6.0, 1, 0.2, 6.0, 0, 0.6, 0.0, 0])
static var S_NECK := PackedFloat32Array([0.0, 0.0, 0, 0.08, -18.0, 1, 0.15, 18.0, 2, 0.35, 4.0, 1, 0.7, 0.0, 0])
static var S_NECK_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 10.0, 1, 0.18, -8.0, 0, 0.5, 0.0, 0])
static var S_JAW := PackedFloat32Array([0.0, 0.0, 0, 0.1, 30.0, 1, 0.2, 6.0, 0, 0.5, 0.0, 0])
static var M_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.09, -24.0, 1, 0.16, 6.0, 2, 0.3, -12.0, 1, 0.4, 4.0, 2,
	0.6, -2.0, 1, 1.0, 0.0, 0])
static var M_Z := PackedFloat32Array([0.0, 0.0, 0, 0.09, -0.1, 1, 0.16, 0.34, 2, 0.3, 0.2, 1, 0.4, 0.45, 2, 0.6, 0.3, 1,
	1.0, 0.0, 0])
static var M_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.09, 8.0, 1, 0.18, -10.0, 0, 0.3, -4.0, 1, 0.42, 10.0, 0, 0.7,
	0.0, 0])
static var M_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.09, 95.0, 1, 0.16, -8.0, 2, 0.4, 10.0, 1, 0.8, 0.0, 0])
static var M_FOLD_R := PackedFloat32Array([0.0, 0.0, 0, 0.09, -90.0, 1, 0.16, 25.0, 2, 0.5, 0.0, 0])
static var M_SPREAD_R := PackedFloat32Array([0.0, 0.0, 0, 0.09, 24.0, 1, 0.18, -30.0, 0, 0.5, 0.0, 0])
static var M_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.09, 28.0, 1, 0.18, 8.0, 0, 0.3, 90.0, 1, 0.4, -8.0, 2, 0.8,
	0.0, 0])
static var M_FOLD_L := PackedFloat32Array([0.0, 0.0, 0, 0.09, -20.0, 1, 0.18, -10.0, 0, 0.3, -85.0, 1, 0.4, 25.0, 2,
	0.7, 0.0, 0])
static var M_SPREAD_L := PackedFloat32Array([0.0, 0.0, 0, 0.18, 0.0, 0, 0.3, 24.0, 1, 0.42, -30.0, 0, 0.7, 0.0, 0])
static var M_NECK := PackedFloat32Array([0.0, 0.0, 0, 0.09, -25.0, 1, 0.18, 20.0, 2, 0.3, -10.0, 1, 0.42, 24.0, 2,
	0.9, 0.0, 0])
static var M_JAW := PackedFloat32Array([0.0, 0.0, 0, 0.1, 36.0, 1, 0.18, 10.0, 0, 0.32, 40.0, 1, 0.45, 4.0, 0, 0.9,
	0.0, 0])
static var M_FLARE := PackedFloat32Array([0.0, 0.0, 0, 0.12, 1.0, 1, 0.45, 0.8, 0, 1.0, 0.0, 0])
static var R_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.3, -60.0, 1, 1.0, -56.0, 0, 1.12, -63.0, 1, 1.26, 4.0, 2,
	1.45, -2.0, 1, 1.8, 0.0, 0])
static var R_CROUCH := PackedFloat32Array([0.0, 0.0, 0, 0.3, 0.03, 1, 1.12, 0.03, 0, 1.26, 0.0, 0])
static var R_Z := PackedFloat32Array([0.0, 0.0, 0, 1.12, 0.0, 0, 1.26, 0.25, 2, 1.7, 0.0, 0])
static var R_LEG := PackedFloat32Array([0.0, 0.0, 0, 0.3, 10.0, 1, 1.0, 14.0, 0, 1.12, 40.0, 1, 1.26, 8.0, 2, 1.6, 0.0,
	0])
static var R_FOLD := PackedFloat32Array([0.0, 0.0, 0, 0.3, -30.0, 1, 1.0, -26.0, 0, 1.12, -50.0, 1, 1.26, 10.0, 2,
	1.6, 0.0, 0])
static var R_SPREAD := PackedFloat32Array([0.0, 0.0, 0, 0.3, 26.0, 1, 1.0, 24.0, 0, 1.12, 10.0, 1, 1.26, 4.0, 0, 1.6,
	0.0, 0])
static var R_NECK := PackedFloat32Array([0.0, 0.0, 0, 0.3, 34.0, 1, 1.0, 30.0, 0, 1.12, 20.0, 0, 1.26, 12.0, 2, 1.7,
	0.0, 0])
static var R_JAW := PackedFloat32Array([0.0, 0.0, 0, 0.22, 44.0, 1, 1.0, 46.0, 0, 1.14, 20.0, 0, 1.26, 8.0, 0, 1.6,
	0.0, 0])
static var R_SHAKE := PackedFloat32Array([0.0, 0.0, 0, 0.32, 0.0, 0, 0.45, 1.0, 1, 0.95, 1.0, 0, 1.05, 0.0, 0])
static var R_FLARE := PackedFloat32Array([0.0, 0.0, 0, 0.28, 1.0, 1, 1.0, 0.9, 0, 1.3, 0.5, 0, 1.8, 0.0, 0])
static var F_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.6, -52.0, 1, 1.9, -50.0, 0, 2.4, 2.0, 2, 2.6, 0.0, 0])
static var F_LEG := PackedFloat32Array([0.0, 0.0, 0, 0.6, 20.0, 1, 1.9, 22.0, 0, 2.3, 10.0, 1, 2.45, 0.0, 0])
static var F_FOLD := PackedFloat32Array([0.0, 0.0, 0, 0.6, 55.0, 1, 1.9, 50.0, 0, 2.35, 0.0, 0])
static var F_NECK := PackedFloat32Array([0.0, 0.0, 0, 0.6, 30.0, 1, 1.9, 26.0, 0, 2.5, 0.0, 0])
static var D_JOLT := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.3, 0.0, 0])

## Idle stand-and-sniff fidget interval (s, randomised +-40 % per unit); 0 = never. Only within 30 m of the camera.
@export var fidget_every: float = 12.0

var _authored: int = 0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig
var _variant: int = 0
var _enraged: bool = false
var _rage_w: float = 0.0             # 0..1 blend of the enraged pose
var _head_node: Node3D
var _jaw: Node3D
var _jaw_mi: MeshInstance3D
var _head_gi: GeometryInstance3D
var _dust: GPUParticles3D
var _breath: GPUParticles3D
var _lowers: Array[Node3D] = []
var _paws: Array[MeshInstance3D] = []
var _lower_rest: Array[Vector3] = []
var _jaw_rest: Vector3 = Vector3.ZERO
var _jaw_req: float = 0.0            # deg, this frame's jaw opening
var _lower_req := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _jaw_w: float = 999.0
var _lower_w := PackedFloat32Array([999.0, 999.0, 999.0, 999.0])
var _flare: float = 0.0
var _fade: float = 1.0
var _eye_w: float = -1.0
var _meshes_key: String = ""
var _fidget_wait: float = 0.0
var _poll_t: float = 0.0
var _unit: Node = null
var _unit_looked: bool = false
var _swipe_side: float = 1.0
var _cast_last: float = -1.0
var _fidget_last: float = -1.0
var _swipes: int = 0
var _mauls: int = 0
var _roars: int = 0
var _slams: int = 0
var _dusts: int = 0
var _breaths: int = 0
## G-D signature emitter (High / Ultra only; null otherwise).
var _sig: GPUParticles3D


# ================================================================ public (tests, preview, EpicBeasts)

## 0 = Grizzlemaw (A), 1 = Elder Grizzlemaw (B: x1.15, grey-streaked, white muzzle, chain and bones). Safe before
## _ready (applied then). EpicBeasts calls it through Unit.model_call right after the spawn.
func set_variant(v: int) -> void:
	_variant = clampi(v, 0, 1)
	scale = Vector3.ONE * (B_SCALE if _variant == 1 else 1.0)
	body_height = BASE_HEIGHT * (B_SCALE if _variant == 1 else 1.0)
	if _ready_done:
		for gi: GeometryInstance3D in _flash_all_targets:
			gi.set_instance_shader_parameter(&"ao_height", body_height)
		_apply_meshes()


func get_variant() -> int:
	return _variant


## The enrage look (red brighter eyes, head low, snarl, fast breathing). It also follows the owning Unit's
## `beast:enrage` modifier by itself (polled every 0.5 s).
func set_enraged(on: bool) -> void:
	if on == _enraged:
		return
	_enraged = on
	if _ready_done:
		_apply_meshes()
		_write_glow(true)


func is_enraged() -> bool:
	return _enraged


func set_status(id: StringName, on: bool) -> bool:
	if id == &"enraged" or id == &"enrage":
		set_enraged(on)
		return true
	return super.set_status(id, on)


## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Swipe strikes played so far (the `release` frame of each attack), for tests.
func strike_count() -> int:
	return _swipes


func maul_count() -> int:
	return _mauls


func roar_count() -> int:
	return _roars


func slam_count() -> int:
	return _slams


func dust_count() -> int:
	return _dusts


func breath_count() -> int:
	return _breaths


## +1 = the next / current swipe uses the right paw, -1 the left.
func swipe_side() -> float:
	return _swipe_side


func glow_flare() -> float:
	return _flare


## The glow_boost last written to the eyes (0 once dead).
func eye_glow() -> float:
	return _eye_w


## Starts the stand-and-sniff fidget now (it also plays by itself every ~fidget_every s close to the camera).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0
		_fidget_last = -1.0


## Neutral creature: no team colour.
func set_team_color(_c: Color) -> void:
	pass


# ================================================================ parts

func _part(pivot: Node3D, mesh: Mesh, at: Vector3, keep: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored += 1
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, part_name)


func _build_parts() -> void:
	_authored = 0
	_lowers.clear()
	_paws.clear()
	_lower_rest.clear()
	_part($Root/Mount, GM.body_mesh(0), Vector3.ZERO)
	_head_node = $Root/Mount/Head
	_part(_head_node, GM.head_mesh(0, false), GM.HEAD_PIVOT)
	_face = CreatureFaceRig.attach(self, _head_node, "grizzlemaw_0_false", face_spec(0, false))
	_jaw = $Root/Mount/Head/Jaw
	_jaw_rest = _jaw.position
	_jaw_mi = _part(_jaw, GM.jaw_mesh(0), GM.JAW_PIVOT, true, "JawMesh")
	for k: int in 4:
		var leg: Node3D = get_node(LEG_PIVOTS[k])
		var front: bool = k < 2
		var sx: float = -1.0 if k % 2 == 0 else 1.0
		var m := Vector3(sx, 1.0, 1.0)
		_part(leg, GM.upper_leg_mesh(front, sx, 0), (GM.LEG_F if front else GM.LEG_B) * m)
		var low: Node3D = leg.get_node("Lower")
		_paws.append(_part(low, GM.lower_leg_mesh(front, sx, 0), (GM.ELBOW if front else GM.KNEE) * m, true, "Paw"))
		_lowers.append(low)
		_lower_rest.append(low.position)
	_dust = $Fx/Dust
	_breath = $Fx/Breath
	ensure_shadow_blob(1.1, Color(0.03, 0.025, 0.02, 0.55))
	_shadow.scale = Vector3(1.6, 1.0, 3.3)
	_shadow.position = Vector3(0.0, 0.02, -0.1)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	# The kit flashes the merged Chest / Head / ArmR on hits; a quadruped has none: add the body, head, legs, jaw, paws.
	for i: int in [P_MOUNT, P_MOUNT_HEAD, P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
		if m and i == P_MOUNT_HEAD:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for g: MeshInstance3D in [_jaw_mi] + _paws:
		if g and not _flash_hit_targets.has(g):
			_flash_hit_targets.append(g)
	# The eyes (in the merged head) glow on their own: flares, enrage, the death fade.
	_head_gi = _merged_nodes.get(P_MOUNT_HEAD)
	if _head_gi:
		_glow_nodes.erase(_head_gi)
	if _face:
		_face.set_host(_head_gi as MeshInstance3D)
	_fidget_wait = _next_fidget() * 0.6
	set_variant(_variant)
	_write_parts(true)
	_write_glow(true)
	# G-D signature (High+): pale spores shaken loose from the moss saddle over the hump.
	var mount: Node3D = $Root/Mount
	_sig = CreatureSignature.attach(self, mount, Vector3(0.0, 2.05, 0.25) - model_origin(mount), &"moss_dust", 1.4)


## Puts the meshes of the current variant / enrage state on the SAME instances (cached ArrayMeshes, local to each
## pivot exactly like the kit's merged meshes).
func _apply_meshes() -> void:
	var key := "%d_%s" % [_variant, _enraged]
	if key == _meshes_key:
		return
	_meshes_key = key
	if _face:
		_face.switch("grizzlemaw_" + key, face_spec(_variant, _enraged))
	var v := _variant
	var body: MeshInstance3D = _merged_nodes.get(P_MOUNT)
	if body:
		body.mesh = GM.body_mesh(v)
	if _head_gi is MeshInstance3D:
		(_head_gi as MeshInstance3D).mesh = GM.head_mesh(v, _enraged)
		if _face:   # the face goes back into the new head now, not at the next animated frame (half-rate tiers skip one)
			_face.auto_any(self)
	if _jaw_mi:
		_jaw_mi.mesh = GM.jaw_mesh(v)
	for k: int in 4:
		var front: bool = k < 2
		var sx: float = -1.0 if k % 2 == 0 else 1.0
		var up: MeshInstance3D = _merged_nodes.get(P_LEG_FL + k)
		if up:
			up.mesh = GM.upper_leg_mesh(front, sx, v)
		if k < _paws.size() and _paws[k]:
			_paws[k].mesh = GM.lower_leg_mesh(front, sx, v)


## G-D signature gate (CreatureSignature, High / Ultra only): near tier, animating, alive.
func signature_should_emit() -> bool:
	return _tier == 0 and not _offscreen and not _frozen and not _dead


# ================================================================ hooks

func _on_action_event(ev: StringName) -> void:
	if ev == &"attack_start":
		_swipe_side = -_swipe_side
	elif ev == &"release" and _action == &"attack":
		_swipes += 1
		_flare = maxf(_flare, 0.45)
	elif ev == &"cast_start":
		_cast_last = -1.0
		if _cast_id == &"enrage":
			set_enraged(true)


func _on_revive() -> void:
	if _face:
		_face.reset()
	_jaw_req = 0.0
	_lower_req.fill(0.0)
	_flare = 0.0
	_fade = 1.0
	_rage_w = 0.0
	set_enraged(false)
	_write_parts(true)
	_write_glow(true)


# ================================================================ idle / walk

func _idle_head(ph: float) -> Vector3:
	# A slow, low look around; enraged: head lower, a small restless sway.
	var y: float = 12.0 * sin(ph * 0.33 + 0.4 + _phase_off)
	var x: float = 2.0 + 3.0 * sin(ph * 0.5 + _phase_off * 2.0)
	return Vector3(x + 12.0 * _rage_w, y * (1.0 - 0.4 * _rage_w), 0.0) * DEG


func _breath_ph() -> float:
	return (_t + _phase_off) * TAU / idle_period * (1.0 + 1.3 * _rage_w)


func _idle_fast() -> void:
	var ph := _breath_ph()
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.006 * sin(ph), 0))
	_write_rot(P_MOUNT_HEAD, _rest_rot[P_MOUNT_HEAD] + _idle_head(ph))


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph := _breath_ph()
	pos(P_ROOT, Vector3(0, 0.006 * sin(ph) * w, 0))
	rot(P_MOUNT_HEAD, _idle_head(ph) * w)


## Heavy amble (lateral sequence: BL, FL, BR, FR a quarter apart); each forearm / shin folds through its swing; the
## shoulders roll, the head swings low.
func _pose_walk(w: float, _rate: float) -> void:
	var ph: float = TAU * _walk_p
	_stride(P_LEG_BL, ph, 20.0 * w, 42.0 * w)
	_stride(P_LEG_FL, ph - PI * 0.5, 22.0 * w, 58.0 * w)
	_stride(P_LEG_BR, ph - PI, 20.0 * w, 42.0 * w)
	_stride(P_LEG_FR, ph - PI * 1.5, 22.0 * w, 58.0 * w)
	pos(P_ROOT, Vector3(0, walk_bounce * (0.5 + 0.5 * cos(2.0 * ph)) * w, 0))
	rot(P_ROOT, Vector3(1.0 * DEG * sin(2.0 * ph) * w, 1.5 * DEG * sin(ph) * w, 3.0 * DEG * sin(ph + 0.8) * w))
	if _action == &"":
		rot(P_MOUNT_HEAD, Vector3((6.0 + 3.0 * sin(2.0 * ph + 0.6)) * DEG * w, -7.0 * DEG * sin(ph + 0.3) * w, 0))


func _stride(i: int, ph: float, amp: float, fold: float) -> void:
	rot(i, Vector3(-amp * sin(ph) * DEG, 0, 0))
	_lower_req[i - P_LEG_FL] += fold * maxf(0.0, cos(ph))


func _leg(i: int, fwd: float, fold: float = 0.0, spread: float = 0.0) -> void:
	var sx: float = -1.0 if (i - P_LEG_FL) % 2 == 0 else 1.0
	rot(i, Vector3(-fwd * DEG, 0, sx * spread * DEG))
	_lower_req[i - P_LEG_FL] += fold


## Pitches the whole body about the hips (- rears up, + crashes forward) and keeps the hind legs vertical under them.
func _pitch_hips(deg: float) -> void:
	var th: float = deg * DEG
	rot(P_ROOT, Vector3(th, 0, 0))
	var hy: float = GM.HIP.y
	var hz: float = GM.HIP.z
	pos(P_ROOT, Vector3(0, hy - hy * cos(th) + hz * sin(th), hz - hy * sin(th) - hz * cos(th)))
	_leg(P_LEG_BL, deg)
	_leg(P_LEG_BR, deg)


# ================================================================ attack / casts / fidget

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"claw_swipe":
		return super._pose_attack(prev, t)
	var s: float = _swipe_side
	_pitch_hips(_trk(t, S_PITCH))
	pos(P_ROOT, Vector3(0, 0, _trk(t, S_Z)))
	rot(P_ROOT, Vector3(0, _trk(t, S_YAW) * s * DEG, 0))
	var paw: int = P_LEG_FR if s > 0.0 else P_LEG_FL
	var other: int = P_LEG_FL if s > 0.0 else P_LEG_FR
	_leg(paw, _trk(t, S_LEG), _trk(t, S_FOLD), _trk(t, S_SPREAD))
	_leg(other, _trk(t, S_BRACE))
	rot(P_MOUNT_HEAD, Vector3(_trk(t, S_NECK), _trk(t, S_NECK_Y) * s, 0) * DEG)
	_jaw_req += _trk(t, S_JAW)
	if prev < SWIPE_HIT and t >= SWIPE_HIT:
		_on_action_event(&"release")
	return t < SWIPE_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		&"maul":
			return _pose_maul(t)
		&"rending_roar":
			return _pose_roar(t)
	return _pose_snarl(t)


## Maul (1.0 s): rears, the right paw crashes down at 0.12 s, the left at 0.38 s, two bites; the eyes flare.
func _pose_maul(t: float) -> float:
	_pitch_hips(_trk(t, M_PITCH))
	pos(P_ROOT, Vector3(0, 0, _trk(t, M_Z)))
	rot(P_ROOT, Vector3(0, _trk(t, M_YAW) * DEG, 0))
	_leg(P_LEG_FR, _trk(t, M_LEG_R), _trk(t, M_FOLD_R), _trk(t, M_SPREAD_R))
	_leg(P_LEG_FL, _trk(t, M_LEG_L), _trk(t, M_FOLD_L), _trk(t, M_SPREAD_L))
	rot(P_MOUNT_HEAD, Vector3(_trk(t, M_NECK), 0, 0) * DEG)
	_jaw_req += _trk(t, M_JAW)
	_flare = maxf(_flare, _trk(t, M_FLARE))
	if _cast_last < MAUL_HIT and t >= MAUL_HIT:
		_mauls += 1
	if _cast_last < MAUL_HIT2 and t >= MAUL_HIT2:
		_dust_at_paws(0.35)
	_cast_last = t
	return MAUL_LEN


## Rending Roar (1.8 s): rears up on the hind legs, forelegs spread, roars (jaw wide, head shaking, breath at 0.28 s),
## then slams both forepaws down at 1.24 s (dust).
func _pose_roar(t: float) -> float:
	_pitch_hips(_trk(t, R_PITCH))
	pos(P_ROOT, Vector3(0, _trk(t, R_CROUCH), _trk(t, R_Z)))
	var lf: float = _trk(t, R_LEG)
	var fo: float = _trk(t, R_FOLD)
	var sp: float = _trk(t, R_SPREAD)
	var claw_twitch: float = 6.0 * sin(t * 17.0) * _trk(t, R_SHAKE)
	_leg(P_LEG_FL, lf + claw_twitch, fo, sp)
	_leg(P_LEG_FR, lf - claw_twitch, fo, sp)
	var shake: float = _trk(t, R_SHAKE)
	rot(P_MOUNT_HEAD, Vector3(_trk(t, R_NECK) + 4.0 * sin(t * 31.0) * shake, 14.0 * sin(t * 23.0) * shake, 0) * DEG)
	_jaw_req += _trk(t, R_JAW) + 3.0 * sin(t * 40.0) * shake
	_flare = maxf(_flare, _trk(t, R_FLARE))
	if _cast_last < ROAR_BREATH and t >= ROAR_BREATH:
		_roars += 1
		_breath_burst()
	if _cast_last < ROAR_SLAM and t >= ROAR_SLAM:
		_slams += 1
		_dust_at_paws(1.0)
	_cast_last = t
	return ROAR_LEN


## Snarl (0.9 s, `enrage` and any unknown id): head low, jaw open, a violent head shake, the eyes flare.
func _pose_snarl(t: float) -> float:
	var env: float = sin(PI * clampf(t / SNARL_LEN, 0.0, 1.0))
	rot(P_MOUNT_HEAD, Vector3(14.0 * env, 16.0 * sin(t * 24.0) * env, 0) * DEG)
	_jaw_req += 32.0 * env
	_leg(P_LEG_FL, -6.0 * env, 0.0, 6.0 * env)
	_leg(P_LEG_FR, -6.0 * env, 0.0, 6.0 * env)
	_flare = maxf(_flare, 0.8 * env)
	return SNARL_LEN


## Stand and sniff (2.8 s): rises onto its hind legs, forepaws hanging, nose working, a slow look, drops back (dust).
func _pose_fidget(t: float) -> void:
	_pitch_hips(_trk(t, F_PITCH))
	var lf: float = _trk(t, F_LEG)
	var fo: float = _trk(t, F_FOLD)
	_leg(P_LEG_FL, lf, fo, 4.0)
	_leg(P_LEG_FR, lf, fo, 4.0)
	var env: float = clampf((t - 0.6) / 0.2, 0.0, 1.0) * clampf((1.95 - t) / 0.2, 0.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(_trk(t, F_NECK) + 5.0 * sin(t * 20.0) * env, 22.0 * sin((t - 0.6) * 2.4) * env, 0) * DEG)
	_jaw_req += 4.0 * env * maxf(0.0, sin(t * 20.0))
	if _fidget_last < SNIFF_LAND and t >= SNIFF_LAND:
		_dust_at_paws(0.4)
	_fidget_last = t


func _paw_world(k: int) -> Vector3:
	var sx: float = -1.0 if k % 2 == 0 else 1.0
	return _lowers[k].global_transform * ((GM.PAW_F - GM.ELBOW) * Vector3(sx, 1.0, 1.0))


## Restarts the Dust emitter between the fore paws, on the ground.
func _dust_at_paws(ratio: float) -> void:
	if _dust == null or _lowers.size() < 2 or not is_inside_tree():
		return
	_dusts += 1
	var p := (_paw_world(0) + _paw_world(1)) * 0.5
	p.y = global_position.y + 0.05
	_dust.global_position = p
	_dust.amount_ratio = ratio
	_dust.restart()


## Restarts the Breath emitter at the mouth, blowing where the head faces.
func _breath_burst() -> void:
	if _breath == null or _head_node == null or not is_inside_tree():
		return
	_breaths += 1
	var hx := _head_node.global_transform
	_breath.global_transform = Transform3D(hx.basis.orthonormalized() * Basis.from_scale(scale),
		hx * (GM.MOUTH - GM.HEAD_PIVOT))
	_breath.restart()


# ================================================================ death (1.0 s)

func _pose_death(dt: float) -> void:
	var prev: float = _death_t
	_death_t += dt
	var t: float = _death_t
	var jolt: float = _trk(t, D_JOLT)
	var kneel: float = smoothstep(0.08, 0.40, t)
	var top: float = _ease_in(clampf((t - 0.32) / 0.38, 0.0, 1.0))
	var sink: float = _ease_in(clampf((t - 0.8) / 0.2, 0.0, 1.0))
	# The front legs buckle (the body pitches forward and drops), then it rolls onto its left side.
	rot(P_ROOT, Vector3(8.0 * kneel * (1.0 - top) * DEG, 0, TOPPLE * top * DEG))
	pos(P_ROOT, Vector3(0.72 * top, lerpf(-0.34 * kneel, 0.4, top) - 0.6 * sink, 0.06 * kneel * (1.0 - top)))
	var kick: float = 0.0
	if t > 0.72:
		kick = sin((t - 0.72) * 28.0) * exp(-(t - 0.72) * 6.0)
	for i: int in [P_LEG_FL, P_LEG_FR]:
		_leg(i, 12.0 * kneel * (1.0 - top) + 20.0 * top, 80.0 * kneel * (1.0 - top) + 10.0 * top)
	_leg(P_LEG_BL, -6.0 * kneel * (1.0 - top) - 18.0 * top - 10.0 * kick, 18.0 * kneel * (1.0 - top) + 8.0 * top)
	_leg(P_LEG_BR, -6.0 * kneel * (1.0 - top) - 22.0 * top + 10.0 * kick, 18.0 * kneel * (1.0 - top) + 12.0 * top)
	for i: int in [P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		rot(i, Vector3(0, 0, (DEATH_LEG_LIFT + (6.0 if (i - P_LEG_FL) % 2 == 1 else 0.0)) * top * DEG))
	# A last roar (head up, jaw open), then the head droops onto the ground.
	rot(P_MOUNT_HEAD, Vector3((-22.0 * jolt + 10.0 * top) * DEG, 0, 14.0 * top * DEG))
	_jaw_req += 40.0 * jolt + 14.0 * top
	_flare = maxf(_flare, jolt)
	_fade = 1.0 - smoothstep(0.25, DEATH_GLOW_OFF, t)
	if prev < DEATH_GLOW_OFF and t >= DEATH_GLOW_OFF:
		_glows_dead()
	if prev < DEATH_LAND and t >= DEATH_LAND and _dust and is_inside_tree():
		_dusts += 1
		_dust.global_position = global_transform * Vector3(-0.7, 0.05, 0.0)
		_dust.amount_ratio = 0.8
		_dust.restart()
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
	if _face:
		_face.auto_any(self)
	if not _dead:
		_poll_t -= dt
		if _poll_t <= 0.0:
			_poll_t = ENRAGE_POLL
			_poll_enrage()
		_rage_w = move_toward(_rage_w, 1.0 if _enraged else 0.0, dt * 2.5)
		if _action == &"fidget":
			if _speed >= 0.3 or _action_t >= SNIFF_LEN:
				_action = &""
			else:
				_pose_fidget(_action_t)     # the kit advances _action_t and applies the offsets after this
		elif fidget_every > 0.0 and _action == &"" and _speed < 0.3 and _tier == 0 and not _enraged:
			_fidget_wait -= dt
			if _fidget_wait <= 0.0:
				_fidget_wait = _next_fidget()
				play_fidget()
		if _hit_t < HIT_LEN:
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_MOUNT_HEAD, Vector3(-12.0 * k, 7.0 * k, 0) * DEG)
			_jaw_req += 22.0 * k
			_flare = maxf(_flare, 0.3 * k)
		if _rage_w > 0.0 and _action == &"":
			_jaw_req += (9.0 + 3.0 * sin(_t * 19.0)) * _rage_w
	_write_parts(false)
	_write_glow(false)
	_flare = move_toward(_flare, 0.0, dt * 1.5)
	_jaw_req = 0.0
	_lower_req.fill(0.0)


## Reads the owning Unit's enrage modifier (CreatureAbilities `beast:enrage`), cheap: once per ENRAGE_POLL.
func _poll_enrage() -> void:
	if not _unit_looked:
		_unit_looked = true
		var p: Node = get_parent()
		for k: int in 3:
			if p == null:
				break
			if p.has_method(&"has_modifier"):
				_unit = p
				break
			p = p.get_parent()
	if _unit != null and is_instance_valid(_unit):
		set_enraged(bool(_unit.call(&"has_modifier", ENRAGE_MODIFIER)))


## Writes the Jaw / paw transforms (skipped when they barely changed).
func _write_parts(force: bool) -> void:
	if _jaw and (force or absf(_jaw_req - _jaw_w) > 0.3):
		_jaw_w = _jaw_req
		_jaw.transform = Transform3D(Basis(Vector3.RIGHT, clampf(_jaw_req, -5.0, 55.0) * DEG), _jaw_rest)
	for k: int in _lowers.size():
		var v: float = _lower_req[k]
		if force or absf(v - _lower_w[k]) > 0.3:
			_lower_w[k] = v
			_lowers[k].transform = Transform3D(Basis(Vector3.RIGHT, v * DEG), _lower_rest[k])


## Eyes: steady x glow_level (0 once dead) x the death fade, + the flares; brighter when enraged.
func _write_glow(force: bool) -> void:
	var g: float = glow_level() * _fade
	var eye: float = g * (1.0 + 1.2 * _flare) * (1.35 if _enraged else 1.0)
	if _head_gi and (force or absf(eye - _eye_w) > 0.03 or (eye == 0.0 and _eye_w != 0.0)):
		_eye_w = eye
		_head_gi.set_instance_shader_parameter(&"glow_boost", eye)


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


## Keyframe track [t, v, ease, ...] (see the constants).
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


## The eyes (faces pass 2026-09-28): glowing amber bear eyes (red and brighter when enraged, with a permanent scowl)
## under a heavy scowling brow ridge (the Elder's is white). Drawn inside the merged head (CreatureFaceRig host mode:
## no extra draw instance; the head's glow drive lights the irises: flares, enrage, the death fade).
static func face_spec(v: int, rage: bool) -> Dictionary:
	var out := Vector3(0.62, 0.22, 0.75).normalized()
	var iris := Color(1.0, 0.26, 0.14) if rage else Color(1.0, 0.70, 0.20)
	var o := {"eye": {"top": 0.030, "bot": 0.022, "ir": 0.020}, "brow": {"w": Vector3(0.012, 0.015, 0.006)},
		"palette": {"brow": Color(0.86, 0.84, 0.78) if v == 1 else Color(0.20, 0.12, 0.07), "lash": Color(0.08, 0.05, 0.03)}}
	if rage:
		o["x"] = {&"neutral": {"cut_in": 0.7, "brow": [-0.020, -0.008, 0.010], "brow_in_dx": -0.006}}
	return CreatureFaceRig.side_eye_spec(GM.EYE + out * 0.02, out, 0.046, Color(0.42, 0.26, 0.14), iris, 0.9, o)


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
