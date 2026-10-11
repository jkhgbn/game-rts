extends SceneTree
## Mission e5m3 timing check (docs/design/mission-e5-03.md "Lead" check: scripted runs on normal end `victory=true` in
## 12-15 game-minutes). Real fights: no hero protection, no kills or time skips by the test; cinematics off (fallback
## end states), the spec lengths of e5m3_wickmoor 0:12 and e5m3_found 0:45 are added to the reported play time (the
## bridge c_e5_turn plays before the scene).
## The scripted player (careful, not perfect): a route of steps around the churchyard: call the old graves with the
## candle pinched, read the tombstones and the three secrets with it lit, Soot / Bramble / the Shades at his heels and
## fighting what comes close, back to the hut to heal when hurt, and the bell at midnight, then the Reeve. `rush`: the
## direct route (crypts in order, no graves, no tombstones, straight to the bell).
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e5m3_sim.gd --fixed-fps 60
## --quit-after 80000

const TASK_ID := "e5m3_sim"
const MISSION := "res://missions/mission_e5_03.tscn"
const CUTSCENE_SECONDS := {&"wickmoor": 12.0, &"found": 45.0}
const RUSH_MIN := 660.0   ## a rush must not win faster than this (play time; the bell waits for midnight)
## Route: [kind, position, arg]. kind: "go" (walk there), "grave" (index), "stone" (index), "secret" (crypt id), "bell".
const ROUTE := [
	["grave", Vector3(-36, 0, 14), 0],
	["stone", Vector3(-20, 0, 26), 0],
	["secret", Vector3(-28, 0, -27), &"C1"],
	["grave", Vector3(14, 0, -36), 1],
	["stone", Vector3(-6, 0, -30), 2],
	["secret", Vector3(27, 0, -29), &"C2"],
	["stone", Vector3(30, 0, -14), 4],
	["grave", Vector3(36, 0, 10), 2],
	["secret", Vector3(28, 0, 25), &"C3"],
	["stone", Vector3(34, 0, 30), 5],
	["stone", Vector3(10, 0, 30), 3],
	["bell", Vector3(0, 0, 5), 0],
]
const RUSH_ROUTE := [
	["secret", Vector3(-28, 0, -27), &"C1"],
	["secret", Vector3(27, 0, -29), &"C2"],
	["secret", Vector3(28, 0, 25), &"C3"],
	["bell", Vector3(0, 0, 5), 0],
]

var verbose := false
var rush := false
var h := MissionHarness.new()
var main: MissionE5_03
var _step := 0
var _tick := 0.0
var _last_print := -1
var _phase_log: Array[String] = []
var _retreat := false
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e5m3_sim_none.json"}}) as MissionE5_03
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
	var key := "%d:%s" % [_step, who]
	killers[key] = int(killers.get(key, 0)) + 1


func _process(_delta: float) -> bool:
	return h.tick()


func _route() -> Array:
	return RUSH_ROUTE if rush else ROUTE


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var cine: float = CUTSCENE_SECONDS[&"wickmoor"] + (CUTSCENE_SECONDS[&"found"] if h.ended == 1 else 0.0)
		var total := t + cine
		print("  %s at mission time %s (play time with cutscenes %s); secrets %s; tombstones %d; graves %d; gifts %d; cries %d alarm %d wakes %d; L%d" % [
				"victory" if h.ended == 1 else "defeat", MissionE5Base.mmss(t), MissionE5Base.mmss(total), str(m.secrets_read),
				m.stones_read.size(), m.graves_called.size(), m.gifts_taken.size(), m.cries, m.alarm, m.wakes, m.hero.level])
		print("  phases %s; spotlight %s" % [", ".join(_phase_log), h.spotlight_log])
		print("  objectives %s" % str(h.objective_log))
		print("  losses by step:killer %s" % str(killers))
		var around: Array = []
		for n in m.get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and u.is_alive() and int(u.team) != 0 and MissionBase._flat(u.global_position, m.hero.global_position) < 14.0:
				around.append("%s/%s %.0f" % [u.name, str(u.get_meta(&"e5_mode", "-")), MissionBase._flat(u.global_position, m.hero.global_position)])
		print("  at the end: killer %s, around %s" % [str(m.hero.killer.name) if m.hero.killer else "-", str(around)])
		if rush:
			h.check(h.ended == 0 or total >= RUSH_MIN, "rush won in %s (< %s)" % [MissionE5Base.mmss(total), MissionE5Base.mmss(RUSH_MIN)])
			return true
		h.check(h.ended == 1, "defeat at %.0f s (step %d)" % [t, _step])
		h.check(total >= 690.0 and total <= 930.0, "play time %s outside ~11:30-15:30" % MissionE5Base.mmss(total))
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 5.0) != _last_print and (m.mission_time() < 120.0 or int(m.mission_time()) % 30 < 5):
		_last_print = int(m.mission_time() / 5.0)
		print("    t=%s step %d malrik %3.0f/%3.0f L%d candle %s | army %d | secrets %d stones %d | alarm %d dark lamps %d | near wardens %d hunting %s" % [
				MissionE5Base.mmss(m.mission_time()), _step, m.hero.hp, m.hero.max_hp, m.hero.level, m.candle_lit,
				_army().size(), m.secrets_read.size(), m.stones_read.size(), m.alarm, m.dark_lamps.size(), _wardens_near(m.hero.global_position, 12.0).size(), m._hunting()])
	_spells()
	_plan()
	return false


func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in main.units_of(Unit.Team.PLAYER):
		if u != main.hero and u != main.keep:
			out.append(u)
	return out


func _foes_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) != Unit.Team.PLAYER and not main.is_dormant(u) \
				and not u.has_meta(Unit.TRUCE_META) and MissionBase._flat(u.global_position, at) <= r:
			out.append(u)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return MissionBase._flat(a.global_position, at) < MissionBase._flat(b.global_position, at))
	return out


func _spells() -> void:
	var w := main.hero as Wizard
	if w.spell_points > 0:
		for id: StringName in [&"soul_siphon", &"shadow_lance", &"umbral_shroud"]:
			if w.learn_spell(id) == "":
				break
	if w.spell_caster == null or not w.spell_caster.has_method(&"suggest_cast"):
		return
	if _foes_near(w.global_position, 10.0).is_empty():
		return
	var s: Dictionary = w.spell_caster.call(&"suggest_cast")
	var id := StringName(str(s.get("spell_id", "")))
	if id != &"":
		w.command_cast(id, s.get("target"))


func _set_phase(p: String) -> void:
	if _phase_log.size() >= 2 and _phase_log[-2].begins_with(p + "@"):
		return   # oscillating between two phases: logged once
	if _phase_log.is_empty() or not _phase_log[-1].begins_with(p + "@"):
		_phase_log.append("%s@%s" % [p, MissionE5Base.mmss(main.mission_time())])


func _candle(lit: bool) -> void:
	if main.candle_lit != lit:
		main.toggle_candle()


## Awake wardens / the Reeve within `r` of `at`.
func _wardens_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for v: Variant in main.gravewardens + [main.reeve]:
		if v != null and is_instance_valid(v) and (v as Unit).is_alive() and not main.is_dormant(v) \
				and MissionBase._flat((v as Unit).global_position, at) <= r:
			out.append(v as Unit)
	return out


## The nearest shadow spot (a zone centre that is not lit now) to `from`.
## The dark spot to run to while hurt: unlit, empty, within 30 m, as far from the foes as it is near to him.
func _safe_shadow(from: Vector3, foes: Array) -> Vector3:
	var best := Vector3.INF
	var score := -INF
	var ls := main.lights()
	for z: Array in main.zones():
		var c: Vector3 = z[0]
		var d := MissionBase._flat(c, from)
		if d > 30.0 or main.lit_at(c, ls) or not _foes_near(c, float(z[1]) + 3.0).is_empty():
			continue
		var far := 30.0
		for f: Variant in foes:
			far = minf(far, MissionBase._flat((f as Unit).global_position, c))
		var s := far - 0.5 * d
		if s > score:
			score = s
			best = c
	return best if best != Vector3.INF else _nearest_shadow(from)


func _nearest_shadow(from: Vector3) -> Vector3:
	var best := Vector3.INF
	var d := INF
	var ls := main.lights()
	for z: Array in main.zones():
		var c: Vector3 = z[0]
		if main.lit_at(c, ls) or not _foes_near(c, float(z[1]) + 4.0).is_empty():
			continue   # lit, or someone waits in it
		var dd := MissionBase._flat(c, from)
		if dd < d:
			d = dd
			best = c
	return best


func _plan() -> void:
	var m := main
	var hero := m.hero
	if not _retreat and hero.hp < hero.max_hp * 0.5:
		_retreat = true
	if _retreat and hero.hp >= hero.max_hp * 0.95:
		_retreat = false
	var army := _army()
	var foes := _foes_near(hero.global_position, 9.0)
	# The army: fight what comes close to Malrik, else walk at his heels (Shades keep out of his candle's light).
	for u in army:
		if not foes.is_empty():
			if u.attack_target == null:
				u.command_attack(foes[0])
		elif MissionBase._flat(u.global_position, hero.global_position) > (6.0 if m.candle_lit else 4.0) and not u.has_move_order():
			var off := Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
			if m.shades.has(u) and m.candle_lit:
				off = (u.global_position - hero.global_position).normalized() * 5.0
			u.command_move(hero.global_position + off)
	# Two or fewer on him: fight (running from wardens as fast as he is only gets him hit in the back).
	if not foes.is_empty() and foes.size() <= 2 and not _retreat:
		_candle(false)
		if hero.attack_target == null or not is_instance_valid(hero.attack_target):
			hero.command_attack(foes[0])
		return
	# Three or more on him (a waking town): a careful player runs for the dark instead of trading blows (it hides and
	# heals him; 2026-10-11, a run that fought four hunters at 2:31 died). Not in the Final: the Reeve is the goal.
	if foes.size() > 2 and not _retreat and not rush and _step < _route().size():
		_set_phase("flee")
		_candle(false)
		var dark := _safe_shadow(hero.global_position, foes)
		if dark == Vector3.INF:
			_go_home()
		elif MissionBase._flat(hero.global_position, dark) > 1.0:
			hero.command_move(dark)
		return
	if _retreat:
		_set_phase("heal")
		if not foes.is_empty() and MissionBase._flat(hero.global_position, MissionE5_03.HUT) < 7.0:
			if hero.attack_target == null:
				hero.command_attack(foes[0])   # cornered at home: fight by the fire
			return
		_candle(false)
		var s := _safe_shadow(hero.global_position, foes)   # the dark heals him
		if s == Vector3.INF:
			_go_home()
		elif MissionBase._flat(hero.global_position, s) > 1.0:
			hero.command_move(s)
		return
	var route := _route()
	if _step >= route.size():
		_final_fight()
		return
	var row: Array = route[_step]
	var kind := String(row[0])
	var at: Vector3 = row[1]
	_set_phase("%d:%s" % [_step, kind])
	var done := false
	match kind:
		"go":
			done = MissionBase._flat(hero.global_position, at) < 2.0
		"grave":
			done = m.graves_called.has(int(row[2]))
			_candle(false)
		"stone":
			done = m.stones_read.has(int(row[2]))
			_candle(MissionBase._flat(hero.global_position, at) < 4.0)
		"secret":
			done = m.secrets_read.has(String(row[2]))
			_candle(MissionBase._flat(hero.global_position, at) < 4.0)
		"bell":
			done = m.has_fired(&"E13")
			_candle(MissionBase._flat(hero.global_position, at) < 4.0)
	if done:
		_step += 1
		return
	if not foes.is_empty():
		if hero.attack_target == null:
			hero.command_attack(foes[0])
		return
	if rush:
		if MissionBase._flat(hero.global_position, at) > 1.0:
			hero.command_move(at)
		return
	# Patience: home at the hut (the yard is shadow, its fire heals) while the town is restless, Malrik is hurt or a
	# patrol walks near the next job; a standing guard at the job is taken out first.
	var patrols: Array = []   # loud and patient: fights what comes, never waits for a patrol to pass
	var posted := _wardens_near(at, 8.0).filter(func(w: Unit) -> bool: return w.get_meta(&"e5_mode", &"") == &"post")
	var bell_wait := kind == "bell" and (m.bell_at() - m.mission_time() > 20.0 or hero.hp < hero.max_hp * 0.95)
	if bell_wait:
		_set_phase("home")
		_go_home()
		return
	if hero.hp < hero.max_hp * 0.75:
		_set_phase("lie_low")   # in the dark until healed and the town has calmed down
		_candle(false)
		var s := _nearest_shadow(hero.global_position)
		if s == Vector3.INF:
			_go_home()
		elif MissionBase._flat(hero.global_position, s) > 1.0:
			hero.command_move(s)
		return
	if not posted.is_empty() and kind != "bell":
		for u in army + [hero]:
			if u.attack_target == null:
				u.command_attack(posted[0])
		return
	if MissionBase._flat(hero.global_position, at) > 1.0:
		hero.command_move(at)


func _go_home() -> void:
	_candle(false)
	var to := MissionE5_03.HUT + Vector3(2.0, 0.0, -2.0)
	if MissionBase._flat(main.hero.global_position, to) > 1.5:
		main.hero.command_move(to)

## After the bell: the Reeve and the porch guard; everyone on the Reeve.
func _final_fight() -> void:
	var m := main
	_set_phase("reeve")
	_candle(false)
	if m.reeve == null or not is_instance_valid(m.reeve) or m.is_dormant(m.reeve):
		return
	var foes := _foes_near(m.hero.global_position, 14.0)   # the porch guards first (nearest), then the Reeve
	var target: Unit = foes[0] if not foes.is_empty() else m.reeve
	for u in _army():
		if u.attack_target == null:
			u.command_attack(target)
	if m.hero.attack_target == null:
		m.hero.command_attack(target)
