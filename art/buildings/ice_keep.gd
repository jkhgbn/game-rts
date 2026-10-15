extends Node3D
## Rime Keep ("the Glacier Throne") visual model: idle animation + the state hooks of art-keep.md 8.2-8.8,
## Ice look from kingdom-ice.md 8.1. The geometry is built by art/buildings/ice_keep_build.gd (run it
## WINDOWED to regenerate ice_keep.tscn: headless drops MultiMesh buffers). Gate on local -Z.
## Every hook is safe to call before _ready (cached, applied in _ready).

signal destroyed_finished

const DEFAULT_TEAM := Color(0.45, 0.75, 0.95)
const GLOW_DEFAULT := Color(0.75, 0.92, 1.00)
const IDLE_RIM := Color(0.45, 0.74, 0.98)
const IDLE_RIM_STRENGTH := 0.2
## In-game grade pass (2026-09-30): the keep was the brightest thing on screen. The team-coloured crystals are
## CRYSTAL_DARKEN darker than the kingdom colour, the snow / silver ~17 % darker (ice_keep.tscn), the glow parts under
## the bloom (GLOW_BOOST), the ground frost a hard 1 m rim (ice_keep_ground.gdshader).
const CRYSTAL_DARKEN := 0.15
const GLOW_BOOST := 0.3
const HALO_SPEED := deg_to_rad(8.0)
const HALO_Y := 12.0
const HALO_R := 2.8
const TIP_Y := 12.3
const TIP_SPIN := deg_to_rad(10.0)
const HEIGHT := 16.1 # model-space height used by the construction rise (8.2)
const CROWN_BASE := 5.1 # the crown cluster grows out of the top terrace
const POLE_X := 1.72 # banner poles, between the gatehouse and the front towers
## Battered terraces: [half-size bottom, half-size top, y bottom, y top] (A.8).
const TERRACES: Array = [[2.85, 2.65, 0.8, 2.4], [2.2, 2.0, 2.4, 3.9], [1.6, 1.45, 3.9, 5.2]]
const SWIRL_SPEED := deg_to_rad(-24.0)
const CRUSH_PIVOT := 0.8 # plinth top: everything above it sinks on collapse
## G-B Ice: the Ice paint layer's surface kind per painted material of ice_keep.tscn (by resource name).
const PART_KINDS := {"DarkStone": 1, "Stone": 0, "Snow": 4, "Crystal": 3}
const FLOATING: Array[StringName] = [&"Tip", &"Halo"]
const CROWN: Array[StringName] = [&"CrystalMain", &"CrystalL", &"CrystalR", &"Core", &"CrownShards"]
const NO_CRUSH: Array[StringName] = [&"PlinthLower", &"Rubble", &"Rubble2", &"GroundSpikes"]
## Bottom / top (model space) of parts whose AABB is unreliable (MultiMeshes are empty headless).
const SPANS := {
	# Snow, icicles, corner spikes and ground spikes pop in (no rise) once the top terrace is up.
	&"SnowCaps": Vector2(5.2, 5.2), &"Icicles": Vector2(5.2, 5.2), &"Spikes": Vector2(5.2, 5.2),
	&"GroundSpikes": Vector2(5.2, 5.2), &"Windows": Vector2(1.2, 3.5), &"CrownShards": Vector2(5.0, 7.5),
	&"GateGlow": Vector2(0.8, 4.1), &"BannerPoles": Vector2(0.8, 5.3), &"Rubble": Vector2(0.0, 0.6),
}

var _team_color: Color = DEFAULT_TEAM
var _health_ratio: float = 1.0
var _progress: float = 1.0
var _selected: bool = false
var _destroyed: bool = false
var _t: float = 0.0
var _pulse_t: float = 10.0
var _halo_mult: float = 1.0
var _tip_bob: float = 0.12
var _tip_spin: float = TIP_SPIN
var _agitated: bool = false
var _rumble: bool = false
var _sel: float = 0.0
var _halo_broken: bool = false
var _halo_crystal: bool = false  ## G-E 7: the halo shards are lit crystals (no glow instance uniforms)
var _floating_shown: bool = true
var _painted_mats: Array[ShaderMaterial] = []
var _crystal_mat: ShaderMaterial
var _glow_mat: ShaderMaterial
var _banner_mat: ShaderMaterial
var _ground_mat: ShaderMaterial
var _sel_tween: Tween
var _float_tween: Tween
var _outline_tween: Tween
var _ready_done: bool = false
var _parts: Array[Node3D] = [] # rising parts (construction) in model space
var _spans: Array[Vector2] = []
var _orig: Dictionary = {} # Node3D -> Transform3D

@onready var _model: Node3D = $Model
@onready var _halo: Node3D = $Model/Halo
@onready var _halo_mm: MultiMeshInstance3D = $Model/Halo/HaloShards
@onready var _tip: Node3D = $Model/Tip
@onready var _core: GeometryInstance3D = $Model/Core
@onready var _crystal_r: Node3D = $Model/CrystalR
@onready var _gate_glow: GeometryInstance3D = $Model/GateGlow
@onready var _rubble: Node3D = $Model/Rubble
@onready var _rubble2: Node3D = $Model/Rubble2
@onready var _banners: Array[Node3D] = [$Model/Banner1, $Model/Banner2]
@onready var _poles: Node3D = $Model/BannerPoles
@onready var _crown_light: OmniLight3D = $CrownLight
@onready var _gate_light: OmniLight3D = $GateLight
@onready var _snow: GPUParticles3D = $SnowMotes
@onready var _mist: GPUParticles3D = $FrostMist
@onready var _mist2: GPUParticles3D = $FrostMist2
@onready var _swirl: GPUParticles3D = $FrostSwirl
@onready var _smoke: Array[GPUParticles3D] = [$Smoke1, $Smoke2]
@onready var _frost: Array[GPUParticles3D] = [$FrostFlare1, $FrostFlare2]
@onready var _burst: GPUParticles3D = $TrainBurst
@onready var _build_ring: GPUParticles3D = $BuildRing
@onready var _dust: GPUParticles3D = $CollapseDust
@onready var _shatter: GPUParticles3D = $Shatter
@onready var _outline: GeometryInstance3D = $Outline


## Halo shard i (0-5) transform inside the Halo node; shared with ice_keep_build.gd.
static func halo_xf(i: int) -> Transform3D:
	var th: float = TAU * float(i) / 6.0
	var r := Vector3(cos(th), 0.0, sin(th))
	var k: Vector3 = r.cross(Vector3.UP).normalized()
	return Transform3D(Basis(k, deg_to_rad(-15.0)) * Basis(Vector3.UP, float(i) * 0.9), r * HALO_R)


func _ready() -> void:
	_make_unique_materials()
	# Per-keep copies of what the states edit (the .tscn resources are shared by every instance).
	_halo_mm.multimesh = _halo_mm.multimesh.duplicate() as MultiMesh
	_reshape_halo()
	_burst.process_material = _burst.process_material.duplicate() as ParticleProcessMaterial
	_build_ring.process_material = _build_ring.process_material.duplicate() as ParticleProcessMaterial
	for c: Node in _model.get_children():
		var n := c as Node3D
		if n == null:
			continue
		_orig[n] = n.transform
		if n.name in FLOATING or n == _rubble2:
			continue
		_parts.append(n)
		_spans.append(_span_of(n))
	_build_tier_parts()
	_ready_done = true
	_update_halo()
	set_team_color(_team_color)
	set_construction_progress(_progress)
	set_health_ratio(_health_ratio)
	_set_sel(1.0 if _selected else 0.0)
	_apply_tier()


func _span_of(n: Node3D) -> Vector2:
	if SPANS.has(n.name):
		return SPANS[n.name]
	var gi := n as VisualInstance3D
	if gi == null:
		return Vector2(n.position.y, n.position.y)
	var box: AABB = n.transform * gi.get_aabb()
	return Vector2(box.position.y, box.end.y)


## Materials in the .tscn are shared by every instance: duplicate them once so selecting or
## damaging one keep never changes another.
func _make_unique_materials() -> void:
	var dups: Dictionary = {}
	for node: Node in find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		var mat := gi.material_override
		if mat == null or not (mat is ShaderMaterial):
			continue
		if not dups.has(mat):
			var d: ShaderMaterial = (mat as ShaderMaterial).duplicate()
			dups[mat] = d
			var path: String = d.shader.resource_path
			if path.ends_with("glow.gdshader"):
				_glow_mat = d
			elif path.ends_with("banner.gdshader"):
				_banner_mat = d
			elif path.ends_with("ground.gdshader"):
				_ground_mat = d
			else:
				_painted_mats.append(d)
				if d.resource_name == "Crystal":
					_crystal_mat = d
		gi.material_override = dups[mat]
	# G-B Ice: the painted parts take the Ice paint layer (crystal ice, snow, frost-rimmed ice-stone).
	for m: ShaderMaterial in _painted_mats:
		IceShapes.ice_part(m, int(PART_KINDS.get(m.resource_name, IceShapes.K_STONE)))
	# Warm interior light in the windows: the shared glow material's per-instance tint (no 9th material, Art Lab B8);
	# the team colour stays on the crown, halo and gate.
	var win := get_node_or_null(^"Model/Windows") as GeometryInstance3D
	if win and not IceShapes.legacy:
		win.set_instance_shader_parameter(&"tint_color", Color(IceShapes.WARM_WINDOW, 1.0))


func _process(delta: float) -> void:
	_t += delta
	var fast: float = 1.0
	if _pulse_t < 0.6:
		_pulse_t += delta
		fast = 3.0
		var k: float = _pulse_t / 0.6
		var b: float = 1.0 + 2.0 * (1.0 - k) * (1.0 - k) if _pulse_t > 0.1 else 1.0 + 20.0 * _pulse_t
		_gate_glow.set_instance_shader_parameter(&"boost", b)
		if _pulse_t >= 0.6:
			_gate_glow.set_instance_shader_parameter(&"boost", 1.0)
	if _destroyed:
		if _rumble:
			_model.position = Vector3(sin(_t * TAU * 15.0) * 0.08, 0.0, cos(_t * TAU * 13.0) * 0.08)
		return
	_halo.rotation.y += HALO_SPEED * _halo_mult * fast * delta
	_halo.position.y = HALO_Y + 0.15 * sin(_t * 1.4)
	_tip.position.y = TIP_Y + _tip_bob * sin(_t * 1.2)
	_tip.rotation.y += _tip_spin * delta
	_swirl.rotation.y += SWIRL_SPEED * _halo_mult * fast * delta
	var shimmer: float = 0.9 + 0.1 * sin(_t * 1.7)
	if _agitated:
		shimmer = 0.7 + 0.15 * sin(_t * 23.0) + 0.15 * sin(_t * 37.0)
	var p: float = _progress
	_tier_process(delta)
	_crown_light.light_energy = 1.5 * shimmer * p * (1.3 if _tier >= 3 else 1.0)
	_gate_light.light_energy = 1.0 * (0.9 + 0.1 * sin(_t * 1.7)) * p * (2.0 if _pulse_t < 0.3 else 1.0)


# --- Hooks (art-keep.md 8.8) ---------------------------------------------------------------

func set_team_color(c: Color) -> void:
	_team_color = c
	if not _ready_done:
		return
	var glow: Color = _glow_color()
	var is_default: bool = c.is_equal_approx(DEFAULT_TEAM)
	_crystal_mat.set_shader_parameter(&"base_color", c.darkened(CRYSTAL_DARKEN))
	_glow_mat.set_shader_parameter(&"glow_color", glow)
	_banner_mat.set_shader_parameter(&"cloth_color", c)
	_banner_mat.set_shader_parameter(&"stripe_color", Color(0.15, 0.35, 0.60) if is_default else c.darkened(0.55))
	_banner_mat.set_shader_parameter(&"glyph_color", glow)
	_ground_mat.set_shader_parameter(&"glow_color", glow)
	(_burst.process_material as ParticleProcessMaterial).color = glow
	(_build_ring.process_material as ParticleProcessMaterial).color = glow
	_crown_light.light_color = Color(0.70, 0.88, 1.00) if is_default else glow
	_gate_light.light_color = glow
	_apply_rim()


func set_health_ratio(r: float) -> void:
	_health_ratio = clampf(r, 0.0, 1.0)
	if not _ready_done or _destroyed:
		return
	var below50: bool = _health_ratio < 0.5
	var below25: bool = _health_ratio < 0.25
	var dmg: float = 1.0 if below25 else (0.6 if below50 else (1.0 - _health_ratio) * 0.5)
	for m: ShaderMaterial in _painted_mats:
		m.set_shader_parameter(&"damage", dmg)
	_ground_mat.set_shader_parameter(&"damage", dmg)
	var built: bool = _progress >= 1.0
	for s: GPUParticles3D in _smoke:
		s.emitting = below50 and built
	for s: GPUParticles3D in _frost:
		s.emitting = below25 and built
	_rubble2.visible = below50 and _progress > 0.0
	_halo_mult = 3.0 / 8.0 if below50 else 1.0
	if not _halo_crystal:
		_halo_mm.set_instance_shader_parameter(&"energy", 1.5 if below50 else 2.5)
	_halo_broken = below25
	_update_halo()
	_tip_bob = 0.3 if below25 else 0.12
	_tip_spin = deg_to_rad(45.0) if below25 else TIP_SPIN
	_agitated = below25
	if built:
		_crystal_r.visible = not below50
		_banners[0].visible = not below25


func set_construction_progress(p: float) -> void:
	var was: float = _progress
	_progress = clampf(p, 0.0, 1.0)
	if not _ready_done or _destroyed:
		return
	var done: bool = _progress >= 1.0
	var h: float = _progress * HEIGHT
	for i: int in _parts.size():
		var n: Node3D = _parts[i]
		var sp: Vector2 = _spans[i]
		if done:
			n.visible = true
			n.transform = _orig[n]
			continue
		n.visible = h >= sp.x and _progress > 0.0
		var s: float = clampf((h - sp.x) / maxf(sp.y - sp.x, 0.01), 0.05, 1.0)
		_squash(n, s, sp.x)
	# Floating parts pop in at 95 % with a 0.5 s scale-in.
	var show_float: bool = _progress >= 0.95
	if show_float != _floating_shown:
		_floating_shown = show_float
		if _float_tween:
			_float_tween.kill()
		for nm: StringName in FLOATING:
			var f: Node3D = _model.get_node(NodePath(nm))
			f.visible = show_float
			f.scale = Vector3.ONE * (0.01 if show_float else 1.0)
		if show_float:
			_float_tween = create_tween().set_parallel(true)
			for nm: StringName in FLOATING:
				_float_tween.tween_property(_model.get_node(NodePath(nm)), "scale", Vector3.ONE, 0.5) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ground_mat.set_shader_parameter(&"build", _progress)
	_snow.emitting = done
	_mist.emitting = done
	_swirl.emitting = done
	_build_ring.emitting = not done
	if _outline_tween:
		_outline_tween.kill()
	if not done:
		_outline.visible = true
		_outline.set_instance_shader_parameter(&"energy", 2.0)
	elif was < 1.0:
		# Finished: outline fades out, flash from the top, damage looks come back.
		_outline_tween = create_tween()
		_outline_tween.tween_method(func(e: float) -> void:
			_outline.set_instance_shader_parameter(&"energy", e), 2.0, 0.0, 0.5)
		_outline_tween.tween_callback(_outline.hide)
		_fire_burst(Vector3(0, 14.5, 0), Vector3.UP, 180.0, 2.0, 5.0, 40.0 / 72.0)
	else:
		_outline.visible = false
	_apply_rim()
	_apply_tier()
	if done and was < 1.0:
		set_health_ratio(_health_ratio)


func play_training_pulse() -> void:
	if _destroyed:
		return
	_pulse_t = 0.0
	_fire_burst(Vector3(0, 2.0, -3.5), Vector3(0, 0, -1), 60.0, 2.0, 4.0, 1.0 / 3.0)


func set_selected(on: bool) -> void:
	_selected = on
	if not _ready_done:
		return
	if _sel_tween:
		_sel_tween.kill()
	_sel_tween = create_tween()
	_sel_tween.tween_method(_set_sel, _sel, 1.0 if on else 0.0, 0.15 if on else 0.25)


## The 3.0 s collapse (art-keep.md 8.5, Ice version from kingdom-ice.md 8.1: the crown crystal
## topples and shatters into 12 shards). Ends with a frosty wreck and `destroyed_finished`.
## Tweens belong to this node, so freeing it mid-sequence is safe.
func play_destroyed() -> void:
	if _destroyed or not _ready_done:
		return
	_destroyed = true
	_pulse_t = 10.0
	_snow.emitting = false
	_swirl.emitting = false
	_build_ring.emitting = false
	for s: GPUParticles3D in _smoke:
		s.emitting = true
	_outline.visible = false
	if _float_tween:
		_float_tween.kill()
	for nm: StringName in FLOATING:
		(_model.get_node(NodePath(nm)) as Node3D).scale = Vector3.ONE
	# The crown falls as one piece around a pivot at its base on the top terrace.
	var pivot := Node3D.new()
	pivot.name = "ToppleCrown"
	pivot.position = Vector3(0, CROWN_BASE, 0)
	_model.add_child(pivot)
	for nm: StringName in CROWN:
		var n: Node3D = _model.get_node(NodePath(nm))
		n.visible = true
		n.transform = _orig[n]
		n.reparent(pivot, true)
	_core.set_instance_shader_parameter(&"boost", 3.0)
	_crown_light.light_energy = 5.0
	var tw := create_tween().set_parallel(true)
	# 0.0-0.15 flash; 0.0-0.6 the tip and the halo rise and spin up.
	tw.tween_property(_crown_light, "light_energy", 1.5, 0.15)
	tw.tween_property(_tip, "position:y", _tip.position.y + 1.5, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_tip, "rotation:y", _tip.rotation.y + PI, 0.6)
	tw.tween_property(_halo, "position:y", _halo.position.y + 1.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_halo, "rotation:y", _halo.rotation.y + PI * 0.8, 0.6)
	# 0.6 tip and halo burst into sparkles.
	tw.tween_callback(func() -> void:
		_tip.visible = false
		_halo.visible = false
		_fire_burst(_model.transform * Vector3(0, 13.2, 0), Vector3.UP, 180.0, 3.0, 6.0, 1.0)).set_delay(0.6)
	# 0.6-1.3 the crown tilts 40 deg sideways and drops, then shatters into 12 shards.
	tw.tween_property(pivot, "rotation:z", deg_to_rad(40.0), 0.7).set_delay(0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(pivot, "position:y", CROWN_BASE - 2.5, 0.7).set_delay(0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		pivot.hide()
		if _tier_root:
			_tier_root.hide()   # the tier crystals shatter with the crown
		_shatter.restart()
		_fire_dust(5.0)).set_delay(1.3)
	# 1.0-2.2 terraces sink to 35 % with a rumble; banners, icicles hidden at 1.6.
	tw.tween_callback(func() -> void: _rumble = true).set_delay(1.0)
	tw.tween_method(_crush, 0.0, 1.0, 1.2).set_delay(1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		for b: Node3D in _banners:
			b.visible = false
		_poles.visible = false
		_fire_dust(1.2)).set_delay(1.6)
	tw.tween_callback(func() -> void:
		_rumble = false
		_model.position = Vector3.ZERO
		_mist2.emitting = true
		_rubble2.visible = true).set_delay(2.2)
	# 2.2-3.0 lights fade to 30 %, the frost turns to grey slush, debris grows.
	tw.tween_property(_crown_light, "light_energy", 1.5 * 0.3, 0.8).set_delay(2.2)
	tw.tween_property(_gate_light, "light_energy", 1.0 * 0.3, 0.8).set_delay(2.2)
	tw.tween_method(func(v: float) -> void: _ground_mat.set_shader_parameter(&"scorch", v), 0.0, 1.0, 0.8).set_delay(2.2)
	tw.tween_property(_rubble, "scale", Vector3(1.1, 1.6, 1.1), 0.8).set_delay(2.2)
	for m: ShaderMaterial in _painted_mats:
		m.set_shader_parameter(&"damage", 1.0)
	tw.tween_callback(func() -> void: destroyed_finished.emit()).set_delay(3.0)


# --- Internals -------------------------------------------------------------------------------

## Scales a Model child along y about the model-space height `pivot_y` (from its original transform).
func _squash(n: Node3D, sy: float, pivot_y: float) -> void:
	n.transform = Transform3D(Basis.from_scale(Vector3(1.0, sy, 1.0)), Vector3(0.0, pivot_y * (1.0 - sy), 0.0)) * _orig[n]


func _crush(k: float) -> void:
	var sy: float = lerpf(1.0, 0.35, k)
	for n: Node3D in _parts:
		if n.name in NO_CRUSH or n.name in CROWN:
			continue
		_squash(n, sy, CRUSH_PIVOT)


## G-E 7 (docs/art/ge_review.md item 7): the six halo shards were squat hexagonal prisms in the unshaded glow material:
## seen face-on from the RTS camera they read as floating sheets of white paper round the spire. They become thin,
## tall, faceted crystals in the lit crystal material (team tint, darker than the glow core, so their value stays
## under the spire), tilted out by _update_halo.
func _reshape_halo() -> void:
	if IceShapes.legacy or _crystal_mat == null:
		return
	_halo_mm.multimesh.mesh = IceShapes.crystal(0.12, 0.85, 0.55, 0.4)
	_halo_mm.material_override = _crystal_mat
	_halo_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo_crystal = true


## Halo shard transforms; under 25 % HP two shards are gone (scaled to nothing).
func _update_halo() -> void:
	var mm: MultiMesh = _halo_mm.multimesh
	if mm.instance_count < 6:
		return
	for i: int in 6:
		var xf: Transform3D = halo_xf(i)
		if _halo_crystal:
			# Lean the tall shard's tip out from the spire (+15 deg on top of the shared -15 deg tilt).
			var r := xf.origin.normalized()
			xf.basis = Basis(r.cross(Vector3.UP).normalized(), deg_to_rad(-15.0)) * xf.basis
		if _halo_broken and (i == 1 or i == 4):
			xf.basis = Basis.from_scale(Vector3.ZERO)
		mm.set_instance_transform(i, xf)


func _fire_burst(pos: Vector3, dir: Vector3, spread: float, v_min: float, v_max: float, ratio: float) -> void:
	var pm := _burst.process_material as ParticleProcessMaterial
	pm.direction = dir
	pm.spread = spread
	pm.initial_velocity_min = v_min
	pm.initial_velocity_max = v_max
	_burst.position = pos
	_burst.amount_ratio = ratio
	_burst.restart()


func _fire_dust(model_y: float) -> void:
	_dust.position = Vector3(0.0, model_y, 0.0)
	_dust.restart()


func _glow_color() -> Color:
	return GLOW_DEFAULT if _team_color.is_equal_approx(DEFAULT_TEAM) else _team_color.lightened(0.35)


func _set_sel(v: float) -> void:
	_sel = v
	_apply_rim()


func _apply_rim() -> void:
	if not _ready_done:
		return
	var team_rim: Color = _team_color.lightened(0.2)
	var rim: Color = IDLE_RIM.lerp(team_rim, _sel)
	var strength: float = lerpf(IDLE_RIM_STRENGTH, 0.9, _sel)
	if _progress > 0.0 and _progress < 1.0:
		rim = _glow_color() # parts glow in the team colour while they rise
		strength = maxf(strength, 1.0)
	for m: ShaderMaterial in _painted_mats:
		m.set_shader_parameter(&"rim_color", rim)
		m.set_shader_parameter(&"rim_strength", strength)
	_banner_mat.set_shader_parameter(&"rim_color", rim)
	_banner_mat.set_shader_parameter(&"rim_strength", lerpf(0.0, 0.9, _sel))
	_glow_mat.set_shader_parameter(&"boost_mult", lerpf(GLOW_BOOST, GLOW_BOOST * 1.4, _sel))


# --- Keep tiers (G-B Ice, docs/art/gb_ice_buildings.md) --------------------------------------
# Keep.set_tier_now calls set_tier(t) (no placeholder gold rings once the model has it), play_tier_up() unless quiet,
# set_upgrading(on) while the upgrade runs (the next tier's crystals grow with Keep.upgrade_progress()).
#   Stronghold (2): four bastion crystals lean out of the plinth corners (+ eight satellites), an outer halo of eight
#                   crystal shards turning the other way around the crown.
#   Citadel (3):    + a ring of six tall crystals around the crown on the top terrace, four sentinel crystals orbiting
#                   at mid height, the outer halo full (twelve shards), the crown light 30 % brighter.

const BASTION_CORNER := 3.05
const OUTER_HALO_R := 4.4
const OUTER_HALO_Y := 9.2
const SENTINEL_R := 5.3
const SENTINEL_Y := 7.4

var _tier: int = 1
var _upgrading: bool = false
var _tier_root: Node3D
var _t2_static: MultiMeshInstance3D
var _t3_static: MultiMeshInstance3D
var _outer_halo: Node3D
var _outer_mm: MultiMeshInstance3D
var _sentinels: Node3D
var _sentinel_mm: MultiMeshInstance3D
var _base_xf: Dictionary = {}   # MultiMeshInstance3D -> Array of Transform3D (full-size instances)
var _grow: Dictionary = {}      # MultiMeshInstance3D -> current size 0..1
var _pop_t: float = 10.0        # tier-up pop animation clock


## The keep's tier look (1 Keep, 2 Stronghold, 3 Citadel). Safe before _ready.
func set_tier(t: int) -> void:
	_tier = clampi(t, 1, 3)
	_apply_tier()


## While the keep upgrades, the next tier's crystals grow (with the building's upgrade_progress()).
func set_upgrading(on: bool) -> void:
	_upgrading = on
	if _ready_done and not _destroyed:
		_build_ring.emitting = on or _progress < 1.0
	_apply_tier()


## The upgrade finished: a burst from the crown, a light flash, the new crystals pop in.
func play_tier_up() -> void:
	if not _ready_done or _destroyed or IceShapes.legacy:
		return
	_pop_t = 0.0
	_fire_burst(Vector3(0, 14.5, 0), Vector3.UP, 180.0, 3.0, 7.0, 1.0)
	var tw := create_tween()
	tw.tween_property(_crown_light, "light_energy", 6.0, 0.12)
	tw.tween_property(_crown_light, "light_energy", 1.5, 0.6)


func _build_tier_parts() -> void:
	if IceShapes.legacy or _crystal_mat == null:
		return
	_tier_root = Node3D.new()
	_tier_root.name = "TierParts"
	_model.add_child(_tier_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9113
	# Stronghold: bastion crystals at the plinth corners, each with two satellites along the edges.
	var xs: Array = []
	for c: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var corner := Vector3(c.x * BASTION_CORNER, 0.55, c.y * BASTION_CORNER)
		var out := Vector3(c.x, 0.0, c.y).normalized()
		xs.append(Transform3D(IceShapes.lean(out, 20.0) * Basis(Vector3.UP, rng.randf() * TAU), corner))
		for s: float in [-1.0, 1.0]:
			var along := Vector3(c.x, 0, 0) if s < 0.0 else Vector3(0, 0, c.y)
			var p := corner - along * 1.0 + Vector3(0, -0.15, 0)
			xs.append(Transform3D(IceShapes.lean(out + along * 0.6, 34.0) * Basis(Vector3.UP, rng.randf() * TAU)
				* Basis.from_scale(Vector3.ONE * rng.randf_range(0.42, 0.55)), p))
	_t2_static = _tier_mm("StrongholdBastions", IceShapes.crystal(0.5, 2.0, 1.2, 0.0), _crystal_mat, xs, _tier_root)
	# Outer halo (glow shards), turning against the inner one.
	_outer_halo = Node3D.new()
	_outer_halo.name = "OuterHalo"
	_outer_halo.position = Vector3(0, OUTER_HALO_Y, 0)
	_tier_root.add_child(_outer_halo)
	var hx: Array = []
	for i: int in 12:
		var th: float = TAU * float(i) / 12.0
		var r := Vector3(cos(th), 0.0, sin(th))
		var y: float = 0.0 if i % 3 != 2 else 1.1
		hx.append(Transform3D(Basis(r.cross(Vector3.UP).normalized(), deg_to_rad(12.0)) * Basis(Vector3.UP, float(i) * 1.3),
			r * OUTER_HALO_R + Vector3(0, y, 0)))
	# Team crystal, not glow: the crown core / halo stay the keep's few bright points (Art Lab R5).
	_outer_mm = _tier_mm("OuterHaloShards", IceShapes.crystal(0.2, 0.3, 0.5, 0.5), _crystal_mat, hx, _outer_halo)
	# Citadel: a ring of tall crystals on the top terrace around the crown cluster.
	var cx: Array = []
	for i: int in 6:
		var th: float = TAU * float(i) / 6.0 + PI / 6.0
		var out := Vector3(cos(th), 0.0, sin(th))
		var tall: float = 1.0 if i % 2 == 0 else 0.72
		cx.append(Transform3D(IceShapes.lean(out, 16.0) * Basis(Vector3.UP, rng.randf() * TAU)
			* Basis.from_scale(Vector3(1.0, tall, 1.0)), out * 1.32 + Vector3(0, 5.1, 0)))
	_t3_static = _tier_mm("CitadelCrown", IceShapes.crystal(0.3, 1.7, 0.9, 0.0), _crystal_mat, cx, _tier_root)
	# Citadel: four sentinel crystals (bipyramids) orbiting at mid height.
	_sentinels = Node3D.new()
	_sentinels.name = "Sentinels"
	_sentinels.position = Vector3(0, SENTINEL_Y, 0)
	_tier_root.add_child(_sentinels)
	var sx: Array = []
	for i: int in 4:
		var th: float = TAU * float(i) / 4.0 + PI / 4.0
		sx.append(Transform3D(Basis(Vector3.UP, th), Vector3(cos(th), 0.0, sin(th)) * SENTINEL_R))
	_sentinel_mm = _tier_mm("SentinelCrystals", IceShapes.crystal(0.32, 0.45, 0.75, 0.75), _crystal_mat, sx, _sentinels)


func _tier_mm(nm: String, mesh: Mesh, mat: Material, xfs: Array, parent: Node3D) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.material_override = mat
	if mat == _crystal_mat:
		mmi.set_instance_shader_parameter(&"ao_bottom", 0.0)
		mmi.set_instance_shader_parameter(&"ao_height", HEIGHT)
	else:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	_base_xf[mmi] = xfs
	_grow[mmi] = 1.0
	return mmi


## Which tier groups show, and how grown (an upgrade grows the next tier's groups).
func _apply_tier() -> void:
	if not _ready_done or _tier_root == null:
		return
	_tier_root.visible = _progress >= 1.0 and not _destroyed
	var next: int = _tier + 1 if _upgrading else _tier
	_t2_static.visible = next >= 2
	_outer_halo.visible = next >= 2
	_t3_static.visible = next >= 3
	_sentinels.visible = next >= 3
	_outer_mm.multimesh.visible_instance_count = -1 if next >= 3 else 8
	var k: float = _upgrade_k() if _upgrading else 1.0
	for mmi: MultiMeshInstance3D in [_t2_static, _outer_mm]:
		_set_grow(mmi, k if (_upgrading and _tier + 1 == 2) else 1.0)
	for mmi: MultiMeshInstance3D in [_t3_static, _sentinel_mm]:
		_set_grow(mmi, k if (_upgrading and _tier + 1 == 3) else 1.0)


## 0.15 .. 1 from the building's upgrade_progress() (a few nodes up: Building > visual > model).
func _upgrade_k() -> float:
	var n: Node = get_parent()
	for i: int in 3:
		if n == null:
			break
		if n.has_method(&"upgrade_progress"):
			return lerpf(0.15, 1.0, clampf(float(n.call(&"upgrade_progress")), 0.0, 1.0))
		n = n.get_parent()
	return 0.5


func _set_grow(mmi: MultiMeshInstance3D, k: float) -> void:
	if is_equal_approx(float(_grow[mmi]), k):
		return
	_grow[mmi] = k
	var xfs: Array = _base_xf[mmi]
	for i: int in xfs.size():
		var xf: Transform3D = xfs[i]
		mmi.multimesh.set_instance_transform(i, Transform3D(xf.basis.scaled_local(Vector3.ONE * maxf(k, 0.01)), xf.origin))


func _tier_process(delta: float) -> void:
	if _tier_root == null or not _tier_root.visible:
		return
	_outer_halo.rotation.y -= HALO_SPEED * 0.6 * _halo_mult * delta
	_outer_halo.position.y = OUTER_HALO_Y + 0.2 * sin(_t * 0.9 + 1.0)
	if _sentinels.visible:
		_sentinels.rotation.y += deg_to_rad(6.0) * delta
		_sentinels.position.y = SENTINEL_Y + 0.25 * sin(_t * 1.1)
	if _upgrading:
		_apply_tier()   # the next tier grows with the upgrade
		_halo.rotation.y += HALO_SPEED * 1.5 * delta   # the crown spins up while it gathers frost
	if _pop_t < 0.6:
		_pop_t += delta
		var u: float = clampf(_pop_t / 0.6, 0.0, 1.0)
		var s: float = 1.0 + 0.25 * sin(u * PI) * (1.0 - u)
		_tier_root.scale = Vector3(1.0, s, 1.0)
		if _pop_t >= 0.6:
			_tier_root.scale = Vector3.ONE
