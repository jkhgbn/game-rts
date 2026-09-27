extends SceneTree
## Previews of the terrain event effects (task 12b.V4, TerrainVfx). Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/terrain_vfx_preview.gd --resolution 1600x900
##       --fixed-fps 60 --quit-after 9000
## docs/art/screens/12b_v4_vfx_sequence.png: the warning / burn / strike sequence as a 3 x 4 contact sheet (RTS camera,
##   pitch 55, fov 50): wildfire warning (1 s, 8.7 s), burn (0.35 s, 3 s, 6.8 s), storm warning (2.5 s, 9.2 s on a flicker),
##   strike (0.03 s, 0.14 s, 0.9 s), scorch_spawn (0.12 s, 0.7 s). Soldiers stand in for scale.
## docs/art/screens/12b_v4_vfx_z40.png: a wildfire warning, a storm warning and a burn side by side at zoom 40 (the
##   "reads from 40 m" check). With `--all`: every cell full size, docs/art/screens/12b_v4_vfx_<n>.png.
## Prints the node's _process cost with the spec's worst case (2 pairs = 4 events + 8 scorches).

const CELL := Vector2i(640, 360)
const COLS := 3
const SPACING := 60.0
const DT := 1.0 / 60.0
const SOLDIER := "res://art/units/fire/flame_guard.tscn"
const SHADE := "res://art/units/shadow/shade.tscn"
## [id, shot time (s), zoom, focus height, label, lead-in (the warning played first, s; 0 = none)]
const SHOTS := [
	[&"wildfire_warning", 1.0, 22.0, 0.0, "wildfire_warning 1 s: ring r 4.5 + countdown, smoke rising", 0.0],
	[&"wildfire_warning", 8.7, 22.0, 0.0, "wildfire_warning 8.7 s: last seconds, sparks, thick smoke", 0.0],
	[&"wildfire_burn", 0.35, 22.0, 0.0, "wildfire_burn 0.35 s: the fire front rolls out", 2.0],
	[&"wildfire_burn", 3.0, 22.0, 0.0, "wildfire_burn 3 s: flames, fire line on the damage edge", 2.0],
	[&"wildfire_burn", 6.8, 22.0, 0.0, "wildfire_burn 6.8 s: the char cools, smoke drifts off", 2.0],
	[&"storm_warning", 2.5, 27.0, 4.0, "storm_warning 2.5 s: pale ring r 2.5 + reticle, cloud gathers 12 m up", 0.0],
	[&"storm_warning", 9.2, 27.0, 4.0, "storm_warning 9.2 s: flickers in the cloud, static on the ring", 0.0],
	[&"lightning_strike", 0.03, 27.0, 4.0, "lightning_strike 0.03 s: the leader races down", 3.0],
	[&"lightning_strike", 0.14, 27.0, 4.0, "lightning_strike 0.14 s: second stroke + flash", 3.0],
	[&"lightning_strike", 0.9, 18.0, 0.0, "lightning_strike 0.9 s: scorched crater, dust, sparks", 3.0],
	[&"scorch_spawn", 0.12, 13.0, 0.0, "scorch_spawn 0.12 s: Fireball ash r 2.5 appears", 0.0],
	[&"scorch_spawn", 0.7, 13.0, 0.0, "scorch_spawn 0.7 s: soot puff, the char cools", 0.0],
]

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _all := false


func _initialize() -> void:
	_all = "--all" in OS.get_cmdline_user_args()
	_world = Node3D.new()
	root.add_child(_world)
	current_scene = _world
	var we := WorldEnvironment.new()
	we.environment = load("res://art/environment/world_env.tres")
	_world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	_world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(800, 800)
	ground.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = load("res://art/shaders/painted.gdshader")
	gm.set_shader_parameter(&"base_color", Color(0.32, 0.36, 0.2))
	gm.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	gm.set_shader_parameter(&"noise_scale_a", 0.15)
	gm.set_shader_parameter(&"noise_scale_b", 0.04)
	gm.set_shader_parameter(&"rim_strength", 0.0)
	ground.material_override = gm
	ground.position = Vector3(150, 0, 150)
	_world.add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 700.0
	_world.add_child(_cam)
	var layer := CanvasLayer.new()
	_world.add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 836)
	_label.add_theme_font_size_override(&"font_size", 30)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 10)
	layer.add_child(_label)
	_vfx = (load("res://art/vfx/terrain_vfx.gd") as GDScript).new()
	_vfx.set(&"auto_hooks", false)
	_world.add_child(_vfx)
	_run.call_deferred()


func _cell(i: int) -> Vector3:
	return Vector3(float(i % COLS) * SPACING, 0.0, float(i / COLS) * SPACING)


func _model(path: String, pos: Vector3, face: Vector3) -> void:
	if not ResourceLoader.exists(path):
		return
	var m := (load(path) as PackedScene).instantiate() as Node3D
	if m == null:
		return
	_world.add_child(m)
	m.global_position = pos
	if face.distance_to(pos) > 0.1:
		m.look_at(Vector3(face.x, pos.y, face.z), Vector3.UP, true)


func _frame(focus: Vector3, zoom: float) -> void:
	var p := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _frames(sec: float) -> void:
	for i in int(round(sec / DT)):
		await process_frame


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _fx_at(id: StringName, at: Vector3) -> Object:
	for fx: Object in _vfx.get(&"_fx"):
		if fx.get(&"id") == id and (fx.get(&"point") as Vector3).distance_to(at) < 0.5:
			return fx
	return null


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var rows := (SHOTS.size() + COLS - 1) / COLS
	var sheet := Image.create_empty(CELL.x * COLS, CELL.y * rows, false, Image.FORMAT_RGBA8)
	await _frames(0.5)
	for i in SHOTS.size():
		var spec: Array = SHOTS[i]
		var id: StringName = spec[0]
		var c := _cell(i)
		var r := 4.5 if String(id).begins_with("wildfire") else 2.5
		# Soldiers for scale: on the rim of the zone, one inside.
		_model(SOLDIER, c + Vector3(-r - 1.2, 0.0, 1.0), c)
		_model(SOLDIER, c + Vector3(r * 0.4, 0.0, r * 0.3), c + Vector3(0, 0, 10))
		_model(SHADE, c + Vector3(r + 1.4, 0.0, -0.8), c)
		_frame(c + Vector3(0.0, float(spec[3]), 0.0), float(spec[2]))
		_label.text = String(spec[4])
		await _frames(0.3)
		var lead: float = spec[5]
		if lead > 0.0:
			var warn := &"wildfire_warning" if id == &"wildfire_burn" else &"storm_warning"
			_vfx.call(&"play", warn, c, r, lead)
			await _frames(lead)
		_vfx.call(&"play", id, c, r)
		await _frames(float(spec[1]))
		if id == &"storm_warning" and float(spec[1]) > 9.0:
			# Wait for a flicker (<= 0.7 s).
			var fx := _fx_at(id, c)
			for k in 42:
				if fx == null or float(fx.get(&"flash")) > 0.55:
					break
				await process_frame
		var img := await _grab()
		if _all:
			img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12b_v4_vfx_%d.png" % i))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot %-17s t=%.2f fps=%d draw_calls=%d live=%d" % [id, spec[1], Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), _vfx.call(&"live_count")])
		_vfx.call(&"stop_all")
		await _frames(0.2)
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12b_v4_vfx_sequence.png"))
	print("saved docs/art/screens/12b_v4_vfx_sequence.png")
	await _far()
	await _cost()
	quit()


## Zoom 40: a wildfire warning (6 s in), a storm warning (6 s in) and a burn (2 s in), 16 m apart.
func _far() -> void:
	var c := Vector3(60.0, 0.0, 300.0)
	var a := c + Vector3(-16.0, 0.0, 0.0)
	var b := c
	var d := c + Vector3(16.0, 0.0, 0.0)
	for p: Vector3 in [a, b, d]:
		for k in 4:
			_model(SOLDIER if k % 2 == 0 else SHADE, p + Vector3(-5.5 + 3.5 * float(k), 0.0, 5.5), p)
	_frame(c, 40.0)
	_label.text = "zoom 40: wildfire warning (6 s), storm warning (6 s), wildfire burn (2 s)"
	await _frames(0.3)
	_vfx.call(&"play", &"wildfire_warning", a, 4.5, 10.0)
	_vfx.call(&"play", &"storm_warning", b, 2.5, 10.0)
	await _frames(4.0)
	_vfx.call(&"play", &"wildfire_burn", d, 4.5, 6.0)
	await _frames(2.0)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12b_v4_vfx_z40.png"))
	print("saved docs/art/screens/12b_v4_vfx_z40.png (live=%d, draw_calls=%d)" % [_vfx.call(&"live_count"),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	_vfx.call(&"stop_all")
	await _frames(4.5)


## CPU cost of the node with the spec's worst case: 2 pairs (4 events) + 8 scorches.
func _cost() -> void:
	var c := Vector3(200.0, 0.0, 200.0)
	_vfx.call(&"play", &"wildfire_warning", c, 4.5, 10.0)
	_vfx.call(&"play", &"wildfire_warning", -c, 4.5, 10.0)
	_vfx.call(&"play", &"storm_warning", c + Vector3(20, 0, 0), 2.5, 10.0)
	_vfx.call(&"play", &"storm_warning", -c - Vector3(20, 0, 0), 2.5, 10.0)
	for i in 8:
		_vfx.call(&"play", &"scorch_spawn", c + Vector3(float(i) * 4.0, 0.0, 12.0), 2.5)
	await _frames(0.2)
	var total := 0
	for f in 30:
		await process_frame
		var t0 := Time.get_ticks_usec()
		_vfx.call(&"_process", 0.0)
		total += Time.get_ticks_usec() - t0
	print("TerrainVfx _process, 4 warnings + 8 scorches (0.2 s in): %.1f us / frame (live %d)" % [float(total) / 30.0,
			_vfx.call(&"live_count")])
	await _frames(1.2)
	total = 0
	for f in 30:
		await process_frame
		var t1 := Time.get_ticks_usec()
		_vfx.call(&"_process", 0.0)
		total += Time.get_ticks_usec() - t1
	print("TerrainVfx _process, 4 warnings running (1.9 s in): %.1f us / frame (live %d)" % [float(total) / 30.0,
			_vfx.call(&"live_count")])
	_vfx.call(&"stop_all")
	await _frames(4.5)
	print("after stop_all + 4.5 s: running=%d live=%d (expect 0 / 0)" % [_vfx.call(&"active_count"),
			_vfx.call(&"live_count")])
