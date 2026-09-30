extends SceneTree
## UI LAB: screenshots every screen at several resolutions and checks the UI (docs/plan/ui-lab.md is the manual).
## Windowed (screenshots + pixel contrast; headless runs the Control checks only, contrast from style boxes):
##   & tools/godot_run.ps1 --path . -s res://tools/ui_lab/ui_lab.gd --quit-after 200000 '--' 'res=1600x900,1920x1080,3440x1440'
## Args after `--` (key=value):
##   res       comma list of WxH (default 1600x900,1920x1080,3440x1440)
##   screens   comma list (default all): main_menu, skirmish_setup, settings, hud, hud_keep, hud_caster, pause, end_score
##             (hud_keep = the keep card at the Stronghold, B = the caster; hud_caster = a caster card, Z / V spells:
##             caster-units.md CU.L1)
##   out       output folder (default res://docs/ui/lab): scorecard.md / .json, <WxH>/<screen>.jpg
##   match_s   match time before the HUD shot (default 60)     timescale  game speed while waiting (default 8)
##   ui_scale  UI scale forced for the run (default 1.0; the saved setting is never written)
##   log=0     no improvement-log row
## Exit code: 0 PASS / WARN, 1 FAIL, 2 bad arguments, 3 watchdog. Last lines: the result and each FAIL / WARN cell.

const WATCHDOG_S := 900.0
const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const ALL_SCREENS: Array[String] = ["main_menu", "skirmish_setup", "settings", "hud", "hud_keep", "hud_caster", "pause",
		"end_score"]
const MENU_SCREENS: Array[String] = ["main_menu", "skirmish_setup", "settings"]
const GAME_SCREENS: Array[String] = ["hud", "hud_keep", "hud_caster", "pause", "end_score"]

var report := UILabReport.new()
var out_dir := "res://docs/ui/lab"
var headless := false
var match_s := 60.0
var timescale := 8.0
var ui_scale := 1.0
var write_log := true
var _t0 := 0
var _thumbs := {}   # "screen@res" -> Image (THUMB_W wide)
const THUMB_W := 480
const BORDER := 4
const SHEET_BG := Color(0.07, 0.06, 0.08)
const STATUS_COLORS := {"FAIL": Color(0.9, 0.2, 0.2), "WARN": Color(0.95, 0.65, 0.15), "PASS": Color(0.3, 0.75, 0.35)}


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	_t0 = Time.get_ticks_msec()
	create_timer(WATCHDOG_S, true, false, true).timeout.connect(func() -> void:
		print("UI LAB ERROR: watchdog (%d s)" % int(WATCHDOG_S))
		Engine.time_scale = 1.0
		quit(3))
	var args := _parse(OS.get_cmdline_user_args())
	if args.has("error"):
		print("UI LAB ERROR: %s" % args["error"])
		quit(2)
		return
	headless = DisplayServer.get_name() == "headless"
	report.headless = headless
	report.started = Time.get_datetime_string_from_system(false, true)
	var sizes: Array[Vector2i] = args["res"]
	var screens: Array[String] = args["screens"]
	report.screens = screens
	GameSettings.ensure_loaded(self)
	GameSettings.fullscreen = false   # static only: the saved file is never written
	GameSettings.ui_scale = ui_scale
	GameSettings.apply_window(self)
	for sz in sizes:
		var res := "%dx%d" % [sz.x, sz.y]
		report.resolutions.append(res)
		var got: Vector2i = await _set_window(sz)
		report.actual_sizes[res] = "%dx%d" % [got.x, got.y]
		if got != sz and not headless:
			# A size the screen cannot show is skipped, not faked: its layout would be the smaller one's.
			var scr := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
			report.notes.append("**%s NOT CHECKED**: the window came out %dx%d (screen %dx%d). Run this size on a screen at least that big (desktop ultrawide)." % [
				res, got.x, got.y, scr.x, scr.y])
			print("UI LAB WARNING: %s not reachable on this %dx%d screen (window %dx%d): skipped" % [res, scr.x, scr.y, got.x, got.y])
			for sc in screens:
				report.add_skip(sc, res, "overflow", "screen too small for %s (got %dx%d)" % [res, got.x, got.y])
			continue
		print("UI LAB: %s (window %dx%d)" % [res, got.x, got.y])
		await _run_resolution(res, screens)
	Engine.time_scale = 1.0
	paused = false
	report.seconds = (Time.get_ticks_msec() - _t0) / 1000.0
	_write_contact_sheet()
	report.write(out_dir, out_dir.path_join("improvement-log.md") if write_log else "")
	_print_summary()
	quit(report.exit_code())


func _parse(args: PackedStringArray) -> Dictionary:
	var sizes: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(3440, 1440)]
	var screens: Array[String] = ALL_SCREENS.duplicate()
	for a in args:
		var kv := a.split("=", true, 1)
		if kv.size() != 2:
			continue
		match kv[0]:
			"res":
				sizes.clear()
				for r in kv[1].split(",", false):
					var wh := r.to_lower().split("x")
					if wh.size() != 2 or not wh[0].is_valid_int() or not wh[1].is_valid_int():
						return {"error": "bad res '%s' (use 1920x1080)" % r}
					sizes.append(Vector2i(int(wh[0]), int(wh[1])))
			"screens":
				screens.clear()
				for s in kv[1].split(",", false):
					if not ALL_SCREENS.has(s):
						return {"error": "unknown screen '%s' (known: %s)" % [s, ", ".join(ALL_SCREENS)]}
					screens.append(s)
			"out":
				out_dir = kv[1]
			"match_s":
				match_s = float(kv[1])
			"timescale":
				timescale = maxf(1.0, float(kv[1]))
			"ui_scale":
				ui_scale = clampf(float(kv[1]), 0.5, 2.0)
			"log":
				write_log = kv[1] != "0"
	return {"res": sizes, "screens": screens}


## Resizes the window (borderless at the screen origin when it is as big as the screen). Returns the size obtained.
func _set_window(sz: Vector2i) -> Vector2i:
	if headless:
		root.size = sz
		await _frames(2)
		return root.size
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var scr := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var big := sz.x >= scr.x - 20 or sz.y >= scr.y - 60
	root.borderless = big
	root.size = sz
	var origin := DisplayServer.screen_get_position(DisplayServer.window_get_current_screen())
	root.position = origin if big else origin + (scr - sz) / 2
	await _frames(8)
	# root.size keeps the requested size even when the OS clamps the window to the screen (laptop 1920x1080 asked
	# for 3440x1440: v1 reported "3440x1440" and checked a 1920 layout). The rendered texture is the truth.
	var tex := Vector2i(root.get_texture().get_size())
	var win := DisplayServer.window_get_size()
	return Vector2i(mini(mini(tex.x, win.x), root.size.x), mini(mini(tex.y, win.y), root.size.y))


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _real_wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _run_resolution(res: String, screens: Array[String]) -> void:
	paused = false
	Engine.time_scale = 1.0
	change_scene_to_file(MAIN_MENU)
	await _frames(12)
	var menu := current_scene
	if menu == null or not menu.has_method(&"show_main"):
		report.notes.append("%s: the main menu did not load" % res)
		return
	if screens.has("main_menu"):
		menu.call(&"show_main")
		await _frames(8)
		await _capture("main_menu", res, menu)
	if screens.has("skirmish_setup"):
		menu.call(&"show_skirmish_setup")
		await _frames(8)
		await _capture("skirmish_setup", res, menu)
	if screens.has("settings"):
		menu.call(&"show_settings")
		await _frames(8)
		var sp: Node = menu.get(&"settings_panel")
		await _capture("settings", res, sp if sp != null else menu)
	var wants_game := false
	for s in GAME_SCREENS:
		if screens.has(s):
			wants_game = true
	if not wants_game:
		return
	menu.call(&"show_main")
	var level: Node = menu.call(&"start_skirmish")
	if level == null:
		report.notes.append("%s: the skirmish did not start" % res)
		return
	# Wait for the navmesh bake (match_started), then run the clock to match_s at `timescale`.
	var t := Time.get_ticks_msec()
	while not bool(level.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t > 90000:
			report.notes.append("%s: the skirmish never started (navmesh bake > 90 s)" % res)
			return
	Engine.time_scale = timescale
	t = Time.get_ticks_msec()
	while float(level.call(&"match_time")) < match_s:
		await process_frame
		if Time.get_ticks_msec() - t > 120000:
			report.notes.append("%s: match clock stuck at %.0f s" % [res, float(level.call(&"match_time"))])
			break
	Engine.time_scale = 1.0
	var hud: Node = level.get(&"hud")
	if hud == null:
		report.notes.append("%s: the skirmish has no HUD" % res)
		return
	_select_player_units(level)
	await _frames(20)
	if screens.has("hud"):
		await _capture("hud", res, hud, level)
	if screens.has("hud_keep"):
		await _capture_keep_card(res, hud, level)
	if screens.has("hud_caster"):
		await _capture_caster_card(res, hud, level)
	var pause: Node = null
	for c in level.get_children():
		if c.has_method(&"open") and c.has_method(&"can_open") and c is CanvasLayer:
			pause = c
	if screens.has("pause"):
		if pause == null:
			report.notes.append("%s: no pause menu under the level" % res)
		else:
			pause.call(&"open")
			await _frames(8)
			await _capture("pause", res, pause)
			pause.call(&"close")
			await _frames(2)
	if screens.has("end_score") and level.has_method(&"surrender"):
		level.call(&"surrender", Unit.Team.PLAYER)
		await _real_wait(1.2)
		await _frames(4)
		var ep: Node = hud.get(&"end_panel")
		await _capture("end_score", res, ep if ep != null else hud)


## caster-units.md CU.L1: the player's keep at the Stronghold (the caster on B, Set Rally r3c1), captured as "hud_keep".
func _capture_keep_card(res: String, hud: Node, level: Node) -> void:
	var sel: Node = level.get(&"selection")
	var keep: Node = level.call(&"keep_of", Unit.Team.PLAYER) if level.has_method(&"keep_of") else level.get(&"keep")
	if sel == null or keep == null:
		report.notes.append("%s: no keep to show" % res)
		return
	var ts := TierSystem.instance()
	if ts:
		ts.set_tier(Unit.Team.PLAYER, 2)
	sel.call(&"select_building", keep)
	await _frames(12)
	await _capture("hud_keep", res, hud, level)


## caster-units.md CU.L1: a caster of the player's kingdom selected (M C H A + Z V), captured as "hud_caster".
func _capture_caster_card(res: String, hud: Node, level: Node) -> void:
	var sel: Node = level.get(&"selection")
	var keep: Node3D = level.call(&"keep_of", Unit.Team.PLAYER) if level.has_method(&"keep_of") else level.get(&"keep")
	var k: StringName = StringName(str(level.call(&"kingdom_of", Unit.Team.PLAYER))) if level.has_method(&"kingdom_of") else &"fire"
	var t := UnitType.find(String(CasterKit.caster_for(k)))
	if sel == null or keep == null or t == null:
		report.notes.append("%s: no caster to show" % res)
		return
	var u := t.create_unit()
	u.team = Unit.Team.PLAYER
	level.add_child(u)
	u.global_position = keep.global_position - Vector3(keep.global_position.x, 0, keep.global_position.z).normalized() * 12.0
	u.command_stop()
	sel.call(&"select_units", [u])
	await _frames(12)
	await _capture("hud_caster", res, hud, level)
	u.queue_free()
	await _frames(2)


## Selects the player's commandable units (the wizard and the workers at 1:00): the selection panel and command card
## show a mixed group.
func _select_player_units(level: Node) -> void:
	var sel: Node = level.get(&"selection")
	if sel == null:
		return
	var units: Array = []
	for u in get_nodes_in_group(&"units"):
		if int(u.get(&"team")) == Unit.Team.PLAYER and u.has_method(&"is_alive") and u.call(&"is_alive") \
				and (not u.has_method(&"is_commandable") or u.call(&"is_commandable")):
			units.append(u)
	sel.call(&"select_units", units)


func _capture(screen: String, res: String, scope: Node, level: Node = null) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = null
	if not headless:
		img = root.get_texture().get_image()
		if img != null and not img.is_empty():
			var rel := "%s/%s.jpg" % [res, screen]
			var path := out_dir.path_join(rel)
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			img.save_jpg(ProjectSettings.globalize_path(path), 0.85)
			report.shots["%s@%s" % [screen, res]] = rel
			var thumb := img.duplicate() as Image
			thumb.convert(Image.FORMAT_RGB8)
			thumb.resize(THUMB_W, maxi(1, int(round(float(THUMB_W) * img.get_height() / img.get_width()))),
					Image.INTERPOLATE_BILINEAR)
			_thumbs["%s@%s" % [screen, res]] = thumb
		else:
			img = null
	var controls := UILabChecks.visible_controls(scope)
	var screen_rect := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	var in_game := screen.begins_with("hud")
	# 1. overflow: sticking out of the frame by > 6 px = FAIL, cut text = WARN.
	var ov := UILabChecks.find_overflow(controls)
	for it: Dictionary in ov:
		it["fail"] = it.get("kind", "") == "frame" and float(it["value"]) > 6.0
	report.add_items(screen, res, "overflow", ov)
	report.add_items(screen, res, "offscreen", UILabChecks.find_offscreen(controls, screen_rect), true)
	var ol := UILabChecks.find_overlaps(controls)
	for it: Dictionary in ol:
		it["fail"] = float(it["value"]) >= 150.0
	report.add_items(screen, res, "overlap", ol)
	report.add_items(screen, res, "font", UILabChecks.find_small_fonts(controls))
	report.add_items(screen, res, "contrast", UILabChecks.find_low_contrast(controls, img))
	# Tooltips: every button in game (short / icon ones FAIL), only short ones on menus.
	var tips: Array[Dictionary] = []
	for it: Dictionary in UILabChecks.find_missing_tooltips(controls):
		it["fail"] = bool(it["short"])
		if in_game or bool(it["short"]):
			tips.append(it)
	report.add_items(screen, res, "tooltip", tips)
	if screen.begins_with("hud"):
		var hk: Array[Dictionary] = []
		var card: Node = scope.get(&"command_card")
		if card != null:
			for it: Dictionary in UILabChecks.find_duplicate_badges(card.get(&"key_labels")):
				it["fail"] = true
				hk.append(it)
		var wname := "Your wizard"
		if level != null and level.get(&"hero") != null:
			wname = GameHUD.wizard_short_name(level.get(&"hero"))
		hk.append_array(UILabChecks.find_duplicate_help_keys(GameHUD.help_text(wname)))
		report.add_items(screen, res, "hotkeys", hk)
	# v2 checks (lab review 2026-09-27)
	if in_game:
		report.add_items(screen, res, "gaps", UILabChecks.find_bottom_gaps(controls, screen_rect))
	if screen in ["pause", "end_score", "settings"]:
		report.add_items(screen, res, "bleed", UILabChecks.find_bleed_through(scope, UILabChecks.visible_controls(root)))
	if img != null:
		report.add_items(screen, res, "icons", UILabChecks.find_low_contrast_icons(controls, img))
	else:
		report.add_skip(screen, res, "icons", "headless: needs the screenshot")
	report.add_items(screen, res, "edge", UILabChecks.find_edge_crowding(controls, screen_rect))
	print("UI LAB: %s @ %s: %d controls checked" % [screen, res, controls.size()])


## contact_sheet.jpg: one row per resolution (top to bottom in run order), one column per screen (in `screens`
## order), each shot framed in its worst status colour (red FAIL, orange WARN, green PASS).
func _write_contact_sheet() -> void:
	if _thumbs.is_empty():
		return
	var cols := report.screens.size()
	var row_h: Array[int] = []
	for res in report.resolutions:
		var h := 0
		for sc in report.screens:
			var t: Image = _thumbs.get("%s@%s" % [sc, res])
			if t != null:
				h = maxi(h, t.get_height())
		row_h.append(h)
	var total_h := BORDER
	for h in row_h:
		total_h += h + 3 * BORDER
	var sheet := Image.create(cols * (THUMB_W + 3 * BORDER) + BORDER, total_h, false, Image.FORMAT_RGB8)
	sheet.fill(SHEET_BG)
	var y := BORDER
	for r in report.resolutions.size():
		var res: String = report.resolutions[r]
		for c in cols:
			var sc: String = report.screens[c]
			var t: Image = _thumbs.get("%s@%s" % [sc, res])
			if t == null:
				continue
			var x := BORDER + c * (THUMB_W + 3 * BORDER)
			var worst := "PASS"
			for chk: Dictionary in report.checks:
				if chk["screen"] == sc and chk["res"] == res:
					if chk["status"] == "FAIL" or (chk["status"] == "WARN" and worst == "PASS"):
						worst = chk["status"]
			sheet.fill_rect(Rect2i(x, y, THUMB_W + 2 * BORDER, t.get_height() + 2 * BORDER), STATUS_COLORS[worst])
			sheet.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(x + BORDER, y + BORDER))
		y += row_h[r] + 3 * BORDER
	var path := ProjectSettings.globalize_path(out_dir.path_join("contact_sheet.jpg"))
	sheet.save_jpg(path, 0.85)
	report.shots["contact_sheet"] = "contact_sheet.jpg"


func _print_summary() -> void:
	for c: Dictionary in report.checks:
		if c["status"] == "FAIL" or c["status"] == "WARN":
			var ex := ""
			if not (c["items"] as Array).is_empty():
				var it: Dictionary = (c["items"] as Array)[0]
				for cand: Dictionary in c["items"]:
					if bool(cand["fail"]):
						it = cand
						break
				ex = " e.g. %s: %s" % [it["text"], it["detail"]]
			print("  %s %s @ %s %s x%d%s" % [c["status"], c["screen"], c["res"], c["type"], int(c["count"]), ex])
	print("UI LAB: %s quality %.0f (%d FAIL, %d WARN, %d PASS) -> %s" % [report.result(), report.quality(),
		report.count("FAIL"), report.count("WARN"), report.count("PASS"), out_dir.path_join("scorecard.md")])
