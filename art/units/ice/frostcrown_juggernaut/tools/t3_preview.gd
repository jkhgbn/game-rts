extends SceneTree
## Preview + measure tool for the Stables T3 / extra unit models (frostcrown_juggernaut, rime_harrier, snowdrift_rider,
## bramble_harrier, spirit_wolf, thornback_charger). Windowed, through the Godot gate:
##   tools\godot_run.ps1 --path . -s res://art/units/ice/frostcrown_juggernaut/tools/t3_preview.gd --quit-after 20000 --
##     --scene=res://art/units/ice/frostcrown_juggernaut/frostcrown_juggernaut.tscn --out=C:/tmp/x --tag=fj
##     [--refs=res://a.tscn,res://b.tscn] [--only=views,attack,move,death,rts] [--color=r,g,b]
## Writes <out>/<tag>_<sheet>.png sheets and prints "T3P verts N draws N" (visible meshes at rest, every surface counted)
## and the per-node vertex list. Read-only on the project (writes only to --out).

var args := {}
var world: Node3D
var cam: Camera3D
var holder: Node3D
var model: Node3D
var out_dir := ""
var tag := "t3"
const ORIGIN := Vector3(30.0, 0.0, 30.0)


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	out_dir = String(args.get("out", OS.get_user_data_dir()))
	tag = String(args.get("tag", "t3"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = load("res://art/environment/world_env.tres")
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(300, 300)
	ground.mesh = pm
	ground.material_override = load("res://art/environment/ground_material.tres")
	world.add_child(ground)
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.far = 500.0
	world.add_child(cam)
	cam.make_current()
	holder = Node3D.new()
	holder.position = ORIGIN
	world.add_child(holder)
	model = (load(String(args["scene"])) as PackedScene).instantiate()
	holder.add_child(model)
	if args.has("color"):
		var p := String(args["color"]).split(",")
		model.call(&"set_team_color", Color(float(p[0]), float(p[1]), float(p[2])))
	_freeze_fidgets(model)
	await _wait(1.0)
	_measure()
	var only := String(args.get("only", "views,rts,attack,move,death"))
	if "views" in only:
		await _views()
	if "rts" in only:
		await _rts()
	if "attack" in only:
		await _attack()
	if "move" in only:
		await _move_sheet()
	if "death" in only:
		await _death()
	print("T3P DONE")
	quit(0)


func _freeze_fidgets(n: Node) -> void:
	if n.get(&"fidget_every") != null:
		n.set(&"fidget_every", 0.0)
	for c in n.get_children():
		_freeze_fidgets(c)


func _wait(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(sec * 1000.0):
		await process_frame


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _look(from: Vector3, at: Vector3) -> void:
	cam.look_at_from_position(from, at)


## Orbit view: yaw (deg, 0 = in front of the model's face), pitch (deg), distance, focus height.
func _orbit(yaw: float, pitch: float, dist: float, fy: float) -> void:
	var y := deg_to_rad(yaw)
	var p := deg_to_rad(pitch)
	var at := ORIGIN + Vector3(0, fy, 0)
	_look(at + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * dist, at)


func _sheet(imgs: Array[Image], cols: int, nm: String, w: int, h: int) -> void:
	var rows := int(ceil(float(imgs.size()) / float(cols)))
	var sheet := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	for i: int in imgs.size():
		var im := imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		var cw: int = mini(im.get_width(), int(im.get_height() * float(w) / float(h)))
		var ch: int = int(cw * float(h) / float(w))
		var src := im.get_region(Rect2i((im.get_width() - cw) / 2, (im.get_height() - ch) / 2, cw, ch))
		src.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(src, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	var p := out_dir.path_join("%s_%s.png" % [tag, nm])
	sheet.save_png(p)
	print("T3P sheet ", p)


func _measure() -> void:
	var total := 0
	var draws := 0
	var lines: PackedStringArray = []
	for n in model.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var m := (gi as MeshInstance3D).mesh
			var v := 0
			var per := PackedStringArray()
			for s: int in m.get_surface_count():
				var sv := (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				v += sv
				var mat := m.surface_get_material(s)
				per.append("%s:%d" % [mat.resource_name if mat and mat.resource_name != "" else "?", sv])
			total += v
			draws += 1
			lines.append("  %s %d verts [%s]" % [model.get_path_to(gi), v, ", ".join(per)])
		elif gi is GPUParticles3D and (gi as GPUParticles3D).emitting:
			draws += 1
	print("T3P verts %d draws %d" % [total, draws])
	for l in lines:
		print(l)


func _views() -> void:
	var imgs: Array[Image] = []
	var fy := float(model.get(&"body_height")) * 0.55 if model.get(&"body_height") != null else 1.2
	var d := float(args.get("dist", "6.0"))
	for v: Array in [[35.0, 14.0, d], [90.0, 6.0, d], [215.0, 20.0, d], [-70.0, 10.0, d], [0.0, 55.0, d * 1.6],
			[150.0, 55.0, d * 1.6]]:
		_orbit(v[0], v[1], v[2], fy)
		await _wait(0.3)
		imgs.append(await _grab())
	_sheet(imgs, 3, "views", 640, 420)
	# close face
	_orbit(20.0, 8.0, d * 0.42, float(args.get("face_y", str(fy * 1.6))))
	await _wait(0.3)
	var face: Array[Image] = [await _grab()]
	_orbit(-25.0, 25.0, d * 0.42, float(args.get("face_y", str(fy * 1.6))))
	await _wait(0.2)
	face.append(await _grab())
	_sheet(face, 2, "face", 640, 420)


## Game camera (pitch 55, fov 50) at zoom 30 and 40 with reference units beside it.
func _rts() -> void:
	var refs: Array[Node3D] = []
	if args.has("refs"):
		var x := 3.2
		for r: String in String(args["refs"]).split(","):
			var n := (load(r) as PackedScene).instantiate() as Node3D
			world.add_child(n)
			n.position = ORIGIN + Vector3(x, 0, 0.8 if refs.size() % 2 == 0 else -0.8)
			x += 3.0
			refs.append(n)
	await _wait(0.8)
	var imgs: Array[Image] = []
	for z: float in [30.0, 40.0]:
		var at := ORIGIN + Vector3(3.0, 0, 0)
		cam.position = at + Vector3(0, sin(deg_to_rad(55.0)), cos(deg_to_rad(55.0))) * z
		cam.rotation = Vector3(-deg_to_rad(55.0), 0, 0)
		await _wait(0.2)
		var im := await _grab()
		var w := im.get_width()
		var h := im.get_height()
		imgs.append(im.get_region(Rect2i(w / 2 - 320, h / 2 - 170, 640, 340)))
	_sheet(imgs, 1, "rts", 1280, 680)
	for n in refs:
		n.queue_free()


func _attack() -> void:
	var imgs: Array[Image] = []
	var fy := float(model.get(&"body_height")) * 0.55 if model.get(&"body_height") != null else 1.2
	var d := float(args.get("dist", "6.0"))
	for t: float in [0.0, 0.06, 0.1, 0.15, 0.24, 0.4]:
		if t > 0.0:
			model.call(&"play_attack")
			var t0 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < int(t * 1000.0):
				await process_frame
			_pause(model, true)
		_orbit(70.0, 12.0, d, fy)
		await process_frame
		await process_frame
		imgs.append(await _grab())
		_pause(model, false)
		await _wait(1.0)
	# game angle strike
	model.call(&"play_attack")
	await _wait(0.12)
	_pause(model, true)
	_orbit(0.0, 55.0, d * 1.7, fy)
	await process_frame
	await process_frame
	imgs.append(await _grab())
	_pause(model, false)
	await _wait(1.0)
	if model.has_method(&"play_charge"):
		model.call(&"play_charge")
		await _wait(0.12)
		_pause(model, true)
		_orbit(70.0, 12.0, d, fy)
		await process_frame
		await process_frame
		imgs.append(await _grab())
		_pause(model, false)
		await _wait(1.0)
	_sheet(imgs, 4, "attack", 480, 360)


func _pause(n: Node, on: bool) -> void:
	n.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT


func _move_sheet() -> void:
	var imgs: Array[Image] = []
	var fy := float(model.get(&"body_height")) * 0.55 if model.get(&"body_height") != null else 1.2
	var d := float(args.get("dist", "6.0"))
	for sp: float in [1.8, 6.8]:
		model.call(&"set_moving", sp)
		await _wait(1.0)
		for k: int in 4:
			_orbit(90.0, 8.0, d, fy)
			imgs.append(await _grab())
			await _wait(0.13)
	model.call(&"set_moving", 0.0)
	await _wait(0.6)
	_sheet(imgs, 4, "move", 480, 340)


func _death() -> void:
	var imgs: Array[Image] = []
	var fy := float(model.get(&"body_height")) * 0.55 if model.get(&"body_height") != null else 1.2
	var d := float(args.get("dist", "6.0"))
	model.call(&"play_hit")
	await _wait(0.05)
	_orbit(35.0, 20.0, d, fy)
	imgs.append(await _grab())
	await _wait(0.6)
	model.call(&"play_death")
	for t: float in [0.2, 0.45, 0.7, 1.05]:
		await _wait(t - (0.0 if imgs.size() == 1 else [0.2, 0.45, 0.7, 1.05][imgs.size() - 2]))
		_orbit(35.0, 20.0, d, fy)
		imgs.append(await _grab())
	_sheet(imgs, 5, "death", 400, 300)
