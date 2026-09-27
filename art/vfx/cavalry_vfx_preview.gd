extends SceneTree
## Screenshots of the cavalry effects (task 13.V20) with the real riders and mounts (13.V1a-V6 mounts, 13.V1b seated
## riders, the 13.V15 Nightmare Knight): charge (+ close-up, the Knight's, one per kingdom), lifesteal (rider, Knight),
## mount at t = 0.03 s (the puff hides the rider's hop start inside the mount) and 0.16 s, dismount, thrown, speed
## lines (+ close-up) and the 40 m game camera. Writes docs/art/screens/13_v20_<name>.png and the contact sheet
## 13_v20_sheet.png. Windowed (needs a GPU):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s art/vfx/cavalry_vfx_preview.gd --fixed-fps 60 --quit-after 12000
## Add `-- --only=<name>` for one shot. Then a stress run prints the CavalryVfx _process cost and the draw calls.

const OUT := "res://docs/art/screens/13_v20_"
const CELL := Vector2i(640, 360)
const COLS := 4
const SPACING := 90.0
const MOUNTS := {&"fire": "res://art/units/mounts/ember_boar/ember_boar.tscn",
	&"shadow": "res://art/units/mounts/dusk_steed/dusk_steed.tscn",
	&"ice": "res://art/units/mounts/rimehorn/rimehorn.tscn",
	&"nature": "res://art/units/mounts/grove_stag/grove_stag.tscn"}
const RIDERS := {&"fire": "res://art/units/wizards/vessa.tscn", &"shadow": "res://art/units/wizards/malrik.tscn",
	&"ice": "res://art/units/wizards/torvald.tscn", &"nature": "res://art/units/wizards/ysolde.tscn"}
const TINTS := {&"fire": Color(0.85, 0.30, 0.12), &"shadow": Color(0.42, 0.22, 0.60), &"ice": Color(0.45, 0.75, 0.95),
	&"nature": Color(0.35, 0.70, 0.25)}
const KNIGHT := "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"
const GUARD := "res://art/units/fire/flame_guard.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar kingdom: StringName = &\"neutral\"\nvar titan: bool = false\nvar model: Node3D\nvar mount: Node3D\nfunc is_alive() -> bool:\n\treturn true\nfunc is_titan() -> bool:\n\treturn titan\nfunc get_model() -> Node3D:\n\treturn model\n"
## [name, action, kingdom, time after the event (s), zoom, pitch, yaw, label]
const SHOTS := [
	[&"charge", &"charge", &"shadow", 0.14, 12.0, 38.0, 0.0, "charge: 5 m streak into the rider, shock ring, sparks, dust (Shadow)"],
	[&"charge_close", &"charge", &"fire", 0.2, 8.0, 18.0, 30.0, "charge close-up (Fire, Vessa on the Ember Boar)"],
	[&"charge_knight", &"knight_charge", &"shadow", 0.16, 16.0, 38.0, 0.0, "charge, titan version (Nightmare Knight)"],
	[&"charge_kingdoms", &"kingdoms", &"", 0.16, 24.0, 50.0, 0.0, "charge per kingdom: fire, shadow, ice, nature"],
	[&"lifesteal", &"drain", &"shadow", 0.26, 9.0, 24.0, 20.0, "lifesteal: soul wisps from the victim into the rider"],
	[&"lifesteal_knight", &"knight_drain", &"shadow", 0.3, 12.0, 26.0, 20.0, "lifesteal, Nightmare Knight (4 wisps)"],
	[&"mount_t0", &"mount", &"fire", 0.03, 8.5, 22.0, 25.0, "mount at 0.03 s: the puff hides the hop start inside the boar"],
	[&"mount_hop", &"mount", &"fire", 0.16, 8.5, 22.0, 25.0, "mount at 0.16 s: rider over the left flank, glints"],
	[&"dismount", &"dismount", &"nature", 0.33, 8.5, 22.0, 25.0, "dismount at 0.33 s: the stag leaves in the puff"],
	[&"thrown", &"thrown", &"ice", 0.5, 9.0, 24.0, 20.0, "thrown at 0.5 s: jolt puff, skid dust, clods, the mount leaves"],
	[&"speed_lines", &"gallop", &"fire", 1.2, 12.0, 35.0, 20.0, "rider speed lines + hoof dust (7 m/s)"],
	[&"speed_lines_close", &"gallop", &"shadow", 1.2, 7.0, 16.0, 35.0, "speed lines close-up (Malrik on the Dusk Steed)"],
	[&"game40", &"game", &"", 0.16, 40.0, 55.0, 0.0, "game camera 40 m: 4 riders galloping, 2 charges, a drain, a mount"],
]

var _world: Node3D
var _cam: Camera3D
var _label: Label
var _vfx: Node3D
var _stub: GDScript
var _movers: Array[Dictionary] = []    # {n, v}
var _made: Array[Node3D] = []          # units of the current shot (freed after it)


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
	_vfx = (load("res://art/vfx/cavalry_vfx.gd") as GDScript).new()
	_vfx.name = "CavalryVfx"
	_world.add_child(_vfx)
	_run.call_deferred()


func _cell(i: int) -> Vector3:
	return Vector3(float(i % COLS) * SPACING, 0.0, float(i / COLS) * SPACING)


func _frame(focus: Vector3, zoom: float, pitch_deg: float, yaw_deg: float) -> void:
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	_cam.position = focus + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * zoom
	_cam.rotation = Vector3(-p, y, 0.0)


func _unit(team: int, kingdom: StringName, pos: Vector3, yaw_deg: float) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.set(&"team", team)
	u.set(&"kingdom", kingdom)
	_world.add_child(u)
	u.global_position = pos
	u.rotation.y = deg_to_rad(yaw_deg)
	_made.append(u)
	return u


## A wizard riding her kingdom's mount (rider and mount siblings under a visual holder, as Unit does).
func _rider(kingdom: StringName, pos: Vector3, yaw_deg: float, seated := true) -> Node3D:
	var u := _unit(0, kingdom, pos, yaw_deg)
	var holder := Node3D.new()
	u.add_child(holder)
	var r := (load(RIDERS[kingdom]) as PackedScene).instantiate() as Node3D
	var m := (load(MOUNTS[kingdom]) as PackedScene).instantiate() as Node3D
	m.set(&"fidget_every", 0.0)
	holder.add_child(r)
	holder.add_child(m)
	r.call(&"set_team_color", TINTS[kingdom])
	m.call(&"set_team_color", TINTS[kingdom])
	if seated:
		r.call(&"set_seated", true, m)
	u.set(&"model", r)
	u.set(&"mount", m)
	return u


func _knight(pos: Vector3, yaw_deg: float) -> Node3D:
	var u := _unit(0, &"shadow", pos, yaw_deg)
	u.set(&"titan", true)
	var holder := Node3D.new()
	u.add_child(holder)
	var m := (load(KNIGHT) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	m.call(&"set_team_color", TINTS[&"shadow"])
	u.set(&"model", m)
	u.set(&"mount", m)
	return u


func _guard(pos: Vector3, face: Vector3) -> Node3D:
	var u := _unit(1, &"fire", pos, 0.0)
	var ps := load(GUARD) as PackedScene
	if ps:
		var g := ps.instantiate() as Node3D
		u.add_child(g)
	u.look_at(face, Vector3.UP, true)
	return u


func _moving(u: Node3D, speed: float) -> void:
	for key: StringName in [&"mount", &"model"]:
		var n: Variant = u.get(key)
		if n is Node3D and (n as Node3D).has_method(&"set_moving"):
			(n as Node3D).call(&"set_moving", speed)


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
		var action: StringName = spec[1]
		var k: StringName = spec[2]
		var after: float = spec[3]
		var c := _cell(i)
		_movers.clear()
		var fwd := Vector3(1.0, 0.0, 0.0)     # riders face +X (side view from the RTS camera)
		var focus := c
		_label.text = String(spec[7])
		match action:
			&"charge", &"knight_charge":
				var u := _knight(c - fwd * 5.6, 90.0) if action == &"knight_charge" else _rider(k, c - fwd * 5.6, 90.0)
				var g := _guard(c + fwd * (2.2 if action == &"knight_charge" else 1.6), c - fwd * 5.0)
				_frame(c + Vector3(-1.0, 1.2, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				_moving(u, 8.0)
				_movers.append({"n": u, "v": fwd * 8.0})
				await _wait(0.7)
				_movers.clear()
				(u.get(&"mount") as Node3D).call(&"play_charge")
				_vfx.call(&"play", &"charge", g, u)
				await _wait(after)
			&"kingdoms":
				var ks: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
				var us: Array[Node3D] = []
				var gs: Array[Node3D] = []
				for j in 4:
					var row := c + Vector3(0.0, 0.0, -7.5 + 5.0 * float(j))
					us.append(_rider(ks[j], row - fwd * 5.6, 90.0))
					gs.append(_guard(row + fwd * 1.6, row - fwd * 5.0))
				_frame(c + Vector3(-1.0, 0.5, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				for u in us:
					_moving(u, 8.0)
					_movers.append({"n": u, "v": fwd * 8.0})
				await _wait(0.7)
				_movers.clear()
				for j in 4:
					(us[j].get(&"mount") as Node3D).call(&"play_charge")
					_vfx.call(&"play", &"charge", gs[j], us[j])
				await _wait(after)
			&"drain", &"knight_drain":
				var u := _knight(c, 90.0) if action == &"knight_drain" else _rider(k, c, 90.0)
				var g := _guard(c + fwd * (2.6 if action == &"knight_drain" else 1.9), c)
				focus = c + fwd * 1.0
				_frame(focus + Vector3(0.0, 1.4, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(0.4)
				(u.get(&"model") as Node3D).call(&"play_attack")
				await _wait(0.12)
				_vfx.call(&"play", &"lifesteal", g, u)
				await _wait(after)
			&"mount":
				var u := _rider(k, c, 90.0, false)
				_frame(c + Vector3(0.0, 1.0, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(0.4)
				(u.get(&"model") as Node3D).call(&"set_seated", true, u.get(&"mount"))
				(u.get(&"model") as Node3D).call(&"play_mount")
				_vfx.call(&"play", &"mount", u, u)
				await _wait(after)
			&"dismount":
				var u := _rider(k, c, 90.0)
				_frame(c + Vector3(0.0, 1.0, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(0.4)
				(u.get(&"model") as Node3D).call(&"play_dismount")
				_vfx.call(&"play", &"dismount", u, u)
				await _wait(0.3)
				(u.get(&"mount") as Node3D).visible = false   # gameplay removes the mount at the end of the hop
				await _wait(after - 0.3)
			&"thrown":
				var u := _rider(k, c, 90.0)
				_frame(c + Vector3(0.0, 1.0, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(0.4)
				(u.get(&"model") as Node3D).call(&"play_thrown")
				_vfx.call(&"play", &"thrown", u, u)
				await _wait(0.48)
				(u.get(&"mount") as Node3D).visible = false   # gameplay removes the mount when the rider is unseated
				await _wait(after - 0.48)
			&"gallop":
				var u := _rider(k, c - fwd * 8.4, 90.0)
				_moving(u, 7.0)
				_movers.append({"n": u, "v": fwd * 7.0})
				_vfx.call(&"play", &"speed_lines", null, u)
				_frame(c + Vector3(0.0, 1.2, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(after)
				_frame(u.global_position + Vector3(-0.8, 1.2, 0.0), float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(0.03)
			&"game":
				var ks: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
				for j in 4:
					var u := _rider(ks[j], c + Vector3(-14.0, 0.0, -9.0 + 3.2 * float(j)), 90.0)
					_moving(u, 7.0)
					_movers.append({"n": u, "v": fwd * 7.0})
					_vfx.call(&"play", &"speed_lines", null, u)
				var c1 := _rider(&"fire", c + Vector3(-5.6, 0.0, 5.0), 90.0)
				var g1 := _guard(c + Vector3(1.6, 0.0, 5.0), c + Vector3(-5.0, 0.0, 5.0))
				var kn := _knight(c + Vector3(-5.6, 0.0, 10.0), 90.0)
				var g2 := _guard(c + Vector3(2.2, 0.0, 10.0), c + Vector3(-5.0, 0.0, 10.0))
				var dr := _rider(&"shadow", c + Vector3(8.0, 0.0, -2.0), 90.0)
				var g3 := _guard(c + Vector3(9.9, 0.0, -2.0), c + Vector3(8.0, 0.0, -2.0))
				var mt := _rider(&"nature", c + Vector3(10.0, 0.0, 6.0), 90.0, false)
				for u: Node3D in [c1, kn]:
					_moving(u, 8.0)
					_movers.append({"n": u, "v": fwd * 8.0})
				_frame(c, float(spec[4]), float(spec[5]), float(spec[6]))
				await _wait(0.7)
				_movers.resize(4)
				for pair: Array in [[c1, g1], [kn, g2]]:
					((pair[0] as Node3D).get(&"mount") as Node3D).call(&"play_charge")
					_vfx.call(&"play", &"charge", pair[1], pair[0])
				(dr.get(&"model") as Node3D).call(&"play_attack")
				_vfx.call(&"play", &"lifesteal", g3, dr)
				(mt.get(&"model") as Node3D).call(&"set_seated", true, mt.get(&"mount"))
				(mt.get(&"model") as Node3D).call(&"play_mount")
				_vfx.call(&"play", &"mount", mt, mt)
				await _wait(after)
		var img := await _grab()
		img.save_png(ProjectSettings.globalize_path(OUT + String(shot) + ".png"))
		img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y))
		print("shot ", shot, " fps=", Engine.get_frames_per_second(), " draw_calls=",
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " running=",
				_vfx.call(&"active_ids"))
		_movers.clear()
		for u in _made:
			if is_instance_valid(u):
				u.queue_free()
		_made.clear()
	if only == "":
		sheet.save_png(ProjectSettings.globalize_path(OUT + "sheet.png"))
		print("saved docs/art/screens/13_v20_sheet.png")
		await _stress()
	elif only == "stress":
		await _stress()
	quit()


## 8 riders with speed lines, 8 charges, 12 drains, 6 puffs at once (cost check), then everything must end.
func _stress() -> void:
	var c := Vector3(150.0, 0.0, 400.0)
	var fwd := Vector3(1.0, 0.0, 0.0)
	var ks: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
	var all: Array[Node3D] = []
	for j in 8:
		var u := _rider(ks[j % 4], c + Vector3(-20.0, 0.0, -12.0 + 3.0 * float(j)), 90.0)
		_moving(u, 7.0)
		_movers.append({"n": u, "v": fwd * 7.0})
		_vfx.call(&"play", &"speed_lines", null, u)
		all.append(u)
	_frame(c, 32.0, 55.0, 0.0)
	_label.text = "stress: 8 riders with speed lines + 8 charges + 12 drains + 6 puffs (zoom 32)"
	await _wait(0.6)
	for j in 8:
		var s := _unit(0, ks[j % 4], c + Vector3(-4.0 + float(j) * 2.0, 0.0, 6.0), 90.0)
		all.append(s)
		_vfx.call(&"play", &"charge", s.global_position + fwd * 1.6, s)
	for j in 12:
		var s := _unit(0, &"shadow", c + Vector3(-10.0 + float(j) * 1.8, 0.0, 10.0), 90.0)
		all.append(s)
		_vfx.call(&"play", &"lifesteal", s.global_position + fwd * 1.8, s)
	for j in 6:
		var s := _unit(0, ks[j % 4], c + Vector3(-8.0 + float(j) * 3.0, 0.0, 14.0), 90.0)
		all.append(s)
		_vfx.call(&"play", [&"mount", &"dismount", &"thrown"][j % 3], s, s)
	await _wait(0.2)
	var fxs: Array = _vfx.get(&"_fx")
	var per := {}
	for fx in fxs:
		var a0 := Time.get_ticks_usec()
		for n in 20:
			_vfx.call(&"_tick", fx, 0.0)
		per[fx.id] = float(per.get(fx.id, 0.0)) + float(Time.get_ticks_usec() - a0) / 20.0
	var a1 := Time.get_ticks_usec()
	for n in 20:
		_vfx.call(&"_tick_riders", 0.0)
	print("per kind us: ", per, " riders: ", float(Time.get_ticks_usec() - a1) / 20.0)
	var a := Time.get_ticks_usec()
	for n in 20:
		_vfx.call(&"_process", 0.0)
	print("CavalryVfx _process (%d effects, %d riders): %.0f us avg of 20" % [_vfx.call(&"active_count"),
			_vfx.call(&"rider_count"), float(Time.get_ticks_usec() - a) / 20.0])
	var img := await _grab()
	img.save_png(ProjectSettings.globalize_path(OUT + "stress.png"))
	print("stress: running=", _vfx.call(&"active_count"), " fps=", Engine.get_frames_per_second(), " draw_calls=",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_movers.clear()
	for u in all:
		u.queue_free()
	await _wait(4.0)
	print("after 4 s: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " riders=",
			_vfx.call(&"rider_count"), " (expect 0 / 0 / 0)")
