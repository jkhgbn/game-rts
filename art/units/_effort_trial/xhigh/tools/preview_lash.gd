extends SceneTree
## Windowed preview of the Vinelasher's lash / snare shapes (effort trial xhigh): a grid of frames from the side and
## from a 55-degree game-like camera. Usage (through the Godot gate):
##   .\tools\godot_run.ps1 --path . -s res://art/units/_effort_trial/xhigh/tools/preview_lash.gd --quit-after 3000 '--' out=<png path>

const SCENE := "res://art/units/_effort_trial/xhigh/vinelasher.tscn"
const CELL := Vector2i(320, 320)
const SHOTS: Array = [["rest", 0.0], ["attack", 0.05], ["attack", 0.1], ["attack", 0.15], ["attack", 0.2],
	["attack", 0.3], ["attack", 0.42], ["attack", 0.55], ["cast", 0.08], ["cast", 0.18], ["cast", 0.32], ["cast", 0.52],
	["cast", 0.7]]


func _initialize() -> void:
	_run()


func _run() -> void:
	var out := "user://vinelasher_preview.png"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	var sv := SubViewport.new()
	sv.size = CELL
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_2X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.7)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	e.ambient_light_energy = 0.8
	env.environment = e
	sv.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.2
	sv.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.42, 0.58, 0.3)
	ground.material_override = gm
	sv.add_child(ground)
	# 1 m grid marks along +Z (reach check)
	for z: int in range(1, 5):
		var mk := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.6, 0.02, 0.04)
		mk.mesh = bm
		mk.position = Vector3(0, 0.01, float(z))
		sv.add_child(mk)
	var cam := Camera3D.new()
	cam.fov = 50.0
	sv.add_child(cam)
	var cams: Array = [[Vector3(7.5, 1.6, 1.4), Vector3(0, 1.0, 1.4)], [Vector3(0.0, 7.5, 6.8), Vector3(0, 0.6, 1.2)]]
	var scene := load(SCENE) as PackedScene
	var grid := Image.create(CELL.x * SHOTS.size(), CELL.y * cams.size(), false, Image.FORMAT_RGBA8)
	for si: int in SHOTS.size():
		var shot: Array = SHOTS[si]
		var m: Node3D = scene.instantiate()
		sv.add_child(m)
		await process_frame
		await process_frame
		m.set_process(false)
		var t: float = 0.0
		if shot[0] == "attack":
			m.call(&"play_attack")
		elif shot[0] == "cast":
			m.call(&"play_cast", &"snare_lash")
		while t < float(shot[1]) - 0.0001:
			m.call(&"_process", 0.01)
			t += 0.01
		m.call(&"_process", 0.0001)
		for ci: int in cams.size():
			cam.position = cams[ci][0]
			cam.look_at(cams[ci][1])
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var img := sv.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			grid.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i(si * CELL.x, ci * CELL.y))
		m.queue_free()
		await process_frame
	grid.save_png(out)
	print("PREVIEW saved ", out)
	quit()
