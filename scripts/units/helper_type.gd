class_name HelperType
extends Resource
## A tier-3 helper (docs/design/t3-helpers.md sections 1-4, 12): the campaign ally each kingdom calls at its Citadel keep.
## One .tres per helper in data/helpers/<id>.tres. Level = the bonded wizard's level (no own XP).

const DIR := "res://data/helpers/"
const IDS: Array[StringName] = [&"helper_vey", &"helper_hush", &"helper_aldra", &"helper_maelis"]

@export var id: StringName = &""
@export var display_name := ""               ## "Old Vey" (short name on the keep card: "Call Old Vey").
@export var title := ""                      ## "The Storm-Sword".
@export var kingdom: StringName = &""        ## &"fire", &"shadow", &"ice", &"nature".
@export var bonded_wizard_id: StringName = &""
@export var hp_base := 600.0
@export var hp_per_level := 40.0
@export var damage_base := 20.0
@export var damage_per_level := 2.0
@export var armor := 0.0
@export var attack_range := 2.0              ## More than 3.0 = shoots projectiles.
@export var attack_cooldown := 1.2
@export var move_speed := 5.0
@export var sight := 13.0
@export var aggro := 10.0
@export var kind: StringName = &"melee"      ## &"melee" or &"ranged".
@export var ability_ids: Array[StringName] = []   ## 3, slot order; the 3rd is the signature (signature_level).
@export var passive_id: StringName = &""
@export var signature_level := 5
@export var level_factor := 0.04             ## Ability amounts x (1 + level_factor x (L - 1)).
@export var call_crystals := 350
@export var call_essence := 200
@export var call_time := 60.0
@export var pop := 4
@export var radius := 0.5
@export var body_height := 2.0
@export var color := Color(1, 1, 1)
@export var projectile_color := Color(1, 1, 1)
@export var model_scene: PackedScene
@export var model_path := ""                 ## The real model to build (docs/handoff/tiers-wave.md).
@export var portrait: Texture2D
@export var voice_prefix := ""

static var _cache: Dictionary = {}


static func find(helper_id: StringName) -> HelperType:
	if _cache.has(helper_id):
		return _cache[helper_id]
	var path := DIR + String(helper_id) + ".tres"
	if not ResourceLoader.exists(path):
		return null
	var t := load(path) as HelperType
	if t:
		_cache[helper_id] = t
	return t


## The helper of a kingdom (&"fire" -> Old Vey), or null.
static func for_kingdom(k: StringName) -> HelperType:
	for hid in IDS:
		var t := find(hid)
		if t and t.kingdom == k:
			return t
	return null


func max_hp_at(level: int) -> float:
	return hp_base + hp_per_level * float(maxi(1, level) - 1)


func damage_at(level: int) -> float:
	return damage_base + damage_per_level * float(maxi(1, level) - 1)


func factor_at(level: int) -> float:
	return 1.0 + level_factor * float(maxi(1, level) - 1)
