extends SceneTree
## Windowed still sheet of the dragon sky (art/cinematics/flocks/README.md):
##   & .\tools\godot_run.ps1 --path . -s res://art/cinematics/flocks/tools/flock_sheet.gd --quit-after 20000 '--' [set=forge_citadel] [scene=res://...tscn] [far=0]
## Backdrop: the World Forge set `set=` if it is built (its own WorldEnvironment, or a dawn sky), else a plain dawn sky
## over a cloud-sea plane. Flocks: `scene=` (default dragon_sky.tscn) + dragon_sky_far.tscn (far=0 to skip).
## Writes art/cinematics/flocks/sheets/sheet.png (2.39 crops, 5 views x 2 times + the LOD pair) and prints the budget,
## the draw calls with / without the flock and a render determinism check (same t twice, after another t).

const OUT := "res://art/cinematics/flocks/sheets"
const TW := 640
const TH := 268

var _flock: DragonFlock
var _far: DragonFlock
var _cam: Camera3D


func _init() -> void:
	_run.call_deferred()


func _pose(t: float) -> void:
	for f: DragonFlock in [_flock, _far]:
		if f:
			f.set_cine_time(t)


func _grab(t: float) -> Image:
	for i: int in 3:
		_pose(t)
		await process_frame
	_pose(t)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	# the 2.39 band of the frame
	var bh := int(img.get_width() / 2.39)
	var band := img.get_region(Rect2i(0, (img.get_height() - bh) / 2, img.get_width(), bh))
	return band


func _env(set_node: Node) -> void:
	if set_node and not set_node.find_children("*", "WorldEnvironment", true, false).is_empty():
		return
	var we := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.33, 0.47, 0.72)
	sm.sky_horizon_color = Color(0.95, 0.74, 0.55)
	sm.ground_horizon_color = Color(0.9, 0.72, 0.58)
	sm.ground_bottom_color = Color(0.55, 0.5, 0.52)
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.fog_enabled = true
	e.fog_light_color = Color(0.86, 0.78, 0.72)
	e.fog_density = 0.0007
	e.fog_aerial_perspective = 0.6
	we.environment = e
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-22, 35, 0)
	sun.light_color = Color(1.0, 0.86, 0.7)
	sun.light_energy = 1.3
	root.add_child(sun)
	if set_node == null:
		# a cloud sea 0-40 m below the flock, for scale
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1400, 1400)
		mi.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.93, 0.9, 0.9)
		mat.roughness = 1.0
		mi.material_override = mat
		mi.position = Vector3(0, -5, 0)
		root.add_child(mi)


func _run() -> void:
	var set_id := ""
	var scene := "res://art/cinematics/flocks/dragon_sky.tscn"
	var with_far := true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("set="):
			set_id = a.substr(4)
		elif a.begins_with("scene="):
			scene = a.substr(6)
		elif a == "far=0":
			with_far = false
	var set_node: Node3D = null
	var set_path := "res://art/cinematics/stage_sets/%s/%s.tscn" % [set_id, set_id]
	if set_id != "" and ResourceLoader.exists(set_path):
		set_node = (load(set_path) as PackedScene).instantiate() as Node3D
		root.add_child(set_node)
		print("backdrop: set %s" % set_id)
	else:
		print("backdrop: plain dawn sky (set %s not built)" % set_id if set_id != "" else "backdrop: plain dawn sky")
	_env(set_node)
	_cam = Camera3D.new()
	_cam.far = 250.0
	root.add_child(_cam)
	_cam.current = true
	_flock = (load(scene) as PackedScene).instantiate() as DragonFlock
	root.add_child(_flock)
	if with_far:
		_far = (load("res://art/cinematics/flocks/dragon_sky_far.tscn") as PackedScene).instantiate() as DragonFlock
		root.add_child(_far)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# the first hero (an elder) for the close view
	var hero_i := -1
	for i: int in _flock.flyer_count():
		if bool(_flock.flyer_state(i, 0.0)["hero"]):
			hero_i = i
			break
	var views: Array = [
		["ground_up", Vector3(0, 6, 150), Vector3(0, 60, 0), 50.0],
		["high_wide", Vector3(-140, 95, 140), Vector3(0, 45, 0), 45.0],
		["in_flock", Vector3(40, 48, 60), Vector3(-20, 44, -40), 40.0],
		["hero_close", Vector3.ZERO, Vector3.ZERO, 38.0],
		["small_flight", Vector3.ZERO, Vector3.ZERO, 36.0],
	]
	var small_i := _flock.flyer_count() - 1
	var times: Array[float] = [3.0, 21.5]
	var tiles: Array[Image] = []
	var names: Array[String] = []
	for t: float in times:
		for v: Array in views:
			var from: Vector3 = v[1]
			var look: Vector3 = v[2]
			if v[0] == "hero_close" and hero_i >= 0:
				var st := _flock.flyer_state(hero_i, t)
				var x: Transform3D = st["xform"]
				var sc: float = st["scale"]
				look = _flock.to_global(x.origin)
				from = look + x.basis.orthonormalized() * Vector3(-7.0, 2.5, 9.0) * sc
			elif v[0] == "small_flight":
				var st2 := _flock.flyer_state(small_i, t)
				var x2: Transform3D = st2["xform"]
				look = _flock.to_global(x2.origin)
				from = look + x2.basis.orthonormalized() * Vector3(-5.0, 2.0, 10.0)
			_cam.fov = v[3]
			_cam.global_position = from
			_cam.look_at(look)
			var img: Image = await _grab(t)
			img.save_png(ProjectSettings.globalize_path(OUT.path_join("%s_t%04.1f.png" % [v[0], t])))
			img.resize(TW, TH, Image.INTERPOLATE_BILINEAR)
			tiles.append(img)
			names.append("%s t=%.1f" % [v[0], t])
	# LOD pair: the in-flock view with every impostor near vs every impostor far
	_cam.global_position = views[2][1]
	_cam.look_at(views[2][2])
	_cam.fov = views[2][3]
	var keep := _flock.lod_px
	_flock.lod_px = 0.0
	var near_img: Image = await _grab(21.5)
	_flock.lod_px = 100000.0
	var far_img: Image = await _grab(21.5)
	_flock.lod_px = keep
	for im: Image in [near_img, far_img]:
		im.resize(TW, TH, Image.INTERPOLATE_BILINEAR)
		tiles.append(im)
	names.append("LOD all near t=21.5")
	names.append("LOD all far t=21.5")
	# render determinism: t=21.5, then 3.0, then 21.5 again
	var a: Image = await _grab(21.5)
	var _b: Image = await _grab(3.0)
	var c: Image = await _grab(21.5)
	var diff := 0
	for y: int in range(0, a.get_height(), 2):
		for x: int in range(0, a.get_width(), 2):
			var p := a.get_pixel(x, y)
			var q := c.get_pixel(x, y)
			if absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.02:
				diff += 1
	print("render determinism (t 21.5 -> 3.0 -> 21.5): %d changed px of %d sampled" % [diff, (a.get_width() / 2) * (a.get_height() / 2)])
	# draw calls with / without the flocks (high_wide view)
	_cam.global_position = views[1][1]
	_cam.look_at(views[1][2])
	_cam.fov = views[1][3]
	await _grab(21.5)
	await process_frame
	var dc_on := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var pr_on := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var t0 := Time.get_ticks_usec()
	for i: int in 30:
		_pose(21.5 + i / 30.0)
	var upd := (Time.get_ticks_usec() - t0) / 1000.0 / 30.0
	_flock.visible = false
	if _far:
		_far.visible = false
	for i: int in 3:
		await process_frame
	var dc_off := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var pr_off := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	print("draw calls: %d with the flocks, %d without (+%d); primitives +%d; update both flocks %.2f ms / frame" % [dc_on, dc_off, dc_on - dc_off, pr_on - pr_off, upd])
	for f: DragonFlock in [_flock, _far]:
		if f:
			print("%s: %s" % [f.name, str(f.budget())])
	# the sheet
	var cols := 5
	var rows := int(ceil(tiles.size() / float(cols)))
	var sheet := Image.create(cols * TW + (cols + 1) * 6, rows * TH + (rows + 1) * 6, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.08, 0.08, 0.09))
	for i: int in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, TW, TH), Vector2i(6 + (i % cols) * (TW + 6), 6 + (i / cols) * (TH + 6)))
	sheet.save_png(ProjectSettings.globalize_path(OUT.path_join("sheet.png")))
	print("sheet tiles (left to right, top to bottom): " + " | ".join(names))
	print("DONE flock_sheet -> %s/sheet.png" % OUT)
	quit(0)
