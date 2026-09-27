class_name AIMapFill
extends RefCounted
## Rules 11-13 of the bot for the filled map (docs/design/map-fill.md section 7, task 12.A1). Owned by the Commander,
## one per bot, like AITrade. It reaches the step-12 systems only through their groups and has_method() (never their
## class names): "river" (RiverSystem), "capture_points_service" / "capture_points" (CapturePoints / CapturePoint),
## "camp_manager" / "neutral_camps" (CampManager / NeutralCamp), "epic_beasts" / "beasts" (EpicBeasts), and
## "game_critters" (deer). Every rule is a no-op while its system is absent (missions, toggles off), so the bot plays
## exactly as before there. Services are looked up again every LOOKUP_EVERY seconds (never per unit).
## - 11a / 11c / 11e creep_target(): the camp (tier in ai.creep_tiers, own bank, the own-near ford nest, the own-bank
##   hollow only with ai.creep_hollow, the stag only from STAG_STRENGTH) or epic beast (ai.beast_ratio, own-bank lairs
##   except the Grizzlemaw; ai.beast_far adds the Grizzlemaw across the road bridge) nearest the rally that
##   own_strength beats by the ratio, with no enemy fighter seen near it for 30 s (the bot knows the camp spots and
##   their schedule; beast spawns are announced to both teams). The Commander sends the
##   army (Stage.CREEP) and ends it (note_creep_end: the wizard picks up drops within 12 m on normal / hard).
## - 12a / 12c squad_tick(): the capture squad (ai.capture_squad cheapest idle rally soldiers, command_move only)
##   walks to the next point (own well, own home tower, the other own-bank tower, then enemy-bank wells / towers
##   while own_strength >= ai.steal_points_ratio x max(seen, 250)), stands until captured (max 40 s), comes back; one
##   squad at a time, every 20 s. It leaves for an own-bank Wayshrine so as to stand in it ai.shrine_lead s before it
##   wakes (0 = at the waking), or the wizard goes when there is no squad (easy). 11d (ai.hunt_deer, hard): a ranged
##   member of a returning squad may shoot one visible deer within 10 m (once per 120 s, dropped after 8 s). Easy /
##   normal never target a game critter: they are not Units, nothing here orders an attack on one.
## - 12b sense(): an enemy seen capturing an own point within 35 m of an own building = a rule-1 intruder
##   (intruder()); farther, point_sortie() offers the army a defence when the capturers are <= 0.8 x the rally.
## - 12c attack_shrine(): an awake enemy-bank shrine (ai.shrine_contest) becomes rule 7's first target row.
## - 13a scout: SCOUT_PATH_RIVER (Millstone Bridge, never the isle or a guarded ford), scout_point_ok() for the
##   fog grid, scout_via() = a road bridge (or a cleared ford) when the next point is on the other bank.
## - 13b attack_waypoint() (ai.attack_reroute, hard): a seen tower covering the exit of the enemy's Crown Bridge, or
##   5+ enemy soldiers seen holding it in 60 s -> the ford (nest cleared) or road bridge of the side with fewer seen
##   towers.
## - B8-B11 flag_candidates(): read by AIChampions (ai.mapfill_flags).
## Creatures and beasts count 0 in seen_strength / own_strength (they are NEUTRAL: the Commander's scan never adds
## them); a camp's strength is NeutralCamp.strength() (fallback: 5.1 strengths x (1 + 0.15 x camp level)).

const LOOKUP_EVERY := 5.0            ## Seconds between two service lookups (groups).
const ENEMY_MEMORY := 30.0           ## 11a / 11e / 12a: no enemy fighter seen near the target this long.
const CAMP_ENEMY_RADIUS := 25.0
const BEAST_ENEMY_RADIUS := 30.0
const STAG_STRENGTH := 900.0         ## 11c: the stag only from this own_strength (like the crown camp).
const CAMP_LEVEL_STRENGTH := 0.15
const NEST_FORD_RADIUS := 8.0        ## A Mirefang camp this close to a ford centre guards it.
const SQUAD_EVERY := 20.0            ## 12a
const SQUAD_HOLD := 40.0             ## 12a: stand in the circle at most this long.
const SQUAD_GO_TIMEOUT := 90.0       ## Walking longer than this = stuck: come back.
const SQUAD_BACK_TIMEOUT := 60.0     ## Released at the latest this long after turning back.
const POINT_ENEMY_RADIUS := 20.0     ## 12a: no enemy fighter seen this close to the point in 30 s.
const SQUAD_DANGER_RADIUS := 15.0    ## A stronger fresh enemy this close to the held point sends the squad home.
const SQUAD_CAMP_CLEAR := 12.0       ## Squads walk around living camps their straight way passes this close to...
const REACH_VIA := 4.0               ## ...through a waypoint reached at this distance.
const FRESH := 3.0
const GIVE_UP_COOLDOWN := 60.0       ## A point the squad (or wizard) gave up on is skipped this long.
const POINT_NEAR_BASE := 35.0        ## 12b
const POINT_SORTIE_RATIO := 0.8      ## 12b
const CAPTURER_MARGIN := 2.0         ## 12b: enemies this far outside the capture circle still count as capturers.
const SQUAD_SPEED := 4.0             ## 12c: walking speed estimate (m/s) for the shrine departure...
const TRAVEL_SLACK := 1.25           ## ...times this (paths are longer than the straight line).
const SHRINE_WAIT := 60.0            ## 12c: a shrine that will not wake within this is not waited for.
const SHRINE_CHECK_MAX := 5.0        ## 12c: seconds between two shrine checks at most.
const WIZARD_PASS := 15.0            ## 12a easy: points this close to the wizard's path.
const WIZARD_JOB_TIMEOUT := 90.0
const PICKUP_RADIUS := 12.0          ## 11b
const PICKUP_TIME := 15.0
const DEER_RADIUS := 10.0            ## 11d
const DEER_EVERY := 120.0
const DEER_DROP := 8.0
const BRIDGE_COVER := 12.0           ## 13b
const BRIDGE_HOLDERS := 5
const BRIDGE_MEMORY := 60.0
const SIDE_TOWER_RADIUS := 20.0      ## 13b: seen towers this close to a side's crossings count for that side.
const SCOUT_CAMP_CLEAR := 13.0       ## 13a: fog-grid points this close to a living camp are skipped...
const SCOUT_LAIR_CLEAR := 8.0        ## ...and this far beyond a living beast's lair radius...
const ISLE_RADIUS := 15.0            ## ...and the isle (moat included) while the wardens live.
const CAMP_GROUND := 10.0            ## 20.A3: in_neutral_camp(): this close to a living camp's spot.
const RALLY_RADIUS := 12.0
const RANGED_MIN := 3.0              ## Attack range above this = ranged (AIMemory.RANGED_MIN_RANGE).
const SEEN_FLOOR := 250.0
const SAMPLES_KEPT := 2000
const EXPLORE_STAKE := 25            ## B8
const HUNT_CAMP_STAKE := 75          ## B9
const GUARD_STAKE := 50              ## B10
const CLAIM_OFFSET := 4.0            ## B8: the Explore flag stands this far from the tower, toward the own base.
const WELL_ALARM := 25.0             ## B10

## map-fill.md 5.1 / 5.5 strengths (fallbacks when the services do not answer strength()).
const CREATURE_STRENGTH := {&"bristleback": 100.0, &"mirefang": 110.0, &"gloomcap_elder": 220.0,
		&"gloomcap_sprout": 50.0, &"hollow_stag": 700.0}
const BEAST_STRENGTH := {&"ironhide_tusker": 900.0, &"old_scarback": 1080.0, &"stormcrest_roc": 800.0,
		&"duskwing_roc": 800.0, &"greymane_direwolf": 700.0, &"moonpelt_direwolf": 780.0, &"grizzlemaw": 1300.0,
		&"elder_grizzlemaw": 1500.0}
## map-fill.md 2.3: the enemy (north-east) bot's scout loop over Millstone Bridge; a PLAYER-side bot mirrors it.
const SCOUT_PATH_RIVER: Array[Vector3] = [Vector3(16.0, 0.0, -6.0), Vector3(12.0, 0.0, 22.0), Vector3(17.0, 0.0, 47.0),
		Vector3(-2.0, 0.0, 44.0), Vector3(-16.0, 0.0, 6.0), Vector3(-27.0, 0.0, 27.0), Vector3(-2.0, 0.0, 44.0),
		Vector3(17.0, 0.0, 47.0)]
## map-fill.md 2.2, used when the RiverSystem has no crossings() (a partial stub).
const CROSSINGS_FALLBACK: Array[Dictionary] = [
	{"id": &"bridge_road_n", "kind": &"bridge_road", "center": Vector3(-12.0, 0.0, -48.7), "length": 9.0},
	{"id": &"bridge_road_s", "kind": &"bridge_road", "center": Vector3(12.0, 0.0, 48.7), "length": 9.0},
	{"id": &"ford_n", "kind": &"ford", "center": Vector3(-8.5, 0.0, -34.0), "length": 7.0},
	{"id": &"ford_s", "kind": &"ford", "center": Vector3(8.5, 0.0, 34.0), "length": 7.0},
	{"id": &"bridge_crown_w", "kind": &"bridge_lane", "center": Vector3(-9.02, 0.0, 9.02), "length": 6.5},
	{"id": &"bridge_crown_e", "kind": &"bridge_lane", "center": Vector3(9.02, 0.0, -9.02), "length": 6.5},
	{"id": &"steps_nw", "kind": &"steps", "center": Vector3(-9.02, 0.0, -9.02), "length": 6.0},
	{"id": &"steps_se", "kind": &"steps", "center": Vector3(9.02, 0.0, 9.02), "length": 6.0},
]

## Read only: the capture squad's units (untyped: may be freed) and its job
## {"kind": &"point" / &"shrine", "point", "name", "pos", "phase": &"go" / &"hold" / &"back", "since", "arrived",
## "woke", "woke_at", "back_since"}.
var squad: Array = []
var squad_job: Dictionary = {}
## Read only: the wizard's job {"kind": &"point" / &"shrine" / &"pickup", "point" or "node", "pos", "since", ...}.
var wizard_job: Dictionary = {}
## Read only: every army creep launched {"name", "kind", "tier", "time", "strength", "own"}; every squad / wizard job
## {"name", "kind", "by", "time"}; captures seen done {"name", "time"}; deer shots (hard).
var creeps: Array[Dictionary] = []
var jobs: Array[Dictionary] = []
var captured: Array[Dictionary] = []
var deer_shots := 0
## The creep the Commander runs now ({} = none): B9 / B11 read it.
var current_creep: Dictionary = {}
## Perf (like AITrade): decision microseconds per think tick (sense + squads + targets). Read only.
var usec_total := 0
var tick_count := 0
var usec_samples := PackedInt32Array()
var usec_parts := {}                   ## Read only: total microseconds per part (&"sense", &"squads", &"creep").

var _team := 0
var _enemy_team := 1
var _ai: AIProfile
var _tree: SceneTree
var _now := 0.0
var _own_base := Vector3.ZERO
var _enemy_base := Vector3.ZERO
var _fog: FogOfWar = null
var _memory: AIMemory = null
var _own_strength := 0.0
var _seen_strength := 0.0
var _river: Node = null
var _points_svc: Node = null
var _camps_svc: Node = null
var _beasts_svc: Node = null
var _lookup_at := -INF
var _points: Array = []
var _camps: Array = []
var _beasts: Array = []
var _crossings_cache: Array = []
var _info := {}                        # point / camp instance id -> {"kind", "tier", "pos", "bank"} (fixed facts)
var _squad_ids := {}
var _orders := {}                      # unit id -> [pos, time] (squad / wizard moves, not re-sent within 6 s)
var _next_squad := 0.0
var _gave_up := {}                     # point instance id -> time
var _intruder: Node3D = null
var _threat: Dictionary = {}
var _deer: Array = []                  # [unit, deer, time] while a squad member hunts (11d)
var _last_deer := -INF
var _shrine_check_at := -INF           # 12c: no own shrine can be due before this match time
var _keep_home: Unit = null            # the soldier the Commander's scout rule wants next (never taken by a squad)
var _tick_usec := 0
var _counted_tick := -1.0


func _init(team: int, enemy_team: int, profile: AIProfile) -> void:
	_team = team
	_enemy_team = enemy_team
	_ai = profile


func set_profile(profile: AIProfile) -> void:
	_ai = profile


## Once, from the Commander's setup: the tree and the two base centres (bank fallback without a river).
func setup(tree: SceneTree, level: Node) -> void:
	_tree = tree
	if level != null and level.has_method(&"base_center"):
		_own_base = level.call(&"base_center", _team)
		_enemy_base = level.call(&"base_center", _enemy_team)
	_lookup(-INF)


## True when map fill is on for this profile and at least one step-12 system exists.
func active() -> bool:
	if _ai == null or not _ai.map_fill:
		return false
	return _ok(_river) or _ok(_points_svc) or _ok(_camps_svc) or _ok(_beasts_svc) or not _points.is_empty() \
			or not _camps.is_empty()


func has_river() -> bool:
	return _ai != null and _ai.map_fill and _ok(_river)


## Squad members are not home units for the Commander (no defence, rally, scout, attack or creep orders).
func is_busy(u: Object) -> bool:
	return u != null and _squad_ids.has(u.get_instance_id())


# ---------------------------------------------------------------- services

## Every LOOKUP_EVERY s: the services, and the point / camp lists (fixed sets: re-read only then). True if it ran.
func _lookup(now: float) -> bool:
	if _tree == null or now - _lookup_at < LOOKUP_EVERY:
		return false
	_lookup_at = now
	var river := _first(&"river")
	if river != _river:
		_info.clear()   # banks come from the river
		_crossings_cache = []
	_river = river
	_points_svc = _first(&"capture_points_service")
	_camps_svc = _first(&"camp_manager")
	_beasts_svc = _first(&"epic_beasts")
	_points = _list(_points_svc, &"points", &"capture_points")
	_camps = _list(_camps_svc, &"camps", &"neutral_camps")
	return true


func _first(group: StringName) -> Node:
	var n := _tree.get_first_node_in_group(group)
	return n if _ok(n) else null


static func _ok(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and not (n as Node).is_queued_for_deletion()


## Every tick: the living beasts; points / camps freed since the last lookup leave their lists.
func _refresh_lists() -> void:
	for list: Array in [_points, _camps]:
		for i in range(list.size() - 1, -1, -1):
			if not is_instance_valid(list[i]):
				list.remove_at(i)
	_beasts = _list(_beasts_svc, &"beasts", &"beasts")


## Cached facts of a point or camp that never change: kind, bank, tier (camps), position.
func _info_of(n: Node3D) -> Dictionary:
	var id := n.get_instance_id()
	var d: Dictionary = _info.get(id, {})
	if d.is_empty():
		d["kind"] = _kind(n)
		d["tier"] = _iget(n, &"tier", 0)
		d["pos"] = n.global_position
		var v: Variant = n.get(&"bank")
		d["bank"] = int(v) if (v is int or v is float) and int(v) >= 0 else bank_of(n.global_position)
		_info[id] = d
	return d


func _list(svc: Node, method: StringName, group: StringName) -> Array:
	var raw: Array = []
	if _ok(svc) and svc.has_method(method):
		var v: Variant = svc.call(method)
		if v is Array:
			raw = v
	elif _tree != null:
		raw = _tree.get_nodes_in_group(group)
	var out: Array = []
	for n: Variant in raw:
		if _ok(n) and n is Node3D:
			out.append(n)
	return out


## PLAYER / ENEMY bank of `pos` (-1 = isle or water) from the RiverSystem; without one, the nearer base's team.
func bank_of(pos: Vector3) -> int:
	if _ok(_river) and _river.has_method(&"bank_of"):
		return int(_river.call(&"bank_of", pos))
	return _team if _flat(pos, _own_base) <= _flat(pos, _enemy_base) else _enemy_team


func _point_bank(p: Node3D) -> int:
	return int(_info_of(p)["bank"])


func _pkind(p: Node3D) -> StringName:
	return _info_of(p)["kind"]


## A Wayshrine is awake (capturable) in every state but asleep: an awake shrine being taken reads "capturing" or
## "contested".
static func _shrine_up(p: Object) -> bool:
	if p.has_method(&"is_awake"):
		return bool(p.call(&"is_awake"))
	var st := _state(p)
	return st != &"asleep" and st != &""


static func _owner(p: Object) -> int:
	return _iget(p, &"owner_team", -1)


static func _kind(n: Object) -> StringName:
	var v: Variant = n.get(&"kind")
	return StringName(str(v)) if v != null else &""


static func _state(p: Object) -> StringName:
	var v: Variant = p.get(&"state")
	return StringName(str(v)) if v != null else &""


static func _iget(n: Object, prop: StringName, def: int) -> int:
	var v: Variant = n.get(prop)
	return int(v) if (v is int or v is float) else def


static func _fget(n: Object, prop: StringName, def: float) -> float:
	var v: Variant = n.get(prop)
	return float(v) if (v is int or v is float) else def


static func _name(n: Object) -> String:
	var v: Variant = n.get(&"display_name")
	if v != null and str(v) != "":
		return str(v)
	for prop: StringName in [&"point_id", &"camp_id", &"unit_name"]:
		v = n.get(prop)
		if v != null and str(v) != "":
			return str(v)
	return str((n as Node).name) if n is Node else "?"


# ---------------------------------------------------------------- sense (12b)

## Once per think tick, early (before rule 1): services, point lists, the 12b point threats.
## `enemies` = the enemy units this team sees now (the Commander's scan), `buildings` = own living buildings.
func sense(now: float, fog: FogOfWar, memory: AIMemory, own_strength: float, seen_strength: float,
		enemies: Array[Unit], buildings: Array[Building]) -> void:
	if _ai == null or not _ai.map_fill:
		return
	var t0 := Time.get_ticks_usec()
	_now = now
	_fog = fog
	_memory = memory
	_own_strength = own_strength
	_seen_strength = seen_strength
	_lookup(now)
	_refresh_lists()
	_intruder = null
	_threat = {}
	for p: Node3D in _points:
		# The owner is told "The enemy is taking <point>!" (4.3) without vision: the point's own state says it is
		# being taken; who and how strong only from what the fog shows (else the last 30 s of memory there).
		if _owner(p) != _team or _iget(p, &"capture_team", -1) != _enemy_team:
			continue
		var st := _state(p)
		if st != &"capturing" and st != &"neutralising" and st != &"contested":
			continue
		var pos := p.global_position
		var r := _fget(p, &"capture_radius", 6.0) + CAPTURER_MARGIN
		var nearest: Unit = null
		var nearest_d := INF
		var strength := 0.0
		for e in enemies:   # already only what the fog shows this team
			if e is Worker:
				continue
			var d := _flat(e.global_position, pos)
			if d <= r:
				strength += AIMemory.strength_of(e)
				if d < nearest_d:
					nearest_d = d
					nearest = e
		if nearest != null and _distance_to(pos, buildings) <= POINT_NEAR_BASE:
			_intruder = nearest
			continue
		if nearest == null and memory != null:
			strength = memory.strength_near(pos, r + 8.0, now, ENEMY_MEMORY)
		if _threat.is_empty() or strength > float(_threat["strength"]):
			_threat = {"kind": &"point", "point": p, "pos": pos, "strength": strength, "name": _name(p)}
	_count(Time.get_ticks_usec() - t0, &"sense")


## 12b: an enemy capturing an own point within 35 m of an own building (a rule-1 intruder), else null.
func intruder() -> Node3D:
	return _intruder if _intruder != null and is_instance_valid(_intruder) else null


## 12b: the farther own point being captured ({"point", "pos", "strength", "name"}), or {}.
func point_sortie() -> Dictionary:
	if _threat.is_empty() or not _ok(_threat["point"]):
		return {}
	return _threat


## 12b: the point sortie may end (no enemy fighter seen near the point just now).
func point_safe(t: Dictionary) -> bool:
	if t.is_empty() or not _ok(t.get("point")):
		return true
	var p := t["point"] as Node3D
	var st := _state(p)
	if _iget(p, &"capture_team", -1) == _enemy_team and (st == &"capturing" or st == &"neutralising"):
		return false
	return _memory == null or not _memory.fighter_near(p.global_position,
			_fget(p, &"capture_radius", 6.0) + 8.0, _now, FRESH)


# ---------------------------------------------------------------- 11a / 11c / 11e creep targets

## The camp or beast rule 11a / 11e would creep now, nearest to `from` first ({} = none): {"kind": &"camp" /
## &"beast", "node", "pos", "name", "tier", "strength", "camp_kind"}. The ratio is checked against `group_strength`
## (the soldiers that would go; < 0 = own_strength): the reserve and the squads stay home, and 5.4's fight checks
## (3-4 soldiers for a wallow, ~6 for a nest, 10-12 for the stag) need the army that is sent. The stag's 900 floor
## uses own_strength (like the crown camp).
func creep_target(now: float, own_strength: float, from: Vector3, group_strength: float = -1.0) -> Dictionary:
	if _ai == null or not _ai.map_fill or now < _ai.creep_start:
		return {}
	_now = now
	var going := own_strength if group_strength < 0.0 else minf(own_strength, group_strength)
	var t0 := Time.get_ticks_usec()
	var best: Dictionary = {}
	var best_d := INF
	for camp: Node3D in _camps:
		# Cheap fixed facts first (cached), the camp's state last.
		var info := _info_of(camp)
		var tier: int = info["tier"]
		if not _ai.creep_tiers.has(tier):
			continue
		var pos: Vector3 = info["pos"]
		var kind: StringName = info["kind"]
		var d := _flat(from, pos)
		if d >= best_d or not _camp_allowed(kind, pos, int(info["bank"])):
			continue
		if kind == &"hollow_stag" and own_strength < STAG_STRENGTH:
			continue
		if not _camp_alive(camp):
			continue
		var s := camp_strength(camp)
		if going < _ai.creep_ratio * s:   # the bot knows the camp spots and their schedule (map-fill.md 7)
			continue
		if _memory != null and _memory.fighter_near(pos, CAMP_ENEMY_RADIUS, now, ENEMY_MEMORY):
			continue
		best_d = d
		best = {"kind": &"camp", "node": camp, "pos": pos, "name": _name(camp), "tier": tier, "strength": s,
				"camp_kind": kind}
	if _ai.beast_ratio > 0.0:
		for beast: Node3D in _beasts:
			if not _unit_alive(beast):
				continue
			var lair := lair_of(beast)
			var center: Vector3 = lair.get("center", beast.global_position)
			if not _lair_allowed(StringName(str(lair.get("kind", ""))), beast, center):
				continue
			var s := beast_strength(beast)
			if going < _ai.beast_ratio * s:   # spawns are announced to both teams (5.5)
				continue
			if _memory != null and _memory.fighter_near(center, BEAST_ENEMY_RADIUS, now, ENEMY_MEMORY):
				continue
			var pos := beast.global_position if _visible(beast.global_position) else center
			var d := _flat(from, pos)
			if d < best_d:
				best_d = d
				best = {"kind": &"beast", "node": beast, "pos": pos, "center": center, "name": _name(beast),
						"tier": 4, "strength": s, "camp_kind": &""}
	_count(Time.get_ticks_usec() - t0, &"creep")
	return best


## 11a: a camp kind at `pos` this bot may creep: own-bank camps; the Mirefang nest nearer to its own base (the ford
## nests stand in the water); the Gloomcap hollow only with ai.creep_hollow (hard) and on the own bank.
func _camp_allowed(kind: StringName, pos: Vector3, bank: int) -> bool:
	if kind == &"mirefang":
		return _flat(pos, _own_base) < _flat(pos, _enemy_base)
	if kind == &"gloomcap" and not _ai.creep_hollow:
		return false
	return bank == _team


## 11e: the own bank's Tusker / Roc / Direwolf lairs; ai.beast_far adds the Grizzlemaw nearer to this bot (the one
## across the road bridge; the own-bank Den is nearer the enemy).
func _lair_allowed(kind: StringName, beast: Node3D, center: Vector3) -> bool:
	var grizz := String(kind).to_lower().contains("grizzlemaw")
	if kind == &"" and beast is Unit and (beast as Unit).unit_type != null:
		grizz = String((beast as Unit).unit_type.id).contains("grizzlemaw")
	if grizz:
		return _ai.beast_far and _flat(center, _own_base) < _flat(center, _enemy_base)
	return bank_of(center) == _team


## Not NeutralCamp.is_cleared() and a living creature there (a camp before its first spawn has none).
func _camp_alive(camp: Node3D) -> bool:
	if not _ok(camp):
		return false
	if camp.has_method(&"is_cleared") and bool(camp.call(&"is_cleared")):
		return false
	return _has_creature(camp)


func _has_creature(camp: Node3D) -> bool:
	if not camp.has_method(&"creatures"):
		return false
	var v: Variant = camp.call(&"creatures")
	if v is Array:
		for c: Variant in v:
			if _unit_alive(c):
				return true
	return false


func _creatures(camp: Node3D) -> Array:
	var out: Array = []
	if camp.has_method(&"creatures"):
		var v: Variant = camp.call(&"creatures")
		if v is Array:
			for c: Variant in v:
				if _unit_alive(c):
					out.append(c)
	return out


static func _unit_alive(n: Variant) -> bool:
	return _ok(n) and (not (n as Object).has_method(&"is_alive") or bool((n as Object).call(&"is_alive")))


## NeutralCamp.strength(), else the 5.1 creature strengths x (1 + 0.15 x camp level).
func camp_strength(camp: Node3D) -> float:
	if camp.has_method(&"strength"):
		return float(camp.call(&"strength"))
	var s := 0.0
	for c: Variant in _creatures(camp):
		var u := c as Unit
		var id: StringName = u.unit_type.id if u != null and u.unit_type != null else &""
		s += float(CREATURE_STRENGTH.get(id, 100.0))
	return s * (1.0 + CAMP_LEVEL_STRENGTH * float(_iget(camp, &"camp_level", 0)))


func beast_strength(beast: Node3D) -> float:
	if _ok(_beasts_svc) and _beasts_svc.has_method(&"strength_of"):
		return float(_beasts_svc.call(&"strength_of", beast))
	var u := beast as Unit
	var id: StringName = u.unit_type.id if u != null and u.unit_type != null else &""
	return float(BEAST_STRENGTH.get(id, 1000.0))


func lair_of(beast: Node3D) -> Dictionary:
	if _ok(_beasts_svc) and _beasts_svc.has_method(&"lair_of"):
		var v: Variant = _beasts_svc.call(&"lair_of", beast)
		if v is Dictionary:
			return v
	return {}


## The creep target still stands (camp not cleared, beast alive).
func target_alive(t: Dictionary) -> bool:
	if t.is_empty():
		return false
	if t.get("kind") == &"beast":
		return _unit_alive(t.get("node"))
	return _ok(t.get("node")) and _camp_alive(t["node"] as Node3D)


## Where the army goes: the camp spot; a beast where it is seen now, else its lair.
func target_pos(t: Dictionary) -> Vector3:
	if t.get("kind") == &"beast" and _unit_alive(t.get("node")):
		var b := t["node"] as Node3D
		if _visible(b.global_position):
			t["pos"] = b.global_position
		elif t.has("center"):
			t["pos"] = t["center"]
	return t.get("pos", Vector3.ZERO)


## The Commander launched (or ended) a creep. `joined` = the wizard went along.
func note_creep_start(t: Dictionary, own_strength: float) -> void:
	current_creep = t
	creeps.append({"name": str(t.get("name", "")), "kind": t.get("kind"), "tier": int(t.get("tier", 0)),
			"camp_kind": t.get("camp_kind", &""), "time": _now, "strength": float(t.get("strength", 0.0)),
			"own": own_strength})


## 11b: a cleared camp (normal / hard): the wizard that went along picks up a dropped item within 12 m first.
func note_creep_end(t: Dictionary, cleared: bool, wizard: Node3D) -> String:
	current_creep = {}
	if not cleared or not _ai.creep_pickup or wizard == null or not _unit_alive(wizard) or _tree == null:
		return ""
	var at: Vector3 = t.get("pos", wizard.global_position)
	var best: Node3D = null
	var best_d := PICKUP_RADIUS
	for n in _tree.get_nodes_in_group(&"item_pickups"):
		var p := n as Node3D
		if p == null or p.is_queued_for_deletion():
			continue
		var d := _flat(p.global_position, at)
		if d <= best_d:
			best_d = d
			best = p
	if best == null:
		return ""
	wizard_job = {"kind": &"pickup", "node": best, "pos": best.global_position, "since": _now, "name": str(best.name)}
	return "WIZARD picks up %s after the creep" % best.name


# ---------------------------------------------------------------- 12c: the shrine as rule 7's first row

## An awake enemy-bank Wayshrine when ai.shrine_contest and own_strength >= attack_ratio x max(seen, 250), else null.
func attack_shrine(own_strength: float, seen_strength: float) -> Node3D:
	if _ai == null or not _ai.map_fill or not _ai.shrine_contest:
		return null
	if own_strength < _ai.attack_ratio * maxf(seen_strength, SEEN_FLOOR):
		return null
	for p: Node3D in _points:
		if _pkind(p) == &"shrine" and _point_bank(p) == _enemy_team and _shrine_up(p):
			return p
	return null


func shrine_awake(p: Variant) -> bool:
	return _ok(p) and _shrine_up(p as Object)


# ---------------------------------------------------------------- 12a / 12c / 11d squads

## Once per think tick after rule 7: drives the squad and the wizard's shrine job, starts new ones.
## `home` = the Commander's home soldiers, `wizard_free` = the wizard may take a job now, `busy` = defending / all-in
## (no new job), `keep_home` = the soldier the scout rule wants next (never taken). Returns log lines.
func squad_tick(now: float, rally: Vector3, home: Array[Unit], wizard: Unit, wizard_free: bool,
		busy: bool, keep_home: Unit = null) -> Array[String]:
	var out: Array[String] = []
	if not active():
		return out
	var t0 := Time.get_ticks_usec()
	_now = now
	_keep_home = keep_home
	_prune_squad()
	if not squad_job.is_empty():
		_drive_squad(rally, out)
	var shrine := _shrine_due(rally)
	if shrine != null and not _job_on(shrine):
		if not squad_job.is_empty() and squad_job["kind"] == &"point" and squad_job["phase"] != &"back":
			out.append("SQUAD leaves %s for %s" % [squad_job["name"], _name(shrine)])
			_start_job(squad_job, &"shrine", shrine)
			squad_job["via"] = _detour(_squad_centre(), shrine.global_position)
			_squad_moves(rally)
		elif squad_job.is_empty() and not busy:
			if not _start_squad(&"shrine", shrine, home, rally, out) and wizard_free and _unit_alive(wizard) \
					and wizard_job.is_empty():
				_start_job(wizard_job, &"shrine", shrine)
				jobs.append({"name": _name(shrine), "kind": &"shrine", "by": "wizard", "time": now})
				out.append("WIZARD goes to %s (wakes in %.0f s)" % [_name(shrine), _until_awake(shrine)])
	if squad_job.is_empty() and not busy and now >= _next_squad and _ai.capture_squad > 0:
		_next_squad = now + SQUAD_EVERY
		var p := _next_point()
		if p != null:
			_start_squad(&"point", p, home, rally, out)
	_count(Time.get_ticks_usec() - t0, &"squads")
	return out


func _prune_squad() -> void:
	if squad.is_empty() and _squad_ids.is_empty() and squad_job.is_empty():
		return
	for i in range(squad.size() - 1, -1, -1):
		if not _unit_alive(squad[i]):
			squad.remove_at(i)
	_squad_ids.clear()
	for u: Variant in squad:
		_squad_ids[(u as Object).get_instance_id()] = true
	if squad.is_empty() and not squad_job.is_empty():
		squad_job = {}


func _job_on(p: Node3D) -> bool:
	return (not squad_job.is_empty() and squad_job.get("point") == p) \
			or (not wizard_job.is_empty() and wizard_job.get("point") == p)


func _start_job(job: Dictionary, kind: StringName, p: Node3D) -> void:
	job.clear()
	job["kind"] = kind
	job["point"] = p
	job["name"] = _name(p)
	job["pos"] = p.global_position
	job["phase"] = &"go"
	job["since"] = _now
	job["arrived"] = -1.0
	job["woke"] = false
	job["woke_at"] = -1.0
	job["back_since"] = -1.0


## 12a / 12c: the ai.capture_squad cheapest idle soldiers near the rally (all of them, or nobody).
func _start_squad(kind: StringName, p: Node3D, home: Array[Unit], rally: Vector3, out: Array[String]) -> bool:
	var n := _ai.capture_squad
	if n <= 0:
		return false
	var free: Array[Unit] = []
	for u in home:
		if u is Worker or not u.is_commandable() or u.attack_target != null or _flat(u.global_position, rally) > RALLY_RADIUS:
			continue
		if u == _keep_home:
			continue   # the next scout stays home (rule 6 comes first)
		free.append(u)
	if free.size() < n:
		return false
	free.sort_custom(func(a: Unit, b: Unit) -> bool: return _cost(a) < _cost(b))
	squad = []
	for i in n:
		squad.append(free[i])
	_prune_squad()
	_start_job(squad_job, kind, p)
	squad_job["via"] = _detour(rally, p.global_position)
	_squad_moves(rally)
	jobs.append({"name": _name(p), "kind": kind, "by": "squad", "time": _now})
	var extra := " (wakes in %.0f s)" % _until_awake(p) if kind == &"shrine" else ""
	out.append("SQUAD %d units to %s%s" % [n, _name(p), extra])
	return true


## A squad walks around a living camp its straight way passes within SQUAD_CAMP_CLEAR of (the first one on the way):
## a point that far from the camp on the side the way passes, else INF.
func _detour(from: Vector3, to: Vector3) -> Vector3:
	var ab := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var len2 := ab.length_squared()
	if len2 < 1.0:
		return Vector3.INF
	var via := Vector3.INF
	var first := INF
	for camp: Node3D in _camps:
		var c: Vector3 = _info_of(camp)["pos"]
		var t := clampf((Vector3(c.x - from.x, 0.0, c.z - from.z)).dot(ab) / len2, 0.0, 1.0)
		if t <= 0.05 or t >= 0.95:
			continue   # the camp is behind the start or at the goal: a detour would not help
		var q := from + ab * t
		if _flat(q, c) >= SQUAD_CAMP_CLEAR or t * sqrt(len2) >= first or not _camp_alive(camp):
			continue
		var away := Vector3(q.x - c.x, 0.0, q.z - c.z)
		if away.length() < 0.1:
			away = Vector3(-ab.z, 0.0, ab.x)
		via = c + away.normalized() * SQUAD_CAMP_CLEAR
		first = t * sqrt(len2)
	return via


static func _cost(u: Unit) -> int:
	return u.unit_type.cost if u.unit_type else 999


func _drive_squad(rally: Vector3, out: Array[String]) -> void:
	var job := squad_job
	var p: Variant = job.get("point")
	if not _ok(p) and job["phase"] != &"back":
		_turn_back(out, "the point is gone")
	match job["phase"]:
		&"go":
			var pt := p as Node3D
			var via: Vector3 = job.get("via", Vector3.INF)
			if via != Vector3.INF:
				if _flat(_squad_centre(), via) <= REACH_VIA:
					job["via"] = Vector3.INF
				elif _now - float(job["since"]) < SQUAD_GO_TIMEOUT:
					for i in squad.size():
						_move(squad[i] as Unit, via + Vector3(cos(i * 2.4), 0.0, sin(i * 2.4)) * 1.2)
					return
			if _flat(_squad_centre(), pt.global_position) <= _fget(pt, &"capture_radius", 6.0):
				job["phase"] = &"hold"
				job["arrived"] = _now
			elif _now - float(job["since"]) >= SQUAD_GO_TIMEOUT:
				_give_up(pt)
				_turn_back(out, "took too long to reach %s" % job["name"])
				return
			_squad_moves(rally)
		&"hold":
			var pt := p as Node3D
			var done := _job_done(job)
			if done:
				captured.append({"name": job["name"], "time": _now})
				_turn_back(out, "%s done" % job["name"])
				return
			if _hold_over(job):
				_give_up(pt)
				_turn_back(out, "gave up on %s" % job["name"])
				return
			if _memory != null and _memory.fighter_near(pt.global_position, SQUAD_DANGER_RADIUS, _now, FRESH) \
					and _memory.strength_near(pt.global_position, SQUAD_DANGER_RADIUS, _now, FRESH) > _squad_strength():
				_give_up(pt)
				_turn_back(out, "enemies at %s" % job["name"])
				return
			_squad_moves(rally)
		&"back":
			_hunt_deer(rally, out)
			for i in range(squad.size() - 1, -1, -1):
				var u := squad[i] as Unit
				if _deer.size() == 3 and _deer[0] == u:
					continue
				if _flat(u.global_position, rally) <= RALLY_RADIUS - 2.0:
					squad.remove_at(i)
					_squad_ids.erase(u.get_instance_id())
					continue
				_move(u, rally + Vector3(cos(i * 2.4), 0.0, sin(i * 2.4)) * 2.0)
			if squad.is_empty() or _now - float(job["back_since"]) >= SQUAD_BACK_TIMEOUT:
				squad.clear()
				_squad_ids.clear()
				_deer = []
				squad_job = {}


func _turn_back(out: Array[String], why: String) -> void:
	squad_job["phase"] = &"back"
	squad_job["back_since"] = _now
	out.append("SQUAD back: %s" % why)


## Squad members walk to (or stay at) their spot in the circle.
func _squad_moves(_rally: Vector3) -> void:
	var p: Variant = squad_job.get("point")
	if not _ok(p):
		return
	var pt := p as Node3D
	var r := _fget(pt, &"capture_radius", 6.0)
	var via: Vector3 = squad_job.get("via", Vector3.INF)
	for i in squad.size():
		var u := squad[i] as Unit
		if squad_job["phase"] == &"go" and via != Vector3.INF:
			_move(u, via + Vector3(cos(i * 2.4), 0.0, sin(i * 2.4)) * 1.2)
			continue
		var spot := _stand_spot(pt, i)
		if squad_job["phase"] == &"hold" and _flat(u.global_position, pt.global_position) <= r - 0.5:
			continue   # inside the circle: stand (idle units still defend themselves)
		_move(u, spot)


## A spot inside the capture circle on the own base's side, just outside the point's footprint.
func _stand_spot(p: Node3D, i: int) -> Vector3:
	var pos := p.global_position
	var r := _fget(p, &"capture_radius", 6.0)
	var off := 1.5
	match _pkind(p):
		&"watchtower":
			off = 3.6
		&"well":
			off = 3.0
	off = minf(off, r - 1.0)
	var dir := _own_base - pos
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.1 else Vector3.RIGHT
	var side := Vector3(-dir.z, 0.0, dir.x)
	var k := 0.0   # 0, +1, -1, +1.5, -1.5... along the side
	if i > 0:
		k = float(i + 1) / 2.0
		if i % 2 == 0:
			k = -k
	return pos + dir * off + side * (1.2 * k)


func _squad_centre() -> Vector3:
	var c := Vector3.ZERO
	if squad.is_empty():
		return c
	for u: Variant in squad:
		c += (u as Node3D).global_position
	return c / float(squad.size())


func _squad_strength() -> float:
	var s := 0.0
	for u: Variant in squad:
		s += AIMemory.strength_of(u as Node)
	return s


## Point: owned by the team. Shrine: it woke while the job ran and sleeps again (captured, the blessing given).
func _job_done(job: Dictionary) -> bool:
	var p: Variant = job.get("point")
	if not _ok(p):
		return true
	if job["kind"] == &"point":
		return _owner(p as Object) == _team
	if _shrine_up(p as Object):
		if not bool(job["woke"]):
			job["woke"] = true
			job["woke_at"] = _now
		return false
	return bool(job["woke"])


## Held too long: a point 40 s; a shrine 40 s after it woke, or (asleep) when it will not wake within 60 s.
func _hold_over(job: Dictionary) -> bool:
	var arrived := float(job["arrived"])
	if job["kind"] == &"point":
		return arrived >= 0.0 and _now - arrived >= SQUAD_HOLD
	if bool(job["woke"]):
		return _now - float(job["woke_at"]) >= SQUAD_HOLD
	return _until_awake(job["point"] as Node3D) > SHRINE_WAIT


func _give_up(p: Variant) -> void:
	if _ok(p):
		_gave_up[(p as Object).get_instance_id()] = _now


func _given_up(p: Node3D) -> bool:
	return _now - float(_gave_up.get(p.get_instance_id(), -INF)) < GIVE_UP_COOLDOWN


func _until_awake(p: Node3D) -> float:
	if _shrine_up(p):
		return 0.0
	if p.has_method(&"time_until_awake"):
		return float(p.call(&"time_until_awake"))
	return INF


## 12c: an own-bank shrine that is awake, or wakes before a squad leaving now would arrive + ai.shrine_lead.
## Not due: checked again when it could first be (at most SHRINE_CHECK_MAX s later).
func _shrine_due(rally: Vector3) -> Node3D:
	if _now < _shrine_check_at:
		return null
	var next := _now + SHRINE_CHECK_MAX
	for p: Node3D in _points:
		if _pkind(p) != &"shrine" or _point_bank(p) != _team:
			continue
		if _shrine_up(p):
			return p
		var travel := _flat(rally, p.global_position) / SQUAD_SPEED * TRAVEL_SLACK
		var slack := _until_awake(p) - travel - _ai.shrine_lead
		if slack <= 0.0:
			return p
		next = minf(next, _now + slack - 0.5)
	_shrine_check_at = next
	return null


## 12a: the next point to capture, in order: own-bank wells, own-bank towers (nearest the base first), then (when
## own_strength >= ai.steal_points_ratio x max(seen, 250)) enemy-bank wells and towers; neutral or enemy-owned, no
## enemy fighter seen within 20 m in 30 s, not given up on in the last 60 s.
func _next_point() -> Node3D:
	var own_wells: Array = []
	var own_towers: Array = []
	var far: Array = []
	var steal := _ai.steal_points_ratio > 0.0 \
			and _own_strength >= _ai.steal_points_ratio * maxf(_seen_strength, SEEN_FLOOR)
	for p: Node3D in _points:
		var kind := _pkind(p)
		if kind != &"well" and kind != &"watchtower":
			continue
		if _owner(p) == _team or _given_up(p) or _job_on(p):
			continue
		if _memory != null and _memory.fighter_near(p.global_position, POINT_ENEMY_RADIUS, _now, ENEMY_MEMORY):
			continue
		var bank := _point_bank(p)
		if bank == _team:
			(own_wells if kind == &"well" else own_towers).append(p)
		elif bank == _enemy_team and steal:
			far.append(p)
	var by_base := func(a: Node3D, b: Node3D) -> bool:
		return _flat(a.global_position, _own_base) < _flat(b.global_position, _own_base)
	own_towers.sort_custom(by_base)
	far.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var wa := 0 if _kind(a) == &"well" else 1
		var wb := 0 if _kind(b) == &"well" else 1
		if wa != wb:
			return wa < wb
		return _flat(a.global_position, _own_base) < _flat(b.global_position, _own_base))
	for list: Array in [own_wells, own_towers, far]:
		if not list.is_empty():
			return list[0]
	return null


## 11d (ai.hunt_deer, hard): a ranged member of the returning squad shoots one visible deer within 10 m, at most
## once per 120 s, and drops it after 8 s. Never a rabbit, never a detour.
func _hunt_deer(rally: Vector3, out: Array[String]) -> void:
	if _deer.size() == 3:
		var hunter: Variant = _deer[0]
		var deer: Variant = _deer[1]
		if not _unit_alive(hunter) or not _unit_alive(deer) or _now - float(_deer[2]) >= DEER_DROP:
			if _unit_alive(hunter):
				_orders.erase((hunter as Object).get_instance_id())
				_move(hunter as Unit, rally)
			_deer = []
		return
	if not _ai.hunt_deer or _now - _last_deer < DEER_EVERY or _tree == null:
		return
	for u: Variant in squad:
		var unit := u as Unit
		if unit == null or unit.attack_range <= RANGED_MIN:
			continue
		for n in _tree.get_nodes_in_group(&"game_critters"):
			var c := n as Node3D
			if c == null or _kind(c) != &"deer" or not _unit_alive(c) or not _visible(c.global_position):
				continue
			if _flat(c.global_position, unit.global_position) > DEER_RADIUS:
				continue
			unit.command_attack(c)
			_orders.erase(unit.get_instance_id())
			_deer = [unit, c, _now]
			_last_deer = _now
			deer_shots += 1
			out.append("SQUAD %s shoots a deer on the way back" % unit.unit_name)
			return


# ---------------------------------------------------------------- the wizard's jobs

## Rule 8 asks where the wizard should walk for a map-fill job (INF = none): a pickup after a creep (11b), an
## own-bank shrine with no squad (12c), and on easy (no squad) a capturable point within 15 m of its path (12a).
## `in_attack` = the wizard follows an attack group now (jobs wait; nothing new starts).
func wizard_goal(now: float, w: Unit, in_attack: bool) -> Vector3:
	if _ai == null or not _ai.map_fill or w == null or not w.is_alive():
		return Vector3.INF
	_now = now
	if in_attack:
		return Vector3.INF
	if wizard_job.is_empty() and _ai.capture_squad <= 0:
		var p := _passing_point(w.global_position)
		if p != null:
			_start_job(wizard_job, &"point", p)
			jobs.append({"name": _name(p), "kind": &"point", "by": "wizard", "time": now})
	if wizard_job.is_empty():
		return Vector3.INF
	var job := wizard_job
	if now - float(job["since"]) >= WIZARD_JOB_TIMEOUT:
		_give_up(job.get("point"))
		wizard_job = {}
		return Vector3.INF
	if job["kind"] == &"pickup":
		var n: Variant = job.get("node")
		if not _ok(n) or now - float(job["since"]) >= PICKUP_TIME:
			wizard_job = {}
			return Vector3.INF
		return (n as Node3D).global_position
	var p: Variant = job.get("point")
	if not _ok(p):
		wizard_job = {}
		return Vector3.INF
	var pt := p as Node3D
	if job["arrived"] < 0.0 and _flat(w.global_position, pt.global_position) <= _fget(pt, &"capture_radius", 6.0):
		job["arrived"] = now
	if _job_done(job):
		captured.append({"name": job["name"], "time": now})
		wizard_job = {}
		return Vector3.INF
	if _hold_over(job):
		_give_up(pt)
		wizard_job = {}
		return Vector3.INF
	return _stand_spot(pt, 0)


## 12a easy: the nearest capturable own-bank well / tower within 15 m of `pos`.
func _passing_point(pos: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := WIZARD_PASS
	for p: Node3D in _points:
		var kind := _pkind(p)
		if kind != &"well" and kind != &"watchtower":
			continue
		if _owner(p) == _team or _given_up(p) or _point_bank(p) != _team:
			continue
		var d := _flat(p.global_position, pos)
		if d > best_d:
			continue
		if _memory != null and _memory.fighter_near(p.global_position, POINT_ENEMY_RADIUS, _now, ENEMY_MEMORY):
			continue
		best_d = d
		best = p
	return best


# ---------------------------------------------------------------- 13a scout, 13b attack route

## 13a: a fog-grid scouting point is fine: not in deep water, not on the isle while the wardens live, not next to a
## living camp or inside a living beast's lair.
func scout_point_ok(p: Vector3, wardens_alive: bool) -> bool:
	if not active():
		return true
	if has_river() and _river.has_method(&"is_water") and bool(_river.call(&"is_water", p)):
		return false
	if wardens_alive and _flat(p, Vector3.ZERO) < ISLE_RADIUS:
		return false
	for camp: Node3D in _camps:
		if _flat(p, camp.global_position) < SCOUT_CAMP_CLEAR and _camp_alive(camp):
			return false
	for beast: Node3D in _beasts:
		var lair := lair_of(beast)
		if lair.is_empty():
			continue
		var c: Vector3 = lair.get("center", beast.global_position)
		if _flat(p, c) < float(lair.get("radius", 5.0)) + SCOUT_LAIR_CLEAR:
			return false
	return true


## 20.A3: `pos` is inside a living neutral camp (CAMP_GROUND of its spot) or a living beast's lair: the Commander's
## rule 1 does not chase an enemy there (the creatures fight whoever comes; defending armies died to them).
func in_neutral_camp(pos: Vector3) -> bool:
	if not active():
		return false
	for camp: Node3D in _camps:
		if _ok(camp) and _flat(pos, _info_of(camp)["pos"]) < CAMP_GROUND and _camp_alive(camp):
			return true
	for beast: Node3D in _beasts:
		if not _unit_alive(beast):
			continue
		var lair := lair_of(beast)
		if lair.is_empty():
			continue
		if _flat(pos, lair.get("center", beast.global_position)) < float(lair.get("radius", 5.0)) + 2.0:
			return true
	return false


## 13a: a safe crossing to walk through first when `goal` lies on the other bank (a road bridge, or a ford whose
## nest is cleared: never the isle); on the same bank a detour around a living camp on the way; else INF.
func scout_via(from: Vector3, goal: Vector3) -> Vector3:
	if not has_river():
		return Vector3.INF
	var bf := bank_of(from)
	var bg := bank_of(goal)
	if bf < 0 or bg < 0 or bf == bg:
		return _detour(from, goal)   # same bank: around a living camp on the way (like the squads)
	var best := Vector3.INF
	var best_d := INF
	for c: Dictionary in _crossings():
		var kind: StringName = c.get("kind", &"")
		var center: Vector3 = c.get("center", Vector3.INF)
		if kind != &"bridge_road" and not (kind == &"ford" and _ford_open(center)):
			continue
		var d := _flat(from, center) + _flat(center, goal)
		if d < best_d:
			best_d = d
			best = center
	return best


## 13b (ai.attack_reroute, hard): the crossing the attack walks through instead of the lane over the isle, or INF.
func attack_waypoint(memory: AIMemory, now: float) -> Vector3:
	if _ai == null or not _ai.attack_reroute or not has_river() or memory == null:
		return Vector3.INF
	var lane := Vector3.INF
	var lane_len := 6.5
	for c: Dictionary in _crossings():
		if c.get("kind") != &"bridge_lane":
			continue
		var center: Vector3 = c.get("center", Vector3.INF)
		if lane == Vector3.INF or _flat(center, _enemy_base) < _flat(lane, _enemy_base):
			lane = center
			lane_len = float(c.get("length", 6.5))
	if lane == Vector3.INF:
		return Vector3.INF
	var out := Vector3(lane.x, 0.0, lane.z)
	var exit := lane + (out.normalized() * lane_len * 0.5 if out.length() > 0.1 else Vector3.ZERO)
	if not _bridge_held(memory, now, exit):
		return Vector3.INF
	# The side (north / south river) with fewer seen enemy towers near its crossings; ties: the shorter way.
	var best := Vector3.INF
	var best_key := Vector2(INF, INF)
	for north: bool in [true, false]:
		var towers := 0
		var pick := Vector3.INF
		var road := Vector3.INF
		for c: Dictionary in _crossings():
			var center: Vector3 = c.get("center", Vector3.INF)
			var kind: StringName = c.get("kind", &"")
			if (center.z < 0.0) != north or (kind != &"ford" and kind != &"bridge_road"):
				continue
			towers += _towers_near(memory, center)
			if kind == &"ford" and _ford_open(center):
				pick = center
			elif kind == &"bridge_road":
				road = center
		if pick == Vector3.INF:
			pick = road
		if pick == Vector3.INF:
			continue
		var key := Vector2(float(towers), _flat(_own_base, pick) + _flat(pick, _enemy_base))
		if key.x < best_key.x or (key.x == best_key.x and key.y < best_key.y):
			best_key = key
			best = pick
	return best


## 13b: a seen enemy tower within 12 m of the bridge exit, or 5+ enemy soldiers seen within 12 m of it in 60 s.
func _bridge_held(memory: AIMemory, now: float, exit: Vector3) -> bool:
	if _towers_near(memory, exit, BRIDGE_COVER) > 0:
		return true
	var holders := 0
	for e: Dictionary in memory.units.values():
		if bool(e.get("soldier", false)) and now - float(e.get("time", -INF)) <= BRIDGE_MEMORY \
				and _flat(e.get("pos", Vector3.INF), exit) <= BRIDGE_COVER:
			holders += 1
	return holders >= BRIDGE_HOLDERS


static func _towers_near(memory: AIMemory, pos: Vector3, radius: float = SIDE_TOWER_RADIUS) -> int:
	var n := 0
	for e: Dictionary in memory.buildings.values():
		if e.get("kind") == &"tower" and _flat(e.get("pos", Vector3.INF), pos) <= radius:
			n += 1
	return n


func _crossings() -> Array:
	if not _crossings_cache.is_empty():
		return _crossings_cache
	if _ok(_river) and _river.has_method(&"crossings"):
		var v: Variant = _river.call(&"crossings")
		if v is Array and not (v as Array).is_empty():
			_crossings_cache = v
			return _crossings_cache
	return CROSSINGS_FALLBACK


## A ford is open when no living Mirefang nest stands in it.
func _ford_open(center: Vector3) -> bool:
	for camp: Node3D in _camps:
		if _flat(camp.global_position, center) <= NEST_FORD_RADIUS and _camp_alive(camp):
			return false
	return true


# ---------------------------------------------------------------- B8-B11 (read by AIChampions)

## The champion flags map fill asks for now, in rule order: {"rule", "kind" (Bounty kind), "target" (Node3D or
## null), "pos", "stake"}. AIChampions checks ai.mapfill_flags, the budget, one flag per rule and places them.
func flag_candidates(now: float, memory: AIMemory) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not active():
		return out
	_now = now
	# B8: an own-bank tower neutral / enemy-held and no squad (or wizard) going -> Explore (Claim) 25 on it.
	for p: Node3D in _points:
		if _pkind(p) == &"watchtower" and _point_bank(p) == _team and _owner(p) != _team and not _job_on(p):
			var dir := _own_base - p.global_position
			dir.y = 0.0
			var pos := p.global_position + (dir.normalized() * CLAIM_OFFSET if dir.length() > 0.1 else Vector3.ZERO)
			out.append({"rule": "B8", "kind": Bounty.EXPLORE, "target": null, "pos": pos, "stake": EXPLORE_STAKE,
					"name": _name(p)})
			break
	# B9: rule 11a creeps the stag or the hollow -> Hunt 75 on its strongest creature.
	if current_creep.get("kind") == &"camp" and current_creep.get("camp_kind") in [&"hollow_stag", &"gloomcap"] \
			and _ok(current_creep.get("node")):
		var strongest: Node3D = null
		var best := -1.0
		for c: Variant in _creatures(current_creep["node"] as Node3D):
			var u := c as Unit
			var s := u.hp if u != null else 0.0
			if u != null and u.unit_type != null:
				s = float(CREATURE_STRENGTH.get(u.unit_type.id, u.hp))
			if s > best:
				best = s
				strongest = c as Node3D
		if strongest != null:
			out.append({"rule": "B9", "kind": Bounty.HUNT, "target": strongest, "pos": strongest.global_position,
					"stake": HUNT_CAMP_STAKE, "name": _name(strongest)})
	# B10: an enemy seen within 25 m of an own-held well in the last 30 s -> Guard 50 on the well.
	if memory != null:
		for p: Node3D in _points:
			if _pkind(p) == &"well" and _owner(p) == _team \
					and memory.fighter_near(p.global_position, WELL_ALARM, now, ENEMY_MEMORY):
				out.append({"rule": "B10", "kind": Bounty.GUARD, "target": p, "pos": p.global_position,
						"stake": GUARD_STAKE, "name": _name(p)})
				break
	# B11: rule 11e sends the army to a beast -> Hunt (100, hard 150) on it.
	if current_creep.get("kind") == &"beast" and _unit_alive(current_creep.get("node")):
		var b := current_creep["node"] as Node3D
		out.append({"rule": "B11", "kind": Bounty.HUNT, "target": b, "pos": b.global_position,
				"stake": _ai.beast_hunt_stake, "name": _name(b)})
	return out


# ---------------------------------------------------------------- helpers

func _move(u: Unit, pos: Vector3) -> void:
	if u == null or not u.is_commandable():
		return
	var id := u.get_instance_id()
	var last: Array = _orders.get(id, [])
	if not last.is_empty() and _flat(last[0], pos) <= 1.0 and _now - float(last[1]) < 6.0:
		return
	_orders[id] = [pos, _now]
	u.command_move(pos)


func _visible(pos: Vector3) -> bool:
	return _fog == null or _fog.is_visible(_team, pos)


static func _distance_to(pos: Vector3, buildings: Array[Building]) -> float:
	var best := INF
	for b in buildings:
		if b != null and is_instance_valid(b):
			best = minf(best, _flat(b.global_position, pos))
	return best


## Decision cost of this think tick (several calls per tick add up into one sample).
func _count(usec: int, part: StringName = &"") -> void:
	if part != &"":
		usec_parts[part] = int(usec_parts.get(part, 0)) + usec
	if _now != _counted_tick:
		if _counted_tick >= 0.0 or tick_count > 0:
			usec_samples.append(_tick_usec)
			if usec_samples.size() > SAMPLES_KEPT:
				usec_samples.remove_at(0)
		_counted_tick = _now
		_tick_usec = 0
		tick_count += 1
	_tick_usec += usec
	usec_total += usec


## Median decision cost per think tick, in ms.
func median_ms() -> float:
	if usec_samples.is_empty():
		return float(_tick_usec) / 1000.0
	var s := usec_samples.duplicate()
	s.sort()
	return float(s[s.size() / 2]) / 1000.0


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
