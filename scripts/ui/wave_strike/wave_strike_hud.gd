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
## Muster Pad (WS3.U1 / U2, ui-wave-strike.md 7): a MusterPadView per seat in the world (tokens, grid, spawn box),
## MusterPadInput for the own pad (hover / place ghost / drag / box select / right-click sell), P = pad camera, L =
## auto-arrange, Ctrl+L = undo (5 s), Esc = cancel the ghost / selection; a buy with the cursor on the pad (or the
## `Place on buy: Manual` setting) shows the place ghost instead of auto-placing.
## Upgrades (WS4.U1, 8): Shift + card key = upgrade A, Shift+Ctrl = B, Shift+Alt = cancel (5 s); R / Y / O = Armoury.

const CARD_KEYS: Array[int] = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M, KEY_COMMA, KEY_PERIOD, KEY_SLASH]
const KEY_COFFER := KEY_G
const KEY_TIER := KEY_U
const KEY_PEEK := KEY_I
const KEY_PAD := KEY_P
const KEY_ARRANGE := KEY_L
const ARMOURY_KEYS: Array[int] = [KEY_R, KEY_Y, KEY_O]
const NO_ROOM_TIME := 2.5
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
var pad_view: MusterPadView
var enemy_pad_view: MusterPadView
var pad_input: MusterPadInput
var pad_overlay: MusterPadInput.PadOverlay
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
		var name_l := UIStyle.panel_label(_side_name(team), 15, UIStyle.team_kingdom_color(team, _kingdom(team)).lightened(0.25))
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if side == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		name_l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_name_labels.append([name_l, team])
		col.add_child(name_l)
		var b: Array = UIStyle.bar(UIStyle.team_kingdom_color(team, _kingdom(team)), 22.0)
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
	muster.armoury_pressed.connect(func(line: StringName) -> void: armoury_buy(line))
	muster.pad_pressed.connect(func() -> void: toggle_pad_camera())
	muster.arrange_pressed.connect(func() -> void: arrange_pad())
	muster.undo_pressed.connect(func() -> void: undo_arrange())
	_place_muster()
	_build_pads(root)
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


## The pad views (own + enemy, in the world) and the own pad's input + 2D overlay.
func _build_pads(root: Control) -> void:
	var rosters_all: Array = level.get(&"rosters")
	pad_view = MusterPadView.new()
	level.add_child(pad_view)
	pad_view.setup(roster, true, director)
	if rosters_all.size() > 1 - seat and 1 - seat >= 0:
		enemy_pad_view = MusterPadView.new()
		level.add_child(enemy_pad_view)
		enemy_pad_view.setup(rosters_all[1 - seat], false, director)
	pad_overlay = MusterPadInput.PadOverlay.new()
	root.add_child(pad_overlay)
	root.move_child(pad_overlay, 0)
	pad_input = MusterPadInput.new()
	add_child(pad_input)
	pad_input.setup(self, level, roster, pad_view, enemy_pad_view, pad_overlay)
	pad_overlay.input = pad_input
	muster.setup_pad(pad_view, pad_input)


func _exit_tree() -> void:
	for v: Node in [pad_view, enemy_pad_view]:
		if v != null and is_instance_valid(v) and not v.is_queued_for_deletion():
			v.queue_free()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


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
		&"up_a":
			upgrade_card(i, WaveUpgradeTable.SLOT_A)
		&"up_b":
			upgrade_card(i, WaveUpgradeTable.SLOT_B)
		&"up_cancel":
			cancel_upgrade_card(i)
		_:
			buy_card(i)


## Buys card `i` (slot 0-9) of the panel; returns "" or the reason (shown as a HUD message, the price shakes).
## An empty slot (Fire's slot 10) refuses quietly with "No card".
## With the cursor on the own pad or `Place on buy: Manual`, a buy that could happen shows the place ghost instead
## (paid on the click, 15.2); a refused one answers at once.
func buy_card(i: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return NO_CARD
	if pad_input != null and (pad_input.placing() != &"" or pad_input.wants_ghost()):
		var pre := roster.can_buy(ids[i])
		if pre == "" or pre == MusterRoster.REASON_NO_ROOM:   # no room for auto: the player may still pick a spot
			pad_input.begin_place(ids[i])
			return ""
		_after(i, pre)
		return pre
	var why := roster.buy(ids[i])
	_after(i, why)
	return why


## Card `i`'s upgrade `slot` (Shift / Shift+Ctrl + key, a pip click); "" or the reason.
func upgrade_card(i: int, slot: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return NO_CARD
	var why := roster.buy_upgrade(ids[i], slot)
	_after(i, why)
	return why


## Shift+Alt + key: takes back card `i`'s latest upgrade inside the cancel window (B first, then A).
func cancel_upgrade_card(i: int) -> String:
	var ids := roster.card_ids()
	if i < 0 or i >= ids.size():
		return NO_CARD
	var why := roster.cancel_upgrade(ids[i], WaveUpgradeTable.SLOT_B)
	if why != "":
		why = roster.cancel_upgrade(ids[i], WaveUpgradeTable.SLOT_A)
	_after(i, why)
	return why


## R / Y / O: the next level of Armoury line `line`; "" or the reason.
func armoury_buy(line: StringName) -> String:
	var why := roster.armoury_buy(line)
	_say(why)
	_refresh()
	return why


## P: the camera flies behind the own pad; again = back.
func toggle_pad_camera() -> void:
	if pad_input != null:
		pad_input.toggle_pad_camera()


## L: auto-arrange the own pad (Line).
func arrange_pad() -> void:
	if pad_input != null:
		pad_input.arrange()
		_refresh()


## Ctrl+L: undo the last arrange within 5 s; "" or the reason.
func undo_arrange() -> String:
	var why := pad_input.undo_arrange() if pad_input != null else "Nothing to undo"
	_refresh()
	return why


## A pad action refused for card `id` (the pad input calls it): the card shakes, the message line says why.
func refuse_card(id: StringName, why: String) -> void:
	var i := roster.card_ids().find(id)
	_after(i, why)


## The pad changed from a pad action (drop, sell): the panel refreshes now.
func after_pad_change() -> void:
	_refresh()


## A message on the HUD line (pad / arrange messages).
func say(text: String, _col := Color.WHITE, seconds := 2.5) -> void:
	var gh: Node = level.get(&"hud")
	if gh and gh.has_method(&"show_message"):
		gh.call(&"show_message", text, seconds)


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
	if why != "" and muster != null and i >= 0:
		muster.refuse(i)
	if why == MusterRoster.REASON_NO_ROOM:
		say(Loc.t("No room on the pad  ·  %s = auto-arrange") % KeyLabels.of(KEY_ARRANGE), UIStyle.WARN, NO_ROOM_TIME)
		if muster != null and muster.mini_pad != null:
			muster.mini_pad.flash()
	else:
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
	# 8.4 precedence: Shift+Ctrl > Shift+Alt > Shift > Ctrl > Alt > plain
	if i >= 0:
		if k.shift_pressed and k.ctrl_pressed:
			upgrade_card(i, WaveUpgradeTable.SLOT_B)
		elif k.shift_pressed and k.alt_pressed:
			cancel_upgrade_card(i)
		elif k.shift_pressed:
			upgrade_card(i, WaveUpgradeTable.SLOT_A)
		elif k.ctrl_pressed:
			rank_card(i)
		elif k.alt_pressed:
			sell_card(i)
		else:
			buy_card(i)
		get_viewport().set_input_as_handled()
		return
	if code == KEY_ESCAPE and pad_input != null and pad_input.cancel():
		get_viewport().set_input_as_handled()
		return
	if code == KEY_ARRANGE and not k.alt_pressed and not k.shift_pressed:
		if k.ctrl_pressed:
			var why := undo_arrange()
			if why != "":
				_say(why)
		else:
			arrange_pad()
		get_viewport().set_input_as_handled()
		return
	if k.ctrl_pressed or k.shift_pressed:
		return
	var a := ARMOURY_KEYS.find(code)
	if a >= 0 and not k.alt_pressed and roster.upgrades != null and a < roster.upgrades.armoury_order.size():
		armoury_buy(roster.upgrades.armoury_order[a])
		get_viewport().set_input_as_handled()
	elif code == KEY_PAD and not k.alt_pressed:
		toggle_pad_camera()
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
