class_name FrostForgeModel
extends FireHallModel
## Visual model of Torvald's Forge, the Frost Forge (task G-B Ice, docs/art/gb_ice_buildings.md; unit-upgrades.md: kind
## &"forge", 3 x 3 cells = 6 x 6 m, data height 4). It replaces the ForgeBuilding placeholder (anvil yard + chimney)
## through BuildingType.model_path, in the Rime Keep / Frost Hall language.
## Read from the RTS camera:
## - Dominant vertical (back right, ~6.3 m): a tall ice-stone chimney banded in silver, crowned with four small team
##   crystals around a floating cold flame (frostfire: a glowing shard + pale flame particles).
## - The smithy: a battered ice-stone house under a hipped roof of glazed team-ice tiles with a snow cap and icicle
##   fringes; on its front the forge mouth (dark arch, silver frame) glows with the frostfire (it flares when a research
##   completes: play_training_pulse), warm-lit side slits.
## - The yard in front (asymmetric): a great anvil carved from team ice on a dark block (left), a quench trough of pale
##   frost-water and a stack of silver ingots (right), a crystal cluster erupting at the back-left corner, a team banner
##   on a post, snow drifts, a frost patch on the ground.
## Hooks (FireHallModel contract, art-keep.md 8.8): set_team_color, set_construction_progress, set_health_ratio,
## play_training_pulse, play_destroyed (-> destroyed_finished after 3 s), set_selected. No active light (emissive only).

const HX := -0.45     ## smithy axis x
const HZ := 0.75      ## smithy centre z
const WX := 1.85      ## smithy half-width
const WZ := 1.45      ## smithy half-depth
const PT := 0.45      ## plinth top
const WALL_H := 2.5
const CHIM := Vector3(1.75, PT, 1.6)
const CHIM_H := 4.6
const FLAME_Y := 5.75  ## the floating frostfire shard (chimney space)
const FROST_GROUND: Shader = preload("res://art/buildings/ice/ice_frost_ground.gdshader")

var mat_snow: ShaderMaterial
var mat_roof: ShaderMaterial    ## glazed roof tiles: the team colour, deeper
var mat_window: ShaderMaterial  ## warm side slits
var _flame: MeshInstance3D
var _frost_mat: ShaderMaterial


func _setup_palette() -> void:
	kingdom_color = Color(0.45, 0.75, 0.95)
	glow_color = Color(0.75, 0.92, 1.00)
	stone_color = Color(0.40, 0.49, 0.63)
	dark_color = Color(0.27, 0.31, 0.39)
	metal_color = Color(0.70, 0.78, 0.88)
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
	if _flame and _flame.visible:
		_flame.position.y = FLAME_Y + 0.12 * sin(_t * 2.1)
		_flame.rotation.y += 1.1 * delta


## Frost Forge parts (Body space, gate -Z). Heights: plinth 0.45, smithy walls 2.95, roof ridge ~4.3, chimney 5.05,
## frostfire ~6.3. Tiers: PlinthBase, Walls (smithy + forge mouth), Roof, Chimney (falls on the collapse; its crystal
## crown is lost under 50 %), Yard (anvil, trough, ingots, crystal cluster).
func _build_structure() -> void:
	_top_y = 6.4
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var sq: Mesh = IceShapes.prism(1.0, 1.0, 1.0, 4)
	var mound: Mesh = IceShapes.mound()
	mat_snow = _painted_mat(Color(0.86, 0.92, 1.0), 0.15, 0.0)
	mat_roof = _painted_mat(kingdom_color.darkened(0.35), 0.45, 0.35)
	mat_roof.set_shader_parameter(&"crack_scale", 1.2)
	mat_roof.set_shader_parameter(&"crack_speed", 0.9)
	mat_team.set_shader_parameter(&"spec_strength", 0.5)   # team = glazed crystal ice
	mat_team.set_shader_parameter(&"crack_strength", 0.9)
	mat_team.set_shader_parameter(&"crack_scale", 1.2)
	mat_team.set_shader_parameter(&"crack_speed", 0.9)
	mat_stone.set_shader_parameter(&"crack_scale", 1.8)
	mat_gate.set_shader_parameter(&"rune_bands", 0)
	mat_window = _glow_mat(2.0, 0.8, 0)
	mat_window.set_shader_parameter(&"glow_color", IceShapes.window_color(glow_color))
	var hole: StandardMaterial3D = _hole_mat()
	hole.albedo_color = Color(0.02, 0.03, 0.06)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8808
	# --- Plinth: a battered dark tier, a step at the forge mouth, snow drifts, ice spikes erupting at two corners.
	var it: Array = []
	it.append(BMG.item(IceShapes.prism(2.92, 2.84, 0.3, 4), Vector3.ZERO, mat_dark))
	it.append(BMG.item(IceShapes.prism(2.74, 2.7, 0.15, 4), Vector3(0, 0.3, 0), mat_dark))
	it.append(BMG.item(box1, Vector3(HX, 0.12, -3.0), mat_dark, Vector3.ZERO, Vector3(1.6, 0.24, 0.45)))
	for d: Array in [[Vector3(2.95, 0.0, -0.6), Vector3(0.36, 0.22, 1.0)], [Vector3(-2.95, 0.0, 1.4), Vector3(0.4, 0.22, 0.9)],
			[Vector3(0.4, 0.0, 2.95), Vector3(1.1, 0.2, 0.36)], [Vector3(-2.2, PT, 2.3), Vector3(0.5, 0.18, 0.35)]]:
		it.append(BMG.item(mound, d[0], mat_snow, Vector3(0, rng.randf_range(-20, 20), 0), d[1]))
	for cl: Vector2 in [Vector2(225.0, 3.5), Vector2(320.0, 3.4)]:
		var a0: float = deg_to_rad(cl.x)
		for j: int in 3:
			var a: float = a0 + rng.randf_range(-0.22, 0.22)
			var out := Vector3(cos(a), 0.0, sin(a))
			var sc: float = rng.randf_range(0.8, 1.2) * (1.0 if j == 0 else 0.6)
			var b: Basis = IceShapes.lean(out, rng.randf_range(18.0, 42.0)) * Basis(Vector3.UP, rng.randf() * TAU) \
				* Basis.from_scale(Vector3.ONE * sc)
			it.append(BMG.item_xf(IceShapes.crystal(0.24, 0.6, 0.5, 0.0), Transform3D(b,
				out * (cl.y + rng.randf_range(-0.2, 0.2)) + Vector3(0, -0.15, 0)), mat_team))
	_merged("PlinthBase", "plinth", it, null, false)
	# --- Walls: the battered smithy, base course, corner piers, warm side slits, the forge mouth on the front.
	it = []
	it.append(BMG.item(sq, Vector3(HX, PT, HZ), mat_dark, Vector3.ZERO, Vector3(WX + 0.15, 0.4, WZ + 0.15)))
	it.append(BMG.item(IceShapes.prism(1.0, 0.94, 1.0, 4), Vector3(HX, PT, HZ), mat_stone, Vector3.ZERO,
		Vector3(WX, WALL_H, WZ)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)]:
		it.append(BMG.item(IceShapes.prism(0.32, 0.26, 1.0, 4), Vector3(HX + c.x * WX, PT, HZ + c.y * WZ), mat_dark,
			Vector3.ZERO, Vector3(1.0, WALL_H + 0.1, 1.0)))
	for sx: float in [-1.0, 1.0]:
		var p := Vector3(HX + sx * WX * 0.955, 1.9, HZ + 0.15)
		it.append(BMG.item(box1, p, mat_dark, Vector3.ZERO, Vector3(0.16, 1.0, 0.5)))
		it.append(BMG.item(box1, p + Vector3(sx * 0.07, -0.04, 0), mat_window, Vector3.ZERO, Vector3(0.08, 0.75, 0.22)))
		it.append(BMG.item(box1, p + Vector3(sx * 0.05, 0.56, 0), mat_snow, Vector3.ZERO, Vector3(0.22, 0.09, 0.6)))
	var fz: float = HZ - WZ * 0.97
	it.append(BMG.item(IceShapes.arch(0.82, 0.75, 0.3), Vector3(HX, PT, fz - 0.05), mat_dark))
	it.append(BMG.item(IceShapes.arch(0.68, 0.7, 0.14), Vector3(HX, PT, fz - 0.17), mat_metal))
	it.append(BMG.item(IceShapes.arch(0.54, 0.62, 0.1), Vector3(HX, PT, fz - 0.21), hole))
	it.append(BMG.item(box1, Vector3(HX, PT + 0.42, fz - 0.24), mat_gate, Vector3.ZERO, Vector3(0.78, 0.5, 0.04)))
	it.append(BMG.item(box1, Vector3(HX, PT + 1.82, fz - 0.22), mat_gate, Vector3(0, 0, 45), Vector3(0.28, 0.28, 0.08)))
	it.append(BMG.item(IceShapes.prism(1.0, 0.97, 1.0, 4), Vector3(HX, PT + WALL_H - 0.02, HZ), mat_snow, Vector3.ZERO,
		Vector3(WX + 0.08, 0.12, WZ + 0.08)))
	_merged("Walls", "walls", it)
	# --- Roof: a hipped roof of glazed team-ice tiles (two courses), a snow cap, icicle fringes front and back.
	it = []
	var ry: float = PT + WALL_H + 0.1
	it.append(BMG.item(IceShapes.prism(1.0, 0.55, 1.0, 4), Vector3(HX, ry, HZ), mat_roof, Vector3.ZERO,
		Vector3(WX + 0.32, 0.72, WZ + 0.32)))
	it.append(BMG.item(IceShapes.prism(1.0, 0.25, 1.0, 4), Vector3(HX, ry + 0.66, HZ), mat_roof, Vector3(0, 0, 0),
		Vector3(WX * 0.6, 0.62, WZ * 0.6)))
	it.append(BMG.item(IceShapes.prism(1.0, 0.45, 1.0, 4), Vector3(HX, ry + 0.95, HZ), mat_snow, Vector3.ZERO,
		Vector3(WX * 0.42, 0.3, WZ * 0.42)))
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(IceShapes.icicle_strip(WX * 2.0 + 0.3, 9, 0.55, 0.1, 81 if s < 0.0 else 82),
			Vector3(HX, ry + 0.02, HZ + s * (WZ + 0.3)), mat_snow))
	var roof := _merged("Roof", "roof", it)
	_hide_on_collapse.append(roof)
	_show_below_50.append(_roof_hole("RoofHole", roof, Vector3(HX - 0.7, ry + 0.4, HZ - 0.4), -1.0, WX, 0.7, false))
	# --- Chimney (dominant vertical; falls on the collapse): banded stack, crystal crown, the floating frostfire.
	var chim := Node3D.new()
	chim.name = "Chimney"
	chim.position = CHIM
	_body.add_child(chim)
	it = []
	it.append(BMG.item(IceShapes.prism(0.58, 0.58, 0.3, 4), Vector3.ZERO, mat_dark))
	it.append(BMG.item(IceShapes.prism(0.5, 0.4, CHIM_H, 4), Vector3.ZERO, mat_stone))
	for y: float in [1.9, 3.6]:
		it.append(BMG.item(IceShapes.prism(0.5, 0.48, 0.16, 4), Vector3(0, y, 0), mat_metal))
	it.append(BMG.item(IceShapes.prism(0.52, 0.52, 0.18, 4), Vector3(0, CHIM_H, 0), mat_dark))
	it.append(BMG.item(IceShapes.prism(0.5, 0.44, 0.1, 4), Vector3(0, CHIM_H + 0.18, 0), mat_snow))
	_merged("Stack", "stack", it, chim)
	it = []
	for i: int in 4:
		var a: float = TAU * float(i) / 4.0 + PI / 4.0
		var out := Vector3(cos(a), 0.0, sin(a))
		it.append(BMG.item_xf(IceShapes.crystal(0.13, 0.35, 0.3, 0.0), Transform3D(IceShapes.lean(out, 24.0),
			out * 0.36 + Vector3(0, CHIM_H + 0.24, 0)), mat_team))
	var crown := _merged("ChimneyCrown", "crown", it, chim)
	_hide_below_50.append(crown)
	_flame = _part("Frostfire", IceShapes.crystal(0.2, 0.25, 0.42, 0.42), Vector3(0, FLAME_Y, 0), mat_glow, Vector3.ZERO, chim)
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hide_below_50.append(_flame)
	_falling = chim
	_fall_axis = Vector3(1, 0, -1).normalized()
	_fall_deg = 34.0
	# --- Yard: the ice anvil (left), the quench trough and ingots (right), a team banner on a post.
	var yard := Node3D.new()
	yard.name = "Yard"
	_body.add_child(yard)
	it = []
	var an := Vector3(-1.95, PT, -1.75)
	it.append(BMG.item(IceShapes.prism(0.34, 0.24, 0.55, 4), an, mat_dark))
	it.append(BMG.item(box1, an + Vector3(0, 0.66, 0), mat_team, Vector3(0, 18, 0), Vector3(0.95, 0.24, 0.42)))
	it.append(BMG.item_xf(IceShapes.crystal(0.12, 0.0, 0.45, 0.0), Transform3D(Basis(Vector3.BACK, deg_to_rad(90.0)),
		an + Vector3(-0.42, 0.66, -0.15)), mat_team))
	it.append(BMG.item(box1, an + Vector3(0.08, 0.83, 0), mat_metal, Vector3(0, 30, 0), Vector3(0.5, 0.08, 0.1)))   # a blade
	var tr := Vector3(1.55, PT, -2.05)
	it.append(BMG.item(box1, tr + Vector3(0, 0.22, 0), mat_dark, Vector3(0, -8, 0), Vector3(1.25, 0.44, 0.62)))
	it.append(BMG.item(box1, tr + Vector3(0, 0.42, 0), mat_gate, Vector3(0, -8, 0), Vector3(1.05, 0.03, 0.44)))
	for i: int in 3:
		it.append(BMG.item(box1, Vector3(2.45, PT + 0.08 + 0.13 * i, -0.85 + 0.05 * i), mat_metal,
			Vector3(0, 12.0 * i, 0), Vector3(0.48, 0.12, 0.2)))
	it.append(BMG.item(_cyl(0.07, 0.08, 2.6, 6), Vector3(-2.55, PT + 1.3, -0.65), mat_metal))
	it.append(BMG.item(box1, Vector3(-2.55, PT + 2.55, -0.67), mat_metal, Vector3.ZERO, Vector3(0.7, 0.09, 0.09)))
	it.append(BMG.item(IceShapes.crystal(0.12, 0.1, 0.3, 0.1), Vector3(-2.55, PT + 2.72, -0.65), mat_team))
	for cl: Vector3 in [Vector3(-2.35, 0.0, 2.35)]:
		for j: int in 3:
			var a: float = deg_to_rad(135.0) + rng.randf_range(-0.4, 0.4)
			var out := Vector3(cos(a), 0.0, sin(a))
			var b2: Basis = IceShapes.lean(out, rng.randf_range(10.0, 30.0)) * Basis(Vector3.UP, rng.randf() * TAU) \
				* Basis.from_scale(Vector3.ONE * (1.0 if j == 0 else 0.62))
			it.append(BMG.item_xf(IceShapes.crystal(0.3, 0.9, 0.6, 0.0), Transform3D(b2, cl + out * 0.3 * j
				+ Vector3(0, PT - 0.1, 0)), mat_team))
	_merged("YardParts", "yard", it, yard, false)
	_hide_on_collapse.append(yard)
	var bn := _banner("Banner", Vector2(0.62, 1.5), Vector3(-2.55, PT + 1.7, -0.7), 0.0)
	_hide_below_25.append(bn)
	_hide_on_collapse.append(bn)
	# No active light (the base class drives _light, so it exists but stays hidden).
	_light = _omni(Vector3(HX, 1.4, -1.8), 6.0)
	_light.visible = false
	# Idle particles: pale frostfire licking up from the chimney, cold vapour at the trough, frost mist at the feet.
	var flame := _pm(Vector3.UP, 14.0, 0.6, 1.0, Vector3.ZERO, 0.32, 0.08, _fire_ramp)
	flame.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	flame.emission_sphere_radius = 0.18
	_idle_fx.append(_particles("Frostflame", chim, Vector3(0, CHIM_H + 0.4, 0), 12, 0.9, flame, _add_quad, false))
	var vap := _pm(Vector3.UP, 20.0, 0.15, 0.3, Vector3(0.05, 0.04, 0), 0.35, 0.9,
		_ramp(Color(0.85, 0.92, 1.0, 0.22), Color(0.85, 0.92, 1.0), false))
	vap.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	vap.emission_box_extents = Vector3(0.45, 0.02, 0.2)
	_idle_fx.append(_particles("TroughVapour", _body, tr + Vector3(0, 0.5, 0), 6, 2.4, vap, _mix_quad, false))
	if IceShapes.high_fx():
		var sf := _particles("Snowfall", _body, Vector3(0, 3.6, 0), 8, 3.4, IceShapes.snowfall_pm(2.8), _mix_quad, false)
		MoteCap.apply(sf, 0.05)   # G-F r2 item 7: small (sized quad), dim, faded near the camera
		sf.set_meta(&"no_ghost", true)   # dressing: never copied into the fog-of-war ghost
		_idle_fx.append(sf)
	# Construction scaffolding, the collapse wreck (the chimney stump), the frost patch on the ground.
	_build_scaffold(HX, HZ - 0.2, 4.4, 3.6, 3.6)
	_build_wreck(HX, HZ, 4.0, 3.2, PT + WALL_H * 0.3, CHIM + Vector3(0, 1.0, 0), Vector3(1.0, 2.0, 1.0), 8181)
	var decal := get_node_or_null(^"ContactDecal") as MeshInstance3D
	if decal:
		_frost_mat = ShaderMaterial.new()
		_frost_mat.shader = FROST_GROUND
		_frost_mat.set_shader_parameter(&"size", 9.0)
		_frost_mat.set_shader_parameter(&"plinth_half", 2.95)
		_frost_mat.set_shader_parameter(&"sectors", 14.0)
		_frost_mat.set_shader_parameter(&"seed", 3.7)
		_frost_mat.set_shader_parameter(&"glow_color", glow_color)
		decal.material_override = _frost_mat
	_smoke_points = [Vector3(HX - 0.7, ry + 0.6, HZ - 0.4), CHIM + Vector3(0, CHIM_H + 0.3, 0)]
	_blaze_points = [Vector3(HX + 0.6, ry + 0.4, HZ + 0.3), Vector3(HX, PT + 0.8, -1.2)]
	_rubble2_points = [CHIM + Vector3(0.6, 0.05, -0.5), CHIM + Vector3(-0.2, 0.05, -0.9), CHIM + Vector3(0.8, 0.05, 0.3)]
	_gate_pos = Vector3(HX, PT + 0.6, fz - 0.4)


## G-B Ice: after the B8 merge the body draws with the Ice paint layer (FireHallModel._post_build not called).
func _post_build() -> void:
	IceShapes.ice_vc(mat_team)


## The B8 paths stay on once the body is the Ice version of painted_vc.
func _vc_wanted() -> bool:
	return IceShapes.is_vc(mat_team) or (mat_team != null and mat_team.shader == PAINTED)


## B8 merge: the roof is the team colour darkened 35 %.
func _vc_team() -> Array:
	return [mat_team, [mat_roof, 0.65]]


func set_team_color(c: Color) -> void:
	super(c)
	if mat_roof:
		mat_roof.set_shader_parameter(&"base_color", c.darkened(0.35))
	if _ready_done and mat_banner:
		IceShapes.tint_banner(mat_banner, c, kingdom_color, glow_color if c.is_equal_approx(kingdom_color) else c.lightened(0.35))


## The keep's cold idle rim instead of the base one (selection still turns it to the team colour).
func _apply_rim_and_glow() -> void:
	super()
	if _ready_done:
		IceShapes.apply_ice_rim(_painted, _team_color, _sel_k, _progress < 1.0 and not _destroyed)


## Ice rubble (the lost chimney crown) is crystal, not dark stone.
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
