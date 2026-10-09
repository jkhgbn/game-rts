extends SceneTree
## Mission e5m2 timing check (docs/design/mission-e5-02.md "Lead" check: a scripted headless run on normal, army
## first through the Causeway, spots 3 / 3 bands and ends `victory=true` in 16-20 game-minutes with sec_patience done).
## Real fights: no hero protection, no kills or time skips by the test; cinematics off (fallback end states), the spec
## lengths of e5m2_rookhold 0:15, e5m2_door 0:08 and e5m2_morning 0:45 are added to the reported play time.
## The scripted player (patient): Cinder Hands to 10, two Hearths, Flame Guards / Ember Archers / Ash Hurlers from the
## Ember Hall; the army walks the Causeway reed by reed with Vessa behind 4+ soldiers (the bands are spotted), then the
## siege from the north-west: Hurlers on the near tower and the Rook Gate from 12 m, archers under Ashby, Guards in
## front against the sally; through the breach to the Nest. `rush`: Vessa and the start army go at once (springs).
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e5m2_sim.gd --fixed-fps 60
## --quit-after 110000

const TASK_ID := "e5m2_sim"
const MISSION := "res://missions/mission_e5_02.tscn"
const CUTSCENE_SECONDS := {&"rookhold": 15.0, &"door": 8.0, &"morning": 45.0}
const HOME := Vector3(-36.0, 0.0, -36.0)
const RALLY := Vector3(-22.0, 0.0, -26.0)
const HEARTHS: Array[Vector3] = [Vector3(-48.0, 0.0, -46.0), Vector3(-46.0, 0.0, -52.0)]
const WORKERS := 10
const SIEGE_SPOT := Vector3(12.0, 0.0, 16.0)
const RUSH_MIN := 840.0   ## a rush must not win faster than this (play time, the spec's easy lower bound 14:00)
## Steps: [id, soldiers needed, earliest mission time].
const PLAN := [
	[&"R1", 10, 180.0],
	[&"R2", 12, 330.0],
	[&"R3", 14, 450.0],
	[&"siege", 18, 570.0],
	[&"assault", 0, 0.0],
]

var verbose := false
var rush := false
var h := MissionHarness.new()
var main: MissionE5_02
var _step := 0
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _sites: Array = []
var _wounded := {}
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("_rush" if rush else "")
	h.protect_hero = false
	h.timeout_frames = 105000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e5m2_sim_none.json"}}) as MissionE5_02
	h.steps.add("play", _play, 104000)
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
	return String(PLAN[mini(_step, PLAN.size() - 1)][0])


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"rookhold"] + (CUTSCENE_SECONDS[&"door"] if m.has_fired(&"E11") else 0.0) \
				+ (CUTSCENE_SECONDS[&"morning"] if h.ended == 1 else 0.0)
		var total := t + cine
		print("  %s at mission time %s (play time with cutscenes %s); bands spotted %d sprung %d; towers %d; Ashby wounds %d; Gannet fled %s" % [
				"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t), MissionE5Base.mmss(total), m.bands_spotted,
				m.bands_sprung, m.towers_burned, m.ashby_wounds, m.gannet_fled])
		print("  phases %s; waves %s; spotlight %s" % [", ".join(_phase_log), ",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Fire losses by killer: %s" % str(killers))
		if rush:
			h.check(h.ended == 0 or total >= RUSH_MIN, "rush won in %s (< %s)" % [MissionE5Base.mmss(total), MissionE5Base.mmss(RUSH_MIN)])
			return true
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, _step_id()])
		h.check(total >= 900.0 and total <= 1260.0, "play time %s outside ~15-21 min" % MissionE5Base.mmss(total))
		h.check(m.objective_state("sec_patience") == "done", "sec_patience %s" % m.objective_state("sec_patience"))
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
		print("    t=%s %s vessa %3.0f/%3.0f L%d | army %2d (hurlers %d) w%d | crystals %4d pop %d/%d | gate %4.0f nest %4.0f | bands %s" % [
				MissionE5Base.mmss(m.mission_time()), _step_id(), m.hero.hp, m.hero.max_hp, m.hero.level, _soldiers().size(),
				_of_type("ash_hurler").size(), _workers().size(), eco.crystals, eco.pop_used, eco.pop_cap,
				m.rook_gate.hp if is_instance_valid(m.rook_gate) else 0.0, m.nest.hp if is_instance_valid(m.nest) else 0.0,
				str(m.band_state.values())])
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


func _of_type(id: String) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _soldiers():
		if u.unit_type and String(u.unit_type.id) == id:
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
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not main.is_dormant(u) \
				and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _hold(units: Array, at: Vector3, r: float, facing := Vector3(1.0, 0.0, 1.0)) -> bool:
	if units.is_empty():
		return false
	var foes := _foes_near(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target) or u.attack_target is Building:
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
				node = m.node_of(0, "dyke")
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
	var hearths := _count_built("fire_hearth")
	if free_w and eco.pop_cap - eco.pop_used < 5 and hearths < 2 and eco.crystals >= 80 \
			and not _sites.any(func(r: Array) -> bool: return (r[0] as Building).building_type.id == &"fire_hearth"):
		_build("fire_hearth", HEARTHS[hearths], free_w)
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"fire_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 90:
			continue
		var want := "flame_guard"
		var hurlers := _of_type("ash_hurler").size()
		var archers := _of_type("ember_archer").size()
		var guards := _of_type("flame_guard").size()
		if hurlers < 4 and m.mission_time() > 240.0:
			want = "ash_hurler"
		elif archers < guards:
			want = "ember_archer"
		if hall.queue_unit(UnitType.find(want)) == "":
			_train_i += 1
		hall.set_rally_point(RALLY)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"kindle", &"fireball", &"ember_step"]:
			if w.learn_spell(id) == "":
				break
	if w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		return
	if _foes_near(w.global_position, 12.0).is_empty():
		return
	var s: Dictionary = w.spell_caster.call(&"suggest_cast")
	var id := StringName(str(s.get("spell_id", "")))
	if id == &"fireball" or id == &"kindle":
		w.command_cast(id, s.get("target"))


# ---------------------------------------------------------------- the plan

func _set_phase(p: String) -> void:
	if _phase_log.is_empty() or not _phase_log[-1].begins_with(p + "@"):
		_phase_log.append("%s@%s" % [p, MissionE5Base.mmss(main.mission_time())])


## Vessa stays behind the army (4+ soldiers around her), never first into the reeds.
func _vessa_behind(army: Array, toward: Vector3) -> void:
	var c := SimTactics.centroid(army)
	if c == Vector3.INF:
		_hero_to(RALLY, 3.0)
		return
	var back := (c - toward)
	back.y = 0.0
	back = back.normalized() if back.length() > 0.1 else Vector3(-1.0, 0.0, -1.0).normalized()
	_hero_to(c + back * (4.0 if not _retreat else 10.0), 2.5)


func _plan() -> void:
	var m := main
	var hero := m.hero
	var t := m.mission_time()
	if not _retreat and hero.hp < hero.max_hp * 0.4:
		_retreat = true
	if _retreat and hero.hp >= hero.max_hp * 0.8:
		_retreat = false
	var army: Array = SimTactics.pull_back_wounded(_soldiers(), RALLY, _wounded, 0.5)
	var home_foes := _foes_near(m.keep.global_position if m.keep else HOME, 22.0)
	if home_foes.size() >= 2 and not rush and _step < 3:
		_set_phase("defend")
		_hold(army, home_foes[0].global_position, 16.0)
		_vessa_behind(army, home_foes[0].global_position)
		return
	var row: Array = PLAN[mini(_step, PLAN.size() - 1)]
	var id: StringName = row[0]
	_set_phase(String(id))
	if not rush and (army.size() < int(row[1]) or t < float(row[2])):
		_hold(army, RALLY if _step == 0 else _staging(), 14.0)
		_vessa_behind(army, MissionE5_02.FORT)
		return
	match id:
		&"R1", &"R2", &"R3":
			var c: Vector3 = MissionE5_02.REEDS[id][1]
			var busy := _hold(army, c, 14.0)
			_vessa_behind(army, c)
			var ac := SimTactics.centroid(army)
			if not busy and m.band_state[id] != "hidden" and ac != Vector3.INF and MissionBase._flat(ac, c) < 11.0:
				_step += 1
		&"siege":
			_siege(army)
		&"assault":
			_assault(army)


## Where the army waits for the next step: the last reed field cleared, never within the towers' / gate's reach.
func _staging() -> Vector3:
	var last := PLAN[maxi(0, _step - 1)][0] as StringName
	if last == &"R3":
		return MissionE5_02.REEDS[&"R2"][1] + Vector3(-3.0, 0.0, -3.0)
	if MissionE5_02.REEDS.has(last):
		return MissionE5_02.REEDS[last][1]
	return RALLY


## Hurlers on the nearest tower then the Rook Gate from 12 m; archers by Ashby; Guards in front; Vessa fireballs wood.
func _siege(army: Array) -> void:
	var m := main
	if m.has_fired(&"E11"):
		_step += 1
		return
	var tower: Building = null
	for v: Variant in m.towers:
		if is_instance_valid(v) and (v as Building).is_alive():
			tower = v
			break
	var target: Building = tower if tower else m.rook_gate
	if target == null or not is_instance_valid(target) or not target.is_alive():
		_step += 1
		return
	var foes := _foes_near(SIEGE_SPOT, 16.0)
	var melee: Array = []
	var ranged: Array = []
	for v: Variant in army:
		var u := v as Unit
		if u.unit_type and u.unit_type.id == &"ash_hurler":
			if u.attack_target != target and foes.is_empty():
				u.command_attack(target)
			elif not foes.is_empty() and u.attack_target == target:
				pass
		elif SimTactics.is_ranged(u) or u == m.ashby:
			ranged.append(u)
		else:
			melee.append(u)
	if not foes.is_empty():
		for u: Variant in melee + ranged:
			if (u as Unit).attack_target == null or (u as Unit).attack_target is Building:
				(u as Unit).command_attack_move(foes[0].global_position)
	else:
		SimTactics.spread_to(melee, SIEGE_SPOT + Vector3(3.0, 0.0, 3.0), Vector3(1.0, 0.0, 1.0).normalized())
		for u: Variant in ranged:
			var ru := u as Unit
			if ru == m.ashby:
				if MissionBase._flat(ru.global_position, SIEGE_SPOT) > 3.0:
					ru.command_move(SIEGE_SPOT + Vector3(-1.0, 0.0, -1.0))
			elif MissionBase._flat(ru.global_position, target.global_position) > 8.5:
				ru.command_attack(target)
	var hero := m.hero
	if _retreat:
		_hero_to(SIEGE_SPOT + Vector3(-8.0, 0.0, -8.0), 2.0)
	elif MissionBase._flat(hero.global_position, target.global_position) > 9.0:
		_hero_to(target.global_position + (SIEGE_SPOT - target.global_position).normalized() * 8.0, 2.0)
	elif hero.attack_target != target and foes.is_empty():
		hero.command_attack(target)


## Through the breach to the Nest: kill what comes, then burn it.
func _assault(army: Array) -> void:
	var m := main
	if m.nest == null or not is_instance_valid(m.nest) or not m.nest.is_alive():
		return
	var at := m.nest.global_position
	var inside := _foes_near(MissionE5_02.FORT, MissionE5_02.FORT_R + 6.0)
	if not inside.is_empty():
		for v: Variant in army:
			var u := v as Unit
			if u.attack_target == null or u.attack_target is Building:
				u.command_attack_move(inside[0].global_position)
	else:
		for v: Variant in army:
			var u := v as Unit
			if u.attack_target != m.nest:
				u.command_attack(m.nest)
	_vessa_behind(army, at)
	if not _retreat and inside.is_empty() and m.hero.attack_target != m.nest:
		m.hero.command_attack(m.nest)
