extends SceneTree
## Previews of the Mage Archer effects (task 13b.V8, art/vfx/champion_mage_archer_vfx.gd through ChampionVfx) ->
## docs/art/screens/13b_v8_sheet.png (3 x 4 cells, RTS camera: pitch 55, fov 50), one full-size shot per cell
## (13b_v8_<tag>.png) and the game camera at 40 m (13b_v8_z40.png). Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/champion_mage_archer_vfx_preview.gd --fixed-fps 60 --quit-after 5000
## Bodies: the Mage Archer model (art/units/champions/mage_archer) driven like the gameplay does (play_cast / play_attack /
## play_call / revive with the VFX call), Flame Guards as her prey. Prints fps / draw calls and the ChampionVfx _process
## cost of a stress run (2 archers casting everything over 60 units).

const CELL := Vector2i(640, 360)
const COLS := 3
const SPACING := 70.0
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 2.0\nvar radius: float = 0.5\nvar alive: bool = true\nvar model: Node3D = null\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn model\n"
const ARCHER := "res://art/units/champions/mage_archer/mage_archer.tscn"
const PREY := "res://art/units/fire/flame_guard.tscn"
## [tag, id, shot time (s), zoom, label]
const SHOTS := [
	["arrow", &"arcane_arrow", 0.24, 10.0, "arcane_arrow: her shot of light"],
	["shaft_charge", &"sable_shaft", 0.45, 9.0, "sable_shaft: the charge on the bow"],
	["shaft_pierce", &"sable_shaft", 0.69, 17.0, "sable_shaft: the shaft tears down the line"],
	["shaft_after", &"sable_shaft", 1.0, 17.0, "sable_shaft: pierce beam + scar"],
	["mark", &"grave_mark", 1.2, 8.0, "grave_mark: the sigil over the prey"],
	["reap", &"grave_mark", 1.24, 11.0, "grave_mark: killed while marked -> soul wisp"],
	["volley_warn", &"eclipse_volley", 0.55, 17.0, "eclipse_volley: telegraph (0.55 s)"],
	["volley_wave", &"eclipse_volley", 1.08, 17.0, "eclipse_volley: wave 2 falling"],
	["volley_after", &"eclipse_volley", 1.75, 17.0, "eclipse_volley: after the 3 waves"],
	["call", &"unique_call", 0.9, 12.0, "unique_call: the ritual, she rises"],
	["call_peak", &"unique_call", 1.56, 12.0, "unique_call: the peak (bow raised)"],
	["revive", &"unique_revive", 0.38, 12.0, "unique_revive: the pillar lands"],
]

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript


func _initialize() -> void:
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
	var gm := ShaderMaterial.new()   # plain painted grass (same as the other VFX previews)
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
	_cam.far = 500.0
	_world.add_child(_cam)
	var layer := CanvasLayer.new()
	_world.add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 836)
	_label.add_theme_font_size_override(&"font_size", 34)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 10)
	layer.add_child(_label)
	_vfx = (load("res://art/vfx/champion_vfx.gd") as GDScript).new()
	_world.add_child(_vfx)
	_run.call_deferred()


func _cell(i: int) -> Vector3:
	return Vector3(float(i % COLS) * SPACING, 0.0, float(i / COLS) * SPACING)


func _body(team: int, pos: Vector3, face: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	var model: Node3D = (load(ARCHER if team == 0 else PREY) as PackedScene).instantiate()
	u.add_child(model)
	u.set(&"model", model)
	if team == 1:
		u.set(&"body_height", 1.8)
		u.set(&"radius", 0.45)
	_world.add_child(u)
	u.global_position = pos
	u.add_to_group(&"units")
	if face.distance_to(pos) > 0.1:
		u.look_at(Vector3(face.x, pos.y, face.z), Vector3.UP, true)
	return u


func _frame(focus: Vector3, zoom: float) -> void:
	var p := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _model(u: Node3D) -> Node3D:
	return u.get(&"model")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var rows := (SHOTS.size() + COLS - 1) / COLS
	var sheet := Image.create_empty(CELL.x * COLS, CELL.y * rows, false, Image.FORMAT_RGBA8)
	await _wait(0.5)
	for i in SHOTS.size():
		var spec: Array = SHOTS[i]
		var tag: String = spec[0]
		var id: StringName = spec[1]
		var c := _cell(i)
		var focus := c
		var caster_pos := c + Vector3(-4.0, 0.0, 1.5)
		var prey: Array[Vector3] = []
		var t_arg: Variant = null
		match tag:
			"arrow":
				prey = [c + Vector3(3.5, 0.0, -1.0)]
			"shaft_charge":
				caster_pos = c + Vector3(-1.0, 0.0, 0.8)
				prey = [c + Vector3(6.0, 0.0, -1.5)]
			"shaft_pierce", "shaft_after":
				caster_pos = c + Vector3(-8.0, 0.0, 2.5)
				var d := Vector3(1.0, 0.0, -0.3).normalized()
				prey = [caster_pos + d * 5.0, caster_pos + d * 8.5 + Vector3(0.2, 0, 0.3), caster_pos + d * 12.0,
						caster_pos + d * 14.5 - Vector3(0.1, 0, 0.3), caster_pos + d * 7.0 + Vector3(0, 0, 2.2)]
				focus = c + Vector3(0.5, 0.0, 0.0)
			"mark", "reap":
				caster_pos = c + Vector3(-4.0, 0.0, 2.0)
				prey = [c + Vector3(1.0, 0.0, -0.4)]
				focus = c + Vector3(0.0 if tag == "mark" else -1.2, 0.0, 0.3)
			"volley_warn", "volley_wave", "volley_after":
				caster_pos = c + Vector3(-9.5, 0.0, 5.0)
				prey = [c + Vector3(-1.5, 0.0, 0.5), c + Vector3(1.2, 0.0, -1.3), c + Vector3(0.3, 0.0, 1.8),
						c + Vector3(2.4, 0.0, 1.0), c + Vector3(-0.6, 0.0, -2.4), c + Vector3(-2.8, 0.0, -0.8)]
				focus = c + Vector3(-2.0, 0.0, 1.0)
				t_arg = c
			"call", "call_peak", "revive":
				caster_pos = c
				prey = [c + Vector3(4.5, 0.0, -2.5)]
		var caster := _body(0, caster_pos, prey[0] if not prey.is_empty() else c + Vector3(0, 0, 5))
		var targets: Array[Node3D] = []
		for p in prey:
			targets.append(_body(1, p, caster_pos))
		if t_arg == null:
			t_arg = targets[0] if id != &"unique_call" and id != &"unique_revive" else caster
		_frame(focus, float(spec[3]))
		_label.text = String(spec[4])
		if id == &"unique_revive":
			_model(caster).call(&"play_death")
		await _wait(0.6)
		var shot_at: float = spec[2]
		var events: Array = []
		match id:
			&"arcane_arrow":
				# The gameplay spawns the bolt at the model's windup (0.15 s); a second shot in flight for the picture.
				_model(caster).call(&"play_attack")
				events.append([0.15, func() -> void: _vfx.call(&"play", id, caster, t_arg)])
			&"unique_call":
				_model(caster).call(&"play_call")
				_vfx.call(&"play", id, caster, t_arg)
			&"unique_revive":
				_model(caster).call(&"revive")
				_vfx.call(&"play", id, caster, t_arg)
			_:
				_model(caster).call(&"play_cast", id)
				_vfx.call(&"play", id, caster, t_arg)
		if tag == "reap":
			events.append([0.9, func() -> void:
				targets[0].set(&"alive", false)
				_model(targets[0]).call(&"play_death")])
		var t := 0.0
		while t < shot_at:
			await process_frame
			t += 1.0 / 60.0
			for e: Array in events:
				if e.size() == 2 and t >= float(e[0]):
					(e[1] as Callable).call()
					e.append(true)
		var img := await _grab()
		img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/13b_v8_%s.png" % tag))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot ", tag, " fps=", Engine.get_frames_per_second(), " draw_calls=",
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/screens/13b_v8_sheet.png"))
	print("saved docs/art/screens/13b_v8_sheet.png")
	await _game_camera()
	await _stress()
	quit()


## The game camera (40 m): she opens with Eclipse Volley on a guard line, then a Sable Shaft down it.
func _game_camera() -> void:
	var c := Vector3(40.0, 0.0, 330.0)
	var archer := _body(0, c + Vector3(-9.0, 0.0, 6.0), c)
	var guards: Array[Node3D] = []
	for i in 10:
		guards.append(_body(1, c + Vector3(-3.0 + float(i % 5) * 1.6, 0.0, -1.0 + float(i / 5) * 2.0), archer.global_position))
	_frame(c + Vector3(-3.0, 0.0, 2.0), 40.0)
	_label.text = "game camera 40 m: Eclipse Volley on a guard line + Sable Shaft"
	await _wait(0.6)
	_model(archer).call(&"play_cast", &"eclipse_volley")
	_vfx.call(&"play", &"eclipse_volley", archer, c)
	await _wait(0.3)
	var a2 := _body(0, c + Vector3(-8.0, 0.0, -4.0), guards[0].global_position)
	_model(a2).call(&"play_cast", &"sable_shaft")
	_vfx.call(&"play", &"sable_shaft", a2, guards[4])
	await _wait(0.8)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/13b_v8_z40.png"))
	print("z40 fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	await _wait(2.5)


## ChampionVfx._process timed by hand over 60 frames.
func _time_process(tag: String) -> void:
	_vfx.set_process(false)
	var worst := 0
	var total := 0
	for i in 60:
		await process_frame
		var a := Time.get_ticks_usec()
		_vfx.call(&"_process", 1.0 / 60.0)
		var d := Time.get_ticks_usec() - a
		total += d
		worst = maxi(worst, d)
	_vfx.set_process(true)
	print("ChampionVfx _process (%s, %d effects): avg %d us, worst %d us" % [tag, _vfx.call(&"active_count"),
			total / 60, worst])


## 2 Mage Archers (one per team) shooting every 0.3 s and casting all their effects over 60 units; then all must end.
func _stress() -> void:
	var c := Vector3(150.0, 0.0, 330.0)
	var units: Array[Node3D] = []
	for i in 60:
		units.append(_body(1, c +Vector3(-14.0 + float(i % 10) * 3.0, 0.0, -8.0 + float(i / 10) * 3.0), c))
	var archers: Array[Node3D] = [_body(0, c + Vector3(-10.0, 0.0, 12.0), c), _body(0, c + Vector3(10.0, 0.0, 12.0), c)]
	_frame(c, 40.0)
	_label.text = "stress: 2 Mage Archers, every effect, over 60 units (zoom 40)"
	await _wait(0.5)
	var ids: Array[StringName] = [&"sable_shaft", &"grave_mark", &"eclipse_volley", &"unique_revive", &"unique_call"]
	for k in 10:
		for ai in 2:
			var a := archers[ai]
			var tgt: Node3D = units[(k * 7 + ai * 13) % units.size()]
			_vfx.call(&"play", &"arcane_arrow", a, tgt)
			if k % 2 == 0:
				var id: StringName = ids[(k / 2 + ai) % ids.size()]
				var arg: Variant = tgt.global_position if id == &"eclipse_volley" else (a if id in [&"unique_call",
						&"unique_revive"] else tgt)
				_vfx.call(&"play", id, a, arg)
		await _wait(0.3)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/13b_v8_stress.png"))
	print("stress: running=", _vfx.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	await _time_process("fresh casts")
	await _wait(8.0)
	print("after 8 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
