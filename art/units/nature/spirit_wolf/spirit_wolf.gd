extends MountModel
## Spirit Wolf (titans-2.md 5.6, the Nature summon: Maelis / the Wildcaller's "Call the Pack", 20 s, not commandable):
## the unit's model_scene. A forest spirit in wolf shape, ~1.9 m nose to tail, shoulders ~0.95 m: a BARK-BROWN body of
## grained wood-fur, a PALE HEARTWOOD MASK down the long muzzle, a PALE MOSS MANE along the neck and shoulders (the 40 m
## cap), a TEAM LEAF MANTLE of broad leaves over the shoulders (nature_cloth: the team colour, top-facing), tall pointed
## ears, glowing sap-green eyes and a glowing SEED in the chest (the spirit's heart), a long brush of a tail ending in a
## tuft of pale leaves. Apart from the Direwolf (a grey horse-sized neutral wolf, no glow) and the Grave Hound (Shadow,
## near-black bone) by the brown wood and pale moss, the leaf mantle and the green glow; apart from the Nature riders by
## having no rider at all.
## Palette (Nature in-game fix, under_90.md B): bark-brown / pale heartwood / pale moss, green only on the team mantle.
## Glow points: the eyes (CreatureFaceRig irises, host mode inside the merged head) and the chest seed (nature_glow).
## Motion (MountModel + own): a light trot and a long-reaching gallop from 3.0 m/s; the spawn "coalesce" (it grows out
## of a swirl of leaves in 0.45 s when it enters the tree; skip_spawn() jumps to the end); `wolf_bite` attack (0.5 s,
## strike 0.12 s: the head drops and lunges, the jaws-forward snap, a worrying shake); a HOWL fidget; the generic hit;
## death: it staggers and rolls like a beast, then comes apart into leaves (scale-out + a leaf burst) by 1.0 s.
## Budget (unit / soldier: <= 14 draws, 2500 vertices + the face allowance): 8 draw instances (Body, Head, 4 legs, Tail,
## blob), 2 one-shot particle systems (the spawn swirl, the death leaves), 0 lights.

signal spawned

const OWN := "res://art/units/nature/spirit_wolf/materials/"
const NAT := "res://art/units/nature/materials/"
const BLOB_TINT := Color(0.05, 0.05, 0.02, 0.5)
const LIFE := Vector3(0.50, 1.0, 0.22)
const SPAWN_LEN := 0.45

const BC := Vector3(0, 0.72, -0.05)
const SY := 1.15
const BARREL_Z: Array[float] = [-0.60, -0.54, -0.38, -0.08, 0.24, 0.46, 0.56, 0.60]
const BARREL_R: Array[float] = [0.00, 0.17, 0.235, 0.25, 0.26, 0.23, 0.15, 0.00]
const CHEST_C := Vector3(0, 0.74, 0.32)
const CHEST_R := Vector3(0.23, 0.29, 0.24)
const SKULL_C := Vector3(0, 1.00, 0.70)
const SKULL_S := Vector3(0.92, 0.86, 1.10)
const SKULL_R := 0.135
const TAIL: Array[Vector3] = [Vector3(0, 0.82, -0.56), Vector3(0, 0.76, -0.78), Vector3(0, 0.66, -0.98),
	Vector3(0, 0.60, -1.14)]
const TAIL_R: Array[float] = [0.07, 0.11, 0.10, 0.06]

var _face: CreatureFaceRig
var _spawn_fx: GPUParticles3D
var _leaf_fx: GPUParticles3D
var _life_v: float = -1.0
var _spawn_done: bool = false
var _leaves_out: bool = false


# ================================================================ public hooks

## Plays the coalesce now (automatic when the wolf enters the tree).
func play_spawn() -> void:
	if _dead:
		return
	_action = &"spawn"
	_action_t = 0.0
	_spawn_done = false
	if _spawn_fx and _tier < 2:
		_spawn_fx.restart()
	set_process(true)


## Jumps to the end of the coalesce (tools, cinematics).
func skip_spawn() -> void:
	if _action == &"spawn":
		_action = &""
	_spawn_done = true
	_force_write = true


func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


# ================================================================ build

func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "spirit_wolf", face_style())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	add_sculpt($Root/Mount/Tail, _tail_sculpt)
	ensure_shadow_blob(0.5, BLOB_TINT)
	_shadow.scale = Vector3(1.5, 1.0, 3.0)
	_shadow.position = Vector3(0, 0.02, -0.05)
	# the spawn swirl (leaves rising in a spiral) and the death leaves (the spirit comes apart)
	_spawn_fx = NatureModel.make_petals(Color(0.70, 0.66, 0.36), 10, 0.7, 0.45, -1.2, 0.14, true)
	_spawn_fx.name = "SpawnLeaves"
	_spawn_fx.position = Vector3(0, 0.3, 0)
	$Fx.add_child(_spawn_fx)
	_leaf_fx = NatureModel.make_petals(Color(0.62, 0.50, 0.26), 12, 1.0, 0.45, 1.2, 0.15, true)
	_leaf_fx.name = "DeathLeaves"
	_leaf_fx.position = Vector3(0, 0.7, 0)
	$Fx.add_child(_leaf_fx)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("sw_") else NAT) + name + ".tres")


static func spike_mesh(sides: int = 3) -> Mesh:
	var key := "t3_spike_%d" % sides
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apex := Vector3(0, 1, 0)
	for i: int in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var p0 := Vector3(sin(a0), 0, cos(a0))
		var p1 := Vector3(sin(a1), 0, cos(a1))
		var n := (p1 - p0).cross(apex - p0).normalized()
		if n.dot(p0 + p1) < 0.0:
			n = -n
		var b := p1
		var c := apex
		if (p1 - p0).cross(apex - p0).dot(n) > 0.0:
			b = apex
			c = p1
		for v: Vector3 in [p0, b, c]:
			st.set_normal(n)
			st.add_vertex(v)
	return _cached(key, st.commit())


static func _blob(s: Dictionary, mat: Material, c: Vector3, r: Vector3, seg: int = 8, rings: int = 4,
		rot_deg: Vector3 = Vector3.ZERO) -> void:
	sculpt_put(s, sphere(1.0, seg, rings), mat, c, rot_deg, r)


## A flat leaf-lens (NatureModel.leaf_mesh) from `base` along `dir`, its face toward `nrm`; size = (width, thick, length).
static func _lens(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, nrm: Vector3, size: Vector3) -> void:
	var z := dir.normalized()
	var y := (nrm - z * nrm.dot(z)).normalized()
	var x := y.cross(z)
	sculpt_add(s, NatureModel.leaf_mesh(), Transform3D(Basis(x * size.x, y * size.y, z * size.z), base + z * size.z * 0.5), mat)


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var bark := m("sw_bark")
	var grain := m("sw_grain")
	var moss := m("nature_moss")
	var cloth := m("nature_cloth")
	var cdark := m("nature_cloth_dark")
	var glow := m("nature_glow")
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	sculpt_add(s, lathe_mesh("sw_barrel_v1", prof, 8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis.from_scale(Vector3(1, 1, SY)), BC), bark)
	_blob(s, bark, CHEST_C, CHEST_R)
	_blob(s, bark, Vector3(0, 0.76, -0.44), Vector3(0.22, 0.24, 0.22), 7, 3)
	# carved heartwood markings: a pale spiral ridge along each flank (the spirit's grain)
	var mask := m("nature_sec_sprigling")
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, tube_mesh("sw_grain_%s_v2" % sx, PackedVector3Array([Vector3(0.20 * sx, 0.90, 0.26),
			Vector3(0.262 * sx, 0.78, 0.04), Vector3(0.25 * sx, 0.70, -0.20), Vector3(0.20 * sx, 0.80, -0.42)]),
			PackedFloat32Array([0.018, 0.026, 0.024, 0.0]), 4, true), Transform3D.IDENTITY, mask)
	sculpt_add(s, tube_mesh("sw_spine_v1", PackedVector3Array([Vector3(0, 1.0, 0.12), Vector3(0, 0.99, -0.14),
		Vector3(0, 0.93, -0.40), Vector3(0, 0.86, -0.55)]), PackedFloat32Array([0.035, 0.04, 0.03, 0.0]), 4, true),
		Transform3D.IDENTITY, grain)
	# the pale moss mane: a thick shaggy ruff round the neck and over the shoulders (the 40 m cap), locks down the spine
	sculpt_fringe(s, moss, fringe_mesh("sw_mane_v2", 0.21, 0.21, 0.30, 0.30, 0.18, -140.0, 140.0, 8, 0.10, 0.03, 0.6),
		CHEST_C + Vector3(0, 0.26, 0.02))
	sculpt_fringe(s, moss, fringe_mesh("sw_ruff_v1", 0.16, 0.14, 0.22, 0.20, 0.12, -80.0, 80.0, 5, 0.08, 0.025, 0.6),
		CHEST_C + Vector3(0, 0.02, 0.16))
	for i: int in 2:
		var z: float = -0.06 - 0.22 * float(i)
		sculpt_lock(s, moss, Vector3(0, 1.0 - 0.04 * float(i), z), Vector3(0, -0.3, -1.0).normalized(), Vector3.UP,
			0.15 - 0.02 * float(i), 0.26, 0.05)
	# the team leaf mantle over the shoulders and the back: broad leaves fanning back (a dark team vein leaf in the
	# middle) = the top-facing team colour
	for k: int in 5:
		var u: float = (float(k) / 4.0) * 2.0 - 1.0
		var base := CHEST_C + Vector3(u * 0.17, 0.27, -0.10 - 0.05 * absf(u))
		var dir := Vector3(u * 0.75, -0.30, -0.62).normalized()
		_lens(s, cdark if k == 2 else cloth, base, dir, Vector3(u * 0.45, 1.0, 0.0), Vector3(0.28, 0.05, 0.46))
	# the glowing seed in the chest (the spirit's heart), in a pale heartwood socket
	sculpt_put(s, sphere(0.075, 6, 3), m("nature_sec_sprigling"), CHEST_C + Vector3(0, -0.06, 0.23), Vector3.ZERO,
		Vector3(1.1, 1.2, 0.7))
	sculpt_put(s, sphere(0.05, 6, 3), glow, CHEST_C + Vector3(0, -0.06, 0.27), Vector3.ZERO, Vector3(1.0, 1.3, 0.8))


# ================================================================ head

func _head_sculpt(s: Dictionary) -> void:
	var bark := m("sw_bark")
	var mask := m("nature_sec_sprigling")
	var dark := m("nature_bark_dark")
	var moss := m("nature_moss")
	sculpt_add(s, tube_mesh("sw_neck_v1", PackedVector3Array([Vector3(0, 0.80, 0.40), Vector3(0, 0.92, 0.54),
		Vector3(0, 0.98, 0.64)]), PackedFloat32Array([0.17, 0.14, 0.12]), 7, false), Transform3D.IDENTITY, bark)
	sculpt_put(s, sphere(SKULL_R, 8, 5), bark, SKULL_C, Vector3.ZERO, SKULL_S)
	# the long muzzle with the pale heartwood mask on top, a dark nose, a lower jaw
	sculpt_add(s, tube_mesh("sw_muzzle_v1", PackedVector3Array([Vector3(0, 0.98, 0.78), Vector3(0, 0.94, 0.92),
		Vector3(0, 0.91, 1.02)]), PackedFloat32Array([0.085, 0.065, 0.045]), 6, true), Transform3D.IDENTITY, bark)
	sculpt_put(s, sphere(0.09, 6, 2), mask, Vector3(0, 1.02, 0.86), Vector3(-14, 0, 0), Vector3(0.75, 0.40, 1.55))
	sculpt_put(s, spike_mesh(3), dark, Vector3(0, 0.93, 1.03), Vector3(-80, 0, 0), Vector3(0.03, 0.04, 0.025))
	sculpt_put(s, box(Vector3(0.07, 0.03, 0.18)), dark, Vector3(0, 0.88, 0.90), Vector3(8, 0, 0))
	# tall pointed ears (bark backs, pale moss insides) and pale cheek ruffs
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, spike_mesh(3), bark, Vector3(0.075 * sx, 1.08, 0.64), Vector3(-12, 0, -16.0 * sx), Vector3(0.06, 0.20, 0.035))
		sculpt_put(s, spike_mesh(3), moss, Vector3(0.078 * sx, 1.09, 0.665), Vector3(-12, 0, -16.0 * sx), Vector3(0.035, 0.14, 0.02))
		sculpt_lock(s, moss, Vector3(0.10 * sx, 0.96, 0.70), Vector3(0.6 * sx, -1.0, -0.3).normalized(),
			Vector3(sx, -0.2, 0.2).normalized(), 0.10, 0.13, 0.04)


static func face_spec() -> Dictionary:
	var dir := Vector3(0.62, 0.34, 0.70).normalized()
	var eye := SKULL_C + Vector3(dir.x * SKULL_R * SKULL_S.x, dir.y * SKULL_R * SKULL_S.y, dir.z * SKULL_R * SKULL_S.z)
	var out := Vector3(dir.x / SKULL_S.x, dir.y / SKULL_S.y, dir.z / SKULL_S.z).normalized()
	return CreatureFaceRig.side_eye_spec(eye, out, 0.034, Color(0.40, 0.28, 0.17), NatureFaces.EYE_SAP, 0.9)


static func face_style() -> Dictionary:
	var spec := face_spec()
	var st := FaceKit.style_from(spec)
	var r: float = spec["radius"]
	st["canvas"] = FaceKit.canvas(spec["center"], r, spec["head_mesh"], spec.get("head_scale", Vector3.ONE), Vector3.INF,
		Basis.IDENTITY, float(spec["lift"]))
	st["density"] = 6.0
	return st


# ================================================================ legs + tail

func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var bark := m("sw_bark")
	var dark := m("nature_bark_dark")
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	if front:
		sculpt_add(s, tube_mesh("sw_leg_f_v2", PackedVector3Array([Vector3(0, 0.74, 0), Vector3(0, 0.40, 0.02),
			Vector3(0, 0.08, 0.04)]), PackedFloat32Array([0.115, 0.075, 0.058]), 6, false),
			Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), bark)
	else:
		sculpt_add(s, tube_mesh("sw_leg_b_v1", PackedVector3Array([Vector3(0, 0.78, 0.02), Vector3(0, 0.48, -0.12),
			Vector3(0, 0.24, -0.06), Vector3(0, 0.08, 0.02)]), PackedFloat32Array([0.13, 0.08, 0.055, 0.05]), 6, false),
			Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), bark)
	sculpt_put(s, sphere(0.065, 6, 2), dark, Vector3(x, 0.045, z + 0.06), Vector3.ZERO, Vector3(1.0, 0.6, 1.35))


func _tail_sculpt(s: Dictionary) -> void:
	var bark := m("sw_bark")
	var moss := m("nature_moss")
	var leaf := m("nature_leaf")
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	for i: int in TAIL.size():
		pts.append(TAIL[i])
		rad.append(TAIL_R[i])
	sculpt_add(s, tube_mesh("sw_tail_v1", pts, rad, 6, false), Transform3D.IDENTITY, bark)
	var tip := TAIL[TAIL.size() - 1]
	var d := (tip - TAIL[TAIL.size() - 2]).normalized()
	for k: int in 3:
		var a := TAU * float(k) / 3.0
		var o := Vector3(cos(a), sin(a) * 0.4, 0.0)
		_lens(s, moss if k != 1 else leaf, tip - d * 0.06 + o * 0.02, (d + o * 0.5).normalized(), Vector3.UP,
			Vector3(0.10, 0.03, 0.22))


# ================================================================ motion (on top of MountModel)

func _mount_ready() -> void:
	_life_v = -1.0
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))
		_update_tier()
		_face.auto_any(self)
	if not _spawn_done:
		play_spawn()


# wolf_bite (play_attack, 0.5 s, strike 0.12 s): the head drops low and forward, the lunge, the snap, a worrying shake.
static var WB_HEAD := PackedFloat32Array([0.0, 0.0, 0, 0.07, -14.0, 1, 0.12, 22.0, 2, 0.24, 14.0, 0, 0.5, 0.0, 0])
static var WB_HEAD_Y := PackedFloat32Array([0.0, 0.0, 0, 0.14, 0.0, 0, 0.20, 16.0, 1, 0.28, -14.0, 0, 0.36, 8.0, 0,
	0.5, 0.0, 0])
static var WB_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.06, 1, 0.12, 0.30, 2, 0.26, 0.14, 0, 0.5, 0.0, 0])
static var WB_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.06, 1, 0.14, -0.03, 0, 0.5, 0.0, 0])
static var WB_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.07, 10.0, 1, 0.12, -24.0, 2, 0.30, -8.0, 0, 0.5, 0.0, 0])
static var WB_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.12, 20.0, 2, 0.30, 6.0, 0, 0.5, 0.0, 0])


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"wolf_bite":
		return super(prev, t)
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, WB_HEAD) * DEG, _mkf(t, WB_HEAD_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, _mkf(t, WB_ROOT_Y), _mkf(t, WB_ROOT_Z)))
	rot(P_MOUNT, Vector3(_mkf(t, WB_HEAD) * 0.3 * DEG, 0, 0))
	var f := _mkf(t, WB_LEG_F) * DEG * (1.0 - 0.6 * _walk_w)
	var b := _mkf(t, WB_LEG_B) * DEG * (1.0 - 0.6 * _walk_w)
	rot(P_LEG_FL, Vector3(f, 0, 0)); rot(P_LEG_FR, Vector3(f * 0.85, 0, 0))
	rot(P_LEG_BL, Vector3(b, 0, 0)); rot(P_LEG_BR, Vector3(b * 0.9, 0, 0))
	xrot(X_TAIL, Vector3(-_mkf(t, WB_HEAD) * 1.2 * DEG, 0, 0))
	if prev < 0.12 and t >= 0.12:
		_on_action_event(&"release")
	return t < 0.5


## The howl: the head thrown back, the tail low, a tremolo; the chest seed and the eyes flare.
func _pose_fidget(t: float) -> float:
	var up := _k3(t, 0.0, 0.35, 1.35, 1.8, 1.0, 1.0)
	var trem: float = sin(t * TAU * 6.0) * 2.0 * up
	rot(P_MOUNT_HEAD, Vector3((-46.0 * up + trem) * DEG, 0, 0))
	rot(P_MOUNT, Vector3(-4.0 * DEG * up, 0, 0))
	xrot(X_TAIL, Vector3(-18.0 * DEG * up, 0, 0))
	if _fidget_prev < 0.5 and t >= 0.5:
		_flare = maxf(_flare, 0.8)
		_on_mount_event(&"fidget_snort")
	return 1.8


## The coalesce (spawn) and the death: the spirit comes apart into leaves (life flash, scale-out, a leaf burst).
func _mount_process(_dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if _action == &"spawn":
		var u: float = clampf(_action_t / SPAWN_LEN, 0.0, 1.0)
		var e: float = 1.0 + 2.2 * pow(u - 1.0, 3.0) + 1.2 * pow(u - 1.0, 2.0)   # ease-out with a small overshoot
		_root_scale *= Vector3.ONE * maxf(0.05, e)
		_write_life(0.45 * (1.0 - u))
		if _action_t >= SPAWN_LEN:
			_action = &""
			_spawn_done = true
			_write_life(0.0)
			spawned.emit()
		return
	if not _dead:
		return
	var t := _death_t
	_write_life(0.55 * smoothstep(0.0, 0.1, t) * (1.0 - smoothstep(0.35, 0.7, t)))
	if t >= 0.45:
		if not _leaves_out:
			_leaves_out = true
			if _leaf_fx and _tier < 2:
				_leaf_fx.restart()
		var c: float = smoothstep(0.45, 0.95, t)
		_root_scale *= Vector3.ONE * maxf(0.02, 1.0 - c)


func _write_life(v: float) -> void:
	v = snappedf(v, 0.05)
	if v == _life_v:
		return
	_life_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", LIFE if v > 0.0 else WHITE)


func _mount_revive() -> void:
	if _face:
		_face.reset()
	_leaves_out = false
	_life_v = -1.0
	_write_life(0.0)
