class_name IceWizard
extends Wizard
## Torvald, the Ice Wizard (docs/design/kingdom-ice.md section 4): the tankiest, slowest wizard,
## base armor 10. Casts Rime Bolt / Flash Freeze / Rime Aegis through the SpellCaster; as a bot hero
## he casts by himself what SpellCaster.suggest_cast() proposes (rules 4.3, spells agent), unless the
## Commander owns his casts (ai_auto_cast = false), same as Malrik.
## On a non-player team he is in "enemy_heroes" instead of "heroes" (like Malrik).

const CAST_CHECK_INTERVAL := 0.5

@export var base_armor := 10.0   ## His base `armor` stat (items add on top).

## false = the Commander (scripts/ai/commander.gd) casts for him; he never casts by himself.
var ai_auto_cast := true

var _cast_check_left := 0.0


func _init() -> void:
	unit_name = "Torvald, Ice Wizard"
	max_hp = 440.0
	move_speed = 4.2
	attack_damage = 15.0
	attack_range = 6.5
	attack_cooldown = 1.5
	aggro_range = 9.0
	radius = 0.55
	body_height = 2.1
	body_color = Color(0.35, 0.60, 0.85)
	hat_color = Color(0.15, 0.35, 0.60)
	orb_color = Color(0.75, 0.92, 1.00)
	projectile_color = Color(0.75, 0.92, 1.00)
	max_mana = 100.0
	mana_regen = 4.0
	hp_per_level = 30.0   # kingdom-ice.md 4: +30 HP / +2 damage / +10 mana / +0.25 regen per level
	damage_per_level = 2.0
	mana_per_level = 10.0
	mana_regen_per_level = 0.25
	default_spell_ids = [&"rime_bolt", &"flash_freeze", &"rime_aegis"]
	default_model_path = "res://art/units/wizards/torvald.tscn"
	kingdom = &"ice"


func _ready() -> void:
	super._ready()
	set_base_stat(&"armor", base_armor)
	if team != Team.PLAYER:
		remove_from_group("heroes")
		add_to_group("enemy_heroes")


func _physics_process(delta: float) -> void:
	_cast_check_left -= delta
	if _cast_check_left <= 0.0 and ai_auto_cast and team != Team.PLAYER:   # the player casts his own
		_cast_check_left = CAST_CHECK_INTERVAL
		if is_alive() and spell_caster and spell_caster.has_method(&"suggest_cast"):
			_ai_cast_with_caster()
	super._physics_process(delta)


## Casts what suggest_cast() proposes; a "retreat" suggestion also walks him home.
func _ai_cast_with_caster() -> void:
	var s: Dictionary = spell_caster.call(&"suggest_cast")
	if s.is_empty():
		return
	var id := StringName(str(s.get("spell_id", "")))
	if command_cast(id, s.get("target")) != "":
		return
	if bool(s.get("retreat", false)):
		command_move(home_position())


func _reset_spells() -> void:
	super._reset_spells()
	_cast_check_left = 0.0


## Torvald doesn't know Fireball.
func command_fireball(_target: Vector3) -> String:
	return "Torvald can't cast Fireball"
