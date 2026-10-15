class_name EmberSpireModel
extends SmallBuildingModel
## Fire tower "Ember Spire" (buildings.md: 1 x 1 cell = 2 x 2 m, height 5, orb blinks on each shot). Task 5.V2.
## Read from the RTS camera: a tapering eight-sided stone shaft with lava cracks, a flared team-coloured cup,
## four bronze claws holding a glowing ember orb, and an obsidian shard leaning on the shaft (the asymmetric
## secondary). No real light (B5, art-keep 0.4): a fake glow halo (additive billboard) around the orb. A.9: stepped plinth, four dark buttress fins at the
## foot, two bronze bands, three slits; scaffolding while built, a broken stump with embers after the collapse.
## Extra hook for towers: play_shot() (the Tower script calls it each time it fires): the orb blinks 0.1 s.
## NightSpireModel (shadow_tower.gd) extends this and only changes the palette and the parts.

const SHOT_HOLD := 0.1
const SHOT_FADE := 0.18

var _orb: MeshInstance3D
var _orb_mat: ShaderMaterial
var _halo: MeshInstance3D
var _halo_size: float = 1.7
var _orb_y: float = 4.5
static var _halo_cache: Dictionary = {}
var _crown: MultiMeshInstance3D
var _shot_left: float = 0.0
var _flicker_amp: float = 0.08
var _orb_energy: float = 3.2


func _setup() -> void:
	kingdom_color = Color(0.85, 0.30, 0.12)
	glow_color = Color(1.0, 0.55, 0.15)
	stone_color = Color(0.30, 0.26, 0.24)
	dark_color = Color(0.12, 0.10, 0.10)
	trim_color = Color(0.62, 0.40, 0.16)
	smoke_color = Color(0.16, 0.14, 0.13)
	stain_color = Color(0.22, 0.07, 0.02, 0.35)
	footprint = 2.0
	crack_strength = 0.9
	vc_merge = true   # B8: one vertex-coloured painted material (PaintedVC)
	plinth_top = 0.4
	wreck_top = 1.25
	smoke_points = [Vector3(0.3, 2.6, 0.3)]
	blaze_points = [Vector3(-0.25, 3.3, -0.2)]


## A.9: merged tiers (Plinth, Shaft with fins / bands / slits / shard, Cup), claws stay a MultiMesh (_crown).
func _build_parts() -> void:
	var box1: Mesh = _box(Vector3.ONE)
	var oct := Basis(Vector3.UP, PI / 8.0)
	if _gb_fire():
		_m_wood = _painted_mat(Color(0.36, 0.22, 0.12), 0.0, 0.0)   # G-B: timber scaffold
	var slit_mat: ShaderMaterial = _glow_mat(glow_color, 2.2, 1.5, false)
	var ember_mat: ShaderMaterial = _glow_mat(glow_color, 2.4, 2.0, false)
	var it: Array = []
	# 2026-09-30 (Art Lab C1): the slab became a battered block (sloped sides catch the light from four more angles).
	it.append(_itx(_cyl(1.47, 1.66, 0.4, 4), Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(0, 0.2, 0)), _m_dark))
	it.append(_itx(_cyl(1.0, 1.08, 0.24, 8), Transform3D(oct, Vector3(0, 0.52, 0)), _m_dark))
	# 2026-09-30 detail pass (Art Lab C1 / C2 / P2: a plain shaft on a slab): a ring of fallen / set stones round the
	# plinth in two shades, two smaller obsidian splinters beside the big shard (vc_merge: shades are free).
	var drng := RandomNumberGenerator.new()
	drng.seed = 2402
	var st_a: ShaderMaterial = _painted_mat(stone_color.lightened(0.12), 0.0, 0.0)
	var st_b: ShaderMaterial = _painted_mat(dark_color.lightened(0.12), 0.1, 0.0)
	var st_c: ShaderMaterial = _painted_mat(stone_color.lightened(0.24), 0.0, crack_strength * 0.5)
	for k: int in 10:
		var a: float = TAU * float(k) / 10.0 + drng.randf_range(-0.15, 0.15)
		var r: float = drng.randf_range(0.98, 1.1)
		var sz := Vector3(drng.randf_range(0.26, 0.4), drng.randf_range(0.12, 0.2), drng.randf_range(0.2, 0.3))
		it.append(_it(box1, Vector3(sin(a) * r, 0.4 + sz.y * 0.5, cos(a) * r), st_a if k % 2 == 0 else st_b,
			Vector3(drng.randf_range(-8, 8), rad_to_deg(a) + drng.randf_range(-15, 15), drng.randf_range(-8, 8)), sz))
	_no_collapse.append(_merged("Plinth", "plinth", it))
	# Shaft tier: tapering octagonal stone shaft, two bronze bands, four dark buttress fins at the foot, three
	# glowing slits, the obsidian shard leaning on the front-left (asymmetric secondary).
	it = []
	# 2026-09-30 (Art Lab C1: eight faces gave too few light directions): the shaft, bands and cup are 12-sided.
	it.append(_itx(_cyl(0.55, 0.85, 3.0, 12), Transform3D(oct, Vector3(0, 1.9, 0)), _m_stone))
	it.append(_itx(_cyl(0.78, 0.8, 0.22, 12), Transform3D(oct, Vector3(0, 1.55, 0)), _m_trim))
	it.append(_itx(_cyl(0.64, 0.66, 0.2, 12), Transform3D(oct, Vector3(0, 3.1, 0)), _m_trim))
	for i: int in 4:
		var a: float = PI * 0.25 + PI * 0.5 * i
		var d := Vector3(sin(a), 0.0, cos(a))
		it.append(_itx(_prism(Vector3(0.75, 1.3, 0.3), 0.0), Transform3D(Basis(Vector3.UP, a - PI * 0.5),
			d * 1.02 + Vector3(0, 1.05, 0)), _m_dark))
	for s: Array in [[Vector3(0, 2.55, -0.64), 0.0], [Vector3(0.64, 2.55, 0), 90.0], [Vector3(-0.64, 2.55, 0), 90.0]]:
		it.append(_it(box1, s[0], slit_mat, Vector3(0, s[1], 0), Vector3(0.14, 0.6, 0.08)))
	var sb: Basis = _lean(Vector3(-1, 0, -0.4), 22.0)
	it.append(_itx(_cyl(0.0, 0.3, 1.9, 5), Transform3D(sb, Vector3(-0.72, 0.4, -0.3) + sb * Vector3(0, 0.95, 0)), _m_dark))
	for sh: Array in [[Vector3(-0.95, 0.4, 0.2), Vector3(-1, 0, 0.5), 30.0, 0.9, 0.17], [Vector3(-0.45, 0.4, -0.85),
			Vector3(-0.3, 0, -1), 26.0, 0.75, 0.14]]:
		var sb2: Basis = _lean(sh[1], sh[2])
		it.append(_itx(_cyl(0.0, sh[4], sh[3], 5), Transform3D(sb2, sh[0] + sb2 * Vector3(0, sh[3] * 0.5, 0)), st_b))
	# Rivets round both bronze bands (12 each).
	for band: Vector2 in [Vector2(1.55, 0.8), Vector2(3.1, 0.66)]:
		for k: int in 12:
			var ra: float = TAU * (float(k) + 0.5) / 12.0
			var rd := Vector3(sin(ra), 0.0, cos(ra))
			it.append(_itx(_cyl(0.035, 0.05, 0.05, 6), Transform3D(Basis(rd.cross(Vector3.UP).normalized(), PI * 0.5),
				rd * (band.y + 0.01) + Vector3(0, band.x, 0)), st_b))
	# Masonry courses: three rings of proud blocks round the tapering shaft, alternately set, two shades.
	for ring: int in 3:
		var y: float = 0.95 + 0.62 * float(ring) + (0.0 if ring < 2 else 0.7)
		var rad: float = lerpf(0.85, 0.55, (y - 0.4) / 3.0)
		for k: int in 8:
			var a2: float = PI / 8.0 + TAU * float(k) / 8.0 + (PI / 8.0 if ring % 2 == 1 else 0.0)
			var d2 := Vector3(sin(a2), 0.0, cos(a2))
			it.append(_itx(box1, Transform3D(Basis(Vector3.UP, a2) * Basis(Vector3.RIGHT, deg_to_rad(drng.randf_range(-4, 4)))
				.scaled_local(Vector3(rad * 0.62, 0.24, 0.16)), d2 * (rad * 0.99) + Vector3(0, y, 0)), st_a if (k + ring) % 2 == 0 else st_c))
	_merged("Shaft", "shaft", it)
	# Cup tier: the flared team cup and its bronze rim.
	it = []
	it.append(_itx(_cyl(1.0, 0.6, 0.55, 12), Transform3D(oct, Vector3(0, 3.67, 0)), _m_team))
	it.append(_itx(_cyl(1.06, 1.06, 0.16, 12), Transform3D(oct, Vector3(0, 4.0, 0)), _m_trim))
	# Detail pass: bronze thorns on the rim between the claws, a darker band under the cup.
	for k: int in 8:
		var a3: float = TAU * float(k) / 8.0
		var d3 := Vector3(sin(a3), 0.0, cos(a3))
		var tb: Basis = _lean(d3, 30.0)
		it.append(_itx(_cyl(0.0, 0.07, 0.34, 4), Transform3D(tb, d3 * 1.02 + Vector3(0, 4.08, 0) + tb * Vector3(0, 0.17, 0)), _m_trim))
	it.append(_itx(_cyl(0.66, 0.62, 0.12, 12), Transform3D(oct, Vector3(0, 3.36, 0)), st_b))
	# A team war-cloth hung from the rim on the +X side (asymmetric secondary, top-facing team colour), notched hem.
	# Hung on the front-left rim over the obsidian splinters (one heavy side: the asymmetric read), turned to the
	# diagonal so both cameras and the front see it.
	var cy: Basis = Basis(Vector3.UP, deg_to_rad(45.0))
	var cl: Basis = cy * Basis(Vector3.RIGHT, deg_to_rad(8.0))
	var cp := Vector3(-0.78, 3.5, -0.78)
	it.append(_itx(box1, Transform3D(cl.scaled_local(Vector3(0.62, 0.95, 0.06)), cp), _m_team))
	for hs: float in [-1.0, 1.0]:
		it.append(_itx(_prism(Vector3(0.31, 0.3, 0.06), 0.5), Transform3D(cl * Basis(Vector3.BACK, PI),
			cp + cl * Vector3(hs * 0.155, -0.6, 0.0)), _m_team))
	it.append(_itx(box1, Transform3D(cy.scaled_local(Vector3(0.74, 0.08, 0.14)), cp + Vector3(0, 0.49, 0.0)), _m_trim))
	var cup := _merged("Cup", "cup", it)
	_build_scaffold(2.3, 4.3, [2.0, 3.7] as Array[float])
	_build_wreck(0.72, 1.3, ember_mat, 2021, 4)
	# Four claws leaning out 14 deg around the orb (one draw call).
	var cx: Array[Transform3D] = []
	for i: int in 4:
		var a: float = PI * 0.25 + PI * 0.5 * i
		var dir := Vector3(sin(a), 0.0, cos(a))
		var b: Basis = _lean(dir, 14.0)
		cx.append(Transform3D(b, dir * 0.72 + Vector3(0, 4.05, 0) + b * Vector3(0, 0.55, 0)))
	_crown = _multi("Claws", _cyl(0.0, 0.15, 1.1, 4), _m_trim, cx)
	_build_orb(0.34, 3.2)
	_hide_on_collapse.append_array([cup, _crown])
	var em := _pm(Vector3.UP, 30.0, 0.5, 1.1, Vector3(0, 0.2, 0), 0.08, 0.04,
		_ramp(Color(1.0, 0.7, 0.25), Color(1.0, 0.4, 0.1), false))
	em.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	em.emission_sphere_radius = 0.35
	_idle_particles("OrbEmbers", Vector3(0, _orb_y, 0), 10, 1.4, em, true)


## The orb (team glow) and its fake-light halo, shared by both towers.
func _build_orb(radius: float, energy: float) -> void:
	_orb_energy = energy
	_orb_mat = _glow_mat(glow_color, energy, 3.0, true)
	_orb = _part("Orb", _sphere(radius), _orb_mat, Vector3(0, _orb_y, 0))
	_floaters.append(_orb)
	# Fake glow instead of an OmniLight: a soft additive halo billboard (one shared quad, one material per colour).
	_halo = MeshInstance3D.new()
	_halo.name = "OrbHalo"
	_halo.mesh = _halo_quad()
	_halo.material_override = _halo_mat(glow_color)
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.position = Vector3(0, _orb_y, 0)
	_halo.scale = Vector3.ONE * _halo_size
	add_child(_halo)


static func _halo_quad() -> QuadMesh:
	if _halo_cache.has(&"quad"):
		return _halo_cache[&"quad"]
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	_halo_cache[&"quad"] = q
	return q


## Additive radial halo, kept faint (alpha 0.45) so it reads as light spill around the orb, not as a glow point.
static func _halo_mat(c: Color) -> StandardMaterial3D:
	if _halo_cache.has(c):
		return _halo_cache[c]
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.45))
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
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = tex
	m.albedo_color = Color(c.r, c.g, c.b, 0.45)
	_halo_cache[c] = m
	return m


# --- Tower hook ---

## The tower fired: the orb blinks (boost x3.5, +30 % size, light x3) for 0.1 s, then fades in 0.18 s.
func play_shot() -> void:
	if _destroyed or _progress < 1.0:
		return
	_shot_left = SHOT_HOLD + SHOT_FADE


# --- Overrides ---

## G-B Fire: the Ember Spire itself (NightSpireModel extends this script and keeps its own look).
func _gb_fire() -> bool:
	return (get_script() as Script).resource_path == "res://art/buildings/fire_tower.gd"


func _idle(delta: float) -> void:
	_orb.position.y = _orb_y + 0.08 * sin(_t * 2.2)
	var k: float = 0.0
	if _shot_left > 0.0:
		_shot_left = maxf(_shot_left - delta, 0.0)
		k = 1.0 if _shot_left > SHOT_FADE else _shot_left / SHOT_FADE
		_orb_mat.set_shader_parameter(&"boost", _sel_boost() * (1.0 + 2.5 * k))
		if _shot_left <= 0.0:
			_orb_mat.set_shader_parameter(&"boost", _sel_boost())
	if _float_appear >= 1.0:
		_orb.scale = Vector3.ONE * (1.0 + 0.3 * k)
	var n: float = sin(_t * 7.3) * 0.5 + sin(_t * 12.1) * 0.5
	_halo.position.y = _orb.position.y
	_halo.scale = Vector3.ONE * _halo_size * (1.0 - _flicker_amp + _flicker_amp * n) * (1.0 + 0.8 * k)
	_crown_idle(delta)


func _crown_idle(_delta: float) -> void:
	pass


func _on_progress(building: bool) -> void:
	_halo.visible = not building


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	# Below 50 % one claw breaks off; below 25 % the orb dims and its halo gutters.
	_crown.multimesh.visible_instance_count = _crown.multimesh.instance_count - 1 if smoke_on else -1
	_orb_mat.set_shader_parameter(&"energy", _orb_energy * 0.55 if fire_on else _orb_energy)
	_flicker_amp = 0.35 if fire_on else 0.08


func _on_team_color(g: Color) -> void:
	_halo.material_override = _halo_mat(g)


func _on_destroy_start() -> void:
	_shot_left = 0.0


func _on_destroy(t: float) -> void:
	# A last flare of the halo, then it shrinks out.
	_halo.scale = Vector3.ONE * _halo_size * (2.0 if t < 0.2 else clampf(1.0 - (t - 0.2) / 0.6, 0.0, 1.0))
	_halo.visible = t < 0.8
