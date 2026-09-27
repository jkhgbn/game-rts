extends SceneTree
## Task 3.S1: the keeps use the art scenes and the art hooks are called; building kills give XP.
## Checks (1v1 map, scenes/skirmish.tscn):
## - both keeps have a model child under their visual and no placeholder box / roof; the Fire keep's
##   model is turned -90 degrees (gate toward the centre);
## - a building with a spy model gets set_team_color / set_health_ratio (on damage and heal) /
##   set_selected / play_training_pulse / play_destroyed, and is freed after destroyed_finished;
## - a Flame Guard that destroys an enemy building gets soldier XP;
## - Skirmish.node_of() is null (no error) once a node is freed, wardens drop dead ones,
##   the Hovel slot V1 (50, -46) passes BuildGrid.check.
## Run:  godot --headless --path . -s tests/test_3_s1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "3.S1"
const TIMEOUT_FRAMES := 1500

const SPY_SRC := """extends Node3D
signal destroyed_finished
var calls: Array = []
var last_ratio := -1.0
func set_team_color(c: Color) -> void:
	calls.append("team")
func set_construction_progress(p: float) -> void:
	calls.append("progress")
func set_health_ratio(r: float) -> void:
	calls.append("health")
	last_ratio = r
func set_selected(on: bool) -> void:
	calls.append("selected_%s" % on)
func play_training_pulse() -> void:
	calls.append("pulse")
func play_destroyed() -> void:
	calls.append("destroyed")
"""

var main: Node
var frame := 0
var _wait := 0
var _fails: Array[String] = []
var _spy_building: Node
var _spy: Node
var _spy_freed_check := -1
var _guard: Node
var _target: Node


func _initialize() -> void:
	main = load("res://scenes/skirmish.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	# Screenshot mode (windowed): -- shots=<folder> saves the skirmish start and quits.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			if frame == 120:
				root.get_texture().get_image().save_png("%s/skirmish_start.png" % arg.substr(6))
				print("SHOT saved")
				return true
			return false
	if frame == 10:
		_check_models()
		_setup_spy()
		_setup_xp()
		_check_skirmish_fixes()
	if frame == 12:
		_check_spy_damage()
		_check_node_of()
	if frame == 20:
		_check_xp()
		_spy_building.call(&"take_damage", 1.0e6, _guard)
		var calls: Array = _spy.get(&"calls")
		if not calls.has("destroyed"):
			_fails.append("play_destroyed not called (calls %s)" % [calls])
		_spy.emit_signal(&"destroyed_finished")
		_spy_freed_check = frame + 2
	if frame == _spy_freed_check:
		if is_instance_valid(_spy_building) and not _spy_building.is_queued_for_deletion():
			_fails.append("building not freed after destroyed_finished")
		_finish()
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _check_models() -> void:
	for k in [main.keep, main.shadow_keep]:
		var model: Node3D = k.get(&"_model")
		if model == null or not model.is_inside_tree():
			_fails.append("%s has no model child" % k.name)
			continue
		if model.get_parent() != k.get(&"_visual"):
			_fails.append("%s model not under the visual" % k.name)
		if (k.get(&"_mats") as Array).size() > 0:
			_fails.append("%s still built its placeholder shapes" % k.name)
		if not model.has_method(&"set_health_ratio"):
			_fails.append("%s model has no set_health_ratio" % k.name)
	var fire_model: Node3D = main.keep.get(&"_model")
	if fire_model and absf(fire_model.rotation.y + PI / 2.0) > 0.01:
		_fails.append("Fire keep model yaw %.2f, expected -PI/2" % fire_model.rotation.y)
	var gate := fire_model.find_child("GateLight", true, false) as Node3D if fire_model else null
	if gate:
		print("fire gate light offset from keep: ", gate.global_position - main.keep.global_position)
	var dusk_model: Node3D = main.shadow_keep.get(&"_model")
	if dusk_model and absf(dusk_model.rotation.y - PI / 2.0) > 0.01:
		_fails.append("Dusk keep model yaw %.2f, expected +PI/2" % dusk_model.rotation.y)


func _setup_spy() -> void:
	var script := GDScript.new()
	script.source_code = SPY_SRC
	script.reload()
	var spy_root := Node3D.new()
	spy_root.set_script(script)
	var packed := PackedScene.new()
	packed.pack(spy_root)
	spy_root.free()
	var type: Resource = load("res://scripts/buildings/building_type.gd").call(&"find", "shadow_barracks")
	var bg = main.build_grid
	var b = bg.create_building(type)
	b.model_scene = packed
	b.team = 1
	b.position = Vector3(20.0, 0.0, -20.0)
	main.nav_region.add_child(b)
	_spy_building = b
	_spy = b.get(&"_model")
	if _spy == null:
		_fails.append("spy model not instanced")
		return
	b.call(&"set_selected", true)
	b.call(&"set_selected", false)
	b.call(&"queue_unit", type.trains[0])   # may be refused (crystals), the pulse is forced below
	b.call(&"_spawn", type.trains[0])


func _check_spy_damage() -> void:
	if _spy == null:
		return
	var b = _spy_building
	b.call(&"take_damage", 100.0, null)
	var ratio: float = _spy.get(&"last_ratio")
	if absf(ratio - b.hp / b.max_hp) > 0.001:
		_fails.append("damage: set_health_ratio got %.3f, hp ratio %.3f" % [ratio, b.hp / b.max_hp])
	b.call(&"heal", 50.0)
	ratio = _spy.get(&"last_ratio")
	if absf(ratio - b.hp / b.max_hp) > 0.001:
		_fails.append("heal: set_health_ratio got %.3f" % ratio)
	var calls: Array = _spy.get(&"calls")
	for c in ["team", "progress", "health", "selected_true", "selected_false", "pulse"]:
		if not calls.has(c):
			_fails.append("hook %s not called (calls %s)" % [c, calls])


func _setup_xp() -> void:
	_guard = main.make_unit("flame_guard")
	main._spawn(_guard, 0, Vector3(-20.0, 0.0, 20.0))
	var type: Resource = load("res://scripts/buildings/building_type.gd").call(&"find", "shadow_hovel")
	_target = main.build_grid.spawn_complete(type, Vector3(-16.0, 0.0, 22.0), 1)


func _check_xp() -> void:
	var before_xp: int = _guard.xp
	var before_lvl: int = _guard.level
	_target.call(&"take_damage", 1.0e6, _guard)
	if _guard.xp == before_xp and _guard.level == before_lvl:
		_fails.append("Flame Guard got no XP for the hovel (xp %d level %d)" % [_guard.xp, _guard.level])


func _check_skirmish_fixes() -> void:
	# node_of on a freed node: must return null without an error.
	var n = main.crystal_nodes.get(&"node_shadow_mid")
	if n:
		n.queue_free()   # checked in _check_node_of, after the free
	# wardens: a dead one leaves the list.
	var count: int = main.wardens.size()
	if count > 0:
		var w = main.wardens[0]
		w.take_damage(1.0e6, main.hero)
		if main.wardens.size() != count - 1 or main.wardens.has(w):
			_fails.append("dead warden still in wardens")
	# Hovel slot V1.
	var hovel: Resource = load("res://scripts/buildings/building_type.gd").call(&"find", "shadow_hovel")
	var reason: String = main.build_grid.check(hovel, Vector3(50.0, 0.0, -46.0), 1)
	if reason != "":
		_fails.append("Hovel slot V1 (50, -46): %s" % reason)
	var fire_hearth: Resource = load("res://scripts/buildings/building_type.gd").call(&"find", "fire_hearth")
	reason = main.build_grid.check(fire_hearth, Vector3(-50.0, 0.0, 46.0), 0)
	if reason != "":
		_fails.append("Hearth mirror slot (-50, 46): %s" % reason)


func _check_node_of() -> void:
	if main.node_of(1, "mid") != null:
		_fails.append("node_of returned a freed node")
	if main.natural_node(1) != null or main.home_nodes(1).size() != 2:
		_fails.append("natural_node / home_nodes wrong after a node was freed")


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  - " + f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _fails.size()])
