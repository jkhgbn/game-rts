class_name GroveKinModel
extends NatureModel
## Polish layer (task A2.1) for the small folk of the grove: Sprigling (worker), Sapling (summon), Bloomtender
## (support). It sits between NatureModel (shared with the A2.2 units, left untouched) and those three scripts.
## Adds:
##   bake(key, parts)   [[mesh, Transform3D, material], ...] -> ONE cached ArrayMesh, one surface per material, so a
##                      keep_separate subtree (bouncing sprout, floppy hat, swinging censer) costs one draw instance.
##   lathe(key, profile, seg, lobes, lobe_amp, lobe_from, lobe_dip, inward)   a revolved profile (Vector2(r, y), top
##                      to bottom) with optional petal lobes / cloth folds (cos(lobes x angle)) on the lower rings.
##   add_hit_leaves(model_pos, color, n)   leaves / petals knocked off on every hit (only within 30 m).
##   spring(s, target, drive, w, damp, dt)  one damped-spring step (secondary motion: sprouts, canopies, hats).
##   root_accel()       vertical / forward acceleration of Root this frame (m/s^2), the drive of those springs.
##   Idle fidget every ~fidget_every s (standing, idle, < 30 m): override _pose_fidget(t) -> length; play_fidget().
##   KIN_BLOB           darker green-black ground blob: separates green bodies from the green grass.
## Per-frame work stays tiny: no allocation, no get_node; springs only write when they move.

const KIN_BLOB := Color(0.03, 0.05, 0.02, 0.58)

## Idle fidget (_pose_fidget) every ~N s (randomised +-40 % per unit) while standing within 30 m; 0 = never.
@export var fidget_every: float = 9.0

var _fidget_wait: float = 0.0
var _hit_leaves: GPUParticles3D
# Root motion tracking (the drive of the springs).
var _rp_prev: Vector3 = Vector3.ZERO
var _rv_prev: Vector3 = Vector3.ZERO
var _racc: Vector3 = Vector3.ZERO


# ================================================================ mesh builders (static, cached, shared)

## Bakes [[mesh, xform, material], ...] (surface 0 of each mesh) into one ArrayMesh with one surface per material.
static func bake(key: String, parts: Array) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var by_mat: Dictionary = {}
	var order: Array[Material] = []
	for p: Array in parts:
		var mat: Material = p[2]
		if not by_mat.has(mat):
			by_mat[mat] = [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), PackedVector2Array()]
			order.append(mat)
		var acc: Array = by_mat[mat]
		var xf: Transform3D = p[1]
		var nb := xf.basis.inverse().transposed()
		var arr := (p[0] as Mesh).surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var b0: int = (acc[0] as PackedVector3Array).size()
		for j: int in v.size():
			acc[0].append(xf * v[j])
			acc[1].append((nb * nr[j]).normalized() if j < nr.size() else Vector3.UP)
			acc[3].append(uv[j] if j < uv.size() else Vector2.ZERO)   # G-C: leaf / thorn UV tags (nature_living)
		if ix.is_empty():
			for j: int in v.size():
				acc[2].append(b0 + j)
		else:
			for j: int in ix.size():
				acc[2].append(b0 + ix[j])
	var am := ArrayMesh.new()
	for mat: Material in order:
		var acc: Array = by_mat[mat]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc[0]
		arrays[Mesh.ARRAY_NORMAL] = acc[1]
		arrays[Mesh.ARRAY_TEX_UV] = acc[3]
		arrays[Mesh.ARRAY_INDEX] = acc[2]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, mat)
	return _cached(key, am)


## Revolved profile: prof[i] = Vector2(radius, y), listed top to bottom; seg segments around (+Z at angle 0).
## Rings from `lobe_from` on get lobes: r x (1 + lobe_amp x w x cos(lobes x a)) and the gaps between lobes rise by
## lobe_dip x w (w ramps 0 -> 1 down to the last ring): petal tips, scalloped hems, cloth folds. inward = normals
## face the axis (the inside of a hat). Open at both ends. Smooth normals, closed seam.
static func lathe(key: String, prof: PackedVector2Array, seg: int, lobes: int = 0, lobe_amp: float = 0.0,
		lobe_from: int = 0, lobe_dip: float = 0.0, inward: bool = false) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = prof.size()
	for i: int in n:
		var w: float = 0.0
		if lobes > 0 and i >= lobe_from and n - 1 > lobe_from:
			w = float(i - lobe_from) / float(n - 1 - lobe_from)
		elif lobes > 0 and i >= lobe_from:
			w = 1.0
		for j: int in seg:
			var a: float = TAU * float(j) / float(seg)
			var c: float = cos(float(lobes) * a)
			var r: float = prof[i].x * (1.0 + lobe_amp * w * c)
			var y: float = prof[i].y + lobe_dip * w * (1.0 - c) * 0.5
			st.add_vertex(Vector3(r * sin(a), y, r * cos(a)))
	for i: int in n - 1:
		for j: int in seg:
			var a0: int = i * seg + j
			var b0: int = i * seg + (j + 1) % seg
			var c0: int = (i + 1) * seg + j
			var d0: int = (i + 1) * seg + (j + 1) % seg
			if inward:
				st.add_index(a0); st.add_index(d0); st.add_index(b0)
				st.add_index(a0); st.add_index(c0); st.add_index(d0)
			else:
				st.add_index(a0); st.add_index(b0); st.add_index(d0)
				st.add_index(a0); st.add_index(d0); st.add_index(c0)
	st.generate_normals()
	return _cached(key, st.commit())


## One damped-spring step (semi-implicit Euler, dt clamped for stability). s = (value, velocity); drive = extra
## acceleration (e.g. -root_accel().y x gain). Returns the new (value, velocity).
static func spring(s: Vector2, target: float, drive: float, w: float, damp: float, dt: float) -> Vector2:
	var h: float = minf(dt, 0.05)
	var v: float = s.y + ((target - s.x) * w * w - s.y * damp + drive) * h
	return Vector2(s.x + v * h, v)


# ================================================================ fx

## Leaves / petals knocked off the body on each hit (pre-built one-shot, restarted within 30 m).
func add_hit_leaves(model_pos: Vector3, color: Color, n: int = 6, size: float = 0.13) -> void:
	_hit_leaves = make_petals(color, n, 0.8, 0.22, 2.2, size, true)
	_hit_leaves.name = "HitLeaves"
	_hit_leaves.position = model_pos
	$Fx.add_child(_hit_leaves)


## Starts the idle fidget now (preview helper; the loop does it by itself every ~fidget_every s).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0


# ================================================================ kit hooks

func _after_ready() -> void:
	_fidget_wait = _next_fidget() * 0.6
	_kin_ready()


func play_hit() -> void:
	if not _dead and _t - _last_hit_time >= 0.15:
		if _hit_leaves and _tier == 0:
			_hit_leaves.restart()
		_on_kin_hit()
	super.play_hit()


func _extra_process(dt: float) -> void:
	_track_root(dt)
	_fidget_process(dt)
	_kin_process(dt)
	_face_tick()


func _on_revive() -> void:
	_rp_prev = Vector3.ZERO
	_rv_prev = Vector3.ZERO
	_racc = Vector3.ZERO
	_kin_revive()
	_face_reset()


## True when the kit is on its pure-idle fast path this frame (pose offsets written with rot() / pos() are ignored).
func is_idle_fast() -> bool:
	return not _dead and _action == &"" and _walk_w == 0.0 and _speed < 0.3 and _hit_t >= HIT_LEN \
		and _level_t >= LEVEL_LEN


## Root acceleration this frame (model space, m/s^2): x sideways, y up, z forward. Zero on the idle fast path.
func root_accel() -> Vector3:
	return _racc


func _track_root(dt: float) -> void:
	if dt <= 0.0:
		return
	var p: Vector3 = Vector3.ZERO if is_idle_fast() else _off_pos[P_ROOT]
	var v: Vector3 = (p - _rp_prev) / dt
	_racc = ((v - _rv_prev) / dt).clamp(Vector3(-60, -60, -60), Vector3(60, 60, 60))
	_rp_prev = p
	_rv_prev = v


## Idle fidget: a private action id the kit's timeline ignores (it only advances _action_t); posed and ended here.
func _fidget_process(dt: float) -> void:
	if _action == &"fidget":
		if _dead or _speed >= 0.3:
			_action = &""
			return
		var length := _pose_fidget(_action_t)
		if _action_t >= length:
			_action = &""
		return
	if fidget_every <= 0.0 or _dead or _action != &"" or _speed >= 0.3 or _tier != 0 or _carrying:
		return
	_fidget_wait -= dt
	if _fidget_wait <= 0.0:
		_fidget_wait = _next_fidget()
		_action = &"fidget"
		_action_t = 0.0


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


# ================================================================ subclass hooks

## After the parts are merged (grab keep_separate nodes here).
func _kin_ready() -> void:
	pass


## Per-frame extras (after the body pose; rot() / pos() apply only when not is_idle_fast()).
func _kin_process(_dt: float) -> void:
	pass


## A hit landed (rate-limited like the kit's flinch).
func _on_kin_hit() -> void:
	pass


func _kin_revive() -> void:
	pass


## Idle fidget pose at time t (write with rot() / pos()); return its length (s). Base: a slow look around.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.4, 0.9, 1.4, 1.0, 1.0)
	rot(P_HEAD, Vector3(-6.0 * DEG * k, 22.0 * DEG * k, 0))
	return 1.4
