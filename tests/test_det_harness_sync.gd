extends SceneTree
## Determinism guard (root-cause pass 2026-10-16, follow-up of test_det_model_pose): a mission sim must give the same
## run whatever the CPU load. The game bakes navmeshes on a thread and the nav map applies them with async iterations,
## so a rebake reached path queries after a wall-clock delay: e2m2 / e7m4 passed or failed depending on how many Godots
## ran at once. MissionHarness.open uses the Replay Lab's deterministic mode; this checks that it still does:
## BAKE_SYNC before the first bake, map and region async iterations off (set before the map's first sync, so it still
## gives paths), a rebake done in the same frame.
## Run:  godot --headless --path . -s tests/test_det_harness_sync.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "det_harness_sync"
const MISSION := "res://missions/mission_01.tscn"
const _REPLAY := preload("res://scripts/core/replay/replay_hooks.gd")

var h := MissionHarness.new()
var main: Node


func _initialize() -> void:
	h.task_id = TASK_ID
	main = h.open(self, MISSION, {"difficulty": 1})
	h.steps.add("sync mode", _check, 10)


func _process(_delta: float) -> bool:
	return h.tick()


func _check() -> bool:
	if _REPLAY.bake_mode != _REPLAY.BAKE_SYNC:
		h.errors.append("ReplayHooks.bake_mode is %d, not BAKE_SYNC: navmeshes bake on a thread" % _REPLAY.bake_mode)
	var region := main.get(&"nav_region") as NavigationRegion3D
	if region == null:
		h.errors.append("the mission has no nav_region")
		return true
	var map := region.get_world_3d().navigation_map
	if NavigationServer3D.map_get_use_async_iterations(map):
		h.errors.append("the nav map uses async iterations (a rebake lands after a wall-clock delay)")
	# Switching async off while the map's first async iteration was in flight left it at iteration 0: no path, no unit
	# ever moved (every sim lost).
	var hero := main.get(&"hero") as Node3D
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		h.errors.append("the nav map never synced (iteration 0)")
	elif hero and NavigationServer3D.map_get_path(map, hero.global_position, hero.global_position + Vector3.RIGHT * 6.0,
			true).is_empty():
		h.errors.append("the nav map gives no path next to the hero")
	for r in main.find_children("*", "NavigationRegion3D", true, false):
		if NavigationServer3D.region_get_use_async_iterations((r as NavigationRegion3D).get_rid()):
			h.errors.append("region %s uses async iterations" % r.name)
	var grid: Object = main.get(&"build_grid")
	if grid == null:
		h.errors.append("the mission has no build_grid")
		return true
	grid.call(&"request_rebake")
	if bool(grid.call(&"is_rebaking")):
		h.errors.append("a rebake is still running after request_rebake (threaded bake)")
	return true
