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

const UNIT_DIR := "res://data/units/"
const BUILDING_DIR := "res://data/buildings/"

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
const BOT_CHECK_FRAMES := 15   ## physics frames between two looks for a new bot profile

static var _holders := 0
static var _originals: Array = []   # [[Resource, field, old value]] while applied
static var _held: Array[Resource] = []

var _patched := {}   # AIProfile instance id -> true
var _frames := 0


## Call from the level's _ready before anything is built. `fast` true: apply the A2 values (once per run of Fast
## levels) and add the PaceSwitch node that patches the bots and undoes everything when the level leaves.
static func setup(level: Node, fast: bool) -> PaceSwitch:
	if not fast or level == null:
		return null
	var node := PaceSwitch.new()
	node.name = "PaceSwitch"
	level.add_child(node)
	return node


## True while the A2 values are in the loaded resources.
static func is_applied() -> bool:
	return not _originals.is_empty()


func _enter_tree() -> void:
	_holders += 1
	if _holders == 1:
		apply_resources()


func _exit_tree() -> void:
	_holders = maxi(0, _holders - 1)
	if _holders == 0:
		restore_resources()


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
		if ai == null or _patched.has(ai.get_instance_id()):
			continue
		_patched[ai.get_instance_id()] = true
		patch_ai(ai)


## The A2 aggression knobs on one profile (in place).
static func patch_ai(ai: AIProfile) -> void:
	for k: String in AI_KNOBS:
		if not (StringName(k) in ai):
			continue
		var old: Variant = ai.get(StringName(k))
		var v := _resolve(float(old), AI_KNOBS[k])
		ai.set(StringName(k), roundi(v) if old is int else v)


## Edits the cached resources (no-op when already applied).
static func apply_resources() -> void:
	if is_applied():
		return
	for id in SOLDIERS:
		_edit(UNIT_DIR, id, &"train_time", SOLDIER_TRAIN_X)
	for id in WORKERS:
		_edit(UNIT_DIR, id, &"train_time", WORKER_TRAIN_X)
	for id in BUILDINGS:
		_edit(BUILDING_DIR, id, &"max_hp", BUILDING_HP_X)
	for id in WALLS:
		_edit(BUILDING_DIR, id, &"max_hp", WALL_HP_X)
	for id in TURRETS:
		_edit(BUILDING_DIR, id, &"attack_damage", TURRET_DAMAGE_X)


## Puts every edited value back (no-op when nothing is applied).
static func restore_resources() -> void:
	for i in range(_originals.size() - 1, -1, -1):
		var row: Array = _originals[i]
		(row[0] as Resource).set(row[1], row[2])
	_originals.clear()
	_held.clear()


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
	_held.append(res)   # keep the edited resource referenced so the cache keeps it
	_originals.append([res, field, old])
	var v := float(old) * mult
	res.set(field, roundi(v) if old is int else v)


static func _resolve(old: float, spec: Variant) -> float:
	if spec is int or spec is float:
		return float(spec)
	var s := String(spec)
	if s.begins_with("x"):
		return old * s.substr(1).to_float()
	return s.to_float()
