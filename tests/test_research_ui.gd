extends SceneTree
## UR.U2 (ui-sc2-console.md 7.4-7.7): research marks outside the command card. Fire skirmish:
## - building view: the research chip of an own Hall (idle tooltip `No research`, running row + progress while Kindled
##   Mail researches, a click cancels it with a full refund); hidden on a worker selection's building-less view;
## - completion: alert kind `research` with `Research complete: Kindled Mail (Flame Guard)`; a row granted without
##   being started here (a load) raises nothing;
## - 1-unit view: `Research: Kindled Mail` line, tooltip `Kindled Mail: +5 armor`; portrait: 1 research pip;
## - 2+ types: the Flame Guard type tab carries the research mark; a grid icon tooltip says `1 upgrade`;
## - Unit Guide: Flame Guard's Upgrades block Z "+", X Kindled Mail, C Backdraft; search `kindled` finds it; Blaze
##   Rider's rank-3 comes after its rows; the Forge unit lines are gone from the abilities.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_research_ui.gd --fixed-fps 60 --quit-after 30000
## Options after `--`: lang=fr (French), shots=<res:// dir> (saves research_*.jpg there). Windowed (`--resolution
## 1600x900`, no --headless) every shot runs the UI Lab control checks on the HUD: frame overflow > 6 px, overlap
## >= 150 px2, off screen = FAIL.

const TASK_ID := "research_ui"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0

var main: Node
var sel: SelectionManager
var hud: GameHUD
var panel: SelectionPanel
var _errors: Array[String] = []
var _shots := ""
var _lang := "en"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	GameSettings.ensure_read()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			_shots = a.trim_prefix("shots=")
		elif a.begins_with("lang="):
			_lang = a.trim_prefix("lang=")
	if _lang != "en":
		Loc.set_language(_lang)
	_guide_checks()
	await _game()
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


func _fail(what: String) -> void:
	_errors.append(what)
	print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _guide_checks() -> void:
	UnitGuideData.reset()
	var e := UnitGuideData.entry(&"flame_guard")
	var ups: Array = e.get("upgrades", [])
	var got: PackedStringArray = []
	for u: Dictionary in ups:
		got.append("%s %s" % [u["key"], u["name"]])
	if got != PackedStringArray(["Z Flame Guard+", "X Kindled Mail", "C Backdraft"]):
		_fail("Flame Guard guide upgrades %s" % str(got))
	elif UnitGuideData.upgrade_line(ups[2]) != "%s · T2 · 125 · 40 s" % UnitGuideData.building_label(String(e["building"])):
		_fail("Backdraft guide line '%s'" % UnitGuideData.upgrade_line(ups[2]))
	var found := false
	for f: Dictionary in UnitGuideData.filter(&"", 0, "", "kindled"):
		found = found or f["id"] == &"flame_guard"
	if not found:
		_fail("guide search 'kindled' does not find the Flame Guard")
	var br: Array = UnitGuideData.entry(&"blaze_rider").get("upgrades", [])
	var n_rows := UnitResearch.rows_for_unit(&"blaze_rider").size()
	if br.size() != 2 + n_rows or str((br.back() as Dictionary)["name"]) != Stables16.rank_name(&"blaze_rider") \
			or str((br.back() as Dictionary)["key"]) != "ZXCVB"[1 + n_rows]:
		_fail("Blaze Rider guide upgrades %s (rank-3 last on %s)" % [str(br), "ZXCVB"[1 + n_rows]])
	for id: StringName in UnitGuideData.ids():
		for a: Dictionary in UnitGuideData.entry(id)["abilities"]:
			if str(a.get("name", "")) == "Hall research" or str(a.get("tmpl", "")).begins_with("Forge research once"):
				_fail("%s still lists '%s' in its abilities" % [id, a.get("name", a.get("tmpl", ""))])


func _game() -> void:
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
			return
	await _frames(5)
	sel = main.get(&"selection")
	hud = main.get(&"hud")
	panel = hud.selection_panel
	var path := StrIntPath.of(main.get(&"hero"))
	if path != null and not path.is_locked():
		path.choose(&"str")
	paused = false
	var eco := Economy.for_team(PLAYER)
	eco.add(20000)
	var ts := TierSystem.instance()
	ts.time_gates = false
	ts.set_tier(PLAYER, 1)
	var keep: Keep = main.get(&"keep")
	var grid: BuildGrid = main.get(&"build_grid")
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var ht := BuildingType.find("fire_barracks")
	var hall := grid.spawn_complete(ht, grid.find_spot(ht, keep.global_position + dir * 16.0, PLAYER), PLAYER)
	await _frames(3)

	# ---- Building view: idle chip.
	sel.select_building(hall)
	await _frames(3)
	var st := panel.research_chip_state()
	if not st["shown"] or st["running"] != &"" or not str(st["tooltip"]).begins_with(Loc.t("No research · open with {key}", {"key": "+"})):
		_fail("idle research chip: %s" % str(st))
	# Running: buy Kindled Mail, the chip shows it; a chip click cancels it (full refund).
	var c0 := eco.crystals
	sel.open_upgrades()
	sel.open_research_unit(&"flame_guard")
	sel.buy_research(&"flame_guard_kindled_mail")
	await _frames(20)
	st = panel.research_chip_state()
	if st["running"] != &"flame_guard_kindled_mail" or float(st["progress"]) <= 0.0 \
			or not str(st["tooltip"]).contains("Kindled Mail"):
		_fail("running research chip: %s" % str(st))
	if not panel.research_chip_bar.visible or not panel.research_chip_time.visible:
		_fail("running chip: no RESEARCH bar / time left")
	await _shot("research_unit_page")
	sel.research_back()
	await _shot("research_page")
	sel.open_research_unit(&"flame_guard")
	panel.research_chip.pressed.emit()
	await _frames(2)
	var bank := UnitResearch.for_team(PLAYER)
	if bank.is_working(&"flame_guard_kindled_mail") or eco.crystals != c0:
		_fail("chip click did not cancel with a full refund (crystals %d, want %d)" % [eco.crystals, c0])

	# ---- Completion alert (started here), then a granted row (never started) raises nothing.
	sel.buy_research(&"flame_guard_kindled_mail")
	for i in 70:   # the alert stack finds the research node on its 0.5 s poll
		await process_frame
	var before := hud.alert_stack.alerts.size()
	bank.grant(&"flame_guard_kindled_mail")
	await _frames(2)
	var alert: Dictionary = hud.alert_stack.alerts.back() if hud.alert_stack.alerts.size() > before else {}
	if alert.is_empty() or alert["kind"] != &"research" \
			or str(alert["message"]) != Loc.t("Research complete: {name} ({unit})", {"name": "Kindled Mail", "unit": "Flame Guard"}):
		_fail("no research alert (%s)" % str(alert))
	var n_alerts := hud.alert_stack.alerts.size()
	bank.grant(&"ember_archer_quick_nock")
	await _frames(2)
	if hud.alert_stack.alerts.size() != n_alerts or int(hud.alert_stack.alerts.back()["count"]) != 1:
		_fail("a granted (load) row raised an alert")

	# ---- 1-unit view: Research line + tooltip; portrait pip.
	sel.close_upgrades()
	var guard: Unit = UnitType.find("flame_guard").create_unit()
	guard.team = Unit.Team.PLAYER
	main.add_child(guard)
	guard.global_position = keep.global_position + dir * 8.0
	var archer: Unit = UnitType.find("blaze_rider").create_unit()
	archer.team = Unit.Team.PLAYER
	main.add_child(archer)
	archer.global_position = keep.global_position + dir * 8.0 + Vector3(2, 0, 0)
	await _frames(3)
	sel.select_units([guard])
	await _frames(3)
	if panel.research_line_text() != Loc.t("Research: ") + "Kindled Mail":
		_fail("1-unit research line '%s'" % panel.research_line_text())
	if panel.single_extra_rows[0].tooltip_text != Loc.t("{name}: {effect}", {"name": "Kindled Mail", "effect": Loc.sink("+5 armor")}):
		_fail("research line tooltip '%s'" % panel.single_extra_rows[0].tooltip_text)
	if panel.portrait_window.pip_count() != 1:
		_fail("portrait pips %d (want 1)" % panel.portrait_window.pip_count())
	await _shot("research_line")
	sel.select_units([archer])
	await _frames(3)
	if panel.research_line_text() != "" or panel.portrait_window.pip_count() != 0:
		_fail("Blaze Rider without research shows '%s' / %d pips" % [panel.research_line_text(),
				panel.portrait_window.pip_count()])

	# ---- 2 types: the Flame Guard tab's mark, its grid icon tooltip.
	sel.select_units([guard, archer])
	await _frames(3)
	var marked := 0
	for i in panel.type_tabs.size():
		if panel.type_tab_research_mark(i):
			marked += 1
	if marked != 1:
		_fail("%d type tabs carry the research mark (want 1)" % marked)
	await _shot("research_tabs")
	var gi := panel.icon_index_of(guard)
	if gi < 0 or not panel.icons[gi].tooltip_text.contains(Loc.tn("{n} upgrade", "{n} upgrades", 1)):
		_fail("grid icon tooltip '%s'" % (panel.icons[gi].tooltip_text if gi >= 0 else "-"))
	main.queue_free()
	await _frames(3)


## Saves the screen (windowed + shots=) and runs the UI Lab control checks on the HUD (FAIL rules of ui_lab.gd).
func _shot(shot_name: String) -> void:
	await _frames(4)
	if DisplayServer.get_name() == "headless":
		return   # the headless window is not the HUD's 1600 x 900 (its layout checks would measure nothing real)
	if _shots != "":
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var dir := ProjectSettings.globalize_path(_shots)
		DirAccess.make_dir_recursive_absolute(dir)
		img.save_jpg(dir.path_join("%s_%s.jpg" % [shot_name, _lang]), 0.85)
	var controls := UILabChecks.visible_controls(hud)
	var screen := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	for it: Dictionary in UILabChecks.find_overflow(controls):
		if it.get("kind", "") == "frame" and float(it["value"]) > 6.0:
			_fail("%s: overflow %s" % [shot_name, str(it)])
	for it: Dictionary in UILabChecks.find_overlaps(controls):
		if float(it["value"]) >= 150.0:
			_fail("%s: overlap %s" % [shot_name, str(it)])
	for it: Dictionary in UILabChecks.find_offscreen(controls, screen):
		_fail("%s: off screen %s" % [shot_name, str(it)])
