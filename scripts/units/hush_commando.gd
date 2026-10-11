class_name HushCommando
extends Wizard
## Mother Hush as a story hero (docs/design/mission-e3-02.md D3 and "Hush in the night"; E3M2.G1): the hero of e3m2's
## night. F / Q / E = Blink Strike / Smoke Cloak / Night of Knives (no mana, their own cooldowns; `command_cast` takes
## `&"hush_blink"`, `&"hush_smoke"`, `&"hush_knives"`), the Mouthless Veil passive (veiled after VEIL_IDLE s without
## attacking or being hit; the first strike out of the veil x VEIL_BONUS; veiled she never auto-attacks), level 5 fixed
## (add_xp does nothing).
## Built 2026-10-07 (reduced E3M2.G1): the abilities are code here (no SpellType resources, no SpellCaster spells); the
## mission decides who may be picked (`foe_filter`), what "concealed" means (`smoke_cloak_cast`, `is_veiled()`) and the
## exposure after a strike (`exposed`). The concealed status itself is Unit's `&"concealed"`.

signal smoke_cloak_cast(at: Vector3)   ## Q: smoke of SMOKE_RADIUS for SMOKE_TIME at `at`
signal exposed(seconds: float)          ## a strike or Night of Knives: seen at full sight for `seconds`

const ABILITIES: Array[StringName] = [&"hush_blink", &"hush_smoke", &"hush_knives"]
const LEVEL := 5
const BLINK_RANGE := 14.0
const BLINK_COOLDOWN := 10.0
const SMOKE_COOLDOWN := 22.0
const SMOKE_RADIUS := 4.0
const SMOKE_TIME := 5.0
const SMOKE_SHROUD := 3.0
const KNIVES_COOLDOWN := 75.0
const KNIVES_RANGE := 10.0
const KNIVES_HITS := 6
const KNIVES_DAMAGE := 46.0
const KNIVES_HERO_MULT := 1.5
const VEIL_IDLE := 4.0
const VEIL_BONUS := 1.6
const EXPOSE_TIME := 3.0
const IDLE_REGEN_PCT := 2.0
const AGGRO_RANGE := 6.0
const REFUSE_RECHARGING := "Recharging"
const REFUSE_NO_TARGET := "No enemy within 14 m"
const REFUSE_NOT_NOW := "Not now"

var blink_damage := 65.0             ## by difficulty (75 / 65 / 60), set by the mission
var foe_filter: Callable = Callable()   ## (Unit) -> bool: may an ability pick this enemy (default: any living enemy)
var smoke_at := Vector3.INF
var smoke_left := 0.0                ## seconds the current smoke still stands
var _cd := {}                        ## ability id -> seconds left
var _idle := 0.0


func _init() -> void:
	super()
	unit_name = "Mother Hush"
	kingdom = &"shadow"
	var none: Array[StringName] = []
	default_spell_ids = none
	default_model_path = "res://art/units/helpers/helper_hush/helper_hush.tscn"
	max_hp = 900.0
	attack_damage = 34.0
	attack_range = 1.6
	attack_cooldown = 1.0
	move_speed = 5.4
	aggro_range = AGGRO_RANGE
	body_color = Color(0.60, 0.50, 0.75)
	hp_per_level = 0.0
	damage_per_level = 0.0
	mana_per_level = 0.0
	mana_regen_per_level = 0.0


func _ready() -> void:
	super()
	level = LEVEL
	level_cap = LEVEL
	set_idle_regen_pct(IDLE_REGEN_PCT)   # spec: 2 % / s after 8 s out of combat (Unit's idle regen: after 4 s)
	if has_signal(&"damage_taken"):
		connect(&"damage_taken", func(_a: float, _by: Node3D) -> void: _idle = 0.0)
	attack_landed.connect(func(_t: Node3D, _a: float) -> void:
		_idle = 0.0
		exposed.emit(EXPOSE_TIME))


## Level 5 fixed: no XP.
func add_xp(_amount: int) -> void:
	pass


func is_veiled() -> bool:
	return is_alive() and _idle >= VEIL_IDLE


func cooldown_left(id: StringName) -> float:
	return float(_cd.get(id, 0.0))


func cooldown_total(id: StringName) -> float:
	match id:
		&"hush_blink":
			return BLINK_COOLDOWN
		&"hush_smoke":
			return SMOKE_COOLDOWN
		&"hush_knives":
			return KNIVES_COOLDOWN
	return 0.0


## F / Q / E (and the mission's buttons): "" = ok, else the reason. Never asks for mana.
func command_cast(spell_id: StringName, target: Variant) -> String:
	match spell_id:
		&"hush_blink":
			return blink_strike(target as Unit if target is Unit else null)
		&"hush_smoke":
			return smoke_cloak()
		&"hush_knives":
			return night_of_knives()
	return super(spell_id, target)


func _foes_near(r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or u == self or not u.is_alive() or not is_enemy_of(u):
			continue
		if foe_filter.is_valid() and not bool(foe_filter.call(u)):
			continue
		if Vector2(u.global_position.x - global_position.x, u.global_position.z - global_position.z).length() <= r:
			out.append(u)
	return out


## Blink Strike (F, 10 s): behind `target` (default: the weakest enemy within 14 m), blink_damage (out of the veil
## x 1.6: 104 on normal, a one-strike kill on an archer).
func blink_strike(target: Unit = null) -> String:
	if not is_alive() or not can_act():
		return REFUSE_NOT_NOW
	if cooldown_left(&"hush_blink") > 0.0:
		return REFUSE_RECHARGING
	if target == null or not is_instance_valid(target) or not target.is_alive():
		target = null
		for u in _foes_near(BLINK_RANGE):
			if target == null or u.hp < target.hp:
				target = u
	if target == null:
		return REFUSE_NO_TARGET
	_cd[&"hush_blink"] = BLINK_COOLDOWN
	var back := target.global_position - global_position
	back.y = 0.0
	global_position = target.global_position + (back.normalized() if back.length() > 0.01 else Vector3.FORWARD) * 1.2
	var dmg := blink_damage * (VEIL_BONUS if is_veiled() else 1.0)
	target.take_damage(dmg, self)
	command_attack(target)
	_idle = 0.0
	exposed.emit(EXPOSE_TIME)
	return ""


## Smoke Cloak (Q, 22 s): smoke r 4 for 5 s at her spot (the mission conceals squad units inside and cancels the
## fuses); she is shrouded 3 s.
func smoke_cloak() -> String:
	if not is_alive():
		return REFUSE_NOT_NOW
	if cooldown_left(&"hush_smoke") > 0.0:
		return REFUSE_RECHARGING
	_cd[&"hush_smoke"] = SMOKE_COOLDOWN
	smoke_at = global_position
	smoke_left = SMOKE_TIME
	apply_status(&"shroud", SMOKE_SHROUD, true)
	smoke_cloak_cast.emit(smoke_at)
	return ""


## Night of Knives (E, 75 s): 6 strikes of 46 on up to 6 enemies within 10 m (heroes x 1.5 + marked 4 s); exposes her.
func night_of_knives() -> String:
	if not is_alive() or not can_act():
		return REFUSE_NOT_NOW
	if cooldown_left(&"hush_knives") > 0.0:
		return REFUSE_RECHARGING
	var foes := _foes_near(KNIVES_RANGE)
	if foes.is_empty():
		return REFUSE_NO_TARGET
	_cd[&"hush_knives"] = KNIVES_COOLDOWN
	for i in mini(KNIVES_HITS, foes.size()):
		var u := foes[i]
		var hero := u is Wizard or u.is_in_group(&"champions")
		u.take_damage(KNIVES_DAMAGE * (KNIVES_HERO_MULT if hero else 1.0), self)
		if hero:
			u.apply_status(&"marked", 4.0)
	_idle = 0.0
	exposed.emit(EXPOSE_TIME)
	return ""


## True while (x, z) of `p` is inside her standing smoke.
func smoke_covers(p: Vector3) -> bool:
	return smoke_left > 0.0 and Vector2(p.x - smoke_at.x, p.z - smoke_at.z).length() <= SMOKE_RADIUS


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	_idle += delta
	# Veiled, she never picks a fight on her own (a patrol brushing past her would end the stealth): only an order.
	aggro_range = 0.0 if is_veiled() else AGGRO_RANGE
	smoke_left = maxf(0.0, smoke_left - delta)
	for id: Variant in _cd.keys():
		_cd[id] = maxf(0.0, float(_cd[id]) - delta)
