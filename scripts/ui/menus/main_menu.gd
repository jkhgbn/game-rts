class_name MainMenu
extends Control
## The title screen (task 5.U1): Skirmish 1v1 (setup panel, 8.U1: You / Enemy rows of 4 kingdom
## cards, difficulty, Start; MT9: the map picker on its left: 1v1 / 2v2 seat filter, the MapCatalog's ready maps with
## their mapsheet preview, size / players / biome / hook line, a "Random" entry),
## Campaign (7.U1: mission list from CampaignState, difficulty, Start), Unit Guide (UnitGuide, docs/design/unit-guide.md),
## Settings, Quit.
## Painted gradient background with drifting embers.

const TAGLINE := "The Master is gone. Four apprentices fight over what he left behind."
const DIFFICULTY_NAMES := ["Easy", "Normal", "Hard"]   # Commander.Difficulty order
## Map picker words shown through Loc.t (biomes and kingdom looks of data/maps/catalog.tres), listed for the extractor.
const MAP_WORDS := ["Autumn", "Grass", "Marsh", "Meadow", "Snow", "Neutral", "Fire", "Ice", "Nature", "Shadow"]
## Campaign mission titles (mission-01.md); ids and scenes come from CampaignState.
const MISSION_TITLES := {&"m00": "The Night of Knives", &"m01": "The Crown in the Ashes",
		&"m02": "The Orb Beneath the Ice", &"m04": "The Hollow Throne", &"e2m1": "The Burning Grove"}
const MENU_DIORAMA := "res://art/environment/menu_diorama/menu_diorama.tscn"
const MAP_LIST_W := 250.0     ## MT9 map picker: the list's width (px)...
const MAP_PREVIEW := 230.0    ## ...the preview square beside it (the mapsheet render, data/maps/previews/<id>.png)...
const MAP_COLUMN_W := MAP_LIST_W + 10.0 + MAP_PREVIEW + 4.0   ## ...and the whole column (lines under both).
## Dev tool (docs/plan/unit-lab.md): the Unit Lab sandbox, opened by `-- --unit-lab` or Ctrl+Shift+U (debug builds).
const UNIT_LAB_SCENE := "res://scenes/unit_lab.tscn"
const WS_LOBBY := "res://scripts/ui/wave_strike/wave_strike_lobby.gd"

var diorama: Node3D   ## MenuDiorama (3D background); null if the scene is missing.

var main_panel: PanelContainer
var skirmish_panel: PanelContainer
var settings_panel: SettingsPanel
var skirmish_button: Button
var wave_strike_button: Button   ## Wave Strike (docs/design/wave-strike.md M1): opens ws_panel.
var ws_panel: Control            ## WaveStrikeLobby (scripts/ui/wave_strike/wave_strike_lobby.gd); null if missing.
var campaign_button: Button
var settings_button: Button
var unit_guide_button: Button
var unit_guide: UnitGuide   ## Built on first open (show_unit_guide); null before.
var menu_column: VBoxContainer   ## Title + panels; hidden while the Unit Guide fills the screen.
var quit_button: Button
var start_button: Button
var difficulty_buttons: Array[Button] = []
var time_limit_buttons: Array[Button] = []   ## 16a: Off / 30 min / 45 min (GameSettings.TIME_LIMIT_CHOICES order).
var pace_buttons: Array[Button] = []   ## Pace: Normal, Fast (test), Blitz (GameSettings.pace_mode()).
var kingdom_buttons: Array[Button] = []   ## The 4 "You" KingdomCards (KingdomCard.ORDER).
var enemy_buttons: Array[Button] = []     ## The 4 "Enemy" KingdomCards (KingdomCard.ORDER).
var foe_label: Label                      ## The matchup line: "Vessa of Fire  vs  Malrik of Shadow".
var campaign_panel: PanelContainer
var mission_buttons: Array[Button] = []          ## One per mission of CampaignState.MISSION_ORDER.
var mission_ids: Array[StringName] = []
var campaign_difficulty_buttons: Array[Button] = []
var campaign_start_button: Button
## U5-1: the mission list scrolls inside a height-capped box so Back / Watch / Start stay on screen at 900-1440 p.
var campaign_list_scroll: ScrollContainer
var prologue_button: Button                       ## Campaign panel: replays the prologue cinematic.
## MT9 map picker (skirmish panel): the seat filter (1v1 = 2-seat maps, 2v2 = 4-seat maps), the list (item 0 =
## Random, then the catalog's ready maps of the filter), the preview (data/maps/previews/<id>.png) and the info lines.
var map_filter_buttons: Array[Button] = []        ## [1v1, 2v2]
var map_list: ItemList
var map_preview: TextureRect
var map_preview_mark: Label                        ## The "?" over the preview while Random is chosen.
var map_title_label: Label
var map_info_label: Label
var map_note_label: Label                          ## "2v2 map: plays as a 1v1 for now..." ("" = hidden).
## [Label, English msgid] of the all-caps tags (MAP / YOU / ENEMY): set through Loc.t (the string extractor skips
## all-caps plain literals) and re-set on a language switch.
var _caps_labels: Array = []
var map_list_ids: Array[StringName] = []           ## Item index -> map id (MapCatalog.RANDOM_ID first).

## U5-1: screen height used by the campaign panel around the mission list (title, hero line, labels, difficulty row,
## buttons, margins, menu title above the panel).
const CAMPAIGN_CHROME_H := 640.0
var _difficulty := 1   # Commander.Difficulty.NORMAL
var _enemy: StringName = &"shadow"
var _player: StringName = &"fire"
var _mission: StringName = &""
var _map: StringName = MapCatalog.DEFAULT_ID
var _map_seats := MapCatalog.SEATS_1V1


func _ready() -> void:
	MenuFlow.clear_loaded_match()   # W1-3: back at the menu (or off to the Unit Lab): no loaded match to restart
	# Dev only (docs/plan/unit-lab.md): `-- --unit-lab` opens the Unit Lab sandbox instead of the menu.
	if OS.get_cmdline_user_args().has("--unit-lab") and ResourceLoader.exists(UNIT_LAB_SCENE):
		get_tree().change_scene_to_file.call_deferred(UNIT_LAB_SCENE)
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UIStyle.game_theme()   # U7: Alegreya body text, Cinzel headers (null = engine default)
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
	menu_column = column
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	add_child(column)

	var title := UIStyle.use_title_font(UIStyle.label("Four Wizards", 84))
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
	if ResourceLoader.exists(WS_LOBBY):
		ws_panel = (load(WS_LOBBY) as GDScript).new()
		holder.add_child(ws_panel)
		ws_panel.visible = false
		ws_panel.connect(&"back_requested", show_main)
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


## Live language switch (localization.md): auto-translated labels redraw by themselves; the text built in code
## (matchup, map list / info, mission list) is rebuilt here.
func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or not is_node_ready():
		return
	for p: Array in _caps_labels:
		(p[0] as Label).text = Loc.t(p[1])
	_update_matchup()
	if map_list != null:
		_fill_map_list()
		select_map(_map)
	if not mission_buttons.is_empty():
		refresh_missions()


# ---------------------------------------------------------------- public

func show_main() -> void:
	_hide_unit_guide()
	_hide_ws_panel()
	main_panel.visible = true
	skirmish_panel.visible = false
	campaign_panel.visible = false
	settings_panel.visible = false
	skirmish_button.grab_focus()
	_focus_diorama(&"")


func show_skirmish_setup() -> void:
	_hide_ws_panel()
	main_panel.visible = false
	skirmish_panel.visible = true
	campaign_panel.visible = false
	settings_panel.visible = false
	start_button.grab_focus()
	_focus_diorama(_player)


## The campaign panel: the mission list is re-read from the campaign save each time it opens.
func show_campaign() -> void:
	_hide_ws_panel()
	main_panel.visible = false
	skirmish_panel.visible = false
	settings_panel.visible = false
	refresh_missions()
	campaign_panel.visible = true
	campaign_start_button.grab_focus()


func show_settings() -> void:
	_hide_ws_panel()
	main_panel.visible = false
	skirmish_panel.visible = false
	campaign_panel.visible = false
	settings_panel.open()


## The Unit Guide (docs/design/unit-guide.md) over the whole window; Back / Esc returns to the main panel.
func show_unit_guide() -> void:
	if unit_guide == null:
		unit_guide = UnitGuide.new()
		unit_guide.visible = false
		add_child(unit_guide)
		unit_guide.closed.connect(show_main)
	main_panel.visible = false
	skirmish_panel.visible = false
	campaign_panel.visible = false
	settings_panel.visible = false
	_hide_ws_panel()
	menu_column.visible = false
	unit_guide.open()


## The Wave Strike lobby (docs/design/wave-strike.md 7.4, M1: Ashwind Reach, your kingdom, Start).
func show_wave_strike() -> void:
	if ws_panel == null:
		return
	main_panel.visible = false
	skirmish_panel.visible = false
	campaign_panel.visible = false
	settings_panel.visible = false
	ws_panel.visible = true
	if ws_panel.has_method(&"focus_start"):
		ws_panel.call(&"focus_start")


func _hide_ws_panel() -> void:
	if ws_panel:
		ws_panel.visible = false


func is_unit_guide_open() -> bool:
	return unit_guide != null and unit_guide.visible


func _hide_unit_guide() -> void:
	if menu_column:
		menu_column.visible = true
	if unit_guide and unit_guide.visible:
		unit_guide.visible = false


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
	return Loc.t("%s  vs  %s") % [KingdomCard.of_line(_player), KingdomCard.of_line(_enemy)]


## Launches the 1v1 with the chosen difficulty, kingdoms and map (saved as the next default). Returns the new level.
func start_skirmish() -> Node:
	GameSettings.set_map_id(_map, true, _map_seats)
	return MenuFlow.start_skirmish(get_tree(), _difficulty, _enemy, _player, _map, _map_seats)


# ---------------------------------------------------------------- map picker (MT9)

## Shows the maps with `seats` players (MapCatalog.SEATS_1V1 = 2 or SEATS_2V2 = 4); keeps the chosen map when it is
## in the new list, else picks the first map of it (Crown Hollow in 1v1).
func set_map_filter(seats: int) -> void:
	_map_seats = MapCatalog.SEATS_2V2 if seats >= MapCatalog.SEATS_2V2 else MapCatalog.SEATS_1V1
	for i in map_filter_buttons.size():
		map_filter_buttons[i].set_pressed_no_signal(i == (1 if _map_seats == MapCatalog.SEATS_2V2 else 0))
	_fill_map_list()
	if not map_list_ids.has(_map):
		var first: StringName = map_list_ids[1] if map_list_ids.size() > 1 else MapCatalog.RANDOM_ID
		if _map_seats == MapCatalog.SEATS_1V1 and map_list_ids.has(MapCatalog.DEFAULT_ID):
			first = MapCatalog.DEFAULT_ID
		_map = first
	select_map(_map)


func get_map_filter() -> int:
	return _map_seats


## Chooses a map (a ready catalog id or MapCatalog.RANDOM_ID). A map of the other seat count switches the filter;
## an unknown or not-ready id is ignored. Updates the list selection, the preview and the info lines.
func select_map(id: StringName) -> void:
	var cat := MapCatalog.load_default()
	if id != MapCatalog.RANDOM_ID:
		if not cat.is_ready(id):
			return
		var seats := int(cat.entry(id).get("seats", 2))
		if seats != _map_seats and map_list != null:
			_map = id
			set_map_filter(seats)
			return
	_map = id
	GameSettings.set_map_id(id, false, _map_seats)
	if map_list == null:
		return
	var idx := map_list_ids.find(id)
	if idx >= 0 and not (map_list.is_selected(idx) and map_list.get_selected_items().size() == 1):
		map_list.select(idx)
		map_list.ensure_current_is_visible()
	_show_map_info()


func get_map() -> StringName:
	return _map


## The map ids the picker lists right now (Random first).
func listed_maps() -> Array[StringName]:
	return map_list_ids.duplicate()


func _fill_map_list() -> void:
	if map_list == null:
		return
	var cat := MapCatalog.load_default()
	map_list.clear()
	map_list_ids.clear()
	var mode := "2v2" if _map_seats == MapCatalog.SEATS_2V2 else "1v1"
	var ri := map_list.add_item(Loc.t("Random %s map") % mode, _random_icon())
	map_list.set_item_tooltip(ri, "A ready map drawn at Start (a restart replays the same map).")
	map_list_ids.append(MapCatalog.RANDOM_ID)
	for e: Dictionary in cat.list(_map_seats, true):
		var id := StringName(e["id"])
		var sz: Vector2 = e.get("size", Vector2(120, 120))
		var i := map_list.add_item("%s  ·  %d m" % [String(e.get("title", id)), int(maxf(sz.x, sz.y))], cat.preview_texture(id))
		map_list.set_item_tooltip(i, "%s\n%s" % [Loc.sink(MapCatalog.size_text(e)), Loc.t(String(e.get("hook", "")))])
		map_list_ids.append(id)


func _show_map_info() -> void:
	var cat := MapCatalog.load_default()
	var mode := "2v2" if _map_seats == MapCatalog.SEATS_2V2 else "1v1"
	if _map == MapCatalog.RANDOM_ID:
		map_preview.texture = null
		map_preview_mark.visible = true
		map_title_label.text = "Random map"
		map_info_label.text = Loc.t("One of the %d ready %s maps, drawn when the match starts.") % [cat.list(_map_seats, true).size(), mode]
		map_note_label.text = Loc.sink(MapCatalog.mode_note({"seats": _map_seats}))
	else:
		var e := cat.entry(_map)
		map_preview.texture = cat.preview_texture(_map)
		map_preview_mark.visible = map_preview.texture == null
		map_title_label.text = String(e.get("title", _map))
		map_info_label.text = Loc.t("%s · %s · %s look\n%s") % [Loc.sink(MapCatalog.size_text(e)),
				Loc.t(String(e.get("biome", "grass")).capitalize()), Loc.t(String(e.get("kingdom", "neutral")).capitalize()),
				Loc.t(String(e.get("hook", "")))]
		map_note_label.text = Loc.sink(MapCatalog.mode_note(e))
	map_note_label.visible = map_note_label.text != ""


## A small die face (the Random entry's icon).
static func _random_icon() -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.16, 0.13, 0.11))
	for x in 48:
		for y in 48:
			if x < 2 or y < 2 or x > 45 or y > 45:
				img.set_pixel(x, y, UIStyle.GOLD)
	for c: Vector2i in [Vector2i(13, 13), Vector2i(35, 13), Vector2i(24, 24), Vector2i(13, 35), Vector2i(35, 35)]:
		for dx in range(-4, 5):
			for dy in range(-4, 5):
				if dx * dx + dy * dy <= 16:
					img.set_pixel(c.x + dx, c.y + dy, Color(0.95, 0.88, 0.7))
	return ImageTexture.create_from_image(img)


func _build_map_column(parent: Control) -> void:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(MAP_COLUMN_W, 0)
	col.add_theme_constant_override("separation", 8)
	parent.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	var tag := UIStyle.display_label(Loc.t("MAP"), 22, UIStyle.GOLD)
	tag.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_caps_labels.append([tag, "MAP"])
	tag.custom_minimum_size = Vector2(70, 40)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(tag)
	var group := ButtonGroup.new()
	group.allow_unpress = false
	map_filter_buttons.clear()
	for seats: int in [MapCatalog.SEATS_1V1, MapCatalog.SEATS_2V2]:
		var b := _toggle_button(head, "1v1" if seats == MapCatalog.SEATS_1V1 else "2v2", group)
		b.custom_minimum_size = Vector2(118, 40)
		b.tooltip_text = "Maps for 2 players." if seats == MapCatalog.SEATS_1V1 \
				else "Maps for 4 players (played as a 1v1 until 2v2 skirmish comes)."
		var s := seats
		b.pressed.connect(func() -> void: set_map_filter(s))
		map_filter_buttons.append(b)
	# the list and the preview side by side (the setup panel must fit a 1600 x 900 window), the lines below them
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 10)
	col.add_child(mid)
	map_list = ItemList.new()
	map_list.custom_minimum_size = Vector2(MAP_LIST_W, MAP_PREVIEW + 8.0)
	map_list.fixed_icon_size = Vector2i(44, 44)
	map_list.icon_mode = ItemList.ICON_MODE_LEFT
	map_list.select_mode = ItemList.SELECT_SINGLE
	map_list.allow_reselect = true
	map_list.focus_mode = Control.FOCUS_ALL
	map_list.add_theme_font_size_override("font_size", 16)
	map_list.add_theme_constant_override("v_separation", 6)
	map_list.add_theme_color_override("font_selected_color", UIStyle.GOLD)
	map_list.item_selected.connect(_on_map_item_selected)
	map_list.item_activated.connect(func(_i: int) -> void: start_button.grab_focus())
	mid.add_child(map_list)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIStyle.button_style(UIStyle.PANEL_BORDER, Color(0.07, 0.06, 0.06, 0.95)))
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mid.add_child(frame)
	map_preview = TextureRect.new()
	map_preview.custom_minimum_size = Vector2(MAP_PREVIEW, MAP_PREVIEW)
	map_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(map_preview)
	map_preview_mark = UIStyle.display_label("?", 96, UIStyle.GOLD)
	map_preview_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_preview_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	map_preview_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(map_preview_mark)
	map_title_label = UIStyle.display_label("", 20, UIStyle.GOLD)
	col.add_child(map_title_label)
	map_info_label = UIStyle.panel_label("", 15, Color(0.86, 0.82, 0.76))
	map_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_info_label.custom_minimum_size = Vector2(MAP_COLUMN_W, 0)
	col.add_child(map_info_label)
	map_note_label = UIStyle.panel_label("", 14, Color(0.95, 0.7, 0.45))
	map_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_note_label.custom_minimum_size = Vector2(MAP_COLUMN_W, 0)
	col.add_child(map_note_label)
	var cat := MapCatalog.load_default()
	var want := GameSettings.map_id
	if want != MapCatalog.RANDOM_ID and not cat.is_ready(want):
		want = MapCatalog.DEFAULT_ID
	_map = want
	set_map_filter(int(cat.entry(want).get("seats", MapCatalog.SEATS_1V1)) if want != MapCatalog.RANDOM_ID \
			else GameSettings.map_seats)   # U5-3: a saved Random keeps its 1v1 / 2v2 filter


func _on_map_item_selected(i: int) -> void:
	if i >= 0 and i < map_list_ids.size():
		select_map(map_list_ids[i])


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
## else "Locked". Keeps the choice if still playable, else picks the first playable mission not won yet (else the last
## playable one).
func refresh_missions() -> void:
	var unlocked := _unlocked_missions()
	for i in mission_ids.size():
		var id := mission_ids[i]
		var b := mission_buttons[i]
		var title: String = Loc.t(MISSION_TITLES[id]) if MISSION_TITLES.has(id) else Loc.t("Mission %d") % (i + 1)
		var open := unlocked.has(id)
		var built := _mission_available(id)
		b.disabled = not (open and built)
		if not open:
			b.text = "   " + Loc.t("%d.  Locked") % (i + 1)
			b.tooltip_text = "Win the previous mission to unlock it."
		elif not built:
			b.text = "   " + Loc.t("%d.  %s  (coming soon)") % [i + 1, title]
			b.tooltip_text = "Coming soon"
		else:
			b.text = "   %d.  %s" % [i + 1, title]
			b.tooltip_text = ""
	if not is_mission_playable(_mission):
		# The first playable mission not won yet (a new campaign opens on mission 0), else the last playable one.
		_mission = &""
		var cs := CampaignState.open()
		for i in mission_ids.size():
			if not mission_buttons[i].disabled:
				_mission = mission_ids[i]
				if cs != null and not cs.is_completed(mission_ids[i]):
					break
	set_mission(_mission)


func set_mission(id: StringName) -> void:
	_mission = id if is_mission_playable(id) else &""
	for i in mission_ids.size():
		mission_buttons[i].set_pressed_no_signal(mission_ids[i] == _mission)
		if mission_ids[i] == _mission and campaign_list_scroll != null and campaign_list_scroll.is_inside_tree():
			campaign_list_scroll.ensure_control_visible.call_deferred(mission_buttons[i])
	if campaign_start_button:
		campaign_start_button.disabled = _mission == &""
	_refresh_watch_button()


## The watch button replays the selected mission's episode opening (StoryFilms.opening_of: ep3_opening before e3m1)
## when it has one, else the prologue.
func _refresh_watch_button() -> void:
	if prologue_button == null:
		return
	var film := _watch_film()
	prologue_button.text = "Watch opening" if film != &"" else "Watch prologue"
	prologue_button.tooltip_text = "The episode's opening film. Plays before this mission the first time." if film != &"" \
			else "The story so far (3 min). Plays before mission 1 the first time."
	prologue_button.disabled = not (film != &"" or MenuFlow.prologue_available())


func _watch_film() -> StringName:
	var film := StoryFilms.opening_of(_mission) if _mission != &"" else &""
	return film if film != &"" and StoryFilms.available(film) else &""


func get_mission() -> StringName:
	return _mission


func is_mission_playable(id: StringName) -> bool:
	var i := mission_ids.find(id)
	return i >= 0 and not mission_buttons[i].disabled


## Starts the chosen mission with the chosen difficulty. Returns the new level (null = none).
func start_mission() -> Node:
	if _mission == &"":
		return null
	return MenuFlow.start_campaign_mission(get_tree(), _mission, mission_scene(_mission), _difficulty)


## "Watch prologue": replays the campaign prologue, then back to the main menu.
func watch_prologue() -> Node:
	var film := _watch_film()
	if film != &"":
		return StoryFilms.play_only(get_tree(), film)
	return MenuFlow.play_prologue(get_tree(), "", _difficulty)


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
	# Dev only: Ctrl+Shift+U opens the Unit Lab sandbox (debug builds; not shown in the player menu).
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_U and key.ctrl_pressed and key.shift_pressed \
			and OS.is_debug_build() and ResourceLoader.exists(UNIT_LAB_SCENE):
		get_tree().change_scene_to_file.call_deferred(UNIT_LAB_SCENE)
		get_viewport().set_input_as_handled()
		return
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE and main_panel and not main_panel.visible:
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
	if ResourceLoader.exists(WS_LOBBY):
		wave_strike_button = _menu_button(box, "Wave Strike")
		wave_strike_button.tooltip_text = "Buy cards, send waves down one lane, break the enemy Bastion (new mode, 1v1)."
		wave_strike_button.pressed.connect(show_wave_strike)
	campaign_button = _menu_button(box, "Campaign")
	campaign_button.pressed.connect(show_campaign)
	unit_guide_button = _menu_button(box, "Unit Guide")
	unit_guide_button.tooltip_text = "Every unit of the four kingdoms: stats, abilities, pros and cons, counters."
	unit_guide_button.pressed.connect(show_unit_guide)
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
	var title := UIStyle.use_title_font(UIStyle.label("Skirmish 1v1", 34))
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	foe_label = UIStyle.label("", 18)
	foe_label.modulate = Color(1, 1, 1, 0.85)
	foe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(foe_label)

	# MT9: the map picker on the left, the matchup and options on the right.
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	box.add_child(columns)
	_build_map_column(columns)
	var outer := box
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	columns.add_child(box)

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
		var lb := _toggle_button(limit_row, "Off" if minutes == 0 else Loc.t("%d min") % minutes, limit_group)
		lb.tooltip_text = "Off: the match ends only when a side has no building left or concedes.\n" \
				+ "30 / 45 min: at the limit the match ends and the higher score wins."
		lb.set_pressed_no_signal(GameSettings.time_limit_min == minutes)
		lb.pressed.connect(func() -> void: GameSettings.set_time_limit(minutes))
		time_limit_buttons.append(lb)

	# Pace (faster_games_2026-10-06.md, A2): Normal (default) or Fast (test), applied in memory at match start. On the
	# trade row, so the panel still fits 1600 x 900 (test_mt9_map_picker).
	var pace_row := trade_row
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(18, 0)
	pace_row.add_child(gap)
	var pace_title := UIStyle.label("Pace", 20)
	pace_title.custom_minimum_size = Vector2(0, 44)
	pace_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pace_row.add_child(pace_title)
	var pace_group := ButtonGroup.new()
	pace_buttons.clear()
	var pace_names: Array[String] = ["Normal", "Fast (test)", "Blitz"]
	var pace_tips: Array[String] = ["Normal: the usual game.",
			"Fast (test): buildings have less HP, towers hit softer, units train faster
and the bots attack sooner (skirmish only).",
			"Blitz: 9 starting workers, weaker buildings, faster training and keep upgrades,
bolder bots and a 30 % faster clock. Games last about 8 to 12 minutes (skirmish only)."]
	for mode in 3:
		var pb := _toggle_button(pace_row, pace_names[mode], pace_group)
		pb.tooltip_text = pace_tips[mode]
		pb.custom_minimum_size = Vector2(120, 44)
		pb.set_pressed_no_signal(GameSettings.pace_mode() == mode)
		pb.pressed.connect(func() -> void: GameSettings.set_pace_mode(mode))
		pace_buttons.append(pb)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	outer.add_child(actions)
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
	var tag_label := UIStyle.display_label(Loc.t("YOU") if tag == "YOU" else Loc.t("ENEMY"), 22,
			UIStyle.GOLD if tag == "YOU" else Color(0.95, 0.55, 0.45))
	tag_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_caps_labels.append([tag_label, tag])
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
	var title := UIStyle.use_title_font(UIStyle.label("Campaign", 34))
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var who := UIStyle.label("Vessa, apprentice of Fire", 17)
	who.modulate = Color(1, 1, 1, 0.8)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(who)

	box.add_child(UIStyle.label("Mission", 20))
	campaign_list_scroll = ScrollContainer.new()
	campaign_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	campaign_list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(campaign_list_scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_list_scroll.add_child(list)
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
	prologue_button = _menu_button(actions, "Watch prologue")
	prologue_button.custom_minimum_size = Vector2(220, 48)
	prologue_button.tooltip_text = "The story so far (3 min). Plays before mission 1 the first time."
	prologue_button.disabled = not MenuFlow.prologue_available()
	prologue_button.pressed.connect(watch_prologue)
	campaign_start_button = _menu_button(actions, "Start")
	campaign_start_button.custom_minimum_size = Vector2(220, 48)
	UIStyle.style_button(campaign_start_button, UIStyle.GOLD)
	campaign_start_button.pressed.connect(start_mission)

	set_difficulty(_difficulty)
	refresh_missions()
	fit_campaign_list()
	get_viewport().size_changed.connect(fit_campaign_list)
	panel.visible = false
	return panel


## U5-1: caps the mission list's height to what the screen leaves under the title, difficulty row and buttons
## (the rest scrolls). Called on build and on every window resize.
func fit_campaign_list() -> void:
	if campaign_list_scroll == null or not is_inside_tree():
		return
	var screen_h := get_viewport().get_visible_rect().size.y
	var full := float(mission_buttons.size()) * 52.0
	var room := screen_h - CAMPAIGN_CHROME_H
	campaign_list_scroll.custom_minimum_size = Vector2(490, clampf(room, 132.0, maxf(full, 132.0)))


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
