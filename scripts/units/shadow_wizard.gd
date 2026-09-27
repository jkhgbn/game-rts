class_name ShadowWizard
extends Wizard
## Malrik, the Shadow Wizard: the enemy hero of mission 1. Fights like any unit and casts
## Shadow Lance by itself (AI-cast only in wave 1): a bolt that heals him for part of the damage.
## He is NOT in the "heroes" group (so he can't claim artifacts); he is in "enemy_heroes".
## Stats and casting rules: docs/design/units-fire-shadow.md.

signal shadow_lance_cast(target: Unit)
signal lance_healed(amount: float)

const CAST_CHECK_INTERVAL := 0.5
const LANCE_COLOR := Color(0.7, 0.3, 1.0)
const HEAL_FLASH_COLOR := Color(0.75, 0.35, 1.0)

@export var lance_cost := 35.0
@export var lance_damage := 50.0
@export var lance_range := 12.0
@export var lance_cooldown := 8.0
@export var lance_heal_ratio := 0.5        ## Share of the damage really dealt that heals Malrik.
@export var lance_low_hp_target := 50.0    ## Rule 1: finish off targets at or below this HP.
@export var lance_low_self_ratio := 0.6    ## Rule 2: below this share of max HP, drain the biggest target.
@export var lance_speed := 30.0
@export var lance_size := 0.14

var lance_cooldown_left := 0.0
## false = the Commander (scripts/ai/commander.gd) casts for him; he never casts by himself.
var ai_auto_cast := true

var _cast_check_left := 0.0
var _heal_flash := 0.0


func _init() -> void:
	unit_name = "Malrik, Shadow Wizard"
	max_hp = 400.0
	move_speed = 4.4
	attack_damage = 16.0
	attack_range = 7.0
	attack_cooldown = 1.3
	aggro_range = 9.0
	radius = 0.5
	body_height = 2.0
	body_color = Color(0.30, 0.12, 0.45)
	hat_color = Color(0.12, 0.05, 0.20)
	orb_color = Color(0.70, 0.30, 1.00)
	projectile_color = Color(0.6, 0.3, 0.9)
	max_mana = 100.0
	mana_regen = 4.0
	hp_per_level = 30.0   # levels.md: Malrik +30 HP / +2 damage / +10 mana / +0.25 regen per level
	damage_per_level = 2.0
	mana_per_level = 10.0
	mana_regen_per_level = 0.25
	default_spell_ids = [&"shadow_lance", &"soul_siphon", &"umbral_shroud"]
	default_model_path = "res://art/units/wizards/malrik.tscn"
	kingdom = &"shadow"


func _ready() -> void:
	super._ready()
	remove_from_group("heroes")   # only the player's wizard may claim artifacts in wave 1
	add_to_group("enemy_heroes")
	# With the SpellCaster, its life drain heals report as lance_healed (and the purple flash).
	if spell_caster and spell_caster.has_signal(&"healed"):
		spell_caster.connect(&"healed", _on_caster_healed)


func _on_caster_healed(amount: float) -> void:
	if amount <= 0.0:
		return
	_heal_flash = 1.0
	lance_healed.emit(amount)


func _physics_process(delta: float) -> void:
	lance_cooldown_left = max(0.0, lance_cooldown_left - delta)
	_cast_check_left -= delta
	if _cast_check_left <= 0.0 and ai_auto_cast and team != Team.PLAYER:   # the player casts his own
		_cast_check_left = CAST_CHECK_INTERVAL
		if spell_caster and spell_caster.has_method(&"suggest_cast"):
			if is_alive():
				_ai_cast_with_caster()
		elif lance_cooldown_left <= 0.0 and mana >= lance_cost:
			var target := pick_lance_target()
			if target:
				_cast_shadow_lance(target)
	super._physics_process(delta)


## SpellCaster AI (spells.md rules, learned spells only): cast what suggest_cast() proposes;
## rule 1 (Umbral Shroud) also walks him back to his anchor.
func _ai_cast_with_caster() -> void:
	var s: Dictionary = spell_caster.call(&"suggest_cast")
	if s.is_empty():
		return
	var id := StringName(str(s.get("spell_id", "")))
	var target: Variant = s.get("target")
	if command_cast(id, target) != "":
		return
	if bool(s.get("retreat", false)):
		command_move(home_position())


func _reset_spells() -> void:
	super._reset_spells()
	lance_cooldown_left = 0.0
	_cast_check_left = 0.0
	_heal_flash = 0.0
	if _body_mat:
		_body_mat.emission = Color.WHITE


## Whoever casts (his own loop or the Commander with ai_auto_cast = false), an accepted Shadow Lance
## on a unit emits shadow_lance_cast.
func command_cast(spell_id: StringName, target: Variant) -> String:
	var reason := super.command_cast(spell_id, target)
	if reason == "" and spell_id == &"shadow_lance" and target is Unit:
		shadow_lance_cast.emit(target)
	return reason


## Malrik doesn't know Fireball.
func command_fireball(_target: Vector3) -> String:
	return "Malrik can't cast Fireball"


## Casting rules 1-4 of the spec. Returns null when no enemy is within lance_range.
func pick_lance_target() -> Unit:
	var in_range: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var other := node as Unit
		if other and other.is_alive() and is_enemy_of(other) \
				and _flat_distance(other.global_position) <= lance_range:
			in_range.append(other)
	if in_range.is_empty():
		return null
	# 1. Finish off a weak unit: the healthiest one among those at or below the threshold.
	var best: Unit = null
	for u in in_range:
		if u.hp <= lance_low_hp_target and (best == null or u.hp > best.hp):
			best = u
	if best:
		return best
	# 2. Hurt: drain the unit with the most HP (a full heal is guaranteed).
	if hp < max_hp * lance_low_self_ratio:
		for u in in_range:
			if best == null or u.hp > best.hp:
				best = u
		return best
	# 3. The enemy wizard.
	for u in in_range:
		if u is Wizard:
			return u
	# 4. The nearest unit.
	var best_dist := INF
	for u in in_range:
		var d := _flat_distance(u.global_position)
		if d < best_dist:
			best_dist = d
			best = u
	return best


func _cast_shadow_lance(target: Unit) -> void:
	mana -= lance_cost
	lance_cooldown_left = lance_cooldown
	_face(target.global_position - global_position)
	var bolt := Projectile.new()
	get_tree().current_scene.add_child(bolt)
	bolt.launch_at_unit(self, global_position + Vector3.UP * body_height, target,
			lance_damage, LANCE_COLOR, lance_size, lance_speed, 0.0)
	bolt.hit_unit.connect(_on_lance_hit)
	shadow_lance_cast.emit(target)


func _on_lance_hit(_target: Node3D, damage_dealt: float) -> void:
	if not is_alive() or damage_dealt <= 0.0:
		return
	var amount := damage_dealt * lance_heal_ratio
	heal(amount)
	_heal_flash = 1.0
	lance_healed.emit(amount)


func _update_hit_flash(delta: float) -> void:
	if _body_mat == null:
		return
	if _heal_flash > 0.0:
		# Purple glow when Shadow Lance heals him.
		_heal_flash = max(0.0, _heal_flash - delta * 2.0)
		_body_mat.emission = HEAL_FLASH_COLOR
		_body_mat.emission_energy_multiplier = _heal_flash * 3.0
		if _heal_flash <= 0.0:
			_body_mat.emission = Color.WHITE
		return
	super._update_hit_flash(delta)
