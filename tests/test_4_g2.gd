extends SceneTree
## Task 4.G2: character models plugged in (art-units.md 6.1 / 7 / 10 "4.G2").
## Every UnitType spawns its model; walk / attack / hit / death cycle; death_finished frees the unit
## within 2.0 s; ranged windup (archer bolt 0.15 s after play_attack, none if the archer dies first);
## statuses (haste on the model, burn keeps its sphere); veterancy; worker carry; wizard cast; a dead
## wizard hides and revives with the model reset; HP bar / chevrons draw on top.
## Run: godot --headless --path . -s tests/test_4_g2.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "4.G2"
const TIMEOUT_FRAMES := 900
const TYPES := ["ash_hurler", "blaze_rider", "cinder_hand", "ember_archer", "flame_guard", "gloom_thrall",
		"grave_hound", "nightbolt", "ruin_warden", "shade", "shadow_knight"]

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []

var base := Vector3.ZERO
var all_units: Array = []
var archer: Unit
var archer2: Unit
var dummy: Unit
var guard: Unit
var worker: Unit
var wiz            # a spare ShadowWizard (untyped: test scripts compile before autoloads)
var shots: Array = []   # [frame, source]
var attack_frame := -1
var attack2_frame := -1


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
	match frame:
		5:
			_setup()
		25:
			_check_walking()
		70:
			_check_idle_and_hooks()
		80:
			_fire_archer()
		110:
			_check_windup_and_fire_second()
		140:
			_check_no_shot_after_death()
			_kill_all()
		210:
			_check_wizard_dead()
		300:
			_check_freed_and_revive()
		305:
			_check_revived()
			if _errors.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
			return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)


func _spawn(type_id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	u.aggro_range = 0.0
	return u


func _setup() -> void:
	base = main.PLAYER_START + Vector3(10.0, 0.0, -10.0)
	main.child_entered_tree.connect(func(n: Node) -> void:
		if n is Projectile:   # source is set right after add_child: read it at the end of the frame
			var f := frame
			(func() -> void:
				if is_instance_valid(n):
					shots.append([f, (n as Projectile).source])).call_deferred())
	# Wizards got their models where they are created.
	_expect(main.hero.has_model(), "Vessa has no model")
	for w in root.get_tree().get_nodes_in_group(&"enemy_heroes"):
		_expect(w.has_model(), "Malrik has no model")
	# One of every type, all with their model, walking.
	for i in TYPES.size():
		var u := _spawn(TYPES[i], Unit.Team.PLAYER, base + Vector3((i % 4) * 1.6, 0.0, floori(i / 4.0) * 1.6))
		_expect(u.has_model(), "%s has no model" % TYPES[i])
		_expect(u.get_model() != null and u.get_model().has_method(&"play_attack"), "%s model has no hooks" % TYPES[i])
		all_units.append(u)
		u.command_move(u.global_position + Vector3(-4.0, 0.0, 0.0))
	# Archer and a far enemy dummy for the windup checks (away from the hero's aggro).
	archer = _spawn("ember_archer", Unit.Team.PLAYER, base + Vector3(8.0, 0.0, 2.0))
	archer2 = _spawn("ember_archer", Unit.Team.PLAYER, base + Vector3(8.0, 0.0, 4.0))
	dummy = _spawn("flame_guard", Unit.Team.ENEMY, base + Vector3(8.0, 0.0, 9.0))
	dummy.max_hp = 100000.0
	dummy.heal(100000.0)
	dummy.command_hold()
	_expect(is_equal_approx(archer._model_windup, 0.15), "archer windup %.2f != 0.15" % archer._model_windup)
	guard = all_units[TYPES.find("flame_guard")]
	worker = all_units[TYPES.find("cinder_hand")]


func _check_walking() -> void:
	for u: Unit in all_units:
		var m := u.get_model()
		_expect(float(m.get(&"_speed")) >= 0.3, "%s model not walking (speed %.2f)" % [u.unit_name, float(m.get(&"_speed"))])


func _check_idle_and_hooks() -> void:
	for u: Unit in all_units:   # arrived 4 m away: back to idle
		var m := u.get_model()
		_expect(float(m.get(&"_speed")) < 0.3, "%s model still walking (speed %.2f)" % [u.unit_name, float(m.get(&"_speed"))])
	# Hit flinch, statuses, veterancy, worker carry, cast.
	guard.take_damage(1.0, null)
	_expect(float(guard.get_model().get(&"_hit_t")) < 0.22, "play_hit not called")
	guard.apply_status(&"haste", 5.0)
	_expect(not guard._status_marks.has(&"haste"), "haste kept the placeholder sphere")
	_expect(bool(guard.get_model().get(&"_haste")), "model did not get haste")
	guard.apply_dot(&"burn", 1.0, 1.0, 3.0, null)
	_expect(guard._status_marks.has(&"burn"), "burn lost its placeholder sphere")
	guard.add_xp(800)
	_expect(guard.level == 4, "guard level %d" % guard.level)
	_expect(is_equal_approx(float(guard.get_model().get(&"_vet_boost")), 1.8), "set_veterancy(4) not applied")
	_expect(guard._chevrons != null and guard._chevrons.visible and guard._chevrons.no_depth_test,
			"chevrons not visible on top")
	_expect(String(guard._hp_shader.code).contains("depth_test_disabled"), "HP bar still depth tested")
	worker.carried = 10
	worker._update_carry_visual()
	_expect(bool(worker.get_model().get(&"_carrying")), "worker model not carrying")
	_expect(worker._carry_visual == null, "worker built the placeholder crystal")
	main.hero.spell_cast.emit(&"fireball")
	_expect(main.hero.get_model().get(&"_action") == &"cast", "Vessa did not play the cast")


func _fire_archer() -> void:
	attack_frame = frame
	archer._perform_attack(dummy)
	_expect(archer.get_model().get(&"_action") == &"attack", "archer model not attacking")
	_expect(_shots_from(archer, attack_frame) == -1, "archer shot at once (no windup)")


func _check_windup_and_fire_second() -> void:
	var f := _shots_from(archer, attack_frame)
	# 0.15 s = 9 frames at 60 fps (+-1 for the physics / process order).
	_expect(f >= attack_frame + 8 and f <= attack_frame + 10, "archer bolt at +%d frames, expected ~9" % (f - attack_frame))
	attack2_frame = frame
	archer2._perform_attack(dummy)
	archer2.take_damage(1000000.0, null)   # dies inside its windup


func _check_no_shot_after_death() -> void:
	# archer2 died on the frame after its trigger: its bolt must never leave.
	_expect(_shots_from(archer2, attack2_frame) == -1, "dead archer still shot")


func _kill_all() -> void:
	for u: Unit in all_units:
		if is_instance_valid(u) and u.is_alive():
			u.take_damage(1000000.0, null)
	wiz = load("res://scripts/units/shadow_wizard.gd").new()
	wiz.team = Unit.Team.NEUTRAL
	wiz.ai_auto_cast = false
	main.add_child(wiz)
	wiz.global_position = base + Vector3(-6.0, 0.0, 8.0)
	wiz.command_stop()
	wiz.aggro_range = 0.0


func _check_wizard_dead() -> void:
	_expect(wiz.has_model(), "spare wizard has no model")
	wiz.take_damage(1000000.0, null)


func _check_freed_and_revive() -> void:
	# 160 frames = 2.67 s after the kill; death_finished fires at ~1.0 s.
	for u in all_units:
		_expect(not is_instance_valid(u), "a unit was not freed after its death")
	_expect(not wiz.visible, "dead wizard still visible after death_finished")
	_expect(bool(wiz.get_model().get(&"_dead")), "wizard model not dead")
	wiz.respawn(base + Vector3(-6.0, 0.0, 8.0))


func _check_revived() -> void:
	var m: Node3D = wiz.get_model()
	_expect(wiz.visible and wiz.is_alive(), "wizard not back")
	_expect(not bool(m.get(&"_dead")), "wizard model still dead")
	var r := m.get_node(^"Root") as Node3D
	_expect(r.scale.is_equal_approx(Vector3.ONE) and absf(r.rotation.x) < 0.01 and r.position.y > -0.1,
			"wizard model not reset (%s %s)" % [r.position, r.rotation])


# First frame a projectile from `src` appeared at or after `from_frame`; -1 = none.
func _shots_from(src: Node, from_frame: int) -> int:
	for s: Array in shots:
		if int(s[0]) >= from_frame and s[1] == src:
			return int(s[0])
	return -1
