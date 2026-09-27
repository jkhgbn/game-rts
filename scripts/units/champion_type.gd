class_name ChampionType
extends Resource
## One hireable champion archetype (docs/design/champions.md sections 4 and 13). One .tres per archetype in
## data/champions/<id>.tres (ids `wayfinder`, `oathwall`, `coin_cutter`, `mender`). Numbers are level 1.
## Build one with `ChampionType.find(&"coin_cutter").create_champion(variant)`, then set its team and add it.

const DIR := "res://data/champions/"
## Every archetype in tavern-window order.
const IDS: Array[StringName] = [&"wayfinder", &"oathwall", &"coin_cutter", &"mender"]
## Bark triggers (champions.md 4.5) -> chance to say the line. Keys of `barks`. `class_chosen` (skills-rework.md
## 2.2) replaces the level-up bark at level 2.
const BARK_CHANCES := {&"hired": 1.0, &"bounty": 0.3, &"flee": 0.5, &"level_up": 1.0, &"buy": 0.2,
		&"class_chosen": 1.0}

@export var id: StringName = &""
## "the Wayfinder" (shown after the name: "Tamsin Farrow, the Wayfinder").
@export var title := ""
## Sibling names: index 0 = name A (first hire of this archetype in the match), 1 = name B.
@export var names := PackedStringArray()
## "Scout, ranged".
@export var role := ""
@export var pop := 2

@export_group("Stats (level 1)")
@export var max_hp := 100.0
@export var armor := 0.0
@export var attack_damage := 10.0
@export var attack_range := 1.6              ## More than 3.0 means the champion shoots projectiles.
@export var attack_cooldown := 1.0
@export var move_speed := 5.0
@export var aggro_range := 8.0
@export var sight_radius := 12.0             ## Fog of war (fog-of-war.md, champions.md 8.4).
@export var radius := 0.45
@export var body_height := 1.7
@export var body_color := Color(0.5, 0.45, 0.4)   ## Placeholder body (the neutral palette of 4.6).
@export var eye_color := Color(0.95, 0.9, 0.8)
@export var projectile_color := Color(1.0, 0.8, 0.4)
## Level growth: HP, damage, ability damage / heals / shields x (1 + growth_pct x (level - 1)).
@export var growth_pct := 0.08
## Flees (brain rule R2) when HP / max HP is under this.
@export var flee_pct := 0.35

@export_group("Personality (champions.md 4.2, 8)")
## Always has `greed`, `courage`, `engage_radius`; optional extra keys per archetype (see the .tres files).
@export var traits: Dictionary = {}
## Bounty kind affinity: `hunt`, `explore`, `guard`, `escort`.
@export var affinity: Dictionary = {}
## A flag is taken when its utility is at least this (8.2).
@export var bounty_threshold := 10.0
## Abilities in unlock order: two at level 1, the third at level 4 (4.3).
@export var ability_ids: Array[StringName] = []
## Display overrides of this archetype's abilities: id -> name (the Wayfinder's `flare_arrow` is "Signal Flare",
## skills-rework.md 4.1). Read with ability_name(); ids not listed keep the ChampionAbilities name.
@export var ability_names: Dictionary = {}
## Same for the ability text (id -> one line).
@export var ability_texts: Dictionary = {}
## Class id (ChampionClass.IDS) -> base weight of the level-2 class draw (skills-rework.md 2.1).
@export var class_weights: Dictionary = {}
## Item ids bought in order (4.4).
@export var wishlist: Array[StringName] = []
@export var personality_line := ""
@export var likes := ""
@export var fears := ""
## Bark trigger (BARK_CHANCES key) -> line (4.5).
@export var barks: Dictionary = {}

@export_group("Look")
## The character model (9.C10 plugs res://art/units/champions/<id>/<id>.tscn); empty = code placeholder.
@export var model_scene: PackedScene

static var _cache: Dictionary = {}


## The archetype `id_or_name` (an id such as &"coin_cutter", or "Coin-Cutter" / "coin cutter"). Null if unknown.
static func find(id_or_name: Variant) -> ChampionType:
	var key := str(id_or_name).strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	if key.begins_with("the_"):
		key = key.substr(4)
	if _cache.has(key):
		return _cache[key]
	var path := DIR + key + ".tres"
	if not ResourceLoader.exists(path):
		return null
	var type := load(path) as ChampionType
	if type:
		_cache[key] = type
	return type


## The four archetypes in IDS order (missing files are skipped).
static func all() -> Array[ChampionType]:
	var out: Array[ChampionType] = []
	for type_id in IDS:
		var t := find(type_id)
		if t:
			out.append(t)
	return out


## Name A (variant 0) or B (variant 1).
func name_for(variant: int) -> String:
	if names.is_empty():
		return String(id).capitalize()
	return names[clampi(variant, 0, names.size() - 1)]


## "Tamsin Farrow, the Wayfinder".
func full_name(variant: int) -> String:
	return "%s, %s" % [name_for(variant), title] if title != "" else name_for(variant)


## A trait (`greed`, `courage`, `engage_radius`, or an extra key); `fallback` when missing.
func get_trait(trait_name: StringName, fallback: float = 0.0) -> float:
	return float(traits.get(trait_name, traits.get(String(trait_name), fallback)))


## Affinity for a bounty kind (`hunt`, `explore`, `guard`, `escort`); 0 when missing.
func affinity_for(kind: StringName) -> float:
	return float(affinity.get(kind, affinity.get(String(kind), 0.0)))


## The bark line for `trigger` (BARK_CHANCES key), "" when none.
func bark_for(trigger: StringName) -> String:
	return str(barks.get(trigger, barks.get(String(trigger), "")))


## The display name of ability `ability_id` for this archetype (ability_names), else `fallback`.
func ability_name(ability_id: StringName, fallback: String = "") -> String:
	return str(ability_names.get(ability_id, ability_names.get(String(ability_id), fallback)))


## The one-line text of ability `ability_id` for this archetype (ability_texts), else `fallback`.
func ability_text(ability_id: StringName, fallback: String = "") -> String:
	return str(ability_texts.get(ability_id, ability_texts.get(String(ability_id), fallback)))


## Base weight of class `class_id` in the level-2 draw (0 when missing).
func class_weight(class_id: StringName) -> float:
	return float(class_weights.get(class_id, class_weights.get(String(class_id), 0.0)))


## Stat multiplier at `level` (1.00 at L1, 1.08 at L2 ... 1.40 at L6).
func growth_at(level: int) -> float:
	return 1.0 + growth_pct * float(maxi(1, level) - 1)


## A new Champion of this archetype (not in the tree yet): set its team, add it, then place it.
func create_champion(variant: int = 0) -> Champion:
	var ch := Champion.new()
	ch.apply_champion_type(self, variant)
	return ch
