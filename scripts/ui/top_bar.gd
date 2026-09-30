class_name TopBar
extends PanelContainer
## Top-centre bar: crystals and population `used / cap` of the player's Economy (spec: ui-hud.md, 1.U1),
## plus the match timer when the level has one (skirmish-1v1.md).
## Finds the Economy through the group "economies" (team 0), so it works whenever the economy appears.
## Pop turns red at the cap; a failed spend flashes the crystal number red and sends `message`.
## Essence (items.md, 4.U1a): 4th item, a purple flame + the number, from `EssenceBank.for_team(0)`
## (found untyped, so the bar works before the items code exists); the bar is then 520 x 40 at (540, 8).
## Gold (market-trade.md 3.3, ui-trade.md 3, task 10.C8): 5th item, a coin + the number in GOLD_TEXT, shown only
## while the player's team has a GoldBank (group "gold_banks": trade on); the bar is then 644 x 40 at (478, 8)
## (spec 624 x 40 at (488, 8) + POP_EXTRA).
## A failed gold spend flashes the number WARN 0.4 s + shake + "Not enough gold"; a rise of 10+ pops the number.

signal message(text: String)

## Pop cap 200 (2026-09-27): the pop number is 100 px wide ("200 / 200", was 80), so every bar width is 20 px over
## the ui-hud.md / ui-trade.md numbers. Sized here, not left to the row's content, so the bar keeps whole-pixel,
## centred rects (content-driven growth centred it at x .5).
const POP_EXTRA := 20.0
const SIZE := Vector2(320 + POP_EXTRA, 40)          ## 340 x 40 at (630, 8) (spec 320 + POP_EXTRA).
const TIMER_SIZE := Vector2(400 + POP_EXTRA, 40)    ## With the match timer (skirmish-1v1.md): 420 x 40 at (590, 8).
const ESSENCE_EXTRA := 100.0           ## Essence adds 100 px: 520 x 40 at (540, 8) with the timer.
const GOLD_EXTRA := 124.0              ## Gold adds 124 px (gap 32 + 8 + coin 16 + 8 + number 60): 644 x 40 at (478, 8).
const GOLD_TEXT_COLOR := Color(1.0, 0.88, 0.5)
const GOLD_POP_RISE := 10              ## A rise of this much between two polls pops the number.
const GOLD_POP_TIME := 0.2
const ESSENCE_ICON_COLOR := Color(0.75, 0.45, 1.0)
const ESSENCE_TEXT_COLOR := Color(0.9, 0.8, 1.0)
const CRYSTAL_ICON_COLOR := Color(0.45, 0.85, 1.0)
const CRYSTAL_TEXT_COLOR := Color(0.75, 0.92, 1.0)
const FLASH_TIME := 0.4
const PLAYER_TEAM := 0

var economy: Node = null
var crystals_label: Label
var pop_label: Label
var timer_label: Label     ## Match time m:ss (skirmish only).
var essence_bank: Object = null
var essence_label: Label

var gold_bank: Object = null   ## The player's GoldBank (null = trade off: the gold item is hidden).
var gold_label: Label

var _essence_items: Array[Control] = []
var _essence_flash_left := 0.0
var _essence_search_left := 0.0
var _gold_items: Array[Control] = []
var _gold_flash_left := 0.0
var _gold_search_left := 0.0
var _gold_pop_left := 0.0
var _last_gold := -1

var _timer_gap: Control
var _hourglass: HBoxContainer   ## Hourglass icon + timer_label.
var _muted: Array[Label] = []
var _shake_tweens := {}
var _flash_left := 0.0
var _search_left := 0.0


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())   # the chamfered slab is drawn in _draw
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Top-centre, 8 px from the top.
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_left = -SIZE.x * 0.5
	offset_right = SIZE.x * 0.5
	offset_top = 8.0
	offset_bottom = 8.0 + SIZE.y

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	var icon := Control.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.draw.connect(func() -> void:
		icon.draw_colored_polygon(PackedVector2Array([
			Vector2(8, 0), Vector2(16, 8), Vector2(8, 16), Vector2(0, 8)]), CRYSTAL_ICON_COLOR)
		icon.draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(8, 8), Vector2(0, 8)]),
				Color(0.75, 0.95, 1.0)))
	row.add_child(icon)
	crystals_label = UIStyle.number_label("--", 20)
	crystals_label.custom_minimum_size = Vector2(70, 0)
	crystals_label.add_theme_color_override("font_color", CRYSTAL_TEXT_COLOR)
	crystals_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(crystals_label)

	row.add_child(_separator())   # 48 px between items, minus the two separations

	var pop_icon := UIStyle.panel_label("POP", 12)
	_muted.append(pop_icon)
	pop_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pop_icon)
	pop_label = UIStyle.number_label("-- / --", 20)
	pop_label.custom_minimum_size = Vector2(100, 0)   # room for "200 / 200"
	pop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pop_label)

	# Match timer (skirmish only): 48 px after the pop item, the panel widens to 400.
	_timer_gap = _separator()
	_timer_gap.visible = false
	row.add_child(_timer_gap)
	# Timer item: a 12 px hourglass right before the digits (2 px apart), in one box.
	_hourglass = HBoxContainer.new()
	_hourglass.add_theme_constant_override("separation", 2)
	_hourglass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hourglass.visible = false
	row.add_child(_hourglass)
	var glass := Control.new()
	glass.custom_minimum_size = Vector2(12, 12)
	glass.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glass.draw.connect(func() -> void:
		var col := UIStyle.token(&"text_muted")
		glass.draw_colored_polygon(PackedVector2Array([Vector2(1, 0), Vector2(11, 0), Vector2(6, 6)]), col)
		glass.draw_colored_polygon(PackedVector2Array([Vector2(6, 6), Vector2(11, 12), Vector2(1, 12)]), col))
	_hourglass.add_child(glass)
	timer_label = UIStyle.number_label("0:00", 20)
	timer_label.custom_minimum_size = Vector2(56, 0)
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.visible = false
	_hourglass.add_child(timer_label)

	# Essence (4th item, 48 px after the timer): 16 px purple flame + the number, font 20.
	var essence_gap := _separator()
	row.add_child(essence_gap)
	var flame := Control.new()
	flame.custom_minimum_size = Vector2(16, 16)
	flame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flame.draw.connect(func() -> void:
		flame.draw_colored_polygon(PackedVector2Array([
			Vector2(8, 0), Vector2(13, 7), Vector2(14, 11), Vector2(11, 15), Vector2(5, 15),
			Vector2(2, 11), Vector2(3, 7), Vector2(6, 9)]), ESSENCE_ICON_COLOR)
		flame.draw_colored_polygon(PackedVector2Array([Vector2(8, 7), Vector2(10, 11), Vector2(9, 14),
				Vector2(7, 14), Vector2(6, 11)]), Color(0.95, 0.80, 1.0)))
	row.add_child(flame)
	essence_label = UIStyle.number_label("--", 20)
	essence_label.custom_minimum_size = Vector2(52, 0)
	essence_label.add_theme_color_override("font_color", ESSENCE_TEXT_COLOR)
	essence_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(essence_label)
	_essence_items = [essence_gap, flame, essence_label]
	for c in _essence_items:
		c.visible = false

	# Gold (5th item, 48 px after essence): 16 px coin + the number, font 20 GOLD_TEXT (ui-trade.md 3.1).
	var gold_gap := _separator()
	row.add_child(gold_gap)
	var coin := Control.new()
	coin.custom_minimum_size = Vector2(16, 16)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.draw.connect(func() -> void: TradeWindow.draw_coin(coin, Vector2(8, 8), 8.0))
	row.add_child(coin)
	gold_label = UIStyle.number_label("--", 20)
	# 55, not the spec's 60: the row's 3 separations make the item 5 px wider than GOLD_EXTRA counts, and the bar
	# must stay 644 wide (`2 140` = 52 px fits; wider numbers grow the bar, which recentres).
	gold_label.custom_minimum_size = Vector2(55, 0)
	gold_label.add_theme_color_override("font_color", GOLD_TEXT_COLOR)
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(gold_label)
	_gold_items = [gold_gap, coin, gold_label]
	for c in _gold_items:
		c.visible = false


## A 32 px gap with a 1 px frame_dark line, 20 px tall, in its centre (ui-style.md 4.1).
func _separator() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(48 - 16, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.draw.connect(func() -> void:
		var x := floorf(gap.size.x * 0.5) + 0.5
		var y := gap.size.y * 0.5
		gap.draw_line(Vector2(x, y - 10), Vector2(x, y + 10), UIStyle.token(&"frame_dark"), 1.0))
	return gap


## Re-applies the kingdom skin (GameHUD.setup calls it after UIStyle.set_kingdom).
func apply_skin() -> void:
	for l in _muted:
		l.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	refresh()
	queue_redraw()


## The chamfered slab: 45 degree ends cut by 12 px, panel_bg fill, 2 px frame_metal outline with a frame_light
## top edge, and a 1 px trim_glow line 3 px under the top edge.
func _draw() -> void:
	var w := size.x
	var h := size.y
	var ch := 12.0
	var pts := PackedVector2Array([Vector2(ch, 0), Vector2(w - ch, 0), Vector2(w, ch), Vector2(w, h - ch),
			Vector2(w - ch, h), Vector2(ch, h), Vector2(0, h - ch), Vector2(0, ch)])
	draw_colored_polygon(pts, UIStyle.token(&"panel_bg"))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, UIStyle.token(&"frame_metal"), 2.0, true)
	draw_line(Vector2(ch, 1), Vector2(w - ch, 1), UIStyle.token(&"frame_light"), 2.0)
	var g := UIStyle.token(&"trim_glow")
	draw_line(Vector2(ch - 1, 3.5), Vector2(w - ch + 1, 3.5), Color(g.r, g.g, g.b, 0.55), 1.0)


## Failed spend: the number shakes +-4 px, 3 cycles in 0.3 s.
func shake(l: Label) -> void:
	var old: Tween = _shake_tweens.get(l)
	if old and old.is_valid():
		old.kill()
	var t := create_tween()
	_shake_tweens[l] = t
	var steps := 12
	var base := l.position.x
	for i in steps:
		var off := 4.0 * sin(TAU * 3.0 * float(i + 1) / steps)
		t.tween_property(l, "position:x", base + off, 0.3 / steps)
	t.tween_property(l, "position:x", base, 0.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


## The level's match clock ("m:ss") when it has one (skirmish.gd), shown as the third item.
func _update_timer() -> void:
	var level := get_tree().current_scene
	var has_timer := level != null and level.has_method(&"match_time_text")
	var has_essence := essence_bank != null
	var has_gold := gold_bank != null
	if has_timer != timer_label.visible or has_essence != essence_label.visible or has_gold != gold_label.visible:
		timer_label.visible = has_timer
		_timer_gap.visible = has_timer
		_hourglass.visible = has_timer
		for c in _essence_items:
			c.visible = has_essence
		for c in _gold_items:
			c.visible = has_gold
		var w := (TIMER_SIZE.x if has_timer else SIZE.x) + (ESSENCE_EXTRA if has_essence else 0.0) \
				+ (GOLD_EXTRA if has_gold else 0.0)
		custom_minimum_size = Vector2(w, SIZE.y)
		offset_left = -w * 0.5
		offset_right = w * 0.5
	if has_timer:
		timer_label.text = str(level.call(&"match_time_text"))


func _process(delta: float) -> void:
	_update_essence(delta)
	_update_gold(delta)
	_update_timer()
	if economy == null or not is_instance_valid(economy):
		economy = null
		_search_left -= delta
		if _search_left <= 0.0:
			_search_left = 0.25
			_find_economy()
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			crystals_label.add_theme_color_override("font_color", CRYSTAL_TEXT_COLOR)


## Uses this economy (normally found by itself from the group "economies").
func set_economy(e: Node) -> void:
	if economy == e:
		return
	economy = e
	if e == null:
		return
	_connect_signal(e, &"changed", refresh)
	_connect_signal(e, &"spend_failed", flash_not_enough)
	refresh()


func refresh() -> void:
	if economy == null or not is_instance_valid(economy):
		return
	crystals_label.text = str(int(economy.get("crystals")))
	var used := int(economy.get("pop_used"))
	var cap := int(economy.get("pop_cap"))
	pop_label.text = "%d / %d" % [used, cap]   # pop_cap already holds the team's cap (up to 200)
	pop_label.add_theme_color_override("font_color", UIStyle.WARN if used >= cap else UIStyle.token(&"text"))


## Failed spend: the crystal number flashes red for 0.4 s and "Not enough crystals" is shown.
func flash_not_enough() -> void:
	_flash_left = FLASH_TIME
	crystals_label.add_theme_color_override("font_color", UIStyle.WARN)
	shake(crystals_label)
	message.emit("Not enough crystals")


func is_flashing() -> bool:
	return _flash_left > 0.0


## Keeps the essence number live (polls `essence`, so it works whatever `changed` carries) and ends the flash.
func _update_essence(delta: float) -> void:
	if essence_bank != null and not is_instance_valid(essence_bank):
		essence_bank = null
	if essence_bank == null:
		_essence_search_left -= delta
		if _essence_search_left <= 0.0:
			_essence_search_left = 0.5
			set_essence_bank(find_essence_bank(get_tree(), PLAYER_TEAM))
		return
	essence_label.text = str(int(essence_bank.get("essence")))
	if _essence_flash_left > 0.0:
		_essence_flash_left -= delta
		if _essence_flash_left <= 0.0:
			essence_label.add_theme_color_override("font_color", ESSENCE_TEXT_COLOR)


func set_essence_bank(bank: Object) -> void:
	if bank == essence_bank:
		return
	essence_bank = bank
	if bank == null:
		return
	_connect_signal(bank, &"spend_failed", flash_not_enough_essence)
	essence_label.text = str(int(bank.get("essence")))


## Failed `spend` / `spend_essence`: the essence number flashes red 0.4 s + "Not enough essence".
func flash_not_enough_essence() -> void:
	_essence_flash_left = FLASH_TIME
	essence_label.add_theme_color_override("font_color", UIStyle.WARN)
	shake(essence_label)
	message.emit("Not enough essence")


func is_essence_flashing() -> bool:
	return _essence_flash_left > 0.0


## Keeps the gold number live (polls `gold`), pops it on a rise of 10+, ends the flash. Retries the bank lookup
## every 0.5 s while there is none (the skirmish creates the banks when trade is on).
func _update_gold(delta: float) -> void:
	if gold_bank != null and (not is_instance_valid(gold_bank) or (gold_bank as Node).is_queued_for_deletion()):
		gold_bank = null
	if gold_bank == null:
		_gold_search_left -= delta
		if _gold_search_left <= 0.0:
			_gold_search_left = 0.5
			set_gold_bank(TradeWindow.gold_bank_of(get_tree(), PLAYER_TEAM))
		return
	var g := int(gold_bank.get("gold"))
	gold_label.text = TradeWindow.thousands(g)
	if _last_gold >= 0 and g >= _last_gold + GOLD_POP_RISE:
		_gold_pop_left = GOLD_POP_TIME
	_last_gold = g
	if _gold_pop_left > 0.0:
		_gold_pop_left = maxf(_gold_pop_left - delta, 0.0)
		gold_label.pivot_offset = gold_label.size * 0.5
		var s := 1.0 + 0.15 * sin(PI * (1.0 - _gold_pop_left / GOLD_POP_TIME))
		gold_label.scale = Vector2(s, s)
	if _gold_flash_left > 0.0:
		_gold_flash_left -= delta
		if _gold_flash_left <= 0.0:
			gold_label.add_theme_color_override("font_color", GOLD_TEXT_COLOR)


## Uses this GoldBank (normally found by itself from the group "gold_banks"); null hides the gold item.
func set_gold_bank(bank: Object) -> void:
	if bank == gold_bank:
		return
	gold_bank = bank
	_last_gold = -1
	if bank == null:
		return
	_connect_signal(bank, &"spend_failed", flash_not_enough_gold)
	gold_label.text = TradeWindow.thousands(int(bank.get("gold")))


## Failed gold spend: the gold number flashes red 0.4 s, shakes, and "Not enough gold" is shown.
func flash_not_enough_gold() -> void:
	_gold_flash_left = FLASH_TIME
	gold_label.add_theme_color_override("font_color", UIStyle.WARN)
	shake(gold_label)
	message.emit("Not enough gold")


func is_gold_flashing() -> bool:
	return _gold_flash_left > 0.0


## True while the gold number is popping (a delivery or any rise of 10+).
func is_gold_popping() -> bool:
	return _gold_pop_left > 0.0


## `EssenceBank.for_team(team)` looked up by class name (the items code may not exist yet), then a node
## in group "essence_banks", then an Economy that carries `essence` (items.md's first draft).
static func find_essence_bank(tree: SceneTree, team: int) -> Object:
	for info in ProjectSettings.get_global_class_list():
		if str(info.get("class", "")) == "EssenceBank":
			var script: Variant = load(str(info.get("path", "")))
			if script is Script and (script as Script).get_script_method_list().any(
					func(m: Dictionary) -> bool: return str(m.get("name", "")) == "for_team"):
				var bank: Variant = (script as Script).call(&"for_team", team)
				if bank is Object and bank != null:
					return bank
			break
	if tree == null:
		return null
	for b in tree.get_nodes_in_group(&"essence_banks"):
		if int(b.get("team")) == team:
			return b
	for e in tree.get_nodes_in_group(&"economies"):
		if int(e.get("team")) == team and e.get("essence") != null:
			return e
	return null


func _find_economy() -> void:
	for e in get_tree().get_nodes_in_group("economies"):
		if int(e.get("team")) == PLAYER_TEAM:
			set_economy(e)
			return


## Connects whatever the signal's argument count is (the callback takes none).
func _connect_signal(obj: Object, signal_name: StringName, callback: Callable) -> void:
	if not obj.has_signal(signal_name):
		return
	var arg_count := 0
	for s in obj.get_signal_list():
		if s["name"] == signal_name:
			arg_count = (s["args"] as Array).size()
	var c := callback.unbind(arg_count) if arg_count > 0 else callback
	if not obj.is_connected(signal_name, c):
		obj.connect(signal_name, c)
