extends SceneTree
## Mission e2m3 timing check (docs/design/mission-e2-03.md acceptance check 8, the lead's scripted run): a headless run on
## normal with real fights (no hero protection, no kills or time skips by the test; cinematics off = their fallback end
## states, the spec lengths of e2m3_road 0:18, e2m3_lodge 0:15 and e2m3_paid 0:25 are added to the reported play time).
## The scripted player builds the Bazaar, runs 4 caravans to Heron Ford, builds the Stables and trains Emberdart
## Harriers, escorts every tribute with the army, breaks the Tollgate, raises the Citadel and calls Old Vey, and holds the
## guides' countdown at the Bazaar. The first GUARDS soldiers trained after 1:00 stay at the home nodes against the
## raids (the e2m2 sim's rule), and the crystals for the Citadel and Vey's call are held back once they open.
## Must end `victory=true`; prints the phase times and W1's survivors.
## `-- --seed N`, `-- --verbose`. Slow (18+ min of game).
## Run: godot --headless --path . -s tests/test_e2m3_sim.gd --fixed-fps 60 --quit-after 130000

const TASK_ID := "e2m3_sim"
const MISSION := "res://missions/mission_e2_03.tscn"
const HOME := Vector3(-36.0, 0.0, 36.0)
const CUTSCENE_SECONDS := {&"road": 18.0, &"lodge": 15.0, &"paid": 25.0}
const BAZAAR_SPOT := Vector3(-45.0, 0.0, 27.0)
const STABLES_SPOT := Vector3(-55.0, 0.0, 37.0)
const HEARTHS: Array[Vector3] = [Vector3(-56.0, 0.0, 44.0), Vector3(-56.0, 0.0, 50.0), Vector3(-44.0, 0.0, 54.0),
		Vector3(-38.0, 0.0, 54.0)]
const WORKERS := 12
const CARAVANS := 4
const TOLL_ARMY := 12
const GUARDS := 6

var verbose := false
var h := MissionHarness.new()
var main: MissionE2_03
var phase := &"build"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hearth_i := 0
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _start_soldiers: Array = []
var _w1_survivors := -1
var _route_set := false
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID
	h.protect_hero = false
	h.timeout_frames = 125000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m3_sim_none.json"}}) as MissionE2_03
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
		var cine: float = CUTSCENE_SECONDS[&"road"] + (CUTSCENE_SECONDS[&"lodge"] if m.tributes_paid >= 1 else 0.0) \
				+ (CUTSCENE_SECONDS[&"paid"] if m.tributes_paid >= 6 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); tributes %d (lost %d); Magpies %d; raid gold %d; toll falls %d; Vey %s" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), m.tributes_paid, m.tribute_lost,
				m.magpies_killed, m.raid_gold, m.tollgate_falls, "yes" if m.vey_arrived else "no"])
		print("  phases %s; W1 survivors %d / %d; spotlight %s; gold traded %d" % [", ".join(_phase_log), _w1_survivors,
				_start_soldiers.size(), h.spotlight_log, GoldBank.for_team(0).gold])
		print("  objectives %s" % str(h.objective_log))
		print("  Fire losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if _w1_survivors < 0 and m.wave_units.has(&"W1") and MissionBase._all_dead(m.wave_units[&"W1"]):
		_w1_survivors = _start_soldiers.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive()).size()
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		print("    t=%s %s vessa %3.0f L%d | army %2d (w%d) | crystals %4d gold %4d | caravans %d | tribute %d%s | toll %s | guides %s" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.level, _army().size(), _workers().size(),
				Economy.for_team(0).crystals, GoldBank.for_team(0).gold, _caravans().size(), m.tributes_paid,
				" (road)" if m.tribute_caravan != null else "", "up" if m.tollgate != null and is_instance_valid(m.tollgate) and m.tollgate.is_alive() else "-",
				_mmss(m.guides_left)])
		var rs := HelperRoster.for_team(0)
		print("      keep tier %d upgrade '%s' | Vey %s | pop %d/%d | guards %d" % [m.keep.tier if m.keep else 0,
				m.keep.can_upgrade() if m.keep else "-", rs.state() if rs else "-", Economy.for_team(0).pop_used,
				Economy.for_team(0).pop_cap, _home_guard.size()])
	_learn()
	_economy()
	_fireball()
	_guard_home()
	_plan()
	return false


func _all_soldiers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable() and not u.is_in_group(&"caravans"):
			out.append(u)
	return out


var _home_guard: Array = []


func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _all_soldiers():
		if not _home_guard.has(u):
			out.append(u)
	return out


## Between the two home nodes: where the raids hit the workers.
func _guard_post() -> Vector3:
	var a := main.node_of(0, "a")
	var b := main.node_of(0, "b")
	if a and b:
		return (a.global_position + b.global_position) * 0.5
	return HOME


func _guard_home() -> void:
	_home_guard = _home_guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _home_guard.size() < GUARDS and main.mission_time() > 60.0:
		for u in _all_soldiers():
			if _home_guard.size() >= GUARDS:
				break
			if not _home_guard.has(u):
				_home_guard.append(u)
	var post := _guard_post()
	var foes := _enemies_near(post, 18.0)
	for g: Variant in _home_guard:
		var u := g as Unit
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if not foes.is_empty():
			u.command_attack(foes[0])
		elif MissionBase._flat(u.global_position, post) > 6.0:
			u.command_attack_move(post)


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


func _caravans() -> Array:
	var m := Market.of_team(0)
	return m.caravans() if m else []


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) != Unit.Team.PLAYER and not main.is_dormant(u) and not u.is_in_group(&"caravans") \
				and (int(u.team) == Unit.Team.ENEMY or u.is_in_group(&"magpies")) and MissionBase._flat(u.global_position, at) <= r:
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


func _has_kind(kind: StringName, built_only := false) -> bool:
	for b in Building.for_team(0):
		if b.is_alive() and b.building_type and b.building_type.kind == kind and (not built_only or b.is_constructed()):
			return true
	return false


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var node: CrystalNode = null
	for suffix in ["a", "b", "mid"]:
		node = main.node_of(0, suffix)
		if node:
			break
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
	if not _has_kind(&"market") and eco.crystals >= 150 and not workers.is_empty():
		_build("fire_market", BAZAAR_SPOT, workers[0])
		return
	var market := Market.of_team(0)
	if market and market.is_constructed():
		if not _route_set:
			for p in main.trade_posts:
				if p.post_id == &"heron_ford":
					_route_set = market.set_route(p) == ""
		if _caravans().size() + market.queue.size() < CARAVANS and market.queue.size() < 1 and eco.crystals >= 75:
			market.queue_unit(UnitType.find("caravan"))
	if market and not _has_kind(&"stables") and eco.crystals >= 175 and not workers.is_empty() and main.mission_time() > 150.0:
		_build("fire_stables", STABLES_SPOT, workers[0])
		return
	if k.tier == 2 and not k.is_upgrading() and k.can_upgrade() == "" and eco.crystals >= 300:
		k.upgrade()
		return
	var roster := HelperRoster.for_team(Unit.Team.PLAYER)
	if roster and k.tier >= 3 and roster.can_call() == "":
		roster.call_helper()
		return
	if eco.pop_cap - eco.pop_used < 5 and eco.pop_cap < 80 and _hearth_i < HEARTHS.size() and eco.crystals >= 100 \
			and not workers.is_empty():
		_build("fire_hearth", HEARTHS[_hearth_i], workers[0])
		_hearth_i += 1
		return
	if workers.size() < WORKERS and k.queue.size() < 2 and eco.crystals >= 60 and not k.is_upgrading():
		if k.queue_unit(UnitType.find("cinder_hand")) == "" and node:
			k.set_rally_node(node)
	var reserve := 300 if k.tier == 2 and main.mission_time() > 300.0 else 0
	if k.tier >= 3 and roster and roster.state() == &"none":
		reserve = roster.call_type().cost   # Vey's call first
	if eco.crystals - reserve < 120:
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.queue.size() >= 2:
			continue
		var want := ""
		if hall.building_type.id == &"fire_barracks":
			want = ["flame_guard", "ember_archer", "flame_guard", "pyre_adept", "ember_archer"][_train_i % 5]
		elif hall.building_type.kind == &"stables":
			want = "emberdart_harrier"
		else:
			continue
		hall.queue_unit(UnitType.find(want))
		_train_i += 1   # a refused type (pop, tier, card) never blocks the next one
		hall.set_rally_point(HOME + Vector3(-2.0, 0.0, -10.0))


func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.3:
		_retreat = true
	if _retreat:
		_hero_to(HOME, 3.0)
		if hero.hp >= hero.max_hp * 0.8:
			_retreat = false
	if m.tributes_paid < 6 and m.tribute_caravan == null and not m.tribute_pending and GoldBank.for_team(0).gold >= m.tribute_gold():
		m.send_tribute()
	var home_foes := _enemies_near(HOME + Vector3(-4.0, 0.0, -6.0), 24.0)
	if home_foes.size() >= 2:
		_set_phase(&"defend")
		_army_to(home_foes[0].global_position, 3.0)
		if not _retreat:
			_hero_behind(home_foes[0].global_position)
		return
	var toll := m.tollgate
	if toll and is_instance_valid(toll) and toll.is_alive() and _army().size() >= TOLL_ARMY:
		_set_phase(&"toll")
		var foes := _enemies_near(MissionE2_03.TOLLGATE_POS, 12.0)
		if not foes.is_empty():
			_army_to(foes[0].global_position, 3.0)
		else:
			_army_attack(toll)
		if not _retreat:
			_hero_behind(MissionE2_03.TOLLGATE_POS)
		return
	var c := m.tribute_caravan
	if c and is_instance_valid(c) and c.is_alive():
		_set_phase(&"escort")
		var foes := _enemies_near(c.global_position, 14.0)
		if not foes.is_empty():
			_army_to(foes[0].global_position, 3.0)
		else:
			_army_to(c.global_position, 4.0)
		if not _retreat:
			_hero_behind(c.global_position)
		return
	_set_phase(&"hold")
	var hold := Market.of_team(0).global_position + Vector3(4.0, 0.0, -6.0) if Market.of_team(0) else HOME
	var foes := _enemies_near(hold, 20.0)
	_army_to(foes[0].global_position if not foes.is_empty() else hold, 4.0)
	if not _retreat:
		_hero_to(hold + Vector3(-3.0, 0.0, 3.0), 3.0)
