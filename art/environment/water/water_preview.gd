extends SceneTree
## Task 12.V1 screenshots of the water test strip (windowed only, headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/water/water_preview.gd --resolution 1600x900 --quit-after 4000
## Saves docs/art/screens/water_<shot>.png and prints draw calls, primitives and GPU time per shot, then a flow check
## (the same frame 0.5 s apart must differ on the water) and the cost of the water (GPU time with / without it).
## `only=<shot>,<shot>` limits the shots.

const STRIP := "res://art/environment/water/water_test_strip.tscn"

var _rig: Node3D
var _strip: Node3D
var _only := ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_run()


func _wanted(shot: String) -> bool:
	return _only == "" or _only.split(",").has(shot)


func _shoot(shot: String, zoom: float, focus: Vector3, yaw: float = 0.0, pitch: float = 55.0, save: bool = true) -> float:
	_rig.set(&"pitch_degrees", pitch)
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.rotation.y = yaw
	_rig.call(&"focus_on", focus)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var gpu := 0.0
	for i in 40:
		await process_frame
		if i >= 20:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp) / 20.0
	await RenderingServer.frame_post_draw
	var draws: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	if save:
		var img: Image = root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/water_%s.png" % shot))
	print("shot %-14s draws=%d prims=%d gpu_ms=%.2f fps=%d" % [shot, draws, prims, gpu, Engine.get_frames_per_second()])
	return gpu


func _run() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	_strip = (load(STRIP) as PackedScene).instantiate()
	stage.add_child(_strip)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	var tris := 0
	for n: Node in _strip.get_children():
		var mi := n as MeshInstance3D
		if mi and mi.mesh is ArrayMesh and (n.name.contains("Water") or n.name.contains("Walls") \
				or n.name.contains("Film") or n.name.contains("Ends")):
			var t: int = (mi.mesh as ArrayMesh).surface_get_array_index_len(0) / 3
			tris += t
			print("mesh %-14s %d tris" % [n.name, t])
	print("water + trench triangles (north river, whole moat, 3 fords): %d" % tris)
	var shots: Array = [
		["z45", 45.0, Vector3(-6, 0, -24)],
		["z30", 30.0, Vector3(-4, 0, -12)],
		["ford_z14", 14.0, Vector3(-8.5, 0, -32.5)],
		["barge_z11", 11.0, Vector3(-6.0, 0, -23.0)],
		["steps_z16", 16.0, Vector3(-9.0, 0, -7.0)],
		["bank_z10", 10.0, Vector3(-10.4, 0, -40.8)],
		["walls_low", 9.0, Vector3(-4.5, 0, -18.5), 0.45, 28.0],
		["mouth_z18", 18.0, Vector3(-3.0, 0, -13.0)],
		["wade_z7", 7.0, Vector3(-8.2, 0, -32.6)],
		["trench_close", 5.0, Vector3(-7.4, 0, -22.3), 1.25, 24.0],
	]
	for s: Array in shots:
		if _wanted(s[0]):
			await _shoot(s[0], s[1], s[2], s[3] if s.size() > 3 else 0.0, s[4] if s.size() > 4 else 55.0)
	# Map detail Low.
	var wmat := load("res://art/environment/water/water_mat.tres") as ShaderMaterial
	var fmat := load("res://art/environment/water/water_ford_mat.tres") as ShaderMaterial
	if _wanted("low_z30"):
		wmat.set_shader_parameter(&"detail", 0.0)
		fmat.set_shader_parameter(&"detail", 0.0)
		await _shoot("low_z30", 30.0, Vector3(-4, 0, -12))
		wmat.set_shader_parameter(&"detail", 1.0)
		fmat.set_shader_parameter(&"detail", 1.0)
	# Flow check: the ford 0.5 s apart.
	_rig.set(&"pitch_degrees", 55.0)
	_rig.rotation.y = 0.0
	_rig.set(&"_target_zoom", 14.0)
	_rig.set(&"_zoom", 14.0)
	_rig.call(&"focus_on", Vector3(-8.5, 0, -32.5))
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var a: Image = root.get_texture().get_image()
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var b: Image = root.get_texture().get_image()
	var changed := 0
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.04:
				changed += 1
	print("flow check: %d of %d sampled pixels changed in 0.5 s" % [changed, (a.get_width() / 4) * (a.get_height() / 4)])
	# Cost: GPU time at max zoom over the river with and without the water pieces.
	var with_w: float = await _shoot("cost_on", 55.0, Vector3(-4, 0, -20), 0.0, 55.0, false)
	for n: Node in _strip.get_children():
		if n is MeshInstance3D and (n.name.contains("Water") or n.name.contains("Film")):
			(n as MeshInstance3D).visible = false
	var without_w: float = await _shoot("cost_off", 55.0, Vector3(-4, 0, -20), 0.0, 55.0, false)
	print("water cost at zoom 55: %.3f ms (%.2f with, %.2f without)" % [with_w - without_w, with_w, without_w])
	print("SHOTS DONE")
	quit()
