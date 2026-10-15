class_name NightmareKnightModel
extends MountModel
## Nightmare Knight, Shadow's tier-3 titan (cavalry-mounts.md 5 / 10 row 13.V15; task 13.V15). One scene = the knight
## AND his horse: the horse is a MountModel (merge, gait, gallop, charge, fidget, flash, glow, tiers), the knight sits
## on the kit's rider pivots (Root/Chest > Head, ArmL, ArmR) that this script glues to the horse's Seat every frame
## (bob, pitch, roll), so it does not need CharacterModel.set_seated (13.V1b).
## Look: a huge gaunt black nightmare horse (withers 2.15 m, 4 m long) with ribs showing, burning violet hooves, a
## mane, forelock and tail of violet-tipped smoke, glowing eyes under a spiked black chanfron with swept horns, a
## spiked peytral, and a ragged team caparison. On it a tall knight in jagged black plate (helmet top 3.55 m) with a
## flame crest of violet fire (tips at ~4.25 m), huge spiked pauldrons (the left one with a tall guard fin = the
## asymmetric element), a team cape and tabard, a black kite shield with a violet eye, and a 5 m lance with a
## jagged obsidian head (glowing fuller) and a team pennon. The lance is carried high (55 deg: the tallest line of the
## silhouette, ~5.6 m) and comes down level at the gallop, on attacks and on the charge.
## Hooks (all has_method-guarded by callers, safe before _ready): the kit's set_team_color, set_moving, play_attack
## (= lance strike, strike frame 0.12 s), play_hit, play_death + death_finished (1.7 s: the horse falls, the rider
## slumps, both dissolve into violet smoke), play_cast, play_level_up, set_veterancy, set_status, revive; MountModel's
## play_charge (lance level, lunge, strike 0.10 s, glow flare), seat_transform, gait_phase, gallop_blend, is_galloping,
## play_fidget, authored_mesh_count; plus set_gallop_smoke(on) / is_gallop_smoke() (the smoke trail: gameplay turns
## it on with the "at the gallop" armor, else it follows the gallop by itself), get_lance_tip() -> Vector3 (world),
## signal charge_struck(at: Vector3) (the charge strike, lance tip in world space, for the 13.V19 impact VFX).
## Budget (section 10 titan): 14 authored meshes incl. the blob (~17k vertices), 14 geometry draw instances + 2 particle systems
## (smoke trail, mane wisps; both stopped beyond 45 m) = 16 <= 20, 0 lights, 4 own materials + 1 own shader.

signal charge_struck(at: Vector3)

const OWN := "res://art/units/titans/nightmare_knight/materials/"
const SMOKE_PARTICLE := "res://art/units/shadow/materials/shadow_smoke.tres"
const BLOB_TINT := Color(0.07, 0.02, 0.12, 0.55)
const DISSOLVE := Vector3(0.62, 0.22, 1.0)
const WHITE3 := Vector3(1.0, 1.0, 1.0)

## Horse barrel (body) of revolution along z, centred on BC, vertical squash SY. Profile [z offset, radius].
const BC := Vector3(0, 1.62, -0.05)
const SY := 1.22
const BARREL_Z: Array[float] = [-1.08, -1.02, -0.88, -0.62, -0.32, 0.0, 0.34, 0.66, 0.92, 1.10]
const BARREL_R: Array[float] = [0.0, 0.24, 0.37, 0.41, 0.35, 0.36, 0.41, 0.44, 0.36, 0.0]
## Neck centre line (model space) and radii.
const NECK_P: Array[Vector3] = [Vector3(0, 1.78, 0.66), Vector3(0, 2.10, 0.96), Vector3(0, 2.40, 1.20),
	Vector3(0, 2.62, 1.40)]
const NECK_R: Array[float] = [0.33, 0.26, 0.21, 0.19]
## Skull axis from SK_B (poll) to SK_F (muzzle); lathe profile [s, radius], lateral squash SK_X.
const SK_B := Vector3(0, 2.70, 1.38)
const SK_F := Vector3(0, 2.02, 2.02)
const SK_S: Array[float] = [-0.02, 0.0, 0.12, 0.30, 0.50, 0.70, 0.86, 0.95, 0.98]
const SK_R: Array[float] = [0.0, 0.24, 0.27, 0.25, 0.20, 0.165, 0.155, 0.13, 0.0]
const SK_X := 0.7
## Rider: hip point (= Seat = Chest pivot), lance grip (right gauntlet), lance length ahead of the grip.
const SEAT := Vector3(0, 2.14, -0.15)
const GRIP := Vector3(0.50, 2.40, 0.24)
const LANCE_LEN := 3.95
## Lance pitch (deg, Node3D rotation.x; negative = tip up): carried high, couched at the gallop.
const LANCE_CARRY := -55.0
const LANCE_COUCH := -5.0
const NK_DEATH_LEN := 1.7
enum { SMOKE_AUTO, SMOKE_ON, SMOKE_OFF }

## Rider tracks during play_charge (0.85 s, strike 0.10): lance weight, thrust (m), forward lean (deg).
static var CHR_W := PackedFloat32Array([0.0, 0.0, 0, 0.05, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])
static var CHR_PUSH := PackedFloat32Array([0.0, 0.0, 0, 0.05, -0.14, 1, 0.10, 0.50, 2, 0.35, 0.30, 0, 0.85, 0.0, 0])
static var CHR_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.06, 16.0, 1, 0.14, 22.0, 0, 0.45, 8.0, 0, 0.85, 0.0, 0])

static var _lance_mesh: ArrayMesh
static var _fx: Dictionary = {}

var _lance: MeshInstance3D
var _trail: GPUParticles3D
var _mane_fx: GPUParticles3D
var _smoke_mode: int = SMOKE_AUTO
var _lance_pitch: float = 999.0
var _lance_rel: float = LANCE_CARRY
# this frame's rider layers (set by the attack / charge / death poses, used and cleared in _mount_process)
var _ov_w: float = 0.0
var _ov_pitch: float = 0.0
var _push: float = 0.0
var _lean: float = 0.0
var _twist: float = 0.0
# dissolve (death)
var _geo_all: Array[GeometryInstance3D] = []
var _fade_written: float = 0.0
var _dflash_written: float = 0.0


# ================================================================ build

func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	add_sculpt(body, _body_sculpt)
	add_sculpt($Root/Mount/Neck, _neck_sculpt)
	add_sculpt($Root/Mount/Head, _head_sculpt)
	for leg: Node3D in [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	add_sculpt($Root/Mount/Tail, _tail_sculpt)
	add_sculpt($Root/Chest, _torso_sculpt)
	add_sculpt($Root/Chest/Head, _helm_sculpt)
	add_sculpt($Root/Chest/ArmL, _arm_l_sculpt)
	add_sculpt($Root/Chest/ArmR, _arm_r_sculpt)
	if _lance_mesh == null:
		_lance_mesh = _build_lance()
	_lance = part($Root/Chest/ArmR, _lance_mesh, null, GRIP, Vector3(LANCE_CARRY, 0, 0), Vector3.ONE, true, "Lance")
	_trail = _make_trail()
	$Fx.add_child(_trail)
	_mane_fx = _make_mane()
	$Root/Mount/Neck.add_child(_mane_fx)
	ensure_shadow_blob(0.8, BLOB_TINT)
	_shadow.scale = Vector3(2.7, 1.0, 5.2)
	_shadow.position = Vector3(0, 0.02, 0.15)


static func m(nm: String) -> Material:
	if nm.begins_with("nk_"):
		return material_at(OWN + nm + ".tres")
	return palette(StringName(nm))


# ---------------------------------------------------------------- mesh helpers (static, cached)

## A flame / smoke tongue along +Y (root at the origin, height h), teardrop section of radius r squashed to `flat`
## on X, bending toward -Z by `bend` at the tip. UV.y = height fraction, UV.x = seed (nk_flame.gdshader contract).
static func flame_mesh(r: float, h: float, bend: float, flat: float, seed: int, sides: int = 6) -> Mesh:
	var key := "nkf_%.3f_%.3f_%.3f_%.2f_%d_%d" % [r, h, bend, flat, seed, sides]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 6
	var pts: Array = []
	var cs: Array[Vector3] = []
	for i: int in rings + 1:
		var v := float(i) / float(rings)
		var rad: float = r * sin(PI * (0.14 + 0.86 * v)) if i < rings else 0.0
		var c := Vector3(0, h * v, -bend * v * v)
		cs.append(c)
		var ring := PackedVector3Array()
		for j: int in sides:
			var a := TAU * float(j) / float(sides) + 0.4 * float(seed)
			ring.append(c + Vector3(sin(a) * flat, 0.0, cos(a)) * rad)
		pts.append(ring)
	var u0: float = (float(seed % 4) + 0.5) / 4.0
	for i: int in rings:
		var v0 := float(i) / float(rings)
		var v1 := float(i + 1) / float(rings)
		var r0: PackedVector3Array = pts[i]
		var r1: PackedVector3Array = pts[i + 1]
		for j: int in sides:
			var k := (j + 1) % sides
			var out := ((r0[j] + r0[k]) * 0.5 - cs[i]).normalized()
			_emit_uv(st, r0[j], r0[k], r1[k], Vector2(u0, v0), Vector2(u0, v0), Vector2(u0, v1), out)
			_emit_uv(st, r0[j], r1[k], r1[j], Vector2(u0, v0), Vector2(u0, v1), Vector2(u0, v1), out)
	st.index()
	return _cached(key, st.commit())


static func _emit_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2,
		nrm: Vector3) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	if fn.dot(nrm) > 0.0:
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
	st.set_normal(nrm)
	st.set_uv(ua)
	st.add_vertex(a)
	st.set_normal(nrm)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_normal(nrm)
	st.set_uv(uc)
	st.add_vertex(c)


## A flat plate extruded along X from a 2D outline (u -> Z, v -> Y), thickness `thick`; the outline must be
## star-shaped from its centroid (shield, fins, pennon).
static func slab_mesh(key: String, outline: PackedVector2Array, thick: float) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector2.ZERO
	for p: Vector2 in outline:
		c += p
	c /= float(outline.size())
	var h := thick * 0.5
	var n := outline.size()
	for i: int in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		_emit(st, Vector3(h, c.y, c.x), Vector3(h, a.y, a.x), Vector3(h, b.y, b.x), Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT)
		_emit(st, Vector3(-h, c.y, c.x), Vector3(-h, b.y, b.x), Vector3(-h, a.y, a.x), Vector3.LEFT, Vector3.LEFT, Vector3.LEFT)
		var d := b - a
		var n2 := Vector2(d.y, -d.x).normalized()
		if n2.dot((a + b) * 0.5 - c) < 0.0:
			n2 = -n2
		var sn := Vector3(0, n2.y, n2.x)
		_emit(st, Vector3(h, a.y, a.x), Vector3(-h, a.y, a.x), Vector3(-h, b.y, b.x), sn, sn, sn)
		_emit(st, Vector3(h, a.y, a.x), Vector3(-h, b.y, b.x), Vector3(h, b.y, b.x), sn, sn, sn)
	st.index()
	return _cached(key, st.commit())


## A flame tongue rooted at `base` rising along `dir`, its tip bending toward `bend_dir`.
static func _flame(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, bend_dir: Vector3, r: float, h: float,
		bend: float, flat: float, seed: int) -> void:
	sculpt_add(s, flame_mesh(r, h, bend, flat, seed), frame(base, dir, -bend_dir), mat)


## A cone spike from `base` along `dir`.
static func _spike(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, length: float, r: float, seg: int = 6) -> void:
	var d := dir.normalized()
	sculpt_add(s, cyl(0.0, r, length, seg), Transform3D(Basis(Quaternion(Vector3.UP, d)), base + d * length * 0.5), mat)


static func _tube(s: Dictionary, mat: Material, key: String, pts: Array, radii: Array, seg: int = 8,
		caps: bool = true, flat: float = 1.0) -> void:
	sculpt_add(s, tube_mesh(key, PackedVector3Array(pts), PackedFloat32Array(radii), seg, caps, flat), Transform3D.IDENTITY, mat)


static func _barrel_r(zl: float) -> float:
	if zl <= BARREL_Z[0] or zl >= BARREL_Z[BARREL_Z.size() - 1]:
		return 0.0
	for i: int in range(1, BARREL_Z.size()):
		if zl < BARREL_Z[i]:
			return lerpf(BARREL_R[i - 1], BARREL_R[i], (zl - BARREL_Z[i - 1]) / (BARREL_Z[i] - BARREL_Z[i - 1]))
	return 0.0


## Point on the neck centre line at t (0-1) and its radius.
static func _neck_at(t: float) -> Vector4:
	var f := clampf(t, 0.0, 1.0) * 3.0
	var i := mini(int(f), 2)
	var u := f - float(i)
	var p := NECK_P[i].lerp(NECK_P[i + 1], u)
	return Vector4(p.x, p.y, p.z, lerpf(NECK_R[i], NECK_R[i + 1], u))


# ================================================================ horse

func _body_sculpt(s: Dictionary) -> void:
	var hide := m("nk_hide")
	var plate := m("nk_plate")
	var silver := m("shadow_silver")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var leather := m("shadow_leather")
	var glow := m("shadow_glow_mid")
	var at := Transform3D(Basis.IDENTITY, BC)
	# ---- mass: a gaunt barrel (deep chest, tucked waist), withers, rump, breast
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	sculpt_add(s, lathe_mesh("nk_barrel_v1", prof, 14), Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis.from_scale(Vector3(1, 1, SY)), BC), hide)
	sculpt_put(s, sphere(0.40, 12, 6), hide, Vector3(0, 1.80, 0.52), Vector3.ZERO, Vector3(1.0, 1.05, 1.1))
	sculpt_put(s, sphere(0.40, 12, 6), hide, Vector3(0, 1.84, -0.76), Vector3.ZERO, Vector3(1.0, 0.68, 1.1))
	sculpt_put(s, sphere(0.30, 10, 5), hide, Vector3(0, 1.46, 0.84), Vector3.ZERO, Vector3(1.15, 1.2, 0.9))
	# ---- ribs: raised bands on the lower flanks in front of the caparison (the gaunt read up close)
	for i: int in 4:
		var zl: float = 0.10 + 0.13 * float(i)
		var r := _barrel_r(zl) + 0.012
		for sx: float in [-1.0, 1.0]:
			sculpt_add(s, shell_mesh("nk_rib_%d_%s" % [i, sx], r, r * SY, minf(66.0 * sx, 140.0 * sx),
				maxf(66.0 * sx, 140.0 * sx), zl - 0.028, zl + 0.028, 0.04, 5, 1, 1.0, 0.0), at, hide)
	# ---- spiked peytral (chest plate) with a silver rim and three forward spikes
	sculpt_add(s, shell_mesh("nk_peytral_v1", 0.47, 0.47 * SY, 62.0, 298.0, 0.56, 0.98, 0.035, 12, 2, 0.70, 0.05), at, plate)
	sculpt_add(s, shell_mesh("nk_peytral_rim_v1", 0.482, 0.482 * SY, 62.0, 298.0, 0.54, 0.60, 0.045, 12, 1, 1.0), at, silver)
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, shell_mesh("nk_peytral_edge_%s" % sx, 0.48, 0.48 * SY, minf(60.0 * sx, 72.0 * sx),
			maxf(60.0 * sx, 72.0 * sx), 0.56, 0.98, 0.045, 1, 2, 0.70, 0.05), at, silver)
	for i: int in 3:
		var x: float = (float(i) - 1.0) * 0.22
		var b := Vector3(x, 1.40 + absf(x) * 0.3, 0.98 - absf(x) * 0.25)
		_spike(s, plate, b, Vector3(x * 0.8, 0.15, 1.0), 0.28 - absf(x) * 0.25, 0.065)
	# ---- ragged team caparison over the back and rump, dark hems, an eye sigil on each flank
	sculpt_add(s, shell_mesh("nk_capar_v1", 0.44, 0.44 * SY, -130.0, 130.0, -0.95, -0.02, 0.03, 16, 3, 1.0, 0.03), at, cloth)
	sculpt_add(s, shell_mesh("nk_capar_back_v1", 0.452, 0.452 * SY, -132.0, 132.0, -0.97, -0.91, 0.04, 16, 1), at, cdark)
	var hem_y: float = BC.y + 0.44 * SY * cos(deg_to_rad(130.0))
	for sx: float in [-1.0, 1.0]:
		var a0: float = 48.0 if sx > 0.0 else -132.0
		sculpt_fringe(s, cdark, fringe_mesh("nk_capar_hem_%s" % sx, 0.34, 0.47, 0.39, 0.51, 0.10, a0, a0 + 84.0, 7, 0.22,
			0.03, 0.85), Vector3(0, hem_y + 0.03, BC.z - 0.485))
		var zc: float = -0.52
		var r := 0.458
		var an := deg_to_rad(96.0 * sx)
		var nn := Vector3(sin(an) / r, cos(an) / (r * SY), 0.0).normalized()
		var ep := BC + Vector3(r * sin(an), r * SY * cos(an), zc - BC.z) + nn * 0.02
		var eb := frame(ep, Vector3.UP, nn).basis
		sculpt_add(s, box(Vector3(0.34, 0.34, 0.02)), Transform3D(eb * Basis(Vector3.BACK, PI * 0.25), ep), cdark)
		sculpt_add(s, box(Vector3(0.30, 0.09, 0.03)), Transform3D(eb, ep + nn * 0.012), silver)
		sculpt_add(s, sphere(0.05, 8, 4), Transform3D(eb.scaled_local(Vector3(1.0, 1.0, 0.5)), ep + nn * 0.03), glow)
	# ---- war saddle: seat, tall cantle, pommel plate, stirrup leathers and stirrups
	sculpt_put(s, box(Vector3(0.46, 0.08, 0.56)), leather, Vector3(0, 2.08, -0.16), Vector3(-2, 0, 0))
	sculpt_add(s, shell_mesh("nk_cantle_v1", 0.25, 0.20, -82.0, 82.0, -0.04, 0.04, 0.07, 6, 1),
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-12.0)), Vector3(0, 2.13, -0.46)), plate)
	sculpt_put(s, box(Vector3(0.30, 0.20, 0.06)), plate, Vector3(0, 2.20, 0.15), Vector3(18, 0, 0))
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, box(Vector3(0.04, 0.62, 0.06)), leather, Vector3(0.47 * sx, 1.74, 0.02), Vector3(0, 0, -6.0 * sx))
		sculpt_put(s, torus(0.05, 0.10, 10), silver, Vector3(0.52 * sx, 1.36, 0.08), Vector3(0, 0, 90))
	# ---- the knight's legs (glued to the horse: they belong to the body merge), armoured
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.20 * sx, 2.18, -0.12)
		var knee := Vector3(0.47 * sx, 1.92, 0.22)
		var ankle := Vector3(0.50 * sx, 1.44, 0.12)
		_tube(s, plate, "nk_thigh_%s" % sx, [hip, hip.lerp(knee, 0.5) + Vector3(0.03 * sx, 0.02, 0), knee], [0.15, 0.14, 0.12])
		_tube(s, plate, "nk_shin_%s" % sx, [knee, ankle], [0.115, 0.095])
		sculpt_put(s, sphere(0.13, 10, 5), silver, knee + Vector3(0, 0.0, 0.03), Vector3.ZERO, Vector3(1.0, 1.0, 0.9))
		_spike(s, plate, knee + Vector3(0.02 * sx, 0.02, 0.10), Vector3(0.2 * sx, 0.1, 1.0), 0.22, 0.06)
		_tube(s, plate, "nk_sabaton_%s" % sx, [ankle + Vector3(0, 0.0, -0.08), ankle + Vector3(0, -0.06, 0.12),
			ankle + Vector3(0, -0.08, 0.32)], [0.10, 0.085, 0.0])
	# ---- a ridge of bone-black spikes over the croup (poking through the caparison)
	for i: int in 3:
		var z: float = -0.62 - 0.17 * float(i)
		_spike(s, plate, Vector3(0, 2.12, z), Vector3(0, 1.0, -0.7), 0.22 - 0.03 * float(i), 0.065)


func _neck_sculpt(s: Dictionary) -> void:
	var hide := m("nk_hide")
	var plate := m("nk_plate")
	var silver := m("shadow_silver")
	var smoke := m("nk_smoke")
	_tube(s, hide, "nk_neck_v1", NECK_P, NECK_R, 10, false)
	# an armoured crinet: three plates along the top of the neck, silver edged
	var nd := (NECK_P[3] - NECK_P[0]).normalized()
	var up := Vector3(0, nd.z, -nd.y)
	for i: int in 3:
		var q := _neck_at(0.28 + 0.24 * float(i))
		var c := Vector3(q.x, q.y, q.z)
		var fb := Basis(Vector3.RIGHT, up, nd)    # shell z along the neck, shell y (angle 0) toward the crest
		sculpt_add(s, shell_mesh("nk_crinet_%d" % i, q.w + 0.02, q.w + 0.02, -70.0, 70.0, -0.10, 0.10, 0.03, 6, 1, 0.9),
			Transform3D(fb, c), plate)
		sculpt_add(s, shell_mesh("nk_crinet_rim_%d" % i, q.w + 0.035, q.w + 0.035, -72.0, 72.0, 0.07, 0.11, 0.035, 6, 1),
			Transform3D(fb, c), silver)
	# the smoke mane: violet-tipped smoke tongues streaming up and back along the crest
	for i: int in 10:
		var t: float = 0.06 + 0.1 * float(i)
		var q := _neck_at(t)
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var root := Vector3(0.05 * sx, q.y, q.z) + up * (q.w * 0.92)
		var dir := (up * 0.75 + Vector3(0.18 * sx, 0.35, -0.55)).normalized()
		_flame(s, smoke, root, dir, Vector3(0, -0.3, -1.0), 0.15, 0.80 - 0.28 * t, 0.24, 0.55, i)


func _head_sculpt(s: Dictionary) -> void:
	var hide := m("nk_hide")
	var plate := m("nk_plate")
	var silver := m("shadow_silver")
	var eye_glow := m("shadow_glow_hero")
	var glow := m("shadow_glow")
	var dark := m("unit_eye_dark")
	var smoke := m("nk_smoke")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var sf := frame(SK_B, sd, Vector3.UP)
	# ---- a long lean skull, heavy jaw, dark mouth line, glowing nostrils
	var prof := PackedVector2Array()
	for i: int in SK_S.size():
		prof.append(Vector2(SK_R[i], SK_S[i]))
	sculpt_add(s, lathe_mesh("nk_skull_v1", prof, 12), Transform3D(Basis(sf.basis.x * SK_X, sf.basis.y, sf.basis.z), SK_B), hide)
	var jaw := SK_B + sd * 0.60 - up * 0.13
	sculpt_add(s, sphere(0.2, 10, 5), Transform3D(Basis(sf.basis.x * 0.72, sf.basis.y * 1.7, sf.basis.z * 0.6), jaw), hide)
	sculpt_add(s, box(Vector3(0.20, 0.34, 0.03)), Transform3D(sf.basis, SK_B + sd * 0.78 - up * 0.06), dark)
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, sphere(0.04, 6, 3), glow, SK_B + sd * 0.93 + up * 0.03 + Vector3(0.055 * sx, 0, 0))
		# eyes: violet slits under a plate brow
		var eye := SK_B + sd * 0.27 + up * 0.09 + Vector3(0.165 * sx, 0, 0)
		var eb := Basis(Vector3.UP, 0.35 * sx) * Basis(Vector3.BACK, -0.3 * sx)
		sculpt_add(s, box(Vector3(0.07, 0.055, 0.15)), Transform3D(eb * Basis(Vector3.RIGHT, -0.7), eye), eye_glow)
		# ears laid back
		var ear := SK_B + up * 0.20 + Vector3(0.10 * sx, 0, -0.04)
		var ed := Vector3(0.35 * sx, 0.8, -0.6).normalized()
		sculpt_add(s, cyl(0.0, 0.07, 0.24, 6), Transform3D(Basis(Quaternion(Vector3.UP, ed)).scaled_local(Vector3(1.0, 1.0, 0.5)),
			ear + ed * 0.11), hide)
	# ---- spiked chanfron: a black face plate with a silver rim and brow, swept horns, a forehead spike
	var hb := Basis(-sf.basis.x, sf.basis.z, sf.basis.y)
	var at := Transform3D(hb, SK_B)
	sculpt_add(s, shell_mesh("nk_chanfron_v1", 0.20, 0.29, -64.0, 64.0, 0.04, 0.80, 0.03, 8, 3, 0.58, 0.04), at, plate)
	sculpt_add(s, shell_mesh("nk_chanfron_rim_v1", 0.205, 0.295, -66.0, 66.0, 0.02, 0.10, 0.04, 8, 1), at, silver)
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, shell_mesh("nk_chanfron_edge_%s" % sx, 0.205, 0.295, minf(58.0 * sx, 68.0 * sx), maxf(58.0 * sx, 68.0 * sx),
			0.04, 0.80, 0.04, 1, 3, 0.58, 0.04), at, silver)
		sculpt_put(s, sphere(0.08, 8, 4), plate, SK_B + sd * 0.25 + up * 0.17 + Vector3(0.13 * sx, 0, 0), Vector3.ZERO,
			Vector3(1.0, 0.5, 1.4))
		var hbase := SK_B + sd * 0.10 + up * 0.22 + Vector3(0.10 * sx, 0, 0)
		_tube(s, plate, "nk_horn_%s" % sx, [hbase, hbase + Vector3(0.07 * sx, 0.16, -0.10), hbase + Vector3(0.13 * sx, 0.30, -0.30),
			hbase + Vector3(0.12 * sx, 0.36, -0.54)], [0.07, 0.052, 0.03, 0.0], 6)
	_spike(s, silver, SK_B + sd * 0.42 + up * 0.26, (up + sd * 0.8).normalized(), 0.20, 0.05)
	# ---- smoke forelock between the horns
	for i: int in 3:
		var x: float = (float(i) - 1.0) * 0.06
		_flame(s, smoke, SK_B + up * 0.22 + sd * 0.02 + Vector3(x, 0, 0), (up * 0.6 + Vector3(x * 2.0, 0.6, -0.6)).normalized(),
			Vector3(0, 0, -1), 0.09, 0.36 - absf(x) * 1.5, 0.12, 0.5, 11 + i)


func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var hide := m("nk_hide")
	var plate := m("nk_plate")
	var flame := m("nk_flame")
	var smoke := m("nk_smoke")
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	var sfx := "%s_%s" % [x, z]
	var hoof: Vector3
	var fet: Vector3
	if front:
		# forearm, bony knee, thin cannon, fetlock, pastern
		_tube(s, hide, "nk_forearm_" + sfx, [Vector3(x, 1.50, z), Vector3(x, 1.10, z + 0.03), Vector3(x, 0.80, z + 0.04)],
			[0.17, 0.13, 0.095], 8, false)
		sculpt_put(s, sphere(0.105, 8, 4), hide, Vector3(x, 0.78, z + 0.05))
		fet = Vector3(x, 0.30, z + 0.05)
		_tube(s, hide, "nk_fcannon_" + sfx, [Vector3(x, 0.78, z + 0.05), fet], [0.075, 0.07], 8, false)
		hoof = Vector3(x, 0.07, z + 0.12)
	else:
		# gaskin, stifle, hock, cannon
		_tube(s, hide, "nk_gaskin_" + sfx, [Vector3(x, 1.55, z + 0.02), Vector3(x, 1.15, z + 0.08), Vector3(x, 0.82, z - 0.20)],
			[0.19, 0.14, 0.09], 8, false)
		sculpt_put(s, sphere(0.10, 8, 4), hide, Vector3(x, 0.82, z - 0.20))
		_spike(s, plate, Vector3(x, 0.84, z - 0.26), Vector3(0, 0.3, -1.0), 0.14, 0.04)
		fet = Vector3(x, 0.30, z - 0.12)
		_tube(s, hide, "nk_bcannon_" + sfx, [Vector3(x, 0.82, z - 0.20), fet], [0.075, 0.07], 8, false)
		hoof = Vector3(x, 0.07, z - 0.05)
	sculpt_put(s, sphere(0.095, 8, 4), hide, fet)
	_tube(s, hide, "nk_pastern_" + sfx, [fet, hoof + Vector3(0, 0.07, -0.01)], [0.075, 0.08], 6, false)
	sculpt_put(s, cyl(0.10, 0.135, 0.14, 10), plate, hoof)
	# ---- burning hooves: a ring of violet flame tongues licking up around the hoof, a taller one behind
	for k: int in 6:
		var a: float = TAU * float(k) / 6.0 + 0.3
		var base := hoof + Vector3(0.115 * sin(a), 0.04, 0.115 * cos(a))
		var dir := Vector3(0.35 * sin(a), 1.0, 0.35 * cos(a) - 0.2).normalized()
		_flame(s, flame, base, (dir + Vector3(0, 0, -0.25)).normalized(), Vector3(0, 0, -1), 0.065 + 0.01 * float(k % 2),
			0.24 + 0.09 * float((k * 7) % 3), 0.13, 0.6 + 0.2 * float(k % 2), k)
	_flame(s, flame, hoof + Vector3(0, 0.10, -0.09), Vector3(0, 1.0, -0.3).normalized(), Vector3(0, 0, -1), 0.09, 0.44, 0.14,
		0.7, 5)
	# smoke feathering at the fetlock
	for sx: float in [-1.0, 1.0]:
		_flame(s, smoke, fet + Vector3(0.05 * sx, 0.02, -0.04), Vector3(0.4 * sx, -0.5, -1.0).normalized(), Vector3(0, -1, 0),
			0.06, 0.24, 0.06, 0.6, 7)


func _tail_sculpt(s: Dictionary) -> void:
	var hide := m("nk_hide")
	var smoke := m("nk_smoke")
	_tube(s, hide, "nk_tail_v1", [Vector3(0, 2.02, -1.04), Vector3(0, 1.96, -1.18), Vector3(0, 1.84, -1.28)],
		[0.09, 0.07, 0.05], 6)
	for i: int in 6:
		var x: float = (float(i) - 2.5) * 0.10
		var dir := Vector3(x, -0.55, -0.85).normalized()
		_flame(s, smoke, Vector3(x * 0.3, 1.90 + absf(x) * 0.1, -1.20), dir, Vector3(0, -1, 0), 0.13,
			0.95 - absf(x) * 0.9, 0.24, 0.55, 20 + i)


# ================================================================ knight

func _torso_sculpt(s: Dictionary) -> void:
	var plate := m("nk_plate")
	var silver := m("shadow_silver")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var leather := m("shadow_leather")
	# ---- cuirass (flattened front-back), belt, jagged plate faulds over the hips
	var prof := PackedVector2Array([Vector2(0.25, 0.0), Vector2(0.30, 0.14), Vector2(0.36, 0.36), Vector2(0.385, 0.54),
		Vector2(0.33, 0.70), Vector2(0.18, 0.80)])
	sculpt_add(s, lathe_mesh("nk_cuirass_v1", prof, 12), Transform3D(Basis.from_scale(Vector3(1, 1, 0.78)),
		Vector3(0, 2.20, -0.14)), plate)
	sculpt_add(s, cyl(0.275, 0.275, 0.08, 12), Transform3D(Basis.from_scale(Vector3(1, 1, 0.8)), Vector3(0, 2.24, -0.14)), leather)
	sculpt_put(s, box(Vector3(0.12, 0.10, 0.04)), silver, Vector3(0, 2.24, 0.085))
	sculpt_fringe(s, plate, fringe_mesh("nk_faulds_v1", 0.27, 0.22, 0.36, 0.32, 0.12, -150.0, 150.0, 7, 0.11, 0.03, 0.6),
		Vector3(0, 2.25, -0.14))
	# ---- team tabard on the chest (a shell on the cuirass front) with a dark hem and a silver sigil; a front flap
	var tb := Basis(Vector3.RIGHT, -PI * 0.5)       # shell z -> up, shell angle 0 -> back, 180 -> front
	sculpt_add(s, shell_mesh("nk_tabard_v1", 0.285, 0.232, 146.0, 214.0, 0.04, 0.56, 0.02, 6, 3, 1.37, 0.0),
		Transform3D(tb, Vector3(0, 2.20, -0.14)), cloth)
	sculpt_put(s, box(Vector3(0.15, 0.15, 0.03)), silver, Vector3(0, 2.62, 0.172), Vector3(-8, 0, 45))
	sculpt_put(s, box(Vector3(0.07, 0.07, 0.035)), cdark, Vector3(0, 2.62, 0.178), Vector3(-8, 0, 45))
	sculpt_put(s, box(Vector3(0.30, 0.32, 0.025)), cloth, Vector3(0, 2.10, 0.13), Vector3(-28, 0, 0))
	sculpt_put(s, box(Vector3(0.30, 0.06, 0.03)), cdark, Vector3(0, 1.965, 0.20), Vector3(-28, 0, 0))
	# ---- gorget
	sculpt_add(s, cyl(0.16, 0.22, 0.14, 10), Transform3D(Basis.IDENTITY, Vector3(0, 2.98, -0.14)), plate)
	# ---- huge jagged pauldrons: two lames, silver rims, spikes; the left one carries a tall guard fin
	for sx: float in [-1.0, 1.0]:
		var big: bool = sx < 0.0
		var k: float = 1.12 if big else 1.0
		var c := Vector3(0.44 * sx, 2.92, -0.14)
		sculpt_put(s, sphere(0.26, 12, 6), plate, c, Vector3(0, 0, -14.0 * sx), Vector3(1.18, 0.82, 1.12) * k)
		sculpt_put(s, sphere(0.22, 10, 5), plate, c + Vector3(0.09 * sx, -0.15, 0), Vector3(0, 0, -24.0 * sx), Vector3(1.1, 0.55, 1.12) * k)
		sculpt_add(s, torus(0.25 * k, 0.29 * k, 14), Transform3D(Basis(Vector3.BACK, deg_to_rad(-20.0 * sx)).scaled_local(
			Vector3(1.0, 1.0, 0.95)), c + Vector3(0.10 * sx, -0.19, 0)), silver)
		var spikes: Array = [[Vector3(0.02, 0.18, 0.09), Vector3(0.25, 1.0, 0.25), 0.30],
			[Vector3(0.14, 0.14, -0.04), Vector3(0.6, 1.0, -0.1), 0.36],
			[Vector3(0.03, 0.18, -0.17), Vector3(0.25, 1.0, -0.45), 0.28]]
		if big:
			spikes.append([Vector3(0.24, 0.02, 0.10), Vector3(1.0, 0.35, 0.3), 0.26])
		for sp: Array in spikes:
			var o: Vector3 = sp[0]
			var d: Vector3 = sp[1]
			_spike(s, plate, c + Vector3(o.x * sx, o.y, o.z) * k, Vector3(d.x * sx, d.y, d.z), float(sp[2]) * k, 0.075 * k)
	var fin := PackedVector2Array([Vector2(-0.24, 0.0), Vector2(0.20, 0.0), Vector2(0.16, 0.24), Vector2(0.07, 0.30),
		Vector2(0.0, 0.50), Vector2(-0.08, 0.34), Vector2(-0.19, 0.42), Vector2(-0.22, 0.18)])
	var fb := Basis(Vector3.BACK, deg_to_rad(16.0))
	sculpt_add(s, slab_mesh("nk_fin_v1", fin, 0.06), Transform3D(fb, Vector3(-0.62, 3.02, -0.16)), plate)
	var fin_rim := PackedVector2Array()
	for q: Vector2 in fin:
		fin_rim.append(q * 1.08 + Vector2(0, -0.012))
	sculpt_add(s, slab_mesh("nk_fin_rim_v1", fin_rim, 0.035), Transform3D(fb, Vector3(-0.625, 3.02, -0.16)), silver)
	# ---- team cape from the shoulders, sweeping back over the croup
	sculpt_add(s, cape(0.95, 1.35), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(50.0)), Vector3(0, 2.49, -0.83)), m("shadow_cape"))


func _helm_sculpt(s: Dictionary) -> void:
	var plate := m("nk_plate")
	var silver := m("shadow_silver")
	var glow := m("shadow_glow_hero")
	var flame := m("nk_flame")
	# ---- tall great helm, silver band and face ridge, T visor glowing violet
	var prof := PackedVector2Array([Vector2(0.17, 0.0), Vector2(0.215, 0.08), Vector2(0.225, 0.26), Vector2(0.20, 0.38),
		Vector2(0.12, 0.48), Vector2(0.0, 0.53)])
	sculpt_add(s, lathe_mesh("nk_helm_v1", prof, 12), Transform3D(Basis.from_scale(Vector3(1, 1, 1.08)), Vector3(0, 2.99, -0.12)), plate)
	sculpt_add(s, cyl(0.229, 0.229, 0.05, 12, false), Transform3D(Basis.from_scale(Vector3(1, 1, 1.08)), Vector3(0, 3.08, -0.12)), silver)
	sculpt_put(s, box(Vector3(0.36, 0.045, 0.05)), glow, Vector3(0, 3.25, 0.10))
	sculpt_put(s, box(Vector3(0.045, 0.13, 0.05)), glow, Vector3(0, 3.17, 0.108))
	sculpt_put(s, box(Vector3(0.05, 0.16, 0.06)), silver, Vector3(0, 3.37, 0.105), Vector3(-14, 0, 0))
	# crown of jagged spikes around the helm top (none at the front: the visor stays clear)
	for i: int in 7:
		var a: float = deg_to_rad(50.0 + 43.3 * float(i))
		var base := Vector3(0.19 * sin(a), 3.36, -0.12 + 0.20 * cos(a))
		_spike(s, plate, base, Vector3(sin(a) * 0.7, 1.0, cos(a) * 0.7), 0.20 + 0.06 * float(i % 2), 0.055)
	# ---- the violet flame crest: a blade of fire tongues along the helm's top, leaning back (the 40 m read)
	var hs: Array[float] = [0.42, 0.62, 0.78, 0.84, 0.76, 0.62, 0.48, 0.34]
	for i: int in 8:
		var z: float = 0.06 - 0.055 * float(i)
		var dz := absf(z + 0.12)
		var root := Vector3(0, 3.53 - 0.9 * dz * dz - 0.12 * dz, z)
		_flame(s, flame, root, Vector3(0, 1.0, -0.12 - 0.05 * float(i)).normalized(), Vector3(0, 0, -1), 0.14,
			hs[i], 0.18 + 0.03 * float(i), 0.6, i)
	for sx: float in [-1.0, 1.0]:
		_flame(s, flame, Vector3(0.08 * sx, 3.46, -0.10), Vector3(0.45 * sx, 1.0, -0.3).normalized(), Vector3(0, 0, -1), 0.10,
			0.40, 0.14, 0.55, 8)
		_flame(s, flame, Vector3(0.08 * sx, 3.44, -0.26), Vector3(0.45 * sx, 1.0, -0.5).normalized(), Vector3(0, 0, -1), 0.09,
			0.34, 0.14, 0.55, 9)


func _arm_l_sculpt(s: Dictionary) -> void:
	var plate := m("nk_plate")
	var silver := m("shadow_silver")
	var leather := m("shadow_leather")
	var glow := m("shadow_glow_hero")
	var dark := m("unit_eye_dark")
	var sh := Vector3(-0.46, 2.84, -0.13)
	var el := Vector3(-0.52, 2.52, -0.06)
	var hd := Vector3(-0.38, 2.37, 0.26)
	_tube(s, plate, "nk_uarm_l", [sh, el], [0.11, 0.10])
	_tube(s, plate, "nk_farm_l", [el, hd], [0.10, 0.09])
	sculpt_put(s, sphere(0.11, 8, 4), silver, el)
	sculpt_put(s, sphere(0.105, 8, 4), plate, hd + Vector3(0.01, -0.01, 0.03))
	# ---- black kite shield on the forearm (strapped), silver rim, a violet eye sigil and a boss spike
	var outline := PackedVector2Array([Vector2(-0.30, 0.30), Vector2(-0.20, 0.44), Vector2(-0.08, 0.34), Vector2(0.0, 0.46),
		Vector2(0.08, 0.34), Vector2(0.20, 0.44), Vector2(0.30, 0.30), Vector2(0.28, 0.0), Vector2(0.14, -0.34),
		Vector2(0.0, -0.64), Vector2(-0.14, -0.34), Vector2(-0.28, 0.0)])
	var rim := PackedVector2Array()
	for q: Vector2 in outline:
		rim.append(q * 1.07)
	var b := Basis(Vector3.UP, deg_to_rad(200.0))    # slab +X (face) -> outward-left and a little forward
	var c := Vector3(-0.74, 2.40, 0.06)
	var fx := Transform3D(b, c)
	sculpt_add(s, slab_mesh("nk_shield_v1", outline, 0.07), fx, plate)
	sculpt_add(s, slab_mesh("nk_shield_rim_v1", rim, 0.045), fx * Transform3D(Basis.IDENTITY, Vector3(-0.015, 0, 0)), silver)
	sculpt_add(s, box(Vector3(0.03, 0.12, 0.30)), fx * Transform3D(Basis(Vector3.RIGHT, PI * 0.25), Vector3(0.04, 0.10, 0.0)), glow)
	sculpt_add(s, box(Vector3(0.035, 0.18, 0.05)), fx * Transform3D(Basis.IDENTITY, Vector3(0.05, 0.10, 0.0)), dark)
	sculpt_add(s, cyl(0.0, 0.06, 0.18, 6), fx * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(0.11, -0.16, 0.0)), silver)
	sculpt_add(s, box(Vector3(0.20, 0.05, 0.06)), Transform3D(b, c.lerp(el.lerp(hd, 0.5), 0.5)), leather)


func _arm_r_sculpt(s: Dictionary) -> void:
	var plate := m("nk_plate")
	var silver := m("shadow_silver")
	var sh := Vector3(0.46, 2.84, -0.13)
	var el := Vector3(0.54, 2.52, -0.10)
	_tube(s, plate, "nk_uarm_r", [sh, el], [0.11, 0.10])
	_tube(s, plate, "nk_farm_r", [el, GRIP + Vector3(0, 0.0, -0.06)], [0.10, 0.09])
	sculpt_put(s, sphere(0.11, 8, 4), silver, el)
	_spike(s, plate, el + Vector3(0.04, 0.0, -0.08), Vector3(0.3, 0.1, -1.0), 0.18, 0.05)
	sculpt_put(s, sphere(0.11, 8, 4), plate, GRIP + Vector3(0.0, 0.0, -0.01), Vector3.ZERO, Vector3(1.0, 1.05, 1.1))
	sculpt_add(s, cyl(0.13, 0.10, 0.10, 8), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(80.0)), GRIP + Vector3(0, 0.02, -0.12)), silver)


## The lance, in its own frame: grip at the origin, +Z toward the tip (LANCE_LEN), the pennon on the +Y side.
static func _build_lance() -> ArrayMesh:
	var s := sculpt()
	var plate := m("nk_plate")
	var silver := m("shadow_silver")
	var leather := m("shadow_leather")
	var glow := m("shadow_glow")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var z90 := Basis(Vector3.RIGHT, PI * 0.5)       # +Y -> +Z
	sculpt_add(s, tube_mesh("nk_lance_shaft_v1", PackedVector3Array([Vector3(0, 0, -1.0), Vector3(0, 0, 0.2), Vector3(0, 0, 1.5),
		Vector3(0, 0, 3.02)]), PackedFloat32Array([0.058, 0.072, 0.064, 0.052]), 8), Transform3D.IDENTITY, plate)
	sculpt_put(s, sphere(0.09, 8, 4), silver, Vector3(0, 0, -1.03))
	sculpt_add(s, tube_mesh("nk_lance_grip_v1", PackedVector3Array([Vector3(0, 0, -0.20), Vector3(0, 0, 0.14)]),
		PackedFloat32Array([0.08, 0.08]), 8), Transform3D.IDENTITY, leather)
	sculpt_add(s, cyl(0.08, 0.26, 0.34, 12), Transform3D(z90, Vector3(0, 0, 0.34)), plate)
	sculpt_add(s, torus(0.23, 0.28, 14), Transform3D(z90, Vector3(0, 0, 0.18)), silver)
	for z: float in [1.0, 1.9, 2.75]:
		sculpt_add(s, torus(0.05, 0.09, 10), Transform3D(z90, Vector3(0, 0, z)), silver)
	sculpt_add(s, cyl(0.075, 0.105, 0.16, 8), Transform3D(z90, Vector3(0, 0, 3.02)), silver)
	# jagged obsidian head (a vertical blade), a glowing fuller on both faces, two back barbs
	var bp := PackedVector3Array([Vector3(0, 0, 3.05), Vector3(0, 0, 3.30), Vector3(0, 0, 3.62), Vector3(0, 0, LANCE_LEN)])
	sculpt_add(s, tube_mesh("nk_lance_blade_v1", bp, PackedFloat32Array([0.12, 0.17, 0.11, 0.0]), 6, true, 0.32),
		Transform3D.IDENTITY, plate)
	sculpt_add(s, tube_mesh("nk_lance_fuller_v1", PackedVector3Array([Vector3(0, 0, 3.12), Vector3(0, 0, 3.32), Vector3(0, 0, 3.60),
		Vector3(0, 0, 3.86)]), PackedFloat32Array([0.05, 0.09, 0.055, 0.0]), 6, true, 0.75), Transform3D.IDENTITY, glow)
	for sy: float in [-1.0, 1.0]:
		var d := Vector3(0, 0.55 * sy, -0.85).normalized()
		sculpt_add(s, cyl(0.0, 0.05, 0.24, 6), Transform3D(Basis(Quaternion(Vector3.UP, d)), Vector3(0, 0.14 * sy, 3.17) + d * 0.12), plate)
	# team pennon streaming back along the shaft (swallow-tailed)
	var pen := PackedVector2Array([Vector2(2.92, 0.05), Vector2(2.92, 0.34), Vector2(2.55, 0.32), Vector2(2.12, 0.44),
		Vector2(2.34, 0.24), Vector2(2.10, 0.08)])
	sculpt_add(s, slab_mesh("nk_pennon_v1", pen, 0.025), Transform3D.IDENTITY, cloth)
	sculpt_add(s, box(Vector3(0.03, 0.30, 0.06)), Transform3D(Basis.IDENTITY, Vector3(0, 0.20, 2.93)), cdark)
	return sculpt_mesh(s)


# ================================================================ particles (shared resources, built once)

static func _gradient(offsets: PackedFloat32Array, colors: PackedColorArray) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = offsets
	g.colors = colors
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt


static func _quad(size: float) -> QuadMesh:
	var key := "quad%s" % size
	if not _fx.has(key):
		var q := QuadMesh.new()
		q.size = Vector2(size, size)
		q.material = load(SMOKE_PARTICLE)
		_fx[key] = q
	return _fx[key]


## The gallop smoke trail: world-space dark-violet smoke from the legs (the unit runs out of it, a trail stays).
func _make_trail() -> GPUParticles3D:
	if not _fx.has("trail"):
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.42, 0.25, 0.95)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 55.0
		pm.initial_velocity_min = 0.2
		pm.initial_velocity_max = 0.7
		pm.gravity = Vector3(0, 0.45, 0)
		pm.damping_min = 0.4
		pm.damping_max = 0.8
		pm.angle_min = -180.0
		pm.angle_max = 180.0
		pm.color_ramp = _gradient(PackedFloat32Array([0.0, 0.08, 0.35, 1.0]), PackedColorArray([Color(0.50, 0.24, 0.80, 0.0),
			Color(0.42, 0.20, 0.66, 0.62), Color(0.16, 0.10, 0.24, 0.58), Color(0.07, 0.05, 0.11, 0.0)]))
		_fx["trail"] = pm
	var p := GPUParticles3D.new()
	p.name = "SmokeTrail"
	p.amount = 40
	p.lifetime = 1.3
	p.local_coords = false
	p.emitting = false
	p.process_material = _fx["trail"]
	p.draw_pass_1 = _quad(1.0)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-10, -1, -10), Vector3(20, 6, 20))
	p.position = Vector3(0, 0.40, -0.05)
	return p


## Mane wisps: violet smoke peeling off the mane (child of the Neck, world space so it streams back at speed).
func _make_mane() -> GPUParticles3D:
	if not _fx.has("mane"):
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.05, 0.06, 0.32)
		pm.direction = Vector3(0, 1, -0.4)
		pm.spread = 22.0
		pm.initial_velocity_min = 0.25
		pm.initial_velocity_max = 0.5
		pm.gravity = Vector3(0, 0.7, 0)
		pm.angle_min = -180.0
		pm.angle_max = 180.0
		pm.color_ramp = _gradient(PackedFloat32Array([0.0, 0.12, 0.5, 1.0]), PackedColorArray([Color(0.55, 0.25, 0.85, 0.0),
			Color(0.50, 0.22, 0.80, 0.7), Color(0.14, 0.09, 0.20, 0.5), Color(0.06, 0.05, 0.10, 0.0)]))
		_fx["mane"] = pm
	var p := GPUParticles3D.new()
	p.name = "ManeWisps"
	p.amount = 12
	p.lifetime = 0.9
	p.local_coords = false
	p.process_material = _fx["mane"]
	p.draw_pass_1 = _quad(0.55)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-6, -3, -8), Vector3(12, 8, 16))
	# Neck-local: the middle of the mane, box z along the neck crest
	p.position = Vector3(0, 0.62, 0.20)
	p.rotation = Vector3(deg_to_rad(-44.6), 0, 0)
	return p


# ================================================================ hooks

## The smoke trail on / off. Gameplay: on while the "at the gallop" armor modifier is up (TitanAbilities `gallop`),
## off when it drops. Until the first call the model shows it by itself while galloping above gallop_speed.
## Always stopped beyond 45 m.
func set_gallop_smoke(on: bool) -> void:
	_smoke_mode = SMOKE_ON if on else SMOKE_OFF
	if _trail:
		_smoke_tick()


func is_gallop_smoke() -> bool:
	if _smoke_mode == SMOKE_AUTO:
		return not _dead and _gallop_w > 0.6 and _speed >= gallop_speed
	return _smoke_mode == SMOKE_ON


## World position of the lance tip (charge impact VFX, 13.V19).
func get_lance_tip() -> Vector3:
	if _lance and _lance.is_inside_tree():
		return _lance.global_transform * Vector3(0, 0, LANCE_LEN)
	return global_position + Vector3(0, GRIP.y, GRIP.z + LANCE_LEN)


## Current lance pitch in degrees in the model frame (negative = tip up, ~0 = level; the knight's lean is compensated).
func lance_pitch() -> float:
	return _lance_rel


# ================================================================ motion

func _mount_ready() -> void:
	_loop_fx.erase(_trail)     # the trail is driven by the gallop smoke toggle, not by the kit's distance tiers
	_trail.emitting = false
	for i: int in [P_CHEST, P_HEAD, P_ARM_L, P_ARM_R]:
		var mi: MeshInstance3D = _merged_nodes.get(i)
		if mi:
			_mount_geo.append(mi)
			if not _flash_hit_targets.has(mi):
				_flash_hit_targets.append(mi)
	_mount_geo.append(_lance)
	_flash_hit_targets.append(_lance)
	_refresh_team_all()
	_geo_all.clear()
	for gi: GeometryInstance3D in _flash_all_targets + _glow_nodes:
		if gi != _shadow and not _geo_all.has(gi):
			_geo_all.append(gi)
	_lance_pitch = 999.0
	_set_lance(LANCE_CARRY)


## Lance pitch p (deg) in the knight's model frame; chest_deg = the chest's own pitch this frame (compensated).
func _set_lance(p: float, chest_deg: float = 0.0) -> void:
	_lance_rel = p
	var local: float = p - chest_deg
	if absf(local - _lance_pitch) > 0.05:
		_lance_pitch = local
		_lance.rotation = Vector3(deg_to_rad(local), 0.0, 0.0)


## The knight's lance strike (attack_style knight_lance): the lance drops level from the carry, a short draw back, a
## thrust at 0.12 s (release = the melee hit), held, then raised again; the horse lunges with the thrust.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"knight_lance":
		return super(prev, t)
	_ov_w = maxf(_ov_w, _k3(t, 0.0, 0.08, 0.40, 0.75, 1.0, 1.0))
	_ov_pitch = -2.0 + 5.0 * _k3(t, 0.10, 0.14, 0.20, 0.40, 1.0, 1.0)
	_push += _k3(t, 0.0, 0.08, 0.12, 0.60, -0.16, 0.45)
	_twist += _k3(t, 0.0, 0.08, 0.13, 0.60, 12.0, -10.0)
	_lean += _k3(t, 0.0, 0.08, 0.13, 0.60, -4.0, 10.0)
	pos(P_ROOT, Vector3(0, 0, _k3(t, 0.04, 0.12, 0.20, 0.60, 0.20, 0.14)))
	rot(P_MOUNT_HEAD, Vector3(_k3(t, 0.0, 0.08, 0.14, 0.60, -10.0, 12.0) * DEG, 0, 0))
	if prev < 0.12 and t >= 0.12:
		_on_action_event(&"release")
	return t < 0.75


## The charge: MountModel's (head down, lunge, toss) + the knight leans in and drives the lance dead level.
func _pose_charge(t: float) -> float:
	var length := super(t)
	_ov_w = maxf(_ov_w, _mkf(t, CHR_W))
	_ov_pitch = 1.0
	_push += _mkf(t, CHR_PUSH)
	_lean += _mkf(t, CHR_LEAN)
	return length


func _on_mount_event(ev: StringName) -> void:
	if ev == &"charge_hit":
		charge_struck.emit(get_lance_tip())


## Rider on the Seat (bob / pitch / roll), riding idle, gallop lean, hit recoil, the lance angle, the smoke toggle.
func _mount_process(_dt: float) -> void:
	var base_pitch: float = lerpf(LANCE_CARRY, LANCE_COUCH, smoothstep(0.25, 0.9, _gallop_w))
	var ph: float = (_t + _phase_off) * TAU / idle_period
	if _fast:
		# pure idle: the kit writes no offsets this frame, so write the rider pivots directly (only if changed)
		_write_pos(P_CHEST, _rest_pos[P_CHEST])
		_write_rot(P_CHEST, _rest_rot[P_CHEST] + Vector3(1.2 * DEG * sin(ph + 0.8), 0, 0))
		_write_rot(P_HEAD, _rest_rot[P_HEAD] + (Vector3(0, 12.0 * DEG * sin(0.23 * ph + _phase_off * 3.0), 0) if _tier == 0
			else Vector3.ZERO))
		_write_pos(P_ARM_R, _rest_pos[P_ARM_R])
		_write_rot(P_ARM_R, _rest_rot[P_ARM_R])
		_write_rot(P_ARM_L, _rest_rot[P_ARM_L])
		_set_lance(base_pitch + 1.5 * sin(ph))
	elif not _dead:
		# glue the rider's hips to the Seat: the Mount pivot's offset carried to the seat point
		var mr: Vector3 = _off_rot[P_MOUNT]
		var mp: Vector3 = _rest_pos[P_MOUNT] + _off_pos[P_MOUNT]
		var seat_now: Vector3 = mp + Basis.from_euler(mr) * (SEAT - _rest_pos[P_MOUNT])
		pos(P_CHEST, seat_now - SEAT)
		var g: float = _gallop_w * _walk_w
		var idle: float = 1.0 - _walk_w
		var lean: float = 7.0 * g + _lean
		var hk: float = 0.0
		if _hit_t < HIT_LEN:
			hk = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		var chest_x: float = mr.x * 0.45 + (lean - 9.0 * hk) * DEG + idle * 1.2 * DEG * sin(ph + 0.8)
		rot(P_CHEST, Vector3(chest_x, mr.y * 0.5 + _twist * DEG, mr.z * 0.6))
		var look: float = 12.0 * DEG * sin(0.23 * ph + _phase_off * 3.0) * idle if _tier == 0 else 0.0
		rot(P_HEAD, Vector3(-lean * 0.5 * DEG + 6.0 * DEG * hk, look, 0))
		pos(P_ARM_R, Vector3(0, 0, _push))
		rot(P_ARM_L, Vector3(2.5 * DEG * sin(TAU * _gait_p) * _walk_w, 0, 0))
		# the lance keeps its world angle while the knight leans (couched, not tipped into the ground)
		_set_lance(lerpf(base_pitch, _ov_pitch, clampf(_ov_w, 0.0, 1.0)), rad_to_deg(chest_x))
	else:
		_set_lance(lerpf(base_pitch, _ov_pitch, clampf(_ov_w, 0.0, 1.0)))
	_ov_w = 0.0
	_push = 0.0
	_lean = 0.0
	_twist = 0.0
	_smoke_tick()


func _smoke_tick() -> void:
	var want: bool
	if _dead:
		want = _death_t > 0.3 and _death_t < 1.35
	else:
		want = is_gallop_smoke()
	want = want and _tier < 2
	if _trail.emitting != want or _off_fx.paused:
		set_fx_emitting(_trail, want)


## Death (1.7 s, < Unit.DEATH_FALLBACK_TIME 2.0): the horse stumbles and rolls onto its side (MountModel's tracks
## over 1.1 s), the knight slumps and the lance drops, fires gutter at 0.35 s, smoke billows up from 0.3 s, then
## horse and rider flare violet and dissolve (transparency) from 1.0 s; death_finished at 1.7 s.
func _pose_death(dt: float) -> void:
	var prev := _death_t
	_death_t += dt
	var t := _death_t
	var u: float = clampf(t / 1.1, 0.0, 1.0)
	var sd := _fall_side
	var roll: float = _mkf(u, D_ROLL)
	var a: float = sd * 84.0 * DEG * roll
	rot(P_ROOT, Vector3(0, 0, a))
	rot(P_MOUNT, Vector3(_mkf(u, D_PITCH) * DEG, 0, 0))
	var hc: float = _body_c.y
	var y_target: float = lerpf(hc + _mkf(u, D_DROP), _lie_h, clampf(roll, 0.0, 1.0))
	pos(P_ROOT, Vector3(hc * sin(a) * 0.4, y_target - hc * cos(a), 0))
	var lf := _mkf(u, D_LEG_F) * DEG
	var lb := _mkf(u, D_LEG_B) * DEG
	rot(P_LEG_FL, Vector3(lf, 0, 0)); rot(P_LEG_FR, Vector3(lf * 0.8, 0, 0))
	rot(P_LEG_BL, Vector3(lb * 0.9, 0, 0)); rot(P_LEG_BR, Vector3(lb, 0, 0))
	rot(P_MOUNT_HEAD, Vector3(_mkf(u, D_HEAD_X) * DEG, 0, -_mkf(u, D_HEAD_Z) * DEG * sd))
	xrot(X_TAIL, Vector3(-10.0 * DEG * roll, 0, 0))
	# the knight slumps over the neck, the lance tips down
	var sl: float = smoothstep(0.0, 0.45, t)
	rot(P_CHEST, Vector3(34.0 * DEG * sl, 0, -sd * 10.0 * DEG * sl))
	rot(P_HEAD, Vector3(22.0 * DEG * sl, 0, 0))
	rot(P_ARM_R, Vector3(28.0 * DEG * sl, 0, 0))
	rot(P_ARM_L, Vector3(24.0 * DEG * sl, 0, 0))
	_ov_w = 1.0
	_ov_pitch = lerpf(LANCE_CARRY, 30.0, sl)
	if t >= 0.35:
		_glows_dead()
	if prev < 0.64 and t >= 0.64:
		_on_mount_event(&"death_down")
	if t >= 0.9 and (_mane_fx.emitting or _off_fx.paused):
		set_fx_emitting(_mane_fx, false)
	# violet flare then dissolve
	var fl: float = snappedf(0.55 * smoothstep(0.75, 1.15, t) * (1.0 - 0.5 * smoothstep(1.3, 1.7, t)), 0.02)
	if fl != _dflash_written:
		_dflash_written = fl
		for gi: GeometryInstance3D in _flash_all_targets:
			gi.set_instance_shader_parameter(&"hit_flash", fl)
			gi.set_instance_shader_parameter(&"flash_color", DISSOLVE)
	var fade: float = snappedf(smoothstep(1.0, 1.65, t), 0.02)
	if fade != _fade_written:
		_fade_written = fade
		for gi: GeometryInstance3D in _geo_all:
			gi.transparency = fade
	if _shadow:
		_shadow.transparency = clampf((t - 1.1) / 0.5, 0.0, 1.0)
	if t >= NK_DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _mount_revive() -> void:
	_dflash_written = 0.0
	_fade_written = 0.0
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
		gi.set_instance_shader_parameter(&"flash_color", WHITE3)
	for gi: GeometryInstance3D in _geo_all:
		gi.transparency = 0.0
	_ov_w = 0.0
	_lance_pitch = 999.0
	_set_lance(LANCE_CARRY)
	set_fx_emitting(_trail, false)
	set_fx_emitting(_mane_fx, _tier < 2)
