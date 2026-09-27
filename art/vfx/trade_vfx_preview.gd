extends SceneTree
## Contact sheet of the 7 trade effects + the loot sack (task 10.V11) -> docs/art/screens/trade_vfx.png (4 x 2 cells,
## RTS camera: pitch 55, fov 50), plus docs/art/screens/trade_loot_sack_far.png (the sack at zoom 30 beside units,
## the "can I see it from the RTS camera" check). With `--all`: one full-size shot per effect,
## docs/art/screens/trade_vfx_<id>.png. Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/trade_vfx_preview.gd --fixed-fps 60 --quit-after 3000
## Stand-in bodies: the step-10 models if they load (caravan, Magpie, tracker, Ember Bazaar, trading post), else
## kingdom units / the Fire Hall.

const CELL := Vector2i(640, 360)
const COLS := 4
const SPACING := 60.0
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\nfunc target_radius() -> float:\n\treturn radius\n"
const MODELS := {
	&"caravan": ["res://art/units/caravan/caravan.tscn", "res://art/units/ice/rime_hauler.tscn"],
	&"magpie": ["res://art/units/neutral/magpie/magpie.tscn", "res://art/units/shadow/shade.tscn"],
	&"tracker": ["res://art/units/neutral/tracker/tracker.tscn", "res://art/units/fire/ember_archer.tscn"],
	&"bazaar": ["res://art/buildings/market/fire/market_fire.tscn", "res://art/buildings/fire_hall.tscn"],
	&"post": ["res://art/buildings/trade_post/trade_post.tscn", ""],
	&"soldier": ["res://art/units/fire/flame_guard.tscn", ""],
}
## id -> [shot time (s), zoom, label]
const SHOTS := [
	[&"delivery", 0.3, 10.0, "delivery: gold motes rise 1.5 m, coins hop (0.6 s)"],
	[&"post_trade", 0.36, 11.0, "post_trade: road dust + 3 coins arc onto the caravan"],
	[&"snatch", 0.2, 7.5, "snatch: coin trail caravan -> Magpie (0.4 s)"],
	[&"smoke", 0.35, 12.0, "smoke: grey-blue puff r 3 (1.2 s)"],
	[&"sack_pickup", 0.2, 6.5, "sack_pickup: gold sparkle, coins hop to the taker"],
	[&"snare", 0.14, 7.5, "snare: rope coils bind the feet (0.5 s)"],
	[&"ware_bought", 0.42, 18.0, "ware_bought: gold ring pulse on the Bazaar"],
	[&"loot_sack", 1.2, 4.0, "loot sack: burlap, coin spill, gold rim + glow"],
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
	_vfx = (load("res://art/vfx/trade_vfx.gd") as GDScript).new()
	_world.add_child(_vfx)
	_run.call_deferred()


func _cell(i: int) -> Vector3:
	return Vector3(float(i % COLS) * SPACING, 0.0, float(i / COLS) * SPACING)


func _model(kind: StringName) -> Node3D:
	for path: String in MODELS[kind]:
		if path == "" or not ResourceLoader.exists(path):
			continue
		var ps := load(path) as PackedScene
		if ps:
			var n := ps.instantiate() as Node3D
			if n:
				return n
	return null


func _body(kind: StringName, team: int, pos: Vector3, face: Vector3, h: float = 1.8, r: float = 0.45) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	u.set(&"body_height", h)
	u.set(&"radius", r)
	var model := _model(kind)
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


func _sack(pos: Vector3, amount: int) -> Node3D:
	var s := (load("res://art/vfx/trade_loot_sack.tscn") as PackedScene).instantiate() as Node3D
	_world.add_child(s)
	s.global_position = pos
	s.call(&"set_amount", amount)
	return s


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
		var c := _cell(i)
		var at := c
		var target: Node3D = null
		var focus := c
		match id:
			&"delivery":
				_body(&"bazaar", 0, c + Vector3(-1.5, 0.0, -4.2), c + Vector3(0, 0, 8), 4.5, 3.0)
				target = _body(&"caravan", 0, c + Vector3(1.8, 0.0, 0.2), c + Vector3(-4, 0, 0.2), 1.9, 0.8)
				at = c + Vector3(-0.4, 0.0, 0.3)
				focus = c + Vector3(0.0, 0.0, -1.0)
			&"post_trade":
				_body(&"post", 2, c + Vector3(-3.6, 0.0, -2.2), c + Vector3(4, 0, 0), 5.0, 3.0)
				target = _body(&"caravan", 0, c + Vector3(1.4, 0.0, 0.4), c + Vector3(-4, 0, 0.4), 1.9, 0.8)
				_hook(target, &"set_loaded", [true])
				at = c + Vector3(-1.2, 0.0, 0.2)
			&"snatch":
				var car := _body(&"caravan", 0, c + Vector3(-1.6, 0.0, 0.4), c + Vector3(0, 0, -6), 1.9, 0.8)
				_hook(car, &"set_loaded", [true])
				target = _body(&"magpie", 2, c + Vector3(1.4, 0.0, 0.6), car.global_position, 1.6, 0.4)
				_hook(target, &"play_snatch", [])
				at = car.global_position
			&"smoke":
				var m := _body(&"magpie", 2, c, c + Vector3(3, 0, 3), 1.6, 0.4)
				at = m.global_position
			&"sack_pickup":
				_sack(c, 60)
				target = _body(&"soldier", 0, c + Vector3(1.1, 0.0, 0.5), c, 1.8, 0.45)
				at = c
			&"snare":
				target = _body(&"magpie", 2, c, c + Vector3(-4, 0, 2), 1.6, 0.4)
				_body(&"tracker", 0, c + Vector3(-4.5, 0.0, 1.8), c, 1.8, 0.45)
				at = c
				focus = c + Vector3(-1.2, 0.0, 0.4)
			&"ware_bought":
				target = _body(&"bazaar", 0, c, c + Vector3(0, 0, 8), 4.5, 3.0)
				at = c
			&"loot_sack":
				_sack(c, 120)
				_sack(c + Vector3(1.6, 0.0, -0.8), 20)
		_frame(focus, float(spec[2]))
		_label.text = String(spec[3])
		await _wait(0.4)
		if id != &"loot_sack":
			_vfx.call(&"play", id, at, target)
		var shot_at: float = spec[1]
		var t := 0.0
		while t < shot_at:
			await process_frame
			var dt := 1.0 / 60.0
			t += dt
			if id == &"snatch" and target:
				target.global_position += Vector3(2.5 * dt, 0.0, 0.0)   # the thief runs off, the coins follow
		var img := await _grab()
		if _all:
			img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/trade_vfx_%s.png" % id))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot ", id, " fps=", Engine.get_frames_per_second(), " draw_calls=",
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/screens/trade_vfx.png"))
	print("saved docs/art/screens/trade_vfx.png")
	await _far()
	await _stress()
	quit()


## The sack at the normal RTS zoom (30) beside a caravan and two soldiers: it must read as a gold drop.
func _far() -> void:
	var c := Vector3(200.0, 0.0, 0.0)
	_sack(c, 60)
	_body(&"caravan", 0, c + Vector3(-4.0, 0.0, -1.5), c, 1.9, 0.8)
	_body(&"soldier", 0, c + Vector3(3.0, 0.0, 1.0), c, 1.8, 0.45)
	_body(&"magpie", 2, c + Vector3(2.0, 0.0, -3.0), c, 1.6, 0.4)
	_frame(c, 30.0)
	_label.text = "loot sack at zoom 30 (beside a caravan, a soldier, a Magpie)"
	await _wait(1.0)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/trade_loot_sack_far.png"))


## Every effect twice at once over a small area (cost check), then everything must end.
func _stress() -> void:
	var c := Vector3(60.0, 0.0, 200.0)
	var units: Array[Node3D] = []
	for i in 12:
		units.append(_body(&"soldier", i % 2, c + Vector3(-8.0 + float(i % 6) * 3.0, 0.0, -3.0 + float(i / 6) * 4.0), c))
	_frame(c, 30.0)
	_label.text = "stress: 7 effects x 4 at once (zoom 30)"
	await _wait(0.4)
	var ids: Array = [&"delivery", &"post_trade", &"snatch", &"smoke", &"sack_pickup", &"snare", &"ware_bought"]
	for k in 4:
		for j in ids.size():
			var u := units[(k * 3 + j) % units.size()]
			_vfx.call(&"play", ids[j], u.global_position, units[(k + j + 5) % units.size()])
	var a := Time.get_ticks_usec()
	_vfx.call(&"_process", 1.0 / 60.0)
	print("TradeVfx _process (28 fresh effects): %d us" % (Time.get_ticks_usec() - a))
	await _wait(0.25)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/trade_vfx_stress.png"))
	print("stress: running=", _vfx.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	await _wait(3.0)
	print("after 3 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
