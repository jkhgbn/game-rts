class_name DuskboltHarrierRider
extends ShadowModel
## Duskbolt Harrier rider (stables.md 2, Shadow X: the tier-1 mounted crossbow skirmisher, hit-and-run, fragile up close).
## Seated with the kit's CharacterModel.set_seated on the Duskbolt Steed (parts/duskbolt_steed.tscn: the Dusk Steed with a
## bolt case on each flank and a rolled blanket); the scene pairing them is duskbolt_harrier.tscn (DuskboltHarrierModel,
## x0.86). Extends ShadowModel for the Shadow dissolve death and the glowing eyes.
## Look (the light Shadow rider, kept apart from the Gloam Rider's reaper cowl and lance): a lean scout in a dark leather
## jerkin, a broad team MANTLE over the shoulders with a ragged hem, a tall POINTED team hood whose peak leans back (the 40 m
## hook with the crossbow), a silver clasp; inside the hood a gaunt pale face with glowing violet eyes (FaceKit, lank
## silver strands); a bolt pouch at the right hip; in the right hand, held out at the ready, a heavy one-hand CROSSBOW
## (black stock, a wide recurved silver prod with a violet dusk-stone at its heart, a violet-glowing bolt).
## Glow: the dusk-stone in the crossbow's prod and the loaded bolt's head (own glow on the Crossbow node, flared at the reload)
## and the eyes (ShadowModel).
## Attack `bolt_shot` (0.62 s, release at attack_windup 0.12 s = the Unit's projectile frame): the crossbow comes up level,
## the shot kicks it up (the bolt leaves: the Crossbow node shows its empty mesh), it is lowered and cranked, the next
## bolt is back at RELOAD_T 0.44 s. play_charge(): the crossbow levelled at a gallop and a lean in; charge_struck(at) at
## 0.10 s (the crossbow's muzzle, world).
## Hooks (on top of the kit's, the names GloamRiderModel forwards): play_charge(), is_charging(), get_lance_tip() /
## get_weapon_tip() (the muzzle, world), lance_pitch() (deg, negative = up), couch_amount(), set_rank(rank) (no rank
## research for the X harrier: accepted, no look), authored_mesh_count(); signals charge_struck(at), lance_struck(at).
## Budget (rider, JS cap ~3000 vertices with the face): 7 draw instances at rest (Hips with the legs astride, Chest with
## the mantle, Head with the hood, Face, ArmL, ArmR, Crossbow: its loaded / empty meshes are swapped, both cached); no blob
## (the steed's shows); 0 particles, 0 lights.

signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

const SH_L := Vector3(-0.26, 1.37, 0.0)
const SH_R := Vector3(0.26, 1.37, 0.0)
const ELBOW_L := Vector3(-0.30, 1.09, -0.02)
const FIST_L := Vector3(-0.29, 1.04, 0.22)
## The crossbow arm is authored straight and hanging (shoulder to fist); the pose raises it.
const FIST_R := Vector3(0.28, 0.85, 0.02)
const HEAD_C := Vector3(0, 1.62, 0.07)
const HEAD_R := 0.125
## Crossbow (node-local at the fist, the bolt along +Z): the stock's butt, the prod, the muzzle (the bolt's tip).
const XB_BUTT := -0.30
const XB_PROD := 0.32
const XB_MUZZLE := 0.44
## Arm x (deg: negative raises it forward) and crossbow pitch (deg above level): at rest (lowered), aimed, charge.
const REST_X := -62.0
const AIM_X := -96.0
const REST_PITCH := -6.0
const AIM_PITCH := 4.0
const SHOT_LEN := 0.62
const RELEASE_T := 0.12
const RELOAD_T := 0.44
const CHARGE_LEN := 0.85
const CHARGE_HIT := 0.10

# Shot tracks [t, v, ease, ...] (the _kf format below): aim weight 0-1, recoil kick (deg), crank (deg), body.
static var S_AIM := PackedFloat32Array([0.0, 0.0, 0, 0.07, 1.0, 1, 0.26, 1.0, 0, 0.46, 0.25, 0, 0.62, 0.0, 0])
static var S_KICK := PackedFloat32Array([0.0, 0.0, 0, 0.12, 0.0, 0, 0.16, -34.0, 1, 0.32, -6.0, 0, 0.62, 0.0, 0])
static var S_CRANK := PackedFloat32Array([0.0, 0.0, 0, 0.26, 0.0, 0, 0.36, 64.0, 1, 0.44, 0.0, 2, 0.62, 0.0, 0])
static var S_TWIST := PackedFloat32Array([0.0, 0.0, 0, 0.07, -26.0, 1, 0.12, -28.0, 0, 0.18, -14.0, 1, 0.62, 0.0, 0])
static var S_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.07, 6.0, 1, 0.13, -12.0, 1, 0.30, 3.0, 0, 0.62, 0.0, 0])
static var S_RISE := PackedFloat32Array([0.0, 0.0, 0, 0.07, 0.14, 1, 0.13, 0.22, 0, 0.30, 0.06, 0, 0.62, 0.0, 0])
static var C_K := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])

static var _xb_empty: Mesh

var _parts_n: int = 0
var _xb: MeshInstance3D
var _xb_loaded: Mesh
var _shot_t: float = 99.0
var _charge_t: float = 99.0
var _charge_k: float = 0.0
var _cast_k: float = 0.0
var _flare: float = 0.0
var _pitch: float = REST_PITCH
var _xb_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _glow_w: float = -1.0


# ================================================================ public hooks

func play_charge() -> void:
	if _dead:
		return
	_charge_t = 0.0
	_flare = 1.0
	set_process(true)


func is_charging() -> bool:
	return _charge_t < CHARGE_LEN


## World position of the crossbow's muzzle (the bolt's tip): shot / impact VFX.
func get_lance_tip() -> Vector3:
	if _xb and _xb.is_inside_tree():
		return _xb.global_transform * Vector3(0, 0.03, XB_MUZZLE)
	return global_position + Vector3(0.3, 1.9, 0.6)


func get_weapon_tip() -> Variant:
	return get_lance_tip()


func lance_pitch() -> float:
	return -_pitch


func couch_amount() -> float:
	return _charge_k


func set_rank(_rank: int) -> void:
	pass


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var head: Node3D = $Root/Chest/Head
	var arm_r: Node3D = $Root/Chest/ArmR
	_sculpt($Root/Hips, "db_hips_v1", _hips_sculpt)
	_sculpt($Root/Chest, "db_chest_v1", _chest_sculpt)
	_sculpt(head, "db_head_v1", _head_sculpt)
	# Face (FaceKit): the young scout in the hood: glowing violet eyes, a sly half-smile, lank silver strands framing the
	# face from under the hood (the hood covers the ears).
	_face = FaceKit.attach(self, head, "duskbolt_harrier_rider", {
		"center": HEAD_C, "radius": HEAD_R, "head_mesh": sphere(HEAD_R, 10, 6), "head_scale": Vector3(0.94, 1.06, 0.94),
		"preset": &"hollow", "skin": ShadowFaces.SKIN, "hair": ShadowFaces.SILVER, "eyes": ShadowFaces.GLOW, "detail": &"low",
		"x": NatureFaces.lean_x(1.15, {&"neutral": {"mouth": {"kind": "smirk"}, "cut_in": 0.2}}),
		"palette": ShadowFaces.pal(ShadowFaces.SKIN), "eye": {"c": Vector2(0.046, 0.018), "tilt": 0.01},
		"hair_fn": func(acc: Dictionary) -> void:
			ShadowFaces.strands(acc, [HEAD_C + Vector3(0.095, 0.06, 0.04), HEAD_C + Vector3(-0.095, 0.06, 0.04)], 0.19, 0.03,
				ShadowFaces.SILVER, ShadowFaces.SILVER_TIP, Vector3(0.015, 0, 0.0)),
	})
	_sculpt($Root/Chest/ArmL, "db_arm_l_v1", _arm_l_sculpt)
	_sculpt(arm_r, "db_arm_r_v1", _arm_r_sculpt)
	_xb = _sculpt(arm_r, "db_xbow_loaded_v3", func(s: Dictionary) -> void: _xbow_sculpt(s, true), FIST_R, true, "Crossbow")
	_xb.set_meta(&"own_glow", true)
	_xb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_xb_loaded = _xb.mesh
	if _xb_empty == null:
		_xb_empty = _cached_sculpt("db_xbow_empty_v3", func(s: Dictionary) -> void: _xbow_sculpt(s, false))


func _sculpt(pivot: Node3D, key: String, build: Callable, at: Vector3 = Vector3.ZERO, keep: bool = false,
		nm: String = "") -> MeshInstance3D:
	_parts_n += 1
	if not keep and _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return null
	var mesh := _cached_sculpt(key, build)
	if mesh == null:
		return null
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, nm)


static func _cached_sculpt(key: String, build: Callable) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var s := MountModel.sculpt()
	build.call(s)
	return _cached(key, MountModel.sculpt_mesh(s))


static func m(name: String) -> Material:
	if name.begins_with("dusk"):
		return MountModel.material_at("res://art/units/mounts/dusk_steed/materials/" + name + ".tres")
	return palette(StringName(name))


static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg), Transform3D(_to_dir(d), a + d * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


## Keyframe track [t, v, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth, 1 out, 2 in).
static func _kf(t: float, k: PackedFloat32Array) -> float:
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


# ---------------------------------------------------------------- body

## Hips + legs astride (merged into Hips): a dark riding skirt, a belt with a silver buckle and the bolt pouch at the right
## hip, the mantle's back flap, leather trousers, silver knee cops, soft dark boots in the stirrups.
func _hips_sculpt(s: Dictionary) -> void:
	var lea := m("shadow_leather")
	var sil := m("shadow_silver")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var obs := m("shadow_obsidian")
	# G-C leftovers: a riding skirt with a ragged hem (ShadowGeo, was an 8-sided can), a rolled belt, a bevelled
	# buckle, the back flap with a tattered point, smooth legs, domed knee cops, pointed curled boots
	MountModel.sculpt_add(s, ShadowGeo.lathe([Vector3(0.18, 0.94, 0.0), Vector3(0.2, 0.84, 0.0), Vector3(0.228, 0.72, 0.0)],
		12, {"jag": 0.03, "jag_seed": 9}), Transform3D.IDENTITY, cdark)
	RiderShapes.band(s, lea, 0.186, 0.06, 0.014, 12, Transform3D(Basis.IDENTITY, Vector3(0, 0.945, 0)))
	RiderShapes.box_plate(s, sil, Vector3(0.06, 0.06, 0.024), Vector3(0, 0.945, 0.206), Vector3(0, 0, 45))
	# the bolt pouch at the right hip: a team-dark case, a silver cap, fletchings
	_put(s, cyl(0.05, 0.045, 0.22, 8), cdark, Vector3(0.24, 0.84, -0.02), Vector3(-20, 0, -12))
	_put(s, cyl(0.055, 0.055, 0.03, 8, false), sil, Vector3(0.265, 0.95, -0.06), Vector3(-20, 0, -12))
	RiderShapes.box_plate(s, m("dusk_wisp"), Vector3(0.05, 0.08, 0.01), Vector3(0.275, 1.0, -0.08), Vector3(-20, 30, -12),
		Vector3.ONE, 0.5, 0.0)
	# the back flap of the skirt over the cantle
	RiderShapes.box_plate(s, cloth, Vector3(0.29, 0.40, 0.024), Vector3(0, 0.735, -0.23), Vector3(12, 0, 0), Vector3.ONE,
		0.8, 0.22)
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.10 * sx, 0.85, 0.02)
		var knee := Vector3(0.29 * sx, 0.54, 0.20)
		var ankle := Vector3(0.33 * sx, 0.20, 0.08)
		RiderShapes.tube(s, lea, PackedVector3Array([hip, hip.lerp(knee, 0.45), knee]), PackedFloat32Array([0.08, 0.084, 0.064]), 8)
		RiderShapes.lathe(s, sil, PackedVector2Array([Vector2(0.064, 0.0), Vector2(0.06, 0.026), Vector2(0.04, 0.05),
			Vector2(0.0, 0.058)]), 8, MountModel.frame(knee + Vector3(0, 0, -0.01), Vector3(0, 0.1, 1.0), Vector3.UP), 1.0, 1.15)
		var an := ankle + Vector3(0, -0.03, 0)
		RiderShapes.tube(s, lea, PackedVector3Array([knee, knee.lerp(an, 0.3), an]), PackedFloat32Array([0.06, 0.065, 0.052]), 8)
		var fd := Vector3(0.04 * sx, 0.06, 1.0).normalized()
		var fc := ankle + Vector3(0.005 * sx, -0.045, 0.09)
		RiderShapes.boot(s, obs, fc - fd * 0.11, fc + fd * 0.17, 0.058)
		RiderShapes.lathe(s, obs, PackedVector2Array([Vector2(0.06, 0.0), Vector2(0.07, 0.05), Vector2(0.078, 0.07)]), 8,
			MountModel.frame(an - Vector3(0, 0.02, 0), knee - an, Vector3.BACK), 1.0, 1.0, false)


func _chest_sculpt(s: Dictionary) -> void:
	var lea := m("shadow_leather")
	var sil := m("shadow_silver")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var thin := Basis.from_scale(Vector3(0.9, 1.0, 0.78))
	# the lean dark leather jerkin, silver studs down the front
	var prof := PackedVector2Array([Vector2(0.17, 0.92), Vector2(0.195, 1.02), Vector2(0.225, 1.16), Vector2(0.235, 1.26),
		Vector2(0.215, 1.34), Vector2(0.12, 1.42), Vector2(0.0, 1.44)])
	RiderShapes.lathe(s, lea, prof, 12, Transform3D(thin, Vector3.ZERO))
	var studs := PackedVector3Array()
	for k: int in 3:
		studs.append(Vector3(0, 1.06 + 0.09 * float(k), 0.185 + 0.004 * float(k)))
	RiderShapes.studs(s, sil, studs, Vector3.BACK, 0.022)
	# a crossed baldric (team dark) for the bolt pouch
	RiderShapes.box_plate(s, cdark, Vector3(0.06, 0.52, 0.024), Vector3(0.0, 1.16, 0.192), Vector3(-6, 0, 32))
	# the broad team MANTLE over the shoulders, a ragged dark hem, a silver clasp at the throat
	RiderShapes.lathe(s, cloth, PackedVector2Array([Vector2(0.30, 1.27), Vector2(0.285, 1.33), Vector2(0.235, 1.395),
		Vector2(0.14, 1.45)]), 14, Transform3D(Basis.IDENTITY, Vector3(0, 0, -0.02)), 1.0, 0.9, false)
	MountModel.sculpt_fringe(s, cdark, MountModel.fringe_mesh("db_mantle_hem_v1", 0.298, 0.268, 0.31, 0.28, 0.06, -180.0,
		180.0, 10, 0.08, 0.02, 0.7), Vector3(0, 1.275, -0.02))
	MountModel.sculpt_fringe(s, cloth, MountModel.fringe_mesh("db_mantle_back_v1", 0.2, 0.12, 0.27, 0.19, 0.42, 120.0, 240.0,
		5, 0.14, 0.02, 0.7), Vector3(0, 1.30, -0.10), Basis(Vector3.RIGHT, deg_to_rad(26.0)))
	_put(s, sphere(0.04, 6, 3), sil, Vector3(0, 1.41, 0.16), Vector3.ZERO, Vector3(1.0, 1.0, 0.6))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("shadow_skin")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	_put(s, cyl(0.055, 0.064, 0.12, 10), skin, Vector3(0, 1.50, 0.03))
	_put(s, sphere(HEAD_R, 10, 6), skin, HEAD_C, Vector3.ZERO, Vector3(0.94, 1.06, 0.94))
	# the tall POINTED hood: a shell round the head open at the face, the peak rising and leaning back, a dark rim
	_put(s, sphere(0.19, 10, 5), cloth, Vector3(0, 1.66, -0.05), Vector3.ZERO, Vector3(1.0, 1.08, 1.1))
	_put(s, cyl(0.155, 0.158, 0.035, 10, false), cdark, Vector3(0, 1.64, 0.10), Vector3(78, 0, 0), Vector3(1.0, 1.0, 1.22))
	MountModel.sculpt_add(s, MountModel.tube_mesh("db_hood_peak_v1", PackedVector3Array([Vector3(0, 1.78, -0.05),
		Vector3(0, 1.88, -0.11), Vector3(0, 1.95, -0.21), Vector3(0, 1.97, -0.33)]), PackedFloat32Array([0.15, 0.09, 0.045,
		0.0]), 7), Transform3D.IDENTITY, cloth)


func _arm_l_sculpt(s: Dictionary) -> void:
	var lea := m("shadow_leather")
	var cdark := m("shadow_cloth_dark")
	var s0 := SH_L + Vector3(0, 0.02, 0)
	var w0 := FIST_L - (FIST_L - ELBOW_L).normalized() * 0.04
	RiderShapes.tube(s, cdark, PackedVector3Array([s0, s0.lerp(ELBOW_L, 0.45), ELBOW_L]), PackedFloat32Array([0.066, 0.07, 0.058]), 8)
	RiderShapes.tube(s, lea, PackedVector3Array([ELBOW_L, ELBOW_L.lerp(w0, 0.3), w0]), PackedFloat32Array([0.056, 0.06, 0.05]), 8)
	_put(s, sphere(0.056, 8, 4), lea, FIST_L)


## The crossbow arm, authored straight and hanging (the pose raises it): a team-dark sleeve, a leather bracer, a
## leather glove.
func _arm_r_sculpt(s: Dictionary) -> void:
	var lea := m("shadow_leather")
	var cdark := m("shadow_cloth_dark")
	var sil := m("shadow_silver")
	var el := SH_R.lerp(FIST_R, 0.5)
	var s0 := SH_R + Vector3(0, 0.02, 0)
	var w0 := FIST_R + Vector3(0, 0.06, 0)
	RiderShapes.tube(s, cdark, PackedVector3Array([s0, s0.lerp(el, 0.45), el]), PackedFloat32Array([0.068, 0.072, 0.058]), 8)
	RiderShapes.tube(s, lea, PackedVector3Array([el, el.lerp(w0, 0.3), w0]), PackedFloat32Array([0.058, 0.062, 0.052]), 8)
	RiderShapes.band(s, sil, 0.056, 0.05, 0.012, 8, Transform3D(Basis.IDENTITY, FIST_R + Vector3(0, 0.14, 0)))
	_put(s, sphere(0.056, 8, 4), lea, FIST_R)


## The one-hand crossbow (keep_separate "Crossbow", node-local at the fist, the bolt along +Z): a black stock with a
## silver butt cap, a recurved silver prod across the front, the string; `loaded` adds the violet-glowing bolt.
func _xbow_sculpt(s: Dictionary, loaded: bool) -> void:
	var obs := m("shadow_obsidian")
	var sil := m("shadow_silver")
	var iron := m("shadow_iron")
	# G-C leftovers: a bevelled stock (side profile tapering to the prod), a silver butt plate, a bevelled grip
	var sl: float = XB_PROD - XB_BUTT
	RiderShapes.plate(s, obs, PackedVector2Array([Vector2(-sl * 0.5, -0.05), Vector2(sl * 0.5, -0.02), Vector2(sl * 0.5, 0.035),
		Vector2(-sl * 0.5, 0.042)]), 0.07, 0.014, Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(0, 0.035,
		(XB_BUTT + XB_PROD) * 0.5)), true)
	RiderShapes.box_plate(s, sil, Vector3(0.064, 0.095, 0.04), Vector3(0, 0.025, XB_BUTT - 0.005), Vector3.ZERO, Vector3.ONE,
		1.0, 0.0, true)
	RiderShapes.box_plate(s, obs, Vector3(0.08, 0.11, 0.04), Vector3(0, -0.04, -0.02), Vector3(0, -90, 15), Vector3.ONE,
		0.8, 0.0, true)
	# the recurved prod: two limbs out and back, silver tips
	for sx: float in [-1.0, 1.0]:
		var pts := PackedVector3Array([Vector3(0, 0.05, XB_PROD), Vector3(0.20 * sx, 0.05, XB_PROD - 0.05),
			Vector3(0.34 * sx, 0.05, XB_PROD - 0.15), Vector3(0.39 * sx, 0.05, XB_PROD - 0.09)])
		MountModel.sculpt_add(s, MountModel.tube_mesh("db_prod_%s_v2" % sx, pts, PackedFloat32Array([0.034, 0.03, 0.022, 0.014]),
			4), Transform3D.IDENTITY, sil)
		MountModel.sculpt_add(s, cyl(0.005, 0.005, 0.44, 3), Transform3D(_to_dir(Vector3(0.34 * sx, 0, -0.24)),
			Vector3(0.17 * sx, 0.05, XB_PROD - 0.16)), iron)
	# the dusk-stone set in the prod's heart (a steady violet glow point, loaded or not)
	_put(s, sphere(0.068, 6, 3), m("shadow_glow_hero"), Vector3(0, 0.09, XB_PROD + 0.01), Vector3.ZERO, Vector3(1.0, 0.85, 1.0))
	if loaded:
		_put(s, box(Vector3(0.018, 0.018, 0.40)), iron, Vector3(0, 0.075, XB_PROD - 0.06))
		MountModel.sculpt_add(s, cyl(0.0, 0.03, 0.12, 4), Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
			Vector3(0, 0.075, XB_MUZZLE - 0.04)), m("shadow_glow_hero"))


# ================================================================ motion

func _after_ready() -> void:
	super._after_ready()
	_write_glow()


## `bolt_shot`: aim, the shot at attack_windup (the Unit launches its bolt; the crossbow shows its empty mesh), recoil,
## lower and crank, the next bolt at RELOAD_T. The arm is posed in _pose_seated; this runs the clock and the events.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"bolt_shot":
		return super._pose_attack(prev, t)
	_shot_t = t
	rot(P_CHEST, Vector3(_kf(t, S_LEAN) * DEG, _kf(t, S_TWIST) * DEG, 0))
	rot(P_HEAD, Vector3(0, -_kf(t, S_TWIST) * 0.6 * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(t, S_RISE), -_kf(t, S_RISE) * 0.4))   # up in the stirrups to aim (the seat keeps half)
	var rel: float = attack_windup if attack_windup > 0.0 else RELEASE_T
	if prev < rel and t >= rel:
		_on_action_event(&"release")
		lance_struck.emit(get_lance_tip())
		if _xb and _xb_empty:
			_xb.mesh = _xb_empty
	if prev < RELOAD_T and t >= RELOAD_T:
		_reload()
	if t >= SHOT_LEN:
		_shot_t = 99.0
		_reload()
	return t < SHOT_LEN


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	if ev == &"attack_end":
		_shot_t = 99.0
		_reload()


func _reload() -> void:
	if _xb and _xb_loaded and _xb.mesh != _xb_loaded and not _dead:
		_xb.mesh = _xb_loaded
		_flare = 0.6


## A salute for any cast: the crossbow raised to the sky.
func _pose_cast(_spell: StringName, t: float) -> float:
	_cast_k = _k3(t, 0.0, 0.15, 0.45, 0.7, 1.0, 1.0)
	return 0.7


func _extra_process(dt: float) -> void:
	super._extra_process(dt)
	if _action != &"attack":
		_shot_t = 99.0
	if _action != &"cast":
		_cast_k = 0.0
	if _charge_t < CHARGE_LEN:
		var prev := _charge_t
		_charge_t += dt
		_charge_k = _kf(_charge_t, C_K) if not _dead else 0.0
		if prev < CHARGE_HIT and _charge_t >= CHARGE_HIT and not _dead:
			charge_struck.emit(get_lance_tip())
		if _charge_t >= CHARGE_LEN:
			_charge_k = 0.0
	else:
		_charge_k = 0.0
	_flare = maxf(0.0, _flare - dt / 0.5)
	_write_glow()


## Riding: the kit's seat pose; the crossbow arm (lowered at rest, raised level to aim / at the charge, the recoil and the
## crank), the left hand on the reins; the crossbow aimed in the model frame.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(1.5 * sin(2.0 * TAU * gait), 4.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var aim: float = maxf(_charge_k, 0.0)
	var kick: float = 0.0
	var crank: float = 0.0
	if _shot_t < SHOT_LEN:
		aim = maxf(aim, _kf(_shot_t, S_AIM))
		kick = _kf(_shot_t, S_KICK)
		crank = _kf(_shot_t, S_CRANK)
	var ax: float = lerpf(REST_X, AIM_X, aim) + bounce * 0.5 + kick + crank - 90.0 * _cast_k
	var pitch: float = lerpf(REST_PITCH, AIM_PITCH, aim) - kick * 0.8 + 70.0 * _cast_k
	_off_rot[P_ARM_R] = sar + Vector3(ax * DEG, 0, 6.0 * DEG) * w
	if _charge_k > 0.0:
		rot(P_CHEST, Vector3(12.0 * DEG * _charge_k * w, 0, 0))
	if not _dead:
		_pitch = pitch
		_aim_xbow(pitch, -3.0)


## Turns the crossbow (child of ArmR) so the bolt points along pitch / yaw (deg) in the model frame.
func _aim_xbow(pitch_deg: float, yaw_deg: float) -> void:
	if _xb == null:
		return
	var pr := pitch_deg * DEG
	var yr := yaw_deg * DEG
	var d := Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr))
	var up := Vector3.UP - d * d.y
	if up.length_squared() < 1e-4:
		up = Vector3.BACK
	up = up.normalized()
	var want := Basis(up.cross(d), up, d)
	var rb := Basis.from_euler(_rest_rot[P_ROOT] + _off_rot[P_ROOT])
	var bc := Basis.from_euler(_rest_rot[P_CHEST] + _off_rot[P_CHEST])
	var ba := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R])
	var q := ((rb * bc * ba).inverse() * want).orthonormalized().get_rotation_quaternion()
	if not q.is_equal_approx(_xb_q_w):
		_xb_q_w = q
		_xb.quaternion = q


func _write_glow() -> void:
	if _xb == null:
		return
	var g: float = snappedf(glow_level() * (1.0 + 1.4 * _flare + 0.5 * _charge_k), 0.05)
	if g != _glow_w:
		_glow_w = g
		_xb.set_instance_shader_parameter(&"glow_boost", g)


func _on_revive() -> void:
	super._on_revive()
	_shot_t = 99.0
	_charge_t = 99.0
	_charge_k = 0.0
	_cast_k = 0.0
	_flare = 0.0
	_pitch = REST_PITCH
	_xb_q_w = Quaternion(0, 0, 0, 0)
	_glow_w = -1.0
	_reload()
	_write_glow()
