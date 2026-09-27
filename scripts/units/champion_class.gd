class_name ChampionClass
extends Resource
## A champion's combat class (docs/design/skills-rework.md sections 2, 3 and 10). One .tres per class in
## data/champion_classes/<id>.tres (ids `spear`, `sword_shield`, `two_hand`, `wizard`). Numbers are level 1.
## A champion draws its class once, at level 2 (`Champion.add_xp`), with `pick(champion, rng)`: weights =
## `ChampionType.class_weights` + 20 per bounty of the leaning kind paid to it before level 2 (at most +40 per class).
## The class sets the weapon (base attack damage / cooldown, range, projectile), adds the stat modifier
## `class:<id>`, shifts the flee threshold and brings 3 skills (unlocked at `unlock_levels`, ChampionAbilities).
## Apply one with `Champion.set_champion_class(id)`.

const DIR := "res://data/champion_classes/"
## Every class, in the order of the tables (draws walk the weights in this order).
const IDS: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
## Bounty kinds by `Bounty.kind` int (HUNT 0, EXPLORE 1, GUARD 2, ESCORT 3).
const BOUNTY_KINDS: Array[StringName] = [&"hunt", &"explore", &"guard", &"escort"]
## Weight added per paid bounty whose kind leans to a class, and the cap per class (2.1).
const BOUNTY_LEAN_WEIGHT := 20.0
const BOUNTY_LEAN_CAP := 40.0
## Base weight of every class when an archetype has no `class_weights` (equal chances).
const DEFAULT_WEIGHT := 25.0
const MODIFIER_PREFIX := "class:"

@export var id: StringName = &""
## "Sword and Shield".
@export var display_name := ""

@export_group("Weapon (level 1)")
@export var attack_damage := 10.0
@export var attack_cooldown := 1.0
@export var attack_range := 1.8               ## More than 3.0 means the champion shoots projectiles.
@export var is_ranged := false
@export var projectile_color := Color(0.6, 0.75, 1.0)
@export var projectile_speed := 0.0           ## m/s of the auto-attack bolt (0 = the Unit default).
## Model attack style (`spear_thrust`, `sword_slash`, `great_cleave`, `staff_bolt`); the model reads it through
## `set_weapon_class(class_id)`.
@export var attack_style: StringName = &""

@export_group("Stats")
## The modifier `class:<id>` (Stats contract: flat or `_pct` values).
@export var stats: Dictionary = {}
## Added to the archetype's flee threshold (HP ratio): -0.05 flees later, +0.05 sooner.
@export var flee_delta := 0.0

@export_group("Skills")
## The 3 class skills in unlock order (ChampionAbilities ids).
@export var ability_ids: Array[StringName] = []
## The champion level each skill unlocks at ([2, 3, 5]).
@export var unlock_levels: Array[int] = [2, 3, 5]

@export_group("Draw and UI")
## The bounty kind that leans to this class (`explore`, `guard`, `hunt`, `escort`).
@export var bounty_kind: StringName = &""
## Short text for placeholder icons ("SS").
@export var icon_abbrev := ""
## "Sword and Shield · melee · +10 armor · 12 damage every 1.1 s".
@export var tooltip := ""

static var _cache: Dictionary = {}


## The class `id_or_name` (&"sword_shield", or "Sword and Shield" / "sword shield"). Null if unknown.
static func find(id_or_name: Variant) -> ChampionClass:
	var key := _key(id_or_name)
	if key == "":
		return null
	if _cache.has(key):
		return _cache[key]
	var path := DIR + key + ".tres"
	if not ResourceLoader.exists(path):
		for cid in IDS:   # display names ("Two-Hand Sword")
			var c := find(cid)
			if c and _key(c.display_name) == key:
				_cache[key] = c
				return c
		return null
	var cls := load(path) as ChampionClass
	if cls:
		_cache[key] = cls
	return cls


## The four classes in IDS order (missing files are skipped).
static func all() -> Array[ChampionClass]:
	var out: Array[ChampionClass] = []
	for cid in IDS:
		var c := find(cid)
		if c:
			out.append(c)
	return out


## Class id -> draw weight for `champion` right now (2.1): its archetype's `class_weights` plus 20 per bounty
## of the leaning kind it was paid before level 2 (`champion.bounty_leans`, kind -> count), at most +40 per class.
## Every id of IDS is present (0 when a class has no weight).
static func weights_for(champion: Object) -> Dictionary:
	var type: Variant = champion.get(&"champion_type") if champion != null else null
	var leans: Variant = champion.get(&"bounty_leans") if champion != null else null
	return weights_from(type as Resource if type is Resource else null, leans if leans is Dictionary else {})


## weights_for without a champion: an archetype (`class_weights`, null = equal weights) and bounty leans.
static func weights_from(type: Resource, leans: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {}
	if type != null:
		var cw: Variant = type.get(&"class_weights")
		if cw is Dictionary:
			base = cw
	var out := {}
	for cid in IDS:
		var w := DEFAULT_WEIGHT if base.is_empty() else float(base.get(cid, base.get(String(cid), 0.0)))
		var c := find(cid)
		if c and c.bounty_kind != &"":
			var n := int(leans.get(c.bounty_kind, leans.get(String(c.bounty_kind), 0)))
			w += minf(BOUNTY_LEAN_CAP, BOUNTY_LEAN_WEIGHT * float(maxi(0, n)))
		out[cid] = maxf(0.0, w)
	return out


## Class id -> chance 0..1 of each class for `champion` right now (the inspect lean tooltip).
static func chances_for(champion: Object) -> Dictionary:
	var w := weights_for(champion)
	var total := 0.0
	for cid: StringName in w:
		total += float(w[cid])
	var out := {}
	for cid: StringName in w:
		out[cid] = float(w[cid]) / total if total > 0.0 else 0.0
	return out


## The class an archetype leans to (highest base weight; the tavern's "usually Sword and Shield"), or null.
static func usual_for(type: Resource) -> ChampionClass:
	var w := weights_from(type)
	var best: StringName = &""
	for cid in IDS:
		if best == &"" or float(w[cid]) > float(w[best]):
			best = cid
	return find(best)


## Draws `champion`'s class with weights_for(champion). `rng` null = a freshly randomized generator.
## Returns the class id (&"" only when no class file exists).
static func pick(champion: Object, rng: RandomNumberGenerator = null) -> StringName:
	var w := weights_for(champion)
	var total := 0.0
	for cid in IDS:
		if find(cid):
			total += float(w.get(cid, 0.0))
	if total <= 0.0:
		return &""
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var roll := rng.randf() * total
	var last: StringName = &""
	for cid in IDS:
		var wc := float(w.get(cid, 0.0))
		if wc <= 0.0 or find(cid) == null:
			continue
		last = cid
		if roll < wc:
			return cid
		roll -= wc
	return last   # float rounding at the very top of the range


## The bounty kind name (&"hunt"...) of a `Bounty.kind` int or a kind name; &"" when unknown.
static func bounty_kind_name(kind: Variant) -> StringName:
	if kind is int:
		return BOUNTY_KINDS[kind] if kind >= 0 and kind < BOUNTY_KINDS.size() else &""
	var s := StringName(str(kind).strip_edges().to_lower())
	return s if BOUNTY_KINDS.has(s) else &""


## "class:<id>", the stat modifier this class adds.
func modifier_id() -> StringName:
	return StringName(MODIFIER_PREFIX + String(id))


## How many of the 3 class skills are unlocked at `level` (0-3).
func skills_unlocked_at(level: int) -> int:
	var n := 0
	for l in unlock_levels:
		if level >= l:
			n += 1
	return n


## The level `ability_id` unlocks at (0 when it is not one of this class's skills).
func unlock_level_of(ability_id: StringName) -> int:
	var i := ability_ids.find(ability_id)
	return unlock_levels[i] if i >= 0 and i < unlock_levels.size() else 0


static func _key(v: Variant) -> String:
	var key := str(v).strip_edges().to_lower().replace("-", "_").replace(" and ", "_").replace(" ", "_")
	if key.begins_with("the_"):
		key = key.substr(4)
	return key
