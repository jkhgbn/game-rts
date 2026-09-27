extends SceneTree
## Task 12.C7 (map-fill.md 8 + 15; layout docs/design/ui-mapfill.md 2, 4-8, 10-14 and its "Done when" 12.C7): the
## objectives strip, blessing chips, point panel, critter card, camp lines, camp hover chip, beast boss bars + inspect
## card + command card lines, floating +5 / +40, blessing / wading chips, the message listener (20 s filter, 0:40
## hint), the sounds, the Map detail setting and the 12th help line.
## Runs on the real skirmish (Crown Hollow, with the real step-12 services; the bot off). The match clock of the
## CapturePoints service is replaced by the test's own (`match_time_source`), its physics tick is paused for the
## state checks, and SightMarkers make the checked spots visible to the player.
## Run:  godot --headless --path . -s tests/test_12_c7.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "12.C7"
const TIMEOUT_FRAMES := 8500
const SCENE := "res://scenes/skirmish.tscn"
const SETTINGS := "user://settings.cfg"
const OWN := Color(0.3, 1.0, 0.4)
const ENEMY := Color(1.0, 0.3, 0.3)
const NEUTRAL := Color(0.62, 0.64, 0.70)
const GOLD := Color(1.0, 0.85, 0.4)
const WARN := Color(0.95, 0.35, 0.3)
const NEAR := Color(0.4, 0.9, 0.4)
const FAR := Color(1.0, 0.55, 0.2)
const MAP_ORDER := ["Rookwatch", "Millwatch", "Saltwatch", "Owlwatch", "Mossmere Well", "Stonemere Well",
		"West Wayshrine", "East Wayshrine"]
const ICON_X := [661, 693, 725, 757, 802, 834, 879, 911]
const HINT := "Stand near a watchtower, well or shrine with soldiers to capture it"

var main: Node
var hud: Node
var sel: Node
var bar: Node
var panel: Node
var pop: Node
var cp: Node
var total := 0
var clock := 0.0
var _done := false
var _errors: Array[String] = []
var _notes: Array[String] = []
var _markers: Array = []
var _settings_backup := PackedByteArray()
var _settings_existed := false


func _initialize() -> void:
	_run()


func _process(_delta: float) -> bool:
	total += 1
	if total > TIMEOUT_FRAMES and not _done:
		_errors.append("timed out at frame %d" % total)
		return _finish()
	return _done


func _finish() -> bool:
	_restore_settings()
	for n in _notes:
		print("  note: ", n)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	_done = true
	return true


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if bool(cond.call()):
			return true
		await process_frame
	return bool(cond.call())


func _near_color(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 and absf(a.b - b.b) < 0.02


## A permanent sight source for the player at `pos` (so the point / camp / beast there is visible).
func _see(pos: Vector3, r := 9.0) -> void:
	var m: Node3D = load("res://scripts/world/sight_marker.gd").new()
	m.set(&"team", 0)
	m.set(&"sight_radius", r)
	m.set(&"lifetime", 0.0)
	main.add_child(m)
	m.global_position = Vector3(pos.x, 0.0, pos.z)
	_markers.append(m)


func _point(n: String) -> Node3D:
	for p in cp.call(&"points"):
		if str(p.get(&"display_name")) == n:
			return p
	return null


func _offset_x() -> float:
	return bar.get_viewport_rect().size.x * 0.5 - 800.0


# ---------------------------------------------------------------- the run

func _run() -> void:
	_backup_settings()
	await _check_settings()
	_check_help()
	main = load(SCENE).instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	if not await _until(func() -> bool: return main.hero != null, 5000):
		_errors.append("navigation never finished baking")
		_finish()
		return
	root.size = Vector2i(1600, 900)
	main.camera_rig.edge_pan_enabled = false   # the headless mouse sits in a corner
	await _frames(10)
	hud = main.hud
	sel = main.selection
	bar = hud.get(&"mapfill_bar")
	panel = hud.get(&"point_panel")
	pop = hud.get(&"mapfill_popups")
	cp = root.get_tree().get_first_node_in_group(&"capture_points_service")
	_expect(bar != null and panel != null and pop != null, "the HUD did not attach the map-fill pieces")
	_expect(cp != null, "no CapturePoints service in the skirmish")
	if bar == null or panel == null or pop == null or cp == null:
		_finish()
		return
	cp.set(&"match_time_source", func() -> float: return clock)
	await _check_messages_and_hint()
	await _check_strip()
	await _check_point_panel()
	await _check_blessing_and_wading()
	await _check_camps()
	await _check_beasts()
	await _check_critters()
	await _check_sounds()
	_check_widths()
	_finish()


# ---------------------------------------------------------------- settings + help (no level)

func _backup_settings() -> void:
	_settings_existed = FileAccess.file_exists(SETTINGS)
	if _settings_existed:
		_settings_backup = FileAccess.get_file_as_bytes(SETTINGS)


func _restore_settings() -> void:
	if _settings_existed:
		var f := FileAccess.open(SETTINGS, FileAccess.WRITE)
		if f:
			f.store_buffer(_settings_backup)
			f.close()
	elif FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	GameSettings.load_settings()


func _check_settings() -> void:
	GameSettings.load_settings()
	GameSettings.reset_defaults()
	_expect(GameSettings.map_detail == &"high", "map_detail default is '%s'" % GameSettings.map_detail)
	GameSettings.set_map_detail(&"low")
	var cfg := ConfigFile.new()
	_expect(cfg.load(SETTINGS) == OK and str(cfg.get_value("settings", "map_detail", "")) == "low",
			"map_detail not saved as \"low\"")
	GameSettings.map_detail = &"high"
	GameSettings.load_settings()
	_expect(GameSettings.map_detail == &"low", "map_detail not loaded back (%s)" % GameSettings.map_detail)
	cfg.set_value("settings", "map_detail", "ultra")
	cfg.save(SETTINGS)
	GameSettings.load_settings()
	_expect(GameSettings.map_detail == &"high", "unknown map_detail text did not load as high")
	GameSettings.map_detail = &"low"
	GameSettings.reset_defaults()
	_expect(GameSettings.map_detail == &"high", "reset_defaults did not set map_detail high")
	# The settings row (main menu / pause menu panel).
	var sp := SettingsPanel.new()
	root.add_child(sp)
	await _frames(2)
	var opt: OptionButton = sp.get(&"map_detail_option")
	_expect(opt != null and opt.item_count == 2 and opt.get_item_text(0) == "High"
			and opt.get_item_text(1) == "Low (faster)", "Map detail option items")
	_expect(opt != null and opt.tooltip_text.begins_with("High: full plants and flowers"), "Map detail tooltip")
	var hint: Label = sp.get(&"map_detail_hint")
	_expect(hint != null and hint.text == "Applies from the next match. Deer and rabbits stay on every setting.",
			"Map detail hint")
	if opt != null:
		opt.select(1)
		opt.item_selected.emit(1)
		_expect(GameSettings.map_detail == &"low", "choosing Low did not set map_detail")
		sp.call(&"close")
		GameSettings.map_detail = &"high"
		GameSettings.load_settings()
		_expect(GameSettings.map_detail == &"low", "Back did not save map_detail")
	sp.queue_free()
	GameSettings.reset_defaults()


func _check_help() -> void:
	var lines := GameHUD.help_text("Vessa").split("\n")
	_expect(lines.size() == 12, "help has %d lines, expected 12" % lines.size())
	_expect(lines[lines.size() - 1] == "Capture: stand near towers, wells and shrines", "the 12th help line")
	var font := ThemeDB.fallback_font
	var widest := 0.0
	for l in lines:
		widest = maxf(widest, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)
	_expect(widest <= 440.0, "widest help line %d px" % widest)


# ---------------------------------------------------------------- messages

func _check_messages_and_hint() -> void:
	# The listener took the three services' message signals over from the level.
	await _frames(40)
	for g: StringName in [&"capture_points_service", &"camp_manager", &"epic_beasts"]:
		var s := root.get_tree().get_first_node_in_group(g)
		if s == null:
			_notes.append("no %s" % g)
			continue
		var mine := false
		var level_too := false
		for c: Dictionary in s.get_signal_connection_list(&"message"):
			var o: Object = (c["callable"] as Callable).get_object()
			mine = mine or o == pop
			level_too = level_too or o == main
		_expect(mine and not level_too, "%s.message: listener %s, level still connected %s" % [g, mine, level_too])
	# The 0:40 hint (no point held).
	clock = 39.0
	await _frames(40)
	_expect(not pop.get(&"hint_done"), "hint shown before 0:40")
	# The hint never replaces a line still on screen (here: in place of the 10 s start hint, which a real match has
	# long hidden by 0:40): it waits for the free line.
	hud.call(&"show_message", "Another line", 2.0)
	clock = 41.0
	await _frames(40)
	_expect(not pop.get(&"hint_done") and str(hud.get(&"_message").text) == "Another line",
			"the 0:40 hint replaced a line still on screen")
	await _until(func() -> bool: return bool(pop.get(&"hint_done")), 180)
	_expect(bool(pop.get(&"hint_shown")) and (pop.get(&"messages") as Array).has(HINT), "no 0:40 hint")
	_expect(str(hud.get(&"_message").text) == HINT, "the hint is not on the message line")
	# The 20 s filter.
	_expect(bool(pop.call(&"route_message", "Your forces captured Rookwatch", 4.0)), "first point line dropped")
	_expect(not bool(pop.call(&"route_message", "Your forces captured Rookwatch", 4.0)), "identical line not dropped")
	_expect(bool(pop.call(&"route_message", "Your forces captured Millwatch", 4.0)), "another point's line dropped")
	# A service line goes through the filter too (the level no longer forwards it).
	cp.emit_signal(&"message", "The Wayshrines awaken", 4.0)
	cp.emit_signal(&"message", "The Wayshrines awaken", 4.0)
	var n := (pop.get(&"messages") as Array).count("The Wayshrines awaken")
	_expect(n == 1 and (pop.get(&"dropped") as Array).has("The Wayshrines awaken"),
			"service line shown %d times through the filter" % n)


# ---------------------------------------------------------------- strip

func _check_strip() -> void:
	await _until(func() -> bool: return (bar.get(&"icons") as Array).size() == 8, 120)
	var icons: Array = bar.get(&"icons")
	_expect(icons.size() == 8, "strip has %d icons" % icons.size())
	if icons.size() != 8:
		return
	var names: Array[String] = []
	for ic in icons:
		names.append(str(ic.point.get(&"display_name")))
	_expect(names == MAP_ORDER, "strip order %s" % [names])
	var strip: Control = bar.get(&"strip")
	var ox := _offset_x()
	var r := strip.get_global_rect()
	_expect(absf(r.position.x - (650.0 + ox)) < 1.0 and absf(r.position.y - 52.0) < 1.0 and r.size == Vector2(300, 50),
			"strip rect %s" % r)
	for i in 8:
		var ir: Rect2 = icons[i].get_global_rect()
		_expect(absf(ir.position.x - (ICON_X[i] + ox)) < 1.0 and absf(ir.position.y - 58.0) < 1.0
				and ir.size == Vector2(28, 28), "icon %d rect %s" % [i, ir])
	var seps: Array = bar.get(&"separators")
	_expect(seps.size() == 2 and absf(float(seps[0]) + 650.0 - 793.0) < 0.6 and absf(float(seps[1]) + 650.0 - 870.0) < 0.6,
			"separators %s" % [seps])
	# Owners.
	cp.set_physics_process(false)   # states are set by hand from here
	var rook := _point("Rookwatch")
	var salt := _point("Saltwatch")
	rook.call(&"set_owner_team", 0)
	salt.call(&"set_owner_team", 1)
	bar.call(&"refresh")
	_expect(_near_color(icons[0].fill, OWN) and _near_color(icons[2].fill, ENEMY) and _near_color(icons[1].fill, NEUTRAL),
			"owner colours %s %s %s" % [icons[0].fill, icons[2].fill, icons[1].fill])
	# Countdowns: wells before 2:30, asleep shrines.
	clock = 60.0
	for s in cp.call(&"points", &"shrine"):
		s.call(&"set_wake_time", 180.0, clock)
	bar.call(&"refresh")
	var cds: Array = bar.get(&"countdowns")
	_expect(cds[4].visible and cds[4].text == "1:30" and cds[5].text == "1:30", "well countdown '%s'" % cds[4].text)
	_expect(cds[6].visible and cds[6].text == "2:00", "shrine countdown '%s'" % cds[6].text)
	_expect(not cds[0].visible, "a tower shows a countdown")
	clock = 145.0
	bar.call(&"refresh")
	_expect(_near_color(cds[4].get_theme_color(&"font_color"), GOLD), "well countdown not GOLD in its last 10 s")
	clock = 60.0
	# Tooltip.
	bar.call(&"refresh")
	var tip: String = icons[0].tooltip_text
	var tl := tip.split("\n")
	_expect(tl.size() >= 4 and tl[0] == "Rookwatch · Watchtower" and tl[1].begins_with("Held by you")
			and tl[2] == "Sight 22 for its owner" and tl[tl.size() - 1] == "Click: centre the camera", "tooltip '%s'" % tip)
	var far_tip := false
	for ic in icons:
		var b := int(ic.point.get(&"bank"))
		var has_far: bool = str(ic.tooltip_text).contains("On the enemy bank: capture takes 25 % longer")
		_expect(has_far == (b == 1), "%s far-bank line %s with bank %d" % [ic.point.get(&"display_name"), has_far, b])
		far_tip = far_tip or has_far
	_expect(far_tip, "no point shows the far-bank tooltip line")
	# Click = centre the camera (never selects).
	var rig: Node3D = main.camera_rig
	icons[0].pressed.emit()
	_expect(Vector2(rig.global_position.x - rook.global_position.x, rig.global_position.z - rook.global_position.z).length()
			< 0.5, "strip click did not centre the camera")
	_expect(sel.get(&"selected_neutral") == null, "strip click selected the point")
	# An own point being taken where the player sees it: WARN rim, progress strip in the capturer's colour.
	_see(rook.global_position)
	await _until(func() -> bool: return FogOfWar.find().is_visible(0, rook.global_position), 60)
	rook.set(&"state", &"neutralising")
	rook.set(&"capture_team", 1)
	rook.set(&"progress", 0.5)
	bar.call(&"refresh")
	var prs: Array = bar.get(&"progress_rects")
	_expect(icons[0].taken and prs[0].visible and absf(prs[0].size.x - 14.0) < 0.6 and _near_color(prs[0].color, ENEMY),
			"taken state / progress strip (%s, %s, %s)" % [icons[0].taken, prs[0].visible, prs[0].size])
	_expect(_near_color(icons[0].rim_color(), WARN), "taken rim is not WARN")
	# Contested: the glyph flashes toward white, no taken rim.
	rook.set(&"state", &"contested")
	bar.call(&"refresh")
	_expect(icons[0].contested and not icons[0].taken, "contested state")
	rook.set(&"state", &"idle")
	rook.set(&"capture_team", -1)
	rook.set(&"progress", 0.0)
	# Owner change pops the icon.
	rook.call(&"set_owner_team", -1)
	bar.call(&"refresh")
	await _frames(4)
	_expect(icons[0].scale.x > 1.01, "owner change did not pop the icon")
	rook.call(&"set_owner_team", 0)
	await _frames(20)
	# Awake shrine: GOLD glyph + rim pulse; the selected rim.
	var west := _point("West Wayshrine")
	west.call(&"wake")
	bar.call(&"refresh")
	_expect(icons[6].awake and _near_color(icons[6].glyph_color(), GOLD), "awake shrine look")
	sel.call(&"select_neutral", west)
	bar.call(&"refresh")
	_expect(icons[6].selected and _near_color(icons[6].rim_color(), GOLD), "selected rim")


# ---------------------------------------------------------------- point panel

func _panel_lines(p: Node3D) -> PackedStringArray:
	sel.call(&"select_neutral", p)
	panel.call(&"refresh")
	return panel.call(&"panel_lines")


func _check_point_panel() -> void:
	var rook := _point("Rookwatch")
	var lines := _panel_lines(rook)
	_expect(panel.visible and panel.get(&"kind") == &"point", "point panel not shown for a point")
	var r: Rect2 = panel.get_global_rect()
	var vp: Vector2 = panel.get_viewport_rect().size
	_expect(absf(r.position.x - 588.0) < 1.0 and absf(r.end.y - (vp.y - 26.0)) < 1.0 and r.size == Vector2(676, 204),
			"point panel rect %s" % r)
	_expect(lines[0] == "ROOKWATCH · watchtower", "title '%s'" % lines[0])
	_expect(lines[1] == "Held by you" and _near_color(panel.call(&"segment_color", 0, "Held"), NEAR), "owner '%s'" % lines[1])
	_expect(lines[2] == "", "idle state line '%s'" % lines[2])
	_expect(lines[3] == "Sight 22 for its owner", "tower effect '%s'" % lines[3])
	_expect(lines[5] == "Capture: stand in the ring with soldiers, champions or your wizard · R: Guard it when yours",
			"hint '%s'" % lines[5])
	# An enemy capture where the player sees it.
	rook.set(&"state", &"neutralising")
	rook.set(&"capture_team", 1)
	rook.set(&"progress", 0.5)
	lines = _panel_lines(rook)
	var t := float(rook.call(&"time_for", 1, 1))
	var want := "The enemy is neutralising %d / %d s" % [floori(0.5 * t), ceili(t)]
	_expect(lines[2] == want and _near_color(panel.call(&"segment_color", 1, "enemy"), WARN), "enemy state '%s' (want '%s')" % [lines[2], want])
	var bar_c: ProgressBar = panel.get(&"capture_bar")
	_expect(bar_c.visible and absf(bar_c.value - 0.5) < 0.01 and bar_c.size == Vector2(200, 10), "capture bar")
	rook.set(&"state", &"capturing")
	rook.set(&"capture_team", 0)
	lines = _panel_lines(rook)
	_expect(lines[2].begins_with("Capturing ") and _near_color(panel.call(&"segment_color", 1, "Capturing"), NEAR),
			"own capture '%s'" % lines[2])
	rook.set(&"state", &"idle")
	lines = _panel_lines(rook)
	_expect(lines[2].begins_with("Capture fading "), "decay '%s'" % lines[2])
	rook.set(&"capture_team", -1)
	rook.set(&"progress", 0.0)
	# Not in sight (a far point the player does not see).
	var owl := _point("Owlwatch")
	lines = _panel_lines(owl)
	if not FogOfWar.find().is_visible(0, owl.global_position):
		_expect(lines[2] == "Not in sight" and lines[1] == "Neutral", "unseen point '%s' / '%s'" % [lines[1], lines[2]])
	# A well before / after 2:30.
	var well := _point("Mossmere Well")
	clock = 60.0
	lines = _panel_lines(well)
	_expect(lines[0] == "MOSSMERE WELL · essence well", "well title '%s'" % lines[0])
	_expect(lines[3] == "+0.4 essence / s · +3 mana / s to your wizard within 8 m  ·  pays from 2:30"
			and _near_color(panel.call(&"segment_color", 2, "pays"), WARN), "well effect before 2:30 '%s'" % lines[3])
	clock = 200.0
	lines = _panel_lines(well)
	_expect(lines[3] == "+0.4 essence / s · +3 mana / s to your wizard within 8 m", "well effect after 2:30 '%s'" % lines[3])
	clock = 60.0
	# Asleep and awake shrines (seen).
	var east := _point("East Wayshrine")
	_see(east.global_position)
	await _until(func() -> bool: return FogOfWar.find().is_visible(0, east.global_position), 60)
	east.call(&"set_wake_time", 180.0, clock)
	lines = _panel_lines(east)
	_expect(lines[2] == "Asleep: wakes in 2:00" and lines[1] == "Not captured yet", "asleep shrine '%s' / '%s'" % [lines[1], lines[2]])
	_expect(lines[3] == "Blessing: +12 % speed, +1.5 HP / s for 60 s", "shrine effect '%s'" % lines[3])
	east.call(&"set_wake_time", INF, clock)
	lines = _panel_lines(east)
	_expect(lines[2] == "Asleep", "unscheduled shrine '%s'" % lines[2])
	east.call(&"wake")
	lines = _panel_lines(east)
	_expect(lines[2] == "Awake: capture it for the blessing" and _near_color(panel.call(&"segment_color", 1, "Awake"), GOLD),
			"awake shrine '%s'" % lines[2])
	# The far-bank line.
	var far_point: Node3D = null
	for p in cp.call(&"points"):
		if int(p.get(&"bank")) == 1:
			far_point = p
			break
	if far_point != null:
		lines = _panel_lines(far_point)
		_expect(lines[4] == "On the enemy bank: capture takes 25 % longer"
				and _near_color(panel.call(&"segment_color", 3, "enemy bank"), FAR), "far-bank line '%s'" % lines[4])
	lines = _panel_lines(rook)
	_expect(lines[4] == "", "own-bank point shows '%s'" % lines[4])
	# Hidden for anything else.
	sel.call(&"select_units", [main.hero])
	panel.call(&"refresh")
	_expect(not panel.visible, "point panel still shown after selecting a unit")


# ---------------------------------------------------------------- blessing + wading

func _check_blessing_and_wading() -> void:
	var west := _point("West Wayshrine")
	var east := _point("East Wayshrine")
	west.emit_signal(&"blessing_granted", west, 0)
	await _frames(2)
	bar.call(&"refresh")
	var texts: PackedStringArray = bar.call(&"blessing_texts")
	_expect(texts.size() == 1 and texts[0] == "Blessing 60 s", "own blessing chip %s" % [texts])
	east.emit_signal(&"blessing_granted", east, 1)
	await _frames(20)   # the start pop (0.2 s) is over
	bar.call(&"refresh")
	texts = bar.call(&"blessing_texts")
	_expect(texts.size() == 2 and texts[1] == "Enemy blessing 60 s", "enemy blessing chip %s" % [texts])
	var chips: Array = bar.get(&"blessing_chips")
	var ox := _offset_x()
	var r0: Rect2 = chips[0].get_global_rect()
	var r1: Rect2 = chips[1].get_global_rect()
	_expect(absf(r0.position.x - (958.0 + ox)) < 1.0 and absf(r0.position.y - 54.0) < 1.0 and r0.size == Vector2(144, 22)
			and absf(r1.position.y - 78.0) < 1.0, "blessing chip rects %s %s" % [r0, r1])
	_expect(str(chips[0].tooltip_text).begins_with("Wayfarer's Blessing 60 s\n+12 % speed"), "own chip tooltip")
	_expect(str(chips[1].tooltip_text).begins_with("Enemy blessing 60 s"), "enemy chip tooltip")
	_expect((pop.get(&"messages") as Array).has("Blessing of the Wayshrine: +12 % speed, +1.5 HP / s for 60 s"),
			"the blessing message did not go through the listener")
	# Unit chips: the hero column, single view.
	var hero: Node = main.hero
	var sp: Node = hud.selection_panel
	await _frames(2)
	var row_text: String = sp.call(&"status_row_text", sp.get(&"hero_statuses"))
	_expect(row_text.contains("Blessing 60"), "hero status row '%s' lacks the blessing" % row_text)
	hero.call(&"add_modifier", &"terrain:ford", {"move_speed_pct": -0.35})
	await _frames(2)
	row_text = sp.call(&"status_row_text", sp.get(&"hero_statuses"))
	_expect(row_text.ends_with("Blessing 60, Wading"), "hero status row '%s' (blessing, wading)" % row_text)
	sel.call(&"select_units", [hero])
	await _frames(2)
	row_text = sp.call(&"status_row_text", sp.get(&"single_statuses"))
	_expect(row_text.contains("Wading"), "single view status row '%s'" % row_text)
	var wade: Control = (sp.get(&"hero_statuses") as Node).get_node(^"mf_wading")
	_expect(wade.tooltip_text == "Wading: -35 % speed" and wade.size == Vector2(20, 20), "wading chip %s" % wade.size)
	var bl: Control = (sp.get(&"hero_statuses") as Node).get_node(^"mf_blessing")
	_expect(str(bl.tooltip_text).begins_with("Wayfarer's Blessing 60 s\n+12 % speed, +1.5 HP / s") and bl.size.x <= 41.0,
			"blessing chip tooltip / size %s" % bl.size)
	hero.call(&"remove_modifier", &"terrain:ford")


# ---------------------------------------------------------------- camps

func _check_camps() -> void:
	var cm := root.get_tree().get_first_node_in_group(&"camp_manager")
	_expect(cm != null, "no CampManager")
	if cm == null:
		return
	var camp: Node3D = cm.call(&"camp", &"camp_wallow_s")
	await _until(func() -> bool: return camp != null and (camp.call(&"creatures") as Array).size() > 0, 300)
	var creatures: Array = camp.call(&"creatures") if camp != null else []
	_expect(creatures.size() == 2, "Bristleback Wallow has %d creatures" % creatures.size())
	if creatures.is_empty():
		return
	_see(camp.global_position, 10.0)
	main.camera_rig.focus_on(camp.global_position)
	var u: Node3D = creatures[0]
	await _until(func() -> bool: return u.is_visible_in_tree(), 90)
	sel.call(&"inspect_unit", u)
	await _frames(3)
	var sp: Node = hud.selection_panel
	var line: String = sp.call(&"camp_line_text")
	_expect(line == "Bristleback Wallow · Tier 1 · 2 of 2 left · ~50 XP · +10 essence · 30 % Ember Draught",
			"camp line '%s'" % line)
	var rows: String = sp.call(&"mapfill_rows_text")
	_expect(rows.split("\n").size() == 2, "camp rows '%s'" % rows)
	# Underdog: shown when the camp manager names the player's team.
	# (Levels are equal at the start: no underdog word.)
	_expect(not rows.contains("Underdog"), "underdog shown with equal wizard levels")
	# The command card shows nothing for a creature.
	_expect(str(hud.command_card.call(&"inspect_text")) == "", "command card text for a creature")
	# The hover chip.
	bar.call(&"show_hover", camp)
	_expect(str(bar.call(&"hover_text")) == "Bristleback Wallow · Tier 1 · ~50 XP · +10 essence",
			"hover chip '%s'" % bar.call(&"hover_text"))
	var chip: Control = bar.get(&"hover_chip")
	_expect(chip.size.y <= 27.0 and chip.size.x <= 320.0, "hover chip size %s" % chip.size)
	var labels: Array = bar.get(&"hover_labels")
	_expect(_near_color(labels[0].get_theme_color(&"font_color"), GOLD)
			and _near_color(labels[1].get_theme_color(&"font_color"), Color(0.85, 0.85, 0.75)), "hover chip colours")
	# A tier-2 camp preview line (the spec's example shape), from its preview.
	var hollow: Node = cm.call(&"camp", &"camp_hollow_nw")
	if hollow != null:
		var parts: Array = bar.call(&"hover_parts", hollow)
		_expect(parts[0] == "Gloomcap Hollow" and parts[1] == " · Tier 2" and str(parts[2]).begins_with(" · ~"),
				"hollow hover parts %s" % [parts])


# ---------------------------------------------------------------- beasts

func _check_beasts() -> void:
	var eb := root.get_tree().get_first_node_in_group(&"epic_beasts")
	_expect(eb != null, "no EpicBeasts")
	if eb == null:
		return
	var roars := int((pop.get(&"sound_counts") as Dictionary)[&"roar"])
	var beast: Node3D = eb.call(&"spawn_now", &"lair_heath_w")
	_expect(beast != null, "spawn_now returned no beast")
	if beast == null:
		return
	await _frames(2)
	_expect(int((pop.get(&"sound_counts") as Dictionary)[&"roar"]) == roars + 1, "no roar on beast_spawned")
	_expect((pop.get(&"messages") as Array).has("An Ironhide Tusker roams the West Heath"), "spawn message not routed")
	_see(beast.global_position, 12.0)
	main.camera_rig.focus_on(beast.global_position)
	await _until(func() -> bool: return beast.is_visible_in_tree(), 90)
	bar.call(&"refresh_bosses")
	var bars: Array = bar.get(&"bars")
	_expect(bars[0].visible and bars[0].target == beast, "no boss bar for an on-screen beast")
	_expect(str(bars[0].call(&"title_text")) == "Ironhide Tusker · Epic beast", "bar title '%s'" % bars[0].call(&"title_text"))
	var ox := _offset_x()
	var br: Rect2 = bars[0].get_global_rect()
	_expect(absf(br.position.x - (572.0 + ox)) < 1.0 and absf(br.position.y - 156.0) < 1.0 and br.size == Vector2(456, 50),
			"boss bar rect %s" % br)
	var hp_bar: ProgressBar = bars[0].get(&"hp_bar")
	_expect(hp_bar.size == Vector2(440, 18), "boss HP bar size %s" % hp_bar.size)
	await _frames(20)
	beast.call(&"take_damage", 300.0, null)
	await _frames(3)
	_expect(float(bars[0].call(&"ghost_value")) > hp_bar.value, "no ghost damage on the boss bar")
	_expect(str((bars[0].get(&"hp_text") as Label).text).contains(" / 1 800"), "bar text '%s'" % (bars[0].get(&"hp_text") as Label).text)
	# Click centres the camera.
	main.camera_rig.focus_on(Vector3.ZERO)
	bars[0].emit_signal(&"clicked", beast)
	_expect(Vector2(main.camera_rig.global_position.x - beast.global_position.x,
			main.camera_rig.global_position.z - beast.global_position.z).length() < 0.5, "boss bar click did not centre")
	# Death: drain, flash, fade.
	beast.call(&"take_damage", 99999.0, main.hero)
	await _frames(2)
	bar.call(&"refresh_bosses")
	_expect(bool(bars[0].get(&"dying")), "the bar did not play the death")
	await _until(func() -> bool: return not bars[0].visible, 120)
	_expect(not bars[0].visible, "the bar did not fade out after the death")
	# Variant B: Old Scarback + the inspect card + the command card.
	var scar: Node3D = eb.call(&"spawn_now", &"lair_heath_w")
	_expect(scar != null, "no second Tusker")
	if scar == null:
		return
	main.camera_rig.focus_on(scar.global_position)
	await _until(func() -> bool: return scar.is_visible_in_tree(), 90)
	bar.call(&"refresh_bosses")
	_expect(str(bars[0].call(&"title_text")) == "Old Scarback · Epic beast · alpha" or
			str(bars[1].call(&"title_text")) == "Old Scarback · Epic beast · alpha", "variant B bar title")
	sel.call(&"inspect_unit", scar)
	await _frames(3)
	var sp: Node = hud.selection_panel
	_expect(str(sp.call(&"beast_title_text")) == "Old Scarback · Epic beast · alpha",
			"inspect title '%s'" % sp.call(&"beast_title_text"))
	var rows: String = sp.call(&"mapfill_rows_text")
	_expect(rows == "Drops: 2 components · 30 % Vital Root\nRoams the West Heath", "beast rows '%s'" % rows)
	_expect(str(sp.call(&"beast_ability_list")) == "Gore Charge, Bristle Hide", "abilities '%s'" % sp.call(&"beast_ability_list"))
	var slots: Array = sp.get(&"beast_slots")
	var sr: Rect2 = slots[0].get_global_rect()
	_expect(absf(sr.position.x - 1000.0) < 1.5 and absf(sr.position.y - (sp.get_viewport_rect().size.y - 224.0)) < 1.5
			and sr.size == Vector2(48, 48), "beast slot rect %s" % sr)
	_expect(str(slots[0].tooltip_text) == "Gore Charge\nEvery 12 s · a target 6-14 m away\n45 damage and dazed 1.2 s to everyone on its path",
			"Old Scarback's Gore Charge tooltip '%s'" % slots[0].tooltip_text)
	_expect(str(hud.command_card.call(&"inspect_text")) == "Epic beast: attack it with your army.\nHunt it with a bounty  [R]",
			"beast command card '%s'" % hud.command_card.call(&"inspect_text"))
	_expect(SelectionPanel.beast_drop_text(&"tusker", 0) == "a component · 30 % Vital Root", "tusker A drops '%s'" % SelectionPanel.beast_drop_text(&"tusker", 0))
	_expect(SelectionPanel.beast_drop_text(&"grizzlemaw", 1) == "a component · 60 % Warden Scale or Vital Root · Warden Scale",
			"elder grizzlemaw drops '%s'" % SelectionPanel.beast_drop_text(&"grizzlemaw", 1))
	# Max 2 bars; engaged ones first.
	var more: Array = [scar]
	for id: StringName in [&"lair_crag_w", &"lair_hollow_w"]:
		var b: Node3D = eb.call(&"spawn_now", id)
		if b != null:
			more.append(b)
			_see(b.global_position, 12.0)
	await _frames(20)
	for b in more:
		bar.call(&"mark_engaged", b)
	bar.call(&"refresh_bosses")
	var shown := 0
	for t in bar.call(&"bar_targets"):
		if t != null:
			shown += 1
	_expect(more.size() < 3 or shown == 2, "%d boss bars with %d engaged beasts (max 2)" % [shown, more.size()])
	if bars[1].visible:
		var r1: Rect2 = bars[1].get_global_rect()
		_expect(absf(r1.position.y - 212.0) < 1.0, "second bar y %d" % r1.position.y)
	sel.call(&"select_units", [main.hero])
	for b in more:
		if is_instance_valid(b):
			b.queue_free()
	await _frames(3)


# ---------------------------------------------------------------- critters

func _check_critters() -> void:
	var herds := root.get_tree().get_first_node_in_group(&"critter_herds")
	_expect(herds != null, "no CritterHerds")
	if herds == null:
		return
	var deer_list: Array = herds.call(&"critters", &"deer")
	var rabbits: Array = herds.call(&"critters", &"rabbit")
	_expect(not deer_list.is_empty() and not rabbits.is_empty(), "no deer / rabbits")
	if deer_list.is_empty():
		return
	var deer: Node3D = deer_list[0]
	_see(deer.global_position, 12.0)
	main.camera_rig.focus_on(deer.global_position)
	await _until(func() -> bool: return deer.is_visible_in_tree(), 120)
	_expect(deer.is_visible_in_tree(), "the deer never became visible")
	sel.call(&"select_neutral", deer)
	panel.call(&"refresh")
	await _frames(2)
	_expect(panel.visible and panel.get(&"kind") == &"critter", "critter card not shown")
	_expect(str(panel.call(&"card_text")) == "Red deer · 60 HP · Hunt it: +5 essence, venison heals the hunter 40 HP",
			"deer card '%s'" % panel.call(&"card_text"))
	var lines: PackedStringArray = panel.call(&"panel_lines")
	_expect(lines[0] == "RED DEER · game", "critter title '%s'" % lines[0])
	_expect(lines[1] == "Hunt it: +5 essence, venison heals the hunter 40 HP", "reward line '%s'" % lines[1])
	_expect(lines[2] == "Your units within 6 m heal 20 HP" and (lines[3] == "Grazing" or lines[3] == "Fleeing"),
			"venison / state lines '%s' / '%s'" % [lines[2], lines[3]])
	_expect(lines[5] == "Right-click with soldiers or your wizard selected to hunt it · workers and caravans ignore it",
			"critter hint '%s'" % lines[5])
	_expect((panel.get(&"hp_text") as Label).text == "HP  60 / 60", "critter HP bar '%s'" % (panel.get(&"hp_text") as Label).text)
	_expect(str(hud.command_card.call(&"inspect_text")) == "Game: hunt it with soldiers or your wizard.",
			"critter command card '%s'" % hud.command_card.call(&"inspect_text"))
	_expect(PointPanel.card_line(rabbits[0], Vector2(40, 20)) == "Rabbit · +1 essence",
			"rabbit card '%s'" % PointPanel.card_line(rabbits[0], Vector2(40, 20)))
	# Hunt it: +5 over the deer, +40 over the hunter 0.15 s later.
	var hero: Node3D = main.hero
	deer.call(&"take_damage", 100.0, hero)
	await _frames(2)
	var texts: PackedStringArray = pop.call(&"active_texts")
	_expect(texts.has("+5") and not texts.has("+40"), "floats right after the kill %s" % [texts])
	var l5: Label3D = pop.call(&"label_of", "+5")
	if l5 != null:
		_expect(_near_color(l5.modulate, Color(0.75, 0.45, 1.0)), "+5 colour %s" % l5.modulate)
	await _frames(12)
	texts = pop.call(&"active_texts")
	_expect(texts.has("+40"), "no +40 over the hunter %s" % [texts])
	var l40: Label3D = pop.call(&"label_of", "+40")
	if l40 != null:
		_expect(_near_color(l40.modulate, NEAR) and l40.global_position.y > hero.global_position.y + 1.5, "+40 look / place")
	_expect(int(pop.call(&"pool_size")) == 6, "pool size %d" % pop.call(&"pool_size"))
	await _frames(70)
	_expect(int(pop.call(&"active_count")) == 0, "floats still up after 1 s")
	# An enemy hunt shows nothing.
	var before := int(pop.call(&"active_count"))
	herds.emit_signal(&"critter_hunted", rabbits[0], 1, {&"essence": 1})
	_expect(int(pop.call(&"active_count")) == before, "enemy hunt showed a float")
	sel.call(&"select_units", [hero])


# ---------------------------------------------------------------- sounds

func _check_sounds() -> void:
	for id: StringName in [&"chime", &"horn", &"bubble", &"drum", &"stag", &"roar"]:
		var p: AudioStreamPlayer = pop.call(&"player_of", id)
		_expect(p != null and p.bus == &"SFX" and p.stream != null, "sound %s: player / bus / stream" % id)
	_expect(absf((pop.call(&"player_of", &"chime") as AudioStreamPlayer).volume_db + 6.0) < 0.01, "chime volume")
	_expect(absf((pop.call(&"player_of", &"roar") as AudioStreamPlayer).volume_db + 8.0) < 0.01, "roar volume")
	_expect(absf((pop.call(&"player_of", &"bubble") as AudioStreamPlayer).volume_db + 12.0) < 0.01, "bubble volume")
	var splashes: Array = pop.call(&"splash_players")
	_expect(splashes.size() == 3 and splashes[0].bus == &"SFX" and absf(splashes[0].volume_db + 18.0) < 0.01
			and absf(splashes[0].max_distance - 60.0) < 0.01, "splash players")
	var counts: Dictionary = pop.get(&"sound_counts")
	var chime := int(counts[&"chime"])
	var rook := _point("Rookwatch")
	cp.emit_signal(&"point_captured", rook, 1)
	_expect(int(counts[&"chime"]) == chime, "chime on an enemy capture")
	cp.emit_signal(&"point_captured", rook, 0)
	_expect(int(counts[&"chime"]) == chime + 1, "no chime on an own capture")
	var horn := int(counts[&"horn"])
	cp.emit_signal(&"shrine_awakened", rook)
	cp.emit_signal(&"shrine_awakened", rook)
	_expect(int(counts[&"horn"]) == horn + 1, "horn not limited to 1 per 2 s")
	# Bubble: an own well on screen from 2:30 (checked every 5 s).
	var well := _point("Mossmere Well")
	well.call(&"set_owner_team", 0)
	main.camera_rig.focus_on(well.global_position)
	clock = 200.0
	var bubble := int(counts[&"bubble"])
	await _until(func() -> bool: return int(counts[&"bubble"]) > bubble, 360)
	_expect(int(counts[&"bubble"]) == bubble + 1, "no bubble for an own well on screen (on screen %s, t %s, owner %s)"
			% [pop.call(&"on_screen", well.global_position), cp.call(&"match_time"), well.get(&"owner_team")])
	# Drum: a camp cleared where the player sees it near the camera.
	var cm := root.get_tree().get_first_node_in_group(&"camp_manager")
	if cm != null:
		var camp: Node3D = cm.call(&"camp", &"camp_wallow_s")
		main.camera_rig.focus_on(camp.global_position)
		await _frames(2)
		var drum := int(counts[&"drum"])
		cm.emit_signal(&"camp_cleared", camp, 0, {})
		_expect(int(counts[&"drum"]) == drum + 1, "no drum on a visible camp clear")
		var far_camp: Node3D = cm.call(&"camp", &"camp_hollow_se")
		if far_camp != null:
			drum = int(counts[&"drum"])
			await _frames(40)
			cm.emit_signal(&"camp_cleared", far_camp, 1, {})
			_expect(int(counts[&"drum"]) == drum, "drum for a far / unseen camp")
	# Splash: the hero on screen starts to wade.
	var hero: Node3D = main.hero
	main.camera_rig.focus_on(hero.global_position)
	await _frames(3)
	var splash := int(pop.get(&"splash_count"))
	hero.call(&"add_modifier", &"terrain:ford", {"move_speed_pct": -0.35})
	await _until(func() -> bool: return int(pop.get(&"splash_count")) > splash, 30)
	_expect(int(pop.get(&"splash_count")) == splash + 1, "no splash when the hero starts to wade")
	hero.call(&"remove_modifier", &"terrain:ford")
	await _frames(15)
	hero.call(&"add_modifier", &"terrain:ford", {"move_speed_pct": -0.35})
	await _frames(15)
	_expect(int(pop.get(&"splash_count")) == splash + 1, "second splash within 4 s for the same unit")
	hero.call(&"remove_modifier", &"terrain:ford")


# ---------------------------------------------------------------- text widths (Font.get_string_size)

func _check_widths() -> void:
	var font := ThemeDB.fallback_font
	var w := func(t: String, size: int) -> float: return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_expect(float(w.call(PointPanel.POINT_HINT, 12)) <= 568.0, "point hint %d px" % w.call(PointPanel.POINT_HINT, 12))
	_expect(float(w.call(PointPanel.CRITTER_HINT, 12)) <= 568.0, "critter hint %d px" % w.call(PointPanel.CRITTER_HINT, 12))
	var stag := "~160 XP · +50 essence · a component · 40 % Warden Scale or Vital Root · Underdog bonus"
	_expect(float(w.call(stag, 13)) <= 568.0, "longest camp reward row %d px" % w.call(stag, 13))
	var chip := 6.0 + 12.0 + 4.0 + float(w.call("Enemy blessing", 12)) + float(w.call(" 60 s", 12)) + 6.0
	_expect(chip <= 144.0, "enemy blessing chip content %d px" % chip)
	var hover := 12.0 + float(w.call("Bristleback Wallow · Tier 1 · ~50 XP · +10 essence", 13))
	_expect(hover <= 320.0, "hover chip %d px" % hover)
	_notes.append("hint %d px at font 22 (pushed under the help panel when > 636)" % w.call(HINT, 22))
