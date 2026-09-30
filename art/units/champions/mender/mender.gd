extends CharacterModel
## The Mender (Orla Fenwick / Osric Fenwick), hired healer champion. Task 9.V4, champions.md 4.6, art-units.md.
## Look: a ROUND, jolly field-apothecary: herb-green dress under a linen apron, rolled linen sleeves, a linen kerchief
## over chestnut hair, a big oval WICKER BACKPACK stacked with glowing potion jars (a lashed tower of four jars, herb
## sprigs, a bedroll, a hanging pot) and a crook STAFF from which a copper CENSER-KETTLE hangs on a chain; the kettle
## glows green through its pierced belly, its lid vents and the slit under the lid, and steams from the spout.
## Team colour: only the waist SASH (knot + tails) and the small swallow-tailed PENNANT on a pole behind the pack
## (mender_cloth / mender_cloth_dark / mender_pennon, recoloured by the kit's set_team_color, cached per colour).
## Variant B = ONE toggled node `Variant` under Head whose mesh is swapped: 0 Orla = hair bun with a herb sprig,
## 1 Osric = bushy beard, moustache and brows. Same scene, same everything else.
## Glow points: the censer (0.5, 1.0, 0.6) 1.5 with a pulse (+ flares on attacks / casts), the jars 1.5.
## The kettle is a real damped pendulum (model frame, driven by the hook's acceleration): it swings when she walks,
## turns, jabs or falls; casts take it over and swing it in circles, then hand it back to the physics.
## Attack `staff` (attack_windup 0.14): the staff snaps forward like a lance, the censer flies toward the target and
## puffs (the bolt starts at get_beam_origin()). Casts (play_cast): mending_draught (one quick circle, the free hand
## tosses a draught), soothing_circle (staff raised overhead, two wide circles, plants it), lifeline (one slow circle,
## then the staff is thrust at the ally). Unknown ids play mending_draught. Walk = the kit's with a round waddle.
## Budget (test_9_v4.gd): 24 authored meshes, 15 draw instances after the merge (7 merged pivots + Jars, Variant,
## StaffMesh, Kettle, Core, Steam, Burst, Shadow), 0 lights, 5 own materials (+ the kit's shared blob material).
## Every painted part uses ONE material (mender_painted.gdshader): colour = palette index in UV.x, surface mode in
## UV.y (the kit merge keeps UVs). Glows use mender_glow.gdshader (colour index in UV.x, pulse phase in UV.y).
## Hooks: the CharacterModel ones + set_variant(v: int), play_cast(ability_id), get_beam_origin() -> Vector3,
## authored_mesh_count() -> int, set_cast_point(point) (optional, the jar's landing spot).
## Champion classes (task 11.V5, skills-rework.md 5): the censer staff (`Staff`, with its kettle, core and steam) is the
## archetype weapon, hidden by the kit once a class is drawn; the wicker backpack with its jars, the apron and the
## pennant stay. Grips: hand_r = GRIP (the staff fist), hand_l = HAND_L, the spear's quiver is lashed to the LEFT side
## of the backpack (the javelin hand reaches it). With a class weapon: no censer puff / swing; get_beam_origin() = the
## weapon tip; Mending Draught = a draught pulled from the apron pouch, uncorked and tossed; Soothing Circle = a jar
## pulled from the pack over the shoulder and thrown overhand to the circle's centre (Jar node, reparented to Fx while
## it flies, shatters in a green puff); Lifeline = the free hand reaches for the ally while the weapon is raised (each
## weapon its own way). The kit plays the 4 class attack styles and the 12 class skills.

const DIR := "res://art/units/champions/mender/"

# ---- palette indices (mender_painted.gdshader PAL) and surface modes
const LINEN := 0
const WICKER := 1
const HERB := 2
const SKIN := 3
const LEATHER := 4
const COPPER := 5
const WOOD := 6
const HAIR := 7
const EYE := 8
const CORK := 9
const WICKER_DARK := 10
const HERB_DARK := 11
const LEAF := 12
const IRON := 13
const BLUSH := 14
const RUST := 15
const LINEN_SH := 16
const BRASS := 17
const GREY := 18
const SOLE := 19
const M_CLOTH := 0.0
const M_WICKER := 1.0
const M_METAL := 2.0
const M_HAIR := 3.0
const M_WOOD := 4.0
const M_SKIN := 5.0
# ---- glow colours (mender_glow.gdshader GLOW)
const G_GREEN := 0
const G_AMBER := 1
const G_ROSE := 2
const G_BLUE := 3
const GLOW_GREEN := Color(0.5, 1.0, 0.6)
const HERB_LEAF := Color(0.46, 0.66, 0.30)

const BODY_Z := 0.92                          # depth squash of the round body (keeps the pack inside 1.4 x radius)
const SKIRT_Z := 0.95
const GRIP := Vector3(0.535, 0.94, 0.22)      # model space: right fist = pivot of the Staff node
const CROOK_DIR := Vector3(0.819, 0.0, 0.574)  # the crook curls 55 deg outward from the face side (kettle clear of
                                              # the shoulder in the RTS view)
const CROOK_C := Vector3(0.090, 1.33, 0.063)  # staff space: centre of the crook arc (staff 2.2 m, top at 2.27)
const CROOK_R := 0.11
const HOOK := Vector3(0.172, 1.245, 0.12)     # staff space: where the chain hangs (under the crook tip)
const KETTLE_UP := 0.06                       # the kettle is built 0.06 higher than its authoring numbers (short chain)
const KETTLE_C := Vector3(0.0, -0.36, 0.0)    # censer space: kettle belly centre
const SPOUT := Vector3(0.0, -0.245, 0.31)     # censer space: spout tip
const PEND_L := 0.36                          # pendulum length (m)
const PEND_DAMP := 2.2
const JAB_LEN := 0.5
# ---- champion class weapons (11.V5), model space, rest pose
const HAND_L := Vector3(-0.55, 0.78, 0.125)   # left fist centre (the hand sphere of _geo_arm)
## Back quiver lashed upright to the left side of the wicker pack, top leaning out (clear of the bedroll and the jars).
const QUIVER_AT := Vector3(-0.42, 1.28, -0.50)
const QUIVER_ROT := Vector3(-6.0, 0.0, 8.0)
const JAR_IN_HAND := Vector3(0.0, -0.10, 0.04)   # jar centre from the left fist (sits in the palm)
const JAR_DIST := {&"soothing_circle": 5.0, &"mending_draught": 3.0}   # default throw distance (m) without a point
const JAR_LAND_Y := {&"soothing_circle": 0.08, &"mending_draught": 1.0}  # lands on the ground / breaks over the ally
# Class Soothing Circle (jar throw): keyframes, times s, values deg / m (smooth between keys).
const JT_T: Array[float] = [0.0, 0.20, 0.30, 0.42, 0.52, 0.72, 1.15]
const JT_LX: Array[float] = [0.0, -205.0, -216.0, -205.0, -62.0, -42.0, 0.0]
const JT_LZ: Array[float] = [0.0, 10.0, 14.0, 10.0, -8.0, -5.0, 0.0]
const JT_RX: Array[float] = [0.0, 8.0, 10.0, 10.0, -6.0, -3.0, 0.0]
const JT_RZ: Array[float] = [0.0, 10.0, 14.0, 16.0, 6.0, 4.0, 0.0]
const JT_CX: Array[float] = [0.0, -6.0, -10.0, -12.0, 12.0, 8.0, 0.0]
const JT_CY: Array[float] = [0.0, -14.0, -24.0, -26.0, 24.0, 18.0, 0.0]
const JT_HX: Array[float] = [0.0, -10.0, -12.0, -14.0, 6.0, 4.0, 0.0]
const JT_BZ: Array[float] = [0.0, -0.03, -0.05, -0.06, 0.10, 0.08, 0.0]
const JT_BY: Array[float] = [0.0, 0.0, 0.0, -0.02, -0.05, -0.04, 0.0]
const JT_GL: Array[float] = [0.0, 0.0, -2.0, -4.0, 14.0, 12.0, 0.0]
const JT_GR: Array[float] = [0.0, 0.0, 4.0, 6.0, -22.0, -18.0, 0.0]
const JT_GRAB := 0.22      # the jar comes out of the pack
const JT_RELEASE := 0.48
# Class Mending Draught: the draught from the apron pouch, uncorked at the chest, tossed underhand.
const MD_T: Array[float] = [0.0, 0.12, 0.28, 0.42, 0.52, 0.80]
const MD_LX: Array[float] = [0.0, 28.0, -45.0, -85.0, -70.0, 0.0]
const MD_LZ: Array[float] = [0.0, -10.0, 22.0, 6.0, 4.0, 0.0]
const MD_CX: Array[float] = [0.0, 0.0, 4.0, 6.0, 4.0, 0.0]
const MD_CY: Array[float] = [0.0, -12.0, 8.0, 14.0, 10.0, 0.0]
const MD_HX: Array[float] = [0.0, 6.0, 4.0, -6.0, -4.0, 0.0]
const MD_GRAB := 0.14
const MD_RELEASE := 0.42
# Class Lifeline: the free hand reaches out to the ally (burst at 0.52), the weapon raised.
const LL_T: Array[float] = [0.0, 0.18, 0.45, 0.52, 0.70, 0.95]
const LL_LX: Array[float] = [0.0, -40.0, -95.0, -92.0, -88.0, 0.0]
const LL_LP: Array[float] = [0.0, 0.0, 0.08, 0.12, 0.10, 0.0]
const LL_CX: Array[float] = [0.0, -4.0, 8.0, 9.0, 6.0, 0.0]
const LL_BZ: Array[float] = [0.0, 0.0, 0.06, 0.08, 0.06, 0.0]
const LL_BURST := 0.52

@export_range(0, 1) var variant: int = 0:
	set(v):
		variant = clampi(v, 0, 1)
		if _variant_node:
			_variant_node.mesh = _variant_mesh(variant)
		ChampionFaces.switch(_face, "mender", _face_spec, variant)

static var _meshes: Dictionary = {}
static var _burst_res: Dictionary = {}

var _authored: int = 0
## Painted face (FaceKit via ChampionFaces, faces pass 2026-09-28): eyes, brows, lips, expressions.
var _face: FaceRig
var _staff: Node3D
var _censer: Node3D
var _kettle: MeshInstance3D
var _core: MeshInstance3D
var _jars: MeshInstance3D
var _variant_node: MeshInstance3D
var _burst: GPUParticles3D
var _steam: GPUParticles3D

# per-frame pose targets (written by the poses, applied and reset in _extra_process)
var _staff_rot: Vector3 = Vector3.ZERO
var _staff_written: Vector3 = Vector3(99, 99, 99)
var _circle_on: bool = false
var _circle_th: Vector2 = Vector2.ZERO
var _flare: float = 0.0
var _core_written: float = -1.0
var _cast_prev: float = 0.0
# censer pendulum (model frame: x = right, y = forward; value = tan of the tilt)
var _th: Vector2 = Vector2.ZERO
var _th_v: Vector2 = Vector2.ZERO
var _hook_prev: Vector3 = Vector3.ZERO
var _hook_vel: Vector3 = Vector3.ZERO
var _hook_init: bool = false
# class casts (11.V5): the thrown jar / draught
enum { JAR_OFF, JAR_HELD, JAR_FLYING }
var _jar: MeshInstance3D
var _jar_mode: int = JAR_OFF
var _jar_hold_req: bool = false
var _jar_u: float = 0.0
var _jar_dur: float = 0.4
var _jar_from: Vector3 = Vector3.ZERO
var _jar_to: Vector3 = Vector3.ZERO
var _jar_apex: float = 0.5
var _jar_spin: float = 0.0
var _jar_rest: Transform3D = Transform3D.IDENTITY   # the jar in the left fist (ArmL space)
var _hand_l_local: Vector3 = Vector3.ZERO           # the left fist (ArmL space)
var _cast_point: Variant = null        # world point of the cast in progress (set_cast_point), null = default
var _cast_point_frame: int = -100


# ================================================================ public hooks (champions.md 13 / step9 rules 4)

## 0 = Orla (hair bun), 1 = Osric (beard). Safe before _ready.
func set_variant(v: int) -> void:
	variant = v


## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout").
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


## World position of the censer core: where the attack bolt and the heal effects start. With a class weapon (the
## censer is hidden then): the weapon's working end (the Wizard staff crystal, the spear / sword tip).
func get_beam_origin() -> Vector3:
	if weapon_class() != &"":
		var tip: Variant = get_weapon_tip()
		if tip is Vector3:
			return tip
		return global_position + Vector3(0.5, 1.5, 0.45)
	if _censer and _censer.is_inside_tree():
		return _censer.global_transform * (KETTLE_C + Vector3(0, 0.1, 0))
	return global_position + Vector3(0.5, 1.5, 0.45)


## Optional: the world point (Vector3, or a Node3D's position) of the cast about to play or playing. With a class
## weapon the Soothing Circle jar lands there and the Mending Draught breaks over it; call it right before or after
## play_cast. Without it the jar flies JAR_DIST straight ahead.
func set_cast_point(point: Variant) -> void:
	if point is Node3D and is_instance_valid(point) and (point as Node3D).is_inside_tree():
		_cast_point = (point as Node3D).global_position
	elif point is Vector3:
		_cast_point = point
	else:
		_cast_point = null
	_cast_point_frame = Engine.get_process_frames()


## Authored mesh parts of this model (every add_part call + the parts made by hand), before the merge.
func authored_mesh_count() -> int:
	return _authored


func add_part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored += 1
	return super.add_part(pivot, mesh, mat, model_pos, rot_deg, scl, keep_separate, part_name)


## A glow mesh (UV.x = glow colour, UV.y = pulse phase: the old mender_glow layout) as mode 6 of mender_painted: UV.y
## = 6 +- 0.45 carries the phase. Cached per key.
static func _as_glow_paint(key: String, mesh: Mesh) -> Mesh:
	var ck := "glowpaint_" + key
	if _meshes.has(ck):
		return _meshes[ck]
	var am := ArrayMesh.new()
	for s: int in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		for i: int in uv.size():
			uv[i] = Vector2(uv[i].x, 6.0 + (fposmod(uv[i].y / 3.0, 1.0) - 0.5) * 0.9)
		arr[Mesh.ARRAY_TEX_UV] = uv
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		am.surface_set_material(s, _mat(&"mender_painted"))
	_meshes[ck] = am
	return am


## A team-cloth mesh (sash, trim) for the pennant's banner material: every UV = (0, v) so it draws flat cloth_color
## (no stripe / glyph, a still edge: banner.gdshader waves by UV.y). Cached per key.
static func _as_team_cloth(key: String, mesh: Mesh, v: float) -> Mesh:
	var ck := "teamcloth_" + key
	if _meshes.has(ck):
		return _meshes[ck]
	var am := ArrayMesh.new()
	for s: int in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		for i: int in uv.size():
			uv[i] = Vector2(0.0, v)
		arr[Mesh.ARRAY_TEX_UV] = uv
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_meshes[ck] = am
	return am


static func _mat(name: StringName) -> Material:
	var key := "mat_" + String(name)
	if not _meshes.has(key):
		_meshes[key] = load(DIR + String(name) + ".tres")
	return _meshes[key]


# ================================================================ build

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var paint := _mat(&"mender_painted")
	# B8 material merge (in-game grade 2026-09-30): the glows are mode 6 of mender_painted (_as_glow_paint) and the team
	# sash + trim draw with the pennant's banner material as flat team cloth (_as_team_cloth): painted + pennon + face +
	# motes + blob = 5 materials (was 9: mender_glow, mender_cloth, mender_cloth_dark, 2 mote materials).
	var team := _mat(&"mender_pennon")

	# Hips: herb-green skirt with a dark rolled hem and soft folds, the linen apron skirt (pocket + pestle), a pouch.
	add_part(hips, _m("skirt", _geo_skirt), paint, Vector3.ZERO)
	add_part(hips, _m("apron", _geo_apron), paint, Vector3.ZERO)
	add_part(hips, _m("pouch", _geo_pouch), paint, Vector3.ZERO)
	add_part(leg_l, _m("leg_l", _geo_leg.bind(-1.0)), paint, Vector3.ZERO)
	add_part(leg_r, _m("leg_r", _geo_leg.bind(1.0)), paint, Vector3.ZERO)

	# Chest: round bodice + blouse, apron bib, team sash, the wicker backpack with its load, the pennant.
	add_part(chest, _m("torso", _geo_torso), paint, Vector3.ZERO)
	add_part(chest, _m("bib", _geo_bib), paint, Vector3.ZERO)
	add_part(chest, _as_team_cloth("sash", _m("sash", _geo_sash), 0.12), team, Vector3.ZERO)
	add_part(chest, _as_team_cloth("sash_trim", _m("sash_trim", _geo_sash_trim), 0.0), team, Vector3.ZERO)
	add_part(chest, _m("basket", _geo_basket), paint, Vector3.ZERO)
	add_part(chest, _m("jar_caps", _geo_jar_caps), paint, Vector3.ZERO)
	add_part(chest, _m("pack_load", _geo_pack_load), paint, Vector3.ZERO)
	add_part(chest, _m("pole", _geo_pole), paint, Vector3.ZERO)
	add_part(chest, cape(0.24, 0.38), _mat(&"mender_pennon"), Vector3(0.405, 2.13, -0.60), Vector3(0, 0, 90))
	_jars = add_part(chest, _as_glow_paint("jars", _m("jars", _geo_jars)), paint, Vector3.ZERO, Vector3.ZERO, Vector3.ONE,
		true, "Jars")

	# Head: round face (nose, cheeks), hair under a linen kerchief, the variant piece; eyes / brows / lips = FaceKit.
	add_part(head, _m("face", _geo_face), paint, Vector3.ZERO)
	add_part(head, _m("hair", _geo_hair), paint, Vector3.ZERO)
	_variant_node = add_part(head, _variant_mesh(variant), paint, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Variant")
	_face = ChampionFaces.attach(self, head, "mender", _face_spec, variant)

	# Arms: linen puff sleeves rolled at the elbow, bare forearms, round hands.
	add_part(arm_l, _m("arm_l", _geo_arm.bind(-1.0)), paint, Vector3.ZERO)
	add_part(arm_r, _m("arm_r", _geo_arm.bind(1.0)), paint, Vector3.ZERO)

	# Staff (own pivot at the fist so poses can raise / level it) with the censer hanging from the crook.
	_staff = Node3D.new()
	_staff.name = "Staff"
	_staff.set_meta(&"keep_separate", true)
	_staff.position = GRIP - model_origin(arm_r)
	arm_r.add_child(_staff)
	# The censer staff is the archetype weapon: the kit hides the whole node (kettle, core, steam) once a class is drawn.
	mark_archetype_weapon(_staff)
	var sm := MeshInstance3D.new()
	sm.name = "StaffMesh"
	sm.mesh = _m("staff", _geo_staff)
	sm.material_override = paint
	sm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sm.set_meta(&"keep_separate", true)
	_staff.add_child(sm)
	_authored += 1
	_censer = Node3D.new()
	_censer.name = "Censer"
	_censer.position = HOOK
	_staff.add_child(_censer)
	_kettle = MeshInstance3D.new()
	_kettle.name = "Kettle"
	_kettle.mesh = _m("kettle", _geo_kettle)
	_kettle.material_override = paint
	_kettle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_kettle.set_meta(&"keep_separate", true)
	_censer.add_child(_kettle)
	_authored += 1
	_core = MeshInstance3D.new()
	_core.name = "Core"
	_core.mesh = _as_glow_paint("core", _m("core", _geo_core))
	_core.material_override = paint
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_core.set_meta(&"keep_separate", true)
	_core.set_meta(&"own_glow", true)
	_censer.add_child(_core)
	_authored += 1
	# Steam from the spout (looping, the kit stops it beyond 45 m).
	_steam = make_motes(GLOW_GREEN, 6, 1.5, 0.025, 0.32, 0.08)
	_steam.name = "Steam"
	ChampionPalette.share_motes("mender", _steam)
	_steam.position = SPOUT
	_censer.add_child(_steam)
	# One pre-built one-shot emitter for every burst: green puff at the kettle (attack / casts / level-up) and a
	# spill of herb leaves from the pack on death (mode swapped, same amount so nothing is reallocated).
	_burst = make_motes(GLOW_GREEN, 12, 0.7, 0.12, 1.3, 0.13, false, true)
	_burst.name = "Burst"
	ChampionPalette.share_motes("mender", _burst)
	_burst.visibility_aabb = AABB(Vector3(-2.5, -2.5, -2.5), Vector3(5, 5, 5))
	$Fx.add_child(_burst)
	_cache_burst_modes()
	ensure_shadow_blob(0.5)
	_authored += 1
	# The jar / draught of the class casts: one small bottle (glowing contents + cork), in the left fist, shown only by
	# the class Mending Draught and Soothing Circle poses; it flies under Fx.
	_jar = add_part(arm_l, _jar_mesh(), null, HAND_L + JAR_IN_HAND, Vector3.ZERO, Vector3.ONE, true, "Jar")
	_jar.visible = false
	_jar_rest = _jar.transform
	_hand_l_local = HAND_L - model_origin(arm_l)


func _after_ready() -> void:
	# The kit flashes only the merged Chest / Head / ArmR on hits: add the separate painted parts that read as body.
	for gi: GeometryInstance3D in [_variant_node, _kettle, _staff.get_node(^"StaffMesh") as GeometryInstance3D]:
		if gi and not _flash_hit_targets.has(gi):
			_flash_hit_targets.append(gi)
	_variant_node.mesh = _variant_mesh(variant)
	_hook_init = false


func _variant_mesh(v: int) -> Mesh:
	return _m("beard", _geo_beard) if v == 1 else _m("bun", _geo_bun)


# ================================================================ champion class weapons (11.V5)

## Her own fists (constant per scene): the right one is the censer staff's grip, the left one the hand sphere.
func _weapon_slot(slot: StringName) -> Transform3D:
	match slot:
		&"hand_r":
			return Transform3D(Basis.IDENTITY, GRIP)
		&"hand_l":
			return Transform3D(Basis.IDENTITY, HAND_L)
		&"back":
			return Transform3D(Basis.IDENTITY, QUIVER_AT)
	return super._weapon_slot(slot)


## The quiver can't go behind the round wicker pack (it fills her back): it is lashed upright to the pack's left side.
func _weapon_grip(piece: StringName) -> Transform3D:
	match piece:
		&"quiver":
			return Transform3D(Basis.from_euler(QUIVER_ROT * DEG), QUIVER_AT)
		&"spear":
			# the generic hold (tip forward, 30 deg up) turned 20 deg outward: the blade and tassel clear her round face
			return _weapon_slot(&"hand_r") * Transform3D(Basis(Vector3.UP, 20.0 * DEG) * Basis(Vector3.RIGHT, 60.0 * DEG),
				Vector3(0.02, 0.0, 0.0))
		&"sword":
			# held at the ready, point 15 deg down (not 30): the blade clears her round skirt and reads from above
			return _weapon_slot(&"hand_r") * Transform3D(Basis(Vector3.UP, 8.0 * DEG) * Basis(Vector3.RIGHT, 105.0 * DEG),
				Vector3.ZERO)
	return super._weapon_grip(piece)


func _on_weapon_class(class_id: StringName) -> void:
	ChampionPalette.claim_crystal_glow(self, class_id)   # the staff crystal glow (mender_painted has a glow mode now)
	# The censer (hidden with the staff for a class) restarts from rest when it comes back; its steam stops while hidden.
	_staff_rot = Vector3.ZERO
	_staff_written = Vector3(99, 99, 99)
	_circle_on = false
	_th = Vector2.ZERO
	_th_v = Vector2.ZERO
	_hook_init = false
	_flare = 0.0
	if _steam:
		_steam.emitting = class_id == &"" and _tier < 2
	_jar_reset()


# ================================================================ burst modes

func _cache_burst_modes() -> void:
	if not _burst_res.has("puff"):
		_burst_res["puff"] = [_burst.process_material, _burst.draw_pass_1, 0.7, 0.9]
		var p := NatureModel.make_petals(HERB_LEAF, 12, 1.3, 0.35, 1.2, 0.15, true)
		_burst_res["herbs"] = [p.process_material, p.draw_pass_1, 1.3, 0.85]
		p.free()


func _fire_burst(mode: String, model_pos: Vector3) -> void:
	if _burst == null or _tier >= 2:
		return
	var r: Array = _burst_res[mode]
	if _burst.process_material != r[0]:
		_burst.process_material = r[0]
		_burst.draw_pass_1 = r[1]
		_burst.lifetime = r[2]
		_burst.explosiveness = r[3]
	_burst.position = model_pos
	_burst.restart()


# ================================================================ animation

func _pose_walk(w: float, rate: float) -> void:
	super._pose_walk(w, rate)
	# Round waddle: the whole body rolls over the stepping foot, a little yaw with it.
	var s := sin(TAU * _walk_p)
	rot(P_ROOT, Vector3(0, 3.0 * DEG * s * w, 3.5 * DEG * s * w))


## Attack `staff`: cock back, then the staff snaps forward like a lance (release at attack_windup: puff + bolt).
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"staff":
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else 0.14
	var t2 := w + 0.03
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.07, t2, JAB_LEN, 12.0, -38.0) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, 0, _k3(t, 0.0, 0.07, t2, JAB_LEN, -0.05, 0.14)))
	_staff_rot.x += _k3(t, 0.0, 0.07, t2, JAB_LEN, -14.0, 92.0) * DEG
	rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.07, t2, JAB_LEN, -10.0, 22.0) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.07, t2, JAB_LEN, -5.0, 8.0) * DEG, _k3(t, 0.0, 0.07, t2, JAB_LEN, 12.0, -14.0) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _k3(t, 0.0, 0.07, t2, JAB_LEN, -0.04, 0.10)))
	if t < w:
		_flare = maxf(_flare, 0.5 * t / w)
	if prev < w and t >= w:
		_on_action_event(&"release")
	return t < JAB_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	if weapon_class() != &"":
		return _pose_cast_class(spell, t)
	var length: float
	var burst_at: float
	match spell:
		&"soothing_circle":
			length = 1.2
			burst_at = 0.9
			var k := _k3(t, 0.0, 0.22, 0.86, 1.2, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-125.0 * DEG * k, 0, 0))
			_staff_rot.x += 118.0 * DEG * k
			rot(P_ARM_L, Vector3(-30.0 * DEG * k, 0, -35.0 * DEG * k))
			rot(P_HEAD, Vector3(-14.0 * DEG * k, 0, 0))
			rot(P_CHEST, Vector3(-5.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, _k3(t, 0.86, 0.96, 1.02, 1.2, -0.07, -0.07), 0))
			_circle(t, 0.14, 0.9, 2.0, 74.0, PI)
			_flare = maxf(_flare, _k3(t, 0.1, 0.4, 0.92, 1.2, 0.7, 1.0))
		&"lifeline":
			length = 0.95
			burst_at = 0.52
			rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.18, 0.52, 0.95, -85.0, -45.0) * DEG, 0, 0))
			_staff_rot.x += _k3(t, 0.0, 0.18, 0.52, 0.95, 78.0, 112.0) * DEG
			pos(P_ARM_R, Vector3(0, 0, _k3(t, 0.40, 0.52, 0.62, 0.95, 0.16, 0.16)))
			rot(P_ARM_L, Vector3(_k3(t, 0.15, 0.45, 0.65, 0.95, -40.0, -88.0) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_k3(t, 0.3, 0.52, 0.65, 0.95, 0.0, 9.0) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0, _k3(t, 0.4, 0.52, 0.65, 0.95, 0.08, 0.08)))
			_circle(t, 0.04, 0.5, 1.0, 56.0, PI * 0.5)
			_flare = maxf(_flare, _k3(t, 0.05, 0.3, 0.6, 0.95, 0.6, 1.0))
		_:   # mending_draught (and unknown ids)
			length = 0.8
			burst_at = 0.42
			var k := _k3(t, 0.0, 0.16, 0.62, 0.8, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-55.0 * DEG * k, 0, 0))
			_staff_rot.x += 48.0 * DEG * k
			rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.25, 0.42, 0.8, 30.0, -80.0) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_k3(t, 0.0, 0.25, 0.42, 0.8, -3.0, 6.0) * DEG, _k3(t, 0.0, 0.25, 0.42, 0.8, -14.0, 10.0) * DEG, 0))
			rot(P_HEAD, Vector3(-6.0 * DEG * k, 0, 0))
			_circle(t, 0.06, 0.62, 1.0, 64.0, PI)
			_flare = maxf(_flare, _k3(t, 0.05, 0.3, 0.45, 0.8, 0.6, 1.0))
	if _cast_prev < burst_at and t >= burst_at:
		_flare = 1.0
		_fire_burst("puff", _kettle_model_pos())
	_cast_prev = t
	return length


## Censer swung in `turns` circles between t0 and t1 (ease in-out), tilt up to alpha_deg, starting at angle phi0
## (model frame, 0 = forward). The pendulum takes over after t1 with the circle's velocity.
func _circle(t: float, t0: float, t1: float, turns: float, alpha_deg: float, phi0: float) -> void:
	if t <= t0 or t >= t1:
		return
	var u := (t - t0) / (t1 - t0)
	var phi := phi0 + TAU * turns * smoothstep(0.0, 1.0, u)
	var a := alpha_deg * DEG * pow(sin(PI * u), 0.6)
	_circle_on = true
	_circle_th = Vector2(sin(phi), cos(phi)) * tan(a)


# ---------------------------------------------------------------- class casts (11.V5)

## Archetype casts with a class weapon in the right hand: no censer; the free (left) hand does the healing.
func _pose_cast_class(spell: StringName, t: float) -> float:
	var length: float
	match spell:
		&"soothing_circle":
			length = JT_T[JT_T.size() - 1]
			_pose_jar_throw(t)
			if _cast_prev < JT_RELEASE and t >= JT_RELEASE:
				_jar_throw(spell)
		&"lifeline":
			length = LL_T[LL_T.size() - 1]
			_pose_lifeline_class(t)
			if _cast_prev < LL_BURST and t >= LL_BURST:
				_fire_burst("puff", _left_hand_model_pos())
		_:   # mending_draught (and unknown ids)
			length = MD_T[MD_T.size() - 1]
			_pose_draught_class(t)
			if _cast_prev < MD_RELEASE and t >= MD_RELEASE:
				_jar_throw(&"mending_draught")
	_cast_prev = t
	return length


## Soothing Circle: the free hand reaches back over the left shoulder into the pack (0.20), comes up with a jar
## (shown from 0.22), cocks it behind the head and throws it overhand with a step (release 0.48); the weapon arm
## swings out for balance.
func _pose_jar_throw(t: float) -> void:
	rot(P_ARM_L, Vector3(_kf(t, JT_T, JT_LX) * DEG, 0, _kf(t, JT_T, JT_LZ) * DEG))
	rot(P_ARM_R, Vector3(_kf(t, JT_T, JT_RX) * DEG, 0, _kf(t, JT_T, JT_RZ) * DEG))
	rot(P_CHEST, Vector3(_kf(t, JT_T, JT_CX) * DEG, _kf(t, JT_T, JT_CY) * DEG, 0))
	rot(P_HEAD, Vector3(_kf(t, JT_T, JT_HX) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _kf(t, JT_T, JT_BY), _kf(t, JT_T, JT_BZ)))
	rot(P_LEG_L, Vector3(_kf(t, JT_T, JT_GL) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_kf(t, JT_T, JT_GR) * DEG, 0, 0))
	if t >= JT_GRAB and t < JT_RELEASE:
		_jar_hold()


## Mending Draught: the free hand takes a draught from the apron pouch (0.12), uncorks it at the chest (0.28) and
## tosses it underhand to the ally (0.42); the weapon lifts a little.
func _pose_draught_class(t: float) -> void:
	rot(P_ARM_L, Vector3(_kf(t, MD_T, MD_LX) * DEG, 0, _kf(t, MD_T, MD_LZ) * DEG))
	rot(P_CHEST, Vector3(_kf(t, MD_T, MD_CX) * DEG, _kf(t, MD_T, MD_CY) * DEG, 0))
	rot(P_HEAD, Vector3(_kf(t, MD_T, MD_HX) * DEG, 0, 0))
	_weapon_raise(0.35 * _k3(t, 0.0, 0.2, 0.55, 0.8, 1.0, 1.0))
	if t >= MD_GRAB and t < MD_RELEASE:
		_jar_hold()


## Lifeline: the weapon is raised (each weapon its own way) while the free hand reaches out to the ally; the bond
## bursts from the open hand at 0.52.
func _pose_lifeline_class(t: float) -> void:
	rot(P_ARM_L, Vector3(_kf(t, LL_T, LL_LX) * DEG, 0, 0))
	pos(P_ARM_L, Vector3(0, 0, _kf(t, LL_T, LL_LP)))
	rot(P_CHEST, Vector3(_kf(t, LL_T, LL_CX) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, 0, _kf(t, LL_T, LL_BZ)))
	rot(P_HEAD, Vector3(-6.0 * DEG * _k3(t, 0.0, 0.3, 0.7, 0.95, 1.0, 1.0), 0, 0))
	_weapon_raise(_k3(t, 0.0, 0.25, 0.70, 0.95, 1.0, 1.0))


## The weapon arm lifts the class weapon (k 0..1): spear tip to the sky, sword up in salute, greatsword brought upright
## off the shoulder, staff hoisted with its crystal flaring.
func _weapon_raise(k: float) -> void:
	if k <= 0.0:
		return
	match weapon_class():
		&"spear":
			rot(P_ARM_R, Vector3(-28.0 * DEG * k, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.05 * k, 0))
		&"sword_shield":
			rot(P_ARM_R, Vector3(-75.0 * DEG * k, 0, -8.0 * DEG * k))
		&"two_hand":
			rot(P_ARM_R, Vector3(38.0 * DEG * k, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.04 * k, 0))
		&"wizard":
			rot(P_ARM_R, Vector3(-22.0 * DEG * k, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.12 * k, 0))
			weapon_flare(0.8 * k)


## Smooth keyframes (smoothstep between keys).
static func _kf(t: float, ts: Array[float], vs: Array[float]) -> float:
	var n := ts.size()
	if t <= ts[0]:
		return vs[0]
	for i: int in range(1, n):
		if t < ts[i]:
			var f := (t - ts[i - 1]) / maxf(ts[i] - ts[i - 1], 0.0001)
			return lerpf(vs[i - 1], vs[i], f * f * (3.0 - 2.0 * f))
	return vs[n - 1]


## Model-space position of the left fist now (last applied pose).
func _left_hand_model_pos() -> Vector3:
	var arm: Node3D = _piv[P_ARM_L]
	if arm and arm.is_inside_tree() and is_inside_tree():
		return to_local(arm.global_transform * _hand_l_local)
	return HAND_L


# ---------------------------------------------------------------- the jar

## Pose helper (every frame it applies): the jar is in the left hand.
func _jar_hold() -> void:
	_jar_hold_req = true


## Release: the jar leaves the hand toward the cast point (or JAR_DIST ahead) on a lob; it moves under Fx (model space,
## not animated) so the arm's follow-through can't drag it.
func _jar_throw(spell: StringName) -> void:
	if _jar == null or _dead:
		return
	var fx: Node3D = get_node_or_null(^"Fx")
	if fx == null or not is_inside_tree():
		return
	var from := to_local(_jar.global_position)
	var land_y: float = JAR_LAND_Y.get(spell, 1.0)
	var to := Vector3(0.0, land_y, JAR_DIST.get(spell, 3.0))
	if _cast_point is Vector3:
		var p := to_local(_cast_point)
		var flat := Vector2(p.x, p.z)
		var d := clampf(flat.length(), 0.8, 10.0)
		flat = flat.normalized() * d if flat.length() > 0.01 else Vector2(0.0, d)
		to = Vector3(flat.x, land_y, flat.y)
	var dist := Vector2(to.x - from.x, to.z - from.z).length()
	_jar_from = from
	_jar_to = to
	_jar_dur = clampf(0.2 + 0.045 * dist, 0.26, 0.6)
	_jar_apex = 0.3 + 0.1 * dist
	_jar_u = 0.0
	_jar_spin = 0.0
	if _jar.get_parent() != fx:
		_jar.reparent(fx, false)
	_jar.transform = Transform3D(Basis.IDENTITY, from)
	_jar.visible = true
	_jar_mode = JAR_FLYING


## Per frame (from _extra_process): held jar shown / hidden by this frame's pose request; a flying jar follows its lob
## and shatters in a green puff where it lands.
func _jar_process(dt: float) -> void:
	if _jar == null:
		return
	match _jar_mode:
		JAR_OFF:
			if _jar_hold_req and not _dead:
				_jar_mode = JAR_HELD
				_jar.visible = true
		JAR_HELD:
			if not _jar_hold_req or _dead:
				_jar_mode = JAR_OFF
				_jar.visible = false
		JAR_FLYING:
			_jar_u += dt / _jar_dur
			if _jar_u >= 1.0:
				_jar_land()
			else:
				var u := _jar_u
				var p := _jar_from.lerp(_jar_to, u) + Vector3(0.0, 4.0 * _jar_apex * u * (1.0 - u), 0.0)
				_jar_spin += dt * 13.0
				_jar.transform = Transform3D(Basis(Vector3.RIGHT, _jar_spin), p)
	_jar_hold_req = false


func _jar_land() -> void:
	var at := _jar_to
	_jar_reset()
	_flare = 1.0
	_fire_burst("puff", at)


## Back in the left fist, hidden.
func _jar_reset() -> void:
	_jar_mode = JAR_OFF
	_jar_hold_req = false
	if _jar == null:
		return
	var arm: Node3D = _piv[P_ARM_L] if _piv.size() > P_ARM_L else null
	if arm and _jar.get_parent() != arm:
		_jar.reparent(arm, false)
	_jar.transform = _jar_rest
	_jar.visible = false


## The model freezes far from the camera (> 45 m, nothing busy): a jar still in the air lands at once.
func _process(delta: float) -> void:
	super._process(delta)
	if _jar_mode == JAR_FLYING and _frozen:
		_jar_land()


func _on_action_event(ev: StringName) -> void:
	var censer: bool = weapon_class() == &""
	match ev:
		&"release":
			# The class styles release too (the kit's staff_bolt flares its own crystal): the censer puff is hers only.
			if censer:
				_flare = 1.0
				_th_v += Vector2(0.0, 4.2)
				_fire_burst("puff", _kettle_model_pos())
		&"cast_start":
			_cast_prev = 0.0
			if Engine.get_process_frames() - _cast_point_frame > 2:
				_cast_point = null   # a point set for an earlier cast
		&"level_up":
			_flare = 1.0
			# the censer puffs; with a class weapon the jars on the pack do
			_fire_burst("puff", _kettle_model_pos() if censer else Vector3(-0.05, 1.9, -0.47))
		&"death_glow_off":
			_fire_burst("herbs", Vector3(0, 1.25, -0.40))


func _kettle_model_pos() -> Vector3:
	if _kettle and _kettle.is_inside_tree() and is_inside_tree():
		return to_local(_kettle.global_transform * KETTLE_C)
	return GRIP + HOOK + KETTLE_C


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto(self)
	# Level-up: the kit raises the weapon arm 40 deg; keep the staff upright so it is lifted, not tipped back.
	if _level_t < LEVEL_LEN and not _dead:
		_staff_rot.x += 40.0 * DEG * clampf(sin(PI * clampf(_level_t / 0.3, 0.0, 1.0)) * 1.5, 0.0, 1.0)
	_jar_process(dt)
	if weapon_class() != &"":
		# the censer staff is hidden: nothing of it to drive (its steam stays off, the kit's tier toggle included)
		_staff_rot = Vector3.ZERO
		if _steam and _steam.emitting:
			_steam.emitting = false
		_flare = 0.0
		return
	if _staff and _staff_rot != _staff_written:
		_staff_written = _staff_rot
		_staff.rotation = _staff_rot
	_staff_rot = Vector3.ZERO
	_update_censer(dt)
	if _core:
		var b: float = glow_level() * (1.0 + 2.2 * _flare)
		if b != _core_written:
			_core_written = b
			_core.set_instance_shader_parameter(&"glow_boost", b)
	_flare = maxf(0.0, _flare - dt / 0.45)


## The kettle hangs straight down in the world and swings like a damped pendulum from the crook.
func _update_censer(dt: float) -> void:
	if _censer == null or not _censer.is_inside_tree():
		return
	var hook_w := _censer.global_position
	if not _hook_init or dt <= 0.0 or hook_w.distance_to(_hook_prev) > 1.5:
		_hook_init = true
		_hook_prev = hook_w
		_hook_vel = Vector3.ZERO
	else:
		var vel := (hook_w - _hook_prev) / dt
		var acc := (vel - _hook_vel) / dt
		_hook_prev = hook_w
		_hook_vel = vel
		if acc.length() > 40.0:
			acc = acc.normalized() * 40.0
		var am := global_basis.orthonormalized().inverse() * acc
		if _circle_on:
			var nt := _circle_th
			_th_v = (nt - _th) / dt
			_th = nt
		else:
			var g := 9.8 / PEND_L
			var f := -g * _th - PEND_DAMP * _th_v - Vector2(am.x, am.z) / PEND_L
			_th_v += f * dt
			_th += _th_v * dt
			if _th.length() > 2.5:
				_th = _th.normalized() * 2.5
	_circle_on = false
	var d := Vector3(_th.x, -1.0, _th.y).normalized()
	var world := global_basis.orthonormalized() * Basis(Quaternion(Vector3.DOWN, d))
	var parent := (_censer.get_parent() as Node3D).global_basis.orthonormalized()
	_censer.basis = parent.inverse() * world


func _on_revive() -> void:
	if _face:
		_face.reset()
	_flare = 0.0
	_core_written = -1.0
	_staff_rot = Vector3.ZERO
	_staff_written = Vector3(99, 99, 99)
	_th = Vector2.ZERO
	_th_v = Vector2.ZERO
	_hook_init = false
	_circle_on = false
	if _staff:
		_staff.rotation = Vector3.ZERO
	_jar_reset()


# ================================================================ mesh building (static, once per game)

## Cached mesh by key; `build` returns a Geo.
func _m(key: String, build: Callable) -> Mesh:
	if not _meshes.has(key):
		var g: Geo = build.call()
		_meshes[key] = g.commit()
	return _meshes[key]


## Flat [r, y, r, y, ...] list -> lathe profile.
static func _p(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in range(0, a.size(), 2):
		out.append(Vector2(a[i], a[i + 1]))
	return out


static func _xf(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG).scaled_local(scl), pos)


## Transform whose local +Y runs from a to b (for tori / cylinders along a limb).
static func _along(a: Vector3, b: Vector3, scl: Vector3 = Vector3.ONE) -> Transform3D:
	var d := (b - a).normalized()
	return Transform3D(Basis(Quaternion(Vector3.UP, d)).scaled_local(scl), (a + b) * 0.5)


## Mesh accumulator: vertices, normals, UV = (palette index, surface mode), indices. One surface.
class Geo:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var ix := PackedInt32Array()

	## Surface 0 of a primitive mesh, transformed (no negative scales).
	func prim(mesh: Mesh, xf: Transform3D, pal: int, mode: float = 0.0) -> Geo:
		var arr := mesh.surface_get_arrays(0)
		var pv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var pn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var pi: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var nb := xf.basis.inverse().transposed()
		var b0 := v.size()
		var t := Vector2(pal, mode)
		for j: int in pv.size():
			v.append(xf * pv[j])
			n.append((nb * pn[j]).normalized())
			uv.append(t)
		if pi.is_empty():
			for j: int in pv.size():
				ix.append(b0 + j)
		else:
			for j: int in pi.size():
				ix.append(b0 + pi[j])
		return self

	## Surface of revolution of `profile` (r, y) around local Y, from angle a0 to a1 (0 = +Z, TAU/4 = +X).
	## Repeat a point to make a crease. Optional folds: r *= 1 + fold_amp * sin(fold_n * a) * w, w = 1 below
	## fold_y0 fading to 0 at fold_y1 (a hem that ripples).
	func lathe(profile: PackedVector2Array, xf: Transform3D, seg: int, pal: int, mode: float = 0.0,
			a0: float = 0.0, a1: float = TAU, fold_amp: float = 0.0, fold_n: float = 0.0,
			fold_y0: float = 0.0, fold_y1: float = 1.0) -> Geo:
		var np := profile.size()
		var n2 := PackedVector2Array()
		for i: int in np:
			var prev := profile[i - 1] if i > 0 else profile[i]
			var next := profile[i + 1] if i < np - 1 else profile[i]
			if i > 0 and profile[i].is_equal_approx(profile[i - 1]):
				prev = profile[i]
			if i < np - 1 and profile[i].is_equal_approx(profile[i + 1]):
				next = profile[i]
			var tg := next - prev
			if tg.length_squared() < 1e-12:
				tg = Vector2(0, 1)
			tg = tg.normalized()
			n2.append(Vector2(tg.y, -tg.x))
		var nb := xf.basis.inverse().transposed()
		var base := v.size()
		var t := Vector2(pal, mode)
		for c: int in seg + 1:
			var a := lerpf(a0, a1, float(c) / float(seg))
			var s := sin(a)
			var co := cos(a)
			for i: int in np:
				var p := profile[i]
				var r := p.x
				var nx := n2[i].x
				var ln := Vector3(nx * s, n2[i].y, nx * co)
				if fold_amp != 0.0:
					var w := clampf((fold_y1 - p.y) / maxf(fold_y1 - fold_y0, 0.001), 0.0, 1.0)
					var f := fold_amp * w
					r = p.x * (1.0 + f * sin(fold_n * a))
					# d r / d a relative to r tilts the normal around the axis
					var slope := f * fold_n * cos(fold_n * a) / maxf(1.0 + f * sin(fold_n * a), 0.01)
					ln -= Vector3(co, 0.0, -s) * slope * nx
				v.append(xf * Vector3(r * s, p.y, r * co))
				n.append((nb * ln).normalized())
				uv.append(t)
		for c: int in seg:
			for i: int in np - 1:
				if profile[i].is_equal_approx(profile[i + 1]):
					continue
				var a := base + c * np + i
				var b := a + np
				ix.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))
		return self

	## Tube along a polyline, radius per point; aspect > 1 flattens it (width along the binormal, thickness along
	## the normal: the normal follows `hints` (per point, e.g. the body surface normal) or parallel transport.
	func tube(pts: PackedVector3Array, radii: PackedFloat32Array, sides: int, pal: int, mode: float = 0.0,
			caps: bool = true, aspect: float = 1.0, hints: PackedVector3Array = PackedVector3Array()) -> Geo:
		var np := pts.size()
		var base := v.size()
		var t := Vector2(pal, mode)
		var nrm := Vector3.ZERO
		var tans: Array[Vector3] = []
		var rings: Array = []
		for i: int in np:
			var tg := (pts[mini(i + 1, np - 1)] - pts[maxi(i - 1, 0)]).normalized()
			tans.append(tg)
			if hints.size() == np:
				nrm = hints[i] - tg * hints[i].dot(tg)
			elif i == 0:
				var ref := Vector3.BACK if absf(tg.dot(Vector3.BACK)) < 0.9 else Vector3.UP
				nrm = ref - tg * ref.dot(tg)
			else:
				nrm = nrm - tg * nrm.dot(tg)
			nrm = nrm.normalized()
			var bn := tg.cross(nrm)
			rings.append([nrm, bn])
			for k: int in sides + 1:
				var ang := TAU * float(k) / float(sides)
				var c := cos(ang)
				var s := sin(ang)
				v.append(pts[i] + (nrm * c + bn * s * aspect) * radii[i])
				n.append((nrm * c + bn * (s / aspect)).normalized())
				uv.append(t)
		for i: int in np - 1:
			for k: int in sides:
				var a := base + i * (sides + 1) + k
				var b := a + sides + 1
				ix.append_array(PackedInt32Array([a, b, a + 1, b, b + 1, a + 1]))
		if caps:
			for e: int in 2:
				var i := 0 if e == 0 else np - 1
				var want: Vector3 = -tans[i] if e == 0 else tans[i]
				var ctr := v.size()
				v.append(pts[i])
				n.append(want)
				uv.append(t)
				var fr: Array = rings[i]
				for k: int in sides + 1:
					var ang := TAU * float(k) / float(sides)
					v.append(pts[i] + ((fr[0] as Vector3) * cos(ang) + (fr[1] as Vector3) * sin(ang) * aspect) * radii[i])
					n.append(want)
					uv.append(t)
				for k: int in sides:
					_tri(ctr, ctr + 1 + k, ctr + 2 + k, want)
		return self

	## One triangle facing `want` (Godot front faces are clockwise: the geometric cross product points inward).
	func _tri(a: int, b: int, c: int, want: Vector3) -> void:
		if (v[b] - v[a]).cross(v[c] - v[a]).dot(want) > 0.0:
			ix.append_array(PackedInt32Array([a, c, b]))
		else:
			ix.append_array(PackedInt32Array([a, b, c]))

	func shift(d: Vector3) -> void:
		for i: int in v.size():
			v[i] += d

	func commit() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = n
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_INDEX] = ix
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return am


# ---------------------------------------------------------------- hips / legs

const HEM_P: Array = [0.0, 0.14, 0.36, 0.14, 0.405, 0.15, 0.426, 0.19, 0.418, 0.232]
const SKIRT_P: Array = [0.418, 0.232, 0.438, 0.32, 0.446, 0.44, 0.44, 0.54, 0.425, 0.62, 0.36, 0.665, 0.0, 0.68]
const BODICE_P: Array = [0.0, 0.58, 0.33, 0.60, 0.43, 0.63, 0.452, 0.72, 0.458, 0.82, 0.44, 0.94, 0.41, 1.02, 0.37, 1.08]
const BLOUSE_P: Array = [0.37, 1.08, 0.32, 1.14, 0.25, 1.20, 0.16, 1.245, 0.0, 1.265]
const FOLDS: Array = [0.035, 7.0, 0.30, 0.56]   # skirt folds: amp, count, full below y, none above y


## Radius of a flat [r, y, ...] profile at height y (linear, rising part only).
static func _r_at(prof: Array, y: float) -> float:
	for i: int in range(2, prof.size(), 2):
		var y0: float = prof[i - 1]
		var y1: float = prof[i + 1]
		if y1 > y0 and y >= y0 and y <= y1:
			return lerpf(prof[i - 2], prof[i], (y - y0) / (y1 - y0))
	return prof[prof.size() - 2]


## Thin panel profile laid over `prof` between y0 and y1 (n rows): outer at +d_out, inner at +d_in, creased edges.
static func _panel(prof: Array, y0: float, y1: float, n: int, d_out: float, d_in: float) -> PackedVector2Array:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for k: int in n:
		var y := lerpf(y0, y1, float(k) / float(n - 1))
		var r := _r_at(prof, y)
		outer.append(Vector2(r + d_out, y))
		inner.append(Vector2(r + d_in, y))
	var out := PackedVector2Array([inner[0], outer[0]])
	out.append_array(outer)
	out.append(outer[n - 1])
	out.append(inner[n - 1])
	for k: int in range(n - 1, -1, -1):
		out.append(inner[k])
	return out


func _geo_skirt() -> Geo:
	var g := Geo.new()
	var xf := Transform3D(Basis.from_scale(Vector3(1, 1, SKIRT_Z)), Vector3.ZERO)
	# rolled dark hem, then the round skirt (tucked in at the hem: an egg); folds ripple the lower half
	g.lathe(_p(HEM_P), xf, 21, HERB_DARK, M_CLOTH, 0.0, TAU, FOLDS[0], FOLDS[1], FOLDS[2], FOLDS[3])
	g.lathe(_p(SKIRT_P), xf, 21, HERB, M_CLOTH, 0.0, TAU, FOLDS[0], FOLDS[1], FOLDS[2], FOLDS[3])
	return g


## Linen apron over the skirt front (same folds), a pocket on the right with a pestle poking out.
func _geo_apron() -> Geo:
	var g := Geo.new()
	var xf := Transform3D(Basis.from_scale(Vector3(1, 1, SKIRT_Z)), Vector3.ZERO)
	g.lathe(_panel(SKIRT_P, 0.25, 0.62, 5, 0.022, 0.004), xf, 9, LINEN, M_CLOTH, -0.72, 0.72,
		FOLDS[0], FOLDS[1], FOLDS[2], FOLDS[3])
	g.lathe(_panel(SKIRT_P, 0.33, 0.47, 3, 0.034, 0.024), xf, 4, LINEN_SH, M_CLOTH, 0.10, 0.52,
		FOLDS[0], FOLDS[1], FOLDS[2], FOLDS[3])
	var a := 0.30
	var r := _r_at(SKIRT_P, 0.52) + 0.03
	var at := Vector3(sin(a) * r, 0.52, cos(a) * r * SKIRT_Z)
	g.prim(cyl(0.024, 0.028, 0.22), _xf(at, Vector3(8, 0, -14)), WOOD, M_WOOD)
	g.prim(sphere(0.042, 8, 4), _xf(at + Vector3(0.027, 0.105, 0.015)), WOOD, M_WOOD)
	return g


## Leather pouch on the left-back hip (body, flap, brass stud).
func _geo_pouch() -> Geo:
	var g := Geo.new()
	var a := -112.0 * DEG
	var out := Vector3(sin(a), 0, cos(a))
	var r := _r_at(SKIRT_P, 0.47) + 0.045
	var at := Vector3(out.x * r, 0.47, out.z * r * SKIRT_Z)
	var b := Basis(Vector3.UP, a)
	g.prim(sphere(1.0, 8, 5), Transform3D(b.scaled_local(Vector3(0.12, 0.13, 0.075)), at), LEATHER)
	g.prim(sphere(1.0, 8, 4), Transform3D(b.scaled_local(Vector3(0.125, 0.06, 0.08)), at + Vector3(0, 0.07, 0) + out * 0.01), SOLE)
	g.prim(sphere(0.025, 6, 3), _xf(at + out * 0.08 + Vector3(0, 0.035, 0)), BRASS, M_METAL)
	return g


func _geo_leg(side: float) -> Geo:
	var g := Geo.new()
	var x := 0.15 * side
	g.prim(cyl(0.078, 0.07, 0.28), _xf(Vector3(x, 0.27, 0)), HERB_DARK)
	var yaw := Vector3(0, 9.0 * side, 0)
	g.prim(sphere(1.0, 10, 5), _xf(Vector3(x + 0.01 * side, 0.088, 0.05), yaw, Vector3(0.115, 0.088, 0.165)), LEATHER)
	g.prim(torus(0.058, 0.098, 10), _xf(Vector3(x, 0.165, 0.0)), LEATHER)
	g.prim(box(Vector3(0.19, 0.03, 0.30)), _xf(Vector3(x + 0.01 * side, 0.015, 0.05), yaw), SOLE)
	return g


# ---------------------------------------------------------------- chest

func _geo_torso() -> Geo:
	var g := Geo.new()
	var xf := Transform3D(Basis.from_scale(Vector3(1, 1, BODY_Z)), Vector3.ZERO)
	g.lathe(_p(BODICE_P), xf, 14, HERB)
	g.lathe(_p(BLOUSE_P), xf, 14, LINEN)
	# gathered collar ruffle
	g.lathe(_p([0.17, 1.19, 0.24, 1.195, 0.272, 1.215, 0.262, 1.24, 0.21, 1.252, 0.17, 1.25]), xf, 21, LINEN, M_CLOTH,
		0.0, TAU, 0.06, 7.0, 1.3, 1.31)
	return g


## Linen apron bib hugging the round belly (front 70 deg), with a hemmed top edge.
func _geo_bib() -> Geo:
	var g := Geo.new()
	var xf := Transform3D(Basis.from_scale(Vector3(1, 1, BODY_Z)), Vector3.ZERO)
	g.lathe(_panel(BODICE_P, 0.63, 1.0, 6, 0.02, 0.003), xf, 8, LINEN, M_CLOTH, -0.62, 0.62)
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	var r := _r_at(BODICE_P, 1.0) + 0.012
	for k: int in 8:
		var a := lerpf(-0.62, 0.62, float(k) / 7.0)
		pts.append(Vector3(sin(a) * r, 1.0, cos(a) * r * BODY_Z))
		rad.append(0.016)
	g.tube(pts, rad, 6, LINEN_SH)
	return g


const SASH_R := 0.48
const SASH_KNOT := -42.0


## Team sash round the waist, knotted on the left front, two tails (team colour: mender_cloth).
func _geo_sash() -> Geo:
	var g := Geo.new()
	var xf := Transform3D(Basis.from_scale(Vector3(1, 1, BODY_Z)), Vector3.ZERO)
	g.lathe(_p([0.40, 0.585, 0.44, 0.595, 0.462, 0.62, 0.472, 0.655, 0.474, 0.69, 0.466, 0.716, 0.44, 0.73,
		0.40, 0.735]), xf, 16, 0, M_CLOTH)
	var a := SASH_KNOT * DEG
	var knot := Vector3(sin(a) * SASH_R, 0.662, cos(a) * SASH_R * BODY_Z)
	var out := Vector3(sin(a), 0.0, cos(a) * BODY_Z).normalized()
	g.prim(sphere(1.0, 8, 5), Transform3D(Basis(Vector3.UP, a).scaled_local(Vector3(0.075, 0.062, 0.05)), knot + out * 0.02), 0)
	for k: int in 2:
		var off := -0.035 if k == 0 else 0.045
		var drop := 0.34 if k == 0 else 0.27
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		var hints := PackedVector3Array()
		for j: int in 5:
			var u := float(j) / 4.0
			pts.append(knot + out * (0.035 + 0.05 * u) + Vector3(off * (1.0 + u * 0.6), -drop * u, 0.0))
			rad.append(lerpf(0.014, 0.016, u))
			hints.append(out)
		g.tube(pts, rad, 6, 0, M_CLOTH, true, 3.6, hints)
	return g


## Darker team trim: thin rolls on the sash edges and the fringed ends of the tails (mender_cloth_dark).
func _geo_sash_trim() -> Geo:
	var g := Geo.new()
	var xf := Transform3D(Basis.from_scale(Vector3(1, 1, BODY_Z)), Vector3.ZERO)
	g.lathe(_p([0.44, 0.587, 0.457, 0.598, 0.449, 0.609]), xf, 16, 0, M_CLOTH)
	g.lathe(_p([0.458, 0.705, 0.477, 0.716, 0.458, 0.728]), xf, 16, 0, M_CLOTH)
	var a := SASH_KNOT * DEG
	var knot := Vector3(sin(a) * SASH_R, 0.662, cos(a) * SASH_R * BODY_Z)
	var out := Vector3(sin(a), 0.0, cos(a) * BODY_Z).normalized()
	for k: int in 2:
		var off := -0.035 if k == 0 else 0.045
		var drop := 0.34 if k == 0 else 0.27
		var end := knot + out * 0.085 + Vector3(off * 1.6, -drop, 0.0)
		g.prim(sphere(1.0, 6, 3), Transform3D(Basis(Vector3.UP, a).scaled_local(Vector3(0.06, 0.04, 0.025)), end), 0)
	return g


## Oval wicker backpack (rows + stakes painted by the shader), dark rims and band, open top with a dark inside,
## and the two leather shoulder straps.
func _geo_basket() -> Geo:
	var g := Geo.new()
	var xf := Transform3D(Basis.from_scale(Vector3(1, 1, 0.55)), Vector3(0, 0, -0.46))   # lathes 12-sided (were 14: faces pass trim)
	g.lathe(_p([0.0, 0.888, 0.24, 0.888, 0.262, 0.905, 0.272, 0.95]), xf, 12, WICKER_DARK, M_WICKER)
	g.lathe(_p([0.272, 0.95, 0.279, 1.10, 0.29, 1.30, 0.30, 1.44]), xf, 12, WICKER, M_WICKER)
	g.lathe(_p([0.30, 1.44, 0.318, 1.452, 0.324, 1.478, 0.312, 1.50, 0.29, 1.505, 0.274, 1.49, 0.27, 1.465]), xf, 12,
		WICKER_DARK, M_WICKER)
	g.lathe(_p([0.27, 1.465, 0.262, 1.34, 0.262, 1.34, 0.0, 1.34]), xf, 12, WICKER_DARK, M_CLOTH)
	for y: float in [1.16]:
		g.lathe(_p([0.281 + (y - 1.06) * 0.06, y - 0.018, 0.293 + (y - 1.06) * 0.06, y, 0.284 + (y - 1.06) * 0.06, y + 0.018]),
			xf, 12, WICKER_DARK, M_WICKER)
	# shoulder straps: from the pack's front top over the shoulders down onto the apron bib
	for sd: float in [-1.0, 1.0]:
		var pts := PackedVector3Array([Vector3(0.16 * sd, 1.41, -0.30), Vector3(0.19 * sd, 1.31, -0.22),
			Vector3(0.215 * sd, 1.262, -0.08), Vector3(0.235 * sd, 1.232, 0.07), Vector3(0.245 * sd, 1.17, 0.19),
			Vector3(0.25 * sd, 1.085, 0.268), Vector3(0.25 * sd, 1.02, 0.322)])
		var rad := PackedFloat32Array()
		var hints := PackedVector3Array()
		for p: Vector3 in pts:
			rad.append(0.014)
			hints.append((p - Vector3(0, 0.95, -0.05)).normalized())
		g.tube(pts, rad, 6, LEATHER, M_CLOTH, true, 3.9, hints)
		g.prim(box(Vector3(0.10, 0.07, 0.03)), _xf(Vector3(0.25 * sd, 1.08, 0.285), Vector3(-30, 0, 0)), BRASS, M_METAL)
	return g


## [centre x, centre z, bottom y, top y, radius, glow colour]
const JARS: Array = [
	[-0.12, -0.47, 1.30, 1.80, 0.105, G_GREEN],
	[0.14, -0.49, 1.30, 1.66, 0.095, G_AMBER],
	[0.03, -0.375, 1.30, 1.60, 0.072, G_ROSE],
	[-0.115, -0.47, 1.885, 2.04, 0.082, G_BLUE],
]


## The thrown jar (centre = origin): glowing green contents in a round bottle (surface 0, mender_glow), a cork, the
## twine round its neck and a paper label (surface 1, mender_painted). One node, two surfaces, both own materials.
func _jar_mesh() -> Mesh:
	if _meshes.has("thrown_jar"):
		return _meshes["thrown_jar"]
	var gl := Geo.new()
	var big := Transform3D(Basis.from_scale(Vector3.ONE * 1.25), Vector3.ZERO)   # chunky enough to read in the air
	# the whole bottle in one profile: round belly, shoulder, neck (vertex budget: 8000 for the champion)
	gl.lathe(_p([0.0, -0.085, 0.058, -0.085, 0.076, -0.055, 0.078, 0.02, 0.06, 0.06, 0.031, 0.08, 0.028, 0.13,
		0.0, 0.13]), big, 8, G_GREEN, 0.7)
	var pt := Geo.new()
	pt.lathe(_p([0.0, 0.122, 0.034, 0.122, 0.036, 0.172, 0.0, 0.176]), big, 6, CORK)
	pt.lathe(_p([0.079, -0.03, 0.083, -0.02, 0.083, 0.02, 0.079, 0.03]), big, 4, LINEN, M_CLOTH, -1.0, 1.3)
	var am := ArrayMesh.new()
	for pair: Array in [[gl, _mat(&"mender_painted")], [pt, _mat(&"mender_painted")]]:
		var one: ArrayMesh = (pair[0] as Geo).commit()
		if pair[0] == gl:
			one = _as_glow_paint("thrown_jar_glow", one) as ArrayMesh
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, one.surface_get_arrays(0))
		am.surface_set_material(am.get_surface_count() - 1, pair[1])
	_meshes["thrown_jar"] = am
	return am


## Glowing contents of the jars (mender_glow, separate instance: the kit drives its glow_boost).
func _geo_jars() -> Geo:
	var g := Geo.new()
	for i: int in JARS.size():
		var j: Array = JARS[i]
		var r: float = j[4]
		var y0: float = j[2]
		var y1: float = j[3]
		var xf := Transform3D(Basis.IDENTITY, Vector3(j[0], 0, j[1]))
		g.lathe(_p([0.0, y0, r * 0.8, y0, r, y0 + 0.05, r, y1 - 0.07, r * 0.86, y1 - 0.025, r * 0.62, y1, 0.0, y1]), xf, 10,
			j[5], float(i) * 1.7)
		if i == 2:   # the bottle's neck
			g.lathe(_p([0.0, y1 - 0.01, 0.036, y1 - 0.01, 0.034, y1 + 0.13, 0.0, y1 + 0.13]), xf, 8, j[5], float(i) * 1.7)
	return g


## Painted parts of the jars: corks, a cloth cap tied on the big jar, paper labels, twine lashing the stack.
func _geo_jar_caps() -> Geo:
	var g := Geo.new()
	for i: int in JARS.size():
		var j: Array = JARS[i]
		var c := Vector3(j[0], 0, j[1])
		var r: float = j[4]
		var y1: float = j[3]
		match i:
			0:   # cloth cap tied with twine (the stacked jar sits on it)
				g.prim(sphere(1.0, 10, 5), _xf(c + Vector3(0, y1 + 0.02, 0), Vector3.ZERO, Vector3(r * 1.12, 0.07, r * 1.12)), LINEN)
				g.prim(torus(r * 0.72, r * 0.9, 8), _xf(c + Vector3(0, y1 - 0.005, 0)), CORK)
			2:   # bottle cork in the neck
				g.prim(cyl(0.03, 0.028, 0.07), _xf(c + Vector3(0, y1 + 0.16, 0)), CORK)
			_:
				g.prim(cyl(r * 0.6, r * 0.66, 0.07), _xf(c + Vector3(0, y1 + 0.025, 0)), CORK)
				g.prim(torus(r * 0.6, r * 0.8, 8), _xf(c + Vector3(0, y1 - 0.012, 0)), LINEN_SH)
		if i < 2:   # paper label band
			g.lathe(_p([r + 0.004, 0.0, r + 0.007, 0.01, r + 0.007, 0.08, r + 0.004, 0.09]),
				Transform3D(Basis.IDENTITY, c + Vector3(0, lerpf(j[2], y1, 0.52) - 0.045, 0)), 8, LINEN, M_CLOTH,
				-1.2 + 0.5 * i, 1.4 + 0.5 * i)
	# twine lashing the blue jar onto the green one (two crossing loops)
	var top: Array = JARS[3]
	var ctr := Vector3(top[0], (top[2] + top[3]) * 0.5, top[1])
	g.prim(torus(0.085, 0.1, 10), _xf(ctr, Vector3(0, 0, 0), Vector3(1, 1, 1)), CORK)
	g.prim(torus(0.1, 0.115, 8), _xf(ctr + Vector3(0, -0.08, 0), Vector3(90, 0, 12), Vector3(1, 1.6, 1)), CORK)
	return g


## Bedroll under the pack, a copper pot hanging on its right side, herb sprigs over the rim.
func _geo_pack_load() -> Geo:
	var g := Geo.new()
	g.prim(capsule(0.088, 0.64), _xf(Vector3(0, 0.80, -0.445), Vector3(0, 0, 90)), RUST)
	for x: float in [-0.19, 0.19]:
		g.prim(torus(0.083, 0.106, 8), _xf(Vector3(x, 0.80, -0.445), Vector3(0, 0, 90)), LEATHER)
	# small hanging pot: body, rim, bail to a hook on the basket
	var pc := Vector3(0.345, 1.05, -0.47)
	g.lathe(_p([0.0, -0.075, 0.05, -0.075, 0.075, -0.05, 0.082, 0.0, 0.08, 0.045, 0.08, 0.045, 0.09, 0.05, 0.088, 0.062,
		0.072, 0.06, 0.0, 0.03]), Transform3D(Basis.IDENTITY, pc), 10, COPPER, M_METAL)
	var bail := PackedVector3Array()
	var brad := PackedFloat32Array()
	for k: int in 7:
		var a := lerpf(0.0, PI, float(k) / 6.0)
		bail.append(pc + Vector3(0.0, 0.05 + sin(a) * 0.13, cos(a) * 0.082))
		brad.append(0.011)
	g.tube(bail, brad, 5, IRON, M_METAL)
	# herb sprigs over the rim: a big bunch at the right back, a smaller one at the left front
	var leaf := NatureModel.leaf_mesh()
	var bunches := [[Vector3(0.17, 1.47, -0.55), 5, Vector3(0.6, 0, -0.55)], [Vector3(-0.25, 1.47, -0.40), 3, Vector3(-1, 0, 0.1)]]
	for bu: Array in bunches:
		var base: Vector3 = bu[0]
		var cnt: int = bu[1]
		var dir: Vector3 = bu[2]
		for k: int in cnt:
			var yaw := (float(k) - (cnt - 1) * 0.5) * 0.5
			var d := dir.rotated(Vector3.UP, yaw)
			var tilt := 70.0 - 9.0 * absf(float(k) - (cnt - 1) * 0.5)
			var sz := Vector3(0.10, 0.03, 0.24 + 0.04 * float(k % 2))
			g.prim(leaf, NatureModel.leaf_xform(base, d, sz, tilt), LEAF if k % 3 != 1 else HERB)
	return g


## Pennant pole behind the pack (right back), lashed twice, brass finial.
func _geo_pole() -> Geo:
	var g := Geo.new()
	g.prim(cyl(0.02, 0.024, 1.36), _xf(Vector3(0.21, 1.62, -0.60)), WOOD, M_WOOD)
	g.prim(sphere(0.042, 8, 4), _xf(Vector3(0.21, 2.32, -0.60)), BRASS, M_METAL)
	for y: float in [1.40]:
		g.prim(torus(0.022, 0.042, 8), _xf(Vector3(0.21, y, -0.598)), LEATHER)
	return g


# ---------------------------------------------------------------- head

func _geo_face() -> Geo:
	var g := Geo.new()
	g.prim(sphere(0.235, 12, 7), _xf(Vector3(0, 1.46, 0.03), Vector3.ZERO, Vector3(1.0, 0.97, 0.97)), SKIN, M_SKIN)
	for sd: float in [-1.0, 1.0]:
		g.prim(sphere(0.078, 6, 4), _xf(Vector3(0.118 * sd, 1.40, 0.175), Vector3.ZERO, Vector3(1.0, 0.85, 0.8)), SKIN, M_SKIN)
	g.prim(sphere(0.062, 8, 5), _xf(Vector3(0, 1.448, 0.262)), BLUSH, M_SKIN)
	# (the eye bar and the mouth box: replaced by the FaceKit face, faces pass 2026-09-28)
	return g


## Face styles (FaceKit, faces pass 2026-09-28): the jolly round apothecary. Big warm brown eyes set high over the
## round cheeks (the cheek spheres are her blush: no painted blush), chestnut brows just under the hair fringe, a wide
## happy closed smile at rest, round ears. Osric (B): his bushy brows / moustache / beard are the Variant mesh, so no
## painted brows and the mouth sits on the beard's top (its own canvas) under the moustache.
static func _face_spec(v: int) -> Dictionary:
	var c := Vector3(0, 1.46, 0.03)
	var spec := {"center": c, "radius": 0.235, "head_mesh": sphere(0.235, 12, 7), "head_scale": Vector3(1.0, 0.97, 0.97),
		"preset": &"bright" if v == 0 else &"plain", "skin": Color(0.90, 0.70, 0.55), "hair": Color(0.52, 0.25, 0.12),
		"eyes": Color(0.42, 0.26, 0.12), "ears": &"round",
		"eye": {"c": Vector2(0.080, 0.040), "hw": 0.036, "top": 0.027, "bot": 0.014, "ir": 0.018},
		"brow": {"inner": Vector2(0.036, 0.074), "mid": Vector2(0.078, 0.086), "outer": Vector2(0.118, 0.072)},
		"mouth": {"c": Vector2(0.0, -0.090), "hw": 0.050},
		"palette": {"lip": Color(0.86, 0.46, 0.42), "lip_line": Color(0.42, 0.14, 0.10)},
		"x": {&"neutral": {"blush": 0.0, "mouth": {"curve": 1.4, "w": 1.1}}, &"smile": {"blush": 0.0},
			&"fierce": {"blush": 0.0}, &"worried": {"blush": 0.0}, &"shout": {"blush": 0.0}}}
	if v == 1:
		spec["brow"] = {"none": true}
		spec["mouth_canvas"] = FaceKit.canvas(Vector3(0, 1.335, 0.165), 0.19, sphere(1.0, 12, 6), Vector3(0.232, 0.19, 0.15),
			Vector3.INF, Basis(Vector3.RIGHT, deg_to_rad(12.0)), 0.002)
		spec["mouth"] = {"c": Vector2(0.0, 0.022), "hw": 0.042, "lip": 0.004}
		spec["palette"]["lip_line"] = Color(0.30, 0.10, 0.06)
	return spec


## Chestnut hair (a tilted cap: fringe at the front, down to the nape) under a linen kerchief knotted at the back.
func _geo_hair() -> Geo:
	var g := Geo.new()
	g.lathe(_cap_profile(0.255, 0.228, 115.0), _xf(Vector3(0, 1.47, 0.012), Vector3(-45, 0, 0)), 12, HAIR, M_HAIR)
	g.lathe(_cap_profile(0.268, 0.25, 62.0), _xf(Vector3(0, 1.47, 0.012), Vector3(-48, 0, 0)), 12, LINEN, M_CLOTH,
		0.0, TAU, 0.03, 6.0, 0.0, 1.0)
	# knot + two short tails at the back
	g.prim(sphere(1.0, 8, 5), _xf(Vector3(0, 1.405, -0.235), Vector3.ZERO, Vector3(0.07, 0.055, 0.05)), LINEN)
	for sd: float in [-1.0, 1.0]:
		g.prim(sphere(1.0, 8, 4), _xf(Vector3(0.05 * sd, 1.33, -0.255), Vector3(-15, 0, 25 * sd), Vector3(0.045, 0.085, 0.022)), LINEN)
	return g


## Spherical cap profile (bottom -> top, outward normals): an inner lip at radius r_in, then the outer shell of
## radius r from `deg` (angle from the pole) up to the pole.
static func _cap_profile(r: float, r_in: float, deg: float) -> PackedVector2Array:
	var e := deg * DEG
	var out := PackedVector2Array([Vector2(r_in * sin(e), r_in * cos(e)), Vector2(r * sin(e), r * cos(e))])
	out.append(out[1])
	for k: int in range(1, 10):
		var ph := lerpf(e, 0.0, float(k) / 9.0)
		out.append(Vector2(r * sin(ph), r * cos(ph)))
	return out


## Variant A (Orla): a round bun on the crown with a green ribbon and a sprig of herbs.
func _geo_bun() -> Geo:
	var g := Geo.new()
	var c := Vector3(0, 1.70, -0.155)
	g.prim(sphere(0.118, 12, 6), _xf(c, Vector3(-20, 0, 0), Vector3(1.0, 0.9, 1.0)), HAIR, M_HAIR)
	g.prim(torus(0.085, 0.118, 12), _xf(c + Vector3(0, -0.05, 0.02), Vector3(-25, 0, 0)), HERB)
	var leaf := NatureModel.leaf_mesh()
	for k: int in 3:
		var d := Vector3(0.35 * float(k - 1), 0.0, -1.0).normalized()
		g.prim(leaf, NatureModel.leaf_xform(c + Vector3(0.02 * float(k - 1), 0.07, -0.02), d, Vector3(0.07, 0.025, 0.19), 55.0), LEAF)
	return g


## Variant B (Osric): a bushy rounded beard over the collar, a droopy moustache, bushy brows, sideburns.
func _geo_beard() -> Geo:
	var g := Geo.new()
	g.prim(sphere(1.0, 12, 6), _xf(Vector3(0, 1.335, 0.165), Vector3(12, 0, 0), Vector3(0.232, 0.19, 0.15)), HAIR, M_HAIR)
	g.prim(sphere(1.0, 10, 5), _xf(Vector3(0, 1.20, 0.215), Vector3(20, 0, 0), Vector3(0.15, 0.12, 0.10)), HAIR, M_HAIR)
	for sd: float in [-1.0, 1.0]:
		g.prim(sphere(1.0, 8, 5), _xf(Vector3(0.195 * sd, 1.43, 0.07), Vector3(0, 0, -8 * sd), Vector3(0.065, 0.13, 0.085)), HAIR, M_HAIR)
		g.prim(sphere(1.0, 8, 4), _xf(Vector3(0.066 * sd, 1.402, 0.262), Vector3(0, 0, -20 * sd), Vector3(0.088, 0.04, 0.045)), HAIR, M_HAIR)
		g.prim(sphere(1.0, 8, 4), _xf(Vector3(0.078 * sd, 1.558, 0.222), Vector3(0, 0, 10 * sd), Vector3(0.075, 0.032, 0.036)), HAIR, M_HAIR)
	return g


# ---------------------------------------------------------------- arms / staff / censer

func _geo_arm(side: float) -> Geo:
	var g := Geo.new()
	var s := Vector3(0.38 * side, 1.17, 0.0)
	var e: Vector3
	var w: Vector3
	var h: Vector3
	if side < 0.0:
		e = Vector3(-0.52, 0.985, 0.03)
		w = Vector3(-0.545, 0.84, 0.10)
		h = Vector3(-0.55, 0.78, 0.125)
	else:
		e = Vector3(0.52, 1.0, 0.04)
		w = Vector3(0.53, 0.955, 0.165)
		h = GRIP
	g.prim(sphere(0.132, 10, 6), _xf(s + Vector3(0.015 * side, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.95, 1.0)), LINEN)
	g.tube(PackedVector3Array([s, s.lerp(e, 0.5) + Vector3(0.01 * side, 0, 0), e]), PackedFloat32Array([0.105, 0.1, 0.09]),
		8, LINEN)
	g.prim(torus(0.062, 0.112, 10), _along(e, w, Vector3(1.0, 1.3, 1.0)), LINEN_SH)
	g.tube(PackedVector3Array([e, w]), PackedFloat32Array([0.076, 0.068]), 8, SKIN, M_SKIN)
	g.prim(sphere(0.105, 10, 6), _xf(h), SKIN, M_SKIN)
	return g


## Staff in staff space (origin = the fist): shaft, brass ferrule, leather grip, a crook curling forward over the
## censer, a herb bundle tied under the crook.
func _geo_staff() -> Geo:
	var g := Geo.new()
	g.prim(cyl(0.036, 0.042, 2.2, 8), _xf(Vector3(0, 0.23, 0)), WOOD, M_WOOD)
	g.prim(cyl(0.047, 0.044, 0.07, 8), _xf(Vector3(0, -0.84, 0)), BRASS, M_METAL)
	g.prim(cyl(0.05, 0.05, 0.15, 8), _xf(Vector3(0, 0.15, 0)), LEATHER)
	g.prim(cyl(0.05, 0.05, 0.10, 8), _xf(Vector3(0, -0.14, 0)), LEATHER)
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	for k: int in 12:
		var th := lerpf(-10.0, 205.0, float(k) / 11.0) * DEG
		pts.append(CROOK_C + Vector3(0, CROOK_R * sin(th), 0) - CROOK_DIR * (CROOK_R * cos(th)))
		rad.append(lerpf(0.037, 0.03, float(k) / 11.0))
	g.tube(pts, rad, 7, WOOD, M_WOOD)
	g.prim(sphere(0.04, 8, 4), _xf(pts[pts.size() - 1]), BRASS, M_METAL)
	# herb bundle tied under the crook, hanging leaves
	g.prim(torus(0.035, 0.055, 8), _xf(Vector3(0, 1.10, 0)), CORK)
	var leaf := NatureModel.leaf_mesh()
	for k: int in 5:
		var a := TAU * float(k) / 5.0 + 0.4
		var d := Vector3(sin(a), 0, cos(a))
		g.prim(leaf, NatureModel.leaf_xform(Vector3(0, 1.12, 0) + d * 0.03, d, Vector3(0.075, 0.025, 0.2), -55.0 - 8.0 * float(k % 2)),
			LEAF if k % 2 == 0 else HERB)
	return g


## Censer-kettle in censer space (origin = the hook, hanging down -Y, spout toward +Z): chain, iron bail, pot-bellied
## copper body with an iron band, a gap under the brass lid where the core glows, a spout.
func _geo_kettle() -> Geo:
	var g := Geo.new()
	var bail := PackedVector3Array()
	var brad := PackedFloat32Array()
	for k: int in 9:
		var a := lerpf(0.0, PI, float(k) / 8.0)
		bail.append(Vector3(cos(a) * 0.142, -0.325 + sin(a) * 0.17, 0.0))
		brad.append(0.014)
	g.tube(bail, brad, 5, IRON, M_METAL)
	g.lathe(_p([0.0, -0.595, 0.075, -0.595, 0.075, -0.595, 0.12, -0.575, 0.162, -0.515, 0.182, -0.445, 0.178, -0.39,
		0.157, -0.35, 0.136, -0.334, 0.136, -0.334, 0.15, -0.329, 0.15, -0.316, 0.128, -0.316, 0.125, -0.34]),
		Transform3D.IDENTITY, 12, COPPER, M_METAL)
	g.lathe(_p([0.175, -0.458, 0.192, -0.445, 0.175, -0.432]), Transform3D.IDENTITY, 12, IRON, M_METAL)
	g.lathe(_p([0.118, -0.268, 0.146, -0.262, 0.149, -0.248, 0.128, -0.232, 0.092, -0.212, 0.046, -0.202, 0.0, -0.2]),
		Transform3D.IDENTITY, 12, BRASS, M_METAL)
	g.prim(sphere(0.036, 8, 4), _xf(Vector3(0, -0.186, 0)), BRASS, M_METAL)
	g.tube(PackedVector3Array([Vector3(0, -0.47, 0.13), Vector3(0, -0.42, 0.205), Vector3(0, -0.36, 0.265),
		Vector3(0, -0.32, 0.30)]), PackedFloat32Array([0.045, 0.035, 0.028, 0.026]), 7, COPPER, M_METAL)
	g.shift(Vector3(0, KETTLE_UP, 0))
	g.tube(PackedVector3Array([Vector3(0, 0.03, 0), Vector3(0, -0.095, 0)]), PackedFloat32Array([0.016, 0.016]), 5, IRON, M_METAL)
	return g


## The glowing core: a belt showing in the gap under the lid, a ring of pierced holes on the belly, lid vents and
## the spout mouth. One mesh, own glow (mender_glow colour 0).
func _geo_core() -> Geo:
	var g := Geo.new()
	g.prim(sphere(1.0, 12, 5), _xf(Vector3(0, -0.29, 0), Vector3.ZERO, Vector3(0.157, 0.05, 0.157)), G_GREEN, 0.0)
	for k: int in 7:
		var a := TAU * float(k) / 7.0 + 0.45
		var d := Vector3(sin(a), 0, cos(a))
		g.prim(sphere(0.024, 5, 3), _xf(d * 0.168 + Vector3(0, -0.385, 0)), G_GREEN, 0.0)
	for k: int in 4:
		var a := TAU * float(k) / 4.0 + PI * 0.25
		var d := Vector3(sin(a), 0, cos(a))
		g.prim(sphere(1.0, 5, 2), _xf(d * 0.085 + Vector3(0, -0.214, 0), Vector3(0, a / DEG, 0), Vector3(0.018, 0.012, 0.03)), G_GREEN, 0.0)
	g.shift(Vector3(0, KETTLE_UP, 0))
	g.prim(sphere(0.024, 6, 3), _xf(SPOUT + Vector3(0, -0.012, -0.005)), G_GREEN, 0.0)
	return g
