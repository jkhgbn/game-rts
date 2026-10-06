extends SceneTree
## Mission e2m2 timing check (docs/design/mission-e2-02.md acceptance check 9, the lead's scripted run): a headless run on
## normal with real fights (no hero protection, no kills or time skips by the test; cinematics off = their fallback end
## states, the spec lengths of e2m2_muster 0:18, e2m2_first_grove 0:10, e2m2_heartwood 0:25 and e2m2_two_banners 0:20
## are added to the reported play time). The scripted player trains from its own economy, guards Ysolde's planting at
## Grove A, takes the Millwatch, sends Ysolde to Grove B and guards it, raises the Citadel and calls Old Vey, breaks
## Rimehold, sends Ysolde to Grove C (the Heartseed) and guards it, then holds the Vice beside the Ember Hall while a
## `help` ping sends the ally to Grove B. Must end `victory=true`; prints the phase times and W1's survivors.
## `-- --novey`: never raises the Citadel nor calls Old Vey. `-- --seed N`: the run's random seed. `-- --verbose`.
## Slow (20+ min of game). Run: godot --headless --path . -s tests/test_e2m2_sim.gd --fixed-fps 60 --quit-after 130000

const TASK_ID := "e2m2_sim"
const MISSION := "res://missions/mission_e2_02.tscn"
const HOME := Vector3(-36.0, 0.0, 36.0)
const CUTSCENE_SECONDS := {&"muster": 18.0, &"first_grove": 10.0, &"heartwood": 25.0, &"two_banners": 20.0}
const VICE_HOLD := Vector3(-22.0, 0.0, 40.0)      ## Between the Ember Hall and the south flank (the Ice Vice's target).
const WORKERS := 12
const HEARTHS: Array[Vector3] = [Vector3(-56.0, 0.0, 40.0), Vector3(-56.0, 0.0, 34.0), Vector3(-44.0, 0.0, 54.0),
		Vector3(-38.0, 0.0, 54.0), Vector3(-56.0, 0.0, 46.0)]
const HOME_HALLS: Array[Vector3] = [Vector3(-30.0, 0.0, 38.0), Vector3(-24.0, 0.0, 34.0)]
const RIMEHOLD_ARMY := 20
const RIMEHOLD_LATEST := 600.0
const GUARDS := 6
const GUARD_POST := Vector3(-38.0, 0.0, 40.0)   ## Between the home nodes.
const B_AT := 270.0          ## The spec's rhythm: Grove B against W2 (5:00)...
const C_AT := 690.0          ## ...Grove C against W5 (12:30).

var novey := false
var verbose := false
var h := MissionHarness.new()
var main: MissionE2_02
var phase := &"grove_a"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hearth_i := 0
var _train_i := 0
var _hall2 := false
var _phase_log: Array[String] = []
var _retreat := false
var _start_soldiers: Array = []
var _w1_survivors := -1
var _pinged_vice := false
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	novey = args.has("--novey")
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("/novey" if novey else "/vey")
	h.protect_hero = false
	h.timeout_frames = 125000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m2_sim_none.json"}}) as MissionE2_02
	h.steps.add("play", _play, 124000)
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.unit_died.connect(_on_died)


func _on_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or int(unit.team) != Unit.Team.PLAYER or main == null:
		return
	var k: Variant = unit.killer
	var who := "?"
	if k != null and is_instance_valid(k):
		var kt: Variant = k.get(&"unit_type")
		who = String((kt as UnitType).id) if kt != null else String((k as Node).name)
	var key := "%s:%s" % [phase, who]
	killers[key] = int(killers.get(key, 0)) + 1


func _process(_delta: float) -> bool:
	return h.tick()


static func _mmss(t: float) -> String:
	if t < 0.0:
		return "-"
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _set_phase(p: StringName) -> void:
	if phase != p:
		phase = p
		_phase_log.append("%s@%s" % [p, _mmss(main.mission_time())])


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if _start_soldiers.is_empty():
		_start_soldiers = _army().duplicate()
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"muster"] + (CUTSCENE_SECONDS[&"first_grove"] if m.has_fired(&"E3") else 0.0) \
				+ (CUTSCENE_SECONDS[&"heartwood"] if m.ally_active else 0.0) + (CUTSCENE_SECONDS[&"two_banners"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); E14 %s; Vice %s; Vey %s; carriers lost %d; points peak %d" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), _mmss(m.e14_time),
				"done" if m.vice_done else _mmss(m.vice_left), "yes" if m.vey_arrived else "no", m.carriers_lost, m.points_peak])
		print("  phases %s; W1 survivors %d / %d; waves %s; spotlight %s" % [", ".join(_phase_log), _w1_survivors,
				_start_soldiers.size(), ",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Fire losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if _w1_survivors < 0 and m.waves_fired.has(&"W1") and MissionBase._all_dead(m.wave_units.get(&"W1", [])):
		_w1_survivors = _start_soldiers.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive()).size()
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		print("    t=%s %s vessa %3.0f/%3.0f L%d | army %2d (w%d) | crystals %4d | groves %d (%s %.2f) | rime %d | vice %s | ally %d | waves %s" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _workers().size(),
				Economy.for_team(0).crystals, m.groves_standing(), m.column_target,
				(m.sites[m.column_target] as GroveSite).progress if m.column_target != &"" else 0.0,
				m.rimehold.filter(func(b: Variant) -> bool: return is_instance_valid(b) and (b as Building).is_alive()).size(),
				_mmss(m.vice_left), m._ally_fighters(false).size(), ",".join(m.waves_fired)])
	if verbose and int(m.mission_time()) % 60 == 0 and _tick == 0.5:
		var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type.id == &"fire_barracks")
		var eco := Economy.for_team(0)
		print("      halls %d (q %s) pop %d/%d keep %s tier %d upgrade '%s'" % [halls.size(), str(halls.map(func(b: Building) -> int: return (b as TrainingBuilding).queue.size())),
				eco.pop_used, eco.pop_cap, str(m.keep.is_alive()) if m.keep else "-", m.keep.tier if m.keep else 0,
				m.keep.can_upgrade() if m.keep else ""])
		if m.column_target != &"":
			print("      site %s: %s" % [m.column_target, m.site_debug(m.column_target)])
	_learn()
	_economy()
	_fireball()
	_guard_home()
	_plan()
	return false


# ---------------------------------------------------------------- helpers

var _home_guard: Array = []


## The first GUARDS soldiers trained after 1:00 stay home against the raids (the m04 sim's rule).
func _guard_home() -> void:
	_home_guard = _home_guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _home_guard.size() < GUARDS and main.mission_time() > 60.0:
		for u in _all_soldiers():
			if _home_guard.size() >= GUARDS:
				break
			if not _home_guard.has(u):
				_home_guard.append(u)
	for g: Variant in _home_guard:
		var u := g as Unit
		if u.attack_target == null and MissionBase._flat(u.global_position, GUARD_POST) > 6.0:
			u.command_attack_move(GUARD_POST)


func _all_soldiers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable():
			out.append(u)
	return out


func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _all_soldiers():
		if not _home_guard.has(u):
			out.append(u)
	return out


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and int(u.team) != Unit.Team.NEUTRAL \
				and not main.is_dormant(u) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	return out


func _army_to(at: Vector3, spread := 4.0) -> void:
	for u in _army():
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if MissionBase._flat(u.global_position, at) > spread + 2.0:
			u.command_attack_move(at + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread)))


func _army_attack(target: Node3D) -> void:
	for u in _army():
		if u.attack_target == target:
			continue
		if u.attack_target != null and is_instance_valid(u.attack_target) and u.attack_target is Unit:
			continue
		u.command_attack(target)


func _army_center() -> Vector3:
	var a := _army()
	if a.is_empty():
		return main.hero.global_position
	var c := Vector3.ZERO
	for u in a:
		c += u.global_position
	return c / a.size()


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _hero_behind(goal: Vector3) -> void:
	var c := _army_center()
	var back := HOME - c
	back.y = 0.0
	var spot := c + (back.normalized() * 4.0 if back.length() > 0.5 else Vector3.ZERO)
	if not _enemies_near(main.hero.global_position, 10.0).is_empty() or MissionBase._flat(c, goal) > 6.0:
		_hero_to(spot, 3.0)


func _learn() -> void:
	var w := main.hero as Wizard
	for i in 3:
		if w.spell_points <= 0:
			return
		for id: StringName in [&"fireball", &"kindle", &"ember_step"]:
			if w.learn_spell(id) == "":
				break


func _fireball() -> void:
	var hero := main.hero
	var foes := _enemies_near(hero.global_position, 11.0)
	var best: Unit = null
	var best_n := 0
	for u in foes:
		if u is Wizard and foes.size() > 1:
			continue
		var n := 0
		for o in foes:
			if MissionBase._flat(o.global_position, u.global_position) <= 3.0:
				n += 1
		if n > best_n:
			best_n = n
			best = u
	if best and (best_n >= 2 or hero.mana > hero.max_mana * 0.6):
		hero.command_cast(&"fireball", best.global_position)


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.snap(at, t.footprint)
	if main.build_grid.check(t, c, Unit.Team.PLAYER) != "":
		return false
	return main.build_grid.place(t, c, Unit.Team.PLAYER, [worker]) != null


func _mine_node() -> CrystalNode:
	var rime_done := main.objective_state("obj_rimehold") == "done"
	for suffix in (["a", "b", "mid", "rich"] if rime_done else ["a", "b", "mid"]):
		var n := main.node_of(Unit.Team.PLAYER, suffix)
		if n:
			return n
	return null


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var node := _mine_node()
	for w in workers:
		var t: Variant = w.get(&"gather_node")
		if node and not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			w.call(&"command_gather", node)
	var k := main.keep
	if k == null or not k.is_alive():
		return
	if workers.size() < WORKERS and k.queue.size() < 2 and eco.crystals >= 60 and not k.is_upgrading():   # workers first
		if k.queue_unit(UnitType.find("cinder_hand")) == "" and node:
			k.set_rally_node(node)
	if not novey:
		if k.tier == 2 and not k.is_upgrading() and k.can_upgrade() == "" and eco.crystals >= 300:
			k.upgrade()
			return
		var roster := HelperRoster.for_team(Unit.Team.PLAYER)
		if roster and k.tier >= 3 and roster.can_call() == "":
			roster.call_helper()
			return
	if eco.pop_cap - eco.pop_used < 5 and eco.pop_cap < 80 and _hearth_i < HEARTHS.size() and eco.crystals >= 100 \
			and not workers.is_empty():
		if _build("fire_hearth", HEARTHS[_hearth_i], workers[0]):
			_hearth_i += 1
			return
		_hearth_i += 1
	if not _hall2 and eco.crystals >= 400 and not workers.is_empty() and main.mission_time() > 90.0:
		_hall2 = true   # one try per spot list; a refused spot never blocks the economy
		for spot in HOME_HALLS:
			if _build("fire_barracks", spot, workers[0]):
				return
	if workers.size() < WORKERS and k.queue.size() < 2 and eco.crystals >= 60 and not k.is_upgrading():
		if k.queue_unit(UnitType.find("cinder_hand")) == "" and node:
			k.set_rally_node(node)
	var reserve := 300 if not novey and k.tier == 2 and main.mission_time() > 300.0 else 0
	if eco.crystals - reserve < 120:
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"fire_barracks" \
				or hall.queue.size() >= 2:
			continue
		var want: String = ["flame_guard", "ember_archer", "flame_guard", "pyre_adept", "ember_archer", "blaze_rider"][_train_i % 6]
		hall.queue_unit(UnitType.find(want))
		_train_i += 1   # a refused type (pop, tier, card) never blocks the next one
		hall.set_rally_point(HOME + Vector3(8.0, 0.0, -8.0))


# ---------------------------------------------------------------- the plan

func _site_pos(id: StringName) -> Vector3:
	return (main.sites[id] as GroveSite).global_position


## Holds the army at `at` (fights what comes within 16 m), Vessa behind it.
func _guard(at: Vector3) -> void:
	var foes := _enemies_near(at, 16.0)
	if not foes.is_empty():
		_army_to(foes[0].global_position, 3.0)
		_hero_behind(foes[0].global_position)
	else:
		_army_to(at, 5.0)
		if not _retreat:
			_hero_to(at + Vector3(0.0, 0.0, 4.0), 3.0)


func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.3:
		_retreat = true
	if _retreat:
		_hero_to(HOME, 3.0)
		if hero.hp >= hero.max_hp * 0.8:
			_retreat = false
	# Home defence: anything at the base comes first.
	var at_home := _enemies_near(HOME, 22.0)
	if at_home.size() >= 3 and phase != &"vice":
		_army_to(at_home[0].global_position, 3.0)
		return
	match phase:
		&"grove_a":
			_guard(_site_pos(&"A"))
			if (m.sites[&"A"] as GroveSite).is_planted():
				_set_phase(&"point")
		&"point":
			var mw := Vector3(-34.0, 0.0, 0.0)   # Mossmere Well (the Millwatch is Rimehold's: taken with it)
			_guard(mw)
			if (m.points_held() >= 1 and m.mission_time() > B_AT) or m.mission_time() > B_AT + 60.0:
				m.send_ysolde(&"B")
				_set_phase(&"grove_b")
		&"grove_b":
			if m.column_target != &"B" and not (m.sites[&"B"] as GroveSite).is_planted():
				m.send_ysolde(&"B")
			_guard(_site_pos(&"B"))
			if (m.sites[&"B"] as GroveSite).is_planted():
				_set_phase(&"muster")
		&"muster":
			_guard(Vector3(-24.0, 0.0, 30.0))
			if _army().size() >= RIMEHOLD_ARMY or m.mission_time() >= RIMEHOLD_LATEST:
				_set_phase(&"rimehold")
		&"rimehold":
			if m.objective_state("obj_rimehold") == "done":
				if m.mission_time() < C_AT:
					_guard(Vector3(-24.0, 0.0, 30.0))
					return
				m.send_ysolde(&"C")
				_set_phase(&"grove_c")
				return
			var g1: Array = m.guard_groups[&"G1"]
			var foes := _enemies_near(MissionE2_02.RIMEHOLD_HALL, 18.0)
			if not foes.is_empty():
				_army_to(foes[0].global_position, 3.0)
				_hero_behind(foes[0].global_position)
				return
			for b in m.rimehold:
				if is_instance_valid(b) and b.is_alive():
					_army_attack(b)
					_hero_behind(b.global_position)
					return
			var _g := g1
		&"grove_c":
			if m.column_target != &"C" and not (m.sites[&"C"] as GroveSite).is_planted():
				m.send_ysolde(&"C")
			_guard(_site_pos(&"C"))
			if m.ally_active:
				_set_phase(&"vice")
		&"vice":
			if not _pinged_vice and m.vice_left >= 0.0:
				_pinged_vice = true
				AllyChannel.instance(m.get_tree()).ping(&"help", _site_pos(&"B"), 0)
			var foes := _enemies_near(VICE_HOLD, 24.0)
			if not foes.is_empty():
				_army_to(foes[0].global_position, 3.0)
				if not _retreat:
					_hero_behind(foes[0].global_position)
			else:
				_army_to(VICE_HOLD, 5.0)
				if not _retreat:
					_hero_to(VICE_HOLD + Vector3(-4.0, 0.0, 4.0), 3.0)
