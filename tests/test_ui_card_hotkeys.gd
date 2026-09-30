extends SceneTree
## JS 2026-09-29 ("hotkey should the unit or building it its" = every unit / building shows its own hotkey on its button).
## Skirmish, the 4 player kingdoms in turn. For every command card the player can see (keep at tiers 1 / upgrading / 2 / 3
## and with the helper out, Hall at tiers 1 / 2 and its "+" page, Stables, Bazaar, a construction site, workers, the
## build menu, a soldier, the wizard, a mixed group, a caravan, the helper's stances) and for the tavern and trade windows:
## - every button that trains, builds, upgrades, hires, casts or sets a stance shows a key badge (bottom-right, font 12,
##   KEY_COLOR, inside the button) and its tooltip's first line names the same key;
## - no letter twice on one card (UILabChecks.find_duplicate_badges, the UI Lab's hotkey check);
## - the letter is the physical key that really acts: pressing it does what the button does (queues that unit, starts
##   that placement / research / upgrade, sets that stance, hires that champion), or answers the button's refusal;
## - AZERTY (label keys as the OS reports them): the badges and tooltips show the letters printed on that keyboard, "," on
##   the physical M key and ";" on the physical , key (never "Comma");
## - a unit keeps its key: the keep's tier-3 unit and helper call keep C / V from tier 1 to the Citadel;
## - UnitType.card_key is the letter of the unit's button (on at least one card that trains it).
## - caster-units.md 3.2 / 3.3: the keep's caster on B (r2c1, greyed "Requires Stronghold" at tier 1, B at the Citadel),
##   Set Rally at r3c1; a caster card = M C H X/A + Z V (its spells; the key starts aiming or answers the refusal).
## Run:  godot --headless --path . -s tests/test_ui_card_hotkeys.gd --fixed-fps 60 --quit-after 200000
##   Options after `--`: kingdoms=fire,ice (default all four)

const TASK_ID := "ui_card_hotkeys"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0
## QWERTY letter shown -> physical key (single letters: their own code).
const NAMED_KEYS := {"Del": KEY_DELETE, "Esc": KEY_ESCAPE, ",": KEY_COMMA, "+": KEY_EQUAL}
## AZERTY through the OS path: physical key -> the label key the OS reports (KeyLabels turns them into characters).
const AZERTY := {KEY_Z: KEY_W, KEY_W: KEY_Z, KEY_A: KEY_Q, KEY_Q: KEY_A, KEY_M: KEY_COMMA, KEY_COMMA: KEY_SEMICOLON,
		KEY_SEMICOLON: KEY_M}
const AZERTY_TEXT := {"Z": "W", "W": "Z", "A": "Q", "Q": "A", "M": ",", ",": ";"}
## Buttons that must show a key (by slot id).
const SPELL_IDS: Array[String] = ["fireball", "ember_step", "kindle"]

var kingdoms: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
var main: Node
var sel: SelectionManager
var card: CommandCard
var hud: GameHUD
var _k: StringName = &""
var _errors: Array[String] = []
var _msgs: Array[String] = []
var _checked := 0            # buttons checked
var _pressed := 0            # keys pressed and verified
var _unit_keys := {}         # unit id -> {shown letters} over every card (card_key check)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("kingdoms="):
			kingdoms.clear()
			for s in a.trim_prefix("kingdoms=").split(",", false):
				kingdoms.append(StringName(s))
	_run.call_deferred()


func _run() -> void:
	GameSettings.ensure_read()
	GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC, false)
	KeyLabels.overrides = {}
	for k in kingdoms:
		_k = k
		await _kingdom(k)
	KeyLabels.overrides = {}
	if _errors.is_empty():
		print("PASS %s (%d kingdoms, %d buttons, %d keys pressed)" % [TASK_ID, kingdoms.size(), _checked, _pressed])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 40))])
	quit(0 if _errors.is_empty() else 1)


func _fail(what: String) -> void:
	_errors.append("%s: %s" % [_k, what])
	print("  x %s: %s" % [_k, what])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# ---------------------------------------------------------------- one kingdom

func _kingdom(k: StringName) -> void:
	print("---- %s" % k)
	_unit_keys.clear()
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", k)
	main.set(&"enemy_kingdom", &"fire" if k == &"shadow" else &"shadow")
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_fail("the skirmish never started")
			return
	await _frames(5)
	sel = main.get(&"selection")
	hud = main.get(&"hud")
	card = hud.command_card
	sel.message.connect(func(t: String) -> void: _msgs.append(t))
	var hero: Wizard = main.get(&"hero")
	var path := StrIntPath.of(hero)
	if path != null and not path.is_locked():
		path.choose(&"str")   # the windowed start panel pauses the game until a path is chosen
	paused = false
	var eco := Economy.for_team(PLAYER)
	eco.add(60000)
	eco.add_pop_bonus(150)
	var ess := EssenceBank.for_team(PLAYER)
	if ess:
		ess.add(9000)
	for g in get_nodes_in_group(&"gold_banks"):
		if int(g.get(&"team")) == PLAYER and g.has_method(&"add"):
			g.call(&"add", 5000)
	var ts := TierSystem.instance()
	if ts == null:
		_fail("no TierSystem in the skirmish")
		return
	ts.time_gates = false
	ts.set_tier(PLAYER, 1)
	for t in get_nodes_in_group(&"taverns"):
		t.set(&"open_time", 0.0)
	var keep: Keep = main.get(&"keep")
	var grid: BuildGrid = main.get(&"build_grid")
	var hall := _spawn(grid, BuildingType.find("%s_barracks" % k), keep, 16, 0)
	var stables := _spawn(grid, Stables16.stables_type(k), keep, 16, 14)
	var market := _spawn(grid, BuildingType.find("%s_market" % k), keep, 9, -12)
	var tower_type := BuildingType.find("%s_tower" % k)
	var site_spot := grid.find_spot(tower_type, keep.global_position + Vector3(0, 0, 20), PLAYER)
	var site: Building = grid.place(tower_type, site_spot, PLAYER, []) if site_spot != Vector3.INF else null
	if hall == null or stables == null or market == null or site == null:
		_fail("test buildings not placed (Hall %s, Stables %s, Bazaar %s, site %s)" % [hall, stables, market, site])
		return
	await _frames(3)
	var workers: Array = []
	for u in get_nodes_in_group(&"units"):
		if int(u.get(&"team")) == PLAYER and (u as Unit).is_alive() and u.has_method(&"command_gather") \
				and not SelectionManager.is_caravan(u):
			workers.append(u)
	var soldier: Unit = (hall.trainable_types()[0] as UnitType).create_unit()
	soldier.team = Unit.Team.PLAYER
	main.add_child(soldier)
	soldier.global_position = keep.global_position + Vector3(6, 0, 6)
	var caravan: Unit = Worker.make_unit(UnitType.find("caravan"))
	caravan.team = Unit.Team.PLAYER
	main.add_child(caravan)
	caravan.global_position = keep.global_position + Vector3(-6, 0, 6)
	await _frames(3)

	# Keep: tier 1, upgrading, tier 2, Citadel. The tier-3 unit and the helper call keep their keys.
	var t3_id := "train_" + String(T3Kit.KEEP_UNITS[k])
	var call_id := "train_" + String(HelperRoster.CALL_ID)
	var caster_id := "train_" + String(CasterKit.caster_for(k))
	var select_keep := func() -> void: sel.select_building(keep)
	var tier1 := await _card("keep tier 1", select_keep)
	_expect_ids(tier1, ["train_" + String(keep.building_type.trains[0].id), "train_keep_upgrade", t3_id, call_id, caster_id,
			"rally"], "keep tier 1")
	if _slot_of(tier1, caster_id) != 4 or _key_of(tier1, caster_id) != "B" or _slot_of(tier1, "rally") != 8:
		_fail("keep caster on %d key '%s', rally on %d (want B on r2c1, rally r3c1)" % [_slot_of(tier1, caster_id),
				_key_of(tier1, caster_id), _slot_of(tier1, "rally")])
	var caster_row: Dictionary = tier1[_ids(tier1).find(caster_id)] if _ids(tier1).has(caster_id) else {}
	if caster_row.is_empty() or caster_row["reason"] != TierSystem.MSG_T2:
		_fail("keep caster at tier 1 not greyed with '%s' (%s)" % [TierSystem.MSG_T2, caster_row.get("reason", "-")])
	var r := keep.upgrade()
	if r != "":
		_fail("keep.upgrade() refused: %s" % r)
	await _card("keep upgrading", select_keep)
	keep.cancel_upgrade()
	ts.set_tier(PLAYER, 2)
	await _card("keep tier 2", select_keep)
	ts.set_tier(PLAYER, 3)
	var tier3 := await _card("keep Citadel", select_keep)
	for id: String in [t3_id, call_id, caster_id]:
		if _key_of(tier1, id) == "" or _key_of(tier1, id) != _key_of(tier3, id):
			_fail("%s changed key from tier 1 (%s) to the Citadel (%s)" % [id, _key_of(tier1, id), _key_of(tier3, id)])
	if _key_of(tier3, "train_keep_upgrade") != "" or _slot_of(tier3, t3_id) != 2:
		_fail("Citadel keep card %s: the tier slot X must stay empty, the tier-3 unit on C" % str(_ids(tier3)))
	# Hall: tier 1 (tier-2 units refused on their own key), tier 2, the "+" page (keys = the units' own keys).
	ts.set_tier(PLAYER, 1)
	var select_hall := func() -> void: sel.select_building(hall)
	var hall1 := await _card("Hall tier 1", select_hall)
	if hall1.size() < 9 or _key_of(hall1, "plus_page") != SelectionManager.UPGRADES_KEY_LABEL:
		_fail("Hall card %s (8 units, rally, + %s)" % [str(_ids(hall1)), _key_of(hall1, "plus_page")])
	ts.set_tier(PLAYER, 2)
	var hall2 := await _card("Hall tier 2", select_hall)
	var plus := await _card("Hall + page", func() -> void:
		sel.select_building(hall)
		sel.open_upgrades())
	for row: Dictionary in plus:
		var id: String = row["id"]
		if id.begins_with("plus_") and id != "plus_back" and row["key"] != _key_of(hall2, "train_" + id.trim_prefix("plus_")):
			_fail("+ page: %s shows '%s', its unit's training key is '%s'" % [id, row["key"],
					_key_of(hall2, "train_" + id.trim_prefix("plus_"))])
	await _check_upgrades_page_keys(hall)
	# Stables, Bazaar, a construction site (Citadel: everything open).
	ts.set_tier(PLAYER, 3)
	await _card("Stables", func() -> void: sel.select_building(stables))
	await _card("Bazaar", func() -> void: sel.select_building(market))
	await _card("site", func() -> void: sel.select_building(site))
	# Units: workers, the build menu, a soldier, the wizard, a mixed group, a caravan (Classic and Hero WASD letters).
	await _card("workers", func() -> void: sel.select_units(workers))
	var menu := await _card("build menu", func() -> void:
		sel.select_units(workers)
		sel.open_build_menu())
	_check_build_menu_places(menu)
	await _card("soldier", func() -> void: sel.select_units([soldier]))
	# caster-units.md: a caster card (M C H X/A + Z V) and a caster + soldier group (Z / V act from any subgroup).
	var caster: Unit = UnitType.find(String(CasterKit.caster_for(k))).create_unit()
	caster.team = Unit.Team.PLAYER
	main.add_child(caster)
	caster.global_position = keep.global_position + Vector3(8, 0, 4)
	await _frames(2)
	var cab := CasterKit.ability_of(caster)
	if cab:
		cab.mana = 200.0
	var ccard := await _card("caster", func() -> void: sel.select_units([caster]))
	var zv := CasterKit.spells_of(caster.unit_type.id)
	if _key_of(ccard, "caster_" + String(zv[0])) != "Z" or _key_of(ccard, "caster_" + String(zv[1])) != "V" \
			or _slot_of(ccard, "caster_" + String(zv[0])) != 4 or _slot_of(ccard, "caster_" + String(zv[1])) != 5:
		_fail("caster card %s: Z / V on r2c1 / r2c2" % str(_ids(ccard)))
	await _card("caster + soldier", func() -> void: sel.select_units([caster, soldier]))
	await _card("wizard", func() -> void: sel.select_units([hero]))
	await _card("mixed", func() -> void: sel.select_units([hero, soldier, workers[0]]))
	await _card("caravan", func() -> void: sel.select_units([caravan]))
	GameSettings.set_control_scheme(GameSettings.CONTROLS_HERO_WASD, false)
	await _card("mixed (Hero WASD)", func() -> void: sel.select_units([hero, soldier, workers[0]]))
	GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC, false)
	# The helper: call it (fast), inspect it: Z X C = its stances; the keep keeps its keys with the helper out.
	var roster := HelperRoster.for_team(PLAYER)
	var stub := roster.call_type() if roster else null
	if stub == null:
		_fail("no helper call stub")
	else:
		stub.train_time = 0.1
		sel.select_building(keep)
		_press(KEY_V)   # the call's key on the keep card
		for i in 40:
			await physics_frame
		stub.train_time = 60.0
		var h: Unit = roster.helper
		if h == null or not is_instance_valid(h):
			_fail("V at the Citadel keep did not call the helper (state %s)" % roster.state())
		else:
			await _card("helper stances", func() -> void:
				sel.inspect_unit(h)
				(h as Helper).set_stance(&"home" if (h as Helper).stance == &"escort" else &"escort"))
			var alive := await _card("keep with the helper out", select_keep)
			if _key_of(alive, t3_id) != _key_of(tier1, t3_id):
				_fail("the tier-3 unit moved to %s once the helper is out" % _key_of(alive, t3_id))
	# Delete on the site (last: it cancels it).
	sel.select_building(site)
	_press(KEY_DELETE)
	await _frames(2)
	if is_instance_valid(site) and not bool(site.get(&"cancelled")):
		_fail("Delete (the site's key) did not cancel the site")
	await _check_tavern(hall)
	await _check_trade(hall)
	_check_card_keys()
	main.queue_free()
	main = null
	await _frames(4)


func _spawn(grid: BuildGrid, type: BuildingType, keep: Node3D, fwd: float, side: float) -> Building:
	if type == null:
		return null
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + dir * fwd + Vector3(dir.z, 0, -dir.x) * side, PLAYER)
	return grid.spawn_complete(type, spot, PLAYER) if spot != Vector3.INF else null


# ---------------------------------------------------------------- one card

## Shows the card `setup` selects, checks it, presses every key, and returns its rows.
func _card(case_name: String, setup: Callable) -> Array:
	setup.call()
	card.refresh()
	await _frames(1)
	card.refresh()
	var rows := _rows()
	var where := "%s card" % case_name
	for d: Dictionary in UILabChecks.find_duplicate_badges(card.key_labels):
		_fail("%s: letter %s on two buttons (%s)" % [where, d["value"], d["detail"]])
	for row: Dictionary in rows:
		_checked += 1
		_check_row(where, row)
	_check_azerty(where, rows)
	for row: Dictionary in rows:
		if row["key"] == "" or row["key"] == "Del":
			continue
		setup.call()
		card.refresh()
		await _frames(1)
		await _press_and_check(where, row, setup)
	setup.call()
	card.refresh()
	for row: Dictionary in rows:
		var id: String = row["id"]
		if id.begins_with("train_") and row["key"] != "":
			var uid := id.trim_prefix("train_")
			if not _unit_keys.has(uid):
				_unit_keys[uid] = {}
			(_unit_keys[uid] as Dictionary)[row["key"]] = true
	print("  %-24s %s" % [case_name, " ".join(PackedStringArray(rows.map(func(x: Dictionary) -> String:
			return "%s=%s" % [String(x["id"]).trim_prefix("train_"), x["key"] if x["key"] != "" else "-"])))])
	return rows


func _rows() -> Array:
	var out := []
	for i in card.buttons.size():
		var b := card.buttons[i]
		if not b.visible:
			continue
		var s: Dictionary = card.slots[i]
		var badge := card.key_labels[i]
		out.append({"i": i, "id": str(s.get("id", "")), "key": badge.text if badge.visible else "",
				"tip": b.tooltip_text, "reason": str(s.get("reason", "")), "badge": badge, "button": b})
	return out


## Needs a key: it trains, builds, upgrades, casts, sets a stance, or opens / closes a page.
static func _needs_key(id: String) -> bool:
	return id.begins_with("train_") or id.begins_with("build_") or id.begins_with("plus_") \
			or id.begins_with("stance_") or id.begins_with("caster_") or SPELL_IDS.has(id) or id in ["move", "stop", "hold", "attack", "gather", \
			"trade", "build", "back", "cancel", "raise", "remove", "wares"]


func _check_row(where: String, row: Dictionary) -> void:
	var id: String = row["id"]
	var key: String = row["key"]
	var line1: String = (row["tip"] as String).get_slice("\n", 0)
	if _needs_key(id) and key == "":
		_fail("%s: '%s' (%s) shows no key" % [where, id, line1])
		return
	if key == "":
		return
	var hint := "[Delete]" if key == "Del" else "[%s]" % key
	if not line1.contains(hint):
		_fail("%s: '%s' shows %s but its tooltip starts '%s'" % [where, id, key, line1])
	# ui-hud.md 1.U2: the letter bottom-right, font 12 (Esc / Del: 10), in KEY_COLOR (black on the gold active badge).
	var badge: Label = row["badge"]
	var b: Button = row["button"]
	var br := b.get_global_rect()
	var kr := badge.get_global_rect()
	if not br.grow(0.5).encloses(kr) or br.end.distance_to(kr.end) > 4.0:
		_fail("%s: '%s' key badge %s is not in the bottom-right of its button %s" % [where, id, kr, br])
	var fs := badge.get_theme_font_size("font_size")
	if fs != (12 if key.length() <= 1 else 10):
		_fail("%s: '%s' key font %d" % [where, id, fs])
	var col := badge.get_theme_color("font_color")
	if not col.is_equal_approx(CommandCard.KEY_COLOR) and not col.is_equal_approx(Color.BLACK):
		_fail("%s: '%s' key colour %s" % [where, id, col])


## AZERTY labels: each badge shows the character printed on the physical key it stands for.
func _check_azerty(where: String, rows: Array) -> void:
	KeyLabels.overrides = AZERTY.duplicate()
	card.refresh()
	for row: Dictionary in rows:
		var qw: String = row["key"]
		if qw == "":
			continue
		var want: String = AZERTY_TEXT.get(qw, qw)
		var shown := card.key_labels[row["i"]].text
		if shown != want:
			_fail("%s AZERTY: '%s' shows '%s', the key there prints '%s'" % [where, row["id"], shown, want])
		elif want != "Del" and not card.buttons[row["i"]].tooltip_text.get_slice("\n", 0).contains("[%s]" % want):
			_fail("%s AZERTY: '%s' tooltip '%s' lacks [%s]" % [where, row["id"],
					card.buttons[row["i"]].tooltip_text.get_slice("\n", 0), want])
	KeyLabels.overrides = {}
	card.refresh()


func _code_of(letter: String) -> Key:
	if NAMED_KEYS.has(letter):
		return NAMED_KEYS[letter]
	return letter.to_upper().unicode_at(0) as Key


func _press(code: Key, shift := false) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.shift_pressed = shift
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


## Presses the row's key and checks it did the button's action (then undoes it).
func _press_and_check(where: String, row: Dictionary, setup: Callable) -> void:
	var id: String = row["id"]
	var reason: String = row["reason"]
	var b: Node = sel.selected_building
	var q0: int = (b.get(&"queue") as Array).size() if b != null and b.get(&"queue") is Array else -1
	var up0 := b is Keep and (b as Keep).is_upgrading()
	var bank := UnitUpgrades.for_team(PLAYER)
	var ranks := Stables16.for_team(PLAYER)
	var trade := hud.trade_window
	_msgs.clear()
	_press(_code_of(row["key"]))
	await _frames(2)
	_pressed += 1
	var got := ""
	if id.begins_with("train_"):
		var tid := id.trim_prefix("train_")
		var q := (b.get(&"queue") as Array) if b != null and is_instance_valid(b) and b.get(&"queue") is Array else []
		if q.size() > q0:
			got = "queued " + str(q.back().get(&"id"))
			b.call(&"cancel", q.size() - 1)
		elif b is Keep and (b as Keep).is_upgrading() != up0:
			got = "upgrade"
			if up0:
				(b as Keep).upgrade()
			else:
				(b as Keep).cancel_upgrade()
		elif tid.begins_with(Stables16.STUB_PREFIX) and ranks.is_working(StringName(tid.trim_prefix(Stables16.STUB_PREFIX))):
			got = "rank " + tid.trim_prefix(Stables16.STUB_PREFIX)
			ranks.cancel(StringName(tid.trim_prefix(Stables16.STUB_PREFIX)))
		var ok := got == "queued " + tid or (got == "upgrade" and tid == String(Keep.TIER_STUB_ID)) \
				or got == "rank " + tid.trim_prefix(Stables16.STUB_PREFIX) or (got == "" and reason != "" and _msgs.has(reason))
		if not ok:
			_fail("%s: key %s on '%s' did %s (msgs %s, reason '%s')" % [where, row["key"], id, got if got != "" else "nothing",
					str(_msgs), reason])
	elif id.begins_with("build_"):
		var bid := id.trim_prefix("build_")
		var placing := sel.placing_type.id if sel.placing_type != null else &""
		if String(placing) != bid and not (reason != "" and _msgs.has(reason)):
			_fail("%s: key %s on '%s' placed '%s' (msgs %s)" % [where, row["key"], id, placing, str(_msgs)])
		sel.cancel_targeting()
	elif id.begins_with("plus_") and id != "plus_back" and id != "plus_page":
		var uid := StringName(id.trim_prefix("plus_"))
		if bank.is_working(uid):
			bank.cancel(uid)
		elif not (reason != "" and (reason == "Researched" or _msgs.has(reason))):
			_fail("%s: key %s on '%s' did not start that research (msgs %s)" % [where, row["key"], id, str(_msgs)])
	elif id == "plus_page":
		if not sel.upgrades_open():
			_fail("%s: + did not open the upgrades page" % where)
		_press(KEY_EQUAL)
		await _frames(1)
		if sel.upgrades_open():
			_fail("%s: + again did not close the upgrades page" % where)
	elif id == "plus_back":
		if sel.upgrades_open():
			_fail("%s: Esc did not close the upgrades page" % where)
	elif id.begins_with("stance_"):
		var h := sel.inspected as Helper
		if h == null or String(h.stance) != id.trim_prefix("stance_"):
			_fail("%s: key %s did not set the %s stance (%s)" % [where, row["key"], id, h.stance if h else &"-"])
		if h:
			h.set_stance(&"home" if h.stance == &"escort" else &"escort")   # the next stance key must change it
	elif SPELL_IDS.has(id):
		if sel.get_pending_order() != StringName(id) and _msgs.is_empty():
			_fail("%s: key %s did not start %s (pending %s)" % [where, row["key"], id, sel.get_pending_order()])
	elif id.begins_with("caster_"):
		var sid := StringName(id.trim_prefix("caster_"))
		if sel.pending_caster_spell() != sid and not (reason != "" and _msgs.has(reason)):
			_fail("%s: key %s did not start aiming %s (pending %s, msgs %s)" % [where, row["key"], sid,
					sel.pending_caster_spell(), str(_msgs)])
	else:
		var ok := true
		match id:
			"move":
				ok = sel.get_pending_order() == SelectionManager.ORDER_MOVE
			"attack":
				ok = sel.get_pending_order() == SelectionManager.ORDER_ATTACK_MOVE
			"gather", "trade":
				ok = sel.get_pending_order() == SelectionManager.ORDER_GATHER
			"build":
				ok = sel.build_menu_open
			"back":
				ok = not sel.build_menu_open
			"wares":
				ok = trade != null and trade.is_open()
				if trade:
					trade.close()
		if not ok:
			_fail("%s: key %s on '%s' did not do its action" % [where, row["key"], id])
	sel.cancel_targeting()
	paused = false


func _check_upgrades_page_keys(hall: Node3D) -> void:
	sel.select_building(hall)
	card.refresh()
	_press(KEY_EQUAL)
	await _frames(1)
	if not sel.upgrades_open():
		_fail("+ on the Hall did not open its upgrades page")
	_press(KEY_ESCAPE)
	await _frames(1)
	if sel.upgrades_open() or paused:
		_fail("Esc did not close the upgrades page (or opened the pause menu)")
		paused = false
	# While the page is open, a unit key never trains.
	sel.open_upgrades()
	var q0 := (hall.get(&"queue") as Array).size()
	_press(KEY_Z)
	await _frames(1)
	if (hall.get(&"queue") as Array).size() != q0:
		_fail("Z on the upgrades page trained a unit")
	var bank := UnitUpgrades.for_team(PLAYER)
	for id in UnitUpgrades.UNITS:
		if bank.is_working(id):
			bank.cancel(id)
	sel.close_upgrades()


## The build menu keeps each key on one place in every kingdom (BUILD_KEY_SLOTS).
func _check_build_menu_places(rows: Array) -> void:
	for row: Dictionary in rows:
		var id: String = row["id"]
		if not id.begins_with("build_"):
			continue
		var t := BuildingType.find(id.trim_prefix("build_"))
		var want: int = CommandCard.BUILD_KEY_SLOTS.get(t.hotkey_label.to_upper(), -1) if t else -1
		if want >= 0 and row["i"] != want:
			_fail("build menu: %s (key %s) at slot %d, expected %d" % [id, t.hotkey_label, row["i"], want])


## The tavern window: each row's Hire shows its key and the key hires that champion (never trains at the selected Hall).
func _check_tavern(hall: Node3D) -> void:
	var w: TavernWindow = hud.tavern_window
	if w == null:
		_fail("no tavern window")
		return
	sel.select_building(hall)
	w.open()
	w.refresh()
	await _frames(2)
	var g := w.guild()
	for i in w.rows.size():
		var row: TavernWindow.Row = w.rows[i]
		if not row.hire_button.visible:
			continue
		var want := TavernWindow.row_key_label(i)
		if row.hire_key.text != want or not row.hire_key.is_visible_in_tree() \
				or not row.hire_button.tooltip_text.begins_with("Hire  [%s]" % want):
			_fail("tavern row %s: Hire badge '%s', tooltip '%s' (want %s)" % [row.id, row.hire_key.text,
					row.hire_button.tooltip_text.get_slice("\n", 0), want])
	if w.genie_button.visible and (w.genie_key.text != KeyLabels.of(TavernWindow.GENIE_KEY)
			or not w.genie_button.tooltip_text.contains("[%s]" % w.genie_key.text)):
		_fail("tavern Genie badge '%s' / tooltip '%s'" % [w.genie_key.text, w.genie_button.tooltip_text.get_slice("\n", 0)])
	var q0 := (hall.get(&"queue") as Array).size()
	var hired0: int = int(g.call(&"roster_size")) if g else 0
	_press(KEY_Z)
	await _frames(2)
	_pressed += 1
	if (hall.get(&"queue") as Array).size() != q0:
		_fail("Z in the open tavern trained at the selected Hall")
	if g == null or int(g.call(&"roster_size")) != hired0 + 1 or not g.call(&"is_hiring", w.row_ids[0]):
		_fail("Z in the open tavern did not hire row 1 (%s)" % [w.row_ids[0]])
	# Gold (trade on): row 2's gold button names Shift + its key, and Shift+X hires with gold.
	var bank: Node = w.gold_bank()
	if bank != null:
		w.refresh()
		var r2: TavernWindow.Row = w.rows[1]
		var gold_tip := "Hire with gold  [Shift+%s]" % TavernWindow.row_key_label(1)
		if r2.hire_gold_button.visible and not r2.hire_gold_button.tooltip_text.begins_with(gold_tip):
			_fail("tavern gold tooltip '%s' (want '%s')" % [r2.hire_gold_button.tooltip_text.get_slice("\n", 0), gold_tip])
		var gold0 := int(bank.get(&"gold"))
		_press(KEY_X, true)
		await _frames(2)
		_pressed += 1
		if not g.call(&"is_hiring", w.row_ids[1]) or int(bank.get(&"gold")) >= gold0:
			_fail("Shift+X in the open tavern did not hire row 2 with gold (gold %d -> %d)" % [gold0, int(bank.get(&"gold"))])
	w.close()
	_press(KEY_X)   # the window closed: X is the Hall's again
	await _frames(2)
	if (hall.get(&"queue") as Array).size() != q0 + 1:
		_fail("X after closing the tavern did not train at the Hall")
	else:
		hall.call(&"cancel", (hall.get(&"queue") as Array).size() - 1)


## The trade window (U): the wares' Buy (Z X C V), the exchange (B / N, Shift x5) and the Lodge contracts (Z X) show
## their keys; the keys act on the shown tab and never train at the selected Hall meanwhile.
func _check_trade(hall: Node3D) -> void:
	var t: TradeWindow = hud.trade_window
	if t == null:
		_fail("no trade window")
		return
	sel.select_building(hall)
	if not t.open(&"bazaar"):
		_fail("the trade window did not open (trade on)")
		return
	t.refresh()
	await _frames(2)
	for i in t.ware_rows.size():
		var r: TradeWindow.WareRow = t.ware_rows[i]
		var want := TradeWindow.row_key_label(i)
		if r.buy_button.visible and (r.buy_key.text != want or not r.buy_button.tooltip_text.get_slice("\n", 0).ends_with("[%s]" % want)):
			_fail("trade ware %d: badge '%s', tooltip '%s' (want %s)" % [i, r.buy_key.text,
					r.buy_button.tooltip_text.get_slice("\n", 0), want])
	for i in t.exchange_buttons.size():
		var want := KeyLabels.of(TradeWindow.EXCHANGE_KEYS[i])
		var badge := t.exchange_buttons[i].get_meta(&"key_badge") as Label
		if badge == null or badge.text != want or not t.exchange_buttons[i].tooltip_text.begins_with("Exchange  [%s]" % want):
			_fail("trade exchange %d: badge '%s', tooltip '%s'" % [i, badge.text if badge else "-",
					t.exchange_buttons[i].tooltip_text.get_slice("\n", 0)])
	var bank := t.gold_bank()
	var q0 := (hall.get(&"queue") as Array).size()
	var gold0 := int(bank.get(&"gold"))
	_press(KEY_Z)   # ware 1
	await _frames(2)
	_pressed += 1
	if (hall.get(&"queue") as Array).size() != q0:
		_fail("Z in the open trade window trained at the selected Hall")
	if not t.owns_ware(TradeWindow.WARE_IDS[0]):
		_fail("Z in the trade window did not buy %s (%s)" % [TradeWindow.WARE_IDS[0], t.last_result])
	var gold1 := int(bank.get(&"gold"))
	_press(KEY_B, true)   # exchange x5 to crystals
	await _frames(2)
	_pressed += 1
	if int(bank.get(&"gold")) != gold1 - 5 * TradeWindow.EXCHANGE_STEP:
		_fail("Shift+B in the trade window did not exchange 500 gold (%d -> %d, %s)" % [gold1, int(bank.get(&"gold")),
				t.last_result])
	# The Lodge tab: Z X = its contracts (closed before 5:00: the key answers the Lodge's refusal).
	t.open(&"lodge")
	t.refresh()
	await _frames(2)
	for i in t.contract_rows.size():
		var r: TradeWindow.ContractRow = t.contract_rows[i]
		var want := TradeWindow.row_key_label(i)
		if r.hire_button.visible and (r.hire_key.text != want or not r.hire_button.tooltip_text.get_slice("\n", 0).ends_with("[%s]" % want)):
			_fail("trade contract %d: badge '%s', tooltip '%s'" % [i, r.hire_key.text,
					r.hire_button.tooltip_text.get_slice("\n", 0)])
	var guild := t.hunters_guild()
	if guild != null and guild.has_method(&"can_hire"):
		var expect := str(guild.call(&"can_hire", PLAYER, TradeWindow.CONTRACT_KINDS[1]))
		t.last_result = "?"
		_press(KEY_X)
		await _frames(2)
		_pressed += 1
		if t.last_result != expect:
			_fail("X on the Lodge tab answered '%s', its contract says '%s'" % [t.last_result, expect])
	t.close()
	_press(KEY_Z)   # the window closed: Z is the Hall's again
	await _frames(2)
	if (hall.get(&"queue") as Array).size() != q0 + 1:
		_fail("Z after closing the trade window did not train at the Hall")
	else:
		hall.call(&"cancel", (hall.get(&"queue") as Array).size() - 1)


## Every trained unit's card_key is the letter of its button on a card that trains it.
func _check_card_keys() -> void:
	for uid: String in _unit_keys:
		var t := UnitType.find(uid)
		if t == null:
			continue   # stubs (tier button, helper call, rank-ups)
		var shown: Dictionary = _unit_keys[uid]
		if t.card_key == "" or not shown.has(t.card_key.to_upper()):
			_fail("%s: card_key '%s' but its button shows %s" % [uid, t.card_key, str(shown.keys())])


# ---------------------------------------------------------------- helpers

func _key_of(rows: Array, id: String) -> String:
	for row: Dictionary in rows:
		if row["id"] == id:
			return row["key"]
	return ""


func _slot_of(rows: Array, id: String) -> int:
	for row: Dictionary in rows:
		if row["id"] == id:
			return row["i"]
	return -1


func _ids(rows: Array) -> Array:
	return rows.map(func(x: Dictionary) -> String: return x["id"])


func _expect_ids(rows: Array, want: Array, where: String) -> void:
	if _ids(rows) != want:
		_fail("%s shows %s, expected %s" % [where, str(_ids(rows)), str(want)])
