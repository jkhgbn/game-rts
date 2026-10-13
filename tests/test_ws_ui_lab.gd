extends SceneTree
## WS2.U1 UI Lab shot `ws_buy` (ui-wave-strike.md "Done when"): the Wave Strike Muster panel mid-match for Fire and
## Ice (cards bought, the Stronghold up = T3 locked, a ranked line, the held-at-home warning), screenshot + the UI Lab
## checks (UILabChecks, same rules as tools/ui_lab/ui_lab.gd _capture) per resolution and language.
## Windowed only (headless prints a skip PASS; test_ws_ui covers the logic):
##   tools\godot_run.ps1 --path . -s tests/test_ws_ui_lab.gd --quit-after 200000 -- res=1600x900,1920x1080 lang=en,fr
## Writes docs/ui/lab/ws_buy/<lang>/scorecard.md + <WxH>/ws_buy_<kingdom>.jpg and docs/ui/lab/ws_buy_m2.png (1080p Ice,
## English) / ws_buy_m2_fr.png. Prints "PASS ws_ui_lab" (no FAIL) or "FAIL ws_ui_lab: <cells>".

const SCENE := "res://scenes/wave_strike.tscn"
const OUT := "res://docs/ui/lab/ws_buy"

var sizes: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1920, 1080)]
var langs: Array[String] = ["en", "fr"]
var kingdoms: Array[StringName] = [&"fire", &"ice"]
var headless := false
var _fails: Array[String] = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() != 2:
			continue
		match kv[0]:
			"res":
				sizes.clear()
				for r in kv[1].split(",", false):
					var wh := r.split("x")
					sizes.append(Vector2i(int(wh[0]), int(wh[1])))
			"lang":
				langs.clear()
				for l in kv[1].split(",", false):
					langs.append(l)
			"kingdoms":
				kingdoms.clear()
				for k in kv[1].split(",", false):
					kingdoms.append(StringName(k))
	_main.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


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
	var tex := Vector2i(root.get_texture().get_size())
	return Vector2i(mini(tex.x, root.size.x), mini(tex.y, root.size.y))


func _main() -> void:
	headless = DisplayServer.get_name() == "headless"
	if headless:   # a screenshot lab: the headless CI runs test_ws_ui (keys / states / French) instead
		print("PASS ws_ui_lab (skipped: windowed only)")
		quit(0)
		return
	GameSettings.ensure_loaded(self)
	GameSettings.fullscreen = false
	GameSettings.apply_window(self)
	for lang in langs:
		Loc.set_language(lang)
		var report := UILabReport.new()
		report.headless = headless
		report.started = Time.get_datetime_string_from_system(false, true)
		report.notes.append("Language: %s; WS2.U1 Muster panel (tests/test_ws_ui_lab.gd)" % lang)
		var out := OUT.path_join(lang)
		for sz in sizes:
			var res := "%dx%d" % [sz.x, sz.y]
			var got := await _set_window(sz)
			report.actual_sizes[res] = "%dx%d" % [got.x, got.y]
			if got != sz and not headless:
				report.notes.append("%s not reachable (window %dx%d): skipped" % [res, got.x, got.y])
				continue
			report.resolutions.append(res)
			for k in kingdoms:
				var screen := "ws_buy_%s" % k
				if not report.screens.has(screen):
					report.screens.append(screen)
				await _shot(report, screen, res, k, out, lang)
		report.write(out, "")
		for c: Dictionary in report.checks:
			if String(c.get("status", "")) == "FAIL":
				_fails.append("%s %s@%s %s" % [lang, c.get("screen", ""), c.get("res", ""), c.get("type", "")])
		print("WS UI LAB %s: %s (quality %.0f, FAIL %d, WARN %d)" % [lang, report.result(), report.quality(),
				report.count("FAIL"), report.count("WARN")])
	Engine.time_scale = 1.0
	Loc.set_language("en")
	if _fails.is_empty():
		print("PASS ws_ui_lab")
	else:
		print("FAIL ws_ui_lab: %s" % ", ".join(_fails))
	quit(0 if _fails.is_empty() else 1)


func _shot(report: UILabReport, screen: String, res: String, k: StringName, out: String, lang: String) -> void:
	var level: Node = (load(SCENE) as PackedScene).instantiate()
	level.set(&"player_kingdom", k)
	level.set(&"enemy_kingdom", &"shadow" if k != &"shadow" else &"fire")
	MenuFlow.ws_kingdom = k   # MenuFlow's restart hook re-applies its own kingdoms to a WS level entering the tree
	MenuFlow.ws_enemy_resolved = &"shadow" if k != &"shadow" else &"fire"
	root.add_child(level)
	current_scene = level
	var hud: Node = null
	var t := Time.get_ticks_msec()
	while hud == null or hud.get(&"muster") == null:
		await process_frame
		hud = level.get(&"ws_hud")
		if Time.get_ticks_msec() - t > 90000:
			report.notes.append("%s %s: no WS HUD" % [res, k])
			level.queue_free()
			return
	var roster: MusterRoster = hud.get(&"roster")
	var bank: WaveBank = hud.get(&"bank")
	bank.refund(1200)
	for i in [0, 0, 0, 1, 2, 2, 3, 4]:
		hud.call(&"buy_card", i)
	# the match runs to ~1:20 (two horns on the field), then the Stronghold is up: T2 buys, T3 locked
	Engine.time_scale = 6.0
	var director: WaveDirector = hud.get(&"director")
	while director.time < 78.0:
		await process_frame
	Engine.time_scale = 1.0
	roster.tier = 2
	bank.refund(1500)
	for i in [5, 5, 6, 7, 0]:
		hud.call(&"buy_card", i)
	hud.call(&"rank_card", 0)
	(level.get(&"stats") as Array)[0]["held_horn"] = 12
	var cam: Node = level.get(&"camera_rig")
	var lane: PackedVector3Array = level.call(&"lane_for", 0)
	if cam and lane.size() > 1:
		cam.call(&"focus_on", lane[0].lerp(lane[lane.size() - 1], 0.3))
	await _frames(30)
	var muster := hud.get(&"muster") as Control
	var card := (muster.get(&"cards") as Array)[0] as Control
	# hover-free, mid-animation-free shot
	await _frames(40)
	await RenderingServer.frame_post_draw
	var img: Image = null
	if not headless:
		img = root.get_texture().get_image()
		var rel := "%s/%s.jpg" % [res, screen]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.path_join(res)))
		img.save_jpg(ProjectSettings.globalize_path(out.path_join(rel)), 0.9)
		report.shots["%s@%s" % [screen, res]] = rel
		if res == "1920x1080" and k == &"ice":
			img.save_png(ProjectSettings.globalize_path("res://docs/ui/lab/ws_buy_m2%s.png" % ("" if lang == "en" else "_" + lang)))
		# a close crop of the panel for the review
		var sc := float(img.get_width()) / root.get_visible_rect().size.x
		var r := Rect2i(Vector2i(muster.global_position * sc) - Vector2i(8, 16), Vector2i(muster.size * sc) + Vector2i(16, 24))
		r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		img.get_region(r).save_png(ProjectSettings.globalize_path(out.path_join("%s/%s_panel.png" % [res, screen])))
	var gh: Node = level.get(&"hud")
	var controls := UILabChecks.visible_controls(hud)
	var all := controls.duplicate()
	all.append_array(UILabChecks.visible_controls(gh))
	var screen_rect := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	var ov := UILabChecks.find_overflow(controls)
	for it: Dictionary in ov:
		it["fail"] = it.get("kind", "") == "frame" and float(it["value"]) > 6.0
	report.add_items(screen, res, "overflow", ov)
	report.add_items(screen, res, "offscreen", UILabChecks.find_offscreen(controls, screen_rect), true)
	var ol := UILabChecks.find_overlaps(all)
	for it: Dictionary in ol:
		it["fail"] = float(it["value"]) >= 150.0
	report.add_items(screen, res, "overlap", ol)
	report.add_items(screen, res, "font", UILabChecks.find_small_fonts(controls))
	report.add_items(screen, res, "contrast", UILabChecks.find_low_contrast(controls, img))
	var tips: Array[Dictionary] = []
	for it: Dictionary in UILabChecks.find_missing_tooltips(controls):
		it["fail"] = bool(it["short"])
		tips.append(it)
	report.add_items(screen, res, "tooltip", tips)
	report.add_items(screen, res, "gaps", UILabChecks.find_bottom_gaps(all, screen_rect))
	if img != null:
		report.add_items(screen, res, "icons", UILabChecks.find_low_contrast_icons(controls, img))
	report.add_items(screen, res, "edge", UILabChecks.find_edge_crowding(controls, screen_rect))
	print("WS UI LAB: %s @ %s (%s): %d controls, card 1 at %s, roster %s, level %s" % [screen, res, lang, controls.size(),
			card.global_position, roster.kingdom, level.get(&"player_kingdom")])
	level.queue_free()
	await _frames(4)
