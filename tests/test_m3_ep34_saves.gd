extends SceneTree
## Mission save hardening M3 (docs/handoff/mission-save-hardening-2026-10-12.md part D Ep3/4, code review C4-1..C4-10):
## every Episode 3 / 4 mission is driven to its risky late step (events forced), saved, rebuilt from the save, checked
## (the state the C4 rows named comes back with its hooks), then pushed to the end (victory) or to the next step.
## Run: tools/godot_run.ps1 --headless --path . -s tests/test_m3_ep34_saves.gd --fixed-fps 60 --quit-after 200000
## Options after '--': only=<substring> (one mission, e.g. only=e4_03). Prints "PASS m3_ep34_saves" or "FAIL ...".

const TASK_ID := "m3_ep34_saves"
## Cases: "<scene>" or "<scene>:<variant>" (a second save point in the same mission).
const MISSIONS := ["mission_e3_01", "mission_e3_02", "mission_e3_03", "mission_e3_04", "mission_e3_04:kneel",
		"mission_e4_01", "mission_e4_02", "mission_e4_03", "mission_e4_04", "mission_e4_04:thaw", "mission_e4_04:warden"]

var missions: Array[String] = []
var index := -1
var level: MissionBase
var step := ""
var frames := 0
var data: Dictionary = {}
var restorer_done := false
var restorer_ok := false
var ended := -1
var fails: Array[String] = []
var report: Array[String] = []
var _note := {}   ## per-mission values recorded before the save


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
		ev.connect(&"mission_ended", func(victory: bool) -> void: ended = 1 if victory else 0)
	_next()


func _next() -> void:
	index += 1
	if level:
		root.remove_child(level)
		level.queue_free()
		level = null
	if index >= missions.size():
		return
	var scene := missions[index].get_slice(":", 0)
	level = (load("res://missions/%s.tscn" % scene) as PackedScene).instantiate() as MissionBase
	level.show_briefing = false
	level.save_campaign_on_victory = false
	level.cinematics_enabled = false
	level.mission_difficulty = 1
	root.add_child(level)
	current_scene = level
	ended = -1
	_note = {}
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
	if level and level.hero and is_instance_valid(level.hero) and level.hero.is_alive():
		level.hero.heal(1.0e6)
	match step:
		"start":
			if level.hero != null and level.match_started and frames > 120 and SaveGame.block_reason(level) == "":
				var why := _prepare(name)
				if why != "":
					return _result(name, "FAIL prepare: " + why)
				_goto("settle")
			elif frames > 6000:
				return _result(name, "FAIL never saveable (%s)" % SaveGame.block_reason(level))
		"settle":
			if frames >= 30:
				var why := SaveGame.block_reason(level)
				if why != "":
					return _result(name, "FAIL save refused at the late step: %s (timers %s)" % [why, _timer_names()])
				_note["time"] = level.mission_time()
				data = SaveGame.capture(level)
				_reload()
				_goto("wait")
		"wait":
			if restorer_done:
				if not restorer_ok:
					return _result(name, "FAIL the restorer failed")
				_goto("verify")
			elif frames > 6000:
				return _result(name, "FAIL the load never finished")
		"verify":
			if frames >= 20:
				var bad := _verify(name)
				if not bad.is_empty():
					return _result(name, "FAIL after the load: " + ", ".join(bad))
				_finish_action(name)
				_goto("finish")
		"finish":
			var r := _finish_check(name)
			if r == "ok":
				return _result(name, "ok (saved at %.0f s)" % float(_note.get("time", 0.0)))
			if r != "" or frames > 1800:
				return _result(name, "FAIL finishing: " + (r if r != "" else "timed out"))
	return false


func _goto(s: String) -> void:
	step = s
	frames = 0


func _result(name: String, what: String) -> bool:
	report.append("  %s: %s" % [name, what])
	print("  %s: %s" % [name, what])
	if what.begins_with("FAIL"):
		fails.append("%s %s" % [name, what])
	_next()
	return false


func _reload() -> void:
	root.remove_child(level)
	level.queue_free()
	level = SaveGame.instantiate_level(data) as MissionBase
	level.save_campaign_on_victory = false
	level.get_node(NodePath(SaveGame.RESTORER_NAME)).set(&"_restore_cinematics", false)
	restorer_done = false
	restorer_ok = false
	level.get_node(NodePath(SaveGame.RESTORER_NAME)).connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		restorer_ok = ok)
	root.add_child(level)
	current_scene = level
	ended = -1


## The pending after() timers by method name ("<lambda>" for one a save cannot write).
func _timer_names() -> Array[String]:
	var out: Array[String] = []
	for t: Array in level.get(&"_timers"):
		var c := t[1] as Callable
		var n := String(c.get_method())
		out.append(n if n != "" and not n.begins_with("<") else "<lambda>")
	return out


static func _hooked(sig: Signal, method: StringName) -> bool:
	return MissionBase.is_hooked(sig, method)


func _skip_to(t: float) -> void:
	if level.mission_time() < t:
		MissionHarness.skip_time(level, t - level.mission_time())


# ---------------------------------------------------------------- per mission: the late step

func _prepare(name: String) -> String:
	var m := level
	match name:
		"mission_e3_01":   # C4-6: ford taken, all three standards ours, the hold running
			var ford := m.get(&"ford_zone") as MissionZone
			ford.set_owner_side(0)
			m.call(&"_on_ford_captured", ford, 0)
			var stds: Dictionary = m.get(&"standards")
			for id: Variant in stds:
				(stds[id] as MissionZone).set_owner_side(0)
				m.call(&"_on_standard_captured", stds[id], 0)
			if m.objective_state("obj_hold") != "active":
				return "obj_hold not active"
			MissionHarness.kill([m.get(&"hush")])   # her 45 s return timer is pending at the save
		"mission_e3_02":   # C4-4: dawn (phase 2)
			m.call(&"_end_night")
			if int(m.get(&"phase")) != 2:
				return "no dawn"
		"mission_e3_03":   # C4-1 / C4-9: a barrow open with its Wardens out, the Sexton risen
			m.call(&"_open_door", &"B1")
			m.call(&"_tick_doors", 100.0)
			m.call(&"_raise_sexton")
			_note["door_units"] = ((m.get(&"door_units") as Dictionary)[&"B1"] as Array).size()
			if m.get(&"sexton") == null or int(_note["door_units"]) == 0:
				return "no Sexton / door Wardens"
		"mission_e3_04":   # Vey on the field (a mid-mission Helper with a death guard)
			m.call(&"_vey_arrives")
			if m.get(&"vey") == null:
				return "no Vey"
		"mission_e4_01":   # C4-7 first horn call at 6:00; C4-2 a bell rung; C4-6 the ford lost
			_skip_to(365.0)
			_note["horn"] = true
			m.call(&"rouse", &"larkford")
			var ford := m.get(&"ford_zone") as MissionZone
			ford.set_owner_side(1)
		"mission_e4_02":   # C4-8 first brook relief at 5:00; C4-3 A1 awake, A3 asleep
			_skip_to(305.0)
			_note["relief"] = true
			m.call(&"_wake_group", &"A1")
		"mission_e4_03":   # C4-10 frost_late pending; C4-5 a grove grown (its heart)
			_skip_to(float(MissionE4_03.FROST_AT) + 2.0)
			m.call(&"_grow", &"hollowfen")
			var h: Variant = ((m.get(&"groves") as Dictionary)[&"hollowfen"] as Dictionary)["heart"]
			if not h is MissionGrove:
				return "no hollowfen heart"
			(h as Building).hp = 450.0
		"mission_e3_04:kneel":   # Vey broken once: the kneel and the wait for the first assault are pending
			m.call(&"_vey_arrives")
			(m.get(&"vey") as Unit).take_damage(1.0e7, null)
		"mission_e4_04:thaw":   # the Winterheart shattered: the thaw is on the code-made types
			m.set(&"heart_opens_at", 0.0)
			var ws: Dictionary = m.get(&"wallwardens")
			for id: Variant in ws:
				m.call(&"_wake_warden", id)
			MissionHarness.kill(ws.values())
			MissionHarness.kill([m.get(&"winterheart")])
			if not bool(m.get(&"thawed")):
				return "no thaw"
		"mission_e4_04:warden":   # one Wallwarden woken and alive
			m.call(&"_wake_warden", &"west")
			var w: Unit = (m.get(&"wallwardens") as Dictionary)[&"west"]
			if w == null or m.is_dormant(w):
				return "the west Wallwarden did not wake"
		"mission_e4_04":   # C4-3 both Wardens down, the Winterheart opened; C4-5 an Elder Treant
			m.set(&"heart_opens_at", 0.0)
			m.call(&"_grant_treant", Vector3(0.0, 0.0, 30.0))
			var ws: Dictionary = m.get(&"wallwardens")
			for id: Variant in ws:
				m.call(&"_wake_warden", id)
			MissionHarness.kill(ws.values())
			if not bool(m.get(&"heart_open")):
				return "the Winterheart did not open (wardens_down %d)" % int(m.get(&"wardens_down"))
	return ""


# ---------------------------------------------------------------- per mission: after the load

func _verify(name: String) -> Array[String]:
	var bad: Array[String] = []
	var m := level
	if m.game_over:
		bad.append("game over")
	match name:
		"mission_e3_01":
			var names := _timer_names()
			if not names.has("_final_second") or not names.has("_hush_back"):
				bad.append("Final / Hush timers lost %s" % [names])
			var ford := m.get(&"ford_zone") as MissionZone
			if ford.owner_side != 0 or not ford.locked:
				bad.append("ford owner %d locked %s" % [ford.owner_side, ford.locked])
			if int(m.call(&"standards_owned", 0)) != 3:
				bad.append("standards owned %d" % int(m.call(&"standards_owned", 0)))
			if m.objective_state("obj_hold") != "active":
				bad.append("obj_hold %s" % m.objective_state("obj_hold"))
		"mission_e3_02":
			var malrik: Wizard = m.get(&"malrik")
			if malrik == null or m.hero != malrik:
				bad.append("hero is not Malrik")
			elif m.is_dormant(malrik) or not malrik.is_in_group(&"heroes"):
				bad.append("Malrik asleep / not a hero")
			var bank := EssenceBank.for_team(Unit.Team.PLAYER)
			if bank == null or not bank.trickle_enabled:
				bad.append("essence trickle off")
			var roster := HelperRoster.for_team(Unit.Team.PLAYER)
			if roster and not roster.is_connected(&"helper_ready", Callable(m, &"_on_helper_ready")):
				bad.append("sec_call hook lost")
			if m.get_node_or_null(NodePath("Bot%d" % MissionE3_02.ALLY_SEAT)) == null:
				bad.append("Torvald's Commander missing")
			var vessa: Wizard = m.get(&"vessa")
			if vessa and m.is_dormant(vessa):
				bad.append("Vessa asleep")
			if m.keep and m.keep.has_meta(TrainingBuilding.META_LOCKED):
				bad.append("base locked")
		"mission_e3_03":
			var sx: Unit = m.get(&"sexton")
			if sx == null or not is_instance_valid(sx) or not sx.is_alive():
				bad.append("Sexton not rebuilt")
			else:
				if sx.unit_type == null or String(sx.unit_type.id) != "sexton":
					bad.append("Sexton typeless")
				if not sx.died.is_connected(Callable(m, &"_on_sexton_fell")):
					bad.append("Sexton fall hook lost")
			if int(m.get(&"sexton_phase")) != 1:
				bad.append("sexton_phase %d" % int(m.get(&"sexton_phase")))
			var units: Array = (m.get(&"door_units") as Dictionary)[&"B1"]
			var n := 0
			for u: Variant in units:
				if u is Unit and is_instance_valid(u):
					n += 1
					if not _hooked((u as Unit).died, &"_on_door_warden_died"):
						bad.append("a door Warden's died hook lost")
						break
			if n != int(_note["door_units"]):
				bad.append("door Wardens %d -> %d" % [int(_note["door_units"]), n])
		"mission_e3_04":
			var v: Variant = m.get(&"vey")
			if not v is Helper or not is_instance_valid(v):
				bad.append("Vey not rebuilt as a Helper")
			else:
				var vh := v as Helper
				if not vh.death_guard.is_valid():
					bad.append("Vey's guard lost")
				if absf(vh.max_hp - float(MissionE3_04.VEY_HP)) > 1.0:
					bad.append("Vey max_hp %.0f" % vh.max_hp)
		"mission_e4_01":
			if (m.get(&"_guests") as Array).is_empty():
				bad.append("no horn call by 6:05 (C4-7)")
			for g: Variant in m.get(&"_guests"):
				if g is Unit and is_instance_valid(g) and ((g as Unit).unit_type == null or (g as Unit).unit_type.pop != 0):
					bad.append("a horn guest came back costing pop")
					break
			var folk: Array = m.get(&"folk")
			var alive := 0
			for f: Variant in folk:
				if f is Unit and is_instance_valid(f) and (f as Unit).is_alive():
					alive += 1
					var fu := f as Unit
					if fu.unit_type == null or String(fu.unit_type.id) != "meadow_folk":
						bad.append("a villager typeless")
						break
					if not fu.died.is_connected(Callable(m, &"_on_folk_died")):
						bad.append("a villager's died hook lost")
						break
			if alive < 6:
				bad.append("villagers %d after the load" % alive)
			if not bool(((m.get(&"bells") as Dictionary)[&"larkford"] as Dictionary)["roused"]):
				bad.append("larkford bell not roused")
			var ford := m.get(&"ford_zone") as MissionZone
			if ford.owner_side != 1:
				bad.append("ford owner %d" % ford.owner_side)
		"mission_e4_02":
			if not (m.get(&"waves_fired") as Array).has(&"RELIEF"):
				bad.append("no brook relief by 5:05 (C4-8)")
			var groups: Dictionary = m.get(&"groups")
			for v: Variant in groups[&"A1"]:
				if v is Unit and is_instance_valid(v) and (v as Unit).is_alive():
					if m.is_dormant(v) or not (v as Unit).is_in_group(&"units"):   # awake: the fog shows / hides it
						bad.append("A1 asleep after the load")
						break
			for v: Variant in groups[&"A3"]:
				if v is Unit and is_instance_valid(v) and (v as Unit).is_alive():
					if not m.is_dormant(v) or (v as Unit).visible:
						bad.append("A3 awake / seen after the load")
						break
			var convoys: Array = m.get(&"convoys")
			if convoys.is_empty() or ((convoys[0] as Dictionary)["walkers"] as Array).is_empty():
				bad.append("no walkers")
			else:
				for w: Variant in (convoys[0] as Dictionary)["walkers"]:
					if w is Unit and is_instance_valid(w) and not (w as Unit).died.is_connected(Callable(m, &"_on_walker_died")):
						bad.append("a walker's died hook lost")
						break
		"mission_e4_03":
			var has_late := false
			for e: Array in m.get(&"_events"):
				if StringName(e[0]) == &"frost_late":
					has_late = true
			if not has_late and not m.has_fired(&"frost_late"):
				bad.append("frost_late not rebuilt (C4-10)")
			var g: Dictionary = (m.get(&"groves") as Dictionary)[&"hollowfen"]
			if g["state"] != &"grown":
				bad.append("hollowfen %s after the load" % g["state"])
			elif not g["heart"] is MissionGrove or not is_instance_valid(g["heart"]) or not (g["heart"] as Building).is_alive():
				bad.append("hollowfen heart not a living MissionGrove (C4-5)")
			else:
				var heart := g["heart"] as MissionGrove
				if not _hooked(heart.destroyed, &"_on_heart_destroyed"):
					bad.append("hollowfen heart's destroyed hook lost")
				if heart.hp < 400.0 or heart.hp > 700.0:
					bad.append("hollowfen heart HP %.0f (saved 450)" % heart.hp)
			var plain := 0
			for b in get_nodes_in_group(&"buildings"):
				var bb := b as Building
				if bb.building_type == null or String(bb.building_type.id) != "ysolde_grove":
					continue
				if not bb is MissionGrove and not bb.is_queued_for_deletion():
					plain += 1
			if plain > 0:
				bad.append("%d plain grove buildings left" % plain)
		"mission_e4_04":
			var wh: Building = m.get(&"winterheart")
			if wh == null or not is_instance_valid(wh):
				bad.append("no Winterheart")
			elif wh.has_meta(Unit.TRUCE_META):
				bad.append("Winterheart still in truce")
			if int(m.get(&"wardens_down")) != 2:
				bad.append("wardens_down %d" % int(m.get(&"wardens_down")))
			var trees: Array = (m.get(&"treants") as Array).filter(func(t: Variant) -> bool: return t is Unit and is_instance_valid(t))
			if trees.is_empty() or String((trees[0] as Unit).unit_type.id) != "elder_treant":
				bad.append("Elder Treant lost")
		"mission_e3_04:kneel":
			if StringName(m.get(&"vey_state")) != &"kneeling" or int(m.get(&"breaks")) != 1:
				bad.append("Vey %s, breaks %d" % [m.get(&"vey_state"), int(m.get(&"breaks"))])
			var names := _timer_names()
			if not names.has("_kneel_done") or not names.has("_launch_due"):
				bad.append("kneel / assault-wait timers lost %s" % [names])
			if not bool(m.get(&"_launch_pending")):
				bad.append("_launch_pending lost")
		"mission_e4_04:thaw":
			var wt: BuildingType = m.get(&"_wall_type")
			var st: BuildingType = m.get(&"_spire_type")
			if wt == null or wt.idle_regen_pct != 0.0:
				bad.append("the Wall regrows after the load")
			if st == null or st.attack_damage != 0.0:
				bad.append("the Wall spires shoot after the load")
		"mission_e4_04:warden":
			var w: Variant = (m.get(&"wallwardens") as Dictionary)[&"west"]
			if not w is Unit or not is_instance_valid(w) or not (w as Unit).is_alive():
				bad.append("the woken Wallwarden is gone")
			else:
				var wu := w as Unit
				if m.is_dormant(wu) or not wu.is_in_group(&"units") or wu.death_guard.is_valid():
					bad.append("the woken Wallwarden is asleep / immortal")
				if not _hooked(wu.died, &"_on_wallwarden_died"):
					bad.append("the Wallwarden's died hook lost")
	return bad


# ---------------------------------------------------------------- per mission: on to the end

func _finish_action(name: String) -> void:
	var m := level
	match name:
		"mission_e3_01":
			m.set(&"hold_left", 0.3)
		"mission_e3_02":
			m.set(&"light_left", 0.3)
		"mission_e3_03":
			var c: Dictionary = m.get(&"candles")
			for id: Variant in c:
				c[id] = true
			MissionHarness.kill([m.get(&"sexton")])
		"mission_e3_04":
			var v := m.get(&"vey") as Unit
			_note["breaks"] = int(m.get(&"breaks"))
			v.take_damage(1.0e7, null)
		"mission_e4_01":
			_note["lost"] = int(m.get(&"folk_lost"))
			for f: Variant in m.get(&"folk"):
				if f is Unit and is_instance_valid(f) and (f as Unit).is_alive():
					MissionHarness.kill([f])
					break
		"mission_e4_02":
			_note["lost"] = int(m.get(&"lost"))
			for w: Variant in ((m.get(&"convoys") as Array)[0] as Dictionary)["walkers"]:
				if w is Unit and is_instance_valid(w) and (w as Unit).is_alive():
					MissionHarness.kill([w])
					break
		"mission_e4_03":   # a grove grows, then the Heartglade: its heart stands, frost_late fires
			var groves: Dictionary = m.get(&"groves")
			for id: Variant in groves:
				if (groves[id] as Dictionary)["state"] != &"grown":
					m.call(&"_grow", id)
		"mission_e4_04":
			MissionHarness.kill([m.get(&"winterheart")])
		"mission_e3_04:kneel":
			MissionHarness.skip_time(m, float(MissionE3_04.KNEEL) + 1.0)
		"mission_e4_04:warden":
			_note["down"] = int(m.get(&"wardens_down"))
			MissionHarness.kill([(m.get(&"wallwardens") as Dictionary)[&"west"]])


## "" = not yet, "ok" = done, else what failed.
func _finish_check(name: String) -> String:
	var m := level
	match name:
		"mission_e3_01", "mission_e3_02", "mission_e3_03":
			if ended == 1:
				return "ok"
			if ended == 0 or m.game_over and ended != 1:
				return "defeat"
		"mission_e3_04":
			if int(m.get(&"breaks")) == int(_note["breaks"]) + 1 and (m.get(&"vey") as Unit).is_alive():
				return "ok"
		"mission_e4_01":
			if int(m.get(&"folk_lost")) == int(_note["lost"]) + 1:
				return "ok"
		"mission_e4_02":
			if int(m.get(&"lost")) == int(_note["lost"]) + 1:
				return "ok"
		"mission_e4_03":
			if frames < 30:
				return ""
			var groves: Dictionary = m.get(&"groves")
			for id: Variant in groves:
				var h: Variant = (groves[id] as Dictionary)["heart"]
				if not h is MissionGrove or not is_instance_valid(h):
					return "grove %s has no heart" % id
				if not _hooked((h as MissionGrove).destroyed, &"_on_heart_destroyed"):
					return "grove %s heart hook lost" % id
			if m.has_fired(&"frost_late"):
				return "ok"
		"mission_e4_04", "mission_e4_04:thaw":
			if bool(m.get(&"thawed")) and m.objective_state("obj_wall") == "done":
				return "ok"
		"mission_e3_04:kneel":   # the kneel ends (Vey rests), then the first assault launches from the saved wait
			if StringName(m.get(&"vey_state")) == &"resting" and not _note.has("skipped"):
				_note["skipped"] = true
				MissionHarness.skip_time(m, maxf(0.0, float(MissionE3_04.ASSAULT_AT[0]) + 1.0 - m.mission_time()))
			elif _note.has("skipped") and int(m.get(&"assault")) >= 1:
				return "ok"
		"mission_e4_04:warden":
			if int(m.get(&"wardens_down")) == int(_note["down"]) + 1:
				return "ok"
	return ""
