extends SceneTree
## Contact sheet of the 12 champion class-skill effects + the 4 class_chosen rings (task 11.V6) ->
## docs/art/screens/champion_class_vfx.png (4 x 4 cells, RTS camera: pitch 55, fov 50) + one full-size shot per cell
## under docs/art/screens/champion_class_vfx_<id>.png with `--all`. Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/champion_class_vfx_preview.gd --fixed-fps 60 --quit-after 4000
## Bodies: the champion models (art/units/champions/<id>/<id>.tscn, `set_weapon_class` when they have it), else
## kingdom stand-ins. The gameplay's moves (Lunge dash, Slipstep jump) and hit signals (Riposte counters, Whirlwind
## ticks) are faked here. Prints fps / draw calls and the ChampionVfx _process cost for a stress shot.

const CELL := Vector2i(640, 360)
const COLS := 4
const SPACING := 60.0
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nvar cls: StringName = &\"\"\nvar abilities: Node = null\nfunc is_alive() -> bool:\n\treturn alive\nfunc class_id() -> StringName:\n\treturn cls\n"
const ABILITIES_SRC := "extends Node\nsignal skill_hit(id: StringName, target: Node3D, amount: float)\n"
const STAND_INS := {&"wayfinder": "fire/ember_archer", &"oathwall": "ice/rimeshield", &"coin_cutter": "shadow/shade",
		&"mender": "nature/bloomtender"}
const HEIGHTS := {&"wayfinder": 1.8, &"oathwall": 2.0, &"coin_cutter": 1.7, &"mender": 1.7}
## [id, champion, class, shot time (s), zoom, label]
const SHOTS := [
	[&"lunge", &"wayfinder", &"spear", 0.12, 14.0, "lunge: dash streak, impact, daze"],
	[&"hobbling_javelin", &"coin_cutter", &"spear", 1.0, 15.0, "hobbling_javelin: javelin + hobble dust"],
	[&"skewer", &"wayfinder", &"spear", 0.1, 14.0, "skewer: thrust flash through a 5 m line"],
	[&"riposte", &"oathwall", &"sword_shield", 0.75, 11.0, "riposte: brass shimmer + counter sparks"],
	[&"second_wind", &"mender", &"sword_shield", 1.2, 11.0, "second_wind: wind ring, rising wisps"],
	[&"shield_throw", &"oathwall", &"sword_shield", 0.42, 16.0, "shield_throw: spinning shield, bounces"],
	[&"cleave", &"coin_cutter", &"two_hand", 0.1, 13.0, "cleave: blade crescent r 2.5"],
	[&"crushing_blow", &"oathwall", &"two_hand", 0.22, 11.0, "crushing_blow: cracks, shards, armor badge"],
	[&"whirlwind", &"coin_cutter", &"two_hand", 0.7, 15.0, "whirlwind: blade band r 3"],
	[&"arc_bolt", &"mender", &"wizard", 0.42, 16.0, "arc_bolt: crackling bolt + hit"],
	[&"slipstep", &"wayfinder", &"wizard", 0.15, 15.0, "slipstep: fade, streak, reappear"],
	[&"starfall", &"mender", &"wizard", 0.82, 19.0, "starfall: warning ring + falling star"],
	[&"class_chosen", &"wayfinder", &"spear", 0.3, 9.0, "class_chosen: spear"],
	[&"class_chosen", &"oathwall", &"sword_shield", 0.3, 9.0, "class_chosen: sword and shield"],
	[&"class_chosen", &"coin_cutter", &"two_hand", 0.3, 9.0, "class_chosen: two-hand sword"],
	[&"class_chosen", &"mender", &"wizard", 0.3, 9.0, "class_chosen: wizard"],
]

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript
var _abil_script: GDScript
var _all := false


func _initialize() -> void:
	_all = "--all" in OS.get_cmdline_user_args()
	_stub = _script(STUB_SRC)
	_abil_script = _script(ABILITIES_SRC)
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
	ground.position = Vector3(90, 0, 90)
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


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _cell(i: int) -> Vector3:
	return Vector3(float(i % COLS) * SPACING, 0.0, float(i / COLS) * SPACING)


func _body(team: int, pos: Vector3, champion: StringName, face: Vector3, cls: StringName = &"") -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	var path := ""
	if champion != &"":
		path = "res://art/units/champions/%s/%s.tscn" % [champion, champion]
		if not ResourceLoader.exists(path):
			path = "res://art/units/%s.tscn" % STAND_INS[champion]
		u.set(&"body_height", HEIGHTS[champion])
		u.set(&"cls", cls)
		var ab := Node.new()
		ab.set_script(_abil_script)
		ab.name = "ChampionAbilities"
		u.add_child(ab)
		u.set(&"abilities", ab)
	else:
		path = "res://art/units/%s.tscn" % ("shadow/gloom_thrall" if team == 1 else "fire/flame_guard")
	var model: Node3D = (load(path) as PackedScene).instantiate()
	u.add_child(model)
	_world.add_child(u)
	u.global_position = pos
	u.add_to_group(&"units")
	if cls != &"" and model.has_method(&"set_weapon_class"):
		model.call(&"set_weapon_class", cls)
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


func _hit(caster: Node3D, id: StringName, target: Node3D) -> void:
	var ab: Node = caster.get(&"abilities")
	if ab:
		ab.emit_signal(&"skill_hit", id, target, 10.0)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var rows := (SHOTS.size() + COLS - 1) / COLS
	var sheet := Image.create_empty(CELL.x * COLS, CELL.y * rows, false, Image.FORMAT_RGBA8)
	await _wait(0.5)
	for i in SHOTS.size():
		var spec: Array = SHOTS[i]
		var id: StringName = spec[0]
		var champ: StringName = spec[1]
		var cls: StringName = spec[2]
		var c := _cell(i)
		var caster_pos := c + Vector3(-3.0, 0.0, 1.2)
		var target_pos := c + Vector3(2.4, 0.0, -0.6)
		var focus := c
		var extra: Array[Vector3] = []
		match id:
			&"lunge":
				caster_pos = c + Vector3(-3.5, 0.0, 1.5)
				target_pos = c + Vector3(2.0, 0.0, -0.5)
			&"hobbling_javelin":
				caster_pos = c + Vector3(-5.0, 0.0, 2.0)
				target_pos = c + Vector3(3.0, 0.0, -1.0)
			&"skewer":
				caster_pos = c + Vector3(-3.0, 0.0, 1.0)
				target_pos = c + Vector3(-0.8, 0.0, 0.25)
				extra = [c + Vector3(0.9, 0.0, -0.4), c + Vector3(2.3, 0.0, -0.7), c + Vector3(1.2, 0.0, 1.6)]
			&"riposte", &"second_wind", &"whirlwind", &"class_chosen":
				caster_pos = c
				if id == &"riposte":
					extra = [c + Vector3(1.4, 0.0, -0.6), c + Vector3(-1.2, 0.0, -1.0)]
				elif id == &"whirlwind":
					extra = [c + Vector3(2.0, 0.0, -0.8), c + Vector3(-1.8, 0.0, -1.4), c + Vector3(0.4, 0.0, 2.3),
							c + Vector3(-2.2, 0.0, 1.2)]
			&"shield_throw":
				caster_pos = c + Vector3(-5.0, 0.0, 2.0)
				target_pos = c + Vector3(1.0, 0.0, -0.5)
				extra = [c + Vector3(3.5, 0.0, 1.0), c + Vector3(4.2, 0.0, -2.6)]
				focus = c + Vector3(0.0, 0.0, 0.0)
			&"cleave", &"crushing_blow":
				caster_pos = c + Vector3(-1.4, 0.0, 0.8)
				target_pos = c + Vector3(0.8, 0.0, -0.4)
				if id == &"cleave":
					extra = [c + Vector3(2.4, 0.0, 0.8), c + Vector3(1.4, 0.0, -2.2), c + Vector3(3.0, 0.0, -1.2)]
			&"arc_bolt":
				caster_pos = c + Vector3(-5.0, 0.0, 2.0)
				target_pos = c + Vector3(4.0, 0.0, -1.5)
			&"slipstep":
				caster_pos = c + Vector3(-3.0, 0.0, 1.0)
				target_pos = c + Vector3(4.0, 0.0, -1.5)
				extra = [c + Vector3(-4.2, 0.0, 1.6)]
			&"starfall":
				caster_pos = c + Vector3(-7.0, 0.0, 4.0)
				target_pos = c + Vector3(1.0, 0.0, -1.0)
				extra = [c + Vector3(2.0, 0.0, -0.2), c + Vector3(-0.4, 0.0, -2.0), c + Vector3(0.2, 0.0, 0.6),
						c + Vector3(2.4, 0.0, -2.3)]
				focus = c + Vector3(-1.5, 0.0, 0.8)
		var caster := _body(0, caster_pos, champ, target_pos, cls)
		var target: Node3D = null
		var point_target := id == &"slipstep" or id == &"starfall"
		if not point_target and not (id in [&"riposte", &"second_wind", &"whirlwind", &"class_chosen"]):
			target = _body(1, target_pos, &"", caster_pos)
		var others: Array[Node3D] = []
		for p in extra:
			others.append(_body(1, p, &"", caster_pos))
		_frame(focus, float(spec[4]))
		_label.text = String(spec[5])
		await _wait(0.4)
		var shot_at: float = spec[3]
		# What the gameplay does around the cast, as timed events.
		var events: Array = []
		match id:
			&"hobbling_javelin", &"arc_bolt":
				events.append([shot_at - (0.16 if id == &"hobbling_javelin" else 0.14), func() -> void:
					_vfx.call(&"play", id, caster, target)])   # a second one in flight for the shot
			&"riposte":
				for k in others.size():
					events.append([shot_at - 0.08 - 0.12 * float(k), func() -> void: _hit(caster, id, others[k])])
			&"whirlwind":
				for k in others.size():
					events.append([shot_at - 0.1, func() -> void: _hit(caster, id, others[k])])
		var t_arg: Variant = caster
		match id:
			&"slipstep", &"starfall":
				t_arg = target_pos
			&"riposte", &"second_wind", &"whirlwind", &"class_chosen":
				t_arg = caster
			_:
				t_arg = target
		var first_at := 0.0 if id != &"arc_bolt" else 0.0
		_vfx.call(&"play", id, caster, t_arg)
		# The gameplay's instant moves right after the cast.
		if id == &"lunge":
			var back := (caster_pos - target_pos).normalized()
			caster.global_position = target_pos + back * 1.0
		elif id == &"slipstep":
			caster.global_position = target_pos
		var t := first_at
		while t < shot_at:
			await process_frame
			t += 1.0 / 60.0
			for e: Array in events:
				if e.size() == 2 and t >= float(e[0]):
					(e[1] as Callable).call()
					e.append(true)
		var img := await _grab()
		if _all:
			var tag := String(id) if id != &"class_chosen" else "class_chosen_%s" % cls
			img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/champion_class_vfx_%s.png" % tag))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot ", id, " fps=", Engine.get_frames_per_second(), " draw_calls=",
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/screens/champion_class_vfx.png"))
	print("saved docs/art/screens/champion_class_vfx.png")
	await _stress()
	quit()


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


## 6 champions casting every class effect within 2 s over 60 units (cost check), then everything must end.
func _stress() -> void:
	var c := Vector3(60.0, 0.0, 300.0)
	var units: Array[Node3D] = []
	for i in 60:
		units.append(_body(i % 2, c + Vector3(-14.0 + float(i % 10) * 3.0, 0.0, -8.0 + float(i / 10) * 3.0), &"", c))
	var casters: Array[Node3D] = []
	var classes: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
	for i in 6:
		casters.append(_body(i % 2, c + Vector3(-10.0 + float(i) * 4.0, 0.0, 6.0), [&"wayfinder", &"oathwall",
				&"coin_cutter", &"mender"][i % 4], c, classes[i % 4]))
	_frame(c, 40.0)
	_label.text = "stress: 6 casters x 13 class effects over 60 units (zoom 40)"
	await _wait(0.5)
	var ids: Array[StringName] = []
	for s: Array in SHOTS.slice(0, 13):
		ids.append(s[0])
	for k in 13:
		for ci in 6:
			var id: StringName = ids[(k + ci) % 13]
			var tgt: Variant = units[(k * 7 + ci * 11) % units.size()]
			if id in [&"riposte", &"second_wind", &"whirlwind", &"class_chosen"]:
				tgt = casters[ci]
			elif id == &"slipstep" or id == &"starfall":
				tgt = (tgt as Node3D).global_position
			_vfx.call(&"play", id, casters[ci], tgt)
		await _wait(0.15)
	await _wait(0.3)
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/champion_class_vfx_stress.png"))
	print("stress: running=", _vfx.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	await _time_process("fresh casts")
	await _wait(8.0)
	print("after 8 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " (expect 0 / 0)")
