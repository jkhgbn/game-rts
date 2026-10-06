extends SceneTree
## Mission 4 timing check (docs/design/mission-04.md "Done when", lead runs): a scripted headless run on normal with
## real fights (no hero protection, no kills or time skips by the test; cutscenes off = their skip end states, their
## spec lengths are added to the reported play time). The scripted player trains from its own economy, holds its base
## against Malrik's attacks, takes the Master's seat at SEAT_AT (clearing the isle guard first), breaks P1 and P2 at
## home then crosses for whatever east pylon Malrik left, fights the walking Colossus beside the keep, and turns the key
## beside Old Vey until the Colossus falls. Must end `victory=true`; prints the phase times.
## `-- --meter`: never sits (the meter Rise). `-- --seed N`: the run's random seed. `-- --verbose`: state every 30 s.
## Slow (20+ min of game).
## Run:  godot --headless --path . -s tests/test_19_c5_sim.gd --fixed-fps 60 --quit-after 150000 [-- --meter]

const TASK_ID := "19_c5_sim"
const MISSION := "res://missions/mission_04.tscn"
const HOME := Vector3(-34.0, 0.0, 34.0)
const SEAT_AT := 360.0
const CUTSCENE_SECONDS := {&"war": 30.0, &"rise": 45.0, &"storm": 105.0, &"fall": 6.0}
const STAGING := Vector3(-24.0, 0.0, 24.0)
const ATTACK_ARMY := 14      ## Phase 1: go for a pylon with this many soldiers...
const REGROUP_ARMY := 5      ## ...fall back home below this many.
const EAST_WAIT := 180.0     ## Phase 1: the east pylons are left to Malrik's strike this long after the Rise.
const WORKERS := 12
const GUARDS := 6
const GUARD_POST := Vector3(-42.0, 0.0, 38.0)
## A second Ember Hall at home (production; the natural's X1 spot beside Crown Isle is where Malrik's attacks land),
## then a drop-off hall at the rich node once the home nodes run low.
const HOME_HALLS: Array[Vector3] = [Vector3(-28.0, 0.0, 38.0), Vector3(-20.0, 0.0, 44.0), Vector3(-36.0, 0.0, 24.0)]
const HEARTHS: Array[Vector3] = [Vector3(-44.0, 0.0, 52.0), Vector3(-38.0, 0.0, 52.0), Vector3(-52.0, 0.0, 38.0),
		Vector3(-32.0, 0.0, 52.0), Vector3(-52.0, 0.0, 32.0)]

var meter := false
var verbose := false
var h := MissionHarness.new()
var main: Mission04
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hearth_i := 0
var _train_i := 0
var _retreat := false
var _phase_log: Array[String] = []
var _last_phase := 0
var _regroup := true
var _hall2_built := false
var _rich_hall_built := false
var _home_guard: Array = []
var _regroup_since := 0.0
var _dodging := {}   ## unit instance id -> msec until which the plan leaves it alone (stepping out of a ring)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	meter = args.has("--meter")
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("/meter" if meter else "/seat")
	h.protect_hero = false
	h.timeout_frames = 140000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_19_c5_sim_none.json"}}) as Mission04
	h.steps.add("play", _play, 139000)
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.unit_died.connect(_on_died)


var killers := {}   ## "phase:killer" -> Fire units killed (diagnostics)


func _on_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or int(unit.team) != Unit.Team.PLAYER or main == null:
		return
	var k: Variant = unit.killer
	var who := "?"
	if k != null and is_instance_valid(k):
		var kt: Variant = k.get(&"unit_type")
		who = String((kt as UnitType).id) if kt != null else String((k as Node).name)
	var key := "p%d:%s" % [main.phase, who]
	killers[key] = int(killers.get(key, 0)) + 1


func _process(_delta: float) -> bool:
	return h.tick()


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"war"] + (CUTSCENE_SECONDS[&"rise"] if m.rise_time >= 0.0 else 0.0) \
				+ (CUTSCENE_SECONDS[&"storm"] if m.storm_time >= 0.0 else 0.0) + (CUTSCENE_SECONDS[&"fall"] if h.ended == 1 else 0.0)
		var total := t + cine
		print("  %s at mission time %s (play time with cutscenes %s); Rise %s (%s), walk %s, storm %s; pylons by Shadow %d; exposures %d" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(total), _mmss(m.rise_time),
				"seat" if m.seat_taken else "meter", _mmss(m.walk_time), _mmss(m.storm_time), m.shadow_pylons,
				m.keystone.exposures])
		print("  darkest by %s; Vessa L%d; army %d; phases %s" % [m.darkest_by, m.hero.level, _army().size(),
				", ".join(_phase_log)])
		print("  Fire losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (phase %d)" % [t, m.phase])
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if m.phase != _last_phase:
		_last_phase = m.phase
		_phase_log.append("p%d@%s" % [m.phase, _mmss(m.mission_time())])
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var boss := m.keystone.colossus_hp_pct() * 100.0 if m.keystone.colossus_alive() else -1.0
		var pyl := ""
		for i in m.keystone.pylons.size():
			var p: Unit = m.keystone.pylons[i]
			if is_instance_valid(p) and p.is_alive():
				pyl += "P%d(%d hp, %d foes) " % [i + 1, int(p.hp), _enemies_near(p.global_position, 10.0).size()]
		if pyl != "":
			print("      pylons: ", pyl)
		var halls := 0
		var gathering := 0
		for b in Building.for_team(Unit.Team.PLAYER):
			if b.is_alive() and b.building_type.id == &"fire_barracks" and b.is_constructed():
				halls += 1
		for w in _workers():
			if w.call(&"is_gathering"):
				gathering += 1
		var nodes := ""
		for sfx in ["a", "b", "mid", "rich"]:
			var cn: CrystalNode = m.crystal_nodes.get(StringName("node_fire_" + sfx))
			nodes += "%s=%d " % [sfx, cn.crystals_left if cn and is_instance_valid(cn) else -1]
		print("      eco: halls %d, gathering %d / %d, nodes %s, hall2 %s" % [halls, gathering, _workers().size(), nodes, _hall2_built])
		if _last_print % 2 == 0 and not killers.is_empty():
			print("      losses: ", killers)
		print("    t=%s p%d vessa %3.0f/%3.0f L%d | army %2d (w%d) | crystals %4d | hollow %5.1f | pylons %d | boss %3.0f%% | keep %3.0f%%" % [
				_mmss(m.mission_time()), m.phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _workers().size(),
				Economy.for_team(Unit.Team.PLAYER).crystals, m.hollow, 4 - m.pylons_broken, boss, m._keep_pct() * 100.0])
	_learn()
	_economy()
	_fireball()
	if m.phase >= 0 and m.phase < 3:
		_guard_home()
	_play_phase()
	_dodge()
	return false


## A player steps out of the Colossus's telegraph rings (Hurl 1.6 s, Stomp 1.2 s): every own unit inside walks out.
func _dodge() -> void:
	var rings: Array = main.keystone.active_threats()
	if rings.is_empty():
		return
	var mine: Array[Unit] = _army()
	mine.append(main.hero)
	for u in mine:
		for r: Array in rings:
			var c: Vector3 = r[0]
			var d := MissionBase._flat(u.global_position, c)
			if d <= float(r[1]) + 0.6:
				var dir := u.global_position - c
				dir.y = 0.0
				if dir.length() < 0.2:
					dir = Vector3(-1.0, 0.0, 1.0)
				u.command_move(c + dir.normalized() * (float(r[1]) + 2.0))
				_dodging[u.get_instance_id()] = int(main.mission_time() * 1000.0) + 2000
				break


static func _mmss(t: float) -> String:
	if t < 0.0:
		return "-"
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


# ---------------------------------------------------------------- helpers

func _army(include_dodging := true) -> Array[Unit]:
	var out: Array[Unit] = []
	var now := int(main.mission_time() * 1000.0)
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable():
			if not include_dodging and int(_dodging.get(u.get_instance_id(), 0)) > now:
				continue
			if _home_guard.has(u):
				continue
			out.append(u)
	return out


## GUARDS soldiers stay home against the raids (an efficient player never leaves the workers alone).
func _guard_home() -> void:
	_home_guard = _home_guard.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if _home_guard.size() < GUARDS:
		for u in _army():
			if _home_guard.size() >= GUARDS:
				break
			if u.unit_type and u.unit_type.id != &"ash_hurler":
				_home_guard.append(u)
	var foes := _enemies_near(HOME, 26.0)
	for g: Variant in _home_guard:
		var u := g as Unit
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if not foes.is_empty():
			u.command_attack_move(foes[0].global_position)
		elif MissionBase._flat(u.global_position, GUARD_POST) > 5.0:
			u.command_attack_move(GUARD_POST)


func _enemies_near(at: Vector3, r: float, with_pylons := false) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u.team != Unit.Team.PLAYER and not main.is_dormant(u) \
				and (with_pylons or not u.is_in_group(&"pylons")) and u != main.keystone.colossus \
				and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	return out


func _learn() -> void:
	var w := main.hero as Wizard
	for i in 3:
		if w.spell_points <= 0:
			return
		for id: StringName in [&"fireball", &"ember_step", &"kindle"]:
			if w.learn_spell(id) == "":
				break


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
			out.append(n as Unit)
	return out


## The first home / rich / natural node with crystals left (an efficient player moves on when a node runs dry; the
## natural beside Crown Isle comes last: the isle guard, Malrik's attacks and, after the Rise, the Colossus's Hurl
## reach it).
func _mine_node() -> CrystalNode:
	for suffix in ["a", "b", "rich", "mid"]:
		var n := main.node_of(Unit.Team.PLAYER, suffix)
		if n:
			return n
	return null


## Crystals left on the two home nodes.
func _home_left() -> int:
	var n := 0
	for sfx in ["a", "b"]:
		var cn := main.node_of(Unit.Team.PLAYER, sfx)
		if cn:
			n += cn.crystals_left
	return n


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var eco := Economy.for_team(Unit.Team.PLAYER)
	if eco == null:
		return
	var workers := _workers()
	var node := _mine_node()
	for w in workers:   # idle or on a dry node: back to work
		var t: Variant = w.get(&"gather_node")
		if node and not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) 				and not w.has_move_order():
			w.call(&"command_gather", node)
	if eco.pop_cap - eco.pop_used < 4 and eco.pop_cap < 70 and _hearth_i < HEARTHS.size() and eco.crystals >= 100 			and not workers.is_empty():
		_build("fire_hearth", HEARTHS[_hearth_i], workers[0])
		_hearth_i += 1
		return
	if not _hall2_built and eco.crystals >= 450 and not workers.is_empty():   # a second production hall at home
		for spot in HOME_HALLS:
			if _build("fire_barracks", spot, workers[0]):
				_hall2_built = true
				break
		return
	if not _rich_hall_built and eco.crystals >= 450 and not workers.is_empty() and _home_left() < 900:
		_rich_hall_built = _build("fire_barracks", main.rich_hall_spot(Unit.Team.PLAYER), workers[0])
		return
	var k := main.keep
	if workers.size() < WORKERS and k and k.is_alive() and k.queue.size() < 2 and eco.crystals >= 60:
		if k.queue_unit(UnitType.find("cinder_hand")) == "" and node:
			k.set_rally_node(node)
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"fire_barracks" 				or hall.queue.size() >= 2:
			continue
		var want: String = ["flame_guard", "ember_archer", "flame_guard", "ember_archer", "ash_hurler"][_train_i % 5]
		if hall.queue_unit(UnitType.find(want)) == "":
			_train_i += 1


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.snap(at, t.footprint)
	if main.build_grid.check(t, c, Unit.Team.PLAYER) != "":
		return false
	return main.build_grid.place(t, c, Unit.Team.PLAYER, [worker]) != null


func _fireball() -> void:
	var hero := main.hero
	var k := main.keystone
	if k.colossus_alive() and k.colossus.exposed \
			and MissionBase._flat(hero.global_position, k.colossus.global_position) <= 12.0:
		hero.command_cast(&"fireball", k.colossus.global_position)
		return
	var best: Unit = null
	var best_n := 0
	var foes := _enemies_near(hero.global_position, 11.0)
	for u in foes:
		var n := 0
		for o in foes:
			if MissionBase._flat(o.global_position, u.global_position) <= 3.0:
				n += 1
		if n > best_n:
			best_n = n
			best = u
	if best and (best_n >= 2 or hero.mana > hero.max_mana * 0.6):
		hero.command_cast(&"fireball", best.global_position)


func _army_to(at: Vector3, spread := 4.0) -> void:
	for u in _army(false):
		if u.attack_target != null and is_instance_valid(u.attack_target) and u.attack_target is Unit \
				and not (u.attack_target as Unit).is_in_group(&"boss"):
			continue
		if MissionBase._flat(u.global_position, at) > spread + 2.0:
			u.command_attack_move(at + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread)))


func _army_attack(target: Unit) -> void:
	for u in _army(false):
		if u.attack_target == target:
			continue
		if u.attack_target != null and is_instance_valid(u.attack_target) and u.attack_target is Unit \
				and MissionBase._flat((u.attack_target as Unit).global_position, u.global_position) < 6.0 \
				and not (u.attack_target as Unit).is_in_group(&"pylons"):
			continue   # finishing a Warden next to it
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
	var hero := main.hero
	if MissionBase._flat(hero.global_position, at) > near:
		hero.command_move(at)


func _hero_behind(goal: Vector3) -> void:
	var c := _army_center()
	var back := (HOME - c)
	back.y = 0.0
	var spot := c + (back.normalized() * 4.0 if back.length() > 0.5 else Vector3.ZERO)
	if not _enemies_near(main.hero.global_position, 12.0).is_empty() or MissionBase._flat(c, goal) > 6.0:
		_hero_to(spot, 3.0)


func _threat_near_home() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _enemies_near(HOME, 28.0):
		if u.team == Unit.Team.ENEMY:
			out.append(u)
	return out


func _next_pylon() -> Unit:
	var order: Array[int] = [0, 1, 2, 3]
	for i in order:
		var p: Unit = main.keystone.pylons[i]
		if not is_instance_valid(p) or not p.is_alive():
			continue
		if i >= 2:
			if main.mission_time() - main.rise_time < EAST_WAIT:
				continue   # P1 / P2 first at home; Malrik's strike works on P3 / P4 meanwhile
			var shadow := 0
			for u in _enemies_near(p.global_position, 16.0):
				if int(u.team) == Unit.Team.ENEMY:
					shadow += 1
			if shadow >= 3:
				continue   # Malrik's strike is on it: let it soften the pylon (mission-04.md "the intended answer")
		return p
	return null


# ---------------------------------------------------------------- the plan

func _play_phase() -> void:
	var m := main
	var hero := m.hero
	var k := m.keystone
	if m.phase == 3:
		_phase_key()
		return
	if not _retreat and hero.hp < hero.max_hp * 0.3:
		_retreat = true
	if _retreat:
		_hero_to(m.keep.global_position + Vector3(4.0, 0.0, -4.0), 3.0)
		_army_to(hero.global_position, 5.0)
		if hero.hp >= hero.max_hp * 0.85:
			_retreat = false
		return
	var raid := _threat_near_home()
	if raid.size() > GUARDS and m.phase != 2:
		_army_to(raid[0].global_position, 3.0)
		_hero_behind(raid[0].global_position)
		return
	match m.phase:
		0:
			if meter or m.mission_time() < SEAT_AT:
				_army_to(m.ARMY_POS, 3.0)
				_hero_to(m.ARMY_POS + Vector3(-3.0, 0.0, 3.0), 3.0)
				return
			var guard := _enemies_near(Vector3.ZERO, 12.0)
			if not guard.is_empty():
				_army_to(guard[0].global_position, 3.0)
				_hero_behind(guard[0].global_position)
			else:
				_army_to(Vector3(-4.0, 0.0, 4.0), 3.0)
				_hero_to(Vector3.ZERO, 1.0)
		1:
			var p := _next_pylon()
			if p == null:   # waiting for Malrik on the east bank: hold home, out of the Hurl's 30 m
				_army_to(STAGING, 4.0)
				_hero_to(STAGING + Vector3(-3.0, 0.0, 3.0), 3.0)
				return
			# Regroup at home when the army is thin, then go in together (Wardens first, then the pylon).
			var army := _army().size()
			if _regroup and (army >= ATTACK_ARMY or m.mission_time() - _regroup_since > 90.0):
				_regroup = false
			elif not _regroup and army < REGROUP_ARMY:
				_regroup = true
				_regroup_since = m.mission_time()
			if _regroup:
				_army_to(STAGING, 4.0)
				_hero_to(STAGING + Vector3(-3.0, 0.0, 3.0), 3.0)
				return
			var foes := _enemies_near(p.global_position, 10.0)
			if not foes.is_empty():
				_army_to(p.global_position, 3.0)
			else:
				_army_attack(p)
			_hero_behind(p.global_position)
		2:
			# Fight the Colossus once it is on the player's bank; Vessa stays back from its fists.
			if not k.colossus_alive():
				return
			# Phase 2 is meant to feel lost: hold at the keep (towers + the keep's heal), hit the Colossus when it
			# arrives, Vessa behind the keep, out of its fists and the Wardens' way.
			var c := k.colossus.global_position
			var kp := m.keep.global_position
			var near_keep := _enemies_near(kp, 20.0)
			# The Shadow push and the Wardens only, never the Colossus's fists (the army must live to phase 3); the
			# Cracked Leg stagger is the one window to hit it.
			if k.colossus.cracked_left > 0.0 and MissionBase._flat(c, kp) < 22.0:
				_army_attack(k.colossus)
			elif not near_keep.is_empty() and MissionBase._flat(near_keep[0].global_position, c) > 8.0:
				_army_to(near_keep[0].global_position, 3.0)
			else:
				_army_to(kp + Vector3(7.0, 0.0, 8.0), 3.0)   # beside the keep, off the Colossus's lane
			_hero_to(kp + Vector3(-7.0, 0.0, 7.0), 2.0)


## Phase 3: Vessa by the heart (within 4 m of its edge), the army on the Colossus and its Wardens.
func _phase_key() -> void:
	var m := main
	var k := m.keystone
	if not k.colossus_alive():
		return
	var c := k.colossus.global_position
	var away := (HOME - c)
	away.y = 0.0
	var spot := c + away.normalized() * (k.colossus.radius + 2.5)
	var hero := m.hero
	if hero.hp < hero.max_hp * 0.45 and k.key_progress <= 0.0:
		_hero_to(c + away.normalized() * 14.0, 2.0)   # breathe; Vey stays with her
	else:
		_hero_to(spot, 1.0)
	var wardens := _enemies_near(hero.global_position, 8.0)
	if not wardens.is_empty() and not k.colossus.exposed:
		_army_to(wardens[0].global_position, 2.0)
	else:
		_army_attack(k.colossus)
