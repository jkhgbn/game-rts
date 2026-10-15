class_name IceHallModel
extends FireHallModel
## Visual model of Torvald's barracks, the Frost Hall (task 7.V2, epic pass A2.4; kingdom-ice.md 8.1): a frozen
## fortress hall in the Rime Keep's language. A battered ice-stone hall under a gable roof of glazed team-coloured ice
## tiles (snow ridge, snow drifts, icicle fringes), a crenellated gatehouse in front with the keep's tombstone gate
## (silver frame, black void, glowing slit and keystone) flanked by two square turrets with crystal caps and team
## banners. Dominant vertical: the ridge crystal (faceted team crystal, a glowing core in the gap, a floating tip
## and three orbiting shards, like the keep's crown). Asymmetric secondary: a frost brazier and a stack of cut ice
## blocks on the right, a rack of ice glaives and round ice shields on the left. Frost patch on the ground with
## ice spikes erupting around the plinth.
## Same hooks and state machine as FireHallModel (fire_hall.gd): set_team_color, set_construction_progress,
## set_health_ratio, play_training_pulse, play_destroyed (-> destroyed_finished after 3 s), set_selected.
## Footprint 3 x 3 cells (6 x 6 m), gate local -Z. Tiers are merged meshes (BuildingMerge). No active light (the
## base class light exists but stays hidden): the glow comes from emissive parts and bloom.

const HX := -0.25   ## hall axis x (the brazier / ice store sits on the right)
const HZ := 0.45    ## hall body centre z (the gatehouse stands in front of it)
const WX := 2.3     ## hall body half-width
const WZ := 2.0     ## hall body half-depth
const R_Z := 0.65   ## roof axis z
const R_HALF := 2.95
const R_EAVE := 3.72
const R_RISE := 2.35
const R_DEPTH := 4.8
const GATE_Z := -2.1   ## gatehouse centre z (front face at -2.82)
const TUR_X := 2.05    ## turrets at HX +- TUR_X
const TUR_Z := -2.2
const CRYSTAL_POS := Vector3(HX, 5.55, 1.35)
const FROST_GROUND: Shader = preload("res://art/buildings/ice/ice_frost_ground.gdshader")

var mat_snow: ShaderMaterial
var mat_roof: ShaderMaterial   ## glazed roof tiles: the team colour, deeper
var mat_window: ShaderMaterial   ## G-B Ice: warm arrow slits
var _crystal: Node3D
var _tip: MeshInstance3D
var _tip_y: float = 4.05
var _halo: Node3D
var _brazier_orb: MeshInstance3D
var _orb_y: float = 2.3
var _frost_mat: ShaderMaterial


func _setup_palette() -> void:
	kingdom_color = Color(0.45, 0.75, 0.95)
	glow_color = Color(0.75, 0.92, 1.00)
	stone_color = Color(0.40, 0.49, 0.63)   # the Rime Keep's ice-stone
	dark_color = Color(0.27, 0.31, 0.39)
	metal_color = Color(0.70, 0.78, 0.88)   # silver-blue trim
	stripe_color = Color(0.15, 0.35, 0.60)
	glyph_color = Color(0.75, 0.92, 1.00)
	glyph_shape = 1
	smoke_color = Color(0.25, 0.28, 0.34)
	dust_color = Color(0.78, 0.84, 0.90)
	decal_color = Color(0.10, 0.14, 0.22)
	crack_strength = 0.45
	light_color = Color(0.70, 0.88, 1.00)
	light_energy = 1.5
	danger_ramp_hot = Color(0.95, 1.0, 1.0)
	danger_ramp_mid = Color(0.55, 0.82, 1.0)
	danger_ramp_end = Color(0.15, 0.35, 0.60)


func _light_wave(_n: float) -> float:
	if _flicker_amp > 0.2:
		return 0.75 + 0.25 * sin(_t * 17.0)
	return 0.9 + 0.1 * sin(_t * 1.6)


func _idle_motion(delta: float) -> void:
	if _tip and _tip.visible:
		_tip.position.y = _tip_y + 0.14 * sin(_t * 1.3)
		_tip.rotation.y += 0.35 * delta
	if _halo:
		_halo.rotation.y += deg_to_rad(28.0) * delta * (3.0 if _pulse_left > 0.0 else 1.0)
		_halo.position.y = 3.6 + 0.08 * sin(_t * 1.7)
	if _brazier_orb:
		_brazier_orb.position.y = _orb_y + 0.1 * sin(_t * 2.4 + 1.0)
		_brazier_orb.rotation.y = -_t * 1.3


## Frost Hall parts (Body space, gate -Z). Heights: plinth 0.8, walls 3.8, gatehouse 4.65, roof ridge 6.07, turret
## crystals 7.2, ridge crystal tip 11.8. Tiers: PlinthBase, Walls (+ gatehouse, gate, turrets), TurretCapR, Roof,
## RidgeCrystal (base + core + floating tip + halo), IceStore (right), WeaponRack (left).
func _build_structure() -> void:
	_top_y = 11.8
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var sq: Mesh = IceShapes.prism(1.0, 1.0, 1.0, 4)
	mat_snow = _painted_mat(Color(0.86, 0.92, 1.0), 0.15, 0.0)
	mat_roof = _painted_mat(_roof_of(kingdom_color), 0.45, 0.35)
	mat_roof.set_shader_parameter(&"crack_scale", 1.2)
	mat_roof.set_shader_parameter(&"crack_speed", 0.9)
	mat_team.set_shader_parameter(&"spec_strength", 0.5)   # team = glazed crystal ice
	mat_team.set_shader_parameter(&"crack_strength", 0.9)
	mat_team.set_shader_parameter(&"crack_scale", 1.2)
	mat_team.set_shader_parameter(&"crack_speed", 0.9)
	mat_stone.set_shader_parameter(&"crack_scale", 1.8)
	mat_stone.set_shader_parameter(&"crack_speed", 0.9)
	mat_gate.set_shader_parameter(&"rune_bands", 0)
	# G-B Ice: warm interior light in the arrow slits (the gate slit and keystone stay the cold team glow).
	mat_window = _glow_mat(2.0, 0.8, 0)
	mat_window.set_shader_parameter(&"glow_color", IceShapes.window_color(glow_color))
	var hole: StandardMaterial3D = _hole_mat()
	hole.albedo_color = Color(0.02, 0.03, 0.06)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7702
	# --- Plinth: two battered dark tiers, back corner blocks, a step and flagstones at the gate, snow drifts against
	# the plinth and clusters of ice spikes erupting from the frozen ground (the keep's glacier contact).
	var it: Array = []
	it.append(BMG.item(IceShapes.prism(3.2, 3.1, 0.5, 4), Vector3.ZERO, mat_dark))
	it.append(BMG.item(IceShapes.prism(2.98, 2.9, 0.3, 4), Vector3(0, 0.5, 0), mat_dark))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(sq, Vector3(sx * 2.65, 0.8, 2.65), mat_dark, Vector3.ZERO, Vector3(0.36, 0.34, 0.36)))
	it.append(BMG.item(box1, Vector3(HX, 0.14, -3.45), mat_dark, Vector3.ZERO, Vector3(2.4, 0.28, 0.55)))
	for i: int in 2:
		var p := Vector3(HX + rng.randf_range(-0.3, 0.3), 0.03, -4.0 - 0.75 * i)
		it.append(BMG.item(box1, p, mat_stone, Vector3(0, rng.randf_range(-20, 20), 0),
			Vector3(rng.randf_range(0.8, 1.0), 0.07, rng.randf_range(0.5, 0.6))))
	var mound: Mesh = IceShapes.mound()
	for d: Array in [[Vector3(3.22, 0.0, 1.3), Vector3(0.42, 0.26, 1.2)], [Vector3(-3.24, 0.0, -1.7), Vector3(0.45, 0.24, 0.95)],
			[Vector3(1.4, 0.0, 3.24), Vector3(1.3, 0.24, 0.42)], [Vector3(2.65, 1.14, 2.65), Vector3(0.4, 0.16, 0.4)],
			[Vector3(-2.65, 1.14, 2.65), Vector3(0.4, 0.16, 0.4)], [Vector3(-2.2, 0.8, 2.75), Vector3(0.7, 0.2, 0.3)]]:
		it.append(BMG.item(mound, d[0], mat_snow, Vector3(0, rng.randf_range(-20, 20), 0), d[1]))
	for cl: Vector2 in [Vector2(125.0, 3.75), Vector2(212.0, 3.55), Vector2(330.0, 3.75), Vector2(55.0, 3.8)]:
		var a0: float = deg_to_rad(cl.x)
		for j: int in 3:
			var a: float = a0 + rng.randf_range(-0.2, 0.2)
			var out := Vector3(cos(a), 0.0, sin(a))
			var sc: float = rng.randf_range(0.85, 1.3) * (1.0 if j == 0 else 0.6)
			var b: Basis = IceShapes.lean(out, rng.randf_range(18.0, 44.0)) * Basis(Vector3.UP, rng.randf() * TAU) \
				* Basis.from_scale(Vector3.ONE * sc)
			it.append(BMG.item_xf(IceShapes.crystal(0.26, 0.7, 0.55, 0.0), Transform3D(b,
				out * (cl.y + rng.randf_range(-0.2, 0.25)) + Vector3(0, -0.2, 0)), mat_team))
	_merged("PlinthBase", "plinth", it, null, false)   # low plinth: the walls' shadow covers its own
	# --- Walls tier: battered hall body, base courses, back pillars, arrow slits, the crenellated gatehouse with the
	# tombstone gate, the two front turrets (the right turret's crystal cap is its own node: lost under 50 %).
	it = []
	it.append(BMG.item(sq, Vector3(HX, 0.8, HZ), mat_dark, Vector3.ZERO, Vector3(WX + 0.18, 0.45, WZ + 0.18)))
	it.append(BMG.item(IceShapes.prism(1.0, 0.95, 1.0, 4), Vector3(HX, 0.8, HZ), mat_stone, Vector3.ZERO,
		Vector3(WX, 3.0, WZ)))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(IceShapes.prism(0.4, 0.33, 1.0, 4), Vector3(HX + sx * WX, 0.8, HZ + WZ), mat_dark,
			Vector3.ZERO, Vector3(1.0, 3.1, 1.0)))
	# Arrow slits (cold light, flash with the training pulse): two per side, two at the back.
	var fx: float = WX * 0.968
	for sx: float in [-1.0, 1.0]:
		for z: float in [-0.35, 1.35]:
			var p := Vector3(HX + sx * fx, 2.75, z)
			it.append(BMG.item(box1, p, mat_dark, Vector3.ZERO, Vector3(0.16, 1.25, 0.56)))
			it.append(BMG.item(box1, p + Vector3(sx * 0.07, -0.05, 0), mat_window, Vector3.ZERO, Vector3(0.08, 0.95, 0.24)))
			it.append(BMG.item(box1, p + Vector3(sx * 0.05, 0.68, 0), mat_snow, Vector3.ZERO, Vector3(0.22, 0.1, 0.66)))
	for x: float in [HX - 1.0, HX + 1.0]:
		var p := Vector3(x, 2.75, HZ + WZ * 0.968)
		it.append(BMG.item(box1, p, mat_dark, Vector3.ZERO, Vector3(0.56, 1.25, 0.16)))
		it.append(BMG.item(box1, p + Vector3(0, -0.05, 0.07), mat_window, Vector3.ZERO, Vector3(0.24, 0.95, 0.08)))
	# Gatehouse: battered block, base course, snow lip, four snow-capped merlons on the front edge.
	it.append(BMG.item(sq, Vector3(HX, 0.8, GATE_Z), mat_dark, Vector3.ZERO, Vector3(1.84, 0.45, 0.8)))
	it.append(BMG.item(IceShapes.prism(1.0, 0.96, 1.0, 4), Vector3(HX, 0.8, GATE_Z), mat_stone, Vector3.ZERO,
		Vector3(1.72, 3.85, 0.72)))
	for x: float in [-1.2, -0.4, 0.4, 1.2]:
		it.append(BMG.item(IceShapes.prism(1.0, 0.9, 1.0, 4), Vector3(HX + x, 4.72, GATE_Z - 0.42), mat_stone,
			Vector3.ZERO, Vector3(0.27, 0.55, 0.24)))
		it.append(BMG.item(IceShapes.prism(1.0, 0.85, 1.0, 4), Vector3(HX + x, 5.27, GATE_Z - 0.42), mat_snow,
			Vector3.ZERO, Vector3(0.3, 0.12, 0.27)))
	it.append(BMG.item(IceShapes.prism(1.0, 0.97, 1.0, 4), Vector3(HX, 4.62, GATE_Z), mat_snow, Vector3.ZERO,
		Vector3(1.8, 0.16, 0.8)))
	# The keep's gate: dark surround, silver frame, black void, glowing slit and diamond keystone.
	it.append(BMG.item(IceShapes.arch(0.98, 1.55, 0.3), Vector3(HX, 0.8, -2.9), mat_dark))
	it.append(BMG.item(IceShapes.arch(0.8, 1.45, 0.14), Vector3(HX, 0.8, -3.02), mat_metal))
	it.append(BMG.item(IceShapes.arch(0.62, 1.35, 0.1), Vector3(HX, 0.8, -3.06), hole))
	it.append(BMG.item(box1, Vector3(HX, 1.62, -3.12), mat_gate, Vector3.ZERO, Vector3(0.14, 1.25, 0.05)))
	it.append(BMG.item(box1, Vector3(HX, 3.33, -3.07), mat_gate, Vector3(0, 0, 45), Vector3(0.36, 0.36, 0.1)))
	# Turrets: battered square towers, base course, silver band, snow cap; the left one's crystal cap here.
	for s: float in [-1.0, 1.0]:
		var tp := Vector3(HX + s * TUR_X, 0.8, TUR_Z)
		it.append(BMG.item(IceShapes.prism(0.72, 0.72, 0.5, 4), tp, mat_dark))
		it.append(BMG.item(IceShapes.prism(0.64, 0.52, 4.5, 4), tp, mat_stone))
		it.append(BMG.item(IceShapes.prism(0.6, 0.6, 0.22, 4), tp + Vector3(0, 3.72, 0), mat_metal))
		it.append(BMG.item(IceShapes.prism(0.68, 0.58, 0.24, 4), tp + Vector3(0, 4.5, 0), mat_snow))
		var slit := tp + Vector3(s * 0.6, 2.3, 0.0)
		it.append(BMG.item(box1, slit, mat_dark, Vector3.ZERO, Vector3(0.14, 0.9, 0.42)))
		it.append(BMG.item(box1, slit + Vector3(s * 0.06, 0, 0), mat_window, Vector3.ZERO, Vector3(0.08, 0.65, 0.18)))
		if s < 0.0:
			_turret_cap(it, tp + Vector3(0, 4.7, 0), s)
	_merged("Walls", "walls", it)
	it = []
	_turret_cap(it, Vector3(HX + TUR_X, 5.5, TUR_Z), 1.0)
	var cap_r := _merged("TurretCapR", "turret_cap_r", it)
	_hide_below_50.append(cap_r)
	# --- Roof tier: stone gables, 4 courses a side of glazed ice tiles, silver bargeboards, a snow ridge, snow drifts,
	# icicle fringes under both eaves, a crystal emblem on the front gable and a round frost window at the back.
	it = []
	_gable_roof(it, HX, R_Z, R_HALF, R_EAVE, R_RISE, R_DEPTH, R_DEPTH - 0.6, 4, mat_stone, mat_roof, mat_metal, 0.0, 9.0)
	var ridge_y: float = R_EAVE + R_RISE
	it.append(BMG.item(_prism(Vector3(1.05, 0.44, R_DEPTH + 0.25), 0.5), Vector3(HX, ridge_y + 0.21, R_Z), mat_snow))
	# Snow blanket over the upper third of both slopes, its lower edge jagged by tongues of different lengths.
	var slope: float = atan2(R_RISE, R_HALF)
	var slope_l: float = sqrt(R_HALF * R_HALF + R_RISE * R_RISE)
	for s: float in [-1.0, 1.0]:
		var sb := Basis(Vector3.BACK, -s * slope)
		var p: Vector3 = _gable_point(HX, R_HALF, R_EAVE, R_RISE, s, 0.82, 0.37, R_Z)
		it.append(BMG.item_xf(box1, Transform3D(sb.scaled_local(Vector3(slope_l * 0.36 + 0.1, 0.13, R_DEPTH + 0.1)), p),
			mat_snow))
		# Soft drifts along the blanket's lower edge (flattened mounds lying on the slope).
		for dz: Vector3 in [Vector3(-1.75, 0.55, 0.7), Vector3(-0.55, 0.42, 0.55), Vector3(0.65, 0.6, 0.8),
				Vector3(1.8, 0.4, 0.5)]:
			var z: float = R_Z + dz.x * s
			var q: Vector3 = _gable_point(HX, R_HALF, R_EAVE, R_RISE, s, 0.64 - dz.y * 0.12, 0.28, z)
			it.append(BMG.item_xf(mound, Transform3D(sb * Basis(Vector3.UP, 0.0).scaled_local(
				Vector3(dz.y, 0.16, dz.z)), q), mat_snow))
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(IceShapes.icicle_strip(R_DEPTH - 0.3, 10, 0.8, 0.12, 71 if s < 0.0 else 72),
			Vector3(HX + s * (R_HALF - 0.05), R_EAVE - 0.02, R_Z), mat_snow, Vector3(0, 90, 0)))
	it.append(BMG.item(_cyl(0.52, 0.52, 0.12, 6), Vector3(HX, 5.2, R_Z - 2.13), mat_metal, Vector3(90, 30, 0)))
	it.append(BMG.item(IceShapes.crystal(0.34, 0.0, 0.42, 0.42, 4), Vector3(HX, 5.2, R_Z - 2.22), mat_team,
		Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.62, 0.62, 0.12, 10), Vector3(HX, 4.75, R_Z + 2.12), mat_dark, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.45, 0.45, 0.12, 10), Vector3(HX, 4.75, R_Z + 2.18), mat_gate, Vector3(90, 0, 0)))
	var roof := _merged("Roof", "roof", it)
	_hide_on_collapse.append(roof)
	var hole_l: Vector3 = _gable_point(HX, R_HALF, R_EAVE, R_RISE, -1.0, 0.5, 0.32, R_Z + 0.2)
	var hole_r: Vector3 = _gable_point(HX, R_HALF, R_EAVE, R_RISE, 1.0, 0.42, 0.32, R_Z + 0.4)
	_show_below_50.append(_roof_hole("RoofHoleL", roof, hole_l, -1.0, R_HALF, R_RISE, false))
	_show_below_25.append(_roof_hole("RoofHoleR", roof, hole_r, 1.0, R_HALF, R_RISE, true))
	# --- Dominant vertical: the ridge crystal (the keep's crown in small): silver collar, main crystal, two tilted
	# side crystals and three shards, a glowing core in the gap, a floating tip and three orbiting glow shards.
	var crystal := Node3D.new()
	crystal.name = "RidgeCrystal"
	crystal.position = CRYSTAL_POS
	_body.add_child(crystal)
	it = []
	it.append(BMG.item(IceShapes.prism(0.92, 0.78, 0.55, 6), Vector3.ZERO, mat_metal))
	it.append(BMG.item(IceShapes.prism(0.8, 0.66, 0.12, 6), Vector3(0, 0.55, 0), mat_snow))
	it.append(BMG.item(IceShapes.crystal(0.72, 2.6, 0.3, 0.0), Vector3(0, 0.45, 0), mat_team, Vector3(0, 17, 0)))
	for c: Array in [[Vector3(-0.5, 0.35, 0.15), Vector3(-1, 0, 0.3), 24.0, IceShapes.crystal(0.46, 1.5, 0.65, 0.0)],
			[Vector3(0.45, 0.35, -0.3), Vector3(0.9, 0, -0.5), 20.0, IceShapes.crystal(0.4, 1.0, 0.55, 0.0)]]:
		it.append(BMG.item_xf(c[3], Transform3D(IceShapes.lean(c[1], c[2]), c[0]), mat_team))
	for a: float in [60.0, 190.0, 300.0]:
		var out := Vector3(cos(deg_to_rad(a)), 0.0, sin(deg_to_rad(a)))
		it.append(BMG.item_xf(IceShapes.crystal(0.2, 0.35, 0.35, 0.0), Transform3D(IceShapes.lean(out, 42.0),
			out * 0.72 + Vector3(0, 0.3, 0)), mat_team))
	_merged("CrystalBase", "crystal", it, crystal)
	var core := _part("Core", _cyl(0.26, 0.26, 0.95, 6), Vector3(0, 3.6, 0), mat_glow, Vector3.ZERO, crystal)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tip = _part("FloatTip", IceShapes.crystal(0.72, 0.45, 1.75, 0.4), Vector3(0, _tip_y, 0), mat_team, Vector3.ZERO,
		crystal)
	_halo = Node3D.new()
	_halo.name = "Halo"
	_halo.position = Vector3(0, 3.6, 0)
	crystal.add_child(_halo)
	it = []
	for i: int in 3:
		var th: float = TAU * float(i) / 3.0
		var r := Vector3(cos(th), 0.0, sin(th))
		var b := Basis(r.cross(Vector3.UP).normalized(), deg_to_rad(-15.0)) * Basis(Vector3.UP, float(i) * 0.9)
		it.append(BMG.item_xf(IceShapes.crystal(0.16, 0.25, 0.3, 0.3), Transform3D(b, r * 1.15), mat_glow))
	_merged("HaloShards", "halo", it, _halo, false)
	_crystal = crystal
	_falling = crystal
	_fall_axis = Vector3.RIGHT
	_fall_deg = 38.0
	_hide_below_50.append(_tip)
	# --- Banners on the turret fronts.
	var bl := _banner("BannerL", Vector2(0.8, 1.9), Vector3(HX - TUR_X, 3.3, TUR_Z - 0.66), 0.0)
	var br := _banner("BannerR", Vector2(0.8, 1.9), Vector3(HX + TUR_X, 3.3, TUR_Z - 0.66), 0.0)
	_hide_below_25.append(br)
	_hide_on_collapse.append_array([bl, br])
	# --- Asymmetric secondary (right, +X): frost brazier with a floating glow shard, a stack of cut ice blocks.
	var store := Node3D.new()
	store.name = "IceStore"
	_body.add_child(store)
	it = []
	it.append(BMG.item(_cyl(0.5, 0.3, 0.9, 6), Vector3(2.72, 1.25, -0.55), mat_dark))
	it.append(BMG.item(_cyl(0.57, 0.57, 0.14, 6), Vector3(2.72, 1.72, -0.55), mat_metal))
	it.append(BMG.item(_cyl(0.36, 0.36, 0.06, 6), Vector3(2.72, 1.8, -0.55), mat_glow))
	for b: Array in [[Vector3(2.72, 1.1, 1.0), 10.0], [Vector3(2.76, 1.1, 1.85), -8.0], [Vector3(2.7, 1.72, 1.4), 28.0],
			[Vector3(2.2, 1.05, 2.45), 40.0]]:
		it.append(BMG.item(box1, b[0], mat_team, Vector3(0, b[1], 0), Vector3(0.66, 0.6, 0.66)))
	it.append(BMG.item(mound, Vector3(2.75, 0.8, 0.25), mat_snow, Vector3.ZERO, Vector3(0.4, 0.2, 0.45)))
	_merged("StoreParts", "store", it, store, false)
	_hide_on_collapse.append(store)
	_brazier_orb = _octa("BrazierShard", 0.26, 0.4, Vector3(2.72, _orb_y, -0.55), mat_glow, null)
	_hide_on_collapse.append(_brazier_orb)
	# --- Weapon rack (left, -X): two posts, a bar, three ice glaives, two round ice shields with silver bosses.
	var rack := Node3D.new()
	rack.name = "WeaponRack"
	_body.add_child(rack)
	it = []
	for z: float in [-0.55, 1.75]:
		it.append(BMG.item(box1, Vector3(-3.0, 1.85, z), mat_dark, Vector3.ZERO, Vector3(0.28, 2.1, 0.28)))
	it.append(BMG.item(box1, Vector3(-3.0, 2.75, 0.6), mat_metal, Vector3.ZERO, Vector3(0.28, 0.28, 2.65)))
	for i: int in 3:
		var z: float = -0.2 + 0.72 * float(i)
		var tilt := Vector3(8.0 - 8.0 * i, 0, 0)
		it.append(BMG.item(_cyl(0.07, 0.07, 2.4, 6), Vector3(-3.18, 2.0, z), mat_metal, tilt))
		it.append(BMG.item(IceShapes.crystal(0.14, 0.2, 0.5, 0.12), Vector3(-3.18, 3.2, z + tilt.x * 0.02), mat_team))
	for z: float in [0.1, 1.2]:
		it.append(BMG.item(_cyl(0.52, 0.52, 0.14, 8), Vector3(-3.1, 2.05, z), mat_team, Vector3(0, 0, 90)))
		it.append(BMG.item(_cyl(0.6, 0.6, 0.08, 8), Vector3(-3.03, 2.05, z), mat_metal, Vector3(0, 0, 90)))
		it.append(BMG.item(_cyl(0.18, 0.18, 0.12, 6), Vector3(-3.2, 2.05, z), mat_metal, Vector3(0, 0, 90)))
	_merged("RackParts", "rack", it, rack, false)
	_hide_on_collapse.append(rack)
	# No active light: the base class drives _light, so it exists but stays hidden.
	_light = _omni(Vector3(HX, 2.2, -3.6), 6.0)
	_light.visible = false
	# Idle particles (~36): cold flame at the brazier, snow motes falling around the crystal, frost mist at the feet.
	var flame := _pm(Vector3.UP, 16.0, 0.7, 1.1, Vector3.ZERO, 0.4, 0.1, _fire_ramp)
	flame.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	flame.emission_sphere_radius = 0.22
	_idle_fx.append(_particles("ColdFlame", _body, Vector3(2.72, 1.9, -0.55), 12, 0.9, flame, _add_quad, false))
	var motes := _pm(Vector3.DOWN, 40.0, 0.3, 0.6, Vector3(0, -0.3, 0), 0.12, 0.06,
		_ramp(Color(0.9, 0.97, 1.0), Color(0.6, 0.85, 1.0), false))
	motes.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 1.6
	_idle_fx.append(_particles("SnowMotes", crystal, Vector3(0, 4.0, 0), 16, 3.0, motes, _add_quad, false))
	var mist := _pm(Vector3(1, 0, 0), 180.0, 0.1, 0.25, Vector3.ZERO, 1.2, 2.4,
		_ramp(Color(0.85, 0.92, 1.0, 0.16), Color(0.85, 0.92, 1.0), false))
	mist.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mist.emission_ring_axis = Vector3.UP
	mist.emission_ring_radius = 3.4
	mist.emission_ring_inner_radius = 2.6
	mist.emission_ring_height = 0.05
	_idle_fx.append(_particles("FrostMist", self, Vector3(0, 0.35, 0), 8, 6.0, mist, _mix_quad, false))
	# Construction scaffolding, the collapse wreck (a broken turret stub), the frost patch on the ground.
	_build_scaffold(HX, HZ - 0.4, 5.0, 5.5, 4.3)
	_build_wreck(HX, HZ, 4.6, 4.0, PLINTH_TOP + 3.0 * 0.3, Vector3(HX - TUR_X, 1.8, TUR_Z), Vector3(1.2, 2.0, 1.2), 7171)
	var decal := get_node_or_null(^"ContactDecal") as MeshInstance3D
	if decal:
		_frost_mat = ShaderMaterial.new()
		_frost_mat.shader = FROST_GROUND
		_frost_mat.set_shader_parameter(&"size", 10.0)
		_frost_mat.set_shader_parameter(&"plinth_half", 3.2)
		_frost_mat.set_shader_parameter(&"sectors", 16.0)
		_frost_mat.set_shader_parameter(&"seed", 1.3)
		_frost_mat.set_shader_parameter(&"glow_color", glow_color)
		decal.material_override = _frost_mat
	# State particle anchors and the lost-cap rubble (right turret).
	_smoke_points = [hole_l + Vector3(0, 0.3, 0), Vector3(HX - 0.9, 4.9, GATE_Z)]
	_blaze_points = [hole_r + Vector3(0, 0.2, 0), CRYSTAL_POS + Vector3(0, 0.8, 0)]
	var rt := Vector3(HX + TUR_X, 0.0, TUR_Z)
	_rubble2_points = [rt + Vector3(0.75, 0.95, -0.55), rt + Vector3(0.15, 0.95, -0.95), rt + Vector3(0.95, 0.5, -1.2),
		rt + Vector3(-0.55, 1.0, -1.05)]
	_gate_pos = Vector3(HX, 1.6, -3.3)


## G-B Ice: after the B8 merge the body draws with the Ice paint layer (crystal ice, snow, frost-rimmed stone).
## FireHallModel._post_build is not called on purpose: the Fire look must never reach the Frost Hall.
func _post_build() -> void:
	IceShapes.ice_vc(mat_team)


## The B8 paths stay on once the body is the Ice version of painted_vc.
func _vc_wanted() -> bool:
	return IceShapes.is_vc(mat_team) or (mat_team != null and mat_team.shader == PAINTED)


## Team colour: the base class recolours crystals, banners and sparks; the roof tiles take a deeper shade of it.
func set_team_color(c: Color) -> void:
	super(c)
	if mat_roof:
		mat_roof.set_shader_parameter(&"base_color", _roof_of(c))


func _roof_of(c: Color) -> Color:
	return c.darkened(0.35)


## B8 merge: the roof is the team colour darkened 35 %.
func _vc_team() -> Array:
	return [mat_team, [mat_roof, 0.65]]


## The keep's cold idle rim instead of the base one (selection still turns it to the team colour).
func _apply_rim_and_glow() -> void:
	super()
	if _ready_done:
		IceShapes.apply_ice_rim(_painted, _team_color, _sel_k, _progress < 1.0 and not _destroyed)


## A turret's crystal cap (team crystal leaning slightly outward + a small spike), appended to `items` at `p`.
func _turret_cap(items: Array, p: Vector3, s: float) -> void:
	items.append(BMG.item_xf(IceShapes.crystal(0.55, 0.3, 1.35, 0.0), Transform3D(Basis(Vector3.UP, 0.4 * s)
		* IceShapes.lean(Vector3(s, 0, -0.3), 5.0), p), mat_team))
	items.append(BMG.item_xf(IceShapes.crystal(0.2, 0.3, 0.4, 0.0), Transform3D(IceShapes.lean(Vector3(s, 0, -0.6), 34.0),
		p + Vector3(s * 0.38, -0.05, -0.28)), mat_team))


## Ice rubble (the lost turret cap) is crystal, not dark stone.
func _build_state_nodes() -> void:
	super()
	_rubble2.material_override = mat_team


## Frost patch follows the damage (fern lines glow brighter).
func _apply_health() -> void:
	super()
	if _frost_mat:
		_frost_mat.set_shader_parameter(&"damage", 0.0 if _health_ratio >= 0.5 else (0.5 if _health_ratio >= 0.25 else 1.0))


## Collapse: the base sequence, then the frost patch turns to grey slush.
func _process_destroyed(delta: float) -> void:
	super(delta)
	if _frost_mat:
		_frost_mat.set_shader_parameter(&"scorch", clampf(_destroy_t - 2.0, 0.0, 1.0))


## An octahedron (two 4-sided cones base to base), glowing shards. Not shadowed.
func _octa(nm: String, r: float, h: float, pos: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var up := _part(nm, _cyl(0.0, r, h, 4), pos, mat, Vector3.ZERO, parent)
	var down := MeshInstance3D.new()
	down.name = "Down"
	down.mesh = _cyl(r, 0.0, h, 4)
	down.material_override = mat
	down.position = Vector3(0, -h, 0)
	down.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	up.add_child(down)
	up.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return up
