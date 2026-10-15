class_name IceSpireModel
extends SmallBuildingModel
## Ice tower "Rime Spire" (kingdom-ice.md 5 + 8.1: 1 x 1 cell = 2 x 2 m, height 5, the glow orb blinks on each shot).
## Task 7.V2, epic pass A2.4 in the Rime Keep's language. Read from the RTS camera: a hexagonal ice needle: a battered
## ice-stone shaft with three dark buttress fins, silver bands and cold-lit slits, a flared silver collar under a
## crown of six faceted team crystals leaning out around a glowing orb (three glow shards orbit it), and a floating
## team crystal needle spinning above (dominant vertical, 7.3 m). Asymmetric secondary: a jagged ice cluster erupting
## from the front-left of the hex plinth and a team pennant on an arm at the right. Frost patch on the ground.
## Hooks: SmallBuildingModel's plus play_shot() (the Tower script calls it on each shot): the orb flares (boost x3.5,
## +30 % size) for 0.1 s, then fades in 0.18 s, and the shards whirl. No active light (emissive + bloom only).
## Built Ice Walls on the next cell join it with a curtain (IceWallModel, group ANCHOR_GROUP).

const SHOT_HOLD := 0.1
const SHOT_FADE := 0.18
const ORB_Y := 4.9
const TIP_Y := 5.8
const FROST_GROUND: Shader = preload("res://art/buildings/ice/ice_frost_ground.gdshader")
const ANCHOR_GROUP := &"ice_wall_anchors"

var _m_snow: ShaderMaterial
var _slit_mat: ShaderMaterial
var _orb_mat: ShaderMaterial
var _banner_mat: ShaderMaterial
var _frost_mat: ShaderMaterial
var _orb: MeshInstance3D
var _halo: MultiMeshInstance3D
var _tip: MeshInstance3D
var _claws: MultiMeshInstance3D
var _orb_energy: float = 3.4
var _shot_left: float = 0.0
var _whirl: float = 0.0
var _tip_wobble: bool = false


func _setup() -> void:
	kingdom_color = Color(0.45, 0.75, 0.95)
	glow_color = Color(0.75, 0.92, 1.00)
	stone_color = Color(0.40, 0.49, 0.63)
	dark_color = Color(0.27, 0.31, 0.39)
	trim_color = Color(0.70, 0.78, 0.88)
	smoke_color = Color(0.25, 0.28, 0.34)
	blaze_a = Color(0.95, 1.0, 1.0)
	blaze_b = Color(0.45, 0.75, 1.0)
	stain_color = Color(0.85, 0.92, 1.00, 0.40)
	footprint = 2.0
	crack_strength = 0.45
	plinth_top = 0.42
	wreck_top = 1.25
	smoke_points = [Vector3(0.3, 2.6, 0.3)]
	blaze_points = [Vector3(-0.2, 3.4, -0.2)]


func _build_parts() -> void:
	var box1: Mesh = _box(Vector3.ONE)
	var mound: Mesh = IceShapes.mound()
	_m_snow = _painted_mat(Color(0.86, 0.92, 1.0), 0.15, 0.0)
	_m_team.set_shader_parameter(&"spec_strength", 0.5)
	_m_team.set_shader_parameter(&"crack_strength", 0.9)
	_m_team.set_shader_parameter(&"crack_scale", 1.2)
	_m_team.set_shader_parameter(&"crack_speed", 0.9)
	_m_stone.set_shader_parameter(&"crack_scale", 1.8)
	_slit_mat = _glow_mat(IceShapes.window_color(glow_color), 2.0, 1.3, false)   # G-B Ice: warm light inside the shaft
	# --- Plinth (never collapses): two hex dark tiers, snow drifts, the ice cluster erupting at the front-left.
	var it: Array = []
	it.append(_it(IceShapes.prism(1.08, 1.02, 0.3, 6), Vector3.ZERO, _m_dark))
	it.append(_it(IceShapes.prism(0.9, 0.87, 0.12, 6), Vector3(0, 0.3, 0), _m_dark))
	it.append(_it(mound, Vector3(0.95, 0.0, 0.7), _m_snow, Vector3(0, 20, 0), Vector3(0.36, 0.28, 0.5)))
	it.append(_it(mound, Vector3(-0.25, 0.0, 1.05), _m_snow, Vector3(0, -10, 0), Vector3(0.48, 0.24, 0.3)))
	for c: Array in [[Vector3(-0.72, 0.0, -0.55), Vector3(-1, 0, -0.7), 26.0, IceShapes.crystal(0.3, 1.0, 0.6, 0.0)],
			[Vector3(-0.22, 0.0, -0.92), Vector3(-0.3, 0, -1), 38.0, IceShapes.crystal(0.22, 0.6, 0.45, 0.0)],
			[Vector3(-0.98, 0.0, -0.05), Vector3(-1, 0, 0.15), 44.0, IceShapes.crystal(0.18, 0.4, 0.35, 0.0)]]:
		it.append(_itx(c[3], Transform3D(IceShapes.lean(c[1], c[2]), c[0]), _m_team))
	var plinth := _merged("Plinth", "plinth", it)
	plinth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # low plinth: no visible shadow of its own
	_no_collapse.append(plinth)
	# --- Shaft tier: battered hex shaft, base course, three buttress fins, two silver bands, three framed slits.
	it = []
	it.append(_it(IceShapes.prism(0.76, 0.76, 0.3, 6), Vector3(0, 0.42, 0), _m_dark))
	it.append(_it(IceShapes.prism(0.66, 0.5, 2.85, 6), Vector3(0, 0.42, 0), _m_stone))
	for a: float in [60.0, 180.0, 300.0]:
		var d := Vector3(cos(deg_to_rad(a)), 0.0, sin(deg_to_rad(a)))
		it.append(_itx(_prism(Vector3(0.62, 1.4, 0.3), 0.0), Transform3D(Basis(Vector3.UP, atan2(-d.z, d.x)),
			d * 0.86 + Vector3(0, 1.12, 0)), _m_dark))
	it.append(_it(IceShapes.prism(0.64, 0.64, 0.18, 6), Vector3(0, 1.35, 0), _m_trim))
	it.append(_it(IceShapes.prism(0.56, 0.56, 0.2, 6), Vector3(0, 3.05, 0), _m_trim))
	for a: float in [270.0, 30.0, 150.0]:
		var d := Vector3(cos(deg_to_rad(a)), 0.0, sin(deg_to_rad(a)))
		var yb := Basis(Vector3.UP, atan2(d.x, d.z))
		it.append(_itx(box1, Transform3D(yb.scaled_local(Vector3(0.26, 0.82, 0.06)), d * 0.55 + Vector3(0, 2.25, 0)), _m_dark))
		it.append(_itx(box1, Transform3D(yb.scaled_local(Vector3(0.12, 0.6, 0.06)), d * 0.575 + Vector3(0, 2.25, 0)),
			_slit_mat))
	_merged("Shaft", "shaft", it)
	# --- Crown tier: flared silver collar, snowy rim, the pennant arm.
	it = []
	it.append(_it(IceShapes.prism(0.56, 0.8, 0.42, 6), Vector3(0, 3.27, 0), _m_trim))
	it.append(_it(IceShapes.prism(0.84, 0.84, 0.1, 6), Vector3(0, 3.66, 0), _m_trim))
	it.append(_it(IceShapes.prism(0.8, 0.7, 0.1, 6), Vector3(0, 3.74, 0), _m_snow))
	it.append(_it(box1, Vector3(0.98, 3.52, 0.0), _m_trim, Vector3.ZERO, Vector3(0.62, 0.1, 0.1)))
	it.append(_it(IceShapes.crystal(0.08, 0.05, 0.2, 0.1), Vector3(1.3, 3.5, 0.0), _m_team))
	var crown := _merged("Crown", "crown", it)
	# Six crystal claws leaning out around the orb, tall and short in turn (one breaks off under 50 % HP).
	var cx: Array[Transform3D] = []
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0 + PI / 6.0
		var dir := Vector3(cos(a), 0.0, sin(a))
		var tall: float = 1.0 if i % 2 == 0 else 0.72
		var b: Basis = IceShapes.lean(dir, 22.0) * Basis(Vector3.UP, -a) * Basis.from_scale(Vector3(1.0, tall, 1.0))
		cx.append(Transform3D(b, dir * 0.55 + Vector3(0, 3.76, 0)))
	_claws = _multi("Claws", IceShapes.crystal(0.17, 0.75, 0.5, 0.0), _m_team, cx)
	# Orb (team glow), three orbiting glow shards, the floating needle tip (team crystal).
	_orb_mat = _glow_mat(glow_color, _orb_energy, 3.0, true)
	_orb = _part("Orb", _sphere(0.3), _orb_mat, Vector3(0, ORB_Y, 0))
	_floaters.append(_orb)
	var hx: Array[Transform3D] = []
	for i: int in 3:
		var a: float = TAU * float(i) / 3.0
		hx.append(Transform3D(Basis(Vector3.RIGHT, 0.35), Vector3(cos(a), 0.0, sin(a)) * 0.58))
	_halo = _multi("Halo", IceShapes.crystal(0.09, 0.12, 0.18, 0.18), _glow_mat(glow_color, 2.8, 2.0, true), hx)
	_halo.position = Vector3(0, ORB_Y, 0)
	_floaters.append(_halo)
	_tip = _part("NeedleTip", IceShapes.crystal(0.24, 0.45, 1.05, 0.45), _m_team, Vector3(0, TIP_Y, 0))
	_floaters.append(_tip)
	# Team pennant hanging from the arm.
	_banner_mat = IceShapes.banner_material(kingdom_color)
	var pen := _part("Pennant", IceShapes.banner_mesh(Vector2(0.46, 1.2)), _banner_mat, Vector3(1.04, 2.88, 0.0))
	pen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pen.set_instance_shader_parameter(&"phase", randf() * TAU)
	_hide_on_collapse.append_array([crown, _claws, pen])
	_build_scaffold(2.3, 4.4, [2.0, 3.7] as Array[float])
	_build_wreck(0.72, 1.3, _slit_mat, 2027, 4)
	var mo := _pm(Vector3.DOWN, 60.0, 0.2, 0.5, Vector3(0, -0.3, 0), 0.08, 0.03,
		_ramp(Color(0.9, 0.97, 1.0), Color(0.55, 0.8, 1.0), false))
	mo.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mo.emission_sphere_radius = 0.5
	_idle_particles("FrostMotes", Vector3(0, ORB_Y, 0), 10, 1.6, mo, true)


## Frost patch (ice_frost_ground.gdshader) instead of the plain stain, on a 5 m quad.
func _build_ground() -> void:
	super()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.0, 5.0)
	_decal.mesh = pm
	_frost_mat = ShaderMaterial.new()
	_frost_mat.shader = FROST_GROUND
	_frost_mat.set_shader_parameter(&"size", 5.0)
	_frost_mat.set_shader_parameter(&"plinth_half", 1.1)
	_frost_mat.set_shader_parameter(&"roundness", 1.0)
	_frost_mat.set_shader_parameter(&"sectors", 10.0)
	_frost_mat.set_shader_parameter(&"seed", 4.1)
	_frost_mat.set_shader_parameter(&"glow_color", glow_color)
	_decal.material_override = _frost_mat


# --- Tower hook ---

## The tower fired: the orb flares (boost x3.5, +30 % size) for 0.1 s, then fades in 0.18 s; the shards whirl.
func play_shot() -> void:
	if _destroyed or _progress < 1.0:
		return
	_shot_left = SHOT_HOLD + SHOT_FADE
	_whirl = 1.0


## Wall joints (IceWallModel): a finished, standing spire.
func is_joinable() -> bool:
	return _ready_done and not _destroyed and _progress >= 1.0 and is_inside_tree()


## Wall joints: the team colour walls compare with.
func joint_color() -> Color:
	return _team_color


# --- Overrides ---

func _enter_tree() -> void:
	add_to_group(ANCHOR_GROUP)


func _exit_tree() -> void:
	remove_from_group(ANCHOR_GROUP)
	IceWallModel.refresh_around(self)


func _idle(delta: float) -> void:
	var k: float = 0.0
	if _shot_left > 0.0:
		_shot_left = maxf(_shot_left - delta, 0.0)
		k = 1.0 if _shot_left > SHOT_FADE else _shot_left / SHOT_FADE
		_orb_mat.set_shader_parameter(&"boost", _sel_boost() * (1.0 + 2.5 * k))
		if _shot_left <= 0.0:
			_orb_mat.set_shader_parameter(&"boost", _sel_boost())
	_orb.position.y = ORB_Y + 0.08 * sin(_t * 2.2)
	if _float_appear >= 1.0:
		_orb.scale = Vector3.ONE * (1.0 + 0.3 * k)
	_whirl = maxf(_whirl - delta * 1.5, 0.0)
	_halo.rotate_y(deg_to_rad(50.0 + 500.0 * _whirl) * delta)
	_halo.position.y = _orb.position.y
	var wob: float = 0.12 if _tip_wobble else 0.0
	_tip.position.y = TIP_Y + 0.1 * sin(_t * 1.5)
	_tip.rotation = Vector3(wob * sin(_t * 9.0), _tip.rotation.y - deg_to_rad(30.0) * delta, wob * cos(_t * 7.0))


func _on_progress(_building: bool) -> void:
	IceWallModel.refresh_around(self)


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	# Below 50 % one crown crystal breaks off; below 25 % the orb dims and the needle wobbles.
	_claws.multimesh.visible_instance_count = _claws.multimesh.instance_count - 1 if smoke_on else -1
	_orb_mat.set_shader_parameter(&"energy", _orb_energy * 0.55 if fire_on else _orb_energy)
	_tip_wobble = fire_on
	if _frost_mat:
		_frost_mat.set_shader_parameter(&"damage", 1.0 if fire_on else (0.5 if smoke_on else 0.0))


func _on_team_color(g: Color) -> void:
	IceShapes.tint_banner(_banner_mat, _team_color, kingdom_color, g)


func _on_destroy_start() -> void:
	_shot_left = 0.0
	IceWallModel.refresh_around(self)


## G-B Ice: every painted part draws with the Ice paint layer (per part: the spire is not vertex-merged).
func _post_build() -> void:
	IceShapes.ice_part(_m_stone, IceShapes.K_STONE)
	IceShapes.ice_part(_m_dark, IceShapes.K_DARK)
	IceShapes.ice_part(_m_trim, IceShapes.K_METAL)
	IceShapes.ice_part(_m_team, IceShapes.K_ICE)
	IceShapes.ice_part(_m_snow, IceShapes.K_SNOW)


## The keep's cold idle rim instead of the base one (selection still turns it to the team colour).
func _apply_rim_and_glow() -> void:
	super()
	if _ready_done and _body != null:
		IceShapes.apply_ice_rim(_painted, _team_color, _sel_k, _progress < 1.0 and not _destroyed)
