extends SceneTree
## B13 Cause 3 (docs/balance/b13_2026-10-13/diagnosis.md), ai-coder part, normal pace only.
## Part 0 (static): AIProfile.for_faction at normal pace: Shadow 7 home workers (Fire stays 6), Ice = Blitz's
## "ai_kingdom.ice" knobs (min pop 6, ratio / floor x0.8, reserve 1), Fire / Nature unchanged; with `paced` true every
## kingdom resolves exactly the pre-change profile, so Blitz's patches give the same knobs as before.
## Part 1 (live): four skirmishes (Blitz fire:shadow, Blitz ice:nature, Normal fire:shadow, Normal ice:nature), a
## normal-difficulty Commander on each side: Blitz bots carry the pre-change profile + PaceSwitch.BLITZ "ai" +
## "ai_kingdom" (every exported knob compared); normal bots carry for_faction(k, 1) (Shadow 7, Ice the Blitz knobs).
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_bal_cause3.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "bal_cause3"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
const RUNS: Array = [[true, &"fire", &"shadow"], [true, &"ice", &"nature"], [false, &"fire", &"shadow"],
		[false, &"ice", &"nature"]]
const LEVEL_TIMEOUT := 6000

var _errors: Array[String] = []
var _runs: Array = []
var _run: Array = []
var _level: Node
var _bots: Array = []
var _frames := 0
var _settle := -1
var _gap := 0


func _initialize() -> void:
	_part0()
	_runs = RUNS.duplicate()
	_gap = 2


func _process(_delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			if _runs.is_empty():
				return _finish()
			_next_run()
		return false
	if _level == null:
		return _finish()
	_frames += 1
	if _frames > LEVEL_TIMEOUT:
		_errors.append("%s: bots never set up" % _run_name())
		_end_run()
		return false
	if _settle < 0:
		var all_set := true
		for b: Node in _bots:
			if not is_instance_valid(b) or b.get(&"faction") == &"":
				all_set = false
		if all_set:
			_settle = 40   # PaceSwitch looks for new bot profiles every 15 physics frames
		return false
	_settle -= 1
	if _settle == 0:
		_check_run()
		_end_run()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


# ---------------------------------------------------------------- helpers

## The profile every kingdom resolved before Cause 3 (normal difficulty): the plain kingdom profile.
func _before(k: StringName) -> AIProfile:
	return AIProfile.for_id(AIProfile.id_for_faction(k), 1)


## Blitz's patches on a profile (what PaceSwitch.patch_bots does): "ai", then "ai_kingdom" of the kingdom.
func _blitz_patch(p: AIProfile, k: StringName) -> AIProfile:
	PaceSwitch.patch_ai(p, PaceSwitch.blitz_value("ai"))
	var per: Dictionary = PaceSwitch.blitz_value("ai_kingdom")
	if per.has(String(k)):
		PaceSwitch.patch_ai(p, per[String(k)])
	return p


## Exported knob names that differ between two profiles.
func _diff(a: AIProfile, b: AIProfile) -> Array[String]:
	var out: Array[String] = []
	for prop: Dictionary in a.get_property_list():
		if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var n := StringName(prop["name"])
		var x: Variant = a.get(n)
		var y: Variant = b.get(n)
		var same: bool = is_equal_approx(float(x), float(y)) if (x is float or y is float) else x == y
		if not same:
			out.append("%s %s != %s" % [n, str(x), str(y)])
	return out


# ---------------------------------------------------------------- part 0: static

func _part0() -> void:
	var sh := AIProfile.for_faction(&"shadow", 1)
	var fi := AIProfile.for_faction(&"fire", 1)
	if sh.worker_target_home != 7:
		_errors.append("Shadow normal worker_target_home %d, want 7" % sh.worker_target_home)
	if fi.worker_target_home != 6:
		_errors.append("Fire normal worker_target_home %d, want 6" % fi.worker_target_home)
	var sh_rest := _diff(sh, _before(&"shadow"))
	if sh_rest.size() != 1 or not sh_rest[0].begins_with("worker_target_home"):
		_errors.append("Shadow normal differs beyond workers: %s" % str(sh_rest))
	for k: StringName in [&"fire", &"nature"]:
		var d := _diff(AIProfile.for_faction(k, 1), _before(k))
		if not d.is_empty():
			_errors.append("%s normal profile changed: %s" % [k, str(d)])
	# Ice normal = the old Blitz Ice knobs ("ai_kingdom.ice" on the same base).
	var ice := AIProfile.for_faction(&"ice", 1)
	var old_blitz_ice := _before(&"ice")
	PaceSwitch.patch_ai(old_blitz_ice, PaceSwitch.BLITZ["ai_kingdom"]["ice"])
	for k: String in PaceSwitch.BLITZ["ai_kingdom"]["ice"]:
		if not is_equal_approx(float(ice.get(k)), float(old_blitz_ice.get(k))):
			_errors.append("Ice normal %s = %s, Blitz Ice knob %s" % [k, str(ice.get(k)), str(old_blitz_ice.get(k))])
	if ice.min_attack_pop != 6 or ice.attack_reserve != 1 or not is_equal_approx(ice.attack_ratio, 1.04) \
			or not is_equal_approx(ice.attack_ratio_floor, 0.64):
		_errors.append("Ice normal knobs pop %d reserve %d ratio %.3f floor %.3f (want 6 / 1 / 1.04 / 0.64)" % [
				ice.min_attack_pop, ice.attack_reserve, ice.attack_ratio, ice.attack_ratio_floor])
	if _diff(ice, _before(&"ice")).size() != 3:   # ratio, floor, reserve (min pop was already 6)
		_errors.append("Ice normal changes other knobs: %s" % str(_diff(ice, _before(&"ice"))))
	# Other difficulties untouched.
	for k: StringName in KINGDOMS:
		for d in [0, 2]:
			var df := _diff(AIProfile.for_faction(k, d), AIProfile.for_id(AIProfile.id_for_faction(k), d))
			if not df.is_empty():
				_errors.append("%s difficulty %d changed: %s" % [k, d, str(df)])
	# Paced (Fast / Blitz): the pre-change profile, so Blitz's patches resolve the same knobs as before.
	for k: StringName in KINGDOMS:
		var df := _diff(_blitz_patch(AIProfile.for_faction(k, 1, true), k), _blitz_patch(_before(k), k))
		if not df.is_empty():
			_errors.append("Blitz %s knobs moved: %s" % [k, str(df)])
	var bi := _blitz_patch(AIProfile.for_faction(&"ice", 1, true), &"ice")
	if not is_equal_approx(bi.attack_ratio, 1.3 * 0.9 * 0.8) or not is_equal_approx(bi.attack_ratio_floor, 0.8 * 0.9 * 0.8) \
			or bi.attack_reserve != 1 or bi.min_attack_pop != 6:
		_errors.append("Blitz Ice knobs %.3f / %.3f / %d / %d (want 0.936 / 0.576 / 1 / 6)" % [bi.attack_ratio,
				bi.attack_ratio_floor, bi.attack_reserve, bi.min_attack_pop])
	if _blitz_patch(AIProfile.for_faction(&"shadow", 1, true), &"shadow").worker_target_home != 9:
		_errors.append("Blitz Shadow home workers != 9")
	print("part 0: static profiles checked (%d errors)" % _errors.size())


# ---------------------------------------------------------------- part 1: live levels

func _run_name() -> String:
	return "%s %s:%s" % ["Blitz" if bool(_run[0]) else "Normal", _run[1], _run[2]]


func _next_run() -> void:
	_run = _runs.pop_front()
	_level = load(SCENE).instantiate()
	_level.name = "Cause3Level"   # MenuFlow's restart hook re-applies the saved pace to a root node named "Skirmish"
	_level.set(&"blitz_pace", bool(_run[0]))
	_level.set(&"fast_pace", false)
	_level.set(&"player_kingdom", _run[1])
	_level.set(&"enemy_kingdom", _run[2])
	_bots = [_bot_for(0), _bot_for(1)]
	root.add_child(_level)
	current_scene = _level
	_frames = 0
	_settle = -1


func _bot_for(team: int) -> Node:
	for child in _level.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			child.difficulty = 1
			child.profile = null
			child.profile_id = &""
			return child
	var b: Node = COMMANDER.new()
	b.team = team
	b.difficulty = 1
	_level.add_child(b)
	return b


func _check_run() -> void:
	var blitz := bool(_run[0])
	if PaceSwitch.is_blitz() != blitz or (not blitz and PaceSwitch.is_applied()):
		_errors.append("%s: PaceSwitch state wrong (applied %s, blitz %s)" % [_run_name(), PaceSwitch.is_applied(),
				PaceSwitch.is_blitz()])
	for b: Node in _bots:
		var k: StringName = b.get(&"faction")
		var ai: AIProfile = b.get(&"ai")
		var want := _blitz_patch(_before(k), k) if blitz else AIProfile.for_faction(k, 1)
		var df := _diff(ai, want)
		if not df.is_empty():
			_errors.append("%s %s bot: %s" % [_run_name(), k, str(df)])
		print("%s %s bot: home workers %d, min pop %d, ratio %.3f, floor %.3f, reserve %d" % [_run_name(), k,
				ai.worker_target_home, ai.min_attack_pop, ai.attack_ratio, ai.attack_ratio_floor, ai.attack_reserve])


func _end_run() -> void:
	_level.queue_free()
	_level = null
	_bots = []
	_gap = 3
