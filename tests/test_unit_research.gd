extends SceneTree
## UR.S1 / UR.S2 (docs/design/unit-upgrades.md 7-15): UnitResearch, unit-specific research at the training building.
## - data: 67 rows (55 new + 12 moved Forge lines) + 7 bowman rows; every unit exists in the row's kingdom and is
##   trained by a Hall / Stables / keep of it; gate 1-3, price / time bands (section 8), bowman rows = bowmen.md 4;
##   a unit page holds at most 5 buttons ("+" + rows); kit / effect / mods shapes;
## - the game: on in the skirmish, off in a plain scene, a mission (on with research_enabled), Wave Strike;
## - refusal order (unknown, done, in progress, building, tier, needs, busy, crystals); one research slot per building
##   shared with the "+" (both ways), training never blocked, two Halls = two research at once;
## - cancel = full refund, building destroyed = 75 % refund;
## - apply: living + new units get "research:<id>", others nothing; range +1 once; has / param / effects_of; lab_off;
## - save / load round trip: done rows back, range +1 not doubled, a full-HP unit with +max HP stays full, the
##   research in progress resumes on its Hall.
## Run:  tools/godot_run.ps1 --headless --path . -s tests/test_unit_research.gd --fixed-fps 60 --quit-after 30000

const TASK_ID := "unit_research"
const SCENE := "res://scenes/skirmish.tscn"
const TEST_PATH := "user://saves/_test_unit_research.save"
const PLAYER := 0
const ENEMY := 1
const KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]

var main: Node
var _errors: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_start():
		_finish()
		return
	await _frames(5)
	_check_data()   # in the skirmish: the bowmen / new Hall units are listed only there
	await _check_game()
	_finish()


func _wait_start() -> bool:
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")) or main.get(&"hero") == null:
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_ok(false, "the skirmish never started")
			return false
	return true


func _finish() -> void:
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _checks])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


# ---------------------------------------------------------------- data

func _trained_by_kingdom(k: StringName) -> Dictionary:
	var out := {}
	for kind in ["barracks", "stables", "keep"]:
		var bt := BuildingType.find("%s_%s" % [k, kind])
		if bt == null:
			continue
		for t in bt.trains:
			if t:
				out[t.id] = kind
		if kind == "barracks":
			var bow := BowmanKit.hall_bowman(bt)
			if bow:
				out[bow.id] = kind
			for t in NewUnits12.hall_units(bt):
				out[t.id] = kind
	for t in Stables16.roster_types(k):
		out[t.id] = "stables"
	out[CasterKit.caster_for(k)] = "keep"
	if T3Kit.KEEP_UNITS.has(k):
		out[StringName(T3Kit.KEEP_UNITS[k])] = "keep"
	return out


func _check_data() -> void:
	var stats_ok := [&"max_hp", &"max_mana", &"mana_regen", &"hp_regen", &"attack_damage", &"attack_cooldown",
			&"move_speed", &"armor", &"spell_power", &"cooldown_reduction", &"lifesteal"]
	var kinds_ok := [&"on_hit_status", &"every_nth", &"first_hit", &"bonus_vs_status", &"splash", &"dot", &"thorns",
			&"combat_shield", &"low_hp_status", &"kill_status", &"pack_aura", &"idle_regen"]
	var per_kingdom := {}
	var bowman := 0
	var moved := 0
	var trained := {}
	for k in KINGDOMS:
		trained[k] = _trained_by_kingdom(k)
	for id: StringName in UnitResearch.ROWS:
		var r: Dictionary = UnitResearch.ROWS[id]
		var units: Array = r.get("units", [])
		_ok(not units.is_empty() and str(r.get("name", "")) != "" and str(r.get("text", "")) != "", "%s name / text / units" % id)
		var faction: StringName = &""
		var min_cost := 100000
		for uid: StringName in units:
			var t := UnitType.find(String(uid))
			_ok(t != null, "%s: unit %s exists" % [id, uid])
			if t == null:
				continue
			if faction == &"":
				faction = t.faction
			_ok(t.faction == faction and KINGDOMS.has(faction), "%s: %s in one kingdom (%s)" % [id, uid, t.faction])
			_ok(trained.has(faction) and (trained[faction] as Dictionary).has(uid),
					"%s: %s is trained by a Hall / Stables / keep" % [id, uid])
			_ok(not t.is_worker and not t.is_caravan, "%s: %s is a soldier" % [id, uid])
			min_cost = mini(min_cost, t.cost)
		per_kingdom[faction] = int(per_kingdom.get(faction, 0)) + (0 if r.get("bowman", false) else 1)
		var tier := int(r["tier"])
		var price := int(r["price"])
		var time := float(r["time"])
		_ok(tier >= 1 and tier <= 3, "%s gate %d" % [id, tier])
		var needs: StringName = r.get("needs", &"")
		_ok(needs == &"" or UnitResearch.ROWS.has(needs), "%s needs a known row" % id)
		if bool(r.get("bowman", false)):
			bowman += 1
			var b: Dictionary = BowmanUpgrades.UPGRADES.get(id, {})
			_ok(not b.is_empty() and int(b["crystals"]) == price and is_equal_approx(float(b["time"]), time) \
					and StringName(b["needs"]) == needs and tier == 1 and units == [b["unit"]],
					"%s = bowmen.md 4 row" % id)
		elif bool(r.get("forge", false)):
			moved += 1
			_ok(tier == 2 and price == 125 and is_equal_approx(time, 40.0), "%s moved Forge numbers" % id)
		elif tier == 1:
			_ok(price == (75 if min_cost <= 100 else 100) and is_equal_approx(time, 30.0 if price == 75 else 35.0),
					"%s tier-1 band (cost %d: %d / %.0f)" % [id, min_cost, price, time])
		elif tier == 2:
			_ok((price == 150 or (price == 125 and min_cost < 250)) and is_equal_approx(time, 40.0 if price == 125 else 45.0),
					"%s tier-2 band (cost %d: %d / %.0f)" % [id, min_cost, price, time])
		else:
			_ok(price == (175 if min_cost < 350 else 200) and is_equal_approx(time, 50.0 if price == 175 else 60.0),
					"%s tier-3 band (cost %d: %d / %.0f)" % [id, min_cost, price, time])
		for s: Variant in (r.get("mods", {}) as Dictionary):
			var base := String(s).trim_suffix("_pct")
			_ok(stats_ok.has(StringName(base)), "%s mod %s is a Stats key" % [id, s])
		var e: Dictionary = r.get("effect", {})
		_ok(e.is_empty() or kinds_ok.has(StringName(e.get("kind", &""))), "%s effect kind %s" % [id, e.get("kind", "")])
		_ok(float(r.get("range", 0.0)) >= 0.0 and float(r.get("range", 0.0)) <= 2.0, "%s range" % id)
	_ok(UnitResearch.ROWS.size() == 74, "74 rows (%d)" % UnitResearch.ROWS.size())
	_ok(bowman == 7 and moved == 12, "7 bowman rows (%d), 12 moved Forge lines (%d)" % [bowman, moved])
	_ok(int(per_kingdom.get(&"fire", 0)) == 16 and int(per_kingdom.get(&"shadow", 0)) == 17
			and int(per_kingdom.get(&"ice", 0)) == 17 and int(per_kingdom.get(&"nature", 0)) == 17,
			"rows per kingdom 16 / 17 / 17 / 17 (%s)" % str(per_kingdom))
	# Unit pages: "+" + rows <= 5; spec order examples.
	for k in KINGDOMS:
		for uid: StringName in trained[k]:
			var n := UnitResearch.rows_for_unit(uid).size() + (1 if UnitUpgrades.has_plus(uid) else 0)
			_ok(n <= 5, "%s page: %d buttons" % [uid, n])
	_ok(UnitResearch.rows_for_unit(&"wildwood_archer") == ([&"wildwood_keen_eye", &"wildwood_heartseeker",
			&"wildwood_hunting_party", &"nature_bowstrings"] as Array[StringName]), "Wildwood Archer page order")
	_ok(UnitResearch.rows_for_unit(&"blaze_rider") == ([&"blaze_rider_running_start", &"fire_lances"] as Array[StringName]),
			"Blaze Rider page order")
	_ok(UnitResearch.rows_for_unit(&"cinder_hand").is_empty() and UnitResearch.rows_for_unit(&"rimehorn_rider").is_empty()
			and UnitResearch.rows_for_unit(&"stormbottle_genie").is_empty(), "no rows: worker, Rimehorn Rider, Genie")


# ---------------------------------------------------------------- the game

func _check_game() -> void:
	for n in main.find_children("*", "Commander", true, false):
		n.set(&"enabled", false)
	var eco := Economy.for_team(PLAYER)
	eco.add(20000)
	eco.add_pop_bonus(100)
	var ts := TierSystem.instance()
	ts.time_gates = false
	ts.set_tier(PLAYER, 1)
	var keep: Keep = main.get(&"keep")
	var grid: BuildGrid = main.get(&"build_grid")

	# On / off by game.
	_ok(UnitResearch.enabled_here(), "research is on in the skirmish")
	var plain := Node.new()
	var gd := GDScript.new()
	gd.source_code = "extends \"res://scripts/world/skirmish.gd\"\nvar research_enabled := false\n" \
			+ "func define_objectives(_rows: Array) -> void:\n\tpass\n"
	gd.reload()
	var mission_like: Node = gd.new()
	var skirmish_like: Node = (load("res://scripts/world/skirmish.gd") as GDScript).new()
	var ws: Node = (load("res://scripts/world/wave_strike/wave_strike_level.gd") as GDScript).new()
	_ok(not UnitResearch.enabled_for(plain) and not UnitResearch.enabled_for(mission_like)
			and UnitResearch.enabled_for(skirmish_like) and not UnitResearch.enabled_for(ws),
			"enabled_for: plain off, mission off, skirmish on, Wave Strike off")
	mission_like.set(&"research_enabled", true)
	_ok(UnitResearch.enabled_for(mission_like), "a mission with research_enabled is on")
	var mb: Node = (load("res://scripts/campaign/mission_base.gd") as GDScript).new()
	_ok(&"research_enabled" in mb and not bool(mb.get(&"research_enabled")), "MissionBase has the research_enabled knob (off)")
	for n: Node in [plain, mission_like, skirmish_like, ws, mb]:
		n.free()

	var bank := UnitResearch.for_team(PLAYER)
	_ok(bank != null and bank.is_in_group(&"saved_state") and bank.save_key() == "unit_research_0", "team node + save key")
	var hall := _spawn(grid, BuildingType.find("fire_barracks"), keep, 14, -10)
	var hall2 := _spawn(grid, BuildingType.find("fire_barracks"), keep, 14, 10)
	_ok(hall != null and hall2 != null, "two Halls spawned")
	if hall == null or hall2 == null:
		return
	await _physics(2)

	# Refusal order.
	_ok(bank.can_buy(&"nope", hall) == UnitResearch.REASON_UNKNOWN, "unknown id")
	_ok(bank.can_buy(&"flame_guard_kindled_mail", keep) == UnitResearch.REASON_BUILDING, "a keep does not train Flame Guards")
	_ok(bank.can_buy(&"fire_caster", hall) == UnitResearch.REASON_BUILDING, "a Hall does not train the Kilnwarden")
	_ok(bank.can_buy(&"flame_guard_backdraft", hall) == TierSystem.MSG_T2, "tier-2 row at tier 1: '%s'" % bank.can_buy(&"flame_guard_backdraft", hall))
	_ok(bank.can_buy(&"fire_caster", keep) == TierSystem.MSG_T2, "Kiln Focus at the keep, tier 1: Requires Stronghold")
	_ok(bank.can_buy(&"kilnwarden_molten_slag", keep) == TierSystem.MSG_T3, "tier-3 row: Requires Citadel")
	_ok(bank.can_buy(&"scorchbow_pitch_arrows", hall) == UnitResearch.REASON_NEEDS % "Heavy Draw",
			"bowman chain: '%s'" % bank.can_buy(&"scorchbow_pitch_arrows", hall))
	var c0 := eco.crystals
	_ok(bank.buy(&"flame_guard_kindled_mail", hall) == "" and eco.crystals == c0 - 75, "Kindled Mail started (75)")
	_ok(bank.can_buy(&"flame_guard_kindled_mail", hall2) == UnitResearch.REASON_WORKING, "same row again: in progress")
	_ok(bank.can_buy(&"ember_archer_quick_nock", hall) == UnitResearch.REASON_BUSY, "same Hall: busy")
	_ok(bank.working_at(hall) == &"flame_guard_kindled_mail" and UnitResearch.building_busy(hall)
			and not UnitResearch.building_busy(hall2), "working_at / building_busy")
	_ok(bank.can_buy(&"ember_archer_quick_nock", hall2) == "", "a second Hall can run a second research")
	ts.set_tier(PLAYER, 2)
	var plus := UnitUpgrades.for_team(PLAYER)
	_ok(plus.can_buy(&"ember_archer", hall) == UnitUpgrades.REASON_BUSY and UnitUpgrades.REASON_BUSY == UnitResearch.REASON_BUSY,
			"the '+' at a Hall running a row: '%s'" % plus.can_buy(&"ember_archer", hall))
	_ok(plus.buy(&"ember_archer", hall2) == "", "the '+' at the free Hall")
	_ok(bank.can_buy(&"ember_archer_quick_nock", hall2) == UnitResearch.REASON_BUSY, "a row at a Hall running a '+': busy")
	plus.cancel(&"ember_archer")
	# Training never blocked.
	_ok(hall.queue_unit(UnitType.find("flame_guard")) == "", "the Hall still trains while researching")
	hall.cancel(0)
	# Crystals.
	var keep_c := eco.crystals
	eco.crystals = 10
	_ok(bank.can_buy(&"ember_archer_quick_nock", hall2) == UnitResearch.REASON_NO_CRYSTALS, "not enough crystals")
	eco.crystals = keep_c
	# options_for_unit (UI rows).
	var opts := UnitResearch.options_for_unit(hall, &"flame_guard")
	_ok(opts.size() == 2 and opts[0]["state"] == &"working" and opts[1]["state"] == &"locked"
			and opts[1]["reason"] == UnitResearch.REASON_BUSY and int(opts[0]["crystals"]) == 75, "options_for_unit rows %s" % str(opts))
	_ok(UnitResearch.unit_ids_for_building(hall).has(&"flame_guard") and UnitResearch.unit_ids_for_building(hall).has(&"scorchbow")
			and not UnitResearch.unit_ids_for_building(hall).has(&"cinder_hand"), "unit_ids_for_building(Hall)")
	_ok(UnitResearch.unit_ids_for_building(keep).has(&"kilnwarden"), "unit_ids_for_building(keep) lists the caster")

	# Cancel = full refund; destroyed = 75 %.
	var c1 := eco.crystals
	bank.cancel(&"flame_guard_kindled_mail")
	_ok(eco.crystals == c1 + 75 and not bank.is_working(&"flame_guard_kindled_mail"), "cancel: full refund")
	_ok(bank.buy(&"ember_archer_quick_nock", hall2) == "", "Quick Nock at Hall 2")
	var c2 := eco.crystals
	hall2.take_damage(1.0e9, null)
	await _physics(3)
	_ok(not bank.is_working(&"ember_archer_quick_nock") and eco.crystals == c2 + 56,
			"Hall destroyed: 75 %% refund (%d -> %d)" % [c2, eco.crystals])

	# Apply: living and new units.
	var guard := _unit(&"flame_guard", keep, Vector3(6, 0, 6))
	var archer := _unit(&"ember_archer", keep, Vector3(7, 0, 5))
	var hurler := _unit(&"ash_hurler", keep, Vector3(5, 0, 8))
	var scorch := _unit(&"scorchling", keep, Vector3(8, 0, 8))
	var enemy_guard := _unit(&"flame_guard", keep, Vector3(30, 0, 30), Unit.Team.ENEMY)
	await _physics(2)
	var armor0 := guard.get_stat(&"armor")
	var hp0 := hurler.max_hp
	var r0 := archer.attack_range
	var ar_base := (UnitType.find("ember_archer") as UnitType).attack_range
	_ok(bank.buy(&"flame_guard_kindled_mail", hall) == "", "Kindled Mail again")
	var w: Dictionary = {}
	for row: Dictionary in bank.get(&"_work"):
		w = row
	w["left"] = 0.2
	var completed: Array[StringName] = []
	bank.research_completed.connect(func(id: StringName) -> void: completed.append(id))
	await _physics(30)
	_ok(UnitResearch.team_has(PLAYER, &"flame_guard_kindled_mail") and completed == ([&"flame_guard_kindled_mail"] as Array[StringName]),
			"Kindled Mail researched (signal)")
	_ok(guard.has_modifier(&"research:flame_guard_kindled_mail") and is_equal_approx(guard.get_stat(&"armor"), armor0 + 5.0),
			"living Flame Guard +5 armor")
	_ok(not enemy_guard.has_modifier(&"research:flame_guard_kindled_mail"), "the enemy's Flame Guard gets nothing")
	_ok(not archer.has_modifier(&"research:flame_guard_kindled_mail"), "the archer gets nothing")
	var late := _unit(&"flame_guard", keep, Vector3(4, 0, 8))
	await _frames(2)
	_ok(late.has_modifier(&"research:flame_guard_kindled_mail"), "a new Flame Guard gets it too")
	bank.grant(&"fire_bowstrings")
	bank.refresh_units()
	UnitResearch.apply_to(archer)
	_ok(is_equal_approx(archer.attack_range, r0 + 1.0), "Ember Bowstrings +1 range once (%.1f -> %.1f)" % [r0, archer.attack_range])
	bank.grant(&"ash_hurler_wheeled_mantlet")
	_ok(is_equal_approx(hurler.max_hp, hp0 * 1.35) and is_equal_approx(hurler.hp, hurler.max_hp), "Wheeled Mantlet +35 % HP")
	# has / param / effects_of.
	_ok(UnitResearch.param(scorch, &"flashpoint_damage", 15.0) == 15.0, "param default before the row")
	bank.grant(&"scorchling_volatile_core")
	bank.grant(&"flame_guard_backdraft")
	_ok(UnitResearch.param(scorch, &"flashpoint_damage", 15.0) == 25.0 and UnitResearch.param(guard, &"flashpoint_damage", 15.0) == 15.0,
			"param: the Scorchling's row, not the guard's")
	_ok(UnitResearch.has(guard, &"flame_guard_backdraft") and not UnitResearch.has(enemy_guard, &"flame_guard_backdraft")
			and not UnitResearch.has(archer, &"flame_guard_backdraft"), "has(unit, id)")
	var fx := UnitResearch.effects_of(guard)
	_ok(fx.size() == 1 and fx[0]["kind"] == &"thorns" and UnitResearch.effects_of(enemy_guard).is_empty(), "effects_of")
	UnitResearch.lab_off = true
	_ok(UnitResearch.param(scorch, &"flashpoint_damage", 15.0) == 15.0 and UnitResearch.effects_of(guard).is_empty()
			and bank.can_buy(&"ember_archer_quick_nock", hall) == UnitResearch.REASON_UNKNOWN, "lab_off: nothing applies")
	UnitResearch.lab_off = false

	# Save / load round trip: a research in progress on the Hall.
	ts.set_tier(PLAYER, 1)
	_ok(bank.buy(&"ember_archer_quick_nock", hall) == "", "Quick Nock running at save time")
	await _physics(2)
	var why := SaveGame.block_reason(main)
	_ok(why == "", "save allowed (%s)" % why)
	_ok(SaveGame.write_file(TEST_PATH, SaveGame.capture(main)) == "", "save written")
	var data := SaveGame.read_file(TEST_PATH)
	_ok(not data.has("error"), "save read")
	var old := main
	root.remove_child(old)
	old.queue_free()
	main = SaveGame.instantiate_level(data)
	var state := {"done": false}
	var r := main.get_node(NodePath(SaveGame.RESTORER_NAME))
	r.connect(&"finished", func(ok: bool) -> void:
		state["done"] = true
		_ok(ok, "the restorer reported success"))
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(state["done"]):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_ok(false, "the load never finished")
			return
	await _frames(3)
	var bank2 := UnitResearch.for_team(PLAYER, false)
	_ok(bank2 != null and bank2 != bank and bank2.is_done(&"fire_bowstrings") and bank2.is_done(&"flame_guard_kindled_mail")
			and UnitResearch.team_has(PLAYER, &"ash_hurler_wheeled_mantlet"), "done rows back after the load")
	_ok(bank2 != null and bank2.is_working(&"ember_archer_quick_nock") and _hall_running(bank2) != null,
			"the research in progress resumes on its Hall")
	var a2 := _first(&"ember_archer")
	_ok(a2 != null and is_equal_approx(a2.attack_range, ar_base + 1.0),
			"loaded archer range %.2f (want %.2f, not doubled)" % [a2.attack_range if a2 else -1.0, ar_base + 1.0])
	var g2 := _first(&"flame_guard")
	_ok(g2 != null and g2.has_modifier(&"research:flame_guard_kindled_mail"), "loaded Flame Guard has its research")
	var h2 := _first(&"ash_hurler")
	_ok(h2 != null and is_equal_approx(h2.max_hp, hp0 * 1.35) and h2.hp >= h2.max_hp - 0.5,
			"loaded full-HP Ash Hurler stays full (%.1f / %.1f)" % [h2.hp if h2 else -1.0, h2.max_hp if h2 else -1.0])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


# ---------------------------------------------------------------- helpers

func _hall_running(b: UnitResearch) -> Node:
	for n in Building.for_team(PLAYER):
		if n.is_alive() and n.building_type and n.building_type.kind == &"barracks" and b.working_at(n) == &"ember_archer_quick_nock":
			return n
	return null


func _first(id: StringName) -> Unit:
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == PLAYER and u.unit_type and u.unit_type.id == id and u.is_alive():
			return u
	return null


func _spawn(grid: BuildGrid, type: BuildingType, keep: Node3D, fwd: float, side: float) -> Building:
	if type == null:
		return null
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + dir * fwd + Vector3(dir.z, 0, -dir.x) * side, PLAYER)
	return grid.spawn_complete(type, spot, PLAYER) if spot != Vector3.INF else null


func _unit(id: StringName, keep: Node3D, off: Vector3, team: int = Unit.Team.PLAYER) -> Unit:
	var u: Unit = UnitType.find(String(id)).create_unit()
	u.team = team
	main.add_child(u)
	u.global_position = keep.global_position + off
	return u
