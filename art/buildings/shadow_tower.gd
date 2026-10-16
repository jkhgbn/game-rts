class_name NightSpireModel
extends EmberSpireModel
## Shadow tower "Night Spire" (buildings.md: 1 x 1 cell = 2 x 2 m, height 5, orb blinks on each shot). Task 5.V2.
## Read from the RTS camera: a twisted six-sided needle (two prisms turned 20 deg apart), a team-coloured
## collar, three silver fins leaning out like a claw (one taller: the asymmetric secondary) around a purple
## orb circled by a turning rune ring. Same hooks as EmberSpireModel (play_shot included).

const HEX := PI / 6.0
## G-F Shadow leftovers: the slate crown (eave radius, top radius, eave y, rise), its yaw and courses; team shades.
const ROOF := Vector4(1.04, 0.42, 3.86, 0.42)
const ROOF_YAW := 0.6981   # 40 deg, the old collar's turn
const ROOF_COURSES := 4
const TEAM_DARK := 0.74
const TEAM_MID := 0.87

var _m_team_dark: ShaderMaterial
var _m_team_mid: ShaderMaterial
var _ring: MeshInstance3D
var _stones: MeshInstance3D
var _dress: ShadowDress


func _setup() -> void:
	outline_calm = true   # G-F Shadow leftovers: the site outline under the scaffold (SiteOutline)
	kingdom_color = Color(0.42, 0.22, 0.60)
	glow_color = Color(0.70, 0.30, 1.00)
	stone_color = Color(0.20, 0.17, 0.26)
	dark_color = Color(0.10, 0.08, 0.14)
	trim_color = Color(0.55, 0.52, 0.66)
	smoke_color = Color(0.12, 0.09, 0.16)
	blaze_a = Color(0.85, 0.55, 1.0)
	blaze_b = Color(0.45, 0.15, 0.75)
	stain_color = Color(0.15, 0.06, 0.25, 0.35)
	footprint = 2.0
	crack_strength = 0.7
	vc_merge = true   # G-B (Art Lab B8 / B9 WARN, 13 materials): one vertex-coloured painted material, like the Ember Spire
	plinth_top = 0.4
	wreck_top = 1.2
	_orb_y = 4.55
	_halo_size = 1.6
	smoke_points = [Vector3(0.3, 2.5, 0.3)]
	blaze_points = [Vector3(-0.2, 3.2, -0.2)]


## A.9: merged tiers (Plinth, Shaft with root shards / band / slits, Collar); fins stay a MultiMesh (_crown); three
## rune stones orbit the shaft (a floater, turned in _crown_idle).
func _build_parts() -> void:
	var box1: Mesh = _box(Vector3.ONE)
	var hexb := Basis(Vector3.UP, HEX)
	var slit_mat: ShaderMaterial = _glow_mat(glow_color, 2.5, 1.0, false)
	var it: Array = []
	it.append(_itx(_cyl(1.3, 1.3, 0.4, 6), Transform3D(hexb, Vector3(0, 0.2, 0)), _m_dark))
	it.append(_itx(_cyl(0.98, 1.05, 0.22, 6), Transform3D(Basis(Vector3.UP, HEX + deg_to_rad(10.0)), Vector3(0, 0.51, 0)),
		_m_dark))
	_no_collapse.append(_merged("Plinth", "plinth", it))
	# Shaft tier: stone lower needle, dark twisted upper needle, a silver band at the joint, two glowing slits, and
	# three dark root shards clawing at the foot (the tallest one front-left: the asymmetric secondary).
	it = []
	it.append(_itx(_cyl(0.68, 0.82, 1.75, 6), Transform3D(hexb, Vector3(0, 1.275, 0)), _m_stone))
	it.append(_itx(_cyl(0.5, 0.64, 1.6, 6), Transform3D(Basis(Vector3.UP, HEX + deg_to_rad(20.0)), Vector3(0, 2.95, 0)),
		_m_dark))
	it.append(_itx(_cyl(0.74, 0.74, 0.16, 6), Transform3D(Basis(Vector3.UP, HEX + deg_to_rad(10.0)), Vector3(0, 2.17, 0)),
		_m_trim))
	it.append(_it(box1, Vector3(0, 1.4, -0.66), slit_mat, Vector3.ZERO, Vector3(0.1, 0.7, 0.08)))
	it.append(_it(box1, Vector3(0, 1.4, 0.66), slit_mat, Vector3.ZERO, Vector3(0.1, 0.7, 0.08)))
	for k: int in 3:
		var a: float = PI * 1.25 + TAU * k / 3.0
		var d := Vector3(sin(a), 0.0, cos(a))
		var h: float = 1.9 if k == 0 else 1.3
		var b: Basis = _lean(d, 24.0)
		it.append(_itx(_cyl(0.0, 0.26, h, 4), Transform3D(b, d * 0.9 + Vector3(0, 0.45, 0) + b * Vector3(0, h * 0.5, 0)),
			_m_dark))
	# G-B: an obsidian claw of shards round the foot, three bone ribs gripping the shaft, a spiked iron crown on the
	# band: the needle reads bigger and meaner at 40 m.
	var obs: ShaderMaterial = _painted_mat(Color(0.085, 0.065, 0.12), 0.45, 0.0)
	var bone: ShaderMaterial = _painted_mat(Color(0.68, 0.64, 0.57), 0.12, 0.0)
	for k: int in 6:
		var a: float = TAU * (float(k) + 0.5) / 6.0 + 0.2
		var d := Vector3(sin(a), 0.0, cos(a))
		var h: float = 1.15 if k % 2 == 0 else 0.8
		var b: Basis = _lean(d, 30.0 + 6.0 * float(k % 3))
		it.append(_itx(_cyl(0.0, 0.2, h, 4), Transform3D(b, d * 1.12 + Vector3(0, 0.4, 0) + b * Vector3(0, h * 0.5, 0)), obs))
	for k: int in 3:
		var a: float = TAU * float(k) / 3.0 + 0.5
		var d := Vector3(sin(a), 0.0, cos(a))
		var lo: Vector3 = d * 0.95 + Vector3(0, 0.55, 0)
		var mid: Vector3 = d * 0.86 + Vector3(0, 1.5, 0)
		var hi: Vector3 = d * 0.62 + Vector3(0, 2.35, 0)
		for seg: Array in [[lo, mid], [mid, hi]]:
			var e: Vector3 = (seg[1] as Vector3) - (seg[0] as Vector3)
			it.append(_itx(_cyl(0.06, 0.09, e.length(), 5), Transform3D(Basis(Quaternion(Vector3.UP, e.normalized())),
				((seg[0] as Vector3) + (seg[1] as Vector3)) * 0.5), bone))
		it.append(_itx(_cyl(0.0, 0.07, 0.4, 4), Transform3D(_lean(d, -60.0), hi + d * 0.08 + Vector3(0, 0.12, 0)), bone))
	for k: int in 6:
		var a: float = TAU * float(k) / 6.0 + HEX
		var d := Vector3(sin(a), 0.0, cos(a))
		var b: Basis = _lean(d, 55.0)
		it.append(_itx(_cyl(0.0, 0.07, 0.42, 4), Transform3D(b, d * 0.76 + Vector3(0, 2.2, 0) + b * Vector3(0, 0.2, 0)), _m_trim))
	_merged("Shaft", "shaft", it)
	# G-F Shadow leftovers: the collar was one flat team hexagon (a slab at close zoom); now a slate crown (see _crown_roof).
	it = []
	_crown_roof(it, box1)
	var collar: MeshInstance3D = _merged("Collar", "collar", it)
	# Rune stones: three dark slabs with glowing runes orbiting the shaft at 2.4 m.
	var rune_mat: ShaderMaterial = _glow_mat(glow_color, 2.6, 1.8, true, 3)
	it = []
	for k: int in 3:
		var a: float = TAU * k / 3.0
		var d := Vector3(sin(a), 0.0, cos(a))
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.15)
		it.append(_itx(box1, Transform3D(b.scaled_local(Vector3(0.5, 0.72, 0.2)), d * 1.2), _m_dark))
		it.append(_itx(box1, Transform3D(b.scaled_local(Vector3(0.3, 0.46, 0.04)), d * 1.31), rune_mat))
	_stones = _merged("RuneStones", "stones", it)
	_stones.position = Vector3(0, 2.4, 0)
	_stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_floaters.append(_stones)
	_build_scaffold(2.3, 4.3, [2.0, 3.7] as Array[float])
	_build_wreck(0.7, 1.4, slit_mat, 2022, 4)
	# Three fins leaning out 20 deg; the back one (+Z) is 35 % taller.
	var fx: Array[Transform3D] = []
	for i: int in 3:
		var a: float = PI + TAU * i / 3.0 + PI / 3.0
		var dir := Vector3(sin(a), 0.0, cos(a))
		var tall: float = 1.35 if i == 1 else 1.0
		var b: Basis = _lean(dir, 20.0) * Basis(Vector3.UP, a) * Basis.from_scale(Vector3(1.0, tall, 1.0))
		fx.append(Transform3D(b, dir * 0.72 + Vector3(0, 4.1, 0) + b * Vector3(0, 0.6, 0)))
	# Blade fins: a 4-sided cone flattened across the lean direction.
	for i: int in fx.size():
		fx[i] = Transform3D(fx[i].basis * Basis.from_scale(Vector3(1.0, 1.0, 0.35)), fx[i].origin)
	_crown = _multi("Fins", _cyl(0.0, 0.34, 1.3, 4), _m_trim, fx)
	_build_orb(0.3, 3.4)
	_ring = _part("RuneRing", _torus(0.44, 0.52), _glow_mat(glow_color, 2.6, 1.3, true, 6), Vector3(0, _orb_y, 0),
		Basis(Vector3.RIGHT, deg_to_rad(18.0)))
	_floaters.append(_ring)
	_hide_on_collapse.append_array([collar, _crown])
	var mo := _pm(Vector3.UP, 180.0, 0.2, 0.5, Vector3(0, -0.4, 0), 0.07, 0.03,
		_ramp(Color(0.9, 0.6, 1.0), Color(0.4, 0.15, 0.7), false))
	mo.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mo.emission_sphere_radius = 0.4
	_idle_particles("OrbMotes", Vector3(0, _orb_y, 0), 10, 1.4, mo, true)


## G-F Shadow leftovers (docs/art/gf_shadow_leftovers.md, gf_review2 item 3): the crown under the orb in the
## Gloom Hall / Hovel slate style. A dark corbel flares out of the needle; a thick dark eave board; a six-sided slate
## skirt (ROOF: eave radius, top radius, eave y, rise) of `ROOF_COURSES` rows of single slates, every other row offset
## half a slate, each tilted flatter than its face (a shadow line per row), in three team shades (dark, mid, team)
## with a lighter row every other course and a sawtooth eave row; dark hip ribs (ridge caps) on the six corners; a dark socket
## ring round the orb with six short spikes (the spire cap). Items for one merged mesh: one surface after the painted
## merge (vc_merge), the same single draw the old collar part was.
func _crown_roof(it: Array, box1: Mesh) -> void:
	_m_team_dark = _painted_mat(kingdom_color.darkened(1.0 - TEAM_DARK), 0.1, 0.0)
	_m_team_mid = _painted_mat(kingdom_color.darkened(1.0 - TEAM_MID), 0.1, 0.0)
	var shades: Array[ShaderMaterial] = [_m_team_dark, _m_team_mid, _m_team]
	var rb: float = ROOF.x
	var rt: float = ROOF.y
	var y0: float = ROOF.z
	var rise: float = ROOF.w
	var hexb := Basis(Vector3.UP, HEX + ROOF_YAW)   # hex cylinders: faces centred on ROOF_YAW + k x 60 deg
	# Corbel: the needle's top flaring out under the eave, and the stone core under the slates.
	it.append(_itx(_cyl(rb - 0.18, 0.5, 0.3, 6), Transform3D(hexb, Vector3(0, y0 - 0.17, 0)), _m_dark))
	it.append(_itx(_cyl(rt - 0.06, rb - 0.14, rise - 0.04, 6), Transform3D(hexb, Vector3(0, y0 + rise * 0.5 - 0.02, 0)),
		_m_stone))
	# Eave board: a thick dark hexagon band (the roof's edge has a thickness from above).
	it.append(_itx(_cyl(rb + 0.02, rb + 0.04, 0.12, 6), Transform3D(hexb, Vector3(0, y0 - 0.01, 0)), _m_dark))
	var rng := RandomNumberGenerator.new()
	rng.seed = 6113
	var apo: float = cos(PI / 6.0)
	var dr: float = (rb - rt) * apo
	var slope_l: float = sqrt(dr * dr + rise * rise)
	for f: int in 6:
		var a: float = ROOF_YAW + PI / 3.0 * float(f)
		var d := Vector3(sin(a), 0.0, cos(a))
		var side: Vector3 = Vector3.UP.cross(d).normalized()
		var nrm: Vector3 = (d * rise + Vector3.UP * dr).normalized()
		var b := Basis(side, nrm, side.cross(nrm)) * Basis(Vector3.RIGHT, deg_to_rad(-6.0))
		for k: int in ROOF_COURSES:
			var t: float = (float(k) + 0.5) / float(ROOF_COURSES)
			var r: float = lerpf(rb, rt, t)   # face width = the hexagon's side = its circumradius
			var n_s: int = maxi(int(round(r / 0.21)), 2)
			var sw: float = r / float(n_s)
			var off: float = 0.5 * sw if k % 2 == 1 else 0.0
			var row_base: int = 1 if k % 2 == 0 else 2   # value step per course: mid / light rows
			var c: Vector3 = d * (r * apo) + Vector3(0, y0 + rise * t, 0) + nrm * 0.05
			for j: int in range(-1, n_s + 1):
				var xa: float = maxf(-r * 0.5 + sw * float(j) + off, -r * 0.5)
				var xb: float = minf(-r * 0.5 + sw * float(j + 1) + off, r * 0.5)
				if xb - xa < 0.09:
					continue
				var shade: int = row_base
				var roll: float = rng.randf()
				if roll < 0.22:
					shade = 0
				elif roll < 0.36:
					shade = 2 if row_base == 1 else 1
				var ln: float = slope_l / float(ROOF_COURSES) + 0.08
				var down: float = rng.randf_range(-0.02, 0.02)
				if k == 0 and j % 2 == 0:
					ln += 0.07   # sawtooth eave
					down += 0.035
				var p: Vector3 = c + side * ((xa + xb) * 0.5) + b.z * down
				var yb: Basis = Basis(nrm, deg_to_rad(rng.randf_range(-3.0, 3.0))) * b
				it.append(_itx(box1, Transform3D(yb.scaled_local(Vector3(xb - xa - 0.025, 0.04, ln)), p), shades[shade]))
		# Hip rib on the corner between this face and the next (a dark ridge cap down each hip).
		var ca: float = a + PI / 6.0
		var cd := Vector3(sin(ca), 0.0, cos(ca))
		var lo: Vector3 = cd * (rb + 0.02) + Vector3(0, y0 + 0.04, 0)
		var hi: Vector3 = cd * (rt + 0.02) + Vector3(0, y0 + rise + 0.04, 0)
		var e: Vector3 = hi - lo
		it.append(_itx(box1, Transform3D(Basis(Quaternion(Vector3.UP, e.normalized())).scaled_local(
			Vector3(0.08, e.length() + 0.08, 0.08)), (lo + hi) * 0.5), _m_dark))
	# Spire cap: a dark socket ring the orb sits in, six short silver spikes on its rim.
	it.append(_itx(_cyl(rt - 0.02, rt + 0.04, 0.14, 6), Transform3D(hexb, Vector3(0, y0 + rise + 0.03, 0)), _m_dark))
	for k: int in 6:
		var a: float = ROOF_YAW + PI / 6.0 + PI / 3.0 * float(k)
		var d := Vector3(sin(a), 0.0, cos(a))
		var lb: Basis = _lean(d, 18.0)
		it.append(_itx(_cyl(0.0, 0.05, 0.22, 4), Transform3D(lb, d * rt + Vector3(0, y0 + rise + 0.1, 0) + lb * Vector3(0, 0.11, 0)),
			_m_trim))


## G-F Shadow leftovers: the slate shades follow the team colour (x TEAM_DARK / TEAM_MID), as on the Hovel.
func _vc_team() -> Array:
	return [_m_team, [_m_team_dark, TEAM_DARK], [_m_team_mid, TEAM_MID]]


## G-B: tier-scaled dressing round the needle (nothing at Low; the orb lights the ground at Ultra).
func _post_build() -> void:
	super()
	_dress = ShadowDress.attach(self, {"radius": 2.7, "inner": 1.2, "top": 5.5, "mist": 1.5, "seed": 2.9,
		"wisp_r": 1.15, "wisp_y": Vector2(0.5, 3.4), "glow": team_glow(), "embers": [smoke_points[0]],
		"light": Vector3(0, _orb_y, 0), "light_energy": 0.9, "light_range": 5.0})


func _on_progress(building: bool) -> void:
	super(building)
	if _dress:
		_dress.sync(_progress, _health_ratio, false)


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	super(smoke_on, fire_on)
	if _dress:
		_dress.sync(_progress, _health_ratio, false)


func _on_destroy_start() -> void:
	super()
	if _dress:
		_dress.sync(1.0, 0.0, true)


func _on_team_color(g: Color) -> void:
	super(g)
	if _dress:
		_dress.set_glow(g)


func _crown_idle(delta: float) -> void:
	_ring.rotate_y(deg_to_rad(-40.0) * delta)
	_ring.position.y = _orb.position.y
	_stones.rotate_y(deg_to_rad(22.0) * delta)
	_stones.position.y = 2.4 + 0.1 * sin(_t * 1.3)
