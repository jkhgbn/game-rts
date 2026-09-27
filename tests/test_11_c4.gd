extends SceneTree
## Task 11.C4 (ui-champions.md 15 "Done when (11.C4)", skills-rework.md 7): the champion class UI. Runs on the
## mission 1 map with stub champions (a `class_id()` method, a `class_chosen` signal, `bounty_leans`), stub abilities
## (`ability_ids` / `is_unlocked` / `cooldown_left` only) and a stub guild without hire_cost / revive_cost (the
## fallback prices), so it needs none of the step-11 gameplay scripts. Checks, at 1600 x 900:
## - tavern: column B has 4 lines at y 6 / 26 / 46 / 66 with the L4 badge at (372, 47) and the L2 badge at (372, 67);
##   an unhired Oathwall reads `Class · usually Sword and Shield`, hired with 2 Guard bounties below level 2
##   `Class · leans Sword and Shield (71 %)`, at level 2 `Sword and Shield · skills 1 / 3` (class glyph); the lean /
##   class tooltips; a hired row's stats read the champion; prices 225 / 75 (fallback), `Revive 150` at level 2; the
##   hired tile badge at (6, 70); the row flashes gold when its champion chooses a class while the window is open;
##   the Wayfinder's first ability reads `Signal Flare`;
## - bar: the 16 x 16 badge at (6, 50) only with a class; PNG or code glyph; the 4-line class tooltip; tooltip line 1
##   gains ` · Sword and Shield` (5 lines unchanged before); the pop on class_chosen, none for a class loaded with the
##   champion; 225+75 / 275+100 / 325+125 and 80 + 35 x level fallbacks; the message once per champion (own always,
##   enemy only while visible);
## - inspect: 6 slots in 2 rows at (1104 + 54 j, 684 / 766), names y 734 / 816, captions (1104, 670 / 752), autocast
##   (1104, 834); the 392-wide title `GARRAN STONEWARD · the Oathwall · no class yet` / `... · Sword and Shield`; `?`
##   slots (alpha 0.45, L2 / L3 / L5, `Skill 1-3`, live lean tooltip 71 %, enemy base 60 % without the bounty line);
##   after the choice the class skills with L3 / L5 and `(class, level n)`; the ability list; the autocast line; the
##   class stat line (`Armor 30`, `Range 2.4`);
## - fallback tables (class_scripts_enabled = false) give the same texts; no `_private` calls in the 11.C4 files.
## Run:  godot --headless --path . -s tests/test_11_c4.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "11.c4"
const TIMEOUT_FRAMES := 2400
const WARM_UP := 30

const ARCHETYPE_IDS := {
	&"wayfinder": [&"flare_arrow", &"snare_line", &"trailblaze"],
	&"oathwall": [&"oath_of_iron", &"shield_bash", &"bulwark_stand"],
	&"coin_cutter": [&"cutpurse", &"smoke_pouch", &"marked_for_coin"],
	&"mender": [&"mending_draught", &"soothing_circle", &"lifeline"],
}
const CLASS_IDS := {
	&"spear": [&"lunge", &"hobbling_javelin", &"skewer"],
	&"sword_shield": [&"riposte", &"second_wind", &"shield_throw"],
	&"two_hand": [&"cleave", &"crushing_blow", &"whirlwind"],
	&"wizard": [&"arc_bolt", &"slipstep", &"starfall"],
}
const UNLOCKS := {&"flare_arrow": 1, &"snare_line": 1, &"trailblaze": 4, &"oath_of_iron": 1, &"shield_bash": 1,
	&"bulwark_stand": 4, &"cutpurse": 1, &"smoke_pouch": 1, &"marked_for_coin": 4, &"mending_draught": 1,
	&"soothing_circle": 1, &"lifeline": 4}


## Stands in for Champion: the fields the UI reads, `class_id()`, `bounty_leans` and `class_chosen`.
class StubChampion extends Unit:
	signal class_chosen(champion: Node, class_id: StringName)
	var champion_id: StringName = &"oathwall"
	var variant := 0
	var display_name := "Garran Stoneward"
	var purse := 50
	var intent: StringName = &"Guarding"
	var intent_target: Node3D = null
	var inventory: Node = null
	var abilities: Node = null
	var is_unpaid := false
	var fallen := false
	var cls: StringName = &""
	var bounty_leans: Dictionary = {}
	var orders := 0

	func _ready() -> void:
		super._ready()
		add_to_group(&"champions")

	func type_id() -> StringName:
		return champion_id

	func class_id() -> StringName:
		return cls

	## The level-2 draw as Champion does it: the class, then class_chosen.
	func choose(id: StringName) -> void:
		cls = id
		class_chosen.emit(self, id)

	func is_commandable() -> bool:
		return false

	func is_alive() -> bool:
		return not fallen and super.is_alive()

	func xp_to_next() -> int:
		return 500

	func take_damage(_amount: float, _attacker: Node3D = null) -> void:
		pass

	func command_move(_p: Vector3) -> void:
		orders += 1

	func command_attack(_t: Unit) -> void:
		orders += 1

	func command_stop() -> void:
		orders += 1


## The 3 methods the UI needs: 3 archetype ids + the class's 3 after the choice, unlocks by level, no cooldowns.
class StubAbilities extends Node:
	var ch: StubChampion

	func ability_ids() -> Array[StringName]:
		var out: Array[StringName] = []
		out.assign(ARCHETYPE_IDS[ch.champion_id])
		if ch.cls != &"":
			out.append_array(CLASS_IDS[ch.cls])
		return out

	func is_unlocked(id: StringName) -> bool:
		if UNLOCKS.has(id):
			return ch.level >= int(UNLOCKS[id])
		if ch.cls == &"" or not (CLASS_IDS[ch.cls] as Array).has(id):
			return false
		return ch.level >= [2, 3, 5][(CLASS_IDS[ch.cls] as Array).find(id)]

	func cooldown_left(_id: StringName) -> float:
		return 0.0


## ChampionGuild stand-in without hire_cost / revive_cost: the UI's fallback prices show.
class StubGuild extends Node:
	var team := 0
	var champions: Array = []

	func _init() -> void:
		add_to_group(&"champion_guilds")

	func is_open() -> bool:
		return true

	func can_hire(_id: StringName) -> String:
		return ""

	func can_revive(ch: Node) -> String:
		return "Not fallen" if ch.is_alive() else ""


var main: Node
var hud: Node
var sel: Node
var hero: Node
var bar: Node
var panel: Node
var tavern: Node
var guild: StubGuild
var a: StubChampion        # Oathwall, level 1, 2 Guard bounties -> Sword and Shield at level 2
var b: StubChampion        # Mender, level 2, Wizard, fallen
var c: StubChampion        # Wayfinder, level 5, Spear
var e: StubChampion        # enemy Oathwall, level 1, visible
var f: StubChampion        # enemy Coin-Cutter, hidden by the fog
var frame := 0
var _wait := 0
var _warm := 0
var _step := 0
var _step_frame := 0
var _errors: Array[String] = []
var _done := false
var _notes: Array[String] = []


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_warm += 1
	if _warm < WARM_UP:
		return false
	frame += 1
	_run()
	if not _errors.is_empty():
		for err in _errors:
			print("  - ", err)
		print("FAIL %s: %d problem(s) (step %d)" % [TASK_ID, _errors.size(), _step])
		return true
	if _done:
		for n in _notes:
			print("note: ", n)
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at step %d" % [TASK_ID, _step])
		return true
	return false


func _next() -> void:
	_step += 1
	_step_frame = frame


func _since() -> int:
	return frame - _step_frame


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


## True when `ctl`'s global rect starts at `pos` (+- 1 px) and, when given, has `size`.
func _at(ctl: Control, pos: Vector2, size := Vector2.ZERO) -> bool:
	var r := ctl.get_global_rect()
	return r.position.distance_to(pos) <= 1.0 and (size == Vector2.ZERO or r.size.distance_to(size) <= 1.0)


func _rect(ctl: Control) -> String:
	return str(ctl.get_global_rect())


func _run() -> void:
	match _step:
		0:
			root.size = Vector2i(1600, 900)
			hud = main.get("hud")
			sel = main.get("selection")
			hero = main.hero
			bar = hud.get("champion_bar") if hud != null else null
			panel = hud.get("selection_panel") if hud != null else null
			tavern = hud.get("tavern_window") if hud != null else null
			if bar == null or panel == null or tavern == null:
				_errors.append("HUD lacks champion_bar / selection_panel / tavern_window")
				return
			(sel.camera.get_parent() as Node3D).set("edge_pan_enabled", false)
			for g in get_nodes_in_group(&"champion_guilds"):
				g.remove_from_group(&"champion_guilds")
			guild = StubGuild.new()
			guild.name = "StubGuild"
			main.add_child(guild)
			_check_prices()
			_next()
		1:
			if _since() < 2:
				return
			tavern.open()   # (the window's container lays the rows out at the end of the frame)
			_next()
		2:
			if _since() < 2:
				return
			_check_tavern_unhired()
			_spawn_own()
			_next()
		3:
			if _since() < 3:
				return
			tavern.refresh()
			_check_tavern_hired()
			tavern.close()
			bar.refresh()
			_check_bar_before()
			sel.select_units([hero])
			panel.inspect(a)
			_next()
		4:
			if _since() < 12:
				return
			panel.refresh()
			_check_inspect_before()
			# The level-2 draw while the tavern is open and the Oathwall is inspected.
			tavern.open()
			a.level = 2
			a.max_hp = 561.0
			a.set_base_stat(&"max_hp", 561.0)
			a.hp = 561.0
			a.set_base_stat(&"attack_damage", 12.96)
			a.set_base_stat(&"armor", 30.0)
			a.set_base_stat(&"move_speed", 4.1)
			a.choose(&"sword_shield")
			a.choose(&"sword_shield")   # a second emit never shows a second message
			tavern.refresh()
			_check_class_chosen()
			_next()
		5:
			if _since() < 2:
				return
			panel.refresh()
			_check_inspect_after()
			tavern.close()
			_check_bar_after()
			_spawn_enemies()
			panel.inspect(c)
			_next()
		6:
			if _since() < 3:
				return
			panel.refresh()
			_check_inspect_spear()
			panel.inspect(e)
			_next()
		7:
			if _since() < 3:
				return
			panel.refresh()
			_check_inspect_enemy()
			_check_enemy_messages()
			_check_fallback_tables()
			_check_real_champion()
			_check_no_private_calls()
			sel.select_units([hero])
			_next()
		8:
			for s: StubChampion in [a, b, c, e, f]:
				_expect(s.orders == 0, "%s received %d orders" % [s.display_name, s.orders])
			_done = true


# ---------------------------------------------------------------- setup

func _stub(id: StringName, n: String, lvl: int, team: int, stats: Dictionary, offset: Vector3) -> StubChampion:
	var s := StubChampion.new()
	s.champion_id = id
	s.display_name = n
	s.unit_name = n
	s.team = team
	s.max_hp = float(stats.get("max_hp", 300.0))
	s.attack_damage = float(stats.get("attack_damage", 15.0))
	s.attack_range = float(stats.get("attack_range", 1.8))
	s.move_speed = float(stats.get("move_speed", 4.3))
	main.add_child(s)
	s.global_position = hero.global_position + offset
	s.level = lvl
	s.hp = s.max_hp
	s.set_base_stat(&"armor", float(stats.get("armor", 0.0)))
	var ab := StubAbilities.new()
	ab.ch = s
	s.abilities = ab
	s.add_child(ab)
	return s


func _spawn_own() -> void:
	a = _stub(&"oathwall", "Garran Stoneward", 1, Unit.Team.PLAYER,
			{"max_hp": 520.0, "attack_damage": 15.0, "attack_range": 1.8, "move_speed": 4.3, "armor": 20.0},
			Vector3(4, 0, 3))
	a.bounty_leans = {&"guard": 2}
	b = _stub(&"mender", "Orla Fenwick", 2, Unit.Team.PLAYER,
			{"max_hp": 272.0, "attack_damage": 11.88, "attack_range": 7.5, "move_speed": 4.8, "armor": 5.0},
			Vector3(-4, 0, 3))
	b.cls = &"wizard"
	b.fallen = true
	c = _stub(&"wayfinder", "Tamsin Farrow", 5, Unit.Team.PLAYER,
			{"max_hp": 343.2, "attack_damage": 17.16, "attack_range": 2.4, "move_speed": 6.0, "armor": 0.0},
			Vector3(0, 0, -5))
	c.cls = &"spear"
	guild.champions = [a, b, c]


# ---------------------------------------------------------------- checks

func _check_prices() -> void:
	var costs: Array = ChampionBar.FALLBACK_COSTS
	_expect(costs == [Vector2i(225, 75), Vector2i(275, 100), Vector2i(325, 125)], "FALLBACK_COSTS %s" % [costs])
	_expect(ChampionBar.hire_cost(guild, &"oathwall") == Vector2i(225, 75),
			"first hire fallback %s" % ChampionBar.hire_cost(guild, &"oathwall"))
	var levels := [[1, 115], [2, 150], [4, 220], [6, 290]]
	for lv: Array in levels:
		var s := StubChampion.new()
		s.level = int(lv[0])
		_expect(ChampionBar.revive_cost(guild, s) == int(lv[1]),
				"revive fallback at L%d = %d, expected %d" % [lv[0], ChampionBar.revive_cost(guild, s), lv[1]])
		s.free()


func _check_tavern_unhired() -> void:
	_expect(tavern.is_open(), "tavern did not open")
	var o: Node = tavern.rows[1]   # oathwall, y 300
	var base := Vector2(430, 300)
	for j in 3:
		var x := 372.0 + (24.0 if j == 2 else 0.0)
		_expect(_at(o.ability_labels[j], base + Vector2(x, 6 + 20 * j)), "oathwall ability line %d at %s" % [j,
				_rect(o.ability_labels[j])])
		# Height 16 asked; a font-12 Label's minimum is 17 px (the 20 px step leaves 3 px between lines).
		_expect(o.ability_labels[j].size.y <= 17.5, "ability line %d height %.1f" % [j, o.ability_labels[j].size.y])
	_expect(_at(o.lock_badge, base + Vector2(372, 47)), "L4 badge at %s" % _rect(o.lock_badge))
	_expect(o.class_l2_badge.visible and _at(o.class_l2_badge, base + Vector2(372, 67)),
			"L2 badge at %s (visible %s)" % [_rect(o.class_l2_badge), o.class_l2_badge.visible])
	_expect(_at(o.class_word, base + Vector2(396, 66)), "class line at %s" % _rect(o.class_word))
	_expect(o.class_line_text() == "Class · usually Sword and Shield", "unhired Oathwall line 4 '%s'" % o.class_line_text())
	_expect(not o.class_glyph.visible and not o.tile_badge.visible, "unhired row shows a class glyph")
	var tip: String = o.class_word.tooltip_text
	_expect(tip.contains("Chooses a class at level 2 · leans Sword and Shield (60 %)")
			and tip.contains("Sword and Shield 60 % · Two-Hand Sword 20 % · Spear 15 % · Wizard 5 %")
			and tip.contains(ChampionBar.BOUNTY_HINT) and tip.begins_with("Class\n"),
			"unhired lean tooltip:\n%s" % tip)
	var usual := {0: "Class · usually Spear", 2: "Class · usually Two-Hand Sword", 3: "Class · usually Wizard"}
	for k: int in usual:
		_expect(tavern.rows[k].class_line_text() == usual[k], "row %d line 4 '%s'" % [k, tavern.rows[k].class_line_text()])
	_expect(o.price_crystals.text == "225" and o.price_essence.text == "75", "first hire price %s / %s" % [
			o.price_crystals.text, o.price_essence.text])
	_expect(o.hire_button.tooltip_text.begins_with("Hire  [Y]\n225 crystals · 75 essence · 2 pop"),
			"hire tooltip '%s'" % o.hire_button.tooltip_text)
	var w: Node = tavern.rows[0]
	_expect(w.ability_labels[0].text.begins_with("Signal Flare · "), "Wayfinder ability 1 '%s'" % w.ability_labels[0].text)
	_expect(w.ability_labels[0].tooltip_text.begins_with("Signal Flare\n")
			and w.ability_labels[0].tooltip_text.contains("Hurls a flare up to 20 m: 20 damage around it"),
			"Signal Flare tooltip '%s'" % w.ability_labels[0].tooltip_text)


func _check_tavern_hired() -> void:
	var o: Node = tavern.rows[1]
	_expect(o.state == &"hired", "oathwall row state %s" % o.state)
	_expect(o.class_line_text() == "Class · leans Sword and Shield (71 %)", "hired L1 line 4 '%s'" % o.class_line_text())
	_expect(o.class_l2_badge.visible and not o.class_glyph.visible and not o.tile_badge.visible,
			"hired L1: L2 badge %s glyph %s tile %s" % [o.class_l2_badge.visible, o.class_glyph.visible, o.tile_badge.visible])
	_expect(o.class_word.tooltip_text.contains("leans Sword and Shield (71 %)")
			and o.class_word.tooltip_text.contains("Sword and Shield 71 % · Two-Hand Sword 14 % · Spear 11 % · Wizard 4 %"),
			"live lean tooltip:\n%s" % o.class_word.tooltip_text)
	_expect(o.stats_label.text == "520 HP · 15 damage · 1.8 range · 4.3 speed · 20 armor", "hired stats '%s'" % o.stats_label.text)
	var m: Node = tavern.rows[3]   # mender, fallen, level 2, wizard
	_expect(m.state == &"fallen" and m.revive_button.text == "Revive 150", "fallen L2 revive '%s' (%s)" % [
			m.revive_button.text, m.state])
	_expect(m.class_line_text() == "Wizard · skills 1 / 3", "fallen wizard line 4 '%s'" % m.class_line_text())
	_expect(m.tile_badge.visible and _at(m.tile_badge, Vector2(430 + 6, 204 + 96 * 3 + 70), Vector2(16, 16)),
			"tile badge %s visible %s" % [_rect(m.tile_badge), m.tile_badge.visible])
	_expect(m.class_glyph.visible and _at(m.class_glyph, Vector2(430 + 372, 204 + 96 * 3 + 66), Vector2(16, 16))
			and not m.class_l2_badge.visible, "fallen class glyph %s" % _rect(m.class_glyph))
	_expect(m.tile_badge.modulate.r < 0.9, "fallen tile badge not dimmed")
	_expect(m.stats_label.text.contains("7.5 range"), "wizard stats '%s'" % m.stats_label.text)
	var w: Node = tavern.rows[0]
	_expect(w.class_line_text() == "Spear · skills 3 / 3", "L5 spear line 4 '%s'" % w.class_line_text())
	_expect(w.class_word.tooltip_text.begins_with("Spear\nmelee · 17.2 damage every 0.95 s · reach 2.4\n+0.2 speed\n"
			+ "Lunge L2 · Hobbling Javelin L3 · Skewer L5"), "spear class tooltip:\n%s" % w.class_word.tooltip_text)
	_expect(w.stats_label.text.contains("2.4 range · 6.0 speed"),
			"spear stats '%s'" % w.stats_label.text)


func _check_bar_before() -> void:
	_expect(bar.visible, "bar hidden with a guild")
	var s0: Node = bar.slots[0]
	_expect(not s0.class_badge.visible, "badge shown before the class")
	var lines: PackedStringArray = s0.tooltip_text.split("\n")
	_expect(lines.size() == 5 and lines[0] == "Garran Stoneward  [F5]  the Oathwall", "tooltip before:\n%s" % s0.tooltip_text)
	var s1: Node = bar.slots[1]
	_expect(s1.class_badge.visible and _at(s1.class_badge, Vector2(16 + 6, 408 + 78 + 50), Vector2(16, 16)),
			"fallen wizard badge %s visible %s" % [_rect(s1.class_badge), s1.class_badge.visible])
	_expect(not s1.is_class_pop_playing() and not s0.is_class_pop_playing(), "a class seen on the first refresh popped")
	_expect(bar.messages_shown.is_empty(), "messages before any draw: %s" % [bar.messages_shown])
	_expect(s1.class_badge.tooltip_text == "Wizard\nranged 7.5 · 11.9 damage every 1.3 s\n-10 % max HP\n"
			+ "Arc Bolt L2 · Slipstep L3 · Starfall L5", "wizard badge tooltip:\n%s" % s1.class_badge.tooltip_text)
	var ln1: String = s1.tooltip_text.split("\n")[0]
	_expect(ln1 == "Orla Fenwick  [F6]  the Mender · Wizard", "fallen tooltip line 1 '%s'" % ln1)


func _check_inspect_before() -> void:
	_expect(panel.current_view() == "champion", "champion view not shown (%s)" % panel.current_view())
	_expect(panel.champion_abilities.size() == 6, "%d ability slots" % panel.champion_abilities.size())
	for j in 3:
		_expect(_at(panel.champion_abilities[j], Vector2(1104 + 54 * j, 684), Vector2(48, 48)),
				"row 1 slot %d at %s" % [j, _rect(panel.champion_abilities[j])])
		_expect(_at(panel.champion_abilities[3 + j], Vector2(1104 + 54 * j, 766), Vector2(48, 48)),
				"row 2 slot %d at %s" % [j, _rect(panel.champion_abilities[3 + j])])
		_expect(_at(panel.champion_ability_names[j], Vector2(1104 + 54 * j, 734)), "row 1 name %d" % j)
		_expect(_at(panel.champion_ability_names[3 + j], Vector2(1104 + 54 * j, 816)), "row 2 name %d" % j)
	_expect(_at(panel.champion_row1_caption, Vector2(1104, 670)) and _at(panel.champion_row2_caption, Vector2(1104, 752)),
			"captions at %s / %s" % [_rect(panel.champion_row1_caption), _rect(panel.champion_row2_caption)])
	_expect(_at(panel.champion_autocast, Vector2(1104, 834)), "autocast at %s" % _rect(panel.champion_autocast))
	var name_row: Control = panel.champion_name.get_parent()
	# 392 wide (the height is the Cinzel 20 line's own, as in step 9).
	_expect(_at(name_row, Vector2(696, 670)) and absf(name_row.size.x - 392.0) <= 1.0, "name row %s" % _rect(name_row))
	_expect(panel.champion_stats.get_global_rect().end.x <= 1089.0, "stat line ends at %.0f" % panel.champion_stats.get_global_rect().end.x)
	var title: String = panel.champion_name.text.to_upper() + panel.champion_title.text + panel.champion_class_label.text
	_expect(title == "GARRAN STONEWARD · the Oathwall · no class yet", "title before '%s'" % title)
	_expect(panel.champion_row1_caption.text == "the Oathwall" and panel.champion_row2_caption.text == "Class at level 2",
			"captions '%s' / '%s'" % [panel.champion_row1_caption.text, panel.champion_row2_caption.text])
	var badges := ["L2", "L3", "L5"]
	for j in 3:
		var slot: Node = panel.champion_abilities[3 + j]
		_expect(slot.visible and slot.placeholder and slot.question.visible and slot.modulate.a < 0.5
				and slot.badge.visible and (slot.badge.get_child(0) as Label).text == badges[j],
				"? slot %d: placeholder %s alpha %.2f badge '%s'" % [j, slot.placeholder, slot.modulate.a,
				(slot.badge.get_child(0) as Label).text])
		_expect(panel.champion_ability_names[3 + j].text == "Skill %d" % (j + 1), "? name %d '%s'" % [j,
				panel.champion_ability_names[3 + j].text])
	var tip: String = panel.champion_abilities[3].tooltip_text
	_expect(tip.begins_with("Class skill 1  Locked\nChooses a class at level 2 · leans Sword and Shield (71 %)\n")
			and tip.contains("Sword and Shield 71 % · Two-Hand Sword 14 % · Spear 11 % · Wizard 4 %")
			and tip.contains(ChampionBar.BOUNTY_HINT) and tip.ends_with("Unlocks at level 2"), "? tooltip:\n%s" % tip)
	_expect(panel.champion_abilities[5].tooltip_text.ends_with("Unlocks at level 5"), "? slot 3 unlock line")
	_expect(panel.champion_ability_list() == "Oath of Iron, Shield Bash, Bulwark Stand",
			"ability list before '%s'" % panel.champion_ability_list())
	_expect(panel.champion_autocast.text == "Autocast · next at level 2", "autocast before '%s'" % panel.champion_autocast.text)
	# The styled tooltip: `Your bounties` in GOLD, `Locked` / `Unlocks at level` in WARN.
	var box: Control = ChampionBar.styled_tooltip(tip)
	var gold := false
	var warn := false
	for l: Label in box.find_children("*", "Label", true, false):
		if l.text.begins_with("Your bounties") and l.get_theme_color("font_color").is_equal_approx(UIStyle.GOLD):
			gold = true
		if l.text == "Locked" and l.get_theme_color("font_color").is_equal_approx(UIStyle.WARN):
			warn = true
	box.free()
	_expect(gold and warn, "styled lean tooltip: gold hint %s, WARN Locked %s" % [gold, warn])


func _check_class_chosen() -> void:
	_expect(bar.messages_shown == ["Garran Stoneward takes up the Sword and Shield"],
			"class message(s): %s" % [bar.messages_shown])
	var s0: Node = bar.slots[0]
	_expect(s0.class_badge.visible and s0.is_class_pop_playing(), "bar badge after the draw: visible %s pop %s" % [
			s0.class_badge.visible, s0.is_class_pop_playing()])
	var o: Node = tavern.rows[1]
	_expect(o.class_line_text() == "Sword and Shield · skills 1 / 3", "L2 line 4 '%s'" % o.class_line_text())
	_expect(o.is_flashing(), "the row did not flash on class_chosen")
	_expect(o.class_glyph.visible and not o.class_l2_badge.visible and o.tile_badge.visible,
			"L2 row: glyph %s L2 %s tile %s" % [o.class_glyph.visible, o.class_l2_badge.visible, o.tile_badge.visible])
	_expect(o.stats_label.text == "561 HP · 13 damage · 1.8 range · 4.1 speed · 30 armor", "L2 stats '%s'" % o.stats_label.text)
	_expect(o.class_word.tooltip_text.begins_with("Sword and Shield\nmelee · 13 damage every 1.1 s · reach 1.8\n"
			+ "+10 armor · -0.2 speed\nRiposte L2 · Second Wind L3 · Shield Throw L5"), "class tooltip:\n%s" % o.class_word.tooltip_text)


func _check_inspect_after() -> void:
	var title: String = panel.champion_name.text.to_upper() + panel.champion_title.text + panel.champion_class_label.text
	_expect(title == "GARRAN STONEWARD · the Oathwall · Sword and Shield", "title after '%s'" % title)
	_expect(panel.champion_class_label.tooltip_text.begins_with("Sword and Shield\nmelee · "), "class label tooltip")
	_expect(panel.champion_row2_caption.text == "Sword and Shield", "row 2 caption '%s'" % panel.champion_row2_caption.text)
	_expect(panel.champion_ability_list() == "Oath of Iron, Shield Bash, Bulwark Stand, Riposte, Second Wind, Shield Throw",
			"ability list after '%s'" % panel.champion_ability_list())
	var want := [[&"riposte", true, "L2"], [&"second_wind", false, "L3"], [&"shield_throw", false, "L5"]]
	for j in 3:
		var slot: Node = panel.champion_abilities[3 + j]
		var locked: bool = not want[j][1]
		_expect(slot.ability_id == want[j][0] and not slot.placeholder and not slot.question.visible
				and slot.badge.visible == locked and (not locked or (slot.badge.get_child(0) as Label).text == want[j][2]),
				"class slot %d: id %s badge %s '%s'" % [j, slot.ability_id, slot.badge.visible,
				(slot.badge.get_child(0) as Label).text])
		_expect(slot.tooltip_text.split("\n")[0].ends_with("(class, level %s)" % want[j][2].substr(1)),
				"class slot %d tooltip line 1 '%s'" % [j, slot.tooltip_text.split("\n")[0]])
	_expect(panel.champion_abilities[4].tooltip_text.contains("Unlocks at level 3")
			and panel.champion_abilities[4].tooltip_text.begins_with("Second Wind  Locked  (class, level 3)"),
			"locked class skill tooltip:\n%s" % panel.champion_abilities[4].tooltip_text)
	_expect(panel.champion_autocast.text == "Autocast · next at level 3", "autocast after '%s'" % panel.champion_autocast.text)
	_expect(panel.champion_stats.text == "Level 2 · Damage 13 · Range 1.8 · Speed 4.1 · Armor 30",
			"stat line after '%s'" % panel.champion_stats.text)
	_expect(panel.champion_view.find_children("*", "BaseButton", true, false).is_empty(), "champion view has buttons")


func _check_bar_after() -> void:
	var s0: Node = bar.slots[0]
	# (still popping: read the unscaled rect) 16 x 16 at (6, 50) in the slot at (16, 408).
	_expect(_at(s0, Vector2(16, 408)) and s0.class_badge.position.distance_to(Vector2(6, 50)) < 0.5
			and s0.class_badge.size.distance_to(Vector2(16, 16)) < 0.5, "bar badge at %s (local %s)" % [
			_rect(s0.class_badge), s0.class_badge.position])
	_expect(s0.tooltip_text.split("\n")[0] == "Garran Stoneward  [F5]  the Oathwall · Sword and Shield",
			"tooltip line 1 after '%s'" % s0.tooltip_text.split("\n")[0])
	_expect(s0.tooltip_text.split("\n").size() == 5, "tooltip lines after: %d" % s0.tooltip_text.split("\n").size())
	_expect(s0.class_badge.tooltip_text == "Sword and Shield\nmelee · 13 damage every 1.1 s · reach 1.8\n"
			+ "+10 armor · -0.2 speed\nRiposte L2 · Second Wind L3 · Shield Throw L5", "badge tooltip:\n%s" % s0.class_badge.tooltip_text)
	_expect(s0.class_badge.mouse_filter == Control.MOUSE_FILTER_PASS, "badge mouse_filter not PASS")
	if ResourceLoader.exists("res://art/icons/classes/sword_shield.png"):
		_expect(s0.class_badge.uses_icon(), "the class PNG exists but the badge draws the glyph")
	else:
		_notes.append("no art/icons/classes/sword_shield.png: PNG path not exercised")
	ChampionBar.class_icons_enabled = false
	bar.refresh()
	_expect(not s0.class_badge.uses_icon() and s0.class_badge.visible, "icons off: the badge still uses a texture")
	ChampionBar.class_icons_enabled = true
	bar.refresh()
	# A champion loaded from a save with its class: badge, no pop, no message.
	var d := _stub(&"coin_cutter", "Sable Quint", 3, Unit.Team.PLAYER, {"max_hp": 300.0}, Vector3(2, 0, -2))
	d.cls = &"two_hand"
	guild.champions[2] = d
	bar.refresh()
	var s2: Node = bar.slots[2]
	_expect(s2.class_badge.visible and s2.class_badge.class_id == &"two_hand" and not s2.is_class_pop_playing(),
			"loaded class: visible %s id %s pop %s" % [s2.class_badge.visible, s2.class_badge.class_id,
			s2.is_class_pop_playing()])
	_expect(bar.messages_shown.size() == 1, "a loaded class showed a message: %s" % [bar.messages_shown])
	# Empty slots show no badge.
	s2.show_empty(true)
	_expect(not s2.class_badge.visible, "empty slot shows a class badge")
	guild.champions[2] = c
	bar.refresh()


func _check_inspect_spear() -> void:
	_expect(panel.champion_name.text == "Tamsin Farrow", "spear inspect name '%s'" % panel.champion_name.text)
	_expect(panel.champion_stats.text.contains("Range 2.4"), "spear stat line '%s'" % panel.champion_stats.text)
	_expect(panel.champion_ability_names[0].text == "Signal Flare", "Wayfinder ability 1 '%s'" %
			panel.champion_ability_names[0].text)
	_expect(panel.champion_ability_list() == "Signal Flare, Snare Line, Trailblaze, Lunge, Hobbling Javelin, Skewer",
			"spear list '%s'" % panel.champion_ability_list())
	_expect(panel.champion_autocast.text == "Autocast", "L5 autocast '%s'" % panel.champion_autocast.text)
	_expect(panel.champion_row2_caption.text == "Spear", "spear caption '%s'" % panel.champion_row2_caption.text)


func _check_inspect_enemy() -> void:
	_expect(panel.current_view() == "champion" and panel.champion_name.text == "Gerda Stoneward",
			"enemy not inspected (view %s)" % panel.current_view())
	_expect(panel.champion_class_label.text == " · no class yet", "enemy class part '%s'" % panel.champion_class_label.text)
	var tip: String = panel.champion_abilities[3].tooltip_text
	_expect(tip.contains("leans Sword and Shield (60 %)") and not tip.contains("Your bounties"),
			"enemy ? tooltip (base weights, no hint):\n%s" % tip)
	_expect(panel.champion_autocast.text == "Autocast", "enemy autocast '%s'" % panel.champion_autocast.text)
	_expect(panel.champion_intent.text == "Enemy champion", "enemy intent '%s'" % panel.champion_intent.text)


func _spawn_enemies() -> void:
	e = _stub(&"oathwall", "Gerda Stoneward", 1, Unit.Team.ENEMY, {"max_hp": 520.0, "armor": 20.0}, Vector3(3, 0, 0))
	e.bounty_leans = {&"guard": 2}   # the enemy view ignores leans (base weights)
	f = _stub(&"coin_cutter", "Silas Quint", 1, Unit.Team.ENEMY, {"max_hp": 300.0}, Vector3(-3, 0, 0))
	f.visible = false


func _check_enemy_messages() -> void:
	bar.scan_champions()
	var before: int = bar.messages_shown.size()
	e.choose(&"spear")
	f.choose(&"two_hand")
	e.choose(&"spear")
	var got: Array = bar.messages_shown.slice(before)
	_expect(got == ["Gerda Stoneward takes up the Spear"], "enemy messages %s" % [got])
	_expect(ChampionBar.class_message(b, &"wizard") == "Orla Fenwick takes up the Wizard's staff",
			"wizard message '%s'" % ChampionBar.class_message(b, &"wizard"))


func _check_fallback_tables() -> void:
	var with_data := [ChampionBar.class_tooltip(&"two_hand"), ChampionBar.lean_tooltip(ChampionBar.class_weights_for(a)),
			ChampionBar.class_display_name(&"wizard"), ChampionBar.usual_class(&"coin_cutter")]
	ChampionBar.class_scripts_enabled = false
	var fallback := [ChampionBar.class_tooltip(&"two_hand"), ChampionBar.lean_tooltip(ChampionBar.class_weights_for(a)),
			ChampionBar.class_display_name(&"wizard"), ChampionBar.usual_class(&"coin_cutter")]
	ChampionBar.class_scripts_enabled = true
	_expect(with_data == fallback, "fallback tables differ:\n%s\nvs\n%s" % [with_data, fallback])
	_expect(fallback[0] == "Two-Hand Sword\nmelee · 24 damage every 1.55 s · reach 2.1\nno stat change\n"
			+ "Cleave L2 · Crushing Blow L3 · Whirlwind L5", "two-hand tooltip:\n%s" % fallback[0])
	_expect(ChampionBar.ability_tooltip(&"riposte", 2).begins_with("Riposte  (class, level 2)\nCooldown 22 s · Self, 4 s\n"
			+ "Melee attackers take 10.8 damage per hit.\nAutocast: when 2+ melee enemies attack it"),
			"riposte tooltip:\n%s" % ChampionBar.ability_tooltip(&"riposte", 2))


## With the real data (11.C1 landed): a real Oathwall paid 2 Guard bounties reads 71 % through
## ChampionClass.weights_for; after set_champion_class the UI reads its class, skills and tooltip.
func _check_real_champion() -> void:
	var type: Variant = load("res://data/champions/oathwall.tres") if ResourceLoader.exists(
			"res://data/champions/oathwall.tres") else null
	if type == null or not (type as Object).has_method(&"create_champion") \
			or not ResourceLoader.exists("res://data/champion_classes/sword_shield.tres"):
		_notes.append("no champion / class data: real-champion check skipped")
		return
	var ch: Node = type.call(&"create_champion", 0)
	ch.set(&"bounty_leans", {&"guard": 2})
	_expect(ChampionBar.lean_text(ChampionBar.class_weights_for(ch)) == "Sword and Shield (71 %)",
			"real Oathwall lean '%s'" % ChampionBar.lean_text(ChampionBar.class_weights_for(ch)))
	_expect(ChampionBar.lean_text(ChampionBar.class_weights_for(&"oathwall")) == "Sword and Shield (60 %)",
			"real Oathwall base lean '%s'" % ChampionBar.lean_text(ChampionBar.class_weights_for(&"oathwall")))
	ch.call(&"set_champion_class", &"sword_shield")
	_expect(ChampionBar.class_id_of(ch) == &"sword_shield" and ChampionBar.class_name_of(ch) == "Sword and Shield",
			"real class '%s'" % ChampionBar.class_id_of(ch))
	_expect(ChampionBar.ability_display_name(&"flare_arrow", &"wayfinder") == "Signal Flare", "type ability name")
	ch.free()


## "Nothing in scripts/ui/ calls a _private function" (the 11.C4 files).
func _check_no_private_calls() -> void:
	var re := RegEx.create_from_string("[A-Za-z0-9_\\)\\]]\\._[a-z]\\w*\\(|call\\(&?\"_")
	for path in ["res://scripts/ui/champion_bar.gd", "res://scripts/ui/tavern_window.gd",
			"res://scripts/ui/selection_panel.gd"]:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var line: String = lines[i]
			if line.strip_edges().begins_with("#") or line.contains("super._"):
				continue
			if re.search(line) != null:
				_errors.append("%s:%d calls a private function: %s" % [path, i + 1, line.strip_edges()])
