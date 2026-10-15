extends SceneTree
## Task 8.A1 (Nature bot + any-kingdom bot vs bot), scenes/skirmish.tscn.
## Part 0 (instant): the Nature profiles (data/ai/nature_*.tres = AIProfile.nature()), the kingdom -> profile
##   mapping, Ysolde's item lists.
## Part 1 (Nature available): a normal Nature bot (ENEMY) against an idle player, 5:30: Grove Hall at 0:00,
##   3 Spriglings queued at once, gathers, trains Nature soldiers, a Thornling scouts from 1:30, the V3 row,
##   expansion (X1) placed by 5:00.
## Part 2: the retreat / regrow rule (Nature bot, or a Shadow bot with the Nature profile if Nature is missing):
##   10 soldiers at the rally, wardens removed; 3 s after the launch the group is hurt to 45 %: it retreats (at
##   < 50 % of its launch HP) and attacks again only at >= 85 % average HP or after 45 s at the rally (balance-2).
## Part 3: bot vs bot matrix, both sides normal bots of any kingdom (PLAYER team too), 12 game-minutes max each:
##   winner / time or "no winner", army sizes. Pairs "player:enemy". Unavailable kingdoms are skipped.
## Run:  godot --headless --path . -s tests/test_8_a1.gd --fixed-fps 60 --quit-after 200000
##   Options after `--`: --only=nature | --only=matrix, --pairs=fire:ice,shadow:nature, --minutes=12, --full
## Early stop (fast CI, 2026-10-02): part 1 ends as soon as every value it judges is recorded (each is the first time
##   seen, so the verdict cannot change after); before, it always ran to 5:30. --full restores the 5:30 run.
##   Part 2 already ends at the second attack; the matrix (part 3) runs its full minutes (its runtime is the
##   bot-vs-bot coverage).

const TASK_ID := "8.A1"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const NATURE_TIME := 330.0
const REGROW_TIMEOUT := 200.0
const DEFAULT_PAIRS: Array[String] = ["fire:ice", "shadow:nature", "ice:nature"]
const RALLY := Vector3(30.0, 0.0, -30.0)

var main: Node
var bot: Node
var bot2: Node
var part := 0
var _queue: Array = []              # parts still to run: [kind, arg]
var _wait := 0
var _gap := 0
var _t := 0.0
var _frame := 0
var _errors: Array[String] = []
var _notes: Array[String] = []
var _minutes := 12.0
var _nature_ok := false
var _full := false                   # --full: part 1 runs to NATURE_TIME even once its verdict is known

# part 1
var _n := {}
var _keep_queue_max := 0
# part 2
var _p2_setup := false
var _p2_hurt_at := -1.0
var _p2_launch := -1.0
var _p2_kingdom := &""
# part 3
var _pair := ""
var _pk := &""
var _ek := &""
var _army_max := {PLAYER: 0, ENEMY: 0}
var _results: Array[String] = []
var _casts := {}


func _initialize() -> void:
	var only := ""
	var pairs: Array[String] = DEFAULT_PAIRS.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a.begins_with("--pairs="):
			pairs.clear()
			for p in a.trim_prefix("--pairs=").split(",", false):
				pairs.append(p)
		elif a.begins_with("--minutes="):
			_minutes = a.trim_prefix("--minutes=").to_float()
		elif a == "--full":
			_full = true
	_nature_ok = _kingdom_ok(&"nature")
	_part0()
	if only != "matrix":
		if _nature_ok:
			_queue.append([1, ""])
		else:
			_notes.append("part 1 skipped (Nature kingdom not available)")
		_queue.append([2, ""])
	if only != "nature":
		for p in pairs:
			_queue.append([3, p])
	_next_part()


## True when the skirmish can start this kingdom (8.S2 Skirmish.kingdom_available, else Shadow / Ice only).
func _kingdom_ok(k: StringName) -> bool:
	var probe: Node = load(SCENE).instantiate()
	var ok := false
	if probe.has_method(&"kingdom_available"):
		ok = bool(probe.call(&"kingdom_available", k))
	else:
		ok = k == &"shadow" or k == &"fire" or (k == &"ice" and &"enemy_kingdom" in probe)
	probe.free()
	return ok


# ---------------------------------------------------------------- part 0: profiles

func _part0() -> void:
	if AIProfile.id_for_faction(&"nature") != &"nature_default":
		_errors.append("id_for_faction(nature) = %s" % AIProfile.id_for_faction(&"nature"))
	if AIProfile.id_for_faction(&"fire") != &"shadow_default" or AIProfile.id_for_faction(&"ice") != &"ice_default":
		_errors.append("id_for_faction broke for fire / ice")
	var fields := ["id", "decision_interval", "reaction_delay", "build_delay", "worker_target_home",
			"worker_target_expanded", "worker_target_x2", "second_expansion", "queue_depth", "attack_ratio",
			"min_attack_pop", "memory_seconds", "scout_interval", "malrik_joins", "no_reserve_at_cap", "spell_order",
			"item_build", "potion_stock", "profile_id", "retreat_hp", "expand_time", "mix_default", "mix_vs_ranged",
			"mix_vs_melee", "scout_worker_before", "scout_fast", "retreat_spell", "opening_workers", "heavy_crystals",
			"heavy_soldier_pop", "regrow_hp", "regrow_wait", "first_scout_time", "tower1_time", "tower2_time",
			"defend_radius", "build_walls"]
	for d in 3:
		var path := "res://data/ai/nature_%s.tres" % AIProfile.DIFFICULTY_NAMES[d]
		if not ResourceLoader.exists(path):
			_errors.append("missing %s" % path)
			continue
		var from_file := AIProfile.for_id(&"nature_default", d)
		var code := AIProfile.nature(d)
		for f in fields:
			var a: Variant = from_file.get(f)
			var b: Variant = code.get(f)
			var same: bool = is_equal_approx(float(a), float(b)) if (a is float or b is float) else a == b
			if not same:
				_errors.append("%s: %s = %s, code says %s" % [path.get_file(), f, str(a), str(b)])
	var n := AIProfile.nature(1)
	if not is_equal_approx(n.attack_ratio, 1.2) or n.worker_target_home != 7 or n.worker_target_expanded != 9:
		_errors.append("nature_normal: attack_ratio %.2f, workers %d / %d (want 1.2, 7 / 9, balance-2)" % [n.attack_ratio,
				n.worker_target_home, n.worker_target_expanded])
	if not is_equal_approx(n.retreat_hp, 0.5) or not is_equal_approx(n.regrow_hp, 0.85) or n.expand_time != 270.0 or n.regrow_wait != 45.0:
		_errors.append("nature_normal retreat / regrow / X1 time wrong")
	var e := AIProfile.nature(0).item_build
	var h := AIProfile.nature(2).item_build
	if e.size() != 4 or e[2] != "bloomcaller_staff":
		_errors.append("nature_easy items %s" % str(e))
	if h.size() != n.item_build.size() + 1 or h[h.find("heart_of_the_grove") + 1] != "ember_draught":
		_errors.append("nature_hard items %s" % str(h))
	for id in n.item_build:
		if not ResourceLoader.exists("res://data/items/%s.tres" % id):
			_notes.append("item %s not in data/items yet (the bot skips it)" % id)
	print("part 0: Nature profiles checked (kingdom Nature available: %s)" % str(_nature_ok))


# ---------------------------------------------------------------- scene handling

func _next_part() -> void:
	if _queue.is_empty():
		_finish()
		return
	var p: Array = _queue.pop_front()
	part = int(p[0])
	_wait = 0
	_frame = 0
	bot = null
	bot2 = null
	main = load(SCENE).instantiate()
	match part:
		1:
			_set_kingdoms(&"fire", &"nature")
		2:
			_p2_kingdom = &"nature" if _nature_ok else &"shadow"
			_set_kingdoms(&"fire", _p2_kingdom)
		3:
			_pair = str(p[1])
			var ks := _pair.split(":")
			_pk = StringName(ks[0])
			_ek = StringName(ks[1] if ks.size() > 1 else "shadow")
			_army_max = {PLAYER: 0, ENEMY: 0}
			if not _kingdom_ok(_pk) or not _kingdom_ok(_ek) or (_pk != &"fire" and not &"player_kingdom" in main):
				_results.append("MATRIX %s: SKIPPED (kingdom not available yet)" % _pair)
				print(_results[-1])
				main.free()
				main = null
				_next_part()
				return
			_set_kingdoms(_pk, _ek)
	bot = _bot_for(ENEMY)
	if part == 3:
		bot2 = _bot_for(PLAYER)
	if part == 2:
		bot.profile = AIProfile.nature(1)
	bot.debug_log = part != 3
	root.add_child(main)
	current_scene = main


func _set_kingdoms(p: StringName, e: StringName) -> void:
	if &"player_kingdom" in main:
		main.set(&"player_kingdom", p)
	if &"enemy_kingdom" in main:
		main.set(&"enemy_kingdom", e)


func _bot_for(team: int) -> Node:
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			child.difficulty = 1
			child.profile = null
			child.profile_id = &""
			return child
	var b: Node = COMMANDER.new()
	b.team = team
	b.difficulty = 1
	main.add_child(b)
	return b


func _end_part() -> void:
	main.queue_free()
	main = null
	_gap = 3


func _process(_delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_next_part()
		return false
	if main == null:
		return true   # _finish() ran
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_frame += 1
	_t = main.match_time()
	match part:
		1:
			_nature_tick()
		2:
			_regrow_tick()
		3:
			_matrix_tick()
	return false


func _kingdom_of(team: int) -> StringName:
	if main.has_method(&"kingdom_of"):
		return main.call(&"kingdom_of", team)
	var w: Node = main.wizard_of(team)
	return (w as Unit).unit_type.faction if w and (w as Unit).unit_type else &""


# ---------------------------------------------------------------- part 1: the Nature bot

func _nature_tick() -> void:
	if _frame == 1:
		_n = {"hall_at": -1.0, "queued3_at": -1.0, "gathered": false, "soldier": false, "scout_at": -1.0,
				"scout_type": "", "x1_at": -1.0, "v3_row": false, "hollows": 0}
	if not bot.get(&"_ready_done"):
		return
	if _n.get("checked") == null:
		_n["checked"] = true
		if bot.faction != &"nature" or bot.ai.profile_id != &"nature_default":
			_errors.append("Nature bot: faction %s, profile %s" % [bot.faction, bot.ai.profile_id])
		for row: Dictionary in bot.get(&"_rows"):
			if row["id"] == &"V3":
				_n["v3_row"] = true
		print("Nature bot profile %s (%s), kingdom %s" % [bot.ai.id, bot.ai.profile_id, _kingdom_of(ENEMY)])
	var keep: Node = main.keep_of(ENEMY)
	if keep:
		_keep_queue_max = maxi(_keep_queue_max, (keep.queue as Array).size())
	if _n["queued3_at"] < 0.0 and bot.workers_queued >= 3:
		_n["queued3_at"] = _t
	var eco := Economy.for_team(ENEMY)
	if eco and eco.gathered_total > 0:
		_n["gathered"] = true
	if _frame % 30 == 0:
		var barracks := 0
		var hollows := 0
		for node in get_nodes_in_group("buildings"):
			var b := node as Building
			if b == null or int(b.team) != ENEMY or b.building_type == null:
				continue
			if b.building_type.kind == &"barracks":
				barracks += 1
			if b.building_type.kind == &"house":
				hollows += 1
		_n["hollows"] = maxi(int(_n["hollows"]), hollows)
		if barracks >= 1 and _n["hall_at"] < 0.0:
			_n["hall_at"] = _t
		if barracks >= 2 and _n["x1_at"] < 0.0:
			_n["x1_at"] = _t
		for node in get_nodes_in_group("units"):
			var u := node as Unit
			if u and int(u.team) == ENEMY and u.unit_type and u.unit_type.faction == &"nature" \
					and not u.unit_type.is_worker and not u is Wizard:
				_n["soldier"] = true
		var sc: Variant = bot.get(&"_scout")
		if _n["scout_at"] < 0.0 and sc != null and is_instance_valid(sc):
			_n["scout_at"] = _t
			_n["scout_type"] = str((sc as Unit).unit_type.id) if (sc as Unit).unit_type else "?"
	var decided := not _full and _nature_decided()
	if _t < NATURE_TIME and not main.game_over and not decided:
		return
	if decided and _t < NATURE_TIME:
		print("part 1: EARLY STOP at %.0f s (frame %d): every judged value is recorded (--full runs to %.0f s)" % [_t,
				_frame, NATURE_TIME])
	print("Nature bot at %.0f s: %s, keep queue max %d" % [_t, str(_n), _keep_queue_max])
	for line in bot.log_lines:
		if line.contains("PLACE") or line.contains("START") or line.contains("SCOUT ") or line.begins_with("[0:0"):
			print("  " + line)
	if _n["hall_at"] < 0.0 or _n["hall_at"] > 5.0:
		_errors.append("Nature: Grove Hall site at %.1f s (want 0:00)" % _n["hall_at"])
	if _n["queued3_at"] < 0.0 or _n["queued3_at"] > 10.0 or _keep_queue_max < 3:
		_errors.append("Nature: 3 Spriglings not queued at once (queued 3 at %.1f s, keep queue max %d)" % [
				_n["queued3_at"], _keep_queue_max])
	if not _n["gathered"]:
		_errors.append("Nature: never gathered")
	if not _n["soldier"]:
		_errors.append("Nature: no Nature soldier trained")
	if _n["scout_at"] >= 0.0 and (_n["scout_at"] < 89.0 or _n["scout_type"] != "thornling"):
		_errors.append("Nature: scout %s at %.0f s (want a Thornling from 1:30)" % [_n["scout_type"], _n["scout_at"]])
	elif _n["scout_at"] < 0.0:
		_notes.append("Nature: no scout by %.0f s" % _t)
	if not _n["v3_row"]:
		_errors.append("Nature: no V3 house row (Seed Hollow max_count %s)" % str(
				BuildingType.find("nature_hollow").max_count if BuildingType.find("nature_hollow") else "missing"))
	if _n["x1_at"] < 0.0 or _n["x1_at"] > 300.0:
		_errors.append("Nature: expansion hall at %.0f s (want by 5:00)" % _n["x1_at"])
	_end_part()


## Part 1's verdict is final once every value it judges is recorded: each one is stored the first time it is seen
## (hall, 3 queued, scout, X1 times; gathered / soldier / V3 row flags) and the queue max only grows.
func _nature_decided() -> bool:
	if _n.get("checked") == null:
		return false
	return float(_n["hall_at"]) >= 0.0 and float(_n["queued3_at"]) >= 0.0 and _keep_queue_max >= 3 \
			and bool(_n["gathered"]) and bool(_n["soldier"]) and float(_n["scout_at"]) >= 0.0 and bool(_n["v3_row"]) \
			and float(_n["x1_at"]) >= 0.0


# ---------------------------------------------------------------- part 2: retreat + regrow

func _regrow_tick() -> void:
	if not bot.get(&"_ready_done"):
		return
	if not _p2_setup:
		_p2_setup = true
		for wd in main.wardens.duplicate():
			if is_instance_valid(wd):
				(wd as Unit).take_damage(1.0e6, null)
		var type_id := "thornling" if UnitType.find("thornling") and _p2_kingdom == &"nature" else "shade"
		for i in 10:
			var s: Unit = main.make_unit(type_id)
			s.team = ENEMY
			main.add_child(s)
			s.global_position = RALLY + Vector3((i % 4) * 1.5 - 2.0, 0.0, (i / 4) * 1.5 - 1.5)
		bot.ai.attack_ratio = 0.1
		bot.ai.min_attack_pop = 4
		bot.ai.malrik_joins = AIProfile.MalrikJoins.NEVER
		print("part 2: %s bot, profile %s, 10 %s at the rally" % [_p2_kingdom, bot.ai.id, type_id])
	if _p2_launch < 0.0 and bot.attacks_launched >= 1:
		_p2_launch = _t
	if _p2_launch >= 0.0 and _p2_hurt_at < 0.0 and _t - _p2_launch >= 3.0:
		_p2_hurt_at = _t
		for u: Variant in bot.get(&"_group"):
			if is_instance_valid(u) and (u as Unit).is_alive():
				var unit := u as Unit
				unit.take_damage(maxf(0.0, unit.hp - 0.45 * unit.max_hp), null)
		print("part 2: group hurt to 45 %% at %.1f s" % _t)
	var done: bool = bot.attacks_launched >= 2 or _t >= REGROW_TIMEOUT or main.game_over
	if not done:
		return
	for line in bot.log_lines:
		if line.contains("ATTACK") or line.contains("RETREAT") or line.contains("REGROW"):
			print("  " + line)
	print("part 2: retreats at %s of launch HP, launch avg HP %s, waited %s" % [str(bot.retreat_hp_ratios),
			str(bot.launch_hp_ratios), str(bot.launch_after_regrow)])
	if bot.retreat_hp_ratios.is_empty():
		_errors.append("regrow: no HP retreat after the group fell to 45 %")
	elif bot.retreat_hp_ratios[0] >= 0.5 or bot.retreat_hp_ratios[0] < 0.3:
		_errors.append("regrow: retreat at %.2f of launch HP (want just under 0.5)" % bot.retreat_hp_ratios[0])
	if bot.attacks_launched < 2:
		_errors.append("regrow: no second attack by %.0f s" % _t)
	elif bot.launch_after_regrow.is_empty():
		_errors.append("regrow: second attack not recorded as after a retreat")
	else:
		var hp: float = bot.launch_hp_ratios[1]
		var waited: float = bot.launch_after_regrow[0]
		if hp < 0.85 and waited < 44.0:
			_errors.append("regrow: re-attacked at %.0f %% HP after %.0f s (want >= 85 %% or 45 s)" % [hp * 100.0, waited])
	_end_part()


# ---------------------------------------------------------------- part 3: bot vs bot matrix

func _matrix_tick() -> void:
	if not _army_max.has("checked") and bot.get(&"_ready_done") and bot2.get(&"_ready_done"):
		_army_max["checked"] = true
		for b in [bot2, bot]:
			var want := _pk if int(b.team) == PLAYER else _ek
			if b.faction != want:
				_errors.append("matrix %s: team %d bot plays %s" % [_pair, int(b.team), b.faction])
		print("MATRIX %s start: player bot %s (%s), enemy bot %s (%s)" % [_pair, bot2.ai.id, bot2.faction, bot.ai.id,
				bot.faction])
		_casts = {PLAYER: 0, ENEMY: 0}
		for team in [PLAYER, ENEMY]:
			var w: Node = main.wizard_of(team)
			var caster: Variant = w.get(&"spell_caster") if w else null
			if caster is Object and (caster as Object).has_signal(&"spell_cast"):
				(caster as Object).connect(&"spell_cast", func(_id: StringName) -> void: _casts[team] += 1)
	if _frame % 60 == 0:
		for team in [PLAYER, ENEMY]:
			_army_max[team] = maxi(int(_army_max[team]), int(_army(team)["pop"]))
	if _frame % 7200 == 0:
		var a := _army(PLAYER)
		var b := _army(ENEMY)
		print("  [%d:%02d] %s army pop %d (%d units) vs %s %d (%d), workers %d / %d, buildings %d / %d" % [int(_t) / 60,
				int(_t) % 60, _pk, a["pop"], a["units"], _ek, b["pop"], b["units"], a["workers"], b["workers"],
				Building.for_team(PLAYER).size(), Building.for_team(ENEMY).size()])
	if not main.game_over and _t < _minutes * 60.0:
		return
	var a := _army(PLAYER)
	var b := _army(ENEMY)
	var winner := "no winner"
	if main.game_over and int(main.winner_team) >= 0:
		winner = "%s wins" % (_pk if int(main.winner_team) == PLAYER else _ek)
	var line := "MATRIX %s (player %s vs enemy %s): %s at %d:%02d | army pop now %d / %d (max %d / %d), units %d / %d, workers %d / %d | attacks %d / %d, retreats %d / %d | gathered %d / %d | wizard lvl %d / %d, casts %d / %d" % [
			_pair, _pk, _ek, winner, int(_t) / 60, int(_t) % 60, a["pop"], b["pop"], _army_max[PLAYER],
			_army_max[ENEMY], a["units"], b["units"], a["workers"], b["workers"], bot2.attacks_launched,
			bot.attacks_launched, bot2.retreat_hp_ratios.size(), bot.retreat_hp_ratios.size(),
			Economy.for_team(PLAYER).gathered_total, Economy.for_team(ENEMY).gathered_total,
			_wizard_level(PLAYER), _wizard_level(ENEMY), int(_casts.get(PLAYER, 0)), int(_casts.get(ENEMY, 0))]
	_results.append(line)
	print(line)
	print("  ticks avg %.3f / %.3f ms, max %.3f / %.3f ms (at %.0f / %.0f s), rule usec %s / %s" % [
			bot2.tick_usec_average() / 1000.0, bot.tick_usec_average() / 1000.0, bot2.tick_usec_max / 1000.0,
			bot.tick_usec_max / 1000.0, bot2.tick_max_at, bot.tick_max_at, str(bot2.rule_usec), str(bot.rule_usec)])
	_end_part()


func _army(team: int) -> Dictionary:
	var out := {"pop": 0, "units": 0, "workers": 0}
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) != team or u is Wizard or u.unit_type == null:
			continue
		if u.unit_type.is_worker:
			out["workers"] += 1
		elif not AICasts.is_summon(u):
			out["units"] += 1
			out["pop"] += u.unit_type.pop
	return out


func _wizard_level(team: int) -> int:
	var w: Node = main.wizard_of(team)
	return (w as Unit).level if w else 0


# ---------------------------------------------------------------- end

func _finish() -> void:
	for n in _notes:
		print("note: " + n)
	if not _results.is_empty():
		print("---- matrix results ----")
		for r in _results:
			print(r)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit()
