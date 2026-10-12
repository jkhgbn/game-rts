class_name ChampionSense
extends Node
## What a team's champions know (docs/design/champions.md 8.4, task 9.C5). One node per team (group
## "champion_senses"), created on demand by `ChampionSense.for_team(team)` as a child of the current scene.
## Every 0.5 s ONE pass over the groups "units" and "buildings" (plus the few "bounties", "taverns",
## "lost_caches", "peddlers" / "shops" nodes) fills a cache that every ChampionBrain of the team reads:
## - `enemies`: enemy (and neutral) units standing on a cell the team's fog shows VISIBLE now:
##   {node, pos, strength, worker, melee, hero, champion, target, hp_ratio, loot (a Magpie's carried gold, 10.A3)};
## - `workers_seen`: enemy workers seen in the last 30 s (last seen position);
## - `structures`: enemy towers / keeps on EXPLORED cells (known): {node, pos, strength 150 / 250, reach};
## - own side: completed buildings, soldiers, wizard, champions, keep, usable shops, and `hits` (own units /
##   buildings hit in the last 2 s by a visible enemy that targets them);
## - own bounties (`bounties`, `bounty_version` changes when one is placed / raised / removed), taverns
##   (door point, held by the enemy or not), Lost Caches.
## Knowledge comes only from the fog (`FogOfWar.state_at(team, pos)`); no fog node or fog off: all visible.
## Other step-9 classes (Champion, Bounty, Tavern...) are reached through groups / get() / has_method().
## 12.A2 map fill (docs/design/map-fill.md 6), each list empty when its system is absent (groups + has_method only):
## - `points`: the capture points (landmarks, known from 0:00): {node, pos, kind, owner, bank, radius, stand};
## - `camps`: the neutral camps, alive / strength remembered from the last time the spot was VISIBLE (never seen:
##   assumed alive): {node, pos, tier, alive, strength, visible, explored}; a camp's aggro zone (CAMP_ZONE) adds its
##   strength to `danger_at` while the spot is not visible (visible creatures count as enemies, with their 5.1
##   strength x camp level); `camp_zone_at` / `camp_blocking` let brains keep out of camp aggro;
## - `beasts`: epic beasts visible now or seen in the last 30 s: {node, pos, strength, time, visible, center, leash};
## - `critters`: game critters visible to the team now within 20 m of an own Wayfinder / Coin-Cutter (the R9 idle
##   hunters): {node, pos, kind};
## - the beast hunting party (`party_target(champion)`): 2+ free champions, sum(courage x power) >= 1.2 x strength.

const REFRESH := 0.5
const WORKER_MEMORY := 30.0         ## Enemy workers are remembered this long after they were last seen.
const HIT_WINDOW := 2.0             ## An own thing hit this recently counts as "being hit" (rule R4).
const DANGER_RADIUS := 15.0         ## 8.2: visible enemies within 15 m of a point.
const TOWER_DANGER := 150.0
const KEEP_DANGER := 250.0
const COVER_MARGIN := 5.0           ## 8.2: a tower / keep whose range + 5 m covers the point.
const HELD_RADIUS := 12.0           ## Section 2: a tavern door is held by the enemy within 12 m.
const DOOR_FACTOR := 0.8            ## Section 2: door point = tavern spot x 0.8.
const DEFAULT_TOWER_RANGE := 10.0
const MELEE_RANGE := 3.0            ## Units with a longer attack range shoot (Unit.attack_range doc).
# 12.A2 map fill
const CAMP_ZONE := 10.0             ## A camp's aggro zone around its spot (aggro 6-8 + the creatures' ring of 2 m).
const CREATURE_DEFAULT := 100.0     ## Strength of a creature whose id is not in CampManager.CREATURE_STRENGTH.
const BEAST_DEFAULT := 900.0
const BEAST_MEMORY := 30.0          ## A beast seen this recently is still known (the hunting party).
const BEAST_LEASH_EXTRA := 10.0     ## A beast's territory = lair radius + this (EpicBeasts.LEASH_EXTRA).
const PARTY_NEAR := 40.0            ## A known beast this close to a free champion can start a party...
const PARTY_JOIN := 60.0            ## ...and every free champion this close to it takes part.
const PARTY_START := 1.2            ## sum(courage x power) >= this x the beast's strength starts a hunt...
const PARTY_ABORT := 0.8            ## ...which ends below this x (a champion fled / fell).
const PARTY_MIN := 2                ## Never with a single champion.
const PARTY_HP := 0.7               ## A champion joins a new hunt only above this HP ratio.
const TERRITORY_MARGIN := 2.0
const CRITTER_SCAN := 20.0          ## `critters` only lists those this close to an own Wayfinder / Coin-Cutter.

## Perf counters (read only): microseconds spent in refresh() by every sense, and the pass count.
static var usec_total := 0
static var passes := 0
static var _by_team: Dictionary = {}   # team -> ChampionSense

var team := 0
var now := 0.0                       ## Game seconds since this sense was created (brains share it).
var version := 0                     ## +1 per refresh.
var bounty_version := 0              ## +1 whenever the team's bounties change (placed, raised, removed).
## +1 when a Magpie carrying loot comes into view (10.A3): a Coin-Cutter re-plans at once (its Raid default takes a
## looter within 30 m first), not at its next 2 s plan tick, when it may already have walked out of sight.
var looter_version := 0
var _looters_seen: Dictionary = {}   # instance id of the looters visible at the last pass -> true

var enemies: Array[Dictionary] = []
var workers_seen: Dictionary = {}    # instance id -> {node: WeakRef, pos, time}
var structures: Array[Dictionary] = []
var own_buildings: Array[Dictionary] = []   # completed + alive: {node, pos, kind, radius, since_damage, shop}
var own_soldiers: Array = []                # Units: not workers, wizards, champions or summons
var own_soldier_pos := PackedVector3Array() # their positions at this pass (same order)
var own_champions: Array = []
var own_wizard: Node3D = null               # living wizard or null
var own_keep: Node3D = null                 # living own keep or null
var hits: Array[Dictionary] = []            # {node, pos, building: bool, attackers: Array[Dictionary]}
var shops: Array = []                       # usable shops: own is_shop() buildings + Ruin Peddlers
var bounties: Array = []                    # own, valid
var taverns: Array[Dictionary] = []         # {node, door: Vector3, held: bool}
var caches: Array = []                      # every node in "lost_caches"
var enemy_home := Vector3.ZERO              ## Where the enemy lives (its base centre / keep).
var home_point := Vector3.ZERO              ## Own keep (or oldest barracks, or the level's base centre).
# 12.A2 map fill (see the header)
var points: Array[Dictionary] = []
var camps: Array[Dictionary] = []
var beasts: Array[Dictionary] = []
var critters: Array[Dictionary] = []
var party_beast: Node3D = null              ## Read only: the beast the team's hunting party is after (or null).
var party_members: Array = []               ## Read only: its champions.

var _camp_memory := {}      # camp instance id -> {alive, strength} at the last sighting of its spot
var _camp_fixed := {}       # camp instance id -> {tier, pos, full strength} (read once)
var _point_nodes: Array = []   # the capture points `points` was built from
var _beast_memory := {}     # beast instance id -> {node: WeakRef, pos, time, strength, center, leash}
var _creature_strength := {}   # creature instance id -> strength (this pass)
var _creature_base: Dictionary = {}   # creature type id -> 5.1 strength (CampManager.CREATURE_STRENGTH)
var _level_strength := 0.15
var _bank_cache := {}       # Vector2i (metre grid) -> bank
var _party_version := -1
var _left := 0.0
var _bounty_sig := 0
var _fog: FogOfWar = null
var _own_fighters: Array[Vector3] = []      # positions of own soldiers / wizard / champions (held check)


## The sense of `for_team_id`, created (child of the current scene) if missing.
static func for_team(for_team_id: int) -> ChampionSense:
	var existing: Variant = _by_team.get(for_team_id)
	if existing != null and is_instance_valid(existing) and not (existing as Node).is_queued_for_deletion():
		return existing as ChampionSense
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(&"champion_senses"):
		var s := node as ChampionSense
		if s and s.team == for_team_id and not s.is_queued_for_deletion():
			_by_team[for_team_id] = s
			return s
	var sense := ChampionSense.new()
	sense.team = for_team_id
	sense.name = "ChampionSense%d" % for_team_id
	sense._left = 0.25 * float(posmod(for_team_id, 2))   # the two teams refresh on different frames
	var parent: Node = tree.current_scene if tree.current_scene else tree.root
	parent.add_child.call_deferred(sense)
	_by_team[for_team_id] = sense
	return sense


func _enter_tree() -> void:
	add_to_group(&"champion_senses")


func _physics_process(delta: float) -> void:
	now += delta
	_left -= delta
	if _left > 0.0:
		return
	_left += REFRESH
	if _left < 0.0:
		_left = REFRESH
	if _team_has_champion():
		refresh()   # no champion of this team: nobody reads the cache, skip the pass


func _team_has_champion() -> bool:
	for node in get_tree().get_nodes_in_group(&"champions"):
		var t: Variant = node.get(&"team")
		if t != null and int(t) == team:
			return true
	return false


# ---------------------------------------------------------------- queries (brains)

## FogOfWar state (0 unexplored, 1 explored, 2 visible) of `pos` for this team; VISIBLE without a fog.
func state_at(pos: Vector3) -> int:
	if _fog == null or not is_instance_valid(_fog):
		_fog = FogOfWar.find()
	if _fog == null:
		return FogOfWar.VISIBLE
	return _fog.state_at(team, pos)


func is_visible_pos(pos: Vector3) -> bool:
	return state_at(pos) == FogOfWar.VISIBLE


## True if `node` is known now: an own thing, or something standing on a VISIBLE cell.
func knows(node: Variant) -> bool:
	if node == null or not is_instance_valid(node) or not node is Node3D:
		return false
	var t: Variant = (node as Node3D).get(&"team")
	if t != null and int(t) == team:
		return true
	return is_visible_pos((node as Node3D).global_position)


## 8.2 danger at `pos`: strength of visible enemies within `radius` + known towers (150) / keeps (250)
## whose range + 5 m covers it. `wizard_mult`: an enemy wizard above 50 % HP counts this many times.
func danger_at(pos: Vector3, radius: float = DANGER_RADIUS, wizard_mult: float = 1.0) -> float:
	var d := 0.0
	var r2 := radius * radius
	for e: Dictionary in enemies:
		var p: Vector3 = e["pos"]
		if (p.x - pos.x) * (p.x - pos.x) + (p.z - pos.z) * (p.z - pos.z) <= r2:
			var s := float(e["strength"])
			if wizard_mult != 1.0 and bool(e["hero"]) and float(e["hp_ratio"]) > 0.5:
				s *= wizard_mult
			d += s
	for s: Dictionary in structures:
		var p2: Vector3 = s["pos"]
		var reach := float(s["reach"])
		if (p2.x - pos.x) * (p2.x - pos.x) + (p2.z - pos.z) * (p2.z - pos.z) <= reach * reach:
			d += float(s["strength"])
	# 12.A2: a remembered living camp whose spot is not visible now (visible creatures are in `enemies`)
	var z2 := CAMP_ZONE * CAMP_ZONE
	for c: Dictionary in camps:
		if not bool(c["alive"]) or bool(c["visible"]):
			continue
		var p3: Vector3 = c["pos"]
		if (p3.x - pos.x) * (p3.x - pos.x) + (p3.z - pos.z) * (p3.z - pos.z) <= z2:
			d += float(c["strength"])
	return d


## 12.A2: the remembered living camp whose aggro zone holds `pos` ({} if none); `ignore` = a camp node to skip.
func camp_zone_at(pos: Vector3, ignore: Variant = null) -> Dictionary:
	var z2 := CAMP_ZONE * CAMP_ZONE
	for c: Dictionary in camps:
		if not bool(c["alive"]) or c["node"] == ignore:
			continue
		var p: Vector3 = c["pos"]
		if (p.x - pos.x) * (p.x - pos.x) + (p.z - pos.z) * (p.z - pos.z) <= z2:
			return c
	return {}


## 12.A2: the first remembered living camp whose aggro zone the straight walk `from` -> `to` crosses ({} if none).
## Camps whose zone holds `from` (walking out) or `to` (the goal itself) are skipped.
func camp_blocking(from: Vector3, to: Vector3, ignore: Variant = null) -> Dictionary:
	var seg := Vector2(to.x - from.x, to.z - from.z)
	var len2 := seg.length_squared()
	if len2 < 0.01:
		return {}
	var z2 := CAMP_ZONE * CAMP_ZONE
	var best: Dictionary = {}
	var best_t := INF
	for c: Dictionary in camps:
		if not bool(c["alive"]) or c["node"] == ignore:
			continue
		var p: Vector3 = c["pos"]
		var rel := Vector2(p.x - from.x, p.z - from.z)
		if rel.length_squared() <= z2 or Vector2(p.x - to.x, p.z - to.z).length_squared() <= z2:
			continue
		var t := clampf(rel.dot(seg) / len2, 0.0, 1.0)
		if (rel - seg * t).length_squared() < z2 and t < best_t:
			best_t = t
			best = c
	return best


## 12.A2: the entry of `points` / `camps` / `beasts` for `node` ({} if unknown).
func point_entry(node: Variant) -> Dictionary:
	return _entry_of(points, node)


func camp_entry(node: Variant) -> Dictionary:
	return _entry_of(camps, node)


func beast_entry(node: Variant) -> Dictionary:
	return _entry_of(beasts, node)


static func _entry_of(list: Array[Dictionary], node: Variant) -> Dictionary:
	if node == null:
		return {}
	for e: Dictionary in list:
		if e["node"] == node:
			return e
	return {}


## 12.A2: the river bank of `pos` (RiverSystem.bank_of through the group "river"); without a river the side of the
## nearer home (-1 within 3 m of the middle). Cached per metre cell.
func bank_of(pos: Vector3) -> int:
	var key := Vector2i(roundi(pos.x), roundi(pos.z))
	var cached: Variant = _bank_cache.get(key)
	if cached != null:
		return int(cached)
	var bank := -1
	var tree := get_tree() if is_inside_tree() else Engine.get_main_loop() as SceneTree
	var river: Node = tree.get_first_node_in_group(&"river") if tree else null
	if river != null and river.has_method(&"bank_of"):
		bank = int(river.call(&"bank_of", pos))
	else:
		var d_own := Vector2(pos.x - home_point.x, pos.z - home_point.z).length()
		var d_enemy := Vector2(pos.x - enemy_home.x, pos.z - enemy_home.z).length()
		var other := Teams.opponent_of(team)   # 2v2: the lane opponent, never an allied seat
		if absf(d_own - d_enemy) > 3.0:
			bank = team if d_own < d_enemy else other
		if river == null and home_point == enemy_home:
			return bank   # homes not known yet: do not cache
	_bank_cache[key] = bank
	return bank


## 12.A2 beast hunting party (map-fill.md 6): the beast `champion` hunts with the others of its team now, or null.
## Recomputed once per pass (the first brain that asks): when 2+ own champions are free (ChampionBrain.party_free:
## R8 / R9, not fleeing, HP >= 70 % to start) and a known beast (visible, or seen in the last 30 s) is within 40 m
## of one of them, the free champions within 60 m of it hunt together if sum(courage x power) >= 1.2 x its strength;
## the party goes on while that sum stays >= 0.8 x (members who flee, fall or take a flag leave), the beast is
## known and inside its territory. Never with a single champion.
func party_target(champion: Node) -> Node3D:
	_update_party()
	if party_beast != null and party_members.has(champion):
		return party_beast
	return null


func _update_party() -> void:
	if _party_version == version:
		return
	_party_version = version
	if party_beast != null:
		var entry := beast_entry(party_beast) if is_instance_valid(party_beast) else {}
		var keep: Array = []
		if not entry.is_empty() and _in_territory(entry):
			var pos: Vector3 = entry["pos"]
			for m: Variant in party_members:
				var b := _brain_of(m)
				if b != null and b.party_free(false):
					keep.append(m)
			for c: Variant in own_champions:
				if keep.has(c):
					continue
				var b2 := _brain_of(c)
				if b2 != null and b2.party_free(true) and _flat_dist(c, pos) <= PARTY_JOIN:
					keep.append(c)
			if keep.size() >= PARTY_MIN and _party_power(keep) >= PARTY_ABORT * float(entry["strength"]):
				party_members = keep
				return
		party_beast = null
		party_members = []
	var free: Array = []
	for c: Variant in own_champions:
		var b3 := _brain_of(c)
		if b3 != null and b3.party_free(true):
			free.append(c)
	if free.size() < PARTY_MIN:
		return
	var best_d := INF
	for e: Dictionary in beasts:
		if not _in_territory(e):
			continue
		var pos2: Vector3 = e["pos"]
		var members: Array = []
		var nearest := INF
		for c2: Variant in free:
			var d := _flat_dist(c2, pos2)
			nearest = minf(nearest, d)
			if d <= PARTY_JOIN:
				members.append(c2)
		if nearest > PARTY_NEAR or members.size() < PARTY_MIN or nearest >= best_d:
			continue
		if _party_power(members) >= PARTY_START * float(e["strength"]):
			best_d = nearest
			party_beast = e["node"]
			party_members = members


func _party_power(members: Array) -> float:
	var sum := 0.0
	for m: Variant in members:
		var b := _brain_of(m)
		if b != null:
			sum += b.party_power()
	return sum


static func _in_territory(e: Dictionary) -> bool:
	var c: Variant = e.get("center")
	if not c is Vector3:
		return true   # no lair known: no territory rule
	var p: Vector3 = e["pos"]
	var cv: Vector3 = c
	return Vector2(p.x - cv.x, p.z - cv.z).length() <= float(e.get("leash", INF)) + TERRITORY_MARGIN


static func _brain_of(c: Variant) -> ChampionBrain:
	if c == null or not is_instance_valid(c) or not c is Node:
		return null
	var b: Variant = (c as Node).get(&"brain")
	if b is ChampionBrain and is_instance_valid(b):
		return b as ChampionBrain
	return (c as Node).get_node_or_null(^"Brain") as ChampionBrain


static func _flat_dist(n: Variant, pos: Vector3) -> float:
	if n == null or not is_instance_valid(n) or not n is Node3D:
		return INF
	var p := (n as Node3D).global_position
	return Vector2(p.x - pos.x, p.z - pos.z).length()


## True if a known enemy tower / keep stands within `dist` of `pos`.
func near_structure(pos: Vector3, dist: float) -> bool:
	for s: Dictionary in structures:
		var p: Vector3 = s["pos"]
		if Vector2(p.x - pos.x, p.z - pos.z).length() <= dist:
			return true
	return false


## The visible enemy nearest to `pos` within `max_dist` ({} if none).
func nearest_enemy(pos: Vector3, max_dist: float = INF) -> Dictionary:
	var best: Dictionary = {}
	var best_d := max_dist * max_dist if max_dist < INF else INF
	for e: Dictionary in enemies:
		var p: Vector3 = e["pos"]
		var d := (p.x - pos.x) * (p.x - pos.x) + (p.z - pos.z) * (p.z - pos.z)
		if d < best_d:
			best_d = d
			best = e
	return best


## Distance from `pos` to the nearest completed own building (INF if none).
func dist_to_own_building(pos: Vector3) -> float:
	var best := INF
	for b: Dictionary in own_buildings:
		var p: Vector3 = b["pos"]
		best = minf(best, Vector2(p.x - pos.x, p.z - pos.z).length())
	return best


## The completed own building nearest to `pos` ({} if none).
func nearest_own_building(pos: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for b: Dictionary in own_buildings:
		var p: Vector3 = b["pos"]
		var d := Vector2(p.x - pos.x, p.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = b
	return best


## Strength of an enemy unit for danger sums: a champion's power() x HP ratio, else AIMemory's rules
## (soldier cost x veterancy, wizard 170 + 30 x level + items / 5, warden 200, worker 0). 10.A3
## (market-trade.md 5.1 / 6.1): a caravan 0, a Magpie 80, a Greywater Tracker 150 (TradeNetwork.unit_strength).
static func strength_of(u: Unit) -> float:
	if u.has_method(&"power"):
		return float(u.call(&"power")) * clampf(u.hp / maxf(u.max_hp, 1.0), 0.0, 1.0)
	if u.is_in_group(&"caravans") or u.is_in_group(&"magpies") or u.is_in_group(&"trackers"):
		return TradeNetwork.unit_strength(u)
	return AIMemory.strength_of(u)


# ---------------------------------------------------------------- the pass

## Rebuilds the cache now (normally every 0.5 s; tests may call it).
func refresh() -> void:
	var t0 := Time.get_ticks_usec()
	var tree := get_tree() if is_inside_tree() else Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	_fog = FogOfWar.find()
	version += 1
	var looters_now := {}
	var new_looter := false
	enemies.clear()
	structures.clear()
	own_buildings.clear()
	own_soldiers.clear()
	own_soldier_pos.clear()
	own_champions.clear()
	hits.clear()
	shops.clear()
	_own_fighters.clear()
	own_wizard = null
	own_keep = null
	var oldest_barracks: Node3D = null
	var hit_index := {}   # own instance id -> index in hits

	if _fog != null and not _fog.enabled:
		_fog = null   # fog off: everything is visible
	var beast_svc: Node = tree.get_first_node_in_group(&"epic_beasts")
	_refresh_camps(tree)   # 12.A2: before the units (creature strengths)
	for node in tree.get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive():
			continue
		var pos := u.global_position
		if int(u.team) == team:
			_see_own_unit(u, pos)
			continue
		if Teams.is_allied_fast(int(u.team), team):
			continue   # 2v2: an allied seat's unit is neither own nor enemy
		if Unit.truce_count > 0 and StringName(u.get_meta(Unit.TRUCE_META, &"")) == Unit.TRUCE_ALL:
			continue   # bot review B8: a mission truce at peace with everyone (withdrawn seat) is no enemy
		if _fog != null and _fog.state_at(team, pos) != FogOfWar.VISIBLE:
			continue
		var t := u.unit_type
		var hero := t == null and (u is Wizard or u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes"))
		var worker := t != null and t.is_worker
		var strength := 0.0
		var is_beast := u.is_in_group(&"beasts")
		if is_beast:   # 12.A2: epic beasts count their 5.5 strength, camp creatures their 5.1 strength x level
			strength = _beast_strength(beast_svc, u)
			_see_beast(beast_svc, u, pos, strength)
		elif _creature_strength.has(u.get_instance_id()):
			strength = float(_creature_strength[u.get_instance_id()])
		elif u.is_in_group(&"creatures"):
			strength = _creature_base_of(u)   # seen away from its (hidden) spot: type strength
		else:
			strength = strength_of(u)
		var e := {"node": u, "pos": pos, "strength": strength, "worker": worker, "beast": is_beast,
				"melee": u.attack_range <= MELEE_RANGE, "hero": hero,
				"champion": u.is_in_group(&"champions"), "target": u.attack_target,
				"hp_ratio": u.hp / maxf(u.max_hp, 1.0),
				"loot": int(u.get_meta(&"loot", 0)) if u.is_in_group(&"magpies") else 0}   # 10.A3: Magpie loot
		enemies.append(e)
		if int(e["loot"]) > 0:
			looters_now[u.get_instance_id()] = true
			if not _looters_seen.has(u.get_instance_id()):
				new_looter = true
		if worker:
			workers_seen[u.get_instance_id()] = {"node": weakref(u), "pos": pos, "time": now}
		var tgt: Variant = u.attack_target
		if tgt != null and is_instance_valid(tgt) and (tgt as Node).get(&"team") != null \
				and int((tgt as Node).get(&"team")) == team and (tgt as Node).has_method(&"seconds_since_damage") \
				and float((tgt as Node).call(&"seconds_since_damage")) < HIT_WINDOW:
			var id := (tgt as Node).get_instance_id()
			if not hit_index.has(id):
				hit_index[id] = hits.size()
				hits.append({"node": tgt, "pos": (tgt as Node3D).global_position,
						"building": tgt is Building, "attackers": []})
			(hits[hit_index[id]]["attackers"] as Array).append(e)
	_looters_seen = looters_now
	if new_looter:
		looter_version += 1

	for node in tree.get_nodes_in_group(&"buildings"):
		var b := node as Building
		if b == null or not b.is_alive():
			continue
		var kind: StringName = b.building_type.kind if b.building_type else &""
		if int(b.team) == team:
			if not b.is_constructed():
				continue
			var shop := b.has_method(&"is_shop") and bool(b.call(&"is_shop"))
			own_buildings.append({"node": b, "pos": b.global_position, "kind": kind,
					"radius": b.target_radius(), "since_damage": b.seconds_since_damage(), "shop": shop})
			if shop:
				shops.append(b)
			if kind == &"keep" and own_keep == null:
				own_keep = b
			elif kind == &"barracks" and oldest_barracks == null:
				oldest_barracks = b
			continue
		if int(b.team) == int(Unit.Team.NEUTRAL) or Teams.is_allied_fast(int(b.team), team) or not b.is_constructed():
			continue
		if kind != &"tower" and kind != &"keep":
			continue
		if state_at(b.global_position) == FogOfWar.UNEXPLORED:
			continue   # unknown
		var range_m := DEFAULT_TOWER_RANGE
		if b.building_type and b.building_type.attack_range > 0.0:
			range_m = b.building_type.attack_range
		if kind == &"keep":
			range_m += b.target_radius()   # the keep measures its range from its walls
		structures.append({"node": b, "pos": b.global_position, "kind": kind,
				"strength": KEEP_DANGER if kind == &"keep" else TOWER_DANGER, "reach": range_m + COVER_MARGIN})

	for node in tree.get_nodes_in_group(&"peddlers") + tree.get_nodes_in_group(&"shops"):
		var n3 := node as Node3D
		if n3 == null or shops.has(n3) or (n3.has_method(&"is_alive") and not bool(n3.call(&"is_alive"))):
			continue
		if n3.has_method(&"is_shop") and not bool(n3.call(&"is_shop")):
			continue
		var st: Variant = n3.get(&"team")
		if st != null and int(st) != team and int(st) != int(Unit.Team.NEUTRAL):
			continue
		shops.append(n3)

	# Enemy workers: forget the dead and the stale.
	for id: int in workers_seen.keys():
		var w: Dictionary = workers_seen[id]
		var wn: Object = (w["node"] as WeakRef).get_ref()
		if wn == null or not bool(wn.call(&"is_alive")) or now - float(w["time"]) > WORKER_MEMORY:
			workers_seen.erase(id)

	_refresh_bounties(tree)
	_refresh_taverns(tree)
	caches = tree.get_nodes_in_group(&"lost_caches")
	home_point = own_keep.global_position if own_keep else (oldest_barracks.global_position
			if oldest_barracks else _level_point(tree, team, home_point))
	_refresh_enemy_home(tree)
	_refresh_beasts()
	_refresh_points(tree)
	_refresh_critters(tree)
	passes += 1
	usec_total += Time.get_ticks_usec() - t0


# ---------------------------------------------------------------- 12.A2 map fill passes

## Camps (group "camp_manager": camps(); NeutralCamp: creatures(), strength(), tier, camp_level, is_disabled()).
func _refresh_camps(tree: SceneTree) -> void:
	camps.clear()
	_creature_strength.clear()
	var cm: Node = tree.get_first_node_in_group(&"camp_manager")
	if cm == null or not cm.has_method(&"camps"):
		return
	if _creature_base.is_empty():
		var consts := _script_consts(cm)
		var base: Variant = consts.get("CREATURE_STRENGTH")
		if base is Dictionary:
			_creature_base = base
		if consts.has("LEVEL_STRENGTH"):
			_level_strength = float(consts["LEVEL_STRENGTH"])
	var list: Variant = cm.call(&"camps")
	if not list is Array:
		return
	for c: Variant in list:
		if c == null or not is_instance_valid(c) or not c is Node3D:
			continue
		var camp := c as Node3D
		var id := camp.get_instance_id()
		var fixed: Dictionary = _camp_fixed.get(id, {})
		if fixed.is_empty():   # once per camp: tier, spot, full strength (for a camp never seen yet)
			var tier: Variant = camp.get(&"tier")
			fixed = {"tier": int(tier) if tier != null else 1, "pos": camp.global_position,
					"full": float(camp.call(&"strength")) if camp.has_method(&"strength") else 0.0}
			_camp_fixed[id] = fixed
		if camp.has_method(&"is_disabled") and bool(camp.call(&"is_disabled")):
			continue
		var pos: Vector3 = fixed["pos"]
		var st := state_at(pos)
		var mem: Dictionary = _camp_memory.get(id, {})
		if st == FogOfWar.VISIBLE:   # seen now: exact creatures, level and strength
			var living: Array = []
			if camp.has_method(&"creatures"):
				living = camp.call(&"creatures")
			var lvl: Variant = camp.get(&"camp_level")
			var mult := 1.0 + _level_strength * (float(lvl) if lvl != null else 0.0)
			for u: Variant in living:
				if u != null and is_instance_valid(u):
					_creature_strength[(u as Node).get_instance_id()] = _creature_base_of(u as Node) * mult
			mem = {"alive": not living.is_empty(),
					"strength": float(camp.call(&"strength")) if camp.has_method(&"strength") else 0.0}
			_camp_memory[id] = mem
		elif mem.is_empty():
			mem = {"alive": true, "strength": fixed["full"]}   # never seen: assumed alive (not stored)
		camps.append({"node": camp, "pos": pos, "tier": fixed["tier"],
				"alive": bool(mem["alive"]), "strength": float(mem["strength"]),
				"visible": st == FogOfWar.VISIBLE, "explored": st != FogOfWar.UNEXPLORED})


## The 5.1 strength of a creature's type (CampManager.CREATURE_STRENGTH, level not included).
func _creature_base_of(u: Node) -> float:
	var ut: Variant = u.get(&"unit_type")
	var tid: StringName = StringName(str((ut as Resource).get(&"id"))) if ut is Resource else &""
	return float(_creature_base.get(tid, CREATURE_DEFAULT))


static func _script_consts(node: Object) -> Dictionary:
	var s := node.get_script() as Script
	return s.get_script_constant_map() if s != null else {}


func _beast_strength(svc: Node, u: Unit) -> float:
	if svc != null and svc.has_method(&"strength_of"):
		var s := float(svc.call(&"strength_of", u))
		if s > 0.0:
			return s
	return BEAST_DEFAULT


## A visible beast: remember where and when (the lair's centre and leash once, from EpicBeasts.lair_of).
func _see_beast(svc: Node, u: Unit, pos: Vector3, strength: float) -> void:
	var id := u.get_instance_id()
	var mem: Dictionary = _beast_memory.get(id, {})
	if mem.is_empty():
		mem = {"node": weakref(u), "center": null, "leash": INF}
		if svc != null and svc.has_method(&"lair_of"):
			var lair: Variant = svc.call(&"lair_of", u)
			if lair is Dictionary and (lair as Dictionary).get("center") is Vector3:
				mem["center"] = (lair as Dictionary)["center"]
				mem["leash"] = float((lair as Dictionary).get("radius", 5.0)) + BEAST_LEASH_EXTRA
		_beast_memory[id] = mem
	mem["pos"] = pos
	mem["time"] = now
	mem["strength"] = strength


func _refresh_beasts() -> void:
	beasts.clear()
	for id: int in _beast_memory.keys():
		var m: Dictionary = _beast_memory[id]
		var b: Object = (m["node"] as WeakRef).get_ref()
		if b == null or not bool(b.call(&"is_alive")) or now - float(m["time"]) > BEAST_MEMORY:
			_beast_memory.erase(id)
			continue
		beasts.append({"node": b, "pos": m["pos"], "strength": m["strength"], "time": m["time"],
				"visible": float(m["time"]) == now, "center": m["center"], "leash": m["leash"]})


## Capture points (group "capture_points_service": points(); CapturePoint fields). Landmarks: known from 0:00.
func _refresh_points(tree: SceneTree) -> void:
	var svc: Node = tree.get_first_node_in_group(&"capture_points_service")
	if svc == null or not svc.has_method(&"points"):
		points.clear()
		_point_nodes = []
		return
	var list: Variant = svc.call(&"points")
	if not list is Array:
		points.clear()
		_point_nodes = []
		return
	if list == _point_nodes:   # same points: only the owners change
		var ok := true
		for e: Dictionary in points:
			var n0: Variant = e["node"]
			if not is_instance_valid(n0):
				ok = false
				break
			var ot0: Variant = (n0 as Node).get(&"owner_team")
			e["owner"] = int(ot0) if ot0 != null else -1
			var bk0: Variant = (n0 as Node).get(&"bank")
			if bk0 != null:
				e["bank"] = int(bk0)
		if ok:
			return
	points.clear()
	_point_nodes = (list as Array).duplicate()
	for p: Variant in list:
		if p == null or not is_instance_valid(p) or not p is Node3D:
			continue
		var n := p as Node3D
		var ot: Variant = n.get(&"owner_team")
		var bk: Variant = n.get(&"bank")
		var rad: Variant = n.get(&"capture_radius")
		var radius := float(rad) if rad != null else 6.0
		var clearing := float(n.call(&"clearing_radius")) if n.has_method(&"clearing_radius") else radius * 0.5
		points.append({"node": n, "pos": n.global_position, "kind": StringName(str(n.get(&"kind"))),
				"owner": int(ot) if ot != null else -1, "bank": int(bk) if bk != null else bank_of(n.global_position),
				"radius": radius, "stand": clampf(clearing + 0.5, 1.0, maxf(radius - 1.5, 1.0))})


## Game critters visible to the team (group "critter_herds": critters(); GameCritter.is_visible_to(team)), only those
## within CRITTER_SCAN of an own Wayfinder / Coin-Cutter (the idle hunters; nobody else reads the list).
func _refresh_critters(tree: SceneTree) -> void:
	critters.clear()
	var hunters := PackedVector3Array()
	for ch: Variant in own_champions:
		var ct: Variant = (ch as Node).get(&"champion_type")
		var cid: Variant = (ct as Resource).get(&"id") if ct is Resource else null
		if cid != null and (StringName(str(cid)) == &"wayfinder" or StringName(str(cid)) == &"coin_cutter"):
			hunters.append((ch as Node3D).global_position)
	if hunters.is_empty():
		return
	var svc: Node = tree.get_first_node_in_group(&"critter_herds")
	if svc == null or not svc.has_method(&"critters"):
		return
	var list: Variant = svc.call(&"critters")
	if not list is Array:
		return
	var r2 := CRITTER_SCAN * CRITTER_SCAN
	for c: Variant in list:
		if c == null or not is_instance_valid(c) or not c is Node3D:
			continue
		var n := c as Node3D
		var cp := n.global_position
		var near := false
		for h: Vector3 in hunters:
			if (h.x - cp.x) * (h.x - cp.x) + (h.z - cp.z) * (h.z - cp.z) <= r2:
				near = true
				break
		if not near:
			continue
		if n.has_method(&"is_alive") and not bool(n.call(&"is_alive")):
			continue
		if n.has_method(&"is_visible_to"):
			if not bool(n.call(&"is_visible_to", team)):
				continue
		elif not is_visible_pos(n.global_position):
			continue
		critters.append({"node": n, "pos": n.global_position, "kind": StringName(str(n.get(&"kind")))})


func _see_own_unit(u: Unit, pos: Vector3) -> void:
	var t := u.unit_type
	if t != null:
		if t.is_worker or t.lifetime > 0.0 or u.is_in_group(&"caravans"):
			return
		if u.is_in_group(&"trackers"):
			_own_fighters.append(pos)   # 10.A3: hired trackers hold ground, but are not the army
			return
		own_soldiers.append(u)
		own_soldier_pos.append(pos)
		_own_fighters.append(pos)
		return
	if u.is_in_group(&"champions"):
		own_champions.append(u)
		_own_fighters.append(pos)
	elif u is Wizard or u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes"):
		own_wizard = u
		_own_fighters.append(pos)


func _refresh_bounties(tree: SceneTree) -> void:
	bounties.clear()
	var sig: Array = []
	for node in tree.get_nodes_in_group(&"bounties"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var bt: Variant = node.get(&"team")
		if bt == null or int(bt) != team:
			continue
		if node.has_method(&"is_valid") and not bool(node.call(&"is_valid")):
			continue
		bounties.append(node)
		sig.append(node.get_instance_id())
		sig.append(node.get(&"stake"))
	var h := sig.hash()
	if h != _bounty_sig:
		_bounty_sig = h
		bounty_version += 1


func _refresh_taverns(tree: SceneTree) -> void:
	taverns.clear()
	for node in tree.get_nodes_in_group(&"taverns"):
		var tv := node as Node3D
		if tv == null:
			continue
		var door := door_of(tv)
		var enemy_near := false
		for e: Dictionary in enemies:
			if bool(e["worker"]) or int((e["node"] as Node).get(&"team")) == int(Unit.Team.NEUTRAL):
				continue
			var p: Vector3 = e["pos"]
			if Vector2(p.x - door.x, p.z - door.z).length() <= HELD_RADIUS:
				enemy_near = true
				break
		var own_near := false
		if enemy_near:
			for p2: Vector3 in _own_fighters:
				if Vector2(p2.x - door.x, p2.z - door.z).length() <= HELD_RADIUS:
					own_near = true
					break
		taverns.append({"node": tv, "door": door, "held": enemy_near and not own_near})


## A tavern's door point: its `door_point()` (Tavern) / `door_position()` / `door_point` property if it has
## one, else spot x 0.8 (section 2). "Held" is judged from the team's fog, never from hidden units.
static func door_of(tv: Node3D) -> Vector3:
	for method: StringName in [&"door_point", &"door_position"]:
		if tv.has_method(method):
			var d: Variant = tv.call(method)
			if d is Vector3:
				return d
	var dp: Variant = tv.get(&"door_point")
	if dp is Vector3:
		return dp
	var p := tv.global_position
	return Vector3(p.x * DOOR_FACTOR, p.y, p.z * DOOR_FACTOR)


func _refresh_enemy_home(tree: SceneTree) -> void:
	var enemy_team := Teams.opponent_of(team)   # 2v2: never an allied seat's base
	var level := tree.current_scene
	if level and level.has_method(&"base_center"):
		enemy_home = level.call(&"base_center", enemy_team)
		return
	for s: Dictionary in structures:
		if s["kind"] == &"keep":
			enemy_home = s["pos"]
			return
	enemy_home = Vector3(-home_point.x, 0.0, -home_point.z)   # the maps are point-mirrored


static func _level_point(tree: SceneTree, for_team_id: int, fallback: Vector3) -> Vector3:
	var level := tree.current_scene
	if level and level.has_method(&"base_center"):
		return level.call(&"base_center", for_team_id)
	return fallback
