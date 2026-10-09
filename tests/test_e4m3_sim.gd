extends SceneTree
## Mission e4m3 timing check (docs/design/mission-e4-03.md "Lead" check: a scripted headless run on normal grows the
## five groves and holds, `victory=true` in 22-26 game-minutes; the G3 fight leaves Ysolde alive). Real fights: no hero
## protection, no kills or time skips by the test; cinematics off (fallback end states), the spec lengths of
## e4m3_arrival 0:15, e4m3_aldra 0:10, e4m3_shoot 0:12 and e4m3_spring 0:35 are added to the reported play time.
## The scripted player (human-like): Spriglings to 11, Seed Hollows, a second Grove Hall, the Citadel when it can, 2 Briar
## Rocs, Thornlings / Burr Slingers / Vinelashers / Oathkeepers / Bloomtenders; the army takes the groves in order
## (Hollowfen, Stagwatch, the Heartglade, Fernhollow, Mossgate): guards and totems first, then Ysolde plants; 3 keepers
## stay on every planted grove (they also hold it while it takes root); once all five are green the army answers
## whichever grove is attacked. Aldra and Torvald are focused by the ranged units.
## `-- --rush` (tests/test_e4m3_rush_sim.gd): the same player pushes every grove at once from 0:00 (no PUSH_AT pacing);
## it must still win and take at least RUSH_MIN game-minutes. It attacks a guarded grove once its free army reaches
## RUSH_ARMY, waits for 8 more after each repulse (army under half of that; it goes anyway once the army has stopped
## growing for a minute), and pulls Ysolde back at 60 % HP.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e4m3_sim.gd --fixed-fps 60
## --quit-after 130000

const TASK_ID := "e4m3_sim"
const MISSION := "res://missions/mission_e4_03.tscn"
const CUTSCENE_SECONDS := {&"arrival": 15.0, &"aldra": 10.0, &"shoot": 12.0, &"spring": 35.0}
const ORDER: Array[StringName] = [&"hollowfen", &"stagwatch", &"heartglade", &"fernhollow", &"mossgate"]
## Human pacing (the spec's intended rhythm: Hollowfen at once, Stagwatch ~5:00, the Heartglade after the Citadel,
## Fernhollow ~14:00, Mossgate with the Rocs ~19:00): the army builds up before each push. A player who rushes every
## grove at once finished in ~7 minutes at the spec's numbers (2026-10-08 run: all five green by 4:07); since the
## sturdier guards / totems and the 30 s rooting hold it must take at least RUSH_MIN (see the mission header).
const PUSH_AT: Array[float] = [0.0, 300.0, 570.0, 840.0, 1140.0]
const RUSH_MIN := 960.0
const RUSH_ARMY := 40      ## the rusher first attacks a frozen grove with this many free soldiers (no clock), +8 per repulse
const RUSH_FLOOR := 12     ## ... but with at least this many it goes once the army stopped growing for a minute
const RALLY := Vector3(30.0, 0.0, 30.0)
const WORKERS := 11
const KEEPERS := 3
const HOLLOWS: Array[Vector3] = [Vector3(56.0, 0.0, 40.0), Vector3(54.0, 0.0, 60.0), Vector3(36.0, 0.0, 60.0)]
const HALL2 := Vector3(30.0, 0.0, 40.0)

var verbose := false
var rush := false
var _rush_need := RUSH_ARMY
var _rush_best := 0
var _rush_push := 0        ## free army when the current push started
var _rush_best_at := 0.0
var h := MissionHarness.new()
var main: MissionE4_03
var phase := &"build"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _hollow_i := 0
var _train_i := 0
var _phase_log: Array[String] = []
var _retreat := false
var _sites: Array = []
var _keepers := {}        ## grove id -> Array of units
var _wounded := {}
var _g3_hero_hp := 1.0
var killers := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	verbose = args.has("--verbose")
	rush = rush or args.has("--rush")
	var i := args.find("--seed")
	if i >= 0 and i + 1 < args.size():
		seed(int(args[i + 1]))
	h.task_id = "e4m3_rush_sim" if rush else TASK_ID
	h.protect_hero = false
	h.timeout_frames = 125000
	var sets := {"campaign_save_path": "user://test_e4m3_sim_none.json"}
	for a in args:   # tuning: -- --ghp=3.0 --gdmg=1.4
		if a.begins_with("--ghp="):
			sets["guard_hp_mult"] = float(a.trim_prefix("--ghp="))
		elif a.begins_with("--gdmg="):
			sets["guard_dmg_mult"] = float(a.trim_prefix("--gdmg="))
	main = h.open(self, MISSION, {"difficulty": 1, "set": sets}) as MissionE4_03
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
		_phase_log.append("%s@%s" % [p, _mmss(main.mission_time())])


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"arrival"] + (CUTSCENE_SECONDS[&"aldra"] if m.has_fired(&"E6") else 0.0) \
				+ (CUTSCENE_SECONDS[&"shoot"] if m.has_fired(&"E16") else 0.0) + (CUTSCENE_SECONDS[&"spring"] if h.ended == 1 else 0.0)
		print("  %s at mission time %s (play time with cutscenes %s); groves grown %d; a grove lost %s; spire %s; hero HP after G3 %d %%" % [
				"victory" if h.ended == 1 else "defeat", _mmss(t), _mmss(t + cine), m.groves_grown(), m.lost_a_grove,
				m.objective_state("sec_spire"), int(100.0 * _g3_hero_hp)])
		print("  phases %s; waves %s; spotlight %s" % [", ".join(_phase_log), ",".join(m.waves_fired), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  Nature losses by killer: %s" % str(killers))
		h.check(h.ended == 1, "defeat at %.0f s (%s)" % [t, phase])
		if rush and h.ended == 1:
			h.check(t >= RUSH_MIN, "the rush won too fast (%s < %s)" % [_mmss(t), _mmss(RUSH_MIN)])
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if m.has_fired(&"E6") and m.groves[&"heartglade"]["state"] != &"grown":
		_g3_hero_hp = minf(_g3_hero_hp, m.hero.hp / maxf(1.0, m.hero.max_hp))
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		var eco := Economy.for_team(0)
		var st := []
		for id in ORDER:
			var g: Dictionary = m.groves[id]
			var pct := ""
			if g["state"] == &"growing":
				pct = "%d" % int(100.0 * float(g["meter"]))
			elif g["state"] == &"rooting":
				pct = "%d" % int(100.0 * float(g["root"]))
			st.append("%s%s" % [String(g["state"]).left(4), pct])
		print("    t=%s %s ysolde %3.0f/%3.0f L%d | army %2d (w%d) T%d | crystals %4d pop %d/%d | groves %s | hold %.0f" % [
				_mmss(m.mission_time()), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _soldiers().size(),
				_workers().size(), m.keep.tier if m.keep else 0, eco.crystals, eco.pop_used, eco.pop_cap, str(st), m.hold_left])
		if not killers.is_empty():
			print("      losses so far: %s" % str(killers))
		for id in ORDER:
			if m.groves[id]["state"] == &"thawed":
				var near: Array[String] = []
				for n in m.get_tree().get_nodes_in_group(&"units"):
					var e := n as Unit
					if e and e.is_alive() and int(e.team) == Unit.Team.ENEMY and MissionBase._flat(e.global_position, MissionE4_03.GROVES[id][1]) <= 10.0:
						near.append("%s%s%s hp %d" % [e.unit_type.id if e.unit_type else e.name, " dormant" if m.is_dormant(e) else "",
								" truce" if e.has_meta(Unit.TRUCE_META) else "", int(e.hp)])
				print("      %s thawed: enemies within 10 m %s; Ysolde %.1f m" % [id, str(near),
						MissionBase._flat(m.hero.global_position, MissionE4_03.GROVES[id][1])])
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
				and u.is_commandable() and not u is Helper:
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
				and not u.has_meta(Unit.TRUCE_META) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _hero_to(at: Vector3, near := 2.0) -> void:
	if MissionBase._flat(main.hero.global_position, at) > near:
		main.hero.command_move(at)


func _hold(units: Array, at: Vector3, r: float, facing := Vector3(-1.0, 0.0, -1.0)) -> bool:
	if units.is_empty():
		return false
	var ranged: Array = units.filter(func(u: Unit) -> bool: return SimTactics.is_ranged(u))
	SimTactics.focus_wizards(ranged, [main.torvald, main.aldra], 14.0, func(w: Unit) -> bool: return not main.is_dormant(w))
	var foes := _enemies_near(at, r)
	if not foes.is_empty():
		for v: Variant in units:
			var u := v as Unit
			if u.attack_target == null or not is_instance_valid(u.attack_target):
				u.command_attack_move(foes[0].global_position)
		return true
	SimTactics.spread_to(units, at, facing)
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


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var m := main
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var workers := _workers()
	var node: CrystalNode = null
	for suffix in ["a", "b", "x", "y", "c", "d"]:
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
	var saving := k.tier < 3 and m.mission_time() >= 300.0 and not k.is_upgrading()
	if k.tier < 3 and m.mission_time() >= 330.0 and k.can_upgrade() == "":
		k.upgrade()
		return
	if workers.size() < WORKERS and k.queue.size() < 1 and eco.crystals >= (360 if saving else 40):
		if k.queue_unit(UnitType.find("sprigling")) == "" and node:
			k.set_rally_node(node)
	if workers.is_empty():
		return
	if eco.pop_cap - eco.pop_used < 6 and _hollow_i < HOLLOWS.size() and eco.crystals >= (380 if saving else 90):
		_build("nature_hollow", HOLLOWS[_hollow_i], workers[0])
		_hollow_i += 1
	var halls := Building.for_team(0).filter(func(b: Building) -> bool: return b.is_alive() and b.building_type \
			and b.building_type.id == &"nature_barracks").size()
	if halls < 2 and eco.crystals >= 200 and m.mission_time() > 60.0 and not saving:
		_build("nature_barracks", HALL2, workers[0])
	if saving and eco.crystals < 360:
		return
	if k.tier >= 3 and k.queue.size() < 2 and eco.crystals >= 380:
		var rocs := _soldiers().filter(func(u: Unit) -> bool: return u.unit_type.id == &"briar_roc").size()
		if rocs < 2:
			k.queue_unit(UnitType.find("briar_roc"))
	for b in Building.for_team(Unit.Team.PLAYER):
		var hall := b as TrainingBuilding
		if hall == null or not hall.is_alive() or not hall.is_constructed() or hall.building_type.id != &"nature_barracks" \
				or hall.queue.size() >= 2 or eco.crystals < 90:
			continue
		var mix: Array = ["thornling", "burr_slinger", "thornling", "vinelasher", "greenheart_oathkeeper", "burr_slinger",
				"bloomtender", "thornling"]
		var want: String = mix[_train_i % mix.size()]
		if hall.queue_unit(UnitType.find(want)) != "":
			hall.queue_unit(UnitType.find("thornling"))
		_train_i += 1
		hall.set_rally_point(RALLY)
	for u in _soldiers():
		var ca := u.get_node_or_null(^"CasterAbility")
		if ca and ca.has_method(&"set_autocast"):
			for sid: StringName in [&"snagroot", &"pollen_haze", &"seed_storm"]:
				if ca.has_method(&"autocast") and not bool(ca.call(&"autocast", sid)):
					ca.call(&"set_autocast", sid, true)


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"thornburst", &"wild_bloom", &"call_the_thicket"]:
			if w.learn_spell(id) == "":
				break
	if w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		return
	if _enemies_near(w.global_position, 14.0).is_empty() and w.hp > w.max_hp * 0.8:
		return
	var s: Dictionary = w.spell_caster.call(&"suggest_cast")
	var id := StringName(str(s.get("spell_id", "")))
	if id != &"":
		w.command_cast(id, s.get("target"))


# ---------------------------------------------------------------- the plan

func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * (0.6 if rush else 0.45):
		_retreat = true
	if _retreat and hero.hp >= hero.max_hp * 0.85:
		_retreat = false
	# --- keepers: 3 melee on every planted grove (a lone Rimeshield there re-rimes it).
	var kept: Array = []
	for id in ORDER:
		var g: Dictionary = m.groves[id]
		var list: Array = (_keepers.get(id, []) as Array).filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
		if MissionE4_03._planted(g):
			if list.size() < KEEPERS:
				for u in _soldiers():
					if list.size() >= KEEPERS:
						break
					if not SimTactics.is_ranged(u) and u.unit_type.id != &"briar_roc" and not _in_keepers(u) and not list.has(u):
						list.append(u)
			_hold(list, MissionE4_03.GROVES[id][1], 10.0)
		else:
			list = []
		_keepers[id] = list
		kept.append_array(list)
	var army: Array = SimTactics.pull_back_wounded(_soldiers().filter(func(u: Unit) -> bool: return not kept.has(u)),
			RALLY, _wounded, 0.5)
	var goal := Vector3.INF
	var target := &""
	for i in ORDER.size():
		var st: StringName = m.groves[ORDER[i]]["state"]
		if (st == &"frozen" or st == &"thawed") and (rush or m.mission_time() >= PUSH_AT[i]):
			target = ORDER[i]
			break
	# A planted grove under attack comes first.
	var threatened := &""
	for id in ORDER:
		var st: StringName = m.groves[id]["state"]
		if MissionE4_03._planted(m.groves[id]) and _enemies_near(MissionE4_03.GROVES[id][1], 12.0).size() >= 2:
			threatened = id
			break
	if threatened != &"":
		_set_phase(StringName("defend_%s" % threatened))
		var at: Vector3 = MissionE4_03.GROVES[threatened][1]
		_hold(army, at, 16.0)
		goal = at + Vector3(6.0, 0.0, 6.0)
	elif target != &"" and rush and m.groves[target]["state"] == &"frozen" \
			and (m.groves[target]["guards"] as Array).any(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive()) \
			and _rush_waits(army.size(), target):
		_set_phase(&"rush_regroup")
		_hold(army, RALLY, 16.0)
		goal = RALLY + Vector3(0.0, 0.0, 6.0)
	elif target != &"":
		_set_phase(StringName("take_%s" % target))
		var at: Vector3 = MissionE4_03.GROVES[target][1]
		var g: Dictionary = m.groves[target]
		# Thawed: the army stands on the far side (away from home, where Ysolde comes from): a big army packed on the
		# centre or on her way blocks her from the planting spot.
		var aside: Vector3 = at + (at - RALLY).normalized() * 12.0
		var busy := _hold(army, aside if g["state"] == &"thawed" else at, 16.0 if g["state"] == &"thawed" else 14.0)
		if not busy and g["state"] == &"frozen":
			var totems: Array = (g["totems"] as Array).filter(func(t: Variant) -> bool: return is_instance_valid(t) and (t as Building).is_alive())
			if not totems.is_empty():
				for v: Variant in army:
					var u := v as Unit
					if u.attack_target == null or not is_instance_valid(u.attack_target):
						u.command_attack(totems[0])
		if g["state"] == &"thawed" and _enemies_near(at, 10.0).is_empty():
			goal = at   # plant
		else:
			goal = at + (Vector3(11.0, 0.0, 11.0) if rush else Vector3(7.0, 0.0, 7.0))
	else:
		_set_phase(&"hold" if m.objective_state("obj_hold") == "active" else &"guard")
		var at: Vector3 = MissionE4_03.GROVES[&"heartglade"][1] if MissionE4_03._planted(m.groves[&"heartglade"]) else RALLY
		for id in ORDER:   # a grove still taking root needs holders more than anything
			if m.groves[id]["state"] == &"rooting":
				at = MissionE4_03.GROVES[id][1]
				break
		_hold(army, at, 18.0)
		goal = at + Vector3(5.0, 0.0, 5.0)
	if _retreat:
		_hero_to(RALLY, 3.0)
	elif goal != Vector3.INF:
		_hero_to(goal, 1.5)


## The rusher still needs an army: it goes as soon as it has _rush_need free soldiers; beaten back (under half of
## what it went in with), it learns and waits for 8 more next time.
func _rush_waits(n: int, target: StringName) -> bool:
	if phase == StringName("take_%s" % target):
		if _rush_push == 0:
			_rush_push = n
		if n >= float(_rush_push) * 0.5:
			return false
		_rush_need = mini(_rush_need + 8, 70)
		_rush_best = 0
		_rush_push = 0
		return true
	_rush_push = 0
	if n > _rush_best:
		_rush_best = n
		_rush_best_at = main.mission_time()
	# The army stopped growing for a minute (the income is gone): go with what there is.
	if n >= RUSH_FLOOR and main.mission_time() - _rush_best_at > 60.0:
		return false
	return n < _rush_need


func _in_keepers(u: Unit) -> bool:
	for id: StringName in _keepers:
		if (_keepers[id] as Array).has(u):
			return true
	return false
