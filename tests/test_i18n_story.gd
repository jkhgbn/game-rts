extends SceneTree
## Localization of the story screens (docs/design/localization.md): in French, the briefing screen, the objectives
## panel, the dialogue box and the cinematic subtitles show French for mission 1's texts (exact msgids, counters,
## printf texts like "Light the braziers of Emberfall (%d / 3)"), no text sticks out of its frame or the 1600 x 900
## screen (UILabChecks), and English comes back unchanged.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_i18n_story.gd --quit-after 3000
## Windowed (no --headless): also saves docs/ui/lab_fr/story/*.png. Prints "PASS i18n_story" or "FAIL i18n_story: ...".

const TASK_ID := "i18n_story"
const StoryText := preload("res://scripts/ui/mission/story_text.gd")
const SCREEN := Vector2(1600, 900)
const SHOT_DIR := "res://docs/ui/lab_fr/story/"

const TITLE := "Mission 1: The Crown in the Ashes"
const PARAGRAPHS: Array[String] = [
	"The God Wizard vanished between one breath and the next. He left four apprentices, four kingdoms and not one word of instruction. His regalia fell across the world like sparks from a kicked fire.",
	"One spark still glows: the Ember Crown, sealed in Emberfall, the Master's burnt-out observatory on the border between the Fire and Shadow kingdoms. Three old braziers hold the seal shut.",
	"Vessa, the youngest and least patient apprentice, rides out the night she hears of it. Malrik of Shadow got there first and is camped at the far end of the ruins. He cannot light a brazier. She can.",
]
const LINE := "Three braziers, one seal. I've been lighting things since before I could talk."   # No AI Slop pass 2026-10-07


class FakeMission extends Node:
	var hold_left := 83.0

	func briefing() -> Dictionary:
		return {title = TITLE, paragraphs = PARAGRAPHS,
				objectives = ["Light the braziers of Emberfall (0 / 3)", "Claim the Ember Crown",
						"Survive Malrik's counterattack (2:00)"]}

	func objectives() -> Array:
		return [
			{id = &"obj_braziers", text = "Light the braziers of Emberfall (1 / 3)", primary = true},
			{id = &"obj_crown", text = "Claim the Ember Crown", primary = true, progress = 1, goal = 3},
			{id = &"obj_hold", text = "Survive Malrik's counterattack (2:00)", primary = true, time_left = hold_left},
			{id = &"obj_vessa", text = "Vessa must survive", primary = true},
			{id = &"sec_peddler", text = "Free the Ruin Peddler", type = "secondary"},
			{id = &"sec_outpost", text = "Burn Malrik's Gloom Hall", type = "secondary"},
		]


var fails: PackedStringArray = []
var _frames := 0
var _mhud: MissionHud
var _fake: FakeMission
var _cine: CinematicOverlay
var _windowed := false


func _initialize() -> void:
	_windowed = DisplayServer.get_name() != "headless"
	root.size = Vector2i(SCREEN)   # headless -s runs start at 64 x 64
	Loc.set_language("fr")
	_static_checks()


func _build() -> void:
	_fake = FakeMission.new()
	root.add_child(_fake)
	_mhud = MissionHud.attach(root, _fake, null)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		root.size = Vector2i(SCREEN)
	elif _frames == 3:
		_build()
	elif _frames == 6:
		_check_briefing()
		_shot("briefing")
	elif _frames == 8:
		_mhud.briefing.begin()
	elif _frames == 10:
		_mhud.objectives_panel.refresh()
		_mhud.dialogue_box.say(&"vessa", LINE)
	elif _frames == 14:
		_check_objectives_and_dialogue()
		_shot("objectives_dialogue")
		_cine = CinematicOverlay.new()
		_cine.instant = true
		root.add_child(_cine)
		_cine.open(2.39)
		_cine.show_line(&"narrator", "Then, between one breath and the next, he was gone.", 4.0)
	elif _frames == 18:
		_check_cinematic()
		_shot("cinematic")
		_check_english()
		Loc.set_language("en")
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


func _expect(what: String, got: String, want: String) -> void:
	if got != want:
		_fail("%s: got \"%s\", want \"%s\"" % [what, got, want])


func _french(what: String, english: String, shown: String) -> void:
	if shown == english or shown == "":
		_fail("%s still English: \"%s\"" % [what, english.substr(0, 60)])


## StoryText on its own: exact msgids, numeric templates, printf msgids (with a translated %s), multi-line.
func _static_checks() -> void:
	var nb := String.chr(0xA0)
	_expect("exact", StoryText.tr_text("Claim the Ember Crown"), "S'emparer de l'Ember Crown")
	_expect("printf %d", StoryText.tr_text("Light the braziers of Emberfall (2 / 3)"),
			"Allumer les braseros d'Emberfall (2 / 3)")
	_expect("printf %d %%", StoryText.tr_text("Stop Malrik's dig (45 %)"), "Arrêter la fouille de Malrik (45" + nb + "%)")   # no-break space before % (glossary)
	_expect("printf %d:%02d", StoryText.tr_text("Take the Master's Signet (Malrik marches in 1:05)"),
			"Prendre le Master's Signet (Malrik part dans 1:05)")
	_expect("printf %s translated", StoryText.tr_text("Knives from the north!"), "Des couteaux, côté nord" + nb + "!")
	_expect("multi-line", StoryText.tr_text("VICTORY\nThe night is over"), "VICTOIRE\nLa nuit est finie")
	_expect("unknown stays English", StoryText.tr_text("Zorblax 42"), "Zorblax 42")
	# HUD messages (hud.gd shows them through Loc.sink, which has the printf fallback since 2026-10-06).
	_expect("sink %s", Loc.sink("Knives from the east!"), "Des couteaux, côté est" + nb + "!")
	_expect("sink %d %%", Loc.sink("Malrik's dig: 45 %"), "Fouille de Malrik" + nb + ": 45" + nb + "%")
	_expect("sink %s wears", Loc.sink("Vessa wears the Ember Crown"), "Vessa porte" + nb + ": Ember Crown")
	if Loc.sink("Your Keep can become a Stronghold: select the Keep and press X (150 crystals). It opens new units.") \
			.begins_with("Your"):
		_fail("HINT_STRONGHOLD stays English through Loc.sink")
	if Loc.sink("Y: hire a champion. Champions choose their own jobs; bounty flags (R) pay them to do yours.") \
			.begins_with("Y: hire"):
		_fail("HINT_HIRE stays English through Loc.sink")


func _check_briefing() -> void:
	var b := _mhud.briefing
	if b == null:
		_fail("no briefing screen")
		return
	_french("briefing title", TITLE, b.title_label.text)
	if not b.title_label.text.begins_with("Mission 1" + String.chr(0xA0) + ":"):
		_fail("briefing title not the French template: " + b.title_label.text)
	for i in b.paragraph_labels.size():
		_french("briefing paragraph %d" % i, PARAGRAPHS[i], b.paragraph_labels[i].text)
	_expect("briefing objective 0", b.objective_labels[0].text, "Allumer les braseros d'Emberfall (0 / 3)")
	_expect("briefing objective 2", b.objective_labels[2].text,
			"Survivre à la contre-attaque de Malrik (2:00)")
	_expect("Begin button", b.begin_button.atr(b.begin_button.text), "Commencer")
	_layout_checks("briefing", b)


func _check_objectives_and_dialogue() -> void:
	var p := _mhud.objectives_panel
	_expect("objective counter in text", p.row_text(&"obj_braziers"), "Allumer les braseros d'Emberfall (1 / 3)")
	_expect("objective + appended counter", p.row_text(&"obj_crown"), "S'emparer de l'Ember Crown (1 / 3)")
	_expect("objective clock", p.row_text(&"obj_hold"), "Survivre à la contre-attaque de Malrik (1:23)")
	_expect("secondary objective", p.row_text(&"sec_peddler"), "Libérer le colporteur des ruines")
	var d := _mhud.dialogue_box
	_french("dialogue line", LINE, d.current_text())
	_layout_checks("mission HUD", _mhud)


func _check_cinematic() -> void:
	_expect("cinematic subtitle", _cine.current_line_text(), "Puis, entre deux souffles, il disparut.")
	_layout_checks("cinematic", _cine)


func _check_english() -> void:
	Loc.set_language("en")
	_expect("English printf", StoryText.tr_text("Light the braziers of Emberfall (2 / 3)"),
			"Light the braziers of Emberfall (2 / 3)")
	_expect("English line", StoryText.tr_text(LINE), LINE)


func _layout_checks(what: String, scope: Node) -> void:
	var controls := UILabChecks.visible_controls(scope)
	for it in UILabChecks.find_overflow(controls):
		_fail("%s overflow: %s %s" % [what, it.text, it.detail])
	for it in UILabChecks.find_offscreen(controls, Rect2(Vector2.ZERO, SCREEN)):
		_fail("%s offscreen: %s %s" % [what, it.text, it.detail])


func _shot(name: String) -> void:
	if not _windowed:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var img := root.get_texture().get_image()
	if img:
		img.save_png(SHOT_DIR + name + ".png")
