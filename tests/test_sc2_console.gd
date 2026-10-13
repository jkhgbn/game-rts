extends SceneTree
## Tasks SC2.U1-U5 (docs/design/ui-sc2-console.md): the console HUD in a Fire skirmish at 1600 x 900.
## - U1: one ConsoleFrame y 684-900 across the screen; minimap 200 at (14, 692); selection block x 244-1132 / y 692-892;
##   portrait window 136 at (1144, 696) + status slate (1144, 840); command card 5 x 3 of 56 (gap 4) from (1292, 704) with
##   the remapped slots (orders row 1, spells F / Q / E r2c1-r2c3, Build r3c1, build menu Z X C V B / N M + Back r3c5, the
##   keep's Set Rally r3c1); the old help block is not on screen.
## - U2: resources right-anchored (right edge 1592, y 8), the clock in the quick row, the tier chip under the resources,
##   Menu / ? at (8, 8) / (40, 8), the help overlay on ? / K / Esc, the objective folds to its header.
## - U3: hero tile 240 x 100 at (8, 548) with the 6 + 2 item slots, the champion slots 240 x 52 from (8, 380), the
##   Idle / Army buttons hidden at 0, the alert stack (a push shows a tile at (8, 340) and pings the minimap).
## - U4: group tabs 56 x 32 at y 652; multi-selection = type tabs + 40 px icons 16 per row whose rim follows HP; the
##   single view's stat table; the building view's queue 44 px + tier line + rally; the site's Cancel button.
## - U5: tooltips render the cost line as icons, the requirement line in WARN; the spell buttons show a mana tag.
## Run:  godot --headless --path . -s tests/test_sc2_console.gd --fixed-fps 60 --quit-after 200000
##   Options after `--`: shots=<absolute folder> (windowed run: saves PNG shots of each step there)

const TASK_ID := "sc2_console"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0

var main: Node
var sel: SelectionManager
var hud: GameHUD
var _errors: Array[String] = []
var _shots := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			_shots = a.trim_prefix("shots=")
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _fail(what: String) -> void:
	_errors.append(what)
	print("  x %s" % what)


func _near(r: Rect2, want: Rect2, what: String, eps := 1.5) -> void:
	if absf(r.position.x - want.position.x) > eps or absf(r.position.y - want.position.y) > eps \
			or (want.size.x > 0.0 and absf(r.size.x - want.size.x) > eps) \
			or (want.size.y > 0.0 and absf(r.size.y - want.size.y) > eps):
		_fail("%s at %s, want %s" % [what, r, want])


func _shot(name: String) -> void:
	if _shots == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shots)
	img.save_png(_shots.path_join(name + ".png"))


func _run() -> void:
	root.size = Vector2i(1600, 900)
	GameSettings.ensure_read()
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_fail("the skirmish never started")
			_finish()
			return
	root.size = Vector2i(1600, 900)
	await _frames(5)
	sel = main.get(&"selection")
	hud = main.get(&"hud")
	var hero: Wizard = main.get(&"hero")
	var path := StrIntPath.of(hero)
	if path != null and not path.is_locked():
		path.choose(&"str")
	paused = false
	await _frames(10)
	await _check_u1()
	await _check_u2()
	await _check_u3()
	await _check_u4()
	await _check_u5()
	await _check_sizes()
	_finish()


func _finish() -> void:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 40))])
	quit(0 if _errors.is_empty() else 1)


# ---------------------------------------------------------------- U1

func _check_u1() -> void:
	var console: ConsoleFrame = hud.console
	_near(console.get_global_rect(), Rect2(0, 684, 1600, 216), "console frame")
	_near(console.zone_rect(&"selection"), Rect2(244, 692, 888, 200), "selection zone")
	_near(hud.minimap.get_global_rect(), Rect2(14, 692, 200, 200), "minimap")
	_near(hud.selection_panel.get_global_rect(), Rect2(244, 692, 888, 200), "selection block")
	var pw: PortraitWindow = hud.selection_panel.portrait_window
	_near(hud.selection_panel.portrait.get_global_rect(), Rect2(1144, 696, 136, 136), "portrait")
	_near(pw.get_node(^"StatusSlate").get_global_rect(), Rect2(1144, 840, 136, 44), "status slate")
	var card := hud.command_card
	if CommandCard.COLUMNS != 5 or CommandCard.ROWS != 3 or CommandCard.BUTTON_SIZE != 56.0:
		_fail("card is %d x %d of %d" % [CommandCard.COLUMNS, CommandCard.ROWS, CommandCard.BUTTON_SIZE])
	_near(card.get_global_rect(), Rect2(1292, 704, 296, 176), "command card")
	_near((card.buttons[0].get_parent() as Control).get_global_rect(), Rect2(1292, 704, 56, 56), "card r1c1")
	_near((card.buttons[14].get_parent() as Control).get_global_rect(), Rect2(1532, 824, 56, 56), "card r3c5")
	if hud.get(&"_help_panel").visible:
		_fail("the controls help is on screen by default")
	# Slots: the wizard = M C H A on row 1, F Q E on r2c1-r2c3.
	var hero: Wizard = main.get(&"hero")
	sel.select_units([hero])
	await _frames(4)
	card.refresh()
	var ids := card.slot_ids()
	for want: Array in [[0, "move"], [1, "stop"], [2, "hold"], [3, "attack"]]:
		if ids[want[0]] != want[1]:
			_fail("wizard card slot %d = '%s', want %s" % [want[0], ids[want[0]], want[1]])
	var spells := SpellInfo.ids(hero)
	for i in mini(spells.size(), 3):
		if ids[5 + i] != String(spells[i]):
			_fail("spell %d at slot %d = '%s'" % [i, 5 + i, ids[5 + i]])
	if pw.portrait.target != hero:
		_fail("portrait does not show the wizard")
	await _shot("u1_wizard")
	# Workers: Gather r1c4, Build r3c1; the build menu = Z X C on row 1, Back r3c5.
	var workers := _own_workers()
	sel.select_units(workers)
	await _frames(4)
	card.refresh()
	ids = card.slot_ids()
	if ids[3] != "gather" or ids[10] != "build":
		_fail("worker card: gather at 3 = '%s', build at 10 = '%s'" % [ids[3], ids[10]])
	sel.open_build_menu()
	await _frames(2)
	card.refresh()
	ids = card.slot_ids()
	if ids[14] != "back" or not ids[0].begins_with("build_") or not ids[1].begins_with("build_"):
		_fail("build menu slots %s" % [ids])
	sel.close_build_menu()
	# The keep: training row 1 (Z X C V B), Set Rally r3c1.
	var keep: Keep = main.get(&"keep")
	sel.select_building(keep)
	await _frames(4)
	card.refresh()
	ids = card.slot_ids()
	if ids[10] != "rally" or not ids[0].begins_with("train_"):
		_fail("keep card %s" % [ids])
	if pw.portrait.target != keep:
		_fail("portrait does not show the keep")
	await _shot("u1_keep")


func _own_workers() -> Array:
	var out: Array = []
	for u in get_nodes_in_group(&"units"):
		if int(u.get(&"team")) == PLAYER and (u as Unit).is_alive() and SelectionManager.is_worker_unit(u):
			out.append(u)
	return out


# ---------------------------------------------------------------- U2

func _check_u2() -> void:
	var tb: Rect2 = hud.top_bar.get_global_rect()
	if absf(tb.end.x - 1592.0) > 1.5 or absf(tb.position.y - 8.0) > 1.0 or absf(tb.size.y - 32.0) > 1.0:
		_fail("resources at %s (want right edge 1592, y 8, 32 tall)" % tb)
	var clock: Control = hud.top_bar.clock_box
	if not clock.is_visible_in_tree():
		_fail("the match clock is not in the quick row")
	elif absf(clock.get_global_rect().end.x - 244.0) > 2.0:
		_fail("clock right edge %.0f, want 244" % clock.get_global_rect().end.x)
	var chip: Variant = hud.tier_chip
	if chip is Control and (chip as Control).visible:
		var cr := (chip as Control).get_global_rect()
		if absf(cr.end.x - 1592.0) > 1.5 or absf(cr.position.y - 44.0) > 1.5:
			_fail("tier chip at %s (want right edge 1592, y 44)" % cr)
	_near(hud.menu_button.get_global_rect(), Rect2(8, 8, 28, 22), "Menu button")
	_near(hud.help_button.get_global_rect(), Rect2(40, 8, 28, 22), "? button")
	# Help overlay: K opens, K closes, ? opens, Esc closes.
	_key(KEY_K)
	await _frames(2)
	if not hud.is_help_open():
		_fail("K did not open the controls overlay")
	else:
		_near(hud.get(&"_help_panel").get_global_rect(), Rect2(560, 140, 480, 0), "help overlay")
		await _shot("u2_help")
	_key(KEY_K)
	await _frames(2)
	if hud.is_help_open():
		_fail("K did not close the controls overlay")
	hud.help_button.pressed.emit()
	await _frames(2)
	_key(KEY_ESCAPE)
	await _frames(2)
	if hud.is_help_open():
		_fail("Esc did not close the controls overlay")
	# Objective: folds to its header line.
	var obj: Control = hud.objective_panel()
	_near(obj.get_global_rect(), Rect2(8, 36, 0, 0), "objective panel")
	var h0 := obj.size.y
	hud.toggle_objective()
	await _frames(2)
	if not hud.objective_collapsed or obj.size.y >= h0 - 4.0:
		_fail("the objective did not fold (%.0f -> %.0f)" % [h0, obj.size.y])
	hud.toggle_objective()
	await _frames(2)
	# Supply-blocked flash.
	hud.top_bar.flash_supply_blocked()
	if not hud.top_bar.is_supply_flashing():
		_fail("no supply-blocked flash")


func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


# ---------------------------------------------------------------- U3

func _check_u3() -> void:
	var panel := hud.selection_panel
	_near(panel.hero_tile.get_global_rect(), Rect2(8, 548, 240, 100), "hero tile")
	_near(panel.hero_hp.get_global_rect(), Rect2(66, 572, 140, 12), "hero HP bar")
	_near(panel.hero_mana.get_global_rect(), Rect2(66, 586, 140, 12), "hero mana bar")
	var inv := hud.inventory_bar
	if inv.slot_controls.size() != 8:
		_fail("%d inventory slots" % inv.slot_controls.size())
	else:
		_near((inv.slot_controls[0] as Control).get_global_rect(), Rect2(10, 612, 32, 32), "item slot 1")
		_near((inv.slot_controls[5] as Control).get_global_rect(), Rect2(175, 612, 32, 32), "item slot 6")
		_near((inv.slot_controls[6] as Control).get_global_rect(), Rect2(212, 552, 32, 32), "artifact slot")
	var cb := hud.champion_bar
	_near(cb.slots[0].get_global_rect(), Rect2(8, 380, 240, 52), "champion slot 1")
	_near(cb.slots[2].get_global_rect(), Rect2(8, 492, 240, 52), "champion slot 3")
	# Quick row: Idle / Army hidden at 0, at their spots when shown.
	var idle := hud.idle_worker_button
	idle.refresh()
	if idle.visible != not sel.idle_workers().is_empty():
		_fail("idle button visible %s with %d idle" % [idle.visible, sel.idle_workers().size()])
	_near(idle.get_global_rect(), Rect2(8, 648, 36, 36), "idle button")
	_near(hud.army_button.get_global_rect(), Rect2(48, 648, 36, 36), "army button")
	hud.army_button.refresh()
	if hud.army_button.visible != not sel.army_units().is_empty():
		_fail("army button visible %s with %d army" % [hud.army_button.visible, sel.army_units().size()])
	# Alerts: a push = a tile at (8, 340) + a minimap ping; same kind nearby merges.
	var st := hud.alert_stack
	var a := st.push(&"built", "Ember Hall complete", Vector3(10, 0, 10))
	st.push(&"built", "Ember Hall complete", Vector3(12, 0, 10))
	await _frames(2)
	if st.alerts.size() != 1 or int(a["count"]) != 2:
		_fail("alerts did not merge (%d alerts)" % st.alerts.size())
	else:
		_near((a["tile"] as Control).get_global_rect(), Rect2(8, 340, 36, 36), "alert tile")
	st.push(&"attack", "You are under attack", Vector3(-40, 0, 30))
	await _frames(2)
	if st.alerts.size() != 2 or (st.alerts[0]["tile"] as Control).get_global_rect().position.y > 305.0:
		_fail("a second alert did not stack above the newest")
	await _shot("u3_left_stack")


# ---------------------------------------------------------------- U4

func _check_u4() -> void:
	var panel := hud.selection_panel
	var workers := _own_workers()
	sel.select_units(workers)
	sel.set_control_group(1)
	await _frames(3)
	hud.group_bar.refresh()
	var tab: Button = hud.group_bar.tab_for_group(1)
	if tab == null or not tab.visible:
		_fail("group 1 tab not shown")
	else:
		_near(tab.get_global_rect(), Rect2(252, 652, 56, 32), "group tab 1")
	# Multi-selection: type tabs + 40 px icons, 16 per row, HP rim.
	var hero: Wizard = main.get(&"hero")
	var group: Array = workers.duplicate()
	group.append(hero)
	sel.select_units(group)
	await _frames(4)
	if panel.current_view() != "multi":
		_fail("multi view not shown")
	else:
		_near(panel.icons[0].get_global_rect(), Rect2(252, 728, 40, 40), "multi icon 1")
		if panel.type_tabs_shown() < 2:
			_fail("type tabs: %d shown for 2 types" % panel.type_tabs_shown())
		var w: Unit = workers[0]
		w.hp = w.max_hp * 0.2
		await _frames(3)
		var i := panel.icon_index_of(w)
		if i < 0 or not panel.icon_rim(i).is_equal_approx(UIStyle.WARN):
			_fail("a 20 %% HP unit's icon rim is %s" % (panel.icon_rim(i) if i >= 0 else Color.BLACK))
		w.hp = w.max_hp
	await _shot("u4_multi")
	# Single unit: the stat table.
	sel.select_units([workers[0]])
	await _frames(4)
	if panel.current_view() != "single" or panel.stat_table_text() == "":
		_fail("single view stat table '%s'" % panel.stat_table_text())
	await _shot("u4_single")
	# Building: queue slots 44 px at (252, 776).
	var keep: Keep = main.get(&"keep")
	sel.select_building(keep)
	await _frames(4)
	_near(panel.queue_buttons[0].get_global_rect(), Rect2(252, 776, 44, 44), "queue slot 1")
	if panel.keep_tier_line() == "":
		_fail("no tier line on the keep view")
	await _shot("u4_keep")


# ---------------------------------------------------------------- screen sizes (UI Lab checks)

## The UI Lab's FAIL rules (overflow > 6 px out of the frame, off-screen, overlaps >= 150 px2, font < 9 px, bottom-bar
## gaps > 40 %) on the HUD with the wizard, the keep and a multi-selection, at 1600 x 900 (= 2560 x 1440 at x1.6) and
## 2150 x 900 (3440 x 1440 at x1.6: only the selection block widens, the portrait / card stay at the right edge).
func _check_sizes() -> void:
	var keep: Keep = main.get(&"keep")
	var hero: Wizard = main.get(&"hero")
	var group: Array = _own_workers()
	group.append(hero)
	for sz: Vector2i in [Vector2i(1600, 900), Vector2i(2150, 900)]:
		root.size = sz
		for pick: Array in [["wizard", [hero]], ["multi", group], ["keep", keep]]:
			if pick[1] is Array:
				sel.select_units(pick[1])
			else:
				sel.select_building(pick[1])
			await _frames(6)
			_lab_check("%s @%dx%d" % [pick[0], sz.x, sz.y], Rect2(Vector2.ZERO, Vector2(sz)))
		var w := float(sz.x)
		_near(hud.command_card.get_global_rect(), Rect2(w - 308.0, 704, 296, 176), "card @%d" % sz.x)
		_near(hud.selection_panel.portrait.get_global_rect(), Rect2(w - 456.0, 696, 136, 136), "portrait @%d" % sz.x)
		_near(hud.selection_panel.get_global_rect(), Rect2(244, 692, w - 712.0, 200), "selection block @%d" % sz.x)
		_near(hud.console.get_global_rect(), Rect2(0, 684, w, 216), "console @%d" % sz.x)
	root.size = Vector2i(1600, 900)
	await _frames(2)


func _lab_check(tag: String, screen: Rect2) -> void:
	var controls := UILabChecks.visible_controls(hud)
	for it: Dictionary in UILabChecks.find_overflow(controls):
		if it.get("kind", "") == "frame" and float(it["value"]) > 6.0:
			_fail("%s overflow: %s (%s)" % [tag, it["text"], it["detail"]])
	for it: Dictionary in UILabChecks.find_offscreen(controls, screen):
		_fail("%s off-screen: %s (%s)" % [tag, it["text"], it["detail"]])
	for it: Dictionary in UILabChecks.find_overlaps(controls):
		if float(it["value"]) >= 150.0:
			_fail("%s overlap: %s (%s)" % [tag, it["text"], it["detail"]])
	for it: Dictionary in UILabChecks.find_small_fonts(controls):
		if bool(it.get("fail", false)):
			_fail("%s font: %s %s px" % [tag, it["text"], it["value"]])
	for it: Dictionary in UILabChecks.find_bottom_gaps(controls, screen):
		if bool(it.get("fail", false)):
			_fail("%s gap: %s" % [tag, it["detail"]])


# ---------------------------------------------------------------- U5

func _check_u5() -> void:
	var tip := ItemTooltip.HudSkin.tooltip_panel("Flame Guard  [Z]\nCost 90 crystals · Pop 1 · 18 s\nMelee line unit.\nNot enough crystals")
	var cost_row := tip.find_child("CostRow", true, false)
	if cost_row == null:
		_fail("the tooltip's cost line is not rendered as icons")
	var reasons := tip.find_children("*", "Label", true, false).filter(func(l: Node) -> bool:
			return (l as Label).text == "Not enough crystals")
	if reasons.is_empty() or not (reasons[0] as Label).get_theme_color(&"font_color").is_equal_approx(UIStyle.WARN):
		_fail("the requirement line is not WARN")
	tip.free()
	var hero: Wizard = main.get(&"hero")
	sel.select_units([hero])
	await _frames(3)
	var card := hud.command_card
	card.refresh()
	var tag: Label = card.cost_tags[5]
	if not tag.visible or not tag.text.ends_with("MANA") and not tag.text.is_valid_int():
		_fail("no mana tag on the wizard's first spell ('%s', visible %s)" % [tag.text, tag.visible])
