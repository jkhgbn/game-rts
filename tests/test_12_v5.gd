extends SceneTree
## Task 12.V5 (river mouths): the mouth shaders parse (no screen / depth reads, one sampler), the saved materials and
## meshes exist within budget, the open cliff ring really has its two gaps (nothing over the gorge's water, the falls
## and the gorge seen from the game camera), the closed ring stays closed, map_dressing.tscn carries the RiverMouths
## node, and on the live skirmish RiverMouthsArt opens / closes the ring (meshes, border instances, ground skirt)
## with no light, collider or particles and the MapDressing draw budget kept.
## Run: $GODOT --headless --path . -s tests/test_12_v5.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "12.V5"
const RM := "res://art/environment/river_mouths/"
const MESH_DIR := "res://art/environment/meshes/"
const SHADERS: Array[String] = ["waterfall", "mouth_foam", "mouth_mist", "mouth_water_fallback"]
const MATS: Array[String] = ["waterfall_mat", "mouth_foam_mat", "mouth_mist_mat", "mouth_water_fallback_mat"]
## [mesh, max triangles]
const MESH_BUDGET: Array = [["mouth_water", 1200], ["mouth_falls", 900], ["mouth_foam", 900], ["mouth_mist", 64]]
const CLIFF_MAT := "res://art/environment/cliff_mat.tres"
const WATER_MAT := "res://art/environment/water/water_mat.tres"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const MAX_DRESSING_DRAWS := 140
const TIMEOUT_FRAMES := 5000
const PITCH := 55.0

# Mirrors of build_env.gd (river mouths): the gorge path and water levels.
const S_EDGE_X := 14.549
const GORGE_STEPS: Array[float] = [2.9, 6.6, 10.3, 14.0]
const GORGE_LEVELS: Array[float] = [-0.362, -0.9, -1.55, -2.25, -2.95]
const CHUTE_HALF := 0.3

var main: Node
var _fails: PackedStringArray = PackedStringArray()
var _frame := 0
var _ready_frame := -1


func _initialize() -> void:
	_check_shaders()
	_check_resources()
	_check_geometry()
	_check_scene_file()
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	_frame += 1
	if _ready_frame < 0:
		if main.get(&"hero") != null:
			_ready_frame = _frame
		elif _frame > TIMEOUT_FRAMES:
			_fail("the skirmish never finished loading")
			return _finish()
		return false
	if _frame < _ready_frame + 30:   # MapDressingArt populates / RiverMouthsArt applies (deferred)
		return false
	_check_live()
	return _finish()


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - %s" % f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fail(msg)


# ---------------------------------------------------------------- shaders / resources

func _check_shaders() -> void:
	for s: String in SHADERS:
		var path: String = RM + s + ".gdshader"
		var sh := load(path) as Shader
		if sh == null:
			_fail("%s does not load" % path)
			continue
		var code: String = sh.code
		_check(code.count("{") == code.count("}"), "%s: unbalanced braces" % s)
		_check(not code.contains("SCREEN_TEXTURE") and not code.contains("hint_screen_texture")
				and not code.contains("hint_depth_texture") and not code.contains("DEPTH_TEXTURE"), "%s: screen / depth read" % s)
		_check(code.count("sampler2D") == 1, "%s: one sampler (the shared paint noise)" % s)
		_check(not code.contains("proximity_fade"), "%s: no proximity fade (depth read)" % s)


func _check_resources() -> void:
	for i: int in MATS.size():
		var m := load(RM + MATS[i] + ".tres") as ShaderMaterial
		_check(m != null, "%s.tres missing" % MATS[i])
		if m:
			_check(m.shader != null and m.shader.resource_path == RM + SHADERS[i] + ".gdshader", "%s uses %s" % [MATS[i], SHADERS[i]])
			_check(m.get_shader_parameter(&"noise_tex") is Texture2D, "%s has the paint noise" % MATS[i])
	for e: Array in MESH_BUDGET:
		var mesh := load(RM + String(e[0]) + ".res") as ArrayMesh
		_check(mesh != null and mesh.get_surface_count() == 1, "%s.res missing / not one surface" % e[0])
		if mesh:
			var tris: int = mesh.surface_get_array_index_len(0) / 3
			_check(tris > 0 and tris <= int(e[1]), "%s: %d triangles (max %d)" % [e[0], tris, e[1]])
			_check(mesh.surface_get_array_index_len(0) > 0, "%s is indexed" % e[0])
	var open_c := load(MESH_DIR + "map_cliffs.res") as ArrayMesh
	var closed_c := load(RM + "map_cliffs_closed.res") as ArrayMesh
	_check(open_c != null and closed_c != null, "cliff rings missing")
	if open_c and closed_c:
		var to: int = open_c.surface_get_array_len(0) / 3
		var tc: int = closed_c.surface_get_array_len(0) / 3
		print("cliff ring triangles: open %d, closed %d" % [to, tc])
		_check(to <= tc + 8000, "open ring adds %d triangles (max 8000)" % (to - tc))
	_check(load(MESH_DIR + "map_plateau.res") != null and load(RM + "map_plateau_closed.res") != null, "plateau rings missing")


# ---------------------------------------------------------------- geometry

func _gorge_x(d: float) -> float:
	return S_EDGE_X + 1.1 * (1.0 - exp(-d * 0.2256 / 1.1)) + 0.35 * sin(d * 0.33) * smoothstep(3.0, 8.0, d)


func _gorge_wy(d: float) -> float:
	var y: float = GORGE_LEVELS[0]
	for k: int in GORGE_STEPS.size():
		y = lerpf(y, GORGE_LEVELS[k + 1], smoothstep(GORGE_STEPS[k] - CHUTE_HALF, GORGE_STEPS[k] + CHUTE_HALF, d))
	return y


## True within reach of one of the rocks standing in the rapids (build_env.gd `_gorge_rapid_rocks`).
func _near_rapid_rock(d: float) -> bool:
	for rk: Vector3 in [Vector3(1.2, 1.5, 0.4), Vector3(3.7, 1.15, 0.45), Vector3(4.4, -1.25, 0.35), Vector3(7.5, -0.7, 0.55),
			Vector3(8.7, 1.05, 0.4), Vector3(11.3, 0.35, 0.6), Vector3(14.8, -1.0, 0.5), Vector3(15.7, 1.2, 0.35)]:
		if absf(d - rk.x) < rk.z * 1.3 and absf(rk.y) < rk.z * 1.3:
			return true
	return false


## Triangles of `meshes` whose bounds touch `box` (x/z rectangle), as a flat PackedVector3Array.
func _faces(meshes: Array, box: Rect2) -> PackedVector3Array:
	var out := PackedVector3Array()
	for m: Mesh in meshes:
		var f: PackedVector3Array = m.get_faces()
		for t: int in range(0, f.size(), 3):
			var lo := Vector2(minf(f[t].x, minf(f[t + 1].x, f[t + 2].x)), minf(f[t].z, minf(f[t + 1].z, f[t + 2].z)))
			var hi := Vector2(maxf(f[t].x, maxf(f[t + 1].x, f[t + 2].x)), maxf(f[t].z, maxf(f[t + 1].z, f[t + 2].z)))
			if Rect2(lo, hi - lo).grow(0.01).intersects(box):
				out.append_array([f[t], f[t + 1], f[t + 2]])
	return out


## Nearest hit distance of the segment from -> to against `faces` (INF when clear).
func _hit(faces: PackedVector3Array, from: Vector3, to: Vector3) -> float:
	var best: float = INF
	for t: int in range(0, faces.size(), 3):
		var p: Variant = Geometry3D.segment_intersects_triangle(from, to, faces[t], faces[t + 1], faces[t + 2])
		if p != null:
			best = minf(best, from.distance_to(p as Vector3))
	return best


func _cam(focus: Vector3, zoom: float) -> Vector3:
	var p: float = deg_to_rad(PITCH)
	return focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)


func _check_geometry() -> void:
	var cliffs := load(MESH_DIR + "map_cliffs.res") as Mesh
	var plateau := load(MESH_DIR + "map_plateau.res") as Mesh
	var cliffs_c := load(RM + "map_cliffs_closed.res") as Mesh
	var plateau_c := load(RM + "map_plateau_closed.res") as Mesh
	var water := load(RM + "mouth_water.res") as Mesh
	var falls := load(RM + "mouth_falls.res") as Mesh
	if cliffs == null or plateau == null or cliffs_c == null or plateau_c == null or water == null or falls == null:
		_fail("meshes missing: geometry not checked")
		return
	# South gorge: nothing of the open ring over the water (up to the arch); the water is there at the right level;
	# the closed ring covers the same spots.
	var south_box := Rect2(8.0, 59.0, 16.0, 26.0)
	var open_s: PackedVector3Array = _faces([cliffs, plateau], south_box)
	var closed_s: PackedVector3Array = _faces([cliffs_c, plateau_c], south_box)
	var water_s: PackedVector3Array = _faces([water], south_box)
	var blocked := 0
	var dry := 0
	var closed_open := 0
	var n := 0
	var d: float = 0.85
	while d < 16.5:
		var x: float = _gorge_x(d)
		var y: float = _gorge_wy(d)
		var top := Vector3(x, 40.0, 60.0 + d)
		var h: float = _hit(open_s, top, Vector3(x, y - 0.3, 60.0 + d))
		if h < 40.0 - y - 0.15 and not _near_rapid_rock(d):
			blocked += 1
			print("  gorge covered at d %.1f (hit %.2f m under the top)" % [d, h])
		var hw: float = _hit(water_s, top, Vector3(x, y - 1.0, 60.0 + d))
		if hw == INF or absf((40.0 - hw) - y) > 0.12:
			dry += 1
			print("  gorge water missing / off at d %.1f (expected y %.2f, hit %.2f)" % [d, y, 40.0 - hw])
		if d > 8.5 and _hit(closed_s, top, Vector3(x, 1.0, 60.0 + d)) == INF:
			closed_open += 1
		n += 1
		d += 0.7
	print("gorge: %d samples, %d covered, %d without water, closed ring open at %d" % [n, blocked, dry, closed_open])
	_check(blocked == 0, "%d gorge samples covered by the open cliff ring / plateau" % blocked)
	_check(dry == 0, "%d gorge samples without water at the right level" % dry)
	_check(closed_open == 0, "the closed ring has %d holes over the gorge" % closed_open)
	# The gorge seen from the game camera (focus on the south edge, zoom 40 and 55).
	var seen := 0
	var tried := 0
	for zoom: float in [40.0, 55.0]:
		var cam: Vector3 = _cam(Vector3(15.0, 0.0, 58.0), zoom)
		var d2: float = 1.0
		while d2 < 15.5:
			var p := Vector3(_gorge_x(d2), _gorge_wy(d2) + 0.02, 60.0 + d2)
			if _hit(open_s, cam, p) > cam.distance_to(p) - 0.2:
				seen += 1
			tried += 1
			d2 += 1.0
	print("gorge from the camera: %d / %d water samples visible" % [seen, tried])
	_check(seen >= int(tried * 0.85), "the gorge water is hidden from the camera (%d / %d)" % [seen, tried])
	# North falls seen from the game camera (focus near the north edge, zoom 40 and 55): the curtain's vertices.
	var north_box := Rect2(-26.0, -90.0, 22.0, 34.0)
	var open_n: PackedVector3Array = _faces([cliffs, plateau], north_box)
	var fv: PackedVector3Array = falls.get_faces()
	var pts: Array[Vector3] = []
	for i: int in range(0, fv.size(), 7):
		if fv[i].z < -61.0 and fv[i].y > 0.3:   # the main curtain (the rapid steps are at the south)
			pts.append(fv[i])
	var seen_n := 0
	var tried_n := 0
	for zoom2: float in [40.0, 55.0]:
		var cam2: Vector3 = _cam(Vector3(-14.0, 0.0, -52.0), zoom2)
		for p2: Vector3 in pts:
			if _hit(open_n, cam2, p2) > cam2.distance_to(p2) - 0.2:
				seen_n += 1
			tried_n += 1
	print("falls from the camera: %d / %d curtain points visible" % [seen_n, tried_n])
	_check(tried_n > 20, "the falls curtain has too few points (%d)" % tried_n)
	_check(seen_n >= int(tried_n * 0.85), "the falls are hidden by the cliffs (%d / %d)" % [seen_n, tried_n])
	# The closed ring has no notch: the camera's view of the fall's spot hits the cliff face in front of it.
	var closed_n: PackedVector3Array = _faces([cliffs_c], north_box)
	var cam3: Vector3 = _cam(Vector3(-14.0, 0.0, -52.0), 40.0)
	var spot := Vector3(-15.1, 4.0, -65.5)
	_check(_hit(closed_n, cam3, spot) < cam3.distance_to(spot) - 0.3, "the closed ring shows the notch")


func _check_scene_file() -> void:
	var ps := load("res://art/environment/map_dressing.tscn") as PackedScene
	if ps == null:
		_fail("map_dressing.tscn missing")
		return
	var d: Node = ps.instantiate()
	var rm: Node = d.get_node_or_null(^"RiverMouths")
	_check(rm != null and rm.has_method(&"set_open") and rm.has_method(&"is_open"), "map_dressing.tscn: RiverMouths node / API")
	if rm:
		for nm: String in ["Water", "Falls", "Foam", "Mist"]:
			var mi := rm.get_node_or_null(NodePath(nm)) as MeshInstance3D
			_check(mi != null and mi.mesh != null, "RiverMouths/%s missing" % nm)
			if mi:
				_check(mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "RiverMouths/%s casts a shadow" % nm)
		var co: Dictionary = rm.get(&"closed_only")
		var oo: Dictionary = rm.get(&"open_only")
		_check(_count(co) > 0 and _count(oo) > 0, "RiverMouths closed_only / open_only empty")
		_check_ring_instances(d.get(&"border_sets"), co, oo)
	var cl := d.get_node_or_null(^"Cliffs") as MeshInstance3D
	_check(cl != null and cl.mesh != null and cl.mesh.resource_path == MESH_DIR + "map_cliffs.res", "Cliffs default = the open ring")
	d.free()


# ---------------------------------------------------------------- the live skirmish

func _check_live() -> void:
	var dressing: Node = main.find_child("MapDressing", true, false)
	if dressing == null:
		_fail("MapDressing missing from the skirmish")
		return
	var rm: Node = dressing.get_node_or_null(^"RiverMouths")
	if rm == null:
		_fail("RiverMouths missing from the live MapDressing")
		return
	var want: bool = main.get(&"river_enabled") == true
	_check(bool(rm.call(&"is_open")) == want, "RiverMouths follows river_enabled (%s)" % str(main.get(&"river_enabled")))
	print("river_enabled = %s, mouths open = %s" % [str(main.get(&"river_enabled")), str(rm.call(&"is_open"))])
	var water := rm.get_node_or_null(^"Water") as MeshInstance3D
	if water:
		var mp: String = water.material_override.resource_path if water.material_override else ""
		var expect: String = WATER_MAT if ResourceLoader.exists(WATER_MAT) else RM + "mouth_water_fallback_mat.tres"
		_check(mp == expect, "Water material %s (expected %s)" % [mp, expect])
	_check(dressing.find_children("*", "Light3D", true, false).is_empty(), "MapDressing has a light")
	_check(dressing.find_children("*", "CollisionObject3D", true, false).is_empty(), "MapDressing has a collider")
	_check(dressing.find_children("*", "GPUParticles3D", true, false).is_empty()
			and dressing.find_children("*", "CPUParticles3D", true, false).is_empty(), "MapDressing has particles")
	var draws := dressing.find_children("*", "GeometryInstance3D", true, false).size()
	print("MapDressing draw nodes: %d" % draws)
	_check(draws <= MAX_DRESSING_DRAWS, "MapDressing has %d draw nodes (max %d)" % [draws, MAX_DRESSING_DRAWS])
	var cliffs := dressing.get_node_or_null(^"Cliffs") as MeshInstance3D
	var plateau := dressing.get_node_or_null(^"Plateau") as MeshInstance3D
	var ground: ShaderMaterial = _ground(main)
	var n_closed: int = _count(rm.get(&"closed_only"))
	var n_open: int = _count(rm.get(&"open_only"))
	for open: bool in [true, false, want]:
		rm.call(&"set_open", open)
		var tag: String = "open" if open else "closed"
		_check((rm as Node3D).visible == open, "%s: RiverMouths visible = %s" % [tag, str((rm as Node3D).visible)])
		var cp: String = MESH_DIR + "map_cliffs.res" if open else RM + "map_cliffs_closed.res"
		var pp: String = MESH_DIR + "map_plateau.res" if open else RM + "map_plateau_closed.res"
		_check(cliffs != null and cliffs.mesh != null and cliffs.mesh.resource_path == cp, "%s: Cliffs mesh" % tag)
		_check(plateau != null and plateau.mesh != null and plateau.mesh.resource_path == pp, "%s: Plateau mesh" % tag)
		_check(cliffs != null and cliffs.material_override != null and cliffs.material_override.resource_path == CLIFF_MAT,
				"%s: Cliffs keep cliff_mat.tres (MAP.P1)" % tag)
		if ground:
			var ee: Variant = ground.get_shader_parameter(&"expand_edge")
			if open:
				_check(ee == false, "open: the ground skirt (expand_edge) must be off")
			else:
				_check(ee == null or ee == true, "closed: the ground skirt must be back (%s)" % str(ee))
		var hidden: int = int(rm.call(&"hidden_count"))
		_check(hidden == (n_closed if open else n_open), "%s: %d border instances hidden (expected %d)" % [tag, hidden,
				n_closed if open else n_open])


func _count(idx: Dictionary) -> int:
	var n := 0
	for k: Variant in idx:
		n += PackedInt32Array(idx[k]).size()
	return n


## Instances of the closed ring only stand in the mouth zones; the open ring's own never stand in the stream, the lip
## or the gorge (except on the stone arch).
func _check_ring_instances(sets: Variant, co: Dictionary, oo: Dictionary) -> void:
	if not (sets is Array):
		_fail("MapDressing.border_sets missing")
		return
	var data: Dictionary = {}
	for s: Variant in sets:
		data[String(s[1])] = s[2]
	var bad_c := 0
	var bad_o := 0
	for nm: Variant in co:
		for i: int in PackedInt32Array(co[nm]):
			var p: Vector3 = _origin(data.get(String(nm), PackedFloat32Array()), i)
			var north: bool = p.z < -60.0 and absf(p.x + 15.1) < 7.4
			var south: bool = p.z > 60.0 and p.z < 85.0 and p.x > 8.8 and p.x < 21.6
			if not (north or south):
				bad_c += 1
	for nm2: Variant in oo:
		for i2: int in PackedInt32Array(oo[nm2]):
			var q: Vector3 = _origin(data.get(String(nm2), PackedFloat32Array()), i2)
			var dd: float = q.z - 60.0
			if dd > 0.0 and dd < 17.4 and absf(q.x - _gorge_x(dd)) < 2.6:
				bad_o += 1   # in the gorge
			if q.z < -60.0 and q.z > -80.5 and absf(q.x + 15.1) < 1.3:
				bad_o += 1   # in the stream / on the lip
	_check(bad_c == 0, "%d closed-ring-only instances outside the mouth zones" % bad_c)
	_check(bad_o == 0, "%d open-ring instances stand in the water" % bad_o)


func _origin(buf: PackedFloat32Array, i: int) -> Vector3:
	if buf.size() < (i + 1) * 12:
		return Vector3.ZERO
	return Vector3(buf[i * 12 + 9], buf[i * 12 + 10], buf[i * 12 + 11])

func _ground(level: Node) -> ShaderMaterial:
	for n: Node in level.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if mi.mesh is PlaneMesh and (mi.mesh as PlaneMesh).size.x >= 119.0 and sm and sm.shader \
				and sm.shader.resource_path == GROUND_SHADER:
			return sm
	return null
