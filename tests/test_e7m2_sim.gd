extends SceneTree
## Mission e7m2 timing check (docs/design/mission-e7-02.md acceptance check 1: a scripted headless run on normal -
## Mortars on the barricades, the Citadel, Aldra, the rock, the 3 clues, the duel, the ambush - ends `victory=true` in
## 12-24 game minutes; campaign review 2026-10-16: no duel floor, Dacian comes 45 s after the third clue); `-- --passive` (tests/test_e7m2_passive_sim.gd) checks that doing nothing never wins (no clue reads
## itself). Real fights, cinematics off; e7m2_morning 0:12 + herald 0:15 + laurel_call 0:12 + knives 0:06 + mask 0:30
## are added to the play time. `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s
## tests/test_e7m2_sim.gd --fixed-fps 60 --quit-after 100000

const TASK_ID := "e7m2_sim"
const MISSION := "res://missions/mission_e7_02.tscn"
const CINE_SECONDS := 75.0
const PASSIVE_LIMIT := 1500.0
const HOME := Vector3(-28.0, 0.0, 28.0)
const LODGE_SPOT := Vector3(-54.0, 0.0, 52.0)
const SE_STEPS := Vector3(10.0, 0.0, 10.0)
const WORKERS := 10

var verbose := false
var passive := false
var h := MissionHarness.new()
var main: MissionE7_02
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
	h.timeout_frames = 98000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e7m2_sim_none.json"}}) as MissionE7_02
	h.steps.add("play", _play, 97000)
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
	print("  %s at mission time %s (play time with cutscenes %s); clues %s; duel %s; boxes %d; aldra %s; waves %s" % [
			"victory" if h.ended == 1 else ("defeat" if h.ended == 0 else "no end"), MissionE5Base.mmss(t),
			MissionE5Base.mmss(t + CINE_SECONDS), str(m.clues_found), m.duel_state, m.boxes_open,
			m.objective_state("sec_aldra"), ",".join(m.waves_fired)])
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
		h.check(t + CINE_SECONDS >= 720.0 and t + CINE_SECONDS <= 1440.0, "play time %s outside 12-24 min" % MissionE5Base.mmss(t + CINE_SECONDS))
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
		print("    t=%s %s torvald %3.0f L%d | army %2d w%d | crystals %4d gold %4d pop %d/%d T%d | barricades %d rock %d clues %d | duel %s | foes %d" % [
				MissionE5Base.mmss(m.mission_time()), _phase, m.hero.hp, m.hero.level, _soldiers().size(), _workers().size(),
				eco.crystals, m.gold(), eco.pop_used, eco.pop_cap, m.keep.tier if m.keep else 0, m.barricades_left(),
				m.rock_owner(), m.clues_found.size(), m.duel_state, _foes(_center(), 30.0).size()])
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
	if gb and gb.gold >= 150 and eco.crystals < 300:
		gb.exchange(100, &"crystals")
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
	if main.duel_state == "on" and main.dacian:
		if w.command_cast(&"flash_freeze", main.dacian.global_position) == "":
			return
		w.command_cast(&"rime_bolt", main.dacian)
		return
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


func _center_of(units: Array) -> Vector3:
	if units.is_empty():
		return main.hero.global_position
	var c := Vector3.ZERO
	for u: Variant in units:
		c += (u as Unit).global_position
	return c / float(units.size())


func _plan() -> void:
	var m := main
	var all := _soldiers()
	# a third holds the keep (Vessa raids it the moment the barricade falls), two thirds go out
	var army: Array[Unit] = []
	var home: Array[Unit] = []
	for i in all.size():
		var guard_share := 2 if m.mission_time() < 600.0 else 3
		if i % guard_share == guard_share - 1 and m.duel_state == "":
			home.append(all[i])
		else:
			army.append(all[i])
	_go(home, HOME + Vector3(-6.0, 0.0, 6.0), 22.0)
	var hero_spot := _center() + Vector3(-3.0, 0.0, 3.0)
	if m.barricades_left() > 0:
		_phase = "barricade"
		var target: Building = null
		for b: Variant in m.barricades:
			if is_instance_valid(b) and (b as Building).is_alive():
				target = b as Building
				break
		if army.size() < 18 or m.mission_time() < 360.0:
			_go(army, HOME, 18.0)
		elif target:
			var foes := _foes(target.global_position, 12.0)
			for u in army:
				if u.attack_target == null or not is_instance_valid(u.attack_target):
					if not foes.is_empty():
						u.command_attack(foes[0])
					else:
						u.command_attack(target)
	elif m.duel_state == "" and m.clues_found.size() < 3:
		var goal := Vector3.ZERO
		for cid: StringName in [&"knives", &"ledger", &"herald"]:
			if not m.clues_found.has(cid):
				goal = MissionE7_02.CLUES[cid]
				break
		_phase = "clue"
		if army.size() < 10:
			_phase = "regroup"
			_go(army, HOME, 18.0)
			goal = HOME
		var c := _center_of(army)
		var clear := _go(army, goal, 14.0)
		if goal == MissionE7_02.CLUES[&"herald"] and MissionBase._flat(c, goal) > 30.0:
			_go(army, SE_STEPS + Vector3(6.0, 0.0, 6.0), 10.0)
		hero_spot = goal if clear and MissionBase._flat(c, goal) < 16.0 else c
	elif m.duel_state == "" or m.duel_state == "on":
		_phase = "duel"
		_go(army, Vector3(-12.0, 0.0, 12.0), 12.0)
		hero_spot = m.dacian.global_position if m.dacian and is_instance_valid(m.dacian) else Vector3(-3.0, 0.0, 3.0)
	else:
		_phase = "ambush"
		var d := m.dacian
		if d and is_instance_valid(d):
			_go(army, d.global_position, 14.0)
			hero_spot = d.global_position + Vector3(-4.0, 0.0, 4.0)
	if m.duel_state != "on" and m.hero.hp < m.hero.max_hp * 0.4:
		hero_spot = MissionE7Base.RIME_KEEP + Vector3(6.0, 0.0, -6.0)
	if MissionBase._flat(m.hero.global_position, hero_spot) > 2.0:
		m.hero.command_move(hero_spot)
