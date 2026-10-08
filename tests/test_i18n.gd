extends SceneTree
## Localization (docs/design/localization.md): keys, French coverage of the converted areas, placeholders, plurals,
## glyphs, typography, live switching on the main menu and the settings round trip.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_i18n.gd --quit-after 3000
## Prints "PASS i18n" or "FAIL i18n: <reasons>".

const TASK_ID := "i18n"
const FONTS: Array[String] = ["res://assets/fonts/Alegreya-VF.ttf", "res://assets/fonts/Alegreya-Italic-VF.ttf",
		"res://assets/fonts/Cinzel-VF.ttf"]
## The accents French needs (task list + capitals) and the typography characters the .po files use.
const FRENCH_GLYPHS := "éèêëàâçîïôûùüÿœæÉÈÊÀÂÇÎÔÛŒ«»’ "

var fails: PackedStringArray = []
var _frames := 0
var _menu: Node


func _initialize() -> void:
	GameSettings.use_test_file()
	_static_checks()
	_menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(_menu)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		_switch_checks()
	if _frames < 6:
		return false
	Loc.set_language("en")
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in fails:
			print("  " + f)
		print("FAIL %s: %d problems (first: %s)" % [TASK_ID, fails.size(), fails[0]])
	return true


func _fail(msg: String) -> void:
	fails.append(msg)


func _static_checks() -> void:
	var ex := I18nExtract.new()
	ex.quiet = true
	ex._load_ignore()
	ex.scan_all()
	# 1. Every key has an English entry (the msgid) and, in the required areas, a French entry.
	var cov := ex.coverage()
	for area: String in I18nExtract.REQUIRED_AREAS:
		var c: Dictionary = cov[area]
		if int(c["total"]) == 0:
			_fail("area %s has no keys (extractor broken?)" % area)
		var miss: PackedStringArray = c["missing"]
		if not miss.is_empty():
			_fail("area %s: %d keys without French, e.g. \"%s\"" % [area, miss.size(), miss[0].substr(0, 70)])
	# 2. Placeholders / plural forms identical between English and French.
	for p in ex.check_french():
		_fail("placeholder: " + p)
	if I18nExtract.placeholder_mismatch("Need %d crystals", "Il faut %s cristaux") == "":
		_fail("placeholder check missed %d vs %s")
	if I18nExtract.placeholder_mismatch("{a} vs {b}", "{b} contre {a}") != "":
		_fail("placeholder check refused reordered {names}")
	# 3. Glyphs: every character of every French entry exists in the project fonts; the French accents too.
	var fonts: Array[FontFile] = []
	for path in FONTS:
		var f := load(path) as FontFile
		if f == null:
			_fail("font missing: " + path)
		else:
			fonts.append(f)
	var chars: Dictionary = {}
	for c in FRENCH_GLYPHS:
		chars[c] = "glyph list"
	var typo_bad := 0
	for path in Loc.po_files("fr"):
		var po := I18nPo.load_file(path)
		for e in po.entries:
			for s: String in e["strs"]:
				for c in s:
					if c.unicode_at(0) > 127 and not chars.has(c):
						chars[c] = path.get_file()
				# 4. Typography: no plain space before : ; ? ! (the no-break space is U+00A0).
				for p in [" :", " ;", " ?", " !"]:
					if s.contains(p):
						typo_bad += 1
						if typo_bad <= 3:
							_fail("typography: plain space in \"%s\" (%s); run extract_strings.gd fix" % [s.substr(0, 50), path.get_file()])
	for c: String in chars:
		for f in fonts:
			if not f.has_char(c.unicode_at(0)) and not (f.resource_path.contains("Cinzel") and c == "’"):
				_fail("glyph U+%04X '%s' (%s) missing in %s" % [c.unicode_at(0), c, chars[c], f.resource_path.get_file()])
	# 5. Plurals and placeholders through Loc (French: n <= 1 singular; English: n == 1).
	Loc.set_language("fr")
	# A live plural key ("{n} worker" was an obsolete entry, no longer loaded since review 2026-10-08 L2).
	var probe := Loc.tn("{n} crystal", "{n} crystals", 0)
	if Loc.tn("{n} crystal", "{n} crystals", 1) == probe.replace("0", "1") and Loc.tn("{n} crystal", "{n} crystals", 2) == probe.replace("0", "2"):
		_fail("French plural: 0 and 2 read the same (%s)" % probe)
	if probe != "0 cristal":
		_fail("French plural for 0 should be singular: '%s'" % probe)
	if Loc.tn("{n} crystal", "{n} crystals", 3) != "3 cristaux":
		_fail("French plural for 3: '%s'" % Loc.tn("{n} crystal", "{n} crystals", 3))
	# 6. Numeric templates (text from game logic): numbers kept, words translated.
	# (A live template: "Need # more crystals" was an obsolete entry, no longer loaded since review 2026-10-08 L2.)
	var sunk := Loc.sink("Must be within 50 m of your keep")
	if not sunk.contains("50") or sunk == "Must be within 50 m of your keep":
		_fail("Loc.sink numeric template: '%s'" % sunk)
	if Loc.t("Settings") == "Settings":
		_fail("French 'Settings' not translated")
	Loc.set_language("en")
	if Loc.tn("{n} crystal", "{n} crystals", 0) != "0 crystals" or Loc.t("Settings") != "Settings":
		_fail("English fallback / plural broken")
	# 7. Settings round trip (test file only).
	GameSettings.set_language("fr")
	GameSettings.load_settings()
	if GameSettings.language != "fr":
		_fail("language not saved / loaded (%s)" % GameSettings.language)
	GameSettings.set_language("en")
	if Loc.resolve_setting("fr") != "en":
		_fail("a scripted run must stay English unless -- --lang=fr")


func _switch_checks() -> void:
	var settings_btn: Button = _menu.get("settings_button")
	var panel: SettingsPanel = _menu.get("settings_panel")
	if settings_btn == null or panel == null:
		_fail("main menu has no settings_button / settings_panel")
		return
	var hint_en := panel.controls_hint.text
	var tip_en: String = (_menu.get("kingdom_buttons")[0] as Control).tooltip_text
	var matchup_en: String = _menu.call("matchup_text")
	GameSettings.set_language("fr", false)
	if settings_btn.atr(settings_btn.text) != "Paramètres":
		_fail("Settings button shows '%s' in French" % settings_btn.atr(settings_btn.text))
	if panel.controls_hint.text == hint_en:
		_fail("settings controls hint did not switch to French")
	if (_menu.get("kingdom_buttons")[0] as Control).tooltip_text == tip_en:
		_fail("kingdom card tooltip did not switch to French")
	if _menu.call("matchup_text") == matchup_en:
		_fail("matchup line did not switch to French")
	if panel.language_option.selected != Loc.LANGS.find("fr"):
		_fail("Settings > Language does not show French")
	GameSettings.set_language("en", false)
	if settings_btn.atr(settings_btn.text) != "Settings" or panel.controls_hint.text != hint_en:
		_fail("switching back to English did not restore the labels")
