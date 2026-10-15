extends FlyerModel
## Frost Wyrm, the neutral epic beast over the river (titans-2.md 7 / 11 row 13c.V8; task 13c.V8). Both variants in
## one scene:
##   A Rimescale Wyrm: a long WINGLESS frost serpent (12.5 m spine), pale ice-blue scales with dark chevron bands over
##     the back, a pale belly, a dotted row of glowing frost spots along each flank, a ragged ice-feather DORSAL FIN from
##     the nape to the tail, a wide FRILLED FIN CREST (a collar of ice-feather rays) behind the head, two short clawed
##     forelegs, small pectoral fans (1.1 m, not wings) and a four-lobed ice-feather tail fluke with a glowing crystal;
##   B Old Hoarfang (`set_variant(1)`): the elder, x1.15, white-violet scales and fins, white-violet CRYSTAL HORNS on
##     the brow, violet glow, and frost motes drifting off the body (looping, < 45 m).
## Read at 40 m, next to the Frost Dragon (horns + compact body + two big wings): a long banded S-shaped SERPENT with a
## frill collar and no wings; coiled on the ground it is a round banded coil with the head raised at its front.
## Rig: flyer_model.gd (FlyerModel: the hooks, signals, flash / glow collection, bank measurement, distance tiers,
## ground blob) with Root > Body (chest) > Neck1 > Neck2 > Head > Jaw and Body > LegFL / LegFR; the wings and hind
## legs of the dragons are absent. The long body is ONE skinned mesh on a 25-bone Skeleton3D (Root/Spine, built in
## code) posed procedurally every frame: a spine of bone angles (heading psi, pitch theta per bone, integrated from the
## chest so the length never changes), rotated frames by parallel transport, the head placed on bone 0 with its own
## steady orientation. Nothing in flyer_model.gd / the dragons changed.
## Hooks (all safe before _ready): the FlyerModel kit set (set_moving, set_turning, play_attack = the Rime Breath with
## `breath_released` at 0.35 s, play_hit, play_death + death_finished + crashed(at), play_level_up, set_veterancy,
## set_carrying, play_mine, set_status, revive, get_breath_origin, set_team_color = no-op: neutral) +
##   set_variant(v: int) / get_variant() -> int
##   set_grounded(on: bool) / is_grounded() -> bool / grounded_ratio() -> float (0 airborne .. 1 coiled)
##   play_cast(&"glacial_dive" / &"tail_lash" / &"blizzard") (any other id: a roar; &"enrage" also turns the enrage
##     look on)
##   set_enraged(on) / is_enraged() (also set_status(&"enraged", on) and the owning Unit's `beast:enrage` modifier,
##     polled every 0.5 s): brighter eyes, faster writhing, jaw ajar
##   get_tail_tip() -> Vector3, get_head_point() -> Vector3 (world, for the VFX of 13c.V9)
##   signals dive_landed(at: Vector3) (the Glacial Dive hits the ground, 1.0 s after the cast), tail_struck(at: Vector3)
##     (the Tail Lash strike, 0.35 s), blizzard_released(at: Vector3) (the Blizzard roar, 0.75 s).
## Motion (procedural, one _process, no Tween / AnimationPlayer; FlyerModel distance tiers):
##  - airborne (default): the body flies fly_height (4 m) above the model origin (the unit's ground point) and SWIMS
##    through the air: a travelling S-wave from the neck to the tail (lazy in the hover, faster and flatter moving),
##    the neck raised and the tail hanging a little in the hover, the head steady and looking around, the body curving
##    into turns (bank), the pectoral fans rippling, the forelegs tucked;
##  - set_grounded(true) (0.8 s): it drops and COILS: about one turn of body on the ground around the model origin,
##    the chest raised at the front of the coil, forelegs planted, fans folded, the neck up and the head held LOW,
##    swaying; the tail tip twitches. set_grounded(false): takes off in 0.8 s (uncoils as it rises);
##  - play_attack (Rime Breath, 1.3 s): rears the neck back, strikes forward at 0.35 s with the jaw wide open, the head
##    sweeps the cone, the throat / eyes / spots flare;
##  - play_cast(&"glacial_dive") (1.5 s): climbs +1.3 m with the neck drawn back, then plunges head-first like a spear
##    (the body trailing up behind) and HITS THE GROUND at DIVE_IMPACT 1.0 s (`dive_landed`, ice burst), then snaps into
##    the coil in 0.45 s: the dive ENDS GROUNDED. Gameplay keeps it grounded with set_grounded(true) and releases it with
##    set_grounded(false); if gameplay never calls set_grounded after a dive, it takes off by itself after
##    DIVE_GROUND_FALLBACK (6 s, the spec's grounded time);
##  - play_cast(&"tail_lash") (0.9 s, strike 0.35 s): winds the tail back and whips it round in a wide arc, lifted off
##    the ground, alternating sides; the head snarls;
##  - play_cast(&"blizzard") (1.8 s): rears up high, throws the head back and ROARS at the sky (jaw wide, head shaking),
##    the whole body ripples, every glow flares, an ice burst at 0.75 s (`blizzard_released`);
##  - hit: kit flash + a jolt, a kink down the body, the head recoils;
##  - death (1.85 s < Unit.DEATH_FALLBACK_TIME): the head thrown back, the body writhes and it falls (from the air or
##    from the coil), crashes onto the ground in a loose curve (ice burst, `crashed`), the glow dies, then it sinks;
##    `death_finished` at the end.
## Budget (the TITAN budget, titans-2.md 11: <= 36 meshes, <= 20 draw instances, 0 lights, <= 2 particle systems
## stopped beyond 45 m): 7 authored meshes (skinned body, head, jaw, 2 legs, 2 fans) + the blob = 8; 10 draw instances
## with the 2 particle systems (Motes: B only, looping, < 45 m; Burst: one shot, dive / blizzard / crash). 9 own
## materials (materials/; 5 per variant: scale, fin, ice, eye + the shared claw) + the kit blob. Shadows: body, head.
## See tests/test_13c_v8.gd and tools/frost_wyrm_preview.tscn.

const WM := preload("res://art/units/neutral/beasts/frost_wyrm/frost_wyrm_mesh.gd")
const N := 25
const CI := 5
const DS := WM.LEN / 24.0
const B_SCALE := 1.15
const GROUND_LEN := 0.8
const DIVE_IMPACT := 1.0
const DIVE_LEN := 1.5
const DIVE_SETTLE := 0.45
const DIVE_GROUND_FALLBACK := 6.0
const LASH_LEN := 0.9
const LASH_STRIKE := 0.35
## The Tail Lash whips the tail from this bone on.
const LASH_ROOT := 13
const BLIZ_LEN := 1.8
const BLIZ_RELEASE := 0.75
const ROAR_LEN := 1.1
const W_DEATH_LEN := 1.85
const W_CRASH_AIR := 0.95
const W_CRASH_GROUND := 0.55
const CORPSE_Y := 0.44
const CAST_IDS: Array[StringName] = [&"glacial_dive", &"tail_lash", &"blizzard"]
const MAT_A: Array[String] = ["scale_a", "fin_a", "ice_a", "eye_a"]
const MAT_B: Array[String] = ["scale_b", "fin_b", "ice_b", "eye_b"]
const ENRAGE_MODIFIER := &"beast:enrage"
const ENRAGE_POLL := 0.5
const BLOB_AIR := Vector2(3.0, 7.5)
const BLOB_GROUND := Vector2(5.6, 5.6)
## Wave numbers of the lateral / vertical body waves (rad per m).
const K_LAT := TAU / 7.0
const K_VERT := TAU / 7.5
## The chest's heading in the coil (the neck turns back to face +Z) and its height.
const COIL_PSI_C := 80.0 * PI / 180.0
const CHEST_Y_G := 0.62
## xz of the coil centroid (bones chest -> tail), unscaled.
const COIL_CENTRE := Vector2(-0.2, -0.45)
const AIR_CHEST_Z := 1.0
## How much of the neck raise each neck bone (0 = head joint .. 4) takes.
const NECK_W: Array[float] = [1.0, 1.0, 0.85, 0.6, 0.3]

## The Glacial Dive hits the ground (world point under the head).
signal dive_landed(at: Vector3)
## The Tail Lash strike (world point near the tail end).
signal tail_struck(at: Vector3)
## The Blizzard roar releases (world point at the head).
signal blizzard_released(at: Vector3)

## 0 = Rimescale Wyrm, 1 = Old Hoarfang (x1.15, white-violet, crystal horns, frost motes). Use set_variant().
@export_range(0, 1) var variant: int = 0:
	set(v):
		variant = clampi(v, 0, 1)
		if _ready_done:
			_apply_variant()

static var _coil_psi := PackedFloat32Array()
static var _coil_th := PackedFloat32Array()
static var _coil_anchor := Vector3.ZERO
## Lowest body-centre height of each bone (its belly radius): nothing goes under the ground.
static var _rz := PackedFloat32Array()

var _skel: Skeleton3D
var _body_mi: MeshInstance3D
var _head_mi: MeshInstance3D
var _parts: Array[MeshInstance3D] = []
var _fin_l: Node3D
var _fin_r: Node3D
var _fin_rest: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _motes: GPUParticles3D
var _burst: GPUParticles3D
var _authored: int = 0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig

# ---- pose buffers (reused every frame)
var _psi := PackedFloat32Array()
var _th := PackedFloat32Array()
var _psi_a := PackedFloat32Array()
var _th_a := PackedFloat32Array()
var _pts := PackedVector3Array()
var _bas: Array[Basis] = []
var _anchor := Vector3.ZERO
var _roll: float = 0.0
var _head_yaw: float = 0.0
var _head_pitch: float = 0.0
var _head_roll: float = 0.0
var _jaw: float = 0.0
var _leg_x: float = 0.0
var _leg_z: float = 0.0
var _fin_sweep: float = 0.0
var _fin_droop: float = 0.0
var _amp_mult: float = 1.0

# ---- state
var _g: float = 0.0                    # 0 airborne .. 1 coiled
var _grounded: bool = false
var _g_explicit: bool = false          # set_grounded(true) came from gameplay (not only the dive)
var _dive_ground_t: float = 0.0
var _wave_ph: float = 0.0
var _vwave_ph: float = 0.0
var _cast_id: StringName = &""
var _lash_side: float = 1.0
var _enraged: bool = false
var _poll_t: float = 0.0
var _unit: Node
var _unit_looked: bool = false
var _death_g: float = 0.0
var _death_y: float = 4.0
var _death_crash: float = W_CRASH_AIR
var _dives: int = 0
var _lashes: int = 0
var _blizzards: int = 0
var _breaths: int = 0
var _bursts: int = 0
## G-D signature emitter (High / Ultra only; null otherwise): frost motes shed along the body.
var _sig: GPUParticles3D


# ================================================================ public (gameplay, tests, preview)

func set_variant(v: int) -> void:
	variant = v


func get_variant() -> int:
	return variant


## Airborne (false, default) or coiled on the ground (true). 0.8 s blend; safe before _ready (applied at once then).
func set_grounded(on: bool) -> void:
	_g_explicit = on
	_dive_ground_t = 0.0
	if not _ready_done:
		_grounded = on
		_g = 1.0 if on else 0.0
		return
	_grounded = on


func is_grounded() -> bool:
	return _grounded


## 0 = airborne .. 1 = fully coiled (the 0.8 s blend in between).
func grounded_ratio() -> float:
	return _g


## Neutral beast: no team colour.
func set_team_color(_c: Color) -> void:
	pass


## `glacial_dive`, `tail_lash`, `blizzard`; any other id plays a roar (`enrage` also turns the enrage look on).
func play_cast(spell_id: StringName) -> void:
	if _dead:
		return
	if spell_id == &"enrage":
		set_enraged(true)
	_cast_id = spell_id if spell_id in CAST_IDS else &"roar"
	_action = &"cast"
	_action_t = 0.0
	if _cast_id == &"tail_lash":
		_lash_side = -_lash_side
	_on_action_event(&"cast_start")


func play_death() -> void:
	if _dead:
		return
	_death_g = _g
	_death_y = _anchor.y
	_death_crash = lerpf(W_CRASH_AIR, W_CRASH_GROUND, _g)
	super.play_death()


## The enrage look (below 30 % HP): brighter eyes and spots, faster writhing, the jaw ajar. It also follows the owning
## Unit's `beast:enrage` modifier by itself (polled every 0.5 s).
func set_enraged(on: bool) -> void:
	_enraged = on
	_apply_glow(true)


func is_enraged() -> bool:
	return _enraged


## frozen -> the body stops writhing (false: the ice look stays the VFX's); haste -> brighter (true);
## enraged -> the enrage look (true).
func set_status(id: StringName, on: bool) -> bool:
	if id == &"enraged" or id == &"enrage":
		set_enraged(on)
		return true
	return super.set_status(id, on)


func glow_level() -> float:
	return super.glow_level() * (1.35 if _enraged else 1.0)


## World position of the tail tip (bone 24).
func get_tail_tip() -> Vector3:
	return _world(_pts[N - 1]) if _pts.size() == N else global_position


## World position of the head joint (bone 0).
func get_head_point() -> Vector3:
	return _world(_pts[0]) if _pts.size() == N else global_position + Vector3.UP * fly_height


## Authored MeshInstance3D count (parts + the blob), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Bone positions in MODEL space (the node's local space, variant scale applied), for tests and the VFX.
func spine_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	var sc := _scale()
	for p: Vector3 in _pts:
		out.append(p * sc)
	return out


func dive_count() -> int:
	return _dives


func lash_count() -> int:
	return _lashes


func blizzard_count() -> int:
	return _blizzards


func breath_count() -> int:
	return _breaths


func burst_count() -> int:
	return _bursts


# ================================================================ build

func _build_parts() -> void:
	_authored = 0
	_parts.clear()
	_psi.resize(N)
	_th.resize(N)
	_psi_a.resize(N)
	_th_a.resize(N)
	_pts.resize(N)
	_bas.resize(N)
	for i: int in N:
		_pts[i] = WM.bone_rest(i)
		_bas[i] = Basis.IDENTITY
	_build_coil()
	# the skinned body on its skeleton (Root space = skeleton space)
	_skel = Skeleton3D.new()
	_skel.name = "Spine"
	for i: int in N:
		_skel.add_bone("b%02d" % i)
		_skel.set_bone_rest(i, Transform3D(Basis(), WM.bone_rest(i)))
	_piv[P_ROOT].add_child(_skel)
	_body_mi = MeshInstance3D.new()
	_body_mi.name = "BodyMesh"
	_body_mi.mesh = WM.body_mesh()
	_body_mi.skin = WM.skin()
	_body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_body_mi.custom_aabb = AABB(Vector3(-9.0, -1.5, -10.0), Vector3(18.0, 11.0, 20.0))
	_skel.add_child(_body_mi)
	_body_mi.skeleton = NodePath("..")
	_authored += 1
	_parts.append(_body_mi)
	_head_mi = _add(P_HEAD, WM.head_mesh(0), true, "HeadMesh")
	_face = CreatureFaceRig.attach(self, _piv[P_HEAD], "frost_wyrm", face_spec())
	_add(P_JAW, WM.jaw_mesh(), false, "JawMesh")
	_add(P_LEG_FL, WM.leg_mesh(-1.0), false, "LegFLMesh")
	_add(P_LEG_FR, WM.leg_mesh(1.0), false, "LegFRMesh")
	# pectoral fans on their own pivots under the chest
	var body := _piv[P_BODY]
	for side: int in 2:
		var sx := -1.0 if side == 0 else 1.0
		var fp := Node3D.new()
		fp.name = "FinL" if side == 0 else "FinR"
		var fr := Vector3(WM.FIN_ROOT.x * sx, WM.FIN_ROOT.y, WM.FIN_ROOT.z)
		fp.position = fr - model_origin(body)
		_fin_rest[side] = fp.position
		body.add_child(fp)
		var mi := MeshInstance3D.new()
		mi.name = "FinLMesh" if side == 0 else "FinRMesh"
		mi.mesh = WM.fin_mesh(sx)
		mi.position = -fr
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fp.add_child(mi)
		_authored += 1
		_parts.append(mi)
		if side == 0:
			_fin_l = fp
		else:
			_fin_r = fp
	var mouth := Node3D.new()
	mouth.name = "Mouth"
	add_pivot_node(P_HEAD, mouth, WM.MOUTH)
	_mouth = mouth
	# Old Hoarfang's frost motes (world space: they trail behind in flight; B only, stopped beyond 45 m) and the
	# one-shot ice burst (dive impact, blizzard roar, crash), both moved to where they play.
	_motes = CharacterModel.make_motes(Color(0.88, 0.8, 1.0), 18, 1.8, 1.9, 0.3, 0.17)
	_motes.name = "Motes"
	_motes.visibility_aabb = AABB(Vector3(-5.0, -3.0, -5.0), Vector3(10.0, 7.0, 10.0))
	_piv[P_ROOT].add_child(_motes)
	_burst = CharacterModel.make_motes(Color(0.85, 0.96, 1.0), 34, 1.1, 1.2, 3.4, 0.28, false, true)
	_burst.name = "Burst"
	_burst.visibility_aabb = AABB(Vector3(-5.0, -3.0, -5.0), Vector3(10.0, 8.0, 10.0))
	_piv[P_ROOT].add_child(_burst)
	ensure_shadow_blob(BLOB_AIR, Color(0.03, 0.05, 0.08, 0.42))
	_authored += 1


func _add(i: int, mesh: Mesh, shadow: bool, nm: String) -> MeshInstance3D:
	var mi := add_pivot_mesh(i, mesh, shadow, nm)
	if mi:
		_authored += 1
		_parts.append(mi)
	return mi


func _after_ready() -> void:
	_sig = CreatureSignature.attach(self, _piv[P_BODY], Vector3.ZERO, &"frost_motes", 2.4)
	_apply_variant()


## G-D signature gate (CreatureSignature, High / Ultra only): near tier and alive (the gate adds the on-screen test).
func signature_should_emit() -> bool:
	return _tier == 0 and not _dead


## B: the crystal-horned head (mesh swap on the same instance), every A surface overridden by its B twin (shared .tres,
## no runtime material), x1.15, taller HP bar, frost motes. A: back.
func _apply_variant() -> void:
	if _head_mi:
		_head_mi.mesh = WM.head_mesh(variant)
	var a: Array[Material] = []
	var b: Array[Material] = []
	for k: int in MAT_A.size():
		a.append(WM.mat(MAT_A[k]))
		b.append(WM.mat(MAT_B[k]))
	for mi: MeshInstance3D in _parts:
		for s: int in mi.get_surface_override_material_count():
			mi.set_surface_override_material(s, null)
		for s: int in mi.mesh.get_surface_count():
			var k := a.find(mi.mesh.surface_get_material(s))
			mi.set_surface_override_material(s, b[k] if variant == 1 and k >= 0 else null)
	body_height = 6.0 * _scale()
	_piv[P_ROOT].scale = Vector3.ONE * _scale()
	_update_motes()


func _scale() -> float:
	return B_SCALE if variant == 1 else 1.0


func _update_motes() -> void:
	if _motes:
		_motes.visible = variant == 1
		set_fx_emitting(_motes, variant == 1 and _tier == 0 and not _dead)


func _update_tier() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var nt: int = 1
	if cam:
		nt = 0 if cam.global_position.distance_to(global_position) < 45.0 else 1
	if nt != _tier:
		_tier = nt
		_update_motes()


func _on_revive() -> void:
	if _face:
		_face.reset()
	_g = 1.0 if _grounded else 0.0
	_action = &""
	_cast_id = &""
	_update_motes()


func _on_action_event(ev: StringName) -> void:
	if ev == &"crash":
		_update_motes()


## The static coil (angles of every bone when grounded) and the chest anchor that centres it: computed once per game.
static func _build_coil() -> void:
	if not _coil_psi.is_empty():
		return
	_coil_psi.resize(N)
	_coil_th.resize(N)
	_rz.resize(N)
	for i: int in N:
		_rz[i] = WM.radius_at(float(i) * DS).z * 0.95
	var neck_th: Array[float] = [-8.0, -24.0, -40.0, -48.0, -44.0]
	for i: int in CI:
		var u := float(i) / float(CI)
		_coil_psi[i] = COIL_PSI_C * pow(u, 1.4)
		_coil_th[i] = neck_th[i] * DEG
	_coil_psi[CI] = COIL_PSI_C
	_coil_th[CI] = -24.0 * DEG
	var desc: Array[float] = [-12.0, -6.0, -2.0]
	for i: int in range(CI + 1, N):
		var s := (float(i) - 0.5) * DS
		var r := lerpf(1.95, 0.8, clampf((s - WM.CHEST_S) / (WM.LEN - WM.CHEST_S), 0.0, 1.0))
		_coil_psi[i] = _coil_psi[i - 1] - DS / r
		var k := i - CI - 1
		_coil_th[i] = (desc[k] if k < desc.size() else 0.0) * DEG
	var pts := PackedVector3Array()
	pts.resize(N)
	_integrate(Vector3(0.0, CHEST_Y_G, 0.0), _coil_psi, _coil_th, pts)
	var c := Vector2.ZERO
	for i: int in range(CI, N):
		c += Vector2(pts[i].x, pts[i].z)
	c /= float(N - CI)
	_coil_anchor = Vector3(COIL_CENTRE.x - c.x, CHEST_Y_G, COIL_CENTRE.y - c.y)


static func _fwd(psi: float, th: float) -> Vector3:
	var c := cos(th)
	return Vector3(sin(psi) * c, -sin(th), cos(psi) * c)


## Bone positions from the chest anchor and the bone angles (segment direction = mean of its two bones): every
## segment keeps its length DS.
static func _integrate(anchor: Vector3, psi: PackedFloat32Array, th: PackedFloat32Array, out: PackedVector3Array) -> void:
	out[CI] = anchor
	for i: int in range(CI + 1, N):
		out[i] = out[i - 1] - _fwd((psi[i - 1] + psi[i]) * 0.5, (th[i - 1] + th[i]) * 0.5) * DS
	for i: int in range(CI - 1, -1, -1):
		out[i] = out[i + 1] + _fwd((psi[i] + psi[i + 1]) * 0.5, (th[i] + th[i + 1]) * 0.5) * DS


# ================================================================ per frame

func _animate(dt: float) -> void:
	_update_turn(dt)
	_flare = 0.0
	_amp_mult = 1.0
	if _dead:
		_death_t += dt
		_compose_base(dt, true)
		_pose_wyrm_death()
	else:
		_update_ground(dt)
		_compose_base(dt, false)
		_pose_actions(dt)
		if _hit_t < HIT_LEN:
			_hit_t += dt
			_pose_wyrm_hit(_hit_t)
	_solve()
	_update_flash(dt)
	_extra_process(dt)
	_apply()
	_apply_glow(false)


func _update_ground(dt: float) -> void:
	var diving := _action == &"cast" and _cast_id == &"glacial_dive"
	var target := 1.0 if _grounded else 0.0
	var rate := dt / GROUND_LEN
	if diving:
		if _action_t < DIVE_IMPACT:
			target = 0.0
		else:
			rate = dt / DIVE_SETTLE
	_g = move_toward(_g, target, rate)
	if _grounded and not _g_explicit:
		_dive_ground_t += dt
		if _dive_ground_t >= DIVE_GROUND_FALLBACK:
			_grounded = false


## The base pose: the air swim blended with the coil by the grounded weight; head, jaw, legs, fans.
func _compose_base(dt: float, dead: bool) -> void:
	var gw := _g * _g * (3.0 - 2.0 * _g)
	if dead:
		gw = _death_g * _death_g * (3.0 - 2.0 * _death_g)
	var moving := _speed >= 0.3 and _g < 0.5 and not dead
	_move_w = move_toward(_move_w, 1.0 if moving else 0.0, dt / 0.8)
	var mw := _move_w * _move_w * (3.0 - 2.0 * _move_w)
	var hw := 1.0 - mw
	var sc := _scale()
	# --- wave phases (frozen: the body stops; dead: a fast writhe)
	var period := lerpf(3.4, 1.8, mw) * (0.8 if _enraged else 1.0)
	var speed_k := 2.6 if dead else 1.0
	if not _frozen_status:
		_wave_ph = fmod(_wave_ph + dt * TAU / period * speed_k, TAU * 64.0)
		_vwave_ph = fmod(_vwave_ph + dt * TAU / (period * 1.37) * speed_k, TAU * 64.0)
	# --- airborne: the swim
	var raise := lerpf(26.0, 10.0, mw) * DEG
	var sag := lerpf(16.0, 4.0, mw) * DEG
	var av := lerpf(0.16, 0.07, mw)
	var ak := lerpf(1.0, 0.8, mw)
	for i: int in N:
		var s := float(i) * DS
		var u := s / WM.LEN
		# lateral displacement x(s) = A(s) sin(k s - phase) travelling tailward; the heading follows its slope
		var am := _wave_amp(s) * ak
		var da := (_wave_amp(s + 0.05) - _wave_amp(s - 0.05)) * 10.0 * ak
		var ph := K_LAT * s - _wave_ph
		_psi_a[i] = -atan(am * K_LAT * cos(ph) + da * sin(ph)) + _bank * 0.55 * (1.0 - u)
		var th := av * sin(K_VERT * s - _vwave_ph)
		if i < CI:
			th -= raise * NECK_W[i]
		elif i == CI:
			th -= lerpf(6.0, 0.0, mw) * DEG
		th -= sag * smoothstep(0.45, 1.0, u)
		_th_a[i] = th
	# --- coiled: the static coil + idle life (neck sway, breathing, tail twitch)
	var sway := 0.12 * sin(_t * 0.6 + _phase_off * 4.0)
	var breathe := 0.035 * sin(_t * 1.15)
	for i: int in N:
		var pg := _coil_psi[i]
		var tg := _coil_th[i]
		if i < CI:
			pg += sway * NECK_W[i]
			tg += breathe * NECK_W[i]
		elif i >= N - 5:
			pg += 0.22 * sin(_t * 1.9 + float(i) * 0.7) * float(i - (N - 6)) / 5.0
		_psi[i] = lerpf(_psi_a[i], pg, gw)
		_th[i] = lerpf(_th_a[i], tg, gw)
	var bob := (0.14 * sin(_t * 1.4 + _phase_off * 6.0) * hw + 0.05 * sin(_wave_ph)) * (1.0 - gw)
	var a_air := Vector3(0.0, fly_height / sc + bob, AIR_CHEST_Z)
	_anchor = a_air.lerp(_coil_anchor, gw)
	_roll = -bank_max_deg * DEG * _bank * (1.0 - gw)
	# --- head: steady (absolute), looking around in the hover, low and swaying on the ground
	var look_y := hw * (14.0 * sin(_t * 0.37 + _phase_off * 4.0) + 6.0 * sin(_t * 0.91 + 1.3))
	var look_x := hw * 4.0 * sin(_t * 0.53 + 0.7)
	var ya := 0.3 * (_psi[0]) + (look_y + 10.0 * _bank) * DEG
	var yg := (10.0 * sin(_t * 0.5 + _phase_off * 3.0)) * DEG
	_head_yaw = lerpf(ya, yg, gw)
	_head_pitch = lerpf((4.0 + look_x) * DEG, (16.0 + 3.0 * sin(_t * 1.1)) * DEG, gw)
	_head_roll = -0.4 * _roll
	_jaw = (2.0 + 2.0 * sin(_t * 1.7 + _phase_off)) * DEG
	if _enraged:
		_jaw += (9.0 + 3.0 * sin(_t * 19.0)) * DEG
	# --- forelegs tucked back in the air, planted in the coil; fans spread and rippling / folded back
	var paddle := 5.0 * sin(_wave_ph * 2.0) * (1.0 - gw)
	_leg_x = lerpf(78.0 + paddle, -24.0, gw) * DEG
	_leg_z = lerpf(8.0, 6.0, gw) * DEG
	var ripple := 8.0 * sin(_wave_ph * 1.5 + 0.7)
	_fin_sweep = lerpf(4.0 * sin(_wave_ph * 1.5), 52.0, gw) * DEG
	_fin_droop = lerpf(-8.0 + ripple * (0.6 + 0.4 * hw), -24.0, gw) * DEG


## Lateral amplitude (m) of the airborne swim at spine length s: a small sway at the neck, wide at the tail.
static func _wave_amp(s: float) -> float:
	return lerpf(0.22, 1.05, smoothstep(0.05, 1.0, clampf(s, 0.0, WM.LEN) / WM.LEN))


## Offsets of the playing action (breath, casts).
func _pose_actions(dt: float) -> void:
	if _action == &"attack":
		var prev := _action_t
		_action_t += dt
		_pose_breath_w(prev, _action_t)
		if _action_t >= BREATH_LEN:
			_action = &""
			_on_action_event(&"attack_end")
	elif _action == &"cast":
		var prev := _action_t
		_action_t += dt
		var ln := _pose_cast(prev, _action_t)
		if _action_t >= ln:
			_action = &""
			_on_action_event(&"cast_end")


## Rime Breath: rear the neck back (0 .. 0.3), strike forward (release 0.35: jaw wide), sweep, recover by 1.3 s.
func _pose_breath_w(prev: float, t: float) -> void:
	var ts: Array = [0.0, 0.30, 0.40, 0.95, 1.30]
	var neck := _kf(t, ts, [0.0, -16.0, 10.0, 8.0, 0.0]) * DEG
	for i: int in CI:
		_th[i] += neck * NECK_W[i]
	for i: int in range(CI, CI + 3):
		_th[i] += _kf(t, ts, [0.0, -6.0, 4.0, 3.0, 0.0]) * DEG
	var sweep := 0.0
	if t > 0.38 and t < 0.98:
		sweep = 13.0 * sin((t - 0.38) / 0.6 * TAU) * sin(PI * (t - 0.38) / 0.6)
	_head_pitch += _kf(t, ts, [0.0, -20.0, 12.0, 8.0, 0.0]) * DEG
	_head_yaw += sweep * DEG
	_jaw = maxf(_jaw, _kf(t, [0.0, 0.28, 0.35, 0.42, 0.95, 1.12], [0.0, 10.0, 12.0, 42.0, 38.0, 0.0]) * DEG)
	_anchor += Vector3(0.0, _kf(t, ts, [0.0, 0.18, -0.05, 0.0, 0.0]), _kf(t, ts, [0.0, -0.25, 0.22, 0.12, 0.0]))
	_flare = maxf(_flare, _kf(t, ts, [0.0, 0.9, 1.7, 1.3, 0.0]))
	if prev < BREATH_RELEASE and t >= BREATH_RELEASE:
		_breaths += 1
		breath_released.emit()
		_on_action_event(&"release")


## Returns the cast length.
func _pose_cast(prev: float, t: float) -> float:
	match _cast_id:
		&"glacial_dive":
			_pose_dive(prev, t)
			return DIVE_LEN
		&"tail_lash":
			_pose_lash(prev, t)
			return LASH_LEN
		&"blizzard":
			_pose_roar(prev, t, true)
			return BLIZ_LEN
	_pose_roar(prev, t, false)
	return ROAR_LEN


## Glacial Dive: climb with the neck drawn back, plunge head-first (the body trailing up behind like a spear), hit the
## ground at DIVE_IMPACT (dive_landed, ice burst, grounded), then snap into the coil.
func _pose_dive(prev: float, t: float) -> void:
	var fly := fly_height / _scale()
	var e := 1.0 - smoothstep(DIVE_IMPACT, DIVE_IMPACT + DIVE_SETTLE, t)
	var dk: Array = [0.0, 0.3, 0.6, 0.88, 1.0]
	var neck := _kf(t, dk, [0.0, -30.0, 30.0, 42.0, 20.0]) * DEG * e
	var body := _kf(t, dk, [0.0, -14.0, 22.0, 36.0, 22.0]) * DEG * e
	for i: int in CI:
		_th[i] += neck * NECK_W[i]
	for i: int in range(CI, N):
		var u := float(i - CI) / float(N - 1 - CI)
		_th[i] += body * (1.0 - 0.45 * u)
		# the body straightens like a spear in the plunge
		_psi[i] = lerpf(_psi[i], 0.0, 0.6 * smoothstep(0.3, 0.7, t) * e * (1.0 - _g))
	_head_pitch += _kf(t, dk, [0.0, -25.0, 20.0, 38.0, 10.0]) * DEG * e
	_jaw = maxf(_jaw, _kf(t, [0.0, 0.3, 0.55, 0.9, 1.0], [0.0, 14.0, 40.0, 44.0, 6.0]) * DEG * e)
	if t < DIVE_IMPACT:
		_anchor.y = _kf(t, dk, [fly, fly + 1.3, fly - 0.5, 1.5, CHEST_Y_G])
		_anchor.z += _kf(t, [0.0, 0.3, 0.8, 1.0], [0.0, -0.45, 0.9, 0.6])
	else:
		_anchor.y = _coil_anchor.y
		_anchor.z += 0.6 * e
	_flare = maxf(_flare, _kf(t, [0.0, 0.3, 0.7, 1.0, 1.5], [0.0, 0.6, 1.5, 1.8, 0.0]))
	if prev < DIVE_IMPACT and t >= DIVE_IMPACT:
		_dives += 1
		_grounded = true
		_dive_ground_t = 0.0
		var hp := get_head_point()
		var at := Vector3(hp.x, global_position.y, hp.z) if is_inside_tree() else Vector3.ZERO
		_burst_at(_pts[0], 1.0)
		dive_landed.emit(at)
		_on_action_event(&"impact")


## Tail Lash: the tail winds back, whips round in a wide arc (lifted) at LASH_STRIKE, recovers; alternating sides.
func _pose_lash(prev: float, t: float) -> void:
	var side := _lash_side
	# the tail end (from bone LASH_ROOT on) uncurls into a straight whip and swings round: windup back, strike across
	var amp := _kf(t, [0.0, 0.22, 0.42, 0.62, 0.9], [0.0, -40.0, 75.0, 30.0, 0.0]) * side * DEG
	var uncurl := _kf(t, [0.0, 0.18, 0.42, 0.65, 0.9], [0.0, 0.75, 0.9, 0.5, 0.0])
	var lift := _kf(t, [0.0, 0.2, 0.4, 0.9], [0.0, 16.0, 8.0, 0.0]) * DEG
	var base_psi := _psi[LASH_ROOT]
	for i: int in range(LASH_ROOT + 1, N):
		var w := smoothstep(float(LASH_ROOT), float(LASH_ROOT) + 3.0, float(i))
		_psi[i] = lerpf(_psi[i], base_psi, uncurl * w) + amp * w
		_th[i] += lift * w
	for i: int in range(CI, LASH_ROOT):
		_psi[i] -= amp * 0.1
	_head_yaw += amp * 0.25
	_jaw = maxf(_jaw, _kf(t, [0.0, 0.15, 0.35, 0.6, 0.9], [0.0, 18.0, 28.0, 12.0, 0.0]) * DEG)
	_flare = maxf(_flare, _kf(t, [0.0, 0.3, 0.45, 0.9], [0.0, 0.5, 0.7, 0.0]))
	if prev < LASH_STRIKE and t >= LASH_STRIKE:
		_lashes += 1
		tail_struck.emit(_world(_pts[N - 4]))
		_on_action_event(&"lash")


## Blizzard (true) / roar (false): rear up, head back to the sky, roar with the head shaking, the body ripples.
func _pose_roar(prev: float, t: float, bliz: bool) -> void:
	var k := 1.0 if bliz else 0.6
	var tt := t if bliz else t * BLIZ_LEN / ROAR_LEN
	var rise := _kf(tt, [0.0, 0.5, 1.25, 1.8], [0.0, 2.1, 1.8, 0.0]) * k
	_anchor.y += rise * lerpf(1.0, 0.7, _g)
	var neck := _kf(tt, [0.0, 0.5, 1.3, 1.8], [0.0, -52.0, -46.0, 0.0]) * DEG * k
	for i: int in CI:
		_th[i] += neck * NECK_W[i]
	for i: int in range(CI, CI + 4):
		_th[i] += neck * (0.7 - 0.15 * float(i - CI))
	_head_pitch += _kf(tt, [0.0, 0.45, 0.7, 1.3, 1.8], [0.0, -38.0, -46.0, -30.0, 0.0]) * DEG * k
	var roar := smoothstep(0.55, 0.7, tt) * (1.0 - smoothstep(1.25, 1.45, tt))
	_head_yaw += 8.0 * sin(t * 34.0) * roar * DEG
	_jaw = maxf(_jaw, _kf(tt, [0.0, 0.4, 0.6, 1.35, 1.6], [0.0, 20.0, 46.0, 44.0, 0.0]) * DEG)
	var ripple := sin(PI * clampf(tt / 1.8, 0.0, 1.0)) * k
	for i: int in range(CI + 1, N):
		var s := float(i) * DS
		_psi[i] += 0.3 * ripple * sin(K_LAT * 1.4 * s - t * 9.0) * (1.0 - 0.8 * _g)
	_flare = maxf(_flare, _kf(tt, [0.0, 0.5, 0.75, 1.3, 1.8], [0.0, 1.0, 2.2, 1.4, 0.0]) * k)
	if bliz and prev < BLIZ_RELEASE and t >= BLIZ_RELEASE:
		_blizzards += 1
		_burst_at(_pts[0], 1.0)
		blizzard_released.emit(get_head_point())
		_on_action_event(&"blizzard")


## A jolt back and up, a kink down the body, the head recoils (the kit flash comes from FlyerModel).
func _pose_wyrm_hit(t: float) -> void:
	var k: float = clampf(t / 0.06, 0.0, 1.0) if t < 0.06 else clampf(1.0 - (t - 0.06) / (HIT_LEN - 0.06), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	_anchor += Vector3(0.0, 0.1 * k, -0.18 * k)
	for i: int in CI:
		_th[i] -= 8.0 * DEG * k * NECK_W[i]
	for i: int in range(CI, N):
		_psi[i] += 0.12 * k * sin(float(i) * 0.6)
	_head_pitch -= 12.0 * DEG * k
	_jaw = maxf(_jaw, 16.0 * DEG * k)


## Death: throe (head thrown back, a violent writhe), the fall to the ground (from the air or the coil), the crash in a
## loose curve (squash, burst, crashed), the glow out, the sink; death_finished at W_DEATH_LEN.
func _pose_wyrm_death() -> void:
	var t := _death_t
	var crash := _death_crash
	var throe := _ease_out(clampf(t / 0.25, 0.0, 1.0)) * (1.0 - clampf((t - 0.3) / 0.35, 0.0, 1.0))
	var f := clampf((t - 0.15) / (crash - 0.15), 0.0, 1.0)
	var fall := f * f
	var land_k := _ease_out(clampf((t - crash) / 0.2, 0.0, 1.0))
	var sd := _spiral_dir
	var flat := maxf(fall * 0.55, land_k)
	for i: int in N:
		var s := float(i) * DS
		var dead_psi := sd * 0.5 * sin(K_LAT * 0.8 * s + 1.0) * smoothstep(0.0, 3.0, s)
		var writhe := 0.35 * throe * sin(K_LAT * 1.3 * s - t * 14.0) * (1.0 - land_k)
		var loose := lerpf(1.0, 0.45, land_k * _death_g)
		_psi[i] = lerpf(_psi[i] * loose + writhe, lerpf(_psi[i], dead_psi, 0.6), flat * (1.0 - _death_g * 0.5))
		_th[i] = lerpf(_th[i], 0.0, flat)
	for i: int in CI:
		_th[i] += (-36.0 * throe + 14.0 * land_k) * DEG * NECK_W[i]
	var y0 := _death_y
	var y := lerpf(y0 + 0.3 * throe, CORPSE_Y, fall)
	if t >= crash:
		var ti := t - crash
		y = CORPSE_Y + 0.14 * maxf(0.0, sin(clampf(ti / 0.2, 0.0, 1.0) * PI)) * exp(-ti * 3.0)
		if not _crash_emitted:
			_crash_emitted = true
			_burst_at(_pts[CI], 1.0)
			crashed.emit(_world(Vector3(_pts[CI].x, 0.1, _pts[CI].z)))
			_on_action_event(&"crash")
	_anchor.y = y
	_head_pitch = lerpf(_head_pitch - 30.0 * DEG * throe, 20.0 * DEG, land_k)
	_head_yaw += sd * 28.0 * DEG * land_k
	_head_roll = sd * 24.0 * DEG * land_k
	_jaw = (38.0 * throe + 12.0 * fall * (1.0 - land_k) + 18.0 * land_k) * DEG
	_leg_x = lerpf(_leg_x, 40.0 * DEG, land_k)
	_fin_sweep = lerpf(_fin_sweep, 30.0 * DEG, land_k)
	_fin_droop = lerpf(_fin_droop, -30.0 * DEG, land_k)
	_flare = 1.2 * throe
	_cool = 1.0 - smoothstep(crash + 0.05, crash + 0.5, t)
	if _shadow:
		_shadow.transparency = clampf((t - 1.4) / 0.3, 0.0, 1.0)
	if t >= W_DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


## Positions (integration from the chest), the air centring, the ground clamp, the death sink, then the bone frames
## (parallel transport from the chest) and the head basis.
func _solve() -> void:
	_integrate(_anchor, _psi, _th, _pts)
	var gw := _death_g if _dead else _g
	var air := 1.0 - gw * gw * (3.0 - 2.0 * gw)
	if air > 0.0:
		var mx := 0.0
		for p: Vector3 in _pts:
			mx += p.x
		mx = mx / float(N) * air
		for i: int in N:
			_pts[i] = _pts[i] - Vector3(mx, 0.0, 0.0)
	var sink := 0.0
	if _dead:
		sink = 1.2 * _ease_in(clampf((_death_t - 1.3) / (W_DEATH_LEN - 1.3), 0.0, 1.0))
	for i: int in N:
		var p := _pts[i]
		p.y = maxf(p.y, _rz[i]) - sink
		_pts[i] = p
	# frames: the chest from its tangent (+ the bank roll), the rest by parallel transport outward
	var tc := _tangent(CI)
	var x := Vector3.UP.cross(tc)
	if x.length_squared() < 1e-6:
		x = Vector3.RIGHT
	x = x.normalized()
	_bas[CI] = Basis(x, tc.cross(x).normalized(), tc) * Basis(Vector3.BACK, _roll)
	var prev_t := tc
	for i: int in range(CI + 1, N):
		var t := _tangent(i)
		_bas[i] = (Basis(Quaternion(prev_t, t)) * _bas[i - 1]).orthonormalized()
		prev_t = t
	prev_t = tc
	for i: int in range(CI - 1, -1, -1):
		var t := _tangent(i)
		_bas[i] = (Basis(Quaternion(prev_t, t)) * _bas[i + 1]).orthonormalized()
		prev_t = t


## Headward unit tangent at bone i.
func _tangent(i: int) -> Vector3:
	var d: Vector3
	if i == 0:
		d = _pts[0] - _pts[1]
	elif i == N - 1:
		d = _pts[N - 2] - _pts[N - 1]
	else:
		d = _pts[i - 1] - _pts[i + 1]
	return d.normalized() if d.length_squared() > 1e-10 else Vector3.BACK


func _apply() -> void:
	var sc := _scale()
	var root := _piv[P_ROOT]
	root.transform = Transform3D(Basis.from_scale(Vector3.ONE * sc), Vector3.ZERO)
	if _skel:
		for i: int in N:
			_skel.set_bone_pose_position(i, _pts[i])
			_skel.set_bone_pose_rotation(i, _bas[i].get_rotation_quaternion())
	var body_t := Transform3D(_bas[CI], _pts[CI])
	_piv[P_BODY].transform = body_t
	_piv[P_NECK1].transform = body_t.affine_inverse()
	_piv[P_NECK2].transform = Transform3D.IDENTITY
	var hb := Basis(Vector3.UP, _head_yaw) * Basis(Vector3.RIGHT, _head_pitch) * Basis(Vector3.BACK, _head_roll)
	_piv[P_HEAD].transform = Transform3D(hb, _pts[0])
	_piv[P_JAW].transform = Transform3D(Basis(Vector3.RIGHT, _jaw), _rest_pos[P_JAW])
	# the forelegs: tucked (air) / planted (coil): the leg swing cancels the chest's own pitch on the ground
	var chest_pitch := -asin(clampf(_bas[CI].z.y, -1.0, 1.0))
	var lx := _leg_x - chest_pitch * _g
	_piv[P_LEG_FL].transform = Transform3D(Basis.from_euler(Vector3(lx, 0.0, -_leg_z)), _rest_pos[P_LEG_FL])
	_piv[P_LEG_FR].transform = Transform3D(Basis.from_euler(Vector3(lx, 0.0, _leg_z)), _rest_pos[P_LEG_FR])
	if _fin_l:
		_fin_l.transform = Transform3D(Basis(Vector3.UP, -_fin_sweep) * Basis(Vector3.BACK, -_fin_droop), _fin_rest[0])
		_fin_r.transform = Transform3D(Basis(Vector3.UP, _fin_sweep) * Basis(Vector3.BACK, _fin_droop), _fin_rest[1])
	if _shadow:
		var c := Vector3.ZERO
		for p: Vector3 in _pts:
			c += p
		c /= float(N)
		var gw := _death_g if _dead else _g
		var sz := BLOB_AIR.lerp(BLOB_GROUND, gw) * sc
		_shadow.position = Vector3(c.x * sc, 0.02, c.z * sc)
		_shadow.scale = Vector3(sz.x, 1.0, sz.y)
		if not _dead:
			_shadow.transparency = 0.3 * (1.0 - gw)
	if _motes and _motes.visible:
		_motes.position = _pts[11]


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if _dead:
		return
	_poll_t -= dt
	if _poll_t <= 0.0:
		_poll_t = ENRAGE_POLL
		_poll_enrage()


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
		var on := bool(_unit.call(&"has_modifier", ENRAGE_MODIFIER))
		if on != _enraged:
			set_enraged(on)


## Head and jaw take the whole flare (eyes, palate, the crest's ice rays), the body the half (flank spots, fins).
func _flare_weight(pi: int) -> float:
	match pi:
		P_HEAD, P_JAW:
			return 1.0
		P_ROOT, P_BODY:
			return 0.5
	return 0.3


## Restarts the ice burst at a Root-space point.
func _burst_at(p: Vector3, ratio: float) -> void:
	if _burst == null or not is_inside_tree():
		return
	_bursts += 1
	_burst.position = p
	_burst.amount_ratio = ratio
	_burst.restart()


## Root-space point -> world.
func _world(p: Vector3) -> Vector3:
	var root := _piv[P_ROOT] if _piv.size() > 0 else null
	if root and root.is_inside_tree():
		return root.global_transform * p
	return p


## The eyes (faces pass 2026-09-28): painted on the front of the cold glowing eye blobs (kept: the glow point), a
## slit pupil and the lids that narrow on the attack and droop when it dies; the 3D brow ridges stay. Its own Face
## node (the wyrm is under its 20-draw titan budget).
static func face_spec() -> Dictionary:
	var out := Vector3(0.90, 0.10, 0.42).normalized()
	return CreatureFaceRig.side_eye_spec(Vector3(0.262, 4.178, 4.05) + out * 0.048, out, 0.062, Color(0.55, 0.72, 0.86),
		Color(0.70, 0.95, 1.0), 0.6, {"palette": {"sclera": Color(0.42, 0.62, 0.86), "brow": Color(0.30, 0.42, 0.60),
		"lash": Color(0.10, 0.16, 0.26)}, "eye": {"pupil": 0.60, "pupil_w": 0.28, "top": 0.030, "bot": 0.026}, "lift": 0.004})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
