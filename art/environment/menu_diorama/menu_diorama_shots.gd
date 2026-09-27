extends SceneTree
## Look-dev / screenshot / GPU probe for the menu diorama (task A2.10). Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/menu_diorama/menu_diorama_shots.gd
##       --fixed-fps 60 --quit-after 8000 -- tag=v1 size=1600x900      (or size=3440x1440)
## The diorama and the real main menu (its 2D MenuBackdrop hidden) render in a SubViewport of exactly `size`, so
## the shots do not depend on the OS window. Saves docs/art/screens/menu_diorama_<tag>_<W>x<H>_<shot>.png and
## prints the measured GPU time of that viewport (diorama + menu).
## Args: tag=NAME, size=WxH, shots=a,b,c (default: all), gpu=0 to skip the GPU probe, look=0|1|2 (altar look),
## set=property:value (a float export of the diorama, e.g. set=distance:30).
## Shots: wide (no UI), wide_ui (main menu on top), drift_l / drift_r (the two ends of the sway, UI on),
##        skirmish_ui (skirmish setup panel, camera on the player's wizard), focus_fire / focus_shadow /
##        focus_ice / focus_nature (no UI).

const DIORAMA := "res://art/environment/menu_diorama/menu_diorama.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
const ALL_SHOTS: Array[String] = ["wide", "wide_ui", "drift_l", "drift_r", "skirmish_ui", "focus_fire",
	"focus_shadow", "focus_ice", "focus_nature"]

var _tag := "shot"
var _shots: Array[String] = []
var _gpu := true
var _size := Vector2i(1600, 900)
var _vp: SubViewport
var _dio: Node3D
var _menu: Control


func _initialize() -> void:
	_shots = ALL_SHOTS.duplicate()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("shots="):
			_shots.clear()
			for s: String in arg.substr(6).split(","):
				_shots.append(s)
		elif arg == "gpu=0":
			_gpu = false
		elif arg.begins_with("size="):
			var wh := arg.substr(5).split("x")
			_size = Vector2i(int(wh[0]), int(wh[1]))
	_vp = SubViewport.new()
	_vp.size = _size
	_vp.msaa_3d = Viewport.MSAA_2X   # project setting of the root viewport
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	_dio = (load(DIORAMA) as PackedScene).instantiate() as Node3D
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("look="):
			_dio.set(&"altar_look", int(arg.substr(5)))
			_tag += "_look" + arg.substr(5)
		elif arg.begins_with("set="):
			var kv := arg.substr(4).split(":")
			_dio.set(StringName(kv[0]), float(kv[1]))
		elif arg == "native=1":
			_dio.set(&"auto_render_scale", false)
			_tag += "_native"
		elif arg == "bilinear=1":
			_dio.set(&"render_scale_fsr", false)
			_tag += "_bil"
	_vp.add_child(_dio)
	if ResourceLoader.exists(MENU):
		_menu = (load(MENU) as PackedScene).instantiate() as Control
		_vp.add_child(_menu)
	_run()


## The painted 2D backdrop would cover the 3D view: hide it (the lead removes it when plugging the diorama).
func _hide_backdrop() -> void:
	if _menu == null:
		return
	for c: Node in _menu.get_children():
		if c is MenuBackdrop:
			(c as Control).visible = false


func _set_time(t: float) -> void:
	_dio.set(&"_time", t)


func _run() -> void:
	for i in 30:
		await process_frame
	_hide_backdrop()
	print("viewport %s" % _vp.size)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("exp="):
			for e: String in arg.substr(4).split(","):
				_experiment(e)
	if _gpu:
		await _probe("wide_ui")
		await _probe("wide")
	for s: String in _shots:
		if s == "none":
			continue
		_menu_mode(s)
		match s:
			"wide", "wide_ui":
				_dio.call(&"focus_kingdom", &"")
				_dio.set(&"_blend", 1.0)
				_set_time(0.0)
			"drift_l":
				_dio.call(&"focus_kingdom", &"")
				_dio.set(&"_blend", 1.0)
				_set_time(float(_dio.get(&"drift_period")) * 0.25)
			"drift_r":
				_dio.call(&"focus_kingdom", &"")
				_dio.set(&"_blend", 1.0)
				_set_time(float(_dio.get(&"drift_period")) * 0.75)
			"skirmish_ui":
				_dio.call(&"focus_kingdom", &"fire")
				_dio.set(&"_blend", 1.0)
				_set_time(0.0)
			_:
				if s.begins_with("focus_"):
					_dio.call(&"focus_kingdom", StringName(s.substr(6)))
					_dio.set(&"_blend", 1.0)
					_set_time(0.0)
		for i in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = _vp.get_texture().get_image()
		var path := "res://docs/art/screens/menu_diorama_%s_%dx%d_%s.png" % [_tag, _size.x, _size.y, s]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	quit()


## Perf experiments (exp=a,b): what each part of the frame costs.
func _experiment(e: String) -> void:
	var env: Environment = (_dio.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	match e:
		"noshadow":
			(_dio.get_node(^"Sun") as DirectionalLight3D).shadow_enabled = false
		"flatground":
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.3, 0.4, 0.2)
			(_dio.get_node(^"Ground") as MeshInstance3D).material_override = m
		"nomsaa":
			_vp.msaa_3d = Viewport.MSAA_DISABLED
		"noglow":
			env.glow_enabled = false
		"glow35":
			env.set_glow_level(1, 0.0)
		"glow5":
			env.set_glow_level(1, 0.0)
			env.set_glow_level(2, 0.0)
			env.set_glow_level(4, 1.0)
		"nosky":
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.5, 0.3, 0.3)
		"nocanvas":
			_menu.visible = false
		"nofog":
			env.fog_enabled = false
		"noadjust":
			env.adjustment_enabled = false
		"nofar":
			(_dio.get_node(^"FarTreeline") as Node3D).visible = false
		"notrees":
			(_dio.get_node(^"Trees") as Node3D).visible = false
		"nolights":
			for n: Node in _dio.find_children("*", "OmniLight3D", true, false):
				(n as OmniLight3D).visible = false
		"noparticles":
			for n: Node in _dio.find_children("*", "GPUParticles3D", true, false):
				(n as GPUParticles3D).visible = false
		"novignette":
			(_dio.get_node(^"Vignette") as CanvasLayer).visible = false
		"nobeacon":
			var b := _dio.get_node_or_null(^"Altar/Beacon") as Node3D
			if b:
				b.scale = Vector3.ZERO
		"linearglow":
			RenderingServer.environment_glow_set_use_bicubic_upscale(false)
		"ortho":
			(_dio.get_node(^"Sun") as DirectionalLight3D).directional_shadow_mode = \
					DirectionalLight3D.SHADOW_ORTHOGONAL
		"fxaa":
			_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		_:
			# fsrNN / bilNN: 3D resolution scale NN % with FSR 1 or bilinear upscaling.
			if e.begins_with("fsr") or e.begins_with("bil"):
				_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if e.begins_with("fsr") \
						else Viewport.SCALING_3D_MODE_BILINEAR
				_vp.scaling_3d_scale = float(e.substr(3)) / 100.0


func _menu_mode(shot: String) -> void:
	if _menu == null:
		return
	var ui := shot.ends_with("_ui") or shot.begins_with("drift")
	_menu.visible = ui
	if shot == "skirmish_ui":
		_menu.call(&"show_skirmish_setup")
	else:
		_menu.call(&"show_main")


## Average GPU / CPU time of the SubViewport over 240 frames.
func _probe(shot: String) -> void:
	_menu_mode(shot)
	var rid := _vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for i in 60:
		await process_frame
	var gpu := 0.0
	var cpu := 0.0
	var worst := 0.0
	var n := 240
	for i in n:
		await process_frame
		var g := RenderingServer.viewport_get_measured_render_time_gpu(rid)
		gpu += g
		worst = maxf(worst, g)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
	print("GPU %s %dx%d: avg %.2f ms, worst %.2f ms (render cpu %.2f ms)" % [shot, _size.x, _size.y, gpu / n,
			worst, cpu / n])
