class_name MountModel
extends CharacterModel
## Shared base of every tier-2 cavalry / hero mount (cavalry-mounts.md 10, task 13.V1a). First mount:
## art/units/mounts/rimehorn/. How to build one: docs/handoff/for-tech-artist.md "Step 13 (task 13.V1a): MountModel".
## It IS a CharacterModel (merge into pivots, instance-uniform slots, flash, glow, tiers, fade, statuses unchanged)
## specialised for a riderless quadruped that a rider (CharacterModel.set_seated, 13.V1b) or a cavalry unit sits on.
##
## Scene layout (face = local +Z, feet origin, every pivot unrotated at rest):
##   MyMount (Node3D, script extends MountModel)      <- never animated
##     Root                    feet origin; the death roll turns it
##       Mount                 the BODY pivot (kit name, P_MOUNT): put it at the body centre (it pitches / rolls)
##         Head                kit P_MOUNT_HEAD, at the neck root (the neck mesh goes here when there is no Neck)
##         Neck                optional extra pivot (horses): MountModel animates it and carries Head with it
##         LegFL LegFR LegBL LegBR   kit pivots at the top of each leg (shoulder / hip)
##         Tail                optional extra pivot at the tail root
##         Seat                Node3D marker, no mesh: the rider's hip point (+Z forward, +Y up); follows the body
##     Fx
##     Shadow                  made by ensure_shadow_blob()
## Hooks (all has_method-guarded by callers; calls before _ready are kept): the kit's (set_team_color, set_moving,
## play_attack, play_cast, play_hit, play_death + death_finished, play_level_up, set_veterancy, set_status, revive)
## plus set_barded(on), is_barded(), play_charge(), seat_transform() -> Transform3D, seat_node(), gait_phase(),
## gallop_blend(), is_galloping(), play_fidget(), authored_mesh_count().
## Authoring (in _build_mount): part(), add_sculpt(), add_barding_part(), add_barding_sculpt() + the static mesh
## builders lathe_mesh / tube_mesh / shell_mesh / lock_mesh and sculpt_* (one multi-material mesh = one authored part).

## Extra pivots (not in the kit's fixed list): merged here, animated here.
const X_NECK := 0
const X_TAIL := 1
const EXTRA_PATHS: Array[String] = ["Root/Mount/Neck", "Root/Mount/Tail"]
## Leg order of every per-leg table: FL, FR, BL, BR (kit pivot ids below).
const LEGS: Array[int] = [P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]
## Touch-down time of each leg in the cycle (0-1). Walk = 4-beat lateral sequence (BL, FL, BR, FR); gallop =
## transverse gallop (hinds, then fores, a short suspension after the hinds leave).
const WALK_T: Array[float] = [0.25, 0.75, 0.0, 0.5]
const GAL_T: Array[float] = [0.42, 0.50, 0.0, 0.08]
const WALK_DUTY := 0.66
const GAL_DUTY := 0.40
## play_charge(): the strike frame (s) and the event name sent to _on_mount_event there.
const CHARGE_HIT := 0.10
const TOSS_HIT := 0.12

## Speed (m/s) from which the gait becomes a gallop (blends over ~1 m/s). Independent of stride_speed, which the Unit
## may overwrite with the type's move_speed at spawn.
@export var gallop_speed: float = 3.5
## Seconds per gallop stride at gallop_speed (the rate grows slowly with the speed).
@export var gallop_time: float = 0.62
## Leg swing amplitude (deg, front legs; hind legs 0.9 x) in the walk and in the gallop.
@export var walk_swing_deg: float = 22.0
@export var gallop_swing_deg: float = 34.0
## Hoof lift (m) at mid-swing in the walk; the gallop lifts 1.7 x.
@export var step_lift: float = 0.09
## Gallop body motion: vertical bounce (m) and body pitch rocking (deg); head carried lower by gallop_head_deg.
@export var gallop_bounce: float = 0.07
@export var gallop_pitch_deg: float = 5.0
@export var gallop_head_deg: float = 6.0
## Tail swish amplitude (deg) in the idle; the gallop lifts the tail by tail_gallop_lift_deg.
@export var tail_swish_deg: float = 16.0
@export var tail_gallop_lift_deg: float = 24.0
## Head drop (deg, nose down) that levels the horn / tusks at the charge.
@export var charge_head_deg: float = 26.0
## Death: height (m) of the body centre once lying on its side; 0 = auto (half the body's width).
@export var lie_height: float = 0.0
## Idle fidget (head shake, paw, tail) every ~N s (+-40 %) while standing within 30 m; 0 = never.
@export var fidget_every: float = 10.0

# --- static caches (per mount type) ---
static var _bard_src: Dictionary = {}    # "type|pivot" -> Array of [mesh, pivot-local xf, mats]
static var _bard_mesh: Dictionary = {}   # "type|pivot" -> ArrayMesh (the plain merge + the barding) or null
static var _bard_done: Dictionary = {}   # type -> true once its barding sources are recorded
static var _mat_files: Dictionary = {}   # path -> Material

# --- extra pivots ---
var _xpiv: Array[Node3D] = [null, null]
var _xmerged: Array[MeshInstance3D] = [null, null]
var _xrest_pos: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _xrest_rot: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _xoff_pos: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _xoff_rot: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _xlast_pos: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _xlast_rot: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _seat: Node3D

# --- setup / looks ---
var _setup_done: bool = false
var _authored_n: int = 0
var _mount_geo: Array[MeshInstance3D] = []       # every merged mount mesh (flash, team colour, barding swap)
var _pivot_mi: Dictionary = {}                   # "type|pivot" -> MeshInstance3D (barding swap target)
var _pivot_node: Dictionary = {}                 # "type|pivot" -> pivot Node3D
var _barded: bool = false
var _barded_applied: bool = false
var _team_col: Variant = null                    # null = the scene's own kingdom colour
var _body_c: Vector3 = Vector3(0, 0.9, 0)        # model-space centre of the body merge
var _lie_h: float = 0.5
var _fall_side: float = 1.0

# --- motion state ---
var _mdt: float = 0.0
var _fast: bool = false
var _gait_p: float = 0.0
var _gallop_w: float = 0.0
var _leg_prev: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _flare: float = 0.0
var _flare_written: float = -1.0
var _fidget_wait: float = 0.0
var _fidget_prev: float = 0.0
var _charge_prev: float = 0.0
# idle values of this frame (shared by the blended idle and the fast path)
var _iv_root_y: float = 0.0
var _iv_body: Vector3 = Vector3.ZERO
var _iv_head: Vector3 = Vector3.ZERO
var _iv_neck: Vector3 = Vector3.ZERO
var _iv_tail: Vector3 = Vector3.ZERO

# Keyframe tracks [t, value, ease, ...] (see _mkf). Charge (strike 0.10 s): the head drops to level the horn, the
# body lunges, the fronts reach and the hinds drive, then a gore toss (head up) and the recovery.
static var CH_HEAD := PackedFloat32Array([0.0, 0.0, 0, 0.06, 1.0, 1, 0.14, 0.9, 0, 0.28, -0.9, 1, 0.48, -0.3, 0, 0.85, 0.0, 0])
static var CH_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.05, -0.06, 1, 0.12, 0.42, 2, 0.34, 0.26, 0, 0.85, 0.0, 0])
static var CH_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.06, -0.08, 1, 0.14, -0.05, 0, 0.30, 0.05, 1, 0.85, 0.0, 0])
static var CH_BODY_X := PackedFloat32Array([0.0, 0.0, 0, 0.06, 6.0, 1, 0.14, 4.0, 0, 0.30, -5.0, 1, 0.85, 0.0, 0])
static var CH_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.06, -16.0, 1, 0.14, -26.0, 1, 0.40, -6.0, 0, 0.85, 0.0, 0])
static var CH_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.06, 14.0, 1, 0.14, 24.0, 1, 0.40, 6.0, 0, 0.85, 0.0, 0])
static var CH_TAIL := PackedFloat32Array([0.0, 0.0, 0, 0.10, 30.0, 1, 0.40, 18.0, 0, 0.85, 0.0, 0])
# mount_toss (play_attack, strike 0.12 s): a head dip then a toss with a short lunge.
static var TS_HEAD := PackedFloat32Array([0.0, 0.0, 0, 0.08, 16.0, 1, 0.13, -22.0, 2, 0.30, -8.0, 1, 0.55, 0.0, 0])
static var TS_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.05, 1, 0.13, 0.18, 2, 0.30, 0.10, 0, 0.55, 0.0, 0])
static var TS_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.08, -8.0, 1, 0.14, -14.0, 1, 0.55, 0.0, 0])
# Death (1.0 s): stumble (front knees give, nose down), roll onto the side, a bounce, a last kick, settle.
static var D_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.22, 9.0, 1, 0.55, 3.0, 0, 1.0, 0.0, 0])
static var D_DROP := PackedFloat32Array([0.0, 0.0, 0, 0.22, -0.16, 1, 0.50, -0.10, 0, 1.0, -0.10, 0])
static var D_ROLL := PackedFloat32Array([0.0, 0.0, 0, 0.20, 0.06, 1, 0.58, 1.0, 2, 0.68, 0.93, 1, 0.80, 1.0, 2, 1.0, 1.0, 0])
static var D_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.22, 40.0, 1, 0.58, 20.0, 0, 0.74, -10.0, 1, 0.86, 6.0, 0, 1.0, 6.0, 0])
static var D_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.22, -8.0, 1, 0.58, 8.0, 0, 0.74, 22.0, 1, 0.86, 12.0, 0, 1.0, 12.0, 0])
static var D_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.18, -22.0, 1, 0.50, -12.0, 0, 0.66, 14.0, 2, 1.0, 10.0, 0])
static var D_HEAD_Z := PackedFloat32Array([0.0, 0.0, 0, 0.50, 0.0, 0, 0.70, 22.0, 2, 1.0, 18.0, 0])


# ================================================================ authoring (called from _build_mount)

## Subclass hook: build the mount's parts (called on every instance; the static parts are skipped once the type is
## cached, so call the same helpers every time: the authored count stays right).
func _build_mount() -> void:
	pass


## add_part() that counts in authored_mesh_count(). Same arguments and return as CharacterModel.add_part.
func part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored_n += 1
	return add_part(pivot, mesh, mat, model_pos, rot_deg, scl, keep_separate, part_name)


## One authored part = a multi-material "sculpt" built by `build.call(s)` (s = sculpt(); fill it with sculpt_add /
## sculpt_lathe... in MODEL space). The callable only runs for the first instance of the type (cached after).
func add_sculpt(pivot: Node3D, build: Callable) -> void:
	_authored_n += 1
	if pivot_cached(pivot):
		return
	var s := sculpt()
	build.call(s)
	var m := sculpt_mesh(s)
	if m:
		add_part(pivot, m, null, Vector3.ZERO)


## A barding part (shown only while set_barded(true)): merged into a cached barded variant of the pivot's mesh
## (0 extra draw instances). Same placement arguments as part(); mat null = the mesh's own surface materials.
func add_barding_part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	_authored_n += 1
	if pivot == null or _bard_done.has(_type_key):
		return
	var b := Basis.from_euler(rot_deg * DEG) * Basis.from_scale(scl)
	_bard_record(pivot, mesh, Transform3D(b, model_pos - model_origin(pivot)), [mat] if mat else [])


## Barding as a sculpt (model space, like add_sculpt). One authored part.
func add_barding_sculpt(pivot: Node3D, build: Callable) -> void:
	_authored_n += 1
	if pivot == null or _bard_done.has(_type_key):
		return
	var s := sculpt()
	build.call(s)
	var m := sculpt_mesh(s)
	if m:
		_bard_record(pivot, m, Transform3D(Basis.IDENTITY, -model_origin(pivot)), [])


## True when the pivot's merged mesh is already cached for this scene type (its static parts are not needed).
func pivot_cached(pivot: Node3D) -> bool:
	return pivot == null or _merged.has(_type_key + "|" + _pivot_name(pivot))


## Authored meshes of this scene (parts + sculpts + barding pieces + the blob), the budget number of section 10.
func authored_mesh_count() -> int:
	return _authored_n + (1 if _shadow else 0)


func _bard_record(pivot: Node3D, mesh: Mesh, xf: Transform3D, mats: Array) -> void:
	var key := _type_key + "|" + _pivot_name(pivot)
	if not _bard_src.has(key):
		_bard_src[key] = []
	(_bard_src[key] as Array).append([mesh, xf, mats])


## Material resource by path, loaded once and shared (never duplicated: no runtime materials).
static func material_at(path: String) -> Material:
	if not _mat_files.has(path):
		_mat_files[path] = load(path)
	return _mat_files[path]


# ================================================================ sculpts + mesh builders (static, cached)

## An empty multi-material accumulator (per-material surfaces, like the kit merge).
static func sculpt() -> Dictionary:
	return {"by": {}, "order": []}


## Adds `mesh` (all its surfaces) placed by `xf` (model space) with material `mat`.
static func sculpt_add(s: Dictionary, mesh: Mesh, xf: Transform3D, mat: Material) -> void:
	if mesh == null:
		return
	var mats: Array = []
	for i: int in mesh.get_surface_count():
		mats.append(mat)
	_merge_acc(s["by"], s["order"], mesh, xf, mats)


## Primitive at a model position with rotation (deg, YXZ like Node3D) and scale.
static func sculpt_put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	sculpt_add(s, mesh, Transform3D(Basis.from_euler(rot_deg * DEG) * Basis.from_scale(scl), at), mat)


## Hexagonal ice / stone crystal from `base` along `dir`: prism body + pointed tip (tip = share of the length).
## (One cheap shared hex mesh, ~26 vertices; `tip` picks the nearest of 3 cached shapes.)
static func sculpt_crystal(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, r: float, h: float,
		tip: float = 0.45, twist_deg: float = 0.0) -> void:
	var d := dir.normalized()
	var b := Basis(Quaternion(Vector3.UP, d)) * Basis(Vector3.UP, twist_deg * DEG)
	sculpt_add(s, crystal_mesh(tip), Transform3D(b.scaled_local(Vector3(r, h, r)), base), mat)


## Unit hexagonal crystal along +Y (radius 1 at the base, length 1): a slightly widening prism then a point taking
## `tip` of the length (snapped to 0.35 / 0.45 / 0.55). Flat facets come from the ice shader.
static func crystal_mesh(tip: float = 0.45) -> Mesh:
	var t: float = 0.35 if tip < 0.4 else (0.45 if tip < 0.5 else 0.55)
	return lathe_mesh("mount_crystal_%s" % t, PackedVector2Array([Vector2(0.86, 0.0), Vector2(1.0, 1.0 - t),
		Vector2(0.0, 1.0)]), 6)


## A fur lock whose root is at `base`, hanging along `dir` (length len), width w, thickness th; its tip curls toward
## `out` (the surface's outward normal). See lock_mesh().
static func sculpt_lock(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, out: Vector3, w: float,
		len: float, th: float) -> void:
	sculpt_add(s, lock_mesh(), lock_xform(base, dir, out, w, len, th), mat)


static func sculpt_mesh(s: Dictionary) -> ArrayMesh:
	if (s["order"] as Array).is_empty():
		return null
	return _merge_finish(s["by"], s["order"])


## Frame whose +Y is `y_dir` and +Z is the part of `z_hint` perpendicular to it (for lathes / plates along a bone).
static func frame(o: Vector3, y_dir: Vector3, z_hint: Vector3) -> Transform3D:
	var y := y_dir.normalized()
	var z := (z_hint - y * z_hint.dot(y)).normalized()
	if z.length_squared() < 0.5:
		z = (Vector3.FORWARD - y * Vector3.FORWARD.dot(y)).normalized()
	return Transform3D(Basis(y.cross(z), y, z), o)


## Transform of a fur lock (lock_mesh) rooted at base, hanging along dir, curling toward out.
static func lock_xform(base: Vector3, dir: Vector3, out: Vector3, w: float, len: float, th: float) -> Transform3D:
	var f := frame(base, -dir, out)
	return Transform3D(Basis(f.basis.x * w, f.basis.y * len, f.basis.z * th), base)


## Surface of revolution around +Y. `prof` = [Vector2(radius, y), ...] walked from the bottom to the top (outline on
## the right); ends with radius > 0 get a cap. Smooth normals.
static func lathe_mesh(key: String, prof: PackedVector2Array, seg: int = 10, caps: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := prof.size()
	var sn: Array[Vector2] = []
	for i: int in n - 1:
		var t := prof[i + 1] - prof[i]
		sn.append(Vector2(t.y, -t.x).normalized())
	for i: int in n - 1:
		var n0: Vector2 = sn[i] if i == 0 else (sn[i - 1] + sn[i]).normalized()
		var n1: Vector2 = sn[i] if i == n - 2 else (sn[i] + sn[i + 1]).normalized()
		for j: int in seg:
			var a0 := TAU * float(j) / float(seg)
			var a1 := TAU * float(j + 1) / float(seg)
			var va := _rv(prof[i], a0)
			var vb := _rv(prof[i], a1)
			var vc := _rv(prof[i + 1], a1)
			var vd := _rv(prof[i + 1], a0)
			var na := _rn(n0, a0)
			var nb := _rn(n0, a1)
			var nc := _rn(n1, a1)
			var nd := _rn(n1, a0)
			_emit(st, va, vb, vc, na, nb, nc)
			_emit(st, va, vc, vd, na, nc, nd)
	if caps:
		for e: int in [0, n - 1]:
			var pe := prof[e]
			if pe.x <= 0.001:
				continue
			var up: Vector3 = Vector3.UP if e == n - 1 else Vector3.DOWN
			var c := Vector3(0, pe.y, 0)
			for j: int in seg:
				_emit(st, c, _rv(pe, TAU * float(j) / float(seg)), _rv(pe, TAU * float(j + 1) / float(seg)), up, up, up)
	st.index()
	return _cached(key, st.commit())


static func _rv(p: Vector2, a: float) -> Vector3:
	return Vector3(p.x * sin(a), p.y, p.x * cos(a))


static func _rn(nn: Vector2, a: float) -> Vector3:
	return Vector3(nn.x * sin(a), nn.y, nn.x * cos(a)).normalized()


## Smooth tube through `pts` with one radius per point (0 = a point). `flat` < 1 squashes the cross-section on the
## side axis (a blade-like horn). Parallel-transported rings, capped ends.
static func tube_mesh(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6,
		caps: bool = true, flat: float = 1.0) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var rings: Array = []
	var norms: Array = []
	var ref := Vector3.ZERO
	for i: int in n:
		var t := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		if i == 0:
			var r0 := Vector3.UP if absf(t.y) < 0.9 else Vector3.BACK
			ref = (r0 - t * r0.dot(t)).normalized()
		else:
			ref = (ref - t * ref.dot(t)).normalized()
		var bn := t.cross(ref)
		var ring := PackedVector3Array()
		var rn := PackedVector3Array()
		for j: int in seg:
			var a := TAU * float(j) / float(seg)
			ring.append(pts[i] + (ref * cos(a) + bn * sin(a) * flat) * radii[i])
			rn.append((ref * cos(a) + bn * (sin(a) / maxf(flat, 0.05))).normalized())
		rings.append(ring)
		norms.append(rn)
	for i: int in n - 1:
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		var m0: PackedVector3Array = norms[i]
		var m1: PackedVector3Array = norms[i + 1]
		for j: int in seg:
			var k := (j + 1) % seg
			if radii[i + 1] <= 0.0005:
				var tip_n := (m0[j] + m0[k]).normalized()
				_emit(st, r0[j], r0[k], pts[i + 1], m0[j], m0[k], tip_n)
				continue
			_emit(st, r0[j], r0[k], r1[k], m0[j], m0[k], m1[k])
			_emit(st, r0[j], r1[k], r1[j], m0[j], m1[k], m1[j])
	if caps:
		for e: int in [0, n - 1]:
			if radii[e] <= 0.0005:
				continue
			var t2 := (pts[mini(e + 1, n - 1)] - pts[maxi(e - 1, 0)]).normalized()
			var o: Vector3 = t2 if e == n - 1 else -t2
			var ring2: PackedVector3Array = rings[e]
			for j: int in seg:
				_emit(st, pts[e], ring2[j], ring2[(j + 1) % seg], o, o, o)
	st.index()
	return _cached(key, st.commit())


## Curved plate (saddle-cloth, barding plates, drapes): a patch of an elliptic cylinder around local +Z.
## Angle a (deg) is measured around Z from +Y (top, 0) toward +X (90); length l along Z from l0 to l1.
## Point = (rx sin a, ry cos a, l) x scale(l), scale = lerp(1, taper, v) x (1 + bulge sin(pi v)); `thick` inward.
## Place it with an xf in the sculpt (e.g. Transform3D(Basis.IDENTITY, body_centre) for a plate on the barrel).
static func shell_mesh(key: String, rx: float, ry: float, a0: float, a1: float, l0: float, l1: float, thick: float,
		seg_a: int = 8, seg_l: int = 2, taper: float = 1.0, bulge: float = 0.0) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer: Array = []
	var inner: Array = []
	var nrm: Array = []
	for il: int in seg_l + 1:
		var v := float(il) / float(seg_l)
		var l := lerpf(l0, l1, v)
		var sc := lerpf(1.0, taper, v) * (1.0 + bulge * sin(PI * v))
		var ro := PackedVector3Array()
		var ri := PackedVector3Array()
		var rn := PackedVector3Array()
		for ia: int in seg_a + 1:
			var a := deg_to_rad(lerpf(a0, a1, float(ia) / float(seg_a)))
			var nn := Vector3(sin(a) / rx, cos(a) / ry, 0.0).normalized()
			var p := Vector3(rx * sin(a) * sc, ry * cos(a) * sc, l)
			ro.append(p)
			ri.append(p - nn * thick)
			rn.append(nn)
		outer.append(ro)
		inner.append(ri)
		nrm.append(rn)
	for il: int in seg_l:
		var o0: PackedVector3Array = outer[il]
		var o1: PackedVector3Array = outer[il + 1]
		var i0: PackedVector3Array = inner[il]
		var i1: PackedVector3Array = inner[il + 1]
		var n0: PackedVector3Array = nrm[il]
		var n1: PackedVector3Array = nrm[il + 1]
		for ia: int in seg_a:
			var k := ia + 1
			_emit(st, o0[ia], o0[k], o1[k], n0[ia], n0[k], n1[k])
			_emit(st, o0[ia], o1[k], o1[ia], n0[ia], n1[k], n1[ia])
			_emit(st, i0[ia], i1[k], i0[k], -n0[ia], -n1[k], -n0[k])
			_emit(st, i0[ia], i1[ia], i1[k], -n0[ia], -n1[ia], -n1[k])
	# edges: the two long sides (a0, a1) and the two ends (l0, l1), flat shaded
	for il: int in seg_l:
		for side: int in 2:
			var ia: int = 0 if side == 0 else seg_a
			var nb_i: int = 1 if side == 0 else seg_a - 1
			var a := (outer[il] as PackedVector3Array)[ia]
			var b := (outer[il + 1] as PackedVector3Array)[ia]
			var c := (inner[il + 1] as PackedVector3Array)[ia]
			var d := (inner[il] as PackedVector3Array)[ia]
			# outward = away from the neighbouring column (the plate's rim faces sideways)
			var en := (a - (outer[il] as PackedVector3Array)[nb_i]).normalized()
			_emit(st, a, b, c, en, en, en)
			_emit(st, a, c, d, en, en, en)
	for end: int in 2:
		var il: int = 0 if end == 0 else seg_l
		var o: PackedVector3Array = outer[il]
		var ii: PackedVector3Array = inner[il]
		var en := Vector3(0, 0, -1.0 if end == 0 else 1.0)
		for ia: int in seg_a:
			_emit(st, o[ia], o[ia + 1], ii[ia + 1], en, en, en)
			_emit(st, o[ia], ii[ia + 1], ii[ia], en, en, en)
	st.index()
	return _cached(key, st.commit())


## Fur lock: a flattened 4-sided strand, root at the origin, hanging along -Y (length 1), width 1 (x), thickness 1
## (z), the tip curling toward +Z. Use it through sculpt_lock / lock_xform. ~16 vertices.
static func lock_mesh() -> Mesh:
	return tube_mesh("mount_lock_v2", PackedVector3Array([Vector3(0, 0.04, -0.05), Vector3(0, -0.40, 0.03),
		Vector3(0, -0.76, 0.14), Vector3(0, -1.0, 0.30)]), PackedFloat32Array([0.5, 0.5, 0.34, 0.0]), 4, false)


## Shaggy fur fringe (mane capes, belly skirts, fur boots, manes): a double-sided band around local +Y, top ring
## (rx0, rz0) at y 0, bottom ring (rx1, rz1) at y -h, whose lower edge is cut into `teeth` points hanging `tooth`
## further (`ragged` 0-1 varies each tooth's length). Angle (deg) from +Z toward +X, a0..a1 (360 apart = closed).
## ~8 vertices per tooth.
static func fringe_mesh(key: String, rx0: float, rz0: float, rx1: float, rz1: float, h: float, a0: float, a1: float,
		teeth: int, tooth: float, thick: float = 0.03, ragged: float = 0.5) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var closed: bool = absf(a1 - a0) >= 359.9
	var n: int = teeth * 2
	var cnt: int = n if closed else n + 1
	var tops := PackedVector3Array()
	var bots := PackedVector3Array()
	var nrm := PackedVector3Array()
	var flare: float = ((rx1 + rz1) - (rx0 + rz0)) * 0.5 / maxf(h, 0.01)
	for i: int in cnt:
		var th := deg_to_rad(lerpf(a0, a1, float(i) / float(n)))
		var sn := sin(th)
		var cs := cos(th)
		var long: bool = i % 2 == 1
		# ragged: a fixed pseudo-random length per tooth, so the hem reads as fur, not a saw blade
		var rnd: float = fposmod(sin(float(i) * 12.9898 + rx1 * 78.233 + h * 37.719) * 43758.5453, 1.0)
		var tl: float = tooth * (1.0 + ragged * (rnd * 2.0 - 1.0)) if long else tooth * 0.25 * rnd * ragged
		var reach: float = 1.0 + (0.06 + 0.06 * rnd * ragged if long else 0.0)
		tops.append(Vector3(rx0 * sn, 0.0, rz0 * cs))
		bots.append(Vector3(rx1 * sn * reach, -h - tl, rz1 * cs * reach))
		nrm.append(Vector3(sn / maxf(rx1, 0.01), flare / maxf((rx1 + rz1) * 0.5, 0.01), cs / maxf(rz1, 0.01)).normalized())
	for i: int in n:
		var j: int = (i + 1) % cnt
		var a := tops[i]
		var b := tops[j]
		var c := bots[j]
		var d := bots[i]
		_emit(st, a, b, c, nrm[i], nrm[j], nrm[j])
		_emit(st, a, c, d, nrm[i], nrm[j], nrm[i])
		var ia := a - nrm[i] * thick
		var ib := b - nrm[j] * thick
		var ic := c - nrm[j] * thick
		var id := d - nrm[i] * thick
		_emit(st, ia, ic, ib, -nrm[i], -nrm[j], -nrm[j])
		_emit(st, ia, id, ic, -nrm[i], -nrm[i], -nrm[j])
	st.index()
	return _cached(key, st.commit())


## Fur fringe in a sculpt: fringe_mesh placed with its top ring centred at `at` (model space), optional basis.
static func sculpt_fringe(s: Dictionary, mat: Material, mesh: Mesh, at: Vector3, b: Basis = Basis.IDENTITY) -> void:
	sculpt_add(s, mesh, Transform3D(b, at), mat)


## One triangle with the front face (Godot: clockwise) toward the given normals.
static func _emit(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	if fn.dot(na + nb + nc) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)


## Keyframe track [t, v, ease, t, v, ease, ...] starting at t = 0 (same format as FireModel._kf / NatureWarModel._kf):
## ease of the segment arriving at a key: 0 smooth, 1 ease-out (snappy start), 2 ease-in (accelerating into it).
static func _mkf(t: float, k: PackedFloat32Array) -> float:
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


# ================================================================ kit lifecycle

func _build_parts() -> void:
	for j: int in 2:
		var n := get_node_or_null(EXTRA_PATHS[j]) as Node3D
		_xpiv[j] = n
		if n:
			n.set_meta(&"keep_separate", true)   # the kit's Mount merge skips it; merged below
			_xrest_pos[j] = n.position
			_xrest_rot[j] = n.rotation
			_xlast_pos[j] = n.position
			_xlast_rot[j] = n.rotation
	_seat = get_node_or_null(^"Root/Mount/Seat") as Node3D
	_build_mount()
	for j: int in 2:
		if _xpiv[j]:
			_merge_extra(j)
	_bard_done[_type_key] = true


func _merge_extra(j: int) -> void:
	var p: Node3D = _xpiv[j]
	var key := _type_key + "|" + _pivot_name(p)
	var parts: Array[MeshInstance3D] = []
	var xforms: Array[Transform3D] = []
	_collect_static(p, Transform3D.IDENTITY, parts, xforms, true)
	var entry: Dictionary
	if _merged.has(key):
		entry = _merged[key]
	else:
		entry = _build_merged(parts, xforms)
		_merged[key] = entry
	for m: MeshInstance3D in parts:
		if m.get_child_count() == 0:
			m.get_parent().remove_child(m)
			m.queue_free()
		else:
			m.mesh = null
	if entry.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.name = "Merged"
	mi.mesh = entry["mesh"]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var params: Dictionary = entry["params"]
	for nm: StringName in params:
		mi.set_instance_shader_parameter(nm, params[nm])
	p.add_child(mi)
	_xmerged[j] = mi


func _after_ready() -> void:
	_mount_geo.clear()
	for i: int in [P_MOUNT, P_MOUNT_HEAD, P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if _piv[i]:
			_pivot_node[_type_key + "|" + _pivot_name(_piv[i])] = _piv[i]
		if m:
			_mount_geo.append(m)
			_pivot_mi[_type_key + "|" + _pivot_name(_piv[i])] = m
	for j: int in 2:
		if _xpiv[j]:
			_pivot_node[_type_key + "|" + _pivot_name(_xpiv[j])] = _xpiv[j]
		if _xmerged[j]:
			_mount_geo.append(_xmerged[j])
			_pivot_mi[_type_key + "|" + _pivot_name(_xpiv[j])] = _xmerged[j]
	# The kit flashes the merged Chest / Head / ArmR on hits; a mount has none: the whole beast flashes.
	for m: MeshInstance3D in _mount_geo:
		if not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
	# Body centre and lying height (death roll) from the body merge.
	var body: MeshInstance3D = _merged_nodes.get(P_MOUNT)
	if body and body.mesh and _piv[P_MOUNT]:
		var bb := body.mesh.get_aabb()
		_body_c = model_origin(_piv[P_MOUNT]) + bb.get_center()
		_lie_h = lie_height if lie_height > 0.0 else bb.size.x * 0.5
	else:
		_lie_h = lie_height if lie_height > 0.0 else 0.5
	_fall_side = 1.0 if (hash(get_instance_id()) & 1) == 0 else -1.0
	_fidget_wait = _next_fidget() * 0.6
	_setup_done = true
	if _barded:
		_apply_barding()
	_refresh_team_all()
	_mount_ready()


## Subclass hook: after the merge (grab keep_separate nodes here).
func _mount_ready() -> void:
	pass


# ================================================================ hooks

## Team colour (the saddle-cloth: every *_cloth / *_cloth_dark / *_cape / *_pennon surface). Setting the scene's own
## kingdom_color again restores it. Any number of calls in any order; the keep_separate parts (material_override)
## follow too. Nested kit models (a howdah) get their own call from the subclass. Safe before _ready.
func set_team_color(c: Color) -> void:
	if not _ready_done:
		_team_pending = c
		return
	_team_pending = null
	var tc: Variant = null if _is_kingdom_color(c) else c
	if tc == null and _team_col == null:
		return   # still the authored colours
	_team_col = tc
	if _setup_done:
		_refresh_team_all()
	_recolor(self, tc, false)


## Barding on / off: swaps each pivot's merged mesh for its cached barded variant (0 extra draw instances).
func set_barded(on: bool) -> void:
	_barded = on
	if _setup_done:
		_apply_barding()


func is_barded() -> bool:
	return _barded


## The charge (call it when the charge hit lands, Unit.charged): head levels the horn / tusks, lunge, gore toss.
## Strike frame CHARGE_HIT (0.10 s) sends _on_mount_event(&"charge_hit"); eyes / glows flare. Length 0.85 s.
func play_charge() -> void:
	if _dead:
		return
	_action = &"charge"
	_action_t = 0.0
	_charge_prev = 0.0
	_flare = 1.0
	_on_mount_event(&"charge_start")
	set_process(true)


## Starts the idle fidget now (preview helper; the loop does it by itself every ~fidget_every s when close).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0
		_fidget_prev = 0.0


## The rider's hip point in MODEL space (this node's frame), with the current body motion (bob, pitch, death roll).
## Before _ready / without a Seat marker: the rest seat / an estimate at 0.7 x body_height.
func seat_transform() -> Transform3D:
	if _seat == null:
		_seat = get_node_or_null(^"Root/Mount/Seat") as Node3D
	if _seat == null:
		return Transform3D(Basis.IDENTITY, Vector3(0, body_height * 0.7, 0))
	var xf := _seat.transform
	var n: Node = _seat.get_parent()
	while n != null and n != self:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf


## The Seat marker (parent the rider's model to it: it then follows the gait with no frame lag), or null.
func seat_node() -> Node3D:
	if _seat == null:
		_seat = get_node_or_null(^"Root/Mount/Seat") as Node3D
	return _seat


## Gait cycle phase 0-1 (for a rider's bob / sway), 0 at the left hind footfall.
func gait_phase() -> float:
	return _gait_p


## 0 = walking, 1 = galloping (blends over ~0.35 s).
func gallop_blend() -> float:
	return _gallop_w


func is_galloping() -> bool:
	return _gallop_w > 0.5 and _walk_w > 0.5


# ================================================================ subclass hooks

## Events: charge_start, charge_hit (the strike frame), fidget_snort, death_down (the body hits the ground).
func _on_mount_event(_ev: StringName) -> void:
	pass


## A hoof lands (leg 0-3 = FL, FR, BL, BR; gallop true when galloping). Only within 30 m (tier 0).
func _on_footfall(_leg: int, _gallop: bool) -> void:
	pass


## Per-frame extras (after the body pose; rot() / pos() / xrot() only apply on animated frames, not in the idle fast
## path). Keep it tiny: no allocation, no get_node.
func _mount_process(_dt: float) -> void:
	pass


func _mount_revive() -> void:
	pass


## Idle fidget pose at time t (write offsets); return its length (s). Base: a head shake, a paw and a tail swish.
func _pose_fidget(t: float) -> float:
	var env := _k3(t, 0.0, 0.25, 1.35, 1.7, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(8.0 * DEG * env, 16.0 * DEG * sin(t * TAU * 2.2) * env * smoothstep(0.3, 0.5, t) *
		(1.0 - smoothstep(0.9, 1.2, t)), 0))
	var paw: float = sin((t - 0.2) / 0.9 * TAU * 2.0) if t > 0.2 and t < 1.1 else 0.0
	rot(P_LEG_FR, Vector3((-24.0 * maxf(paw, 0.0) + 10.0 * maxf(-paw, 0.0)) * DEG, 0, 0))
	pos(P_LEG_FR, Vector3(0, 0.06 * maxf(paw, 0.0), 0))
	xrot(X_TAIL, Vector3(8.0 * DEG * env, 22.0 * DEG * sin(t * TAU * 1.6) * env, 0))
	if _fidget_prev < 1.3 and t >= 1.3:
		_on_mount_event(&"fidget_snort")
		_flare = maxf(_flare, 0.5)
	return 1.7


## Charge pose at time t (write offsets); return its length. Base: CH_* tracks (see play_charge).
func _pose_charge(t: float) -> float:
	var hd := _mkf(t, CH_HEAD)
	var head_x: float = charge_head_deg * hd if hd > 0.0 else 30.0 * hd
	rot(P_MOUNT_HEAD, Vector3(head_x * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _mkf(t, CH_ROOT_Y), _mkf(t, CH_ROOT_Z)))
	rot(P_MOUNT, Vector3(_mkf(t, CH_BODY_X) * DEG, 0, 0))
	var k: float = 1.0 - 0.6 * _walk_w   # already galloping: the legs keep most of their cycle
	var f := _mkf(t, CH_LEG_F) * DEG * k
	var b := _mkf(t, CH_LEG_B) * DEG * k
	rot(P_LEG_FL, Vector3(f, 0, 0)); rot(P_LEG_FR, Vector3(f * 0.85, 0, 0))
	rot(P_LEG_BL, Vector3(b, 0, 0)); rot(P_LEG_BR, Vector3(b * 0.9, 0, 0))
	xrot(X_TAIL, Vector3(_mkf(t, CH_TAIL) * DEG, 0, 0))
	xrot(X_NECK, Vector3(head_x * 0.3 * DEG, 0, 0))
	return 0.85


# ================================================================ pose helpers for the extra pivots

## Adds a rotation offset (radians) to extra pivot j (X_NECK, X_TAIL) for this frame.
func xrot(j: int, r: Vector3) -> void:
	if _xpiv[j]:
		_xoff_rot[j] += r


func xpos(j: int, p: Vector3) -> void:
	if _xpiv[j]:
		_xoff_pos[j] += p


func _xwrite(j: int, p: Vector3, r: Vector3) -> void:
	var n := _xpiv[j]
	if n == null:
		return
	if r != _xlast_rot[j] or _force_write:
		_xlast_rot[j] = r
		n.rotation = r
	if p != _xlast_pos[j] or _force_write:
		_xlast_pos[j] = p
		n.position = p


# ================================================================ animation (kit overrides)

func _animate(dt: float) -> void:
	_mdt = dt
	_fast = false
	for j: int in 2:
		_xoff_pos[j] = Vector3.ZERO
		_xoff_rot[j] = Vector3.ZERO
	if not _dead:
		_idle_values()
	var target_g: float = 0.0 if _dead else smoothstep(gallop_speed - 0.9, gallop_speed + 0.2, _speed)
	_gallop_w = move_toward(_gallop_w, target_g, dt / 0.35)
	super(dt)
	if not _fast:
		for j: int in 2:
			_xwrite(j, _xrest_pos[j] + _xoff_pos[j], _xrest_rot[j] + _xoff_rot[j])


## This frame's idle motion: breathing (root + chest), head nod and slow looks, neck, intermittent tail swishes.
func _idle_values() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	_iv_root_y = 0.014 * s
	_iv_body = Vector3(-0.7 * DEG * s, 0, 0.5 * DEG * sin(0.5 * ph + 0.7))
	var look: float = 9.0 * DEG * sin(0.29 * ph + _phase_off) if _tier == 0 else 0.0
	_iv_head = Vector3(3.5 * DEG * sin(1.3 * ph + 0.4), look, 0)
	_iv_neck = Vector3(2.0 * DEG * sin(ph + 0.6), look * 0.4, 0)
	var burst: float = clampf(sin(0.41 * ph + _phase_off * 2.0) * 2.5 - 1.2, 0.0, 1.0)
	_iv_tail = Vector3(3.0 * DEG * s, (0.25 + 0.75 * burst) * tail_swish_deg * DEG * sin(2.6 * ph), 0)


func _idle_fast() -> void:
	_fast = true
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, _iv_root_y, 0))
	_write_rot(P_MOUNT, _rest_rot[P_MOUNT] + _iv_body)
	var hp := _rest_pos[P_MOUNT_HEAD]
	var hr := _iv_head
	if _xpiv[X_NECK]:
		hp += _neck_carry(_iv_neck, Vector3.ZERO)
		hr += _iv_neck
	_write_pos(P_MOUNT_HEAD, hp)
	_write_rot(P_MOUNT_HEAD, _rest_rot[P_MOUNT_HEAD] + hr)
	_xwrite(X_NECK, _xrest_pos[X_NECK], _xrest_rot[X_NECK] + _iv_neck)
	_xwrite(X_TAIL, _xrest_pos[X_TAIL], _xrest_rot[X_TAIL] + _iv_tail)


func _pose_idle(w: float) -> void:
	if _dead:
		return
	pos(P_ROOT, Vector3(0, _iv_root_y * w, 0))
	rot(P_MOUNT, _iv_body * w)
	rot(P_MOUNT_HEAD, _iv_head * w)
	xrot(X_NECK, _iv_neck * w)
	xrot(X_TAIL, _iv_tail * w)


## Walk (4-beat) blending into a gallop above gallop_speed: per-leg stance / swing with hoof lift, body bob, roll and
## pitch rocking, head nod, tail. The phase runs on its own clock (walk: stride_speed / stride_time; gallop:
## gallop_speed / gallop_time).
func _pose_walk(w: float, _rate: float) -> void:
	var g := _gallop_w
	var fw: float = clampf(_speed / maxf(stride_speed, 0.1), 0.55, 1.8) / maxf(stride_time, 0.05)
	var fg: float = clampf(sqrt(maxf(_speed, 0.1) / maxf(gallop_speed, 0.1)), 0.8, 1.35) / maxf(gallop_time, 0.05)
	_gait_p = fmod(_gait_p + _mdt * lerpf(fw, fg, g), 1.0)
	var p := _gait_p
	var near: bool = _tier == 0
	for k: int in 4:
		var front: bool = k < 2
		var phw: float = fposmod(p - WALK_T[k], 1.0)
		var phg: float = fposmod(p - GAL_T[k], 1.0)
		var cw := _leg_cycle(phw, WALK_DUTY)
		var cg := _leg_cycle(phg, GAL_DUTY)
		var amp_w: float = walk_swing_deg * (1.0 if front else 0.9)
		var amp_g: float = gallop_swing_deg * (1.0 if front else 0.9)
		var ang: float = lerpf(cw.x * amp_w, cg.x * amp_g, g)
		var lift: float = lerpf(cw.y, cg.y * 1.7, g) * step_lift
		rot(LEGS[k], Vector3(ang * DEG * w, 0, 0))
		pos(LEGS[k], Vector3(0, lift * w, 0))
		if near:
			var ph_now: float = lerpf(phw, phg, 0.0 if g < 0.5 else 1.0)
			if ph_now < _leg_prev[k] - 0.5 and w > 0.5:
				_on_footfall(k, g >= 0.5)
			_leg_prev[k] = ph_now
	# body
	var wy: float = walk_bounce * 0.5 * cos(2.0 * TAU * p)
	var gy: float = gallop_bounce * (0.5 + 0.5 * cos(TAU * (p - 0.44))) - gallop_bounce * 0.35
	pos(P_ROOT, Vector3(0, lerpf(wy, gy, g) * w, 0))
	var pitch: float = lerpf(1.2 * sin(2.0 * TAU * p), gallop_pitch_deg * sin(TAU * (p - 0.25)), g)
	var roll: float = lerpf(2.2 * sin(TAU * p), 1.0 * sin(TAU * p), g)
	rot(P_MOUNT, Vector3(pitch * DEG * w, 0, roll * DEG * w))
	# head / neck / tail (the charge / attack poses own the head while they run)
	var head_x: float = lerpf(4.0 * sin(2.0 * TAU * p + 1.0), -0.7 * pitch + 6.0 * sin(TAU * (p - 0.05)) + gallop_head_deg, g)
	var head_y: float = lerpf(3.0 * sin(TAU * p), 1.0 * sin(TAU * p), g)
	if _action != &"attack" and _action != &"charge":
		rot(P_MOUNT_HEAD, Vector3(head_x * DEG * w, head_y * DEG * w, 0))
	xrot(X_NECK, Vector3(lerpf(2.0 * sin(2.0 * TAU * p + 0.6), -0.5 * pitch, g) * DEG * w, 0, 0))
	xrot(X_TAIL, Vector3(lerpf(4.0, tail_gallop_lift_deg, g) * DEG * w,
		lerpf(10.0, 6.0, g) * sin(TAU * p + 0.5) * DEG * w, 0))


## (swing -1..1, lift 0..1) of one leg at cycle phase phi: stance = the hoof on the ground sliding back (-1 = forward
## at the touch-down, +1 = back at the lift-off); swing = the hoof coming forward, lifted.
static func _leg_cycle(phi: float, duty: float) -> Vector2:
	if phi < duty:
		return Vector2(lerpf(-1.0, 1.0, phi / duty), 0.0)
	var u := (phi - duty) / (1.0 - duty)
	var s := u * u * (3.0 - 2.0 * u)
	return Vector2(lerpf(1.0, -1.0, s), sin(PI * u))


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"mount_toss":
		return super(prev, t)
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, TS_HEAD) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, 0, _mkf(t, TS_ROOT_Z)))
	var f := _mkf(t, TS_LEG_F) * DEG * (1.0 - 0.6 * _walk_w)
	rot(P_LEG_FL, Vector3(f, 0, 0)); rot(P_LEG_FR, Vector3(f * 0.8, 0, 0))
	xrot(X_TAIL, Vector3(_mkf(t, TS_HEAD) * -0.6 * DEG, 0, 0))
	if prev < TOSS_HIT and t >= TOSS_HIT:
		_on_action_event(&"release")
	return t < 0.55


## A mount has no cast: a short rear with the head up (the rider's cast hop-off happens in gameplay).
func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.18, 0.35, 0.6, 1.0, 1.0)
	rot(P_MOUNT, Vector3(-5.0 * DEG * k, 0, 0))
	rot(P_MOUNT_HEAD, Vector3(-14.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, 0.03 * k, 0))
	return 0.6


func _extra_process(dt: float) -> void:
	_fidget_tick(dt)
	if not _fast:
		if _action == &"charge" and not _dead:
			var len := _pose_charge(_action_t)
			if _charge_prev < CHARGE_HIT and _action_t >= CHARGE_HIT:
				_on_mount_event(&"charge_hit")
			_charge_prev = _action_t
			if _action_t >= len:
				_action = &""
		elif _action == &"fidget":
			if _dead or _speed >= 0.3:
				_action = &""
			else:
				var fl := _pose_fidget(_action_t)
				_fidget_prev = _action_t
				if _action_t >= fl:
					_action = &""
		if _hit_t < HIT_LEN and not _dead:
			var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
			rot(P_MOUNT_HEAD, Vector3(-12.0 * DEG * k, 8.0 * DEG * k * _fall_side, 0))
			rot(P_MOUNT, Vector3(0, 0, 3.0 * DEG * k * _fall_side))
			xrot(X_TAIL, Vector3(26.0 * DEG * k, 0, 0))
	_mount_process(dt)
	if not _fast and _xpiv[X_NECK] and _piv[P_MOUNT_HEAD]:
		pos(P_MOUNT_HEAD, _neck_carry(_xoff_rot[X_NECK], _xoff_pos[X_NECK]))
		rot(P_MOUNT_HEAD, _xoff_rot[X_NECK])
	_flare_tick(dt)


## Head position offset that keeps it on the end of a Neck rotated by r (and moved by p) from its rest.
func _neck_carry(r: Vector3, p: Vector3) -> Vector3:
	if _xpiv[X_NECK] == null or _piv[P_MOUNT_HEAD] == null:
		return Vector3.ZERO
	var d: Vector3 = _rest_pos[P_MOUNT_HEAD] - _xrest_pos[X_NECK]
	return p + Basis.from_euler(r) * d - d


func _fidget_tick(dt: float) -> void:
	if _action == &"fidget" or fidget_every <= 0.0 or _dead or _action != &"" or _speed >= 0.3 or _tier != 0:
		return
	_fidget_wait -= dt
	if _fidget_wait <= 0.0:
		_fidget_wait = _next_fidget()
		play_fidget()


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


## Glow flare (charge, snort): glow_boost = glow_level x (1 + 1.6 x flare) on the glow nodes, decays over 0.5 s.
func _flare_tick(dt: float) -> void:
	if _flare <= 0.0 and _flare_written < 0.0:
		return
	if _action != &"charge":
		_flare = maxf(0.0, _flare - dt / 0.5)
	var b: float = glow_level() * (1.0 + 1.6 * _flare)
	if absf(b - _flare_written) > 0.02 or _flare == 0.0:
		_flare_written = b if _flare > 0.0 else -1.0
		for gi: GeometryInstance3D in _glow_nodes:
			gi.set_instance_shader_parameter(&"glow_boost", b)


## Death (1.0 s): the front knees give and the nose drops, the beast rolls onto its side (lying at lie_height, legs
## out), bounces, a last kick, then lies still; glows die at 0.3 s, the blob fades 0.7-1.0, death_finished at 1.0.
func _pose_death(dt: float) -> void:
	var prev := _death_t
	_death_t += dt
	var t := _death_t
	var s := _fall_side
	var roll: float = _mkf(t, D_ROLL)
	var a: float = s * 86.0 * DEG * roll
	rot(P_ROOT, Vector3(0, 0, a))
	rot(P_MOUNT, Vector3(_mkf(t, D_PITCH) * DEG, 0, 0))
	# Lift the body so it rests on its flank instead of sinking: rotating Root about the ground point moves the body
	# centre to (-hc sin a, hc cos a); aim it at the lying height, and keep 60 % of the sideways slide.
	var hc: float = _body_c.y
	var y_target: float = lerpf(hc + _mkf(t, D_DROP), _lie_h, clampf(roll, 0.0, 1.0))
	pos(P_ROOT, Vector3(hc * sin(a) * 0.4, y_target - hc * cos(a), 0))
	var lf := _mkf(t, D_LEG_F) * DEG
	var lb := _mkf(t, D_LEG_B) * DEG
	rot(P_LEG_FL, Vector3(lf, 0, 0)); rot(P_LEG_FR, Vector3(lf * 0.8, 0, 0))
	rot(P_LEG_BL, Vector3(lb * 0.9, 0, 0)); rot(P_LEG_BR, Vector3(lb, 0, 0))
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, D_HEAD_X) * DEG, 0, -_mkf(t, D_HEAD_Z) * DEG * s))
	xrot(X_TAIL, Vector3(-10.0 * DEG * roll, 0, 0))
	if t >= 0.3:
		_glows_dead()
	if prev < 0.58 and t >= 0.58:
		_on_mount_event(&"death_down")
	if _shadow:
		_shadow.transparency = clampf((t - 0.7) / 0.3, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _on_revive() -> void:
	_gallop_w = 0.0
	_gait_p = 0.0
	_flare = 0.0
	_flare_written = -1.0
	_fidget_prev = 0.0
	for j: int in 2:
		_xoff_pos[j] = Vector3.ZERO
		_xoff_rot[j] = Vector3.ZERO
		_xlast_rot[j] = Vector3(INF, 0, 0)
		_xwrite(j, _xrest_pos[j], _xrest_rot[j])
	_mount_revive()


# ================================================================ barding + team colour

func _apply_barding() -> void:
	for key: String in _bard_src:
		if not key.begins_with(_type_key + "|"):
			continue
		var mi: MeshInstance3D = _pivot_mi.get(key)
		var pnode: Node3D = _pivot_node.get(key)
		if mi == null:
			if pnode == null:
				continue
			mi = MeshInstance3D.new()   # a pivot with barding only: its node draws nothing while unbarded
			mi.name = "Merged"
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			pnode.add_child(mi)
			mi.set_instance_shader_parameter(&"ao_height", body_height)
			_pivot_mi[key] = mi
			_mount_geo.append(mi)
			_flash_hit_targets.append(mi)
			_flash_all_targets.append(mi)
		var plain: Mesh = (_merged.get(key, {}) as Dictionary).get("mesh")
		var want: Mesh = _barded_variant(key, plain) if _barded else plain
		if mi.mesh == want and _barded_applied:
			continue
		mi.mesh = want
		_refresh_team(mi)
		if want and _mesh_glows(want) and not _glow_nodes.has(mi):
			_glow_nodes.append(mi)
			_apply_glow(true)
	_barded_applied = true


func _barded_variant(key: String, plain: Mesh) -> Mesh:
	if _bard_mesh.has(key):
		return _bard_mesh[key]
	var items: Array = [[plain, Transform3D.IDENTITY, []]]
	items.append_array(_bard_src[key])
	var m := _merge_items(items)
	_bard_mesh[key] = m
	return m


func _refresh_team_all() -> void:
	for mi: MeshInstance3D in _mount_geo:
		_refresh_team(mi)


## Cloth surfaces take the team variant (the kit's cached duplicates); everything else its own material.
func _refresh_team(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for s: int in mi.mesh.get_surface_count():
		var v: Material = null
		if _team_col != null:
			v = _team_variant(mi.mesh.surface_get_material(s), _team_col)
		mi.set_surface_override_material(s, v)
