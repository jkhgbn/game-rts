extends SceneTree
## Task 7.G2: the 5 Ice UnitTypes match kingdom-ice.md section 3; Torvald (IceWizard) matches
## section 4 (stats, armor 10, spells) and grows +30 HP / +2 dmg / +10 mana / +0.25 regen per level
## (L6 590 / 25 / 150 / 5.25, L8 650 / 29 / 170 / 5.75).
## Run:  godot --headless --path . -s tests/test_7_g2.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "7.g2"
const TIMEOUT_FRAMES := 600

## id -> [display, worker, cost, pop, kill_xp, train, hp, armor, dmg, range, cd, speed, aggro, radius, height]
const UNITS := {
	&"rime_hauler": ["Rime Hauler", true, 50, 1, 15, 12.0, 60.0, 0.0, 4.0, 1.4, 1.2, 4.6, 0.0, 0.4, 1.4],
	&"rimeshield": ["Rimeshield", false, 95, 1, 50, 22.0, 150.0, 15.0, 11.0, 1.6, 1.1, 4.2, 8.0, 0.5, 1.7],
	&"shardcaster": ["Shardcaster", false, 110, 1, 55, 22.0, 80.0, 5.0, 9.0, 9.0, 1.4, 4.4, 10.0, 0.45, 1.6],
	&"rime_seer": ["Rime Seer", false, 120, 1, 60, 24.0, 70.0, 5.0, 6.0, 8.0, 1.5, 4.2, 10.0, 0.45, 1.6],
	&"rime_colossus": ["Rime Colossus", false, 290, 3, 145, 52.0, 520.0, 20.0, 28.0, 1.9, 1.8, 3.4, 10.0, 0.8, 2.6],
}
## Extra fields per id (new UnitType fields from 7.G1).
const EXTRAS := {
	&"shardcaster": {"on_hit_status": &"chill", "on_hit_duration": 1.5},
	&"rime_colossus": {"on_hit_status": &"chill", "on_hit_duration": 2.0},
	&"rime_seer": {"support_kind": &"shield", "support_amount": 60.0, "support_duration": 6.0,
			"support_interval": 12.0, "support_range": 8.0},
}

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 1:
		_check_types()
		_check_torvald()
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _eq(label: String, got: Variant, want: Variant) -> void:
	var ok := false
	if got == null:
		ok = false
	elif want is float or got is float:
		ok = is_equal_approx(float(got), float(want))
	else:
		ok = got == want
	if not ok:
		_errors.append("%s = %s (want %s)" % [label, str(got), str(want)])


func _check_types() -> void:
	for id: StringName in UNITS:
		var t := UnitType.find(String(id))
		if t == null:
			_errors.append("missing data/units/%s.tres" % id)
			continue
		var r: Array = UNITS[id]
		_eq("%s.id" % id, t.id, id)
		_eq("%s.faction" % id, t.faction, &"ice")
		_eq("%s.display_name" % id, t.display_name, r[0])
		_eq("%s.is_worker" % id, t.is_worker, r[1])
		_eq("%s.cost" % id, t.cost, r[2])
		_eq("%s.pop" % id, t.pop, r[3])
		_eq("%s.kill_xp" % id, t.kill_xp, r[4])
		_eq("%s.train_time" % id, t.train_time, r[5])
		_eq("%s.max_hp" % id, t.max_hp, r[6])
		_eq("%s.armor" % id, t.get(&"armor"), r[7])
		_eq("%s.attack_damage" % id, t.attack_damage, r[8])
		_eq("%s.attack_range" % id, t.attack_range, r[9])
		_eq("%s.attack_cooldown" % id, t.attack_cooldown, r[10])
		_eq("%s.move_speed" % id, t.move_speed, r[11])
		_eq("%s.aggro_range" % id, t.aggro_range, r[12])
		_eq("%s.radius" % id, t.radius, r[13])
		_eq("%s.body_height" % id, t.body_height, r[14])
		_eq("%s.model_scene set" % id, t.model_scene != null, true)
		var extra: Dictionary = EXTRAS.get(id, {})
		for field: String in extra:
			_eq("%s.%s" % [id, field], t.get(StringName(field)), extra[field])
	# A spawned Rimeshield carries its armor as the base "armor" stat.
	var shield: Unit = main.make_unit("rimeshield")
	if shield:
		shield.team = Unit.Team.ENEMY
		main.add_child(shield)
		shield.global_position = Vector3(0.0, 0.0, -60.0)
		_eq("rimeshield get_stat(armor)", shield.get_stat(&"armor"), 15.0)
		_eq("rimeshield max_hp", shield.max_hp, 150.0)


func _check_torvald() -> void:
	var script := load("res://scripts/units/ice_wizard.gd") as GDScript
	var tor = script.new()
	tor.team = Unit.Team.ENEMY
	main.add_child(tor)
	tor.global_position = Vector3(4.0, 0.0, -60.0)
	_eq("torvald max_hp", tor.max_hp, 440.0)
	_eq("torvald hp", tor.hp, 440.0)
	_eq("torvald armor", tor.get_stat(&"armor"), 10.0)
	_eq("torvald dmg", tor.attack_damage, 15.0)
	_eq("torvald range", tor.attack_range, 6.5)
	_eq("torvald cooldown", tor.attack_cooldown, 1.5)
	_eq("torvald speed", tor.move_speed, 4.2)
	_eq("torvald aggro", tor.aggro_range, 9.0)
	_eq("torvald radius", tor.radius, 0.55)
	_eq("torvald height", tor.body_height, 2.1)
	_eq("torvald max_mana", tor.max_mana, 100.0)
	_eq("torvald mana_regen", tor.mana_regen, 4.0)
	_eq("torvald kingdom", tor.kingdom, &"ice")
	_eq("torvald model", tor.model_scene != null, true)
	_eq("torvald in enemy_heroes", tor.is_in_group(&"enemy_heroes"), true)
	var ids: Array = tor.spell_ids()
	_eq("torvald spells", str(ids), str([&"rime_bolt", &"flash_freeze", &"rime_aegis"]))
	_eq("torvald rime_bolt rank", tor.spell_rank(&"rime_bolt"), 1)
	# Growth: level 6 total XP 1750, then level 8 (3350).
	tor.add_xp(1750)
	_eq("L6 level", tor.level, 6)
	_eq("L6 max_hp", tor.max_hp, 590.0)
	_eq("L6 dmg", tor.attack_damage, 25.0)
	_eq("L6 max_mana", tor.max_mana, 150.0)
	_eq("L6 mana_regen", tor.mana_regen, 5.25)
	_eq("L6 armor", tor.get_stat(&"armor"), 10.0)
	tor.add_xp(3350 - 1750)
	_eq("L8 level", tor.level, 8)
	_eq("L8 max_hp", tor.max_hp, 650.0)
	_eq("L8 dmg", tor.attack_damage, 29.0)
	_eq("L8 max_mana", tor.max_mana, 170.0)
	_eq("L8 mana_regen", tor.mana_regen, 5.75)
