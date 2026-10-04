extends SceneTree
## Mission 3 timing check (docs/design/mission-03.md "Acceptance checks" 9 and the lead's ignore run): a scripted
## headless run on normal with real fights (no hero protection, no kills or time skips by the test). The scripted
## player hires the free champion at 0:30 (a second one when it can), trains from its own economy, burns RH1
## (Mossgate), defends the base when a wave comes near, burns RH2 (Hollowfen) once its army is big enough, lets the
## drains take RH3 (or burns it after 14:00), races Malrik to the Signet (chases him if he takes it), then breaks
## both Warden Gates. Must end `victory=true` (spec 20-25 min for a human; the check is 9-26 min).
## `-- --idle`: the ignore run: the player turtles at home; Malrik must win the race (defeat 17:00-21:00).
## `-- --seed=N` changes the random spread; `-- --verbose` prints the state every 30 s. Slow (20+ min of game).
## Run:  godot --headless --path . -s tests/test_m3_sim.gd --fixed-fps 60 --quit-after 120000 [-- --idle] [--verbose]

const TASK_ID := "m3_sim"
const MISSION := "res://missions/mission_03.tscn"
const HOME := Vector3(-36.0, 0.0, 38.0)
const RH1_WAY := Vector3(-40.0, 0.0, 6.0)      ## base -> Mossgate, west of the trees
const RH2_WAY := Vector3(-8.0, 0.0, 44.0)      ## base -> Hollowfen along the south edge
const GATE_ORDER: Array[StringName] = [&"wg1", &"wg2"]
const RH3_WAY := Vector3(22.0, 0.0, 18.0)     ## base -> Stagwatch, south of the Oldroot ring
const RH2_ARMY := 22
const RH3_ARMY := 30
const RH3_TIME := 840.0
const HEARTHS: Array[Vector3] = [Vector3(-48.0, 0.0, 50.0), Vector3(-42.0, 0.0, 52.0), Vector3(-54.0, 0.0, 40.0),
		Vector3(-36.0, 0.0, 53.0), Vector3(-54.0, 0.0, 34.0), Vector3(-30.0, 0.0, 53.0)]

var idle := false
var verbose := false
var h := MissionHarness.new()
var main: Mission03
var phase := &"stage"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hearth_i := 0
var _train_i := 0
var _retreat := false
var _via := false
var _phase_log: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	idle = args.has("--idle")
	verbose = args.has("--verbose")
	for a in args:
		if a.begins_with("--seed="):
			seed(int(a.substr(7)))
	h.task_id = TASK_ID + ("/idle" if idle else "/victory")
	h.protect_hero = false
	h.timeout_frames = 110000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_m3_sim_none.json"}}) as Mission03
	h.steps.add("play", _play, 109000)


func _process(_delta: float) -> bool:
	return h.tick()


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		print("  %s at mission time %d:%02d, phases: %s" % ["victory" if h.ended == 1 else "defeat", int(t) / 60,
				int(t) % 60, ", ".join(_phase_log)])
		print("  hearts %d (credit %s), army %d, Vessa L%d, events %s" % [m.hearts_down, str(m.heart_credit),
				_army().size(), m.hero.level, str(m.waves_fired)])
		print("  objectives: %s" % " ".join(h.objective_log))
		if idle:
			h.check(h.ended == 0, "the idle run did not end in defeat")
			h.check(m.has_fired(&"E15"), "the idle run did not end on Malrik's carry (E15)")
			h.check(t >= 17.0 * 60.0 and t <= 21.0 * 60.0, "idle defeat at %.0f s, expected 17:00-21:00" % t)
		else:
			h.check(h.ended == 1, "defeat at %.0f s (phase %s)" % [t, phase])
			# mission-03.md says 20-25 min for a human; this omniscient scripted player (it knows where the hearts are,
			# never scouts, perfect focus) plays at ~0.45-0.5 of that (mission 2: 12-13 min for 18-24). Measured 2026-10-04
			# after the pacing pass: 9:50 / 10:37 / 10:42 (seeds 2, 3, 1). The lead may tune further (see the M3 report).
			h.check(t >= 9.0 * 60.0 and t <= 26.0 * 60.0, "victory at %.0f s, outside 9-26 min" % t)
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var hp := []
		for id in Mission03.HEART_ORDER:
			hp.append(int((m.hearts[id] as RootHeart).hp))
		print("    t=%5.1f %-8s vessa %3.0f/%3.0f L%d | army %2d | crystals %4d | essence %4d | hearts %s | signet %s | foes %d" % [
				m.mission_time(), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(),
				Economy.for_team(Unit.Team.PLAYER).crystals, EssenceBank.for_team(Unit.Team.PLAYER).essence, str(hp),
				m.signet_state, _enemies_near(m.hero.global_position, 25.0).size()])
	_learn()
	_economy()
	_champions()
	_fireball()
	if idle:
		_turtle()
	else:
		_play_phase()
	return false


func _turtle() -> void:
	var raid := _wave_near_home()
	if raid.is_empty():
		_army_to(HOME, 5.0)
		_hero_to(main.keep.global_position + Vector3(4.0, 0.0, -4.0), 3.0)
	else:
		_army_to(raid[0].global_position, 3.0)
		_hero_behind(raid[0].global_position)


# ---------------------------------------------------------------- helpers

func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable():
			out.append(u)
	return out


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u.team != Unit.Team.PLAYER and not main.is_dormant(u) \
				and not u.is_hidden_from_auto_target() and Mission03._flat(u.global_position, at) <= r:
			out.append(u)
	return out


func _set_phase(p: StringName) -> void:
	phase = p
	_phase_log.append("%s@%d:%02d" % [p, int(main.mission_time()) / 60, int(main.mission_time()) % 60])


func _learn() -> void:
	var w := main.hero as Wizard
	for i in 3:
		if w.spell_points <= 0:
			return
		for id: StringName in [&"fireball", &"ember_step", &"kindle"]:
			if w.learn_spell(id) == "":
				break


func _champions() -> void:
	var g := ChampionGuild.for_team(Unit.Team.PLAYER)
	if g == null or not g.is_open():
		return
	for id: StringName in [&"oathwall", &"mender"]:
		if g.has_archetype(id):
			continue
		if g.can_hire(id) == "" and (g.hires_made == 0 or Economy.for_team(Unit.Team.PLAYER).crystals > 450):
			g.hire(id)
		return


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var hall := main.ember_hall
	if eco == null or hall == null or not is_instance_valid(hall) or not hall.is_alive():
		return
	if eco.pop_cap - eco.pop_used < 4 and eco.pop_cap < 80 and _hearth_i < HEARTHS.size() and eco.crystals >= 100:
		var t := BuildingType.find("fire_hearth")
		var workers: Array = []
		for n in main.get_tree().get_nodes_in_group(&"units"):
			if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
				workers.append(n)
				break
		while _hearth_i < HEARTHS.size():
			var c := main.build_grid.snap(HEARTHS[_hearth_i], t.footprint)
			_hearth_i += 1
			if main.build_grid.check(t, c, Unit.Team.PLAYER) == "":
				main.build_grid.place(t, c, Unit.Team.PLAYER, workers)
				return
	if hall.queue.size() >= 2:
		return
	var want: String = ["flame_guard", "ember_archer", "ash_hurler", "flame_guard", "ember_archer"][_train_i % 5]
	if hall.queue_unit(UnitType.find(want)) == "":
		_train_i += 1


func _fireball() -> void:
	var hero := main.hero
	var best: Unit = null
	var best_n := 0
	var foes := _enemies_near(hero.global_position, 11.0)
	for u in foes:
		var n := 0
		for o in foes:
			if Mission03._flat(o.global_position, u.global_position) <= 3.0:
				n += 1
		if n > best_n:
			best_n = n
			best = u
	if best and (best_n >= 2 or hero.mana > hero.max_mana * 0.6):
		hero.command_cast(&"fireball", best.global_position)


func _army_to(at: Vector3, spread := 4.0) -> void:
	for u in _army():
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if Mission03._flat(u.global_position, at) > spread + 2.0:
			u.command_attack_move(at + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread)))


func _army_center() -> Vector3:
	var a := _army()
	if a.is_empty():
		return main.hero.global_position
	var c := Vector3.ZERO
	for u in a:
		c += u.global_position
	return c / a.size()


func _hero_to(at: Vector3, near := 2.0) -> void:
	var hero := main.hero
	if Mission03._flat(hero.global_position, at) > near:
		hero.command_move(at)


func _hero_behind(goal: Vector3) -> void:
	var c := _army_center()
	var back := (HOME - c)
	back.y = 0.0
	var spot := c + (back.normalized() * 4.0 if back.length() > 0.5 else Vector3.ZERO)
	if not _enemies_near(main.hero.global_position, 12.0).is_empty() or Mission03._flat(c, goal) > 6.0:
		_hero_to(spot, 3.0)


func _wave_near_home() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _enemies_near(HOME, 26.0):
		if u.team == Unit.Team.ENEMY:
			out.append(u)
	return out


## Burn `heart`: fight what is around it, then everyone (and Vessa) hits it.
func _burn(heart: RootHeart) -> void:
	var at := heart.global_position
	var foes := _enemies_near(at, 10.0)
	if Mission03._flat(_army_center(), at) > 10.0 or not foes.is_empty():
		_army_to(at, 4.0)
		_hero_behind(at)
		return
	for u in _army():
		if u.attack_target != heart:
			u.command_attack(heart)
	if main.hero.attack_target != heart:
		main.hero.command_attack(heart)


# ---------------------------------------------------------------- the plan

func _play_phase() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.3 and m.race_phase != &"march":
		_retreat = true
	if _retreat:
		_hero_to(m.keep.global_position + Vector3(4.0, 0.0, -4.0), 3.0)
		_army_to(hero.global_position, 5.0)
		if hero.hp >= hero.max_hp * 0.85:
			_retreat = false
		return
	var raid := _wave_near_home()
	if not raid.is_empty() and not m.barrier_down:
		_army_to(raid[0].global_position, 3.0)
		_hero_behind(raid[0].global_position)
		return
	if m.barrier_down and m.race_phase != &"over" and phase != &"race":
		_set_phase(&"race")
	match phase:
		&"stage":
			_army_to(Mission03.ARMY_POS, 3.0)
			if m.mission_time() >= 40.0:
				_set_phase(&"rh1")
		&"rh1":
			var heart: RootHeart = m.hearts[&"rh1"]
			if not heart.is_alive():
				_set_phase(&"build")
				_via = false
				return
			if not _via:
				if Mission03._flat(_army_center(), RH1_WAY) < 7.0:
					_via = true
				else:
					_army_to(RH1_WAY, 4.0)
					_hero_behind(RH1_WAY)
					return
			_burn(heart)
		&"build":
			_army_to(HOME, 5.0)
			_hero_to(m.keep.global_position + Vector3(4.0, 0.0, -4.0), 3.0)
			if _army().size() >= RH2_ARMY or m.mission_time() >= 600.0:
				_set_phase(&"rh2")
				_via = false
		&"rh2":
			var heart: RootHeart = m.hearts[&"rh2"]
			if not heart.is_alive():
				_set_phase(&"wait")
				return
			if not _via:
				if Mission03._flat(_army_center(), RH2_WAY) < 7.0:
					_via = true
				else:
					_army_to(RH2_WAY, 4.0)
					_hero_behind(RH2_WAY)
					return
			_burn(heart)
		&"wait":
			# RH3 (Maelis): mass RH3_ARMY units at home (or wait for RH3_TIME), then burn it; the drains may take it first.
			_army_to(HOME, 5.0)
			_hero_to(m.keep.global_position + Vector3(4.0, 0.0, -4.0), 3.0)
			if _army().size() >= RH3_ARMY or m.mission_time() >= RH3_TIME:
				_set_phase(&"rh3")
				_via = false
		&"rh3":
			var heart: RootHeart = m.hearts[&"rh3"]
			if not heart.is_alive():
				return
			if not _via:
				if Mission03._flat(_army_center(), RH3_WAY) < 7.0:
					_via = true
				else:
					_army_to(RH3_WAY, 4.0)
					_hero_behind(RH3_WAY)
					return
			_burn(heart)
		&"race":
			if m.race_phase == &"over":
				_set_phase(&"gates")
				return
			var goal := Vector3.ZERO
			match m.signet_state:
				&"tree":
					goal = Vector3(-1.5, 0.0, 1.5)
				&"ground", &"dropping":
					goal = m.signet_ground
				&"malrik":
					goal = m.shadow_hero.global_position
					for u in _army():
						if u.attack_target != m.shadow_hero:
							u.command_attack(m.shadow_hero)
					_hero_to(goal, 4.0)
					return
			_hero_to(goal, 0.5)
			_army_to(goal + Vector3(-3.0, 0.0, 3.0), 3.0)
		&"gates":
			var gate: WardenGate = null
			for id in GATE_ORDER:
				if (m.gates[id] as WardenGate).is_alive():
					gate = m.gates[id]
					break
			if gate == null:
				return
			var at := gate.global_position
			var foes := _enemies_near(at, 9.0)
			if Mission03._flat(_army_center(), at) > 9.0 or foes.size() > 2:
				_army_to(at, 4.0)
				_hero_behind(at)
				return
			for u in _army():
				if u.attack_target == null or not is_instance_valid(u.attack_target):
					u.command_attack(gate)
			_hero_behind(at)
