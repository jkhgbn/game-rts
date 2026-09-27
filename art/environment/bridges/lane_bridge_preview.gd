extends SceneTree
## Task 12.V3 screenshots: the two Crown Bridges on a stand-in Crown Isle, seen from the game camera
## (RTSCamera: pitch 55, fov 50). Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/bridges/lane_bridge_preview.gd
##       --resolution 1600x900 --quit-after 3000 -- tag=v1
## Saves docs/art/screens/lane_bridge_<shot>.png (+ "_<tag>" when tag is given) and prints the render stats.
## Stand-ins (until 12.V1 / 12.V2 / 12.C1 land): the ground mesh has the moat cut out (r 11.0-14.5), a trench
## (walls to the bed at y -1.0) and a flat teal water ring at y -0.35. The real water / riverbed materials are
## used instead when art/environment/water/water_mat.tres / riverbed_mat.tres exist. The crown altar, the pillar
## ring (r 8) and a few Fire soldiers (scale) complete the scene.

const BRIDGE := "res://art/environment/bridges/lane_bridge.tscn"
const WATER_MAT := "res://art/environment/water/water_mat.tres"
const RIVERBED_MAT := "res://art/environment/water/riverbed_mat.tres"
const MOAT_R := 12.75
const WATER_IN := 11.0
const WATER_OUT := 14.5
const WATER_Y := -0.35
const BED_Y := -1.0
const WEST := Vector3(-9.02, 0.0, 9.02)
const EAST := Vector3(9.02, 0.0, -9.02)

var _tag := ""
var _only := ""
var _rig: Node3D


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_run()


func _wanted(shot: String) -> bool:
	return _only == "" or _only.split(",").has(shot)


func _run() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	_build_ground(stage)
	_build_trench(stage)
	var ped: PackedScene = load("res://art/environment/crown_pedestal.tscn") as PackedScene
	if ped:
		stage.add_child(ped.instantiate())
	_add_pillars(stage)
	for c: Vector3 in [WEST, EAST]:
		var b: Node3D = (load(BRIDGE) as PackedScene).instantiate() as Node3D
		stage.add_child(b)
		b.call(&"place_on_moat", c, Vector3.ZERO)
	_add_units(stage)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	stage.add_child(_rig)
	for i: int in 5:
		await process_frame
	var shots: Array = [
		["z30_west", 30.0, WEST + Vector3(0, 0, 1.0)],
		["z18_west", 18.0, WEST + Vector3(0.3, 0, 0.6)],
		["z11_west_face", 11.0, WEST + Vector3(2.2, 0, 2.6)],
		["z24_east", 24.0, EAST + Vector3(0, 0, 0.8)],
		["z55_isle", 55.0, Vector3(0, 0, 2.0)],
		# Not the game camera: a low side view straight at the west bridge's +X arch face (checks the arches).
		["z6_face_zoom", 6.0, WEST + Vector3(0.707, 0, 0.707) * 4.6 + Vector3(-0.707, 0, 0.707) * -0.66],
		["side_face", 9.0, WEST + Vector3(0.707, 0, 0.707) * 4.3 + Vector3(-0.707, 0, 0.707) * -0.66, PI / 4.0, 16.0],
	]
	for s: Array in shots:
		if _wanted(s[0]):
			_rig.rotation.y = float(s[3]) if s.size() > 3 else 0.0
			_rig.set(&"pitch_degrees", float(s[4]) if s.size() > 4 else 55.0)
			await _shoot(s[0], s[1], s[2])
	print("SHOTS DONE")
	quit()


func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.call(&"focus_on", focus)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var gpu := 0.0
	for i: int in frames:
		await process_frame
		if i >= frames - 20:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp) / 20.0
	await RenderingServer.frame_post_draw
	var draws: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var img: Image = root.get_texture().get_image()
	var path := "res://docs/art/screens/lane_bridge_%s%s.png" % [shot, ("_" + _tag) if _tag != "" else ""]
	img.save_png(ProjectSettings.globalize_path(path))
	print("shot %-14s draws=%d prims=%d gpu_ms=%.2f" % [shot, draws, prims, gpu])


## The painted ground (ground_material.tres: lane, crown plaza) as a polar mesh with the moat cut out.
func _build_ground(stage: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides: int = 160
	var radii: Array[float] = [0.0, 3.0, 6.0, 9.0, WATER_IN]
	var outer: Array[float] = [WATER_OUT, 17.0, 21.0, 26.0, 33.0, 42.0, 55.0, 75.0, 110.0]
	for ring: Array[float] in [radii, outer]:
		for i: int in ring.size() - 1:
			for j: int in sides:
				var a0: float = j * TAU / sides
				var a1: float = (j + 1) * TAU / sides
				var p00 := Vector3(cos(a0) * ring[i], 0, sin(a0) * ring[i])
				var p01 := Vector3(cos(a1) * ring[i], 0, sin(a1) * ring[i])
				var p10 := Vector3(cos(a0) * ring[i + 1], 0, sin(a0) * ring[i + 1])
				var p11 := Vector3(cos(a1) * ring[i + 1], 0, sin(a1) * ring[i + 1])
				_emit(st, p00, p11, p10, Vector3.UP)
				_emit(st, p00, p01, p11, Vector3.UP)
	st.index()
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = st.commit()
	var gm: Material = load("res://art/environment/ground_material.tres") as Material
	if gm is ShaderMaterial:
		gm = (gm as ShaderMaterial).duplicate()
		(gm as ShaderMaterial).set_shader_parameter(&"expand_edge", false)
	mi.material_override = gm
	stage.add_child(mi)


## Stand-in trench (walls + bed, wet dark rock) and the water ring at y -0.35.
func _build_trench(stage: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides: int = 160
	for j: int in sides:
		var a0: float = j * TAU / sides
		var a1: float = (j + 1) * TAU / sides
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		# Inner wall (faces outward, +r), outer wall (faces inward), bed (up). A 0.35 m sloped lip at the top.
		_wall_quad(st, d0, d1, WATER_IN, WATER_IN + 0.12, 0.0, -0.35, 1.0)
		_wall_quad(st, d0, d1, WATER_IN + 0.12, WATER_IN + 0.18, -0.35, BED_Y, 1.0)
		_wall_quad(st, d0, d1, WATER_OUT, WATER_OUT - 0.12, 0.0, -0.35, -1.0)
		_wall_quad(st, d0, d1, WATER_OUT - 0.12, WATER_OUT - 0.18, -0.35, BED_Y, -1.0)
		var bed := Vector3(0, BED_Y, 0)
		_emit(st, d0 * (WATER_IN + 0.18) + bed, d1 * (WATER_OUT - 0.18) + bed, d0 * (WATER_OUT - 0.18) + bed, Vector3.UP)
		_emit(st, d0 * (WATER_IN + 0.18) + bed, d1 * (WATER_IN + 0.18) + bed, d1 * (WATER_OUT - 0.18) + bed, Vector3.UP)
	st.index()
	var trench := MeshInstance3D.new()
	trench.name = "TrenchStandIn"
	trench.mesh = st.commit()
	if ResourceLoader.exists(RIVERBED_MAT):
		trench.material_override = load(RIVERBED_MAT) as Material
	else:
		var tm := StandardMaterial3D.new()
		tm.albedo_color = Color(0.22, 0.19, 0.15)
		tm.roughness = 1.0
		trench.material_override = tm
	stage.add_child(trench)
	# Water ring.
	var ws := SurfaceTool.new()
	ws.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j: int in sides:
		var a0: float = j * TAU / sides
		var a1: float = (j + 1) * TAU / sides
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var u0: float = float(j) / sides * TAU * MOAT_R
		var u1: float = float(j + 1) / sides * TAU * MOAT_R
		var wy := Vector3(0, WATER_Y, 0)
		_emit(ws, d0 * WATER_IN + wy, d1 * WATER_OUT + wy, d0 * WATER_OUT + wy, Vector3.UP,
				[Vector2(u0, 0), Vector2(u1, 1), Vector2(u0, 1)])
		_emit(ws, d0 * WATER_IN + wy, d1 * WATER_IN + wy, d1 * WATER_OUT + wy, Vector3.UP,
				[Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1)])
	ws.index()
	var water := MeshInstance3D.new()
	water.name = "WaterStandIn"
	water.mesh = ws.commit()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if ResourceLoader.exists(WATER_MAT):
		water.material_override = load(WATER_MAT) as Material
	else:
		var wm := StandardMaterial3D.new()
		wm.albedo_color = Color(0.13, 0.33, 0.33)
		wm.roughness = 0.35
		wm.metallic_specular = 0.6
		water.material_override = wm
	stage.add_child(water)


func _wall_quad(st: SurfaceTool, d0: Vector3, d1: Vector3, r_top: float, r_bot: float, y_top: float, y_bot: float,
		face: float) -> void:
	var a: Vector3 = d0 * r_top + Vector3(0, y_top, 0)
	var b: Vector3 = d1 * r_top + Vector3(0, y_top, 0)
	var c: Vector3 = d1 * r_bot + Vector3(0, y_bot, 0)
	var d: Vector3 = d0 * r_bot + Vector3(0, y_bot, 0)
	var n: Vector3 = ((d0 + d1) * 0.5 * face).normalized()
	_emit(st, a, b, c, n)
	_emit(st, a, c, d, n)


var _conv := 0.0


## One triangle, wound so that its front face points along n (Godot's winding detected from a BoxMesh).
func _emit(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, uvs: Array = []) -> void:
	if _conv == 0.0:
		var arr: Array = BoxMesh.new().get_mesh_arrays()
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		_conv = 1.0 if (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]]).dot(nn[idx[0]]) >= 0.0 else -1.0
	var pts: Array = [a, b, c]
	var uv: Array = uvs if uvs.size() == 3 else [Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)]
	var sg: float = 1.0 if (b - a).cross(c - a).dot(n) >= 0.0 else -1.0
	if sg != _conv:
		pts = [a, c, b]
		uv = [uv[0], uv[2], uv[1]]
	for i: int in 3:
		st.set_normal(n)
		st.set_uv(uv[i])
		st.add_vertex(pts[i])


func _add_pillars(stage: Node3D) -> void:
	var mesh: Mesh = load("res://art/environment/meshes/ruin_pillar.res") as Mesh
	if mesh == null:
		return
	var heights: Array[float] = [3.4, 2.4, 4.2, 2.9, 0.0]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 8
	var n: int = 0
	for i: int in 5:
		if i == 4:
			continue
		for k: int in [i, i + 5]:
			var a: float = float(k) * TAU / 10.0
			var pos := Vector3(cos(a) * 8.0, 0, sin(a) * 8.0)
			mm.set_instance_transform(n, Transform3D(Basis(Vector3.UP, float(k) * 1.7).scaled(Vector3(1, heights[i] / 3.0, 1)), pos))
			n += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	stage.add_child(mmi)


## A few Fire soldiers on / by the west bridge for scale.
func _add_units(stage: Node3D) -> void:
	var path := "res://art/units/fire/flame_guard.tscn"
	if not ResourceLoader.exists(path):
		return
	var ps: PackedScene = load(path) as PackedScene
	var out: Vector3 = WEST.normalized()
	var side := Vector3(out.z, 0, -out.x)
	var spots: Array = [WEST + out * 1.4 + side * 1.2, WEST - out * 0.6 - side * 1.6, WEST + out * 4.4 - side * 0.4]
	for i: int in spots.size():
		var u: Node3D = ps.instantiate() as Node3D
		stage.add_child(u)
		u.position = spots[i]   # the stage sits at the origin
		u.rotation.y = atan2(-out.x, -out.z) + (i - 1) * 0.4
