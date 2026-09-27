extends SceneTree
## Task 6.S2: building and environment art plugged in (skirmish). A hall, a hearth site and a tower use
## their art models and receive the hooks (team colour, construction progress, health ratio, selected,
## training pulse, play_shot, destroyed -> freed after destroyed_finished); a crystal node's art fill
## ratio drops as it is mined (and the node no longer scales); trees / rocks / pillars are MultiMeshes,
## the ground is the painted material, the peddlers and caches use their art.
## Run: godot --headless --path . -s tests/test_6_s2.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "6.s2"
const TIMEOUT_FRAMES := 1200

var main: Node
var frame := 0
var _wait := 0
var _phase := 0
var _phase_frame := 0
var _hall: Node
var _site: Node
var _tower: Node
var _builder: Node3D
var _shot_seen := false
var _pulse_seen := false


func _initialize() -> void:
	main = load("res://scenes/skirmish.tscn").instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: map never ready" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 1:
		return _setup()
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out in phase %d" % [TASK_ID, _phase])
		return true
	return _step()


func _fail(reason: String) -> bool:
	print("FAIL %s: %s" % [TASK_ID, reason])
	return true


func _model_script(b: Node) -> String:
	var m: Node = b.call(&"model")
	if m == null or m.get_script() == null:
		return ""
	return (m.get_script() as Script).resource_path


func _setup() -> bool:
	# --- environment
	var env: Node = main.get(&"env_props")
	if env == null or int(env.call(&"instance_count")) < 20:
		return _fail("no EnvProps MultiMeshes")
	var mmi_count := 0
	for c in env.get_children():
		if c is MultiMeshInstance3D and (c as MultiMeshInstance3D).multimesh.instance_count > 0:
			mmi_count += 1
	if mmi_count < 5:
		return _fail("only %d prop MultiMeshes" % mmi_count)
	var ground_ok := false
	for n in main.nav_region.get_children():
		for c in n.get_children():
			var mi := c as MeshInstance3D
			if mi and mi.mesh is PlaneMesh and mi.material_override is ShaderMaterial:
				var lane: Variant = (mi.material_override as ShaderMaterial).get_shader_parameter(&"lane_b")
				if lane is Vector2 and (lane as Vector2).distance_to(Vector2(36.0, -36.0)) < 0.1:
					ground_ok = true
	if not ground_ok:
		return _fail("ground is not the painted material with the map's lane")
	for p in main.peddlers:
		if (p as Node).get_node_or_null(^"Art") == null:
			return _fail("peddler without art")
	for cache in main.caches:
		if cache.get(&"_art") == null:
			return _fail("cache without art")
	if main.crown.get(&"_pedestal_runes") == null:
		return _fail("crown pedestal without art")

	# --- crystal node: art fill ratio, no scaling
	var node: Node = main.node_of(0, "a")
	if absf(float(node.call(&"model_fill_ratio")) - 1.0) > 0.001:
		return _fail("crystal node art fill ratio %s at start" % node.call(&"model_fill_ratio"))
	var max_c: int = node.get(&"max_crystals")
	node.call(&"take", max_c / 2)
	var r := float(node.call(&"model_fill_ratio"))
	if absf(r - 0.5) > 0.01:
		return _fail("crystal node fill ratio %.3f after mining half" % r)
	if (node.get(&"_visual") as Node3D).scale != Vector3.ONE:
		return _fail("crystal node still scales its visual")

	# --- buildings
	var bg: Node = main.build_grid
	_hall = bg.call(&"spawn_complete", BuildingType.find("fire_barracks"), Vector3(-23.0, 0.0, 9.0), 0)
	_tower = bg.call(&"spawn_complete", BuildingType.find("fire_tower"), Vector3(-18.0, 0.0, 16.0), 0)
	_site = bg.call(&"create_building", BuildingType.find("fire_hearth"))
	_site.set(&"team", 0)
	_site.call(&"make_site")
	_site.set(&"position", Vector3(-50.0, 0.0, 46.0))
	main.nav_region.add_child(_site)
	if not _model_script(_hall).ends_with("fire_hall.gd"):
		return _fail("hall model is '%s'" % _model_script(_hall))
	if not _model_script(_tower).ends_with("fire_tower.gd"):
		return _fail("tower model is '%s'" % _model_script(_tower))
	if not _model_script(_site).ends_with("hearth.gd"):
		return _fail("hearth model is '%s'" % _model_script(_site))
	for b in [_hall, _tower, _site]:
		var m: Node = b.call(&"model")
		if not bool(m.get(&"_team_set")) or not (m.get(&"_team_color") as Color).is_equal_approx(b.get(&"team_color")):
			return _fail("%s model has no team colour" % b.name)
	if float(_site.call(&"model").get(&"_progress")) > 0.001:
		return _fail("site model progress not 0")
	# Shadow hall / hovel / night spire models load too.
	for id in ["shadow_barracks", "shadow_hovel", "shadow_tower"]:
		var t: BuildingType = BuildingType.find(id)
		if t.model_scene == null:
			return _fail("%s has no model_scene" % id)
	_builder = Node3D.new()
	main.add_child(_builder)
	_site.call(&"add_builder", _builder)
	# Hall: selected + damaged + a trained unit.
	_hall.call(&"set_selected", true)
	_hall.call(&"take_damage", float(_hall.get(&"max_hp")) * 0.6, null)
	var eco: Node = main.economy
	eco.call(&"add", 1000)
	var why: String = _hall.call(&"queue_unit", UnitType.find("flame_guard"))
	if why != "":
		return _fail("queue_unit refused: %s" % why)
	_hall.set(&"_train_time", 1000.0)   # finish the training on the next physics frame
	# Tower: an enemy shade in range.
	var shade: Node = main.make_unit("shade")
	main._spawn(shade, 1, Vector3(-14.0, 0.0, 16.0))
	return false


func _step() -> bool:
	_phase_frame += 1
	var tm: Node = _tower.call(&"model") if is_instance_valid(_tower) else null
	if tm and float(tm.get(&"_shot_left")) > 0.0:
		_shot_seen = true
	var hm0: Node = _hall.call(&"model") if is_instance_valid(_hall) else null
	if hm0 and float(hm0.get(&"_pulse_left")) > 0.0:
		_pulse_seen = true
	match _phase:
		0:
			var hm: Node = _hall.call(&"model")
			if _phase_frame < 60:
				return false
			if not bool(hm.get(&"_selected")):
				return _fail("hall model not selected")
			if absf(float(hm.get(&"_health_ratio")) - 0.4) > 0.02:
				return _fail("hall model health ratio %.2f" % float(hm.get(&"_health_ratio")))
			if not _pulse_seen:
				return _fail("hall model never got play_training_pulse")
			var sp := float(_site.call(&"model").get(&"_progress"))
			if sp <= 0.0 or absf(sp - float(_site.call(&"construction_progress"))) > 0.001:
				return _fail("site model progress %.3f vs %.3f" % [sp, _site.call(&"construction_progress")])
			_next()
		1:
			if _shot_seen:
				_next()
			elif _phase_frame > 600:
				return _fail("tower model never got play_shot")
		2:
			_hall.call(&"take_damage", 1.0e6, null)
			if not bool(_hall.call(&"model").get(&"_destroyed")):
				return _fail("hall model not destroyed")
			_next()
		3:
			if not is_instance_valid(_hall):
				print("PASS %s" % TASK_ID)
				return true
			if _phase_frame > 400:
				return _fail("hall not freed after destroyed_finished")
	return false


func _next() -> void:
	_phase += 1
	_phase_frame = 0
