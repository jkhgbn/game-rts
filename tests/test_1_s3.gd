extends SceneTree
## Task 1.S3: population (docs/design/economy.md). Mission 1 starts at 250 crystals and 12 / 20;
## a unit death frees its pop; queueing over the cap is refused with "Population cap reached".
## Wave 2 (2.S1): the keep trains only workers, so the queue checks use Cinder Hands
## (2 queued -> 150 and 14 / 20; cancel one -> 200 and 13 / 20), and the cap comes from buildings
## (keep +20): the enemy has no keep on this map yet, so its cap is 0.
## Run:  godot --headless --path . -s tests/test_1_s3.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "1.S3"

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var keep: Keep
var eco: Economy


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
		_run()
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
		return true
	return false


func _run() -> void:
	keep = main.keep
	eco = Economy.for_team(Unit.Team.PLAYER)
	if eco == null or eco != main.economy:
		_errors.append("Economy.for_team(PLAYER) is not main.economy")
		return
	var enemy := Economy.for_team(Unit.Team.ENEMY)
	if enemy == null or enemy.crystals != 250 or enemy.pop_cap != 0:
		_errors.append("enemy economy missing or wrong start")
	elif enemy.pop_used != 16:   # 9 Shades + 2 Grave Hounds + 2 Nightbolts + Shadow Knight 3, Malrik 0
		_errors.append("enemy pop %d, want 16" % enemy.pop_used)
	for pair in [["cinder_hand", 1], ["flame_guard", 1], ["ember_archer", 1], ["blaze_rider", 2],
			["ash_hurler", 1], ["shade", 1], ["shadow_knight", 3]]:
		if UnitType.find(pair[0]).pop != pair[1]:
			_errors.append("%s pop %d" % [pair[0], UnitType.find(pair[0]).pop])

	# Mission start.
	_expect(250, 12, "mission start")
	if eco.pop_cap != 20:
		_errors.append("pop cap %d" % eco.pop_cap)
	for u in get_nodes_in_group("units"):
		if u.has_method("command_gather"):
			u.command_stop()   # no income during the checks

	# The spec's check, with workers (the keep trains only workers from wave 2).
	var hand := UnitType.find("cinder_hand")
	var changes := [0]
	eco.changed.connect(func() -> void: changes[0] += 1)
	keep.queue_unit(hand)
	keep.queue_unit(hand)
	_expect(150, 14, "queue 2 Cinder Hands")
	keep.cancel(1)
	_expect(200, 13, "cancel one")
	if changes[0] == 0:
		_errors.append("Economy.changed never fired")

	# Not enough crystals: refused, spend_failed fires, nothing reserved.
	var failed := [0]
	eco.spend_failed.connect(func() -> void: failed[0] += 1)
	eco.crystals = 40
	if keep.can_queue(hand) != "Not enough crystals" or keep.queue_unit(hand) != "Not enough crystals":
		_errors.append("unit not refused for crystals")
	if failed[0] != 1:
		_errors.append("spend_failed fired %d times, want 1" % failed[0])
	_expect(40, 13, "after a refused queue")
	eco.crystals = 200

	# A unit death frees its pop (when died fires).
	for u in get_nodes_in_group("units"):
		if u.team == Unit.Team.PLAYER and u.unit_name == "Flame Guard":
			u.take_damage(9999.0, null)
			break
	_expect(200, 12, "a Flame Guard died")
	# A wizard's death frees nothing (pop 0): check the count, don't kill Vessa (mission would end).
	if main.hero.unit_type != null:
		_errors.append("Vessa has a unit type (pop should be 0)")

	# Over the cap: 11 living, empty queue; 5 more living Flame Guards -> 16; 4 queued workers -> 20;
	# a 5th (21) is refused for pop (the queue has 4 < 5).
	keep.cancel(0)
	_expect(250, 11, "queue emptied")
	for i in 5:
		var g: Unit = main.make_unit("flame_guard")
		g.team = Unit.Team.PLAYER
		main.add_child(g)
		g.global_position = main.PLAYER_START + Vector3(i * 1.2, 0.0, -6.0)
	_expect(250, 16, "5 Flame Guards added")
	eco.crystals = 5000
	for i in 3:
		var r := keep.queue_unit(hand)
		if r != "":
			_errors.append("worker %d refused: %s" % [i, r])
	_expect(5000 - 3 * 50, 19, "3 workers queued")
	if keep.can_queue(hand) != "":
		_errors.append("a pop-1 unit should still fit (19 + 1 = 20): %s" % keep.can_queue(hand))
	keep.queue_unit(hand)   # exactly 20
	_expect(5000 - 4 * 50, 20, "at the cap")
	var over := keep.queue_unit(hand)   # 21 > 20, queue has 4 < 5
	if over != "Population cap reached" or keep.can_queue(hand) != "Population cap reached":
		_errors.append("over-cap queue gave '%s'" % over)
	_expect(5000 - 4 * 50, 20, "after the refused worker")


func _expect(crystals: int, pop: int, when: String) -> void:
	if eco.crystals != crystals or eco.pop_used != pop:
		_errors.append("%s: %d crystals, %d / %d pop; want %d, %d" % [
				when, eco.crystals, eco.pop_used, eco.pop_cap, crystals, pop])
