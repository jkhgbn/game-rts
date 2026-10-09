extends SceneTree
## Mission e7m4 timing check (docs/design/mission-e7-04.md acceptance check 1: a scripted headless run on normal - the
## army with Malrik onto the Tollrock, the turn, Kesh and Morrow paid home, the rock held, three stages at the
## lighthouse - ends `victory=true` in 25-30 game minutes, cutscenes included). Still the Sea opens at 22:00 at the
## earliest, so no rush ends the mission early; `-- --passive` (tests/test_e7m4_passive_sim.gd) checks that doing
## nothing never wins (nobody channels the lighthouse). Real fights, cinematics off; e7m4_dawn 0:15 + two_skies 0:28 +
## turn 0:28 + still 0:17 are added to the play time. `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless
## --path . -s tests/test_e7m4_sim.gd --fixed-fps 60 --quit-after 120000

const TASK_ID := "e7m4_sim"
const MISSION := "res://missions/mission_e7_04.tscn"
const CINE_SECONDS := 88.0
const PASSIVE_LIMIT := 1680.0
const HOME := Vector3(-28.0, 0.0, 28.0)
const LODGE_SPOT := Vector3(-54.0, 0.0, 52.0)
const SE_STEPS := Vector3(10.0, 0.0, 10.0)
const WORKERS := 10

var verbose := false
var passive := false
var h := MissionHarness.new()
var main: MissionE7_04
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _sites: Array = []
var _built := {}
var _phase := "build"
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	passive = passive or args.has("--passive")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("_passive" if passive else "")
	h.protect_hero = false
	h.timeout_frames = 118000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e7m4_sim_none.json"}}) as MissionE7_04
	h.steps.add("play", _play, 117000)
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.unit_died.connect(_on_died)


func _on_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or int(unit.team) != Unit.Team.PLAYER or main == null or unit.is_worker():
		return
	var k: Variant = unit.killer
	var who := "?"
	if k != null and is_instance_valid(k):
		var kt: Variant = k.get(&"unit_type")
		who = String((kt as UnitType).id) if kt != null else String((k as Node).name)
	var key := "%s@%d" % [who, int(main.mission_time() / 60.0)]
	killers[key] = int(killers.get(key, 0)) + 1


func _process(_delta: float) -> bool:
	return h.tick()


func _report(t: float) -> void:
	var m := main
	print("  %s at mission time %s (play time with cutscenes %s); turn %s; paid %s; red %d silver %d; meter peak %d; stage %d; waves %s" % [
			"victory" if h.ended == 1 else ("defeat" if h.ended == 0 else "no end"), MissionE5Base.mmss(t),
			MissionE5Base.mmss(t + CINE_SECONDS), MissionE5Base.mmss(m.turn_time), str(m.paid), m.red_sunk, m.silver_sunk,
			int(m.meter_peak), m.stage, ",".join(m.waves_fired)])
	print("  objectives %s" % str(h.objective_log))
	print("  said %s" % str(m.said))
	print("  player losses (killer@minute): %s" % str(killers))


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if passive and h.ended < 0 and m.mission_time() >= PASSIVE_LIMIT:
		_report(m.mission_time())
		return true
	if h.ended >= 0:
		var t := m.mission_time()
		_report(t)
		if passive:
			h.check(h.ended != 1, "a passive run won (%s)" % MissionE5Base.mmss(t))
			return true
		h.check(h.ended == 1, "defeat at %s (%s)" % [MissionE5Base.mmss(t), _phase])
		h.check(t + CINE_SECONDS >= 1500.0 and t + CINE_SECONDS <= 1800.0, "play time %s outside 25-30 min" % MissionE5Base.mmss(t + CINE_SECONDS))
		return true
	if passive:
		return false
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		print("    t=%s %s torvald %3.0f L%d | army %2d w%d | crystals %4d gold %4d | phase %d rock %d lost %.0f | meter %.0f stage %d %.1f | paid %d | foes %d" % [
				MissionE5Base.mmss(m.mission_time()), _phase, m.hero.hp, m.hero.level, _soldiers().size(), _workers().size(),
				eco.crystals, m.gold(), m.phase, m.rock_owner(), m.rock_lost_for, m.meter, m.stage, m.stage_progress, m.paid.size(),
				_foes(MissionE7Base.ROCK, 30.0).size()])
	_economy()
	_spells()
	_plan()
	return false


func _soldiers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable() and not u.is_in_group(&"caravans"):
			out.append(u)
	return out


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


func _foes(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and not main.is_dormant(u) \
				and StringName(u.get_meta(Unit.TRUCE_META, &"")) != Unit.TRUCE_ALL \
				and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _center() -> Vector3:
	var army := _soldiers()
	if army.is_empty():
		return main.hero.global_position
	var c := Vector3.ZERO
	for u in army:
		c += u.global_position
	return c / float(army.size())


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.find_spot(t, at, 0)
	if c == Vector3.INF:
		return false
	var site := main.build_grid.place(t, c, Unit.Team.PLAYER, [worker])
	if site:
		_sites.append([site, worker])
	return site != null


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var m := main
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	_sites = _sites.filter(func(r: Array) -> bool: return is_instance_valid(r[0]) and (r[0] as Building).is_alive() \
			and not (r[0] as Building).is_constructed())
	var busy: Array = []
	for r: Array in _sites:
		var wu := r[1] as Unit
		if wu == null or not is_instance_valid(wu) or not wu.is_alive():
			continue
		busy.append(wu)
		if not bool(wu.call(&"is_building")) and not wu.has_move_order():
			wu.call(&"command_build", r[0])
	for w in workers:
		if busy.has(w):
			continue
		var t: Variant = w.get(&"gather_node")
		if not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			for s in ["a", "b", "mid"]:
				var node: CrystalNode = m.node_of(0, s)
				if node:
					w.call(&"command_gather", node)
					break
	var k := m.keep
	if k == null or not k.is_alive():
		return
	var gb := GoldBank.for_team(0)
	if k.tier < 3 and k.can_upgrade() == "" and not k.is_upgrading() and eco.crystals >= 300:
		k.upgrade()
		return
	var roster := HelperRoster.for_team(0)
	if k.tier >= 3 and roster and roster.can_call() == "" and eco.crystals >= 250:
		roster.call_helper()
		return
	if k.tier >= 3 and m.has_fired(&"E4") and not k.is_upgrading() and eco.crystals < 300 and m.mission_time() < 600.0:
		pass
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		if k.queue_unit(UnitType.find("rime_hauler")) == "":
			var node: CrystalNode = m.node_of(0, "a")
			if node:
				k.set_rally_node(node)
	elif k.tier >= 3 and k.queue.size() < 1 and eco.crystals >= 225:
		var guards := _soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"shardguard").size()
		if guards < 2:
			k.queue_unit(UnitType.find("shardguard"))
			k.set_rally_point(HOME)
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w):
			free_w = w
			break
	if free_w and not _built.has("hall2") and eco.crystals >= 160:
		if _build("ice_barracks", Vector3(-20.0, 0.0, 44.0), free_w):
			_built["hall2"] = true
		return
	if free_w and eco.pop_cap - eco.pop_used < 6 and _built.size() < 3 and not _built.has("l%d" % int(eco.pop_cap)) \
			and eco.crystals >= 100:
		if _build("ice_lodge", LODGE_SPOT + Vector3(0.0, 0.0, -6.0 * _built.size()), free_w):
			_built["l%d" % int(eco.pop_cap)] = true
		return
	if k.is_upgrading() == false and k.tier < 3 and m.mission_time() > 330.0 and eco.crystals < 360:
		return   # save for the Citadel
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"ice_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 120:
			continue
		var mix: Array = ["frost_mortar", "rimeshield", "shardcaster", "rimeshield", "shardcaster", "rime_seer"]
		var want: String = mix[_train_i % mix.size()]
		if hall.queue_unit(UnitType.find(want)) != "":
			hall.queue_unit(UnitType.find("rimeshield"))
		_train_i += 1
		hall.set_rally_point(HOME)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"rime_bolt", &"flash_freeze", &"rime_aegis"]:
			if w.learn_spell(id) == "":
				break
	var foes := _foes(w.global_position, 12.0)
	if foes.is_empty():
		return
	if foes.size() >= 4 and w.command_cast(&"flash_freeze", foes[0].global_position) == "":
		return
	if w.hp < w.max_hp * 0.6 and w.command_cast(&"rime_aegis", w) == "":
		return
	w.command_cast(&"rime_bolt", foes[0])


## Sends `army` at `at`: fight what is within `r`, else gather there.
func _go(army: Array, at: Vector3, r: float) -> bool:
	var foes := _foes(at, r)
	for v: Variant in army:
		var u := v as Unit
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if not foes.is_empty():
			u.command_attack(foes[0])
		elif MissionBase._flat(u.global_position, at) > 6.0:
			u.command_attack_move(at)
	return foes.is_empty()


func _plan() -> void:
	var m := main
	var all := _soldiers()
	var army: Array[Unit] = []
	var home: Array[Unit] = []
	for i in all.size():
		if i % 3 == 2:
			home.append(all[i])
		else:
			army.append(all[i])
	_go(home, HOME + Vector3(-6.0, 0.0, 6.0), 24.0)
	var hero_spot := MissionE7Base.NORTH_FOOT + Vector3(-6.0, 0.0, 6.0)
	var t := m.mission_time()
	if m.turn_time >= 0.0:
		for id: String in ["gilt_dragon", "prism_dragon", "sunwake"]:
			if not m.paid.has(id) and m.dragon(id) != null and m.gold() >= m.pay_price(id) + 50:
				m.pay_home(id)
				break
	if m.phase == 1:
		_phase = "p1"
		if t >= 420.0:
			_go(army, MissionE7Base.ROCK, 16.0)
		else:
			_go(army, MissionE7Base.NORTH_FOOT, 16.0)
	elif m.phase == 2 or m.turn_time < 0.0:
		_phase = "truce"
		_go(army, MissionE7Base.NORTH_FOOT, 8.0)
	else:
		_phase = "hold" if m.phase == 4 else "still"
		_go(army, MissionE7Base.ROCK + Vector3(-3.0, 0.0, 3.0), 18.0)
		hero_spot = MissionE7Base.ROCK + Vector3(-5.0, 0.0, 5.0)
		if m.phase == 5 and t >= m.stage_ready_at:
			hero_spot = MissionE7Base.ROCK
	if m.phase != 5 and m.hero.hp < m.hero.max_hp * 0.35:
		hero_spot = MissionE7Base.RIME_KEEP + Vector3(6.0, 0.0, -6.0)
	if MissionBase._flat(m.hero.global_position, hero_spot) > 1.5:
		m.hero.command_move(hero_spot)
