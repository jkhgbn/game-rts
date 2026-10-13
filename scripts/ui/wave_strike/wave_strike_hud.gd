class_name WaveStrikeHud
extends CanvasLayer
## Wave Strike HUD (docs/design/wave-strike.md 7.4 / 14.4, ui-wave-strike.md; M1 task WS.U1, M2 task WS2.U1): the top
## strip (both Bastion HP bars, horn countdown with its ring, match clock, the bank line) and the Muster panel
## (`MusterPanel`, 10 cards in T1 / T2 / T3 groups, Coffer, next tier, field counter) inside the SC2 console's
## `zone_rect(&"muster")` (the skirmish selection block, portrait and command card are hidden), plus the enemy roster
## peek (I, or hover the enemy Bastion bar).
## Keys (physical; KeyLabels prints the AZERTY letters): the bottom row Z X C V B N M , . / = cards 1-10, G = Coffer,
## U = next tier, I = enemy roster; Ctrl + a card key (or Ctrl+click) = rank the line up; Alt + a card key (or
## Alt+click / right-click) = sell one. Over the main GameHUD (its top bar and objective are hidden).

const CARD_KEYS: Array[int] = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M, KEY_COMMA, KEY_PERIOD, KEY_SLASH]
const KEY_COFFER := KEY_G
const KEY_TIER := KEY_U
const KEY_PEEK := KEY_I
const REFRESH := 0.1
const NO_CARD := "No card"

var level: Node                     ## WaveStrikeLevel
var seat := 0
var roster: MusterRoster
var bank: WaveBank
var director: WaveDirector

var _bars: Array = []               ## [[ProgressBar, Label], ...] per team (0 = own side drawn left)
var _horn_label: Label
var _clock_label: Label
var _bank_label: Label
var muster: MusterPanel
var enemy_peek: EnemyRosterPeek
var top_ring: HornRing
var _refresh_left := 0.0
var _flash_left := 0.0
var _name_labels: Array = []          ## U5-7: [[Label, team], ...] side names, rebuilt on a language switch


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
		if gh.has_method(&"set_skirmish_console_visible"):   # WS2.U1: the Muster panel takes the console's zones
			gh.call(&"set_skirmish_console_visible", false)
		var con: Variant = gh.get(&"console")
		if con is ConsoleFrame:
			(con as ConsoleFrame).set_muster_mode(true)
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
		var name_l := UIStyle.panel_label(_side_name(team), 15, UIStyle.kingdom_color(_kingdom(team)).lightened(0.25))
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if side == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		name_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_name_labels.append([name_l, team])
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

	# --- Muster panel (in the console's muster zone) and the enemy roster peek
	muster = MusterPanel.new()
	root.add_child(muster)
	muster.setup(level, roster, bank, director, CARD_KEYS)
	muster.card_action.connect(_on_card_action)
	muster.coffer_pressed.connect(func() -> void: buy_coffer())
	muster.tier_pressed.connect(func() -> void: buy_tier())
	_place_muster()
	var other: Array = level.get(&"rosters")
	enemy_peek = EnemyRosterPeek.new()
	if other.size() > 1 - seat and 1 - seat >= 0:
		enemy_peek.setup(level, other[1 - seat], director)
	root.add_child(enemy_peek)
	for b: Array in _bars:
		if int(b[2]) != seat:
			var bar := b[0] as ProgressBar
			bar.mouse_filter = Control.MOUSE_FILTER_PASS
			bar.mouse_entered.connect(func() -> void: enemy_peek.hovered = true)
			bar.mouse_exited.connect(func() -> void: enemy_peek.hovered = false)


## The Muster panel fills the console's muster zone (ui-sc2-console.md 6); without a console: the same rect from the
## bottom of the screen.
func _place_muster() -> void:
	if muster == null:
		return
	var r := Rect2()
	var gh: Node = level.get(&"hud")
	var con: Variant = gh.get(&"console") if gh else null
	if con is ConsoleFrame and is_instance_valid(con) and (con as ConsoleFrame).is_inside_tree():
		r = (con as ConsoleFrame).zone_rect(&"muster")
	if r.size.x <= 0.0:
		var vp := muster.get_viewport_rect().size if muster.is_inside_tree() else Vector2(1600, 900)
		r = Rect2(244, vp.y - 208.0, vp.x - 256.0, 200.0)
	if muster.position != r.position or muster.size != r.size:
		muster.position = r.position
		muster.size = r.size


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
	var hrow := HBoxContainer.new()
	hrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hrow.alignment = BoxContainer.ALIGNMENT_CENTER
	hrow.add_theme_constant_override("separation", 8)
	c.add_child(hrow)
	top_ring = HornRing.new(36.0)
	hrow.add_child(top_ring)
	_horn_label = UIStyle.display_label("", 26, UIStyle.GOLD)
	_horn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hrow.add_child(_horn_label)
	_clock_label = UIStyle.panel_label("", 14)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(_clock_label)
	return c


func _kingdom(team: int) -> StringName:
	return level.call(&"kingdom_of", team)


func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED:
		return
	for row: Array in _name_labels:
		if is_instance_valid(row[0]):
			(row[0] as Label).text = _side_name(int(row[1]))


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
	var to_h := director.time_to_next_horn()
	var interval := director.next_horn_time() - (director.rules.horn_time(director.horn_index) if director.horn_index > 0 else 0.0)
	top_ring.set_state(to_h / maxf(1.0, interval), to_h <= director.rules.horn_warning, director.is_last_horns())
	_place_muster()
	muster.refresh()


func _on_horn(_index: int) -> void:
	_flash_left = 1.0
	top_ring.burst()
	muster.on_horn()
	_refresh()


func _on_card_action(i: int, kind: StringName) -> void:
	match kind:
		&"rank":
			rank_card(i)
		&"sell":
			sell_card(i)
		_:
			buy_card(i)


## Buys card `i` (slot 0-9) of the panel; returns "" or the reason (shown as a HUD message, the price shakes).
## An empty slot (Fire's slot 10) refuses quietly with "No card".
func buy_card(i: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return NO_CARD
	var why := roster.buy(ids[i])
	_after(i, why)
	return why


func rank_card(i: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return NO_CARD
	var why := roster.rank_up(ids[i])
	_after(i, why)
	return why


func sell_card(i: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return NO_CARD
	var why := roster.sell(ids[i])
	_after(i, why)
	return why


func _after(i: int, why: String) -> void:
	if why != "" and muster != null:
		muster.refuse(i)
	_say(why)
	_refresh()


## Buys the next Coffer (G); "" or the reason.
func buy_coffer() -> String:
	var why := bank.buy_coffer()
	_say(why)
	_refresh()
	return why


## Starts the next tier (U); "" or the reason.
func buy_tier() -> String:
	var why := roster.upgrade()
	_say(why)
	_refresh()
	return why


## Shows / hides the enemy roster peek (I).
func toggle_enemy_peek() -> void:
	if enemy_peek != null:
		enemy_peek.toggle()


func _say(why: String) -> void:
	if why == "":
		return
	var gh: Node = level.get(&"hud")
	if gh and gh.has_method(&"show_message"):
		gh.call(&"show_message", why, 1.5)


## The buy keys win over the unit keys (X / C / B / G...) while Wave Strike runs: lane units take no orders.
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
		buy_coffer()
		get_viewport().set_input_as_handled()
	elif code == KEY_TIER and not k.alt_pressed:
		buy_tier()
		get_viewport().set_input_as_handled()
	elif code == KEY_PEEK and not k.alt_pressed:
		toggle_enemy_peek()
		get_viewport().set_input_as_handled()
