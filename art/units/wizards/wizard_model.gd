class_name WizardModel
extends CharacterModel
## Shared wizard layer (art-units.md 3, 6.2 wizards, 6.4 wizard_bolt, 6.5, 6.8): the staff orb / shard glow
## (instance uniform glow_boost, own_glow), its OmniLight3D and the orb bob. Vessa / Malrik add the parts and casts.
## Wizards never receive set_veterancy; set_carrying / play_mine stay inherited no-ops (no carry parts).

## Base energy of the staff light (Vessa 1.2, Malrik 1.0).
@export var light_energy: float = 1.2

## G3a hero layer (docs/art/g3a_wizards.md): rune bands (wizard_runes.gdshader, procedural glyphs that breathe, a wave
## runs along them, cast flares through the instance uniform `flare`) and a close-camera kingdom aura (embers / soul
## wisps / snow / fireflies) that only emits with the camera within AURA_RANGE (closest RTS zoom, the HUD portrait, cinematics) and Graphics >= Medium.
const RUNE_SHADER := "res://art/units/wizards/wizard_runes.gdshader"
const AURA_KINDS: Array[StringName] = [&"embers", &"wisps", &"snow", &"fireflies"]

static var _g3a: Dictionary = {}    # rune materials, rune meshes, aura process / draw resources (shared per type)

var _runes: GeometryInstance3D      # the wizard's rune band node (keep_separate, kit drives glow_boost)
var _aura: GPUParticles3D           # close-camera aura (looping; null below Medium graphics)
var _flare_written: float = -1.0
var _aura_near: bool = false
var _aura_check: int = 0
## Camera distance under which the aura emits: the closest RTS zoom (rig zoom 10 = ~30 m from the focus point) and
## closer (HUD portrait, cinematics); off from the usual zoom 30-50 up.
const AURA_RANGE := 36.0

var _orb: GeometryInstance3D        # glowing core driven here (meta own_glow)
var _bob: Node3D                    # the node that bobs (orb / shard)
var _bob_rest: Vector3
var _light: OmniLight3D
var _cast_boost: float = 1.0        # set by _pose_cast each frame of a cast
var _cast_light: float = 1.0
var _orb_written: float = -1.0
var _light_written: float = -1.0
var _bob_extra: Vector3 = Vector3.ZERO  # extra offset of the bob node this frame (subclass casts / death)


## Static parts of a kit pivot are pre-merged per pivot (Art Lab B1, art-units 8: <= 26 authored meshes per wizard;
## the heroes' polish detail was 56-69 separate parts). Same arguments and return as CharacterModel.add_part: static
## parts return null (as the kit already does once the type is cached); keep_separate / named parts and parts of
## non-pivot nodes pass straight to the kit. The batch becomes ONE part per pivot right before the kit merges it, so
## the merged mesh, its materials and every hook stay the same.
var _part_batch: Dictionary = {}    # pivot Node3D -> [[mesh, pivot-local Transform3D, [material per surface]], ...]


func add_part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	if keep_separate or part_name != "" or mesh == null or pivot == null or not _piv.has(pivot):
		return super.add_part(pivot, mesh, mat, model_pos, rot_deg, scl, keep_separate, part_name)
	if _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return null
	var xf := Transform3D(Basis.from_euler(rot_deg * DEG) * Basis.from_scale(scl), model_pos - model_origin(pivot))
	var mats: Array = []
	for s: int in mesh.get_surface_count():
		mats.append(mat)
	if not _part_batch.has(pivot):
		_part_batch[pivot] = []
	(_part_batch[pivot] as Array).append([mesh, xf, mats])
	return null


func _merge_pivot(i: int) -> void:
	var p: Node3D = _piv[i]
	var items: Array = _part_batch.get(p, [])
	if not items.is_empty():
		_part_batch.erase(p)
		var am := _merge_items(items)
		if am:
			super.add_part(p, am, null, model_origin(p), Vector3.ZERO, Vector3.ONE, false, "PartBatch")
	super._merge_pivot(i)


## Arm capsule + fist from the shoulder (model space) to the hand (model space).
func add_arm(pivot: Node3D, shoulder: Vector3, hand: Vector3, r: float, fist_r: float, sleeve: Material, skin: Material) -> void:
	var d := hand - shoulder
	var e := Basis(Quaternion(Vector3.DOWN, d.normalized())).get_euler() * (180.0 / PI)
	add_part(pivot, capsule(r, d.length() + r), sleeve, shoulder + d * 0.5, e)
	add_part(pivot, sphere(fist_r), skin, hand)


func _extra_process(dt: float) -> void:
	var b: float = 1.0
	var lm: float = 1.0
	if _action == &"attack" and _action_t < attack_windup + 0.08:
		b = 1.6
		lm = 1.4
	elif _action == &"cast":
		b = _cast_boost
		lm = _cast_light
	if _level_t < LEVEL_LEN:
		b = maxf(b, 3.0)
		lm = maxf(lm, 2.0)
	_cast_boost = 1.0
	_cast_light = 1.0
	var g := glow_level() * b
	if _dead:
		g = _death_glow()
		lm = g / 3.0
	if _orb and g != _orb_written:
		_orb_written = g
		_orb.set_instance_shader_parameter(&"glow_boost", g)
	var le := light_energy * lm
	if _light and le != _light_written:
		_light_written = le
		_light.light_energy = le
	if _bob:
		var y := 0.04 * sin((_t + _phase_off) * PI)   # +-0.04 m over 2 s
		_bob.position = _bob_rest + Vector3(0, y, 0) + _bob_extra
	_bob_extra = Vector3.ZERO
	if _runes:
		var fl := 0.0 if _dead else clampf((b - 1.0) * 0.8, 0.0, 2.5)
		if absf(fl - _flare_written) > 0.02:
			_flare_written = fl
			_runes.set_instance_shader_parameter(&"flare", fl)
	_wizard_process(dt)


## The aura is driven here, not in _extra_process: the kit skips that while the model is frozen (far tier /
## off-screen) or on its half-rate frames, and a frozen model must switch its aura off.
func _process(delta: float) -> void:
	super._process(delta)
	if _aura:
		_update_aura()


func _update_aura() -> void:
	_aura_check -= 1
	if _aura_check <= 0:
		_aura_check = 15
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		_aura_near = cam != null and cam.global_position.distance_to(global_position) < AURA_RANGE
	var on := _aura_near and not _dead and not _frozen and is_visible_in_tree() and aura_allowed()
	if _aura.emitting != on or _off_fx.paused:
		set_fx_emitting(_aura, on)


## Orb boost while dying (default: flash 5 for 0.15 s then out).
func _death_glow() -> float:
	return 5.0 if _death_t < 0.15 else maxf(0.0, 5.0 * (1.0 - (_death_t - 0.15) / 0.1))


## Subclass per-frame extras (flames, shard spin).
func _wizard_process(_dt: float) -> void:
	pass


func _on_revive() -> void:
	_orb_written = -1.0
	_light_written = -1.0
	_flare_written = -1.0
	if _bob:
		_bob.visible = true
		_bob.position = _bob_rest


# ================================================================ G3a hero layer: rune bands

## Shared rune material (one per key for every instance): base = the inlay colour, rune = the glyph glow colour,
## cells = glyphs along the band, aspect = glyph width / height in metres (round strokes on any band).
static func rune_material(key: String, base: Color, rune: Color, cells: float, aspect: float, energy: float = 2.4,
		seed: float = 0.0) -> ShaderMaterial:
	var k := "rune_mat|" + key
	if _g3a.has(k):
		return _g3a[k]
	var m := ShaderMaterial.new()
	m.shader = load(RUNE_SHADER)
	m.resource_name = "wizard_runes_" + key
	m.set_shader_parameter(&"base_color", base)
	m.set_shader_parameter(&"rune_color", rune)
	m.set_shader_parameter(&"cells", cells)
	m.set_shader_parameter(&"aspect", aspect)
	m.set_shader_parameter(&"energy", energy)
	m.set_shader_parameter(&"seed", seed)
	_g3a[k] = m
	return m


## A cone ring strip (no caps) from height y0 (radius r0) up to y1 (radius r1), `seg` facets starting at rot_deg
## (match a faceted robe: same seg + rotation, radius + 1 cm), over arc_deg centred on +Z (360 = closed).
## UV.x 0..1 along the band, UV.y 0 top .. 1 bottom. Returns surface arrays (model space).
static func rune_ring(y0: float, y1: float, r0: float, r1: float, seg: int, rot_deg: float = 0.0,
		arc_deg: float = 360.0) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var ix := PackedInt32Array()
	var slope := (r0 - r1) / maxf(y1 - y0, 0.001)
	var closed := arc_deg >= 359.9
	for i: int in seg + 1:
		var u := float(i) / float(seg)
		var a := deg_to_rad(rot_deg) + (u * TAU if closed else deg_to_rad(lerpf(-arc_deg * 0.5, arc_deg * 0.5, u)))
		var dir := Vector3(sin(a), 0.0, cos(a))
		var nn := (dir + Vector3(0, slope, 0)).normalized()
		v.append(dir * r1 + Vector3(0, y1, 0))
		n.append(nn)
		uv.append(Vector2(u, 0.0))
		v.append(dir * r0 + Vector3(0, y0, 0))
		n.append(nn)
		uv.append(Vector2(u, 1.0))
	for i: int in seg:
		var k := i * 2
		ix.append_array(PackedInt32Array([k, k + 2, k + 1, k + 1, k + 2, k + 3]))
	return _arrays_of(v, n, uv, ix)


## A flat strip from `top` down to `bottom` (model space), `w` wide, facing `face` (UV.x runs top -> bottom).
static func rune_strip(top: Vector3, bottom: Vector3, w: float, face: Vector3) -> Array:
	var along := (bottom - top).normalized()
	var side := along.cross(face).normalized() * (w * 0.5)
	var nn := face.normalized()
	var v := PackedVector3Array([top - side, top + side, bottom - side, bottom + side])
	var n := PackedVector3Array([nn, nn, nn, nn])
	var uv := PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1)])
	return _arrays_of(v, n, uv, PackedInt32Array([0, 2, 1, 1, 2, 3]))


static func _arrays_of(v: PackedVector3Array, n: PackedVector3Array, uv: PackedVector2Array, ix: PackedInt32Array) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = ix
	return arrays


## The rune node: one keep_separate mesh (cached per key) with one surface per [arrays, material] entry, on `pivot`.
## Shadows off; the kit drives its glow_boost (veterancy / haste / death), _extra_process its cast `flare`.
func add_runes(pivot: Node3D, key: String, surfaces: Array) -> MeshInstance3D:
	var k := "rune_mesh|" + key
	var am: ArrayMesh = _g3a.get(k)
	if am == null:
		am = ArrayMesh.new()
		for s: Array in surfaces:
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, s[0])
			am.surface_set_material(am.get_surface_count() - 1, s[1])
		_g3a[k] = am
	var mi := add_part(pivot, am, null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Runes")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_runes = mi
	return mi


# ================================================================ G3a hero layer: close-camera aura

## The kingdom aura (AURA_KINDS): embers rising from the hem (fire), soul wisps spiralling up (shadow), snow motes
## drifting down around the body (ice), fireflies blinking around her (nature). Looping, built once per kind, emits
## only near the camera on Medium+ graphics (_extra_process). Child of `parent` at `at` (local).
func add_aura(kind: StringName, parent: Node3D, at: Vector3) -> GPUParticles3D:
	if not aura_allowed():
		return null   # Low graphics (and every quiet run): no aura node at all
	var p := GPUParticles3D.new()
	p.name = "HeroAura"
	var spec: Dictionary = {
		&"embers": {"amount": 14, "life": 1.7, "size": 0.085},
		&"wisps": {"amount": 10, "life": 2.4, "size": 0.085},
		&"snow": {"amount": 14, "life": 3.4, "size": 0.05},
		&"fireflies": {"amount": 9, "life": 3.2, "size": 0.06},
	}.get(kind, {"amount": 10, "life": 2.0, "size": 0.06})
	p.amount = spec["amount"]
	p.lifetime = spec["life"]
	p.randomness = 0.5
	p.emitting = false
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-1.6, -3.0, -1.6), Vector3(3.2, 3.6, 3.2)) if kind == &"snow" \
		else AABB(Vector3(-1.6, -0.5, -1.6), Vector3(3.2, 3.8, 3.2))
	p.process_material = _aura_process(kind)
	p.draw_pass_1 = _aura_draw(kind, float(spec["size"]))
	p.position = at
	parent.add_child(p)
	_aura = p
	return p


## Test hook: >= 0 forces the graphics tier the aura sees (GameSettings.GFX_*); -1 = the real setting.
static var aura_quality_override: int = -1
static var _gfx_q: int = -1
static var _gfx_frame: int = -1000


## The aura follows the Graphics quality setting (GameSettings.effective_graphics_quality, re-read every 60 frames):
## off on Low (also every headless / -s run unless `-- --gfx=<tier>`), on from Medium up.
static func aura_allowed() -> bool:
	if aura_quality_override >= 0:
		return aura_quality_override >= GameSettings.GFX_MEDIUM
	var f := Engine.get_process_frames()
	if f - _gfx_frame >= 60 or _gfx_q < 0:
		_gfx_frame = f
		_gfx_q = GameSettings.effective_graphics_quality()
	return _gfx_q >= GameSettings.GFX_MEDIUM


static func _aura_process(kind: StringName) -> ParticleProcessMaterial:
	var k := "aura_pm|" + String(kind)
	if _g3a.has(k):
		return _g3a[k]
	var pm := ParticleProcessMaterial.new()
	var g := Gradient.new()
	var sc := Curve.new()
	pm.turbulence_enabled = true
	match kind:
		&"embers":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = 0.50
			pm.emission_ring_inner_radius = 0.28
			pm.emission_ring_height = 0.15
			pm.direction = Vector3.UP
			pm.spread = 18.0
			pm.initial_velocity_min = 0.35
			pm.initial_velocity_max = 0.8
			pm.gravity = Vector3(0, 0.3, 0)
			pm.damping_min = 0.2
			pm.damping_max = 0.5
			pm.turbulence_noise_strength = 0.9
			pm.turbulence_noise_scale = 2.2
			pm.turbulence_influence_min = 0.05
			pm.turbulence_influence_max = 0.15
			g.set_color(0, Color(1.0, 0.92, 0.55, 1.0))
			g.set_color(1, Color(0.75, 0.12, 0.04, 0.0))
			g.add_point(0.35, Color(1.0, 0.55, 0.14, 0.95))
			sc.add_point(Vector2(0, 0.5))
			sc.add_point(Vector2(0.15, 1.0))
			sc.add_point(Vector2(1, 0.1))
		&"wisps":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = 0.55
			pm.emission_ring_inner_radius = 0.30
			pm.emission_ring_height = 0.1
			pm.direction = Vector3.UP
			pm.spread = 12.0
			pm.initial_velocity_min = 0.25
			pm.initial_velocity_max = 0.5
			pm.gravity = Vector3.ZERO
			pm.tangential_accel_min = 0.25
			pm.tangential_accel_max = 0.5
			pm.turbulence_noise_strength = 1.2
			pm.turbulence_noise_scale = 1.6
			pm.turbulence_influence_min = 0.08
			pm.turbulence_influence_max = 0.2
			g.set_color(0, Color(0.95, 0.80, 1.0, 0.0))
			g.set_color(1, Color(0.30, 0.05, 0.55, 0.0))
			g.add_point(0.2, Color(0.90, 0.62, 1.0, 1.0))
			g.add_point(0.6, Color(0.58, 0.20, 1.0, 0.7))
			sc.add_point(Vector2(0, 0.4))
			sc.add_point(Vector2(0.3, 1.0))
			sc.add_point(Vector2(1, 0.3))
		&"snow":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			pm.emission_box_extents = Vector3(0.95, 0.15, 0.95)
			pm.direction = Vector3.DOWN
			pm.spread = 20.0
			pm.initial_velocity_min = 0.25
			pm.initial_velocity_max = 0.45
			pm.gravity = Vector3(0, -0.2, 0)
			pm.damping_min = 0.3
			pm.damping_max = 0.6
			pm.turbulence_noise_strength = 0.8
			pm.turbulence_noise_scale = 1.8
			pm.turbulence_influence_min = 0.04
			pm.turbulence_influence_max = 0.12
			g.set_color(0, Color(0.85, 0.95, 1.0, 0.0))
			g.set_color(1, Color(0.55, 0.85, 1.0, 0.0))
			g.add_point(0.15, Color(0.92, 0.98, 1.0, 1.0))
			g.add_point(0.8, Color(0.70, 0.90, 1.0, 0.8))
			sc.add_point(Vector2(0, 1.0))
			sc.add_point(Vector2(1, 0.6))
		_:  # fireflies
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 0.9
			pm.direction = Vector3.UP
			pm.spread = 180.0
			pm.initial_velocity_min = 0.04
			pm.initial_velocity_max = 0.14
			pm.gravity = Vector3(0, 0.03, 0)
			pm.turbulence_noise_strength = 1.4
			pm.turbulence_noise_scale = 1.3
			pm.turbulence_influence_min = 0.1
			pm.turbulence_influence_max = 0.25
			g.set_color(0, Color(0.85, 1.0, 0.45, 0.0))
			g.set_color(1, Color(0.85, 1.0, 0.45, 0.0))
			g.add_point(0.15, Color(0.92, 1.0, 0.50, 1.0))
			g.add_point(0.32, Color(0.70, 0.95, 0.30, 0.15))
			g.add_point(0.5, Color(0.95, 1.0, 0.55, 1.0))
			g.add_point(0.7, Color(0.70, 0.95, 0.30, 0.2))
			g.add_point(0.85, Color(0.92, 1.0, 0.50, 0.9))
			sc.add_point(Vector2(0, 1.0))
			sc.add_point(Vector2(1, 1.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	var ct := CurveTexture.new()
	ct.curve = sc
	pm.scale_curve = ct
	_g3a[k] = pm
	return pm


static func _aura_draw(kind: StringName, size: float) -> QuadMesh:
	var k := "aura_draw|%s|%s" % [kind, size]
	if _g3a.has(k):
		return _g3a[k]
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.disable_fog = true  # G-E 5: an additive quad must not fog
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.billboard_keep_scale = true
	sm.vertex_color_use_as_albedo = true
	sm.albedo_texture = mote_texture()
	var e := 2.6 if kind == &"embers" or kind == &"fireflies" else 1.8
	sm.albedo_color = Color(e, e, e, 1.0)
	q.material = sm
	_g3a[k] = q
	return q
