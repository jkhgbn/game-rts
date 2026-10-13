class_name SelectionPanel
extends PanelContainer
## The console's selection block (docs/design/ui-sc2-console.md 4.2, SC2.U1 / U4; was ui-hud.md "Selection panel"):
## x 244-1132, y 692-892 at 1600 x 900 (888 x 200, content from (252, 696)); no frame of its own (the ConsoleFrame's),
## anchored left + right so an ultrawide screen widens it. Shows what is selected: nothing / one unit / many units
## (type tabs + icons) / a building ("keep" view: name, HP; trainers add the training queue and rally; construction sites
## the progress, builders and Cancel) / a champion (9.C7: read-only inspect view, own or visible enemy; see inspect()
## and inspected_champion()).
## It also builds the hero tile (HeroTile, `hero_tile`: the player's wizard always, name = click to select her, HP,
## mana, XP, points; while she is dead "Vessa returns in 24 s" counts down) and the portrait window (PortraitWindow,
## `portrait_window`, the one Portrait); the HUD moves both to its root (bottom-left / bottom-right of the console).

const SIZE := Vector2(888, 200)
## The block's rect at 1600 x 900: left edge from the screen's left, right edge from the screen's right.
const LEFT := 244.0
const RIGHT := 468.0
const TOP := 692.0
const ICON_SIZE := 40.0
const ICONS_PER_ROW := 16
const MAX_ICONS := 48
var _icon_rim: Array = []    ## Per icon: its rim colour (follows HP, 4.2).
var _icon_faces: Array[TextureRect] = []   ## Per icon: the unit's icon.
## 4.2 type tabs (one per selected unit type, Tab order) and the "+ 12 more" chip.
const TYPE_TABS := 8
var type_tabs: Array[Button] = []
var multi_more: Label
const ICON_RIM_GREEN := Color(0.3, 0.85, 0.35)
const ICON_RIM_YELLOW := Color(0.95, 0.8, 0.3)
const QUEUE_SLOTS := 5
const PROGRESS_COLOR := Color(1.0, 0.85, 0.4)
## Timed statuses (spells.md "Statuses", kingdom-ice.md 2.1): chip letter, name, tooltip.
const STATUS_INFO := {
	&"haste": ["H", "Haste", "Attacks 30 % faster, moves faster"],
	&"shroud": ["S", "Shroud", "Takes half damage, moves faster"],
	&"chill": ["C", "Chilled", "Attacks 25 % slower, moves 1.5 m/s slower"],
	&"frozen": ["F", "Frozen", "Can't move, attack or cast"],
	&"rooted": ["R", "Rooted", "Can't move; can still attack and cast"],
	# Champion statuses (champions.md 4.3, ui-champions.md 4).
	&"taunted": ["T", "Taunted", "attacks the Oathwall only"],
	&"dazed": ["D", "Dazed", "can't move or act"],
	&"braced": ["B", "Braced", "takes 30 % less damage"],
	&"marked": ["M", "Marked", "takes 15 % more damage"],
	# Caster units (caster-units.md 3.5).
	&"slagged": ["S", "Slagged", "armour -20 (not below 0), slower, takes 10 % more damage"],
	&"scalded": ["C", "Scalded", "mana burnt; no second Mana Scald yet"],
	&"hazed": ["P", "Hazed", "ranged attacks reach 2.5 m only, sight 4 m"],
	&"tithed": ["T", "Tithed", "healed by a Blood Tithe"],
}
## Mark colours of the Ice / Nature statuses (7.U1): chill pale blue, frozen white-blue, rooted green-brown.
## Other statuses use Unit.STATUSES[id]["color"].
const STATUS_COLORS := {
	&"chill": Color(0.62, 0.82, 1.00),
	&"frozen": Color(0.88, 0.96, 1.00),
	&"rooted": Color(0.48, 0.52, 0.22),
}
## Fill of the summon lifetime bar (8.U1, Saplings): leafy green, never skinned.
const LIFETIME_COLOR := Color(0.55, 0.80, 0.30)

var selection: SelectionManager
var hero: Wizard

# Hero column
var hero_name: Button
var hero_hp: ProgressBar
var hero_hp_text: Label
var hero_mana: ProgressBar
var hero_mana_text: Label
var hero_status: Label      ## "Vessa returns in 24 s" while she is dead.
var hero_crown: Label       ## Shown while she wears the Ember Crown.
var hero_badge: Panel       ## Level badge (scales 1.0 -> 1.4 -> 1.0 on level-up / learning).
var hero_level: Label
var hero_xp: ProgressBar
var hero_xp_text: Label     ## "XP  320 / 450" or "XP  MAX".
var points_chip: PanelContainer   ## "+1", only while spell_points > 0 (36 x 14 in the hero tile).
var points_text: Label
var _xp_flash_left := 0.0
# 6.U1 skin: portrait, hero tile aura / trim line, ghost damage, low-HP pulse, level-up ring.
var portrait: Portrait
var portrait_window: PortraitWindow   ## The console's portrait window (holds `portrait`); the HUD places it.
var hero_tile: HeroTile               ## The hero tile (holds the hero_* parts); the HUD places it.
var hero_trim: ColorRect          ## 1 px trim line along the hero tile top (WARN pulse at low HP, gold flash).
var _aura: TextureRect
## Parts kept for the logic but not shown in the hero tile (statuses and the crown line live elsewhere, 3.1 / 4.2).
var _hero_hidden: Control
var _ghost: Control
var _ghost_value := -1.0          ## HP the ghost segment still shows (tweens down to the real HP in 0.5 s).
var _ghost_tween: Tween
var _last_hero_hp := -1.0
var _heal_flash_left := 0.0
var _trim_flash_left := 0.0
var _ring_t := -1.0               ## Level-up ring progress 0..1 (-1 = off).
var _title_labels: Array[Label] = []
var _muted_labels: Array[Label] = []
var _skin_bars: Array[ProgressBar] = []
var _skin_buttons: Array[Button] = []
var _skin := -1
var _view_tween: Tween
var _shown_view: Control
var _last_level := -1
var _last_ranks := -1
var _clock := 0.0
var _badge_tween: Tween
var hero_statuses: HBoxContainer    ## The wizard's status chips ("H 7"), read by tests; the wizard view shows them.

# Selection area views (one visible at a time)
var nothing_view: Label
var single_view: VBoxContainer
var multi_view: VBoxContainer
var keep_view: Control

var single_name: Label
var single_hp: ProgressBar
var single_hp_text: Label
var single_stats: Label
var single_mana: ProgressBar
var single_mana_text: Label
var single_statuses: HBoxContainer  ## Status chips of the selected unit.
var single_lifetime: ProgressBar    ## Summons only (8.U1): time left before it withers.
## 4.2 single view, right part (x 580): level medallion + `Level 3` / `Veteran`, XP bar, statuses, the wizard's learn row.
var stat_table: GridContainer       ## 2 x 2: Damage / Armor / Range / Speed (the plain units' stat line as a table).
var stat_values: Array[Label] = []  ## The 4 numbers, table order.
var single_right: VBoxContainer
var single_level_row: HBoxContainer
var single_badge: Panel
var single_badge_label: Label
var single_level_text: Label
var single_xp: ProgressBar
var single_xp_text: Label
var single_learn_row: HBoxContainer
var single_points: Label            ## "+2" gold chip (the wizard's spell points).
var single_learn_hint: Label        ## "Ctrl+F / Q / E: learn".
const STAT_IDS: Array[StringName] = [&"damage", &"armor", &"range", &"speed"]
const STAT_WORDS: Array[String] = ["Damage", "Armor", "Range", "Speed"]
const LEFT_COLUMN := 316.0          ## 4.2: the right part starts at x 580 (252 + 316 + 12).
var single_lifetime_text: Label     ## "Withers in 18 s".

var multi_header: Label
var icons: Array[Button] = []
var _icon_strips: Array[ColorRect] = []
var _icon_mana_strips: Array[ColorRect] = []   ## Casters: the 3 px mana strip above the HP strip.
var _icon_dots: Array = []          ## Array[Array[ColorRect]]: 3 veterancy dots per icon.
var _icon_status_dots: Array = []   ## Array[Dictionary]: status id -> coloured dot, per icon.
var _icon_units: Array[Unit] = []
var _icon_sig: Array = []                    ## Per icon: _icon_signature() of what it shows (0 = hidden)
var _icon_status_ids: Array[StringName] = [] ## The status ids that have a dot (same keys on every icon)

## Champion view (9.C7, champions.md 9, ui-champions.md 4): read-only, nothing can be ordered from it. Positions are
## relative to the selection block's content top-left (252, 696). The command card's "Champions act on their own." text
## is 9.C8's (command_card.gd).
const CHAMPION_ORIGIN := Vector2(252, 696)
const CH_TEXT_X := 0.0
const CH_ABILITY_X := 408.0
var champion_view: Control
var champion_name: Label        ## "SABLE QUINT" (display_name, Cinzel 20).
var champion_title: Label       ## " · the Coin-Cutter".
var champion_hp: ProgressBar
var champion_hp_text: Label     ## "HP  210 / 300".
var champion_xp: ProgressBar    ## Hidden for enemies.
var champion_xp_text: Label     ## "XP  320 / 400" or "XP  MAX".
var champion_stats: Label       ## "Level 3 · Damage 17 · Range 1.6 · Speed 5.6 · Armor 5".
var champion_intent: Label      ## "Hunting bounty: Gloom Hall" in the intent colour; enemy: "Enemy champion".
var champion_purse_box: HBoxContainer   ## "  ·  Purse " + flame + number (own only).
var champion_purse: Label       ## "120".
var champion_statuses: HBoxContainer    ## Status chips.
var champion_items: Array = []          ## 4 ChampionBar.ItemIcon 36 x 36 (read-only).
## 6 ability slots 48 x 48 (step 11, ui-champions.md 15.3): 0-2 = row 1 (archetype), 3-5 = row 2 (class; three `?`
## before the level-2 choice).
var champion_abilities: Array[AbilitySlot] = []
var _abilities_for: Node = null   ## U2-6: the champion the ability slots show now.
var champion_ability_names: Array[Label] = []
var champion_autocast: Label    ## "Autocast · next at level 3" / "Autocast".
var champion_class_label: Label ## " · Sword and Shield" (title colour) / " · no class yet" (text_muted).
var champion_row1_caption: Label   ## "the Oathwall".
var champion_row2_caption: Label   ## "Sword and Shield" / "Class at level 2".
var _champion_class_seen: Node = null
var _champion_class_id: StringName = &""
## A champion shown read-only (set with inspect(); cleared on the next selection change). The selection
## manager's `inspected` property (9.C8) wins when it has one.
var inspected: Node = null

var keep_name: Label
var keep_hp: ProgressBar
var keep_hp_text: Label
var queue_buttons: Array[Button] = []
var queue_progress: ProgressBar
var queue_count: Label   ## "Training <unit>  37 %" / "3 in queue" beside the queue slots.
var rally_label: Label
var building_info: Label    ## Site progress / builders, pop bonus, tower stats.
var site_row: Control
var site_progress: ProgressBar
var site_cancel: Button
var _queue_row: Control
## 4.2 building view, right part (x 580): the keep's tier line + bar, then rally / info / queue lines.
var keep_tier: Label
var keep_tier_bar: ProgressBar
var _queue_x: Array[Label] = []   ## The `x` shown on a hovered queue slot (click cancels).
const KEEP_RIGHT_X := 328.0
const QUEUE_SLOT := 44.0

## Trade (10.C7, ui-trade.md 5.2 / 6.2 / 6.3). Colours never skinned.
const GOLD_COIN := Color(1.0, 0.78, 0.25)
const GOLD_TEXT := Color(1.0, 0.88, 0.5)
const NEAR_COLOR := Color(0.4, 0.9, 0.4)
const FAR_COLOR := Color(1.0, 0.55, 0.2)
const COIN_RING := Color(0.55, 0.42, 0.10)
const COIN_INNER := Color(0.85, 0.62, 0.18)
const COIN_LIGHT := Color(1.0, 0.93, 0.65)
const WARE_COUNT := 4
## The Bazaar block over the keep view's empty right part: 264 x 100 at (1000, 676) (area offset (412, 6)).
const MARKET_BLOCK_POS := Vector2(600, 6)   ## Right of the building view's right part (4.2).
const MARKET_BLOCK_SIZE := Vector2(264, 100)
var market_block: Control
var market_route_row: HBoxContainer   ## A: "Route: " + name + " (near)".
var market_route_labels: Array[Label] = []
var market_value: Label               ## B
var market_caravans: Label            ## C
var market_traded: Label              ## D
var market_wares_row: HBoxContainer   ## E: "Wares 1 / 4 owned · " + [U]
var market_wares: Label
var market_wares_badge: Label
## Caravan single view: the stat line (coin + "Cargo 119 gold" + " · Route: " + post + " (far)") and the state line.
var single_stats_row: HBoxContainer   ## Holds single_stats (+ single_stats_extra for a Magpie's loot).
var single_stats_extra: Label         ## " · Carrying 60 gold" (GOLD_TEXT).
var cargo_row: HBoxContainer
var cargo_coin: Control
var cargo_labels: Array[Label] = []   ## cargo, " · Route: ", post name, " (far)"
var single_state: Label               ## Caravan state / tracker contract line (font 14).
var _icon_coins: Array[Control] = []  ## Multi view: the 6 px coin of a loaded caravan.
var _overlay: Control                 ## Plain control over the selection area (children placed by hand).

## Map fill (step 12, 12.C7, ui-mapfill.md 5.1 / 6.2 / 8). Colours never skinned.
const TIER_COLORS := {1: Color(0.85, 0.85, 0.75), 2: Color(1.0, 0.6, 0.25), 3: Color(1.0, 0.3, 0.25)}
const WADE_COLOR := Color(0.60, 0.78, 0.88)
const BLESSING_MODIFIER := &"blessing:wayshrine"
const FORD_MODIFIER := &"terrain:ford"
const BLESSING_CHIP := &"mf_blessing"
const WADING_CHIP := &"mf_wading"
const EPIC_BEASTS_PATH := "res://scripts/world/epic_beasts.gd"
const BEAST_BLOCK_POS := Vector2(600, 6)     ## Ability slots 48 at (852 + 58 j, 702) on screen.
const BEAST_SLOT_STEP := 58.0
const VARIANT_WORDS := {&"tusker": "alpha", &"roc": "dark breed", &"direwolf": "silver breed", &"grizzlemaw": "elder"}
const BEAST_KINDS := {
	&"ironhide_tusker": [&"tusker", 0], &"old_scarback": [&"tusker", 1],
	&"stormcrest_roc": [&"roc", 0], &"duskwing_roc": [&"roc", 1],
	&"greymane_direwolf": [&"direwolf", 0], &"moonpelt_direwolf": [&"direwolf", 1],
	&"grizzlemaw": [&"grizzlemaw", 0], &"elder_grizzlemaw": [&"grizzlemaw", 1],
}
## Beast abilities (ui-mapfill.md 6.2): name, abbreviation, line 2, effect, cooldown (0 = passive / triggered), and
## per-type overrides of line 2 / the effect.
const BEAST_ABILITIES := {
	&"gore_charge": ["Gore Charge", "GC", "Every 12 s · a target 6-14 m away",
			"Dashes at it: 45 damage and dazed 0.8 s; 20 damage near its path", 12.0],
	&"bristle_hide": ["Bristle Hide", "BH", "Passive", "Melee attackers take 4 damage per hit", 0.0],
	&"gale_swoop": ["Gale Swoop", "GS", "Every 10 s · leaps up to 12 m",
			"Onto the most crowded spot: 40 damage within 2.5 m, dazed 0.5 s", 10.0],
	&"shrieking_dive": ["Shrieking Dive", "SD", "Every 10 s · leaps up to 12 m",
			"Onto the most crowded spot: 40 damage within 2.5 m, marked 5 s", 10.0],
	&"updraft": ["Updraft", "UD", "Once, at 40 % HP", "Shrouded 4 s, flies to its nest and heals 15 %: chase it", 0.0],
	&"pounce": ["Pounce", "PO", "Every 9 s (Moonpelt: 6 s) · a target 5-10 m away",
			"Leaps on it: 35 damage and rooted 0.8 s", 9.0],
	&"hamstring": ["Hamstring", "HS", "Passive", "Its hits slow by 25 % for 3 s", 0.0],
	&"maul": ["Maul", "MA", "Every 9 s", "70 damage to its target and marked 5 s", 9.0],
	&"rending_roar": ["Rending Roar", "RR", "At 50 % HP, then every 30 s",
			"Dazes enemies within 6 m for 1 s (half on heroes)", 30.0],
	&"enrage": ["Enrage", "EN", "Below 30 % HP", "Attacks 30 % faster", 0.0],
}
const BEAST_ABILITY_OVERRIDES := {
	&"old_scarback": {&"gore_charge": "45 damage and dazed 1.2 s to everyone on its path"},
	&"elder_grizzlemaw": {&"rending_roar": "Dazes enemies within 6 m for 1 s (half on heroes) + taunts soldiers 3 s"},
}
const BEAST_ABILITY_IDS := {
	&"ironhide_tusker": [&"gore_charge", &"bristle_hide"], &"old_scarback": [&"gore_charge", &"bristle_hide"],
	&"stormcrest_roc": [&"gale_swoop", &"updraft"], &"duskwing_roc": [&"shrieking_dive", &"updraft"],
	&"greymane_direwolf": [&"pounce", &"hamstring"], &"moonpelt_direwolf": [&"pounce", &"hamstring"],
	&"grizzlemaw": [&"maul", &"rending_roar", &"enrage"], &"elder_grizzlemaw": [&"maul", &"rending_roar", &"enrage"],
}
## Several buildings selected (2026-09-27, Tab cycles the active one): a strip of chips (one per selected building,
## Tab order) over the keep view's top-right; the active one has a gold frame + underline. Click a chip = make it
## active. At (412, 6) in the selection area, or (412, 110) under the Bazaar block when that one is shown.
const BUILDING_CHIPS := 12
const BUILDING_CHIP := 36.0
const BUILDING_CHIP_COLUMNS := 6
var building_strip: GridContainer
var building_chips: Array[Button] = []
var _chip_hp: Array[ColorRect] = []
var _chip_marks: Array[ColorRect] = []
var _chip_buildings: Array = []
var _chip_active := -1
var single_name_suffix: Label          ## Beasts: " · Epic beast" (font 14, text).
var single_name_variant: Label         ## Beasts: " · alpha" (font 14, GOLD).
var single_extra_rows: Array[HBoxContainer] = []   ## Camp row + reward row (creatures) / drops + lair (beasts).
var beast_block: Control
var beast_slots: Array[BeastAbilitySlot] = []
var beast_slot_names: Array[Label] = []


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())   # the ConsoleFrame draws the frame
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # the console under it stops the clicks
	# The console's selection block: x 244 -> (right edge - 468), y 692-892 at 1600 x 900 (888 x 200).
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = LEFT
	offset_right = -RIGHT
	offset_top = -(900.0 - TOP)
	offset_bottom = offset_top + SIZE.y
	custom_minimum_size = Vector2(0, SIZE.y)

	var area := MarginContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_theme_constant_override("margin_left", 8)    # content x 252-1124, y 696-888
	area.add_theme_constant_override("margin_right", 8)
	area.add_theme_constant_override("margin_top", 4)
	area.add_theme_constant_override("margin_bottom", 4)
	add_child(area)

	nothing_view = UIStyle.panel_label("Nothing selected", 16)
	_muted_labels.append(nothing_view)
	nothing_view.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nothing_view.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nothing_view.draw.connect(_draw_emblem)
	area.add_child(nothing_view)
	portrait = Portrait.new()
	portrait_window = PortraitWindow.new()
	single_view = _build_single_view()
	area.add_child(single_view)
	multi_view = _build_multi_view()
	area.add_child(multi_view)
	keep_view = _build_keep_view()
	area.add_child(keep_view)
	champion_view = _build_champion_view()
	area.add_child(champion_view)
	_overlay = Control.new()
	_overlay.name = "TradeOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(_overlay)
	market_block = _build_market_block()
	_overlay.add_child(market_block)
	beast_block = _build_beast_block()
	_overlay.add_child(beast_block)
	building_strip = _build_building_strip()
	_overlay.add_child(building_strip)
	# The hero tile and the portrait window start in the overlay; GameHUD moves them to its root (their own corners).
	hero_tile = _build_hero_tile()
	_overlay.add_child(hero_tile)
	_overlay.add_child(portrait_window)
	portrait_window.setup_portrait(portrait)
	_show_view(nothing_view)


func setup(p_hero: Wizard, p_selection: SelectionManager) -> void:
	hero = p_hero
	if selection != null and selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)
	selection = p_selection
	if selection != null:
		selection.selection_changed.connect(_on_selection_changed)
	portrait_window.selection = selection
	hero_name.text = GameHUD.wizard_short_name(hero)
	hero_name.tooltip_text = Loc.t("Select your wizard  [F1]")


## Shows `champion` (own or visible enemy) read-only in the selection area until the selection changes.
## The selection manager calls it after its own selection change (a click on a champion). null clears it.
func inspect(champion: Variant) -> void:
	inspected = champion as Node if ChampionBar.is_champion(champion) else null
	refresh()


func _on_selection_changed() -> void:
	inspected = null


## The champion the panel shows read-only, or null: the selection manager's `inspected` (9.C8, read with get() so
## it works before the field exists), else a lone selected champion, else the one given to inspect(). Own
## champions stay while fallen; enemy ones are dropped when they die or the fog hides them.
func inspected_champion() -> Node:
	if selection != null:
		var s: Variant = selection.get("inspected")
		if s is Node and _can_inspect(s):
			return s
		if selection.selected_building == null and selection.selected.size() == 1 \
				and ChampionBar.is_champion(selection.selected[0]) and _can_inspect(selection.selected[0]):
			return selection.selected[0]
	if inspected != null:
		if _can_inspect(inspected):
			return inspected
		inspected = null
	return null


## The inspected unit that is not a champion (a Greywater Tracker, a Magpie, a visible enemy unit), or null.
func inspected_unit() -> Unit:
	if selection == null:
		return null
	var s: Variant = selection.get("inspected")
	if not is_instance_valid(s) or not (s is Unit) or ChampionBar.is_champion(s):
		return null
	return s as Unit


func _can_inspect(n: Variant) -> bool:
	if not ChampionBar.is_champion(n) or (n as Node).is_queued_for_deletion():
		return false
	var node := n as Node
	if is_own(node):
		return true
	return ChampionBar.is_alive(node) and (not (node is CanvasItem or node is Node3D)
			or bool(node.call(&"is_visible_in_tree")))


## True when `node` is on the player's team.
func is_own(node: Node) -> bool:
	var own_team := int(hero.team) if hero != null and is_instance_valid(hero) else 0
	return node != null and node.get("team") != null and int(node.get("team")) == own_team


## Live language switch: the building-strip chips cache their tooltip per building; forget them so the next
## refresh rebuilds the tooltips in the new language (review 2026-10-08 L3).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		for i in _chip_buildings.size():
			_chip_buildings[i] = null


func _process(delta: float) -> void:
	_clock += delta
	if _skin != UIStyle.skin_version:
		apply_skin()
	if _xp_flash_left > 0.0:
		_xp_flash_left -= delta
		if _xp_flash_left <= 0.0:
			UIStyle.set_bar_color(hero_xp, UIStyle.GOLD)
	if _heal_flash_left > 0.0:
		_heal_flash_left -= delta
	if _trim_flash_left > 0.0:
		_trim_flash_left -= delta
	if _ring_t >= 0.0:
		_ring_t += delta / 0.5
		if _ring_t >= 1.0:
			_ring_t = -1.0
		if hero_tile:
			hero_tile.queue_redraw()
	refresh()


## Re-applies the kingdom skin (GameHUD.setup calls it after UIStyle.set_kingdom; also auto on skin change).
func apply_skin() -> void:
	_skin = UIStyle.skin_version
	for l in _title_labels:
		l.add_theme_color_override("font_color", UIStyle.token(&"title"))
	for l in _muted_labels:
		l.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	for b in _skin_bars:
		var bg := b.get_theme_stylebox("background") as StyleBoxFlat
		if bg and b != hero_xp:
			bg.bg_color = UIStyle.token(&"panel_inner")
			bg.border_color = UIStyle.token(&"groove")
	for b in _skin_buttons:
		UIStyle.style_button(b)
	_chip_active = -2   # the building strip restyles its chips (gold frame on the active one) on the next refresh
	_icon_rim.clear()   # the multi icons and type tabs restyle on the next refresh
	_icon_sig.clear()
	for t in type_tabs:
		t.set_meta(&"_sig", "")
	if site_cancel:
		UIStyle.style_button(site_cancel, UIStyle.WARN)
	for slot in champion_abilities:
		slot.apply_skin()
	for icon: ChampionBar.ItemIcon in champion_items:
		icon.set_item(icon.item_type, icon.count)
	if champion_title:
		champion_title.add_theme_color_override("font_color", UIStyle.token(&"text"))
		champion_stats.add_theme_color_override("font_color", UIStyle.token(&"text"))
	if hero_name:
		_style_hero_name()
	if _aura:
		_aura.texture = _aura_texture()
	if hero_trim:
		hero_trim.color = _trim_color()
	if hero_tile:
		hero_tile.apply_skin()
	if portrait_window:
		portrait_window.apply_skin()
	nothing_view.queue_redraw()


func _style_hero_name() -> void:
	hero_name.add_theme_font_override("font", UIStyle.display_font())
	hero_name.add_theme_color_override("font_color", UIStyle.token(&"title"))
	hero_name.add_theme_color_override("font_hover_color", UIStyle.token(&"trim_glow"))
	hero_name.add_theme_color_override("font_pressed_color", UIStyle.token(&"frame_light"))
	hero_name.add_theme_color_override("font_disabled_color", UIStyle.token(&"text_muted"))


func _trim_color() -> Color:
	var g := UIStyle.token(&"trim_glow")
	return Color(g.r, g.g, g.b, 0.55)


func _aura_texture() -> GradientTexture2D:
	var g := Gradient.new()
	var glow := UIStyle.token(&"trim_glow")
	g.set_color(0, Color(glow.r, glow.g, glow.b, 0.10))
	g.set_color(1, Color(glow.r, glow.g, glow.b, 0.0))
	g.set_offset(1, 0.6)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 1
	t.height = 64
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	return t


## The hero tile's level-up ring (drawn by the tile, over its parts): radius 10 -> 32 px around the medallion, fading
## over 0.5 s.
func _draw_ring() -> void:
	if _ring_t < 0.0 or hero_badge == null or hero_tile == null:
		return
	var c := hero_badge.position + hero_badge.size * 0.5
	var a := 1.0 - _ring_t
	hero_tile.draw_arc(c, lerpf(10.0, 32.0, _ring_t), 0.0, TAU, 40, Color(UIStyle.GOLD, a), 3.0, true)


## Hexagonal level medallion (flat top): dark fill, 2 px gold edge, frame_light facet on the upper half.
func _draw_badge() -> void:
	var r := hero_badge.size.x * 0.5
	var c := Vector2(r, r)
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var alive := is_instance_valid(hero) and hero.is_alive()
	var edge := UIStyle.GOLD if alive or hero == null else Color(0.45, 0.42, 0.35)
	hero_badge.draw_colored_polygon(pts, Color(0.15, 0.12, 0.05))
	var closed := pts.duplicate()
	closed.append(pts[0])
	hero_badge.draw_polyline(closed, edge, 2.0, true)
	var inner := PackedVector2Array()
	for i in [3, 4, 5, 0]:
		var a := deg_to_rad(60.0 * i)
		inner.append(c + Vector2(cos(a), sin(a)) * (r - 3.0))
	hero_badge.draw_polyline(inner, UIStyle.token(&"frame_light"), 1.0, true)


func _draw_name_underline() -> void:
	if hero_name.is_hovered() and not hero_name.disabled:
		var w := hero_name.get_theme_font("font").get_string_size(hero_name.text.to_upper(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var y := hero_name.size.y - 3.0
		hero_name.draw_line(Vector2(4, y), Vector2(4 + w, y), UIStyle.token(&"trim_glow"), 2.0)


## Kingdom emblem at alpha 0.06 behind "Nothing selected" (UIStyle.draw_emblem: Fire flames, Shadow crescent,
## Ice snowflake, Nature leaf).
func _draw_emblem() -> void:
	var c := nothing_view.size * 0.5
	var col := Color(UIStyle.token(&"title"), 0.06)
	UIStyle.draw_emblem(nothing_view, UIStyle.get_kingdom(), c, 56.0, col)


## Updates the hero column and the selection area (runs every frame).
func refresh() -> void:
	_update_hero()
	if selection == null:
		return
	var champion := inspected_champion()
	market_block.visible = false
	beast_block.visible = false
	var strip_shown := false
	var other := inspected_unit()
	if champion != null:
		_update_champion(champion)
		portrait.set_target(champion)
	elif selection.selected_building != null:
		_update_keep(selection.selected_building)
		portrait.set_target(selection.selected_building)
		strip_shown = _update_building_strip()
	elif other != null:
		_update_single(other)   # a tracker, a Magpie, a visible enemy unit: read-only single view
		portrait.set_target(other)
	elif selection.selected.is_empty():
		_show_view(nothing_view)
		portrait.set_target(null)
	elif selection.selected.size() == 1:
		_update_single(selection.selected[0])
		portrait.set_target(selection.selected[0])
	else:
		_update_multi(selection.selected)
		portrait.set_target(_active_type_unit())   # 4.3: the active type tab's unit
	building_strip.visible = strip_shown
	# Nothing to show, or a champion without a model (its initials only): hide the portrait's last render (else the
	# previous unit's picture stays behind).
	if portrait.view != null:   # (built in the portrait's _ready, once a view holds it)
		portrait.view.visible = portrait.target != null and (champion == null or champion.get("model_scene") != null)


## The first selected unit of the active type (the multi-selection's portrait), or null.
func _active_type_unit() -> Unit:
	if selection == null:
		return null
	var group := selection.active_type_units()
	if not group.is_empty():
		return group[0]
	return selection.selected[0] if not selection.selected.is_empty() else null


## The strip of selected buildings (2+): chips in Tab order, the active one framed in gold. Returns true when shown.
func _update_building_strip() -> bool:
	var raw: Variant = selection.get("selected_buildings")
	var list: Array = raw if raw is Array else []
	if list.size() < 2:
		return false
	building_strip.position = Vector2(MARKET_BLOCK_POS.x, 110) if market_block.visible else MARKET_BLOCK_POS
	var active := -1
	for i in BUILDING_CHIPS:
		var chip := building_chips[i]
		if i >= list.size() or not is_instance_valid(list[i]):
			chip.visible = false
			_chip_buildings[i] = null
			continue
		var b: Node3D = list[i]
		chip.visible = true
		if b == selection.selected_building:
			active = i
		if _chip_buildings[i] != b:
			_chip_buildings[i] = b
			var type: Variant = b.get("building_type")
			var type_name := str(type.get("display_name")) if type is Object else "Building"
			var tex: Texture2D = ItemTooltip.HudSkin.icon("buildings", str(type.get("id"))) \
					if type is Object and type.get("id") != null else null
			chip.icon = tex
			chip.text = "" if tex != null else UIStyle.abbrev(type_name)
			chip.tooltip_text = Loc.t("%s\nClick: show it  ·  Tab / Shift+Tab: next / previous building") \
					% (type_name if type is Object else Loc.t(type_name))
		var max_hp := float(b.get("max_hp")) if b.get("max_hp") != null else 0.0
		var hp := float(b.get("hp")) if b.get("hp") != null else max_hp
		var ratio := clampf(hp / max_hp, 0.0, 1.0) if max_hp > 0.0 else 1.0
		_chip_hp[i].size.x = BUILDING_CHIP * ratio
		_chip_hp[i].color = Color(0.3, 0.85, 0.3) if ratio > 0.5 else (Color(0.95, 0.8, 0.2) if ratio > 0.25
				else Color(0.9, 0.25, 0.2))
	if active != _chip_active:
		_chip_active = active
		for i in BUILDING_CHIPS:
			UIStyle.style_button(building_chips[i], UIStyle.GOLD if i == active else UIStyle.PANEL_BORDER)
			_chip_marks[i].visible = i == active
			building_chips[i].modulate = Color.WHITE if i == active else Color(0.8, 0.8, 0.8)
	return true


## Index of the highlighted (active) chip in the building strip, -1 when the strip is hidden (for tests).
func active_building_chip() -> int:
	return _chip_active if building_strip.visible else -1


## The buildings the strip shows, in chip order (for tests).
func building_strip_buildings() -> Array:
	var out: Array = []
	if building_strip.visible:
		for i in BUILDING_CHIPS:
			if building_chips[i].visible:
				out.append(_chip_buildings[i])
	return out


func _build_building_strip() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "BuildingStrip"
	grid.columns = BUILDING_CHIP_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	grid.position = MARKET_BLOCK_POS
	grid.visible = false
	for i in BUILDING_CHIPS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(BUILDING_CHIP, BUILDING_CHIP)
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_font_size_override("font_size", 12)
		UIStyle.style_button(b)
		b.pressed.connect(_on_building_chip_pressed.bind(i))
		var hp := ColorRect.new()   # HP strip inside the frame bottom
		hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hp.position = Vector2(0, BUILDING_CHIP - 3.0)
		hp.size = Vector2(BUILDING_CHIP, 3)
		b.add_child(hp)
		var mark := ColorRect.new()   # the active chip's gold underline
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.color = UIStyle.GOLD
		mark.position = Vector2(2, BUILDING_CHIP + 1.0)
		mark.size = Vector2(BUILDING_CHIP - 4.0, 3)
		mark.visible = false
		b.add_child(mark)
		grid.add_child(b)
		building_chips.append(b)
		_chip_hp.append(hp)
		_chip_marks.append(mark)
		_chip_buildings.append(null)
	return grid


func _on_building_chip_pressed(index: int) -> void:
	if selection and index < _chip_buildings.size() and is_instance_valid(_chip_buildings[index]):
		selection.set_active_building(_chip_buildings[index])


## Which view is shown: "nothing", "single", "multi", "keep" or "champion" (for tests).
func current_view() -> String:
	if champion_view.visible:
		return "champion"
	if single_view.visible:
		return "single"
	if multi_view.visible:
		return "multi"
	if keep_view.visible:
		return "keep"
	return "nothing"


## Clicking queue slot `slot` (0 = the one training) cancels it at the selected keep.
func cancel_slot(slot: int) -> void:
	if selection == null or selection.selected_building == null:
		return
	var keep := selection.selected_building
	var queue: Array = _queue_of(keep)
	if slot < queue.size() and keep.has_method("cancel"):
		keep.call("cancel", slot)


# ---------------------------------------------------------------- updates

func _update_hero() -> void:
	if hero == null:
		return
	var alive := is_instance_valid(hero) and hero.is_alive()
	_update_hero_fx(alive)
	if alive:
		hero_hp.max_value = hero.max_hp
		hero_hp.value = hero.hp
		hero_hp_text.text = Loc.t("HP  %d / %d") % [ceili(hero.hp), int(hero.max_hp)]
		hero_mana.max_value = hero.max_mana
		hero_mana.value = hero.mana
		hero_mana_text.text = Loc.t("Mana  %d / %d") % [int(hero.mana), int(hero.max_mana)]
		if hero_name.disabled:   # back from the dead (Wizard.respawn)
			hero_name.modulate = Color.WHITE
			hero_name.disabled = false
		hero_status.visible = false
		hero_hp_text.visible = true
	else:
		hero_hp.value = 0
		hero_mana.value = 0
		hero_hp_text.text = Loc.t("HP  0")
		hero_mana_text.text = Loc.t("Mana  0")
		hero_name.modulate = Color(0.5, 0.5, 0.5)
		hero_name.disabled = true
		var left := _respawn_left()
		hero_status.text = Loc.t("%s returns in %d s") % [_short_name(), ceili(left)] if left > 0.0 else Loc.t("Fallen")
		hero_status.visible = true
		hero_hp_text.visible = false   # the countdown sits on the empty bar
	if hero_tile:
		hero_tile.set_wizard(hero, alive)
	_update_level(alive)
	_update_status_row(hero_statuses, hero if alive else null)
	var crown := _worn_crown()
	hero_crown.visible = crown != null
	if hero_tile:
		var tip := Loc.t("Select your wizard  [F1]") + "\n" + Loc.t("Double-click: centre the camera")
		if crown != null:
			tip += "\n" + hero_crown.text
		if hero_tile.tooltip_text != tip:
			hero_tile.tooltip_text = tip
	if crown != null:
		hero_crown.text = Loc.t("%s  +%d HP · +%d mana") % [str(crown.get("artifact_name")),
				int(crown.get("bonus_hp")), int(crown.get("bonus_mana"))]


## Ghost damage (0.5 s drain), heal flash (0.15 s), low-HP pulse (< 30 %: 1.5 Hz fill + WARN trim line).
func _update_hero_fx(alive: bool) -> void:
	var hp := float(hero.hp) if alive else 0.0
	var max_hp := maxf(float(hero.max_hp), 1.0) if is_instance_valid(hero) else 1.0
	if _last_hero_hp >= 0.0:
		if hp < _last_hero_hp - 0.01:
			if _ghost_value < _last_hero_hp:
				_ghost_value = _last_hero_hp
			if _ghost_tween:
				_ghost_tween.kill()
			_ghost_tween = create_tween()
			_ghost_tween.tween_property(self, "_ghost_value", hp, 0.5).set_ease(Tween.EASE_OUT)
		elif hp > _last_hero_hp + maxf(2.0, max_hp * 0.01):
			_heal_flash_left = 0.15
	_last_hero_hp = hp
	_ghost.queue_redraw()
	var low := alive and hp / max_hp < 0.3
	var fill := UIStyle.HP_COLOR
	if _heal_flash_left > 0.0:
		fill = Color(0.5, 1.0, 0.5)
	elif low:
		fill = UIStyle.HP_COLOR.lerp(Color(1.0, 0.45, 0.40), 0.5 + 0.5 * sin(_clock * TAU * 1.5))
	UIStyle.set_bar_color(hero_hp, fill)
	if _trim_flash_left > 0.0:
		hero_trim.color = UIStyle.GOLD
	elif low:
		hero_trim.color = Color(UIStyle.WARN, 0.65 + 0.25 * sin(_clock * TAU * 1.5))
	else:
		hero_trim.color = _trim_color()


## True while the hero's HP fill pulses (HP < 30 %) (for tests).
func is_low_hp_pulsing() -> bool:
	return hero_trim != null and is_instance_valid(hero) and hero.is_alive() \
			and hero.hp / maxf(hero.max_hp, 1.0) < 0.3


func _draw_ghost() -> void:
	if hero_hp.max_value <= 0.0 or _ghost_value <= hero_hp.value:
		return
	var w := _ghost.size.x
	var x0 := w * clampf(hero_hp.value / hero_hp.max_value, 0.0, 1.0)
	var x1 := w * clampf(_ghost_value / hero_hp.max_value, 0.0, 1.0)
	_ghost.draw_rect(Rect2(x0, 1, x1 - x0, _ghost.size.y - 2), Color(1.0, 0.85, 0.8, 0.8))


## Level badge, XP bar, points chip; plays the flash when the level or a spell rank goes up.
func _update_level(alive: bool) -> void:
	if not is_instance_valid(hero):
		return
	var level := int(hero.get("level")) if hero.get("level") != null else 1
	hero_level.text = str(level)
	hero_badge.modulate = Color.WHITE if alive else Color(0.5, 0.5, 0.5)
	var has_xp := hero.get("xp") != null and hero.has_method(&"xp_to_next")
	hero_xp.visible = has_xp
	var xp_part := ""
	if has_xp:
		var xp := int(hero.get("xp"))
		var next := int(hero.call(&"xp_to_next"))
		if next <= 0:
			hero_xp.max_value = 1.0
			hero_xp.value = 1.0
			hero_xp_text.text = Loc.t("XP  MAX")
			xp_part = Loc.t("MAX")
		else:
			hero_xp.max_value = float(next)
			hero_xp.value = float(xp)
			hero_xp_text.text = Loc.t("XP  %d / %d") % [xp, next]
			xp_part = "%d / %d" % [xp, next]
	var points := int(hero.get("spell_points")) if hero.get("spell_points") != null else 0
	if xp_part != "":
		hero_badge.tooltip_text = Loc.tn("Level {level} · XP {xp} · {n} spell point", "Level {level} · XP {xp} · {n} spell points",
				points, {"level": level, "xp": xp_part})
	else:
		hero_badge.tooltip_text = Loc.tn("Level {level} · {n} spell point", "Level {level} · {n} spell points", points,
				{"level": level})
	points_chip.visible = points > 0
	# The chip sits on the XP bar's right end (3.1): the bar stops short of it while it shows.
	var xp_w := HeroTile.POINTS_RECT.position.x - 4.0 - HeroTile.XP_RECT.position.x if points > 0 else HeroTile.XP_RECT.size.x
	if hero_xp.size.x != xp_w:
		hero_xp.custom_minimum_size.x = xp_w
		hero_xp.size.x = xp_w
	if points > 0:
		points_text.text = "+%d" % points
		points_chip.modulate.a = 0.85 + 0.15 * sin(_clock * TAU / 0.8)
	var ranks := 0
	for id in SpellInfo.ids(hero):
		ranks += SpellInfo.rank(hero, id)
	if (_last_level >= 0 and level > _last_level) or (_last_ranks >= 0 and ranks > _last_ranks):
		flash_level_up(level > _last_level)
	_last_level = level
	_last_ranks = ranks


## The badge scales 1.0 -> 1.4 -> 1.0 over 0.4 s; on a level-up the XP bar also flashes white 0.2 s.
func flash_level_up(xp_bar := true) -> void:
	if _badge_tween:
		_badge_tween.kill()
	hero_badge.scale = Vector2.ONE
	_badge_tween = create_tween()
	_badge_tween.tween_property(hero_badge, "scale", Vector2(1.4, 1.4), 0.2)
	_badge_tween.tween_property(hero_badge, "scale", Vector2.ONE, 0.2)
	if xp_bar:
		UIStyle.set_bar_color(hero_xp, Color.WHITE)
		_xp_flash_left = 0.2
		_ring_t = 0.0          # gold ring behind the badge (0.5 s)
		_trim_flash_left = 0.3 # the hero column's trim line flashes gold


## Seconds until the dead wizard returns (the level's respawn timer; 0 when unknown).
func _respawn_left() -> float:
	var level := get_tree().current_scene
	if level == null or not level.has_method(&"respawn_time_left") or not is_instance_valid(hero):
		return 0.0
	return float(level.call(&"respawn_time_left", int(hero.team)))


## The level's artifact (the Ember Crown) when our wizard wears it, else null.
func _worn_crown() -> Node:
	var level := get_tree().current_scene
	if level == null or not is_instance_valid(hero):
		return null
	var crown: Variant = level.get("artifact")
	if is_instance_valid(crown) and crown is Node and "wearer" in crown and crown.get("wearer") == hero:
		return crown
	return null


## "Vessa, Fire Wizard" -> "Vessa".
func _short_name() -> String:
	return hero.unit_name.get_slice(",", 0).strip_edges() if is_instance_valid(hero) else "Your wizard"


func _update_single(u: Unit) -> void:
	_show_view(single_view)
	var wiz := u as Wizard
	var level := int(u.get("level")) if u.get("level") != null else 1
	var xp := int(u.get("xp")) if u.get("xp") != null else 0
	# Veterancy (levels.md): soldiers only; workers, towers and wardens never level.
	var veteran := wiz == null and not u.has_method(&"command_gather") and (level > 1 or xp > 0)
	# Built once, assigned once: this runs every frame and Label re-shapes on every text change (review M5).
	var name_line := u.unit_name
	if veteran and level > 1:
		name_line += " · " + Loc.t(str(u.call(&"veterancy_name")) if u.has_method(&"veterancy_name") else rank_name(level))
	if single_name.text != name_line:
		single_name.text = name_line
	single_hp.max_value = u.max_hp
	single_hp.value = u.hp
	single_hp_text.text = Loc.t("HP  %d / %d") % [ceili(u.hp), int(u.max_hp)]
	var dmg := float(u.call(&"get_stat", &"attack_damage")) if u.has_method(&"get_stat") else u.attack_damage
	# Ice units and Torvald (kingdom-ice.md 3-4) carry base armor: show it when there is any.
	var armor := float(u.call(&"get_stat", &"armor")) if u.has_method(&"get_stat") else 0.0
	# One template per variant (localization.md: no concatenated fragments).
	var args := {"dmg": _num(dmg), "range": _dec1(u.attack_range), "speed": _dec1(u.move_speed), "armor": _num(armor),
			"level": level}
	var line := Loc.t("Damage {dmg} · Range {range} · Speed {speed} · Armor {armor}", args) if armor > 0.0 \
			else Loc.t("Damage {dmg} · Range {range} · Speed {speed}", args)
	if wiz != null and u.get("level") != null:
		line = Loc.t("Level %d · %s") % [level, line]
	elif veteran:
		var next := _veteran_next(u, level)
		line = Loc.t("%s · XP MAX") % line if next <= 0 else Loc.t("%s · XP %d / %d") % [line, xp, next]
	if single_stats.text != line:
		single_stats.text = line
	var vals: Array[String] = [_num(dmg), _num(armor), _dec1(u.attack_range), _dec1(u.move_speed)]
	for i in stat_values.size():
		if stat_values[i].text != vals[i]:
			stat_values[i].text = vals[i]
	_update_single_right(u, wiz, level, xp, veteran)
	var caster := CasterKit.ability_of(u)   # caster-units.md 9.1 (hud.): the caster's mana bar in the single view
	single_mana.visible = wiz != null or caster != null
	if wiz:
		single_mana.max_value = wiz.max_mana
		single_mana.value = wiz.mana
		single_mana_text.text = Loc.t("Mana  %d / %d") % [int(wiz.mana), int(wiz.max_mana)]
	elif caster:
		single_mana.max_value = maxf(1.0, caster.max_mana())
		single_mana.value = caster.mana
		single_mana_text.text = Loc.t("Mana  %d / %d") % [int(caster.mana), int(caster.max_mana())]
	var life := lifetime_of(u)
	single_lifetime.visible = life.y > 0.0
	if life.y > 0.0:
		single_lifetime.max_value = life.y
		single_lifetime.value = life.x
		single_lifetime_text.text = Loc.t("Withers in %d s") % ceili(life.x)
	_update_status_row(single_statuses, u)
	_update_trade_lines(u)
	_update_mapfill_lines(u)
	# The plain units' stats as the 2 x 2 table; caravans, trackers and loaded Magpies keep their one-line text.
	var table := single_stats.visible and not single_stats_extra.visible and not single_state.visible
	stat_table.visible = table
	if table:
		single_stats.visible = false


## The right part of the single view: level + XP (wizard, soldiers with veterancy), the wizard's points / learn row.
func _update_single_right(u: Unit, wiz: Wizard, level: int, xp: int, veteran: bool) -> void:
	var leveled := wiz != null and u.get("level") != null or veteran
	single_level_row.visible = leveled
	single_xp.visible = leveled
	if leveled:
		var lvl_text := Loc.t("Level %d") % level if wiz != null else Loc.t(
				str(u.call(&"veterancy_name")) if u.has_method(&"veterancy_name") else rank_name(level))
		if single_level_text.text != lvl_text:
			single_level_text.text = lvl_text
		if single_badge_label.text != str(level):
			single_badge_label.text = str(level)
		var next := int(wiz.call(&"xp_to_next")) if wiz != null and wiz.has_method(&"xp_to_next") else _veteran_next(u, level)
		single_xp.max_value = maxf(1.0, float(next))
		single_xp.value = float(xp) if next > 0 else single_xp.max_value
		var t := Loc.t("XP  %d / %d") % [xp, next] if next > 0 else Loc.t("XP  MAX")
		if single_xp_text.text != t:
			single_xp_text.text = t
	var points := int(wiz.get("spell_points")) if wiz != null and wiz.get("spell_points") != null else 0
	var learn := wiz != null and wiz == hero and wiz.has_method(&"learn_spell")
	single_learn_row.visible = learn
	if learn:
		single_points.visible = points > 0
		single_points.text = "+%d" % points
		var hint := Loc.t("Ctrl+%s: learn") % KeyLabels.join([KEY_F, KEY_Q, KEY_E], " / ")
		if single_learn_hint.text != hint:
			single_learn_hint.text = hint


## The stat table as text ("Damage 12 · Armor 0 · Range 1.6 · Speed 5.0"; "" when hidden), for tests.
func stat_table_text() -> String:
	if stat_table == null or not stat_table.visible:
		return ""
	var parts: PackedStringArray = []
	for i in stat_values.size():
		parts.append("%s %s" % [STAT_WORDS[i], stat_values[i].text])
	return " · ".join(parts)


# ---------------------------------------------------------------- map fill (12.C7, ui-mapfill.md 5.1 / 6.2)

## Creatures of a camp: the camp row + the reward row; epic beasts: the name subtitle, the drops and lair rows and
## the ability block; anything else: none of it.
func _update_mapfill_lines(u: Unit) -> void:
	var beast := u.is_in_group(&"beasts")
	var camp := _camp_of(u) if not beast else null
	single_name_suffix.visible = beast
	single_name_variant.visible = false
	if beast:
		var kv := beast_kind_variant(u)
		single_name_suffix.text = Loc.t(" · Epic beast")
		var word := str(VARIANT_WORDS.get(kv[0], "")) if int(kv[1]) == 1 else ""
		single_name_variant.visible = word != ""
		single_name_variant.text = " · " + Loc.t(word)
		var muted := UIStyle.token(&"text_muted")
		_set_segments(single_extra_rows[0], [[Loc.t("Drops: "), muted], [beast_drop_text(kv[0], int(kv[1])),
				UIStyle.token(&"text")]])
		var lair := _lair_name(u)
		_set_segments(single_extra_rows[1], [[Loc.t("Roams the %s") % lair, muted]] if lair != "" else [])
		_update_beast_block(u)
	elif camp != null:
		var r: Dictionary = camp.call(&"reward_preview") if camp.has_method(&"reward_preview") else {}
		var tier := int(r.get(&"tier", camp.get(&"tier") if camp.get(&"tier") != null else 1))
		var level := int(r.get(&"camp_level", camp.get(&"camp_level") if camp.get(&"camp_level") != null else 0))
		var total := int(r.get(&"creatures", 0))
		var alive: int = (camp.call(&"creatures") as Array).size() if camp.has_method(&"creatures") else 0
		var text_c := UIStyle.token(&"text")
		var muted := UIStyle.token(&"text_muted")
		var row0: Array = [[str(camp.get(&"display_name")), text_c], [" · ", muted],
				[Loc.t("Tier %d") % tier, tier_color(tier)], [Loc.t(" · %d of %d left") % [alive, total], text_c]]
		if level > 0:
			row0.append([Loc.t(" · Level %d") % level, muted])
		_set_segments(single_extra_rows[0], row0)
		var row1: Array = [["~%d XP" % int(r.get(&"xp", 0)), UIStyle.GOLD], [" · ", muted],
				[Loc.t("+%d essence") % int(r.get(&"essence", 0)), UIStyle.ESSENCE_TEXT]]
		var drop := Loc.sink(str(r.get(&"drop_text", "")))
		if drop != "":
			row1.append_array([[" · ", muted], [drop, muted]])
		var cm := get_tree().get_first_node_in_group(&"camp_manager")
		var own_team := int(hero.team) if hero != null and is_instance_valid(hero) else 0
		if cm != null and cm.has_method(&"underdog_team") and int(cm.call(&"underdog_team")) == own_team:
			row1.append([Loc.t(" · Underdog bonus"), NEAR_COLOR])
		_set_segments(single_extra_rows[1], row1)
	else:
		# docs/design/unit-upgrades.md: the Forge levels that touch this soldier ("Forge: Weapons 2/3 · Lance Drill").
		var forge := forge_line(u)
		_set_segments(single_extra_rows[0], [[forge, UIStyle.token(&"text_muted")]] if forge != "" else [])
		_set_segments(single_extra_rows[1], [])


## The Forge row of a soldier (unit-upgrades.md 5): "Forge: Weapons 2/3 · Armor 1/3 · Lance Drill", "" = none.
static func forge_line(u: Unit) -> String:
	var parts: PackedStringArray = []
	for e: Array in ForgeKit.summary_for(u):
		var nm := Loc.t(String(e[0]))
		parts.append(nm if int(e[2]) <= 1 else Loc.t("{name} {level}/{max}", {"name": nm, "level": e[1], "max": e[2]}))
	if parts.is_empty():
		return ""
	return Loc.t("Forge: {lines}", {"lines": " · ".join(parts)})


## The camp of a creature (CampManager.camp_of, group "camp_manager"), or null.
func _camp_of(u: Node) -> Node:
	var cm := get_tree().get_first_node_in_group(&"camp_manager") if is_inside_tree() else null
	if cm == null or not cm.has_method(&"camp_of"):
		return null
	var c: Variant = cm.call(&"camp_of", u)
	return c as Node if c is Node and is_instance_valid(c) else null


## The camp line of the viewed creature as one line (tests; map-fill.md 8): `Gloomcap Hollow · Tier 2 · 3 of 4 left
## · ~86 XP · +25 essence · 35 % a component` (no level, no underdog). "" when the view shows no camp creature.
func camp_line_text() -> String:
	if not single_view.visible or not single_extra_rows[0].visible or single_name_suffix.visible:
		return ""
	var parts: PackedStringArray = []
	for i in 2:
		for c in single_extra_rows[i].get_children():
			var l := c as Label
			if l == null or not l.visible:
				continue
			if l.text.begins_with(" · Level") or l.text == " · Underdog bonus":
				continue
			parts.append(l.text)
		if i == 0:
			parts.append(" · ")
	return "".join(parts)


## The two map-fill rows under the stat line as shown (tests), joined with "\n".
func mapfill_rows_text() -> String:
	var out: PackedStringArray = []
	for row in single_extra_rows:
		if row.visible:
			var s := ""
			for c in row.get_children():
				if c is Label and (c as Label).visible:
					s += (c as Label).text
			out.append(s)
	return "\n".join(out)


## The beast name row as plain text (tests): `Old Scarback · Epic beast · alpha`.
func beast_title_text() -> String:
	if not single_name_suffix.visible:
		return ""
	return single_name.text + single_name_suffix.text + (single_name_variant.text if single_name_variant.visible else "")


static func tier_color(tier: int) -> Color:
	return TIER_COLORS.get(clampi(tier, 1, 3), TIER_COLORS[1])


## [kind, variant] of a beast (meta beast_variant wins; else the type id table).
static func beast_kind_variant(u: Node) -> Array:
	var kind := &""
	var variant := 0
	var t: Variant = u.get(&"unit_type")
	var tid := StringName(str((t as Resource).get(&"id"))) if t is Resource else &""
	var info: Variant = BEAST_KINDS.get(tid)
	if info is Array:
		kind = info[0]
		variant = int(info[1])
	if u.has_meta(&"beast_variant"):
		variant = int(u.get_meta(&"beast_variant"))
	return [kind, variant]


## The EpicBeasts node (group "epic_beasts"), or null.
func _epic_beasts() -> Node:
	return get_tree().get_first_node_in_group(&"epic_beasts") if is_inside_tree() else null


func _lair_name(u: Node) -> String:
	var eb := _epic_beasts()
	if eb == null or not eb.has_method(&"lair_of"):
		return ""
	var lair: Variant = eb.call(&"lair_of", u)
	return str((lair as Dictionary).get("name", "")) if lair is Dictionary else ""


## EpicBeasts.DROP_TABLES (from the live node's script, else the script file), {} when neither exists.
static func beast_drop_tables() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var eb := tree.get_first_node_in_group(&"epic_beasts") if tree != null else null
	var script: Script = eb.get_script() as Script if eb != null else null
	if script == null and ResourceLoader.exists(EPIC_BEASTS_PATH):
		script = load(EPIC_BEASTS_PATH) as Script
	if script == null:
		return {}
	var v: Variant = script.get_script_constant_map().get("DROP_TABLES")
	return v if v is Dictionary else {}


static func item_name(id: StringName) -> String:
	var t := ItemType.find(id)
	if t != null and str(t.get(&"display_name")) != "":
		return str(t.get(&"display_name"))
	return String(id).capitalize()


## The drop preview (ui-mapfill.md 6.2 rule) of a beast kind and variant: certain rows of several items count as
## components (`a component`, `2 components`), a certain single item is named, a chance row reads `30 % Vital Root` /
## `60 % Warden Scale or Vital Root`; ` · a trophy` when the variant's trophy item exists.
static func beast_drop_text(kind: StringName, variant: int) -> String:
	var table: Variant = beast_drop_tables().get(kind)
	if not (table is Dictionary):
		return ""
	var parts: Array[String] = []
	var comp_at := -1
	var comps := 0
	for row: Variant in (table as Dictionary).get("rows", []):
		if not (row is Dictionary):
			continue
		var rv := int((row as Dictionary).get("variant", -1))
		if rv != -1 and rv != variant:
			continue
		var items: Array = (row as Dictionary).get("items", [])
		var chance := float((row as Dictionary).get("chance", 1.0))
		if chance >= 1.0 and items.size() > 1:
			comps += 1
			if comp_at == -1:
				comp_at = parts.size()
				parts.append("")
		elif chance >= 1.0 and items.size() == 1:
			parts.append(item_name(StringName(str(items[0]))))
		elif not items.is_empty():
			var names: Array[String] = []
			for it: Variant in items:
				names.append(item_name(StringName(str(it))))
			parts.append(Loc.t("%d %% %s") % [roundi(chance * 100.0), Loc.t(" or ").join(names)])
	if comp_at >= 0:
		parts[comp_at] = Loc.t("a component") if comps == 1 else Loc.t("%d components") % comps
	var trophy: Variant = (table as Dictionary).get("trophy", [])
	if trophy is Array and variant >= 0 and variant < (trophy as Array).size() \
			and ItemType.find(StringName(str((trophy as Array)[variant]))) != null:
		parts.append(Loc.t("a trophy"))
	return " · ".join(parts)


## Ability ids of a beast: its CreatureAbilities' list, else the table by type id.
func beast_ability_ids(u: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	var ab := u.get_node_or_null(^"CreatureAbilities")
	if ab != null and ab.has_method(&"ability_ids"):
		for id: Variant in ab.call(&"ability_ids"):
			out.append(StringName(str(id)))
	if out.is_empty():
		var t: Variant = u.get(&"unit_type")
		var tid := StringName(str((t as Resource).get(&"id"))) if t is Resource else &""
		for id: Variant in BEAST_ABILITY_IDS.get(tid, []):
			out.append(StringName(str(id)))
	return out


## `Gore Charge\nEvery 12 s · a target 6-14 m away\n<effect>` for a beast of type `type_id`.
static func beast_ability_tooltip(id: StringName, type_id: StringName) -> String:
	var info: Array = BEAST_ABILITIES.get(id, [String(id).capitalize(), "", "", "", 0.0])
	var effect := str(info[3])
	var over: Dictionary = BEAST_ABILITY_OVERRIDES.get(type_id, {})
	if over.has(id):
		effect = str(over[id])
	return "%s\n%s\n%s" % [info[0], Loc.t(str(info[2])), Loc.t(effect)]   # the ability name is a proper name


func _update_beast_block(u: Node) -> void:
	beast_block.visible = true
	var ids := beast_ability_ids(u)
	var ab := u.get_node_or_null(^"CreatureAbilities")
	var t: Variant = u.get(&"unit_type")
	var tid := StringName(str((t as Resource).get(&"id"))) if t is Resource else &""
	for j in beast_slots.size():
		var slot := beast_slots[j]
		var shown := j < ids.size()
		slot.visible = shown
		beast_slot_names[j].visible = shown
		if not shown:
			continue
		var id := ids[j]
		var info: Array = BEAST_ABILITIES.get(id, [String(id).capitalize(), UIStyle.abbrev(String(id).capitalize()),
				"", "", 0.0])
		var total := float(info[4])
		if tid == &"moonpelt_direwolf" and id == &"pounce":
			total = 6.0
		var left := 0.0
		if ab != null and total > 0.0 and ab.has_method(&"cooldown_left"):
			left = float(ab.call(&"cooldown_left", id))
			if ab.has_method(&"cooldown_total") and float(ab.call(&"cooldown_total", id)) > 0.0:
				total = float(ab.call(&"cooldown_total", id))
		slot.show_beast_ability(id, str(info[1]), left, total)
		slot.tooltip_text = beast_ability_tooltip(id, tid)
		beast_slot_names[j].text = str(info[0])


## The beast block's ability names (tests), e.g. "Gore Charge, Bristle Hide"; "" while hidden.
func beast_ability_list() -> String:
	if beast_block == null or not beast_block.visible:
		return ""
	var parts: PackedStringArray = []
	for j in beast_slots.size():
		if beast_slots[j].visible:
			parts.append(beast_slot_names[j].text)
	return ", ".join(parts)


## Sets a row from [text, colour] segments (font 13 labels reused); no segments = hidden.
func _set_segments(row: HBoxContainer, segments: Array) -> void:
	row.visible = not segments.is_empty()
	var have := row.get_child_count()
	for j in maxi(have, segments.size()):
		if j >= segments.size():
			(row.get_child(j) as Label).visible = false
			continue
		var l: Label
		if j < have:
			l = row.get_child(j) as Label
		else:
			l = UIStyle.panel_label("", 13)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(l)
		l.visible = true
		if l.text != str(segments[j][0]):
			l.text = str(segments[j][0])
		UIStyle.set_color_if_changed(l, &"font_color", segments[j][1])


# ---------------------------------------------------------------- trade lines (10.C7, ui-trade.md 6.2 / 6.3)

## Caravans: the cargo / route line replaces the stat line, the state line under it. Trackers: the contract line.
## Magpies: ` · Carrying 60 gold` after the stat line.
func _update_trade_lines(u: Unit) -> void:
	var caravan := u.is_in_group(&"caravans")
	var tracker := u.is_in_group(&"trackers")
	single_stats.visible = not caravan
	cargo_row.visible = caravan
	single_state.visible = false
	var loot := int(u.get_meta(&"loot", 0)) if u.is_in_group(&"magpies") else 0
	single_stats_extra.visible = loot > 0
	if loot > 0:
		single_stats_extra.text = Loc.t(" · Carrying %d gold") % loot
	if caravan:
		_update_caravan_lines(u)
	elif tracker:
		single_state.visible = true
		if is_own(u):
			single_state.text = tracker_contract_text(u)
			UIStyle.set_color_if_changed(single_state, &"font_color", UIStyle.token(&"text"))
		else:
			single_state.text = "Enemy hunters"
			UIStyle.set_color_if_changed(single_state, &"font_color", UIStyle.token(&"text_muted"))


func _update_caravan_lines(u: Unit) -> void:
	var cargo := int(u.get("cargo")) if u.get("cargo") != null else 0
	var loaded := bool(u.call(&"is_loaded")) if u.has_method(&"is_loaded") else cargo > 0
	cargo_coin.visible = loaded
	cargo_labels[0].text = Loc.t("Cargo %d gold") % cargo if loaded else "Empty"
	UIStyle.set_color_if_changed(cargo_labels[0], &"font_color", GOLD_TEXT if loaded else UIStyle.token(&"text_muted"))
	var own := is_own(u)
	for i in range(1, 4):
		cargo_labels[i].visible = own
	if not own:
		return   # an enemy caravan: its cargo only (raiders want to know)
	var post: Variant = u.get("route_post")
	var muted := UIStyle.token(&"text_muted")
	UIStyle.set_color_if_changed(cargo_labels[1], &"font_color", muted)
	UIStyle.set_color_if_changed(cargo_labels[2], &"font_color", UIStyle.token(&"text"))
	UIStyle.set_color_if_changed(cargo_labels[3], &"font_color", muted)
	if is_instance_valid(post) and post is Node3D:
		var market: Variant = u.get("home_market")
		var far := false
		if is_instance_valid(market) and market is Node:
			far = RouteLine.is_far(market, post)
		else:
			var net := get_tree().get_first_node_in_group(&"trade_network")
			far = net != null and net.has_method(&"is_far") and bool(net.call(&"is_far", int(u.team), post))
		cargo_labels[1].text = " · Route: "
		cargo_labels[2].text = RouteLine.post_name(post)
		cargo_labels[3].text = " (far)" if far else " (near)"
	else:
		cargo_labels[1].text = " · No route: right-click a post"
		cargo_labels[2].text = ""
		cargo_labels[3].text = ""
	single_state.visible = true
	var state := str(u.call(&"state_text")) if u.has_method(&"state_text") else "Idle"
	single_state.text = Loc.sink(state)   # the caravan's state line comes from its logic (English there)
	UIStyle.set_color_if_changed(single_state, &"font_color", caravan_state_color(state))


## The colour of a caravan state line (ui-trade.md 6.2).
static func caravan_state_color(state: String) -> Color:
	if state.begins_with("Waiting"):
		return UIStyle.WARN
	if state.begins_with("Trading") or state.begins_with("Returning"):
		return UIStyle.GOLD
	if state.begins_with("To "):
		return UIStyle.token(&"text")
	return UIStyle.token(&"text_muted")   # Loading, Idle


## `Contract: Outriders · 1:42 left` for an own Greywater Tracker (its TrackerContract: the unit's meta, else the
## contract in group "tracker_contracts" whose `trackers` holds it); `Contract ended` without one.
func tracker_contract_text(u: Node) -> String:
	var contract: Variant = null
	for key: StringName in [&"_tracker_contract", &"contract"]:   # F3a: meta renamed (runtime marker)
		if u.has_meta(key):
			var c: Variant = u.get_meta(key)
			if is_instance_valid(c) and c is Node:
				contract = c
				break
	if contract == null:
		for c in get_tree().get_nodes_in_group(&"tracker_contracts"):
			var list: Variant = c.get("trackers")
			if list is Array and (list as Array).has(u):
				contract = c
				break
	if contract == null:
		return "Contract ended"
	var kind := str((contract as Node).get("kind")) if (contract as Node).get("kind") != null else ""
	var name := kind.capitalize() if kind != "" else Loc.t("Hunters")
	var left := float((contract as Node).call(&"time_left")) if (contract as Node).has_method(&"time_left") else 0.0
	var secs := maxi(ceili(left), 0)
	return Loc.t("Contract: %s · %d:%02d left") % [name, secs / 60, secs % 60]


## The visible text lines of the single view under the HP bar (stat or cargo line, then the state / contract line),
## joined with "\n", for tests.
func single_lines() -> String:
	var lines: PackedStringArray = []
	if cargo_row.visible:
		var t := ""
		for l in cargo_labels:
			if l.visible:
				t += l.text
		lines.append(t)
	elif single_stats.visible or stat_table.visible:
		lines.append(single_stats.text + (single_stats_extra.text if single_stats_extra.visible else ""))
	if single_state.visible:
		lines.append(single_state.text)
	return "\n".join(lines)


## True while the cargo line shows its coin (a loaded caravan), for tests.
func cargo_coin_shown() -> bool:
	return cargo_row.visible and cargo_coin.visible


## True when multi-select icon `i` shows the loaded-caravan coin, for tests.
func icon_coin_shown(i: int) -> bool:
	return i >= 0 and i < _icon_coins.size() and icons[i].visible and _icon_coins[i].visible


## The 5 lines of the Bazaar block joined with "\n" ("" when hidden: enemy Bazaars, other buildings).
func market_block_text() -> String:
	if market_block == null or not market_block.visible:
		return ""
	var a := ""
	for l in market_route_labels:
		a += l.text
	return "\n".join(PackedStringArray([a, market_value.text, market_caravans.text, market_traded.text,
			market_wares.text + market_wares_badge.text]))


## Draws a gold coin (ui-trade.md 16.2) of `radius` at `c` on `ci`.
static func draw_coin(ci: CanvasItem, c: Vector2, radius: float) -> void:
	ci.draw_circle(c, radius, GOLD_COIN)
	ci.draw_arc(c, radius - 0.5, 0.0, TAU, 20, COIN_RING, 1.0, true)
	if radius > 5.0:
		ci.draw_arc(c, radius * 0.62, 0.0, TAU, 16, COIN_INNER, 1.0, true)
	ci.draw_arc(c, radius * 0.75, deg_to_rad(200.0), deg_to_rad(290.0), 8, COIN_LIGHT, 1.5, true)


## The Bazaar block (own completed Bazaar only): route, value / waiting line, caravans, gold traded, wares.
func _update_market_block(market: Node3D) -> void:
	market_block.visible = true
	var muted := UIStyle.token(&"text_muted")
	var text_c := UIStyle.token(&"text")
	var post: Variant = market.get("route_post")
	var valid_post := is_instance_valid(post) and post is Node3D
	market_route_labels[0].text = "Route: "
	UIStyle.set_color_if_changed(market_route_labels[0], &"font_color", muted)
	if valid_post:
		var far := RouteLine.is_far(market, post)
		market_route_labels[1].text = RouteLine.post_name(post)
		UIStyle.set_color_if_changed(market_route_labels[1], &"font_color", UIStyle.GOLD)
		market_route_labels[2].text = " (far)" if far else " (near)"
		UIStyle.set_color_if_changed(market_route_labels[2], &"font_color", FAR_COLOR if far else NEAR_COLOR)
		var reason := RouteLine.route_reason(market, post)
		if reason.begins_with("Trading posts open"):
			market_value.text = "Posts open at 4:00 · caravans wait"
			UIStyle.set_color_if_changed(market_value, &"font_color", UIStyle.WARN)
		elif reason == "Held by the enemy":
			market_value.text = "Held by the enemy · caravans wait"
			UIStyle.set_color_if_changed(market_value, &"font_color", UIStyle.WARN)
		else:
			market_value.text = Loc.t("%d gold per trip · ~%d / min each") % [RouteLine.value_of(market, post),
					RouteLine.per_minute(market, post)]
			UIStyle.set_color_if_changed(market_value, &"font_color", text_c)
	else:
		market_route_labels[1].text = "none"
		UIStyle.set_color_if_changed(market_route_labels[1], &"font_color", muted)
		market_route_labels[2].text = ""
		market_value.text = "Right-click a trading post to set the route"
		UIStyle.set_color_if_changed(market_value, &"font_color", muted)
	var alive: int = (market.call(&"caravans") as Array).size() if market.has_method(&"caravans") else 0
	var queued := int(market.call(&"queued_caravans")) if market.has_method(&"queued_caravans") else 0
	var limit := int(market.get("CARAVAN_LIMIT")) if market.get("CARAVAN_LIMIT") != null else 6
	market_caravans.text = Loc.t("Caravans %d / %d (%d queued)") % [alive, limit, queued] if queued > 0 \
			else Loc.t("Caravans %d / %d") % [alive, limit]
	UIStyle.set_color_if_changed(market_caravans, &"font_color", UIStyle.WARN if alive + queued >= limit else text_c)
	var team := int(market.get("team"))
	var net := get_tree().get_first_node_in_group(&"trade_network")
	var recent := int(net.call(&"trade_income", team, 180.0)) if net != null and net.has_method(&"trade_income") else 0
	var bank := _gold_bank(team)
	var total := int(bank.call(&"earned", &"trade")) if bank != null and bank.has_method(&"earned") else 0
	market_traded.text = Loc.t("Gold traded, last 3 min: %s · total %s") % [thousands(recent), thousands(total)]
	var owned: Variant = bank.get("owned_wares") if bank != null else null
	market_wares.text = Loc.t("Wares %d / %d owned · ") % [(owned as Array).size() if owned is Array else 0, WARE_COUNT]


## The GoldBank of `team` (group "gold_banks"), or null.
func _gold_bank(team: int) -> Node:
	for b in get_tree().get_nodes_in_group(&"gold_banks"):
		if b.get("team") != null and int(b.get("team")) == team:
			return b
	return null


## 2140 -> "2 140".
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


## Champion view (read-only, ui-champions.md 4 + 15.3): name + title + class, HP, XP, stats with level, intent +
## target, purse, statuses, 4 items, 6 abilities in 2 rows with cooldowns. Enemy: no XP, `Enemy champion`, no purse,
## no sweeps.
func _update_champion(ch: Node) -> void:
	_show_view(champion_view)
	var own := is_own(ch)
	var alive := ChampionBar.is_alive(ch)
	var guild := ChampionBar.guild_for_team(get_tree(), int(hero.team) if is_instance_valid(hero) else 0)
	champion_name.text = ChampionBar.display_name_of(ch)
	var title := ChampionBar.title_of(ch)
	champion_title.text = " · " + title if title != "" else ""
	var cid := ChampionBar.class_id_of(ch)
	var chosen_now := ch == _champion_class_seen and cid != _champion_class_id and cid != &""
	_champion_class_seen = ch
	_champion_class_id = cid
	if cid != &"":
		champion_class_label.text = " · " + ChampionBar.class_display_name(cid)
		champion_class_label.tooltip_text = ChampionBar.class_tooltip_for(ch)
		UIStyle.set_color_if_changed(champion_class_label, &"font_color", UIStyle.token(&"title"))
	else:
		champion_class_label.text = " · no class yet"
		champion_class_label.tooltip_text = ChampionBar.lean_tooltip(_champion_weights(ch, own), 0, own)
		UIStyle.set_color_if_changed(champion_class_label, &"font_color", UIStyle.token(&"text_muted"))
	var max_hp := ChampionBar.max_hp_of(ch)
	var hp := float(ch.get("hp")) if alive and ch.get("hp") != null else 0.0
	champion_hp.max_value = max_hp
	champion_hp.value = hp
	champion_hp_text.text = Loc.t("HP  %d / %d") % [ceili(hp), int(max_hp)]
	champion_xp.visible = own and ch.get("xp") != null
	if champion_xp.visible:
		var xp := int(ch.get("xp"))
		var next := int(ch.call(&"xp_to_next")) if ch.has_method(&"xp_to_next") else 0
		champion_xp.max_value = float(maxi(next, 1))
		champion_xp.value = float(xp) if next > 0 else 1.0
		champion_xp_text.text = ChampionBar.xp_text(ch)
	champion_stats.text = Loc.t("Level %d · Damage %s · Range %s · Speed %s · Armor %s") % [ChampionBar.level_of(ch),
			_num(_stat_of(ch, &"attack_damage")), Loc.num(_stat_of(ch, &"attack_range"), 1),
			Loc.num(_stat_of(ch, &"move_speed"), 1), _num(_stat_of(ch, &"armor"))]
	if own:
		var line := ChampionBar.target_text(ch, guild)   # English: intent_color below reads it
		var shown := ChampionBar.target_text(ch, guild, true)   # the player's language (French template)
		if alive and ChampionBar.is_unpaid(ch):
			line = "Unpaid!"
			shown = Loc.sink(line)
		champion_intent.text = shown
		UIStyle.set_color_if_changed(champion_intent, &"font_color", ChampionBar.intent_color(line))
		champion_purse.text = str(ChampionBar.purse_of(ch))
	else:
		champion_intent.text = "Enemy champion"
		UIStyle.set_color_if_changed(champion_intent, &"font_color", UIStyle.token(&"text_muted"))
	# Intent label max width 260 (ellipsis), then the purse (15.3: the row stops at x 392).
	var font := champion_intent.get_theme_font("font")
	var text_w := font.get_string_size(champion_intent.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			champion_intent.get_theme_font_size("font_size")).x if font != null else 260.0
	champion_intent.custom_minimum_size.x = minf(ceilf(text_w) + 1.0, 260.0)
	champion_purse_box.visible = own
	_update_status_row(champion_statuses, ch if alive else null)
	champion_statuses.visible = true   # keeps its place (an empty row shows nothing)
	var types := ChampionBar.item_types(ch)
	var counts := ChampionBar.item_counts(ch)
	for i in champion_items.size():
		var icon: ChampionBar.ItemIcon = champion_items[i]
		if icon.item_type != types[i] or icon.count != int(counts[i]):
			icon.set_item(types[i], int(counts[i]))
	_update_champion_abilities(ch, own)
	if chosen_now:
		_play_champion_class_chosen()


## Class weights for the lean tooltip: own champions the live weights (bounties included), enemy ones the
## archetype's base weights (ui-champions.md 15.5).
func _champion_weights(ch: Node, own: bool) -> Dictionary:
	return ChampionBar.class_weights_for(ch if own else ChampionBar.champion_id(ch))


## The inspected champion just chose its class (15.3): the title's class part fades in 0.3 s, the row-2 caption
## flashes GOLD -> title over 0.5 s, the class skills pop 1.0 -> 1.08 -> 1.0 staggered 0.05 s, slot 1 flashes ready.
func _play_champion_class_chosen() -> void:
	champion_class_label.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(champion_class_label, "modulate:a", 1.0, 0.3)
	champion_row2_caption.add_theme_color_override("font_color", UIStyle.GOLD)
	var c := create_tween()
	c.tween_method(func(k: float) -> void:
		champion_row2_caption.add_theme_color_override("font_color", UIStyle.GOLD.lerp(UIStyle.token(&"title"), k)),
		0.0, 1.0, 0.5)
	for j in 3:
		var slot := champion_abilities[3 + j]
		if not slot.visible or slot.placeholder:
			continue
		if j == 0 and slot.modulate.a > 0.5:
			slot.play_ready_flash()   # the unlocked first skill: ready flash (it pops too)
		else:
			slot.pop(0.05 * j)


## A stat for the stat line: get_stat() when the unit has it (not for the range), else the property.
func _stat_of(u: Node, stat: StringName) -> float:
	if u.has_method(&"get_stat") and stat != &"attack_range":
		return float(u.call(&"get_stat", stat))
	var v: Variant = u.get(stat)
	return float(v) if v != null else 0.0


## The 6 ability slots (ui-champions.md 15.3). Row 1 = the 3 archetype ids (`abilities.archetype_ability_ids()`,
## else the first 3 of `ability_ids()`, else the type's list); row 2 = the class's 3 skills in unlock order
## (`abilities.class_skill_ids()`, else `ability_ids()` 4-6, else the class table), or three `?` before the level-2
## choice (badges L2 / L3 / L5, lean tooltip). Locked ones dimmed with their `L<n>` badge; own champions show the
## cooldown sweep from `abilities.cooldown_left(id)`. Captions: the archetype title; the class name / `Class at level 2`.
func _update_champion_abilities(ch: Node, own: bool) -> void:
	if ch != _abilities_for:
		# U2-6: another champion: the slots forget the old one's cooldowns (no false "ready" flash)
		_abilities_for = ch
		for slot in champion_abilities:
			slot.reset_cooling()
	var abilities: Variant = ch.get("abilities")
	if not (is_instance_valid(abilities) and abilities is Object):
		abilities = ch.get_node_or_null(^"ChampionAbilities")
	var ab: Object = abilities as Object if is_instance_valid(abilities) and abilities is Object else null
	var all_ids := _champion_ids(ab, &"ability_ids")
	var info := ChampionBar.type_info(ChampionBar.champion_id(ch))
	var row1 := _champion_ids(ab, &"archetype_ability_ids")
	if row1.is_empty():
		row1.assign(all_ids.slice(0, 3))
	if row1.is_empty():
		for a: Variant in info.get("ability_ids", []):
			row1.append(StringName(str(a)))
	var cid := ChampionBar.class_id_of(ch)
	var row2: Array[StringName] = []
	if cid != &"":
		row2 = _champion_ids(ab, &"class_skill_ids")
		if row2.is_empty():
			row2.assign(all_ids.slice(3, 6))
		if row2.is_empty():
			for a: Variant in ChampionBar.class_info(cid).get("ability_ids", []):
				row2.append(StringName(str(a)))
	var level := ChampionBar.level_of(ch)
	var growth := float(info.get("growth_pct", 0.08))
	var spell_power := float(ch.call(&"get_stat", &"spell_power")) if ch.has_method(&"get_stat") else 0.0
	var type_id := ChampionBar.champion_id(ch)
	var locked_levels: Array[int] = []
	var weights := _champion_weights(ch, own) if cid == &"" else {}
	for i in champion_abilities.size():
		var slot := champion_abilities[i]
		var name_label := champion_ability_names[i]
		var row: Array[StringName] = row1 if i < 3 else row2
		var j := i % 3
		if i >= 3 and cid == &"":
			# Before the choice: three `?` slots with the lean tooltip.
			slot.visible = true
			name_label.visible = true
			var unlock := ChampionBar.CLASS_UNLOCKS[j]
			slot.show_placeholder(unlock)
			slot.tooltip_text = ChampionBar.lean_tooltip(weights, j + 1, own)
			name_label.text = Loc.t("Skill %d") % (j + 1)
			locked_levels.append(unlock)
			continue
		var shown := j < row.size()
		slot.visible = shown
		name_label.visible = shown
		if not shown:
			continue
		var id := row[j]
		var a := ChampionBar.ability_info(id)
		var unlock_at := int(a.get("unlock", 1))
		if ab != null and ab.has_method(&"unlock_level_for"):
			unlock_at = int(ab.call(&"unlock_level_for", id))
		var unlocked := level >= unlock_at
		if ab != null and ab.has_method(&"is_unlocked"):
			unlocked = bool(ab.call(&"is_unlocked", id))
		if not unlocked:
			locked_levels.append(unlock_at)
		var left := 0.0
		if own and ab != null and ab.has_method(&"cooldown_left"):
			left = maxf(float(ab.call(&"cooldown_left", id)), 0.0)
		slot.show_ability(id, unlocked, left, float(a.get("cooldown", 0.0)), unlock_at)
		slot.tooltip_text = ChampionBar.ability_tooltip(id, level if unlocked else mini(level, unlock_at - 1), growth,
				spell_power)
		name_label.text = ChampionBar.ability_display_name(id, type_id)
	champion_row1_caption.text = ChampionBar.title_of(ch)
	if cid != &"":
		champion_row2_caption.text = ChampionBar.class_display_name(cid)
		champion_row2_caption.tooltip_text = ChampionBar.class_tooltip_for(ch)
		UIStyle.set_color_if_changed(champion_row2_caption, &"font_color", UIStyle.token(&"title"))
	else:
		champion_row2_caption.text = "Class at level 2"
		champion_row2_caption.tooltip_text = ChampionBar.lean_tooltip(weights, 0, own)
		UIStyle.set_color_if_changed(champion_row2_caption, &"font_color", UIStyle.token(&"text_muted"))
	# `Autocast · next at level 3`: the lowest unlock level still ahead among the locked slots (own champions).
	var next := 0
	for l in locked_levels:
		if l > level and (next == 0 or l < next):
			next = l
	if next == 0 and not locked_levels.is_empty():
		next = level + 1
	champion_autocast.text = Loc.t("Autocast · next at level %d") % next if own and next > 0 else "Autocast"


## An id list from the champion's abilities node (`method` returns Array[StringName]), [] when it has none.
func _champion_ids(ab: Object, method: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if ab != null and ab.has_method(method):
		var v: Variant = ab.call(method)
		if v is Array or v is PackedStringArray:
			for a: Variant in v:
				out.append(StringName(str(a)))
	return out


## The names of the ability slots, row 1 then row 2, e.g. "Oath of Iron, Shield Bash, Bulwark Stand, Riposte,
## Second Wind, Shield Throw" (for tests). The `?` slots before the class choice are not abilities: left out.
func champion_ability_list() -> String:
	var parts: PackedStringArray = []
	for i in champion_abilities.size():
		if champion_abilities[i].visible and not champion_abilities[i].placeholder:
			parts.append(champion_ability_names[i].text)
	return ", ".join(parts)


## (seconds left, total seconds) of a summon's lifetime (`lifetime_left()` / `lifetime_total()`);
## (0, 0) for permanent units.
static func lifetime_of(u: Node) -> Vector2:
	if u == null or not is_instance_valid(u) or not u.has_method(&"lifetime_total"):
		return Vector2.ZERO
	var total := float(u.call(&"lifetime_total"))
	if total <= 0.0:
		return Vector2.ZERO
	var left := float(u.call(&"lifetime_left")) if u.has_method(&"lifetime_left") else total
	return Vector2(clampf(left, 0.0, total), total)


## Shows one chip per active status of `u` ("H 7" = Haste, 7 s left; timers from Unit.status_time_left).
## Hides the row when `u` is null or has none.
## True when `wizard`'s 2nd artifact slot holds something (the inventory bar then shows that slot above the 1st one).
static func second_artifact_shown(wizard: Node) -> bool:
	var inv: Variant = wizard.get("inventory") if wizard != null and is_instance_valid(wizard) else null
	if inv == null or not is_instance_valid(inv):
		return false
	var arts: Variant = (inv as Object).get("artifacts")
	return arts is Array and (arts as Array).size() > 1 and (arts as Array)[1] != null


func _update_status_row(row: HBoxContainer, u: Node) -> void:
	var any := false
	var can := u != null and is_instance_valid(u) and u.has_method(&"has_status")
	for chip: Control in row.get_children():
		if chip.has_meta(&"mapfill"):
			if _update_mapfill_chip(chip, u):
				any = true
			continue
		var id := StringName(chip.name)
		var on := can and bool(u.call(&"has_status", id))
		chip.visible = on
		if not on:
			continue
		any = true
		var left := ceili(float(u.call(&"status_time_left", id)))
		var info: Array = STATUS_INFO.get(id, ["?", String(id).capitalize(), ""])
		(chip.get_child(0) as Label).text = "%s %d" % [info[0], left]
		chip.tooltip_text = Loc.t("%s: %s · %d s left") % [Loc.t(str(info[1])), Loc.t(str(info[2])), left]
	row.visible = any


## Text of the visible status chips of a row, e.g. "H 7, S 3" (for tests).
func status_row_text(row: HBoxContainer) -> String:
	var parts: Array[String] = []
	if row.visible:
		for chip: Control in row.get_children():
			if chip.visible:
				if chip.has_meta(&"mapfill"):
					parts.append(str(chip.get_meta(&"row_text", "")))
				else:
					parts.append((chip.get_child(0) as Label).text)
	return ", ".join(parts)


## The blessing chip (`blessing:wayshrine`: shrine glyph + seconds, `Blessing 38` in status_row_text) and the wading
## chip (`terrain:ford`: the wave glyph, `Wading`) after the timed statuses (ui-mapfill.md 8). True when shown.
func _update_mapfill_chip(chip: Control, u: Node) -> bool:
	var has_mod := u != null and is_instance_valid(u) and u.has_method(&"has_modifier")
	if chip.name == String(BLESSING_CHIP):
		var on := has_mod and bool(u.call(&"has_modifier", BLESSING_MODIFIER))
		chip.visible = on
		if on:
			var secs := ceili(_blessing_left(int(u.get(&"team")) if u.get(&"team") != null else 0))
			(chip.get_node(^"Row/Secs") as Label).text = str(secs)
			chip.set_meta(&"row_text", "Blessing %d" % secs)
			chip.tooltip_text = Loc.t("Wayfarer's Blessing %d s\n+12 %% speed, +1.5 HP / s") % secs
		return on
	var wading := has_mod and bool(u.call(&"has_modifier", FORD_MODIFIER))
	chip.visible = wading
	return wading


## Seconds of Wayfarer's Blessing `team` has left (CapturePoints.blessing_time_left), 0 without the service.
func _blessing_left(team: int) -> float:
	var cp := get_tree().get_first_node_in_group(&"capture_points_service") if is_inside_tree() else null
	if cp == null or not cp.has_method(&"blessing_time_left"):
		return 0.0
	return float(cp.call(&"blessing_time_left", team))


## The two map-fill chips at the end of a status row.
func _add_mapfill_chips(row: HBoxContainer) -> void:
	var gold := UIStyle.GOLD
	var bless := PanelContainer.new()
	bless.name = String(BLESSING_CHIP)
	bless.set_meta(&"mapfill", true)
	bless.set_meta(&"row_text", "Blessing")
	bless.custom_minimum_size = Vector2(40, 20)
	bless.mouse_filter = Control.MOUSE_FILTER_STOP
	var bs := UIStyle.slate_style(0.0, gold)
	bs.content_margin_left = 4.0
	bs.content_margin_right = 4.0
	bless.add_theme_stylebox_override("panel", bs)
	var brow := HBoxContainer.new()
	brow.name = "Row"
	brow.add_theme_constant_override("separation", 3)
	brow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bless.add_child(brow)
	var glyph := Control.new()
	glyph.custom_minimum_size = Vector2(10, 10)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.draw.connect(func() -> void: draw_shrine_glyph(glyph, Vector2.ZERO, 10.0, gold))
	brow.add_child(glyph)
	var secs := UIStyle.panel_label("", 12)
	secs.name = "Secs"
	secs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	secs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brow.add_child(secs)
	bless.visible = false
	row.add_child(bless)
	var wade := PanelContainer.new()
	wade.name = String(WADING_CHIP)
	wade.set_meta(&"mapfill", true)
	wade.set_meta(&"row_text", "Wading")
	wade.custom_minimum_size = Vector2(20, 20)
	wade.mouse_filter = Control.MOUSE_FILTER_STOP
	wade.tooltip_text = "Wading: -35 % speed"
	wade.add_theme_stylebox_override("panel", UIStyle.slate_style(0.0, UIStyle.WARN))
	var wave := Control.new()
	wave.custom_minimum_size = Vector2(12, 8)
	wave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wave.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave.draw.connect(func() -> void: draw_wave_glyph(wave, Vector2.ZERO))
	wade.add_child(wave)
	wade.visible = false
	row.add_child(wade)


## The Wayshrine glyph (ui-mapfill.md 2.3) in a box of `s` px at `o`: diamond + the floating rune, groove outline.
static func draw_shrine_glyph(ci: CanvasItem, o: Vector2, s: float, color: Color) -> void:
	var k := s / 18.0
	var pts := PackedVector2Array([o + Vector2(9, 5) * k, o + Vector2(14.5, 11) * k, o + Vector2(9, 17) * k,
			o + Vector2(3.5, 11) * k])
	ci.draw_colored_polygon(pts, color)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, UIStyle.token(&"groove"), 1.0, true)
	ci.draw_circle(o + Vector2(9, 2) * k, maxf(1.5 * k, 1.0), color)


## The wave glyph 12 x 8 at `o`: three 1.5 px sine lines (amplitude 1 px, period 6 px) at y 2 / 5 / 8, WADE colour.
static func draw_wave_glyph(ci: CanvasItem, o: Vector2) -> void:
	for y: float in [1.0, 4.0, 7.0]:
		var pts := PackedVector2Array()
		for i in 13:
			pts.append(o + Vector2(float(i), y + sin(float(i) / 6.0 * TAU)))
		ci.draw_polyline(pts, WADE_COLOR, 1.5, true)


## Soldier level names (levels.md "Unit veterancy"; rank 4 is "Paragon", champions.md 1).
static func rank_name(level: int) -> String:
	return ["Recruit", "Veteran", "Elite", "Paragon"][clampi(level - 1, 0, 3)]   # English (logic); shown via Loc.t


## XP a soldier needs for its next level (cumulative, from Unit.VETERANCY_XP), 0 at Paragon.
func _veteran_next(u: Unit, level: int) -> int:
	if u.has_method(&"veterancy_next_xp"):
		return int(u.call(&"veterancy_next_xp"))
	return Unit.VETERANCY_XP[level] if level >= 1 and level < Unit.VETERANCY_XP.size() else 0


## 13.2 -> "13.2", 12.0 -> "12" (French: "13,2").
func _num(v: float) -> String:
	if absf(v - roundf(v)) < 0.05:
		return str(roundi(v))
	return Loc.num(v, 1)


## "%.1f" (6.0 -> "6.0"), with the decimal comma in French.
static func _dec1(v: float) -> String:
	var s := "%.1f" % v
	return s.replace(".", ",") if Loc.is_french() else s


func _update_multi(units: Array[Unit]) -> void:
	_show_view(multi_view)
	var counts := {}
	var order: Array[String] = []
	for u in units:
		if not counts.has(u.unit_name):
			order.append(u.unit_name)
		counts[u.unit_name] = counts.get(u.unit_name, 0) + 1
	var parts: Array[String] = []
	for unit_name in order:
		parts.append("%d %s" % [counts[unit_name], unit_name])
	# 4.2: `9 selected` (right of the type tabs); the breakdown in its tooltip.
	var header := Loc.t("%d selected") % units.size()
	if multi_header.text != header:
		multi_header.text = header
	multi_header.tooltip_text = ", ".join(parts)
	_update_type_tabs()
	_icon_units.clear()
	# SC2 subgroups: with 2+ unit types, the active type's icons stay bright, the others dim (Tab cycles it).
	var active_key: StringName = &""
	if selection != null and selection.selected_unit_types().size() >= 2:
		active_key = selection.active_unit_type()
	if _icon_sig.size() != MAX_ICONS:
		_icon_sig.resize(MAX_ICONS)
	var more := units.size() - MAX_ICONS
	multi_more.visible = more > 0
	if more > 0:
		multi_more.text = Loc.t("+ %d more") % more
	for i in MAX_ICONS:
		var b := icons[i]
		if i >= units.size():
			b.visible = false
			_icon_sig[i] = 0
			continue
		var u := units[i]
		_icon_units.append(u)
		b.visible = true
		# Perf pass 2026-10-09: the icon is rebuilt only when something it shows changed (48 icons x text, tooltip,
		# strips and dots every frame cost ~1 ms with a big army selected). Same output.
		var sig := _icon_signature(u, active_key)
		if _icon_sig[i] == sig:
			continue
		_icon_sig[i] = sig
		var ratio := clampf(u.hp / maxf(u.max_hp, 1.0), 0.0, 1.0)
		# 4.2: the icon's rim follows HP (green > 50 %, yellow > 25 %, else WARN).
		var rim := icon_rim_color(ratio)
		if _icon_rim.size() <= i:
			_icon_rim.resize(MAX_ICONS)
		if _icon_rim[i] != rim:
			_icon_rim[i] = rim
			UIStyle.style_button(b, rim)
		b.modulate = Color.WHITE if active_key == &"" or SelectionManager.unit_type_key(u) == active_key \
				else Color(0.7, 0.7, 0.7)
		var tex := unit_icon(u)
		_icon_faces[i].texture = tex
		b.text = "" if tex != null else UIStyle.abbrev(u.unit_name)
		# Tooltip (5): `Name · HP x / y` (+ Mana); items joined by "  ·  " (each one translated template).
		b.tooltip_text = Loc.t("%s  HP %d / %d") % [u.unit_name, ceili(u.hp), int(u.max_hp)]
		var life := lifetime_of(u)
		if life.y > 0.0:
			b.tooltip_text += "  ·  " + Loc.t("withers in %d s") % ceili(life.x)
		var strip := _icon_strips[i]
		strip.color = UIStyle.health_color(ratio)
		strip.size.x = ICON_SIZE * ratio
		# Casters: a 2 px mana strip right above the HP strip (caster-units.md 9.1).
		var cab := CasterKit.ability_of(u)
		var mstrip := _icon_mana_strips[i]
		mstrip.visible = cab != null
		if cab:
			mstrip.size.x = ICON_SIZE * clampf(cab.mana / maxf(1.0, cab.max_mana()), 0.0, 1.0)
			b.tooltip_text += "  ·  " + Loc.t("Mana %d / %d") % [int(cab.mana), int(cab.max_mana())]
		# Veterancy dots: 1-3 gold dots for Veteran / Elite / Paragon soldiers.
		var marks := 0
		if not (u is Wizard) and u.get("level") != null:
			marks = clampi(int(u.get("level")) - 1, 0, 3)
		var dots: Array = _icon_dots[i]
		for j in dots.size():
			(dots[j] as ColorRect).visible = j < marks
		# Status dots (bottom left, above the HP strip), one colour per active status.
		var status_dots: Dictionary = _icon_status_dots[i]
		var has := u.has_method(&"has_status")
		for id: StringName in status_dots:
			(status_dots[id] as ColorRect).visible = has and u.has_status(id)
		_icon_coins[i].visible = u.is_in_group(&"caravans") and u.has_method(&"is_loaded") and bool(u.call(&"is_loaded"))


## A unit's icon (art/icons/units/<type id>.png; a wizard by her name, `vessa`), or null.
static func unit_icon(u: Unit) -> Texture2D:
	if u == null or not is_instance_valid(u):
		return null
	var tex: Texture2D = ItemTooltip.HudSkin.icon("units", String(u.unit_type.id)) if u.unit_type != null else null
	if tex == null and u is Wizard:
		tex = ItemTooltip.HudSkin.icon("units", GameHUD.wizard_short_name(u).to_lower())
	return tex


## The multi-selection icon rim for an HP ratio (4.2).
static func icon_rim_color(ratio: float) -> Color:
	if ratio > 0.5:
		return ICON_RIM_GREEN
	if ratio > 0.25:
		return ICON_RIM_YELLOW
	return UIStyle.WARN


## The type tabs (4.2): one per selected unit type in Tab order (icon 20 + count), the active one gold.
func _update_type_tabs() -> void:
	var types: Array[StringName] = selection.selected_unit_types() if selection != null else []
	var active := selection.active_unit_type() if selection != null else &""
	var counts := {}
	var sample := {}
	for u in selection.orderable_units():
		var k := SelectionManager.unit_type_key(u)
		counts[k] = int(counts.get(k, 0)) + 1
		if not sample.has(k):
			sample[k] = u
	for i in type_tabs.size():
		var t := type_tabs[i]
		if i >= types.size():
			t.visible = false
			continue
		t.visible = true
		var key := types[i]
		var u: Unit = sample.get(key)
		var sig := "%s|%d|%s" % [key, int(counts.get(key, 0)), active == key]
		if t.get_meta(&"_sig", "") == sig:
			continue
		t.set_meta(&"_sig", sig)
		t.set_meta(&"_type_key", key)
		var tex := unit_icon(u)
		(t.get_node(^"Face") as TextureRect).texture = tex
		t.text = str(int(counts.get(key, 0))) if tex != null else "%d %s" % [int(counts.get(key, 0)),
				UIStyle.abbrev(u.unit_name if u != null else String(key))]
		t.tooltip_text = Loc.t("%s  ·  %d\nClick: select only these  ·  Tab: next type") % [
				u.unit_name if u != null else String(key), int(counts.get(key, 0))]
		UIStyle.style_button(t, UIStyle.GOLD if active == key and types.size() >= 2 else UIStyle.PANEL_BORDER)


## True when multi-view icon `i` belongs to the active type (bright; the others dim with 2+ types), for tests.
func icon_is_active(i: int) -> bool:
	return i >= 0 and i < _icon_units.size() and icons[i].visible and icons[i].modulate == Color.WHITE


## The type key of the gold (active) type tab, &"" when none (one type only), for tests.
func active_type_tab() -> StringName:
	if type_tabs_shown() < 2 or selection == null:
		return &""
	return selection.active_unit_type()


## Number of type tabs shown (tests).
func type_tabs_shown() -> int:
	var n := 0
	for t in type_tabs:
		if t.visible:
			n += 1
	return n


## The icon showing `u` in the multi view, or -1 (tests).
func icon_index_of(u: Unit) -> int:
	return _icon_units.find(u)


## The rim colour of multi-view icon `i` (tests).
func icon_rim(i: int) -> Color:
	return _icon_rim[i] if i >= 0 and i < _icon_rim.size() and _icon_rim[i] is Color else Color.BLACK


## Everything a multi-selection icon shows of `u` (hash): identity, HP, lifetime, mana, level, statuses, coins, gold.
func _icon_signature(u: Unit, active_key: StringName) -> int:
	var life := lifetime_of(u)
	var cab := CasterKit.ability_of(u)
	if _icon_status_ids.is_empty() and not _icon_status_dots.is_empty():
		_icon_status_ids.assign((_icon_status_dots[0] as Dictionary).keys())
	var st := 0
	if u.has_method(&"has_status"):
		var bit := 1
		for id: StringName in _icon_status_ids:
			if u.has_status(id):
				st |= bit
			bit <<= 1
	return [u.get_instance_id(), u.hp, u.max_hp, u.unit_name, life, cab.mana if cab else -1.0,
			cab.max_mana() if cab else -1.0, u.get("level"), st, active_key, Loc.language,
			u.is_in_group(&"caravans") and u.has_method(&"is_loaded") and bool(u.call(&"is_loaded"))].hash()


func _update_keep(keep: Node3D) -> void:
	_show_view(keep_view)
	var type: Variant = keep.get("building_type")
	keep_name.text = str(type.get("display_name")) if type is Object else "Keep"
	var max_hp := float(keep.get("max_hp")) if keep.get("max_hp") != null else 0.0
	var hp := float(keep.get("hp")) if keep.get("hp") != null else max_hp
	keep_hp.max_value = maxf(max_hp, 1.0)
	keep_hp.value = hp
	keep_hp_text.text = Loc.t("HP  %d / %d") % [ceili(hp), int(max_hp)]
	var site := keep.has_method("is_constructed") and not bool(keep.call("is_constructed"))
	var trainer := keep.has_method("queue_unit") and not site
	var market := CommandCard.is_market(keep)
	site_row.visible = site
	keep_hp.visible = not site   # 4.2: a site shows its progress bar where the HP bar is
	_queue_row.visible = trainer
	rally_label.visible = trainer and keep.has_method("set_rally_point") and not market   # the Bazaar has a route
	if market and not site and is_own(keep):
		_update_market_block(keep)
	building_info.visible = true
	_update_keep_tier(keep if not site else null)
	if site:
		_update_site(keep)
		return
	building_info.text = _building_info_text(type)
	building_info.visible = building_info.text != ""
	_place_keep_right()
	if not trainer:
		return
	var queue: Array = _queue_of(keep)
	for i in QUEUE_SLOTS:
		var b := queue_buttons[i]
		var tex: Texture2D = null
		if i < queue.size() and queue[i] != null:
			var type_name := str(queue[i].get("display_name"))
			# The unit's icon (art/icons/units/<id>.png, like the command card), else its name as text.
			tex = ItemTooltip.HudSkin.icon("units", str(queue[i].get("id")))
			b.text = "" if tex != null else type_name
			b.tooltip_text = Loc.t("%s\nClick to cancel (full refund).") % type_name
			b.modulate.a = 1.0
		else:
			b.text = ""
			b.tooltip_text = ""
			b.modulate.a = 0.45
		if b.icon != tex:
			b.icon = tex
	var progress := 0.0
	if not queue.is_empty() and keep.has_method("train_progress"):
		progress = float(keep.call("train_progress"))
	queue_progress.value = clampf(progress, 0.0, 1.0)
	# "Training Cinder Hand 37 %" + "3 in queue" beside the slots (the Bazaar's block shows its own count).
	queue_count.visible = not market
	if queue.is_empty() or queue[0] == null:
		queue_count.text = "Nothing in training"
	else:
		queue_count.text = Loc.t("Training %s  %d %%\n%d in queue") % [str(queue[0].get("display_name")),
				floori(clampf(progress, 0.0, 1.0) * 100.0), queue.size()]
	var on_node := keep.has_method("rally_is_node") and bool(keep.call("rally_is_node"))
	rally_label.text = "Rally: gather node" if on_node else "Rally: set"
	for i in QUEUE_SLOTS:
		_queue_x[i].visible = queue_buttons[i].is_hovered() and i < queue.size()


## The keep's tier line (4.2, right part y 0): `Stronghold rising` + the bar while it upgrades, else
## `Tier 1 Keep · next Stronghold 400` (`Tier 3 Citadel` at the top). Hidden for other buildings / without tiers.
func _update_keep_tier(b: Node3D) -> void:
	var k := b as Keep
	var ts := TierSystem.instance()
	if k == null or ts == null:
		keep_tier.visible = false
		keep_tier_bar.visible = false
		return
	keep_tier.visible = true
	var line := ""
	if k.is_upgrading():
		line = Loc.t("{tier} rising", {"tier": Loc.t(TierSystem.tier_name(k.tier + 1))})
		keep_tier_bar.visible = true
		keep_tier_bar.value = clampf(k.upgrade_progress(), 0.0, 1.0)
	else:
		keep_tier_bar.visible = false
		var nxt := k.tier + 1
		if nxt > 3 or nxt > ts.max_tier:
			line = keep_tier_text(k)
		else:
			line = Loc.t("{tier_line} · next {name} {cost}", {"tier_line": keep_tier_text(k),
					"name": Loc.t(TierSystem.tier_name(nxt)), "cost": k.upgrade_cost()})
	if keep_tier.text != line:
		keep_tier.text = line


## The right part's lines stack from y 0: tier line (+ bar), rally, info, queue count.
func _place_keep_right() -> void:
	var y := 0.0
	for c: Control in [keep_tier, keep_tier_bar, rally_label, building_info, queue_count]:
		if not c.visible:
			continue
		c.position = Vector2(KEEP_RIGHT_X, y + (6.0 if c == keep_tier_bar else 0.0))
		y = c.position.y + (12.0 if c == keep_tier_bar else c.get_combined_minimum_size().y) + 4.0


## The keep view's tier line ("" when hidden), for tests.
func keep_tier_line() -> String:
	return keep_tier.text if keep_tier != null and keep_tier.visible else ""


## Construction site: progress bar and "Under construction 45 %  ·  2 builders (x1.5)".
func _update_site(site: Node3D) -> void:
	var progress := float(site.call("construction_progress")) if site.has_method("construction_progress") else 0.0
	site_progress.value = clampf(progress, 0.0, 1.0)
	var builders := int(site.call("builder_count")) if site.has_method("builder_count") else 0
	var speed := float(site.call("build_speed")) if site.has_method("build_speed") else 0.0
	var pct := floori(progress * 100.0)
	var line := Loc.t("Under construction  %d %%  ·  Paused: right-click it with workers") % pct
	if builders > 0:
		line = Loc.tn("Under construction  {pct} %  ·  {n} builder (x{speed})",
				"Under construction  {pct} %  ·  {n} builders (x{speed})", builders,
				{"pct": pct, "speed": Loc.num(speed, 1)})
	building_info.text = line
	_place_keep_right()


## A keep's tier at the head of its info line while the game has tiers: `Tier 2 Stronghold` or `Upgrading to Citadel
## 40 %` ("" for other buildings or without tiers).
static func keep_tier_text(b: Node) -> String:
	var k := b as Keep
	if k == null or TierSystem.instance() == null:
		return ""
	if k.is_upgrading():
		return Loc.t("Upgrading to %s %d %%") % [Loc.t(TierSystem.tier_name(k.tier + 1)), roundi(k.upgrade_progress() * 100.0)]
	return Loc.t("Tier %d %s") % [k.tier, Loc.t(k.tier_name())]


## One line about a finished building: pop bonus, drop-off, tower stats.
func _building_info_text(type: Variant) -> String:
	if not type is BuildingType:
		return ""
	var t := type as BuildingType
	var parts: Array[String] = []
	if t.pop_bonus > 0:
		parts.append(Loc.t("+%d population") % t.pop_bonus)
	if t.kind == &"keep" or t.kind == &"barracks":
		parts.append(Loc.t("Crystal drop-off"))
	if t.kind == &"tower":
		parts.append(Loc.t("Damage %d · Range %d · Every %s s") % [roundi(t.attack_damage), roundi(t.attack_range),
				Loc.num(t.attack_cooldown, 1)])
	return "  ·  ".join(parts)


## Cancel button of a selected construction site (same as Delete).
func _cancel_site() -> void:
	if selection:
		selection.cancel_site()


func _queue_of(keep: Node) -> Array:
	var q: Variant = keep.get("queue")
	return q if q is Array else []


func _show_view(view: Control) -> void:
	if view == _shown_view:
		return
	_shown_view = view
	for v in [nothing_view, single_view, multi_view, keep_view, champion_view]:
		(v as Control).visible = v == view
	# The new view fades in over 0.1 s (also while the game is paused: a paused tween froze the view nearly invisible).
	if _view_tween:
		_view_tween.kill()
	view.modulate.a = 0.0
	_view_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_view_tween.tween_property(view, "modulate:a", 1.0, 0.1)


# ---------------------------------------------------------------- builders

## The hero tile (ui-sc2-console.md 3.1): every hero_* part placed by hand in the 240 x 100 tile. Statuses and the
## Ember Crown line are kept (tests, logic) in a hidden holder: the wizard's view shows her statuses, the tile's tooltip
## the crown.
func _build_hero_tile() -> HeroTile:
	var tile := HeroTile.new()
	tile.select_requested.connect(_select_hero)
	tile.centre_requested.connect(_centre_hero)
	tile.draw_extra = _draw_ring
	# Faint trim_glow aura (top 60 %) and the 1 px trim line along the top edge.
	_aura = TextureRect.new()
	_aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_aura.stretch_mode = TextureRect.STRETCH_SCALE
	_aura.position = Vector2(1, 1)
	_aura.size = HeroTile.SIZE - Vector2(2, 2)
	_aura.texture = _aura_texture()
	tile.add_child(_aura)
	hero_trim = ColorRect.new()
	hero_trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_trim.position = Vector2(0, 0)
	hero_trim.size = Vector2(HeroTile.SIZE.x, 1)
	hero_trim.color = _trim_color()
	tile.add_child(hero_trim)

	hero_name = Button.new()
	hero_name.flat = true
	hero_name.focus_mode = Control.FOCUS_NONE
	hero_name.alignment = HORIZONTAL_ALIGNMENT_LEFT
	hero_name.text = "Your wizard"
	hero_name.tooltip_text = "Select your wizard  [F1]"
	hero_name.position = HeroTile.NAME_POS
	hero_name.size = Vector2(HeroTile.NAME_WIDTH, 18)
	hero_name.clip_text = true
	hero_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hero_name.add_theme_font_size_override("font_size", 14)   # 15 made the button taller than the 20 px above the HP bar
	_style_hero_name()
	hero_name.mouse_entered.connect(func() -> void: hero_name.queue_redraw())
	hero_name.mouse_exited.connect(func() -> void: hero_name.queue_redraw())
	hero_name.draw.connect(_draw_name_underline)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hero_name.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hero_name.pressed.connect(_select_hero)
	tile.add_child(hero_name)

	var hp := UIStyle.bar(UIStyle.HP_COLOR, HeroTile.HP_RECT.size.y)
	hero_hp = hp[0]
	hero_hp_text = hp[1]
	_tile_bar(tile, hero_hp, hero_hp_text, HeroTile.HP_RECT)
	_ghost = Control.new()   # ghost-damage segment, drawn right of the fill, under the ticks and text
	_ghost.name = "Ghost"
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ghost.draw.connect(_draw_ghost)
	hero_hp.add_child(_ghost)
	hero_hp.move_child(_ghost, 0)
	var mana := UIStyle.bar(UIStyle.MANA_COLOR, HeroTile.MANA_RECT.size.y)
	hero_mana = mana[0]
	hero_mana_text = mana[1]
	_tile_bar(tile, hero_mana, hero_mana_text, HeroTile.MANA_RECT)
	var xp := UIStyle.bar(UIStyle.GOLD, HeroTile.XP_RECT.size.y)
	hero_xp = xp[0]
	hero_xp_text = xp[1]
	hero_xp_text.visible = false   # 6 px: no text (the medallion's tooltip has the XP)
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.2, 0.17, 0.1)
	xp_bg.border_color = Color(0, 0, 0, 0.8)
	xp_bg.set_border_width_all(1)
	xp_bg.set_corner_radius_all(1)
	hero_xp.add_theme_stylebox_override("background", xp_bg)
	_tile_bar(tile, hero_xp, null, HeroTile.XP_RECT)
	_skin_bars.append_array([hero_hp, hero_mana, hero_xp])

	# Level medallion 20 px over the portrait's bottom-right corner.
	hero_badge = Panel.new()
	hero_badge.position = HeroTile.MEDALLION.position
	hero_badge.size = HeroTile.MEDALLION.size
	hero_badge.pivot_offset = HeroTile.MEDALLION.size * 0.5
	hero_badge.mouse_filter = Control.MOUSE_FILTER_STOP   # for its tooltip "Level N · XP x / y · N spell points"
	hero_badge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	hero_badge.draw.connect(_draw_badge)
	hero_level = UIStyle.display_label("1", 12, UIStyle.GOLD)
	hero_level.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_badge.add_child(hero_level)
	tile.add_child(hero_badge)

	# "Vessa returns in 24 s" over the empty HP bar while she is dead (the bar's own text hides).
	hero_status = UIStyle.panel_label("", 11, UIStyle.WARN)
	hero_status.position = HeroTile.HP_RECT.position + Vector2(0, -2)
	hero_status.size = Vector2(HeroTile.HP_RECT.size.x, 16)
	hero_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_status.clip_text = true
	hero_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hero_status.add_theme_constant_override("outline_size", 3)
	hero_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_status.visible = false
	tile.add_child(hero_status)

	points_chip = PanelContainer.new()
	points_chip.position = HeroTile.POINTS_RECT.position
	points_chip.size = HeroTile.POINTS_RECT.size
	points_chip.custom_minimum_size = HeroTile.POINTS_RECT.size
	points_chip.tooltip_text = Loc.t("Learn a spell: click + on a spell, or Ctrl+%s / Ctrl+%s / Ctrl+%s") % [
			KeyLabels.of(KEY_F), KeyLabels.of(KEY_Q), KeyLabels.of(KEY_E)]   # keyboard labels (UX.1)
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = UIStyle.GOLD
	chip_style.set_corner_radius_all(3)
	points_chip.add_theme_stylebox_override("panel", chip_style)
	points_text = Label.new()
	points_text.add_theme_font_size_override("font_size", 11)
	points_text.add_theme_color_override("font_color", Color.BLACK)
	points_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_chip.add_child(points_text)
	points_chip.visible = false
	tile.add_child(points_chip)

	_hero_hidden = Control.new()
	_hero_hidden.name = "HiddenParts"
	_hero_hidden.visible = false
	_hero_hidden.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(_hero_hidden)
	hero_statuses = _build_status_row()   # statuses end on death, so never shown with the countdown
	_hero_hidden.add_child(hero_statuses)
	hero_crown = UIStyle.label("", 14)
	hero_crown.add_theme_color_override("font_color", UIStyle.GOLD)
	hero_crown.tooltip_text = "Dropped when your wizard dies."
	hero_crown.visible = false
	_hero_hidden.add_child(hero_crown)
	return tile


## A tile bar at `r`; `text` (its centred label) in font 10 with a 2 px outline.
func _tile_bar(tile: Control, b: ProgressBar, text: Label, r: Rect2) -> void:
	b.position = r.position
	b.size = r.size
	b.custom_minimum_size = r.size
	if text != null:
		text.add_theme_font_size_override("font_size", 10)
		text.add_theme_constant_override("outline_size", 2)
	tile.add_child(b)


## Double-click on the hero tile: centre the camera on the wizard (Space does the same).
func _centre_hero() -> void:
	if selection and hero and is_instance_valid(hero):
		selection.centre_camera_on([hero])


## [row, text column]: the view's texts from the block's content left edge (the portrait is in the portrait window).
func _portrait_row(outer: VBoxContainer) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	outer.add_child(row)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	return [row, box]


func _build_single_view() -> VBoxContainer:
	var outer := VBoxContainer.new()
	var parts := _portrait_row(outer)
	var box: VBoxContainer = parts[1]
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.custom_minimum_size = Vector2(LEFT_COLUMN, 0)
	single_view = outer
	# Name row: the name (Cinzel 20) + an epic beast's subtitle (` · Epic beast` + the variant word in GOLD, font 14).
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 0)
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_row)
	single_name = UIStyle.display_label("", 20)
	_title_labels.append(single_name)
	name_row.add_child(single_name)
	single_name_suffix = UIStyle.panel_label("", 14)
	single_name_suffix.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	single_name_suffix.visible = false
	name_row.add_child(single_name_suffix)
	single_name_variant = UIStyle.panel_label("", 14, UIStyle.GOLD)
	single_name_variant.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	single_name_variant.visible = false
	name_row.add_child(single_name_variant)
	var hp := UIStyle.bar(UIStyle.HP_COLOR, 20.0)
	single_hp = hp[0]
	single_hp_text = hp[1]
	single_hp.custom_minimum_size = Vector2(300, 20)
	single_hp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(single_hp)
	var mana := UIStyle.bar(UIStyle.MANA_COLOR, 20.0)
	single_mana = mana[0]
	single_mana_text = mana[1]
	single_mana.custom_minimum_size = Vector2(300, 20)
	single_mana.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(single_mana)
	stat_table = _build_stat_table()
	box.add_child(stat_table)
	single_stats_row = HBoxContainer.new()
	single_stats_row.add_theme_constant_override("separation", 0)
	single_stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(single_stats_row)
	single_stats = UIStyle.panel_label("", 14)
	single_stats_row.add_child(single_stats)
	single_stats_extra = UIStyle.panel_label("", 14, GOLD_TEXT)   # a Magpie's " · Carrying 60 gold"
	single_stats_extra.visible = false
	single_stats_row.add_child(single_stats_extra)
	# Caravans (ui-trade.md 6.2): (coin) "Cargo 119 gold" + " · Route: " + "Saltgate" + " (far)", font 14.
	cargo_row = HBoxContainer.new()
	cargo_row.add_theme_constant_override("separation", 0)
	cargo_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cargo_row.visible = false
	single_stats_row.add_child(cargo_row)
	cargo_coin = Control.new()
	cargo_coin.custom_minimum_size = Vector2(16, 12)
	cargo_coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cargo_coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cargo_coin.draw.connect(func() -> void: draw_coin(cargo_coin, Vector2(6, 6), 6.0))
	cargo_row.add_child(cargo_coin)
	for i in 4:
		var l := UIStyle.panel_label("", 14)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cargo_row.add_child(l)
		cargo_labels.append(l)
	single_state = UIStyle.panel_label("", 14)
	single_state.visible = false
	box.add_child(single_state)
	# Map fill (ui-mapfill.md 5.1 / 6.2): two font-13 rows under the stat line (camp + reward, or drops + lair).
	for i in 2:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.visible = false
		box.add_child(row)
		single_extra_rows.append(row)
	# Summons (Saplings, 8.U1): lifetime bar "Withers in 18 s", drains from full to empty.
	var life := UIStyle.bar(LIFETIME_COLOR, 16.0)
	single_lifetime = life[0]
	single_lifetime_text = life[1]
	single_lifetime_text.add_theme_font_size_override("font_size", 12)
	single_lifetime.custom_minimum_size = Vector2(300, 16)
	single_lifetime.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	single_lifetime.tooltip_text = "Summoned: withers when the time runs out."
	single_lifetime.mouse_filter = Control.MOUSE_FILTER_STOP
	single_lifetime.visible = false
	box.add_child(single_lifetime)
	single_right = _build_single_right()
	(parts[0] as HBoxContainer).add_child(single_right)
	single_statuses = _build_status_row()
	single_right.add_child(single_statuses)
	single_right.add_child(single_learn_row)
	_skin_bars.append_array([single_hp, single_mana, single_lifetime])
	return outer


## The 2 x 2 stat table (4.2): per cell a 12 px glyph (muted), the word (muted) and the number (text), font 14.
func _build_stat_table() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "StatTable"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 0)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in STAT_IDS.size():
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 5)
		cell.custom_minimum_size = Vector2(140, 0)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var glyph := Control.new()
		glyph.custom_minimum_size = Vector2(12, 12)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var id := STAT_IDS[i]
		glyph.draw.connect(func() -> void: draw_stat_glyph(glyph, id, UIStyle.token(&"text_muted")))
		cell.add_child(glyph)
		var word := UIStyle.panel_label(STAT_WORDS[i], 14)
		_muted_labels.append(word)
		cell.add_child(word)
		var value := UIStyle.number_label("", 14)
		value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		cell.add_child(value)
		stat_values.append(value)
		grid.add_child(cell)
	grid.visible = false
	return grid


## The stat glyphs (12 px): damage = a blade, armor = a shield, range = an arrow, speed = a boot chevron.
static func draw_stat_glyph(ci: CanvasItem, id: StringName, col: Color) -> void:
	match id:
		&"damage":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(12, 2), Vector2(4, 10), Vector2(2, 8)]), col)
			ci.draw_line(Vector2(1, 6), Vector2(6, 11), col, 1.5)
		&"armor":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(1, 1), Vector2(11, 1), Vector2(11, 6), Vector2(6, 11),
					Vector2(1, 6)]), col)
		&"range":
			ci.draw_line(Vector2(1, 11), Vector2(10, 2), col, 1.5)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(11, 1), Vector2(11, 6), Vector2(6, 1)]), col)
		_:
			for k in 2:
				var x := 1.0 + 5.0 * k
				ci.draw_polyline(PackedVector2Array([Vector2(x, 2), Vector2(x + 4, 6), Vector2(x, 10)]), col, 2.0)


## The single view's right part (4.2): level medallion 28 + `Level 3` / `Veteran` (Cinzel 16), the XP bar 240 x 12
## (`XP 320 / 450`), then (added by the caller) the status chips and the wizard's learn row.
func _build_single_right() -> VBoxContainer:
	var right := VBoxContainer.new()
	right.name = "RightPart"
	right.add_theme_constant_override("separation", 4)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	single_level_row = HBoxContainer.new()
	single_level_row.add_theme_constant_override("separation", 8)
	single_level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(single_level_row)
	single_badge = Panel.new()
	single_badge.custom_minimum_size = Vector2(28, 28)
	single_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	single_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	single_badge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	single_badge.draw.connect(func() -> void:
		ChampionBar.draw_hex_badge(single_badge, Vector2(14, 14), 13.0, UIStyle.GOLD))
	single_badge_label = UIStyle.display_label("1", 14, UIStyle.GOLD)
	single_badge_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	single_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	single_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	single_badge_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	single_badge.add_child(single_badge_label)
	single_level_row.add_child(single_badge)
	single_level_text = UIStyle.display_label("", 16)
	single_level_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title_labels.append(single_level_text)
	single_level_row.add_child(single_level_text)
	var xp := UIStyle.bar(UIStyle.GOLD, 12.0)
	single_xp = xp[0]
	single_xp_text = xp[1]
	single_xp_text.add_theme_font_size_override("font_size", 10)
	single_xp_text.add_theme_constant_override("outline_size", 2)
	single_xp.custom_minimum_size = Vector2(240, 12)
	single_xp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.2, 0.17, 0.1)
	xp_bg.border_color = Color(0, 0, 0, 0.8)
	xp_bg.set_border_width_all(1)
	xp_bg.set_corner_radius_all(2)
	single_xp.add_theme_stylebox_override("background", xp_bg)
	right.add_child(single_xp)
	single_learn_row = HBoxContainer.new()
	single_learn_row.add_theme_constant_override("separation", 8)
	single_learn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	single_points = Label.new()
	single_points.add_theme_font_size_override("font_size", 11)
	single_points.add_theme_color_override("font_color", Color.BLACK)
	var chip := StyleBoxFlat.new()
	chip.bg_color = UIStyle.GOLD
	chip.set_corner_radius_all(3)
	chip.content_margin_left = 6
	chip.content_margin_right = 6
	single_points.add_theme_stylebox_override("normal", chip)
	single_points.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	single_learn_row.add_child(single_points)
	single_learn_hint = UIStyle.panel_label("", 12)
	single_learn_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_muted_labels.append(single_learn_hint)
	single_learn_row.add_child(single_learn_hint)
	single_learn_row.visible = false
	return right


## The Bazaar block (ui-trade.md 5.2): 264 x 100 at (1000, 676), five lines at y 676 / 696 / 716 / 736 (font 13) and
## 756 (font 12), clipped with an ellipsis; mouse-transparent.
func _build_market_block() -> Control:
	var block := Control.new()
	block.name = "MarketBlock"
	block.position = MARKET_BLOCK_POS
	block.size = MARKET_BLOCK_SIZE
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.visible = false
	market_route_row = HBoxContainer.new()
	market_route_row.position = Vector2(0, 0)
	market_route_row.size = Vector2(MARKET_BLOCK_SIZE.x, 18)
	market_route_row.clip_contents = true
	market_route_row.add_theme_constant_override("separation", 0)
	market_route_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(market_route_row)
	for i in 3:
		var l := UIStyle.panel_label("", 13)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		market_route_row.add_child(l)
		market_route_labels.append(l)
	market_value = _block_line(block, 20.0, 13)
	market_caravans = _block_line(block, 40.0, 13)
	market_traded = _block_line(block, 60.0, 13)
	market_wares_row = HBoxContainer.new()
	market_wares_row.position = Vector2(0, 80)
	market_wares_row.size = Vector2(MARKET_BLOCK_SIZE.x, 18)
	market_wares_row.add_theme_constant_override("separation", 0)
	market_wares_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(market_wares_row)
	market_wares = UIStyle.panel_label("", 12)
	market_wares.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_muted_labels.append(market_wares)
	market_wares_row.add_child(market_wares)
	market_wares_badge = UIStyle.panel_label("U", 12, Color.BLACK)
	var badge := StyleBoxFlat.new()
	badge.bg_color = UIStyle.GOLD
	badge.set_corner_radius_all(2)
	market_wares_badge.add_theme_stylebox_override("normal", badge)
	market_wares_badge.custom_minimum_size = Vector2(18, 14)
	market_wares_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	market_wares_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	market_wares_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	market_wares_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	market_wares_row.add_child(market_wares_badge)
	return block


func _block_line(block: Control, y: float, font_size: int) -> Label:
	var l := UIStyle.panel_label("", font_size)
	l.position = Vector2(0, y)
	l.size = Vector2(MARKET_BLOCK_SIZE.x, 18)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(l)
	return l


## The epic-beast ability block (ui-mapfill.md 6.2): 3 slots 48 x 48 at (1000 + 58 j, 676) with names (font 11,
## muted, 54 wide, ellipsis) at y 728; tooltips only.
func _build_beast_block() -> Control:
	var block := Control.new()
	block.name = "BeastBlock"
	block.position = BEAST_BLOCK_POS
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.visible = false
	for j in 3:
		var slot := BeastAbilitySlot.new()
		slot.position = Vector2(BEAST_SLOT_STEP * j, 0)
		block.add_child(slot)
		beast_slots.append(slot)
		var n := UIStyle.panel_label("", 11)
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		n.position = Vector2(BEAST_SLOT_STEP * j, 52)
		n.size = Vector2(54, 14)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_muted_labels.append(n)
		block.add_child(n)
		beast_slot_names.append(n)
	return block


## Champion view (ui-champions.md 4), a plain Control over the selection block (252, 696; ui-sc2-console.md 4.2: the
## portrait is in the portrait window now, so the texts start at x 0): name row (0, 0); HP 280 x 22 (0, 30); XP 280 x 14
## (0, 56); stats (0, 74); intent + purse (0, 94); status chips (0, 116); items 36 at (40 i, 156). Step 11
## (ui-champions.md 15.3): the name row is 392 wide (name + title + class); the stat / intent rows stop at x 392; the
## ability block: captions 156 x 12 at (408, 0) / (408, 82), row 1 slots 48 at (408 + 54 j, 14) + names y 64, row 2 at
## (408 + 54 j, 96) + names y 146, autocast line (408, 164).
func _build_champion_view() -> Control:
	var view := Control.new()
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE   # children placed by hand; no minimum size (the area keeps its width)
	var name_row := HBoxContainer.new()
	name_row.position = Vector2(CH_TEXT_X, 0)
	name_row.size = Vector2(392, 24)
	name_row.add_theme_constant_override("separation", 0)
	name_row.clip_contents = true
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(name_row)
	champion_name = UIStyle.display_label("", 20)
	_title_labels.append(champion_name)
	name_row.add_child(champion_name)
	champion_title = UIStyle.panel_label("", 13)
	champion_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(champion_title)
	champion_class_label = ChampionBar.TipLabel.new()
	champion_class_label.add_theme_font_size_override("font_size", 13)
	champion_class_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Takes what is left of the 392 px (no minimum width, so the row never grows past 392): ellipsis if too long.
	champion_class_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	champion_class_label.clip_text = true
	champion_class_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	champion_class_label.mouse_filter = Control.MOUSE_FILTER_STOP
	name_row.add_child(champion_class_label)
	var hp := UIStyle.bar(UIStyle.HP_COLOR)
	champion_hp = hp[0]
	champion_hp_text = hp[1]
	champion_hp.position = Vector2(CH_TEXT_X, 30)
	champion_hp.size = Vector2(280, 22)
	view.add_child(champion_hp)
	var xp := UIStyle.bar(UIStyle.GOLD, 14.0)
	champion_xp = xp[0]
	champion_xp_text = xp[1]
	champion_xp_text.add_theme_font_size_override("font_size", 11)
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.2, 0.17, 0.1)
	xp_bg.border_color = Color(0, 0, 0, 0.8)
	xp_bg.set_border_width_all(1)
	xp_bg.set_corner_radius_all(2)
	champion_xp.add_theme_stylebox_override("background", xp_bg)
	champion_xp.position = Vector2(CH_TEXT_X, 56)
	champion_xp.size = Vector2(280, 14)
	view.add_child(champion_xp)
	_skin_bars.append(champion_hp)
	champion_stats = UIStyle.panel_label("", 14)
	champion_stats.clip_text = true   # before the size: a long line would widen the label into the ability block
	champion_stats.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	champion_stats.position = Vector2(CH_TEXT_X, 74)
	champion_stats.size = Vector2(392, 20)
	view.add_child(champion_stats)
	var intent_row := HBoxContainer.new()
	intent_row.position = Vector2(CH_TEXT_X, 94)
	intent_row.size = Vector2(392, 20)
	intent_row.add_theme_constant_override("separation", 0)
	intent_row.clip_contents = true
	intent_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(intent_row)
	champion_intent = UIStyle.panel_label("", 14)
	champion_intent.clip_text = true   # max width 260 (set with the text), then the purse
	champion_intent.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	intent_row.add_child(champion_intent)
	champion_purse_box = HBoxContainer.new()
	champion_purse_box.add_theme_constant_override("separation", 3)
	champion_purse_box.mouse_filter = Control.MOUSE_FILTER_STOP
	champion_purse_box.tooltip_text = "Its own essence: bounties and loot. It buys its own items."
	intent_row.add_child(champion_purse_box)
	var purse_word := UIStyle.panel_label("  ·  Purse ", 14)
	_muted_labels.append(purse_word)
	champion_purse_box.add_child(purse_word)
	var flame := Control.new()
	flame.custom_minimum_size = Vector2(10, 12)
	flame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flame.draw.connect(func() -> void: ChampionBar.draw_flame(flame, Vector2.ZERO, 12.0))
	champion_purse_box.add_child(flame)
	champion_purse = UIStyle.number_label("", 14, UIStyle.ESSENCE_TEXT)
	champion_purse_box.add_child(champion_purse)
	champion_statuses = _build_status_row()
	champion_statuses.position = Vector2(CH_TEXT_X, 116)
	view.add_child(champion_statuses)
	for i in 4:
		var slot := ChampionBar.ItemIcon.make(null, 36.0)
		slot.position = Vector2(CH_TEXT_X + 40 * i, 156)
		view.add_child(slot)
		champion_items.append(slot)
	# Ability block x 408-564 (660-816 on screen): row 1 = archetype, row 2 = class (ui-champions.md 15.3).
	champion_row1_caption = _champion_caption(Vector2(CH_ABILITY_X, 0))
	_muted_labels.append(champion_row1_caption)
	view.add_child(champion_row1_caption)
	champion_row2_caption = _champion_caption(Vector2(CH_ABILITY_X, 82))
	champion_row2_caption.mouse_filter = Control.MOUSE_FILTER_STOP
	view.add_child(champion_row2_caption)
	for k in 6:
		var row := 1 if k >= 3 else 0
		var j := k % 3
		var a := AbilitySlot.new()
		a.position = Vector2(CH_ABILITY_X + 54 * j, 14 + 82 * row)
		view.add_child(a)
		champion_abilities.append(a)
		var n := UIStyle.panel_label("", 11)
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		n.position = Vector2(CH_ABILITY_X + 54 * j, 64 + 82 * row)
		n.size = Vector2(50, 14)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_muted_labels.append(n)
		view.add_child(n)
		champion_ability_names.append(n)
	champion_autocast = UIStyle.panel_label("Autocast", 11)
	champion_autocast.clip_text = true
	champion_autocast.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	champion_autocast.position = Vector2(CH_ABILITY_X, 164)
	champion_autocast.size = Vector2(156, 14)
	_muted_labels.append(champion_autocast)
	view.add_child(champion_autocast)
	view.visible = false
	return view


## A 156 x 12 caption of the champion ability block (font 10).
func _champion_caption(at: Vector2) -> Label:
	var l := ChampionBar.TipLabel.new()
	l.add_theme_font_size_override("font_size", 10)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.position = at
	l.size = Vector2(156, 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## One ability slot of the champion view (48 x 48): slot frame, icon 40 inset 4 or the abbreviation, the radial
## cooldown sweep + seconds (own champions), the ready flash, `L4` badge + alpha 0.45 while locked. Tooltip only.
class AbilitySlot extends Panel:
	var ability_id: StringName = &""
	var ratio := 0.0              ## Remaining cooldown fraction (0 = ready).
	var icon: TextureRect
	var abbrev: Label
	var seconds: Label
	var badge: PanelContainer
	var question: Label           ## The `?` of a class skill not chosen yet.
	var placeholder := false      ## True while it shows a `?` (show_placeholder).
	var _sweep: Control
	var _was_cooling := false
	var _flash_left := 0.0
	var _cd_total := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(48, 48)
		size = Vector2(48, 48)
		pivot_offset = Vector2(24, 24)
		mouse_filter = Control.MOUSE_FILTER_STOP
		icon = TextureRect.new()
		icon.position = Vector2(4, 4)
		icon.size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)
		abbrev = UIStyle.panel_label("", 14)
		abbrev.set_anchors_preset(Control.PRESET_FULL_RECT)
		abbrev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		abbrev.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		abbrev.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(abbrev)
		_sweep = Control.new()
		_sweep.set_anchors_preset(Control.PRESET_FULL_RECT)
		_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sweep.draw.connect(func() -> void:
			ItemTooltip.HudSkin.draw_sweep(_sweep, Rect2(Vector2(3, 3), size - Vector2(6, 6)), ratio))
		add_child(_sweep)
		seconds = UIStyle.label("", 14)
		seconds.set_anchors_preset(Control.PRESET_FULL_RECT)
		seconds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seconds.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seconds.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(seconds)
		badge = PanelContainer.new()
		badge.position = Vector2(26, 32)
		badge.custom_minimum_size = Vector2(20, 14)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0, 0, 0, 0.75)
		bs.set_corner_radius_all(2)
		badge.add_theme_stylebox_override("panel", bs)
		var bl := UIStyle.panel_label("L4", 10, UIStyle.GOLD)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(bl)
		badge.visible = false
		add_child(badge)
		question = UIStyle.display_label("?", 18)
		question.set_anchors_preset(Control.PRESET_FULL_RECT)
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question.mouse_filter = Control.MOUSE_FILTER_IGNORE
		question.visible = false
		add_child(question)
		apply_skin()

	func apply_skin() -> void:
		add_theme_stylebox_override("panel", UIStyle.button_frame(&"normal"))
		if question != null:
			question.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))

	## A class skill not chosen yet (ui-champions.md 15.3): a `?` Cinzel 18 `text_muted`, alpha 0.45, badge `L<n>`.
	func show_placeholder(unlock_level: int) -> void:
		placeholder = true
		ability_id = &""
		icon.texture = null
		abbrev.text = ""
		question.visible = true
		seconds.text = ""
		ratio = 0.0
		_cd_total = 0.0
		_was_cooling = false
		modulate.a = 0.45
		badge.visible = true
		(badge.get_child(0) as Label).text = "L%d" % unlock_level
		_sweep.queue_redraw()

	## U2-6: forgets the cooldown state (another champion is shown): no ready flash on the next update.
	func reset_cooling() -> void:
		_was_cooling = false
		_cd_total = 0.0
		ability_id = &""

	## Pop 1.0 -> 1.08 -> 1.0 in 0.2 s after `delay` seconds (class chosen: the `?` swap to the class skills).
	func pop(delay := 0.0) -> void:
		var t := create_tween()
		if delay > 0.0:
			t.tween_interval(delay)
		t.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
		t.tween_property(self, "scale", Vector2.ONE, 0.1)

	## The ready flash, on demand (the first class skill when the class is chosen).
	func play_ready_flash() -> void:
		_ready_flash()

	## `left` seconds of cooldown out of `total` (0 = ready, no sweep); locked = alpha 0.45 + the `L4` badge.
	func show_ability(id: StringName, unlocked: bool, left: float, total: float, unlock_level: int) -> void:
		if placeholder:
			placeholder = false
			question.visible = false
			ability_id = &""
		if id != ability_id:
			ability_id = id
			icon.texture = SelectionPanel.ability_icon(id)
			abbrev.text = "" if icon.texture != null else UIStyle.abbrev(str(ChampionBar.ability_info(id).get("name", "")))
			_cd_total = 0.0
		if left > 0.0:
			_cd_total = maxf(maxf(_cd_total, total), left)
			ratio = clampf(left / _cd_total, 0.0, 1.0)
		else:
			ratio = 0.0
			_cd_total = 0.0
		seconds.text = str(ceili(left)) if left > 0.0 else ""
		if _was_cooling and left <= 0.0:
			_ready_flash()
		_was_cooling = left > 0.0
		modulate.a = 1.0 if unlocked else 0.45
		badge.visible = not unlocked
		(badge.get_child(0) as Label).text = "L%d" % unlock_level
		_sweep.queue_redraw()

	## Ready flash (ui-style.md 6.2): the rim flashes trim_glow and the slot pops 1.0 -> 1.08 -> 1.0.
	func _ready_flash() -> void:
		add_theme_stylebox_override("panel", UIStyle.button_frame(&"normal", UIStyle.token(&"trim_glow")))
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
		t.tween_property(self, "scale", Vector2.ONE, 0.1)
		t.tween_callback(apply_skin).set_delay(0.05)

	func _make_custom_tooltip(for_text: String) -> Object:
		return ChampionBar.styled_tooltip(for_text)


## An epic beast's ability slot (ui-mapfill.md 6.2): the champion slot look with the radial cooldown sweep (beasts are
## PvE, so their timers show), no seconds, no ready flash, no lock badge.
class BeastAbilitySlot extends AbilitySlot:
	func show_beast_ability(id: StringName, abbr: String, left: float, total: float) -> void:
		show_ability(id, true, left, total, 1)
		if icon.texture == null:
			abbrev.text = abbr
		seconds.text = ""

	func _ready_flash() -> void:
		pass   # no ready flash on beasts


## Ability icon: `art/icons/abilities/<id>.png` (new icon kind), else null (the abbreviation shows).
static func ability_icon(id: StringName) -> Texture2D:
	return IconLibrary.icon_for(&"abilities", id)


## Every status the panel can mark: Unit.STATUSES plus the Ice / Nature ones of kingdom-ice.md 2.1
## (listed even before the unit script knows them, so the chips exist as soon as gameplay applies them).
static func status_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in Unit.STATUSES:
		out.append(id)
	for id: StringName in STATUS_COLORS:
		if not out.has(id):
			out.append(id)
	return out


## The mark colour of a status: STATUS_COLORS (chill / frozen / rooted) first, else Unit.STATUSES.
static func status_color(id: StringName) -> Color:
	if STATUS_COLORS.has(id):
		return STATUS_COLORS[id]
	if Unit.STATUSES.has(id) and (Unit.STATUSES[id] as Dictionary).has("color"):
		return Unit.STATUSES[id]["color"]
	return Color(0.8, 0.8, 0.8)


## A row with one hidden chip per status of status_ids() (chip name = status id).
func _build_status_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for id: StringName in status_ids():
		var color := status_color(id)
		var chip := PanelContainer.new()
		chip.name = String(id)
		chip.custom_minimum_size = Vector2(40, 20)
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		var style := UIStyle.slate_style(0.0, color)   # slate chip, 1 px border in the status colour
		style.content_margin_left = 4.0
		style.content_margin_right = 4.0
		chip.add_theme_stylebox_override("panel", style)
		var text := UIStyle.panel_label("", 12, color.lightened(0.2))
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(text)
		chip.visible = false
		row.add_child(chip)
	_add_mapfill_chips(row)
	row.visible = false
	return row


func _build_multi_view() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	# Row 1 (y 696): the type tabs, 24 tall, and `9 selected` right-aligned.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	head.custom_minimum_size = Vector2(0, 24)
	box.add_child(head)
	for i in TYPE_TABS:
		var t := Button.new()
		t.custom_minimum_size = Vector2(46, 24)
		t.focus_mode = Control.FOCUS_NONE
		t.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		t.add_theme_font_size_override("font_size", 12)
		UIStyle.style_button(t)
		var face := TextureRect.new()   # the type's 20 px icon (a child: the count stays the button's own text)
		face.name = "Face"
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.position = Vector2(3, 2)
		face.size = Vector2(20, 20)
		t.add_child(face)
		t.visible = false
		t.pressed.connect(_on_type_tab_pressed.bind(i))
		head.add_child(t)
		type_tabs.append(t)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(spacer)
	multi_header = UIStyle.panel_label("", 13)
	multi_header.mouse_filter = Control.MOUSE_FILTER_STOP   # its tooltip lists the types
	multi_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_muted_labels.append(multi_header)
	head.add_child(multi_header)
	# The icons (y 728): 40 x 40, gap 4, 16 per row x 3 rows; "+ 12 more" under them.
	var grid := GridContainer.new()
	grid.columns = ICONS_PER_ROW
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	for i in MAX_ICONS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 12)
		UIStyle.style_button(b)
		b.pressed.connect(_on_icon_pressed.bind(i))
		var face := TextureRect.new()   # the unit's icon (art/icons/units), else the button shows its abbreviation
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.position = Vector2(3, 3)
		face.size = Vector2(ICON_SIZE - 6.0, ICON_SIZE - 6.0)
		b.add_child(face)
		_icon_faces.append(face)
		var strip := ColorRect.new()   # 3 px HP strip inside the frame bottom
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.position = Vector2(0, ICON_SIZE - 3.0)
		strip.size = Vector2(ICON_SIZE, 3)
		b.add_child(strip)
		var mstrip := ColorRect.new()   # caster 2 px mana strip, just above the HP strip
		mstrip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mstrip.color = UIStyle.MANA_COLOR
		mstrip.position = Vector2(0, ICON_SIZE - 5.0)
		mstrip.size = Vector2(ICON_SIZE, 2)
		mstrip.visible = false
		b.add_child(mstrip)
		_icon_mana_strips.append(mstrip)
		var dots: Array[ColorRect] = []
		for j in 3:
			var dot := ColorRect.new()
			dot.color = UIStyle.GOLD
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.position = Vector2(ICON_SIZE - 5.0 - j * 4.0, 2.0)
			dot.size = Vector2(3, 3)
			dot.visible = false
			b.add_child(dot)
			dots.append(dot)
		_icon_dots.append(dots)
		var status_dots := {}
		var k := 0
		for id: StringName in status_ids():
			var sdot := ColorRect.new()
			sdot.color = status_color(id)
			sdot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sdot.position = Vector2(3.0 + (k % 6) * 6.0, ICON_SIZE - 11.0)
			sdot.size = Vector2(5, 5)
			sdot.visible = false
			b.add_child(sdot)
			status_dots[id] = sdot
			k += 1
		_icon_status_dots.append(status_dots)
		# A loaded caravan: a 6 px gold coin at the bottom-right corner (inset 3), above the HP strip.
		var coin := Control.new()
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.position = Vector2(ICON_SIZE - 9.0, ICON_SIZE - 12.0)
		coin.size = Vector2(6, 6)
		coin.draw.connect(func() -> void: draw_coin(coin, Vector2(3, 3), 3.0))
		coin.visible = false
		b.add_child(coin)
		_icon_coins.append(coin)
		grid.add_child(b)
		icons.append(b)
		_icon_strips.append(strip)
	multi_more = UIStyle.panel_label("", 12, UIStyle.GOLD)
	multi_more.visible = false
	box.add_child(multi_more)
	return box


## The building view (4.2), placed by hand from the block's content top-left (252, 696): name (0, 0) Cinzel 20, HP bar
## 300 x 20 at (0, 28); a site: progress 300 x 14 at (0, 28) + `Cancel  [Delete]` 150 x 32 at (0, 52); a trainer: the
## queue, 5 slots 44 x 44 at (0, 80) gap 4, slot 1's progress 44 x 6 under it. Right part from x 328 (580 on screen):
## the keep's tier line + bar, `Rally: set`, the info line, the queue count.
func _build_keep_view() -> Control:
	var view := Control.new()
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keep_name = UIStyle.display_label("Keep", 20)
	_title_labels.append(keep_name)
	keep_name.position = Vector2(0, -2)
	keep_name.size = Vector2(LEFT_COLUMN, 26)
	keep_name.clip_text = true
	keep_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	view.add_child(keep_name)
	var hp := UIStyle.bar(UIStyle.HP_COLOR, 20.0)
	keep_hp = hp[0]
	keep_hp_text = hp[1]
	keep_hp.position = Vector2(0, 28)
	keep_hp.size = Vector2(300, 20)
	view.add_child(keep_hp)
	_skin_bars.append(keep_hp)

	# Construction site: progress bar + Cancel (Delete).
	site_row = Control.new()
	site_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	site_row.position = Vector2.ZERO
	site_row.size = Vector2(LEFT_COLUMN, 90)
	view.add_child(site_row)
	site_progress = ProgressBar.new()
	site_progress.show_percentage = false
	site_progress.max_value = 1.0
	site_progress.step = 0.0
	site_progress.position = Vector2(0, 28)
	site_progress.size = Vector2(300, 14)
	site_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var site_bg := StyleBoxFlat.new()
	site_bg.bg_color = Color(0.12, 0.12, 0.14)
	var site_fill := StyleBoxFlat.new()
	site_fill.bg_color = PROGRESS_COLOR
	site_progress.add_theme_stylebox_override("background", site_bg)
	site_progress.add_theme_stylebox_override("fill", site_fill)
	site_row.add_child(site_progress)
	site_cancel = Button.new()
	site_cancel.text = "Cancel  [Delete]"
	site_cancel.tooltip_text = "Stop building. Refunds 75 % of the cost."
	site_cancel.focus_mode = Control.FOCUS_NONE
	site_cancel.position = Vector2(0, 52)
	site_cancel.size = Vector2(150, 32)
	site_cancel.custom_minimum_size = Vector2(150, 32)
	site_cancel.add_theme_font_size_override("font_size", 14)
	UIStyle.style_button(site_cancel, UIStyle.WARN)
	site_cancel.pressed.connect(_cancel_site)
	site_row.add_child(site_cancel)
	site_row.visible = false

	var queue_row := Control.new()
	queue_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_row.position = Vector2(0, 80)
	queue_row.size = Vector2(QUEUE_SLOTS * (QUEUE_SLOT + 4.0), QUEUE_SLOT + 8.0)
	view.add_child(queue_row)
	_queue_row = queue_row
	for i in QUEUE_SLOTS:
		var b := Button.new()
		b.position = Vector2(i * (QUEUE_SLOT + 4.0), 0)
		b.size = Vector2(QUEUE_SLOT, QUEUE_SLOT)
		b.custom_minimum_size = Vector2(QUEUE_SLOT, QUEUE_SLOT)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 11)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # the name fallback: "Cinder / Hand" on 2 lines
		b.clip_text = true
		UIStyle.style_button(b)
		_skin_buttons.append(b)
		b.pressed.connect(cancel_slot.bind(i))
		queue_row.add_child(b)
		queue_buttons.append(b)
		var x := UIStyle.panel_label("x", 12, UIStyle.WARN)   # hover: click cancels
		x.mouse_filter = Control.MOUSE_FILTER_IGNORE
		x.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		x.add_theme_constant_override("outline_size", 3)
		x.position = Vector2(QUEUE_SLOT - 11.0, -2.0)
		x.visible = false
		b.add_child(x)
		_queue_x.append(x)
		if i == 0:
			queue_progress = ProgressBar.new()
			queue_progress.show_percentage = false
			queue_progress.max_value = 1.0
			queue_progress.step = 0.0
			queue_progress.position = Vector2(0, QUEUE_SLOT + 2.0)
			queue_progress.size = Vector2(QUEUE_SLOT, 6)
			queue_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bg := StyleBoxFlat.new()
			bg.bg_color = Color(0.12, 0.12, 0.14)
			var fill := StyleBoxFlat.new()
			fill.bg_color = PROGRESS_COLOR
			queue_progress.add_theme_stylebox_override("background", bg)
			queue_progress.add_theme_stylebox_override("fill", fill)
			queue_row.add_child(queue_progress)

	# Right part (x 328): tier line (+ bar), rally, info, queue count; placed by _place_keep_right().
	keep_tier = UIStyle.panel_label("", 13)
	keep_tier.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	keep_tier.visible = false
	view.add_child(keep_tier)
	var tb := UIStyle.bar(UIStyle.GOLD, 12.0)
	keep_tier_bar = tb[0]
	keep_tier_bar.max_value = 1.0
	keep_tier_bar.size = Vector2(240, 12)
	keep_tier_bar.visible = false
	view.add_child(keep_tier_bar)
	rally_label = UIStyle.panel_label("Rally: set", 13)
	_muted_labels.append(rally_label)
	view.add_child(rally_label)
	building_info = UIStyle.panel_label("", 13)
	building_info.size = Vector2(260, 0)
	_muted_labels.append(building_info)
	view.add_child(building_info)
	queue_count = UIStyle.panel_label("Nothing in training", 13)
	queue_count.name = "QueueCount"
	view.add_child(queue_count)
	for c: Control in [keep_tier, rally_label, building_info, queue_count]:
		c.position = Vector2(KEEP_RIGHT_X, 0)
	view.visible = false
	return view


func _select_hero() -> void:
	if selection and hero and is_instance_valid(hero) and hero.is_alive():
		selection.select_units([hero])


## Click an icon = select that unit; Shift+click = remove it from the selection (4.2).
func _on_icon_pressed(index: int) -> void:
	if selection == null or index >= _icon_units.size() or not is_instance_valid(_icon_units[index]):
		return
	if Input.is_key_pressed(KEY_SHIFT):
		var rest: Array = selection.orderable_units().duplicate()
		rest.erase(_icon_units[index])
		selection.select_units(rest)
	else:
		selection.select_units([_icon_units[index]])


## Click a type tab = only that type stays selected.
func _on_type_tab_pressed(index: int) -> void:
	if selection == null or index >= type_tabs.size():
		return
	var key: Variant = type_tabs[index].get_meta(&"_type_key", &"")
	var only: Array = []
	for u in selection.orderable_units():
		if SelectionManager.unit_type_key(u) == key:
			only.append(u)
	if not only.is_empty():
		selection.select_units(only)
