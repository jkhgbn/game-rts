class_name WaveStrikeLobby
extends PanelContainer
## The main menu's Wave Strike page (docs/design/wave-strike.md 7.4 "Lobby", M1): the fixed map (Ashwind Reach, its
## World Forge preview from the MapCatalog), the player's kingdom (all 4 since balance pass 2), the bot's kingdom
## (Random = another kingdom) and personality, Start and Back. MenuFlow.start_wave_strike builds the match.

signal back_requested

const MAP_ID := &"ashwind_reach"
const PREVIEW := 220.0
const RULES_TEXT := ("Buy cards: each one sends a unit at every horn (every 40 s, first at 0:30).\n"
		+ "Coffers raise your income, the Stronghold opens tier-2 cards and more supply.\n"
		+ "Your wizard guards your half of the lane. Break the enemy Bastion to win.")

## The 4 kingdoms with Wave Strike cards (data/wave_strike/card_prices.tres), lobby order.
const KINGDOMS: Array[StringName] = [&"fire", &"ice", &"nature", &"shadow"]

var kingdom_buttons: Array[Button] = []
var enemy_buttons: Array[Button] = []     ## Random, then KINGDOMS
var personality_buttons: Array[Button] = []
var start_button: Button
var _kingdom: StringName = &"fire"
var _enemy: StringName = &"random"
var _personality := "steward"
var _map_label: Label   ## U5-7: map title + size line, rebuilt on a language switch.
var _texts: Array = []  ## U5-7: [control, Callable returning its text] rebuilt on a language switch.


## The button text of a kingdom (whole msgids, translated through Loc).
static func kingdom_label(k: StringName) -> String:
	match k:
		&"fire":
			return Loc.t("Fire (Vessa)")
		&"ice":
			return Loc.t("Ice (Torvald)")
		&"nature":
			return Loc.t("Nature (Ysolde)")
		&"shadow":
			return Loc.t("Shadow (Malrik)")
	return Loc.t("Random")


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.frame_style(24.0))
	_kingdom = MenuFlow.ws_kingdom
	_enemy = MenuFlow.ws_enemy_kingdom
	_personality = MenuFlow.ws_personality
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := UIStyle.use_title_font(UIStyle.label("Wave Strike", 34))
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	# the map
	var map_col := VBoxContainer.new()
	row.add_child(map_col)
	var cat := MapCatalog.load_default()
	var tex := cat.preview_texture(MAP_ID)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(PREVIEW, PREVIEW)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture = tex
	map_col.add_child(pic)
	_map_label = UIStyle.panel_label("", 15)
	_map_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	map_col.add_child(_map_label)
	_refresh_map_label()
	# the choices
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	row.add_child(col)
	col.add_child(_loc_label(func() -> String: return Loc.t("Your kingdom"), 17))
	var kg := ButtonGroup.new()
	var kgrid := GridContainer.new()
	kgrid.columns = 2
	col.add_child(kgrid)
	for k: StringName in KINGDOMS:
		var b := _toggle(kgrid, kingdom_label(k), kg)
		b.button_pressed = k == _kingdom
		var kk := k
		_track(b, func() -> String: return kingdom_label(kk))
		b.pressed.connect(func() -> void: _kingdom = kk)
		kingdom_buttons.append(b)
	col.add_child(_loc_label(func() -> String: return Loc.t("Enemy kingdom"), 17))
	var eg := ButtonGroup.new()
	var egrid := GridContainer.new()
	egrid.columns = 3
	col.add_child(egrid)
	for k: StringName in [&"random"] + KINGDOMS:
		var b := _toggle(egrid, kingdom_label(k), eg)
		b.custom_minimum_size = Vector2(132, 36)
		b.button_pressed = k == _enemy
		var kk := k
		_track(b, func() -> String: return kingdom_label(kk))
		b.pressed.connect(func() -> void: _enemy = kk)
		enemy_buttons.append(b)
	col.add_child(UIStyle.panel_label("Enemy bot", 17, UIStyle.GOLD))
	var pg := ButtonGroup.new()
	var prow := HBoxContainer.new()
	col.add_child(prow)
	for p: String in ["steward", "hammer"]:
		var b := _toggle(prow, "Steward (economy)" if p == "steward" else "Hammer (aggressive)", pg)
		b.button_pressed = p == _personality
		var pp := p
		b.pressed.connect(func() -> void: _personality = pp)
		personality_buttons.append(b)
	var rules := UIStyle.panel_label(RULES_TEXT, 14)
	rules.custom_minimum_size = Vector2(420, 0)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(rules)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var back := _button(buttons, "Back")
	back.pressed.connect(func() -> void: back_requested.emit())
	start_button = _button(buttons, "Start")
	start_button.pressed.connect(start)


func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or not is_node_ready():
		return
	_refresh_map_label()
	for row: Array in _texts:
		var c: Control = row[0]
		if is_instance_valid(c):
			c.set(&"text", (row[1] as Callable).call())


## The map's title and size line in the current language (Loc.sink: logic text from the catalog).
func _refresh_map_label() -> void:
	if _map_label == null:
		return
	var e := MapCatalog.load_default().entry(MAP_ID)
	var title := Loc.sink(String(e.get("title", "Ashwind Reach")))
	var size_line := Loc.sink(MapCatalog.size_text(e)) if not e.is_empty() else Loc.t("192 x 96 m · 2 players")
	_map_label.text = "%s\n%s" % [title, size_line]


## A gold header label whose text is built in code (Loc.t) and rebuilt on a language switch.
func _loc_label(text_of: Callable, size: int) -> Label:
	var l := UIStyle.panel_label(String(text_of.call()), size, UIStyle.GOLD)
	_track(l, text_of)
	return l


func _track(c: Control, text_of: Callable) -> void:
	c.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_texts.append([c, text_of])


func focus_start() -> void:
	if start_button:
		start_button.grab_focus()


func start() -> Node:
	return MenuFlow.start_wave_strike(get_tree(), _kingdom, _personality, _enemy)


func _button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 44)
	b.add_theme_font_size_override("font_size", 19)
	UIStyle.style_button(b)
	parent.add_child(b)
	return b


func _toggle(parent: Control, text: String, group: ButtonGroup) -> Button:
	var b := _button(parent, text)
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(200, 40)
	b.add_theme_font_size_override("font_size", 16)
	return b
