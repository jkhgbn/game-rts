extends SceneTree
## Mission e3m4 timing check (docs/design/mission-e3-04.md: a scripted normal run holds the ridge and breaks Old Vey's
## storm three times, `victory=true` in 24-30 game-minutes with cutscene lengths). Real fights: no hero protection, no
## kills or time skips by the test; cinematics off, the spec lengths of e3m4_return 0:20, e3m4_whisper 0:15 and
## e3m4_field 0:45 are added to the play time.
## The scripted player: Thralls to 11, Hovels, a second Gloom Hall, the Dread Paddock at 4:00 and Nightmare Knights,
## Shades / Nightbolts / Knights / Hexweavers; the army holds the Bishop's Crest and answers the watch point under attack
## (Torvald holds Birch Watch); whenever Vey fights, the army and the Knights go for him; the Thunderhead ring is left.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e3m4_sim.gd --fixed-fps 60 --quit-after 140000

const TASK_ID := "e3m4_sim"
const MISSION := "res://missions/mission_e3_04.tscn"
const CUTSCENE_SECONDS := {&"return": 20.0, &"whisper": 15.0, &"field": 45.0}
const RALLY := Vector3(-2.0, 0.0, -30.0)
const HOVELS: Array[Vector3] = [Vector3(-30.0, 0.0, -50.0), Vector3(-4.0, 0.0, -56.0), Vector3(-30.0, 0.0, -38.0),
		Vector3(8.0, 0.0, -56.0)]
const HALL2 := Vector3(-20.0, 0.0, -32.0)
const WORKERS := 11
const HOME := Vector3(-14.0, 0.0, -48.0)   ## between the two home nodes
const HOME_GUARDS := 5
const SPIRES: Array[Vector3] = [Vector3(-16.0, 0.0, -42.0), Vector3(-2.0, 0.0, -52.0)]

var verbose := false
var h := MissionHarness.new()
var main: MissionE3_04
var phase := &"build"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hovel_i := 0
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _sites: Array = []
var _wounded := {}
var _home_guard: Array = []
var _tower_i := 0
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID
	h.protect_hero = false
	h.timeout_frames = 135000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e3m4_sim_none.json"}}) as MissionE3_04
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
		var cine: float = CUTSCENE_SECONDS[&"return"] + (CUTSCENE_SECONDS[&"whisper"] if m.breaks >= 2 else 0.0) \
				+ (CUTSCENE_SECONDS[&"field"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); breaks %d / 3; assaults %d; knights %d (charge %s); watch %d / 3" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), m.breaks, m.assault, m.knights,
				"yes" if m.knight_charged else "no", m.watch_owned(0)])
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
		var owned := []
		for id: StringName in m.watch:
			owned.append((m.watch[id] as MissionZone).owner_side)
		print("    t=%s %s malrik %3.0f/%3.0f L%d | army %2d (w%d) | crystals %4d pop %d/%d | watch %s ridge %.0f | vey %s %s breaks %d | knights %d" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _workers().size(),
				eco.crystals, eco.pop_used, eco.pop_cap, str(owned), m.ridge_left, m.vey_state,
				"%.0f" % m.vey.hp if m.vey and is_instance_valid(m.vey) else "-", m.breaks, m.knights])
		if not killers.is_empty():
			print("      losses so far: %s" % str(killers))
	_economy()
	_lance()
	_guard_home()
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
		if not _home_guard.has(u):
			out.append(u)
	return out


## A home guard on the Thralls against the Blaze Rider raids (every 2:30 from 3:00): without it the raids emptied the
## mines by A3 and the economy never came back (a human keeps a few units home).
func _guard_home() -> void:
	_home_guard = _home_guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _home_guard.size() < HOME_GUARDS and main.mission_time() > 150.0:
		for u in _all_soldiers():
			if _home_guard.size() >= HOME_GUARDS:
				break
			if not _home_guard.has(u) and u.unit_type.id in [&"shadow_knight", &"hollow_oathsworn", &"nightbolt"]:
				_home_guard.append(u)
	var foes := _enemies_near(HOME, 24.0)
	for g: Variant in _home_guard:
		var u := g as Unit
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if not foes.is_empty():
			u.command_attack(foes[0])
		elif MissionBase._flat(u.global_position, HOME) > 6.0:
			u.command_attack_move(HOME + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))


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
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not main.is_dormant(u) and not u.has_meta(Unit.TRUCE_META) \
				and MissionBase._flat(u.global_position, at) <= r:
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
	if main.paddock and is_instance_valid(main.paddock) and main.paddock.is_alive() and not main.paddock.is_constructed() \
			and not _sites.any(func(r: Array) -> bool: return r[0] == main.paddock) and not workers.is_empty():
		_sites.append([main.paddock, workers[0]])
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
	var node: CrystalNode = m.node_of(0, "a")
	if node == null:
		node = m.node_of(0, "b")
	if node == null:
		for id: StringName in [&"e3_ridge_w", &"e3_reedfield"]:
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
	if roster and roster.state() == &"fallen" and roster.can_revive() == "":
		roster.revive()
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		if k.queue_unit(UnitType.find("gloom_thrall")) == "" and node:
			k.set_rally_node(node)
	if workers.is_empty():
		return
	if m.mission_time() >= MissionE3_04.PADDOCK_AT and (m.paddock == null or not is_instance_valid(m.paddock)) and eco.crystals >= 300:
		m.raise_paddock()
		return
	var pd := m.paddock as TrainingBuilding if m.paddock and is_instance_valid(m.paddock) else null
	var reserve := 0
	if pd and pd.is_constructed():
		if pd.queue.is_empty() and m.knights < 4 and eco.crystals >= 400:
			pd.queue_unit(pd.trainable_types()[0])
			pd.set_rally_point(RALLY)
		reserve = 400 if m.knights < 3 else 0
	elif m.mission_time() > 200.0 and m.paddock == null:
		reserve = 300
	if eco.pop_cap - eco.pop_used < 8 and _hovel_i < HOVELS.size() and eco.crystals >= 80:   # supply first (a 60/60 cap at A1 cost ~10 soldiers)
		_build("shadow_hovel", HOVELS[_hovel_i], workers[0])
		_hovel_i += 1
	var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and b.building_type.id == &"shadow_barracks").size()
	if halls < 2 and eco.crystals >= 200 + reserve and m.mission_time() > 60.0:
		_build("shadow_barracks", HALL2, workers[0])
	# Night Spires on the mines against the Blaze Rider raids (2:30 apart from 3:00; they killed 30 Thralls and guards
	# in a run without them).
	if _tower_i < SPIRES.size() and m.mission_time() > 150.0 and eco.crystals >= 120 + reserve:
		if _build("shadow_tower", SPIRES[_tower_i], workers[0]):
			_tower_i += 1
	if eco.crystals - reserve < 110:
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"shadow_barracks" \
				or hall.queue.size() >= 2:
			continue
		# Unit Guide counters to a Fireball line: Knights / Oathsworn (HP, armour) over 110-HP Shades, Hexweavers on the
		# heroes, Nightbolts for reach, Hounds to reach a caster.
		var want: String = ["shadow_knight", "nightbolt", "hollow_oathsworn", "hexweaver", "nightbolt", "shade", "grave_hound", "hollow_oathsworn"][_train_i % 8]
		if hall.queue_unit(UnitType.find(want)) != "":
			hall.queue_unit(UnitType.find("shade"))
		_train_i += 1
		hall.set_rally_point(RALLY)


## The human-like player (2026-10-07, SimTactics): the army stands in a loose line just south of the watch point
## (melee in front, ranged behind, 4.2 m apart: one Fireball catches 1-2 units, not a blob), never chases Vessa into
## her column, puts its ranged units and Hounds on her whenever she is within reach (Hexweavers "shut down heroes"),
## walks its wounded back behind the line, and only the melee + Knights go for Vey while he fights.
func _plan() -> void:
	var m := main
	var hero := m.hero
	# Malrik is the mission: Vessa or Vey within 16 m and hurt = Umbral Shroud and back to the keep.
	var danger := false
	for d: Variant in [m.vessa, m.vey]:
		if d != null and is_instance_valid(d) and (d as Unit).is_alive() and not m.is_dormant(d) \
				and MissionBase._flat((d as Unit).global_position, hero.global_position) <= 16.0:
			danger = true
	if danger and hero.hp < hero.max_hp * 0.75:
		hero.command_cast(&"umbral_shroud", null)
	if not _retreat and (hero.hp < hero.max_hp * 0.6 or danger and hero.hp < hero.max_hp * 0.85):
		_retreat = true
	var goal := _goal()
	if _retreat:
		_hero_to(MissionE3_04.DUSK_KEEP + Vector3(6.0, 0.0, 6.0), 3.0)
		if hero.hp >= hero.max_hp * 0.8:
			_retreat = false
	var army: Array = SimTactics.pull_back_wounded(_army(), goal + Vector3(0.0, 0.0, -14.0), _wounded, 0.5)
	# Thunderhead: leave its ring.
	var ring := m.thunder_ring()
	if ring != Vector3.INF:
		for u: Unit in army:
			if MissionBase._flat(u.global_position, ring) <= MissionE3_04.WATCH_R + 1.0:
				u.command_move(u.global_position + (u.global_position - ring).normalized() * 9.0)
	var ranged: Array = army.filter(func(u: Unit) -> bool: return SimTactics.is_ranged(u) or u.unit_type.id == &"grave_hound")
	var melee: Array = army.filter(func(u: Unit) -> bool: return not ranged.has(u))
	var vs := m.vessa
	var vessa_up := vs != null and is_instance_valid(vs) and vs.is_alive() and not m.is_dormant(vs)
	var vey_up := m.vey != null and is_instance_valid(m.vey) and m.vey_state == &"fighting" and (m.vey.global_position.z < 12.0 \
			and MissionBase._flat(m.vey.global_position, goal) <= 22.0   # at the line: chasing him south fed the riders
			or m.vey.hp < m.vey.max_hp * 0.35 and MissionBase._flat(m.vey.global_position, goal) <= 45.0)   # ...unless he is nearly broken
	var line := goal + Vector3(0.0, 0.0, 3.0)
	# Vessa within reach of the line: the ranged units and Hounds on her (never past the line + 12 m).
	var on_vessa: Unit = null
	if vessa_up and MissionBase._flat(vs.global_position, line) <= 16.0:
		on_vessa = SimTactics.focus_wizards(ranged, [vs], 16.0)
	if vey_up:
		_set_phase(&"storm%d" % (m.breaks + 1))
		for u: Unit in melee:
			if u.attack_target != m.vey:
				u.command_attack(m.vey)
		if on_vessa == null:
			for u: Unit in ranged:
				if u.attack_target != m.vey:
					u.command_attack(m.vey)
		if not _retreat:
			_hero_to(goal + Vector3(0.0, 0.0, -12.0), 3.0)
		return
	# A raid in the mines and no storm on the line: half the army goes home (the Thralls are the economy).
	var raid := _enemies_near(HOME, 26.0)
	if not raid.is_empty() and on_vessa == null:
		_set_phase(&"raid")
		var half := army.slice(0, maxi(4, army.size() / 2))
		for u: Unit in half:
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack(raid[0])
		army = army.slice(half.size())
		melee = melee.filter(func(u: Unit) -> bool: return army.has(u))
	_set_phase(&"vessa" if on_vessa else (&"hold" if raid.is_empty() else &"raid"))
	SimTactics.spread_to(melee if on_vessa else army, line, Vector3(0.0, 0.0, 1.0))
	SimTactics.unclump(army, [vs if vessa_up else null, m.vey])
	if not _retreat:
		_hero_to(goal + Vector3(0.0, 0.0, -10.0), 3.0)   # behind the line, out of Vessa's Fireball reach from it


## The watch point under threat (side 1 on it or capturing), else the Bishop's Crest.
func _goal() -> Vector3:
	var m := main
	for id: StringName in [&"W1", &"W2", &"W3"]:
		var z := m.watch[id] as MissionZone
		if z.owner_side != 0 or z.capture_side == 1 or not _enemies_near(z.global_position, 10.0).is_empty():
			if id == &"W3" and z.owner_side == 0 and m.torvald and m.torvald.is_alive():
				continue   # Torvald's post
			return z.global_position
	return MissionE3_04.WATCH[&"W1"][1]
