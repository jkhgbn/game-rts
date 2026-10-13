extends SceneTree
## Mission save hardening, batch M1 (docs/handoff/mission-save-hardening-2026-10-12.md part C / D Ep1, code review C2):
## every Episode 1 mission is pushed to a LATE step (events forced), saved with SaveGame.capture, rebuilt with
## SaveGame.instantiate_level, then checked: the mission actors are in their saved state (braziers lit quietly, Hush
## re-bound, thawed blocks / melted Heartfrost / open floe, hearts / gates / stakes / thorns, crown seal, rider
## unlock) and the mission can still be finished from there (the next objective is reached).
## mission_04 also checks C2-1 (no save from the Rise on) and C2-5 (a freed pylon is no script error).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_m1_ep1_saves.gd --fixed-fps 60 --quit-after 60000
## Options after '--': only=<substring>. Prints "PASS m1_ep1_saves" or "FAIL m1_ep1_saves: <reasons>".

const TASK_ID := "m1_ep1_saves"
const MISSIONS := ["mission_00", "mission_01", "mission_02", "mission_03", "mission_04"]
const PREP_FRAMES := 1500
const FINISH_FRAMES := 1500

var queue: Array[String] = []
var mname := ""
var level: MissionBase
var step := ""
var frames := 0
var sub := 0
var data: Dictionary = {}
var expect: Dictionary = {}
var restorer_done := false
var restorer_ok := false
var fails: Array[String] = []
var report: Array[String] = []


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	for m: String in MISSIONS:
		if only == "" or m.contains(only):
			queue.append(m)
	_next()


func _next() -> void:
	if level:
		root.remove_child(level)
		level.queue_free()
		level = null
	if queue.is_empty():
		mname = ""
		return
	mname = queue.pop_front()
	level = (load("res://missions/%s.tscn" % mname) as PackedScene).instantiate() as MissionBase
	level.set(&"show_briefing", false)
	level.set(&"save_campaign_on_victory", false)
	level.set(&"cinematics_enabled", false)
	level.set(&"mission_difficulty", 2 if mname == "mission_00" else 1)   # hard m00: Hush's 1200 HP > the .tres 900
	root.add_child(level)
	current_scene = level
	_goto("start")


func _goto(s: String) -> void:
	step = s
	frames = 0
	sub = 0


func _result(what: String) -> void:
	report.append("  %s: %s" % [mname, what])
	print("  %s: %s" % [mname, what])
	if what != "ok":
		fails.append("%s %s" % [mname, what])
	_next()


func _process(_delta: float) -> bool:
	if mname == "":
		print("\n".join(report))
		if fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
		return true
	frames += 1
	var hero: Variant = level.get(&"hero") if level else null
	if hero is Unit and is_instance_valid(hero) and (hero as Unit).is_alive():
		(hero as Unit).heal(1.0e6)
	match step:
		"start":
			if hero != null and bool(level.get(&"match_started")):
				_goto("prep")
			elif frames > 6000:
				_result("never started")
		"prep":
			if frames >= 30 and bool(call("_prep_" + mname)):
				_goto("settle")
			elif frames > PREP_FRAMES:
				_result("prep timed out at sub-step %d" % sub)
		"settle":
			_drop_lambda_timers()
			var why := SaveGame.block_reason(level)
			if why == "":
				expect = call("_record_" + mname)
				data = SaveGame.capture(level)
				_reload()
				_goto("wait")
			elif frames > 900:
				_result("save stayed blocked: %s" % why)
		"wait":
			if restorer_done:
				if restorer_ok:
					_goto("verify")
				else:
					_result("the restorer failed")
			elif frames > 6000:
				_result("the load never finished")
		"verify":
			if frames >= 30:
				var bad: Array[String] = call("_verify_" + mname)
				if bool(level.get(&"game_over")):
					bad.append("game over after the load")
				if not bad.is_empty():
					_result("after the load: " + ", ".join(bad))
				else:
					_goto("finish")
		"finish":
			var r: String = call("_finish_" + mname)
			if r == "done":
				_result("ok")
			elif r != "":
				_result(r)
			elif frames > FINISH_FRAMES:
				_result("could not finish from the save (sub-step %d)" % sub)
	return false


## Lambda timers the forced steps added cannot be saved: drop them (the save test is about the state, not those).
func _drop_lambda_timers() -> void:
	var timers: Array = level.get(&"_timers")
	for i in range(timers.size() - 1, -1, -1):
		var t: Array = timers[i]
		if bool(level.call(&"_timer_rebuilt", t)) or bool(level.call(&"_save_timer_ok", t[1])):
			continue
		timers.remove_at(i)


func _reload() -> void:
	root.remove_child(level)
	level.queue_free()
	level = SaveGame.instantiate_level(data) as MissionBase
	level.set(&"save_campaign_on_victory", false)
	level.get_node(NodePath(SaveGame.RESTORER_NAME)).set(&"_restore_cinematics", false)
	restorer_done = false
	restorer_ok = false
	level.get_node(NodePath(SaveGame.RESTORER_NAME)).connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		restorer_ok = ok)
	root.add_child(level)
	current_scene = level


func _hero() -> Unit:
	return level.get(&"hero") as Unit


func _put_hero(at: Vector3) -> void:
	var h := _hero()
	if h and h.is_alive():
		MissionHarness.put(h, at)


func _count(team: int, ids: Array) -> int:
	var n := 0
	for x in get_nodes_in_group(&"units"):
		var u := x as Unit
		if u and u.is_alive() and int(u.team) == team and u.unit_type and ids.has(String(u.unit_type.id)):
			n += 1
	return n


# ---------------------------------------------------------------- mission 0: 2 braziers lit, Mother Hush on the field

func _prep_mission_00() -> bool:
	var bz: Array = level.get(&"braziers")
	(bz[0] as MissionBrazier).light()
	(bz[1] as MissionBrazier).light()
	level.call(&"_fire_wave", &"A3")
	var hush := level.call(&"hush") as Unit
	if hush == null:
		return false
	hush.hp = hush.max_hp * 0.6
	return true


func _record_mission_00() -> Dictionary:
	var hush := level.call(&"hush") as Unit
	return {"max_hp": hush.max_hp, "hp": hush.hp}


func _verify_mission_00() -> Array[String]:
	var bad: Array[String] = []
	var bz: Array = level.get(&"braziers")
	if not (bz[0] as MissionBrazier).lit or not (bz[1] as MissionBrazier).lit or (bz[2] as MissionBrazier).lit:
		bad.append("brazier lit states not kept")
	if int(level.get(&"lit_count")) != 2:
		bad.append("lit_count %d (re-ran the lit handler?)" % int(level.get(&"lit_count")))
	if (level.get(&"_light_markers") as Array).size() != 2:
		bad.append("light markers not back")
	var cast := level.get(&"cast") as M00Cast
	var hush := cast.hush if cast else null
	if hush == null or not is_instance_valid(hush) or not hush.is_alive():
		bad.append("Hush not re-bound")
	else:
		if not hush.death_guard.is_valid():
			bad.append("Hush's guard lost")
		if not hush.damage_taken.is_connected(Callable(cast, &"_on_hush_damaged")):
			bad.append("Hush's damage hook lost")
		if absf(hush.max_hp - float(expect["max_hp"])) > 0.5 or absf(hush.hp - float(expect["hp"])) > 0.05 * hush.max_hp:
			bad.append("Hush HP %.0f / %.0f, saved %.0f / %.0f" % [hush.hp, hush.max_hp, expect["hp"], expect["max_hp"]])
		if cast.hush_state != &"fight":
			bad.append("hush_state %s" % cast.hush_state)
	return bad


func _finish_mission_00() -> String:
	var bz: Array = level.get(&"braziers")
	var cast := level.get(&"cast") as M00Cast
	if sub == 0:
		sub = 1
		(bz[2] as MissionBrazier).light()
		if cast.hush and is_instance_valid(cast.hush):
			cast.hush.take_damage(cast.hush.max_hp * 0.5, _hero())
	if level.objective_state("obj_braziers") == "done" and level.objective_state("sec_hush") == "done":
		return "done" if int(level.get(&"lit_count")) == 3 else "lit_count %d at the end" % int(level.get(&"lit_count"))
	return ""


# ---------------------------------------------------------------- mission 1: 3 braziers (Westwatch last), seal broken

func _prep_mission_01() -> bool:
	var order := [&"hearthward"]
	for row: Array in Mission01.BRAZIER_TABLE:
		if not order.has(row[0]) and row[0] != Mission01.WESTWATCH:
			order.append(row[0])
	order.append(Mission01.WESTWATCH)
	if level.fire_once(&"E4"):   # Pell freed (the cage prop must stay open after the load)
		(level.get(&"pell") as MissionCagedPeddler).open_cage()
	for id: StringName in order:
		var b := level.call(&"brazier", id) as MissionBrazier
		if b:
			b.light()
	return bool(level.get(&"seal_broken"))


func _record_mission_01() -> Dictionary:
	return {}


func _verify_mission_01() -> Array[String]:
	var bad: Array[String] = []
	for b: MissionBrazier in level.get(&"braziers"):
		if not b.lit:
			bad.append("brazier %s cold" % b.brazier_id)
	if int(level.get(&"lit_count")) != 3:
		bad.append("lit_count %d" % int(level.get(&"lit_count")))
	var crown := level.get(&"crown") as EmberCrown
	if crown == null or crown.is_sealed():
		bad.append("crown sealed again (C2-4)")
	var hall := level.get(&"ember_hall") as TrainingBuilding
	var rider := false
	if hall:
		for t in hall.trainable_types():
			rider = rider or t.id == &"blaze_rider"
	if not rider:
		bad.append("Blaze Rider not trainable (C2-7)")
	var ev := false
	for e: Array in level.get(&"_events"):
		ev = ev or e[0] == &"spotlight_tower"
	if not ev and not level.has_fired(&"spotlight_tower"):
		bad.append("spotlight_tower event lost")
	var pell := level.get(&"pell") as MissionCagedPeddler
	if level.has_fired(&"E4") and pell and pell.caged:
		bad.append("Pell caged again")
	return bad


func _finish_mission_01() -> String:
	var crown := level.get(&"crown") as EmberCrown
	if crown:
		_put_hero(crown.global_position)
	if level.objective_state("obj_crown") == "done" and level.objective_state("obj_hold") == "active":
		return "done"
	return ""


# ---------------------------------------------------------------- mission 2: 3 blocks thawed, Heartfrost melted (E10)

func _prep_mission_02() -> bool:
	if sub == 0:
		sub = 1
		for b: MissionBrazier in level.get(&"blocks"):
			b.light()
		var lake := level.get(&"lake") as GlasswaterLake
		lake.break_floe(2)
		lake.crack(5, 2.0, null)
		var hf := level.get(&"heartfrost") as Heartfrost
		hf.hp_floor = 0.0
		hf.take_damage(1.0e9, _hero())
	return bool(level.get(&"heartfrost_freed"))


func _record_mission_02() -> Dictionary:
	return {"squad": _count(Unit.Team.PLAYER, ["flame_guard", "ember_archer"])}


func _verify_mission_02() -> Array[String]:
	var bad: Array[String] = []
	for b: MissionBrazier in level.get(&"blocks"):
		if not b.lit:
			bad.append("block %s frozen again" % b.brazier_id)
	if int(level.get(&"thawed")) != 3:
		bad.append("thawed %d" % int(level.get(&"thawed")))
	var n := _count(Unit.Team.PLAYER, ["flame_guard", "ember_archer"])
	if n > int(expect["squad"]):
		bad.append("Fire squad %d -> %d (re-thaw exploit)" % [int(expect["squad"]), n])
	var hf := level.get(&"heartfrost") as Heartfrost
	if not hf.is_melted or hf.collision_layer != 0:
		bad.append("Heartfrost stands again")
	var lake := level.get(&"lake") as GlasswaterLake
	if not lake.is_open(2):
		bad.append("open floe 2 frozen again")
	if absf(lake.cracks[5] - 2.0) > 0.01:
		bad.append("floe 5 cracks %.2f" % lake.cracks[5])
	return bad


func _finish_mission_02() -> String:
	_put_hero(Mission02.HEARTFROST_POS + Vector3(1.0, 0.0, 0.0))
	if level.objective_state("obj_orb") == "done" and level.objective_state("obj_escape") == "active":
		return "done"
	return ""


# ---------------------------------------------------------------- mission 3: hearts down, barrier gone, E11, a gate down

func _prep_mission_03() -> bool:
	var hearts: Dictionary = level.get(&"hearts")
	match sub:
		0:
			sub = 1
			for id: Variant in hearts:
				(hearts[id] as RootHeart).take_damage(1.0e9, _hero())
		1:
			if bool(level.get(&"barrier_down")):
				sub = 2
		2:
			_put_hero(Mission03.OLDROOT_POS + Vector3(1.0, 0.0, 0.0))
			if level.get(&"race_phase") == &"over":
				sub = 3
		3:
			var gates: Dictionary = level.get(&"gates")
			var ids := gates.keys()
			ids.sort()
			(gates[ids[0]] as WardenGate).take_damage(1.0e9, _hero())
			return int(level.get(&"gates_down")) == 1
	return false


func _record_mission_03() -> Dictionary:
	var stakes := 0
	for s: Variant in level.get(&"stakes"):
		if is_instance_valid(s) and (s as Building).is_alive():
			stakes += 1
	return {"stakes": stakes}


func _verify_mission_03() -> Array[String]:
	var bad: Array[String] = []
	for t in get_nodes_in_group(&"thorn_barrier"):
		if not t.is_queued_for_deletion() and (t as CollisionObject3D).collision_layer != 0:
			bad.append("thorns back (C2-2)")
			break
	for h: Variant in (level.get(&"hearts") as Dictionary).values():
		if (h as RootHeart).is_alive():
			bad.append("heart %s alive again" % (h as RootHeart).heart_id)
	var stakes := 0
	for s: Variant in level.get(&"stakes"):
		if is_instance_valid(s) and (s as Building).is_alive():
			stakes += 1
			if (s as Building).building_type == null or (s as Building).building_type.id != &"ember_stake":
				bad.append("stake type lost")
			if not (s as Building).destroyed.is_connected(Callable(level, &"_on_stake_destroyed")):
				bad.append("stake hook lost")
	if stakes != int(expect["stakes"]) or stakes == 0:
		bad.append("stakes %d -> %d" % [int(expect["stakes"]), stakes])
	var gates: Dictionary = level.get(&"gates")
	var ids := gates.keys()
	ids.sort()
	if (gates[ids[0]] as WardenGate).is_alive():
		bad.append("broken gate stands again (C2-3)")
	if not (gates[ids[1]] as WardenGate).is_open:
		bad.append("open gate closed again (C2-3)")
	return bad


func _finish_mission_03() -> String:
	var gates: Dictionary = level.get(&"gates")
	for g: Variant in gates.values():
		if (g as WardenGate).is_alive():
			(g as WardenGate).take_damage(1.0e9, _hero())
	if level.objective_state("obj_gates") == "done":
		return "done"
	return ""


# ---------------------------------------------------------------- mission 4: war phase after E5, then the Rise

func _prep_mission_04() -> bool:
	level.call(&"_e5_guard_falls_back")
	return level.has_fired(&"E5")


func _record_mission_04() -> Dictionary:
	return {}


func _verify_mission_04() -> Array[String]:
	var bad: Array[String] = []
	for u: Variant in level.get(&"isle_guard"):
		if is_instance_valid(u) and (u as Unit).is_alive() and (u as Unit).is_in_group(MissionBase.SCRIPTED_GROUP):
			bad.append("isle guard scripted again")
			break
	if int(level.get(&"phase")) != 0:
		bad.append("phase %d" % int(level.get(&"phase")))
	return bad


func _finish_mission_04() -> String:
	match sub:
		0:
			sub = 1
			level.call(&"_rise", false)
		1:
			if int(level.get(&"phase")) == 1:
				if SaveGame.block_reason(level) == "":
					return "a save is allowed after the Rise (C2-1)"
				var ks := level.get(&"keystone") as M04Keystone
				(ks.pylons[2] as Unit).queue_free()
				sub = 2
		2:
			var ks := level.get(&"keystone") as M04Keystone
			var p: Variant = level.call(&"_strike_pylon")
			if p != ks.pylons[3]:
				return "_strike_pylon with a freed pylon: %s (C2-5)" % str(p)
			return "done"
	return ""
