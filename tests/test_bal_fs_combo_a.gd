extends SceneTree
## FS 2026-10-14 combo A (docs/balance/fs_2026-10-14): AIProfile.SHADOW_FS_COMBO_A lays the variant's 6 Shadow bot
## knobs on the normal-pace normal Shadow profile only; Blitz / Fast (paced), easy / hard and other kingdoms unchanged.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_bal_fs_combo_a.gd --quit-after 600

const TASK_ID := "bal_fs_combo_a"
const KNOBS := ["champion_earliest", "bounty_max_flags", "bounty_budget_pct", "defend_radius", "reaction_delay",
		"attack_reserve"]
const EXPECTED := {"champion_earliest": 120.0, "bounty_max_flags": 3, "bounty_budget_pct": 0.35,
		"defend_radius": 36.0, "reaction_delay": 0.75, "attack_reserve": 3}
const ALL_KNOBS := ["champion_earliest", "bounty_max_flags", "bounty_budget_pct", "defend_radius", "reaction_delay",
		"attack_reserve", "worker_target_home", "min_attack_pop", "attack_ratio", "attack_ratio_floor"]

var _errors: Array[String] = []


func _initialize() -> void:
	var was: bool = AIProfile.SHADOW_FS_COMBO_A
	_run()
	AIProfile.SHADOW_FS_COMBO_A = was
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit()


func _run() -> void:
	# Snapshots with the switch off.
	AIProfile.SHADOW_FS_COMBO_A = false
	var off_normal := _snap(AIProfile.for_faction(&"shadow", 1, false))
	var off_cases := _other_cases()
	var off_hits := 0
	for k: String in KNOBS:
		if _same(off_normal[k], EXPECTED[k]):
			off_hits += 1
	if off_hits == KNOBS.size():
		_errors.append("switch off: Shadow normal already has all 6 combo A values")
	if int(off_normal["worker_target_home"]) != 7:
		_errors.append("switch off: Shadow normal worker_target_home %s (want 7)" % off_normal["worker_target_home"])
	# Switch on.
	AIProfile.SHADOW_FS_COMBO_A = true
	var on_normal := _snap(AIProfile.for_faction(&"shadow", 1, false))
	for k: String in KNOBS:
		if not _same(on_normal[k], EXPECTED[k]):
			_errors.append("switch on: %s = %s (want %s)" % [k, on_normal[k], EXPECTED[k]])
	if int(on_normal["worker_target_home"]) != 7:
		_errors.append("switch on: worker_target_home %s (want 7, merged)" % on_normal["worker_target_home"])
	if typeof(on_normal["bounty_max_flags"]) != TYPE_INT or typeof(on_normal["attack_reserve"]) != TYPE_INT:
		_errors.append("switch on: int knobs lost their type")
	var on_cases := _other_cases()
	for key: String in off_cases:
		if off_cases[key] != on_cases[key]:
			_errors.append("%s changed with the switch: %s -> %s" % [key, off_cases[key], on_cases[key]])
	# Blitz / Fast (paced) Shadow normal = the base profile, either way.
	var base := _snap(AIProfile.for_id(AIProfile.id_for_faction(&"shadow"), 1))
	if base != on_cases["shadow_normal_paced"]:
		_errors.append("paced Shadow normal differs from the base profile")


## Every profile the switch must not touch: paced Shadow, Shadow easy / hard, Fire / Ice / Nature at each difficulty.
func _other_cases() -> Dictionary:
	var out := {}
	out["shadow_normal_paced"] = _snap(AIProfile.for_faction(&"shadow", 1, true))
	for d in [0, 2]:
		for paced in [false, true]:
			out["shadow_%d_%s" % [d, paced]] = _snap(AIProfile.for_faction(&"shadow", d, paced))
	for f: StringName in [&"fire", &"ice", &"nature"]:
		for d in [0, 1, 2]:
			for paced in [false, true]:
				out["%s_%d_%s" % [f, d, paced]] = _snap(AIProfile.for_faction(f, d, paced))
	return out


func _snap(p: AIProfile) -> Dictionary:
	var d := {}
	for k: String in ALL_KNOBS:
		d[k] = p.get(StringName(k))
	return d


func _same(a: Variant, b: Variant) -> bool:
	return is_equal_approx(float(a), float(b))
