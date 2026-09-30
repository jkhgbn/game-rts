class_name NatureHallModel
extends FireHallModel
## Visual model of Ysolde's barracks, the Grove Hall (kingdom-nature.md 4 + 7.1; epic pass A2.6 in the
## Heartwood's language, art/buildings/nature_keep*). Read from the RTS camera: a ruined mossy stone hall whose roof
## is a living hedge (lumpy team-coloured leaf clumps with dark baked gaps, a fringe of leaves over the eaves, two
## blossoms), held by a frame of living bark arches whose feet pour over the plinth as roots, sap glowing in their
## furrows. The keep's gate (voussoir arch, dark doorway, curtain of glowing vines, seed keystone) on a gatehouse
## under a glowing leaf-rose window, two banner standards with leaf banners. Dominant vertical: a braided young tree
## bursting out of a ruined corner tower at the back-right, its roots gripping the stones, a leafy crown, a
## seed-lantern and a Crown Bloom (the third blossom) on top. Asymmetric secondary: a leaning rune stone, a log pile
## and a side banner on the left. Moss patch with a fairy ring on the ground (nature/nature_ground.gdshader).
## Same hooks and state machine as FireHallModel (fire_hall.gd): set_team_color, set_construction_progress,
## set_health_ratio, play_training_pulse, play_destroyed (-> destroyed_finished after 3 s), set_selected.
## Footprint 3 x 3 cells (6 x 6 m), gate local -Z. Every tier is ONE mesh baked once per class (NatureKit, one
## surface per material). No active light (the base class light exists but stays hidden): emissive + bloom only.
## Ambient particles (pollen, leaves, petals) only run while a camera is within 45 m.

const HX := -0.3      ## hall axis x (the rune stone and logs sit on the left, the tree on the right)
const HZ := 0.25      ## hall body centre z
const WX := 2.0       ## hall body half-width
const WZ := 2.3       ## hall body half-depth
const EAVE := 3.35
const RIDGE := 5.55
const RH := 2.5       ## roof half-width at the eaves
const TOWER := Vector2(2.15, 2.2)   ## the ruined corner tower (x, z)
const TREE_POS := Vector3(2.15, 0.8, 2.2)
const STANDARDS: Array[Vector3] = [Vector3(-1.85, 0.45, -3.05), Vector3(1.25, 0.45, -3.05)]
const NEAR_ON := 45.0
const NEAR_OFF := 50.0
const KEY := "nature_hall/"
const BLOOM_POS := Vector3(0.0, 9.72, 0.1)   ## tree-local
const CLUMPS: Array[Vector4] = [Vector4(0.0, 8.65, 0.1, 1.6), Vector4(-1.15, 7.8, -0.85, 1.1),
	Vector4(0.95, 7.6, 0.85, 1.05)]            ## tree-local crown clumps (x, y, z, r)
const LANTERN_PIVOT := Vector3(-1.05, 7.25, -1.7)   ## tree-local, under the front clump
const BAYS: Array[float] = [-1.35, 0.15, 1.65]       ## hedge bays (z) between the arches and ribs
const RIBS: Array[float] = [-0.6, 0.9]

var _mats: Dictionary = {}
var _ground_mat: ShaderMaterial
var _frame: MeshInstance3D
var _tree: Node3D
var _bloom: Node3D
var _bloom_xf: Transform3D
var _lantern: Node3D
var _ambient: Array[GPUParticles3D] = []
var _ambient_on: bool = false
var _cam_check: float = 0.0
var _leaf_ramps: Array = []
var _glow_ramps: Array = []
var _agitated: bool = false


func _setup_palette() -> void:
	kingdom_color = NatureKit.TEAM
	glow_color = NatureKit.GLOW
	stone_color = Color(0.5, 0.47, 0.37)
	dark_color = Color(0.26, 0.24, 0.17)
	metal_color = Color(0.40, 0.28, 0.16)   # bark
	stripe_color = NatureKit.STRIPE
	glyph_color = NatureKit.GLOW
	smoke_color = Color(0.24, 0.22, 0.17)
	dust_color = Color(0.40, 0.36, 0.26)
	decal_color = Color(0.05, 0.05, 0.02)
	light_color = Color(0.75, 1.00, 0.45)
	light_energy = 1.2
	danger_ramp_hot = Color(0.72, 0.52, 0.16)
	danger_ramp_mid = Color(0.56, 0.38, 0.12)
	danger_ramp_end = Color(0.32, 0.2, 0.08)


## The Heartwood's materials (per instance) in the base class slots: stone, dark stone, bark (trim), leaves
## (team), leaf banner, seed-heart glow, gate runes.
func _make_materials() -> void:
	_mats = NatureKit.make_materials()
	mat_stone = _mats["Stone"]
	mat_dark = _mats["Dark"]
	mat_metal = _mats["Bark"]
	mat_team = _mats["Leaves"]
	mat_banner = _mats["Banner"]
	mat_glow = _mats["Heart"]
	mat_gate = _mats["Gate"]
	_painted = NatureKit.surface_materials(_mats)
	_glows = [_mats["Heart"], _mats["Gate"], _mats["Blossom"], _mats["Petal"]] as Array[ShaderMaterial]


func _light_wave(_n: float) -> float:
	return 1.0


## B8: the NatureKit painted / card materials drawn as one merged material each (NatureVC), the hall's particle
## quads / process materials shared and its rune glows merged (FireHallModel budget passes).
func _budget_wanted() -> bool:
	return true


func _post_build() -> void:
	NatureKit.NVC.convert(self, _mats)


## B8: the hall's particles use NatureKit's soft dots (the pollen's ADD dot, the leaves / petals atlas for MIX).
func _make_particle_quads() -> void:
	super()
	_add_quad = NatureKit.soft_quad(true)
	_mix_quad = NatureKit.soft_quad(false)


func _idle_motion(delta: float) -> void:
	var fast: float = 3.0 if _pulse_left > 0.0 else 1.0
	if _bloom:
		var br: float = sin(_t * 1.3)
		var s: float = 0.84 if _health_ratio < 0.25 and _progress >= 1.0 else 1.0
		_bloom.transform = Transform3D(Basis(Vector3.UP, _t * deg_to_rad(7.0) * fast).scaled(
			Vector3(1.0 + 0.04 * br, 1.0 - 0.035 * br, 1.0 + 0.04 * br) * s), _bloom_xf.origin)
	if _lantern:
		var amp: float = deg_to_rad(8.0) * (1.8 if _agitated else 1.0)
		var ph: float = _t * TAU / 3.0 * fast
		var jit: float = sin(_t * 17.0) * 0.03 if _agitated else 0.0
		_lantern.rotation = Vector3(sin(ph) * amp + jit, 0.0, cos(ph * 0.8) * amp * 0.6)
	_cam_check -= delta
	if _cam_check <= 0.0:
		_cam_check = 0.5
		var d: float = NatureKit.camera_distance(self, global_position + Vector3(0, 4, 0))
		_set_ambient(d < (NEAR_OFF if _ambient_on else NEAR_ON) and _progress >= 1.0)


func _set_ambient(on: bool) -> void:
	if on == _ambient_on:
		return
	_ambient_on = on
	for p: GPUParticles3D in _ambient:
		p.emitting = on


# ============================================================ structure

## Grove Hall parts (Body space, gate -Z). Heights: plinth 0.8, walls 3.35, hedge ridge ~6.4, tower 4.1, tree crown
## ~9.3, Crown Bloom ~10.3. Tiers: PlinthBase, Walls (+ gatehouse, windows, roof core, tower), Frame (living arches,
## roots, standards, logs), Hedge, HedgeLost, Tree (crown, Bloom, lantern), BannersGate, BannersSide.
func _build_structure() -> void:
	_top_y = 10.3
	_part_node("PlinthBase", "plinth", _mesh_plinth, _body, 0.0, 2.5)
	_part_node("Walls", "walls", _mesh_walls, _body, 0.8, 3.6)
	_frame = _part_node("Frame", "frame", _mesh_frame, _body, 0.0, 6.5)
	var hedge := _part_node("Hedge", "hedge", _mesh_hedge.bind(false), _body, 2.6, 4.2)
	var lost := _part_node("HedgeLost", "hedge_lost", _mesh_hedge.bind(true), _body, 2.6, 4.2)
	_hide_below_50.append(lost)
	# Dominant vertical: the tree bursting out of the corner tower (falls back on collapse).
	_tree = Node3D.new()
	_tree.name = "Tree"
	_tree.position = TREE_POS
	_body.add_child(_tree)
	_part_node("TreeCrown", "tree", _mesh_tree, _tree, 0.8, 9.0)
	var bloom := _part_node("Bloom", "bloom", _mesh_bloom, _tree, 0.0, 1.0, false)
	bloom.position = BLOOM_POS
	_bloom = bloom
	_bloom_xf = bloom.transform
	_lantern = Node3D.new()
	_lantern.name = "LanternPivot"
	_lantern.position = LANTERN_PIVOT
	_tree.add_child(_lantern)
	_part_node("Lantern", "lantern", _mesh_lantern, _lantern, 0.0, 1.0, false)
	_falling = _tree
	_fall_axis = Vector3.RIGHT
	_fall_deg = 40.0
	# Banners: two leaf banners on the gate standards, one on the left wall, one on the tower.
	var bg := _part_node("BannersGate", "banners_gate", _mesh_banners_gate, _body, 0.0, 1.0, false)
	var bs := _part_node("BannersSide", "banners_side", _mesh_banners_side, _body, 0.0, 1.0, false)
	_hide_below_25.append(bs)
	# The living frame stands until the 1.6 s dust burst, then the wreck (with the same roots) replaces it.
	_hide_on_collapse.append_array([hedge, lost, bg, bs, _frame])
	# No active light: the base class drives _light, so it exists but stays hidden.
	_light = _omni(Vector3(HX, 2.2, -3.6), 6.0)
	_light.visible = false
	_build_ambient()
	_build_scaffold_nature()
	_build_wreck_nature()
	# State anchors: smoke from the torn hedge and the tower, withering leaves pouring off the hedge and the crown.
	_smoke_points = [Vector3(1.0, 5.2, -1.0), TREE_POS + Vector3(-0.4, 6.4, 0.2)]
	_blaze_points = [Vector3(HX - 0.9, 5.6, 0.6), TREE_POS + Vector3(0.0, 7.6, 0.0)]
	_rubble2_points = [] as Array[Vector3]
	_gate_pos = Vector3(HX, 1.6, -2.95)


## The frame never sinks with the walls (its roots would lift off the ground): it stays upright until it is swapped
## for the wreck.
func _collect_parts() -> void:
	super()
	var fi: int = _parts.find(_frame)
	var ci: int = _collapse_idx.find(fi)
	if ci >= 0:
		_collapse_idx.remove_at(ci)


## One baked tier (NatureKit mesh, this building's materials) under `parent`, with the painted height gradient.
func _part_node(nm: String, key: String, build: Callable, parent: Node3D, ao_bottom: float, ao_height: float,
		shadow: bool = true) -> MeshInstance3D:
	var mi: MeshInstance3D = NatureKit.node(nm, KEY + key, build, _mats, parent, shadow)
	mi.set_instance_shader_parameter(&"ao_bottom", ao_bottom)
	mi.set_instance_shader_parameter(&"ao_height", ao_height)
	return mi


## Wall face offset of the battered hall body at height y (from the axis, added to WX / WZ).
static func _batter(y: float) -> float:
	return lerpf(0.08, -0.06, clampf((y - 1.2) / (EAVE - 1.2), 0.0, 1.0))


func _mesh_plinth(mb: NatureKit.MB) -> void:
	mb.loft("Dark", [NatureKit.chamfer(3.2, 0.95), NatureKit.chamfer(3.13, 0.93)], [0.0, 0.45])
	mb.loft("Dark", [NatureKit.chamfer(2.98, 0.85), NatureKit.chamfer(2.93, 0.83)], [0.45, 0.8])
	# Stairs down from the gate and their cheek stones.
	mb.box("Dark", Vector3(HX, 0.36, -3.24), Vector3(1.8, 0.72, 0.5))
	mb.box("Dark", Vector3(HX, 0.15, -3.62), Vector3(1.9, 0.3, 0.38))
	for sx: float in [-1.0, 1.0]:
		mb.box("Stone", Vector3(HX + sx * 1.02, 0.44, -3.3), Vector3(0.26, 0.88, 0.78), Basis(Vector3.RIGHT, deg_to_rad(-6.0)))
	# The leaning rune stone at the front-left (asymmetric secondary).
	NatureKit.menhir(mb, Vector3(-2.82, 0.76, -1.45), Vector3(-0.95, 0, -0.3).normalized(), 2.3, 0.34, 8.0)
	NatureKit.menhir(mb, Vector3(-2.72, 0.76, -0.75), Vector3(-1, 0, 0.2).normalized(), 1.1, 0.26, 14.0, false)


func _mesh_walls(mb: NatureKit.MB) -> void:
	var c := Vector2(HX, HZ)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2602
	# Base course, battered stone body, string course, cornice.
	mb.loft("Dark", [NatureKit.rect_ch(WX + 0.24, WZ + 0.24, 0.32, c), NatureKit.rect_ch(WX + 0.2, WZ + 0.2, 0.3, c)],
		[0.8, 1.2], true, false, c)
	mb.loft("Stone", [NatureKit.rect_ch(WX + 0.08, WZ + 0.08, 0.26, c), NatureKit.rect_ch(WX - 0.06, WZ - 0.06, 0.22, c)],
		[1.2, EAVE], false, false, c)
	var sc: Array = NatureKit.rect_ch(WX + 0.07, WZ + 0.07, 0.25, c)
	mb.loft("Dark", [sc, sc], [2.28, 2.44], false, false, c)
	mb.loft("Dark", [NatureKit.rect_ch(WX - 0.02, WZ - 0.02, 0.2, c), NatureKit.rect_ch(WX + 0.16, WZ + 0.16, 0.26, c)],
		[EAVE - 0.26, EAVE], true, false, c)
	# Corner buttresses (the back-right corner is the tower).
	for cc: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)]:
		var p := Vector3(HX + cc.x * (WX + 0.06), 0.0, HZ + cc.y * (WZ + 0.06))
		_block(mb, "Dark", p + Vector3(0, 0.8, 0), p + Vector3(-cc.x * 0.05, EAVE - 0.3, -cc.y * 0.05), 0.36, 0.24)
	# Stone gables with the leaf window (the mossy roof core under the hedge belongs to the Hedge tier).
	var z0: float = HZ - WZ - 0.04
	var z1: float = HZ + WZ + 0.04
	var ey: float = EAVE - 0.08
	for z: float in [z0, z1]:
		mb.tri_auto("Stone", Vector3(HX - RH, ey, z), Vector3(HX + RH, ey, z), Vector3(HX, RIDGE, z), Vector3(HX, EAVE + 0.5, HZ))
	# Leaf window on the front gable: a ring of voussoirs round a glowing pane crossed by dark leaf veins.
	var rc := Vector3(HX, 4.3, z0)
	for i: int in 10:
		var a0: float = TAU * float(i) / 10.0 + 0.03
		var a1: float = TAU * float(i + 1) / 10.0 - 0.03
		var p: Array[Vector3] = []
		for bit: int in 8:
			var a: float = a1 if (bit & 1) != 0 else a0
			var r: float = 0.66 if (bit & 2) != 0 else 0.44
			var z: float = z0 - 0.13 if (bit & 4) != 0 else z0 + 0.02
			p.append(Vector3(rc.x + cos(a) * r, rc.y + sin(a) * r, z))
		mb.hexa("Dark", p)
	var pane: Array[Vector3] = []
	for i: int in 12:
		pane.append(rc + Vector3(cos(TAU * i / 12.0) * 0.46, sin(TAU * i / 12.0) * 0.46, -0.03))
	mb.poly("Gate", pane, rc + Vector3(0, 0, 0.5))
	mb.box("Dark", rc + Vector3(0, 0, -0.06), Vector3(0.07, 0.9, 0.04))
	for yy: float in [-0.14, 0.12]:
		for sd: float in [-1.0, 1.0]:
			mb.box("Dark", rc + Vector3(sd * 0.15, yy + 0.08, -0.06), Vector3(0.05, 0.36, 0.04), Basis(Vector3.BACK, sd * -0.8))
	# Back gable: a small round glowing window.
	var bw := Vector3(HX, 4.3, z1)
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0
		mb.box("Dark", bw + Vector3(cos(a) * 0.38, sin(a) * 0.38, 0.05), Vector3(0.22, 0.16, 0.14), Basis(Vector3.BACK, a))
	var bh: Array[Vector3] = []
	for i: int in 10:
		bh.append(bw + Vector3(cos(TAU * i / 10.0) * 0.3, sin(TAU * i / 10.0) * 0.3, 0.04))
	mb.poly("Gate", bh, bw - Vector3(0, 0, 0.5))
	# Side windows: dark recess, glowing vine strip, stone sill and lintel (the right side stops at the tower).
	for w: Vector2 in [Vector2(-1, -0.85), Vector2(-1, 1.35), Vector2(1, -0.85), Vector2(1, 0.45)]:
		var s: float = w.x
		var x: float = HX + s * (WX + _batter(2.35))
		mb.box("Dark", Vector3(x + s * 0.02, 2.4, w.y), Vector3(0.12, 1.15, 0.72))
		mb.box("Black", Vector3(x + s * 0.07, 2.36, w.y), Vector3(0.05, 0.9, 0.44))
		mb.box("Gate", Vector3(x + s * 0.1, 2.3, w.y), Vector3(0.04, 0.72, 0.08))
		mb.box("Gate", Vector3(x + s * 0.1, 2.52, w.y), Vector3(0.04, 0.12, 0.26), Basis(Vector3.RIGHT, 0.6))
		mb.box("Stone", Vector3(x + s * 0.1, 1.76, w.y), Vector3(0.2, 0.12, 0.86))
		mb.box("Stone", Vector3(x + s * 0.08, 3.02, w.y), Vector3(0.18, 0.2, 0.84))
	# Gatehouse: squared portal pushed out of the -Z face, base course, cornice, pointed crest stone, pilasters.
	var gz: float = HZ - WZ
	mb.box("Dark", Vector3(HX, 0.97, gz - 0.3), Vector3(2.55, 0.34, 0.8))
	mb.box("Stone", Vector3(HX, 2.3, gz - 0.28), Vector3(2.3, 2.9, 0.64))
	mb.box("Dark", Vector3(HX, 3.86, gz - 0.3), Vector3(2.62, 0.22, 0.8))
	var crest: Array[Vector3] = [Vector3(HX - 0.5, 3.97, gz - 0.5), Vector3(HX + 0.5, 3.97, gz - 0.5),
		Vector3(HX + 0.5, 3.97, gz - 0.1), Vector3(HX - 0.5, 3.97, gz - 0.1)]
	for i: int in 4:
		mb.tri_auto("Stone", crest[i], crest[(i + 1) % 4], Vector3(HX, 4.62, gz - 0.3), Vector3(HX, 4.1, gz - 0.3))
	for sx: float in [-1.0, 1.0]:
		mb.box("Dark", Vector3(HX + sx * 1.08, 2.3, gz - 0.62), Vector3(0.22, 2.6, 0.12))
	# The keep's arch: jamb stones, nine voussoirs with a big keystone and a glowing seed gem on it.
	var zc: float = gz - 0.6
	var spring: float = 2.2
	var ar: float = 0.62
	for sx: float in [-1.0, 1.0]:
		for j: int in 3:
			var y0: float = 0.85 + float(j) * 0.44
			mb.box("Dark", Vector3(HX + sx * (ar + 0.15), y0 + 0.21, zc - 0.05), Vector3(0.32 + 0.06 * float(j % 2), 0.4, 0.14))
	for i: int in 9:
		var a0: float = PI * float(i) / 9.0 + 0.02
		var a1: float = PI * float(i + 1) / 9.0 - 0.02
		var r1: float = ar + 0.3 + (0.14 if i == 4 else 0.0)
		var p: Array[Vector3] = []
		for bit: int in 8:
			var a: float = a1 if (bit & 1) != 0 else a0
			var r: float = r1 if (bit & 2) != 0 else ar
			var z: float = zc - 0.14 if (bit & 4) != 0 else zc + 0.02
			p.append(Vector3(HX + cos(a) * r, spring + sin(a) * r, z))
		mb.hexa("Dark", p)
	var ks := Vector3(HX, spring + ar + 0.22, zc - 0.16)
	var gem: Array[Vector3] = [ks + Vector3(0, 0.13, 0), ks + Vector3(0.1, 0, 0), ks + Vector3(0, -0.13, 0), ks + Vector3(-0.1, 0, 0)]
	for i: int in 4:
		mb.tri_auto("Gate", gem[i], gem[(i + 1) % 4], ks + Vector3(0, 0, -0.07), ks + Vector3(0, 0, 0.1))
	var door: Array[Vector3] = [Vector3(HX - ar, 0.85, zc - 0.005), Vector3(HX + ar, 0.85, zc - 0.005)]
	for i: int in 11:
		var a: float = PI * float(i) / 10.0
		door.append(Vector3(HX + cos(a) * ar, spring + sin(a) * ar, zc - 0.005))
	mb.poly("Black", door, Vector3(HX, 2.0, zc + 1.0))
	# A curtain of glowing hanging vines inside the doorway (the training flash point).
	for i: int in 6:
		var x: float = -0.45 + 0.18 * float(i)
		var top: float = spring + sqrt(maxf(ar * ar - x * x, 0.0)) - 0.04
		var bottom: float = lerpf(1.25, 1.95, absf(sin(float(i) * 1.7)))
		mb.box("Gate", Vector3(HX + x, (top + bottom) * 0.5, zc - 0.03), Vector3(0.045, top - bottom, 0.04))
		mb.box("Gate", Vector3(HX + x + 0.03, bottom + 0.05, zc - 0.04), Vector3(0.1, 0.1, 0.05), Basis(Vector3.BACK, PI * 0.25))
	# The ruined corner tower (back-right): base course, stone drum, a band, broken merlons, a dark hollow top.
	var t := TOWER
	mb.loft("Dark", [NatureKit.ring_n(10, 1.07, 0.0, t), NatureKit.ring_n(10, 1.02, 0.0, t)], [0.8, 1.2], false, false, t)
	mb.loft("Stone", [NatureKit.ring_n(10, 0.96, 0.0, t), NatureKit.ring_n(10, 0.86, 0.0, t)], [1.2, 4.1], false, false, t)
	var band: Array = NatureKit.ring_n(10, 0.93, 0.0, t)
	mb.loft("Dark", [band, band], [3.55, 3.75], false, false, t)
	mb.annulus("Dark", NatureKit.ring_n(10, 0.86, 0.0, t), NatureKit.ring_n(10, 0.6, 0.0, t), 4.1)
	mb.poly("Black", _v3ring(NatureKit.ring_n(10, 0.6, 0.0, t), 3.95), Vector3(t.x, 3.0, t.y))
	for k: int in 10:
		if k in [2, 3, 7]:
			continue   # missing merlons (the tree burst through)
		var a: float = TAU * (float(k) + 0.5) / 10.0
		var d := Vector3(cos(a), 0.0, -sin(a))
		var h: float = rng.randf_range(0.28, 0.55)
		mb.box("Stone", Vector3(t.x, 4.1 + h * 0.5 - 0.03, t.y) + d * 0.78, Vector3(0.34, h, 0.26),
			Basis(Vector3.UP, a + PI * 0.5) * Basis(Vector3.FORWARD, rng.randf_range(-0.12, 0.12)))
	# Tower slit window (+X face) and the banner rod brackets.
	mb.box("Dark", Vector3(t.x + 0.9, 2.5, t.y - 0.3), Vector3(0.14, 0.8, 0.3))
	mb.box("Gate", Vector3(t.x + 0.96, 2.5, t.y - 0.3), Vector3(0.04, 0.6, 0.1))


## Square-section tapered block between a base and a top centre.
func _block(mb: NatureKit.MB, k: String, base: Vector3, top: Vector3, bw: float, tw: float) -> void:
	var p: Array[Vector3] = []
	for bit: int in 8:
		var sx: float = 1.0 if (bit & 1) != 0 else -1.0
		var sz: float = 1.0 if (bit & 4) != 0 else -1.0
		var up: bool = (bit & 2) != 0
		var w: float = tw if up else bw
		p.append((top if up else base) + Vector3(sx * w, 0, sz * w))
	mb.hexa(k, p)


static func _v3ring(ring: Array, y: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for q: Vector2 in ring:
		out.append(Vector3(q.x, y, q.y))
	return out


## The living frame: bark arches over both gables and a rib across the middle, their feet pouring over the plinth
## as roots; the tree's roots gripping the tower; the banner standards and rods; the log pile.
func _mesh_frame(mb: NatureKit.MB) -> void:
	var zf: float = HZ - WZ - 0.22
	var zb: float = HZ + WZ + 0.2
	var left: Array[Vector2] = [Vector2(-2.72, 0.85), Vector2(-2.68, 2.0), Vector2(-2.58, 3.2), Vector2(-2.22, 4.25),
		Vector2(-1.48, 5.2), Vector2(HX, 5.95)]
	var right: Array[Vector2] = [Vector2(0.88, 5.2), Vector2(1.62, 4.25), Vector2(1.98, 3.2), Vector2(2.08, 2.0),
		Vector2(2.14, 0.85)]
	var rad: Array[float] = [0.36, 0.31, 0.28, 0.25, 0.23, 0.21, 0.23, 0.25, 0.28, 0.31, 0.36]
	# Front arch (frames the gatehouse and the rose window).
	_arch(mb, left, right, rad, zf, 1.0)
	# Back arch: its right foot dives into the tower's crown.
	var right_b: Array[Vector2] = [Vector2(0.88, 5.2), Vector2(1.45, 4.55), Vector2(1.8, 4.2)]
	_arch(mb, left, right_b, rad.slice(0, 9) as Array[float], zb, 2.0)
	# Two ribs arching over the hedge between its bays (the nave of a living hall), their feet curling down the
	# cornice.
	for zr: float in RIBS:
		var rib: Array[Vector3] = []
		for q: Vector2 in [Vector2(-2.66, 2.55), Vector2(-2.68, 3.3), Vector2(-2.5, 4.35), Vector2(-1.8, 5.55),
				Vector2(-1.0, 6.25), Vector2(HX, 6.5), Vector2(0.4, 6.25), Vector2(1.2, 5.55), Vector2(1.9, 4.35),
				Vector2(2.08, 3.3), Vector2(2.06, 2.55)]:
			rib.append(Vector3(q.x, q.y, zr + 0.07 * sin(q.x * 2.0 + zr)))
		mb.tube("Bark", rib, [0.12, 0.2, 0.21, 0.19, 0.17, 0.16, 0.17, 0.19, 0.21, 0.2, 0.12] as Array[float], 7, 2.0,
			0.08, 4.0 + zr, false, false)
	_frame_ground(mb, 4.1)
	# Banner standards on the lower gate step (gnarled poles, crossbar, fronds, glowing bud).
	for k: int in STANDARDS.size():
		NatureKit.standard(mb, STANDARDS[k], 4.2, _standard_facing(k), -1.0 - float(k) if k == 0 else 1.0 + float(k))
	# Banner rods: left wall under the eave, tower +X face.
	var lx: float = HX - WX - 0.3
	mb.box("Wood", Vector3(lx, 3.1, 0.25), Vector3(0.09, 0.09, 1.2))
	for o: float in [-0.4, 0.4]:
		mb.box("Wood", Vector3(lx + 0.15, 3.1, 0.25 + o), Vector3(0.32, 0.12, 0.1))
	mb.box("Wood", Vector3(TOWER.x + 1.12, 3.5, TOWER.y - 0.05), Vector3(0.09, 0.09, 1.0))
	for o: float in [-0.35, 0.35]:
		mb.box("Wood", Vector3(TOWER.x + 1.0, 3.5, TOWER.y - 0.05 + o), Vector3(0.3, 0.12, 0.1))


## The frame's ground part (also in the wreck, which replaces the frame at the collapse): roots pouring out of the
## arch feet over the plinth into the ground, the tree's roots over the tower's crown (at `tower_top`) and down its
## flank, the log pile against the left wall.
func _frame_ground(mb: NatureKit.MB, tower_top: float) -> void:
	var zf: float = HZ - WZ - 0.22
	var zb: float = HZ + WZ + 0.2
	for f: Array in [[Vector3(-2.72, 1.05, zf), Vector3(-1, 0, -0.45)], [Vector3(-2.72, 1.05, zf), Vector3(-0.55, 0, -1)],
			[Vector3(2.14, 1.05, zf), Vector3(1, 0, -0.45)], [Vector3(2.14, 1.05, zf), Vector3(0.5, 0, -1)],
			[Vector3(-2.72, 1.05, zb), Vector3(-1, 0, 0.4)], [Vector3(-2.72, 1.05, zb), Vector3(-0.4, 0, 1)]]:
		var a: Vector3 = f[0]
		var d: Vector3 = (f[1] as Vector3).normalized()
		NatureKit.root(mb, a, a + d * 0.45 + Vector3(0, 0.05, 0), a + d * 1.15 + Vector3(0, -1.3, 0), 0.26, 0.1,
			a.x * 3.0 + d.z)
	var t3 := Vector3(TOWER.x, 0.0, TOWER.y)
	var i: int = 0
	for deg: float in [45.0, 118.0, 160.0, 205.0, 250.0]:
		var d: Vector3 = NatureKit.dir_deg(deg)
		var a: Vector3 = t3 + d * 0.42 + Vector3(0, tower_top - 0.05, 0)
		var over: Vector3 = t3 + d * 1.25 + Vector3(0, tower_top + 0.2, 0)
		var b: Vector3 = t3 + d * (1.35 if deg == 250.0 else 1.6) + Vector3(0, -0.4, 0)
		NatureKit.root(mb, a, over, b, 0.24 - 0.02 * float(i % 2), 0.08, float(i) * 1.9)
		i += 1
	# Log pile against the left wall (bark logs, pale cut ends).
	for l: Vector3 in [Vector3(-2.66, 1.04, 0.0), Vector3(-3.04, 1.04, 0.0), Vector3(-2.85, 1.44, 0.0)]:
		var a := Vector3(l.x, l.y, 0.85)
		var b := Vector3(l.x, l.y, 2.15)
		mb.tube("Bark", [a, a.lerp(b, 0.5) + Vector3(0, 0.02, 0), b] as Array[Vector3], [0.22, 0.23, 0.22] as Array[float],
			8, 2.0, 0.05, l.x, false, false)
		for e: Array in [[a, Vector3.BACK], [b, Vector3.FORWARD]]:
			var p: Vector3 = e[0]
			var dz: Vector3 = e[1]
			mb.tube("Wood", [p + dz * 0.02, p - dz * 0.01] as Array[Vector3], [0.2, 0.2] as Array[float], 8, 1.0, 0.0,
				0.0, true, true)


## Which way gate standard i's banner faces (out of the gate, turned 40 deg outward).
static func _standard_facing(i: int) -> Vector3:
	var sgn: float = signf(STANDARDS[i].x - HX)
	return Vector3(sin(deg_to_rad(40.0)) * sgn, 0, -cos(deg_to_rad(40.0)))


## A bark arch at depth z through the (x, y) points of `left` then `right`, radii `rad`, with a little wobble.
func _arch(mb: NatureKit.MB, left: Array[Vector2], right: Array[Vector2], rad: Array[float], z: float, seed: float) -> void:
	var pts: Array[Vector3] = []
	for q: Vector2 in left + right:
		pts.append(Vector3(q.x, q.y, z + 0.07 * sin(q.x * 2.3 + seed)))
	mb.tube("Bark", pts, rad, 8, 2.0, 0.09, seed, true, true)


## The living hedge (team leaves): clumps along the ridge and both slopes, baked gaps where they meet, a fringe of
## leaf cards over the eaves, blossoms on top, two small flowers. `lost` = the front-right clump only (it falls
## off below 50 % HP); the main hedge is everything else.
func _mesh_hedge(mb: NatureKit.MB, lost: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2603
	var blobs: Array = []
	# Three bays between the arches and the ribs; per bay a ridge clump and a clump on each slope (overhanging the
	# eaves), each a little different so the hedge never reads as a stamp.
	for zb: float in BAYS:
		blobs.append(NatureKit.make_blob(rng, Vector3(HX + rng.randf_range(-0.12, 0.12), RIDGE - 0.1 + rng.randf_range(-0.08,
			0.12), zb + rng.randf_range(-0.08, 0.08)), rng.randf_range(0.95, 1.08), Vector3(1.3, 1.0, 0.8), 0.76,
			Vector3.UP, 13))
		for s: float in [-1.0, 1.0]:
			blobs.append(NatureKit.make_blob(rng, Vector3(HX + s * rng.randf_range(1.5, 1.65), EAVE + 0.9 + rng.randf_range(-0.08,
				0.1), zb + rng.randf_range(-0.1, 0.1)), rng.randf_range(0.9, 1.02), Vector3(1.0, 1.0, 0.84), 0.7,
				Vector3(s, 0.5, 0).normalized(), 13))
	var lost_idx: int = 2   # front bay, right slope
	if not lost:
		# The roof core: a mossy earth ridge under the clumps (seen in the gaps and where a clump was torn off).
		var z0: float = HZ - WZ - 0.04
		var z1: float = HZ + WZ + 0.04
		var ey: float = EAVE - 0.08
		for s: float in [-1.0, 1.0]:
			mb.quad("Moss", Vector3(HX + s * RH, ey, z0), Vector3(HX + s * RH, ey, z1), Vector3(HX, RIDGE, z1),
				Vector3(HX, RIDGE, z0), Vector2(z0, 0), Vector2(z1, 0), Vector2(z1, 3), Vector2(z0, 3), Vector3(HX, EAVE, HZ))
		mb.quad("Moss", Vector3(HX - RH, ey, z0), Vector3(HX + RH, ey, z0), Vector3(HX + RH, ey, z1), Vector3(HX - RH, ey, z1),
			Vector2(HX - RH, z0), Vector2(HX + RH, z0), Vector2(HX + RH, z1), Vector2(HX - RH, z1), Vector3(HX, EAVE + 1.0, HZ))
	for i: int in blobs.size():
		if (i == lost_idx) != lost:
			continue
		var b: NatureKit.Blob = blobs[i]
		NatureKit.blob_mesh(mb, b, 2, float(i) / 10.0, blobs)
		var ridge: bool = i % 3 == 0
		NatureKit.clump_cards(mb, b, rng, 6 if ridge else 12, 2 if ridge else 1, blobs, 0.8,
			-0.5 if not ridge else 0.1, 0.25 if not ridge else 0.6)
	if lost:
		return
	# Two small flowers nestled in the hedge (front-left slope, back of the ridge); the third is the Crown Bloom.
	NatureKit.flower(mb, Vector3(HX - 1.45, 5.0, BAYS[0]), Basis(Vector3.BACK, deg_to_rad(28.0)) * Basis(Vector3.RIGHT,
		deg_to_rad(-12.0)), 0.5, 7, rng)
	NatureKit.flower(mb, Vector3(HX + 0.15, 6.15, BAYS[2]), Basis(Vector3.RIGHT, deg_to_rad(-18.0)), 0.44, 6, rng)


## The tree (tree-local, origin at TREE_POS): three braided bark strands and a core rising out of the tower, limbs
## into three crown clumps (baked gaps, leaf fringe, blossoms), bare twigs, the lantern's branch.
func _mesh_tree(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2604
	var top := Vector3(0, 7.3, 0)
	for k: int in 3:
		var phase: float = deg_to_rad(120.0 * float(k) + 20.0)
		var pts: Array[Vector3] = []
		var rad: Array[float] = []
		for i: int in 11:
			var t: float = float(i) / 10.0
			var y: float = lerpf(0.2, top.y, t)
			var a: float = phase + deg_to_rad(150.0) * t
			var flare: float = 0.2 * (1.0 - smoothstep(0.0, 0.3, t))
			var off: float = lerpf(0.46, 0.17, pow(t, 0.8)) + flare + 0.04 * sin(t * 7.0 + float(k))
			pts.append(Vector3(sin(a) * off, y, -cos(a) * off))
			rad.append(lerpf(0.36, 0.2, t) + flare * 0.6)
		# The strand leaves the trunk top as a limb into its clump.
		var cl: Vector4 = CLUMPS[k]
		var target := Vector3(cl.x, cl.y - cl.w * 0.25, cl.z)
		var last: Vector3 = pts[pts.size() - 1]
		pts.append(last.lerp(target, 0.45) + Vector3(0, 0.35, 0))
		rad.append(0.17)
		pts.append(target)
		rad.append(0.11)
		mb.tube("Bark", pts, rad, 8, 2.0, 0.08, float(k) * 1.7, false, true)
	mb.tube("Bark", [Vector3(0, 0.2, 0), Vector3(0.03, 3.0, 0.0), Vector3(0.0, top.y + 0.3, 0.03)] as Array[Vector3],
		[0.5, 0.4, 0.26] as Array[float], 10, 2.0, 0.06, 0.4, false, true)
	# Bare twigs poking out of the crown (silhouette), and the lantern's branch.
	for i: int in 5:
		var d: Vector3 = NatureKit.dir_deg(40.0 + 72.0 * float(i) + rng.randf_range(-12.0, 12.0))
		var s: Vector3 = d * 0.8 + Vector3(0, 8.6 + rng.randf_range(0.0, 0.5), 0)
		var e: Vector3 = d * rng.randf_range(2.2, 2.7) + Vector3(0, 9.5 + rng.randf_range(0.0, 0.7), 0)
		mb.tube("Bark", [s, s.lerp(e, 0.5) + Vector3(0, 0.2, 0), e] as Array[Vector3], [0.08, 0.05, 0.015] as Array[float], 5, 1.0)
	var pivot := LANTERN_PIVOT
	mb.tube("Bark", [top + Vector3(-0.1, -0.5, -0.1), top.lerp(pivot, 0.6) + Vector3(0, 0.15, 0), pivot + Vector3(0, 0.06, 0)] as Array[Vector3],
		[0.13, 0.09, 0.06] as Array[float], 6, 1.0, 0.05, 2.0)
	# Crown clumps.
	var blobs: Array = []
	for k: int in CLUMPS.size():
		var cl: Vector4 = CLUMPS[k]
		var out := Vector3(cl.x, 0.0, cl.z)
		out = out.normalized() if out.length() > 0.1 else Vector3.ZERO
		blobs.append(NatureKit.make_blob(rng, Vector3(cl.x, cl.y, cl.z), cl.w, Vector3.ONE, 0.76, out, 12, k == 0))
	for k: int in blobs.size():
		var b: NatureKit.Blob = blobs[k]
		NatureKit.blob_mesh(mb, b, 2, 0.6 + float(k) / 10.0, blobs)
		NatureKit.clump_cards(mb, b, rng, int(8.0 + b.r * 7.0), 2 if k > 0 else 3, blobs, 0.85)
	# Hanging moss beards under the side clumps.
	for k: int in [1, 2]:
		var cl: Vector4 = CLUMPS[k]
		for j: int in 2:
			var d: Vector3 = NatureKit.dir_deg(rng.randf_range(0.0, 360.0))
			var p: Vector3 = Vector3(cl.x, cl.y, cl.z) + d * cl.w * 0.5 - Vector3(0, cl.w * 0.4, 0)
			var l: float = rng.randf_range(0.9, 1.4)
			mb.tube("Bark", [p, p + d * 0.1 - Vector3(0, l * 0.5, 0), p - d * 0.05 - Vector3(0, l, 0)] as Array[Vector3],
				[0.07, 0.05, 0.012] as Array[float], 5, 1.0, 0.15, float(j))


## The seed-lantern hanging under the front clump (its pivot swings).
func _mesh_lantern(mb: NatureKit.MB) -> void:
	NatureKit.lantern(mb, 0.9, Vector3(0.08, 0, 0.05), 0.9)


## The Crown Bloom (the hall's third blossom), built at the origin (its node turns and breathes).
func _mesh_bloom(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2605
	NatureKit.flower(mb, Vector3.ZERO, Basis.IDENTITY, 0.72, 8, rng, 7, true)


func _mesh_banners_gate(mb: NatureKit.MB) -> void:
	for k: int in STANDARDS.size():
		var face: Vector3 = _standard_facing(k)
		var bar: Vector3 = STANDARDS[k] + Vector3(0, 4.2 - 0.5, 0) + face * 0.1
		mb.banner(bar + Vector3(0, -0.06, 0) + face * 0.08, face, 0.95, 2.35, 1.9 * float(k))


func _mesh_banners_side(mb: NatureKit.MB) -> void:
	mb.banner(Vector3(HX - WX - 0.37, 3.04, 0.25), Vector3.LEFT, 1.0, 1.55, 0.7)
	mb.banner(Vector3(TOWER.x + 1.2, 3.44, TOWER.y - 0.05), Vector3.RIGHT, 0.85, 1.6, 2.6)


# ============================================================ ground, scaffold, wreck

## Moss patch with roots, petals and a fairy ring (instead of the plain contact decal), ground dressing (mossy
## boulders, fern tufts, glowing mushrooms) instead of the dark rubble cubes.
func _build_ground() -> void:
	super()
	_rubble.visible = false
	var decal := get_node(^"ContactDecal") as MeshInstance3D
	var pm := PlaneMesh.new()
	pm.size = Vector2(10.5, 10.5)
	decal.mesh = pm
	_ground_mat = NatureKit.ground_material(10.5, 3.2, 5.45, 0.0, 4.35, 26.0, 0.0)
	decal.material_override = _ground_mat
	var mi: MeshInstance3D = NatureKit.node("GroundDressing", KEY + "dressing", _mesh_dressing, _mats, self, false)
	mi.set_instance_shader_parameter(&"ao_bottom", -0.3)
	mi.set_instance_shader_parameter(&"ao_height", 1.5)


func _mesh_dressing(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2606
	# Flagstones leading out of the gate.
	for i: int in 2:
		mb.box("Dark", Vector3(HX + rng.randf_range(-0.3, 0.3), 0.03, -4.1 - 0.7 * i), Vector3(rng.randf_range(0.8, 1.0),
			0.08, rng.randf_range(0.5, 0.6)), Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)))
	NatureKit.dressing(mb, rng, 7, 5, 4, 3.45, 4.4, _dress_blocked)


## Keep the gate path clear of ground dressing.
static func _dress_blocked(p: Vector3) -> bool:
	return p.z < -2.8 and absf(p.x - HX) < 2.2


## Construction site: wooden poles, two woven decks, braces, a heap of cut stone and a pile of saplings waiting to be
## grown in. Child of the root, visible while 0 < progress < 1.
func _build_scaffold_nature() -> void:
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	add_child(_scaffold)
	var mi: MeshInstance3D = NatureKit.node("ScaffoldParts", KEY + "scaffold", _mesh_scaffold, _mats, _scaffold)
	mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
	mi.set_instance_shader_parameter(&"ao_height", 5.0)
	_scaffold.visible = false


func _mesh_scaffold(mb: NatureKit.MB) -> void:
	var hx: float = WX + 0.45
	var hz: float = WZ + 0.45
	var top: float = 4.4
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var b := Vector3(HX + c.x * hx, 0.0, HZ + c.y * hz)
		mb.tube("Wood", [b, b + Vector3(0.03 * c.x, top * 0.5, 0), b + Vector3(0, top + 0.5, 0)] as Array[Vector3],
			[0.09, 0.085, 0.07] as Array[float], 6, 1.0, 0.1, c.x + c.y)
	for y: float in [top * 0.5, top]:
		for s: float in [-1.0, 1.0]:
			mb.box("Wood", Vector3(HX, y, HZ + s * hz), Vector3(hx * 2.0 + 0.3, 0.08, 0.5), Basis(Vector3.BACK, s * 0.03))
			mb.box("Wood", Vector3(HX + s * hx, y, HZ), Vector3(0.5, 0.08, hz * 2.0 + 0.3), Basis(Vector3.RIGHT, s * 0.03))
	var ang: float = atan2(top - 0.5, hz * 2.0)
	for s: float in [-1.0, 1.0]:
		mb.box("Wood", Vector3(HX + s * (hx + 0.1), (top + 0.5) * 0.5, HZ), Vector3(0.08, 0.08,
			sqrt(4.0 * hz * hz + (top - 0.5) * (top - 0.5))), Basis(Vector3.RIGHT, -ang * s))
	for p: Vector3 in [Vector3(-3.55, 0.3, -3.5), Vector3(-2.95, 0.3, -3.75), Vector3(-3.25, 0.86, -3.6)]:
		mb.box("Stone", p, Vector3(0.6, 0.56, 0.6), Basis(Vector3.UP, p.x))
	for i: int in 3:
		var a := Vector3(2.4 + 0.25 * i, 0.12 + 0.18 * float(i % 2), -3.3)
		mb.tube("Bark", [a, a + Vector3(0.1, 0.02, -1.4)] as Array[Vector3], [0.1, 0.07] as Array[float], 6, 1.0)


## Collapse leftovers (shown at 1.6 s): broken wall teeth on the squashed stubs, the tree's shattered stump in the
## tower, fallen withered hedge clumps, splintered arch pieces, sap embers.
func _build_wreck_nature() -> void:
	_wreck = Node3D.new()
	_wreck.name = "Wreck"
	add_child(_wreck)
	var mi: MeshInstance3D = NatureKit.node("WreckParts", KEY + "wreck", _mesh_wreck, _mats, _wreck)
	mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
	mi.set_instance_shader_parameter(&"ao_height", 3.0)
	_wreck.visible = false


func _mesh_wreck(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2607
	var stub: float = PLINTH_TOP + (EAVE - PLINTH_TOP) * 0.3
	for i: int in 8:
		var along: float = rng.randf_range(-0.85, 0.85)
		var p := Vector3(HX + along * (WX - 0.2), 0.0, HZ + (1.0 if i % 2 == 0 else -1.0) * (WZ - 0.2))
		if i % 4 >= 2:
			p = Vector3(HX + (1.0 if i % 2 == 0 else -1.0) * (WX - 0.2), 0.0, HZ + along * (WZ - 0.2))
		var s := Vector3(rng.randf_range(0.6, 1.0), rng.randf_range(0.5, 1.1), rng.randf_range(0.5, 0.7))
		p.y = stub + s.y * 0.5 - 0.15
		mb.box("Stone", p, s, Basis.from_euler(Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(-0.3, 0.3),
			rng.randf_range(-0.2, 0.2))))
	# The shattered stump of the tree in the tower (the tower sinks to its stub, the stump stands in it).
	var t := Vector3(TOWER.x, PLINTH_TOP, TOWER.y)
	mb.loft("Wood", [NatureKit.ring_n(9, 0.62, 0.0, Vector2(t.x, t.z)), NatureKit.ring_n(9, 0.56, 0.0, Vector2(t.x, t.z))],
		[t.y + 1.5, t.y + 1.62], true, false, Vector2(t.x, t.z))
	mb.tube("Bark", [t, t + Vector3(0, 1.6, 0)] as Array[Vector3], [0.66, 0.6] as Array[float], 9, 2.0, 0.08, 1.0, false, false)
	for i: int in 7:
		var a: float = TAU * float(i) / 7.0 + rng.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var b: Vector3 = t + d * rng.randf_range(0.35, 0.58) + Vector3(0, 1.5, 0)
		var h: float = rng.randf_range(0.4, 1.3)
		mb.tube("Bark", [b, b + d * 0.08 + Vector3(0, h * 0.6, 0), b + d * 0.14 + Vector3(0, h, 0)] as Array[Vector3],
			[rng.randf_range(0.14, 0.22), 0.1, 0.0] as Array[float], 5, 1.0, 0.0, 0.0, false, false)
	# Fallen hedge clumps (they wither brown with the wreck) and splintered arch pieces.
	var blobs: Array = []
	for p: Vector3 in [Vector3(HX - 1.2, stub + 0.2, -0.9), Vector3(HX + 0.6, stub + 0.25, 0.9),
			Vector3(HX - 0.8, stub + 0.15, 1.6), Vector3(-3.6, 0.2, 1.2)]:
		var b := NatureKit.make_blob(rng, p, rng.randf_range(0.7, 1.0), Vector3(1.2, 1.0, 1.1), 0.55, Vector3.UP, 6)
		blobs.append(b)
	for b: NatureKit.Blob in blobs:
		NatureKit.blob_mesh(mb, b, 1, 0.9, blobs)
	for i: int in 3:
		var s := Vector3(rng.randf_range(-2.5, 1.5), stub + 0.1, rng.randf_range(-2.0, 2.5))
		var e: Vector3 = s + Vector3(rng.randf_range(-2.0, 2.0), 0.15, rng.randf_range(-1.5, 1.5))
		mb.tube("Bark", [s, s.lerp(e, 0.5) + Vector3(0, 0.12, 0), e] as Array[Vector3], [0.24, 0.2, 0.12] as Array[float],
			7, 2.0, 0.08, float(i), true, true)
	for i: int in 5:
		var p := Vector3(HX + rng.randf_range(-1.6, 1.6), stub + 0.06, HZ + rng.randf_range(-1.8, 1.8))
		mb.box("Gate", p, Vector3.ONE * 0.24, Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, 0.3))
	# The frame's roots stay (over the sunken tower stub), the arches' legs stand as splintered stumps.
	_frame_ground(mb, PLINTH_TOP + (4.1 - PLINTH_TOP) * 0.3)
	for leg: Vector3 in [Vector3(-2.72, 0.85, HZ - WZ - 0.22), Vector3(2.14, 0.85, HZ - WZ - 0.22),
			Vector3(-2.72, 0.85, HZ + WZ + 0.2)]:
		var h: float = rng.randf_range(0.9, 1.5)
		mb.tube("Bark", [leg, leg + Vector3(0.02, h * 0.6, 0), leg + Vector3(0.04, h, 0)] as Array[Vector3],
			[0.36, 0.32, 0.3] as Array[float], 8, 2.0, 0.09, leg.x, false, false)
		mb.loft("Wood", [NatureKit.ring_n(8, 0.3, 0.0, Vector2(leg.x + 0.04, leg.z)), NatureKit.ring_n(8, 0.26, 0.0,
			Vector2(leg.x + 0.04, leg.z))], [leg.y + h - 0.02, leg.y + h + 0.06], true, false, Vector2(leg.x + 0.04, leg.z))
		for k: int in 4:
			var a: float = TAU * float(k) / 4.0 + rng.randf()
			var d := Vector3(cos(a), 0, sin(a))
			var b: Vector3 = leg + Vector3(0.04, h, 0) + d * 0.2
			mb.tube("Bark", [b, b + d * 0.05 + Vector3(0, rng.randf_range(0.2, 0.5), 0)] as Array[Vector3],
				[0.1, 0.0] as Array[float], 4, 1.0, 0.0, 0.0, false, false)


# ============================================================ particles and states

## Ambient life (only near the camera): pollen from the Crown Bloom, leaves drifting off the hedge, petals.
func _build_ambient() -> void:
	var glow_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.15, 0.7, 1.0], [Color(glow_color, 0.0),
		Color(glow_color, 1.0), Color(glow_color, 0.8), Color(glow_color, 0.0)], _glow_ramps)
	var po := _pm(Vector3.UP, 60.0, 0.1, 0.35, Vector3(0, 0.08, 0), 0.09, 0.04, glow_ramp)
	po.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	po.emission_sphere_radius = 1.3
	po.color = NatureKit.MOTE_DIM
	po.turbulence_enabled = true
	po.turbulence_noise_strength = 0.3
	_ambient.append(_particles("Pollen", _tree, BLOOM_POS + Vector3(0, 0.2, 0), 14, 3.5, po, NatureKit.soft_quad(true), false))
	var t := kingdom_color
	var leaf_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.08, 0.8, 1.0], [Color(t, 0.0), Color(t, 1.0),
		Color(t.darkened(0.2), 1.0), Color(t.darkened(0.3), 0.0)], _leaf_ramps)
	var lv := _pm(Vector3.DOWN, 20.0, 0.4, 0.9, Vector3(0.3, -0.3, 0.1), 0.3, 0.26, leaf_ramp)
	lv.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	lv.emission_box_extents = Vector3(2.6, 0.4, 2.4)
	lv.angle_min = 0.0
	lv.angle_max = 360.0
	lv.angular_velocity_min = -120.0
	lv.angular_velocity_max = 120.0
	lv.turbulence_enabled = true
	lv.turbulence_noise_strength = 0.6
	lv.turbulence_noise_scale = 2.0
	_ambient.append(_particles("Leaves", _body, Vector3(HX, 5.4, HZ), 8, 5.5, lv, NatureKit.shape_quad(0), false))
	var petal_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.1, 0.8, 1.0], [Color(0.95, 0.55, 0.72, 0.0),
		Color(0.95, 0.55, 0.72, 1.0), Color(0.9, 0.5, 0.68, 1.0), Color(0.9, 0.5, 0.68, 0.0)])
	var pe := _pm(Vector3(0.3, 1.0, -0.2), 60.0, 0.3, 0.7, Vector3(0.3, -0.35, -0.1), 0.13, 0.12, petal_ramp)
	pe.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pe.emission_sphere_radius = 0.7
	pe.angle_min = 0.0
	pe.angle_max = 360.0
	pe.angular_velocity_min = -160.0
	pe.angular_velocity_max = 160.0
	pe.turbulence_enabled = true
	pe.turbulence_noise_strength = 0.5
	_ambient.append(_particles("Petals", _tree, BLOOM_POS + Vector3(0, 0.4, 0), 6, 5.5, pe, NatureKit.shape_quad(1), false))


## Base state nodes, then the Nature looks: the "blaze" plumes become withering leaves pouring down (like the
## Heartwood's Wither particles), and the lost-corner cubes are replaced by a torn-off clump on the ground.
func _build_state_nodes() -> void:
	super()
	for b: GPUParticles3D in _blaze:
		NatureKit.make_withering(b, 1.2, 16)
	_rubble2.multimesh.instance_count = 0
	var fallen: MeshInstance3D = NatureKit.node("FallenClump", KEY + "fallen", _mesh_fallen, _mats, _body)
	fallen.set_instance_shader_parameter(&"ao_bottom", -0.2)
	fallen.set_instance_shader_parameter(&"ao_height", 2.0)
	fallen.visible = false
	_show_below_50.append(fallen)


## Below 50 % HP: the torn-off front-right hedge clump lies on the ground by the right wall, with bark splinters.
func _mesh_fallen(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2608
	var b := NatureKit.make_blob(rng, Vector3(2.75, 0.55, -1.1), 0.85, Vector3(1.0, 1.0, 1.2), 0.6, Vector3.UP, 8)
	NatureKit.blob_mesh(mb, b, 2, 0.95, [b])
	NatureKit.clump_cards(mb, b, rng, 7, 0, [b], 0.7)
	for i: int in 4:
		var p := Vector3(rng.randf_range(2.2, 3.4), 0.86, rng.randf_range(-2.3, 0.2))
		mb.box("Bark", p, Vector3(0.44, 0.13, 0.17), Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, 0.2))


func _apply_health() -> void:
	super()
	var built: bool = _progress >= 1.0
	var hurt: bool = built and _health_ratio < 0.5
	var dying: bool = built and _health_ratio < 0.25
	NatureKit.apply_health(_mats, _health_ratio, hurt, dying)
	_agitated = dying
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"damage", 1.0 if dying else (0.5 if hurt else 0.0))


func set_construction_progress(p: float) -> void:
	super(p)
	if _ready_done and not _destroyed and _progress <= 0.0:
		for part: Node3D in _parts:
			part.visible = false   # at 0 only the glowing outline shows (art-keep.md 8.2)
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"build", _progress)
	if _ready_done and _progress < 1.0:
		_set_ambient(false)
	elif _ready_done:
		_cam_check = 0.0


func play_destroyed() -> void:
	super()
	if _ready_done:
		_set_ambient(false)


## Team colour: the base class recolours the leaves, banners and sparks; the kit does the cards, sap and glows.
func set_team_color(c: Color) -> void:
	super(c)
	if not _ready_done:
		return
	NatureKit.apply_team(_mats, c)
	var glow: Color = NatureKit.glow_of(c)
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"glow_color", glow)
	for g: Gradient in _glow_ramps:
		for i: int in g.get_point_count():
			g.set_color(i, Color(glow, g.get_color(i).a))
	for g: Gradient in _leaf_ramps:
		for i: int in g.get_point_count():
			g.set_color(i, Color(c.darkened(0.25 * g.get_offset(i)), g.get_color(i).a))


## The Heartwood's green idle rim instead of the base one (selection still turns it to the team colour).
func _apply_rim_and_glow() -> void:
	if not _ready_done:
		return
	NatureKit.apply_rim(_mats, _team_color, _sel_k, _progress < 1.0 and not _destroyed)
	NatureKit.apply_boost(_mats, _sel_boost())


## Collapse: the base sequence, then the moss withers, the sap drains and the leaves brown.
func _process_destroyed(delta: float) -> void:
	super(delta)
	var k: float = clampf((_destroy_t - 2.0) / 1.0, 0.0, 1.0)
	if _destroy_t >= 0.6:
		NatureKit.apply_wreck(_mats, k)
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"scorch", k)
