extends SceneTree
## Code review batch F4 (UI, docs/handoff/fix-batches-2026-10-12.md): the testable fixes.
## - U5-1: the campaign mission list sits in a height-capped ScrollContainer (Back / Start stay on a 900 p screen).
## - U1-1: the wizard stays in her control groups while dead and is back in them after respawn.
## - U1-2: F2 (army) skips caravans.
## - U1-4: Ctrl+N / Alt+N with nothing selected keep the group.
## - U1-3: Shift-placed sites are split between the selected workers (one each, then a queue).
## - W1-3: MenuFlow.set_loaded_match(props) re-applies a loaded save's props, cleared by a new start.
## - U2-2: SpellInfo.cast_reason says "Frozen" right after "Dead".
## Run:  godot --headless --path . -s tests/test_f4_ui.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "f4_ui"
const TIMEOUT_FRAMES := 900

var main: Node
var sel: SelectionManager
var menu: Node
var frame := 0
var _wait := 0
var _error := ""
var _done := false
var _army: Array = []
var _workers: Array = []
var _sites: Array = []


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	_step()
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if _done:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _fail(text: String) -> void:
	if _error == "":
		_error = text


func _step() -> void:
	match frame:
		1:
			root.size = Vector2i(1600, 900)
			sel = main.selection
			main.camera_rig.edge_pan_enabled = false
			for u in root.get_tree().get_nodes_in_group("units"):
				if u.team != 0 or u.is_in_group("heroes"):
					continue
				if u.has_method("command_gather"):
					_workers.append(u)
				else:
					_army.append(u)
			if _army.size() < 2 or _workers.size() < 2:
				_fail("expected an army and workers, got %d / %d" % [_army.size(), _workers.size()])
				return
			_check_loaded_match()
			_check_frozen_reason()
			_check_empty_group_keys()
			_check_f2_caravans()
		3:
			_kill_hero_in_group()
		10:
			_check_dead_hero_kept()
		12:
			_check_respawned_hero()
		14:
			_place_split()
		20:
			_check_split()
		22:
			menu = load("res://scenes/ui/main_menu.tscn").instantiate()
			root.add_child(menu)
		24:
			menu.call(&"show_campaign")
		28:
			_check_campaign_scroll()
			menu.queue_free()
			_done = _error == ""


# ---------------------------------------------------------------- W1-3

func _check_loaded_match() -> void:
	MenuFlow.clear_loaded_match()
	var level: Node = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	if MenuFlow.apply_loaded_match(level):
		_fail("apply_loaded_match did something with no loaded match")
	MenuFlow.set_loaded_match({"trade_enabled": false, "enemy_kingdom": &"ice", "time_limit_s": 1800.0,
			"not_a_prop": 3})
	var d := MenuFlow.loaded_match()
	if not MenuFlow.apply_loaded_match(level) or d.size() != 4:
		_fail("set_loaded_match / apply_loaded_match: %s" % [d])
	elif bool(level.get(&"trade_enabled")) or level.get(&"enemy_kingdom") != &"ice" \
			or not is_equal_approx(float(level.get(&"time_limit_s")), 1800.0):
		_fail("loaded props not applied: trade %s enemy %s limit %s" % [level.get(&"trade_enabled"),
				level.get(&"enemy_kingdom"), level.get(&"time_limit_s")])
	MenuFlow.clear_loaded_match()
	if not MenuFlow.loaded_match().is_empty():
		_fail("clear_loaded_match kept the props")
	level.free()


# ---------------------------------------------------------------- U2-2

func _check_frozen_reason() -> void:
	var hero: Node = main.hero
	var ids := SpellInfo.ids(hero)
	if ids.is_empty():
		_fail("the hero has no spells")
		return
	if hero.has_method(&"apply_status"):
		hero.call(&"apply_status", &"frozen", 2.0)
	if hero.has_method(&"can_act") and not bool(hero.call(&"can_act")):
		var r := SpellInfo.cast_reason(hero, ids[0])
		if r != "Frozen":
			_fail("a frozen wizard's cast_reason is '%s', not 'Frozen'" % r)
	if hero.has_method(&"clear_status"):
		hero.call(&"clear_status", &"frozen")


# ---------------------------------------------------------------- U1-4

func _check_empty_group_keys() -> void:
	sel.select_units([_army[0], _army[1]])
	sel.set_control_group(1)
	sel.select_units([])
	sel.set_control_group(1)
	if sel.get_control_group(1).size() != 2:
		_fail("Ctrl+1 with nothing selected changed group 1 (%d members)" % sel.get_control_group(1).size())
	sel.steal_to_control_group(1)
	sel.steal_to_control_group(2)
	if sel.get_control_group(1).size() != 2 or not sel.get_control_group(2).is_empty():
		_fail("Alt+N with nothing selected changed the groups")


# ---------------------------------------------------------------- U1-2

func _check_f2_caravans() -> void:
	var fake: Node = _army[1]
	fake.add_to_group(&"caravans")
	var army := sel.army_units()
	fake.remove_from_group(&"caravans")
	if army.has(fake):
		_fail("F2's army holds a caravan")
	elif not army.has(_army[0]):
		_fail("F2's army lost a soldier")


# ---------------------------------------------------------------- U1-1

func _kill_hero_in_group() -> void:
	sel.select_units([main.hero, _army[0]])
	sel.set_control_group(3)
	if not sel.get_control_group(3).has(main.hero):
		_fail("the hero is not in group 3")
		return
	main.hero.die()


func _check_dead_hero_kept() -> void:
	if main.hero.is_alive():
		_fail("the hero did not die")
		return
	var living := sel.get_control_group(3)
	if living.has(main.hero):
		_fail("a dead hero is listed as a living group member")
	sel.recall_control_group(3)
	if sel.selected.has(main.hero):
		_fail("recalling the group selected the dead hero")
	# Shift+3 while she is dead: the group grows, she stays in it
	sel.select_units([_army[1]])
	sel.add_to_control_group(3)
	main.hero.respawn(main.hero.global_position)


func _check_respawned_hero() -> void:
	if not main.hero.is_alive():
		_fail("the hero did not respawn")
		return
	if not sel.get_control_group(3).has(main.hero):
		_fail("U1-1: the respawned hero is not back in group 3 (Shift+3 while dead dropped her?)")
	elif not sel.get_control_group(3).has(_army[1]):
		_fail("Shift+3 while the hero was dead did not add the unit")


# ---------------------------------------------------------------- U1-3

func _place_split() -> void:
	var eco := Economy.for_team(0)
	if eco:
		eco.add(5000)
	var w: Array = [_workers[0], _workers[1]]
	sel.select_units(w)
	var types := sel.buildable_types()
	if types.is_empty():
		_fail("no buildable type for the workers")
		return
	var type: BuildingType = types[0]
	for t in types:
		if t.footprint.x * t.footprint.y < type.footprint.x * type.footprint.y:
			type = t
	var grid: BuildGrid = main.build_grid
	var keep := sel.own_keep()
	var near: Vector3 = keep.global_position if keep else main.hero.global_position
	sel.begin_placement(type)
	for i in 4:
		var spot := grid.find_spot(type, near + Vector3(6.0 * i, 0.0, 10.0), 0)
		if spot == Vector3.INF:
			_fail("no spot for site %d" % i)
			return
		var site := sel.place_building_at(spot, true)
		if site == null:
			_fail("site %d not placed (%s)" % [i, grid.last_reason])
			return
		_sites.append(site)
	sel.cancel_targeting()


func _check_split() -> void:
	if _sites.size() != 4:
		return
	var w0: Node = _workers[0]
	var w1: Node = _workers[1]
	var b0: Variant = w0.get(&"build_site")
	var b1: Variant = w1.get(&"build_site")
	if b0 == null or b1 == null or b0 == b1:
		_fail("U1-3: the two workers do not build two different sites (%s / %s)" % [b0, b1])
		return
	if not (_sites.has(b0) and _sites.has(b1)):
		_fail("U1-3: a worker builds something else")
		return
	# sites 3 and 4: one queued to each worker (shortest queue first)
	var q0 := sel.build_queue_of(w0 as Unit)
	var q1 := sel.build_queue_of(w1 as Unit)
	if q0.size() != 1 or q1.size() != 1:
		_fail("U1-3: queues %d / %d, want 1 / 1" % [q0.size(), q1.size()])
		return
	var owner: Node = w0
	var third: Node = q0[0]
	# The other worker is re-ordered by the player (a move): its queue is dropped.
	(w1 as Unit).command_move((w1 as Node3D).global_position + Vector3(3.0, 0.0, 0.0))
	sel.advance_build_queues()
	if not sel.build_queue_of(w1 as Unit).is_empty():
		_fail("U1-3: a re-ordered worker kept its build queue")
	# Its current site goes away (cancelled): the worker moves on to the queued one.
	var cur: Node = owner.get(&"build_site")
	cur.call(&"cancel_construction")
	sel.advance_build_queues()
	if owner.get(&"build_site") != third:
		_fail("U1-3: the queued site was not started when the worker's site was gone")


# ---------------------------------------------------------------- U5-1

func _check_campaign_scroll() -> void:
	var scroll: ScrollContainer = menu.get(&"campaign_list_scroll")
	if scroll == null:
		_fail("U5-1: no campaign_list_scroll")
		return
	var buttons: Array = menu.get(&"mission_buttons")
	if buttons.is_empty() or not scroll.is_ancestor_of(buttons[0]):
		_fail("U5-1: the mission buttons are not in the scroll box")
		return
	var col: Control = menu.get(&"menu_column")
	var need := col.get_combined_minimum_size().y
	if need > 900.0:
		_fail("U5-1: the menu needs %d px at 900 p (Back / Start off screen)" % roundi(need))
	if scroll.custom_minimum_size.y >= float(buttons.size()) * 44.0:
		_fail("U5-1: the list is not capped (%d px for %d missions)" % [roundi(scroll.custom_minimum_size.y),
				buttons.size()])
