class_name Bastion
extends Keep
## A Wave Strike team's core building (docs/design/wave-strike.md 4.6): the kingdom's keep at its Citadel look and
## attack, HP = Citadel keep HP x rules.bastion_hp_mult (2.0: Fire / Shadow 7 000), armour 3. Trains nothing, is no
## drop-off, has no tier card; it is still a shop (the wizard buys items there). Destroyed = that team loses
## (WaveStrikeLevel listens to `destroyed`).

var armor := 3.0


## Sets the Citadel look and the Wave Strike HP (call once it is in the tree).
func setup_bastion(rules: WaveStrikeRules) -> void:
	set_start_tier(3)
	var base := building_type.max_hp if building_type else 2500.0
	max_hp = roundf(base * TierSystem.HP_MULT[2] * rules.bastion_hp_mult)
	hp = max_hp
	armor = rules.bastion_armor
	_update_hp_bar()


func trainable_types() -> Array[UnitType]:
	return []


func tier_card_type() -> UnitType:
	return null


func is_drop_off() -> bool:
	return false


func counts_for_defeat() -> bool:
	return true


## Armour as units take it (unit.gd: damage x 100 / (100 + 6 x armour) style curves differ; a flat cut here).
func take_damage(amount: float, attacker: Node3D = null) -> void:
	super(maxf(amount - armor, amount * 0.5), attacker)


func hp_ratio() -> float:
	return clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
