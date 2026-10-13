extends SceneTree
## Test for 3.U3 on the 1v1 map (scenes/skirmish.tscn):
## - help panel shows "Ctrl+F/Q/E: learn spell" and stays clear of the top bar;
## - level badge tooltip "Level N · XP x / y · N spell points";
## - a level-up with an unspent point pulses the "+" learn chips for 2 s (then they stop);
## - statuses (Unit.apply_status) show as chips with a countdown in the hero column and the single view,
##   and as coloured dots on the multi-select icons;
## - 3 Flame Guards (0 / 100 / 300 XP) show 0 / 1 / 2 veterancy dots, and "Veteran" / "Elite" in the single view.
## Run:  godot --headless --path . -s tests/test_3_u3.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "3.u3"
const TIMEOUT_FRAMES := 600
const WARM_UP := 90

var main: Node
var sel: Node
var card: Node
var panel: Node
var hero: Node
var guards: Array = []
var frame := 0
var _wait := 0
var _warm := 0
var _error := ""
var _done := false


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
	_warm += 1
	if _warm < WARM_UP:
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
		print("FAIL %s: timed out at frame %d" % [TASK_ID, frame])
		return true
	return false


func _step() -> void:
	match frame:
		1:
			sel = main.selection
			card = main.hud.command_card
			panel = main.hud.selection_panel
			hero = main.hero
			if not hero.has_method("apply_status"):
				_error = "Unit.apply_status not there yet"
				return
			_check_help()
			if _error != "":
				return
			var tip: String = panel.hero_badge.tooltip_text
			if not tip.begins_with("Level 1 · XP ") or not tip.ends_with(" · 0 spell points"):
				_error = "badge tooltip at level 1 is '%s'" % tip
				return
			if card.learn_pulse_active():
				_error = "learn pulse active before any level-up"
				return
			sel.select_units([hero])
			hero.add_xp(200)
		3:
			if hero.level != 2:
				_error = "hero did not reach level 2"
				return
			var tip: String = panel.hero_badge.tooltip_text
			if tip != "Level 2 · XP %d / %d · 1 spell point" % [hero.xp, hero.xp_to_next()]:
				_error = "badge tooltip at level 2 is '%s'" % tip
				return
			if not card.learn_pulse_active():
				_error = "no learn pulse after a level-up with a point"
				return
			if not card.learn_chips[6].visible:
				_error = "no + chip on Ember Step after the level-up"
				return
			hero.apply_status(&"haste", 8.0)
		5:
			panel.refresh()
			if panel.status_row_text(panel.hero_statuses) != "H 8":
				_error = "hero column statuses '%s', expected 'H 8'" % panel.status_row_text(panel.hero_statuses)
				return
			if panel.current_view() != "single" or panel.status_row_text(panel.single_statuses) != "H 8":
				_error = "single view statuses '%s' (view %s)" % [panel.status_row_text(panel.single_statuses),
						panel.current_view()]
				return
			if not str(panel.hero_statuses.get_node("haste").tooltip_text).begins_with("Haste: "):
				_error = "status chip tooltip '%s'" % panel.hero_statuses.get_node("haste").tooltip_text
				return
			# Three Flame Guards: recruit, veteran (100 XP), elite (300 XP); the elite is shrouded.
			for i in 3:
				var g: Node = main.make_unit("flame_guard")
				g.team = 0
				main.add_child(g)
				g.global_position = hero.global_position + Vector3(-2.0 + i * 1.5, 0.0, 3.0)
				g.command_stop()
				guards.append(g)
			guards[1].add_xp(120)   # Veteran (balance-1: 120 / 350 / 800)
			guards[2].add_xp(350)   # Elite
			guards[2].apply_status(&"shroud", 5.0)
			if guards[1].level != 2 or guards[2].level != 3:
				_error = "guard levels %d / %d, expected 2 / 3" % [guards[1].level, guards[2].level]
				return
			sel.select_units(guards)
		7:
			panel.refresh()
			if panel.current_view() != "multi":
				_error = "3 guards selected but view is %s" % panel.current_view()
				return
			for i in 3:
				var idx: int = panel._icon_units.find(guards[i])
				if idx < 0:
					_error = "guard %d has no icon" % i
					return
				var marks := 0
				for d in panel._icon_dots[idx]:
					if d.visible:
						marks += 1
				if marks != i:
					_error = "guard %d shows %d veterancy dots, expected %d" % [i, marks, i]
					return
				var dots: Dictionary = panel._icon_status_dots[idx]
				if dots[&"shroud"].visible != (i == 2) or dots[&"haste"].visible:
					_error = "guard %d status dots wrong (shroud %s)" % [i, dots[&"shroud"].visible]
					return
			sel.select_units([guards[1]])
		9:
			panel.refresh()
			if not panel.single_name.text.ends_with("Veteran") or panel.single_statuses.visible:
				_error = "veteran single view: '%s', statuses shown %s" % [panel.single_name.text,
						panel.single_statuses.visible]
				return
			sel.select_units([guards[2]])
		11:
			panel.refresh()
			if not panel.single_name.text.ends_with("Elite"):
				_error = "elite single view: '%s'" % panel.single_name.text
				return
			if panel.status_row_text(panel.single_statuses) != "S 5":
				_error = "elite statuses '%s', expected 'S 5'" % panel.status_row_text(panel.single_statuses)
				return
			sel.select_units([hero])
		140:
			# 2 s after the level-up the pulse has stopped and the chips are back to normal size.
			if card.learn_pulse_active():
				_error = "learn pulse still active after 2 s"
				return
			if card.learn_chips[6].visible and card.learn_chips[6].scale != Vector2.ONE:
				_error = "+ chip still scaled %s after the pulse" % card.learn_chips[6].scale
				return
			_done = true


func _check_help() -> void:
	var help: Label = null
	for node in main.hud.find_children("*", "Label", true, false):
		if (node as Label).text.contains("Ctrl+F/Q/E: learn spell"):
			help = node
	if help == null:
		_error = "help text has no 'Ctrl+F/Q/E: learn spell'"
		return
	# Same space as before: still 7 lines, and the edited lines are no wider than the widest old line
	# ("H: hold ... Delete: cancel a site"), so the panel keeps its width.
	var lines := help.text.split("\n")
	if lines.size() > 12:   # step 9 champions line; step 10 reflow to 11 (ui-trade.md 14.1); step 12 capture line
		_error = "help text has %d lines (max 12)" % lines.size()
		return
	var font := help.get_theme_font("font")
	var fs := help.get_theme_font_size("font_size")
	var widest_old := 440.0   # ui-trade.md 14.1: every line <= 438 px (panel 458 wide, clear of the top bar)
	for line in lines:
		if line.contains("Ctrl+F/Q/E") or line.contains("Space: find Vessa"):
			var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if w > widest_old:
				_error = "help line '%s' is wider (%d px) than the panel's widest line (%d px)" % [line, w, widest_old]
