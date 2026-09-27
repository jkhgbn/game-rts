class_name FrostBazaarModel
extends FireHallModel
## Visual model of Torvald's market, the Frost Bazaar (task 10.V3; market-trade.md 4.1 + 9, art-keep.md 0), in the
## Rime Keep / Frost Hall language (ice-stone, glazed team ice, snow, silver-blue trim, faceted crystals).
## Read from the RTS camera (stall + sign silhouette shared by the four Bazaars):
## - Dominant vertical (back right, ~9 m): a faceted team-ice **crystal mast** with silver bands and a flared silver
##   crown whose yoke holds a big **silver-blue balance scale** (a gold heap in one pan, an ice block in the other),
##   a floating glow gem above the pivot. Placed at the back so it rises above the roof line from the RTS camera.
##   A team banner hangs on the mast.
## - Secondary (back left): a snug ice-stone **counting house** under a gable roof of glazed team-ice tiles (snow
##   blanket, icicles), its front gable carrying a big **gold coin emblem** with an ice diamond; a wide counter window
##   built of ice blocks, draped with fur pelts, under a striped team / snow awning with pennant bunting and a frost
##   lantern.
## - Asymmetric goods: a **sled-runner stall** (front left: a sledge loaded with ice blocks and pelts under a team
##   cloth canopy trimmed with white fur) and a **cargo sledge** of frosted crates and a barrel (front right). Cut ice
##   blocks by the mast, paved yard, snow drifts, ice spikes and a frost patch on the ground. A team banner on a pole.
## Gold (coin emblem, coin heaps) is the one colour outside the Ice palette: it is the trade currency and the shared
## "market" cue of the four Bazaars (kept to a few small parts).
## Hooks (FireHallModel contract, art-keep.md 8.8): set_team_color, set_construction_progress, set_health_ratio,
## play_training_pulse, play_destroyed (-> destroyed_finished after 3 s), set_selected, plus **play_delivery()**
## (a caravan delivered: the scale tips toward the gold pan and swings back to balance, the coins glint).
## Footprint 3 x 3 cells (6 x 6 m), gate local -Z, top of the mast gem ~9.1 m. Tiers are merged meshes
## (BuildingMerge); no active light (the base class light exists but stays hidden): the glow comes from emissive parts.

const PT := 0.5        ## plinth top
const HX := -1.05      ## counting house axis x
const HZ := 1.55       ## counting house centre z
const WX := 1.75       ## house half-width
const WZ := 1.3        ## house half-depth
const WALL_H := 2.4
const R_HALF := 2.2
const R_EAVE := 2.95
const R_RISE := 1.75
const R_DEPTH := 3.35
const R_CORE := 2.6
const COIN_POS := Vector3(HX, 3.62, 0.11)   ## coin emblem centre on the front gable (faces -Z)
const MAST := Vector3(1.95, PT, 1.9)         ## mast foot (back right: it rises above the roof line from the camera)
const PIVOT_Y := 7.0   ## scale beam pivot on the mast's silver yoke (mast space)
const BEAM_HALF := 1.15
const PAN_DROP := 1.1  ## pan dish below the beam
const GEM_Y := 8.15    ## floating gem above the pivot (mast space)
const SCALE_YAW := -45.0  ## the scale is turned 45 deg so it reads in all four gate orientations (never edge-on)
const SPRING_K := 22.0 ## scale swing: stiffness, damping, kick per delivery (rad/s)
const SPRING_C := 2.6
const DELIVERY_KICK := 1.35
const GLINT_TIME := 0.9
const GOLD := Color(0.95, 0.74, 0.28)
const FROST_GROUND: Shader = preload("res://art/buildings/ice/ice_frost_ground.gdshader")

var mat_snow: ShaderMaterial
var mat_roof: ShaderMaterial   ## glazed roof tiles: the team colour, deeper
var mat_cloth: ShaderMaterial  ## awning stripes / pennants: the team colour, matte
var mat_fur: ShaderMaterial    ## pelts, crates, barrel (warm goods)
var mat_gold: ShaderMaterial   ## coin emblem, coin heaps
var _mast: Node3D
var _gem: MeshInstance3D
var _beam: Node3D
var _pan_l: Node3D   ## the gold pan (goes down on a delivery)
var _pan_r: Node3D
var _sc_ang: float = 0.0
var _sc_vel: float = 0.0
var _glint_t: float = 0.0
var _glint_pan: GPUParticles3D
var _glint_coin: GPUParticles3D
var _frost_mat: ShaderMaterial
var _deliveries: int = 0


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


# --- Hooks ---

## A caravan delivered its gold: the scale tips toward the gold pan and swings back to balance (~2 s), the coin
## emblem and the gold pan glint. Retriggering adds to the swing. Ignored on a site or a wreck.
func play_delivery() -> void:
	if _destroyed:
		return
	_deliveries += 1
	if not _ready_done or _progress < 1.0:
		return
	_sc_vel += DELIVERY_KICK
	_glint_t = GLINT_TIME
	_fire(_glint_pan)
	_fire(_glint_coin)


## Team colour: the base class recolours crystals, banners and sparks; roof tiles take a deeper shade, the awning
## stripes and pennants the plain colour.
func set_team_color(c: Color) -> void:
	super(c)
	if not _ready_done:
		return
	mat_roof.set_shader_parameter(&"base_color", c.darkened(0.35))
	mat_cloth.set_shader_parameter(&"base_color", c)
	IceShapes.tint_banner(mat_banner, c, kingdom_color, glow_color if c.is_equal_approx(kingdom_color) else c.lightened(0.35))


# --- Kingdom-specific overrides ---

func _light_wave(_n: float) -> float:
	return 0.9 + 0.1 * sin(_t * 1.6)


func _idle_motion(delta: float) -> void:
	if _gem and _gem.visible:
		_gem.position.y = GEM_Y + 0.12 * sin(_t * 1.4)
		_gem.rotation.y += 0.6 * delta
	if _beam:
		var dt: float = minf(delta, 0.05)
		_sc_vel += (-SPRING_K * _sc_ang - SPRING_C * _sc_vel) * dt
		_sc_ang += _sc_vel * dt
		var a: float = _sc_ang + 0.035 * sin(_t * 0.8)
		_beam.rotation.z = a
		_pan_l.rotation.z = -a
		_pan_r.rotation.z = -a
	if _glint_t > 0.0:
		_glint_t = maxf(_glint_t - delta, 0.0)
		var k: float = sin(PI * (1.0 - _glint_t / GLINT_TIME))
		mat_gold.set_shader_parameter(&"crack_strength", 1.4 * k)
		mat_gold.set_shader_parameter(&"rim_color", Color(1.0, 0.86, 0.45))
		mat_gold.set_shader_parameter(&"rim_strength", lerpf(0.35, 2.4, k))
		if _glint_t <= 0.0:
			_apply_rim_and_glow()


## The keep's cold idle rim instead of the base one (selection still turns it to the team colour).
func _apply_rim_and_glow() -> void:
	super()
	if _ready_done:
		IceShapes.apply_ice_rim(_painted, _team_color, _sel_k, _progress < 1.0 and not _destroyed)
		if mat_gold and _glint_t <= 0.0:
			mat_gold.set_shader_parameter(&"crack_strength", 0.0)


## Frost Bazaar parts (Body space, gate -Z). Heights: plinth 0.5, house walls 2.9, roof ridge 4.65 (finials 5.3),
## counter awning 2.8, stall canopy 2.7, mast crown 6.9, scale pivot 7.5 (pans ~6.4), gem top ~9.1.
## Tiers: PlinthBase, Walls (house, counter + awning, banner pole, ice blocks), Roof (+ coin emblem),
## SledStall (sledge + goods, canopy), CargoSled, Mast (column + arm, scale beam + two pans, gem, banner).
func _build_structure() -> void:
	_top_y = 9.1
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var sq: Mesh = IceShapes.prism(1.0, 1.0, 1.0, 4)
	var mound: Mesh = IceShapes.mound()
	mat_snow = _painted_mat(Color(0.86, 0.92, 1.0), 0.15, 0.0)
	mat_roof = _painted_mat(kingdom_color.darkened(0.35), 0.45, 0.35)
	mat_roof.set_shader_parameter(&"crack_scale", 1.2)
	mat_roof.set_shader_parameter(&"crack_speed", 0.9)
	mat_cloth = _painted_mat(kingdom_color, 0.0, 0.0)
	mat_fur = _painted_mat(Color(0.58, 0.46, 0.35), 0.05, 0.0)
	mat_gold = _painted_mat(GOLD, 0.65, 0.0)
	mat_gold.set_shader_parameter(&"crack_color", Color(1.0, 0.85, 0.4))
	mat_gold.set_shader_parameter(&"crack_scale", 0.5)
	mat_gold.set_shader_parameter(&"crack_speed", 6.0)
	mat_team.set_shader_parameter(&"spec_strength", 0.5)   # team = glazed crystal ice
	mat_team.set_shader_parameter(&"crack_strength", 0.9)
	mat_team.set_shader_parameter(&"crack_scale", 1.2)
	mat_team.set_shader_parameter(&"crack_speed", 0.9)
	mat_stone.set_shader_parameter(&"crack_scale", 1.8)
	mat_stone.set_shader_parameter(&"crack_speed", 0.9)
	mat_gate.set_shader_parameter(&"rune_bands", 0)
	var hole: StandardMaterial3D = _hole_mat()
	hole.albedo_color = Color(0.02, 0.03, 0.06)
	var rng := RandomNumberGenerator.new()
	rng.seed = 10303
	# --- Plinth: two dark tiers, a paved yard of light ice-stone slabs, a front step with flagstones, snow drifts
	# and clusters of ice spikes erupting from the frozen ground.
	var it: Array = []
	it.append(BMG.item(IceShapes.prism(3.2, 3.1, 0.3, 4), Vector3.ZERO, mat_dark))
	it.append(BMG.item(IceShapes.prism(3.02, 2.96, 0.2, 4), Vector3(0, 0.3, 0), mat_dark))
	for z: float in [-2.5, -1.52, -0.54]:
		for x: float in [-2.44, -1.46, -0.48, 0.5, 1.48, 2.44]:
			var p := Vector3(x + rng.randf_range(-0.04, 0.04), PT + 0.01, z + rng.randf_range(-0.04, 0.04))
			it.append(BMG.item(box1, p, mat_stone, Vector3(0, rng.randf_range(-5, 5), 0),
				Vector3(rng.randf_range(0.8, 0.88), 0.05, rng.randf_range(0.8, 0.88))))
	it.append(BMG.item(box1, Vector3(0.3, 0.13, -3.42), mat_dark, Vector3.ZERO, Vector3(2.8, 0.26, 0.55)))
	for i: int in 2:
		var p := Vector3(0.3 + rng.randf_range(-0.3, 0.3), 0.03, -3.98 - 0.75 * i)
		it.append(BMG.item(box1, p, mat_stone, Vector3(0, rng.randf_range(-20, 20), 0),
			Vector3(rng.randf_range(0.8, 1.0), 0.07, rng.randf_range(0.5, 0.6))))
	for d: Array in [[Vector3(3.22, 0.0, 1.0), Vector3(0.42, 0.26, 1.1)], [Vector3(-3.24, 0.0, -1.9), Vector3(0.45, 0.24, 0.9)],
			[Vector3(-1.0, 0.0, 3.24), Vector3(1.4, 0.24, 0.42)], [Vector3(3.2, 0.0, -2.6), Vector3(0.36, 0.2, 0.55)],
			[Vector3(-2.75, PT, 2.75), Vector3(0.45, 0.18, 0.4)], [Vector3(1.25, PT, 2.8), Vector3(0.5, 0.16, 0.3)]]:
		it.append(BMG.item(mound, d[0], mat_snow, Vector3(0, rng.randf_range(-20, 20), 0), d[1]))
	for cl: Vector2 in [Vector2(128.0, 3.75), Vector2(206.0, 3.6), Vector2(334.0, 3.75), Vector2(52.0, 3.8)]:
		var a0: float = deg_to_rad(cl.x)
		for j: int in 3:
			var a: float = a0 + rng.randf_range(-0.2, 0.2)
			var out := Vector3(cos(a), 0.0, sin(a))
			var sc: float = rng.randf_range(0.85, 1.25) * (1.0 if j == 0 else 0.6)
			var b: Basis = IceShapes.lean(out, rng.randf_range(18.0, 44.0)) * Basis(Vector3.UP, rng.randf() * TAU) \
				* Basis.from_scale(Vector3.ONE * sc)
			it.append(BMG.item_xf(IceShapes.crystal(0.26, 0.7, 0.55, 0.0), Transform3D(b,
				out * (cl.y + rng.randf_range(-0.2, 0.25)) + Vector3(0, -0.2, 0)), mat_team))
	_merged("PlinthBase", "plinth", it, null, false)   # low plinth: the walls' shadow covers its own
	# --- Walls tier: the counting house (battered ice-stone, dark base course and corner posts, cold side windows),
	# the counter window (ice-block counter, fur pelts, coin stacks) and the banner pole at its left.
	it = []
	it.append(BMG.item(sq, Vector3(HX, PT, HZ), mat_dark, Vector3.ZERO, Vector3(WX + 0.16, 0.42, WZ + 0.16)))
	it.append(BMG.item(IceShapes.prism(1.0, 0.95, 1.0, 4), Vector3(HX, PT, HZ), mat_stone, Vector3.ZERO,
		Vector3(WX, WALL_H, WZ)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(BMG.item(IceShapes.prism(0.26, 0.2, 1.0, 4), Vector3(HX + c.x * (WX - 0.02), PT, HZ + c.y * (WZ - 0.02)),
			mat_dark, Vector3.ZERO, Vector3(1.0, WALL_H + 0.08, 1.0)))
	var fx: float = WX * 0.968
	for sx: float in [-1.0, 1.0]:
		var p := Vector3(HX + sx * fx, 2.1, HZ + 0.25)
		it.append(BMG.item(box1, p, mat_dark, Vector3.ZERO, Vector3(0.16, 1.0, 0.62)))
		it.append(BMG.item(box1, p + Vector3(sx * 0.07, -0.05, 0), mat_gate, Vector3.ZERO, Vector3(0.08, 0.72, 0.3)))
		it.append(BMG.item(box1, p + Vector3(sx * 0.05, 0.56, 0), mat_snow, Vector3.ZERO, Vector3(0.22, 0.1, 0.74)))
	# Counter window: dark frame, black interior, a silver lintel, a glowing lamp strip at the top of the opening.
	it.append(BMG.item(box1, Vector3(HX, 2.02, 0.24), mat_dark, Vector3.ZERO, Vector3(2.55, 1.4, 0.16)))
	it.append(BMG.item(box1, Vector3(HX, 2.0, 0.15), hole, Vector3.ZERO, Vector3(2.2, 1.1, 0.04)))
	it.append(BMG.item(box1, Vector3(HX, 2.5, 0.12), mat_gate, Vector3.ZERO, Vector3(1.9, 0.08, 0.03)))
	it.append(BMG.item(box1, Vector3(HX, 2.76, 0.19), mat_metal, Vector3.ZERO, Vector3(2.7, 0.14, 0.26)))
	# The counter: a shelf of glazed ice on a wall of cut ice blocks.
	it.append(BMG.item(box1, Vector3(HX, 1.4, 0.02), mat_team, Vector3.ZERO, Vector3(2.7, 0.2, 0.66)))
	for i: int in 4:
		var x: float = HX + (-0.96 + 0.64 * i) + rng.randf_range(-0.03, 0.03)
		it.append(BMG.item(box1, Vector3(x, PT + 0.39, -0.02), mat_team, Vector3(0, rng.randf_range(-4, 4), 0),
			Vector3(0.6, 0.78, 0.5)))
	# Fur pelts draped over the counter front, one lying on it; coin stacks and an ingot.
	for pl: Vector3 in [Vector3(HX - 0.78, 1.18, -6.0), Vector3(HX + 0.02, 1.2, 4.0), Vector3(HX + 0.8, 1.16, -3.0)]:
		it.append(BMG.item(box1, Vector3(pl.x, pl.y, -0.36), mat_fur if pl.z < 0.0 else mat_snow, Vector3(76, 0, pl.z),
			Vector3(0.62, 0.05, 0.64)))
	it.append(BMG.item(box1, Vector3(HX + 0.55, 1.53, 0.05), mat_fur, Vector3(0, 12, 0), Vector3(0.75, 0.05, 0.55)))
	it.append(BMG.item(_cyl(0.13, 0.13, 0.2, 8), Vector3(HX - 0.6, 1.6, 0.02), mat_gold))
	it.append(BMG.item(_cyl(0.13, 0.13, 0.12, 8), Vector3(HX - 0.3, 1.56, 0.12), mat_gold))
	it.append(BMG.item(box1, Vector3(HX - 0.95, 1.55, 0.1), mat_gold, Vector3(0, 20, 0), Vector3(0.3, 0.1, 0.16)))
	# Banner pole (left of the house front): silver pole, crossbar, crystal finial.
	var bp := Vector3(-2.92, PT, 0.02)
	it.append(BMG.item(_cyl(0.07, 0.08, 3.5, 6), bp + Vector3(0, 1.75, 0), mat_metal))
	it.append(BMG.item(box1, bp + Vector3(0, 3.35, -0.06), mat_metal, Vector3.ZERO, Vector3(0.86, 0.09, 0.09)))
	it.append(BMG.item(IceShapes.crystal(0.12, 0.1, 0.34, 0.08), bp + Vector3(0, 3.55, 0), mat_team))
	# Snow against the house.
	it.append(BMG.item(mound, Vector3(0.8, PT, 1.9), mat_snow, Vector3(0, 10, 0), Vector3(0.3, 0.3, 0.8)))
	it.append(BMG.item(mound, Vector3(-3.0, PT, 1.3), mat_snow, Vector3(0, -15, 0), Vector3(0.28, 0.24, 0.7)))
	var walls_it: Array = it   # the counter awning and the ice blocks join this tier below (fewer surfaces)
	# --- Roof tier: stone gables, 3 courses a side of glazed ice tiles, silver bargeboards, a snow ridge and blanket,
	# icicle fringes, crystal finials at the ridge ends, the gold coin emblem (front) and a round frost window (back).
	it = []
	_gable_roof(it, HX, HZ, R_HALF, R_EAVE, R_RISE, R_DEPTH, R_CORE, 3, mat_stone, mat_roof, mat_metal, 0.0, 9.0)
	var ridge_y: float = R_EAVE + R_RISE
	it.append(BMG.item(_prism(Vector3(0.95, 0.4, R_DEPTH + 0.25), 0.5), Vector3(HX, ridge_y + 0.2, HZ), mat_snow))
	var slope: float = atan2(R_RISE, R_HALF)
	var slope_l: float = sqrt(R_HALF * R_HALF + R_RISE * R_RISE)
	for s: float in [-1.0, 1.0]:
		var sb := Basis(Vector3.BACK, -s * slope)
		var p: Vector3 = _gable_point(HX, R_HALF, R_EAVE, R_RISE, s, 0.8, 0.36, HZ)
		it.append(BMG.item_xf(box1, Transform3D(sb.scaled_local(Vector3(slope_l * 0.4 + 0.1, 0.12, R_DEPTH + 0.1)), p),
			mat_snow))
		for dz: Vector3 in [Vector3(-1.1, 0.5, 0.6), Vector3(0.05, 0.42, 0.55), Vector3(1.15, 0.55, 0.65)]:
			var q: Vector3 = _gable_point(HX, R_HALF, R_EAVE, R_RISE, s, 0.6 - dz.y * 0.12, 0.27, HZ + dz.x * s)
			it.append(BMG.item_xf(mound, Transform3D(sb.scaled_local(Vector3(dz.y, 0.15, dz.z)), q), mat_snow))
		it.append(BMG.item(IceShapes.icicle_strip(R_DEPTH - 0.3, 8, 0.6, 0.1, 81 if s < 0.0 else 82),
			Vector3(HX + s * (R_HALF - 0.05), R_EAVE - 0.02, HZ), mat_snow, Vector3(0, 90, 0)))
	for z: float in [HZ - R_DEPTH * 0.5 + 0.15, HZ + R_DEPTH * 0.5 - 0.15]:
		it.append(BMG.item(IceShapes.crystal(0.17, 0.12, 0.48, 0.0), Vector3(HX, ridge_y + 0.32, z), mat_team,
			Vector3(0, 30, 0)))
	it.append(BMG.item(_cyl(0.62, 0.62, 0.12, 14), COIN_POS + Vector3(0, 0, 0.08), mat_metal, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.5, 0.5, 0.1, 14), COIN_POS, mat_gold, Vector3(90, 0, 0)))
	it.append(BMG.item_xf(IceShapes.crystal(0.24, 0.0, 0.22, 0.22, 4), Transform3D(Basis(Vector3.RIGHT, PI * 0.5)
		* Basis(Vector3.UP, PI * 0.25), COIN_POS + Vector3(0, 0, -0.06)), mat_team))
	var roof := _merged("Roof", "roof", it)
	_hide_on_collapse.append(roof)
	var hole_l: Vector3 = _gable_point(HX, R_HALF, R_EAVE, R_RISE, -1.0, 0.45, 0.32, HZ + 0.4)
	var hole_r: Vector3 = _gable_point(HX, R_HALF, R_EAVE, R_RISE, 1.0, 0.4, 0.32, HZ - 0.35)
	_show_below_50.append(_roof_hole("RoofHoleL", roof, hole_l, -1.0, R_HALF, R_RISE, false))
	_show_below_25.append(_roof_hole("RoofHoleR", roof, hole_r, 1.0, R_HALF, R_RISE, true))
	# --- Counter awning: striped team / snow cloth sloping out over the counter, pennant bunting along its front,
	# a snow crust, two silver poles and a frost lantern on a bracket off the left pole (Walls tier).
	it = walls_it
	var aw_b := Basis(Vector3.RIGHT, deg_to_rad(-21.4))
	var aw_c := Vector3(HX, 2.575, -0.275)
	var sw: float = 0.42
	for i: int in 7:
		var x: float = HX + (float(i) - 3.0) * sw
		var m: Material = mat_cloth if i % 2 == 0 else mat_snow
		it.append(BMG.item_xf(box1, Transform3D(aw_b.scaled_local(Vector3(sw + 0.005, 0.08, 1.24)), Vector3(x, aw_c.y,
			aw_c.z)), m))
		it.append(BMG.item(_prism(Vector3(sw - 0.02, 0.28, 0.05), 0.5), Vector3(x, 2.21, -0.86), m, Vector3(0, 0, 180)))
	it.append(BMG.item_xf(box1, Transform3D(aw_b.scaled_local(Vector3(2.75, 0.06, 0.46)),
		aw_c + aw_b * Vector3(0, 0.07, 0.32)), mat_snow))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(_cyl(0.055, 0.065, 1.85, 6), Vector3(HX + sx * 1.38, PT + 0.925, -0.8), mat_metal))
		it.append(BMG.item(box1, Vector3(HX + sx * 1.38, 2.4, -0.8), mat_metal, Vector3.ZERO, Vector3(0.16, 0.12, 0.16)))
	var lx: float = HX - 1.38 - 0.34
	it.append(BMG.item(box1, Vector3(HX - 1.38 - 0.18, 2.2, -0.8), mat_metal, Vector3.ZERO, Vector3(0.38, 0.06, 0.06)))
	it.append(BMG.item(_cyl(0.0, 0.2, 0.18, 4), Vector3(lx, 2.06, -0.8), mat_dark, Vector3(0, 45, 0)))
	it.append(BMG.item(box1, Vector3(lx, 1.84, -0.8), mat_glow, Vector3.ZERO, Vector3(0.22, 0.28, 0.22)))
	it.append(BMG.item(box1, Vector3(lx, 1.68, -0.8), mat_dark, Vector3.ZERO, Vector3(0.26, 0.05, 0.26)))
	# Cut ice blocks stacked behind the house and beside the mast (back right).
	for b: Array in [[Vector3(1.25, PT + 0.27, 2.72), 12.0, 0.54], [Vector3(2.72, PT + 0.25, 0.72), -8.0, 0.5],
			[Vector3(1.3, PT + 0.78, 2.7), 34.0, 0.48], [Vector3(2.2, PT + 0.24, 0.62), 20.0, 0.46]]:
		it.append(BMG.item(box1, b[0], mat_team, Vector3(0, b[1], 0), Vector3.ONE * float(b[2])))
	it.append(BMG.item(mound, Vector3(1.3, PT + 1.02, 2.7), mat_snow, Vector3(0, 30, 0), Vector3(0.27, 0.1, 0.27)))
	_merged("Walls", "walls", walls_it)
	# --- Sled-runner stall (front left): a sledge loaded with ice blocks, pelts and a frosted crate under a team
	# cloth canopy trimmed with white fur, on four silver poles, a team pennant on the front pole.
	var stall := Node3D.new()
	stall.name = "SledStall"
	stall.position = Vector3(-1.5, PT, -2.15)
	stall.rotation.y = deg_to_rad(6.0)
	_body.add_child(stall)
	it = []
	_sled(it, 2.3, 1.1)
	for b: Array in [[Vector3(-0.65, 0.71, -0.18), 8.0, 0.42], [Vector3(-0.2, 0.7, -0.24), -10.0, 0.4],
			[Vector3(-0.45, 1.11, -0.2), 30.0, 0.38]]:
		it.append(BMG.item(box1, b[0], mat_team, Vector3(0, b[1], 0), Vector3.ONE * float(b[2])))
	for pl: Array in [[Vector3(0.45, 0.53, 0.12), 5.0, mat_fur], [Vector3(0.42, 0.61, 0.1), -9.0, mat_snow],
			[Vector3(0.47, 0.69, 0.14), 14.0, mat_fur]]:
		it.append(BMG.item(box1, pl[0], pl[2], Vector3(0, pl[1], 0), Vector3(0.85, 0.08, 0.72)))
	it.append(BMG.item(box1, Vector3(0.55, 0.96, -0.2), mat_fur, Vector3(0, -12, 0), Vector3(0.46, 0.46, 0.46)))
	it.append(BMG.item(box1, Vector3(0.55, 0.97, -0.2), mat_metal, Vector3(0, -12, 0), Vector3(0.49, 0.07, 0.49)))
	it.append(BMG.item(box1, Vector3(0.55, 1.21, -0.2), mat_snow, Vector3(0, -12, 0), Vector3(0.42, 0.06, 0.42)))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(_cyl(0.05, 0.06, 2.2, 6), Vector3(sx * 1.05, 1.1, 0.5), mat_metal))
		it.append(BMG.item(_cyl(0.05, 0.06, 1.85, 6), Vector3(sx * 1.05, 0.925, -0.52), mat_metal))
	it.append(BMG.item(_cyl(0.04, 0.04, 0.55, 4), Vector3(1.05, 2.1, -0.52), mat_metal))
	_merged("StallParts", "stall", it, stall, false)
	# Canopy (lost below 50 %): team cloth sloping to the front, a thick white fur roll along its front and back
	# edges, a brown pelt thrown over one corner, a snow crust, fur tassels, the pennant.
	it = []
	var cb := Basis(Vector3.RIGHT, deg_to_rad(-17.2))
	var cc := Vector3(0.0, 2.03, -0.02)
	it.append(BMG.item_xf(box1, Transform3D(cb.scaled_local(Vector3(2.45, 0.08, 1.26)), cc), mat_cloth))
	for ez: float in [-0.62, 0.62]:
		it.append(BMG.item_xf(_cyl(0.11, 0.11, 2.55, 6), Transform3D(cb * Basis(Vector3.BACK, PI * 0.5),
			cc + cb * Vector3(0, 0.03, ez)), mat_snow))
	it.append(BMG.item_xf(box1, Transform3D(cb.scaled_local(Vector3(1.2, 0.05, 0.4)), cc + cb * Vector3(-0.45, 0.07, 0.25)),
		mat_snow))
	for i: int in 5:
		var x: float = -0.96 + 0.48 * float(i)
		it.append(BMG.item_xf(_prism(Vector3(0.3, 0.24, 0.06), 0.5), Transform3D(Basis(Vector3.FORWARD, PI),
			cc + cb * Vector3(x, -0.02, -0.64) + Vector3(0, -0.2, 0)), mat_snow))
	it.append(BMG.item(_prism(Vector3(0.4, 0.55, 0.04), 0.0), Vector3(1.26, 2.12, -0.52), mat_cloth, Vector3(0, 0, -90)))
	var canopy := _merged("StallCanopy", "stall_canopy", it, stall, false)
	_hide_below_50.append(canopy)
	_hide_on_collapse.append(canopy)
	# --- Cargo sledge (front right, its curled runners toward the front): frosted crates, a barrel, a pelt.
	var cargo := Node3D.new()
	cargo.name = "CargoSled"
	cargo.position = Vector3(2.05, PT, -1.55)
	cargo.rotation.y = deg_to_rad(90.0 - 4.0)
	_body.add_child(cargo)
	it = []
	_sled(it, 2.3, 1.1)
	for cr: Array in [[Vector3(-0.55, 0.85, -0.16), 4.0, 0.72], [Vector3(0.22, 0.82, 0.14), -7.0, 0.66],
			[Vector3(-0.38, 1.5, -0.06), 15.0, 0.6]]:
		_crate(it, cr[0], cr[1], cr[2])
	it.append(BMG.item(mound, Vector3(-0.38, 1.86, -0.06), mat_snow, Vector3(0, 20, 0), Vector3(0.3, 0.14, 0.3)))
	it.append(BMG.item(_cyl(0.26, 0.26, 0.66, 8), Vector3(0.85, 0.82, -0.25), mat_fur))
	for y: float in [0.62, 1.02]:
		it.append(BMG.item(_cyl(0.275, 0.275, 0.06, 8), Vector3(0.85, y, -0.25), mat_metal))
	it.append(BMG.item(_cyl(0.24, 0.24, 0.05, 8), Vector3(0.85, 1.17, -0.25), mat_snow))
	it.append(BMG.item(box1, Vector3(0.82, 0.62, 0.28), mat_fur, Vector3(0, 18, 0), Vector3(0.7, 0.1, 0.5)))
	_merged("CargoParts", "cargo", it, cargo, false)
	# --- Dominant vertical: the crystal mast (back right, beside the house): dark socket, silver collar, leaning foot
	# crystals, a tall faceted team-ice column with silver bands, a flared silver crown and a yoke holding the scale.
	_mast = Node3D.new()
	_mast.name = "Mast"
	_mast.position = MAST
	_body.add_child(_mast)
	it = []
	it.append(BMG.item(IceShapes.prism(0.62, 0.5, 0.45, 6), Vector3.ZERO, mat_dark, Vector3(0, 30, 0)))
	it.append(BMG.item(IceShapes.prism(0.5, 0.47, 0.12, 6), Vector3(0, 0.45, 0), mat_metal, Vector3(0, 30, 0)))
	it.append(BMG.item(IceShapes.crystal(0.42, 5.75, 0.5, 0.0), Vector3(0, 0.5, 0), mat_team))
	for y: float in [1.9, 5.05]:
		it.append(BMG.item(IceShapes.prism(0.41, 0.41, 0.16, 6), Vector3(0, y, 0), mat_metal, Vector3(0, 30, 0)))
	it.append(BMG.item(IceShapes.prism(0.4, 0.48, 0.28, 6), Vector3(0, 6.0, 0), mat_metal, Vector3(0, 30, 0)))
	it.append(BMG.item(IceShapes.prism(0.48, 0.45, 0.08, 6), Vector3(0, 6.28, 0), mat_snow, Vector3(0, 30, 0)))
	for a: float in [20.0, 140.0, 255.0]:
		var out := Vector3(cos(deg_to_rad(a)), 0.0, sin(deg_to_rad(a)))
		it.append(BMG.item_xf(IceShapes.crystal(0.16, 0.35, 0.35, 0.0), Transform3D(IceShapes.lean(out, 32.0),
			out * 0.55 + Vector3(0, 0.1, 0)), mat_team))
	# The yoke: two silver cheeks either side of the beam, a crossbar over the pivot (turned with the scale).
	var yb := Basis(Vector3.UP, deg_to_rad(SCALE_YAW))
	for sz: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, yb * Vector3(0, 6.72, sz * 0.22), mat_metal, Vector3(0, SCALE_YAW, 0),
			Vector3(0.2, 0.9, 0.1)))
	it.append(BMG.item(box1, Vector3(0, 7.2, 0), mat_metal, Vector3(0, SCALE_YAW, 0), Vector3(0.24, 0.1, 0.5)))
	it.append(BMG.item(box1, Vector3(0, 4.12, -0.48), mat_metal, Vector3.ZERO, Vector3(1.05, 0.09, 0.09)))
	_merged("MastParts", "mast", it, _mast)
	# The balance scale: a silver beam on the pivot with a crystal pointer; the pans hang from its ends and stay level.
	_beam = Node3D.new()
	_beam.name = "ScaleBeam"
	_beam.position = Vector3(0, PIVOT_Y, 0)
	_beam.rotation.y = deg_to_rad(SCALE_YAW)
	_mast.add_child(_beam)
	it = []
	it.append(BMG.item(box1, Vector3.ZERO, mat_metal, Vector3.ZERO, Vector3(BEAM_HALF * 2.0 + 0.12, 0.15, 0.16)))
	it.append(BMG.item(_prism(Vector3(BEAM_HALF * 1.6, 0.16, 0.12), 0.5), Vector3(0, -0.15, 0), mat_metal,
		Vector3(0, 0, 180)))
	it.append(BMG.item(_cyl(0.14, 0.14, 0.34, 8), Vector3.ZERO, mat_metal, Vector3(90, 0, 0)))
	it.append(BMG.item(IceShapes.crystal(0.09, 0.14, 0.34, 0.0, 4), Vector3(0, 0.07, 0), mat_team))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, Vector3(sx * BEAM_HALF, 0, 0), mat_metal, Vector3(0, 0, 45), Vector3(0.19, 0.19, 0.19)))
	_merged("BeamParts", "beam", it, _beam, false)
	_pan_l = _make_pan("PanL", -BEAM_HALF, true)
	_pan_r = _make_pan("PanR", BEAM_HALF, false)
	_gem = _part("MastGem", IceShapes.crystal(0.32, 0.0, 0.46, 0.46, 4), Vector3(0, GEM_Y, 0), mat_glow, Vector3.ZERO,
		_mast)
	_gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mast_banner := _banner("MastBanner", Vector2(0.85, 2.0), Vector3(0, 3.07, -0.54), 0.0, _mast)
	_falling = _mast
	_fall_axis = Vector3.BACK
	_fall_deg = -35.0
	_hide_below_50.append(_gem)
	_hide_below_25.append(mast_banner)
	var banner_l := _banner("BannerL", Vector2(0.72, 1.55), bp + Vector3(0, 2.52, -0.1), 0.0)
	_hide_on_collapse.append_array([mast_banner, banner_l])
	# No active light: the base class drives _light, so it exists but stays hidden.
	_light = _omni(Vector3(HX, 2.2, -1.5), 6.0)
	_light.visible = false
	# Idle particles (~22): snow motes falling around the gem, frost mist at the feet.
	var motes := _pm(Vector3.DOWN, 40.0, 0.3, 0.6, Vector3(0, -0.3, 0), 0.12, 0.06,
		_ramp(Color(0.9, 0.97, 1.0), Color(0.6, 0.85, 1.0), false))
	motes.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 1.2
	_idle_fx.append(_particles("SnowMotes", _mast, Vector3(0, GEM_Y - 0.3, 0), 14, 3.0, motes, _add_quad, false))
	var mist := _pm(Vector3(1, 0, 0), 180.0, 0.1, 0.25, Vector3.ZERO, 1.2, 2.4,
		_ramp(Color(0.85, 0.92, 1.0, 0.16), Color(0.85, 0.92, 1.0), false))
	mist.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mist.emission_ring_axis = Vector3.UP
	mist.emission_ring_radius = 3.4
	mist.emission_ring_inner_radius = 2.6
	mist.emission_ring_height = 0.05
	_idle_fx.append(_particles("FrostMist", self, Vector3(0, 0.35, 0), 8, 6.0, mist, _mix_quad, false))
	# Delivery glints (one-shot): gold sparks rising from the gold pan and bursting off the coin emblem.
	var gold_ramp: GradientTexture1D = _ramp(Color(1.0, 0.92, 0.55), Color(1.0, 0.7, 0.2), false)
	var gp := _pm(Vector3.UP, 45.0, 0.8, 1.7, Vector3(0, -1.5, 0), 0.16, 0.04, gold_ramp)
	gp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	gp.emission_sphere_radius = 0.25
	_glint_pan = _particles("PanGlint", _pan_l, Vector3(0, -PAN_DROP + 0.2, 0), 16, 0.9, gp, _add_quad, true)
	var gc := _pm(Vector3(0, 0.3, -1), 70.0, 0.6, 1.4, Vector3(0, -1.0, 0), 0.2, 0.05, gold_ramp)
	gc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	gc.emission_sphere_radius = 0.45
	_glint_coin = _particles("CoinGlint", _body, COIN_POS + Vector3(0, 0, -0.15), 14, 0.8, gc, _add_quad, true)
	# Construction scaffolding (around the house), the collapse wreck (house stubs + the mast stump), frost patch.
	_build_scaffold(HX, HZ, 4.3, 3.1, 3.2)
	_build_wreck(HX, HZ, 3.9, 2.8, PLINTH_TOP + (PT + WALL_H - PLINTH_TOP) * 0.3, Vector3(MAST.x, 1.2, MAST.z),
		Vector3(0.75, 1.4, 0.75), 10333)
	var decal := get_node_or_null(^"ContactDecal") as MeshInstance3D
	if decal:
		_frost_mat = ShaderMaterial.new()
		_frost_mat.shader = FROST_GROUND
		_frost_mat.set_shader_parameter(&"size", 10.0)
		_frost_mat.set_shader_parameter(&"plinth_half", 3.2)
		_frost_mat.set_shader_parameter(&"sectors", 16.0)
		_frost_mat.set_shader_parameter(&"seed", 3.1)
		_frost_mat.set_shader_parameter(&"glow_color", glow_color)
		decal.material_override = _frost_mat
	# State particle anchors, lost-canopy rubble (broken ice around the stall), the gate (caravans leave here).
	_smoke_points = [hole_l + Vector3(0, 0.3, 0), Vector3(2.05, 2.4, -1.55)]
	_blaze_points = [hole_r + Vector3(0, 0.2, 0), Vector3(-1.5, 1.6, -2.1)]
	_rubble2_points = [Vector3(-2.5, PT + 0.2, -2.95), Vector3(-0.7, PT + 0.2, -3.0), Vector3(-2.75, PT + 0.2, -1.4),
		Vector3(-0.35, PT + 0.2, -1.55)]
	_gate_pos = Vector3(0.3, 1.3, -3.0)


## A sledge along local X (curled runners at +X), bed top ~0.49. Appended to `items`.
func _sled(items: Array, length: float, width: float) -> void:
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var hw: float = width * 0.5
	var tip: float = length * 0.5
	for s: float in [-1.0, 1.0]:
		var z: float = s * (hw - 0.06)
		items.append(BMG.item(box1, Vector3(-0.1, 0.05, z), mat_metal, Vector3.ZERO, Vector3(length - 0.2, 0.1, 0.1)))
		items.append(BMG.item(box1, Vector3(tip - 0.08, 0.2, z), mat_metal, Vector3(0, 0, 50), Vector3(0.42, 0.1, 0.1)))
		items.append(BMG.item(box1, Vector3(tip - 0.02, 0.44, z), mat_metal, Vector3(0, 0, 100), Vector3(0.24, 0.1, 0.1)))
		for x: float in [-length * 0.35, 0.0, length * 0.3]:
			items.append(BMG.item(box1, Vector3(x - 0.1, 0.25, z), mat_dark, Vector3.ZERO, Vector3(0.1, 0.32, 0.1)))
		items.append(BMG.item(box1, Vector3(-0.1, 0.56, s * (hw - 0.04)), mat_dark, Vector3.ZERO,
			Vector3(length - 0.25, 0.16, 0.08)))
	items.append(BMG.item(box1, Vector3(-0.1, 0.44, 0), mat_dark, Vector3.ZERO, Vector3(length - 0.2, 0.1, width)))


## A frosted crate (warm planks, a silver band, a snow cap) of side `size` centred at `pos`, turned `yaw` degrees.
func _crate(items: Array, pos: Vector3, yaw: float, size: float) -> void:
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var r := Vector3(0, yaw, 0)
	items.append(BMG.item(box1, pos, mat_fur, r, Vector3.ONE * size))
	items.append(BMG.item(box1, pos, mat_metal, r, Vector3(size + 0.03, 0.07, size + 0.03)))
	items.append(BMG.item(box1, pos + Vector3(0, size * 0.5 + 0.02, 0), mat_snow, r, Vector3(size * 0.88, 0.06, size * 0.88)))


## A scale pan hanging from the beam end at `x` (three silver rods to a dish; gold heap or ice block in it).
func _make_pan(nm: String, x: float, gold: bool) -> Node3D:
	var pan := Node3D.new()
	pan.name = nm
	pan.position = Vector3(x, -0.02, 0)
	_beam.add_child(pan)
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var it: Array = []
	for i: int in 3:
		var a: float = TAU * float(i) / 3.0 + PI * 0.5
		it.append(_rod(Vector3.ZERO, Vector3(cos(a) * 0.36, -PAN_DROP + 0.06, sin(a) * 0.36), 0.025, mat_metal))
	it.append(BMG.item(_cyl(0.48, 0.34, 0.13, 10), Vector3(0, -PAN_DROP, 0), mat_metal))
	if gold:
		it.append(BMG.item(IceShapes.mound(), Vector3(0, -PAN_DROP + 0.06, 0), mat_gold, Vector3.ZERO,
			Vector3(0.36, 0.27, 0.36)))
		it.append(BMG.item(_cyl(0.12, 0.12, 0.04, 8), Vector3(0.14, -PAN_DROP + 0.3, 0.06), mat_gold, Vector3(30, 0, 20)))
	else:
		it.append(BMG.item(box1, Vector3(0, -PAN_DROP + 0.26, 0), mat_team, Vector3(0, 25, 0), Vector3(0.4, 0.38, 0.4)))
		it.append(BMG.item(IceShapes.crystal(0.09, 0.1, 0.24, 0.0), Vector3(0.05, -PAN_DROP + 0.45, 0.03), mat_team,
			Vector3(0, 0, 10)))
	_merged(nm + "Parts", nm.to_lower(), it, pan, false)
	return pan


## A thin 4-sided rod from `a` to `b` (radius r) as a merge item.
func _rod(a: Vector3, b: Vector3, r: float, mat: Material) -> Array:
	var d: Vector3 = b - a
	var l: float = d.length()
	var y: Vector3 = d / l
	var axis: Vector3 = Vector3.UP.cross(y)
	var bs := Basis.IDENTITY
	if axis.length() > 0.0001:
		bs = Basis(axis.normalized(), Vector3.UP.angle_to(y))
	elif y.y < 0.0:
		bs = Basis(Vector3.RIGHT, PI)
	return BMG.item_xf(_cyl(r, r, l, 4), Transform3D(bs, (a + b) * 0.5), mat)


## Broken ice (the torn stall) is crystal, not dark stone.
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

