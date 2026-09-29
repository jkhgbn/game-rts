extends WizardModel
## Malrik, the Hollow Bishop (art-units.md 3.2, polish task A.2). A gaunt shadow priest that hovers a hand above
## the ground: a deep hood with a void face and two slanted glowing eyes, a silver circlet with two big curved bone
## horns (the "horned crown"), a high fan collar, iron pauldrons with bone spikes, a purple mantle and cape, a
## narrow robe with a torn hem, and a staff whose silver claw holds a floating obsidian shard with a glowing core
## and a halo ring. He stands in a pool of shadow with a thin purple mist.
## Casts (6.5): shadow_lance (the staff swings down into a lance, the shard shoots forward), soul_siphon (arms spread,
## he rises, then pulls the souls into his chest), umbral_shroud (hunches, sinks into his shadow, cape billows).
## Death: sink, arms clawing upward, eyes flare and die, the shard rises and shatters.
## Extra nodes (all keep_separate, merged here once per type): Staff (child of ArmR, own pivot at the hand),
## Shard (child of Staff), Face (FaceKit FaceRig: face + eyes + strands + crown gem, child of Head; was Glints),
## CapePivot (child of Chest, top edge hinge). set_expression(id) / get_expression() with FaceKit.EXPRESSIONS.
## Palette materials only (kit/materials). Glow points: shard core + halo, eyes + crown gem, cape glyph (faint).

const SHADOW_GLOW := Color(0.70, 0.30, 1.00)
const H := 0.08                         # hover height of the whole body (m)
const HAND_R := Vector3(0.48, H + 1.04, 0.20)
const HAND_L := Vector3(-0.54, H + 1.06, 0.12)
const CAPE_TOP := Vector3(0.0, H + 1.58, -0.05)   # hinge on the body axis; the cloak wraps around it
const CAPE_REST := 5.0 * PI / 180.0
const SHARD_Y := 1.80                   # shard centre above the hand, along the staff
const HUNCH := 4.0 * PI / 180.0         # idle forward loom
const EYE_BASE := 1.25                    # eyes + gem glow_boost at rest

static var _mcache: Dictionary = {}     # "staff" / "shard" -> ArrayMesh, "mist_pm" / "mist_draw", "face_style"

var _staff: Node3D
var _shard: Node3D
var _glints: GeometryInstance3D
var _cape_pivot: Node3D
var _burst: GPUParticles3D
var _staff_rest: Vector3
var _spin: float = 0.0
var _spin_speed: float = 40.0 * DEG
# per-frame offsets written by the pose functions (full path only), applied + reset in _wizard_process
var _staff_off: Vector3 = Vector3.ZERO
var _staff_push: Vector3 = Vector3.ZERO
var _cape_off: float = 0.0
var _eye_boost: float = EYE_BASE
var _staff_rot_w: Vector3 = Vector3(99, 0, 0)
var _staff_pos_w: Vector3 = Vector3(99, 0, 0)
var _cape_w: float = 99.0
var _glint_w: float = -1.0
var _shattered: bool = false
var _face: FaceRig                 # face emerging from the void + 3 hair strands + crown gem (glow driven here)
var _expr: StringName = &"neutral"  # requested by set_expression (kept for a call before _ready)


# ================================================================ build

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := palette(&"shadow_cloth")
	var dark := palette(&"shadow_cloth_dark")
	var silver := palette(&"shadow_silver")
	var skin := palette(&"shadow_skin")
	var iron := palette(&"shadow_iron")
	var bone := palette(&"shadow_bone")
	var obs := palette(&"shadow_obsidian")

	# --- Hips: narrow bell robe, dark hem band, 10 torn rags hanging below it, front stole, silver belt.
	add_part(hips, cyl(0.23, 0.46, 0.96, 8), dark, Vector3(0, H + 0.52, 0), Vector3(0, 22.5, 0))
	add_part(hips, cyl(0.46, 0.49, 0.13, 8), cloth, Vector3(0, H + 0.10, 0), Vector3(0, 22.5, 0))
	for i: int in 10:
		var a := TAU * (float(i) + 0.5) / 10.0
		var out := Vector3(sin(a), 0, cos(a))
		var ln: float = 0.26 if i % 2 == 0 else 0.17
		var d := (Vector3.UP * cos(14.0 * DEG) - out * sin(14.0 * DEG))   # base -> up/in, point -> down/out
		add_part(hips, cyl(0.10, 0.0, ln, 4), dark, out * 0.42 + Vector3(0, H + 0.14 - ln * 0.45, 0), _dir_rot(d))   # tips stay above ground with the hover bob (lab R9)
	add_part(hips, box(Vector3(0.22, 0.94, 0.06)), cloth, Vector3(0, H + 0.53, 0.35), Vector3(-13.5, 0, 0))
	add_part(hips, box(Vector3(0.14, 0.14, 0.07)), silver, Vector3(0, H + 0.20, 0.45), Vector3(-13.5, 0, 45))
	add_part(hips, torus(0.20, 0.28, 10), silver, Vector3(0, H + 1.00, 0))
	add_part(hips, box(Vector3(0.14, 0.14, 0.07)), silver, Vector3(0, H + 1.00, 0.26), Vector3(0, 0, 45))

	# --- Chest: dark torso, purple mantle with a silver rim, iron pauldrons with bone spikes, fan collar, cape.
	add_part(chest, cyl(0.30, 0.22, 0.58), dark, Vector3(0, H + 1.27, 0))
	# short shoulder cape: a 6-sided cone whose lower edge breaks into 8 ragged points
	add_part(chest, cyl(0.24, 0.47, 0.40, 6), cloth, Vector3(0, H + 1.42, -0.03), Vector3(0, 30, 0))
	for i: int in 8:
		var a := TAU * float(i) / 8.0
		var out := Vector3(sin(a), 0, cos(a))
		if out.z > 0.8:
			continue   # leave the chest front open
		var ln: float = 0.24 if i % 2 == 0 else 0.16
		var d := Vector3.UP * cos(28.0 * DEG) - out * sin(28.0 * DEG)
		add_part(chest, cyl(0.12, 0.0, ln, 4), cloth, out * 0.47 + Vector3(0, H + 1.24 - ln * 0.4, -0.03), _dir_rot(d))
	add_part(chest, torus(0.22, 0.31, 10), silver, Vector3(0, H + 1.61, -0.02))
	for sx: float in [-1.0, 1.0]:
		add_part(chest, sphere(0.17), iron, Vector3(0.42 * sx, H + 1.56, -0.02), Vector3.ZERO, Vector3(1.3, 0.62, 1.2))
		add_part(chest, torus(0.17, 0.22, 10), silver, Vector3(0.42 * sx, H + 1.53, -0.02), Vector3(0, 0, -12.0 * sx), Vector3(1.2, 1.0, 1.1))
		_spike(chest, Vector3(0.46 * sx, H + 1.64, -0.05), Vector3(0.55 * sx, 1.0, -0.25), 0.07, 0.36, bone)
		_spike(chest, Vector3(0.54 * sx, H + 1.58, 0.0), Vector3(0.95 * sx, 0.45, 0.05), 0.055, 0.22, bone)
	for a_deg: float in [128.0, 154.0, 180.0, 206.0, 232.0]:
		var a := a_deg * DEG
		var out := Vector3(sin(a), 0, cos(a))
		var ln: float = 0.52 if a_deg == 180.0 else 0.44
		var d := Vector3.UP * cos(24.0 * DEG) + out * sin(24.0 * DEG)
		add_part(chest, cyl(0.0, 0.09, ln, 4), dark, Vector3(0, H + 1.60, -0.02) + out * 0.22 + d * ln * 0.5, _dir_rot(d))
	_cape_pivot = Node3D.new()
	_cape_pivot.name = "CapePivot"
	_cape_pivot.set_meta(&"keep_separate", true)
	_cape_pivot.position = CAPE_TOP - model_origin(chest)
	_cape_pivot.rotation.x = CAPE_REST
	chest.add_child(_cape_pivot)
	var cape_mi := MeshInstance3D.new()
	cape_mi.name = "Cape"
	cape_mi.mesh = _cape_mesh()
	cape_mi.material_override = palette(&"shadow_cape")
	cape_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cape_pivot.add_child(cape_mi)

	# --- Head: deep hood, void face framed by a purple hood lip, silver circlet with 3 spikes, 2 curved horns.
	add_part(head, sphere(0.28), dark, Vector3(0, H + 1.86, -0.07), Vector3.ZERO, Vector3(1.0, 1.05, 1.1))
	add_part(head, sphere(0.20), palette(&"unit_eye_dark"), Vector3(0, H + 1.85, 0.085), Vector3.ZERO, Vector3(1.0, 1.1, 0.8))
	# hood lip: a thin oval ring facing forward and 25 deg up (toward the high camera), framing the void face
	add_part(head, torus(0.18, 0.26, 12), cloth, Vector3(0, H + 1.87, 0.19), Vector3(65, 0, 0), Vector3(1.0, 1.0, 1.15))
	# circlet on the hood, 3 front spikes (the centre one tall)
	add_part(head, torus(0.21, 0.29, 12), silver, Vector3(0, H + 2.03, -0.06), Vector3(12, 0, 0))
	for k: int in 3:
		var a := (float(k) - 1.0) * 38.0 * DEG
		var out := Vector3(sin(a), 0, cos(a))
		var ln: float = 0.30 if k == 1 else 0.18
		var d := Vector3.UP * cos(14.0 * DEG) + out * sin(14.0 * DEG)
		add_part(head, cyl(0.0, 0.065, ln, 4), silver, Vector3(0, H + 2.06, -0.03) + out * 0.24 + d * ln * 0.5, _dir_rot(d))
	for sx: float in [-1.0, 1.0]:
		_horn(head, sx, bone, obs, iron)
	# Face (face rework 2026-09-28): a gaunt face emerging from the hood's void, glowing slit-pupil eyes, a sly smile,
	# 3 ink-violet strands escaping the hood; the crown gem rides on the same node (it was the old Glints node).
	_face = FaceKit.attach(self, head, "malrik", _face_style())
	_face.set_expression(_expr)
	_face.set_meta(&"own_glow", true)
	_glints = _face

	# --- Arms: long sleeves with bell cuffs; left hand is a clawed skeletal hand, right hand holds the staff.
	_arm(arm_l, Vector3(-0.40, H + 1.53, 0), HAND_L, cloth, skin)
	_arm(arm_r, Vector3(0.40, H + 1.53, 0), HAND_R, cloth, skin)
	for k: int in 3:
		var fx := (float(k) - 1.0) * 0.06
		var d := Vector3(fx * 1.5, -1.0, 0.55)
		add_part(arm_l, cyl(0.0, 0.035, 0.18, 4), skin, HAND_L + Vector3(fx, -0.08, 0.05) + d.normalized() * 0.07, _dir_rot(d))

	# --- Staff (own pivot at the hand, merged once): iron shaft, silver collar and butt spike, 3 curled claw prongs.
	_staff = Node3D.new()
	_staff.name = "Staff"
	_staff.set_meta(&"keep_separate", true)
	_staff.position = HAND_R - model_origin(arm_r)
	_staff_rest = _staff.position
	arm_r.add_child(_staff)
	var smi := _keep_mesh(_staff, "StaffMesh", _staff_mesh(), null)
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# Floating shard (obsidian bi-pyramid + glowing core poking through the facets + a tilted halo ring).
	_shard = Node3D.new()
	_shard.name = "Shard"
	_shard.set_meta(&"keep_separate", true)
	_shard.position = Vector3(0, SHARD_Y, 0)
	_staff.add_child(_shard)
	var core := _keep_mesh(_shard, "ShardMesh", _shard_mesh(), null)
	core.set_meta(&"own_glow", true)
	_orb = core
	_bob = _shard
	_bob_rest = _shard.position
	_light = OmniLight3D.new()
	_light.name = "ShardLight"
	_light.light_color = Color(0.60, 0.30, 1.00)
	_light.light_energy = light_energy
	_light.omni_range = 4.5
	_light.shadow_enabled = false
	_light.position = Vector3(0, SHARD_Y, 0.05)
	_staff.add_child(_light)
	_burst = make_motes(SHADOW_GLOW, 12, 0.7, 0.12, 2.2, 0.09, false, true)
	_burst.name = "ShardBurst"
	_burst.position = Vector3(0, SHARD_Y, 0)
	_staff.add_child(_burst)

	# --- Fx: void motes, shadow mist, death motes; the pool of shadow under him.
	# 2 motes (was 8): with the 6 mist puffs the looping total stays at the wizard's 8 (Art Lab B6p).
	var motes := make_motes(SHADOW_GLOW, 2, 2.0, 0.5, 0.5, 0.05, true)
	motes.name = "VoidMotes"
	motes.position = Vector3(0, 0.2, 0)
	$Fx.add_child(motes)
	$Fx.add_child(_make_mist())
	var death := make_motes(SHADOW_GLOW, 16, 1.2, 0.5, 1.2, 0.07, true, true)
	death.name = "DeathMotes"
	death.set_meta(&"death_fx", true)
	death.position = Vector3(0, 0.3, 0)
	$Fx.add_child(death)
	ensure_shadow_blob(0.62, Color(0.10, 0.03, 0.18, 0.62))


## A cone spike from `base` along `dir` (base radius r, length ln).
func _spike(pivot: Node3D, base: Vector3, dir: Vector3, r: float, ln: float, mat: Material) -> void:
	var d := dir.normalized()
	add_part(pivot, cyl(0.0, r, ln, 4), mat, base + d * ln * 0.5, _dir_rot(d))


## One curved horn (4 tapered segments + joint spheres), rooted on the circlet side; sx = +1 / -1.
func _horn(head: Node3D, sx: float, mat: Material, tip_mat: Material, root_mat: Material) -> void:
	var pts: Array[Vector3] = [Vector3(0.23, 2.05, -0.06), Vector3(0.38, 2.13, -0.10), Vector3(0.50, 2.28, -0.13),
		Vector3(0.55, 2.47, -0.12), Vector3(0.50, 2.66, -0.05)]
	var rad: Array[float] = [0.10, 0.085, 0.068, 0.048, 0.0]
	add_part(head, sphere(0.10, 8, 4), root_mat, Vector3(pts[0].x * sx, H + pts[0].y, pts[0].z))
	for i: int in 4:
		var a := Vector3(pts[i].x * sx, H + pts[i].y, pts[i].z)
		var b := Vector3(pts[i + 1].x * sx, H + pts[i + 1].y, pts[i + 1].z)
		var m: Material = tip_mat if i == 3 else mat
		add_part(head, cyl(rad[i + 1], rad[i], a.distance_to(b), 6), m, (a + b) * 0.5, _dir_rot(b - a))
		if i > 0:
			add_part(head, sphere(rad[i], 6, 3), mat, a)


## Sleeve capsule + bell cuff (wide mouth at the hand) + hand.
func _arm(pivot: Node3D, shoulder: Vector3, hand: Vector3, sleeve: Material, skin: Material) -> void:
	add_arm(pivot, shoulder, hand, 0.09, 0.10, sleeve, skin)
	var u := (shoulder - hand).normalized()
	add_part(pivot, cyl(0.08, 0.17, 0.28, 8), sleeve, hand + u * 0.16, _dir_rot(u))


## Euler degrees that turn +Y toward d.
static func _dir_rot(d: Vector3) -> Vector3:
	return Basis(Quaternion(Vector3.UP, d.normalized())).get_euler() * (180.0 / PI)


## A keep_separate MeshInstance3D with a mesh merged by this script (shared by every Malrik).
func _keep_mesh(parent: Node3D, nm: String, mesh: Mesh, _pivot_for_origin: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.set_meta(&"keep_separate", true)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _tmp(mesh: Mesh, mat: Material, p: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = p
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	return mi


static func _merge_tmp(key: String, parts: Array[MeshInstance3D]) -> Mesh:
	var xf: Array[Transform3D] = []
	for p: MeshInstance3D in parts:
		xf.append(p.transform)
	var entry := _build_merged(parts, xf)
	for p: MeshInstance3D in parts:
		p.free()
	_mcache[key] = entry["mesh"]
	return entry["mesh"]


func _staff_mesh() -> Mesh:
	if _mcache.has("staff"):
		return _mcache["staff"]
	var iron := palette(&"shadow_iron")
	var silver := palette(&"shadow_silver")
	var parts: Array[MeshInstance3D] = [
		_tmp(cyl(0.045, 0.05, 2.3), iron, Vector3(0, 0.13, 0)),
		_tmp(cyl(0.075, 0.06, 0.12), silver, Vector3(0, 1.22, 0)),
		_tmp(cyl(0.06, 0.06, 0.10), silver, Vector3(0, -0.45, 0)),
		_tmp(cyl(0.05, 0.0, 0.16), silver, Vector3(0, -1.10, 0)),
	]
	for i: int in 3:
		var a := TAU * float(i) / 3.0
		var out := Vector3(sin(a), 0, cos(a))
		var b0 := out * 0.05 + Vector3(0, 1.26, 0)
		var b1 := out * 0.17 + Vector3(0, 1.48, 0)
		var b2 := out * 0.09 + Vector3(0, 1.70, 0)
		parts.append(_tmp(cyl(0.03, 0.045, b0.distance_to(b1), 4), silver, (b0 + b1) * 0.5, _dir_rot(b1 - b0)))
		parts.append(_tmp(cyl(0.0, 0.03, b1.distance_to(b2), 4), silver, (b1 + b2) * 0.5, _dir_rot(b2 - b1)))
	return _merge_tmp("staff", parts)


func _shard_mesh() -> Mesh:
	if _mcache.has("shard"):
		return _mcache["shard"]
	var obs := palette(&"shadow_obsidian")
	var parts: Array[MeshInstance3D] = [
		_tmp(cyl(0.0, 0.15, 0.36, 4), obs, Vector3(0, 0.18, 0)),
		_tmp(cyl(0.15, 0.0, 0.20, 4), obs, Vector3(0, -0.10, 0)),
		_tmp(sphere(0.118, 8, 4), palette(&"shadow_glow_hero"), Vector3.ZERO),
		_tmp(torus(0.22, 0.26), palette(&"shadow_glow_mid"), Vector3(0, 0.02, 0), Vector3(68, 0, 0)),
	]
	return _merge_tmp("shard", parts)


## Curved cloak (banner shader: UV.y 0 at the fixed top edge): a 130 deg arc behind the body that flares from
## r 0.31 at the shoulders to r 0.56 at the hem, with a ragged lower edge. Hinge (origin) on the body axis.
func _cape_mesh() -> Mesh:
	if _mcache.has("cape"):
		return _mcache["cape"]
	const COLS := 10
	const ROWS := 8
	const HALF := 65.0 * PI / 180.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j: int in ROWS + 1:
		var v := float(j) / ROWS
		for i: int in COLS + 1:
			var u := float(i) / COLS
			var a := PI + (u * 2.0 - 1.0) * HALF
			var r := lerpf(0.31, 0.56, v)
			var ln := 1.48 - (0.14 if (i % 2 == 1 and j == ROWS) else 0.0)
			var p := Vector3(sin(a) * r, -ln * v, cos(a) * r)
			var n := Vector3(sin(a), 0.25 / 1.48, cos(a)).normalized()
			st.set_normal(n)
			st.set_uv(Vector2(u, v))
			st.add_vertex(p)
	for j: int in ROWS:
		for i: int in COLS:
			var k := j * (COLS + 1) + i
			st.add_index(k)
			st.add_index(k + 1)
			st.add_index(k + COLS + 1)
			st.add_index(k + 1)
			st.add_index(k + COLS + 2)
			st.add_index(k + COLS + 1)
	var m := st.commit()
	_mcache["cape"] = m
	return m

# ================================================================ face / expressions

## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout"; aliases
## angry / sad / cast / happy). Unknown ids = neutral. Safe before _ready and any number of times.
func set_expression(id: StringName) -> void:
	_expr = FaceKit.canonical(id)
	if _face:
		_face.set_expression(_expr)


func get_expression() -> StringName:
	return _expr


## Malrik's face style: a gaunt grey-lilac face that fades into the hood's void at its edges (vertex-colour gradient),
## sunken sockets and cheeks, pale lilac eye whites with GLOWING violet irises and slit pupils (his RTS read: two
## violet points under the horns), sharp slanted brows, thin lips in a sly closed smile at rest; the shout / smile
## mouths glow violet inside. Hair: 3 ink-violet strands with pale lilac tips escaping the hood lip over the collar.
static func _face_style() -> Dictionary:
	if _mcache.has("face_style"):
		return _mcache["face_style"]
	var c := Vector3(0, H + 1.85, 0.085)
	var skin := Color(0.66, 0.62, 0.74)
	var void_c := Color(0.10, 0.08, 0.11)
	var ink := Color(0.24, 0.13, 0.34)
	var lilac := Color(0.86, 0.74, 1.0)
	var st := {
		"canvas": FaceKit.canvas(c, 0.19, sphere(0.20), Vector3(1.0, 1.1, 0.8), Vector3.INF, Basis.IDENTITY, 0.004),
		"palette": {"skin": skin, "sclera": FaceKit.glow(Color(0.84, 0.72, 0.98), 0.3), "iris_in": Color(1.0, 0.80, 1.0), "iris_out": Color(0.62, 0.22, 1.0),
			"iris_glow": 1.0, "pupil": Color(0.12, 0.02, 0.18), "highlight": Color(1.0, 0.95, 1.0), "lash": Color(0.10, 0.05, 0.14),
			"brow": Color(0.22, 0.13, 0.30), "blush": skin, "lip_line": Color(0.20, 0.08, 0.24), "lip": Color(0.52, 0.42, 0.62),
			"mouth_in": Color(0.40, 0.10, 0.62), "mouth_glow": 0.9, "teeth": Color(0.90, 0.88, 0.95), "tongue": Color(0.58, 0.26, 0.60)},
		"eye": {"c": Vector2(0.056, 0.020), "hw": 0.031, "top": 0.019, "bot": 0.011, "tilt": 0.016, "ir": 0.0150, "pupil": 0.62,
			"pupil_w": 0.34, "lash": 1.1, "flick": 0.009},
		"brow": {"inner": Vector2(0.020, 0.047), "mid": Vector2(0.058, 0.058), "outer": Vector2(0.096, 0.070), "w": Vector3(0.0058, 0.0048, 0.0018)},
		"cheek": {"c": Vector2(0.075, -0.030), "r": Vector2(0.02, 0.012)},
		"mouth": {"c": Vector2(0.0, -0.074), "hw": 0.036, "lip": 0.0026},
		"x": {&"neutral": {"blush": 0.0, "mouth": {"curve": 1.35}}, &"smile": {"blush": 0.0}, &"fierce": {"blush": 0.0},
			&"worried": {"blush": 0.0}, &"shout": {"blush": 0.0}},
		"base": func(acc: Dictionary, _id: StringName) -> void:
			var cv: Dictionary = _mcache["face_style"]["canvas"]
			var fc := Vector2(0.0, -0.008)
			var fr := Vector2(0.112, 0.150)
			FaceKit.fill(acc, cv, FaceKit.ellipse(fc, fr, 0.0, 24), FaceKit.radial(fc, fr, skin, void_c, 0.5), 0.0, 0.007)
			for sx: float in [-1.0, 1.0]:
				# sunken sockets (a soft shadow around the eyes) and a gaunt shadow line under each cheekbone
				var so := Vector2(0.056 * sx, 0.024)
				FaceKit.fill(acc, cv, FaceKit.ellipse(so, Vector2(0.046, 0.031), 0.0, 16), FaceKit.radial(so, Vector2(0.046, 0.031), skin.darkened(0.42), skin, 0.25), 0.0006, 0.006)
				FaceKit.strip(acc, cv, FaceKit.mirror(FaceKit.bez(Vector2(0.050, -0.018), Vector2(0.070, -0.034), Vector2(0.066, -0.062)), sx),
					Vector3(0.002, 0.0055, 0.001), skin.darkened(0.28), 0.0008, 0.006),
		"geo": func(acc: Dictionary) -> void:
			for sx: float in [-1.0, 1.0]:
				FaceKit.lock(acc, [Vector3(0.15 * sx, H + 1.86, 0.16), Vector3(0.22 * sx, H + 1.74, 0.24), Vector3(0.18 * sx, H + 1.64, 0.32),
					Vector3(0.22 * sx, H + 1.57, 0.36)], Vector3(0.4 * sx, 0.2, 0.9).normalized(), 0.075, 0.03, ink, lilac, 5, 0.55, -20.0 * sx)
			FaceKit.lock(acc, [Vector3(0.09, H + 1.90, 0.20), Vector3(0.15, H + 1.78, 0.26), Vector3(0.11, H + 1.67, 0.32),
				Vector3(0.13, H + 1.58, 0.35)], Vector3(0.3, 0.2, 0.9).normalized(), 0.05, 0.022, ink, lilac, 4, 0.5, 15.0)
			# the crown gem (was a shadow_glow_hero surface): fully glowing vertex colour
			FaceKit.put_mesh(acc, sphere(0.07, 8, 4), Transform3D(Basis.IDENTITY, Vector3(0, H + 2.01, 0.235)), FaceKit.glow(Color(0.72, 0.34, 1.0), 1.0)),
	}
	_mcache["face_style"] = st
	return st


## Thin dark-violet mist rising from the hem (6 soft billboards, MIX blend, world space so it trails).
func _make_mist() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "ShadowMist"
	p.amount = 6
	p.lifetime = 2.4
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 3, 4))
	p.position = Vector3(0, 0.12, 0)
	if not _mcache.has("mist_pm"):
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pm.emission_ring_axis = Vector3.UP
		pm.emission_ring_radius = 0.38
		pm.emission_ring_inner_radius = 0.2
		pm.emission_ring_height = 0.05
		pm.direction = Vector3.UP
		pm.spread = 30.0
		pm.initial_velocity_min = 0.12
		pm.initial_velocity_max = 0.28
		pm.gravity = Vector3.ZERO
		pm.scale_min = 0.8
		pm.scale_max = 1.2
		var sc := Curve.new()
		sc.add_point(Vector2(0, 0.5))
		sc.add_point(Vector2(1, 1.5))
		var sct := CurveTexture.new()
		sct.curve = sc
		pm.scale_curve = sct
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.3, Color(1, 1, 1, 0.55))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_ramp = gt
		_mcache["mist_pm"] = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.75, 0.75)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.vertex_color_use_as_albedo = true
		sm.albedo_color = Color(0.10, 0.04, 0.16, 1.0)
		sm.no_depth_test = false
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		var rg := Gradient.new()
		rg.set_color(0, Color(1, 1, 1, 1))
		rg.set_color(1, Color(1, 1, 1, 0))
		var rt := GradientTexture2D.new()
		rt.gradient = rg
		rt.fill = GradientTexture2D.FILL_RADIAL
		rt.fill_from = Vector2(0.5, 0.5)
		rt.fill_to = Vector2(0.5, 0.0)
		rt.width = 64
		rt.height = 64
		sm.albedo_texture = rt
		q.material = sm
		_mcache["mist_draw"] = q
	p.process_material = _mcache["mist_pm"]
	p.draw_pass_1 = _mcache["mist_draw"]
	return p


# ================================================================ poses (overrides of the kit's idle / walk / attack)

func _pose_idle(w: float) -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	pos(P_ROOT, Vector3(0, 0.03 * s * w, 0))                                   # hover bob
	rot(P_HIPS, Vector3(0, 0, 1.5 * DEG * sin(0.5 * ph) * w))                   # robe sway
	rot(P_CHEST, Vector3((HUNCH + 2.0 * DEG * s) * w, 0, 0))                    # looming breath
	rot(P_HEAD, Vector3(3.0 * DEG * w, 7.0 * DEG * sin(0.5 * ph + 1.0) * w, 0)) # head low, slow looks
	rot(P_ARM_L, Vector3((-22.0 + 6.0 * sin(0.8 * ph)) * DEG * w, 0, -10.0 * DEG * w))   # claw hovers forward
	rot(P_ARM_R, Vector3(0, 0, 2.0 * DEG * sin(0.7 * ph) * w))                  # staff sway


## Fast idle path (kit): same pose as _pose_idle(1), written only when changed.
func _idle_fast() -> void:
	for i: int in _pidx:
		_off_pos[i] = Vector3.ZERO
		_off_rot[i] = Vector3.ZERO
	_pose_idle(1.0)
	for i: int in _pidx:
		_write_rot(i, _rest_rot[i] + _off_rot[i])
		_write_pos(i, _rest_pos[i] + _off_pos[i])


## Glide instead of steps: leans into the move, robe and cape trail, the free hand drags behind.
func _pose_walk(w: float, _rate: float) -> void:
	var s: float = sin(TAU * _walk_p)
	pos(P_ROOT, Vector3(0, 0.025 * s * w, 0))
	rot(P_ROOT, Vector3(6.0 * DEG * w, 0, 0))
	rot(P_HIPS, Vector3(10.0 * DEG * w, 4.0 * DEG * s * w, 3.0 * DEG * s * w))
	rot(P_CHEST, Vector3(4.0 * DEG * w, -3.0 * DEG * s * w, 2.0 * DEG * s * w))
	rot(P_HEAD, Vector3(3.0 * DEG * w, 0, 0))
	rot(P_ARM_L, Vector3((28.0 + 6.0 * s) * DEG * w, 0, -18.0 * DEG * w))
	rot(P_ARM_R, Vector3((-14.0 + 4.0 * s) * DEG * w, 0, 4.0 * DEG * w))
	_staff_off.x += (14.0 - 4.0 * s) * DEG * w     # the staff stays upright like a pilgrim's staff
	_cape_off += (16.0 + 4.0 * s) * DEG * w


## wizard_bolt: the kit raises ArmR and fires `release`; Malrik also leans in, tips the shard toward the target
## and flicks his claw hand forward.
func _pose_attack(prev: float, t: float) -> bool:
	var going := super._pose_attack(prev, t)
	if attack_style == &"wizard_bolt":
		rot(P_CHEST, Vector3(_k3(t, 0.0, 0.12, 0.18, 0.45, -6.0, 10.0) * DEG, 0, 0))
		rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.10, 0.16, 0.45, -55.0, -70.0) * DEG, 0, _k3(t, 0.0, 0.1, 0.16, 0.45, -12.0, -12.0) * DEG))
		pos(P_ROOT, Vector3(0, 0, _k3(t, 0.10, 0.16, 0.20, 0.45, 0.10, 0.10)))
		_staff_off.x += _k3(t, 0.0, 0.12, 0.20, 0.45, 55.0, 55.0) * DEG
		var k := _k3(t, 0.0, 0.12, 0.16, 0.45, 1.0, 1.0)
		_spin_speed = (40.0 + 300.0 * k) * DEG
		_eye_boost += 0.8 * k
	return going


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		&"soul_siphon":
			# 0-0.28 arms spread wide, head back, he rises; 0.4-0.6 pulls the souls into his chest; back by 0.9.
			var k := _k3(t, 0.0, 0.28, 0.45, 0.9, 1.0, 1.0)
			var p := _k3(t, 0.38, 0.58, 0.64, 0.9, 1.0, 1.0)
			var lev := _k3(t, 0.0, 0.32, 0.62, 0.9, 1.0, 1.0)
			rot(P_ARM_L, Vector3((-70.0 * k - 25.0 * p) * DEG, 0, (-55.0 * k + 60.0 * p) * DEG))
			rot(P_ARM_R, Vector3((-55.0 * k - 10.0 * p) * DEG, 0, (45.0 * k - 30.0 * p) * DEG))
			rot(P_CHEST, Vector3((-12.0 * k + 18.0 * p) * DEG, 0, 0))
			rot(P_HEAD, Vector3((-20.0 * k + 22.0 * p) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0.25 * lev, 0))
			_staff_off.x += 45.0 * k * DEG
			_cape_off += 10.0 * k * DEG
			_bob_extra = Vector3(0, 0.25 * k, 0)
			_eye_boost += 2.0 * maxf(k, p)
			_spin_speed = (40.0 + 240.0 * k) * DEG
			_cast_boost = 1.0 + 1.5 * k + 1.0 * p
			_cast_light = 1.0 + 1.0 * k + 0.6 * p
			return 0.9
		&"umbral_shroud":
			# 0-0.25 hunches, arms cross over the chest, sinks into his shadow, cape billows up; back by 0.9.
			var k := _k3(t, 0.0, 0.25, 0.55, 0.9, 1.0, 1.0)
			rot(P_CHEST, Vector3(22.0 * DEG * k, 0, 0))
			rot(P_HEAD, Vector3(10.0 * DEG * k, 0, 0))
			rot(P_ARM_L, Vector3(-55.0 * DEG * k, 0, 42.0 * DEG * k))
			rot(P_ARM_R, Vector3(-42.0 * DEG * k, 0, -18.0 * DEG * k))
			pos(P_ROOT, Vector3(0, -0.16 * k, 0))
			_staff_off += Vector3(42.0 * DEG * k, 0, 18.0 * DEG * k)
			_cape_off += 10.0 * DEG * k
			_eye_boost += 1.8 * k
			_cast_light = 1.0 + 0.6 * k
			return 0.9
		_:  # shadow_lance (and unknown ids)
			# 0-0.20 gather: shard drops into the claw and spins, claw hand charges; 0.20-0.32 the staff swings down
			# into a lance pointing at the target, lunge, shard springs forward; hold to 0.45; back by 0.8.
			var arm := _k3(t, 0.0, 0.20, 0.32, 0.8, -25.0, -72.0)
			var stf := _k3(t, 0.0, 0.20, 0.32, 0.8, 20.0, 145.0)
			rot(P_ARM_R, Vector3(arm * DEG, 0, _k3(t, 0.0, 0.2, 0.32, 0.8, 0.0, -8.0) * DEG))
			_staff_off.x += stf * DEG
			rot(P_CHEST, Vector3(_k3(t, 0.0, 0.20, 0.32, 0.8, -10.0, 14.0) * DEG, _k3(t, 0.0, 0.2, 0.32, 0.8, 8.0, -12.0) * DEG, 0))
			rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.20, 0.32, 0.8, -60.0, 35.0) * DEG, 0, _k3(t, 0.0, 0.2, 0.32, 0.8, -10.0, -25.0) * DEG))
			rot(P_HEAD, Vector3(_k3(t, 0.0, 0.2, 0.32, 0.8, -6.0, 8.0) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0, _k3(t, 0.18, 0.32, 0.42, 0.8, 0.24, 0.20)))
			_bob_extra = Vector3(0, _k3(t, 0.0, 0.20, 0.32, 0.8, -0.10, 0.18), 0)
			_cape_off += _k3(t, 0.15, 0.32, 0.42, 0.8, 14.0, 14.0) * DEG
			var k := _k3(t, 0.0, 0.20, 0.35, 0.8, 1.0, 1.0)
			_spin_speed = (40.0 + 360.0 * k) * DEG
			_eye_boost += 1.5 * k
			_cast_boost = 1.0 + 2.0 * k
			_cast_light = 1.0 + 1.5 * k   # 1.0 -> 2.5
			return 0.8


# ================================================================ per frame

func _extra_process(dt: float) -> void:
	if _dead:
		var t := _death_t
		# arms claw upward and the body arches back while the shadow swallows him
		var a := _ease_out(clampf((t - 0.12) / 0.38, 0.0, 1.0))
		rot(P_ARM_L, Vector3(-150.0 * DEG * a, 0, -18.0 * DEG * a))
		rot(P_ARM_R, Vector3(-115.0 * DEG * a, 0, 14.0 * DEG * a))
		rot(P_CHEST, Vector3(-52.0 * DEG * a, 0, 0))
		rot(P_HEAD, Vector3(-28.0 * DEG * a, 0, 0))
		_staff_off.x += 70.0 * DEG * a
		_cape_off += 15.0 * DEG * a
		# the shard tears free, rises 0.5 m and shatters at 0.7 s
		_bob_extra = Vector3(0, 0.5 * _ease_out(clampf(t / 0.6, 0.0, 1.0)), 0)
		if t >= 0.7 and not _shattered:
			_shattered = true
			_shard.visible = false
			_burst.global_position = _shard.global_position
			_burst.restart()
	elif _hit_t < HIT_LEN:
		_eye_boost += 1.5 * (1.0 - _hit_t / HIT_LEN)
	super._extra_process(dt)


func _wizard_process(dt: float) -> void:
	if _shard == null:
		return
	_spin = fmod(_spin + dt * _spin_speed, TAU)
	_spin_speed = 40.0 * DEG
	_shard.rotation.y = _spin
	# staff pivot + push, cape hinge (written only when changed)
	if _staff_off != _staff_rot_w:
		_staff_rot_w = _staff_off
		_staff.rotation = _staff_off
	var sp := _staff_rest + _staff_push
	if sp != _staff_pos_w:
		_staff_pos_w = sp
		_staff.position = sp
	var c := CAPE_REST + _cape_off
	if c != _cape_w:
		_cape_w = c
		_cape_pivot.rotation.x = c
	# eyes + crown gem
	var g: float
	if _dead:
		g = 4.0 * (1.0 - smoothstep(0.25, 0.5, _death_t))
	else:
		g = glow_level() * _eye_boost
	if g != _glint_w:
		_glint_w = g
		_glints.set_instance_shader_parameter(&"glow_boost", g)
	if _face:
		_face.auto(self)
	_staff_off = Vector3.ZERO
	_staff_push = Vector3.ZERO
	_cape_off = 0.0
	_eye_boost = EYE_BASE


func _death_glow() -> float:
	return 3.0 * clampf(1.0 - _death_t / 0.7, 0.0, 1.0)


func _on_revive() -> void:
	super._on_revive()
	_shattered = false
	_glint_w = -1.0
	if _face:
		_face.reset()
	_staff_rot_w = Vector3(99, 0, 0)
	_staff_pos_w = Vector3(99, 0, 0)
	_cape_w = 99.0
	if _shard:
		_shard.visible = true
