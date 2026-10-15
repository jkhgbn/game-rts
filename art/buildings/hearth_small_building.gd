class_name SmallBuildingModel
extends Node3D
## Shared visual logic of the small buildings (task 5.V2): Hearth, Hovel, Ember Spire, Night Spire.
## Same hooks as the keeps (docs/design/art-keep.md 8.8), all safe before _ready (values are cached):
##   set_team_color(c), set_construction_progress(p), set_health_ratio(r), set_selected(on),
##   play_destroyed() -> `destroyed_finished` after DESTROY_TIME (the wreck stays until freed).
## Towers (SpireTowerModel) add play_shot().
## Subclasses set the palette in _setup() and build their parts in _build_parts() with _part() / _multi().
## Everything is built once in _ready (meshes and particle quads shared between instances); one _process,
## no tweens, no per-frame allocations. Materials are per instance (selection rim, orb flash).
## Task A.9 (opt-in, unused by the Ice / Nature subclasses): `_merged()` bakes a tier of parts into one shared
## ArrayMesh (BuildingMerge, one surface per material); `_scaffold` shows while the site rises, `_wreck` appears at
## the collapse (0.8 s), `_show_below_50/25` hold damage details (roof holes) shown under those HP ratios.

signal destroyed_finished

const PAINTED: Shader = preload("res://art/shaders/painted.gdshader")
const GLOW: Shader = preload("res://art/shaders/rune_glow.gdshader")
const NOISE: Texture2D = preload("res://art/shaders/paint_noise.tres")
const RIM_IDLE := Color(0.55, 0.65, 0.85)
const DESTROY_TIME := 2.5
const FIRE_RAMP_A := Color(1.0, 0.92, 0.55)
const FIRE_RAMP_B := Color(1.0, 0.5, 0.1)
const BMG := preload("res://art/buildings/fire_hall_merge.gd")
const PVC := preload("res://art/buildings/painted_vc.gd")
## G-B Fire look layer (docs/art/gb_fire_buildings.md): only the Fire models use it (_gb_fire()).
const GBF := preload("res://art/buildings/fire/fire_building_look.gd")

static var _mesh_cache: Dictionary = {}
static var _quad_cache: Dictionary = {}
static var _decal_cache: Dictionary = {}

# Palette (art-keep.md 0.2); the subclass fills it in _setup().
var kingdom_color: Color = Color(0.85, 0.30, 0.12)
var glow_color: Color = Color(1.0, 0.55, 0.15)
var stone_color: Color = Color(0.30, 0.26, 0.24)
var dark_color: Color = Color(0.12, 0.10, 0.10)
var trim_color: Color = Color(0.62, 0.40, 0.16)
var smoke_color: Color = Color(0.16, 0.14, 0.13)
var blaze_a: Color = FIRE_RAMP_A
var blaze_b: Color = FIRE_RAMP_B
var stain_color: Color = Color(0.20, 0.06, 0.02, 0.35)
var footprint: float = 4.0
var crack_strength: float = 0.6
var plinth_top: float = 0.45
var wreck_top: float = 1.0      # top of the collapsed stub (debris sits on it)
## B8 opt-in (a subclass sets it in _setup()): after the build, every painted part draws with ONE vertex-coloured
## material (PaintedVC: the team material with the painted_vc shader; same look). Off by default.
var vc_merge: bool = false
var crack_glow: float = 1.0   ## vc_merge: crack emission x this (< 1 keeps the veins under the bloom level)
var _glow_vc: ShaderMaterial   ## vc_merge: the merged glow material (PaintedVC.convert_glow)
var smoke_points: Array[Vector3] = []
var _m_wood: ShaderMaterial   ## G-B Fire: timber (scaffold, woodpile); null = the trim stand-in
var _hazes: Array[Node3D] = []   ## G-B Fire: heat-haze quads (High / Ultra)
var blaze_points: Array[Vector3] = []

var _body: Node3D
var _m_stone: ShaderMaterial
var _m_dark: ShaderMaterial
var _m_trim: ShaderMaterial
var _m_team: ShaderMaterial
var _m_hole: StandardMaterial3D
var _painted: Array[ShaderMaterial] = []
var _glows: Array[ShaderMaterial] = []
var _team_glows: Array[ShaderMaterial] = []
var _team_ramps: Array[Gradient] = []

var _parts: Array[GeometryInstance3D] = []
var _part_xf: Array[Transform3D] = []
var _part_b: PackedFloat32Array = PackedFloat32Array()
var _part_t: PackedFloat32Array = PackedFloat32Array()
var _floaters: Array[Node3D] = []        # appear at p >= 0.95, hidden at the collapse
var _no_collapse: Array[Node3D] = []     # plinth: never squashed
var _hide_on_collapse: Array[Node3D] = []  # roofs, crowns: hidden mid-collapse
var _idle_fx: Array[GPUParticles3D] = []
var _height: float = 1.0
# A.9 opt-in extras (null / empty = off). Scaffold and wreck are children of the root (never rise or squash).
var _scaffold: Node3D
var _wreck: Node3D
var _show_below_50: Array[Node3D] = []
var _show_below_25: Array[Node3D] = []

var _smoke: Array[GPUParticles3D] = []
var _blaze: Array[GPUParticles3D] = []
var _dust: GPUParticles3D
var _flash: GPUParticles3D
var _settle_dust: GPUParticles3D   ## G-B leftovers: the completion settle (BuildSettle)
var _settle_glint: GPUParticles3D
var _outline: MultiMeshInstance3D
var _outline_mat: ShaderMaterial
var _decal: MeshInstance3D
var _debris: MultiMeshInstance3D

var _t: float = 0.0
var _ready_done: bool = false
var _team_color: Color
var _team_set: bool = false
var _progress: float = 1.0
var _was_building: bool = false
var _float_appear: float = 1.0
var _outline_fade: float = 0.0
var _health_ratio: float = 1.0
var _selected: bool = false
var _sel_k: float = 0.0
var _destroyed: bool = false
var _destroy_t: float = 0.0
var _destroy_step: int = 0


func _ready() -> void:
	_ready_done = true
	_t = randf() * 10.0
	_setup()
	if not _team_set:
		_team_color = kingdom_color
	_make_materials()
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_build_parts()
	_build_ground()
	_collect_parts()
	_build_state_nodes()
	if vc_merge:
		PVC.convert(self, _m_team, _vc_team(), [_m_hole] if _m_hole else [], _vc_skip())
		_m_team.set_shader_parameter(&"crack_energy", crack_glow)
		if _gb_fire():
			GBF.apply(_m_team)   # G-B: the Fire paint layer (same vertex contract and uniforms)
	_post_build()
	if vc_merge:
		_glow_vc = PVC.convert_glow(self)   # one glow material; _process copies the sources' state over
	set_team_color(_team_color)
	set_construction_progress(_progress)
	_sel_k = 1.0 if _selected else 0.0
	_apply_rim_and_glow()
	if _destroyed:
		_destroyed = false
		play_destroyed()


func _process(delta: float) -> void:
	_t += delta
	if _destroyed:
		_process_destroyed(delta)
		PVC.sync_glow(_glow_vc)
		return
	if _float_appear < 1.0:
		_float_appear = minf(_float_appear + delta / 0.5, 1.0)
		var s: float = maxf(ease(_float_appear, 0.4), 0.01)
		for f: Node3D in _floaters:
			f.scale = Vector3.ONE * s
	_idle(delta)
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

## Construction progress 0..1: glowing footprint outline at 0, parts rise from the ground in height order,
## floating parts (orbs, lanterns) scale in at >= 0.95, a flash from the top at 1.
func set_construction_progress(p: float) -> void:
	_progress = clampf(p, 0.0, 1.0)
	if not _ready_done or _destroyed:
		return
	var building: bool = _progress < 1.0
	var h: float = _progress * _height
	for i: int in _parts.size():
		var part: GeometryInstance3D = _parts[i]
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
	var floating: bool = _progress >= 0.95
	for f: Node3D in _floaters:
		if floating and not f.visible:
			_float_appear = 0.0 if building or _was_building else 1.0
			f.scale = Vector3.ONE * (0.01 if _float_appear < 1.0 else 1.0)
		f.visible = floating
	for fx: GPUParticles3D in _idle_fx:
		fx.emitting = not building
	for hz: Node3D in _hazes:
		hz.visible = not building
	if _scaffold:
		_scaffold.visible = building and _progress > 0.0
	if building:
		_outline.visible = true
		_outline_fade = 0.0
		_outline_mat.set_shader_parameter(&"energy", 2.0)
	elif _was_building:
		_outline_fade = 1.0
		BuildSettle.play(_settle_dust, _settle_glint, self)   # G-B leftovers: dust + glints, fog-safe
	else:
		_outline.visible = false
	_was_building = building
	_on_progress(building)
	_apply_health()
	_apply_rim_and_glow()


## HP ratio 0..1: soot from the first hit, smoke below 50 %, fire below 25 % (+ per-building extras).
func set_health_ratio(r: float) -> void:
	_health_ratio = clampf(r, 0.0, 1.0)
	if _ready_done and not _destroyed:
		_apply_health()


## Collapse: DESTROY_TIME s, then `destroyed_finished`; the smoking stub stays until the Building frees it.
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
	if _scaffold:
		_scaffold.visible = false
	for fx: GPUParticles3D in _idle_fx:
		fx.emitting = false
	for hz: Node3D in _hazes:
		hz.visible = false
	for s: GPUParticles3D in _smoke:
		s.emitting = true
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"damage", 1.0)
	_on_destroy_start()


## Selection: team rim on every painted material, glow boost 1.4 (0.15 s in, 0.25 s out).
func set_selected(on: bool) -> void:
	_selected = on


## Team colour: roofs / collars, selection rim, team glows (orbs, lanterns), construction outline and flash.
func set_team_color(c: Color) -> void:
	_team_color = c
	_team_set = true
	if not _ready_done:
		return
	_m_team.set_shader_parameter(&"base_color", c)
	var g: Color = team_glow()
	for m: ShaderMaterial in _team_glows:
		m.set_shader_parameter(&"glow_color", g)
	_outline_mat.set_shader_parameter(&"glow_color", g)
	for gr: Gradient in _team_ramps:
		gr.set_color(0, Color(g, 1.0))
		gr.set_color(1, Color(g, 0.0))
	_on_team_color(g)
	_apply_rim_and_glow()


## The glow that stands for the team: the kingdom glow for the kingdom colour, else the team colour lightened.
func team_glow() -> Color:
	return glow_color if _team_color.is_equal_approx(kingdom_color) else _team_color.lightened(0.35)


# --- Subclass hooks ---

func _setup() -> void:
	pass


func _build_parts() -> void:
	pass


func _idle(_delta: float) -> void:
	pass


func _on_progress(_building: bool) -> void:
	pass


func _on_health(_smoke_on: bool, _fire_on: bool) -> void:
	pass


func _on_destroy_start() -> void:
	pass


func _on_destroy(_t_now: float) -> void:
	pass


func _on_team_color(_g: Color) -> void:
	pass


## The billboard quad of the state / idle particles (the shared ADD / MIX dots); the Nature buildings use NatureKit's
## (same soft dot) so their pollen and leaves share the materials.
func _quad_for(add: bool) -> Mesh:
	return _quad(add)


## Runs once after the build and the painted merge, before the glow merge (the Nature buildings merge their
## NatureKit materials here).
func _post_build() -> void:
	pass


## G-B Fire: true for the Fire models (Hearth, Ember Spire) that opt in; the other kingdoms keep their look.
func _gb_fire() -> bool:
	return false


## G-B Fire: a heat-haze quad (High / Ultra only) kept with the idle effects.
func _gb_haze(parent: Node3D, pos: Vector3, size: Vector2, strength: float = 1.0) -> void:
	var hz: MeshInstance3D = GBF.add_heat_haze(parent, pos, size, strength)
	if hz:
		_hazes.append(hz)


## vc_merge: painted materials whose base_color is the team colour (a material, or [material, multiplier] for a
## darker team shade). Subclasses add theirs.
func _vc_team() -> Array:
	return [_m_team]


## vc_merge: painted materials a subclass changes at run time on its own (not through the _painted loops).
func _vc_skip() -> Array:
	return []


# --- Part helpers (for _build_parts) ---

func _painted_mat(color: Color, spec: float, cracks: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PAINTED
	m.set_shader_parameter(&"base_color", color)
	m.set_shader_parameter(&"noise_tex", NOISE)
	m.set_shader_parameter(&"spec_strength", spec)
	m.set_shader_parameter(&"crack_strength", cracks)
	m.set_shader_parameter(&"crack_color", glow_color)
	m.set_shader_parameter(&"crack_scale", 0.5)
	_painted.append(m)
	return m


func _glow_mat(color: Color, energy: float, pulse_speed: float, team: bool, bands: int = 0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GLOW
	m.set_shader_parameter(&"glow_color", color)
	m.set_shader_parameter(&"energy", energy)
	m.set_shader_parameter(&"pulse_speed", pulse_speed)
	m.set_shader_parameter(&"rune_bands", bands)
	m.set_shader_parameter(&"phase", randf() * TAU)
	_glows.append(m)
	if team:
		_team_glows.append(m)
	return m


func _make_materials() -> void:
	_m_stone = _painted_mat(stone_color, 0.0, crack_strength)
	_m_dark = _painted_mat(dark_color, 0.0, 0.0)
	_m_trim = _painted_mat(trim_color, 0.35, 0.0)
	_m_team = _painted_mat(kingdom_color, 0.1, 0.0)
	_m_hole = StandardMaterial3D.new()
	_m_hole.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_m_hole.albedo_color = Color(dark_color.darkened(0.7), 1.0)


static func _box(size: Vector3) -> Mesh:
	var key: String = "b%s" % size
	if not _mesh_cache.has(key):
		var m := BoxMesh.new()
		m.size = size
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _cyl(top_r: float, bot_r: float, h: float, segs: int) -> Mesh:
	var key: String = "c%.3f_%.3f_%.3f_%d" % [top_r, bot_r, h, segs]
	if not _mesh_cache.has(key):
		var m := CylinderMesh.new()
		m.top_radius = top_r
		m.bottom_radius = bot_r
		m.height = h
		m.radial_segments = segs
		m.rings = 1
		m.cap_top = top_r > 0.0
		_mesh_cache[key] = m
	return _mesh_cache[key]


## A PrismMesh (apex at `apex` 0 = left .. 1 = right), cached like the other primitives.
static func _prism(size: Vector3, apex: float) -> Mesh:
	var key: String = "p%s_%.2f" % [size, apex]
	if not _mesh_cache.has(key):
		var m := PrismMesh.new()
		m.size = size
		m.left_to_right = apex
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _sphere(r: float) -> Mesh:
	var key: String = "s%.3f" % r
	if not _mesh_cache.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = 12
		m.rings = 6
		_mesh_cache[key] = m
	return _mesh_cache[key]


static func _torus(inner: float, outer: float) -> Mesh:
	var key: String = "t%.3f_%.3f" % [inner, outer]
	if not _mesh_cache.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = 24
		m.ring_segments = 6
		_mesh_cache[key] = m
	return _mesh_cache[key]


## A part of the structure (direct child of Body). `pos` is its centre.
func _part(nm: String, mesh: Mesh, mat: Material, pos: Vector3, basis: Basis = Basis.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(basis, pos)
	if mat is StandardMaterial3D or (mat is ShaderMaterial and (mat as ShaderMaterial).shader == GLOW):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(mi)
	return mi


func _multi(nm: String, mesh: Mesh, mat: Material, xforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i: int in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.material_override = mat
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader == GLOW:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(mmi)
	return mmi


## A.9: a tier of parts merged into one mesh (one surface per material, baked once per class + `key` and shared).
## `items` = [mesh, Transform3D, material] in `parent` space (default Body). Unshadowed when every part glows.
func _merged(nm: String, key: String, items: Array, parent: Node3D = null) -> MeshInstance3D:
	var mi: MeshInstance3D = BMG.instance(nm, "%s/%s" % [get_script().resource_path, key], items)
	var all_glow: bool = true
	for m: Material in BMG.materials_of(items):
		if not (m is ShaderMaterial and (m as ShaderMaterial).shader == GLOW):
			all_glow = false
	if all_glow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else _body).add_child(mi)
	return mi


## Item helpers for _merged (see BuildingMerge.item).
func _it(mesh: Mesh, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Array:
	return BMG.item(mesh, pos, mat, rot_deg, scale)


func _itx(mesh: Mesh, xf: Transform3D, mat: Material) -> Array:
	return BMG.item_xf(mesh, xf, mat)


## Construction scaffolding (A.9): corner poles around a `size` square, one or two plank decks, a brace, a few cut
## stones; trim colour (reads as timber). Child of the root, visible while 0 < progress < 1.
func _build_scaffold(size: float, top: float, decks: Array[float]) -> void:
	var box1: Mesh = _box(Vector3.ONE)
	var h: float = size * 0.5
	var it: Array = []
	var wood: ShaderMaterial = _m_wood if _m_wood else _m_trim   # G-B Fire: timber when the model made it
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_it(box1, Vector3(c.x * h, top * 0.5, c.y * h), wood, Vector3.ZERO, Vector3(0.16, top, 0.16)))
	for y: float in decks:
		for s: float in [-1.0, 1.0]:
			it.append(_it(box1, Vector3(0, y, s * h), wood, Vector3(0, 0, s * 2.5), Vector3(size + 0.25, 0.08, 0.4)))
			it.append(_it(box1, Vector3(s * h, y, 0), wood, Vector3(s * 2.5, 0, 0), Vector3(0.4, 0.08, size + 0.25)))
	var ang: float = atan2(top * 0.8, size)
	it.append(_itx(box1, Transform3D(Basis(Vector3.RIGHT, -ang).scaled_local(Vector3(0.1, 0.1,
		sqrt(size * size + top * top * 0.64))), Vector3(-h - 0.1, top * 0.45, 0)), wood))
	for p: Vector3 in [Vector3(h + 0.55, 0.22, -h - 0.35), Vector3(h + 0.2, 0.22, -h - 0.75), Vector3(h + 0.4, 0.64, -h - 0.5)]:
		it.append(_it(box1, p, _m_stone, Vector3(0, p.z * 30.0, 0), Vector3.ONE * (0.2 + footprint * 0.07)))
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	add_child(_scaffold)
	_merged("ScaffoldParts", "scaffold", it, _scaffold)
	_scaffold.visible = false


## Collapse leftovers (A.9): broken wall teeth around the squashed stub (half size `half`, stub top `stub_top`), a
## charred beam, a torn team-coloured slab and glowing embers (`ember` material). Shown at 0.8 s of the collapse.
func _build_wreck(half: float, stub_top: float, ember: Material, rng_seed: int, teeth: int = 5) -> void:
	var box1: Mesh = _box(Vector3.ONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var it: Array = []
	for i: int in teeth:
		var a: float = TAU * (float(i) + rng.randf_range(0.0, 0.5)) / float(teeth)
		var s := Vector3(rng.randf_range(0.4, 0.7), rng.randf_range(0.4, 0.8), rng.randf_range(0.35, 0.55)) \
			* (0.6 + footprint * 0.1)
		var p := Vector3(sin(a) * half, stub_top + s.y * 0.5 - 0.12, cos(a) * half)
		it.append(_it(box1, p, _m_stone, Vector3(rng.randf_range(-12, 12), rad_to_deg(a), rng.randf_range(-14, 14)), s))
	for i: int in 2:
		it.append(_it(box1, Vector3(rng.randf_range(-0.4, 0.4) * half, stub_top + 0.2, rng.randf_range(-0.4, 0.4) * half),
			_m_dark if i == 0 else _m_team, Vector3(rng.randf_range(-25, 25), rng.randf() * 180.0, rng.randf_range(15, 30)),
			Vector3(0.22, 0.22, half * 1.8) if i == 0 else Vector3(half * 0.9, 0.12, half * 0.8)))
	for i: int in 3:
		it.append(_it(box1, Vector3(rng.randf_range(-0.5, 0.5) * half, stub_top + 0.04, rng.randf_range(-0.5, 0.5) * half),
			ember, Vector3(0, rng.randf() * 90.0, 20), Vector3.ONE * 0.3))
	_wreck = Node3D.new()
	_wreck.name = "Wreck"
	add_child(_wreck)
	_merged("WreckParts", "wreck", it, _wreck)
	_wreck.visible = false


## A caved-in roof patch (A.9) on a roof face: dark hole, two broken rafters, loose team tiles, embers when
## `ember` is given. `xf` places it (local +Y = out of the roof, local X = along the slope). Child of `roof`, hidden.
func _roof_patch(nm: String, roof: Node3D, xf: Transform3D, size: float, ember: Material = null) -> MeshInstance3D:
	var box1: Mesh = _box(Vector3.ONE)
	var it: Array = []
	it.append(_itx(box1, xf * Transform3D(Basis.from_scale(Vector3(size, 0.04, size * 0.9)), Vector3.ZERO), _m_hole))
	if ember:
		it.append(_itx(box1, xf * Transform3D(Basis.from_scale(Vector3(size * 0.6, 0.04, size * 0.55)), Vector3(0, 0.03, 0)),
			ember))
	for i: int in 2:
		it.append(_itx(box1, xf * Transform3D(Basis(Vector3.UP, 0.25 - 0.5 * i) * Basis(Vector3.FORWARD, 0.2 - 0.4 * i)
			* Basis.from_scale(Vector3(size * 1.15, 0.1, 0.1)), Vector3(0, 0.08, -0.15 + 0.3 * i)), _m_dark))
	for i: int in 2:
		it.append(_itx(box1, xf * Transform3D(Basis(Vector3.RIGHT, 0.4 + 0.3 * i) * Basis(Vector3.UP, 0.8 * i)
			* Basis.from_scale(Vector3(0.36, 0.08, 0.42)), Vector3(size * (0.55 - 0.3 * i), 0.1, size * (0.35 - 0.8 * i))), _m_team))
	var mi := _merged(nm, nm.to_lower(), it, roof)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	return mi


## Trim ridges along the hip edges of a CylinderMesh roof (bottom radius r0 at y0, top radius r1 at y1,
## `segs` sides, yawed by `yaw`): breaks up the flat roof faces from the high camera. One draw call.
func _hip_ridges(nm: String, r0: float, r1: float, y0: float, y1: float, segs: int, yaw: float,
		thick: float) -> MultiMeshInstance3D:
	var xf: Array[Transform3D] = []
	var rot := Basis(Vector3.UP, yaw)
	var length: float = 0.0
	for i: int in segs:
		var a: float = TAU * i / segs
		var d := Vector3(sin(a), 0.0, cos(a))
		var p0: Vector3 = rot * (d * r0 + Vector3(0, y0, 0))
		var p1: Vector3 = rot * (d * r1 + Vector3(0, y1, 0))
		var edge: Vector3 = p1 - p0
		length = edge.length()
		var b := Basis(Quaternion(Vector3.UP, edge.normalized()))
		xf.append(Transform3D(b, (p0 + p1) * 0.5))
	return _multi(nm, _box(Vector3(thick, length, thick)), _m_trim, xf)


## Basis leaning `deg` degrees away from the centre, toward the horizontal direction `dir`.
static func _lean(dir: Vector3, deg: float) -> Basis:
	var axis: Vector3 = Vector3.UP.cross(Vector3(dir.x, 0.0, dir.z).normalized())
	return Basis(axis, deg_to_rad(deg))


func _light(nm: String, pos: Vector3, color: Color, energy: float, light_range: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = nm
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	l.shadow_enabled = false
	l.light_specular = 0.2
	add_child(l)
	return l


# --- Internals ---

func _collect_parts() -> void:
	for child: Node in _body.get_children():
		if not (child is MeshInstance3D or child is MultiMeshInstance3D):
			continue
		var g := child as GeometryInstance3D
		var box: AABB = g.transform * (g as VisualInstance3D).get_aabb()
		_height = maxf(_height, box.end.y)
		if g in _floaters:
			continue
		_parts.append(g)
		_part_xf.append(g.transform)
		_part_b.append(maxf(box.position.y, 0.0))
		_part_t.append(box.end.y)
	for child: Node in _body.get_children():
		var g := child as GeometryInstance3D
		if g and g.material_override is ShaderMaterial and (g.material_override as ShaderMaterial).shader == PAINTED:
			g.set_instance_shader_parameter(&"ao_bottom", 0.0)
			g.set_instance_shader_parameter(&"ao_height", _height)
		elif g is MeshInstance3D and g.material_override == null:   # merged tiers (A.9): surface materials
			_ao_tree(g)
	for n: Node3D in [_scaffold, _wreck]:
		if n:
			_ao_tree(n)


## Height gradient on a merged mesh and its merged children (surface override materials).
func _ao_tree(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).set_instance_shader_parameter(&"ao_bottom", 0.0)
		(n as MeshInstance3D).set_instance_shader_parameter(&"ao_height", _height)
	for c: Node in n.get_children():
		_ao_tree(c)


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
	_on_health(smoke, fire)


func _sel_boost() -> float:
	return lerpf(1.0, 1.4, _sel_k)


func _apply_rim_and_glow() -> void:
	if not _ready_done:
		return
	var k: float = _sel_k
	if _progress < 1.0 and not _destroyed:
		k = maxf(k, 0.65)
	var rim_col: Color = RIM_IDLE.lerp(_team_color, k)
	var rim_str: float = lerpf(0.25, 0.9, k)
	for m: ShaderMaterial in _painted:
		m.set_shader_parameter(&"rim_color", rim_col)
		m.set_shader_parameter(&"rim_strength", rim_str)
	var boost: float = _sel_boost()
	for m: ShaderMaterial in _glows:
		m.set_shader_parameter(&"boost", boost)


func _process_destroyed(delta: float) -> void:
	_destroy_t += delta
	var t: float = _destroy_t
	# 0.0-0.2: every glow overloads.
	if t < 0.2:
		for m: ShaderMaterial in _glows:
			m.set_shader_parameter(&"boost", 1.0 + 12.0 * t)
	elif _destroy_step == 0:
		_destroy_step = 1
		for f: Node3D in _floaters:
			f.visible = false
		_flash.position = Vector3(0.0, _height * 0.8, 0.0)
		_fire(_flash)
		_dust.position = Vector3(0.0, _height * 0.5, 0.0)
		_fire(_dust)
	# 0.2-1.2: the structure sinks to 30 % with a rumble; tops hidden at 0.8 with a second dust burst.
	if t >= 0.2 and _destroy_step < 3:
		var k: float = clampf((t - 0.2) / 1.0, 0.0, 1.0)
		var s: float = lerpf(1.0, 0.3, 1.0 - pow(1.0 - k, 2.0))
		var jitter := Vector3(sin(t * 94.2) * 0.06, 0.0, cos(t * 87.9) * 0.06) if k < 1.0 else Vector3.ZERO
		for i: int in _parts.size():
			if _parts[i] in _no_collapse:
				continue
			_squash(i, s, plinth_top, jitter)
		if t >= 0.8 and _destroy_step < 2:
			_destroy_step = 2
			for n: Node3D in _hide_on_collapse:
				n.visible = false
			_dust.position = Vector3(0.0, 0.6, 0.0)
			_fire(_dust)
			_debris.visible = true
			_decal.material_override = _decal_mat(true)
			if _wreck:
				_wreck.visible = true
		if k >= 1.0:
			_destroy_step = 3
			for m: ShaderMaterial in _glows:
				m.set_shader_parameter(&"boost", 0.25)
	_debris.scale = Vector3(1.0, lerpf(0.4, 1.0, clampf((t - 0.8) / 0.5, 0.0, 1.0)), 1.0)
	_on_destroy(t)
	if t >= DESTROY_TIME:
		set_process(false)
		destroyed_finished.emit()


func _fire(p: GPUParticles3D) -> void:
	p.restart()
	p.emitting = true


# --- Ground contact (art-keep.md 0.5) ---

func _decal_mat(wreck: bool) -> StandardMaterial3D:
	var key: String = "%s_%s" % [stain_color, wreck]
	if _decal_cache.has(key):
		return _decal_cache[key]
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.03, 0.02, 0.9 if wreck else 0.62))
	g.set_color(1, Color(0.05, 0.03, 0.02, 0.0))
	g.add_point(0.55, Color(stain_color.r, stain_color.g, stain_color.b, stain_color.a * (1.6 if wreck else 1.0)))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = tex
	_decal_cache[key] = m
	return m


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * (footprint + 2.0)
	_decal = MeshInstance3D.new()
	_decal.name = "ContactDecal"
	_decal.mesh = plane
	_decal.position.y = 0.03
	_decal.material_override = _decal_mat(false)
	_decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_decal)
	# Rubble ring (one draw call) and the wreck debris (hidden until the collapse).
	var rng := RandomNumberGenerator.new()
	rng.seed = int(footprint * 1000.0) + int(stone_color.r * 977.0)
	var half: float = footprint * 0.5
	var pts: Array[Vector3] = []
	for i: int in 7:
		var a: float = TAU * (float(i) + rng.randf_range(0.0, 0.6)) / 7.0
		var rad: float = half * rng.randf_range(1.05, 1.2)
		pts.append(Vector3(sin(a) * rad, -0.02, cos(a) * rad))
	_cubes("Rubble", pts, 0.2 + footprint * 0.04, rng)
	pts = []
	for i: int in 11:
		pts.append(Vector3(rng.randf_range(-half, half) * 0.7, wreck_top + rng.randf_range(-0.15, 0.1), rng.randf_range(-half, half) * 0.7))
	_debris = _cubes("Debris", pts, 0.25 + footprint * 0.1, rng)
	_debris.visible = false


func _cubes(nm: String, points: Array[Vector3], size: float, rng: RandomNumberGenerator) -> MultiMeshInstance3D:
	var xf: Array[Transform3D] = []
	for p: Vector3 in points:
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(10.0, 25.0)))
		xf.append(Transform3D(b.scaled(Vector3.ONE * rng.randf_range(0.7, 1.2)), p))
	var mmi := _multi(nm, _box(Vector3.ONE * size), _m_dark, xf)
	mmi.set_instance_shader_parameter(&"ao_bottom", -0.3)
	mmi.set_instance_shader_parameter(&"ao_height", 1.5)
	# Removed from Body by the caller so the rise / collapse ignore it.
	_body.remove_child(mmi)
	add_child(mmi)
	return mmi


# --- State nodes (particles, outline) ---

func _build_state_nodes() -> void:
	var smoke_ramp: Texture2D = _ramp(Color(smoke_color, 0.75), Color(smoke_color, 0.0), false)
	var fire_ramp: Texture2D = _ramp2(blaze_a, blaze_b)
	for pos: Vector3 in smoke_points:
		var pm := _pm(Vector3.UP, 12.0, 1.0, 1.5, Vector3(0.25, 0.1, 0.0), 0.5, 1.8, smoke_ramp)
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.25
		_smoke.append(_particles("Smoke%d" % (_smoke.size() + 1), _body, pos, 16, 3.0, pm, false, false))
	for pos: Vector3 in blaze_points:
		var pm := _pm(Vector3.UP, 15.0, 1.3, 2.2, Vector3.ZERO, 0.7, 0.2, fire_ramp)
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.3
		_blaze.append(_particles("Blaze%d" % (_blaze.size() + 1), _body, pos, 14, 0.9, pm, true, false))
	var du := _pm(Vector3.UP, 55.0, 0.3, 0.9, Vector3(0, -0.2, 0), 0.4, 1.1 + footprint * 0.15,
		_ramp(Color(smoke_color, 0.5), Color(smoke_color, 0.0), false))
	du.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	du.emission_box_extents = Vector3(footprint * 0.3, 0.3, footprint * 0.3)
	_dust = _particles("CollapseDust", self, Vector3(0, 1.0, 0), 14, 1.6, du, false, true)
	var fl := _pm(Vector3.UP, 180.0, 1.5, 3.5, Vector3(0, -4.0, 0), 0.14, 0.04, _ramp(glow_color, glow_color, true))
	_flash = _particles("Flash", self, Vector3(0, _height, 0), 24, 0.7, fl, true, true)   # the collapse burst only
	# G-B leftovers: the completion settle (BuildSettle) instead of the white-hot spark rain.
	var st: int = BuildSettle.style_of(glow_color)
	var half: float = footprint * 0.5
	var gl := BuildSettle.glint_pm(half * 0.8, maxf(_height * 0.3, 0.5), st, _ramp(glow_color, glow_color, true))
	_settle_glint = _particles("SettleGlint", self, Vector3(0, plinth_top + maxf(_height * 0.35, 0.6), 0),
		BuildSettle.glint_amount() * 2 / 3, BuildSettle.GLINT_LIFE, gl, true, true)
	var dc: Color = BuildSettle.dust_color(smoke_color.lerp(stone_color, 0.6), stone_color)
	var sd := BuildSettle.dust_pm_cached(half + 0.2, st, dc)
	_settle_dust = _particles("SettleDust", self, Vector3(0, 0.15, 0), BuildSettle.dust_amount() * 2 / 3, BuildSettle.DUST_LIFE,
		sd, false, true)
	BuildSettle.mark(_settle_dust, _settle_glint)
	# Glowing construction outline: 4 thin emissive bars around the footprint.
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = GLOW
	_outline_mat.set_shader_parameter(&"energy", 2.0)
	_outline_mat.set_shader_parameter(&"pulse_speed", TAU)
	var side: float = footprint + 0.3
	var xf: Array[Transform3D] = []
	for i: int in 4:
		var yaw: float = PI * 0.5 * i
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		xf.append(Transform3D(Basis(Vector3.UP, yaw), dir * side * 0.5 + Vector3(0, 0.05, 0)))
	_outline = _multi("BuildOutline", _box(Vector3(side + 0.2, 0.05, 0.2)), _outline_mat, xf)
	_body.remove_child(_outline)
	add_child(_outline)
	_outline.visible = false


func _ramp(a: Color, b: Color, team: bool) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, Color(b, 0.0))
	if team:
		_team_ramps.append(g)
	var tex := GradientTexture1D.new()
	tex.gradient = g
	return tex


func _ramp2(a: Color, b: Color) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, Color(b.darkened(0.5), 0.0))
	g.add_point(0.4, b)
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


## Shared billboard quad (ADD for fire / sparks / motes, MIX for smoke), art-keep.md 0.6.
static func _quad(add: bool) -> QuadMesh:
	if _quad_cache.has(add):
		return _quad_cache[add]
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
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	m.disable_fog = add  # G-E 5: an additive quad must not fog
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	var q := QuadMesh.new()
	q.material = m
	_quad_cache[add] = q
	return q


func _particles(nm: String, parent: Node3D, pos: Vector3, amount: int, life: float,
		pm: ParticleProcessMaterial, add: bool, one_shot: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = nm
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = true
	p.process_material = pm
	p.draw_pass_1 = _quad_for(add)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-5, -3, -5), Vector3(10, 14, 10))
	p.position = pos
	p.emitting = false
	parent.add_child(p)
	return p


## Idle particles (on only once built), e.g. chimney smoke, orb embers.
func _idle_particles(nm: String, pos: Vector3, amount: int, life: float, pm: ParticleProcessMaterial,
		add: bool) -> GPUParticles3D:
	var p := _particles(nm, _body, pos, amount, life, pm, add, false)
	_idle_fx.append(p)
	return p
