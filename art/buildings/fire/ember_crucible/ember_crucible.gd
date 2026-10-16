class_name EmberCrucibleAnnex
extends Node3D
## The Ember Crucible annex (task 13c.V7, docs/design/titans-2.md 6 + 11, style art-keep.md 0): Fire's second "titan",
## a base upgrade that forges a free Flame Guard every 40 s, shown as a small crucible-and-anvil forge beside the Dragon
## Roost's foot. Draw-only child scene of the Roost model (13.V25): no collision, no navigation, no logic of its own
## besides its look. The Roost art did not exist when this was built, so it is a standalone scene the Roost adds as a
## child (keep it out of the Roost's mesh merge: meta keep_separate / never merged).
##
## Look (from the RTS camera: one warm glowing bowl, lower than the Roost plinth crown by far): a dark basalt floor pad
## with stone flags; a squat stone firebox (dark base course, corner buttresses, bronze band) with a glowing fire mouth
## on each side face (+X and -X: one per camera); on it, between two iron trunnion posts with bronze bearings, a big
## cast-iron crucible with a dark belly band, an open bronze ring rim (the molten metal inside is the read), a bronze
## spout toward local -Z and an iron tipping lever, full of glowing molten metal (a dark slag crust when cold); a
## short stone chimney behind it (+Z) with an ember mouth (top 2.76 m, under a third of the Roost's 9 m nest crown); in
## front a stone mould (a shield and a sword cast in it) with a bronze sprue funnel under the spout; an anvil with a
## glowing blade on a stone stump (+X front); a stone quench trough with tongs (-X front); red leather bellows blowing
## into the firebox (-X back). A fake light pool (additive) warms the floor. 0 real lights.
##
## Hooks (safe before _ready and before the node is in the tree):
##   set_crucible(on: bool, instant: bool = false)  lit / cold. Lighting flares the bowl (a spark burst, a bellows
##       pump) and ramps the glow in over 1.2 s; going out cools it over 2.0 s to a dark slag crust. Before _ready (or
##       with instant) the state is applied at once (save restore, a Roost built with the Crucible already lit).
##   play_forge()  one Flame Guard forged (2.2 s): the bellows pump, the crucible tips 38 deg toward the mould, a white
##       hot stream pours into the sprue, a spark fountain and a floor flare at FORGE_HIT (0.4 s), the mould's shield
##       and sword glow white and cool, steam hisses from the quench trough at 1.3 s, the crucible rights itself.
##       Restarts if retriggered; ignored while the crucible is cold (not lit or still igniting below half heat).
##   is_crucible_on() -> bool, is_forging() -> bool, heat() -> float (0 cold .. 1 lit).
##   Signal forge_poured(at: Vector3) at FORGE_HIT (world point of the sprue): sync the forge clang / Guard exit.
## Placement (for the Roost): origin = the pad's ground contact (put it on the Roost plinth top). Front (the spout,
## mould and anvil) = local -Z, the Roost's gate side; the side mouths face +-X (the two cameras). Bounds: x +-1.35,
## z -1.35..+1.37, top 3.0 m (FOOTPRINT_HALF, TOP_Y). Suggested spot on a 3 x 3 cell (6 x 6 m) Roost: ROOST_ANCHOR
## (a front corner, pad inside 3.3 m of the centre). Hide it on a construction site / wreck; call set_crucible(false,
## true) when the Roost dies (titans-2.md 6.3: the Crucible goes out with the Roost).
## Budget: 11 mesh instances (3 moving: crucible, bellows board, bellows leather) + 3 particle systems (embers
## continuous while lit, sparks and steam one-shots; hidden beyond PARTICLE_RANGE), 10 materials (.tres, shared by
## every annex), 0 lights. Runtime materials: particle draw materials built once and shared, and one ec_painted
## copy per non-fire team colour (_apply_team, shared by every annex of that colour; never per instance). Idle = no
## _process (the glows pulse in the shader); only transitions and forging tick.

signal forge_poured(at: Vector3)

const DIR := "res://art/buildings/fire/ember_crucible/materials/"
const PVC := preload("res://art/buildings/painted_vc.gd")
const GBF := preload("res://art/buildings/fire/fire_building_look.gd")
## Crucible tilt axis (the trunnion pins), annex space.
const AXLE := Vector3(0.0, 1.62, 0.35)
const TILT_DEG := 38.0
## Spout lip end, crucible (pivot) space.
const SPOUT := Vector3(0.0, 0.31, -0.95)
const SPROUT_TOP := 0.70          ## sprue funnel mouth height (the stream lands here)
const FORGE_TIME := 2.2
const FORGE_HIT := 0.4            ## the stream reaches the mould: sparks, flare, forge_poured
const STEAM_AT := 1.3
const IGNITE_TIME := 1.2
const COOL_TIME := 2.0
const MOULD_REST := 0.32          ## residual glow of the last cast while lit
## In-game grade 2026-10-12 (under_90.md row 28): the 40 m read grows inside the same bounds (taller stack, a team
## banner on the outer front corner, team-glazed pad skirt), so TOP_Y rose 2.76 -> 3.0 (still a third of the Roost's
## 9 m crown); ROOST_ANCHOR unchanged, FOOTPRINT_HALF.x 1.30 -> 1.35 (pad to the terrace kerb, inside 3.3 m);
## nothing new on the -X / +Z side toward the Roost's spire.
const TOP_Y := 3.0
const FOOTPRINT_HALF := Vector2(1.35, 1.37)
## Team banner pole (annex space, the outer front corner +X / -Z, away from the Roost's spire).
const BANNER := Vector3(1.19, 0.0, -1.22)
## Quench crane post (annex space, front -X corner beside the trough).
const CRANE := Vector3(-1.2, 0.0, -1.22)
## The fire kingdom colour (painted_vc's default base_color): set_team_color with it keeps the shared material.
const FIRE_TEAM := Color(0.85, 0.30, 0.12)
const ROOST_ANCHOR := Vector3(1.85, 0.0, -1.85)
const PARTICLE_RANGE := 48.0
const AO_HEIGHT := 2.8
## Bellows: hinge (nozzle end), board length and full opening at the handle end.
const BELLOWS_HINGE := Vector3(-0.72, 0.53, 0.80)
const BELLOWS_LEN := 0.46
const BELLOWS_OPEN := 0.30
const BELLOWS_REST := 0.65
## Prop groups set a touch askew (2026-10-12, C1 craft): the mould (and its cast) and the anvil (with its blade).
const MOULD_YAW := -5.0
const ANVIL_YAW := 8.0

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}
static var _prims: Dictionary = {}
static var _fx: Dictionary = {}
static var _team_mats: Dictionary = {}   ## team colour (html) -> ec_painted copy, shared by every annex of that colour

var _team: Color = FIRE_TEAM

var _lit: bool = false
var _heat: float = 0.0
var _ign_t: float = -1.0
var _forge_t: float = -1.0
var _mould_heat: float = 0.0
var _bellows: float = BELLOWS_REST
var _ready_done: bool = false

var _painted: Array[GeometryInstance3D] = []
var _pivot: Node3D
var _static_mi: MeshInstance3D
var _hot: MeshInstance3D
var _molten: MeshInstance3D
var _crust: MeshInstance3D
var _pour: MeshInstance3D
var _mould: MeshInstance3D
var _pool: MeshInstance3D
var _bellows_top: Node3D
var _bellows_leather: Node3D
var _embers: GPUParticles3D
var _sparks: GPUParticles3D
var _steam: GPUParticles3D


# ================================================================ hooks

## Lights (true) or puts out (false) the crucible. `instant` skips the ignition / cooling ramps.
func set_crucible(on: bool, instant: bool = false) -> void:
	if on == _lit and not instant:
		return
	_lit = on
	if not _ready_done or instant:
		_heat = 1.0 if on else 0.0
		_ign_t = -1.0
		_mould_heat = MOULD_REST if on else 0.0
		if not on:
			_forge_t = -1.0
		if _ready_done:
			_apply(0.0)
		return
	if on:
		_ign_t = 0.0
		_burst(_sparks, Vector3(AXLE.x, AXLE.y + 0.45, AXLE.z))
	set_process(true)


## One Flame Guard forged: the pour (2.2 s). Ignored while cold.
func play_forge() -> void:
	if not _ready_done or not _lit or _heat < 0.5:
		return
	_forge_t = 0.0
	set_process(true)


func is_crucible_on() -> bool:
	return _lit


func is_forging() -> bool:
	return _forge_t >= 0.0


func heat() -> float:
	return _heat


# ---------------------------------------------------------------- standard building hooks (art-keep.md 8.8)
# The annex is a draw-only child of the Dragon Roost, which drives it with set_crucible / play_forge; these keep the
# common building contract so tools and a standalone annex behave: selection has nothing to tint, a site shows
# nothing until built, a dead Roost puts it out. set_team_color (2026-10-12): the banner, the glazed pad skirt, the
# firebox band and the stack collar take the team colour (ec_team parts; the fire colour by default).

func set_team_color(c: Color) -> void:
	_team = c
	if _ready_done:
		_apply_team()


func set_selected(_on: bool) -> void:
	pass


func set_construction_progress(p: float) -> void:
	visible = p >= 1.0


func set_health_ratio(r: float) -> void:
	if r <= 0.0:
		set_crucible(false)


func play_destroyed() -> void:
	set_crucible(false)


## World point of the sprue funnel (where the pour lands; the sparks and forge_poured come from here).
func get_sprue_point() -> Vector3:
	return global_transform * _sprue()


# ================================================================ build

func _ready() -> void:
	_build()
	# B8: the five painted .tres (stone, dark, bronze, iron, leather) are drawn with ONE vertex-coloured material,
	# ec_painted.tres (PaintedVC, painted_vc shader: the same shading), shared by every annex like the others.
	# ec_team parts get COLOR.a 0: drawn as ec_painted's base_color (the team colour, see _apply_team).
	# G-B: ec_painted is shared; an earlier annex already switched it to the Fire shader, which PaintedVC.convert does
	# not accept: back to painted_vc for the convert, then the Fire paint layer again (same contract, in memory).
	var body := m("ec_painted") as ShaderMaterial
	if body.shader == GBF.FIRE_VC:
		body.shader = GBF.PAINTED_VC
	PVC.convert(self, body, [m("ec_team")])
	GBF.apply(body)
	_ready_done = true
	_apply_team()
	set_notify_transform(true)
	_update_ao()
	_apply(0.0)
	set_process(_needs_process())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and _ready_done:
		_update_ao()


## The team colour: the fire colour draws with the shared ec_painted.tres itself; another colour with one shared copy
## per colour (built once, never per annex), set as a surface override on the painted surfaces.
func _apply_team() -> void:
	var body := m("ec_painted") as ShaderMaterial
	var mat: Material = body
	if not _team.is_equal_approx(FIRE_TEAM):
		var key := _team.to_html(false)
		if not _team_mats.has(key):
			var dup := body.duplicate() as ShaderMaterial
			dup.set_shader_parameter(&"base_color", _team)
			dup.set_meta(&"team_copy_of", body.resource_path)   # tools / tests map it back to ec_painted.tres
			_team_mats[key] = dup
		mat = _team_mats[key]
	for n: Node in find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		# PaintedVC.convert put `body` on the painted surfaces as a surface override.
		for s: int in mi.mesh.get_surface_count():
			var cur: Material = mi.get_surface_override_material(s)
			if cur != null and (cur == body or _team_mats.values().has(cur)):
				mi.set_surface_override_material(s, mat)


static func m(name: String) -> Material:
	if not _mats.has(name):
		_mats[name] = load(DIR + name + ".tres")
	return _mats[name]


## Sprue funnel position (annex space): straight under the spout at full tilt.
static func _sprue() -> Vector3:
	var s: Vector3 = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-TILT_DEG)), AXLE) * SPOUT
	return Vector3(s.x, SPROUT_TOP, s.z)


func _build() -> void:
	_static_mi = _mesh_instance("Static", "static", _static_items, self, true)
	_painted.append(_static_mi)
	_hot = _mesh_instance("HotGlow", "hot", _hot_items, self, false)
	_mould = _mesh_instance("MouldGlow", "mould", _mould_items, self, false)
	# Pilot glows (always on, lit or cold): the banner's ember lantern and the forge sigils on the stack.
	_mesh_instance("PilotGlow", "pilot", _pilot_items, self, false)
	# The crucible (tilts on its trunnions).
	_pivot = Node3D.new()
	_pivot.name = "CruciblePivot"
	_pivot.position = AXLE
	add_child(_pivot)
	_painted.append(_mesh_instance("CrucibleBody", "body", _body_items, _pivot, true))
	_crust = _mesh_instance("Crust", "crust", _crust_items, _pivot, true)
	_painted.append(_crust)
	_molten = _mesh_instance("Molten", "molten", _molten_items, _pivot, false)
	# The pour: a unit cylinder placed every frame from the spout down to the sprue.
	_pour = MeshInstance3D.new()
	_pour.name = "Pour"
	_pour.mesh = _prim("pour", func() -> Mesh: return _cyl_mesh(0.5, 0.5, 1.0, 8))
	_pour.material_override = m("ec_white_hot")
	_pour.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pour.visible = false
	add_child(_pour)
	# Bellows: the top board hinges at the nozzle; the leather wedge stretches with it.
	_bellows_top = Node3D.new()
	_bellows_top.name = "BellowsTop"
	_bellows_top.position = BELLOWS_HINGE
	add_child(_bellows_top)
	_painted.append(_mesh_instance("BellowsBoard", "bellows_board", _bellows_board_items, _bellows_top, true))
	_bellows_leather = Node3D.new()
	_bellows_leather.name = "BellowsLeather"
	_bellows_leather.position = BELLOWS_HINGE
	add_child(_bellows_leather)
	_painted.append(_mesh_instance("Leather", "bellows_leather", _bellows_leather_items, _bellows_leather, true))
	# Fake light pool on the floor.
	_pool = MeshInstance3D.new()
	_pool.name = "LightPool"
	_pool.mesh = _prim("pool", func() -> Mesh:
		var pm := PlaneMesh.new()
		pm.size = Vector2(2.9, 2.9)
		return pm)
	_pool.material_override = m("ec_pool")
	_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pool.position = Vector3(0.0, 0.275, -0.15)
	add_child(_pool)
	# Particles.
	_embers = _particles("Embers", &"embers", Vector3(AXLE.x, AXLE.y + 0.42, AXLE.z), 10, 1.6, false)
	_sparks = _particles("Sparks", &"sparks", _sprue(), 40, 0.95, true)
	_steam = _particles("Steam", &"steam", Vector3(-0.92, 0.66, -0.72), 10, 1.7, true)


func _mesh_instance(nm: String, key: String, build: Callable, parent: Node3D, shadows: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = _merged_mesh(key, build)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## One ArrayMesh per part key, one surface per material (materials set on the mesh: shared .tres), built once.
static func _merged_mesh(key: String, build: Callable) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var items: Array = build.call()
	var mats: Array[Material] = []
	for it: Array in items:
		if not mats.has(it[2]):
			mats.append(it[2])
	var am := ArrayMesh.new()
	for mat: Material in mats:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for it: Array in items:
			if it[2] != mat:
				continue
			var src: Mesh = it[0]
			for s: int in src.get_surface_count():
				st.append_from(src, s, it[1])
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, mat)
	_meshes[key] = am
	return am


# ---------------------------------------------------------------- primitives

static func _prim(key: String, make: Callable) -> Mesh:
	if not _prims.has(key):
		_prims[key] = make.call()
	return _prims[key]


static func _cyl_mesh(top: float, bottom: float, h: float, seg: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 0
	return c


const SQRT2 := 1.41421356


## A square frustum tile without its hidden bottom face (unit square base, corners at +-0.5; top = `taper` x the
## base): pads, flags and stone blocks get bevelled sides that break the light, and no area wasted face-down.
static func _tile_mesh(taper: float, cap_top: bool = true) -> Mesh:
	return _prim("tile_%.3f_%s" % [taper, cap_top], func() -> Mesh:
		var c := _cyl_mesh(taper * SQRT2 * 0.5, SQRT2 * 0.5, 1.0, 4)
		c.cap_bottom = false
		c.cap_top = cap_top
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.append_from(c, 0, Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3.ZERO))
		return st.commit())


static func _tl(pos: Vector3, size: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, taper: float = 0.9) -> Array:
	return _it(_tile_mesh(taper), pos, mat, rot_deg, size)


static func _box() -> Mesh:
	return _prim("box", func() -> Mesh:
		var b := BoxMesh.new()
		b.size = Vector3.ONE
		return b)


## A cylinder with its hidden caps left out (cap_top / cap_bottom false: buried in or covered by another part).
static func _cylc(top: float, bottom: float, h: float, seg: int, cap_top: bool, cap_bottom: bool) -> Mesh:
	return _prim("cylc_%.3f_%.3f_%.3f_%d_%s_%s" % [top, bottom, h, seg, cap_top, cap_bottom], func() -> Mesh:
		var c := _cyl_mesh(top, bottom, h, seg)
		c.cap_top = cap_top
		c.cap_bottom = cap_bottom
		return c)


static func _cyl(top: float, bottom: float, h: float, seg: int = 12) -> Mesh:
	return _prim("cyl_%.3f_%.3f_%.3f_%d" % [top, bottom, h, seg], func() -> Mesh: return _cyl_mesh(top, bottom, h, seg))


## A ring (the crucible rim: the bowl stays open so the molten metal shows).
static func _torus(inner: float, outer: float) -> Mesh:
	return _prim("torus_%.3f_%.3f" % [inner, outer], func() -> Mesh:
		var t := TorusMesh.new()
		t.inner_radius = inner
		t.outer_radius = outer
		t.rings = 28
		t.ring_segments = 10
		return t)


static func _sph(r: float) -> Mesh:
	return _prim("sph_%.3f" % r, func() -> Mesh:
		var s := SphereMesh.new()
		s.radius = r
		s.height = r * 2.0
		s.radial_segments = 10
		s.rings = 5
		return s)


static func _it(mesh: Mesh, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Array:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
	return [mesh, Transform3D(b.scaled_local(scale), pos), mat]


## Turns items[from..] about the vertical axis through `centre` (a prop group set askew as one piece).
static func _yaw_group(items: Array, from: int, centre: Vector3, deg: float) -> void:
	var c := Vector3(centre.x, 0.0, centre.z)
	var t := Transform3D(Basis.IDENTITY, c) * Transform3D(Basis(Vector3.UP, deg_to_rad(deg)), Vector3.ZERO)
	t = t * Transform3D(Basis.IDENTITY, -c)
	for i: int in range(from, items.size()):
		items[i][1] = t * (items[i][1] as Transform3D)


## A box without its bottom face (never seen from the RTS camera; 2026-10-12, C1 craft: no area wasted face-down).
static func _bx(pos: Vector3, size: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> Array:
	return _it(_tile_mesh(1.0), pos, mat, rot_deg, size)


## A box running from `a` to `b` (local Z along the segment), `w` wide and `t` thick.
static func _slab(a: Vector3, b: Vector3, w: float, t: float, mat: Material) -> Array:
	var z: Vector3 = b - a
	var len: float = z.length()
	z = z / maxf(len, 0.0001)
	var x: Vector3 = Vector3.RIGHT if absf(z.x) < 0.9 else Vector3.UP
	var y: Vector3 = z.cross(x).normalized()
	x = y.cross(z).normalized()
	return [_box(), Transform3D(Basis(x, y, z).scaled_local(Vector3(w, t, len)), (a + b) * 0.5), mat]


# ---------------------------------------------------------------- parts

## Floor pad, firebox, chimney, trunnion posts, mould, sprue, anvil + stump, quench trough, bellows base, tools.
static func _static_items() -> Array:
	var stone := m("ec_stone")
	var dark := m("ec_dark")
	var bronze := m("ec_bronze")
	var iron := m("ec_iron")
	var team := m("ec_team")
	var it: Array = []
	# Floor pad (2026-10-12): a team-glazed tile skirt (a square frustum, no hidden bottom face) under a dark grout
	# slab and nine pale fireclay flags: the value step that keeps the forge off dark ash, the team colour round it.
	it.append(_it(_tile_mesh(1.2 / 1.35, false), Vector3(0.0, 0.1, 0.0), team, Vector3.ZERO, Vector3(2.7, 0.2, 2.7)))
	it.append(_tl(Vector3(0.0, 0.22, 0.0), Vector3(2.42, 0.04, 2.42), dark, Vector3.ZERO, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 70713
	for ix: int in 3:
		for iz: int in 3:
			var p := Vector3(-0.79 + 0.79 * ix + rng.randf_range(-0.02, 0.02), 0.245,
				-0.79 + 0.79 * iz + rng.randf_range(-0.02, 0.02))
			it.append(_tl(p, Vector3(0.72, 0.05, 0.72), stone, Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-11.0, 11.0), rng.randf_range(-3.0, 3.0))))
	# Firebox (centre z 0.35): base course, stone body, corner buttresses, bronze band, collar.
	var fz: float = AXLE.z
	# 2026-10-12: an octagonal firebox (flat faces on the axes, the fire mouths on +-X), buttresses on the four
	# diagonal faces, a sloped collar hood: the light breaks on eight directions instead of four (C1 craft).
	var o8 := Vector3(0, 22.5, 0)
	var k8: float = 1.0 / cos(deg_to_rad(22.5))           # octagon vertex radius per apothem
	it.append(_it(_cylc(0.65 * k8, 0.76 * k8, 0.22, 8, false, false), Vector3(0.0, 0.37, fz), dark, o8))
	it.append(_it(_cylc(0.64 * k8, 0.65 * k8, 0.62, 8, false, false), Vector3(0.0, 0.79, fz), stone, o8))
	for d: float in [45.0, 135.0, 225.0, 315.0]:
		var dv := Vector3(cos(deg_to_rad(d)), 0.0, sin(deg_to_rad(d))) * 0.66
		it.append(_bx(Vector3(dv.x, 0.8, fz + dv.z), Vector3(0.24, 0.66, 0.22), dark, Vector3(0, -d, 0)))
	it.append(_it(_cylc(0.685 * k8, 0.69 * k8, 0.09, 8, true, false), Vector3(0.0, 1.05, fz), team, o8))
	it.append(_it(_cylc(0.6 * k8, 0.82 * k8, 0.14, 8, false, false), Vector3(0.0, 1.17, fz), dark, o8))
	it.append(_it(_cylc(0.0, 0.6 * k8, 0.05, 8, false, false), Vector3(0.0, 1.265, fz), dark, o8))
	# Fire mouths on both side faces (the coals glow in HotGlow): a dark hole, a bronze lintel with a keystone, a sill.
	for sx: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(sx * 0.655, 0.73, fz), Vector3(0.06, 0.42, 0.44), dark))
		it.append(_bx(Vector3(sx * 0.68, 0.99, fz), Vector3(0.12, 0.12, 0.56), bronze))
		it.append(_bx(Vector3(sx * 0.7, 1.0, fz), Vector3(0.1, 0.2, 0.16), bronze))
		it.append(_bx(Vector3(sx * 0.68, 0.51, fz), Vector3(0.14, 0.07, 0.56), bronze))
	# Chimney behind the crucible (+Z, 2026-10-12: taller, a tapering round stack on a dark footing): two dark
	# bands, a team-glazed collar, an open crown (the ember mouth glows inside), four bronze spikes up to TOP_Y.
	var cz: float = 1.02
	it.append(_tl(Vector3(0.0, 0.5, cz), Vector3(0.72, 0.5, 0.64), dark, Vector3.ZERO, 0.86))
	it.append(_it(_cylc(0.3, 0.345, 1.89, 20, true, false), Vector3(0.0, 1.655, cz), stone))
	for y: float in [1.28, 1.9]:
		it.append(_it(_cyl(0.365, 0.372, 0.1, 8), Vector3(0.0, y, cz), dark, Vector3(0, 22.5, 0)))
	it.append(_it(_cyl(0.36, 0.31, 0.2, 8), Vector3(0.0, 2.48, cz), team, Vector3(0, 22.5, 0)))
	it.append(_it(_cyl(0.372, 0.36, 0.06, 8), Vector3(0.0, 2.36, cz), dark, Vector3(0, 22.5, 0)))
	# Crown rim (G-F round 3 item 6): a round lip and eight rounded rim stones round the ember mouth, so the top reads
	# as a round stack, never a square.
	# Low-poly (6-sided tapered stones, top caps only: the triangle budget) and inside FOOTPRINT_HALF.
	it.append(_it(_cylc(0.325, 0.34, 0.08, 16, false, false), Vector3(0.0, 2.62, cz), dark))
	for i: int in 8:
		var a: float = TAU * (float(i) + 0.5) / 8.0
		var h: float = 0.13 if i % 2 == 0 else 0.1
		it.append(_it(_cylc(0.05, 0.075, h, 6, true, false), Vector3(cos(a) * 0.265, 2.66 + h * 0.5, cz + sin(a) * 0.265), dark, Vector3(0, float(i) * 17.0, 0)))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			it.append(_it(_cyl(0.0, 0.07, 0.28, 6), Vector3(sx * 0.32, 2.85, cz + sz * 0.27), bronze, Vector3(0, 0, -sx * 8.0)))
	# Team banner on the outer front corner (+X / -Z): a stone socket, an iron pole, a crossbar running inward on the
	# diagonal, a team flag on it (both cameras see it at 45 deg; dark hems, a bronze sun disc on both faces), a bronze
	# finial cup under the ember lantern.
	var bp := BANNER
	var fd := Vector3(-SQRT2 * 0.5, 0.0, SQRT2 * 0.5)    # flag direction from the pole
	var fc := bp + fd * 0.4                              # flag centre (x, z)
	it.append(_it(_cyl(0.08, 0.11, 0.22, 8), Vector3(bp.x, 0.36, bp.z), stone))
	it.append(_it(_cyl(0.035, 0.045, 2.5, 8), Vector3(bp.x, 1.47, bp.z), iron))
	it.append(_slab(Vector3(bp.x, 2.66, bp.z) - fd * 0.03, Vector3(bp.x, 2.62, bp.z) + fd * 0.8, 0.05, 0.05, iron))
	it.append(_bx(Vector3(fc.x, 2.0, fc.z), Vector3(0.035, 1.2, 0.72), team, Vector3(0, -45, 0)))
	it.append(_bx(Vector3(fc.x, 1.42, fc.z), Vector3(0.045, 0.07, 0.74), dark, Vector3(0, -45, 0)))
	it.append(_bx(Vector3(fc.x, 2.57, fc.z), Vector3(0.045, 0.07, 0.74), dark, Vector3(0, -45, 0)))
	it.append(_it(_cyl(0.16, 0.16, 0.06, 12), Vector3(fc.x, 2.05, fc.z), bronze, Vector3(0, -45, 90)))
	it.append(_it(_cyl(0.11, 0.04, 0.12, 8), Vector3(bp.x, 2.77, bp.z), bronze))
	# Quench crane (front -X corner): an iron post on a stone socket, a raking brace, a jib out over the trough, a chain
	# and a bronze dipping bucket.
	var cp := CRANE
	var jd := Vector3(0.45, 0.0, 0.45)                   # jib reach toward the trough centre
	it.append(_it(_cyl(0.09, 0.12, 0.24, 8), Vector3(cp.x, 0.37, cp.z), stone))
	it.append(_it(_cyl(0.05, 0.06, 2.1, 8), Vector3(cp.x, 1.3, cp.z), iron))
	it.append(_slab(Vector3(cp.x, 2.3, cp.z) - jd * 0.15, Vector3(cp.x, 2.3, cp.z) + jd, 0.07, 0.09, iron))
	it.append(_slab(Vector3(cp.x, 1.7, cp.z), Vector3(cp.x, 2.27, cp.z) + jd * 0.62, 0.05, 0.05, iron))
	it.append(_it(_cyl(0.1, 0.07, 0.12, 8), Vector3(cp.x, 2.38, cp.z), bronze))
	it.append(_bx(Vector3(cp.x, 1.92, cp.z) + jd * 0.92, Vector3(0.025, 0.72, 0.025), iron))
	it.append(_it(_cyl(0.13, 0.1, 0.2, 10), Vector3(cp.x, 1.48, cp.z) + jd * 0.92, bronze))
	# Trunnion posts and bearing blocks (the pins of the crucible turn in them).
	for sx: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(sx * 0.76, 1.36, fz), Vector3(0.18, 0.44, 0.24), iron))
		it.append(_bx(Vector3(sx * 0.76, AXLE.y, fz), Vector3(0.26, 0.2, 0.32), bronze))
		it.append(_slab(Vector3(sx * 0.76, 1.24, fz - 0.42), Vector3(sx * 0.76, 1.5, fz - 0.1), 0.1, 0.1, iron))
		it.append(_slab(Vector3(sx * 0.76, 1.24, fz + 0.42), Vector3(sx * 0.76, 1.5, fz + 0.1), 0.1, 0.1, iron))
	# Mould (a stone block, a bronze frame, the dark cavities of a round shield and a sword) and the sprue funnel.
	var mz: float = -0.74
	var g0: int = it.size()
	it.append(_tl(Vector3(0.0, 0.4, mz), Vector3(0.94, 0.28, 0.62), dark, Vector3.ZERO, 0.9))
	for sz: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(0.0, 0.56, mz + sz * 0.3), Vector3(0.98, 0.05, 0.07), bronze))
	for sx: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(sx * 0.475, 0.56, mz), Vector3(0.07, 0.05, 0.62), bronze))
	it.append(_it(_cyl(0.19, 0.19, 0.012, 14), Vector3(-0.2, 0.545, mz - 0.04), iron))
	it.append(_bx(Vector3(0.17, 0.545, mz - 0.08), Vector3(0.46, 0.012, 0.08), iron))
	it.append(_bx(Vector3(-0.07, 0.545, mz - 0.08), Vector3(0.05, 0.012, 0.22), iron))
	_yaw_group(it, g0, Vector3(0.0, 0.0, mz), MOULD_YAW)   # set a touch askew (C1: the light breaks on it)
	var sp := _sprue()
	it.append(_it(_cyl(0.16, 0.07, 0.16, 10), Vector3(sp.x, SPROUT_TOP - 0.08, sp.z), bronze))
	it.append(_it(_cyl(0.07, 0.07, 0.1, 8), Vector3(sp.x, SPROUT_TOP - 0.2, sp.z), bronze))
	# Anvil on a stone stump (+X front), a hammer lying on its face.
	var ax: float = 0.9
	var az: float = -0.58
	it.append(_tl(Vector3(ax, 0.46, az), Vector3(0.46, 0.4, 0.46), stone, Vector3(0, 8, 0), 0.82))
	it.append(_bx(Vector3(ax, 0.67, az), Vector3(0.5, 0.05, 0.5), dark, Vector3(0, 8, 0)))
	g0 = it.size()
	it.append(_bx(Vector3(ax, 0.74, az), Vector3(0.22, 0.12, 0.3), iron))
	it.append(_bx(Vector3(ax, 0.84, az), Vector3(0.3, 0.09, 0.58), iron))
	it.append(_it(_cyl(0.0, 0.1, 0.3, 8), Vector3(ax, 0.84, az - 0.43), iron, Vector3(-90, 0, 0), Vector3(1.0, 1.0, 0.8)))
	it.append(_bx(Vector3(ax, 0.84, az + 0.33), Vector3(0.2, 0.07, 0.1), iron))
	it.append(_slab(Vector3(ax - 0.05, 0.915, az + 0.2), Vector3(ax + 0.38, 0.915, az + 0.3), 0.05, 0.05, bronze))
	it.append(_bx(Vector3(ax - 0.06, 0.94, az + 0.2), Vector3(0.12, 0.1, 0.22), iron))
	_yaw_group(it, g0, Vector3(ax, 0.0, az), ANVIL_YAW)   # the anvil turned with its stump
	# Quench trough (-X front): stone basin, bronze rim, dark water, tongs leaning in it.
	var qx: float = -0.92
	var qz: float = -0.72
	g0 = it.size()
	it.append(_it(_tile_mesh(0.9, false), Vector3(qx, 0.44, qz), stone, Vector3.ZERO, Vector3(0.62, 0.36, 0.8)))
	for sz: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(qx, 0.63, qz + sz * 0.38), Vector3(0.66, 0.05, 0.07), bronze))
	for sx: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(qx + sx * 0.3, 0.63, qz), Vector3(0.07, 0.05, 0.8), bronze))
	it.append(_bx(Vector3(qx, 0.6, qz), Vector3(0.5, 0.02, 0.68), iron))
	it.append(_slab(Vector3(qx + 0.12, 0.58, qz + 0.1), Vector3(qx + 0.26, 1.12, qz + 0.34), 0.05, 0.05, iron))
	it.append(_slab(Vector3(qx + 0.18, 0.58, qz + 0.06), Vector3(qx + 0.3, 1.1, qz + 0.3), 0.05, 0.05, iron))
	_yaw_group(it, g0, Vector3(qx, 0.0, qz), 6.0)
	# Bellows base (-X back): a stone block, the lower board, the bronze nozzle into the firebox wall.
	var h := BELLOWS_HINGE
	it.append(_tl(Vector3(h.x - 0.25, 0.37, h.z), Vector3(0.56, 0.22, 0.5), stone, Vector3.ZERO, 0.85))
	it.append(_bx(Vector3(h.x - 0.25, h.y - 0.025, h.z), Vector3(BELLOWS_LEN + 0.06, 0.05, 0.48), dark))
	it.append(_it(_cyl(0.045, 0.1, 0.2, 8), Vector3(h.x + 0.05, h.y + 0.03, h.z), bronze, Vector3(0, 0, -90)))
	return it


## Coals in both fire mouths, the coal bed under the crucible, the chimney's ember mouth, the blade on the anvil.
static func _hot_items() -> Array:
	var coals := m("ec_coals")
	var molten := m("ec_molten")
	var it: Array = []
	for sx: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(sx * 0.692, 0.7, AXLE.z), Vector3(0.02, 0.3, 0.38), coals))
	it.append(_it(_cyl(0.5, 0.54, 0.06, 14), Vector3(0.0, 1.27, AXLE.z), coals))
	it.append(_it(_cylc(0.26, 0.26, 0.03, 10, true, false), Vector3(0.0, 2.635, 1.02), coals))   # round coal bed (r3: no square)
	var g0: int = it.size()
	it.append(_bx(Vector3(0.9, 0.9, -0.66), Vector3(0.07, 0.035, 0.44), molten))
	it.append(_bx(Vector3(0.9, 0.9, -0.34), Vector3(0.04, 0.03, 0.14), molten))
	_yaw_group(it, g0, Vector3(0.9, 0.0, -0.58), ANVIL_YAW)
	return it


## Always-on pilot glows (lit or cold): the ember lantern on the banner finial, a forge sigil slit on both side faces
## of the stack (one faces each camera).
static func _pilot_items() -> Array:
	var molten := m("ec_molten")
	var it: Array = []
	it.append(_it(_sph(0.1), Vector3(BANNER.x, 2.89, BANNER.z), molten))
	# The chimney's pit floor (G-F round 3 item 6): dark ember red with a faint warm glow, never a black hole; the
	# lit coal bed (HotGlow) sits just above it.
	it.append(_it(_cylc(0.29, 0.29, 0.02, 10, true, false), Vector3(0.0, 2.61, 1.02), m("ec_pit")))   # over the stack's stone cap (2.6)
	for sx: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(sx * 0.3, 2.13, 1.02), Vector3(0.03, 0.34, 0.12), molten, Vector3(0, 0, sx * 1.7)))
	return it


## The fresh cast in the mould (shield + sword) and the sprue mouth.
static func _mould_items() -> Array:
	var hot := m("ec_white_hot")
	var it: Array = []
	var mz: float = -0.74
	it.append(_it(_cyl(0.18, 0.18, 0.02, 14), Vector3(-0.2, 0.556, mz - 0.04), hot))
	it.append(_bx(Vector3(0.17, 0.556, mz - 0.08), Vector3(0.44, 0.02, 0.07), hot))
	it.append(_bx(Vector3(-0.07, 0.556, mz - 0.08), Vector3(0.045, 0.02, 0.2), hot))
	_yaw_group(it, 0, Vector3(0.0, 0.0, mz), MOULD_YAW)
	var sp := _sprue()
	it.append(_it(_cyl(0.13, 0.13, 0.02, 10), Vector3(sp.x, SPROUT_TOP + 0.005, sp.z), hot))
	return it


## The crucible (pivot space, origin on the trunnion axis): a bulbous cast-iron bowl, bronze belly band and heavy
## rim, a spout toward -Z, the trunnion pins with bronze caps and a tipping lever on the +X pin.
static func _body_items() -> Array:
	var iron := m("ec_iron")
	var bronze := m("ec_bronze")
	var dark := m("ec_dark")
	var it: Array = []
	it.append(_it(_cylc(0.53, 0.38, 0.34, 32, false, false), Vector3(0.0, -0.16, 0.0), iron))
	it.append(_it(_cylc(0.58, 0.53, 0.3, 32, false, false), Vector3(0.0, 0.16, 0.0), iron))
	it.append(_it(_cylc(0.38, 0.28, 0.07, 24, false, true), Vector3(0.0, -0.36, 0.0), dark))
	it.append(_it(_cylc(0.56, 0.56, 0.09, 24, false, false), Vector3(0.0, 0.0, 0.0), dark))
	it.append(_it(_torus(0.47, 0.65), Vector3(0.0, 0.35, 0.0), bronze, Vector3.ZERO, Vector3(1.0, 0.75, 1.0)))
	# Rivet heads round the belly band (2026-10-12: secondary detail at the close-up).
	for i: int in 14:
		var a: float = TAU * (float(i) + 0.5) / 14.0
		it.append(_it(_sph(0.035), Vector3(cos(a) * 0.565, 0.0, sin(a) * 0.565), bronze))
	# Spout: a bronze trough over the rim toward -Z (base + two side lips), a lip plate.
	it.append(_bx(Vector3(0.0, 0.3, -0.72), Vector3(0.28, 0.06, 0.48), bronze, Vector3(-8, 0, 0)))
	for sx: float in [-1.0, 1.0]:
		it.append(_bx(Vector3(sx * 0.14, 0.35, -0.72), Vector3(0.05, 0.12, 0.48), bronze, Vector3(-8, 0, 0)))
	# Trunnion pins (through the bowl) and caps outside the bearings.
	it.append(_it(_cyl(0.09, 0.09, 1.66, 8), Vector3.ZERO, iron, Vector3(0, 0, 90)))
	for sx: float in [-1.0, 1.0]:
		it.append(_it(_cyl(0.13, 0.13, 0.06, 10), Vector3(sx * 0.9, 0.0, 0.0), bronze, Vector3(0, 0, 90)))
	# Tipping lever on the +X pin (outside the bearing): a bronze arm back and up, a dark grip knob.
	it.append(_slab(Vector3(0.96, 0.0, 0.0), Vector3(0.96, 0.52, 0.46), 0.08, 0.08, iron))
	it.append(_it(_sph(0.09), Vector3(0.96, 0.55, 0.49), bronze))
	return it


## Cold slag crust in the bowl (off): a dark disc with a few lumps below the rim.
static func _crust_items() -> Array:
	var dark := m("ec_dark")
	var it: Array = []
	# G-F round 3 item 6: the crust floor is dark ember red (ec_pit, a faint warm glow), not black; the lumps stay dark.
	it.append(_it(_cylc(0.42, 0.55, 0.05, 12, true, false), Vector3(0.0, 0.31, 0.0), m("ec_pit"), Vector3(0, 9, 0)))
	for p: Vector3 in [Vector3(0.18, 0.32, 0.12), Vector3(-0.22, 0.32, -0.06), Vector3(0.02, 0.32, -0.26)]:
		it.append(_it(_sph(0.11), p, dark, Vector3.ZERO, Vector3(1.0, 0.45, 1.0)))
	return it


## Molten metal (lit): a flat disc and a low dome so it reads as a full, bright bowl from above.
static func _molten_items() -> Array:
	var molten := m("ec_molten")
	var it: Array = []
	it.append(_it(_cyl(0.55, 0.55, 0.04, 24), Vector3(0.0, 0.325, 0.0), molten))
	it.append(_it(_sph(0.44), Vector3(0.0, 0.33, 0.0), molten, Vector3.ZERO, Vector3(1.0, 0.16, 1.0)))
	return it


## Bellows top board (board space: origin on the hinge, the board runs toward -X).
static func _bellows_board_items() -> Array:
	var it: Array = []
	it.append(_bx(Vector3(-BELLOWS_LEN * 0.5, 0.025, 0.0), Vector3(BELLOWS_LEN + 0.06, 0.05, 0.48), m("ec_dark")))
	it.append(_bx(Vector3(-BELLOWS_LEN - 0.06, 0.03, 0.0), Vector3(0.1, 0.05, 0.1), m("ec_bronze")))
	it.append(_it(_cyl(0.08, 0.08, 0.03, 8), Vector3(-BELLOWS_LEN * 0.55, 0.055, 0.0), m("ec_bronze")))
	return it


## Bellows leather: a wedge (thin at the hinge, BELLOWS_OPEN tall at the handle end); its node scales in y.
static func _bellows_leather_items() -> Array:
	var p := PrismMesh.new()
	p.left_to_right = 0.0
	p.size = Vector3(BELLOWS_LEN, BELLOWS_OPEN, 0.44)
	return [[p, Transform3D(Basis.IDENTITY, Vector3(-BELLOWS_LEN * 0.5, BELLOWS_OPEN * 0.5, 0.0)), m("ec_leather")]]


# ---------------------------------------------------------------- particles

static func _soft_tex() -> Texture2D:
	if not _fx.has(&"tex"):
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.3, Color(1, 1, 1, 0.85))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 32
		gt.height = 32
		_fx[&"tex"] = gt
	return _fx[&"tex"]


static func _ramp(cols: Array[Color], offs: PackedFloat32Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = offs
	g.colors = PackedColorArray(cols)
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt


static func _curve(pts: Array[Vector2]) -> CurveTexture:
	var c := Curve.new()
	for p: Vector2 in pts:
		c.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = c
	return ct


## Shared process + draw resources per kind (built once for every annex).
static func _fx_pair(kind: StringName) -> Array:
	if _fx.has(kind):
		return _fx[kind]
	var pm := ParticleProcessMaterial.new()
	var size: float = 0.14
	var additive := true
	match kind:
		&"embers":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 0.34
			pm.direction = Vector3.UP
			pm.spread = 18.0
			pm.initial_velocity_min = 0.8
			pm.initial_velocity_max = 1.7
			pm.gravity = Vector3(0.0, 0.35, 0.0)
			pm.damping_min = 0.3
			pm.damping_max = 0.6
			pm.color_ramp = _ramp([Color(2.2, 1.3, 0.45, 1), Color(1.6, 0.45, 0.1, 0.9), Color(0.8, 0.15, 0.04, 0)],
				PackedFloat32Array([0.0, 0.5, 1.0]))
			pm.scale_curve = _curve([Vector2(0, 1.0), Vector2(1, 0.25)])
			size = 0.15
		&"sparks":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 0.12
			pm.direction = Vector3.UP
			pm.spread = 55.0
			pm.initial_velocity_min = 3.2
			pm.initial_velocity_max = 6.2
			pm.gravity = Vector3(0.0, -9.8, 0.0)
			pm.color_ramp = _ramp([Color(3.0, 2.6, 1.6, 1), Color(2.4, 1.2, 0.3, 1), Color(1.2, 0.3, 0.05, 0)],
				PackedFloat32Array([0.0, 0.35, 1.0]))
			pm.scale_curve = _curve([Vector2(0, 1.0), Vector2(1, 0.4)])
			size = 0.14
		&"steam":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			pm.emission_box_extents = Vector3(0.2, 0.02, 0.3)
			pm.direction = Vector3.UP
			pm.spread = 22.0
			pm.initial_velocity_min = 0.7
			pm.initial_velocity_max = 1.4
			pm.gravity = Vector3(0.0, 0.3, 0.0)
			pm.damping_min = 0.4
			pm.damping_max = 0.7
			pm.color_ramp = _ramp([Color(0.95, 0.93, 0.9, 0.0), Color(0.95, 0.93, 0.9, 0.55), Color(0.85, 0.83, 0.82, 0.0)],
				PackedFloat32Array([0.0, 0.15, 1.0]))
			pm.scale_curve = _curve([Vector2(0, 0.4), Vector2(1, 1.5)])
			size = 0.9
			additive = false
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var mkey := &"mat_add" if additive else &"mat_mix"
	if _fx.has(mkey):   # B8: embers and sparks share one additive material (only the quad size differs)
		q.material = _fx[mkey]
		_fx[kind] = [pm, q]
		return _fx[kind]
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	sm.disable_fog = additive  # G-E 5: an additive quad must not fog
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.billboard_keep_scale = true
	sm.vertex_color_use_as_albedo = true
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	sm.albedo_texture = _soft_tex()
	q.material = sm
	_fx[mkey] = sm
	_fx[kind] = [pm, q]
	return _fx[kind]


func _particles(nm: String, kind: StringName, at: Vector3, amount: int, life: float, one_shot: bool) -> GPUParticles3D:
	var pair: Array = _fx_pair(kind)
	var p := GPUParticles3D.new()
	p.name = nm
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 0.92 if kind == &"sparks" else (0.7 if kind == &"steam" else 0.0)
	p.emitting = false
	p.process_material = pair[0]
	p.draw_pass_1 = pair[1]
	p.position = at
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2.5, -2.0, -2.5), Vector3(5.0, 5.5, 5.0))
	p.visibility_range_end = PARTICLE_RANGE
	add_child(p)
	return p


func _burst(p: GPUParticles3D, at: Vector3) -> void:
	if p == null:
		return
	p.position = at
	p.restart()
	p.emitting = true


# ================================================================ animation

func _process(delta: float) -> void:
	_apply(delta)
	if not _needs_process():
		set_process(false)


func _needs_process() -> bool:
	if _forge_t >= 0.0 or _ign_t >= 0.0:
		return true
	if _lit and _heat < 1.0:
		return true
	if not _lit and _heat > 0.0:
		return true
	var rest: float = MOULD_REST if _lit else 0.0
	return absf(_mould_heat - rest) > 0.01


## Smooth 0 -> 1 -> 0 bump: rises from a to b, falls from b to c.
static func _bump(t: float, a: float, b: float, c: float) -> float:
	if t <= a or t >= c:
		return 0.0
	if t < b:
		return smoothstep(a, b, t)
	return 1.0 - smoothstep(b, c, t)


func _apply(delta: float) -> void:
	# Heat ramps (ignite / cool).
	if _lit and _heat < 1.0:
		_heat = minf(1.0, _heat + delta / IGNITE_TIME)
	elif not _lit and _heat > 0.0:
		_heat = maxf(0.0, _heat - delta / COOL_TIME)
	var ign_flare := 0.0
	var bellows := BELLOWS_REST
	if _ign_t >= 0.0:
		_ign_t += delta
		ign_flare = 1.4 * _bump(_ign_t, 0.45, 0.9, IGNITE_TIME + 0.3)
		bellows = BELLOWS_REST + 0.35 * sin(_ign_t / 0.5 * TAU)
		if _ign_t >= IGNITE_TIME + 0.3:
			_ign_t = -1.0
	# Forge timeline.
	var tilt := 0.0
	var molten_flare := 0.0
	var coal_flare := 0.0
	var pool_flare := 0.0
	var pour_on := false
	if _forge_t >= 0.0:
		var f0: float = _forge_t
		_forge_t += delta
		var f: float = _forge_t
		if f < 0.35:
			tilt = sin(f / 0.35 * PI * 0.5)
		elif f < 1.15:
			tilt = 1.0
		elif f < 1.65:
			tilt = 1.0 - smoothstep(1.15, 1.65, f)
		if f < 0.9:
			bellows = BELLOWS_REST + 0.35 * sin(f / 0.45 * TAU)
			coal_flare = 0.9 * _bump(f, 0.0, 0.2, 0.9)
		molten_flare = 1.3 * _bump(f, 0.05, 0.35, 1.5)
		pool_flare = 1.1 * _bump(f, 0.3, 0.5, 1.6)
		pour_on = f >= 0.26 and f <= 1.2
		if f0 < FORGE_HIT and f >= FORGE_HIT:
			_burst(_sparks, _sprue())
			_mould_heat = 3.2
			forge_poured.emit(get_sprue_point() if is_inside_tree() else _sprue())
		if f0 < STEAM_AT and f >= STEAM_AT:
			_steam.restart()
			_steam.emitting = true
		if f >= FORGE_TIME:
			_forge_t = -1.0
		# The pour: a vertical white-hot stream from the spout to the sprue.
		if pour_on:
			var tip: Vector3 = Transform3D(Basis(Vector3.RIGHT, -deg_to_rad(TILT_DEG) * tilt), AXLE) * SPOUT
			var bottom_y: float = SPROUT_TOP
			var top_y: float = tip.y
			if f < 0.4:
				bottom_y = lerpf(tip.y, SPROUT_TOP, clampf((f - 0.26) / 0.14, 0.0, 1.0))
			if f > 1.05:
				top_y = lerpf(tip.y, SPROUT_TOP, clampf((f - 1.05) / 0.15, 0.0, 1.0))
			var len: float = maxf(top_y - bottom_y, 0.02)
			var w: float = 0.15 * (1.0 + 0.12 * sin(f * 41.0))
			_pour.transform = Transform3D(Basis.from_scale(Vector3(w, len, w)), Vector3(tip.x, (top_y + bottom_y) * 0.5, tip.z))
	_pour.visible = pour_on
	_pivot.rotation.x = -deg_to_rad(TILT_DEG) * tilt
	# Mould cools toward its rest glow (fast from the flash, slower after).
	var rest: float = MOULD_REST * _heat if _lit else 0.0
	if delta > 0.0:
		var k: float = 2.5 if _mould_heat < rest else (1.5 if _mould_heat > 1.0 else 1.0)
		_mould_heat = rest + (_mould_heat - rest) * exp(-k * delta)
	# Bellows: the board hinges, the leather stretches.
	_bellows = bellows if _heat > 0.0 or _forge_t >= 0.0 else BELLOWS_REST
	var open: float = clampf(_bellows, 0.15, 1.0)
	_bellows_leather.scale = Vector3(1.0, open, 1.0)
	_bellows_top.rotation.z = -atan2(BELLOWS_OPEN * open, BELLOWS_LEN)
	# Glows.
	var h: float = _heat
	_molten.visible = h > 0.04
	_crust.visible = h < 0.45
	_hot.visible = h > 0.04
	_mould.visible = _mould_heat > 0.03
	_pool.visible = h > 0.02
	_molten.set_instance_shader_parameter(&"glow_boost", h * (1.0 + ign_flare + molten_flare))
	_hot.set_instance_shader_parameter(&"glow_boost", h * (1.0 + 0.5 * ign_flare + coal_flare))
	_mould.set_instance_shader_parameter(&"glow_boost", _mould_heat)
	_pool.set_instance_shader_parameter(&"glow_boost", h * (1.0 + 0.6 * ign_flare + pool_flare))
	_pour.set_instance_shader_parameter(&"glow_boost", 1.2)
	var embers_on: bool = h > 0.6
	if _embers.emitting != embers_on:
		_embers.emitting = embers_on


func _update_ao() -> void:
	var y0: float = global_position.y if is_inside_tree() else position.y
	for gi: GeometryInstance3D in _painted:
		gi.set_instance_shader_parameter(&"ao_bottom", y0)
		gi.set_instance_shader_parameter(&"ao_height", AO_HEIGHT)
