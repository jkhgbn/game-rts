class_name CreatureAbilities
extends Node
## Abilities of the neutral camp creatures and the epic beasts (docs/design/map-fill.md 5.1 / 5.5 / 13, task 12.C4).
## A child node named "CreatureAbilities" of the creature / beast Unit: CampManager / EpicBeasts / BeastBrain add it
## (`CreatureAbilities.attach(unit)` does it once, with the default ids of the unit's type), or anyone calls
## setup(unit, ids). Without setup the node takes its parent Unit and that type's default ids.
##
## Ids (ABILITIES): creatures `spore_burst` (Gloomcap Elder), `antler_sweep` (Hollow Stag); beasts `gore_charge`,
## `bristle_hide` (Tusker), `gale_swoop` / `shrieking_dive` + `updraft` (Roc A / B), `pounce`, `hamstring` (Direwolf),
## `maul`, `rending_roar`, `enrage` (Grizzlemaw). Passives (`bristle_hide`, `hamstring`, `enrage`) always run: cast()
## refuses them with "Passive". The variant (A = 0, B = 1) comes from the unit's type (BEASTS).
##
## cast(id, target = null) -> String: "" = done, else in this order: "Dead", "Cannot act" (frozen / dazed), "Locked"
## (not one of its ids), "Passive", "Busy" (mid dash / leap), "Cannot move" (rooted: dash / leap / updraft),
## "On cooldown", "Not ready" (Rending Roar before the first drop to 50 % HP, Updraft above 40 % HP or already used),
## "Invalid target". A null target = the ability picks its own (the autocast rule below); a given target must fit the
## rule (Gore Charge: an enemy combatant Unit 6-14 m away, centre to centre; Gale Swoop / Shrieking Dive: a Unit
## within 12 m; Pounce: a Unit 5-10 m away; Maul: an enemy in melee reach; Spore Burst: an enemy Node3D or a Vector3
## within 9 m; Antler Sweep / Rending Roar ignore it; Updraft: the nest as a Vector3 / Node3D, null = its lair centre
## from EpicBeasts.lair_of, else home_position()). ready(id) is true when cast(id, <a valid target>) would succeed.
##
## Autocast (autocast_enabled, default true; a BeastBrain may turn it off and call cast itself): every 0.5 s (staggered)
## while fighting (a living attack target, or damaged in the last 3 s) the first ability whose rule holds is cast (at
## most one per check). Rules: Spore Burst every 10 s at the current target; Antler Sweep every 8 s when 2+ enemies are
## within 3 m; Gore Charge every 12 s at a combatant 6-14 m away (the current target first); Gale Swoop / Shrieking
## Dive every 10 s at the enemy with the most enemies within 3 m (12 m reach); Pounce every 9 s (Moonpelt 6 s) at a
## target 5-10 m away (ranged units / wizards first); Maul every 9 s on the current target in reach; Rending Roar at 50 %
## HP, then every 30 s; Updraft once per life at 40 % HP (even when not fighting). The first cast of a fight comes at
## least 1.5 s after the fight starts.
##
## Dashes and leaps (Gore Charge 12 m/s, leaps 16 m/s) move the unit along a straight line sampled every 0.5 m; the
## line stops before the first sample that is deep water (RiverSystem.is_water through group "river", load-guarded)
## or off the navmesh (more than 0.6 m from its closest point), so the unit always ends on the navmesh, never in water
## and never across the river. Gore Charge may stop short (then only units it passed are hit); a leap that cannot
## land beside its target is refused ("Invalid target"). While moving, modifier `beast:motion` (move speed x0) holds
## the unit's own pathing.
##
## Numbers (ABILITIES) scale with the unit's damage: amount x attack_damage / UnitType.attack_damage (camp levels
## +10 % per level). Damage names the unit as the attacker (kills by creatures credit nobody: Unit rules). Beasts hit
## only combatants (not workers, not caravans); creatures hit every PLAYER / ENEMY unit.
##
## Feedback on every cast: the model's play_cast(id) (Unit.model_call) at the start, and MapFillVfx.play(id, at,
## target) (group "mapfill_vfx", if present): Spore Burst at the impact (0.46 s after the call, the Elder's slam frame:
## the cloud's point, the targeted node or null) together with its damage; Antler Sweep / Rending Roar / Updraft
## (the unit's position, the unit); Gore Charge / Gale Swoop / Shrieking Dive / Pounce at the start (the landing
## point, the unit); Maul (the victim's position, the victim); Hamstring when a fresh slow lands (victim position,
## victim). Model hooks besides play_cast (12.C9, all has_method-safe through Unit.model_call): each Bristle Hide
## reflect plays play_cast(&"bristle_hide") (the Tusker's bristle spike); enrage turning on calls set_enraged(true) +
## play_cast(&"enrage") (the Grizzlemaw's snarl), off calls set_enraged(false); beasts get set_variant(variant) at setup
## (EpicBeasts sends it too); a dash / leap turns the unit toward where it goes (Unit.face_direction).
## Signals ability_cast(id, target) after a cast, ability_hit(id, target, amount) for each hit (amount before
## armor; Bristle Hide = the reflect on the attacker).

signal ability_cast(id: StringName, target: Variant)
## One per unit hit by an ability (amount before armor and marks), Bristle Hide reflects included.
signal ability_hit(id: StringName, target: Node3D, amount: float)

const NODE_NAME := "CreatureAbilities"

const REASON_DEAD := "Dead"
const REASON_CANNOT_ACT := "Cannot act"
const REASON_LOCKED := "Locked"
const REASON_PASSIVE := "Passive"
const REASON_BUSY := "Busy"
const REASON_CANNOT_MOVE := "Cannot move"
const REASON_COOLDOWN := "On cooldown"
const REASON_NOT_READY := "Not ready"
const REASON_TARGET := "Invalid target"

## Every ability (map-fill.md 5.1 / 5.5). "cooldown_b" / "duration_b" / "status_b": variant B values. "self": no
## target. "move": a dash / leap (refused while rooted). "passive": always on, never cast.
const ABILITIES := {
	&"spore_burst": {"cooldown": 10.0, "damage": 20.0, "radius": 3.0, "status": &"marked", "duration": 4.0,
			"range": 9.0, "delay": 0.46},
	&"antler_sweep": {"cooldown": 8.0, "damage": 35.0, "radius": 3.0, "min_enemies": 2, "self": true, "delay": 0.0},
	&"gore_charge": {"cooldown": 12.0, "min": 6.0, "max": 14.0, "speed": 12.0, "damage": 45.0, "path_damage": 20.0,
			"path_width": 1.5, "status": &"dazed", "duration": 0.8, "duration_b": 1.2, "move": true},
	&"bristle_hide": {"passive": true, "reflect": 4.0},
	&"gale_swoop": {"cooldown": 10.0, "max": 12.0, "damage": 40.0, "radius": 2.5, "cluster": 3.0, "status": &"dazed",
			"duration": 0.5, "move": true},
	&"shrieking_dive": {"cooldown": 10.0, "max": 12.0, "damage": 40.0, "radius": 2.5, "cluster": 3.0,
			"status": &"marked", "duration": 5.0, "move": true},
	&"updraft": {"hp": 0.4, "shroud": 4.0, "heal_pct": 0.15, "heal_time": 4.0, "move": true},
	&"pounce": {"cooldown": 9.0, "cooldown_b": 6.0, "min": 5.0, "max": 10.0, "damage": 35.0, "status": &"rooted",
			"duration": 0.8, "move": true},
	&"hamstring": {"passive": true, "speed_pct": -0.25, "duration": 3.0},
	&"maul": {"cooldown": 9.0, "damage": 70.0, "status": &"marked", "duration": 5.0},
	&"rending_roar": {"cooldown": 30.0, "hp": 0.5, "radius": 6.0, "status": &"dazed", "duration": 1.0,
			"taunt_b": 3.0, "self": true},
	&"enrage": {"passive": true, "hp": 0.3, "cooldown_pct": -0.3},
}
## Autocast order (at most one cast per check).
const AUTOCAST_ORDER: Array[StringName] = [&"updraft", &"rending_roar", &"gore_charge", &"pounce", &"gale_swoop",
		&"shrieking_dive", &"maul", &"antler_sweep", &"spore_burst"]

## The 5 camp creatures (map-fill.md 5.1): fight strength (NeutralCamp.strength / bot) and default ability ids.
const CREATURES := {
	&"bristleback": {"strength": 100.0, "abilities": []},
	&"mirefang": {"strength": 110.0, "abilities": [], "amphibious": true},
	&"gloomcap_elder": {"strength": 220.0, "abilities": [&"spore_burst"]},
	&"gloomcap_sprout": {"strength": 50.0, "abilities": []},
	&"hollow_stag": {"strength": 700.0, "abilities": [&"antler_sweep"]},
}
## The 8 epic beasts (map-fill.md 5.5): kind, variant (0 = A, 1 = B), strength, aggro (the brain picks targets: the
## .tres has aggro_range 0), patrol speed (the .tres move_speed is the fight speed) and default ability ids.
const BEASTS := {
	&"ironhide_tusker": {"kind": &"tusker", "variant": 0, "strength": 900.0, "aggro": 8.0, "patrol_speed": 3.5,
			"abilities": [&"gore_charge", &"bristle_hide"]},
	&"old_scarback": {"kind": &"tusker", "variant": 1, "strength": 1080.0, "aggro": 8.0, "patrol_speed": 3.5,
			"abilities": [&"gore_charge", &"bristle_hide"]},
	&"stormcrest_roc": {"kind": &"roc", "variant": 0, "strength": 800.0, "aggro": 10.0, "patrol_speed": 3.5,
			"abilities": [&"gale_swoop", &"updraft"]},
	&"duskwing_roc": {"kind": &"roc", "variant": 1, "strength": 800.0, "aggro": 10.0, "patrol_speed": 3.5,
			"abilities": [&"shrieking_dive", &"updraft"]},
	&"greymane_direwolf": {"kind": &"direwolf", "variant": 0, "strength": 700.0, "aggro": 9.0, "patrol_speed": 4.5,
			"abilities": [&"pounce", &"hamstring"]},
	&"moonpelt_direwolf": {"kind": &"direwolf", "variant": 1, "strength": 780.0, "aggro": 9.0, "patrol_speed": 4.5,
			"abilities": [&"pounce", &"hamstring"]},
	&"grizzlemaw": {"kind": &"grizzlemaw", "variant": 0, "strength": 1300.0, "aggro": 9.0, "patrol_speed": 3.0,
			"abilities": [&"maul", &"rending_roar", &"enrage"]},
	&"elder_grizzlemaw": {"kind": &"grizzlemaw", "variant": 1, "strength": 1500.0, "aggro": 9.0, "patrol_speed": 3.0,
			"abilities": [&"maul", &"rending_roar", &"enrage"]},
}

const MOTION_MODIFIER := &"beast:motion"       # move speed x0 while a dash / leap moves the unit
const HAMSTRING_MODIFIER := &"beast:hamstring"
const HAMSTRING_NODE := "BeastHamstring"
const ENRAGE_MODIFIER := &"beast:enrage"
const PATROL_MODIFIER := &"beast:patrol"
const AUTOCAST_INTERVAL := 0.5
const OPENING_DELAY := 1.5        # the first cast of a fight comes at least this long after it starts
const FIGHT_MEMORY := 3.0         # "fighting" = a living target, or damaged within this many seconds
const NAV_STEP := 0.5             # dash / leap line sampling (m)
const NAV_TOLERANCE := 0.6        # a sample farther than this from its closest navmesh point is off the mesh
const MIN_CHARGE_TRAVEL := 2.0    # a Gore Charge blocked before this is refused
const LEAP_SPEED := 16.0
const MIN_MOTION_TIME := 0.25
const LAND_GAP := 0.1             # a dash / leap stops this far from the target's edge
const LAND_SLACK := 1.5           # the leap / charge still hits a target that moved this much
const MELEE_MAX_RANGE := 3.0      # Unit: more than 3 m shoots
const REACH_SLACK := 0.5
const HOT_TICK := 0.5

## False = only explicit cast() calls (a BeastBrain that drives every cast). Passives always run.
var autocast_enabled := true
## The creature / beast (read only).
var unit: Unit = null

var _ids: Array[StringName] = []
var _cooldown_left: Dictionary = {}    # StringName -> seconds
var _cooldown_total: Dictionary = {}
var _autocast_left := AUTOCAST_INTERVAL
var _is_beast := false
var _variant := 0
var _fighting := false
var _updraft_used := false
var _roar_unlocked := false
var _pending: Array[Dictionary] = []   # delayed impacts: {left, id, at, target}
var _hots: Array[Dictionary] = []      # heal over time: {ticks, per_tick, next}
var _motion: Dictionary = {}           # the running dash / leap


## A timed stat modifier on a victim that outlives the caster (Hamstring): removes itself when it runs out.
class TimedModifier extends Node:
	var mod_id: StringName = &""
	var left := 0.0

	func _physics_process(delta: float) -> void:
		left -= delta
		if left > 0.0:
			return
		var u := get_parent() as Unit
		if u != null and is_instance_valid(u):
			u.remove_modifier(mod_id)
		queue_free()


func _init() -> void:
	name = NODE_NAME


func _ready() -> void:
	if unit == null:
		var parent := get_parent() as Unit
		if parent != null:
			setup(parent, [])


## Binds the node to `p_unit` with `ability_ids` (empty = the defaults of the unit's type: abilities_for). Unknown ids
## are dropped with a warning. Also puts Mirefangs in group "amphibious" and the 5 creature kinds in "creatures".
func setup(p_unit: Unit, ability_ids: Array[StringName] = []) -> void:
	if unit != null and is_instance_valid(unit):
		if unit.damage_taken.is_connected(_on_damage_taken):
			unit.damage_taken.disconnect(_on_damage_taken)
		if unit.attack_landed.is_connected(_on_attack_landed):
			unit.attack_landed.disconnect(_on_attack_landed)
	unit = p_unit
	_ids.clear()
	_cooldown_left.clear()
	_cooldown_total.clear()
	if unit == null:
		return
	var type_id := _type_id()
	var wanted: Array[StringName] = ability_ids if not ability_ids.is_empty() else abilities_for(type_id)
	for id: StringName in wanted:
		if ABILITIES.has(id):
			if not _ids.has(id):
				_ids.append(id)
		else:
			push_warning("CreatureAbilities: unknown ability id %s" % id)
	_is_beast = BEASTS.has(type_id)
	_variant = int((BEASTS[type_id] as Dictionary)["variant"]) if _is_beast else 0
	if not _is_beast and unit.has_meta(&"beast_variant"):   # EpicBeasts also stamps the variant on the unit
		_variant = int(unit.get_meta(&"beast_variant"))
	if CREATURES.has(type_id):
		unit.add_to_group(&"creatures")
		if bool((CREATURES[type_id] as Dictionary).get("amphibious", false)):
			unit.add_to_group(&"amphibious")
	unit.damage_taken.connect(_on_damage_taken)
	unit.attack_landed.connect(_on_attack_landed)
	if _is_beast:
		_sync_model_variant()
	# Stagger the checks of many creatures over the interval.
	_autocast_left = AUTOCAST_INTERVAL * fposmod(float(CasterKit.next_stagger() % 997) * 0.618, 1.0) + 0.01


# Beasts: the model (one scene per kind) shows this type's variant. EpicBeasts also sends it right after the spawn;
# a beast spawned any other way gets it here (now, or once the Unit has built its model in _ready).
func _sync_model_variant() -> void:
	if unit == null or not is_instance_valid(unit):
		return
	if unit.is_node_ready():
		unit.model_call(&"set_variant", [_variant])
	elif not unit.ready.is_connected(_sync_model_variant):
		unit.ready.connect(_sync_model_variant, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- static helpers

## Adds a "CreatureAbilities" child to `unit` (once; returns the existing one) with `ids` (empty = the type defaults).
static func attach(p_unit: Unit, ids: Array[StringName] = []) -> CreatureAbilities:
	if p_unit == null:
		return null
	var existing := p_unit.get_node_or_null(NODE_NAME) as CreatureAbilities
	if existing != null:
		return existing
	var node := CreatureAbilities.new()
	node.setup(p_unit, ids)
	p_unit.add_child(node)
	return node


## The CreatureAbilities child of `node`, or null.
static func of(node: Node) -> CreatureAbilities:
	if node == null or not is_instance_valid(node):
		return null
	return node.get_node_or_null(NODE_NAME) as CreatureAbilities


## Default ability ids of a creature / beast type id (empty for the others).
static func abilities_for(type_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var row: Dictionary = CREATURES.get(type_id, BEASTS.get(type_id, {}))
	for id: Variant in row.get("abilities", []):
		out.append(StringName(str(id)))
	return out


## Fight strength of a creature / beast type (map-fill.md 5.1 / 5.5 "Strength"); 0 when unknown.
static func strength_of_type(type_id: StringName) -> float:
	var row: Dictionary = CREATURES.get(type_id, BEASTS.get(type_id, {}))
	return float(row.get("strength", 0.0))


## BEASTS row of a beast type id ({kind, variant, strength, aggro, patrol_speed, abilities}); {} for other types.
static func beast_info(type_id: StringName) -> Dictionary:
	return BEASTS.get(type_id, {})


static func is_passive(id: StringName) -> bool:
	return bool((ABILITIES.get(id, {}) as Dictionary).get("passive", false))


# ---------------------------------------------------------------- public API

func ability_ids() -> Array[StringName]:
	return _ids.duplicate()


func has_ability(id: StringName) -> bool:
	return _ids.has(id)


## 0 = variant A, 1 = variant B (from the unit's type).
func variant() -> int:
	return _variant


func cooldown_left(id: StringName) -> float:
	return float(_cooldown_left.get(id, 0.0))


func cooldown_total(id: StringName) -> float:
	return float(_cooldown_total.get(id, cooldown_for(id)))


## The full cooldown of `id` for this unit's variant (0 for passives and Updraft).
func cooldown_for(id: StringName) -> float:
	var d: Dictionary = ABILITIES.get(id, {})
	if _variant == 1 and d.has("cooldown_b"):
		return float(d["cooldown_b"])
	return float(d.get("cooldown", 0.0))


func reset_cooldowns() -> void:
	_cooldown_left.clear()


## True while a dash / leap moves the unit.
func is_busy() -> bool:
	return not _motion.is_empty()


func is_fighting() -> bool:
	return _fighting


func is_enraged() -> bool:
	return unit != null and is_instance_valid(unit) and unit.has_modifier(ENRAGE_MODIFIER)


func updraft_used() -> bool:
	return _updraft_used


## True when `id` could be cast now on a valid target (every refusal of cast() but "Invalid target").
func ready(id: StringName) -> bool:
	return _check(id) == ""


## The reason cast(id) would give right now without a target check ("" = only the target is left to check).
func can_cast(id: StringName) -> String:
	return _check(id)


## The target the ability would pick by itself now (its autocast rule), or null. Self abilities return the unit
## when their condition holds; Updraft returns its nest point (Vector3).
func find_target(id: StringName) -> Variant:
	if unit == null or not is_instance_valid(unit) or not unit.is_alive():
		return null
	return _trigger(id)


## Casts `id` (see the header). "" = done.
func cast(id: StringName, target: Variant = null) -> String:
	var why := _check(id)
	if why != "":
		return why
	var plan := _plan(id, target)
	if plan.is_empty():
		return REASON_TARGET
	var cd := cooldown_for(id)
	if cd > 0.0:
		_cooldown_left[id] = cd
		_cooldown_total[id] = cd
	_execute(id, plan)
	ability_cast.emit(id, plan.get("target", plan.get("at")))
	return ""


## Beasts: true = patrol pace (BEASTS patrol_speed, modifier `beast:patrol`), false = fight speed (the .tres value).
func set_patrolling(on: bool) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	var row: Dictionary = BEASTS.get(_type_id(), {})
	if not on or row.is_empty() or unit.unit_type == null or unit.unit_type.move_speed <= 0.0:
		unit.remove_modifier(PATROL_MODIFIER)
		return
	var ratio := float(row["patrol_speed"]) / unit.unit_type.move_speed
	unit.add_modifier(PATROL_MODIFIER, {&"move_speed_pct": ratio - 1.0})


func is_patrolling() -> bool:
	return unit != null and is_instance_valid(unit) and unit.has_modifier(PATROL_MODIFIER)


# ---------------------------------------------------------------- tick

func _physics_process(delta: float) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	if not unit.is_alive():
		if not _motion.is_empty():
			_end_motion(false)
		_pending.clear()
		_hots.clear()
		return
	if not _cooldown_left.is_empty():
		for id: StringName in _cooldown_left.keys():
			var left := float(_cooldown_left[id]) - delta
			if left <= 0.0:
				_cooldown_left.erase(id)
			else:
				_cooldown_left[id] = left
	if not _pending.is_empty():
		_tick_pending(delta)
	if not _hots.is_empty():
		_tick_hots(delta)
	if not _motion.is_empty():
		_tick_motion(delta)
	_autocast_left -= delta
	if _autocast_left <= 0.0:
		_autocast_left += AUTOCAST_INTERVAL
		_think()


func _think() -> void:
	var ratio := unit.hp / maxf(1.0, unit.max_hp)
	_update_enrage()
	if _ids.has(&"rending_roar") and ratio <= float(ABILITIES[&"rending_roar"]["hp"]):
		_roar_unlocked = true
	var fighting := _current_target() != null or unit.seconds_since_damage() < FIGHT_MEMORY
	if fighting and not _fighting:
		for id: StringName in _ids:
			if cooldown_for(id) > 0.0:
				_cooldown_left[id] = maxf(cooldown_left(id), OPENING_DELAY)
	_fighting = fighting
	if not fighting and ratio >= 0.999:
		_roar_unlocked = false   # healed in full after a reset: the roar waits for 50 % again
	if not autocast_enabled or not _motion.is_empty():
		return
	for id: StringName in AUTOCAST_ORDER:
		if not _ids.has(id) or (not fighting and id != &"updraft") or _check(id) != "":
			continue
		var t: Variant = _trigger(id)
		if t == null:
			continue
		if cast(id, t) == "":
			return


# ---------------------------------------------------------------- checks and targets

func _check(id: StringName) -> String:
	if unit == null or not is_instance_valid(unit) or not unit.is_alive():
		return REASON_DEAD
	if not unit.can_act():
		return REASON_CANNOT_ACT
	if not _ids.has(id):
		return REASON_LOCKED
	var d: Dictionary = ABILITIES[id]
	if bool(d.get("passive", false)):
		return REASON_PASSIVE
	if not _motion.is_empty():
		return REASON_BUSY
	if bool(d.get("move", false)) and not unit.can_move():
		return REASON_CANNOT_MOVE
	if cooldown_left(id) > 0.0:
		return REASON_COOLDOWN
	match id:
		&"rending_roar":
			if not _roar_unlocked and unit.hp > unit.max_hp * float(d["hp"]):
				return REASON_NOT_READY
		&"updraft":
			if _updraft_used or unit.hp > unit.max_hp * float(d["hp"]):
				return REASON_NOT_READY
	return ""


# The autocast rule of `id`: a target (Node3D / Vector3) or null when it should not fire now.
func _trigger(id: StringName) -> Variant:
	var d: Dictionary = ABILITIES.get(id, {})
	match id:
		&"spore_burst":
			var t := _current_target()
			return t if t != null and _flat_dist(t.global_position, unit.global_position) <= float(d["range"]) else null
		&"antler_sweep":
			return unit if _victims(unit.global_position, float(d["radius"])).size() >= int(d["min_enemies"]) else null
		&"gore_charge":
			return _pick_in_band(float(d["min"]), float(d["max"]), false)
		&"pounce":
			return _pick_in_band(float(d["min"]), float(d["max"]), true)
		&"gale_swoop", &"shrieking_dive":
			return _best_cluster(float(d["max"]), float(d["cluster"]))
		&"maul":
			var t := _current_target()
			return t if t != null and _in_reach(t) else null
		&"rending_roar":
			return unit if not _victims(unit.global_position, float(d["radius"])).is_empty() else null
		&"updraft":
			return _nest_point() if unit.hp <= unit.max_hp * float(d["hp"]) and not _updraft_used else null
	return null


# Validates / resolves the target of a cast: {} = invalid, else what _execute needs.
func _plan(id: StringName, target: Variant) -> Dictionary:
	var d: Dictionary = ABILITIES[id]
	if target == null and not bool(d.get("self", false)):
		target = _trigger(id)
	match id:
		&"spore_burst":
			var at := Vector3.INF
			var node: Node3D = null
			if target is Vector3:
				at = target
			elif _is_victim(target):
				node = target as Node3D
				at = node.global_position
			elif _is_enemy_node(target):   # an enemy building
				node = target as Node3D
				at = node.global_position
			if at == Vector3.INF or _flat_dist(at, unit.global_position) > float(d["range"]):
				return {}
			return {"at": at, "target": node}
		&"antler_sweep":
			if _victims(unit.global_position, float(d["radius"])).size() < int(d["min_enemies"]):
				return {}
			return {"at": unit.global_position, "target": unit}
		&"rending_roar":
			if _victims(unit.global_position, float(d["radius"])).is_empty():
				return {}
			return {"at": unit.global_position, "target": unit}
		&"maul":
			if not (_is_victim(target) or _is_enemy_node(target)) or not _in_reach(target as Node3D):
				return {}
			return {"at": (target as Node3D).global_position, "target": target}
		&"gore_charge":
			if not _is_victim(target):
				return {}
			var u := target as Unit
			var dist := _flat_dist(u.global_position, unit.global_position)
			if dist < float(d["min"]) or dist > float(d["max"]):
				return {}
			var end := _safe_end(unit.global_position, _beside(u))
			if _flat_dist(end, unit.global_position) < MIN_CHARGE_TRAVEL:
				return {}
			return {"at": end, "target": u}
		&"gale_swoop", &"shrieking_dive", &"pounce":
			if not _is_victim(target):
				return {}
			var u := target as Unit
			var dist := _flat_dist(u.global_position, unit.global_position)
			if dist > float(d["max"]) or dist < float(d.get("min", 0.0)):
				return {}
			var want := _beside(u)
			var end := _safe_end(unit.global_position, want)
			if _flat_dist(end, want) > LAND_SLACK:
				return {}   # it cannot land beside its target (water, off the navmesh)
			return {"at": end, "target": u}
		&"updraft":
			var nest := Vector3.INF
			if target is Vector3:
				nest = target
			elif target != null and is_instance_valid(target) and target is Node3D:
				nest = (target as Node3D).global_position
			else:
				nest = _nest_point()
			return {"at": nest, "target": null}
	return {}


# ---------------------------------------------------------------- execution

func _execute(id: StringName, plan: Dictionary) -> void:
	var d: Dictionary = ABILITIES[id]
	var at: Vector3 = plan.get("at", unit.global_position)
	var target: Node3D = plan.get("target") as Node3D if plan.get("target") is Node3D else null
	unit.model_call(&"play_cast", [id])
	match id:
		&"spore_burst", &"antler_sweep":
			var delay := float(d.get("delay", 0.0))
			if delay > 0.0:
				_pending.append({"left": delay, "id": id, "at": at, "target": target})
			else:
				_impact(id, at, target)
		&"maul":
			_vfx(id, target.global_position, target)
			var amount := float(d["damage"]) * _power()
			_hit(id, target, amount)
			if target is Unit and (target as Unit).is_alive():
				(target as Unit).apply_status(d["status"], float(d["duration"]))
		&"rending_roar":
			_roar_unlocked = true
			_vfx(id, unit.global_position, unit)
			for u: Unit in _victims(unit.global_position, float(d["radius"])):
				u.apply_status(d["status"], float(d["duration"]))
				if _variant == 1 and not _is_hero(u):
					u.apply_status(&"taunted", float(d["taunt_b"]), false, unit)
				ability_hit.emit(id, u, 0.0)
		&"updraft":
			_updraft_used = true
			_vfx(id, unit.global_position, unit)
			unit.apply_status(&"shroud", float(d["shroud"]), true)
			var ticks := maxi(1, roundi(float(d["heal_time"]) / HOT_TICK))
			_hots.append({"ticks": ticks, "per_tick": unit.max_hp * float(d["heal_pct"]) / float(ticks),
					"next": HOT_TICK})
			if at != Vector3.INF and _flat_dist(at, unit.global_position) > 1.0:
				unit.command_move(at)
		&"gore_charge":
			_vfx(id, at, unit)
			_start_motion(id, at, float(d["speed"]), target)
		&"gale_swoop", &"shrieking_dive", &"pounce":
			_vfx(id, at, unit)
			_start_motion(id, at, LEAP_SPEED, target)


# Spore Burst / Antler Sweep: the area hit (Spore Burst lands on its target's current spot if it still lives).
func _impact(id: StringName, at: Vector3, target: Node3D) -> void:
	var d: Dictionary = ABILITIES[id]
	if id == &"spore_burst" and target != null and is_instance_valid(target) and _alive(target):
		at = target.global_position
	if id == &"antler_sweep":
		at = unit.global_position
	_vfx(id, at, target if id == &"spore_burst" else unit)
	var amount := float(d["damage"]) * _power()
	for u: Unit in _victims(at, float(d["radius"])):
		_hit(id, u, amount)
		if d.has("status") and u.is_alive():
			u.apply_status(d["status"], float(d["duration"]))


func _tick_pending(delta: float) -> void:
	var due: Array[Dictionary] = []
	for p: Dictionary in _pending:
		p["left"] = float(p["left"]) - delta
		if float(p["left"]) <= 0.0:
			due.append(p)
	for p: Dictionary in due:
		_pending.erase(p)
		var t: Variant = p["target"]
		_impact(p["id"], p["at"], t as Node3D if t != null and is_instance_valid(t) else null)


func _tick_hots(delta: float) -> void:
	for h: Dictionary in _hots.duplicate():
		h["next"] = float(h["next"]) - delta
		if float(h["next"]) > 0.0:
			continue
		h["next"] = float(h["next"]) + HOT_TICK
		unit.heal(float(h["per_tick"]))
		h["ticks"] = int(h["ticks"]) - 1
		if int(h["ticks"]) <= 0:
			_hots.erase(h)


func _start_motion(id: StringName, to: Vector3, speed: float, target: Node3D) -> void:
	var from := unit.global_position
	var dist := _flat_dist(from, to)
	_motion = {"id": id, "from": from, "to": Vector3(to.x, from.y, to.z), "t": 0.0,
			"dur": maxf(MIN_MOTION_TIME, dist / maxf(0.1, speed)), "target": target, "prev": from, "hits": {},
			"target_hit": false}
	unit.add_modifier(MOTION_MODIFIER, {&"move_speed_pct": -1.0})
	# The unit is moved by position (no velocity), so it would not turn by itself: face the dash / leap.
	var face := to - from
	if face.length() < 0.01 and target != null and is_instance_valid(target):
		face = target.global_position - from
	if unit.has_method(&"face_direction"):
		unit.call(&"face_direction", face)


func _tick_motion(delta: float) -> void:
	var m := _motion
	m["t"] = float(m["t"]) + delta
	var k := clampf(float(m["t"]) / float(m["dur"]), 0.0, 1.0)
	var from: Vector3 = m["from"]
	var to: Vector3 = m["to"]
	var p := from.lerp(to, k)
	p.y = unit.global_position.y
	unit.global_position = p
	unit.velocity = Vector3.ZERO
	if m["id"] == &"gore_charge":
		var stop := _gore_hits(m, m["prev"], p)
		m["prev"] = p
		if stop:
			_end_motion(true)
			return
	m["prev"] = p
	if k >= 1.0:
		_end_motion(true)


func _end_motion(landed: bool) -> void:
	var m := _motion
	_motion = {}
	if unit == null or not is_instance_valid(unit):
		return
	unit.remove_modifier(MOTION_MODIFIER)
	unit.velocity = Vector3.ZERO
	if not landed or not unit.is_alive():
		return
	var id: StringName = m["id"]
	var d: Dictionary = ABILITIES[id]
	var t: Variant = m["target"]
	var target: Unit = t as Unit if t != null and is_instance_valid(t) else null
	var power := _power()
	match id:
		&"gore_charge":
			if not bool(m["target_hit"]) and target != null and target.is_alive() \
					and _flat_dist(target.global_position, unit.global_position) \
					<= unit.radius + target.radius + LAND_GAP + LAND_SLACK:
				_gore_main_hit(target)
		&"pounce":
			if target != null and target.is_alive() and _flat_dist(target.global_position, unit.global_position) \
					<= unit.radius + target.radius + LAND_GAP + LAND_SLACK:
				_hit(id, target, float(d["damage"]) * power)
				if target.is_alive():
					target.apply_status(d["status"], float(d["duration"]))
		&"gale_swoop", &"shrieking_dive":
			var from: Vector3 = m["from"]
			var dir := Vector3(unit.global_position.x - from.x, 0.0, unit.global_position.z - from.z)
			var center := unit.global_position
			if target != null and target.is_alive() and _flat_dist(target.global_position, unit.global_position) \
					<= unit.radius + target.radius + LAND_GAP + LAND_SLACK:
				center = target.global_position
			elif dir.length() > 0.01 and target != null:
				center = unit.global_position + dir.normalized() * (unit.radius + target.radius + LAND_GAP)
			for u: Unit in _victims(center, float(d["radius"])):
				_hit(id, u, float(d["damage"]) * power)
				if u.is_alive():
					u.apply_status(d["status"], float(d["duration"]))


# Gore Charge along the segment a -> b: units within 1.5 m of the path take the path hit; reaching the main target
# hits it and ends the charge (returns true).
func _gore_hits(m: Dictionary, a: Vector3, b: Vector3) -> bool:
	var d: Dictionary = ABILITIES[&"gore_charge"]
	var hits: Dictionary = m["hits"]
	var t: Variant = m["target"]
	var main: Unit = t as Unit if t != null and is_instance_valid(t) else null
	var width := float(d["path_width"])
	var power := _power()
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not _is_victim(u):
			continue
		var key := u.get_instance_id()
		if u == main:
			if not bool(m["target_hit"]) and _flat_dist(u.global_position, b) <= unit.radius + u.radius + LAND_GAP + 0.3:
				m["target_hit"] = true
				hits[key] = true
				_gore_main_hit(u)
				return true
			continue
		if hits.has(key) or _seg_dist(u.global_position, a, b) > width:
			continue
		hits[key] = true
		if _variant == 1:
			_hit(&"gore_charge", u, float(d["damage"]) * power)
			if u.is_alive():
				u.apply_status(d["status"], float(d["duration_b"]))
		else:
			_hit(&"gore_charge", u, float(d["path_damage"]) * power)
	return false


func _gore_main_hit(u: Unit) -> void:
	var d: Dictionary = ABILITIES[&"gore_charge"]
	_hit(&"gore_charge", u, float(d["damage"]) * _power())
	if u.is_alive():
		u.apply_status(d["status"], float(d["duration_b"] if _variant == 1 else d["duration"]))


func _hit(id: StringName, target: Node3D, amount: float) -> void:
	if target == null or not is_instance_valid(target) or not _alive(target):
		return
	target.call(&"take_damage", amount, unit)
	ability_hit.emit(id, target, amount)


# ---------------------------------------------------------------- passives

# Bristle Hide: a melee attacker hitting us takes 4. Enrage follows the HP.
func _on_damage_taken(amount: float, attacker: Node3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	if _ids.has(&"enrage"):
		_update_enrage()
	if amount <= 0.0 or not _ids.has(&"bristle_hide") or attacker == null or not is_instance_valid(attacker):
		return
	var a := attacker as Unit
	if a == null or not a.is_alive() or a.attack_range > MELEE_MAX_RANGE or a.attack_target != unit \
			or not unit.is_enemy_of(a):
		return
	var reflect := float(ABILITIES[&"bristle_hide"]["reflect"])
	a.take_damage(reflect, unit)
	unit.model_call(&"play_cast", [&"bristle_hide"])   # Tusker: a bristle spike over any pose (12.C9)
	ability_hit.emit(&"bristle_hide", a, reflect)


# Hamstring: each landed attack slows the victim by 25 % for 3 s (modifier `beast:hamstring`, refreshed, never
# stacked; a child node of the victim removes it, so it outlives the beast).
func _on_attack_landed(target: Node3D, _amount: float) -> void:
	if not _ids.has(&"hamstring") or target == null or not is_instance_valid(target):
		return
	var u := target as Unit
	if u == null or not u.is_alive():
		return
	var d: Dictionary = ABILITIES[&"hamstring"]
	var fresh := apply_timed_modifier(u, HAMSTRING_NODE, HAMSTRING_MODIFIER,
			{&"move_speed_pct": float(d["speed_pct"])}, float(d["duration"]))
	if fresh:
		_vfx(&"hamstring", u.global_position, u)
	ability_hit.emit(&"hamstring", u, 0.0)


## Puts modifier `mod_id` on `victim` for `seconds` through a child node `node_name` (refreshes an existing one).
## True when the modifier is new.
static func apply_timed_modifier(victim: Unit, node_name: String, mod_id: StringName, stats: Dictionary,
		seconds: float) -> bool:
	var existing := victim.get_node_or_null(node_name) as TimedModifier
	if existing != null and not existing.is_queued_for_deletion() and existing.left > 0.0 \
			and victim.has_modifier(mod_id):
		existing.left = maxf(existing.left, seconds)
		return false
	victim.add_modifier(mod_id, stats)
	var node := TimedModifier.new()
	node.name = node_name
	node.mod_id = mod_id
	node.left = seconds
	victim.add_child(node)
	return true


func _update_enrage() -> void:
	if not _ids.has(&"enrage") or unit == null or not is_instance_valid(unit):
		return
	var d: Dictionary = ABILITIES[&"enrage"]
	var low := unit.is_alive() and unit.hp < unit.max_hp * float(d["hp"])
	if low and not unit.has_modifier(ENRAGE_MODIFIER):
		unit.add_modifier(ENRAGE_MODIFIER, {&"attack_cooldown_pct": float(d["cooldown_pct"])})
		# Grizzlemaw: the enrage look at once (it also polls the modifier) and a snarling head shake.
		unit.model_call(&"set_enraged", [true])
		unit.model_call(&"play_cast", [&"enrage"])
	elif not low and unit.has_modifier(ENRAGE_MODIFIER):
		unit.remove_modifier(ENRAGE_MODIFIER)
		unit.model_call(&"set_enraged", [false])


# ---------------------------------------------------------------- helpers

func _type_id() -> StringName:
	return unit.unit_type.id if unit != null and unit.unit_type != null else &""


# Damage scale: effective / base attack damage (camp levels, auras).
func _power() -> float:
	if unit.unit_type == null or unit.unit_type.attack_damage <= 0.0:
		return 1.0
	return maxf(0.0, unit.attack_damage / unit.unit_type.attack_damage)


func _current_target() -> Node3D:
	var t: Node3D = unit.attack_target
	if t == null or not is_instance_valid(t) or not _alive(t) or not unit.is_enemy_of(t):
		return null
	return t


func _in_reach(t: Node3D) -> bool:
	return t != null and _flat_dist(t.global_position, unit.global_position) \
			<= unit.attack_range + unit.radius + Unit.radius_of(t) + REACH_SLACK


# A unit this creature's abilities may hit: a living PLAYER / ENEMY unit that is our enemy; beasts: combatants only
# (not workers, not caravans).
func _is_victim(v: Variant) -> bool:
	if v == null or not is_instance_valid(v) or not v is Unit:
		return false
	var u := v as Unit
	if u == unit or not u.is_alive() or int(u.team) == Unit.Team.NEUTRAL or not unit.is_enemy_of(u):
		return false
	if _is_beast and (u.is_worker() or (u.unit_type != null and u.unit_type.is_caravan)):
		return false
	return true


func _is_enemy_node(v: Variant) -> bool:
	return v != null and is_instance_valid(v) and v is Node3D and _alive(v) and unit.is_enemy_of(v as Node3D)


# Victims whose body is within r of `at` (centre distance minus their radius).
func _victims(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u != null and _is_victim(u) and _flat_dist(u.global_position, at) - u.radius <= r:
			out.append(u)
	return out


# Gore Charge / Pounce autocast: a victim at a centre distance in [lo, hi]; the current target first, then (Pounce)
# ranged units and wizards, then the nearest. Units hidden from auto-target (Smoke Pouch) are skipped.
func _pick_in_band(lo: float, hi: float, prefer_ranged: bool) -> Unit:
	var cur := _current_target() as Unit
	if cur != null and _is_victim(cur):
		var cd := _flat_dist(cur.global_position, unit.global_position)
		if cd >= lo and cd <= hi and not prefer_ranged:
			return cur
	var best: Unit = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not _is_victim(u) or u.is_hidden_from_auto_target():
			continue
		var dist := _flat_dist(u.global_position, unit.global_position)
		if dist < lo or dist > hi:
			continue
		var score := dist
		if prefer_ranged and (u.attack_range > MELEE_MAX_RANGE or _is_hero(u)):
			score -= 100.0
		if u == cur:
			score -= 50.0
		if score < best_score:
			best_score = score
			best = u
	return best


# Gale Swoop / Shrieking Dive: the victim within `reach` with the most victims within `cluster` m (itself included);
# ties: the nearest.
func _best_cluster(reach: float, cluster: float) -> Unit:
	var pool: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u != null and _is_victim(u) and not u.is_hidden_from_auto_target() \
				and _flat_dist(u.global_position, unit.global_position) <= reach:
			pool.append(u)
	var best: Unit = null
	var best_n := 0
	var best_d := INF
	for u: Unit in pool:
		var n := 0
		for o: Unit in pool:
			if _flat_dist(o.global_position, u.global_position) <= cluster:
				n += 1
		var dist := _flat_dist(u.global_position, unit.global_position)
		if n > best_n or (n == best_n and dist < best_d):
			best = u
			best_n = n
			best_d = dist
	return best


# Where a dash / leap onto `u` should end: beside it, on the line from us.
func _beside(u: Unit) -> Vector3:
	var me := unit.global_position
	var back := Vector3(me.x - u.global_position.x, 0.0, me.z - u.global_position.z)
	var gap := unit.radius + u.radius + LAND_GAP
	if back.length() <= gap:
		return me
	var p := u.global_position + back.normalized() * gap
	p.y = me.y
	return p


## The furthest point of the straight line from -> to that the unit can reach: every 0.5 m sample must be on the
## navmesh and not deep water; the result is snapped to the navmesh. `from` when the first step is blocked.
func _safe_end(from: Vector3, to: Vector3) -> Vector3:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var dist := flat.length()
	if dist < 0.01:
		return from
	var dir := flat / dist
	var river := _river()
	var map := _nav_map()
	var last := from
	var steps := ceili(dist / NAV_STEP)
	for i in range(1, steps + 1):
		var p := from + dir * minf(dist, float(i) * NAV_STEP)
		p.y = from.y
		if not _walkable(p, river, map):
			break
		last = p
	if last != from and map.is_valid():
		var q := NavigationServer3D.map_get_closest_point(map, last)
		if _flat_dist(q, last) <= NAV_TOLERANCE and (river == null or not bool(river.call(&"is_water", q))):
			last = Vector3(q.x, from.y, q.z)
	return last


func _walkable(p: Vector3, river: Node, map: RID) -> bool:
	if river != null and bool(river.call(&"is_water", p)):
		return false
	if map.is_valid():
		var q := NavigationServer3D.map_get_closest_point(map, p)
		if _flat_dist(q, p) > NAV_TOLERANCE:
			return false
	return true


# The navigation map once it has a region and a first sync; RID() otherwise (no navmesh check then).
func _nav_map() -> RID:
	var world := unit.get_world_3d()
	if world == null:
		return RID()
	var map := world.navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) <= 0 \
			or NavigationServer3D.map_get_regions(map).is_empty():
		return RID()
	return map


# The RiverSystem (12.C1) through its group; null without one.
func _river() -> Node:
	if not is_inside_tree():
		return null
	var r := get_tree().get_first_node_in_group(&"river")
	return r if r != null and r.has_method(&"is_water") else null


# The Roc's nest: its lair centre (EpicBeasts.lair_of, load-guarded through the group), else its home spot.
func _nest_point() -> Vector3:
	if is_inside_tree():
		var eb := get_tree().get_first_node_in_group(&"epic_beasts")
		if eb != null and eb.has_method(&"lair_of"):
			var lair: Variant = eb.call(&"lair_of", unit)
			if lair is Dictionary and (lair as Dictionary).get("center") is Vector3:
				return (lair as Dictionary)["center"]
	return unit.home_position()


func _vfx(id: StringName, at: Vector3, target: Variant) -> void:
	if not is_inside_tree():
		return
	var vfx := get_tree().get_first_node_in_group(&"mapfill_vfx")
	if vfx != null and vfx.has_method(&"play"):
		vfx.call(&"play", id, at, target)


static func _is_hero(u: Node) -> bool:
	return u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes") or u.is_in_group(&"champions") \
			or u.has_method(&"command_cast")


static func _alive(v: Variant) -> bool:
	return v != null and is_instance_valid(v) and (v as Object).has_method(&"is_alive") \
			and bool((v as Object).call(&"is_alive"))


static func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var len2 := ab.length_squared()
	var k := 0.0 if len2 < 0.0001 else clampf(ap.dot(ab) / len2, 0.0, 1.0)
	return (ap - ab * k).length()
