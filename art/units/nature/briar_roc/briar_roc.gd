extends "res://art/units/neutral/beasts/roc/roc.gd"
## Briar Roc, Nature T3 flyer (t3-helpers.md 7.2 / 7.3, tiers wave). A 5 m wingspan bird of BARK and THORN: dry-leaf
## wings with thorned bark leading edges and long pointed leaf primaries, a leaf tail fan, a pale thorn beak, an
## ANTLER CREST carrying two glowing seed buds (the glow point, high up), a seed-pod belly with glowing seed slits.
## Reuses the Roc's flight rig and motion (roc.gd on FlyerModel: hover-glide idle, banked glide, talon rake, swoop,
## tumble death) with its own meshes (briar_roc_mesh.gd) and materials (materials/, briar_feather.gdshader).
## The whole bird is scaled by BODY_SCALE (the Roc's 6.7 m span -> 5 m); it glides `fly_height` above its ground point.
## Team colour: the leaf mantle, the outer primaries, three tail leaves and the crest leaves (instance uniform
## membrane_tint, written by FlyerModel; set_team_color works, unlike the neutral Roc's).
## Hooks: the FlyerModel / Roc set (set_moving, set_turning, play_attack = talon rake from the air, play_cast, play_hit,
## play_death + death_finished, play_level_up, set_veterancy, set_status, revive, set_team_color).
## play_cast(&"seed_storm") (or any id): the Roc's swoop; at the impact the pod shakes open and seeds rain as green
## sparks (Fx/Seeds, one-shot), the pod slits and the crest buds flare. 0 lights.

const BRM := preload("res://art/units/nature/briar_roc/briar_roc_mesh.gd")
const BODY_SCALE := 0.75
const BLOB_MULT := 0.78
const LUNGE_Z := 1.8
static var K_LUNGE := PackedFloat32Array([0.0, 0.0, 0.08, 0.05, 0.18, 1.0, 0.38, 0.9, 0.6, 0.25, 0.8, 0.0])

var _seeds: GPUParticles3D
var _face: FaceRig   # beast eyes (FaceKit): amber raptor eyes under the brow ridges
var _seed_bursts: int = 0


## Seed Storm sparks played (tests / preview).
func seed_burst_count() -> int:
	return _seed_bursts


## Team colour -> the leaf surfaces (FlyerModel's membrane_tint instance uniform; no material duplicate).
func set_team_color(c: Color) -> void:
	if not _ready_done:
		_team_pending = c
		return
	_team_pending = null
	_tint = c
	_write_tint()


func _build_parts() -> void:
	_authored = 0
	_parts.clear()
	for side: int in 2:
		var sx := -1.0 if side == 0 else 1.0
		wing_axis[side] = (RM.mx(RM.ROOT_TRAIL, sx) - RM.mx(RM.SHOULDER, sx)).normalized()
		hand_axis[side] = (RM.mx(RM.WRIST_TRAIL, sx) - RM.mx(RM.WRIST, sx)).normalized()
	_add(P_BODY, BRM.body_mesh(), true, "BodyMesh")
	_add(P_NECK1, BRM.neck1_mesh(), false, "Neck1Mesh")
	_add(P_NECK2, BRM.neck2_mesh(), false, "Neck2Mesh")
	_head_gi = _add(P_HEAD, BRM.head_mesh(), true, "HeadMesh")
	_add(P_JAW, BRM.jaw_mesh(), false, "JawMesh")
	_add(P_WING_L, BRM.wing_arm_mesh(-1.0), true, "WingLMesh")
	_add(P_WING_L2, BRM.wing_hand_mesh(-1.0), true, "WingL2Mesh")
	_add(P_WING_R, BRM.wing_arm_mesh(1.0), true, "WingRMesh")
	_add(P_WING_R2, BRM.wing_hand_mesh(1.0), true, "WingR2Mesh")
	_add(P_TAIL1, BRM.tail_mesh(), false, "Tail1Mesh")
	_add(P_LEG_FL, BRM.leg_mesh(-1.0), false, "LegFLMesh")
	_add(P_LEG_FR, BRM.leg_mesh(1.0), false, "LegFRMesh")
	var beak := Node3D.new()
	beak.name = "Beak"
	add_pivot_node(P_HEAD, beak, RM.BEAK_TIP)
	_mouth = beak
	# Eyes (FaceKit beast face, face rework 2026-09-28): round amber raptor eyes on the skull sides whose lids glare on
	# the rake (fierce), widen on the swoop (shout) and droop when it falls (worried). The beak hides the mouth.
	var sc := Vector3(0.0, 4.60, 1.15)
	var hide := Color(0.36, 0.25, 0.15)
	_face = FaceKit.attach(self, _piv[P_HEAD], "briar_roc", NatureFaces.style({
		"center": sc, "radius": 0.21, "head_mesh": CharacterModel.sphere(1.0, 12, 6), "head_scale": Vector3(0.20, 0.19, 0.26),
		"head_at": sc, "preset": &"stern", "skin": hide, "eyes": Color(0.85, 0.55, 0.12), "detail": &"low",
		"x": NatureFaces.lean_x(1.15, {&"neutral": {"cut_in": 0.3}}),
		"palette": NatureFaces.beast_palette(hide, Color(0.85, 0.55, 0.12)).merged({"sclera": Color(0.95, 0.72, 0.22),
			"iris_in": Color(0.55, 0.30, 0.08), "iris_out": Color(0.25, 0.12, 0.04)}, true),
		"eye": {"c": Vector2(0.175, 0.020), "hw": 0.042, "top": 0.036, "bot": 0.032, "ir": 0.024, "pupil": 0.6, "tilt": 0.0},
		"brow": {"none": true}, "mouth": NatureFaces.beast_mouth(Vector2(0, -0.30)),
	}, Vector3(-0.12 * 180.0 / PI, 0, 0), 0.004))
	ensure_shadow_blob(BLOB_SIZE * BLOB_MULT, Color(0.05, 0.035, 0.02, 0.42))
	_authored += 1


func _on_revive() -> void:
	super()
	if _face:
		_face.reset()


func _after_ready() -> void:
	super()
	_seeds = get_node_or_null(^"Fx/Seeds") as GPUParticles3D


## The eyes are dark here: the head glow is the crest buds (flare on attack / cast), the body's the pod slits.
func _flare_weight(pi: int) -> float:
	return 1.0 if pi == P_HEAD or pi == P_BODY else 0.0


## Scales the bird (after the Roc's pose, before _apply) and keeps the blob at the smaller size.
func _extra_process(dt: float) -> void:
	super(dt)
	if _face:
		if _tier != 0 and not _dead:
			_face.far()
		else:
			_face.react(&"worried" if _dead else (&"fierce" if _action == &"attack" else (&"shout" if _action == &"cast" else &"")))
	_body_scale *= BODY_SCALE
	if _shadow:
		_shadow.scale = Vector3(_shadow.scale.x * BLOB_MULT, 1.0, _shadow.scale.z * BLOB_MULT)


## Talon rake from the air: the Roc's rake plus a long stoop (the Briar Roc strikes from 4 m): the bird lunges
## LUNGE_Z forward and down at the strike, talons thrown out, then climbs back.
func _pose_strike(prev: float, t: float) -> void:
	super(prev, t)
	var k := _tk(t, K_LUNGE)
	pos(P_ROOT, Vector3(0.0, -0.25 * k, LUNGE_Z * k))
	rot(P_LEG_FL, Vector3(-18.0 * k * DEG, 0.0, 0.0))
	rot(P_LEG_FR, Vector3(-18.0 * k * DEG, 0.0, 0.0))


func _on_action_event(ev: StringName) -> void:
	super(ev)
	if ev == &"impact":
		_seed_storm()


## The pod shakes open: seeds rain from the belly as green sparks (pre-built one-shot emitter, world space).
func _seed_storm() -> void:
	if _seeds == null or not is_inside_tree() or _piv[P_BODY] == null:
		return
	_seed_bursts += 1
	_seeds.global_position = _piv[P_BODY].global_position + Vector3(0, -0.25, 0)
	_seeds.restart()
