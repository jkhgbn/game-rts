class_name NewUnits12
extends Node
## Twelve new Hall units, 3 per kingdom, tier 1 to tier 2 (docs/design/new-units-12.md; JS 2026-09-27 "add 3 new
## units each, T1 to T2, to each wizard"). Static side: which Hall lists which unit (slots 6-8, keys N M ,), the T2
## gate, the bot shares. Instance side: one NewUnits12 node is added under each new unit (Unit._ready hook) and runs
## its ability (autocast every 0.5 s, staggered, or a passive on the unit's own signals).
## The whole feature hangs on ENABLED.

## THE switch (new-units-12.md 1): false = no Hall lists a new unit, bots never train one, abilities never attach.
const ENABLED := true

## id -> faction, tier, card key (new-units-12.md 2). Order inside a kingdom = card order (slots 6, 7, 8).
const UNITS := {
	&"scorchling": {"faction": &"fire", "tier": 1, "key": "N"},
	&"pyre_adept": {"faction": &"fire", "tier": 2, "key": "M"},
	&"cinder_arbalest": {"faction": &"fire", "tier": 2, "key": ","},
	&"barrow_ghoul": {"faction": &"shadow", "tier": 1, "key": "N"},
	&"hexweaver": {"faction": &"shadow", "tier": 2, "key": "M"},
	&"hollow_oathsworn": {"faction": &"shadow", "tier": 2, "key": ","},
	&"rimeling": {"faction": &"ice", "tier": 1, "key": "N"},
	&"hoarlight_magebow": {"faction": &"ice", "tier": 2, "key": "M"},
	&"frost_mortar": {"faction": &"ice", "tier": 2, "key": ","},
	&"thistle_darter": {"faction": &"nature", "tier": 1, "key": "N"},
	&"vinelasher": {"faction": &"nature", "tier": 2, "key": "M"},
	&"greenheart_oathkeeper": {"faction": &"nature", "tier": 2, "key": ","},
}
const HALL_UNITS := {
	&"fire": [&"scorchling", &"pyre_adept", &"cinder_arbalest"],
	&"shadow": [&"barrow_ghoul", &"hexweaver", &"hollow_oathsworn"],
	&"ice": [&"rimeling", &"hoarlight_magebow", &"frost_mortar"],
	&"nature": [&"thistle_darter", &"vinelasher", &"greenheart_oathkeeper"],
}
## Ability id per unit (model play_cast(spell_id), logs, icons art/icons/abilities/<id>.png).
const ABILITY_IDS := {
	&"scorchling": &"flashpoint", &"pyre_adept": &"flame_burst", &"cinder_arbalest": &"piercing_bolt",
	&"barrow_ghoul": &"grave_feast", &"hexweaver": &"wither_hex", &"hollow_oathsworn": &"unbroken_vow",
	&"rimeling": &"frostbite", &"hoarlight_magebow": &"frost_needle", &"frost_mortar": &"frost_shell",
	&"thistle_darter": &"skitter", &"vinelasher": &"snare_lash", &"greenheart_oathkeeper": &"grove_oath",
}
## Command card tooltip line per unit (command_card.gd falls back to it).
const DESCRIPTIONS := {
	&"scorchling": "Tier 1. Fast fire imp. Flashpoint: bursts for 15 on death.",
	&"pyre_adept": "Tier 2 caster. Flame Burst: 30 to a clump of 3+ enemies (14 s).",
	&"cinder_arbalest": "Tier 2 crossbow. Piercing bolt: half damage to the enemy behind.",
	&"barrow_ghoul": "Tier 1 melee. Grave Feast: heals 30 % on a kill.",
	&"hexweaver": "Tier 2 caster. Wither Hex: the costliest enemy deals -20 % for 6 s (10 s).",
	&"hollow_oathsworn": "Tier 2 swordsman. Unbroken Vow: under 35 % HP, shield 50 and +15 % damage (45 s).",
	&"rimeling": "Tier 1. Cheap frost goblin; every hit chills 1 s.",
	&"hoarlight_magebow": "Tier 2 mage archer, quick to train. Frost Needle: 20 + chill (8 s).",
	&"frost_mortar": "Tier 2 siege. Frost Shell: full damage and chill in 2 m.",
	&"thistle_darter": "Tier 1 skirmisher. Skitter: faster for 1.5 s after each dart.",
	&"vinelasher": "Tier 2 whip. Snare Lash: 10 and rooted 1.5 s (10 s).",
	&"greenheart_oathkeeper": "Tier 2 swordsman. Grove Oath: taunts enemies in 5 m and braces (14 s).",
}
## Bot target share of soldier pop (small: the four old slots keep their AIProfile mix, the bowman 0.08-0.10).
const BOT_SHARE := {1: 0.06, 2: 0.05}

## The tier-2 gate (new-units-12.md 3). The real gate is the tier system (tiers-wave.md): the T2 .tres files set
## `requires_tier = 2` and TrainingBuilding refuses "Requires Stronghold". This file's own stop-gap gate (a completed
## own Bazaar OR a second completed own Hall) stays behind OWN_T2_GATE, OFF since the tier system landed.
const OWN_T2_GATE := false
const REASON_T2 := "Requires a Bazaar or a second Hall"

## Ability numbers (new-units-12.md 4).
const TICK := 0.5
const FLASHPOINT := {"damage": 15.0, "radius": 2.0}
const FLAME_BURST := {"cd": 14.0, "range": 8.0, "radius": 2.5, "min_count": 3, "damage": 30.0}
## Flame Burst's single scan reaches this much past range + radius (a candidate's own radius; units stay under it).
const FLAME_POOL_MARGIN := 3.0
const PIERCE := {"radius": 3.0, "ratio": 0.5}
const GRAVE_FEAST := {"heal_pct": 0.30}
const WITHER_HEX := {"cd": 10.0, "range": 9.0, "time": 6.0, "attack_pct": -0.20}
const WITHER_MOD := &"status_withered"
const WITHER_META := &"_nu12_withered_until"   # "_" = not saved (SaveCodec): the modifier / timer aren't either
const WITHER_SERIAL_META := &"_nu12_withered_serial"
const VOW := {"cd": 45.0, "hp_pct": 0.35, "shield": 50.0, "time": 6.0, "attack_pct": 0.15}
const VOW_MOD := &"ability:unbroken_vow"
const FROST_NEEDLE := {"cd": 8.0, "range": 10.0, "damage": 20.0, "chill": 1.0}
const FROST_SHELL := {"radius": 2.0, "chill": 1.5, "building_mult": 1.5}
const SKITTER := {"speed": 1.0, "time": 1.5}
const SKITTER_MOD := &"ability:skitter"
const SNARE_LASH := {"cd": 10.0, "range": 5.0, "damage": 10.0, "root": 1.5}
const GROVE_OATH := {"cd": 14.0, "radius": 5.0, "taunt": 2.5, "brace": 4.0}

## Unit research K keys each ability reads (unit-upgrades.md 10) -> today's value. `_refresh_kit` copies the team's
## numbers into the fields of the same name with a leading "_".
const KIT_KEYS := {
	&"scorchling": {&"flashpoint_damage": 15.0, &"flashpoint_radius": 2.0},
	&"pyre_adept": {&"flame_burst_min_count": 3.0, &"flame_burst_radius": 2.5},
	&"cinder_arbalest": {&"pierce_ratio": 0.5},
	&"barrow_ghoul": {&"grave_feast_heal_pct": 0.30},
	&"hexweaver": {&"wither_time": 6.0, &"wither_move_speed": 0.0},
	&"hollow_oathsworn": {&"vow_cd": 45.0, &"vow_shield": 50.0},
	&"hoarlight_magebow": {&"frost_needle_cd": 8.0, &"frost_needle_damage": 20.0},
	&"frost_mortar": {&"frost_shell_radius": 2.0},
	&"thistle_darter": {&"skitter_speed": 1.0, &"skitter_time": 1.5},
	&"vinelasher": {&"snare_damage": 10.0, &"snare_root": 1.5},
	&"greenheart_oathkeeper": {&"grove_oath_radius": 5.0, &"grove_oath_brace": 4.0},
}

const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"
const NODE_NAME := "NewUnitAbility"

## Tests on any scene may set this true (the Halls list the new units only in a real skirmish otherwise).
static var force_enabled := false

var unit: Unit
var id: StringName = &""
var casts := 0              ## Times the ability fired (tests, balance logs).
var enemy_scans := 0        ## Full "units" passes made by _enemies_near (tests: Flame Burst = 1 per try).
var _tick_left := TICK
var _cd_left := 0.0
var _mod_left := 0.0        ## Timed self modifier (Vow, Skitter).
# Kit numbers in use (KIT_KEYS; refreshed by _refresh_kit, read on the hit path as plain fields).
var _kit_sig := ""
var _flashpoint_damage := float(FLASHPOINT["damage"])
var _flashpoint_radius := float(FLASHPOINT["radius"])
var _flame_burst_min_count := float(FLAME_BURST["min_count"])
var _flame_burst_radius := float(FLAME_BURST["radius"])
var _pierce_ratio := float(PIERCE["ratio"])
var _grave_feast_heal_pct := float(GRAVE_FEAST["heal_pct"])
var _wither_time := float(WITHER_HEX["time"])
var _wither_move_speed := 0.0
var _vow_cd := float(VOW["cd"])
var _vow_shield := float(VOW["shield"])
var _frost_needle_cd := float(FROST_NEEDLE["cd"])
var _frost_needle_damage := float(FROST_NEEDLE["damage"])
var _frost_shell_radius := float(FROST_SHELL["radius"])
var _skitter_speed := float(SKITTER["speed"])
var _skitter_time := float(SKITTER["time"])
var _snare_damage := float(SNARE_LASH["damage"])
var _snare_root := float(SNARE_LASH["root"])
var _grove_oath_radius := float(GROVE_OATH["radius"])
var _grove_oath_brace := float(GROVE_OATH["brace"])


# ---------------------------------------------------------------- static: roster, gate, bots

static func is_new_unit(type_id: StringName) -> bool:
	return ENABLED and UNITS.has(type_id)


static func description(type_id: StringName) -> String:
	if not is_new_unit(type_id):
		return ""
	var gate := (REASON_T2 if OWN_T2_GATE else "Tier 2: requires Stronghold") if tier_of(type_id) >= 2 else ""
	return String(DESCRIPTIONS.get(type_id, "")) + ("\n" + gate if gate != "" else "")


static func tier_of(type_id: StringName) -> int:
	return int((UNITS.get(type_id, {}) as Dictionary).get("tier", 0))


## True when the Halls of the current game list the new units: the plain skirmish or a generated map (LayoutLevel;
## missions extend it: off, see CasterKit.is_plain_skirmish and thornwater_2026-10-11.md).
static func enabled_here() -> bool:
	if not ENABLED:
		return false
	if force_enabled:
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return false
	return CasterKit.is_plain_skirmish(tree.current_scene)


## The new units a Hall of `building_type` adds after its bowman (TrainingBuilding.trainable_types). [] otherwise.
static func hall_units(building_type: Resource) -> Array[UnitType]:
	var out: Array[UnitType] = []
	if building_type == null or StringName(building_type.get(&"kind")) != &"barracks" or not enabled_here():
		return out
	for uid: StringName in HALL_UNITS.get(StringName(building_type.get(&"faction")), []):
		var t := UnitType.find(String(uid))
		if t:
			out.append(t)
	return out


## "" when `team` may train `type` now, else the refusal (TrainingBuilding.can_queue, bots, card).
static func gate_reason(type: UnitType, team: int) -> String:
	if not OWN_T2_GATE or type == null or tier_of(type.id) < 2 or not ENABLED:
		return ""
	return "" if t2_open(team) else REASON_T2


## Tier 2 is open for `team`: a completed own Bazaar, or two completed own Halls.
static func t2_open(team: int) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var halls := 0
	for n in tree.get_nodes_in_group(&"buildings"):
		var b := n as Building
		if b == null or int(b.team) != team or not b.is_alive() or not b.is_constructed() or b.building_type == null:
			continue
		var kind := b.building_type.kind
		if kind == &"market" or b.is_in_group(&"markets"):
			return true
		if kind == &"barracks":
			halls += 1
			if halls >= 2:
				return true
	return false


## Bot target share for a Hall slot past the AIProfile mix (commander _pick_soldier). 0 for anything else.
static func bot_share(type_id: StringName) -> float:
	if not is_new_unit(type_id):
		return 0.0
	return float(BOT_SHARE.get(tier_of(type_id), 0.0))


## Unit._ready: adds the ability node under a new unit.
static func attach(u: Unit) -> void:
	if u == null or u.unit_type == null or not is_new_unit(u.unit_type.id) or u.has_node(NODE_NAME):
		return
	var n := NewUnits12.new()
	n.name = NODE_NAME
	n.unit = u
	n.id = u.unit_type.id
	u.add_child(n)


## Seconds before the ability may fire again (0 = ready). Read only (UI, tests).
func cooldown_left() -> float:
	return maxf(0.0, _cd_left)


## Seconds left on the timed self modifier (Unbroken Vow, Skitter). Read only (UI, tests).
func self_modifier_left() -> float:
	return maxf(0.0, _mod_left)


## The ability node of a new unit, or null.
static func ability_of(u: Node) -> NewUnits12:
	return u.get_node_or_null(NODE_NAME) as NewUnits12 if u else null


# ---------------------------------------------------------------- instance: the ability

func _ready() -> void:
	if unit == null:
		unit = get_parent() as Unit
	# Stagger the 0.5 s checks so a clump of casters does not tick on the same frame.
	_tick_left = TICK * float(CasterKit.next_stagger() % 10) / 10.0 + 0.05
	_refresh_kit()
	match id:
		&"scorchling":
			unit.died.connect(_on_died_flashpoint)
		&"cinder_arbalest", &"barrow_ghoul", &"frost_mortar", &"thistle_darter":
			unit.attack_landed.connect(_on_attack_landed)
		&"hollow_oathsworn":
			unit.damage_taken.connect(_on_damage_taken)


func _physics_process(delta: float) -> void:
	if unit == null or not unit.is_alive():
		return
	if _cd_left > 0.0:
		_cd_left -= delta
	if _mod_left > 0.0:
		_mod_left -= delta
		if _mod_left <= 0.0:
			unit.remove_modifier(VOW_MOD if id == &"hollow_oathsworn" else SKITTER_MOD)
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	if unit.get_meta(UnitResearch.SIG_META, "") != _kit_sig:
		_refresh_kit()   # UnitResearch re-applied this unit (a row done, a load): one meta read per 0.5 s
	if _cd_left > 0.0 or not unit.can_act():
		return
	match id:
		&"pyre_adept":
			_try_flame_burst()
		&"hexweaver":
			_try_wither_hex()
		&"hoarlight_magebow":
			_try_frost_needle()
		&"vinelasher":
			_try_snare_lash()
		&"greenheart_oathkeeper":
			_try_grove_oath()


# Scorchling: on death, 15 to enemy units within 2 m (never buildings, never own units).
func _on_died_flashpoint(_u: Unit) -> void:
	var at := unit.global_position
	var dmg := _flashpoint_damage
	for e in _enemies_near(at, _flashpoint_radius):
		e.take_damage(dmg, unit)
	casts += 1


# Pyre Adept: a point (an enemy's spot) within 8 m with >= 3 enemy units within 2.5 m: 30 to each of them.
# One enemy scan (range + radius + the widest unit), then the clusters are counted inside that list with squared
# distances: no second "units" pass per candidate (review 2026-10-08 M3, was O(k * n) is_enemy_of calls).
func _try_flame_burst() -> void:
	var r := _flame_burst_radius
	var reach := float(FLAME_BURST["range"])
	var me := unit.global_position
	var pool := _enemies_near(me, reach + r + FLAME_POOL_MARGIN)
	var best: Array[Unit] = []
	for c in pool:
		if _flat(c.global_position, me) > reach + c.radius:
			continue   # same candidate rule as before: an enemy within range
		var cp := c.global_position
		var group: Array[Unit] = []
		for u in pool:
			var lim := r + u.radius
			var dx := u.global_position.x - cp.x
			var dz := u.global_position.z - cp.z
			if dx * dx + dz * dz <= lim * lim:
				group.append(u)
		if group.size() > best.size():
			best = group
	if best.size() < roundi(_flame_burst_min_count):
		return
	for e in best:
		e.take_damage(float(FLAME_BURST["damage"]), unit)
	_cast_fx()
	_cd_left = float(FLAME_BURST["cd"])


# Hexweaver: the highest-cost enemy soldier in range not already withered: attack -20 % for 6 s (heroes 3 s).
func _try_wither_hex() -> void:
	var now := _now()
	var pick: Unit = null
	for e in _enemies_near(unit.global_position, float(WITHER_HEX["range"])):
		if e is Wizard:
			continue   # wizards are immune
		if e.unit_type and e.unit_type.is_worker:
			continue
		if float(e.get_meta(WITHER_META, 0.0)) > now:
			continue
		if pick == null or _cost(e) > _cost(pick):
			pick = e
	if pick == null:
		return
	var t := _wither_time
	if pick.is_in_group(&"champions"):
		t *= 0.5
	apply_withered(pick, t, _wither_move_speed)
	_cast_fx()
	_cd_left = float(WITHER_HEX["cd"])


## `withered` (new-units-12.md 4): attack_damage_pct -0.20 for `seconds`, never stacks with itself.
## `move_speed` (flat, <= 0): Deepening Hex's extra slow (unit-upgrades.md 9.2), 0 = none.
static func apply_withered(target: Unit, seconds: float, move_speed: float = 0.0) -> void:
	var until := _now() + seconds
	target.set_meta(WITHER_META, until)
	# Cast serial (R3-1): the timer runs on game time (Blitz time_scale 1.3) while _now() counts frames, so the
	# callback compares serials, never times: only the newest cast's timer removes the modifier.
	var serial := int(target.get_meta(WITHER_SERIAL_META, 0)) + 1
	target.set_meta(WITHER_SERIAL_META, serial)
	var stats := {&"attack_damage_pct": float(WITHER_HEX["attack_pct"])}
	if move_speed != 0.0:
		stats[&"move_speed"] = move_speed
	target.add_modifier(WITHER_MOD, stats)
	var tree := target.get_tree()
	if tree == null:
		return
	var ref: WeakRef = weakref(target)
	tree.create_timer(seconds, false, true).timeout.connect(func() -> void:
		var u := ref.get_ref() as Unit
		if u == null or not is_instance_valid(u):
			return
		if int(u.get_meta(WITHER_SERIAL_META, 0)) != serial:
			return   # a newer cast refreshed it; its own timer removes it
		u.set_meta(WITHER_META, 0.0)
		u.remove_modifier(WITHER_MOD))


# Hollow Oathsworn: the first hit that leaves it under 35 % HP (every 45 s): shield 50 + attack +15 % for 6 s (2026-10-06, was 100 / +30 %: Unit Lab balance pass).
func _on_damage_taken(_amount: float, _attacker: Node3D) -> void:
	if _cd_left > 0.0 or not unit.is_alive() or unit.hp > unit.max_hp * float(VOW["hp_pct"]):
		return
	unit.add_shield(_vow_shield, float(VOW["time"]))
	unit.add_modifier(VOW_MOD, {&"attack_damage_pct": float(VOW["attack_pct"])})
	_mod_left = float(VOW["time"])
	_cd_left = _vow_cd
	_cast_fx()


# Hoarlight Magebow: a weak spell: 20 + chill 1 s on its target (else the nearest enemy unit) within 10 m.
func _try_frost_needle() -> void:
	# Validity first: `as Unit` on a freed attack_target raises "Trying to cast a freed object".
	var target: Unit = unit.attack_target as Unit if is_instance_valid(unit.attack_target) else null
	var rng := float(FROST_NEEDLE["range"])
	if target == null or not target.is_alive() or not unit.is_enemy_of(target) \
			or _flat(target.global_position, unit.global_position) > rng + target.radius:
		target = _nearest_enemy(rng)
	if target == null:
		return
	target.take_damage(_frost_needle_damage, unit)
	if target.is_alive():
		target.apply_status(&"chill", maxf(float(FROST_NEEDLE["chill"]), target.status_time_left(&"chill")))
	_cast_fx()
	_cd_left = _frost_needle_cd


# Vinelasher: the nearest enemy unit within 5 m: 10 + rooted 1.5 s (heroes half, by apply_status).
func _try_snare_lash() -> void:
	var target := _nearest_enemy(float(SNARE_LASH["range"]))
	if target == null:
		return
	target.take_damage(_snare_damage, unit)
	target.apply_status(&"rooted", _snare_root)
	_cast_fx()
	_cd_left = float(SNARE_LASH["cd"])


# Greenheart Oathkeeper: enemies within 5 m are taunted onto it for 2.5 s; it braces (damage taken x0.7) 4 s.
func _try_grove_oath() -> void:
	var near := _enemies_near(unit.global_position, _grove_oath_radius)
	if near.is_empty():
		return
	for e in near:
		e.apply_status(&"taunted", float(GROVE_OATH["taunt"]), false, unit)
	unit.apply_status(&"braced", _grove_oath_brace, true)
	_cast_fx()
	_cd_left = float(GROVE_OATH["cd"])


# Passives on a landed attack (Arbalest pierce, Ghoul feast, Mortar shell, Darter skitter).
func _on_attack_landed(target: Node3D, _amount: float) -> void:
	if unit == null:
		return
	match id:
		&"cinder_arbalest":
			var victim := target as Unit
			if victim == null:
				return
			var dir := victim.global_position - unit.global_position
			var best: Unit = null
			var best_d := INF
			for e in _enemies_near(victim.global_position, float(PIERCE["radius"])):
				if e == victim or dir.dot(e.global_position - victim.global_position) < 0.0:
					continue   # only enemies behind the first one (the bolt flies on)
				var d := _flat(e.global_position, victim.global_position)
				if d < best_d:
					best_d = d
					best = e
			if best:
				best.take_damage(unit.attack_damage * _pierce_ratio, unit)
				casts += 1
		&"barrow_ghoul":
			var victim := target as Unit
			if victim and not victim.is_alive() and unit.is_alive():
				unit.heal(unit.max_hp * _grave_feast_heal_pct)
				casts += 1
		&"frost_mortar":
			var at := target.global_position
			for e in _enemies_near(at, _frost_shell_radius):
				if e != target:
					e.take_damage(unit.attack_damage, unit)
				if e.is_alive():
					e.apply_status(&"chill", maxf(float(FROST_SHELL["chill"]), e.status_time_left(&"chill")))
			if target is Building and target.has_method(&"take_damage"):
				target.call(&"take_damage", unit.attack_damage * (float(FROST_SHELL["building_mult"]) - 1.0), unit)
			casts += 1
		&"thistle_darter":
			if unit.is_alive():
				unit.add_modifier(SKITTER_MOD, {&"move_speed": _skitter_speed})
				_mod_left = _skitter_time
				casts += 1


# ---------------------------------------------------------------- helpers

## Re-reads this unit's kit numbers (the team's unit research rows, UR.G3, unit-upgrades.md 10 K keys; else today's
## constants) into the `_<key>` fields. Called at spawn and when UnitResearch re-applies the unit (its row signature
## meta changes: a row done mid-life, a load); the ability code then only reads plain fields.
func _refresh_kit() -> void:
	_kit_sig = str(unit.get_meta(UnitResearch.SIG_META, "")) if unit else ""
	var keys: Dictionary = KIT_KEYS.get(id, {})
	for key: StringName in keys:
		set(StringName("_" + String(key)), UnitResearch.param(unit, key, float(keys[key])))


func _cast_fx() -> void:
	casts += 1
	if unit.model_has(&"play_cast"):
		unit.model_call(&"play_cast", [ABILITY_IDS.get(id, id)])


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	enemy_scans += 1
	var out: Array[Unit] = []
	for n in unit.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or u == unit or not u.is_alive() or not unit.is_enemy_of(u):
			continue
		if _flat(u.global_position, at) <= r + u.radius:
			out.append(u)
	return out


func _nearest_enemy(r: float) -> Unit:
	var best: Unit = null
	var best_d := INF
	for e in _enemies_near(unit.global_position, r):
		var d := _flat(e.global_position, unit.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


static func _cost(u: Unit) -> int:
	return u.unit_type.cost if u.unit_type else 0


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _now() -> float:
	return CasterKit.now_s()   # the shared pausable match clock (R3-7)
