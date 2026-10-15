class_name GameHUD
extends CanvasLayer
## On-screen interface: the console HUD (docs/design/ui-sc2-console.md, SC2.U1-U5; older parts ui-hud.md).
## Top-left: Menu / ? buttons, the objective (collapsible) and the Next hint; top-right: the resources (TopBar) and
## the tier chip. Bottom: ONE console (ConsoleFrame) holding the minimap, the selection block (SelectionPanel), the
## portrait window and the command card; above it on the left the alert stack, the champion slots, the hero tile
## (+ inventory) and the quick row (Idle F3 / Army F2 / match clock), and the control-group tabs. The controls help is
## an overlay (? button or K). Pop-up messages and the victory / defeat banner as before.

## The command card's Fireball button (main.gd connects it to the selection's Fireball targeting).
signal fireball_pressed

var minimap: Minimap
var console: ConsoleFrame                 ## The bottom console frame (zones: ConsoleFrame.zone_rect).
var idle_worker_button: IdleWorkerButton   ## Quick row (8, 648): idle count, click = F3.
var army_button: ArmyButton                ## Quick row (48, 648): army count, click = F2.
var alert_stack: AlertStack                ## Alerts above the champion slots (ui-sc2-console.md 3.3).
var menu_button: Button                    ## Top-left: opens the pause menu.
var help_button: Button                    ## Top-left `?`: toggles the controls overlay (K too).
var top_bar: TopBar
var command_card: CommandCard
var selection_panel: SelectionPanel
var group_bar: ControlGroupBar
var inventory_bar: InventoryBar   ## Vessa's 6 item slots + 2 artifact slots in the hero tile (4.U1a, SC2.U3).
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
var end_restart_button: Button   ## End screen: "Restart (F9)" (reloads the level, like F9).
var end_menu_button: Button      ## End screen: "Main menu".
var next_step_hint: Node         ## Skirmish "Next: ..." line under the objective (scripts/ui/next_step_hint.gd), or null.
var tier_chip: Node              ## Keep tier indicator (scripts/ui/tier_chip.gd) while the game has tiers, or null.
var chat_line: ChatLine          ## Chat / command line (Enter): "dance 1 / 2 / 3" (scripts/ui/chat_line.gd).

var _hero: Wizard
var _selection: SelectionManager

var _objective: Label
var _objective_header: Button   ## "v Objective" / "> Objective": click folds the objective to this line.
var objective_collapsed := false   ## Kept for the match (the HUD is rebuilt with the level).
## G-F review 2 item 12: the objective folds to its header by itself after OBJECTIVE_FOLD_TIME s of unpaused play
## with a text (once per match); a click on the header (toggle_objective) turns this off.
var objective_auto_fold := true
var _objective_shown_s := 0.0
const OBJECTIVE_FOLD_TIME := 10.0
## Messages longer than this many characters use MESSAGE_LONG_FONT (the 10 s start hint: a slimmer plate).
const MESSAGE_LONG_CHARS := 64
const MESSAGE_FONT := 22
const MESSAGE_LONG_FONT := 18
var _message: Label
var _banner: Label
var _help_panel: Control         ## The controls overlay (hidden until ? / K).
var _help_backdrop: Control      ## Full-screen catcher behind it: a click outside closes it.
var _clock_holder: HBoxContainer ## The quick row's match clock (TopBar.clock_box), right edge at x 244.
var _message_time := 0.0
var _root: Control
var _obj_panel: PanelContainer
var _help_label: Label
var _help_name := "your wizard"   # the wizard named in the help
var _help_lang := ""              # the language the help was written in (refresh on a live switch)
var _help_scheme := -1            # the control scheme the help was written for
var _help_check_left := 0         # frames to the next keyboard-layout re-check
var _map_panel: PanelContainer
var _dim: ColorRect
var _banner_glow: Label
var _end_rule: Control
var _end_tween: Tween
const MESSAGE_FADE := 0.3   ## The message line fades out over its last 0.3 s.
var _hero_levels := {}   # wizard instance id -> last seen level (level-up message)
## The "heroes" group, re-read 4 times a second (not every frame); levels are still compared every frame.
var _heroes: Array[Node] = []
var _heroes_left := 0.0
const HEROES_POLL := 0.25
var _objective_source := ""   # the English objective text (re-translated on a language switch)

const MESSAGE_Y := 120.0
## Top-left buttons (ui-sc2-console.md 1): 28 x 22 from (8, 8), gap 4; the objective from (8, 36).
const TOP_BUTTON := Vector2(28, 22)
const OBJECTIVE_POS := Vector2(8, 36)
const OBJECTIVE_MAX_W := 420.0
## The controls overlay: 480 wide at (560, 140).
const HELP_RECT := Rect2(560, 140, 480, 0)
const HELP_KEY := KEY_K
const CLOCK_RIGHT := 244.0
const CLOCK_Y := 658.0


## G1: applies GameSettings.effective_graphics_quality() to the root viewport and the "lighting_rigs" group.
func _apply_graphics_quality() -> void:
	if is_inside_tree():
		GameSettings.apply_graphics(get_tree())


func _ready() -> void:
	# G1: a new match gets the graphics tier (root viewport + lighting rigs, once the level has built them).
	_apply_graphics_quality.call_deferred()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.hud_theme()   # slate tooltips
	add_child(root)
	_root = root

	# The console (ui-sc2-console.md 1): one framed panel along the bottom; its zones' pieces are drawn over it.
	console = ConsoleFrame.new()
	root.add_child(console)

	# Objective (top left, (8, 36)): a header row ("v Objective", click folds it) over the text, slate, font 17 in the
	# title colour. Read-only parts let clicks through to the battlefield under them.
	var obj_panel := _panel(root)
	obj_panel.add_theme_stylebox_override("panel", UIStyle.slate_style(8.0))
	obj_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_panel.position = OBJECTIVE_POS
	_obj_panel = obj_panel
	var obj_box := VBoxContainer.new()
	obj_box.add_theme_constant_override("separation", 2)
	obj_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_panel.add_child(obj_box)
	_objective_header = _fold_header("Objective")
	_objective_header.tooltip_text = "Click: fold / unfold the objective"
	_objective_header.pressed.connect(toggle_objective)
	obj_box.add_child(_objective_header)
	_objective = _label("", 17)
	_objective.add_theme_color_override("font_color", UIStyle.token(&"title"))
	obj_box.add_child(_objective)

	# Resources (top right).
	top_bar = TopBar.new()
	root.add_child(top_bar)
	top_bar.message.connect(show_message)

	# Top-left buttons: Menu (the pause menu) and ? (the controls overlay, K too).
	menu_button = _top_button(root, 0, "", Loc.t("Menu  [Esc]"))
	menu_button.pressed.connect(open_menu)
	var bars := Control.new()
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars.draw.connect(func() -> void:
		var col := UIStyle.token(&"text")
		for k in 3:
			bars.draw_rect(Rect2(8, 6 + 4 * k, 12, 2), col))
	menu_button.add_child(bars)
	help_button = _top_button(root, 1, "?", Loc.t("Controls  [%s]") % KeyLabels.of(HELP_KEY))
	help_button.pressed.connect(toggle_help)

	# Controls overlay (hidden): title + the help_text() lines, closes on ? / K / Esc / a click outside.
	_help_backdrop = Control.new()
	_help_backdrop.name = "HelpBackdrop"
	_help_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_help_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_help_backdrop.visible = false
	_help_backdrop.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb != null and mb.pressed:
			close_help())
	root.add_child(_help_backdrop)
	var help_panel := _panel(root)
	help_panel.name = "HelpOverlay"
	help_panel.add_theme_stylebox_override("panel", UIStyle.slate_style(10.0))
	help_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	help_panel.position = HELP_RECT.position
	help_panel.custom_minimum_size = Vector2(HELP_RECT.size.x, 0)
	help_panel.visible = false
	var help_box := VBoxContainer.new()
	help_box.add_theme_constant_override("separation", 6)
	help_panel.add_child(help_box)
	var help_title := UIStyle.display_label("Controls", 16)
	help_title.add_theme_color_override("font_color", UIStyle.token(&"title"))
	help_box.add_child(help_title)
	# Keys: CLAUDE.md "Keys" / ui-hud.md.
	GameSettings.ensure_read()   # the help follows the saved control scheme (UX.1)
	var help := _label(help_text(_help_name, help_features()), 13)
	help.add_theme_color_override("font_color", UIStyle.token(&"text"))
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # French lines are longer
	help.custom_minimum_size = Vector2(HELP_RECT.size.x - 20.0, 0)
	help_box.add_child(help)
	_help_panel = help_panel
	_help_label = help

	# Minimap: 200 x 200 at (14, 692), in the console's minimap zone (no frame of its own).
	var map_panel := _panel(root)
	map_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_map_panel = map_panel
	_anchor_bottom_left(map_panel, ConsoleFrame.MINIMAP.position.x, 900.0 - ConsoleFrame.MINIMAP.end.y)
	minimap = Minimap.new()
	map_panel.add_child(minimap)

	# Selection block, portrait window and command card (the console's middle and right zones).
	selection_panel = SelectionPanel.new()
	root.add_child(selection_panel)
	_adopt(root, selection_panel.portrait_window)
	group_bar = ControlGroupBar.new()   # control group tabs on the console's top edge
	root.add_child(group_bar)
	command_card = CommandCard.new()
	command_card.fireball_action = _on_fireball_button
	root.add_child(command_card)
	# Left stack: hero tile (+ inventory), champion slots, alerts, quick row (Idle F3, Army F2, clock).
	_adopt(root, selection_panel.hero_tile)
	inventory_bar = InventoryBar.new()   # over the hero tile: items row y 612, artifacts on the right
	root.add_child(inventory_bar)
	inventory_bar.message.connect(show_message)
	# Champion slots (left, above the hero tile; hidden while the team has no ChampionGuild).
	champion_bar = ChampionBar.new()
	root.add_child(champion_bar)
	champion_bar.tavern_requested.connect(_on_tavern_requested)
	alert_stack = AlertStack.new()
	root.add_child(alert_stack)
	idle_worker_button = IdleWorkerButton.new()   # click = next, Ctrl+click = all; hidden at 0
	root.add_child(idle_worker_button)
	army_button = ArmyButton.new()   # click = F2, Shift+click = add; hidden at 0
	root.add_child(army_button)
	_clock_holder = HBoxContainer.new()
	_clock_holder.name = "QuickClock"
	_clock_holder.alignment = BoxContainer.ALIGNMENT_END
	_clock_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock_holder.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_clock_holder.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_clock_holder.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_clock_holder.offset_left = CLOCK_RIGHT - 100.0
	_clock_holder.offset_right = CLOCK_RIGHT
	_clock_holder.offset_top = -(900.0 - CLOCK_Y)
	_clock_holder.offset_bottom = _clock_holder.offset_top + 20.0
	root.add_child(_clock_holder)
	_clock_holder.add_child(top_bar.clock_box)

	# Short messages ("Not enough mana") and the big victory/defeat banner
	_message = _label("", 22)
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.position.y = MESSAGE_Y
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Readable over bright ground (mission 2's snow, fix 2026-10-04): a thicker outline and a dark backing plate,
	# shown only while a line is up.
	_message.add_theme_constant_override("outline_size", 5)
	_message.add_theme_stylebox_override("normal", message_backing())
	_message.visible = false
	root.add_child(_message)

	# Chat / command line (Enter opens it; "dance 1 / 2 / 3"), and the match-end dances (UnitDances).
	chat_line = ChatLine.attach(root)
	var events := get_node_or_null(^"/root/Events")
	if events != null and events.has_signal(&"mission_ended"):
		events.connect(&"mission_ended", _on_mission_ended_dances)

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
	# Playtest fix 2026-09-27: Restart (same as F9) and Main menu buttons on every end screen.
	var end_buttons := HBoxContainer.new()
	end_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	end_buttons.add_theme_constant_override("separation", 16)
	end_buttons.process_mode = Node.PROCESS_MODE_ALWAYS   # still clickable if the tree is paused
	end_box.add_child(end_buttons)
	end_restart_button = _end_button(end_buttons, "Restart (F9)")
	end_restart_button.pressed.connect(restart_match)
	end_menu_button = _end_button(end_buttons, "Main menu")
	end_menu_button.pressed.connect(quit_to_menu)


func setup(hero: Wizard, selection: SelectionManager) -> void:
	_hero = hero
	_selection = selection
	if chat_line != null:
		chat_line.selection = selection
	# The player's kingdom skins the HUD (ui-style.md 1).
	var before := UIStyle.skin_version
	UIStyle.set_kingdom(kingdom_of(hero))
	if UIStyle.skin_version != before:
		apply_skin()
	_help_name = wizard_short_name(hero)
	_help_label.text = help_text(_help_name, help_features())
	selection_panel.setup(hero, selection)
	command_card.setup(selection)
	group_bar.setup(selection)
	idle_worker_button.setup(selection)
	army_button.setup(selection)
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
	next_step_hint = attach_optional("res://scripts/ui/next_step_hint.gd", [self])
	tier_chip = attach_optional("res://scripts/ui/tier_chip.gd", [self])
	# The minimap reads the map size and the artifact from the level (main.gd), when present.
	var level := get_parent()
	var map_size := MapInfo.size_max()   # MT1: the running map (a non-square one is letterboxed in the square view)
	var artifact: Node3D = null
	if level and level.get_script():
		artifact = level.get("artifact") as Node3D
	var rig: RTSCamera = null
	if selection.camera:
		rig = selection.camera.get_parent() as RTSCamera
	minimap.setup(selection, rig, map_size, artifact)
	alert_stack.setup(selection, minimap)


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


## A 28 x 22 top-left button, slot `i` from (8, 8) with a 4 px gap.
func _top_button(parent: Control, i: int, text: String, tip: String) -> Button:
	var b := Button.new()
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	UIStyle.style_button(b)
	if text != "":   # a label child: the frame's content margins would make a text button taller than 22
		var l := UIStyle.panel_label(text, 14)
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.add_child(l)
	b.position = Vector2(8.0 + i * (TOP_BUTTON.x + 4.0), 8.0)
	b.size = TOP_BUTTON
	b.custom_minimum_size = TOP_BUTTON
	parent.add_child(b)
	return b


## A flat header row with a 12 px fold glyph (`v` open, `>` folded) before `text` (font 12, muted).
func _fold_header(text: String) -> Button:
	var b := Button.new()
	b.text = "     " + text   # room for the glyph
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 12)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.draw.connect(func() -> void:
		var col := UIStyle.token(&"text_muted") if not b.is_hovered() else UIStyle.token(&"trim_glow")
		var y := b.size.y * 0.5
		if objective_collapsed:
			b.draw_colored_polygon(PackedVector2Array([Vector2(2, y - 5), Vector2(10, y), Vector2(2, y + 5)]), col)
		else:
			b.draw_colored_polygon(PackedVector2Array([Vector2(1, y - 4), Vector2(11, y - 4), Vector2(6, y + 4)]), col))
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	_style_fold_header(b)
	return b


func _style_fold_header(b: Button) -> void:
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
		b.add_theme_color_override(c, UIStyle.token(&"text_muted"))


## Moves `node` (built by the selection panel) into the HUD root, keeping its anchors.
func _adopt(parent: Control, node: Control) -> void:
	if node == null:
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	parent.add_child(node)


## Folds / unfolds the objective to its header line (state kept for the match).
func toggle_objective() -> void:
	objective_auto_fold = false   # the player chose: never fold it again by itself
	set_objective_collapsed(not objective_collapsed)


# Item 12: counts unpaused seconds while the objective shows a text, then folds it once.
func _tick_objective_fold(delta: float) -> void:
	if not objective_auto_fold or objective_collapsed or _obj_panel == null or not _obj_panel.visible \
			or _objective.text == "":
		return
	_objective_shown_s += delta
	if _objective_shown_s >= OBJECTIVE_FOLD_TIME:
		objective_auto_fold = false
		set_objective_collapsed(true)


func set_objective_collapsed(v: bool) -> void:
	objective_collapsed = v
	_objective.visible = not v
	_objective_header.queue_redraw()
	_obj_panel.reset_size()


## The Menu button: the pause menu (Esc does the same).
func open_menu() -> void:
	var level := get_parent()
	if level == null:
		return
	for n in level.find_children("*", "PauseMenu", true, false):
		if n.has_method(&"can_open") and bool(n.call(&"can_open")):
			n.call(&"open")
			return


## The controls overlay (? / K): toggles it.
func toggle_help() -> void:
	if is_help_open():
		close_help()
	else:
		open_help()


func open_help() -> void:
	refresh_help()
	_help_panel.visible = true
	_help_backdrop.visible = true
	_help_panel.reset_size()


func close_help() -> void:
	_help_panel.visible = false
	_help_backdrop.visible = false


func is_help_open() -> bool:
	return _help_panel != null and _help_panel.visible


## The console's skirmish pieces (selection block, portrait window, command card) on / off: Wave Strike's Muster panel
## (WS2.U1) hides them and fills `console.zone_rect(&"muster")` instead (ui-sc2-console.md 6). The minimap, hero tile and
## champion slots stay.
func set_skirmish_console_visible(v: bool) -> void:
	for c: Control in [selection_panel, selection_panel.portrait_window, command_card, group_bar]:
		if c != null:
			c.visible = v


## Shows / hides the top-left objective panel (the mission UI hides it when it has its own objectives panel).
func set_objective_visible(v: bool) -> void:
	if _obj_panel != null:
		_obj_panel.visible = v


## The top-left objective panel (the next-step hint sits under it).
func objective_panel() -> Control:
	return _obj_panel


## Match end (Events.mission_ended, after the skirmish stopped every order): the winners dance dance_victory, the
## losers (defeat or concede) dance_surrender; units still fighting are skipped (UnitDances.match_end).
func _on_mission_ended_dances(victory: bool) -> void:
	if is_inside_tree():
		UnitDances.match_end(get_tree(), Unit.Team.PLAYER if victory else Unit.Team.ENEMY)


## End screen Restart button: reloads the level like F9 (MenuFlow keeps difficulty / kingdoms / settings).
func restart_match() -> void:
	MenuFlow.restart(get_tree())


## End screen Main menu button.
func quit_to_menu() -> void:
	MenuFlow.quit_to_menu(get_tree())


func _end_button(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(170, 38)
	b.add_theme_font_size_override("font_size", 17)
	UIStyle.style_button(b)
	parent.add_child(b)
	return b


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
		return Loc.t("Your wizard")
	var n := str(hero.get("unit_name")).get_slice(",", 0).strip_edges()
	return n if n != "" and n != "<null>" else Loc.t("Your wizard")


## Tutorial wording for moving the wizard in the current control scheme (UX.1), keyboard labels included:
## Classic "Right-click the ground to move Vessa", Hero WASD "Walk Vessa with W A S D" ("Z Q S D" on AZERTY).
static func walk_hint(wizard_name: String) -> String:
	if GameSettings.hero_wasd():
		return Loc.t("Walk %s with %s") % [wizard_name, KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D])]
	return Loc.t("Right-click the ground to move %s") % wizard_name


## Rewrites the help when the control scheme changed (Settings in the pause menu) or the keyboard layout did.
func _refresh_help() -> void:
	_help_check_left -= 1
	if _help_check_left > 0 and _help_scheme == GameSettings.control_scheme and _help_lang == Loc.language:
		return
	_help_lang = Loc.language
	refresh_help()


## Rewrites the controls help now (control scheme and keyboard labels).
func refresh_help() -> void:
	if _help_label == null:
		return
	_help_check_left = 60
	_help_scheme = GameSettings.control_scheme
	var text := help_text(_help_name, help_features())
	if _help_label.text != text:
		_help_label.text = text


## The systems the controls help lists keys for: {} (every line) outside a campaign mission; in a mission
## (MissionBase) champions only with taverns, trade / capture points only when the mission turns them on, caster keys
## only when it has casters (fix 2026-10-04: the help listed Bazaar / bounty / capture keys that did nothing).
func help_features() -> Dictionary:
	var level := get_tree().current_scene if is_inside_tree() else null
	if not (level is MissionBase):
		return {}
	return {
		&"champions": bool(level.get(&"tavern_enabled")),
		&"trade": bool(level.get(&"trade_enabled")),
		&"capture": bool(level.get(&"points_enabled")),
		&"casters": CasterKit.enabled_here(),
	}


## The last help line (step 12, ui-mapfill.md 12).
const HELP_CAPTURE := "Capture: stand near towers, wells and shrines"


## The controls help (CLAUDE.md "Keys"), naming the player's wizard. Reflowed to 11 lines of <= 438 px for step 10
## (ui-trade.md 14.1: the panel is 458 x 229 at (1126, 16), clear of the 624 px top bar with gold); step 12 adds a
## 12th line (ui-mapfill.md 12: 458 x 248).
## UX.1: lines 2-4 follow the control scheme (Classic: right click moves the wizard, A + click = attack-move;
## Hero WASD: W A S D walk her, X = attack-move) and every letter is the label on the player's keyboard
## (KeyLabels: an AZERTY player reads "Q + click: attack-move", "Z Q S D: walk").
## `features` (fix 2026-10-04): keys of systems the level does not have are left out (missions: no trade, no capture
## points, champions only with a tavern, caster keys only with casters). Empty = every line (the skirmish / tests).
static func help_text(wizard_name: String, features: Dictionary = {}) -> String:
	var has := func(f: StringName) -> bool: return features.is_empty() or bool(features.get(f, false))
	var k := func(code: Key) -> String: return KeyLabels.of(code)
	# The training slot keys (SelectionManager.SLOT_KEYS: Z X C V B, then N M , on a Hall's 8-unit card).
	var train := KeyLabels.join(SelectionManager.SLOT_KEYS)
	var spells := KeyLabels.join([KEY_F, KEY_Q, KEY_E], " / ")
	var middle := ""
	var pan_keys := KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D]) if GameSettings.rts_wasd() else Loc.t("Arrows")
	# One translated template per help line (localization.md); the key labels stay as KeyLabels prints them.
	if GameSettings.hero_wasd():
		middle = (Loc.t("Right click: move / attack / gather / rally    %s: attack-move    %s: stop")
				% [k.call(KEY_X), k.call(KEY_C)]
				+ "\n" + Loc.t("%s: hold    %s: gather    %s: build (workers)    %s: train")
				% [k.call(KEY_H), k.call(KEY_G), k.call(KEY_B), train]
				+ "\n" + Loc.t("Delete: cancel a site    %s: walk %s    %s: spells")
				% [KeyLabels.join([KEY_W, KEY_A, KEY_S, KEY_D]), wizard_name, spells] + "\n")
	elif GameSettings.rts_wasd():
		# RTS camera (WASD): Classic moves, X = attack-move (A pans the camera, see the pan line below).
		middle = (Loc.t("Right click: move (%s too) / attack / gather / rally    %s: stop") % [wizard_name, k.call(KEY_C)]
				+ "\n" + Loc.t("Attack-move: %s + click    %s: hold    %s: gather    %s: build")
				% [k.call(KEY_X), k.call(KEY_H), k.call(KEY_G), k.call(KEY_B)]
				+ "\n" + Loc.t("%s: train    Delete: cancel a site    %s: spells") % [train, spells] + "\n")
	else:
		middle = (Loc.t("Right click: move (%s too) / attack / gather / rally    %s: stop") % [wizard_name, k.call(KEY_C)]
				+ "\n" + Loc.t("Attack-move: %s + click (%s too)    %s: hold    %s: gather    %s: build")
				% [k.call(KEY_A), k.call(KEY_X), k.call(KEY_H), k.call(KEY_G), k.call(KEY_B)]
				+ "\n" + Loc.t("%s: train    Delete: cancel a site    %s: spells") % [train, spells] + "\n")
	return (Loc.t("Left click / drag: select    Shift: add    Double-click: all of a type") + "\n"
			+ middle
			+ Loc.t("Ctrl+%s: learn spell    F1: %s    Space: find %s    F9: restart")
			% [KeyLabels.join([KEY_F, KEY_Q, KEY_E], "/"), wizard_name, wizard_name]
			+ "\n" + Loc.t("Groups 1-0: Ctrl set · Shift add · Alt steal · NN centre    Ctrl+%s: all") % k.call(KEY_A)
			+ "\n" + Loc.t("F2: army (Shift add)   F3: idle (Ctrl all)   Tab: type   F10 x2: surrender")
			+ "\n" + Loc.t("%s / edge: pan    Wheel: zoom    Middle drag: rotate    %s: shop") % [pan_keys, k.call(KEY_T)]
			+ _help_lines(k, has))


## The feature-dependent tail of help_text (a newline + its lines, or ""): champions, trade, casters, capture points.
static func _help_lines(k: Callable, has: Callable) -> String:
	var lines: Array[String] = []
	if has.call(&"champions"):
		lines.append(Loc.t("%s: bounty (Shift+click: stay)    %s: tavern    F5-F7: find champion") % [k.call(KEY_R), k.call(KEY_Y)])
	var row: Array[String] = []
	if has.call(&"champions"):
		row.append(Loc.t("Flag: %s raise · Delete remove") % k.call(KEY_Z))
	if has.call(&"trade"):
		row.append(Loc.t("%s: trade & hunters    %s: trade (caravans)") % [k.call(KEY_U), k.call(KEY_G)])
	if not row.is_empty():
		lines.append("    ".join(row))
	# caster-units.md 9.1: the casters' spell keys (the Bazaar's route click is on its Set Route tooltip).
	row = []
	if has.call(&"trade"):
		row.append(Loc.t("%s, %s: Bazaar    Bazaar: %s caravan") % [k.call(KEY_B), k.call(KEY_B), k.call(KEY_Z)])
	if has.call(&"casters"):
		row.append(Loc.t("%s / %s: caster spells (Ctrl: autocast)") % [k.call(KEY_Z), k.call(KEY_V)])
	if not row.is_empty():
		lines.append("    ".join(row))
	if has.call(&"capture"):
		lines.append(Loc.t(HELP_CAPTURE))
	return "" if lines.is_empty() else "\n" + "\n".join(lines)


## Re-skins every HUD piece: my panels here, and any child that has `apply_skin()` (convention for 6.U2/6.U3).
func apply_skin() -> void:
	_root.theme = UIStyle.hud_theme()
	_obj_panel.add_theme_stylebox_override("panel", UIStyle.slate_style(8.0))
	_objective.add_theme_color_override("font_color", UIStyle.token(&"title"))
	_style_fold_header(_objective_header)
	_help_panel.add_theme_stylebox_override("panel", UIStyle.slate_style(10.0))
	_help_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
	for b: Button in [menu_button, help_button]:
		UIStyle.style_button(b)
	end_panel.add_theme_stylebox_override("panel", UIStyle.frame_style(24.0))
	end_body.add_theme_color_override("font_color", UIStyle.token(&"text"))
	for b: Button in _end_tab_buttons.values():
		UIStyle.style_button(b)
	for b: Button in [end_restart_button, end_menu_button]:
		if b != null:
			UIStyle.style_button(b)
	_end_rule.queue_redraw()
	for n in _root.find_children("*", "", true, false):
		if n.has_method(&"apply_skin"):
			n.call(&"apply_skin")


func set_objective(text: String) -> void:
	_objective_source = text
	_objective.text = Loc.sink(text)   # objectives come from the logic (campaign / skirmish), English there


func _notification(what: int) -> void:
	# Live language switch: the objective was translated once when set (review 2026-10-08 L3).
	if what == NOTIFICATION_TRANSLATION_CHANGED and _objective != null and _objective_source != "":
		_objective.text = Loc.sink(_objective_source)


## The message line's plate: near-black at 80 % (G-F review 2 item 12: was 62 %, the start hint read thin over the
## keep's roofs), rounded, 16 x 5 px padding.
static func message_backing() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.03, 0.03, 0.8)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 5.0
	sb.content_margin_bottom = 5.0
	return sb


func show_message(text: String, seconds := 2.0) -> void:
	text = Loc.sink(text)   # logic messages stay English in the logic, translated here (localization.md)
	if end_panel.visible and end_body.text != "" and text == end_body.text:
		return   # the end stats are already in the end panel
	_message.text = text
	_message.visible = text != ""
	# Item 12: a long line (the start hint) gets a smaller font, so its plate covers less of the base.
	_message.add_theme_font_size_override("font_size",
			MESSAGE_LONG_FONT if text.length() > MESSAGE_LONG_CHARS else MESSAGE_FONT)
	var w := _message.get_combined_minimum_size().x   # plate = the text's width, centred (shrinks after a long line)
	_message.offset_left = -w * 0.5
	_message.offset_right = w * 0.5
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
	if shop_window != null and is_instance_valid(shop_window):
		shop_window.close()   # U4-1: it covered the banner / Score tab / Restart / Main menu buttons
	text = Loc.sink(text)
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.visible = true
	_banner_glow.text = text
	var g := UIStyle.token(&"trim_glow")
	_banner_glow.add_theme_color_override("font_color", Color(g.r, g.g, g.b, 0.35))
	var level := get_parent()
	var stats := ""
	if level != null and level.has_method(&"end_screen_text"):
		stats = Loc.sink(str(level.call(&"end_screen_text")))
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
	end_subtitle.text = Loc.sink(subtitle)
	end_subtitle.visible = subtitle != ""
	if keeper != null:
		colors = colors.duplicate()
		for i in mini(teams.size(), colors.size()):   # G-E: a mirror's later side in its alt palette, like its units
			var t := int(teams[i])
			var k := Unit.team_kingdom_of(t)
			if t != Unit.Team.NEUTRAL and Unit.uses_alt_palette(t, k):
				colors[i] = Unit.team_display_color(t)
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


## Esc closes the controls overlay before anything else sees it (the pause menu listens in _unhandled_input).
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not is_help_open():
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code == KEY_ESCAPE:
		close_help()
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code == HELP_KEY and not key.shift_pressed:
		toggle_help()
		get_viewport().set_input_as_handled()
		return
	# Enter opens the chat / command line (it checks cinematics, dialogues and focused text fields itself).
	if (code == KEY_ENTER or code == KEY_KP_ENTER) and not key.shift_pressed and chat_line != null:
		if chat_line.try_open():
			get_viewport().set_input_as_handled()
		return
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
	_heroes_left -= delta
	if _heroes_left <= 0.0:
		_heroes_left = HEROES_POLL
		_refresh_heroes()
	_check_hero_levels()
	_tick_objective_fold(delta)
	_refresh_help()
	if _clock_holder != null:
		_clock_holder.visible = top_bar.visible   # Wave Strike hides the resources: its strip has the clock
	if _message_time > 0.0:
		_message.position.y = _message_y()
		_message_time -= delta
		_message.modulate.a = clampf(_message_time / MESSAGE_FADE, 0.0, 1.0)
		if _message_time <= 0.0:
			_message.text = ""
			_message.visible = false
			_message.modulate.a = 1.0


## levels.md: "Vessa reaches level 3" (and "Malrik reaches level 3": the player sees the bot's too).
## Polls `level` on every wizard (group "heroes"), so it works whatever the signal's arguments are.
func _check_hero_levels() -> void:
	for wiz in _heroes:
		if not is_instance_valid(wiz):
			continue
		var lvl: Variant = wiz.get("level")
		if lvl == null:
			continue
		var id := wiz.get_instance_id()
		var before: int = _hero_levels.get(id, -1)
		if before >= 0 and int(lvl) > before:
			var short := str(wiz.get("unit_name")).get_slice(",", 0).strip_edges()
			show_message(Loc.t("%s reaches level %d") % [short, int(lvl)], 3.0)
		_hero_levels[id] = int(lvl)


## Re-reads the "heroes" group and forgets the levels of wizards that are gone (review 2026-10-08 L6).
func _refresh_heroes() -> void:
	_heroes = get_tree().get_nodes_in_group(&"heroes")
	var live: Dictionary = {}
	for wiz in _heroes:
		live[wiz.get_instance_id()] = true
	for id: int in _hero_levels.keys():
		if not live.has(id):
			_hero_levels.erase(id)


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
