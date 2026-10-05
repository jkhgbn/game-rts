extends SceneTree
## Unit Guide (docs/design/unit-guide.md): data coverage, honest numbers and the screen.
## Run: godot --headless --path . -s tests/test_unit_guide.gd --fixed-fps 60 --quit-after 3000
## Checks: every player-facing unit / champion / helper has a data/ui/unit_guide.json block and no JSON id is stale;
## lint (3 pros, 2-3 cons, length limits, tags, roles) and every rank claim ("Highest HP in the Fire army") holds;
## the stats the guide shows equal the resources; the screen opens headless, the filters / search / compare work;
## the main menu and the pause menu open and close it.

const TASK_ID := "unit_guide"
const PLAYER_KINGDOMS: Array[StringName] = [&"fire", &"ice", &"nature", &"shadow"]

var frame := 0
var fails: Array[String] = []
var guide: UnitGuide
var menu: Node
var pause: Node


func _initialize() -> void:
	UnitGuideData.reset()
	_check_data()
	guide = UnitGuide.new()
	root.add_child(guide)


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		3:
			_check_screen()
			guide.queue_free()
			menu = (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
			root.add_child(menu)
		8:
			_check_main_menu()
		12:
			_check_main_menu_back()
			pause = PauseMenu.new()
			root.add_child(pause)
		16:
			_check_pause()
		20:
			_check_pause_back()
			for f in fails:
				print("  " + f)
			if fails.is_empty():
				print("PASS %s (%d units)" % [TASK_ID, UnitGuideData.entries().size()])
			else:
				print("FAIL %s: %d problems (first: %s)" % [TASK_ID, fails.size(), fails[0]])
			return true
	return frame > 400


func _fail(msg: String) -> void:
	fails.append(msg)


# ---------------------------------------------------------------- data

func _check_data() -> void:
	var ids := UnitGuideData.ids()
	if ids.size() < 60:
		_fail("only %d guide entries" % ids.size())
	# 1. every trainable kingdom unit with a model is in the roster (a new .tres must reach the guide)
	for f in DirAccess.get_files_at("res://data/units/"):
		if not f.ends_with(".tres"):
			continue
		var u := load("res://data/units/" + f) as UnitType
		if u == null or u.model_scene == null:
			continue
		if PLAYER_KINGDOMS.has(u.faction) and u.cost > 0 and u.commandable and not ids.has(u.id):
			_fail("player unit %s has no guide entry" % u.id)
	for cid in ChampionType.IDS:
		if not ids.has(cid):
			_fail("champion %s missing" % cid)
	for hid in HelperType.IDS:
		if not ids.has(hid):
			_fail("helper %s missing" % hid)
	for extra: StringName in [&"caravan", T3Kit.GENIE_ID, &"greywater_tracker"]:
		if not ids.has(extra):
			_fail("%s missing" % extra)
	# 2. JSON <-> roster
	var units: Dictionary = UnitGuideData.json().get("units", {})
	if units.is_empty():
		_fail("data/ui/unit_guide.json missing or unreadable")
	for key: String in units:
		if not ids.has(StringName(key)):
			_fail("stale JSON id %s" % key)
	# 3. lint + claims
	for id in ids:
		for p in UnitGuideData.lint(id):
			_fail("%s: %s" % [id, p])
		for p in UnitGuideData.check_claims(id):
			_fail("%s: false claim %s" % [id, p])
	# the claim checker itself catches a false claim
	var probe := UnitGuideData.entry(&"flame_guard")
	if not probe.is_empty():
		var saved: Array = probe["pros"]
		probe["pros"] = ["Highest HP in any army"]
		if UnitGuideData.check_claims(&"flame_guard").is_empty():
			_fail("check_claims missed a false claim")
		probe["pros"] = saved
	# 4. stats = data
	for e in UnitGuideData.entries():
		var s: Dictionary = e["stats"]
		var want := {}
		match String(e["kind"]):
			"champion":
				var c := ChampionType.find(e["id"])
				want = {"hp": c.max_hp, "damage": c.attack_damage, "range": c.attack_range, "speed": c.move_speed,
					"armor": c.armor, "sight": c.sight_radius, "cooldown": c.attack_cooldown}
			"helper":
				var h := HelperType.find(e["id"])
				want = {"hp": h.hp_base, "damage": h.damage_base, "range": h.attack_range, "speed": h.move_speed,
					"armor": h.armor, "sight": h.sight, "crystals": h.call_crystals, "pop": h.pop}
			_:
				var u := UnitType.find(String(e["id"]))
				want = {"hp": u.max_hp, "damage": u.attack_damage, "range": u.attack_range, "speed": u.move_speed,
					"armor": u.armor, "cooldown": u.attack_cooldown, "crystals": u.cost, "pop": u.pop,
					"train_time": u.train_time, "tier": u.requires_tier}
		for k: String in want:
			if not is_equal_approx(float(s[k]), float(want[k])):
				_fail("%s %s shown %s, data %s" % [e["id"], k, s[k], want[k]])
		if absf(float(s["dps"]) - float(s["damage"]) / maxf(0.05, float(s["cooldown"]))) > 0.001:
			_fail("%s dps not damage / cooldown" % e["id"])


# ---------------------------------------------------------------- screen

func _check_screen() -> void:
	var all := UnitGuideData.entries().size()
	if guide.visible_ids().size() != all:
		_fail("list shows %d of %d with no filter" % [guide.visible_ids().size(), all])
	guide.set_kingdom_filter(&"fire")
	var n_fire := guide.visible_ids().size()
	if n_fire < 10:
		_fail("fire filter shows %d" % n_fire)
	for id in guide.visible_ids():
		if UnitGuideData.entry(id)["kingdom"] != &"fire":
			_fail("fire filter lets %s through" % id)
	if not guide.visible_ids().has(guide.selected_id()):
		_fail("selection not moved into the filtered list")
	guide.set_tier_filter(3)
	for id in guide.visible_ids():
		if int(UnitGuideData.entry(id)["tier"]) != 3 or UnitGuideData.entry(id)["kingdom"] != &"fire":
			_fail("fire + tier 3 filter lets %s through" % id)
	if guide.visible_ids().is_empty():
		_fail("no fire tier-3 unit")
	guide.set_kingdom_filter(&"")
	guide.set_tier_filter(0)
	guide.set_role_filter("cavalry")
	if guide.visible_ids().size() < 16:
		_fail("cavalry filter shows %d (want the 16 Stables units)" % guide.visible_ids().size())
	for id in guide.visible_ids():
		if UnitGuideData.entry(id)["role"] != "cavalry":
			_fail("cavalry filter lets %s through" % id)
	guide.set_role_filter("")
	guide.set_search("frost")
	if not guide.visible_ids().has(&"frostbow") or guide.visible_ids().has(&"flame_guard"):
		_fail("search 'frost' wrong: %s" % [guide.visible_ids()])
	guide.set_search("zzzz")
	if not guide.visible_ids().is_empty() or not guide.empty_label.visible:
		_fail("search with no match should show the empty line")
	guide.set_search("")
	# single view: the labels show the data
	guide.select_unit(&"frostcrown_juggernaut")
	var jug := UnitType.find("frostcrown_juggernaut")
	_expect_label("frostcrown_juggernaut:hp", str(int(jug.max_hp)))
	_expect_label("frostcrown_juggernaut:armor", str(int(jug.armor)))
	_expect_label("frostcrown_juggernaut:crystals", str(jug.cost))
	_expect_label("frostcrown_juggernaut:dps", "%.1f" % (jug.attack_damage / jug.attack_cooldown))
	# compare
	guide.set_compare_pair(&"blaze_rider", &"stagrunner")
	var pair := guide.compare_ids()
	if pair.size() != 2 or pair[0] != &"blaze_rider" or pair[1] != &"stagrunner":
		_fail("compare ids %s" % [guide.compare_ids()])
	_expect_label("blaze_rider:speed", UnitGuide.stat_text(UnitGuideData.entry(&"blaze_rider"), "speed"))
	_expect_label("stagrunner:hp", str(int(UnitType.find("stagrunner").max_hp)))
	var faster: Label = guide.stat_labels.get("stagrunner:speed")
	if faster == null or not faster.get_theme_color(&"font_color").is_equal_approx(UnitGuide.BETTER):
		_fail("the faster unit's speed is not marked better")
	guide.select_unit(&"shade")
	if guide.compare_ids()[1] != &"shade":
		_fail("list click in compare mode should set unit B")
	guide.swap_compare()
	if guide.compare_ids()[0] != &"shade":
		_fail("swap did not swap")
	guide.set_compare(false)
	if guide.is_comparing():
		_fail("compare did not turn off")
	# every entry renders without error
	for id in UnitGuideData.ids():
		guide.select_unit(id)
		if not guide.stat_labels.has("%s:hp" % id):
			_fail("%s detail has no HP label" % id)


func _expect_label(key: String, want: String) -> void:
	var l: Label = guide.stat_labels.get(key)
	if l == null:
		_fail("no label %s" % key)
	elif l.text != want:
		_fail("%s shows '%s', want '%s'" % [key, l.text, want])


func _check_main_menu() -> void:
	if menu.get(&"unit_guide_button") == null:
		_fail("main menu has no Unit Guide button")
		return
	(menu.get(&"unit_guide_button") as Button).pressed.emit()
	if not bool(menu.call(&"is_unit_guide_open")):
		_fail("main menu: the guide did not open")
	if (menu.get(&"menu_column") as Control).visible:
		_fail("main menu: the title column stays visible behind the guide")


func _check_main_menu_back() -> void:
	var g: UnitGuide = menu.get(&"unit_guide")
	if g == null:
		return
	g.close()
	if bool(menu.call(&"is_unit_guide_open")) or not (menu.get(&"main_panel") as Control).visible:
		_fail("main menu: Back did not return to the main panel")


func _check_pause() -> void:
	pause.call(&"open")
	pause.call(&"show_unit_guide")
	var g: UnitGuide = pause.get(&"unit_guide")
	if g == null or not g.is_visible_in_tree():
		_fail("pause menu: the guide did not open")
	if (pause.get(&"panel") as Control).visible:
		_fail("pause menu: its panel stays visible behind the guide")


func _check_pause_back() -> void:
	var g: UnitGuide = pause.get(&"unit_guide")
	if g:
		g.close()
	if not (pause.get(&"panel") as Control).visible:
		_fail("pause menu: Back did not return to the pause panel")
	pause.call(&"close")
	paused = false
