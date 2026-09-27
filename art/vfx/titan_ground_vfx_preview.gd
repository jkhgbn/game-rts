extends SceneTree
## Screenshots of the non-dragon titan effects (task 13.V19) with the real titan models, auto-attached by TitanVfx's
## family node exactly as in the game: frost aura, trample, howdah bolt, root morph / root bed, grove pulse, thorn
## volley, sapling sprout, knight knockback, and everything at the 40 m game camera.
## Writes docs/art/screens/13_v19_<name>.png and the contact sheet 13_v19_sheet.png. Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/titan_ground_vfx_preview.gd --fixed-fps 60 --quit-after 9000
## Add `-- --only=<name>` for one shot. Then a stress run prints the family's _process cost and the draw calls.

const OUT := "res://docs/art/screens/13_v19_"
const CELL := Vector2i(640, 360)
const COLS := 4
const SPACING := 90.0
const MAMMOTH := "res://art/units/titans/war_mammoth/war_mammoth.tscn"
const TREANT := "res://art/units/titans/elder_treant/elder_treant.tscn"
const KNIGHT := "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"
const GUARD := "res://art/units/fire/flame_guard.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar alive: bool = true\nvar model: Node3D\nvar body_height: float = 1.9\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn model\n"
const ICE_TINT := Color(0.45, 0.75, 0.95)
const NATURE_TINT := Color(0.35, 0.70, 0.25)
const SHADOW_TINT := Color(0.42, 0.22, 0.60)
## [name, action, time after the event (s), zoom, pitch, yaw, label]
const SHOTS := [
	[&"aura", &"aura", 1.2, 15.0, 50.0, 20.0, "frost_aura: r 5 rime ring, crystal teeth, mist (War Mammoth)"],
	[&"trample", &"trample", 0.1, 10.0, 40.0, 30.0, "trample: stomp crack, frost shock ring r 1.6, snow dust, ice shards"],
	[&"trample_after", &"trample", 0.9, 10.0, 55.0, 30.0, "trample after 0.9 s: cracks, snowy lip, drifting dust"],
	[&"howdah_bolt", &"bolt", 0.16, 13.0, 22.0, 0.0, "howdah_bolt in flight: ice crystal + light trail + glints"],
	[&"bolt_hit", &"bolt", 0.5, 8.0, 40.0, 30.0, "howdah_bolt hit: ice burst, shards, frost splat"],
	[&"root_morph", &"morph", 1.3, 15.0, 35.0, 25.0, "root_morph (1.3 s of 3): soil dust, clods, leaves, roots spreading"],
	[&"root_bed", &"morph", 5.4, 13.0, 55.0, 25.0, "rooted: the torn-soil root bed stays (r 3.4, sap lines)"],
	[&"grove_pulse", &"pulse", 0.55, 22.0, 55.0, 0.0, "grove_pulse (r 8, every 4 s): leaf band, root veins, motes"],
	[&"thorn_volley", &"volley", 0.22, 16.0, 22.0, 0.0, "thorn_volley in flight: 6 bark thorns, green trails"],
	[&"thorn_hit", &"volley", 0.55, 10.0, 45.0, 70.0, "thorn_volley landed: splinters, sap, thorns stuck"],
	[&"sapling_sprout", &"sprout", 0.18, 7.0, 40.0, 0.0, "sapling_sprout: soil burst, leaf swirl, green ring"],
	[&"knockback", &"knock", 0.45, 11.0, 50.0, 20.0, "knight_knockback: skid furrows + dust (charge impact = CavalryVfx)"],
	[&"game40", &"all", 0.5, 40.0, 55.0, 0.0, "game camera 40 m: aura + trample, rooted treant volley + pulse"],
]

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript
var _movers: Array[Dictionary] = []    # {n, v, left}
var _units: Array[Node3D] = []


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
	_units.append(u)
	return u


func _titan(path: String, tint: Color, team: int, pos: Vector3, yaw_deg: float) -> Node3D:
	var u := _unit(team, pos, yaw_deg)
	var holder := Node3D.new()
	u.add_child(holder)
	var m := (load(path) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", tint)
	u.set(&"model", m)
	return u


func _guard(pos: Vector3, face: Vector3) -> Node3D:
	var u := _unit(1, pos, 0.0)
	var ps := load(GUARD) as PackedScene
	if ps:
		var g := ps.instantiate() as Node3D
		u.add_child(g)
		u.set(&"model", g)
	u.look_at(face, Vector3.UP, true)
	return u


func _model(u: Node3D) -> Node3D:
	return u.get(&"model") as Node3D


func _wait(sec: float) -> void:
	var t := 0.0
	while t < sec:
		await process_frame
		var dt := 1.0 / 60.0
		t += dt
		for m in _movers:
			var nv: Variant = m["n"]
			if is_instance_valid(nv) and float(m["left"]) > 0.0:
				(nv as Node3D).global_position += (m["v"] as Vector3) * dt
				m["left"] = float(m["left"]) - dt


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
		var action: StringName = spec[1]
		var after: float = spec[2]
		var c := _cell(i)
		_movers.clear()
		var fwd := Vector3(1.0, 0.0, 0.0)
		var focus := c
		_label.text = String(spec[6])
		match action:
			&"aura":
				_titan(MAMMOTH, ICE_TINT, 2, c, 90.0)
				for k in 4:
					_guard(c + Vector3(3.6 + float(k % 2) * 1.2, 0.0, -2.0 + float(k) * 1.3), c)
				_frame(c + Vector3(0, 1.0, 0), float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(after)
			&"trample":
				var mu := _titan(MAMMOTH, ICE_TINT, 2, c - fwd * 3.0, 90.0)
				_model(mu).call(&"set_moving", 3.4)
				_movers.append({"n": mu, "v": fwd * 3.4, "left": 99.0})
				await _wait(0.9)
				_model(mu).call(&"play_trample")
				await _wait(0.2 + after)
				_frame(mu.global_position + fwd * 1.2 + Vector3(0, 0.5, 0), float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(0.02)
			&"bolt":
				var mu2 := _titan(MAMMOTH, ICE_TINT, 2, c - fwd * 4.0, 90.0)
				var tg := _guard(c + fwd * 5.0 + Vector3(0, 0, 2.0), c - fwd * 4.0)
				await _wait(0.6)
				_model(mu2).call(&"play_howdah_shot", tg)
				_vfx.call(&"play", &"howdah_bolt", tg, mu2)
				if after < 0.3:
					_frame(c + Vector3(0, 2.5, 1.0), float(spec[3]), float(spec[4]), float(spec[5]))
				else:
					_frame(tg.global_position + Vector3(0, 0.6, 0), float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(0.12 + after)
			&"morph":
				var tu := _titan(TREANT, NATURE_TINT, 3, c, 30.0)
				_frame(c + Vector3(0, 1.4, 0), float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(0.4)
				_model(tu).call(&"set_rooted", true)
				await _wait(after)
			&"pulse":
				var tu2 := _titan(TREANT, NATURE_TINT, 3, c, 0.0)
				for k in 5:
					var a := float(k) * TAU / 5.0 + 0.4
					_guard(c + Vector3(cos(a), 0.0, sin(a)) * (3.0 + float(k % 2) * 2.5), c).set(&"team", 3)
				_frame(c, float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(0.4)
				_model(tu2).call(&"set_rooted", true, true)
				await _wait(after)
			&"volley":
				var tu3 := _titan(TREANT, NATURE_TINT, 3, c - fwd * 5.0, 90.0)
				_model(tu3).call(&"set_rooted", true, true)
				await _wait(2.3)
				var aim := c + fwd * 4.0
				for k in 3:
					_guard(aim + Vector3(float(k) * 0.9 - 0.9, 0.0, float(k % 2) * 1.2 - 0.6), c - fwd * 5.0)
				_model(tu3).call(&"play_volley")
				_vfx.call(&"play", &"thorn_volley", aim, tu3)
				if after < 0.3:
					_frame(c + Vector3(-1.5, 2.8, 0), float(spec[3]), float(spec[4]), float(spec[5]))
				else:
					_frame(aim + Vector3(0, 0.4, 0), float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(0.15 + after)
			&"sprout":
				_frame(c + Vector3(0, 0.5, 0), float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(0.3)
				_vfx.call(&"play", &"sapling_sprout", c, null)
				await _wait(after)
			&"knock":
				var ku := _titan(KNIGHT, SHADOW_TINT, 1, c - fwd * 3.2, 90.0)
				var vic := _guard(c, c - fwd * 3.2)
				await _wait(0.5)
				_model(ku).call(&"play_charge")
				await _wait(0.1)
				_vfx.call(&"play", &"knight_knockback", vic, ku)
				_movers.append({"n": vic, "v": fwd * (3.0 / 0.35), "left": 0.35})
				_frame(c + fwd * 1.5 + Vector3(0, 0.6, 0), float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(after)
			&"all":
				var mu4 := _titan(MAMMOTH, ICE_TINT, 2, c + Vector3(-9.0, 0.0, 4.0), 90.0)
				_model(mu4).call(&"set_moving", 3.4)
				_movers.append({"n": mu4, "v": fwd * 3.4, "left": 99.0})
				var tu4 := _titan(TREANT, NATURE_TINT, 3, c + Vector3(6.0, 0.0, -5.0), 225.0)
				_model(tu4).call(&"set_rooted", true, true)
				for k in 5:
					_guard(c + Vector3(-3.0 + float(k) * 1.1, 0.0, -1.0 + float(k % 2)), c + Vector3(6.0, 0.0, -5.0))
				_frame(focus, float(spec[3]), float(spec[4]), float(spec[5]))
				await _wait(3.7)
				_model(mu4).call(&"play_trample")
				_model(tu4).call(&"play_volley")
				_vfx.call(&"play", &"thorn_volley", c + Vector3(-1.0, 0.0, -0.5), tu4)
				_vfx.call(&"play", &"grove_pulse", null, tu4)
				await _wait(after)
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
		print("saved docs/art/screens/13_v19_sheet.png")
		await _stress()
	elif only == "stress":
		await _stress()
	quit()


## 6 mammoths (auras + tramples + bolts) and 4 rooted treants (volleys + pulses) at once: cost check.
func _stress() -> void:
	for old in _units:
		if is_instance_valid(old):
			old.queue_free()
	_units.clear()
	await _wait(2.5)
	var c := Vector3(150.0, 0.0, 330.0)
	var units: Array[Node3D] = []
	var fam: Node = _vfx.get_node_or_null(^"TitanGroundVfx")
	for i in 6:
		units.append(_titan(MAMMOTH, ICE_TINT, 2, c + Vector3(-15.0 + float(i) * 6.0, 0.0, -6.0), 90.0))
	for i in 4:
		var t := _titan(TREANT, NATURE_TINT, 3, c + Vector3(-12.0 + float(i) * 8.0, 0.0, 6.0), 180.0)
		_model(t).call(&"set_rooted", true, true)
		units.append(t)
	_frame(c, 34.0, 55.0, 0.0)
	_label.text = "stress: 6 mammoths (aura, trample, bolt) + 4 rooted treants (volley, pulse)"
	await _wait(0.5)
	for u in units:
		var m := _model(u)
		if m.has_method(&"play_trample"):
			m.call(&"play_trample")
			m.call(&"play_howdah_shot", c + Vector3(0, 0, 12))
		else:
			m.call(&"play_volley")
	await _wait(0.3)
	var per := {}
	for fx: Variant in fam.get(&"_fx"):
		var a0 := Time.get_ticks_usec()
		for k in 20:
			fam.call(&"_tick", fx, 0.0)
		per[fx.id] = float(per.get(fx.id, 0.0)) + float(Time.get_ticks_usec() - a0) / 20.0
	print("per kind us (sum): ", per)
	var a := Time.get_ticks_usec()
	for k in 20:
		fam.call(&"_process", 0.0)
	print("TitanGroundVfx _process (%d effects): %.0f us avg of 20" % [fam.call(&"active_count"),
			float(Time.get_ticks_usec() - a) / 20.0])
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path(OUT + "stress.png"))
	print("stress: running=", fam.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	for u in units:
		u.queue_free()
	await _wait(6.0)
	print("after 6 s: running=", fam.call(&"active_count"), " live=", fam.call(&"live_count"), " (expect 0 / 0)")
