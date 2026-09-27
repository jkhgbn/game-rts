class_name AIItems
extends RefCounted
## The bot's items (docs/design/items.md "The bot", task 4.A1). Owned by the Commander, one per bot.
## Shopping: while Malrik is alive and within 12 m of an own shop (keep / Gloom Hall), one purchase per
## tick: first a Draught restock, else the next entry of the difficulty's build list (in order; the
## inventory's buy() / Recipes consume the parts already carried). Uses: Ember Draught under 50 % HP,
## Brace under 40 % HP with an enemy within 8 m, Blink toward the keep under 25 % HP (once per scare),
## Stride when an attack or a retreat starts, Rallying Cry when 3+ own soldiers within 10 m are hurt
## (Overgrowth of Heart of the Grove: the same rule within 8 m, kingdom-nature.md 5).
## The items system (scripts/items/, data/items/) is written by other agents and may be missing or
## partial: everything is reached through has_method / get / ResourceLoader.exists and no static type
## from scripts/items/ is used. With no inventory the bot plays exactly as before.

const SHOP_RADIUS := 12.0
const DRAUGHT := "ember_draught"
const DRAUGHT_HP := 0.5
const DRAUGHT_TIME := 8.0          ## A Draught heals over 8 s: don't drink another meanwhile.
const BRACE_HP := 0.4
const BRACE_ENEMY := 8.0
const BLINK_HP := 0.25
const BLINK_RANGE := 10.0
const BLINK_RESET_HP := 0.7        ## Blink again only after HP went back above this.
const CRY_RADIUS := 10.0
const CRY_HP := 0.6
const CRY_UNITS := 3
const DRAUGHT_ITEMS: Array[String] = [DRAUGHT]
const BRACE_ITEMS: Array[String] = ["bulwark_of_ruin", "ruinwarden_mantle"]
const BLINK_ITEMS: Array[String] = ["shadowstride"]
const STRIDE_ITEMS: Array[String] = ["ashen_greaves"]
const CRY_ITEMS: Array[String] = ["banner_of_embers"]
## kingdom-ice.md 6: Glacier Shell (Winterwall Aegis) when HP < 25 % and an enemy is within 6 m.
const SHELL_ITEMS: Array[String] = ["winterwall_aegis"]
const SHELL_HP := 0.25
const SHELL_ENEMY := 6.0
## kingdom-nature.md 5: Overgrowth (Heart of the Grove) when 3+ own soldiers within 8 m are under 60 % HP.
const OVERGROWTH_ITEMS: Array[String] = ["heart_of_the_grove"]
const OVERGROWTH_RADIUS := 8.0
const ITEM_PATH := "res://data/items/%s.tres"
const ITEM_TYPE_SCRIPT := "res://scripts/items/item_type.gd"
const RECIPES_SCRIPT := "res://scripts/items/recipes.gd"
const BANK_SCRIPT := "res://scripts/items/essence_bank.gd"
const OK_REASON := ""
const NOT_SOLD := "Not sold here"

var build: PackedStringArray                 ## Read only: the build list (item ids, in order).
var potion_stock := 1                        ## Read only: most Draughts kept in stock.
var build_index := 0                         ## Read only: build entries bought (or skipped) so far.
var bought: Array[String] = []               ## Read only: every purchase, in order (list + restocks).
var used: Array[String] = []                 ## Read only: every active / consumable used, in order.

var _team := 0
var _types := {}                             # id -> Resource (found ones only)
var _scripts := {}                           # path -> Script (found ones only)
var _potion_until := -INF
var _blink_ready := true
var _price_cache := {}                       # 20.A3: "item|carried ids" -> price() (Recipes.plan is not cheap)
var _skip_checked := {}                      # 20.A3: "item id|carried ids" already asked can_buy() while unaffordable

static var _has_cache := {}                  # 20.A3: "script id:function" -> bool (_script_has)


func _init(team: int, build_list: PackedStringArray, stock: int) -> void:
	_team = team
	build = build_list
	potion_stock = stock


# ---------------------------------------------------------------- static helpers (also for AIMemory)

## The wizard's Inventory (`wizard.inventory`, else a child named "Inventory"), or null.
static func inventory_of(w: Node) -> Object:
	if w == null or not is_instance_valid(w):
		return null
	var inv: Variant = w.get(&"inventory")
	if inv is Object and is_instance_valid(inv):
		return inv
	return w.get_node_or_null(^"Inventory")


## `Inventory.total_item_value()` of a wizard (0 without items).
static func item_value(w: Node) -> float:
	var inv := inventory_of(w)
	if inv == null or not inv.has_method(&"total_item_value"):
		return 0.0
	return float(inv.call(&"total_item_value"))


## The item type in a slot entry (`{type, count, cooldown_left}`, or the type itself), else null.
static func slot_type(entry: Variant) -> Object:
	if entry is Dictionary:
		var t: Variant = (entry as Dictionary).get("type")
		return t if t is Object else null
	if entry is Object and is_instance_valid(entry):
		var t: Variant = (entry as Object).get(&"type")
		if t is Object:
			return t
		if (entry as Object).get(&"id") != null:
			return entry
	return null


static func type_id(t: Object) -> String:
	if t == null:
		return ""
	var id: Variant = t.get(&"id")
	return str(id) if id != null else ""


## True if `s` is a Script declaring a function `fn_name` (static functions included). 20.A3: cached per script and
## name (get_script_method_list() builds the whole method list: it was called several times per think tick).
static func _script_has(s: Variant, fn_name: String) -> bool:
	if not s is Script:
		return false
	var key := "%d:%s" % [(s as Script).get_instance_id(), fn_name]
	var hit: Variant = _has_cache.get(key)
	if hit != null:
		return hit
	var found := false
	for m: Dictionary in (s as Script).get_script_method_list():
		if str(m.get("name", "")) == fn_name:
			found = true
			break
	_has_cache[key] = found
	return found


static func slot_field(entry: Variant, field: String, fallback: Variant) -> Variant:
	if entry is Dictionary:
		return (entry as Dictionary).get(field, fallback)
	if entry is Object and is_instance_valid(entry):
		var v: Variant = (entry as Object).get(StringName(field))
		return v if v != null else fallback
	return fallback


# ---------------------------------------------------------------- lookups

## The ItemType resource of `id` (data/items/<id>.tres, else ItemType.find), or null.
func type_of(id: String) -> Object:
	if _types.has(id):
		return _types[id]
	var t: Object = null
	var path := ITEM_PATH % id
	if ResourceLoader.exists(path):
		t = load(path)
	else:
		var s := _script(ITEM_TYPE_SCRIPT)
		if _script_has(s, "find"):
			var r: Variant = (s as Object).call(&"find", id)
			t = r if r is Object else null
	if t != null:
		_types[id] = t
	return t


## The script at path once it exists (cached), else null.
func _script(path: String) -> Script:
	if _scripts.has(path):
		return _scripts[path]
	if not ResourceLoader.exists(path):
		return null
	var s := load(path) as Script
	if s:
		_scripts[path] = s
	return s


## Team essence (EssenceBank, else Economy.essence); -1 when unknown.
func essence() -> int:
	var bank_script := _script(BANK_SCRIPT)
	if _script_has(bank_script, "for_team"):
		var bank: Variant = bank_script.call(&"for_team", _team)
		if bank is Object and is_instance_valid(bank) and (bank as Object).get(&"essence") != null:
			return int((bank as Object).get(&"essence"))
	var eco := Economy.for_team(_team)
	if eco and eco.get(&"essence") != null:
		return int(eco.get(&"essence"))
	return -1


## What buying `t` costs now (Recipes.plan with the carried parts, else total_cost / cost). 20.A3: the price only
## depends on the item and the parts carried, so it is remembered per (item, carried item ids): Recipes.plan (shop
## lookup, sold-at bits) was the costliest call of the think tick, asked up to 5 times per tick.
func price(inv: Object, t: Object) -> int:
	var key := "%d|%s" % [t.get_instance_id(), _carried_key(inv)]
	var hit: Variant = _price_cache.get(key)
	if hit != null:
		return hit
	var p := _price_now(inv, t)
	if _price_cache.size() > 64:
		_price_cache.clear()
	_price_cache[key] = p
	return p


## The carried item ids in slot order ("" for an empty slot): what a recipe price depends on.
func _carried_key(inv: Object) -> String:
	if inv == null:
		return ""
	var slots: Variant = inv.get(&"slots")
	if not slots is Array:
		return ""
	var ids := PackedStringArray()
	for entry: Variant in slots:
		ids.append(type_id(slot_type(entry)))
	return ",".join(ids)


func _price_now(inv: Object, t: Object) -> int:
	var recipes := _script(RECIPES_SCRIPT)
	if _script_has(recipes, "plan"):
		var plan: Variant = recipes.call(&"plan", inv, t)
		if plan is Dictionary:
			for key in ["essence", "essence_cost", "cost", "price"]:
				if (plan as Dictionary).has(key):
					return int((plan as Dictionary)[key])
	if t.has_method(&"total_cost"):
		return int(t.call(&"total_cost"))
	var c: Variant = t.get(&"cost")
	return int(c) if c != null else 0


func count_of(inv: Object, id: String) -> int:
	var n := 0
	var slots: Variant = inv.get(&"slots")
	if not slots is Array:
		return 0
	for entry: Variant in slots:
		if type_id(slot_type(entry)) == id:
			n += maxi(1, int(slot_field(entry, "count", 1)))
	return n


func slot_of(inv: Object, ids: Array[String]) -> int:
	var slots: Variant = inv.get(&"slots")
	if not slots is Array:
		return -1
	for i in (slots as Array).size():
		var entry: Variant = (slots as Array)[i]
		if ids.has(type_id(slot_type(entry))) and float(slot_field(entry, "cooldown_left", 0.0)) <= 0.0:
			return i
	return -1


## True if an own shop (a building answering is_shop(), else a finished keep / barracks) is within 12 m.
static func shop_near(w: Node3D, own_buildings: Array) -> bool:
	for b: Variant in own_buildings:
		if b == null or not is_instance_valid(b):
			continue
		var bld := b as Building
		if bld == null or not bld.is_alive():
			continue
		var shop := false
		if bld.has_method(&"is_shop"):
			shop = bool(bld.call(&"is_shop"))
		else:
			shop = bld.is_constructed() and (bld is Keep or (bld.building_type != null \
					and bld.building_type.kind == &"barracks"))
		if shop and Vector2(bld.global_position.x - w.global_position.x,
				bld.global_position.z - w.global_position.z).length() <= SHOP_RADIUS:
			return true
	return false


# ---------------------------------------------------------------- shopping

## Draughts the list has bought so far (capped by potion_stock): the stock to keep.
func _stock_target() -> int:
	var n := 0
	for i in mini(build_index, build.size()):
		if build[i] == DRAUGHT:
			n += 1
	return mini(n, potion_stock)


## The next thing to buy: {"type", "id", "list": bool}, or {} (list done / items missing).
## Entries whose ItemType doesn't exist are skipped (logged once by the caller).
func next_purchase(inv: Object) -> Dictionary:
	if count_of(inv, DRAUGHT) < _stock_target():
		var d := type_of(DRAUGHT)
		if d:
			return {"type": d, "id": DRAUGHT, "list": false}
	while build_index < build.size():
		var id := build[build_index]
		var t := type_of(id)
		if t:
			return {"type": t, "id": id, "list": true}
		build_index += 1
	return {}


## One purchase at most. Returns a log line ("" = nothing bought).
func shop_tick(inv: Object) -> String:
	if not inv.has_method(&"buy"):
		return ""
	var p := next_purchase(inv)
	if p.is_empty():
		return ""
	var t: Object = p["type"]
	# 20.A3: while the essence can't pay, can_buy() (a full Recipes.plan with the shop lookup) can only refuse: it is
	# asked once per (item, carried parts) for the skip reasons below, not every think tick.
	var have := essence()
	if have >= 0 and have < price(inv, t):
		var key := "%s|%s" % [p["id"], _carried_key(inv)]
		if _skip_checked.has(key):
			return ""
		_skip_checked[key] = true
	if inv.has_method(&"can_buy"):
		var reason := str(inv.call(&"can_buy", t))
		if (reason == NOT_SOLD or reason.begins_with("Needs ")) and bool(p["list"]):
			build_index += 1   # peddler-only: the bot never visits one (items.md)
			return "ITEM skip %s (%s)" % [p["id"], reason]
		if reason != OK_REASON:
			return ""
	var before := essence()
	var r: Variant = inv.call(&"buy", t)
	var ok: bool = (r is String and r == OK_REASON) or (r is bool and r)
	if not ok:
		return ""
	if bool(p["list"]):
		build_index += 1
	bought.append(str(p["id"]))
	return "ITEM bought %s (%s #%d), essence %d -> %d" % [p["id"], "list" if p["list"] else "restock",
			build_index, before, essence()]


## True when the next purchase is affordable now (walk back to the shop for it).
func wants_shop(inv: Object) -> bool:
	if not inv.has_method(&"buy"):
		return false
	var p := next_purchase(inv)
	if p.is_empty():
		return false
	var have := essence()
	return have >= 0 and have >= price(inv, p["type"])


# ---------------------------------------------------------------- using

## Draught / Brace / Blink / Rallying Cry rules. Returns log lines.
func use_tick(w: Wizard, inv: Object, now: float, enemy_close: bool, home: Vector3, soldiers: Array,
		enemy_very_close: bool = false) -> Array[String]:
	var out: Array[String] = []
	if not inv.has_method(&"use_item"):
		return out
	var ratio := w.hp / maxf(w.max_hp, 1.0)
	if ratio < SHELL_HP and enemy_very_close:
		_use(inv, SHELL_ITEMS, w, out)
	if ratio >= BLINK_RESET_HP:
		_blink_ready = true
	if ratio < DRAUGHT_HP and now >= _potion_until:
		if _use(inv, DRAUGHT_ITEMS, w, out):
			_potion_until = now + DRAUGHT_TIME
	if ratio < BRACE_HP and enemy_close:
		_use(inv, BRACE_ITEMS, w, out)
	if ratio < BLINK_HP and _blink_ready:
		var dir := home - w.global_position
		dir.y = 0.0
		if dir.length() > 1.0:
			var to := w.global_position + dir.normalized() * minf(BLINK_RANGE, dir.length())
			if _use(inv, BLINK_ITEMS, to, out):
				_blink_ready = false
	if slot_of(inv, CRY_ITEMS) >= 0 and hurt_near(w, soldiers, CRY_RADIUS) >= CRY_UNITS:
		_use(inv, CRY_ITEMS, w, out)
	if slot_of(inv, OVERGROWTH_ITEMS) >= 0 and hurt_near(w, soldiers, OVERGROWTH_RADIUS) >= CRY_UNITS:
		_use(inv, OVERGROWTH_ITEMS, w, out)
	return out


## Living units of `soldiers` under 60 % HP within `radius` of the wizard.
static func hurt_near(w: Node3D, soldiers: Array, radius: float) -> int:
	var hurt := 0
	for s: Variant in soldiers:
		var u := s as Unit
		if u and is_instance_valid(u) and u.is_alive() and u.hp < CRY_HP * u.max_hp \
				and Vector2(u.global_position.x - w.global_position.x,
				u.global_position.z - w.global_position.z).length() <= radius:
			hurt += 1
	return hurt


## Stride when an attack or a retreat starts.
func on_move_start(w: Wizard, inv: Object) -> Array[String]:
	var out: Array[String] = []
	if inv != null and inv.has_method(&"use_item"):
		_use(inv, STRIDE_ITEMS, w, out)
	return out


func _use(inv: Object, ids: Array[String], target: Variant, out: Array[String]) -> bool:
	var slot := slot_of(inv, ids)
	if slot < 0:
		return false
	var id := type_id(slot_type((inv.get(&"slots") as Array)[slot]))
	var r := str(inv.call(&"use_item", slot, target))
	if r != OK_REASON:
		return false
	used.append(id)
	out.append("ITEM used %s (slot %d)" % [id, slot + 1])
	return true
