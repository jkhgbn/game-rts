extends SceneTree
## Task 12.V7 screenshots: a riverbank strip (a 5 m river cut into the ground, both banks dressed from
## riverbank_set.gd ENTRIES with a small stand-in of the 12.V6 scatter, willows on the banks) + lineups.
## Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/biomes/riverbank/riverbank_preview.gd
##       --resolution 1600x900 --quit-after 6000
## Saves docs/art/screens/riverbank_<shot>.png (+ biome_riverbank.png = the game-camera strip) and prints render
## stats. `only=<shot>,<shot>` limits the shots. Water: art/environment/water/water_mat.tres when it exists (12.V1),
## else a flat painted stand-in (preview only).

const SET_PATH := "res://art/environment/biomes/riverbank/riverbank_set.gd"
const MESH_DIR := "res://art/environment/meshes/"
const RB := "res://art/environment/biomes/riverbank/"
const WATER_MAT := "res://art/environment/water/water_mat.tres"
const RIVERBED_MAT := "res://art/environment/water/riverbed_mat.tres"
const HALF_W := 2.5
const STRIP_X := Vector2(-40.0, 33.0)   ## scattered stretch; x > 35 holds the lily-pad lineup on the water

var _rig: Node3D
var _stage: Node3D
var _only := ""
var _rng := RandomNumberGenerator.new()
var _willows: Array[Vector3] = []
var _lists := {}   # "mesh|shadow|range" -> Array[Transform3D]
var _count := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_rng.seed = 12007
	_run()


func _wanted(shot: String) -> bool:
	return _only == "" or _only.split(",").has(shot)


# ---------------------------------------------------------------- stage

func _run() -> void:
	_stage = Node3D.new()
	_stage.name = "Stage"
	root.add_child(_stage)
	current_scene = _stage
	_stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	_build_ground()
	_build_river()
	_place_willows()
	_scatter()
	_lineups()
	_commit()
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 5.0)
	_stage.add_child(_rig)
	print("riverbank preview: %d decor instances on a %.0f m strip" % [_count, STRIP_X.y - STRIP_X.x])
	for i in 5:
		await process_frame
	var shots: Array = [
		["strip_z40", 40.0, Vector3(-4, 0, 2), 0.0],
		["strip_z24", 24.0, Vector3(-16, 0, 1), 0.0],
		["strip_z24_side", 24.0, Vector3(6, 0, 0), 0.9],
		["willow_close", 12.0, _willows[1] + Vector3(0.5, 0, -1.8), 0.0],
		["bank_close", 7.0, Vector3(-30, 0, 1.2), 0.35],
		["lineup", 13.0, Vector3(-5.5, 0, 16.5), 0.0],
		["lineup_close", 6.0, Vector3(-11.5, 0, 16.3), 0.0],
		["lily_lineup", 6.5, Vector3(40.0, 0, 0.5), 0.0],
		["trees_z40", 40.0, Vector3(0, 0, -24), 0.0],
		["trees_z16", 16.0, Vector3(0, 0, -25), 0.0],
	]
	for s: Array in shots:
		if _wanted(s[0]):
			await _shoot(s[0], s[1], s[2], s[3])
	await _wind_check()
	print("SHOTS DONE")
	quit()


func _ground_mat() -> Material:
	var gm: Material = load("res://art/environment/ground_material.tres")
	if gm is ShaderMaterial:
		gm = (gm as ShaderMaterial).duplicate()
		(gm as ShaderMaterial).set_shader_parameter(&"lane_a", Vector2(500, 500))
		(gm as ShaderMaterial).set_shader_parameter(&"lane_b", Vector2(501, 501))
		for i in 4:
			(gm as ShaderMaterial).set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	return gm


func _build_ground() -> void:
	var gm: Material = _ground_mat()
	for side: int in 2:
		var sgn: float = -1.0 if side == 0 else 1.0
		var g := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(100, 50.0 - HALF_W)
		plane.subdivide_width = 8
		plane.subdivide_depth = 4
		g.mesh = plane
		g.position = Vector3(0, 0, sgn * (HALF_W + (50.0 - HALF_W) * 0.5))
		g.material_override = gm
		_stage.add_child(g)


func _build_river() -> void:
	# Trench: two sloped walls (ground edge y 0 at |z| 2.5 -> bed y -1.0 at |z| 1.9) + the bed.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: int in 2:
		var s: float = -1.0 if side == 0 else 1.0
		var a := Vector3(-50, 0.0, s * HALF_W)
		var b := Vector3(50, 0.0, s * HALF_W)
		var c := Vector3(50, -1.0, s * 1.9)
		var d := Vector3(-50, -1.0, s * 1.9)
		var quad: Array = [a, b, c, a, c, d] if side == 1 else [a, c, b, a, d, c]
		for p: Vector3 in quad:
			st.add_vertex(p)
	for p2: Vector3 in [Vector3(-50, -1, -1.9), Vector3(50, -1, -1.9), Vector3(50, -1, 1.9), Vector3(-50, -1, -1.9),
			Vector3(50, -1, 1.9), Vector3(-50, -1, 1.9)]:
		st.add_vertex(p2)
	st.generate_normals()
	st.index()
	var trench := MeshInstance3D.new()
	trench.mesh = st.commit()
	var bed: Material = load(RIVERBED_MAT) if ResourceLoader.exists(RIVERBED_MAT) else null
	if bed == null:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.20, 0.17, 0.12)
		sm.roughness = 1.0
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		bed = sm
	trench.material_override = bed
	_stage.add_child(trench)
	# Water strip in the 12.V1 convention: UV.x = metres along the flow (+x), UV.y = 0 -> 1 bank to bank.
	var ws := SurfaceTool.new()
	ws.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 50:
		var x0: float = -50.0 + i * 2.0
		var x1: float = x0 + 2.0
		var q: Array = [[x0, -HALF_W, 0.0], [x1, -HALF_W, 0.0], [x1, HALF_W, 1.0], [x0, -HALF_W, 0.0], [x1, HALF_W, 1.0],
			[x0, HALF_W, 1.0]]
		for c: Array in q:
			ws.set_normal(Vector3.UP)
			ws.set_uv(Vector2(float(c[0]) + 50.0, float(c[2])))
			ws.add_vertex(Vector3(c[0], 0.0, c[1]))
	ws.index()
	var water := MeshInstance3D.new()
	water.mesh = ws.commit()
	water.position = Vector3(0, -0.35, 0)
	var wm: Material = load(WATER_MAT) if ResourceLoader.exists(WATER_MAT) else null
	if wm == null:
		var sm2 := StandardMaterial3D.new()
		sm2.albedo_color = Color(0.12, 0.30, 0.30)
		sm2.roughness = 0.35
		sm2.metallic_specular = 0.3
		wm = sm2
	else:
		print("water: using ", WATER_MAT)
	water.material_override = wm
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stage.add_child(water)


## nature_painted.gdshader's hash1 (the shader picks the variant from it).
static func _hash1(p: Vector2) -> float:
	var p3 := Vector3(fposmod(p.x * 0.1031, 1.0), fposmod(p.y * 0.1031, 1.0), fposmod(p.x * 0.1031, 1.0))
	var d: float = p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	return fposmod((p3.x + p3.y) * p3.z, 1.0)


static func variant_at(pos: Vector3) -> int:
	return mini(int(floor(_hash1(Vector2(pos.z, pos.x) + Vector2(3.1, 7.7)) * 3.0)), 2)


func _find_variant(pos: Vector3, variant: int) -> Vector3:
	for i in 400:
		var p: Vector3 = pos + Vector3(fmod(i * 0.173, 1.2) - 0.6, 0.0, fmod(i * 0.311, 1.2) - 0.6)
		if variant_at(p) == variant:
			return p
	return pos


func _add(mesh: String, xf: Transform3D, shadow: bool, range_end: float) -> void:
	var key := "%s|%d|%d" % [mesh, 1 if shadow else 0, int(range_end)]
	if not _lists.has(key):
		_lists[key] = []
	(_lists[key] as Array).append(xf)
	_count += 1


## Yaw so local +X points at the water (the willow's lean axis).
func _toward_water(z: float) -> float:
	return -PI * 0.5 if z < 0.0 else PI * 0.5


func _place_willows() -> void:
	var spots: Array = [[Vector3(-26, 0, -5.2), 0, 1.05], [Vector3(-8, 0, 5.4), 1, 1.1], [Vector3(10, 0, -4.6), 2, 1.0],
		[Vector3(26, 0, 5.0), 0, 1.15]]
	for s: Array in spots:
		var p: Vector3 = _find_variant(s[0], s[1])
		_willows.append(p)
		var sc: float = s[2]
		_add(MESH_DIR + "tree_willow.res", Transform3D(Basis(Vector3.UP, _toward_water(p.z)).scaled(Vector3(sc, sc, sc)),
			p), true, 0.0)


func _blocked(x: float, z: float) -> bool:
	for w: Vector3 in _willows:
		if Vector2(x - w.x, z - w.z).length() < 1.0:
			return true
	return false


## A small stand-in of the 12.V6 scatter: per_100m2 x zone area, clumps by `cluster`.
func _scatter() -> void:
	var set_script: GDScript = load(SET_PATH)
	var entries: Array = set_script.get_script_constant_map()["ENTRIES"]
	var length: float = STRIP_X.y - STRIP_X.x
	for e: Dictionary in entries:
		var place: StringName = e["place"]
		var shore: float = e.get("shore", HALF_W)
		var area: float = 0.0
		match place:
			&"bank":
				area = 2.0 * length * 2.5
			&"land":
				area = 2.0 * length * 6.0
			&"water":
				area = 2.0 * length * minf(shore, HALF_W)
		var n: int = int(round(float(e["per_100m2"]) * area / 100.0))
		var sc: Vector2 = e["scale"]
		var cluster: float = e["cluster"]
		var y: float = e.get("y", 0.0)
		var last := Vector2.INF
		var placed := 0
		var tries := 0
		while placed < n and tries < n * 20:
			tries += 1
			var p: Vector2
			if last != Vector2.INF and _rng.randf() < cluster:
				p = last + Vector2(_rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.9, 0.9))
			else:
				var side: float = -1.0 if _rng.randf() < 0.5 else 1.0
				var d: float = 0.0
				match place:
					&"bank":
						d = HALF_W + _rng.randf_range(0.1, 2.5)
					&"land":
						d = HALF_W + _rng.randf_range(0.3, 6.0)
					&"water":
						d = HALF_W - _rng.randf_range(0.15, minf(shore, HALF_W - 0.3))
				p = Vector2(_rng.randf_range(STRIP_X.x, STRIP_X.y), side * d)
			var az: float = absf(p.y)
			var ok: bool = p.x > STRIP_X.x and p.x < STRIP_X.y
			match place:
				&"bank":
					ok = ok and az > HALF_W + 0.1 and az < HALF_W + 2.5
				&"land":
					ok = ok and az > HALF_W + 0.3 and az < HALF_W + 6.0
				&"water":
					ok = ok and az < HALF_W - 0.1 and az > HALF_W - shore
			if not ok or _blocked(p.x, p.y):
				continue
			last = p
			var s: float = _rng.randf_range(sc.x, sc.y)
			_add(e["mesh"], Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)),
				Vector3(p.x, y, p.y)), e["shadow"], e["range"])
			placed += 1
		print("entry %-18s %-6s %3d instances (%.0f m2)" % [String(e["mesh"]).get_file().get_basename(), place, placed,
			area])


func _lineups() -> void:
	# Decor lineup on the south field (z 16), 3 variants each; lily pads on the water at x 36-44.
	var names: Array[String] = ["rb_reeds", "rb_cattails", "rb_river_stones", "rb_driftwood"]
	for k in names.size():
		for i in 3:
			var pos: Vector3 = _find_variant(Vector3(-15.0 + k * 7.0 + (i - 1) * 2.3, 0.0, 16.0), i)
			_add(RB + names[k] + ".res", Transform3D(Basis(Vector3.UP, 0.4 + i * 1.7), pos), names[k] == "rb_driftwood",
				0.0)
	for i in 3:
		var lp: Vector3 = _find_variant(Vector3(37.5 + i * 2.6, 0.0, 0.3), i)
		_add(RB + "rb_lily_pads.res", Transform3D(Basis(Vector3.UP, 0.8 + i * 2.0), lp + Vector3(0, -0.35, 0)), false,
			0.0)
	# Trees for the "distinct at 40 m" check (north field, z -24): willow among the map's other trees.
	var trees: Array = [["tree_broadleaf", -14.0], ["tree_birch", -7.0], ["tree_willow", 0.0], ["tree_pine", 7.0],
		["tree_willow_far", 14.0]]
	for t: Array in trees:
		_add(MESH_DIR + String(t[0]) + ".res", Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(t[1], 0, -24.0)), true,
			0.0)
	for i in 3:
		var wp: Vector3 = _find_variant(Vector3(-8.0 + i * 8.0, 0.0, -33.0), i)
		_add(MESH_DIR + "tree_willow.res", Transform3D(Basis(Vector3.UP, -PI * 0.5), wp), true, 0.0)


func _commit() -> void:
	for key: String in _lists:
		var parts: PackedStringArray = key.split("|")
		var mesh := load(parts[0]) as Mesh
		var list: Array = _lists[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		if parts[1] == "0":
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var r: float = float(parts[2])
		if r > 0.0:
			mmi.visibility_range_end = r
			mmi.visibility_range_end_margin = 10.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		_stage.add_child(mmi)


# ---------------------------------------------------------------- shots

func _shoot(shot: String, zoom: float, focus: Vector3, yaw: float) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.rotation.y = yaw
	_rig.call(&"focus_on", focus)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var gpu := 0.0
	for i in 40:
		await process_frame
		if i >= 20:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp) / 20.0
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/riverbank_%s.png" % shot))
	if shot == "strip_z40":
		img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/biome_riverbank.png"))
	print("shot %-16s draws=%d prims=%d gpu_ms=%.2f fps=%d" % [shot,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), gpu, Engine.get_frames_per_second()])


## The same close frame 0.75 s apart must differ (reeds / willow curtain sway).
func _wind_check() -> void:
	_rig.rotation.y = 0.0
	_rig.call(&"focus_on", _willows[0])
	_rig.set(&"_target_zoom", 12.0)
	_rig.set(&"_zoom", 12.0)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var a: Image = root.get_texture().get_image()
	for i in 45:
		await process_frame
	await RenderingServer.frame_post_draw
	var b: Image = root.get_texture().get_image()
	var changed := 0
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.06:
				changed += 1
	print("wind check: %d of %d sampled pixels changed in 0.75 s" % [changed, (a.get_width() / 4) * (a.get_height() / 4)])
