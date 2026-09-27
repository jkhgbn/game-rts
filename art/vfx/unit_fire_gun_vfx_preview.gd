extends SceneTree
## Previews of the gunpowder effects (task 13b.V6) through UnitVfx, with the real Cinderlock model (13b.V1) and the
## game's world_env + sun + ground. Saves docs/art/screens/13b_v6_*.png:
##   shot_close (side close-up at the flash peak), shot_after (0.3 s: sparks + wisps), volley (6 guns, zoom 14),
##   smoke_1s / smoke_2s (the cloud r 4 at 1.2 s / 2.4 s), impact (a Shade hit, zoom 6), breach (a Shadow Hall hit),
##   game40 / game40_smoke (10 musketeers volleying 6 Shades at the game camera, 40 m), stress (20 guns + 12 clouds),
##   sheet (contact sheet of the above).
## Windowed (needs a GPU), frame-exact:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/unit_fire_gun_vfx_preview.gd --fixed-fps 60 --quit-after 6000

const CELL := Vector2i(640, 360)
const COLS := 4
const OUT := "res://docs/art/screens/13b_v6_%s.png"
const CINDER := "res://art/units/fire/cinderlock/cinderlock.tscn"
const SHADE := "res://art/units/shadow/shade.tscn"
const HALL := "res://art/buildings/shadow_hall.tscn"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nfunc is_alive() -> bool:\n\treturn true\nfunc get_model() -> Node3D:\n\treturn get_child(0) as Node3D if get_child_count() > 0 else null\n"
const HALL_SRC := "extends Node3D\nvar team: int = 1\nvar building_type: Resource = null\nfunc _ready() -> void:\n\tadd_to_group(&\"buildings\")\n"

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript
var _hall_script: GDScript
var _live: Array[Node3D] = []
var _sheet: Image
var _cells := 0


func _initialize() -> void:
	_stub = _script(STUB_SRC)
	_hall_script = _script(HALL_SRC)
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


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


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


## Starts the musket_volley pose on these shooters, waits the 0.15 s release, fires musket_shot from each muzzle.
func _fire(shooters: Array[Node3D], target: Node3D) -> void:
	for s in shooters:
		(s.get_child(0) as Node3D).call(&"play_attack")
	await _frames(9)
	for s in shooters:
		_vfx.call(&"play", &"musket_shot", (s.get_child(0) as Node3D).call(&"get_muzzle_xf"), target)


func _centre(nodes: Array[Node3D]) -> Vector3:
	var c := Vector3.ZERO
	for n in nodes:
		c += n.global_position
	return c / float(maxi(nodes.size(), 1))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _frames(20)
	# 1. Close-up of one shot (side view, the flash peak, then 0.3 s later).
	var c := Vector3(0, 0, 0)
	var s1 := _unit(CINDER, 0, c, 90.0, FIRE)
	var tgt := _unit(SHADE, 1, c + Vector3(8.0, 0, 0), -90.0, SHADOW)
	_frame(c + Vector3(1.2, 1.2, 0), 4.2, 12.0, 0.0)
	_label.text = "musket_shot: flame cone + flash + sparks (0.03 s)"
	await _frames(10)
	var one: Array[Node3D] = [s1]
	await _fire(one, tgt)
	await _frames(2)
	await _shoot("shot_close")
	_label.text = "musket_shot: 0.3 s (sparks, powder wisps)"
	await _frames(16)
	await _shoot("shot_after")
	_clear()
	# 2. A 6-gun volley at zoom 14 + the cloud.
	c = Vector3(40, 0, 0)
	var line: Array[Node3D] = []
	for i in 6:
		line.append(_unit(CINDER, 0, c + Vector3(0, 0, -3.75 + 1.5 * float(i)), 90.0, FIRE))
	var foes: Array[Node3D] = []
	for i in 4:
		foes.append(_unit(SHADE, 1, c + Vector3(8.5, 0, -2.5 + 1.7 * float(i)), -90.0, SHADOW))
	_frame(c + Vector3(3.5, 0, 0), 15.0)
	_label.text = "powder_volley: shock rings, flash, dust (6 guns)"
	await _frames(10)
	await _fire(line, foes[1])
	_vfx.call(&"play", &"powder_volley", _centre(line), foes[1])
	_vfx.call(&"play", &"powder_smoke", _centre(line), {"radius": 2.5 + 0.3 * 6.0, "team": 0})
	await _frames(3)
	await _shoot("volley")
	# Bullets land ~0.2 s later (8.5 m at 40 m/s).
	await _frames(9)
	for f in foes:
		_vfx.call(&"play", &"musket_impact", f, f)
	_label.text = "powder_smoke r 4.0 at 1.2 s"
	await _frames(50)
	await _shoot("smoke_1s")
	_label.text = "powder_smoke r 4.0 at 2.4 s (thinning)"
	await _frames(72)
	await _shoot("smoke_2s")
	await _frames(60)
	_clear()
	# 3. Impact on a unit (close).
	c = Vector3(80, 0, 0)
	var v := _unit(SHADE, 1, c, 0.0, SHADOW)
	_frame(c + Vector3(0, 0.8, 0), 6.5)
	_label.text = "musket_impact: fire burst, grit, sparks, splash ring r 1.5"
	await _frames(10)
	_vfx.call(&"play", &"musket_impact", v.global_position + Vector3(0, 1.0, 0.3), v)
	await _frames(5)
	await _shoot("impact")
	_label.text = "musket_impact: 0.4 s (smoke, scorch)"
	await _frames(20)
	await _shoot("impact_after")
	_clear()
	# 4. Breach on a building.
	c = Vector3(120, 0, 0)
	var hall := Node3D.new()
	hall.set_script(_hall_script)
	_world.add_child(hall)
	hall.global_position = c
	hall.add_child((load(HALL) as PackedScene).instantiate())
	_live.append(hall)
	_frame(c + Vector3(0, 1.5, 2.0), 13.0)
	_label.text = "musket_impact on a building: breach sparks, chips, dust"
	await _frames(20)
	for i in 3:
		_vfx.call(&"play", &"musket_impact", c + Vector3(-1.5 + 1.5 * float(i), 1.2 + 0.4 * float(i), 3.2), hall)
	await _frames(7)
	await _shoot("breach")
	await _frames(40)
	_clear()
	# 5. Game camera (40 m): 10 musketeers volley 6 Shades.
	c = Vector3(0, 0, 60)
	var ten: Array[Node3D] = []
	for i in 10:
		ten.append(_unit(CINDER, 0, c + Vector3(-1.2 * float(i % 2), 0, -6.0 + 1.35 * float(i)), 90.0, FIRE))
	var six: Array[Node3D] = []
	for i in 6:
		six.append(_unit(SHADE, 1, c + Vector3(9.0 + 1.0 * float(i % 2), 0, -4.0 + 1.6 * float(i)), -90.0, SHADOW))
	_frame(c + Vector3(4.0, 0, 0), 40.0)
	_label.text = "game camera 40 m: 10 Cinderlocks volley (0.2 s)"
	await _frames(20)
	await _fire(ten, six[2])
	var mid := _centre(ten)
	_vfx.call(&"play", &"powder_volley", mid, six[2])
	_vfx.call(&"play", &"powder_smoke", mid, {"radius": 4.0, "team": 0})
	await _frames(9)
	for i in six.size():
		_vfx.call(&"play", &"musket_impact", six[i], six[i])
	await _frames(3)
	await _shoot("game40")
	_label.text = "game camera 40 m: the cloud at 1.5 s"
	await _frames(78)
	await _shoot("game40_smoke")
	await _frames(120)
	_clear()
	# 6. Stress: 20 guns (2 volleys) + 6 clouds per team, 30 m.
	c = Vector3(0, 0, 140)
	var guns: Array[Node3D] = []
	for i in 20:
		guns.append(_unit(CINDER, 0, c + Vector3(-1.2 * float(i % 2), 0, -12.0 + 1.25 * float(i)), 90.0, FIRE))
	var foes2: Array[Node3D] = []
	for i in 10:
		foes2.append(_unit(SHADE, 1, c + Vector3(9.0, 0, -9.0 + 2.0 * float(i)), -90.0, SHADOW))
	_frame(c + Vector3(3.0, 0, 0), 34.0)
	_label.text = "stress: 20 guns, 2 volleys, 6 clouds per team"
	await _frames(20)
	await _fire(guns, foes2[4])
	_vfx.call(&"play", &"powder_volley", _centre(guns.slice(0, 10)), foes2[2])
	_vfx.call(&"play", &"powder_volley", _centre(guns.slice(10, 20)), foes2[7])
	for i in 6:
		_vfx.call(&"play", &"powder_smoke", c + Vector3(-0.6, 0, -10.0 + 4.0 * float(i)), {"radius": 3.4, "team": 0})
		_vfx.call(&"play", &"powder_smoke", c + Vector3(9.0, 0, -10.0 + 4.0 * float(i)), {"radius": 3.0, "team": 1})
	await _frames(9)
	for f in foes2:
		_vfx.call(&"play", &"musket_impact", f, f)
	var fam: Node = (_vfx.call(&"families") as Array)[0]
	var a := Time.get_ticks_usec()
	fam.call(&"_process", 0.0)
	print("stress: family _process (fresh) %d us, running %d" % [Time.get_ticks_usec() - a, fam.call(&"active_count")])
	await _frames(4)
	await _shoot("stress")
	# Steady-state cost with 12 clouds + wisps alive (no new effects).
	await _frames(30)
	var t0 := Time.get_ticks_usec()
	for i in 60:
		await process_frame
	print("stress steady: fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " clouds=",
			fam.call(&"smoke_cloud_count"), " wall 60 frames=", (Time.get_ticks_usec() - t0) / 1000, " ms")
	a = Time.get_ticks_usec()
	fam.call(&"_process", 0.0)
	print("stress steady: family _process %d us" % (Time.get_ticks_usec() - a))
	_sheet.save_png(ProjectSettings.globalize_path(OUT % "sheet"))
	print("saved sheet")
	await _frames(240)
	print("after 4 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
	quit()
