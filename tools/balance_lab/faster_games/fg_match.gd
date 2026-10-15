extends "../balance_match.gd"
## Faster-games experiment (docs/balance/faster_games_2026-10-06.md, JS 2026-10-06 "buff / nerf units or add siege
## units ... finish the game faster, try both"). ONE Balance Lab match (balance_match.gd: the variant's units /
## buildings overrides, in memory) plus the variant's optional "fg" block, also in memory and lab-only:
##   "fg": {
##     "siege": {"<unit id>": {"building_mult": 3.0}},   damage this unit deals to a BUILDING x mult (the extra part is
##                                                        dealt through Building.take_damage, same attacker)
##     "prefer_buildings": true,                          siege units point their auto-aggro at an enemy building in
##                                                        attack range (Unit.set_auto_target) before any unit
##     "add_units": [{"id", "kingdom", "path"}],          a lab UnitType added to that kingdom's Hall (after the Hall
##                                                        bowman; the 3 new-units-12 slots follow) and to UnitType.find
##     "bot_share": {"<unit id>": 0.15},                  the bots' target share of soldier pop for that Hall slot
##     "ai": {"<AIProfile knob>": 12 | "x0.8" | "+5"}     bot knobs (both sides)
##     "ai_kingdom": {"ice": {"<knob>": 12 | true}}       bot knobs of that kingdom's bot only (a bool knob takes a bool)
##     "start_workers": 6,                                workers each side starts with (skirmish: 3); the extras are
##                                                        spawned at match start beside the first three, on the home
##                                                        nodes a / b in the same 2:1 pattern (faster_games_2026-10-08.md)
##     "start_crystals": "+150" | 400 | "workers"         starting crystals (Economy.START_CRYSTALS = 250); "workers" =
##                                                        + the crystal cost of the extra start workers
##     "research_off": true                               UnitResearch.lab_off (arm ur_off): no unit research
##     "blitz": {} | {"<PaceSwitch.BLITZ key>": value}    the REAL Blitz pace (Skirmish.blitz_pace = true, PaceSwitch);
##                                                        keys given replace PaceSwitch.BLITZ's (PaceSwitch.tuning) to
##                                                        tune it (docs/balance/blitz_2026-10-10.md)
##   }
## Nothing in data/ or scripts/ is written; the default game never sees any of it.
## Always recorded (any arm, baseline too) in the JSON line under "fg": every building destroyed {t, team, id, kind,
## by, siege} and per team the bonus siege damage, siege units seen, first building / tower / production loss.
## Launched by tools/balance_lab/faster_games/run_fg.py; same flags as balance_match.gd.

const PRODUCTION_KINDS := ["barracks", "stables", "forge", "keep", "market"]

var fg: Dictionary = {}
var _siege_mult := {}          # unit id -> building damage factor
var _prefer := false
var _bot_share := {}           # unit id -> soldier pop share
var _ai_mods := {}
var _ai_kingdom := {}          # kingdom -> {knob: value} (only that kingdom's bot)
var _patched_ai: Array = []    # AIProfile objects already patched (instance ids)
var _hall_order := {}          # kingdom -> Array[UnitType] (what TrainingBuilding.trainable_types lists for a Hall)
var _b_deaths: Array = []
var _bonus := [0.0, 0.0]       # extra siege damage on buildings, by attacking team
var _siege_hits := [0.0, 0.0]  # all damage siege units dealt to buildings (base + extra), by attacking team
var _siege_seen := [{}, {}]    # team -> {unit instance id: type id}
var _in_bonus := false
var _tick_left := 0.0
var _last_t := 0.0
var _added: Array = []
var _blitz_on := false         # fg "blitz": the level plays the real Blitz pace
var _start_log := {}           # side -> {workers, crystals} after the start boost (only when the variant has one)


func apply_variant(data: Dictionary) -> void:
	super.apply_variant(data)
	var raw: Variant = data.get("fg", {})
	if not (raw is Dictionary):
		return
	fg = raw as Dictionary
	var siege: Variant = fg.get("siege", {})
	if siege is Dictionary:
		for id: String in siege:
			_siege_mult[id] = float((siege[id] as Dictionary).get("building_mult", 1.0)) if siege[id] is Dictionary else 1.0
	_prefer = bool(fg.get("prefer_buildings", false))
	if bool(fg.get("research_off", false)):
		UnitResearch.lab_off = true   # arm ur_off (unit-upgrades.md 12): no unit research at all
		print("FG variant %s: unit research OFF" % variant_name)
	var shares: Variant = fg.get("bot_share", {})
	if shares is Dictionary:
		_bot_share = shares
	var mods: Variant = fg.get("ai", {})
	if mods is Dictionary:
		_ai_mods = mods
	var kmods: Variant = fg.get("ai_kingdom", {})
	if kmods is Dictionary:
		_ai_kingdom = kmods
	if fg.get("blitz") is Dictionary:
		_blitz_on = true
		PaceSwitch.tuning = (fg["blitz"] as Dictionary).duplicate(true)
		print("FG variant %s: blitz, tuning %s" % [variant_name, str(PaceSwitch.tuning)])
	for row: Variant in fg.get("add_units", []):
		if row is Dictionary:
			_add_unit(row as Dictionary)
	print("FG variant %s: start workers %s, start crystals %s" % [variant_name, str(fg.get("start_workers", "-")),
			str(fg.get("start_crystals", "-"))])
	print("FG variant %s: siege %s, prefer %s, added %s, shares %s, ai %s" % [variant_name, str(_siege_mult), _prefer,
			str(_added), str(_bot_share), str(_ai_mods)])


## A lab UnitType goes into its kingdom's Hall list: Hall trains = [4 slots, the Hall bowman, the new unit] (the
## bowman is put in explicitly, trainable_types adds it only while the list has fewer than 5), then the new-units-12
## slots as before. UnitType.find learns the id too (its static cache; lab only).
func _add_unit(row: Dictionary) -> void:
	var path := String(row.get("path", ""))
	var t := load(path) as UnitType if ResourceLoader.exists(path) else null
	if t == null:
		variant_errors.append("fg.add_units: can't load %s" % path)
		return
	var bt := load(BUILDING_DIR + String(row.get("kingdom", "")) + "_barracks.tres") as BuildingType
	if bt == null:
		variant_errors.append("fg.add_units: no barracks for %s" % row.get("kingdom", ""))
		return
	_held.append(t)
	_held.append(bt)
	if bt.trains.size() < 5:
		var bow_id: Variant = BowmanKit.HALL_BOWMAN.get(StringName(bt.faction))
		var bow := UnitType.find(String(bow_id)) if bow_id != null else null
		if bow != null and not bt.trains.has(bow):
			bt.trains.append(bow)
	if not bt.trains.has(t):
		bt.trains.append(t)
	UnitType._cache[String(t.id)] = t
	_added.append(String(t.id))


## The Hall list of a kingdom, as TrainingBuilding.trainable_types builds it (trains, bowman if < 5, new-units-12).
func _hall_types(kingdom: String) -> Array:
	if _hall_order.has(kingdom):
		return _hall_order[kingdom]
	var out: Array = []
	var bt := load(BUILDING_DIR + kingdom + "_barracks.tres") as BuildingType
	if bt == null:
		return out
	for t in bt.trains:
		if t:
			out.append(t)
	if out.size() < 5:
		var bow_id: Variant = BowmanKit.HALL_BOWMAN.get(StringName(kingdom))
		var bow := UnitType.find(String(bow_id)) if bow_id != null else null
		if bow != null and not out.has(bow):
			out.append(bow)
	for id: StringName in NewUnits12.HALL_UNITS.get(StringName(kingdom), []):
		var nt := UnitType.find(String(id))
		if nt != null and not out.has(nt):
			out.append(nt)
	_hall_order[kingdom] = out
	return out


## Bot profile patch (the Commander swaps its preset for the kingdom profile on its first tick: patched again then).
func _patch_bots() -> void:
	if _bot_share.is_empty() and _ai_mods.is_empty() and _ai_kingdom.is_empty():
		return
	for team in [PLAYER, ENEMY]:
		var bot: Node = bots[team]
		if bot == null or not is_instance_valid(bot):
			continue
		var ai: Variant = bot.get(&"ai")
		if not (ai is Resource) or _patched_ai.has((ai as Object).get_instance_id()):
			continue
		_patched_ai.append((ai as Object).get_instance_id())
		var types := _hall_types(kingdoms[team])
		if not _bot_share.is_empty():
			for key: StringName in [&"mix_default", &"mix_vs_ranged", &"mix_vs_melee"]:
				var mix: PackedFloat32Array = (ai as Resource).get(key)
				var n := mix.size()
				var touched := false
				for i in types.size():
					var id := String((types[i] as UnitType).id)
					if not _bot_share.has(id) and i < n:
						continue
					var share := float(_bot_share[id]) if _bot_share.has(id) else \
							BowmanKit.bot_share(StringName(id)) + NewUnits12.bot_share(StringName(id))
					if i >= mix.size():
						mix.resize(i + 1)
					mix[i] = share
					touched = true
				# slots between the old end and a new entry keep their kit share (bowman, new units)
				for i in range(n, mix.size()):
					var id2 := StringName((types[i] as UnitType).id)
					if not _bot_share.has(String(id2)):
						mix[i] = BowmanKit.bot_share(id2) + NewUnits12.bot_share(id2)
				if touched:
					(ai as Resource).set(key, mix)
		for k: String in _ai_mods:
			if not (StringName(k) in ai):
				variant_errors.append("fg.ai.%s: no such AIProfile knob" % k)
				continue
			var old: Variant = (ai as Resource).get(StringName(k))
			if not (old is int or old is float):
				continue
			var v := resolve_value(float(old), _ai_mods[k])
			(ai as Resource).set(StringName(k), roundi(v) if old is int else v)
		var own: Variant = _ai_kingdom.get(String(kingdoms[team]), {})
		if own is Dictionary:
			for k: String in own:
				if not (StringName(k) in ai):
					variant_errors.append("fg.ai_kingdom.%s: no such AIProfile knob" % k)
					continue
				var old2: Variant = (ai as Resource).get(StringName(k))
				if old2 is bool:
					(ai as Resource).set(StringName(k), bool(own[k]))
				elif old2 is int or old2 is float:
					var v2 := resolve_value(float(old2), own[k])
					(ai as Resource).set(StringName(k), roundi(v2) if old2 is int else v2)


## Start boost (JS 2026-10-08 "start with more workers"): runs once, on the lab's match-start frame (the skirmish has
## spawned its 3 workers per side in _on_navigation_ready just before).
func _on_match_started() -> void:
	super._on_match_started()
	if not fg.has("start_workers") and not fg.has("start_crystals"):
		return
	for team in [PLAYER, ENEMY]:
		var have: Array = main.call(&"workers_of", team)
		var extra := 0
		var wtype: UnitType = null
		if not have.is_empty():
			wtype = (have[0] as Unit).unit_type
		var want := int(fg.get("start_workers", have.size()))
		var side_sign := 1.0 if team == PLAYER else -1.0
		var start: Vector3 = main.call(&"start_position", team)
		for i in range(have.size(), want):
			if wtype == null:
				variant_errors.append("fg.start_workers: no worker type for team %d" % team)
				break
			var offset := Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2) * side_sign
			var u: Unit = main.call(&"_spawn", Worker.make_unit(wtype), team, start + offset)
			var node: Variant = main.call(&"node_of", team, "a" if i % 3 < 2 else "b")
			if node != null:
				u.call(&"command_gather", node)
			extra += 1
		var eco: Node = _economy(team)
		if eco != null and fg.has("start_crystals"):
			var spec: Variant = fg["start_crystals"]
			var old := int(eco.get(&"crystals"))
			var v := old
			if str(spec) == "workers":
				v = old + extra * (wtype.cost if wtype != null else 0)
			else:
				v = roundi(resolve_value(float(old), spec))
			eco.set(&"crystals", v)
		_start_log[SIDES[team]] = {"workers": (main.call(&"workers_of", team) as Array).size(),
				"crystals": int(eco.get(&"crystals")) if eco != null else -1}
	print("FG start boost: %s" % str(_start_log))


func _on_node_added(node: Node) -> void:
	if _blitz_on and node == main and &"blitz_pace" in node:
		node.set(&"blitz_pace", true)   # before the level's _ready (PaceSwitch.setup reads it there)
	super._on_node_added(node)
	if node.has_signal(&"damaged") and node.has_signal(&"destroyed") and node.has_method(&"target_radius"):
		node.connect(&"damaged", _on_building_damaged.bind(node))
		node.connect(&"destroyed", _on_building_destroyed)


func _on_building_damaged(amount: float, attacker: Node3D, b: Node) -> void:
	if _in_bonus or attacker == null or not is_instance_valid(attacker) or not is_instance_valid(b):
		return
	var t: Variant = attacker.get(&"unit_type")
	if not (t is Resource):
		return
	var id := String((t as Resource).get(&"id"))
	if not _siege_mult.has(id):
		return
	var team := int(attacker.get(&"team"))
	var m := float(_siege_mult[id])
	if team == PLAYER or team == ENEMY:
		_siege_hits[team] += amount
	if m <= 1.0 or not bool(b.call(&"is_alive")):
		return
	_in_bonus = true
	b.call(&"take_damage", amount * (m - 1.0), attacker)
	_in_bonus = false
	if team == PLAYER or team == ENEMY:
		_bonus[team] += amount * (m - 1.0)
		_siege_hits[team] += amount * (m - 1.0)


func _on_building_destroyed(b: Node) -> void:
	if b == null or not is_instance_valid(b):
		return
	var bt: Variant = b.get(&"building_type")
	var killer: Variant = b.get(&"killer")
	var by := ""
	if killer != null and is_instance_valid(killer):
		var kt: Variant = (killer as Object).get(&"unit_type")
		if kt is Resource:
			by = String((kt as Resource).get(&"id"))
		elif (killer as Object).get(&"building_type") is Resource:
			by = "building"
		else:
			by = String((killer as Node).name)
	var t := _last_t
	if main != null and is_instance_valid(main) and main.has_method(&"match_time"):
		t = float(main.call(&"match_time"))
	_b_deaths.append({"t": snappedf(t, 0.1), "team": int(b.get(&"team")),
			"id": String((bt as Resource).get(&"id")) if bt is Resource else "",
			"kind": String((bt as Resource).get(&"kind")) if bt is Resource else "",
			"constructed": bool(b.call(&"is_constructed")) if b.has_method(&"is_constructed") else true,
			"by": by, "siege": _siege_mult.has(by)})


func _process(delta: float) -> bool:
	var r := super._process(delta)
	if main == null or not is_instance_valid(main) or not _started:
		return r
	var t := float(main.call(&"match_time")) if main.has_method(&"match_time") else _last_t
	var dt := t - _last_t
	_last_t = t
	_tick_left -= dt
	if _tick_left > 0.0:
		return r
	_tick_left = 0.5
	_patch_bots()
	if _siege_mult.is_empty():
		return r
	var buildings := get_nodes_in_group(&"buildings")
	for node in get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive() or u.unit_type == null or not _siege_mult.has(String(u.unit_type.id)):
			continue
		if u.team == PLAYER or u.team == ENEMY:
			(_siege_seen[u.team] as Dictionary)[u.get_instance_id()] = String(u.unit_type.id)
		if not _prefer:
			continue
		var cur: Variant = u.attack_target
		if cur != null and is_instance_valid(cur) and (cur as Node).is_in_group(&"buildings"):
			continue
		var best: Node3D = null
		var best_d := u.unit_type.attack_range
		for bn in buildings:
			var b := bn as Node3D
			if b == null or not u.is_enemy_of(b) or not bool(b.call(&"is_alive")):
				continue
			var d := Vector2(b.global_position.x - u.global_position.x, b.global_position.z - u.global_position.z).length() \
					- float(b.call(&"target_radius"))
			if d <= best_d:
				best_d = d
				best = b
		if best != null:
			u.set_auto_target(best)
	return r


func _finish(reason: String, winner: int, error: String) -> bool:
	var was_finished := _finished
	var r := super._finish(reason, winner, error)
	if was_finished or out_path == "":
		return r
	var f := FileAccess.open(out_path, FileAccess.READ)
	if f == null:
		return r
	var data: Variant = JSON.parse_string(f.get_line())
	f.close()
	if not (data is Dictionary):
		return r
	var sides := {}
	for team in [PLAYER, ENEMY]:
		var first := -1.0
		var first_tower := -1.0
		var first_prod := -1.0
		var lost := 0
		for d: Dictionary in _b_deaths:
			if int(d["team"]) != team or not bool(d["constructed"]) or String(d["id"]).ends_with("_wall"):
				continue
			lost += 1
			var tt := float(d["t"])
			if first < 0.0:
				first = tt
			if first_tower < 0.0 and String(d["kind"]) == "tower":
				first_tower = tt
			if first_prod < 0.0 and PRODUCTION_KINDS.has(String(d["kind"])):
				first_prod = tt
		var seen := {}
		for id: String in (_siege_seen[team] as Dictionary).values():
			seen[id] = int(seen.get(id, 0)) + 1
		sides[SIDES[team]] = {"buildings_lost": lost, "first_building_lost": first, "first_tower_lost": first_tower,
				"first_production_lost": first_prod, "siege_bonus_dmg": roundi(_bonus[team]),
				"siege_building_dmg": roundi(_siege_hits[team]), "siege_units": seen}
	var research := {}
	for team: int in [0, 1]:
		var ur: Node = UnitResearch.for_team(team, false)
		var done: Array = []
		if ur != null:
			for rid: StringName in UnitResearch.ROWS:
				if ur.call(&"is_done", rid):
					done.append(String(rid))
		research[SIDES[team]] = done
	data["fg"] = {"active": not fg.is_empty(), "sides": sides, "deaths": _b_deaths, "added": _added, "start": _start_log,
			"blitz": {"on": PaceSwitch.is_blitz(), "tuning": PaceSwitch.tuning}, "research_off": UnitResearch.lab_off,
			"research": research}
	var w := FileAccess.open(out_path, FileAccess.WRITE)
	if w:
		w.store_line(JSON.stringify(data))
		w.close()
	return r
