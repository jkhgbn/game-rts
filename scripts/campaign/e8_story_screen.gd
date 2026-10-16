class_name E8StoryScreen
extends Control
## Episode 8's three full-screen story screens (outline 4.1 / 4.5, mission-e8-03.md 8.2), one script, `kind`:
## - &"road": "Whose road do you walk?" (the campaign's e8m1 entry, missions/e8_road_choice.tscn): four wizard cards;
##   the pick writes `e8_road` (int 0-3) and `e8_road_<k>` and starts mission_e8_01_<k>.
## - &"choice": the ending's choice card (missions/ep8_choice.tscn): Break the throne / Take the seat, no timer, not
##   skippable; writes `ep8_choice` (1 break / 2 take), `ep8_throne_broken`, `ep8_dark_track`, saves, then plays
##   ep8_ending_b (FILM_BRANCHES picks the dark tail and the dark bookend).
## - &"credits": a slow roll of ROLL_SECONDS (campaign review 2026-10-16): the four wizards (portrait, name in their
##   kingdom colour, kingdom, the relic each carried; the player's road last), then the thank-you text
##   (docs/design/script-episodes-4-8/e8m3.md section 4); Esc / Enter / Space / a click skips it; then the end panel
##   and the main menu.
## The dark track: earlier choices weigh on the card (e3m3 / e3m4 refusals not made, the stone used in Ep3 or Ep8, the
## Hundredwinter Gate kept shut, the Outwall not sheltered): at 3 or more, the throne's whisper line shows under the
## title. It never picks for the player.

const ROADS := [
	[&"fire", "Vessa", "The Spark Waits", "She never waits."],
	[&"shadow", "Malrik", "Put Down the Shovel", "He is never full."],
	[&"ice", "Torvald", "The Gate Opens", "He waits too long."],
	[&"nature", "Ysolde", "Take a Side", "She will not take a side."],
]
const TEMPTATION := {&"fire": "I could stop every war. Keep everyone safe.", &"shadow": "Full. At last. Just once, to be full.",
		&"ice": "A peace that never melts. Never breaks.", &"nature": "Everything would grow. Everywhere. Always."}
const CREDITS: Array[String] = ["Thank you for playing Four Wizards.", "Four apprentices, one storm, and you at the table.",
		"Every battle you fought is part of this tale now.", "Made with care, many playtests, and one very patient wizard.",
		"The storm chooses its own. Thank you for choosing it."]
## The credits roll's length in seconds (the roll scrolls from below the screen until its last line has left the top).
const ROLL_SECONDS := 90.0
## The roll's wizard rows: kingdom, the kingdom line, the relic (MissionE8Base.KEY_OF, its ItemType name).
const ROLL_KINGDOMS := {&"fire": "Kingdom of Fire", &"shadow": "Kingdom of Shadow", &"ice": "Kingdom of Ice",
		&"nature": "Kingdom of Nature"}
const PORTRAIT_DIR := "res://art/portraits/"

@export var kind: StringName = &"road"
## MenuFlow sets it on a "mission" scene (the road picker).
var mission_difficulty := 1
## StoryFilms sets it on a story screen.
var bot_difficulty := 1
## Tests: the save the screen reads / writes ("" = the default).
var save_path := ""
## Tests: false = picking does not change scene.
var launch := true

var _box: VBoxContainer
var _rolling := false
var _roll_t := 0.0
var _roll: VBoxContainer
var _roll_clip: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UIStyle.game_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.035, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override(&"separation", 18)
	_box.custom_minimum_size = Vector2(760.0, 0.0)
	center.add_child(_box)
	match kind:
		&"road":
			_build_road()
		&"choice":
			_build_choice()
		_:
			_build_credits()


func _title(text: String, size := 34) -> Label:
	var l := UIStyle.display_label(text, size, UIStyle.GOLD)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(l)
	return l


func _line(text: String, size := 18, color := Color(0.88, 0.85, 0.80)) -> Label:
	var l := UIStyle.label(text, size)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_color_override(&"font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(l)
	return l


func _button(text: String, on_press: Callable, parent: Control = null) -> Button:
	var b := Button.new()
	b.text = text
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(0.0, 52.0)
	b.add_theme_font_size_override(&"font_size", 19)
	UIStyle.style_button(b, UIStyle.GOLD)
	b.pressed.connect(on_press)
	(parent if parent else _box).add_child(b)
	return b


# ---------------------------------------------------------------- the road picker

func _build_road() -> void:
	_title(Loc.t("Whose road do you walk?"))
	_line(Loc.t("Four keys. One door. Each wizard walks their own road to Crown Hollow; the others open for replay after the ending."))
	var first: Button = null
	for row: Array in ROADS:
		var k := StringName(row[0])
		var b := _button(Loc.t("{wizard}: {title}", {"wizard": Loc.t(String(row[1])), "title": Loc.t(String(row[2]))}),
				pick_road.bind(k))
		b.tooltip_text = Loc.t(String(row[3]))
		if first == null:
			first = b
	_button(Loc.t("Back to the menu"), func() -> void: MenuFlow.quit_to_menu(get_tree()))
	if first:
		first.grab_focus.call_deferred()


## Writes the road and starts its mission (the scene path of `e8m1_<k>`).
func pick_road(k: StringName) -> void:
	var cs := CampaignState.open(save_path)
	var flags := {"e8_road": MissionE8Base.road_index(k)}
	for r: Array in ROADS:
		flags["e8_road_%s" % r[0]] = StringName(r[0]) == k
	cs.set_flags(flags)
	var id := StringName("e8m1_%s" % k)
	if not cs.unlocked.has(id):
		cs.unlocked.append(id)
	cs.save()
	if launch:
		MenuFlow.start_mission(get_tree(), CampaignState.mission_scene(id), mission_difficulty)


# ---------------------------------------------------------------- the choice card

static func dark_score(flags: Dictionary) -> int:
	var n := 0
	if flags.has("e3m3_refused") and not bool(flags["e3m3_refused"]):
		n += 1
	if flags.has("e3m4_refused") and not bool(flags["e3m4_refused"]):
		n += 1
	if int(flags.get("shadow_stone_uses", 0)) > 0:
		n += 1
	if int(flags.get("e8_stone_uses", 0)) > 0:
		n += 1
	if flags.has("e6m2_gate_opened") and not bool(flags["e6m2_gate_opened"]):
		n += 1
	if flags.has("e7m3_people") and not bool(flags["e7m3_people"]):
		n += 1
	return n


func _build_choice() -> void:
	var cs := CampaignState.open(save_path)
	var v: Variant = cs.flag_value("e8_road", 0)
	var road: StringName = MissionE8Base.E8_KINGDOMS[clampi(int(v) if (v is int or v is float) else 0, 0, 3)]
	_title(Loc.t("Choose, all four of you."))
	_line(Loc.t(TEMPTATION[road]), 20, Color(1.0, 0.80, 0.45))
	if dark_score(cs.flags) >= 3:
		_line(Loc.t("The throne remembers every time you held the stone."), 16, Color(0.95, 0.65, 0.30))
	var b := _button(Loc.t("Break the throne"), choose.bind(CampaignState.CHOICE_BREAK))
	_line(Loc.t("Four hands keep the peace, not one."), 16)
	_button(Loc.t("Take the seat"), choose.bind(CampaignState.CHOICE_TAKE))
	_line(Loc.t("Keep the peace yourself."), 16)
	b.grab_focus.call_deferred()


## Saves the choice at once, then the branch plays.
func choose(choice: int) -> void:
	var cs := CampaignState.open(save_path)
	cs.set_flags({"ep8_choice": choice, "ep8_throne_broken": choice == CampaignState.CHOICE_BREAK,
			"ep8_dark_track": dark_score(cs.flags) >= 3})
	cs.mark_seen(&"ep8_choice")
	if launch:
		StoryFilms.play_chain(get_tree(), &"ep8_ending_b", bot_difficulty)


# ---------------------------------------------------------------- the credits

func _build_credits() -> void:
	_roll_clip = Control.new()
	_roll_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_roll_clip.clip_contents = true
	_roll_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_roll_clip)
	_roll = VBoxContainer.new()
	_roll.add_theme_constant_override(&"separation", 26)
	_roll.custom_minimum_size = Vector2(760.0, 0.0)
	_roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll_clip.add_child(_roll)
	_roll_line(Loc.t("Four Wizards"), 46, UIStyle.GOLD, true)
	_roll_line(Loc.t("The four who kept the peace"), 20, Color(0.80, 0.76, 0.70))
	_roll_gap(80.0)
	for k: StringName in roll_order(_road()):
		_roll_wizard(k)
		_roll_gap(70.0)
	_roll_gap(60.0)
	for c: String in CREDITS:
		_roll_line(Loc.t(c), 24, Color(0.92, 0.89, 0.84))
		_roll_gap(70.0)
	_roll_line(Loc.t("Made with the Godot Engine."), 18, Color(0.70, 0.68, 0.64))
	_roll_gap(120.0)
	_roll_line(Loc.t("Four hands keep the peace, not one."), 26, UIStyle.GOLD, true)
	_rolling = true
	_roll_t = 0.0
	_place_roll()


## The four kingdoms in roll order: the player's road (`e8_road`'s kingdom) last.
static func roll_order(road: StringName) -> Array[StringName]:
	var last: StringName = road if MissionE8Base.E8_KINGDOMS.has(road) else MissionE8Base.E8_KINGDOMS[0]
	var out: Array[StringName] = []
	for k: StringName in MissionE8Base.E8_KINGDOMS:
		if k != last:
			out.append(k)
	out.append(last)
	return out


## The relic's shown name (its ItemType display name, translated).
static func relic_name(k: StringName) -> String:
	var id := String(MissionE8Base.KEY_OF.get(k, ""))
	var it: ItemType = ItemType.find(StringName(id)) if id != "" else null
	return Loc.t(it.display_name) if it != null else id.capitalize()


func _road() -> StringName:
	var v: Variant = CampaignState.open(save_path).flag_value("e8_road", 0)
	return MissionE8Base.E8_KINGDOMS[clampi(int(v) if (v is int or v is float) else 0, 0, 3)]


func _roll_line(text: String, size: int, color: Color, display := false) -> Label:
	var l := UIStyle.display_label(text, size, color) if display else UIStyle.label(text, size)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if not display:
		l.add_theme_color_override(&"font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roll.add_child(l)
	return l


func _roll_gap(h: float) -> void:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0.0, h)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll.add_child(g)


## One wizard row: portrait (art/portraits/<wizard>.png when it exists), name in the kingdom colour, kingdom, relic.
func _roll_wizard(k: StringName) -> void:
	var col := UIStyle.kingdom_color(k)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 28)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll.add_child(row)
	var path := PORTRAIT_DIR + String(MissionE8Base.WIZARD_OF[k]) + ".png"
	if ResourceLoader.exists(path):
		var tex := TextureRect.new()
		tex.texture = load(path) as Texture2D
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(132.0, 132.0)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tex)
	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.custom_minimum_size = Vector2(360.0, 0.0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	var name_l := UIStyle.display_label(Loc.t(String(MissionE8Base.WIZARD_NAME[k])), 36, col)
	name_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	text.add_child(name_l)
	var kingdom_l := UIStyle.label(Loc.t(String(ROLL_KINGDOMS[k])), 19)
	kingdom_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	kingdom_l.add_theme_color_override(&"font_color", col.lerp(Color(0.9, 0.88, 0.84), 0.45))
	text.add_child(kingdom_l)
	var relic_l := UIStyle.label(Loc.t("Relic: {relic}", {"relic": relic_name(k)}), 19)
	relic_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	relic_l.add_theme_color_override(&"font_color", Color(0.88, 0.85, 0.80))
	text.add_child(relic_l)


## The roll's position at `_roll_t`: its top starts at the screen's bottom edge, its bottom leaves the top at ROLL_SECONDS.
func _place_roll() -> void:
	if _roll == null:
		return
	var view := _roll_clip.size if _roll_clip.size.y > 0.0 else get_viewport_rect().size
	var h := maxf(_roll.get_combined_minimum_size().y, _roll.size.y)
	_roll.size = Vector2(minf(760.0, view.x), h)
	var f := clampf(_roll_t / ROLL_SECONDS, 0.0, 1.0)
	_roll.position = Vector2((view.x - _roll.size.x) * 0.5, lerpf(view.y, -h, f))


## True while the credits roll plays (before the end panel).
func is_rolling() -> bool:
	return _rolling


## Seconds of the roll played so far.
func roll_time() -> float:
	return _roll_t


## Ends the roll now (Esc / Enter / Space / a click) and shows the end panel.
func skip_credits() -> void:
	if not _rolling:
		return
	_rolling = false
	if _roll_clip:
		_roll_clip.queue_free()
		_roll_clip = null
		_roll = null
	_end_panel()


func _process(delta: float) -> void:
	if kind != &"credits" or not _rolling:
		return
	_roll_t += delta
	if _roll_t >= ROLL_SECONDS:
		skip_credits()
		return
	_place_roll()


func _unhandled_input(event: InputEvent) -> void:
	if kind != &"credits" or not _rolling or not event.is_pressed() or event.is_echo():
		return
	var skip := event is InputEventMouseButton
	if event is InputEventKey:
		var key := (event as InputEventKey).physical_keycode
		skip = key in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	if not skip and (event.is_action(&"ui_cancel") or event.is_action(&"ui_accept")):
		skip = true
	if skip:
		get_viewport().set_input_as_handled()
		skip_credits()


func _end_panel() -> void:
	for c in _box.get_children():
		c.queue_free()
	var cs := CampaignState.open(save_path)
	cs.mark_seen(&"ep8_credits")
	_title(Loc.t("Episode 8 complete. The story is told."))
	var broken := int(cs.flag_value("ep8_choice", CampaignState.CHOICE_BREAK)) != CampaignState.CHOICE_TAKE
	_line(Loc.t("The throne is broken") if broken else Loc.t("The throne is full"), 22, UIStyle.GOLD)
	var b := _button(Loc.t("Back to the menu"), func() -> void: MenuFlow.quit_to_menu(get_tree()))
	b.grab_focus.call_deferred()
