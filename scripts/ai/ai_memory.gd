class_name AIMemory
extends RefCounted
## What the bot has seen (docs/design/ai.md "What the bot knows"). The Commander calls see_unit /
## see_building for every enemy standing in a cell its team's fog of war shows as VISIBLE this tick
## (6.A1; without a fog, or with the fog off: within 16 m of its units / 20 m of its buildings); nothing
## else enters. Units are forgotten `memory_seconds` after they were last seen. Buildings don't move,
## so they are remembered until they are destroyed. Dead things leave at once.
## Strength (ai.md + levels.md "The bot"): a soldier = cost x (0.8 + 0.2 x veterancy level), a worker 0,
## a wizard 170 + 30 x level + carried items / 5, a (finished) tower 120, a Ruin Warden 100 (items.md
## "The bot": Vessa's items are read when she is seen, like her level). A dead wizard is dropped from memory at once, so a dead Vessa counts 0.
## A champion (9.C9, champions.md 10) = its power() (150 + 50 x level + items / 5); it counts as a fighter.

const STRENGTH_WIZARD := 200.0              ## A level-1 wizard (wizard_strength(1)).
const STRENGTH_WIZARD_BASE := 170.0
const STRENGTH_WIZARD_PER_LEVEL := 30.0
const STRENGTH_TOWER := 150.0              ## balance-1.md 2f (750 HP spires).
const STRENGTH_WARDEN := 200.0             ## balance-1.md 2f (300 HP wardens).
const ITEM_STRENGTH_DIVISOR := 5.0          ## items.md: 1 essence of items = 0.2 of strength.
const RANGED_MIN_RANGE := 3.0   ## Units with a longer attack range shoot (Unit.attack_range doc).

## instance id -> {"node": WeakRef, "type": StringName, "pos": Vector3, "time": float,
## "strength": float, "pop": int, "soldier": bool, "wizard": bool, "ranged": bool, "champion": bool, "worker": bool}
var units: Dictionary = {}
## instance id -> {"node": WeakRef, "type": StringName, "kind": StringName, "pos": Vector3,
## "time": float, "strength": float}
var buildings: Dictionary = {}


## The strength of a unit or building (0 for workers and plain buildings).
static func strength_of(node: Node) -> float:
	if node is Wizard:
		return wizard_strength((node as Wizard).level) + item_strength(node)
	if node is Champion:
		return (node as Champion).power()
	if node is Unit:
		var t := (node as Unit).unit_type
		if t == null or t.is_worker:
			return 0.0
		if t.id == &"ruin_warden":
			return STRENGTH_WARDEN
		if CasterKit.is_caster_unit(node):   # caster-units.md 8.2: cost x 0.5, x 1.0 with mana for two casts
			return CasterKit.bot_strength(node as Unit) + item_strength(node)
		return soldier_strength(t.cost, (node as Unit).level) + item_strength(node)
	if node is Building:
		var b := node as Building
		if b.building_type and b.building_type.kind == &"tower" and b.is_constructed():
			return STRENGTH_TOWER
	return 0.0


## levels.md: 170 + 30 x level (L1 = 200, L8 = 440).
static func wizard_strength(wizard_level: int) -> float:
	return STRENGTH_WIZARD_BASE + STRENGTH_WIZARD_PER_LEVEL * float(maxi(1, wizard_level))


## levels.md: cost x (0.8 + 0.2 x level): Recruit 1.0, Veteran 1.2, Elite 1.4, Champion 1.6 x cost.
static func soldier_strength(cost: int, unit_level: int) -> float:
	return float(cost) * (0.8 + 0.2 * float(clampi(unit_level, 1, 4)))


## items.md "The bot" (4.A1): a wizard's carried items add total_cost / 5 (Inventory.total_item_value()).
## Only wizards carry items; 0 for everything else and while the items system is missing.
static func item_strength(node: Node) -> float:
	if not node is Wizard:
		return 0.0
	return AIItems.item_value(node) / ITEM_STRENGTH_DIVISOR


func see_unit(u: Unit, now: float) -> void:
	var id := u.get_instance_id()
	var e: Dictionary = units.get(id, {})
	if e.is_empty():
		var t := u.unit_type
		e["node"] = weakref(u)
		e["type"] = t.id if t else &"wizard"
		e["soldier"] = t != null and not t.is_worker
		e["wizard"] = u is Wizard
		e["champion"] = u is Champion
		e["worker"] = t != null and t.is_worker
		e["pop"] = t.pop if t else 0
		e["ranged"] = u.attack_range > RANGED_MIN_RANGE
		units[id] = e
	e["pos"] = u.global_position
	e["time"] = now
	e["strength"] = strength_of(u)


func see_building(b: Building, now: float) -> void:
	var id := b.get_instance_id()
	var e: Dictionary = buildings.get(id, {})
	if e.is_empty():
		e["node"] = weakref(b)
		e["type"] = b.building_type.id if b.building_type else &""
		e["kind"] = b.building_type.kind if b.building_type else &""
		e["pos"] = b.global_position
		buildings[id] = e
	e["time"] = now
	e["strength"] = strength_of(b)


## Drops units not seen for `memory_seconds` and everything that died.
func forget(now: float, memory_seconds: float) -> void:
	for id in units.keys():
		var e: Dictionary = units[id]
		if now - float(e["time"]) > memory_seconds or not _alive(e):
			units.erase(id)
	for id in buildings.keys():
		if not _alive(buildings[id]):
			buildings.erase(id)


## seen_strength: remembered enemy soldiers, wizard and towers.
func strength() -> float:
	var s := 0.0
	for e: Dictionary in units.values():
		s += float(e["strength"])
	for e: Dictionary in buildings.values():
		s += float(e["strength"])
	return s


## Strength of what was seen within `radius` of `pos` in the last `max_age` seconds.
func strength_near(pos: Vector3, radius: float, now: float, max_age: float) -> float:
	var s := 0.0
	var r2 := radius * radius
	for e: Dictionary in units.values():
		if now - float(e["time"]) <= max_age and _dist2(e["pos"], pos) <= r2:
			s += float(e["strength"])
	for e: Dictionary in buildings.values():
		if float(e["strength"]) > 0.0 and _dist2(e["pos"], pos) <= r2:
			s += float(e["strength"])
	return s


## True if an enemy soldier, wizard or champion was seen within `radius` of `pos` in the last `max_age` s.
func fighter_near(pos: Vector3, radius: float, now: float, max_age: float) -> bool:
	var r2 := radius * radius
	for e: Dictionary in units.values():
		if (e["soldier"] or e["wizard"] or e["champion"]) and now - float(e["time"]) <= max_age \
				and _dist2(e["pos"], pos) <= r2:
			return true
	return false


## The living enemy units seen at `now` (this tick's sightings), as nodes (9.C9 bounty rules: no map hacks).
func seen_now(now: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for e: Dictionary in units.values():
		if now - float(e["time"]) > 0.001:
			continue
		var u := (e["node"] as WeakRef).get_ref() as Unit
		if u and u.is_alive():
			out.append(u)
	return out


## The remembered living building nearest to `pos` within `max_dist` (any kind if `kind` is empty;
## never of kind `skip_kind`, never one whose instance id is a key of `skip_ids`).
func nearest_building(pos: Vector3, max_dist: float = INF, kind: StringName = &"",
		skip_kind: StringName = &"", skip_ids: Dictionary = {}) -> Building:
	var best: Building = null
	var best_d := max_dist * max_dist if max_dist < INF else INF
	for id: int in buildings:
		var e: Dictionary = buildings[id]
		if (kind != &"" and e["kind"] != kind) or (skip_kind != &"" and e["kind"] == skip_kind):
			continue
		if not skip_ids.is_empty() and skip_ids.has(id):
			continue
		var d := _dist2(e["pos"], pos)
		if d <= best_d:
			var b := (e["node"] as WeakRef).get_ref() as Building
			if b and b.is_alive():
				best_d = d
				best = b
	return best


## Seen enemy soldier pop by kind: {"ranged": int, "melee": int, "total": int}.
func soldier_mix() -> Dictionary:
	var ranged := 0
	var melee := 0
	for e: Dictionary in units.values():
		if not e["soldier"]:
			continue
		if e["ranged"]:
			ranged += int(e["pop"])
		else:
			melee += int(e["pop"])
	return {"ranged": ranged, "melee": melee, "total": ranged + melee}


static func _alive(e: Dictionary) -> bool:
	var n: Object = (e["node"] as WeakRef).get_ref()
	return n != null and bool(n.call(&"is_alive"))


static func _dist2(a: Vector3, b: Vector3) -> float:
	return (a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z)
