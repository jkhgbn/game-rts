class_name IceLodgeModel
extends SmallBuildingModel
## Ice house "Snow Lodge" (kingdom-ice.md 5 + 8.1: 2 x 2 cells = 4 x 4 m, height 3, +10 pop). Task 7.V2, epic pass
## A2.4 in the Rime Keep's language. Read from the RTS camera: a round igloo-lodge whose dome is built of four stepped
## courses of glazed team-coloured ice blocks (offset like bricks, a snow cap and a small crystal finial on top) on a
## battered ice-stone drum, a stone chimney at the back-right with a floating, turning frost crystal above it
## (dominant vertical, team glow), the keep's tombstone door at the end of a vaulted entrance tunnel (silver frame,
## black void, glowing keystone, icicles), a team banner on a pole beside the door and an ice lantern on a silver post
## at the front-right (asymmetric secondary), cold-lit windows, a stack of cut ice blocks at the back, snow drifts and
## ice spikes around an octagonal dark plinth, a frost patch on the ground.
## Tiers are merged meshes (Plinth, Walls, Dome, Lantern); no active light. Hooks: see SmallBuildingModel.

const FROST_GROUND: Shader = preload("res://art/buildings/ice/ice_frost_ground.gdshader")
const DOME_R := 1.68
const DOME_Y := 1.25
const COURSES: Array[float] = [0.0, 24.0, 46.0, 66.0, 84.0]   ## dome course angles (degrees)
const CHIM := Vector3(0.92, 0.0, 0.82)
const DOOR_X := -0.35

var _m_snow: ShaderMaterial
var _m_roof: ShaderMaterial   ## dome ice blocks: the team colour, deeper
var _window_mat: ShaderMaterial
var _banner_mat: ShaderMaterial
var _frost_mat: ShaderMaterial
var _crystal: MeshInstance3D
var _crystal_y: float = 4.2
var _lantern: MeshInstance3D


func _setup() -> void:
	kingdom_color = Color(0.45, 0.75, 0.95)
	glow_color = Color(0.75, 0.92, 1.00)
	stone_color = Color(0.40, 0.49, 0.63)
	dark_color = Color(0.27, 0.31, 0.39)
	trim_color = Color(0.70, 0.78, 0.88)
	smoke_color = Color(0.25, 0.28, 0.34)
	blaze_a = Color(0.95, 1.0, 1.0)
	blaze_b = Color(0.45, 0.75, 1.0)
	stain_color = Color(0.85, 0.92, 1.00, 0.40)
	footprint = 4.0
	crack_strength = 0.45
	plinth_top = 0.5
	wreck_top = 1.0
	smoke_points = [Vector3(0.5, 2.7, -0.5)]
	blaze_points = [Vector3(-0.6, 2.4, 0.5)]


func _build_parts() -> void:
	var box1: Mesh = _box(Vector3.ONE)
	var mound: Mesh = IceShapes.mound()
	_m_snow = _painted_mat(Color(0.86, 0.92, 1.0), 0.15, 0.0)
	_m_roof = _painted_mat(kingdom_color.darkened(0.35), 0.45, 0.35)
	_m_roof.set_shader_parameter(&"crack_scale", 1.2)
	_m_roof.set_shader_parameter(&"crack_speed", 0.9)
	_m_team.set_shader_parameter(&"spec_strength", 0.5)
	_m_team.set_shader_parameter(&"crack_strength", 0.9)
	_m_team.set_shader_parameter(&"crack_scale", 1.2)
	_m_team.set_shader_parameter(&"crack_speed", 0.9)
	_m_stone.set_shader_parameter(&"crack_scale", 1.8)
	_m_hole.albedo_color = Color(0.02, 0.03, 0.06)
	_window_mat = _glow_mat(glow_color, 2.4, 1.2, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4402
	# --- Plinth (never collapses): two octagonal dark tiers, a door step and flagstone, snow drifts, ice spikes.
	var it: Array = []
	it.append(_it(IceShapes.prism(2.1, 2.04, 0.32, 8), Vector3.ZERO, _m_dark))
	it.append(_it(IceShapes.prism(1.92, 1.88, 0.18, 8), Vector3(0, 0.32, 0), _m_dark))
	it.append(_it(box1, Vector3(DOOR_X, 0.1, -2.2), _m_dark, Vector3.ZERO, Vector3(1.3, 0.2, 0.5)))
	it.append(_it(box1, Vector3(DOOR_X + 0.05, 0.03, -2.75), _m_dark, Vector3(0, 12, 0), Vector3(0.9, 0.08, 0.55)))
	# Snow banks hugging the plinth (long, low, turned along its edge).
	for d: Vector4 in [Vector4(35.0, 2.05, 0.95, 0.22), Vector4(200.0, 2.05, 0.8, 0.2), Vector4(95.0, 2.0, 1.1, 0.24),
			Vector4(320.0, 2.1, 0.55, 0.16)]:
		var a: float = deg_to_rad(d.x)
		it.append(_itx(mound, Transform3D(Basis(Vector3.UP, -a).scaled_local(Vector3(0.42, d.w, d.z)),
			Vector3(cos(a), 0.0, sin(a)) * d.y), _m_snow))
	it.append(_it(mound, Vector3(-0.95, 0.5, 1.5), _m_snow, Vector3(0, 20, 0), Vector3(0.5, 0.14, 0.28)))
	for cl: Vector2 in [Vector2(145.0, 2.45), Vector2(30.0, 2.4)]:
		for j: int in 2:
			var a: float = deg_to_rad(cl.x) + rng.randf_range(-0.25, 0.25)
			var out := Vector3(cos(a), 0.0, sin(a))
			var sc: float = rng.randf_range(0.8, 1.15) * (1.0 if j == 0 else 0.6)
			var b: Basis = IceShapes.lean(out, rng.randf_range(20.0, 42.0)) * Basis(Vector3.UP, rng.randf() * TAU) \
				* Basis.from_scale(Vector3.ONE * sc)
			it.append(_itx(IceShapes.crystal(0.2, 0.55, 0.45, 0.0), Transform3D(b, out * cl.y + Vector3(0, -0.15, 0)), _m_team))
	var plinth := _merged("Plinth", "plinth", it)
	plinth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # low plinth: no visible shadow of its own
	_no_collapse.append(plinth)
	# --- Walls tier: battered drum, base course, windows, the entrance tunnel and door, banner pole, lantern post,
	# a stack of cut ice blocks at the back-left.
	it = []
	it.append(_it(IceShapes.prism(1.8, 1.8, 0.2, 10), Vector3(0, 0.5, 0), _m_dark))
	it.append(_it(IceShapes.prism(1.72, 1.62, 0.78, 10), Vector3(0, 0.5, 0), _m_stone))
	for a: float in [-38.0, 42.0, 165.0]:
		var d := Vector3(cos(deg_to_rad(a)), 0.0, sin(deg_to_rad(a)))
		var yb := Basis(Vector3.UP, atan2(d.x, d.z))
		it.append(_itx(box1, Transform3D(yb.scaled_local(Vector3(0.5, 0.5, 0.14)), d * 1.64 + Vector3(0, 0.9, 0)), _m_dark))
		it.append(_itx(box1, Transform3D(yb.scaled_local(Vector3(0.44, 0.08, 0.2)), d * 1.7 + Vector3(0, 1.18, 0)), _m_snow))
		it.append(_itx(box1, Transform3D(yb.scaled_local(Vector3(0.28, 0.32, 0.08)), d * 1.69 + Vector3(0, 0.9, 0)),
			_window_mat))
	it.append(_it(box1, Vector3(DOOR_X, 0.59, -1.75), _m_dark, Vector3.ZERO, Vector3(1.6, 0.18, 1.34)))
	it.append(_it(IceShapes.arch(0.72, 0.42, 1.3), Vector3(DOOR_X, 0.5, -1.75), _m_stone))
	it.append(_it(IceShapes.arch(0.6, 0.4, 0.14), Vector3(DOOR_X, 0.5, -2.43), _m_trim))
	it.append(_it(IceShapes.arch(0.46, 0.36, 0.1), Vector3(DOOR_X, 0.5, -2.47), _m_hole))
	it.append(_it(box1, Vector3(DOOR_X, 1.56, -2.45), _window_mat, Vector3(0, 0, 45), Vector3(0.26, 0.26, 0.08)))
	it.append(_it(mound, Vector3(DOOR_X, 1.42, -1.72), _m_snow, Vector3.ZERO, Vector3(0.66, 0.3, 0.72)))
	it.append(_it(IceShapes.icicle_strip(0.95, 5, 0.34, 0.08, 31), Vector3(DOOR_X, 1.66, -2.43), _m_snow))
	# Banner pole (left of the door) with a crystal finial and a crossbar; lantern post (front-right) with its arm.
	it.append(_it(_cyl(0.07, 0.08, 2.6, 6), Vector3(-1.5, 1.8, -1.35), _m_trim))
	it.append(_it(box1, Vector3(-1.5, 2.93, -1.38), _m_trim, Vector3.ZERO, Vector3(0.74, 0.1, 0.1)))
	it.append(_it(IceShapes.crystal(0.13, 0.12, 0.34, 0.1), Vector3(-1.5, 3.12, -1.35), _m_team))
	it.append(_it(box1, Vector3(1.6, 1.5, -1.45), _m_trim, Vector3.ZERO, Vector3(0.18, 2.0, 0.18)))
	it.append(_it(box1, Vector3(1.36, 2.42, -1.45), _m_trim, Vector3.ZERO, Vector3(0.62, 0.14, 0.14)))
	for b: Array in [[Vector3(-1.62, 0.78, 0.72), 12.0], [Vector3(-1.3, 0.78, 1.28), -18.0], [Vector3(-1.48, 1.3, 1.0), 30.0]]:
		it.append(_it(box1, b[0], _m_team, Vector3(0, b[1], 0), Vector3(0.55, 0.52, 0.55)))
	_merged("Walls", "walls", it)
	# --- Dome tier: silver band, four stepped courses of glazed ice blocks (offset like bricks), snow cap, finial,
	# the chimney stack with a snowy cap (the crystal floats above it).
	it = []
	it.append(_it(IceShapes.prism(1.76, 1.74, 0.14, 10), Vector3(0, DOME_Y - 0.06, 0), _m_trim))
	var apo: float = cos(PI / 10.0)
	for k: int in COURSES.size() - 1:
		var t0: float = deg_to_rad(COURSES[k])
		var t1: float = deg_to_rad(COURSES[k + 1])
		var r0: float = DOME_R * cos(t0) - (0.0 if k == 0 else 0.06)
		var r1: float = DOME_R * cos(t1) + 0.04
		var y0: float = DOME_Y + DOME_R * 0.95 * sin(t0)
		var y1: float = DOME_Y + DOME_R * 0.95 * sin(t1)
		it.append(_itx(IceShapes.prism(r0 * apo, r1 * apo, y1 - y0, 10),
			Transform3D(Basis(Vector3.UP, deg_to_rad(18.0 * k)), Vector3(0, y0, 0)), _m_roof))
		if k < COURSES.size() - 2:   # a snow ledge on each course joint (the igloo's rings from above)
			it.append(_itx(IceShapes.prism(r1 * apo + 0.05, r1 * apo - 0.02, 0.09, 10),
				Transform3D(Basis(Vector3.UP, deg_to_rad(18.0 * k)), Vector3(0, y1 - 0.03, 0)), _m_snow))
	var top_y: float = DOME_Y + DOME_R * 0.95 * sin(deg_to_rad(COURSES[COURSES.size() - 1]))
	it.append(_it(mound, Vector3(0, top_y - 0.04, 0), _m_snow, Vector3.ZERO, Vector3(0.62, 0.3, 0.62)))
	it.append(_it(IceShapes.crystal(0.15, 0.12, 0.42, 0.0), Vector3(0, top_y + 0.2, 0), _m_team, Vector3(0, 30, 0)))
	var cb := Basis(Vector3.UP, 0.35)
	it.append(_itx(IceShapes.prism(0.36, 0.3, 1.75, 4), Transform3D(cb, CHIM + Vector3(0, 1.85, 0)), _m_stone))
	it.append(_itx(IceShapes.prism(0.46, 0.46, 0.2, 4), Transform3D(cb, CHIM + Vector3(0, 3.58, 0)), _m_dark))
	it.append(_itx(IceShapes.prism(0.44, 0.36, 0.1, 4), Transform3D(cb, CHIM + Vector3(0, 3.78, 0)), _m_snow))
	var dome := _merged("Dome", "dome", it)
	# --- Floating chimney crystal (team glow), the lantern (lost under 50 %), the banner.
	_crystal = _part("ChimneyCrystal", IceShapes.crystal(0.3, 0.5, 0.6, 0.45), _glow_mat(glow_color, 2.8, 1.4, true),
		CHIM + Vector3(0, _crystal_y, 0))
	_floaters.append(_crystal)
	it = []
	it.append(_it(box1, Vector3(1.14, 2.07, -1.45), _window_mat, Vector3.ZERO, Vector3(0.34, 0.4, 0.34)))
	it.append(_it(box1, Vector3(1.14, 1.84, -1.45), _m_dark, Vector3.ZERO, Vector3(0.4, 0.07, 0.4)))
	it.append(_it(_cyl(0.0, 0.3, 0.26, 4), Vector3(1.14, 2.4, -1.45), _m_dark, Vector3(0, 45, 0)))
	_lantern = _merged("Lantern", "lantern", it)
	_lantern.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_banner_mat = IceShapes.banner_material(kingdom_color)
	var banner := _part("Banner", IceShapes.banner_mesh(Vector2(0.6, 1.35)), _banner_mat, Vector3(-1.5, 2.2, -1.43))
	banner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	banner.set_instance_shader_parameter(&"phase", randf() * TAU)
	_hide_on_collapse.append_array([dome, _lantern, banner])
	# Damage: a caved-in patch on the front-left of the dome (< 50 %), a glowing breach on the right (< 25 %).
	_show_below_50.append(_roof_patch("DomeHoleF", dome, _dome_xf(215.0, 40.0), 0.75))
	_show_below_25.append(_roof_patch("DomeHoleR", dome, _dome_xf(345.0, 28.0), 0.65, _window_mat))
	_build_scaffold(4.0, 3.0, [1.3, 2.5] as Array[float])
	_build_wreck(1.45, 1.0, _window_mat, 4041)
	# Idle particles (16): cold vapour from the chimney, frost sparkles around the crystal.
	var va := _pm(Vector3.UP, 12.0, 0.5, 0.8, Vector3(0.2, 0.05, 0.0), 0.35, 1.2,
		_ramp(Color(0.85, 0.92, 1.0, 0.35), Color(0.85, 0.92, 1.0, 0.0), false))
	_idle_particles("ChimneyVapour", CHIM + Vector3(0, 3.8, 0), 8, 2.6, va, false)
	var sp := _pm(Vector3.UP, 180.0, 0.2, 0.5, Vector3(0, -0.2, 0), 0.09, 0.03,
		_ramp(Color(0.9, 0.97, 1.0), Color(0.55, 0.8, 1.0), false))
	sp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.5
	_idle_particles("CrystalSparkles", CHIM + Vector3(0, _crystal_y + 0.3, 0), 8, 1.4, sp, true)


## Transform on the dome surface at azimuth `az` / elevation `el` (degrees; azimuth 0 = +X, 90 = +Z): +Y out of the
## dome, X horizontal along it.
func _dome_xf(az: float, el: float) -> Transform3D:
	var a: float = deg_to_rad(az)
	var e: float = deg_to_rad(el)
	var n := Vector3(cos(e) * cos(a), sin(e), cos(e) * sin(a))
	var x: Vector3 = Vector3.UP.cross(n).normalized()
	var pos := Vector3(n.x * DOME_R, DOME_Y + n.y * DOME_R * 0.95, n.z * DOME_R)
	return Transform3D(Basis(x, n, x.cross(n)), pos + n * 0.04)


## Frost patch (ice_frost_ground.gdshader) instead of the plain stain, on a 7 m quad.
func _build_ground() -> void:
	super()
	var pm := PlaneMesh.new()
	pm.size = Vector2(7.0, 7.0)
	_decal.mesh = pm
	_frost_mat = ShaderMaterial.new()
	_frost_mat.shader = FROST_GROUND
	_frost_mat.set_shader_parameter(&"size", 7.0)
	_frost_mat.set_shader_parameter(&"plinth_half", 2.15)
	_frost_mat.set_shader_parameter(&"roundness", 1.0)
	_frost_mat.set_shader_parameter(&"sectors", 12.0)
	_frost_mat.set_shader_parameter(&"seed", 2.7)
	_frost_mat.set_shader_parameter(&"glow_color", glow_color)
	_decal.material_override = _frost_mat


func _idle(_delta: float) -> void:
	_crystal.position.y = CHIM.y + _crystal_y + 0.1 * sin(_t * 1.9)
	_crystal.rotation.y = _t * 0.8


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	# Below 50 % the lantern is knocked off its post; below 25 % the windows go dark.
	if _progress >= 1.0:
		_lantern.visible = not smoke_on
	_window_mat.set_shader_parameter(&"energy", 0.5 if fire_on else 2.4)
	if _frost_mat:
		_frost_mat.set_shader_parameter(&"damage", 1.0 if fire_on else (0.5 if smoke_on else 0.0))


func _on_team_color(g: Color) -> void:
	IceShapes.tint_banner(_banner_mat, _team_color, kingdom_color, g)
	_m_roof.set_shader_parameter(&"base_color", _team_color.darkened(0.35))


## The keep's cold idle rim instead of the base one (selection still turns it to the team colour).
func _apply_rim_and_glow() -> void:
	super()
	if _ready_done and _body != null:
		IceShapes.apply_ice_rim(_painted, _team_color, _sel_k, _progress < 1.0 and not _destroyed)
