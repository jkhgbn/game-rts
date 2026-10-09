extends SceneTree
## Mission e6m3 timing / balance check (docs/design/mission-e6-03.md acceptance "Timing / balance": a scripted headless
## run on normal with 2 tenders per garden at each night and the army on the busiest front reaches spring with >= 3
## gardens; spring is fixed at 16:00, the e6m3_spring film 0:50 is added to the reported play time). Real fights,
## cinematics off. tests/test_e6m3_passive_sim.gd: no tending, the army idle = at most 2 gardens (a defeat on normal).
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e6m3_sim.gd --fixed-fps 60
## --quit-after 80000

const TASK_ID := "e6m3_sim"
const MISSION := "res://missions/mission_e6_03.tscn"
const SPRING_FILM := 50.0
const HOLLOW := Vector3(-46.0, 0.0, 56.0)
const RALLY := Vector3(-10.0, 0.0, 30.0)
const WORKERS := 12

var verbose := false
var passive := false
var h := MissionHarness.new()
var main: MissionE6_03
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _sites: Array = []
var _built := {}
var _tenders := {}          # Unit -> garden index


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("_passive" if passive else "")
	h.protect_hero = false
	h.timeout_frames = 78000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e6m3_sim_none.json"}}) as MissionE6_03
	h.steps.add("play", _play, 77000)


func _process(_delta: float) -> bool:
	return h.tick()


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var life: Array[String] = []
		for g: Variant in m.gardens:
			life.append("%d" % int((g as MissionE6_03.SeedGarden).hp))
		print("  %s at mission time %s (play time with the film %s); gardens %d alive [%s]; sprouts %d; Whitepelt %s" % [
				"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t), MissionE5Base.mmss(t + SPRING_FILM),
				m.gardens_alive(), ", ".join(life), m.sprouts, m.objective_state("sec_whitepelt")])
		print("  waves %s; spotlight %s" % [",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		if passive:
			h.check(h.ended == 0 or m.gardens_alive() <= 2, "a passive run kept %d gardens" % m.gardens_alive())
			return true
		h.check(h.ended == 1, "defeat at %s" % MissionE5Base.mmss(t))
		h.check(m.gardens_alive() >= 3, "only %d gardens at spring" % m.gardens_alive())
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
		var life: Array[String] = []
		for g: Variant in m.gardens:
			life.append("%3d" % int((g as MissionE6_03.SeedGarden).hp))
		print("    t=%s night %d ysolde %3.0f L%d | army %2d w%d tend %d | crystals %4d pop %d/%d | gardens %s | wolves %d" % [
				MissionE5Base.mmss(m.mission_time()), m.night, m.hero.hp, m.hero.level, _soldiers().size(), _workers().size(),
				_tenders.size(), eco.crystals, eco.pop_used, eco.pop_cap, " ".join(life), _wolves().size()])
	_economy()
	_spells()
	_plan()
	return false


func _soldiers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable():
			out.append(u)
	return out


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


func _wolves(at := Vector3.INF, r := INF) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and (at == Vector3.INF or MissionBase._flat(u.global_position, at) <= r):
			out.append(u)
	return out


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.find_spot(t, at, 0)
	if c == Vector3.INF:
		return false
	var site := main.build_grid.place(t, c, Unit.Team.PLAYER, [worker])
	if site:
		_sites.append([site, worker])
	return site != null


func _tending_time() -> bool:
	var m := main
	return m.night >= 0 or m.night_in() <= 14.0


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
	# Tending: 2 Spriglings onto each living garden from 14 s before a night until it ends.
	_tenders = _tenders.duplicate()
	for k: Variant in _tenders.keys():
		if not is_instance_valid(k) or not (k as Unit).is_alive():
			_tenders.erase(k)
	if _tending_time():
		var free: Array = workers.filter(func(w: Unit) -> bool: return not busy.has(w) and not _tenders.has(w))
		for gi in m.gardens.size():
			var g := m.gardens[gi] as MissionE6_03.SeedGarden
			if not g.is_alive():
				continue
			var have := _tenders.values().count(gi)
			while have < 2 and not free.is_empty():
				var w := free.pop_back() as Unit
				_tenders[w] = gi
				have += 1
		for w: Variant in _tenders:
			var g := m.gardens[int(_tenders[w])] as MissionE6_03.SeedGarden
			var spot := g.global_position + Vector3(0.9 if _tenders.keys().find(w) % 2 == 0 else -0.9, 0.0, 0.9)
			if MissionBase._flat((w as Unit).global_position, spot) > 1.2 and not (w as Unit).has_move_order():
				(w as Unit).command_move(spot)
	elif not _tenders.is_empty():
		_tenders.clear()
	for w in workers:
		if busy.has(w) or _tenders.has(w):
			continue
		var t: Variant = w.get(&"gather_node")
		if not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			for s in ["a", "b", "rich"]:
				var node: CrystalNode = m.node_of(0, s)
				if node:
					w.call(&"command_gather", node)
					break
	var k := m.keep
	if k == null or not k.is_alive():
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		if k.queue_unit(UnitType.find("sprigling")) == "":
			var node: CrystalNode = m.node_of(0, "a")
			if node:
				k.set_rally_node(node)
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w) and not _tenders.has(w):
			free_w = w
			break
	if free_w and eco.pop_cap - eco.pop_used < 5 and not _built.has("hollow") and eco.crystals >= 100:
		if _build("nature_hollow", HOLLOW, free_w):
			_built["hollow"] = true
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"nature_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 70:
			continue
		var mix: Array = ["thornling", "thornling", "burr_slinger", "thistle_darter", "bloomtender"]
		hall.queue_unit(UnitType.find(mix[_train_i % mix.size()]))
		_train_i += 1
		hall.set_rally_point(RALLY)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"wild_bloom", &"thornburst", &"call_the_thicket"]:
			if w.learn_spell(id) == "":
				break
	for v: Variant in main.gardens:
		var g := v as MissionE6_03.SeedGarden
		if g.is_alive() and g.ratio() < 0.6 and MissionBase._flat(g.global_position, w.global_position) < 10.0:
			if w.command_cast(&"wild_bloom", g.global_position) == "":
				return
	var foes := _wolves(w.global_position, 12.0)
	if foes.size() >= 4 and w.command_cast(&"call_the_thicket", foes[0].global_position) == "":
		return
	if not foes.is_empty():
		w.command_cast(&"thornburst", foes[0].global_position)


func _plan() -> void:
	var m := main
	var army := _soldiers()
	# The busiest garden: the most wolves within 18 m (ties: the lowest Life).
	var best: MissionE6_03.SeedGarden = null
	var best_n := 0
	for v: Variant in m.gardens:
		var g := v as MissionE6_03.SeedGarden
		if not g.is_alive():
			continue
		var n := _wolves(g.global_position, 18.0).size()
		if n > best_n or (n == best_n and n > 0 and best and g.ratio() < best.ratio()):
			best = g
			best_n = n
	var at := RALLY if best == null else best.global_position
	var foes := _wolves(at, 18.0)
	for u in army:
		if not foes.is_empty():
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		elif MissionBase._flat(u.global_position, at) > 6.0 and not u.has_move_order():
			u.command_move(at + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
	# Ysolde: by the lowest living garden near the army (her touch), back home under 35 % HP.
	var low: MissionE6_03.SeedGarden = null
	for v: Variant in m.gardens:
		var g := v as MissionE6_03.SeedGarden
		if g.is_alive() and g.index != 3 and (low == null or g.ratio() < low.ratio()):
			low = g
	var spot: Vector3 = (best.global_position if best else (low.global_position if low else RALLY)) + Vector3(-2.0, 0.0, 3.0)
	if m.hero.hp < m.hero.max_hp * 0.35:
		spot = MissionE6_03.KEEP_POS + Vector3(6.0, 0.0, -6.0)
	if MissionBase._flat(m.hero.global_position, spot) > 2.5:
		m.hero.command_move(spot)
