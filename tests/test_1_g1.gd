extends SceneTree
## Task 1.G1: UnitType resources match the spec tables, main.gd builds units from them,
## and mission 1 spawns the starting forces of docs/design/units-fire-shadow.md.
## Run:  godot --headless --path . -s tests/test_1_g1.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "1.G1"
const TIMEOUT_FRAMES := 300

## id: [display_name, faction, is_worker, cost, pop, train, hp, dmg, range, cooldown, speed, aggro, radius, height, colour]
const EXPECTED := {
	"cinder_hand": ["Cinder Hand", "fire", true, 50, 1, 12.0, 50.0, 4.0, 1.4, 1.2, 4.6, 0.0, 0.4, 1.4, Color(0.80, 0.60, 0.45)],
	"flame_guard": ["Flame Guard", "fire", false, 90, 1, 18.0, 115.0, 10.0, 1.6, 1.0, 5.0, 8.0, 0.45, 2.0, Color(0.85, 0.30, 0.12)],  # body_height 2.0: model x1.12 (Fire clarity pass 2026-09-30), head top; hp 115 / dmg 10 (balance rounds 2026-10-11)
	"ember_archer": ["Ember Archer", "fire", false, 100, 1, 20.0, 70.0, 9.0, 9.0, 1.2, 5.2, 10.0, 0.45, 1.9, Color(0.95, 0.55, 0.20)],  # body_height 1.9: model x1.12 (2026-09-30)
	"blaze_rider": ["Blaze Rider", "fire", false, 180, 2, 30.0, 205.0, 17.0, 1.7, 0.9, 7.5, 9.0, 0.6, 2.3, Color(0.95, 0.40, 0.05)],  # body_height 2.3 since 13.V10 (rider on the Ember Boar)
	"ash_hurler": ["Ash Hurler", "fire", false, 140, 1, 26.0, 60.0, 24.0, 12.0, 2.2, 4.0, 12.0, 0.45, 1.8, Color(0.60, 0.35, 0.25)],  # body_height 1.8: model x1.12 (2026-09-30)
	"gloom_thrall": ["Gloom Thrall", "shadow", true, 50, 1, 12.0, 50.0, 4.0, 1.4, 1.2, 4.6, 0.0, 0.4, 1.4, Color(0.50, 0.45, 0.55)],
	"shade": ["Shade", "shadow", false, 80, 1, 16.0, 100.0, 11.0, 1.6, 1.0, 4.8, 8.0, 0.45, 1.6, Color(0.42, 0.22, 0.60)],
	"nightbolt": ["Nightbolt", "shadow", false, 100, 1, 20.0, 70.0, 10.0, 9.0, 1.3, 5.0, 10.0, 0.45, 1.6, Color(0.55, 0.30, 0.70)],
	"grave_hound": ["Grave Hound", "shadow", false, 75, 1, 14.0, 70.0, 8.0, 1.4, 0.7, 7.0, 9.0, 0.4, 1.0, Color(0.30, 0.28, 0.35)],
	"shadow_knight": ["Shadow Knight", "shadow", false, 260, 3, 45.0, 400.0, 24.0, 1.9, 1.4, 4.0, 10.0, 0.7, 2.4, Color(0.25, 0.12, 0.38)],
}

## Mission 1 starting forces (display name -> count), wizards excluded.
const PLAYER_FORCES := {"Flame Guard": 5, "Ember Archer": 4, "Cinder Hand": 3}
const ENEMY_FORCES := {"Shade": 9, "Grave Hound": 2, "Nightbolt": 2, "Shadow Knight": 1}

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
	if frame == 5:
		_check_resources()
		_check_make_unit()
		_check_spawns()
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _check_resources() -> void:
	for id in EXPECTED:
		var e: Array = EXPECTED[id]
		var t := UnitType.find(id)
		if t == null:
			_errors.append("missing %s.tres" % id)
			continue
		var got := [t.display_name, String(t.faction), t.is_worker, t.cost, t.pop, t.train_time,
				t.max_hp, t.attack_damage, t.attack_range, t.attack_cooldown, t.move_speed,
				t.aggro_range, t.radius, t.body_height, t.body_color]
		for i in e.size():
			var ok: bool
			if e[i] is float:
				ok = is_equal_approx(float(got[i]), e[i])
			elif e[i] is Color:
				ok = (got[i] as Color).is_equal_approx(e[i])
			else:
				ok = got[i] == e[i]
			if not ok:
				_errors.append("%s field %d: got %s, want %s" % [id, i, got[i], e[i]])
		if String(t.id) != id:
			_errors.append("%s has id %s" % [id, t.id])
	var archer := UnitType.find("ember_archer")
	if archer and not archer.projectile_color.is_equal_approx(Color(1.0, 0.75, 0.3)):
		_errors.append("ember_archer bolt colour")
	var nightbolt := UnitType.find("nightbolt")
	if nightbolt and not nightbolt.projectile_color.is_equal_approx(Color(0.7, 0.4, 1.0)):
		_errors.append("nightbolt bolt colour")
	var hurler := UnitType.find("ash_hurler")
	if hurler and not hurler.projectile_color.is_equal_approx(Color(0.5, 0.5, 0.5)):
		_errors.append("ash_hurler bolt colour")
	# card_key = the letter of the unit's training button (2026-09-29: the old wave-1 Q W E R T keep keys were stale;
	# the keep trains the Cinder Hand on Z, the Ember Hall its four units on Z X C V).
	var keys := ""
	for id in ["cinder_hand", "flame_guard", "ember_archer", "blaze_rider", "ash_hurler"]:
		keys += UnitType.find(id).card_key
	if keys != "ZZXCV":
		_errors.append("card keys %s" % keys)


func _check_make_unit() -> void:
	if main.get_script().get_script_constant_map().has("UNIT_TYPES"):
		_errors.append("UNIT_TYPES still in main.gd")
	var by_name: Unit = main.make_unit("Flame Guard")   # the perf test calls it like this
	var by_id: Unit = main.make_unit("flame_guard")
	if by_name == null or by_id == null:
		_errors.append("make_unit failed")
		return
	if by_name.unit_name != "Flame Guard" or by_name.max_hp != 115.0 or by_name.unit_type == null:
		_errors.append("make_unit('Flame Guard') has wrong stats")
	var worker: Unit = main.make_unit("Cinder Hand")
	if worker == null or not worker.is_worker() or by_id.is_worker():
		_errors.append("is_worker() wrong")
	for u in [by_name, by_id, worker]:
		if u:
			u.free()


func _check_spawns() -> void:
	var counts := [{}, {}]
	var wizards := [0, 0]
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u is Wizard:
			wizards[u.team] += 1
			continue
		counts[u.team][u.unit_name] = counts[u.team].get(u.unit_name, 0) + 1
	if counts[0] != PLAYER_FORCES:
		_errors.append("player forces %s" % counts[0])
	if counts[1] != ENEMY_FORCES:
		_errors.append("enemy forces %s" % counts[1])
	if wizards != [1, 1]:
		_errors.append("wizards per team %s" % [wizards])
	var hero: Unit = main.hero
	if hero.unit_name != "Vessa, Fire Wizard" or hero.max_hp != 350.0 or hero.move_speed != 4.6:
		_errors.append("Vessa stats")
	# Population: 12 at start (1 per basic unit, wizards 0).
	var pop := 0
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u.team == Unit.Team.PLAYER and u.unit_type:
			pop += u.unit_type.pop
	if pop != 12:
		_errors.append("player pop %d, want 12" % pop)
	# Soldier positions unchanged, workers at their new spots.
	var start: Vector3 = main.PLAYER_START
	var expected_worker := start + Vector3(-4.0, 0.0, 4.0)
	var found := false
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u.unit_name == "Cinder Hand" and Vector2(u.global_position.x - expected_worker.x,
				u.global_position.z - expected_worker.z).length() < 0.5:
			found = true
	if not found:
		_errors.append("no Cinder Hand at PLAYER_START + (-4, 4)")
