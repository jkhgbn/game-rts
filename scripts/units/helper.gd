class_name Helper
extends Champion
## A tier-3 helper (docs/design/t3-helpers.md sections 2-4, 12): the kingdom's campaign ally, called at the Citadel keep
## (HelperRoster). Autonomous like a champion (`is_commandable()` false) with a player-set stance (Escort / Vanguard /
## Hold home). Level = its bonded wizard's level, always (no own XP, no items, no purse, no class, no bounties).
## HP / damage from HelperType per level; ability amounts x ability_factor() (1 + 0.04 x (L - 1)).
## Children: "HelperAbilities" (scripts/units/helper_abilities.gd, 3 abilities + passive + bond, autocast).
## Its brain lives here (_brain_tick, 4 times a second): R2 flee under 25 % HP to the keep (rest there, Champion rest
## rule), fight what threatens the anchor, else follow the anchor of the stance.
## Groups: "units" (alive), "champions" (so the UI inspects it read-only with the gold frame), "helpers".

signal stance_changed(helper: Helper, stance: StringName)

const STANCES: Array[StringName] = [&"escort", &"vanguard", &"home"]
const MAX_HELPER_LEVEL := 8
const BRAIN_TICK := 0.25
const FLEE_PCT := 0.25                 ## R2: under 25 % HP it walks home ...
const RETURN_PCT := 0.7                ## ... and fights again from 70 %.
const ESCORT_NEAR := 3.0               ## Escort: stay 3-7 m from the wizard.
const ESCORT_FAR := 7.0
const ESCORT_LEASH := 12.0             ## Fights enemies within this of the wizard.
const VANGUARD_LEASH := 14.0
const HOME_LEASH := 20.0               ## Hold home: intruders within 20 m of the keep.
const HOME_OUT := 7.0                  ## Hold home spot: this far from the keep toward the map centre.
const CLUSTER_RADIUS := 10.0
const KILL_XP := 100                   ## Victim XP 100 + 30 x level (t3-helpers.md 3).
const KILL_XP_PER_LEVEL := 30
const POWER_BASE_HELPER := 200.0       ## Bot strength 200 + 40 x level (section 9).
const POWER_PER_LEVEL_HELPER := 40.0
const INTENT_ESCORT := &"Escorting"
const INTENT_VANGUARD := &"With the army"
const INTENT_HOME := &"Guarding home"
const INTENT_FIGHT := &"Fighting"
const INTENT_FLEE := &"Fleeing"
const INTENT_REST := &"Resting"

var helper_type: HelperType
## The wizard whose level it follows (its kingdom's wizard on its team). Null while none is known.
var bonded_wizard: Unit = null
var stance: StringName = &"escort"
var helper_abilities: HelperAbilities = null

var _brain_left := 0.0
var _fleeing := false
var _untargetable_left := 0.0          # Night of Knives: no damage while > 0


func _init() -> void:
	super._init()
	add_to_group(&"helpers")
	purse = 0
	unit_name = "Helper"


## Copies the helper's stats at `lvl` (before or after the tree).
func apply_helper_type(t: HelperType, lvl: int = 1) -> void:
	if t == null:
		return
	helper_type = t
	_ensure_base()
	_base[&"move_speed"] = t.move_speed
	_base[&"attack_cooldown"] = t.attack_cooldown
	_base[&"armor"] = t.armor
	attack_range = t.attack_range
	aggro_range = t.aggro
	radius = t.radius
	body_height = t.body_height
	body_color = t.color
	eye_color = t.color.lightened(0.4)
	projectile_color = t.projectile_color
	model_scene = t.model_scene
	sight_radius = t.sight
	flee_pct = FLEE_PCT
	growth_pct = 0.0
	display_name = t.display_name
	unit_name = t.display_name
	_type_applied = true
	level = clampi(lvl, 1, MAX_HELPER_LEVEL)
	_apply_level_stats()


func _ready() -> void:
	super._ready()
	if helper_type:
		unit_name = helper_type.display_name
	var ab := HelperAbilities.new()
	ab.name = "HelperAbilities"
	add_child(ab)
	ab.setup(self)
	helper_abilities = ab
	abilities = ab
	_find_bond()
	_brain_left = BRAIN_TICK * float(get_instance_id() % 4) / 4.0


# ---------------------------------------------------------------- identity / Champion paths skipped

func type_id() -> StringName:
	return helper_type.id if helper_type else &""


func full_name() -> String:
	return "%s, %s" % [helper_type.display_name, helper_type.title] if helper_type else display_name


## Helpers never gain XP: their level is the bonded wizard's.
func add_xp(_amount: int) -> void:
	pass


func xp_to_next() -> int:
	return 0


func is_max_level() -> bool:
	return level >= MAX_HELPER_LEVEL


## No XP, no purse from kills.
func credit_kill(_victim: Node3D, _killer_node: Node3D, _value: int) -> int:
	return 0


## Bot / brain strength: 200 + 40 x level (t3-helpers.md 9).
func power(with_hp: bool = false) -> float:
	var p := POWER_BASE_HELPER + POWER_PER_LEVEL_HELPER * float(level)
	if with_hp:
		p *= clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	return p


## Victim XP (Unit.kill_xp_value reads it): 100 + 30 x level.
func helper_kill_xp() -> int:
	return KILL_XP + KILL_XP_PER_LEVEL * level


## Ability amounts x this (1.12 at L4, 1.28 at L8).
func ability_factor() -> float:
	return helper_type.factor_at(level) if helper_type else 1.0


## Sets the level (the bonded wizard's): HP / damage of the HelperType row, HP gain healed while alive.
func set_level(lvl: int) -> void:
	lvl = clampi(lvl, 1, MAX_HELPER_LEVEL)
	if lvl == level:
		return
	level = lvl
	_apply_level_stats()
	_model_call(&"play_level_up")
	level_changed.emit(self, level)


func _apply_level_stats() -> void:
	if helper_type == null:
		return
	_ensure_base()
	_base[&"max_hp"] = helper_type.max_hp_at(level)
	_base[&"attack_damage"] = helper_type.damage_at(level)
	_recompute_stats(true)


# Champion extras a helper does not have (no items, no ChampionAbilities / ChampionBrain, no bounty leans).
func _create_inventory() -> void:
	inventory = null


func _create_child(_path: String, _node_name: String) -> Node:
	return null


func _connect_bounty_board() -> bool:
	return false


# ---------------------------------------------------------------- bond

## Binds to `wizard` (its level from now on).
func bond_to(wizard: Unit) -> void:
	if wizard == bonded_wizard:
		return
	if bonded_wizard and is_instance_valid(bonded_wizard) and bonded_wizard.level_changed.is_connected(_on_wizard_level):
		bonded_wizard.level_changed.disconnect(_on_wizard_level)
	bonded_wizard = wizard
	if wizard == null:
		return
	wizard.level_changed.connect(_on_wizard_level)
	set_level(wizard.level)
	if helper_abilities:
		helper_abilities.bind_wizard(wizard)


func _on_wizard_level(_u: Unit, lvl: int) -> void:
	set_level(lvl)


## The wizard of its team whose kingdom is the helper's, else any wizard of its team.
func _find_bond() -> void:
	if bonded_wizard != null and is_instance_valid(bonded_wizard):
		return
	var w := HelperRoster.wizard_of(get_tree(), int(team), helper_type.kingdom if helper_type else &"")
	if w:
		bond_to(w)


# ---------------------------------------------------------------- stance

## &"escort", &"vanguard" or &"home". "" = done, else "Invalid stance". Not an order: is_commandable stays false.
func set_stance(id: StringName) -> String:
	if not STANCES.has(id):
		return "Invalid stance"
	if id != stance:
		stance = id
		_brain_left = 0.0
		stance_changed.emit(self, stance)
	return ""


# ---------------------------------------------------------------- damage / death

func take_damage(amount: float, attacker: Node3D = null) -> void:
	if _untargetable_left > 0.0:
		return
	super.take_damage(amount, attacker)


## Night of Knives: no damage and no auto-targeting for `seconds`.
func set_untargetable(seconds: float) -> void:
	_untargetable_left = maxf(_untargetable_left, seconds)
	hide_from_auto_target(seconds)


func is_untargetable() -> bool:
	return _untargetable_left > 0.0


func respawn(at: Vector3) -> void:
	super.respawn(at)
	_fleeing = false
	_model_call(&"play_revive")


func die() -> void:
	if _dead:
		return
	super.die()
	_model_call(&"play_fall")


# ---------------------------------------------------------------- brain (t3-helpers.md 2.1, champions.md 8.1 R2 / R4)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _untargetable_left > 0.0:
		_untargetable_left -= delta
	if _dead:
		return
	_brain_left -= delta
	if _brain_left > 0.0:
		return
	_brain_left += BRAIN_TICK
	if _brain_left < 0.0:
		_brain_left = BRAIN_TICK
	_brain_tick()


func _brain_tick() -> void:
	if bonded_wizard == null or not is_instance_valid(bonded_wizard):
		_find_bond()
	if not can_act():
		return
	var keep := Keep.nearest(int(team), global_position)
	var ratio := hp / maxf(1.0, max_hp)
	if _fleeing:
		if ratio >= RETURN_PCT or keep == null:
			_fleeing = false
		else:
			var home := keep.drop_off_point()
			if _flat_distance(home) > 5.0:
				if not _has_move_order or attack_target != null:
					command_move(home)
				set_intent(INTENT_FLEE, keep)
			else:
				command_stop()
				set_intent(INTENT_REST, keep)
			return
	elif ratio < FLEE_PCT and keep != null:
		_fleeing = true
		command_move(keep.drop_off_point())
		set_intent(INTENT_FLEE, keep)
		return
	var mode := effective_stance()
	var anchor := _anchor_point(mode, keep)
	var leash := ESCORT_LEASH if mode == &"escort" else (HOME_LEASH if mode == &"home" else VANGUARD_LEASH)
	var target := _pick_target(mode, anchor, leash)
	if target:
		if attack_target != target:
			command_attack(target)
		set_intent(INTENT_FIGHT, target)
		return
	# The current fight drifted too far from the anchor: drop it.
	if attack_target != null and (not _target_alive(attack_target) or _flat(attack_target.global_position, anchor) > leash + 4.0):
		command_stop()
	var d := _flat_distance(anchor)
	var far := ESCORT_FAR if mode == &"escort" else 6.0
	if d > far:
		var dir := (global_position - anchor)
		dir.y = 0.0
		var spot := anchor + (dir.normalized() * ESCORT_NEAR if dir.length() > 0.1 else Vector3(ESCORT_NEAR, 0.0, 0.0))
		if mode == &"escort":
			command_move(spot)
		else:
			command_attack_move(spot)
	set_intent(INTENT_ESCORT if mode == &"escort" else (INTENT_HOME if mode == &"home" else INTENT_VANGUARD), null)


## The stance actually played: Escort acts as Vanguard while the wizard is dead.
func effective_stance() -> StringName:
	if stance == &"escort" and (bonded_wizard == null or not is_instance_valid(bonded_wizard) or not bonded_wizard.is_alive()):
		return &"vanguard"
	return stance


func _anchor_point(mode: StringName, keep: Keep) -> Vector3:
	match mode:
		&"escort":
			return bonded_wizard.global_position
		&"home":
			if keep:
				var to_centre := -keep.global_position
				to_centre.y = 0.0
				var out := to_centre.normalized() * HOME_OUT if to_centre.length() > 0.1 else Vector3.ZERO
				return keep.global_position + out
			return global_position
	# vanguard: the centre of the biggest own soldier group, else the wizard, else the keep.
	var c: Variant = _army_centre()
	if c is Vector3:
		return c
	if bonded_wizard and is_instance_valid(bonded_wizard) and bonded_wizard.is_alive():
		return bonded_wizard.global_position
	return keep.global_position if keep else global_position


func _army_centre() -> Variant:
	var soldiers: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		# Own seat only (not the 2v2 ally rule): the helper follows its own army, not an allied seat's.
		if u == null or u == self or int(u.team) != int(team) or not u.is_alive() or u.unit_type == null:
			continue
		if u.unit_type.is_worker or u.unit_type.is_caravan or u.is_in_group(&"champions") or not u.is_commandable():
			continue
		soldiers.append(u)
	if soldiers.is_empty():
		return null
	var best_n := -1
	var best: Unit = null
	var step := maxi(1, soldiers.size() / 24)   # sample at most ~24 centres
	var r2 := CLUSTER_RADIUS * CLUSTER_RADIUS
	for i in range(0, soldiers.size(), step):
		var s := soldiers[i]
		var n := 0
		for o in soldiers:
			var dx := o.global_position.x - s.global_position.x
			var dz := o.global_position.z - s.global_position.z
			if dx * dx + dz * dz <= r2:
				n += 1
		if n > best_n:
			best_n = n
			best = s
	var sum := Vector3.ZERO
	var count := 0
	for o in soldiers:
		if _flat(o.global_position, best.global_position) <= CLUSTER_RADIUS:
			sum += o.global_position
			count += 1
	return Vector3(sum.x / count, 0.0, sum.z / count)


func _pick_target(mode: StringName, anchor: Vector3, leash: float) -> Node3D:
	var best: Unit = null
	var best_d := INF
	var threat: Unit = null
	var threat_d := INF
	var wiz := bonded_wizard if bonded_wizard and is_instance_valid(bonded_wizard) and bonded_wizard.is_alive() else null
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not is_enemy_of(u) or u.is_hidden_from_auto_target():
			continue
		if u.has_method(&"is_disguised_for") and bool(u.call(&"is_disguised_for", int(team))):
			continue
		if _flat(u.global_position, anchor) > leash:
			continue
		var d := _flat_distance(u.global_position)
		if mode == &"escort" and wiz and u.attack_target == wiz and d < threat_d:
			threat_d = d
			threat = u
		if d < best_d:
			best_d = d
			best = u
	if threat:
		return threat
	if best:
		return best
	if mode != &"escort":   # no enemy unit: an enemy building near the anchor
		var bt: Node3D = null
		var bd := INF
		for n in get_tree().get_nodes_in_group(&"buildings"):
			var b := n as Node3D
			if b == null or not is_enemy_of(b) or not _target_alive(b):
				continue
			var da := _flat(b.global_position, anchor) - radius_of(b)
			if da > leash * 0.6:
				continue
			var d2 := _flat_distance(b.global_position)
			if d2 < bd:
				bd = d2
				bt = b
		return bt
	return null


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
