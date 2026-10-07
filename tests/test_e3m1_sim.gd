extends SceneTree
## Mission e3m1 timing check (docs/design/mission-e3-01.md "Lead" check: a scripted headless run on normal takes the
## ford, the 3 standards and holds them, `victory=true` in 22-28 game-minutes; the W3 fight leaves Malrik alive). Real
## fights: no hero protection, no kills or time skips by the test; cinematics off (their fallback end states), the spec
## lengths of e3m1_ford 0:12, e3m1_standard 0:10 and e3m1_dusk 0:30 are added to the reported play time.
## The scripted player: Thralls to 11, Hovels, a second Gloom Hall, the Stronghold at 3:30, Shades / Nightbolts /
## Knights / Hexweavers and 2 Gloom Deacons (autocast); a home guard on the workers until the ford push; the push at
## ~9:00 (or 20 soldiers): the north bank first, then the ford; then Ysolde's Standard, Lark Well, the Clover Stone; the
## hold from between the Clover Stone and the Standard (the army answers any standard under attack).
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e3m1_sim.gd --fixed-fps 60 --quit-after 130000

const TASK_ID := "e3m1_sim"
const MISSION := "res://missions/mission_e3_01.tscn"
const CUTSCENE_SECONDS := {&"ford": 12.0, &"standard": 10.0, &"dusk": 30.0}
const HOME := Vector3(-12.0, 0.0, -42.0)
const RALLY := Vector3(-2.0, 0.0, -24.0)
const NORTH_BANK := Vector3(3.0, 0.0, -8.0)
const HOLD_SPOT := Vector3(-12.0, 0.0, 14.0)
const WORKERS := 14
const HOVELS: Array[Vector3] = [Vector3(-22.0, 0.0, -36.0), Vector3(-26.0, 0.0, -42.0), Vector3(-4.0, 0.0, -40.0),
		Vector3(-28.0, 0.0, -50.0), Vector3(-16.0, 0.0, -56.0)]
const HALL2 := Vector3(-24.0, 0.0, -28.0)
const GUARDS := 5
const PUSH_AT := 690.0
const PUSH_ARMY := 36
const EXPANSION_HALL := Vector3(-41.0, 0.0, -36.0)   ## The west expansion's hall spot (a drop-off by e3_ridge_w).
const BANK_HOLD := Vector3(4.0, 0.0, -8.5)   ## North bank, out of the ford: where the army meets W3 (spec answer).
const STANDARD_ORDER: Array[StringName] = [&"std_well", &"std_clover", &"std_ysolde"]   ## the one between the crest spires last
const REGROUP_ARMY := 24   ## after the ford: rebuild to this before the next standard

var verbose := false
var h := MissionHarness.new()
var main: MissionE3_01
var phase := &"build"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hovel_i := 0
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _home_guard: Array = []
var _sites: Array = []
var _pushing := false
var _w3_hero_hp := 1.0
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
	main = h.open(self, MISSION, {"difficulty": 1}) as MissionE3_01
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
		if k is Wizard:
			who = "wizard:%s" % (k as Wizard).unit_name
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
		var cine: float = (CUTSCENE_SECONDS[&"ford"] if m.has_fired(&"E7") else 0.0) \
				+ (CUTSCENE_SECONDS[&"standard"] if m.has_fired(&"E10") else 0.0) + (CUTSCENE_SECONDS[&"dusk"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); ford %s; horns %d / 2; Vessa driven %s; hero HP after W3 %d %%" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), _mmss(m.ford_taken_at), m.horns_down,
				"yes" if m.vessa_driven else "no", int(100.0 * _w3_hero_hp)])
		print("  phases %s; waves %s; spotlight %s; heartbeats %d" % [", ".join(_phase_log), ",".join(m.waves_fired),
				h.spotlight_log, m.heartbeats])
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
	if m.has_fired(&"E6") and m.hero_alive():
		_w3_hero_hp = minf(_w3_hero_hp, m.hero.hp / maxf(1.0, m.hero.max_hp))
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		var owned := []
		for id: StringName in m.standards:
			owned.append((m.standards[id] as MissionZone).owner_side)
		print("    t=%s %s malrik %3.0f/%3.0f L%d | army %2d (w%d) T%d | crystals %4d pop %d/%d | ford %3.0f %% | standards %s | hold %s | horns %d" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _workers().size(), m.keep.tier if m.keep else 0,
				eco.crystals, eco.pop_used, eco.pop_cap, 100.0 * m.ford_zone.progress if not m.ford_zone.locked else 100.0,
				str(owned), "%.0f" % m.hold_left, m.horns_down])
		if not killers.is_empty():
			print("      losses so far: %s" % str(killers))
		var wn := {}
		for w in _workers():
			var g: Variant = w.get(&"gather_node")
			var key: String = String((g as Node).name) if g != null and is_instance_valid(g) else "none"
			wn[key] = int(wn.get(key, 0)) + 1
		var left := {}
		for id: StringName in [&"e3_dusk_a", &"e3_dusk_b", &"e3_ridge_w", &"e3_reedfield"]:
			var v: Variant = m.crystal_nodes.get(id)
			left[id] = (v as CrystalNode).crystals_left if v != null and is_instance_valid(v) else -1
		print("      workers %s nodes %s" % [str(wn), str(left)])
		if phase == &"ford" or phase == &"build" and m.mission_time() > 540.0:
			var seen := {}
			for u in _enemies_near(MissionE3_01.FORD_ZONE, 24.0):
				var key: String = String(u.unit_type.id) if u.unit_type else String(u.name)
				seen[key] = int(seen.get(key, 0)) + 1
			var mine := {}
			for u in _army():
				var key: String = String(u.unit_type.id)
				mine[key] = int(mine.get(key, 0)) + 1
			print("      near the ford: %s | army %s" % [str(seen), str(mine)])
	_economy()
	_lance()
	_guard_home()
	_plan()
	return false


# ---------------------------------------------------------------- helpers

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
				and not main.is_dormant(u) and not u.has_meta(Unit.TRUCE_META) and MissionBase._flat(u.global_position, at) <= r:
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
	if foes.is_empty():
		return
	var best: Unit = foes[0]
	for u in foes:
		if u is Wizard or u.hp < best.hp:
			best = u
			if u is Wizard:
				break
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
	for suffix in ["a", "b"]:
		node = m.node_of(0, suffix)
		if node:
			break
	if node == null:
		for nid: StringName in [&"e3_ridge_w", &"e3_reedfield"]:
			var v: Variant = m.crystal_nodes.get(nid)
			if v != null and is_instance_valid(v) and not (v as CrystalNode).is_depleted():
				node = v as CrystalNode
				break
	var busy := _tend_sites(workers)
	var ridge_v: Variant = m.crystal_nodes.get(&"e3_ridge_w")
	var ridge := ridge_v as CrystalNode if ridge_v != null and is_instance_valid(ridge_v) and not (ridge_v as CrystalNode).is_depleted() else null
	var ridge_hall := Building.for_team(0).any(func(b: Building) -> bool: return b.is_alive() and b.is_constructed() 			and b.building_type.id == &"shadow_barracks" and MissionBase._flat(b.global_position, EXPANSION_HALL) < 8.0)
	for i in workers.size():
		var w := workers[i]
		if busy.has(w):
			continue
		if ridge and ridge_hall and i % 2 == 1:
			var cur: Variant = w.get(&"gather_node")
			if cur != ridge and not w.call(&"is_building"):
				w.call(&"command_gather", ridge)
			continue
		var t: Variant = w.get(&"gather_node")
		if node and not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			w.call(&"command_gather", node)
	var k := m.keep
	if k == null or not k.is_alive():
		return
	var saving := k.tier < 2 and m.mission_time() >= 200.0 and not k.is_upgrading()   # the Stronghold first
	if k.tier < 2 and k.can_upgrade() == "":
		k.upgrade()
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= (250 if saving else 50):
		if k.queue_unit(UnitType.find("gloom_thrall")) == "" and node:
			k.set_rally_node(node)
	if workers.is_empty():
		return
	if eco.pop_cap - eco.pop_used < 6 and _hovel_i < HOVELS.size() and eco.crystals >= (280 if saving else 80):
		_build("shadow_hovel", HOVELS[_hovel_i], workers[0])
		_hovel_i += 1
	var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and b.building_type.id == &"shadow_barracks").size()
	if halls < 2 and eco.crystals >= 200 and m.mission_time() > 90.0:
		_build("shadow_barracks", HALL2, workers[0])
	elif halls < 3 and k.tier >= 2 and eco.crystals >= 200 and m.mission_time() > 330.0:
		_build("shadow_barracks", EXPANSION_HALL, workers[0])   # the drop-off by the west expansion
	if k.tier >= 2 and k.queue.size() < 2 and eco.crystals >= 150:
		var deacons := _all_soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"gloom_deacon").size()
		if deacons < 2:
			k.queue_unit(UnitType.find("gloom_deacon"))
	if saving and eco.crystals < 310:
		return   # save for the Stronghold
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"shadow_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 110:
			continue
		var want: String = ["shade", "nightbolt", "shade", "shadow_knight", "hexweaver", "nightbolt", "shade", "hollow_oathsworn"][_train_i % 8]
		if hall.queue_unit(UnitType.find(want)) != "":
			hall.queue_unit(UnitType.find("shade"))
		_train_i += 1
		hall.set_rally_point(RALLY if not m.has_fired(&"E7") else MissionE3_01.FORD_ZONE + Vector3(0.0, 0.0, -6.0))
	for u in _all_soldiers():
		var ca := u.get_node_or_null(^"CasterAbility")
		if ca and ca.has_method(&"set_autocast"):
			for sid: StringName in [&"blood_tithe"]:
				if not bool(ca.call(&"autocast", sid)):
					ca.call(&"set_autocast", sid, true)


func _guard_home() -> void:
	_home_guard = _home_guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _pushing and main.has_fired(&"E7"):
		_home_guard.clear()   # the ford is taken: everyone goes south
		return
	if _home_guard.size() < GUARDS and main.mission_time() > 45.0:
		for u in _all_soldiers():
			if _home_guard.size() >= GUARDS:
				break
			if not _home_guard.has(u) and u.unit_type.id != &"gloom_deacon":
				_home_guard.append(u)
	var foes := _enemies_near(HOME, 26.0)
	foes.append_array(_enemies_near(Vector3(-24.0, 0.0, -14.0), 10.0))
	for g: Variant in _home_guard:
		var u := g as Unit
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if not foes.is_empty():
			u.command_attack(foes[0])
		elif MissionBase._flat(u.global_position, HOME) > 8.0:
			u.command_attack_move(HOME)


# ---------------------------------------------------------------- the plan

## The enemy wizards (Ysolde, Vessa) near the army are its first target (the e2m5 rule for Malrik).
func _focus_wizard() -> bool:
	var army := _army()
	if army.is_empty():
		return false
	var c := Vector3.ZERO
	for u in army:
		c += u.global_position
	c /= float(army.size())
	for w: Variant in [main.ysolde, main.vessa]:
		if w == null or not is_instance_valid(w) or not (w as Wizard).is_alive():
			continue
		var wiz := w as Wizard
		if MissionBase._flat(wiz.global_position, c) <= 14.0 and not main.is_dormant(wiz) and not wiz.has_meta(Unit.TRUCE_META):
			for u in army:
				if u.attack_target != wiz and (u.attack_target == null or not (u.attack_target is Wizard)):
					u.command_attack(wiz)
			return true
	return false


func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.5:
		_retreat = true
	if _retreat:
		_hero_to(RALLY if not m.has_fired(&"E7") else Vector3(4.0, 0.0, -10.0), 3.0)
		if hero.hp >= hero.max_hp * 0.8:
			_retreat = false
	var army := _army()
	if not _pushing:
		_set_phase(&"build")
		var raid := _enemies_near(RALLY, 20.0)
		if not raid.is_empty():
			_army_to(raid[0].global_position, 3.0)
		else:
			_army_to(RALLY, 4.0)
		if not _retreat:
			_hero_to(RALLY + Vector3(0.0, 0.0, -4.0), 3.0)
		if m.mission_time() >= PUSH_AT or army.size() >= PUSH_ARMY:
			_pushing = true
		return
	if not m.has_fired(&"E7"):
		_set_phase(&"ford")
		if _focus_wizard():
			if not _retreat:
				_hero_to(BANK_HOLD + Vector3(0.0, 0.0, -5.0), 2.5)
			return
		for u in army:
			if u.global_position.z > 14.0:
				u.command_move(MissionE3_01.FORD_LANDING)   # never chase up the hill into the crest spires
		var zone := _enemies_near(MissionE3_01.FORD_ZONE, 12.0)
		var w3 := m.waves_fired.has(&"W3") and zone.size() >= 3
		if w3:
			# W3 comes to the ford: fight it from the north bank, out of the water (the ford slows everyone inside).
			var bank := _enemies_near(BANK_HOLD, 10.0)
			if not bank.is_empty():
				_army_to(bank[0].global_position, 3.0)
			else:
				for u in army:
					if u.attack_target == null and MissionBase._flat(u.global_position, BANK_HOLD) > 5.0:
						u.command_move(BANK_HOLD + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-2.0, 1.0)))
			if not _retreat:
				_hero_to(BANK_HOLD + Vector3(0.0, 0.0, -5.0), 2.5)
			return
		if not zone.is_empty():
			_army_to(zone[0].global_position, 3.0)
		else:
			_army_to(MissionE3_01.FORD_ZONE + Vector3(0.0, 0.0, 2.0), 3.0)
		if not _retreat:
			_hero_to(MissionE3_01.FORD_ZONE + Vector3(-1.0, 0.0, -3.0) if zone.size() <= 2 else BANK_HOLD + Vector3(0.0, 0.0, -4.0), 2.5)
		return
	if _focus_wizard():
		return
	if m.objective_state("obj_hold") != "active" and army.size() < REGROUP_ARMY and m.standards_owned(0) < 3:
		_set_phase(&"regroup")   # rebuild on the south landing before the next standard (the ford is ours for good)
		var near := _enemies_near(MissionE3_01.FORD_LANDING, 12.0)
		_army_to(near[0].global_position if not near.is_empty() else MissionE3_01.FORD_LANDING, 4.0)
		if not _retreat:
			_hero_to(MissionE3_01.FORD_ZONE + Vector3(0.0, 0.0, -2.0), 3.0)
		return
	# The standards: the next one in order not owned; then hold between the Clover Stone and the Standard.
	var target := &""
	for id in STANDARD_ORDER:
		if (m.standards[id] as MissionZone).owner_side != 0:
			target = id
			break
	var threatened := &""
	for id in STANDARD_ORDER:
		var z := m.standards[id] as MissionZone
		if z.owner_side == 0 and (z.capture_side == 1 or not _enemies_near(z.global_position, 8.0).is_empty()):
			threatened = id
			break
	if threatened != &"" and (target == &"" or m.objective_state("obj_hold") == "active"):
		target = threatened
	if target != &"":
		_set_phase(StringName("take_%s" % target) if m.objective_state("obj_hold") != "active" else &"hold")
		var at: Vector3 = (m.standards[target] as MissionZone).global_position
		var foes := _enemies_near(at, 12.0)
		_army_to(foes[0].global_position if not foes.is_empty() else at, 3.0)
		if not _retreat:
			_hero_to(at + Vector3(0.0, 0.0, -3.0) if foes.size() <= 3 else at + Vector3(0.0, 0.0, -9.0), 2.5)
		return
	_set_phase(&"hold")
	var foes2 := _enemies_near(HOLD_SPOT, 16.0)
	_army_to(foes2[0].global_position if not foes2.is_empty() else HOLD_SPOT, 4.0)
	if not _retreat:
		_hero_to(HOLD_SPOT + Vector3(0.0, 0.0, -5.0), 3.0)
