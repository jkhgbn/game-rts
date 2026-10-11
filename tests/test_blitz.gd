extends SceneTree
## Skirmish "Pace: Blitz" (PaceSwitch.BLITZ, docs/balance/blitz_2026-10-10.md).
## Checks: the setting (off by default, saved, exclusive with Fast, put on the level); Normal and Fast leave the Blitz
## extras alone (3 workers, tier factor 1); the Blitz values are applied only in Blitz and the defaults come back when
## the level leaves; a real Blitz skirmish spawns PaceSwitch.BLITZ start_workers per side, speeds the tiers up and
## patches the bots; a save of it keeps the mode (SaveGame.LEVEL_PROPS) and a load rebuilds a Blitz level.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_blitz.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "blitz"
const SCENE := "res://scenes/skirmish.tscn"
const SAVE_PATH := "user://test_blitz.save"
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


func _start() -> void:
	_check_settings()
	_snapshot_defaults()
	_check_values()
	_level = load(SCENE).instantiate()
	GameSettings.pace_blitz = true
	_expect(GameSettings.apply_pace(_level) and bool(_level.get(&"blitz_pace")), "apply_pace sets blitz_pace")
	_expect(not bool(_level.get(&"fast_pace")), "Blitz also set fast_pace")
	GameSettings.pace_blitz = false
	root.add_child(_level)
	current_scene = _level


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_start()
		return false
	if _phase == 0:
		if _level.get(&"match_started") and _check_live():
			_check_save_load()
			_phase = 1
			_level.queue_free()
			_level = null
			return false
		if _frame > TIMEOUT_FRAMES:
			_fails.append("Blitz skirmish: workers / tiers / bot knobs never showed the Blitz values")
			return _finish()
		return false
	if _phase == 1:   # one frame after the level left
		_expect(not PaceSwitch.is_applied() and not PaceSwitch.is_blitz(), "values still applied after Blitz left")
		_expect(is_equal_approx(Engine.time_scale, 1.0), "game speed not restored after Blitz left")
		_expect(_changed_from_defaults().is_empty(), "defaults not restored after the Blitz skirmish: %s"
				% str(_changed_from_defaults().slice(0, 5)))
		return _finish()
	return false


func _finish() -> bool:
	GameSettings.reset_defaults()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _check_settings() -> void:
	_expect(not GameSettings.pace_blitz and GameSettings.pace_mode() == GameSettings.PACE_NORMAL, "Pace defaults to Normal")
	GameSettings.set_pace_mode(GameSettings.PACE_BLITZ)
	GameSettings.pace_blitz = false
	GameSettings.load_settings()
	_expect(GameSettings.pace_blitz and not GameSettings.pace_fast, "Blitz is saved in the settings file")
	_expect(GameSettings.pace_mode() == GameSettings.PACE_BLITZ, "pace_mode() reads Blitz")
	GameSettings.set_pace_fast(true)
	_expect(GameSettings.pace_fast and not GameSettings.pace_blitz, "Fast clears Blitz")
	GameSettings.set_pace_mode(GameSettings.PACE_NORMAL)
	GameSettings.load_settings()
	_expect(not GameSettings.pace_fast and not GameSettings.pace_blitz, "Normal is saved in the settings file")
	_expect(SaveGame.LEVEL_PROPS.has(&"blitz_pace"), "SaveGame.LEVEL_PROPS stores blitz_pace")
	var sk: Node = load(SCENE).instantiate()
	_expect(sk.get(&"blitz_pace") == false, "Skirmish.blitz_pace defaults to false")
	sk.free()
	# The level-side helpers: Normal / Fast keep the normal start.
	_expect(PaceSwitch.start_workers(false) == 3, "start_workers outside Blitz != 3")
	_expect(PaceSwitch.start_crystals_add(false) == 0, "start crystals added outside Blitz")
	_expect(is_equal_approx(PaceSwitch.tier_time_x(false), 1.0), "tier factor outside Blitz != 1")
	_expect(PaceSwitch.start_workers(true) == int(PaceSwitch.BLITZ["start_workers"]), "Blitz start_workers")
	_expect(int(PaceSwitch.BLITZ["start_workers"]) == 9, "Blitz should start with 9 workers (JS 2026-10-10)")
	_expect(PaceSwitch.tuning.is_empty(), "PaceSwitch.tuning (lab only) is set in the game")


func _key(dir: String, id: String, field: String) -> String:
	return "%s|%s|%s" % [dir, id, field]


## [dir, id, field, Blitz factor] for every Blitz edit.
func _entries() -> Array:
	var b := PaceSwitch.BLITZ
	var out: Array = []
	for id in PaceSwitch.SOLDIERS:
		var path := PaceSwitch.UNIT_DIR + id + ".tres"
		var faction: StringName = load(path).get(&"faction") if ResourceLoader.exists(path) else &""
		out.append([PaceSwitch.UNIT_DIR, id, "train_time", PaceSwitch.kingdom_factor(b["soldier_train_x"], faction)])
	for id in PaceSwitch.WORKERS:
		out.append([PaceSwitch.UNIT_DIR, id, "train_time", b["worker_train_x"]])
		out.append([PaceSwitch.UNIT_DIR, id, "max_hp", b["worker_hp_x"]])
	for id in PaceSwitch.BUILDINGS:
		out.append([PaceSwitch.BUILDING_DIR, id, "max_hp",
				b["keep_hp_x"] if PaceSwitch.KEEPS.has(id) else b["building_hp_x"]])
	for id in PaceSwitch.WALLS:
		out.append([PaceSwitch.BUILDING_DIR, id, "max_hp", b["wall_hp_x"]])
	for id in PaceSwitch.TURRETS:
		out.append([PaceSwitch.BUILDING_DIR, id, "attack_damage",
				b["keep_damage_x"] if PaceSwitch.KEEPS.has(id) else b["turret_damage_x"]])
	return out


func _snapshot_defaults() -> void:
	for e: Array in _entries():
		var path := String(e[0]) + String(e[1]) + ".tres"
		if ResourceLoader.exists(path):
			_defaults[_key(e[0], e[1], e[2])] = load(path).get(StringName(e[2]))


func _changed_from_defaults() -> Array:
	var out: Array = []
	for k: String in _defaults:
		var parts := k.split("|")
		var now: Variant = load(parts[0] + parts[1] + ".tres").get(StringName(parts[2]))
		if not is_equal_approx(float(now), float(_defaults[k])):
			out.append(k)
	return out


func _check_values() -> void:
	var lvl := Node.new()
	root.add_child(lvl)
	_expect(PaceSwitch.setup(lvl, false, false) == null, "Normal added a PaceSwitch")
	_expect(_changed_from_defaults().is_empty(), "Normal changed the data")
	# Fast is not Blitz.
	var fast := PaceSwitch.setup(lvl, true, false)
	_expect(fast != null and PaceSwitch.is_applied() and not PaceSwitch.is_blitz(), "Fast reads as Blitz")
	fast.free()
	_expect(_changed_from_defaults().is_empty(), "defaults not restored after Fast")
	# Blitz: every value = default x its Blitz factor.
	var node := PaceSwitch.setup(lvl, false, true)
	_expect(node != null and PaceSwitch.is_blitz(), "Blitz did not apply")
	_expect(is_equal_approx(PaceSwitch.worker_spell_x, float(PaceSwitch.BLITZ["worker_spell_x"])),
			"Blitz worker spell factor not applied")
	for e: Array in _entries():
		var k := _key(e[0], e[1], e[2])
		if not _defaults.has(k):
			continue
		var old: Variant = _defaults[k]
		var now: Variant = load(String(e[0]) + String(e[1]) + ".tres").get(StringName(e[2]))
		var expect: Variant = roundi(float(old) * float(e[3])) if old is int else float(old) * float(e[3])
		_expect(is_equal_approx(float(now), float(expect)), "%s: %s, want %s" % [k, str(now), str(expect)])
	lvl.free()
	_expect(not PaceSwitch.is_applied() and _changed_from_defaults().is_empty(), "defaults not restored after Blitz")
	_expect(is_equal_approx(PaceSwitch.worker_spell_x, 1.0), "worker spell factor not restored after Blitz")
	# Bot knobs: Blitz's own dictionary.
	var ai := AIProfile.normal()
	PaceSwitch.patch_ai(ai, PaceSwitch.BLITZ["ai"])
	var knobs: Dictionary = PaceSwitch.BLITZ["ai"]
	if knobs.has("first_attack_by"):
		_expect(is_equal_approx(ai.first_attack_by, float(knobs["first_attack_by"])), "Blitz first_attack_by")
	# Per-kingdom knobs (Blitz "ai_kingdom") on top of the shared ones.
	var per: Dictionary = PaceSwitch.BLITZ["ai_kingdom"]
	for kingdom: String in per:
		var kai := AIProfile.normal()
		PaceSwitch.patch_ai(kai, per[kingdom])
		for k: String in per[kingdom]:
			_expect(StringName(k) in kai, "ai_kingdom.%s.%s: no such AIProfile knob" % [kingdom, k])


## The running Blitz skirmish: start workers, tier factor, keep HP, bot knobs (after the bot's first tick).
func _check_live() -> bool:
	if not PaceSwitch.is_blitz():
		return false
	var want := int(PaceSwitch.BLITZ["start_workers"])
	for team in [0, 1]:
		var workers: Array = _level.call(&"workers_of", team)
		if workers.size() < want:
			return false
		_expect(workers.size() == want, "team %d starts with %d workers, want %d" % [team, workers.size(), want])
		var k: Node = _level.call(&"keep_of", team)
		if k == null:
			return false
		var bt: Resource = k.get(&"building_type")
		var key := _key(PaceSwitch.BUILDING_DIR, String(bt.get(&"id")), "max_hp")
		_expect(_defaults.has(key) and is_equal_approx(float(bt.get(&"max_hp")),
				roundi(float(_defaults[key]) * float(PaceSwitch.BLITZ["keep_hp_x"]))), "Blitz keep HP")
	_expect(is_equal_approx(Engine.time_scale, float(PaceSwitch.BLITZ["game_speed"])), "Blitz game speed not applied")
	var ts: Node = _level.get(&"tier_system")
	_expect(ts != null and is_equal_approx(float(ts.get(&"pace_time_x")), float(PaceSwitch.BLITZ["tier_time_x"])),
			"TierSystem.pace_time_x is not Blitz's")
	var knobs: Dictionary = PaceSwitch.BLITZ["ai"]
	var bots := 0
	for c in _level.get_children():
		if c is Commander:
			var ai := (c as Commander).ai
			if ai == null or (c as Commander).faction == &"":
				return false
			if knobs.has("first_attack_by") and not is_equal_approx(ai.first_attack_by, float(knobs["first_attack_by"])):
				return false
			bots += 1
	return bots > 0


## A save of the Blitz match keeps the mode; a load rebuilds the level with blitz_pace on.
func _check_save_load() -> void:
	var data := SaveGame.capture(_level)
	var props: Dictionary = (data.get("level", {}) as Dictionary).get("props", {})
	_expect(bool(props.get("blitz_pace", false)), "a save captures blitz_pace = true")
	_expect(SaveGame.write_file(SAVE_PATH, data) == "", "could not write the test save")
	var back := SaveGame.read_file(SAVE_PATH)
	var lvl := SaveGame.instantiate_level(back)
	_expect(lvl != null and bool(lvl.get(&"blitz_pace")), "a load lost blitz_pace")
	if lvl:
		lvl.free()
