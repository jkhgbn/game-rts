class_name FireMarketModel
extends FireHallModel
## Visual model of the Fire kingdom's market, the Ember Bazaar (task 10.V1, docs/design/market-trade.md 4.1 + 9,
## style art-keep.md 0). Read from the RTS camera: a squat stone counting-house with a hip roof in the team colour,
## pierced by a tall bronze mast (the dominant vertical) crowned with an ember beacon; from the mast's yardarm hangs a
## big balance scale (beam at ~6.9 m, one pan heaped with glowing gold, the other holding an ember crystal) beside a team
## coin medallion and a waving team banner. Asymmetric secondary: a striped awning stall in the team colour on the
## gate side (counter, cloth bolts, ingots, jars), a crate stack with a team tarp and a barrel on one side of the
## house, a roaring brazier and grain sacks on the other.
## Same hooks and state machine as FireHallModel (fire_hall.gd, art-keep.md 8.8): set_team_color,
## set_construction_progress, set_health_ratio (smoke + torn awning flap + lost medallion + jammed scale < 50 %,
## fire + burnt awning hole + lost banner < 25 %), play_training_pulse (a caravan leaves: the gold glints),
## play_destroyed (-> destroyed_finished after 3 s; the mast topples, the wreck shows the fallen scale and spilled
## gold), set_selected. Market hook: play_delivery() (the scale tips toward the gold pan and rocks back, the coins
## glint and sparkle). All hooks are safe before _ready.
## Footprint 3 x 3 cells (6 x 6 m), gate local -Z (Building turns it toward the map centre). The camera sees the
## local +X side (player) or -X side (enemy), so everything that must read is on the local x = 0 line or duplicated:
## the scale beam runs along local Z (broadside to both cameras). Everything below 2.5 m stays within 3.3 m of the
## centre; above it, the scale pans and yardarm overhang at most ~0.7 m.
## No real light: the base class drives a virtual OmniLight3D that is never added to the tree; its flicker drives an
## additive fake light pool on the plinth. Parts are merged per tier (BuildingMerge, one surface per material).

const GOLD_GLOW := Color(1.0, 0.72, 0.2)
const DELIVERY_TIME := 1.8
const DELIVERY_TIP_DEG := 18.0
const IDLE_TILT_DEG := 3.0     ## the gold side is heavier
const JAM_TILT_DEG := 11.0     ## below 50 % HP the scale hangs crooked
## Counting-house centre (x, z). A little toward local -X: the far side from the player's camera (the player's own
## Bazaar is the one seen most), so the mast, yardarm and scale beam rise clear of the roofline in silhouette.
const HOUSE := Vector3(-0.3, 0.0, 1.8)
const HOUSE_HALF := Vector2(1.3, 1.2)      ## half-size (x, z)
const WALL_TOP := 3.2
const MAST_POS := Vector3(-0.3, 0.8, 1.8)  ## mast base (in the house), Body space
const MAST_TOP := 7.9                       ## column top, mast space (world 8.7); the beacon sits on it (~9.6)
const ARM_Y := 6.78                         ## yardarm height, mast space (world 7.58)
const PIVOT := Vector3(0.0, 6.65, -2.6)     ## scale hook, mast space (world y 7.45, z -0.8)
const BEAM_DROP := 0.55                     ## hook -> beam (beam at world y ~6.9)
const BEAM_HALF := 1.3
const PAN_DROP := 0.95
const BRAZIER := Vector3(-2.3, 0.8, 2.35)
# Awning: 6 stripes along x, a lean-to from the house wall (back) to the front edge, sagging a little in the middle.
const AW_X0 := -2.4
const AW_N := 6
const AW_W := 0.8
const AW_BACK := Vector2(0.6, 3.2)     ## (z, y)
const AW_MID := Vector2(-1.0, 3.0)
const AW_FRONT := Vector2(-2.6, 2.86)
## Light stripe of every Bazaar awning (cream canvas): the team stripes change colour, this one never does, so the
## awning reads as "market" (and apart from the team roofs) from the RTS camera.
const CANVAS := Color(0.93, 0.83, 0.62)

var mat_stripe: ShaderMaterial
var _scale_pivot: Node3D
var _beam: Node3D
var _pans: Array[Node3D] = []
var _pool: MeshInstance3D
var _pool_mat: StandardMaterial3D
var _glint: GPUParticles3D
var _deliver_t: float = -1.0
var _tilt: float = 0.0


func _setup_palette() -> void:
	light_energy = 1.0   # the virtual light's energy is read back as a 0..1+ flicker for the fake pool


## Base materials + the awning's second stripe; the "gate" glow becomes the gold (coins, windows).
func _make_materials() -> void:
	super()
	mat_stripe = _painted_mat(CANVAS, 0.05, 0.0)
	mat_gate.set_shader_parameter(&"glow_color", GOLD_GLOW)
	mat_gate.set_shader_parameter(&"rune_bands", 0)
	mat_gate.set_shader_parameter(&"energy", 1.1)
	mat_gate.set_shader_parameter(&"pulse_speed", 1.7)


func _process(delta: float) -> void:
	super(delta)
	if _pool and _ready_done and _light:
		var c: Color = _pool_mat.albedo_color
		c.a = clampf(0.22 * _light.light_energy / maxf(light_energy, 0.01), 0.0, 0.9)
		_pool_mat.albedo_color = c


func _notification(what: int) -> void:
	# The virtual light never enters the tree: free it with the model.
	if what == NOTIFICATION_PREDELETE and _light != null and is_instance_valid(_light) and not _light.is_inside_tree():
		_light.free()


# --- Hooks (market) ---

## Gold delivered: the scale tips toward the gold pan and rocks back (1.8 s), the coins glint and sparkle.
## Restarts if retriggered. Ignored on a site, a wreck or before _ready.
func play_delivery() -> void:
	if _destroyed or not _ready_done or _progress < 1.0:
		return
	_deliver_t = 0.0
	_fire(_glint)


## Current tilt of the scale beam in degrees (positive = the gold pan is down). For tests and tools.
func get_scale_tilt() -> float:
	return rad_to_deg(_tilt)


func set_construction_progress(p: float) -> void:
	super(p)
	if _pool:
		_pool.visible = _progress >= 1.0 and not _destroyed
	if _progress < 1.0:
		_deliver_t = -1.0


# --- Idle motion: the scale sways on its hook, the beam rocks, the pans hang plumb ---

func _idle_motion(delta: float) -> void:
	if _scale_pivot == null:
		return
	var sway: float = deg_to_rad(1.5) * sin(_t * 1.1) + deg_to_rad(0.5) * sin(_t * 2.7 + 1.0)
	var tilt_deg: float = IDLE_TILT_DEG + 1.6 * sin(_t * 0.8 + 0.6)
	if _health_ratio < 0.5 and _progress >= 1.0:
		tilt_deg = JAM_TILT_DEG + 0.6 * sin(_t * 3.1)
	if _deliver_t >= 0.0:
		_deliver_t += delta
		var k: float = _deliver_t
		var tip: float
		if k < 0.22:
			tip = DELIVERY_TIP_DEG * sin(k / 0.22 * PI * 0.5)
		else:
			tip = DELIVERY_TIP_DEG * exp(-2.3 * (k - 0.22)) * cos(5.2 * (k - 0.22))
		tilt_deg += tip
		sway += deg_to_rad(4.0) * exp(-2.0 * k) * sin(k * 7.0)
		mat_gate.set_shader_parameter(&"boost", (1.0 + 2.5 * exp(-2.2 * k)) * _sel_boost())
		if _deliver_t >= DELIVERY_TIME:
			_deliver_t = -1.0
			mat_gate.set_shader_parameter(&"boost", _sel_boost())
	_tilt = deg_to_rad(tilt_deg)
	_scale_pivot.transform = Transform3D(Basis(Vector3.RIGHT, sway), PIVOT)
	_beam.transform = Transform3D(Basis(Vector3.RIGHT, _tilt), Vector3(0.0, -BEAM_DROP, 0.0))
	var plumb := Basis(Vector3.RIGHT, -sway)
	for i: int in _pans.size():
		var end := Vector3(0.0, 0.0, BEAM_HALF if i == 0 else -BEAM_HALF)
		_pans[i].transform = Transform3D(plumb, _beam.transform * end)


# --- Structure ---

func _build_structure() -> void:
	_top_y = 9.4
	# Virtual light: the base class writes its energy (flicker, training x2, collapse flash); never in the tree.
	_light = OmniLight3D.new()
	_light.name = "VirtualLight"
	_light.light_energy = light_energy
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 10101
	_build_plinth(box1, rng)
	_build_house(box1)
	_build_roof(box1)
	var awning := _build_awning(box1)
	_build_stall(box1, rng)
	var crates := _build_crates(box1)
	_build_brazier(box1)
	var mast := _build_mast(box1)
	# Light pool (fake warm light on the plinth under the awning and around the brazier).
	_build_pool()
	# Construction scaffolding around the house, the wreck (house stubs, mast stump, fallen scale, spilled gold).
	_build_scaffold(HOUSE.x, HOUSE.z, 3.1, 2.9, 3.4)
	_build_wreck(HOUSE.x, HOUSE.z, HOUSE_HALF.x * 2.0, HOUSE_HALF.y * 2.0, 0.8 + (WALL_TOP - 0.8) * 0.3,
		Vector3(MAST_POS.x, 1.5, MAST_POS.z), Vector3(0.7, 1.4, 0.7), 1010)
	_build_wreck_extra(box1)
	_scorch_decal(Vector3(BRAZIER.x + 0.2, 0.84, BRAZIER.z - 0.1), 2.0)
	# Collapse: the mast topples backwards (+Z, away from the stall), the stall cloth and crates go at 1.6 s.
	_falling = mast
	_fall_axis = Vector3.RIGHT
	_fall_deg = 36.0
	_hide_on_collapse.append_array([awning, crates])
	# State anchors (smoke from the roof and the awning, flames from the burnt awning hole and the roof).
	_smoke_points = [Vector3(0.7, 4.5, 1.2), Vector3(0.6, 3.3, -1.3)]
	_blaze_points = [Vector3(AW_X0 + AW_W * 1.5, _aw_y(-1.2) + 0.25, -1.2), Vector3(HOUSE.x - 0.6, 4.2, 2.4)]
	_rubble2_points = [Vector3(2.7, 0.9, -2.8), Vector3(2.3, 0.9, -3.0), Vector3(3.0, 0.5, -2.1),
		Vector3(-2.9, 0.5, -2.7)]
	_gate_pos = Vector3(0.0, 1.5, -3.0)


## Two dark tiers, raised corner blocks at the free front corners, a stone kerb and loose flags in front of the stall.
func _build_plinth(box1: BoxMesh, rng: RandomNumberGenerator) -> void:
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, 0.25, 0), mat_dark, Vector3.ZERO, Vector3(6.4, 0.5, 6.4)))
	it.append(BMG.item(box1, Vector3(0, 0.65, 0), mat_dark, Vector3.ZERO, Vector3(5.8, 0.3, 5.8)))
	for c: Vector2 in [Vector2(1, -1), Vector2(-1, -1)]:
		it.append(BMG.item(box1, Vector3(c.x * 2.72, 0.95, c.y * 2.72), mat_dark, Vector3.ZERO, Vector3(0.7, 0.4, 0.7)))
	# A worn stone kerb along the front edge of the stall (the "shop floor" line), a few loose flags.
	it.append(BMG.item(box1, Vector3(-0.1, 0.84, -2.78), mat_stone, Vector3.ZERO, Vector3(5.2, 0.1, 0.24)))
	for i: int in 3:
		var p := Vector3(-1.6 + 1.5 * i + rng.randf_range(-0.2, 0.2), 0.84, -3.0 + rng.randf_range(-0.05, 0.05))
		it.append(BMG.item(box1, p, mat_stone, Vector3(0, rng.randf_range(-12, 12), 0), Vector3(0.6, 0.08, 0.3)))
	_merged("PlinthBase", "plinth", it)


## The counting-house: stone walls on a dark base course, dark corner pillars, a bronze top band, a door into the
## stall (-Z) and a warm gold window on each side face (+X / -X, one per camera).
func _build_house(box1: BoxMesh) -> void:
	var it: Array = []
	var hx: float = HOUSE.x
	var hz: float = HOUSE.z
	var h: float = WALL_TOP - 0.8
	it.append(BMG.item(box1, Vector3(hx, 0.8 + h * 0.5, hz), mat_stone, Vector3.ZERO,
		Vector3(HOUSE_HALF.x * 2.0, h, HOUSE_HALF.y * 2.0)))
	it.append(BMG.item(box1, Vector3(hx, 0.98, hz), mat_dark, Vector3.ZERO,
		Vector3(HOUSE_HALF.x * 2.0 + 0.2, 0.36, HOUSE_HALF.y * 2.0 + 0.2)))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			it.append(BMG.item(box1, Vector3(hx + sx * HOUSE_HALF.x, 0.8 + (h + 0.1) * 0.5, hz + sz * HOUSE_HALF.y), mat_dark,
				Vector3.ZERO, Vector3(0.46, h + 0.1, 0.46)))
	it.append(BMG.item(box1, Vector3(hx, WALL_TOP + 0.05, hz), mat_metal, Vector3.ZERO,
		Vector3(HOUSE_HALF.x * 2.0 + 0.3, 0.22, HOUSE_HALF.y * 2.0 + 0.3)))
	# Door on the stall side.
	var fz: float = hz - HOUSE_HALF.y
	it.append(BMG.item(box1, Vector3(hx, 1.7, fz - 0.03), mat_dark, Vector3.ZERO, Vector3(1.25, 1.8, 0.14)))
	it.append(BMG.item(box1, Vector3(hx, 1.6, fz - 0.09), _hole_mat(), Vector3.ZERO, Vector3(0.85, 1.55, 0.06)))
	it.append(BMG.item(box1, Vector3(hx, 2.68, fz - 0.1), mat_metal, Vector3.ZERO, Vector3(1.4, 0.22, 0.24)))
	# Side windows (gold glow) with bronze sills.
	for sx: float in [-1.0, 1.0]:
		var wx: float = hx + sx * HOUSE_HALF.x
		it.append(BMG.item(box1, Vector3(wx + sx * 0.05, 2.25, hz), mat_dark, Vector3.ZERO, Vector3(0.16, 0.95, 0.85)))
		it.append(BMG.item(box1, Vector3(wx + sx * 0.1, 2.25, hz), mat_gate, Vector3.ZERO, Vector3(0.08, 0.62, 0.52)))
		it.append(BMG.item(box1, Vector3(wx + sx * 0.12, 1.72, hz), mat_metal, Vector3.ZERO, Vector3(0.24, 0.12, 0.95)))
		# A bronze grille bar across the window (strongroom).
		it.append(BMG.item(box1, Vector3(wx + sx * 0.14, 2.25, hz), mat_metal, Vector3.ZERO, Vector3(0.06, 0.62, 0.08)))
	_merged("House", "house", it)


## Hip roof in the team colour: a flared skirt, a bronze band, the main pyramid and a cap collar around the mast.
func _build_roof(box1: BoxMesh) -> void:
	var it: Array = []
	var zk: float = HOUSE_HALF.y / HOUSE_HALF.x
	var sc := Vector3(1.0, 1.0, zk)
	var c := Vector3(HOUSE.x, 0.0, HOUSE.z)
	var r_skirt: float = HOUSE_HALF.x * 1.36 * sqrt(2.0)
	var r_main: float = r_skirt * 0.8
	it.append(BMG.item(_cyl(r_skirt * 0.84, r_skirt, 0.38, 4), c + Vector3(0, 3.5, 0), mat_team, Vector3(0, 45, 0), sc))
	it.append(BMG.item(_cyl(r_skirt * 0.86, r_skirt * 0.86, 0.12, 4), c + Vector3(0, 3.74, 0), mat_metal,
		Vector3(0, 45, 0), sc))
	it.append(BMG.item(_cyl(0.4, r_main, 1.2, 4), c + Vector3(0, 4.4, 0), mat_team, Vector3(0, 45, 0), sc))
	it.append(BMG.item(_cyl(0.5, 0.56, 0.18, 4), c + Vector3(0, 5.06, 0), mat_metal, Vector3(0, 45, 0), sc))
	# Bronze hip ridges on the 4 edges of the main pyramid (corners on the diagonals).
	var h: float = sqrt(0.5)
	for k: int in 4:
		var d := Vector3(h if k % 2 == 0 else -h, 0.0, (h if k < 2 else -h) * zk)
		var a := c + Vector3(0, 3.84, 0) + d * r_main
		var b := c + Vector3(0, 5.02, 0) + d * 0.4
		it.append(BMG.item_xf(box1, _slab(a, b, 0.17, 0.15), mat_metal))
	_merged("Roof", "roof", it)


## Awning height (y of the cloth's centre line) at depth z.
func _aw_y(z: float) -> float:
	if z >= AW_MID.x:
		return lerpf(AW_MID.y, AW_BACK.y, (z - AW_MID.x) / (AW_BACK.x - AW_MID.x))
	return lerpf(AW_FRONT.y, AW_MID.y, (z - AW_FRONT.x) / (AW_MID.x - AW_FRONT.x))


## Striped lean-to awning: 6 cloth stripes (team / stripe colour, two sagging segments each), a scalloped valance on
## the front and both sides. The +X end stripe and its side valance are a separate flap (torn below 50 % HP); a burnt
## hole shows below 25 %.
func _build_awning(box1: BoxMesh) -> MeshInstance3D:
	var main: Array = []
	var flap: Array = []
	for i: int in AW_N:
		var xc: float = AW_X0 + AW_W * (i + 0.5)
		var m: ShaderMaterial = mat_team if i % 2 == 0 else mat_stripe
		var dst: Array = flap if i == AW_N - 1 else main
		dst.append(BMG.item_xf(box1, _slab(Vector3(xc, AW_BACK.y, AW_BACK.x), Vector3(xc, AW_MID.y, AW_MID.x),
			AW_W + 0.02, 0.08), m))
		dst.append(BMG.item_xf(box1, _slab(Vector3(xc, AW_MID.y, AW_MID.x), Vector3(xc, AW_FRONT.y, AW_FRONT.x - 0.04),
			AW_W + 0.02, 0.08), m))
		# Front scallop (points down), in the other colour so the edge reads as a trim.
		var vm: ShaderMaterial = mat_stripe if i % 2 == 0 else mat_team
		dst.append(BMG.item(_prism(Vector3(AW_W, 0.42, 0.05), 0.5), Vector3(xc, AW_FRONT.y - 0.23, AW_FRONT.x - 0.06),
			vm, Vector3(0, 0, 180)))
	# Side valances: 4 scallops per side following the slope.
	for side: int in 2:
		var x: float = AW_X0 - 0.03 if side == 0 else AW_X0 + AW_W * AW_N + 0.03
		var n: int = 4
		var span: float = AW_BACK.x - AW_FRONT.x
		for k: int in n:
			var z: float = AW_FRONT.x + span * (k + 0.5) / n
			var vm: ShaderMaterial = mat_stripe if k % 2 == 0 else mat_team
			var dst: Array = main if side == 0 else flap
			dst.append(BMG.item(_prism(Vector3(span / n, 0.38, 0.05), 0.5), Vector3(x, _aw_y(z) - 0.21, z), vm,
				Vector3(0, 90, 180)))
	var awning := _merged("Awning", "awning", main)
	var flap_mi := _merged("AwningFlap", "awning_flap", flap, awning)
	_hide_below_50.append(flap_mi)
	# Torn flap (< 50 %): a ragged back remnant and two strips dangling from it, one loose valance scallop.
	var torn: Array = []
	var xf0: float = AW_X0 + AW_W * (AW_N - 0.5)
	var zc: float = -0.35
	torn.append(BMG.item_xf(box1, _slab(Vector3(xf0, AW_BACK.y, AW_BACK.x), Vector3(xf0, _aw_y(zc), zc), AW_W, 0.08),
		mat_team))
	for s: float in [-1.0, 1.0]:
		var top := Vector3(xf0 + s * 0.22, _aw_y(zc) - 0.02, zc + 0.05)
		var bot := top + Vector3(s * 0.12, -1.05, -0.28 - 0.12 * s)
		torn.append(BMG.item_xf(box1, _slab(top, bot, 0.36, 0.06), mat_team))
	torn.append(BMG.item(_prism(Vector3(0.8, 0.38, 0.05), 0.5), Vector3(AW_X0 + AW_W * AW_N + 0.05, 2.5, -1.6), mat_stripe,
		Vector3(20, 90, 160)))
	var torn_mi := _merged("AwningTorn", "awning_torn", torn, awning, false)
	torn_mi.visible = false
	_show_below_50.append(torn_mi)
	# Burnt hole (< 25 %): dark scorched patch with glowing edges on the second stripe.
	var burn: Array = []
	var bx: float = AW_X0 + AW_W * 1.5
	var bz: float = -1.2
	var off := Vector3(0, 0.07, 0)
	burn.append(BMG.item_xf(box1, _slab(Vector3(bx, _aw_y(bz + 0.45), bz + 0.45) + off,
		Vector3(bx, _aw_y(bz - 0.45), bz - 0.45) + off, 0.95, 0.04), mat_glow))
	burn.append(BMG.item_xf(box1, _slab(Vector3(bx, _aw_y(bz + 0.34), bz + 0.34) + off * 1.4,
		Vector3(bx, _aw_y(bz - 0.34), bz - 0.34) + off * 1.4, 0.7, 0.04), _hole_mat()))
	var burn_mi := _merged("AwningBurn", "awning_burn", burn, awning, false)
	burn_mi.visible = false
	_show_below_25.append(burn_mi)
	return awning


## The stall under the awning: posts with spear tips, beams, a stone counter with a bronze top and a team drape,
## wares (cloth bolts, ingots, jars) and a front display (pots, a basket of cloth); sacks by the house.
func _build_stall(box1: BoxMesh, rng: RandomNumberGenerator) -> void:
	var it: Array = []
	var fz: float = AW_FRONT.x + 0.12
	for x: float in [AW_X0 + 0.15, AW_X0 + AW_W * AW_N - 0.15]:
		it.append(BMG.item(box1, Vector3(x, 2.1, fz), mat_metal, Vector3.ZERO, Vector3(0.24, 2.6, 0.24)))
		it.append(BMG.item(_cyl(0.0, 0.2, 0.5, 6), Vector3(x, 3.65, fz), mat_metal))
		it.append(BMG.item(_cyl(0.2, 0.2, 0.12, 6), Vector3(x, 3.36, fz), mat_dark))
		it.append(BMG.item(box1, Vector3(x, 1.975, AW_BACK.x - 0.05), mat_metal, Vector3.ZERO, Vector3(0.24, 2.35, 0.24)))
	it.append(BMG.item(box1, Vector3(0.0, _aw_y(fz) - 0.15, fz), mat_metal, Vector3.ZERO, Vector3(4.9, 0.2, 0.2)))
	it.append(BMG.item(box1, Vector3(0.0, AW_BACK.y - 0.14, AW_BACK.x - 0.05), mat_metal, Vector3.ZERO,
		Vector3(4.9, 0.2, 0.2)))
	# Two small ember lanterns hanging from the front beam (warm the stall; hidden by the cloth from high up).
	for x: float in [-1.3, 1.1]:
		var ly: float = _aw_y(fz) - 0.5
		it.append(BMG.item(box1, Vector3(x, ly + 0.2, fz), mat_dark, Vector3.ZERO, Vector3(0.05, 0.2, 0.05)))
		it.append(BMG.item(_cyl(0.12, 0.2, 0.1, 6), Vector3(x, ly + 0.08, fz), mat_dark))
		it.append(BMG.item(box1, Vector3(x, ly - 0.12, fz), mat_glow, Vector3(0, 45, 0), Vector3(0.24, 0.3, 0.24)))
	# Counter.
	var cz: float = -2.25
	it.append(BMG.item(box1, Vector3(-0.1, 1.22, cz), mat_dark, Vector3.ZERO, Vector3(3.8, 0.84, 0.7)))
	it.append(BMG.item(box1, Vector3(-0.1, 1.71, cz - 0.04), mat_metal, Vector3.ZERO, Vector3(3.95, 0.14, 0.9)))
	it.append(BMG.item(box1, Vector3(-0.1, 1.36, cz - 0.38), mat_team, Vector3.ZERO, Vector3(3.6, 0.5, 0.05)))
	for k: int in 6:
		var m: ShaderMaterial = mat_stripe if k % 2 == 0 else mat_team
		it.append(BMG.item(_prism(Vector3(0.6, 0.26, 0.05), 0.5), Vector3(-1.7 + 0.6 * k, 0.98, cz - 0.39), m,
			Vector3(0, 0, 180)))
	# Wares on the counter (top 1.78).
	it.append(BMG.item(_cyl(0.2, 0.2, 0.85, 8), Vector3(-1.45, 1.98, cz - 0.15), mat_team, Vector3(0, 0, 90)))
	it.append(BMG.item(_cyl(0.2, 0.2, 0.85, 8), Vector3(-1.45, 1.98, cz + 0.25), mat_stripe, Vector3(0, 0, 90)))
	it.append(BMG.item(_cyl(0.2, 0.2, 0.85, 8), Vector3(-1.42, 2.32, cz + 0.05), mat_team, Vector3(0, 0, 90)))
	for k: int in 3:
		it.append(BMG.item(box1, Vector3(-0.3 + 0.05 * k, 1.87 + (0.16 if k == 2 else 0.0), cz - 0.12 + 0.26 * (k % 2)),
			mat_metal, Vector3(0, rng.randf_range(-15, 15), 0), Vector3(0.44, 0.16, 0.24)))
	it.append(BMG.item(_cyl(0.13, 0.22, 0.5, 8), Vector3(0.75, 2.03, cz - 0.1), mat_dark))
	it.append(BMG.item(_cyl(0.1, 0.17, 0.38, 8), Vector3(1.15, 1.97, cz + 0.15), mat_stone))
	it.append(BMG.item(box1, Vector3(1.45, 1.96, cz - 0.12), mat_metal, Vector3(0, 12, 0), Vector3(0.5, 0.34, 0.38)))
	it.append(BMG.item(box1, Vector3(1.45, 2.16, cz - 0.12), mat_team, Vector3(0, 12, 0), Vector3(0.54, 0.08, 0.42)))
	# Front display on the plinth: two big pots and a basket of cloth.
	it.append(BMG.item(_cyl(0.2, 0.34, 0.62, 8), Vector3(-1.1, 1.11, -2.95), mat_stone))
	it.append(BMG.item(_cyl(0.26, 0.2, 0.12, 8), Vector3(-1.1, 1.47, -2.95), mat_stone))
	it.append(BMG.item(_cyl(0.16, 0.28, 0.5, 8), Vector3(-0.5, 1.05, -3.0), mat_dark))
	it.append(BMG.item(_cyl(0.38, 0.3, 0.36, 8), Vector3(0.7, 0.98, -2.82), mat_metal))
	it.append(BMG.item(_sph(0.3), Vector3(0.62, 1.2, -2.82), mat_team, Vector3.ZERO, Vector3(1.0, 0.5, 1.0)))
	it.append(BMG.item(_sph(0.24), Vector3(0.86, 1.22, -2.77), mat_stripe, Vector3.ZERO, Vector3(1.0, 0.6, 1.0)))
	# Grain sacks by the house (-X side, beside the brazier).
	for p: Vector3 in [Vector3(-2.45, 1.08, 0.95), Vector3(-2.55, 1.04, 1.5), Vector3(-2.5, 1.48, 1.22)]:
		it.append(BMG.item(_sph(0.38), p, mat_stone, Vector3(rng.randf_range(-10, 10), rng.randf() * 90.0, 0),
			Vector3(1.0, 0.78, 0.9)))
		it.append(BMG.item(_cyl(0.07, 0.12, 0.16, 6), p + Vector3(0, 0.32, 0), mat_metal))
	_merged("Stall", "stall", it)


## Crate stack on the +X side of the house: two big crates, two on top (one under a team tarp), a barrel.
func _build_crates(box1: BoxMesh) -> MeshInstance3D:
	var it: Array = []
	var crates: Array[Vector4] = [Vector4(2.3, 0.8, 1.3, 1.0), Vector4(2.35, 0.8, 2.35, 0.85)]
	var tops: Array[Vector4] = [Vector4(2.28, 1.8, 1.4, 0.76), Vector4(2.42, 1.65, 2.4, 0.56)]
	var yaws: Array[float] = [4.0, -8.0, -14.0, 20.0]
	var all: Array[Vector4] = []
	all.append_array(crates)
	all.append_array(tops)
	for i: int in all.size():
		var c: Vector4 = all[i]
		var s: float = c.w
		var base := Vector3(c.x, c.y + s * 0.5, c.z)
		var rot := Vector3(0, yaws[i], 0)
		it.append(BMG.item(box1, base, mat_metal, rot, Vector3.ONE * s))
		# Dark edge boards + a band: reads as a crate from above.
		var b := Basis.from_euler(Vector3(0, deg_to_rad(yaws[i]), 0))
		for cx: float in [-1.0, 1.0]:
			for cz: float in [-1.0, 1.0]:
				it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(0.12, s + 0.02, 0.12)),
					base + b * Vector3(cx * s * 0.47, 0, cz * s * 0.47)), mat_dark))
		it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(s + 0.03, 0.1, s + 0.03)), base), mat_dark))
		if i == 2:
			# Team tarp on the top crate: a cloth sheet with two flaps.
			it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(s + 0.14, 0.08, s + 0.14)),
				base + Vector3(0, s * 0.5 + 0.03, 0)), mat_team))
			for sx: float in [-1.0, 1.0]:
				it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(0.06, 0.42, s + 0.14)),
					base + b * Vector3(sx * (s * 0.5 + 0.08), s * 0.5 - 0.18, 0)), mat_team))
	# Barrel with dark hoops and a lid.
	var bp := Vector3(1.6, 0.8, 0.12)
	it.append(BMG.item(_cyl(0.33, 0.33, 0.95, 10), bp + Vector3(0, 0.475, 0), mat_metal))
	it.append(BMG.item(_cyl(0.37, 0.37, 0.4, 10), bp + Vector3(0, 0.475, 0), mat_metal))
	for y: float in [0.15, 0.8]:
		it.append(BMG.item(_cyl(0.36, 0.36, 0.09, 10), bp + Vector3(0, y, 0), mat_dark))
	it.append(BMG.item(_cyl(0.3, 0.3, 0.05, 10), bp + Vector3(0, 0.96, 0), mat_dark))
	return _merged("Crates", "crates", it)


## A standing brazier on a stone pedestal behind the house's -X side (glow point).
func _build_brazier(box1: BoxMesh) -> void:
	var it: Array = []
	var p := BRAZIER
	it.append(BMG.item(box1, p + Vector3(0, 0.22, 0), mat_dark, Vector3(0, 10, 0), Vector3(0.78, 0.44, 0.78)))
	it.append(BMG.item(_cyl(0.13, 0.2, 0.75, 8), p + Vector3(0, 0.8, 0), mat_metal))
	it.append(BMG.item(_cyl(0.5, 0.22, 0.4, 8), p + Vector3(0, 1.37, 0), mat_metal))
	it.append(BMG.item(_cyl(0.54, 0.54, 0.08, 8), p + Vector3(0, 1.58, 0), mat_dark))
	for k: int in 3:
		var d := Vector3(cos(TAU * k / 3.0), 0.0, sin(TAU * k / 3.0))
		var b: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(28.0))
		it.append(BMG.item_xf(_cyl(0.0, 0.09, 0.45, 4), Transform3D(b, p + d * 0.48 + Vector3(0, 1.62, 0)
			+ b * Vector3(0, 0.22, 0)), mat_metal))
	it.append(BMG.item(_sph(0.34), p + Vector3(0, 1.6, 0), mat_glow, Vector3.ZERO, Vector3(1.0, 0.55, 1.0)))
	_merged("Brazier", "brazier", it)
	var fire := _pm(Vector3.UP, 14.0, 1.1, 1.7, Vector3.ZERO, 0.5, 0.12, _fire_ramp)
	fire.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	fire.emission_sphere_radius = 0.22
	_idle_fx.append(_particles("BrazierFire", _body, p + Vector3(0, 1.72, 0), 14, 0.65, fire, _add_quad, false))


## The mast group (one construction part; topples on collapse): bronze column rising through the roof, dark bands, a
## team coin medallion, the yardarm with a stay rod, an ember beacon on top (glow point), a team banner on the back
## stub and the hanging balance scale.
func _build_mast(box1: BoxMesh) -> Node3D:
	var mast := Node3D.new()
	mast.name = "Mast"
	mast.position = MAST_POS
	_body.add_child(mast)
	var it: Array = []
	it.append(BMG.item(_cyl(0.21, 0.29, MAST_TOP - 1.8, 8), Vector3(0, (MAST_TOP + 1.8) * 0.5, 0), mat_metal))
	it.append(BMG.item(_cyl(0.42, 0.5, 0.3, 8), Vector3(0, 4.3, 0), mat_dark))
	for y: float in [ARM_Y - 0.55, ARM_Y + 0.5, MAST_TOP - 0.15]:
		it.append(BMG.item(_cyl(0.3, 0.3, 0.14, 8), Vector3(0, y, 0), mat_dark))
	# Yardarm (along -Z over the stall, a short stub toward +Z for the banner), end caps, stay rod from the top.
	var z_tip: float = PIVOT.z - 0.15
	var z_stub: float = 1.35
	it.append(BMG.item(box1, Vector3(0, ARM_Y, (z_tip + z_stub) * 0.5), mat_metal, Vector3.ZERO,
		Vector3(0.26, 0.26, z_stub - z_tip)))
	for z: float in [z_tip, z_stub]:
		it.append(BMG.item(box1, Vector3(0, ARM_Y, z), mat_dark, Vector3.ZERO, Vector3(0.34, 0.34, 0.2)))
	it.append(BMG.item_xf(box1, _slab(Vector3(0, MAST_TOP - 0.2, -0.15), Vector3(0, ARM_Y + 0.1, z_tip + 0.2), 0.09, 0.09),
		mat_metal))
	it.append(BMG.item_xf(box1, _slab(Vector3(0, MAST_TOP - 0.2, 0.15), Vector3(0, ARM_Y + 0.1, z_stub - 0.1), 0.09, 0.09),
		mat_metal))
	_merged("MastStack", "mast_stack", it, mast)
	# Coin medallion (faces +X and -X): a gold coin with a bronze rim and a team-colour square boss (the coin's hole),
	# thicker than the mast so the column does not cut it. Lost below 50 % HP.
	it = []
	it.append(BMG.item(_cyl(0.52, 0.52, 0.5, 16), Vector3(0, 5.05, 0), mat_metal, Vector3(0, 0, 90)))
	it.append(BMG.item(_cyl(0.4, 0.4, 0.56, 16), Vector3(0, 5.05, 0), mat_gate, Vector3(0, 0, 90)))
	it.append(BMG.item(box1, Vector3(0, 5.05, 0), mat_team, Vector3(45, 0, 0), Vector3(0.62, 0.27, 0.27)))
	_hide_below_50.append(_merged("Medallion", "medallion", it, mast))
	# Ember beacon on top.
	it = []
	it.append(BMG.item(_cyl(0.6, 0.26, 0.44, 8), Vector3(0, MAST_TOP + 0.22, 0), mat_metal))
	it.append(BMG.item(_cyl(0.64, 0.64, 0.1, 8), Vector3(0, MAST_TOP + 0.46, 0), mat_dark))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var d := Vector3(c.x, 0.0, c.y).normalized()
		var b: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(26.0))
		it.append(BMG.item_xf(_cyl(0.0, 0.14, 0.75, 4), Transform3D(b, d * 0.56 + Vector3(0, MAST_TOP + 0.48, 0) + b * Vector3(0, 0.36, 0)),
			mat_metal))
	it.append(BMG.item(_sph(0.34), Vector3(0, MAST_TOP + 0.46, 0), mat_glow, Vector3.ZERO, Vector3(1.0, 0.5, 1.0)))
	_merged("MastTop", "mast_top", it, mast)
	var up_fire := _pm(Vector3.UP, 12.0, 1.1, 1.7, Vector3.ZERO, 0.5, 0.1, _fire_ramp)
	up_fire.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	up_fire.emission_box_extents = Vector3(0.25, 0.05, 0.25)
	_idle_fx.append(_particles("BeaconFire", mast, Vector3(0, MAST_TOP + 0.55, 0), 14, 0.6, up_fire, _add_quad, false))
	var sm := _pm(Vector3.UP, 10.0, 0.8, 1.1, Vector3(0.2, 0.0, 0.0), 0.5, 1.6,
		_ramp(Color(smoke_color, 0.4), Color(smoke_color, 0.0), false))
	_idle_fx.append(_particles("BeaconSmoke", mast, Vector3(0, MAST_TOP + 1.2, 0), 8, 3.0, sm, _mix_quad, false))
	# Team banner on the back stub (hangs in the YZ plane: faces both cameras).
	var banner := _banner("MastBanner", Vector2(0.8, 1.9), Vector3(0, ARM_Y - 0.13 - 0.95, z_stub - 0.24), 90.0, mast)
	_hide_below_25.append(banner)
	_hide_on_collapse.append(banner)
	_build_scale(box1, mast)
	return mast


## The balance scale: a hook link, the beam (along Z) with end knobs, a pointer fin and a team boss at the fulcrum,
## two pans on three rods each: gold coins (+Z, the "heavy" side) and an ember crystal (-Z).
func _build_scale(box1: BoxMesh, mast: Node3D) -> void:
	_scale_pivot = Node3D.new()
	_scale_pivot.name = "ScalePivot"
	_scale_pivot.position = PIVOT
	mast.add_child(_scale_pivot)
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, -0.24, 0), mat_metal, Vector3.ZERO, Vector3(0.09, 0.5, 0.09)))
	it.append(BMG.item(_cyl(0.13, 0.13, 0.06, 8), Vector3(0, 0.0, 0), mat_dark, Vector3(0, 0, 90)))
	_merged("ScaleHook", "scale_hook", it, _scale_pivot)
	_beam = Node3D.new()
	_beam.name = "Beam"
	_beam.position = Vector3(0, -BEAM_DROP, 0)
	_scale_pivot.add_child(_beam)
	it = []
	it.append(BMG.item(box1, Vector3.ZERO, mat_metal, Vector3.ZERO, Vector3(0.18, 0.22, BEAM_HALF * 2.0 + 0.1)))
	it.append(BMG.item(_prism(Vector3(0.9, 0.2, 0.12), 0.5), Vector3(0, 0.13, 0), mat_metal, Vector3(0, 90, 0)))
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(_sph(0.17), Vector3(0, 0, s * (BEAM_HALF + 0.1)), mat_dark))
	it.append(BMG.item(_prism(Vector3(0.1, 0.55, 0.3), 0.5), Vector3(0, 0.3, 0), mat_metal, Vector3(0, 90, 0)))
	it.append(BMG.item(_cyl(0.26, 0.26, 0.28, 12), Vector3.ZERO, mat_team, Vector3(0, 0, 90)))
	it.append(BMG.item(_cyl(0.09, 0.09, 0.3, 8), Vector3.ZERO, mat_dark, Vector3(0, 0, 90)))
	_merged("BeamParts", "beam", it, _beam)
	for i: int in 2:
		var pan := Node3D.new()
		pan.name = "PanA" if i == 0 else "PanB"
		pan.position = Vector3(0, -BEAM_DROP, BEAM_HALF if i == 0 else -BEAM_HALF)
		_scale_pivot.add_child(pan)
		it = []
		for k: int in 3:
			var a: float = TAU * k / 3.0 + PI / 6.0
			var rim := Vector3(cos(a) * 0.5, -PAN_DROP + 0.08, sin(a) * 0.5)
			it.append(BMG.item_xf(box1, _slab(Vector3(0, -0.02, 0), rim, 0.06, 0.06), mat_metal))
		it.append(BMG.item(_cyl(0.6, 0.34, 0.22, 12), Vector3(0, -PAN_DROP, 0), mat_metal))
		it.append(BMG.item(_cyl(0.12, 0.05, 0.14, 8), Vector3(0, -PAN_DROP - 0.16, 0), mat_dark))
		if i == 0:
			it.append(BMG.item(_sph(0.48), Vector3(0, -PAN_DROP + 0.1, 0), mat_gate, Vector3.ZERO, Vector3(1.0, 0.55, 1.0)))
			for c: Vector3 in [Vector3(0.12, 0.26, 0.05), Vector3(-0.14, 0.22, -0.1), Vector3(0.0, 0.3, -0.2)]:
				it.append(BMG.item(_cyl(0.15, 0.15, 0.05, 10), Vector3(c.x, -PAN_DROP + c.y, c.z), mat_gate,
					Vector3(c.x * 90.0, 0, c.z * 90.0)))
		else:
			it.append(BMG.item(_cyl(0.0, 0.34, 0.34, 4), Vector3(0, -PAN_DROP + 0.44 + 0.17, 0), mat_glow, Vector3(0, 45, 0)))
			it.append(BMG.item(_cyl(0.0, 0.34, 0.34, 4), Vector3(0, -PAN_DROP + 0.44 - 0.17, 0), mat_glow, Vector3(180, 45, 0)))
		_merged("PanParts", "pan_%d" % i, it, pan)
		_pans.append(pan)
	# Coin glint (delivery): a burst of gold sparkles from the gold pan.
	var g := _pm(Vector3.UP, 70.0, 0.9, 1.9, Vector3(0, -2.5, 0), 0.2, 0.05,
		_ramp(Color(1.6, 1.25, 0.5), Color(1.2, 0.8, 0.3), false))
	g.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	g.emission_sphere_radius = 0.3
	_glint = _particles("CoinGlint", _pans[0], Vector3(0, -PAN_DROP + 0.25, 0), 18, 0.9, g, _add_quad, true)


## Additive warm pool on the plinth: the "light" of the brazier and the stall, flickering with the virtual light.
func _build_pool() -> void:
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
	_pool_mat = StandardMaterial3D.new()
	_pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_pool_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_pool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pool_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_pool_mat.albedo_texture = tex
	_pool_mat.albedo_color = Color(1.0, 0.55, 0.2, 0.22)
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.2, 4.2)
	_pool = MeshInstance3D.new()
	_pool.name = "LightPool"
	_pool.mesh = pm
	_pool.material_override = _pool_mat
	_pool.position = Vector3(-0.3, 0.9, -1.3)
	_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pool)


## Extra wreck pieces (shown with the base wreck at 1.6 s): the fallen scale beam and an upturned pan by the stall, a
## spill of gold coins, the medallion on the ground.
func _build_wreck_extra(box1: BoxMesh) -> void:
	var it: Array = []
	it.append(BMG.item(box1, Vector3(1.0, 0.98, -0.5), mat_metal, Vector3(0, 28, 6), Vector3(0.16, 0.18, 2.3)))
	it.append(BMG.item(_cyl(0.52, 0.3, 0.2, 12), Vector3(0.1, 1.0, -1.4), mat_metal, Vector3(160, 0, 12)))
	it.append(BMG.item(_cyl(0.56, 0.56, 0.16, 16), Vector3(1.9, 0.95, -0.2), mat_metal, Vector3(78, 20, 0)))
	it.append(BMG.item(_cyl(0.42, 0.42, 0.2, 16), Vector3(1.9, 0.97, -0.2), mat_team, Vector3(78, 20, 0)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2020
	for k: int in 7:
		var p := Vector3(0.6 + rng.randf_range(-0.6, 0.6), 0.9, -1.0 + rng.randf_range(-0.6, 0.5))
		it.append(BMG.item(_cyl(0.15, 0.15, 0.05, 10), p, mat_gate, Vector3(rng.randf_range(-20, 20), 0,
			rng.randf_range(-20, 20))))
	_merged("WreckExtra", "wreck_extra", it, _wreck)


# --- Small helpers ---

## Transform of a box running from `a` to `b` (local Z along the segment), `w` wide (local X) and `t` thick.
func _slab(a: Vector3, b: Vector3, w: float, t: float) -> Transform3D:
	var z: Vector3 = (b - a)
	var len: float = z.length()
	z = z / maxf(len, 0.0001)
	var x: Vector3 = Vector3.RIGHT if absf(z.x) < 0.9 else Vector3.UP
	var y: Vector3 = z.cross(x).normalized()
	x = y.cross(z).normalized()
	return Transform3D(Basis(x, y, z).scaled_local(Vector3(w, t, len)), (a + b) * 0.5)


func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 5
	return s
