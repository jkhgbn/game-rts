class_name HearthModel
extends SmallBuildingModel
## Fire house "Hearth" (buildings.md: 2 x 2 cells = 4 x 4 m, +10 pop). Task 5.V2, polished in A.9.
## Read from the RTS camera: a squat black-stone forge house under a stepped three-tier roof in the team colour
## (bronze hip ridges, a spike finial), a fat chimney at the back-right corner breathing smoke and embers (the
## asymmetric secondary), an arched door with a hanging lantern, warm windows, a woodpile and a chopping stump.
## Gate (door) on local -Z. Hooks: see SmallBuildingModel. Tiers are merged meshes (Plinth, Walls, Roof).
## States: scaffolding while built, < 50 % HP finial lost + a caved-in patch on the front of the roof, < 25 % a
## burning hole on the right and dark windows, a wreck of broken walls and embers after the collapse.

const TIERS: Array[Vector4] = [   # (bottom radius, top radius, bottom y, height) of the 4-sided roof tiers
	Vector4(3.3, 2.05, 2.62, 0.85), Vector4(2.6, 1.15, 3.32, 0.95), Vector4(1.6, 0.0, 4.12, 1.45)]

var _window_mat: ShaderMaterial
var _coal_mat: ShaderMaterial
var _finial: MeshInstance3D


func _setup() -> void:
	kingdom_color = Color(0.85, 0.30, 0.12)
	glow_color = Color(1.0, 0.55, 0.15)
	stone_color = Color(0.30, 0.26, 0.24)
	dark_color = Color(0.12, 0.10, 0.10)
	trim_color = Color(0.62, 0.40, 0.16)
	smoke_color = Color(0.16, 0.14, 0.13)
	stain_color = Color(0.22, 0.07, 0.02, 0.35)
	footprint = 4.0
	crack_strength = 0.55
	plinth_top = 0.45
	wreck_top = 1.05
	smoke_points = [Vector3(0.5, 3.4, -1.4)]
	blaze_points = [Vector3(1.45, 4.1, -0.2)]


func _build_parts() -> void:
	var box1: Mesh = _box(Vector3.ONE)
	_window_mat = _glow_mat(glow_color, 2.2, 3.0, false)
	_coal_mat = _glow_mat(glow_color, 3.0, 2.0, false)
	# Plinth (never collapses): slab, a door step, a corner stone.
	var it: Array = []
	it.append(_it(box1, Vector3(0, 0.225, 0), _m_dark, Vector3.ZERO, Vector3(4.3, 0.45, 4.3)))
	it.append(_it(box1, Vector3(-0.55, 0.12, -2.35), _m_dark, Vector3.ZERO, Vector3(1.4, 0.24, 0.45)))
	it.append(_it(box1, Vector3(-0.5, 0.03, -2.95), _m_dark, Vector3(0, 12, 0), Vector3(0.9, 0.08, 0.55)))
	_no_collapse.append(_merged("Plinth", "plinth", it))
	# Walls tier: stone box, dark base course and corner buttresses, arched door, windows, lantern, woodpile.
	it = []
	it.append(_it(box1, Vector3(0, 1.4, 0), _m_stone, Vector3.ZERO, Vector3(3.4, 1.9, 3.4)))
	it.append(_it(box1, Vector3(0, 0.6, 0), _m_dark, Vector3.ZERO, Vector3(3.6, 0.3, 3.6)))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			it.append(_it(box1, Vector3(1.7 * sx, 1.4, 1.7 * sz), _m_dark, Vector3.ZERO, Vector3(0.6, 1.95, 0.6)))
	it.append(_it(box1, Vector3(-0.55, 1.05, -1.72), _m_hole, Vector3.ZERO, Vector3(0.95, 1.2, 0.12)))
	it.append(_it(_cyl(0.475, 0.475, 0.12, 12), Vector3(-0.55, 1.65, -1.72), _m_hole, Vector3(90, 0, 0)))
	it.append(_it(_cyl(0.62, 0.62, 0.1, 12), Vector3(-0.55, 1.65, -1.69), _m_trim, Vector3(90, 0, 0),
		Vector3(1.0, 1.0, 1.0)))
	it.append(_it(box1, Vector3(-0.55, 2.2, -1.8), _m_trim, Vector3.ZERO, Vector3(0.36, 0.34, 0.3)))
	# Windows (front right, right side): glow pane, bronze sill, dark hood.
	for w: Transform3D in [Transform3D(Basis.IDENTITY, Vector3(0.82, 1.5, -1.72)),
			Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.72, 1.5, -0.2))]:
		it.append(_itx(box1, w * Transform3D(Basis.from_scale(Vector3(0.62, 0.55, 0.1)), Vector3.ZERO), _window_mat))
		it.append(_itx(box1, w * Transform3D(Basis.from_scale(Vector3(0.9, 0.14, 0.3)), Vector3(0, -0.34, -0.05)), _m_trim))
		it.append(_itx(box1, w * Transform3D(Basis.from_scale(Vector3(0.86, 0.14, 0.26)), Vector3(0, 0.36, -0.04)), _m_dark))
	# Lantern on a bronze bracket between door and window.
	it.append(_it(box1, Vector3(0.14, 2.0, -1.86), _m_trim, Vector3.ZERO, Vector3(0.12, 0.12, 0.36)))
	it.append(_it(box1, Vector3(0.14, 1.78, -2.0), _window_mat, Vector3.ZERO, Vector3(0.24, 0.3, 0.24)))
	it.append(_it(_cyl(0.0, 0.22, 0.2, 4), Vector3(0.14, 2.03, -2.0), _m_dark, Vector3(0, 45, 0)))
	# Woodpile against the left wall, a chopping stump at the front-left corner.
	for l: Vector3 in [Vector3(-1.98, 0.62, 0.0), Vector3(-1.98, 0.62, 0.36), Vector3(-1.98, 0.93, 0.18)]:
		it.append(_it(_cyl(0.17, 0.17, 1.5, 7), l, _m_trim, Vector3(90, 0, 0)))
	it.append(_it(_cyl(0.28, 0.3, 0.45, 8), Vector3(-1.6, 0.67, -2.2), _m_trim))
	_merged("Walls", "walls", it)
	# Roof tier: bronze eave, three stepped team tiers with bronze hip ridges, the chimney with its glowing coal.
	it = []
	it.append(_it(box1, Vector3(0, 2.5, 0), _m_trim, Vector3.ZERO, Vector3(3.9, 0.3, 3.9)))
	for t: Vector4 in TIERS:
		it.append(_it(_cyl(t.y, t.x, t.w, 4), Vector3(0, t.z + t.w * 0.5, 0), _m_team, Vector3(0, 45, 0)))
		for i: int in 4:
			var a: float = TAU * i / 4.0 + PI * 0.25   # the tier's corners (CylinderMesh vertex 0 is +Z, turned 45)
			var d := Vector3(sin(a), 0.0, cos(a))
			var p0: Vector3 = d * (t.x + 0.02) + Vector3(0, t.z, 0)
			var p1: Vector3 = d * maxf(t.y, 0.05) + Vector3(0, t.z + t.w, 0)
			var e: Vector3 = p1 - p0
			it.append(_itx(box1, Transform3D(Basis(Quaternion(Vector3.UP, e.normalized()))
				.scaled_local(Vector3(0.2, e.length(), 0.2)), (p0 + p1) * 0.5), _m_trim))
	it.append(_it(box1, Vector3(1.05, 4.0, 0.9), _m_stone, Vector3.ZERO, Vector3(0.8, 2.7, 0.8)))
	it.append(_it(box1, Vector3(1.05, 4.85, 0.9), _m_trim, Vector3.ZERO, Vector3(0.94, 0.18, 0.94)))
	it.append(_it(_cyl(0.62, 0.5, 0.32, 4), Vector3(1.05, 5.45, 0.9), _m_dark, Vector3(0, 45, 0)))
	it.append(_it(box1, Vector3(1.05, 5.64, 0.9), _coal_mat, Vector3.ZERO, Vector3(0.6, 0.12, 0.6)))
	var roof := _merged("Roof", "roof", it)
	_finial = _part("Finial", _cyl(0.0, 0.2, 0.8, 4), _m_trim, Vector3(0, 5.95, 0), Basis(Vector3.UP, PI * 0.25))
	_hide_on_collapse.append_array([roof, _finial])
	# Damage patches on the roof tiers (children of the roof: they squash and hide with it).
	_show_below_50.append(_roof_patch("RoofHoleF", roof, _face_xf(TIERS[0], Vector3(0, 0, -1), 0.45), 0.8))
	_show_below_25.append(_roof_patch("RoofHoleR", roof, _face_xf(TIERS[1], Vector3(1, 0, 0), -0.2), 0.7, _coal_mat))
	_build_scaffold(4.2, 3.4, [1.6, 3.0] as Array[float])
	_build_wreck(1.55, 1.02, _coal_mat, 3031)
	# Idle: chimney smoke + a few embers.
	var sm := _pm(Vector3.UP, 10.0, 0.7, 1.0, Vector3(0.25, 0.05, 0.0), 0.35, 1.3,
		_ramp(Color(0.26, 0.22, 0.20, 0.45), Color(0.26, 0.22, 0.20, 0.0), false))
	_idle_particles("ChimneySmoke", Vector3(1.05, 5.8, 0.9), 10, 3.0, sm, false)
	var em := _pm(Vector3.UP, 25.0, 0.8, 1.6, Vector3(0, -0.3, 0), 0.08, 0.04,
		_ramp(Color(1.0, 0.65, 0.2), Color(1.0, 0.4, 0.1), false))
	_idle_particles("ChimneyEmbers", Vector3(1.05, 5.7, 0.9), 8, 1.6, em, true)


## Transform on the face of a roof tier looking along the horizontal `d`, `along` metres sideways from its middle:
## +Y out of the roof, X horizontal along the face.
func _face_xf(t: Vector4, d: Vector3, along: float) -> Transform3D:
	var mid_r: float = (t.x + t.y) * 0.5 * cos(PI * 0.25)
	var dr: float = (t.x - t.y) * cos(PI * 0.25)
	var n: Vector3 = (d * t.w + Vector3.UP * dr).normalized()
	var side: Vector3 = Vector3.UP.cross(d).normalized()
	return Transform3D(Basis(side, n, side.cross(n)), d * mid_r + Vector3(0, t.z + t.w * 0.5, 0) + side * along + n * 0.05)


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	# Below 50 % the finial is knocked off; below 25 % the windows go dark (the fire is outside now).
	if smoke_on or _progress >= 1.0:
		_finial.visible = not smoke_on
	_window_mat.set_shader_parameter(&"energy", 0.6 if fire_on else 2.2)
