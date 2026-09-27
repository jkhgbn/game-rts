class_name T3UnitAbility
extends Node
## The abilities of the 5 tier-3 units (docs/design/t3-helpers.md 7.2): child "T3Ability" of each one (Unit._ready ->
## T3Kit.attach). Ticks 10 times a second (Shardguard charge watch), autocasts every 0.5 s.
## Ashveil Saboteur: disguise (enemy auto-aggro ignores it; the enemy sees a worker of its own kingdom), Powder Charge
## (3 s plant, 5 s fuse, 250 + the building's training paused 10 s), Eavesdrop (T3Kit.eavesdropped).
## Nightblood Reaver: Nightblood (heals 35 % of damage dealt; a fire hit halves it for 4 s), Blood Frenzy under 40 %.
## Shardguard: Hold the Line (a charge / lunge / blink ending within 2.4 m: frozen 1 s, heroes 0.5; once per 10 s),
## Challenge (every 14 s: taunt 2.5 s on enemies within 5 m attacking an own ranged unit).
## Briar Roc: Seed Storm every 16 s. Stormbottle Genie: chain 22 / 16 on each bolt, Tempest Bolt (12 s).

const NODE_NAME := "T3Ability"
const TICK := 0.1
const CAST_TICK := 0.5

const DISGUISE := {"reveal_building": 6.0, "reveal_hero": 8.0, "rehide": 8.0}
const CHARGE := {"cd": 45.0, "reach": 2.5, "plant": 3.0, "fuse": 5.0, "damage": 250.0, "pause": 10.0}
const NIGHTBLOOD := {"drink": 0.35, "sunburn_mult": 0.5, "sunburn": 4.0}
const FRENZY := {"cd": 30.0, "hp_pct": 0.4, "time": 5.0, "attack_cooldown_pct": -0.23, "drink": 0.6}
const FRENZY_MOD := &"ability:blood_frenzy"
const HOLD := {"radius": 2.4, "every": 10.0, "freeze": 1.0, "fast": 7.5, "jump": 3.0}
const CHALLENGE := {"cd": 14.0, "radius": 5.0, "taunt": 2.5}
const SEED_STORM := {"cd": 16.0, "range": 8.0, "radius": 3.0, "damage": 30.0, "root": 1.0}
const GENIE_CHAIN := {"radius": 5.0, "damage": [22.0, 16.0]}
const TEMPEST := {"cd": 12.0, "range": 12.0, "damage": 120.0, "titan_mult": 1.5, "chain": 40.0, "jumps": 2}

var unit: Unit
var id: StringName = &""
var casts := {}               ## ability id -> count (tests, logs).
var disguised := false        ## Saboteur: true while hidden as a worker.
var planting := false         ## Saboteur: a charge is being planted.

var _tick_left := TICK
var _cast_left := CAST_TICK
var _cd := {}                 # ability id -> seconds left
var _reveal_left := 0.0       # Saboteur: seconds before it can re-disguise
var _sunburn_left := 0.0
var _frenzy_left := 0.0
var _hold_left := 0.0
var _last_pos := {}           # Shardguard: enemy instance id -> Vector3 (last tick)
var _disguise_model: Node3D = null
var _braced_shown := false


func _ready() -> void:
	if unit == null:
		unit = get_parent() as Unit
	_tick_left = TICK * float(get_instance_id() % 7) / 7.0
	unit.attack_landed.connect(_on_attack_landed)
	unit.damage_taken.connect(_on_damage_taken)
	if id == &"ashveil_saboteur":
		_set_disguised(true)


func _physics_process(delta: float) -> void:
	if unit == null or not unit.is_alive():
		return
	for k in _cd:
		_cd[k] = float(_cd[k]) - delta
	_sunburn_left -= delta
	_hold_left -= delta
	if _frenzy_left > 0.0:
		_frenzy_left -= delta
		if _frenzy_left <= 0.0:
			unit.remove_modifier(FRENZY_MOD)
			if unit.model_has(&"set_status"):
				unit.model_call(&"set_status", [&"frenzy", false])
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	match id:
		&"ashveil_saboteur":
			_tick_disguise()
		&"shardguard":
			_watch_charges()
	_cast_left -= TICK
	if _cast_left > 0.0:
		return
	_cast_left += CAST_TICK
	if not unit.can_act():
		return
	match id:
		&"ashveil_saboteur":
			_try_charge()
		&"nightblood_reaver":
			_try_frenzy()
		&"shardguard":
			_try_challenge()
		&"briar_roc":
			_try_seed_storm()
		&"stormbottle_genie":
			_try_tempest()


func cooldown_left(ability: StringName) -> float:
	return maxf(0.0, float(_cd.get(ability, 0.0)))


func _count(ability: StringName) -> void:
	casts[ability] = int(casts.get(ability, 0)) + 1
	if unit.model_has(&"play_cast"):
		unit.model_call(&"play_cast", [ability])


# ---------------------------------------------------------------- Ashveil Saboteur

## True while `viewer_team` (an enemy) sees a worker, not the Saboteur.
func is_disguised_for(viewer_team: int) -> bool:
	return disguised and viewer_team != int(unit.team)


## Reveals it now (attacking, planting, spotted); it hides again after 8 s unseen.
func reveal() -> void:
	_reveal_left = float(DISGUISE["rehide"])
	if disguised:
		_set_disguised(false)


func _tick_disguise() -> void:
	if _spotted():
		_reveal_left = float(DISGUISE["rehide"])
	if _reveal_left > 0.0:
		_reveal_left -= TICK
		if disguised:
			_set_disguised(false)
		return
	if not disguised:
		_set_disguised(true)
	unit.hide_from_auto_target(TICK * 3.0)


func _spotted() -> bool:
	var at := unit.global_position
	for n in unit.get_tree().get_nodes_in_group(&"buildings"):
		var b := n as Node3D
		if b == null or not unit.is_enemy_of(b) or not bool(b.call(&"is_alive")):
			continue
		var bt: Variant = b.get(&"building_type")
		var shoots := bt is BuildingType and ((bt as BuildingType).kind == &"keep" or (bt as BuildingType).attack_damage > 0.0)
		if shoots and _flat(b.global_position, at) - Unit.radius_of(b) <= float(DISGUISE["reveal_building"]):
			return true
	for n in unit.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not unit.is_enemy_of(u):
			continue
		if (u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes") or u.is_in_group(&"champions")) \
				and _flat(u.global_position, at) <= float(DISGUISE["reveal_hero"]):
			return true
	return false


# The enemy player sees a worker of its own kingdom: the Saboteur's model swaps for that worker's while disguised
# (only when the viewer is the local player, team 0; the owner always sees the true form).
func _set_disguised(on: bool) -> void:
	var was := disguised
	disguised = on
	if on:
		unit.hide_from_auto_target(TICK * 3.0)
	elif was and unit.model_has(&"play_reveal"):
		unit.model_call(&"play_reveal")   # the disguise burns away in embers
	if int(unit.team) == 0 or not unit.is_inside_tree():
		return
	# The player (team 0) inspecting a disguised enemy Saboteur reads a worker's name.
	var worker_name := _viewer_worker_name()
	if worker_name != "" and unit.unit_type:
		unit.unit_name = worker_name if on else unit.unit_type.display_name
	var model := unit.get_model()
	if on and _disguise_model == null:
		_disguise_model = _make_worker_look()
	if _disguise_model:
		_disguise_model.visible = on
		if model:
			model.visible = not on


func _viewer_worker_name() -> String:
	var scene := unit.get_tree().current_scene
	var k: StringName = StringName(str(scene.call(&"kingdom_of", 0))) if scene and scene.has_method(&"kingdom_of") else &"fire"
	var keep := BuildingType.find("%s_keep" % k)
	if keep == null or keep.trains.is_empty() or keep.trains[0] == null:
		return ""
	return keep.trains[0].display_name


func _make_worker_look() -> Node3D:
	var scene := unit.get_tree().current_scene
	var k: StringName = StringName(str(scene.call(&"kingdom_of", 0))) if scene and scene.has_method(&"kingdom_of") else &"fire"
	var keep := BuildingType.find("%s_keep" % k)
	if keep == null or keep.trains.is_empty() or keep.trains[0] == null or keep.trains[0].model_scene == null:
		return null
	var look := keep.trains[0].model_scene.instantiate() as Node3D
	if look == null:
		return null
	look.name = "DisguiseLook"
	var model := unit.get_model()
	if model and model.get_parent():
		model.get_parent().add_child(look)
		look.transform = model.transform
	else:
		unit.add_child(look)
	return look


func _try_charge() -> void:
	if planting or cooldown_left(&"powder_charge") > 0.0:
		return
	var b := _building_in_reach()
	if b == null:
		return
	planting = true
	reveal()
	unit.command_hold()
	_cd[&"powder_charge"] = float(CHARGE["cd"])
	var ref: WeakRef = weakref(b)
	unit.get_tree().create_timer(float(CHARGE["plant"]), false, true).timeout.connect(func() -> void:
		planting = false
		if not is_instance_valid(unit) or not unit.is_alive():
			return   # killed while planting: no charge
		unit.command_stop()
		_count(&"powder_charge")
		unit.get_tree().create_timer(float(CHARGE["fuse"]), false, true).timeout.connect(func() -> void:
			var t := ref.get_ref() as Node3D
			if t and bool(t.call(&"is_alive")):
				t.call(&"take_damage", float(CHARGE["damage"]), unit if is_instance_valid(unit) else null)
				T3Kit.pause_building(t, float(CHARGE["pause"]))))


## An enemy building whose edge is within 2.5 m, the one it attacks first.
func _building_in_reach() -> Node3D:
	var at := unit.global_position
	var t := unit.attack_target
	if t and t.is_in_group(&"buildings") and unit.is_enemy_of(t) and bool(t.call(&"is_alive")) \
			and _flat(t.global_position, at) - Unit.radius_of(t) <= float(CHARGE["reach"]):
		return t
	for n in unit.get_tree().get_nodes_in_group(&"buildings"):
		var b := n as Node3D
		if b == null or not unit.is_enemy_of(b) or not bool(b.call(&"is_alive")):
			continue
		if int(b.get(&"team")) == 2:
			continue
		if _flat(b.global_position, at) - Unit.radius_of(b) <= float(CHARGE["reach"]):
			return b
	return null


# ---------------------------------------------------------------- Nightblood Reaver / Genie / passives

func _on_attack_landed(target: Node3D, dealt: float) -> void:
	match id:
		&"ashveil_saboteur":
			reveal()
		&"nightblood_reaver":
			if dealt > 0.0:
				var drink := float(FRENZY["drink"]) if _frenzy_left > 0.0 else float(NIGHTBLOOD["drink"])
				if _sunburn_left > 0.0:
					drink *= float(NIGHTBLOOD["sunburn_mult"])
				unit.heal(dealt * drink)
				casts[&"nightblood"] = int(casts.get(&"nightblood", 0)) + 1
		&"stormbottle_genie":
			var victim := target as Unit
			if victim == null:
				return
			var hit: Array[Unit] = [victim]
			var from := victim.global_position
			for amount: float in GENIE_CHAIN["damage"]:
				var next := _nearest_enemy(from, float(GENIE_CHAIN["radius"]), hit)
				if next == null:
					break
				next.take_damage(amount, unit)
				hit.append(next)
				from = next.global_position


func _on_damage_taken(_amount: float, attacker: Node3D) -> void:
	match id:
		&"ashveil_saboteur":
			reveal()
		&"nightblood_reaver":
			if T3Kit.is_fire_source(attacker):
				_sunburn_left = float(NIGHTBLOOD["sunburn"])


## Sunburn from a spell (the Fire wizard's Fireball, burn): T3Kit calls it on spell hits too.
func sunburn() -> void:
	_sunburn_left = float(NIGHTBLOOD["sunburn"])


## Seconds left of Sunburn (tests / UI).
func sunburn_left() -> float:
	return maxf(0.0, _sunburn_left)


func _try_frenzy() -> void:
	if cooldown_left(&"blood_frenzy") > 0.0 or unit.hp > unit.max_hp * float(FRENZY["hp_pct"]):
		return
	if _nearest_enemy(unit.global_position, unit.attack_range + 4.0, []) == null:
		return
	unit.add_modifier(FRENZY_MOD, {&"attack_cooldown_pct": float(FRENZY["attack_cooldown_pct"])})
	_frenzy_left = float(FRENZY["time"])
	_cd[&"blood_frenzy"] = float(FRENZY["cd"])
	_count(&"blood_frenzy")
	if unit.model_has(&"set_status"):
		unit.model_call(&"set_status", [&"frenzy", true])   # eyes and blade flare crimson


func is_frenzied() -> bool:
	return _frenzy_left > 0.0


# ---------------------------------------------------------------- Shardguard

# A charge / lunge / blink = an enemy that ends inside 2.4 m after moving faster than 7.5 m/s or jumping 3+ m in a tick.
func _watch_charges() -> void:
	var ready := _hold_left <= 0.0
	if ready != _braced_shown and unit.model_has(&"set_braced"):
		_braced_shown = ready
		unit.model_call(&"set_braced", [ready])   # glaive planted, glass ring: Hold the Line is ready
	var seen := {}
	var at := unit.global_position
	for e in _enemies_near(at, 12.0):
		var key := e.get_instance_id()
		seen[key] = e.global_position
		if not _last_pos.has(key) or _hold_left > 0.0:
			continue
		var moved := _flat(e.global_position, _last_pos[key])
		var fast := moved / TICK >= float(HOLD["fast"]) or moved >= float(HOLD["jump"])
		if fast and _flat(e.global_position, at) <= float(HOLD["radius"]) + e.radius:
			hold_the_line(e)
	_last_pos = seen


## Stops `attacker`'s charge: frozen 1 s (heroes 0.5 by hero_mult), once per 10 s. True if it fired.
func hold_the_line(attacker: Unit) -> bool:
	if _hold_left > 0.0 or attacker == null or not attacker.is_alive():
		return false
	_hold_left = float(HOLD["every"])
	attacker.velocity = Vector3.ZERO
	attacker.apply_status(&"frozen", float(HOLD["freeze"]))
	_count(&"hold_the_line")
	return true


func _try_challenge() -> void:
	if cooldown_left(&"challenge") > 0.0:
		return
	var any := false
	for e in _enemies_near(unit.global_position, float(CHALLENGE["radius"])):
		var t := e.attack_target as Unit
		if t and int(t.team) == int(unit.team) and t.attack_range > 3.0 and t != unit:
			e.apply_status(&"taunted", float(CHALLENGE["taunt"]), false, unit)
			any = true
	if any:
		_cd[&"challenge"] = float(CHALLENGE["cd"])
		_count(&"challenge")


# ---------------------------------------------------------------- Briar Roc / Genie casts

func _try_seed_storm() -> void:
	if cooldown_left(&"seed_storm") > 0.0:
		return
	var r := float(SEED_STORM["radius"])
	var best: Unit = null
	var best_n := 0
	for e in _enemies_near(unit.global_position, float(SEED_STORM["range"])):
		if HelperAbilities._is_flyer(e):
			continue
		var n := _enemies_near(e.global_position, r).size()
		if n > best_n:
			best_n = n
			best = e
	if best == null:
		return
	seed_storm(best.global_position)


## Seed Storm at `at`: 30 + rooted 1 s to ground enemy units within 3 m (flyers are never rooted).
func seed_storm(at: Vector3) -> void:
	for e in _enemies_near(at, float(SEED_STORM["radius"])):
		if HelperAbilities._is_flyer(e):
			continue
		e.take_damage(float(SEED_STORM["damage"]), unit)
		if e.is_alive():
			e.apply_status(&"rooted", float(SEED_STORM["root"]))
	_cd[&"seed_storm"] = float(SEED_STORM["cd"])
	_count(&"seed_storm")


func _try_tempest() -> void:
	if cooldown_left(&"tempest_bolt") > 0.0:
		return
	var best: Unit = null
	for e in _enemies_near(unit.global_position, float(TEMPEST["range"])):
		if best == null or HelperAbilities._is_big(e) and not HelperAbilities._is_big(best) or e.max_hp > best.max_hp:
			best = e
	if best:
		tempest_bolt(best)


## Tempest Bolt: 120 to `target` (x1.5 on titans), then 40 to 2 more enemies within 5 m.
func tempest_bolt(target: Unit) -> void:
	var dmg := float(TEMPEST["damage"])
	if target.unit_type and target.unit_type.pop >= 6:
		dmg *= float(TEMPEST["titan_mult"])
	var hit: Array[Unit] = [target]
	var from := target.global_position
	target.take_damage(dmg, unit)
	for i in int(TEMPEST["jumps"]):
		var next := _nearest_enemy(from, float(GENIE_CHAIN["radius"]), hit)
		if next == null:
			break
		next.take_damage(float(TEMPEST["chain"]), unit)
		hit.append(next)
		from = next.global_position
	_cd[&"tempest_bolt"] = float(TEMPEST["cd"])
	_count(&"tempest_bolt")


# ---------------------------------------------------------------- helpers

func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in unit.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or u == unit or not u.is_alive() or not unit.is_enemy_of(u):
			continue
		if _flat(u.global_position, at) <= r + u.radius:
			out.append(u)
	return out


func _nearest_enemy(at: Vector3, r: float, skip: Array) -> Unit:
	var best: Unit = null
	var bd := INF
	for e in _enemies_near(at, r):
		if skip.has(e):
			continue
		var d := _flat(e.global_position, at)
		if d < bd:
			bd = d
			best = e
	return best


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
