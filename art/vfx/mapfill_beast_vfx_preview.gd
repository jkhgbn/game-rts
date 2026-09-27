extends SceneTree
## Contact sheet of the 9 epic-beast effects (task 12.V31) -> docs/art/screens/12_v31_beast_vfx.png (4 x 3 cells, RTS
## camera: pitch 55, fov 50): each effect at its most telling moment, plus the Gore Charge mid-run, the Gale Swoop
## mid-dive and the beast_spawn flock seen from zoom 45. With `--all`: one full-size shot per cell,
## docs/art/screens/12_v31_<name>.png. Then a stress shot (every effect x 3 at once) -> 12_v31_stress.png.
## Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/mapfill_beast_vfx_preview.gd --fixed-fps 60 --quit-after 4000
## Stand-in bodies: the step-12 beast models if they exist (art/units/neutral/beasts/<kind>/<kind>.tscn), else the
## Bristleback (tusker), the deer (direwolf), the Hollow Stag (grizzlemaw) and a dark box bird (roc); victims = Flame
## Guards. The beasts are moved along their dash / leap here at the ability speeds (12 / 16 m/s).

const CELL := Vector2i(640, 360)
const COLS := 4
const SPACING := 70.0
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\n"
const MODELS := {
	&"tusker": ["res://art/units/neutral/beasts/tusker/tusker.tscn", "res://art/units/neutral/bristleback/bristleback.tscn"],
	&"roc": ["res://art/units/neutral/beasts/roc/roc.tscn", ""],
	&"direwolf": ["res://art/units/neutral/beasts/direwolf/direwolf.tscn", "res://art/units/neutral/critters/deer.tscn"],
	&"grizzlemaw": ["res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn",
			"res://art/units/neutral/hollow_stag/hollow_stag.tscn"],
	&"soldier": ["res://art/units/fire/flame_guard.tscn", ""],
}
## Stand-in scale when the real beast model is missing.
const STAND_IN_SCALE := {&"tusker": 1.8, &"direwolf": 1.25, &"grizzlemaw": 0.9}
## [name, effect id, shot time (s), zoom, label]
const SHOTS := [
	[&"gore_run", &"gore_charge", 0.55, 16.0, "gore_charge: dust + clods trail, furrow with tusk gouges (mid-run)"],
	[&"gore_charge", &"gore_charge", 1.02, 14.0, "gore_charge: impact where it stops (shock ring, dust, clods)"],
	[&"gale_dive", &"gale_swoop", 0.3, 15.0, "gale_swoop: mark on the target spot + wind streak (mid-dive)"],
	[&"gale_swoop", &"gale_swoop", 0.62, 13.0, "gale_swoop: storm-blue wind ring r 2.5, gusts, feathers"],
	[&"shrieking_dive", &"shrieking_dive", 0.66, 13.0, "shrieking_dive: violet shriek ring + air ripples"],
	[&"updraft", &"updraft", 0.75, 13.0, "updraft: feather swirl in a wind column (A storm / B dusk)"],
	[&"pounce", &"pounce", 0.85, 11.0, "pounce: leap streak + root claw marks (A grey / B moon)"],
	[&"hamstring", &"hamstring", 0.12, 5.5, "hamstring: small red slash on the legs"],
	[&"maul", &"maul", 0.15, 8.0, "maul: three-claw swipe + impact"],
	[&"rending_roar", &"rending_roar", 0.36, 19.0, "rending_roar: shock ring to r 6, cracks, ripples"],
	[&"beast_spawn", &"beast_spawn", 1.3, 22.0, "beast_spawn: a flock rises over the lair"],
	[&"beast_spawn_far", &"beast_spawn", 1.9, 45.0, "beast_spawn at zoom 45 (the distant tell)"],
]

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript
var _all := false
var _movers: Array[Dictionary] = []    # {n, to, speed}


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
	pm.size = Vector2(800, 800)
	ground.mesh = pm
	var gm := ShaderMaterial.new()   # plain painted grass (same as the other VFX previews)
	gm.shader = load("res://art/shaders/painted.gdshader")
	gm.set_shader_parameter(&"base_color", Color(0.32, 0.36, 0.2))
	gm.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	gm.set_shader_parameter(&"noise_scale_a", 0.15)
	gm.set_shader_parameter(&"noise_scale_b", 0.04)
	gm.set_shader_parameter(&"rim_strength", 0.0)
	ground.material_override = gm
	ground.position = Vector3(120, 0, 80)
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
	_vfx = (load("res://art/vfx/mapfill_beast_vfx.gd") as GDScript).new()
	_world.add_child(_vfx)
	_run.call_deferred()


func _cell(i: int) -> Vector3:
	return Vector3(float(i % COLS) * SPACING, 0.0, float(i / COLS) * SPACING)


func _model(kind: StringName) -> Node3D:
	var paths: Array = MODELS[kind]
	for j in paths.size():
		var path: String = paths[j]
		if path == "" or not ResourceLoader.exists(path):
			continue
		var ps := load(path) as PackedScene
		if ps:
			var n := ps.instantiate() as Node3D
			if n:
				if j > 0 and STAND_IN_SCALE.has(kind):
					n.scale = Vector3.ONE * float(STAND_IN_SCALE[kind])
				return n
	if kind == &"roc":
		return _box_bird()
	return null


## A crude dark bird (the Roc model is not there yet): body + two long wings, 2.5 m up, a shadow blob.
func _box_bird() -> Node3D:
	var n := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.26, 0.34)
	for spec: Array in [[Vector3(0.7, 0.5, 1.8), Vector3(0, 2.5, 0)], [Vector3(4.6, 0.12, 1.0), Vector3(0, 2.6, 0.1)]]:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = spec[0]
		m.mesh = b
		m.material_override = mat
		m.position = spec[1]
		n.add_child(m)
	return n


func _body(kind: StringName, team: int, pos: Vector3, face: Vector3, h: float, r: float, variant: int = 0) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	u.set(&"body_height", h)
	u.set(&"radius", r)
	u.set_meta(&"beast_variant", variant)
	var model := _model(kind)
	if model:
		u.add_child(model)
		if model.has_method(&"set_variant"):
			model.call(&"set_variant", variant)
	_world.add_child(u)
	u.global_position = pos
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


## A dash / leap: from the beast's spot to `to` at `speed`, then it stops.
func _move(n: Node3D, to: Vector3, speed: float) -> void:
	_movers.append({"n": n, "to": to, "speed": speed})


func _step_movers(dt: float) -> void:
	for m in _movers:
		var n: Node3D = m["n"]
		if not is_instance_valid(n):
			continue
		var to: Vector3 = m["to"]
		var d := to - n.global_position
		var step := float(m["speed"]) * dt
		n.global_position = to if d.length() <= step else n.global_position + d.normalized() * step


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var rows := (SHOTS.size() + COLS - 1) / COLS
	var sheet := Image.create_empty(CELL.x * COLS, CELL.y * rows, false, Image.FORMAT_RGBA8)
	await _wait(0.5)
	for i in SHOTS.size():
		var spec: Array = SHOTS[i]
		var shot: StringName = spec[0]
		var id: StringName = spec[1]
		var c := _cell(i)
		var at := c
		var target: Node3D = null
		var focus := c
		_movers.clear()
		var extra: Array = []   # a second effect started together with the main one: [id, at, target]
		match shot:
			&"gore_run", &"gore_charge":
				var v := _body(&"soldier", 0, c + Vector3(5.5, 0.0, 0.0), c + Vector3(-6, 0, 0), 1.8, 0.45)
				_body(&"soldier", 0, c + Vector3(6.6, 0.0, 1.4), c + Vector3(-6, 0, 0), 1.8, 0.45)
				target = _body(&"tusker", 2, c + Vector3(-7.0, 0.0, 0.0), v.global_position, 2.0, 1.0)
				at = v.global_position - Vector3(1.55, 0.0, 0.0)
				_move(target, at, 12.0)
				focus = c + Vector3(-0.5, 0.0, 0.0)
			&"gale_dive", &"gale_swoop", &"shrieking_dive":
				var v := _body(&"soldier", 0, c + Vector3(1.3, 0.0, 0.0), c + Vector3(-6, 0, -2), 1.8, 0.45)
				_body(&"soldier", 0, c + Vector3(2.2, 0.0, 1.3), c + Vector3(-6, 0, -2), 1.8, 0.45)
				_body(&"soldier", 0, c + Vector3(2.4, 0.0, -1.2), c + Vector3(-6, 0, -2), 1.8, 0.45)
				var variant := 1 if id == &"shrieking_dive" else 0
				target = _body(&"roc", 2, c + Vector3(-6.5, 0.0, -2.5), v.global_position, 3.2, 0.9, variant)
				at = c
				_move(target, at, 16.0)
				focus = c + Vector3(-1.5, 0.0, -0.5)
			&"updraft":
				# Both variants side by side: storm (A) left, dusk (B) right.
				target = _body(&"roc", 2, c + Vector3(-3.2, 0.0, 0.0), c + Vector3(0, 0, 8), 3.2, 0.9, 0)
				var b := _body(&"roc", 2, c + Vector3(3.2, 0.0, 0.0), c + Vector3(0, 0, 8), 3.2, 0.9, 1)
				extra = [&"updraft", b.global_position, b]
				at = target.global_position
				focus = c + Vector3(0.0, 1.5, 0.0)
			&"pounce":
				# Greymane (A) above, Moonpelt (B) below.
				var v := _body(&"soldier", 0, c + Vector3(1.6, 0.0, -2.2), c + Vector3(-6, 0, -2.2), 1.8, 0.45)
				var v2 := _body(&"soldier", 0, c + Vector3(1.6, 0.0, 2.2), c + Vector3(-6, 0, 2.2), 1.8, 0.45)
				target = _body(&"direwolf", 2, c + Vector3(-6.0, 0.0, -2.2), v.global_position, 1.8, 0.8, 0)
				var w2 := _body(&"direwolf", 2, c + Vector3(-6.0, 0.0, 2.2), v2.global_position, 1.8, 0.8, 1)
				at = v.global_position - Vector3(1.35, 0.0, 0.0)
				var at2 := v2.global_position - Vector3(1.35, 0.0, 0.0)
				_move(target, at, 16.0)
				_move(w2, at2, 16.0)
				extra = [&"pounce", at2, w2]
				focus = c + Vector3(-1.5, 0.0, 0.0)
			&"hamstring":
				target = _body(&"soldier", 0, c, c + Vector3(-3, 0, 1), 1.8, 0.45)
				_body(&"direwolf", 2, c + Vector3(-1.9, 0.0, 0.4), c, 1.8, 0.8)
				at = c
				focus = c + Vector3(-0.5, 0.4, 0.0)
			&"maul":
				target = _body(&"soldier", 0, c, c + Vector3(-3, 0, 0), 1.8, 0.45)
				_body(&"grizzlemaw", 2, c + Vector3(-2.3, 0.0, 0.0), c, 2.6, 1.1)
				at = c
				focus = c + Vector3(-0.8, 0.5, 0.0)
			&"rending_roar":
				target = _body(&"grizzlemaw", 2, c, c + Vector3(0, 0, 6), 2.6, 1.1)
				for k in 6:
					var a := float(k) * TAU / 6.0 + 0.3
					_body(&"soldier", 0, c + Vector3(cos(a), 0.0, sin(a)) * (3.0 + float(k % 3)), c, 1.8, 0.45)
				at = c
			&"beast_spawn", &"beast_spawn_far":
				target = _body(&"grizzlemaw", 2, c, c + Vector3(0, 0, 6), 2.6, 1.1)
				at = c
				focus = c + Vector3(0.0, 3.0 if shot == &"beast_spawn" else 5.0, 0.0)
		_frame(focus, float(spec[3]))
		_label.text = String(spec[4])
		await _wait(0.4)
		_vfx.call(&"play", id, at, target)
		if not extra.is_empty():
			_vfx.call(&"play", extra[0], extra[1], extra[2])
		var shot_at: float = spec[2]
		var t := 0.0
		while t < shot_at:
			await process_frame
			var dt := 1.0 / 60.0
			t += dt
			_step_movers(dt)
		var img := await _grab()
		if _all:
			img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v31_%s.png" % shot))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot ", shot, " fps=", Engine.get_frames_per_second(), " draw_calls=",
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v31_beast_vfx.png"))
	print("saved docs/art/screens/12_v31_beast_vfx.png")
	await _stress()
	quit()


## Every effect x 3 at once around a crowd (cost check), then everything must end.
func _stress() -> void:
	var c := Vector3(100.0, 0.0, 260.0)
	var units: Array[Node3D] = []
	for i in 12:
		units.append(_body(&"soldier", 0, c + Vector3(-9.0 + float(i % 6) * 3.6, 0.0, -3.0 + float(i / 6) * 5.0), c,
				1.8, 0.45))
	var beasts: Array[Node3D] = []
	for i in 4:
		beasts.append(_body(&"tusker", 2, c + Vector3(-10.0 + float(i) * 6.0, 0.0, -9.0), c, 2.0, 1.0))
	_frame(c, 30.0)
	_label.text = "stress: 9 effects x 3 at once (zoom 30)"
	await _wait(0.4)
	var ids: Array = [&"gore_charge", &"gale_swoop", &"shrieking_dive", &"updraft", &"pounce", &"hamstring", &"maul",
			&"rending_roar", &"beast_spawn"]
	_movers.clear()
	for k in 3:
		for j in ids.size():
			var id: StringName = ids[j]
			var u := units[(k * 4 + j) % units.size()]
			var b := beasts[(k + j) % beasts.size()]
			if id == &"hamstring" or id == &"maul":
				_vfx.call(&"play", id, u.global_position, u)
			else:
				_vfx.call(&"play", id, u.global_position, b)
	for b in beasts:
		_move(b, b.global_position + Vector3(0.0, 0.0, 7.0), 12.0)
	var a := Time.get_ticks_usec()
	_vfx.call(&"_process", 1.0 / 60.0)
	print("MapFillBeastVfx _process (27 fresh effects): %d us" % (Time.get_ticks_usec() - a))
	var t := 0.0
	while t < 0.5:
		await process_frame
		t += 1.0 / 60.0
		_step_movers(1.0 / 60.0)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v31_stress.png"))
	print("stress: running=", _vfx.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	await _wait(5.0)
	print("after 5 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
