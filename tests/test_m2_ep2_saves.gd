extends SceneTree
## Mission save hardening batch M2 (docs/handoff/mission-save-hardening-2026-10-12.md part D, Ep2; code review C3,
## C1-4): every Episode 2 mission is saved at its risky late step (the events are forced), rebuilt from the save, then
## checked, then won or lost on purpose to prove its ending still works after the load.
## - e2m1: survivors freed + the Heartwood kindled (C1-4 / C3-4 / C3-5): kindled, damageable, out of the truce, the
##   bound wave timers saved, wood_folk typed with their died hook; the Heartwood's fall loses the mission.
## - e2m2: three groves + E14 + the Vice armed (C3-1 / C3-4 / C3-5): 3 MissionGroves, ALLY Economy + Commander, the
##   Heartwood keep / Ysolde / carrier hooks, W6 timer saved; the Vice runs down and wins.
## - e2m3: the Tollgate raised (C3-6): max_hp and the destroyed hook back (its fall counts); Vessa's fall loses.
## - e2m4: the forge claimed (C3-2): `keep`, research / destroyed hooks, E10, Ashby's type; 2 researches finish
##   obj_research, the forge's fall loses.
## - e2m5: a Cinder Dragon trained (C3-5): typed, counted once, breath hooked; then the wake blocks saves (C3-3) and the
##   Doorwarden felled in B2 wins with obj_tether done (C3-7).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_m2_ep2_saves.gd --fixed-fps 60 --quit-after 60000
## Options after '--': only=<substring>. Prints "PASS m2_ep2_saves" or "FAIL m2_ep2_saves: <reasons>".

const TASK_ID := "m2_ep2_saves"
const MISSIONS := ["mission_e2_01", "mission_e2_02", "mission_e2_03", "mission_e2_04", "mission_e2_05"]
const SAVE_TRY_FRAMES := 2400
const END_FRAMES := 1500

var missions: Array[String] = []
var index := -1
var level: MissionBase
var step := ""
var frames := 0
var data: Dictionary = {}
var restorer_done := false
var restorer_ok := false
var ended := -1            ## -1 running, 0 defeat, 1 victory (Events.mission_ended)
var protect_hero := true
var fails: Array[String] = []
var report: Array[String] = []
var _bad: Array[String] = []   ## this mission's failures
var _saved_dragons := 0
var _saved_hush_hp := -1.0
var _saved_pop_cap := -1
var _saved_sprouts := {}     ## e2m2 site id -> living sprouts at the save
var _saved_guests := 0       ## e2m2 pop-0 guests at the save


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	for m: String in MISSIONS:
		if only == "" or m.contains(only):
			missions.append(m)
	var ev := root.get_node_or_null("Events")
	if ev:
		ev.mission_ended.connect(func(victory: bool) -> void: ended = 1 if victory else 0)
	_next()


func _next() -> void:
	index += 1
	if level:
		root.remove_child(level)
		level.queue_free()
		level = null
	if index >= missions.size():
		return
	level = (load("res://missions/%s.tscn" % missions[index]) as PackedScene).instantiate() as MissionBase
	level.show_briefing = false
	level.save_campaign_on_victory = false
	level.cinematics_enabled = false
	level.mission_difficulty = 1
	root.add_child(level)
	current_scene = level
	ended = -1
	protect_hero = true
	_bad.clear()
	_goto("start")


func _process(_delta: float) -> bool:
	if index >= missions.size():
		print("\n".join(report))
		if fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
		return true
	frames += 1
	var name := missions[index]
	var hero: Variant = level.get(&"hero") if level else null
	if protect_hero and hero is Unit and is_instance_valid(hero) and (hero as Unit).is_alive():
		(hero as Unit).heal(1.0e6)
	match step:
		"start":
			if hero != null and level.match_started and frames > 120:
				_prepare(name)
				_goto("save")
			elif frames > 6000:
				_result(name, "never started")
		"save":
			if frames % 10 == 0:
				var why := SaveGame.block_reason(level)
				if why == "":
					_before_save(name)
					data = SaveGame.capture(level)
					_reload()
					_goto("wait")
				elif frames > SAVE_TRY_FRAMES:
					_bad.append("save still refused after the late step: %s" % why)
					_result(name, "")
		"wait":
			if restorer_done:
				if not restorer_ok:
					_bad.append("the restorer failed")
					_result(name, "")
				else:
					_goto("settle")
			elif frames > 6000:
				_bad.append("the load never finished")
				_result(name, "")
		"settle":
			if frames >= 60:
				_check_load(name)
				_drive_end(name)
				_goto("end")
		"end":
			_tick_end(name)
			if ended >= 0:
				_check_end(name)
				_result(name, "")
			elif frames > END_FRAMES:
				_bad.append("the mission did not end after the load (expected %s)" % _expected_text(name))
				_result(name, "")
	return false


func _goto(s: String) -> void:
	step = s
	frames = 0


func _result(name: String, _what: String) -> void:
	var line := "  %s: %s" % [name, "ok" if _bad.is_empty() else "FAIL " + ", ".join(_bad)]
	report.append(line)
	print(line)
	if not _bad.is_empty():
		fails.append("%s %s" % [name, ", ".join(_bad)])
	_next()


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_bad.append(what)


func _reload() -> void:
	root.remove_child(level)
	level.queue_free()
	level = SaveGame.instantiate_level(data) as MissionBase
	level.save_campaign_on_victory = false
	var restorer := level.get_node(NodePath(SaveGame.RESTORER_NAME))
	restorer.set(&"_restore_cinematics", false)
	restorer_done = false
	restorer_ok = false
	restorer.connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		restorer_ok = ok)
	root.add_child(level)
	current_scene = level


func _units_of_type(id: String) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u.unit_type and String(u.unit_type.id) == id:
			out.append(u)
	return out


func _guests() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u.has_meta(&"e2m2_guest"):
			out.append(u)
	return out


func _has_timer(method: String) -> bool:
	for t: Array in level.get(&"_timers"):
		var c := t[1] as Callable
		if c.is_valid() and String(c.get_method()) == method:
			return true
	return false


func _expected_text(name: String) -> String:
	return "victory" if name in ["mission_e2_02", "mission_e2_05"] else "defeat"


# ---------------------------------------------------------------- the late steps

func _prepare(name: String) -> void:
	var m := level
	match name:
		"mission_e2_01":
			m.call(&"_free_hideout", &"S1")
			m.call(&"kindle")
			var roster := HelperRoster.for_team(Unit.Team.PLAYER)
			if roster:
				roster.grant(m.hero.global_position + Vector3(3.0, 0.0, 3.0))   # Old Vey arrives (E11, the E12 hook)
		"mission_e2_02":
			m.call(&"_plant", &"A", [])
			m.call(&"_plant", &"B", [])
			m.call(&"_plant", &"C", [])   # the third grove: E14, the ALLY seat
			m.set_objective(&"obj_rimehold", "done")
			m.call(&"_check_vice_start")
			for st: Variant in (m.get(&"sites") as Dictionary).values():
				(st as GroveSite).sprout_left = 0.01   # every grove sprouts before the save
		"mission_e2_03":
			m.call(&"_raise_tollgate")
		"mission_e2_04":
			m.call(&"claim_forge")
			m.call(&"_spawn_hush", Vector3(0.0, 0.0, -60.0), 0.6)   # E15's Hush (mission HP 1400 on normal), hurt
		"mission_e2_05":
			var d := m.make_unit("cinder_dragon")
			m.call(&"_spawn", d, Unit.Team.PLAYER, m.hero.global_position + Vector3(4.0, 0.0, 4.0))


func _before_save(name: String) -> void:
	if name == "mission_e2_05":
		_saved_dragons = int(level.get(&"dragons"))
	if name == "mission_e2_02":
		_saved_sprouts.clear()
		for id: Variant in (level.get(&"sites") as Dictionary):
			var st := (level.get(&"sites") as Dictionary)[id] as GroveSite
			_saved_sprouts[String(id)] = st.sprouts.filter(func(u: Variant) -> bool:
				return is_instance_valid(u) and (u as Unit).is_alive()).size()
		_saved_guests = _guests().size()
	if name == "mission_e2_04":
		var eco := Economy.for_team(Unit.Team.PLAYER)
		_saved_pop_cap = eco.pop_cap if eco else -1
		var hc: Variant = level.get(&"hush_cast")
		var h: Variant = (hc as Node).get(&"hush") if hc is Node else null
		_saved_hush_hp = (h as Unit).hp if h is Unit and is_instance_valid(h) else -1.0


func _check_load(name: String) -> void:
	var m := level
	match name:
		"mission_e2_01":
			var hw := m.get(&"heartwood") as MissionHeartwood
			_expect(hw != null and hw.is_kindled and not hw.invulnerable, "Heartwood not kindled after the load")
			_expect(hw != null and not hw.has_meta(Unit.TRUCE_META), "Heartwood still in a truce after the load")
			_expect(bool(m.get(&"kindled")), "kindled lost")
			_expect(_has_timer("_fire_wave"), "the bound wave timers were not saved")
			var folk := _units_of_type("wood_folk")
			_expect(folk.size() >= 4, "wood_folk not rebuilt with their type (%d)" % folk.size())
			for f in folk:
				if not f.died.is_connected(Callable(m, &"_on_folk_died")):
					_bad.append("a survivor's died hook lost")
					break
			_expect(bool(m.get(&"vey_arrived")), "Old Vey did not arrive before the save")
			var roster := HelperRoster.for_team(Unit.Team.PLAYER)
			var hooked := false
			if roster and roster.helper and is_instance_valid(roster.helper):
				for c in roster.helper.get_children():
					if c.has_signal(&"ability_cast") and c.is_connected(&"ability_cast", Callable(m, &"_on_vey_ability")):
						hooked = true
			_expect(hooked, "Vey's E12 Stormcall hook lost")
		"mission_e2_02":
			_expect(int(m.call(&"groves_standing")) == 3, "groves standing after the load: %d" % int(m.call(&"groves_standing")))
			var groves := get_nodes_in_group(&"buildings").filter(func(b: Node) -> bool: return b is MissionGrove)
			_expect(groves.size() == 3, "MissionGroves after the load: %d" % groves.size())
			_expect(Economy.for_team(Unit.Team.ALLY) != null, "no ALLY Economy after the load")
			var bot: Variant = m.get(&"ally_commander")
			_expect(bot is Node and is_instance_valid(bot), "no ALLY Commander after the load")
			var hw: Variant = m.get(&"heartwood")
			_expect(hw is Keep and (hw as Keep).destroyed.is_connected(Callable(m, &"_on_ally_keep_destroyed")),
					"the ALLY Heartwood keep's hook lost")
			var ys: Variant = m.get(&"ysolde")
			_expect(ys is Wizard and (ys as Wizard).died.is_connected(Callable(m, &"_on_ysolde_died")), "Ysolde's died hook lost")
			for c: Variant in m.get(&"carriers"):
				if is_instance_valid(c) and not (c as Unit).died.is_connected(Callable(m, &"_on_carrier_died")):
					_bad.append("a carrier's died hook lost")
					break
			_expect(_units_of_type("seed_carrier").size() > 0, "no seed_carrier typed after the load")
			_expect(_has_timer("_fire_wave"), "the W6 timer was not saved")
			for id: Variant in (m.get(&"sites") as Dictionary):
				var st := (m.get(&"sites") as Dictionary)[id] as GroveSite
				var n := st.sprouts.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive()).size()
				_expect(n == int(_saved_sprouts.get(String(id), -1)), "site %s sprouts %d after the load, %d saved" % [id, n, int(_saved_sprouts.get(String(id), -1))])
			var guests := _guests()
			_expect(_saved_guests > 0 and guests.size() == _saved_guests, "guests %d after the load, %d saved" % [guests.size(), _saved_guests])
			for g in guests:
				if g.unit_type.pop != 0:
					_bad.append("a guest came back with pop %d" % g.unit_type.pop)
					break
			for n in get_nodes_in_group(&"units"):
				var u := n as Unit
				if u and u.is_alive() and int(u.team) == Unit.Team.ALLY and not u.has_meta(&"e2m2_guest") \
						and u.unit_type and u.unit_type.id == &"thornling" and u.unit_type.pop == 0:
					_bad.append("a post-E14 thornling came back as a pop-0 guest")
					break
			_expect(_has_timer("_start_vice") or float(m.get(&"vice_left")) >= 0.0, "the Vice start timer was lost")
		"mission_e2_03":
			var tg: Variant = m.get(&"tollgate")
			_expect(tg is Building and is_instance_valid(tg) and (tg as Building).is_alive(), "no Tollgate after the load")
			if tg is Building and is_instance_valid(tg):
				var b := tg as Building
				_expect(is_equal_approx(b.max_hp, 720.0), "Tollgate max_hp %.0f, not 720" % b.max_hp)
				_expect(b.destroyed.is_connected(Callable(m, &"_on_tollgate_destroyed")), "the Tollgate's destroyed hook lost")
		"mission_e2_04":
			_expect(bool(m.get(&"forge_claimed")), "forge_claimed lost")
			var k: Variant = m.get(&"keep")
			_expect(k is Keep and is_instance_valid(k), "keep is not the Warden Forge after the load")
			if k is Keep and is_instance_valid(k):
				_expect((k as Keep).destroyed.is_connected(Callable(m, &"_on_forge_destroyed")), "the forge's destroyed hook lost")
			var fk := ForgeKit.for_team(Unit.Team.PLAYER)
			_expect(fk != null and fk.research_completed.is_connected(Callable(m, &"_on_research")), "research hook lost")
			if k is Keep and is_instance_valid(k):
				_expect((k as Keep).building_type.display_name == "Warden Forge", "the forge is named %s after the load" % (k as Keep).building_type.display_name)
			_expect(m.find_child("ColdWardenForge", true, false) == null, "the cold forge stands again after the load")
			_expect(int(m.get(&"forge_pop_bonus")) > 0, "the claim gave no extra pop (the pop cap check proves nothing)")
			var eco := Economy.for_team(Unit.Team.PLAYER)
			_expect(eco != null and eco.pop_cap == _saved_pop_cap, "pop cap %d after the load, %d saved" % [eco.pop_cap if eco else -1, _saved_pop_cap])
			var e10 := false
			for e: Array in m.get(&"_events"):
				if StringName(e[0]) == &"E10":
					e10 = true
			_expect(e10 or m.has_fired(&"E10"), "E10 not re-added")
			var hc: Variant = m.get(&"hush_cast")
			var h: Variant = (hc as Node).get(&"hush") if hc is Node and is_instance_valid(hc) else null
			_expect(h is Unit and is_instance_valid(h), "Hush's kit (actor cast) not back after the load")
			if h is Unit and is_instance_valid(h):
				var hu := h as Unit
				_expect(is_equal_approx(hu.max_hp, 1400.0), "Hush max_hp %.0f after the load, not 1400" % hu.max_hp)
				_expect(absf(hu.hp - _saved_hush_hp) <= 0.05 * hu.max_hp, "Hush hp %.0f after the load, %.0f saved" % [hu.hp, _saved_hush_hp])
			var ab: Variant = m.get(&"ashby")
			_expect(ab is Unit and is_instance_valid(ab) and (ab as Unit).unit_type != null \
					and (ab as Unit).unit_type.id == &"ashby", "Ashby not rebuilt with his type")
		"mission_e2_05":
			var dr := _units_of_type("cinder_dragon")
			_expect(dr.size() == 1, "Cinder Dragons after the load: %d" % dr.size())
			_expect(int(m.get(&"dragons")) == _saved_dragons, "dragons %d after the load, %d saved" % [int(m.get(&"dragons")), _saved_dragons])
			if dr.size() == 1:
				_expect(dr[0].is_in_group(&"titans"), "the dragon lost its titans group")
				_expect(dr[0].attack_landed.get_connections().size() > 0, "the dragon's breath hook lost")
			_expect(SaveGame.block_reason(m) == "", "save refused before the wake: %s" % SaveGame.block_reason(m))


## Forces the ending this mission must reach after the load.
func _drive_end(name: String) -> void:
	var m := level
	match name:
		"mission_e2_01":
			var hw := m.get(&"heartwood") as MissionHeartwood
			if hw:
				hw.take_damage(1.0e8, null)
		"mission_e2_02":
			if float(m.get(&"vice_left")) < 0.0:
				m.call(&"_start_vice")
			m.set(&"vice_left", 1.0)
		"mission_e2_03":
			var tg: Variant = m.get(&"tollgate")
			if tg is Building and is_instance_valid(tg):
				(tg as Building).take_damage(1.0e8, null)
			_expect(int(m.get(&"tollgate_falls")) == 1, "the Tollgate's fall was not counted after the load")
			protect_hero = false
			m.hero.take_damage(1.0e8, null)
		"mission_e2_04":
			var fk := ForgeKit.for_team(Unit.Team.PLAYER)
			if fk:
				fk.research_completed.emit(&"armor", 1)
				fk.research_completed.emit(&"weapons", 1)
			_expect(m.objective_state(&"obj_research") == "done", "2 researches did not finish obj_research (%s)" % m.objective_state(&"obj_research"))
			var k: Variant = m.get(&"keep")
			if k is Keep and is_instance_valid(k):
				(k as Keep).take_damage(1.0e8, null)
		"mission_e2_05":
			m.call(&"wake_up")
			_expect(SaveGame.block_reason(m) != "", "a save is allowed during the Doorwarden fight (C3-3)")
			m.call(&"_start_b2")


func _tick_end(name: String) -> void:
	if name == "mission_e2_05" and frames > 5 and frames % 10 == 0:
		var boss: Variant = level.get(&"boss")
		if is_instance_valid(boss) and boss is Unit and (boss as Unit).is_alive():
			(boss as Unit).take_damage(1.0e8, null)
	if name == "mission_e2_03" and frames % 30 == 0 and is_instance_valid(level.hero) and level.hero.is_alive():
		level.hero.take_damage(1.0e8, null)   # a respawn guard would bring her back: keep hitting


func _check_end(name: String) -> void:
	var want := 1 if _expected_text(name) == "victory" else 0
	_expect(ended == want, "ended in %s, expected %s" % ["victory" if ended == 1 else "defeat", _expected_text(name)])
	var m := level
	match name:
		"mission_e2_01":
			_expect(m.has_fired(&"E22"), "the defeat did not come from the Heartwood's fall")
		"mission_e2_02":
			_expect(m.has_fired(&"E21"), "the victory did not come from the Vice")
		"mission_e2_04":
			_expect(m.has_fired(&"E23"), "the defeat did not come from the forge's fall")
		"mission_e2_05":
			_expect(m.objective_state(&"obj_tether") != "active", "obj_tether still active on the victory (C3-7)")
			_expect(m.objective_state(&"obj_doorwarden") == "done", "obj_doorwarden not done")
