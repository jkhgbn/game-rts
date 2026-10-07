extends SceneTree
## Mission e2m5 timing check (docs/design/mission-e2-05.md acceptance check 9, the lead's scripted run): a headless run on
## normal with real fights (no hero protection, no kills or time skips by the test; cinematics off = their fallback end
## states, the spec lengths of e2m5_cavern 0:24, e2m5_wake 0:30, e2m5_answer 0:12 and e2m5_fall 0:20 are added to the
## reported play time). The scripted player kindles S then W with the army, holds the dais's south half (re-kindling
## what Malrik cracks), keeps a home guard on the workers, builds the Ember Stables, the Dragon Roost (8:00) and a Cinder
## Dragon, then at the wake fights the Doorwarden from the south rim: B2 the army goes for Malrik (the tether), B3 Vessa
## stands at the Door with Vey (the Sunlance). Must end `victory=true`; prints the phase times, the Door, the seals.
## `-- --seed N`, `-- --verbose`, `-- --noseals` (never kindles, never hunts Malrik: the Door should fall).
## Slow (25+ min of game). Run: godot --headless --path . -s tests/test_e2m5_sim.gd --fixed-fps 60 --quit-after 150000

const TASK_ID := "e2m5_sim"
const MISSION := "res://missions/mission_e2_05.tscn"
const CUTSCENE_SECONDS := {&"cavern": 24.0, &"wake": 30.0, &"answer": 12.0, &"fall": 20.0}
const HOME := Vector3(-48.0, 0.0, 50.0)
const STABLES_SPOT := Vector3(-62.0, 0.0, 36.0)
const HEARTHS: Array[Vector3] = [Vector3(-66.0, 0.0, 56.0), Vector3(-66.0, 0.0, 50.0), Vector3(-58.0, 0.0, 70.0),
		Vector3(-52.0, 0.0, 70.0), Vector3(-66.0, 0.0, 44.0)]
const WORKERS := 12
const EXTRA_HALLS: Array[Vector3] = [Vector3(-30.0, 0.0, 50.0), Vector3(-30.0, 0.0, 60.0)]
const GUARDS := 8
const TOWERS: Array[Vector3] = [Vector3(-50.0, 0.0, 40.0), Vector3(-36.0, 0.0, 66.0)]
const DAIS_HOLD := Vector3(-8.0, 0.0, 22.0)   ## South of the dais rim (the host leashes on the dais).
const REGROUP := Vector3(-6.0, 0.0, 20.0)      ## Off the dais, south: where the army waits out the wake.
const SAFE := Vector3(-12.0, 0.0, 28.0)        ## Off the dais and the sunstones' south road: the army's wait spot.
const BOSS_LINE := Vector3(0.0, 0.0, 8.5)

var verbose := false
var noseals := false
var h := MissionHarness.new()
var main: MissionE2_05
var phase := &"seals"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hearth_i := 0
var _train_i := 0
var _tower_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _home_guard: Array = []
var _sites: Array = []
var _door_min := 100.0
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	noseals = args.has("--noseals")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("/noseals" if noseals else "")
	h.protect_hero = false
	h.timeout_frames = 145000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m5_sim_none.json"}}) as MissionE2_05
	h.steps.add("play", _play, 144000)
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
		who = String((kt as UnitType).id) if kt != null else "%s(t%d)" % [(k as Node).name,
				int((k as Object).get(&"team")) if (k as Object).get(&"team") != null else -1]
		if k is Wizard:
			who = "wizard:%s(t%d)" % [(k as Wizard).unit_name, int((k as Wizard).team)]
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
	if m.woke and m.door and is_instance_valid(m.door):
		_door_min = minf(_door_min, 100.0 * m.door.hp / maxf(1.0, m.door.max_hp))
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"cavern"] + (CUTSCENE_SECONDS[&"wake"] if m.woke else 0.0) \
				+ (CUTSCENE_SECONDS[&"answer"] if m.boss_phase >= 3 else 0.0) + (CUTSCENE_SECONDS[&"fall"] if h.ended == 1 else 0.0)
		var door_pct := 100.0 * m.door.hp / maxf(1.0, m.door.max_hp) if m.door and is_instance_valid(m.door) else 0.0
		print("  %s at mission time %s (play time with cutscenes %s); wake %s; Door %d %% (min %d %%, Hold %s); lances %d; dragons %d" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), _mmss(m.wake_time), int(door_pct),
				int(_door_min), "yes" if m.door_held else "no", m.lances, m.dragons])
		print("  phases %s; seals at the wake %s; waves %s; spotlight %s" % [", ".join(_phase_log), str(m.seals),
				",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Fire losses by killer: %s" % str(killers))
		if noseals:
			print("  noseals run: %s (the spec expects the Door to fall in 3 / 5)" % ("Door fell" if h.ended == 0 else "held"))
		else:
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
		print("    t=%s %s vessa %3.0f/%3.0f L%d | army %2d (w%d) | crystals %4d pop %d/%d | wake %3.0f seals %s | boss %s %s | door %s | dragons %d" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _workers().size(),
				eco.crystals, eco.pop_used, eco.pop_cap, m.wake, str(m.seals.values()), m.boss_phase,
				"%.0f" % m.boss.hp if m.boss and is_instance_valid(m.boss) else "-",
				"%.0f" % m.door.hp if m.door and is_instance_valid(m.door) else "-", m.dragons])
		if verbose and not killers.is_empty():
			print("      losses so far: %s" % str(killers))
		if verbose and m.boss and is_instance_valid(m.boss) and m.woke:
			var bt: Variant = m.boss.attack_target
			print("      boss at %s target %s door dist %.1f tether %s exposed %.0f lances %d" % [m.boss.global_position,
					(bt as Node).name if bt != null and is_instance_valid(bt) else "-", MissionBase._flat(m.boss.global_position,
					Vector3.ZERO), m.tether_on, m.exposed_left, m.lances])
		var mk := m.shadow_hero
		if verbose and mk and is_instance_valid(mk):
			var inv: Variant = ItemDrops.inventory_of(mk)
			var items: Array = []
			if inv != null:
				for e: Variant in inv.get(&"slots"):
					if e is Dictionary and e.get("type") != null:
						items.append(String((e["type"] as ItemType).id) if e["type"] is ItemType else str(e["type"]))
			print("      malrik L%d hp %d/%d sp %.0f dmg %.0f armor %.0f items %s at %s" % [mk.level, mk.hp, mk.max_hp,
					mk.get_stat(&"spell_power"), mk.get_stat(&"attack_damage"), mk.get_stat(&"armor"), items, mk.global_position])
	_learn()
	_economy()
	_fireball()
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
				and not main.is_dormant(u) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	return out


func _army_to(at: Vector3, spread := 4.0) -> void:
	for u in _army():
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if MissionBase._flat(u.global_position, at) > spread + 2.0:
			u.command_attack_move(at + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread)))


func _army_attack(target: Unit, all := false) -> void:
	for u in _army():
		if u.attack_target == target:
			continue
		if not all and u.attack_target != null and is_instance_valid(u.attack_target) and u.attack_target is Unit \
				and (u.attack_target as Unit).is_alive() and MissionBase._flat(u.global_position, (u.attack_target as Unit).global_position) < 5.0:
			continue
		u.command_attack(target)


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _learn() -> void:
	var w := main.hero as Wizard
	for i in 3:
		if w.spell_points <= 0:
			return
		for id: StringName in [&"fireball", &"kindle", &"ember_step"]:
			if w.learn_spell(id) == "":
				break


func _fireball() -> void:
	var hero := main.hero
	var foes := _enemies_near(hero.global_position, 11.0)
	var best: Unit = null
	var best_n := 0
	for u in foes:
		var n := 0
		for o in foes:
			if MissionBase._flat(o.global_position, u.global_position) <= 3.0:
				n += 1
		if u == main.boss:
			n += 2
		if n > best_n:
			best_n = n
			best = u
	if best and (best_n >= 2 or hero.mana > hero.max_mana * 0.6):
		hero.command_cast(&"fireball", best.global_position)


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
	if main.roost and is_instance_valid(main.roost) and main.roost.is_alive() and not main.roost.is_constructed() \
			and not _sites.any(func(r: Array) -> bool: return r[0] == main.roost) and not workers.is_empty():
		_sites.append([main.roost, workers[0]])
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


func _has_kind(kind: StringName, built_only := false) -> Building:
	for b in Building.for_team(0):
		if b.is_alive() and b.building_type and b.building_type.kind == kind and (not built_only or b.is_constructed()):
			return b
	return null


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var m := main
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var node: CrystalNode = null
	for suffix in ["a", "b", "mid", "seep"]:
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
	if workers.size() < WORKERS and k.queue.size() < 2 and eco.crystals >= 60:
		if k.queue_unit(UnitType.find("cinder_hand")) == "" and node:
			k.set_rally_node(node)
	var roster := HelperRoster.for_team(0)
	if roster and roster.state() == &"fallen" and roster.can_revive() == "":
		roster.revive()
	if workers.is_empty():
		return
	if _has_kind(&"stables") == null and eco.crystals >= 175 and m.mission_time() > 180.0:
		if not _build("fire_stables", STABLES_SPOT, workers[0]) and verbose:
			print("      stables refused near %s" % STABLES_SPOT)
	if m.mission_time() >= MissionE2_05.ROOST_AT and (m.roost == null or not is_instance_valid(m.roost)) \
			and _has_kind(&"stables", true) != null and eco.crystals >= MissionE2_05.ROOST_COST:
		var rwhy := m.raise_roost()
		if rwhy != "" and verbose:
			print("      roost refused: %s" % rwhy)
	var roost := m.roost as TrainingBuilding if m.roost and is_instance_valid(m.roost) else null
	if roost and roost.is_constructed() and roost.queue.is_empty() and m.dragons < 1 and eco.crystals >= 700:
		roost.queue_unit(roost.trainable_types()[0])
	if eco.pop_cap - eco.pop_used < 6 and eco.pop_cap < 100 and _hearth_i < HEARTHS.size() and eco.crystals >= 100:
		_build("fire_hearth", HEARTHS[_hearth_i], workers[0])
		_hearth_i += 1
	var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type 			and b.building_type.id == &"fire_barracks").size()
	if halls < 2 and eco.crystals >= 400 and m.mission_time() > 60.0:
		_build("fire_barracks", EXTRA_HALLS[0], workers[0])
	var towers := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type 			and b.building_type.id == &"fire_tower").size()
	if towers < 1 + TOWERS.size() and _tower_i < TOWERS.size() and eco.crystals >= 160 and m.mission_time() > 120.0:
		_build("fire_tower", TOWERS[_tower_i], workers[0])   # home defence against the raids (W1, Hush, W3)
		_tower_i += 1
	var reserve := 0
	if m.roost and is_instance_valid(m.roost) and m.dragons < 1:
		reserve = 700
	elif m.mission_time() > 390.0 and m.roost == null:
		reserve = 300
	if eco.crystals - reserve < 120:
		return
	if verbose and int(m.mission_time()) % 30 < 2:
		for b in Building.for_team(Unit.Team.PLAYER):
			if b is TrainingBuilding:
				print("      %s %s built %s queue %d progress %.2f" % [b.name, b.building_type.id, b.is_constructed(), (b as TrainingBuilding).queue.size(), (b as TrainingBuilding).train_progress()])
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"fire_barracks" \
				or hall.queue.size() >= 2:
			continue
		var want: String = ["flame_guard", "ember_archer", "flame_guard", "pyre_adept", "ember_archer", "cinder_arbalest"][_train_i % 6]
		var why := hall.queue_unit(UnitType.find(want))
		if why != "" and verbose and _train_i % 20 == 0:
			print("      hall refused %s: %s" % [want, why])
		_train_i += 1
		hall.set_rally_point(MissionE2_05.RALLY)


func _guard_home() -> void:
	_home_guard = _home_guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _home_guard.size() < GUARDS and main.mission_time() > 60.0:
		for u in _all_soldiers():
			if _home_guard.size() >= GUARDS:
				break
			if not _home_guard.has(u) and not u.unit_type.id == &"cinder_dragon":
				_home_guard.append(u)
	var foes := _enemies_near(HOME, 24.0)
	for g: Variant in _home_guard:
		var u := g as Unit
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if not foes.is_empty():
			u.command_attack(foes[0])
		elif MissionBase._flat(u.global_position, HOME) > 8.0:
			u.command_attack_move(HOME)


# ---------------------------------------------------------------- the plan

func _seal_to_kindle() -> StringName:
	if noseals:
		return &""
	for id: StringName in [&"S", &"W"]:
		if main.seals[id] != &"gold":
			return id
	return &""


func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.3:
		_retreat = true
	if _retreat:
		_hero_to(MissionE2_05.RALLY, 3.0)
		if hero.hp >= hero.max_hp * 0.75:
			_retreat = false
	if not m.woke:
		_plan_seals()
		return
	var boss := m.boss
	if boss == null or not is_instance_valid(boss) or not boss.is_alive():
		return
	# The wake push and the amber Wardens first (south of the Door, then around the boss), then the boss.
	var adds := _enemies_near(Vector3(0.0, 0.0, 10.0), 14.0).filter(func(u: Unit) -> bool: return u != boss)
	if adds.size() < 3:
		adds = _enemies_near(boss.global_position, 12.0).filter(func(u: Unit) -> bool: return u != boss)
	if m.boss_phase == 2 and not noseals and m.tether_on and m.shadow_hero and m.shadow_hero.is_alive():
		_set_phase(&"tether")
		for u in _army():
			if u.attack_target != m.shadow_hero:
				u.command_attack(m.shadow_hero)   # the whole army on Malrik: the tether breaks the moment he dies
		if not _retreat:
			_hero_to(BOSS_LINE + Vector3(-4.0, 0.0, 4.0), 3.0)
		return
	_set_phase(&"boss%d" % m.boss_phase)
	if adds.size() >= 3:
		_army_to(adds[0].global_position, 3.0)
	elif m.mission_time() - m.wake_time < 35.0:
		_army_to(REGROUP, 4.0)   # the wake: stand off the dais until the push arrives
	else:
		_army_attack(boss)
	if _retreat:
		return
	if m.boss_phase == 3:
		_hero_to(MissionE2_05.SOUTH_RIM + Vector3(0.0, 0.0, 1.5), 1.5)
		if m.vey and is_instance_valid(m.vey) and m.vey.is_alive() and m.vey.attack_target == null 				and MissionBase._flat(m.vey.global_position, hero.global_position) > 6.0:
			m.vey.command_move(hero.global_position + Vector3(2.0, 0.0, 1.0))
	elif m.mission_time() - m.wake_time < 35.0:
		_hero_to(REGROUP + Vector3(0.0, 0.0, 4.0), 3.0)
	else:
		_hero_to(BOSS_LINE + Vector3(0.0, 0.0, 4.0), 3.0)


## Phase 1, the careful player: kindle S then W only while Malrik is off the dais, Torvald's cover is not running and
## at most one enemy stands on the seal; otherwise the army waits off the dais (SAFE) and fights only what comes to it.
## The army is kept whole for the wake (the boss is the test); it regroups south of the Door just before the wake.
func _plan_seals() -> void:
	var m := main
	_set_phase(&"seals")
	var near_wake := m.wake >= 94.0 and m.mission_time() >= MissionE2_05.WAKE_FLOOR - 20.0 			or m.mission_time() >= float(m.by_difficulty(MissionE2_05.WAKE_CAP)) - 15.0
	if near_wake:
		_army_to(REGROUP, 4.0)
		if not _retreat:
			_hero_to(REGROUP + Vector3(0.0, 0.0, 4.0), 3.0)
		return
	var id := _seal_to_kindle()
	var mk := m.shadow_hero
	if id != &"":
		var at: Vector3 = MissionE2_05.SEALS[id]
		var malrik_near := mk != null and mk.is_alive() and MissionBase._flat(mk.global_position, at) <= 22.0
		if m.cover_active or malrik_near or _enemies_near(at, 10.0).size() > 1 or _army().size() < 10 and m.mission_time() > 60.0:
			id = &""
	var goal: Vector3 = SAFE if id == &"" else MissionE2_05.SEALS[id]
	var foes := _enemies_near(goal, 14.0).filter(func(u: Unit) -> bool: return u.global_position.z > 2.0)
	for u in _army():
		if u.global_position.z < 0.0 and (u.attack_target == null or not is_instance_valid(u.attack_target) 				or (u.attack_target as Node3D).global_position.z < 0.0):
			u.command_move(goal + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(0.0, 4.0)))   # never chase north
	if not foes.is_empty():
		_army_to(foes[0].global_position, 3.0)
	else:
		_army_to(goal + Vector3(0.0, 0.0, 3.0), 4.0)
	if _retreat:
		return
	if id != &"":
		_hero_to(goal + Vector3(0.0, 0.0, 1.0), 1.0)
	else:
		_hero_to(SAFE + Vector3(0.0, 0.0, 5.0), 3.0)
