class_name AICasters
extends Node
## The bot's caster units (docs/design/caster-units.md 8; task CU.A1): one AICasters node per Commander (its child,
## made in Commander._setup), ticking every 0.5 s while the Commander is enabled and the match runs.
## 8.1 Training: Easy none; Normal 1 caster at tier 2 (2 at the Citadel); Hard 2 (3). Tier >= 2, no worker in the keep's
##   queue, crystals >= 150 + 100, casters <= 10 % of the soldier pop (rounded up), at the keep closest to the rally.
##   Hard queues it before any other Hall unit (Commander._rule_train calls try_train(true) first); Normal from its
##   own tick (after the rule-5 spending).
## 8.2 Positioning: each caster stands 4 m behind the centre of the army group it follows (the attack group while one
##   is out, else the soldiers at the rally), on the side away from the nearest seen enemy; never leads (a plain move,
##   never an attack-move). Flee: a melee enemy within 3.5 m or HP < 50 % -> 6 m away toward the rear, at most once per
##   1.5 s. When the Commander retreats, the casters leave first. With 2+ Gloom Deacons one (the anchor) stays home.
##   Strength: AIMemory.strength_of counts a caster cost x 0.5 (x 1.0 with mana >= twice its cheapest spell).
##   Target preference: every bot soldier fighting near a visible enemy caster switches to it (unless it hits an
##   enemy wizard under 30 % HP); hard: fast units (cavalry, hounds, Scorchlings, Thistle Darters) dive the enemy
##   casters when 2+ are seen. Counter-mix: 2+ enemy casters seen -> fast units +0.05 of the training mix.
## 8.3 Casting: every spell autocasts for bots (CasterAbility.bot_controlled, reaction easy 1.5 s / normal 0.5 / hard
##   0.25; hard waits for an enemy caster's cast before Mana Scald and holds Pollen Haze for 5 ranged units early in a
##   fight), plus: Rimecarver a) dive guard (normal, hard), b) retreat cover (hard), c) runes every 30 s ahead of an
##   attacking group and on a unit hit from the fog (hard); max one Bulwark per 3 s per team. Gloom Deacon: retreat
##   Passage (normal, hard: a retreating group >= 25 m away), home Passage (hard: the base attacked while the group is
##   >= 35 m from home, cast by the anchor at home).
## Test hook: AICasters.last_cast(team) -> {id, target, time, rule}; history(team) -> the last 50 of those.

const TICK := 0.5
const FOLLOW_BEHIND := 4.0
const HOME_OFFSET := 6.0
const HOME_GROUP_RADIUS := 15.0
const REORDER_DIST := 2.5
const REORDER_EVERY := 2.0
const FLEE_MELEE := 3.5
const FLEE_HP := 0.5
const FLEE_DIST := 6.0
const FLEE_EVERY := 1.5
const ENEMY_NEAR := 30.0
const BULWARK_TEAM_EVERY := 3.0
const RETREAT_CHASE := 8.0
const RUNE_EVERY := 30.0
const RUNE_AHEAD := 10.0
const RUNE_BLIND_RADIUS := 12.0
const PASSAGE_RETREAT_DIST := 25.0
const PASSAGE_HOME_DIST := 35.0
const PREFER_EXTRA := 2.0            ## a soldier switches to an enemy caster within its aggro range + this
const WIZARD_FOCUS_HP := 0.3
const DIVE_RADIUS := 20.0
const DIVE_EVERY := 2.0
const SEEN_MEMORY := 60.0
const COUNTER_MIX := 0.05
const FAST_IDS: Array[StringName] = [&"blaze_rider", &"grave_hound", &"scorchling", &"thistle_darter",
		&"snowdrift_rider", &"gloam_rider", &"stagrunner", &"pyrehoof_lancer", &"rimehorn_rider", &"glade_outrider"]
const FAST_SPEED := 6.5
## Difficulty (Commander.Difficulty: 0 easy, 1 normal, 2 hard) -> the casters' autocast reaction (s).
const REACTION := {0: 1.5, 1: 0.5, 2: 0.25}
const HISTORY_MAX := 50

static var _last := {}        # team -> {id, target, time, rule}
static var _history := {}     # team -> Array of those
static var _by_team := {}     # team -> AICasters (the counter-mix read)

var commander: Node           ## the Commander (read through its public accessors)
var team := 1
var difficulty := 1
## Enemy casters seen in the last 60 s (instance id -> time), for the counter-mix and the hard dive.
var seen_enemy_casters := {}
## The Gloom Deacon that stays home (2+ Deacons), or null.
var anchor: Unit = null
## Casters queued by this bot (tests / logs).
var trained := 0
## Rule -> casts (dive_guard, retreat_cover, rune_ahead, rune_blind, retreat_passage, home_passage, autocast).
var casts_by_rule := {}

var _tick_left := 0.0
var _flee_at := {}            # caster instance id -> time of its last flee
var _orders := {}             # caster instance id -> [pos, time]
var _dive_at := {}            # soldier instance id -> time of its last dive order
var _bulwark_at := -INF
var _rune_at := -INF
var _adopted := {}            # caster instance id -> true
var _rule_of := {}            # CasterAbility instance id -> the rule of its cast in flight (spell_cast lands later)


func _init(cmd: Node = null) -> void:
	commander = cmd
	name = "AICasters"
	if cmd:
		team = int(cmd.get(&"team"))
		difficulty = int(cmd.get(&"difficulty"))


func _ready() -> void:
	_by_team[team] = self
	_tick_left = TICK * float(team % 3) / 3.0


func _exit_tree() -> void:
	if _by_team.get(team) == self:
		_by_team.erase(team)


## The last cast of a bot caster of `team` ({} when none): {id, target, time, rule}.
static func last_cast(for_team: int) -> Dictionary:
	return _last.get(for_team, {})


## The bot casters' casts of `team`, oldest first (the last 50).
static func history(for_team: int) -> Array:
	return _history.get(for_team, [])


## Counter-mix (8.2): +0.05 of the training mix for a fast unit type while 2+ enemy casters were seen.
static func mix_bonus(for_team: int, type: UnitType) -> float:
	var ai: AICasters = _by_team.get(for_team)
	if ai == null or not is_instance_valid(ai) or type == null or not is_fast(type):
		return 0.0
	return COUNTER_MIX if ai.enemy_casters_seen() >= 2 else 0.0


static func is_fast(type: UnitType) -> bool:
	return type != null and (FAST_IDS.has(type.id) or type.move_speed >= FAST_SPEED) and type.attack_range <= 3.0 \
			and not CasterKit.is_caster(type.id) and not type.is_worker


func enemy_casters_seen() -> int:
	var now := CasterKit.now_s()
	var n := 0
	for k: Variant in seen_enemy_casters.keys():
		if now - float(seen_enemy_casters[k]) <= SEEN_MEMORY:
			n += 1
		else:
			seen_enemy_casters.erase(k)
	return n


# ---------------------------------------------------------------- 8.1 training

## Queues one caster at the keep when the 8.1 rules allow it. `priority` = the hard bot's call from rule 5 (before any
## Hall unit). True = queued now.
func try_train(priority: bool) -> bool:
	if not CasterKit.enabled_here() or commander == null or difficulty <= 0:
		return false
	if priority and difficulty < 2:
		return false
	var tier := TierSystem.tier_of(team)
	if tier < 2:
		return false
	var faction: StringName = commander.get(&"faction")
	var type := UnitType.find(String(CasterKit.caster_for(faction)))
	if type == null:
		return false
	var want := int(CasterKit.BOT_KEEP.get(difficulty, 0)) + (1 if tier >= 3 else 0)
	var soldier_pop := 0
	for u in _valid(commander.call(&"own_soldiers")):
		soldier_pop += u.unit_type.pop if u.unit_type else 1
	var cap := ceili(CasterKit.BOT_SHARE_CAP * float(soldier_pop))
	var allowed := mini(want, cap)
	var have := T3Kit.count_alive(team, type.id, true)
	if have >= allowed:
		return false
	var eco := Economy.for_team(team)
	if eco == null or eco.crystals < type.cost + CasterKit.BOT_RESERVE:
		return false
	var keep := _training_keep()
	if keep == null or keep.queue.size() >= 2:
		return false
	for t in keep.queue:
		if t and t.is_worker:
			return false   # the workers first (the Queen trade-off)
	if keep.can_queue(type) != "" or keep.queue_unit(type) != "":
		return false
	trained += 1
	if commander.has_method(&"note_log"):
		commander.call(&"note_log", "CASTER TRAIN %s (%d / %d, soldier pop %d, crystals left %d)" % [type.display_name,
				have + 1, allowed, soldier_pop, eco.crystals])
	return true


# The own keep of tier >= 2 closest to the rally point.
func _training_keep() -> Keep:
	var rally: Vector3 = commander.call(&"rally_point")
	var best: Keep = null
	var bd := INF
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var k := n as Keep
		if k == null or int(k.team) != team or not k.is_alive() or not k.is_constructed() or k.tier < 2:
			continue
		var d := _flat(k.global_position, rally)
		if d < bd:
			bd = d
			best = k
	return best


# ---------------------------------------------------------------- the tick

func _physics_process(delta: float) -> void:
	if commander == null or not is_instance_valid(commander) or not bool(commander.get(&"enabled")):
		return
	var level: Node = commander.get_parent()
	if level == null or not bool(level.get(&"match_started")) or bool(level.get(&"game_over")):
		return
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	think()


## One 0.5 s pass: adopt new casters, see enemy casters, train (normal), position, flee, cast, target preference.
func think() -> void:
	if not CasterKit.ENABLED:
		return
	if difficulty >= 1 and not bool(commander.call(&"queued_this_tick")):
		try_train(false)
	var casters := _valid(commander.call(&"own_casters"))
	var enemies := _valid(commander.call(&"seen_enemies"))
	var now := CasterKit.now_s()
	var enemy_casters: Array[Unit] = []
	for e in enemies:
		if is_instance_valid(e) and e.is_alive() and CasterKit.is_caster_unit(e):
			enemy_casters.append(e)
			seen_enemy_casters[e.get_instance_id()] = now
	_prefer_casters(enemy_casters)
	if casters.is_empty():
		return
	_pick_anchor(casters)
	var group := _follow_group()
	var centre := _centre(group)
	for c in casters:
		if not is_instance_valid(c) or not c.is_alive():
			continue
		_adopt(c)
		var ab := CasterKit.ability_of(c)
		if ab == null or c.is_displaced() or ab.is_casting() or ab.channel_id() == &"umbral_passage":
			continue
		if _flee(c, group, centre, enemies, now):
			continue
		if _cast_rules(c, ab, group, centre, enemies, now):
			continue
		_position(c, ab, group, centre, enemies, now)


func _adopt(c: Unit) -> void:
	var key := c.get_instance_id()
	if _adopted.has(key):
		return
	_adopted[key] = true
	var ab := CasterKit.ability_of(c)
	if ab == null:
		return
	ab.bot_controlled = true
	ab.bot_hard = difficulty >= 2
	ab.reaction = float(REACTION.get(difficulty, 0.5))
	for s in ab.spell_ids():
		ab.set_autocast(s, true)
	ab.spell_cast.connect(_on_spell_cast.bind(weakref(c)))


func _on_spell_cast(spell_id: StringName, ref: WeakRef) -> void:
	var c := ref.get_ref() as Unit
	var ab := CasterKit.ability_of(c) if c else null
	var rule := "autocast"
	if ab and _rule_of.has(ab.get_instance_id()):
		var r: Array = _rule_of[ab.get_instance_id()]
		_rule_of.erase(ab.get_instance_id())
		if CasterKit.now_s() - float(r[1]) <= 3.0:   # a cancelled cast's rule never sticks to a later one
			rule = String(r[0])
	var entry := {"id": spell_id, "target": ab.last_target if ab else null, "time": CasterKit.now_s(), "rule": rule,
			"caster": String(c.unit_type.id) if c and c.unit_type else ""}
	_last[team] = entry
	var h: Array = _history.get(team, [])
	h.append(entry)
	if h.size() > HISTORY_MAX:
		h.pop_front()
	_history[team] = h
	casts_by_rule[rule] = int(casts_by_rule.get(rule, 0)) + 1


# ---------------------------------------------------------------- 8.2 positioning

# With 2+ Gloom Deacons, the first one stays home.
func _pick_anchor(casters: Array[Unit]) -> void:
	var deacons: Array[Unit] = []
	for c in casters:
		if c.unit_type and c.unit_type.id == &"gloom_deacon" and c.is_alive():
			deacons.append(c)
	if deacons.size() < 2:
		anchor = null
		return
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_alive() or not deacons.has(anchor):
		anchor = deacons[0]


# The group the casters follow: the attack group while it is out (or retreating), else the soldiers at the rally.
func _follow_group() -> Array[Unit]:
	var out: Array[Unit] = []
	if bool(commander.call(&"group_out")) or bool(commander.call(&"is_retreating")):
		out = _valid(commander.call(&"army_group"))
		if not out.is_empty():
			return out
	var rally: Vector3 = commander.call(&"rally_point")
	for u in _valid(commander.call(&"own_soldiers")):
		if _flat(u.global_position, rally) <= HOME_GROUP_RADIUS:
			out.append(u)
	return out


## The living units of `list` (the commander's lists may hold units freed since its last scan).
static func _valid(list: Variant) -> Array[Unit]:
	var out: Array[Unit] = []
	if list is Array:
		for v: Variant in list:
			if is_instance_valid(v) and v is Unit and (v as Unit).is_alive():
				out.append(v)
	return out


func _centre(group: Array[Unit]) -> Vector3:
	if group.is_empty():
		return _home_spot()
	var c := Vector3.ZERO
	for u in group:
		c += u.global_position
	c /= float(group.size())
	return Vector3(c.x, 0.0, c.z)


# No group: 6 m from the own keep toward the map centre.
func _home_spot() -> Vector3:
	var k: Node3D = commander.call(&"home_keep")
	if k == null or not is_instance_valid(k):
		return commander.call(&"rally_point")
	var to_mid := -Vector3(k.global_position.x, 0.0, k.global_position.z)
	var d := to_mid.normalized() if to_mid.length() > 0.1 else Vector3.FORWARD
	return Vector3(k.global_position.x, 0.0, k.global_position.z) + d * (Unit.radius_of(k) + HOME_OFFSET)


# The side away from the nearest seen enemy (or from the map centre when none): unit vector.
func _rear_dir(centre: Vector3, enemies: Array[Unit]) -> Vector3:
	var best: Unit = null
	var bd := ENEMY_NEAR
	for e in enemies:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var d := _flat(e.global_position, centre)
		if d < bd:
			bd = d
			best = e
	var away := Vector3.ZERO
	if best:
		away = centre - best.global_position
	else:
		away = centre   # away from the map centre (0, 0)
	away.y = 0.0
	return away.normalized() if away.length() > 0.05 else Vector3.FORWARD


func _position(c: Unit, ab: CasterAbility, group: Array[Unit], centre: Vector3, enemies: Array[Unit], now: float) -> void:
	var goal: Vector3
	if c == anchor:
		goal = _home_spot()
	elif bool(commander.call(&"is_retreating")):
		goal = commander.call(&"rally_point")   # the casters leave first
	else:
		goal = centre + _rear_dir(centre, enemies) * FOLLOW_BEHIND
	if ab.tithe_target() != null and _flat(ab.tithe_target().global_position, goal) > 7.0:
		return   # a tether in progress: stay by the ally (it breaks at 9 m)
	_move(c, goal, now)


func _move(c: Unit, goal: Vector3, now: float, force := false) -> void:
	var key := c.get_instance_id()
	if _flat(c.global_position, goal) <= REORDER_DIST and not force:
		return
	var last: Array = _orders.get(key, [])
	if not force and not last.is_empty() and _flat(last[0], goal) < REORDER_DIST and now - float(last[1]) < REORDER_EVERY \
			and c.has_move_order():
		return
	c.command_move(goal)
	_orders[key] = [goal, now]


# A melee enemy within 3.5 m, or HP under 50 %: 6 m away toward the rear (once per 1.5 s). True = fled.
func _flee(c: Unit, group: Array[Unit], centre: Vector3, enemies: Array[Unit], now: float) -> bool:
	var key := c.get_instance_id()
	if now - float(_flee_at.get(key, -INF)) < FLEE_EVERY:
		return c.has_move_order()   # still fleeing: no other order meanwhile
	var threat: Unit = null
	var td := FLEE_MELEE
	for e in enemies:
		if not is_instance_valid(e) or not e.is_alive() or e.attack_range > 3.0:
			continue
		var d := _flat(e.global_position, c.global_position)
		if d <= td + e.radius:
			td = d
			threat = e
	var hurt := c.hp < c.max_hp * FLEE_HP and _any_enemy_near(c.global_position, enemies, 10.0)
	if threat == null and not hurt:
		return false
	var away: Vector3
	if threat:
		away = c.global_position - threat.global_position
	else:
		away = _rear_dir(centre, enemies)
	away.y = 0.0
	away = away.normalized() if away.length() > 0.05 else _rear_dir(centre, enemies)
	# Toward the group's rear when the escape runs toward the enemy side (never back through the threat).
	var rear := _rear_dir(centre, enemies)
	if not group.is_empty() and away.dot(rear) < 0.0:
		away = (away + rear * 0.5).normalized()
	var tower := _nearest_own_tower(c.global_position, 14.0)
	var goal := c.global_position + away * FLEE_DIST
	if tower:
		goal = tower.global_position + (c.global_position - tower.global_position).normalized() * (Unit.radius_of(tower) + 1.5)
	_flee_at[key] = now
	var ab := CasterKit.ability_of(c)
	if ab and ab.tithe_target() != null:
		ab.stop_channel()
	_move(c, goal, now, true)
	return true


func _any_enemy_near(p: Vector3, enemies: Array[Unit], r: float) -> bool:
	for e in enemies:
		if is_instance_valid(e) and e.is_alive() and _flat(e.global_position, p) <= r:
			return true
	return false


func _nearest_own_tower(p: Vector3, r: float) -> Node3D:
	var best: Node3D = null
	var bd := r
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var b := n as Building
		if b == null or int(b.team) != team or not b.is_alive() or b.building_type == null or b.building_type.kind != &"tower":
			continue
		var d := _flat(b.global_position, p)
		if d < bd:
			bd = d
			best = b
	return best


# ---------------------------------------------------------------- 8.3 casting rules (beyond the autocast)

func _cast_rules(c: Unit, ab: CasterAbility, group: Array[Unit], centre: Vector3, enemies: Array[Unit], now: float) -> bool:
	match c.unit_type.id:
		&"rimecarver":
			return _rimecarver(c, ab, group, centre, enemies, now)
		&"gloom_deacon":
			return _deacon(c, ab, group, centre, now)
	return false


func _try(ab: CasterAbility, spell_id: StringName, target: Variant, rule: String) -> bool:
	if ab.cast(spell_id, target) != "":
		return false
	_rule_of[ab.get_instance_id()] = [rule, CasterKit.now_s()]   # its spell_cast (after the 0.4 s cast / the 2.5 s channel) carries it
	return true


func _rimecarver(_c: Unit, ab: CasterAbility, group: Array[Unit], centre: Vector3, enemies: Array[Unit], now: float) -> bool:
	# a) Dive guard (normal, hard). Max one Bulwark per 3 s per team.
	if now - _bulwark_at >= BULWARK_TEAM_EVERY and difficulty >= 1:
		var spot: Variant = ab.dive_guard_spot()
		if spot != null and _try(ab, &"rime_bulwark", spot, "dive_guard"):
			_bulwark_at = now
			return true
	if difficulty < 2:
		return false
	# b) Retreat cover (hard): the group retreats with enemies chasing within 8 m -> a wall behind the last own unit.
	if bool(commander.call(&"is_retreating")) and now - _bulwark_at >= BULWARK_TEAM_EVERY and not group.is_empty():
		var rally: Vector3 = commander.call(&"rally_point")
		var last: Unit = group[0]
		for u in group:
			if _flat(u.global_position, rally) > _flat(last.global_position, rally):
				last = u
		var chaser: Unit = null
		var cd := RETREAT_CHASE
		for e in enemies:
			if is_instance_valid(e) and e.is_alive() and _flat(e.global_position, last.global_position) <= cd:
				cd = _flat(e.global_position, last.global_position)
				chaser = e
		if chaser:
			var dir := Vector3(chaser.global_position.x - last.global_position.x, 0.0,
					chaser.global_position.z - last.global_position.z).normalized()
			var spot := last.global_position + dir * 2.0
			spot.y = 0.0
			if _try(ab, &"rime_bulwark", {"at": spot, "facing": -dir}, "retreat_cover"):
				_bulwark_at = now
				return true
	# c) Runes (hard): a unit hit from the fog -> a rune on it; every 30 s while attacking, one 10 m ahead.
	for u in group:
		if u.seconds_since_damage() < 0.6 and not _any_enemy_near(u.global_position, enemies, RUNE_BLIND_RADIUS):
			if _try(ab, &"scrying_rune", u.global_position, "rune_blind"):
				return true
	if bool(commander.call(&"group_out")) and now - _rune_at >= RUNE_EVERY and not group.is_empty():
		var rally: Vector3 = commander.call(&"rally_point")
		var ahead := centre - rally
		ahead.y = 0.0
		if ahead.length() > 1.0:
			var p := centre + ahead.normalized() * RUNE_AHEAD
			if ab.distance_to_target(p) > float(CasterKit.spell_value(&"scrying_rune", "range", 12.0)):
				p = ab.unit.global_position + ahead.normalized() * 11.0
			if _try(ab, &"scrying_rune", p, "rune_ahead"):
				_rune_at = now
				return true
	return false


func _deacon(c: Unit, ab: CasterAbility, group: Array[Unit], centre: Vector3, _now: float) -> bool:
	if difficulty < 1 or ab.cooldown_left(&"umbral_passage") > 0.0 or ab.mana < ab.mana_cost(&"umbral_passage"):
		return false
	var passage_range := float(CasterKit.spell_value(&"umbral_passage", "range", 45.0))
	# Retreat Passage (normal, hard): a retreating group whose centre is >= 25 m from this Deacon.
	if bool(commander.call(&"is_retreating")) and group.size() >= 2:
		var d := _flat(centre, c.global_position)
		if d >= PASSAGE_RETREAT_DIST and d <= passage_range:
			var dense := _densest(group)
			if _try(ab, &"umbral_passage", dense, "retreat_passage"):
				return true
	# Home Passage (hard): the base is attacked while the group is >= 35 m from home; the anchor (at home) calls it.
	if difficulty >= 2 and bool(commander.call(&"defending")) and bool(commander.call(&"group_out")) and group.size() >= 2 \
			and (anchor == null or c == anchor):
		var home := _home_spot()
		if _flat(centre, home) >= PASSAGE_HOME_DIST and _flat(c.global_position, home) <= 12.0 \
				and _flat(centre, c.global_position) <= passage_range:
			if _try(ab, &"umbral_passage", centre, "home_passage"):
				return true
	return false


# The group member with the most other members within 4 m (the Passage pick radius).
func _densest(group: Array[Unit]) -> Vector3:
	var best := group[0].global_position
	var best_n := -1
	var r := float(CasterKit.spell_value(&"umbral_passage", "radius", 4.0))
	for u in group:
		var n := 0
		for o in group:
			if _flat(o.global_position, u.global_position) <= r:
				n += 1
		if n > best_n:
			best_n = n
			best = u.global_position
	return Vector3(best.x, 0.0, best.z)


# ---------------------------------------------------------------- target preference (8.2)

# Bot soldiers near a visible enemy caster hit it first (after an enemy wizard under 30 % HP); hard: fast units dive
# the casters when 2+ are seen.
func _prefer_casters(enemy_casters: Array[Unit]) -> void:
	var soldiers := _valid(commander.call(&"own_soldiers"))
	for u in soldiers:
		u.prefer_casters = true   # their own auto-aggro picks an enemy caster in reach first (Unit._find_nearest_enemy)
	if enemy_casters.is_empty():
		return
	var now := CasterKit.now_s()
	var dive := difficulty >= 2 and enemy_casters.size() >= 2
	for u in soldiers:
		if u.is_holding():
			continue
		var cur := u.attack_target as Unit
		if cur != null and is_instance_valid(cur) and cur.is_alive():
			if CasterKit.is_caster_unit(cur):
				continue
			if (cur is Wizard or cur.is_in_group(&"heroes") or cur.is_in_group(&"enemy_heroes")) \
					and cur.hp < cur.max_hp * WIZARD_FOCUS_HP:
				continue   # an enemy wizard under 30 %: that one first
		if u.has_move_order():
			if not (dive and u.unit_type and is_fast(u.unit_type)):
				continue   # walking on a plain order (a retreat): never pulled into a fight
		var reach := u.aggro_range + PREFER_EXTRA
		if dive and u.unit_type and is_fast(u.unit_type):
			reach = maxf(reach, DIVE_RADIUS)
		var best: Unit = null
		var bd := reach
		for e in enemy_casters:
			if not is_instance_valid(e) or not e.is_alive():
				continue
			var d := _flat(e.global_position, u.global_position)
			if d <= bd:
				bd = d
				best = e
		if best == null:
			continue
		if dive and u.unit_type and is_fast(u.unit_type):
			var key := u.get_instance_id()
			if now - float(_dive_at.get(key, -INF)) >= DIVE_EVERY:
				_dive_at[key] = now
				u.command_attack(best)
		elif u.attack_target != null or u.is_attack_moving() or not u.has_move_order():
			u.attack_target = best   # keeps its attack-move: back on the way once the caster falls


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
