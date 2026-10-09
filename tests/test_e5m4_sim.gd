extends SceneTree
## Mission e5m4 timing check (docs/design/mission-e5-04.md "Lead" check: the intended steal run wins on normal in 18-22
## game-minutes). Real fights: no hero protection, no kills or time skips by the test; cinematics off (fallback end
## states), the spec lengths of e5m4_green 0:15 and e5m4_bell 0:30 are added to the reported play time.
## The scripted player (the spec's intended run): Gloom Thralls to 10, two Hovels, Shades / Nightbolts / Shadow Knights
## and Grave Hounds from the Gloom Hall; the West Banner first, the main army hidden in the Hedge Garden and sent at
## whatever banner Vessa holds away from her army whenever her bell counts; the hounds wait in the Old Orchard's shade
## and steal her home banner when she leaves it thin; Malrik's bell on three banners. `passive`: the army stays home.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e5m4_sim.gd --fixed-fps 60
## --quit-after 110000

const TASK_ID := "e5m4_sim"
const MISSION := "res://missions/mission_e5_04.tscn"
const CUTSCENE_SECONDS := {&"green": 15.0, &"bell": 30.0}
const HOME := Vector3(-36.0, 0.0, -36.0)
const RALLY := Vector3(-24.0, 0.0, -18.0)
const HEDGE := Vector3(-18.0, 0.0, 4.0)
const ORCHARD := Vector3(14.0, 0.0, 31.0)
const HOVELS: Array[Vector3] = [Vector3(-50.0, 0.0, -44.0), Vector3(-44.0, 0.0, -52.0)]
const WORKERS := 10
const HOUNDS := 5

var verbose := false
var passive := false
var h := MissionHarness.new()
var main: MissionE5_04
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _train_i := 0
var _phase_log: Array[String] = []
var _sites: Array = []
var _retreat := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = TASK_ID + ("_passive" if passive else "")
	h.protect_hero = false
	h.timeout_frames = 105000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e5m4_sim_none.json"}}) as MissionE5_04
	h.steps.add("play", _play, 104000)


func _process(_delta: float) -> bool:
	return h.tick()


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"green"] + (CUTSCENE_SECONDS[&"bell"] if h.ended == 1 else 0.0)
		var total := t + cine
		print("  %s at mission time %s (play time with cutscenes %s); banners Malrik %d Vessa %d; spoils %d; charges %d; Vessa yields %d" % [
				"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t), MissionE5Base.mmss(total), m.owned(0), m.owned(1),
				m.spoils, m.charges, m.vessa_yields])
		print("  phases %s; spotlight %s" % [", ".join(_phase_log), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		var k: Variant = m.hero.killer
		print("  Malrik's killer %s at %s; foes within 15 m %d" % [str((k as Node).name) if k != null and is_instance_valid(k) else "-", str(m.hero.global_position), _foes_near(m.hero.global_position, 15.0).size()])
		if passive:
			h.check(h.ended == 0 and t >= 300.0, "passive run: %s at %s (expected a defeat to Vessa's bell)" % [
					"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t)])
			return true
		h.check(h.ended == 1, "defeat at %.0f s" % t)
		h.check(total >= 960.0 and total <= 1380.0, "play time %s outside ~16-23 min" % MissionE5Base.mmss(total))
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
		print("    t=%s malrik %3.0f/%3.0f L%d | army %2d hounds %d w%d | crystals %4d pop %d/%d | banners M%d V%d bell %.0f/%.0f | V army %d phase %d" % [
				MissionE5Base.mmss(m.mission_time()), m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(), _hounds().size(),
				_workers().size(), eco.crystals, eco.pop_used, eco.pop_cap, m.owned(0), m.owned(1), m.bell[0], m.bell[1],
				m._vessa_army().size(), m.v_phase])
	if verbose and int(m.mission_time()) % 60 == 0 and m.mission_time() > 100.0:
		var z := m.banners[&"bn_orrery"] as MissionZone
		print("    DEBUG orrery owner %d counts %s progress %.2f side %d contested %s vc %s" % [z.owner_side, str(z.counts), z.progress, z.capture_side, z.contested, str(_v_centroid())])
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


func _hounds() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _soldiers():
		if u.unit_type and u.unit_type.id == &"grave_hound":
			out.append(u)
	return out


func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _soldiers():
		if not (u.unit_type and u.unit_type.id == &"grave_hound"):
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
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not u.is_worker() \
				and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _build(type_id: String, at: Vector3, worker: Unit) -> bool:
	var t := BuildingType.find(type_id)
	var c := main.build_grid.find_spot(t, at, 0)
	if c == Vector3.INF:
		return false
	var site := main.build_grid.place(t, c, Unit.Team.PLAYER, [worker])
	if site:
		_sites.append([site, worker])
	return site != null


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var m := main
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	_sites = _sites.filter(func(r: Array) -> bool: return is_instance_valid(r[0]) and (r[0] as Building).is_alive() \
			and not (r[0] as Building).is_constructed())
	var busy: Array = []
	for r: Array in _sites:
		var w: Variant = r[1]
		if is_instance_valid(w) and (w as Unit).is_alive():
			busy.append(w)
			if not bool((w as Unit).call(&"is_building")) and not (w as Unit).has_move_order():
				(w as Unit).call(&"command_build", r[0])
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
				node = m.node_of(0, "x")
			if node:
				w.call(&"command_gather", node)
	var k := m.keep
	if k == null or not k.is_alive():
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= 50:
		var node: CrystalNode = m.node_of(0, "a")
		if k.queue_unit(UnitType.find("gloom_thrall")) == "" and node:
			k.set_rally_node(node)
	var free_w: Unit = null
	for w in workers:
		if not busy.has(w):
			free_w = w
			break
	var hovels := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and b.building_type.id == &"shadow_hovel").size()
	if free_w and eco.pop_cap - eco.pop_used < 5 and hovels < 2 and eco.crystals >= 80 and _sites.is_empty():
		_build("shadow_hovel", HOVELS[hovels], free_w)
		return
	var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and b.building_type.id == &"shadow_barracks").size()
	if free_w and halls < 2 and eco.crystals >= 160 and m.mission_time() > 90.0 and _sites.is_empty():
		_build("shadow_barracks", Vector3(-40.0, 0.0, -28.0), free_w)
		return
	if free_w and halls < 3 and eco.crystals >= 160 and m.mission_time() > 420.0 and _sites.is_empty():
		_build("shadow_barracks", Vector3(-42.0, 0.0, 8.0), free_w)   # a drop-off by the expansion node
		return
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"shadow_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 80:
			continue
		var want := "shade"
		if _hounds().size() < HOUNDS:
			want = "grave_hound"
		else:
			var mix: Array = ["shade", "nightbolt", "shade", "shadow_knight", "nightbolt"]
			want = mix[_train_i % mix.size()]
		if hall.queue_unit(UnitType.find(want)) == "":
			_train_i += 1
		hall.set_rally_point(RALLY)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"umbral_shroud", &"soul_siphon", &"shadow_lance"]:
			if w.learn_spell(id) == "":
				break
	if w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		return
	if _foes_near(w.global_position, 12.0).is_empty():
		return
	var s: Dictionary = w.spell_caster.call(&"suggest_cast")
	var id := StringName(str(s.get("spell_id", "")))
	if id != &"":
		w.command_cast(id, s.get("target"))


# ---------------------------------------------------------------- the plan

func _set_phase(p: String) -> void:
	if _phase_log.size() >= 2 and _phase_log[-2].begins_with(p + "@"):
		return
	if _phase_log.is_empty() or not _phase_log[-1].begins_with(p + "@"):
		_phase_log.append("%s@%s" % [p, MissionE5Base.mmss(main.mission_time())])


func _bpos(id: StringName) -> Vector3:
	return (main.banners[id] as MissionZone).global_position


func _owner(id: StringName) -> int:
	return (main.banners[id] as MissionZone).owner_side


## The group goes to `at`: fights what is there, else stands in the ring.
func _send(units: Array, at: Vector3, r := 9.0) -> void:
	var foes := _foes_near(at, r)
	for v: Variant in units:
		var u := v as Unit
		if not foes.is_empty():
			if u.attack_target == null or u.attack_target is Building:
				u.command_attack_move(foes[0].global_position)
		elif MissionBase._flat(u.global_position, at) > 3.5 and not u.has_move_order():
			u.command_move(at + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0)))


func _v_centroid() -> Vector3:
	var army := main._vessa_army()
	if army.is_empty():
		return Vector3(30.0, 0.0, 28.0)
	var c := Vector3.ZERO
	for u in army:
		c += u.global_position
	return c / float(army.size())


func _plan() -> void:
	var m := main
	var hero := m.hero
	var army := _army()
	var hounds := _hounds()
	var t := m.mission_time()
	if not _retreat and hero.hp < hero.max_hp * 0.6:
		_retreat = true
	if _retreat and hero.hp >= hero.max_hp * 0.85:
		_retreat = false
	if passive:
		_set_phase("passive")
		_send(army + hounds, HOME + Vector3(6.0, 0.0, 6.0), 12.0)
		return
	var vc := _v_centroid()
	var her := m._vessa_army().size()
	# --- the main army waits in the long shadow by its home banner; it defends that banner, and takes the banner
	# Vessa holds farthest from her army whenever that army is away (her charge, her retakes) or her bell counts.
	var goal := _bpos(&"bn_shadow") + Vector3(-3.0, 0.0, -3.0)
	var why := "wait"
	if _owner(&"bn_west") == -1 and MissionBase._flat(vc, _bpos(&"bn_west")) > 25.0:
		goal = _bpos(&"bn_west")
		why = "west"
	var best := &""
	var far := -1.0
	for id: StringName in [&"bn_west", &"bn_orrery", &"bn_east"]:
		if _owner(id) == 1:
			var d := MissionBase._flat(_bpos(id), vc)
			if d > far:
				far = d
				best = id
	var late := t >= m.bell_from() - 90.0   # build up at home until the bell is near, then race
	if late and best != &"" and far > 22.0 and army.size() >= 6:
		goal = _bpos(best)
		why = "take_%s" % best
	elif late and best != &"" and m.bell[1] > 0.0 and army.size() >= her + 2:
		goal = _bpos(best)
		why = "break_%s" % best
	# The bell opens soon (or counts): break her three / make his three with everything.
	if t >= m.bell_from() - 75.0 and best != &"" and (m.owned(1) >= 3 or m.owned(0) < 3):
		goal = _bpos(best)
		why = "race_%s" % best
	elif t >= m.bell_from() - 75.0 and m.owned(0) < 3:
		for id: StringName in [&"bn_west", &"bn_east", &"bn_orrery"]:
			if _owner(id) == -1:
				goal = _bpos(id)
				why = "race_%s" % id
				break
	if _foes_near(_bpos(&"bn_shadow"), 14.0).size() >= 2 and _foes_near(_bpos(&"bn_shadow"), 14.0).size() * 4 <= army.size():
		goal = _bpos(&"bn_shadow")
		why = "defend"
	# Never meet her whole army head-on: when it comes for us, take what she left (or wait by the keep).
	if MissionBase._flat(vc, goal) < 18.0 and her * 2 > army.size():
		if best != &"" and MissionBase._flat(_bpos(best), vc) > 24.0:
			goal = _bpos(best)
			why = "swap_%s" % best
		else:
			goal = HOME + Vector3(4.0, 0.0, 4.0)
			why = "keep"
	for w in _workers():   # raiders at the workers: everyone home
		if _foes_near(w.global_position, 12.0).size() >= 2:
			goal = w.global_position
			why = "workers"
			break
	_set_phase(why)
	_send(army, goal)	# --- the hounds: the Orchard's shade, then her home banner when it is thin.
	if t >= 150.0 and hounds.size() >= 3:
		var fire := _bpos(&"bn_fire")
		var guards := _foes_near(fire, 9.0).size()
		if _owner(&"bn_fire") != 0 and guards <= 2 and (m.v_phase == 4 or t >= 540.0):
			_set_phase("steal")
			_send(hounds, fire, 9.0)
		elif _owner(&"bn_fire") == 0:
			_send(hounds, fire, 9.0)
		elif MissionBase._flat(vc, ORCHARD) > 22.0:
			_send(hounds, ORCHARD, 6.0)
		else:
			_send(hounds, goal)
	else:
		_send(hounds, goal)
	# --- Malrik with the main army (he counts 2 on a banner), home when hurt.
	if _retreat or _foes_near(hero.global_position, 14.0).size() >= 4:   # her charge: under the keep's arrows
		if MissionBase._flat(hero.global_position, HOME) > 4.0:
			hero.command_move(HOME)
		return
	var c := _bpos(&"bn_shadow") + Vector3(-5.0, 0.0, -5.0)   # Malrik keeps the home banner, in the long shadow
	var foes := _foes_near(hero.global_position, 10.0)
	if not foes.is_empty():
		if hero.attack_target == null:
			hero.command_attack(foes[0])
	elif MissionBase._flat(hero.global_position, c) > 3.0:
		hero.command_move(c)
