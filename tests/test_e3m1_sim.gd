extends SceneTree
## Mission e3m1 timing check (docs/design/mission-e3-01.md "Lead" check: a scripted headless run on normal takes the
## ford, the 3 standards and holds them, `victory=true` in 22-28 game-minutes; the W3 fight leaves Malrik alive). Real
## fights: no hero protection, no kills or time skips by the test; cinematics off (their fallback end states), the spec
## lengths of e3m1_ford 0:12, e3m1_standard 0:10 and e3m1_dusk 0:30 are added to the reported play time.
## The scripted player: Thralls to 11, Hovels, a second Gloom Hall, the Stronghold at 3:30, Shades / Nightbolts /
## Knights / Hexweavers and 2 Gloom Deacons (autocast); a home guard on the workers until the ford push; the push at
## ~9:00 (or 20 soldiers): the north bank first, then the ford; then Ysolde's Standard, Lark Well, the Clover Stone; the
## hold from between the Clover Stone and the Standard (the army answers any standard under attack).
## 2026-10-13 (CI: the ford at ~20:38, then a timeout): the Halls save for the mix (a Knight / Oathsworn / Hexweaver it
## cannot afford yet is waited for, not swapped for a Shade); a beaten ford push falls back to the rally and rebuilds;
## push / regroup sizes count soldier pop; the third standard (the Final) is only taken with a full army.
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
const PUSH_EARLIEST := 540.0   ## never before 9:00 (the Stronghold units in the army), even with 36 Shades
const EXPANSION_HALL := Vector3(-41.0, 0.0, -36.0)   ## The west expansion's hall spot (a drop-off by e3_ridge_w).
const BANK_HOLD := Vector3(4.0, 0.0, -8.5)   ## North bank, out of the ford: where the army meets W3 (spec answer).
const STANDARD_ORDER: Array[StringName] = [&"std_well", &"std_clover", &"std_ysolde"]   ## the one between the crest spires last
const REGROUP_ARMY := 24   ## after the ford: under this soldier pop (_strength), rebuild...
const REGROUP_LEAVE := 30  ## ...to this before the next standard
const LATE_GO := 1560.0    ## from 26:00 the last standard is taken with whatever the army is (the run's clock)
const FORD_FALLBACK := 14   ## before the ford is ours: under this soldier pop the push falls back to the rally...
const FORD_REPUSH := 36     ## ...and goes again at this much (or at the pop cap)
const SHOP_LIST: Array[StringName] = [&"vital_root", &"ironbark_plate", &"vital_root", &"warden_scale"]   ## +HP / armour
const CREST_Z := 23.0       ## after the ford: soldiers past this z are called back (the crest spires' reach)
const BANK_EDGE := Vector3(4.0, 0.0, -6.0)   ## the north bank's edge by the Stone Ford (the water starts at ~z -4.5)
const BANK_TIME := 45.0     ## each push fights from the bank this long before it crosses
const REGROUP_SPOT := Vector3(4.0, 0.0, -12.0)   ## north of the Stone Ford

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
var _wounded := {}
var _regrouping := false
var _ford_rebuild := false
var _bank_until := 0.0
var _shop_i := 0
var _fighting: Array = []   ## the army minus the wounded walking back (this tick)
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
		if phase == &"ford" or phase == &"ford_regroup" or phase == &"build" and m.mission_time() > 540.0:
			var seen := {}
			for u in _enemies_near(MissionE3_01.FORD_ZONE, 24.0):
				var key: String = String(u.unit_type.id) if u.unit_type else String(u.name)
				seen[key] = int(seen.get(key, 0)) + 1
			var mine := {}
			for u in _army():
				var key: String = String(u.unit_type.id)
				mine[key] = int(mine.get(key, 0)) + 1
			print("      near the ford: %s | army %s" % [str(seen), str(mine)])
			for wz: Variant in [m.ysolde, m.vessa]:
				if wz != null and is_instance_valid(wz):
					var wu := wz as Unit
					print("      %s hp %d/%d at %s alive %s dormant %s" % [wu.name, int(wu.hp), int(wu.max_hp), str(wu.global_position.round()),
							str(wu.is_alive()), str(m.is_dormant(wu))])
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


## After the ford: a loose line at `at` facing the way the army walks (SimTactics: 4.2 m apart, melee in front, ranged
## behind), never the old random +-4 m pile that one Thornburst / Fireball emptied. Before it: the old push (`spread`).
func _army_to(at: Vector3, spread := 4.0) -> void:
	var army: Array = _fighting
	if not main.has_fired(&"E7"):
		# The ford: one push together (a loose line trickled into the ford's slow water and lost 30 of 40 to the Nature
		# line's Burr Slinger splash); the loose line is for the standards and the hold, where the wizards' AoE lands.
		for v: Variant in army:
			var u := v as Unit
			if u.attack_target != null and is_instance_valid(u.attack_target):
				continue
			if MissionBase._flat(u.global_position, at) > spread + 2.0:
				u.command_attack_move(at + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread)))
		return
	var c := SimTactics.centroid(army)
	if c == Vector3.INF:
		return
	SimTactics.spread_to(army, at, at - c if MissionBase._flat(at, c) > 3.0 else Vector3(0.0, 0.0, 1.0))


## True when the player cannot train more (pop cap reached, no room for one more soldier).
## The army's size in population (a 3-pop Shadow Knight counts 3): the push / regroup thresholds read this, so a mixed
## army with Knights and Oathsworn is not held back as "small".
func _strength(units: Array) -> int:
	var n := 0
	for v: Variant in units:
		var u := v as Unit
		n += u.unit_type.pop if u.unit_type else 1
	return n


func _pop_capped() -> bool:
	var eco := Economy.for_team(Unit.Team.PLAYER)
	return eco != null and eco.pop_cap > 0 and eco.pop_used >= eco.pop_cap - 1


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
	var ridge_hall := Building.for_team(0).any(func(b: Building) -> bool: return b.is_alive() and b.is_constructed() \
			and b.building_type.id == &"shadow_barracks" and MissionBase._flat(b.global_position, EXPANSION_HALL) < 8.0)
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
	if k.tier >= 2 and k.queue.size() < 2 and eco.crystals >= 120:
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
		# Unit Guide picks: Knights and Oathsworn (HP, armour) in the Shade front line, Hexweavers on the heroes,
		# Nightbolts for reach (a Nightbolt-heavy army fed the Burr Slingers' splash at the ford).
		var want: String = ["shade", "nightbolt", "shadow_knight", "shade", "hollow_oathsworn", "hexweaver", "shade", "nightbolt"][_train_i % 8]
		var want_t := UnitType.find(want)
		if not eco.can_afford(want_t.cost):
			break   # save for it: buying a Shade instead every time left a 28-Shade army (no Knight / Oathsworn / Hexweaver)
		if hall.queue_unit(want_t) != "":
			hall.queue_unit(UnitType.find("shade"))   # locked (before the Stronghold)
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

## The enemy wizards (Ysolde, Vessa) near the army: its ranged units, Hexweavers and Hounds go for her (Unit Guide:
## "shuts down heroes", "reaches casters"); the melee keep their line and only join when she is within 8 m of them.
## Returns true while a wizard is focused (the melee still follow the plan).
func _focus_wizard() -> bool:
	var army := _fighting
	if army.is_empty():
		return false
	var ranged: Array = army.filter(func(u: Unit) -> bool: return SimTactics.is_ranged(u) or u.unit_type.id == &"grave_hound")
	var awake := func(w: Unit) -> bool: return not main.is_dormant(w)
	var w := SimTactics.focus_wizards(ranged, [main.ysolde, main.vessa], 15.0, awake)
	if w == null:
		return false
	for u: Unit in army:
		if not ranged.has(u) and u.attack_target != w and MissionBase._flat(u.global_position, w.global_position) <= 8.0:
			u.command_attack(w)
	return true


## Before the push Malrik spends his essence (400 at the start, +1 / s) at the Dusk Keep's shop on HP and armour, as a
## player would (his death is the mission). True while he is on that trip (`quiet` = no raid at the rally).
func _shop(quiet: bool) -> bool:
	var inv: Variant = main.hero.get(&"inventory")
	if inv == null or _shop_i >= SHOP_LIST.size() or not quiet:
		return false
	var it := ItemType.find(SHOP_LIST[_shop_i])
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	if it == null or bank == null or bank.essence < it.total_cost():
		return false
	_hero_to(MissionE3_01.DUSK_KEEP + Vector3(0.0, 0.0, 8.0), 2.5)
	var why: String = inv.call(&"buy", it)
	if why == "":
		_shop_i += 1
	elif why != "No shop nearby":
		_shop_i += 1   # cannot be bought here (full, not sold): the next one
	return true


func _plan() -> void:
	var m := main
	var hero := m.hero
	# Past the ford both enemy wizards (L5 in the Final) reach him: he steps back earlier (his death ends the mission).
	if not _retreat and hero.hp < hero.max_hp * (0.6 if m.has_fired(&"E7") else 0.5):
		_retreat = true
	if _retreat:
		_hero_to(RALLY if not m.has_fired(&"E7") else Vector3(4.0, 0.0, -10.0), 3.0)
		if hero.hp >= hero.max_hp * 0.8:
			_retreat = false
	# The wounded (under 30 %) walk back behind the line: to the rally, north of the river once the ford is ours.
	var safe := RALLY if not m.has_fired(&"E7") else Vector3(4.0, 0.0, -12.0)
	_fighting = SimTactics.pull_back_wounded(_army(), safe, _wounded, 0.5)
	var army: Array = _fighting
	if not _pushing:
		_set_phase(&"build")
		_focus_wizard()   # W2: Vessa's raid (her Fireballs took 10 of the waiting army)
		var raid := _enemies_near(RALLY, 20.0)
		if not raid.is_empty():
			_army_to(raid[0].global_position, 3.0)
		else:
			_army_to(RALLY, 4.0)
		if not _retreat and not _shop(raid.is_empty()):
			_hero_to(RALLY + Vector3(0.0, 0.0, -4.0), 3.0)
		if m.mission_time() >= PUSH_AT or army.size() >= PUSH_ARMY and m.mission_time() >= PUSH_EARLIEST:
			_pushing = true
		return
	if not m.has_fired(&"E7"):
		# A beaten push falls back behind the rally and rebuilds instead of feeding new trainees into the ford one by one
		# (the CI run trickled in for ten minutes and took the ford at ~20:38).
		var ford_strength := _strength(army)
		if ford_strength < FORD_FALLBACK:
			_ford_rebuild = true
		elif ford_strength >= FORD_REPUSH or (ford_strength >= FORD_FALLBACK + 8 and _pop_capped()):
			_ford_rebuild = false
		if _ford_rebuild:
			_set_phase(&"ford_regroup")
			var raid := _enemies_near(RALLY, 20.0)
			if not raid.is_empty():
				_army_to(raid[0].global_position, 3.0)
			else:
				for u: Unit in army:   # a real retreat (move, not attack-move): the ford fight is left behind
					if MissionBase._flat(u.global_position, RALLY) > 10.0 and not u.has_move_order():
						u.command_move(RALLY + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
			_hero_to(RALLY + Vector3(0.0, 0.0, -4.0), 3.0)
			return
		if phase != &"ford":
			_bank_until = m.mission_time() + BANK_TIME   # a new push: the bank fight first
		_set_phase(&"ford")
		_focus_wizard()
		for u: Unit in army:
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
		if zone.size() >= 4 and m.mission_time() < _bank_until:
			# The horn relief stands IN the ford (its order is the ford zone): a loose line on the north bank's edge
			# fights it from dry ground first (spec: "win the fight on the bank, then cross"); walking into the slow water
			# onto 25 defenders lost 20 of 36 in 30 s.
			SimTactics.spread_to(army, BANK_EDGE, Vector3(0.0, 0.0, 1.0))
			if not _retreat:
				_hero_to(BANK_HOLD + Vector3(0.0, 0.0, -4.0), 2.5)
			return
		if not zone.is_empty():
			_army_to(zone[0].global_position, 3.0)
		else:
			_army_to(MissionE3_01.FORD_ZONE + Vector3(0.0, 0.0, 2.0), 3.0)
		if not _retreat:
			_hero_to(MissionE3_01.FORD_ZONE + Vector3(-1.0, 0.0, -3.0) if zone.size() <= 2 else BANK_HOLD + Vector3(0.0, 0.0, -4.0), 2.5)
		return
	_focus_wizard()
	for u: Unit in army:
		if u.global_position.z > CREST_Z:   # a chase up the hill walks into the crest towers (range 10-11 from z 30-34)
			u.command_move(Vector3(u.global_position.x, 0.0, 16.0))
	var strength := _strength(army)
	var now := m.mission_time()
	# Waiting cannot grow the army at the pop cap, with no crystals left (campaign notes 2026-10-11), or past LATE_GO.
	var no_income := Economy.for_team(0).crystals < 110 and not [&"e3_dusk_a", &"e3_dusk_b", &"e3_ridge_w", &"e3_reedfield"].any(
			func(id: StringName) -> bool:
				var v: Variant = m.crystal_nodes.get(id)
				return v != null and is_instance_valid(v) and not (v as CrystalNode).is_depleted())
	var cannot_grow := _pop_capped() or no_income or now >= LATE_GO
	if strength < REGROUP_ARMY:
		_regrouping = true
	if _regrouping and (strength >= REGROUP_LEAVE or (cannot_grow and (strength >= REGROUP_ARMY - 6 or now >= LATE_GO))):
		_regrouping = false
	# The last standard starts the hold and the Final (both wizards at L5 + 24 soldiers): only with a full army.
	var hold_gate := m.standards_owned(0) == 2 and strength < REGROUP_LEAVE and not cannot_grow
	if m.objective_state("obj_hold") != "active" and (_regrouping or hold_gate) and m.standards_owned(0) < 3:
		# Rebuild behind the river before the next standard (the ford is ours for good): whatever comes has to wade the
		# ford's slow water into the line (on the south landing W4 and the crest caught a half-built army in the open).
		_set_phase(&"regroup")
		var near := _enemies_near(REGROUP_SPOT, 12.0)
		_army_to(near[0].global_position if not near.is_empty() else REGROUP_SPOT, 4.0)
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
			_hero_to(at + Vector3(0.0, 0.0, -3.0) if foes.size() <= 3 and m.objective_state("obj_hold") != "active" else at + Vector3(0.0, 0.0, -9.0), 2.5)
		return
	_set_phase(&"hold")
	var foes2 := _enemies_near(HOLD_SPOT, 16.0)
	_army_to(foes2[0].global_position if not foes2.is_empty() else HOLD_SPOT, 4.0)
	if not _retreat:
		_hero_to(HOLD_SPOT + Vector3(0.0, 0.0, -9.0), 3.0)
