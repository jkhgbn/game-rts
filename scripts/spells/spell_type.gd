class_name SpellType
extends Resource
## One spell's data (data/spells/<id>.tres). Numbers: docs/design/spells.md (rank 1) and
## docs/design/levels.md (ranks 2-3). The scalar fields are rank 1; the *_by_rank arrays hold every
## rank (index = rank - 1). An empty array means "the scalar at every rank".
## For zone spells (Ember Step's scorch, Soul Siphon) `damage` is the damage of ONE tick.

enum TargetType { POINT, UNIT, SELF, AREA }

const DIR := "res://data/spells/"

@export var id: StringName
@export var display_name := ""
@export var hotkey_label := ""          ## "F", "Q" or "E".
@export var target_type: TargetType = TargetType.POINT
@export var mana_cost := 0.0            ## Never changes with rank.
@export var cooldown := 0.0
@export var cast_range := 0.0           ## 0 for self spells ("range" in spells.md).
@export var radius := 0.0
@export var damage := 0.0               ## Per hit, or per tick for zone spells.
@export var duration := 0.0             ## Zone or status duration.
@export var is_zone := false           ## Leaves a ticking circle (scorch, Soul Siphon).
@export var tick_interval := 0.5        ## Zone spells only.
@export var heal_ratio := 0.0           ## Share of the damage dealt that heals the caster.
@export var status_id: StringName       ## &"haste" / &"shroud" / &"chill" / &"frozen" / &"rooted" for status spells.
## A second status put on the target when the first one ends (Flash Freeze: `chill` 3 s after `frozen`).
@export var secondary_status_id: StringName
@export var secondary_duration := 0.0
@export var shield_amount := 0.0        ## Shield spells (Rime Aegis); lasts `duration`.
## Heal-over-time spells (Wild Bloom): TOTAL heal per unit over `duration`, one tick every `tick_interval`.
@export var heal_amount := 0.0
## Summon spells (Call the Thicket): the UnitType id spawned, how many; they wither after `duration`.
@export var summon_unit_id: StringName
@export var summon_count := 0
@export var icon_abbrev := ""
@export_multiline var tooltip := ""     ## The one-line description (third tooltip line).
@export var max_rank := 3
@export var level_required: Array[int] = []   ## Wizard level needed for each rank.
@export var damage_by_rank: Array[float] = []
@export var cooldown_by_rank: Array[float] = []
@export var range_by_rank: Array[float] = []
@export var radius_by_rank: Array[float] = []
@export var duration_by_rank: Array[float] = []
@export var shield_by_rank: Array[float] = []
@export var heal_by_rank: Array[float] = []
@export var summon_count_by_rank: Array[int] = []


func damage_at(rank: int) -> float:
	return _pick(damage_by_rank, damage, rank)


func cooldown_at(rank: int) -> float:
	return _pick(cooldown_by_rank, cooldown, rank)


func range_at(rank: int) -> float:
	return _pick(range_by_rank, cast_range, rank)


func radius_at(rank: int) -> float:
	return _pick(radius_by_rank, radius, rank)


func duration_at(rank: int) -> float:
	return _pick(duration_by_rank, duration, rank)


func shield_at(rank: int) -> float:
	return _pick(shield_by_rank, shield_amount, rank)


## Total heal per unit of a heal-over-time spell at this rank (before spell power).
func heal_at(rank: int) -> float:
	return _pick(heal_by_rank, heal_amount, rank)


## Units a summon spell creates at this rank.
func summon_count_at(rank: int) -> int:
	if summon_count_by_rank.is_empty():
		return summon_count
	return summon_count_by_rank[clampi(rank, 1, summon_count_by_rank.size()) - 1]


## Total damage of a zone spell at this rank (ticks x damage per tick); the hit damage otherwise.
func total_damage_at(rank: int) -> float:
	if is_zone and tick_interval > 0.0:
		return damage_at(rank) * roundf(duration_at(rank) / tick_interval)
	return damage_at(rank)


## Level needed for `rank` (1-based); 99 when the rank does not exist.
func level_for_rank(rank: int) -> int:
	if rank < 1 or rank > max_rank:
		return 99
	if rank - 1 < level_required.size():
		return level_required[rank - 1]
	return 1


func _pick(values: Array[float], fallback: float, rank: int) -> float:
	if values.is_empty():
		return fallback
	return values[clampi(rank, 1, values.size()) - 1]


static var _cache: Dictionary = {}


## The SpellType with this id (data/spells/<id>.tres), or null.
static func find(spell_id: StringName) -> SpellType:
	if _cache.has(spell_id):
		return _cache[spell_id]
	var path := DIR + String(spell_id) + ".tres"
	var t: SpellType = null
	if ResourceLoader.exists(path):
		t = load(path) as SpellType
	_cache[spell_id] = t
	return t
