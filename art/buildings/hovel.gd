class_name HovelModel
extends SmallBuildingModel
## Shadow house "Hovel" (buildings.md: 2 x 2 cells = 4 x 4 m, +10 pop). Task 5.V2, polished in A.9.
## Read from the RTS camera: a six-sided half-timbered hut under a crooked witch-hat roof in the team colour whose
## tip bends toward +x and ends in a glowing shard; a tall silver lantern post at the front-right corner (the
## asymmetric secondary) with a bobbing soul orb; two purple slits frame the pointed door (-Z); a bubbling cauldron
## and a fence of bone stakes at the front-left, a crooked silver stovepipe at the back.
## Hooks: see SmallBuildingModel. Tiers are merged meshes (Plinth, Walls, Roof).
## States: scaffolding while built, < 50 % HP the tip shard goes dark + a caved-in roof patch, < 25 % the orb
## gutters out + a burning hole, a wreck of broken walls and purple embers after the collapse.

const HEX := PI / 6.0  # rotate hexagons so a flat face looks at -Z
const ROOF := Vector4(2.55, 1.05, 2.78, 1.3)  # witch-hat frustum: bottom r, top r, bottom y, height

var _orb: MeshInstance3D
var _tip_glow: MeshInstance3D
var _orb_y: float = 4.45
var _brew_mat: ShaderMaterial
const TEAM_DARK := 0.74   ## G-B: the darker shingle courses = team colour x this (unmerged material and merged multiplier)

var _m_team_dark: ShaderMaterial   ## G-B: the darker shingle courses (team colour x TEAM_DARK)
var _m_bone: ShaderMaterial
var _dress: ShadowDress


func _setup() -> void:
	kingdom_color = Color(0.42, 0.22, 0.60)
	glow_color = Color(0.70, 0.30, 1.00)
	stone_color = Color(0.20, 0.17, 0.26)
	dark_color = Color(0.10, 0.08, 0.14)
	trim_color = Color(0.3, 0.28, 0.37)   # G-B: dark iron (was 0.55 0.52 0.66: read as white sticks)
	smoke_color = Color(0.12, 0.09, 0.16)
	blaze_a = Color(0.85, 0.55, 1.0)
	blaze_b = Color(0.45, 0.15, 0.75)
	stain_color = Color(0.15, 0.06, 0.25, 0.35)
	footprint = 4.0
	crack_strength = 0.5
	plinth_top = 0.45
	wreck_top = 1.15
	smoke_points = [Vector3(-1.1, 3.4, -1.0)]
	blaze_points = [Vector3(1.2, 3.5, 0.75)]
	# B8 (in-game grade 2026-09-30, 13 -> 8 materials): every painted part draws with ONE vertex-coloured material
	# and the purple glows with one glow material (SmallBuildingModel vc_merge, art/buildings/painted_vc.gd).
	vc_merge = true


func _build_parts() -> void:
	var box1: Mesh = _box(Vector3.ONE)
	var hexb := Basis(Vector3.UP, HEX)
	var slit_mat: ShaderMaterial = _glow_mat(glow_color, 2.5, 1.0, false)
	_brew_mat = _glow_mat(glow_color, 2.8, 2.6, true)
	_m_team_dark = _painted_mat(kingdom_color.darkened(1.0 - TEAM_DARK), 0.1, 0.0)
	_m_bone = _painted_mat(Color(0.7, 0.66, 0.58), 0.12, 0.0)
	var win_mat: ShaderMaterial = _glow_mat(glow_color, 1.5, 0.8, false)   # dim lit windows (under the bloom)
	# Plinth (never collapses): hex slab and a door step.
	var it: Array = []
	it.append(_itx(_cyl(2.3, 2.3, 0.45, 6), Transform3D(hexb, Vector3(0, 0.225, 0)), _m_dark))
	it.append(_it(box1, Vector3(0, 0.12, -2.25), _m_dark, Vector3.ZERO, Vector3(1.3, 0.24, 0.5)))
	# G-B: rough-cut foundation stones round the plinth edge (two shades), cracked flags on the door path.
	var grng := RandomNumberGenerator.new()
	grng.seed = 4407
	for k: int in 12:
		var a: float = TAU * (float(k) + 0.5) / 12.0
		if absf(wrapf(a - PI, -PI, PI)) < 0.5:
			continue   # the door
		var s := Vector3(grng.randf_range(0.55, 0.85), grng.randf_range(0.22, 0.34), grng.randf_range(0.35, 0.5))
		it.append(_it(box1, Vector3(sin(a) * 2.18, s.y * 0.5 + 0.3, cos(a) * 2.18), _m_stone if k % 2 == 0 else _m_dark,
			Vector3(grng.randf_range(-6, 6), rad_to_deg(a) + grng.randf_range(-8, 8), grng.randf_range(-5, 5)), s))
	for k: int in 2:
		it.append(_it(box1, Vector3(grng.randf_range(-0.15, 0.15), 0.03, -2.6 - 0.5 * k), _m_stone,
			Vector3(0, grng.randf_range(-18, 18), 0), Vector3(grng.randf_range(0.55, 0.75), 0.06, 0.42)))
	_no_collapse.append(_merged("Plinth", "plinth", it))
	# Walls tier: stone hex body, dark base ring, timber posts on the corners, pointed door, slits, stakes, cauldron.
	it = []
	it.append(_itx(_cyl(1.75, 1.8, 2.15, 6), Transform3D(hexb, Vector3(0, 1.52, 0)), _m_stone))
	it.append(_itx(_cyl(1.92, 1.97, 0.32, 6), Transform3D(hexb, Vector3(0, 0.6, 0)), _m_dark))
	for k: int in 6:
		var a: float = HEX + PI / 3.0 * k
		it.append(_itx(box1, Transform3D(Basis(Vector3.UP, a).scaled_local(Vector3(0.26, 2.1, 0.26)),
			Vector3(sin(a) * 1.8, 1.6, cos(a) * 1.8)), _m_dark))
	it.append(_it(box1, Vector3(0, 1.17, -1.5), _m_hole, Vector3.ZERO, Vector3(0.9, 1.45, 0.12)))
	it.append(_it(_cyl(0.0, 0.64, 0.5, 4), Vector3(0, 2.14, -1.42), _m_hole, Vector3(0, 45, 0), Vector3(1.0, 1.0, 0.2)))
	for x: float in [-0.62, 0.62]:
		it.append(_it(box1, Vector3(x, 1.3, -1.56), slit_mat, Vector3.ZERO, Vector3(0.09, 1.5, 0.08)))
	# G-B: a horned skull over the door, four lit lancet windows (dark iron frames, a dim soul glow behind a mullion).
	it.append(_it(_sphere(0.17), Vector3(0, 2.38, -1.6), _m_bone, Vector3.ZERO, Vector3(1.0, 0.9, 0.8)))
	it.append(_it(box1, Vector3(0, 2.24, -1.66), _m_bone, Vector3.ZERO, Vector3(0.18, 0.12, 0.12)))
	for sx: float in [-1.0, 1.0]:
		var hb: Basis = Basis(Vector3.FORWARD, sx * deg_to_rad(-55.0)) * Basis(Vector3.RIGHT, deg_to_rad(-20.0))
		it.append(_itx(_cyl(0.0, 0.07, 0.5, 4), Transform3D(hb, Vector3(sx * 0.26, 2.5, -1.62) + hb * Vector3(0, 0.2, 0)), _m_bone))
	for k: int in [1, 2, 4, 5]:
		var a: float = PI / 3.0 * float(k)
		var d := Vector3(sin(a), 0.0, cos(a))
		var wb := Basis(Vector3.UP, a)
		var wp: Vector3 = d * 1.5 + Vector3(0, 1.75, 0)
		it.append(_itx(box1, Transform3D(wb.scaled_local(Vector3(0.5, 0.85, 0.1)), wp + d * 0.02), _m_dark))
		it.append(_itx(_cyl(0.0, 0.36, 0.32, 4), Transform3D(wb * Basis(Vector3.UP, PI * 0.25).scaled_local(Vector3(1.0, 1.0, 0.25)),
			wp + d * 0.02 + Vector3(0, 0.57, 0)), _m_dark))
		it.append(_itx(box1, Transform3D(wb.scaled_local(Vector3(0.32, 0.62, 0.06)), wp + d * 0.07), win_mat))
		it.append(_itx(box1, Transform3D(wb.scaled_local(Vector3(0.05, 0.66, 0.06)), wp + d * 0.1), _m_trim))
	# Bone stakes (front-left), leaning out, and a bubbling cauldron beside the door.
	for k: int in 4:
		var a: float = PI * 1.12 + 0.3 * k
		var d := Vector3(sin(a), 0.0, cos(a))
		var b: Basis = _lean(d, 16.0 + 5.0 * (k % 2))
		it.append(_itx(_cyl(0.0, 0.14, 1.1 + 0.2 * (k % 2), 4), Transform3D(b, d * 2.12 + Vector3(0, 0.45, 0)
			+ b * Vector3(0, 0.55, 0)), _m_bone))
	it.append(_it(_cyl(0.42, 0.3, 0.55, 8), Vector3(-1.25, 0.72, -1.75), _m_dark))
	it.append(_it(_cyl(0.36, 0.36, 0.06, 8), Vector3(-1.25, 0.98, -1.75), _brew_mat))
	for x: float in [-1.55, -0.95]:
		it.append(_it(box1, Vector3(x, 0.55, -1.75), _m_dark, Vector3(0, 0, (x + 1.25) * 60.0), Vector3(0.12, 0.3, 0.12)))
	# Lantern post at the front-right corner: silver pole and crooked arm (the orb floats, own node).
	it.append(_it(_cyl(0.09, 0.14, 3.7, 6), Vector3(1.95, 2.3, -1.5), _m_trim))
	it.append(_it(box1, Vector3(1.7, 4.05, -1.5), _m_trim, Vector3(0, 0, 12), Vector3(0.75, 0.12, 0.12)))
	_merged("Walls", "walls", it)
	# Roof tier: silver band, witch-hat frustum + silver ring course + hip ridges, the bent tip, a stovepipe.
	it = []
	it.append(_itx(_cyl(2.0, 2.0, 0.24, 6), Transform3D(hexb, Vector3(0, 2.66, 0)), _m_trim))
	# G-B: the witch hat is four stepped shingle courses (team / darker team, each lipped over the one below) round a
	# dark core, so the roof reads as slate from the RTS camera instead of one flat purple cone.
	it.append(_itx(_cyl(ROOF.y - 0.05, ROOF.x - 0.12, ROOF.w, 6), Transform3D(hexb, Vector3(0, ROOF.z + ROOF.w * 0.5, 0)),
		_m_team_dark))
	for k: int in 4:
		var t0: float = float(k) / 4.0
		var t1: float = minf(float(k + 1) / 4.0 + 0.07, 1.0)
		var r0: float = lerpf(ROOF.x, ROOF.y, t0) + 0.13
		var r1: float = lerpf(ROOF.x, ROOF.y, t1)
		var hk: float = ROOF.w * (t1 - t0)
		it.append(_itx(_cyl(r1, r0, hk, 6), Transform3D(hexb, Vector3(0, ROOF.z + ROOF.w * t0 + hk * 0.5, 0)),
			_m_team if k % 2 == 0 else _m_team_dark))
	it.append(_itx(_cyl(1.86, 1.94, 0.14, 6), Transform3D(hexb, Vector3(0, ROOF.z + ROOF.w * 0.45, 0)), _m_trim))
	for k: int in 6:
		var a: float = HEX + PI / 3.0 * k
		var d := Vector3(sin(a), 0.0, cos(a))
		var p0: Vector3 = d * 2.6 + Vector3(0, 2.78, 0)
		var p1: Vector3 = d * 1.08 + Vector3(0, 4.08, 0)
		var e: Vector3 = p1 - p0
		it.append(_itx(box1, Transform3D(Basis(Quaternion(Vector3.UP, e.normalized())).scaled_local(
			Vector3(0.2, e.length(), 0.2)), (p0 + p1) * 0.5), _m_trim))
	var bend := Basis(Vector3.BACK, deg_to_rad(-24.0)) * hexb
	var up: Vector3 = bend * Vector3.UP
	var base := Vector3(0, 4.06, 0)
	it.append(_itx(_cyl(0.0, 1.05, 2.1, 6), Transform3D(bend, base + up * 1.05), _m_team))
	it.append(_itx(_cyl(1.1, 1.1, 0.14, 6), Transform3D(bend, base + up * 0.12), _m_trim))
	# G-B: two darker shingle bands up the bent tip, iron spikes on the six eave corners, a hooked iron finial.
	it.append(_itx(_cyl(0.72, 0.92, 0.32, 6), Transform3D(bend, base + up * 0.42), _m_team_dark))
	it.append(_itx(_cyl(0.36, 0.52, 0.26, 6), Transform3D(bend, base + up * 1.18), _m_team_dark))
	for k: int in 6:
		var a: float = HEX + PI / 3.0 * k
		var d := Vector3(sin(a), 0.0, cos(a))
		var sb: Basis = Basis(Quaternion(Vector3.UP, (d + Vector3(0, 0.55, 0)).normalized()))
		it.append(_itx(_cyl(0.0, 0.085, 0.55, 4), Transform3D(sb, d * 2.72 + Vector3(0, 2.86, 0) + sb * Vector3(0, 0.25, 0)),
			_m_trim))
	it.append(_itx(_cyl(2.66, 2.7, 0.09, 6), Transform3D(hexb, Vector3(0, 2.8, 0)), _m_dark))
	# Crooked stovepipe through the back-left of the roof, with a cap.
	var pb: Basis = _lean(Vector3(-0.6, 0, 1), 10.0)
	it.append(_itx(_cyl(0.16, 0.16, 1.6, 6), Transform3D(pb, Vector3(-1.05, 3.6, 0.95)), _m_trim))
	it.append(_itx(_cyl(0.3, 0.2, 0.2, 6), Transform3D(pb, Vector3(-1.05, 3.6, 0.95) + pb * Vector3(0, 0.86, 0)), _m_dark))
	# G-B: two little dormers with a lit window on the hat (front over the door, back-left), visible from above.
	for a: float in [PI, PI * 5.0 / 3.0]:
		var fx: Transform3D = _face_xf(a, 0.0)
		var d := Vector3(sin(a), 0.0, cos(a))
		var p: Vector3 = fx.origin - Vector3(0, 0.12, 0)
		var db := Basis(Vector3.UP, a)
		it.append(_itx(box1, Transform3D(db.scaled_local(Vector3(0.56, 0.62, 0.62)), p + Vector3(0, 0.18, 0)), _m_dark))
		it.append(_itx(_cyl(0.0, 0.46, 0.42, 4), Transform3D(db * Basis(Vector3.UP, PI * 0.25), p + Vector3(0, 0.69, 0)),
			_m_team_dark))
		it.append(_itx(box1, Transform3D(db.scaled_local(Vector3(0.26, 0.34, 0.05)), p + d * 0.31 + Vector3(0, 0.2, 0)), win_mat))
	var roof := _merged("Roof", "roof", it)
	_tip_glow = _part("TipShard", _cyl(0.0, 0.2, 0.55, 4), _glow_mat(glow_color, 3.0, 2.0, true),
		base + up * 2.05, bend)
	_orb = _part("LanternOrb", _sphere(0.26), _glow_mat(glow_color, 3.2, 2.0, true), Vector3(1.45, _orb_y, -1.5))
	_floaters.append(_orb)
	_hide_on_collapse.append_array([roof, _tip_glow])
	_show_below_50.append(_roof_patch("RoofHoleF", roof, _face_xf(PI * 4.0 / 3.0, 0.0), 0.75))
	_show_below_25.append(_roof_patch("RoofHoleR", roof, _face_xf(PI / 3.0, 0.1), 0.7, _brew_mat))
	_build_scaffold(4.2, 3.6, [1.5, 2.9] as Array[float])
	_build_wreck(1.5, 1.1, _brew_mat, 4041, 6)
	# Idle: purple motes spiral up around the hut, a thin wisp from the stovepipe.
	var mo := _pm(Vector3.UP, 20.0, 0.3, 0.6, Vector3.ZERO, 0.09, 0.04,
		_ramp(Color(0.55, 0.25, 0.85, 0.7), Color(0.30, 0.10, 0.50), false))
	mo.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mo.emission_ring_axis = Vector3.UP
	mo.emission_ring_radius = 2.4
	mo.emission_ring_inner_radius = 1.9
	mo.emission_ring_height = 0.1
	mo.orbit_velocity_min = 0.1
	mo.orbit_velocity_max = 0.14
	_idle_particles("VoidMotes", Vector3(0, 0.5, 0), 12, 4.0, mo, true)
	var wisp := _pm(Vector3.UP, 12.0, 0.5, 0.8, Vector3(0.15, 0.05, 0), 0.25, 0.8,
		_ramp(Color(0.35, 0.18, 0.5, 0.4), Color(0.35, 0.18, 0.5, 0.0), false))
	_idle_particles("PipeWisp", Vector3(-1.2, 4.6, 1.1), 6, 2.4, wisp, false)
	var brew := _pm(Vector3.UP, 20.0, 0.25, 0.5, Vector3.ZERO, 0.1, 0.03,
		_ramp(Color(0.85, 0.55, 1.0), Color(0.45, 0.15, 0.75), false))
	brew.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	brew.emission_sphere_radius = 0.25
	_idle_particles("BrewBubbles", Vector3(-1.25, 1.05, -1.75), 6, 1.2, brew, true)


## Transform on the witch-hat frustum face looking along yaw `a` (0 = +Z), `along` metres sideways.
func _face_xf(a: float, along: float) -> Transform3D:
	var d := Vector3(sin(a), 0.0, cos(a))
	var apo: float = cos(PI / 6.0)
	var mid_r: float = (ROOF.x + ROOF.y) * 0.5 * apo
	var dr: float = (ROOF.x - ROOF.y) * apo
	var n: Vector3 = (d * ROOF.w + Vector3.UP * dr).normalized()
	var side: Vector3 = Vector3.UP.cross(d).normalized()
	return Transform3D(Basis(side, n, side.cross(n)), d * mid_r + Vector3(0, ROOF.z + ROOF.w * 0.5, 0) + side * along
		+ n * 0.06)


func _idle(_delta: float) -> void:
	_orb.position.y = _orb_y + 0.12 * sin(_t * 2.5)


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	# Below 50 % the tip shard goes dark; below 25 % the lantern orb gutters out.
	if smoke_on or _progress >= 1.0:
		_tip_glow.visible = not smoke_on
	if _progress >= 0.95:
		_orb.visible = not fire_on
	if _dress:
		_dress.sync(_progress, _health_ratio, false)


## G-B: the darker shingle courses follow the team colour (x TEAM_DARK).
func _vc_team() -> Array:
	return [_m_team, [_m_team_dark, TEAM_DARK]]


## G-B: tier-scaled dressing (dead ground, mist, wisps, embers, the lantern's light at Ultra; nothing at Low).
func _post_build() -> void:
	_dress = ShadowDress.attach(self, {"radius": 4.3, "inner": 2.2, "top": 6.2, "mist": 2.6, "seed": 1.7,
		"wisp_r": 2.3, "wisp_y": Vector2(0.5, 3.0), "glow": team_glow(),
		"embers": [blaze_points[0], smoke_points[0]], "light": Vector3(1.45, 4.1, -1.5), "light_energy": 0.8,
		"light_range": 5.0})


func _on_progress(_building: bool) -> void:
	if _dress:
		_dress.sync(_progress, _health_ratio, false)


func _on_destroy_start() -> void:
	if _dress:
		_dress.sync(1.0, 0.0, true)


func _on_team_color(g: Color) -> void:
	if _dress:
		_dress.set_glow(g)
