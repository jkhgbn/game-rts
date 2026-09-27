extends Node3D
## Test strip for the river look (task 12.V1): the real north river of Crown Hollow (map-fill.md 2.1, N0-N5),
## Reed Ford, the whole Crown Isle moat with both Crown Steps, a few foam rocks (the drowned barge spot, bank
## stones), lily pads (flat-surface check) and a wading soldier with the `wade` ripples. The ground is a grid cut
## along the water (vertices snapped to the bank line), painted with ground_material.tres (lane / roads off).
## Built in _ready, so it also shows how RiverSystem (12.C1) can use WaterMeshes. Preview: water_preview.gd.

const WM_PATH := "res://art/environment/water/water_meshes.gd"
const GROUND_MAT := "res://art/environment/ground_material.tres"
const ROCK_MESH := "res://art/environment/meshes/rock_boulder.res"
const RIPPLE_MAT := "res://art/environment/water/wade_ripple_mat.tres"

const RIVER: Array[Vector2] = [Vector2(-17, -80), Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38),
	Vector2(-8, -30), Vector2(-5, -21), Vector2(-2.5, -12.5)]
const HALF_WIDTH := 2.5
const MOAT := Vector4(0, 0, 12.75, 1.75)
const FORDS: Array[Vector4] = [Vector4(-8.5, -34, 3.5, 0), Vector4(-9.02, -9.02, 3.0, 0), Vector4(9.02, 9.02, 3.0, 0)]
const FOAM_ROCKS: Array[Vector4] = [Vector4(-6.2, -24.5, 0.65, 0), Vector4(-10.9, -44.6, 0.45, 0),
	Vector4(-3.4, -17.3, 0.4, 0), Vector4(11.2, -5.6, 0.45, 0), Vector4(-12.4, 4.4, 0.35, 0)]
const LILY_PADS: Array[Vector3] = [Vector3(-10.2, 0, -41.5), Vector3(-9.7, 0, -41.0), Vector3(-10.5, 0, -40.6),
	Vector3(12.4, 0, 3.5), Vector3(12.9, 0, 4.2)]
const GROUND_MIN := Vector2(-56, -76)
const GROUND_MAX := Vector2(44, 30)
const GROUND_CELL := 0.5

var river_path := PackedVector2Array()
var moat_path := PackedVector2Array()
var ripples: Array[MeshInstance3D] = []
var _t := 0.0


func _ready() -> void:
	var wm: GDScript = load(WM_PATH)
	river_path = PackedVector2Array(RIVER)
	moat_path = wm.arc_path(Vector2(MOAT.x, MOAT.y), MOAT.z, 180.0, 540.0, 0.6)
	# Shared materials: the world-space data RiverSystem would set once (fords + foam rocks).
	var water_mat := load(wm.WATER_MAT) as ShaderMaterial
	var ford_mat := load(wm.FORD_MAT) as ShaderMaterial
	var rocks := PackedVector4Array(FOAM_ROCKS)
	var fords := PackedVector4Array(FORDS)
	for m: ShaderMaterial in [water_mat, ford_mat]:
		m.set_shader_parameter(&"foam_rocks", rocks)
		m.set_shader_parameter(&"foam_rock_count", rocks.size())
		m.set_shader_parameter(&"fords", fords)
		m.set_shader_parameter(&"ford_count", fords.size())
	# Water: the river sits 4 mm under the moat where they overlap (the ring wins, no z-fight); no bank foam
	# across the river mouth on the moat's outer rim.
	var in_moat := func(p: Vector2) -> float: return 0.0 if p.length() < MOAT.z + MOAT.w + 0.3 else 1.0
	var in_river := func(p: Vector2) -> float:
		return 0.0 if p.length() > MOAT.z and wm.distance_to_path(river_path, p) < HALF_WIDTH + 0.35 else 1.0
	_add("RiverWater", wm.channel_surface(river_path, HALF_WIDTH, wm.WATER_Y - 0.004, 0.0, 1.0, in_moat))
	# The moat flows from the north mouth (258.7 deg) round both sides of the isle to the south mouth (78.7 deg):
	# two halves, each with UV.x running downstream.
	var moat_w: PackedVector2Array = wm.arc_path(Vector2(MOAT.x, MOAT.y), MOAT.z, 258.69, 78.69, 0.6)
	var moat_e: PackedVector2Array = wm.arc_path(Vector2(MOAT.x, MOAT.y), MOAT.z, 258.69, 438.69, 0.6)
	var s_mouth: float = _length(river_path)
	var radial := PackedVector2Array([moat_w[0], moat_w[moat_w.size() - 1]])   # centre (0, 0): radial = position
	_add("MoatWaterW", wm.channel_surface(moat_w, MOAT.w, wm.WATER_Y, s_mouth, 0.6, in_river, true, radial))
	_add("MoatWaterE", wm.channel_surface(moat_e, MOAT.w, wm.WATER_Y, s_mouth, 0.6, in_river, false, radial))
	_add("ReedFordFilm", wm.ford_film(river_path, HALF_WIDTH, Vector2(FORDS[0].x, FORDS[0].y), FORDS[0].z))
	_add("StepsFilmNW", wm.ford_film(moat_w, MOAT.w, Vector2(FORDS[1].x, FORDS[1].y), FORDS[1].z, wm.FILM_Y, s_mouth))
	_add("StepsFilmSE", wm.ford_film(moat_e, MOAT.w, Vector2(FORDS[2].x, FORDS[2].y), FORDS[2].z, wm.FILM_Y, s_mouth))
	# Trench walls (+ the ford end walls), riverbed_mat.
	var skip_river := func(p: Vector2) -> bool: return p.length() < MOAT.z + MOAT.w - 0.05
	var skip_moat := func(p: Vector2) -> bool:
		return p.length() > MOAT.z and wm.distance_to_path(river_path, p) < HALF_WIDTH - 0.05
	_add("RiverWalls", wm.channel_walls(river_path, HALF_WIDTH, skip_river, wm.WALL_BOTTOM_Y, 0.8, 1))
	_add("MoatWalls", wm.channel_walls(moat_path, MOAT.w, skip_moat, wm.WALL_BOTTOM_Y, 0.8, 2))
	_add("ReedFordEnds", wm.ford_end_walls(river_path, HALF_WIDTH, Vector2(FORDS[0].x, FORDS[0].y), FORDS[0].z))
	for i in [1, 2]:
		_add("StepsEnds%d" % i, wm.ford_end_walls(moat_path, MOAT.w, Vector2(FORDS[i].x, FORDS[i].y), FORDS[i].z))
	_build_ground(wm)
	_build_props()


func _process(delta: float) -> void:
	# Wade ripples: three rings growing and fading in turn around the wading soldier (what 12.V25 pools).
	_t += delta
	for i in ripples.size():
		var k: float = fmod(_t * 0.8 + float(i) / ripples.size(), 1.0)
		var r := ripples[i]
		r.scale = Vector3.ONE * lerpf(0.5, 1.9, k)
		r.transparency = clampf(k * 1.1, 0.0, 1.0)


static func _length(path: PackedVector2Array) -> float:
	var l := 0.0
	for i in path.size() - 1:
		l += path[i].distance_to(path[i + 1])
	return l


func _add(node_name: String, mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _deep(p: Vector2, wm: GDScript) -> bool:
	for f: Vector4 in FORDS:
		if p.distance_to(Vector2(f.x, f.y)) < f.z:
			return false
	if absf(p.length() - MOAT.z) < MOAT.w:
		return true
	# The river's round end at N5 must not bite into the isle: only count it outside the moat centre line.
	return p.length() > MOAT.z and wm.distance_to_path(river_path, p) < HALF_WIDTH


## Nearest point on the water's edge that is on land.
func _snap(p: Vector2, wm: GDScript) -> Vector2:
	var cands: Array[Vector2] = []
	var r: float = p.length()
	if r > 0.001:
		cands.append(p / r * (MOAT.z - MOAT.w))
		cands.append(p / r * (MOAT.z + MOAT.w))
	for i in river_path.size() - 1:
		var a: Vector2 = river_path[i]
		var b: Vector2 = river_path[i + 1]
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var c: Vector2 = a + ab * t
		var d: Vector2 = p - c
		if d.length() > 0.0001:
			cands.append(c + d.normalized() * HALF_WIDTH)
	for f: Vector4 in FORDS:
		var fc := Vector2(f.x, f.y)
		if p.distance_to(fc) > 0.0001:
			cands.append(fc + (p - fc).normalized() * f.z)
	var best := p
	var best_d := INF
	for q: Vector2 in cands:
		var out: Vector2 = (q - p).normalized() * 0.01 if q.distance_to(p) > 0.0001 else Vector2.ZERO
		if _deep(q + out, wm):
			continue
		var d2: float = q.distance_to(p)
		if d2 < best_d:
			best_d = d2
			best = q
	return best


func _build_ground(wm: GDScript) -> void:
	var nx: int = int((GROUND_MAX.x - GROUND_MIN.x) / GROUND_CELL)
	var nz: int = int((GROUND_MAX.y - GROUND_MIN.y) / GROUND_CELL)
	var pts: Array[Vector2] = []
	var deep: Array[bool] = []
	for j in nz + 1:
		for i in nx + 1:
			var p := GROUND_MIN + Vector2(i, j) * GROUND_CELL
			var d: bool = _deep(p, wm)
			deep.append(d)
			pts.append(_snap(p, wm) if d else p)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for j in nz:
		for i in nx:
			var a: int = j * (nx + 1) + i
			var b: int = a + 1
			var c: int = a + nx + 1
			var d: int = c + 1
			for tri: Array in [[a, b, d], [a, d, c]]:
				if deep[tri[0]] and deep[tri[1]] and deep[tri[2]]:
					continue
				var p0: Vector2 = pts[tri[0]]
				var p1: Vector2 = pts[tri[1]]
				var p2: Vector2 = pts[tri[2]]
				if _deep((p0 + p1 + p2) / 3.0, wm):
					continue
				# Clockwise seen from above = front face.
				var v0 := Vector3(p0.x, 0, p0.y)
				var v1 := Vector3(p1.x, 0, p1.y)
				var v2 := Vector3(p2.x, 0, p2.y)
				if (v1 - v0).cross(v2 - v0).y > 0.0:
					var tmp := v1
					v1 = v2
					v2 = tmp
				for v: Vector3 in [v0, v1, v2]:
					st.add_vertex(v)
	st.index()
	var mi := _add("Ground", st.commit())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gm := (load(GROUND_MAT) as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"lane_a", Vector2(500, 500))
	gm.set_shader_parameter(&"lane_b", Vector2(501, 501))
	gm.set_shader_parameter(&"spot_0", Vector4.ZERO)
	gm.set_shader_parameter(&"spot_1", Vector4.ZERO)
	gm.set_shader_parameter(&"expand_edge", false)
	gm.set_shader_parameter(&"border_mode", 0.0)
	mi.material_override = gm
	# A dark mud floor under everything: the snapped grid leaves small holes at ford / mouth corners that the real
	# ground (12.V2, an analytic discard) does not have.
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "PreviewFloor"
	var fp := PlaneMesh.new()
	fp.size = GROUND_MAX - GROUND_MIN
	floor_mi.mesh = fp
	floor_mi.position = Vector3((GROUND_MIN.x + GROUND_MAX.x) * 0.5, -0.62, (GROUND_MIN.y + GROUND_MAX.y) * 0.5)
	floor_mi.material_override = load(wm.BED_MAT)
	floor_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(floor_mi)


func _build_props() -> void:
	# Foam rocks (stand-ins for piers, stones and the drowned barge).
	var rock := load(ROCK_MESH) as Mesh
	if rock:
		var box: AABB = rock.get_aabb()
		var base_r: float = maxf(box.size.x, box.size.z) * 0.5
		for i in FOAM_ROCKS.size():
			var f: Vector4 = FOAM_ROCKS[i]
			var mi := MeshInstance3D.new()
			mi.name = "FoamRock%d" % i
			mi.mesh = rock
			var s: float = f.z / maxf(base_r, 0.01) * 1.3   # its waterline section ~ the foam radius
			mi.transform = Transform3D(Basis(Vector3.UP, 0.7 + i * 1.9).scaled(Vector3(s, s * 0.8, s)),
					Vector3(f.x, -0.35 - box.position.y * s * 0.8 - box.size.y * s * 0.8 * 0.45, f.y))
			add_child(mi)
	# Lily pads sit exactly on the flat surface (lily-pad-safe check). Test-only material.
	var pad_mat := StandardMaterial3D.new()
	pad_mat.albedo_color = Color(0.22, 0.45, 0.16)
	var pad := CylinderMesh.new()
	pad.top_radius = 0.32
	pad.bottom_radius = 0.32
	pad.height = 0.02
	pad.radial_segments = 12
	pad.material = pad_mat
	for i in LILY_PADS.size():
		var mi := MeshInstance3D.new()
		mi.name = "LilyPad%d" % i
		mi.mesh = pad
		mi.position = LILY_PADS[i] + Vector3(0, -0.345, 0)
		mi.scale = Vector3.ONE * (0.8 + 0.25 * float(i % 3))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	# A wading soldier stand-in in Reed Ford with three wade ripples around it.
	var body := MeshInstance3D.new()
	body.name = "Wader"
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.6
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.85, 0.30, 0.12)
	cap.material = body_mat
	body.mesh = cap
	body.position = Vector3(-8.2, 0.8, -33.4)
	add_child(body)
	var rmat: Material = load(RIPPLE_MAT) if ResourceLoader.exists(RIPPLE_MAT) else null
	if rmat:
		var plane := PlaneMesh.new()
		plane.size = Vector2(1.0, 1.0)
		plane.material = rmat
		for i in 3:
			var r := MeshInstance3D.new()
			r.name = "WadeRipple%d" % i
			r.mesh = plane
			r.position = Vector3(-8.2, 0.05 + i * 0.002, -33.4)
			r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(r)
			ripples.append(r)
