extends SceneTree
## Forge model fallback (G-B Ice handoff 2026-10-15): Building._ready takes BuildingType.get_model_scene() (model_scene,
## else model_path once the file exists), so an Ice Forge built in a skirmish carries the FrostForgeModel, and a Forge
## of a kingdom without a model file (Fire) keeps the placeholder shapes. The Bazaar still finds its model.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_forge_model.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "forge_model"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0
const ENEMY := 1

var main: Node
var _errors: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_errors.append(what)
		print("  x " + what)


func _run() -> void:
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", &"ice")
	main.set(&"enemy_kingdom", &"fire")
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_ok(false, "the skirmish never started")
			_finish()
			return
	for i in 5:
		await process_frame
	_check()
	_finish()


func _check() -> void:
	var grid: BuildGrid = main.get(&"build_grid")
	var ice := _spawn(grid, ForgeKit.forge_type(&"ice"), _keep_of(PLAYER), PLAYER)
	var fire := _spawn(grid, ForgeKit.forge_type(&"fire"), _keep_of(ENEMY), ENEMY)
	_ok(ice is ForgeBuilding, "Ice Forge spawned as a ForgeBuilding")
	_ok(fire is ForgeBuilding, "Fire Forge spawned as a ForgeBuilding")
	if ice:
		_ok(ice.model() is FrostForgeModel, "Ice Forge model is FrostForgeModel (got %s)" % ice.model())
		var found := false
		for c in ice.find_children("*", "Node3D", true, false):
			if c is FrostForgeModel:
				found = true
		_ok(found, "FrostForgeModel is under the Ice Forge")
	if fire:
		var path := fire.building_type.model_path
		if path == "" or not ResourceLoader.exists(path):
			_ok(fire.model() == null, "Fire Forge (no model file) keeps the placeholder")
		else:
			_ok(fire.model() != null, "Fire Forge model file exists and is shown")
	var market := BuildingType.find("ice_market")
	_ok(market != null and market.get_model_scene() != null, "ice_market still finds its model")


func _keep_of(team: int) -> Node3D:
	for b in main.get_tree().get_nodes_in_group("buildings"):
		if b is Keep and int(b.team) == team:
			return b as Node3D
	return null


func _spawn(grid: BuildGrid, type: BuildingType, keep: Node3D, team: int) -> Building:
	if type == null or keep == null or grid == null:
		return null
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + dir * 14.0 + Vector3(dir.z, 0, -dir.x) * -10.0, team)
	return grid.spawn_complete(type, spot, team) if spot != Vector3.INF else null


func _finish() -> void:
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _checks])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit(0 if _errors.is_empty() else 1)
