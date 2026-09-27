class_name GameHUD
extends CanvasLayer
## On-screen interface (layout: docs/design/ui-hud.md): objective, top bar (crystals, pop),
## controls help, minimap, selection panel (hero column + selection), command card,
## and pop-up messages / the victory-defeat banner.

## The command card's Fireball button (main.gd connects it to the selection's Fireball targeting).
signal fireball_pressed

var minimap: Minimap
var top_bar: TopBar
var command_card: CommandCard
var selection_panel: SelectionPanel
var group_bar: ControlGroupBar
var inventory_bar: InventoryBar   ## Vessa's 6 item slots + artifact slot in the hero column (4.U1a).
var shop_window: ShopWindow       ## The shop (4.U1b), toggled with T (physical key).
var champion_bar: ChampionBar     ## The 3 champion slots (9.C7); F5 / F6 / F7 centre on them.
var tavern_window: TavernWindow   ## Hire / revive / dismiss champions (9.C7), toggled with Y or a tavern click.
var trade_window: TradeWindow     ## Wares / exchange / Lodge contracts (10.C8), U; never open with the shop / tavern.
var post_panel: Node              ## Post / Den / Lodge info panel (10.C8, scripts/ui/post_panel.gd), or null.
var trade_popups: Node            ## Trade messages, floating +28 texts, trade sounds (10.C8), or null.
var mapfill_bar: Node             ## Objectives strip, blessing chips, beast boss bars, camp hover chip (12.C7), or null.
var point_panel: Node             ## Capture point panel / game-critter card (12.C7, scripts/ui/point_panel.gd), or null.
var mapfill_popups: Node          ## Map-fill messages (dup filter, 0:40 hint), floating +5 / +40, sounds (12.C7), or null.
var capture_rings: Node           ## 12.C6's capture rings + camp timers in the world (scripts/vfx/capture_rings.gd), or null.
var end_panel: PanelContainer   ## The end screen: banner + stats (hidden while playing).
var end_body: Label             ## The end stats under the banner (the Summary tab).
var end_subtitle: Label         ## 16a: "Won on score" / "Lost on score" under the banner ("" = hidden).
var end_tabs: HBoxContainer     ## 16a: Summary / Score tab buttons (hidden until show_score).
var score_panel: VBoxContainer  ## 16a: the Score tab (table + graph), a ScorePanel (scripts/ui/score_panel.gd).
const SCORE_PANEL_SCRIPT := preload("res://scripts/ui/score_panel.gd")
var end_tab: StringName = &"summary"   ## The end tab shown: END_TAB_SUMMARY or END_TAB_SCORE.
const END_TAB_SUMMARY := &"summary"
const END_TAB_SCORE := &"score"
var _end_tab_buttons := {}

var _hero: Wizard
var _selection: SelectionManager

var _objective: Label
var _message: Label
var _banner: Label
var _help_panel: Control
var _message_time := 0.0
var _root: Control
var _obj_panel: PanelContainer
var _help_label: Label
var _help_name := "your wizard"   # the wizard named in the help
var _help_scheme := -1            # the control scheme the help was written for
var _help_check_left := 0         # frames to the next keyboard-layout re-check
var _map_panel: PanelContainer
var _dim: ColorRect
var _banner_glow: Label
var _end_rule: Control
var _end_tween: Tween
const MESSAGE_FADE := 0.3   ## The message line fades out over its last 0.3 s.
var _hero_levels := {}   # wizard instance id -> last seen level (level-up message)

const MESSAGE_Y := 120.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.hud_theme()   # slate tooltips
	add_child(root)
	_root = root

	# Objective (top left): slate, font 17 in the title colour, outline 3.
	# Read-only panels let clicks through to the battlefield under them.
	var obj_panel := _panel(root)
	obj_panel.add_theme_stylebox_override("panel", UIStyle.slate_style())
	obj_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_panel.position = Vector2(16, 16)
	_obj_panel = obj_panel
	_objective = _label("", 17)
	_objective.add_theme_color_override("font_color", UIStyle.token(&"title"))
	obj_panel.add_child(_objective)

	# Top bar: crystals and population (top centre)
	top_bar = TopBar.new()
	root.add_child(top_bar)
	top_bar.message.connect(show_message)

	# Controls help (top right)
	var help_panel := _panel(root)
	help_panel.add_theme_stylebox_override("panel", UIStyle.slate_style())
	help_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	help_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	help_panel.offset_left = -16.0
	help_panel.offset_right = -16.0
	help_panel.offset_top = 16.0
	help_panel.offset_bottom = 16.0
	# Keys: CLAUDE.md "Keys" / ui-hud.md (lines kept short so the panel stays right of the top bar).
	GameSettings.ensure_read()   # the help follows the saved control scheme (UX.1)
	var help := _label(help_text(_help_name), 13)
	help.modulate = Color(1, 1, 1, 0.8)
	help.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	help_panel.add_child(help)
	_help_panel = help_panel
	_help_label = help

	# Minimap (bottom left, 240 x 240 panel at (16, 644) on a 1600 x 900 screen): heavy frame.
	var map_panel := _panel(root)
	map_panel.add_theme_stylebox_override("panel", UIStyle.frame_style(10.0))
	UIStyle.add_drop_shadow(map_panel)
	_map_panel = map_panel
	_anchor_bottom_left(map_panel, 16.0, 16.0)
	minimap = Minimap.new()
	map_panel.add_child(minimap)

	# Selection panel (bottom, hero column + selection) and command card (bottom right)
	selection_panel = SelectionPanel.new()
	root.add_child(selection_panel)
	group_bar = ControlGroupBar.new()   # control group tabs, just above the selection panel
	root.add_child(group_bar)
	command_card = CommandCard.new()
	command_card.fireball_action = _on_fireball_button
	root.add_child(command_card)
	inventory_bar = InventoryBar.new()   # over the hero column, row at y 834
	root.add_child(inventory_bar)
	inventory_bar.message.connect(show_message)
	# Champion bar (left, above the minimap; hidden while the team has no ChampionGuild).
	champion_bar = ChampionBar.new()
	root.add_child(champion_bar)
	champion_bar.tavern_requested.connect(_on_tavern_requested)

	# Short messages ("Not enough mana") and the big victory/defeat banner
	_message = _label("", 22)
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.position.y = MESSAGE_Y
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_message)

	# End screen (skirmish-1v1.md): the VICTORY / DEFEAT banner and, when the level has one, its
	# stats block (match time, 4 stats, crystals, "F9: play again") in one centred panel.
	# Full-screen dim behind the end panel (fades in over 0.3 s).
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	root.add_child(_dim)
	end_panel = _panel(root)
	end_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_panel.add_theme_stylebox_override("panel", UIStyle.frame_style(24.0))
	UIStyle.add_drop_shadow(end_panel)
	end_panel.custom_minimum_size = Vector2(560, 0)
	end_panel.set_anchors_preset(Control.PRESET_CENTER)
	end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	end_panel.visible = false
	var end_box := VBoxContainer.new()
	end_box.add_theme_constant_override("separation", 12)
	end_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_panel.add_child(end_box)
	_banner = UIStyle.display_label("", 64)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_box.add_child(_banner)
	# trim_glow glow behind the banner: a second label at alpha 0.35, scale 1.03.
	_banner_glow = UIStyle.display_label("", 64)
	_banner_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner_glow.show_behind_parent = true
	_banner_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(_banner_glow)
	# Rule between the banner and the stats: 1 px groove + 1 px frame_light, 400 px wide, centred.
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(400, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.draw.connect(func() -> void:
		rule.draw_rect(Rect2(0, 0, 400, 1), UIStyle.token(&"groove"))
		rule.draw_rect(Rect2(0, 1, 400, 1), UIStyle.token(&"frame_light")))
	end_box.add_child(rule)
	_end_rule = rule
	# 16a: "Won on score" line under the rule, and the Summary / Score tabs (shown once show_score() ran).
	end_subtitle = UIStyle.panel_label("", 22, UIStyle.GOLD)
	end_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_subtitle.visible = false
	end_box.add_child(end_subtitle)
	end_tabs = HBoxContainer.new()
	end_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	end_tabs.add_theme_constant_override("separation", 8)
	end_tabs.visible = false
	end_box.add_child(end_tabs)
	var tab_group := ButtonGroup.new()
	for tab: StringName in [END_TAB_SUMMARY, END_TAB_SCORE]:
		var b := Button.new()
		b.text = "Summary" if tab == END_TAB_SUMMARY else "Score"
		b.toggle_mode = true
		b.button_group = tab_group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(130, 34)
		b.add_theme_font_size_override("font_size", 17)
		UIStyle.style_button(b)
		var t := tab
		b.pressed.connect(func() -> void: select_end_tab(t))
		end_tabs.add_child(b)
		_end_tab_buttons[tab] = b
	end_body = UIStyle.panel_label("", 20)
	end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_body.visible = false
	end_box.add_child(end_body)
	score_panel = SCORE_PANEL_SCRIPT.new()
	score_panel.visible = false
	end_box.add_child(score_panel)


func setup(hero: Wizard, selection: SelectionManager) -> void:
	_hero = hero
	_selection = selection
	# The player's kingdom skins the HUD (ui-style.md 1).
	var before := UIStyle.skin_version
	UIStyle.set_kingdom(kingdom_of(hero))
	if UIStyle.skin_version != before:
		apply_skin()
	_help_name = wizard_short_name(hero)
	_help_label.text = help_text(_help_name)
	selection_panel.setup(hero, selection)
	command_card.setup(selection)
	group_bar.setup(selection)
	inventory_bar.setup(hero, selection)
	if shop_window != null and is_instance_valid(shop_window):
		shop_window.hero = hero   # setup again (the player's wizard changed): keep the one window
	else:
		shop_window = ShopWindow.attach(self, hero)
	if tavern_window != null and is_instance_valid(tavern_window):
		tavern_window.set_hero(hero)
	else:
		tavern_window = TavernWindow.attach(self, hero)
		shop_window.opened.connect(tavern_window.close)   # the shop and the tavern never show together
	champion_bar.tavern_window = tavern_window
	champion_bar.setup(hero, selection)
	# 9.C8 glue (ui-champions.md 13.4): the flag card over the selection area and the bounty-mode chip (the
	# selection manager makes one; attach returns it). Guarded loads: the HUD works without those files.
	attach_optional("res://scripts/ui/flag_card.gd", [self, selection])
	attach_optional("res://scripts/ui/bounty_mode.gd", [self])
	_setup_trade(selection)
	_setup_map_fill(selection)
	# The minimap reads the map size and the artifact from the level (main.gd), when present.
	var level := get_parent()
	var map_size := 120.0
	var artifact: Node3D = null
	if level and level.get_script():
		map_size = float((level.get_script() as Script).get_script_constant_map().get("MAP_SIZE", map_size))
		artifact = level.get("artifact") as Node3D
	var rig: RTSCamera = null
	if selection.camera:
		rig = selection.camera.get_parent() as RTSCamera
	minimap.setup(selection, rig, map_size, artifact)


## Step-10 trade UI (ui-trade.md 16.4): the trade window (exclusive with the shop and the tavern), the post / Den /
## Lodge panel, the trade listener (messages, floating texts, sounds) and 10.C7's route line, each loaded guarded so
## a missing file never breaks the HUD. A Lodge click also opens the window on its tab. Safe to call again.
func _setup_trade(selection: SelectionManager) -> void:
	if trade_window == null or not is_instance_valid(trade_window):
		trade_window = TradeWindow.attach(self)
		shop_window.opened.connect(trade_window.close)
		tavern_window.opened.connect(trade_window.close)
		trade_window.opened.connect(shop_window.close)
		trade_window.opened.connect(tavern_window.close)
	post_panel = attach_optional("res://scripts/ui/post_panel.gd", [self, selection])
	trade_popups = attach_optional("res://scripts/vfx/trade_popups.gd", [self])
	if get_tree().get_first_node_in_group(&"route_line") == null:
		attach_optional("res://scripts/vfx/route_line.gd", [self, selection])
	if selection.has_signal(&"neutral_building_clicked") \
			and not selection.is_connected(&"neutral_building_clicked", _on_neutral_building_clicked):
		selection.connect(&"neutral_building_clicked", _on_neutral_building_clicked)


## Step-12 map-fill UI (ui-mapfill.md 15.4): the objectives strip / boss bars / hover chip, the point panel, the
## listener (messages, floating texts, sounds) and 12.C6's capture rings, each loaded guarded (a missing file, or a
## map without points, camps or beasts, simply shows nothing). Safe to call again.
func _setup_map_fill(selection: SelectionManager) -> void:
	mapfill_bar = attach_optional("res://scripts/ui/mapfill_bar.gd", [self, selection])
	point_panel = attach_optional("res://scripts/ui/point_panel.gd", [self, selection])
	mapfill_popups = attach_optional("res://scripts/vfx/mapfill_popups.gd", [self])
	capture_rings = attach_optional("res://scripts/vfx/capture_rings.gd", [self, selection])


## A trading post or guild house was clicked (10.C7): a Greywater Lodge opens the trade window on its tab; the
## panel (post_panel.gd) shows the rest.
func _on_neutral_building_clicked(node: Node3D) -> void:
	if node == null or not is_instance_valid(node) or trade_window == null:
		return
	if node.is_in_group(&"guilds") and StringName(str(node.get(&"kind"))) == &"lodge":
		trade_window.open(&"lodge")


## Shows / hides the top-left objective panel (the mission UI hides it when it has its own objectives panel).
func set_objective_visible(v: bool) -> void:
	if _obj_panel != null:
		_obj_panel.visible = v


## Is the top-left objective panel shown (for tests)?
func is_objective_visible() -> bool:
	return _obj_panel != null and _obj_panel.visible


## &"fire" / &"shadow" / &"ice" for the player's wizard: its `faction` (or unit type's) if it has one, else its name.
static func kingdom_of(hero: Node) -> StringName:
	if hero == null or not is_instance_valid(hero):
		return &"fire"
	for src: Variant in [hero.get("faction"), hero.get("kingdom")]:
		if src != null and UIStyle.SKINS.has(StringName(str(src))):
			return StringName(str(src))
	var t: Variant = hero.get("unit_type")
	if t is Object and t.get("faction") != null and UIStyle.SKINS.has(StringName(str(t.get("faction")))):
		return StringName(str(t.get("faction")))
	var n := str(hero.get("unit_name")).to_lower()
	if n.contains("ice") or n.contains("torvald"):
		return &"ice"
	if n.contains("nature") or n.contains("ysolde"):
		return &"nature"
	return &"shadow" if n.contains("shadow") or n.contains("malrik") else &"fire"


## "Vessa, Fire Wizard" -> "Vessa" (any wizard); "Your wizard" when there is none.
static func wizard_short_name(hero: Node) -> String:
	if hero == null or not is_instance_valid(hero):
		return "Your wizard"
	var n := str(hero.get("unit_name")).get_slice(",", 0).strip_edges()
	return n if n != "" and n != "<null>" else "Your wizard"


## Tutorial wording for moving the wizard in the current control scheme (UX.1), keyboard labels included:
## Classic "Right-click the ground to move Vessa", Hero WASD "Walk Vessa with W A S D" ("Z Q S D" on AZERTY).
static func walk_hint(wizard_name: String) -> String:
	if GameSettings.hero_wasd():
		return "Walk %s with %s" % [wizard_name, KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D])]
	return "Right-click the ground to move %s" % wizard_name


## Rewrites the help when the control scheme changed (Settings in the pause menu) or the keyboard layout did.
func _refresh_help() -> void:
	_help_check_left -= 1
	if _help_check_left > 0 and _help_scheme == GameSettings.control_scheme:
		return
	refresh_help()


## Rewrites the controls help now (control scheme and keyboard labels).
func refresh_help() -> void:
	if _help_label == null:
		return
	_help_check_left = 60
	_help_scheme = GameSettings.control_scheme
	var text := help_text(_help_name)
	if _help_label.text != text:
		_help_label.text = text


## The last help line (step 12, ui-mapfill.md 12).
const HELP_CAPTURE := "Capture: stand near towers, wells and shrines"


## The controls help (CLAUDE.md "Keys"), naming the player's wizard. Reflowed to 11 lines of <= 438 px for step 10
## (ui-trade.md 14.1: the panel is 458 x 229 at (1126, 16), clear of the 624 px top bar with gold); step 12 adds a
## 12th line (ui-mapfill.md 12: 458 x 248).
## UX.1: lines 2-4 follow the control scheme (Classic: right click moves the wizard, A + click = attack-move;
## Hero WASD: W A S D walk her, X = attack-move) and every letter is the label on the player's keyboard
## (KeyLabels: an AZERTY player reads "Q + click: attack-move", "Z Q S D: walk").
static func help_text(wizard_name: String) -> String:
	var k := func(code: Key) -> String: return KeyLabels.of(code)
	var train := KeyLabels.join([KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B])
	var spells := KeyLabels.join([KEY_F, KEY_Q, KEY_E], " / ")
	var middle := ""
	if GameSettings.hero_wasd():
		middle = ("Right click: move / attack / gather / rally    %s: attack-move    %s: stop\n"
				% [k.call(KEY_X), k.call(KEY_C)]
				+ "%s: hold    %s: gather    %s: build (workers)    %s: train\n"
				% [k.call(KEY_H), k.call(KEY_G), k.call(KEY_B), train]
				+ "Delete: cancel a site    %s: walk %s    %s: spells\n"
				% [KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D]), wizard_name, spells])
	else:
		middle = ("Right click: move (%s too) / attack / gather / rally    %s: stop\n" % [wizard_name, k.call(KEY_C)]
				+ "Attack-move: %s + click (%s too)    %s: hold    %s: gather    %s: build\n"
				% [k.call(KEY_A), k.call(KEY_X), k.call(KEY_H), k.call(KEY_G), k.call(KEY_B)]
				+ "%s: train    Delete: cancel a site    %s: spells\n" % [train, spells])
	return ("Left click / drag: select    Shift: add    Double-click: all of a type\n"
			+ middle
			+ "Ctrl+%s: learn spell    F1: %s    Space: find %s    F9: restart\n"
			% [KeyLabels.join([KEY_F, KEY_Q, KEY_E], "/"), wizard_name, wizard_name]
			+ "Groups 1-0: Ctrl set · Shift add · Alt steal · N N: centre\n"
			+ "F2: army    F3: idle worker    F10 twice: surrender    Numpad 1-6: items\n"
			+ "Arrows / edge: pan    Wheel: zoom    Middle drag: rotate    %s: shop\n" % k.call(KEY_T)
			+ "%s: bounty (Shift+click: stay)    %s: tavern    F5-F7: find champion\n" % [k.call(KEY_R), k.call(KEY_Y)]
			+ "Flag: %s raise · Delete remove    %s: trade & hunters    %s: trade (caravans)\n"
			% [k.call(KEY_Z), k.call(KEY_U), k.call(KEY_G)]
			+ "%s, %s: Bazaar    Bazaar: %s caravan · right-click a post: route\n"
			% [k.call(KEY_B), k.call(KEY_B), k.call(KEY_Z)]
			+ HELP_CAPTURE)


## Re-skins every HUD piece: my panels here, and any child that has `apply_skin()` (convention for 6.U2/6.U3).
func apply_skin() -> void:
	_root.theme = UIStyle.hud_theme()
	_obj_panel.add_theme_stylebox_override("panel", UIStyle.slate_style())
	_objective.add_theme_color_override("font_color", UIStyle.token(&"title"))
	_help_panel.add_theme_stylebox_override("panel", UIStyle.slate_style())
	_help_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	_map_panel.add_theme_stylebox_override("panel", UIStyle.frame_style(10.0))
	end_panel.add_theme_stylebox_override("panel", UIStyle.frame_style(24.0))
	end_body.add_theme_color_override("font_color", UIStyle.token(&"text"))
	for b: Button in _end_tab_buttons.values():
		UIStyle.style_button(b)
	_end_rule.queue_redraw()
	for n in _root.find_children("*", "", true, false):
		if n.has_method(&"apply_skin"):
			n.call(&"apply_skin")


func set_objective(text: String) -> void:
	_objective.text = text


func show_message(text: String, seconds := 2.0) -> void:
	if end_panel.visible and end_body.text != "" and text == end_body.text:
		return   # the end stats are already in the end panel
	_message.text = text
	_message_time = seconds


## True while the message line still shows a line (tips such as the 0:40 capture hint wait for it to clear).
func is_message_shown() -> bool:
	return _message_time > 0.0 and _message.text != ""


## The end banner. When the level has end_screen_text() (skirmish), its stats go under the banner.
func show_banner(text: String, color: Color) -> void:
	if tavern_window != null and is_instance_valid(tavern_window):
		tavern_window.close()   # the match ended
	if trade_window != null and is_instance_valid(trade_window):
		trade_window.close()
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.visible = true
	_banner_glow.text = text
	var g := UIStyle.token(&"trim_glow")
	_banner_glow.add_theme_color_override("font_color", Color(g.r, g.g, g.b, 0.35))
	var level := get_parent()
	var stats := ""
	if level != null and level.has_method(&"end_screen_text"):
		stats = str(level.call(&"end_screen_text"))
	end_body.text = stats
	end_body.visible = stats != "" and not end_tabs.visible
	if end_tabs.visible:
		select_end_tab(end_tab)
	end_panel.visible = true
	# The panel shrinks / grows around the screen centre.
	end_panel.reset_size()
	end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	# Dim 0.3 s, banner scale 1.2 -> 1.0 in 0.25 s (pivot centre).
	var was_dim := _dim.visible
	_dim.visible = true
	var bsize := _banner.get_combined_minimum_size()
	_banner.pivot_offset = Vector2(maxf(_banner.size.x, bsize.x), bsize.y) * 0.5
	_banner_glow.pivot_offset = _banner.pivot_offset
	_banner_glow.scale = Vector2(1.03, 1.03)
	if not was_dim:
		if _end_tween:
			_end_tween.kill()
		_dim.modulate.a = 0.0
		_banner.scale = Vector2(1.2, 1.2)
		_end_tween = create_tween().set_parallel(true)
		_end_tween.tween_property(_dim, "modulate:a", 1.0, 0.3)
		_end_tween.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT)


func is_banner_shown() -> bool:
	return end_panel.visible


## 16a: fills the Score tab from `keeper` (a ScoreKeeper), shows the Summary / Score tabs and opens the Score tab.
## `teams` = [the local team, the other], `names` / `colors` per team; `subtitle` = "Won on score ..." or "".
## The skirmish calls it after show_banner on every end (victory, defeat, concede, time limit).
func show_score(keeper: Object, teams: Array, names: Array, colors: Array, subtitle := "") -> void:
	end_subtitle.text = subtitle
	end_subtitle.visible = subtitle != ""
	if keeper != null:
		score_panel.call(&"show_score", keeper, teams, names, colors)
	end_tabs.visible = keeper != null
	select_end_tab(END_TAB_SCORE if keeper != null else END_TAB_SUMMARY)


## 16a: shows the end tab END_TAB_SUMMARY (the stats) or END_TAB_SCORE (table + graph).
func select_end_tab(tab: StringName) -> void:
	end_tab = tab
	var score := tab == END_TAB_SCORE and end_tabs.visible
	score_panel.visible = score
	end_body.visible = not score and end_body.text != ""
	var b: Variant = _end_tab_buttons.get(END_TAB_SCORE if score else END_TAB_SUMMARY)
	if b is Button:
		(b as Button).set_pressed_no_signal(true)
	if end_panel.visible:
		end_panel.reset_size()
		end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	# Y (tavern) and F5-F7 (find champion) are handled by the champion bar (ui-champions.md 13.3).
	if code == KEY_T and shop_window:
		shop_window.toggle()
		get_viewport().set_input_as_handled()


## Left click on a tavern (group "taverns") opens the tavern window. The click is not consumed, so the
## selection manager still handles it as usual (9.C8 may also open the window from there: opening twice is harmless).
func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or tavern_window == null:
		return
	if _selection != null and _selection.get_pending_order() != &"":
		return   # a targeted order / placement takes the click
	for mode in get_tree().get_nodes_in_group(&"bounty_mode"):
		if mode.has_method(&"is_active") and bool(mode.call(&"is_active")):
			return   # bounty mode (R) places flags on taverns' neighbours, not the window
	var tavern := tavern_at(mb.position)
	if tavern != null:
		tavern_window.open()


## The tavern (group "taverns") under the screen point: a layer-2 ray hit, or a ground click within 3.5 m of
## its centre (the 6 x 6 footprint). null when none.
func tavern_at(screen_pos: Vector2) -> Node3D:
	if _selection == null or _selection.camera == null or not _selection.camera.is_inside_tree():
		return null
	var taverns := get_tree().get_nodes_in_group(&"taverns")
	if taverns.is_empty():
		return null
	var cam := _selection.camera
	var from := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	var space := cam.get_world_3d().direct_space_state
	if space != null:
		var query := PhysicsRayQueryParameters3D.create(from, from + dir * 500.0, 2)
		query.collide_with_areas = true
		var hit := space.intersect_ray(query)
		var n: Node = hit.get("collider") as Node if not hit.is_empty() else null
		while n != null:
			if n.is_in_group(&"taverns") and n is Node3D:
				return n as Node3D
			n = n.get_parent()
	var ground: Variant = Plane(Vector3.UP, 0.0).intersects_ray(from, dir)
	if ground == null:
		return null
	var p := ground as Vector3
	for t in taverns:
		if is_instance_valid(t) and t is Node3D:
			var c := (t as Node3D).global_position
			if absf(p.x - c.x) <= 3.5 and absf(p.z - c.z) <= 3.5:
				return t as Node3D
	return null


## Calls the static `attach(...)` of the script at `path` with `args` when the file exists and has one (UI pieces
## of other tasks, reached without a static type). Returns what attach returned, or null.
func attach_optional(path: String, args: Array) -> Variant:
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null:
		return null
	for m in script.get_script_method_list():
		if m.get("name") == "attach":
			return script.callv(&"attach", args)
	return null


## A fallen / reviving / empty champion slot was clicked (or its F key pressed): the tavern window, with the
## fallen champion's row highlighted.
func _on_tavern_requested(slot: int) -> void:
	if tavern_window != null:
		tavern_window.open(slot)


func _process(delta: float) -> void:
	_check_hero_levels()
	_refresh_help()
	if _message_time > 0.0:
		_message.position.y = _message_y()
		_message_time -= delta
		_message.modulate.a = clampf(_message_time / MESSAGE_FADE, 0.0, 1.0)
		if _message_time <= 0.0:
			_message.text = ""
			_message.modulate.a = 1.0


## levels.md: "Vessa reaches level 3" (and "Malrik reaches level 3": the player sees the bot's too).
## Polls `level` on every wizard (group "heroes"), so it works whatever the signal's arguments are.
func _check_hero_levels() -> void:
	for wiz in get_tree().get_nodes_in_group(&"heroes"):
		var lvl: Variant = wiz.get("level")
		if lvl == null:
			continue
		var id := wiz.get_instance_id()
		var before: int = _hero_levels.get(id, -1)
		if before >= 0 and int(lvl) > before:
			var short := str(wiz.get("unit_name")).get_slice(",", 0).strip_edges()
			show_message("%s reaches level %d" % [short, int(lvl)], 3.0)
		_hero_levels[id] = int(lvl)


## The message line sits at y 120, or just below the controls help when a long message would
## run into it (the help panel is 7 lines tall on the right).
func _message_y() -> float:
	if _help_panel == null or not _help_panel.visible:
		return MESSAGE_Y
	var help := _help_panel.get_global_rect()
	var half_width := _message.get_minimum_size().x * 0.5
	var centre := _message.get_viewport_rect().size.x * 0.5
	if centre + half_width < help.position.x - 8.0:
		return MESSAGE_Y
	return maxf(MESSAGE_Y, help.end.y + 10.0)


## Fireball button: goes through `fireball_pressed` when the level listens to it, else straight
## to the selection manager.
func _on_fireball_button() -> void:
	if fireball_pressed.get_connections().is_empty():
		if _selection:
			_selection.begin_fireball_targeting()
	else:
		fireball_pressed.emit()


# ---------------------------------------------------------------- small UI builders

func _panel(parent: Control) -> PanelContainer:
	return UIStyle.panel(parent)


## Pins the panel's bottom-left corner `left` px from the left and `bottom` px from the bottom,
## whatever the screen size; the panel grows up and right to fit its content.
func _anchor_bottom_left(panel: Control, left: float, bottom: float) -> void:
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, true)
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = left
	panel.offset_right = left
	panel.offset_top = -bottom
	panel.offset_bottom = -bottom


func _label(text: String, font_size: int) -> Label:
	return UIStyle.label(text, font_size)
