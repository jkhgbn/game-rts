extends SceneTree
## Mission e4m1 timing check (docs/design/mission-e4-01.md "Lead" check: a scripted headless run on normal rings the 5
## bells, holds the ford to 12:00, holds the foot, defends the tree, `victory=true` in 22-28 game-minutes; the W3 fight
## leaves Ysolde alive). Real fights: no hero protection, no kills or time skips by the test; cinematics off (their
## fallback end states), the spec lengths of e4m1_horn 0:12, e4m1_foot 0:10 and e4m1_nightfall 0:30 are added to the
## reported play time.
## The scripted player (human-like): Spriglings to 11, Seed Hollows, a second Grove Hall, the Stronghold at 3:30,
## Thornlings / Burr Slingers / Vinelashers / Oathkeepers and 2 Bramblesages (autocast); Ysolde walks the foot of the
## hill ringing Larkford and Millbrook, takes the west detachment over Reed Ford to clear Reedfield's picket, rings
## Birchend, then crosses Birch Ford with the army for Birchwater; the army holds the ford's south bank (spread, ranged
## behind, the enemy wizards focused) until the evening horn, then the foot between the standards, then the tree.
## `-- --seed N`, `-- --verbose`, `-- --difficulty N`. Slow. Run: godot --headless --path . -s tests/test_e4m1_sim.gd
## --fixed-fps 60 --quit-after 140000

const TASK_ID := "e4m1_sim"
const MISSION := "res://missions/mission_e4_01.tscn"
const CUTSCENE_SECONDS := {&"horn": 12.0, &"foot": 10.0, &"nightfall": 30.0}
const RALLY := Vector3(-14.0, 0.0, 28.0)
const FORD_BANK := Vector3(4.0, 0.0, 11.0)     ## south bank, out of the ford's slow water
const FOOT := Vector3(-6.0, 0.0, 25.0)          ## between the standards, under the crest spires
const TREE_GUARD := Vector3(-12.0, 0.0, 41.0)   ## the refuge's north edge
const WEST_POINT := Vector3(-40.0, 0.0, 12.0)
const WORKERS := 11
const HOLLOWS: Array[Vector3] = [Vector3(-34.0, 0.0, 60.0), Vector3(-26.0, 0.0, 62.0), Vector3(-52.0, 0.0, 46.0)]
const HALL2 := Vector3(-30.0, 0.0, 36.0)
const BIRCHWATER_AT := 470.0   ## the army crosses Birch Ford after W2 (7:00) is beaten
const FORD_BY := 560.0         ## back on the ford's bank for W3 (9:30)

var verbose := false
var difficulty := 1
var h := MissionHarness.new()
var main: MissionE4_01
var phase := &"build"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hollow_i := 0
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _sites: Array = []
var _det: Array = []          ## the west detachment (the P2 + P4 posts)
var _wounded := {}
var _w3_hero_hp := 1.0
var _bell_log: Array[String] = []
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	i = args.find("--difficulty")
	if i >= 0 and i + 1 < args.size():
		difficulty = int(args[i + 1])
	h.task_id = TASK_ID
	h.protect_hero = false
	h.timeout_frames = 135000
	main = h.open(self, MISSION, {"difficulty": difficulty}) as MissionE4_01
	h.steps.add("play", _play, 134000)
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
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = (CUTSCENE_SECONDS[&"horn"] if m.has_fired(&"E11") else 0.0) \
				+ (CUTSCENE_SECONDS[&"foot"] if m.has_fired(&"E15b") else 0.0) + (CUTSCENE_SECONDS[&"nightfall"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); folk saved %d lost %d; ford %s; horns %d / 2; tree %d / %d; hero HP after W3 %d %%" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), m.folk_saved, m.folk_lost,
				"lost at " + _mmss(m.ford_lost_at) if m.ford_lost_at >= 0.0 else "held", 2 - m.horns_down,
				int(m.tree.hp) if is_instance_valid(m.tree) else 0, int(m.tree.max_hp) if is_instance_valid(m.tree) else 0,
				int(100.0 * _w3_hero_hp)])
		print("  phases %s; bells %s; waves %s; spotlight %s" % [", ".join(_phase_log), ", ".join(_bell_log),
				",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Nature losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if m.has_fired(&"E9"):
		_w3_hero_hp = minf(_w3_hero_hp, m.hero.hp / maxf(1.0, m.hero.max_hp))
	for id: StringName in m.bells:
		var b: Dictionary = m.bells[id]
		var tag := "%s@%s" % [id, _mmss(m.mission_time())]
		var key := "%s:%s" % [id, "rung" if b["roused"] else "burned"]
		if (bool(b["roused"]) or bool(b["burned"])) and not _bell_log.any(func(s: String) -> bool: return s.begins_with(key)):
			_bell_log.append("%s:%s" % [key, tag.get_slice("@", 1)])
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		print("    t=%s %s ysolde %3.0f/%3.0f L%d | army %2d det %d (w%d) T%d | crystals %4d pop %d/%d | folk %d saved %d lost | ford %3.0f %% | std %d | tree %d" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _det_alive().size(),
				_workers().size(), m.keep.tier if m.keep else 0, eco.crystals, eco.pop_used, eco.pop_cap, m.folk_saved,
				m.folk_lost, 100.0 * m.ford_zone.progress, m.standards_owned(0), int(m.tree.hp) if is_instance_valid(m.tree) else 0])
		if not killers.is_empty():
			print("      losses so far: %s" % str(killers))
	_economy()
	_spells()
	_plan()
	return false


# ---------------------------------------------------------------- helpers

func _soldiers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable() and not u is Helper:
			out.append(u)
	return out


func _det_alive() -> Array[Unit]:
	var out: Array[Unit] = []
	for v: Variant in _det:
		if is_instance_valid(v) and (v as Unit).is_alive():
			out.append(v as Unit)
	return out


func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _soldiers():
		if not _det.has(u):
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
		if u and u.is_alive() and Teams.side_of(int(u.team)) == 1 and not main.is_dormant(u) \
				and not u.has_meta(Unit.TRUCE_META) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _group_to(units: Array, at: Vector3, facing: Vector3 = Vector3(0.0, 0.0, -1.0)) -> void:
	SimTactics.spread_to(units, at, facing)


## The group fights what is within `r` of `at` (the nearest first), else forms up there. Enemy wizards in reach are
## focused by the ranged units (the Unit Guide answer).
func _hold(units: Array, at: Vector3, r: float, facing := Vector3(0.0, 0.0, -1.0)) -> bool:
	if units.is_empty():
		return false
	var ranged: Array = units.filter(func(u: Unit) -> bool: return SimTactics.is_ranged(u))
	SimTactics.focus_wizards(ranged, [main.malrik, main.torvald], 14.0, func(w: Unit) -> bool: return not main.is_dormant(w))
	var foes := _enemies_near(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		return true
	_group_to(units, at, facing)
	return false


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.find_spot(t, at, 0)
	if c == Vector3.INF:
		return false
	var site := main.build_grid.place(t, c, Unit.Team.PLAYER, [worker])
	if site:
		_sites.append([site, worker])
	return site != null


func _tend_sites(workers: Array[Unit]) -> Array:
	var busy: Array = []
	_sites = _sites.filter(func(r: Array) -> bool: return is_instance_valid(r[0]) and (r[0] as Building).is_alive() \
			and not (r[0] as Building).is_constructed())
	for r: Array in _sites:
		var w: Variant = r[1]
		if w == null or not is_instance_valid(w) or not (w as Unit).is_alive():
			if workers.is_empty():
				continue
			w = workers[0]
			r[1] = w
		var wu := w as Unit
		busy.append(wu)
		if not bool(wu.call(&"is_building")) and not wu.has_move_order():
			wu.call(&"command_build", r[0])
	return busy


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var m := main
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var node: CrystalNode = null
	for suffix in ["a", "b", "x"]:
		node = m.node_of(0, suffix)
		if node:
			break
	var busy := _tend_sites(workers)
	for w in workers:
		if busy.has(w):
			continue
		var t: Variant = w.get(&"gather_node")
		if node and not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			w.call(&"command_gather", node)
	var k := m.keep
	if k == null or not k.is_alive():
		return
	var saving := k.tier < 2 and m.mission_time() >= 200.0 and not k.is_upgrading()
	if k.tier < 2 and m.mission_time() >= 210.0 and k.can_upgrade() == "":
		k.upgrade()
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= (250 if saving else 40):
		if k.queue_unit(UnitType.find("sprigling")) == "" and node:
			k.set_rally_node(node)
	if workers.is_empty():
		return
	if eco.pop_cap - eco.pop_used < 6 and _hollow_i < HOLLOWS.size() and eco.crystals >= (280 if saving else 90):
		_build("nature_hollow", HOLLOWS[_hollow_i], workers[0])
		_hollow_i += 1
	var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and b.building_type.id == &"nature_barracks").size()
	if halls < 2 and eco.crystals >= 200 and m.mission_time() > 100.0 and not saving:
		_build("nature_barracks", HALL2, workers[0])
	if k.tier >= 2 and k.queue.size() < 2 and eco.crystals >= 150:
		var sages := _soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"bramblesage").size()
		if sages < 2:
			k.queue_unit(UnitType.find("bramblesage"))
	if saving and eco.crystals < 260:
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"nature_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 90:
			continue
		var mix: Array = ["thornling", "burr_slinger", "thornling", "vinelasher", "greenheart_oathkeeper", "burr_slinger",
				"bloomtender", "thornling"] if k.tier >= 2 else ["thornling", "burr_slinger", "thornling", "bloomtender"]
		var want: String = mix[_train_i % mix.size()]
		if hall.queue_unit(UnitType.find(want)) != "":
			hall.queue_unit(UnitType.find("thornling"))
		_train_i += 1
		hall.set_rally_point(RALLY)
	for u in _soldiers():
		var ca := u.get_node_or_null(^"CasterAbility")
		if ca and ca.has_method(&"set_autocast"):
			for sid: StringName in [&"snagroot", &"pollen_haze"]:
				if not bool(ca.call(&"autocast", sid)):
					ca.call(&"set_autocast", sid, true)


## Ysolde casts what her kit suggests (the bots' own Nature rule: Thornburst on a clump, Wild Bloom on the hurt line),
## and learns ranks on level-up (Thornburst, then Wild Bloom, then the Thicket).
func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"thornburst", &"call_the_thicket", &"wild_bloom"]:
			if w.learn_spell(id) == "":
				break
	if w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		return
	if _enemies_near(w.global_position, 14.0).is_empty() and w.hp > w.max_hp * 0.8:
		return
	var s: Dictionary = w.spell_caster.call(&"suggest_cast")
	if s.is_empty():
		return
	var id := StringName(str(s.get("spell_id", "")))
	if id != &"":
		w.command_cast(id, s.get("target"))


# ---------------------------------------------------------------- the plan

func _bell_open(id: StringName) -> bool:
	var b: Dictionary = main.bells[id]
	return not bool(b["roused"]) and not bool(b["burned"])


func _plan() -> void:
	var m := main
	var hero := m.hero
	var t := m.mission_time()
	if _det.is_empty() and t < 5.0:
		for u in _soldiers():
			var p := u.global_position
			if MissionBase._flat(p, Vector3(-28.0, 0.0, 20.0)) < 5.0 or MissionBase._flat(p, Vector3(-40.0, 0.0, 13.0)) < 5.0:
				_det.append(u)
	if not _retreat and hero.hp < hero.max_hp * 0.45:
		_retreat = true
	if _retreat and hero.hp >= hero.max_hp * 0.85:
		_retreat = false
	var army: Array = SimTactics.pull_back_wounded(_army(), TREE_GUARD, _wounded, 0.5)
	var det: Array = _det_alive()
	# --- the west: Larkford, Millbrook, then Reedfield over Reed Ford with the detachment (picket F1 first).
	var hero_goal := Vector3.INF
	if _bell_open(&"larkford"):
		hero_goal = MissionE4_01.BELLS[&"larkford"][1]
	elif _bell_open(&"millbrook"):
		hero_goal = MissionE4_01.BELLS[&"millbrook"][1]
	elif _bell_open(&"reedfield") and t < 430.0:
		var farm: Vector3 = MissionE4_01.BELLS[&"reedfield"][1]
		var picket_up := not MissionBase._all_dead(m.picket_groups[&"F1"])
		_hold(det, farm if picket_up else farm + Vector3(0.0, 0.0, 4.0), 12.0, Vector3(0.0, 0.0, -1.0))
		hero_goal = farm + Vector3(0.0, 0.0, 9.0) if picket_up else farm
	elif _bell_open(&"birchend"):
		hero_goal = MissionE4_01.BELLS[&"birchend"][1]
	elif _bell_open(&"birchwater") and t >= BIRCHWATER_AT and t < 650.0:
		var farm2: Vector3 = MissionE4_01.BELLS[&"birchwater"][1]
		var picket2 := not MissionBase._all_dead(m.picket_groups[&"F2"])
		_set_phase(&"birchwater")
		_hold(army, farm2 if picket2 else farm2 + Vector3(0.0, 0.0, 4.0), 13.0, Vector3(0.0, 0.0, -1.0))
		hero_goal = farm2 + Vector3(0.0, 0.0, 9.0) if picket2 else farm2
		_hold(det, FORD_BANK, 14.0)
		_move_hero(hero_goal)
		return
	# --- the detachment, once Reedfield is done: back to the west horn, then the army.
	if not _bell_open(&"reedfield") or t >= 430.0:
		if t < 700.0:
			_hold(det, WEST_POINT, 16.0)
		else:
			for u in det:
				_det.erase(u)
	# --- the army: the ford's south bank until the evening horn, then the foot, then the tree.
	if not m.has_fired(&"E11"):
		_set_phase(&"ford" if t >= FORD_BY else &"bank")
		var threat := _enemies_near(MissionE4_01.BELLS[&"birchend"][1], 16.0)
		if not threat.is_empty() and t < FORD_BY:
			_hold(army, MissionE4_01.BELLS[&"birchend"][1], 16.0)
		else:
			_hold(army, FORD_BANK, 15.0)
	elif not m.waves_fired.has(&"FINAL") and not m.waves_fired.has(&"RAID"):
		_set_phase(&"foot")
		var spot := FOOT
		var near_tree := _enemies_near(MissionE4_01.GOLDEN_TREE, 18.0)
		if not near_tree.is_empty():
			spot = MissionE4_01.GOLDEN_TREE
		_hold(army, spot, 18.0)
	else:
		_set_phase(&"tree")
		_hold(army, TREE_GUARD, 20.0)
	if hero_goal == Vector3.INF:
		hero_goal = SimTactics.centroid(army) if not army.is_empty() else TREE_GUARD
		if hero_goal == Vector3.INF:
			hero_goal = TREE_GUARD
		hero_goal += Vector3(0.0, 0.0, 6.0)   # behind the line
	_move_hero(hero_goal)


func _move_hero(goal: Vector3) -> void:
	if _retreat:
		_hero_to(MissionE4_01.GOLDEN_TREE + Vector3(0.0, 0.0, -3.0), 3.0)
		return
	_hero_to(goal, 2.0)
