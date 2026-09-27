extends CharacterModel
## The trade caravan (market-trade.md 4.2 / 9 row 10.V5 / 12; task 10.V5). One scene for every kingdom.
## A two-wheeled covered wagon pulled by a stocky, shaggy, short-horned draught ox (brass-capped horns, a mop of
## forelock over its eyes, a brass bell under the collar), driven by a round, ginger-bearded drover in a wide hat.
## Team colour (`caravan_cloth`, recoloured by the kit's set_team_color): the canvas cover, the rear pennant, the ox's
## rump blanket, the drover's scarf and hat band.
## `set_loaded(true)`: the open rear deck fills (two strapped crates on the tailboard carrying the brass-bound strongbox,
## its lid thrown back on a heap of glowing coins, and a sack) and the front lantern lights up (glow (1.0, 0.85, 0.3) 2.5);
## `set_loaded(false)`: bare planks + a rope coil, the lantern glass goes dull. Readable at 40 m by the two glows.
## Motion: ox trot (4 legs), wheels spin from the real ground speed, wagon rocks, lantern on a damped pendulum,
## pennant flaps, drover looks around; ox head toss every ~7 s. Hit: the whole rig jolts back, the ox throws its head
## up, white flash (wagon, ox, drover). Death (`topple`, 1.0 s): the ox buckles to the ground, a wheel gives way and
## the wagon tips onto its left side, the lantern goes out, a dust puff, then everything sinks. Never attacks.
## Face = local +Z (the ox walks ahead, the wagon trails behind). Pivots: Hips = the axle (both wheels, spins),
## Chest = the wagon (rocks about the axle), Chest/Head = the drover's head, Mount = the ox body, Mount/Leg* = its legs,
## Mount/Head = its head. Budget: 13 authored meshes (blob included), 13 draw instances after the merge (9 merged
## pivots + Cargo, Lantern, Pennant, blob; + the one-shot dust emitter = 14), 0 lights, 5 materials (this folder)
## + the kit's shared blob.

const MAT_PATH := "res://art/units/caravan/materials/caravan_"
const HIT_KICK := Vector2(-4.0, 3.0)
const BUMP_LEN := 0.4
const LANTERN_DARK := -0.13
## Lit lantern glow_boost: 2.5 x 1.4 = 3.5 effective energy, the halo range of art-keep 0.4 (orbs / gems 2.5-4.0).
const LANTERN_LIT := 1.4

# Model-space layout (feet origin, +Z = the ox's nose). Wagon z -1.53 .. 0.41, ox z 0.36 .. 1.80.
const AXLE := Vector3(0.0, 0.46, -0.72)
const WHEEL_R := 0.46
const WHEEL_X := 0.72
const BOARD_TOP := 0.94
const CAN_Z0 := -1.00          # canopy rear edge (at the boards)
const CAN_Z1 := -0.28          # canopy front edge
const CAN_RX := 0.64
const CAN_RY := 0.96           # canopy top = 0.94 + 0.96 = 1.90
const NECK := Vector3(0.0, 1.50, 0.04)
const OX_C := Vector3(0.0, 0.90, 0.94)
const OX_R := Vector3(0.42, 0.40, 0.52)
const LANTERN_AT := Vector3(0.66, 2.03, 0.22)
const PENNANT_AT := Vector3(-0.66, 2.16, -1.02)

static var _own_mats: Dictionary = {}
static var _meshes: Dictionary = {}
static var _dust_pm: ParticleProcessMaterial
static var _dust_quad: QuadMesh

var _loaded: bool = false
var _cargo: MeshInstance3D
var _lantern: MeshInstance3D
var _pennant: MeshInstance3D
var _dust: GPUParticles3D

var _wheel_a: float = 0.0
var _lan_a: Vector2 = Vector2.ZERO
var _lan_v: Vector2 = Vector2.ZERO
var _lan_written: Vector2 = Vector2(99, 99)
var _pen_written: float = 99.0
var _lan_glow_written: float = -1.0
var _cargo_glow_written: float = -1.0
var _bump_t: float = 99.0
# idle values (computed once per frame, no allocation)
var _iv_breath: float = 0.0
var _iv_head: float = 0.0
var _iv_look: float = 0.0


static func _mat(name: StringName) -> Material:
	if not _own_mats.has(name):
		_own_mats[name] = load(MAT_PATH + String(name) + ".tres")
	return _own_mats[name]


# ================================================================ hooks

## Loaded = the rear deck full of goods + the lantern lit. Safe before _ready (cached and applied).
func set_loaded(on: bool) -> void:
	if on == _loaded:
		return
	_loaded = on
	if _cargo:
		_cargo.visible = on
		_bump_t = 0.0
	_update_glow()


func is_showing_cargo() -> bool:
	return _loaded


func play_hit() -> void:
	var before := _hit_t
	super()
	if _hit_t < before:
		_lan_v += HIT_KICK


# ================================================================ parts

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var mount: Node3D = $Root/Mount
	var mhead: Node3D = $Root/Mount/Head
	var fx: Node3D = $Fx
	add_part(hips, _wheels_mesh(), null, Vector3.ZERO)
	add_part(chest, _wagon_mesh(), null, Vector3.ZERO)
	add_part(head, _drover_head_mesh(), null, Vector3.ZERO)
	add_part(mount, _ox_body_mesh(), null, Vector3.ZERO)
	add_part(mhead, _ox_head_mesh(), null, Vector3.ZERO)
	for leg: String in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var p: Node3D = mount.get_node(leg)
		add_part(p, _leg_mesh(model_origin(p)), null, Vector3.ZERO)
	# Toggled / animated on their own (keep_separate).
	_cargo = add_part(chest, _cargo_mesh(), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Cargo")
	_cargo.set_meta(&"own_glow", true)
	_lantern = add_part(chest, _lantern_mesh(), null, LANTERN_AT, Vector3.ZERO, Vector3.ONE, true, "Lantern")
	_lantern.set_meta(&"own_glow", true)
	_pennant = add_part(chest, _pennant_mesh(), null, PENNANT_AT, Vector3.ZERO, Vector3.ONE, true, "Pennant")
	_dust = _make_dust()
	_dust.name = "DeathDust"
	_dust.set_meta(&"death_fx", true)
	_dust.position = Vector3(0.0, 0.25, 0.1)
	fx.add_child(_dust)
	ensure_shadow_blob(0.8)


func _after_ready() -> void:
	_cargo.visible = _loaded
	_shadow.scale = Vector3(1.95, 1.0, 4.1)      # a long oval under ox + wagon
	for i: int in [P_MOUNT, P_MOUNT_HEAD, P_HIPS]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
	var wheels: MeshInstance3D = _merged_nodes.get(P_HIPS)
	if wheels:
		wheels.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var drover: MeshInstance3D = _merged_nodes.get(P_HEAD)
	if drover:
		drover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lan_glow_written = -1.0
	_cargo_glow_written = -1.0
	_update_glow()


func _on_revive() -> void:
	_lan_a = Vector2.ZERO
	_lan_v = Vector2.ZERO
	_lan_written = Vector2(99, 99)
	_pen_written = 99.0
	_bump_t = 99.0
	_lan_glow_written = -1.0
	_cargo_glow_written = -1.0
	if _cargo:
		_cargo.visible = _loaded
	if _lantern:
		_lantern.rotation = Vector3.ZERO
	_update_glow()


# ================================================================ animation

func _animate(dt: float) -> void:
	if _bump_t < BUMP_LEN:
		_force_write = true        # keeps the full pose path while the load bump plays
	super(dt)


func _calc_idle() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	_iv_breath = 0.014 * sin(ph)
	var ct: float = fmod(_t + _phase_off * 2.3, 7.5)
	_iv_head = 4.0 * DEG * sin(0.7 * ph) + DEG * _k3(ct, 0.0, 0.3, 0.5, 1.0, -16.0, 5.0)
	_iv_look = 22.0 * DEG * sin(0.45 * ph + 1.0)


func _idle_fast() -> void:
	_calc_idle()
	_write_pos(P_MOUNT, _rest_pos[P_MOUNT] + Vector3(0.0, _iv_breath, 0.0))
	_write_rot(P_MOUNT_HEAD, _rest_rot[P_MOUNT_HEAD] + Vector3(_iv_head, 0.0, 0.0))
	if _tier == 0:
		_write_rot(P_HEAD, _rest_rot[P_HEAD] + Vector3(0.0, _iv_look, 0.0))


func _pose_idle(w: float) -> void:
	_calc_idle()
	pos(P_MOUNT, Vector3(0.0, _iv_breath * w, 0.0))
	rot(P_MOUNT_HEAD, Vector3(_iv_head * w, 0.0, 0.0))
	rot(P_HEAD, Vector3(0.0, _iv_look * w, 0.0))


## Ox trot (FL + BR / FR + BL), the ox bobs twice per stride and leans into the collar (more when loaded), the
## wagon rocks about its axle, the drover nods. The wheels spin in _extra_process from the real speed.
func _pose_walk(w: float, _rate: float) -> void:
	var s: float = sin(TAU * _walk_p)
	var s2: float = sin(TAU * _walk_p * 2.0)
	var q: float = 30.0 * DEG * s * w
	rot(P_LEG_FL, Vector3(q, 0, 0))
	rot(P_LEG_BR, Vector3(q, 0, 0))
	rot(P_LEG_FR, Vector3(-q, 0, 0))
	rot(P_LEG_BL, Vector3(-q, 0, 0))
	pos(P_MOUNT, Vector3(0.0, 0.045 * absf(s) * w, 0.0))
	rot(P_MOUNT, Vector3((1.5 * s2 + (5.0 if _loaded else 1.5)) * DEG * w, 0.0, 2.0 * DEG * s * w))
	rot(P_MOUNT_HEAD, Vector3(7.0 * DEG * sin(TAU * _walk_p * 2.0 + 0.9) * w, 0.0, 0.0))
	rot(P_CHEST, Vector3(0.6 * DEG * s2 * w, 0.0, 1.8 * DEG * s * w))
	pos(P_CHEST, Vector3(0.0, 0.012 * absf(s) * w, 0.0))
	rot(P_HEAD, Vector3(4.0 * DEG * sin(TAU * _walk_p * 2.0 + 1.4) * w, 0.0, 0.0))


## Caravans never attack (damage none, aggro 0): nothing to play.
func _pose_attack(_prev: float, _t_: float) -> bool:
	return false


## `topple` (1.0 s): the ox buckles (front legs fold back, hind legs forward, body drops and rolls, head down), a
## wheel gives way and the wagon tips onto its left side, glows out + dust at 0.25 s, then everything sinks.
func _pose_death(dt: float) -> void:
	if death_style != &"topple":
		super(dt)
		return
	_death_t += dt
	var t := _death_t
	var buckle: float = _ease_out(clampf(t / 0.3, 0.0, 1.0))
	rot(P_LEG_FL, Vector3(80.0 * DEG * buckle, 0, 0))
	rot(P_LEG_FR, Vector3(75.0 * DEG * buckle, 0, 0))
	rot(P_LEG_BL, Vector3(-60.0 * DEG * buckle, 0, 0))
	rot(P_LEG_BR, Vector3(-65.0 * DEG * buckle, 0, 0))
	pos(P_MOUNT, Vector3(0.0, -0.36 * buckle, 0.0))
	rot(P_MOUNT, Vector3(4.0 * DEG * buckle, 0.0, 9.0 * DEG * buckle))
	rot(P_MOUNT_HEAD, Vector3(30.0 * DEG * buckle, 0.0, 0.0))
	var tip: float = _ease_in(clampf((t - 0.12) / 0.33, 0.0, 1.0))
	rot(P_CHEST, Vector3(-5.0 * DEG * tip, 0.0, 24.0 * DEG * tip))
	rot(P_HIPS, Vector3(0.0, 0.0, 24.0 * DEG * tip))
	pos(P_CHEST, Vector3(0.0, -0.16 * tip, 0.0))
	pos(P_HIPS, Vector3(0.0, -0.16 * tip, 0.0))
	rot(P_HEAD, Vector3(25.0 * DEG * buckle, 0.0, 0.0))
	if t >= 0.25:
		_glows_dead()
	var g: float = _ease_in(clampf((t - 0.5) / 0.5, 0.0, 1.0))
	pos(P_ROOT, Vector3(0.0, -0.6 * body_height * g, 0.0))
	if _shadow:
		_shadow.transparency = clampf((t - 0.7) / 0.3, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _extra_process(dt: float) -> void:
	# Wheels: rolling without slipping (ground speed / radius); positive x turns the top toward +Z.
	if _walk_w > 0.0 and not _dead:
		_wheel_a = fmod(_wheel_a + dt * _speed * _walk_w / WHEEL_R, TAU)
	rot(P_HIPS, Vector3(_wheel_a, 0.0, 0.0))
	if _hit_t < HIT_LEN:
		var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
		rot(P_MOUNT_HEAD, Vector3(-18.0 * DEG * k, 0.0, 0.0))
		rot(P_HEAD, Vector3(-10.0 * DEG * k, 0.0, 0.0))
	if _bump_t < BUMP_LEN:
		_bump_t += dt
		pos(P_CHEST, Vector3(0.0, -0.035 * sin(PI * clampf(_bump_t / BUMP_LEN, 0.0, 1.0)), 0.0))
	_update_lantern(dt)
	_update_pennant()
	_update_glow()


## Damped pendulum (x = fore / aft, y = side), driven by the trot and kicked by hits.
func _update_lantern(dt: float) -> void:
	if _lantern == null:
		return
	var h: float = minf(dt, 0.05)
	var drive := Vector2(8.0 * DEG * sin(TAU * _walk_p * 2.0 + 0.6) * _walk_w + 1.2 * DEG * sin(_t * 1.1 + _phase_off),
		3.5 * DEG * sin(TAU * _walk_p) * _walk_w)
	if _dead:
		drive = Vector2(0.0, -20.0 * DEG)
	_lan_v += ((drive - _lan_a) * 55.0 - _lan_v * 5.0) * h
	_lan_a += _lan_v * h
	if _lan_a.distance_squared_to(_lan_written) > 1.0e-6:
		_lan_written = _lan_a
		_lantern.rotation = Vector3(_lan_a.x, 0.0, _lan_a.y)


func _update_pennant() -> void:
	if _pennant == null or _tier >= 2:
		return
	var f: float = 14.0 * DEG * sin(_t * (4.0 + 3.0 * _walk_w) + _phase_off * 2.0) * (0.5 + 0.5 * _walk_w) \
		+ 5.0 * DEG * sin(_t * 1.7 + _phase_off)
	if absf(f - _pen_written) > 0.003:
		_pen_written = f
		_pennant.rotation = Vector3(0.0, f, 0.0)


func _update_glow() -> void:
	if not _ready_done or _lantern == null:
		return
	var g := glow_level()
	# Unlit (empty or dead): a slightly negative glow_boost darkens the glass below unit_glow's 0.4 x colour floor,
	# so the lantern reads dark amber, not "half lit" (albedo 0.4 - 2.5 x 0.13 x pulse = 0.08-0.16 x colour).
	var lg: float = g * LANTERN_LIT if _loaded and g > 0.0 else LANTERN_DARK
	if lg != _lan_glow_written:
		_lan_glow_written = lg
		_lantern.set_instance_shader_parameter(&"glow_boost", lg)
	var cg: float = g
	if cg != _cargo_glow_written:
		_cargo_glow_written = cg
		_cargo.set_instance_shader_parameter(&"glow_boost", cg)


# ================================================================ mesh helpers (built once per game, cached)

static func _at(m: Mesh, p: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Array:
	return [m, Transform3D(Basis.from_euler(rot_deg * DEG).scaled_local(scl), p)]


## [cylinder, transform] from a to b (radius ra at a, rb at b).
static func _seg(a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 8) -> Array:
	var d := b - a
	var l := d.length()
	var bs: Basis
	if d.normalized().y < -0.999:
		bs = Basis(Vector3.RIGHT, PI)
	else:
		bs = Basis(Quaternion(Vector3.UP, d / l))
	return [cyl(rb, ra, 1.0, seg), Transform3D(bs.scaled_local(Vector3(1.0, l, 1.0)), (a + b) * 0.5)]


## One multi-surface ArrayMesh from [[parts, material], ...]; parts = [[Mesh, Transform3D], ...]. Cached by key.
static func _bake(key: String, groups: Array) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	for g: Array in groups:
		if (g[0] as Array).is_empty():
			continue
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays(g[0]))
		am.surface_set_material(am.get_surface_count() - 1, g[1])
	_meshes[key] = am
	return am


static func _arrays(parts: Array) -> Array:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for p: Array in parts:
		var m: Mesh = p[0]
		var xf: Transform3D = p[1]
		var nb := xf.basis.inverse().transposed()
		var arr := m.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var b0 := verts.size()
		for j: int in v.size():
			verts.append(xf * v[j])
			norms.append((nb * nr[j]).normalized())
			uvs.append(uv[j] if j < uv.size() else Vector2.ZERO)
		if ix.is_empty():
			for j: int in v.size():
				idx.append(b0 + j)
		else:
			for j: int in ix.size():
				idx.append(b0 + ix[j])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	return arrays


static func _mesh(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array,
		idx: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	if not idx.is_empty():
		arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


## Two triangles for the quad a-b-c-d, wound so their front faces the vertex normals.
static func _quad(idx: PackedInt32Array, v: PackedVector3Array, n: PackedVector3Array, a: int, b: int, c: int, d: int) -> void:
	var fn := (v[d] - v[a]).cross(v[b] - v[a])
	if fn.length_squared() < 1e-14:
		fn = (v[c] - v[b]).cross(v[d] - v[b])
	if fn.dot(n[a] + n[b] + n[c] + n[d]) >= 0.0:
		idx.append_array(PackedInt32Array([a, b, d, b, c, d]))
	else:
		idx.append_array(PackedInt32Array([a, d, b, b, d, c]))


## Grid surface p = fn(u, v) (u, v in 0..1). Normals from finite differences, oriented away from out_from(u, v).
## double_sided: a back copy with flipped normals (cloth seen from inside).
static func _grid(fn: Callable, out_from: Callable, cols: int, rows: int, double_sided: bool = false) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	const E := 0.003
	for j: int in rows + 1:
		var v := float(j) / float(rows)
		for i: int in cols + 1:
			var u := float(i) / float(cols)
			var p: Vector3 = fn.call(u, v)
			var du: Vector3 = fn.call(minf(u + E, 1.0), v) - fn.call(maxf(u - E, 0.0), v)
			var dv: Vector3 = fn.call(u, minf(v + E, 1.0)) - fn.call(u, maxf(v - E, 0.0))
			var nn := dv.cross(du)
			var o: Vector3 = p - (out_from.call(u, v) as Vector3)
			if nn.length_squared() < 1e-12:
				nn = o
			nn = nn.normalized()
			if nn.dot(o) < 0.0:
				nn = -nn
			verts.append(p)
			norms.append(nn)
			uvs.append(Vector2(u, v))
	var sides := 2 if double_sided else 1
	var nv := verts.size()
	if double_sided:
		for k: int in nv:
			verts.append(verts[k])
			norms.append(-norms[k])
			uvs.append(uvs[k])
	for s: int in sides:
		for j: int in rows:
			for i: int in cols:
				var q0 := s * nv + j * (cols + 1) + i
				_quad(idx, verts, norms, q0, q0 + 1, q0 + cols + 2, q0 + cols + 1)
	return _mesh(verts, norms, uvs, idx)


## Catmull-Rom point on pts at v (0..1).
static func _cr(pts: Array[Vector3], v: float) -> Vector3:
	var n := pts.size()
	var f := clampf(v, 0.0, 1.0) * float(n - 1)
	var i := mini(int(f), n - 2)
	var t := f - float(i)
	var p0 := pts[maxi(i - 1, 0)]
	var p1 := pts[i]
	var p2 := pts[i + 1]
	var p3 := pts[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


## A tapered tube along a Catmull-Rom curve. rfn(v) -> radius.
static func _tube(pts: Array[Vector3], rfn: Callable, ring: int, samples: int) -> ArrayMesh:
	var frame := func(v: float) -> Array:
		var t := (_cr(pts, minf(v + 0.01, 1.0)) - _cr(pts, maxf(v - 0.01, 0.0))).normalized()
		var ref := Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.FORWARD
		var nn := t.cross(ref).normalized()
		return [nn, t.cross(nn).normalized()]
	var fn := func(u: float, v: float) -> Vector3:
		var fr: Array = frame.call(v)
		var a := TAU * u
		return _cr(pts, v) + (float(rfn.call(v))) * ((fr[0] as Vector3) * cos(a) + (fr[1] as Vector3) * sin(a))
	var centre := func(_u: float, v: float) -> Vector3:
		return _cr(pts, v)
	return _grid(fn, centre, ring, samples)


## Lumpy ellipsoid (shaggy fur / sacks): centre c, radii r, lump amplitude, seed.
static func _lumpy(c: Vector3, r: Vector3, cols: int, rows: int, lump: float, seed: float) -> ArrayMesh:
	var fn := func(u: float, v: float) -> Vector3:
		var a := TAU * u
		var th := PI * v
		var k := 1.0 + lump * sin(5.0 * a + seed) * sin(3.0 * th + seed * 0.7) + lump * 0.6 * sin(9.0 * a + 2.0 * seed) * sin(th)
		return c + Vector3(sin(th) * sin(a) * r.x * k, cos(th) * r.y * k, sin(th) * cos(a) * r.z * k)
	var ctr := func(_u: float, _v: float) -> Vector3:
		return c
	return _grid(fn, ctr, cols, rows)


## Shaggy fringe / dome: from a ring at y_top (radii r_top; zero = a closed dome) down to a dagged hem (radii r_hem).
## hem_fn(a) gives the hem height by angle (a = 0 faces +Z); `dags` pointed locks of `depth` hang below it.
static func _fringe(c: Vector3, y_top: float, r_top: Vector2, r_hem: Vector2, hem_fn: Callable, dags: int,
		depth: float, rows: int) -> ArrayMesh:
	var fn := func(u: float, v: float) -> Vector3:
		var a := TAU * u
		var tip := pow(absf(cos(float(dags) * 0.5 * a)), 3.0)
		var yh: float = float(hem_fn.call(a)) - depth * tip
		var rr := r_top.lerp(r_hem, pow(v, 0.6)) * (1.0 + 0.05 * tip * v)
		return Vector3(c.x + sin(a) * rr.x, lerpf(y_top, yh, v), c.z + cos(a) * rr.y)
	var ctr := func(u: float, v: float) -> Vector3:
		var p: Vector3 = fn.call(u, v)
		return Vector3(c.x, p.y - 0.15, c.z)
	return _grid(fn, ctr, dags * 4, rows)


# ================================================================ meshes (model space)

## Both wheels (spin about the axle = the Hips pivot): wooden rim, brass tyre, 6 spokes, brass hub.
static func _wheels_mesh() -> ArrayMesh:
	if _meshes.has("cv_wheels"):
		return _meshes["cv_wheels"]
	var wood: Array = []
	var brass: Array = []
	for sx: float in [-1.0, 1.0]:
		var c := Vector3(WHEEL_X * sx, AXLE.y, AXLE.z)
		wood.append(_at(torus(0.345, 0.43, 12), c, Vector3(0, 0, 90), Vector3(1.0, 1.35, 1.0)))
		for k: int in 3:
			wood.append(_at(box(Vector3(0.05, 0.72, 0.055)), c, Vector3(60.0 * k, 0, 0)))
		brass.append(_at(torus(0.425, 0.465, 12), c, Vector3(0, 0, 90), Vector3(1.0, 2.2, 1.0)))
		brass.append(_at(cyl(0.085, 0.085, 0.17, 6), c, Vector3(0, 0, 90)))
	return _bake("cv_wheels", [[wood, _mat(&"wood")], [brass, _mat(&"brass")]])


## Canopy point: u across the arch (0 = left board, 1 = right board), v from the rear edge (0) to the front (1).
## End hoops lean outward at the top, the cloth sags a little between the three hoops.
static func _canopy_point(u: float, v: float, grow: float = 1.0) -> Vector3:
	var a := lerpf(-PI * 0.5, PI * 0.5, u)
	var c := cos(a)
	var sag := 1.0 - 0.035 * sin(PI * fmod(v * 2.0, 1.0)) if v < 1.0 else 1.0
	var flare := 1.0 + 0.06 * pow(absf(v * 2.0 - 1.0), 4.0)
	var k := sag * flare * grow
	var z := lerpf(CAN_Z0 - 0.10 * c, CAN_Z1 + 0.07 * c, v)
	return Vector3(CAN_RX * k * sin(a), BOARD_TOP + CAN_RY * k * c, z)


## The wagon (Chest pivot, rocks about the axle): bed, boards, axle, shafts, bench, footboard, canvas cover with its
## hoops and puckered back, lantern pole, pennant pole, rope coil, brass corner caps, and the drover's body.
static func _wagon_mesh() -> ArrayMesh:
	if _meshes.has("cv_wagon"):
		return _meshes["cv_wagon"]
	var wood: Array = []
	var brass: Array = []
	var cloth: Array = []
	var fur: Array = []
	# -- bed
	wood.append(_at(box(Vector3(1.16, 0.10, 1.40)), Vector3(0, 0.61, -0.74)))
	for sx: float in [-1.0, 1.0]:
		wood.append(_at(box(Vector3(0.07, 0.28, 1.40)), Vector3(0.585 * sx, 0.80, -0.74)))
		brass.append(_at(box(Vector3(0.10, 0.08, 0.10)), Vector3(0.59 * sx, 0.95, -1.42)))
		brass.append(_at(box(Vector3(0.10, 0.08, 0.10)), Vector3(0.59 * sx, 0.95, -0.06)))
		# shafts from under the bed to the ox's collar, brass tips
		var a := Vector3(0.46 * sx, 0.58, -0.30)
		var b := Vector3(0.56 * sx, 1.00, 1.26)
		wood.append(_seg(a, b, 0.05, 0.042, 5))
		brass.append(_seg(b - (b - a).normalized() * 0.06, b + (b - a).normalized() * 0.03, 0.055, 0.05, 5))
	wood.append(_at(box(Vector3(1.24, 0.30, 0.07)), Vector3(0, 0.79, -0.05)))          # front board
	wood.append(_at(box(Vector3(1.24, 0.14, 0.07)), Vector3(0, 0.73, -1.44)))          # low tailboard
	wood.append(_at(box(Vector3(1.40, 0.10, 0.16)), Vector3(0, 0.49, AXLE.z)))          # axle block (reads as the axle)
	wood.append(_at(box(Vector3(0.92, 0.12, 0.36)), Vector3(0, 0.96, 0.03)))            # bench
	wood.append(_at(box(Vector3(0.90, 0.05, 0.24)), Vector3(0, 0.70, 0.22)))            # footboard
	wood.append(_at(torus(0.07, 0.16, 8), Vector3(0.24, 0.69, -1.22), Vector3.ZERO, Vector3(1, 1.6, 1)))  # rope coil
	# -- canvas + hoops + puckered back
	var can := _grid(func(u: float, v: float) -> Vector3: return _canopy_point(u, v),
			func(_u: float, v: float) -> Vector3: return Vector3(0, BOARD_TOP, lerpf(CAN_Z0, CAN_Z1, v)), 12, 6, true)
	cloth.append([can, Transform3D()])
	var back_c := Vector3(0.0, 1.30, CAN_Z0 - 0.06)
	var pucker := func(u: float, w: float) -> Vector3:
		var e := _canopy_point(u, 0.0)
		var o := back_c + (e - back_c) * 0.5
		o.z = e.z - 0.07
		var p := e.lerp(o, w)
		p.z += 0.02 * sin(PI * w)
		return p
	cloth.append([_grid(pucker, func(_u: float, _w: float) -> Vector3: return back_c + Vector3(0, 0, 0.4), 12, 2, true),
		Transform3D()])
	for hv: float in [0.0, 0.5, 1.0]:
		var pts: Array[Vector3] = []
		for i: int in 7:
			pts.append(_canopy_point(float(i) / 6.0, hv, 1.03))
		wood.append([_tube(pts, func(_v: float) -> float: return 0.035, 4, 8), Transform3D()])
	# -- lantern pole (front right, crook over the ox's rump) + pennant pole (rear left)
	var lp: Array[Vector3] = [Vector3(0.66, 0.62, -0.04), Vector3(0.66, 1.55, -0.04), Vector3(0.66, 2.02, -0.01),
		Vector3(0.66, 2.14, 0.10), LANTERN_AT + Vector3(0, 0.03, 0)]
	wood.append([_tube(lp, func(_v: float) -> float: return 0.035, 4, 8), Transform3D()])
	brass.append(_at(box(Vector3(0.09, 0.14, 0.09)), Vector3(0.64, 0.80, -0.04)))       # pole clamp
	wood.append(_seg(Vector3(-0.66, 0.66, -1.02), Vector3(-0.66, 2.22, -1.02), 0.032, 0.026, 5))
	brass.append(_at(sphere(0.055, 6, 3), Vector3(-0.66, 2.25, -1.02)))
	brass.append(_at(box(Vector3(0.09, 0.14, 0.09)), Vector3(-0.64, 0.80, -1.02)))
	# -- the drover: round coat body + belly, seated legs on the footboard, arms forward on the reins
	fur.append(_at(cyl(0.15, 0.24, 0.46, 8), Vector3(0, 1.25, 0.0)))
	fur.append(_at(sphere(0.19, 8, 4), Vector3(0, 1.17, 0.08), Vector3.ZERO, Vector3(1.0, 0.9, 0.85)))
	cloth.append(_at(torus(0.08, 0.17, 10), Vector3(0, 1.47, 0.01), Vector3(-8, 0, 0), Vector3(1, 1.4, 1)))
	for sx: float in [-1.0, 1.0]:
		fur.append(_seg(Vector3(0.10 * sx, 1.07, 0.04), Vector3(0.12 * sx, 1.05, 0.24), 0.08, 0.07, 5))
		fur.append(_seg(Vector3(0.12 * sx, 1.05, 0.24), Vector3(0.16 * sx, 0.78, 0.25), 0.065, 0.06, 5))
		wood.append(_at(box(Vector3(0.13, 0.09, 0.22)), Vector3(0.16 * sx, 0.77, 0.29)))
		var sh := Vector3(0.20 * sx, 1.40, 0.0)
		var el := Vector3(0.22 * sx, 1.21, 0.13)
		var hd := Vector3(0.15 * sx, 1.19, 0.32)
		fur.append(_at(sphere(0.085, 6, 3), sh))
		fur.append(_seg(sh, el, 0.07, 0.065, 5))
		fur.append(_seg(el, hd, 0.062, 0.055, 5))
		brass.append(_at(sphere(0.065, 6, 3), hd))
		wood.append(_seg(hd + Vector3(0, -0.02, 0.04), Vector3(0.17 * sx, 0.98, 1.44), 0.016, 0.016, 3))  # reins
	return _bake("cv_wagon", [[wood, _mat(&"wood")], [cloth, _mat(&"cloth")], [fur, _mat(&"fur")],
		[brass, _mat(&"brass")]])


## The drover's head (Chest/Head pivot): tanned face, big nose, bushy ginger beard, wide hat with a team band.
static func _drover_head_mesh() -> ArrayMesh:
	if _meshes.has("cv_drover"):
		return _meshes["cv_drover"]
	return _bake("cv_drover", [
		[[_at(sphere(0.14, 8, 5), Vector3(0, 1.61, 0.05)), _at(sphere(0.055, 6, 3), Vector3(0, 1.60, 0.195))],
			_mat(&"brass")],
		[[_at(cyl(0.14, 0.03, 0.26, 7), Vector3(0, 1.45, 0.13), Vector3(18, 0, 0)),
			_at(box(Vector3(0.20, 0.05, 0.06)), Vector3(0, 1.555, 0.18)),
			_at(cyl(0.27, 0.27, 0.04, 10), Vector3(0, 1.72, 0.04), Vector3(-6, 0, 0)),
			_at(cyl(0.12, 0.145, 0.17, 8), Vector3(0, 1.81, 0.03))], _mat(&"wood")],
		[[_at(cyl(0.152, 0.152, 0.05, 8, false), Vector3(0, 1.765, 0.03))], _mat(&"cloth")]])


## The ox body (Mount pivot): lumpy barrel, a shaggy shoulder mane (the hump), a dagged fur skirt hiding the upper
## legs, a tufted tail, the wooden collar with brass hame knobs and a brass bell, and a team blanket on the rump.
static func _ox_body_mesh() -> ArrayMesh:
	if _meshes.has("cv_ox"):
		return _meshes["cv_ox"]
	var body := _lumpy(OX_C, OX_R, 16, 8, 0.045, 1.3)
	var mane := _fringe(Vector3(0, 0, 1.12), 1.42, Vector2.ZERO, Vector2(0.47, 0.40),
			func(a: float) -> float: return 1.00 + 0.06 * cos(a), 10, 0.09, 3)
	var skirt := _fringe(Vector3(0, 0, OX_C.z), 1.00, Vector2(0.40, 0.49), Vector2(0.48, 0.58),
			func(_a: float) -> float: return 0.46, 14, 0.10, 2)
	var tail: Array[Vector3] = [Vector3(0, 1.08, 0.46), Vector3(0, 1.02, 0.39), Vector3(0, 0.85, 0.37), Vector3(0, 0.70, 0.38)]
	# rump blanket: drapes over the back behind the mane, brass tassels at its corners
	var blanket := func(u: float, v: float) -> Vector3:
		var ph := lerpf(-68.0, 68.0, u) * DEG
		var z := lerpf(0.50, 0.76, v)
		var s := sqrt(maxf(0.0, 1.0 - pow((z - OX_C.z) / OX_R.z, 2.0)))
		return Vector3(sin(ph) * OX_R.x * s * 1.13, OX_C.y + cos(ph) * OX_R.y * s * 1.13, z)
	var blanket_c := func(_u: float, v: float) -> Vector3:
		return Vector3(0, OX_C.y, lerpf(0.50, 0.76, v))
	var brass: Array = [
		_at(sphere(0.06, 6, 3), Vector3(0.22, 1.37, 1.24)), _at(sphere(0.06, 6, 3), Vector3(-0.22, 1.37, 1.24)),
		_at(cyl(0.03, 0.10, 0.13, 7), Vector3(0, 0.60, 1.39)), _at(sphere(0.035, 5, 2), Vector3(0, 0.52, 1.39))]
	for sx: float in [-1.0, 1.0]:
		var ph := 68.0 * DEG * sx
		brass.append(_at(sphere(0.045, 6, 3), Vector3(sin(ph) * 0.46, OX_C.y + cos(ph) * 0.43 - 0.05, 0.57)))
	return _bake("cv_ox", [
		[[[body, Transform3D()], [mane, Transform3D()], [skirt, Transform3D()],
			[_tube(tail, func(v: float) -> float: return lerpf(0.045, 0.03, v), 5, 5), Transform3D()],
			_at(_lumpy(Vector3.ZERO, Vector3(0.08, 0.13, 0.08), 8, 4, 0.12, 0.4), Vector3(0, 0.62, 0.39))], _mat(&"fur")],
		[[_at(torus(0.24, 0.35, 12), Vector3(0, 1.03, 1.28), Vector3(72, 0, 0), Vector3(1.0, 1.0, 1.15))], _mat(&"wood")],
		[[[_grid(blanket, blanket_c, 8, 3), Transform3D()]], _mat(&"cloth")],
		[brass, _mat(&"brass")]])


## The ox head (Mount/Head pivot): lumpy skull, broad muzzle with a brass nose ring, a shaggy forelock hanging over
## its eyes, small ears, short brass-capped horns curling up and out.
static func _ox_head_mesh() -> ArrayMesh:
	if _meshes.has("cv_oxhead"):
		return _meshes["cv_oxhead"]
	var brass: Array = [_at(torus(0.035, 0.06, 8), Vector3(0, 0.75, 1.78), Vector3(0, 0, 90))]
	var fur: Array = [
		[_lumpy(Vector3(0, 0.96, 1.52), Vector3(0.22, 0.20, 0.22), 10, 5, 0.04, 2.1), Transform3D()],
		[_lumpy(Vector3(0, 0.84, 1.65), Vector3(0.17, 0.13, 0.15), 8, 4, 0.03, 0.7), Transform3D()],
		[_fringe(Vector3(0, 0, 1.55), 1.19, Vector2.ZERO, Vector2(0.25, 0.21),
			func(a: float) -> float: return 1.03 + 0.07 * (1.0 - cos(a)), 9, 0.09, 2), Transform3D()]]
	for sx: float in [-1.0, 1.0]:
		fur.append(_at(sphere(0.10, 6, 3), Vector3(0.26 * sx, 1.00, 1.45), Vector3(0, 0, -25.0 * sx), Vector3(1.0, 0.45, 0.65)))
		var horn: Array[Vector3] = [Vector3(0.14 * sx, 1.07, 1.50), Vector3(0.28 * sx, 1.09, 1.52),
			Vector3(0.38 * sx, 1.17, 1.55), Vector3(0.42 * sx, 1.28, 1.58)]
		brass.append([_tube(horn, func(v: float) -> float: return lerpf(0.068, 0.018, v), 5, 5), Transform3D()])
	return _bake("cv_oxhead", [[fur, _mat(&"fur")], [brass, _mat(&"brass")]])


## One ox leg (hangs from its pivot at `top`): shaggy shank, feathered fetlock, wooden-brown hoof.
static func _leg_mesh(top: Vector3) -> ArrayMesh:
	var key := "cv_leg%s" % top
	if _meshes.has(key):
		return _meshes[key]
	var x := top.x
	var z := top.z
	return _bake(key, [
		[[_seg(Vector3(x, top.y + 0.05, z), Vector3(x, 0.17, z), 0.105, 0.09, 6),
			_at(cyl(0.10, 0.145, 0.16, 6), Vector3(x, 0.17, z))], _mat(&"fur")],
		[[_at(cyl(0.10, 0.11, 0.08, 6), Vector3(x, 0.04, z + 0.01))], _mat(&"wood")]])


## The cargo on the open rear deck (toggled by set_loaded): two strapped dark crates side by side on the tailboard,
## the brass-bound strongbox riding on top of them with its lid thrown open on a heap of glowing coins (high enough to
## show over the canvas from the game camera, whatever the heading), and a plump sack tucked under the canvas.
static func _cargo_mesh() -> ArrayMesh:
	if _meshes.has("cv_cargo"):
		return _meshes["cv_cargo"]
	var sb := Vector3(0.0, 1.20, -1.22)
	var hinge := Vector3(sb.x, 1.34, sb.z - 0.16)
	var lid := Transform3D(Basis(Vector3.RIGHT, -122.0 * DEG), hinge) * Transform3D(Basis(), Vector3(0, 0.03, 0.165))
	var wood: Array = [_at(box(Vector3(0.54, 0.28, 0.32)), sb), [box(Vector3(0.56, 0.06, 0.33)), lid],
		_at(_lumpy(Vector3.ZERO, Vector3(0.22, 0.17, 0.15), 8, 4, 0.06, 3.3), Vector3(0.20, 0.84, -0.92))]
	var brass: Array = [_at(box(Vector3(0.05, 0.29, 0.33)), sb + Vector3(-0.17, 0, 0)),
		_at(box(Vector3(0.05, 0.29, 0.33)), sb + Vector3(0.17, 0, 0)),
		[box(Vector3(0.05, 0.07, 0.34)), lid * Transform3D(Basis(), Vector3(-0.17, 0, 0))],
		[box(Vector3(0.05, 0.07, 0.34)), lid * Transform3D(Basis(), Vector3(0.17, 0, 0))],
		_at(box(Vector3(0.10, 0.11, 0.03)), sb + Vector3(0, 0.02, 0.17)),
		_at(box(Vector3(0.42, 0.05, 0.42)), Vector3(-0.25, 0.86, -1.21)),
		_at(box(Vector3(0.05, 0.42, 0.38)), Vector3(0.25, 0.86, -1.23), Vector3(0, 8, 0)),
		_at(torus(0.05, 0.09, 8), Vector3(0.20, 1.00, -0.92), Vector3.ZERO, Vector3(1, 1.5, 1))]
	var fur: Array = [_at(box(Vector3(0.40, 0.40, 0.40)), Vector3(-0.25, 0.86, -1.21)),
		_at(box(Vector3(0.36, 0.40, 0.36)), Vector3(0.25, 0.86, -1.23), Vector3(0, 8, 0))]
	var glow: Array = [_at(sphere(1.0, 8, 4), sb + Vector3(0, 0.14, 0.01), Vector3.ZERO, Vector3(0.24, 0.10, 0.14)),
		_at(cyl(0.065, 0.065, 0.02, 7), sb + Vector3(0.10, 0.22, 0.05), Vector3(20, 0, 30)),
		_at(cyl(0.065, 0.065, 0.02, 7), sb + Vector3(-0.11, 0.21, -0.02), Vector3(-25, 0, -15))]
	return _bake("cv_cargo", [[wood, _mat(&"wood")], [fur, _mat(&"fur")], [brass, _mat(&"brass")],
		[glow, _mat(&"glow")]])


## The lantern, hanging from its pivot (the crook tip): dark iron hook, cap and base around a big glass that glows gold
## when loaded and stays dark amber when empty (the 40 m read: a bright gold point vs nothing).
static func _lantern_mesh() -> ArrayMesh:
	if _meshes.has("cv_lantern"):
		return _meshes["cv_lantern"]
	return _bake("cv_lantern", [
		[[_at(torus(0.02, 0.045, 8), Vector3(0, 0.0, 0), Vector3(90, 0, 0)),
			_seg(Vector3(0, -0.02, 0), Vector3(0, -0.06, 0), 0.016, 0.016, 4),
			_at(cyl(0.04, 0.19, 0.11, 8), Vector3(0, -0.10, 0)),
			_at(cyl(0.19, 0.15, 0.06, 8), Vector3(0, -0.48, 0))], _mat(&"fur")],
		[[_at(cyl(0.16, 0.16, 0.30, 8), Vector3(0, -0.30, 0))], _mat(&"glow")]])


## Swallow-tailed team pennant trailing back (-Z) from its pivot on the pole top, double-sided.
static func _pennant_mesh() -> ArrayMesh:
	if _meshes.has("cv_pennant"):
		return _meshes["cv_pennant"]
	var fn := func(u: float, v: float) -> Vector3:
		var top := -0.03 * u
		var bot := -0.28 + 0.06 * u
		var ln := 0.46 - 0.13 * (1.0 - absf(2.0 * v - 1.0)) * smoothstep(0.7, 1.0, u)
		return Vector3(0.025 * sin(PI * u * 1.5), lerpf(top, bot, v), -0.04 - ln * u)
	var side := func(u: float, v: float) -> Vector3:
		var p: Vector3 = fn.call(u, v)
		return Vector3(p.x - 1.0, p.y, p.z)
	var m := _bake("cv_pennant", [[[[_grid(fn, side, 6, 3, true), Transform3D()]], _mat(&"cloth")]])
	return m


## One-shot brown dust puff at the death (pre-built, restarted by the kit's death_fx).
static func _make_dust() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 16
	p.lifetime = 1.0
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.85
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2.0, -0.5, -2.5), Vector3(4.0, 3.0, 5.0))
	if _dust_pm == null:
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.7, 0.12, 1.5)
		pm.direction = Vector3.UP
		pm.spread = 70.0
		pm.initial_velocity_min = 0.6
		pm.initial_velocity_max = 1.4
		pm.gravity = Vector3(0, -0.8, 0)
		pm.damping_min = 1.0
		pm.damping_max = 2.0
		var sc := Curve.new()
		sc.add_point(Vector2(0, 0.6))
		sc.add_point(Vector2(1, 1.5))
		var sct := CurveTexture.new()
		sct.curve = sc
		pm.scale_curve = sct
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.9))
		g.set_color(1, Color(1, 1, 1, 0.0))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_ramp = gt
		_dust_pm = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.8, 0.8)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true
		sm.albedo_texture = mote_texture()
		sm.albedo_color = Color(0.55, 0.47, 0.36, 0.6)
		sm.vertex_color_use_as_albedo = true
		q.material = sm
		_dust_quad = q
	p.process_material = _dust_pm
	p.draw_pass_1 = _dust_quad
	return p
