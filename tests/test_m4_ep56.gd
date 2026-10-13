extends SceneTree
## Mission fix batch M4 (docs/handoff/code-review-2026-10-12.md C5): Episodes 5 and 6.
## Each case opens a mission, sets up the state before a save (plain checks run there), saves (SaveGame.capture),
## rebuilds it (SaveGame.instantiate_level) and checks what the load must keep:
## - e5m2: a drilled archer keeps its bonus listed in _drilled after the load (C5-7); a wounded (asleep) Ashby keeps
##   the sleep's immortal guard, his own guard stored for the wake (MissionBase.restore_guard);
## - e5m4: a save before 6:00 keeps the yards' truce, a save after 6:00 brings them back with no truce (C5-3);
## - e6m2: the open Frostgate is not a target (C5-2), Snow Lodges cap 3 (C5-5), a mid-mission Warden Breaker is armed
##   again after the load (x2 hook + scale, C5-4), townsfolk do not escort each other (C5-6);
## - e6m3: a lost garden is not counted twice by the load and Maelis stays bonded to Ysolde (C5-9);
## - e6m4: Torvald's push survives the load (C5-10), then Torvald dies and respawns (C5-1, the hook after a load).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_m4_ep56.gd --fixed-fps 60 --quit-after 40000
## Options after '--': only=<substring>. Prints "PASS m4_ep56" or "FAIL m4_ep56: <reasons>".

const TASK_ID := "m4_ep56"
const CASES := ["e5_02", "e5_04_early", "e5_04", "e6_02", "e6_03", "e6_04"]

var cases: Array[String] = []
var index := -1
var level: Node
var step := ""
var frames := 0
var data: Dictionary = {}
var restorer_done := false
var restorer_ok := false
var fails: Array[String] = []
var _sites: Array = []


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	for c: String in CASES:
		if only == "" or c.contains(only):
			cases.append(c)
	_next()


func _next() -> void:
	index += 1
	if level:
		root.remove_child(level)
		level.queue_free()
		level = null
	if index >= cases.size():
		return
	level = (load("res://missions/mission_%s.tscn" % cases[index].trim_suffix("_early")) as PackedScene).instantiate()
	level.set(&"show_briefing", false)
	level.set(&"save_campaign_on_victory", false)
	level.set(&"cinematics_enabled", false)
	level.set(&"mission_difficulty", 1)
	root.add_child(level)
	current_scene = level
	_goto("start")


func _process(_delta: float) -> bool:
	if index >= cases.size():
		if fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
		return true
	frames += 1
	var name := cases[index]
	var hero: Variant = level.get(&"hero") if level else null
	if hero is Unit and is_instance_valid(hero) and (hero as Unit).is_alive():
		(hero as Unit).heal(1.0e6)
	match step:
		"start":
			if hero != null and bool(level.get(&"match_started")) and frames > 120:
				_setup(name)
				_goto("setup")
			elif frames > 8000:
				_fail(name, "never started")
		"setup":
			if _setup_step(name):
				_goto("save")
			elif frames > 900:
				_fail(name, "setup timed out")
		"save":
			var why := SaveGame.block_reason(level)
			if why == "":
				data = SaveGame.capture(level)
				_reload()
				_goto("wait")
			elif frames > 1200:
				_fail(name, "save refused: %s" % why)
		"wait":
			if restorer_done:
				if not restorer_ok:
					_fail(name, "the restorer failed")
				else:
					_check_load(name)
					_goto("after")
			elif frames > 8000:
				_fail(name, "the load never finished")
		"after":
			if _after_step(name):
				print("  %s: ok" % name)
				_next()
			elif frames > 1500:
				_fail(name, "after-load step timed out")
	return false


func _goto(s: String) -> void:
	step = s
	frames = 0


func _fail(name: String, what: String) -> void:
	fails.append("%s: %s" % [name, what])
	print("  x %s: %s" % [name, what])
	_next()


func _expect(name: String, cond: bool, what: String) -> void:
	if not cond:
		fails.append("%s: %s" % [name, what])
		print("  x %s: %s" % [name, what])


func _reload() -> void:
	root.remove_child(level)
	level.queue_free()
	level = SaveGame.instantiate_level(data)
	level.set(&"save_campaign_on_victory", false)
	level.get_node(NodePath(SaveGame.RESTORER_NAME)).set(&"_restore_cinematics", false)
	restorer_done = false
	restorer_ok = false
	level.get_node(NodePath(SaveGame.RESTORER_NAME)).connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		restorer_ok = ok)
	root.add_child(level)
	current_scene = level


# ---------------------------------------------------------------- before the save

func _setup(name: String) -> void:
	match name:
		"e5_02":
			var archers: Array = level.call(&"spawn_group", [["ember_archer", 2]], level.call(&"hero_pos"), 2.0,
					Unit.Team.PLAYER, false)
			var a := archers[0] as Unit
			a.name = "M4Drilled"
			a.add_modifier(&"mission:drill", {"attack_damage_pct": 0.25})
			# not listed in _drilled (Ashby is away, the next drill tick would take it off): the load must list it
			var ashby: Variant = level.get(&"ashby")
			_expect(name, ashby is Unit and is_instance_valid(ashby), "no Ashby")
			if ashby is Unit:
				level.call(&"_ashby_wounded")
				_expect(name, bool(level.call(&"is_dormant", ashby)), "the wounded Ashby is not asleep")
		"e5_04_early":
			var yards: Array = level.get(&"_yards")
			_expect(name, yards.any(func(b: Variant) -> bool: return is_instance_valid(b) and (b as Node).has_meta(Unit.TRUCE_META)),
					"the yards had no truce at the start")
		"e5_04":
			var yards: Array = level.get(&"_yards")
			_expect(name, yards.any(func(b: Variant) -> bool: return is_instance_valid(b) and (b as Node).has_meta(Unit.TRUCE_META)),
					"the yards had no truce at the start")
			MissionHarness.skip_time(level, 370.0)
		"e6_02":
			_setup_e6_02(name)
		"e6_03":
			var g: Node = (level.get(&"gardens") as Array)[3]
			g.call(&"change", -1.0e6)
			_expect(name, int(level.get(&"gardens_lost")) == 1, "losing a garden counted %d" % int(level.get(&"gardens_lost")))
		"e6_04":
			var gates: Dictionary = level.get(&"wgates")
			level.call(&"_torvald_push", gates[&"wg_e"], 120.0)
			_expect(name, not (level.get(&"_push") as Dictionary).is_empty(), "the push did not start")


func _setup_e6_02(name: String) -> void:
	var gate: Node = level.get(&"gate")
	gate.call(&"set_closed", false)
	_expect(name, not bool(gate.call(&"is_alive")), "the open Frostgate is still a target (C5-2)")
	gate.call(&"set_closed", true)
	_expect(name, bool(gate.call(&"is_alive")), "the closed Frostgate is not a target")
	# C5-5: the pre-built lodge + 2 sites = 3 kept; a 4th site is cancelled
	Economy.for_team(Unit.Team.PLAYER).add(5000)
	var lodge := BuildingType.find("ice_lodge")
	var grid: BuildGrid = level.get(&"build_grid")
	_sites.clear()
	for x in range(-28, 29, 5):
		for z in range(-58, -24, 5):
			if _sites.size() >= 3:
				break
			var c := grid.snap(Vector3(x, 0.0, z), lodge.footprint)
			if grid.check(lodge, c, Unit.Team.PLAYER) == "":
				var b := grid.place(lodge, c, Unit.Team.PLAYER, [])
				if b:
					_sites.append(b)
	_expect(name, _sites.size() == 3, "only %d lodge sites placed" % _sites.size())
	# C5-4: a Warden Breaker spawned mid-mission (as a wave does)
	var out: Array = level.call(&"spawn_rows", [[MissionE6Base.BREAKER_ID, 1]], Vector3(30.0, 0.0, 20.0), 0.0,
			Unit.Team.ENEMY, false)
	for v: Variant in out:
		level.call(&"arm_enemy", v)
	_expect(name, out.size() == 1, "no Breaker spawned")


## True once the state before the save is ready.
func _setup_step(name: String) -> bool:
	match name:
		"e5_04":
			return frames > 30 and bool(level.get(&"_yards_open"))
		"e6_02":
			if frames < 90:
				return false
			var lodges := 0
			for b in Building.for_team(Unit.Team.PLAYER):
				if b.is_alive() and not b.is_queued_for_deletion() and b.building_type and b.building_type.id == &"ice_lodge":
					lodges += 1
			_expect(name, lodges == 3, "%d Snow Lodges (pre-built + sites) kept after 4 were placed, not 3 (C5-5)" % lodges)
			return true
	return frames > 30


# ---------------------------------------------------------------- after the load

func _check_load(name: String) -> void:
	match name:
		"e5_02":
			var drilled: Array = level.get(&"_drilled")
			var found := false
			for n in get_nodes_in_group(&"units"):
				var u := n as Unit
				if u and u.unit_type and u.unit_type.id == &"ember_archer" and u.has_modifier(&"mission:drill"):
					found = true
					_expect(name, drilled.has(u), "a drilled archer is not in _drilled after the load (C5-7)")
			_expect(name, found, "the drilled archer lost its saved mission:drill bonus")
			var ashby: Variant = level.get(&"ashby")
			if ashby is Unit and is_instance_valid(ashby):
				var au := ashby as Unit
				var stored: Variant = au.get_meta(MissionBase.META_GUARD, Callable())
				_expect(name, bool(level.call(&"is_dormant", au)), "the wounded Ashby woke up after the load")
				_expect(name, stored is Callable and (stored as Callable).get_method() == &"_ashby_guard",
						"Ashby's guard is not stored for the wake (restore_guard)")
				_expect(name, au.death_guard.is_valid() and au.death_guard.get_method() != &"_ashby_guard",
						"the sleeping Ashby lost the sleep's immortal guard (restore_guard)")
		"e5_04_early":
			var yards: Array = level.get(&"_yards")
			_expect(name, not bool(level.get(&"_yards_open")), "the yards opened before 6:00")
			var kept := 0
			for b: Variant in yards:
				if is_instance_valid(b) and StringName((b as Node).get_meta(Unit.TRUCE_META, &"")) == Unit.TRUCE_ALL:
					kept += 1
			_expect(name, kept == yards.filter(func(b: Variant) -> bool: return is_instance_valid(b)).size() and kept > 0,
					"a yard lost its truce after a pre-6:00 load (%d kept)" % kept)
		"e5_04":
			var yards: Array = level.get(&"_yards")
			_expect(name, bool(level.get(&"_yards_open")), "_yards_open lost")
			for b: Variant in yards:
				if is_instance_valid(b):
					_expect(name, not (b as Node).has_meta(Unit.TRUCE_META), "yard %s keeps its truce after a 6:00+ load (C5-3)"
							% (b as Node).name)
		"e6_02":
			var breakers := 0
			for n in get_nodes_in_group(&"units"):
				var u := n as Unit
				if u == null or int(u.team) != Unit.Team.ENEMY or u.unit_type == null or String(u.unit_type.id) != MissionE6Base.BREAKER_ID:
					continue
				breakers += 1
				var hooked := false
				for c: Dictionary in u.attack_landed.get_connections():
					if (c["callable"] as Callable).get_method() == &"_on_breaker_hit":
						hooked = true
				_expect(name, hooked, "a Breaker lost its x2 hook after the load (C5-4)")
				var m := u.get_model()
				if m:
					_expect(name, absf(m.scale.x - 1.5) < 0.01, "a Breaker lost its scale (%.2f)" % m.scale.x)
			_expect(name, breakers >= 1, "no Breaker after the load")
		"e6_03":
			_check_gardens(name)
		"e6_04":
			var push: Dictionary = level.get(&"_push")
			_expect(name, not push.is_empty() and push.get("target") is WardenGate
					and (push["target"] as WardenGate).gate_id == &"wg_e" and (push.get("units", []) as Array).size() >= 3,
					"Torvald's push was lost by the load (C5-10): %s" % str(push))


func _check_gardens(name: String) -> void:
	var gardens: Array = level.get(&"gardens")
	_expect(name, int(level.get(&"gardens_lost")) == 1, "gardens_lost %d after the load (C5-9)" % int(level.get(&"gardens_lost")))
	_expect(name, bool((gardens[3] as Node).get(&"is_lost")), "the lost garden came back")
	var maelis: Variant = level.get(&"maelis")
	if maelis is Helper and is_instance_valid(maelis):
		_expect(name, (maelis as Helper).bonded_wizard == level.get(&"hero"), "Maelis is not bonded to Ysolde after the load")


func _after_step(name: String) -> bool:
	match name:
		"e6_02":
			if frames == 1:
				level.set(&"branch", &"open")
				level.set(&"chose_at", float(level.call(&"mission_time")))
				return false
			if frames < 90:
				return false
			var folk: Array = level.get(&"folk")
			_expect(name, not folk.is_empty(), "no townsfolk sent")
			for v: Variant in folk:
				var f := v as Unit
				if f == null or not is_instance_valid(f):
					continue
				var guard := false
				for n in get_nodes_in_group(&"units"):
					var u := n as Unit
					if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER and u.is_commandable() and not u.is_worker() \
							and not u is Wizard and Vector2(u.global_position.x - f.global_position.x,
							u.global_position.z - f.global_position.z).length() <= 6.0:
						guard = true
				_expect(name, f.has_modifier(&"escort") == guard, "a townsperson's escort bonus is %s with soldiers near %s (C5-6)"
						% [f.has_modifier(&"escort"), guard])
			return true
		"e6_03":
			if frames < 90:
				return false
			_check_gardens(name)
			return true
		"e6_04":
			var t: Variant = level.get(&"torvald")
			if not t is Wizard or not is_instance_valid(t):
				_expect(name, false, "no Torvald after the load")
				return true
			var tw := t as Wizard
			if frames == 1:
				tw.take_damage(1.0e7, null)
				return false
			if frames == 3:
				_expect(name, not tw.is_alive(), "Torvald did not die")
				var left: Dictionary = level.get(&"_respawn_left")
				_expect(name, left.has(Unit.Team.ALLY), "Torvald's respawn is not armed (C5-1)")
				if left.has(Unit.Team.ALLY):
					left[Unit.Team.ALLY] = 0.1
				return false
			if frames > 3 and tw.is_alive():
				return true
			if frames > 600:
				_expect(name, false, "Torvald never respawned")
				return true
			return false
	return frames > 30
