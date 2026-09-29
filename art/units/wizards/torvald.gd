extends WizardModel
## Torvald, the Ice Wizard (kingdom-ice.md 8.2; built 7.V3, polished A.3). A massive, noble frost sage:
## a deep-blue mantle (1.5 m across, silver rim) and a pale fur stole, both open at the front so a long white beard
## with a silver clasp flows over the chest; frosted-iron pauldrons with silver rims and ice-crystal horns; a tall
## jagged crown of ice (tallest spike in front) over a dark cap, cyan gem and cyan eye bar under white brows; a deep
## blue robe with a light team panel, rimed with frost at the hem above a fur hem (boots show on each stride); and a
## frosted-iron staff whose claw of ice crystals holds a floating glowing snowflake (24 bars, one MultiMesh) that
## always turns to face the camera and spins 30 deg/s. The staff is its own node pivoting at the fist (poses tilt it).
## Casts (6.5): rime_bolt (staff levelled at the target like a lance, off hand pushes), flash_freeze (staff raised
## high, then slammed down with a frost ring at its foot), rime_aegis (staff lifted overhead, off arm spread, eyes
## and crown blaze, frost rises around him). The snowflake snaps into a star on every cast.
## Idle life: slow deep breathing, frost breath puffs, and every 8-14 s (near the camera) a flourish: strokes his
## beard, taps his staff or surveys the field. Death style fall; the snowflake shatters when the glows die.
## Glow points: snowflake 3.0 (ice_glow_hero), crown gem + irises (vertex-colour glow on the FaceKit Face node, cyan). Materials: the Ice palette
## (art/units/ice/materials/) plus the hero-only art/units/wizards/torvald_*.tres (shader torvald_frost.gdshader:
## a unit_painted variant with frost dusting, rimed hem, fur streaks and a crystal look; same instance uniforms).
## Cost: 7 merged pivots + staff mesh + snowflake + 1 light; 1 looping emitter (8) + 5 pre-built one-shots (<= 16).
## Hooks: those of CharacterModel / WizardModel, unchanged.

const SPIN := 30.0 * DEG
const FROST := Color(0.75, 0.92, 1.0)
const STAFF_GRIP := Vector3(0.71, 1.02, 0.22)    # model space: the right fist, pivot of the staff
const FLAKE_UP := 1.88                           # snowflake centre above the grip (staff space)
const TV_MAT_DIR := "res://art/units/wizards/"
const IDLE_IDS: Array[StringName] = [&"idle_beard", &"idle_tap", &"idle_survey"]

static var _staff_mesh: ArrayMesh
static var _flake_mm: MultiMesh
static var _own_mats: Dictionary = {}
static var _pm_cache: Dictionary = {}

var _staff: Node3D                 # keep_separate: pivots at the fist, tilted by poses
var _flake: MultiMeshInstance3D
var _flake_node: Node3D
var _head_glow: GeometryInstance3D # the Face node (crown gem + irises glow)
var _face: FaceRig                 # painted face + moving brows + frost beard / hair locks (FaceKit)
var _expr: StringName = &"neutral"  # requested by set_expression (kept for a call before _ready)
var _burst: GPUParticles3D         # shard burst at the snowflake (casts, shatter)
var _ring: GPUParticles3D          # frost ring at the staff foot (flash freeze)
var _rise: GPUParticles3D          # frost rising around him (aegis, level-up)
var _breath: GPUParticles3D

var _spin: float = 0.0
var _star: float = 0.0             # 0 = snowflake, 1 = star (set by poses each frame)
var _star_written: float = -1.0
var _staff_pitch: float = 0.0      # wanted staff tilt (rad, + = top forward), set by poses each frame
var _staff_keep: float = 1.0       # 1 = the staff stays upright whatever the arm does, 0 = follows the arm
var _staff_written: float = 99.0
var _eye_boost: float = 1.0
var _eye_written: float = -1.0
var _ff_fired: bool = false
var _breath_t: float = 0.0
var _idle_left: float = 6.0
var _idle_i: int = 0


static func _mat(name: StringName) -> Material:
	if not _own_mats.has(name):
		_own_mats[name] = load(TV_MAT_DIR + String(name) + ".tres")
	return _own_mats[name]


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := _mat(&"torvald_cloth")
	var dark := _mat(&"torvald_cloth_dark")
	var pale := _mat(&"torvald_fur_pale")
	var beard := _mat(&"torvald_beard")
	var crystal := _mat(&"torvald_crystal")
	var metal := IceModel.ice(&"ice_metal")
	var iron := _mat(&"torvald_iron")
	var leather := IceModel.ice(&"ice_leather")
	var skin := IceModel.ice(&"ice_skin")
	var gem := IceModel.ice(&"ice_glow_hero")

	# --- Hips: heavy bell robe, dark front panel with a silver medallion, belt, thick fur hem.
	add_part(hips, cyl(0.42, 0.66, 0.94, 12), dark, Vector3(0, 0.47, 0))
	add_part(hips, box(Vector3(0.32, 0.86, 0.05)), cloth, Vector3(0, 0.48, 0.555), Vector3(-14.3, 0, 0))
	add_part(hips, cyl(0.11, 0.11, 0.04, 6), metal, Vector3(0, 0.66, 0.535), Vector3(75.7, 0, 0))
	add_part(hips, torus(0.36, 0.49), leather, Vector3(0, 0.94, 0))
	add_part(hips, box(Vector3(0.20, 0.15, 0.07)), metal, Vector3(0, 0.94, 0.475))
	add_part(hips, torus(0.57, 0.75), pale, Vector3(0, 0.095, 0))
	# --- Legs: boots hidden under the robe at rest, their toes poke out on each stride.
	add_part(leg_l, box(Vector3(0.22, 0.16, 0.34)), leather, Vector3(-0.2, 0.08, 0.30))
	add_part(leg_r, box(Vector3(0.22, 0.16, 0.34)), leather, Vector3(0.2, 0.08, 0.30))

	# --- Chest: barrel torso, the wide team mantle with a silver rim, frosted fur collar, cape.
	add_part(chest, cyl(0.46, 0.38, 0.62, 10), dark, Vector3(0, 1.25, 0))
	# the mantle and the fur stole are open at the front so the beard flows down over the chest
	add_part(chest, _cone_arc(0.34, 0.73, 0.30, 70.0, 14), dark, Vector3(0, 1.44, 0))
	add_part(chest, _tube_arc(0.735, 0.04, 70.0, 14, 6), metal, Vector3(0, 1.295, 0))
	add_part(chest, _tube_arc(0.36, 0.14, 84.0, 14, 8), pale, Vector3(0, 1.60, -0.01))
	for sx: float in [-1.0, 1.0]:   # tufted ends of the stole
		add_part(chest, sphere(0.16), pale, Vector3(0.24 * sx, 1.60, 0.26), Vector3(0, 30.0 * sx, 0), Vector3(1.0, 1.0, 1.15))
	add_part(chest, cape(0.95, 1.42), _mat(&"torvald_cape"), Vector3(0, 0.85, -0.55), Vector3(12, 0, 0))

	# --- Head: face, big nose, beard masses (cheeks + chin), the beard clasp, hair cap, crown. The painted face, the
	# moving 3D brows, the frost beard / moustache / side locks are the FaceKit Face node (face rework 2026-09-28).
	add_part(head, sphere(0.26), skin, Vector3(0, 1.85, 0))
	add_part(head, sphere(0.27), beard, Vector3(0, 1.88, -0.08), Vector3.ZERO, Vector3(1.05, 0.95, 1.0))
	add_part(head, cyl(0.0, 0.06, 0.17, 6), skin, Vector3(0, 1.81, 0.29), Vector3(105, 0, 0))
	add_part(head, sphere(0.25), beard, Vector3(0, 1.66, 0.12), Vector3.ZERO, Vector3(1.05, 0.62, 0.95))
	add_part(head, sphere(0.17), beard, Vector3(0, 1.56, 0.34), Vector3(-10, 0, 0), Vector3(1.15, 0.95, 0.75))
	_seg(head, torus(0.045, 0.11), metal, Vector3(0, 1.13, 0.52), Vector3(0, 1.21, 0.50))
	add_part(head, sphere(0.24), dark, Vector3(0, 2.06, -0.01), Vector3.ZERO, Vector3(1.0, 0.55, 1.0))
	add_part(head, cyl(0.27, 0.285, 0.11, 12), metal, Vector3(0, 2.03, 0))
	# crown: 8 jagged ice spikes, the tallest in front (angle deg, height, radius, tilt deg)
	var spikes: Array[Vector4] = [Vector4(0, 0.74, 0.09, 6), Vector4(38, 0.48, 0.075, 15), Vector4(-38, 0.48, 0.075, 15),
		Vector4(82, 0.62, 0.085, 18), Vector4(-82, 0.62, 0.085, 18), Vector4(128, 0.42, 0.07, 22),
		Vector4(-128, 0.42, 0.07, 22), Vector4(180, 0.32, 0.07, 24)]
	for s: Vector4 in spikes:
		var a := s.x * DEG
		var out := Vector3(sin(a), 0, cos(a))
		var b := Basis(Vector3.UP.cross(out).normalized(), s.w * DEG)
		add_part(head, cyl(0.0, s.z, s.y, 6), crystal, Vector3(0, 2.06, 0) + out * 0.22 + b * Vector3(0, s.y * 0.5, 0),
				b.get_euler() / DEG)
	add_part(head, cyl(0.075, 0.075, 0.05, 6), metal, Vector3(0, 2.035, 0.27), Vector3(90, 0, 0))
	_face = FaceKit.attach(self, head, "torvald", _face_style())
	_face.set_expression(_expr)
	_face.set_meta(&"own_glow", true)   # the irises blaze with the crown gem (_eye_boost), written below

	# --- Arms: wide bell sleeves, fur cuffs, big fists; silver pauldrons with ice crystal horns.
	for side: float in [-1.0, 1.0]:
		var arm: Node3D = arm_r if side > 0.0 else arm_l
		var sh := Vector3(0.56 * side, 1.47, 0)
		var wrist := Vector3(0.70 * side, 1.11, 0.18) if side > 0.0 else Vector3(-0.66, 1.06, 0.08)
		var hand := STAFF_GRIP if side > 0.0 else Vector3(-0.67, 0.97, 0.10)
		_seg(arm, cyl(0.13, 0.21, 1.0, 10), cloth, wrist, sh + (sh - wrist).normalized() * 0.05,
				Vector3(1.0, (sh - wrist).length() + 0.05, 1.0))
		_seg(arm, torus(0.12, 0.25), pale, wrist - (wrist - sh).normalized() * 0.02, wrist + (wrist - sh).normalized() * 0.02)
		add_part(arm, sphere(0.13), skin, hand)
		add_part(arm, sphere(0.2), iron, Vector3(0.60 * side, 1.56, -0.02), Vector3.ZERO, Vector3(1.0, 0.7, 1.05))
		add_part(arm, torus(0.17, 0.23), metal, Vector3(0.60 * side, 1.52, -0.02), Vector3(0, 0, -12.0 * side))
		_horn(arm, Vector3(0.62 * side, 1.66, -0.02), 0.40, 0.075, Vector3(-10, 0, -26 * side), crystal)
		_horn(arm, Vector3(0.52 * side, 1.68, -0.13), 0.28, 0.06, Vector3(-28, 0, -12 * side), crystal)

	# --- Staff (keep_separate so casts can tilt it at the fist): one pre-merged mesh + the floating snowflake.
	_staff = Node3D.new()
	_staff.name = "Staff"
	_staff.set_meta(&"keep_separate", true)
	_staff.position = STAFF_GRIP - model_origin(arm_r)
	arm_r.add_child(_staff)
	var sm := MeshInstance3D.new()
	sm.name = "StaffMesh"
	sm.mesh = _get_staff_mesh()
	sm.set_meta(&"keep_separate", true)
	_staff.add_child(sm)
	_flake_node = Node3D.new()
	_flake_node.name = "Snowflake"
	_flake_node.position = Vector3(0, FLAKE_UP, 0)
	_staff.add_child(_flake_node)
	_flake = MultiMeshInstance3D.new()
	_flake.name = "Flake"
	_flake.multimesh = _get_flake()
	_flake.material_override = gem
	_flake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flake.set_meta(&"own_glow", true)
	_flake.set_meta(&"keep_separate", true)
	_flake_node.add_child(_flake)
	_orb = _flake
	_bob = _flake_node
	_bob_rest = _flake_node.position
	_light = OmniLight3D.new()
	_light.name = "OrbLight"
	_light.light_color = Color(0.70, 0.88, 1.0)
	_light.light_energy = light_energy
	_light.light_specular = 0.2
	_light.omni_range = 4.5
	_light.shadow_enabled = false
	_light.position = _flake_node.position
	_staff.add_child(_light)
	var motes := make_motes(FROST, 8, 1.8, 0.35, 0.25, 0.06)
	motes.name = "SnowMotes"
	motes.position = _flake_node.position
	_staff.add_child(motes)
	_burst = make_motes(FROST, 16, 0.55, 0.12, 3.2, 0.11, false, true)
	_burst.name = "CastBurst"
	_burst.position = _flake_node.position
	_staff.add_child(_burst)

	# --- Fx (not animated): flash-freeze ring at the staff foot, aegis frost rising, death shards; breath at the face.
	_ring = make_motes(FROST, 16, 0.6, 0.35, 0.0, 0.14, true, true)
	_ring.process_material = _pm(&"ring")
	_ring.name = "FrostRing"
	_ring.position = Vector3(0.72, 0.08, 0.50)
	$Fx.add_child(_ring)
	_rise = make_motes(FROST, 16, 1.1, 0.9, 0.0, 0.10, true, true)
	_rise.process_material = _pm(&"rise")
	_rise.name = "FrostRise"
	_rise.position = Vector3(0, 0.15, 0)
	$Fx.add_child(_rise)
	var shards := make_motes(FROST, 14, 0.9, 0.4, 1.8, 0.09, false, true)
	shards.name = "DeathShards"
	shards.set_meta(&"death_fx", true)
	shards.position = Vector3(0, 1.0, 0.3)
	$Fx.add_child(shards)
	_breath = make_motes(Color(0.80, 0.88, 0.95), 5, 1.1, 0.04, 0.0, 0.11, false, true)
	_breath.process_material = _pm(&"breath")
	_breath.explosiveness = 0.5
	_breath.name = "Breath"
	_breath.position = Vector3(0, 1.76, 0.36) - model_origin(head)
	head.add_child(_breath)
	ensure_shadow_blob(0.62)


func _after_ready() -> void:
	_head_glow = _face   # the crown gem + the irises (FaceKit Face node, own_glow)
	_idle_left = 5.0 + 6.0 * fmod(_phase_off, 1.0)
	_breath_t = fmod(_phase_off * 1.7, 3.6)


# ------------------------------------------------------------------ face / expressions

## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout"; aliases
## angry / sad / cast / happy). Unknown ids = neutral. Safe before _ready and any number of times.
func set_expression(id: StringName) -> void:
	_expr = FaceKit.canonical(id)
	if _face:
		_face.set_expression(_expr)


func get_expression() -> StringName:
	return _expr


## Torvald's face style: kind grandfather under the frost: ice-blue irises that glow a little (his cyan eye read,
## blazing with the crown gem on casts), heavy lids, rosy apple cheeks above the beard, big white 3D brows that move
## with the expression, the mouth painted on the beard under an up-curled frost moustache (a warm closed smile at rest).
## Beard (hair plan 3): split into frost locks: 3 long spade locks through the silver clasp + 2 moustache locks + 2
## swept side locks under the crown, white on top with a blue-grey underside (separates from the white stole) and
## icy tips. All on the Face node (one vertex-coloured surface).
static func _face_style() -> Dictionary:
	if _own_mats.has(&"_face_style"):
		return _own_mats[&"_face_style"]
	var frost := Color(0.95, 0.97, 1.0)
	var under := Color(0.40, 0.50, 0.70)
	var icy := Color(0.62, 0.86, 1.0)
	var warm := Color(0.93, 0.79, 0.74)
	var brow := Color(0.34, 0.40, 0.54)
	var st := {
		"canvas": FaceKit.canvas(Vector3(0, 1.85, 0), 0.26, sphere(0.26)),
		# the mouth sits on the top-front of the chin bulge, right under the moustache (faces up toward the camera)
		"mouth_canvas": FaceKit.canvas(Vector3(0, 1.56, 0.34), 0.14, sphere(0.17), Vector3(1.15, 0.95, 0.75), Vector3.INF,
			Basis(Vector3.RIGHT, -10.0 * DEG), 0.001),
		"palette": {"skin": warm, "sclera": Color(0.95, 0.95, 0.96), "iris_in": Color(0.70, 0.95, 1.0),
			"iris_out": Color(0.03, 0.20, 0.52), "iris_glow": 0.55, "pupil": Color(0.03, 0.04, 0.10), "highlight": Color(1, 1, 1),
			"lash": Color(0.08, 0.10, 0.18), "brow": brow, "blush": Color(0.95, 0.50, 0.52), "lip_line": Color(0.24, 0.10, 0.14),
			"lip": Color(0.80, 0.56, 0.58), "mouth_in": Color(0.30, 0.08, 0.10), "teeth": Color(0.98, 0.97, 0.94), "tongue": Color(0.86, 0.42, 0.44)},
		# harsh-review fix (2026-09-28, was 62): bigger eyes with darker lash lines and irises, a warm face patch, a
		# deeper socket shadow, grey-blue brows and a shadow line under the moustache, so the eyes read off the white beard.
		"eye": {"c": Vector2(0.080, 0.024), "hw": 0.050, "top": 0.033, "bot": 0.018, "tilt": -0.004, "ir": 0.0245, "lash": 1.9, "flick": 0.0},
		"base": func(acc: Dictionary, _id: StringName) -> void:
			var cv: Dictionary = _own_mats[&"_face_style"]["canvas"]
			var sk := Color(0.86, 0.82, 0.84)
			# warm face: ruddy centre fading out to the ice-pale head at the edges
			FaceKit.fill(acc, cv, FaceKit.ellipse(Vector2(0, -0.005), Vector2(0.185, 0.125), 0.0, 24),
				FaceKit.radial(Vector2(0, -0.005), Vector2(0.185, 0.125), warm, sk, 0.55), 0.0008, 0.012)
			# a deeper cool shadow under the brow ridge around each eye (the eye whites no longer sit on white)
			for sx: float in [-1.0, 1.0]:
				var so := Vector2(0.080 * sx, 0.030)
				FaceKit.fill(acc, cv, FaceKit.ellipse(so, Vector2(0.068, 0.045), 0.0, 16),
					FaceKit.radial(so, Vector2(0.068, 0.045), Color(0.52, 0.44, 0.50), warm, 0.25), 0.0012, 0.007)
			# the shadow line where the moustache leaves the face
			FaceKit.strip(acc, cv, FaceKit.bez(Vector2(-0.20, -0.050), Vector2(0.0, -0.072), Vector2(0.20, -0.050)),
				Vector3(0.006, 0.013, 0.006), Color(0.34, 0.36, 0.48), 0.0014),
		"brow": {"none": true},
		"bold": 2.6,   # the RTS-distance face: extra-thick lash lines / pupils so the eyes still make dark pixels
		"cheek": {"c": Vector2(0.108, -0.028), "r": Vector2(0.042, 0.024)},
		"mouth": {"c": Vector2(0.0, 0.112), "hw": 0.056, "lip": 0.0045},
		"x": {&"neutral": {"blush": 1.2, "mouth": {"curve": 1.2}}, &"smile": {"blush": 1.4}, &"worried": {"blush": 0.3}},
		"extra": func(acc: Dictionary, id: StringName) -> void:
			# bushy 3D brows: a short thick lock per side, raised / tilted by the expression
			var x := FaceKit.params(_own_mats[&"_face_style"], id)
			var dy: Array = x["brow"]
			for sx: float in [-1.0, 1.0]:
				var yi := 1.934 + float(dy[0]) * 1.2
				var yo := 1.944 + float(dy[2]) * 1.2
				var ym := 1.954 + float(dy[1]) * 1.2
				var ix := 0.035 + float(x["brow_in_dx"]) * 1.5
				var b0: int = acc["v"].size()
				FaceKit.lock(acc, [Vector3(ix * sx, yi, 0.262), Vector3(0.09 * sx, ym + 0.012, 0.262), Vector3(0.15 * sx, (ym + yo) * 0.5, 0.225),
					Vector3(0.19 * sx, yo - 0.02, 0.17)], Vector3(0.15 * sx, 0.3, 1.0).normalized(), 0.068, 0.066, brow, frost, 5, 0.75, 0.0)
				FaceKit.shade_under(acc, b0, Color(0.22, 0.26, 0.38), 0.7),
		"geo": func(acc: Dictionary) -> void:
			var b0: int = acc["v"].size()
			for sx: float in [-1.0, 1.0]:
				# moustache: from under the nose, out and curling UP at the tips (the jolly read over the smile)
				FaceKit.lock(acc, [Vector3(0.015 * sx, 1.775, 0.335), Vector3(0.11 * sx, 1.755, 0.375), Vector3(0.21 * sx, 1.69, 0.33),
					Vector3(0.27 * sx, 1.775, 0.26)], Vector3(0.1 * sx, 0.3, 1.0).normalized(), 0.075, 0.062, frost, icy, 5, 0.7, 25.0 * sx)
				# swept side lock under the crown, framing the temple
				FaceKit.lock(acc, [Vector3(0.20 * sx, 2.01, 0.12), Vector3(0.29 * sx, 1.93, 0.12), Vector3(0.31 * sx, 1.80, 0.05),
					Vector3(0.28 * sx, 1.69, 0.0)], Vector3(sx, 0.1, 0.4).normalized(), 0.11, 0.05, frost, icy, 4, 0.7, 12.0 * sx)
			# the spade: 3 long locks from under the chin, through the clasp, to a point
			for k: int in 3:
				var dx := (float(k) - 1.0) * 0.085
				var w := 0.21 if k == 1 else 0.16
				FaceKit.lock(acc, [Vector3(dx, 1.62, 0.40), Vector3(dx * 1.6, 1.42, 0.54), Vector3(dx * 0.4, 1.22, 0.53),
					Vector3(dx * 0.15, 0.96, 0.55)], Vector3(0, 0.1, 1.0).normalized(), w, 0.09, frost, icy, 5, 0.7, (float(k) - 1.0) * 12.0)
			FaceKit.shade_under(acc, b0, under, 0.85)
			# the crown gem (was a torvald_gem surface on the merged head): fully glowing vertex colour, blazes with _eye_boost
			FaceKit.put_mesh(acc, sphere(0.075), Transform3D(Basis.from_scale(Vector3(1.0, 1.25, 0.8)), Vector3(0, 2.035, 0.30)),
				FaceKit.glow(Color(0.12, 0.55, 0.95), 1.0)),
	}
	_own_mats[&"_face_style"] = st
	return st


## Mesh with its +Y axis from model point a to b (top of a cylinder at b). scl scales the mesh before the rotation.
func _seg(pivot: Node3D, mesh: Mesh, mat: Material, a: Vector3, b: Vector3, scl: Vector3 = Vector3.ONE) -> void:
	var d := (b - a).normalized()
	var e := Basis(Quaternion(Vector3.UP, d)).get_euler() / DEG
	add_part(pivot, mesh, mat, (a + b) * 0.5, e, scl)


## Ice crystal horn (hexagonal cone) standing on `base`, rotated by rot_deg (x back / z outward).
func _horn(pivot: Node3D, base: Vector3, h: float, r: float, rot_deg: Vector3, mat: Material) -> void:
	var b := Basis.from_euler(rot_deg * DEG)
	add_part(pivot, cyl(0.0, r, h, 6), mat, base + b * Vector3(0, h * 0.5, 0), rot_deg)


# ------------------------------------------------------------------ shared resources (built once per game)

## The staff in grip space (origin = the fist): dark frost-iron shaft, leather grip, silver bands and head cup,
## three crystal prongs and a crystal core under the snowflake. One mesh, one surface per material.
static func _get_staff_mesh() -> ArrayMesh:
	if _staff_mesh:
		return _staff_mesh
	var am := ArrayMesh.new()
	var groups: Array = [
		[_mat(&"torvald_iron"), [[cyl(0.05, 0.055, 2.42, 8), Vector3(0, 0.24, 0), Vector3.ZERO]]],
		[IceModel.ice(&"ice_leather"), [[cyl(0.068, 0.068, 0.36, 8), Vector3(0, 0.0, 0), Vector3.ZERO],
			[cyl(0.062, 0.062, 0.14, 8), Vector3(0, -0.62, 0), Vector3.ZERO]]],
		[IceModel.ice(&"ice_metal"), [[cyl(0.078, 0.078, 0.06, 8), Vector3(0, 0.62, 0), Vector3.ZERO],
			[cyl(0.078, 0.078, 0.06, 8), Vector3(0, 1.12, 0), Vector3.ZERO],
			[cyl(0.03, 0.075, 0.10, 8), Vector3(0, -0.93, 0), Vector3.ZERO],
			[cyl(0.085, 0.085, 0.05, 8), Vector3(0, 1.40, 0), Vector3.ZERO]]],
		[_mat(&"torvald_crystal"), []],
	]
	# dark iron claw: a flared cup and three hooked tines, each capped by an ice crystal
	var iron: Array = groups[0][1]
	iron.append([cyl(0.13, 0.06, 0.18, 8), Vector3(0, 1.52, 0), Vector3.ZERO])
	var cr: Array = groups[3][1]
	for i: int in 3:
		var a := TAU * float(i) / 3.0 + PI / 6.0
		var out := Vector3(sin(a), 0, cos(a))
		var b := Basis(Vector3.UP.cross(out).normalized(), 38.0 * DEG)
		var tine_base := Vector3(0, 1.58, 0) + out * 0.10
		iron.append([cyl(0.035, 0.05, 0.22, 6), tine_base + b * Vector3(0, 0.11, 0), b.get_euler() / DEG])
		var b2 := Basis(Vector3.UP.cross(out).normalized(), 8.0 * DEG)
		var tip := tine_base + b * Vector3(0, 0.22, 0)
		cr.append([cyl(0.0, 0.07, 0.34, 6), tip + b2 * Vector3(0, 0.17, 0), b2.get_euler() / DEG])
	cr.append([cyl(0.0, 0.09, 0.16, 6), Vector3(0, 1.69, 0), Vector3.ZERO])
	cr.append([cyl(0.09, 0.0, 0.10, 6), Vector3(0, 1.56, 0), Vector3.ZERO])
	for g: Array in groups:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for p: Array in g[1]:
			var m: Mesh = p[0]
			var xf := Transform3D(Basis.from_euler((p[2] as Vector3) * DEG), p[1])
			st.append_from(m, 0, xf)
		st.set_material(g[0])
		st.commit(am)
	_staff_mesh = am
	return am


## The snowflake: 6 arms, 12 side branches, a 6-bar hexagon core (24 bars of one unit box). Lies in local XY.
static func _get_flake() -> MultiMesh:
	if _flake_mm:
		return _flake_mm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box(Vector3.ONE)
	mm.instance_count = 24
	var k: int = 0
	for i: int in 6:
		var a := TAU * float(i) / 6.0
		var r := Basis(Vector3.BACK, a)
		var up := r * Vector3.UP
		mm.set_instance_transform(k, Transform3D(r * Basis.from_scale(Vector3(0.08, 0.34, 0.05)), up * 0.17))
		k += 1
		for s: float in [-1.0, 1.0]:
			var rb := Basis(Vector3.BACK, a + s * 0.95)
			var d := rb * Vector3.UP
			mm.set_instance_transform(k, Transform3D(rb * Basis.from_scale(Vector3(0.055, 0.14, 0.04)), up * 0.21 + d * 0.065))
			k += 1
		var rt := Basis(Vector3.BACK, a + PI / 6.0 + PI * 0.5)
		var mid := Basis(Vector3.BACK, a + PI / 6.0) * Vector3.UP * 0.087
		mm.set_instance_transform(k, Transform3D(rt * Basis.from_scale(Vector3(0.05, 0.11, 0.045)), mid))
		k += 1
	_flake_mm = mm
	return mm


## Open cone (a cloak draped on the shoulders): radius r_top at +h/2, r_bot at -h/2, open over `open_deg` at the
## front (+Z), double-sided (outer + inner shell `thick` inside). Cached per parameter set.
static func _cone_arc(r_top: float, r_bot: float, h: float, open_deg: float, seg: int, thick: float = 0.03) -> ArrayMesh:
	var key := "tv_cone%s_%s_%s_%s_%d" % [r_top, r_bot, h, open_deg, seg]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var v := PackedVector3Array()
	var nr := PackedVector3Array()
	var ix := PackedInt32Array()
	var a0 := open_deg * 0.5 * DEG
	var a1 := TAU - a0
	for shell: int in 2:
		var off := 0.0 if shell == 0 else -thick
		var sgn := 1.0 if shell == 0 else -1.0
		var base := v.size()
		for i: int in seg + 1:
			var a := lerpf(a0, a1, float(i) / float(seg))
			var s := Vector3(sin(a), 0, cos(a))
			var n := (s * h + Vector3.UP * (r_bot - r_top)).normalized() * sgn
			v.append(s * (r_top + off) + Vector3.UP * h * 0.5)
			v.append(s * (r_bot + off) - Vector3.UP * h * 0.5)
			nr.append(n)
			nr.append(n)
		for i: int in seg:
			var t0 := base + i * 2
			_quad(ix, v, nr, t0, t0 + 2, t0 + 1, t0 + 3)
	_mesh_cache[key] = _arrays_mesh(v, nr, ix)
	return _mesh_cache[key]


## Open torus (a fur stole around the neck): ring radius big_r, tube radius r, open over `open_deg` at the front.
static func _tube_arc(big_r: float, r: float, open_deg: float, seg: int, ring: int = 8) -> ArrayMesh:
	var key := "tv_tube%s_%s_%s_%d_%d" % [big_r, r, open_deg, seg, ring]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var v := PackedVector3Array()
	var nr := PackedVector3Array()
	var ix := PackedInt32Array()
	var a0 := open_deg * 0.5 * DEG
	var a1 := TAU - a0
	for i: int in seg + 1:
		var a := lerpf(a0, a1, float(i) / float(seg))
		var s := Vector3(sin(a), 0, cos(a))
		for j: int in ring + 1:
			var b := TAU * float(j) / float(ring)
			var n := s * cos(b) + Vector3.UP * sin(b)
			v.append(s * big_r + n * r)
			nr.append(n)
	for i: int in seg:
		for j: int in ring:
			var p00 := i * (ring + 1) + j
			_quad(ix, v, nr, p00, p00 + ring + 1, p00 + 1, p00 + ring + 2)
	_mesh_cache[key] = _arrays_mesh(v, nr, ix)
	return _mesh_cache[key]


## Two triangles for the quad (a, b along one edge; c, d the opposite edge), wound so the face points along the
## vertex normals (Godot: clockwise = front).
static func _quad(ix: PackedInt32Array, v: PackedVector3Array, nr: PackedVector3Array, a: int, b: int, c: int, d: int) -> void:
	var n := nr[a] + nr[b] + nr[c]
	if (v[b] - v[a]).cross(v[c] - v[a]).dot(n) < 0.0:
		ix.append_array(PackedInt32Array([a, b, c, b, d, c]))
	else:
		ix.append_array(PackedInt32Array([a, c, b, b, c, d]))


static func _arrays_mesh(v: PackedVector3Array, nr: PackedVector3Array, ix: PackedInt32Array) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nr
	arr[Mesh.ARRAY_INDEX] = ix
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


## Process materials of the model's own one-shot emitters (shared).
static func _pm(kind: StringName) -> ParticleProcessMaterial:
	if _pm_cache.has(kind):
		return _pm_cache[kind]
	var pm := ParticleProcessMaterial.new()
	var cv := Curve.new()
	cv.add_point(Vector2(0, 1))
	cv.add_point(Vector2(1, 0.2))
	var ct := CurveTexture.new()
	ct.curve = cv
	pm.scale_curve = ct
	pm.gravity = Vector3.ZERO
	match kind:
		&"ring":   # flat burst racing outward along the ground
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = 0.35
			pm.emission_ring_inner_radius = 0.25
			pm.emission_ring_height = 0.05
			pm.direction = Vector3.UP
			pm.spread = 15.0
			pm.initial_velocity_min = 0.4
			pm.initial_velocity_max = 0.9
			pm.radial_velocity_min = 3.0
			pm.radial_velocity_max = 4.0
			pm.damping_min = 3.0
			pm.damping_max = 4.0
		&"rise":   # a ring of frost climbing up and closing in around him
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = 0.95
			pm.emission_ring_inner_radius = 0.8
			pm.emission_ring_height = 0.1
			pm.direction = Vector3.UP
			pm.spread = 5.0
			pm.initial_velocity_min = 1.6
			pm.initial_velocity_max = 2.2
			pm.radial_velocity_min = -0.6
			pm.radial_velocity_max = -0.4
		_:         # breath: a soft puff drifting forward and up
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 0.04
			pm.direction = Vector3(0, 0.35, 1)
			pm.spread = 18.0
			pm.initial_velocity_min = 0.3
			pm.initial_velocity_max = 0.45
			pm.damping_min = 0.2
			pm.damping_max = 0.3
			var sc := Curve.new()
			sc.add_point(Vector2(0, 0.4))
			sc.add_point(Vector2(0.5, 1.0))
			sc.add_point(Vector2(1, 0.0))
			var st := CurveTexture.new()
			st.curve = sc
			pm.scale_curve = st
	_pm_cache[kind] = pm
	return pm


# ------------------------------------------------------------------ animation

func _on_action_event(ev: StringName) -> void:
	match ev:
		&"cast_start":
			_ff_fired = false
			match _cast_id:
				&"flash_freeze":
					_burst.restart()
				&"rime_aegis":
					_burst.restart()
					_rise.restart()
				&"idle_beard", &"idle_tap", &"idle_survey":
					pass
				_:
					_burst.restart()
		&"level_up":
			_rise.restart()
		&"death_glow_off":
			_burst.restart()
			_flake_node.visible = false


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		&"flash_freeze":
			# Staff swung up high (0-0.16), slammed down in front (0.16-0.30), held, recover by 1.05.
			var up := _k3(t, 0.0, 0.16, 0.16, 0.30, 1.0, 1.0)
			var slam := _k3(t, 0.16, 0.30, 0.55, 1.05, 1.0, 1.0)
			rot(P_ARM_R, Vector3((-72.0 * up - 28.0 * slam) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.30 * up - 0.02 * slam, 0.12 * slam))
			rot(P_ARM_L, Vector3((-45.0 * up - 25.0 * slam) * DEG, 0, -50.0 * DEG * slam))
			rot(P_CHEST, Vector3((-10.0 * up + 16.0 * slam) * DEG, 0, 0))
			rot(P_HEAD, Vector3((-10.0 * up + 8.0 * slam) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0.04 * up - 0.10 * slam, 0.05 * slam))
			_staff_pitch = 12.0 * DEG * slam
			if not _ff_fired and t >= 0.27:
				_ff_fired = true
				_ring.restart()
			_star = maxf(up, slam)
			_eye_boost = 1.0 + 1.5 * _star
			_cast_boost = 1.0 + 2.5 * _star
			_cast_light = 1.0 + 1.5 * _star
			return 1.05
		&"rime_aegis":
			# Staff lifted overhead, off arm spread wide, looks up; eyes and gem blaze.
			var k := _k3(t, 0.0, 0.22, 0.62, 1.15, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-22.0 * DEG * k, 0, 8.0 * DEG * k))
			pos(P_ARM_R, Vector3(0, 0.46 * k, 0.04 * k))
			rot(P_ARM_L, Vector3(-40.0 * DEG * k, 0, -75.0 * DEG * k))
			rot(P_HEAD, Vector3(-16.0 * DEG * k, 0, 0))
			rot(P_CHEST, Vector3(-8.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, 0.05 * k, 0))
			_bob_extra = Vector3(0, 0.18 * k, 0)
			_star = k
			_eye_boost = 1.0 + 2.0 * k
			_cast_boost = 1.0 + 2.0 * k
			_cast_light = 1.0 + 1.3 * k
			return 1.15
		&"idle_beard":
			if _speed >= 0.3:
				return 0.0
			var k := _k3(t, 0.0, 0.45, 1.35, 1.9, 1.0, 1.0)
			var stroke := sin(clampf((t - 0.45) / 0.9, 0.0, 1.0) * TAU) * k
			rot(P_ARM_L, Vector3(-68.0 * DEG * k, 0, 46.0 * DEG * k))
			pos(P_ARM_L, Vector3(0, -0.06 * absf(stroke), 0.02 * stroke))
			rot(P_HEAD, Vector3(7.0 * DEG * k, -10.0 * DEG * k, 0))
			return 1.9
		&"idle_tap":
			if _speed >= 0.3:
				return 0.0
			var lift := _k3(t, 0.0, 0.35, 0.35, 0.48, 1.0, 1.0)
			var tap := _k3(t, 0.35, 0.48, 0.6, 1.2, 1.0, 1.0)
			pos(P_ARM_R, Vector3(0, 0.14 * lift - 0.02 * tap, 0.04 * lift))
			rot(P_CHEST, Vector3(0, -6.0 * DEG * lift, 0))
			rot(P_HEAD, Vector3(6.0 * DEG * tap, 0, 0))
			_star = 0.5 * tap
			_cast_boost = 1.0 + 1.0 * tap
			return 1.2
		&"idle_survey":
			if _speed >= 0.3:
				return 0.0
			var look := sin(clampf(t / 2.4, 0.0, 1.0) * TAU)
			var k := _k3(t, 0.0, 0.4, 2.0, 2.4, 1.0, 1.0)
			rot(P_HEAD, Vector3(-4.0 * DEG * k, 28.0 * DEG * look, 0))
			rot(P_CHEST, Vector3(-3.0 * DEG * k, 8.0 * DEG * look, 0))
			return 2.4
		_:  # rime_bolt (and unknown ids): the staff is levelled at the target like a lance, the off hand pushes.
			var k := _k3(t, 0.0, 0.10, 0.32, 0.85, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-55.0 * DEG * k, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.08 * k, 0.16 * k))
			rot(P_ARM_L, Vector3(-78.0 * DEG * k, 0, 12.0 * DEG * k))
			rot(P_CHEST, Vector3(8.0 * DEG * k, -12.0 * DEG * k, 0))
			rot(P_HEAD, Vector3(4.0 * DEG * k, 8.0 * DEG * k, 0))
			pos(P_ROOT, Vector3(0, 0, 0.07 * k))
			_staff_pitch = 48.0 * DEG * k
			_star = k
			_eye_boost = 1.0 + 1.2 * k
			_cast_boost = 1.0 + 2.0 * k
			_cast_light = 1.0 + 1.5 * k
			return 0.85


func _wizard_process(dt: float) -> void:
	if _flake == null:
		return
	# Extra body motion layered on the kit's poses (only in animated frames: rot / pos need _apply).
	if _walk_w > 0.0 and not _dead:
		var s := sin(TAU * _walk_p) * _walk_w
		rot(P_HEAD, Vector3(0, 0, -3.0 * DEG * s))
		rot(P_HIPS, Vector3(0, 0, 2.5 * DEG * s))
		rot(P_CHEST, Vector3(0, -4.0 * DEG * s, 0))
		_staff_pitch += 7.0 * DEG * s   # walking-stick rhythm
	if _action == &"attack":
		var k := _k3(_action_t, 0.0, attack_windup, attack_windup, 0.45, 1.0, 1.0)
		# Pushed for the 40 m read (Art Lab A3): the staff levels further, the off hand thrusts, the chest leans in.
		rot(P_ARM_L, Vector3(-58.0 * DEG * k, 0, -10.0 * DEG * k))
		rot(P_CHEST, Vector3(6.0 * DEG * k, -10.0 * DEG * k, 0))
		_staff_pitch += 55.0 * DEG * k
		_star = maxf(_star, 0.6 * k)
		_eye_boost = maxf(_eye_boost, 1.0 + 0.8 * k)
	if _hit_t < HIT_LEN:
		var hk := clampf(1.0 - _hit_t / HIT_LEN, 0.0, 1.0)
		_staff_pitch -= 8.0 * DEG * hk
		_bob_extra += Vector3(0, -0.05 * hk, -0.04 * hk)
	if _level_t < LEVEL_LEN:
		_star = maxf(_star, 1.0 - _level_t / LEVEL_LEN)
		_eye_boost = maxf(_eye_boost, 2.5)
	if _dead:
		_staff_keep = 0.0
		_star = 0.0
		_eye_boost = 1.0
	# Staff tilt at the fist: cancels the arm / chest pitch (upright staff) plus the wanted tilt.
	var st := _staff_pitch - (_off_rot[P_ARM_R].x + _off_rot[P_CHEST].x) * _staff_keep
	if _dead:
		st = 0.0
	if absf(st - _staff_written) > 0.002:
		_staff_written = st
		_staff.rotation.x = st
	# Snowflake: faces the camera, spins (faster while casting), stretches into a star.
	var s := _star
	_spin = fmod(_spin + dt * (SPIN + 540.0 * DEG * s), TAU)
	_flake.rotation.z = _spin
	if absf(s - _star_written) > 0.01:
		_star_written = s
		var sc := 1.0 + 0.55 * s
		_flake.scale = Vector3(sc, sc, 1.0)
	if _flake_node.visible and _tier < 2:
		var cam := get_viewport().get_camera_3d()
		if cam:
			var to := cam.global_position - _flake_node.global_position
			if to.length_squared() > 0.01:
				_flake_node.global_basis = Basis.looking_at(-to, Vector3.UP)
	# Eyes + crown gem (the merged Head glows) blaze on casts / level-up.
	if _head_glow:
		var eg := glow_level() * _eye_boost
		if eg != _eye_written:
			_eye_written = eg
			_head_glow.set_instance_shader_parameter(&"glow_boost", eg)
	if _face:
		_face.auto(self)
	# Frost breath puff and the idle flourishes (near the camera only).
	if not _dead and _tier == 0:
		_breath_t += dt
		if _breath_t >= 3.6:
			_breath_t = 0.0
			_breath.restart()
		if _action == &"" and _speed < 0.3 and _hit_t >= HIT_LEN:
			_idle_left -= dt
			if _idle_left <= 0.0:
				_idle_left = 8.0 + 6.0 * fmod(_phase_off * 7.3 + float(_idle_i) * 0.37, 1.0)
				play_cast(IDLE_IDS[_idle_i % IDLE_IDS.size()])
				_idle_i += 1
		else:
			_idle_left = maxf(_idle_left, 3.0)
	_star = 0.0
	_staff_pitch = 0.0
	_staff_keep = 1.0
	_eye_boost = 1.0


func _on_revive() -> void:
	super._on_revive()
	_star_written = -1.0
	_staff_written = 99.0
	_eye_written = -1.0
	_flake_node.visible = true
	if _face:
		_face.reset()
