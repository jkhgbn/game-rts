class_name MainMenu
extends Control
## The title screen (task 5.U1): Skirmish 1v1 (setup panel, 8.U1: You / Enemy rows of 4 kingdom
## cards, difficulty, Start),
## Campaign (7.U1: mission list from CampaignState, difficulty, Start), Settings, Quit.
## Painted gradient background with drifting embers.

const TAGLINE := "Four apprentices. One vanished master. Every artifact is a step to his throne."
const DIFFICULTY_NAMES := ["Easy", "Normal", "Hard"]   # Commander.Difficulty order
## Campaign mission titles (mission-01.md); ids and scenes come from CampaignState.
const MISSION_TITLES := {&"m01": "The Crown in the Ashes"}
const MENU_DIORAMA := "res://art/environment/menu_diorama/menu_diorama.tscn"

var diorama: Node3D   ## MenuDiorama (3D background); null if the scene is missing.

var main_panel: PanelContainer
var skirmish_panel: PanelContainer
var settings_panel: SettingsPanel
var skirmish_button: Button
var campaign_button: Button
var settings_button: Button
var quit_button: Button
var start_button: Button
var difficulty_buttons: Array[Button] = []
var time_limit_buttons: Array[Button] = []   ## 16a: Off / 30 min / 45 min (GameSettings.TIME_LIMIT_CHOICES order).
var kingdom_buttons: Array[Button] = []   ## The 4 "You" KingdomCards (KingdomCard.ORDER).
var enemy_buttons: Array[Button] = []     ## The 4 "Enemy" KingdomCards (KingdomCard.ORDER).
var foe_label: Label                      ## The matchup line: "Vessa of Fire  vs  Malrik of Shadow".
var campaign_panel: PanelContainer
var mission_buttons: Array[Button] = []          ## One per mission of CampaignState.MISSION_ORDER.
var mission_ids: Array[StringName] = []
var campaign_difficulty_buttons: Array[Button] = []
var campaign_start_button: Button

var _difficulty := 1   # Commander.Difficulty.NORMAL
var _enemy: StringName = &"shadow"
var _player: StringName = &"fire"
var _mission: StringName = &""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	GameSettings.ensure_loaded(get_tree())
	MenuFlow.install_hooks(get_tree())
	if MenuFlow.difficulty >= 0:
		_difficulty = MenuFlow.difficulty
	_enemy = MenuFlow.enemy_kingdom
	_player = MenuFlow.player_kingdom

	# A2.10: the 3D diorama behind the menu, in its own SubViewport (it scales its 3D resolution down on
	# ultrawide screens); the painted 2D backdrop stays as the fallback.
	if ResourceLoader.exists(MENU_DIORAMA):
		var view_holder := SubViewportContainer.new()
		view_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		view_holder.stretch = true
		view_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(view_holder)
		var vp := SubViewport.new()
		vp.own_world_3d = true
		vp.msaa_3d = Viewport.MSAA_2X
		vp.audio_listener_enable_3d = false
		view_holder.add_child(vp)
		diorama = (load(MENU_DIORAMA) as PackedScene).instantiate() as Node3D
		vp.add_child(diorama)
	else:
		var backdrop := MenuBackdrop.new()
		backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(backdrop)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	add_child(column)

	var title := UIStyle.label("Four Wizards", 84)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0.18, 0.05, 0.02))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var tagline := UIStyle.label(TAGLINE, 20)
	tagline.modulate = Color(1, 0.92, 0.8, 0.9)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tagline)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	column.add_child(spacer)

	# The panels share the centre spot; only one is visible at a time.
	var holder := CenterContainer.new()
	column.add_child(holder)
	main_panel = _build_main_panel(holder)
	skirmish_panel = _build_skirmish_panel(holder)
	campaign_panel = _build_campaign_panel(holder)
	settings_panel = SettingsPanel.new()
	holder.add_child(settings_panel)
	settings_panel.visible = false
	settings_panel.closed.connect(show_main)

	var footer := UIStyle.label("Prototype build  -  Esc in game: pause", 14)
	footer.modulate = Color(1, 1, 1, 0.55)
	footer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.position -= Vector2(16, 12)
	add_child(footer)

	show_main()


# ---------------------------------------------------------------- public

func show_main() -> void:
	main_panel.visible = true
	skirmish_panel.visible = false
	campaign_panel.visible = false
	settings_panel.visible = false
	skirmish_button.grab_focus()
	_focus_diorama(&"")


func show_skirmish_setup() -> void:
	main_panel.visible = false
	skirmish_panel.visible = true
	campaign_panel.visible = false
	settings_panel.visible = false
	start_button.grab_focus()
	_focus_diorama(_player)


## The campaign panel: the mission list is re-read from the campaign save each time it opens.
func show_campaign() -> void:
	main_panel.visible = false
	skirmish_panel.visible = false
	settings_panel.visible = false
	refresh_missions()
	campaign_panel.visible = true
	campaign_start_button.grab_focus()


func show_settings() -> void:
	main_panel.visible = false
	skirmish_panel.visible = false
	campaign_panel.visible = false
	settings_panel.open()


## 0 = Easy, 1 = Normal, 2 = Hard (Commander.Difficulty). Shared by the skirmish and campaign panels.
func set_difficulty(value: int) -> void:
	_difficulty = clampi(value, 0, DIFFICULTY_NAMES.size() - 1)
	for i in difficulty_buttons.size():
		difficulty_buttons[i].set_pressed_no_signal(i == _difficulty)
	for i in campaign_difficulty_buttons.size():
		campaign_difficulty_buttons[i].set_pressed_no_signal(i == _difficulty)


func get_difficulty() -> int:
	return _difficulty


## True when the skirmish can start with `kingdom` (Skirmish.kingdom_available: keep, worker and
## wizard exist). True for a known kingdom when the skirmish script has no such check.
static func kingdom_available(kingdom: StringName) -> bool:
	if not KingdomCard.INFO.has(kingdom):
		return false
	var script: Script = load(MenuFlow.SKIRMISH_SCRIPT) if ResourceLoader.exists(MenuFlow.SKIRMISH_SCRIPT) else null
	if script == null or not script.has_method(&"kingdom_available"):
		return true
	return bool(script.call(&"kingdom_available", kingdom))


## `wanted` when it is available, else `fallback`, else the first available kingdom (Fire if none).
static func _pick_available(wanted: StringName, fallback: StringName) -> StringName:
	for k: StringName in [wanted, fallback] + KingdomCard.ORDER:
		if kingdom_available(k):
			return k
	return &"fire"


## The bot's kingdom: &"fire" / &"shadow" / &"ice" / &"nature" (unknown or unavailable = Shadow, else
## the first available one). Mirror allowed.
func set_enemy(kingdom: StringName) -> void:
	_enemy = _pick_available(kingdom, &"shadow")
	_select_card(enemy_buttons, _enemy)
	_update_matchup()


func get_enemy() -> StringName:
	return _enemy


## The player's kingdom: &"fire" / &"shadow" / &"ice" / &"nature" (unknown or unavailable = Fire, else
## the first available one).
func set_player_kingdom(kingdom: StringName) -> void:
	_player = _pick_available(kingdom, &"fire")
	_select_card(kingdom_buttons, _player)
	_update_matchup()
	if skirmish_panel and skirmish_panel.visible:
		_focus_diorama(_player)


## Glides the diorama camera to a wizard (&"" = wide shot). Only on wide windows (> 2:1): at 16:9 the skirmish
## panel would hide the close-up.
func _focus_diorama(kingdom: StringName) -> void:
	if diorama == null or not diorama.has_method(&"focus_kingdom"):
		return
	var size := get_viewport_rect().size
	if kingdom != &"" and size.x < size.y * 2.0:
		kingdom = &""
	diorama.call(&"focus_kingdom", kingdom)


func get_player_kingdom() -> StringName:
	return _player


## "Vessa of Fire  vs  Malrik of Shadow" (the line under the title).
func matchup_text() -> String:
	return "%s of %s  vs  %s of %s" % [KingdomCard.wizard_name_of(_player), KingdomCard.kingdom_name_of(_player),
			KingdomCard.wizard_name_of(_enemy), KingdomCard.kingdom_name_of(_enemy)]


## Launches the 1v1 with the chosen difficulty and kingdoms. Returns the new level.
func start_skirmish() -> Node:
	return MenuFlow.start_skirmish(get_tree(), _difficulty, _enemy, _player)


func _select_card(cards: Array[Button], kingdom: StringName) -> void:
	for b in cards:
		var card := b as KingdomCard
		if card != null:
			card.set_selected(card.kingdom == kingdom)


func _update_matchup() -> void:
	if foe_label:
		foe_label.text = matchup_text()


# ---------------------------------------------------------------- campaign

## Rebuilds the mission states: unlocked + built = playable, unlocked but not built = "coming soon",
## else "Locked". Keeps the choice if still playable, else picks the last playable mission.
func refresh_missions() -> void:
	var unlocked := _unlocked_missions()
	for i in mission_ids.size():
		var id := mission_ids[i]
		var b := mission_buttons[i]
		var title: String = MISSION_TITLES.get(id, "Mission %d" % (i + 1))
		var open := unlocked.has(id)
		var built := _mission_available(id)
		b.disabled = not (open and built)
		if not open:
			b.text = "   %d.  Locked" % (i + 1)
			b.tooltip_text = "Win the previous mission to unlock it."
		elif not built:
			b.text = "   %d.  %s  (coming soon)" % [i + 1, title]
			b.tooltip_text = "Coming soon"
		else:
			b.text = "   %d.  %s" % [i + 1, title]
			b.tooltip_text = ""
	if not is_mission_playable(_mission):
		_mission = &""
		for i in mission_ids.size():
			if not mission_buttons[i].disabled:
				_mission = mission_ids[i]
	set_mission(_mission)


func set_mission(id: StringName) -> void:
	_mission = id if is_mission_playable(id) else &""
	for i in mission_ids.size():
		mission_buttons[i].set_pressed_no_signal(mission_ids[i] == _mission)
	if campaign_start_button:
		campaign_start_button.disabled = _mission == &""


func get_mission() -> StringName:
	return _mission


func is_mission_playable(id: StringName) -> bool:
	var i := mission_ids.find(id)
	return i >= 0 and not mission_buttons[i].disabled


## Starts the chosen mission with the chosen difficulty. Returns the new level (null = none).
func start_mission() -> Node:
	if _mission == &"":
		return null
	return MenuFlow.start_mission(get_tree(), mission_scene(_mission), _difficulty)


## The scene of a mission (CampaignState, fallback mission 1 = res://missions/mission_01.tscn).
func mission_scene(id: StringName) -> String:
	var p := CampaignState.mission_scene(id)
	if p == "" and id == &"m01":
		p = "res://missions/mission_01.tscn"
	return p


func _unlocked_missions() -> Array[StringName]:
	var out: Array[StringName] = []
	var cs := CampaignState.open()
	if cs != null:
		out = cs.unlocked_missions()
	if out.is_empty():
		out.append(&"m01")
	return out


func _mission_available(id: StringName) -> bool:
	return ResourceLoader.exists(mission_scene(id))


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE and not main_panel.visible:
		if settings_panel.visible:
			settings_panel.close()
		else:
			show_main()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- building

func _build_main_panel(parent: Control) -> PanelContainer:
	var panel := UIStyle.panel(parent, 22.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	skirmish_button = _menu_button(box, "Skirmish 1v1")
	skirmish_button.pressed.connect(show_skirmish_setup)
	campaign_button = _menu_button(box, "Campaign")
	campaign_button.pressed.connect(show_campaign)
	settings_button = _menu_button(box, "Settings")
	settings_button.pressed.connect(show_settings)
	quit_button = _menu_button(box, "Quit")
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	return panel


func _build_skirmish_panel(parent: Control) -> PanelContainer:
	var panel := UIStyle.panel(parent, 24.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := UIStyle.label("Skirmish 1v1", 34)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	foe_label = UIStyle.label("", 18)
	foe_label.modulate = Color(1, 1, 1, 0.85)
	foe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(foe_label)

	# 8.U1: two rows of 4 kingdom cards (You / Enemy), mirror matches allowed.
	var player_group := ButtonGroup.new()
	player_group.allow_unpress = false
	kingdom_buttons = _card_row(box, "YOU", "Your kingdom", player_group, set_player_kingdom)
	var enemy_group := ButtonGroup.new()
	enemy_group.allow_unpress = false
	enemy_buttons = _card_row(box, "ENEMY", "The bot", enemy_group, set_enemy)

	var diff_row := HBoxContainer.new()
	diff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_row.add_theme_constant_override("separation", 10)
	box.add_child(diff_row)
	var diff_title := UIStyle.label("Opponent difficulty", 20)
	diff_title.custom_minimum_size = Vector2(0, 44)
	diff_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	diff_row.add_child(diff_title)
	var diff_group := ButtonGroup.new()
	for i in DIFFICULTY_NAMES.size():
		var b := _toggle_button(diff_row, DIFFICULTY_NAMES[i], diff_group)
		var index := i
		b.pressed.connect(func() -> void: set_difficulty(index))
		difficulty_buttons.append(b)

	# Step 10 (10.C8 glue): trade on / off for the skirmish.
	var trade_row := HBoxContainer.new()
	trade_row.alignment = BoxContainer.ALIGNMENT_CENTER
	trade_row.add_theme_constant_override("separation", 10)
	box.add_child(trade_row)
	var trade_title := UIStyle.label("Trade and guilds", 20)
	trade_title.custom_minimum_size = Vector2(0, 44)
	trade_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trade_row.add_child(trade_title)
	var trade_group := ButtonGroup.new()
	for on: bool in [true, false]:
		var tb := _toggle_button(trade_row, "On" if on else "Off", trade_group)
		tb.tooltip_text = "Trading posts, Bazaars, caravans, Magpies and the Greywater Lodges (skirmish only)."
		tb.set_pressed_no_signal(GameSettings.trade_enabled == on)
		tb.pressed.connect(func() -> void: GameSettings.set_trade_enabled(on))

	# Step 16a: match time limit (Off / 30 / 45 min); at the limit the higher score wins.
	var limit_row := HBoxContainer.new()
	limit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	limit_row.add_theme_constant_override("separation", 10)
	box.add_child(limit_row)
	var limit_title := UIStyle.label("Time limit", 20)
	limit_title.custom_minimum_size = Vector2(0, 44)
	limit_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	limit_row.add_child(limit_title)
	var limit_group := ButtonGroup.new()
	time_limit_buttons.clear()
	for minutes: int in GameSettings.TIME_LIMIT_CHOICES:
		var lb := _toggle_button(limit_row, "Off" if minutes == 0 else "%d min" % minutes, limit_group)
		lb.tooltip_text = "Off: the match ends only when a side has no building left or concedes.\n" \
				+ "30 / 45 min: at the limit the match ends and the higher score wins."
		lb.set_pressed_no_signal(GameSettings.time_limit_min == minutes)
		lb.pressed.connect(func() -> void: GameSettings.set_time_limit(minutes))
		time_limit_buttons.append(lb)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	box.add_child(actions)
	var back := _menu_button(actions, "Back")
	back.custom_minimum_size = Vector2(180, 48)
	back.pressed.connect(show_main)
	start_button = _menu_button(actions, "Start")
	start_button.custom_minimum_size = Vector2(220, 48)
	UIStyle.style_button(start_button, UIStyle.GOLD)
	start_button.pressed.connect(start_skirmish)

	set_difficulty(_difficulty)
	set_player_kingdom(_player)
	set_enemy(_enemy)
	return panel


## A row: side tag ("YOU" / "ENEMY" + a muted line) then the 4 kingdom cards. Returns the cards.
func _card_row(parent: Control, tag: String, sub: String, group: ButtonGroup, choose: Callable) -> Array[Button]:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(92, 0)
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(side)
	var tag_label := UIStyle.display_label(tag, 22, UIStyle.GOLD if tag == "YOU" else Color(0.95, 0.55, 0.45))
	side.add_child(tag_label)
	var sub_label := UIStyle.panel_label(sub, 13, Color(0.72, 0.68, 0.64))
	side.add_child(sub_label)
	var cards: Array[Button] = []
	for k: StringName in KingdomCard.ORDER:
		var card := KingdomCard.create(k)
		card.button_group = group
		var kk := k
		card.pressed.connect(func() -> void: choose.call(kk))
		row.add_child(card)
		if not kingdom_available(k):
			card.set_unavailable()
		cards.append(card)
	return cards


func _build_campaign_panel(parent: Control) -> PanelContainer:
	var panel := UIStyle.panel(parent, 24.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := UIStyle.label("Campaign", 34)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var who := UIStyle.label("Vessa, apprentice of Fire", 17)
	who.modulate = Color(1, 1, 1, 0.8)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(who)

	box.add_child(UIStyle.label("Mission", 20))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	box.add_child(list)
	var group := ButtonGroup.new()
	for id: StringName in CampaignState.MISSION_ORDER:
		var b := _toggle_button(list, "", group)
		b.custom_minimum_size = Vector2(470, 44)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var mid := id
		b.pressed.connect(func() -> void: set_mission(mid))
		mission_ids.append(id)
		mission_buttons.append(b)

	box.add_child(UIStyle.label("Opponent difficulty", 20))
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 10)
	box.add_child(diff_row)
	var diff_group := ButtonGroup.new()
	for i in DIFFICULTY_NAMES.size():
		var b := _toggle_button(diff_row, DIFFICULTY_NAMES[i], diff_group)
		var index := i
		b.pressed.connect(func() -> void: set_difficulty(index))
		campaign_difficulty_buttons.append(b)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	box.add_child(actions)
	var back := _menu_button(actions, "Back")
	back.custom_minimum_size = Vector2(180, 48)
	back.pressed.connect(show_main)
	campaign_start_button = _menu_button(actions, "Start")
	campaign_start_button.custom_minimum_size = Vector2(220, 48)
	UIStyle.style_button(campaign_start_button, UIStyle.GOLD)
	campaign_start_button.pressed.connect(start_mission)

	set_difficulty(_difficulty)
	refresh_missions()
	panel.visible = false
	return panel


func _menu_button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.5))
	UIStyle.style_button(b, UIStyle.PANEL_BORDER)
	parent.add_child(b)
	return b


func _toggle_button(parent: Control, text: String, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(150, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.48, 0.46))
	b.add_theme_color_override("font_pressed_color", UIStyle.GOLD)
	UIStyle.style_button(b, UIStyle.PANEL_BORDER)
	b.add_theme_stylebox_override("hover_pressed", UIStyle.button_style(UIStyle.GOLD, Color(0.3, 0.22, 0.12, 0.95)))
	parent.add_child(b)
	return b
