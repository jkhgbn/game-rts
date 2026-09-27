extends SceneTree
## Screenshots of the dragon effects (task 13.V14 + the Frost Dragon ids of 13c.V2) with the real dragon models
## (auto-attached by TitanVfx, exactly as in the game): breath (game camera + close-up), burning ground / hoarfrost,
## the flight trail, the crash (impact + after) for both dragons, and both dragons breathing at the 40 m game camera.
## Writes docs/art/screens/13_v14_<name>.png and the contact sheet 13_v14_sheet.png. Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/titan_vfx_preview.gd --fixed-fps 60 --quit-after 6000
## Add `-- --only=<name>` for one shot. Then a stress run (4 dragons breathing + 12 patches + 2 crashes) prints the
## TitanVfx _process cost and the draw calls.

const OUT := "res://docs/art/screens/13_v14_"
const CELL := Vector2i(640, 360)
const COLS := 4
const SPACING := 90.0
const CINDER := "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"
const FROST := "res://art/units/titans/frost_dragon/frost_dragon.tscn"
const GUARD := "res://art/units/fire/flame_guard.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar alive: bool = true\nvar model: Node3D\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn model\n"
const FIRE_TINT := Color(0.85, 0.30, 0.12)
const ICE_TINT := Color(0.55, 0.80, 0.95)
## [name, dragon, action, time after the event (s), zoom, pitch, yaw, label]
const SHOTS := [
	[&"breath", &"cinder", &"breath", 0.3, 17.0, 50.0, 0.0, "dragon_breath: 60 deg cone to 6 m, flame jet + puffs + sparks"],
	[&"breath_close", &"cinder", &"breath", 0.22, 11.0, 20.0, 35.0, "dragon_breath close-up (jaw open)"],
	[&"burning_ground", &"cinder", &"patch", 1.2, 11.0, 55.0, 0.0, "burning_ground: r 2, 3 s, low flames, fire line"],
	[&"trail", &"cinder", &"fly", 1.8, 20.0, 50.0, 0.0, "ember trail while flying (< 45 m)"],
	[&"crash", &"cinder", &"crash", 0.18, 19.0, 50.0, 0.0, "dragon_crash: shock ring, dust wall, clods, embers"],
	[&"crash_after", &"cinder", &"crash", 1.6, 16.0, 55.0, 0.0, "dragon_crash after 1.6 s: crater, smoke"],
	[&"frost_breath", &"frost", &"breath", 0.3, 17.0, 50.0, 0.0, "frost_breath: 6.5 m, snow billows + ice glints"],
	[&"frost_breath_close", &"frost", &"breath", 0.22, 11.0, 20.0, 35.0, "frost_breath close-up"],
	[&"hoarfrost", &"frost", &"patch", 1.2, 11.0, 55.0, 0.0, "hoarfrost: r 2.5, 4 s, rime + low mist"],
	[&"frost_trail", &"frost", &"fly", 1.8, 20.0, 50.0, 0.0, "ice-shard trail while flying"],
	[&"frost_crash", &"frost", &"crash", 0.18, 19.0, 50.0, 0.0, "frost_crash: ice shatter, snow dust"],
	[&"frost_crash_after", &"frost", &"crash", 1.6, 16.0, 55.0, 0.0, "frost_crash after 1.6 s: ice crater, cold mist"],
	[&"game40", &"both", &"breath", 0.3, 40.0, 55.0, 0.0, "game camera 40 m: both breaths + patches"],
]

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript
var _movers: Array[Dictionary] = []    # {n, v}


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
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 120.0
	_world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(900, 900)
	ground.mesh = pm
	var gm := ShaderMaterial.new()   # plain painted grass (same as the other VFX previews)
	gm.shader = load("res://art/shaders/painted.gdshader")
	gm.set_shader_parameter(&"base_color", Color(0.32, 0.36, 0.2))
	gm.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	gm.set_shader_parameter(&"noise_scale_a", 0.15)
	gm.set_shader_parameter(&"noise_scale_b", 0.04)
	gm.set_shader_parameter(&"rim_strength", 0.0)
	ground.material_override = gm
	ground.position = Vector3(150, 0, 120)
	_world.add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 600.0
	_world.add_child(_cam)
	_cam.make_current()
	var layer := CanvasLayer.new()
	_world.add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 836)
	_label.add_theme_font_size_override(&"font_size", 30)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 10)
	layer.add_child(_label)
	_vfx = (load("res://art/vfx/titan_vfx.gd") as GDScript).new()
	_vfx.name = "TitanVfx"
	_world.add_child(_vfx)
	_run.call_deferred()


func _cell(i: int) -> Vector3:
	return Vector3(float(i % COLS) * SPACING, 0.0, float(i / COLS) * SPACING)


func _frame(focus: Vector3, zoom: float, pitch_deg: float, yaw_deg: float) -> void:
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	_cam.position = focus + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * zoom
	_cam.rotation = Vector3(-p, y, 0.0)


func _unit(team: int, pos: Vector3, yaw_deg: float) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	_world.add_child(u)
	u.global_position = pos
	u.rotation.y = deg_to_rad(yaw_deg)
	return u


func _dragon(kind: StringName, pos: Vector3, yaw_deg: float) -> Node3D:
	var u := _unit(0 if kind == &"cinder" else 2, pos, yaw_deg)
	var holder := Node3D.new()
	u.add_child(holder)
	var m := (load(CINDER if kind == &"cinder" else FROST) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	m.call(&"set_team_color", FIRE_TINT if kind == &"cinder" else ICE_TINT)
	u.set(&"model", m)
	return u


func _guards(c: Vector3, fwd: Vector3, count: int) -> void:
	var side := Vector3(-fwd.z, 0.0, fwd.x)
	for k in count:
		var d := 3.0 + float(k % 3) * 1.3
		var s := (float(k % 3) - 1.0) * 1.1 + (0.5 if k >= 3 else -0.4)
		var at := c + fwd * d + side * s
		var ps := load(GUARD) as PackedScene
		if ps == null:
			return
		var g := ps.instantiate() as Node3D
		_world.add_child(g)
		g.global_position = at
		g.look_at(c, Vector3.UP, true)


func _wait(sec: float) -> void:
	var t := 0.0
	while t < sec:
		await process_frame
		var dt := 1.0 / 60.0
		t += dt
		for m in _movers:
			var n: Node3D = m["n"]
			if is_instance_valid(n):
				n.global_position += (m["v"] as Vector3) * dt


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var only := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	var rows := (SHOTS.size() + COLS - 1) / COLS
	var sheet := Image.create_empty(CELL.x * COLS, CELL.y * rows, false, Image.FORMAT_RGBA8)
	await _wait(0.5)
	for i in SHOTS.size():
		var spec: Array = SHOTS[i]
		var shot: StringName = spec[0]
		if only != "" and not String(shot).begins_with(only):
			continue
		var kind: StringName = spec[1]
		var action: StringName = spec[2]
		var c := _cell(i)
		_movers.clear()
		var fwd := Vector3(1.0, 0.0, 0.0)     # the dragons face +X (side view from the RTS camera)
		var focus := c + fwd * 2.5
		var dragons: Array[Node3D] = []
		if kind == &"both":
			dragons.append(_dragon(&"cinder", c + Vector3(-4.0, 0.0, -5.0), 90.0))
			dragons.append(_dragon(&"frost", c + Vector3(-4.0, 0.0, 5.0), 90.0))
			_guards(c + Vector3(-4.0, 0.0, -5.0), fwd, 5)
			_guards(c + Vector3(-4.0, 0.0, 5.0), fwd, 5)
			focus = c
		else:
			dragons.append(_dragon(kind, c, 90.0))
			if action == &"breath" or action == &"patch":
				_guards(c, fwd, 5)
		_frame(focus + Vector3(0.0, 1.5, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
		_label.text = String(spec[7])
		await _wait(0.6)
		var after: float = spec[3]
		match action:
			&"breath":
				for d in dragons:
					(d.get(&"model") as Node3D).call(&"play_attack")
				await _wait(0.35)
				for d in dragons:
					var frost: bool = int(d.get(&"team")) == 2
					_vfx.call(&"play", &"hoarfrost" if frost else &"burning_ground", d.global_position + fwd * 4.0, d)
				await _wait(after)
			&"patch":
				_vfx.call(&"play", &"hoarfrost" if kind == &"frost" else &"burning_ground", c + fwd * 4.0, dragons[0])
				_frame(c + fwd * 4.0 + Vector3(0.0, 0.5, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(after)
			&"fly":
				var d := dragons[0]
				d.global_position = c - fwd * 8.0
				(d.get(&"model") as Node3D).call(&"set_moving", 5.5)
				_movers.append({"n": d, "v": fwd * 5.5})
				await _wait(after)
				_frame(d.global_position + Vector3(-2.0, 3.0, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(0.05)
			&"crash":
				var d := dragons[0]
				(d.get(&"model") as Node3D).call(&"play_death")
				d.set(&"alive", false)
				await _wait(1.12 + after)
		var img := await _grab()
		img.save_png(ProjectSettings.globalize_path(OUT + String(shot) + ".png"))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot ", shot, " fps=", Engine.get_frames_per_second(), " draw_calls=",
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " running=",
				_vfx.call(&"active_ids"))
	if only == "":
		sheet.save_png(ProjectSettings.globalize_path(OUT + "sheet.png"))
		print("saved docs/art/screens/13_v14_sheet.png")
		await _stress()
	elif only == "stress":
		await _stress()
	quit()


## 4 dragons breathing + 12 patches + 2 crashes at once (cost check), then everything must end.
func _stress() -> void:
	var c := Vector3(150.0, 0.0, 330.0)
	var dragons: Array[Node3D] = []
	for i in 4:
		dragons.append(_dragon(&"cinder" if i % 2 == 0 else &"frost", c + Vector3(-9.0 + float(i) * 6.0, 0.0, -4.0), 0.0))
	_frame(c, 30.0, 55.0, 0.0)
	_label.text = "stress: 4 breaths + 12 patches + 2 crashes (zoom 30)"
	await _wait(0.5)
	for d in dragons:
		(d.get(&"model") as Node3D).call(&"play_attack")
	for k in 12:
		_vfx.call(&"play", &"burning_ground" if k % 2 == 0 else &"hoarfrost",
				c + Vector3(-12.0 + float(k % 6) * 4.8, 0.0, 3.0 + float(k / 6) * 5.0), null)
	_vfx.call(&"play", &"dragon_crash", c + Vector3(-14.0, 0.0, -10.0), null)
	_vfx.call(&"play", &"frost_crash", c + Vector3(14.0, 0.0, -10.0), null)
	await _wait(0.35)
	var fxs: Array = _vfx.get(&"_fx")
	var per := {}
	for fx in fxs:
		var a0 := Time.get_ticks_usec()
		for k in 20:
			_vfx.call(&"_tick", fx, 0.0)
		per[fx.id] = float(per.get(fx.id, 0.0)) + float(Time.get_ticks_usec() - a0) / 20.0
	var a1 := Time.get_ticks_usec()
	for k in 20:
		_vfx.call(&"_tick_trails", 0.0)
	print("per kind us: ", per, " trails: ", float(Time.get_ticks_usec() - a1) / 20.0)
	var a := Time.get_ticks_usec()
	for k in 20:
		_vfx.call(&"_process", 0.0)
	print("TitanVfx _process (%d effects, %d trails): %.0f us avg of 20" % [_vfx.call(&"active_count"),
			(_vfx.get(&"_trails") as Array).size(), float(Time.get_ticks_usec() - a) / 20.0])
	await _wait(0.2)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path(OUT + "stress.png"))
	print("stress: running=", _vfx.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	for d in dragons:
		d.queue_free()
	await _wait(6.0)
	print("after 6 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
