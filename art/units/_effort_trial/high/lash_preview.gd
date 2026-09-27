extends SceneTree
## Effort-trial helper (windowed): shoots the Vinelasher's whip poses from the side and from a high 3/4 view.
## godot_run.ps1 --path . -s res://art/units/_effort_trial/high/lash_preview.gd --quit-after 3000
## Output: docs/art/lab/effort-trial/high/preview_<pose>.png (side | high, side by side).

const OUT := "res://docs/art/lab/effort-trial/high/"
const SHOTS := [["attack", 0.14], ["attack", 0.24], ["attack", 0.36], ["cast", 0.32], ["cast", 0.62]]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(800, 600)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.62, 0.7)
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.35, 0.55, 0.25)
	ground.material_override = gm
	world.add_child(ground)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	for shot: Array in SHOTS:
		var m: Node3D = load("res://art/units/_effort_trial/high/vinelasher.tscn").instantiate()
		world.add_child(m)
		for i: int in 5:
			await process_frame
		if shot[0] == "attack":
			m.call(&"play_attack")
		else:
			m.call(&"play_cast", &"snare_lash")
		await create_timer(shot[1]).timeout
		m.process_mode = Node.PROCESS_MODE_DISABLED
		var imgs: Array[Image] = []
		for view: int in 2:
			if view == 0:
				cam.position = Vector3(7.0, 1.4, 1.4)
				cam.look_at(Vector3(0, 1.0, 1.4))
			else:
				cam.position = Vector3(3.5, 7.5, -4.0)
				cam.look_at(Vector3(0, 0.8, 1.2))
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			imgs.append(root.get_texture().get_image())
		var w := imgs[0].get_width()
		var h := imgs[0].get_height()
		var out := Image.create(w * 2, h, false, imgs[0].get_format())
		out.blit_rect(imgs[0], Rect2i(0, 0, w, h), Vector2i(0, 0))
		out.blit_rect(imgs[1], Rect2i(0, 0, w, h), Vector2i(w, 0))
		out.save_png(ProjectSettings.globalize_path(OUT + "preview_%s_%03d.png" % [shot[0], int(shot[1] * 100)]))
		m.queue_free()
		await process_frame
	print("LASH PREVIEW done")
	quit()
