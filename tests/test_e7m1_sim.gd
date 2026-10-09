extends SceneTree
## Mission e7m1 timing check (docs/design/mission-e7-01.md acceptance check 1: a scripted headless run on normal -
## Bazaar, 4 caravans on the Diamond Harbour route, the Stronghold, bids on every auction it can afford, Seraphine
## escorted home, the hold - ends `victory=true` in 22-28 game minutes). The auctions are on the clock (8:00 / 14:00 /
## 20:00) and the hold needs 2:00 after the third hammer, so no rush can win before ~22:45; `-- --passive` (or
## tests/test_e7m1_passive_sim.gd) checks that doing nothing loses (no Bazaar = no bid: Aurivane wins A1 and A2).
## Real fights, cinematics off; e7m1_arrival 0:15 + e7m1_laurel 0:14 + e7m1_dusk 0:30 are added to the play time.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e7m1_sim.gd --fixed-fps 60
## --quit-after 110000

const TASK_ID := "e7m1_sim"
const MISSION := "res://missions/mission_e7_01.tscn"
const CINE_SECONDS := 59.0
const HOLD_SPOT := Vector3(-46.0, 0.0, 14.0)
const LODGE_SPOT := Vector3(-54.0, 0.0, 52.0)
const WORKERS := 10
const CARAVANS := 4

var verbose := false
var passive := false
var h := MissionHarness.new()
var main: MissionE7_01
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _sites: Array = []
var _built := {}
var _route_set := false
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
	h.timeout_frames = 108000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e7m1_sim_none.json"}}) as MissionE7_01
	h.steps.add("play", _play, 107000)
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


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		print("  %s at mission time %s (play time with cutscenes %s); auctions won %d lost %d %s; rock hammers %d; harbour %d %%; seraphine home %s; toll %d" % [
				"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t), MissionE5Base.mmss(t + CINE_SECONDS),
				m.wins, m.losses, str(m.auction_log), m.rock_hammers, int(m.harbour.ratio() * 100.0) if m.harbour else 0,
				m.seraphine_home, m.toll_paid])
		print("  waves %s; gold %d; spotlight %s" % [",".join(m.waves_fired), m.gold(), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  player losses (killer@minute): %s" % str(killers))
		if passive:
			h.check(h.ended == 0, "a passive run won (%s)" % MissionE5Base.mmss(t))
			return true
		h.check(h.ended == 1, "defeat at %s (%s)" % [MissionE5Base.mmss(t), _phase])
		h.check(t + CINE_SECONDS >= 1320.0 and t + CINE_SECONDS <= 1680.0, "play time %s outside 22-28 min" % MissionE5Base.mmss(t + CINE_SECONDS))
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
		print("    t=%s %s torvald %3.0f L%d | army %2d w%d cv%d | crystals %4d gold %4d pop %d/%d T%d | harbour %4.0f | rock %d | wins %d/%d | foes %d" % [
				MissionE5Base.mmss(m.mission_time()), _phase, m.hero.hp, m.hero.level, _soldiers().size(), _workers().size(),
				_caravans().size(), eco.crystals, m.gold(), eco.pop_used, eco.pop_cap, m.keep.tier if m.keep else 0,
				m.harbour.hp if m.harbour else 0.0, m.rock_owner(), m.wins, m.losses, _foes(HOLD_SPOT, 40.0).size()])
	_economy()
	_bids()
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


func _caravans() -> Array:
	var mk := Market.of_team(0)
	return mk.caravans() if mk else []


func _foes(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and not main.is_dormant(u) \
				and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hold(units: Array, at: Vector3, r: float) -> bool:
	if units.is_empty():
		return false
	var foes := _foes(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		return true
	SimTactics.spread_to(units, at, Vector3(1.0, 0.0, -1.0))
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
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w):
			free_w = w
			break
	var market := Market.of_team(0)
	if market == null and not _built.has("bazaar") and free_w and eco.crystals >= 175:
		if _build("ice_market", MissionE7Base.BAZAAR_SPOT, free_w):
			_built["bazaar"] = true
		return
	if market and market.is_constructed():
		if not _route_set:
			var p := m.post_named(&"heron_ford")
			if p:
				_route_set = market.set_route(p) == ""
		if _caravans().size() + market.queue.size() < CARAVANS and market.queue.size() < 1 and eco.crystals >= 75:
			market.queue_unit(UnitType.find("caravan"))
	if k.tier < 2 and k.can_upgrade() == "" and not k.is_upgrading() and eco.crystals >= 200:
		k.upgrade()
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		if k.queue_unit(UnitType.find("rime_hauler")) == "":
			var node: CrystalNode = m.node_of(0, "a")
			if node:
				k.set_rally_node(node)
	elif k.tier >= 2 and k.queue.size() < 1 and eco.crystals >= 150:
		var carvers := _soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"rimecarver").size()
		if carvers < 1:
			k.queue_unit(UnitType.find("rimecarver"))
			k.set_rally_point(HOLD_SPOT)
	if free_w and eco.pop_cap - eco.pop_used < 6 and _built.size() < 5 and not _built.has("l%d" % int(eco.pop_cap)) \
			and eco.crystals >= 100:
		if _build("ice_lodge", LODGE_SPOT + Vector3(0.0, 0.0, -6.0 * _built.size()), free_w):
			_built["l%d" % int(eco.pop_cap)] = true
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"ice_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 110:
			continue
		var mix: Array = ["rimeshield", "shardcaster", "rimeshield", "shardcaster", "rime_seer", "frost_mortar"]
		var want: String = mix[_train_i % mix.size()]
		if hall.queue_unit(UnitType.find(want)) != "":
			want = "rimeshield"
			hall.queue_unit(UnitType.find(want))
		_train_i += 1
		hall.set_rally_point(HOLD_SPOT)


## Bids: answer Aurivane by +50 whenever the coffers allow, keeping 50 back.
func _bids() -> void:
	var m := main
	if not m.auction_open():
		return
	var bids: Array = m.auction["bids"]
	var safe := int(bids[0]) > int(bids[1]) and (m.rock_owner() != 1 or float(bids[1]) < float(bids[0]) * 0.89)
	if safe:
		return
	if m.gold() >= maxi(int(bids[0]), int(bids[1])) + 50:
		m.player_bid(50)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"rime_aegis", &"flash_freeze", &"rime_bolt"]:
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


## The army takes the Tollrock before each hammer (the rock's word) and walks home after it.
func _rock_time() -> bool:
	var t := main.mission_time()
	for a: float in MissionE7_01.A_TIMES:
		if t >= a - 100.0 and t < a + 50.0:
			return true
	return false


func _plan() -> void:
	var m := main
	var army := _soldiers()
	var s := m.seraphine
	var escort := m.has_fired(&"E11") and not m.seraphine_home and s != null and is_instance_valid(s) and s.is_alive()
	# two thirds go out (the rock, Seraphine), a third holds the harbour and the base
	var out: Array = []
	var home: Array = []
	for i in army.size():
		if i % 3 == 2:
			home.append(army[i])
		else:
			out.append(army[i])
	var spot := HOLD_SPOT + Vector3(-3.0, 0.0, 3.0)
	if escort:
		_phase = "escort"
		var foes := _foes(s.global_position, 14.0)
		for v: Variant in out:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				if not foes.is_empty():
					u.command_attack(foes[0])
				elif MissionBase._flat(u.global_position, s.global_position) > 6.0:
					u.command_attack_move(s.global_position)
		spot = s.global_position if MissionBase._flat(m.hero.global_position, s.global_position) > 5.0 else HOLD_SPOT
		_hold(home, HOLD_SPOT, 26.0)
	elif _rock_time() and m.hold_started < 0.0:
		_phase = "rock"
		var foes := _foes(MissionE7Base.ROCK, 14.0)
		for v: Variant in out:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				if not foes.is_empty():
					u.command_attack(foes[0])
				elif MissionBase._flat(u.global_position, MissionE7Base.ROCK) > 4.0:
					u.command_attack_move(MissionE7Base.ROCK + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0)))
		_hold(home, HOLD_SPOT, 26.0)
	else:
		_phase = "final" if m.hold_started >= 0.0 else "hold"
		_hold(army, HOLD_SPOT, 26.0)
	if not escort and m.hero.hp < m.hero.max_hp * 0.35:
		spot = MissionE7Base.RIME_KEEP + Vector3(6.0, 0.0, -6.0)
	if MissionBase._flat(m.hero.global_position, spot) > 3.0:
		m.hero.command_move(spot)
