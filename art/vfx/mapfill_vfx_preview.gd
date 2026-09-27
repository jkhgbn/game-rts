extends SceneTree
## Contact sheet of the map-fill effects (task 12.V25) -> docs/art/screens/12_v25_mapfill_vfx.png (3 x 3 cells, RTS
## camera: pitch 55, fov 50), docs/art/screens/12_v25_far.png (shrine_awaken + blessing runes + capture at zoom 40 / 55,
## the "reads across the map" check) and docs/art/screens/12_v25_stress.png (every effect x 3 + 60 runes + 16 rings).
## With `--all`: one full-size shot per effect, docs/art/screens/12_v25_<id>.png. Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/mapfill_vfx_preview.gd --fixed-fps 60 --quit-after 6000
## Stand-in bodies: the step-12 models (watchtower, wayshrine, essence well, Bristleback, Gloomcap Elder, Hollow Stag)
## and Fire soldiers; the wade shot lays the ford film material (12.V1) under three wading soldiers.

const CELL := Vector2i(640, 360)
const COLS := 3
const SPACING := 70.0
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar owner_team: int = -1\nvar capture_radius: float = 7.0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nvar velocity: Vector3 = Vector3.ZERO\nfunc is_alive() -> bool:\n\treturn alive\n"
const MODELS := {
	&"tower": "res://art/buildings/capture/watchtower/watchtower.tscn",
	&"shrine": "res://art/buildings/capture/wayshrine/wayshrine.tscn",
	&"well": "res://art/buildings/capture/essence_well/essence_well.tscn",
	&"bristleback": "res://art/units/neutral/bristleback/bristleback.tscn",
	&"elder": "res://art/units/neutral/gloomcap/gloomcap_elder.tscn",
	&"stag": "res://art/units/neutral/hollow_stag/hollow_stag.tscn",
	&"soldier": "res://art/units/fire/flame_guard.tscn",
	&"shade": "res://art/units/shadow/shade.tscn",
}
const FORD_MAT := "res://art/environment/water/water_ford_mat.tres"
## id -> [shot time (s), zoom, label]
const SHOTS := [
	[&"capture_done", 0.32, 22.0, "capture_done: ring burst to the capture radius in the owner's colour"],
	[&"shrine_awaken", 0.75, 34.0, "shrine_awaken: gold column 24 m, wind ring r 6, spiralling motes"],
	[&"blessing", 1.0, 11.0, "blessing: the Wayfarer's rune over each blessed unit"],
	[&"well_pulse", 0.35, 12.0, "well_pulse: essence motes + ring in the owner's colour"],
	[&"camp_respawn", 0.45, 13.0, "camp_respawn: dust ring + swirling leaves"],
	[&"camp_cleared", 0.5, 13.0, "camp_cleared: clearing team's ring, essence rising, leaves settle"],
	[&"wade", 1.3, 9.0, "wade: ripple rings round waders on the ford film"],
	[&"spore_burst", 0.95, 12.0, "spore_burst: blue-grey spore cloud r 3 + drifting spores"],
	[&"antler_sweep", 0.28, 13.0, "antler_sweep: green wind ring r 3, glowing leaves flung out"],
]

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript
var _all := false


func _initialize() -> void:
	_all = "--all" in OS.get_cmdline_user_args()
	_stub = GDScript.new()
	_stub.source_code = STUB_SRC
	_stub.reload()
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
	pm.size = Vector2(700, 700)
	ground.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = load("res://art/shaders/painted.gdshader")
	gm.set_shader_parameter(&"base_color", Color(0.32, 0.36, 0.2))
	gm.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	gm.set_shader_parameter(&"noise_scale_a", 0.15)
	gm.set_shader_parameter(&"noise_scale_b", 0.04)
	gm.set_shader_parameter(&"rim_strength", 0.0)
	ground.material_override = gm
	ground.position = Vector3(100, 0, 100)
	_world.add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 600.0
	_world.add_child(_cam)
	var layer := CanvasLayer.new()
	_world.add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 836)
	_label.add_theme_font_size_override(&"font_size", 34)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 10)
	layer.add_child(_label)
	_vfx = (load("res://art/vfx/mapfill_vfx.gd") as GDScript).new()
	_vfx.set(&"auto_hooks", false)
	_vfx.set(&"auto_wade", false)
	_world.add_child(_vfx)
	_run.call_deferred()


func _cell(i: int) -> Vector3:
	return Vector3(float(i % COLS) * SPACING, 0.0, float(i / COLS) * SPACING)


func _body(kind: StringName, team: int, pos: Vector3, face: Vector3, h: float = 1.8, r: float = 0.45) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	u.set(&"body_height", h)
	u.set(&"radius", r)
	var path: String = MODELS.get(kind, "")
	if path != "" and ResourceLoader.exists(path):
		var model := (load(path) as PackedScene).instantiate() as Node3D
		if model:
			u.add_child(model)
			u.set_meta(&"model", model)
	_world.add_child(u)
	u.global_position = pos
	if face.distance_to(pos) > 0.1:
		u.look_at(Vector3(face.x, pos.y, face.z), Vector3.UP, true)
	return u


func _hook(u: Node3D, method: StringName, args: Array) -> void:
	var m: Variant = u.get_meta(&"model", null)
	if m is Object and is_instance_valid(m) and (m as Object).has_method(method):
		(m as Object).callv(method, args)


func _frame(focus: Vector3, zoom: float) -> void:
	var p := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _ford(c: Vector3, r: float) -> void:
	if not ResourceLoader.exists(FORD_MAT):
		return
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.02
	cm.radial_segments = 48
	mi.mesh = cm
	mi.material_override = load(FORD_MAT)
	_world.add_child(mi)
	mi.global_position = c + Vector3(0.0, 0.01, 0.0)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var rows := (SHOTS.size() + COLS - 1) / COLS
	var sheet := Image.create_empty(CELL.x * COLS, CELL.y * rows, false, Image.FORMAT_RGBA8)
	await _wait(0.5)
	for i in SHOTS.size():
		var spec: Array = SHOTS[i]
		var id: StringName = spec[0]
		var c := _cell(i)
		var at := c
		var target: Node3D = null
		var focus := c
		var units: Array[Node3D] = []
		match id:
			&"capture_done":
				target = _body(&"tower", 2, c, c + Vector3(0, 0, 8), 9.0, 2.0)
				target.set(&"owner_team", 0)
				target.set(&"capture_radius", 7.0)
				_hook(target, &"set_owner_color", [Color(0.3, 1.0, 0.4)])
				for k in 3:
					_body(&"soldier", 0, c + Vector3(-3.0 + 2.2 * float(k), 0.0, 4.0), c)
				focus = c + Vector3(0.0, 1.5, 0.0)
			&"shrine_awaken":
				target = _body(&"shrine", 2, c, c + Vector3(0, 0, 8), 1.6, 1.0)
				_hook(target, &"set_state", [&"awake"])
				focus = c + Vector3(0.0, 6.0, 0.0)
			&"blessing":
				for k in 6:
					var u := _body(&"soldier", 0, c + Vector3(-3.0 + 1.3 * float(k), 0.0, float(k % 2) * 1.4 - 0.7), c
							+ Vector3(0, 0, 8))
					units.append(u)
				units.append(_body(&"shade", 1, c + Vector3(3.5, 0.0, -2.5), c))
				focus = c + Vector3(0.0, 1.0, 0.0)
			&"well_pulse":
				target = _body(&"well", 2, c, c + Vector3(0, 0, 8), 1.5, 1.6)
				target.set(&"owner_team", 0)
				_hook(target, &"set_owner_color", [Color(0.3, 1.0, 0.4)])
				_body(&"soldier", 0, c + Vector3(3.2, 0.0, 1.5), c)
			&"camp_respawn", &"camp_cleared":
				for k in 3:
					var a := TAU * float(k) / 3.0 + 0.4
					units.append(_body(&"bristleback", 2, c + Vector3(cos(a), 0.0, sin(a)) * 1.6, c, 1.1, 0.55))
				if id == &"camp_cleared":
					for u in units:
						u.visible = false   # the creatures are dead
					_body(&"soldier", 0, c + Vector3(-3.5, 0.0, 2.2), c)
					_body(&"soldier", 0, c + Vector3(3.2, 0.0, 2.6), c)
			&"wade":
				_ford(c, 4.0)
				for k in 3:
					units.append(_body(&"soldier", 0, c + Vector3(-2.2 + 2.2 * float(k), 0.0, -1.5 + float(k % 2) * 1.6),
							c + Vector3(-2.2 + 2.2 * float(k), 0.0, 8.0)))
			&"spore_burst":
				var elder := _body(&"elder", 2, c + Vector3(-3.0, 0.0, -1.8), c + Vector3(1.5, 0, 1.0), 2.4, 0.7)
				_hook(elder, &"play_cast", [&"spore_burst"])
				for k in 3:
					units.append(_body(&"soldier", 0, c + Vector3(1.0 + float(k % 2) * 1.2, 0.0, 0.2 + float(k) * 0.9),
							elder.global_position))
				at = c + Vector3(1.5, 0.0, 1.0)
			&"antler_sweep":
				target = _body(&"stag", 2, c, c + Vector3(0, 0, 8), 3.2, 1.2)
				_hook(target, &"play_cast", [&"antler_sweep"])
				for k in 3:
					var a := TAU * float(k) / 3.0 + 1.0
					units.append(_body(&"soldier", 0, c + Vector3(cos(a), 0.0, sin(a)) * 2.4, c))
				focus = c + Vector3(0.0, 1.0, 0.0)
		_frame(focus, float(spec[2]))
		_label.text = String(spec[3])
		await _wait(0.5)
		var shot_at: float = spec[1]
		match id:
			&"blessing":
				for u in units:
					if int(u.get(&"team")) == 0:
						_vfx.call(&"play", id, u.global_position, u)
			&"well_pulse":
				_hook(target, &"play_pulse", [])
				_vfx.call(&"play", id, c, target)
			&"camp_cleared":
				# The hook path passes the clearing team; here a team-0 stand-in carries it.
				_vfx.call(&"play", id, c, _body(&"", 0, c, c))
			&"wade", &"spore_burst":
				pass
			_:
				_vfx.call(&"play", id, at, target)
		var t := 0.0
		var next_ring := 0.0
		var spore_done := false
		while t < shot_at:
			await process_frame
			var dt := 1.0 / 60.0
			t += dt
			if id == &"wade":
				for u in units:
					u.global_position += Vector3(0.0, 0.0, 1.2 * dt)
				if t >= next_ring:
					next_ring += 0.4
					for u in units:
						_vfx.call(&"play", &"wade", u.global_position, u)
			elif id == &"spore_burst" and not spore_done and t >= 0.46:
				spore_done = true
				_vfx.call(&"play", id, at, units[0])
		var img := await _grab()
		if _all:
			img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v25_%s.png" % id))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot ", id, " fps=", Engine.get_frames_per_second(), " draw_calls=",
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v25_mapfill_vfx.png"))
	print("saved docs/art/screens/12_v25_mapfill_vfx.png")
	await _far()
	await _stress()
	quit()


## From far: a shrine waking at max zoom (55) beside a tower being captured, and blessed soldiers at zoom 30.
func _far() -> void:
	var c := Vector3(250.0, 0.0, 0.0)
	var shrine := _body(&"shrine", 2, c, c + Vector3(0, 0, 8), 1.6, 1.0)
	_hook(shrine, &"set_state", [&"awake"])
	var tower := _body(&"tower", 2, c + Vector3(-22.0, 0.0, 10.0), c, 9.0, 2.0)
	tower.set(&"owner_team", 1)
	_hook(tower, &"set_owner_color", [Color(1.0, 0.3, 0.3)])
	var squad: Array[Node3D] = []
	for k in 8:
		squad.append(_body(&"soldier", 0, c + Vector3(10.0 + float(k % 4) * 1.4, 0.0, 6.0 + float(k / 4) * 1.4), c))
	_frame(c + Vector3(-4.0, 0.0, 4.0), 55.0)
	_label.text = "zoom 55: shrine_awaken, capture_done (enemy), 8 blessed soldiers"
	await _wait(0.6)
	for u in squad:
		_vfx.call(&"play", &"blessing", u.global_position, u)
	await _wait(0.5)
	_vfx.call(&"play", &"shrine_awaken", c, shrine)
	_vfx.call(&"play", &"capture_done", tower.global_position, tower)
	await _wait(0.6)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v25_far.png"))
	_frame(c + Vector3(10.0, 0.0, 6.0), 30.0)
	_label.text = "zoom 30: blessed squad (runes)"
	await _wait(0.3)
	img = await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v25_runes_z30.png"))


## Every effect x 3 at once + 60 runes + the ring pool (cost check), then everything must end.
func _stress() -> void:
	var c := Vector3(60.0, 0.0, 320.0)
	var units: Array[Node3D] = []
	for i in 60:
		units.append(_body(&"soldier", i % 2, c + Vector3(-15.0 + float(i % 10) * 3.0, 0.0, -9.0 + float(i / 10) * 3.0), c))
	_frame(c, 40.0)
	_label.text = "stress: 9 effects x 3 + 60 runes + 16 rings (zoom 40)"
	await _wait(0.4)
	for u in units:
		_vfx.call(&"play", &"blessing", u.global_position, u)
	var ids: Array = _vfx.get(&"EFFECTS")
	for k in 3:
		for j in ids.size():
			var u := units[(k * 11 + j * 5) % units.size()]
			if ids[j] == &"wade":
				for r in 6:
					_vfx.call(&"play", &"wade", u.global_position + Vector3(float(r), 0.0, float(k)), u)
			elif ids[j] != &"blessing":
				_vfx.call(&"play", ids[j], u.global_position + Vector3(0.0, 0.0, float(k) * 2.0), u)
	var a := Time.get_ticks_usec()
	_vfx.call(&"_process", 1.0 / 60.0)
	print("MapFillVfx _process (24 fresh effects, 60 runes, 16 rings): %d us" % (Time.get_ticks_usec() - a))
	await _wait(0.35)
	var total := 0
	for f in 30:
		await process_frame
		var b := Time.get_ticks_usec()
		_vfx.call(&"_process", 0.0)
		total += Time.get_ticks_usec() - b
	print("MapFillVfx _process with 60 runes + running effects: %.1f us / frame" % (float(total) / 30.0))
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v25_stress.png"))
	print("stress: running=", _vfx.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	await _wait(3.0)
	total = 0
	for f in 30:
		await process_frame
		var b := Time.get_ticks_usec()
		_vfx.call(&"_process", 0.0)
		total += Time.get_ticks_usec() - b
	print("MapFillVfx _process with only the 60 runes: %.1f us / frame (running=%d)" % [float(total) / 30.0,
			_vfx.call(&"active_count")])
	for u in units:
		u.queue_free()
	await _wait(3.5)
	print("after 3.5 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
