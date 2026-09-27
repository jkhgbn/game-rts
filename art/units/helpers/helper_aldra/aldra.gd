extends WizardModel
## Aldra Stillwater, the Glass Warden (Ice T3 helper, t3-helpers.md 1 / 4.4 / 10; task TH.V3). Built to the wizard bar
## (10.1 parity: wizard budget, one signature glow, 0 lights, painted face with expressions, a green-scored hairdo).
## THE READ at 40 m: a tall woman in a long WHITE FELT COAT open down the front over a HAUBERK OF GLASS SCALES (glass-teal,
## the kingdom's only teal), a FAN OF GLASS SHARDS standing behind her head like a frozen collar, spiky glass pauldrons,
## and a pale steel RUNE-CHISEL STAFF taller than her whose clear crystal (fist-sized, ringed by three floating glass
## chips) is her one glow focus. Team colour: the coat's lining (seen down the open front and when it swings), the hem
## band, the lapels and the braid ribbon.
## Close up: a woman in her fifties, calm teal eyes, a teal rune on the brow, ash-blond hair in a CROWN BRAID threaded with
## glass beads (the hook seen from the RTS camera: a ring on top of the head), a long braid over her left shoulder down the
## coat front, two temple locks; chisels and a pouch at the belt, wrapped boots under the coat.
## Hooks (all safe before _ready): the kit's + WizardModel's, plus the helper set of t3-helpers.md 10.1:
##   play_arrival() (3.5 s: crouched in the glass shell, rises, taps the staff: a ringing flash, looks up),
##   play_fall() (the kit fall with a stagger onto the staff), play_revive() (alive, rises from one knee, crystal flare),
##   set_charge(0..1) (crystal brightness for wind-ups / cinematics), play_gesture(id) + point() / nod() / kneel() /
##   stand_up() / raise_weapon(), set_expression(&"neutral" | &"smile" | &"fierce"), get_crystal_origin().
## Abilities through play_cast(id): aldra_shatter (the chisel raised back then driven down and forward along the line,
## lunge; release 0.38), aldra_aegis (staff raised upright before her, off palm pushed out: 1.0 s), aldra_sentinel (both
## arms up, the staff slammed into the ground in a crouch at 0.72, held, rise: 1.5 s), aldra_ward (the passive tell: a
## short staff tap). Attack wizard_bolt (release 0.12): the crystal is flicked at the target. Close camera idle: every
## 8-13 s she traces a rune in the air with two fingers.
## Budget: 7 merged pivots + Face + Crystal + Chips + blob = 11 meshes, + 3 particle systems (1 looping) = 14 draw
## instances, 0 lights. Materials: Ice palette + kit eye / highlight + 5 own (aldra_felt, aldra_glass, aldra_glass_deep,
## aldra_hair, aldra_glow).

const HP := preload("res://art/units/helpers/helper_aldra/helper_paint.gd")
const OWN_DIR := "res://art/units/helpers/helper_aldra/"
const ICE_DIR := "res://art/units/ice/materials/"
const TEAL := Color(0.62, 0.95, 0.88)
const SHOULDER_L := Vector3(-0.30, 1.42, 0.0)
const SHOULDER_R := Vector3(0.30, 1.42, 0.0)
const HAND_L := Vector3(-0.40, 0.98, 0.10)
const GRIP := Vector3(0.46, 1.00, 0.20)
const STAFF_X := 0.46
const STAFF_Z := 0.20
const CRYSTAL_Y := 2.56
const FACE_C := Vector3(0.0, 1.76, 0.02)
const FACE_R := 0.19
const HEAD_SCALE := Vector3(0.92, 1.06, 0.96)
const EXPRESSIONS: Array[StringName] = [&"neutral", &"smile", &"fierce"]
const ABILITY_IDS: Array[StringName] = [&"aldra_shatter", &"aldra_aegis", &"aldra_sentinel", &"aldra_ward"]
const ARRIVAL_ID := &"aldra_arrival"
const REVIVE_ID := &"aldra_revive"
const IDLE_ID := &"_idle_rune"
const ARRIVAL_LEN := 3.5
const REVIVE_LEN := 1.2

static var _mats: Dictionary = {}

var _face: MeshInstance3D
var _chips: MeshInstance3D
var _spark: GPUParticles3D
var _expr: StringName = &"neutral"
var _face_shown: StringName = &""
var _charge: float = 0.0
var _kneeling: bool = false
var _pending: StringName = &""
var _fidget_next: float = 9.0
var _chip_a: float = 0.0
var _fired: bool = false


static func _m(name: String) -> Material:
	if not _mats.has(name):
		var path := OWN_DIR + name + ".tres"
		if name.begins_with("ice_"):
			path = ICE_DIR + name + ".tres"
		elif name.begins_with("unit_") or name.begins_with("fire_"):
			path = MAT_DIR + name + ".tres"
		_mats[name] = load(path)
	return _mats[name]


# ================================================================ helper hooks

## Arrival set-piece (t3-helpers.md 10.2): she steps out of the glass shell. 3.5 s. Safe before _ready.
func play_arrival() -> void:
	_kneeling = false
	_request(ARRIVAL_ID)


## Fallen: the kit fall (death_finished after 1.0 s) with a stagger onto the staff first.
func play_fall() -> void:
	_kneeling = false
	play_death()


## Revived at the keep door: alive again, rises from one knee with a crystal flare.
func play_revive() -> void:
	_kneeling = false
	revive()
	_request(REVIVE_ID)


## Crystal charge 0..1 (ability wind-ups, cinematics): brighter crystal, faster chips.
func set_charge(v: float) -> void:
	_charge = clampf(v, 0.0, 1.0)


## 19.V10 gestures: point, nod, kneel (held until stand_up), stand_up, raise_weapon.
func play_gesture(id: StringName) -> void:
	if id == &"kneel":
		_kneeling = true
	elif id == &"stand_up":
		_kneeling = false
	_request(id)


func point() -> void:
	play_gesture(&"point")


func nod() -> void:
	play_gesture(&"nod")


func kneel() -> void:
	play_gesture(&"kneel")


func stand_up() -> void:
	play_gesture(&"stand_up")


func raise_weapon() -> void:
	play_gesture(&"raise_weapon")


func is_kneeling() -> bool:
	return _kneeling


## Cinematic / UI hook: &"neutral" (default), &"smile", &"fierce". Unknown ids fall back to neutral.
func set_expression(id: StringName) -> void:
	_expr = id if EXPRESSIONS.has(id) else &"neutral"
	_update_face()


func get_expression() -> StringName:
	return _expr


## World-space centre of the staff crystal (ability VFX origin).
func get_crystal_origin() -> Vector3:
	if _orb == null or not is_inside_tree():
		return global_position + Vector3(STAFF_X, CRYSTAL_Y, STAFF_Z)
	return (_orb as Node3D).global_position


func get_beam_origin() -> Vector3:
	return get_crystal_origin()


func _request(id: StringName) -> void:
	if not _ready_done:
		_pending = id
		return
	play_cast(id)


func _after_ready() -> void:
	super._after_ready()
	if _pending != &"":
		var id := _pending
		_pending = &""
		play_cast(id)


# ================================================================ parts

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	add_part(leg_l, _leg_mesh(-1.0), null, Vector3.ZERO)
	add_part(leg_r, _leg_mesh(1.0), null, Vector3.ZERO)
	add_part(hips, _skirt_mesh(), null, Vector3.ZERO)
	add_part(chest, _torso_mesh(), null, Vector3.ZERO)
	add_part(head, _head_mesh(), null, Vector3.ZERO)
	add_part(arm_l, _arm_mesh(-1.0), null, Vector3.ZERO)
	add_part(arm_r, _arm_mesh(1.0), null, Vector3.ZERO)
	add_part(arm_r, _staff_mesh(), null, Vector3.ZERO)
	_face = add_part(head, _face_mesh(_face_target()), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Face")
	_face_shown = _face_target()
	# The signature glow: the crystal (own_glow, driven by WizardModel as the orb; it bobs a little over the claws).
	var cp := Vector3(STAFF_X, CRYSTAL_Y, STAFF_Z)
	var crystal := add_part(arm_r, _crystal_mesh(), null, cp, Vector3.ZERO, Vector3.ONE, true, "Crystal")
	crystal.set_meta(&"own_glow", true)
	_orb = crystal
	_bob = crystal
	_bob_rest = crystal.position
	_chips = add_part(arm_r, _chips_mesh(), null, cp, Vector3.ZERO, Vector3.ONE, true, "Chips")
	var motes := make_motes(TEAL, 6, 1.6, 0.14, 0.14, 0.05)
	motes.name = "CrystalMotes"
	motes.position = crystal.position
	arm_r.add_child(motes)
	_spark = make_motes(TEAL, 14, 0.5, 0.08, 2.0, 0.07, false, true)
	_spark.name = "ReleaseSparks"
	_spark.position = crystal.position
	arm_r.add_child(_spark)
	var burst := make_motes(Color(0.8, 1.0, 0.97), 16, 1.0, 0.3, 1.2, 0.07, false, true)
	burst.name = "DeathShards"
	burst.set_meta(&"death_fx", true)
	burst.position = Vector3(0, 1.2, 0.2)
	$Fx.add_child(burst)
	ensure_shadow_blob(0.55, Color(0.03, 0.05, 0.08, 0.45))


# ---------------------------------------------------------------- meshes (static, cached per game)

static func _leg_mesh(side: float) -> ArrayMesh:
	var key := "aldra_leg%d" % int(side)
	if HP.cached(key):
		return HP.cached(key)
	var boot := HP.bucket()
	var trouser := HP.bucket()
	var fur := HP.bucket()
	var x := 0.10 * side
	HP.seg(trouser, Vector3(x, 0.92, 0.0), Vector3(x, 0.26, 0.01), 0.075, 0.066, 8)
	HP.put(boot, CharacterModel.cyl(0.068, 0.082, 0.28, 8), HP.xf(Vector3(x, 0.14, 0.01)))
	HP.put(boot, CharacterModel.sphere(0.078, 8, 4), HP.xf(Vector3(x, 0.055, 0.075), Vector3.ZERO, Vector3(1.0, 0.7, 1.45)))
	HP.put(fur, CharacterModel.torus(0.06, 0.098, 10), HP.xf(Vector3(x, 0.27, 0.01)))
	for k: int in 2:
		HP.put(fur, CharacterModel.torus(0.07, 0.088, 10), HP.xf(Vector3(x, 0.11 + 0.08 * float(k), 0.01), Vector3(8.0 * float(k) - 4.0, 0, 0)))
	return HP.commit(key, [[boot, _m("ice_leather")], [trouser, _m("ice_steel")], [fur, _m("ice_fur")]])


## The coat's radius at height y (hem 0.07 -> neck 1.60) and the half-angle (rad) of its front opening.
static func _coat(y: float) -> Vector2:
	var prof: Array = [[0.07, 0.56, 36.0], [0.25, 0.49, 31.0], [0.45, 0.40, 26.0], [0.65, 0.335, 19.0], [0.85, 0.28, 13.0],
		[0.97, 0.262, 11.0], [1.10, 0.268, 18.0], [1.26, 0.292, 26.0], [1.38, 0.305, 29.0], [1.48, 0.275, 33.0],
		[1.56, 0.19, 40.0], [1.61, 0.13, 52.0]]
	for i: int in prof.size() - 1:
		var a: Array = prof[i]
		var b: Array = prof[i + 1]
		if y <= float(b[0]) or i == prof.size() - 2:
			var t := clampf((y - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			t = smoothstep(0.0, 1.0, t)
			return Vector2(lerpf(float(a[1]), float(b[1]), t), lerpf(float(a[2]), float(b[2]), t) * DEG)
	return Vector2(0.13, 52.0 * DEG)


static func _coat_point(u: float, y: float, grow: float = 0.0) -> Vector3:
	var c := _coat(y)
	var a := lerpf(c.y, TAU - c.y, u)
	var wave := 0.014 * sin(7.0 * a + 0.6) * clampf((0.6 - y) / 0.5, 0.0, 1.0)
	var r := c.x + wave + grow
	return Vector3(sin(a) * r, y, cos(a) * r * 0.9)


## A band of the open coat between heights y0 and y1 (rows), outer into `outer`, the lining (inset) into `lining`.
static func _coat_band(outer: Array, lining: Array, y0: float, y1: float, rows: int, grow: float) -> void:
	const COLS := 20
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in rows + 1:
		var y := lerpf(y0, y1, float(j) / float(rows))
		for i: int in COLS + 1:
			var p := _coat_point(float(i) / float(COLS), y, grow)
			pts.append(p)
			hints.append(Vector3(p.x, 0.12, p.z))
	HP.grid(outer, pts, hints, COLS, rows, false, lining, 0.012)


## The coat's front edges (lapels): team bands from y0 to y1.
static func _lapels(team: Array, y0: float, y1: float) -> void:
	for u: float in [0.0, 1.0]:
		var ctrl: Array[Vector3] = []
		for k: int in 6:
			ctrl.append(_coat_point(u, lerpf(y0, y1, float(k) / 5.0), 0.006))
		HP.tube(team, ctrl, 6, 0.022, 0.022, 4)


## Glass scales on a surface of revolution r(y) (front arc +-arc deg), rows from y0 to y1.
static func _scales(glass: Array, deep: Array, r_of_y: Callable, y0: float, y1: float, rows: int, per: int, arc: float) -> void:
	for j: int in rows:
		var y := lerpf(y0, y1, float(j) / float(maxi(rows - 1, 1)))
		var r: float = r_of_y.call(y)
		for i: int in per:
			var off := 0.5 if j % 2 == 1 else 0.0
			var a := lerpf(-arc, arc, (float(i) + off) / float(per - 1)) * DEG
			if absf(a) > arc * DEG + 0.01:
				continue
			var n := Vector3(sin(a), -0.25, cos(a) * 0.9).normalized()
			var c := Vector3(sin(a) * r, y, cos(a) * r * 0.86) + n * 0.004
			HP.shard(glass if (i + j) % 3 != 0 else deep, c, n, 0.042, 0.016, 0.004, 4, 0.3 * float(j))


static func _skirt_r(y: float) -> float:
	return lerpf(0.36, 0.232, clampf((y - 0.30) / 0.66, 0.0, 1.0))


## Hips: the coat skirt (white felt, team lining, a team hem band), the glass hauberk skirt seen down the opening,
## the belt with its glass buckle, chisels and a pouch.
static func _skirt_mesh() -> ArrayMesh:
	if HP.cached("aldra_skirt"):
		return HP.cached("aldra_skirt")
	var felt := HP.bucket()
	var lining := HP.bucket()
	var team := HP.bucket()
	var glass := HP.bucket()
	var deep := HP.bucket()
	var leather := HP.bucket()
	var steel := HP.bucket()
	var dyed := HP.bucket()
	_coat_band(team, lining, 0.07, 0.17, 1, 0.004)
	_coat_band(dyed, lining, 0.17, 0.42, 2, 0.0)
	_coat_band(felt, lining, 0.42, 0.97, 5, 0.0)
	_lapels(team, 0.08, 0.96)
	# rune stitches on the hem band: small pale diamonds
	for i: int in 10:
		var u := (float(i) + 0.5) / 10.0
		var p := _coat_point(u, 0.12, 0.012)
		var n := Vector3(p.x, 0.0, p.z).normalized()
		HP.shard(glass, p, n, 0.022, 0.006, 0.002, 4)
	# the hauberk skirt: a glass cone, scales on the front
	HP.lathe(deep, PackedVector2Array([Vector2(0.37, 0.28), Vector2(0.30, 0.60), Vector2(0.245, 0.90), Vector2(0.23, 0.98)]), 16,
		Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.86)), Vector3.ZERO))
	_scales(glass, deep, _skirt_r, 0.36, 0.90, 5, 6, 40.0)
	# belt, glass buckle, chisels on the right hip, pouch on the left
	HP.put(leather, CharacterModel.torus(0.24, 0.285, 18), HP.xf(Vector3(0, 0.95, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.88)))
	HP.shard(glass, Vector3(0, 0.95, 0.255), Vector3(0, 0, 1), 0.05, 0.025, 0.006, 6)
	for k: int in 3:
		var x := 0.17 + 0.035 * float(k)
		HP.seg(steel, Vector3(x, 0.93, 0.15 - 0.03 * float(k)), Vector3(x + 0.01, 0.74 + 0.03 * float(k), 0.17 - 0.03 * float(k)), 0.012, 0.006, 5)
		HP.put(leather, CharacterModel.cyl(0.016, 0.016, 0.06, 6), HP.xf(Vector3(x, 0.95, 0.15 - 0.03 * float(k))))
	HP.put(leather, CharacterModel.box(Vector3(0.11, 0.12, 0.06)), HP.xf(Vector3(-0.19, 0.86, 0.16), Vector3(0, -30, 0)))
	HP.put(leather, CharacterModel.sphere(0.04, 6, 3), HP.xf(Vector3(-0.19, 0.92, 0.19), Vector3.ZERO, Vector3(1.4, 0.5, 0.8)))
	return HP.commit("aldra_skirt", [[felt, _m("aldra_felt")], [dyed, _m("ice_stone")], [lining, _m("ice_cloth_dark")], [team, _m("ice_cloth")],
		[glass, _m("aldra_glass")], [deep, _m("aldra_glass_deep")], [leather, _m("ice_leather")], [steel, _m("ice_steel")]])


static func _torso_r(y: float) -> float:
	if y < 1.26:
		return lerpf(0.235, 0.27, clampf((y - 0.95) / 0.31, 0.0, 1.0))
	return lerpf(0.27, 0.20, clampf((y - 1.26) / 0.24, 0.0, 1.0))


## Chest: glass hauberk (scaled front), the coat top (open V, team lining and lapels, a felt collar), spiky glass
## pauldrons and the fan of glass shards standing behind the head.
static func _torso_mesh() -> ArrayMesh:
	if HP.cached("aldra_torso"):
		return HP.cached("aldra_torso")
	var felt := HP.bucket()
	var lining := HP.bucket()
	var team := HP.bucket()
	var glass := HP.bucket()
	var deep := HP.bucket()
	var metal := HP.bucket()
	var dark := HP.bucket()
	var fur := HP.bucket()
	HP.lathe(deep, PackedVector2Array([Vector2(0.225, 0.93), Vector2(0.24, 1.10), Vector2(0.27, 1.26), Vector2(0.275, 1.38),
		Vector2(0.235, 1.48), Vector2(0.14, 1.56), Vector2(0.07, 1.61)]), 16, Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.86)), Vector3.ZERO))
	_scales(glass, deep, _torso_r, 1.02, 1.44, 5, 5, 32.0)
	_coat_band(felt, lining, 0.93, 1.61, 7, 0.02)
	_lapels(team, 0.94, 1.60)
	# felt collar round the neck, a glass clasp on each lapel at the chest
	HP.put(felt, CharacterModel.torus(0.10, 0.155, 16), HP.xf(Vector3(0, 1.595, -0.01), Vector3(-8, 0, 0), Vector3(1.0, 1.3, 0.95)))
	for sx: float in [-1.0, 1.0]:
		var p := _coat_point(0.0 if sx > 0.0 else 1.0, 1.30, 0.02)
		HP.shard(glass, p, Vector3(0.2 * sx, 0.1, 1.0), 0.03, 0.02, 0.006, 6)
	HP.seg(metal, _coat_point(0.0, 1.30, 0.03), _coat_point(1.0, 1.30, 0.03), 0.006, 0.006, 4)
	# the mantle: a wide team-dark shoulder cape (felt lining), open at the front, a white fur roll at its hem
	_mantle(dark, felt, fur)
	# pauldrons on the mantle: a deep glass cap, three glass plates, two up-swept shards
	for sx: float in [-1.0, 1.0]:
		var sc := Vector3(0.36 * sx, 1.50, 0.0)
		HP.put(deep, CharacterModel.sphere(0.14, 10, 5), HP.xf(sc, Vector3.ZERO, Vector3(1.05, 0.6, 1.05)))
		for k: int in 3:
			var c := sc + Vector3(0.04 * sx * float(k), -0.04 * float(k) + 0.035, 0.0)
			HP.lens(glass, c, Vector3(sx * 0.9, -0.45, 0.0), Vector3(0, 0, 1), 0.22 - 0.02 * float(k), 0.25, 0.04)
		HP.shard(glass, sc + Vector3(0.05 * sx, 0.08, -0.02), Vector3(0.5 * sx, 1.0, -0.1), 0.04, 0.26, 0.02, 5)
		HP.shard(deep, sc + Vector3(0.12 * sx, 0.04, 0.05), Vector3(0.9 * sx, 0.7, 0.15), 0.032, 0.16, 0.015, 5)
	# THE CREST: a fan of glass blades standing behind the head like a frozen sunburst (9 blades, the centre tallest),
	# rising from a deep glass yoke on the mantle's back
	HP.put(deep, CharacterModel.torus(0.11, 0.18, 14), HP.xf(Vector3(0, 1.575, -0.08), Vector3(-25, 0, 0), Vector3(1.0, 1.0, 0.8)))
	for k: int in 9:
		var off := float(k) - 4.0
		var fan := off * 17.0 * DEG
		var up := Basis(Vector3.FORWARD, fan) * Vector3.UP
		up = (up + Vector3(0, 0, -0.30)).normalized()
		var base := Vector3(sin(fan) * 0.10, 1.56, -0.17)
		var h := 0.78 - 0.085 * absf(off)
		HP.shard(glass if k % 2 == 0 else deep, base + up * h * 0.22, up, 0.052 - 0.003 * absf(off), h * 0.78, h * 0.22, 4, 0.785)
	return HP.commit("aldra_torso", [[felt, _m("aldra_felt")], [lining, _m("ice_cloth_dark")], [team, _m("ice_cloth")],
		[glass, _m("aldra_glass")], [deep, _m("aldra_glass_deep")], [metal, _m("ice_metal")], [dark, _m("ice_cloth_dark")],
		[fur, _m("ice_fur_pale")]])


## Mantle point: u across (0 = the right front edge, 1 = the left, round the back), v 0 (neck) -> 1 (hem).
static func _mantle_point(u: float, v: float, grow: float = 0.0) -> Vector3:
	var gap := lerpf(40.0, 30.0, v) * DEG
	var a := lerpf(gap, TAU - gap, u)
	var side := absf(sin(a))
	var r := 0.14 + (0.30 + 0.08 * side) * pow(sin(v * PI * 0.5), 0.7) + grow
	var back := maxf(0.0, -cos(a))
	var y := 1.61 - 0.30 * pow(v, 1.3) - 0.10 * back * v * v + 0.012 * sin(9.0 * a) * v
	return Vector3(sin(a) * r, y, cos(a) * r * 0.86)


static func _mantle(outer: Array, lining: Array, fur: Array) -> void:
	const COLS := 22
	const ROWS := 5
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in ROWS + 1:
		for i: int in COLS + 1:
			var p := _mantle_point(float(i) / float(COLS), float(j) / float(ROWS), 0.03)
			pts.append(p)
			hints.append(Vector3(p.x, 0.5, p.z))
	HP.grid(outer, pts, hints, COLS, ROWS, false, lining, 0.012)
	for i: int in 17:
		var p := _mantle_point((float(i) + 0.5) / 17.0, 1.0, 0.035)
		HP.put(fur, CharacterModel.sphere(0.05, 6, 3), HP.xf(p, Vector3.ZERO, Vector3(1.3, 0.8, 1.3)))


## Head: neck, face (skin), nose, ears; the hair: a cap, two side sweeps from a centre part, two temple locks, the
## CROWN BRAID threaded with glass beads, and the long braid over her left shoulder down the coat front (team ribbon,
## glass drop, a tapered tail).
static func _head_mesh() -> ArrayMesh:
	if HP.cached("aldra_head"):
		return HP.cached("aldra_head")
	var skin := HP.bucket()
	var hair := HP.bucket()
	var beads := HP.bucket()
	var team := HP.bucket()
	HP.seg(skin, Vector3(0, 1.50, -0.01), Vector3(0, 1.66, 0.0), 0.058, 0.052, 8)
	HP.put(skin, CharacterModel.sphere(FACE_R, 12, 6), HP.xf(FACE_C, Vector3.ZERO, HEAD_SCALE))
	HP.seg(skin, Vector3(0, 1.785, 0.184), Vector3(0, 1.728, 0.207), 0.020, 0.015, 6)
	HP.put(skin, CharacterModel.sphere(0.017, 6, 3), HP.xf(Vector3(0, 1.727, 0.205)))
	HP.put(skin, CharacterModel.sphere(0.05, 8, 4), HP.xf(Vector3(0, 1.645, 0.12), Vector3.ZERO, Vector3(1.0, 0.8, 0.8)))
	for sx: float in [-1.0, 1.0]:
		HP.put(skin, CharacterModel.sphere(0.034, 6, 3), HP.xf(Vector3(0.168 * sx, 1.75, 0.0), Vector3.ZERO, Vector3(0.5, 1.0, 0.8)))
	# hair cap (under the braid), then the locks
	HP.put(hair, CharacterModel.sphere(0.192, 12, 6), HP.xf(Vector3(0, 1.805, -0.03), Vector3(-10, 0, 0), Vector3(0.98, 0.94, 1.02)))
	HP.put(hair, CharacterModel.sphere(0.12, 10, 5), HP.xf(Vector3(0, 1.70, -0.13), Vector3.ZERO, Vector3(1.05, 0.9, 0.8)))
	for sx: float in [-1.0, 1.0]:
		HP.lock(hair, [], [Vector3(0.015 * sx, 1.975, 0.10), Vector3(0.12 * sx, 1.965, 0.15), Vector3(0.195 * sx, 1.86, 0.07),
			Vector3(0.18 * sx, 1.74, -0.07)], Vector3(0.6 * sx, 0.7, 0.3).normalized(), 0.15, 0.05, 5, 1.0, 12.0 * sx)
		HP.lock(hair, [], [Vector3(0.10 * sx, 1.90, 0.145), Vector3(0.165 * sx, 1.85, 0.172), Vector3(0.18 * sx, 1.75, 0.15),
			Vector3(0.162 * sx, 1.655, 0.115)], Vector3(0.8 * sx, 0.1, 0.6).normalized(), 0.075, 0.034, 4, 1.0, -10.0 * sx)
	# the crown braid: a ring round the head, tilted back, beads every third lobe
	var ring: Array[Vector3] = []
	var tilt := Basis(Vector3.RIGHT, -14.0 * DEG)
	for k: int in 13:
		var a := TAU * float(k) / 12.0
		ring.append(Vector3(0, 1.905, -0.035) + tilt * Vector3(sin(a) * 0.176, 0.0, cos(a) * 0.172))
	HP.braid(hair, ring, 16, 0.042, 0.042, beads, 3, 0.019)
	# the long braid: from behind the left ear over the shoulder, down the coat front
	var path: Array[Vector3] = [Vector3(-0.13, 1.74, -0.10), Vector3(-0.18, 1.62, -0.01), Vector3(-0.165, 1.50, 0.17),
		Vector3(-0.15, 1.36, 0.255), Vector3(-0.145, 1.22, 0.275), Vector3(-0.14, 1.10, 0.265)]
	var end := HP.braid(hair, path, 12, 0.044, 0.030, beads, 4, 0.017)
	HP.put(team, CharacterModel.torus(0.018, 0.036, 10), HP.xf(end + Vector3(0, -0.035, 0.0)))
	HP.shard(beads, end + Vector3(0, -0.07, 0.01), Vector3.UP, 0.024, 0.02, 0.045, 6)
	HP.lock(hair, [], [end + Vector3(0, -0.03, -0.01), end + Vector3(0.01, -0.09, 0.0), end + Vector3(-0.01, -0.15, 0.01),
		end + Vector3(0.0, -0.20, 0.02)], Vector3(0, 0, 1), 0.07, 0.03, 4)
	return HP.commit("aldra_head", [[skin, _m("ice_skin")], [hair, _m("aldra_hair")], [beads, _m("aldra_glass")],
		[team, _m("ice_cloth")]])


## One arm: white felt sleeve, a team-dark bell cuff with a glass bead trim, the hand.
static func _arm_mesh(side: float) -> ArrayMesh:
	var key := "aldra_arm%d" % int(side)
	if HP.cached(key):
		return HP.cached(key)
	var felt := HP.bucket()
	var cuff := HP.bucket()
	var skin := HP.bucket()
	var glass := HP.bucket()
	var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
	var hand := GRIP if side > 0.0 else HAND_L
	var d := hand - sh
	HP.seg(felt, sh + Vector3(0, 0.04, 0), sh + d * 0.72, 0.092, 0.08, 8)
	HP.put(felt, CharacterModel.sphere(0.092, 8, 4), HP.xf(sh + Vector3(0, 0.04, 0)))
	HP.seg(cuff, sh + d * 0.64, sh + d * 0.90, 0.085, 0.13, 10)
	for k: int in 6:
		var a := TAU * float(k) / 6.0
		var dn := d.normalized()
		var bx := dn.cross(Vector3.FORWARD).normalized()
		var bz := dn.cross(bx)
		HP.put(glass, CharacterModel.sphere(0.016, 6, 3), HP.xf(sh + d * 0.90 + (bx * cos(a) + bz * sin(a)) * 0.13))
	HP.put(skin, CharacterModel.sphere(0.062, 8, 4), HP.xf(hand + d.normalized() * 0.02, Vector3.ZERO, Vector3(1.0, 1.15, 1.0)))
	return HP.commit(key, [[felt, _m("aldra_felt")], [cuff, _m("ice_cloth_dark")], [skin, _m("ice_skin")], [glass, _m("aldra_glass")]])


## The rune-chisel staff (static, in the right fist): pale steel shaft with rune bands, wrapped grip, a foot spike, the
## chisel head (a bevelled wedge) and four glass claws cupping the crystal.
static func _staff_mesh() -> ArrayMesh:
	if HP.cached("aldra_staff"):
		return HP.cached("aldra_staff")
	var metal := HP.bucket()
	var steel := HP.bucket()
	var leather := HP.bucket()
	var glass := HP.bucket()
	var o := Vector3(STAFF_X, 0.0, STAFF_Z)
	HP.seg(metal, o + Vector3(0, 0.08, 0), o + Vector3(0, 2.32, 0), 0.036, 0.032, 8)
	HP.put(steel, CharacterModel.cyl(0.0, 0.04, 0.10, 6), HP.xf(o + Vector3(0, 0.05, 0), Vector3(180, 0, 0)))
	for y: float in [0.45, 0.70, 1.45, 1.75, 2.05]:
		HP.put(steel, CharacterModel.torus(0.03, 0.05, 8), HP.xf(o + Vector3(0, y, 0)))
	HP.put(leather, CharacterModel.cyl(0.044, 0.044, 0.22, 8), HP.xf(o + Vector3(0, 1.0, 0)))
	# chisel head: a collar, a flat bevelled wedge each side (the chisel edge), four glass claws
	HP.put(steel, CharacterModel.cyl(0.07, 0.045, 0.12, 8), HP.xf(o + Vector3(0, 2.36, 0)))
	for sx: float in [-1.0, 1.0]:
		HP.put(steel, CharacterModel.prism(Vector3(0.10, 0.20, 0.03)), HP.xf(o + Vector3(0.085 * sx, 2.36, 0), Vector3(0, 0, 180.0 + 35.0 * sx)))
	for k: int in 4:
		var a := (45.0 + 90.0 * float(k)) * DEG
		var out := Vector3(sin(a), 0, cos(a))
		HP.shard(glass, o + Vector3(0, 2.44, 0) + out * 0.07, (out * 0.55 + Vector3.UP).normalized(), 0.022, 0.16, 0.02, 4)
	return HP.commit("aldra_staff", [[metal, _m("ice_metal")], [steel, _m("ice_steel")], [leather, _m("ice_leather")],
		[glass, _m("aldra_glass")]])


## The crystal (node-local: centred at its node): a clear six-sided gem, teal glow.
static func _crystal_mesh() -> ArrayMesh:
	if HP.cached("aldra_crystal"):
		return HP.cached("aldra_crystal")
	var g := HP.bucket()
	HP.shard(g, Vector3.ZERO, Vector3.UP, 0.085, 0.17, 0.10, 6, 0.2)
	return HP.commit("aldra_crystal", [[g, _m("aldra_glow")]])


## Three glass chips floating round the crystal (node-local), turned in _wizard_process.
static func _chips_mesh() -> ArrayMesh:
	if HP.cached("aldra_chips"):
		return HP.cached("aldra_chips")
	var g := HP.bucket()
	for k: int in 3:
		var a := TAU * float(k) / 3.0
		HP.shard(g, Vector3(sin(a) * 0.19, 0.02 * float(k), cos(a) * 0.19), Vector3(0.2, 1.0, 0.1), 0.028, 0.07, 0.04, 4)
	return HP.commit("aldra_chips", [[g, _m("aldra_glass")]])


# ---------------------------------------------------------------- painted face

## Painted face decals for one expression, cached. Surfaces: eye white (ice_hair), iris (aldra_glass_deep), pupil / lash
## (unit_eye_dark), highlight (ice_hair), brows (aldra_hair), fine lines + mouth (ice_leather), brow rune (aldra_glass_deep).
static func _face_mesh(id: StringName) -> ArrayMesh:
	var key := "aldra_face_" + String(id)
	if HP.cached(key):
		return HP.cached(key)
	var f := HP.face_new(FACE_C, FACE_R, CharacterModel.sphere(FACE_R, 12, 6), HEAD_SCALE)
	var keys := {"white": &"white", "iris": &"iris", "pupil": &"dark", "hi": &"white_hi", "lash": &"dark"}
	var eye := Vector2(0.066, 0.016)
	for sx: float in [1.0, -1.0]:
		match id:
			&"smile":
				# soft happy eyes: lower lids up, a smile crease at the outer corner
				HP.face_eye(f, eye, 0.029, 0.013, 0.004, 0.006, 0.010, sx, keys)
				HP.face_strip(f, &"brow", HP.mirror(HP.bez(Vector2(0.034, 0.056), Vector2(0.068, 0.076), Vector2(0.104, 0.060)), sx), Vector3(0.006, 0.0065, 0.0025), 0.003)
				HP.face_strip(f, &"line", HP.mirror(HP.bez(Vector2(0.100, 0.020), Vector2(0.108, 0.008), Vector2(0.104, -0.004)), sx), Vector3(0.0015, 0.002, 0.001), 0.003)
			&"fierce":
				HP.face_eye(f, eye, 0.030, 0.012, 0.009, -0.004, 0.011, sx, keys)
				HP.face_strip(f, &"brow", HP.mirror(HP.bez(Vector2(0.026, 0.040), Vector2(0.062, 0.050), Vector2(0.104, 0.064)), sx), Vector3(0.0075, 0.007, 0.003), 0.003)
				HP.face_strip(f, &"line", HP.mirror(PackedVector2Array([Vector2(0.018, 0.050), Vector2(0.014, 0.066)]), sx), Vector3(0.0015, 0.0015, 0.001), 0.003)
			_:
				HP.face_eye(f, eye, 0.030, 0.016, 0.009, 0.004, 0.011, sx, keys)
				HP.face_strip(f, &"brow", HP.mirror(HP.bez(Vector2(0.032, 0.052), Vector2(0.068, 0.068), Vector2(0.106, 0.056)), sx), Vector3(0.0065, 0.0065, 0.0025), 0.003)
		# lines of age: crow's feet, the fold under the eye, cheek line from the nose
		HP.face_strip(f, &"line", HP.mirror(PackedVector2Array([Vector2(0.102, 0.022), Vector2(0.116, 0.028)]), sx), Vector3(0.0012, 0.0016, 0.0008), 0.003)
		HP.face_strip(f, &"line", HP.mirror(PackedVector2Array([Vector2(0.103, 0.012), Vector2(0.117, 0.008)]), sx), Vector3(0.0012, 0.0016, 0.0008), 0.003)
		HP.face_strip(f, &"line", HP.mirror(HP.bez(Vector2(0.046, -0.004), Vector2(0.066, -0.010), Vector2(0.086, -0.004)), sx), Vector3(0.0008, 0.0014, 0.0008), 0.003)
		HP.face_strip(f, &"line", HP.mirror(HP.bez(Vector2(0.030, -0.040), Vector2(0.050, -0.068), Vector2(0.050, -0.094)), sx), Vector3(0.0012, 0.0018, 0.0008), 0.003)
	# the brow rune: a small teal chevron with a dot
	HP.face_strip(f, &"rune", PackedVector2Array([Vector2(-0.016, 0.090), Vector2(0.0, 0.078), Vector2(0.016, 0.090)]), Vector3(0.0025, 0.003, 0.0025), 0.003)
	HP.face_fill(f, &"rune", HP.ellipse(Vector2(0.0, 0.100), Vector2(0.004, 0.004), 0.0, 8), 0.003)
	match id:
		&"smile":
			HP.face_strip(f, &"mouth", HP.bez(Vector2(-0.040, -0.084), Vector2(0.0, -0.104), Vector2(0.040, -0.084)), Vector3(0.0022, 0.0055, 0.0022), 0.003)
			for sx: float in [1.0, -1.0]:
				HP.face_strip(f, &"mouth", HP.mirror(PackedVector2Array([Vector2(0.038, -0.085), Vector2(0.046, -0.078)]), sx), Vector3(0.002, 0.0016, 0.001), 0.003)
		&"fierce":
			HP.face_strip(f, &"mouth", HP.bez(Vector2(-0.036, -0.090), Vector2(0.0, -0.086), Vector2(0.036, -0.092)), Vector3(0.0026, 0.004, 0.0026), 0.003)
		_:
			HP.face_strip(f, &"mouth", HP.bez(Vector2(-0.036, -0.088), Vector2(0.0, -0.093), Vector2(0.036, -0.088)), Vector3(0.0022, 0.0045, 0.0022), 0.003)
	HP.face_strip(f, &"line", HP.bez(Vector2(-0.018, -0.108), Vector2(0.0, -0.111), Vector2(0.018, -0.108)), Vector3(0.001, 0.0018, 0.001), 0.003)
	return HP.face_commit(f, key, [&"white", &"iris", &"dark", &"white_hi", &"brow", &"line", &"mouth", &"rune"],
		{&"white": _m("ice_hair"), &"iris": _m("aldra_glass_deep"), &"dark": _m("unit_eye_dark"), &"white_hi": _m("ice_hair"),
		&"brow": _m("aldra_hair"), &"line": _m("ice_leather"), &"mouth": _m("ice_leather"), &"rune": _m("aldra_glass_deep")})


func _face_target() -> StringName:
	if _expr != &"neutral" or _dead or _tier != 0:
		return _expr
	if _level_t < 1.6 or (_action == &"cast" and (_cast_id == &"nod" or _cast_id == REVIVE_ID)):
		return &"smile"
	if (_action == &"cast" and (ABILITY_IDS.has(_cast_id) or _cast_id == &"raise_weapon")) or _action == &"attack":
		return &"fierce"
	return _expr


func _update_face() -> void:
	if _face == null:
		return
	var id := _face_target()
	if id != _face_shown:
		_face_shown = id
		_face.mesh = _face_mesh(id)


# ================================================================ poses

func _pose_cast(spell: StringName, t: float) -> float:
	if HP.is_gesture(spell):
		var gl := HP.gesture_pose(self, spell, t, _kneeling)
		if spell == &"raise_weapon":
			var k := _k3(t, 0.0, 0.35, 1.15, 1.6, 1.0, 1.0)
			_cast_boost = 1.0 + 1.5 * k
		return gl
	match spell:
		&"aldra_shatter":
			var w := _k3(t, 0.0, 0.24, 0.30, 0.34, 1.0, 0.0)
			var s := _k3(t, 0.26, 0.38, 0.58, 0.90, 1.0, 1.0)
			rot(P_ARM_R, Vector3((-34.0 * w + 78.0 * s) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.18 * w + 0.02 * s, 0.24 * s))
			rot(P_ARM_L, Vector3((-30.0 * w + 30.0 * s) * DEG, 0, (-40.0 * s) * DEG))
			rot(P_CHEST, Vector3((-9.0 * w + 16.0 * s) * DEG, (-12.0 * w + 8.0 * s) * DEG, 0))
			rot(P_HEAD, Vector3((6.0 * w - 10.0 * s) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, -0.07 * s, 0.16 * s))
			rot(P_LEG_R, Vector3(-18.0 * s * DEG, 0, 0))
			rot(P_LEG_L, Vector3(14.0 * s * DEG, 0, 0))
			_release_at(t, 0.38)
			_cast_boost = 1.0 + 2.5 * maxf(w, s)
			return 0.9
		&"aldra_aegis":
			var k := _k3(t, 0.0, 0.25, 0.70, 1.0, 1.0, 1.0)
			pos(P_ARM_R, Vector3(-0.04 * k, 0.07 * k, 0.08 * k))
			rot(P_ARM_R, Vector3(-38.0 * DEG * k, 0, -10.0 * DEG * k))
			rot(P_ARM_L, Vector3(-78.0 * DEG * k, 0, 22.0 * DEG * k))
			rot(P_HEAD, Vector3(-6.0 * DEG * k, 0, 0))
			rot(P_CHEST, Vector3(-5.0 * DEG * k, 0, 0))
			_release_at(t, 0.3)
			_cast_boost = 1.0 + 2.0 * k
			return 1.0
		&"aldra_sentinel":
			var up := _k3(t, 0.0, 0.55, 0.62, 0.74, 1.0, 1.0)
			var slam := _k3(t, 0.62, 0.74, 1.10, 1.50, 1.0, 1.0)
			pos(P_ARM_R, Vector3(0, 0.08 * up - 0.06 * slam, 0.03 * up + 0.16 * slam))
			rot(P_ARM_R, Vector3((-30.0 * up + 40.0 * slam) * DEG, 0, 50.0 * up * (1.0 - slam) * DEG))
			rot(P_ARM_L, Vector3((-150.0 * up + 110.0 * slam) * DEG, 0, (-20.0 * up - 30.0 * slam) * DEG))
			rot(P_CHEST, Vector3((-10.0 * up + 22.0 * slam) * DEG, 0, 0))
			rot(P_HEAD, Vector3((-16.0 * up + 6.0 * slam) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0.04 * up - 0.20 * slam, 0.08 * slam))
			rot(P_LEG_L, Vector3(-30.0 * slam * DEG, 0, 0))
			rot(P_LEG_R, Vector3(22.0 * slam * DEG, 0, 0))
			_release_at(t, 0.74)
			var flash := 1.0 if t > 0.72 and t < 0.95 else 0.0
			_cast_boost = 1.0 + 2.0 * up + 3.0 * flash
			return 1.5
		&"aldra_ward":
			return _pose_tap(t, 0.0)
		ARRIVAL_ID:
			var c := 1.0 - smoothstep(0.55, 1.8, t)
			HP.kneel_weights(self, c)
			rot(P_HEAD, Vector3(18.0 * DEG * c, 0, 0))
			var tap_len := _pose_tap(t, 1.95)
			var proud := _k3(t, 2.3, 2.7, 3.2, 3.5, 1.0, 1.0)
			rot(P_HEAD, Vector3(-9.0 * DEG * proud, 0, 0))
			rot(P_CHEST, Vector3(-4.0 * DEG * proud, 0, 0))
			rot(P_ARM_L, Vector3(-20.0 * DEG * proud, 0, 18.0 * DEG * proud))
			_cast_boost = maxf(_cast_boost, 1.0 + 1.2 * (1.0 - c))
			return maxf(ARRIVAL_LEN, tap_len)
		REVIVE_ID:
			var c := 1.0 - smoothstep(0.15, 1.05, t)
			HP.kneel_weights(self, c)
			var fl := _k3(t, 0.5, 0.75, 0.85, 1.2, 1.0, 1.0)
			_cast_boost = 1.0 + 3.0 * fl
			return REVIVE_LEN
		IDLE_ID:
			if _speed >= 0.3:
				return 0.0
			var k := _k3(t, 0.0, 0.45, 1.8, 2.3, 1.0, 1.0)
			var tr := sin(t * 6.0) * _k3(t, 0.4, 0.6, 1.6, 1.8, 1.0, 1.0)
			rot(P_ARM_L, Vector3((-62.0 + 8.0 * tr) * DEG * k, 0, (14.0 + 12.0 * tr) * DEG * k))
			rot(P_HEAD, Vector3(10.0 * DEG * k, -14.0 * DEG * k, 0))
			rot(P_CHEST, Vector3(0, -6.0 * DEG * k, 0))
			_cast_boost = 1.0 + 0.4 * k
			return 2.3
		_:
			# unknown ids: a quick crystal thrust
			var k := _k3(t, 0.0, 0.18, 0.30, 0.6, 1.0, 1.0)
			rot(P_ARM_R, Vector3(50.0 * DEG * k, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.06 * k, 0.2 * k))
			rot(P_CHEST, Vector3(8.0 * DEG * k, 0, 0))
			_release_at(t, 0.18)
			_cast_boost = 1.0 + 2.0 * k
			return 0.6


## Lift the staff and tap its foot down at t0 (a ringing flash). Returns the end time.
func _pose_tap(t: float, t0: float) -> float:
	var lift := _k3(t, t0, t0 + 0.30, t0 + 0.36, t0 + 0.42, 1.0, 1.0)
	var tap := _k3(t, t0 + 0.36, t0 + 0.42, t0 + 0.5, t0 + 0.9, 1.0, 1.0)
	pos(P_ARM_R, Vector3(0, 0.08 * lift, 0))
	pos(P_ROOT, Vector3(0, -0.02 * tap, 0))
	rot(P_HEAD, Vector3(-6.0 * DEG * tap, 0, 0))
	_release_at(t, t0 + 0.42)
	_cast_boost = maxf(_cast_boost, 1.0 + 2.5 * tap)
	return t0 + 0.9


func _release_at(t: float, rel: float) -> void:
	if t < rel:
		_fired = false
	elif not _fired:
		_fired = true
		if _spark and _tier < 2:
			_spark.restart()


func _on_action_event(ev: StringName) -> void:
	if ev == &"attack_start" or ev == &"cast_start":
		_fired = false


# ================================================================ per frame

func _extra_process(dt: float) -> void:
	super._extra_process(dt)
	if _charge > 0.001 and not _dead and _orb:
		_orb.set_instance_shader_parameter(&"glow_boost", glow_level() * (1.0 + 2.5 * _charge) * maxf(_cast_boost, 1.0))
		_orb_written = -1.0


func _wizard_process(dt: float) -> void:
	if _chips == null:
		return
	_update_face()
	if not _dead:
		_body_extras()
	else:
		_death_extras()
	# chips orbit the crystal (close / mid camera only)
	if _tier < 2:
		_chip_a = fmod(_chip_a + dt * (0.9 + 2.5 * _charge), TAU)
		_chips.rotation.y = _chip_a
	_chips.visible = not _dead or _death_t < 0.3
	# idle fidget: close camera only, every 8-13 s
	if _action == &"" and not _dead and _speed < 0.3 and _tier == 0 and _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN \
			and not _kneeling:
		if _t >= _fidget_next:
			_fidget_next = _t + 8.0 + fmod(_phase_off * 5.3 + _t, 5.0)
			play_cast(IDLE_ID)
	elif _action != &"" or _speed >= 0.3:
		_fidget_next = maxf(_fidget_next, _t + 4.0)
	if _kneeling and _action == &"" and not _dead:
		play_cast(&"kneel")


func _body_extras() -> void:
	if _walk_w > 0.0:
		var sw := sin(TAU * _walk_p) * _walk_w
		rot(P_HIPS, Vector3(0, 5.0 * DEG * sw, 1.5 * DEG * sw))
		rot(P_CHEST, Vector3(3.0 * DEG * _walk_w, -3.0 * DEG * sw, 0))
		rot(P_ARM_R, Vector3(-5.0 * DEG * _walk_w, 0, 0))
	if _action == &"attack":
		var a := _k3(_action_t, 0.0, attack_windup, attack_windup + 0.05, 0.45, 1.0, 1.0)
		rot(P_ARM_R, Vector3(64.0 * DEG * a, 0, 0))
		pos(P_ARM_R, Vector3(0, 0.08 * a, 0.26 * a))
		rot(P_CHEST, Vector3(9.0 * DEG * a, 12.0 * DEG * a, 0))
		rot(P_ARM_L, Vector3(24.0 * DEG * a, 0, -34.0 * DEG * a))
		_release_at(_action_t, attack_windup)
	if _hit_t < HIT_LEN:
		var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		rot(P_HEAD, Vector3(-12.0 * DEG * k, 0, 5.0 * DEG * k))
		rot(P_ARM_L, Vector3(-18.0 * DEG * k, 0, -14.0 * DEG * k))
	if _level_t < LEVEL_LEN:
		var u := clampf(_level_t / LEVEL_LEN, 0.0, 1.0)
		rot(P_ARM_L, Vector3(-40.0 * DEG * sin(PI * u), 0, -30.0 * DEG * sin(PI * u)))
		rot(P_HEAD, Vector3(-10.0 * DEG * sin(PI * u), 0, 0))


## Fall: she staggers onto the staff (a half kneel, head down) before the kit's forward fall.
func _death_extras() -> void:
	var t := _death_t
	var g := _k3(t, 0.0, 0.22, 0.32, 0.6, 1.0, 1.0)
	HP.kneel_weights(self, 0.45 * g)
	rot(P_HEAD, Vector3(20.0 * DEG * g, 0, 0))
	rot(P_ARM_L, Vector3(-40.0 * DEG * g, 0, 20.0 * DEG * g))


func _on_revive() -> void:
	super._on_revive()
	_face_shown = &""
	_update_face()
	_fired = false
	if _chips:
		_chips.visible = true
