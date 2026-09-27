extends SceneTree
## Task A.11 screenshots: loads the real skirmish map (scenes/skirmish.tscn), bot off, fog off, HUD hidden,
## stages a fight in the centre and saves the game camera (pitch 55, fov 50) to
## docs/art/screens/polish_light_<tag>_<shot>.png. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/lighting/light_preview.gd
##       --resolution 1600x900 --quit-after 6000 -- tag=after rig=warm
## `rig=warm|ice` swaps main.gd's WorldEnvironment + sun for a LightingRig with that preset (what main.gd
## does once the lines in docs/art/lighting.md are applied); `rig=none` (default) keeps main.gd's own.
## `player=ice` sets the skirmish player_kingdom (Ice army in the south-west base), `only=<shot>` one shot.

const SHOTS: Array = [
	# [name, zoom, focus]
	["base_z30", 30.0, Vector3(-40.0, 0.0, 41.0)],
	["base_z45", 45.0, Vector3(-38.0, 0.0, 38.0)],
	["fight_z22", 22.0, Vector3(0.0, 0.0, 3.0)],
	["fight_z40", 40.0, Vector3(0.0, 0.0, 3.0)],
	["enemy_z35", 35.0, Vector3(40.0, 0.0, -38.0)],
	["edge_z55", 55.0, Vector3(10.0, 0.0, -52.0)],
]

var main: Node
var _tag := "shot"
var _rig := "none"
var _player := ""
var _only := ""
var _overrides: Array = []   ## "env:glow_intensity=0.6", "sun:light_energy=1.5", "vig:strength=0.2"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("rig="):
			_rig = arg.substr(4)
		elif arg.begins_with("player="):
			_player = arg.substr(7)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
		elif arg.begins_with("env:") or arg.begins_with("sun:") or arg.begins_with("fill:") \
				or arg.begins_with("vig:"):
			_overrides.append(arg)
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	if _player != "":
		main.set(&"player_kingdom", StringName(_player))
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	if _rig == "old":
		_old_lighting()
	elif _rig != "none":
		_swap_lighting(_rig)
	_apply_overrides()
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_stage_fight()
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for s: Array in SHOTS:
		if _only != "" and not _only.split(",").has(s[0]):
			continue
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = 0.0
		rig.call(&"focus_on", s[2])
		for i in 50:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/polish_light_%s_%s.png" % [_tag, s[0]]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s fps=%d draws=%d" % [path, Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	print("SHOTS DONE")
	quit()


## Replaces main.gd's WorldEnvironment and sun with the art rig (same as the handoff lines).
func _swap_lighting(preset_id: String) -> void:
	for n: Node in main.get_children():
		if n is WorldEnvironment or n is DirectionalLight3D:
			main.remove_child(n)
			n.free()
	var rig: Node = (load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new()
	rig.set(&"preset_id", StringName(preset_id))
	main.add_child(rig)


## The pre-A.11 world_env.tres and main.gd sun, rebuilt in code for fair before / after shots.
func _old_lighting() -> void:
	for n: Node in main.get_children():
		if n is WorldEnvironment or n is DirectionalLight3D:
			main.remove_child(n)
			n.free()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.42, 0.62)
	sky_mat.sky_horizon_color = Color(0.72, 0.68, 0.62)
	sky_mat.ground_bottom_color = Color(0.18, 0.16, 0.14)
	sky_mat.ground_horizon_color = Color(0.72, 0.68, 0.62)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.52, 0.7)
	env.ambient_light_energy = 0.35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	for i in 7:
		env.set_glow_level(i, 1.0 if i == 2 or i == 4 else 0.0)
	env.glow_intensity = 0.55
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.1
	env.glow_hdr_scale = 2.0
	var we := WorldEnvironment.new()
	we.environment = env
	main.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 90.0
	main.add_child(sun)


## Test-only tweaks from the command line, so values can be compared without editing the .tres.
func _apply_overrides() -> void:
	var rig: Node = main.get_node_or_null(^"LightingRig")
	for o: String in _overrides:
		var head := o.get_slice(":", 0)
		var kv := o.substr(head.length() + 1)
		var key := kv.get_slice("=", 0)
		var value: Variant = str_to_var(kv.substr(key.length() + 1))
		var target: Object = null
		match head:
			"env":
				for n: Node in main.find_children("*", "WorldEnvironment", true, false):
					target = (n as WorldEnvironment).environment
			"sun":
				target = rig.get(&"sun") if rig else null
			"fill":
				target = rig.get(&"fill") if rig else null
			"vig":
				if rig:
					var mat: ShaderMaterial = rig.get(&"_vignette_mat")
					mat.set_shader_parameter(key, value)
				continue
		if target:
			if key.contains("/"):
				target.set_indexed(NodePath(key), value)
			else:
				target.set(key, value)
			print("override %s.%s = %s" % [head, key, str(value)])


## Two small armies meet in the centre so the fight effects (bolts, hits) are on screen.
func _stage_fight() -> void:
	var p_ids: Array = ["flame_guard", "flame_guard", "flame_guard", "flame_guard", "ember_archer",
			"ember_archer", "ember_archer", "blaze_rider"]
	var e_ids: Array = ["shade", "shade", "shade", "shade", "shadow_knight", "nightbolt", "nightbolt",
			"grave_hound"]
	if _player == "ice":
		p_ids = ["rimeshield", "rimeshield", "rimeshield", "shardcaster", "shardcaster", "rime_seer",
				"rime_colossus", "shardcaster"]
	var mine: Array = []
	var theirs: Array = []
	for i in p_ids.size():
		var u: Node3D = main.call(&"make_unit", p_ids[i])
		if u == null:
			continue
		u.set(&"team", 0)
		main.add_child(u)
		u.global_position = Vector3(-7.0 + (i % 4) * 1.6, 0.0, 9.0 + (i / 4) * 1.8)
		mine.append(u)
	for i in e_ids.size():
		var u: Node3D = main.call(&"make_unit", e_ids[i])
		if u == null:
			continue
		u.set(&"team", 1)
		main.add_child(u)
		u.global_position = Vector3(3.0 + (i % 4) * 1.6, 0.0, -3.0 - (i / 4) * 1.8)
		theirs.append(u)
	for i in mine.size():
		mine[i].call(&"command_attack_move", Vector3(4.0, 0.0, -2.0))
	for i in theirs.size():
		theirs[i].call(&"command_attack_move", Vector3(-4.0, 0.0, 8.0))
