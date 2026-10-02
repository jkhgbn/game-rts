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
##   Fights: a Kilnwarden, Bramblesage or Gloom Deacon with mana for a spell joins the nearest fight (an enemy within
##   12 m of an own soldier or the wizard, within 45 m of the caster) at 6-8 m from the enemy clump on its army's side,
##   2.5 m apart, so its spells find targets in range; 4 s after a flee at the earliest. The Rimecarver stays behind.
##   Fights and fight casts count neutral creatures within 20 m too (the army creeps camps).
##   A flee whose straight run would cross a Rime Bulwark or end in a building turns (up to 180 deg) until it does not.
##   Strength: AIMemory.strength_of counts a caster cost x 0.5 (x 1.0 with mana >= twice its cheapest spell).
##   Target preference: every bot soldier fighting near a visible enemy caster switches to it (unless it hits an
##   enemy wizard under 30 % HP); hard: fast units (cavalry, hounds, Scorchlings, Thistle Darters) dive the enemy
##   casters when 2+ are seen. Counter-mix: 2+ enemy casters seen -> fast units +0.05 of the training mix.
## 8.3 Casting: every spell autocasts for bots (CasterAbility.bot_controlled, reaction easy 1.5 s / normal 0.5 / hard
##   0.25; hard waits for an enemy caster's cast before Mana Scald and holds Pollen Haze for 5 ranged units early in a
##   fight), plus: Rimecarver a) dive guard (normal, hard), b) retreat cover (hard), c) runes every 30 s ahead of an
##   attacking group and on a unit hit from the fog (hard); max one Bulwark per 3 s per team. Gloom Deacon: retreat
##   Passage (normal, hard: a retreating group >= 25 m away), home Passage (hard: the base attacked while the group is
##   >= 35 m from home, cast by the anchor at home). Fight casts (the autocast rules wait for targets bot fights
##   rarely offer), only on enemies an own soldier or the own wizard fights (within 12 m): Kilnwarden Mana Scald on
##   the enemy wizard from 25 mana ("fight_scald"), Slag Rain on 3+ enemies in 3 m or a hero / champion ("fight_slag");
##   Bramblesage Pollen Haze on 3+ ranged enemies in 3.5 m ("fight_haze"), Snagroot on a hero / champion or a
##   ranged unit 4.5-9 m away into 2+ own fighters (a hero: 3+), a melee unit from 175 mana with 3+ ("fight_snag").
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
const FLEE_REJOIN := 4.0   ## after a flee, the caster rejoins a fight (_fight_spot) only this much later
const ENEMY_NEAR := 30.0
const BULWARK_TEAM_EVERY := 3.0
const RETREAT_CHASE := 8.0
const RUNE_EVERY := 30.0
const RUNE_AHEAD := 10.0
const RUNE_BLIND_RADIUS := 12.0
const PASSAGE_RETREAT_DIST := 25.0
const PASSAGE_HOME_DIST := 35.0
## Joining fights (8.2 + 8.3: a caster "follows" its army, but the autocast rules need enemies in spell range): an
## enemy within FIGHT_RADIUS of an own soldier or the own wizard is a fight; a caster of STANDOFF with mana for a
## spell and a fight within FIGHT_JOIN of it walks to STANDOFF m from the enemy clump, on its own army's side (behind
## the front line, inside its 9-10 m spell ranges; Blood Tithe: within 7 m of the allies in melee), FIGHT_SPREAD m
## from the next caster. The anchor Deacon joins only fights within HOME_FIGHT of home. Retreats and fleeing come
## first.
const FIGHT_RADIUS := 12.0
const FIGHT_JOIN := 45.0
const FOE_CLUMP := 8.0
const HOME_FIGHT := 25.0
const FIGHT_SPREAD := 2.5
const CREEP_NEAR := 20.0
const STANDOFF := {&"kilnwarden": 7.5, &"bramblesage": 8.0, &"gloom_deacon": 6.0}
## Fight casts (_kilnwarden_fight / _bramblesage_fight): Slag Rain on 3+ enemies in 3 m (a hero / champion / helper
## alone counts 3), Pollen Haze on 3+ ranged enemies in 3.5 m, Snagroot on a hero / champion / helper or a ranged unit
## at least 4.5 m away (a melee unit too from 175 mana with 3+ own fighters near).
const FIGHT_SLAG_MIN := 3
const FIGHT_HAZE_MIN := 3
const FIGHT_SNAG_MIN := 4.5
const FIGHT_SNAG_ANY_MANA := 175.0   ## from this much mana (and 3+ own fighters near) Snagroot also pulls melee units
const FIGHT_SCALD_WIZARD := 25.0   ## Mana Scald on the enemy wizard from this much mana (autocast: 40)
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
## saving_for_caster(): seconds of saving at a time (45 like the tier upgrade's TierSystem.BOT_SAVE_WINDOW; 25 s was too
## short: a Fire bot hovered at 45-245 of the 250 crystals for 7 minutes and never trained its caster, 2026-10-02)...
const SAVE_FOR := 45.0
const SAVE_PAUSE := 30.0     ## ...then this many seconds of normal spending

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
## Why the last try_train() call queued nothing ("" = it queued one, or it was not called yet), for logs / tests.
var train_block := ""
## Rule -> casts (dive_guard, retreat_cover, rune_ahead, rune_blind, retreat_passage, home_passage, autocast).
var casts_by_rule := {}

var _tick_left := 0.0
var _flee_at := {}            # caster instance id -> time of its last flee
var _orders := {}             # caster instance id -> [pos, time]
var _dive_at := {}            # soldier instance id -> time of its last dive order
var _bulwark_at := -INF
var _rune_at := -INF
var _adopted := {}            # caster instance id -> true
var _save_since := -INF       # start of the current first-caster saving window
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

## Queues one caster at the keep when the 8.1 rules allow it. `priority` = the call from rule 5 before any Hall unit:
## the hard bot's, and the normal bot's while its first caster is due (none alive or queued; else its crystals never
## reach 150 + 100 and it never fields one). True = queued now.
func try_train(priority: bool) -> bool:
	if not CasterKit.enabled_here() or commander == null or difficulty <= 0:
		return false
	if priority and difficulty < 2 and not first_caster_due():
		return false
	var tier := TierSystem.tier_of(team)
	if tier < 2:
		train_block = "tier %d" % tier
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
		train_block = "have %d / %d (want %d, cap %d of soldier pop %d)" % [have, allowed, want, cap, soldier_pop]
		return false
	var eco := Economy.for_team(team)
	if eco == null or eco.crystals < type.cost + CasterKit.BOT_RESERVE:
		train_block = "crystals %d < %d" % [eco.crystals if eco else 0, type.cost + CasterKit.BOT_RESERVE]
		return false
	var keep := _training_keep()
	if keep == null or keep.queue.size() >= 2:
		train_block = "no keep" if keep == null else "keep queue full"
		return false
	for t in keep.queue:
		if t and t.is_worker:
			train_block = "a worker in the keep queue"
			return false   # the workers first (the Queen trade-off)
	if commander.has_method(&"can_spend_now") and not bool(commander.call(&"can_spend_now", type.cost)):
		train_block = "a build waits for the crystals"
		return false
	var why := keep.can_queue(type)
	if why == "":
		why = keep.queue_unit(type)
	if why != "":
		train_block = "keep: %s" % why
		return false
	train_block = ""
	trained += 1
	if commander.has_method(&"note_log"):
		commander.call(&"note_log", "CASTER TRAIN %s (%d / %d, soldier pop %d, crystals left %d)" % [type.display_name,
				have + 1, allowed, soldier_pop, eco.crystals])
	return true


## True while the bot (normal, hard) is at tier >= 2 with no caster alive or queued.
func first_caster_due() -> bool:
	if not CasterKit.enabled_here() or commander == null or difficulty <= 0 or TierSystem.tier_of(team) < 2:
		return false
	var type := UnitType.find(String(CasterKit.caster_for(commander.get(&"faction"))))
	return type != null and T3Kit.count_alive(team, type.id, true) == 0


## Normal bot: rule 5 keeps its crystals (no Hall unit, upgrade or Stables step) while the first caster is due, the
## army is big enough for one (10 % cap) and the crystals are under 150 + 100: at tier 2 a few seconds of income. At
## most SAVE_FOR s at a time, then SAVE_PAUSE s of normal spending (never a stall). Never blocks workers or a due
## champion hire (the Commander asks after it).
func saving_for_caster() -> bool:
	if difficulty != 1 or not first_caster_due():   # hard: its 8.1 priority call is enough (it saves elsewhere)
		_save_since = -INF
		return false
	var type := UnitType.find(String(CasterKit.caster_for(commander.get(&"faction"))))
	var eco := Economy.for_team(team)
	if eco == null or eco.crystals >= type.cost + CasterKit.BOT_RESERVE:
		return false
	if _training_keep() == null or _valid(commander.call(&"own_soldiers")).is_empty():
		return false
	if commander.has_method(&"build_waiting") and bool(commander.call(&"build_waiting")):
		return false   # a waiting build keeps its crystals first
	var now := CasterKit.now_s()
	if now - _save_since >= SAVE_FOR + SAVE_PAUSE:
		_save_since = now   # a new saving window
	return now - _save_since < SAVE_FOR


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
		var spot: Variant = null
		if now - float(_flee_at.get(c.get_instance_id(), -INF)) >= FLEE_REJOIN:   # just fled: no walk back for a while
			spot = _fight_spot(c, ab, _with_creeps(c, enemies))
		if spot != null:
			_move(c, spot, now)   # join the fight at spell range (its autocast picks the targets)
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


# A fight to join: the stand spot (Vector3), or null (no fight near, no mana for any spell, retreating).
func _fight_spot(c: Unit, ab: CasterAbility, enemies: Array[Unit]) -> Variant:
	if enemies.is_empty() or bool(commander.call(&"is_retreating")) or not STANDOFF.has(c.unit_type.id if c.unit_type else &""):
		return null   # the Rimecarver keeps its 8.2 place: its dive guard reaches 19 m, it zones from behind
	var cheapest := INF
	for sid in ab.spell_ids():
		cheapest = minf(cheapest, ab.mana_cost(sid))
	if ab.mana + 0.001 < cheapest:
		return null   # nothing to cast: it stays behind the army (8.2)
	var soldiers := _fighters()
	if soldiers.is_empty():
		return null
	var best: Unit = null
	var bd := FIGHT_JOIN
	for e in enemies:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var d := _flat(e.global_position, c.global_position)
		if d >= bd:
			continue
		for s in soldiers:
			if _flat(s.global_position, e.global_position) <= FIGHT_RADIUS:
				bd = d
				best = e
				break
	if best == null:
		return null
	if c == anchor and _flat(best.global_position, _home_spot()) > HOME_FIGHT:
		return null
	var foe := Vector3.ZERO
	var nf := 0
	for e in enemies:
		if is_instance_valid(e) and e.is_alive() and _flat(e.global_position, best.global_position) <= FOE_CLUMP:
			foe += e.global_position
			nf += 1
	foe /= float(maxi(nf, 1))
	var own := Vector3.ZERO
	var no := 0
	for s in soldiers:
		if _flat(s.global_position, foe) <= FIGHT_RADIUS + 4.0:
			own += s.global_position
			no += 1
	var side := (own / float(no) - foe) if no > 0 else (c.global_position - foe)
	side.y = 0.0
	if side.length() < 0.5:
		side = c.global_position - foe
		side.y = 0.0
	side = side.normalized() if side.length() > 0.05 else Vector3.FORWARD
	var spot := foe + side * float(STANDOFF.get(c.unit_type.id if c.unit_type else &"", 7.0))
	# Casters spread 2.5 m apart across the line (never one clump the enemy can dive, and room to flee).
	spot += side.cross(Vector3.UP).normalized() * (float(c.get_instance_id() % 3) - 1.0) * FIGHT_SPREAD
	spot.y = 0.0
	var ally := ab.tithe_target()
	if ally != null and _flat(ally.global_position, spot) > 6.0:
		var to := spot - ally.global_position
		to.y = 0.0
		spot = ally.global_position + to.normalized() * 5.0   # a tether in progress: stay within 7 m of the ally
		spot.y = 0.0
	return spot


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
		var blend := (away + rear * 0.5).normalized()
		# ...unless that run ends barely farther from the melee threat (it would brush past it): straight away then.
		if threat == null or _flat(c.global_position + blend * FLEE_DIST, threat.global_position) \
				>= _flat(c.global_position, threat.global_position) + FLEE_DIST * 0.6:
			away = blend
	var tower := _nearest_own_tower(c.global_position, 14.0)
	var goal := _clear_flee_goal(c, away, threat)
	if tower:
		var at_tower := tower.global_position + (c.global_position - tower.global_position).normalized() \
				* (Unit.radius_of(tower) + 1.5)
		# The tower only when running to it takes the caster away from the melee threat (never past it).
		if threat == null or (_flat(at_tower, threat.global_position) >= _flat(c.global_position, threat.global_position) + 2.0
				and Vector2(threat.global_position.x, threat.global_position.z).distance_to(
					Geometry2D.get_closest_point_to_segment(Vector2(threat.global_position.x, threat.global_position.z),
					Vector2(c.global_position.x, c.global_position.z), Vector2(at_tower.x, at_tower.z))) >= 2.0):
			goal = at_tower
	_flee_at[key] = now
	var ab := CasterKit.ability_of(c)
	if ab and ab.tithe_target() != null:
		ab.stop_channel()
	_move(c, goal, now, true)
	return true


# The flee goal: FLEE_DIST m along `away`, else, when that run crosses a Rime Bulwark (walls of both teams block the
# caster) or ends in a building / off the map, the turn of it (30-180 deg either side) that ends farthest from the
# melee threat (a caster pinned against a wall or a keep still gets out).
func _clear_flee_goal(c: Unit, away: Vector3, threat: Unit) -> Vector3:
	var from := c.global_position
	var walls: Array = CasterKit.bulwarks_of(0) + CasterKit.bulwarks_of(1)
	var map := c.get_world_3d().navigation_map if c.is_inside_tree() else RID()
	var nav := map.is_valid() and NavigationServer3D.map_get_iteration_id(map) > 0
	var first := from + away * FLEE_DIST
	var best := first
	var best_score := -INF
	for deg: float in [0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0, 120.0, -120.0, 150.0, -150.0, 180.0]:
		var goal := from + away.rotated(Vector3.UP, deg_to_rad(deg)) * FLEE_DIST
		if nav and _flat(NavigationServer3D.map_get_closest_point(map, goal), goal) > 1.5:
			continue   # a building or the map edge there
		var blocked := false
		for w: Variant in walls:
			var wall := w as Node3D
			if wall == null:
				continue
			var half := wall.global_transform.basis.x.normalized() * (float(wall.get(&"length")) * 0.5 + 0.5)
			if _segments_close(from, goal, wall.global_position - half, wall.global_position + half,
					float(wall.get(&"thickness")) * 0.5 + 0.6):
				blocked = true
				break
		if blocked:
			continue
		if deg == 0.0:
			return goal
		var score := -absf(deg) * 0.01
		if threat != null and is_instance_valid(threat):
			score += _flat(goal, threat.global_position)
		if score > best_score:
			best_score = score
			best = goal
	return best


# True when the flat segments a-b and c-d come within `r` of each other (or cross).
static func _segments_close(a: Vector3, b: Vector3, c: Vector3, d: Vector3, r: float) -> bool:
	var p := Vector2(a.x, a.z)
	var q := Vector2(b.x, b.z)
	var m := Vector2(c.x, c.z)
	var n := Vector2(d.x, d.z)
	if Geometry2D.segment_intersects_segment(p, q, m, n) != null:
		return true
	for pt: Vector2 in [p, q]:
		if pt.distance_to(Geometry2D.get_closest_point_to_segment(pt, m, n)) <= r:
			return true
	for pt: Vector2 in [m, n]:
		if pt.distance_to(Geometry2D.get_closest_point_to_segment(pt, p, q)) <= r:
			return true
	return false


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
		&"kilnwarden":
			return _kilnwarden_fight(c, ab, _with_creeps(c, enemies))
		&"bramblesage":
			return _bramblesage_fight(c, ab, _with_creeps(c, enemies))
	return false


# Fight rules for the damage / control casters (the section-5 autocast waits for ideal targets that a bot fight rarely
# offers: 4 units in 3 m, an enemy caster or siege, 4 archers in 3.5 m). Only while an own soldier fights within 12 m
# of the target (never a lone skirmish), after the autocast had its chance (it runs on its own, faster, tick).
func _kilnwarden_fight(c: Unit, ab: CasterAbility, enemies: Array[Unit]) -> bool:
	var soldiers := _fighters()
	# Mana Scald on the enemy wizard in range from 25 mana (the autocast waits for 40).
	if ab.cooldown_left(&"mana_scald") <= 0.0 and ab.mana + 0.001 >= ab.mana_cost(&"mana_scald"):
		var srng := float(CasterKit.spell_value(&"mana_scald", "range", 9.0))
		for e in enemies:
			if is_instance_valid(e) and e.is_alive() and e is Wizard and (e as Wizard).mana >= FIGHT_SCALD_WIZARD \
					and ab.distance_to_target(e) <= srng and ab.target_reason(&"mana_scald", e) == "" \
					and _try(ab, &"mana_scald", e, "fight_scald"):
				return true
	if ab.cooldown_left(&"slag_rain") > 0.0 or ab.mana + 0.001 < ab.mana_cost(&"slag_rain"):
		return false
	var s := CasterKit.spell(&"slag_rain")
	var r := float(s["radius"])
	var rng := float(s["range"])
	var best: Variant = null
	var best_n := FIGHT_SLAG_MIN - 1
	for e in enemies:
		if not is_instance_valid(e) or not e.is_alive() or _flat(e.global_position, c.global_position) > rng:
			continue
		if not _engaged(e, soldiers):
			continue
		var n := 0
		var slagged := 0
		for o in enemies:
			if is_instance_valid(o) and o.is_alive() and _flat(o.global_position, e.global_position) <= r:
				n += FIGHT_SLAG_MIN if CasterKit.is_big_target(o) else 1   # a wizard / champion / helper alone is worth it
				if o.status_time_left(&"slagged") > 4.0:
					slagged += 1
		if n > best_n and slagged * 2 < n:
			best_n = n
			best = Vector3(e.global_position.x, 0.0, e.global_position.z)
	return best != null and _try(ab, &"slag_rain", best, "fight_slag")


func _bramblesage_fight(c: Unit, ab: CasterAbility, enemies: Array[Unit]) -> bool:
	var soldiers := _fighters()
	# Pollen Haze on 3+ ranged ground enemies within 3.5 m of a point in range.
	if ab.cooldown_left(&"pollen_haze") <= 0.0 and ab.mana + 0.001 >= ab.mana_cost(&"pollen_haze"):
		var hs := CasterKit.spell(&"pollen_haze")
		var hr := float(hs["radius"])
		var ranged: Array[Unit] = []
		for e in enemies:
			if is_instance_valid(e) and e.is_alive() and e.attack_range > 3.0 and not e.has_status(&"hazed") \
					and not (e.unit_type and HelperAbilities.FLYER_IDS.has(e.unit_type.id)) \
					and _flat(e.global_position, c.global_position) <= float(hs["range"]) + hr:
				ranged.append(e)
		var best: Variant = null
		var best_n := FIGHT_HAZE_MIN - 1
		for e in ranged:
			if _flat(e.global_position, c.global_position) > float(hs["range"]) or not _engaged(e, soldiers):
				continue
			var n := 0
			for o in ranged:
				if _flat(o.global_position, e.global_position) <= hr:
					n += 1
			if n > best_n and not _own_haze_covers(e.global_position):
				best_n = n
				best = Vector3(e.global_position.x, 0.0, e.global_position.z)
		if best != null and _try(ab, &"pollen_haze", best, "fight_haze"):
			return true
	# Snagroot: pull the enemy wizard, else a ranged unit, 5-9 m away into 2+ own soldiers around the Bramblesage.
	if ab.cooldown_left(&"snagroot") > 0.0 or ab.mana + 0.001 < ab.mana_cost(&"snagroot"):
		return false
	var near := 0
	for u in soldiers:
		if _flat(u.global_position, c.global_position) <= 6.0:
			near += 1
	if near < 2:
		return false
	var rng := float(CasterKit.spell_value(&"snagroot", "range", 9.0))
	var pick: Unit = null
	var pick_score := -INF
	for e in enemies:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var d := ab.distance_to_target(e)
		if d > rng or _flat(e.global_position, c.global_position) < FIGHT_SNAG_MIN or ab.target_reason(&"snagroot", e) != "":
			continue
		var score := -1.0
		if CasterKit.is_big_target(e):
			if near < 3:
				continue   # a hero lands 2 m from the Bramblesage: only into 3+ own fighters (5.3)
			score = 100.0   # the enemy wizard, a champion or a helper into our army
		elif e.attack_range > 3.0:
			score = e.attack_range
		elif ab.mana >= FIGHT_SNAG_ANY_MANA and near >= 3:
			score = 0.5   # mana to spare: tear a melee unit out of its line
		if score > pick_score and score > 0.0:
			pick_score = score
			pick = e
	return pick != null and _try(ab, &"snagroot", pick, "fight_snag")


# The seen enemies plus the neutral creatures (camps, beasts) within CREEP_NEAR m of the caster: the army creeps
# them, and the casters help (the Commander's scan lists only the enemy team).
func _with_creeps(c: Unit, enemies: Array[Unit]) -> Array[Unit]:
	var out := enemies.duplicate()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == Unit.Team.NEUTRAL and u.is_alive() and _flat(u.global_position, c.global_position) <= CREEP_NEAR:
			out.append(u)
	return out


# The own units whose fights the casters join: the soldiers and the wizard.
func _fighters() -> Array[Unit]:
	var out := _valid(commander.call(&"own_soldiers"))
	if commander.has_method(&"own_wizard"):
		var w: Variant = commander.call(&"own_wizard")
		if w is Unit and is_instance_valid(w) and (w as Unit).is_alive():
			out.append(w)
	return out


# An own fighter (soldier, wizard) within FIGHT_RADIUS of `e`.
static func _engaged(e: Unit, soldiers: Array[Unit]) -> bool:
	for s in soldiers:
		if _flat(s.global_position, e.global_position) <= FIGHT_RADIUS:
			return true
	return false


func _own_haze_covers(p: Vector3) -> bool:
	for h in get_tree().get_nodes_in_group(&"pollen_hazes"):
		var hz := h as CasterHaze
		if hz and hz.team == team and hz.time_left() > 1.0 and hz.covers(p):
			return true
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
