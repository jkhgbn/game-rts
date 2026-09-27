extends SceneTree
## Task 12.A2: ChampionBrain map-fill behaviour (docs/design/map-fill.md section 6). Headless on scenes/skirmish.tscn
## (river, capture points, camps, beasts and game critters on) with the bot off and REAL Champions:
##  1. camps in ChampionSense: creature strength (5.1) in `enemies` and danger, remembered camp zones, walks and
##     Wayfinder goals keep out of camp aggro; R4 joins a fight with a Bristleback, not with a Hollow Stag (L1);
##  2. a Wayfinder with a known map (fog off) captures the neutral own-bank Millwatch on its patrol loop (`Capturing`);
##  3. an Oathwall's patrol adds own-held towers within 35 m of an own building (not a far one) and walks into the circle;
##  4. a level-4 Coin-Cutter with enough power (courage x power >= 1.6 x camp strength) goes for and clears its home
##     Bristleback Wallow; a weaker level-4 one does not;
##  5. champions on a Claim (Explore within 7 m of a not-own point) stand in the capture circle until it is captured;
##  6. three free level-4 champions near a visible Tusker hunt it together (`Hunting big game`); the party ends when two
##     flee; a single strong champion and two weak ones never start one;
##  7. R9 idle hunt: an idle Wayfinder attacks a visible deer within 15 m (`Hunting game`), not one at 18 m, at most
##     once per 120 s; an Oathwall never does.
## Run:  godot --headless --path . -s tests/test_12_a2.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "12.A2"
const SCENE := "res://scenes/skirmish.tscn"
const P := 0
const E := 1

var main: Node
var fog: FogOfWar
var _done := false
var _errors: Array[String] = []
var _checks := 0
var _temp: Array = []


func _initialize() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


# ---------------------------------------------------------------- helpers

func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if ok:
		print("ok   " + what)
	else:
		_errors.append(what)
		print("FAIL " + what)


## A real champion of `arch` with class `cls` (&"" = none) at `level` (only with a class), items by id, brain and
## autocast off unless `auto`.
func _champ(arch: StringName, cls: StringName, pos: Vector3, level: int = 1, items: Array = [],
		auto: bool = false) -> Champion:
	var ch := ChampionType.find(arch).create_champion(0)
	ch.team = P as Unit.Team
	if cls != &"":
		ch.set_champion_class(cls)
	main.add_child(ch)
	ch.global_position = pos
	ch.command_stop()
	if cls != &"" and level > 1:
		ch.add_xp(Champion.LEVEL_TOTAL_XP[level - 1] - ch.xp)
	for id: Variant in items:
		var it := ItemType.find(StringName(str(id)))
		if it != null and ch.inventory != null:
			ch.inventory.add_item(it)
	ch.hp = ch.max_hp
	var brain := _brain(ch)
	if brain:
		brain.enabled = auto
	if ch.abilities and &"autocast_enabled" in ch.abilities:
		ch.abilities.set(&"autocast_enabled", auto)
	_temp.append(ch)
	return ch


func _brain(ch: Node) -> ChampionBrain:
	return ch.get_node_or_null(^"Brain") as ChampionBrain


func _unit(type_id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	_temp.append(u)
	return u


func _sync() -> void:
	if fog.enabled:
		fog.update_team(P)
	ChampionSense.for_team(P).refresh()


func _clear() -> void:
	for n: Variant in _temp:
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
	_temp.clear()
	await _frames(2)
	_sync()


func _wait_until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if cond.call():
			return true
		await process_frame
	return bool(cond.call())


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _plan_name(b: ChampionBrain) -> String:
	return str(ChampionBrain.Plan.keys()[b.plan]) if b else "?"


func _service(prop: StringName) -> Node:
	var s: Variant = main.get(prop)
	return s as Node if s is Node and is_instance_valid(s) else null


# ---------------------------------------------------------------- the run

func _run() -> void:
	var waited := 0
	while not main.match_started:
		await process_frame
		waited += 1
		if waited > 6000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			_done = true
			return
	for child in main.get_children():
		if child is Commander:
			(child as Commander).enabled = false
	fog = main.get(&"fog") as FogOfWar
	if fog == null:
		fog = FogOfWar.find()
	if fog == null:
		print("FAIL %s: no fog of war in the skirmish" % TASK_ID)
		_done = true
		return
	ChampionSense.for_team(P)
	await _frames(3)
	var need := {&"capture_points": _service(&"capture_points"), &"camp_manager": _service(&"camp_manager"),
			&"epic_beasts": _service(&"epic_beasts"), &"critter_herds": _service(&"critter_herds")}
	for k: StringName in need:
		_check(need[k] != null, "skirmish has its %s service" % k)
	if _errors.is_empty():
		await _phase_camps()
		await _phase_wayfinder_tower()
		await _phase_oathwall_points()
		await _phase_coin_cutter_camp()
		await _phase_claim()
		await _phase_party()
		await _phase_idle_hunt()

	print("---- %d checks, %d failed" % [_checks, _errors.size()])
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	_done = true


# 1. Camps in the sense: strengths, zones, detours, R4.
func _phase_camps() -> void:
	var cm := _service(&"camp_manager")
	var wallow := cm.call(&"camp", &"camp_wallow_s") as Node3D
	var ok_spawn := await _wait_until(func() -> bool: return (wallow.call(&"creatures") as Array).size() == 2, 600)
	_check(ok_spawn, "the home Bristleback Wallow has its 2 creatures")
	var wp := wallow.global_position
	var at := wp + Vector3(7.0, 0.0, -8.0)
	var wf := _champ(&"wayfinder", &"", at)
	var brain := _brain(wf)
	_sync()
	var sense := ChampionSense.for_team(P)
	var e := sense.camp_entry(wallow)
	_check(not e.is_empty() and bool(e["alive"]) and bool(e["visible"]) and absf(float(e["strength"]) - 200.0) < 1.0,
			"sense lists the seen wallow alive, strength 200 (%s)" % str(e))
	var creature_s: Array = []
	for en: Dictionary in sense.enemies:
		if (en["node"] as Node).is_in_group(&"creatures"):
			creature_s.append(float(en["strength"]))
	_check(creature_s.size() == 2 and absf(float(creature_s[0]) - 100.0) < 0.5,
			"visible Bristlebacks count 100 each in enemies (%s)" % str(creature_s))
	_check(sense.danger_at(wp) >= 200.0, "danger at the camp >= 200 (%.0f)" % sense.danger_at(wp))
	var blocking := sense.camp_blocking(wp + Vector3(-20.0, 0.0, -3.0), wp + Vector3(20.0, 0.0, -3.0))
	_check(not blocking.is_empty() and blocking["node"] == wallow, "a straight walk across the camp is blocked by it")
	_check(sense.camp_blocking(wp + Vector3(-20.0, 0.0, -14.0), wp + Vector3(20.0, 0.0, -14.0)).is_empty(),
			"a walk 14 m from the camp is not")
	var in_zone := 0
	for i in 20:
		var g := brain.explore_goal()
		if g != Vector3.INF and not sense.camp_zone_at(g).is_empty():
			in_zone += 1
	_check(in_zone == 0, "Wayfinder explore goals are never in a camp's aggro zone (%d / 20)" % in_zone)
	# R4: an own soldier hit by a Bristleback -> the L1 Wayfinder joins (danger 200 <= 0.9 x 200 x 1.5 = 270)
	var guard := _unit("flame_guard", P, wp + Vector3(3.0, 0.0, -4.0))
	var boar: Unit = (wallow.call(&"creatures") as Array)[0]
	boar.attack_target = guard
	guard.take_damage(1.0, boar)
	_sync()
	brain.think_now()
	_check(wf.intent == ChampionBrain.I_FIGHTING, "R4: joins the fight with a Bristleback (intent %s)" % wf.intent)
	await _clear()
	# R4: a Hollow Stag (700) is too strong for an L1 Wayfinder
	var stag_camp := cm.call(&"camp", &"camp_stag_w") as Node3D
	if (stag_camp.call(&"creatures") as Array).is_empty():
		stag_camp.call(&"spawn")
	await _frames(2)
	var stags: Array = stag_camp.call(&"creatures")
	_check(stags.size() == 1, "the Stag Glade spawned its stag")
	if stags.size() == 1:
		var sp := (stags[0] as Node3D).global_position
		var wf2 := _champ(&"wayfinder", &"", sp + Vector3(0.0, 0.0, 9.0))
		var g2 := _unit("flame_guard", P, sp + Vector3(0.0, 0.0, 3.0))
		(stags[0] as Unit).attack_target = g2
		g2.take_damage(1.0, stags[0])
		_sync()
		_brain(wf2).think_now()
		_check(wf2.intent != ChampionBrain.I_FIGHTING and absf(sense.danger_at(sp) - 700.0) < 1.0,
				"R4: does not join a fight with the Hollow Stag (danger %.0f, intent %s)" % [sense.danger_at(sp), wf2.intent])
		(stags[0] as Unit).take_damage(1.0e6, null)   # out of the way of the Claim at the nearby well (phase 5)
		await _clear()


# 2. Wayfinder, map known: captures the neutral own-bank tower on its loop.
func _phase_wayfinder_tower() -> void:
	var cps := _service(&"capture_points")
	var mill := cps.call(&"point_by_id", &"tower_s") as Node3D
	_sync()
	var sense := ChampionSense.for_team(P)
	var pe := sense.point_entry(mill)
	_check(not pe.is_empty() and int(pe["bank"]) == P and int(pe["owner"]) == -1,
			"sense: Millwatch is a neutral point of the own bank (%s)" % str(pe))
	fog.enabled = false   # the map is known: nothing unexplored scores, the Wayfinder patrols
	var wf := _champ(&"wayfinder", &"", Vector3(0.0, 0.0, 47.0), 1, [], true)
	var brain := _brain(wf)
	brain.idle_hunt_enabled = false
	var saw_capturing := [false]
	var inside_at_capture := [false]
	var watch := func() -> bool:
		if wf.intent == ChampionBrain.I_CAPTURE and wf.intent_target == mill:
			saw_capturing[0] = true
		if int(mill.get(&"owner_team")) == P:
			inside_at_capture[0] = _flat(wf.global_position, mill.global_position) <= float(mill.get(&"capture_radius"))
			return true
		return false
	var captured := await _wait_until(watch, 2700)
	_check(captured and saw_capturing[0] and inside_at_capture[0],
			"Wayfinder (map known) captured Millwatch standing in its circle (captured %s, Capturing %s, inside %s, plan %s)"
			% [str(captured), str(saw_capturing[0]), str(inside_at_capture[0]), _plan_name(brain)])
	await _frames(240)
	_check(wf.intent != ChampionBrain.I_CAPTURE and brain.plan_goal() != Vector3.INF
			and _flat(brain.plan_goal(), mill.global_position) > 8.0,
			"then it moves on along its loop (intent %s)" % wf.intent)
	fog.enabled = true
	await _clear()


# 3. Oathwall: own-held towers within 35 m of an own building join the patrol.
func _phase_oathwall_points() -> void:
	var cps := _service(&"capture_points")
	var mill := cps.call(&"point_by_id", &"tower_s") as Node3D
	var rook := cps.call(&"point_by_id", &"tower_nw") as Node3D
	if int(mill.get(&"owner_team")) != P:
		mill.call(&"set_owner_team", P)
	rook.call(&"set_owner_team", P)
	var grid: Variant = main.get(&"build_grid")
	var ttype := BuildingType.find("fire_tower")
	var bld: Building = null
	if grid != null and ttype != null:
		bld = grid.spawn_complete(ttype, mill.global_position + Vector3(-11.0, 0.0, 1.0), P)
		_temp.append(bld)
	_check(bld != null, "spawned an own tower 11 m from Millwatch")
	var keep := main.keep_of(P) as Node3D
	var ow := _champ(&"oathwall", &"", keep.global_position + Vector3(6.0, 0.0, -6.0))
	var brain := _brain(ow)
	_sync()
	var stops := brain.patrol_stops()
	_check(stops.has(mill) and not stops.has(rook) and stops.has(keep),
			"Oathwall patrol stops: the keep, Millwatch (near a building), not the far Rookwatch (%d stops)" % stops.size())
	var sense := ChampionSense.for_team(P)
	var visited := false
	var goal_inside := false
	for i in stops.size() + 2:
		sense.now += ChampionBrain.PATROL_EVERY + 1.0
		_sync()
		brain.think_now()
		if brain.plan_node() == mill:
			visited = true
			var g := brain.plan_goal()
			goal_inside = g != Vector3.INF and _flat(g, mill.global_position) < float(mill.get(&"capture_radius"))
			break
	_check(visited and goal_inside and ow.intent == ChampionBrain.I_PATROL,
			"Oathwall patrols to Millwatch, inside its circle (visited %s, inside %s)" % [str(visited), str(goal_inside)])
	rook.call(&"set_owner_team", -1)
	await _clear()


# 4. Coin-Cutter: a level-4 one with enough power clears its home Bristleback Wallow; a weaker one does not go.
func _phase_coin_cutter_camp() -> void:
	var cm := _service(&"camp_manager")
	var wallow := cm.call(&"camp", &"camp_wallow_s") as Node3D
	await _wait_until(func() -> bool: return not bool(wallow.call(&"is_cleared")), 60)
	var wp := wallow.global_position
	fog.reveal(P, wp, 6.0)   # explored
	var sense := ChampionSense.for_team(P)
	sense.workers_seen.clear()   # enemy workers seen while the fog was off: no raid target
	var weak := _champ(&"coin_cutter", &"two_hand", wp + Vector3(10.0, 0.0, -9.0), 4)
	var strong := _champ(&"coin_cutter", &"two_hand", wp + Vector3(12.0, 0.0, -7.0), 4, [&"whetted_fang"])
	_sync()
	var bw := _brain(weak)
	var bs := _brain(strong)
	bw.think_now()
	bs.think_now()
	var s := float(wallow.call(&"strength"))
	_check(0.8 * weak.power() < 1.6 * s and bw.plan != ChampionBrain.Plan.CAMP,
			"L4 Coin-Cutter, power %.0f (0.8 x = %.0f < %.0f): does not go for the camp (plan %s)"
			% [weak.power(), 0.8 * weak.power(), 1.6 * s, _plan_name(bw)])
	_check(0.8 * strong.power() >= 1.6 * s and bs.plan == ChampionBrain.Plan.CAMP and bs.plan_node() == wallow,
			"L4 Coin-Cutter, power %.0f (0.8 x = %.0f >= %.0f): goes for its home T1 camp (plan %s)"
			% [strong.power(), 0.8 * strong.power(), 1.6 * s, _plan_name(bs)])
	weak.queue_free()
	_temp.erase(weak)
	bs.enabled = true
	if strong.abilities and &"autocast_enabled" in strong.abilities:
		strong.abilities.set(&"autocast_enabled", true)
	var engaged := [false]
	var watch := func() -> bool:
		var t: Variant = strong.attack_target
		if t != null and is_instance_valid(t) and (t as Node).is_in_group(&"creatures"):
			engaged[0] = true
		return bool(wallow.call(&"is_cleared")) or not strong.is_alive()
	await _wait_until(watch, 3600)
	_check(engaged[0] and bool(wallow.call(&"is_cleared")) and strong.is_alive(),
			"it clears the Bristleback Wallow alone (engaged %s, cleared %s, alive %s, HP %.0f / %.0f)"
			% [str(engaged[0]), str(wallow.call(&"is_cleared")), str(strong.is_alive()), strong.hp, strong.max_hp])
	_sync()
	bs.think_now()
	_check(bs.plan != ChampionBrain.Plan.CAMP, "then it leaves the cleared camp (plan %s)" % _plan_name(bs))
	await _clear()


# 5. Claim: pursuers stand in the capture circle until the point is captured.
func _phase_claim() -> void:
	var cps := _service(&"capture_points")
	var well := cps.call(&"point_by_id", &"well_w") as Node3D
	if int(well.get(&"owner_team")) != -1:
		well.call(&"set_owner_team", -1)
	var c := well.global_position
	var radius := float(well.get(&"capture_radius"))
	var board := BountyBoard.for_team(P)
	var bank: Variant = EssenceBank.for_team(P)
	if bank != null:
		(bank as Node).call(&"add", 500)
	var wf := _champ(&"wayfinder", &"", c + Vector3(-12.0, 0.0, 6.0), 1, [], true)
	var cc := _champ(&"coin_cutter", &"", c + Vector3(-10.0, 0.0, -7.0), 1, [], true)
	_brain(wf).idle_hunt_enabled = false
	_brain(cc).idle_hunt_enabled = false
	var guild: Variant = ChampionGuild.for_team(P)   # "No champions" reads the guild's roster
	if guild != null:
		(guild as ChampionGuild).champions.append(wf)
		(guild as ChampionGuild).champions.append(cc)
	await _frames(2)
	var flag_pos := c + Vector3(4.0, 0.0, 3.0)
	var err := board.place(Bounty.EXPLORE, null, flag_pos, 150)
	var flag: Bounty = null
	for b: Bounty in board.bounties:
		if b.kind == Bounty.EXPLORE and _flat(b.global_position, flag_pos) < 1.0:
			flag = b
	_check(err == "" and flag != null and flag.is_claim() and flag.claim_point == well,
			"BountyBoard: an Explore 5 m from the neutral well is a Claim (err '%s')" % err)
	if flag == null:
		if guild != null:
			(guild as ChampionGuild).champions.clear()
		await _clear()
		return
	var fref: WeakRef = weakref(flag)   # the flag frees itself when paid: never capture it in the lambda
	var arrived := {}
	var left := [false]
	var took := [false]
	var watch := func() -> bool:
		for ch: Champion in [wf, cc]:
			if ch.intent == ChampionBrain.I_SCOUT and _brain(ch).current_flag != null \
					and _brain(ch).current_flag == fref.get_ref():
				took[0] = true
			var inside := _flat(ch.global_position, c) <= radius
			if inside:
				arrived[ch] = true
			elif arrived.has(ch) and not left[0]:
				left[0] = true
				print("  left: %s at %.1f m, intent %s, plan %s, flag %s, valid %s, owner %d" % [ch.name,
						_flat(ch.global_position, c), ch.intent, _plan_name(_brain(ch)), str(_brain(ch).current_flag),
						str(fref.get_ref() != null), int(well.get(&"owner_team"))])
		return int(well.get(&"owner_team")) == P
	var captured := await _wait_until(watch, 3000)
	_check(took[0] and captured and arrived.size() == 2 and not left[0],
			"both pursuers stood in the circle until the well was captured (took %s, captured %s, in %d / 2, left %s)"
			% [str(took[0]), str(captured), arrived.size(), str(left[0])])
	await _frames(30)
	var fl: Variant = fref.get_ref()
	_check(fl == null or not (fl as Bounty).is_valid(), "the Claim ended on the capture")
	well.call(&"set_owner_team", -1)
	if guild != null:
		(guild as ChampionGuild).champions.erase(wf)
		(guild as ChampionGuild).champions.erase(cc)
	await _clear()


# 6. The beast hunting party.
func _phase_party() -> void:
	var eb := _service(&"epic_beasts")
	var tusker: Node3D = eb.call(&"spawn_now", &"lair_heath_w")
	if tusker == null:
		tusker = eb.call(&"beast_of", &"lair_heath_w")
	_check(tusker != null, "a Tusker spawned at the West Heath")
	if tusker == null:
		return
	for bb in get_nodes_in_group(&"beast_brains"):
		if bb.get(&"beast") == tusker and &"enabled" in bb:
			bb.set(&"enabled", false)
	(tusker as Unit).command_stop()
	await _frames(2)
	var bp := tusker.global_position
	var ow := _champ(&"oathwall", &"sword_shield", bp + Vector3(7.0, 0.0, 0.0), 4)
	var wf := _champ(&"wayfinder", &"spear", bp + Vector3(0.0, 0.0, 8.0), 4)
	var cc := _champ(&"coin_cutter", &"two_hand", bp + Vector3(-6.0, 0.0, 5.0), 4)
	_sync()
	var sense := ChampionSense.for_team(P)
	_check(fog.is_visible(P, bp) and not sense.beast_entry(tusker).is_empty(), "the Tusker is visible to the team")
	for ch: Champion in [ow, wf, cc]:
		_brain(ch).think_now()
	var all_hunt := true
	for ch: Champion in [ow, wf, cc]:
		var b := _brain(ch)
		all_hunt = all_hunt and b.plan == ChampionBrain.Plan.BEAST and ch.intent == ChampionBrain.I_BIG_GAME \
				and ch.attack_target == tusker
	var sum := 0.0
	for ch2: Champion in [ow, wf, cc]:
		sum += _brain(ch2).party_power()
	_check(all_hunt and sense.party_members.size() == 3,
			"three free L4 champions hunt the Tusker together (sum %.0f >= 1.2 x %.0f)" % [sum,
			float(eb.call(&"strength_of", tusker))])
	# two flee: the Oathwall alone gives up
	for ch3: Champion in [wf, cc]:
		ch3.hp = ch3.max_hp * 0.1
		_brain(ch3).think_now()
	_sync()
	_brain(ow).think_now()
	_check(_brain(wf).fleeing and _brain(cc).fleeing and _brain(ow).plan != ChampionBrain.Plan.BEAST,
			"two members flee: the last one ends the hunt (plan %s)" % _plan_name(_brain(ow)))
	await _clear()
	# a single strong champion never starts one
	var solo := _champ(&"oathwall", &"sword_shield", bp + Vector3(7.0, 0.0, 0.0), 6,
			[&"inferno_blade", &"winterwall_aegis", &"ruinwarden_mantle"])
	_sync()
	_brain(solo).think_now()
	_check(_brain(solo).plan != ChampionBrain.Plan.BEAST and solo.intent != ChampionBrain.I_BIG_GAME,
			"a single champion (power %.0f) never hunts the Tusker (plan %s)" % [solo.power(), _plan_name(_brain(solo))])
	await _clear()
	# two weak ones do not either (0.7 x 390 x 2 < 1.2 x 900)
	var m1 := _champ(&"mender", &"wizard", bp + Vector3(7.0, 0.0, 0.0), 4)
	var m2 := _champ(&"mender", &"wizard", bp + Vector3(0.0, 0.0, 8.0), 4)
	_sync()
	_brain(m1).think_now()
	_brain(m2).think_now()
	_check(_brain(m1).plan != ChampionBrain.Plan.BEAST and _brain(m2).plan != ChampionBrain.Plan.BEAST,
			"two L4 Menders (sum %.0f) are too weak for a party" % (_brain(m1).party_power() + _brain(m2).party_power()))
	await _clear()
	(tusker as Unit).take_damage(1.0e6, null)
	await _frames(2)


# 7. R9 idle hunt.
func _phase_idle_hunt() -> void:
	var herds := _service(&"critter_herds")
	var deer: Array = herds.call(&"critters", &"deer")
	_check(deer.size() >= 2, "at least 2 deer on the map (%d)" % deer.size())
	if deer.size() < 2:
		return
	var d1 := deer[0] as Node3D
	var d2: Node3D = null
	for d: Variant in deer:
		if _flat((d as Node3D).global_position, d1.global_position) > 40.0:
			d2 = d
			break
	if d2 == null:
		d2 = deer[deer.size() - 1]
	var sense := ChampionSense.for_team(P)
	# an Oathwall never idle-hunts; a Wayfinder at 18 m does not either
	var ow := _champ(&"oathwall", &"", d1.global_position + Vector3(9.0, 0.0, 0.0))
	var far := _spot_away_from_critters(d1.global_position, 18.0)
	var wf := _champ(&"wayfinder", &"", far)
	_sync()
	_brain(ow).think_now()
	_brain(wf).think_now()
	_check(ow.intent != ChampionBrain.I_GAME and _brain(ow).plan != ChampionBrain.Plan.GAME,
			"an Oathwall never idle-hunts (intent %s)" % ow.intent)
	_check(_brain(wf).plan != ChampionBrain.Plan.GAME,
			"a Wayfinder 18 m from the nearest critter does not hunt (plan %s)" % _plan_name(_brain(wf)))
	ow.queue_free()
	_temp.erase(ow)
	# within 15 m: attacks it
	wf.global_position = d1.global_position + Vector3(9.0, 0.0, 3.0)
	_sync()
	var b := _brain(wf)
	var seen: bool = d1.call(&"is_visible_to", P)
	b.think_now()
	_check(seen and b.plan == ChampionBrain.Plan.GAME and wf.intent == ChampionBrain.I_GAME
			and wf.attack_target == b.plan_node() and b.hunts_started == 1,
			"an idle Wayfinder attacks a visible critter within 15 m (seen %s, plan %s, hunts %d)"
			% [str(seen), _plan_name(b), b.hunts_started])
	# gone beyond 20 m: dropped
	wf.global_position = _spot_away_from_critters(d1.global_position, 25.0)
	_sync()
	b.think_now()
	_check(b.plan != ChampionBrain.Plan.GAME, "the hunt is dropped once the critter is beyond 20 m (plan %s)" % _plan_name(b))
	# another deer within 15 m before 120 s: no new hunt
	wf.global_position = d2.global_position + Vector3(9.0, 0.0, 3.0)
	_sync()
	b.think_now()
	_check(b.plan != ChampionBrain.Plan.GAME and b.hunts_started == 1,
			"no second hunt within 120 s (plan %s, hunts %d)" % [_plan_name(b), b.hunts_started])
	sense.now += ChampionBrain.GAME_GAP + 1.0
	_sync()
	b.think_now()
	_check(b.plan == ChampionBrain.Plan.GAME and wf.intent == ChampionBrain.I_GAME and b.hunts_started == 2,
			"after 120 s it hunts again (plan %s, hunts %d)" % [_plan_name(b), b.hunts_started])
	await _clear()


## A point `dist` m from `from` whose nearest game critter is farther than 15 m (tries 16 directions).
func _spot_away_from_critters(from: Vector3, dist: float) -> Vector3:
	var herds := _service(&"critter_herds")
	var all: Array = herds.call(&"critters")
	var best := from + Vector3(dist, 0.0, 0.0)
	var best_d := -1.0
	for i in 16:
		var a := TAU * float(i) / 16.0
		var p := from + Vector3(cos(a), 0.0, sin(a)) * dist
		if absf(p.x) > 58.0 or absf(p.z) > 58.0:
			continue
		var nearest := INF
		for c: Variant in all:
			nearest = minf(nearest, _flat((c as Node3D).global_position, p))
		if nearest > best_d:
			best_d = nearest
			best = p
	return best
