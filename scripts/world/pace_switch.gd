class_name PaceSwitch
extends Node
## Skirmish option "Pace: Normal / Fast (test)" (docs/balance/faster_games_2026-10-06.md, experiment A2 =
## tools/balance_lab/variants/fg_a2_strong.json). OFF by default; nothing in data/ changes. With Fast, at match start
## (Skirmish._ready, before any building) the loaded UnitType / BuildingType resources are edited IN MEMORY:
## buildings -40 % HP (walls -50 %), keeps / towers -40 % damage, soldiers train 30 % faster, workers 40 % faster;
## and every bot's AIProfile gets the A2 aggression knobs (patched again when the Commander swaps its preset for the
## kingdom profile on its first tick). The edits are undone when the last Fast level leaves the tree, so the next
## match (or a mission) sees the normal data. Values are copied from fg_a2_strong.json (tools/ is not exported);
## tests/test_pace_switch.gd checks they still match it.
## Use: `PaceSwitch.setup(level, fast)` from the level's _ready. One PaceSwitch node rides along with a Fast level.
## Blitz (JS 2026-10-10, docs/balance/blitz_2026-10-10.md): `PaceSwitch.setup(level, false, true)`. Same mechanism with
## the BLITZ values (stronger than A2: start workers, start crystals, faster keep tiers, own keep / tower factors, own
## bot knobs); the level reads `start_workers()` / `start_crystals_add()` / `tier_time_x()` while it builds the start.

const UNIT_DIR := "res://data/units/"
const BUILDING_DIR := "res://data/buildings/"
const SPELL_DIR := "res://data/spells/"

const SOLDIER_TRAIN_X := 0.7
const WORKER_TRAIN_X := 0.6
const BUILDING_HP_X := 0.6
const WALL_HP_X := 0.5
const TURRET_DAMAGE_X := 0.6

const SOLDIERS: Array[String] = ["ash_hurler", "ashveil_saboteur", "barrow_ghoul", "barrow_knight", "blaze_rider",
		"bleakbow", "bloomtender", "bramble_harrier", "bramblehorn", "bramblesage", "briar_roc", "burr_slinger",
		"cinder_arbalest", "duskbolt_harrier", "ember_archer", "emberdart_harrier", "flame_guard", "frost_mortar",
		"frostbow", "frostcrown_juggernaut", "glade_outrider", "gloam_rider", "gloom_deacon", "grave_hound",
		"greenheart_oathkeeper", "hexweaver", "hoarlight_magebow", "hollow_oathsworn", "kilnwarden",
		"nightblood_reaver", "nightbolt", "pyre_adept", "pyrehoof_lancer", "rime_colossus", "rime_harrier", "rime_seer",
		"rimecarver", "rimehorn_rider", "rimeling", "rimeshield", "scorchbow", "scorchling", "shade", "shadow_knight",
		"shardcaster", "shardguard", "snowdrift_rider", "stagrunner", "sunforge_cataphract", "thistle_darter",
		"thornback_charger", "thornling", "veilborn_dreadrider", "vinelasher", "wildwood_archer"]
const WORKERS: Array[String] = ["cinder_hand", "gloom_thrall", "rime_hauler", "sprigling"]
const BUILDINGS: Array[String] = ["fire_barracks", "fire_forge", "fire_hearth", "fire_keep", "fire_market",
		"fire_stables", "fire_tower", "fire_watch_keep", "ice_barracks", "ice_forge", "ice_keep", "ice_lodge",
		"ice_market", "ice_stables", "ice_tower", "nature_barracks", "nature_forge", "nature_hollow", "nature_keep",
		"nature_market", "nature_stables", "nature_tower", "shadow_barracks", "shadow_forge", "shadow_hovel",
		"shadow_keep", "shadow_market", "shadow_stables", "shadow_tower"]
const WALLS: Array[String] = ["ice_wall"]
const TURRETS: Array[String] = ["fire_keep", "fire_tower", "fire_watch_keep", "ice_keep", "ice_tower", "nature_keep",
		"nature_tower", "shadow_keep", "shadow_tower"]
## AIProfile knobs: a number = set, "x0.85" = multiply (same format as the Balance Lab variants).
const AI_KNOBS := {"attack_ratio": "x0.85", "attack_ratio_floor": "x0.85", "attack_patience": 60,
		"attack_full_pop": 16, "first_attack_by": 420}
## Blitz values (docs/balance/blitz_2026-10-10.md, tuned with the faster-games lab arm "blitz").
const BLITZ := {
	"soldier_train_x": {"fire": 0.9, "ice": 0.35, "default": 0.5},   # per kingdom (Fire's lead in Blitz, Ice's lag)
	"worker_train_x": 0.6, "worker_hp_x": 2.0,   # sturdier workers: 9 in a line must survive an early raid
	"building_hp_x": 0.3, "wall_hp_x": 0.4, "turret_damage_x": 0.5,
	"keep_hp_x": 0.4, "keep_damage_x": 0.6,   # the four kingdom keeps (own factors)
	"start_workers": 9,
	"start_crystals_add": {"fire": 0, "nature": 100, "shadow": 500, "ice": 800},   # per kingdom (balance lever)
	"tier_time_x": 0.5,
	"game_speed": 1.3,   # Engine.time_scale while the Blitz level runs (1.0 = real time)
	"ai": {"attack_ratio": "x0.9", "attack_ratio_floor": "x0.9", "attack_patience": 45, "attack_full_pop": 10,
			"first_attack_by": 300, "retreat_hp": 0.25, "worker_target_home": 9, "worker_target_expanded": 12,
			"worker_target_x2": 14},
	## 10-10 v20: attack_ratio / floor x0.9 (x0.75 sent armies into the defender, who won 67-75 %).
	## Per-kingdom bot knobs on top of "ai" (same format), e.g. {"ice": {"attack_ratio": "x0.8"}}.
	"ai_kingdom": {"ice": {"min_attack_pop": 6, "attack_ratio": "x0.8", "attack_ratio_floor": "x0.8",
			"attack_reserve": 1}},   # v18: the Ice bot sat on ~12 pop at home (min pop 8 + a 2-soldier reserve)
	## Spell damage taken by workers (SpellCaster.deal_damage): AoE spells on a 9-worker line.
	"worker_spell_x": 0.5,
	## Wizard spell damage by the caster's kingdom (SpellCaster.deal_damage), e.g. {"fire": 0.75}; missing = 1.0.
	"spell_damage_x": {},
	## SpellType resources scaled in memory while Blitz is applied (damage + every damage_by_rank entry), by spell id.
	## 10-12 arm D (docs/balance/shadow_fire_2026-10-12/report.md 4 item 7): Fireball x0.75 (60 -> 45).
	"spell_type_x": {"fireball": 0.75},
}
const KEEPS: Array[String] = ["fire_keep", "ice_keep", "nature_keep", "shadow_keep"]
const BOT_CHECK_FRAMES := 15   ## physics frames between two looks for a new bot profile

## Lab only (tools/balance_lab/faster_games, fg "blitz" block): keys here replace BLITZ's while tuning. Empty in game.
static var tuning: Dictionary = {}
static var _holders := 0
static var _blitz := false   # the applied values are the Blitz ones
static var _old_time_scale := -1.0   # Engine.time_scale before Blitz changed it (-1 = untouched)
static var _originals: Array = []   # [[Resource, field, old value]] while applied
static var _held: Array[Resource] = []
## Spell damage factor on workers while Blitz is applied (1.0 otherwise); read by SpellCaster.deal_damage.
static var worker_spell_x := 1.0
static var spell_x_by_kingdom := {}   ## Blitz "spell_damage_x" while applied ({} otherwise)
static var spell_mods_on := false     ## any of the two above differs from 1.0 (cheap check in deal_damage)

var blitz := false
var _patched := {}   # AIProfile instance id -> true
var _patched_kingdom := {}   # AIProfile instance id -> true (Blitz "ai_kingdom", once the faction is known)
var _frames := 0


## Call from the level's _ready before anything is built. `fast` true: apply the A2 values (once per run of Fast
## levels) and add the PaceSwitch node that patches the bots and undoes everything when the level leaves.
static func setup(level: Node, fast: bool, blitz_on := false) -> PaceSwitch:
	if not (fast or blitz_on) or level == null:
		return null
	var node := PaceSwitch.new()
	node.blitz = blitz_on
	node.name = "PaceSwitch"
	level.add_child(node)
	return node


## True while the A2 values are in the loaded resources.
static func is_applied() -> bool:
	return not _originals.is_empty()


func _enter_tree() -> void:
	_holders += 1
	if _holders == 1:
		apply_resources(blitz)
		if blitz and not is_equal_approx(float(blitz_value("game_speed")), 1.0):
			_old_time_scale = Engine.time_scale
			Engine.time_scale = float(blitz_value("game_speed"))


func _exit_tree() -> void:
	_holders = maxi(0, _holders - 1)
	if _holders == 0:
		restore_resources()
		if _old_time_scale > 0.0:
			Engine.time_scale = _old_time_scale
			_old_time_scale = -1.0


func _physics_process(_delta: float) -> void:
	_frames -= 1
	if _frames > 0:
		return
	_frames = BOT_CHECK_FRAMES
	patch_bots(get_parent())


## Patches every Commander child of `level` whose current AIProfile was not patched yet.
func patch_bots(level: Node) -> void:
	if level == null:
		return
	for c in level.get_children():
		if not (c is Commander):
			continue
		var ai := (c as Commander).ai
		if ai == null:
			continue
		if not _patched.has(ai.get_instance_id()):
			_patched[ai.get_instance_id()] = true
			patch_ai(ai, blitz_value("ai") if blitz else AI_KNOBS)
		var faction := (c as Commander).faction
		if blitz and faction != &"" and not _patched_kingdom.has(ai.get_instance_id()):
			_patched_kingdom[ai.get_instance_id()] = true
			var per: Dictionary = blitz_value("ai_kingdom")
			if per.has(String(faction)):
				patch_ai(ai, per[String(faction)])


## The A2 aggression knobs (or `knobs`, e.g. Blitz's) on one profile (in place).
static func patch_ai(ai: AIProfile, knobs: Dictionary = AI_KNOBS) -> void:
	for k: String in knobs:
		if not (StringName(k) in ai):
			continue
		var old: Variant = ai.get(StringName(k))
		var v := _resolve(float(old), knobs[k])
		ai.set(StringName(k), roundi(v) if old is int else v)


## A Blitz value (BLITZ, or the lab's `tuning` override).
static func blitz_value(key: String) -> Variant:
	return tuning.get(key, BLITZ[key])


## True while the applied values are the Blitz ones.
static func is_blitz() -> bool:
	return is_applied() and _blitz


## Workers each side starts with: 3, or Blitz's start_workers.
static func start_workers(blitz_on: bool) -> int:
	return maxi(3, int(blitz_value("start_workers"))) if blitz_on else 3


## Crystals added to a side's start bank (0 outside Blitz). BLITZ "start_crystals_add" is a number (every kingdom) or
## a Dictionary kingdom -> number (the Blitz kingdom balance lever: a missing kingdom gets 0).
static func start_crystals_add(blitz_on: bool, kingdom: StringName = &"") -> int:
	if not blitz_on:
		return 0
	var v: Variant = blitz_value("start_crystals_add")
	if v is Dictionary:
		return int((v as Dictionary).get(String(kingdom), 0))
	return int(v)


## Keep tier-up time factor (TierSystem.pace_time_x): earliest start, upgrade time, bot timeline. 1.0 outside Blitz.
static func tier_time_x(blitz_on: bool) -> float:
	return float(blitz_value("tier_time_x")) if blitz_on else 1.0


## Edits the cached resources (no-op when already applied). `blitz_on`: the Blitz values instead of A2.
static func apply_resources(blitz_on := false) -> void:
	if is_applied():
		return
	_blitz = blitz_on
	worker_spell_x = float(blitz_value("worker_spell_x")) if blitz_on else 1.0
	spell_x_by_kingdom = (blitz_value("spell_damage_x") as Dictionary).duplicate() if blitz_on else {}
	spell_mods_on = not is_equal_approx(worker_spell_x, 1.0) or not spell_x_by_kingdom.is_empty()
	var f := func(key: String, a2: float) -> float: return float(blitz_value(key)) if blitz_on else a2
	for id in SOLDIERS:
		var x := SOLDIER_TRAIN_X
		if blitz_on:
			x = kingdom_factor(blitz_value("soldier_train_x"), _faction_of(UNIT_DIR + id + ".tres"))
		_edit(UNIT_DIR, id, &"train_time", x)
	for id in WORKERS:
		_edit(UNIT_DIR, id, &"train_time", f.call("worker_train_x", WORKER_TRAIN_X))
		if blitz_on:
			_edit(UNIT_DIR, id, &"max_hp", float(blitz_value("worker_hp_x")))
	for id in BUILDINGS:
		var hp_x: float = f.call("keep_hp_x", BUILDING_HP_X) if KEEPS.has(id) else f.call("building_hp_x", BUILDING_HP_X)
		_edit(BUILDING_DIR, id, &"max_hp", hp_x)
	for id in WALLS:
		_edit(BUILDING_DIR, id, &"max_hp", f.call("wall_hp_x", WALL_HP_X))
	for id in TURRETS:
		var dmg_x: float = f.call("keep_damage_x", TURRET_DAMAGE_X) if KEEPS.has(id) 				else f.call("turret_damage_x", TURRET_DAMAGE_X)
		_edit(BUILDING_DIR, id, &"attack_damage", dmg_x)
	if blitz_on:
		var spells: Dictionary = blitz_value("spell_type_x")
		for sid: String in spells:
			_edit(SPELL_DIR, sid, &"damage", float(spells[sid]))
			_edit_array(SPELL_DIR, sid, &"damage_by_rank", float(spells[sid]))


## Blitz spell damage factor for one hit (worker_spell_x on workers, spell_damage_x by the caster's kingdom).
static func spell_damage_x(target: Node3D, attacker: Node3D) -> float:
	var x := 1.0
	if target is Unit and (target as Unit).is_worker():
		x *= worker_spell_x
	if not spell_x_by_kingdom.is_empty() and attacker != null and is_instance_valid(attacker) and &"kingdom" in attacker:
		x *= float(spell_x_by_kingdom.get(String(attacker.get(&"kingdom")), 1.0))
	return x


## A Blitz factor that is a number (every kingdom) or a Dictionary {"fire": 0.6, ..., "default": 0.5} (the Blitz
## kingdom balance lever; a kingdom not listed takes "default", else 1.0).
static func kingdom_factor(spec: Variant, faction: StringName) -> float:
	if spec is Dictionary:
		var d := spec as Dictionary
		return float(d.get(String(faction), d.get("default", 1.0)))
	return float(spec)


static func _faction_of(path: String) -> StringName:
	if not ResourceLoader.exists(path):
		return &""
	var res := load(path) as Resource
	return StringName(res.get(&"faction")) if res != null and &"faction" in res else &""


## Puts every edited value back (no-op when nothing is applied).
static func restore_resources() -> void:
	for i in range(_originals.size() - 1, -1, -1):
		var row: Array = _originals[i]
		(row[0] as Resource).set(row[1], row[2])
	_originals.clear()
	_held.clear()
	_blitz = false
	worker_spell_x = 1.0
	spell_x_by_kingdom = {}
	spell_mods_on = false


static func _edit(dir: String, id: String, field: StringName, mult: float) -> void:
	var path := dir + id + ".tres"
	if not ResourceLoader.exists(path):
		return
	var res := load(path) as Resource
	if res == null or not (field in res):
		return
	var old: Variant = res.get(field)
	if not (old is int or old is float):
		return
	if is_equal_approx(mult, 1.0):
		return
	_held.append(res)   # keep the edited resource referenced so the cache keeps it
	_originals.append([res, field, old])
	var v := float(old) * mult
	res.set(field, roundi(v) if old is int else v)


## Like _edit for an Array[float] field (every entry x mult); a new array is set, the old one is kept for the restore.
static func _edit_array(dir: String, id: String, field: StringName, mult: float) -> void:
	var path := dir + id + ".tres"
	if not ResourceLoader.exists(path) or is_equal_approx(mult, 1.0):
		return
	var res := load(path) as Resource
	if res == null or not (field in res):
		return
	var old: Variant = res.get(field)
	if not (old is Array):
		return
	var arr: Array[float] = []
	for v: Variant in old as Array:
		arr.append(float(v) * mult)
	_held.append(res)
	_originals.append([res, field, old])
	res.set(field, arr)


static func _resolve(old: float, spec: Variant) -> float:
	if spec is int or spec is float:
		return float(spec)
	var s := String(spec)
	if s.begins_with("x"):
		return old * s.substr(1).to_float()
	if s.begins_with("+"):
		return old + s.substr(1).to_float()
	return s.to_float()
