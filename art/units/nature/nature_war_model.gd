class_name NatureWarModel
extends NatureModel
## Polish layer (task A2.2) shared by the Nature war units Thornling, Burr Slinger and Bramblehorn only (sprigling,
## sapling, bloomtender and Ysolde do not use it). On top of NatureModel / the kit (hooks, merge, tiers unchanged):
##  - keyframed timelines: _kf(t, [t, value, ease, ...]) (same format as FireModel._kf),
##  - idle fidgets every ~fidget_every s when standing close to the camera (tier 0): _pose_fidget(t) -> length,
##  - hit: a pre-built burst of bark splinters + leaves (add_hit_burst), within 30 m,
##  - death "return to the grove": a green life flash leaves the body as it falls, verdant motes rise and leaves
##    scatter (add_death_bloom), then the body sinks into its moss instead of lying there,
##  - per-unit hooks: _war_ready(), _war_process(dt), _war_revive(), _pose_fidget(t).
## Everything is pre-built at _build_parts; no allocation, no get_node, no Tween per frame.

## Idle fidget interval (s, randomised +-40 % per unit); 0 = never.
@export var fidget_every: float = 8.0

## Warm spring green poured into the body on death (the life leaving it). Emission colour of the kit's flash.
const LIFE_GREEN := Vector3(0.50, 1.0, 0.22)
const LIFE_PEAK := 0.55
## Death leaf quad size (m; G-E fixes D: was 0.15).
const DEATH_LEAF_SIZE := 0.09

var _hit_fx: GPUParticles3D
var _fidget_wait: float = 0.0
var _life_v: float = 0.0


# ================================================================ helpers for the unit scripts

## Keyframe track [t, v, ease, t, v, ease, ...] starting at t = 0; ease of the segment arriving at a key:
## 0 smooth, 1 ease-out (snappy start), 2 ease-in (accelerating into the key). A few float ops per call.
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


## Commits a SurfaceTool filled with append_from() as an INDEXED mesh (append_from unrolls the primitives' index
## arrays; re-indexing shares the vertices again: about half the vertex count).
static func _indexed(st: SurfaceTool) -> Mesh:
	st.index()
	return st.commit()


## Curved horn / claw: n tapering 6-sided segments through `pts` (radii `radii`, last radius 0 = the point), baked
## into ONE cached mesh (a unit-height cylinder per segment, so the key must be unique per shape).
static func tapered_path_mesh(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6,
		caps: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	for i: int in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := b - a
		var extra: float = 0.03 if radii[i + 1] > 0.0 else 0.0   # overlap the joints so no gap shows
		var basis := Basis(Quaternion(Vector3.UP, d.normalized()))
		var len_total := d.length() + extra
		# caps only at the path's two ends: the inner joints overlap (face rework 2026-09-28: -16 vertices a joint)
		var c := cyl(radii[i + 1], radii[i], len_total, seg, caps and (i == 0 or i == pts.size() - 2))
		st.append_from(c, 0, Transform3D(basis, a + d.normalized() * len_total * 0.5))
	return _cached(key, _indexed(st))


## Pre-built hit burst at a model-space point: bark splinters + leaves knocked off (restarted by play_hit, tier 0).
func add_hit_burst(model_pos: Vector3, color: Color = Color(0.46, 0.66, 0.20), amount: int = 7) -> void:
	_hit_fx = make_petals(color, amount, 0.6, 0.18, 4.5, 0.12, true)
	_hit_fx.name = "HitLeaves"
	_hit_fx.position = model_pos
	$Fx.add_child(_hit_fx)


## Pre-built death bloom (restarted by the kit when the glows die): verdant motes rise, leaves scatter.
func add_death_bloom(model_pos: Vector3, radius: float, motes: int = 10, leaves: int = 12,
		leaf_color: Color = Color(0.40, 0.58, 0.17)) -> void:
	var up := make_motes(NATURE_GLOW, motes, 1.1, radius, 1.4, 0.12, true, true)
	up.name = "DeathMotes"
	up.set_meta(&"death_fx", true)
	up.position = model_pos + Vector3(0, -0.3, 0)
	$Fx.add_child(up)
	# G-E fixes D: 0.15 -> 0.09 m and a deeper green by default: at z14-30 the 0.15 m quads (x the model scale, kept
	# by billboard_keep_scale) still read as a pale confetti cloud over the melee; now small dark leaves.
	var lv := make_petals(leaf_color, leaves, 1.0, radius, 1.5, DEATH_LEAF_SIZE, true)
	lv.name = "DeathLeaves"
	lv.set_meta(&"death_fx", true)
	lv.position = model_pos
	$Fx.add_child(lv)


## Soft dust / pollen puffs (alpha, not additive): pre-built one-shot, grows and fades. Shared resources per look.
static func make_dust(color: Color, amount: int, lifetime: float, radius: float, size: float, up: float = 0.6,
		spread: float = 70.0) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.92
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2.5, -1.0, -2.5), Vector3(5, 4, 5))
	var key := "naturedust%s_%s_%s" % [radius, up, spread]
	var pm: ParticleProcessMaterial = _mat_cache.get(key)
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = maxf(radius, 0.01)
		pm.direction = Vector3.UP
		pm.spread = spread
		pm.initial_velocity_min = up * 0.5
		pm.initial_velocity_max = up
		pm.gravity = Vector3(0, -0.4, 0)
		pm.damping_min = 0.8
		pm.damping_max = 1.5
		pm.scale_min = 0.7
		pm.scale_max = 1.3
		var sc := CurveTexture.new()
		var cv := Curve.new()
		cv.add_point(Vector2(0, 0.4))
		cv.add_point(Vector2(1, 1.0))
		sc.curve = cv
		pm.scale_curve = sc
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.0))
		g.set_color(1, Color(1, 1, 1, 0.0))
		g.add_point(0.15, Color(1, 1, 1, 0.55))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_ramp = gt
		_mat_cache[key] = pm
	p.process_material = pm
	var dkey := "naturedustdraw%s_%s" % [color.to_html(), size]
	var q: QuadMesh = _mesh_cache.get(dkey)
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(size, size)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true   # A.17: the grow curve is ignored without it (Godot 4.7)
		sm.vertex_color_use_as_albedo = true
		sm.albedo_color = color
		sm.albedo_texture = mote_texture()
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		q.material = sm
		_mesh_cache[dkey] = q
	p.draw_pass_1 = q
	return p


## Starts the idle fidget now (preview helper; the loop does it by itself every ~fidget_every s when close).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0


# ================================================================ kit hooks

func _after_ready() -> void:
	_fidget_wait = _next_fidget() * 0.6
	_war_ready()


func play_hit() -> void:
	if not _dead and _t - _last_hit_time >= 0.15 and _hit_fx and _tier == 0:
		_hit_fx.restart()
	super.play_hit()


func _extra_process(dt: float) -> void:
	_fidget_process(dt)
	if _dead:
		# Life flash: a spring-green glow pours out of the body as it buckles, gone by the time it hits the ground.
		var d := _death_t
		_write_life(LIFE_PEAK * smoothstep(0.0, 0.08, d) * (1.0 - smoothstep(0.12, 0.6, d)))
	_war_process(dt)
	_face_tick()


func _on_revive() -> void:
	_write_life(0.0)
	_war_revive()
	_face_reset()


func _fidget_process(dt: float) -> void:
	if _action == &"fidget":
		if _dead or _speed >= 0.3:
			_action = &""
			return
		if _action_t >= _pose_fidget(_action_t):
			_action = &""
		return
	if fidget_every <= 0.0 or _dead or _action != &"" or _speed >= 0.3 or _tier != 0:
		return
	_fidget_wait -= dt
	if _fidget_wait <= 0.0:
		_fidget_wait = _next_fidget()
		_action = &"fidget"
		_action_t = 0.0


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


func _write_life(v: float) -> void:
	v = snappedf(v, 0.05)
	if v == _life_v:
		return
	_life_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", LIFE_GREEN if v > 0.0 else WHITE)


# ================================================================ subclass hooks

func _war_ready() -> void:
	pass


## Per-frame extras (after the body pose; rot() / pos() only apply on animated frames, not in the idle fast path).
func _war_process(_dt: float) -> void:
	pass


func _war_revive() -> void:
	pass


## Idle fidget pose at time t (write with rot() / pos()); return its length (s). Base: a slow look around.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.4, 0.9, 1.4, 1.0, 1.0)
	rot(P_HEAD, Vector3(-6.0 * DEG * k, 22.0 * DEG * k, 0))
	return 1.4
