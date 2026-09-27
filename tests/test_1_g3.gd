extends SceneTree
## Task 1.G3: Malrik (ShadowWizard) and Shadow Lance.
## - Malrik is spawned, not in "heroes" (can't claim the artifact), in "enemy_heroes".
## - Target rules 1-4 pick the right unit.
## - A full hit heals 25, an overkill heals half the HP that was left, cooldown 8 s, mana 35.
## - Killing Malrik shows the message and does not end the mission.
## Run:  godot --headless --path . -s tests/test_1_g3.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "1.G3"
const TIMEOUT_FRAMES := 1800

var main: Node
var frame := 0
var _wait := 0
var malrik: ShadowWizard
var errors: Array[String] = []
var temp: Array = []

var victim: Unit
var casts: Array = []        # [frame, target]
var heals: Array = []        # [frame, amount]
var hp_before_heal := 0.0
var phase := 0
var phase_frame := 0


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
		_find_malrik()
		if malrik == null:
			print("FAIL %s: Malrik not spawned" % TASK_ID)
			return true
		_clear_other_units()
	elif frame == 2:
		_check_rules()
		_start_live_test()
	elif frame > 2:
		_run_live_test()
	if not errors.is_empty():
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
		return true
	if phase == 99:
		print("casts at frames %s, heals %s" % [casts.map(func(c): return c[0]), heals.map(func(h): return snappedf(h[1], 0.1))])
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out in phase %d (casts=%d heals=%s)" % [TASK_ID, phase, casts.size(), heals])
		return true
	return false


func _find_malrik() -> void:
	for node in get_nodes_in_group("units"):
		if node is ShadowWizard:
			malrik = node as ShadowWizard
	if malrik == null:
		return
	if malrik.is_in_group("heroes"):
		errors.append("Malrik is in 'heroes' (could claim the artifact)")
	if not malrik.is_in_group("enemy_heroes"):
		errors.append("Malrik not in 'enemy_heroes'")
	if malrik.team != Unit.Team.ENEMY or malrik.max_hp != 400.0 or malrik.unit_name != "Malrik, Shadow Wizard":
		errors.append("Malrik stats/team")
	var want: Vector3 = main.ARTIFACT_POS + Vector3(4.0, 0.0, -4.0)
	if Vector2(malrik.global_position.x - want.x, malrik.global_position.z - want.z).length() > 0.5:
		errors.append("Malrik not at ARTIFACT_POS + (4, -4)")


func _clear_other_units() -> void:
	for u in get_nodes_in_group("units"):
		if u != main.hero and u != malrik:
			u.remove_from_group("units")
			u.queue_free()
	# Move Malrik to the empty mid camp clearing, far from the artifact and the hero.
	malrik.global_position = main.MID_CAMP
	malrik.command_stop()


func _spawn(type_id: String, pos: Vector3, hp: float = -1.0) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = Unit.Team.PLAYER
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	if hp > 0.0:
		u.hp = hp
	temp.append(u)
	return u


func _free_temp() -> void:
	for u in temp:
		if is_instance_valid(u):
			u.remove_from_group("units")
			u.free()
	temp.clear()


## All in one frame (no physics runs between spawning and checking).
func _check_rules() -> void:
	var c: Vector3 = main.MID_CAMP
	var hero: Unit = main.hero
	var hero_home: Vector3 = hero.global_position

	if malrik.pick_lance_target() != null:
		errors.append("picked a target with nobody in range")
	_spawn("flame_guard", c + Vector3(12.5, 0.0, 0.0))
	if malrik.pick_lance_target() != null:
		errors.append("picked a target at 12.5 m")
	_free_temp()

	# Rule 1: HP <= 50 -> the healthiest of those.
	_spawn("flame_guard", c + Vector3(3.0, 0.0, 0.0), 40.0)
	var b := _spawn("flame_guard", c + Vector3(10.0, 0.0, 0.0), 50.0)
	_spawn("flame_guard", c + Vector3(0.0, 0.0, 5.0), 130.0)
	if malrik.pick_lance_target() != b:
		errors.append("rule 1")
	_free_temp()

	# Rule 2: Malrik under 60 % -> highest HP in range (even over Vessa).
	hero.global_position = c + Vector3(0.0, 0.0, -6.0)
	_spawn("flame_guard", c + Vector3(3.0, 0.0, 0.0), 100.0)
	var big := _spawn("shadow_knight", c + Vector3(8.0, 0.0, 0.0), 400.0)   # team set to player by _spawn
	malrik.hp = 230.0
	if malrik.pick_lance_target() != big:
		errors.append("rule 2")
	# Rule 3: healthy Malrik -> Vessa when she is in range.
	malrik.hp = malrik.max_hp
	if malrik.pick_lance_target() != hero:
		errors.append("rule 3")
	# Rule 4: Vessa out of range -> nearest.
	hero.global_position = hero_home
	var near := _spawn("flame_guard", c + Vector3(2.0, 0.0, 0.0), 100.0)
	if malrik.pick_lance_target() != near:
		errors.append("rule 4")
	_free_temp()


func _start_live_test() -> void:
	# A guard 11 m away: inside lance range, outside both units' aggro ranges.
	victim = _spawn("flame_guard", main.MID_CAMP + Vector3(11.0, 0.0, 0.0))
	victim.command_hold()   # stay put, don't wander
	malrik.hp = 300.0       # above 60 %, so rule 4 (nearest) picks the victim
	malrik.command_hold()
	malrik.shadow_lance_cast.connect(func(t: Unit) -> void: casts.append([frame, t]))
	malrik.lance_healed.connect(func(amount: float) -> void: heals.append([frame, amount]))
	phase = 1


func _run_live_test() -> void:
	match phase:
		1:   # first cast: full hit on a 130 HP guard -> 50 damage, +25 HP
			if heals.size() == 1:
				if casts.size() != 1 or casts[0][1] != victim:
					errors.append("first cast target")
				if not is_equal_approx(heals[0][1], 25.0):
					errors.append("full hit healed %.2f, want 25" % heals[0][1])
				if not is_equal_approx(malrik.hp, 325.0):
					errors.append("Malrik hp %.1f after full hit, want 325" % malrik.hp)
				if not is_equal_approx(victim.hp, 80.0):
					errors.append("victim hp %.1f, want 80" % victim.hp)
				victim.hp = 20.0   # next hit overkills: deals 20, heals 10
				phase = 2
		2:   # second cast must wait for the 8 s cooldown, then heal only 10
			if casts.size() >= 2 and heals.size() >= 2:
				var gap: int = casts[1][0] - casts[0][0]
				if gap < 8 * 60 - 1 or gap > 9 * 60:
					errors.append("cooldown gap %d frames, want about 480" % gap)
				if not is_equal_approx(heals[1][1], 10.0):
					errors.append("overkill healed %.2f, want 10" % heals[1][1])
				if victim.is_alive():
					errors.append("victim survived the overkill")
				# Mana: 100 - 35 = 65, +4/s for ~8 s = ~97, -35 = ~62.
				if malrik.mana > 70.0 or malrik.mana < 55.0:
					errors.append("mana %.1f after two casts" % malrik.mana)
				phase = 3
				phase_frame = frame
		3:   # kill Malrik: message shown, mission goes on
			if frame == phase_frame + 1:
				malrik.take_damage(9999.0)
			elif frame == phase_frame + 30:
				if main.game_over:
					errors.append("killing Malrik ended the mission")
				if not _hud_shows("Malrik has fallen back into the shadows"):
					errors.append("no 'Malrik has fallen' message")
				phase = 99


func _hud_shows(text: String) -> bool:
	for node in main.hud.find_children("*", "Label", true, false):
		if (node as Label).text.contains(text):
			return true
	return false
