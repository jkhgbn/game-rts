extends SceneTree
## Mission e3m3 timing check (docs/design/mission-e3-03.md acceptance check S2: a scripted normal run (call Hush at ~2:30,
## relight B1, B2, B3, B4, kill the Sexton) with 0 uses of the stone ends `victory=true` in 20-25 game-minutes and never
## loses the crypt). Real fights: no hero protection, no kills or time skips by the test; cinematics off, the spec
## lengths of e3m3_homecoming 0:20, e3m3_offer 0:10, e3m3_sexton 0:20 and e3m3_rest 0:30 are added to the play time.
## The scripted player: Thralls to 11, Hovels, a second Gloom Hall, Shades / Nightbolts / Knights / Hexweavers, 2
## Nightblood Reavers and a second Deacon at the Seat, Hush called at ~2:30; a guard of 8 at the crypt; the rest of the
## army walks Malrik to each open barrow's candle (B1, B2, then B3, B4), clears it and waits for the relight; the Sexton
## is fought at the crypt. `-- --seed N`, `-- --verbose`, `-- --stone` (Heart of the Hollow on every cooldown).
## Slow. Run: godot --headless --path . -s tests/test_e3m3_sim.gd --fixed-fps 60 --quit-after 120000

const TASK_ID := "e3m3_sim"
const MISSION := "res://missions/mission_e3_03.tscn"
const CUTSCENE_SECONDS := {&"home": 20.0, &"offer": 10.0, &"sexton": 20.0, &"rest": 30.0}
const RALLY := Vector3(0.0, 0.0, -10.0)
const CRYPT_GUARD := Vector3(0.0, 0.0, 7.0)
const HOVELS: Array[Vector3] = [Vector3(22.0, 0.0, -42.0), Vector3(-24.0, 0.0, -46.0), Vector3(24.0, 0.0, -50.0),
		Vector3(-24.0, 0.0, -36.0)]
const HALL2 := Vector3(-14.0, 0.0, -28.0)
const WORKERS := 11
const GUARDS := 8
const ORDER: Array[StringName] = [&"B1", &"B2", &"B3", &"B4"]

var verbose := false
var use_stone := false
var h := MissionHarness.new()
var main: MissionE3_03
var phase := &"build"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hovel_i := 0
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _guard: Array = []
var _sites: Array = []
var _crypt_min := 100.0
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	use_stone = args.has("--stone")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("/stone" if use_stone else "")
	h.protect_hero = false
	h.timeout_frames = 115000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e3m3_sim_none.json"}}) as MissionE3_03
	h.steps.add("play", _play, 114000)
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
	if m.crypt and is_instance_valid(m.crypt) and m.crypt.is_alive():
		_crypt_min = minf(_crypt_min, 100.0 * m.crypt.hp / maxf(1.0, m.crypt.max_hp))
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"home"] + (CUTSCENE_SECONDS[&"offer"] if m.heart_enabled else 0.0) \
				+ (CUTSCENE_SECONDS[&"sexton"] if m.sexton_phase > 0 else 0.0) + (CUTSCENE_SECONDS[&"rest"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); candles %d / 4; crypt min %d %%; stone uses %d, hold %d %%, seizures %d" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), m.candles_lit(), int(_crypt_min), m.shard_uses,
				int(m.stone_hold), m.seizures])
		print("  phases %s; spotlight %s" % [", ".join(_phase_log), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Shadow losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		print("    t=%s %s malrik %3.0f/%3.0f L%d | army %2d guard %d (w%d) | crystals %4d pop %d/%d | candles %d | crypt %.0f | hollow %d | sexton %s | hold %.0f" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _guard.size(),
				_workers().size(), eco.crystals, eco.pop_used, eco.pop_cap, m.candles_lit(),
				m.crypt.hp if m.crypt and is_instance_valid(m.crypt) else -1.0, m.get_tree().get_nodes_in_group(&"hollow").size(),
				"%.0f" % m.sexton.hp if m.sexton and is_instance_valid(m.sexton) else "-", m.stone_hold])
	_economy()
	_lance()
	_guard_crypt()
	_plan()
	return false


func _all_soldiers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable() and not u is Helper:
			out.append(u)
	return out


func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _all_soldiers():
		if not _guard.has(u):
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
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not main.is_dormant(u) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	return out


func _army_to(at: Vector3, spread := 4.0) -> void:
	for u in _army():
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if MissionBase._flat(u.global_position, at) > spread + 2.0:
			u.command_attack_move(at + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread)))


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _lance() -> void:
	var hero := main.hero
	var foes := _enemies_near(hero.global_position, 11.0)
	if use_stone and main.heart_enabled and foes.size() >= 3:
		main.use_heart()
	if foes.is_empty():
		return
	var best: Unit = foes[0]
	for u in foes:
		if u.hp < best.hp:
			best = u
	if hero.mana > 45.0:
		hero.command_cast(&"shadow_lance", best)
	if foes.size() >= 3 and hero.mana > 60.0:
		hero.command_cast(&"soul_siphon", foes[0].global_position)
	var w := hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"shadow_lance", &"soul_siphon", &"umbral_shroud"]:
			if w.learn_spell(id) == "":
				break


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
	for id: StringName in [&"e3m3_seat_a", &"e3m3_seat_b", &"e3m3_ossuary_w", &"e3m3_ossuary_e"]:
		var v: Variant = m.crystal_nodes.get(id)
		if v != null and is_instance_valid(v) and not (v as CrystalNode).is_depleted():
			node = v as CrystalNode
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
	var roster := HelperRoster.for_team(0)
	if roster and m.mission_time() >= 150.0:
		if roster.state() == &"fallen" and roster.can_revive() == "":
			roster.revive()
		elif roster.can_call() == "":
			roster.call_helper()
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		if k.queue_unit(UnitType.find("gloom_thrall")) == "" and node:
			k.set_rally_node(node)
	if workers.is_empty():
		return
	if eco.pop_cap - eco.pop_used < 6 and _hovel_i < HOVELS.size() and eco.crystals >= 80:
		_build("shadow_hovel", HOVELS[_hovel_i], workers[0])
		_hovel_i += 1
	var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and b.building_type.id == &"shadow_barracks").size()
	if halls < 2 and eco.crystals >= 200 and m.mission_time() > 60.0:
		_build("shadow_barracks", HALL2, workers[0])
	var reapers := _all_soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"nightblood_reaver").size()
	var deacons := _all_soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"gloom_deacon").size()
	if k.queue.size() < 2 and eco.crystals >= 280 and reapers < 2:
		k.queue_unit(UnitType.find("nightblood_reaver"))
	elif k.queue.size() < 2 and eco.crystals >= 150 and deacons < 2:
		k.queue_unit(UnitType.find("gloom_deacon"))
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"shadow_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 110:
			continue
		var want: String = ["shade", "nightbolt", "shade", "shadow_knight", "hexweaver", "nightbolt", "shade", "hollow_oathsworn"][_train_i % 8]
		if hall.queue_unit(UnitType.find(want)) != "":
			hall.queue_unit(UnitType.find("shade"))
		_train_i += 1
		hall.set_rally_point(RALLY)
	for u in _all_soldiers():
		var ca := u.get_node_or_null(^"CasterAbility")
		if ca and ca.has_method(&"set_autocast") and not bool(ca.call(&"autocast", &"blood_tithe")):
			ca.call(&"set_autocast", &"blood_tithe", true)


## The crypt guard (8, the Reavers first): Wardens near the crypt are theirs.
func _guard_crypt() -> void:
	_guard = _guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _guard.size() < GUARDS:
		var soldiers := _all_soldiers()
		soldiers.sort_custom(func(a: Unit, b: Unit) -> bool: return a.unit_type.id == &"nightblood_reaver" and b.unit_type.id != &"nightblood_reaver")
		for u in soldiers:
			if _guard.size() >= GUARDS:
				break
			if not _guard.has(u) and u.unit_type.id != &"gloom_deacon":
				_guard.append(u)
	var foes := _enemies_near(Vector3.ZERO, 16.0)
	for g: Variant in _guard:
		var u := g as Unit
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if not foes.is_empty():
			u.command_attack(foes[0])
		elif MissionBase._flat(u.global_position, CRYPT_GUARD) > 6.0:
			u.command_attack_move(CRYPT_GUARD)


func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.35:
		_retreat = true
	if _retreat:
		_hero_to(RALLY, 3.0)
		if hero.hp >= hero.max_hp * 0.8:
			_retreat = false
	var army := _army()
	if m.sexton_phase >= 1 and m.sexton_phase < 3 and m.sexton and is_instance_valid(m.sexton) and m.sexton.is_alive():
		_set_phase(&"sexton")
		for u in army:
			if u.attack_target != m.sexton and (u.attack_target == null or not is_instance_valid(u.attack_target)):
				u.command_attack(m.sexton)
		if not _retreat:
			_hero_to(m.sexton.global_position + (Vector3(0.0, 0.0, -9.0)), 3.0)
		return
	# The next open barrow (B1, B2, B3, B4 order) with an army able to walk there; else hold the crypt.
	var target := &""
	for id in ORDER:
		if m.doors_open.get(id, false) and not m.candles[id]:
			target = id
			break
	if target == &"" or army.size() < 8:
		_set_phase(&"crypt")
		var foes := _enemies_near(Vector3.ZERO, 18.0)
		_army_to(foes[0].global_position if not foes.is_empty() else RALLY, 3.0)
		if not _retreat:
			_hero_to(RALLY + Vector3(0.0, 0.0, -4.0), 3.0)
		return
	_set_phase(StringName("candle_%s" % target))
	var candle: Vector3 = MissionE3_03.BARROWS[target][2]
	var door: Vector3 = MissionE3_03.BARROWS[target][1]
	var near := _enemies_near(candle, 12.0)
	if not near.is_empty():
		_army_to(near[0].global_position, 3.0)
	else:
		_army_to(candle.lerp(door, 0.5), 3.0)
	if _retreat:
		return
	if _enemies_near(candle, MissionE3_03.CANDLE_BLOCK).is_empty():
		_hero_to(candle, 1.0)
	else:
		_hero_to(candle.lerp(Vector3.ZERO, 0.35), 2.0)
