class_name NatureWizard
extends Wizard
## Ysolde, the Nature Wizard (docs/design/kingdom-nature.md section 3): the fastest, frailest wizard
## with the most mana. Kingdom passive "Verdant": she regenerates 1.5 % max HP / s after 4 s without
## taking damage (Unit idle regen). Casts Thornburst / Wild Bloom / Call the Thicket through the
## SpellCaster; as a bot hero she casts by herself what SpellCaster.suggest_cast() proposes (rules 3.3,
## spells agent), unless the Commander owns her casts (ai_auto_cast = false), same as Malrik / Torvald.
## On a non-player team she is in "enemy_heroes" instead of "heroes".

const CAST_CHECK_INTERVAL := 0.5
const VERDANT_REGEN_PCT := 1.5   ## kingdom-nature.md 1: % of max HP / s after 4 s without damage

## false = the Commander (scripts/ai/commander.gd) casts for her; she never casts by herself.
## Ignored on the PLAYER team: the player's Ysolde never casts by herself.
var ai_auto_cast := true

var _cast_check_left := 0.0


func _init() -> void:
	unit_name = "Ysolde, Nature Wizard"
	max_hp = 340.0
	move_speed = 4.8
	attack_damage = 13.0
	attack_range = 7.5
	attack_cooldown = 1.2
	aggro_range = 9.0
	radius = 0.5
	body_height = 2.0
	body_color = Color(0.35, 0.70, 0.25)
	hat_color = Color(0.15, 0.40, 0.15)
	orb_color = Color(0.75, 1.00, 0.40)
	projectile_color = Color(0.75, 1.00, 0.40)
	max_mana = 110.0
	mana_regen = 4.5
	hp_per_level = 22.0   # kingdom-nature.md 3: +22 HP / +2 damage / +12 mana / +0.3 regen per level
	damage_per_level = 2.0
	mana_per_level = 12.0
	mana_regen_per_level = 0.3
	default_spell_ids = [&"thornburst", &"wild_bloom", &"call_the_thicket"]
	default_model_path = "res://art/units/wizards/ysolde.tscn"
	kingdom = &"nature"


func _ready() -> void:
	super._ready()
	set_idle_regen_pct(VERDANT_REGEN_PCT)
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


## Casts what suggest_cast() proposes; a "retreat" suggestion also walks her home.
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


## Ysolde doesn't know Fireball.
func command_fireball(_target: Vector3) -> String:
	return "Ysolde can't cast Fireball"
