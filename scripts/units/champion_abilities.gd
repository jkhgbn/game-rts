class_name ChampionAbilities
extends Node
## The autocast abilities of a champion (docs/design/champions.md 4.3, 5, 8.4, 13; task 9.C2).
## A child node named "ChampionAbilities" of a Champion: the champion creates it in _ready (it may call
## setup(self); otherwise _ready takes the parent). The owner is only read through the Champion
## contract (`level`, `champion_type.ability_ids / growth_pct / flee_pct`, `intent`, `intent_target`,
## `team`, `add_purse`) and the Unit API, never through the Champion class.
##
## Numbers: ABILITIES (level 1). Damage, heals and shields x effect_multiplier() =
## (1 + growth_pct x (level - 1)) x (1 + spell_power / 100) (spell power capped at 60): Mending Draught
## heals 50 / 62 / 70 at L1 / L4 / L6. Cooldowns x (1 - cooldown_reduction / 100), capped at 40 %
## (SpellCaster.cooldown_multiplier). An ability with unlock 4 (the third) needs level 4.
##
## cast(id, target) -> String: "" = done at once (champions never walk to cast: the brain moves them),
## else, in this order: "Dead", "Cannot act" (frozen / dazed), "Locked" (not one of its abilities, or
## level too low), "On cooldown", "Invalid target" (wrong kind, not an enemy / ally, out of range).
## Targets: point abilities (Flare Arrow, Soothing Circle) a Vector3 (a Node3D counts as its position);
## Snare Line / Marked for Coin an enemy Unit; Shield Bash / Cutpurse an enemy Unit or building; Mending
## Draught / Lifeline an own Unit (Mending Draught: null = the most hurt ally in range); self abilities
## ignore it. Ranges are measured from the champion's edge to the target's edge.
##
## Autocast: every 0.5 s (staggered per champion) try_autocast() checks the 4.3 triggers in
## AUTOCAST_ORDER and casts the first that fires: at most one cast per check. Enemies it reacts to must
## be visible to its team (FogOfWar; fog off = all visible). After a cast: the model's
## play_cast(ability_id) and ChampionVfx.play(ability_id, champion, target_or_point) (group
## "champion_vfx"), both if present, then signal ability_cast(id). Cutpurse only arms at cast: its
## play_cast (the lunge-stab) and its VFX (coins) come when the empowered hit lands. Targets passed to the
## VFX: the unit for unit abilities (Mending Draught = the healed unit), the point for Flare Arrow /
## Soothing Circle (the circle's centre), the champion itself for self abilities.
##
## Statuses used (Unit.STATUSES): haste, rooted, shroud (existing), taunted, dazed, braced, marked
## (task 9.C1). Taunt passes the caster as the status source (Unit keeps `taunted_by` as the only
## target); Smoke Pouch clears the champion from the targets of enemies within 6 m and calls
## Unit.hide_from_auto_target(3 s). All ability damage names the champion as the attacker.
##
## Classes (docs/design/skills-rework.md 4, task 11.C2). ability_ids() = the 3 archetype ids + the 3
## skills of the champion's class (none before the level-2 choice). The class is read through the
## Champion contract only: `class_id()` if the champion has it, else `champion_class.id`; its skill
## ids / unlock levels come from `champion_class.ability_ids / unlock_levels` when that resource is
## there, else CLASS_SKILLS / CLASS_UNLOCK_LEVELS (the same data: 2 / 3 / 5). A class skill of another
## class, or below its level, is "Locked". Class skill amounts grow like the others (+8 % per level x
## spell power), except Second Wind (20 % of max HP, spell power only). Targets: Lunge, Hobbling
## Javelin, Skewer (the aim), Shield Throw, Arc Bolt an enemy Unit; Crushing Blow an enemy Unit or
## building in melee reach; Starfall a point (a Node3D counts as its position); Riposte, Second Wind,
## Cleave, Whirlwind, Slipstep ignore it (Slipstep is "Invalid target" when no melee enemy is near or
## no explored navmesh spot is free). Crushing Blow puts modifier `ability:crush` (armor -20, 6 s) on a
## Unit through a child node "AbilityCrush" (it outlives the caster; a new blow refreshes it).
## Feedback targets of class skills: Lunge = the struck unit, played BEFORE the dash (the caster is still
## at its start); Slipstep = the destination point, played BEFORE the jump; Skewer = the far end point
## of the line; Starfall = the point (the star lands 1.0 s later); Cleave (like Cutpurse) plays when the
## empowered hit lands, on the unit hit; self skills = the champion. Each damage / heal a class skill
## deals (bounces, counters, splashes, ticks, landings) also emits skill_hit(id, target, amount).

signal ability_cast(id: StringName)
signal cooldown_started(id: StringName, seconds: float)
## A class skill hit `target` for `amount` (before armor): Lunge, the javelin / bolt landing, each Skewer
## victim, each Riposte counter, each Shield Throw bounce, each Cleave splash, Crushing Blow, each
## Whirlwind tick victim, each Starfall victim, each Second Wind tick (a heal). For VFX and tests.
signal skill_hit(id: StringName, target: Node3D, amount: float)

const REASON_DEAD := "Dead"
const REASON_CANNOT_ACT := "Cannot act"
const REASON_LOCKED := "Locked"
const REASON_COOLDOWN := "On cooldown"
const REASON_TARGET := "Invalid target"

enum Target { SELF, POINT, ENEMY_UNIT, ENEMY, ALLY }

## Level-1 numbers (champions.md 4.3). amount = damage / heal / shield / bonus damage (grows with
## level and spell power); duration = status or effect seconds; radius = area; range = cast reach.
const ABILITIES := {
	# Displayed "Signal Flare" since step 11 (skills-rework.md 4.1: thrown from the lantern pole).
	&"flare_arrow": {"name": "Signal Flare", "champion": &"wayfinder", "unlock": 1, "cooldown": 18.0,
			"range": 20.0, "radius": 2.0, "amount": 20.0, "sight_radius": 8.0, "duration": 6.0,
			"target": Target.POINT,
			"text": "Hurls a flare up to 20 m: 20 damage around it, and the spot stays in sight for 6 s."},
	&"snare_line": {"name": "Snare Line", "champion": &"wayfinder", "unlock": 1, "cooldown": 14.0,
			"range": 8.0, "amount": 15.0, "duration": 1.5, "target": Target.ENEMY_UNIT,
			"text": "Snags one enemy within 8 m: 15 damage and rooted for 1.5 s."},
	&"trailblaze": {"name": "Trailblaze", "champion": &"wayfinder", "unlock": 4, "cooldown": 30.0,
			"range": 0.0, "radius": 8.0, "duration": 5.0, "target": Target.SELF,
			"text": "Blazes a trail: itself and allies within 8 m are hasted for 5 s."},
	&"oath_of_iron": {"name": "Oath of Iron", "champion": &"oathwall", "unlock": 1, "cooldown": 16.0,
			"range": 0.0, "radius": 6.0, "duration": 3.0, "armor": 20.0, "target": Target.SELF,
			"text": "Dares every soldier within 6 m to hit it for 3 s, with +20 armor meanwhile."},
	&"shield_bash": {"name": "Shield Bash", "champion": &"oathwall", "unlock": 1, "cooldown": 10.0,
			"range": 2.2, "amount": 30.0, "duration": 0.8, "target": Target.ENEMY,
			"text": "Slams its shield into a foe: 30 damage and dazed for 0.8 s."},
	&"bulwark_stand": {"name": "Bulwark Stand", "champion": &"oathwall", "unlock": 4, "cooldown": 40.0,
			"range": 0.0, "radius": 5.0, "duration": 6.0, "target": Target.SELF,
			"text": "Plants its shield for 6 s: it holds its ground, allies within 5 m take 30 % less damage."},
	&"cutpurse": {"name": "Cutpurse", "champion": &"coin_cutter", "unlock": 1, "cooldown": 8.0,
			"range": 0.0, "amount": 25.0, "loot": 15, "target": Target.ENEMY,
			"text": "Its next strike deals +25 damage; a kill with it pockets 15 essence."},
	&"smoke_pouch": {"name": "Smoke Pouch", "champion": &"coin_cutter", "unlock": 1, "cooldown": 25.0,
			"range": 0.0, "radius": 3.0, "drop_radius": 6.0, "duration": 3.0, "target": Target.SELF,
			"text": "A puff of smoke: shrouded for 3 s, and enemies within 6 m lose track of it."},
	&"marked_for_coin": {"name": "Marked for Coin", "champion": &"coin_cutter", "unlock": 4,
			"cooldown": 20.0, "range": 8.0, "duration": 6.0, "target": Target.ENEMY_UNIT,
			"text": "Marks one enemy within 8 m for 6 s: it takes 15 % more damage from everyone."},
	&"mending_draught": {"name": "Mending Draught", "champion": &"mender", "unlock": 1, "cooldown": 7.0,
			"range": 9.0, "amount": 50.0, "target": Target.ALLY,
			"text": "Throws a draught to the most hurt ally within 9 m: heals 50."},
	&"soothing_circle": {"name": "Soothing Circle", "champion": &"mender", "unlock": 1, "cooldown": 24.0,
			"range": 9.0, "radius": 5.0, "amount": 30.0, "duration": 5.0, "tick": 0.5,
			"target": Target.POINT,
			"text": "A calming ring 5 m wide heals every ally inside by 30 over 5 s."},
	&"lifeline": {"name": "Lifeline", "champion": &"mender", "unlock": 4, "cooldown": 35.0,
			"range": 9.0, "amount": 100.0, "duration": 5.0, "target": Target.ALLY,
			"text": "Wraps an ally within 9 m in a 100-point shield for 5 s."},
	# ---- Class skills (skills-rework.md 4.2). "class" = the class that owns it, "unlock" = its level.
	&"lunge": {"name": "Lunge", "class": &"spear", "unlock": 2, "cooldown": 14.0, "range": 6.0,
			"amount": 25.0, "duration": 0.5, "target": Target.ENEMY_UNIT,
			"text": "Darts to a foe within 6 m and strikes: 25 damage and dazed for 0.5 s."},
	&"hobbling_javelin": {"name": "Hobbling Javelin", "class": &"spear", "unlock": 3, "cooldown": 16.0,
			"range": 10.0, "amount": 25.0, "duration": 3.0, "speed": 24.0, "target": Target.ENEMY_UNIT,
			"text": "Throws a javelin at a foe within 10 m: 25 damage and hobbled (-1.5 speed) for 3 s."},
	&"skewer": {"name": "Skewer", "class": &"spear", "unlock": 5, "cooldown": 25.0, "range": 5.0,
			"width": 1.0, "amount": 40.0, "target": Target.ENEMY_UNIT,
			"text": "A long thrust through a 5 m line: 40 damage to every enemy in it."},
	&"riposte": {"name": "Riposte", "class": &"sword_shield", "unlock": 2, "cooldown": 22.0, "range": 0.0,
			"amount": 10.0, "duration": 4.0, "melee_range": 3.0, "target": Target.SELF,
			"text": "For 4 s, melee attackers take 10 damage per hit."},
	&"second_wind": {"name": "Second Wind", "class": &"sword_shield", "unlock": 3, "cooldown": 45.0,
			"range": 0.0, "heal_pct": 0.20, "duration": 4.0, "tick": 0.5, "target": Target.SELF,
			"text": "Heals itself 20 % of its max HP over 4 s."},
	&"shield_throw": {"name": "Shield Throw", "class": &"sword_shield", "unlock": 5, "cooldown": 20.0,
			"range": 8.0, "amount": 30.0, "bounces": [20.0, 10.0], "bounce_radius": 4.0,
			"target": Target.ENEMY_UNIT,
			"text": "Throws its shield at a foe within 8 m: 30 damage, then it bounces to 2 more foes (20, then 10)."},
	&"cleave": {"name": "Cleave", "class": &"two_hand", "unlock": 2, "cooldown": 10.0, "range": 0.0,
			"radius": 2.5, "duration": 3.0, "target": Target.SELF,
			"text": "Its next attack also hits every other enemy within 2.5 m of the target for full damage."},
	&"crushing_blow": {"name": "Crushing Blow", "class": &"two_hand", "unlock": 3, "cooldown": 20.0,
			"range": 0.0, "amount": 30.0, "armor": -20.0, "duration": 6.0, "target": Target.ENEMY,
			"text": "A two-hand chop: 30 damage, and the foe loses 20 armor for 6 s."},
	&"whirlwind": {"name": "Whirlwind", "class": &"two_hand", "unlock": 5, "cooldown": 30.0, "range": 0.0,
			"radius": 3.0, "amount": 12.0, "duration": 2.0, "tick": 0.5, "target": Target.SELF,
			"text": "Spins for 2 s: 12 damage every 0.5 s to every enemy within 3 m."},
	&"arc_bolt": {"name": "Arc Bolt", "class": &"wizard", "unlock": 2, "cooldown": 10.0, "range": 12.0,
			"amount": 40.0, "speed": 28.0, "target": Target.ENEMY_UNIT,
			"text": "A bolt at a foe within 12 m: 40 damage."},
	&"slipstep": {"name": "Slipstep", "class": &"wizard", "unlock": 3, "cooldown": 22.0, "range": 8.0,
			"target": Target.SELF,
			"text": "Teleports up to 8 m away from the nearest melee enemy."},
	&"starfall": {"name": "Starfall", "class": &"wizard", "unlock": 5, "cooldown": 35.0, "range": 12.0,
			"radius": 3.5, "amount": 45.0, "delay": 1.0, "target": Target.POINT,
			"text": "A star falls on a spot within 12 m after 1 s: 45 damage to every enemy within 3.5 m."},
}

## The 3 skills of each class in unlock order (ChampionClass.ability_ids wins when present).
const CLASS_SKILLS := {
	&"spear": [&"lunge", &"hobbling_javelin", &"skewer"],
	&"sword_shield": [&"riposte", &"second_wind", &"shield_throw"],
	&"two_hand": [&"cleave", &"crushing_blow", &"whirlwind"],
	&"wizard": [&"arc_bolt", &"slipstep", &"starfall"],
}
## Levels of class skills 1 / 2 / 3 (ChampionClass.unlock_levels wins when present).
const CLASS_UNLOCK_LEVELS: Array[int] = [2, 3, 5]

## Which trigger is checked first (one cast per check), skills-rework.md 4.3: escapes, then saves, then
## control, then area damage, then single damage, then heals, then utility. Each champion owns 6 at most.
const AUTOCAST_ORDER: Array[StringName] = [&"smoke_pouch", &"slipstep", &"snare_line", &"trailblaze",
		&"lifeline", &"second_wind", &"bulwark_stand", &"oath_of_iron", &"riposte", &"shield_bash",
		&"hobbling_javelin", &"crushing_blow", &"whirlwind", &"starfall", &"skewer", &"marked_for_coin",
		&"lunge", &"cleave", &"shield_throw", &"arc_bolt", &"cutpurse", &"soothing_circle",
		&"mending_draught", &"flare_arrow"]

const AUTOCAST_INTERVAL := 0.5
const DEFAULT_GROWTH := 0.08
const DEFAULT_FLEE := 0.35
const MAX_LEVEL := 6
const MAX_SPELL_POWER := 60.0
const OATH_MODIFIER := &"ability:oath"
const SIGHT_MARKER_PATH := "res://scripts/world/sight_marker.gd"
const SCAN_RANGE := 20.0          # enemies the triggers look at (Flare Arrow's reach)
const ALLY_SCAN_RANGE := 14.0     # Soothing Circle: 9 m cast + 5 m radius
const MELEE_SLACK := 0.3          # Cutpurse reach on top of the champion's own attack reach
const BRACE_REFRESH := 0.5
# Trigger thresholds (4.3).
const FLARE_MIN := 14.0
const FLARE_MAX := 20.0
const FLARE_ANGLES: Array[float] = [0.0, -0.45, 0.45]
const FLARE_DISTANCES: Array[float] = [20.0, 17.0, 14.0]
const TRAILBLAZE_FAR := 25.0
const MOVING_SPEED := 0.5
const OATH_ATTACKERS := 2
const OATH_TARGETERS := 3
const BULWARK_ENEMIES := 3
const BULWARK_ENEMY_RANGE := 8.0
const BULWARK_HOME_RANGE := 20.0
const CUTPURSE_HP := 0.5
const SMOKE_HP_MARGIN := 0.10
const SMOKE_TARGETERS := 3
const SMOKE_RECENT_HIT := 3.0     # the low-HP clause only fires while it is being hurt
const MEND_HP := 0.70
const CIRCLE_HP := 0.80
const CIRCLE_COUNT := 3
const LIFELINE_HP := 0.35
# Class skills (skills-rework.md 4.2).
const CRUSH_MODIFIER := &"ability:crush"
const CRUSH_NODE := "AbilityCrush"
const MELEE_MAX_RANGE := 3.0      # "melee" = attack_range <= 3 m (Unit: more than 3 m shoots)
const HERO_COST := 1000           # heroes rank above every soldier for "highest cost first"
const LUNGE_MIN := 3.0            # Lunge: preferred foes 3-6 m away (edge to edge)
const LUNGE_HP := 0.40
const LUNGE_TOWER := 11.0         # ... not within 11 m of a known enemy tower / keep
const LUNGE_GAP := 1.0            # lands this far from the target's centre (more if the bodies need it)
const JAVELIN_HP := 0.60
const JAVELIN_COLOR := Color(0.85, 0.75, 0.55)
const SKEWER_MIN := 3
const RIPOSTE_ATTACKERS := 2
const ATTACK_SLACK := 0.5         # "is attacking it": its target and within its reach + this
const SECOND_WIND_HP := 0.50
const SECOND_WIND_RECENT := 2.0
const SHIELD_THROW_MIN := 3.0     # current target 3-8 m away (edge to edge) and out of reach
const CLEAVE_NEIGHBOURS := 2
const CLEAVE_SLACK := 1.0         # the current target is about to be hit: within attack reach + 1 m
const CRUSH_ARMOR := 10.0
const CRUSH_COST := 200
const WHIRL_ENEMIES := 3
const ARC_BOLT_COLOR := Color(0.6, 0.75, 1.0)
const SLIP_HP := 0.70
const SLIP_NEAR := 3.0
const SLIP_FLEE_NEAR := 4.0
const SLIP_MIN := 3.0             # shortest jump tried (straight away first, then +-20 / +-40 degrees)
const SLIP_ANGLES: Array[float] = [0.0, 0.35, -0.35, 0.7, -0.7]
const NAV_SNAP := 1.5             # a navmesh point this far from the wanted spot is accepted
const STARFALL_MIN := 3

## The champion (a Unit). Read only; set by setup() or taken from the parent.
var champion: Unit = null
## False = no automatic casts (a brain or a test drives cast() / try_autocast() itself).
var autocast_enabled := true
## The sight marker of the last Flare Arrow (freed after its lifetime). Read only.
var last_sight_marker: Node3D = null

var _ids_override: Array[StringName] = []
var _cooldown_left: Dictionary = {}    # StringName -> seconds
var _cooldown_total: Dictionary = {}   # StringName -> length of the running cooldown
var _autocast_left := AUTOCAST_INTERVAL
var _agent: NavigationAgent3D = null
# Scan cache (one pass over "units" per check).
var _enemies: Array[Unit] = []         # visible, alive, within SCAN_RANGE
var _allies: Array[Unit] = []          # own team, alive, within ALLY_SCAN_RANGE (itself included)
var _enemy_d := PackedFloat32Array()   # flat centre distance of each _enemies entry (same order)
var _last_seen: Dictionary = {}        # instance id -> [unit, position] (Flare Arrow "left vision")
var _lost_enemy_pos := Vector3.INF
# Running effects.
var _oath_left := 0.0
var _bulwark_left := 0.0
var _brace_left := 0.0
var _cutpurse_armed := false
var _cutpurse_bonus := 0.0
var _riposte_left := 0.0
var _cleave_left := 0.0
var _whirl_left := 0.0
var _whirl_ticks := 0
var _whirl_next := 0.0
var _whirl_amount := 0.0
# True while a Riposte counter hits: another Riposte never answers a counter (no ping-pong).
static var _countering := false


## Optional: `ids` overrides champion_type.ability_ids (tests, special units); the class skills are
## still added after them.
func setup(p_champion: Node3D, ids: Array[StringName] = []) -> void:
	if champion and is_instance_valid(champion):
		if champion.attack_landed.is_connected(_on_attack_landed):
			champion.attack_landed.disconnect(_on_attack_landed)
		if champion.damage_taken.is_connected(_on_damage_taken):
			champion.damage_taken.disconnect(_on_damage_taken)
	champion = p_champion as Unit
	_ids_override = ids.duplicate()
	_agent = null
	if champion:
		if not champion.attack_landed.is_connected(_on_attack_landed):
			champion.attack_landed.connect(_on_attack_landed)
		if not champion.damage_taken.is_connected(_on_damage_taken):
			champion.damage_taken.connect(_on_damage_taken)


func _ready() -> void:
	if champion == null:
		setup(get_parent() as Node3D)
	# Stagger the checks (0.05 .. 0.45 s) so several champions don't all check in the same frame.
	_autocast_left = 0.05 + 0.1 * float(absi(get_instance_id()) % 5)


# ---------------------------------------------------------------- public API

## The champion's abilities in slot order: the 3 archetype ids (champion_type.ability_ids), then the 3
## skills of its class in unlock order (none before the class is chosen at level 2).
func ability_ids() -> Array[StringName]:
	var out := archetype_ability_ids()
	for id in class_skill_ids():
		if not out.has(id):
			out.append(id)
	return out


## The 3 archetype abilities (champion_type.ability_ids, or the setup() override).
func archetype_ability_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if not _ids_override.is_empty():
		out.assign(_ids_override)
		return out
	var raw: Variant = _type_value(&"ability_ids")
	if raw is Array or raw is PackedStringArray:
		for v: Variant in raw:
			out.append(StringName(str(v)))
	return out


## The champion's class id (&"spear", &"sword_shield", &"two_hand", &"wizard"), &"" before the choice.
## Read from Champion.class_id(), else Champion.champion_class.id.
func class_id() -> StringName:
	if champion == null or not is_instance_valid(champion):
		return &""
	if champion.has_method(&"class_id"):
		var v: Variant = champion.call(&"class_id")
		return StringName(str(v)) if v != null else &""
	var cc := _class_resource()
	if cc:
		var id: Variant = cc.get(&"id")
		return StringName(str(id)) if id != null else &""
	return &""


## The 3 skills of its class in unlock order ([] before the choice).
func class_skill_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	var cid := class_id()
	if cid == &"":
		return out
	var cc := _class_resource()
	if cc:
		var raw: Variant = cc.get(&"ability_ids")
		if (raw is Array or raw is PackedStringArray) and not raw.is_empty():
			for v: Variant in raw:
				out.append(StringName(str(v)))
			return out
	return class_skills_of(cid)


## The level at which the champion gets `id`: archetype abilities per ch. 4.3 (1 or 4), class skills per
## the class's unlock_levels (2 / 3 / 5).
func unlock_level_for(id: StringName) -> int:
	var cls := skill_class(id)
	if cls == &"":
		return unlock_level(id)
	var cc := _class_resource()
	if cc:
		var ids: Variant = cc.get(&"ability_ids")
		var levels: Variant = cc.get(&"unlock_levels")
		if (ids is Array or ids is PackedStringArray) and (levels is Array or levels is PackedInt32Array):
			var i: int = -1
			for k in ids.size():
				if StringName(str(ids[k])) == id:
					i = k
					break
			if i >= 0 and i < levels.size():
				return int(levels[i])
	return unlock_level(id)


## One of its abilities (archetype or its class) and its level is high enough.
func is_unlocked(id: StringName) -> bool:
	return ABILITIES.has(id) and ability_ids().has(id) and _level() >= unlock_level_for(id)


## How many of its class skills are unlocked now (0-3): Champion.power() adds 20 per skill.
func unlocked_class_skill_count() -> int:
	var n := 0
	var lvl := _level()
	for id in class_skill_ids():
		if ABILITIES.has(id) and lvl >= unlock_level_for(id):
			n += 1
	return n


func cooldown_left(id: StringName) -> float:
	return float(_cooldown_left.get(id, 0.0))


## Length of the running cooldown; when none runs, the cooldown the next cast would get.
func cooldown_total(id: StringName) -> float:
	var running := float(_cooldown_total.get(id, 0.0))
	return running if running > 0.0 and cooldown_left(id) > 0.0 else cooldown_for(id)


## The ability's cooldown after the champion's cooldown_reduction.
func cooldown_for(id: StringName) -> float:
	var base := float(ability_data(id).get("cooldown", 0.0))
	if champion and is_instance_valid(champion):
		base *= SpellCaster.cooldown_multiplier(champion.get_stat(&"cooldown_reduction"))
	return base


## (1 + growth x (level - 1)) x (1 + spell_power / 100): multiplies damage, heals and shields.
func effect_multiplier() -> float:
	if champion == null or not is_instance_valid(champion):
		return 1.0
	var growth := 1.0 + _growth_pct() * float(_level() - 1)
	var sp := clampf(champion.get_stat(&"spell_power"), -100.0, MAX_SPELL_POWER)
	return growth * (1.0 + sp / 100.0)


## The ability's damage / heal / shield / bonus now (level and spell power applied). Second Wind: the
## heal of 20 % of its max HP (spell power applies, no level growth: the max HP already grows).
func amount_of(id: StringName) -> float:
	if id == &"second_wind":
		if champion == null or not is_instance_valid(champion):
			return 0.0
		var sp := clampf(champion.get_stat(&"spell_power"), -100.0, MAX_SPELL_POWER)
		return float(ability_data(id)["heal_pct"]) * champion.max_hp * (1.0 + sp / 100.0)
	return float(ability_data(id).get("amount", 0.0)) * effect_multiplier()


## The reason cast() would give right now, ignoring the target ("" = castable).
func can_cast(id: StringName) -> String:
	if champion == null or not is_instance_valid(champion) or not champion.is_alive():
		return REASON_DEAD
	if not champion.can_act():
		return REASON_CANNOT_ACT
	if not is_unlocked(id):
		return REASON_LOCKED
	if cooldown_left(id) > 0.0:
		return REASON_COOLDOWN
	return ""


## Casts `id` at once. "" = done, else the reason (see the header).
func cast(id: StringName, target: Variant = null) -> String:
	var reason := can_cast(id)
	if reason != "":
		return reason
	var picked := _resolve_target(id, target)
	if picked.is_empty():
		return REASON_TARGET
	_execute(id, picked[0])
	return ""


## One autocast check (the node runs it every 0.5 s while autocast_enabled): the first ability of
## AUTOCAST_ORDER whose trigger fires is cast. Returns its id, or &"" when nothing was cast.
func try_autocast() -> StringName:
	if champion == null or not is_instance_valid(champion) or not champion.is_alive() \
			or not champion.can_act():
		_last_seen.clear()
		return &""
	var ids := ability_ids()
	if ids.is_empty():
		return &""
	_scan(ids.has(&"flare_arrow"))
	for id in AUTOCAST_ORDER:
		if not ids.has(id) or can_cast(id) != "":
			continue
		var picked := _trigger(id)
		if picked.is_empty():
			continue
		if cast(id, picked[0]) == "":
			return id
	return &""


## Revive (champions.md 3.3): every cooldown ready, running effects of the last life dropped.
func reset_cooldowns() -> void:
	for id: StringName in _cooldown_left.keys():
		_cooldown_left[id] = 0.0
	_cooldown_total.clear()
	_cutpurse_armed = false
	_cutpurse_bonus = 0.0
	_bulwark_left = 0.0
	_riposte_left = 0.0
	_cleave_left = 0.0
	_whirl_left = 0.0
	_whirl_ticks = 0
	_last_seen.clear()
	if _oath_left > 0.0:
		_oath_left = 0.0
		if champion and is_instance_valid(champion):
			champion.remove_modifier(OATH_MODIFIER)


## Same as reset_cooldowns() (the SpellCaster name).
func reset() -> void:
	reset_cooldowns()


## True while Cutpurse waits for the next attack.
func is_cutpurse_armed() -> bool:
	return _cutpurse_armed


## Seconds left of Bulwark Stand (0 = not planted).
func bulwark_time_left() -> float:
	return maxf(0.0, _bulwark_left)


## Seconds left of Riposte (0 = not active).
func riposte_time_left() -> float:
	return maxf(0.0, _riposte_left)


## True while Cleave waits for the next attack (at most 3 s).
func is_cleave_armed() -> bool:
	return _cleave_left > 0.0


## Seconds left of the Whirlwind spin (0 = not spinning).
func whirlwind_time_left() -> float:
	return maxf(0.0, _whirl_left)


static func ability_data(id: StringName) -> Dictionary:
	return ABILITIES.get(id, {})


## The level in ABILITIES (archetype 1 / 4, class skills 2 / 3 / 5). For a champion, unlock_level_for().
static func unlock_level(id: StringName) -> int:
	return int(ability_data(id).get("unlock", 1))


## The class a class skill belongs to (&"" for the 12 archetype abilities and unknown ids).
static func skill_class(id: StringName) -> StringName:
	return StringName(str(ability_data(id).get("class", "")))


static func is_class_skill(id: StringName) -> bool:
	return skill_class(id) != &""


## The 3 skills of class `cid` in unlock order ([] for an unknown class).
static func class_skills_of(cid: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if CLASS_SKILLS.has(cid):
		out.assign(CLASS_SKILLS[cid])
	return out


## Seconds left of the Crushing Blow armor break on `unit` (0 = none).
static func crush_time_left(unit: Node) -> float:
	if unit == null or not is_instance_valid(unit):
		return 0.0
	var mark := unit.get_node_or_null(NodePath(CRUSH_NODE)) as CrushMark
	return mark.left if mark else 0.0


## "Flare Arrow" (UI).
static func ability_name(id: StringName) -> String:
	return str(ability_data(id).get("name", String(id).capitalize()))


## One line for tooltips / the tavern window (level-1 numbers).
static func ability_text(id: StringName) -> String:
	return str(ability_data(id).get("text", ""))


static func range_of(id: StringName) -> float:
	return float(ability_data(id).get("range", 0.0))


# ---------------------------------------------------------------- per frame

func _physics_process(delta: float) -> void:
	for id: StringName in _cooldown_left.keys():
		var left := float(_cooldown_left[id])
		if left > 0.0:
			_cooldown_left[id] = maxf(0.0, left - delta)
	if _oath_left > 0.0:
		_oath_left -= delta
		if _oath_left <= 0.0:
			_oath_left = 0.0
			if champion and is_instance_valid(champion):
				champion.remove_modifier(OATH_MODIFIER)
	if _bulwark_left > 0.0:
		_tick_bulwark(delta)
	if _riposte_left > 0.0:
		_riposte_left = maxf(0.0, _riposte_left - delta)
	if _cleave_left > 0.0:
		_cleave_left = maxf(0.0, _cleave_left - delta)
	if _whirl_left > 0.0 or _whirl_ticks > 0:
		_tick_whirlwind(delta)
	if autocast_enabled and champion != null:
		_autocast_left -= delta
		if _autocast_left <= 0.0:
			_autocast_left += AUTOCAST_INTERVAL
			if _autocast_left <= 0.0:
				_autocast_left = AUTOCAST_INTERVAL
			try_autocast()


func _tick_bulwark(delta: float) -> void:
	if not _alive(champion):
		_bulwark_left = 0.0
		return
	_bulwark_left -= delta
	if _bulwark_left <= 0.0:
		_bulwark_left = 0.0
		return
	_brace_left -= delta
	if _brace_left <= 0.0:
		_brace_left += BRACE_REFRESH
		_brace_allies()


# Whirlwind: the first tick lands at the cast, then one every 0.5 s (4 in the 2 s spin).
func _tick_whirlwind(delta: float) -> void:
	if not _alive(champion):
		_whirl_left = 0.0
		_whirl_ticks = 0
		return
	_whirl_left = maxf(0.0, _whirl_left - delta)
	if _whirl_ticks <= 0:
		return
	_whirl_next -= delta
	if _whirl_next <= 0.0001:
		_whirl_next += float(ability_data(&"whirlwind")["tick"])
		_whirl_ticks -= 1
		_whirlwind_hit()


# ---------------------------------------------------------------- casting

func _resolve_target(id: StringName, target: Variant) -> Array:
	var d := ability_data(id)
	var reach := float(d.get("range", 0.0))
	match int(d.get("target", Target.SELF)):
		Target.SELF:
			if id == &"slipstep":
				var dest := _slipstep_destination()
				return [dest] if dest != Vector3.INF else []
			return [null]
		Target.POINT:
			var pos := Vector3.ZERO
			if target is Vector3:
				pos = target
			elif _is_node(target):
				pos = (target as Node3D).global_position
			else:
				return []
			if _flat_dist(pos, champion.global_position) > reach + 0.01:
				return []
			return [pos]
		Target.ENEMY_UNIT:
			if _is_enemy_unit(target) and _in_reach(target as Node3D, reach):
				return [target]
		Target.ENEMY:
			if id == &"cutpurse" or id == &"crushing_blow":
				reach = _melee_reach()
			if (_is_enemy_unit(target) or _is_enemy_building(target)) and _in_reach(target as Node3D, reach):
				return [target]
		Target.ALLY:
			if target == null and id == &"mending_draught":
				var hurt := _most_hurt_ally(reach, 1.0)
				return [hurt] if hurt else []
			if _is_ally_unit(target) and _in_reach(target as Node3D, reach):
				return [target]
	return []


func _execute(id: StringName, target: Variant) -> void:
	var cd := cooldown_for(id)
	_cooldown_left[id] = cd
	_cooldown_total[id] = cd
	var fx_target: Variant = champion
	var played := id == &"cutpurse"   # Cutpurse plays its feedback when the empowered hit lands
	match id:
		&"flare_arrow":
			_cast_flare_arrow(target)
			fx_target = target
		&"snare_line":
			_cast_snare_line(target as Unit)
			fx_target = target
		&"trailblaze":
			_cast_trailblaze()
		&"oath_of_iron":
			_cast_oath_of_iron()
		&"shield_bash":
			_cast_shield_bash(target as Node3D)
			fx_target = target
		&"bulwark_stand":
			_cast_bulwark_stand()
		&"cutpurse":
			_cutpurse_armed = true
			_cutpurse_bonus = amount_of(id)
			fx_target = target
		&"smoke_pouch":
			_cast_smoke_pouch()
		&"marked_for_coin":
			(target as Unit).apply_status(&"marked", float(ability_data(id)["duration"]))
			fx_target = target
		&"mending_draught":
			(target as Unit).heal(amount_of(id))
			fx_target = target
		&"soothing_circle":
			_cast_soothing_circle(target)
			fx_target = target
		&"lifeline":
			(target as Unit).add_shield(amount_of(id), float(ability_data(id)["duration"]))
			fx_target = target
		# ---- class skills (skills-rework.md 4.2)
		&"lunge":
			_play_feedback(id, target)   # before the dash: the streak runs from where it stood
			played = true
			_cast_lunge(target as Unit)
		&"hobbling_javelin":
			_throw_javelin(target as Unit)
			fx_target = target
		&"skewer":
			fx_target = _cast_skewer(target as Unit)
		&"riposte":
			_riposte_left = float(ability_data(id)["duration"])
		&"second_wind":
			_cast_second_wind()
		&"shield_throw":
			_cast_shield_throw(target as Unit)
			fx_target = target
		&"cleave":
			_cleave_left = float(ability_data(id)["duration"])
			played = true   # the sweep and its arc come with the empowered hit
		&"crushing_blow":
			_cast_crushing_blow(target as Node3D)
			fx_target = target
		&"whirlwind":
			_cast_whirlwind()
		&"arc_bolt":
			_shoot_arc_bolt(target as Unit)
			fx_target = target
		&"slipstep":
			_play_feedback(id, target)   # before the jump: the fade shows where it stood, the point where it lands
			played = true
			_teleport(target)
		&"starfall":
			_cast_starfall(target)
			fx_target = target
	if not played:
		_play_feedback(id, fx_target)
	ability_cast.emit(id)
	if cd > 0.0:
		cooldown_started.emit(id, cd)


## Flare Arrow: damage to enemy units and buildings around the point, then a sight marker there.
func _cast_flare_arrow(pos: Vector3) -> void:
	var d := ability_data(&"flare_arrow")
	var dmg := amount_of(&"flare_arrow")
	var r := float(d["radius"])
	for group: StringName in [&"units", &"buildings"]:
		for node in get_tree().get_nodes_in_group(group):
			var n := node as Node3D
			if n == null or n.is_in_group(&"taverns") or not n.has_method(&"take_damage") \
					or not champion.is_enemy_of(n) or not _alive(n):
				continue
			if _flat_dist(n.global_position, pos) <= r + Unit.radius_of(n):
				n.call(&"take_damage", dmg, champion)
	_spawn_sight_marker(pos, float(d["sight_radius"]), float(d["duration"]))


## SightMarker.spawn(team, pos, radius, seconds, parent) (scripts/world/sight_marker.gd, 9.C4) when it
## exists; else a FlareSight with the same fields.
func _spawn_sight_marker(pos: Vector3, sight: float, seconds: float) -> void:
	var marker: Node3D = null
	if ResourceLoader.exists(SIGHT_MARKER_PATH):
		var script := load(SIGHT_MARKER_PATH) as Script
		if script and _has_script_method(script, &"spawn"):
			marker = script.call(&"spawn", int(champion.team), pos, sight, seconds, _world()) as Node3D
	if marker == null:
		marker = FlareSight.new()
		marker.name = "FlareSight"
		marker.set(&"team", int(champion.team))
		marker.set(&"sight_radius", sight)
		marker.set(&"lifetime", seconds)
		marker.position = pos
		marker.add_to_group(&"fog_sources")
		_world().add_child(marker, true)
		marker.global_position = pos
	last_sight_marker = marker


static func _has_script_method(script: Script, method: StringName) -> bool:
	for m: Dictionary in script.get_script_method_list():
		if StringName(m.get("name", "")) == method:
			return true
	return false


func _cast_snare_line(u: Unit) -> void:
	u.take_damage(amount_of(&"snare_line"), champion)
	if u.is_alive():
		u.apply_status(&"rooted", float(ability_data(&"snare_line")["duration"]))


## Itself and own non-worker units within 8 m: haste.
func _cast_trailblaze() -> void:
	var d := ability_data(&"trailblaze")
	var r := float(d["radius"])
	var secs := float(d["duration"])
	var me := champion.global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) != int(champion.team) or u.is_worker():
			continue
		if u == champion or _flat_dist(u.global_position, me) <= r + u.radius:
			u.apply_status(&"haste", secs)


## +20 armor for 3 s; enemy non-hero units within 6 m are taunted 3 s (wizards and champions immune).
func _cast_oath_of_iron() -> void:
	var d := ability_data(&"oath_of_iron")
	var secs := float(d["duration"])
	var r := float(d["radius"])
	champion.add_modifier(OATH_MODIFIER, {&"armor": float(d["armor"])})
	_oath_left = secs
	var me := champion.global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive() or not champion.is_enemy_of(u) or _is_hero(u) \
				or u.is_in_group(&"taverns"):
			continue
		if _flat_dist(u.global_position, me) <= r + u.radius:
			_taunt(u, secs)


# Unit keeps a taunted unit on its source (taunted_by) while the status lasts.
func _taunt(u: Unit, secs: float) -> void:
	u.apply_status(&"taunted", secs, false, champion)
	if u.has_status(&"taunted"):
		u.attack_target = champion   # at once (the unit re-applies it every frame)


func _cast_shield_bash(n: Node3D) -> void:
	n.call(&"take_damage", amount_of(&"shield_bash"), champion)
	var u := n as Unit
	if u and u.is_alive():
		u.apply_status(&"dazed", float(ability_data(&"shield_bash")["duration"]))


## Rooted itself for 6 s (full duration: self-inflicted); braces own units within 5 m every 0.5 s.
func _cast_bulwark_stand() -> void:
	var secs := float(ability_data(&"bulwark_stand")["duration"])
	champion.apply_status(&"rooted", secs, true)
	_bulwark_left = secs
	_brace_left = BRACE_REFRESH
	_brace_allies()


func _brace_allies() -> void:
	var r := float(ability_data(&"bulwark_stand")["radius"])
	var secs := minf(BRACE_REFRESH + 0.1, _bulwark_left)   # the last refresh ends with the stand
	if secs <= 0.0:
		return
	var me := champion.global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) != int(champion.team):
			continue
		if u == champion or _flat_dist(u.global_position, me) <= r + u.radius:
			u.apply_status(&"braced", secs)


func _cast_smoke_pouch() -> void:
	var d := ability_data(&"smoke_pouch")
	var secs := float(d["duration"])
	var r := float(d["drop_radius"])
	champion.apply_status(&"shroud", secs, true)
	champion.hide_from_auto_target(secs)
	var me := champion.global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u.is_alive() and champion.is_enemy_of(u) and _flat_dist(u.global_position, me) <= r + u.radius \
				and _targets_champion(u):
			u.attack_target = null


## Heal over time (SpellHot, like Wild Bloom) on the own units inside the circle at cast.
func _cast_soothing_circle(pos: Vector3) -> void:
	var d := ability_data(&"soothing_circle")
	var r := float(d["radius"])
	var targets: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == int(champion.team) \
				and _flat_dist(u.global_position, pos) <= r + u.radius:
			targets.append(u)
	if targets.is_empty():
		return
	var hot := SpellHot.new()
	hot.name = "SoothingCircle"
	hot.spell_id = &"soothing_circle"
	hot.setup(targets, amount_of(&"soothing_circle"), float(d["duration"]), float(d["tick"]))
	_world().add_child(hot, true)


# ---------------------------------------------------------------- class skills (skills-rework.md 4.2)

## Lunge: dash to the closest navmesh point 1 m from the target, then 25 damage + dazed 0.5 s (0.25 s on
## a hero: Unit hero_mult). No free spot on the navmesh: it strikes from where it stands.
func _cast_lunge(u: Unit) -> void:
	var me := champion.global_position
	var tp := u.global_position
	var back := Vector3(me.x - tp.x, 0.0, me.z - tp.z)
	var gap := maxf(LUNGE_GAP, champion.radius + u.radius + 0.1)
	if back.length() > gap + 0.05:
		var dest := tp + back.normalized() * gap
		dest.y = me.y
		dest = _on_navmesh(dest)
		if dest != Vector3.INF:
			_teleport(dest)
	var dmg := amount_of(&"lunge")
	u.take_damage(dmg, champion)
	skill_hit.emit(&"lunge", u, dmg)
	if u.is_alive():
		u.apply_status(&"dazed", float(ability_data(&"lunge")["duration"]))


## Hobbling Javelin: a 24 m/s javelin; on landing 25 damage + `smoulder` 3 s (the "hobbled" slow).
func _throw_javelin(u: Unit) -> void:
	var bolt := _launch(&"hobbling_javelin", u, JAVELIN_COLOR, 0.1, 0.35)
	bolt.hit_unit.connect(_on_javelin_hit)


func _on_javelin_hit(target: Node3D, _dealt: float) -> void:
	skill_hit.emit(&"hobbling_javelin", target, amount_of(&"hobbling_javelin"))
	var u := target as Unit
	if u and u.is_alive():
		u.apply_status(&"smoulder", float(ability_data(&"hobbling_javelin")["duration"]))


## Arc Bolt: a 28 m/s bolt, 40 damage on landing.
func _shoot_arc_bolt(u: Unit) -> void:
	var bolt := _launch(&"arc_bolt", u, ARC_BOLT_COLOR, 0.16, 0.3)
	bolt.hit_unit.connect(_on_arc_bolt_hit)


func _on_arc_bolt_hit(target: Node3D, _dealt: float) -> void:
	skill_hit.emit(&"arc_bolt", target, amount_of(&"arc_bolt"))


func _launch(id: StringName, u: Unit, color: Color, size: float, arc: float) -> Projectile:
	var bolt := Projectile.new()
	bolt.name = "ChampionProjectile"
	_world().add_child(bolt, true)
	bolt.launch_at_target(champion, _cast_origin(), u, amount_of(id), color, size,
			float(ability_data(id)["speed"]), arc)
	return bolt


# Where thrown / shot skills start: the model's get_beam_origin() (staff crystal...), else chest height.
func _cast_origin() -> Vector3:
	var model := champion.get_model()
	if model and model.has_method(&"get_beam_origin"):
		var p: Variant = model.call(&"get_beam_origin")
		if p is Vector3:
			return p
	return champion.global_position + Vector3.UP * champion.body_height * 0.75


## Skewer: 40 damage to every enemy unit in the 5 x 1 m line toward `aim`. Returns the far end point.
func _cast_skewer(aim: Unit) -> Vector3:
	var me := champion.global_position
	var dir := _flat_dir(me, aim.global_position)
	if dir == Vector3.ZERO:
		dir = Vector3(sin(champion.rotation.y), 0.0, cos(champion.rotation.y))
	var span := champion.radius + range_of(&"skewer") + Unit.MAX_UNIT_RADIUS
	var pool: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and _is_enemy_unit(u) and _flat_dist(u.global_position, me) <= span:
			pool.append(u)
	var dmg := amount_of(&"skewer")
	for u in _units_in_line(dir, pool):
		u.take_damage(dmg, champion)
		skill_hit.emit(&"skewer", u, dmg)
	return me + dir * (champion.radius + range_of(&"skewer"))


# Units of `pool` whose body touches the line: from the champion's centre along `dir` (flat, unit length),
# its radius + 5 m long, 1 m wide.
func _units_in_line(dir: Vector3, pool: Array[Unit]) -> Array[Unit]:
	var d := ability_data(&"skewer")
	var length := champion.radius + float(d["range"])
	var half := float(d["width"]) * 0.5
	var me := champion.global_position
	var out: Array[Unit] = []
	for u in pool:
		var rel := Vector3(u.global_position.x - me.x, 0.0, u.global_position.z - me.z)
		var t := rel.dot(dir)
		if t < 0.0 or t > length + u.radius:
			continue
		if (rel - dir * t).length() <= half + u.radius:
			out.append(u)
	return out


## Riposte (while active): a melee enemy unit that hits the champion takes 10 back, credited to it.
func _on_damage_taken(_amount: float, attacker: Node3D) -> void:
	if _riposte_left <= 0.0 or _countering or not _alive(champion):
		return
	if attacker == null or not is_instance_valid(attacker) or not attacker is Unit:
		return
	var u := attacker as Unit
	if not u.is_alive() or not champion.is_enemy_of(u) \
			or u.attack_range > float(ability_data(&"riposte")["melee_range"]):
		return
	var dmg := amount_of(&"riposte")
	_countering = true
	u.take_damage(dmg, champion)
	_countering = false
	skill_hit.emit(&"riposte", u, dmg)


## Second Wind: 20 % of its max HP over 4 s in 8 ticks (a SpellHot on itself: it stops if it dies).
func _cast_second_wind() -> void:
	var d := ability_data(&"second_wind")
	var hot := SpellHot.new()
	hot.name = "SecondWind"
	hot.spell_id = &"second_wind"
	var targets: Array[Node3D] = [champion]
	hot.setup(targets, amount_of(&"second_wind"), float(d["duration"]), float(d["tick"]))
	hot.healed_target.connect(_on_second_wind_tick)
	_world().add_child(hot, true)


func _on_second_wind_tick(target: Node3D, amount: float) -> void:
	skill_hit.emit(&"second_wind", target, amount)


## Shield Throw: 30 to the target, then it bounces to the nearest enemy unit within 4 m of the last one
## hit (20, then 10), never the same unit twice.
func _cast_shield_throw(first: Unit) -> void:
	var d := ability_data(&"shield_throw")
	var mult := effect_multiplier()
	var bounce_r := float(d["bounce_radius"])
	var hit: Array[Unit] = [first]
	var dmg := float(d["amount"]) * mult
	first.take_damage(dmg, champion)
	skill_hit.emit(&"shield_throw", first, dmg)
	var from := first.global_position
	for b: Variant in d["bounces"]:
		var next := _nearest_enemy_unit(from, bounce_r, hit)
		if next == null:
			break
		dmg = float(b) * mult
		from = next.global_position
		hit.append(next)
		next.take_damage(dmg, champion)
		skill_hit.emit(&"shield_throw", next, dmg)


func _nearest_enemy_unit(pos: Vector3, r: float, skip: Array[Unit]) -> Unit:
	var best: Unit = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or skip.has(u) or not _is_enemy_unit(u):
			continue
		var dist := _flat_dist(u.global_position, pos)
		if dist <= r + u.radius and dist < best_d:
			best_d = dist
			best = u
	return best


## Cleave (armed): the attack also hits every other enemy unit within 2.5 m of its target for the
## attack's full damage (the champion's attack_damage). Rides a bolt too: around the bolt's target.
func _cleave_splash(center: Node3D) -> void:
	var r := float(ability_data(&"cleave")["radius"])
	var dmg := champion.attack_damage
	var c := center.global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or u == center or not _is_enemy_unit(u):
			continue
		if _flat_dist(u.global_position, c) <= r + u.radius:
			u.take_damage(dmg, champion)
			skill_hit.emit(&"cleave", u, dmg)


## Crushing Blow: 30 damage; a unit still standing loses 20 armor for 6 s (`ability:crush`). Buildings
## only take the damage.
func _cast_crushing_blow(n: Node3D) -> void:
	var d := ability_data(&"crushing_blow")
	var dmg := amount_of(&"crushing_blow")
	n.call(&"take_damage", dmg, champion)
	skill_hit.emit(&"crushing_blow", n, dmg)
	var u := n as Unit
	if u == null or not u.is_alive():
		return
	var mark := u.get_node_or_null(NodePath(CRUSH_NODE)) as CrushMark
	if mark == null:
		mark = CrushMark.new()
		mark.name = CRUSH_NODE
		u.add_child(mark)
	mark.start(u, CRUSH_MODIFIER, float(d["armor"]), float(d["duration"]))


## Whirlwind: spins 2 s; 12 damage to every enemy unit within 3 m now and every 0.5 s after (4 ticks).
func _cast_whirlwind() -> void:
	var d := ability_data(&"whirlwind")
	var tick := float(d["tick"])
	_whirl_amount = amount_of(&"whirlwind")
	_whirl_left = float(d["duration"])
	_whirl_ticks = maxi(1, roundi(float(d["duration"]) / tick)) - 1
	_whirl_next = tick
	_whirlwind_hit()


func _whirlwind_hit() -> void:
	var r := float(ability_data(&"whirlwind")["radius"])
	var me := champion.global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and _is_enemy_unit(u) and _flat_dist(u.global_position, me) <= r + u.radius:
			u.take_damage(_whirl_amount, champion)
			skill_hit.emit(&"whirlwind", u, _whirl_amount)


## Slipstep: up to 8 m straight away from the nearest melee enemy (then +-20 / +-40 degrees, shorter
## jumps down to 3 m), on the navmesh, never on a cell its team has not explored. INF = no spot.
func _slipstep_destination() -> Vector3:
	var me := champion.global_position
	var threat: Unit = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not _is_enemy_unit(u) or not _is_melee(u):
			continue
		var dist := _flat_dist(u.global_position, me)
		if dist <= SCAN_RANGE and dist < best_d:
			best_d = dist
			threat = u
	if threat == null:
		return Vector3.INF
	var away := _flat_dir(threat.global_position, me)
	if away == Vector3.ZERO:
		away = Vector3(-sin(champion.rotation.y), 0.0, -cos(champion.rotation.y))
	var reach := range_of(&"slipstep")
	var fog := FogOfWar.find()
	var fog_on := fog != null and fog.enabled
	var team := int(champion.team)
	for ang in SLIP_ANGLES:
		var dir := away.rotated(Vector3.UP, ang)
		var dist := reach
		while dist >= SLIP_MIN - 0.01:
			var want := me + dir * dist
			dist -= 1.0
			if absf(want.x) > FogOfWar.MAP_HALF or absf(want.z) > FogOfWar.MAP_HALF:
				continue
			var p := _on_navmesh(want)
			if p == Vector3.INF or _flat_dist(p, me) > reach + 0.5:
				continue
			if fog_on and fog.state_at(team, p) == FogOfWar.UNEXPLORED:
				continue
			if _flat_dist(p, threat.global_position) < best_d + SLIP_MIN - 0.5:
				continue   # the navmesh pulled it back toward the threat
			return p
	return Vector3.INF


## Starfall: the star lands 1.0 s after the cast (a StarfallStrike in the world: it lands even if the
## champion falls meanwhile): 45 damage to every enemy unit and building within 3.5 m.
func _cast_starfall(pos: Vector3) -> void:
	var d := ability_data(&"starfall")
	var star := StarfallStrike.new()
	star.name = "Starfall"
	star.caster = champion
	star.team = int(champion.team)
	star.damage = amount_of(&"starfall")
	star.radius = float(d["radius"])
	star.left = float(d["delay"])
	star.on_hit = _on_starfall_hit
	_world().add_child(star, true)
	star.global_position = pos


func _on_starfall_hit(target: Node3D, amount: float) -> void:
	skill_hit.emit(&"starfall", target, amount)


# The closest navmesh point to `p` (INF when it is more than 1.5 m away); `p` itself without a navmesh.
func _on_navmesh(p: Vector3) -> Vector3:
	var world := champion.get_world_3d()
	if world == null:
		return p
	var map := world.navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) <= 0 \
			or NavigationServer3D.map_get_regions(map).is_empty():
		return p
	var q := NavigationServer3D.map_get_closest_point(map, p)
	return q if _flat_dist(q, p) <= NAV_SNAP else Vector3.INF


# Instant move (Lunge, Slipstep): the orders are kept, the brain re-plans the path.
func _teleport(dest: Vector3) -> void:
	champion.global_position = Vector3(dest.x, dest.y, dest.z)
	champion.velocity = Vector3.ZERO
	champion.reset_physics_interpolation()


# The attack hooks: Cutpurse (bonus damage + loot on a kill) and Cleave (splash) ride the next attack.
func _on_attack_landed(target: Node3D, _amount: float) -> void:
	if _cutpurse_armed:
		_land_cutpurse(target)
	if _cleave_left > 0.0:
		_cleave_left = 0.0
		if target != null and is_instance_valid(target):
			_play_feedback(&"cleave", target)
			_cleave_splash(target)


# Cutpurse: the armed bonus lands with the next attack; a kill with it gives the loot.
func _land_cutpurse(target: Node3D) -> void:
	_cutpurse_armed = false
	if target == null or not is_instance_valid(target):
		return
	# 9.C10: the model's lunge-stab and the coin burst on the empowered hit (the VFX still shows on a kill).
	_play_feedback(&"cutpurse", target)
	if _alive(target):
		target.call(&"take_damage", _cutpurse_bonus, champion)
	# Game critters (deer, rabbits) pay no champion loot (map-fill.md 3.4).
	if not _alive(target) and champion.has_method(&"add_purse") and not target.has_method(&"is_game_critter"):
		champion.call(&"add_purse", int(ability_data(&"cutpurse")["loot"]))


func _play_feedback(id: StringName, fx_target: Variant) -> void:
	var model := champion.get_model()
	if model and model.has_method(&"play_cast"):
		model.call(&"play_cast", id)
	var vfx := get_tree().get_first_node_in_group(&"champion_vfx")
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", id, champion, fx_target)


# ---------------------------------------------------------------- autocast triggers (4.3)

# One pass over "units": visible enemies within 20 m, own units within 14 m. With `track_lost`, also
# the last spot of enemies that were visible at the previous check and are hidden now (Flare Arrow).
func _scan(track_lost: bool) -> void:
	_enemies.clear()
	_enemy_d.clear()
	_allies.clear()
	_lost_enemy_pos = Vector3.INF
	var me := champion.global_position
	var team := int(champion.team)
	var fog := FogOfWar.find()
	var fog_on := fog != null and fog.enabled
	var seen := {}
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive():
			continue
		var p := u.global_position
		var d := Vector2(p.x - me.x, p.z - me.z).length()
		if int(u.team) == team:
			if d <= ALLY_SCAN_RANGE + u.radius:
				_allies.append(u)
			continue
		if d > SCAN_RANGE + u.radius or u.is_in_group(&"taverns"):
			continue
		if fog_on and not fog.is_visible(team, p):
			continue
		_enemies.append(u)
		_enemy_d.append(d)
		if track_lost:
			seen[u.get_instance_id()] = [u, u.global_position]
	if not track_lost:
		_last_seen.clear()
		return
	if fog_on:
		var best := INF
		for key: int in _last_seen:
			if seen.has(key):
				continue
			var entry: Array = _last_seen[key]
			if not _alive(entry[0]):
				continue
			var gone := entry[0] as Unit
			if fog.is_visible(team, gone.global_position):
				continue   # still in sight, only outside the scan radius
			var last: Vector3 = entry[1]
			var dist := _flat_dist(last, me)
			if dist <= FLARE_MAX and dist < best:
				best = dist
				_lost_enemy_pos = last
	_last_seen = seen


# [] = the trigger does not fire; [target] = cast with that target (null for self abilities).
func _trigger(id: StringName) -> Array:
	match id:
		&"flare_arrow":
			return _trigger_flare()
		&"snare_line":
			return _trigger_snare()
		&"trailblaze":
			return _trigger_trailblaze()
		&"oath_of_iron":
			return _trigger_oath()
		&"shield_bash":
			return _trigger_bash()
		&"bulwark_stand":
			return _trigger_bulwark()
		&"cutpurse":
			return _trigger_cutpurse()
		&"smoke_pouch":
			return _trigger_smoke()
		&"marked_for_coin":
			return _trigger_marked()
		&"mending_draught":
			var hurt := _most_hurt_ally(range_of(id), MEND_HP, _allies)
			return [hurt] if hurt else []
		&"soothing_circle":
			return _trigger_circle()
		&"lifeline":
			return _trigger_lifeline()
		&"lunge":
			return _trigger_lunge()
		&"hobbling_javelin":
			return _trigger_javelin()
		&"skewer":
			return _trigger_skewer()
		&"riposte":
			return _trigger_riposte()
		&"second_wind":
			return _trigger_second_wind()
		&"shield_throw":
			return _trigger_shield_throw()
		&"cleave":
			return _trigger_cleave()
		&"crushing_blow":
			return _trigger_crushing_blow()
		&"whirlwind":
			return _trigger_whirlwind()
		&"arc_bolt":
			return _trigger_arc_bolt()
		&"slipstep":
			return _trigger_slipstep()
		&"starfall":
			return _trigger_starfall()
	return []


# Fighting: the last spot of an enemy that just left vision within 20 m. Exploring / on an Explore
# flag: the least explored point 14-20 m ahead (nothing when all of it is visible).
func _trigger_flare() -> Array:
	if _lost_enemy_pos != Vector3.INF and _is_fighting():
		return [_lost_enemy_pos]
	if _intent_is(["explor", "scout"]):
		var p := _flare_explore_point()
		if p != Vector3.INF:
			return [p]
	return []


func _flare_explore_point() -> Vector3:
	var fog := FogOfWar.find()
	if fog == null or not fog.enabled:
		return Vector3.INF
	var dir := _travel_direction()
	if dir == Vector3.ZERO:
		return Vector3.INF
	var me := champion.global_position
	var team := int(champion.team)
	var best := Vector3.INF
	var best_state: int = FogOfWar.VISIBLE
	for dist in FLARE_DISTANCES:
		for ang in FLARE_ANGLES:
			var p := me + dir.rotated(Vector3.UP, ang) * dist
			if absf(p.x) > FogOfWar.MAP_HALF or absf(p.z) > FogOfWar.MAP_HALF:
				continue
			var s := fog.state_at(team, p)
			if s < best_state:
				best_state = s
				best = p
	return best


# Fleeing and an enemy within 8 m targets it; or its Hunt target is within 8 m and moving away.
func _trigger_snare() -> Array:
	var reach := range_of(&"snare_line")
	if _intent_is(["flee"]):
		var best: Unit = null
		var best_d := INF
		for e in _enemies:
			if not _targets_champion(e) or e.has_status(&"rooted") or not _in_reach(e, reach):
				continue
			var d := _flat_dist(e.global_position, champion.global_position)
			if d < best_d:
				best_d = d
				best = e
		if best:
			return [best]
	if _intent_is(["hunt"]):
		var t := _intent_node() as Unit
		if t and _enemies.has(t) and not t.has_status(&"rooted") and _in_reach(t, reach) \
				and _moving_away(t):
			return [t]
	return []


# Fleeing; or walking (not fighting) to a flag / explore point more than 25 m away.
func _trigger_trailblaze() -> Array:
	if _intent_is(["flee"]):
		return [null]
	if _is_fighting() or _intent_is(["rest", "fallen", "return"]) or _speed() < MOVING_SPEED:
		return []
	var dest := _walk_destination()
	if dest != Vector3.INF and _flat_dist(dest, champion.global_position) > TRAILBLAZE_FAR:
		return [null]
	return []


# 2+ enemies within 6 m attack an own unit or building, or 3+ enemies target the Oathwall.
func _trigger_oath() -> Array:
	var r := float(ability_data(&"oath_of_iron")["radius"])
	var me := champion.global_position
	var attackers := 0
	var on_me := 0
	for e in _enemies:
		var t := e.attack_target
		if not is_instance_valid(t):
			continue
		if t == champion:
			on_me += 1
		if _is_own(t) and _flat_dist(e.global_position, me) <= r + e.radius:
			attackers += 1
	if attackers >= OATH_ATTACKERS or on_me >= OATH_TARGETERS:
		return [null]
	return []


# Its current target in range; an enemy in range hitting an own building or the wizard first.
func _trigger_bash() -> Array:
	var reach := range_of(&"shield_bash")
	for e in _enemies:
		var t := e.attack_target
		if not is_instance_valid(t) or not _is_own(t) or not _in_reach(e, reach):
			continue
		if t.is_in_group(&"buildings") or _is_wizard(t):
			return [e]
	var cur := champion.attack_target
	if is_instance_valid(cur) and (_is_enemy_unit(cur) or _is_enemy_building(cur)) and _in_reach(cur, reach):
		return [cur]
	return []


# 3+ enemies within 8 m and it is Guarding, or within 20 m of an own building.
func _trigger_bulwark() -> Array:
	if _bulwark_left > 0.0:
		return []
	var me := champion.global_position
	var near := 0
	for e in _enemies:
		if _flat_dist(e.global_position, me) <= BULWARK_ENEMY_RANGE + e.radius:
			near += 1
	if near < BULWARK_ENEMIES:
		return []
	if _intent_is(["guard"]) or _own_building_within(BULWARK_HOME_RANGE):
		return [null]
	return []


# Its target (in melee reach) is below 50 % HP or a worker.
func _trigger_cutpurse() -> Array:
	if _cutpurse_armed:
		return []
	var at: Variant = champion.attack_target
	if at == null or not is_instance_valid(at):   # a target freed without dying first (10.A3)
		return []
	var t := at as Unit
	if t == null or not _is_enemy_unit(t) or not _in_reach(t, _melee_reach()):
		return []
	if t.is_worker() or _hp_ratio(t) < CUTPURSE_HP:
		return [t]
	return []


# HP below the flee threshold + 10 % while being hurt, or 3+ enemies target it.
func _trigger_smoke() -> Array:
	if champion.has_status(&"shroud"):
		return []
	var on_me := 0
	for e in _enemies:
		if _targets_champion(e):
			on_me += 1
	if on_me >= SMOKE_TARGETERS:
		return [null]
	if _hp_ratio(champion) < _flee_pct() + SMOKE_HP_MARGIN \
			and champion.seconds_since_damage() < SMOKE_RECENT_HIT:
		return [null]
	return []


# Its Hunt (bounty) or raid target, in range and not marked yet.
func _trigger_marked() -> Array:
	if not _intent_is(["hunt", "raid"]):
		return []
	var t := _intent_node() as Unit
	if t and _enemies.has(t) and not t.has_status(&"marked") and _in_reach(t, range_of(&"marked_for_coin")):
		return [t]
	return []


# 3+ allies below 80 % HP within 5 m of one point (an ally within 9 m is the centre).
func _trigger_circle() -> Array:
	var r := float(ability_data(&"soothing_circle")["radius"])
	var reach := range_of(&"soothing_circle")
	var hurt: Array[Unit] = []
	for a in _allies:
		if _hp_ratio(a) < CIRCLE_HP:
			hurt.append(a)
	if hurt.size() < CIRCLE_COUNT:
		return []
	var me := champion.global_position
	var best_n := 0
	var best_pos := Vector3.ZERO
	for c in hurt:
		if _flat_dist(c.global_position, me) > reach:
			continue
		var n := 0
		for o in hurt:
			if _flat_dist(o.global_position, c.global_position) <= r + o.radius:
				n += 1
		if n > best_n:
			best_n = n
			best_pos = c.global_position
	return [best_pos] if best_n >= CIRCLE_COUNT else []


# The wizard or a champion (itself included) within 9 m below 35 % HP, wizard first, not shielded.
func _trigger_lifeline() -> Array:
	var reach := range_of(&"lifeline")
	for wizard_pass in [true, false]:
		var best: Unit = null
		for a in _allies:
			var is_wiz := _is_wizard(a)
			if is_wiz != wizard_pass or (not is_wiz and not a.is_in_group(&"champions")):
				continue
			if a.shield > 0.0 or _hp_ratio(a) >= LIFELINE_HP or not _in_reach(a, reach):
				continue
			if best == null or _hp_ratio(a) < _hp_ratio(best):
				best = a
		if best:
			return [best]
	return []


# ---- class skill triggers (skills-rework.md 4.2). Enemies = the visible ones of the scan.

# Its Hunt target within 6 m moving away; or fighting / hunting and a preferred foe (an enemy ranged unit
# or caster, or one under 40 % HP) 3-6 m away that is not within 11 m of a known enemy tower / keep.
func _trigger_lunge() -> Array:
	var reach := range_of(&"lunge")
	var hunting := _intent_is(["hunt"])
	if hunting:
		var t := _intent_node() as Unit
		if t and _enemies.has(t) and _in_reach(t, reach) and _moving_away(t):
			return [t]
	if not hunting and not _is_fighting():
		return []
	var cr := champion.radius
	var best: Unit = null
	var best_d := INF
	for i in _enemies.size():
		var e := _enemies[i]
		var gap := _enemy_d[i] - cr - e.radius
		if gap < LUNGE_MIN or gap > reach or gap >= best_d:
			continue
		if not _is_ranged_or_caster(e) and _hp_ratio(e) >= LUNGE_HP:
			continue
		if _near_known_tower(e.global_position, LUNGE_TOWER):
			continue
		best = e
		best_d = gap
	return [best] if best else []


# An enemy unit within 10 m under 60 % HP moving away from it or from an own unit fighting it; or its
# Hunt target moving away. Never on a unit already hobbled.
func _trigger_javelin() -> Array:
	var reach := range_of(&"hobbling_javelin")
	if _intent_is(["hunt"]):
		var t := _intent_node() as Unit
		if t and _enemies.has(t) and not t.has_status(&"smoulder") and _in_reach(t, reach) and _moving_away(t):
			return [t]
	var cr := champion.radius
	var best: Unit = null
	var best_d := INF
	var chasers: Variant = null   # built on first need
	for i in _enemies.size():
		var e := _enemies[i]
		var d := _enemy_d[i]
		if d >= best_d or d - cr - e.radius > reach or e.hp >= JAVELIN_HP * e.max_hp:
			continue
		var v := e.velocity
		if v.x * v.x + v.z * v.z < MOVING_SPEED * MOVING_SPEED or e.has_status(&"smoulder"):
			continue   # standing still: it flees nobody
		if not _moving_away(e):
			if chasers == null:
				chasers = _chasers()
			if not _fleeing_own_unit(e, chasers):
				continue
		best = e
		best_d = d
	return [best] if best else []


# 3+ enemy units in the 5 x 1 m line toward one of them (the line with the most).
func _trigger_skewer() -> Array:
	var reach := range_of(&"skewer")
	var me := champion.global_position
	var cr := champion.radius
	var span := cr + reach + Unit.MAX_UNIT_RADIUS
	var near: Array[Unit] = []
	for i in _enemies.size():
		if _enemy_d[i] <= span:
			near.append(_enemies[i])
	if near.size() < SKEWER_MIN:
		return []
	var best: Unit = null
	var best_n := 0
	for e in near:
		if _flat_dist(e.global_position, me) - cr - e.radius > reach:
			continue
		var dir := _flat_dir(me, e.global_position)
		if dir == Vector3.ZERO:
			continue
		var n := _units_in_line(dir, near).size()
		if n > best_n:
			best_n = n
			best = e
	return [best] if best and best_n >= SKEWER_MIN else []


# 2+ enemy melee units are attacking it (it is their target and it stands in their reach).
func _trigger_riposte() -> Array:
	if _riposte_left > 0.0:
		return []
	var cr := champion.radius
	var n := 0
	for i in _enemies.size():
		var e := _enemies[i]
		if e.attack_target != champion or e.attack_range > MELEE_MAX_RANGE:
			continue
		if _enemy_d[i] - cr - e.radius <= e.attack_range + ATTACK_SLACK and not e.is_non_combatant():
			n += 1
			if n >= RIPOSTE_ATTACKERS:
				return [null]
	return []


# HP under 50 % and it was hit in the last 2 s.
func _trigger_second_wind() -> Array:
	if _hp_ratio(champion) < SECOND_WIND_HP and champion.seconds_since_damage() < SECOND_WIND_RECENT:
		return [null]
	return []


# An enemy ranged unit or caster within 8 m hitting an own unit or building (the nearest); or its
# current target is 3-8 m away and out of its reach.
func _trigger_shield_throw() -> Array:
	var reach := range_of(&"shield_throw")
	var cr := champion.radius
	var best: Unit = null
	var best_d := INF
	for i in _enemies.size():
		var e := _enemies[i]
		var gap := _enemy_d[i] - cr - e.radius
		if gap > reach or gap >= best_d or e.attack_target == null:
			continue
		if not is_instance_valid(e.attack_target) or not _is_own(e.attack_target) or not _is_ranged_or_caster(e):
			continue
		best = e
		best_d = gap
	if best:
		return [best]
	var cur := champion.attack_target
	if _is_enemy_unit(cur):
		var gap := _edge_dist(cur)
		if gap >= SHIELD_THROW_MIN and gap <= reach and gap > champion.attack_range:
			return [cur]
	return []


# Its current target (about to be hit) has 2+ other enemy units within 2.5 m.
func _trigger_cleave() -> Array:
	if _cleave_left > 0.0:
		return []
	var t := champion.attack_target
	if not (_is_enemy_unit(t) or _is_enemy_building(t)) or not _in_reach(t, champion.attack_range + CLEAVE_SLACK):
		return []
	var r := float(ability_data(&"cleave")["radius"])
	var n := 0
	for e in _enemies:
		if e != t and _flat_dist(e.global_position, t.global_position) <= r + e.radius:
			n += 1
			if n >= CLEAVE_NEIGHBOURS:
				return [null]
	return []


# Its current target (in melee reach) has armor >= 10, or is a hero, or a unit costing >= 200.
func _trigger_crushing_blow() -> Array:
	var t := champion.attack_target
	if not (_is_enemy_unit(t) or _is_enemy_building(t)) or not _in_reach(t, _melee_reach()):
		return []
	if _armor_of(t) >= CRUSH_ARMOR:
		return [t]
	if t is Unit and (_is_hero(t) or _cost_of(t as Unit) >= CRUSH_COST):
		return [t]
	return []


# 3+ enemy units within 3 m (not while spinning).
func _trigger_whirlwind() -> Array:
	if _whirl_left > 0.0:
		return []
	var r := float(ability_data(&"whirlwind")["radius"])
	var n := 0
	for i in _enemies.size():
		if _enemy_d[i] <= r + _enemies[i].radius:
			n += 1
			if n >= WHIRL_ENEMIES:
				return [null]
	return []


# An enemy unit within 12 m that the bolt kills (highest cost first, heroes above all); else an enemy hero
# in range (the nearest); else the enemy in range attacking the most hurt own unit.
func _trigger_arc_bolt() -> Array:
	var reach := range_of(&"arc_bolt")
	var dmg := amount_of(&"arc_bolt")
	var kill: Unit = null
	var kill_cost := -1
	var hero: Unit = null
	var hero_d := INF
	var saver: Unit = null
	var saver_ratio := INF
	var cr := champion.radius
	var max_hit := dmg * Unit.armor_multiplier(Unit.ARMOR_FLOOR)   # the most the bolt can take
	for i in _enemies.size():
		var e := _enemies[i]
		var d := _enemy_d[i]
		if d - cr - e.radius > reach:
			continue
		if e.hp <= max_hit and e.hp <= dmg * Unit.armor_multiplier(e.get_stat(&"armor")):
			var cost := _cost_of(e)
			if cost > kill_cost or (cost == kill_cost and e.hp < kill.hp):
				kill = e
				kill_cost = cost
		if kill != null:
			continue   # a kill wins: the rest only matters while there is none
		if d < hero_d and _is_hero(e):
			hero = e
			hero_d = d
		if hero != null:
			continue   # a hero wins over the saving shot
		var t := e.attack_target
		if t != null and is_instance_valid(t) and t is Unit and _is_own(t):
			var ratio := _hp_ratio(t as Unit)
			if ratio < saver_ratio:
				saver = e
				saver_ratio = ratio
	if kill:
		return [kill]
	if hero:
		return [hero]
	return [saver] if saver else []


# A melee enemy within 3 m targets it and its HP is under 70 %; or it is fleeing and a melee enemy is
# within 4 m. Only when a landing spot exists.
func _trigger_slipstep() -> Array:
	var fleeing := _intent_is(["flee"])
	var low := _hp_ratio(champion) < SLIP_HP
	if not fleeing and not low:
		return []
	var fire := false
	for e in _enemies:
		if not _is_melee(e):
			continue
		var gap := _edge_dist(e)
		if (low and gap <= SLIP_NEAR and _targets_champion(e)) or (fleeing and gap <= SLIP_FLEE_NEAR):
			fire = true
			break
	if not fire or _slipstep_destination() == Vector3.INF:
		return []
	return [null]


# An enemy unit within 12 m with 3+ enemy units within 3.5 m of it (itself included): the one with the
# most; the star falls on its spot. Neighbours are counted through a 3.5 m grid (no n^2 on big armies).
func _trigger_starfall() -> Array:
	var reach := range_of(&"starfall")
	var r := float(ability_data(&"starfall")["radius"])
	var cell := r + Unit.MAX_UNIT_RADIUS
	var xs := PackedFloat32Array()
	var zs := PackedFloat32Array()
	var lims := PackedFloat32Array()   # r + its radius: the neighbour distance for that unit
	var units: Array[Unit] = []
	var in_range := PackedByteArray()
	for i in _enemies.size():
		var d := _enemy_d[i]
		if d > reach + cell:
			continue
		var e := _enemies[i]
		var p := e.global_position
		xs.append(p.x)
		zs.append(p.z)
		lims.append(r + e.radius)
		units.append(e)
		in_range.append(1 if d <= reach else 0)
	var n_pool := units.size()
	if n_pool < STARFALL_MIN:
		return []
	var buckets := {}   # Vector2i cell -> PackedInt32Array of pool indices
	var keys: Array[Vector2i] = []
	for k in n_pool:
		var key := Vector2i(floori(xs[k] / cell), floori(zs[k] / cell))
		keys.append(key)
		var list: PackedInt32Array = buckets.get(key, PackedInt32Array())
		list.append(k)
		buckets[key] = list
	var best := -1
	var best_n := 0
	for k in n_pool:
		if in_range[k] == 0:
			continue
		var x := xs[k]
		var z := zs[k]
		var n := 0
		for dx in 3:
			for dz in 3:
				var list: Variant = buckets.get(keys[k] + Vector2i(dx - 1, dz - 1))
				if list == null:
					continue
				for o: int in list:
					var ox := xs[o] - x
					var oz := zs[o] - z
					if ox * ox + oz * oz <= lims[o] * lims[o]:
						n += 1
		if n > best_n:
			best_n = n
			best = k
	return [units[best].global_position] if best >= 0 and best_n >= STARFALL_MIN else []


# ---------------------------------------------------------------- helpers

## Melee: attack reach 3 m or less, and it fights (caravans / 0-damage units never count).
static func _is_melee(u: Unit) -> bool:
	return u.attack_range <= MELEE_MAX_RANGE and not u.is_non_combatant()


## Ranged units (they shoot: reach over 3 m), support casters and wizards.
static func _is_ranged_or_caster(u: Unit) -> bool:
	return u.attack_range > MELEE_MAX_RANGE or u.support_caster != null or _is_wizard(u)


## Crystal cost for "highest cost first" (heroes = HERO_COST; units without a type = 0).
static func _cost_of(u: Unit) -> int:
	if _is_hero(u):
		return HERO_COST
	return u.unit_type.cost if u.unit_type else 0


static func _armor_of(n: Node3D) -> float:
	if n.has_method(&"get_stat"):
		return float(n.call(&"get_stat", &"armor"))
	var a: Variant = n.get(&"armor")
	return float(a) if a != null else 0.0


## Edge-to-edge distance from the champion (the way ranges are measured).
func _edge_dist(n: Node3D) -> float:
	return _flat_dist(n.global_position, champion.global_position) - champion.radius - Unit.radius_of(n)


## Flat unit vector from `a` to `b` (ZERO when they stand on the same spot).
static func _flat_dir(a: Vector3, b: Vector3) -> Vector3:
	var v := Vector3(b.x - a.x, 0.0, b.z - a.z)
	return v.normalized() if v.length() > 0.01 else Vector3.ZERO


# An own unit (not the champion) is fighting `e` and `e` walks away from it. `chasers` = _chasers() of
# this check (built once).
func _fleeing_own_unit(e: Unit, chasers: Dictionary) -> bool:
	var from: Variant = chasers.get(e.get_instance_id())
	if from == null:
		return false
	for p: Vector3 in from:
		if _moving_away_from(e, p):
			return true
	return false


# Instance id of an enemy -> positions of the own units (not the champion) that attack it.
func _chasers() -> Dictionary:
	var out := {}
	for a in _allies:
		var t := a.attack_target
		if a == champion or t == null or not is_instance_valid(t) or not t is Unit:
			continue
		var key := t.get_instance_id()
		if out.has(key):
			(out[key] as Array).append(a.global_position)
		else:
			out[key] = [a.global_position]
	return out


# A known enemy tower or keep (constructed, on a cell its team has explored; fog off = all known)
# stands within `r` of `pos`.
func _near_known_tower(pos: Vector3, r: float) -> bool:
	var fog := FogOfWar.find()
	var fog_on := fog != null and fog.enabled
	var team := int(champion.team)
	for node in get_tree().get_nodes_in_group(&"buildings"):
		var b := node as Building
		if b == null or not b.is_alive() or not champion.is_enemy_of(b) or not b.is_constructed():
			continue
		var kind: StringName = b.building_type.kind if b.building_type else &""
		if kind != &"tower" and kind != &"keep":
			continue
		if _flat_dist(b.global_position, pos) > r:
			continue
		if fog_on and fog.state_at(team, b.global_position) == FogOfWar.UNEXPLORED:
			continue
		return true
	return false

## `pool`: the scan's _allies (every own unit within reach is in it, same order); empty = the "units" group.
func _most_hurt_ally(reach: float, below: float, pool: Array[Unit] = []) -> Unit:
	var best: Unit = null
	var best_ratio := below
	var nodes: Array = []
	if pool.is_empty():
		nodes = get_tree().get_nodes_in_group(&"units")
	else:
		nodes = pool
	for node in nodes:
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) != int(champion.team):
			continue
		var ratio := _hp_ratio(u)
		if ratio < best_ratio and _in_reach(u, reach):   # the ratio first: it is cheaper
			best_ratio = ratio
			best = u
	return best


func _own_building_within(r: float) -> bool:
	var me := champion.global_position
	for node in get_tree().get_nodes_in_group(&"buildings"):
		var b := node as Node3D
		if b == null or not _is_own(b) or not _alive(b):
			continue
		if _flat_dist(b.global_position, me) - Unit.radius_of(b) <= r:
			return true
	return false


func _targets_champion(e: Unit) -> bool:
	return is_instance_valid(e.attack_target) and e.attack_target == champion


func _is_fighting() -> bool:
	return _intent_is(["fight"]) or is_instance_valid(champion.attack_target)


## The intent id, lower case ("fighting", "hunting_bounty"...): ids and display names both work.
func _intent_key() -> String:
	var v: Variant = champion.get(&"intent")
	return str(v).to_lower() if v != null else ""


func _intent_is(prefixes: Array) -> bool:
	var key := _intent_key()
	if key.is_empty():
		return false
	for p: Variant in prefixes:
		if key.begins_with(str(p)):
			return true
	return false


## The intent target; a bounty flag resolves to what it is on (its own spot for Explore flags).
func _intent_node() -> Node3D:
	var t: Variant = champion.get(&"intent_target")
	if not _is_node(t):
		return null
	var n := t as Node3D
	if n.is_in_group(&"bounties"):
		var inner: Variant = n.get(&"target")
		if _is_node(inner):
			return inner as Node3D
	return n


func _walk_destination() -> Vector3:
	var node := _intent_node()
	if node:
		return node.global_position
	var raw: Variant = champion.get(&"intent_target")
	if raw is Vector3:
		return raw
	var agent := _nav_agent()
	if agent and not agent.is_navigation_finished():
		return agent.target_position
	return Vector3.INF


# Where it is going: its velocity, else the direction of its destination. ZERO = unknown.
func _travel_direction() -> Vector3:
	var v := Vector3(champion.velocity.x, 0.0, champion.velocity.z)
	if v.length() >= MOVING_SPEED:
		return v.normalized()
	var dest := _walk_destination()
	if dest == Vector3.INF:
		return Vector3.ZERO
	var off := Vector3(dest.x - champion.global_position.x, 0.0, dest.z - champion.global_position.z)
	return off.normalized() if off.length() > 1.0 else Vector3.ZERO


func _moving_away(t: Unit) -> bool:
	return _moving_away_from(t, champion.global_position)


func _moving_away_from(t: Unit, from: Vector3) -> bool:
	var away := Vector3(t.global_position.x - from.x, 0.0, t.global_position.z - from.z)
	if away.length() < 0.01:
		return false
	return Vector3(t.velocity.x, 0.0, t.velocity.z).dot(away.normalized()) >= MOVING_SPEED


func _speed() -> float:
	return Vector2(champion.velocity.x, champion.velocity.z).length()


func _nav_agent() -> NavigationAgent3D:
	if _agent and is_instance_valid(_agent):
		return _agent
	for child in champion.get_children():
		if child is NavigationAgent3D:
			_agent = child
			return _agent
	return null


func _melee_reach() -> float:
	return champion.attack_range + MELEE_SLACK


## Edge-to-edge distance within `reach` (the champion's radius counts, like attack range).
func _in_reach(node: Node3D, reach: float) -> bool:
	return _flat_dist(node.global_position, champion.global_position) \
			<= reach + champion.radius + Unit.radius_of(node)


func _is_enemy_unit(v: Variant) -> bool:
	if not _is_node(v) or not v is Unit:
		return false
	var u := v as Unit
	return u.is_alive() and champion.is_enemy_of(u) and not u.is_in_group(&"taverns")


func _is_enemy_building(v: Variant) -> bool:
	if not _is_node(v) or v is Unit:
		return false
	var n := v as Node3D
	return n.is_in_group(&"buildings") and not n.is_in_group(&"taverns") and n.has_method(&"take_damage") \
			and _alive(n) and champion.is_enemy_of(n)


func _is_ally_unit(v: Variant) -> bool:
	if not _is_node(v) or not v is Unit:
		return false
	var u := v as Unit
	return u.is_alive() and int(u.team) == int(champion.team)


func _is_own(n: Node3D) -> bool:
	var t: Variant = n.get(&"team")
	return t != null and int(t) == int(champion.team)


static func _is_wizard(n: Node) -> bool:
	return n.is_in_group(&"heroes") or n.is_in_group(&"enemy_heroes") or n.has_method(&"command_cast")


## Wizards and champions: immune to taunts.
static func _is_hero(n: Node) -> bool:
	return _is_wizard(n) or n.is_in_group(&"champions")


static func _is_node(v: Variant) -> bool:
	return typeof(v) == TYPE_OBJECT and is_instance_valid(v) and v is Node3D


static func _alive(v: Variant) -> bool:
	return SpellCaster.is_target_alive(v)


static func _hp_ratio(u: Unit) -> float:
	return u.hp / maxf(1.0, u.max_hp)


static func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _level() -> int:
	if champion == null or not is_instance_valid(champion):
		return 1
	return clampi(champion.level, 1, MAX_LEVEL)


func _type_value(key: StringName) -> Variant:
	if champion == null or not is_instance_valid(champion):
		return null
	var ct: Variant = champion.get(&"champion_type")
	if typeof(ct) == TYPE_OBJECT and is_instance_valid(ct):
		return (ct as Object).get(key)
	return null


## The champion's ChampionClass resource (Champion.champion_class), or null (none chosen / no such field).
func _class_resource() -> Object:
	if champion == null or not is_instance_valid(champion):
		return null
	var cc: Variant = champion.get(&"champion_class")
	if typeof(cc) == TYPE_OBJECT and is_instance_valid(cc):
		return cc as Object
	return null


func _growth_pct() -> float:
	var v: Variant = _type_value(&"growth_pct")
	var g := float(v) if v != null else DEFAULT_GROWTH
	return g / 100.0 if g > 1.0 else g


## Flee threshold as a ratio (champion_type.flee_pct: 0.35 or 35 both work).
func _flee_pct() -> float:
	var v: Variant = _type_value(&"flee_pct")
	var f := float(v) if v != null else DEFAULT_FLEE
	return f / 100.0 if f > 1.0 else f


func _world() -> Node:
	var scene := get_tree().current_scene
	return scene if scene else champion.get_parent()


## Fallback sight marker when scripts/world/sight_marker.gd is missing: group "fog_sources" with
## `team` + `sight_radius`, frees itself after `lifetime` s.
class FlareSight extends Node3D:
	var team: int = 0
	var sight_radius := 8.0
	var lifetime := 6.0

	func _physics_process(delta: float) -> void:
		lifetime -= delta
		if lifetime <= 0.0:
			remove_from_group(&"fog_sources")
			queue_free()

	func is_alive() -> bool:
		return lifetime > 0.0


## Crushing Blow's armor break: a child "AbilityCrush" of the unit hit. Adds the stat modifier at start()
## (again = the timer restarts, never stacks) and removes it after `left` s. Lives on the victim, so the
## modifier always goes even if the caster is gone.
class CrushMark extends Node:
	var unit: Unit = null
	var modifier: StringName = &""
	var left := 0.0

	func start(u: Unit, mod_id: StringName, armor: float, seconds: float) -> void:
		unit = u
		modifier = mod_id
		left = seconds
		u.add_modifier(mod_id, {&"armor": armor})
		set_physics_process(true)

	func _physics_process(delta: float) -> void:
		left -= delta
		if left > 0.0001:
			return
		left = 0.0
		set_physics_process(false)
		if is_instance_valid(unit):
			unit.remove_modifier(modifier)
		queue_free()


## Starfall's falling star: lands `left` s after it is created, then hits every enemy unit and building
## (not taverns) within `radius` for `damage`, credited to the caster if it still exists. The point is
## its global_position. Lives in the world, so the champion falling meanwhile does not stop it.
class StarfallStrike extends Node3D:
	var caster: Node3D = null
	var team := 0
	var damage := 0.0
	var radius := 3.5
	var left := 1.0
	var on_hit := Callable()

	func _physics_process(delta: float) -> void:
		left -= delta
		if left > 0.0001:
			return
		set_physics_process(false)
		_land()
		queue_free()

	func _land() -> void:
		var src: Node3D = caster if is_instance_valid(caster) else null
		var at := global_position
		for group: StringName in [&"units", &"buildings"]:
			for node in get_tree().get_nodes_in_group(group):
				var n := node as Node3D
				if n == null or n.is_in_group(&"taverns") or not n.has_method(&"take_damage") \
						or not SpellCaster.is_target_alive(n):
					continue
				var t: Variant = n.get(&"team")
				if t == null or int(t) == team:
					continue
				if Vector2(n.global_position.x - at.x, n.global_position.z - at.z).length() \
						> radius + Unit.radius_of(n):
					continue
				n.call(&"take_damage", damage, src)
				if on_hit.is_valid():
					on_hit.call(n, damage)
