class_name TopBar
extends PanelContainer
## The resources, top-right (docs/design/ui-sc2-console.md 2, task SC2.U2; was the top-centre bar of ui-hud.md 1.U1):
## one slate item per resource, 96 x 32 each (the pop item grows for "200 / 200"), right edge at x 1592, y 8 at
## 1600 x 900, in the order crystals, essence (EssenceBank.for_team(0), found untyped), gold (only while the player's
## team has a GoldBank: trade on), pop `12 / 20`. Each item: a 16 px icon + the number (font 20); hover = what it is.
## Finds the Economy through the group "economies" (team 0), so it works whenever the economy appears.
## Pop at the cap: the number in WARN; a refused spend at the cap (or flash_supply_blocked) pulses the pop item's
## border WARN (alpha 0.4-0.9, 2 Hz) for 3 s, the "supply-blocked flash". A failed spend flashes the crystal number red,
## shakes it and sends `message` ("Not enough crystals"); the same for essence and gold. A gold rise of 10+ pops it.
## The match clock (skirmish-1v1.md) is `clock_box` (hourglass + `timer_label`): the HUD shows it in the console's
## quick row (ui-sc2-console.md 3.3), this bar only keeps it up to date.

signal message(text: String)

## Item size (the pop item may grow), the bar's top-right corner at 1600 x 900.
const ITEM_SIZE := Vector2(96, 32)
const RIGHT := 8.0
const TOP := 8.0
## Kept for the tests' notes (2026-09-27: pop cap 200, "200 / 200").
const POP_EXTRA := 20.0
const SIZE := Vector2(ITEM_SIZE.x * 2.0, ITEM_SIZE.y)
const GOLD_TEXT_COLOR := Color(1.0, 0.88, 0.5)
const GOLD_POP_RISE := 10              ## A rise of this much between two polls pops the number.
const GOLD_POP_TIME := 0.2
const ESSENCE_ICON_COLOR := Color(0.75, 0.45, 1.0)
const ESSENCE_TEXT_COLOR := Color(0.9, 0.8, 1.0)
const CRYSTAL_ICON_COLOR := Color(0.45, 0.85, 1.0)
const CRYSTAL_TEXT_COLOR := Color(0.75, 0.92, 1.0)
const FLASH_TIME := 0.4
const SUPPLY_FLASH_TIME := 3.0          ## The supply-blocked border pulse lasts this long ...
const SUPPLY_FLASH_HZ := 2.0            ## ... at this rate, alpha 0.4 -> 0.9.
const MSG_POP_CAP := "Population cap reached"
const PLAYER_TEAM := 0

var economy: Node = null
var crystals_label: Label
var pop_label: Label
var timer_label: Label     ## Match time m:ss (skirmish only), inside clock_box.
var clock_box: HBoxContainer   ## Hourglass + timer_label (the HUD puts it in the quick row).
var essence_bank: Object = null
var essence_label: Label

var gold_bank: Object = null   ## The player's GoldBank (null = trade off: the gold item is hidden).
var gold_label: Label

var _row: HBoxContainer
var _crystal_item: PanelContainer
var _essence_item: PanelContainer
var _gold_item: PanelContainer
var _pop_item: PanelContainer
var _essence_flash_left := 0.0
var _essence_search_left := 0.0
var _gold_flash_left := 0.0
var _gold_search_left := 0.0
var _gold_pop_left := 0.0
var _last_gold := -1
var _supply_flash_left := 0.0
var _supply_t := 0.0

var _muted: Array[Label] = []
var _shake_tweens := {}
var _shake_base := {}   ## U4-4: label -> its rest x before the first running shake
static var _essence_script: Script = null   ## U4-5: EssenceBank's script (for_team), looked up once.
static var _essence_script_checked := false   ## U4-5: true once the class list was walked
var _flash_left := 0.0
var _search_left := 0.0


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())   # no slab: each item is its own slate
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Top-right, 8 px from the right and top edges; grows to the left.
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -RIGHT
	offset_left = -RIGHT - SIZE.x
	offset_top = TOP
	offset_bottom = TOP + ITEM_SIZE.y

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_END
	_row.add_theme_constant_override("separation", 0)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)

	var crystal := _icon(func(c: Control) -> void:
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(8, 0), Vector2(16, 8), Vector2(8, 16), Vector2(0, 8)]), CRYSTAL_ICON_COLOR)
		c.draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(8, 8), Vector2(0, 8)]),
				Color(0.75, 0.95, 1.0)))
	crystals_label = UIStyle.number_label("--", 20)
	crystals_label.add_theme_color_override("font_color", CRYSTAL_TEXT_COLOR)
	_crystal_item = _item(crystal, crystals_label, "Crystals: mined by workers")

	var flame := _icon(func(c: Control) -> void:
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(8, 0), Vector2(13, 7), Vector2(14, 11), Vector2(11, 15), Vector2(5, 15),
			Vector2(2, 11), Vector2(3, 7), Vector2(6, 9)]), ESSENCE_ICON_COLOR)
		c.draw_colored_polygon(PackedVector2Array([Vector2(8, 7), Vector2(10, 11), Vector2(9, 14),
				Vector2(7, 14), Vector2(6, 11)]), Color(0.95, 0.80, 1.0)))
	essence_label = UIStyle.number_label("--", 20)
	essence_label.add_theme_color_override("font_color", ESSENCE_TEXT_COLOR)
	_essence_item = _item(flame, essence_label, "Essence: +1 per second and from kills; buys items, champions and spells")
	_essence_item.visible = false
	essence_label.visible = false

	var coin := _icon(func(c: Control) -> void: TradeWindow.draw_coin(c, Vector2(8, 8), 8.0))
	gold_label = UIStyle.number_label("--", 20)
	gold_label.add_theme_color_override("font_color", GOLD_TEXT_COLOR)
	_gold_item = _item(coin, gold_label, "Gold: brought home by caravans; spent at the Bazaar")
	_gold_item.visible = false
	gold_label.visible = false

	var shield := _icon(func(c: Control) -> void: draw_pop_icon(c, Vector2.ZERO, 16.0, UIStyle.token(&"text_muted")))
	pop_label = UIStyle.number_label("-- / --", 20)
	# Room for "200 / 200" (pop cap 200) from the start: the pop item is wider than 96, the bar never jumps.
	var pf := pop_label.get_theme_font(&"font")
	if pf != null:
		pop_label.custom_minimum_size.x = ceilf(pf.get_string_size("200 / 200", HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x) + 1.0
	_pop_item = _item(shield, pop_label, "Population: used / cap. Build houses to raise the cap")

	# The match clock (skirmish only): a 12 px hourglass right before the digits; the HUD shows it in the quick row.
	clock_box = HBoxContainer.new()
	clock_box.name = "Clock"
	clock_box.add_theme_constant_override("separation", 3)
	clock_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_box.visible = false
	var glass := Control.new()
	glass.custom_minimum_size = Vector2(10, 12)
	glass.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.draw.connect(func() -> void:
		var col := UIStyle.token(&"text_muted")
		glass.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(5, 6)]), col)
		glass.draw_colored_polygon(PackedVector2Array([Vector2(5, 6), Vector2(10, 12), Vector2(0, 12)]), col))
	clock_box.add_child(glass)
	timer_label = UIStyle.number_label("0:00", 16)
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.visible = false
	clock_box.add_child(timer_label)
	_fit()


## A 16 x 16 icon control drawn by `painter(control)`.
func _icon(painter: Callable) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(16, 16)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(painter.bind(c))
	return c


## One resource item: a slate 96 x 32 (min), the icon + the number, its hover text.
func _item(icon: Control, number: Label, tip: String) -> PanelContainer:
	var item := PanelContainer.new()
	item.custom_minimum_size = ITEM_SIZE
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.tooltip_text = tip
	item.add_theme_stylebox_override("panel", _item_style(Color(0, 0, 0, 0)))
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(box)
	box.add_child(icon)
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(number)
	_row.add_child(item)
	return item


func _item_style(border: Color) -> StyleBoxFlat:
	var st := UIStyle.slate_style(0.0, border)
	st.content_margin_left = 8.0
	st.content_margin_right = 8.0
	st.content_margin_top = 2.0
	st.content_margin_bottom = 2.0
	return st


## The pop glyph: a small shield (the cost line's "Pop" icon too), `s` px at `o`.
static func draw_pop_icon(ci: CanvasItem, o: Vector2, s: float, col: Color) -> void:
	var k := s / 16.0
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(2, 1) * k, o + Vector2(14, 1) * k, o + Vector2(14, 8) * k,
			o + Vector2(8, 15) * k, o + Vector2(2, 8) * k]), col)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(8, 3) * k, o + Vector2(12, 3) * k, o + Vector2(12, 8) * k,
			o + Vector2(8, 12.5) * k]), Color(col, 0.45))


## Re-applies the kingdom skin (GameHUD.setup calls it after UIStyle.set_kingdom).
func apply_skin() -> void:
	for l in _muted:
		l.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	for item: PanelContainer in [_crystal_item, _essence_item, _gold_item, _pop_item]:
		if item != null:
			item.add_theme_stylebox_override("panel", _item_style(Color(0, 0, 0, 0)))
	refresh()
	queue_redraw()


## The bar's width follows the shown items (it stays right-anchored at x 1592).
func _fit() -> void:
	var w := 0.0
	for item: PanelContainer in [_crystal_item, _essence_item, _gold_item, _pop_item]:
		if item.visible:
			w += maxf(ITEM_SIZE.x, item.get_combined_minimum_size().x)
	custom_minimum_size = Vector2(w, ITEM_SIZE.y)
	offset_left = -RIGHT - w
	offset_right = -RIGHT


## Failed spend: the number shakes +-4 px, 3 cycles in 0.3 s.
func shake(l: Label) -> void:
	var old: Tween = _shake_tweens.get(l)
	var base := l.position.x
	if old and old.is_valid():
		old.kill()
		base = float(_shake_base.get(l, base))   # U4-4: a shake over a shake starts from the rest spot (no drift)
	_shake_base[l] = base
	var t := create_tween()
	_shake_tweens[l] = t
	var steps := 12
	for i in steps:
		var off := 4.0 * sin(TAU * 3.0 * float(i + 1) / steps)
		t.tween_property(l, "position:x", base + off, 0.3 / steps)
	t.tween_property(l, "position:x", base, 0.0)


## The clock box lives in the HUD's quick row; a bar freed without a HUD frees its orphan clock too.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and clock_box != null and is_instance_valid(clock_box) and clock_box.get_parent() == null:
		clock_box.free()


## The level's match clock ("m:ss") when it has one (skirmish.gd), in clock_box; shows / hides the essence and gold
## items with their banks.
func _update_timer() -> void:
	var level := get_tree().current_scene
	var has_timer := level != null and level.has_method(&"match_time_text")
	var has_essence := essence_bank != null
	var has_gold := gold_bank != null
	if has_timer != timer_label.visible:
		timer_label.visible = has_timer
		clock_box.visible = has_timer
	if has_essence != _essence_item.visible or has_gold != _gold_item.visible:
		_essence_item.visible = has_essence
		_gold_item.visible = has_gold
		essence_label.visible = has_essence   # the labels follow their items (tests read them)
		gold_label.visible = has_gold
		_fit()
	if has_timer:
		timer_label.text = Loc.sink(str(level.call(&"match_time_text")))


## Supply blocked (a spend refused at the population cap): the pop item's border pulses WARN for 3 s.
func flash_supply_blocked() -> void:
	_supply_flash_left = SUPPLY_FLASH_TIME


## True while the supply-blocked pulse runs (tests).
func is_supply_flashing() -> bool:
	return _supply_flash_left > 0.0


func _update_supply_flash(delta: float) -> void:
	if _supply_flash_left <= 0.0:
		return
	_supply_flash_left = maxf(_supply_flash_left - delta, 0.0)
	_supply_t += delta
	var a := 0.4 + 0.5 * (0.5 + 0.5 * sin(_supply_t * TAU * SUPPLY_FLASH_HZ))
	var st := _item_style(Color(UIStyle.WARN, a) if _supply_flash_left > 0.0 else Color(0, 0, 0, 0))
	if _supply_flash_left > 0.0:
		st.set_border_width_all(2)
	_pop_item.add_theme_stylebox_override("panel", st)


func _process(delta: float) -> void:
	_update_essence(delta)
	_update_gold(delta)
	_update_timer()
	_update_supply_flash(delta)
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
	if _pop_item != null and _pop_item.get_combined_minimum_size().x > ITEM_SIZE.x + 0.5:
		_fit.call_deferred()   # "200 / 200" widens the pop item: the bar stays right-anchored


## Failed spend: the crystal number flashes red for 0.4 s and "Not enough crystals" is shown.
func flash_not_enough() -> void:
	_flash_left = FLASH_TIME
	crystals_label.add_theme_color_override("font_color", UIStyle.WARN)
	shake(crystals_label)
	message.emit("Not enough crystals")
	if economy != null and is_instance_valid(economy) and int(economy.get("pop_used")) >= int(economy.get("pop_cap")):
		flash_supply_blocked()


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
	if not _essence_script_checked:
		# U4-5: the global class list is walked once (the trade / shop windows call this 4 x / s)
		_essence_script_checked = true
		for info in ProjectSettings.get_global_class_list():
			if str(info.get("class", "")) == "EssenceBank":
				var script: Variant = load(str(info.get("path", "")))
				if script is Script and (script as Script).get_script_method_list().any(
						func(m: Dictionary) -> bool: return str(m.get("name", "")) == "for_team"):
					_essence_script = script
				break
	if _essence_script != null:
		var bank: Variant = _essence_script.call(&"for_team", team)
		if bank is Object and bank != null:
			return bank
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
