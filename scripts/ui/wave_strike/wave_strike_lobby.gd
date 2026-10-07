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
	var e := cat.entry(MAP_ID)
	var tex := cat.preview_texture(MAP_ID)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(PREVIEW, PREVIEW)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture = tex
	map_col.add_child(pic)
	var map_l := UIStyle.panel_label("%s\n%s" % [String(e.get("title", "Ashwind Reach")),
		MapCatalog.size_text(e) if not e.is_empty() else "192 x 96 m · 2 players"], 15)
	map_col.add_child(map_l)
	# the choices
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	row.add_child(col)
	col.add_child(UIStyle.panel_label(Loc.t("Your kingdom"), 17, UIStyle.GOLD))
	var kg := ButtonGroup.new()
	var kgrid := GridContainer.new()
	kgrid.columns = 2
	col.add_child(kgrid)
	for k: StringName in KINGDOMS:
		var b := _toggle(kgrid, kingdom_label(k), kg)
		b.button_pressed = k == _kingdom
		var kk := k
		b.pressed.connect(func() -> void: _kingdom = kk)
		kingdom_buttons.append(b)
	col.add_child(UIStyle.panel_label(Loc.t("Enemy kingdom"), 17, UIStyle.GOLD))
	var eg := ButtonGroup.new()
	var egrid := GridContainer.new()
	egrid.columns = 3
	col.add_child(egrid)
	for k: StringName in [&"random"] + KINGDOMS:
		var b := _toggle(egrid, kingdom_label(k), eg)
		b.custom_minimum_size = Vector2(132, 36)
		b.button_pressed = k == _enemy
		var kk := k
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
