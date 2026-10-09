extends SceneTree
## Mission e5m1 timing check (docs/design/mission-e5-01.md "Lead" check: a scripted headless run on normal lights the 5
## beacons and ends `victory=true` in 12-15 game-minutes, cutscenes included). Real fights: no hero protection, no kills
## or time skips by the test; cinematics off (fallback end states), the spec lengths of e5m1_valley 0:15 and
## e5m1_watch 0:40 are added to the reported play time.
## The scripted player (a careful newcomer): Cinder Hands to 8, the Ember Hall at ~1:00, a Hearth, Flame Guards and
## Ember Archers; beacons in the spec order (Hearthstone, Millrace, Old Bridge, the Knoll, Bellmouth), the army first
## (Vessa never runs ahead), home defence when raiders reach Valewatch, an Ember Spire by the farms after the first
## raid, the tents burned before Bellmouth, then the hold on Bellmouth's hill.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e5m1_sim.gd --fixed-fps 60
## --quit-after 80000

const TASK_ID := "e5m1_sim"
const MISSION := "res://missions/mission_e5_01.tscn"
const CUTSCENE_SECONDS := {&"valley": 15.0, &"watch": 40.0}
const HOME := Vector3(-30.0, 0.0, -36.0)
const RALLY := Vector3(-24.0, 0.0, -30.0)
const HALL := Vector3(-24.0, 0.0, -46.0)
const HEARTH := Vector3(-46.0, 0.0, -48.0)
const SPIRE := Vector3(-38.0, 0.0, 26.0)
const WORKERS := 8
## Plan steps: [id, beacon or point, soldiers needed before leaving, earliest mission time].
const PLAN := [
	[&"hearthstone", 0, 0.0],
	[&"millrace", 6, 120.0],
	[&"bridge", 9, 300.0],
	[&"knoll", 11, 420.0],
	[&"tents", 12, 540.0],
	[&"bellmouth", 13, 600.0],
]

const RUSH_MIN := 600.0   ## a rush (no waiting for the army) must not win faster than this (play time)

var verbose := false
var rush := false          ## test_e5m1_rush_sim: every step at once, Vessa with whatever she has
var h := MissionHarness.new()
var main: MissionE5_01
var _step := 0
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _sites: Array = []
var _wounded := {}
var _built := {}
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("_rush" if rush else "")
	h.protect_hero = false
	h.timeout_frames = 75000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e5m1_sim_none.json"}}) as MissionE5_01
	h.steps.add("play", _play, 74000)
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
	var key := "%s:%s" % [_step_id(), who]
	killers[key] = int(killers.get(key, 0)) + 1


func _process(_delta: float) -> bool:
	return h.tick()


func _step_id() -> String:
	return String(PLAN[mini(_step, PLAN.size() - 1)][0]) if _step < PLAN.size() else "hold"


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"valley"] + (CUTSCENE_SECONDS[&"watch"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); beacons %s; farms %d; tents %d; Vey kneels %d; barks %d; Gannet fled %s" % [
				"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t), MissionE5Base.mmss(t + cine),
				",".join(m.lit), m.farms_standing(), m.tents_burned, m.vey_kneels, m.bark_count, m.gannet_fled])
		print("  phases %s; waves %s; spotlight %s" % [", ".join(_phase_log), ",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Fire losses by killer: %s" % str(killers))
		var total := t + cine
		if rush:
			h.check(h.ended == 0 or total >= RUSH_MIN, "rush won in %s (< %s)" % [MissionE5Base.mmss(total), MissionE5Base.mmss(RUSH_MIN)])
			return true
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, _step_id()])
		h.check(total >= 660.0 and total <= 960.0, "play time %s outside ~11-16 min" % MissionE5Base.mmss(total))
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
		print("    t=%s %s vessa %3.0f/%3.0f L%d | army %2d w%d | crystals %4d pop %d/%d | lit %d | vey %3.0f" % [
				MissionE5Base.mmss(m.mission_time()), _step_id(), m.hero.hp, m.hero.max_hp, m.hero.level, _soldiers().size(),
				_workers().size(), eco.crystals, eco.pop_used, eco.pop_cap, m.lit.size(),
				m.vey.hp if m.vey and is_instance_valid(m.vey) else -1.0])
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


func _foes_near(at: Vector3, r: float, neutral := true) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and (int(u.team) == Unit.Team.ENEMY or (neutral and int(u.team) == Unit.Team.NEUTRAL)) \
				and not main.is_dormant(u) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


## The army fights around `at` (radius r) or forms up there. True while it fights.
func _hold(units: Array, at: Vector3, r: float, facing := Vector3(1.0, 0.0, 1.0)) -> bool:
	if units.is_empty():
		return false
	var foes := _foes_near(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		return true
	SimTactics.spread_to(units, at, facing.normalized())
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


func _count_built(type_id: String) -> int:
	return Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and String(b.building_type.id) == type_id).size()


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var m := main
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var busy := _tend_sites(workers)
	for w in workers:
		if busy.has(w):
			continue
		var t: Variant = w.get(&"gather_node")
		if not w.call(&"is_building") and (t == null or not is_instance_valid(t) or (t as CrystalNode).is_depleted()) \
				and not w.has_move_order():
			var node: CrystalNode = m.node_of(0, "a")
			if node == null:
				node = m.node_of(0, "b")
			if node == null:
				node = m.node_of(0, "mill")
			if node:
				w.call(&"command_gather", node)
	var k := m.keep
	if k == null or not k.is_alive():
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		var node: CrystalNode = m.node_of(0, "a")
		if k.queue_unit(UnitType.find("cinder_hand")) == "" and node:
			k.set_rally_node(node)
	if workers.is_empty():
		return
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w):
			free_w = w
			break
	if free_w and _count_built("fire_barracks") == 0 and not _built.has("hall") and eco.crystals >= 150 and m.mission_time() > 45.0:
		if _build("fire_barracks", HALL, free_w):
			_built["hall"] = true
		return
	if free_w and eco.pop_cap - eco.pop_used < 4 and _count_built("fire_hearth") < 1 and eco.crystals >= 80 \
			and not _sites.any(func(r: Array) -> bool: return (r[0] as Building).building_type.id == &"fire_hearth"):
		_build("fire_hearth", HEARTH + Vector3(0.0, 0.0, 5.0 * _count_built("fire_hearth")), free_w)
		return
	if free_w and m.has_fired(&"E_raid1") and not _built.has("spire") and eco.crystals >= 120:
		if _build("fire_tower", SPIRE, free_w):
			_built["spire"] = true
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"fire_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 90:
			continue
		var mix: Array = ["flame_guard", "ember_archer", "flame_guard", "ember_archer", "flame_guard"]
		var want: String = mix[_train_i % mix.size()]
		if hall.queue_unit(UnitType.find(want)) == "":
			_train_i += 1
		hall.set_rally_point(RALLY)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"ember_step", &"fireball", &"kindle"]:
			if w.learn_spell(id) == "":
				break
	if w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		return
	if _foes_near(w.global_position, 12.0, false).is_empty():
		return
	var s: Dictionary = w.spell_caster.call(&"suggest_cast")
	var id := StringName(str(s.get("spell_id", "")))
	if id == &"fireball":
		w.command_cast(id, s.get("target"))


# ---------------------------------------------------------------- the plan

func _set_phase(p: String) -> void:
	if _phase_log.is_empty() or not _phase_log[-1].begins_with(p + "@"):
		_phase_log.append("%s@%s" % [p, MissionE5Base.mmss(main.mission_time())])


func _plan() -> void:
	var m := main
	var hero := m.hero
	var t := m.mission_time()
	if not _retreat and hero.hp < hero.max_hp * 0.4:
		_retreat = true
	if _retreat and hero.hp >= hero.max_hp * 0.8:
		_retreat = false
	var army: Array = SimTactics.pull_back_wounded(_soldiers(), RALLY, _wounded, 0.5)
	var c := SimTactics.centroid(army)
	# Home defence: raiders at Valewatch or the workers (W1, W3).
	var home_foes := _foes_near(m.keep.global_position if m.keep else HOME, 20.0, false)
	if home_foes.size() >= 2 and _step < PLAN.size() and not rush:
		_set_phase("defend")
		_hold(army, home_foes[0].global_position, 14.0)
		_hero_to(c if c != Vector3.INF else HOME, 4.0)
		return
	if _step >= PLAN.size():
		_set_phase("hold")
		var at: Vector3 = MissionE5_01.BEACONS[&"bellmouth"][1] + Vector3(-4.0, 0.0, -4.0)
		_hold(army, at, 16.0, Vector3(1.0, 0.0, 1.0))
		_hero_to(at + Vector3(-3.0, 0.0, -3.0) if not _retreat else at + Vector3(-8.0, 0.0, -8.0), 2.0)
		return
	var row: Array = PLAN[_step]
	var id: StringName = row[0]
	_set_phase(String(id))
	var target: Vector3
	if id == &"tents":
		var tent: Building = null
		for v: Variant in m.tents:
			if is_instance_valid(v) and (v as Building).is_alive():
				tent = v as Building
				break
		if tent == null:
			_step += 1
			return
		target = tent.global_position
	else:
		target = MissionE5_01.BEACONS[id][1]
	# Wait at the rally for the army and the clock.
	if not rush and (army.size() < int(row[1]) or t < float(row[2])):
		_hold(army, RALLY if _step < 2 else _staging(), 14.0)
		_hero_to((c if c != Vector3.INF else RALLY) + Vector3(-2.0, 0.0, -2.0), 3.0)
		return
	var near := _foes_near(target, 14.0)
	var army_at := c if c != Vector3.INF else hero.global_position
	if id == &"tents":
		if not _hold(army, target, 12.0):
			for v: Variant in army:
				var u := v as Unit
				if u.attack_target == null:
					var tent_b := _nearest_tent(u.global_position)
					if tent_b:
						u.command_attack(tent_b)
		_hero_to(army_at + Vector3(-3.0, 0.0, -3.0), 3.0)
		return
	var br := m.beacons[id] as MissionBrazier
	if br.lit:
		_step += 1
		return
	_hold(army, target, 14.0)
	if near.is_empty() and MissionBase._flat(army_at, target) < 10.0 and not _retreat:
		_hero_to(target + Vector3(1.0, 0.0, 1.0), 1.0)   # light it
	elif _retreat:
		_hero_to(HOME, 3.0)   # heal at Valewatch (home healing)
	else:
		_hero_to(army_at + (army_at - target).normalized() * 3.0, 3.0)   # behind the army, never ahead


## Where the army waits once the vale is half lit: the Old Bridge.
func _staging() -> Vector3:
	return MissionE5_01.BEACONS[&"bridge"][1] + Vector3(-4.0, 0.0, -4.0) if main.lit.has("bridge") \
			else MissionE5_01.BEACONS[&"hearthstone"][1] + Vector3(4.0, 0.0, 4.0)


func _nearest_tent(from: Vector3) -> Building:
	var best: Building = null
	var d := INF
	for v: Variant in main.tents:
		if is_instance_valid(v) and (v as Building).is_alive():
			var dd := MissionBase._flat((v as Node3D).global_position, from)
			if dd < d:
				d = dd
				best = v as Building
	return best
