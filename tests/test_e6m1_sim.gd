extends SceneTree
## Mission e6m1 timing check (docs/design/mission-e6-01.md acceptance "Timing": a scripted headless run on normal holds
## the NE gap, carves both stones in the thaws and ends `victory=true` at 18:00-20:00 mission time with the Heartfrost
## above 40 %). Real fights: no hero protection, no kills or time skips by the test; cinematics off (fallback end states),
## the spec lengths of e6m1_heartfrost 0:30 and e6m1_return 0:40 are added to the reported play time.
## The scripted player: Rime Haulers to 10, Rimeshields / Shardcasters / Rime Seers from the Frost Hall, a Snow Lodge,
## the army on the lake in front of the Heartfrost (it fights what comes within 18 m), Torvald beside the Heartfrost
## (its regen) casting Rime Bolt / Flash Freeze, a walk to the Sentinel stones in each thaw.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e6m1_sim.gd --fixed-fps 60
## --quit-after 90000

const TASK_ID := "e6m1_sim"
const MISSION := "res://missions/mission_e6_01.tscn"
const CUTSCENE_SECONDS := 30.0
const RETURN_SECONDS := 40.0
const HOLD := Vector3(6.0, 0.0, -6.0)         ## the army's spot on the lake, toward the NE gap
const TORVALD_SPOT := Vector3(-3.0, 0.0, 3.0)
const LODGE := Vector3(-48.0, 0.0, 50.0)
const WORKERS := 10

var verbose := false
var passive := false        ## test_e6m1_passive_sim: the army and Torvald never move, nothing is built
var h := MissionHarness.new()
var main: MissionE6_01
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _sites: Array = []
var _built := {}
var _min_heart := 1.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("_passive" if passive else "")
	h.protect_hero = false
	h.timeout_frames = 88000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e6m1_sim_none.json"}}) as MissionE6_01
	h.steps.add("play", _play, 87000)


func _process(_delta: float) -> bool:
	return h.tick()


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if m.heartfrost:
		_min_heart = minf(_min_heart, m.heartfrost.ratio())
	if h.ended >= 0:
		var t := m.mission_time()
		var cine := CUTSCENE_SECONDS + (RETURN_SECONDS if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); Heartfrost min %d %%; carved %d; floes broken %d (sunk %d); Aldra falls %d; longhouse %s" % [
				"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t), MissionE5Base.mmss(t + cine),
				int(_min_heart * 100.0), m.carved, m.floes_broken, (m.lake as MissionE6_01.E6Lake).sunk, m.aldra_falls,
				m.objective_state("sec_longhouse")])
		print("  waves %s; spotlight %s" % [",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		if passive:
			h.check(h.ended == 0, "a passive player won (%s)" % MissionE5Base.mmss(t))
			return true
		h.check(h.ended == 1, "defeat at %s" % MissionE5Base.mmss(t))
		h.check(t >= 1080.0 and t <= 1200.0, "mission time %s outside 18:00-20:00" % MissionE5Base.mmss(t))
		h.check(_min_heart > 0.4, "the Heartfrost fell to %d %%" % int(_min_heart * 100.0))
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
		print("    t=%s season %d torvald %3.0f/%3.0f L%d | army %2d w%d | crystals %4d pop %d/%d | heart %4.0f | foes %d" % [
				MissionE5Base.mmss(m.mission_time()), m.season, m.hero.hp, m.hero.max_hp, m.hero.level, _soldiers().size(),
				_workers().size(), eco.crystals, eco.pop_used, eco.pop_cap, m.heartfrost.hp, _foes_near(Vector3.ZERO, 80.0).size()])
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
				and u.is_commandable():
			out.append(u)
	return out


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


func _foes_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


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
			for s in ["a", "b", "rich", "mid"]:
				var node: CrystalNode = m.node_of(0, s)
				if node:
					w.call(&"command_gather", node)
					break
	var k := m.keep
	if k == null or not k.is_alive():
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		if k.queue_unit(UnitType.find("rime_hauler")) == "":
			var node: CrystalNode = m.node_of(0, "a")
			if node:
				k.set_rally_node(node)
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w):
			free_w = w
			break
	if free_w and eco.pop_cap - eco.pop_used < 6 and not _built.has("lodge%d" % int(eco.pop_cap)) and eco.crystals >= 100:
		if _build("ice_lodge", LODGE + Vector3(0.0, 0.0, -5.0 * _built.size()), free_w):
			_built["lodge%d" % int(eco.pop_cap)] = true
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"ice_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 90:
			continue
		var mix: Array = ["rimeshield", "shardcaster", "rimeshield", "rime_seer", "shardcaster"]
		if hall.queue_unit(UnitType.find(mix[_train_i % mix.size()])) == "":
			_train_i += 1
		hall.set_rally_point(HOLD)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"flash_freeze", &"rime_bolt", &"rime_aegis"]:
			if w.learn_spell(id) == "":
				break
	var foes := _foes_near(w.global_position, 14.0)
	if foes.is_empty():
		return
	var on_floe := foes.filter(func(u: Unit) -> bool: return GlasswaterLake.floe_at(u.global_position) >= 0)
	if foes.size() >= 3 and w.command_cast(&"flash_freeze", (on_floe[0] if not on_floe.is_empty() else foes[0]).global_position) == "":
		return
	w.command_cast(&"rime_bolt", on_floe[0] if not on_floe.is_empty() else foes[0])


# ---------------------------------------------------------------- the plan

func _plan() -> void:
	var m := main
	var army := _soldiers()
	var foes := _foes_near(Vector3.ZERO, 20.0)
	var raid := _foes_near(MissionE6_01.LONGHOUSE_POS, 12.0)
	var heart_foes := foes.size()
	if heart_foes > 0:
		for u in army:
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
	elif raid.size() > 0 and not m.is_winter():
		for u in army:
			if u.attack_target == null:
				u.command_attack_move(raid[0].global_position)
	else:
		SimTactics.spread_to(army, HOLD, Vector3(1.0, 0.0, -1.0))
	# Torvald: carve in a thaw while the lake is quiet, else beside the Heartfrost.
	if m.objective_state("sec_sentinels") == "active" and not m.is_winter() and heart_foes == 0 and m.carved < 2:
		var stone: Vector3 = MissionE6_01.SENTINEL_STONES[m.carved]
		for i in MissionE6_01.SENTINEL_STONES.size():
			if float(m.carve[i]) < MissionE6_01.CARVE_TIME:
				stone = MissionE6_01.SENTINEL_STONES[i]
				break
		_hero_to(stone + Vector3(2.0, 0.0, -2.0), 2.0)
		return
	if m.hero.hp < m.hero.max_hp * 0.35:
		_hero_to(TORVALD_SPOT + Vector3(-6.0, 0.0, 6.0), 2.0)
	else:
		_hero_to(TORVALD_SPOT, 2.5)
