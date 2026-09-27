class_name BarrowGiantModel
extends WardenModel
## Barrow Giant, Shadow's second tier-3 titan (titans-2.md 4 / 11 row 13c.V3): the cheap, massable stone artillery.
## Built on the Ruin Warden (warden_model.gd, WardenModel extends CharacterModel) the way the Frost Dragon is built on the
## Cinder Dragon: the rig, the kit hooks, the idle (breathing + floating head scan), the heavy stomping walk, the hit
## knock, the body fade of the crumble, and the mesh / particle helpers (rough, _octa, _burst, _smoke_draw, _ppm_soul,
## _write_fade...) come from WardenModel unchanged; this script only builds new parts and replaces the attack (slam ->
## boulder_throw), the death (crumble -> collapse into a barrow mound) and the glow drive. Nothing in warden_model.gd or
## ruin_warden.tscn changed.
## Look (the read at 40 m): a hunched giant of dark violet barrow stone (glowing violet crack veins), 2.9 m at the hump,
## holding a PALE ARCHED GRAVESTONE overhead in both fists (top at ~4.6 m; a violet soul-knot rune glows on both faces,
## a clod of torn-up earth under it). Its chest is a dolmen doorway with a violet soul core inside, its back a burial
## mound with two standing stones, its head sits low under the slab with two violet eyes and a crown of broken
## grave-markers on a tarnished silver band. A tattered team-colour burial shroud hangs over the LEFT shoulder (the
## asymmetric element); a shroud rag hangs at the hips; silver shackles on the ankles.
## Scale: authored like the warden (feet origin, face +Z) and scaled x1.85 by the scene root; every pose offset scales.
## Hooks (kit, has_method-guarded by gameplay, safe before _ready): set_team_color(c) (shroud = team cloth; the Shadow
## colour is a no-op) Â· set_moving(speed) Â· play_attack() (= boulder_throw, below) Â· play_hit() Â· play_death() + signal
## death_finished (1.6 s) Â· play_cast Â· play_level_up Â· set_veterancy Â· set_status Â· revive(); read-only attack_windup.
## Boulder throw (attack_style &"boulder_throw", 1.8 s): 0-0.40 heave the slab back over the hump (the core charges) Â·
## 0.40-0.60 two-arm overhead lob, RELEASE at 0.60 s (the slab leaves the fists: hidden, signal
## boulder_released(origin) with its world centre, violet sparks) Â· 0.60-1.08 follow-through down to the ground Â·
## 1.08 tears a new gravestone out of the ground (dust, the slab grows back in the fists, its rune ignites) Â· 1.08-1.80
## lifts it back overhead. `THROW_RELEASE` / `get_throw_release()` = 0.6, `get_throw_origin() -> Vector3` (world).
## Death (1.6 s): rears up as the core flares, the slab crashes down in front, the knees give, the body collapses and
## sinks while a barrow mound (earth, rubble, a tilted headstone with the glowing rune) rises where it fell and a violet
## soul wisp leaves it; the mound sinks and fades at the end (the warden crumble, recoloured and grounded).
## Budget (massable): 7 merged pivots + Core + Gravestone + blob = 10 draw instances in play (+ the death mound, hidden
## until the death), 2 one-shot particle systems (Dust: footfalls < 30 m, regrab, collapse; Soul: release sparks, death
## wisp), no looping emitter, 0 lights, 7 own materials + 2 kit palette entries (shadow_silver, shadow_obsidian) + blob.

signal boulder_released(origin: Vector3)

const OWN_MATS := "res://art/units/shadow/barrow_giant/materials/"
const VIOLET := Color(0.72, 0.32, 1.0)
const BG_DUST := Color(0.33, 0.30, 0.36)
const THROW_RELEASE := 0.6
const REGRAB := 1.08
const POP_LEN := 0.16
const BG_ATTACK_LEN := 1.8
const BG_DEATH_LEN := 1.6
## Gravestone (slab) size, authored units (x1.85 in the world): arched top.
const SLAB_W := 0.70
const SLAB_RECT := 0.56
const SLAB_T := 0.21
const SLAB_ARCH_Y := 0.10
## Model-space rest centre of the carried slab and the arm points (right side; the left mirrors x).
const SLAB_AT := Vector3(0.0, 2.36, -0.08)
const SLAB_TILT := -14.0
const A_SHOULDER := Vector3(0.64, 1.40, 0.0)
const A_ELBOW := Vector3(0.72, 1.72, -0.02)
const A_WRIST := Vector3(0.54, 1.93, -0.06)
const A_FIST := Vector3(0.47, 2.02, -0.07)

## Timelines [t, value, ease into this key (0 smooth, 1 in, 2 out, 3 linear)]. Arms: + = forward for the raised arms.
static var ARMS_X := PackedFloat32Array([0.0, 0.0, 0, 0.40, -38.0, 0, 0.60, 62.0, 1, 0.82, 98.0, 2, 1.08, 140.0, 0,
	1.22, 136.0, 0, 1.55, 30.0, 0, 1.80, 0.0, 0])
static var CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.40, -14.0, 0, 0.60, 20.0, 1, 0.82, 30.0, 2, 1.08, 42.0, 0,
	1.22, 38.0, 0, 1.55, 8.0, 0, 1.80, 0.0, 0])
static var HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.40, -10.0, 0, 0.60, 4.0, 1, 1.08, -24.0, 0, 1.40, -10.0, 0,
	1.80, 0.0, 0])
static var ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.40, -0.05, 0, 0.60, 0.02, 1, 0.82, -0.03, 2, 1.08, -0.13, 0,
	1.22, -0.11, 0, 1.55, -0.02, 0, 1.80, 0.0, 0])
static var ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.40, -0.06, 0, 0.60, 0.10, 1, 0.82, 0.13, 2, 1.22, 0.08, 0,
	1.80, 0.0, 0])
static var LEG_L_X := PackedFloat32Array([0.0, 0.0, 0, 0.40, -6.0, 0, 0.60, -26.0, 1, 0.82, -24.0, 2, 1.22, -16.0, 0,
	1.80, 0.0, 0])
static var LEG_R_X := PackedFloat32Array([0.0, 0.0, 0, 0.40, 6.0, 0, 0.60, 18.0, 1, 1.22, 12.0, 0, 1.80, 0.0, 0])
static var CORE_K := PackedFloat32Array([0.0, 0.0, 0, 0.40, 0.6, 0, 0.60, 1.0, 1, 0.90, 0.2, 2, 1.22, 0.5, 0,
	1.80, 0.0, 0])
static var RUNE_K := PackedFloat32Array([0.0, 1.0, 0, 0.40, 1.6, 0, 0.59, 2.2, 1, 0.60, 0.0, 3, 1.08, 0.0, 3,
	1.24, 2.6, 2, 1.55, 1.0, 0, 1.80, 1.0, 0])

static var _bmats: Dictionary = {}
static var _bmesh: Dictionary = {}
static var _bfx: Dictionary = {}

var _stone: MeshInstance3D
var _mound: MeshInstance3D
var _dust: GPUParticles3D
var _soul: GPUParticles3D
var _stone_scale_written: Vector3 = Vector3.ONE
var _mound_written: float = -1.0
var _mound_glow_written: float = -1.0
var _death_dust_done: bool = false
var _death_soul_done: bool = false


static func _bmat(nm: String) -> Material:
	if not _bmats.has(nm):
		_bmats[nm] = load(OWN_MATS + nm + ".tres")
	return _bmats[nm]


# ================================================================ parts

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var fx: Node3D = $Fx
	var stone := _bmat("barrow_stone")        # dark violet barrow stone with glowing violet veins
	var dark := _bmat("barrow_stone_dark")
	var grave := _bmat("barrow_grave")        # pale weathered headstone stone (the slab, the crown markers)
	var earth := _bmat("barrow_earth")
	var glow := _bmat("barrow_soul_glow")
	var shroud := _bmat("barrow_shroud_cape")
	var shroud_lump := _bmat("barrow_shroud_cloth")
	var silver := palette(&"shadow_silver")

	# ---- Legs: short thick pillars, light thighs, dark shins and slab feet, tarnished silver shackles (broken chain).
	for side: int in [-1, 1]:
		var leg: Node3D = $Root/Hips/LegL if side < 0 else $Root/Hips/LegR
		var s := float(side)
		add_part(leg, rough(box(Vector3(0.36, 0.34, 0.38)), 0.035, 3.0 + s), stone, Vector3(0.31 * s, 0.47, 0.0),
			Vector3(0, 0, -5.0 * s))
		add_part(leg, rough(box(Vector3(0.24, 0.16, 0.12)), 0.02, 4.0 + s), dark, Vector3(0.32 * s, 0.33, 0.19),
			Vector3(-12, 0, 0))
		add_part(leg, rough(box(Vector3(0.32, 0.26, 0.34)), 0.03, 5.0 + s), dark, Vector3(0.33 * s, 0.21, 0.04))
		add_part(leg, torus(0.15, 0.205, 10), silver, Vector3(0.33 * s, 0.14, 0.04))
		add_part(leg, torus(0.035, 0.065, 8), silver, Vector3(0.50 * s, 0.07, 0.12), Vector3(0, 30.0 * s, 90))
		add_part(leg, rough(box(Vector3(0.44, 0.15, 0.56)), 0.03, 7.0 + s), dark, Vector3(0.34 * s, 0.075, 0.10))

	# ---- Hips: pelvis block, a tarnished silver band, a shroud rag hanging in front.
	add_part(hips, rough(box(Vector3(0.72, 0.28, 0.48)), 0.04, 11.0), dark, Vector3(0, 0.72, -0.02))
	add_part(hips, box(Vector3(0.78, 0.08, 0.54)), silver, Vector3(0, 0.83, -0.02))
	add_part(hips, cape(0.34, 0.40), shroud, Vector3(0.06, 0.64, 0.275), Vector3(6, 0, 2))

	# ---- Chest: a hunched keg of barrow stone leaning forward, a dolmen doorway (two dark uprights + a lintel) with
	# the soul core inside, a burial mound on the back with two standing stones, the yoke of shoulder boulders.
	add_part(chest, rough(cyl(0.36, 0.32, 0.34, 6), 0.03, 13.0), stone, Vector3(0, 0.98, 0.02), Vector3(0, 30, 0),
		Vector3(1, 1, 0.82))
	add_part(chest, rough(cyl(0.58, 0.42, 0.62, 6), 0.045, 14.0), stone, Vector3(0, 1.24, 0.06), Vector3(21, 30, 0),
		Vector3(1, 1, 0.78))
	for side: int in [-1, 1]:
		var s := float(side)
		add_part(chest, rough(box(Vector3(0.20, 0.34, 0.16)), 0.025, 15.0 + s), dark, Vector3(0.19 * s, 1.28, 0.37),
			Vector3(16, -10.0 * s, 3.0 * s))
	add_part(chest, rough(box(Vector3(0.58, 0.12, 0.18)), 0.02, 17.0), dark, Vector3(0, 1.47, 0.38), Vector3(16, 0, -3))
	add_part(chest, box(Vector3(0.20, 0.26, 0.05)), palette(&"shadow_obsidian"), Vector3(0, 1.28, 0.335),
		Vector3(16, 0, 0))
	# The back: a burial mound of earth (the barrow it was raised from) and two dark standing stones.
	add_part(chest, rough(sphere(0.46, 10, 5), 0.035, 18.0), earth, Vector3(0, 1.40, -0.24), Vector3(-12, 0, 0),
		Vector3(1.30, 0.72, 1.0))
	add_part(chest, rough(box(Vector3(0.13, 0.36, 0.11)), 0.02, 19.0), dark, Vector3(-0.22, 1.66, -0.33),
		Vector3(-18, 10, 14))
	add_part(chest, rough(box(Vector3(0.11, 0.28, 0.10)), 0.02, 20.0), dark, Vector3(0.20, 1.63, -0.40),
		Vector3(-26, -8, -12))
	# Shoulder yoke: two big boulders.
	for side: int in [-1, 1]:
		var s := float(side)
		add_part(chest, rough(box(Vector3(0.43, 0.42, 0.44)), 0.05, 21.0 + s), stone, Vector3(0.60 * s, 1.38, -0.02),
			Vector3(8, 18.0 * s, 12.0 * s))
	add_part(chest, rough(box(Vector3(0.30, 0.20, 0.26)), 0.03, 24.0), dark, Vector3(0, 1.27, 0.22))   # neck block
	# The burial shroud over the LEFT shoulder: a folded lump on the boulder, a rag down the front, a long one down
	# the back over the mound (team colour).
	add_part(chest, rough(sphere(0.27, 10, 5), 0.02, 23.0), shroud_lump, Vector3(-0.60, 1.58, -0.04), Vector3(0, 0, 10),
		Vector3(1.15, 0.52, 1.25))
	add_part(chest, cape(0.40, 0.70), shroud, Vector3(-0.60, 1.25, 0.27), Vector3(-14, 0, 5))
	add_part(chest, cape(0.52, 0.92), shroud, Vector3(-0.48, 1.20, -0.62), Vector3(16, 180, -6))
	# Soul core in the dolmen (own glow: pulses, charges on the throw, flares at death).
	_core = add_part(chest, _octa(), glow, Vector3(0, 1.28, 0.39), Vector3(90 + 16, 0, 0), Vector3(1.35, 1.35, 1.35),
		true, "Core")
	_core.set_meta(&"own_glow", true)

	# ---- Head: low and forward under the slab, heavy brow, jaw, two violet eyes, a crown of broken grave-markers.
	add_part(head, rough(box(Vector3(0.38, 0.30, 0.34)), 0.03, 31.0), stone, Vector3(0, 1.31, 0.40))
	add_part(head, rough(box(Vector3(0.46, 0.12, 0.18)), 0.025, 32.0), dark, Vector3(0, 1.42, 0.51), Vector3(-12, 0, 0))
	add_part(head, rough(box(Vector3(0.34, 0.13, 0.28)), 0.025, 33.0), dark, Vector3(0, 1.17, 0.44), Vector3(6, 0, 0))
	for side: int in [-1, 1]:
		add_part(head, box(Vector3(0.085, 0.055, 0.04)), glow, Vector3(0.09 * side, 1.345, 0.575))
	add_part(head, torus(0.165, 0.205, 12), silver, Vector3(0, 1.465, 0.39))
	var angs: Array[float] = [-64.0, -32.0, 0.0, 32.0, 64.0, 150.0, 210.0]
	for i: int in angs.size():
		var a := deg_to_rad(angs[i])
		var d := Vector3(sin(a), 0, cos(a))
		var hh: float = 0.15 + 0.05 * _h(Vector3(float(i), 3.0, 1.0))
		add_part(head, rough(box(Vector3(0.11, hh, 0.05)), 0.015, 40.0 + float(i)), grave,
			Vector3(0, 1.47 + hh * 0.5, 0.39) + d * 0.185, Vector3(14, angs[i], 8.0 * (_h(Vector3(float(i), 1, 5)) - 0.5)))

	# ---- Arms: raised, both fists gripping the gravestone overhead; the slab rides on the right arm.
	for side: int in [-1, 1]:
		var arm: Node3D = $Root/Chest/ArmL if side < 0 else $Root/Chest/ArmR
		var s := float(side)
		var sh := _mx(A_SHOULDER, s)
		var el := _mx(A_ELBOW, s)
		var wr := _mx(A_WRIST, s)
		_limb(arm, rough(box(Vector3(0.28, sh.distance_to(el) + 0.14, 0.30)), 0.03, 50.0 + s), stone, sh, el)
		add_part(arm, rough(sphere(0.16, 8, 4), 0.02, 52.0 + s), dark, el)
		_limb(arm, rough(cyl(0.17, 0.22, el.distance_to(wr) + 0.10, 6), 0.025, 54.0 + s), stone, el, wr)
		_limb(arm, cyl(0.215, 0.215, 0.12, 8), silver, el.lerp(wr, 0.45), el.lerp(wr, 0.46))
		_limb(arm, rough(box(Vector3(0.25, 0.24, 0.28)), 0.03, 56.0 + s), dark, wr, _mx(A_FIST, s) * 2.0 - wr,
			_mx(A_FIST, s))
	var arm_r: Node3D = $Root/Chest/ArmR
	_stone = add_part(arm_r, _slab_mesh(), null, SLAB_AT, Vector3(SLAB_TILT, 0, 0), Vector3.ONE, true, "Gravestone")
	_stone.material_override = null
	_stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_stone.set_meta(&"own_glow", true)

	# ---- Death mound (hidden until the death): earth, rubble and a tilted headstone with the rune, on the ground.
	_mound = MeshInstance3D.new()
	_mound.name = "Mound"
	_mound.mesh = _mound_mesh()
	_mound.position = Vector3(0, 0, 0.30)
	_mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mound.visible = false
	_mound.set_meta(&"own_glow", true)
	fx.add_child(_mound)

	# ---- FX: two one-shot emitters, repositioned and re-used (no looping emitter: cheap in a mass).
	_dust = _burst("Dust", fx, 18, 1.1, _ppm_bg(&"step"), _smoke_draw(0.55))
	_soul = make_motes(VIOLET, 18, 1.3, 0.25, 2.0, 0.10, false, true)
	_soul.name = "Soul"
	_soul.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	_soul.process_material = _ppm_bg(&"sparks")
	fx.add_child(_soul)
	ensure_shadow_blob(0.62, Color(0.07, 0.03, 0.10, 0.55))


## x mirrored to side s (-1 left, +1 right).
static func _mx(p: Vector3, s: float) -> Vector3:
	return Vector3(p.x * s, p.y, p.z)


## A part whose local +Y runs from a to b, centred at `at` (default: the midpoint).
func _limb(pivot: Node3D, mesh: Mesh, mat: Material, a: Vector3, b: Vector3, at: Variant = null) -> void:
	var y := (b - a).normalized()
	var z := Vector3.RIGHT.cross(y).normalized()
	var x := y.cross(z).normalized()
	var c: Vector3 = at if at != null else (a + b) * 0.5
	add_part(pivot, mesh, mat, c, _deg(Basis(x, y, z).get_euler()))


## The parts of one arched gravestone (local, centred): [mesh, Transform3D, material] for _combine.
static func _slab_parts(xf: Transform3D, with_clod: bool) -> Array:
	var up := Basis(Vector3.RIGHT, PI * 0.5)     # cylinder / torus axis Y -> Z
	var r := SLAB_W * 0.5
	var arch := SLAB_ARCH_Y                      # arch centre; the rectangle hangs under it, the round top over it
	var p: Array = []
	p.append([rough(box(Vector3(SLAB_W, SLAB_RECT, SLAB_T)), 0.02, 51.0),
		xf * Transform3D(Basis(), Vector3(0, arch - SLAB_RECT * 0.5, 0)), _bmat("barrow_grave")])
	p.append([rough(cyl(r, r, SLAB_T, 14), 0.02, 52.0), xf * Transform3D(up, Vector3(0, arch, 0)), _bmat("barrow_grave")])
	if with_clod:
		p.append([rough(box(Vector3(SLAB_W * 0.95, 0.12, SLAB_T + 0.10)), 0.035, 53.0),
			xf * Transform3D(Basis(Vector3.BACK, 0.04), Vector3(0.02, arch - SLAB_RECT - 0.04, 0)), _bmat("barrow_earth")])
	# The soul rune on both faces: a diamond outline around a lit core, a crack running down from it to the foot.
	for zs: float in [1.0, -1.0]:
		var zf := (SLAB_T * 0.5 + 0.006) * zs
		var ctr := Vector3(0, arch - 0.10, zf)
		for q: int in 4:
			var ang := deg_to_rad(45.0 + 90.0 * float(q))
			var off := Vector3(cos(ang), sin(ang), 0) * 0.095
			p.append([rough(box(Vector3(0.04, 0.23, 0.02)), 0.0, 56.0),
				xf * Transform3D(Basis(Vector3.BACK, ang), ctr + off), _bmat("barrow_soul_glow")])
		p.append([rough(box(Vector3(0.07, 0.07, 0.02)), 0.0, 55.0),
			xf * Transform3D(Basis(Vector3.BACK, PI * 0.25), ctr), _bmat("barrow_soul_glow")])
		p.append([rough(box(Vector3(0.03, 0.20, 0.02)), 0.0, 57.0),
			xf * Transform3D(Basis(Vector3.BACK, 0.18), ctr + Vector3(0.02, -0.25, 0)), _bmat("barrow_soul_glow")])
		p.append([rough(box(Vector3(0.028, 0.12, 0.02)), 0.0, 57.0),
			xf * Transform3D(Basis(Vector3.BACK, -0.35), ctr + Vector3(0.025, -0.40, 0)), _bmat("barrow_soul_glow")])
	return p


static func _slab_mesh() -> ArrayMesh:
	if not _bmesh.has("slab"):
		_bmesh["slab"] = _combine(_slab_parts(Transform3D.IDENTITY, true))
	return _bmesh["slab"]


static func _mound_mesh() -> ArrayMesh:
	if not _bmesh.has("mound"):
		var p: Array = []
		p.append([rough(sphere(0.55, 12, 6), 0.05, 61.0), Transform3D(Basis().scaled(Vector3(1.35, 0.55, 1.10)),
			Vector3(0, -0.02, 0)), _bmat("barrow_earth")])
		var rub: Array = [[Vector3(-0.52, 0.07, 0.36), 10.0], [Vector3(0.56, 0.08, 0.22), -25.0],
			[Vector3(-0.26, 0.20, -0.38), 40.0], [Vector3(0.38, 0.17, -0.30), 70.0], [Vector3(0.05, 0.10, 0.55), -60.0]]
		for i: int in rub.size():
			var b := Basis(Vector3.UP, deg_to_rad(float(rub[i][1]))) * Basis(Vector3.RIGHT, 0.3)
			p.append([rough(box(Vector3(0.24, 0.17, 0.21)), 0.03, 62.0 + float(i)), Transform3D(b, rub[i][0]),
				_bmat("barrow_stone") if i % 2 == 0 else _bmat("barrow_stone_dark")])
		var hs := Transform3D(Basis.from_euler(Vector3(deg_to_rad(-10.0), deg_to_rad(14.0), deg_to_rad(8.0)))
			.scaled_local(Vector3.ONE * 0.85), Vector3(0.10, 0.50, -0.12))
		p.append_array(_slab_parts(hs, false))
		_bmesh["mound"] = _combine(p)
	return _bmesh["mound"]


## Merges [mesh, Transform3D, material] parts into one ArrayMesh, one surface per material (first-seen order).
## Every source mesh is a flat non-indexed one (rough), so they append cleanly.
static func _combine(parts: Array) -> ArrayMesh:
	var order: Array[Material] = []
	var sts: Dictionary = {}
	for pt: Array in parts:
		var mat: Material = pt[2]
		if not sts.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			sts[mat] = st
			order.append(mat)
		(sts[mat] as SurfaceTool).append_from(pt[0] as Mesh, 0, pt[1] as Transform3D)
	var am := ArrayMesh.new()
	for mat: Material in order:
		(sts[mat] as SurfaceTool).commit(am)
		am.surface_set_material(am.get_surface_count() - 1, mat)
	return am


func _after_ready() -> void:
	super._after_ready()
	# Both raised arms throw a shadow (the kit casts ArmR only); the small head under the slab does not.
	var al := get_node_or_null(^"Root/Chest/ArmL/Merged") as GeometryInstance3D
	if al:
		al.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var hd := get_node_or_null(^"Root/Chest/Head/Merged") as GeometryInstance3D
	if hd:
		hd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mound_glow(0.0, true)


# ================================================================ hooks

## The shroud (and the hip rag) take the kingdom colour; the stone never does. The Ruin Warden's own override is a
## no-op, so this is the kit's behaviour restated.
func set_team_color(c: Color) -> void:
	if not _ready_done:
		_team_pending = c
		return
	_team_pending = null
	_apply_team_color(c)


## Seconds from play_attack() to the moment the slab leaves the fists (the gameplay lob should launch then).
func get_throw_release() -> float:
	return THROW_RELEASE


## World centre of the carried gravestone (where the thrown stone starts).
func get_throw_origin() -> Vector3:
	if _stone and _stone.is_inside_tree():
		return _stone.global_position
	return global_position + Vector3.UP * 4.0


func play_death() -> void:
	if _dead:
		return
	super.play_death()
	_stone_set(true, Vector3.ONE)
	_death_dust_done = false
	_death_soul_done = false


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"attack_start", &"attack_end":
			_stone_set(true, Vector3.ONE)
		&"release":
			var o := get_throw_origin()
			boulder_released.emit(o)
			if _soul and _soul.is_inside_tree() and _tier < 2:
				_soul.process_material = _ppm_bg(&"sparks")
				_soul.global_position = o
				_soul.restart()


func _on_revive() -> void:
	super._on_revive()
	_stone_set(true, Vector3.ONE)
	if _mound:
		_mound.visible = false
		_mound.transparency = 0.0
	_mound_written = -1.0
	_mound_glow(0.0, true)
	if _dust:
		_dust.process_material = _ppm_bg(&"step")


func _stone_set(on: bool, scl: Vector3) -> void:
	if _stone == null:
		return
	if _stone.visible != on:
		_stone.visible = on
	if scl != _stone_scale_written:
		_stone_scale_written = scl
		_stone.scale = scl


# ================================================================ walk / attack

## The warden's heavy stomp, but both hands stay on the slab: the kit and warden arm swings are cancelled and the
## slab dips with every footfall instead.
func _pose_walk(w: float, rate: float) -> void:
	super._pose_walk(w, rate)
	var s: float = sin(TAU * _walk_p)
	var bob: float = -4.0 * DEG * cos(2.0 * TAU * _walk_p) * w
	rot(P_ARM_L, Vector3(28.0 * DEG * s * w + bob, 0, 0))
	rot(P_ARM_R, Vector3(-8.0 * DEG * s * w + bob, 0, 0))


## boulder_throw (replaces the warden's slam): see the header. Returns false when finished.
func _pose_attack(prev: float, t: float) -> bool:
	var arms := _trk(t, ARMS_X) * DEG
	rot(P_ARM_L, Vector3(arms, 0, 0))
	rot(P_ARM_R, Vector3(arms, 0, 0))
	rot(P_CHEST, Vector3(_trk(t, CHEST_X) * DEG, 0, 0))
	rot(P_HEAD, Vector3(_trk(t, HEAD_X) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _trk(t, ROOT_Y), _trk(t, ROOT_Z)))
	rot(P_LEG_L, Vector3(_trk(t, LEG_L_X) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_trk(t, LEG_R_X) * DEG, 0, 0))
	if prev < THROW_RELEASE and t >= THROW_RELEASE:
		_on_action_event(&"release")
		_stone_set(false, Vector3.ONE)
	if prev < REGRAB and t >= REGRAB:
		# Tears a new gravestone out of the ground: dust where the slab meets the ground.
		_stone_set(true, Vector3(0.55, 0.25, 0.55))
		if _dust and _dust.is_inside_tree() and _tier < 2:
			var p := get_throw_origin()
			_dust.process_material = _ppm_bg(&"scoop")
			_dust.global_position = Vector3(p.x, global_position.y + 0.05, p.z)
			_dust.restart()
	if t > REGRAB and t < REGRAB + POP_LEN + 0.05:
		var u := _ease_out(clampf((t - REGRAB) / POP_LEN, 0.0, 1.0))
		_stone_set(true, Vector3(0.55 + 0.45 * u, 0.25 + 0.75 * u, 0.55 + 0.45 * u))
	return t < BG_ATTACK_LEN


## Keyframe track [t, v, ease] (see ARMS_X): the value at t, eased per segment, held past the ends.
static func _trk(t: float, k: PackedFloat32Array) -> float:
	var n: int = k.size() / 3
	if t <= k[0]:
		return k[1]
	for i: int in range(1, n):
		var t1: float = k[i * 3]
		if t < t1:
			var t0: float = k[i * 3 - 3]
			var u: float = clampf((t - t0) / maxf(t1 - t0, 0.0001), 0.0, 1.0)
			match int(k[i * 3 + 2]):
				1:
					u = u * u
				2:
					u = 1.0 - (1.0 - u) * (1.0 - u)
				3:
					pass
				_:
					u = smoothstep(0.0, 1.0, u)
			return lerpf(k[i * 3 - 2], k[i * 3 + 1], u)
	return k[k.size() - 2]


# ================================================================ death (collapse into a barrow mound, 1.6 s)

func _pose_death(dt: float) -> void:
	_death_t += dt
	var t := _death_t
	var a: float = smoothstep(0.0, 0.2, t)                              # rears up, slab high, core flares
	var b: float = _ease_in(clampf((t - 0.2) / 0.4, 0.0, 1.0))         # the slab crashes down in front, knees give
	var c: float = _ease_in(clampf((t - 0.45) / 0.6, 0.0, 1.0))        # collapse and sink into the mound
	var rear: float = a * (1.0 - b)
	var arms: float = (-22.0 * rear + 128.0 * b) * DEG
	rot(P_ARM_L, Vector3(arms, 0, -14.0 * c * DEG))
	rot(P_ARM_R, Vector3(arms, 0, 14.0 * c * DEG))
	pos(P_ARM_L, Vector3(-0.08 * c, -0.30 * c, 0))
	pos(P_ARM_R, Vector3(0.08 * c, -0.30 * c, 0))
	rot(P_CHEST, Vector3((-14.0 * rear + 36.0 * b) * DEG, 0, 7.0 * b * DEG))
	rot(P_HEAD, Vector3((-18.0 * rear + 55.0 * b) * DEG, 0, 24.0 * b * DEG))
	pos(P_HEAD, Vector3(0.10 * b, -0.30 * c, 0.26 * b))
	rot(P_LEG_L, Vector3(-30.0 * b * DEG, 0, 0))
	rot(P_LEG_R, Vector3(52.0 * b * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, 0.05 * rear - 0.26 * b - 0.62 * c, 0.10 * b))
	_root_scale *= Vector3(1.0 + 0.18 * c, 1.0 - 0.5 * c, 1.0 + 0.18 * c)
	if t < 0.3:
		_death_glow = 1.0 + 3.0 * smoothstep(0.0, 0.22, t)
		var g := glow_level() * _death_glow
		for gi: GeometryInstance3D in _glow_nodes:
			gi.set_instance_shader_parameter(&"glow_boost", g)
	else:
		_glows_dead()
	_write_fade(smoothstep(0.62, 1.05, t))
	# The mound rises where it falls, holds with the rune lit, then sinks and fades.
	var rise: float = smoothstep(0.42, 0.95, t)
	var sink: float = smoothstep(1.25, BG_DEATH_LEN, t)
	if _mound:
		var key: float = rise * 10.0 + sink
		if key != _mound_written:
			_mound_written = key
			_mound.visible = t >= 0.42
			_mound.scale = Vector3(0.7 + 0.3 * rise, maxf(rise, 0.05), 0.7 + 0.3 * rise)
			_mound.position.y = -0.12 * (1.0 - rise) - 0.28 * sink
			_mound.transparency = sink
		_mound_glow(2.2 * smoothstep(0.7, 1.0, t) * (1.0 - sink), false)
	if not _death_dust_done and t >= 0.5 and _dust and _dust.is_inside_tree():
		_death_dust_done = true
		_dust.process_material = _ppm_bg(&"collapse")
		_dust.global_position = global_position + global_transform.basis * Vector3(0, 0.3, 0.3)
		_dust.restart()
	if not _death_soul_done and t >= 0.72 and _soul and _soul.is_inside_tree():
		_death_soul_done = true
		_soul.process_material = _ppm_soul()
		_soul.global_position = global_position + global_transform.basis * Vector3(0, 0.5, 0.3)
		_soul.restart()
	if _shadow:
		_shadow.transparency = smoothstep(1.2, BG_DEATH_LEN, t)
	if t >= BG_DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _mound_glow(v: float, force: bool) -> void:
	if _mound and (force or absf(v - _mound_glow_written) > 0.01):
		_mound_glow_written = v
		_mound.set_instance_shader_parameter(&"glow_boost", v)


# ================================================================ per frame extras

## Replaces the warden's (no slam ring / maul): hit knock, level-up (both arms keep the slab), footfall dust, glows.
func _extra_process(_dt: float) -> void:
	if not _dead:
		if _hit_t < HIT_LEN:
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_HEAD, Vector3(-10.0 * DEG * k, 0, 7.0 * DEG * k))
			rot(P_CHEST, Vector3(-5.0 * DEG * k, 0, 0))
		if _level_t < LEVEL_LEN:
			rot(P_ARM_L, Vector3(-40.0 * DEG * clampf(sin(PI * clampf(_level_t / 0.3, 0.0, 1.0)) * 1.5, 0.0, 1.0), 0, 0))
		if _walk_w > 0.5 and _tier == 0:
			var s: float = absf(sin(TAU * _walk_p))
			if s >= 0.96 and _last_step < 0.96 and _dust and _dust.is_inside_tree() and _action == &"":
				var foot: Node3D = _piv[P_LEG_R] if sin(TAU * _walk_p) > 0.0 else _piv[P_LEG_L]
				if foot:
					var fp := foot.global_position
					_dust.process_material = _ppm_bg(&"step")
					_dust.global_position = Vector3(fp.x, global_position.y + 0.05, fp.z)
					_dust.restart()
			_last_step = s
	_write_own_glows(false)


## Core: pulse from the material, charges on the heave, flares at death. Slab rune: glows brighter on the heave, lights
## up again when a new stone is torn from the ground.
func _write_own_glows(force: bool) -> void:
	var base := glow_level()
	var core := base
	var rune := base
	if _dead:
		core = base * _death_glow
		rune = core
	elif _action == &"attack":
		core = base * (1.0 + 1.4 * _trk(_action_t, CORE_K))
		rune = base * _trk(_action_t, RUNE_K)
	if _core and (force or absf(core - _core_written) > 0.01):
		_core_written = core
		_core.set_instance_shader_parameter(&"glow_boost", core)
	if _stone and (force or absf(rune - _rune_written) > 0.01):
		_rune_written = rune
		_stone.set_instance_shader_parameter(&"glow_boost", rune)


# ================================================================ particles (process materials shared per process)

static func _ppm_bg(kind: StringName) -> ParticleProcessMaterial:
	if _bfx.has(kind):
		return _bfx[kind]
	var pm := ParticleProcessMaterial.new()
	match kind:
		&"step":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = 0.20
			pm.emission_ring_inner_radius = 0.10
			pm.emission_ring_height = 0.02
			pm.direction = Vector3.UP
			pm.spread = 30.0
			pm.initial_velocity_min = 0.12
			pm.initial_velocity_max = 0.30
			pm.radial_velocity_min = 0.5
			pm.radial_velocity_max = 0.9
			pm.damping_min = 2.0
			pm.damping_max = 3.0
			pm.gravity = Vector3.ZERO
			pm.scale_min = 0.6
			pm.scale_max = 0.9
			pm.scale_curve = _curve([Vector2(0, 0.6), Vector2(1, 1.2)])
			pm.color_ramp = _fade_ramp(Color(BG_DUST.r, BG_DUST.g, BG_DUST.b, 0.5))
		&"scoop":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = 0.30
			pm.emission_ring_inner_radius = 0.12
			pm.emission_ring_height = 0.04
			pm.direction = Vector3.UP
			pm.spread = 25.0
			pm.initial_velocity_min = 0.4
			pm.initial_velocity_max = 1.0
			pm.radial_velocity_min = 1.0
			pm.radial_velocity_max = 1.8
			pm.damping_min = 2.5
			pm.damping_max = 3.5
			pm.gravity = Vector3(0, -0.5, 0)
			pm.scale_min = 0.8
			pm.scale_max = 1.3
			pm.scale_curve = _curve([Vector2(0, 0.5), Vector2(0.35, 1.0), Vector2(1, 1.25)])
			pm.color_ramp = _fade_ramp(Color(BG_DUST.r, BG_DUST.g, BG_DUST.b, 0.75))
		&"collapse":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			pm.emission_box_extents = Vector3(0.55, 0.30, 0.45)
			pm.direction = Vector3.UP
			pm.spread = 80.0
			pm.initial_velocity_min = 0.4
			pm.initial_velocity_max = 1.1
			pm.radial_velocity_min = 0.6
			pm.radial_velocity_max = 1.3
			pm.damping_min = 1.0
			pm.damping_max = 2.0
			pm.gravity = Vector3(0, 0.1, 0)
			pm.scale_min = 1.0
			pm.scale_max = 1.6
			pm.scale_curve = _curve([Vector2(0, 0.5), Vector2(0.4, 1.0), Vector2(1, 1.3)])
			pm.color_ramp = _fade_ramp(Color(BG_DUST.r, BG_DUST.g, BG_DUST.b, 0.8))
		_:   # sparks: violet shards burst off the slab as it leaves the fists
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 0.30
			pm.direction = Vector3(0, 0.6, 1.0)
			pm.spread = 55.0
			pm.initial_velocity_min = 1.2
			pm.initial_velocity_max = 2.6
			pm.damping_min = 1.0
			pm.damping_max = 2.0
			pm.gravity = Vector3(0, -2.0, 0)
			pm.scale_curve = _curve([Vector2(0, 1.0), Vector2(1, 0.15)])
	_bfx[kind] = pm
	return pm
