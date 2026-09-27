class_name ShopWindow
extends PanelContainer
## The shop window (task 4.U1b, spec: docs/design/items.md "UI"): 640 x 440 at (480, 200).
## Title (`Keep shop` / `Ruin Peddler`) + essence + X; left 380 px: the item grid by tier (Components / Mid /
## Top / Consumables, 48 x 48 buttons, 7 per row, tier border, live price, green when owned parts lower it);
## right 240 px: details of the hovered (else selected) item, its recipe tree, Buy / Combine with the refusal
## reason, the Sell zone (drop an inventory slot on it) and the crystals -> essence exchange.
## Opens with `open(shop)` / `toggle()` (T, wired by the lead); closes with T, Esc, X or when the wizard
## walks more than 12 m from the shop.
## The items code (scripts/items/) is duck-typed here: untyped values, has_method, guarded loads, so the
## window degrades to "Items not available" when a piece is missing.

signal message(text: String)
signal opened
signal closed

const POS := Vector2(480, 200)
const SIZE := Vector2(640, 440)
const GRID_W := 380.0
const DETAILS_W := 220.0
const SHOP_RANGE := 12.0
const BUTTON := 48.0
const GAP := 6
const PER_ROW := 7
const REFRESH_TIME := 0.25

enum Tier { COMPONENT, MID, TOP, CONSUMABLE, ARTIFACT }
const TIER_NAMES := ["Components", "Mid", "Top", "Consumables"]
const TIER_KEYS := ["component", "mid", "top", "consumable", "artifact"]
const TIER_COLORS := [Color(0.85, 0.85, 0.85), Color(0.30, 0.75, 1.00), Color(1.00, 0.60, 0.20),
		Color(0.40, 0.90, 0.40), Color(1.00, 0.85, 0.30)]
const ESSENCE_COLOR := Color(0.9, 0.8, 1.0)
const ESSENCE_ICON := Color(0.75, 0.45, 1.0)
const OWNED_COLOR := Color(0.4, 0.95, 0.4)
const CRYSTAL_COLOR := Color(0.45, 0.85, 1.0)

const ITEMS_DIR := "res://data/items/"
const ESSENCE_BANK_PATH := "res://scripts/items/essence_bank.gd"
const RECIPES_PATH := "res://scripts/items/recipes.gd"

const STAT_WORDS := {
	"attack_damage": "damage", "max_hp": "HP", "max_mana": "mana", "mana_regen": "mana regen",
	"hp_regen": "HP regen", "attack_cooldown": "attack cooldown", "move_speed": "speed", "armor": "armor",
	"spell_power": "spell power", "cooldown_reduction": "cooldown reduction", "lifesteal": "lifesteal",
}

var hero: Node = null                 ## The wizard who shops (Vessa).
var shop: Node = null                 ## The shop building / peddler the window shows.
var inventory_override: Variant = null   ## Tests can plug an inventory in; else `hero.inventory`.
var last_buy_result := ""             ## The last `buy()` answer ("" = bought).
var item_buttons: Array[Button] = []  ## One per item in the grid (meta "item_type").

var _title: Label
var _essence_label: Label
var _grid_box: VBoxContainer
var _missing: Label
var _exchange: Button
var _name: Label
var _stats: Label
var _text: Label
var _tree: RecipeTree
var _buy: Button
var _reason: Label
var _sell_zone: SellZone
var _selected: Variant = null
var _hovered: Variant = null
var _refresh_left := 0.0

static var _type_cache: Array = []

const HudSkin := ItemTooltip.HudSkin


## Numbers font: default font, embolden 0.5 (ui-style.md 2).
static func _bold_font() -> Font:
	var fv := FontVariation.new()
	fv.base_font = ThemeDB.fallback_font
	fv.variation_embolden = 0.5
	return fv


## The round stud X (6.4): `frame_metal` fill, `frame_light` ring, hover `WARN` ring.
static func _style_stud(b: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var s := StyleBoxFlat.new()
		s.bg_color = HudSkin.token(&"frame_metal").darkened(0.2 if state == "pressed" else 0.0)
		s.border_color = UIStyle.WARN if state == "hover" else HudSkin.token(&"frame_light")
		s.set_border_width_all(2)
		s.set_corner_radius_all(12)
		s.set_content_margin_all(0)
		b.add_theme_stylebox_override(state, s)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", HudSkin.token(&"text"))
	b.add_theme_color_override("font_hover_color", HudSkin.token(&"text"))


## The "primary" button (Buy / Combine): `trim_glow` rim, inside `trim_glow` 0.18 over `panel_inner`.
static func _style_primary(b: Button) -> void:
	var glow := HudSkin.token(&"trim_glow")
	var inner := HudSkin.token(&"panel_inner").blend(Color(glow, 0.18))
	b.add_theme_stylebox_override("normal", HudSkin.slot_frame(glow, inner))
	b.add_theme_stylebox_override("hover", HudSkin.slot_frame(glow.lightened(0.3), inner.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", HudSkin.slot_frame(glow.darkened(0.3), inner.darkened(0.25)))
	b.add_theme_stylebox_override("disabled", HudSkin.state_frames()["disabled"])
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, HudSkin.token(&"text"))
	b.add_theme_color_override("font_disabled_color", HudSkin.token(&"text_muted"))


## Builds the window under the HUD (a CanvasLayer or Control) for `wizard`; hidden until `open()`.
## Messages go to `hud.show_message` when it has one.
static func attach(hud: Node, wizard: Node) -> ShopWindow:
	var w := ShopWindow.new()
	w.hero = wizard
	hud.add_child(w)
	if hud.has_method(&"show_message"):
		w.message.connect(func(t: String) -> void: hud.call(&"show_message", t))
	return w


func _ready() -> void:
	add_theme_stylebox_override("panel", HudSkin.frame_style(8.0))
	position = POS
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	add_child(col)

	# Title bar (28 px): shop name left, essence flame + number right, stud X; a frame_light rule under it.
	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 28)
	col.add_child(top)
	_title = HudSkin.text("Keep shop", 20, HudSkin.token(&"title"), true)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_title)
	var flame := Control.new()
	flame.custom_minimum_size = Vector2(12, 16)
	flame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flame.draw.connect(func() -> void:
		flame.draw_colored_polygon(PackedVector2Array([Vector2(6, 0), Vector2(11, 8), Vector2(10, 14), Vector2(6, 16),
				Vector2(2, 14), Vector2(1, 8)]), ESSENCE_ICON)
		flame.draw_colored_polygon(PackedVector2Array([Vector2(6, 6), Vector2(8, 11), Vector2(6, 14), Vector2(4, 11)]),
				Color(0.95, 0.80, 1.0)))
	top.add_child(flame)
	_essence_label = HudSkin.text("0", 16, ESSENCE_COLOR)
	_essence_label.add_theme_font_override("font", _bold_font())
	top.add_child(_essence_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(12, 0)
	top.add_child(spacer)
	var x := Button.new()
	x.text = "x"
	x.custom_minimum_size = Vector2(24, 24)
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	x.focus_mode = Control.FOCUS_NONE
	x.add_theme_font_size_override("font_size", 13)
	_style_stud(x)
	x.pressed.connect(close)
	top.add_child(x)
	var rule := ColorRect.new()
	rule.color = HudSkin.token(&"frame_light")
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	# Left: the grid (scrolls if a long stock does not fit) + the exchange button.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(GRID_W, 0)
	left.add_theme_constant_override("separation", 4)
	body.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	_grid_box = VBoxContainer.new()
	_grid_box.add_theme_constant_override("separation", 2)
	_grid_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid_box)
	_missing = UIStyle.label("Items not available", 16)
	_missing.modulate = Color(1, 1, 1, 0.7)
	_missing.visible = false
	left.add_child(_missing)
	_exchange = Button.new()
	_exchange.text = "Exchange 100 crystals -> 40 essence"
	_exchange.custom_minimum_size = Vector2(0, 26)
	_exchange.add_theme_font_size_override("font_size", 12)
	_exchange.focus_mode = Control.FOCUS_NONE
	HudSkin.style_button(_exchange, CRYSTAL_COLOR)
	_exchange.pressed.connect(exchange)
	_exchange.visible = false
	left.add_child(_exchange)

	# Right: details, recipe tree, Buy / Combine, reason, Sell zone.
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(DETAILS_W, 0)
	right.add_theme_constant_override("separation", 4)
	body.add_child(right)
	_name = HudSkin.text("", 18, HudSkin.token(&"title"), true)
	_name.clip_text = true
	_name.custom_minimum_size = Vector2(DETAILS_W, 0)
	right.add_child(_name)
	_stats = HudSkin.text("", 13, HudSkin.token(&"text"))
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats.custom_minimum_size = Vector2(DETAILS_W, 0)
	right.add_child(_stats)
	_text = HudSkin.text("", 13, HudSkin.token(&"text_muted"))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(DETAILS_W, 0)
	_text.max_lines_visible = 4
	right.add_child(_text)
	_tree = RecipeTree.new()
	_tree.window = self
	_tree.custom_minimum_size = Vector2(DETAILS_W, RecipeTree.HEIGHT)
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_tree)
	_reason = HudSkin.text("", 12, UIStyle.WARN)
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason.custom_minimum_size = Vector2(DETAILS_W, 0)
	_reason.clip_text = true
	right.add_child(_reason)
	_buy = Button.new()
	_buy.custom_minimum_size = Vector2(DETAILS_W, 36)
	_buy.focus_mode = Control.FOCUS_NONE
	_buy.add_theme_font_size_override("font_size", 16)
	_buy.add_theme_font_override("font", HudSkin.display_font())
	_style_primary(_buy)
	_buy.pressed.connect(buy_selected)
	right.add_child(_buy)
	_sell_zone = SellZone.new()
	_sell_zone.window = self
	_sell_zone.custom_minimum_size = Vector2(DETAILS_W, 28)
	right.add_child(_sell_zone)


# ---------------------------------------------------------------- open / close

## Opens on `shop_node`, or on the nearest shop in range. Returns false ("No shop nearby") otherwise.
func open(shop_node: Node = null) -> bool:
	if shop_node == null:
		shop_node = find_shop()
	if shop_node == null or not _in_range(shop_node):
		message.emit("No shop nearby")
		return false
	shop = shop_node
	_title.text = _shop_title(shop)
	_build_grid()
	visible = true
	_refresh()
	opened.emit()
	return true


func close() -> void:
	if not visible:
		return
	visible = false
	shop = null
	_hovered = null
	closed.emit()


## T: open when closed (nearest shop), close when open.
func toggle() -> void:
	if visible:
		close()
	else:
		open()


func is_open() -> bool:
	return visible


## The nearest shop within 12 m of the wizard: `inventory.nearest_shop()` first, else any node in the groups
## "buildings" / "shops" answering `is_shop()` (own team or neutral).
func find_shop() -> Node:
	var inv: Variant = get_inventory()
	if inv != null and inv.has_method(&"nearest_shop"):
		var s: Variant = inv.call(&"nearest_shop")
		if s is Node:
			return s
	if hero == null or not is_instance_valid(hero):
		return null
	var best: Node = null
	var best_d := SHOP_RANGE
	var team: Variant = hero.get("team")
	for group in [&"shops", &"buildings"]:
		for b in get_tree().get_nodes_in_group(group):
			if not (b is Node3D) or not b.has_method(&"is_shop") or not b.call(&"is_shop"):
				continue
			var bt: Variant = b.get("team")
			if bt != null and team != null and int(bt) != int(team) and int(bt) != 2:   # 2 = Team.NEUTRAL
				continue
			var d := _flat_distance(b)
			if d <= best_d:
				best_d = d
				best = b
	return best


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	if shop == null or not is_instance_valid(shop) or not _in_range(shop) \
			or (shop.has_method(&"is_alive") and not shop.call(&"is_alive")):
		close()
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh()


func _in_range(node: Node) -> bool:
	return _flat_distance(node) <= SHOP_RANGE


func _flat_distance(node: Node) -> float:
	if hero == null or not is_instance_valid(hero) or not (hero is Node3D) or not (node is Node3D):
		return INF
	var a: Vector3 = (hero as Node3D).global_position
	var b: Vector3 = (node as Node3D).global_position
	return Vector2(a.x - b.x, a.z - b.z).length()


func _shop_title(s: Node) -> String:
	if s.has_method(&"shop_title"):
		return str(s.call(&"shop_title"))
	if (s.is_in_group(&"shops") and not s.is_in_group(&"buildings")) or str(s.name).to_lower().contains("peddler"):
		return "Ruin Peddler"
	var bt: Variant = s.get("building_type")
	if bt is Object and bt.get("display_name") != null:
		return "%s shop" % str(bt.get("display_name"))
	return "Keep shop"


# ---------------------------------------------------------------- items access (duck-typed)

func get_inventory() -> Variant:
	if inventory_override != null:
		return inventory_override
	if hero != null and is_instance_valid(hero):
		return hero.get("inventory")
	return null


func essence() -> int:
	var bank: Variant = _essence_bank()
	if bank != null and bank.get("essence") != null:
		return int(bank.get("essence"))
	return 0


func _essence_bank() -> Variant:
	if hero == null or not is_instance_valid(hero) or not ResourceLoader.exists(ESSENCE_BANK_PATH):
		return null
	var script: Variant = load(ESSENCE_BANK_PATH)
	if not _script_has(script, &"for_team"):
		return null
	var team: Variant = hero.get("team")
	return script.call(&"for_team", int(team) if team != null else 0)


## Every item type the window can list (data/items/*.tres), artifacts and campaign-only items left out.
static func all_item_types() -> Array:
	if not _type_cache.is_empty():
		return _type_cache
	if not DirAccess.dir_exists_absolute(ITEMS_DIR):
		return _type_cache
	for f in DirAccess.get_files_at(ITEMS_DIR):
		var file := f.trim_suffix(".remap")
		if not file.ends_with(".tres") and not file.ends_with(".res"):
			continue
		var t: Resource = load(ITEMS_DIR + file)
		if t == null or t.get("id") == null:
			continue
		if t.get("is_artifact") == true or t.get("campaign_only") == true or t.get("available") == false \
				or tier_of(t) == Tier.ARTIFACT:
			continue
		_type_cache.append(t)
	_type_cache.sort_custom(func(a: Resource, b: Resource) -> bool:
		var ta := tier_of(a)
		var tb := tier_of(b)
		if ta != tb:
			return ta < tb
		return total_cost_of(a) < total_cost_of(b))
	return _type_cache


static func tier_of(t: Variant) -> int:
	return tier_index(t.get("tier") if t is Object else null)


## Tier as an index into TIER_COLORS, from the enum value or its name ("mid").
static func tier_index(v: Variant) -> int:
	if v is int:
		return clampi(v, 0, 4)
	if v is String or v is StringName:
		var i := TIER_KEYS.find(str(v).to_lower())
		return maxi(i, 0)
	return Tier.COMPONENT


static func total_cost_of(t: Variant) -> int:
	if t is Object and t.has_method(&"total_cost"):
		return int(t.call(&"total_cost"))
	var c: Variant = t.get("cost") if t is Object else 0
	var total := int(c) if c != null else 0
	for p in parts_of(t):
		total += total_cost_of(p)
	return total


static func parts_of(t: Variant) -> Array:
	var p: Variant = t.get("parts") if t is Object else null
	return p if p is Array else []


static func id_of(t: Variant) -> String:
	if t is Object and t.get("id") != null:
		return str(t.get("id"))
	return str(t)


static func name_of(t: Variant) -> String:
	var n: Variant = t.get("display_name") if t is Object else null
	return str(n) if n != null and str(n) != "" else id_of(t)


static func abbrev_of(t: Variant) -> String:
	var a: Variant = t.get("icon_abbrev") if t is Object else null
	return str(a) if a != null and str(a) != "" else UIStyle.abbrev(name_of(t))


## "+20 damage · -12 % attack cooldown".
static func stats_text(t: Variant) -> String:
	var s: Variant = t.get("stats") if t is Object else null
	if not (s is Dictionary):
		return ""
	var bits: PackedStringArray = []
	for key in s:
		var k := str(key)
		var v := float(s[key])
		var pct := k.ends_with("_pct")
		var base := k.trim_suffix("_pct")
		var word: String = STAT_WORDS.get(base, base.replace("_", " "))
		var sg := "+" if v >= 0.0 else "-"
		if pct:
			bits.append("%s%s %% %s" % [sg, _num(absf(v) * 100.0), word])
		else:
			bits.append("%s%s %s" % [sg, _num(absf(v)), word])
	return " · ".join(bits)


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v


## Item id -> count carried (slots and artifact slots).
func owned_counts() -> Dictionary:
	var out := {}
	var inv: Variant = get_inventory()
	if inv == null:
		return out
	for list_name in ["slots", "artifacts"]:
		var list: Variant = inv.get(list_name)
		if not (list is Array):
			continue
		for e in list:
			var t: Variant = null
			if e is Dictionary:
				t = e.get("type")
			elif e is Object:
				t = e.get("type") if e.get("type") != null else e
			if t != null:
				var id := id_of(t)
				out[id] = int(out.get(id, 0)) + 1
	return out


func _recipes() -> Variant:
	if not ResourceLoader.exists(RECIPES_PATH):
		return null
	return load(RECIPES_PATH)


## `Recipes.tree(type, inventory)` when it exists, else the same shape built here from `parts`.
func recipe_tree(t: Variant) -> Dictionary:
	var recipes: Variant = _recipes()
	var inv: Variant = get_inventory()
	if _script_has(recipes, &"tree") and inv is Object:
		var d: Variant = recipes.call(&"tree", t, inv)
		if d is Dictionary:
			return d
	return _own_tree(t, 0, owned_counts(), false)


func _own_tree(t: Variant, level: int, counts: Dictionary, match_owned: bool) -> Dictionary:
	var id := id_of(t)
	var owned := match_owned and int(counts.get(id, 0)) > 0
	if owned:
		counts[id] = int(counts[id]) - 1
	var parts: Array = []
	if level < 2:
		for p in parts_of(t):
			parts.append(_own_tree(p, level + 1, counts, not owned))
	return {"id": id, "name": name_of(t), "abbrev": abbrev_of(t), "tier": tier_of(t),
			"total_cost": total_cost_of(t), "owned": owned, "parts": parts}


## What a click costs now: `Recipes.plan(inventory, type, shop)` when it exists, else recipe cost + the parts
## not carried.
func price_of(t: Variant) -> int:
	var inv: Variant = get_inventory()
	if inv is Object:
		var recipes: Variant = _recipes()
		if _script_has(recipes, &"plan"):
			var plan: Variant = recipes.call(&"plan", inv, t, shop)
			if plan is Dictionary:
				for key in ["essence_cost", "essence", "cost", "price"]:
					if plan.has(key):
						return int(plan[key])
	var counts := owned_counts()
	return _price_with(t, counts, true)


func _price_with(t: Variant, counts: Dictionary, is_root: bool) -> int:
	var id := id_of(t)
	if not is_root and int(counts.get(id, 0)) > 0:
		counts[id] = int(counts[id]) - 1
		return 0
	var parts := parts_of(t)
	if parts.is_empty():
		return total_cost_of(t)
	var c: Variant = t.get("cost")
	var total := int(c) if c != null else 0
	for p in parts:
		total += _price_with(p, counts, false)
	return total


static func _script_has(script: Variant, method: StringName) -> bool:
	if not (script is Script):
		return false
	for m in (script as Script).get_script_method_list():
		if m.get("name") == String(method):
			return true
	return false


## `inventory.can_buy(type)`: "" = can buy, else the reason.
func buy_reason(t: Variant) -> String:
	var inv: Variant = get_inventory()
	if inv == null or not inv.has_method(&"can_buy"):
		return "Items not available"
	return str(inv.call(&"can_buy", t))


func _stock_ids() -> Variant:
	if shop == null or not is_instance_valid(shop) or not shop.has_method(&"shop_stock"):
		return null
	var ids := {}
	var stock: Variant = shop.call(&"shop_stock")
	if stock is Array:
		for s in stock:
			ids[id_of(s)] = true
	return ids


## Components and consumables must be in the shop's stock; mid / top combine at any shop.
func is_sold_here(t: Variant, stock: Variant, reason: String) -> bool:
	if reason == "Not sold here" or reason.begins_with("Needs"):
		return false
	var tier := tier_of(t)
	if stock is Dictionary and (tier == Tier.COMPONENT or tier == Tier.CONSUMABLE):
		return (stock as Dictionary).has(id_of(t))
	return true


# ---------------------------------------------------------------- actions

## Buys (or combines) the selected item through `inventory.buy(type)`; shows the refusal reason.
func buy_selected() -> String:
	if _selected == null:
		return "Nothing selected"
	return buy(_selected)


func buy(t: Variant) -> String:
	var inv: Variant = get_inventory()
	if inv == null or not inv.has_method(&"buy"):
		last_buy_result = "Items not available"
	else:
		last_buy_result = str(inv.call(&"buy", t))
	if last_buy_result == "":
		message.emit("Bought %s" % name_of(t))
	else:
		message.emit(last_buy_result)
		_reason.text = last_buy_result
	_refresh()
	if last_buy_result != "":
		_reason.text = last_buy_result
	return last_buy_result


## Sells the item in inventory slot `slot` (drag onto the Sell zone). Returns the essence gained.
func sell_slot(slot: int) -> int:
	var inv: Variant = get_inventory()
	if inv == null or not inv.has_method(&"sell"):
		message.emit("Items not available")
		return 0
	var slots: Variant = inv.get("slots")
	var t: Variant = null
	if slots is Array and slot >= 0 and slot < (slots as Array).size() and slots[slot] is Dictionary:
		t = slots[slot].get("type")
	var gained := int(inv.call(&"sell", slot))
	if gained > 0 and t != null:
		message.emit("Sold %s for %d" % [name_of(t), gained])
	_refresh()
	return gained


## Crystals -> essence at a base shop (`exchange_crystals(team)` on the shop).
func exchange() -> void:
	if shop == null or not is_instance_valid(shop) or not shop.has_method(&"exchange_crystals"):
		return
	var team: Variant = hero.get("team") if hero != null else 0
	var r: Variant = shop.call(&"exchange_crystals", int(team) if team != null else 0)
	if r is String and r != "":
		message.emit(r)
	elif r is bool and not r:
		message.emit("Not enough crystals")
	else:
		message.emit("Exchanged 100 crystals for 40 essence")
	_refresh()


# ---------------------------------------------------------------- building / refreshing

func _build_grid() -> void:
	for c in _grid_box.get_children():
		c.queue_free()
	item_buttons.clear()
	_selected = null
	var types := all_item_types()
	var inv: Variant = get_inventory()
	_missing.visible = types.is_empty() or inv == null
	if _missing.visible:
		_missing.text = "Items not available"
	for tier in range(4):
		var of_tier: Array = types.filter(func(t: Variant) -> bool: return tier_of(t) == tier)
		if of_tier.is_empty():
			continue
		# Row label (display font 12, muted) + a 1 px frame_dark rule after it.
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(HudSkin.text(TIER_NAMES[tier], 12, HudSkin.token(&"text_muted"), true))
		var rule := ColorRect.new()
		rule.color = HudSkin.token(&"frame_dark")
		rule.custom_minimum_size = Vector2(0, 1)
		rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(rule)
		_grid_box.add_child(head)
		var grid := GridContainer.new()
		grid.columns = PER_ROW
		grid.add_theme_constant_override("h_separation", GAP)
		grid.add_theme_constant_override("v_separation", GAP)
		_grid_box.add_child(grid)
		for t in of_tier:
			grid.add_child(_item_button(t))
	if not item_buttons.is_empty():
		_selected = item_buttons[0].get_meta("item_type")


func _item_button(t: Variant) -> Button:
	var b := ShopButton.new()
	b.custom_minimum_size = Vector2(BUTTON, BUTTON)
	b.set_meta("item_type", t)
	b.set_meta("rim", Color(0, 0, 0, 0))
	b.tier_color = TIER_COLORS[tier_of(t)]
	b.focus_mode = Control.FOCUS_NONE
	HudSkin.style_button(b, TIER_COLORS[tier_of(t)])
	var tex := HudSkin.icon("items", id_of(t))
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.position = Vector2(4, 4)
		icon.size = Vector2(40, 40)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icon)
	else:
		var ab := HudSkin.text(abbrev_of(t), 14, HudSkin.token(&"text"))
		ab.set_anchors_preset(Control.PRESET_FULL_RECT)
		ab.offset_bottom = -12.0
		ab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_child(ab)
	var cost := UIStyle.label("", 10)
	cost.add_theme_constant_override("outline_size", 3)
	cost.name = "Cost"
	cost.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cost.offset_top = -15.0
	cost.offset_bottom = -2.0
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cost)
	b.pressed.connect(func() -> void:
		_selected = t
		_refresh())
	b.mouse_entered.connect(func() -> void:
		_hovered = t
		_show_details())
	b.mouse_exited.connect(func() -> void:
		if _hovered == t:
			_hovered = null
			_show_details())
	# Right-click buys straight away.
	b.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			_selected = t
			buy(t))
	item_buttons.append(b)
	return b


func _refresh() -> void:
	_refresh_left = REFRESH_TIME
	var ess := essence()
	_essence_label.text = str(ess)
	_exchange.visible = shop != null and is_instance_valid(shop) and shop.has_method(&"exchange_crystals") \
			and shop.get("exchange_enabled") != false
	var stock: Variant = _stock_ids()
	var counts := owned_counts()
	for b in item_buttons:
		var t: Variant = b.get_meta("item_type")
		var price := price_of(t)
		var reason := buy_reason(t)
		var cost: Label = b.get_node("Cost")
		cost.text = str(price)
		var cheaper := price < total_cost_of(t)
		cost.add_theme_color_override("font_color", OWNED_COLOR if cheaper else ESSENCE_COLOR)
		var sold := is_sold_here(t, stock, reason)
		if not sold:
			b.modulate.a = 0.3
		elif price > ess:
			b.modulate.a = 0.45
		else:
			b.modulate.a = 1.0
		var border: Color = UIStyle.GOLD if t == _selected else TIER_COLORS[tier_of(t)]
		if b.get_meta("rim") != border:
			b.set_meta("rim", border)
			if t == _selected:
				HudSkin.style_button_selected(b)
			else:
				HudSkin.style_button(b, border)
		b.tooltip_text = tooltip_for(t, price, reason, counts)
	_show_details()


## Shop tooltip (items.md format): name, stats, passive / active text, then the price or the reason.
func tooltip_for(t: Variant, price: int, reason: String, counts: Dictionary) -> String:
	var lines: PackedStringArray = [name_of(t)]
	var st := stats_text(t)
	if st != "":
		lines.append(st)
	var tip: Variant = t.get("tooltip") if t is Object else null
	if tip != null and str(tip) != "":
		lines.append(str(tip))
	var stack: Variant = t.get("stack_max") if t is Object else null
	if tier_of(t) == Tier.CONSUMABLE and stack != null and int(stack) > 1:
		lines.append("Stacks to %d" % int(stack))
	if counts.get(id_of(t), 0) > 0:
		lines.append("Owned: %d" % int(counts[id_of(t)]))
	lines.append(("Cost %d" % price) if reason == "" or reason.begins_with("Not enough") else reason)
	lines.append("Sell %d" % int(total_cost_of(t) / 2))
	return "\n".join(lines)


func _show_details() -> void:
	var t: Variant = _hovered if _hovered != null else _selected
	_tree.data = recipe_tree(t) if t != null else {}
	_tree.queue_redraw()
	if t == null:
		_name.text = ""
		_stats.text = ""
		_text.text = "Items not available" if _missing.visible else "Pick an item"
		_buy.text = "Buy"
		_buy.disabled = true
		_reason.text = ""
		return
	_name.text = name_of(t)
	_stats.text = stats_text(t).replace(" · ", "\n")
	var tip: Variant = t.get("tooltip") if t is Object else null
	_text.text = str(tip) if tip != null else ""
	# The Buy button always acts on the selected item (hover only previews).
	var sel: Variant = _selected
	if sel == null:
		_buy.disabled = true
		return
	var price := price_of(sel)
	var reason := buy_reason(sel)
	var combine := not parts_of(sel).is_empty() and price < total_cost_of(sel)
	_buy.text = ("Combine %d" if combine else "Buy %d") % price
	_buy.disabled = reason != ""
	_reason.text = reason


# ---------------------------------------------------------------- inner controls

## The recipe tree of one item: the item 48 x 48, its parts 36 x 36, their parts 28 x 28 (3 levels).
## Draws `Recipes.tree(type, inventory)` (`{name, abbrev, tier, total_cost, owned, parts}`): carried parts
## get a green border; missing ones show their cost.
class RecipeTree extends Control:
	const HEIGHT := 150.0
	const SIZES := [48.0, 36.0, 28.0]
	const ROWS_Y := [0.0, 64.0, 116.0]
	var window: ShopWindow
	var data: Dictionary = {}

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _draw() -> void:
		if not data.is_empty():
			_node(data, 0, 0.0, size.x, null)

	func _node(n: Dictionary, level: int, x0: float, x1: float, parent_bottom: Variant) -> void:
		var s: float = SIZES[level]
		var cx := (x0 + x1) * 0.5
		var rect := Rect2(cx - s * 0.5, ROWS_Y[level], s, s)
		if parent_bottom is Vector2:
			draw_line(parent_bottom, Vector2(cx, rect.position.y), Color(ShopWindow.HudSkin.token(&"frame_light"), 0.7), 1.5)
		var owned := level > 0 and bool(n.get("owned", false))
		var tier := ShopWindow.tier_index(n.get("tier", 0))
		var rim: Color = ShopWindow.OWNED_COLOR if owned else ShopWindow.TIER_COLORS[tier]
		draw_style_box(ShopWindow.HudSkin.slot_frame(rim, ShopWindow.HudSkin.token(&"panel_inner")), rect)
		var font := ThemeDB.fallback_font
		var fs := 14 if level == 0 else (12 if level == 1 else 10)
		var show_cost := not owned and level > 0
		var tex := ShopWindow.HudSkin.icon("items", str(n.get("id", "")))
		if tex != null:
			var inset := 4.0 if level < 2 else 2.0
			draw_texture_rect(tex, rect.grow(-inset), false)
		else:
			var text_y := rect.position.y + s * 0.5 + fs * 0.35 - (4.0 if show_cost else 0.0)
			var ab := str(n.get("abbrev", ""))
			if ab == "":
				ab = UIStyle.abbrev(str(n.get("name", "?")))
			draw_string(font, Vector2(rect.position.x, text_y), ab, HORIZONTAL_ALIGNMENT_CENTER, s, fs,
					ShopWindow.HudSkin.token(&"text"))
		if show_cost:
			var cost := str(int(n.get("total_cost", 0)))
			var p := Vector2(rect.position.x, rect.end.y - 4.0)
			draw_string_outline(font, p, cost, HORIZONTAL_ALIGNMENT_CENTER, s, 9, 3, Color.BLACK)
			draw_string(font, p, cost, HORIZONTAL_ALIGNMENT_CENTER, s, 9, ShopWindow.ESSENCE_COLOR)
		var parts: Variant = n.get("parts", [])
		if level >= 2 or not (parts is Array) or (parts as Array).is_empty():
			return
		var w := (x1 - x0) / (parts as Array).size()
		for i in (parts as Array).size():
			if parts[i] is Dictionary:
				_node(parts[i], level + 1, x0 + w * i, x0 + w * (i + 1), Vector2(cx, rect.end.y))


## Drop an inventory slot here to sell it. Accepts drag data `int` (slot) or `{ "slot": int }`.
## Also takes the inventory bar's `{ "inventory_slot": int }`. Dashed `WARN` border; solid + tinted while an
## item is dragged over it.
class SellZone extends PanelContainer:
	var window: ShopWindow
	var _hot := false

	func _init() -> void:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var l := ShopWindow.HudSkin.text("Drop an item here to sell", 12, ShopWindow.HudSkin.token(&"text_muted"))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(l)
		mouse_exited.connect(func() -> void: _set_hot(false))

	func _set_hot(on: bool) -> void:
		if on != _hot:
			_hot = on
			queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_DRAG_END:
			_set_hot(false)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size).grow(-0.5)
		if _hot:
			draw_rect(r, Color(UIStyle.WARN, 0.15))
			draw_rect(r, UIStyle.WARN, false, 1.0)
		else:
			ShopWindow.HudSkin.draw_dashed_rect(self, r, Color(UIStyle.WARN, 0.6))

	func _slot_of(data: Variant) -> int:
		if data is int:
			return data
		if data is Dictionary and data.has("slot"):
			return int(data["slot"])
		if data is Dictionary and data.has("inventory_slot"):
			return int(data["inventory_slot"])
		return -1

	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		var ok := _slot_of(data) >= 0
		_set_hot(ok)
		return ok

	func _drop_data(_pos: Vector2, data: Variant) -> void:
		_set_hot(false)
		window.sell_slot(_slot_of(data))


## A grid button whose tooltip is the styled panel (section 8), name in the tier colour.
class ShopButton extends Button:
	var tier_color := Color.WHITE

	func _make_custom_tooltip(for_text: String) -> Object:
		return ShopWindow.HudSkin.tooltip_panel(for_text, tier_color, true)
