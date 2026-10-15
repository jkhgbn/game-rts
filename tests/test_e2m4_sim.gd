extends SceneTree
## Mission e2m4 timing check (docs/design/mission-e2-04.md acceptance check 9, the lead's scripted run): a headless run on
## normal with real fights (no hero protection, no kills or time skips by the test; cinematics off = their fallback end
## states, the spec lengths of e2m4_descent 0:20, e2m4_first_warden 0:10, e2m4_forge 0:15, e2m4_hush 0:10 and
## e2m4_sunrise 0:30 are added to the reported play time). The scripted player lights S1 / S2, wakes the Hall 1 Wardens
## with Vey, breaks G1, wakes G1n, breaks the forge guard, claims the forge, wakes the Hall 2 sleepers, lights S3 / S4,
## mines, builds an Ember Forge, a Hearth and an Ember Hall, researches Weapons and Armor, holds the forge through W1-W3,
## then takes the army to Hall 3 (Hush, the camp, the H3 sleepers, S5 / S6) and opens the gate with Vey.
## Must end `victory=true`; prints the phase times, G1's survivors and the Wardens / stones.
## `-- --seed N`, `-- --verbose`. Slow (17+ min of game).
## Run: godot --headless --path . -s tests/test_e2m4_sim.gd --fixed-fps 60 --quit-after 130000

const TASK_ID := "e2m4_sim"
const MISSION := "res://missions/mission_e2_04.tscn"
const CUTSCENE_SECONDS := {&"descent": 20.0, &"first_warden": 10.0, &"forge": 15.0, &"hush": 10.0, &"sunrise": 30.0}
const FORGE_SPOT := Vector3(10.0, 0.0, 5.0)
const HALL_SPOT := Vector3(-9.0, 0.0, 5.0)
const HEARTHS: Array[Vector3] = [Vector3(-6.0, 0.0, -13.0), Vector3(6.0, 0.0, -13.0), Vector3(-15.0, 0.0, -3.0)]
const WORKERS := 8
const LEAVE_AT := 750.0       ## The spec's rhythm: Hall 3 from ~12:00 (after W3).
const HOLD := Vector3(0.0, 0.0, 3.0)

var verbose := false
var h := MissionHarness.new()
var main: MissionE2_04
var phase := &"hall1"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hearth_i := 0
var _train_i := 0
var _built_forge := false
var _built_hall := false
var _phase_log: Array[String] = []
var _retreat := false
var _start_soldiers: Array = []
var _g1_survivors := -1
var _plan_i := 0
var killers := {}

## Vessa's walk list per phase: [kind, id or position].
var _plan_h1 := [[&"stone", 0], [&"wake", &"H1a"], [&"fight", &"G1"], [&"stone", 1], [&"wake", &"H1b"],
		[&"wake", &"H1c"], [&"wake", &"G1n"]]
var _plan_h2 := [[&"fight", &"G2"], [&"claim", 0], [&"wake", &"H2c"], [&"wake", &"H2d"], [&"wake", &"H2a"],
		[&"wake", &"H2b"], [&"stone", 2], [&"stone", 3]]
var _plan_h3 := [[&"fight", &"G3"], [&"wake", &"H3c"], [&"stone", 4], [&"wake", &"H3a"], [&"wake", &"H3b"],
		[&"camp", 0], [&"wake", &"H3d"], [&"stone", 5], [&"gate", 0]]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID
	h.protect_hero = false
	h.timeout_frames = 125000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m4_sim_none.json"}}) as MissionE2_04
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
		_plan_i = 0
		_phase_log.append("%s@%s" % [p, _mmss(main.mission_time())])


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if _start_soldiers.is_empty():
		_start_soldiers = _army().duplicate()
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"descent"] + (CUTSCENE_SECONDS[&"first_warden"] if m.has_fired(&"E4") else 0.0) \
				+ (CUTSCENE_SECONDS[&"forge"] if m.forge_claimed else 0.0) + (CUTSCENE_SECONDS[&"hush"] if m.hush_state != &"" else 0.0) \
				+ (CUTSCENE_SECONDS[&"sunrise"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); Wardens %d; stones %d; researches %d; Hush %s; gate %d %%" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), m.wardens_woken, m.stones_lit,
				m.researches, m.hush_state, int(m.gate_progress * 100.0)])
		print("  phases %s; G1 survivors %d / %d; waves %s; spotlight %s; amber %d" % [", ".join(_phase_log), _g1_survivors,
				_start_soldiers.size(), ",".join(m.waves_fired), h.spotlight_log, m.amber_wardens.size()])
		print("  objectives %s" % str(h.objective_log))
		print("  Fire losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if _g1_survivors < 0 and MissionBase._all_dead(m.guard_groups.get(&"G1", [])):
		_g1_survivors = _start_soldiers.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive()).size()
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		print("    t=%s %s/%d vessa %3.0f/%3.0f L%d | army %2d (w%d) | crystals %4d pop %d/%d | wardens %d amber %d stones %d | res %d | gate %.2f%s | hush %s | waves %s" % [
				_mmss(m.mission_time()), phase, _plan_i, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _workers().size(),
				eco.crystals, eco.pop_used, eco.pop_cap, m.sunwardens.size(), m.amber_wardens.size(), m.stones_lit, m.researches,
				m.gate_progress, " paused (%s)" % m.gate_block() if m.gate_paused else "", m.hush_state, ",".join(m.waves_fired)])
		if m.gate_paused:
			for n in m.get_tree().get_nodes_in_group(&"units"):
				var u := n as Unit
				if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and MissionBase._flat(u.global_position, MissionE2_04.GATE_SPOT) <= 10.0:
					print("      blocker %s at %s mode %s" % [u.unit_type.id, u.global_position, u.get_meta(MissionBase.META_MODE, &"")])
			var vy := m.vey
			print("      vey %s at %s vessa at %s" % [vy.is_alive() if vy else false, vy.global_position if vy else Vector3.ZERO, m.hero.global_position])
	if verbose and h.frame % 600 == 1:
		var pl: Array = _plan_h1 if phase == &"hall1" else (_plan_h2 if phase == &"hall2" else _plan_h3)
		var st: Array = pl[mini(_plan_i, pl.size() - 1)]
		print("      plan %s goal %s hero at %s moving %s foes %d retreat %s" % [str(st), _goal_pos(st), m.hero.global_position, m.hero.has_move_order(), _enemies_near(m.hero.global_position, 16.0).size(), _retreat])
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
				and u.is_commandable() and not u is Helper:
			out.append(u)
	return out


func _workers() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive() \
				and (n as Unit).is_commandable():
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


## Direct attack orders on the nearest foe (the dark hides foes from attack-move's auto-targets).
func _army_hit(foes: Array[Unit]) -> void:
	for u in _army():
		if u.attack_target != null and is_instance_valid(u.attack_target) and u.attack_target is Unit \
				and (u.attack_target as Unit).is_alive():
			continue
		var best: Unit = null
		var best_d := INF
		for f in foes:
			var d := MissionBase._flat(f.global_position, u.global_position)
			if d < best_d:
				best_d = d
				best = f
		if best:
			u.command_attack(best)


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
		if u.unit_type and u.unit_type.id == &"splinter_acolyte":
			n += 3   # Fireball one-shots the acolytes
		if n > best_n:
			best_n = n
			best = u
	if best and (best_n >= 2 or hero.mana > hero.max_mana * 0.6):
		hero.command_cast(&"fireball", best.global_position)


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.snap(at, t.footprint)
	var why := main.build_grid.check(t, c, Unit.Team.PLAYER)
	if why != "":
		if verbose:
			print("      build %s at %s refused: %s" % [type_id, c, why])
		return false
	var site := main.build_grid.place(t, c, Unit.Team.PLAYER, [worker])
	if site:
		_sites.append([site, worker])
	return site != null


var _sites: Array = []   ## [site, builder]: the builder is never sent back to the crystals before its site stands.


## Keeps every site's builder on it (a new builder when it died), so a gather order never steals it.
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
	if not m.forge_claimed:
		return
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var node: CrystalNode = null
	for id: StringName in [&"v1", &"v2", &"v3"]:
		var nv: Variant = m.crystal_nodes.get(id)
		if nv == null or not is_instance_valid(nv):
			continue
		var n := nv as CrystalNode
		if n and not n.is_depleted() and (id != &"v3" or MissionBase._all_dead(m.guard_groups.get(&"G4", []))):
			node = n
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
		roster.revive()   # the gate needs Vey
	if workers.size() < WORKERS and k.queue.size() < 2 and eco.crystals >= 60:
		if k.queue_unit(UnitType.find("cinder_hand")) == "" and node:
			k.set_rally_node(node)
	if workers.is_empty():
		return
	if not _built_forge and eco.crystals >= 125:
		_built_forge = _build("fire_forge", FORGE_SPOT, workers[0]) or _built_forge
		return
	var forge := _has_kind(&"forge", true) as ForgeBuilding
	if verbose and _built_forge and int(m.mission_time()) % 30 < 2:
		var f := _has_kind(&"forge")
		var bw: Variant = _sites[0][1] if not _sites.is_empty() else null
		print("      sites %d progress %.2f builder %s at %s" % [_sites.size(), f.construction_progress() if f else -1.0,
				str(bw.get(&"build_state")) if bw != null and is_instance_valid(bw) else "-",
				str((bw as Unit).global_position) if bw != null and is_instance_valid(bw) else "-"])
		print("      forge %s built %s queue %s card %s" % [f != null, forge != null, str(forge.queue.size()) if forge else "-",
				str(forge.trainable_types().map(func(t: UnitType) -> String: return "%s:%s" % [t.id, forge.can_queue(t)])) if forge else "-"])
	if forge and forge.queue.is_empty() and m.researches < 3:
		for t in forge.trainable_types():
			var line: StringName = t.get_meta(&"forge_line", &"")
			if (line == &"weapons" or line == &"armor") and forge.can_queue(t) == "" and eco.crystals >= t.cost:
				forge.queue_unit(t)
				break
	if eco.pop_cap - eco.pop_used < 5 and _hearth_i < HEARTHS.size() and eco.crystals >= 100:
		if _build("fire_hearth", HEARTHS[_hearth_i], workers[0]):
			_hearth_i += 1
			return
		_hearth_i += 1
	if not _built_hall and eco.crystals >= 200 and m.researches >= 1:
		_built_hall = _build("fire_barracks", HALL_SPOT, workers[0]) or _built_hall
		return
	if eco.crystals < 150 or (forge and m.researches < 2 and forge.queue.is_empty()):
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"fire_barracks" \
				or hall.queue.size() >= 2:
			continue
		var want: String = ["flame_guard", "ember_archer", "flame_guard", "pyre_adept"][_train_i % 4]
		hall.queue_unit(UnitType.find(want))
		_train_i += 1
		hall.set_rally_point(HOLD)


# ---------------------------------------------------------------- the plan

func _goal_pos(step: Array) -> Vector3:
	match step[0]:
		&"stone":
			return main.sunstones[int(step[1])].global_position
		&"wake":
			var s: Variant = main.sleepers.get(step[1])
			return (s as Node3D).global_position if s != null and is_instance_valid(s) else Vector3.INF
		&"fight":
			for u: Variant in main.guard_groups.get(step[1], []):
				if is_instance_valid(u) and (u as Unit).is_alive():
					return (u as Unit).global_position
			return Vector3.INF
		&"claim":
			return MissionE2_04.FORGE_POS + Vector3(0.0, 0.0, 3.5)
		&"camp":
			for b: Variant in main.camp:
				if is_instance_valid(b) and (b as Building).is_alive():
					return (b as Building).global_position
			return Vector3.INF
		&"gate":
			return MissionE2_04.GATE_SPOT
	return Vector3.INF


func _step_done(step: Array) -> bool:
	match step[0]:
		&"stone":
			return main.sunstones[int(step[1])].lit
		&"wake":
			return not main.sleepers.has(step[1])
		&"fight":
			return MissionBase._all_dead(main.guard_groups.get(step[1], []))
		&"claim":
			return main.forge_claimed
		&"camp":
			return not main.camp_standing()
		&"gate":
			return main.gate_open
	return true


## Walks Vessa through `plan`; the army fights what is near her (direct orders: the dark), else follows her.
func _run_plan(plan: Array) -> bool:
	while _plan_i < plan.size() and (_step_done(plan[_plan_i]) or _goal_pos(plan[_plan_i]) == Vector3.INF):
		_plan_i += 1
	if _plan_i >= plan.size():
		return true
	var step: Array = plan[_plan_i]
	var goal := _goal_pos(step)
	var hero := main.hero
	var foes := _enemies_near(hero.global_position, 16.0)
	if step[0] == &"fight" or step[0] == &"camp":
		foes.append_array(_enemies_near(goal, 10.0))
	if step[0] == &"gate":
		foes.append_array(_enemies_near(MissionE2_04.GATE_SPOT, 14.0))
	if not foes.is_empty():
		_army_hit(foes)
		if step[0] == &"camp" and foes.size() < 3:
			pass
		elif step[0] != &"gate" or MissionBase._flat(hero.global_position, goal) > 4.0:
			# Vessa stays behind the line.
			var c := _army_center()
			var back := hero.global_position - foes[0].global_position
			back.y = 0.0
			if MissionBase._flat(hero.global_position, foes[0].global_position) < 7.0 and not _retreat:
				_hero_to(c + back.normalized() * 3.0, 2.0)
			return false
	if step[0] == &"fight":
		_army_to(goal, 3.0)
		_hero_to(_army_center(), 4.0)
		return false
	if step[0] == &"camp":
		for u in _army():
			if u.attack_target == null:
				for b: Variant in main.camp:
					if is_instance_valid(b) and (b as Building).is_alive():
						u.command_attack(b as Building)
						break
		_hero_to(goal + Vector3(0.0, 0.0, 8.0), 3.0)
		return false
	var spot := goal + (Vector3(1.5, 0.0, 1.5) if step[0] != &"gate" else Vector3.ZERO)
	_hero_to(spot, 1.5 if step[0] != &"claim" else 2.0)
	if step[0] == &"gate":
		_army_to(MissionE2_04.GATE_SPOT + Vector3(0.0, 0.0, 8.0), 5.0)   # a ring south of the spot, never on it
	else:
		_army_to(hero.global_position + Vector3(0.0, 0.0, 4.0), 4.0)
	if main.vey and is_instance_valid(main.vey) and main.vey.is_alive() \
			and MissionBase._flat(main.vey.global_position, hero.global_position) > 6.0 and main.vey.attack_target == null:
		main.vey.command_move(hero.global_position + Vector3(2.0, 0.0, 2.0))
	return false


func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.3:
		_retreat = true
	if _retreat:
		_hero_to(_army_center() + Vector3(0.0, 0.0, 5.0), 3.0)
		if hero.hp >= hero.max_hp * 0.7:
			_retreat = false
		return
	match phase:
		&"hall1":
			if _run_plan(_plan_h1):
				_set_phase(&"hall2")
		&"hall2":
			if _run_plan(_plan_h2):
				_set_phase(&"hold")
		&"hold":
			var foes := _enemies_near(HOLD, 24.0)
			if not foes.is_empty():
				_army_hit(foes)
				_hero_to(HOLD + Vector3(0.0, 0.0, 4.0), 3.0)
			else:
				_army_to(HOLD, 5.0)
				_hero_to(HOLD + Vector3(0.0, 0.0, 4.0), 3.0)
			if m.objective_state("obj_research") == "done" and m.mission_time() >= LEAVE_AT and foes.size() < 2:
				_set_phase(&"hall3")
		&"hall3":
			_run_plan(_plan_h3)
