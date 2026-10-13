extends SceneTree
## Playtest request 2026-09-27 (JS): select-all / all-army / idle-worker keys + Tab unit subgroups + unit priority.
## Ctrl+A = every own commandable unit (Ctrl+3 then stores them), F2 = army, Shift+F2 adds it, F3 / Ctrl+F3 = next / all
## idle workers, the HUD idle-worker button (count badge, hidden at 0), Tab / Shift+Tab = active unit type (command
## card + gold portraits follow), GameSettings unit priority (+ / - / reset) decides the Tab order.
## Run:  godot --headless --path . -s tests/test_ui_select_hotkeys.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "ui_select_hotkeys"
const TIMEOUT_FRAMES := 5000

var main: Node
var frame := 0
var step := 0
var _wait := 0
var _workers: Array[Unit] = []
var _hounds: Array[Unit] = []
var _weaver: Unit


func _initialize() -> void:
	main = MenuFlow.start_skirmish(self, 0, &"shadow", &"fire")


func _process(_delta: float) -> bool:
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	var sel: SelectionManager = main.get("selection") if main != null else null
	match step:
		0:
			_wait += 1
			if main == null or main.get("hero") == null or main.get("keep") == null or _wait < 30:
				return _wait > 3000 and _finish("skirmish never started")
			GameSettings.reset_unit_priority(false)
			var at: Vector3 = (main.get("keep") as Node3D).global_position
			for i in 2:
				_workers.append(_spawn("gloom_thrall", at + Vector3(-10 - i * 2, 0, 8)))
				_hounds.append(_spawn("grave_hound", at + Vector3(8, 0, 8 + i * 2)))
			_weaver = _spawn("hexweaver", at + Vector3(10, 0, 12))
			_wait = 0
			step = 1
		1:
			_wait += 1
			if _wait < 20:
				return false
			var hero: Unit = main.get("hero")
			# Ctrl+A: every own commandable unit (workers + the wizard), no building; Ctrl+3 stores them all.
			sel.select_building(main.get("keep"))
			_key(KEY_A, false, true)
			var all := sel.all_own_units()
			if sel.selected.size() != all.size() or not sel.selected.has(hero) or not sel.selected.has(_workers[0]):
				return _finish("Ctrl+A selected %d of %d units" % [sel.selected.size(), all.size()])
			if sel.selected_building != null or not sel.selected_buildings.is_empty():
				return _finish("Ctrl+A kept a building selected")
			if sel.get_pending_order() != &"":
				return _finish("Ctrl+A started attack-move targeting")
			_key(KEY_3, false, true)
			if sel.get_control_group(3).size() != all.size():
				return _finish("Ctrl+3 after Ctrl+A stored %d" % sel.get_control_group(3).size())
			# F2 = army (no worker); Shift+F2 adds the army to a worker.
			_key(KEY_F2)
			if sel.selected.has(_workers[0]) or not sel.selected.has(hero) or not sel.selected.has(_weaver):
				return _finish("F2 army wrong (%d)" % sel.selected.size())
			sel.select_units([_workers[0]])
			_key(KEY_F2, true)
			if not sel.selected.has(_workers[0]) or not sel.selected.has(_hounds[1]) or not sel.selected.has(hero):
				return _finish("Shift+F2 did not add the army")
			# Idle workers: Ctrl+F3 = all, F3 = one; the HUD button counts them.
			var idle := sel.idle_workers()
			if not idle.has(_workers[0]) or not idle.has(_workers[1]):
				return _finish("spawned workers not idle (%d idle)" % idle.size())
			_key(KEY_F3, false, true)
			if sel.selected.size() != idle.size() or not sel.selected.all(func(u): return idle.has(u)):
				return _finish("Ctrl+F3 selected %d of %d idle" % [sel.selected.size(), idle.size()])
			_key(KEY_F3)
			if sel.selected.size() != 1 or not idle.has(sel.selected[0]):
				return _finish("F3 did not select one idle worker")
			var btn: IdleWorkerButton = main.get("hud").idle_worker_button
			btn.refresh()
			if not btn.visible or btn.count_badge.text != str(idle.size()):
				return _finish("idle button shows '%s' (visible %s), expected %d" % [btn.count_badge.text, btn.visible,
						idle.size()])
			btn.activate(true)
			if sel.selected.size() != idle.size():
				return _finish("idle button Ctrl+click selected %d" % sel.selected.size())
			print("  Ctrl+A %d units, army ok, %d idle workers, button badge %s" % [all.size(), idle.size(),
					btn.count_badge.text])
			_wait = 0
			step = 2
		2:
			# Tab subgroups: wizard first by default, then the dearer soldier, then the cheaper one.
			var hero: Unit = main.get("hero")
			sel.select_units([_hounds[0], hero, _weaver, _hounds[1]])
			var types := sel.selected_unit_types()
			if types.size() != 3 or types[0] != &"wizard":
				return _finish("subgroup order %s" % [types])
			if sel.active_unit_type() != &"wizard":
				return _finish("active type %s, not the wizard" % sel.active_unit_type())
			var card: CommandCard = main.get("hud").command_card
			card.refresh()
			var wizard_ids := card.slot_ids()
			_key(KEY_TAB)
			if sel.active_unit_type() != types[1]:
				return _finish("Tab did not move to %s" % types[1])
			card.refresh()
			if card.slot_ids() == wizard_ids:
				return _finish("command card did not follow the active type")
			if sel.active_type_units().has(hero):
				return _finish("active type units still hold the wizard")
			var panel: SelectionPanel = main.get("hud").selection_panel
			panel.refresh()
			var gold := 0
			# SC2.U4 (ui-sc2-console.md 4.2): the active type's tab is gold, its icons bright, the other types' dimmed.
			if panel.active_type_tab() != types[1]:
				return _finish("gold type tab is '%s', expected %s" % [panel.active_type_tab(), types[1]])
			for i in panel._icon_units.size():
				if panel.icon_is_active(i):
					gold += 1
					if SelectionManager.unit_type_key(panel._icon_units[i]) != types[1]:
						return _finish("bright icon of a unit of another type")
			if gold != sel.active_type_units().size():
				return _finish("%d bright icons, expected %d" % [gold, sel.active_type_units().size()])
			_key(KEY_TAB, true)
			if sel.active_unit_type() != &"wizard":
				return _finish("Shift+Tab did not go back to the wizard")
			_key(KEY_TAB, true)
			if sel.active_unit_type() != types[2]:
				return _finish("Shift+Tab did not wrap to the last type")
			# Unit priority: put the hound first, then "+" the wizard back above it; Reset.
			var hound_id := SelectionManager.unit_type_key(_hounds[0])
			GameSettings.set_unit_priority([hound_id, &"wizard"], false)
			sel.select_units([hero, _hounds[0], _weaver])
			if sel.active_unit_type() != hound_id:
				return _finish("priority: active %s, not %s" % [sel.active_unit_type(), hound_id])
			var order := GameSettings.move_unit_priority(GameSettings.unit_priority(), &"wizard", -1, false)
			if order[0] != &"wizard":
				return _finish("'+' did not move the wizard up (%s)" % [order])
			sel.select_units([hero, _hounds[0], _weaver])
			if sel.active_unit_type() != &"wizard":
				return _finish("priority change not used")
			GameSettings.reset_unit_priority(false)
			if not GameSettings.unit_priority().is_empty():
				return _finish("reset kept a custom order")
			# Settings > Unit priority list: wizard first, workers last by default; a saved order moves rows.
			var rows := SettingsPanel.priority_order(&"shadow")
			if rows.is_empty() or rows[0] != &"wizard" or rows[rows.size() - 1] != &"gloom_thrall":
				return _finish("default priority rows %s" % [rows])
			GameSettings.set_unit_priority([&"grave_hound"], false)
			if SettingsPanel.priority_order(&"shadow")[0] != &"grave_hound":
				return _finish("saved order not first in the settings list")
			var sp := SettingsPanel.new()
			root.add_child(sp)
			sp.priority_kingdom.select(1)
			sp.rebuild_priority_list()
			var shown := sp.priority_list.get_children().filter(func(c): return not c.is_queued_for_deletion())
			if shown.size() != rows.size():
				return _finish("settings list shows %d rows, expected %d" % [shown.size(), rows.size()])
			sp.queue_free()
			GameSettings.reset_unit_priority(false)
			print("  settings rows (shadow): %s" % [rows])
			print("  Tab types %s, card follows, %d gold portraits, priority ok" % [types, gold])
			return _finish("")
	return false


func _spawn(id: String, pos: Vector3) -> Unit:
	var u: Unit = UnitType.find(id).create_unit()
	u.team = Unit.Team.PLAYER
	u.position = pos
	main.add_child(u)
	u.command_stop()
	return u


func _key(code: Key, shift := false, ctrl := false) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.shift_pressed = shift
	ev.ctrl_pressed = ctrl
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _finish(reason: String) -> bool:
	paused = false
	GameSettings.reset_unit_priority(false)
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
