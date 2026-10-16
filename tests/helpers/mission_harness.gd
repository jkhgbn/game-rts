class_name MissionHarness
extends RefCounted
## Headless mission test helper (docs/design/mission-framework.md "Testing a mission"). A mission acceptance test is
## a SceneTree script that builds the mission with `open`, waits for `is_ready`, then feeds a step list to `Steps`:
##
##   var h := MissionHarness.new()
##   func _initialize() -> void:
##       main = h.open(self, "res://missions/mission_02.tscn", {"difficulty": 1})
##       h.steps.add("free Pell", func() -> bool: ..., 600)        # true = step done; frames before a timeout
##   func _process(_d: float) -> bool:
##       return h.tick()                                           # prints PASS / FAIL <task id> at the end
##
## `open` turns the briefing, the campaign save and cinematics off (skip end states run at once) and records
## Events.objective_changed / dialogue / mission_ended. Never write `Events` in a test (autoloads compile later): the
## harness reaches it through the root.

const _REPLAY := preload("res://scripts/core/replay/replay_hooks.gd")
const _SESSION := preload("res://scripts/core/replay/replay_session.gd")
const DEFAULT_SEED := 1   ## the run's seed when the command line has no `-- --seed N`

var task_id := "mission"
var main: Node
var steps := Steps.new()
var errors: Array[String] = []
var objective_log: Array[String] = []     ## "id=state" in emission order
var dialogue_log: Array[String] = []      ## "speaker: text"
var spotlight_log: Array[String] = []     ## spotlight ids shown (Events.spotlight_shown), in order
var ended := -1                           ## -1 running, 0 defeat, 1 victory
var protect_hero := true                  ## heal the player's hero every frame (scripted runs)
var nav_timeout_frames := 5000
var timeout_frames := 20000
var frame := 0
var _wait := 0
var _nav_synced := false
var _seed := DEFAULT_SEED
var _rng_count := 0
var _tree: SceneTree


## Instantiates the mission (a scene path, a Script or a Node) with the test switches and adds it as the current
## scene. Options: "difficulty" (0-2), "config" (MissionConfig), "set" ({property: value} before the tree), "task_id".
func open(tree: SceneTree, mission: Variant, options: Dictionary = {}) -> Node:
	_tree = tree
	task_id = String(options.get("task_id", task_id))
	var ev := tree.root.get_node_or_null("Events")
	if ev:
		ev.objective_changed.connect(func(id: StringName, state: StringName) -> void:
			objective_log.append("%s=%s" % [id, state]))
		ev.mission_ended.connect(func(victory: bool) -> void: ended = 1 if victory else 0)
		if ev.has_signal(&"dialogue"):
			ev.connect(&"dialogue", func(speaker: StringName, text: String) -> void:
				dialogue_log.append("%s: %s" % [speaker, text]))
		if ev.has_signal(&"spotlight_shown"):
			ev.connect(&"spotlight_shown", func(id: StringName, _card: String) -> void:
				spotlight_log.append(String(id)))
	if mission is String:
		main = (load(mission) as PackedScene).instantiate()
	elif mission is Script:
		main = (mission as Script).new()
	else:
		main = mission as Node
	main.set(&"show_briefing", false)
	main.set(&"save_campaign_on_victory", false)
	main.set(&"cinematics_enabled", false)
	if options.has("difficulty"):
		main.set(&"mission_difficulty", int(options["difficulty"]))
	var extra: Dictionary = options.get("set", {})
	if options.has("config"):
		# MissionBase._ready re-copies the switches of a new config onto the node: a "set" value for a config field
		# (casters_enabled, t3_enabled...) goes into a copy of the config too, so "set" always wins over "config".
		var c := (options["config"] as Resource).duplicate() as Resource
		for k: Variant in extra:
			if StringName(str(k)) in c:
				c.set(StringName(str(k)), extra[k])
		main.set(&"config", c)
	for k: Variant in extra:
		main.set(StringName(str(k)), extra[k])
	# Same run whatever the CPU load (root-cause pass 2026-10-16): navmeshes bake on the main thread (the game bakes on a
	# thread, so a new navmesh landed after a wall-clock delay) and the nav map applies them at once (no async
	# iterations). The Replay Lab's deterministic mode; set before the level bakes its first navmesh and before the map's
	# first sync (switching async off while an async iteration is in flight leaves the map without paths for good).
	_REPLAY.bake_mode = _REPLAY.BAKE_SYNC
	# Same seeds every run (Godot randomizes the global RNG at launch, and RNG nodes randomize in _ready): the global
	# RNG and, after each node's _ready, its RNG fields, like the Replay Lab's session.
	var args := OS.get_cmdline_user_args()
	var si := args.find("--seed")
	_seed = int(args[si + 1]) if si >= 0 and si + 1 < args.size() else DEFAULT_SEED
	seed(_seed)
	tree.node_added.connect(_on_node_added)
	var map := tree.root.get_world_3d().navigation_map
	if map.is_valid():
		NavigationServer3D.map_set_use_async_iterations(map, false)
	tree.root.add_child(main)
	tree.current_scene = main
	sync_nav_map(main)
	return main


## Turns the async iterations of the level's nav map and regions off (paths see a rebake on the next map sync, not
## after a thread's delay). `open` calls it before the map's first sync (later, it can leave the map without paths). The
## server applies the switch on its next sync: true only once the map reports it off, so `tick` calls it every frame
## until then and the steps start after it.
static func sync_nav_map(level: Node) -> bool:
	var region: Variant = level.get(&"nav_region") if level != null else null
	if not region is NavigationRegion3D or not (region as NavigationRegion3D).is_inside_tree():
		return false
	var map := (region as NavigationRegion3D).get_world_3d().navigation_map
	if not map.is_valid():
		return false
	var done := not NavigationServer3D.map_get_use_async_iterations(map)
	NavigationServer3D.map_set_use_async_iterations(map, false)
	for r in level.find_children("*", "NavigationRegion3D", true, false):
		var rid := (r as NavigationRegion3D).get_rid()
		done = done and not NavigationServer3D.region_get_use_async_iterations(rid)
		NavigationServer3D.region_set_use_async_iterations(rid, false)
	return done


func _on_node_added(node: Node) -> void:
	var cb := _seed_rngs.bind(node)
	if node.get_script() != null and not node.is_connected(&"ready", cb):   # by name: some scripts have a ready()
		node.connect(&"ready", cb, CONNECT_ONE_SHOT)


func _seed_rngs(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for key in _SESSION.RNG_FIELDS:
		if key in node and node.get(key) is RandomNumberGenerator:
			_rng_count += 1
			(node.get(key) as RandomNumberGenerator).seed = hash([_seed, _rng_count, String(key)])


## True once the navmesh is baked, the hero exists and the match clock runs.
func is_ready() -> bool:
	return main != null and main.get(&"hero") != null and bool(main.get(&"match_started"))


## One frame: waits for the map and the nav map sync switch, keeps the hero alive (protect_hero), runs the steps,
## prints the verdict. Returns true when the test is over (return it from _process).
func tick() -> bool:
	if not _nav_synced:
		_nav_synced = sync_nav_map(main)
	if not _nav_synced or not is_ready():
		_wait += 1
		if _wait > nav_timeout_frames:
			print("FAIL %s: navigation never finished baking" % task_id)
			return true
		return false
	frame += 1
	if steps.size() == 0:   # a test with nothing to check must not print PASS
		errors.append("no steps: the test checks nothing")
		finish()
		return true
	var hero: Node = main.get(&"hero")
	if protect_hero and is_instance_valid(hero) and hero.call(&"is_alive"):
		hero.call(&"heal", 1.0e6)
	var done := steps.tick(self)
	if done or frame > timeout_frames:
		if not done:
			errors.append("timed out at step '%s'" % steps.current_name())
		errors.append_array(steps.errors)
		finish()
		return true
	return false


func finish() -> void:
	if errors.is_empty():
		print("PASS %s" % task_id)
	else:
		print("FAIL %s: %s" % [task_id, "; ".join(errors)])


func check(cond: bool, what: String) -> bool:
	if not cond:
		errors.append(what)
		print("  x ", what)
	return cond


# ---------------------------------------------------------------- world helpers

## Kills every living unit / building of `nodes` at once.
static func kill(nodes: Array) -> void:
	for n: Variant in nodes:
		if is_instance_valid(n) and (n as Node).call(&"is_alive"):
			(n as Node).call(&"take_damage", 1.0e7, null)


## Teleports `unit` to `at` and stops it there.
static func put(unit: Node3D, at: Vector3) -> void:
	unit.global_position = at
	unit.call(&"command_stop")


## Makes `unit` unkillable (hp back to full on a killing blow).
static func immortal(unit: Node) -> void:
	unit.set(&"death_guard", func(_a: Variant) -> bool:
		unit.set(&"hp", unit.get(&"max_hp"))
		return true)


## Moves the match clock forward by `seconds` (timers fire on the next frames; mission_time follows).
static func skip_time(mission: Node, seconds: float) -> void:
	mission.set(&"_match_time", float(mission.get(&"_match_time")) + seconds)


## True once Events.objective_changed sent `id` = `state`.
func saw(id: String, state: String) -> bool:
	return objective_log.has("%s=%s" % [id, state])


## True once the mission showed the spotlight card of `id` (Events.spotlight_shown).
func saw_spotlight(id: String) -> bool:
	return spotlight_log.has(id)


## A step list: each step is [name, Callable() -> bool (true = done), max frames]. Steps run in order, one per frame
## until done; a step that times out records an error and stops the run.
class Steps:
	var errors: Array[String] = []
	var _list: Array = []
	var _i := 0
	var _frames := 0

	func add(step_name: String, step: Callable, max_frames: int = 1200) -> void:
		_list.append([step_name, step, max_frames])

	func size() -> int:
		return _list.size()

	func current_name() -> String:
		return String(_list[_i][0]) if _i < _list.size() else "done"

	## True when every step is done or one timed out.
	func tick(_h: Object) -> bool:
		if _i >= _list.size():
			return true
		_frames += 1
		var row: Array = _list[_i]
		if bool((row[1] as Callable).call()):
			_i += 1
			_frames = 0
			return _i >= _list.size()
		if _frames > int(row[2]):
			errors.append("step '%s' timed out" % row[0])
			return true
		return false
