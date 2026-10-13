extends SceneTree
## The Forge (docs/design/unit-upgrades.md, ForgeKit / ForgeBuilding), scenes/skirmish.tscn (Fire player).
## - data: 4 Forge types (kind forge, key M, tier 1, max 1), 6 lines per kingdom (Z X C generic 3 levels, V B N unit
##   lines 1 level) whose unit ids exist, modest numbers (<= 10 % / 6 armor / 1 range per level);
## - the game: on in the skirmish, off in a mission / Wave Strike / plain scene; the build menu shows the Forge on M (r2c2)
##   and M starts its placement;
## - the card: 6 research buttons Z X C V B N, no rally, each key badge in the tooltip, pressing each key queues that
##   research or answers its refusal (V B N "Requires Stronghold" at tier 1); a second Z = "Already in progress";
## - research: Weapons 1 lands -> a living Flame Guard and a new one get +6 % damage, a worker / the wizard nothing;
##   cancel = full refund; Weapons 2 needs the Stronghold, level 3 then "Max level";
## - unit lines: Ember Bowstrings +1 range once (idempotent), Lance Drill on the Blaze Rider only, Kiln Focus +25 % mana;
## - UI: the selection panel's Forge row, the Unit Guide's Forge entries, French text;
## - bot: a hard bot builds its Forge (after BOT_BUILD_AT, with the crystals), researches the cheapest line, easy caps
##   at level 1.
## Run:  godot --headless --path . -s tests/test_unit_upgrades.gd --fixed-fps 60 --quit-after 60000

const TASK_ID := "unit_upgrades"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0
const ENEMY := 1

var main: Node
var sel: SelectionManager
var card: CommandCard
var _errors: Array[String] = []
var _msgs: Array[String] = []
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
	_check_data()
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_ok(false, "the skirmish never started")
			_finish()
			return
	await _frames(5)
	await _check_game()
	_finish()


func _finish() -> void:
	Loc.set_language("en")
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _checks])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


# ---------------------------------------------------------------- data

func _check_data() -> void:
	for k: StringName in ForgeKit.FORGE_IDS:
		var t := ForgeKit.forge_type(k)
		_ok(t != null, "%s Forge type loads" % k)
		if t == null:
			continue
		_ok(t.kind == &"forge" and t.hotkey_label == "M" and t.requires_tier == 1 and t.max_count == 1 \
				and t.faction == k and t.cost > 0 and t.requires_kind == &"",
				"%s Forge data (kind %s key %s tier %d max %d)" % [k, t.kind, t.hotkey_label, t.requires_tier, t.max_count])
		var lines := ForgeKit.card_lines(k)
		_ok(lines.size() == 6, "%s card has 6 lines (%d)" % [k, lines.size()])
		for i in lines.size():
			var line := lines[i]
			_ok(ForgeKit.max_level(line) == (3 if i < 3 else 1), "%s %s max level" % [k, line])
			_ok(ForgeKit.is_unit_line(line) == (i >= 3), "%s %s: unit lines on V B N" % [k, line])
			var d := ForgeKit.line_data(line)
			_ok(str(d.get("name", "")) != "" and str(d.get("text", "")) != "", "%s %s name / text" % [k, line])
			for stat: StringName in d.get("stats", {}):
				var v := absf(float(d["stats"][stat]))
				_ok(v <= (0.25 if String(stat).begins_with("ma") else (0.10 if String(stat).ends_with("_pct") else 6.0)),
						"%s %s %s = %s is modest" % [k, line, stat, v])
			_ok(float(d.get("range", 0.0)) <= 1.0, "%s %s range <= 1" % [k, line])
			for uid: StringName in d.get("units", []):
				var ut := UnitType.find(String(uid))
				_ok(ut != null and ut.faction == k, "%s %s unit %s exists in the kingdom" % [k, line, uid])
		_ok(lines[2] == ForgeKit.KINGDOM_LINE[k], "%s kingdom line on C" % k)
	var s1 := ForgeKit.stub(&"weapons", 1)
	var s2 := ForgeKit.stub(&"weapons", 2)
	_ok(s1 != s2 and s1 == ForgeKit.stub(&"weapons", 1) and s1.pop == 0 and s1.requires_tier == 1 \
			and s2.requires_tier == 2 and ForgeKit.stub(&"weapons", 3).requires_tier == 3 \
			and ForgeKit.stub(&"fire_lances", 1).requires_tier == 2, "stubs: cached, pop 0, tiers 1 / 2 / 3, unit lines 2")
	_ok(UnitType.find(String(s1.id)) == null, "a stub id is no unit .tres")


# ---------------------------------------------------------------- the game

func _check_game() -> void:
	sel = main.get(&"selection")
	card = (main.get(&"hud") as GameHUD).command_card
	sel.message.connect(func(t: String) -> void: _msgs.append(t))
	var hero: Wizard = main.get(&"hero")
	var path := StrIntPath.of(hero)
	if path != null and not path.is_locked():
		path.choose(&"str")
	paused = false
	var eco := Economy.for_team(PLAYER)
	eco.add(20000)
	eco.add_pop_bonus(100)
	var ts := TierSystem.instance()
	ts.time_gates = false
	ts.set_tier(PLAYER, 1)
	var keep: Keep = main.get(&"keep")
	var grid: BuildGrid = main.get(&"build_grid")

	# On / off by game.
	_ok(ForgeKit.enabled_here(), "the Forge is on in the skirmish")
	var plain := Node.new()
	var mission_like := Node.new()
	var gd := GDScript.new()
	gd.source_code = "extends \"res://scripts/world/skirmish.gd\"\nfunc define_objectives(_rows: Array) -> void:\n\tpass\n"
	gd.reload()
	var skirmish_like: Node = (load("res://scripts/world/skirmish.gd") as GDScript).new()
	mission_like.free()
	mission_like = gd.new()
	_ok(not ForgeKit.enabled_for(plain) and not ForgeKit.enabled_for(mission_like) and ForgeKit.enabled_for(skirmish_like),
			"enabled_for: plain scene off, mission off, skirmish on")
	plain.free()
	mission_like.free()
	skirmish_like.free()

	# Build menu: M on r2c2 (SC2.U1 5 x 3 card: row 2 = N M), M starts the placement.
	var workers: Array = []
	for u in get_nodes_in_group(&"units"):
		if int(u.get(&"team")) == PLAYER and (u as Unit).is_alive() and u.has_method(&"command_gather") \
				and not SelectionManager.is_caravan(u):
			workers.append(u)
	sel.select_units(workers)
	sel.open_build_menu()
	card.refresh()
	await _frames(1)
	card.refresh()
	var bi := _slot_index("build_fire_forge")
	_ok(bi == 6 and card.key_labels[bi].text == "M" and card.buttons[bi].tooltip_text.get_slice("\n", 0).contains("[M]"),
			"build menu: the Forge on r2c2 with M (slot %d)" % bi)
	_press(KEY_M)
	await _frames(2)
	_ok(sel.placing_type != null and sel.placing_type.id == &"fire_forge", "M in the build menu places the Forge")
	sel.cancel_targeting()
	sel.close_build_menu()

	# The Forge and its card.
	var forge := _spawn(grid, ForgeKit.forge_type(&"fire"), keep, 14, -10) as ForgeBuilding
	_ok(forge != null, "Forge spawned as a ForgeBuilding")
	if forge == null:
		return
	_ok(not forge.is_drop_off() and not forge.is_shop(), "the Forge is no drop-off / shop")
	await _frames(2)
	sel.select_building(forge)
	card.refresh()
	await _frames(1)
	card.refresh()
	var want_keys := ["Z", "X", "C", "V", "B", "N"]
	var lines := ForgeKit.card_lines(&"fire")
	for i in 6:
		var s: Dictionary = card.slots[i]
		var id := "train_" + String(ForgeKit.stub(lines[i], 1).id)
		_ok(str(s.get("id", "")) == id and card.key_labels[i].text == want_keys[i] \
				and card.buttons[i].tooltip_text.get_slice("\n", 0).contains("[%s]" % want_keys[i]),
				"Forge card slot %d = %s [%s] (%s)" % [i, id, want_keys[i], s.get("id", "-")])
	_ok(_slot_index("rally") < 0, "the Forge card has no Set Rally")
	for d: Dictionary in UILabChecks.find_duplicate_badges(card.key_labels):
		_ok(false, "Forge card: letter %s twice" % d["value"])
	# Each key: queues its research or answers the refusal (unit lines: Requires Stronghold at tier 1).
	for i in 6:
		_msgs.clear()
		var q0 := forge.queue.size()
		_press(_code(want_keys[i]))
		await _frames(2)
		if i < 3:
			_ok(forge.queue.size() == q0 + 1 and ForgeKit.stub_line(forge.queue.back()) == lines[i],
					"key %s queues %s" % [want_keys[i], lines[i]])
		else:
			_ok(forge.queue.size() == q0 and _msgs.has(TierSystem.MSG_T2),
					"key %s at tier 1 answers '%s' (%s)" % [want_keys[i], TierSystem.MSG_T2, str(_msgs)])
	_msgs.clear()
	_press(KEY_Z)
	await _frames(2)
	_ok(forge.queue.size() == 3 and _msgs.has(ForgeKit.REASON_WORKING), "second Z: '%s'" % ForgeKit.REASON_WORKING)
	# Cancel = full refund.
	var c0 := eco.crystals
	while not forge.queue.is_empty():
		forge.cancel(forge.queue.size() - 1)
	_ok(eco.crystals == c0 + 300, "cancel refunds 3 x 100 (%d -> %d)" % [c0, eco.crystals])

	# Research lands: living and new soldiers, not workers / the wizard.
	var guard := _unit(&"flame_guard", keep, Vector3(6, 0, 6))
	var archer := _unit(&"ember_archer", keep, Vector3(7, 0, 5))
	var rider := _unit(&"blaze_rider", keep, Vector3(5, 0, 7))
	var kiln := _unit(&"kilnwarden", keep, Vector3(8, 0, 6))
	await _physics(2)
	var base_dmg := guard.get_stat(&"attack_damage")
	var worker: Unit = workers[0]
	var w_dmg := worker.get_stat(&"attack_damage")
	var h_dmg := hero.get_stat(&"attack_damage")
	var stub1 := ForgeKit.stub(&"weapons", 1)
	var keep_time := stub1.train_time
	stub1.train_time = 0.2
	_ok(forge.queue_unit(stub1) == "", "Weapons 1 queued")
	await _physics(30)
	stub1.train_time = keep_time
	_ok(ForgeKit.level_of(PLAYER, &"weapons") == 1, "Weapons 1 researched (level %d)" % ForgeKit.level_of(PLAYER, &"weapons"))
	_ok(is_equal_approx(guard.get_stat(&"attack_damage"), base_dmg * 1.06),
			"living Flame Guard +6 %% (%.2f -> %.2f)" % [base_dmg, guard.get_stat(&"attack_damage")])
	_ok(is_equal_approx(worker.get_stat(&"attack_damage"), w_dmg) and is_equal_approx(hero.get_stat(&"attack_damage"), h_dmg),
			"workers and the wizard get nothing")
	var late := _unit(&"flame_guard", keep, Vector3(4, 0, 8))
	await _frames(2)
	_ok(is_equal_approx(late.get_stat(&"attack_damage"), base_dmg * 1.06), "a new Flame Guard gets Weapons 1 too")
	_ok(late.hp == late.max_hp, "the new unit starts at full HP")
	# Tier gate for level 2, max level.
	var stub2 := ForgeKit.stub(&"weapons", 2)
	_ok(forge.can_queue(stub2) == TierSystem.MSG_T2, "Weapons 2 at tier 1: '%s'" % forge.can_queue(stub2))
	ts.set_tier(PLAYER, 2)
	_ok(forge.can_queue(stub2) == "", "Weapons 2 at the Stronghold can start")
	var bank := ForgeKit.for_team(PLAYER)
	bank.set_level(&"weapons", 3)
	_ok(forge.can_queue(ForgeKit.stub(&"weapons", 3)) == ForgeKit.REASON_MAX, "Weapons 3 done: '%s'" % ForgeKit.REASON_MAX)
	_ok(is_equal_approx(guard.get_stat(&"attack_damage"), base_dmg * 1.18), "Weapons 3 = +18 %")
	bank.set_level(&"armor", 2)
	_ok(is_equal_approx(guard.get_stat(&"armor"), guard.get_base_stat(&"armor") + 12.0), "Armor 2 = +12 armor")
	# Unit lines.
	var r0 := archer.attack_range
	bank.set_level(&"fire_bowstrings", 1)
	bank.refresh_units()
	bank.set_level(&"fire_bowstrings", 1)
	_ok(is_equal_approx(archer.attack_range, r0 + 1.0), "Ember Bowstrings: +1 range once (%.1f -> %.1f)" % [r0, archer.attack_range])
	_ok(is_equal_approx(guard.attack_range, (UnitType.find("flame_guard") as UnitType).attack_range),
			"the Flame Guard's range is untouched")
	var sp0 := rider.get_stat(&"move_speed")
	bank.set_level(&"fire_lances", 1)
	_ok(is_equal_approx(rider.get_stat(&"move_speed"), sp0 + 0.3) and is_equal_approx(guard.get_stat(&"attack_damage"),
			base_dmg * 1.18), "Lance Drill on the Blaze Rider only")
	var m0 := kiln.get_stat(&"max_mana")
	bank.set_level(&"fire_caster", 1)
	_ok(m0 > 0.0 and is_equal_approx(kiln.get_stat(&"max_mana"), m0 * 1.25), "Kiln Focus +25 %% max mana (%.0f)" % m0)
	bank.set_level(&"fire_fury", 1)
	_ok(guard.get_stat(&"attack_cooldown") < guard.get_base_stat(&"attack_cooldown"), "Kindled Fury: faster attacks")

	# UI: selection panel row, Unit Guide, French.
	var row := SelectionPanel.forge_line(guard)
	_ok(row.contains("Weapons 3/3") and row.contains("Armor 2/3") and not row.contains("Lance"), "panel row '%s'" % row)
	_ok(SelectionPanel.forge_line(worker) == "", "no Forge row on a worker")
	var ga := UnitGuideData.forge_abilities(&"blaze_rider")
	_ok(ga.size() == 2 and str(ga[1]["name"]) == "Lance Drill", "Unit Guide: Blaze Rider lists the Forge + Lance Drill")
	_ok(UnitGuideData.forge_abilities(&"cinder_hand").is_empty(), "Unit Guide: no Forge entry on the worker")
	Loc.set_language("fr")
	var fr_row := SelectionPanel.forge_line(guard)
	var fr_tip := Loc.sink(str(ForgeKit.stub(&"weapons", 2).get_meta(&"card_text")))
	var fr_unit := Loc.sink(str(ForgeKit.stub(&"fire_lances", 1).get_meta(&"card_text")))
	var fr_guide := UnitGuideData.ability_text(ga[0])
	var fr_build := Loc.t("Researches Weapons, Armor and kingdom upgrades for all your soldiers, and upgrades for key units. One per kingdom.")
	Loc.set_language("en")
	_ok(fr_row != row and fr_row.begins_with("Forge"), "French panel row '%s'" % fr_row)
	_ok(fr_tip != str(ForgeKit.stub(&"weapons", 2).get_meta(&"card_text")), "French research text '%s'" % fr_tip)
	_ok(fr_unit != str(ForgeKit.stub(&"fire_lances", 1).get_meta(&"card_text")), "French unit research text '%s'" % fr_unit)
	_ok(fr_guide != UnitGuideData.ability_text(ga[0]), "French Unit Guide text '%s'" % fr_guide)
	_ok(fr_build.begins_with("Recherche") or fr_build.begins_with("AmÃ©liore"), "French build tooltip '%s'" % fr_build)

	# Bot: research (hard: the cheapest open line), easy caps at level 1, build.
	for line in lines:
		bank.set_level(line, 0)
	for u in [guard, archer, rider, late]:
		_ok(not (u as Unit).has_modifier(ForgeKit.MODIFIER) or ForgeKit.for_team(PLAYER).stats_for((u as Unit).unit_type.id).is_empty(),
				"levels 0: modifier gone")
	_ok(is_equal_approx(archer.attack_range, r0), "levels 0: range back")
	eco.add(5000)
	ts.set_tier(PLAYER, 3)
	_ok(ForgeKit.bot_step(PLAYER, &"fire", eco, 3000.0, grid, [], keep, 2) and forge.queue.size() == 1 \
			and ForgeKit.stub_line(forge.queue[0]) == &"weapons", "hard bot researches Weapons 1 first")
	_ok(not ForgeKit.bot_step(PLAYER, &"fire", eco, 3001.0, grid, [], keep, 2), "the bot waits BOT_EVERY between checks")
	forge.cancel(0)
	for line in lines:
		bank.set_level(line, 1 if not ForgeKit.is_unit_line(line) else 0)
	_ok(not ForgeKit.bot_step(PLAYER, &"fire", eco, 4000.0, grid, [], keep, 0) and forge.queue.is_empty(),
			"easy bot stops at level 1 and skips unit lines")
	var eeco := Economy.for_team(ENEMY)
	eeco.add(2000)
	var ekeep: Node3D = null
	var eworkers: Array = []
	for b in Building.for_team(ENEMY):
		if b is Keep:
			ekeep = b
	for u in get_nodes_in_group(&"units"):
		if int(u.get(&"team")) == ENEMY and (u as Unit).is_alive() and u.has_method(&"command_build"):
			eworkers.append(u)
	_ok(not ForgeKit.bot_step(ENEMY, &"shadow", eeco, 100.0, grid, eworkers, ekeep, 2), "no Forge before BOT_BUILD_AT")
	_ok(ForgeKit.bot_step(ENEMY, &"shadow", eeco, 400.0, grid, eworkers, ekeep, 2), "hard bot places its Forge at 6:40")
	var site := false
	for b in Building.for_team(ENEMY):
		if b is ForgeBuilding:
			site = true
	_ok(site, "the enemy Forge site exists")


# ---------------------------------------------------------------- helpers

func _spawn(grid: BuildGrid, type: BuildingType, keep: Node3D, fwd: float, side: float) -> Building:
	if type == null:
		return null
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + dir * fwd + Vector3(dir.z, 0, -dir.x) * side, PLAYER)
	return grid.spawn_complete(type, spot, PLAYER) if spot != Vector3.INF else null


func _unit(id: StringName, keep: Node3D, off: Vector3) -> Unit:
	var u: Unit = UnitType.find(String(id)).create_unit()
	u.team = Unit.Team.PLAYER
	main.add_child(u)
	u.global_position = keep.global_position + off
	return u


func _slot_index(id: String) -> int:
	for i in card.slots.size():
		if card.buttons[i].visible and str(card.slots[i].get("id", "")) == id:
			return i
	return -1


func _code(letter: String) -> Key:
	return letter.to_upper().unicode_at(0) as Key


func _press(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)
