class_name InventoryBar
extends Control
## Vessa's inventory row in the hero column (items.md "HUD", 4.U1a): 6 item slots 36 x 36 at
## (282 + i x 40, 834) and the artifact slot at (526, 834) with a gold border (a 2nd artifact slot appears
## above it, at (526, 794), only while it holds something). Each slot: tier-colour border, 2-letter
## abbreviation, key digit (Numpad 1-6), stack count, cooldown sweep. Left click = use (targeted actives
## use the selection's targeting flow), right click = sell near a shop / drop otherwise, drag onto another
## slot = swap, drag onto the world = drop. Hovering a slot or a ground item (group "item_pickups") shows
## its tooltip. Everything items-side is read untyped (`get`, `has_method`) so the bar compiles and stays
## empty until the items code exists.

signal message(text: String)

const SLOT_SIZE := 36.0
const SLOT_STEP := 40.0
const ITEM_SLOTS := 6
const ARTIFACT_SLOTS := 2
const BAR_POS := Vector2(282, 834)          ## At 1600 x 900 (anchored bottom-left: 66 px from the bottom).
const ARTIFACT_OFFSETS: Array[Vector2] = [Vector2(244, 0), Vector2(244, -40)]
const SLOT_BG := Color(0.10, 0.08, 0.12)
const ARTIFACT_BORDER := Color(1.0, 0.85, 0.3)
const KEY_COLOR := Color(1.0, 0.85, 0.4)
const PICKUP_HOVER_PX := 28.0

var hero: Node
var selection: Node
var tooltip: ItemTooltip
var slot_controls: Array = []   ## ItemSlot: 0-5 item slots, 6-7 artifact slots.

const HudSkin := ItemTooltip.HudSkin

var _hover_slot := -1
var _hover_pickup: Node = null
var _cd_totals := {}            ## slot -> the largest cooldown seen since it started (sweep ratio).
var _cd_was_on := {}            ## slot -> was the sweep showing last frame (ready flash).
var _flash := {}                ## slot -> ready flash seconds left.
var _drag_from := -1            ## The slot whose item is being dragged.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	var w := ARTIFACT_OFFSETS[0].x + SLOT_SIZE
	offset_left = BAR_POS.x
	offset_right = BAR_POS.x + w
	offset_top = -(900.0 - BAR_POS.y)
	offset_bottom = offset_top + SLOT_SIZE
	for i in ITEM_SLOTS + ARTIFACT_SLOTS:
		var s := ItemSlot.new()
		s.bar = self
		s.index = i
		s.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		s.custom_minimum_size = s.size
		s.position = Vector2(i * SLOT_STEP, 0) if i < ITEM_SLOTS else ARTIFACT_OFFSETS[i - ITEM_SLOTS]
		s.mouse_entered.connect(_on_slot_hover.bind(i, true))
		s.mouse_exited.connect(_on_slot_hover.bind(i, false))
		add_child(s)
		slot_controls.append(s)
	tooltip = ItemTooltip.new()
	add_child(tooltip)


func setup(p_hero: Node, p_selection: Node) -> void:
	hero = p_hero
	selection = p_selection


func _process(delta: float) -> void:
	for k in _flash.keys():
		_flash[k] = maxf(float(_flash[k]) - delta, 0.0)
	if selection != null and is_instance_valid(selection) and selection.get("hero") != null:
		hero = selection.get("hero")
	var inv := inventory()
	visible = inv != null
	for i in slot_controls.size():
		var s: Control = slot_controls[i]
		if i >= ITEM_SLOTS + 1:
			s.visible = entry(i) != null
		s.queue_redraw()
	_update_tooltip()


# ---------------------------------------------------------------- items side (untyped)

## Vessa's Inventory (`wizard.inventory`, or a child named "Inventory"), or null.
func inventory() -> Node:
	return inventory_of(hero)


static func inventory_of(wizard: Node) -> Node:
	if wizard == null or not is_instance_valid(wizard):
		return null
	var inv: Variant = wizard.get("inventory")
	if is_instance_valid(inv) and inv is Node:
		return inv
	return wizard.get_node_or_null(^"Inventory")


## The entry of slot `i` (0-5 items, 6-7 artifacts): `{ type, count, cooldown_left }` or null.
func entry(i: int) -> Variant:
	return slot_entry(inventory(), i)


static func slot_entry(inv: Node, i: int) -> Variant:
	if inv == null or not is_instance_valid(inv):
		return null
	var list: Variant = inv.get("slots") if i < ITEM_SLOTS else inv.get("artifacts")
	var k := i if i < ITEM_SLOTS else i - ITEM_SLOTS
	if not (list is Array) or k >= (list as Array).size():
		return null
	return list[k]


func entry_type(i: int) -> Variant:
	return type_of_entry(entry(i))


static func type_of_entry(e: Variant) -> Variant:
	if e == null:
		return null
	if e is Dictionary:
		return (e as Dictionary).get("type")
	if e is Object and (e as Object).get(&"type") != null:
		return (e as Object).get(&"type")
	return e   # the slot holds the ItemType itself


func entry_count(i: int) -> int:
	var e: Variant = entry(i)
	if e is Dictionary:
		return int((e as Dictionary).get("count", 1))
	if e is Object and (e as Object).get(&"count") != null:
		return int((e as Object).get(&"count"))
	return 1 if e != null else 0


## Seconds left on the slot's active: the entry's `cooldown_left`, or `cooldown_left(slot)` on the
## inventory / an ItemActives node (4.I2), whichever exists.
func cooldown_left(i: int) -> float:
	var e: Variant = entry(i)
	if e == null:
		return 0.0
	if e is Dictionary and (e as Dictionary).has("cooldown_left"):
		return float(e["cooldown_left"])
	var inv := inventory()
	for n in [inv, _item_actives()]:
		if n != null and (n as Object).has_method(&"cooldown_left"):
			return float((n as Object).call(&"cooldown_left", i))
	return 0.0


func _item_actives() -> Node:
	var inv := inventory()
	for base in [inv, hero]:
		if base != null and is_instance_valid(base):
			var n: Node = (base as Node).get_node_or_null(^"ItemActives")
			if n != null:
				return n
	return null


## Remaining / total for the sweep (total = the item's cooldown, or the largest seen).
func cooldown_ratio(i: int) -> float:
	var left := cooldown_left(i)
	if left <= 0.0:
		_cd_totals.erase(i)
		return 0.0
	var total := maxf(float(ItemTooltip.field(entry_type(i), &"active_cooldown", 0.0)), 0.0)
	total = maxf(total, float(_cd_totals.get(i, 0.0)))
	total = maxf(total, left)
	_cd_totals[i] = total
	return clampf(left / total, 0.0, 1.0)


# ---------------------------------------------------------------- actions

## Click or Numpad: the selection's item flow (targeting for point actives), else use_item directly.
func use_slot(i: int) -> void:
	if i >= ITEM_SLOTS:
		return
	if selection != null and is_instance_valid(selection) and selection.has_method(&"use_item_slot"):
		selection.call(&"use_item_slot", i)
		return
	var inv := inventory()
	if inv != null and inv.has_method(&"use_item"):
		var r := str(inv.call(&"use_item", i, null))
		if r != "":
			message.emit(r)


## Right click: sell at a shop (12 m), drop otherwise. Artifacts are never sold or dropped by hand.
func sell_or_drop(i: int) -> void:
	var inv := inventory()
	var type: Variant = entry_type(i)
	if inv == null or type == null:
		return
	var name := ItemTooltip.display_name(type)
	if i >= ITEM_SLOTS or ItemTooltip.tier(type) == &"artifact":
		message.emit("Artifact (cannot be sold)")
		return
	var shop: Variant = inv.call(&"nearest_shop") if inv.has_method(&"nearest_shop") else null
	if shop != null and inv.has_method(&"sell"):
		var got: Variant = inv.call(&"sell", i)
		if got is String:
			if got != "":
				message.emit(got)
		elif int(got) > 0:
			message.emit(Loc.t("Sold {name} for {n}", {"name": name, "n": int(got)}))
		return
	drop_slot(i)


func drop_slot(i: int) -> void:
	var inv := inventory()
	var type: Variant = entry_type(i)
	if inv == null or type == null or i >= ITEM_SLOTS or not inv.has_method(&"drop"):
		return
	var r: Variant = inv.call(&"drop", i)
	if r is String and r != "":
		message.emit(r)
	else:
		message.emit(Loc.t("Dropped {name}", {"name": ItemTooltip.display_name(type)}))


func swap_slots(a: int, b: int) -> void:
	var inv := inventory()
	if inv == null or a == b or a >= ITEM_SLOTS or b >= ITEM_SLOTS or not inv.has_method(&"swap"):
		return
	inv.call(&"swap", a, b)


# ---------------------------------------------------------------- tooltip

func _on_slot_hover(i: int, entered: bool) -> void:
	if entered:
		_hover_slot = i
	elif _hover_slot == i:
		_hover_slot = -1


func slot_tooltip_text(i: int) -> String:
	var type: Variant = entry_type(i)
	if type == null:
		return ""
	var key := "Num %d" % (i + 1) if i < ITEM_SLOTS else ""
	return ItemTooltip.describe(type, key, entry_count(i))


func _update_tooltip() -> void:
	var text := ""
	var anchor := Vector2.ZERO
	if _hover_slot >= 0 and visible:
		text = slot_tooltip_text(_hover_slot)
		var s: Control = slot_controls[_hover_slot]
		anchor = s.global_position + Vector2(0, -6)
	var pickup := _pickup_under_mouse() if text == "" else null
	if pickup != _hover_pickup:
		if _hover_pickup != null and is_instance_valid(_hover_pickup) and _hover_pickup.has_method(&"set_hovered"):
			_hover_pickup.call(&"set_hovered", false)
		if pickup != null and pickup.has_method(&"set_hovered"):
			pickup.call(&"set_hovered", true)
		_hover_pickup = pickup
	if pickup != null:
		text = ItemTooltip.describe(pickup_type(pickup), "", int(ItemTooltip.field(pickup, &"count", 1)))
		anchor = get_viewport().get_mouse_position() + Vector2(16, -8)
	if text == "":
		tooltip.hide_tip()
	else:
		var type: Variant = pickup_type(pickup) if pickup != null else entry_type(_hover_slot)
		tooltip.show_text(text, anchor, ItemTooltip.tier_color(type))


## The ItemType a ground item carries (`item_type`, `type` or `item`).
static func pickup_type(pickup: Node) -> Variant:
	for key in [&"item_type", &"type", &"item"]:
		var v: Variant = pickup.get(key)
		if v is Object:
			return v
	return null


## The ground item drawn nearest the mouse (within 28 px), unless the mouse is over the HUD.
func _pickup_under_mouse() -> Node:
	if selection == null or not is_instance_valid(selection):
		return null
	if selection.has_method(&"item_pickup_at"):
		var vp := get_viewport()
		var hovered: Variant = vp.gui_get_hovered_control() if vp.has_method(&"gui_get_hovered_control") else null
		if hovered != null:
			return null
		return selection.call(&"item_pickup_at", vp.get_mouse_position())
	return null


# ---------------------------------------------------------------- drawing

## Slot look (ui-style.md 6.3): button frame rimmed in the tier colour, top / artifact halo, 32 px icon
## (or the abbreviation), key badge, stack count, radial cooldown sweep with seconds and a ready flash,
## hover / drag rims, empty artifact crown.
func draw_slot(s: Control, i: int) -> void:
	var type: Variant = entry_type(i)
	var rect := Rect2(Vector2.ZERO, s.size)
	var dragging_from_here := _drag_from == i and get_viewport() != null and get_viewport().gui_is_dragging()
	if dragging_from_here:
		type = null   # the source slot shows an empty rim while its item is carried
	var tier := ItemTooltip.tier(type) if type != null else &""
	var rim := ItemTooltip.tier_color(type) if type != null else ItemTooltip.EMPTY_COLOR
	var inside := HudSkin.token(&"panel_inner")
	if type == null:
		inside = inside.darkened(0.2)
	if i >= ITEM_SLOTS:
		rim = ARTIFACT_BORDER if type != null else Color(ARTIFACT_BORDER, 0.6)
	var hovered := _hover_slot == i
	var drop_target := hovered and _drag_from >= 0 and _drag_from != i and i < ITEM_SLOTS \
			and get_viewport() != null and get_viewport().gui_is_dragging()
	if drop_target:
		rim = HudSkin.GOLD
	elif hovered:
		rim = HudSkin.token(&"frame_light")
		inside = inside.lightened(0.12)
	# Halo: top items and artifacts (tier colour 0.35), hover (trim glow).
	if type != null and (tier == &"top" or tier == &"artifact"):
		s.draw_rect(rect.grow(2.0), Color(ItemTooltip.tier_color(type), 0.35), false, 2.0)
	if hovered:
		s.draw_rect(rect.grow(0.5), Color(HudSkin.token(&"trim_glow"), 0.6), false, 1.0)
	s.draw_style_box(HudSkin.slot_frame(rim, inside), rect)
	var font := s.get_theme_default_font()
	if type == null and i >= ITEM_SLOTS:
		_draw_crown(s, Color(ARTIFACT_BORDER, 0.35))
	if type != null:
		var tex := HudSkin.icon("items", str(ItemTooltip.field(type, &"id", "")))
		if tex != null:
			var k := 1.0 + 0.08 * sin(PI * clampf(float(_flash.get(i, 0.0)) / 0.2, 0.0, 1.0))
			var icon_rect := Rect2(Vector2(2, 2), Vector2(32, 32))
			icon_rect = icon_rect.grow((k - 1.0) * 16.0)
			s.draw_texture_rect(tex, icon_rect, false)
		else:
			_draw_centered(s, font, ItemTooltip.abbrev(type), 14, HudSkin.token(&"text"), s.size.y * 0.5 + 5.0)
		var count := entry_count(i)
		if count > 1 or tier == &"consumable":
			s.draw_string_outline(font, Vector2(3, s.size.y - 3), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
			s.draw_string(font, Vector2(3, s.size.y - 3), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, HudSkin.token(&"text"))
		var ratio := cooldown_ratio(i) if not dragging_from_here else 0.0
		if ratio > 0.0:
			HudSkin.draw_sweep(s, rect.grow(-3.0), ratio)
			_draw_centered(s, font, str(ceili(cooldown_left(i))), 12, HudSkin.token(&"text"), s.size.y * 0.5 + 4.0)
		var on := ratio > 0.0
		if _cd_was_on.get(i, false) and not on:
			_flash[i] = 0.25
		_cd_was_on[i] = on
	if float(_flash.get(i, 0.0)) > 0.0:
		s.draw_rect(rect.grow(-2.0), Color(HudSkin.token(&"trim_glow"), float(_flash[i]) / 0.25), false, 2.0)
	# Key digit bottom-right on a 10 x 10 badge: empty slots and items with an active (passive-only: none).
	if i < ITEM_SLOTS and (type == null or ItemTooltip.has_active(type)):
		var digit := str(i + 1)
		var c := KEY_COLOR if type != null else Color(KEY_COLOR, 0.45)
		s.draw_rect(Rect2(s.size.x - 12, s.size.y - 12, 10, 10), Color(0, 0, 0, 0.75))
		s.draw_string(font, Vector2(s.size.x - 12, s.size.y - 3.5), digit, HORIZONTAL_ALIGNMENT_CENTER, 10, 10, c)


## The 10 x 8 crown glyph of an empty artifact slot.
func _draw_crown(s: Control, color: Color) -> void:
	var o := s.size * 0.5 - Vector2(5, 4)
	var pts := PackedVector2Array([o + Vector2(0, 8), o + Vector2(0, 1), o + Vector2(2.5, 4), o + Vector2(5, 0),
			o + Vector2(7.5, 4), o + Vector2(10, 1), o + Vector2(10, 8)])
	s.draw_colored_polygon(pts, color)


func _draw_centered(s: Control, font: Font, text: String, font_size: int, color: Color, baseline: float) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var p := Vector2((s.size.x - w) * 0.5, baseline)
	s.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color.BLACK)
	s.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## One slot: draws through the bar, clicks, drag / drop.
class ItemSlot extends Control:
	var bar: InventoryBar
	var index := 0
	var _dragged := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		if bar != null:
			bar.draw_slot(self, index)

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb == null:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if not _dragged:
				bar.use_slot(index)
			_dragged = false
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_dragged = false
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			bar.sell_or_drop(index)
			accept_event()

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if index >= InventoryBar.ITEM_SLOTS or bar.entry_type(index) == null:
			return null
		_dragged = true
		var type: Variant = bar.entry_type(index)
		# Drag ghost: the slot (frame + icon or abbreviation) at alpha 0.7 under the cursor.
		var preview := Panel.new()
		preview.size = Vector2(InventoryBar.SLOT_SIZE, InventoryBar.SLOT_SIZE)
		preview.position = -preview.size * 0.5
		preview.modulate.a = 0.7
		preview.add_theme_stylebox_override("panel",
				InventoryBar.HudSkin.slot_frame(ItemTooltip.tier_color(type), InventoryBar.HudSkin.token(&"panel_inner")))
		var tex := InventoryBar.HudSkin.icon("items", str(ItemTooltip.field(type, &"id", "")))
		if tex != null:
			var r := TextureRect.new()
			r.texture = tex
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.position = Vector2(2, 2)
			r.size = Vector2(32, 32)
			preview.add_child(r)
		else:
			var l := UIStyle.label(ItemTooltip.abbrev(type), 14)
			l.add_theme_color_override("font_color", ItemTooltip.tier_color(type))
			l.size = preview.size
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			preview.add_child(l)
		var holder := Control.new()
		holder.add_child(preview)
		set_drag_preview(holder)
		bar._drag_from = index
		return {"inventory_slot": index}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return index < InventoryBar.ITEM_SLOTS and data is Dictionary and (data as Dictionary).has("inventory_slot")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		bar.swap_slots(int(data["inventory_slot"]), index)

	func _notification(what: int) -> void:
		# A drag from this slot released on nothing that takes it (the world) = drop the item.
		if what == NOTIFICATION_DRAG_END and bar != null:
			bar._drag_from = -1
		if what == NOTIFICATION_DRAG_END and _dragged:
			_dragged = false
			var vp := get_viewport()
			if vp != null and not vp.gui_is_drag_successful():
				var hovered: Variant = vp.gui_get_hovered_control() if vp.has_method(&"gui_get_hovered_control") else null
				if hovered == null:
					bar.drop_slot(index)
