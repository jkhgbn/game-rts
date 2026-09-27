class_name FlyerModel
extends Node3D
## Flight rig of a winged titan (cavalry-mounts.md 3.3 / 10 row 13.V13; first user: the Cinder Dragon). Own file,
## the shared CharacterModel kit is not used as a base (its 14 fixed pivots have no wings, neck chain or tail).
## Hooks for gameplay (all safe before _ready, has_method-guarded by Unit):
##   set_moving(speed) · set_turning(rate_deg_per_s) · play_attack() (= the breath) · play_hit() · play_death()
##   + signal death_finished · set_team_color(c) (wing membrane tint) · set_status(id, on) -> bool · revive()
##   plus the kit no-ops play_cast, play_level_up, set_veterancy, set_carrying, play_mine.
## Extra for the VFX (13.V14): signals breath_released / crashed(at), get_breath_origin() -> Transform3D.
## The model origin is the GROUND point under the flyer (the Unit stays on the ground, its ring and blob too);
## the body flies `fly_height` above it (meshes are authored at BAKE_HEIGHT and lifted by Root).
## Turning: set_turning(rate) in degrees per second of the unit's yaw (the value `rotation.y` changes by, positive =
## toward the model's local +X). Without calls, the rig measures its own global yaw change (so banking works even if
## gameplay only rotates the visual).
## Face = local +Z. Pivots (rest pose = the glide pose, every pivot basis identity; meshes in MODEL space under a
## child node placed at -model_origin(pivot)):
##   Root > Body > Neck1 > Neck2 > Head > Jaw · Body > WingL > WingL2, WingR > WingR2 · Body > Tail1 > Tail2 > Tail3 ·
##   Body > LegFL, LegFR, LegBL, LegBR.  Plus Fx (particles) and Shadow (ground blob) beside Root.
## Wings rotate about HINGE axes (not Euler): WingX about the shoulder -> hip line (the membrane root stays on the
## flank), WingX2 about the wrist -> last-finger line (the hand panel stays joined to the arm panel).
## Animation: all procedural in one _process (no Tween, no AnimationPlayer), distance tiers 0 (< 45 m, every
## frame) and 1 (every other frame); looping particles stop beyond 45 m.

signal death_finished
## The breath leaves the mouth (BREATH_RELEASE after play_attack): the breath cone of 13.V14 starts here.
signal breath_released
## The death fall hits the ground (CRASH_T after play_death): world position of the impact (crash dust, 13.V14).
signal crashed(at: Vector3)

enum { P_ROOT, P_BODY, P_NECK1, P_NECK2, P_HEAD, P_JAW, P_WING_L, P_WING_L2, P_WING_R, P_WING_R2,
	P_TAIL1, P_TAIL2, P_TAIL3, P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR }
const PIVOT_PATHS: Array[String] = ["Root", "Root/Body", "Root/Body/Neck1", "Root/Body/Neck1/Neck2",
	"Root/Body/Neck1/Neck2/Head", "Root/Body/Neck1/Neck2/Head/Jaw", "Root/Body/WingL", "Root/Body/WingL/WingL2",
	"Root/Body/WingR", "Root/Body/WingR/WingR2", "Root/Body/Tail1", "Root/Body/Tail1/Tail2",
	"Root/Body/Tail1/Tail2/Tail3", "Root/Body/LegFL", "Root/Body/LegFR", "Root/Body/LegBL", "Root/Body/LegBR"]
const NP: int = 17
const DEG := PI / 180.0
## Height of the body centre in the authored meshes (Root lifts the rig by fly_height - BAKE_HEIGHT).
const BAKE_HEIGHT := 4.0
## Body centre height when the corpse lies on the ground.
const GROUND_BODY_Y := 0.76
const HIT_LEN := 0.32
const BREATH_LEN := 1.3
## Spec 5.1: the breath's windup is 0.35 s; the jaw then stays open 0.6 s (spec 10).
const BREATH_RELEASE := 0.35
const JAW_OPEN_LEN := 0.6
## Spiral fall + crash + cool-down + sink. Must stay under Unit.DEATH_FALLBACK_TIME (2.0 s).
const DEATH_LEN := 1.85
const CRASH_T := 1.12
const WHITE := Vector3(1.0, 1.0, 1.0)
const GOLD := Vector3(1.0, 0.58, 0.08)
const LEVEL_LEN := 0.4

## Kit contract: HP bar / chevrons live at the UnitType's body_height; this one is the flying top (back + crown).
@export var body_height: float = 5.4
## Height of the body centre above the model origin (UnitType.fly_height, 4.0).
@export var fly_height: float = 4.0
## Seconds per wing beat (spec: 1.2 s).
@export var flap_period: float = 1.2
## Roll at the reference turn rate (deg).
@export var bank_max_deg: float = 34.0
## The turn rate that gives the full bank (UnitType.turn_rate_deg, 120).
@export var turn_rate_ref_deg: float = 120.0
## Speed of full forward flight (Unit overwrites it with the type's move_speed, 5.5).
@export var stride_speed: float = 5.5
## Kit contract (ranged release delay read by Unit, <= 0.15). 0: the breath is timed by gameplay (0.35 s windup).
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.0
## The colour the membrane material is authored with (set_team_color with it changes nothing).
@export var kingdom_color: Color = Color(0.85, 0.30, 0.12)
## Kit contract: Unit reads these on some models; the flyer ignores them.
@export var attack_style: StringName = &"breath"
@export var death_style: StringName = &"spiral_crash"

# --- rig
var _piv: Array[Node3D] = []
var _pidx: PackedInt32Array = PackedInt32Array()
var _rest_pos := PackedVector3Array()
var _off_pos := PackedVector3Array()
var _off_rot := PackedVector3Array()            # Euler offsets (YXZ), accumulated per frame
var _off_hinge: Array[Basis] = []               # hinge rotations (applied outside the Euler part)
var _root_scale: Vector3 = Vector3.ONE
var _body_scale: Vector3 = Vector3.ONE        # squash about the body centre (crash)
## Hinge axes (model space, unit length), set by the subclass in _build_parts: [left, right].
var wing_axis: Array[Vector3] = [Vector3(0, 0, -1), Vector3(0, 0, -1)]
var hand_axis: Array[Vector3] = [Vector3(0, 0, -1), Vector3(0, 0, -1)]

# --- nodes the rig drives
var _shadow: GeometryInstance3D
var _mouth: Node3D
var _mesh_nodes: Array[GeometryInstance3D] = []  # every mesh of the model (not the blob, not particles)
var _node_pivot: Dictionary = {}                   # GeometryInstance3D -> pivot index
var _flash_nodes: Array[GeometryInstance3D] = []
var _glow_nodes: Array[GeometryInstance3D] = []
var _tint_nodes: Array[GeometryInstance3D] = []
var _loop_fx: Array[GPUParticles3D] = []
var _death_fx: Array[GPUParticles3D] = []
var _ready_done: bool = false

# --- state
var _t: float = 0.0
var _phase_off: float = 0.0
var _tier: int = 0
var _tier_timer: float = 0.0
var _acc: float = 0.0
var _speed: float = 0.0
var _move_w: float = 0.0
var _turn_set: float = 0.0
var _turn_set_t: float = 99.0
var _turn_meas: float = 0.0
var _last_yaw: float = 0.0
var _has_yaw: bool = false
var _bank: float = 0.0                 # -1..1 (positive = turning toward +X)
var _flap_p: float = 0.0               # 0..1, 0 = wings at the top
var _flap_amp_w: float = 1.0           # smoothed flap amplitude weight (0 = glide pose)
var _gliding: bool = false
var _glide_left: float = 0.0
var _flaps_left: int = 3
var _straight_t: float = 0.0
var _action: StringName = &""          # &"attack"
var _action_t: float = 0.0
var _hit_t: float = 99.0
var _last_hit_time: float = -9.0
var _level_t: float = 99.0
var _dead: bool = false
var _death_t: float = 0.0
var _death_emitted: bool = false
var _crash_emitted: bool = false
var _frozen_status: bool = false
var _haste: bool = false
var _vet_boost: float = 1.0
var _cool: float = 1.0                 # 1 = lava hot, 0 = cooled (death)
var _flare: float = 0.0                # breath glow flare (0..~1.6)
var _flash_v: float = 0.0
var _flash_gold: bool = false
var _team_pending: Variant = null
var _tint: Color = Color(0.85, 0.30, 0.12)
var _glow_written: Dictionary = {}     # node -> last glow_boost
var _spiral_dir: float = 1.0


# ================================================================ lifecycle

func _ready() -> void:
	_phase_off = float(hash(get_instance_id()) % 100) / 100.0
	_tier_timer = float(hash(get_instance_id()) % 50) / 100.0
	_flap_p = _phase_off
	_spiral_dir = 1.0 if (hash(get_instance_id()) & 1) == 0 else -1.0
	_piv.resize(NP)
	_off_hinge.resize(NP)
	for a: PackedVector3Array in [_rest_pos, _off_pos, _off_rot]:
		a.resize(NP)
	for i: int in NP:
		var n := get_node_or_null(PIVOT_PATHS[i]) as Node3D
		_piv[i] = n
		_off_hinge[i] = Basis.IDENTITY
		if n:
			_pidx.append(i)
			_rest_pos[i] = n.position
	_shadow = get_node_or_null("Shadow") as GeometryInstance3D
	_tint = kingdom_color
	_build_parts()
	_collect(self)
	_ready_done = true
	_after_ready()
	_write_tint()
	_apply_glow(true)
	if _team_pending != null:
		set_team_color(_team_pending)
	_animate(0.0)


## Subclass: build the meshes (add_pivot_mesh), particles, the Mouth marker, set wing_axis / hand_axis.
func _build_parts() -> void:
	pass


## Subclass: grab node references after the collection.
func _after_ready() -> void:
	pass


## Subclass: own per-frame motion (flames...). No allocation.
func _extra_process(_dt: float) -> void:
	pass


# ================================================================ hooks

## Kingdom colour -> the wing membrane tint (instance uniform, no material duplicate).
func set_team_color(c: Color) -> void:
	if not _ready_done:
		_team_pending = c
		return
	_team_pending = null
	_tint = c
	_write_tint()


func set_moving(speed: float) -> void:
	_speed = maxf(speed, 0.0)


## Signed yaw rate in degrees per second (positive = turning toward local +X). Overrides the measured rate for 0.3 s.
func set_turning(rate: float) -> void:
	_turn_set = rate
	_turn_set_t = 0.0


## The breath (jaw open 0.6 s from BREATH_RELEASE). Re-trigger restarts.
func play_attack() -> void:
	if _dead:
		return
	_action = &"attack"
	_action_t = 0.0
	_on_action_event(&"attack_start")


func play_cast(_spell_id: StringName) -> void:
	play_attack()


func play_hit() -> void:
	if _dead or _t - _last_hit_time < 0.15:
		return
	_last_hit_time = _t
	_hit_t = 0.0
	_flash_gold = false


func play_death() -> void:
	if _dead:
		return
	_dead = true
	_death_t = 0.0
	_death_emitted = false
	_crash_emitted = false
	_action = &""
	_hit_t = 99.0
	_speed = 0.0
	set_process(true)


func revive() -> void:
	_dead = false
	_death_t = 0.0
	_death_emitted = false
	_crash_emitted = false
	_action = &""
	_hit_t = 99.0
	_level_t = 99.0
	_speed = 0.0
	_move_w = 0.0
	_bank = 0.0
	_cool = 1.0
	_flare = 0.0
	_root_scale = Vector3.ONE
	_set_flash(0.0)
	if _shadow:
		_shadow.transparency = 0.0
	_glow_written.clear()
	_apply_glow(true)
	_on_revive()
	set_process(true)
	_animate(0.0)


## Titans have no veterancy (spec 3.4); kept for the kit contract.
func set_veterancy(level: int) -> void:
	_vet_boost = [1.0, 1.0, 1.25, 1.5, 1.8][clampi(level, 0, 4)]
	_apply_glow(false)


func play_level_up() -> void:
	if _dead:
		return
	_level_t = 0.0


func set_carrying(_on: bool) -> void:
	pass


func play_mine() -> void:
	pass


## haste -> brighter lava (true). frozen -> the wings stop in place (false: the ice look stays the VFX's).
func set_status(id: StringName, on: bool) -> bool:
	match id:
		&"haste":
			_haste = on
			_apply_glow(false)
			return true
		&"frozen":
			_frozen_status = on
			return false
	return false


func glow_level() -> float:
	return _vet_boost * (1.3 if _haste else 1.0) * _cool


## World transform at the mouth, +Z along the breath (the head's facing).
func get_breath_origin() -> Transform3D:
	if _mouth and _mouth.is_inside_tree():
		return _mouth.global_transform
	return global_transform * Transform3D(Basis(), Vector3(0.0, fly_height + 0.9, 2.9))


func is_breathing() -> bool:
	return _action == &"attack" and _action_t >= BREATH_RELEASE and _action_t < BREATH_RELEASE + JAW_OPEN_LEN


func _on_action_event(_ev: StringName) -> void:
	pass


func _on_revive() -> void:
	pass


# ================================================================ building helpers

## Adds a mesh (MODEL-space vertices) under pivot index i: the node sits at -model_origin so it renders in place.
func add_pivot_mesh(i: int, mesh: Mesh, cast_shadow: bool = false, node_name: String = "Mesh") -> MeshInstance3D:
	var p: Node3D = _piv[i]
	if p == null or mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = -model_origin(p)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(mi)
	return mi


## A marker / emitter at a MODEL-space point under pivot i.
func add_pivot_node(i: int, n: Node3D, model_pos: Vector3) -> void:
	var p: Node3D = _piv[i]
	if p == null:
		return
	n.position = model_pos - model_origin(p)
	p.add_child(n)


## Model-space rest position of a node (pivots are unrotated at rest).
func model_origin(n: Node3D) -> Vector3:
	var p := Vector3.ZERO
	var c: Node = n
	while c and c != self:
		p += (c as Node3D).position
		c = c.get_parent()
	return p


func ensure_shadow_blob(size: Vector2, tint: Color) -> void:
	if _shadow == null:
		var mi := MeshInstance3D.new()
		mi.name = "Shadow"
		var pm := PlaneMesh.new()
		pm.size = Vector2.ONE
		mi.mesh = pm
		mi.material_override = CharacterModel.palette(&"unit_shadow_blob")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0, 0.02, 0)
		add_child(mi)
		_shadow = mi
	_shadow.scale = Vector3(size.x, 1.0, size.y)
	_shadow.set_instance_shader_parameter(&"blob_color", tint)


func _pivot_index_of(n: Node) -> int:
	var c: Node = n
	while c and c != self:
		var k := _piv.find(c)
		if k >= 0:
			return k
		c = c.get_parent()
	return -1


func _collect(n: Node) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D:
			var gp := c as GPUParticles3D
			if gp.one_shot:
				_death_fx.append(gp)
			else:
				_loop_fx.append(gp)
		elif c is GeometryInstance3D and c != _shadow:
			var gi := c as GeometryInstance3D
			_mesh_nodes.append(gi)
			_node_pivot[gi] = _pivot_index_of(gi)
			var names := PackedStringArray()
			for m: Material in _materials_of(gi):
				names.append_array(CharacterModel.instance_uniforms_of(m))
			if names.has("hit_flash"):
				_flash_nodes.append(gi)
			if names.has("glow_boost"):
				_glow_nodes.append(gi)
			if names.has("membrane_tint"):
				_tint_nodes.append(gi)
		_collect(c)


func _materials_of(gi: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if gi.material_override:
		out.append(gi.material_override)
		return out
	if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
		var mi := gi as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(s)
			if m == null:
				m = mi.mesh.surface_get_material(s)
			if m:
				out.append(m)
	return out


# ================================================================ per frame

func _process(delta: float) -> void:
	_t += delta
	_turn_set_t += delta
	_tier_timer -= delta
	if _tier_timer <= 0.0:
		_tier_timer = 0.5
		_update_tier()
	_acc += delta
	if _tier >= 1 and ((Engine.get_process_frames() + get_instance_id()) & 1) == 1:
		return
	var dt := _acc
	_acc = 0.0
	_animate(dt)


func _update_tier() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var nt: int = 1
	if cam:
		nt = 0 if cam.global_position.distance_to(global_position) < 45.0 else 1
	if nt != _tier:
		_tier = nt
		for p: GPUParticles3D in _loop_fx:
			p.emitting = nt == 0 and not _dead


func _animate(dt: float) -> void:
	for i: int in _pidx:
		_off_pos[i] = Vector3.ZERO
		_off_rot[i] = Vector3.ZERO
		_off_hinge[i] = Basis.IDENTITY
	_root_scale = Vector3.ONE
	_body_scale = Vector3.ONE
	_update_turn(dt)
	if _dead:
		_pose_death(dt)
	else:
		_pose_flight(dt)
		if _action == &"attack":
			var prev := _action_t
			_action_t += dt
			_pose_breath(prev, _action_t)
			if _action_t >= BREATH_LEN:
				_action = &""
				_flare = 0.0
				_on_action_event(&"attack_end")
		if _hit_t < HIT_LEN:
			_hit_t += dt
			_pose_hit(_hit_t)
	_update_flash(dt)
	_extra_process(dt)
	_apply()
	_apply_glow(false)


# ---------------------------------------------------------------- turning / bank

func _global_yaw() -> float:
	var z := global_transform.basis.z
	return atan2(z.x, z.z)


func _update_turn(dt: float) -> void:
	if not is_inside_tree():
		return
	var yaw := _global_yaw()
	if _has_yaw and dt > 0.0001:
		var d := wrapf(yaw - _last_yaw, -PI, PI)
		var meas := clampf(rad_to_deg(d) / dt, -400.0, 400.0)
		_turn_meas = lerpf(_turn_meas, meas, 1.0 - exp(-dt * 10.0))
	_last_yaw = yaw
	_has_yaw = true
	var rate := _turn_set if _turn_set_t < 0.3 else _turn_meas
	var target := 0.0 if _dead else clampf(rate / maxf(turn_rate_ref_deg, 1.0), -1.0, 1.0)
	_bank = lerpf(_bank, target, 1.0 - exp(-dt * 3.2))


# ---------------------------------------------------------------- flight

## Hover (standing still: big beats, nose up, legs hanging, tail low, the head looks around), forward flight
## (smaller beats, level, legs tucked, tail streaming) with glides between beats when flying straight, banking
## into turns (roll, head into the turn, tail swings out, the flap resumes in a turn).
func _pose_flight(dt: float) -> void:
	var moving := _speed >= 0.3
	_move_w = move_toward(_move_w, 1.0 if moving else 0.0, dt / 0.7)
	var mw := _move_w * _move_w * (3.0 - 2.0 * _move_w)
	var hw := 1.0 - mw
	var sp := clampf(_speed / maxf(stride_speed, 0.5), 0.0, 1.3)
	var ab := absf(_bank)
	# --- glide / flap scheduler (glides only when flying straight and not breathing)
	var straight := mw > 0.85 and ab < 0.18 and _action == &"" and not _frozen_status
	_straight_t = _straight_t + dt if straight else 0.0
	var prev_p := _flap_p
	if not _frozen_status:
		_flap_p = fmod(_flap_p + dt / maxf(flap_period, 0.2), 1.0)
	var wrapped := _flap_p < prev_p
	if _gliding:
		_glide_left -= dt
		if _glide_left <= 0.0 or not straight:
			_gliding = false
			_flaps_left = 2 + int(fmod(_t * 7.3 + _phase_off * 10.0, 2.0))
	elif wrapped:
		_flaps_left -= 1
		if _flaps_left <= 0 and straight and _straight_t > 0.8:
			_gliding = true
			_glide_left = 2.2 + fmod(_t * 3.1 + _phase_off * 7.0, 1.0)
	var amp_target := 0.0 if _gliding else 1.0
	_flap_amp_w = move_toward(_flap_amp_w, amp_target, dt / (0.5 if _gliding else 0.35))
	var aw := _flap_amp_w * _flap_amp_w * (3.0 - 2.0 * _flap_amp_w)
	var gw := 1.0 - aw

	# --- wing beat: fast downstroke (0 .. 0.45), slower upstroke; psi 0 = top, 0.5 = bottom
	var down := 0.45
	var psi := 0.5 * _flap_p / down if _flap_p < down else 0.5 + 0.5 * (_flap_p - down) / (1.0 - down)
	var c := cos(TAU * psi)
	var amp := lerpf(52.0, 40.0, mw)
	var mid := lerpf(10.0, 6.0, mw)
	var brk := _breath_wing_mult()
	var raise := (mid + amp * c) * aw * brk
	# glide: wings level with a slow soaring sway
	var soar := sin(_t * 1.9 + _phase_off * 6.0)
	raise += gw * (2.0 + 3.0 * soar)
	# the hand lags the arm (whip): tip down on the upstroke, flicks up at the bottom
	var hand := (-24.0 * sin(TAU * psi - 0.9) - 6.0) * aw * brk + gw * (5.0 + 2.0 * soar)
	# sweep: forward on the downstroke (hover: a figure-eight stroke plane)
	var sweep := (lerpf(7.0, 4.0, mw) * sin(TAU * psi + 0.4)) * aw
	for side: int in 2:
		var s := -1.0 if side == 0 else 1.0
		var wi := P_WING_L if side == 0 else P_WING_R
		var hi := P_WING_L2 if side == 0 else P_WING_R2
		# a small asymmetry in turns: the outer wing beats a little higher
		var turn_extra := 5.0 * _bank * s * aw
		_wing_raise(side, (raise - turn_extra) * DEG)
		_hand_bend(side, hand * DEG)
		rot(wi, Vector3(0.0, -s * sweep * DEG, 0.0))
		rot(hi, Vector3(0.0, -s * 3.0 * DEG * sin(TAU * psi + 1.2) * aw, 0.0))

	# --- body: bob with the beat (lowest with the wings up), hover nose-up, bank roll
	var bob := (-lerpf(0.17, 0.09, mw) * c) * aw
	var drift := 0.06 * sin(_t * 0.83 + _phase_off * 5.0) * hw + gw * 0.05 * sin(_t * 1.1)
	var lift := fly_height - BAKE_HEIGHT
	pos(P_ROOT, Vector3(0.0, lift + bob + drift, 0.0))
	var pitch := lerpf(-13.0, -1.5 + 3.0 * clampf(sp - 0.6, 0.0, 0.6), mw) + 3.0 * sin(TAU * psi - 0.6) * aw
	pitch += -5.0 * ab * mw   # pull up a little in turns
	var roll := -bank_max_deg * _bank
	rot(P_BODY, Vector3(pitch * DEG, 0.0, roll * DEG))

	# --- neck + head: steady head (counter the bob / pitch), look around while hovering, into turns
	var look_y := hw * (14.0 * sin(_t * 0.37 + _phase_off * 4.0) + 6.0 * sin(_t * 0.91 + 1.3))
	var look_x := hw * 5.0 * sin(_t * 0.53 + 0.7)
	var steady := -0.55 * pitch
	rot(P_NECK1, Vector3((steady * 0.5 + 3.0 * c * aw) * DEG, (0.4 * look_y + 12.0 * _bank) * DEG, 0.0))
	rot(P_NECK2, Vector3((steady * 0.3 + look_x - 2.5 * c * aw) * DEG, (0.4 * look_y + 10.0 * _bank) * DEG,
		-0.35 * roll * DEG))
	rot(P_HEAD, Vector3((steady * 0.2 - look_x * 0.5 - 1.5 * c * aw) * DEG, (0.3 * look_y + 6.0 * _bank) * DEG,
		-0.45 * roll * DEG))
	rot(P_JAW, Vector3((2.0 + 2.0 * sin(_t * 1.7 + _phase_off)) * DEG, 0.0, 0.0))

	# --- tail: travelling wave, low while hovering, streaming in flight, swings out in turns
	var wave_w := lerpf(1.0, 0.5, mw)
	var tail_pitch: Array[float] = [lerpf(-10.0, 1.0, mw), lerpf(-7.0, 0.0, mw), lerpf(-6.0, 1.0, mw)]
	var tail_amp: Array[float] = [7.0, 10.0, 14.0]
	var tail_i: Array[int] = [P_TAIL1, P_TAIL2, P_TAIL3]
	for k: int in 3:
		var ph := _t * TAU / 2.6 - float(k) * 0.95 + _phase_off * 3.0
		var yaw: float = tail_amp[k] * wave_w * sin(ph) + (6.0 + 3.0 * float(k)) * _bank
		var pit: float = tail_pitch[k] + 4.0 * sin(TAU * psi - 1.2 - float(k) * 0.8) * aw
		rot(tail_i[k], Vector3(pit * DEG, yaw * DEG, 0.0))

	# --- legs: tucked in flight, hanging (and pedalling a little) while hovering
	var dang := hw
	var paddle := 5.0 * sin(TAU * psi + 0.5) * aw
	rot(P_LEG_FL, Vector3((32.0 * dang + paddle) * DEG, 0.0, 6.0 * dang * DEG))
	rot(P_LEG_FR, Vector3((32.0 * dang + paddle) * DEG, 0.0, -6.0 * dang * DEG))
	rot(P_LEG_BL, Vector3((-40.0 * dang - paddle) * DEG, 0.0, 4.0 * dang * DEG))
	rot(P_LEG_BR, Vector3((-40.0 * dang - paddle) * DEG, 0.0, -4.0 * dang * DEG))


## Wing raise (radians, positive = tip up) about the shoulder hinge. side 0 = left (-X), 1 = right (+X).
func _wing_raise(side: int, ang: float) -> void:
	var i := P_WING_L if side == 0 else P_WING_R
	# The hinge points backward (shoulder -> hip): a positive rotation about it lifts the -X wing and lowers +X.
	var a := ang if side == 0 else -ang
	_off_hinge[i] = _off_hinge[i] * Basis(wing_axis[side], a)


## Hand bend (radians, positive = tip up) about the wrist -> last-finger hinge.
func _hand_bend(side: int, ang: float) -> void:
	var i := P_WING_L2 if side == 0 else P_WING_R2
	var a := ang if side == 0 else -ang
	_off_hinge[i] = _off_hinge[i] * Basis(hand_axis[side], a)


# ---------------------------------------------------------------- breath

## Multiplier of the beat amplitude while breathing (the wings hold wide and beat shallow, backing the body).
func _breath_wing_mult() -> float:
	if _action != &"attack":
		return 1.0
	return _kf(_action_t, [0.0, 0.25, 0.4, 0.95, 1.3], [1.0, 0.35, 0.55, 0.55, 1.0])


## Rear back (0 .. 0.3: neck up, chest out, wings flared, the lava heats up), strike down at the target
## (0.35: jaw opens, breath_released), jaw open 0.6 s while the head sweeps the cone, recover by 1.3 s.
func _pose_breath(prev: float, t: float) -> void:
	var ts: Array = [0.0, 0.30, 0.40, 0.95, 1.30]
	rot(P_NECK1, Vector3(_kf(t, ts, [0.0, -18.0, 15.0, 12.0, 0.0]) * DEG, 0.0, 0.0))
	rot(P_NECK2, Vector3(_kf(t, ts, [0.0, -16.0, 12.0, 10.0, 0.0]) * DEG, 0.0, 0.0))
	var sweep := 0.0
	if t > 0.38 and t < 0.98:
		sweep = 13.0 * sin((t - 0.38) / 0.6 * TAU) * sin(PI * (t - 0.38) / 0.6)
	rot(P_HEAD, Vector3(_kf(t, ts, [0.0, -14.0, 12.0, 9.0, 0.0]) * DEG, sweep * DEG, 0.0))
	rot(P_JAW, Vector3(_kf(t, [0.0, 0.28, 0.35, 0.42, 0.95, 1.12], [0.0, 10.0, 12.0, 40.0, 36.0, 0.0]) * DEG, 0.0, 0.0))
	rot(P_BODY, Vector3(_kf(t, ts, [0.0, -9.0, 5.0, 3.0, 0.0]) * DEG, 0.0, 0.0))
	pos(P_BODY, Vector3(0.0, _kf(t, ts, [0.0, 0.10, -0.04, 0.0, 0.0]), _kf(t, ts, [0.0, -0.12, 0.14, -0.10, 0.0])))
	var wing := _kf(t, ts, [0.0, 24.0, -8.0, -4.0, 0.0])
	var hnd := _kf(t, ts, [0.0, 12.0, -6.0, -2.0, 0.0])
	for side: int in 2:
		_wing_raise(side, wing * DEG)
		_hand_bend(side, hnd * DEG)
	# the tail curls up as the chest rears (it balances the neck), then lashes side to side
	rot(P_TAIL1, Vector3(_kf(t, ts, [0.0, 6.0, -2.0, 0.0, 0.0]) * DEG, 0.0, 0.0))
	rot(P_TAIL2, Vector3(_kf(t, ts, [0.0, 8.0, -4.0, 2.0, 0.0]) * DEG, _kf(t, ts, [0.0, 0.0, 8.0, -8.0, 0.0]) * DEG, 0.0))
	rot(P_TAIL3, Vector3(_kf(t, ts, [0.0, 12.0, -6.0, 4.0, 0.0]) * DEG, _kf(t, ts, [0.0, 0.0, 12.0, -12.0, 0.0]) * DEG, 0.0))
	_flare = _kf(t, ts, [0.0, 0.9, 1.7, 1.3, 0.0])
	if prev < BREATH_RELEASE and t >= BREATH_RELEASE:
		breath_released.emit()
		_on_action_event(&"release")


# ---------------------------------------------------------------- hit

## A jolt up and back, wings flinch up, the head recoils, the tail flicks; white flash on every painted part.
func _pose_hit(t: float) -> void:
	var k: float = clampf(t / 0.06, 0.0, 1.0) if t < 0.06 else clampf(1.0 - (t - 0.06) / (HIT_LEN - 0.06), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	pos(P_BODY, Vector3(0.0, 0.10 * k, -0.18 * k))
	rot(P_BODY, Vector3(-6.0 * DEG * k, 0.0, 0.0))
	rot(P_NECK2, Vector3(-9.0 * DEG * k, 0.0, 0.0))
	rot(P_HEAD, Vector3(-12.0 * DEG * k, 0.0, 0.0))
	rot(P_JAW, Vector3(14.0 * DEG * k, 0.0, 0.0))
	for side: int in 2:
		_wing_raise(side, 14.0 * DEG * k)
		_hand_bend(side, -10.0 * DEG * k)
	rot(P_TAIL2, Vector3(10.0 * DEG * k, 0.0, 0.0))
	rot(P_TAIL3, Vector3(16.0 * DEG * k, 0.0, 0.0))


func _update_flash(dt: float) -> void:
	if _hit_t < HIT_LEN and not _dead:
		_flash_gold = false
		_set_flash(clampf(1.0 - _hit_t / 0.13, 0.0, 1.0))
	elif _level_t < LEVEL_LEN and not _dead:
		_level_t += dt
		_flash_gold = true
		_set_flash(0.42 * clampf(1.0 - _level_t / LEVEL_LEN, 0.0, 1.0))
	elif _flash_v != 0.0:
		_set_flash(0.0)


func _set_flash(v: float) -> void:
	if v == _flash_v:
		return
	_flash_v = v
	var col := GOLD if _flash_gold else WHITE
	for gi: GeometryInstance3D in _flash_nodes:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", col)


# ---------------------------------------------------------------- death

## Death throe (0 .. 0.3: head thrown up, roar, wings jerk up), spiral fall (the body spins down a tight helix,
## rolls over, one wing flails, the other crumples), crash at CRASH_T (squash, bounce, wings splay on the ground,
## `crashed`, embers burst), the lava cools (1.2 .. 1.6), then the corpse sinks; death_finished at DEATH_LEN.
func _pose_death(dt: float) -> void:
	_death_t += dt
	var t := _death_t
	var lift := fly_height - BAKE_HEIGHT
	var throe := _ease_out(clampf(t / 0.28, 0.0, 1.0)) * (1.0 - clampf((t - 0.3) / 0.35, 0.0, 1.0))
	var f := clampf((t - 0.25) / (CRASH_T - 0.25), 0.0, 1.0)
	var fall := f * f
	var landed := t >= CRASH_T
	var sd := _spiral_dir
	# --- height: lurch up, then accelerate down to the ground
	var y_air := lift + 0.35 * throe
	var y_ground := GROUND_BODY_Y - BAKE_HEIGHT
	var y := lerpf(y_air, y_ground, fall)
	# --- the helix: the body circles (radius 0.9 m) while the whole rig spins about its own axis
	var spin := sd * 1.35 * PI * _ease_in(f)
	var circle := sd * 1.6 * PI * f
	var rad := 0.9 * sin(PI * minf(f * 1.2, 1.0))
	var off := Vector3(rad * (1.0 - cos(circle)), 0.0, rad * sin(circle))
	if landed:
		# impact: squash + a small bounce, then settle
		var ti := t - CRASH_T
		var sq := exp(-ti * 9.0) * cos(ti * 22.0)
		_body_scale = Vector3(1.0 + 0.08 * sq, 1.0 - 0.18 * sq, 1.0 + 0.05 * sq)
		y = y_ground + 0.16 * maxf(0.0, sin(clampf(ti / 0.22, 0.0, 1.0) * PI)) * exp(-ti * 3.0)
		spin = sd * 1.35 * PI
		off = Vector3.ZERO
		var sink := _ease_in(clampf((t - 1.45) / (DEATH_LEN - 1.45), 0.0, 1.0))
		y -= 1.35 * sink
		if not _crash_emitted:
			_crash_emitted = true
			for p: GPUParticles3D in _death_fx:
				p.restart()
			crashed.emit(global_transform * Vector3(0.0, 0.1, 0.0))
			_on_action_event(&"crash")
	pos(P_ROOT, Vector3(off.x, y, off.z))
	rot(P_ROOT, Vector3(0.0, spin, 0.0))
	# --- body: rolls over in the fall, lands mostly on its belly (a slight list), nose down while falling
	var roll_air := sd * 70.0 * _ease_in(f)
	var land_k := _ease_out(clampf((t - CRASH_T) / 0.18, 0.0, 1.0))
	var roll := lerpf(roll_air, sd * 9.0, land_k)
	var pitch := lerpf(-10.0 * throe + 28.0 * fall, 4.0, land_k)
	rot(P_BODY, Vector3(pitch * DEG, 0.0, roll * DEG))
	# --- neck / head: thrown up (roar), limp in the fall, slammed down and flopped aside on the ground
	var n1 := -28.0 * throe + 22.0 * fall
	var n2 := -20.0 * throe + 20.0 * fall
	var hd := -22.0 * throe + 16.0 * fall
	if landed:
		n1 = lerpf(n1, 16.0, land_k)
		n2 = lerpf(n2, 14.0, land_k)
		hd = lerpf(hd, 12.0, land_k)
	var flop := sd * 24.0 * land_k
	rot(P_NECK1, Vector3(n1 * DEG, flop * 0.4 * DEG, 0.0))
	rot(P_NECK2, Vector3(n2 * DEG, flop * 0.6 * DEG, 0.0))
	rot(P_HEAD, Vector3(hd * DEG, flop * 0.5 * DEG, sd * 20.0 * land_k * DEG))
	rot(P_JAW, Vector3((34.0 * throe + 10.0 * fall * (1.0 - land_k) + 16.0 * land_k) * DEG, 0.0, 0.0))
	# --- wings: jerk up, then one flails (fast, decaying) and one crumples; splayed flat on the ground
	var flail := sin(t * 34.0) * 30.0 * clampf(1.0 - f, 0.0, 1.0) * clampf((t - 0.25) / 0.1, 0.0, 1.0)
	var up_side := 1 if sd > 0.0 else 0   # the wing that ends high in the roll (+Z roll lifts +X) flails
	for side: int in 2:
		var w_air: float
		var h_air: float
		if side == up_side:
			w_air = 40.0 * throe + (20.0 + flail) * fall
			h_air = 10.0 * throe - 20.0 * fall
		else:
			w_air = 40.0 * throe + 65.0 * fall
			h_air = 10.0 * throe - 70.0 * fall
		# splayed on the ground: the tips just touch it (the high side of the list reaches further down)
		var w_gnd := -33.0 if side == up_side else -22.0
		var h_gnd := -3.0
		_wing_raise(side, lerpf(w_air, w_gnd, land_k) * DEG)
		_hand_bend(side, lerpf(h_air, h_gnd, land_k) * DEG)
	# --- tail: lashing in the fall, laid out in a curve after the crash
	var tail_i: Array[int] = [P_TAIL1, P_TAIL2, P_TAIL3]
	for k: int in 3:
		var la: float = (16.0 + 8.0 * float(k)) * sin(t * 9.0 - float(k) * 1.1) * (1.0 - land_k)
		var curl: float = sd * (12.0 + 6.0 * float(k)) * land_k
		rot(tail_i[k], Vector3((-6.0 * land_k + 10.0 * fall * (1.0 - land_k)) * DEG, (la + curl) * DEG, 0.0))
	# --- legs: flail, then splay
	var lk := land_k
	rot(P_LEG_FL, Vector3((30.0 * throe + 20.0 * fall * (1.0 - lk) + 38.0 * lk) * DEG, 0.0, 14.0 * lk * DEG))
	rot(P_LEG_FR, Vector3((30.0 * throe + 20.0 * fall * (1.0 - lk) + 38.0 * lk) * DEG, 0.0, -14.0 * lk * DEG))
	rot(P_LEG_BL, Vector3((-30.0 * throe - 25.0 * fall * (1.0 - lk) - 10.0 * lk) * DEG, 0.0, 22.0 * lk * DEG))
	rot(P_LEG_BR, Vector3((-30.0 * throe - 25.0 * fall * (1.0 - lk) - 10.0 * lk) * DEG, 0.0, -22.0 * lk * DEG))
	# --- lava: flares in the throe, cools after the crash
	_flare = 1.2 * throe
	_cool = 1.0 - smoothstep(CRASH_T + 0.05, CRASH_T + 0.5, t)
	if _shadow:
		_shadow.transparency = clampf((t - 1.5) / 0.3, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


# ================================================================ pose helpers

## Adds an Euler rotation offset (radians, YXZ) to pivot i for this frame.
func rot(i: int, r: Vector3) -> void:
	if _piv[i]:
		_off_rot[i] += r


## Adds a position offset (m, parent space) to pivot i for this frame.
func pos(i: int, p: Vector3) -> void:
	if _piv[i]:
		_off_pos[i] += p


## Smooth keyframes (times ascending, values), smoothstep between keys, clamped at the ends.
static func _kf(t: float, ts: Array, vs: Array) -> float:
	if t <= float(ts[0]):
		return float(vs[0])
	for k: int in range(1, ts.size()):
		if t < float(ts[k]):
			var a := (t - float(ts[k - 1])) / maxf(float(ts[k]) - float(ts[k - 1]), 0.0001)
			return lerpf(float(vs[k - 1]), float(vs[k]), a * a * (3.0 - 2.0 * a))
	return float(vs[vs.size() - 1])


static func _ease_out(x: float) -> float:
	return 1.0 - (1.0 - x) * (1.0 - x)


static func _ease_in(x: float) -> float:
	return x * x


func _apply() -> void:
	for i: int in _pidx:
		var b := _off_hinge[i] * Basis.from_euler(_off_rot[i])
		if i == P_BODY:
			b = b.scaled_local(_body_scale)
		_piv[i].transform = Transform3D(b, _rest_pos[i] + _off_pos[i])
	var root := _piv[P_ROOT]
	if root:
		root.scale = _root_scale
	if _shadow and _piv[P_ROOT]:
		# the blob stays on the ground under the body (it follows the death spiral's circle)
		var rp := _piv[P_ROOT].position
		_shadow.position = Vector3(rp.x, 0.02, rp.z)


func _apply_glow(force: bool) -> void:
	if not _ready_done:
		return
	var g := glow_level()
	for gi: GeometryInstance3D in _glow_nodes:
		var pi: int = _node_pivot.get(gi, -1)
		var fl := _flare * _flare_weight(pi)
		var v := g * (1.0 + fl)
		if force or absf(float(_glow_written.get(gi, -99.0)) - v) > 0.004:
			_glow_written[gi] = v
			gi.set_instance_shader_parameter(&"glow_boost", v)


## How much of the breath flare a pivot's lava takes (head and neck most: the fire rises up the throat).
func _flare_weight(pi: int) -> float:
	match pi:
		P_HEAD, P_JAW:
			return 1.0
		P_NECK2:
			return 0.9
		P_NECK1:
			return 0.75
		P_BODY:
			return 0.5
	return 0.15


func _write_tint() -> void:
	var v := Vector3(_tint.r, _tint.g, _tint.b)
	for gi: GeometryInstance3D in _tint_nodes:
		gi.set_instance_shader_parameter(&"membrane_tint", v)
