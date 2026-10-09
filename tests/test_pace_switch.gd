extends SceneTree
## Skirmish "Pace: Normal / Fast (test)" (PaceSwitch, A2 of docs/balance/faster_games_2026-10-06.md).
## Checks: the setting (off by default, saved, put on the level, in SaveGame.LEVEL_PROPS); the A2 values match
## tools/balance_lab/variants/fg_a2_strong.json; Normal changes nothing; Fast edits the types and bot knobs and the
## defaults come back exactly when the level leaves; a real Fast skirmish starts with the edited keep and bot knobs.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_pace_switch.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "pace_switch"
const VARIANT := "res://tools/balance_lab/variants/fg_a2_strong.json"
const SCENE := "res://scenes/skirmish.tscn"
const TIMEOUT_FRAMES := 3600

var _fails: Array[String] = []
var _defaults := {}   # "dir|id|field" -> value before any switch
var _level: Node
var _frame := 0
var _phase := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	GameSettings.use_test_file()


## Frame 1 (the root is in the tree now): the unit checks, then a real Fast skirmish.
func _start() -> void:
	_check_settings()
	_snapshot_defaults()
	_check_variant_match()
	_check_normal_and_fast()
	_level = load(SCENE).instantiate()
	GameSettings.pace_fast = true
	_expect(GameSettings.apply_pace(_level) and bool(_level.get(&"fast_pace")), "apply_pace sets fast_pace")
	GameSettings.pace_fast = false
	root.add_child(_level)
	current_scene = _level


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_start()
		return false
	if _phase == 0:
		if _level.get(&"match_started") and _check_live():
			_phase = 1
			_level.queue_free()
			_level = null
			return false
		if _frame > TIMEOUT_FRAMES:
			_fails.append("Fast skirmish: the keep / bot knobs never showed the A2 values")
			return _finish()
		return false
	if _phase == 1:   # one frame after the level left
		_expect(not PaceSwitch.is_applied(), "values still applied after the Fast level left")
		_expect(_changed_from_defaults().is_empty(), "defaults not restored after the Fast skirmish: %s"
				% str(_changed_from_defaults().slice(0, 5)))
		return _finish()
	return false


func _finish() -> bool:
	GameSettings.reset_defaults()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _check_settings() -> void:
	_expect(GameSettings.pace_fast == false, "Pace defaults to Normal")
	GameSettings.set_pace_fast(true)
	GameSettings.pace_fast = false
	GameSettings.load_settings()
	_expect(GameSettings.pace_fast == true, "Fast is saved in the settings file")
	GameSettings.set_pace_fast(false)
	GameSettings.load_settings()
	_expect(GameSettings.pace_fast == false, "Normal is saved in the settings file")
	_expect(SaveGame.LEVEL_PROPS.has(&"fast_pace"), "SaveGame.LEVEL_PROPS stores fast_pace")
	var plain := Node.new()
	_expect(not GameSettings.apply_pace(plain), "apply_pace set a node without fast_pace")
	plain.free()
	var sk: Node = load(SCENE).instantiate()
	_expect(sk.get(&"fast_pace") == false, "Skirmish.fast_pace defaults to false")
	sk.set(&"fast_pace", true)
	var info := SaveGame.level_info(sk)
	_expect(bool((info.get("props", {}) as Dictionary).get("fast_pace", false)), "a save captures fast_pace = true")
	sk.free()


func _key(dir: String, id: String, field: String) -> String:
	return "%s|%s|%s" % [dir, id, field]


func _all_entries() -> Array:   # [dir, id, field, mult]
	var out: Array = []
	for id in PaceSwitch.SOLDIERS:
		out.append([PaceSwitch.UNIT_DIR, id, "train_time", PaceSwitch.SOLDIER_TRAIN_X])
	for id in PaceSwitch.WORKERS:
		out.append([PaceSwitch.UNIT_DIR, id, "train_time", PaceSwitch.WORKER_TRAIN_X])
	for id in PaceSwitch.BUILDINGS:
		out.append([PaceSwitch.BUILDING_DIR, id, "max_hp", PaceSwitch.BUILDING_HP_X])
	for id in PaceSwitch.WALLS:
		out.append([PaceSwitch.BUILDING_DIR, id, "max_hp", PaceSwitch.WALL_HP_X])
	for id in PaceSwitch.TURRETS:
		out.append([PaceSwitch.BUILDING_DIR, id, "attack_damage", PaceSwitch.TURRET_DAMAGE_X])
	return out


func _snapshot_defaults() -> void:
	for e: Array in _all_entries():
		var path := String(e[0]) + String(e[1]) + ".tres"
		_expect(ResourceLoader.exists(path), "missing %s" % path)
		if ResourceLoader.exists(path):
			_defaults[_key(e[0], e[1], e[2])] = load(path).get(StringName(e[2]))


func _changed_from_defaults() -> Array:
	var out: Array = []
	for e: Array in _all_entries():
		var k := _key(e[0], e[1], e[2])
		if _defaults.has(k) and load(String(e[0]) + String(e[1]) + ".tres").get(StringName(e[2])) != _defaults[k]:
			out.append(k)
	return out


## PaceSwitch's lists = the variant's units / buildings / fg.ai blocks, entry for entry.
func _check_variant_match() -> void:
	var f := FileAccess.open(VARIANT, FileAccess.READ)
	_expect(f != null, "can't read %s" % VARIANT)
	if f == null:
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var want := {}
	for section: String in ["units", "buildings"]:
		var dir := PaceSwitch.UNIT_DIR if section == "units" else PaceSwitch.BUILDING_DIR
		for id: String in data[section]:
			for field: String in data[section][id]:
				want[_key(dir, id, field)] = String(data[section][id][field])
	var have := {}
	for e: Array in _all_entries():
		have[_key(e[0], e[1], e[2])] = "x%s" % str(e[3])
	_expect(have.size() == want.size(), "PaceSwitch has %d overrides, the variant %d" % [have.size(), want.size()])
	for k: String in want:
		_expect(have.get(k, "") == want[k], "%s: PaceSwitch %s, variant %s" % [k, have.get(k, "-"), want[k]])
	var ai_want: Dictionary = data["fg"]["ai"]
	_expect(ai_want.size() == PaceSwitch.AI_KNOBS.size(), "AI knob count differs from the variant")
	for k: String in ai_want:
		var mine: Variant = PaceSwitch.AI_KNOBS.get(k, "-")
		var same := is_equal_approx(float(mine), float(ai_want[k])) if ai_want[k] is float else str(mine) == str(ai_want[k])
		_expect(same, "fg.ai.%s differs from the variant" % k)


func _check_normal_and_fast() -> void:
	# Normal: no node, nothing changes.
	var lvl := Node.new()
	root.add_child(lvl)
	_expect(PaceSwitch.setup(lvl, false) == null, "Normal added a PaceSwitch")
	_expect(not PaceSwitch.is_applied() and _changed_from_defaults().is_empty(), "Normal changed the data")
	# Fast: every value = default x mult.
	var node := PaceSwitch.setup(lvl, true)
	_expect(node != null and PaceSwitch.is_applied(), "Fast did not apply")
	for e: Array in _all_entries():
		var k := _key(e[0], e[1], e[2])
		var old: Variant = _defaults.get(k)
		var now: Variant = load(String(e[0]) + String(e[1]) + ".tres").get(StringName(e[2]))
		var expect: Variant = roundi(float(old) * float(e[3])) if old is int else float(old) * float(e[3])
		_expect(is_equal_approx(float(now), float(expect)), "%s: %s, want %s" % [k, str(now), str(expect)])
	# A second Fast level (restart / reload overlap) must not apply twice nor restore early.
	var lvl2 := Node.new()
	root.add_child(lvl2)
	PaceSwitch.setup(lvl2, true)
	var keep_now := float(load(PaceSwitch.BUILDING_DIR + "fire_keep.tres").get(&"max_hp"))
	_expect(is_equal_approx(keep_now, roundi(float(_defaults[_key(PaceSwitch.BUILDING_DIR, "fire_keep", "max_hp")]) * 0.6)),
			"a second Fast level applied the values twice")
	lvl.free()
	_expect(PaceSwitch.is_applied(), "values restored while a Fast level is still running")
	lvl2.free()
	_expect(not PaceSwitch.is_applied() and _changed_from_defaults().is_empty(), "defaults not restored after Fast")
	# Bot knobs on a normal profile.
	var ai := AIProfile.normal()
	var base := AIProfile.normal()
	PaceSwitch.patch_ai(ai)
	_expect(is_equal_approx(ai.attack_ratio, base.attack_ratio * 0.85), "attack_ratio x0.85")
	_expect(is_equal_approx(ai.attack_ratio_floor, base.attack_ratio_floor * 0.85), "attack_ratio_floor x0.85")
	_expect(is_equal_approx(ai.attack_patience, 60.0), "attack_patience 60")
	_expect(ai.attack_full_pop == 16, "attack_full_pop 16")
	_expect(is_equal_approx(ai.first_attack_by, 420.0), "first_attack_by 420")


## The running Fast skirmish: keeps use the edited types, every bot carries the A2 knobs (after its first tick).
func _check_live() -> bool:
	if not PaceSwitch.is_applied():
		return false
	for team in [0, 1]:
		var k: Node = _level.call(&"keep_of", team)
		if k == null:
			return false
		var bt: Resource = k.get(&"building_type")
		var key := _key(PaceSwitch.BUILDING_DIR, String(bt.get(&"id")), "max_hp")
		if not _defaults.has(key) or float(bt.get(&"max_hp")) >= float(_defaults[key]):
			return false
	var bots := 0
	for c in _level.get_children():
		if c is Commander:
			var ai := (c as Commander).ai
			if ai == null or not is_equal_approx(ai.first_attack_by, 420.0) or ai.attack_full_pop != 16 \
					or (c as Commander).faction == &"":
				return false
			bots += 1
	return bots > 0
