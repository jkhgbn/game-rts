class_name CommandCard
extends PanelContainer
## Bottom-right command card: 4 x 3 grid of 64 px buttons (spec: ui-hud.md, 1.U2).
## The slots mirror the SelectionManager hotkeys; pressing a button does the same as the key.
## Slot layout: see the table in docs/design/ui-hud.md ("Command card").

const COLUMNS := 4
const ROWS := 3
const BUTTON_SIZE := 64.0
const GAP := 6
const SIZE := Vector2(294, 224)
const KEY_COLOR := Color(1.0, 0.85, 0.4)
const NORMAL_BORDER := Color(0.45, 0.4, 0.35, 0.9)
const REFRESH_INTERVAL := 0.1
const LEARN_PULSE_TIME := 2.0
const TRAIN_DESCRIPTIONS := {
	&"cinder_hand": "Worker. Gathers crystals.",
	&"flame_guard": "Melee line unit.",
	&"ember_archer": "Ranged unit.",
	&"blaze_rider": "Fast shock cavalry.",
	&"ash_hurler": "Long-range artillery.",
	&"rime_hauler": "Worker. Gathers crystals.",
	&"rimeshield": "Armored melee line unit.",
	&"shardcaster": "Ranged unit. Chills on hit.",
	&"rime_seer": "Support. Shields hurt soldiers.",
	&"rime_colossus": "Heavy elite. Chills on hit.",
	&"caravan": "Trades with a post and brings gold back. Max 6.",
}
## Build menu: hotkey_label -> slot (r1c1-r1c3 = Z X C, r1c4 = Back, r2c1 = V: the Ice Wall, r2c2 = B: the Bazaar).
const BUILD_KEY_SLOTS := {"Z": 0, "X": 1, "C": 2, "V": 4, "B": 5}
## Trade (10.C7, ui-trade.md 5-6): colours of the route buttons' tags and the tracker inspect texts.
const GOLD_TEXT := Color(1.0, 0.88, 0.5)
const NEAR_COLOR := Color(0.4, 0.9, 0.4)
const FAR_COLOR := Color(1.0, 0.55, 0.2)
const MARKET_KIND := &"market"
const TRACKER_TEXT := "Hired hunters act on their own."
const TRACKER_KEY_TEXT := ": trade & hunters"
const MSG_POSTS_CLOSED := "Trading posts open at 4:00"
## Route button letters (ui-trade.md 5.1); other posts use UIStyle.abbrev of their name.
const POST_ABBREVS := {&"heron_ford": "HF", &"millstone_cross": "MC", &"saltgate": "SG", &"lantern_wharf": "LW"}

var selection: SelectionManager
## Called by the Fireball button (the HUD passes its own so `GameHUD.fireball_pressed` still fires).
var fireball_action: Callable

const HudSkin := ItemTooltip.HudSkin
const ICON_RECT := Rect2(4, 4, 56, 56)
const READY_FLASH_TIME := 0.25
const ICON_POP_TIME := 0.2
const LEARN_FLASH_TIME := 0.3

var buttons: Array[Button] = []
var key_labels: Array[Label] = []           ## Hotkey letters, drawn on an 18 x 14 badge at (44, 48).
## What each slot holds right now: {} = empty, else {id, abbr, key, tooltip, disabled, order, action}.
var slots: Array[Dictionary] = []
var icons: Array[TextureRect] = []          ## 56 x 56 icon at (4, 4) when art/icons has one.
var cost_tags: Array[Label] = []            ## Train / build cost, 26 x 12 at (4, 48) (a route button: its gold value).
var near_chips: Array[Label] = []           ## Route buttons: `near` / `far`, 26 x 12 at (2, 2).

## Spell extras, one per button (index = slot).
var cooldown_rects: Array[Control] = []     ## The radial sweep (visible while on cooldown).
var cooldown_labels: Array[Label] = []      ## Remaining seconds, rounded up.
var rank_pips: Array = []                   ## Array[Array[Pip]], 3 diamonds per button.
var learn_chips: Array[Button] = []         ## The "+" chip (learns, never casts).

var _refresh_left := 0.0
var _normal_style: Array = []
var _clock := 0.0
var _last_hero_level := -1
var _learn_pulse_left := 0.0   ## > 0 for 2 s after Vessa levels up with a point to spend.
var _decos: Array[Control] = []
var _pending: Array[bool] = []
var _was_on: Array[bool] = []
var _flash: Array[float] = []        ## Ready flash left (s).
var _learn_flash: Array[float] = []  ## Gold rim after learning (s).
var _hover_a: Array[float] = []      ## Halo alpha 0-1 (fades in over 0.08 s).
var _last_rank: Array[int] = []
var _last_id: Array[String] = []

## Champions (9.C8, ui-champions.md 4): the text block shown while a champion is inspected (all slots empty).
const INSPECT_TEXT := "Champions act on their own."
const INSPECT_BOUNTY := "Bounty  "
const INSPECT_BOUNTY_ENEMY := "Hunt it with a bounty  "
## Map fill (12.C7, ui-mapfill.md 6.3 / 7.2): an epic beast viewed / a game critter selected (all slots empty).
const BEAST_TEXT := "Epic beast: attack it with your army."
const CRITTER_TEXT := "Game: hunt it with soldiers or your wizard."
## tiers.md 5: the Hall whose "+" upgrades page is open (null = its normal training card). Slot of the toggle.
const PLUS_SLOT := 11
var plus_hall: Node = null
var inspect_block: Control
var inspect_line: Label       ## "Champions act on their own."
var inspect_key_line: Label   ## "Bounty  " / "Hunt it with a bounty  " (+ the [R] badge)
var inspect_badge: Label
var inspect_lead_badge: Label ## The [U] badge before ": trade & hunters" (own trackers).
## The flag card over the selection area (FlagCard.attach, added on setup).
var flag_card: FlagCard
## The level's trade route ribbon (RouteLine.attach, added on setup).
var route_line: RouteLine


func _ready() -> void:
	add_theme_stylebox_override("panel", HudSkin.frame_style(10.0))
	custom_minimum_size = SIZE
	# Bottom-right, 16 px from the right and bottom edges: (1290, 660) at 1600 x 900.
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -16.0 - SIZE.x
	offset_right = -16.0
	offset_top = -16.0 - SIZE.y
	offset_bottom = -16.0

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	add_child(grid)
	for i in COLUMNS * ROWS:
		var holder := Control.new()   # keeps the grid cell when the button is hidden
		holder.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(holder)
		var b := CardButton.new()
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 18)
		HudSkin.style_button(b)
		b.visible = false
		b.pressed.connect(press_slot.bind(i))
		holder.add_child(b)
		var icon := TextureRect.new()
		icon.position = ICON_RECT.position
		icon.size = ICON_RECT.size
		icon.pivot_offset = ICON_RECT.size * 0.5
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.visible = false
		b.add_child(icon)
		icons.append(icon)
		b.button_down.connect(func() -> void: icon.position = ICON_RECT.position + Vector2.ONE)
		b.button_up.connect(func() -> void: icon.position = ICON_RECT.position)
		var deco := Deco.new()
		deco.card = self
		deco.index = i
		deco.set_anchors_preset(Control.PRESET_FULL_RECT)
		deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(deco)
		_decos.append(deco)
		var key := HudSkin.text("", 12, KEY_COLOR)
		key.add_theme_stylebox_override("normal", HudSkin.badge_style())
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key.custom_minimum_size = Vector2(18, 14)
		key.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		key.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		key.grow_vertical = Control.GROW_DIRECTION_BEGIN
		key.offset_left = -20.0
		key.offset_right = -2.0
		key.offset_top = -16.0
		key.offset_bottom = -2.0
		b.add_child(key)
		var cost := HudSkin.text("", 10, HudSkin.CRYSTAL_TEXT)
		var tag := StyleBoxFlat.new()
		tag.bg_color = Color(0, 0, 0, 0.75)
		tag.set_corner_radius_all(2)
		tag.content_margin_left = 2
		tag.content_margin_right = 2
		cost.add_theme_stylebox_override("normal", tag)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost.custom_minimum_size = Vector2(26, 12)
		cost.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)   # bottom edge at 62 like the key badge
		cost.grow_vertical = Control.GROW_DIRECTION_BEGIN
		cost.offset_left = 4.0
		cost.offset_right = 30.0
		cost.offset_top = -14.0
		cost.offset_bottom = -2.0
		cost.visible = false
		b.add_child(cost)
		cost_tags.append(cost)
		var chip := HudSkin.text("", 9, NEAR_COLOR)
		var chip_bg := StyleBoxFlat.new()
		chip_bg.bg_color = Color(0, 0, 0, 0.75)
		chip_bg.set_corner_radius_all(2)
		chip.add_theme_stylebox_override("normal", chip_bg)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.position = Vector2(2, 2)
		chip.size = Vector2(26, 12)
		chip.custom_minimum_size = Vector2(26, 12)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.visible = false
		b.add_child(chip)
		near_chips.append(chip)
		buttons.append(b)
		key_labels.append(key)
		slots.append({})
		_normal_style.append(false)
		_pending.append(false)
		_was_on.append(false)
		_flash.append(0.0)
		_learn_flash.append(0.0)
		_hover_a.append(0.0)
		_last_rank.append(0)
		_last_id.append("")
		_build_spell_overlays(b, holder)
	_build_inspect_block()


## The inspect text (ui-champions.md 4): `Champions act on their own.` font 14 muted at panel y 80 and
## `Bounty  [R]` font 13 at y 102 (the key on an 18 x 14 gold badge), centred; hidden whenever a slot is filled.
func _build_inspect_block() -> void:
	inspect_block = Control.new()
	inspect_block.name = "InspectText"
	inspect_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect_block.visible = false
	add_child(inspect_block)   # PanelContainer: it covers the grid's rect (content x 1300-1574, y 670-874)
	inspect_line = UIStyle.panel_label(INSPECT_TEXT, 14)
	inspect_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inspect_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	inspect_line.offset_top = 70.0    # panel y 80 (content starts 10 px in)
	inspect_line.offset_bottom = 90.0
	inspect_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect_block.add_child(inspect_line)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_top = 92.0             # panel y 102
	row.offset_bottom = 110.0
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect_block.add_child(row)
	# Trackers (ui-trade.md 6.3): `[U]: trade & hunters`, the badge first.
	inspect_lead_badge = _inspect_badge_label("U")
	inspect_lead_badge.visible = false
	row.add_child(inspect_lead_badge)
	inspect_key_line = UIStyle.panel_label(INSPECT_BOUNTY, 13)
	inspect_key_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(inspect_key_line)
	inspect_badge = _inspect_badge_label("R")
	row.add_child(inspect_badge)
	_skin_inspect_block()


## An 18 x 14 gold key badge (black letter) for the inspect block.
func _inspect_badge_label(letter: String) -> Label:
	var l := HudSkin.text(letter, 12, Color.BLACK)
	var badge := StyleBoxFlat.new()
	badge.bg_color = KEY_COLOR
	badge.set_corner_radius_all(2)
	l.add_theme_stylebox_override("normal", badge)
	l.custom_minimum_size = Vector2(18, 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## GameHUD.apply_skin calls it on a kingdom change: the inspect text colours.
func apply_skin() -> void:
	_skin_inspect_block()


func _skin_inspect_block() -> void:
	if inspect_line == null:
		return
	inspect_line.add_theme_color_override("font_color", HudSkin.token(&"text_muted"))
	inspect_key_line.add_theme_color_override("font_color", HudSkin.token(&"text"))


## The inspect block's two lines ("" when hidden), for tests: `Champions act on their own.\nBounty  [R]`,
## `Hired hunters act on their own.\n[U]: trade & hunters`.
func inspect_text() -> String:
	if inspect_block == null or not inspect_block.visible:
		return ""
	if not inspect_key_line.get_parent().visible:
		return inspect_line.text   # a game critter: one line
	var second := inspect_key_line.text
	if inspect_lead_badge.visible:
		second = "[%s]%s" % [inspect_lead_badge.text, second]
	if inspect_badge.visible:
		second += "[%s]" % inspect_badge.text
	return "%s\n%s" % [inspect_line.text, second]


## Spell extras on every button (hidden unless the slot holds a spell): radial cooldown sweep + seconds,
## diamond rank pips at (4, 54), and the "+" learn chip at (2, 2) (a sibling so the dimmed button doesn't fade it).
func _build_spell_overlays(b: Button, holder: Control) -> void:
	var cd := Sweep.new()
	cd.set_anchors_preset(Control.PRESET_FULL_RECT)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd.visible = false
	b.add_child(cd)
	b.move_child(cd, _decos.back().get_index())   # under the rims, badge and seconds
	cooldown_rects.append(cd)
	var secs := UIStyle.label("", 18)
	secs.add_theme_constant_override("outline_size", 3)
	secs.add_theme_color_override("font_color", HudSkin.token(&"text"))
	secs.set_anchors_preset(Control.PRESET_FULL_RECT)
	secs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	secs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	secs.visible = false
	b.add_child(secs)
	cooldown_labels.append(secs)
	var pips: Array = []
	for j in 3:
		var pip := Pip.new()
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.position = Vector2(4.0 + j * 8.0, 54.0)
		pip.size = Vector2(6, 6)
		pip.visible = false
		b.add_child(pip)
		pips.append(pip)
	rank_pips.append(pips)
	var chip := Button.new()
	chip.text = "+"
	chip.focus_mode = Control.FOCUS_NONE
	chip.position = Vector2(2, 2)
	chip.size = Vector2(16, 16)
	chip.custom_minimum_size = Vector2(16, 16)
	chip.pivot_offset = Vector2(8, 8)   # the level-up pulse grows it from its centre
	chip.add_theme_font_size_override("font_size", 14)
	chip.add_theme_color_override("font_color", Color.BLACK)
	chip.add_theme_color_override("font_hover_color", Color.BLACK)
	chip.add_theme_color_override("font_pressed_color", Color.BLACK)
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = KEY_COLOR
	chip_style.set_corner_radius_all(3)
	chip_style.set_content_margin_all(0)
	for state in ["normal", "hover", "pressed", "disabled"]:
		chip.add_theme_stylebox_override(state, chip_style)
	chip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	chip.visible = false
	chip.pressed.connect(press_learn.bind(learn_chips.size()))
	holder.add_child(chip)
	learn_chips.append(chip)


func setup(p_selection: SelectionManager) -> void:
	selection = p_selection
	# Safe to call again (GameHUD.setup re-runs when the level swaps the player's wizard).
	if not selection.selection_changed.is_connected(refresh):
		selection.selection_changed.connect(refresh)
	if not selection.mode_changed.is_connected(refresh):
		selection.mode_changed.connect(refresh)
	# The flag card lives over the selection area; it is added once under the HUD (no hud.gd wiring needed).
	if (flag_card == null or not is_instance_valid(flag_card)) and get_parent() != null:
		var hud: Node = get_parent()
		while hud != null and not hud is CanvasLayer:
			hud = hud.get_parent()
		flag_card = FlagCard.attach(hud if hud != null else get_parent(), selection)
	elif flag_card != null:
		flag_card.setup(selection)
	# The trade route ribbon + hover chip (10.C7, ui-trade.md 7): one per level; attach returns the existing one.
	var layer: Node = get_parent()
	while layer != null and not layer is CanvasLayer:
		layer = layer.get_parent()
	if layer != null:
		route_line = RouteLine.attach(layer, selection)
	refresh()


func _process(delta: float) -> void:
	_clock += delta
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_INTERVAL
		refresh()
	_check_level_up()
	if _learn_pulse_left > 0.0:
		_learn_pulse_left = maxf(_learn_pulse_left - delta, 0.0)
	# Every frame: the cooldown sweeps and the "+" chips' pulse (0.7 <-> 1.0 every 0.8 s); for 2 s
	# after a level-up with a point to spend they also grow 1.0 <-> 1.35 every 0.4 s.
	var pulse := 0.85 + 0.15 * sin(_clock * TAU / 0.8)
	var grow := 1.0
	if _learn_pulse_left > 0.0:
		grow = 1.0 + 0.35 * absf(sin(_clock * PI / 0.4))
	for i in buttons.size():
		if slots[i].has("spell"):
			_update_cooldown(i)
		_flash[i] = maxf(_flash[i] - delta, 0.0)
		_learn_flash[i] = maxf(_learn_flash[i] - delta, 0.0)
		var hovered := buttons[i].visible and buttons[i].is_hovered()
		_hover_a[i] = move_toward(_hover_a[i], 1.0 if hovered else 0.0, delta / 0.08)
		var pop := _flash[i] - (READY_FLASH_TIME - ICON_POP_TIME)
		var k := 1.0 + 0.08 * sin(PI * (1.0 - pop / ICON_POP_TIME)) if pop > 0.0 else 1.0
		icons[i].scale = Vector2(k, k)
		if buttons[i].visible:
			_decos[i].queue_redraw()
		if learn_chips[i].visible:
			learn_chips[i].modulate.a = pulse
			learn_chips[i].scale = Vector2(grow, grow)
			learn_chips[i].self_modulate = Color(1.3, 1.3, 1.3) if grow > 1.0 else Color.WHITE


## Starts the 2 s "+" chip pulse when Vessa's level goes up and she has an unspent spell point.
func _check_level_up() -> void:
	var hero: Node = selection.hero if selection else null
	if hero == null or not is_instance_valid(hero) or hero.get("level") == null:
		return
	var level := int(hero.get("level"))
	if _last_hero_level >= 0 and level > _last_hero_level:
		var points := int(hero.get("spell_points")) if hero.get("spell_points") != null else 0
		if points > 0:
			_learn_pulse_left = LEARN_PULSE_TIME
			refresh()   # show the chips right away
	_last_hero_level = level


## Are the "+" chips doing their level-up pulse (for tests)?
func learn_pulse_active() -> bool:
	return _learn_pulse_left > 0.0


func _update_cooldown(i: int) -> void:
	var hero: Node = selection.hero if selection else null
	var id: StringName = slots[i]["spell"]
	var left := SpellInfo.cooldown_left(hero, id)
	var total := SpellInfo.cooldown_total(hero, id)
	var on := left > 0.0 and total > 0.0
	cooldown_rects[i].visible = on
	cooldown_labels[i].visible = on
	if _was_on[i] and not on:
		_flash[i] = READY_FLASH_TIME   # ready flash + icon pop
	_was_on[i] = on
	if on:
		(cooldown_rects[i] as Sweep).ratio = clampf(left / total, 0.0, 1.0)
		cooldown_rects[i].queue_redraw()
		cooldown_labels[i].text = str(ceili(left))


## The "+" chip of button `index`: learn that spell (Wizard.learn_spell), never cast.
func press_learn(index: int) -> void:
	if index < 0 or index >= slots.size() or not slots[index].has("spell") or selection == null:
		return
	selection.learn_spell_slot(int(slots[index]["spell_slot"]))
	refresh()


## Is the cooldown sweep showing on slot `index` (for tests)?
func cooldown_visible(index: int) -> bool:
	return cooldown_rects[index].visible


## Rebuilds the slots from the current selection (also runs 10 times a second for live states).
func refresh() -> void:
	var new_slots := _build_slots()
	_update_inspect_block(new_slots)
	var pending: StringName = selection.get_pending_order() if selection else &""
	for i in buttons.size():
		var s: Dictionary = new_slots[i]
		slots[i] = s
		var b := buttons[i]
		_update_spell_extras(i, s)
		if s.is_empty():
			b.visible = false
			key_labels[i].text = ""
			_last_id[i] = ""
			near_chips[i].visible = false
			continue
		b.visible = true
		b.text = s["abbr"]
		var tex := _icon_for(s)
		icons[i].texture = tex
		icons[i].visible = tex != null
		# With an icon the abbreviation stays in `text` (tests, fallback) but is not drawn.
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(c, Color(0, 0, 0, 0) if tex != null else HudSkin.token(&"text"))
		key_labels[i].text = s["key"]
		key_labels[i].visible = s["key"] != ""
		key_labels[i].add_theme_font_size_override("font_size", 12 if str(s["key"]).length() <= 1 else 10)
		var disabled: bool = s["reason"] != ""
		b.disabled = disabled
		# A spell on cooldown stays bright: the dark sweep shows it.
		b.modulate.a = 0.45 if disabled and s["reason"] != "On cooldown" else 1.0
		icons[i].self_modulate = Color(0.55, 0.55, 0.55) if disabled and s["reason"] != "On cooldown" else Color.WHITE
		b.tooltip_text = s["tooltip"] + ("\n" + s["reason"] if disabled else "")
		_pending[i] = s["order"] != &"" and s["order"] == pending
		var highlight: bool = _pending[i]
		if s.has("active"):
			highlight = s["active"]
		if highlight != _normal_style[i]:
			_normal_style[i] = highlight
			if highlight:
				HudSkin.style_button_selected(b)
			else:
				HudSkin.style_button(b)
			key_labels[i].add_theme_stylebox_override("normal", HudSkin.badge_style(highlight))
			key_labels[i].add_theme_color_override("font_color", Color.BLACK if highlight else KEY_COLOR)
		var has_cost := s.has("cost") or s.has("value")
		cost_tags[i].visible = has_cost
		if s.has("value"):   # a route button: gold per trip
			cost_tags[i].text = str(s["value"])
			cost_tags[i].add_theme_color_override("font_color", GOLD_TEXT)
		elif has_cost:
			cost_tags[i].text = str(s["cost"])
			cost_tags[i].add_theme_color_override("font_color",
					UIStyle.WARN if str(s["reason"]).begins_with("Not enough crystals") else HudSkin.CRYSTAL_TEXT)
		near_chips[i].visible = s.has("far")
		if s.has("far"):
			near_chips[i].text = "far" if s["far"] else "near"
			near_chips[i].add_theme_color_override("font_color", FAR_COLOR if s["far"] else NEAR_COLOR)


## The slot ids in grid order ("" = empty), for tests: e.g. ["move", "stop", "hold", "attack", ...].
func slot_ids() -> Array[String]:
	var ids: Array[String] = []
	for s in slots:
		ids.append(str(s.get("id", "")))
	return ids


## Presses slot `index` (the button's action), if it is shown and enabled.
func press_slot(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	var s: Dictionary = slots[index]
	if s.is_empty() or s["reason"] != "":
		return
	(s["action"] as Callable).call()
	refresh()


# ---------------------------------------------------------------- slot tables

func _build_slots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in COLUMNS * ROWS:
		out.append({})
	if selection == null:
		return out
	if plus_hall != null and (not is_instance_valid(plus_hall) or selection.selected_building != plus_hall):
		plus_hall = null   # the "+" page closes when the Hall is no longer the selected building
	if selection.selected_bounty != null:
		_flag_slots(out, selection.selected_bounty)
	elif selection.selected_building != null:
		_building_slots(out, selection.selected_building)
	elif selection.build_menu_open or selection.placing_type != null:
		_build_menu_slots(out)
	elif selection.is_inspecting():
		_helper_stance_slots(out, selection.inspected)   # champions are never ordered; an own helper shows its 3 stances
	elif not selection.orderable_units().is_empty():
		_unit_slots(out)
	return out


## An own tier-3 helper inspected (t3-helpers.md 2.1): r1c1-r1c3 Escort / Vanguard / Hold home, click only (no key).
## A stance is not an order: the helper stays non-commandable.
func _helper_stance_slots(out: Array[Dictionary], h: Variant) -> void:
	if not (h is Helper) or not is_instance_valid(h) or int((h as Helper).team) != Unit.Team.PLAYER:
		return
	var helper := h as Helper
	var tips := {
		&"escort": "Escort\nStays 3-7 m from your wizard and fights what threatens it.",
		&"vanguard": "Vanguard\nFollows your largest army group and fights with it.",
		&"home": "Hold home\nGuards the keep: fights intruders within 20 m.",
	}
	var abbr := {&"escort": "ES", &"vanguard": "VG", &"home": "HM"}
	for i in Helper.STANCES.size():
		var st: StringName = Helper.STANCES[i]
		var tip: String = tips[st] + ("\n(current)" if helper.stance == st else "")
		var s := _slot("stance_" + String(st), abbr[st], "", tip, func() -> void: helper.set_stance(st))
		s["active"] = helper.stance == st
		out[i] = s


## The inspect text shows while a champion or a Greywater Tracker is inspected and every slot is empty; enemy:
## `Hunt it with a bounty`. Other inspected units (a visible enemy soldier, a Magpie) show no text.
func _update_inspect_block(new_slots: Array[Dictionary]) -> void:
	if inspect_block == null:
		return
	var empty := new_slots.all(func(s: Dictionary) -> bool: return s.is_empty())
	var show := selection != null and selection.selected_bounty == null and selection.selected_building == null \
			and selection.is_inspecting() and empty
	var tracker := show and selection.inspected.is_in_group(&"trackers")
	var beast := show and selection.inspected.is_in_group(&"beasts")
	if show and not tracker and not beast and not selection.inspected.is_in_group(&"champions") \
			and SelectionManager.is_commandable_unit(selection.inspected):
		show = false   # an ordinary enemy / neutral unit
	# A game critter selected (12.C6's selected_neutral): one line, no bounty key (flags are refused on critters).
	var critter := false
	if not show and selection != null and empty and selection.selected_bounty == null \
			and selection.selected_building == null and not selection.is_inspecting():
		var n: Variant = selection.get(&"selected_neutral")
		critter = is_instance_valid(n) and n is Node and (n as Node).has_method(&"is_game_critter") \
				and bool((n as Node).call(&"is_game_critter"))
	inspect_key_line.get_parent().visible = not critter
	inspect_block.visible = show or critter
	if critter:
		inspect_line.text = CRITTER_TEXT
		return
	if show:
		var enemy := selection.inspected.team != Unit.Team.PLAYER
		inspect_line.text = TRACKER_TEXT if tracker else (BEAST_TEXT if beast else INSPECT_TEXT)
		var own_tracker := tracker and not enemy
		inspect_lead_badge.visible = own_tracker
		inspect_badge.visible = not own_tracker
		if own_tracker:
			inspect_key_line.text = TRACKER_KEY_TEXT
		else:
			inspect_key_line.text = INSPECT_BOUNTY_ENEMY if enemy else INSPECT_BOUNTY


## A bounty flag selected (ui-champions.md 7): r1c1 `Raise +25 [Z]`, r1c2 `Remove [Del]` with the refund in the
## tooltip. Enemy flags: no buttons.
func _flag_slots(out: Array[Dictionary], flag: Node3D) -> void:
	var sel := selection
	if not is_instance_valid(flag) or not sel.is_own_bounty_selected():
		return
	var stake := BountyMode.flag_stake(flag)
	var raise_reason := ""
	if stake >= BountyMode.MAX_STAKE:
		raise_reason = BountyMode.MSG_MAX
	elif BountyMode.essence_of(Unit.Team.PLAYER) < mini(BountyMode.RAISE_STEP, BountyMode.MAX_STAKE - stake):
		raise_reason = BountyMode.MSG_NO_ESSENCE
	var raise_tip := "Raise +%d  [Z]\nStake %d -> %d (max %d)\nShift+Z: +%d" % [BountyMode.RAISE_STEP, stake,
			mini(stake + BountyMode.RAISE_STEP, BountyMode.MAX_STAKE), BountyMode.MAX_STAKE, BountyMode.RAISE_BIG]
	out[0] = _slot("raise", "+%d" % BountyMode.RAISE_STEP, "Z", raise_tip,
			func() -> void: sel.raise_selected_bounty(BountyMode.RAISE_STEP), raise_reason)
	out[1] = _slot("remove", "RM", "Del", remove_tooltip(flag), func() -> void: sel.remove_selected_bounty())


## `Remove  [Delete]\nRefund 150 (100 %): nobody pursues it.` or
## `Remove  [Delete]\nRefund 75 (50 %) · 75 to the 2 pursuers`.
static func remove_tooltip(flag: Node) -> String:
	var refund := BountyMode.refund_preview(flag)
	var pursuers := BountyMode.flag_pursuers(flag).size()
	if pursuers == 0:
		return "Remove  [Delete]\nRefund %d (100 %%): nobody pursues it." % refund
	var unpaid := maxi(0, BountyMode.flag_stake(flag) - BountyMode.flag_paid(flag))
	return "Remove  [Delete]\nRefund %d (50 %%) · %d to the %d pursuer%s" % [refund, unpaid - refund, pursuers,
			"" if pursuers == 1 else "s"]


## Slot table (ui-hud.md / buildings.md): workers only = Move Stop Hold Gather / Build;
## soldiers = Move Stop Hold Attack-move; wizard adds Fireball at r2c1; mixed with workers = Gather r2c4.
## Caravans (ui-trade.md 6.1): Move Stop Hold Trade (G); with workers the Gather slot says `Gather / Trade`;
## caravans never get Attack-move.
func _unit_slots(out: Array[Dictionary]) -> void:
	var sel := selection
	out[0] = _slot("move", "MV", "M", "Move  [M]\nWalk to the clicked point.",
			func() -> void: sel.begin_order(SelectionManager.ORDER_MOVE), "", SelectionManager.ORDER_MOVE)
	out[1] = _slot("stop", "ST", "C", "Stop  [C]\nStop and stand still.", sel.stop)
	out[2] = _slot("hold", "HD", "H", "Hold  [H]\nStay in place; hit only enemies in range.", sel.hold)
	var fighters := sel.has_fighters()
	var workers := sel.has_workers()
	var caravans := sel.has_caravans()
	if caravans and not workers:
		out[7 if fighters else 3] = _slot("trade", "TR", "G",
				"Trade  [G]\nClick a trading post: trade there from now on.\nClick your Bazaar: go home and deliver.",
				func() -> void: sel.begin_order(SelectionManager.ORDER_GATHER), "", SelectionManager.ORDER_GATHER)
	if fighters:
		# UX.1: Classic = A (X works too), Hero WASD = X; _slot shows the key as labelled on the player's keyboard.
		var am := "X" if GameSettings.attack_move_key() == KEY_X else "A"
		var am_tip := "Attack-move  [%s]\nMove and fight anything met on the way." % am
		if am != "X":
			am_tip += "\n%s works too." % KeyLabels.of(KEY_X)
		out[3] = _slot("attack", "AM", am, am_tip,
				sel.begin_attack_move_targeting, "", SelectionManager.ORDER_ATTACK_MOVE)
	if sel.has_hero():
		var spell_ids := SpellInfo.ids(sel.hero)
		for i in mini(spell_ids.size(), 3):
			out[4 + i] = _spell_slot(spell_ids[i], i)
	if workers:
		var tip := "Gather  [G]\nMine crystals and carry them to a keep or hall."
		if caravans:
			tip = "Gather / Trade  [G]\nWorkers gather at a crystal node; caravans trade at a post or go home to the Bazaar."
		var gather := _slot("gather", "GA", "G", tip,
				func() -> void: sel.begin_order(SelectionManager.ORDER_GATHER),
				"" if sel.has_gatherers() or caravans else "Workers can't gather yet", SelectionManager.ORDER_GATHER)
		out[7 if fighters else 3] = gather
	if sel.can_build():
		out[4] = _slot("build", "BU", "B", "Build  [B]\nOpen the build menu: Hearth, hall and spire.",
				sel.open_build_menu)


## The build menu (after B): row 1 = the buildings (Z X C), then Back (Esc / right click); a 4th building
## (the Ice Wall, key V) goes to r2c1 (kingdom-ice.md 5). Slots follow the type's hotkey_label.
func _build_menu_slots(out: Array[Dictionary]) -> void:
	var sel := selection
	var types := sel.buildable_types()
	var free := [0, 1, 2, 4, 5, 6, 7]
	var placed: Array = []   # [slot, type]
	for type: BuildingType in types:
		var slot: int = BUILD_KEY_SLOTS.get(type.hotkey_label.to_upper(), -1)
		if slot >= 0 and free.has(slot):
			free.erase(slot)
			placed.append([slot, type])
	for type: BuildingType in types:   # no known key: the next free slot
		if not BUILD_KEY_SLOTS.has(type.hotkey_label.to_upper()) and not free.is_empty():
			placed.append([free.pop_front(), type])
	for entry: Array in placed:
		var i: int = entry[0]
		var type: BuildingType = entry[1]
		var tip := "%s  [%s]\nCost %d crystals · %d s · %d HP\n%s" % [
				type.display_name, type.hotkey_label, type.cost, roundi(type.build_time), int(type.max_hp),
				_building_description(type)]
		var s := _slot("build_" + String(type.id), UIStyle.abbrev(type.display_name), type.hotkey_label, tip,
				func() -> void: sel.begin_placement(type), sel.build_reason(type), SelectionManager.ORDER_BUILD)
		s["active"] = sel.placing_type == type
		s["cost"] = type.cost
		s["icon"] = ["buildings", String(type.id)]
		out[i] = s
	out[3] = _slot("back", "<", "Esc", "Back  [Esc]\nClose the build menu (right click does the same).",
			sel.close_build_menu)


func _building_description(type: BuildingType) -> String:
	var faction := String(type.faction).capitalize()
	match type.kind:
		&"barracks":
			return "Trains %s soldiers. Workers can drop crystals here." % faction
		&"house":
			var limit := " Max %d." % type.max_count if type.max_count > 0 else ""
			return "+%d population.%s" % [type.pop_bonus, limit]
		&"tower":
			return "Shoots enemies in range (damage %d, range %d)." % [roundi(type.attack_damage), roundi(type.attack_range)]
		&"market":
			return "Sends caravans to the trading posts for gold. Within 20 m of your keep. One per kingdom."
	if type.kind == &"wall" or String(type.id).ends_with("_wall"):
		return "Blocks the way.%s" % (" Max %d." % type.max_count if type.max_count > 0 else "")
	return ""


## Spell button r2c1-r2c3 (spells.md, levels.md "Spell buttons"): disabled with the reason
## (Not learned [· needs level n] / On cooldown / Not enough mana / Dead), rank pips, "+" chip.
func _spell_slot(id: StringName, slot: int) -> Dictionary:
	var hero := selection.hero
	var reason := SpellInfo.cast_reason(hero, id)
	var learn := SpellInfo.learn_reason(hero, id) if hero != null and hero.has_method(&"can_learn") else "n/a"
	if reason == "Not learned" and learn.begins_with("Needs level"):
		reason = "Not learned · needs level %s" % learn.get_slice(" ", 2)
	var key: String = SpellInfo.SLOT_KEYS[slot]
	var action: Callable = selection.cast_spell_slot.bind(slot)
	if slot == 0 and fireball_action.is_valid():
		action = fireball_action
	var s := _slot(String(id), SpellInfo.abbrev(id), key, SpellInfo.tooltip(hero, id, slot), action, reason,
			StringName(id))
	s["spell"] = id
	s["spell_slot"] = slot
	s["rank"] = SpellInfo.rank(hero, id)
	s["max_rank"] = SpellInfo.max_rank(id, slot)
	s["learnable"] = learn == ""
	s["active"] = selection.get_pending_order() == StringName(id) or learn == ""
	return s


## Pips, "+" chip and cooldown sweep of button `i` for slot `s`.
func _update_spell_extras(i: int, s: Dictionary) -> void:
	var is_spell := s.has("spell")
	var levels := is_spell and selection.hero != null and selection.hero.has_method(&"spell_rank")
	var r: int = s.get("rank", 0)
	var max_r: int = s.get("max_rank", 0)
	var sid := str(s.get("id", ""))
	if is_spell and sid == _last_id[i] and r > _last_rank[i]:
		_learn_flash[i] = LEARN_FLASH_TIME   # the rim flashes gold after learning / ranking up
	_last_id[i] = sid
	_last_rank[i] = r
	var pips: Array = rank_pips[i]
	for j in pips.size():
		var pip: Pip = pips[j]
		pip.visible = levels and r > 0 and j < max_r
		pip.color = KEY_COLOR if j < r else Color(0.3, 0.3, 0.3)
	learn_chips[i].visible = is_spell and bool(s.get("learnable", false))
	learn_chips[i].tooltip_text = "Learn  [Ctrl+%s]" % s.get("key", "") if is_spell else ""
	if is_spell:
		_update_cooldown(i)
	else:
		cooldown_rects[i].visible = false
		cooldown_labels[i].visible = false


## A selected building: a construction site shows Cancel (Delete); a trainer (keep, hall) shows its
## training slots Z X C V B and Set Rally right after them; other buildings show nothing.
func _building_slots(out: Array[Dictionary], keep: Node) -> void:
	var sel := selection
	if keep.has_method("is_constructed") and not bool(keep.call("is_constructed")):
		var type: Variant = keep.get("building_type")
		var refund := floori(int(type.get("cost")) * 0.75) if type is Object else 0
		out[0] = _slot("cancel", "CN", "Del",
				"Cancel  [Delete]\nStop building and get %d crystals back (75 %%)." % refund,
				func() -> void: sel.cancel_site())
		return
	if plus_hall != null and plus_hall == keep and is_instance_valid(keep):
		_plus_slots(out, keep)
		return
	var types := sel.trainable_types()
	var n_train := mini(types.size(), SelectionManager.SLOT_KEYS.size())   # 5, or 8 on a Hall (new-units-12.md)
	for i in n_train:
		var type: Variant = types[i]
		var type_name := str(type.get("display_name"))
		var key := sel.train_key(type, i)
		var reason := ""
		if keep.has_method("can_queue"):
			reason = str(keep.call("can_queue", type))
		var desc: String = TRAIN_DESCRIPTIONS.get(StringName(str(type.get("id"))),
				NewUnits12.description(StringName(str(type.get("id")))))
		if desc == "" and type is Object and (type as Object).has_meta(&"card_text"):   # stub types (keep tier button)
			desc = str((type as Object).get_meta(&"card_text"))
		var tip := "%s  [%s]\nCost %d crystals · Pop %d · %d s" % [
				type_name, key, int(type.get("cost")), int(type.get("pop")), roundi(float(type.get("train_time")))]
		if desc != "":
			tip += "\n" + desc
		out[i] = _slot("train_" + str(type.get("id")), UIStyle.abbrev(type_name), key, tip,
				func() -> void: sel.train(type), reason)
		out[i]["cost"] = int(type.get("cost"))
		out[i]["icon"] = ["units", str(type.get("id"))]
	if is_market(keep):
		_market_slots(out, keep, n_train)
		return
	if keep.has_method("set_rally_point"):
		out[n_train] = _slot("rally", "RL", "",
				"Set Rally  (right click)\nNew units walk here. Click a crystal node to send new workers mining.",
				func() -> void: sel.begin_order(SelectionManager.ORDER_RALLY), "", SelectionManager.ORDER_RALLY)
	# tiers.md 5: an own Hall opens its "+" upgrades page from r3c4 (click only).
	if int(keep.get(&"team")) == Unit.Team.PLAYER and out[PLUS_SLOT].is_empty() \
			and not UnitUpgrades.ids_for_hall(keep).is_empty():
		var tip := "Upgrades\n\"+\" research for this Hall's units: +10 % HP and damage each. Needs a Stronghold."
		out[PLUS_SLOT] = _slot("plus_page", "+", "", tip, func() -> void: plus_hall = keep)


## The "+" upgrades page of a Hall (tiers.md 5): one button per unit (card order), Back at r3c4.
func _plus_slots(out: Array[Dictionary], hall: Node) -> void:
	var rows := UnitUpgrades.options_for(hall)
	for i in mini(rows.size(), PLUS_SLOT):
		var r: Dictionary = rows[i]
		var id: StringName = r["id"]
		var state: StringName = r["state"]
		var reason: String = r["reason"]
		if state == &"done":
			reason = "Researched"
		elif state == &"working":
			reason = "Researching %d %%" % roundi(float(r["progress"]) * 100.0)
		var tip := "%s\n%d crystals · %d s\n%s for every %s of your kingdom." % [r["name"], int(r["crystals"]),
				roundi(float(r["time"])), r["text"], String(r["name"]).trim_suffix("+")]
		var buy := func() -> void:
			var bank := UnitUpgrades.for_team(int(hall.get(&"team")))
			if bank:
				bank.buy(id, hall)
		var s := _slot("plus_" + String(id), UIStyle.abbrev(String(r["name"]).trim_suffix("+")) + "+", "", tip,
				buy, reason)
		s["cost"] = int(r["crystals"])
		s["icon"] = ["units", String(id)]
		s["active"] = state == &"working" or state == &"done"
		out[i] = s
	out[PLUS_SLOT] = _slot("plus_back", "<", "", "Back\nThe Hall's training buttons.", func() -> void: plus_hall = null)


## A Bazaar (building kind &"market").
static func is_market(b: Node) -> bool:
	if b == null or not is_instance_valid(b):
		return false
	var t: Variant = b.get("building_type")
	return b.is_in_group(&"markets") or (t is BuildingType and (t as BuildingType).kind == MARKET_KIND)


## The own Bazaar (ui-trade.md 5.1): r1c1 Caravan (the training slot), r1c2 Set Route (no key, targeted order),
## r1c3 Wares (U: the trade window on the Bazaar tab), r2 one button per trading post sorted by value, with the value
## tag, the near / far chip, the current route selected, and `Opens at 4:00` / `Held by the enemy` refusals.
## No Set Rally: a right click on a post sets the route.
func _market_slots(out: Array[Dictionary], market: Node, first_free: int) -> void:
	var sel := selection
	var closed := _posts_closed(market)
	var route_i := maxi(first_free, 1)
	out[route_i] = _slot("route", "RT", "",
			"Set Route\nClick a trading post: caravans trade there from now on.\nRight-click a post does the same.",
			func() -> void: sel.begin_order(SelectionManager.ORDER_ROUTE), MSG_POSTS_CLOSED if closed else "",
			SelectionManager.ORDER_ROUTE)
	out[route_i + 1] = _slot("wares", "WR", "U", "Wares  [U]\nBuy one-time wares and exchange gold at the Bazaar.",
			open_wares)
	var posts := route_posts(market)
	var current: Variant = market.get("route_post")
	for j in mini(posts.size(), 4):
		var post: Node3D = posts[j]
		var pid := str(post.get("post_id")) if post.get("post_id") != null else String(post.name)
		var pname := RouteLine.post_name(post)
		var far := RouteLine.is_far(market, post)
		var value := RouteLine.value_of(market, post)
		var is_current: bool = current == post
		var reason := RouteLine.short_reason(RouteLine.route_reason(market, post))
		var line3 := "Current route" if is_current else "Right-click the post does the same."
		var tip := "%s · %s\n%d gold per trip · ~%d / min per caravan\n%s" % [pname, "far" if far else "near", value,
				RouteLine.per_minute(market, post), line3]
		var s := _slot("route_" + pid, POST_ABBREVS.get(StringName(pid), UIStyle.abbrev(pname)), "", tip,
				func() -> void: sel.set_market_route(post), reason)
		s["value"] = value
		s["far"] = far
		s["active"] = is_current
		s["held"] = reason == "Held by the enemy"
		s["icon"] = ["posts", pid]
		s["post"] = post
		out[4 + j] = s


## The trading posts (TradeNetwork.posts(), else group "trade_posts"), sorted by route value from `market`, lowest
## first (the near ones first by construction).
func route_posts(market: Node) -> Array:
	var list: Array = []
	var net := get_tree().get_first_node_in_group(&"trade_network") if is_inside_tree() else null
	var src: Variant = net.call(&"posts") if net != null and net.has_method(&"posts") \
			else (get_tree().get_nodes_in_group(&"trade_posts") if is_inside_tree() else [])
	for p: Variant in src:
		if is_instance_valid(p) and p is Node3D and (p as Node3D).is_inside_tree():
			list.append(p)
	var values := {}
	for p: Node3D in list:
		values[p.get_instance_id()] = RouteLine.value_of(market, p)
	list.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var va: int = values[a.get_instance_id()]
		var vb: int = values[b.get_instance_id()]
		return va < vb if va != vb else RouteLine.post_name(a) < RouteLine.post_name(b))
	return list


## True while the trading posts are closed (TradeNetwork.is_open() false; no network = open).
func _posts_closed(_market: Node) -> bool:
	var net := get_tree().get_first_node_in_group(&"trade_network") if is_inside_tree() else null
	return net != null and net.has_method(&"is_open") and not bool(net.call(&"is_open"))


## Wares (U): the trade window on the Bazaar tab (10.C8's TradeWindow, reached through the HUD's `trade_window`).
func open_wares() -> void:
	var n: Node = self
	while n != null:
		var w: Variant = n.get("trade_window")
		if is_instance_valid(w) and w is Object and (w as Object).has_method(&"open"):
			(w as Object).call(&"open", &"bazaar")
			return
		n = n.get_parent()
	for w in get_tree().get_nodes_in_group(&"trade_window"):
		if w.has_method(&"open"):
			w.call(&"open", &"bazaar")
			return


## `key` is the QWERTY letter of the physical key (or "Del", "Esc", ""): the slot shows the letter printed on the
## player's keyboard (KeyLabels, UX.1) and the tooltip's "[Q]" / "Ctrl+Q" / "Shift+Q" hints follow.
func _slot(id: String, abbr: String, key: String, tooltip: String, action: Callable,
		reason := "", order: StringName = &"") -> Dictionary:
	var shown := KeyLabels.letter(key)
	if shown != key:
		tooltip = KeyLabels.localize_hints(tooltip, key)
		key = shown
	return {"id": id, "abbr": abbr, "key": key, "tooltip": tooltip, "action": action,
			"reason": reason, "order": order}


## The slot's icon (`art/icons/<kind>/<id>.png`), or null (then the abbreviation shows).
func _icon_for(s: Dictionary) -> Texture2D:
	if s.has("icon"):
		return HudSkin.icon(s["icon"][0], s["icon"][1])
	if s.has("spell"):
		return HudSkin.icon("spells", String(s["spell"]))
	return HudSkin.icon("orders", str(s["id"]))


## Hover halo, pending gold pulse, ready flash and learn flash of button `i` (drawn by its Deco).
func draw_deco(d: Control, i: int) -> void:
	var r := Rect2(Vector2.ZERO, d.size)
	if bool(slots[i].get("held", false)):
		d.draw_rect(r.grow(-0.5), UIStyle.WARN, false, 1.0)   # a route to a post held by the enemy
	if _hover_a[i] > 0.0:
		d.draw_rect(r.grow(0.5), Color(HudSkin.token(&"trim_glow"), 0.6 * _hover_a[i]), false, 1.0)
	if _pending[i]:
		var a := 0.85 + 0.15 * sin(_clock * TAU * 2.0)
		d.draw_rect(r.grow(-2.0), Color(KEY_COLOR, a), false, 2.0)
	if _flash[i] > 0.0:
		d.draw_rect(r.grow(-2.0), Color(HudSkin.token(&"trim_glow"), _flash[i] / READY_FLASH_TIME), false, 2.0)
	if _learn_flash[i] > 0.0:
		d.draw_rect(r.grow(-2.0), Color(KEY_COLOR, _learn_flash[i] / LEARN_FLASH_TIME), false, 2.0)


## Is the ready flash playing on slot `index` (for tests)?
func ready_flash_active(index: int) -> bool:
	return _flash[index] > 0.0


## A card button whose tooltip is the styled panel of ui-style.md section 8 (same `tooltip_text`).
class CardButton extends Button:
	func _make_custom_tooltip(for_text: String) -> Object:
		return ItemTooltip.HudSkin.tooltip_panel(for_text)


## Draws the rim effects of one button through the card.
class Deco extends Control:
	var card: CommandCard
	var index := 0

	func _draw() -> void:
		if card != null:
			card.draw_deco(self, index)


## The radial cooldown sweep (6.2).
class Sweep extends Control:
	var ratio := 0.0

	func _draw() -> void:
		ItemTooltip.HudSkin.draw_sweep(self, Rect2(Vector2.ZERO, size), ratio)


## A rank pip drawn as a 6 x 6 diamond with a 1 px groove edge.
class Pip extends Control:
	var color := Color.WHITE:
		set(value):
			if value != color:
				color = value
				queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var h := size.x * 0.5
		var pts := PackedVector2Array([c + Vector2(0, -h), c + Vector2(h, 0), c + Vector2(0, h), c + Vector2(-h, 0)])
		draw_colored_polygon(pts, color)
		pts.append(pts[0])
		draw_polyline(pts, ItemTooltip.HudSkin.token(&"groove"), 1.0)
