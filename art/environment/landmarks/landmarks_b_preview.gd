extends SceneTree
## Task 12.V14 screenshots: the Old Aqueduct, the Drowned Barge and the Standing Stones at their real map spots, on a
## staged north river (a trench heightfield with riverbed_mat + a water strip with water_mat and the landmarks'
## foam_rocks), warm lighting rig, game camera (pitch 55, fov 50), Flame Guards for scale. Windowed only:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/landmarks/landmarks_b_preview.gd
##       --resolution 1600x900 --quit-after 9000
## Saves docs/art/screens/landmark_b_<shot>.png; `only=<shot>,<shot>` limits the shots. Shots named *_back_* look from
## the north (camera turned 180 deg): that is how the point-mirrored copy on the enemy half shows to the player.
## sil_* shots: unshaded black silhouettes on white (art-keep.md 0.1 silhouette test).

const LDIR := "res://art/environment/landmarks/"
const RIVER_N: Array[Vector2] = [Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38), Vector2(-8, -30), Vector2(-5, -21),
	Vector2(-2.5, -12.5)]
const HALF_W := 2.5
const SPOTS := {
	"aqueduct": Vector3(-13.4, 0.0, -55.0),
	"barge": Vector3(-6.2, 0.0, -24.5),
	"standing_stones": Vector3(-54.0, 0.0, 20.0),
}

var _only := ""
var _rig: Node3D
var _stage: Node3D
var _conv := 1.0
var _landmarks: Array[Node3D] = []
var _hide_for_sil: Array[Node3D] = []
var _env: Environment


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	_conv = 1.0 if (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]]).dot(n[idx[0]]) >= 0.0 else -1.0
	_run()


func _wanted(shot: String) -> bool:
	return _only == "" or _only.split(",").has(shot)


func _run() -> void:
	_stage = Node3D.new()
	_stage.name = "Stage"
	root.add_child(_stage)
	current_scene = _stage
	var light: Node3D = (load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new()
	_stage.add_child(light)
	# Ground: a heightfield with the river trench around the north river, a flat plane elsewhere.
	var gm: ShaderMaterial = (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate()
	gm.set_shader_parameter(&"lane_a", Vector2(500, 500))
	gm.set_shader_parameter(&"lane_b", Vector2(501, 501))
	for i in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	var bed: Material = load("res://art/environment/water/riverbed_mat.tres")
	var river_ground := _river_ground(Rect2(-42.0, -66.0, 58.0, 60.0), 0.3, gm, bed)
	_stage.add_child(river_ground)
	_hide_for_sil.append(river_ground)
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	pm.subdivide_width = 6
	pm.subdivide_depth = 6
	plane.mesh = pm
	plane.material_override = gm
	plane.position = Vector3(-50, 0, 25)
	_stage.add_child(plane)
	_hide_for_sil.append(plane)
	# The landmarks at their spots.
	var foam := PackedVector4Array()
	for id: String in SPOTS:
		var ps := load(LDIR + id + ".tscn") as PackedScene
		var lm := ps.instantiate() as Node3D
		lm.position = SPOTS[id]
		_stage.add_child(lm)
		_landmarks.append(lm)
		var fr: PackedVector3Array = lm.get_meta(&"foam_rocks", PackedVector3Array())
		for f: Vector3 in fr:
			var wp: Vector3 = lm.transform * Vector3(f.x, 0.0, f.y)
			foam.append(Vector4(wp.x, wp.z, f.z, 0.0))
		print("landmark %-16s tris %d, surfaces %d, colliders %d" % [id, _tris((lm.get_node("Model") as MeshInstance3D).mesh),
			(lm.get_node("Model") as MeshInstance3D).mesh.get_surface_count(),
			lm.get_node("Collision").get_child_count() if lm.has_node("Collision") else 0])
	# Water strip with the landmarks' foam circles.
	var wm: ShaderMaterial = (load("res://art/environment/water/water_mat.tres") as ShaderMaterial).duplicate()
	var fa: Array[Vector4] = []
	for f4: Vector4 in foam:
		fa.append(f4)
	while fa.size() < 16:
		fa.append(Vector4.ZERO)
	wm.set_shader_parameter(&"foam_rocks", fa)
	wm.set_shader_parameter(&"foam_rock_count", foam.size())
	var water := _water_strip(wm)
	_stage.add_child(water)
	_hide_for_sil.append(water)
	# Flame Guards for scale (and to check nothing hides them).
	if ResourceLoader.exists("res://art/units/fire/flame_guard.tscn"):
		var fg := load("res://art/units/fire/flame_guard.tscn") as PackedScene
		for p: Vector3 in [Vector3(-19.6, 0, -54.2), Vector3(-19.0, 0, -56.8), Vector3(-7.6, 0, -53.6), Vector3(-17.4, 0, -52.4),
				Vector3(-9.6, 0, -57.3), Vector3(-9.8, 0, -24.0), Vector3(-2.7, 0, -25.8), Vector3(-54.3, 0, 20.9),
				Vector3(-50.2, 0, 23.4), Vector3(-57.8, 0, 17.6), Vector3(-52.6, 0, 16.4)]:
			var u := fg.instantiate() as Node3D
			_stage.add_child(u)
			u.position = p
			u.rotation.y = p.x * 0.7
			_hide_for_sil.append(u)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_stage.add_child(_rig)
	for i in 5:
		await process_frame
	var we: WorldEnvironment = null
	for n: Node in _stage.find_children("*", "WorldEnvironment", true, false):
		we = n as WorldEnvironment
	_env = we.environment if we else null
	var shots: Array = [
		["aqueduct_z14", 14.0, Vector3(-13.4, 0, -53.2), 0.0],
		["aqueduct_z24", 24.0, Vector3(-13.4, 0, -52.0), 0.0],
		["aqueduct_z40", 40.0, Vector3(-13.4, 0, -48.0), 0.0],
		["aqueduct_back_z24", 24.0, Vector3(-13.4, 0, -57.0), PI],
		["barge_z12", 12.0, Vector3(-6.2, 0, -23.6), 0.0],
		["barge_z24", 24.0, Vector3(-6.2, 0, -22.5), 0.0],
		["barge_back_z14", 14.0, Vector3(-6.2, 0, -25.4), PI],
		["stones_z12", 12.0, Vector3(-54.0, 0, 21.2), 0.0],
		["stones_z24", 24.0, Vector3(-54.0, 0, 22.0), 0.0],
		["stones_z40", 40.0, Vector3(-54.0, 0, 25.0), 0.0],
		["stones_back_z24", 24.0, Vector3(-54.0, 0, 18.0), PI],
		["stones_runes_z8", 8.0, Vector3(-53.2, 0, 20.8), 0.0],
	]
	for s: Array in shots:
		if _wanted(s[0]):
			await _shoot(s[0], s[1], s[2], s[3])
	# Silhouettes: black unshaded on white, at 40 m.
	var sil_shots: Array = [["sil_aqueduct_z40", 40.0, Vector3(-13.4, 0, -48.0)], ["sil_barge_z40", 40.0, Vector3(-6.2, 0, -18.0)],
		["sil_stones_z40", 40.0, Vector3(-54.0, 0, 25.0)]]
	var any := false
	for s2: Array in sil_shots:
		any = any or _wanted(s2[0])
	if any:
		_silhouette_mode()
		for s3: Array in sil_shots:
			if _wanted(s3[0]):
				await _shoot(s3[0], s3[1], s3[2], 0.0)
	print("SHOTS DONE")
	quit()


func _shoot(shot: String, zoom: float, focus: Vector3, yaw: float, frames: int = 45) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.rotation.y = yaw
	_rig.call(&"focus_on", focus)
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/landmark_b_%s.png" % shot))
	print("shot %-20s draws=%d prims=%d" % [shot, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])


func _silhouette_mode() -> void:
	for n: Node3D in _hide_for_sil:
		n.visible = false
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var clear := StandardMaterial3D.new()
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.albedo_color = Color(1, 1, 1, 0)
	for lm: Node3D in _landmarks:
		var mi := lm.get_node("Model") as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(s)
			var is_contact: bool = m != null and m.resource_path.contains("contact")
			mi.set_surface_override_material(s, clear if is_contact else black)
	if _env:
		_env.background_mode = Environment.BG_COLOR
		_env.background_color = Color.WHITE
		_env.fog_enabled = false
		_env.glow_enabled = false
		_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		_env.adjustment_enabled = false
	for c: Node in _stage.find_children("*", "CanvasLayer", true, false):
		(c as CanvasLayer).visible = false


func _tris(mesh: Mesh) -> int:
	var t := 0
	for s in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		t += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return t


# ---------------------------------------------------------------- staged river

func _river_dist(p: Vector2) -> float:
	var best := INF
	for i in RIVER_N.size() - 1:
		var a: Vector2 = RIVER_N[i]
		var b: Vector2 = RIVER_N[i + 1]
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


func _height(x: float, z: float) -> float:
	var d: float = _river_dist(Vector2(x, z))
	return -1.0 + smoothstep(HALF_W - 0.35, HALF_W + 0.05, d)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if (1.0 if fn.y >= 0.0 else -1.0) != _conv:
		var t: Vector3 = b
		b = c
		c = t
		var tn: Vector3 = nb
		nb = nc
		nc = tn
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)


func _river_ground(r: Rect2, cell: float, land: Material, bed: Material) -> MeshInstance3D:
	var nx: int = int(r.size.x / cell)
	var nz: int = int(r.size.y / cell)
	var hs: Array[PackedFloat32Array] = []
	for j in nz + 1:
		var row := PackedFloat32Array()
		for i in nx + 1:
			row.append(_height(r.position.x + i * cell, r.position.y + j * cell))
		hs.append(row)
	var st_land := SurfaceTool.new()
	var st_bed := SurfaceTool.new()
	st_land.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_bed.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in nz:
		for i in nx:
			var p: Array[Vector3] = []
			var nn: Array[Vector3] = []
			for q: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var y: float = hs[q.y][q.x]
				p.append(Vector3(r.position.x + q.x * cell, y, r.position.y + q.y * cell))
				var hl: float = hs[q.y][maxi(q.x - 1, 0)]
				var hr: float = hs[q.y][mini(q.x + 1, nx)]
				var hd: float = hs[maxi(q.y - 1, 0)][q.x]
				var hu: float = hs[mini(q.y + 1, nz)][q.x]
				nn.append(Vector3(hl - hr, 2.0 * cell, hd - hu).normalized())
			var low: bool = false
			for pp: Vector3 in p:
				if pp.y < -0.02:
					low = true
			var st: SurfaceTool = st_bed if low else st_land
			_tri(st, p[0], p[1], p[2], nn[0], nn[1], nn[2])
			_tri(st, p[0], p[2], p[3], nn[0], nn[2], nn[3])
	var mesh := ArrayMesh.new()
	st_land.commit(mesh)
	mesh.surface_set_material(0, land)
	st_bed.commit(mesh)
	mesh.surface_set_material(1, bed)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	return mi


func _water_strip(m: Material) -> MeshInstance3D:
	# Resample the polyline every 0.5 m; UV.x = metres along (downstream), UV.y 0 (west bank) -> 1 (east bank).
	var pts: Array[Vector2] = []
	for i in RIVER_N.size() - 1:
		var a: Vector2 = RIVER_N[i]
		var b: Vector2 = RIVER_N[i + 1]
		var steps: int = maxi(1, int(a.distance_to(b) / 0.5))
		for k in steps:
			pts.append(a.lerp(b, float(k) / steps))
	pts.append(RIVER_N[RIVER_N.size() - 1])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := 0.0
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_u := 0.0
	for i in pts.size():
		var t: Vector2 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var nrm := Vector2(t.y, -t.x)   # points west-ish for a southward flow
		var l := Vector3(pts[i].x + nrm.x * HALF_W, -0.35, pts[i].y + nrm.y * HALF_W)
		var rr := Vector3(pts[i].x - nrm.x * HALF_W, -0.35, pts[i].y - nrm.y * HALF_W)
		if i > 0:
			along += pts[i].distance_to(pts[i - 1])
			for tri: Array in [[prev_l, prev_r, rr, Vector2(prev_u, 0), Vector2(prev_u, 1), Vector2(along, 1)],
					[prev_l, rr, l, Vector2(prev_u, 0), Vector2(along, 1), Vector2(along, 0)]]:
				var a3: Vector3 = tri[0]
				var b3: Vector3 = tri[1]
				var c3: Vector3 = tri[2]
				var ua: Vector2 = tri[3]
				var ub: Vector2 = tri[4]
				var uc: Vector2 = tri[5]
				if (1.0 if (b3 - a3).cross(c3 - a3).y >= 0.0 else -1.0) != _conv:
					var tv: Vector3 = b3
					b3 = c3
					c3 = tv
					var tu: Vector2 = ub
					ub = uc
					uc = tu
				for pair: Array in [[a3, ua], [b3, ub], [c3, uc]]:
					st.set_normal(Vector3.UP)
					st.set_uv(pair[1])
					st.add_vertex(pair[0])
		prev_l = l
		prev_r = rr
		prev_u = along
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
