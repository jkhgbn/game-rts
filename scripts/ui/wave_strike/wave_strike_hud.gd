class_name WaveStrikeHud
extends CanvasLayer
## Wave Strike M1 HUD (docs/design/wave-strike.md 7.4, task WS.U1, minimal): the top strip (both Bastion HP bars,
## horn countdown, match clock, the bank line: crystals, income per horn, Coffers, supply, tier) and the buy panel
## (the kingdom's 4 cards with price, pop, count and the greyed reason, the Coffer, the Stronghold, next-wave size).
## Keys (physical, consistent with ui-hud.md: no W A S D Q E F): Z X C V = cards 1-4, B = Coffer, N = Stronghold;
## Ctrl + a card key (or Ctrl+click) = rank the line up (Drilled at Stronghold, Elite at Citadel);
## Alt + a card key (or Alt+click / right-click) = sell one. Over the main GameHUD (its top bar and objective are hidden).

const CARD_KEYS: Array[int] = [KEY_Z, KEY_X, KEY_C, KEY_V]
const KEY_COFFER := KEY_B
const KEY_TIER := KEY_N
const REFRESH := 0.1
const PANEL_W := 330.0

var level: Node                     ## WaveStrikeLevel
var seat := 0
var roster: MusterRoster
var bank: WaveBank
var director: WaveDirector

var _bars: Array = []               ## [[ProgressBar, Label], ...] per team (0 = own side drawn left)
var _horn_label: Label
var _clock_label: Label
var _bank_label: Label
var _card_buttons: Array[Button] = []
var _coffer_button: Button
var _tier_button: Button
var _wave_label: Label
var _refresh_left := 0.0
var _flash_left := 0.0


func setup(p_level: Node, p_seat: int) -> void:
	level = p_level
	seat = p_seat
	roster = level.get(&"rosters")[seat]
	bank = level.get(&"banks")[seat]
	director = level.get(&"director")
	layer = 5
	var gh: Node = level.get(&"hud")
	if gh:
		var tb: Variant = gh.get(&"top_bar")
		if tb is CanvasItem:
			(tb as CanvasItem).visible = false
		for key: StringName in [&"next_step_hint", &"tier_chip"]:   # skirmish hints ("build an Ember Hall")
			var n: Variant = gh.get(key)
			if n is CanvasItem and is_instance_valid(n):
				(n as CanvasItem).visible = false
				(n as Node).process_mode = Node.PROCESS_MODE_DISABLED
		if gh.has_method(&"set_objective_visible"):
			gh.call(&"set_objective_visible", false)
	_build()
	director.horn.connect(_on_horn)
	_refresh()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.hud_theme()
	add_child(root)

	# --- top strip
	var top_wrap := _centre_strip(root, 10.0)
	var top := UIStyle.panel(top_wrap, 10.0)
	top.add_theme_stylebox_override("panel", UIStyle.frame_style(10.0))
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(row)
	for side in 2:
		var team := seat if side == 0 else 1 - seat
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.custom_minimum_size = Vector2(250, 0)
		var name_l := UIStyle.panel_label(_side_name(team), 15, UIStyle.kingdom_color(_kingdom(team)))
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if side == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		col.add_child(name_l)
		var b: Array = UIStyle.bar(UIStyle.kingdom_color(_kingdom(team)), 22.0)
		(b[0] as ProgressBar).max_value = 1.0
		(b[0] as ProgressBar).fill_mode = ProgressBar.FILL_BEGIN_TO_END if side == 0 else ProgressBar.FILL_END_TO_BEGIN
		col.add_child(b[0])
		_bars.append([b[0], b[1], team])
		if side == 1:
			row.add_child(_centre_column())
		row.add_child(col)
	var bank_panel := UIStyle.panel(_centre_strip(root, 96.0), 8.0)
	bank_panel.add_theme_stylebox_override("panel", UIStyle.slate_style(8.0))
	bank_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bank_label = UIStyle.panel_label("", 16, UIStyle.GOLD)
	_bank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bank_panel.add_child(_bank_label)

	# --- buy panel (right side)
	var buy := UIStyle.panel(root, 12.0)
	buy.add_theme_stylebox_override("panel", UIStyle.frame_style(12.0))
	UIStyle.add_drop_shadow(buy)
	buy.set_anchors_preset(Control.PRESET_TOP_RIGHT)   # over the GameHUD's skirmish key help (top right)
	buy.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	buy.offset_right = -16.0
	buy.offset_left = -16.0 - PANEL_W
	buy.offset_top = 16.0
	buy.custom_minimum_size = Vector2(PANEL_W, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	buy.add_child(box)
	var title := UIStyle.use_title_font(UIStyle.label("Muster", 22))
	title.add_theme_color_override("font_color", UIStyle.token(&"title"))
	box.add_child(title)
	var ids := roster.card_ids()
	for i in ids.size():
		var b := _make_button(box)
		var idx := i
		b.gui_input.connect(func(ev: InputEvent) -> void: _on_card_input(ev, idx))
		_card_buttons.append(b)
	box.add_child(HSeparator.new())
	_coffer_button = _make_button(box)
	_coffer_button.pressed.connect(_buy_coffer)
	_tier_button = _make_button(box)
	_tier_button.pressed.connect(_buy_tier)
	_wave_label = UIStyle.panel_label("", 14)
	_wave_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_wave_label)
	var hint := UIStyle.panel_label("Click / key = buy   ·   Ctrl = rank up   ·   Alt / right-click = sell", 12)
	hint.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)


## A full-width strip at `top` px that centres its child horizontally.
func _centre_strip(parent: Control, top: float) -> Control:
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_TOP_WIDE)
	c.offset_top = top
	parent.add_child(c)
	return c


func _centre_column() -> Control:
	var c := VBoxContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size = Vector2(200, 0)
	_horn_label = UIStyle.display_label("", 26, UIStyle.GOLD)
	_horn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(_horn_label)
	_clock_label = UIStyle.panel_label("", 14)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(_clock_label)
	return c


func _make_button(parent: Control) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(PANEL_W - 24.0, 40)
	b.add_theme_font_size_override("font_size", 15)
	UIStyle.style_button(b)
	parent.add_child(b)
	return b


func _kingdom(team: int) -> StringName:
	return level.call(&"kingdom_of", team)


func _side_name(team: int) -> String:
	var k := String(_kingdom(team)).capitalize()
	return Loc.t("Your Bastion (%s)") % Loc.t(k) if team == seat else Loc.t("Enemy Bastion (%s)") % Loc.t(k)


static func _mmss(t: float) -> String:
	var s := maxi(0, ceili(t))
	return "%d:%02d" % [s / 60, s % 60]


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = REFRESH
	_refresh()


func _refresh() -> void:
	if director == null:
		return
	for b: Array in _bars:
		var ratio := float(level.call(&"bastion_ratio", int(b[2])))
		(b[0] as ProgressBar).value = ratio
		(b[1] as Label).text = "%d %%" % roundi(ratio * 100.0)
	var to_horn := director.time_to_next_horn()
	_horn_label.text = Loc.t("Horn %d in %s") % [director.horn_index + 1, _mmss(to_horn)]
	_horn_label.modulate = Color(1.0, 0.55, 0.35) if to_horn <= director.rules.horn_warning or _flash_left > 0.0 else Color.WHITE
	var clock := _mmss(director.time)
	if director.is_last_horns():
		clock += "  ·  " + Loc.t("LAST HORNS")
	_clock_label.text = clock
	# Every line goes through Loc (review 2026-10-08 M7: the French entries existed but were never used).
	_bank_label.text = Loc.t("Crystals %d   ·   +%d / horn   ·   Coffer %d/%d   ·   Supply %d/%d   ·   %s%s") % [
		bank.crystals(), bank.income(), bank.coffer_level, director.rules.coffer_prices.size(), roster.pop_used(),
		roster.cap(), Loc.t(roster.tier_name()), "" if roster.upgrade_left <= 0.0 else Loc.t(" (%s in %ds)") % [
			Loc.t(roster.tier_name(roster.tier + 1)), ceili(roster.upgrade_left)]]
	var ids := roster.card_ids()
	for i in mini(ids.size(), _card_buttons.size()):
		var id := ids[i]
		var t := UnitType.find(String(id))
		var why := roster.can_buy(id)
		var b := _card_buttons[i]
		b.text = Loc.t("[%s] %s   %d   ·  pop %d   ·  x%d") % [KeyLabels.of(CARD_KEYS[i]),
			Loc.t(t.display_name) if t else String(id), roster.price_of(id), roster.pop_of(id), roster.count(id)]
		b.modulate = Color.WHITE if why == "" else Color(1, 1, 1, 0.55)
		b.tooltip_text = (Loc.sink(why) + "\n" if why != "" else "") + _card_tip(t)
	var cp := bank.coffer_price()
	_coffer_button.text = Loc.t("[%s] Coffer %d   %s   (+%d / horn)") % [KeyLabels.of(KEY_COFFER),
		bank.coffer_level + 1, str(cp) if cp >= 0 else Loc.t("max"), director.rules.coffer_step] if cp >= 0 \
		else Loc.t("Coffers: all 8 bought")
	_coffer_button.modulate = Color.WHITE if bank.can_buy_coffer() == "" else Color(1, 1, 1, 0.55)
	_coffer_button.tooltip_text = Loc.sink(bank.can_buy_coffer())
	var tw := roster.can_upgrade()
	if roster.tier >= director.rules.max_tier:
		_tier_button.text = Loc.t("%s reached") % Loc.t(roster.tier_name())
	elif roster.upgrade_left > 0.0:
		_tier_button.text = Loc.t("%s rising: %d s") % [Loc.t(roster.tier_name(roster.tier + 1)), ceili(roster.upgrade_left)]
	else:
		_tier_button.text = Loc.t("[%s] %s   %d   (%s, supply %d)") % [KeyLabels.of(KEY_TIER),
			Loc.t(roster.tier_name(roster.tier + 1)), roster.next_tier_price(),
			Loc.t("T2 cards, Drilled") if roster.tier == 1 else Loc.t("Elite"), director.rules.cap_at(roster.tier + 1)]
	_tier_button.modulate = Color.WHITE if tw == "" else Color(1, 1, 1, 0.55)
	_tier_button.tooltip_text = Loc.sink(tw)
	_wave_label.text = Loc.t("Next wave: %d units   (last horn: %d)") % [roster.card_total(), director.last_wave_size[seat]]


static func _card_tip(t: UnitType) -> String:
	if t == null:
		return ""
	return Loc.t("%s: %d HP, %d damage, range %.1f, speed %.1f%s") % [Loc.t(t.display_name), int(t.max_hp),
		int(t.attack_damage), t.attack_range, t.move_speed, Loc.t("  (Stronghold)") if t.requires_tier >= 2 else ""]


func _on_horn(_index: int) -> void:
	_flash_left = 1.0
	_refresh()


func _on_card_input(ev: InputEvent, i: int) -> void:
	var mb := ev as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.ctrl_pressed:
			rank_card(i)
		elif mb.alt_pressed:
			sell_card(i)
		else:
			buy_card(i)
		get_viewport().set_input_as_handled()
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		sell_card(i)
		get_viewport().set_input_as_handled()


## Buys card `i` of the panel; returns "" or the reason (shown as a HUD message).
func buy_card(i: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return "No card"
	var why := roster.buy(ids[i])
	_say(why)
	_refresh()
	return why


func rank_card(i: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return "No card"
	var why := roster.rank_up(ids[i])
	_say(why)
	_refresh()
	return why


func sell_card(i: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return "No card"
	var why := roster.sell(ids[i])
	_say(why)
	_refresh()
	return why


func _buy_coffer() -> void:
	_say(bank.buy_coffer())
	_refresh()


func _buy_tier() -> void:
	_say(roster.upgrade())
	_refresh()


func _say(why: String) -> void:
	if why == "":
		return
	var gh: Node = level.get(&"hud")
	if gh and gh.has_method(&"show_message"):
		gh.call(&"show_message", why, 1.5)


## The buy keys win over the unit keys (X / C) while Wave Strike runs: lane units take no orders.
func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or bool(level.get(&"game_over")):
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	if k.meta_pressed:
		return
	var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
	var i := CARD_KEYS.find(code)
	if k.ctrl_pressed:
		if i >= 0:
			rank_card(i)
			get_viewport().set_input_as_handled()
		return
	if i >= 0:
		if k.alt_pressed:
			sell_card(i)
		else:
			buy_card(i)
		get_viewport().set_input_as_handled()
	elif code == KEY_COFFER and not k.alt_pressed:
		_buy_coffer()
		get_viewport().set_input_as_handled()
	elif code == KEY_TIER and not k.alt_pressed:
		_buy_tier()
		get_viewport().set_input_as_handled()
