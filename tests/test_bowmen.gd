extends SceneTree
## Bowmen (docs/design/bowmen.md): the 4 .tres; each skirmish Hall lists its bowman as slot 5 (missions / the
## BOWMEN_ENABLED switch aside); on-hit effects through real arrows (Frostbow chill + Hamstring Shot, Scorchbow burn,
## Bleakbow bleed ticks and the 3-stack cap, 5 with Serrated Barbs); Wildwood crits (Keen Eye x2, Heartseeker x2.75);
## upgrades are bought at the right Hall only (price, needs, busy Hall, completion applies to living and new units);
## Hunting Party trains a second archer; the bot picks the Hall bowman when the older slots sit on their mix.
## Run:  godot --headless --path . -s tests/test_bowmen.gd --fixed-fps 60 --quit-after 12000

const TASK_ID := "bowmen"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const TIMEOUT_FRAMES := 9000

var main: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _halls := {}          # faction -> TrainingBuilding (player)
var _spot := Vector3.ZERO  # open ground near the player keep, toward the map centre


func _initialize() -> void:
	main = load(SCENE).instantiate()
	main.camps_enabled = false    # no neutral camp or beast wanders into the test ground
	main.beasts_enabled = false
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
	if frame == 5 and not _started:
		_started = true
		_run()
	if _done:
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	_check_data()
	_setup_halls()
	await _frames(2)
	await _check_frostbow()
	await _check_scorchbow_and_upgrades()
	await _check_bleakbow()
	await _check_wildwood()
	await _check_hunting_party()
	_check_bot_pick()
	_done = true


# ---------------------------------------------------------------- data + Halls

func _check_data() -> void:
	_check(BowmanKit.BOWMEN_ENABLED, "BOWMEN_ENABLED is off")
	_check(BowmanKit.enabled_here(), "bowmen not enabled in scenes/skirmish.tscn")
	# id: [faction, cost, hp, dmg, range, cd]
	var want := {
		"frostbow": ["ice", 140, 90.0, 22.0, 12.0, 2.4],
		"scorchbow": ["fire", 125, 75.0, 14.0, 9.5, 1.6],
		"bleakbow": ["shadow", 115, 70.0, 8.0, 9.0, 1.2],
		"wildwood_archer": ["nature", 85, 60.0, 8.0, 9.0, 1.2],
	}
	for id: String in want:
		var t := UnitType.find(id)
		if t == null:
			_check(false, "missing data/units/%s.tres" % id)
			continue
		var w: Array = want[id]
		_check(String(t.faction) == w[0] and t.cost == w[1] and t.max_hp == w[2] and t.attack_damage == w[3]
				and t.attack_range == w[4] and t.attack_cooldown == w[5] and t.pop == 1 and t.model_scene != null
				and t.card_key == "B" and t.on_hit_status == &"", "%s numbers" % id)


func _setup_halls() -> void:
	var keep: Node3D = main.keep
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var side := dir.cross(Vector3.UP)
	_spot = keep.global_position + dir * 20.0
	main.economy.add(20000)
	main.economy.add_pop_bonus(150)
	var i := 0
	for f: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
		var bt := BuildingType.find("%s_barracks" % f)
		var pos := keep.global_position - dir * 2.0 + side * (-15.0 + 10.0 * i)
		var hall := main.build_grid.spawn_complete(bt, pos, PLAYER) as TrainingBuilding
		_halls[f] = hall
		i += 1
		var types := hall.trainable_types()
		var want: StringName = BowmanKit.HALL_BOWMAN[f]
		_check(types.size() >= 5 and types[4].id == want, "%s Hall slot 5 is %s" % [f, str(types.map(func(t: UnitType) -> StringName: return t.id))])
		_check(bt.trains.size() == 4 or bt.train_ids.size() == 4, "%s Hall data list changed" % f)
	# Missions (Skirmish subclasses) never list bowmen: enabled_here() looks at the exact skirmish script.
	_check(BowmanKit.hall_bowman(BuildingType.find("fire_keep")) == null, "a keep lists a bowman")


func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	return u


## A punching bag: 5000 HP, armor 0, no fighting back.
func _dummy(pos: Vector3) -> Unit:
	var u := Unit.new()
	u.team = ENEMY as Unit.Team
	u.max_hp = 5000.0
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.hide_from_auto_target(9999.0)   # only the bowmen under test shoot it
	u.damage_taken.connect(func(amount: float, attacker: Node3D) -> void:
		if attacker == null or not (attacker is Unit and (attacker as Unit).unit_type
				and BowmanKit.is_bowman((attacker as Unit).unit_type.id)):
			print("  dummy hit %.1f by %s" % [amount, attacker.name if attacker else "null"]))
	return u


func _cleanup(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- on-hit effects

func _check_frostbow() -> void:
	var target := _dummy(_spot)
	var bow := _spawn("frostbow", PLAYER, _spot + Vector3(8.0, 0.0, 0.0))
	bow.command_attack(target)
	var ok := false
	for f in 240:
		await physics_frame
		if target.has_status(&"chill"):
			ok = true
			break
	_check(ok, "Frostbow arrow did not chill")
	_check(target.status_time_left(&"chill") <= 1.5 + 0.01, "standing target chill %.2f (want 1.5, no Hamstring)"
			% target.status_time_left(&"chill"))
	# Hamstring Shot: the next arrow at a MOVING unit chills 3.5 s, then waits 12 s.
	bow.command_stop()
	await _frames(170)   # cooldown 2.4 s + the 1.5 s chill runs out
	var runner := _dummy(_spot + Vector3(0.0, 0.0, 3.0))
	runner.command_move(_spot + Vector3(0.0, 0.0, 30.0))
	bow.command_attack(runner)
	ok = false
	for f in 300:
		await physics_frame
		if runner.status_time_left(&"chill") > 2.0:
			ok = true
			break
	print("  runner v %s chill %.2f meta %s" % [str(runner.velocity), runner.status_time_left(&"chill"),
			str(bow.get_meta(BowmanKit.HAMSTRING_META, -1.0))])
	_check(ok, "Hamstring Shot never chilled a moving unit for 3.5 s")
	_check(float(bow.get_meta(BowmanKit.HAMSTRING_META, 0.0)) > BowmanKit._now() + 5.0, "Hamstring cooldown not started")
	await _cleanup([target, bow, runner])


func _check_scorchbow_and_upgrades() -> void:
	var target := _dummy(_spot)
	var bow := _spawn("scorchbow", PLAYER, _spot + Vector3(8.0, 0.0, 0.0))
	bow.command_attack(target)
	var ok := false
	for f in 240:
		await physics_frame
		if target.dot_time_left(&"burn") > 0.0:
			ok = true
			break
	_check(ok, "Scorchbow arrow did not burn")
	bow.command_stop()
	bow.command_move(_spot + Vector3(30.0, 0.0, 0.0))
	await _frames(10)
	var hp0 := target.hp
	await _frames(125)   # ~2 ticks of 2 damage
	var lost := hp0 - target.hp
	_check(lost >= 3.9 and lost <= 6.1, "burn ticks lost %.1f HP in ~2 s (want ~4)" % lost)
	# Upgrades at the Ember Hall.
	var bank := BowmanUpgrades.for_team(PLAYER)
	var eco: Economy = main.economy
	_check(bank.can_buy(&"scorchbow_heavy_draw", _halls[&"ice"]) == BowmanUpgrades.REASON_HALL, "Heavy Draw at a Frost Hall")
	_check(bank.can_buy(&"scorchbow_pitch_arrows", _halls[&"fire"]) == "Needs Heavy Draw", "Pitch Arrows needs: %s"
			% bank.can_buy(&"scorchbow_pitch_arrows", _halls[&"fire"]))
	var c0 := eco.crystals
	_check(bank.buy(&"scorchbow_heavy_draw", _halls[&"fire"]) == "", "buy Heavy Draw")
	_check(eco.crystals == c0 - 100, "Heavy Draw price %d" % (c0 - eco.crystals))
	_check(bank.can_buy(&"scorchbow_heavy_draw", _halls[&"fire"]) == BowmanUpgrades.REASON_QUEUED, "Heavy Draw twice")
	_check(BowmanUpgrades.options_for(_halls[&"fire"]).size() == 2, "Ember Hall options")
	_check(BowmanUpgrades.options_for(_halls[&"fire"])[0]["state"] == &"working", "Heavy Draw state")
	(UnitResearch.for_team(PLAYER)._work[0] as Dictionary)["left"] = 0.05   # UR.G5: the work lives in UnitResearch
	await _frames(5)
	_check(BowmanUpgrades.team_has(PLAYER, &"scorchbow_heavy_draw"), "Heavy Draw never completed")
	_check(is_equal_approx(bow.attack_damage, 17.0), "living Scorchbow damage %.1f after Heavy Draw" % bow.attack_damage)
	var fresh := _spawn("scorchbow", PLAYER, _spot + Vector3(12.0, 0.0, 4.0))
	_check(is_equal_approx(fresh.attack_damage, 17.0), "new Scorchbow damage %.1f" % fresh.attack_damage)
	var other := _spawn("scorchbow", ENEMY, _spot + Vector3(30.0, 0.0, 30.0))
	_check(is_equal_approx(other.attack_damage, 14.0), "enemy Scorchbow got the upgrade")
	_check(bank.buy(&"scorchbow_pitch_arrows", _halls[&"fire"]) == "", "buy Pitch Arrows")
	# Hall destroyed while researching: 75 % refund.
	var c1 := eco.crystals
	_halls[&"fire"].take_damage(99999.0, null)
	await _frames(3)
	_check(eco.crystals == c1 + 93, "destroyed Hall refund %d (want 93)" % (eco.crystals - c1))
	_check(not bank.is_working(&"scorchbow_pitch_arrows"), "research survived its Hall")
	bank.grant(&"scorchbow_pitch_arrows")
	_check(BowmanKit.burn_numbers(PLAYER) == Vector2(3.5, 4.0), "Pitch Arrows burn numbers")
	await _cleanup([target, bow, fresh, other])


func _check_bleakbow() -> void:
	var target := _dummy(_spot)
	var bows: Array = []
	for k in 3:
		var b := _spawn("bleakbow", PLAYER, _spot + Vector3(7.0, 0.0, -2.0 + 2.0 * k))
		b.command_attack(target)
		bows.append(b)
	var max_stacks := 0
	for f in 420:
		await physics_frame
		max_stacks = maxi(max_stacks, int(target.get_meta(BowmanKit.BLEED_META, 0)))
	_check(max_stacks == 3, "bleed stacks peaked at %d (cap 3)" % max_stacks)
	for b in bows:
		b.command_stop()   # stopped units never auto-pick the hidden dummy
	await _frames(40)   # arrows still in flight land first
	var hp0 := target.hp
	await _frames(60)   # 2 ticks of 3 stacks x 1.5 x 0.5 = 2.25
	var lost := hp0 - target.hp
	_check(lost >= 3.5 and lost <= 5.5, "bleed at 3 stacks lost %.2f HP in 1 s (want 4.5)" % lost)
	BowmanUpgrades.for_team(PLAYER).grant(&"bleakbow_serrated_barbs")
	print("  bleed cap %d, bows alive %d, target hp %.0f" % [BowmanKit.bleed_cap(PLAYER),
			bows.filter(func(b: Unit) -> bool: return is_instance_valid(b) and b.is_alive()).size(), target.hp])
	for b in bows:
		b.queue_free()
	bows.clear()
	for k in 3:
		var b := _spawn("bleakbow", PLAYER, target.global_position + Vector3(7.0, 0.0, -2.0 + 2.0 * k))
		b.command_attack(target)
		bows.append(b)
	max_stacks = 0
	for f in 420:
		await physics_frame
		max_stacks = maxi(max_stacks, int(target.get_meta(BowmanKit.BLEED_META, 0)))
	_check(max_stacks == 5, "Serrated Barbs stacks peaked at %d (want 5)" % max_stacks)
	var drawn := 0
	for b in bows:
		b.command_stop()
		if float(b.get(&"_shot_left")) > 0.0:   # read only, for the log
			drawn += 1
	print("  bows stopped with %d drawn shot(s) pending" % drawn)
	# A bow caught mid-draw keeps its drawn shot through command_stop (Unit D2: the arrow leaves at the model's release
	# frame, <= Unit.MAX_ATTACK_WINDUP s after play_attack). Teleporting it in the same frame made that arrow leave
	# from 40 m away (1.6 s of flight at 25 m/s) and refresh the 5 s bleed late: "bleed never ended (0.55 s left)".
	# Whether a bow is mid-draw at the stop depends on its attack phase, which is not frame-exact from run to run (it
	# passed alone, failed in a loaded CI run; a scratch repro that stops a bow mid-draw and teleports it in the same
	# frame left 0.70 s of bleed after 6 s, 0 with this wait). Let every drawn shot leave from 7 m first, then move.
	await _frames(ceili(Unit.MAX_ATTACK_WINDUP * 60.0) + 3)
	for b in bows:
		# Away from the dummy: its 0-damage melee swings would make a stopped bow answer (fight back).
		b.global_position = target.global_position + Vector3(0.0, 0.0, 40.0)
	await _frames(360)   # 6 s > the 5 s bleed from the last arrow (released <= 0.15 s after the stop, 0.3 s flight)
	_check(target.dot_time_left(&"bleed") <= 0.0, "bleed never ended (%.2f s left, bow0 target %s)"
			% [target.dot_time_left(&"bleed"), str((bows[0] as Unit).attack_target)])
	await _cleanup([target] + bows)


func _check_wildwood() -> void:
	var target := _dummy(_spot)
	var a := _spawn("wildwood_archer", PLAYER, _spot + Vector3(8.0, 0.0, 0.0))
	await _frames(2)
	var crits := 0
	for k in 20:
		if BowmanKit.shot_damage(a, target) > a.attack_damage + 0.01:
			crits += 1
	_check(crits == 0, "crits before Keen Eye")
	var bank := BowmanUpgrades.for_team(PLAYER)
	_check(bank.can_buy(&"wildwood_keen_eye", _halls[&"nature"]) == "", "Keen Eye at the Grove Hall: %s"
			% bank.can_buy(&"wildwood_keen_eye", _halls[&"nature"]))
	_check(bank.can_buy(&"wildwood_keen_eye", _halls[&"shadow"]) == BowmanUpgrades.REASON_HALL, "Keen Eye at a Gloom Hall")
	bank.grant(&"wildwood_keen_eye")
	crits = 0
	var best := 0.0
	for k in 20:
		var d := BowmanKit.shot_damage(a, target)
		best = maxf(best, d)
		if d > a.attack_damage + 0.01:
			crits += 1
	_check(crits >= 2 and crits <= 3, "Keen Eye: %d crits in 20 shots (want 3)" % crits)
	_check(is_equal_approx(best, 16.0), "Keen Eye crit %.1f (want 16)" % best)
	bank.grant(&"wildwood_heartseeker")
	crits = 0
	best = 0.0
	for k in 20:
		var d := BowmanKit.shot_damage(a, target)
		best = maxf(best, d)
		if d > a.attack_damage + 0.01:
			crits += 1
	_check(crits >= 3 and crits <= 5, "Heartseeker: %d crits in 20 shots (want 4)" % crits)
	_check(is_equal_approx(best, 22.0), "Heartseeker crit %.1f (want 22)" % best)
	# A real crit arrow lands for 22.
	a.set_meta(BowmanKit.CRIT_META, 0.85)
	var hp0 := target.hp
	a.command_attack(target)
	for f in 120:
		await physics_frame
		if target.hp < hp0:
			break
	_check(is_equal_approx(hp0 - target.hp, 22.0), "real crit arrow dealt %.1f" % (hp0 - target.hp))
	await _cleanup([target, a])


func _count(id: StringName) -> int:
	var n := 0
	for u in get_nodes_in_group(&"units"):
		if u is Unit and int(u.team) == PLAYER and u.unit_type and u.unit_type.id == id and u.is_alive():
			n += 1
	return n


func _check_hunting_party() -> void:
	var hall: TrainingBuilding = _halls[&"nature"]
	var quick := UnitType.find("wildwood_archer").duplicate() as UnitType
	quick.train_time = 0.2
	var before := _count(&"wildwood_archer")
	_check(hall.queue_unit(quick) == "", "queue a Wildwood Archer")
	await _frames(30)
	_check(_count(&"wildwood_archer") == before + 1, "without Hunting Party: %d new" % (_count(&"wildwood_archer") - before))
	BowmanUpgrades.for_team(PLAYER).grant(&"wildwood_hunting_party")
	before = _count(&"wildwood_archer")
	_check(hall.queue_unit(quick) == "", "queue a Wildwood Archer (2)")
	await _frames(30)
	_check(_count(&"wildwood_archer") == before + 2, "Hunting Party: %d new (want 2)" % (_count(&"wildwood_archer") - before))
	# Other Hall units never get a twin.
	var sb := UnitType.find("bramblehorn")
	if sb:
		var q2 := sb.duplicate() as UnitType
		q2.train_time = 0.2
		var nb := _count(&"bramblehorn")
		hall.queue_unit(q2)
		await _frames(30)
		_check(_count(&"bramblehorn") == nb + 1, "a Bramblehorn got a twin")


# ---------------------------------------------------------------- bots

func _check_bot_pick() -> void:
	var bot: Node = null
	for child in main.get_children():
		if child.get_script() == COMMANDER:
			bot = child
			break
	if bot == null:
		bot = COMMANDER.new()
		bot.team = ENEMY
		main.add_child(bot)
	var hall: TrainingBuilding = _halls[&"shadow"]
	var types := hall.trainable_types()
	var mix: PackedFloat32Array = bot.ai.mix_default
	var old_r: PackedFloat32Array = bot.ai.mix_vs_ranged
	var old_m: PackedFloat32Array = bot.ai.mix_vs_melee
	bot.ai.mix_vs_ranged = mix
	bot.ai.mix_vs_melee = mix
	# Soldiers exactly on the profile mix: the bowman (target 0.08, none alive) is the furthest below target.
	var fake: Array[Unit] = []
	for i in mini(4, mix.size()):
		for k in roundi(mix[i] * 20.0 / float(types[i].pop)):   # shares are of pop (a Shadow Knight is 3)
			fake.append(types[i].create_unit())
	var old_soldiers: Array[Unit] = bot._soldiers
	var old_barracks: Array[TrainingBuilding] = bot._barracks
	bot._soldiers = fake
	var one: Array[TrainingBuilding] = [hall]
	bot._barracks = one
	print("  barracks %s queue %s" % [str(bot._barracks), str(hall.queue.map(func(t: UnitType) -> StringName: return t.id))])
	var pick: UnitType = bot._pick_soldier(hall)
	var slots := []
	for u in fake:
		slots.append(COMMANDER._slot_of(types, u.unit_type))
	print("  share %.3f slots %s heavy %d/%d crystals %d seen %s ai_mix %s" % [BowmanKit.bot_share(types[4].id), str(slots),
			bot.ai.heavy_crystals, bot.ai.heavy_soldier_pop, bot._eco.crystals, str(bot.memory.soldier_mix()),
			str(bot.ai.mix_default)])
	print("  bot team %d mix %s fake %d/%d types %d pick %s" % [int(bot.team), str(mix), fake.size(),
			(bot._soldiers as Array).size(), types.size(), pick.id if pick else &"-"])
	bot._soldiers = old_soldiers
	bot._barracks = old_barracks
	bot.ai.mix_vs_ranged = old_r
	bot.ai.mix_vs_melee = old_m
	for u in fake:
		u.free()
	_check(pick != null and pick.id == &"bleakbow", "bot picked %s (want bleakbow)" % (pick.id if pick else &"null"))
	_check(BowmanKit.bot_share(&"frostbow") > 0.0 and BowmanKit.bot_share(&"flame_guard") == 0.0, "bot shares")
