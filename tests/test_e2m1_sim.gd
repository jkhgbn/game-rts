extends SceneTree
## Mission e2m1 timing check (docs/design/mission-e2-01.md "Done when", the lead's scripted run): a headless run on
## normal with real fights (no hero protection, no kills or time skips by the test; cinematics off = their fallback end
## states, the spec lengths of e2m1_arrival 0:20, e2m1_frostwarden 0:12 and e2m1_ysolde 0:30 are added to the reported
## play time). The scripted player trains from its own economy, clears G1, frees Fernhollow (S1), breaks the glade
## siege (G2, then the three Rime Totems: the frost stops), frees the Charred Glade (S2) while the frost is stopped,
## kindles the Heartwood, raises the Citadel and calls Old Vey, and holds the glade for the 12:00 countdown. Must end
## `victory=true`; prints the phase times and the survivors brought home.
## `-- --novey`: never raises the Citadel nor calls Old Vey (the spec's "a run with no Citadel and no Vey still wins").
## `-- --seed N`: the run's random seed. `-- --verbose`: state every 30 s. Slow (18+ min of game).
## Run:  godot --headless --path . -s tests/test_e2m1_sim.gd --fixed-fps 60 --quit-after 120000 [-- --novey]

const TASK_ID := "e2m1_sim"
const MISSION := "res://missions/mission_e2_01.tscn"
const HOME := Vector3(-36.0, 0.0, 36.0)
const CUTSCENE_SECONDS := {&"arrival": 20.0, &"frostwarden": 12.0, &"ysolde": 30.0}
const HOLD_POS := Vector3(0.0, 0.0, 12.0)       ## The army's spot in the glade (the tree at (0, 9), the Oldroot north).
const VESSA_HOLD := Vector3(0.0, 0.0, 15.0)     ## Vessa just south of the Heartwood.
const WORKERS := 12
const HEARTHS: Array[Vector3] = [Vector3(-48.0, 0.0, 50.0), Vector3(-42.0, 0.0, 52.0), Vector3(-54.0, 0.0, 40.0),
		Vector3(-30.0, 0.0, 53.0), Vector3(-54.0, 0.0, 34.0)]
const HOME_HALLS: Array[Vector3] = [Vector3(-20.0, 0.0, 44.0), Vector3(-28.0, 0.0, 38.0)]
const G2_ARMY := 16          ## Go for the glade with this many soldiers (or at 3:30).
const G2_LATEST := 210.0

var novey := false
var verbose := false
var h := MissionHarness.new()
var main: MissionE2_01
var phase := &"g1"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hearth_i := 0
var _train_i := 0
var _hall2 := false
var _phase_log: Array[String] = []
var _retreat := false
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	novey = args.has("--novey")
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("/novey" if novey else "/vey")
	h.protect_hero = false
	h.timeout_frames = 110000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m1_sim_none.json"}}) as MissionE2_01
	h.steps.add("play", _play, 109000)
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
		var cine: float = CUTSCENE_SECONDS[&"arrival"] + CUTSCENE_SECONDS[&"frostwarden"] \
				+ (CUTSCENE_SECONDS[&"ysolde"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); kindle %s; folk home %d (dead %d); Vey %s; frost %.0f %%" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), _mmss(m.kindle_time), m.folk_home,
				m.folk_dead, "yes" if m.vey_arrived else "no", m.frost])
		print("  phases %s; spotlight %s (first unit %s); waves %s" % [", ".join(_phase_log), h.spotlight_log,
				m.spotlight_unit != null, ",".join(m.waves_fired)])
		print("  Fire losses by killer: %s" % str(killers))
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
		print("    t=%s %s vessa %3.0f/%3.0f L%d | army %2d (w%d) | crystals %4d | frost %4.1f | tree %s | hold %s | waves %s" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _workers().size(),
				Economy.for_team(Unit.Team.PLAYER).crystals, m.frost,
				"%d" % int(m.heartwood.hp) if m.kindled and m.heartwood.is_alive() else "-", _mmss(m.hold_left),
				",".join(m.waves_fired)])
	_learn()
	_economy()
	_fireball()
	_plan()
	return false


# ---------------------------------------------------------------- helpers

func _army() -> Array[Unit]:
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


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not main.is_dormant(u) \
				and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	return out


func _army_to(at: Vector3, spread := 4.0) -> void:
	for u in _army():
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if MissionBase._flat(u.global_position, at) > spread + 2.0:
			u.command_attack_move(at + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread)))


func _army_attack(target: Node3D) -> void:
	for u in _army():
		if u.attack_target == target:
			continue
		if u.attack_target != null and is_instance_valid(u.attack_target) and u.attack_target is Unit:
			continue   # finish the unit it is on
		u.command_attack(target)


func _army_center() -> Vector3:
	var a := _army()
	if a.is_empty():
		return main.hero.global_position
	var c := Vector3.ZERO
	for u in a:
		c += u.global_position
	return c / a.size()


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


## Vessa a few metres behind the army (toward home), out of the front line.
func _hero_behind(goal: Vector3) -> void:
	var c := _army_center()
	var back := HOME - c
	back.y = 0.0
	var spot := c + (back.normalized() * 4.0 if back.length() > 0.5 else Vector3.ZERO)
	if not _enemies_near(main.hero.global_position, 10.0).is_empty() or MissionBase._flat(c, goal) > 6.0:
		_hero_to(spot, 3.0)


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
		if u is Wizard and foes.size() > 1:
			continue
		var n := 0
		for o in foes:
			if MissionBase._flat(o.global_position, u.global_position) <= 3.0:
				n += 1
		if n > best_n:
			best_n = n
			best = u
	if best and (best_n >= 2 or hero.mana > hero.max_mana * 0.6):
		hero.command_cast(&"fireball", best.global_position)


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.snap(at, t.footprint)
	if main.build_grid.check(t, c, Unit.Team.PLAYER) != "":
		return false
	return main.build_grid.place(t, c, Unit.Team.PLAYER, [worker]) != null


func _mine_node() -> CrystalNode:
	for suffix in ["a", "b", "rich", "mid"]:
		var n := main.node_of(Unit.Team.PLAYER, suffix)
		if n:
			return n
	return null


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var node := _mine_node()
	for w in workers:
		var t: Variant = w.get(&"gather_node")
		if node and not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			w.call(&"command_gather", node)
	var k := main.keep
	if k == null or not k.is_alive():
		return
	# The Citadel (from 5:45) and Old Vey: the storm the hold is built around.
	if not novey:
		if k.tier == 2 and not k.is_upgrading() and k.can_upgrade() == "" and eco.crystals >= 300:
			k.upgrade()
			return
		var roster := HelperRoster.for_team(Unit.Team.PLAYER)
		if roster and k.tier >= 3 and roster.can_call() == "":
			roster.call_helper()
			return
	if eco.pop_cap - eco.pop_used < 5 and eco.pop_cap < 80 and _hearth_i < HEARTHS.size() and eco.crystals >= 100 \
			and not workers.is_empty():
		if _build("fire_hearth", HEARTHS[_hearth_i], workers[0]):
			_hearth_i += 1
			return
		_hearth_i += 1
	if not _hall2 and eco.crystals >= 400 and not workers.is_empty() and main.mission_time() > 90.0:
		for spot in HOME_HALLS:
			if _build("fire_barracks", spot, workers[0]):
				_hall2 = true
				break
		return
	if workers.size() < WORKERS and k.queue.size() < 2 and eco.crystals >= 60 and not k.is_upgrading():
		if k.queue_unit(UnitType.find("cinder_hand")) == "" and node:
			k.set_rally_node(node)
	# Keep 300 crystals back for the Citadel between 5:00 and its start.
	var reserve := 300 if not novey and k.tier == 2 and main.mission_time() > 300.0 else 0
	if eco.crystals - reserve < 120:
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"fire_barracks" \
				or hall.queue.size() >= 2:
			continue
		var want: String = ["flame_guard", "ember_archer", "flame_guard", "pyre_adept", "ember_archer", "blaze_rider"][_train_i % 6]
		if hall.queue_unit(UnitType.find(want)) == "":
			_train_i += 1
		hall.set_rally_point(HOLD_POS if main.kindled else HOME + Vector3(8.0, 0.0, -8.0))


# ---------------------------------------------------------------- the plan

func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.3:
		_retreat = true
	if _retreat:
		var safe := (VESSA_HOLD + Vector3(-4.0, 0.0, 8.0)) if m.kindled else (_army_center() + Vector3(-6.0, 0.0, 6.0))
		_hero_to(safe, 2.0)
		if hero.hp >= hero.max_hp * 0.8:
			_retreat = false
		if not m.kindled:
			return
	match phase:
		&"g1":
			var g1: Array = m.guard_groups[&"G1"]
			if MissionBase._all_dead(g1):
				_set_phase(&"s1")
				return
			for u in g1:
				if is_instance_valid(u) and (u as Unit).is_alive():
					_army_to((u as Unit).global_position, 3.0)
					_hero_behind((u as Unit).global_position)
					break
		&"s1":
			if _hideout_step(&"S1", 3):
				_set_phase(&"glade")
		&"glade":
			if _army().size() < G2_ARMY and m.mission_time() < G2_LATEST and m.frost < 45.0:
				_army_to(Vector3(-22.0, 0.0, 22.0), 4.0)   # muster on the road, out of G2's reach
				_hero_to(Vector3(-25.0, 0.0, 25.0), 3.0)
				return
			var g2: Array = m.guard_groups[&"G2"]
			var foes := _enemies_near(MissionE2_01.HEARTWOOD_POS, 14.0)
			if not foes.is_empty():
				_army_to(foes[0].global_position, 3.0)
				_hero_behind(foes[0].global_position)
				return
			for t in m.totems:
				if is_instance_valid(t) and t.is_alive():
					_army_attack(t)
					_hero_behind(t.global_position)
					return
			if MissionBase._all_dead(g2):
				_set_phase(&"s2")
		&"s2":
			if _hideout_step(&"S2", 4):
				_set_phase(&"kindle")
		&"kindle":
			_army_to(HOLD_POS, 4.0)
			_hero_to(MissionE2_01.HEARTWOOD_POS + Vector3(0.0, 0.0, 3.5), 1.0)
			if m.kindled:
				_set_phase(&"hold")
		&"hold":
			var foes := _enemies_near(MissionE2_01.HEARTWOOD_POS, 22.0)
			if not foes.is_empty():
				_army_to(foes[0].global_position, 3.0)
			else:
				_army_to(HOLD_POS, 4.0)
			if not _retreat:
				_hero_to(VESSA_HOLD, 2.0)


## Clears hideout `id` (its guard group G<g>) and walks Vessa in; true once it is freed.
func _hideout_step(id: StringName, g: int) -> bool:
	var m := main
	if m.hideout_freed.has(id):
		return true
	var at: Vector3 = (MissionE2_01.HIDEOUTS[id] as Array)[1]
	var guards: Array = m.guard_groups[StringName("G%d" % g)]
	if not MissionBase._all_dead(guards):
		for u in guards:
			if is_instance_valid(u) and (u as Unit).is_alive():
				_army_to((u as Unit).global_position, 3.0)
				_hero_behind((u as Unit).global_position)
				break
		return false
	_army_to(at, 4.0)
	_hero_to(at, 2.0)
	return false
