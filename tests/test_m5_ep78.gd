extends SceneTree
## Mission fix batch M5 (code-review-2026-10-12 C6, Ep7 + Ep8): real mission scenes saved mid-mission with
## SaveGame.capture and rebuilt with SaveGame.instantiate_level. Checks:
## - e7m1: an open auction survives the load with its bid panel and is hammered later (C6-1); a bound dragon keeps its
##   "rest at 15 %" guard before and after the load (C6-7); Seraphine keeps her difficulty HP (C6-6);
## - e7m2: an opened strongbox stays hidden (C6-12);
## - e7m3: a press-gang restored by the load leaves (C6-5); a raider with no row left attack-moves to the keep, never
##   to Vector3.INF (C6-8); the briefing rule names the real loss limit (C6-11);
## - e7m4 (phase 4): the pay panel is back, the crimson galleys stay hidden, Seraphine is awake and out of the truce,
##   Malrik's Commander stays paused, every dragon keeps its rest guard (C6-2, C6-4, C6-9, C6-12, C6-7);
## - e8m1_ice: refugees keep the difficulty's HP, the open gate stays open to the eye (C6-6, C6-12);
## - e8m1_shadow: the Stone's Gift panel is back (C6-3); Ep3's `shadow_stone_uses` adds 2 Shades to G4 (C6-10);
## - e8m2: lit keyhole pillars and the Early Rise hand are drawn again (C6-12).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_m5_ep78.gd --fixed-fps 60 --quit-after 60000
## Options after '--': only=<case name>. Prints "PASS m5_ep78" or "FAIL m5_ep78: <reasons>".

const TASK_ID := "m5_ep78"
const START_TIMEOUT := 6000
const LOAD_TIMEOUT := 6000

## [name, scene, difficulty, flag_override (null = none), save (bool)]
const CASES := [
	["e7m1", "res://missions/mission_e7_01.tscn", 0, null, true],
	["e7m2", "res://missions/mission_e7_02.tscn", 1, null, true],
	["e7m3", "res://missions/mission_e7_03.tscn", 0, null, true],
	["e7m4", "res://missions/mission_e7_04.tscn", 1, null, true],
	["e8m1_ice", "res://missions/mission_e8_01_ice.tscn", 0, null, true],
	["e8m1_shadow", "res://missions/mission_e8_01_shadow.tscn", 1, {"m5_dummy": 1}, true],
	["e8m1_shadow_stone", "res://missions/mission_e8_01_shadow.tscn", 1, {"shadow_stone_uses": 2}, false],
	["e8m2", "res://missions/mission_e8_02.tscn", 1, null, true],
]

var cases: Array = []
var index := -1
var level: Node
var step := ""
var frames := 0
var data: Dictionary = {}
var restorer_done := false
var restorer_ok := false
var fails: Array[String] = []
var _pillars_before := 0


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	for c: Array in CASES:
		if only == "" or String(c[0]).begins_with(only):
			cases.append(c)
	_next()


func _name() -> String:
	return String(cases[index][0])


func _next() -> void:
	if index >= 0 and index < cases.size():
		print("  %s: done (%d fails so far)" % [_name(), fails.size()])
	index += 1
	if level:
		root.remove_child(level)
		level.queue_free()
		level = null
	if index >= cases.size():
		return
	var c: Array = cases[index]
	level = (load(String(c[1])) as PackedScene).instantiate()
	level.set(&"show_briefing", false)
	level.set(&"save_campaign_on_victory", false)
	level.set(&"cinematics_enabled", false)
	level.set(&"mission_difficulty", int(c[2]))
	if c[3] != null:
		level.set(&"flag_override", (c[3] as Dictionary).duplicate())
	root.add_child(level)
	current_scene = level
	_goto("start")


func _goto(s: String) -> void:
	step = s
	frames = 0


func _fail(what: String) -> void:
	fails.append("%s: %s" % [_name(), what])


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_fail(what)


func _process(_delta: float) -> bool:
	if index >= cases.size():
		_report()
		return true
	frames += 1
	var hero: Variant = level.get(&"hero") if level else null
	if hero is Unit and is_instance_valid(hero) and (hero as Unit).is_alive():
		(hero as Unit).heal(1.0e6)
	match step:
		"start":
			if hero != null and bool(level.get(&"match_started")) and frames > 60:
				_goto("prepare")
			elif frames > START_TIMEOUT:
				_fail("never started")
				_next()
		"prepare":
			if SaveGame.block_reason(level) != "":
				if frames > 3000:
					_fail("save refused before the setup: %s" % SaveGame.block_reason(level))
					_next()
				return false
			_prepare()
			if not bool(cases[index][4]):
				_next()
				return false
			_strip_lambda_timers()
			var why := SaveGame.block_reason(level)
			if why != "":
				_fail("save refused after the setup: %s" % why)
				_next()
				return false
			data = SaveGame.capture(level)
			_reload()
			_goto("wait")
		"wait":
			if restorer_done:
				if not restorer_ok:
					_fail("the restorer failed")
					_next()
				else:
					_goto("settle")
			elif frames > LOAD_TIMEOUT:
				_fail("the load never finished")
				_next()
		"settle":
			if frames >= 30:
				_check_load()
				_goto("after")
		"after":
			if _after_done():
				_next()
	return false


func _report() -> void:
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])


## The tests' own lambdas cannot be saved: drop the ones the setup added (the sweep test does the same).
func _strip_lambda_timers() -> void:
	var m := level as MissionBase
	var timers: Array = m.get(&"_timers")
	for i in range(timers.size() - 1, -1, -1):
		var row: Array = timers[i]
		var c := row[1] as Callable
		if row.size() > 2 and StringName(row[2]) != &"":
			continue
		if not (c.is_standard() and c.get_object() == m):
			timers.remove_at(i)


func _reload() -> void:
	root.remove_child(level)
	level.queue_free()
	level = SaveGame.instantiate_level(data)
	level.set(&"save_campaign_on_victory", false)
	var restorer := level.get_node(NodePath(SaveGame.RESTORER_NAME))
	restorer.set(&"_restore_cinematics", false)
	restorer_done = false
	restorer_ok = false
	restorer.connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		restorer_ok = ok)
	root.add_child(level)
	current_scene = level


func _const(name: String) -> Variant:
	var sc := level.get_script() as Script
	while sc != null:
		var map := sc.get_script_constant_map()
		if map.has(name):
			return map[name]
		sc = sc.get_base_script()
	return null


func _panel(panel_name: String) -> bool:
	var hud: Variant = level.get(&"hud")
	if hud == null or not is_instance_valid(hud):
		return false
	var p := (hud as Node).find_child(panel_name, true, false)
	return p != null and not p.is_queued_for_deletion()


## True when `u` gets the dragons' rest guard now (awake) or back from its wake (asleep).
func _dragon_guarded(u: Unit) -> bool:
	if u.has_meta(MissionBase.META_DORMANT):
		var g: Variant = u.get_meta(MissionBase.META_GUARD, Callable())
		return g is Callable and (g as Callable).is_valid()
	return u.death_guard.is_valid()


# ---------------------------------------------------------------- per case

func _prepare() -> void:
	var m := level as MissionBase
	match _name():
		"e7m1":
			m.call(&"open_auction", "gilt_dragon", "Kesh", 600)
			m.fire_once(&"pre_A0")
			m.fire_once(&"A0")
			((m.get(&"auction") as Dictionary)["bids"] as Array)[1] = 150
			m.fire_once(&"E11")
			m.call(&"_laurel_end")
			MissionHarness.kill(m.get(&"knives") as Array)
			m.call(&"bind_dragon", "prism_dragon", 0, 180.0)
			var d := m.call(&"dragon", "prism_dragon") as Unit
			_expect(d != null and d.death_guard.is_valid(), "a bound dragon has no rest guard before any load (wake drop)")
		"e7m2":
			m.fire_once(&"box_0")
			var props: Array = m.get(&"_box_props")
			if not props.is_empty() and is_instance_valid(props[0]):
				(props[0] as Node3D).visible = false
		"e7m3":
			var rule := String(m.briefing().get("rule", ""))
			_expect(rule.contains(str(int(m.call(&"lost_limit")))), "the briefing rule does not name the real limit (%s)" % rule)
			m.call(&"_press_gang", &"R1")
			_expect(not (m.get(&"_gangs") as Array).is_empty(), "no press-gang to save")
			_check_inf()
		"e7m4":
			m.fire_once(&"E7")
			m.fire_once(&"E8")
			m.set(&"phase", 2)
			m.call(&"_two_skies_end")
			m.fire_once(&"E9")
			m.call(&"_turn_end")
			_expect(_panel("PayPanel"), "no pay panel after the turn")
		"e8m1_ice":
			m.call(&"_spawn_column")
			m.call(&"set_gate", true)
		"e8m1_shadow", "e8m1_shadow_stone":
			if _name() == "e8m1_shadow_stone":
				# own baseline: G4's 6 Shades scaled by this mission; the stone adds its own scaled row of 2
				var plain := int(m.call(&"scaled", 6, "sworn_shade"))
				var extra := int(m.call(&"scaled", 2, "sworn_shade"))
				var n := _garrison_count()
				_expect(extra > 0 and n == plain + extra,
						"shadow_stone_uses did not add the Shades to the garrison (%d, want %d + %d)" % [n, plain, extra])
			else:
				_expect(_panel("GiftPanel"), "no Stone's Gift panel after the intro")
		"e8m2":
			m.call(&"_light", Unit.Team.PLAYER)
			m.call(&"_feed", 100.0)
			_pillars_before = _pillar_count()
			_expect(_pillars_before >= 1 and _hand_present(), "the setup drew no pillar / hand")


func _check_load() -> void:
	var m := level as MissionBase
	match _name():
		"e7m1":
			var a: Dictionary = m.get(&"auction")
			_expect(not a.is_empty() and String(a.get("id", "")) == "gilt_dragon"
					and int((a.get("bids", [0, 0]) as Array)[1]) == 150, "the open auction was lost by the load (%s)" % a)
			_expect(_panel("AuctionPanel"), "no bid panel after the load")
			var d := m.call(&"dragon", "prism_dragon") as Unit
			_expect(d != null and int(d.team) == Unit.Team.PLAYER and _dragon_guarded(d), "the bound dragon lost its rest guard")
			if d:
				d.take_damage(1.0e7, null)
				_expect(d.is_alive() and d.hp >= d.max_hp * 0.1, "the bound dragon died for good after the load")
			var s := m.get(&"seraphine") as Unit
			var want := float((_const("SERAPHINE_HP") as Array)[0])
			_expect(s != null and absf(s.max_hp - want) < 1.0, "Seraphine's difficulty HP was lost (%s, want %s)"
					% [s.max_hp if s else -1.0, want])
			MissionHarness.skip_time(m, 60.0)
		"e7m2":
			var props: Array = m.get(&"_box_props")
			_expect(not props.is_empty() and is_instance_valid(props[0]) and not (props[0] as Node3D).visible,
					"the opened strongbox is back after the load")
		"e7m3":
			var gangs: Array = m.get(&"_gangs")
			var ok := not gangs.is_empty()
			for g: Array in gangs:
				ok = ok and String(g[2]) == "walk" and StringName(g[1]) == &"R1" and not (g[0] as Array).is_empty()
				for u: Variant in g[0]:
					ok = ok and (u as Unit).has_move_order()
			_expect(ok, "the walking press-gang does not walk on after the load (%s)" % [gangs])
		"e7m4":
			_expect(_panel("PayPanel"), "no pay panel after a phase-4 load")
			var crimson: Dictionary = m.get(&"crimson")
			var shown := 0
			var alive := 0
			for k: Variant in crimson:
				var g: Variant = crimson[k]
				if is_instance_valid(g) and (g as Building).is_alive():
					alive += 1
					if (g as Node3D).visible:
						shown += 1
			_expect(alive > 0 and shown == 0, "crimson galleys visible after the load (%d of %d)" % [shown, alive])
			var s := m.get(&"seraphine") as Unit
			_expect(s != null and not m.is_dormant(s) and not s.has_meta(Unit.TRUCE_META),
					"Seraphine came back asleep / at peace after a phase-4 load")
			var bot: Variant = m.get(&"_malrik_cmd")
			_expect(bot == null or not bool((bot as Node).get(&"enabled")), "Malrik's Commander is enabled again")
			var dragons: Dictionary = m.get(&"dragons")
			for id: Variant in dragons:
				var u := m.call(&"dragon", String(id)) as Unit
				_expect(u == null or _dragon_guarded(u), "dragon %s lost its rest guard" % id)
		"e8m1_ice":
			var want := float((_const("REFUGEE_HP") as Array)[0])
			var refugees: Array = m.call(&"alive_refugees")
			var bad := 0
			for v: Variant in refugees:
				if absf((v as Unit).max_hp - want) > 0.5:
					bad += 1
			_expect(not refugees.is_empty() and bad == 0, "%d of %d refugees lost the difficulty HP" % [bad, refugees.size()])
			var look := m.get(&"gate_look") as Node3D
			_expect(look == null or not look.visible, "the open gate is drawn shut after the load")
		"e8m1_shadow":
			_expect(_panel("GiftPanel"), "no Stone's Gift panel after the load")
		"e8m2":
			_expect(_pillar_count() >= _pillars_before, "lit keyhole pillars gone after the load (%d < %d)" % [_pillar_count(), _pillars_before])
			_expect(_hand_present(), "the Early Rise hand is gone after the load")


## Some checks need a few more frames after the load.
func _after_done() -> bool:
	var m := level as MissionBase
	match _name():
		"e7m1":
			if not bool(m.call(&"auction_open")):
				_expect((m.get(&"auction_log") as Array).size() >= 1, "the restored auction closed without a hammer")
				return true
			if frames > 600:
				_fail("the restored auction was never hammered")
				return true
			return false
	return true


## C6-8: a raider whose default is gone (Vector3.INF, every row rung) attack-moves to the keep.
func _check_inf() -> void:
	var m := level as MissionBase
	var rung: Array = m.get(&"bells_rung")
	for rid: Variant in (_const("ROWS") as Dictionary):
		if not rung.has(rid):
			rung.append(rid)
	var u := m.make_unit("masked_shade")
	u.team = Unit.Team.ENEMY
	m.add_child(u)
	u.global_position = Vector3(10.0, 0.0, 0.0)
	u.set_meta(&"e7_default", Vector3.INF)
	m.call(&"_refresh_e7_mode", u, &"raid3", Vector3.ZERO)
	var target: Vector3 = u.get(&"_attack_move_target")
	_expect(target != Vector3.INF and target.is_finite(), "a raider attack-moves to Vector3.INF")
	u.queue_free()
	rung.clear()


func _garrison_count() -> int:
	var at: Vector3 = _const("GARRISON")
	var n := 0
	for x in get_nodes_in_group(&"units"):
		var u := x as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and Vector2(u.global_position.x - at.x, u.global_position.z - at.z).length() < 12.0 \
				and u.unit_type and String(u.unit_type.id).contains("shade"):
			n += 1
	return n


func _pillar_count() -> int:
	var n := 0
	for c in level.get_children():
		var mi := c as MeshInstance3D
		if mi and mi.mesh is CylinderMesh and absf((mi.mesh as CylinderMesh).height - 10.0) < 0.01:
			n += 1
	return n


func _hand_present() -> bool:
	var crack: Vector3 = _const("CRACK")
	for c in level.get_children():
		var n := c as Node3D
		if n == null or n is Unit or n is Building or Vector2(n.global_position.x - crack.x, n.global_position.z - crack.z).length() > 0.5:
			continue
		for k in n.get_children():
			var mi := k as MeshInstance3D
			if mi and mi.mesh is BoxMesh and absf((mi.mesh as BoxMesh).size.y - 9.0) < 0.01:
				return true
	return false
