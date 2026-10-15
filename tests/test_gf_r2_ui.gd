extends SceneTree
## G-F art review 2 items 12 and 13 (docs/art/gf_review2.md): the start view breathes and the main menu frames the
## diorama.
## Item 13 (main menu at 1600 x 900): the title + main panel sit in the right part (column_on_side, anchor 0.45) so
##   the wizards round the fire stay in view; the setup panel is centred again; the tagline has a light fill with a
##   dark outline and a shadow; the main panel's slate is translucent.
## Item 12 (skirmish HUD): the objective folds to its header by itself after OBJECTIVE_FOLD_TIME s (the Next hint
##   follows it up); a header click turns the auto-fold off; the long start hint uses the smaller font on a darker
##   plate; the champion bar shows one slot until the taverns open, then the 3 slots.
## Run: godot --headless --path . -s tests/test_gf_r2_ui.gd --fixed-fps 60 --quit-after 12000
## Shots (windowed, 1600 x 900): ... -s tests/test_gf_r2_ui.gd --quit-after 20000 -- --shots  (STR picked, HUD at 1 s and
## 12 s -> docs/art/lab/gf_r2_ui/_after_shots/; no verdict).

const TASK_ID := "gf_r2_ui"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const SKIRMISH := "res://scenes/skirmish.tscn"

var h := MissionHarness.new()
var menu: Node
var main: Node
var _phase := 0
var _frames := 0
var _menu_fails: Array[String] = []
var _hint_y0 := 0.0


func _initialize() -> void:
	h.task_id = TASK_ID
	if OS.get_cmdline_user_args().has("--shots"):
		_phase = 10
		root.size = Vector2i(1600, 900)
		main = (load(SKIRMISH) as PackedScene).instantiate()
		root.add_child(main)
		current_scene = main
		return
	h.timeout_frames = 9000
	menu = (load(MENU_SCENE) as PackedScene).instantiate()
	root.add_child(menu)


func _process(_d: float) -> bool:
	if _phase >= 10:
		return _shots()
	if _phase == 0:
		_frames += 1
		if _frames == 2:
			root.size = Vector2i(1600, 900)   # headless starts at 64 x 64 and ignores a size set in _initialize
			menu.call(&"place_column")
		elif _frames == 5:
			_check_menu_main()
			menu.call(&"show_skirmish_setup")
		elif _frames == 8:
			if bool(menu.get(&"column_on_side")):
				_menu_fails.append("the skirmish setup panel is not centred")
			menu.call(&"show_main")
		elif _frames == 11:
			if not bool(menu.get(&"column_on_side")):
				_menu_fails.append("back on the main panel: not on the side")
			menu.queue_free()
			_phase = 1
		return false
	if _phase == 1:
		_phase = 2
		main = h.open(self, SKIRMISH)
		for f in _menu_fails:
			h.errors.append(f)
		h.steps.add("start view", _start_view, 10)
		h.steps.add("objective folds", _folded, 900)
		h.steps.add("header click stops the auto-fold", _manual, 100)
		h.steps.add("taverns open: 3 slots", _taverns_open, 4000)
		h.steps.add("hovered unit HP bar", _hover_bar, 10)
		return false
	return h.tick()


func _check_menu_main() -> void:
	if not bool(menu.get(&"column_on_side")):
		_menu_fails.append("main menu column not on the side at 1600 x 900")
	var col: Control = menu.get(&"menu_column")
	if col == null or absf(col.anchor_left - 0.45) > 0.01:
		_menu_fails.append("menu column anchor_left %s" % (col.anchor_left if col else -1.0))
	var panel: Control = menu.get(&"main_panel")
	var c := panel.get_global_rect().get_center().x if panel else 0.0
	if c < 900.0:
		_menu_fails.append("main panel centre x %.0f (want the right part)" % c)
	var sb := panel.get_theme_stylebox(&"panel") as StyleBoxFlat if panel else null
	if sb == null or sb.bg_color.a > 0.8:
		_menu_fails.append("main panel slate not translucent")
	var tag: Label = menu.get(&"tagline_label")
	if tag == null:
		_menu_fails.append("no tagline_label")
		return
	var fill := tag.get_theme_color(&"font_color")
	if fill.get_luminance() < 0.8 or tag.get_theme_constant(&"outline_size") < 6 \
			or tag.get_theme_color(&"font_shadow_color").a < 0.4 or tag.modulate.a < 1.0:
		_menu_fails.append("tagline style: fill %s outline %d" % [fill, tag.get_theme_constant(&"outline_size")])


func _hud() -> Node:
	return main.get(&"hud")


func _start_view() -> bool:
	var hud := _hud()
	h.check(hud != null, "the skirmish has a HUD")
	if hud == null:
		return true
	h.check(not bool(hud.get(&"objective_collapsed")), "objective open at the start")
	h.check(bool(hud.get(&"objective_auto_fold")), "auto-fold armed at the start")
	var msg: Label = hud.get(&"_message")
	h.check(msg != null and msg.visible and msg.text.length() > 64, "the start hint is up")
	if msg != null:
		h.check(msg.get_theme_font_size(&"font_size") == 18, "start hint font %d (want 18)" % msg.get_theme_font_size(&"font_size"))
		var plate := msg.get_theme_stylebox(&"normal") as StyleBoxFlat
		h.check(plate != null and plate.bg_color.a >= 0.75, "start hint plate darker")
	var bar: ChampionBar = hud.get(&"champion_bar")
	h.check(bar != null and bar.visible, "champion bar shown (taverns on the map)")
	if bar != null:
		bar.refresh()
		h.check(bar.compact, "champion bar compact before the taverns open")
		h.check(bar.slots[0].visible and not bar.slots[1].visible and not bar.slots[2].visible,
				"one slot shown before the taverns open")
		h.check(bar.slots[0].state == &"empty", "the shown slot is the empty Hire slot")
	var hint: Control = hud.get(&"next_step_hint")
	if hint != null:
		_hint_y0 = hint.position.y
	return true


func _folded() -> bool:
	var hud := _hud()
	if not bool(hud.get(&"objective_collapsed")):
		return false
	h.check(float(main.call(&"match_time")) >= 9.0, "folded at %.1f s (want about 10 s)" % float(main.call(&"match_time")))
	h.check(not bool(hud.get(&"objective_auto_fold")), "auto-fold used once")
	_frames = 0
	return true


func _manual() -> bool:
	_frames += 1
	if _frames < 45:
		return false   # the Next hint re-places itself every 0.5 s
	var hud := _hud()
	var hint: Control = hud.get(&"next_step_hint")
	if hint != null and hint.visible:
		h.check(hint.position.y < _hint_y0 - 20.0, "Next hint moved up under the folded objective (%.0f -> %.0f)"
				% [_hint_y0, hint.position.y])
	hud.call(&"toggle_objective")
	h.check(not bool(hud.get(&"objective_collapsed")), "header click unfolds")
	h.check(not bool(hud.get(&"objective_auto_fold")), "header click keeps the auto-fold off")
	Engine.time_scale = 10.0
	return true


func _taverns_open() -> bool:
	var hud := _hud()
	if float(main.call(&"match_time")) < 125.0:
		return false
	Engine.time_scale = 1.0
	h.check(not bool(hud.get(&"objective_collapsed")), "a manually opened objective stays open")
	var bar: ChampionBar = hud.get(&"champion_bar")
	bar.refresh()
	h.check(not bar.compact, "champion bar not compact once the taverns open")
	for i in 3:
		h.check(bar.slots[i].visible, "slot %d shown once the taverns open" % (i + 1))
	return true


# Review item 1 (gameplay request): the unit under the cursor gets set_hp_bar_hover(true), the previous one false.
func _hover_bar() -> bool:
	var sel: Node = main.get(&"selection")
	h.check(sel != null and sel.has_method(&"set_hovered_unit"), "SelectionManager.set_hovered_unit exists")
	var units: Array = []
	for u: Node in get_nodes_in_group(&"units"):
		if u.has_method(&"set_hp_bar_hover"):
			units.append(u)
	if sel == null or units.size() < 2:
		h.check(units.size() >= 2, "two units with set_hp_bar_hover")
		return true
	sel.call(&"set_hovered_unit", units[0])
	h.check(bool(units[0].get(&"_bar_hover")), "hovered unit's bar is in hover mode")
	sel.call(&"set_hovered_unit", units[1])
	h.check(not bool(units[0].get(&"_bar_hover")) and bool(units[1].get(&"_bar_hover")), "hover moves to the new unit")
	sel.call(&"set_hovered_unit", null)
	h.check(not bool(units[1].get(&"_bar_hover")), "hover off when the cursor leaves")
	return true


# Windowed shot mode: picks STR when the path panel is up, then captures the HUD at 1 s and 12 s of match time.
func _shots() -> bool:
	_frames += 1
	if _frames > 15000:
		return true
	if main.get(&"hero") == null or not bool(main.get(&"match_started")):
		return false
	var hero: Node = main.get(&"hero")
	var path := hero.get_node_or_null(^"StrIntPath")
	if path != null and StringName(str(path.get(&"path"))) == &"":
		path.call(&"choose", &"str")
	var t := float(main.call(&"match_time"))
	if _phase == 10 and t >= 1.0:
		_save_shot("hud_after_1s.png")
		_phase = 11
	elif _phase == 11 and t >= 12.0:
		_save_shot("hud_after_12s.png")
		return true
	return false


func _save_shot(file: String) -> void:
	var dir := "res://docs/art/lab/gf_r2_ui/_after_shots/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(dir + file))
	print("SHOT %s" % file)
