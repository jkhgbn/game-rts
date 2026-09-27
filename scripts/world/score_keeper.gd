class_name ScoreKeeper
extends Node
## Step 16a: the running SCORE of each team (docs/plan/waves.md "Step 16a"). One node per match, group "score",
## created by the Skirmish at match start (`ScoreKeeper.instance(tree)` finds it). It only listens and samples:
## - military: enemy unit / building value killed (Events.unit_died, Building.destroyed; the killer's team from
##   `killer`), own value lost;
## - economy: crystals gathered (Economy.gathered_total), essence gained (EssenceBank.changed, positive steps),
##   gold earned and trade gold (GoldBank.earned), peak worker count;
## - map: capture-point-seconds held (CapturePoints.held_by, sampled every second), camps cleared
##   (CampManager.cleared_count), epic beasts slain (EpicBeasts.beast_slain), expansions built (a drop-off building
##   other than a keep completed more than EXPANSION_DISTANCE from the team's base), game hunted
##   (CritterHerds.hunted_count);
## - growth: peak wizard level, peak sum of champion levels, keep tier and research count (when step 14 exposes
##   them: a keep property `tier` / `keep_tier` / `upgrade_level`, a node in group "research" with
##   `researched_count(team)`).
## Every step-12 / trade service is optional (found by group, checked with has_method / has_signal).
## A history point (every category + the total) is taken every HISTORY_INTERVAL seconds of match time, plus one at
## the start and one when the match ends (`finish()`).
## API: score(team), breakdown(team), history(team), leader(), margin(), table_text(); tests may feed numbers
## through add_stat / set_stat / sample_now.

## Weights: points per unit of each raw stat. Tuned so that in a ~20 min 1v1 each category is worth thousands:
## economy ~6-9k (15k crystals gathered), military ~4-8k (enemy value killed), map ~2-4k (4 points held ~15 min,
## a few camps / beasts / expansions), growth ~2-4k (wizard level 8, three level-4 champions, keep tiers).
## A negative weight is a penalty; a category never goes below 0.
const WEIGHTS := {
	# military
	&"value_killed": 1.0,        ## per crystal of enemy unit / building value killed
	&"value_lost": -0.25,        ## per crystal of own value lost
	# economy
	&"crystals": 0.4,            ## per crystal gathered
	&"essence": 0.5,             ## per essence gained (trickle, kills, caches)
	&"gold": 0.6,                ## per gold earned (all sources)
	&"trade_gold": 0.2,          ## bonus per gold earned by caravans (on top of `gold`)
	&"peak_workers": 40.0,       ## per worker at the peak
	# map
	&"point_seconds": 0.3,       ## per second a capture point is held (8 points)
	&"camps": 150.0,             ## per neutral camp cleared
	&"beasts": 400.0,            ## per epic beast slain
	&"expansions": 300.0,        ## per expansion drop-off built
	&"critters": 30.0,           ## per deer / rabbit hunted
	# growth
	&"wizard_level": 200.0,      ## per wizard level above 1 (peak)
	&"champion_levels": 120.0,   ## per champion level (peak sum over the team's champions)
	&"keep_tier": 400.0,         ## per keep tier above 1 (peak, step 14)
	&"research": 150.0,          ## per research done (step 14)
}
## Stat -> category, in table order.
const CATEGORIES := {
	&"military": [&"value_killed", &"value_lost"],
	&"economy": [&"crystals", &"essence", &"gold", &"trade_gold", &"peak_workers"],
	&"map": [&"point_seconds", &"camps", &"beasts", &"expansions", &"critters"],
	&"growth": [&"wizard_level", &"champion_levels", &"keep_tier", &"research"],
}
const CATEGORY_NAMES := {&"military": "Military", &"economy": "Economy", &"map": "Map control", &"growth": "Growth"}
## Stats whose weight applies above a base value (a level-1 wizard / tier-1 keep scores 0).
const BASELINE := {&"wizard_level": 1, &"keep_tier": 1}
## Stats kept as the maximum ever seen (set_stat keeps the peak for them).
const PEAK_STATS: Array[StringName] = [&"peak_workers", &"wizard_level", &"champion_levels", &"keep_tier"]

const TEAMS: Array[int] = [0, 1]            ## Unit.Team.PLAYER, Unit.Team.ENEMY
const NEUTRAL_TEAM := 2
const SAMPLE_INTERVAL := 1.0                ## Seconds between samples of totals.
const HISTORY_INTERVAL := 30.0              ## Seconds of match time between history points.
const EXPANSION_DISTANCE := 25.0            ## A drop-off this far from the base centre is an expansion.
## Value of units / buildings without a crystal cost.
const KEEP_VALUE := 600
const WIZARD_VALUE := 300                   ## + WIZARD_VALUE_PER_LEVEL x level
const WIZARD_VALUE_PER_LEVEL := 50
const CHAMPION_VALUE := 250                 ## + CHAMPION_VALUE_PER_LEVEL x level
const CHAMPION_VALUE_PER_LEVEL := 50

## Seconds of match time (the Skirmish sets it to its match_time); unset = this node's own clock.
var match_time_source: Callable
## The level (for base_center(team) / kingdom_of(team)); may be null (tests).
var level: Node
## False once finish() ran (no more sampling or counting).
var running := true

var _stats := {}            # team -> {stat: float}
var _history := {}          # team -> Array[Dictionary]
var _clock := 0.0
var _sample_left := 0.0
var _next_history := 0.0
var _essence_seen := {}     # EssenceBank instance id -> last essence
var _hooked := {}           # object instance id -> true (signals connected)


## The match's ScoreKeeper (group "score"), or null.
static func instance(tree: SceneTree) -> ScoreKeeper:
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"score"):
		if n is ScoreKeeper and not n.is_queued_for_deletion():
			return n as ScoreKeeper
	return null


func _init() -> void:
	for team in TEAMS:
		var s := {}
		for stat: StringName in WEIGHTS:
			s[stat] = 0.0
		_stats[team] = s
		_history[team] = []


func _enter_tree() -> void:
	add_to_group(&"score")


func _ready() -> void:
	var events := get_node_or_null(^"/root/Events")
	if events:
		if events.has_signal(&"unit_died") and not events.is_connected(&"unit_died", _on_unit_died):
			events.connect(&"unit_died", _on_unit_died)
		if events.has_signal(&"building_completed") and not events.is_connected(&"building_completed", _on_building_completed):
			events.connect(&"building_completed", _on_building_completed)
	for b in get_tree().get_nodes_in_group(&"buildings"):
		_watch_building(b)
	get_tree().node_added.connect(_on_node_added)
	sample_now()
	_record_history()
	_next_history = HISTORY_INTERVAL


func _physics_process(delta: float) -> void:
	if not running:
		return
	if level != null and is_instance_valid(level) and level.get(&"game_over") == true:
		finish()
		return
	_clock += delta
	_sample_left -= delta
	if _sample_left <= 0.0:
		var dt := SAMPLE_INTERVAL - _sample_left   # the time since the last sample
		_sample_left = SAMPLE_INTERVAL
		_sample_points(minf(dt, SAMPLE_INTERVAL * 2.0))
		sample_now()
	if now() >= _next_history:
		_record_history()
		_next_history += HISTORY_INTERVAL


# ---------------------------------------------------------------- API

## Seconds of match time.
func now() -> float:
	if match_time_source.is_valid():
		return float(match_time_source.call())
	return _clock


## The team's total score.
func score(team: int) -> int:
	return int(breakdown(team)["total"])


## {"military", "economy", "map", "growth", "total"} (ints) and "stats" (the raw stats, a copy).
func breakdown(team: int) -> Dictionary:
	var s: Dictionary = _stats.get(team, {})
	var out := {}
	var total := 0
	for cat: StringName in CATEGORIES:
		var pts := 0.0
		for stat: StringName in CATEGORIES[cat]:
			pts += maxf(0.0, float(s.get(stat, 0.0)) - float(BASELINE.get(stat, 0))) * float(WEIGHTS[stat])
		var v := maxi(0, roundi(pts))
		out[String(cat)] = v
		total += v
	out["total"] = total
	out["stats"] = s.duplicate()
	return out


## History points of the team, oldest first: {"t": seconds, "total", "military", "economy", "map", "growth"}.
func history(team: int) -> Array:
	return (_history.get(team, []) as Array).duplicate()


## The team with the higher score, -1 on a tie.
func leader() -> int:
	var a := score(TEAMS[0])
	var b := score(TEAMS[1])
	if a == b:
		return -1
	return TEAMS[0] if a > b else TEAMS[1]


## The absolute score difference between the two teams.
func margin() -> int:
	return absi(score(TEAMS[0]) - score(TEAMS[1]))


## Adds to a raw stat (tests, or systems without a signal).
func add_stat(team: int, stat: StringName, amount: float) -> void:
	if running and _stats.has(team) and WEIGHTS.has(stat):
		_stats[team][stat] = float(_stats[team][stat]) + amount


## Sets a raw stat (peak stats keep the maximum).
func set_stat(team: int, stat: StringName, value: float) -> void:
	if not running or not _stats.has(team) or not WEIGHTS.has(stat):
		return
	if PEAK_STATS.has(stat):
		value = maxf(value, float(_stats[team][stat]))
	_stats[team][stat] = value


## Raw stat value.
func stat(team: int, stat_id: StringName) -> float:
	return float((_stats.get(team, {}) as Dictionary).get(stat_id, 0.0))


## Takes the final sample and history point, then stops. Safe to call twice.
func finish() -> void:
	if not running:
		return
	sample_now()
	_record_history()
	running = false


## Reads every sampled total now (crystals, gold, workers, levels, camps...). Point-seconds are not added here.
func sample_now() -> void:
	if not running or not is_inside_tree():
		return
	var tree := get_tree()
	var workers := {}
	var wiz_level := {}
	var champ_levels := {}
	for team in TEAMS:
		workers[team] = 0
		wiz_level[team] = 0
		champ_levels[team] = 0
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not _stats.has(int(u.team)):
			continue
		var team := int(u.team)
		if u.is_in_group(&"champions"):
			champ_levels[team] = int(champ_levels[team]) + u.level
		elif u is Wizard:
			wiz_level[team] = maxi(int(wiz_level[team]), u.level)
		elif u.is_alive() and u.has_method(&"command_gather"):
			workers[team] = int(workers[team]) + 1
	for team in TEAMS:
		set_stat(team, &"peak_workers", workers[team])
		if int(wiz_level[team]) > 0:
			set_stat(team, &"wizard_level", wiz_level[team])
		set_stat(team, &"champion_levels", champ_levels[team])
		var eco := Economy.for_team(team)
		if eco:
			set_stat(team, &"crystals", eco.gathered_total)
		var bank := _node_of_team(&"gold_banks", team)
		if bank and bank.has_method(&"earned"):
			set_stat(team, &"gold", int(bank.call(&"earned")))
			set_stat(team, &"trade_gold", int(bank.call(&"earned", &"trade")))
		var ess := _node_of_team(&"essence_banks", team)
		if ess:
			_hook_essence(ess)
		var tier := _keep_tier(team)
		if tier > 0:
			set_stat(team, &"keep_tier", tier)
		var research := _research_count(team)
		if research >= 0:
			set_stat(team, &"research", research)
	var cm := tree.get_first_node_in_group(&"camp_manager")
	if cm and cm.has_method(&"cleared_count"):
		for team in TEAMS:
			set_stat(team, &"camps", int(cm.call(&"cleared_count", team)))
	var ch := tree.get_first_node_in_group(&"critter_herds")
	if ch and ch.has_method(&"hunted_count"):
		for team in TEAMS:
			set_stat(team, &"critters", int(ch.call(&"hunted_count", team)))
	var eb := tree.get_first_node_in_group(&"epic_beasts")
	if eb and eb.has_signal(&"beast_slain") and not _hooked.has(eb.get_instance_id()):
		_hooked[eb.get_instance_id()] = true
		eb.connect(&"beast_slain", _on_beast_slain)


## A plain-text table for logs: the four categories and the total per team, then the raw stats.
func table_text() -> String:
	var names: Array[String] = []
	for team in TEAMS:
		names.append(team_name(team))
	var lines: Array[String] = []
	lines.append("%-16s %16s %16s" % ["SCORE at " + _clock_text(now()), names[0], names[1]])
	var b0 := breakdown(TEAMS[0])
	var b1 := breakdown(TEAMS[1])
	for cat: StringName in CATEGORIES:
		lines.append("%-16s %16s %16s" % [CATEGORY_NAMES[cat], fmt(int(b0[String(cat)])), fmt(int(b1[String(cat)]))])
	lines.append("%-16s %16s %16s" % ["TOTAL", fmt(int(b0["total"])), fmt(int(b1["total"]))])
	for cat: StringName in CATEGORIES:
		for st: StringName in CATEGORIES[cat]:
			lines.append("  %-14s %16s %16s" % [String(st), fmt(roundi(stat(TEAMS[0], st))), fmt(roundi(stat(TEAMS[1], st)))])
	var lead := leader()
	lines.append("leader: %s by %s" % ["tie" if lead < 0 else "team %d" % lead, fmt(margin())])
	return "\n".join(lines)


## "Team 0 (fire)" style name (the level's kingdom_of when it has one).
func team_name(team: int) -> String:
	if level != null and is_instance_valid(level) and level.has_method(&"kingdom_of"):
		return "Team %d (%s)" % [team, String(level.call(&"kingdom_of", team))]
	return "Team %d" % team


## 12345 -> "12 345" (the end screen's thousands style).
static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = " " + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## The value of a unit / building for the military score (crystal cost; keeps, wizards, champions fixed).
static func value_of(node: Node) -> int:
	if node == null or not is_instance_valid(node):
		return 0
	if node is Building:
		var bt := (node as Building).building_type
		if bt == null:
			return 0
		return KEEP_VALUE if bt.kind == &"keep" else bt.cost
	var u := node as Unit
	if u == null:
		return 0
	if u.is_in_group(&"champions"):
		return CHAMPION_VALUE + CHAMPION_VALUE_PER_LEVEL * u.level
	if u is Wizard:
		return WIZARD_VALUE + WIZARD_VALUE_PER_LEVEL * u.level
	return u.unit_type.cost if u.unit_type != null else 0


## Credits a kill of `value` (victim of `victim_team`, killed by `killer_team`; -1 = unknown = the other side).
func record_kill(victim_team: int, killer_team: int, value: int) -> void:
	if not running or value <= 0 or not _stats.has(victim_team):
		return
	add_stat(victim_team, &"value_lost", value)
	if killer_team < 0:
		killer_team = TEAMS[1] if victim_team == TEAMS[0] else TEAMS[0]
	if killer_team != victim_team and _stats.has(killer_team):
		add_stat(killer_team, &"value_killed", value)


# ---------------------------------------------------------------- listeners

func _on_unit_died(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or unit.get(&"team") == null:
		return
	var victim_team := int(unit.get(&"team"))
	if not _stats.has(victim_team):
		return
	record_kill(victim_team, _killer_team(unit), value_of(unit))


func _on_node_added(node: Node) -> void:
	if node is Building:
		_watch_building(node)


func _watch_building(node: Node) -> void:
	if node is Building and not node.is_connected(&"destroyed", _on_building_destroyed):
		node.connect(&"destroyed", _on_building_destroyed)


func _on_building_destroyed(building: Building) -> void:
	if building == null or not is_instance_valid(building) or building.cancelled:
		return
	var victim_team := int(building.team)
	if _stats.has(victim_team):
		record_kill(victim_team, _killer_team(building), value_of(building))


func _on_building_completed(building: Node) -> void:
	if not running or building == null or not is_instance_valid(building) or building is Keep:
		return
	var b := building as Building
	if b == null or not _stats.has(int(b.team)) or not b.is_drop_off():
		return
	var base := _base_of(int(b.team))
	if base != Vector3.INF and Vector2(b.global_position.x - base.x, b.global_position.z - base.z).length() > EXPANSION_DISTANCE:
		add_stat(int(b.team), &"expansions", 1.0)


func _on_beast_slain(_beast: Node, team: int, _drops: Array) -> void:
	if _stats.has(team):
		add_stat(team, &"beasts", 1.0)


func _on_essence_changed(bank: Node) -> void:
	if not running or bank == null or not is_instance_valid(bank):
		return
	var id := bank.get_instance_id()
	var now_value := int(bank.get(&"essence"))
	var before := int(_essence_seen.get(id, now_value))
	_essence_seen[id] = now_value
	if now_value > before:
		add_stat(int(bank.get(&"team")), &"essence", now_value - before)


# ---------------------------------------------------------------- helpers

## Capture-point-seconds: each point the team holds counts `dt` seconds.
func _sample_points(dt: float) -> void:
	var cp := get_tree().get_first_node_in_group(&"capture_points_service")
	if cp == null or not cp.has_method(&"held_by"):
		return
	for team in TEAMS:
		add_stat(team, &"point_seconds", float((cp.call(&"held_by", team) as Array).size()) * dt)


func _record_history() -> void:
	var t := now()
	for team in TEAMS:
		var b := breakdown(team)
		var point := {"t": t, "total": b["total"], "military": b["military"], "economy": b["economy"],
				"map": b["map"], "growth": b["growth"]}
		var hist: Array = _history[team]
		if not hist.is_empty() and absf(float((hist.back() as Dictionary)["t"]) - t) < 0.01:
			hist[hist.size() - 1] = point   # same instant (finish right after a history tick)
		else:
			hist.append(point)


func _hook_essence(bank: Node) -> void:
	var id := bank.get_instance_id()
	if _hooked.has(id) or not bank.has_signal(&"changed"):
		return
	_hooked[id] = true
	_essence_seen[id] = int(bank.get(&"essence"))
	# Essence held before the hook (the start 150) counts as gained.
	add_stat(int(bank.get(&"team")), &"essence", float(_essence_seen[id]))
	bank.connect(&"changed", _on_essence_changed.bind(bank))


func _node_of_team(group: StringName, team: int) -> Node:
	for n in get_tree().get_nodes_in_group(group):
		if n.get(&"team") != null and int(n.get(&"team")) == team and not n.is_queued_for_deletion():
			return n
	return null


func _keep_tier(team: int) -> int:
	if TierSystem.instance() != null:   # tiers.md: the team tier (highest living keep), Keep.tier below otherwise
		return TierSystem.tier_of(team)
	var best := 0
	for b in Building.for_team(team):
		if b is Keep:
			for prop: StringName in [&"tier", &"keep_tier", &"upgrade_level"]:
				var v: Variant = b.get(prop)
				if v is int:
					best = maxi(best, v)
					break
	return best


func _research_count(team: int) -> int:
	var r := get_tree().get_first_node_in_group(&"research")
	if r and r.has_method(&"researched_count"):
		return int(r.call(&"researched_count", team))
	return -1


func _base_of(team: int) -> Vector3:
	if level != null and is_instance_valid(level) and level.has_method(&"base_center"):
		return level.call(&"base_center", team)
	for b in Building.for_team(team):
		if b is Keep:
			return b.global_position
	return Vector3.INF


static func _killer_team(victim: Node) -> int:
	var k: Variant = victim.get(&"killer")
	if typeof(k) == TYPE_OBJECT and is_instance_valid(k):
		var t: Variant = (k as Object).get(&"team")
		if t != null:
			return int(t)
	return -1


static func _clock_text(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
