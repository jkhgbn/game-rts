class_name FireHallModel
extends Node3D
## Visual model of Vessa's barracks, the Ember Hall (task 5.V1): a forge hall with a gable roof in the team
## colour, a tall forge chimney (dominant vertical, glowing coals), a furnace + anvil and a weapon rack.
## Same hooks as the keeps (docs/design/art-keep.md 8.8):
##   set_team_color(c), set_construction_progress(p), set_health_ratio(r) (smoke < 50 %, fire < 25 %),
##   play_training_pulse(), play_destroyed() (emits `destroyed_finished` after 3.0 s; the wreck stays until
##   freed), set_selected(on).
## Everything is built in code at _ready (primitives, 7 materials made per instance so selecting one hall never
## lights another). Hooks are safe before _ready (values cached). No tweens or timers: one _process.
## Gate side is local -Z. Footprint 6 x 6 m (collision is Building's). 1 OmniLight, shadows off.
## `ShadowHallModel` (shadow_hall.gd) extends this and overrides the palette + `_build_structure`
## (IceHallModel / NatureHallModel too: every A.9 addition below is opt-in and unused by them).
## Task A.9 (polish + mesh merge): the parts are baked per tier into shared ArrayMeshes (BuildingMerge, one
## surface per material): ~10 geometry nodes instead of ~30. Opt-in extras for subclasses: `_scaffold` (shown while
## the site rises), `_wreck` (broken walls / charred beams shown at the collapse), `_show_below_50/25` (roof holes).

signal destroyed_finished

const PAINTED: Shader = preload("res://art/shaders/painted.gdshader")
const RUNE_GLOW: Shader = preload("res://art/shaders/rune_glow.gdshader")
const BANNER: Shader = preload("res://art/shaders/banner.gdshader")
const NOISE: Texture2D = preload("res://art/shaders/paint_noise.tres")
const RIM_IDLE := Color(0.55, 0.65, 0.85)
const BMG := preload("res://art/buildings/fire_hall_merge.gd")
const PVC := preload("res://art/buildings/painted_vc.gd")
const PULSE_TIME := 0.6
const DESTROY_TIME := 3.0
const PLINTH_TOP := 0.8

# Palette (art-keep.md 0.2), overridden by subclasses in _setup_palette().
var kingdom_color := Color(0.85, 0.30, 0.12)
var glow_color := Color(1.0, 0.58, 0.16)
var stone_color := Color(0.30, 0.26, 0.24)
var dark_color := Color(0.10, 0.08, 0.09)
var metal_color := Color(0.62, 0.40, 0.16)
var stripe_color := Color(0.55, 0.08, 0.05)
var glyph_color := Color(1.0, 0.75, 0.30)
var glyph_shape: int = 0
var smoke_color := Color(0.16, 0.14, 0.13)
var dust_color := Color(0.24, 0.21, 0.19)
var decal_color := Color(0.09, 0.04, 0.02)
var crack_strength: float = 0.7
var crack_glow: float = 0.35   ## painted-vc halls: crack emission x this (under the bloom level; 1 = painted.gdshader)
var light_color := Color(1.0, 0.5, 0.15)
var light_energy: float = 1.8
var danger_ramp_hot := Color(1.0, 0.9, 0.5)
var danger_ramp_mid := Color(1.0, 0.45, 0.1)
var danger_ramp_end := Color(0.5, 0.06, 0.0)

# Materials (created per instance in _make_materials).
var mat_stone: ShaderMaterial
var mat_dark: ShaderMaterial
var mat_metal: ShaderMaterial
var mat_team: ShaderMaterial
var mat_banner: ShaderMaterial
var mat_glow: ShaderMaterial
var mat_gate: ShaderMaterial
var _painted: Array[ShaderMaterial] = []
var _glows: Array[ShaderMaterial] = []
var _decal_mat: StandardMaterial3D
var _glow_vc: ShaderMaterial  ## the merged glow material (PaintedVC.convert_glow), null when not merged
var _light_pool: MeshInstance3D  ## warm ground pool standing in for the light (painted-vc halls, no real light)
var _proxy_light: OmniLight3D  ## the detached light _omni made in budget mode (never in the tree)
static var _hall_quads: Dictionary = {}
static var _hall_pms: Dictionary = {}

# Nodes filled by _build_structure().
var _body: Node3D
var _light: OmniLight3D
var _falling: Node3D  ## tilts and drops on collapse (chimney / bell tower), then hides
var _fall_axis := Vector3.RIGHT
var _fall_deg: float = -30.0
var _hide_below_50: Array[Node3D] = []  ## lost cap
var _hide_below_25: Array[Node3D] = []  ## a banner
var _hide_on_collapse: Array[Node3D] = []  ## banners, racks, ornaments (hidden at 1.6 s)
var _idle_fx: Array[GPUParticles3D] = []
var _smoke_points: Array[Vector3] = []
var _blaze_points: Array[Vector3] = []
var _rubble2_points: Array[Vector3] = []
var _gate_pos := Vector3(0.0, 1.6, -2.6)
var _top_y: float = 8.8
# A.9 opt-in extras (null / empty = off; children of the root, not of Body, except the damage details).
var _scaffold: Node3D  ## construction scaffolding, visible while 0 < progress < 1
var _wreck: Node3D  ## collapse leftovers, shown at 1.6 s of play_destroyed
var _show_below_50: Array[Node3D] = []  ## damage details (roof holes) shown below 50 % HP
var _show_below_25: Array[Node3D] = []  ## shown below 25 % HP
var mat_hole: StandardMaterial3D  ## dark unshaded (holes, doorways); made by _hole_mat()

# Construction bookkeeping.
var _parts: Array[Node3D] = []
var _part_xf: Array[Transform3D] = []
var _part_b: PackedFloat32Array = PackedFloat32Array()
var _part_t: PackedFloat32Array = PackedFloat32Array()
var _collapse_idx: PackedInt32Array = PackedInt32Array()
var _height: float = 1.0
var _fall_xf: Transform3D

# State particles / helpers.
var _add_quad: Mesh
var _mix_quad: Mesh
var _fire_ramp: GradientTexture1D
var _smoke: Array[GPUParticles3D] = []
var _blaze: Array[GPUParticles3D] = []
var _train_burst: GPUParticles3D
var _build_ring: GPUParticles3D
var _build_flash: GPUParticles3D
var _dust: GPUParticles3D
var _outline: MultiMeshInstance3D
var _outline_mat: ShaderMaterial
var _rubble: MultiMeshInstance3D
var _rubble2: MultiMeshInstance3D
var _debris: MultiMeshInstance3D
var _team_ramps: Array[Gradient] = []

var _t: float = 0.0
var _ready_done: bool = false
var _team_color: Color
var _team_set: bool = false
var _progress: float = 1.0
var _was_building: bool = false
var _outline_fade: float = 0.0
var _health_ratio: float = 1.0
var _flicker_amp: float = 0.1
var _pulse_left: float = 0.0
var _selected: bool = false
var _sel_k: float = 0.0
var _destroyed: bool = false
var _destroy_t: float = 0.0
var _destroy_step: int = 0


func _ready() -> void:
	_setup_palette()
	if not _team_set:
		_team_color = kingdom_color
	_t = randf() * 10.0
	_make_materials()
	_make_particle_quads()
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_build_ground()
	_build_structure()
	_collect_parts()
	_build_state_nodes()
	if _vc_wanted():
		# B8: every painted part draws with ONE vertex-coloured material (the team material, painted_vc shader).
		PVC.convert(self, mat_team, _vc_team(), [mat_hole] if mat_hole else [], _vc_skip())
		# R5 (hall: 2-4 glow points): the lava / rime veins glow under the bloom level (like the Stables), so the
		# coals, gate and lanterns stay the building's few bright points.
		mat_team.set_shader_parameter(&"crack_energy", crack_glow)
	if _budget_wanted() and mat_banner and mat_banner.shader == BANNER:
		mat_banner.set_shader_parameter(&"glyph_energy", 0.2)   # R5: the glyph reads as paint, not as a glow point
	_make_light_pool()
	_post_build()
	if _budget_wanted():
		# B8: every rune glow (coals, gate, windows, outline...) draws with ONE channel-array material; the code keeps
		# driving the source glow materials, _process copies them over (PaintedVC.sync_glow).
		_glow_vc = PVC.convert_glow(self, _vc_glow_skip())
	_ready_done = true
	set_team_color(_team_color)
	set_construction_progress(_progress)
	_sel_k = 1.0 if _selected else 0.0
	_apply_rim_and_glow()
	if _destroyed:
		_destroyed = false
		play_destroyed()


func _process(delta: float) -> void:
	_t += delta
	if not _ready_done:
		return
	if _destroyed:
		_process_destroyed(delta)
		PVC.sync_glow(_glow_vc)
		return
	_idle_motion(delta)
	var n: float = sin(_t * 8.1) * 0.5 + sin(_t * 13.7) * 0.5
	var flicker: float = _light_wave(n)
	var mult: float = 1.0
	if _pulse_left > 0.0:
		_pulse_left = maxf(_pulse_left - delta, 0.0)
		var k: float = 1.0 - _pulse_left / PULSE_TIME
		var boost: float = 1.0 + 2.0 * (k / 0.17) if k < 0.17 else 1.0 + 2.0 * pow(1.0 - (k - 0.17) / 0.83, 2.0)
		mat_gate.set_shader_parameter(&"boost", boost * _sel_boost())
		mult = 2.0 if _pulse_left > 0.3 else 1.0
	_light.light_energy = light_energy * flicker * mult * _progress
	if _light_pool:
		_light_pool.visible = _light.visible and _progress > 0.0
		_light_pool.transparency = clampf(1.0 - _light.light_energy / maxf(light_energy, 0.01) * 0.8, 0.0, 1.0)
	var target: float = 1.0 if _selected else 0.0
	if _sel_k != target:
		_sel_k = move_toward(_sel_k, target, delta / (0.15 if _selected else 0.25))
		_apply_rim_and_glow()
	if _outline_fade > 0.0:
		_outline_fade = maxf(_outline_fade - delta / 0.5, 0.0)
		_outline_mat.set_shader_parameter(&"energy", 2.0 * _outline_fade)
		if _outline_fade <= 0.0:
			_outline.visible = false
	PVC.sync_glow(_glow_vc)


# --- Hooks ---

## Construction progress 0..1: glowing outline at 0, parts rise from the ground in height order, flash at 1.
func set_construction_progress(p: float) -> void:
	_progress = clampf(p, 0.0, 1.0)
	if not _ready_done or _destroyed:
		return
	var building: bool = _progress < 1.0
	var h: float = _progress * _height
	for i: int in _parts.size():
		var part: Node3D = _parts[i]
		if not building:
			part.transform = _part_xf[i]
			part.visible = true
			continue
		var b: float = _part_b[i]
		if h < b:
			part.visible = false
			continue
		part.visible = true
		_squash(i, clampf((h - b) / maxf(_part_t[i] - b, 0.01), 0.05, 1.0), b, Vector3.ZERO)
	for fx: GPUParticles3D in _idle_fx:
		fx.emitting = not building
	if _scaffold:
		_scaffold.visible = building and _progress > 0.0
	_build_ring.emitting = building
	if building:
		_outline.visible = true
		_outline_fade = 0.0
		_outline_mat.set_shader_parameter(&"energy", 2.0)
	elif _was_building:
		_outline_fade = 1.0
		_fire(_build_flash)
	else:
		_outline.visible = false
	_was_building = building
	_apply_health()
	_apply_rim_and_glow()


## A unit walked out of the gate: 0.6 s gate flash, light x2, spark burst. Restarts if retriggered.
func play_training_pulse() -> void:
	if _destroyed:
		return
	_pulse_left = PULSE_TIME
	if _ready_done and _progress >= 1.0:
		_fire(_train_burst)


## HP ratio 0..1: smoke + lost cap below 50 %, fire + lost banner below 25 %. Reverts when healed.
func set_health_ratio(r: float) -> void:
	_health_ratio = clampf(r, 0.0, 1.0)
	if _ready_done and not _destroyed:
		_apply_health()


## Collapse: 3.0 s sequence, then `destroyed_finished`; the smoking wreck stays until freed.
func play_destroyed() -> void:
	if _destroyed:
		return
	_destroyed = true
	if not _ready_done:
		return
	_destroy_t = 0.0
	_destroy_step = 0
	for i: int in _parts.size():
		_parts[i].transform = _part_xf[i]
		_parts[i].visible = _parts[i].visible or _progress >= 1.0
	_outline.visible = false
	_build_ring.emitting = false
	if _scaffold:
		_scaffold.visible = false
	for fx: GPUParticles3D in _idle_fx:
		fx.emitting = false
	for s: GPUParticles3D in _smoke:
		s.emitting = true
	for b: GPUParticles3D in _blaze:
		b.emitting = true
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"damage", 1.0)


## Selection: team rim on every painted material, glow boost 1.4.
func set_selected(on: bool) -> void:
	_selected = on


## Team colour: roof, shields, banners, selection rim, construction / training sparks.
func set_team_color(c: Color) -> void:
	_team_color = c
	_team_set = true
	if not _ready_done:
		return
	mat_team.set_shader_parameter(&"base_color", c)
	mat_banner.set_shader_parameter(&"cloth_color", _cloth_of(c))
	var glow: Color = glow_color if c.is_equal_approx(kingdom_color) else c.lightened(0.35)
	_outline_mat.set_shader_parameter(&"glow_color", glow)
	for g: Gradient in _team_ramps:
		g.set_color(0, Color(glow, 1.0))
		g.set_color(1, Color(glow, 0.0))
	_apply_rim_and_glow()


# --- Kingdom-specific (overridden by ShadowHallModel) ---

func _setup_palette() -> void:
	pass


func _cloth_of(c: Color) -> Color:
	return c


## B8 vertex-colour merge (PaintedVC) on when the team material is a plain painted.gdshader one (the Stables bring
## their own one-material shader and stay as they are).
func _vc_wanted() -> bool:
	return mat_team != null and (mat_team.shader == PAINTED or mat_team.shader == PVC.PAINTED_VC)


## The other budget passes (shared particle quads / process materials, one decal material for the contact decal and
## the stains, no real light): the painted-vc halls, and the Nature halls (they override it; their own merge is
## NatureVC). The Stables keep their own setup.
func _budget_wanted() -> bool:
	return _vc_wanted()


## Painted materials whose base_color is the team colour (their parts follow set_team_color). Subclasses add theirs.
func _vc_team() -> Array:
	return [mat_team]


## Painted materials changed at run time on their own (not through the _painted loops): left out of the merge.
func _vc_skip() -> Array:
	return []


## Runs once after the build and the painted merge, before the glow merge (the Nature halls merge their NatureKit
## materials here).
func _post_build() -> void:
	pass


## Glow materials to keep out of the glow merge (none: every change on a source is copied each frame).
func _vc_glow_skip() -> Array:
	return []


func _light_wave(n: float) -> float:
	return 1.0 - _flicker_amp + _flicker_amp * n


func _idle_motion(_delta: float) -> void:
	pass


## Ember Hall parts (Body space, gate -Z). Heights: plinth 0.8, walls 3.8, roof ridge 6.3, chimney horns 9.1.
## Tiers (one merged mesh each): PlinthBase, Walls (+ gate, windows, forge), Roof (stone gables, 4 tile courses a
## side, crossed bargeboards, shield emblem), Chimney (stack + crown), WeaponRack, then the opt-in extras.
func _build_structure() -> void:
	_top_y = 9.1
	const HX := -0.4   # hall axis (walls shifted left, the forge sits on the right)
	const HZ := 0.3
	var box1: BoxMesh = _boxm(Vector3.ONE)
	# --- Plinth: two dark tiers, raised corner blocks, steps and a flagstone path at the gate.
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, 0.25, 0), mat_dark, Vector3.ZERO, Vector3(6.4, 0.5, 6.4)))
	it.append(BMG.item(box1, Vector3(0, 0.65, 0), mat_dark, Vector3.ZERO, Vector3(5.8, 0.3, 5.8)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(BMG.item(box1, Vector3(c.x * 2.72, 0.95, c.y * 2.72), mat_dark, Vector3.ZERO, Vector3(0.75, 0.4, 0.75)))
	it.append(BMG.item(box1, Vector3(-0.6, 0.14, -3.45), mat_dark, Vector3.ZERO, Vector3(2.9, 0.28, 0.55)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4401
	for i: int in 3:
		var p := Vector3(-0.6 + rng.randf_range(-0.35, 0.35), 0.04, -4.0 - 0.7 * i)
		it.append(BMG.item(box1, p, mat_dark, Vector3(0, rng.randf_range(-20, 20), 0),
			Vector3(rng.randf_range(0.8, 1.05), 0.1, rng.randf_range(0.55, 0.65))))
	# 2026-09-30 detail pass (Art Lab C2 / C3: the hall used a fifth of its vertex budget): a rim of worn flagstones
	# on the upper plinth tier, in two stone shades (extra painted shades cost nothing: one merged material).
	var drng := RandomNumberGenerator.new()   # its own seed: the older parts keep their layout
	drng.seed = 9901
	var flag_a: ShaderMaterial = _painted_mat(stone_color.lightened(0.12), 0.0, 0.0)
	var flag_b: ShaderMaterial = _painted_mat(stone_color.darkened(0.12), 0.0, 0.0)
	for k: int in 16:
		var side: int = k / 4
		var t: float = -2.2 + 1.47 * float(k % 4)
		var fp: Vector3 = [Vector3(t, 0, -2.62), Vector3(2.62, 0, t), Vector3(-t, 0, 2.62), Vector3(-2.62, 0, -t)][side]
		if fp.distance_to(Vector3(-0.6, 0, -2.62)) < 1.1:
			continue   # the gate steps
		it.append(BMG.item(box1, fp + Vector3(0, 0.815, 0), flag_a if k % 3 != 1 else flag_b,
			Vector3(drng.randf_range(-1.5, 1.5), drng.randf_range(-6, 6), drng.randf_range(-1.5, 1.5)),
			Vector3(1.3, 0.07, 0.5) if side % 2 == 0 else Vector3(0.5, 0.07, 1.3)))
	_merged("PlinthBase", "plinth", it)
	# --- Walls tier: stone box, dark base course and corner pillars, arched gate, windows, the forge.
	it = []
	it.append(BMG.item(box1, Vector3(HX, 2.3, HZ), mat_stone, Vector3.ZERO, Vector3(4.8, 3.0, 4.4)))
	it.append(BMG.item(box1, Vector3(HX, 1.0, HZ), mat_dark, Vector3.ZERO, Vector3(5.1, 0.4, 4.7)))
	for c: Vector2 in [Vector2(-2.8, -1.9), Vector2(2.0, -1.9), Vector2(-2.8, 2.5), Vector2(2.0, 2.5)]:
		it.append(BMG.item(box1, Vector3(c.x, 2.4, c.y), mat_dark, Vector3.ZERO, Vector3(0.62, 3.2, 0.62)))
	# Gate (-Z): dark frame with a round arch, glowing portcullis (box + half disc), bronze keystone and imposts.
	it.append(BMG.item(box1, Vector3(-0.6, 1.95, -2.05), mat_dark, Vector3.ZERO, Vector3(2.6, 2.3, 0.7)))
	it.append(BMG.item(_cyl(1.3, 1.3, 0.7, 16), Vector3(-0.6, 3.1, -2.05), mat_dark, Vector3(90, 0, 0)))
	it.append(BMG.item(box1, Vector3(-0.6, 1.8, -2.44), mat_gate, Vector3.ZERO, Vector3(1.6, 2.0, 0.12)))
	it.append(BMG.item(box1, Vector3(-0.6, 2.95, -2.44), mat_gate, Vector3.ZERO, Vector3(1.3, 0.3, 0.12)))
	it.append(BMG.item(box1, Vector3(-0.6, 3.22, -2.44), mat_gate, Vector3.ZERO, Vector3(0.85, 0.24, 0.12)))
	it.append(BMG.item(box1, Vector3(-0.6, 4.3, -2.1), mat_metal, Vector3.ZERO, Vector3(0.55, 0.65, 0.85)))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, Vector3(-0.6 + sx * 1.32, 3.1, -2.1), mat_metal, Vector3.ZERO, Vector3(0.45, 0.3, 0.85)))
	# Warm windows (portcullis glow, so they flash with the training pulse): one on the right, two at the back.
	it.append(BMG.item(box1, Vector3(2.06, 2.5, -0.1), mat_dark, Vector3.ZERO, Vector3(0.2, 1.3, 1.0)))
	it.append(BMG.item(box1, Vector3(2.12, 2.45, -0.1), mat_gate, Vector3.ZERO, Vector3(0.1, 0.95, 0.65)))
	for x: float in [-2.0, -0.45]:
		it.append(BMG.item(box1, Vector3(x, 2.5, 2.56), mat_dark, Vector3.ZERO, Vector3(1.0, 1.3, 0.2)))
		it.append(BMG.item(box1, Vector3(x, 2.45, 2.62), mat_gate, Vector3.ZERO, Vector3(0.65, 0.95, 0.1)))
	# Forge (front right): furnace, bronze hood, glowing mouth, a stove pipe through the roof, anvil, coal heap.
	it.append(BMG.item(box1, Vector3(2.15, 1.65, -1.95), mat_dark, Vector3.ZERO, Vector3(1.7, 1.7, 1.5)))
	it.append(BMG.item(_prism(Vector3(2.1, 0.8, 1.8), 0.5), Vector3(2.15, 2.9, -1.95), mat_dark, Vector3(0, 90, 0)))
	it.append(BMG.item(box1, Vector3(2.15, 2.54, -1.95), mat_metal, Vector3.ZERO, Vector3(1.9, 0.14, 2.2)))
	it.append(BMG.item(box1, Vector3(2.15, 1.4, -2.72), mat_glow, Vector3.ZERO, Vector3(1.0, 0.65, 0.12)))
	it.append(BMG.item(_cyl(0.2, 0.24, 2.1, 8), Vector3(2.35, 4.15, -1.75), mat_metal))
	it.append(BMG.item(_cyl(0.38, 0.26, 0.24, 8), Vector3(2.35, 5.25, -1.75), mat_dark))
	it.append(BMG.item(box1, Vector3(0.95, 0.9, -2.95), mat_dark, Vector3.ZERO, Vector3(0.7, 0.2, 0.5)))
	it.append(BMG.item(box1, Vector3(0.95, 1.05, -2.95), mat_metal, Vector3.ZERO, Vector3(0.4, 0.3, 0.32)))
	it.append(BMG.item(box1, Vector3(0.95, 1.36, -2.95), mat_dark, Vector3.ZERO, Vector3(0.85, 0.32, 0.45)))
	it.append(BMG.item(_cyl(0.0, 0.16, 0.5, 6), Vector3(1.6, 1.36, -2.95), mat_dark, Vector3(0, 0, -90)))
	for i: int in 6:
		var p := Vector3(2.55 + rng.randf_range(-0.35, 0.35), 0.62 + (0.3 if i > 3 else 0.0), -3.05 + rng.randf_range(-0.12, 0.12))
		it.append(BMG.item(box1, p, mat_dark, Vector3(rng.randf_range(-30, 30), rng.randf() * 90.0, rng.randf_range(-30, 30)),
			Vector3.ONE * rng.randf_range(0.36, 0.48)))
	# Firewood stacked against the back wall (bronze reads as seasoned wood).
	for l: Vector3 in [Vector3(-1.2, 1.0, 2.72), Vector3(-1.2, 0.72, 3.02), Vector3(-1.2, 1.38, 2.74)]:
		it.append(BMG.item(_cyl(0.19, 0.19, 1.6, 7), l, mat_metal, Vector3(0, 0, 90)))
	# Detail pass: quoins (alternating long / short blocks) up the four corner pillars, a quench barrel with iron
	# hoops and a water face beside the forge, more coal lumps, and three more logs on the firewood stack.
	var quoin: ShaderMaterial = _painted_mat(stone_color.lightened(0.08), 0.0, crack_strength * 0.5)
	for c: Vector2 in [Vector2(-2.8, -1.9), Vector2(2.0, -1.9), Vector2(-2.8, 2.5), Vector2(2.0, 2.5)]:
		for q: int in 5:
			var long_x: bool = (q % 2 == 0)
			it.append(BMG.item(box1, Vector3(c.x, 1.35 + 0.6 * q, c.y), quoin if q % 2 == 0 else mat_stone,
				Vector3(0, drng.randf_range(-3, 3), 0), Vector3(0.82 if long_x else 0.7, 0.26, 0.7 if long_x else 0.82)))
	var water: ShaderMaterial = _painted_mat(Color(0.12, 0.16, 0.18), 0.6, 0.0)
	var bar := Vector3(0.45, 0.8, 2.78)
	it.append(BMG.item(_cyl(0.3, 0.26, 0.62, 12), bar + Vector3(0, 0.31, 0), mat_metal))
	for y: float in [0.12, 0.5]:
		it.append(BMG.item(_cyl(0.315, 0.315, 0.06, 12), bar + Vector3(0, y, 0), mat_dark))
	it.append(BMG.item(_cyl(0.27, 0.27, 0.02, 12), bar + Vector3(0, 0.6, 0), water))
	for i: int in 6:
		var p := Vector3(2.9 + drng.randf_range(-0.3, 0.25), 0.9 + drng.randf_range(0.0, 0.2), -2.6 + drng.randf_range(-0.35, 0.35))
		it.append(BMG.item(box1, p, mat_dark, Vector3(drng.randf_range(-30, 30), drng.randf() * 90.0, drng.randf_range(-30, 30)),
			Vector3.ONE * drng.randf_range(0.22, 0.34)))
	for l: Vector3 in [Vector3(-1.2, 0.72, 2.66), Vector3(-1.2, 1.05, 3.0), Vector3(-1.2, 1.4, 3.06)]:
		it.append(BMG.item(_cyl(0.16, 0.16, 1.45, 7), l, flag_b if l.y > 1.0 else mat_metal, Vector3(0, 0, 90)))
	_merged("Walls", "walls", it)
	# --- Roof tier: stone gable core, 4 tile courses a side, bronze ridge, crossed bargeboards, gable shield.
	it = []
	_gable_roof(it, HX, HZ, 3.35, 3.72, 2.58, 5.9, 5.0, 4, mat_stone, mat_team, mat_metal)
	it.append(BMG.item(_cyl(0.6, 0.6, 0.16, 10), Vector3(HX, 5.3, -2.27), mat_team, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.72, 0.72, 0.1, 10), Vector3(HX, 5.3, -2.22), mat_metal, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.2, 0.2, 0.14, 6), Vector3(HX, 5.3, -2.38), mat_metal, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.48, 0.48, 0.16, 10), Vector3(HX, 5.0, 2.87), mat_dark, Vector3(90, 0, 0)))
	# A dormer on the left slope, near the front: stone cheeks, a team gable, a warm window looking out (-X).
	var dz: float = HZ - 1.15
	it.append(BMG.item(box1, Vector3(-2.3, 4.72, dz), mat_stone, Vector3.ZERO, Vector3(1.3, 1.05, 1.15)))
	it.append(BMG.item(box1, Vector3(-2.97, 4.66, dz), mat_gate, Vector3.ZERO, Vector3(0.1, 0.52, 0.48)))
	it.append(BMG.item(box1, Vector3(-2.99, 4.34, dz), mat_metal, Vector3.ZERO, Vector3(0.18, 0.1, 0.7)))
	it.append(BMG.item(_prism(Vector3(1.45, 0.62, 1.7), 0.5), Vector3(-2.2, 5.55, dz), mat_team, Vector3(0, 90, 0)))
	it.append(BMG.item(box1, Vector3(-2.2, 5.88, dz), mat_metal, Vector3.ZERO, Vector3(1.75, 0.16, 0.2)))
	var roof := _merged("Roof", "roof", it)
	_hide_on_collapse.append(roof)
	# Damage: a caved-in patch on the left slope (< 50 %), a burning hole on the right slope (< 25 %).
	var hole_l: Vector3 = _gable_point(HX, 3.35, 3.72, 2.58, -1.0, 0.55, 0.32, HZ + 1.1)
	var hole_r: Vector3 = _gable_point(HX, 3.35, 3.72, 2.58, 1.0, 0.4, 0.32, HZ + 1.0)
	_show_below_50.append(_roof_hole("RoofHoleL", roof, hole_l, -1.0, 3.35, 2.58, false))
	_show_below_25.append(_roof_hole("RoofHoleR", roof, hole_r, 1.0, 3.35, 2.58, true))
	# --- Dominant vertical: the forge chimney (back right), tapered stack, bronze bands, horned crown, coals.
	var chimney := Node3D.new()
	chimney.name = "Chimney"
	chimney.position = Vector3(1.95, PLINTH_TOP, 1.7)
	_body.add_child(chimney)
	it = []
	it.append(BMG.item(box1, Vector3(0, 1.7, 0), mat_stone, Vector3.ZERO, Vector3(1.75, 3.4, 1.75)))
	it.append(BMG.item(_cyl(1.05, 1.28, 3.9, 4), Vector3(0, 5.3, 0), mat_stone, Vector3(0, 45, 0)))
	for y: float in [4.55, 6.45]:
		it.append(BMG.item(_cyl(1.34, 1.34, 0.3, 4), Vector3(0, y, 0), mat_metal, Vector3(0, 45, 0)))
	# Detail pass: the stack's stones stand out in courses (a few proud blocks per face, two shades).
	for k: int in 12:
		var face: int = k % 4
		var fy: float = 0.6 + 0.62 * float(k / 4) + 0.2 * float(face % 2)
		var fd: Vector3 = [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)][face]
		var along := Vector3(absf(fd.z), 0, absf(fd.x))
		it.append(BMG.item(box1, fd * 0.88 + along * drng.randf_range(-0.4, 0.4) + Vector3(0, fy, 0),
			quoin if k % 2 == 0 else flag_b, Vector3(0, 0, 0), along * 0.6 + fd.abs() * 0.12 + Vector3(0, 0.3, 0)))
	_merged("ChimneyStack", "chimney_stack", it, chimney)
	it = []
	it.append(BMG.item(_cyl(1.55, 1.05, 0.8, 4), Vector3(0, 7.6, 0), mat_dark, Vector3(0, 45, 0)))
	it.append(BMG.item(box1, Vector3(0, 7.93, 0), mat_glow, Vector3.ZERO, Vector3(1.35, 0.3, 1.35)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var d := Vector3(c.x, 0.0, c.y).normalized()
		var b: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(24.0))
		it.append(BMG.item_xf(_cyl(0.0, 0.2, 1.1, 4), Transform3D(b, d * 1.02 + Vector3(0, 8.0, 0) + b * Vector3(0, 0.5, 0)),
			mat_metal))
	var crown := _merged("ChimneyTop", "chimney_top", it, chimney)
	var chim_banner := _banner("ChimneyBanner", Vector2(1.1, 2.2), Vector3(0, 5.2, -0.98), 0.0, chimney)
	_falling = chimney
	_fall_axis = Vector3.FORWARD
	_fall_deg = -32.0
	_hide_below_50.append(crown)
	_hide_below_25.append(chim_banner)
	var bl := _banner("BannerL", Vector2(0.9, 2.0), Vector3(-2.3, 2.75, -2.62), 0.0)
	_hide_on_collapse.append(bl)
	_hide_on_collapse.append(chim_banner)
	# --- Weapon rack (left side, -X): posts, bar, three big blades, two round team shields with bronze bosses.
	var rack := Node3D.new()
	rack.name = "WeaponRack"
	_body.add_child(rack)
	it = []
	for z: float in [-1.3, 1.6]:
		it.append(BMG.item(box1, Vector3(-3.05, 1.65, z), mat_metal, Vector3.ZERO, Vector3(0.35, 2.3, 0.35)))
	it.append(BMG.item(box1, Vector3(-3.05, 2.6, 0.15), mat_metal, Vector3.ZERO, Vector3(0.35, 0.35, 3.3)))
	for i: int in 3:
		it.append(BMG.item(_prism(Vector3(0.4, 2.1, 0.14), 0.5), Vector3(-3.25, 1.95, -0.6 + 0.75 * i), mat_metal,
			Vector3(180, 90, 8.0 - 8.0 * i)))
	for z: float in [-0.55, 1.05]:
		it.append(BMG.item(_cyl(0.55, 0.55, 0.18, 8), Vector3(-2.9, 3.2, z), mat_team, Vector3(0, 0, 90)))
		it.append(BMG.item(_cyl(0.2, 0.2, 0.14, 6), Vector3(-3.02, 3.2, z), mat_metal, Vector3(0, 0, 90)))
	_merged("RackParts", "rack", it, rack)
	_hide_on_collapse.append(rack)
	# Light: one flickering forge light at the furnace / gate.
	_light = _omni(Vector3(0.9, 2.3, -3.4), 7.0)
	# Idle particles: chimney flames + smoke, forge sparks, pipe smoke (~50).
	var up_fire := _pm(Vector3.UP, 12.0, 1.2, 1.8, Vector3.ZERO, 0.6, 0.15, _fire_ramp)
	up_fire.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	up_fire.emission_box_extents = Vector3(0.5, 0.05, 0.5)
	_idle_fx.append(_particles("ChimneyFire", chimney, Vector3(0, 8.05, 0), 20, 0.7, up_fire, _add_quad, false))
	var sm := _pm(Vector3.UP, 10.0, 0.8, 1.1, Vector3(0.25, 0.0, 0.0), 0.6, 1.9,
		_ramp(Color(smoke_color, 0.45), Color(smoke_color, 0.0), false))
	_idle_fx.append(_particles("ChimneySmoke", chimney, Vector3(0, 8.6, 0), 12, 3.5, sm, _mix_quad, false))
	var sp := _pm(Vector3(0, 0.6, -1), 35.0, 1.0, 2.2, Vector3(0, -3.0, 0), 0.12, 0.05, _fire_ramp)
	_idle_fx.append(_particles("ForgeSparks", _body, Vector3(2.15, 1.4, -2.8), 12, 0.9, sp, _add_quad, false))
	var ps := _pm(Vector3.UP, 8.0, 0.5, 0.8, Vector3(0.2, 0.0, 0.0), 0.3, 0.9,
		_ramp(Color(smoke_color, 0.35), Color(smoke_color, 0.0), false))
	_idle_fx.append(_particles("PipeSmoke", _body, Vector3(2.35, 5.45, -1.75), 6, 2.2, ps, _mix_quad, false))
	# Construction scaffolding and the collapse wreck.
	_build_scaffold(HX, HZ, 5.75, 5.4, 4.3)
	_build_wreck(HX, HZ, 4.8, 4.4, PLINTH_TOP + 3.0 * 0.3, Vector3(1.95, 1.75, 1.7), Vector3(1.75, 1.9, 1.75), 5151)
	_scorch_decal(Vector3(2.4, 0.035, -3.2), 3.4)
	# State particle anchors and lost-corner rubble.
	_smoke_points = [hole_l + Vector3(0, 0.3, 0), Vector3(0.6, 5.4, -1.2)]
	_blaze_points = [hole_r + Vector3(0, 0.2, 0), Vector3(1.9, 7.6, 1.7)]
	_rubble2_points = [Vector3(3.0, 0.9, 2.9), Vector3(2.4, 0.9, 3.2), Vector3(3.3, 0.5, 1.9), Vector3(1.3, 1.2, 2.7)]
	_gate_pos = Vector3(-0.6, 1.6, -2.7)


## Collapse leftovers (hidden until 1.6 s of play_destroyed): broken wall teeth on the squashed stubs (walls rect
## centre cx / cz, size sx x sz, stub top y `stub_top`), charred beams, two torn roof slabs, the stump of the tall
## element (`stump` centre, `stump_size`) and a few glowing embers.
func _build_wreck(cx: float, cz: float, sx: float, sz: float, stub_top: float, stump: Vector3,
		stump_size: Vector3, rng_seed: int) -> void:
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var it: Array = []
	var hx: float = sx * 0.5 - 0.3
	var hz: float = sz * 0.5 - 0.3
	for i: int in 7:
		var along: float = rng.randf_range(-0.85, 0.85)
		var p := Vector3(cx + along * hx, 0.0, cz + (1.0 if i % 2 == 0 else -1.0) * hz)
		if i % 4 >= 2:
			p = Vector3(cx + (1.0 if i % 2 == 0 else -1.0) * hx, 0.0, cz + along * hz)
		var s := Vector3(rng.randf_range(0.6, 1.1), rng.randf_range(0.55, 1.2), rng.randf_range(0.6, 0.85))
		p.y = stub_top + s.y * 0.5 - 0.15
		it.append(BMG.item(box1, p, mat_stone, Vector3(rng.randf_range(-10, 10), rng.randf_range(-20, 20),
			rng.randf_range(-12, 12)), s))
	it.append(BMG.item(box1, stump, mat_stone, Vector3.ZERO, stump_size))
	it.append(BMG.item(box1, stump + Vector3(-0.3, stump_size.y * 0.5 + 0.25, -0.2), mat_stone, Vector3(0, 20, 12),
		Vector3(0.75, 0.6, 0.75)))
	for i: int in 4:
		var p := Vector3(cx + rng.randf_range(-hx, hx) * 0.6, stub_top + rng.randf_range(0.15, 0.45),
			cz + rng.randf_range(-hz, hz) * 0.6)
		it.append(BMG.item(box1, p, mat_dark, Vector3(rng.randf_range(-28, 28), rng.randf() * 180.0,
			rng.randf_range(-20, 20)), Vector3(0.3, 0.3, rng.randf_range(3.0, 3.6))))
	for i: int in 2:
		var p := Vector3(cx + rng.randf_range(-hx, hx) * 0.5, stub_top + 0.2, cz + rng.randf_range(-hz, hz) * 0.5)
		it.append(BMG.item(box1, p, mat_team, Vector3(rng.randf_range(-25, 25), rng.randf() * 180.0,
			rng.randf_range(20, 32) * (1.0 if i == 0 else -1.0)), Vector3(1.5, 0.15, 1.8)))
	for i: int in 5:
		var p := Vector3(cx + rng.randf_range(-hx, hx) * 0.7, stub_top + 0.05, cz + rng.randf_range(-hz, hz) * 0.7)
		it.append(BMG.item(box1, p, mat_glow, Vector3(0, rng.randf() * 90.0, 20), Vector3.ONE * 0.36))
	_wreck = Node3D.new()
	_wreck.name = "Wreck"
	add_child(_wreck)
	_merged("WreckParts", "wreck", it, _wreck)
	_wreck.visible = false


# --- A.9 helpers (merged tiers, roofs, scaffolding) ---

## Merged part: `items` ([mesh, xf, material] in `parent` space) baked once per class + `key` into one mesh with a
## surface per material (BuildingMerge). Added under `parent` (default Body); height gradient from its own bottom.
func _merged(nm: String, key: String, items: Array, parent: Node3D = null, shadow: bool = true) -> MeshInstance3D:
	var mi: MeshInstance3D = BMG.instance(nm, "%s/%s" % [get_script().resource_path, key], items)
	var p: Node3D = parent if parent else _body
	p.add_child(mi)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var xf := Transform3D.IDENTITY
	var n: Node = p
	while n != null and n != self and n != _body:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	var bottom: float = (xf * mi.get_aabb()).position.y
	mi.set_instance_shader_parameter(&"ao_bottom", bottom)
	mi.set_instance_shader_parameter(&"ao_height", maxf(_top_y - bottom, 1.5))
	return mi


## Gable roof along Z (ridge on the Z axis at x = cx): a stone core whose triangles are the gables, `courses` tile
## rows per slope in `tile` (each tilted `tilt_deg` flatter than the roof so its lower edge lifts: stepped shingle
## lines from the high camera), a ridge cap and bargeboards in `trim` running `cross` metres past the ridge (Fire:
## crossed horns). Appended to `items`.
func _gable_roof(items: Array, cx: float, cz: float, half: float, eave_y: float, rise: float, depth: float,
		core_depth: float, courses: int, core: Material, tile: Material, trim: Material, cross: float = 0.8,
		tilt_deg: float = 10.0) -> void:
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var slope_l: float = sqrt(half * half + rise * rise)
	var a: float = atan2(rise, half)
	var hc: float = half - 0.35
	var ch: float = hc * tan(a) - 0.05
	items.append(BMG.item(_prism(Vector3(hc * 2.0, ch, core_depth), 0.5), Vector3(cx, eave_y + 0.08 + ch * 0.5, cz), core))
	var w: float = slope_l / courses + 0.2
	for s: float in [-1.0, 1.0]:
		var e := Vector3(cx + s * half, eave_y, cz)
		var u := Vector3(-s * cos(a), sin(a), 0.0)
		var n := Vector3(s * sin(a), cos(a), 0.0)
		for k: int in courses:
			var p: Vector3 = e + u * ((k + 0.5) * slope_l / courses) + n * 0.14
			items.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, -s * (a - deg_to_rad(tilt_deg)))
				.scaled_local(Vector3(w, 0.2, depth)), p), tile))
		for z: float in [cz - depth * 0.5 - 0.1, cz + depth * 0.5 + 0.1]:
			var p: Vector3 = e + u * (slope_l * 0.5 + cross * 0.5) + n * 0.28
			items.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, -s * a).scaled_local(
				Vector3(slope_l + cross + 0.2, 0.3, 0.24)), Vector3(p.x, p.y, z)), trim))
	items.append(BMG.item(_prism(Vector3(0.8, 0.4, depth + 0.1), 0.5), Vector3(cx, eave_y + rise + 0.12, cz), trim))


## A point on a `_gable_roof` slope: side -1 / +1, `t` 0 eave .. 1 ridge, `out` metres off the slope, at depth z.
func _gable_point(cx: float, half: float, eave_y: float, rise: float, side: float, t: float, out: float,
		z: float) -> Vector3:
	var a: float = atan2(rise, half)
	return Vector3(cx + side * half * (1.0 - t), eave_y + rise * t, z) + Vector3(side * sin(a), cos(a), 0.0) * out


## A caved-in roof patch (dark hole, broken rafters, loose tiles; embers when `burning`), child of `roof` so it
## squashes and hides with it. Hidden until _apply_health shows it.
func _roof_hole(nm: String, roof: Node3D, pos: Vector3, side: float, half: float, rise: float,
		burning: bool) -> MeshInstance3D:
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var a: float = atan2(rise, half)
	var b := Basis(Vector3.BACK, -side * a)
	var u: Vector3 = b * Vector3.RIGHT * -side   # up the slope
	var n: Vector3 = b * Vector3.UP
	var it: Array = []
	it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(1.3, 0.05, 1.35)), pos), _hole_mat()))
	if burning:
		it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(0.8, 0.05, 0.85)), pos + n * 0.03), mat_glow))
	for i: int in 3:
		var rb := Basis(n, deg_to_rad(-14.0 + 14.0 * i)) * b * Basis(Vector3.RIGHT, deg_to_rad(10.0 - 10.0 * i))
		it.append(BMG.item_xf(box1, Transform3D(rb.scaled_local(Vector3(0.15, 0.15, 1.55)),
			pos + u * (-0.4 + 0.4 * i) + n * 0.12), mat_dark))
	for i: int in 3:
		var tb: Basis = b * Basis(Vector3.RIGHT, deg_to_rad(18.0 + 12.0 * i)) * Basis(Vector3.UP, 0.7 * i)
		it.append(BMG.item_xf(box1, Transform3D(tb.scaled_local(Vector3(0.55, 0.1, 0.62)),
			pos + u * (0.75 - 0.2 * i) + b * Vector3(0, 0, -0.8 + 0.8 * i) + n * 0.12), mat_team))
	var mi := _merged(nm, nm.to_lower(), it, roof, false)
	mi.visible = false
	return mi


func _hole_mat() -> StandardMaterial3D:
	if mat_hole == null:
		mat_hole = StandardMaterial3D.new()
		mat_hole.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_hole.albedo_color = Color(dark_color.darkened(0.6), 1.0)
	return mat_hole


## Construction scaffolding around the walls (posts, two plank decks, side braces, a pallet of cut stone): one
## merged mesh in the trim colour (reads as timber), child of the root, visible while 0 < progress < 1.
func _build_scaffold(cx: float, cz: float, sx: float, sz: float, top: float) -> void:
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var it: Array = []
	var hx: float = sx * 0.5
	var hz: float = sz * 0.5
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(BMG.item(box1, Vector3(cx + c.x * hx, (top + 0.7) * 0.5, cz + c.y * hz), mat_metal, Vector3.ZERO,
			Vector3(0.2, top + 0.7, 0.2)))
	for y: float in [top * 0.5, top]:
		for s: float in [-1.0, 1.0]:
			it.append(BMG.item(box1, Vector3(cx, y, cz + s * hz), mat_metal, Vector3(0, 0, s * 2.0),
				Vector3(sx + 0.3, 0.1, 0.5)))
			it.append(BMG.item(box1, Vector3(cx + s * hx, y, cz), mat_metal, Vector3(s * 2.0, 0, 0),
				Vector3(0.5, 0.1, sz + 0.3)))
	var ang: float = atan2(top - 0.5, sz)
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.RIGHT, -ang * s).scaled_local(
			Vector3(0.12, 0.12, sqrt(sz * sz + (top - 0.5) * (top - 0.5)))), Vector3(cx + s * (hx + 0.12), (top + 0.5) * 0.5, cz)),
			mat_metal))
	for p: Vector3 in [Vector3(-3.55, 0.3, -3.5), Vector3(-2.9, 0.3, -3.75), Vector3(-3.25, 0.88, -3.6)]:
		it.append(BMG.item(box1, p, mat_stone, Vector3(0, p.x * 25.0, 0), Vector3(0.62, 0.56, 0.62)))
	it.append(BMG.item(box1, Vector3(-3.25, 0.03, -3.6), mat_metal, Vector3(0, -10, 0), Vector3(1.6, 0.06, 1.0)))
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	add_child(_scaffold)
	_merged("ScaffoldParts", "scaffold", it, _scaffold)
	_scaffold.visible = false


## A soft tinted ground stain (ash / scorch / mist colour), art-keep.md 0.5 second colour. No shadow, no depth write.
func _scorch_decal(pos: Vector3, size: float, col: Color = Color(0.10, 0.05, 0.03, 0.55)) -> MeshInstance3D:
	if _budget_wanted() and _decal_mat and _decal_mat.vertex_color_use_as_albedo:
		# B8: the contact decal's material, tinted by the vertex colour (alpha scaled so the centre matches).
		var sd := MeshInstance3D.new()
		sd.name = "ScorchDecal"
		sd.mesh = PVC.tinted_plane(Vector2.ONE * size, Color(col, clampf(col.a / (0.85 * 0.75), 0.0, 1.0)))
		sd.material_override = _decal_mat
		sd.position = pos
		sd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sd)
		return sd
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = tex
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * size
	var d := MeshInstance3D.new()
	d.name = "ScorchDecal"
	d.mesh = pm
	d.material_override = m
	d.position = pos
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(d)
	return d


# --- Building helpers ---

func _make_materials() -> void:
	mat_stone = _painted_mat(stone_color, 0.0, crack_strength)
	mat_dark = _painted_mat(dark_color, 0.2, 0.0)
	mat_metal = _painted_mat(metal_color, 0.35, 0.0)
	mat_team = _painted_mat(kingdom_color, 0.1, 0.0)
	mat_banner = ShaderMaterial.new()
	mat_banner.shader = BANNER
	mat_banner.set_shader_parameter(&"cloth_color", _cloth_of(kingdom_color))
	mat_banner.set_shader_parameter(&"stripe_color", stripe_color)
	mat_banner.set_shader_parameter(&"glyph_color", glyph_color)
	mat_banner.set_shader_parameter(&"glyph_shape", glyph_shape)
	mat_banner.set_shader_parameter(&"amplitude", 0.12)
	mat_banner.set_shader_parameter(&"speed", 2.4)
	mat_glow = _glow_mat(3.0, 2.0, 0)
	mat_gate = _glow_mat(2.2, 1.0, 5)


func _painted_mat(c: Color, spec: float, crack: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PAINTED
	m.set_shader_parameter(&"base_color", c)
	m.set_shader_parameter(&"noise_tex", NOISE)
	m.set_shader_parameter(&"spec_strength", spec)
	m.set_shader_parameter(&"crack_strength", crack)
	m.set_shader_parameter(&"crack_color", glow_color)
	_painted.append(m)
	return m


func _glow_mat(energy: float, pulse: float, bands: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = RUNE_GLOW
	m.set_shader_parameter(&"glow_color", glow_color)
	m.set_shader_parameter(&"energy", energy)
	m.set_shader_parameter(&"pulse_speed", pulse)
	m.set_shader_parameter(&"rune_bands", bands)
	_glows.append(m)
	return m


func _boxm(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _prism(size: Vector3, apex: float) -> PrismMesh:
	var p := PrismMesh.new()
	p.size = size
	p.left_to_right = apex
	return p


func _cyl(top: float, bottom: float, h: float, segments: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = segments
	c.rings = 1
	return c


func _part(nm: String, mesh: Mesh, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO,
		parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	(parent if parent else _body).add_child(mi)
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader == PAINTED:
		var xf: Transform3D = mi.transform if parent == null else parent.transform * mi.transform
		var box: AABB = xf * mesh.get_aabb()
		mi.set_instance_shader_parameter(&"ao_bottom", box.position.y)
		mi.set_instance_shader_parameter(&"ao_height", maxf(_top_y - box.position.y, 1.5))
	return mi


func _banner(nm: String, size: Vector2, pos: Vector3, yaw_deg: float, parent: Node3D = null) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = size
	pm.orientation = PlaneMesh.FACE_Z
	pm.subdivide_width = 2
	pm.subdivide_depth = 10
	var mi := _part(nm, pm, pos, mat_banner, Vector3(0, yaw_deg, 0), parent)
	mi.set_instance_shader_parameter(&"phase", randf() * TAU)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _omni(pos: Vector3, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = "HallLight"
	l.position = pos
	l.light_color = light_color
	l.light_energy = light_energy
	l.omni_range = rng
	l.shadow_enabled = false
	l.light_specular = 0.2
	if _budget_wanted():
		# Hall budget (step-12/13 rules, B5): no real light. The light stays a detached proxy the state code keeps
		# driving (never in the tree, freed with the model); if it stays visible, _ready turns its warmth on the
		# ground into a tinted pool (_make_light_pool).
		_proxy_light = l
		return l
	_body.add_child(l)
	return l


func _notification(what: int) -> void:
	# The proxy light (hall budget: no real light) never enters the tree: free it with the model.
	if what != NOTIFICATION_PREDELETE or _proxy_light == null:
		return
	if is_instance_valid(_proxy_light) and not _proxy_light.is_inside_tree():
		_proxy_light.free()


## The proxy light's warmth on the ground: a tinted pool sharing the contact decal's material, flickering with the
## proxy (per-instance transparency, _process). Only for a proxy the hall keeps visible (a hidden one lit nothing).
func _make_light_pool() -> void:
	if _proxy_light == null or _proxy_light != _light or not _proxy_light.visible or _decal_mat == null:
		return
	_light_pool = MeshInstance3D.new()
	_light_pool.name = "LightPool"
	_light_pool.mesh = PVC.tinted_plane(Vector2.ONE * _proxy_light.omni_range * 0.95, Color(light_color, 0.62))
	_light_pool.material_override = _decal_mat
	var p: Vector3 = _proxy_light.position
	_light_pool.position = Vector3(p.x, 0.045, p.z)
	_light_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_light_pool)


func _make_particle_quads() -> void:
	if _budget_wanted():
		# B8 / B9: the two particle quads are the same for every hall: one pair for the whole game.
		if not _hall_quads.has("add"):
			_hall_quads["add"] = _quad(true)
			_hall_quads["mix"] = _quad(false)
		_add_quad = _hall_quads["add"]
		_mix_quad = _hall_quads["mix"]
	else:
		_add_quad = _quad(true)
		_mix_quad = _quad(false)
	var g := Gradient.new()
	g.set_color(0, danger_ramp_hot)
	g.set_color(1, Color(danger_ramp_end, 0.0))
	g.add_point(0.4, danger_ramp_mid)
	g.add_point(0.8, Color(danger_ramp_end, 0.8))
	_fire_ramp = GradientTexture1D.new()
	_fire_ramp.gradient = g


func _quad(additive: bool) -> QuadMesh:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.material = m
	return q


## Contact decal (0.5), rubble ring, all at root scale.
func _build_ground() -> void:
	# B8 (painted-vc buildings): the gradient is white and the plane carries decal_color as its vertex colour, so the
	# scorch stains (_scorch_decal) share this one material with their own tint. Same look.
	var vc: bool = _budget_wanted()
	var dc: Color = Color.WHITE if vc else decal_color
	var g := Gradient.new()
	g.set_color(0, Color(dc, 0.85))
	g.set_color(1, Color(dc, 0.0))
	g.add_point(0.55, Color(dc, 0.55))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_decal_mat = StandardMaterial3D.new()
	_decal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_decal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_decal_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_decal_mat.albedo_texture = tex
	_decal_mat.albedo_color = Color(1, 1, 1, 0.75)
	var pm := PlaneMesh.new()
	pm.size = Vector2(10.0, 10.0)
	var decal := MeshInstance3D.new()
	decal.name = "ContactDecal"
	decal.mesh = pm
	if vc:
		_decal_mat.vertex_color_use_as_albedo = true
		_decal_mat.vertex_color_is_srgb = true
		decal.mesh = PVC.tinted_plane(Vector2(10.0, 10.0), Color(decal_color, 1.0))
	decal.material_override = _decal_mat
	decal.position = Vector3(0, 0.03, 0)
	decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(decal)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5101
	var pts: Array[Vector3] = []
	for i: int in 9:
		var a: float = TAU * float(i) / 9.0 + rng.randf_range(-0.25, 0.25)
		var r: float = rng.randf_range(3.35, 3.9)
		pts.append(Vector3(cos(a) * r, 0.05, sin(a) * r))
	_rubble = _cubes("Rubble", pts, 0.5, rng, self)


## Every direct MeshInstance3D child of Body is a part; a plain Node3D child (chimney, rack) is one grouped
## part (bottom / top from its meshes). They rise in height order while building and sink on collapse.
func _collect_parts() -> void:
	for child: Node in _body.get_children():
		if child is GPUParticles3D or child is Light3D or not (child is Node3D):
			continue
		var n := child as Node3D
		var box := AABB()
		if n is MeshInstance3D:
			box = n.transform * (n as MeshInstance3D).get_aabb()
		else:
			var first: bool = true
			for c: Node in n.get_children():
				if c is MeshInstance3D:
					var mi := c as MeshInstance3D
					var bb: AABB = n.transform * (mi.transform * mi.get_aabb())
					box = bb if first else box.merge(bb)
					first = false
		_parts.append(n)
		_part_xf.append(n.transform)
		_part_b.append(box.position.y)
		_part_t.append(box.end.y)
		_height = maxf(_height, box.end.y)
		if not n.name.begins_with("Plinth") and n != _falling:
			_collapse_idx.append(_parts.size() - 1)
	if _falling:
		_fall_xf = _falling.transform


## Squash part i vertically about height `b` (Body space), with an optional offset (rumble).
func _squash(i: int, s: float, b: float, offset: Vector3) -> void:
	var sq := Transform3D(Basis.from_scale(Vector3(1.0, s, 1.0)), Vector3(0.0, b * (1.0 - s), 0.0) + offset)
	_parts[i].transform = sq * _part_xf[i]


func _apply_health() -> void:
	var r: float = _health_ratio
	var built: bool = _progress >= 1.0
	var smoke: bool = built and r < 0.5
	var fire: bool = built and r < 0.25
	var dmg: float = (1.0 - r) * 0.5
	if r < 0.25:
		dmg = 1.0
	elif r < 0.5:
		dmg = 0.6
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"damage", dmg)
	for s: GPUParticles3D in _smoke:
		s.emitting = smoke
	for b: GPUParticles3D in _blaze:
		b.emitting = fire
	for n: Node3D in _show_below_50:
		n.visible = smoke
	for n: Node3D in _show_below_25:
		n.visible = fire
	if not built:
		return
	for n: Node3D in _hide_below_50:
		n.visible = not smoke
	for n: Node3D in _hide_below_25:
		n.visible = not fire
	_rubble2.visible = smoke
	_flicker_amp = 0.3 if fire else 0.1


func _sel_boost() -> float:
	return lerpf(1.0, 1.4, _sel_k)


func _apply_rim_and_glow() -> void:
	if not _ready_done:
		return
	var k: float = _sel_k
	if _progress < 1.0 and not _destroyed:
		k = maxf(k, 0.65)  # sites glow in the team colour while they rise
	var rim_col: Color = RIM_IDLE.lerp(_team_color, k)
	var rim_str: float = lerpf(0.25, 0.9, k)
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"rim_color", rim_col)
		m.set_shader_parameter(&"rim_strength", rim_str)
	mat_banner.set_shader_parameter(&"rim_color", _team_color.lightened(0.3))
	mat_banner.set_shader_parameter(&"rim_strength", 0.6 * _sel_k)
	var boost: float = _sel_boost()
	for m: ShaderMaterial in _glows:
		m.set_shader_parameter(&"boost", boost)


func _process_destroyed(delta: float) -> void:
	_destroy_t += delta
	var t: float = _destroy_t
	# 0.0-0.5: the glow overloads (coals / lantern flare), the light flashes.
	if t < 0.5:
		mat_glow.set_shader_parameter(&"boost", 1.0 + 3.0 * t / 0.5)
	elif _destroy_step == 0:
		_destroy_step = 1
		_dust.position = Vector3(_fall_xf.origin.x, _top_y - 1.5, _fall_xf.origin.z)
		_fire(_dust)
		_fire(_train_burst)
	# 0.5-1.4: the tall element tilts and drops, then vanishes.
	if _falling and t >= 0.5 and _falling.visible:
		var k2: float = clampf((t - 0.5) / 0.9, 0.0, 1.0)
		k2 *= k2
		_falling.transform = Transform3D(Basis(_fall_axis, deg_to_rad(_fall_deg) * k2),
			_fall_xf.origin + Vector3(0.0, -5.0 * k2, 0.0))
		if t >= 1.4:
			_falling.visible = false
	# 0.8-2.0: walls and roof sink to 30 % with a rumble.
	if t >= 0.8 and _destroy_step < 3:
		var k3: float = clampf((t - 0.8) / 1.2, 0.0, 1.0)
		var s: float = lerpf(1.0, 0.3, 1.0 - pow(1.0 - k3, 2.0))
		var jitter := Vector3(sin(t * 94.2) * 0.07, 0.0, cos(t * 87.9) * 0.07) if k3 < 1.0 else Vector3.ZERO
		for i: int in _collapse_idx:
			_squash(i, s, PLINTH_TOP, jitter)
		if k3 >= 1.0:
			_destroy_step = 3
	if t >= 1.6 and _destroy_step < 2:
		_destroy_step = 2
		for n: Node3D in _hide_on_collapse:
			n.visible = false
		_dust.position = Vector3(0.0, 1.2, 0.0)
		_fire(_dust)
		_debris.visible = true
		if _wreck:
			_wreck.visible = true
			mat_glow.set_shader_parameter(&"boost", 0.8)  # embers in the rubble, after the overload
	var k4: float = clampf((t - 2.0) / 1.0, 0.0, 1.0)
	_light.light_energy = 5.0 if t < 0.15 else lerpf(light_energy, 0.3, k4)
	_rubble.scale = Vector3.ONE * lerpf(1.0, 1.5, k4)
	_debris.scale = Vector3(1.0, lerpf(0.5, 1.0, clampf((t - 1.6) / 0.6, 0.0, 1.0)), 1.0)
	var dk: float = lerpf(1.0, 0.6, k4)
	_decal_mat.albedo_color = Color(dk, dk, dk, lerpf(0.75, 1.0, k4))
	if t >= DESTROY_TIME:
		set_process(false)
		destroyed_finished.emit()


func _fire(p: GPUParticles3D) -> void:
	p.restart()
	p.emitting = true


func _build_state_nodes() -> void:
	var smoke_ramp: Texture2D = _ramp(Color(smoke_color, 0.8), Color(smoke_color, 0.0), false)
	for pos: Vector3 in _smoke_points:
		var pm := _pm(Vector3.UP, 12.0, 1.1, 1.6, Vector3(0.25, 0.1, 0.0), 0.6, 2.2, smoke_ramp)
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.35
		_smoke.append(_particles("Smoke%d" % (_smoke.size() + 1), _body, pos, 24, 3.2, pm, _mix_quad, false))
	for pos: Vector3 in _blaze_points:
		var pm := _pm(Vector3.UP, 15.0, 1.5, 2.4, Vector3.ZERO, 0.8, 0.25, _fire_ramp)
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.4
		_blaze.append(_particles("Blaze%d" % (_blaze.size() + 1), _body, pos, 20, 1.0, pm, _add_quad, false))
	var tb := _pm(Vector3(0, 0.3, -1), 60.0, 2.0, 4.0, Vector3(0, -2.0, 0), 0.28, 0.08, _ramp(glow_color, glow_color, true))
	_train_burst = _particles("TrainBurst", _body, _gate_pos, 24, 0.8, tb, _add_quad, true)
	var br := _pm(Vector3.UP, 10.0, 0.8, 1.6, Vector3.ZERO, 0.22, 0.06, _ramp(glow_color, glow_color, true))
	br.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	br.emission_ring_axis = Vector3.UP
	br.emission_ring_radius = 3.9
	br.emission_ring_inner_radius = 3.7
	br.emission_ring_height = 0.05
	_build_ring = _particles("BuildRing", self, Vector3(0, 0.1, 0), 32, 1.2, br, _add_quad, false)
	var bf := _pm(Vector3.UP, 180.0, 2.5, 5.0, Vector3(0, -3.0, 0), 0.35, 0.1, _ramp(glow_color, glow_color, true))
	_build_flash = _particles("BuildFlash", _body, Vector3(0, _top_y - 1.0, 0), 32, 1.0, bf, _add_quad, true)
	var du := _pm(Vector3.UP, 80.0, 0.8, 2.5, Vector3(0, -0.5, 0), 0.9, 2.6,
		_ramp(Color(dust_color, 0.6), Color(dust_color, 0.0), false))
	du.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	du.emission_box_extents = Vector3(2.4, 0.5, 2.4)
	_dust = _particles("CollapseDust", _body, Vector3(0, 6, 0), 40, 2.5, du, _mix_quad, true)
	# Glowing construction outline: 4 thin emissive bars around the plinth, at ground level.
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = RUNE_GLOW
	_outline_mat.set_shader_parameter(&"energy", 2.0)
	_outline_mat.set_shader_parameter(&"pulse_speed", TAU)
	_outline_mat.set_shader_parameter(&"glow_color", glow_color)
	var bar := BoxMesh.new()
	bar.size = Vector3(7.2, 0.06, 0.25)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bar
	mm.instance_count = 4
	for i: int in 4:
		var yaw: float = PI * 0.5 * i
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw), dir * 3.5 + Vector3(0, 0.06, 0)))
	_outline = MultiMeshInstance3D.new()
	_outline.name = "BuildOutline"
	_outline.multimesh = mm
	_outline.material_override = _outline_mat
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_outline.visible = false
	add_child(_outline)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331
	_rubble2 = _cubes("Rubble2", _rubble2_points, 0.55, rng, _body)
	var pts: Array[Vector3] = []
	for i: int in 10:
		pts.append(Vector3(rng.randf_range(-2.6, 2.6), PLINTH_TOP + rng.randf_range(0.0, 0.4), rng.randf_range(-2.6, 2.6)))
	_debris = _cubes("Debris", pts, 0.8, rng, _body)
	_rubble2.visible = false
	_debris.visible = false


func _cubes(nm: String, points: Array, size: float, rng: RandomNumberGenerator, parent: Node3D) -> MultiMeshInstance3D:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = points.size()
	for i: int in points.size():
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(10.0, 22.0)))
		mm.set_instance_transform(i, Transform3D(b.scaled(Vector3.ONE * rng.randf_range(0.7, 1.2)), points[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.material_override = mat_dark
	parent.add_child(mmi)
	mmi.set_instance_shader_parameter(&"ao_bottom", -0.3)
	mmi.set_instance_shader_parameter(&"ao_height", 2.0)
	return mmi


func _ramp(a: Color, b: Color, team: bool) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, Color(b, 0.0))
	if team:
		_team_ramps.append(g)
	var tex := GradientTexture1D.new()
	tex.gradient = g
	return tex


func _pm(dir: Vector3, spread: float, vmin: float, vmax: float, gravity: Vector3,
		size_start: float, size_end: float, ramp: Texture2D) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir.normalized()
	pm.spread = spread
	pm.initial_velocity_min = vmin
	pm.initial_velocity_max = vmax
	pm.gravity = gravity
	var base: float = maxf(size_start, size_end)
	pm.scale_min = base
	pm.scale_max = base
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, size_start / base))
	curve.add_point(Vector2(1.0, size_end / base))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.color_ramp = ramp
	return pm


func _particles(nm: String, parent: Node3D, pos: Vector3, amount: int, life: float,
		pm: ParticleProcessMaterial, quad: Mesh, one_shot: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = nm
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = true
	p.process_material = _shared_pm(nm, pos, pm)
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-7, -4, -7), Vector3(14, 18, 14))
	p.position = pos
	p.emitting = false
	parent.add_child(p)
	return p


## B9: a process material that does not follow the team colour is the same for every instance of a class (the
## build code is deterministic): share one per class + emitter name + spot. Team-coloured ramps stay per instance.
func _shared_pm(nm: String, pos: Vector3, pm: ParticleProcessMaterial) -> ParticleProcessMaterial:
	if not _budget_wanted():
		return pm
	var ramp := pm.color_ramp as GradientTexture1D
	if ramp and ramp.gradient in _team_ramps:
		return pm
	var key := "%s|%s|%s" % [get_script().resource_path, nm, pos]
	if not _hall_pms.has(key):
		_hall_pms[key] = pm
	return _hall_pms[key]
