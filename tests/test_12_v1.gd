extends SceneTree
## Task 12.V1 (river water): the water / riverbed shaders parse and expose their uniforms, the materials load with
## the right shader and defaults, the wade ripple sprite + material exist, WaterMeshes builds valid meshes with the
## UV convention, and the test strip scene instantiates headless without errors.
## Run: godot --headless --path . -s tests/test_12_v1.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "12.v1"
const DIR := "res://art/environment/water/"
const WATER_UNIFORMS: Array[String] = ["noise_tex", "flow_speed", "foam_amount", "shallow", "channel_width",
	"deep_color", "water_color", "bank_color", "foam_color", "film_color", "glint_strength", "detail",
	"foam_rocks", "foam_rock_count", "fords", "ford_count"]
const BED_UNIFORMS: Array[String] = ["noise_tex", "top_y", "water_y", "root_amount"]

var _fails: Array[String] = []
var _strip: Node3D
var _frame := 0


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)
		print("  check failed: %s" % msg)


func _initialize() -> void:
	_check_shaders()
	_check_materials()
	_check_ripple()
	_check_meshes()
	var ps := load(DIR + "water_test_strip.tscn") as PackedScene
	_check(ps != null, "water_test_strip.tscn missing")
	if ps:
		_strip = ps.instantiate() as Node3D
		root.add_child(_strip)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 5:
		return false
	if _strip:
		for n: String in ["RiverWater", "MoatWaterW", "MoatWaterE", "ReedFordFilm", "RiverWalls", "MoatWalls", "Ground"]:
			var mi := _strip.get_node_or_null(NodePath(n)) as MeshInstance3D
			_check(mi != null and mi.mesh != null and mi.mesh.get_surface_count() == 1, "test strip lacks %s" % n)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _uniforms(sh: Shader) -> Dictionary:
	var names: Dictionary = {}
	for u: Dictionary in sh.get_shader_uniform_list():
		names[String(u["name"])] = u
	return names


func _check_shaders() -> void:
	var water := load(DIR + "water.gdshader") as Shader
	_check(water != null, "water.gdshader missing")
	if water:
		var names := _uniforms(water)
		_check(not names.is_empty(), "water.gdshader did not parse (no uniforms)")
		for n: String in WATER_UNIFORMS:
			_check(names.has(n), "water.gdshader lacks uniform %s" % n)
		var code := water.code
		# Opaque, flat, no screen / depth reads.
		_check(not code.contains("hint_screen_texture") and not code.contains("hint_depth_texture")
				and not code.contains("SCREEN_TEXTURE") and not code.contains("DEPTH_TEXTURE"), "water reads the screen / depth")
		_check(not code.contains("ALPHA"), "water must be opaque (no ALPHA)")
		_check(not code.contains("VERTEX +=") and not code.contains("VERTEX.y"), "water must stay flat (lily pads)")
		_check(code.contains("uniform float shallow"), "shallow must be a float uniform")
	var bed := load(DIR + "riverbed.gdshader") as Shader
	_check(bed != null, "riverbed.gdshader missing")
	if bed:
		var names2 := _uniforms(bed)
		for n: String in BED_UNIFORMS:
			_check(names2.has(n), "riverbed.gdshader lacks uniform %s" % n)


func _check_materials() -> void:
	var wm := load(DIR + "water_mat.tres") as ShaderMaterial
	_check(wm != null and wm.shader != null and wm.shader.resource_path.ends_with("water.gdshader"), "water_mat.tres")
	if wm:
		_check(is_equal_approx(float(wm.get_shader_parameter(&"shallow")), 0.0), "water_mat shallow must be 0")
		_check(float(wm.get_shader_parameter(&"flow_speed")) > 0.0, "water_mat flow_speed")
		_check(wm.get_shader_parameter(&"noise_tex") is Texture2D, "water_mat noise_tex")
	var fm := load(DIR + "water_ford_mat.tres") as ShaderMaterial
	_check(fm != null and fm.shader == (wm.shader if wm else null), "water_ford_mat.tres must share water.gdshader")
	if fm:
		_check(is_equal_approx(float(fm.get_shader_parameter(&"shallow")), 1.0), "water_ford_mat shallow must be 1")
	var bm := load(DIR + "riverbed_mat.tres") as ShaderMaterial
	_check(bm != null and bm.shader != null and bm.shader.resource_path.ends_with("riverbed.gdshader"), "riverbed_mat.tres")
	if bm:
		_check(is_equal_approx(float(bm.get_shader_parameter(&"water_y")), -0.35), "riverbed water_y must be -0.35")


func _check_ripple() -> void:
	var tex := load(DIR + "wade_ripple_tex.res") as Texture2D
	_check(tex != null and tex.get_width() == 128, "wade_ripple_tex.res missing or not 128 px")
	if tex:
		var img: Image = tex.get_image()
		var a_mid: float = img.get_pixel(64, 64).a
		var a_ring: float = 0.0
		for x in range(100, 120):
			a_ring = maxf(a_ring, img.get_pixel(x, 64).a)
		_check(a_mid < 0.1 and a_ring > 0.5, "ripple should be a ring (centre %.2f, ring %.2f)" % [a_mid, a_ring])
	var mat := load(DIR + "wade_ripple_mat.tres") as StandardMaterial3D
	_check(mat != null and mat.albedo_texture != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
			and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "wade_ripple_mat.tres")


func _check_meshes() -> void:
	var wm: GDScript = load(DIR + "water_meshes.gd")
	_check(wm != null, "water_meshes.gd missing")
	if wm == null:
		return
	var path := PackedVector2Array([Vector2(-9, -38), Vector2(-8, -30), Vector2(-5, -21)])
	var surf: ArrayMesh = wm.channel_surface(path, 2.5)
	_check(surf != null and surf.get_surface_count() == 1, "channel_surface")
	if surf and surf.get_surface_count() == 1:
		var arr: Array = surf.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var min_u := INF
		var max_u := -INF
		var ok_y := true
		for i in verts.size():
			ok_y = ok_y and is_equal_approx(verts[i].y, -0.35)
			min_u = minf(min_u, uvs[i].x)
			max_u = maxf(max_u, uvs[i].x)
			_check(uvs[i].y >= -0.001 and uvs[i].y <= 1.001, "UV.y out of 0..1")
			# Bank vertices sit exactly half a width from the centre line (the ground cut).
			var d: float = wm.distance_to_path(path, Vector2(verts[i].x, verts[i].z))
			if absf(d - 2.5) > 0.02:
				_check(false, "surface vertex %d is %.3f m from the centre line" % [i, d])
				break
		_check(ok_y, "water surface must be flat at y -0.35")
		var length: float = path[0].distance_to(path[1]) + path[1].distance_to(path[2])
		_check(absf(min_u) < 0.001 and absf(max_u - length) < 0.01, "UV.x must be metres along (%.2f..%.2f, len %.2f)" % [min_u, max_u, length])
		_check(surf.surface_get_material(0) != null and surf.surface_get_material(0).resource_path.ends_with("water_mat.tres"),
				"channel_surface must use water_mat.tres")
	var walls: ArrayMesh = wm.channel_walls(path, 2.5)
	_check(walls != null and walls.get_surface_count() == 1, "channel_walls")
	if walls and walls.get_surface_count() == 1:
		var box: AABB = walls.get_aabb()
		_check(is_equal_approx(box.end.y, 0.0) and box.position.y < -0.35, "walls must span the lip down under the water")
		_check(walls.surface_get_material(0).resource_path.ends_with("riverbed_mat.tres"), "walls must use riverbed_mat.tres")
	var film: ArrayMesh = wm.ford_film(path, 2.5, Vector2(-8.5, -34), 3.5)
	_check(film != null and film.get_surface_count() == 1, "ford_film")
	if film and film.get_surface_count() == 1:
		_check(film.surface_get_material(0).resource_path.ends_with("water_ford_mat.tres"), "film must use water_ford_mat.tres")
		for v: Vector3 in (film.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			if Vector2(v.x, v.z).distance_to(Vector2(-8.5, -34)) > 3.52:
				_check(false, "film vertex outside the ford circle")
				break
	# Triangle budget for the whole map (map-fill.md 9: <= 6 000): both rivers (N0-N5 mirrored), the moat in two
	# halves, 4 fords with their end walls.
	var north := PackedVector2Array([Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38), Vector2(-8, -30),
		Vector2(-5, -21), Vector2(-2.5, -12.5)])
	var ring: PackedVector2Array = wm.arc_path(Vector2.ZERO, 12.75, 0.0, 360.0)
	var half: PackedVector2Array = wm.arc_path(Vector2.ZERO, 12.75, 258.69, 78.69)
	var tris := 0
	for m: ArrayMesh in [wm.channel_surface(north, 2.5), wm.channel_walls(north, 2.5), wm.channel_surface(half, 1.75),
			wm.ford_film(north, 2.5, Vector2(-8.5, -34), 3.5), wm.ford_end_walls(north, 2.5, Vector2(-8.5, -34), 3.5),
			wm.ford_film(half, 1.75, Vector2(-9.02, -9.02), 3.0), wm.ford_end_walls(ring, 1.75, Vector2(-9.02, -9.02), 3.0)]:
		tris += m.surface_get_array_index_len(0) / 3 * 2   # x2: the mirrored half
	var moat_walls: ArrayMesh = wm.channel_walls(ring, 1.75)
	tris += moat_walls.surface_get_array_index_len(0) / 3
	print("  whole-map water + trench triangles: %d" % tris)
	_check(tris <= 6000, "water + trench triangles %d > 6000" % tris)
