extends SceneTree
## G-F review 3 item 5 (docs/art/gf_r3_autumn.md): the autumn haze lifted. On real Ashwind Reach and Quartermeet levels
## the live Environment has fog_density 0.10-0.20, fog_aerial_perspective 0.05-0.14 and a cool grey fog light (each
## channel 0.72-0.86, blue >= red); the autumn .tres file itself too. Ashwind's own ground material gets the brown-ochre
## lane dirt from LaneDressing.paint_lane_ground (road about (0.42, 0.30, 0.20), saturation <= 0.55) and the shared
## plateau material is left alone.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gf_r3_autumn.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "gf_r3_autumn"
const ENV_PATH := "res://art/environment/autumn/world_env_autumn.tres"
const PLATEAU := "res://art/environment/plateau_mat.tres"
const GROUND_SHADER := "res://art/environment/ground.gdshader"

var fails: Array[String] = []


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	_check_env(load(ENV_PATH) as Environment, "world_env_autumn.tres")
	await _check_level(&"ashwind_reach", true)
	await _check_level(&"quartermeet", false)
	MapInfo.reset()
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
	quit(0 if fails.is_empty() else 1)


func _check_env(env: Environment, label: String) -> void:
	if env == null:
		fails.append("%s: no Environment" % label)
		return
	if not env.fog_enabled:
		fails.append("%s: fog off" % label)
	if env.fog_density < 0.10 or env.fog_density > 0.20:
		fails.append("%s: fog_density %.3f (0.10-0.20)" % [label, env.fog_density])
	if env.fog_aerial_perspective < 0.05 or env.fog_aerial_perspective > 0.14:
		fails.append("%s: fog_aerial_perspective %.3f (0.05-0.14)" % [label, env.fog_aerial_perspective])
	var c := env.fog_light_color
	for ch: float in [c.r, c.g, c.b]:
		if ch < 0.72 or ch > 0.86:
			fails.append("%s: fog_light_color %s outside 0.72-0.86" % [label, c])
			break
	if c.b < c.r:
		fails.append("%s: fog_light_color %s is warm (blue < red)" % [label, c])
	print("%s: fog density %.3f aerial %.3f colour %s" % [label, env.fog_density, env.fog_aerial_perspective, c])


func _check_level(map_id: StringName, lane: bool) -> void:
	var level := MapCatalog.load_default().instantiate_level(map_id)
	if level == null:
		fails.append("%s: no level" % map_id)
		return
	root.add_child(level)
	current_scene = level
	for f: int in 10:
		await process_frame
	var env: Environment = null
	for n: Node in level.find_children("*", "WorldEnvironment", true, false):
		env = (n as WorldEnvironment).environment
		break
	_check_env(env, "%s level" % map_id)
	var ld := load("res://art/environment/lane_dressing/lane_dressing.gd") as Script
	var plateau := load(PLATEAU) as ShaderMaterial
	var plateau_road: Variant = plateau.get_shader_parameter(&"road_color") if plateau else null
	var painted := int(ld.call(&"paint_lane_ground", level)) if bool(ld.call(&"wants", level)) else 0
	if lane:
		if painted < 1:
			fails.append("%s: lane ground not painted (%d materials)" % [map_id, painted])
		var found := false
		for sm: ShaderMaterial in _ground_mats(level):
			if sm == plateau:
				continue
			found = true
			var road := sm.get_shader_parameter(&"road_color") as Color
			var dirt := sm.get_shader_parameter(&"dirt_color") as Color
			if absf(road.r - 0.42) > 0.04 or absf(road.g - 0.31) > 0.04 or absf(road.b - 0.21) > 0.04:
				fails.append("%s: road_color %s not about (0.42, 0.30, 0.20)" % [map_id, road])
			if road.s > 0.55 or dirt.s > 0.55:
				fails.append("%s: lane dirt too saturated (road s %.2f, dirt s %.2f)" % [map_id, road.s, dirt.s])
			print("%s ground: road %s dirt %s" % [map_id, road, dirt])
		if not found:
			fails.append("%s: no level ground material" % map_id)
	elif painted != 0:
		fails.append("%s: LaneDressing painted a non-lane level" % map_id)
	if plateau and plateau.get_shader_parameter(&"road_color") != plateau_road:
		fails.append("%s: the shared plateau material was repainted" % map_id)
	level.queue_free()
	for f: int in 3:
		await process_frame


func _ground_mats(level: Node) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for node: Node in level.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		var mats: Array = [gi.material_override]
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				mats.append(mi.get_surface_override_material(s))
				mats.append(mi.mesh.surface_get_material(s))
		for m: Variant in mats:
			var sm := m as ShaderMaterial
			if sm and sm.shader and sm.shader.resource_path == GROUND_SHADER and not sm in out:
				out.append(sm)
	return out
