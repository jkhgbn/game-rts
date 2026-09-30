class_name IceModel
extends CharacterModel
## Shared Ice army layer on top of the kit (kingdom-ice.md 8.2; polish A.6). Per-unit scripts extend it
## (rime_hauler.gd, rimeshield.gd, shardcaster.gd, rime_seer.gd, rime_colossus.gd). Stable API, also used by Torvald:
##   ice(&"ice_cloth")        Ice palette material (art/units/ice/materials/), falls back to the kit palette.
##   ICE_GLOW                 the Ice glow colour.
## Helpers for Ice units:
##   add_limb(pivot, a, b, r, mat, end_r, end_mat)       capsule from model point a to b (+ optional end sphere).
##   add_spikes(pivot, centre, n, ring_r, r, h, tilt_deg, mat, phase_deg)   ring of hexagonal ice spikes (cones).
##   add_crystal(pivot, base, dir, r, h, mat, tip)       hexagonal crystal: prism body + pointed tip along dir.
##   add_breath(head_pos, size)   soft frost-breath puff (5 MIX puffs), every `breath_interval` s within 30 m.
##   add_hit_chips(model_pos, n)  ice chips burst from the armour on every hit (within 30 m).
##   add_shatter(model_pos, n, spread)   the death: the body frosts over, then SHATTERS at `shatter_time` into
##                                crystal shards + a frost puff and collapses (Ice deaths never just fall / sink).
## Materials: ice_frost_crystal / ice_frost_deep (opaque faceted ice, ice_crystal.gdshader), ice_frost_clear
## (translucent, ice_clear.gdshader). They take the kit's hit / level-up flash like the painted parts.
## Team colour: ice_cloth / ice_cloth_dark / ice_cape are recoloured by set_team_color like the kit's cloth.

const ICE_MAT_DIR := "res://art/units/ice/materials/"
const ICE_GLOW := Color(0.75, 0.92, 1.0)
## ice_skin's colour (FaceKit faces paint over it with vertex colours).
const ICE_SKIN := Color(0.86, 0.82, 0.84)
const FREEZE_COLOR := Vector3(0.40, 0.72, 1.0)
## Ice hit flash (kit hit_flash_*): cyan, half strength, half length (a white flash on the pale armour read as a white
## puff the size of the unit mid-fight, in-game grade 2026-09-30). Torvald uses the same look.
const HIT_FLASH_CYAN := Vector3(0.18, 0.66, 1.0)
const HIT_FLASH_SCALE := 0.5
const HIT_FLASH_TIME := 0.07
## Cool (blue-black) ground blob for every Ice unit: the "dark base" that separates the pale Ice line from snow and
## from each other (in-game grade pass 2026-09-30: 0.5 -> 0.72 alpha).
const BLOB_TINT := Color(0.03, 0.05, 0.11, 0.72)
const ICE_SHADERS: Array[String] = ["res://art/units/ice/ice_crystal.gdshader", "res://art/units/ice/ice_clear.gdshader"]

## Frost breath interval (s); 0 = no breath.
@export var breath_interval: float = 0.0
## Death: the moment the frozen body shatters (s, < 1.0) and how long the body takes to collapse.
@export var shatter_time: float = 0.5
@export var shatter_collapse: float = 0.14
## Idle fidget (_pose_fidget) every ~N s (randomised +-40 % per unit) while standing within 30 m; 0 = never.
@export var fidget_every: float = 9.0

static var _ice_cache: Dictionary = {}

var _breath: GPUParticles3D
var _breath_t: float = 0.0
var _chips: GPUParticles3D
var _shatter: GPUParticles3D
var _mist: GPUParticles3D
var _ice_nodes: Array[GeometryInstance3D] = []
var _shattered: bool = false
var _freeze_written: float = 0.0
var _fidget_wait: float = 0.0
## Painted face (FaceKit, faces pass 2026-09-28): attached by the unit's _build_parts; null = faceless (golems).
var _face: FaceRig


## Ice palette material by name (loaded once, shared). Unknown Ice names fall back to the kit palette.
static func ice(name: StringName) -> Material:
	if not _ice_cache.has(name):
		var p := ICE_MAT_DIR + String(name) + ".tres"
		_ice_cache[name] = load(p) if ResourceLoader.exists(p) else palette(name)
	return _ice_cache[name]


# ================================================================ part helpers

## Capsule limb from model point a to b (radius r), plus an optional end sphere (fist / foot) at b.
## `lo` = the cheap capsule (1 ring per cap: 81 vertices instead of 162; faces pass budget trims).
func add_limb(pivot: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, end_r: float = 0.0,
		end_mat: Material = null, lo: bool = false) -> void:
	var d := b - a
	var e := Basis(Quaternion(Vector3.DOWN, d.normalized())).get_euler() * (180.0 / PI)
	add_part(pivot, capsule_lo(r, d.length() + r) if lo else capsule(r, d.length() + r), mat, a + d * 0.5, e)
	if end_r > 0.0:
		add_part(pivot, sphere(end_r), end_mat if end_mat else mat, b)


## A cheaper capsule (8 sides, 1 ring per cap: 81 vertices; the kit's capsule() is 162). Cached.
static func capsule_lo(r: float, h: float) -> Mesh:
	var key := "caplo%s_%s" % [r, h]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 8
	m.rings = 1
	return _cached(key, m)


## Ring of n hexagonal ice spikes (cones, 6 segments) around `centre` (model space), tips leaning outward.
func add_spikes(pivot: Node3D, centre: Vector3, n: int, ring_r: float, r: float, h: float, tilt_deg: float,
		mat: Material, phase_deg: float = 0.0) -> void:
	for i: int in n:
		var a := TAU * float(i) / float(n) + phase_deg * DEG
		var out := Vector3(sin(a), 0, cos(a))
		var b := Basis(Vector3.UP.cross(out).normalized(), tilt_deg * DEG)
		var e := b.get_euler() * (180.0 / PI)
		add_part(pivot, cyl(0.0, r, h, 6), mat, centre + out * ring_r + b * Vector3(0, h * 0.5, 0), e)


## Hexagonal crystal from model point `base` along `dir`: a prism of length h * (1 - tip) and a pointed tip of
## length h * tip. Two meshes (merged with the pivot).
func add_crystal(pivot: Node3D, base: Vector3, dir: Vector3, r: float, h: float, mat: Material,
		tip: float = 0.4) -> void:
	var d := dir.normalized()
	var e := Basis(Quaternion(Vector3.UP, d)).get_euler() * (180.0 / PI)
	var body := h * (1.0 - tip)
	if body > 0.01:
		add_part(pivot, cyl(r, r * 0.85, body, 6), mat, base + d * body * 0.5, e)
	add_part(pivot, cyl(0.0, r, h * tip, 6), mat, base + d * (body + h * tip * 0.5), e)


# ================================================================ fx (all pre-built, restarted, never instanced later)

## Frost breath: soft white puffs pushed forward out of the mouth (world-space, so they trail behind a walker).
func add_breath(head_pos: Vector3, size: float = 0.22) -> void:
	var head := get_node_or_null(^"Root/Chest/Head") as Node3D
	if head == null:
		return
	_breath = _puffs(size, 6, 1.4, 0.6, 0.05, Vector3(0, 0.2, 1), 12.0, 0.45, 0.8, Vector3(0, 0.15, 0), 0.6)
	_breath.name = "Breath"
	_breath.position = head_pos - model_origin(head)
	head.add_child(_breath)


## Makes the unit breathe out now (preview / cinematic helper; the loop does it by itself).
func puff_breath() -> void:
	if _breath and not _dead:
		_breath.restart()
		_breath_t = 0.0


## Starts the idle fidget now (preview helper; the loop does it by itself every ~fidget_every s).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0


## Ice chips knocked off the armour on each hit (within 30 m). Model-space position.
func add_hit_chips(model_pos: Vector3, n: int = 6) -> void:
	_chips = _shards(n, 0.5, 0.18, 1.6, 3.2, 70.0, Vector3(0, 0.4, 1.0), 0.06)
	_chips.name = "HitChips"
	_chips.position = model_pos
	$Fx.add_child(_chips)


## The shatter death: n crystal shards + a frost puff at `model_pos` (restarted at shatter_time).
func add_shatter(model_pos: Vector3, n: int = 14, spread: float = 0.35, shard: float = 0.11) -> void:
	_shatter = _shards(n, 0.9, spread, 1.6, 3.6, 180.0, Vector3.UP, shard)
	_shatter.name = "Shatter"
	_shatter.position = model_pos
	$Fx.add_child(_shatter)
	_mist = _puffs(0.3 + spread * 0.6, 5, 0.7, 0.9, spread * 0.6, Vector3.UP, 180.0, 0.3, 0.7, Vector3(0, 0.35, 0), 0.4)
	_mist.name = "FrostMist"
	_mist.position = model_pos
	$Fx.add_child(_mist)


# ================================================================ kit hooks

func _after_ready() -> void:
	hit_flash_color = HIT_FLASH_CYAN
	hit_flash_scale = HIT_FLASH_SCALE
	hit_flash_time = HIT_FLASH_TIME
	_fidget_wait = _next_fidget() * 0.6
	_find_ice_nodes(self)
	for gi: GeometryInstance3D in _ice_nodes:
		gi.set_instance_shader_parameter(&"ao_height", body_height)
	_ice_ready()


func play_hit() -> void:
	if not _dead and _t - _last_hit_time >= 0.15:
		if _chips and _tier == 0:
			_chips.restart()
		_on_ice_hit()
	super.play_hit()


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto(self)
	if _breath and breath_interval > 0.0 and not _dead:
		_breath_t += dt
		if _breath_t >= breath_interval:
			_breath_t = fmod(_phase_off, 0.6)
			if _tier == 0:
				_breath.restart()
	if _dead:
		_death_ice()
	_fidget_process(dt)
	_ice_process(dt)


## Idle fidget: a private action id the kit's timeline ignores (it only advances _action_t); posed and ended here.
## Starts only when standing, idle and close (tier 0); walking or any real action cancels it.
func _fidget_process(dt: float) -> void:
	if _action == &"fidget":
		if _dead or _speed >= 0.3:
			_action = &""
			return
		var length := _pose_fidget(_action_t)
		if _action_t >= length:
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


func _on_revive() -> void:
	if _face:
		_face.reset()
	_shattered = false
	_write_freeze(0.0)
	var root := _piv[P_ROOT]
	if root:
		root.visible = true
	_ice_revive()


## Freeze-over then shatter (runs every animated frame while dead, after the kit's death pose).
func _death_ice() -> void:
	var t := _death_t
	var v: float = 0.55 * smoothstep(0.02, shatter_time, t)
	if t >= shatter_time:
		if not _shattered:
			_shattered = true
			if _shatter:
				_shatter.restart()
			if _mist:
				_mist.restart()
			_on_ice_shatter()
		var c: float = clampf((t - shatter_time) / maxf(shatter_collapse, 0.01), 0.0, 1.0)
		v = 0.55 + 0.45 * (1.0 - c)
		_root_scale *= maxf(0.02, 1.0 - c * c)
		var root := _piv[P_ROOT]
		if root and c >= 1.0 and root.visible:
			root.visible = false
	_write_freeze(v)


func _write_freeze(v: float) -> void:
	if v == _freeze_written:
		return
	_freeze_written = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", FREEZE_COLOR)
	for gi: GeometryInstance3D in _ice_nodes:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", FREEZE_COLOR)


func _find_ice_nodes(n: Node) -> void:
	for c: Node in n.get_children():
		if c is GeometryInstance3D and not _flash_all_targets.has(c):
			for m: Material in _materials_of(c as GeometryInstance3D):
				if m is ShaderMaterial and (m as ShaderMaterial).shader \
						and ICE_SHADERS.has((m as ShaderMaterial).shader.resource_path):
					_ice_nodes.append(c as GeometryInstance3D)
					break
		_find_ice_nodes(c)


# ================================================================ face (FaceKit)

## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout").
## No-op on faceless units.
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


# ================================================================ subclass hooks

## After the parts are merged (grab keep_separate nodes here).
func _ice_ready() -> void:
	pass


## Per-frame extras (keep tiny, no allocation). Pose offsets with rot() / pos() only apply on animated frames
## (walk, actions, death); in pure idle the kit takes a fast path and ignores them.
func _ice_process(_dt: float) -> void:
	pass


## A hit landed (rate-limited like the kit's flinch).
func _on_ice_hit() -> void:
	pass


## The frozen body just shattered.
func _on_ice_shatter() -> void:
	pass


## Idle fidget pose at time t (write with rot() / pos()); return its length (s). Base: a slow look around.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.4, 0.9, 1.4, 1.0, 1.0)
	rot(P_HEAD, Vector3(-6.0 * DEG * k, 22.0 * DEG * k * (1.0 if int(_phase_off * 10.0) % 2 == 0 else -1.0), 0))
	return 1.4


func _ice_revive() -> void:
	pass


# ================================================================ shared particle builders (cached per look)

static func _soft_tex() -> Texture2D:
	var t: Texture2D = _mat_cache.get("ice_soft_tex")
	if t == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.55))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		t = gt
		_mat_cache["ice_soft_tex"] = t
	return t


## Soft MIX puffs (breath, frost mist).
static func _puffs(size: float, amount: int, lifetime: float, explosiveness: float, radius: float, dir: Vector3,
		spread: float, v_min: float, v_max: float, gravity: Vector3, alpha: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.emitting = false
	p.explosiveness = explosiveness
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 4, 4))
	var key := "icepuff%s_%s_%s_%s_%s_%s_%s" % [radius, dir, spread, v_min, v_max, gravity, alpha]
	var pm: ParticleProcessMaterial = _mat_cache.get(key)
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = maxf(radius, 0.01)
		pm.direction = dir
		pm.spread = spread
		pm.initial_velocity_min = v_min
		pm.initial_velocity_max = v_max
		pm.gravity = gravity
		pm.damping_min = 0.4
		pm.damping_max = 0.8
		pm.scale_min = 0.8
		pm.scale_max = 1.2
		var sc := CurveTexture.new()
		var cv := Curve.new()
		cv.add_point(Vector2(0, 0.35))
		cv.add_point(Vector2(1, 1.0))
		sc.curve = cv
		pm.scale_curve = sc
		# Blue-grey frost, not white (in-game grade 2026-09-30: white puffs smeared the Ice line mid-fight), and at
		# most 0.5 alpha whatever the caller asks.
		var ramp := GradientTexture1D.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.62, 0.78, 0.92, 0.0))
		g.set_color(1, Color(0.5, 0.66, 0.84, 0.0))
		g.add_point(0.18, Color(0.62, 0.78, 0.92, minf(alpha, 0.5)))
		ramp.gradient = g
		pm.color_ramp = ramp
		_mat_cache[key] = pm
	p.process_material = pm
	var dkey := "icepuffdraw%s" % size
	var q: QuadMesh = _mesh_cache.get(dkey)
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(size, size)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true   # A.17: the puff's grow curve is ignored without it (Godot 4.7)
		sm.vertex_color_use_as_albedo = true
		sm.albedo_texture = _soft_tex()
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		q.material = sm
		_mesh_cache[dkey] = q
	p.draw_pass_1 = q
	return p


## Tumbling crystal shards (hit chips, shatter). Lit, lightly emissive, fall with gravity.
static func _shards(amount: int, lifetime: float, radius: float, v_min: float, v_max: float, spread: float,
		dir: Vector3, size: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.95
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 5, 6))
	var key := "iceshard%s_%s_%s_%s_%s" % [radius, v_min, v_max, spread, dir]
	var pm: ParticleProcessMaterial = _mat_cache.get(key)
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = maxf(radius, 0.01)
		pm.direction = dir
		pm.spread = spread
		pm.initial_velocity_min = v_min
		pm.initial_velocity_max = v_max
		pm.gravity = Vector3(0, -9.0, 0)
		pm.scale_min = 0.6
		pm.scale_max = 1.5
		pm.angle_min = -180.0
		pm.angle_max = 180.0
		pm.angular_velocity_min = -540.0
		pm.angular_velocity_max = 540.0
		pm.particle_flag_rotate_y = true
		pm.collision_mode = ParticleProcessMaterial.COLLISION_DISABLED
		var sc := CurveTexture.new()
		var cv := Curve.new()
		cv.add_point(Vector2(0, 1.0))
		cv.add_point(Vector2(0.75, 0.9))
		cv.add_point(Vector2(1, 0.0))
		sc.curve = cv
		pm.scale_curve = sc
		_mat_cache[key] = pm
	p.process_material = pm
	var dkey := "iceshardmesh%s" % size
	var m: PrismMesh = _mesh_cache.get(dkey)
	if m == null:
		m = PrismMesh.new()
		m.size = Vector3(size, size * 2.2, size * 0.7)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.42, 0.64, 0.84)   # steel-cyan chips (were near-white + glow)
		sm.emission_enabled = true
		sm.emission = Color(0.18, 0.6, 0.95)
		sm.emission_energy_multiplier = 0.5
		sm.roughness = 0.2
		sm.metallic_specular = 0.9
		m.material = sm
		_mesh_cache[dkey] = m
	p.draw_pass_1 = m
	return p
