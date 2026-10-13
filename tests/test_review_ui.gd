extends SceneTree
## Regression tests for the UI + i18n review (docs/reviews/review-2026-10-08.md, "Review: UI + i18n"): M1-M7, L1-L8.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_review_ui.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS review_ui" or "FAIL review_ui: <reasons>".

const TASK_ID := "review_ui"
const TMP := "user://test_review_ui"

var fails: PackedStringArray = []
var _frame := 0
var _wc: WizardControl
var _panel: SettingsPanel
var _hud: GameHUD
var _en_label := ""
var _tc: ThemeCounter
var _tc_count := 0


func _initialize() -> void:
	GameSettings.use_test_file()
	GameSettings.control_scheme = GameSettings.CONTROLS_HERO_WASD   # M1: the walk keys are live
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP))
	_m2_plural_upgrade()
	_m3_hand_kept_files()
	_m4_m5_overrides()
	_m6_sink_cache()
	_m7_wave_strike()
	_l1_extractor()
	_l2_obsolete()
	_l7_doc_order()
	_l8_lang_arg()
	_wc = WizardControl.new()
	root.add_child(_wc)
	_panel = SettingsPanel.new()
	root.add_child(_panel)
	_hud = GameHUD.new()
	root.add_child(_hud)
	_tc = ThemeCounter.new()
	root.add_child(_tc)


func _process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		2:
			# M1: a walk key held when the tree pauses is forgotten (its key-up never arrives while paused).
			_wc._held[KEY_W] = true
			paused = true
			_tc.count = 0
			UIStyle.set_color_if_changed(_tc, &"font_color", Color.RED)
		3:
			if not _wc._held.is_empty():
				_fail("M1: walk key still held after the pause (%s)" % _wc._held)
			_wc._held[KEY_D] = true
			paused = false
			# M4: theme-changed notifications are queued to the end of the frame: compare across frames.
			if _tc.count < 1 or _tc.get_theme_color(&"font_color") != Color.RED:
				_fail("M4: the first override did not apply")
			_tc_count = _tc.count
			for i in 5:
				UIStyle.set_color_if_changed(_tc, &"font_color", Color.RED)
		4:
			if not _wc._held.is_empty():
				_fail("M1: walk key still held after Resume")
			if _tc.count != _tc_count:
				_fail("M4: same-value overrides still send theme changes (%d -> %d)" % [_tc_count, _tc.count])
			UIStyle.set_color_if_changed(_tc, &"font_color", Color.BLUE)
			if _tc.get_theme_color(&"font_color") != Color.BLUE:
				_fail("M4: a new colour was not applied")
			_l4_l5_settings()
			_l6_heroes_prep()
			_en_label = (_panel._value_rows[0][1] as Label).text
			_hud.set_objective("Settings")
			GameSettings.set_language("fr", false)
		6:
			_l3_after_switch()
			_l6_heroes_check()
			GameSettings.set_language("en", false)
		8:
			if (_panel._value_rows[0][1] as Label).text != _en_label:
				_fail("L3: slider label not back to English spacing: '%s'" % (_panel._value_rows[0][1] as Label).text)
			if _hud._objective.text != "Settings":
				_fail("L3: objective not back to English: '%s'" % _hud._objective.text)
			Loc.set_language("en")
			GameSettings.control_scheme = GameSettings.CONTROLS_CLASSIC
			if fails.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				for f in fails:
					print("  " + f)
				print("FAIL %s: %d problems (first: %s)" % [TASK_ID, fails.size(), fails[0]])
			return true
	return false


func _fail(msg: String) -> void:
	fails.append(msg)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


# M2: an existing singular entry turns plural when the source becomes Loc.tn (merge / import keep the plural).
func _m2_plural_upgrade() -> void:
	var po := I18nPo.new()
	var e := po.add("", "{n} worker")
	e["strs"][0] = "{n} ouvrier"
	var e2 := po.add("", "{n} worker", "{n} workers")
	if e2 != e or String(e2["plural"]) != "{n} workers" or (e2["strs"] as PackedStringArray).size() != 2:
		_fail("M2: add() did not upgrade the singular entry to plural (%s)" % e2)
	if String(e2["strs"][0]) != "{n} ouvrier":
		_fail("M2: upgrading to plural lost msgstr[0]")
	var text := po.to_text()
	if not text.contains("msgid_plural \"{n} workers\"") or not text.contains("msgstr[1]"):
		_fail("M2: the written entry has no plural form")


# M3: the hand-kept French files (not areas) are checked too; a '#' dropped in a template is caught.
func _m3_hand_kept_files() -> void:
	var path := TMP.path_join("bad_templates.po")
	_write(path, "msgid \"\"\nmsgstr \"\"\n\"Language: fr_CA\\n\"\n\nmsgid \"Stronghold #: # s left (# crystals)\"\n"
			+ "msgstr \"Forteresse # : # s restantes\"\n\nmsgid \"Knives from the %s!\"\nmsgstr \"Couteaux %d !\"\n")
	var probs := I18nExtract.check_french_file(path, "bad_templates")
	if probs.size() != 2:
		_fail("M3: check_french_file found %d problems in the bad file (want 2: '#' count, printf): %s" % [probs.size(), probs])
	var files := Loc.po_files("fr")
	for need in ["game_logic_templates.po", "story_e4_e8.po"]:
		var found := false
		for p in files:
			found = found or p.ends_with(need)
		if not found:
			_fail("M3: %s not among Loc.po_files" % need)
	var src := FileAccess.get_file_as_string("res://tools/i18n/i18n_extract.gd")
	var body := src.substr(src.find("func check_french()"), 600)
	if not body.contains("Loc.po_files(\"fr\")"):
		_fail("M3: check_french does not loop over the non-area .po files")


# M4 / M5: overrides set only when they change (theme_changed fires once), and the per-frame refresh paths use it.
func _m4_m5_overrides() -> void:
	var cc := FileAccess.get_file_as_string("res://scripts/ui/command_card.gd")
	var refresh := cc.substr(cc.find("func refresh() -> void:"), 5000)
	refresh = refresh.substr(0, refresh.find("\nfunc ", 10))
	for bad in ["add_theme_color_override(c,", "cost_tags[i].add_theme_color_override", "near_chips[i].add_theme_color_override",
			"key_labels[i].add_theme_font_size_override"]:
		if refresh.contains(bad):
			_fail("M4: command_card.refresh still calls %s every tick" % bad)
	var sp := FileAccess.get_file_as_string("res://scripts/ui/selection_panel.gd")
	if sp.contains("single_name.text += "):
		_fail("M5: single_name text still built in two steps every frame")
	var seg := sp.substr(sp.find("func _set_segments("), 900)
	if seg.contains("l.add_theme_color_override"):
		_fail("M5: _set_segments still re-applies the colour every frame")


class ThemeCounter extends Label:
	var count := 0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_THEME_CHANGED:
			count += 1


# M6: no full flush; volatile (digit) strings never push the static ones out; clocks are not cached.
func _m6_sink_cache() -> void:
	Loc.set_language("fr")
	var stat := "Settings"
	Loc.sink(stat)
	if not Loc.sink_cached(stat):
		_fail("M6: a static string is not cached")
	for i in 3000:
		Loc.sink("Must be within %d m of your keep" % i)
	if not Loc.sink_cached(stat):
		_fail("M6: 3000 live-number strings flushed the static cache entry")
	if Loc.sink_cache_size() > Loc.SINK_CACHE_MAX + Loc.VOLATILE_CACHE_MAX:
		_fail("M6: cache over its bound (%d)" % Loc.sink_cache_size())
	var before := Loc.sink_cache_size()
	for s in 120:
		Loc.sink("%d:%02d" % [s / 60, s % 60])
	if Loc.sink_cache_size() != before:
		_fail("M6: clock strings are cached (%d -> %d)" % [before, Loc.sink_cache_size()])
	var sunk := Loc.sink("Must be within 77 m of your keep")
	if not sunk.contains("77") or sunk == "Must be within 77 m of your keep":
		_fail("M6: numeric template broken: '%s'" % sunk)
	Loc.set_language("en")


# M7: the Wave Strike HUD lines go through Loc and their French exists. WS2.U1 (2026-10-13) moved the buy panel into
# MusterPanel (the M1 lines "[%s] %s ... pop" / "[%s] Coffer ..." are gone): the top strip stays in wave_strike_hud.gd.
func _m7_wave_strike() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/ui/wave_strike/wave_strike_hud.gd") 			+ FileAccess.get_file_as_string("res://scripts/ui/wave_strike/muster_panel.gd")
	for msg in ["Crystals %d   ·   +%d / horn", "Supply  %d / %d", "Coffer %d / %d", "Coffers: all %d bought",
			"%s rising: %d s", "Horn %d in %s", "Ctrl+%s: %s for %d"]:
		if not src.contains("Loc.t(\"" + msg):
			_fail("M7: Wave Strike HUD shows '%s' without Loc.t" % msg)
	for reason in ["Loc.sink(cwhy)", "Loc.sink(twhy)", "Loc.sink(why)"]:
		if not src.contains(reason):
			_fail("M7: refusal reason not through Loc.sink (%s)" % reason)
	Loc.set_language("fr")
	if Loc.t("Coffers: all %d bought") == "Coffers: all %d bought":
		_fail("M7: no French for 'Coffers: all %d bought'")
	Loc.set_language("en")


# L1: contexts with quotes / commas in the args, and Loc.tn with its first literal on a far-indented next line.
func _l1_extractor() -> void:
	var path := TMP.path_join("l1_source.gd")
	_write(path, "func f(n: int) -> void:\n"
			+ "\tvar a := Loc.t(\"Hello {who} there\", {\"who\": \"a, b\", \"n\": 5}, \"greet\")\n"
			+ "\tvar b := Loc.tn(\n\t\t\t\t\t\t\t\t\"{n} apple\", \"{n} apples\", n, {\"x\": \"y\"}, \"fruit\")\n"
			+ "\tvar c := Loc.sink(\"Gone fishing\", \"lake\")\n")
	var ex := I18nExtract.new()
	ex.quiet = true
	ex.keys["t"] = I18nPo.new()
	ex._scan_gd("t", path)
	var po: I18nPo = ex.keys["t"]
	if not po.has("greet", "Hello {who} there"):
		_fail("L1: Loc.t context lost with a dictionary args (%s)" % _ids(po))
	var apple := po.find("fruit", "{n} apple")
	if apple.is_empty() or String(apple["plural"]) != "{n} apples":
		_fail("L1: Loc.tn on the next line lost its plural / context (%s)" % _ids(po))
	if po.has("", "{n} apples") or po.has("", "{n} apple"):
		_fail("L1: Loc.tn literals also extracted as plain msgids")
	if not po.has("lake", "Gone fishing"):
		_fail("L1: Loc.sink context lost (%s)" % _ids(po))


func _ids(po: I18nPo) -> String:
	var out: PackedStringArray = []
	for e in po.entries:
		out.append("%s|%s|%s" % [e["ctx"], e["id"], e["plural"]])
	return ", ".join(out)


# L2: obsolete entries are written as "#~" (Godot skips them) and read back as obsolete.
func _l2_obsolete() -> void:
	var po := I18nPo.new()
	var e := po.add("", "Old line")
	e["strs"][0] = "Vieille ligne"
	e["flags"].append("obsolete")
	var text := po.to_text()
	if not text.contains("#~ msgid \"Old line\"") or text.contains("#, obsolete"):
		_fail("L2: obsolete entry not written as #~ lines")
	var back := I18nPo.new()
	back.parse(text)
	var e2 := back.find("", "Old line")
	if e2.is_empty() or not (e2["flags"] as PackedStringArray).has("obsolete") or String(e2["strs"][0]) != "Vieille ligne":
		_fail("L2: #~ entry not read back as obsolete (%s)" % e2)
	var path := TMP.path_join("l2.po")
	_write(path, text)
	var tr := load(path) as Translation
	if tr != null and tr.get_message("Old line") != "":
		_fail("L2: Godot still loads the obsolete entry")
	for f in Loc.po_files("fr"):
		if FileAccess.get_file_as_string(f).contains("#, obsolete"):
			_fail("L2: %s still has '#, obsolete' entries Godot would load" % f.get_file())
	var gl := load("res://data/i18n/fr/game_logic.po") as Translation
	if gl != null and gl.get_message("Ysolde has fallen, the forest will regrow her") != "":
		_fail("L2: the obsolete game_logic entry is still live")


# L3 (part 1) is checked after the language switch; L4 / L5 here.
func _l4_l5_settings() -> void:
	if _panel.apply_changed(&"master_volume") != "audio" or _panel.apply_changed(&"edge_pan") != "edge_pan" \
			or _panel.apply_changed(&"control_scheme") != "" or _panel.apply_changed(&"ui_scale") != "window":
		_fail("L4: a settings step does not apply only its own part")
	var src := FileAccess.get_file_as_string("res://scripts/ui/menus/settings_panel.gd")
	var changed := src.substr(src.find("func _changed("), 2500)
	changed = changed.substr(0, changed.find("\nfunc ", 10))
	if changed.contains("GameSettings.apply(get_tree())"):
		_fail("L4: _changed still re-applies every setting")
	# L5: close the game window with the panel open -> the change is saved.
	GameSettings.reset_defaults()
	GameSettings.save_settings()
	_panel.refresh()
	_panel.master_slider.value = 37.0
	_panel.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	GameSettings.master_volume = 1.0
	GameSettings.load_settings()
	if absf(GameSettings.master_volume - 0.37) > 0.001:
		_fail("L5: closing the window with the panel open lost the change (%.2f)" % GameSettings.master_volume)
	_panel.master_slider.value = 75.0


func _l3_after_switch() -> void:
	var lbl := (_panel._value_rows[0][1] as Label).text
	if not lbl.contains(" %"):
		_fail("L3: slider label kept the English spacing after the switch: '%s'" % lbl)
	if _hud._objective.text == "Settings" and Loc.sink("Settings") != "Settings":
		_fail("L3: HUD objective stayed English after the switch")
	var sp := SelectionPanel.new()
	sp._chip_buildings = [Node.new(), null]
	var n: Node = sp._chip_buildings[0]
	sp.notification(Node.NOTIFICATION_TRANSLATION_CHANGED)
	if sp._chip_buildings[0] != null:
		_fail("L3: building-chip tooltips not rebuilt on a language switch")
	n.free()
	sp.free()


var _fake_hero: Node


func _l6_heroes_prep() -> void:
	_fake_hero = Node.new()
	_fake_hero.set_meta(&"x", 1)
	_fake_hero.add_to_group(&"heroes")
	root.add_child(_fake_hero)
	_hud._refresh_heroes()
	_hud._hero_levels[_fake_hero.get_instance_id()] = 1
	_fake_hero.free()


func _l6_heroes_check() -> void:
	_hud._refresh_heroes()
	if not _hud._hero_levels.is_empty():
		_fail("L6: _hero_levels keeps freed wizards (%s)" % _hud._hero_levels)
	var src := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var body := src.substr(src.find("func _check_hero_levels()"), 400)
	if body.contains("get_nodes_in_group"):
		_fail("L6: the heroes group is still read every frame")


# L7: localization.md lists the areas in the real AREAS order.
func _l7_doc_order() -> void:
	var doc := FileAccess.get_file_as_string("res://docs/design/localization.md")
	var last := -1
	for area: Dictionary in I18nExtract.AREAS:
		var at := doc.find("| %s |" % area["id"])
		if at < 0:
			_fail("L7: area %s missing from localization.md" % area["id"])
			continue
		if at < last:
			_fail("L7: localization.md lists %s out of the AREAS order" % area["id"])
		last = at


# L8: --lang=fr_CA / FR-ca -> French.
func _l8_lang_arg() -> void:
	for v in ["fr_CA", "FR-ca", "fr", " fr "]:
		if Loc.lang_from_arg(v) != "fr":
			_fail("L8: --lang=%s gives '%s'" % [v, Loc.lang_from_arg(v)])
	if Loc.lang_from_arg("de") != "en" or Loc.lang_from_arg("en_US") != "en":
		_fail("L8: unknown / English values do not give English")
