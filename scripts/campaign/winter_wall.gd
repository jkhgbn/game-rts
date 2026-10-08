class_name WinterWall
extends Building
## A piece (or a Winter Gate) of the Wall of a Hundred Winters, mission e4m4 (docs/design/mission-e4-04.md D3): a
## Building of the enemy team on the Wall line. Damage uses the walls.md 8 factors at L3: soldiers, wizards' and
## helpers' auto-attacks x0.35, siege (Ash Hurler, Frost Mortar, Cinder Arbalest) x1.5, titans (Elder Treant,
## Wallwarden) x1.0; damage with no attacker (spells reaching it through the mission) x1.0. While the Winterheart stands
## the pieces regrow (the type's idle_regen_pct, the mission sets it to 0 at the thaw). Placeholder look: the Ice
## wall model scaled along the line (E4M4.V1 replaces it).

const SOLDIER := 0.35
const SIEGE := 1.5
const TITAN := 1.0
const SIEGE_IDS: Array[StringName] = [&"ash_hurler", &"frost_mortar", &"cinder_arbalest"]
const TITAN_IDS: Array[StringName] = [&"elder_treant", &"wallwarden", &"rime_colossus"]

var is_gate := false
## Spells hitting the Wall: a wizard's attacker reference cannot tell a Thornburst from a staff hit, so the mission
## marks spell damage by calling take_spell_damage (x1.0).


## The Wall's BuildingType (code-made): `cells` x 1 cells of 2 m, `hp` HP, regrowth `regen_pct` % / s.
static func make_type(id: StringName, display: String, hp: float, cells: int, regen_pct: float) -> BuildingType:
	var base := BuildingType.find("ice_wall")
	var t := (base.duplicate() as BuildingType) if base else BuildingType.new()
	t.id = id
	t.display_name = display
	t.faction = &"ice"
	t.kind = &"winter_wall"
	t.cost = 0
	t.max_count = 0
	t.hotkey_label = ""
	t.max_hp = hp
	t.footprint = Vector2i(cells, 1)
	t.height = 5.0
	t.sight_radius = 6.0
	t.idle_regen_pct = regen_pct
	t.counts_for_defeat = false
	return t


static func factor_for(attacker: Node3D) -> float:
	if attacker == null or not is_instance_valid(attacker):
		return 1.0
	var t: Variant = attacker.get(&"unit_type")
	if t is UnitType:
		var id := (t as UnitType).id
		if SIEGE_IDS.has(id):
			return SIEGE
		if TITAN_IDS.has(id):
			return TITAN
	return SOLDIER


func take_damage(amount: float, attacker: Node3D = null) -> void:
	super(amount * factor_for(attacker), attacker)


## Spell damage (x1.0), whoever cast it.
func take_spell_damage(amount: float, attacker: Node3D = null) -> void:
	super.take_damage(amount, attacker)
