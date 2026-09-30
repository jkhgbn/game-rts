class_name NatureMarketModel
extends FireHallModel
## Visual model of Ysolde's market, the Grove Bazaar (task 10.V4; market-trade.md 4.1 + 9; 3 x 3 cells = 6 x 6 m;
## the Nature buildings' language: art/buildings/nature/nature_kit.gd + nature_keep/*.gdshader, reused read-only).
## Read from the RTS camera:
## - Dominant vertical (back-left, ~9 m): a slender living mast (three braided bark strands, glowing sap in the
##   furrows, a small leaf crown) with a gallows arm (braced by a knee branch) reaching forward over the stall. From it
##   hangs the sign, a balance scale broadside to both side cameras: a bark beam with gold knobs and hub, a gold coin
##   (a glowing leaf inlaid on both faces) as its pointer, a pan heaped with gold coins and a pan holding a glowing seed.
## - The stall (centre): a great felled trunk lying along the plaza is the counter (bark outside, cut ends with
##   heartwood, a plank tray set into its top with seed jars of glowing seeds, a basket of glow-fruit, a gold-banded
##   strongbox), under a lean-to leaf roof (big team-coloured leaves laid like shingles on three living bark ribs that
##   rise from the flagstones and curl at the open, high edge; a glow-fruit lantern swings from each end rib).
## - Asymmetric secondary: a stack of crates crowned with a big seed jar, sacks and a cart wheel (back-right); a sap tap
##   in the mast dripping into a barrel of glowing sap (back-left); an amphora under the roof's low edge; on the open
##   side a stump stool with a basket of glow-fruit and sacks, a tipped jar spilling glowing seeds; two team leaf
##   banners on standards flanking the caravan gate (front); leafy knots on the roof. Moss patch + fairy ring.
## The game shows the local +X side (player) or -X side (enemy) to the camera: +X sees the open stall under the high
## edge (goods, lanterns), -X sees the leaf roof, the sap barrel and the mast; both see the scale broadside.
## Hooks (art-keep.md 8.8, the FireHallModel / NatureHallModel state machine): set_team_color,
## set_construction_progress, set_health_ratio, play_training_pulse (a caravan leaves: gate glow + sparks),
## play_destroyed (-> destroyed_finished after 3 s), set_selected, plus play_delivery() (market-trade.md 9: a caravan
## paid in: the scale tips toward the gold pan and swings back, the gold flares and glints, gold sparks rise).
## States: < 50 % HP the roof's front-high corner is torn off (its leaves lie on the ground) and smoke rises; < 25 % a
## banner is lost, the lanterns and scale shake, withered leaves pour off the crown and roof. Collapse: the mast falls
## outward with the sign, the stall is swapped for its wreck (split trunk, tumbled crates, smashed jars, the stump).
## Gate (the caravans leave by it) = local -Z. No light at all (the base class's light is an orphan node that never
## enters the tree): emissive + bloom only. Every tier is ONE mesh (one surface per material, indexed), baked once per
## class into art/buildings/market/nature/baked/ by market_nature_bake.gd. Ambient particles (sap motes, drifting
## leaves) only run while a camera is within 45 m.

const KEY := "market_nature/"
const BAKED_DIR := "res://art/buildings/market/nature/baked/"
const TOP := 0.5                                 ## plinth top
const TREE := Vector3(-1.25, 0.0, 2.2)            ## the mast's axis on the ground (Body space)
const HOOK := Vector3(-0.35, 7.2, -0.95)          ## Body space: under the arm's tip, where the sign's vine hangs
const HUB := Vector3(-0.35, 6.05, -0.95)          ## Body space: the scale's pivot
const BEAM_YAW := -PI * 0.5                      ## the beam runs along Z (gold pan at the front, coin facing +X)
const BEAM_HALF := 1.25
const PAN_DROP := 0.85
const LOG_A := Vector3(-0.1, 1.14, -2.0)         ## the felled trunk (counter) axis, front end
const LOG_B := Vector3(-0.2, 1.14, 0.95)          ## back end
const LOG_R := 0.64
const RIBS: Array[float] = [-2.1, -0.55, 1.0]     ## the roof's living ribs (z)
const ROOF_LOW := -2.45                          ## the roof's low edge (x)
const ROOF_HIGH := 1.55                          ## its open high edge (x)
const ROOF_Z := Vector2(-2.5, 1.45)
const STOOL := Vector3(2.0, 0.0, 0.15)            ## a stump stool with a basket of glow-fruit (open side)
const STANDARDS: Array[Vector3] = [Vector3(-0.8, TOP, -2.8), Vector3(2.3, TOP, -2.5)]
const STANDARD_DEG: Array[float] = [-50.0, 50.0]  ## banner facing (NatureKit.dir_deg)
const BARREL := Vector3(-2.45, TOP, 1.75)
const CROWN: Array[Vector4] = [Vector4(0.05, 8.15, 0.2, 0.95), Vector4(0.65, 7.55, 0.5, 0.62),
	Vector4(-0.6, 7.65, 0.4, 0.62)]                 ## tree-local crown clumps (x, y, z, r)
const NEAR_ON := 45.0
const NEAR_OFF := 50.0
const DELIVERY_TIME := 2.6
const DELIVERY_TILT := 16.0                      ## degrees (the first swing peaks near 10)

static var _cache: Dictionary = {}
static var _builders: Dictionary = {}
## The bake script sets it: ignore the baked files and build every mesh from code.
static var force_build: bool = false

var _mats: Dictionary = {}
var _gold: ShaderMaterial
var _ground_mat: ShaderMaterial
var _tree: Node3D
var _beam: Node3D
var _pans: Array[Node3D] = []
var _lanterns: Array[Node3D] = []
var _coin_burst: GPUParticles3D
var _ambient: Array[GPUParticles3D] = []
var _ambient_on: bool = false
var _cam_check: float = 0.0
var _leaf_ramps: Array = []
var _glow_ramps: Array = []
var _agitated: bool = false
var _deliv_left: float = 0.0
var _glint: float = 0.0


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


## The Heartwood's materials (per instance) + the Bazaar's own two: "Clay" (jars, amphorae, sacks: one warm tan so
## the goods read as one family) and "Gold" (market_nature_gold.gdshader: coin, hub, rims, coins, strongbox bands).
func _make_materials() -> void:
	_mats = NatureKit.make_materials()
	var clay := ShaderMaterial.new()
	clay.resource_name = "Clay"
	clay.shader = NatureKit.PAINTED
	clay.set_shader_parameter(&"base_color", Color(0.62, 0.5, 0.33))
	clay.set_shader_parameter(&"noise_tex", NatureKit.NOISE)
	clay.set_shader_parameter(&"pattern", 0)
	clay.set_shader_parameter(&"spec_strength", 0.12)
	clay.set_shader_parameter(&"rim_color", NatureKit.RIM_IDLE)
	clay.set_shader_parameter(&"rim_strength", NatureKit.RIM_IDLE_STRENGTH)
	_mats["Clay"] = clay
	_gold = ShaderMaterial.new()
	_gold.resource_name = "Gold"
	_gold.shader = preload("res://art/buildings/market/nature/market_nature_gold.gdshader")
	_gold.set_shader_parameter(&"noise_tex", NatureKit.NOISE)
	_mats["Gold"] = _gold
	mat_stone = _mats["Stone"]
	mat_dark = _mats["Dark"]
	mat_metal = _mats["Bark"]
	mat_team = _mats["Leaves"]
	mat_banner = _mats["Banner"]
	mat_glow = _mats["Heart"]
	mat_gate = _mats["Gate"]
	_painted = NatureKit.surface_materials(_mats)
	_painted.append(clay)
	_painted.append(_gold)
	_glows = [_mats["Heart"], _mats["Gate"], _mats["Blossom"], _mats["Petal"]] as Array[ShaderMaterial]


func _light_wave(_n: float) -> float:
	return 1.0


## B8: the NatureKit painted (+ Clay) / card materials drawn as one merged material each (NatureVC), the hall's
## particle quads / process materials shared and its rune glows merged (FireHallModel budget passes).
func _budget_wanted() -> bool:
	return true


func _post_build() -> void:
	NatureKit.NVC.convert(self, _mats)


## B8: the hall's particles use NatureKit's soft dots (the pollen's ADD dot, the leaves / petals atlas for MIX).
func _make_particle_quads() -> void:
	super()
	_add_quad = NatureKit.soft_quad(true)
	_mix_quad = NatureKit.soft_quad(false)


func _notification(what: int) -> void:
	# The base class drives `_light` every frame; ours never enters the tree (0 real lights), so free it here.
	if what == NOTIFICATION_PREDELETE and _light != null and is_instance_valid(_light) and not _light.is_inside_tree():
		_light.free()


# ============================================================ hooks

## A caravan delivered gold (Market calls it on each delivery): the scale tips toward the gold pan and swings back
## over 2.6 s, the gold flares and glints, a burst of gold sparks rises from the pan. Restarts if retriggered.
## Ignored while under construction or destroyed.
func play_delivery() -> void:
	if _destroyed:
		return
	if _ready_done and _progress < 1.0:
		return
	_deliv_left = DELIVERY_TIME
	if _ready_done and _coin_burst:
		_fire(_coin_burst)


func set_construction_progress(p: float) -> void:
	super(p)
	if _ready_done and not _destroyed and _progress <= 0.0:
		for part: Node3D in _parts:
			part.visible = false   # at 0 only the glowing outline shows (art-keep.md 8.2)
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"build", _progress)
	if _ready_done and _progress < 1.0:
		_set_ambient(false)
		_deliv_left = 0.0
		_set_glint(0.0)
	elif _ready_done:
		_cam_check = 0.0


func play_destroyed() -> void:
	super()
	if _ready_done:
		_set_ambient(false)
		_deliv_left = 0.0
		_set_glint(0.0)


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


# ============================================================ idle

func _idle_motion(delta: float) -> void:
	var fast: float = 3.0 if _pulse_left > 0.0 else 1.0
	for i: int in _lanterns.size():
		var amp: float = deg_to_rad(8.0) * (1.8 if _agitated else 1.0)
		var ph: float = _t * TAU / 3.0 * fast + float(i) * 1.9
		var jit: float = sin(_t * 17.0 + float(i)) * 0.03 if _agitated else 0.0
		_lanterns[i].rotation = Vector3(sin(ph) * amp + jit, 0.0, cos(ph * 0.8) * amp * 0.6)
	_update_scale(delta)
	_cam_check -= delta
	if _cam_check <= 0.0:
		_cam_check = 0.5
		var d: float = NatureKit.camera_distance(self, global_position + Vector3(0, 4, 0))
		_set_ambient(d < (NEAR_OFF if _ambient_on else NEAR_ON) and _progress >= 1.0)


## The sign: a slow idle sway (agitated below 25 % HP), the delivery tip (a damped swing toward the gold pan), pans
## hanging level from the beam ends, the gold glint.
func _update_scale(delta: float) -> void:
	if _beam == null:
		return
	var tilt: float = deg_to_rad(1.6) * sin(_t * 0.9) * (2.5 if _agitated else 1.0)
	if _agitated:
		tilt += sin(_t * 13.0) * deg_to_rad(0.8)
	if _deliv_left > 0.0:
		_deliv_left = maxf(_deliv_left - delta, 0.0)
		var t: float = DELIVERY_TIME - _deliv_left
		tilt += deg_to_rad(DELIVERY_TILT) * sin(t * 5.2) * exp(-t * 1.5)
		_set_glint(minf(t / 0.12, 1.0) * exp(-t * 1.7))
		if _deliv_left <= 0.0:
			_set_glint(0.0)
	_beam.rotation = Vector3(0.0, BEAM_YAW, tilt)
	var yaw := Basis(Vector3.UP, BEAM_YAW)
	for i: int in _pans.size():
		var end := Vector3((-1.0 if i == 0 else 1.0) * BEAM_HALF, 0.14, 0.0).rotated(Vector3.BACK, tilt)
		_pans[i].position = (HUB - TREE) + yaw * end
		_pans[i].rotation = Vector3(sin(_t * 1.1 + float(i)) * 0.03, BEAM_YAW,
			sin(_t * 1.3 + float(i) * 2.0) * 0.025 - tilt * 0.12)


func _set_glint(k: float) -> void:
	if is_equal_approx(k, _glint):
		return
	_glint = k
	if _gold:
		_gold.set_shader_parameter(&"glint", k)
		NatureKit.NVC.sync_gold(_mats)


func _set_ambient(on: bool) -> void:
	if on == _ambient_on:
		return
	_ambient_on = on
	for p: GPUParticles3D in _ambient:
		p.emitting = on


# ============================================================ mesh cache

## The mesh for `key` ([ArrayMesh, material keys], shared by every instance): the baked file if there is one, else
## `build` (Callable taking a NatureKit.MB) fills a new one the first time.
static func mesh_for(key: String, build: Callable) -> Array:
	_builders[key] = build
	if _cache.has(key):
		return _cache[key]
	var res: Array = []
	var path: String = baked_path(key)
	if not force_build and ResourceLoader.exists(path):
		var m := load(path) as ArrayMesh
		if m:
			var keys: Array[String] = []
			for i: int in m.get_surface_count():
				keys.append(m.surface_get_name(i))
			res = [m, keys]
	if res.is_empty():
		res = NatureKit.build_fresh(build)
	_cache[key] = res
	return res


static func baked_path(key: String) -> String:
	return BAKED_DIR + key.replace("/", "__") + ".res"


## Every mesh key used so far (the bake script saves them all).
static func cached_keys() -> Array:
	return _cache.keys()


static func cached_mesh(key: String) -> ArrayMesh:
	return (_cache[key] as Array)[0] if _cache.has(key) else null


## The code that builds `key` (from the latest instance that asked for it): the staleness test rebuilds with it.
static func builder_of(key: String) -> Callable:
	return _builders.get(key, Callable())


static func clear_cache() -> void:
	_cache.clear()


## One baked tier under `parent` with this building's materials and the painted height gradient.
func _part_node(nm: String, key: String, build: Callable, parent: Node3D, ao_bottom: float, ao_height: float,
		shadow: bool = true) -> MeshInstance3D:
	var res: Array = mesh_for(KEY + key, build)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = res[0]
	var keys: Array[String] = res[1]
	var all_glow: bool = true
	for i: int in keys.size():
		mi.set_surface_override_material(i, _mats[keys[i]])
		if not (keys[i] in ["Heart", "Gate", "Cap", "Black"]):
			all_glow = false
	if not shadow or all_glow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.set_instance_shader_parameter(&"ao_bottom", ao_bottom)
	mi.set_instance_shader_parameter(&"ao_height", ao_height)
	return mi


# ============================================================ structure

## Grove Bazaar parts (Body space, gate -Z). Heights: plinth 0.5, counter top 1.7, roof 2.3-3.9, banners 4.1, scale
## 5.0-6.4, arm 7.4, crown ~8.9. Tiers: PlinthBase, Stall (trunk counter, goods, ribs, roots, barrel, crates,
## standards), Canopy (Roof + RoofLost + two lanterns), Tree (mast, arm, crown; Beam + 2 Pans), BannerA / BannerB.
func _build_structure() -> void:
	_top_y = 8.9
	_part_node("PlinthBase", "plinth", _mesh_plinth, _body, 0.0, 2.0)
	var stall := _part_node("Stall", "stall", _mesh_stall, _body, 0.0, 4.2)
	# The lean-to leaf roof and its lanterns (one part: they rise together; the lanterns swing inside it).
	var canopy := Node3D.new()
	canopy.name = "Canopy"
	_body.add_child(canopy)
	_part_node("Roof", "roof", _mesh_roof.bind(false), canopy, 2.2, 1.8)
	var lost := _part_node("RoofLost", "roof_lost", _mesh_roof.bind(true), canopy, 2.2, 1.8)
	_hide_below_50.append(lost)
	for z: float in [RIBS[0], RIBS[2]]:
		var pv := Node3D.new()
		pv.name = "LanternPivot%d" % _lanterns.size()
		pv.position = _rib_tip(z) + Vector3(0, -0.05, 0)
		canopy.add_child(pv)
		_part_node("Lantern", "lantern", _mesh_lantern, pv, 2.0, 1.4, false)
		_lanterns.append(pv)
	# Dominant vertical: the living mast and its sign (falls outward on collapse, the sign with it).
	_tree = Node3D.new()
	_tree.name = "Tree"
	_tree.position = TREE
	_body.add_child(_tree)
	_part_node("Mast", "mast", _mesh_mast, _tree, 0.2, 8.4)
	_beam = Node3D.new()
	_beam.name = "Beam"
	_beam.position = HUB - TREE
	_beam.rotation = Vector3(0.0, BEAM_YAW, 0.0)
	_tree.add_child(_beam)
	_part_node("BeamParts", "beam", _mesh_beam, _beam, 5.0, 1.6, false)
	for i: int in 2:
		var pan := Node3D.new()
		pan.name = "PanGold" if i == 0 else "PanSeed"
		pan.position = HUB - TREE + Basis(Vector3.UP, BEAM_YAW) * Vector3((-1.0 if i == 0 else 1.0) * BEAM_HALF, 0.14, 0.0)
		pan.rotation = Vector3(0.0, BEAM_YAW, 0.0)
		_tree.add_child(pan)
		_part_node("PanParts", "pan_gold" if i == 0 else "pan_seed", _mesh_pan.bind(i == 0), pan, 4.9, 1.2, false)
		_pans.append(pan)
	_falling = _tree
	_fall_axis = Vector3.RIGHT
	_fall_deg = 38.0   # tips back (+Z), away from the stall
	# Banners: one per standard; the right one is lost below 25 % HP.
	var ba := _part_node("BannerA", "banner_a", _mesh_banner.bind(0), _body, 0.0, 1.0, false)
	var bb := _part_node("BannerB", "banner_b", _mesh_banner.bind(1), _body, 0.0, 1.0, false)
	_hide_below_25.append(bb)
	# At the 1.6 s dust burst the stall, roof and banners are swapped for the wreck.
	_hide_on_collapse.append_array([stall, canopy, ba, bb])
	# No light in the tree: the base class drives `_light` every frame, so it exists as an orphan (freed on delete).
	_light = OmniLight3D.new()
	_light.name = "UnusedLight"
	_light.visible = false
	_build_ambient()
	_build_delivery_fx()
	_build_scaffold_market()
	_build_wreck_market()
	# State anchors: smoke from the torn roof corner and the crown, withering leaves off the crown and the roof.
	_smoke_points = [Vector3(0.9, 3.9, -1.6), TREE + Vector3(0.0, 8.1, 0.2)]
	_blaze_points = [Vector3(-0.8, 3.7, -0.3), TREE + Vector3(0.0, 8.2, 0.2)]
	_rubble2_points = [] as Array[Vector3]
	_gate_pos = Vector3(0.7, 1.4, -2.85)


## Height of the lean-to roof's surface at x (low edge -X, open high edge +X, slightly arched).
static func _roof_y(x: float) -> float:
	return 3.5 + 0.36 * x - 0.05 * x * x


## Slope normal of the roof at x.
static func _roof_n(x: float) -> Vector3:
	return Vector3(-(0.36 - 0.1 * x), 1.0, 0.0).normalized()


## Where the rib at z ends (its curled tip at the open edge; a lantern hangs there).
static func _rib_tip(z: float) -> Vector3:
	return Vector3(ROOF_HIGH + 0.21, _roof_y(ROOF_HIGH) - 0.4, z)


func _mesh_plinth(mb: NatureKit.MB) -> void:
	mb.loft("Dark", [NatureKit.chamfer(3.1, 0.9), NatureKit.chamfer(3.04, 0.88)], [0.0, 0.3])
	mb.loft("Stone", [NatureKit.chamfer(2.95, 0.8), NatureKit.chamfer(2.9, 0.78)], [0.3, TOP])
	# A worn step down from the caravan gate (front).
	mb.box("Dark", Vector3(0.7, 0.12, -3.2), Vector3(2.3, 0.26, 0.42), Basis(Vector3.UP, deg_to_rad(3.0)))


## The mast's roots gripping the flagstones and pouring over the edge into the ground (in the Stall tier, sharing
## its bark surface; the wreck has its own copy).
static func _roots(mb: NatureKit.MB) -> void:
	var t3 := Vector3(TREE.x, 0.0, TREE.z)
	var i: int = 0
	# [direction (NatureKit.dir_deg), reach, pours over the plinth edge]
	for r: Array in [[180.0, 1.75, true], [215.0, 2.1, true], [250.0, 2.2, true], [140.0, 1.5, true],
			[330.0, 1.3, false], [35.0, 1.55, false], [62.0, 2.5, false]]:
		var d: Vector3 = NatureKit.dir_deg(r[0])
		var over_edge: bool = r[2]
		var a: Vector3 = t3 + d * 0.62 + Vector3(0, 0.95, 0)
		var over: Vector3 = t3 + d * 1.2 + Vector3(0, TOP + 0.26, 0)
		var b: Vector3 = t3 + d * float(r[1]) + Vector3(0, -0.45 if over_edge else TOP - 0.18, 0)
		NatureKit.root(mb, a, over, b, 0.24 - 0.03 * float(i % 2), 0.07, float(i) * 1.7 + 0.4)
		i += 1


## The stall: the felled-trunk counter and its goods, the roof's living ribs, the roots, the sap tap and barrel,
## the crate stack with sacks and a cart wheel, the amphorae, the two banner standards.
func _mesh_stall(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3110
	_roots(mb)
	var ax: Vector3 = (LOG_B - LOG_A).normalized()
	var log_basis := Basis(ax, Vector3.UP, ax.cross(Vector3.UP))
	var across: Vector3 = log_basis.z   # horizontal, across the trunk (toward -X)
	# --- The felled trunk: bark with sap, cut ends with heartwood, a plank tray set into its top, chocks.
	var lpts: Array[Vector3] = []
	var lrad: Array[float] = []
	for k: int in 5:
		var t: float = float(k) / 4.0
		lpts.append(LOG_A.lerp(LOG_B, t) + Vector3(0, 0.02 * sin(t * 5.0), 0))
		lrad.append(LOG_R * (1.04 - 0.06 * t) * (1.0 + 0.03 * sin(t * 9.0)))
	mb.tube("Bark", lpts, lrad, 12, 3.0, 0.07, 2.3, false, false)
	for e: int in 2:
		var c: Vector3 = lpts[0] if e == 0 else lpts[4]
		var n: Vector3 = -ax if e == 0 else ax
		var r: float = lrad[0] if e == 0 else lrad[4]
		_disc(mb, "Wood", c + n * 0.005, n, r * 0.97, 12)
		_disc(mb, "Bark", c + n * 0.02, n, r * 0.34, 8)
	var mid: Vector3 = LOG_A.lerp(LOG_B, 0.5)
	var length: float = LOG_A.distance_to(LOG_B)
	mb.box("Wood", mid + Vector3(0, LOG_R - 0.04, 0), Vector3(length - 0.2, 0.1, 0.72), log_basis)
	for sd: float in [-1.0, 1.0]:
		mb.box("Wood", mid + Vector3(0, LOG_R + 0.04, 0) + across * sd * 0.35, Vector3(length - 0.16, 0.12, 0.08), log_basis)
	for t: float in [0.2, 0.8]:
		var p: Vector3 = LOG_A.lerp(LOG_B, t)
		for sd: float in [-1.0, 1.0]:
			mb.box("Wood", Vector3(p.x, TOP + 0.08, p.z) + across * sd * 0.52, Vector3(0.3, 0.2, 0.36),
				log_basis * Basis(Vector3.RIGHT, 0.35 * sd))
	# Branch stubs on the trunk (a felled giant, still knotted with limbs).
	for s: Array in [[0.3, Vector3(0.75, 0.55, 0.1)], [0.62, Vector3(-0.6, 0.7, 0.25)]]:
		var sp: Vector3 = LOG_A.lerp(LOG_B, s[0])
		var d: Vector3 = s[1]
		mb.tube("Bark", [sp + d * 0.55, sp + d * 0.95, sp + d * 1.15 + Vector3(0, 0.08, 0)] as Array[Vector3],
			[0.17, 0.12, 0.07] as Array[float], 6, 1.0, 0.1, float(s[0]) * 9.0, false, true)
	# --- Goods on the tray (toward the open +X side): seed jars with glowing seeds heaped in the mouths, a basket
	# of glow-fruit, a gold-banded strongbox.
	var tray_y: float = LOG_R + 0.06
	var fwd := Vector3(0.12, 0.0, 0.0)
	for g: Array in [[0.1, 0.21, 0.52, true], [0.28, 0.16, 0.4, false], [0.72, 0.22, 0.56, true]]:
		var p: Vector3 = LOG_A.lerp(LOG_B, g[0]) + Vector3(0, tray_y, 0) + fwd
		_jar(mb, p, g[1], g[2], g[3])
	var bp: Vector3 = LOG_A.lerp(LOG_B, 0.49) + Vector3(0, tray_y, 0) + fwd
	mb.lathe("Wood", bp, [Vector2(0.2, 0.0), Vector2(0.3, 0.08), Vector2(0.34, 0.2), Vector2(0.36, 0.24)] as Array[Vector2], 10, 2.0)
	mb.lathe("Wood", bp, [Vector2(0.33, 0.24), Vector2(0.3, 0.12), Vector2(0.18, 0.05)] as Array[Vector2], 10, 2.0)
	for k: int in 5:
		var a: float = TAU * float(k) / 4.0 + 0.3
		var q: Vector3 = bp + (Vector3(cos(a) * 0.16, 0.24, sin(a) * 0.16) if k < 4 else Vector3(0.0, 0.38, 0.0))
		mb.sphere("Heart", q, 0.15, 1.05, 6, 4)
	var sb: Vector3 = LOG_A.lerp(LOG_B, 0.92) + Vector3(0, tray_y + 0.16, 0) + fwd
	var sb_basis: Basis = log_basis * Basis(Vector3.UP, 0.25)
	mb.box("Wood", sb, Vector3(0.5, 0.32, 0.36), sb_basis)
	mb.box("Wood", sb + Vector3(0, 0.2, 0), Vector3(0.52, 0.08, 0.38), sb_basis)
	for sx: float in [-0.16, 0.16]:
		mb.box("Gold", sb + sb_basis.x * sx + Vector3(0, 0.03, 0), Vector3(0.06, 0.44, 0.4), sb_basis)
	mb.box("Gold", sb - sb_basis.z * 0.19 + Vector3(0, 0.08, 0), Vector3(0.1, 0.12, 0.04), sb_basis)
	# --- The roof's three living ribs: out of the flagstones at the low side, up under the roof, curled at the edge.
	var tip_y: float = _roof_y(ROOF_HIGH)
	for z: float in RIBS:
		var pts: Array[Vector3] = [Vector3(ROOF_LOW + 0.05, TOP - 0.1, z), Vector3(ROOF_LOW + 0.02, 1.2, z + 0.04),
			Vector3(ROOF_LOW + 0.08, 1.95, z)]
		for x: float in [-1.9, -1.0, 0.0, 0.9]:
			pts.append(Vector3(x, _roof_y(x) - 0.12, z))
		pts.append(Vector3(1.5, tip_y - 0.04, z))
		pts.append(Vector3(1.74, tip_y - 0.2, z))
		var tip: Vector3 = _rib_tip(z)
		pts.append(tip)
		pts.append(tip + Vector3(-0.12, -0.02, 0))
		mb.tube("Bark", pts, [0.16, 0.14, 0.13, 0.12, 0.12, 0.11, 0.1, 0.09, 0.075, 0.055, 0.04] as Array[float], 7, 1.0,
			0.08, z * 3.0, false, true)
		NatureKit.root(mb, Vector3(ROOF_LOW + 0.05, TOP + 0.2, z), Vector3(ROOF_LOW - 0.3, TOP + 0.12, z + 0.1),
			Vector3(ROOF_LOW - 0.55, TOP - 0.1, z + 0.12), 0.12, 0.05, z * 2.0)
	# --- The sap tap: a hollow reed spout out of the mast dripping glowing sap into a barrel.
	var to_barrel: Vector3 = Vector3(BARREL.x - TREE.x, 0.0, BARREL.z - TREE.z).normalized()
	var trunk_face: Vector3 = Vector3(TREE.x, 1.95, TREE.z) + to_barrel * 0.6
	var spout_end := Vector3(BARREL.x + 0.1, 1.72, BARREL.z - 0.02)
	mb.tube("Wood", [trunk_face, trunk_face.lerp(spout_end, 0.5) + Vector3(0, 0.03, 0), spout_end] as Array[Vector3],
		[0.1, 0.085, 0.075] as Array[float], 6, 1.0, 0.0, 0.0, false, true)
	mb.box("Gate", Vector3(spout_end.x, (spout_end.y + BARREL.y + 0.72) * 0.5 - 0.02, spout_end.z),
		Vector3(0.05, spout_end.y - BARREL.y - 0.76, 0.05))
	mb.sphere("Gate", Vector3(spout_end.x, spout_end.y - 0.08, spout_end.z), 0.06, 1.3, 6, 4)
	var b: Vector3 = BARREL
	var bc := Vector2(b.x, b.z)
	mb.lathe("Wood", b, [Vector2(0.36, -0.02), Vector2(0.42, 0.18), Vector2(0.44, 0.38), Vector2(0.42, 0.58),
		Vector2(0.37, 0.76)] as Array[Vector2], 12, 3.0)
	mb.lathe("Wood", b, [Vector2(0.34, 0.76), Vector2(0.35, 0.68)] as Array[Vector2], 12, 3.0)
	for y: float in [0.12, 0.62]:
		var rr: float = 0.43 if y < 0.3 else 0.425
		mb.loft("Bark", [NatureKit.ring_n(12, rr, 0.0, bc), NatureKit.ring_n(12, rr, 0.0, bc)], [b.y + y, b.y + y + 0.08],
			false, false, bc)
	mb.cap("Heart", NatureKit.ring_n(12, 0.35, 0.0, bc), b.y + 0.7, -1.0)
	# --- Back-right: the crate stack crowned with a big seed jar, sacks, a cart wheel leaning on it (+X face).
	_crate(mb, Vector3(1.9, TOP, 1.8), 0.9, 0.15)
	_crate(mb, Vector3(1.95, TOP + 0.9, 1.75), 0.76, -0.3)
	_crate(mb, Vector3(1.0, TOP, 2.35), 0.7, 0.4)
	_jar(mb, Vector3(1.95, TOP + 1.66, 1.75), 0.27, 0.72, true)
	_sack(mb, Vector3(1.25, TOP, 1.25), 0.15)
	_sack(mb, Vector3(0.35, TOP, 2.45), -0.2, 0.85)
	_wheel(mb, Vector3(2.48, TOP + 0.44, 1.8))
	# --- An amphora under the low edge (-X) and, at the open side, a tipped jar spilling glowing seeds.
	_jar(mb, Vector3(-2.4, TOP, -1.35), 0.3, 0.86, true)
	var saved: Transform3D = mb.xf
	var jar_yaw := Basis(Vector3.UP, deg_to_rad(-20.0))
	var jar_pos := Vector3(1.2, TOP + 0.27, -2.1)
	mb.xf = Transform3D(jar_yaw * Basis(Vector3.BACK, -PI * 0.5 + 0.12), jar_pos)
	_jar(mb, Vector3(0.0, -0.1, 0.0), 0.26, 0.74, false, false)
	mb.xf = saved
	var jar_dir: Vector3 = jar_yaw * Vector3.RIGHT   # its mouth points out (+X, a little back)
	var mouth: Vector3 = Vector3(jar_pos.x, TOP, jar_pos.z) + jar_dir * 0.7
	for k: int in 6:
		var q: Vector3 = mouth + jar_dir.rotated(Vector3.UP, rng.randf_range(-0.5, 0.5)) * rng.randf_range(0.05, 0.45)
		mb.sphere("Heart", Vector3(q.x, TOP + 0.07, q.z), rng.randf_range(0.09, 0.13), 0.75, 5, 3)
	# --- The open side: a stump stool with a basket of glow-fruit, two sacks leaning on it.
	var st := Vector3(STOOL.x, TOP, STOOL.z)
	mb.tube("Bark", [st + Vector3(0, -0.05, 0), st + Vector3(0.02, 0.3, 0), st + Vector3(0, 0.58, 0)] as Array[Vector3],
		[0.42, 0.37, 0.36] as Array[float], 10, 2.0, 0.08, 5.0, false, false)
	mb.loft("Wood", [NatureKit.ring_n(10, 0.35, 0.0, Vector2(st.x, st.z)), NatureKit.ring_n(10, 0.33, 0.0, Vector2(st.x, st.z))],
		[st.y + 0.56, st.y + 0.6], true, false, Vector2(st.x, st.z))
	var bs2: Vector3 = st + Vector3(0, 0.6, 0)
	mb.lathe("Wood", bs2, [Vector2(0.18, 0.0), Vector2(0.28, 0.07), Vector2(0.32, 0.18), Vector2(0.34, 0.22)] as Array[Vector2], 10, 2.0)
	mb.lathe("Wood", bs2, [Vector2(0.31, 0.22), Vector2(0.28, 0.11), Vector2(0.16, 0.04)] as Array[Vector2], 10, 2.0)
	for k: int in 4:
		var a: float = TAU * float(k) / 3.0 + 1.1
		var q: Vector3 = bs2 + (Vector3(cos(a) * 0.14, 0.22, sin(a) * 0.14) if k < 3 else Vector3(0.0, 0.36, 0.0))
		mb.sphere("Heart", q, 0.15, 1.05, 6, 4)
	_sack(mb, st + Vector3(0.05, 0.0, 0.62), -0.25, 0.9)
	_sack(mb, st + Vector3(0.55, 0.0, -0.3), 0.2, 0.8)
	# --- The caravan gate: two banner standards (gnarled poles, crossbars, fronds, glowing buds).
	for k: int in STANDARDS.size():
		NatureKit.standard(mb, STANDARDS[k], 3.6, NatureKit.dir_deg(STANDARD_DEG[k]), -1.2 if k == 0 else 1.7, 1.0)


## A disc (fan) facing `n`.
static func _disc(mb: NatureKit.MB, k: String, c: Vector3, n: Vector3, r: float, sides: int) -> void:
	var ref := Vector3.UP if absf(n.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var u: Vector3 = n.cross(ref).normalized()
	var v: Vector3 = n.cross(u)
	var pts: Array[Vector3] = []
	for i: int in sides:
		var a: float = TAU * float(i) / float(sides)
		pts.append(c + (u * cos(a) + v * sin(a)) * r)
	mb.poly(k, pts, c - n)


## A clay jar (bulb, neck, lip) standing at `base`: glowing seeds heaped in its mouth, a bark stopper, or open.
static func _jar(mb: NatureKit.MB, base: Vector3, r: float, h: float, glow: bool, closed: bool = true) -> void:
	var prof: Array[Vector2] = [Vector2(r * 0.6, 0.0), Vector2(r * 0.92, h * 0.14), Vector2(r, h * 0.38),
		Vector2(r * 0.9, h * 0.62), Vector2(r * 0.58, h * 0.8), Vector2(r * 0.5, h * 0.87), Vector2(r * 0.64, h * 0.93),
		Vector2(r * 0.62, h)]
	mb.lathe("Clay", base, prof, 8, 1.0)
	mb.cap("Clay", NatureKit.ring_n(8, r * 0.6, 0.0, Vector2(base.x, base.z)), base.y, 1.0)
	if glow:
		mb.sphere("Heart", base + Vector3(0, h * 0.95, 0), r * 0.56, 0.62, 7, 4)
	elif closed:
		var c2 := Vector2(base.x, base.z)
		mb.loft("Bark", [NatureKit.ring_n(7, r * 0.52, 0.0, c2), NatureKit.ring_n(7, r * 0.44, 0.0, c2)],
			[base.y + h * 0.9, base.y + h * 1.1], true, false, c2)
	else:
		# Open, empty: the inner lip and a dark inside (bark-dark, no extra material).
		mb.lathe("Clay", base, [Vector2(r * 0.56, h), Vector2(r * 0.46, h * 0.86)] as Array[Vector2], 8, 1.0)
		mb.cap("Bark", NatureKit.ring_n(8, r * 0.47, 0.0, Vector2(base.x, base.z)), base.y + h * 0.86, -1.0)


## A plank crate (edge battens, a top rim, diagonal braces) standing at `base`, turned `yaw`.
static func _crate(mb: NatureKit.MB, base: Vector3, s: float, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	var c: Vector3 = base + Vector3(0, s * 0.5, 0)
	mb.box("Wood", c, Vector3(s, s, s), bs)
	var h: float = s * 0.5
	for cx: float in [-1.0, 1.0]:
		for cz: float in [-1.0, 1.0]:
			mb.box("Bark", c + bs * Vector3(cx * (h + 0.005), 0, cz * (h + 0.005)), Vector3(0.12, s + 0.02, 0.12), bs)
	mb.box("Bark", c + Vector3(0, h - 0.03, 0), Vector3(s + 0.04, 0.08, s + 0.04), bs)
	for f: int in [0, 1]:
		var fb: Basis = bs * Basis(Vector3.UP, PI * 0.5 * float(f))
		mb.box("Bark", c + fb * Vector3(0, 0, h + 0.02), Vector3(s * 1.3, 0.09, 0.05), fb * Basis(Vector3.BACK, PI * 0.25))
		mb.box("Bark", c + fb * Vector3(0, 0, -h - 0.02), Vector3(s * 1.3, 0.09, 0.05), fb * Basis(Vector3.BACK, -PI * 0.25))


## A lumpy burlap sack (tied neck) standing at `base`, leaning `lean` rad, size `s`.
static func _sack(mb: NatureKit.MB, base: Vector3, lean: float, s: float = 1.0) -> void:
	var saved: Transform3D = mb.xf
	mb.xf = saved * Transform3D(Basis(Vector3.RIGHT, lean) * Basis(Vector3.UP, lean * 3.0).scaled(Vector3.ONE * s), base)
	mb.lathe("Clay", Vector3.ZERO, [Vector2(0.26, 0.0), Vector2(0.37, 0.1), Vector2(0.4, 0.3), Vector2(0.34, 0.5),
		Vector2(0.18, 0.62), Vector2(0.1, 0.68), Vector2(0.17, 0.77), Vector2(0.06, 0.84)] as Array[Vector2], 9, 1.0, 0.08, lean)
	mb.cap("Clay", NatureKit.ring_n(9, 0.26), 0.0, 1.0)
	mb.loft("Bark", [NatureKit.ring_n(8, 0.12), NatureKit.ring_n(8, 0.12)], [0.64, 0.7], false, false)
	mb.xf = saved


## A cart wheel leaning on the crates (rim, six spokes, hub), in the YZ plane at `c`, its top toward -X.
static func _wheel(mb: NatureKit.MB, c: Vector3) -> void:
	var saved: Transform3D = mb.xf
	var lean := Basis(Vector3.BACK, deg_to_rad(14.0))
	mb.xf = saved * Transform3D(lean, c)
	var rim: Array[Vector3] = []
	var rad: Array[float] = []
	for i: int in 17:
		var a: float = TAU * float(i) / 16.0
		rim.append(Vector3(0, cos(a) * 0.46, sin(a) * 0.46))
		rad.append(0.065)
	mb.tube("Wood", rim, rad, 6, 1.0, 0.0, 0.0, false, false)
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0
		mb.box("Bark", Vector3(0, cos(a) * 0.23, sin(a) * 0.23), Vector3(0.06, 0.44, 0.07), Basis(Vector3.RIGHT, a))
	mb.xf = saved * Transform3D(lean * Basis(Vector3.BACK, PI * 0.5), c)
	mb.loft("Bark", [NatureKit.ring_n(8, 0.11), NatureKit.ring_n(8, 0.1)], [-0.1, 0.1], true, true)
	mb.xf = saved


## The lean-to leaf roof: a curved mat (Leaves foliage, both faces) under four rows of big team leaves laid like
## shingles from the open high edge (+X) down to the low edge (-X), whose tips droop over it. `lost` = the front-high
## corner only (torn off below 50 % HP); the random numbers are drawn the same way in both builds.
func _mesh_roof(mb: NatureKit.MB, lost: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3120
	var xs: Array[float] = [ROOF_LOW - 0.05, -1.3, -0.3, 0.6, ROOF_HIGH + 0.05]
	var zs: Array[float] = [ROOF_Z.x, -1.4, -0.5, 0.4, ROOF_Z.y]
	for i: int in xs.size() - 1:
		for j: int in zs.size() - 1:
			var in_lost: bool = xs[i] >= 0.5 and zs[j + 1] <= -1.3
			if in_lost != lost:
				continue
			var a := Vector3(xs[i], _roof_y(xs[i]) - 0.02, zs[j])
			var b := Vector3(xs[i + 1], _roof_y(xs[i + 1]) - 0.02, zs[j])
			var c := Vector3(xs[i + 1], _roof_y(xs[i + 1]) - 0.02, zs[j + 1])
			var d := Vector3(xs[i], _roof_y(xs[i]) - 0.02, zs[j + 1])
			var ctr: Vector3 = (a + c) * 0.5
			mb.quad("Leaves", a, b, c, d, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z), Vector2(d.x, d.z),
				ctr - _roof_n(ctr.x))
			var dn := Vector3(0, -0.05, 0)
			mb.quad("Leaves", a + dn, b + dn, c + dn, d + dn, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z),
				Vector2(d.x, d.z), ctr + _roof_n(ctr.x))
	# [stem x, length, z offset]; the upper rows lie on top of the lower ones (shingles).
	var rows: Array = [[ROOF_HIGH + 0.12, 1.5, 0.0], [0.62, 1.5, 0.4], [-0.33, 1.45, 0.0], [-1.25, 1.35, 0.4]]
	for r: int in rows.size():
		var row: Array = rows[r]
		var z: float = ROOF_Z.x + 0.35 + float(row[2])
		while z < ROOF_Z.y - 0.3:
			var zj: float = z + rng.randf_range(-0.08, 0.08)
			var ln: float = float(row[1]) * rng.randf_range(0.92, 1.08)
			var w: float = 1.28 * rng.randf_range(0.95, 1.08)
			var yaw: float = rng.randf_range(-0.12, 0.12)
			var id: float = rng.randf()
			var ph: float = rng.randf()
			var tone: float = rng.randf_range(0.74, 1.0)
			var is_lost: bool = r == 0 and z < -1.1
			z += 0.8
			if is_lost != lost:
				continue
			var d := Vector3(-cos(yaw), 0.0, sin(yaw))
			var side := Vector3(sin(yaw), 0.0, cos(yaw))
			var pts: Array[Vector3] = []
			var nrms: Array[Vector3] = []
			for k: int in 4:
				var s: float = ln * float(k) / 3.0
				var x: float = float(row[0]) + d.x * s
				var y: float = _roof_y(x) + 0.05 + 0.035 * float(rows.size() - 1 - r)
				if x < ROOF_LOW:
					y -= (ROOF_LOW - x) * 0.95
				pts.append(Vector3(x, y, zj + d.z * s))
				var n: Vector3 = _roof_n(x)
				if x < ROOF_LOW:
					n = (n + Vector3(-0.9, 0.0, 0.0)).normalized()
				nrms.append(n)
			var ao: float = tone * (0.86 + 0.04 * float(r))
			mb.col = Color(ao, ao, ao, 1.0)
			mb.strip("LeafCard", pts, side, w, nrms, id, ph)
	mb.col = Color.WHITE
	if lost:
		return
	# Leafy knots where the two back ribs turn at the open edge (volume on the flat roof, the hall's clump language).
	var krng := RandomNumberGenerator.new()
	krng.seed = 3125
	var knots: Array = []
	for z: float in [RIBS[1], RIBS[2]]:
		var c := Vector3(ROOF_HIGH - 0.35, _roof_y(ROOF_HIGH - 0.35) + 0.12, z)
		knots.append(NatureKit.make_blob(krng, c, 0.42, Vector3(1.0, 0.8, 1.25), 0.7, Vector3(0.4, 1.0, 0.0).normalized(), 8))
	for k: int in knots.size():
		var b: NatureKit.Blob = knots[k]
		NatureKit.blob_mesh(mb, b, 1, 0.3 + 0.1 * float(k), knots)
		NatureKit.clump_cards(mb, b, krng, 5, 0, knots, 0.6)


## A glow-fruit lantern (the Heartwood's seed-lantern, smaller) under its swinging pivot.
func _mesh_lantern(mb: NatureKit.MB) -> void:
	NatureKit.lantern(mb, 0.42, Vector3(0.04, 0, 0.05), 0.8)


## The mast (tree-local, origin at TREE): three braided bark strands and a core, limbs into the small crown, the
## gallows arm reaching forward (curled tip) with a knee brace, the vine the sign hangs from, twigs and a beard.
func _mesh_mast(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3130
	var top_y: float = 7.25
	for k: int in 3:
		var phase: float = deg_to_rad(120.0 * float(k) + 35.0)
		var pts: Array[Vector3] = []
		var rad: Array[float] = []
		for i: int in 12:
			var t: float = float(i) / 11.0
			var y: float = lerpf(0.25, top_y, t)
			var a: float = phase + deg_to_rad(220.0) * t
			var flare: float = 0.3 * (1.0 - smoothstep(0.0, 0.22, t))
			var off: float = lerpf(0.44, 0.17, pow(t, 0.7)) + flare + 0.03 * sin(t * 8.0 + float(k))
			pts.append(Vector3(sin(a) * off, y, -cos(a) * off))
			rad.append(lerpf(0.36, 0.18, t) + flare * 0.6)
		var cl: Vector4 = CROWN[k]
		var target := Vector3(cl.x, cl.y - cl.w * 0.3, cl.z)
		var last: Vector3 = pts[pts.size() - 1]
		pts.append(last.lerp(target, 0.5) + Vector3(0, 0.25, 0))
		rad.append(0.15)
		pts.append(target)
		rad.append(0.09)
		mb.tube("Bark", pts, rad, 8, 2.0, 0.08, float(k) * 1.9, false, true)
	mb.tube("Bark", [Vector3(0, 0.2, 0), Vector3(0.02, 3.0, 0.0), Vector3(0.0, top_y + 0.15, 0.02)] as Array[Vector3],
		[0.55, 0.42, 0.24] as Array[float], 10, 2.0, 0.06, 0.7, false, true)
	# The gallows arm: out of the mast below the crown, forward over the stall (a gentle upward bow), a curled tip;
	# a knee brace under it.
	var hook: Vector3 = HOOK - TREE
	var a0 := Vector3(0.0, 6.35, -0.05)
	var a1: Vector3 = hook + Vector3(0.0, 0.22, 0.12)
	var fwd: Vector3 = Vector3(a1.x - a0.x, 0.0, a1.z - a0.z).normalized()
	var arm_at := func(t: float) -> Vector3:
		return a0.lerp(a1, t) + Vector3(0, 0.5 * sin(PI * t) * (1.0 - 0.3 * t), 0)
	var arm: Array[Vector3] = [arm_at.call(0.0), arm_at.call(0.2), arm_at.call(0.45), arm_at.call(0.72), a1,
		hook + fwd * 0.28 + Vector3(0, 0.16, 0), hook + fwd * 0.4 + Vector3(0, -0.08, 0), hook + fwd * 0.2 + Vector3(0, -0.2, 0)]
	mb.tube("Bark", arm, [0.28, 0.24, 0.2, 0.16, 0.13, 0.1, 0.075, 0.05] as Array[float], 8, 2.0, 0.07, 3.3, false, true)
	var knee: Vector3 = arm_at.call(0.45)
	mb.tube("Bark", [Vector3(0.0, 4.8, -0.15), Vector3(0.0, 4.8, -0.15).lerp(knee, 0.4) + fwd * 0.12,
		Vector3(0.0, 4.8, -0.15).lerp(knee, 0.75) + fwd * 0.08, knee - Vector3(0, 0.05, 0)] as Array[Vector3],
		[0.16, 0.13, 0.1, 0.08] as Array[float], 6, 1.0, 0.08, 1.3, false, true)
	# Twin-twisted vine down to the hub.
	var hub: Vector3 = HUB - TREE
	for s: float in [-1.0, 1.0]:
		var vp: Array[Vector3] = []
		var vr: Array[float] = []
		for i: int in 6:
			var t: float = float(i) / 5.0
			var a: float = t * PI * 2.0 + (0.0 if s < 0.0 else PI)
			vp.append(Vector3(hook.x + cos(a) * 0.035, lerpf(hook.y + 0.1, hub.y + 0.1, t), hook.z + sin(a) * 0.035))
			vr.append(0.045)
		mb.tube("Bark", vp, vr, 5, 1.0, 0.0, 0.0, false, false)
	# Crown clumps + the tuft on the arm.
	var blobs: Array = []
	for k: int in CROWN.size():
		var cl: Vector4 = CROWN[k]
		var out := Vector3(cl.x, 0.0, cl.z)
		out = out.normalized() if out.length() > 0.1 else Vector3.ZERO
		blobs.append(NatureKit.make_blob(rng, Vector3(cl.x, cl.y, cl.z), cl.w, Vector3.ONE, 0.78, out, 11, k == 0))
	var tuft: Vector3 = arm_at.call(0.42) + Vector3(0, 0.22, 0)
	var tuft_scale: Vector3 = Vector3(1.0, 0.9, 1.0) + Vector3(absf(fwd.x), 0.0, absf(fwd.z)) * 0.3
	blobs.append(NatureKit.make_blob(rng, tuft, 0.45, tuft_scale, 0.7, Vector3.UP, 8))
	for k: int in blobs.size():
		var b: NatureKit.Blob = blobs[k]
		NatureKit.blob_mesh(mb, b, 2, 0.6 + float(k) / 10.0, blobs)
		NatureKit.clump_cards(mb, b, rng, int(6.0 + b.r * 7.0), 2 if k == 0 else (1 if k < 3 else 0), blobs, 0.75)
	# Bare twigs out of the crown (silhouette) and a moss beard under the arm.
	for i: int in 3:
		var d: Vector3 = NatureKit.dir_deg(100.0 + 110.0 * float(i) + rng.randf_range(-15.0, 15.0))
		var s: Vector3 = d * 0.5 + Vector3(0, 8.4 + rng.randf_range(0.0, 0.2), 0.2)
		var e: Vector3 = d * rng.randf_range(1.2, 1.6) + Vector3(0, 9.1 + rng.randf_range(0.0, 0.3), 0.2)
		mb.tube("Bark", [s, s.lerp(e, 0.5) + Vector3(0, 0.12, 0), e] as Array[Vector3], [0.07, 0.045, 0.015] as Array[float], 5, 1.0)
	var bd: Vector3 = arm_at.call(0.68) - Vector3(0, 0.12, 0)
	mb.tube("Bark", [bd, bd + Vector3(0.05, -0.45, 0.0), bd + Vector3(-0.02, -0.9, 0.04)] as Array[Vector3],
		[0.07, 0.05, 0.012] as Array[float], 5, 1.0, 0.15, 2.0)


## The scale's beam (beam-local, origin at the hub, beam along local X; the node turns it along Z): a bark beam with
## curled ends and gold knobs, a gold hub, and the pointer: a gold coin (raised rim, a glowing leaf inlaid on both
## faces) hanging below the hub, facing local -Z (+X in the building).
func _mesh_beam(mb: NatureKit.MB) -> void:
	var h: float = BEAM_HALF
	mb.tube("Bark", [Vector3(-h - 0.06, 0.18, 0), Vector3(-h + 0.12, 0.05, 0), Vector3(-0.5, 0.0, 0), Vector3(0.5, 0.0, 0),
		Vector3(h - 0.12, 0.05, 0), Vector3(h + 0.06, 0.18, 0)] as Array[Vector3],
		[0.08, 0.11, 0.13, 0.13, 0.11, 0.08] as Array[float], 8, 1.0, 0.05, 1.0, true, true)
	for s: float in [-1.0, 1.0]:
		mb.sphere("Gold", Vector3(s * (h + 0.07), 0.21, 0), 0.11, 1.0, 6, 4)
	var saved: Transform3D = mb.xf
	# Hub: a gold drum across the beam.
	mb.xf = saved * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	mb.loft("Gold", [NatureKit.ring_n(8, 0.2), NatureKit.ring_n(8, 0.2)], [-0.13, 0.13], true, true)
	mb.xf = saved
	# Pointer stem and the coin.
	mb.box("Gold", Vector3(0, -0.26, 0), Vector3(0.09, 0.32, 0.09))
	var cc := Vector3(0, -0.82, 0)
	var r: float = 0.5
	mb.xf = saved * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), cc)   # coin-local +y = local -Z (its front face)
	var outer: Array = NatureKit.ring_n(16, r)
	var inner: Array = NatureKit.ring_n(16, r - 0.1)
	mb.loft("Gold", [outer, outer], [-0.1, 0.1], false, false)   # the edge, full rim thickness
	for f: float in [1.0, -1.0]:
		var y0: float = 0.06 * f
		var y1: float = 0.1 * f
		# Rim top (faces out of this face), then its inner wall (faces the centre).
		mb.flip = f < 0.0
		mb.annulus("Gold", outer, inner, y1)
		mb.flip = true
		mb.loft("Gold", [inner, inner], [minf(y0, y1), maxf(y0, y1)], false, false)
		mb.flip = false
		# The coin's face and the glowing leaf inlay with a gold midrib.
		mb.cap("Gold", inner, y0, -f)
		var leaf: Array[Vector3] = []
		for i: int in 14:
			var t: float = float(i) / 13.0
			var ww: float = pow(sin(PI * t), 0.8) * 0.19
			leaf.append(Vector3(ww, y0 + 0.012 * f, lerpf(-0.3, 0.3, t)))
		for i: int in range(12, 0, -1):
			var t: float = float(i) / 13.0
			var ww: float = pow(sin(PI * t), 0.8) * 0.19
			leaf.append(Vector3(-ww, y0 + 0.012 * f, lerpf(-0.3, 0.3, t)))
		mb.poly("Gate", leaf, Vector3(0, y0 - f, 0))
		mb.box("Gold", Vector3(0, y0 + 0.028 * f, 0.0), Vector3(0.045, 0.03, 0.62))
	mb.xf = saved


## A scale pan (pan-local, origin at the beam end it hangs from): three cords, a gold ring, a wooden bowl with a
## gold rim; the gold pan holds a heap of coins, the other a glowing seed in a calyx.
func _mesh_pan(mb: NatureKit.MB, gold: bool) -> void:
	var y: float = -PAN_DROP
	for i: int in 3:
		var a: float = TAU * float(i) / 3.0 + 0.5
		var rim := Vector3(cos(a) * 0.4, y + 0.02, sin(a) * 0.4)
		mb.tube("Wood", [Vector3(0, -0.04, 0), (Vector3(0, -0.04, 0) + rim) * 0.5, rim] as Array[Vector3],
			[0.03, 0.03, 0.03] as Array[float], 4, 1.0)
	mb.sphere("Gold", Vector3(0, -0.03, 0), 0.08, 1.0, 6, 4)
	mb.lathe("Wood", Vector3.ZERO, [Vector2(0.04, y - 0.24), Vector2(0.24, y - 0.22), Vector2(0.38, y - 0.13),
		Vector2(0.45, y - 0.01)] as Array[Vector2], 12, 2.0)
	mb.lathe("Wood", Vector3.ZERO, [Vector2(0.4, y), Vector2(0.33, y - 0.11), Vector2(0.2, y - 0.17),
		Vector2(0.03, y - 0.18)] as Array[Vector2], 12, 2.0)
	mb.loft("Gold", [NatureKit.ring_n(12, 0.47), NatureKit.ring_n(12, 0.47)], [y - 0.06, y + 0.02], false, false)
	mb.annulus("Gold", NatureKit.ring_n(12, 0.47), NatureKit.ring_n(12, 0.39), y + 0.02)
	if gold:
		mb.sphere("Gold", Vector3(0, y - 0.06, 0), 0.34, 0.45, 8, 4)
		var rng := RandomNumberGenerator.new()
		rng.seed = 3141
		var saved: Transform3D = mb.xf
		for i: int in 4:
			var a: float = TAU * float(i) / 4.0 + rng.randf_range(-0.3, 0.3)
			var p := Vector3(cos(a) * 0.16, y + 0.07 + rng.randf_range(0.0, 0.05), sin(a) * 0.16)
			mb.xf = saved * Transform3D(Basis(Vector3(sin(a), 0, -cos(a)), rng.randf_range(0.3, 0.65)), p)
			mb.loft("Gold", [NatureKit.ring_n(8, 0.13), NatureKit.ring_n(8, 0.13)], [-0.02, 0.02], true, true)
		mb.xf = saved
	else:
		mb.sphere("Heart", Vector3(0, y + 0.13, 0), 0.23, 1.25, 8, 5)
		mb.loft("Wood", [NatureKit.ring_n(7, 0.08), NatureKit.ring_n(7, 0.24)], [y - 0.1, y + 0.03], false, false)


## Banner `i` under its standard's crossbar.
func _mesh_banner(mb: NatureKit.MB, i: int) -> void:
	var face: Vector3 = NatureKit.dir_deg(STANDARD_DEG[i])
	var bar: Vector3 = STANDARDS[i] + Vector3(0, 3.6 - 0.5, 0) + face * 0.1
	mb.banner(bar + Vector3(0, -0.06, 0) + face * 0.08, face, 0.9, 2.0, 1.3 + 1.9 * float(i))


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
	_ground_mat = NatureKit.ground_material(10.5, 3.1, 5.3, 0.0, 4.35, 22.0, 3.0)
	decal.material_override = _ground_mat
	_part_node("GroundDressing", "dressing", _mesh_dressing, self, -0.3, 1.5, false)


func _mesh_dressing(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3160
	# Flagstones leading out of the caravan gate.
	for i: int in 2:
		mb.box("Dark", Vector3(0.7 + rng.randf_range(-0.3, 0.3), 0.03, -3.85 - 0.7 * float(i)), Vector3(rng.randf_range(0.9, 1.1),
			0.08, rng.randf_range(0.5, 0.6)), Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)))
	NatureKit.dressing(mb, rng, 6, 5, 2, 3.45, 4.4, _dress_blocked)


## Keep the caravan path clear of ground dressing.
static func _dress_blocked(p: Vector3) -> bool:
	return p.z < -2.6 and p.x > -0.9 and p.x < 2.3


## Construction site: poles and woven decks round the stall, a staked sapling where the mast will stand, a pile of
## logs and a stack of empty jars. Child of the root, visible while 0 < progress < 1.
func _build_scaffold_market() -> void:
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	add_child(_scaffold)
	_part_node("ScaffoldParts", "scaffold", _mesh_scaffold, _scaffold, 0.0, 4.5)
	_scaffold.visible = false


func _mesh_scaffold(mb: NatureKit.MB) -> void:
	var x0: float = -2.45
	var x1: float = 1.75
	var z0: float = -2.45
	var z1: float = 1.35
	var top: float = 3.9
	for c: Vector2 in [Vector2(x0, z0), Vector2(x1, z0), Vector2(x0, z1), Vector2(x1, z1)]:
		var b := Vector3(c.x, 0.0, c.y)
		mb.tube("Wood", [b, b + Vector3(0.03, top * 0.5, 0), b + Vector3(0, top + 0.4, 0)] as Array[Vector3],
			[0.09, 0.085, 0.07] as Array[float], 6, 1.0, 0.1, c.x + c.y)
	for y: float in [top * 0.5, top]:
		for z: float in [z0, z1]:
			mb.box("Wood", Vector3((x0 + x1) * 0.5, y, z), Vector3(x1 - x0 + 0.3, 0.08, 0.5), Basis(Vector3.BACK, 0.02))
		for x: float in [x0, x1]:
			mb.box("Wood", Vector3(x, y, (z0 + z1) * 0.5), Vector3(0.5, 0.08, z1 - z0 + 0.3), Basis(Vector3.RIGHT, 0.02))
	var ang: float = atan2(top - 0.5, z1 - z0)
	mb.box("Wood", Vector3(x1 + 0.1, (top + 0.5) * 0.5, (z0 + z1) * 0.5), Vector3(0.08, 0.08,
		sqrt((z1 - z0) * (z1 - z0) + (top - 0.5) * (top - 0.5))), Basis(Vector3.RIGHT, -ang))
	# The staked sapling (the mast to be), tied to a tall pole.
	var t := Vector3(TREE.x, TOP, TREE.z)
	mb.tube("Wood", [t + Vector3(0.35, -TOP, 0.0), t + Vector3(0.35, 6.0, 0.0)] as Array[Vector3], [0.08, 0.06] as Array[float], 6, 1.0)
	mb.tube("Bark", [t, t + Vector3(-0.05, 1.8, 0.04), t + Vector3(0.05, 3.6, -0.03)] as Array[Vector3],
		[0.2, 0.13, 0.05] as Array[float], 7, 1.0, 0.08, 1.0)
	for y: float in [1.3, 2.7]:
		var rc := Vector2(t.x + 0.18, t.z)
		mb.loft("Bark", [NatureKit.ring_n(8, 0.3, 0.0, rc), NatureKit.ring_n(8, 0.3, 0.0, rc)], [t.y + y, t.y + y + 0.07], false,
			false, rc)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3170
	for k: int in 3:
		var d: Vector3 = NatureKit.dir_deg(80.0 + 120.0 * float(k))
		var s0: Vector3 = t + Vector3(0, 3.3 + 0.1 * float(k), 0)
		var dir: Vector3 = (d * 0.7 + Vector3.UP * 0.6).normalized()
		var nn: Vector3 = (Vector3.UP + d * 0.3).normalized()
		mb.strip("LeafCard", [s0, s0 + dir * 0.3, s0 + dir * 0.55 + Vector3(0, -0.1, 0)] as Array[Vector3],
			d.cross(Vector3.UP).normalized(), 0.34, [nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())
	# A pile of logs at the front and a stack of empty jars at the back-right.
	for l: Vector3 in [Vector3(-2.0, 0.2, -3.45), Vector3(-1.6, 0.2, -3.45), Vector3(-1.8, 0.52, -3.45)]:
		mb.tube("Bark", [Vector3(l.x - 0.8, l.y, l.z), Vector3(l.x + 0.8, l.y, l.z)] as Array[Vector3], [0.2, 0.2] as Array[float],
			8, 2.0, 0.05, l.x, true, true)
	_jar(mb, Vector3(2.4, TOP, 1.6), 0.25, 0.62, false, false)
	_jar(mb, Vector3(2.0, TOP, 2.2), 0.22, 0.54, false)
	_crate(mb, Vector3(1.3, TOP, 2.3), 0.6, 0.3)


## Collapse leftovers (shown at 1.6 s): the mast's shattered stump, the counter split in two, tumbled crates,
## smashed jars with scattered glowing seeds, fallen withered roof leaves, broken ribs, a fallen banner pole.
func _build_wreck_market() -> void:
	_wreck = Node3D.new()
	_wreck.name = "Wreck"
	add_child(_wreck)
	_part_node("WreckParts", "wreck", _mesh_wreck, _wreck, 0.0, 2.5)
	_wreck.visible = false


func _mesh_wreck(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3150
	_roots(mb)
	# The stump.
	var t := Vector3(TREE.x, 0.2, TREE.z)
	var tc := Vector2(t.x, t.z)
	mb.tube("Bark", [t, t + Vector3(0, 1.55, 0)] as Array[Vector3], [0.85, 0.72] as Array[float], 10, 2.0, 0.08, 1.0, false, false)
	mb.loft("Wood", [NatureKit.ring_n(10, 0.7, 0.0, tc), NatureKit.ring_n(10, 0.62, 0.0, tc)], [t.y + 1.53, t.y + 1.63], true,
		false, tc)
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0 + rng.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var b: Vector3 = t + d * rng.randf_range(0.5, 0.68) + Vector3(0, 1.5, 0)
		var h: float = rng.randf_range(0.4, 1.2)
		mb.tube("Bark", [b, b + d * 0.08 + Vector3(0, h * 0.6, 0), b + d * 0.14 + Vector3(0, h, 0)] as Array[Vector3],
			[rng.randf_range(0.13, 0.2), 0.09, 0.0] as Array[float], 5, 1.0, 0.0, 0.0, false, false)
	# The counter split in two, lying askew on the flagstones.
	var y: float = TOP + LOG_R * 0.85
	for half: Array in [[Vector3(-0.05, y, -2.05), Vector3(0.3, y, -0.6)], [Vector3(-0.55, y, -0.3), Vector3(0.1, y, 1.0)]]:
		var a: Vector3 = half[0]
		var b: Vector3 = half[1]
		mb.tube("Bark", [a, a.lerp(b, 0.5) + Vector3(0, 0.03, 0), b] as Array[Vector3], [LOG_R * 0.95, LOG_R, LOG_R * 0.92] as Array[float],
			12, 3.0, 0.07, a.z, false, false)
		var n: Vector3 = (a - b).normalized()
		_disc(mb, "Wood", a + n * 0.005, n, LOG_R * 0.92, 12)
		for k: int in 6:
			var ang: float = TAU * float(k) / 6.0
			var off: Vector3 = (n.cross(Vector3.UP).normalized() * cos(ang) + Vector3.UP * sin(ang)) * LOG_R * 0.6
			mb.tube("Wood", [b + off, b + off - n * rng.randf_range(0.25, 0.55)] as Array[Vector3], [0.13, 0.0] as Array[float],
				4, 1.0, 0.0, 0.0, false, false)
	# Tumbled crates, a sack, smashed jars (shards) and seeds scattered like embers.
	_crate(mb, Vector3(1.85, TOP - 0.05, 1.75), 0.9, 0.5)
	var saved: Transform3D = mb.xf
	mb.xf = Transform3D(Basis(Vector3.RIGHT, 0.5) * Basis(Vector3.UP, 0.9), Vector3(1.0, TOP + 0.05, 2.3))
	_crate(mb, Vector3.ZERO, 0.75, 0.0)
	mb.xf = saved
	_sack(mb, Vector3(1.3, TOP, 1.0), 0.35)
	for i: int in 9:
		var p := Vector3(rng.randf_range(-2.4, 1.6), TOP + 0.08, rng.randf_range(-2.5, 1.2))
		mb.box("Clay", p, Vector3(rng.randf_range(0.2, 0.34), 0.08, rng.randf_range(0.14, 0.26)),
			Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.4, 0.4)))
	for i: int in 7:
		var p := Vector3(rng.randf_range(-2.2, 1.6), TOP + 0.06, rng.randf_range(-2.4, 1.0))
		mb.box("Gate", p, Vector3.ONE * 0.2, Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, 0.3))
	# Withered roof leaves on the ground and the ribs broken off.
	for i: int in 6:
		var p := Vector3(rng.randf_range(-2.4, 1.2), TOP + 0.05 + 0.02 * float(i), rng.randf_range(-2.3, 1.0))
		var d: Vector3 = NatureKit.dir_deg(rng.randf_range(0.0, 360.0))
		var side := Vector3(-d.z, 0, d.x)
		mb.strip("LeafCard", [p, p + d * 0.6 + Vector3(0, 0.1, 0), p + d * 1.3 + Vector3(0, 0.02, 0)] as Array[Vector3],
			side, 1.1, [Vector3.UP, Vector3.UP, Vector3.UP] as Array[Vector3], rng.randf(), rng.randf())
	for z: float in RIBS:
		var h: float = rng.randf_range(0.6, 1.3)
		var b := Vector3(ROOF_LOW + 0.05, TOP - 0.1, z)
		mb.tube("Bark", [b, b + Vector3(0.02, h * 0.6, 0), b + Vector3(0.05, h, 0.02)] as Array[Vector3], [0.16, 0.13, 0.1] as Array[float],
			7, 1.0, 0.08, z, false, false)
		var rc := Vector2(b.x + 0.05, b.z + 0.02)
		mb.loft("Wood", [NatureKit.ring_n(7, 0.1, 0.0, rc), NatureKit.ring_n(7, 0.08, 0.0, rc)], [b.y + h - 0.02, b.y + h + 0.04],
			true, false, rc)
	# A fallen banner pole at the gate.
	var s0: Vector3 = STANDARDS[1] + Vector3(0, 0.1, 0)
	mb.tube("Wood", [s0, s0 + Vector3(-1.1, 0.05, -0.3), s0 + Vector3(-2.2, 0.12, -0.45)] as Array[Vector3],
		[0.12, 0.1, 0.07] as Array[float], 7, 1.0, 0.1, 2.0)


# ============================================================ particles and states

## Ambient life (only near the camera): sap motes rising from the barrel, leaves drifting off the crown and roof.
func _build_ambient() -> void:
	var glow_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.15, 0.7, 1.0], [Color(glow_color, 0.0),
		Color(glow_color, 1.0), Color(glow_color, 0.8), Color(glow_color, 0.0)], _glow_ramps)
	var po := _pm(Vector3.UP, 30.0, 0.15, 0.4, Vector3(0, 0.1, 0), 0.08, 0.03, glow_ramp)
	po.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	po.emission_sphere_radius = 0.3
	po.color = NatureKit.MOTE_DIM
	po.turbulence_enabled = true
	po.turbulence_noise_strength = 0.3
	_ambient.append(_particles("SapMotes", _body, BARREL + Vector3(0, 0.8, 0), 10, 3.2, po, NatureKit.soft_quad(true), false))
	var t := kingdom_color
	var leaf_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.08, 0.8, 1.0], [Color(t, 0.0), Color(t, 1.0),
		Color(t.darkened(0.2), 1.0), Color(t.darkened(0.3), 0.0)], _leaf_ramps)
	var lv := _pm(Vector3.DOWN, 20.0, 0.4, 0.9, Vector3(0.3, -0.3, 0.1), 0.28, 0.24, leaf_ramp)
	lv.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	lv.emission_box_extents = Vector3(1.8, 2.0, 1.7)
	lv.angle_min = 0.0
	lv.angle_max = 360.0
	lv.angular_velocity_min = -120.0
	lv.angular_velocity_max = 120.0
	lv.turbulence_enabled = true
	lv.turbulence_noise_strength = 0.6
	lv.turbulence_noise_scale = 2.0
	_ambient.append(_particles("Leaves", _body, Vector3(-0.5, 5.8, 0.4), 7, 5.5, lv, NatureKit.shape_quad(0), false))


## The delivery sparks: gold glints bursting out of the gold pan.
func _build_delivery_fx() -> void:
	var gold_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.1, 0.6, 1.0], [Color(1.0, 0.92, 0.55, 0.0),
		Color(1.0, 0.86, 0.42, 1.0), Color(1.0, 0.74, 0.28, 0.8), Color(1.0, 0.68, 0.22, 0.0)])
	var pm := _pm(Vector3.UP, 55.0, 0.9, 2.0, Vector3(0, -1.4, 0), 0.17, 0.05, gold_ramp)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.38
	var at: Vector3 = HUB + Basis(Vector3.UP, BEAM_YAW) * Vector3(-BEAM_HALF, -PAN_DROP, 0.0)
	_coin_burst = _particles("CoinGlint", _body, at, 22, 1.1, pm, _add_quad, true)


## Base state nodes, then the Nature looks: the "blaze" plumes become withering leaves pouring down, and the
## lost-corner cubes are replaced by the torn-off roof leaves lying on the ground.
func _build_state_nodes() -> void:
	super()
	for b: GPUParticles3D in _blaze:
		NatureKit.make_withering(b, 1.2, 16)
	_rubble2.multimesh.instance_count = 0
	var fallen: MeshInstance3D = _part_node("FallenLeaves", "fallen", _mesh_fallen, _body, 0.3, 1.0)
	fallen.visible = false
	_show_below_50.append(fallen)


## Below 50 % HP: the two torn-off roof leaves lie on the flagstones at the open side, with a snapped rib tip.
func _mesh_fallen(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3180
	for p: Vector3 in [Vector3(1.0, TOP + 0.05, -2.3), Vector3(1.9, TOP + 0.08, -1.3)]:
		var d: Vector3 = NatureKit.dir_deg(rng.randf_range(20.0, 150.0))
		var side := Vector3(-d.z, 0, d.x)
		mb.strip("LeafCard", [p, p + d * 0.55 + Vector3(0, 0.14, 0), p + d * 1.2 + Vector3(0, 0.03, 0)] as Array[Vector3],
			side, 1.15, [Vector3.UP, Vector3.UP, Vector3.UP] as Array[Vector3], rng.randf(), rng.randf())
	mb.tube("Bark", [Vector3(1.4, TOP + 0.08, -2.0), Vector3(1.9, TOP + 0.1, -2.15), Vector3(2.3, TOP + 0.06, -2.0)] as Array[Vector3],
		[0.09, 0.08, 0.06] as Array[float], 6, 1.0, 0.06, 1.0, true, true)


func _apply_health() -> void:
	super()
	var built: bool = _progress >= 1.0
	var hurt: bool = built and _health_ratio < 0.5
	var dying: bool = built and _health_ratio < 0.25
	NatureKit.apply_health(_mats, _health_ratio, hurt, dying)
	var dmg: float = 1.0 if dying else (0.6 if hurt else (1.0 - _health_ratio) * 0.5)
	(_mats["Clay"] as ShaderMaterial).set_shader_parameter(&"damage", dmg)
	_gold.set_shader_parameter(&"damage", dmg)
	NatureKit.NVC.sync_gold(_mats)
	_agitated = dying
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"damage", 1.0 if dying else (0.5 if hurt else 0.0))


## The Heartwood's green idle rim instead of the base one (selection still turns it to the team colour); the gold
## keeps a warm rim of its own and takes the team colour only when selected.
func _apply_rim_and_glow() -> void:
	if not _ready_done:
		return
	var building: bool = _progress < 1.0 and not _destroyed
	NatureKit.apply_rim(_mats, _team_color, _sel_k, building)
	NatureKit.apply_boost(_mats, _sel_boost())
	var k: float = maxf(_sel_k, 0.65) if building else _sel_k
	var clay: ShaderMaterial = _mats["Clay"]
	clay.set_shader_parameter(&"rim_color", NatureKit.RIM_IDLE.lerp(_team_color.lightened(0.2), k))
	clay.set_shader_parameter(&"rim_strength", lerpf(NatureKit.RIM_IDLE_STRENGTH, 0.9, k))
	_gold.set_shader_parameter(&"rim_color", Color(1.0, 0.86, 0.5).lerp(_team_color.lightened(0.2), k))
	_gold.set_shader_parameter(&"rim_strength", lerpf(0.3, 0.9, k))
	NatureKit.NVC.sync_gold(_mats)


## Collapse: the base sequence, then the moss withers, the sap drains and the leaves brown.
func _process_destroyed(delta: float) -> void:
	super(delta)
	var k: float = clampf((_destroy_t - 2.0) / 1.0, 0.0, 1.0)
	if _destroy_t >= 0.6:
		NatureKit.apply_wreck(_mats, k)
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"scorch", k)
