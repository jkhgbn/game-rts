class_name StablesModel
extends FireHallModel
## Shared visual model of the four Stables (docs/design/stables.md, cavalry-mounts.md 13.V21-24; style art-keep.md 0,
## each kingdom's Hall / Keep language). Subclasses: EmberStablesModel (fire), GloomStablesModel (shadow),
## FrostStablesModel (ice), GroveStablesModel (nature): they set the palette and override the `_k_*` hooks (kingdom
## skins, roof crest, tower top, fence posts, props, the mount).
## Read from the RTS camera (footprint 3 x 3 cells = 6 x 6 m, gate = local -Z, toward the map centre; the player's
## camera sees the local +X side, the enemy's the -X side, the lab's first view the +Z back):
## - a long low stable barn (along local X, back half) on a battered stone foundation: stone lower course, timber-framed
##   upper walls, a row of three stalls facing the paddock (half-doors, dark upper openings, a mount looking out) under
##   the roof's deep front eave on posts, a big double barn door and a warm gable window on the +X end, a back stall
##   with a second mount looking out, a hay rack and a warm window on the back (+Z);
## - its bell-cast gable roof in the TEAM colour (tile courses on both slopes = the top-facing team area), the
##   kingdom's crest, a ventilation cupola with a weathervane (the secondary hook);
## - the dominant vertical: a two-storey HAY LOFT tower at the -X end (the far side from the player's camera, so it
##   rises clear above the barn's roofline), its own team roof with the gable toward the paddock, an open loft door
##   spilling hay, a HOIST beam with a pulley and a hanging hay bale that sways, the kingdom's top (chimney / spire /
##   crystal / living crown);
## - the PADDOCK (front half): lumpy packed earth and straw, a fence all round with a two-leaf gate (it swings open
##   when a rider is trained), the kingdom's MOUNT standing in it (head grazes, tail swishes), a water trough, a
##   hitching rail, stacked hay bales, a saddle rack with a team saddle cloth, a lantern post and a team banner.
## Hooks (FireHallModel contract, art-keep.md 8.8; all safe before _ready): set_team_color, set_construction_progress
## (parts rise, scaffolding, the mount only once built), set_health_ratio (< 50 %: smoke, a caved roof patch, a broken
## fence rail, the hoist bale gone; < 25 %: fire, a burning roof hole, the tower banner lost, the mount has bolted),
## play_training_pulse / play_trained (the gate leaves swing open and shut, the windows flare, the mount tosses its
## head), play_destroyed (the loft tower topples outward, the barn sinks, a wreck of beams, tiles, hay and fence rails
## stays; `destroyed_finished` after 3 s), set_selected.
## Budgets (building/hall: <= 8 materials, <= 32 draws, <= 12 000 verts, 0 lights): every opaque part is ONE material
## (stables_painted.gdshader: the painted look, colour blocks from vertex colours, team parts masked by vertex alpha),
## merged per tier (one surface per material, baked once per kingdom and shared); + banner, kingdom glow, warm window
## glow, contact decal, construction outline and the two shared particle quads = 8 materials. No real light: the base
## class's light is a detached proxy that is never added to the tree.

const PAINT: Shader = preload("res://art/buildings/stables/stables_painted.gdshader")
const K_PLAIN := 0
const K_STONE := 1
const K_METAL := 2
const K_HOT := 3
const K_HOLE := 4
const PT := 0.8                      ## foundation top (= FireHallModel.PLINTH_TOP: the collapse squashes about it)
const BX0 := -1.45                   ## barn walls x range
const BX1 := 2.8
const BZ0 := 0.25                    ## barn stall front (-Z face)
const BZ1 := 2.85                    ## barn back
const EAVE := 2.95                   ## barn wall top
const TX := -2.15                    ## loft tower centre x / z, half sizes
const TZ := 1.75
const THX := 0.85
const THZ := 1.15
const T_EAVE := 5.25                 ## tower wall top
const TR := 1.02                     ## loft tower radius (round tower)
const TSEG := 10                     ## tower / cone sides
const GATE_HALF := 0.72              ## paddock gate half width
const FZ := -2.9                     ## paddock front fence line
const FX := 2.85                     ## paddock side fences
const SWING_TIME := 1.6
const STALLS: Array[float] = [-0.72, 0.58, 1.88]
const ROOF_HD := 1.85                ## barn roof half depth at the eave (front eave over the stall posts)
const ROOF_CZ := 1.3                 ## barn roof ridge z (forward of the walls centre: deep front eave, short back eave)

static var _vc_cache: Dictionary = {}
static var _prim_cache: Dictionary = {}
static var _shared_quads: Dictionary = {}

# Palette (subclasses set it in _setup_palette).
var c_found := Color(0.14, 0.12, 0.12)      ## foundation / dark stone
var c_stone := Color(0.32, 0.28, 0.26)      ## stone blocks
var c_wall := Color(0.36, 0.25, 0.16)       ## wall infill (planks / wattle)
var c_beam := Color(0.20, 0.13, 0.09)       ## timber frame, dark wood
var c_wood := Color(0.48, 0.32, 0.18)       ## doors, rails, crates (light wood)
var c_trim := Color(0.62, 0.40, 0.16)       ## metal trim
var c_straw := Color(0.86, 0.70, 0.34)      ## hay
var c_straw_dk := Color(0.62, 0.46, 0.20)   ## hay shadow, twine
var c_earth := Color(0.36, 0.27, 0.18)      ## paddock earth
var c_water := Color(0.16, 0.28, 0.36)
var c_leather := Color(0.30, 0.17, 0.10)
var c_roof_core := Color(0.25, 0.22, 0.2)   ## the gable triangles under the tiles
var roof_tile := Color(1, 1, 1, 0)         ## roof tiles: the team colour (alpha 0) or a plain colour (Nature thatch)
var window_color := Color(1.0, 0.68, 0.30)  ## warm windows (mat_gate)
var roof_rise: float = 1.75                 ## barn roof rise (Shadow: steeper)
var tower_rise: float = 1.35
var tile_courses: int = 4
var lower_h: float = 0.8                    ## stone lower course of the barn walls
var crack_on: float = 0.0                   ## glowing cracks in K_STONE parts (Fire lava; kept under the bloom level)
var hot_energy: float = 0.5                 ## self-lit K_HOT parts (under the bloom level)
var glow_energy: float = 4.0                ## kingdom glow points (lantern, top)
var window_energy: float = 4.5              ## warm windows
var mount_pos := Vector3(0.1, 0.0, -1.55)
var mount_yaw: float = -32.0
var mount_len: float = 1.0                  ## mount scale
var seed_base: int = 7100

var mat_body: ShaderMaterial
var _mount: Node3D
var _mount_head: Node3D
var _mount_tail: Node3D
var _bale_pivot: Node3D
var _gate_l: Node3D
var _gate_r: Node3D
var _swing_t: float = -1.0
var _head_toss: float = 0.0


# --- Palette / materials ------------------------------------------------------------------------------------------

func _make_materials() -> void:
	mat_body = ShaderMaterial.new()
	mat_body.shader = PAINT
	mat_body.set_shader_parameter(&"base_color", kingdom_color)
	mat_body.set_shader_parameter(&"noise_tex", NOISE)
	mat_body.set_shader_parameter(&"crack_strength", crack_on)
	mat_body.set_shader_parameter(&"crack_color", glow_color)
	mat_body.set_shader_parameter(&"crack_scale", 0.5)
	mat_body.set_shader_parameter(&"hot_energy", hot_energy)
	NeutralBuildingLook.set_detail(mat_body)   # G-B neutral paint layer tier (stables_painted.gdshader)
	mat_stone = mat_body
	mat_dark = mat_body
	mat_metal = mat_body
	mat_team = mat_body
	_painted.append(mat_body)
	mat_banner = ShaderMaterial.new()
	mat_banner.shader = BANNER
	mat_banner.set_shader_parameter(&"cloth_color", _cloth_of(kingdom_color))
	mat_banner.set_shader_parameter(&"stripe_color", stripe_color)
	mat_banner.set_shader_parameter(&"glyph_color", glyph_color)
	mat_banner.set_shader_parameter(&"glyph_shape", glyph_shape)
	mat_banner.set_shader_parameter(&"amplitude", 0.1)
	mat_banner.set_shader_parameter(&"speed", 2.2)
	mat_glow = _glow_mat(glow_energy, 2.0, 0)
	mat_gate = _glow_mat(window_energy, 1.1, 0)
	mat_gate.set_shader_parameter(&"glow_color", window_color)


## The two particle quads are shared by every Stables (one material each for the whole game).
func _make_particle_quads() -> void:
	if not _shared_quads.has("add"):
		_shared_quads["add"] = _quad(true)
		_shared_quads["mix"] = _quad(false)
	_add_quad = _shared_quads["add"]
	_mix_quad = _shared_quads["mix"]
	var g := Gradient.new()
	g.set_color(0, danger_ramp_hot)
	g.set_color(1, Color(danger_ramp_end, 0.0))
	g.add_point(0.4, danger_ramp_mid)
	g.add_point(0.8, Color(danger_ramp_end, 0.8))
	_fire_ramp = GradientTexture1D.new()
	_fire_ramp.gradient = g


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _light != null and is_instance_valid(_light) and not _light.is_inside_tree():
		_light.free()


# --- Hooks --------------------------------------------------------------------------------------------------------

## A rider walked out: the paddock gate swings open and shut, the windows flare (base pulse), the mount tosses its head.
func play_training_pulse() -> void:
	super()
	if _destroyed or not _ready_done or _progress < 1.0:
		return
	_swing_t = 0.0
	_head_toss = 1.0


## cavalry-mounts.md 13.V21: the Stables' "trained" beat (same as the training pulse).
func play_trained() -> void:
	play_training_pulse()


func set_construction_progress(p: float) -> void:
	super(p)
	if _progress < 1.0:
		_swing_t = -1.0
		_reset_gate()


func _apply_health() -> void:
	super()
	if _mount:
		_mount.visible = _progress >= 1.0 and _health_ratio >= 0.25 and not _destroyed
	if _bale_pivot:
		_bale_pivot.visible = _progress >= 1.0 and _health_ratio >= 0.5


func play_destroyed() -> void:
	super()
	_swing_t = -1.0
	if _ready_done:
		_reset_gate()


## Gate swing 0..1 (open amount now), for tests / tools.
func get_gate_open() -> float:
	if _gate_l == null:
		return 0.0
	return absf(_gate_l.rotation.y) / deg_to_rad(80.0)


# --- Idle motion --------------------------------------------------------------------------------------------------

func _idle_motion(delta: float) -> void:
	if _bale_pivot:
		_bale_pivot.rotation = Vector3(deg_to_rad(3.0) * sin(_t * 1.3), 0.0, deg_to_rad(4.0) * sin(_t * 0.9 + 0.7))
	if _mount_head:
		var graze: float = smoothstep(0.55, 0.95, 0.5 + 0.5 * sin(_t * 0.35))
		var toss: float = 0.0
		if _head_toss > 0.0:
			_head_toss = maxf(_head_toss - delta / 0.9, 0.0)
			toss = sin((1.0 - _head_toss) * PI) * 0.6
		_mount_head.rotation = Vector3(deg_to_rad(30.0) * graze - toss + deg_to_rad(2.0) * sin(_t * 2.1),
			deg_to_rad(6.0) * sin(_t * 0.5), 0.0)
	if _mount_tail:
		_mount_tail.rotation = Vector3(0.0, deg_to_rad(16.0) * sin(_t * 1.7) * (0.6 + 0.4 * sin(_t * 0.23)), 0.0)
	if _swing_t >= 0.0 and _gate_l:
		_swing_t += delta
		var k: float = clampf(_swing_t / SWING_TIME, 0.0, 1.0)
		var open: float = pow(sin(k * PI), 0.6)
		_gate_l.rotation.y = deg_to_rad(-80.0) * open
		_gate_r.rotation.y = deg_to_rad(80.0) * open
		if k >= 1.0:
			_swing_t = -1.0
			_reset_gate()


func _reset_gate() -> void:
	if _gate_l:
		_gate_l.rotation = Vector3.ZERO
		_gate_r.rotation = Vector3.ZERO


# --- The layout ---------------------------------------------------------------------------------------------------

func _build_structure() -> void:
	_top_y = 8.4
	_light = OmniLight3D.new()   # detached proxy: the base class writes its energy, never in the tree
	_light.name = "VirtualLight"
	_light.light_energy = light_energy
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_base
	_build_base(rng)
	_build_walls(rng)
	_build_roof(rng)
	var tower := _build_tower()
	_build_fence()
	var yard := _build_yard(rng)
	_build_mount(mount_pos, mount_yaw, _k_mount_prof())
	_build_scaffold(0.0, 1.55, 6.3, 3.3, 4.6)
	_build_stables_wreck(seed_base + 71)
	_falling = tower
	_fall_axis = Vector3.BACK
	_fall_deg = 38.0
	_hide_on_collapse.append(yard)
	var cz: float = ROOF_CZ
	_smoke_points = [_gx_point(cz, ROOF_HD, EAVE, roof_rise, -1.0, 0.5, 0.3, -0.1), Vector3(1.9, 4.3, 2.3)]
	_blaze_points = [_gx_point(cz, ROOF_HD, EAVE, roof_rise, 1.0, 0.45, 0.25, 1.8), Vector3(TX, 5.9, TZ - 0.4)]
	_rubble2_points = [Vector3(2.9, 0.9, 2.6), Vector3(2.5, 0.9, 3.0), Vector3(3.1, 0.5, 1.6), Vector3(-2.9, 0.5, -0.2)]
	_gate_pos = Vector3(0.0, 0.9, FZ - 0.2)


## Foundation (battered stone under barn + tower), the stall step, lumpy paddock earth + straw, the gate path.
func _build_base(rng: RandomNumberGenerator) -> void:
	var box: BoxMesh = _bx()
	var it: Array = []
	it.append(_frustum(Vector3(-0.1, 0.0, 1.62), 3.18, 1.55, PT, 0.1, c_found, K_STONE))
	it.append(_i(box, Vector3(-0.1, PT - 0.04, 1.62), c_stone.darkened(0.2), Vector3.ZERO, Vector3(6.1, 0.12, 2.86), K_STONE))
	for c: Vector2 in [Vector2(-3.05, 0.2), Vector2(2.95, 0.2), Vector2(-3.05, 3.05), Vector2(2.95, 3.05)]:
		it.append(_frustum(Vector3(c.x, 0.0, c.y), 0.34, 0.34, PT + 0.12, 0.08, c_found.darkened(0.2), K_STONE))
	for k: int in 3:
		var x: float = rng.randf_range(-2.6, 2.6)
		it.append(_i(box, Vector3(x, rng.randf_range(0.2, 0.5), 0.14), c_stone.darkened(0.1), Vector3(rng.randf_range(-6, 6), rng.randf_range(-8, 8), 0),
			Vector3(rng.randf_range(0.5, 0.9), rng.randf_range(0.22, 0.36), 0.12), K_STONE))
	# Stall step (two treads) along the barn front.
	it.append(_i(box, Vector3(0.65, 0.2, 0.0), c_stone.darkened(0.15), Vector3(0, 0, 0), Vector3(4.3, 0.4, 0.5), K_STONE))
	it.append(_i(box, Vector3(0.65, 0.55, 0.12), c_stone.darkened(0.05), Vector3.ZERO, Vector3(4.3, 0.3, 0.3), K_STONE))
	# Paddock: lumpy packed earth (tilted slabs + a trodden ring), straw, flags out of the gate.
	it.append(_i(_bumpy(Vector2(5.9, 3.3), 9, 5, 0.12, seed_base), Vector3(0.0, 0.03, -1.3), c_earth))
	_straw_scatter(it, rng, 3, Rect2(-2.6, -2.7, 5.2, 2.3))
	for k: int in 3:
		var p2 := Vector3(rng.randf_range(-0.3, 0.3), 0.04, FZ - 0.5 - 0.62 * k)
		it.append(_i(box, p2, c_found.lightened(0.12), Vector3(rng.randf_range(-4, 4), rng.randf_range(-15, 15), 0),
			Vector3(rng.randf_range(0.8, 1.0), 0.08, 0.5), K_STONE))
	_k_found_extra(it, rng)
	_vc("PlinthBase", "plinth", it)


## Barn walls: stone lower course, plank / wattle upper walls, dark frame + trims, the three stalls, the stall posts
## and the eave beam, the +X barn door, the back: a stall with a mount looking out, a hay rack, a warm window.
func _build_walls(rng: RandomNumberGenerator) -> void:
	var box: BoxMesh = _bx()
	var it: Array = []
	var cx: float = (BX0 + BX1) * 0.5
	var cz: float = (BZ0 + BZ1) * 0.5
	var lx: float = BX1 - BX0
	var lz: float = BZ1 - BZ0
	_k_walls(it, rng)
	# Frame: corner posts, sill and top plates, trims at the corners.
	for c: Vector2 in [Vector2(BX0, BZ0), Vector2(BX1, BZ0), Vector2(BX0, BZ1), Vector2(BX1, BZ1)]:
		it.append(_i(box, Vector3(c.x, (PT + EAVE) * 0.5, c.y), c_beam, Vector3.ZERO, Vector3(0.3, EAVE - PT, 0.3)))
	for z: float in [BZ0, BZ1]:
		it.append(_i(box, Vector3(cx, EAVE - 0.08, z), c_beam, Vector3.ZERO, Vector3(lx + 0.1, 0.2, 0.22)))
		it.append(_i(box, Vector3(cx, PT + lower_h, z), c_beam, Vector3.ZERO, Vector3(lx, 0.14, 0.2)))
	for x: float in [BX0, BX1]:
		it.append(_i(box, Vector3(x, EAVE - 0.08, cz), c_beam, Vector3.ZERO, Vector3(0.22, 0.2, lz + 0.1)))
	# Stalls (front), posts between them, porch posts (round) with knee braces under the roof's front eave.
	for x: float in STALLS:
		_stall(it, x, 1.22, BZ0, -1.0)
	for x: float in [-0.07, 1.23]:
		it.append(_i(box, Vector3(x, (PT + EAVE) * 0.5, BZ0 - 0.04), c_beam, Vector3.ZERO, Vector3(0.18, EAVE - PT, 0.16)))
	for x: float in [BX0 + 0.15, 0.58, BX1 - 0.15]:
		it.append(_i(_cyc(0.1, 0.12, 2.64, 8), Vector3(x, 1.86, -0.2), c_beam))
		it.append(_i(_cyc(0.16, 0.19, 0.14, 8), Vector3(x, 0.47, -0.2), c_found, Vector3.ZERO, Vector3.ONE, K_STONE))
		it.append(_ix(box, _seg(Vector3(x, 2.35, -0.2), Vector3(x, 2.9, 0.25), 0.12, 0.12), c_beam))
	it.append(_i(box, Vector3(0.65, 3.08, -0.2), c_beam, Vector3.ZERO, Vector3(4.45, 0.2, 0.2)))
	# +X gable end: double barn door with X braces and straps, a dark gap between the leaves, a lintel with a boss.
	var gx: float = BX1 + 0.02
	it.append(_i(box, Vector3(gx, 1.75, cz), c_beam, Vector3.ZERO, Vector3(0.12, 2.0, 1.95)))
	for s: float in [-1.0, 1.0]:
		var zc: float = cz + s * 0.45
		it.append(_i(box, Vector3(gx + 0.06, 1.7, zc), c_wood, Vector3.ZERO, Vector3(0.1, 1.75, 0.84)))
		it.append(_ix(box, _seg(Vector3(gx + 0.13, 0.95, zc - 0.36), Vector3(gx + 0.13, 2.45, zc + 0.36), 0.09, 0.05), c_beam))
		it.append(_ix(box, _seg(Vector3(gx + 0.13, 0.95, zc + 0.36), Vector3(gx + 0.13, 2.45, zc - 0.36), 0.09, 0.05), c_beam))
		for y: float in [2.3]:
			it.append(_i(box, Vector3(gx + 0.15, y, zc), c_trim, Vector3.ZERO, Vector3(0.04, 0.1, 0.8), K_METAL))
	it.append(_i(box, Vector3(gx + 0.12, 1.7, cz), Color.BLACK, Vector3.ZERO, Vector3(0.02, 1.7, 0.05), K_HOLE))
	it.append(_i(box, Vector3(gx + 0.1, 2.72, cz), c_beam, Vector3.ZERO, Vector3(0.18, 0.2, 2.1)))
	it.append(_i(_cyc(0.24, 0.24, 0.08, 10), Vector3(gx + 0.16, 2.72, cz), c_trim, Vector3(0, 0, 90), Vector3.ONE, K_METAL))
	# Back (+Z): a slanted hay rack full of hay, a warm window.
	var hr := Vector3(1.55, 1.55, BZ1 + 0.02)
	for k: int in 4:
		var x: float = hr.x - 0.54 + 0.36 * k
		it.append(_ix(box, _seg(Vector3(x, hr.y - 0.35, BZ1 + 0.06), Vector3(x, hr.y + 0.4, BZ1 + 0.42), 0.06, 0.06), c_beam))
	it.append(_i(box, Vector3(hr.x, hr.y - 0.37, BZ1 + 0.1), c_beam, Vector3.ZERO, Vector3(1.4, 0.1, 0.14)))
	it.append(_i(box, Vector3(hr.x, hr.y + 0.4, BZ1 + 0.42), c_beam, Vector3.ZERO, Vector3(1.4, 0.1, 0.1)))
	it.append(_i(_sp(8, 4), Vector3(hr.x, hr.y + 0.2, BZ1 + 0.24), c_straw, Vector3(-30, 0, 0), Vector3(1.25, 0.55, 0.35)))
	it.append(_i(box, Vector3(1.4, 2.5, BZ1 + 0.03), c_beam, Vector3.ZERO, Vector3(0.8, 0.62, 0.1)))
	it.append(_i(box, Vector3(1.4, 2.5, BZ1 + 0.07), Color.WHITE, Vector3.ZERO, Vector3(0.56, 0.42, 0.04), K_PLAIN, mat_gate))
	it.append(_i(box, Vector3(1.4, 2.5, BZ1 + 0.1), c_beam, Vector3.ZERO, Vector3(0.05, 0.42, 0.04)))
	# A mount looking out of the middle front stall.
	_k_head(it, Transform3D(Basis(Vector3.UP, deg_to_rad(8.0)).scaled(Vector3.ONE * 0.9), Vector3(STALLS[1], 1.95, BZ0 + 0.05)))
	_k_wall_extra(it, rng)
	_vc("Walls", "walls", it)


## Default wall skin: stone lower course (K_STONE), plank upper walls with seams.
func _k_walls(it: Array, rng: RandomNumberGenerator) -> void:
	var box: BoxMesh = _bx()
	var cx: float = (BX0 + BX1) * 0.5
	var cz: float = (BZ0 + BZ1) * 0.5
	var lx: float = BX1 - BX0
	var lz: float = BZ1 - BZ0
	it.append(_i(box, Vector3(cx, PT + lower_h * 0.5, cz), c_stone, Vector3.ZERO, Vector3(lx, lower_h, lz), K_STONE))
	var up0: float = PT + lower_h
	it.append(_i(box, Vector3(cx, (up0 + EAVE) * 0.5, cz), c_wall, Vector3.ZERO, Vector3(lx - 0.08, EAVE - up0, lz - 0.08)))
	# Stones proud of the lower course.
	for k: int in 5:
		var along: float = rng.randf_range(BX0 + 0.3, BX1 - 0.3)
		var z2: float = BZ1 + 0.04 if k % 2 == 0 else BZ0 - 0.04
		it.append(_i(box, Vector3(along, PT + rng.randf_range(0.15, lower_h - 0.15), z2), c_stone.lightened(rng.randf_range(0.0, 0.12)),
			Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-6, 6)), Vector3(rng.randf_range(0.35, 0.6), rng.randf_range(0.18, 0.28), 0.1), K_STONE))


## Barn roof: bell-cast team tiles, ridge, bargeboards, the kingdom crest, the +X gable window, the cupola + vane;
## the damage patches.
func _build_roof(_rng: RandomNumberGenerator) -> void:
	var box: BoxMesh = _bx()
	var it: Array = []
	var cz: float = ROOF_CZ
	var hd: float = ROOF_HD
	var x0: float = BX0 - 0.05
	var x1: float = BX1 + 0.42
	_gable_x(it, x0, x1, cz, hd, EAVE, roof_rise, tile_courses, c_roof_core, roof_tile, c_trim)
	# Gable window (+X), dark frame + warm glass + mullion + sill.
	var gw := Vector3(x1 - 0.22, EAVE + roof_rise * 0.36, cz)
	it.append(_i(box, gw, c_beam, Vector3.ZERO, Vector3(0.1, 0.7, 0.8)))
	it.append(_i(box, gw + Vector3(0.04, 0, 0), Color.WHITE, Vector3.ZERO, Vector3(0.06, 0.5, 0.56), K_PLAIN, mat_gate))
	it.append(_i(box, gw + Vector3(0.08, 0, 0), c_beam, Vector3.ZERO, Vector3(0.04, 0.5, 0.06)))
	it.append(_i(box, gw + Vector3(0.1, -0.38, 0), c_trim, Vector3.ZERO, Vector3(0.14, 0.07, 0.9), K_METAL))
	# Cupola on the ridge: plank box with dark louvres, a team pyramid cap, trim band, rod, arrow + the kingdom vane.
	var cu := Vector3(1.05, EAVE + roof_rise + 0.18, cz)
	it.append(_i(box, cu + Vector3(0, 0.3, 0), c_wall, Vector3.ZERO, Vector3(0.8, 0.72, 0.75)))
	for s: float in [-1.0, 1.0]:
		for k: int in 2:
			it.append(_i(box, cu + Vector3(-0.13 + 0.26 * k, 0.34, s * 0.39), Color.BLACK, Vector3.ZERO, Vector3(0.12, 0.45, 0.02), K_HOLE))
		it.append(_i(box, cu + Vector3(s * 0.41, 0.34, 0), Color.BLACK, Vector3.ZERO, Vector3(0.02, 0.45, 0.4), K_HOLE))
	it.append(_i(_cyc(0.0, 0.66, 0.55, 4), cu + Vector3(0, 0.95, 0), T(0.95), Vector3(0, 45, 0)))
	it.append(_i(_cyc(0.7, 0.7, 0.08, 4), cu + Vector3(0, 0.68, 0), c_trim, Vector3(0, 45, 0), Vector3.ONE, K_METAL))
	it.append(_i(_cy(0.03, 0.03, 0.75, 4), cu + Vector3(0, 1.5, 0), c_trim, Vector3.ZERO, Vector3.ONE, K_METAL))
	it.append(_i(box, cu + Vector3(0, 1.62, 0), c_trim, Vector3(0, 30, 0), Vector3(0.05, 0.05, 0.7), K_METAL))
	it.append(_i(_cyc(0.0, 0.07, 0.14, 4), cu + Vector3(0, 1.62, 0) + Basis(Vector3.UP, deg_to_rad(30.0)) * Vector3(0, 0, -0.38), c_trim,
		Vector3(-90, 30, 0), Vector3.ONE, K_METAL))
	_k_vane(it, cu + Vector3(0, 1.84, 0))
	_k_roof_extra(it, cz, hd, x0, x1)
	var roof := _vc("Roof", "roof", it)
	_hide_on_collapse.append(roof)
	_show_below_50.append(_roof_patch("RoofHoleL", roof, _gx_point(cz, hd, EAVE, roof_rise, -1.0, 0.45, 0.0, -0.1),
		-1.0, roof_rise, hd, 1.1, false))
	_show_below_25.append(_roof_patch("RoofHoleR", roof, _gx_point(cz, hd, EAVE, roof_rise, 1.0, 0.4, 0.0, 1.8),
		1.0, roof_rise, hd, 1.1, true))


## Loft tower (one group: it rises, then topples on the collapse): a ROUND tower (the kingdom skin: stone ground
## storey, loft storey, bands), a dormer toward the paddock with the open loft door spilling hay, the hoist beam +
## pulley + hanging bale out of the dormer gable, a side door and a warm window (-X), a warm window at the back (+Z),
## the bell-cast conical team roof, the kingdom's top, a team banner on the -X face.
func _build_tower() -> Node3D:
	var box: BoxMesh = _bx()
	var tower := Node3D.new()
	tower.name = "LoftTower"
	tower.position = Vector3(TX, PT, TZ)
	_body.add_child(tower)
	var it: Array = []
	var h: float = T_EAVE - PT
	_k_tower_skin(it, h)
	# Dormer (-Z): plank cheeks on a beam frame, the loft door (dark opening, open leaves, hay over the sill), a small
	# team gable roof.
	var dz0: float = -TR - 0.3
	var dz1: float = -0.4
	var dy0: float = 2.75
	var dy1: float = 4.3
	it.append(_i(box, Vector3(0, (dy0 + dy1) * 0.5, (dz0 + dz1) * 0.5), c_wall, Vector3.ZERO, Vector3(1.3, dy1 - dy0, dz1 - dz0)))
	for s: float in [-1.0, 1.0]:
		it.append(_i(box, Vector3(s * 0.62, (dy0 + dy1) * 0.5, dz0 + 0.05), c_beam, Vector3.ZERO, Vector3(0.16, dy1 - dy0 + 0.1, 0.16)))
	it.append(_i(box, Vector3(0, dy0 - 0.02, (dz0 + dz1) * 0.5), c_beam, Vector3.ZERO, Vector3(1.4, 0.16, dz1 - dz0 + 0.1)))
	it.append(_i(box, Vector3(0, 3.5, dz0 - 0.02), Color.BLACK, Vector3.ZERO, Vector3(0.9, 1.15, 0.06), K_HOLE))
	it.append(_i(box, Vector3(0, 2.92, dz0 - 0.08), c_beam, Vector3.ZERO, Vector3(1.1, 0.14, 0.2)))
	for s: float in [-1.0, 1.0]:
		it.append(_i(box, Vector3(s * 0.78, 3.5, dz0 - 0.26), c_wood, Vector3(0, s * 62.0, 0), Vector3(0.48, 1.1, 0.07)))
		it.append(_i(box, Vector3(s * 0.78, 3.5, dz0 - 0.31), c_beam, Vector3(0, s * 62.0, 35.0 * s), Vector3(0.06, 1.15, 0.05)))
	it.append(_i(_sp(8, 4), Vector3(0, 3.05, dz0 - 0.08), c_straw, Vector3(0, 10, 0), Vector3(0.85, 0.34, 0.42)))
	it.append(_i(box, Vector3(0.1, 2.85, dz0 - 0.28), c_straw.lightened(0.08), Vector3(20, 10, 0), Vector3(0.6, 0.06, 0.25)))
	it.append(_i(box, Vector3(-0.2, 2.75, dz0 - 0.33), c_straw_dk, Vector3(35, -20, 0), Vector3(0.45, 0.05, 0.2)))
	_gable_z(it, dz0 - 0.2, dz1, 0.0, 0.8, dy1, 0.62, 2, c_roof_core, roof_tile, c_trim)
	# Side door + warm window on the -X side, a warm window at the back (+Z).
	var wx: float = -TR - 0.02
	it.append(_i(box, Vector3(wx + 0.04, 0.95, 0.0), c_beam, Vector3.ZERO, Vector3(0.12, 1.75, 0.95)))
	it.append(_i(box, Vector3(wx - 0.02, 0.9, 0.0), c_wood, Vector3.ZERO, Vector3(0.06, 1.6, 0.75)))
	it.append(_i(box, Vector3(wx - 0.05, 0.9, 0.0), c_trim, Vector3.ZERO, Vector3(0.03, 0.1, 0.7), K_METAL))
	_window(it, Vector3(wx + 0.06, 3.1, 0.35), Vector3.LEFT)
	_window(it, Vector3(-0.2, 3.1, TR - 0.02), Vector3.BACK, false)
	# Conical bell-cast team roof.
	_cone_roof(it, Vector3(0, h, 0), TR + 0.5, tower_rise + 0.5, 3)
	# Hoist beam out of the dormer gable, knee brace, pulley, hook.
	var by: float = dy1 + 0.35
	it.append(_ix(box, _seg(Vector3(0, by, dz1), Vector3(0, by, dz0 - 1.5), 0.2, 0.22), c_beam))
	it.append(_ix(box, _seg(Vector3(0, by - 0.9, dz0 - 0.02), Vector3(0, by - 0.05, dz0 - 0.75), 0.12, 0.12), c_beam))
	it.append(_i(_cyc(0.17, 0.17, 0.1, 10), Vector3(0, by - 0.2, dz0 - 1.3), c_trim, Vector3(0, 0, 90), Vector3.ONE, K_METAL))
	it.append(_i(box, Vector3(0, by - 0.05, dz0 - 1.3), c_trim, Vector3.ZERO, Vector3(0.05, 0.3, 0.05), K_METAL))
	it.append(_i(box, Vector3(0, by + 0.02, dz0 - 1.5), c_trim, Vector3.ZERO, Vector3(0.26, 0.28, 0.08), K_METAL))
	_k_tower_top(it, tower, h)
	_vc("TowerStack", "tower", it, tower)
	# Hanging bale (sways; gone below 50 % HP).
	_bale_pivot = Node3D.new()
	_bale_pivot.name = "BalePivot"
	_bale_pivot.position = Vector3(0, by - 0.25, dz0 - 1.3)
	tower.add_child(_bale_pivot)
	it = []
	it.append(_i(box, Vector3(0, -0.55, 0), c_straw_dk, Vector3.ZERO, Vector3(0.03, 1.1, 0.03)))
	for s: float in [-1.0, 1.0]:
		it.append(_ix(box, _seg(Vector3(0, -1.08, 0), Vector3(s * 0.32, -1.32, 0), 0.03, 0.03), c_straw_dk))
	_bale(it, Vector3(0, -1.6, 0), Vector3(0.8, 0.48, 0.5), 0.0)
	_vc("HangingBale", "hanging_bale", it, _bale_pivot)
	var ban := _banner("TowerBanner", Vector2(0.75, 1.5), Vector3(-TR - 0.14, h - 1.05, -0.55), -90.0, tower)
	_hide_below_25.append(ban)
	_hide_on_collapse.append(ban)
	return tower


## Default round tower skin: stone ground storey, plank loft storey with posts, trim bands.
func _k_tower_skin(it: Array, h: float) -> void:
	var box: BoxMesh = _bx()
	it.append(_i(_cy(TR - 0.05, TR + 0.04, 2.0, TSEG), Vector3(0, 1.0, 0), c_stone, Vector3(0, 18, 0), Vector3.ONE, K_STONE))
	it.append(_i(_cy(TR - 0.1, TR - 0.06, h - 2.0, TSEG), Vector3(0, (2.0 + h) * 0.5, 0), c_wall, Vector3(0, 18, 0)))
	for y: float in [2.0, h - 0.08]:
		it.append(_i(_cy(TR + 0.03, TR + 0.03, 0.16, TSEG), Vector3(0, y, 0), c_trim, Vector3(0, 18, 0), Vector3.ONE, K_METAL))
	for k: int in 6:
		var a: float = TAU * (k + 0.5) / 6.0 + 0.3
		var d := Vector3(cos(a), 0, sin(a))
		it.append(_ix(box, Transform3D(Basis(Vector3.UP, -a).scaled_local(Vector3(0.12, h - 2.2, 0.2)),
			d * (TR - 0.06) + Vector3(0, (2.1 + h) * 0.5, 0)), c_beam))


## Bell-cast conical roof: `courses` stepped cone rings in the team colour (the eave ring flattest), a dark drip edge
## under each ring, a trim collar and a cap; `c` = centre of the eave, r0 = eave radius.
func _cone_roof(it: Array, c: Vector3, r0: float, rise: float, courses: int) -> void:
	var y: float = c.y
	var r: float = r0
	var step_h: float = rise / (courses + 0.6)
	for k: int in courses:
		var hk: float = step_h * (0.75 + 0.2 * k)
		var r_top: float = r0 * (1.0 - float(k + 1) / (courses + 0.35))
		var shade: float = 0.84 + 0.16 * float(k) / maxf(courses - 1, 1)
		it.append(_i(_cy(r_top + 0.08, r, hk, TSEG), Vector3(c.x, y + hk * 0.5, c.z), _shade(roof_tile, shade), Vector3(0, 18, 0)))
		it.append(_i(_cy(r + 0.02, r + 0.03, 0.08, TSEG), Vector3(c.x, y + 0.02, c.z), _shade(roof_tile, shade * 0.7), Vector3(0, 18, 0)))
		y += hk * 0.92
		r = r_top + 0.1
	var cap_h: float = rise - (y - c.y) + 0.1
	it.append(_i(_cy(0.0, r, cap_h, TSEG), Vector3(c.x, y + cap_h * 0.5, c.z), roof_tile, Vector3(0, 18, 0)))
	it.append(_i(_cy(r * 0.45, r * 0.5, 0.14, TSEG), Vector3(c.x, y + 0.02, c.z), c_trim, Vector3(0, 18, 0), Vector3.ONE, K_METAL))


## A framed warm window (mat_gate) on a wall facing `out` (LEFT / RIGHT / BACK / FORWARD).
func _window(it: Array, p: Vector3, out: Vector3, lit: bool = true) -> void:
	var box: BoxMesh = _bx()
	var along_x: bool = absf(out.z) > 0.5
	var fr := Vector3(0.8, 0.8, 0.1) if along_x else Vector3(0.1, 0.8, 0.7)
	var gl := Vector3(0.52, 0.56, 0.04) if along_x else Vector3(0.04, 0.56, 0.46)
	it.append(_i(box, p, c_beam, Vector3.ZERO, fr))
	if lit:
		it.append(_i(box, p + out * 0.04, Color.WHITE, Vector3.ZERO, gl, K_PLAIN, mat_gate))
	else:   # closed shutters
		it.append(_i(box, p + out * 0.04, c_wood, Vector3.ZERO, gl))
	it.append(_i(box, p + out * 0.07, c_beam, Vector3.ZERO, Vector3(0.05, 0.56, 0.03) if along_x else Vector3(0.03, 0.56, 0.05)))
	it.append(_i(box, p + out * 0.08 + Vector3(0, -0.44, 0), c_trim, Vector3.ZERO,
		Vector3(0.9, 0.07, 0.14) if along_x else Vector3(0.14, 0.07, 0.8), K_METAL))


## Paddock props: stacked hay bales and a loose heap, the water trough, a hitching rail, the saddle rack with a team
## cloth, the gate's lantern post and banner pole, then the kingdom's props.
func _build_yard(rng: RandomNumberGenerator) -> MeshInstance3D:
	var box: BoxMesh = _bx()
	var it: Array = []
	_bale(it, Vector3(-2.25, 0.25, -0.85), Vector3(0.95, 0.5, 0.58), 8.0)
	_bale(it, Vector3(-2.2, 0.25, -1.5), Vector3(0.95, 0.5, 0.58), -4.0)
	_bale(it, Vector3(-2.22, 0.75, -1.18), Vector3(0.95, 0.5, 0.58), 84.0)
	_hay_heap(it, Vector3(1.25, 0.02, -2.35), 0.36, rng)
	# Water trough along the +X fence (hollowed: rim boards around the water), bands.
	var tp := Vector3(2.3, 0.0, -1.85)
	it.append(_i(box, tp + Vector3(0, 0.2, 0), c_wood.darkened(0.2), Vector3.ZERO, Vector3(0.62, 0.36, 1.45)))
	for s: float in [-1.0, 1.0]:
		it.append(_i(box, tp + Vector3(s * 0.27, 0.45, 0), c_wood.darkened(0.1), Vector3(0, 0, s * -8.0), Vector3(0.09, 0.16, 1.45)))
		it.append(_i(box, tp + Vector3(0, 0.45, s * 0.68), c_wood.darkened(0.1), Vector3.ZERO, Vector3(0.62, 0.16, 0.09)))
	it.append(_i(box, tp + Vector3(0, 0.46, 0), c_water, Vector3.ZERO, Vector3(0.46, 0.03, 1.28)))
	# Hitching rail near the stalls (round posts, ring).
	for x: float in [-1.35, -0.35]:
		it.append(_i(_cyc(0.08, 0.1, 1.1, 8), Vector3(x, 0.55, -0.72), c_beam))
	it.append(_i(_cyc(0.06, 0.06, 1.25, 8), Vector3(-0.85, 0.98, -0.72), c_wood, Vector3(0, 0, 90)))
	it.append(_i(_torus(0.04, 0.1), Vector3(-0.85, 0.86, -0.78), c_trim, Vector3(90, 0, 0), Vector3.ONE, K_METAL))
	# Saddle rack with a spare team saddle cloth and a saddle.
	var sr := Vector3(1.9, 0.0, -0.72)
	for s: float in [-1.0, 1.0]:
		it.append(_ix(box, _seg(sr + Vector3(s * 0.4, 0, -0.18), sr + Vector3(s * 0.32, 0.85, 0), 0.08, 0.08), c_beam))
		it.append(_ix(box, _seg(sr + Vector3(s * 0.4, 0, 0.18), sr + Vector3(s * 0.32, 0.85, 0), 0.08, 0.08), c_beam))
	it.append(_i(box, sr + Vector3(0, 0.88, 0), c_wood, Vector3.ZERO, Vector3(0.9, 0.1, 0.1)))
	it.append(_i(_pr(), sr + Vector3(0, 0.8, 0), T(1.0), Vector3(0, 90, 0), Vector3(0.66, 0.34, 0.78)))
	it.append(_i(_pr(), sr + Vector3(0, 0.63, 0), T(0.6), Vector3(0, 90, 0), Vector3(0.7, 0.05, 0.8)))
	it.append(_i(_sp(10, 5), sr + Vector3(0, 1.0, 0), c_leather, Vector3.ZERO, Vector3(0.62, 0.24, 0.42)))
	it.append(_i(_cyc(0.06, 0.06, 0.12, 6), sr + Vector3(0.28, 1.08, 0), c_leather.lightened(0.1)))
	# Gate: lantern post (right), banner pole (left).
	var lp := Vector3(GATE_HALF + 0.2, 0.0, FZ - 0.05)
	it.append(_i(_cyc(0.1, 0.12, 2.2, 8), lp + Vector3(0, 1.1, 0), c_beam))
	it.append(_i(box, lp + Vector3(-0.2, 2.1, 0), c_beam, Vector3.ZERO, Vector3(0.55, 0.12, 0.12)))
	it.append(_ix(box, _seg(lp + Vector3(0, 1.7, 0), lp + Vector3(-0.3, 2.08, 0), 0.08, 0.08), c_beam))
	_lantern(it, lp + Vector3(-0.38, 2.04, 0), mat_glow, _k_lantern_cage())
	var gate_banner := _banner_pole(it, Vector3(-GATE_HALF - 0.2, 0.0, FZ - 0.05), 3.1, Vector2(0.7, 1.3))
	_hide_on_collapse.append(gate_banner)
	_k_yard_extra(it, rng)
	return _vc("Yard", "yard", it)


# --- Kingdom hooks (overridden per kingdom) -----------------------------------------------------------------------

func _k_found_extra(_it: Array, _rng: RandomNumberGenerator) -> void:
	pass


func _k_wall_extra(_it: Array, _rng: RandomNumberGenerator) -> void:
	pass


func _k_roof_extra(_it: Array, _cz: float, _hd: float, _x0: float, _x1: float) -> void:
	pass


func _k_vane(it: Array, p: Vector3) -> void:
	it.append(_i(_bx(), p, c_trim, Vector3.ZERO, Vector3(0.04, 0.26, 0.5), K_METAL))


func _k_tower_top(_it: Array, _tower: Node3D, _h: float) -> void:
	pass


func _k_yard_extra(_it: Array, _rng: RandomNumberGenerator) -> void:
	pass


func _k_lantern_cage() -> Color:
	return c_beam


## Mount proportions: {len, height, girth, coat, dark, hoof, leg_r, neck_h, neck_f, neck_r}.
func _k_mount_prof() -> Dictionary:
	return {"coat": c_wood, "dark": c_beam}


func _k_mount_extra(_body: Array, _tail: Array, _bh: float, _L: float, _G: float) -> void:
	pass


## The mount's head in pivot space (the neck top at the origin, the muzzle toward -Z), transformed by `xf`.
func _k_head(it: Array, xf: Transform3D) -> void:
	it.append(_ix(_sp(8, 4), xf * Transform3D(Basis.from_scale(Vector3(0.3, 0.3, 0.6)), Vector3(0, 0, -0.25)), c_wood))


func _k_post(it: Array, p: Vector3) -> void:
	it.append(_i(_cyc(0.1, 0.11, 1.1, 6), p + Vector3(0, 0.55, 0), c_beam))
	it.append(_i(_cyc(0.0, 0.14, 0.16, 4), p + Vector3(0, 1.18, 0), c_trim, Vector3(0, 45, 0), Vector3.ONE, K_METAL))


func _k_rail(it: Array, a: Vector3, b: Vector3) -> void:
	it.append(_ix(_bx(), _seg(a, b, 0.12, 0.13), c_wood))


# --- Vertex-colour merge --------------------------------------------------------------------------------------------

## Item: `mesh` at `pos` (rotation degrees YXZ, scale), colour `col` (alpha 0 = team x rgb), part class `kind`,
## material (default: the body material).
func _i(mesh: Mesh, pos: Vector3, col: Color, rot_deg: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE,
		kind: int = K_PLAIN, mat: Material = null) -> Array:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
	return [mesh, Transform3D(b.scaled_local(scale), pos), mat if mat else mat_body, col, kind]


func _ix(mesh: Mesh, xf: Transform3D, col: Color, kind: int = K_PLAIN, mat: Material = null) -> Array:
	return [mesh, xf, mat if mat else mat_body, col, kind]


## Team colour part (x `mult`: 1 = the team colour, < 1 darker hem / shade).
static func T(mult: float = 1.0) -> Color:
	return Color(mult, mult, mult, 0.0)


## A battered block (truncated pyramid): bottom centre `base`, half sizes hx / hz at the bottom, height h, the top
## pulled in by `taper` (fraction). World-axis scaled, so the faces lean in.
func _frustum(base: Vector3, hx: float, hz: float, h: float, taper: float, col: Color, kind: int = K_PLAIN) -> Array:
	var b := Basis(Vector3.UP, PI * 0.25).scaled(Vector3(hx * sqrt(2.0), h, hz * sqrt(2.0)))
	return _ix(_cy(1.0 - taper, 1.0, 1.0, 4), Transform3D(b, base + Vector3(0, h * 0.5, 0)), col, kind)


## One merged mesh for `items` (baked once per script + key, shared), surface materials per instance.
func _vc(nm: String, key: String, items: Array, parent: Node3D = null, shadow: bool = true) -> MeshInstance3D:
	var ck: String = "%s/%s" % [get_script().resource_path, key]
	var mats: Array[Material] = []
	for it: Array in items:
		if not mats.has(it[2]):
			mats.append(it[2])
	var am: ArrayMesh = _vc_cache.get(ck)
	if am == null:
		am = _vc_bake(items, mats)
		_vc_cache[ck] = am
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = am
	for i: int in mats.size():
		mi.set_surface_override_material(i, mats[i])
	var p: Node3D = parent if parent else _body
	p.add_child(mi)
	var only_glow: bool = true
	for m: Material in mats:
		if m == mat_body or m == mat_banner:
			only_glow = false
	if not shadow or only_glow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var xf := Transform3D.IDENTITY
	var n: Node = p
	while n != null and n != self and n != _body:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	var bottom: float = (xf * mi.get_aabb()).position.y
	if parent == null:
		bottom = minf(bottom, 0.0)   # Body tiers share one building-wide gradient (art-keep 0.3)
	mi.set_instance_shader_parameter(&"ao_bottom", bottom)
	mi.set_instance_shader_parameter(&"ao_height", maxf(_top_y - bottom, 1.5))
	return mi


static func _vc_bake(items: Array, mats: Array[Material]) -> ArrayMesh:
	var am := ArrayMesh.new()
	for m: Material in mats:
		var V := PackedVector3Array()
		var N := PackedVector3Array()
		var C := PackedColorArray()
		var U := PackedVector2Array()
		var U2 := PackedVector2Array()
		var I := PackedInt32Array()
		for it: Array in items:
			if it[2] != m:
				continue
			var mesh: Mesh = it[0]
			var xf: Transform3D = it[1]
			var col: Color = it[3]
			var k2 := Vector2(float(it[4]), 0.0)
			var nb: Basis = xf.basis.inverse().transposed()
			var flip: bool = xf.basis.determinant() < 0.0
			for s: int in mesh.get_surface_count():
				var a: Array = mesh.surface_get_arrays(s)
				var sv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
				var sn: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
				var su: Variant = a[Mesh.ARRAY_TEX_UV]
				var si: Variant = a[Mesh.ARRAY_INDEX]
				var sc: Variant = a[Mesh.ARRAY_COLOR]
				var has_c: bool = sc is PackedColorArray and (sc as PackedColorArray).size() == sv.size()
				var base: int = V.size()
				var has_uv: bool = su is PackedVector2Array and (su as PackedVector2Array).size() == sv.size()
				for k: int in sv.size():
					V.append(xf * sv[k])
					N.append((nb * sn[k]).normalized())
					C.append(col * (sc as PackedColorArray)[k] if has_c else col)
					U.append((su as PackedVector2Array)[k] if has_uv else Vector2.ZERO)
					U2.append(k2)
				if si is PackedInt32Array and (si as PackedInt32Array).size() > 0:
					var idx: PackedInt32Array = si
					for t: int in range(0, idx.size(), 3):
						if flip:
							I.append(base + idx[t])
							I.append(base + idx[t + 2])
							I.append(base + idx[t + 1])
						else:
							I.append(base + idx[t])
							I.append(base + idx[t + 1])
							I.append(base + idx[t + 2])
				else:
					for t: int in sv.size():
						I.append(base + t)
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V
		arr[Mesh.ARRAY_NORMAL] = N
		arr[Mesh.ARRAY_COLOR] = C
		arr[Mesh.ARRAY_TEX_UV] = U
		arr[Mesh.ARRAY_TEX_UV2] = U2
		arr[Mesh.ARRAY_INDEX] = I
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


# --- Cached primitives ----------------------------------------------------------------------------------------------

static func _bx() -> BoxMesh:
	if not _prim_cache.has("box"):
		var b := BoxMesh.new()
		b.size = Vector3.ONE
		_prim_cache["box"] = b
	return _prim_cache["box"]


## Open cylinder (no bottom cap: never seen from the camera).
static func _cy(top: float, bot: float, h: float, seg: int) -> CylinderMesh:
	var key: String = "c%.3f_%.3f_%.3f_%d" % [top, bot, h, seg]
	if not _prim_cache.has(key):
		var c := CylinderMesh.new()
		c.top_radius = top
		c.bottom_radius = bot
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		c.cap_bottom = false
		_prim_cache[key] = c
	return _prim_cache[key]


## Closed cylinder.
static func _cyc(top: float, bot: float, h: float, seg: int) -> CylinderMesh:
	var key: String = "cc%.3f_%.3f_%.3f_%d" % [top, bot, h, seg]
	if not _prim_cache.has(key):
		var c := CylinderMesh.new()
		c.top_radius = top
		c.bottom_radius = bot
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		_prim_cache[key] = c
	return _prim_cache[key]


static func _pr(apex: float = 0.5) -> PrismMesh:
	var key: String = "p%.2f" % apex
	if not _prim_cache.has(key):
		var p := PrismMesh.new()
		p.size = Vector3.ONE
		p.left_to_right = apex
		_prim_cache[key] = p
	return _prim_cache[key]


static func _sp(seg: int = 10, rings: int = 5) -> SphereMesh:
	var key: String = "s%d_%d" % [seg, rings]
	if not _prim_cache.has(key):
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = seg
		s.rings = rings
		_prim_cache[key] = s
	return _prim_cache[key]


static func _torus(inner: float, outer: float) -> TorusMesh:
	var key: String = "t%.3f_%.3f" % [inner, outer]
	if not _prim_cache.has(key):
		var t := TorusMesh.new()
		t.inner_radius = inner
		t.outer_radius = outer
		t.rings = 10
		t.ring_segments = 5
		_prim_cache[key] = t
	return _prim_cache[key]


## Transform of a box from `a` to `b` (local Z along the segment), `w` wide (local X) and `t` thick (local Y).
static func _seg(a: Vector3, b: Vector3, w: float, t: float) -> Transform3D:
	var z: Vector3 = b - a
	var ln: float = z.length()
	z = z / maxf(ln, 0.0001)
	var x: Vector3 = Vector3.RIGHT if absf(z.x) < 0.9 else Vector3.UP
	var y: Vector3 = z.cross(x).normalized()
	x = y.cross(z).normalized()
	return Transform3D(Basis(x, y, z).scaled_local(Vector3(w, t, ln)), (a + b) * 0.5)


## A cylinder from `a` to `b` (radius r0 at a, r1 at b).
func _rod(a: Vector3, b: Vector3, r0: float, r1: float, seg: int, col: Color, kind: int = K_PLAIN) -> Array:
	var d: Vector3 = b - a
	var ln: float = d.length()
	var up: Vector3 = d / maxf(ln, 0.0001)
	var bas := Basis(Quaternion(Vector3.UP, up))
	return _ix(_cy(r1, r0, ln, seg), Transform3D(bas, (a + b) * 0.5), col, kind)


# --- Shared pieces ------------------------------------------------------------------------------------------------

## Bell-cast gable roof along X (ridge at z = cz): a core prism in `core` (its triangles are the gables), `courses`
## tile rows per slope (the eave course flattest, so the roof flares out; each course split in jittered runs), a
## ridge cap and bargeboards in `trim`. x0 / x1 = roof ends, hd = half depth at the eave, eave_y, rise.
func _gable_x(it: Array, x0: float, x1: float, cz: float, hd: float, eave_y: float, rise: float, courses: int,
		core: Color, tile: Color, trim: Color) -> void:
	var box: BoxMesh = _bx()
	var ln: float = x1 - x0
	var cx: float = (x0 + x1) * 0.5
	var slope_l: float = sqrt(hd * hd + rise * rise)
	var a: float = atan2(rise, hd)
	var hc: float = hd - 0.3
	var ch: float = hc * tan(a) - 0.06
	it.append(_i(_pr(), Vector3(cx, eave_y + 0.06 + ch * 0.5, cz), core, Vector3(0, 90, 0), Vector3(hc * 2.0, ch, ln - 0.5)))
	var w: float = slope_l / courses + 0.14
	var runs: int = maxi(1, roundi(ln / 2.2))
	var rl: float = ln / runs
	for s: float in [-1.0, 1.0]:
		var e := Vector3(cx, eave_y, cz + s * hd)
		var u := Vector3(0.0, sin(a), -s * cos(a))
		var nrm := Vector3(0.0, cos(a), s * sin(a))
		for k: int in courses:
			var p: Vector3 = e + u * ((k + 0.5) * slope_l / courses) + nrm * 0.1
			var flare: float = deg_to_rad(15.0 - 11.0 * float(k) / maxf(courses - 1, 1))
			for r: int in runs:
				var j: float = sin(float(k * 7 + r * 3) * 1.7)
				var shade: float = (0.84 + 0.16 * float(k) / maxf(courses - 1, 1)) * (0.96 + 0.04 * j)
				var tcol: Color = T(tile.r * shade) if tile.a < 0.5 else Color(tile.r * shade, tile.g * shade, tile.b * shade)
				var px: float = x0 + rl * (r + 0.5)
				var bb: Basis = Basis(Vector3.RIGHT, s * (a - flare)) * Basis(Vector3.UP, deg_to_rad(1.8 * j))
				it.append(_ix(box, Transform3D(bb.scaled_local(Vector3(rl + 0.04, 0.16, w)), Vector3(px, p.y, p.z)), tcol))
		for x: float in [x0 - 0.04, x1 + 0.04]:
			var p2: Vector3 = e + u * (slope_l * 0.5) + nrm * 0.2
			it.append(_ix(box, Transform3D(Basis(Vector3.RIGHT, s * a).scaled_local(Vector3(0.18, 0.26, slope_l + 0.25)),
				Vector3(x, p2.y, p2.z)), trim))
	it.append(_i(_pr(), Vector3(cx, eave_y + rise + 0.1, cz), trim, Vector3(0, 90, 0), Vector3(0.62, 0.34, ln + 0.1)))


## Bell-cast gable roof along Z (ridge at x = cx), same recipe (tower roof).
func _gable_z(it: Array, z0: float, z1: float, cx: float, hd: float, eave_y: float, rise: float, courses: int,
		core: Color, tile: Color, trim: Color) -> void:
	var box: BoxMesh = _bx()
	var ln: float = z1 - z0
	var cz: float = (z0 + z1) * 0.5
	var slope_l: float = sqrt(hd * hd + rise * rise)
	var a: float = atan2(rise, hd)
	var hc: float = hd - 0.25
	var ch: float = hc * tan(a) - 0.06
	it.append(_i(_pr(), Vector3(cx, eave_y + 0.06 + ch * 0.5, cz), core, Vector3.ZERO, Vector3(hc * 2.0, ch, ln - 0.4)))
	var w: float = slope_l / courses + 0.14
	for s: float in [-1.0, 1.0]:
		var e := Vector3(cx + s * hd, eave_y, cz)
		var u := Vector3(-s * cos(a), sin(a), 0.0)
		var nrm := Vector3(s * sin(a), cos(a), 0.0)
		for k: int in courses:
			var p: Vector3 = e + u * ((k + 0.5) * slope_l / courses) + nrm * 0.1
			var flare: float = deg_to_rad(16.0 - 12.0 * float(k) / maxf(courses - 1, 1))
			var shade: float = 0.86 + 0.14 * float(k) / maxf(courses - 1, 1)
			var tcol: Color = T(tile.r * shade) if tile.a < 0.5 else Color(tile.r * shade, tile.g * shade, tile.b * shade)
			it.append(_ix(box, Transform3D(Basis(Vector3.BACK, -s * (a - flare)).scaled_local(Vector3(w, 0.16, ln)), p), tcol))
		for z: float in [z0 - 0.04, z1 + 0.04]:
			var p2: Vector3 = e + u * (slope_l * 0.5) + nrm * 0.2
			it.append(_ix(box, Transform3D(Basis(Vector3.BACK, -s * a).scaled_local(Vector3(slope_l + 0.25, 0.26, 0.18)),
				Vector3(p2.x, p2.y, z)), trim))
	it.append(_i(_pr(), Vector3(cx, eave_y + rise + 0.1, cz), trim, Vector3.ZERO, Vector3(0.56, 0.32, ln + 0.1)))


## Point on a _gable_x slope: side -1 (front, -Z) / +1, t 0 eave .. 1 ridge, `out` metres off the slope, at x.
func _gx_point(cz: float, hd: float, eave_y: float, rise: float, side: float, t: float, out: float, x: float) -> Vector3:
	var a: float = atan2(rise, hd)
	return Vector3(x, eave_y + rise * t, cz + side * hd * (1.0 - t)) + Vector3(0.0, cos(a), side * sin(a)) * out


## A rectangular hay bale (`s` size) with two twine bands, yawed `yaw`.
func _bale(it: Array, p: Vector3, s: Vector3, yaw: float, tilt: float = 0.0) -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(yaw), deg_to_rad(tilt)))
	it.append(_ix(_bx(), Transform3D(b.scaled_local(s), p), c_straw))
	for f: float in [-0.25, 0.25]:
		it.append(_ix(_bx(), Transform3D(b.scaled_local(Vector3(0.07, s.y + 0.03, s.z + 0.03)),
			p + b * Vector3(f * s.x, 0, 0)), c_straw_dk))


## A round bale lying on its side (radius r, width w) with its spiral end and two twine bands.
func _round_bale(it: Array, p: Vector3, r: float, w: float, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.BACK, PI * 0.5)
	it.append(_ix(_cyc(r, r, w, 12), Transform3D(b, p + Vector3(0, r, 0)), c_straw))
	for f: float in [-0.28, 0.28]:
		it.append(_ix(_cy(r + 0.02, r + 0.02, 0.06, 12), Transform3D(b, p + Vector3(0, r, 0) + b * Vector3(0, f * w, 0)), c_straw_dk))
	for f2: float in [-0.5, 0.5]:
		it.append(_ix(_cyc(r * 0.55, r * 0.55, 0.03, 10), Transform3D(b, p + Vector3(0, r, 0) + b * Vector3(0, f2 * (w + 0.02), 0)),
			c_straw_dk.lerp(c_straw, 0.4)))


## A hay heap (flattened lumps).
func _hay_heap(it: Array, p: Vector3, r: float, rng: RandomNumberGenerator) -> void:
	it.append(_i(_sp(10, 5), p + Vector3(0, r * 0.25, 0), c_straw, Vector3(0, rng.randf() * 90.0, 0), Vector3(r * 2.0, r * 0.9, r * 1.7)))
	for k: int in 2:
		var a: float = TAU * k / 3.0 + rng.randf()
		it.append(_i(_sp(8, 4), p + Vector3(cos(a) * r * 0.6, r * 0.2, sin(a) * r * 0.6), c_straw_dk.lerp(c_straw, 0.5),
			Vector3(0, rng.randf() * 90.0, 0), Vector3(r * 0.9, r * 0.45, r * 0.8)))
	for k: int in 2:
		var a2: float = rng.randf() * TAU
		it.append(_i(_bx(), p + Vector3(cos(a2) * r * 0.9, 0.04, sin(a2) * r * 0.9), c_straw.lightened(0.08),
			Vector3(rng.randf_range(-8, 8), rng.randf() * 180.0, 0), Vector3(0.5, 0.04, 0.08)))


## Straw scattered on the paddock earth (flat strands).
func _straw_scatter(it: Array, rng: RandomNumberGenerator, n: int, rect: Rect2) -> void:
	for k: int in n:
		var p := Vector3(rng.randf_range(rect.position.x, rect.end.x), 0.085, rng.randf_range(rect.position.y, rect.end.y))
		it.append(_i(_bx(), p, c_straw.lerp(c_straw_dk, rng.randf() * 0.6), Vector3(rng.randf_range(-6, 6), rng.randf() * 180.0, rng.randf_range(-6, 6)),
			Vector3(rng.randf_range(0.35, 0.7), 0.03, rng.randf_range(0.05, 0.12))))


## A stall bay on the barn wall at z (x centre, `out` = -1 front / +1 back): dark upper opening, a braced half-door,
## strap hinges, a lintel and a team plaque over the door.
func _stall(it: Array, x: float, w: float, z: float, out: float) -> void:
	var box: BoxMesh = _bx()
	var o: float = out
	it.append(_i(box, Vector3(x, 2.25, z + o * 0.02), Color.BLACK, Vector3.ZERO, Vector3(w - 0.25, 0.85, 0.08), K_HOLE))
	it.append(_i(box, Vector3(x, 1.3, z + o * 0.07), c_wood, Vector3.ZERO, Vector3(w - 0.28, 0.95, 0.1)))
	it.append(_ix(box, _seg(Vector3(x - (w - 0.4) * 0.5, 0.95, z + o * 0.14), Vector3(x + (w - 0.4) * 0.5, 1.62, z + o * 0.14), 0.1, 0.05), c_beam))
	for y: float in [0.98, 1.64]:
		it.append(_i(box, Vector3(x, y, z + o * 0.15), c_beam, Vector3.ZERO, Vector3(w - 0.3, 0.1, 0.05)))
	it.append(_i(box, Vector3(x - (w - 0.28) * 0.5 + 0.12, 1.31, z + o * 0.17), c_trim, Vector3.ZERO, Vector3(0.22, 0.75, 0.04), K_METAL))
	it.append(_i(box, Vector3(x, 2.72, z + o * 0.06), c_beam, Vector3.ZERO, Vector3(w, 0.16, 0.16)))
	it.append(_i(box, Vector3(x, 2.87, z + o * 0.1), T(1.0), Vector3.ZERO, Vector3(0.46, 0.22, 0.05)))


## Scaffolding around the barn + tower while the site rises (timber colour), child of the root.
func _build_scaffold(cx: float, cz: float, sx: float, sz: float, top: float) -> void:
	var box: BoxMesh = _bx()
	var it: Array = []
	var hx: float = sx * 0.5
	var hz: float = sz * 0.5
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(0, -1), Vector2(0, 1)]:
		it.append(_i(_cyc(0.09, 0.09, top + 0.7, 6), Vector3(cx + c.x * hx, (top + 0.7) * 0.5, cz + c.y * hz), c_wood))
	for y: float in [top * 0.45, top]:
		for s: float in [-1.0, 1.0]:
			it.append(_i(box, Vector3(cx, y, cz + s * hz), c_wood.darkened(0.1), Vector3(0, 0, s * 2.0), Vector3(sx + 0.3, 0.1, 0.45)))
			it.append(_i(box, Vector3(cx + s * hx, y, cz), c_wood.darkened(0.1), Vector3(s * 2.0, 0, 0), Vector3(0.45, 0.1, sz + 0.3)))
	for s: float in [-1.0, 1.0]:
		it.append(_ix(box, _seg(Vector3(cx - hx, 0.4, cz + s * (hz + 0.1)), Vector3(cx + hx * 0.1, top, cz + s * (hz + 0.1)), 0.1, 0.1), c_beam))
	# The tower's pole frame, a timber pile, a stone pallet and a hay bale by the paddock.
	for c2: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_i(_cyc(0.08, 0.08, T_EAVE + 0.8, 6), Vector3(TX + c2.x * (THX + 0.3), (T_EAVE + 0.8) * 0.5, TZ + c2.y * (THZ + 0.3)), c_wood))
	it.append(_i(box, Vector3(TX, T_EAVE - 0.3, TZ - THZ - 0.3), c_wood.darkened(0.1), Vector3.ZERO, Vector3(THX * 2 + 0.8, 0.1, 0.45)))
	for k: int in 3:
		it.append(_i(_cy(0.1, 0.1, 1.9, 6), Vector3(0.6 + 0.02 * k, 0.12 + 0.19 * (k % 2), -1.5 + 0.21 * k), c_wood,
			Vector3(0, 0, 90)))
	for p: Vector3 in [Vector3(-1.6, 0.28, -1.9), Vector3(-1.05, 0.28, -2.15), Vector3(-1.35, 0.8, -2.0)]:
		it.append(_i(box, p, c_stone, Vector3(0, p.x * 25.0, 0), Vector3(0.55, 0.5, 0.55), K_STONE))
	_bale(it, Vector3(1.9, 0.25, -2.1), Vector3(0.9, 0.5, 0.55), 15.0)
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	add_child(_scaffold)
	_vc("ScaffoldParts", "scaffold", it, _scaffold)
	_scaffold.visible = false


## Rubble / debris cubes in the foundation colour (one draw each), baked with vertex colours.
func _cubes(nm: String, points: Array, size: float, rng: RandomNumberGenerator, parent: Node3D) -> MultiMeshInstance3D:
	var ck: String = "%s/cube_%.2f" % [get_script().resource_path, size]
	var am: ArrayMesh = _vc_cache.get(ck)
	if am == null:
		var mats: Array[Material] = [mat_body]
		am = _vc_bake([[_bx(), Transform3D(Basis.from_scale(Vector3.ONE * size), Vector3.ZERO), mat_body, c_found.lightened(0.08), K_PLAIN]], mats)
		_vc_cache[ck] = am
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = am
	mm.instance_count = points.size()
	for i: int in points.size():
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(10.0, 22.0)))
		mm.set_instance_transform(i, Transform3D(b.scaled(Vector3.ONE * rng.randf_range(0.7, 1.2)), points[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.material_override = mat_body
	parent.add_child(mmi)
	mmi.set_instance_shader_parameter(&"ao_bottom", -0.3)
	mmi.set_instance_shader_parameter(&"ao_height", 2.0)
	return mmi


## A caved-in roof patch on a _gable_x slope (dark hole, broken rafters, loose team tiles, embers if burning),
## child of `roof`, hidden until the health state shows it.
func _roof_patch(nm: String, roof: Node3D, pos: Vector3, side: float, rise: float, hd: float, size: float,
		burning: bool) -> MeshInstance3D:
	var box: BoxMesh = _bx()
	var a: float = atan2(rise, hd)
	var b := Basis(Vector3.RIGHT, side * a)
	var nrm: Vector3 = b * Vector3.UP
	var up: Vector3 = b * Vector3(0, 0, -side)
	var it: Array = []
	it.append(_ix(box, Transform3D(b.scaled_local(Vector3(size, 0.05, size * 0.9)), pos + nrm * 0.12), Color.BLACK, K_HOLE))
	if burning:
		it.append(_ix(box, Transform3D(b.scaled_local(Vector3(size * 0.62, 0.05, size * 0.55)), pos + nrm * 0.15),
			Color.WHITE, K_PLAIN, mat_glow))
	for k: int in 3:
		var rb: Basis = b * Basis(Vector3.UP, deg_to_rad(80.0 + 12.0 * k)) * Basis(Vector3.RIGHT, deg_to_rad(8.0 - 8.0 * k))
		it.append(_ix(box, Transform3D(rb.scaled_local(Vector3(0.13, 0.13, size * 1.1)),
			pos + nrm * 0.2 + b * Vector3(-size * 0.3 + size * 0.3 * k, 0, 0)), c_beam))
	for k: int in 3:
		var tb: Basis = b * Basis(Vector3.RIGHT, deg_to_rad(-20.0 - 12.0 * k)) * Basis(Vector3.UP, 0.8 * k)
		it.append(_ix(box, Transform3D(tb.scaled_local(Vector3(0.5, 0.09, 0.4)),
			pos + nrm * 0.22 + up * (size * 0.55) + b * Vector3(-0.4 + 0.4 * k, 0, 0)), T(0.8)))
	var mi := _vc(nm, nm.to_lower(), it, roof, false)
	mi.visible = false
	return mi


## The collapse wreck: broken wall teeth along the barn, the tower stump, charred beams, torn team roof slabs,
## scattered hay, fallen fence rails, embers (kingdom glow). Child of the root, shown at 1.6 s.
func _build_stables_wreck(rng_seed: int) -> void:
	var box: BoxMesh = _bx()
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var it: Array = []
	var stub: float = PT + (EAVE - PT) * 0.3
	for k: int in 8:
		var along: float = rng.randf_range(-0.9, 0.9)
		var p := Vector3((BX0 + BX1) * 0.5 + along * (BX1 - BX0) * 0.5, 0.0, BZ0 + 0.15 if k % 2 == 0 else BZ1 - 0.15)
		if k >= 6:
			p = Vector3(BX1 - 0.15, 0.0, rng.randf_range(BZ0, BZ1))
		var s := Vector3(rng.randf_range(0.5, 0.9), rng.randf_range(0.5, 1.1), rng.randf_range(0.3, 0.5))
		p.y = stub + s.y * 0.5 - 0.15
		it.append(_i(box, p, c_wall if k % 3 else c_stone, Vector3(rng.randf_range(-10, 10), rng.randf_range(-15, 15),
			rng.randf_range(-12, 12)), s))
	it.append(_i(_cy(TR - 0.2, TR + 0.02, 1.3, TSEG), Vector3(TX, PT + 0.65, TZ), c_stone, Vector3(0, 18, 0)))
	it.append(_i(box, Vector3(TX + 0.3, PT + 1.45, TZ - 0.4), c_stone, Vector3(10, 25, 14), Vector3(0.7, 0.55, 0.7)))
	for k: int in 5:
		var p2 := Vector3(rng.randf_range(BX0, BX1), stub + rng.randf_range(0.15, 0.4), rng.randf_range(BZ0, BZ1))
		it.append(_i(box, p2, c_beam.darkened(0.3), Vector3(rng.randf_range(-25, 25), rng.randf() * 180.0,
			rng.randf_range(-18, 18)), Vector3(0.24, 0.24, rng.randf_range(2.2, 3.2))))
	for k: int in 3:
		var p3 := Vector3(rng.randf_range(BX0, BX1) * 0.8, stub + 0.25, rng.randf_range(BZ0, BZ1))
		it.append(_i(box, p3, T(0.75), Vector3(rng.randf_range(-20, 20), rng.randf() * 180.0,
			rng.randf_range(18, 30) * (1.0 if k % 2 == 0 else -1.0)), Vector3(1.4, 0.14, 1.2)))
	_hay_heap(it, Vector3(-1.2, 0.05, -1.2), 0.7, rng)
	_hay_heap(it, Vector3(1.4, 0.05, -0.8), 0.55, rng)
	for k: int in 5:
		var p4 := Vector3(rng.randf_range(-2.4, 2.4), 0.12, FZ + rng.randf_range(0.0, 0.5))
		it.append(_i(box, p4, c_wood.darkened(0.2), Vector3(rng.randf_range(-6, 6), rng.randf_range(-30, 30), 0),
			Vector3(1.4, 0.1, 0.12)))
	for k: int in 4:
		var p6 := Vector3(rng.randf_range(-2.6, 2.6), 0.4, FZ + rng.randf_range(-0.05, 0.3))
		it.append(_i(_cyc(0.09, 0.1, 0.8, 6), p6, c_beam, Vector3(rng.randf_range(-35, 35), 0, rng.randf_range(-35, 35))))
	for k: int in 5:
		var p5 := Vector3(rng.randf_range(BX0, BX1) * 0.7, stub + 0.05, rng.randf_range(BZ0, BZ1))
		it.append(_i(box, p5, Color.WHITE, Vector3(0, rng.randf() * 90.0, 20), Vector3.ONE * 0.3, K_PLAIN, mat_glow))
	_wreck = Node3D.new()
	_wreck.name = "Wreck"
	add_child(_wreck)
	_vc("WreckParts", "wreck", it, _wreck)
	_wreck.visible = false


## The paddock fence (kingdom posts and rails) with a gap for the gate, a broken-rail pair for the damage state; the
## gate itself (two leaves on hinges, each a node that swings on the training pulse).
func _build_fence() -> Node3D:
	var box: BoxMesh = _bx()
	var it: Array = []
	var posts: Array[Vector3] = []
	for x: float in [-FX, -2.1, -1.4, -GATE_HALF - 0.08, GATE_HALF + 0.08, 1.4, 2.1, FX]:
		posts.append(Vector3(x, 0.0, FZ))
	for s: float in [-1.0, 1.0]:
		for z: float in [-2.15, -1.4, -0.65]:
			posts.append(Vector3(s * FX, 0.0, z))
	for p: Vector3 in posts:
		_k_post(it, p)
	var rails: Array = []
	rails.append([Vector3(-FX, 0, FZ), Vector3(-GATE_HALF - 0.08, 0, FZ)])
	rails.append([Vector3(GATE_HALF + 0.08, 0, FZ), Vector3(1.4, 0, FZ)])
	for s: float in [-1.0, 1.0]:
		rails.append([Vector3(s * FX, 0, FZ), Vector3(s * FX, 0, -0.65)])
	for r: Array in rails:
		for y: float in [0.5, 0.92]:
			_k_rail(it, (r[0] as Vector3) + Vector3(0, y, 0), (r[1] as Vector3) + Vector3(0, y, 0))
	var fence := _vc("PlinthFence", "fence", it)
	it = []
	for y: float in [0.5, 0.92]:
		_k_rail(it, Vector3(1.4, y, FZ), Vector3(FX, y, FZ))
	var whole := _vc("FenceSpan", "fence_span", it, fence)
	_hide_below_50.append(whole)
	it = []
	it.append(_ix(box, _seg(Vector3(1.4, 0.92, FZ), Vector3(2.35, 0.1, FZ - 0.35), 0.13, 0.12), c_wood.darkened(0.25)))
	it.append(_ix(box, _seg(Vector3(FX, 0.5, FZ), Vector3(2.25, 0.08, FZ - 0.1), 0.13, 0.12), c_wood.darkened(0.25)))
	it.append(_ix(box, _seg(Vector3(1.4, 0.5, FZ), Vector3(1.85, 0.62, FZ + 0.05), 0.13, 0.12), c_wood.darkened(0.2)))
	var broken := _vc("FenceBroken", "fence_broken", it, fence)
	broken.visible = false
	_show_below_50.append(broken)
	_hide_on_collapse.append(fence)
	var gate := Node3D.new()
	gate.name = "PlinthGate"
	_body.add_child(gate)
	_gate_l = Node3D.new()
	_gate_l.name = "LeafL"
	_gate_l.position = Vector3(-GATE_HALF, 0, FZ)
	gate.add_child(_gate_l)
	_gate_r = Node3D.new()
	_gate_r.name = "LeafR"
	_gate_r.position = Vector3(GATE_HALF, 0, FZ)
	gate.add_child(_gate_r)
	for side: int in 2:
		var s2: float = 1.0 if side == 0 else -1.0   # the leaf extends toward the gate centre
		it = []
		var L: float = GATE_HALF - 0.04
		for y: float in [0.35, 0.95]:
			it.append(_i(box, Vector3(s2 * L * 0.5, y, 0), c_wood, Vector3.ZERO, Vector3(L, 0.13, 0.1)))
		it.append(_i(box, Vector3(s2 * 0.06, 0.62, 0), c_beam, Vector3.ZERO, Vector3(0.12, 0.85, 0.12)))
		it.append(_i(box, Vector3(s2 * (L - 0.05), 0.62, 0), c_beam, Vector3.ZERO, Vector3(0.1, 0.8, 0.1)))
		it.append(_ix(box, _seg(Vector3(s2 * 0.08, 0.35, -0.02), Vector3(s2 * (L - 0.06), 0.95, -0.02), 0.09, 0.07), c_wood.darkened(0.1)))
		it.append(_i(box, Vector3(s2 * L * 0.5, 0.66, -0.05), T(1.0), Vector3.ZERO, Vector3(L * 0.7, 0.26, 0.03)))
		it.append(_i(box, Vector3(s2 * L * 0.5, 0.66, -0.07), T(0.6), Vector3.ZERO, Vector3(L * 0.7, 0.05, 0.02)))
		_vc("GateLeaf", "gate_leaf_%d" % side, it, _gate_l if side == 0 else _gate_r)
	_hide_on_collapse.append(gate)
	return fence


## A banner on a pole (pole in `it`, the cloth a separate banner node facing +-X).
func _banner_pole(it: Array, base: Vector3, h: float, cloth: Vector2, parent: Node3D = null) -> MeshInstance3D:
	it.append(_i(_cyc(0.07, 0.09, h, 8), base + Vector3(0, h * 0.5, 0), c_beam))
	it.append(_i(_cyc(0.0, 0.1, 0.22, 6), base + Vector3(0, h + 0.1, 0), c_trim, Vector3.ZERO, Vector3.ONE, K_METAL))
	it.append(_i(_bx(), base + Vector3(0, h - 0.12, 0), c_trim, Vector3.ZERO, Vector3(0.12, 0.1, cloth.x + 0.3), K_METAL))
	return _banner("GateBanner", cloth, base + Vector3(0.06, h - 0.2 - cloth.y * 0.5, 0), 90.0, parent)


## A hanging lantern on a bracket (glow core in `glow`).
func _lantern(it: Array, hook: Vector3, glow: Material, cage: Color) -> void:
	it.append(_i(_bx(), hook + Vector3(0, -0.12, 0), c_beam, Vector3.ZERO, Vector3(0.04, 0.24, 0.04)))
	it.append(_i(_cyc(0.1, 0.17, 0.12, 6), hook + Vector3(0, -0.28, 0), cage, Vector3.ZERO, Vector3.ONE, K_METAL))
	it.append(_i(_bx(), hook + Vector3(0, -0.52, 0), Color.WHITE, Vector3(0, 45, 0), Vector3(0.24, 0.32, 0.24), K_PLAIN, glow))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, 1)]:
		it.append(_i(_bx(), hook + Vector3(c.x * 0.12, -0.52, c.y * 0.12), cage, Vector3.ZERO, Vector3(0.03, 0.34, 0.03), K_METAL))
	it.append(_i(_cyc(0.15, 0.15, 0.05, 6), hook + Vector3(0, -0.7, 0), cage, Vector3.ZERO, Vector3.ONE, K_METAL))


# --- Mounts (static, vertex-coloured; one body mesh + a head pivot + a tail pivot) ------------------------------------

## A quadruped standing at `pos` facing `yaw_deg` (its muzzle along its local -Z), root child. Proportions from
## `prof` (see _k_mount_prof); the kingdom adds its features in _k_mount_extra and _k_head.
func _build_mount(pos: Vector3, yaw_deg: float, prof: Dictionary) -> void:
	_mount = Node3D.new()
	_mount.name = "Mount"
	_mount.position = pos
	_mount.rotation.y = deg_to_rad(yaw_deg)
	_mount.scale = Vector3.ONE * mount_len
	add_child(_mount)
	var L: float = prof.get("len", 1.9)
	var H: float = prof.get("height", 1.25)
	var G: float = prof.get("girth", 0.62)
	var coat: Color = prof["coat"]
	var dark: Color = prof["dark"]
	var hoof: Color = prof.get("hoof", dark.darkened(0.4))
	var leg_r: float = prof.get("leg_r", 0.09)
	var body: Array = []
	var bh: float = H * 0.72
	body.append(_i(_sp(10, 5), Vector3(0, bh, -L * 0.18), coat, Vector3.ZERO, Vector3(G, G * 1.02, L * 0.55)))
	body.append(_i(_sp(10, 5), Vector3(0, bh + 0.02, L * 0.2), coat.darkened(0.05), Vector3.ZERO, Vector3(G * 0.98, G, L * 0.5)))
	body.append(_i(_sp(10, 5), Vector3(0, bh - G * 0.12, 0.0), coat.darkened(0.12), Vector3.ZERO, Vector3(G * 0.86, G * 0.7, L * 0.6)))
	for lx: float in [-1.0, 1.0]:
		for lz: float in [-1.0, 1.0]:
			var top := Vector3(lx * G * 0.3, bh - G * 0.2, lz * L * 0.3 + (0.04 if lz > 0 else -0.02))
			var knee := top + Vector3(0, -(bh - G * 0.2) * 0.5, lz * 0.04)
			var foot := Vector3(top.x, 0.07, top.z + lz * 0.03)
			body.append(_rod(top, knee, leg_r * 1.5, leg_r * 1.05, 6, coat.darkened(0.08)))
			body.append(_rod(knee, foot, leg_r * 1.0, leg_r * 0.9, 6, dark))
			body.append(_i(_cyc(leg_r * 1.25, leg_r * 1.35, 0.12, 6), foot + Vector3(0, -0.01, 0), hoof))
	# Saddle cloth in the team colour (top-facing) with a dark hem, a leather saddle with a pommel.
	body.append(_i(_bx(), Vector3(0, bh + G * 0.43, -0.02), T(1.0), Vector3.ZERO, Vector3(G * 1.08, 0.08, L * 0.36)))
	for s: float in [-1.0, 1.0]:
		body.append(_i(_bx(), Vector3(s * G * 0.53, bh + G * 0.15, -0.02), T(0.9), Vector3(0, 0, s * 12.0), Vector3(0.05, G * 0.55, L * 0.36)))
		body.append(_i(_bx(), Vector3(s * G * 0.56, bh - G * 0.12, -0.02), T(0.55), Vector3(0, 0, s * 12.0), Vector3(0.05, 0.08, L * 0.37)))
	body.append(_i(_sp(10, 5), Vector3(0, bh + G * 0.5, -0.02), c_leather, Vector3.ZERO, Vector3(G * 0.55, 0.16, L * 0.26)))
	body.append(_i(_bx(), Vector3(0, bh + G * 0.55, -L * 0.1), c_leather.lightened(0.1), Vector3(-10, 0, 0), Vector3(0.12, 0.14, 0.08)))
	var neck_base := Vector3(0, bh + G * 0.22, -L * 0.36)
	var neck_top := neck_base + Vector3(0, prof.get("neck_h", 0.55), -prof.get("neck_f", 0.28))
	body.append(_rod(neck_base, neck_top, G * prof.get("neck_r", 0.36), G * prof.get("neck_r", 0.36) * 0.72, 8, coat))
	var tail: Array = []
	_k_mount_extra(body, tail, bh, L, G)
	_vc("MountBody", "mount_body", body, _mount)
	_mount_head = Node3D.new()
	_mount_head.name = "HeadPivot"
	_mount_head.position = neck_top
	_mount.add_child(_mount_head)
	var head: Array = []
	_k_head(head, Transform3D.IDENTITY)
	_vc("MountHead", "mount_head", head, _mount_head)
	_mount_tail = Node3D.new()
	_mount_tail.name = "TailPivot"
	_mount_tail.position = Vector3(0, bh + G * 0.25, L * 0.46)
	_mount.add_child(_mount_tail)
	if not tail.is_empty():
		_vc("MountTail", "mount_tail", tail, _mount_tail)
	_mount.visible = false
	_hide_on_collapse.append(_mount)


## A lumpy flat-shaded ground patch (size x / z, `nx` x `nz` cells, heights up to `amp`, edges at 0), each triangle
## its own normal and a slightly different shade (vertex colour, multiplied by the item colour). Cached per key.
static func _bumpy(size: Vector2, nx: int, nz: int, amp: float, rng_seed: int) -> ArrayMesh:
	var key: String = "bumpy%s_%d_%d_%.2f_%d" % [size, nx, nz, amp, rng_seed]
	if _prim_cache.has(key):
		return _prim_cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var hgt: Array = []
	for i: int in nx + 1:
		var row: Array = []
		for j: int in nz + 1:
			var edge: bool = i == 0 or j == 0 or i == nx or j == nz
			row.append(0.0 if edge else rng.randf_range(0.2, 1.0) * amp)
		hgt.append(row)
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var C := PackedColorArray()
	var pt := func(i: int, j: int) -> Vector3:
		return Vector3(-size.x * 0.5 + size.x * i / nx, float(hgt[i][j]), -size.y * 0.5 + size.y * j / nz)
	for i: int in nx:
		for j: int in nz:
			var a: Vector3 = pt.call(i, j)
			var b: Vector3 = pt.call(i + 1, j)
			var c: Vector3 = pt.call(i + 1, j + 1)
			var d: Vector3 = pt.call(i, j + 1)
			for tri: Array in [[a, c, b], [a, d, c]]:
				var n: Vector3 = ((tri[1] as Vector3) - (tri[0] as Vector3)).cross((tri[2] as Vector3) - (tri[0] as Vector3)).normalized()
				var shade: float = rng.randf_range(0.86, 1.08)
				for v: Vector3 in tri:
					V.append(v)
					N.append(n)
					C.append(Color(shade, shade, shade, 1.0))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V
	arr[Mesh.ARRAY_NORMAL] = N
	arr[Mesh.ARRAY_COLOR] = C
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_prim_cache[key] = am
	return am


## `c` darkened by `s` (a team colour stays a team multiplier).
static func _shade(c: Color, s: float) -> Color:
	return Color(c.r * s, c.g * s, c.b * s, c.a)
