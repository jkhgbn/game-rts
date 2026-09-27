extends SceneTree
## Previews of the Nature tier-3 effects (task 13b.V9) through UnitVfx, with the real Glade Outrider (13b.V3) and
## Mossback (13b.V4) models and the game's world_env + sun + ground. Saves docs/art/screens/13b_v9_*.png:
##   shot_close (an Outrider at the gallop looses at a Shade 12 m away: the arrow 0.15 s out, from the model's own
##   arrow_released through attach()), shot_land (the landing spark), game40_shots (6 Outriders at the game camera, 40 m),
##   kite (kite_dust as an Outrider bolts from a Flame Guard), canopy_wave / canopy_ring (the pulse at 0.35 s / 0.85 s,
##   zoom 18), block (canopy_block on 4 Burr Slingers shot by Ember Archers, close), game40_canopy (the pulse + blocks
##   at 40 m), stress (8 Outriders, 3 pulses, 30 blocks), sheet (contact sheet of the above).
## Windowed (needs a GPU), frame-exact:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/unit_nature_t3_vfx_preview.gd --fixed-fps 60 --quit-after 6000

const CELL := Vector2i(640, 360)
const COLS := 4
const OUT := "res://docs/art/screens/13b_v9_%s.png"
const OUTRIDER := "res://art/units/nature/glade_outrider/glade_outrider.tscn"
const MOSSBACK := "res://art/units/nature/mossback/mossback.tscn"
const SLINGER := "res://art/units/nature/burr_slinger.tscn"
const SHADE := "res://art/units/shadow/shade.tscn"
const GUARD := "res://art/units/fire/flame_guard.tscn"
const ARCHER := "res://art/units/fire/ember_archer.tscn"
const NATURE := Color(0.35, 0.70, 0.25)
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar attack_target: Node3D = null\nfunc is_alive() -> bool:\n\treturn true\nfunc get_model() -> Node3D:\n\treturn get_child(0) as Node3D if get_child_count() > 0 else null\n"

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _fam: Node3D
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
	_sheet = Image.create_empty(CELL.x * COLS, CELL.y * 3, false, Image.FORMAT_RGBA8)
	_run.call_deferred()


## A unit stand-in (team, body_height, attack_target, get_model) holding a model, facing yaw degrees (0 = +Z).
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
	if cell and _cells < COLS * 3:
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		_sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((_cells % COLS) * CELL.x, (_cells / COLS) * CELL.y))
		_cells += 1


## An Outrider at the gallop aiming at `target` (attached: its arrow_released plays parting_shot).
func _rider(pos: Vector3, yaw: float, target: Node3D) -> Node3D:
	var u := _unit(OUTRIDER, 0, pos, yaw, NATURE)
	u.set(&"attack_target", target)
	_model(u).call(&"set_moving", 7.6)
	_fam.call(&"attach", _model(u))
	return u


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for f: Node in _vfx.call(&"families"):
		if f.has_method(&"attach"):
			_fam = f
	_fam.set(&"auto_attach", false)   # deterministic captures: models are attached by hand, pulses forced
	await _frames(20)
	# 1. One parting shot, side view: the arrow 0.15 s out, then the landing.
	var c := Vector3(0, 0, 0)
	var foe := _unit(SHADE, 1, c + Vector3(12.0, 0, 0), -90.0, SHADOW)
	var r1 := _rider(c, 0.0, foe)   # galloping along +Z, the target to its right
	_frame(c + Vector3(4.0, 1.8, 0), 7.5, 10.0, -20.0)
	_label.text = "parting_shot: the arrow 0.15 s after the loose (gallop)"
	await _frames(30)
	_model(r1).call(&"play_attack")
	await _frames(7 + 9)
	await _shoot("shot_close")
	_frame(foe.global_position + Vector3(0, 1.0, 0), 5.0, 18.0, -60.0)
	_label.text = "parting_shot: the landing spark"
	await _frames(21)
	await _shoot("shot_land")
	await _frames(30)
	_clear()
	# 2. Game camera 40 m: 6 Outriders at the gallop shooting at 6 Shades, staggered.
	c = Vector3(40, 0, 0)
	var riders: Array[Node3D] = []
	var shades: Array[Node3D] = []
	for i in 6:
		shades.append(_unit(SHADE, 1, c + Vector3(10.0 + float(i % 2), 0, -5.0 + 2.0 * float(i)), -90.0, SHADOW))
	for i in 6:
		riders.append(_rider(c + Vector3(-1.5 * float(i % 2), 0, -6.0 + 2.2 * float(i)), 0.0, shades[(i + 2) % 6]))
	_frame(c + Vector3(5.0, 0, 0), 40.0)
	_label.text = "game camera 40 m: 6 Outriders shoot on the move"
	await _frames(30)
	for i in 6:
		_model(riders[i]).call(&"play_attack")
		await _frames(2)
	await _frames(6)
	await _shoot("game40_shots")
	await _frames(40)
	_clear()
	# 3. Kite dust: the Outrider bolts 5 m away from a Flame Guard.
	c = Vector3(80, 0, 0)
	var guard := _unit(GUARD, 1, c + Vector3(-1.8, 0, 0), 90.0, FIRE)
	var r3 := _unit(OUTRIDER, 0, c, 90.0, NATURE)
	_frame(c + Vector3(1.5, 0.6, 0), 9.0, 30.0, 25.0)
	_label.text = "kite_dust: the Outrider bolts from a Flame Guard (0.3 s)"
	await _frames(20)
	_model(r3).call(&"set_moving", 7.6)
	_vfx.call(&"play", &"kite_dust", r3, guard)
	for i in 18:
		r3.global_position += Vector3(7.6 / 60.0, 0, 0)
		await process_frame
	await _shoot("kite")
	await _frames(60)
	_clear()
	# 4. Canopy pulse: the Mossback + 5 Burr Slingers, zoom 18.
	c = Vector3(120, 0, 0)
	var moss := _unit(MOSSBACK, 0, c, 30.0, NATURE)
	_model(moss).call(&"set_canopy", true, true)
	var slingers: Array[Node3D] = []
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.3
		slingers.append(_unit(SLINGER, 0, c + Vector3(cos(a), 0, sin(a)) * 3.6, rad_to_deg(a) + 90.0, NATURE))
	_frame(c, 19.0, 58.0, 20.0)
	_label.text = "canopy_pulse: the wave (0.35 s)"
	await _frames(40)
	_vfx.call(&"play", &"canopy_pulse", moss, {"force": true})
	await _frames(21)
	await _shoot("canopy_wave")
	_label.text = "canopy_pulse: the leaf ring at r 6 (0.85 s)"
	await _frames(30)
	await _shoot("canopy_ring")
	await _frames(80)
	# 5. canopy_block: Ember Archers 10 m away shoot the slingers, close.
	var archers: Array[Node3D] = []
	for i in 4:
		archers.append(_unit(ARCHER, 1, c + Vector3(11.0, 0, -3.0 + 2.0 * float(i)), -90.0, FIRE))
	_frame(c + Vector3(2.5, 1.0, 0.5), 9.0, 28.0, 70.0)
	_label.text = "canopy_block: reduced shots land on the leaf shield"
	await _frames(20)
	for i in 4:
		_vfx.call(&"play", &"canopy_block", slingers[i], archers[i])
		await _frames(1)
	await _frames(3)
	await _shoot("block")
	await _frames(60)
	# 6. Game camera 40 m: pulse + blocks.
	_frame(c + Vector3(3.0, 0, 0), 40.0)
	_label.text = "game camera 40 m: Canopy pulse + blocked shots"
	await _frames(20)
	_vfx.call(&"play", &"canopy_pulse", moss, {"force": true})
	await _frames(40)
	for i in 5:
		_vfx.call(&"play", &"canopy_block", slingers[i], archers[i % 4])
	await _frames(10)
	await _shoot("game40_canopy")
	await _frames(90)
	_clear()
	# 7. Stress: 8 Outriders + 3 Mossbacks pulsing + 30 blocks, 34 m.
	c = Vector3(0, 0, 140)
	var tg: Array[Node3D] = []
	for i in 8:
		tg.append(_unit(SHADE, 1, c + Vector3(12.0, 0, -8.0 + 2.2 * float(i)), -90.0, SHADOW))
	var rs: Array[Node3D] = []
	for i in 8:
		rs.append(_rider(c + Vector3(0, 0, -9.0 + 2.4 * float(i)), 0.0, tg[i]))
	var ms: Array[Node3D] = []
	for i in 3:
		var m := _unit(MOSSBACK, 0, c + Vector3(-9.0, 0, -8.0 + 8.0 * float(i)), 90.0, NATURE)
		_model(m).call(&"set_canopy", true, true)
		ms.append(m)
	_frame(c + Vector3(1.0, 0, 0), 34.0)
	_label.text = "stress: 8 Outriders, 3 Canopy pulses, 30 blocks"
	await _frames(30)
	for r in rs:
		_model(r).call(&"play_attack")
	for m in ms:
		_vfx.call(&"play", &"canopy_pulse", m, {"force": true})
	for i in 30:
		_vfx.call(&"play", &"canopy_block", c + Vector3(-9.0 + float(i % 6) * 0.8, 1.0, -8.0 + 8.0 * float(i / 10)), tg[i % 8])
	var a0 := Time.get_ticks_usec()
	_fam.call(&"_process", 0.0)
	print("stress: family _process (fresh) %d us, running %d" % [Time.get_ticks_usec() - a0, _fam.call(&"active_count")])
	await _frames(12)
	await _shoot("stress")
	var t0 := Time.get_ticks_usec()
	for i in 30:
		await process_frame
	print("stress steady: fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " wall 30 frames=",
			(Time.get_ticks_usec() - t0) / 1000, " ms")
	_sheet.save_png(ProjectSettings.globalize_path(OUT % "sheet"))
	print("saved sheet")
	_clear()
	await _frames(240)
	print("after 4 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
	quit()
