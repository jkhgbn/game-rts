extends SceneTree
## Previews of the rune-rifle effects (task 13b.V7) through UnitVfx, with the real Frostrune Rifleman model (13b.V2)
## and the game's world_env + sun + ground. Saves docs/art/screens/13b_v7_*.png:
##   shot_close (side close-up at the flash peak), shot_after (0.3 s: snowflakes, vapour), tracer (the streak in
##   flight, zoom 12), impact (the rime impact, close), brace_draw / brace_closed / brace_idle (the circle at 0.5 s,
##   1.05 s, 3 s), aim_early / aim_late (Rime Lock at 0.35 s / 1.05 s), freeze_hit / freeze_hold (the shot + spikes at
##   0.05 s / 0.6 s), game40 (6 braced riflemen firing + a Rime Lock at the game camera, 40 m), game40_freeze,
##   stress (20 rifles + 10 locks + 10 freezes), sheet (contact sheet).
## Windowed (needs a GPU), frame-exact:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/unit_ice_rifle_vfx_preview.gd --fixed-fps 60 --quit-after 6000

const CELL := Vector2i(640, 360)
const COLS := 4
const ROWS := 4
const OUT := "res://docs/art/screens/13b_v7_%s.png"
const RIFLEMAN := "res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn"
const SHADE := "res://art/units/shadow/shade.tscn"
const ICE := Color(0.45, 0.75, 0.95)
const SHADOW := Color(0.42, 0.22, 0.60)
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nfunc is_alive() -> bool:\n\treturn true\nfunc get_model() -> Node3D:\n\treturn get_child(0) as Node3D if get_child_count() > 0 else null\n"

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript
var _live: Array[Node3D] = []
var _sheet: Image
var _cells := 0


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
	ground.position = Vector3(100, 0, 100)
	_world.add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	_world.add_child(_cam)
	var layer := CanvasLayer.new()
	_world.add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 24)
	_label.add_theme_font_size_override(&"font_size", 30)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 10)
	layer.add_child(_label)
	_vfx = (load("res://art/vfx/unit_vfx.gd") as GDScript).new()
	_world.add_child(_vfx)
	_sheet = Image.create_empty(CELL.x * COLS, CELL.y * ROWS, false, Image.FORMAT_RGBA8)
	_run.call_deferred()


## A unit stand-in (team, body_height, get_model) holding a model, facing yaw degrees (0 = +Z).
func _unit(path: String, team: int, pos: Vector3, yaw: float, tint: Color) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	_world.add_child(u)
	u.global_position = pos
	u.rotation.y = deg_to_rad(yaw)
	var m := (load(path) as PackedScene).instantiate() as Node3D
	u.add_child(m)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", tint)
	_live.append(u)
	return u


func _model(u: Node3D) -> Node3D:
	return u.get_child(0) as Node3D


func _clear() -> void:
	for u in _live:
		u.queue_free()
	_live.clear()


func _frame(focus: Vector3, zoom: float, pitch: float = 55.0, yaw: float = 0.0) -> void:
	var p := deg_to_rad(pitch)
	var y := deg_to_rad(yaw)
	_cam.position = focus + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * zoom
	_cam.look_at(focus, Vector3.UP)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shoot(name: String, cell: bool = true) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT % name))
	print("saved ", OUT % name, " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if cell and _cells < COLS * ROWS:
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		_sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((_cells % COLS) * CELL.x, (_cells / COLS) * CELL.y))
		_cells += 1


## The rifle_shot pose on these shooters, the 0.10 s crack, then rifle_shot + frost_tracer from each.
func _fire(shooters: Array[Node3D], targets: Array[Node3D]) -> void:
	for s in shooters:
		_model(s).call(&"play_attack")
	await _frames(6)
	for i in shooters.size():
		var t: Node3D = targets[i % targets.size()]
		_vfx.call(&"play", &"rifle_shot", shooters[i], t)
		_vfx.call(&"play", &"frost_tracer", shooters[i], {"to": t, "impact": true})


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _frames(20)
	# 1. Close-up of one shot (side view: flash peak, then 0.3 s later).
	var c := Vector3(0, 0, 0)
	var s1 := _unit(RIFLEMAN, 0, c, 90.0, ICE)
	var tgt := _unit(SHADE, 1, c + Vector3(12.0, 0, 0), -90.0, SHADOW)
	_frame(c + Vector3(1.6, 1.1, 0), 4.2, 10.0, 0.0)
	_label.text = "rifle_shot: ice lance + star + rune rings (0.03 s)"
	await _frames(20)
	var one: Array[Node3D] = [s1]
	var tg: Array[Node3D] = [tgt]
	await _fire(one, tg)
	await _frames(2)
	await _shoot("shot_close")
	_label.text = "rifle_shot: 0.3 s (snowflakes, cold vapour)"
	await _frames(16)
	await _shoot("shot_after")
	_clear()
	# 2. The tracer in flight (zoom 12), then the rime impact.
	c = Vector3(40, 0, 0)
	var s2 := _unit(RIFLEMAN, 0, c, 90.0, ICE)
	var t2 := _unit(SHADE, 1, c + Vector3(13.0, 0, 0), -90.0, SHADOW)
	_frame(c + Vector3(6.5, 0, 0), 13.0, 50.0, 0.0)
	_label.text = "frost_tracer: 13 m streak at 0.05 s"
	await _frames(20)
	var two: Array[Node3D] = [s2]
	var tg2: Array[Node3D] = [t2]
	await _fire(two, tg2)
	await _frames(2)
	await _shoot("tracer")
	_frame(t2.global_position + Vector3(0, 0.8, 0), 5.5, 35.0, 0.0)
	_label.text = "rifle_impact: star, ice chips, snowflakes, rime (0.1 s)"
	_vfx.call(&"play", &"rifle_impact", t2, t2)
	await _frames(6)
	await _shoot("impact")
	await _frames(60)
	_clear()
	# 3. Brace circle: drawing, closing, idle.
	c = Vector3(80, 0, 0)
	var s3 := _unit(RIFLEMAN, 0, c, 60.0, ICE)
	_frame(c + Vector3(0, 0.6, 0), 5.5, 48.0, 20.0)
	await _frames(20)
	_model(s3).call(&"set_braced", true)
	_vfx.call(&"play", &"brace", s3, null)
	_label.text = "brace: rune circle drawing (0.5 s)"
	await _frames(30)
	await _shoot("brace_draw")
	_label.text = "brace: circle closes with the kneel (1.05 s)"
	await _frames(33)
	await _shoot("brace_closed")
	_label.text = "brace: held while braced (3 s)"
	await _frames(117)
	await _shoot("brace_idle")
	# 4. Rime Lock from the braced rifleman at a Shade 13 m away.
	var t4 := _unit(SHADE, 1, c + Vector3(11.0, 0, 6.5), -120.0, SHADOW)
	_frame(c + Vector3(5.5, 0.5, 3.2), 11.0, 45.0, 0.0)
	await _frames(10)
	_model(s3).call(&"play_aim", 1.2)
	_vfx.call(&"play", &"rime_lock_aim", s3, t4)
	_label.text = "rime_lock_aim: 0.35 s (dashes flowing, reticle closing)"
	await _frames(21)
	await _shoot("aim_early")
	_label.text = "rime_lock_aim: 1.05 s (charged, solid line)"
	await _frames(42)
	await _shoot("aim_late")
	await _frames(9)
	_model(s3).call(&"play_attack")
	await _frames(6)
	_vfx.call(&"play", &"rifle_shot", s3, t4)
	_vfx.call(&"play", &"rime_lock_hit", t4, t4)
	_label.text = "rime_lock_hit: shot beam, freeze column, spikes (0.05 s)"
	await _frames(3)
	await _shoot("freeze_hit")
	_frame(t4.global_position + Vector3(0, 0.6, 0), 7.0, 38.0, 20.0)
	_label.text = "rime_lock_hit: spikes hold (0.6 s)"
	await _frames(33)
	await _shoot("freeze_hold")
	_label.text = "rime_lock_hit: spikes shatter (1.2 s)"
	await _frames(36)
	await _shoot("freeze_shatter")
	await _frames(40)
	_clear()
	# 5. Game camera (40 m): 6 braced riflemen fire at 4 Shades; one Rime Lock.
	c = Vector3(0, 0, 60)
	var six: Array[Node3D] = []
	for i in 6:
		var u := _unit(RIFLEMAN, 0, c + Vector3(-1.0 * float(i % 2), 0, -4.0 + 1.6 * float(i)), 90.0, ICE)
		six.append(u)
	var foes: Array[Node3D] = []
	for i in 4:
		foes.append(_unit(SHADE, 1, c + Vector3(13.0 + 1.0 * float(i % 2), 0, -3.0 + 2.0 * float(i)), -90.0, SHADOW))
	_frame(c + Vector3(6.5, 0, 0), 40.0)
	await _frames(10)
	for u in six:
		_model(u).call(&"set_braced", true)
		_vfx.call(&"play", &"brace", u, null)
	await _frames(75)
	_model(six[0]).call(&"play_aim", 1.2)
	_vfx.call(&"play", &"rime_lock_aim", six[0], foes[1])
	await _frames(30)
	var five: Array[Node3D] = []
	five.assign(six.slice(1, 6))
	await _fire(five, foes)
	await _frames(3)
	_label.text = "game camera 40 m: 5 shots + a Rime Lock aim (braced line)"
	await _shoot("game40")
	await _frames(35)
	_model(six[0]).call(&"play_attack")
	await _frames(6)
	_vfx.call(&"play", &"rifle_shot", six[0], foes[1])
	_vfx.call(&"play", &"rime_lock_hit", foes[1], foes[1])
	await _frames(8)
	_label.text = "game camera 40 m: Rime Lock freeze (0.13 s)"
	await _shoot("game40_freeze")
	await _frames(120)
	_clear()
	# 6. Stress: 20 rifles, 10 aims, then 10 freezes, 30 m.
	c = Vector3(0, 0, 140)
	var guns: Array[Node3D] = []
	for i in 20:
		guns.append(_unit(RIFLEMAN, 0, c + Vector3(-1.2 * float(i % 2), 0, -12.0 + 1.25 * float(i)), 90.0, ICE))
	var foes2: Array[Node3D] = []
	for i in 10:
		foes2.append(_unit(SHADE, 1, c + Vector3(13.0, 0, -9.0 + 2.0 * float(i)), -90.0, SHADOW))
	_frame(c + Vector3(6.0, 0, 0), 36.0)
	await _frames(20)
	for i in 20:
		_model(guns[i]).call(&"set_braced", true)
		_vfx.call(&"play", &"brace", guns[i], null)
	for i in 10:
		_vfx.call(&"play", &"rime_lock_aim", guns[i * 2], foes2[i])
	await _frames(70)
	var odd: Array[Node3D] = []
	for i in 10:
		odd.append(guns[i * 2 + 1])
	await _fire(odd, foes2)
	for f in foes2:
		_vfx.call(&"play", &"rime_lock_hit", f, f)
	var fam: Node = null
	for f: Node in _vfx.call(&"families"):
		if f.has_method(&"aim_count"):
			fam = f
	var a := Time.get_ticks_usec()
	fam.call(&"_process", 0.0)
	print("stress: family _process (fresh) %d us, running %d" % [Time.get_ticks_usec() - a, fam.call(&"active_count")])
	_label.text = "stress: 20 braced rifles, 10 shots, 10 Rime Lock freezes"
	await _frames(4)
	await _shoot("stress")
	await _frames(30)
	var t0 := Time.get_ticks_usec()
	for i in 60:
		await process_frame
	print("stress steady: fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " wall 60 frames=",
			(Time.get_ticks_usec() - t0) / 1000, " ms, braces=", fam.call(&"brace_count"))
	a = Time.get_ticks_usec()
	fam.call(&"_process", 0.0)
	print("stress steady: family _process %d us" % (Time.get_ticks_usec() - a))
	_sheet.save_png(ProjectSettings.globalize_path(OUT % "sheet"))
	print("saved sheet")
	for u in guns:
		_model(u).call(&"set_braced", false)
	await _frames(240)
	print("after 4 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
	quit()
