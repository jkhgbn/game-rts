extends SceneTree
## Contact sheet of the 12 champion ability effects (task 9.V5) -> docs/art/screens/champion_vfx.png (4 x 3 cells,
## RTS camera: pitch 55, fov 50) + one full-size shot per effect under docs/art/screens/champion_vfx_<id>.png with
## `--all`. Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/champion_vfx_preview.gd --fixed-fps 60 --quit-after 3000
## Stand-in bodies: the champion models if they exist (art/units/champions/<id>/<id>.tscn), else kingdom units.
## Prints fps / draw calls for a stress shot (6 casters firing everything at once over 60 units).

const CELL := Vector2i(640, 360)
const COLS := 4
const SPACING := 60.0
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\n"
const STAND_INS := {&"wayfinder": "fire/ember_archer", &"oathwall": "ice/rimeshield", &"coin_cutter": "shadow/shade",
		&"mender": "nature/bloomtender"}
const HEIGHTS := {&"wayfinder": 1.8, &"oathwall": 2.0, &"coin_cutter": 1.7, &"mender": 1.7}
## id -> [champion, shot time (s), zoom, label]
const SHOTS := [
	[&"flare_arrow", &"wayfinder", 0.72, 22.0, "flare_arrow: arc, blast, flare ball + light pool r 8"],
	[&"snare_line", &"wayfinder", 0.16, 13.0, "snare_line: rope snaps, root coils"],
	[&"trailblaze", &"wayfinder", 0.4, 24.0, "trailblaze: golden wind ring r 8 + trail"],
	[&"oath_of_iron", &"oathwall", 0.5, 18.0, "oath_of_iron: shockwave r 6 + taunt badges"],
	[&"shield_bash", &"oathwall", 0.12, 11.0, "shield_bash: impact star + daze stars"],
	[&"bulwark_stand", &"oathwall", 0.8, 19.0, "bulwark_stand: planted shield dome r 5"],
	[&"cutpurse", &"coin_cutter", 0.16, 11.0, "cutpurse: gold coin sparks"],
	[&"smoke_pouch", &"coin_cutter", 0.8, 15.0, "smoke_pouch: charcoal smoke r 3"],
	[&"marked_for_coin", &"coin_cutter", 1.2, 11.0, "marked_for_coin: spinning coin mark"],
	[&"mending_draught", &"mender", 0.3, 11.0, "mending_draught: splash, +, rising motes"],
	[&"soothing_circle", &"mender", 1.3, 17.0, "soothing_circle: heal circle r 5"],
	[&"lifeline", &"mender", 0.55, 11.0, "lifeline: thread + green-gold bubble"],
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
	pm.size = Vector2(600, 600)
	ground.mesh = pm
	var gm := ShaderMaterial.new()   # plain painted grass (same as the other VFX previews)
	gm.shader = load("res://art/shaders/painted.gdshader")
	gm.set_shader_parameter(&"base_color", Color(0.32, 0.36, 0.2))
	gm.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	gm.set_shader_parameter(&"noise_scale_a", 0.15)
	gm.set_shader_parameter(&"noise_scale_b", 0.04)
	gm.set_shader_parameter(&"rim_strength", 0.0)
	ground.material_override = gm
	ground.position = Vector3(90, 0, 60)
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


func _body(team: int, pos: Vector3, champion: StringName, face: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	var path := ""
	if champion != &"":
		path = "res://art/units/champions/%s/%s.tscn" % [champion, champion]
		if not ResourceLoader.exists(path):
			path = "res://art/units/%s.tscn" % STAND_INS[champion]
		u.set(&"body_height", HEIGHTS[champion])
	else:
		path = "res://art/units/%s.tscn" % ("shadow/gloom_thrall" if team == 1 else "fire/flame_guard")
	var model: Node3D = (load(path) as PackedScene).instantiate()
	u.add_child(model)
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


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var sheet := Image.create_empty(CELL.x * COLS, CELL.y * ((SHOTS.size() + COLS - 1) / COLS), false, Image.FORMAT_RGBA8)
	await _wait(0.5)
	for i in SHOTS.size():
		var spec: Array = SHOTS[i]
		var id: StringName = spec[0]
		var champ: StringName = spec[1]
		var c := _cell(i)
		var caster_pos := c + Vector3(-2.6, 0.0, 1.2)
		var target_pos := c + Vector3(2.4, 0.0, -0.6)
		var focus := c
		match id:
			&"flare_arrow":
				caster_pos = c + Vector3(-6.0, 0.0, 3.5)
				target_pos = c + Vector3(3.5, 0.0, -1.5)
			&"trailblaze", &"oath_of_iron", &"bulwark_stand", &"smoke_pouch":
				caster_pos = c
			&"soothing_circle":
				caster_pos = c + Vector3(-5.5, 0.0, 3.0)
				target_pos = c + Vector3(1.0, 0.0, -0.5)
				focus = c + Vector3(-1.0, 0.0, 0.5)
		var caster := _body(0, caster_pos, champ, target_pos)
		var target: Node3D = null
		match id:
			&"oath_of_iron":
				for p: Vector3 in [Vector3(3.2, 0, -1.5), Vector3(-2.8, 0, -2.4), Vector3(1.0, 0, -4.2), Vector3(4.2, 0, 2.0)]:
					_body(1, c + p, &"", caster_pos)
			&"bulwark_stand":
				for p: Vector3 in [Vector3(2.2, 0, 1.4), Vector3(-2.0, 0, 1.8), Vector3(0.6, 0, -2.6)]:
					_body(0, c + p, &"", c + Vector3(0, 0, -8))
				_body(1, c + Vector3(6.5, 0, -3.0), &"", c)
			&"soothing_circle":
				for p: Vector3 in [Vector3(-1.0, 0, 0.4), Vector3(2.4, 0, 1.4), Vector3(1.2, 0, -2.6), Vector3(3.2, 0, -1.2)]:
					_body(0, c + p, &"", c + Vector3(0, 0, -8))
			&"trailblaze", &"smoke_pouch":
				pass
			_:
				var ally := id == &"mending_draught" or id == &"lifeline"
				target = _body(0 if ally else 1, target_pos, &"", caster_pos)
		_frame(focus, float(spec[3]))
		_label.text = String(spec[4])
		await _wait(0.4)
		var t_arg: Variant = target if target else (target_pos if id == &"flare_arrow" or id == &"soothing_circle" else caster)
		_vfx.call(&"play", id, caster, t_arg)
		var shot_at: float = spec[2]
		var t := 0.0
		while t < shot_at:
			await process_frame
			var dt := 1.0 / 60.0
			t += dt
			if id == &"trailblaze" or id == &"smoke_pouch":
				caster.global_position += Vector3(5.5 * dt, 0.0, -2.0 * dt)   # runs off with the haste / shroud
		var img := await _grab()
		if _all:
			img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/champion_vfx_%s.png" % id))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot ", id, " fps=", Engine.get_frames_per_second(), " draw_calls=",
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/screens/champion_vfx.png"))
	print("saved docs/art/screens/champion_vfx.png")
	await _stress()
	quit()


## ChampionVfx._process timed by hand over 60 frames (TIME_PROCESS is too noisy with other Godot runs around).
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


## 6 champions casting everything within 2 s over 60 units (cost check), then everything must end.
func _stress() -> void:
	var c := Vector3(60.0, 0.0, 200.0)
	var units: Array[Node3D] = []
	for i in 60:
		units.append(_body(i % 2, c + Vector3(-14.0 + float(i % 10) * 3.0, 0.0, -8.0 + float(i / 10) * 3.0), &"", c))
	var casters: Array[Node3D] = []
	for i in 6:
		casters.append(_body(i % 2, c + Vector3(-10.0 + float(i) * 4.0, 0.0, 6.0), [&"wayfinder", &"oathwall",
				&"coin_cutter", &"mender"][i % 4], c))
	_frame(c, 40.0)
	_label.text = "stress: 6 casters x 12 effects over 60 units (zoom 40)"
	await _wait(0.5)
	var ids: Array = SHOTS.map(func(s: Array) -> StringName: return s[0])
	for k in 12:
		for ci in 6:
			var tgt := units[(k * 7 + ci * 11) % units.size()]
			_vfx.call(&"play", ids[(k + ci) % 12], casters[ci], tgt)
		await _wait(0.15)
	await _wait(0.3)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/champion_vfx_stress.png"))
	print("stress: running=", _vfx.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	await _time_process("fresh casts")
	await _wait(1.5)
	await _time_process("2 s later")
	# A realistic fight: 6 champions, one cast each every ~1.5 s (far above their cooldowns).
	await _wait(7.0)
	for k in 8:
		for ci in 6:
			if (k + ci) % 4 == 0:
				_vfx.call(&"play", ids[(k * 5 + ci) % 12], casters[ci], units[(k * 3 + ci * 7) % units.size()])
		await _wait(0.5)
	await _time_process("6 champions, busy fight")
	await _wait(9.0)
	print("after 9 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
