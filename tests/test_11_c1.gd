extends SceneTree
## 11.C1: ChampionClass + the 4 .tres, the level-2 draw (weights, bounty leans, RNG), set_champion_class, the
## x1.25 XP table, power(), save keys, class_chosen, ChampionType.class_weights / Signal Flare / class barks
## (docs/design/skills-rework.md sections 2, 3, 6, 8, 9 and "Done when" 11.C1).
## Run: godot --headless --path . -s tests/test_11_c1.gd --fixed-fps 60 --quit-after 1500

const TASK_ID := "11.c1"
const FAR := Vector3(300.0, 2.0, 300.0)
const DRAWS := 10000

# id: [damage, cooldown, range, ranged, projectile speed, stats, flee delta, attack style, skills, bounty kind]
const CLASSES := {
	&"spear": [13.0, 0.95, 2.4, false, 0.0, {&"move_speed": 0.2}, 0.0, &"spear_thrust",
			[&"lunge", &"hobbling_javelin", &"skewer"], &"explore"],
	&"sword_shield": [12.0, 1.10, 1.8, false, 0.0, {&"armor": 10.0, &"move_speed": -0.2}, -0.05, &"sword_slash",
			[&"riposte", &"second_wind", &"shield_throw"], &"guard"],
	&"two_hand": [24.0, 1.55, 2.1, false, 0.0, {}, 0.0, &"great_cleave",
			[&"cleave", &"crushing_blow", &"whirlwind"], &"hunt"],
	&"wizard": [11.0, 1.30, 7.5, true, 26.0, {&"max_hp_pct": -0.10}, 0.05, &"staff_bolt",
			[&"arc_bolt", &"slipstep", &"starfall"], &"escort"],
}
# archetype: [spear, sword_shield, two_hand, wizard] (2.1)
const WEIGHTS := {
	&"wayfinder": [50.0, 10.0, 15.0, 25.0],
	&"oathwall": [15.0, 60.0, 20.0, 5.0],
	&"coin_cutter": [25.0, 5.0, 55.0, 15.0],
	&"mender": [15.0, 20.0, 5.0, 60.0],
}
const CLASS_BARKS := {
	&"wayfinder": "New road, new stick.",
	&"oathwall": "Something heavier. Finally.",
	&"coin_cutter": "Bigger blade, bigger cut.",
	&"mender": "Every tool mends something.",
}

var main: Node3D
var frame := 0
var _boot := 0
var _errors: Array[String] = []
var _events: Array[String] = []

# Timed: the Wizard class shoots bolts, a Spear Wayfinder does not.
var _wiz: Champion
var _wiz_foe: Unit
var _spear: Champion
var _spear_foe: Unit
var _bolt_seen := false
var _spear_bolt := false


func _initialize() -> void:
	main = Node3D.new()
	main.name = "World"
	root.add_child(main)
	current_scene = main
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000.0, 1.0, 2000.0)
	shape.shape = box
	shape.position.y = -0.5
	floor_body.add_child(shape)
	main.add_child(floor_body)


func _process(_delta: float) -> bool:
	_boot += 1
	if _boot < 3:
		return false
	frame += 1
	if frame == 1:
		_run_instant()
		_setup_timed()
	elif frame > 1 and frame < 240:
		_watch_bolts()
	elif frame == 240:
		_check_timed()
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)


func _near(a: float, b: float, eps: float = 0.01) -> bool:
	return absf(a - b) < eps


func _quiet(ch: Node) -> void:
	for child_name: String in ["Brain", "ChampionAbilities"]:
		var n := ch.get_node_or_null(child_name)
		if n:
			n.process_mode = Node.PROCESS_MODE_DISABLED


func _champion(id: StringName, team: int, pos: Vector3, variant: int = 0) -> Champion:
	var ch := ChampionType.find(id).create_champion(variant)
	ch.team = team as Unit.Team
	main.add_child(ch)
	ch.global_position = pos
	ch.command_stop()
	_quiet(ch)
	return ch


func _unit(type_id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(type_id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


# A class_rng seed whose first draw for `ch` is `want`.
func _seed_for(ch: Champion, want: StringName) -> int:
	var rng := RandomNumberGenerator.new()
	for s in range(1, 5000):
		rng.seed = s
		if ChampionClass.pick(ch, rng) == want:
			return s
	return -1


# ------------------------------------------------------------------ instant checks

func _run_instant() -> void:
	_check_class_data()
	_check_type_data()
	_check_xp_and_draw_once()
	_check_draw_odds()
	_check_bounty_leans()
	_check_class_stats()
	_check_power()
	_check_save_state()


func _check_class_data() -> void:
	var all := ChampionClass.all()
	_check(all.size() == 4, "ChampionClass.all() = %d" % all.size())
	for id: StringName in CLASSES:
		var c := ChampionClass.find(id)
		if c == null:
			_check(false, "missing data/champion_classes/%s.tres" % id)
			continue
		var r: Array = CLASSES[id]
		_check(c.id == id and c.display_name != "" and c.tooltip != "" and c.icon_abbrev != "", "%s texts" % id)
		_check(_near(c.attack_damage, r[0]) and _near(c.attack_cooldown, r[1]) and _near(c.attack_range, r[2]),
				"%s weapon %s / %s / %s" % [id, c.attack_damage, c.attack_cooldown, c.attack_range])
		_check(c.is_ranged == r[3] and _near(c.projectile_speed, r[4]), "%s ranged / projectile speed" % id)
		_check(str(c.stats) == str(r[5]), "%s stats %s" % [id, c.stats])
		_check(_near(c.flee_delta, r[6]) and c.attack_style == r[7], "%s flee delta / attack style" % id)
		_check(str(c.ability_ids) == str(r[8]) and str(c.unlock_levels) == "[2, 3, 5]", "%s skills %s" % [id, c.ability_ids])
		_check(c.bounty_kind == r[9], "%s bounty kind %s" % [id, c.bounty_kind])
		_check(c.modifier_id() == StringName("class:" + String(id)), "%s modifier id" % id)
		_check(c.skills_unlocked_at(1) == 0 and c.skills_unlocked_at(2) == 1 and c.skills_unlocked_at(4) == 2
				and c.skills_unlocked_at(5) == 3, "%s unlocks 2 / 3 / 5" % id)
	_check(ChampionClass.find(&"wizard").projectile_color.is_equal_approx(Color(0.6, 0.75, 1.0)), "wizard bolt colour")
	_check(ChampionClass.find("Sword and Shield") == ChampionClass.find(&"sword_shield"), "find by name")
	_check(ChampionClass.find("Two-Hand Sword") == ChampionClass.find(&"two_hand"), "find by display name")
	_check(ChampionClass.find(&"nope") == null, "unknown class -> null")
	_check(ChampionClass.bounty_kind_name(2) == &"guard" and ChampionClass.bounty_kind_name("Escort") == &"escort",
			"bounty_kind_name")


func _check_type_data() -> void:
	for id: StringName in WEIGHTS:
		var t := ChampionType.find(id)
		var w: Array = WEIGHTS[id]
		var i := 0
		for cid in ChampionClass.IDS:
			_check(_near(t.class_weight(cid), w[i]), "%s weight %s = %s (want %s)" % [id, cid, t.class_weight(cid), w[i]])
			i += 1
		_check(t.bark_for(&"class_chosen") == CLASS_BARKS[id], "%s class bark '%s'" % [id, t.bark_for(&"class_chosen")])
		_check(t.ability_ids.size() == 3, "%s keeps 3 archetype abilities" % id)
	_check(ChampionType.BARK_CHANCES.get(&"class_chosen", 0.0) == 1.0, "class bark 100 %")
	var way := ChampionType.find(&"wayfinder")
	_check(way.ability_name(&"flare_arrow") == "Signal Flare", "flare_arrow shown as Signal Flare")
	_check(way.ability_text(&"flare_arrow").begins_with("Hurls a flare up to 20 m"), "Signal Flare text")
	_check(way.ability_name(&"snare_line", "Snare Line") == "Snare Line", "other names unchanged")
	_check(ChampionClass.usual_for(ChampionType.find(&"oathwall")).id == &"sword_shield", "Oathwall usually Sword and Shield")


func _check_xp_and_draw_once() -> void:
	var c := _champion(&"coin_cutter", 0, FAR)
	_check(c.class_id() == &"" and c.champion_class == null, "no class at level 1")
	_check(not c.is_ranged() and _champion(&"wayfinder", 0, FAR + Vector3(0, 0, 3)).is_ranged(),
			"is_ranged from the archetype before the class")
	_check(c.xp_to_next() == 190, "L1 bar 190 (%d)" % c.xp_to_next())
	c.class_chosen.connect(func(ch: Champion, cid: StringName) -> void:
		_events.append("class:%s:%d:%s" % [cid, ch.level, ch.class_id()]))
	c.level_changed.connect(func(_u: Unit, l: int) -> void: _events.append("level:%d" % l))
	c.add_xp(189)
	_check(c.level == 1 and c.class_id() == &"", "189 XP: still level 1, no class")
	c.add_xp(1)
	_check(c.level == 2 and c.class_id() != &"", "190 XP -> level 2 with a class (%d, %s)" % [c.level, c.class_id()])
	_check(_events.size() == 2 and _events[0].begins_with("class:") and _events[1] == "level:2",
			"class_chosen (level 2, class set) before level_changed: %s" % str(_events))
	if not _events.is_empty():
		_check(_events[0] == "class:%s:2:%s" % [c.class_id(), c.class_id()], "class_chosen args %s" % _events[0])
	_check(ChampionClass.IDS.has(c.class_id()), "drawn class is one of the 4")
	var chosen := c.class_id()
	_check(c.xp_to_next() == 310, "L2 bar 310 (%d)" % c.xp_to_next())
	c.add_xp(2189 - 190)
	_check(c.level == 5 and c.total_xp == 2189, "2189 XP -> level 5 (%d)" % c.level)
	c.add_xp(1)
	_check(c.level == 6 and c.is_max_level() and c.total_xp == 2190, "2190 XP -> level 6 (%d)" % c.level)
	c.take_damage(100000.0, null)
	_check(not c.is_alive(), "champion died")
	c.respawn(FAR + Vector3(0, 0, 6))
	_check(c.is_alive() and c.class_id() == chosen, "class kept through death and revive")
	var drawn := 0
	for e in _events:
		if e.begins_with("class:"):
			drawn += 1
	_check(drawn == 1, "class_chosen exactly once (%d)" % drawn)
	# A dismissed and re-hired archetype is a new champion: level 1, no class.
	var again := _champion(&"coin_cutter", 0, FAR + Vector3(0, 0, 9))
	_check(again.level == 1 and again.class_id() == &"" and again.bounty_leans.is_empty(), "re-hired: no class")
	# A class set before level 2 (campaign companion) is never replaced by a draw.
	var comp := _champion(&"mender", 0, FAR + Vector3(0, 0, 12))
	comp.set_champion_class(&"sword_shield")
	var fired := [0]
	comp.class_chosen.connect(func(_c: Champion, _id: StringName) -> void: fired[0] += 1)
	comp.add_xp(600)
	_check(comp.level == 3 and comp.class_id() == &"sword_shield" and fired[0] == 0, "companion keeps its class, no draw")
	# announce = true: class_chosen once; the same class again does nothing.
	var loud := _champion(&"wayfinder", 0, FAR + Vector3(0, 0, 15))
	var loud_fired := [0]
	loud.class_chosen.connect(func(_c: Champion, id: StringName) -> void:
		if id == &"spear":
			loud_fired[0] += 1)
	loud.set_champion_class(&"spear", true)
	loud.set_champion_class(&"spear", true)
	_check(loud_fired[0] == 1 and loud.class_id() == &"spear", "set_champion_class(id, true) announces once (%d)"
			% loud_fired[0])


func _check_draw_odds() -> void:
	var oath := _champion(&"oathwall", 0, FAR + Vector3(0, 0, 30))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1101
	var pct := _share(oath, rng, &"sword_shield")
	_check(pct >= 0.58 and pct <= 0.62, "Oathwall, no bounty: Sword and Shield %.3f (58-62 %%)" % pct)
	oath.bounty_leans = {&"guard": 2}
	var w2 := ChampionClass.weights_for(oath)
	_check(_near(float(w2[&"sword_shield"]), 100.0) and _near(float(w2[&"spear"]), 15.0), "2 Guard: weights %s" % w2)
	pct = _share(oath, rng, &"sword_shield")
	_check(pct >= 0.69 and pct <= 0.73, "Oathwall, 2 Guard: Sword and Shield %.3f (69-73 %%)" % pct)
	oath.bounty_leans = {&"guard": 3}
	var w3 := ChampionClass.weights_for(oath)
	_check(str(w3) == str(w2), "a third Guard bounty adds nothing (%s)" % w3)
	pct = _share(oath, rng, &"sword_shield")
	_check(pct >= 0.69 and pct <= 0.73, "Oathwall, 3 Guard: still %.3f" % pct)
	var cc := _champion(&"coin_cutter", 0, FAR + Vector3(0, 0, 33))
	cc.bounty_leans = {&"escort": 1}
	var ch := ChampionClass.chances_for(cc)
	_check(_near(float(ch[&"wizard"]), 35.0 / 120.0, 0.001), "Coin-Cutter + 1 Escort: Wizard 29 %% (%s)" % ch[&"wizard"])
	# Same seed, same draw (the champion's own generator is used by the level-2 draw).
	var a := _champion(&"wayfinder", 0, FAR + Vector3(0, 0, 36))
	var b := _champion(&"wayfinder", 0, FAR + Vector3(0, 0, 39))
	a.class_rng.seed = 77
	b.class_rng.seed = 77
	a.add_xp(190)
	b.add_xp(190)
	_check(a.class_id() == b.class_id() and a.class_id() != &"", "seeded draws repeat (%s / %s)" % [a.class_id(), b.class_id()])


func _share(ch: Champion, rng: RandomNumberGenerator, want: StringName) -> float:
	var n := 0
	for i in DRAWS:
		if ChampionClass.pick(ch, rng) == want:
			n += 1
	return float(n) / float(DRAWS)


func _check_bounty_leans() -> void:
	var board := BountyBoard.new()
	board.team = 0
	board.name = "BountyBoard0"
	board.add_to_group(&"bounty_boards")
	main.add_child(board)
	var ch := _champion(&"oathwall", 0, FAR + Vector3(0, 0, 50))
	var other := _champion(&"mender", 0, FAR + Vector3(0, 0, 53))
	var guard1 := Bounty.new()
	guard1.kind = Bounty.GUARD
	var guard2 := Bounty.new()
	guard2.kind = Bounty.GUARD
	var guard3 := Bounty.new()
	guard3.kind = Bounty.GUARD
	var hunt := Bounty.new()
	hunt.kind = Bounty.HUNT
	board.bounty_paid.emit(guard1, ch, 5)
	board.bounty_paid.emit(guard1, ch, 5)   # a Guard service pays in ticks: counts once
	board.bounty_paid.emit(hunt, other, 30)  # paid to someone else
	_check(int(ch.bounty_leans.get(&"guard", 0)) == 1 and ch.bounty_leans.size() == 1,
			"one Guard bounty paid in 2 ticks = 1 lean (%s)" % ch.bounty_leans)
	_check(other.bounty_leans == {&"hunt": 1}, "the other champion got its Hunt lean (%s)" % other.bounty_leans)
	board.bounty_paid.emit(guard2, ch, 5)
	board.bounty_paid.emit(guard3, ch, 5)
	_check(int(ch.bounty_leans.get(&"guard", 0)) == 3, "3 Guard bounties counted (%s)" % ch.bounty_leans)
	_check(_near(float(ChampionClass.weights_for(ch)[&"sword_shield"]), 100.0), "capped at +40")
	ch.set_champion_class(&"sword_shield")   # after the class: no more leans
	ch.add_xp(190)
	board.bounty_paid.emit(hunt, ch, 30)
	_check(not ch.bounty_leans.has(&"hunt"), "no lean counted after the class")
	for b: Bounty in [guard1, guard2, guard3, hunt]:
		b.free()


func _check_class_stats() -> void:
	# A Coin-Cutter that takes Two-Hand at level 2: 24 x 1.08 = 25.92 damage, cooldown 1.55, range 2.1.
	var cc := _champion(&"coin_cutter", 0, FAR + Vector3(0, 0, 70))
	var s := _seed_for(cc, &"two_hand")
	_check(s > 0, "a seed that draws Two-Hand")
	cc.class_rng.seed = s
	cc.add_xp(190)
	_check(cc.class_id() == &"two_hand", "Coin-Cutter drew Two-Hand (%s)" % cc.class_id())
	_check(_near(cc.attack_damage, 25.92) and _near(cc.attack_cooldown, 1.55) and _near(cc.attack_range, 2.1),
			"Two-Hand Coin-Cutter L2: %s / %s / %s" % [cc.attack_damage, cc.attack_cooldown, cc.attack_range])
	_check(cc.has_modifier(&"class:two_hand") and _near(cc.get_stat(&"armor"), 5.0) and _near(cc.move_speed, 5.6),
			"Two-Hand: modifier, no stat change")
	_check(not cc.is_ranged() and cc.class_skills_unlocked() == 1, "Two-Hand melee, 1 class skill at L2")
	# An Oathwall Sword and Shield at level 2: 520 x 1.08 = 561.6 HP (whole HP: 562), armor 30.
	var oath := _champion(&"oathwall", 0, FAR + Vector3(0, 0, 74))
	oath.class_rng.seed = _seed_for(oath, &"sword_shield")
	oath.add_xp(190)
	_check(oath.class_id() == &"sword_shield", "Oathwall drew Sword and Shield (%s)" % oath.class_id())
	_check(absf(oath.max_hp - 561.6) <= 0.5, "S&S Oathwall L2 HP %s (561.6)" % oath.max_hp)
	_check(_near(oath.get_stat(&"armor"), 30.0), "S&S Oathwall armor 30 (%s)" % oath.get_stat(&"armor"))
	_check(_near(oath.move_speed, 4.1) and _near(oath.attack_damage, 12.0 * 1.08) and _near(oath.attack_cooldown, 1.1),
			"S&S weapon / speed (%s / %s)" % [oath.attack_damage, oath.move_speed])
	_check(_near(oath.flee_pct, 0.15), "S&S Oathwall flees at 15 %% (%s)" % oath.flee_pct)
	# Idempotent, and &"" goes back to the archetype weapon.
	var hp_before := oath.max_hp
	oath.set_champion_class(&"sword_shield")
	_check(_near(oath.max_hp, hp_before) and _near(oath.get_stat(&"armor"), 30.0), "set_champion_class is idempotent")
	oath.set_champion_class(&"")
	_check(oath.class_id() == &"" and not oath.has_modifier(&"class:sword_shield") and _near(oath.get_stat(&"armor"), 20.0)
			and _near(oath.attack_damage, 15.0 * 1.08) and _near(oath.attack_range, 1.8) and _near(oath.flee_pct, 0.20),
			"class cleared: archetype weapon back")
	oath.set_champion_class(&"sword_shield")
	_check(_near(oath.get_stat(&"armor"), 30.0) and oath.class_id() == &"sword_shield", "class set again")
	# A Wizard: range 7.5, bolts, 10 % less HP (Mender L2: 280 x (1 + 0.08 - 0.10) = 274.4; L4 319).
	var men := _champion(&"mender", 0, FAR + Vector3(0, 0, 78))
	men.class_rng.seed = _seed_for(men, &"wizard")
	men.add_xp(190)
	_check(men.class_id() == &"wizard", "Mender drew Wizard (%s)" % men.class_id())
	_check(men.is_ranged() and _near(men.attack_range, 7.5) and _near(men.projectile_speed, 26.0)
			and men.projectile_color.is_equal_approx(Color(0.6, 0.75, 1.0)), "Wizard: ranged 7.5 m, 26 m/s blue bolt")
	_check(absf(men.max_hp - 274.4) <= 0.5, "Wizard Mender L2 HP %s (274.4: 10 %% less)" % men.max_hp)
	_check(_near(men.attack_damage, 11.0 * 1.08) and _near(men.attack_cooldown, 1.3), "Wizard weapon 11 / 1.3")
	_check(_near(men.flee_pct, 0.50), "Wizard Mender flees at 50 %% (%s)" % men.flee_pct)
	men.add_xp(940 - 190)
	_check(men.level == 4 and absf(men.max_hp - 319.2) <= 0.5, "Wizard Mender L4 HP %s (319)" % men.max_hp)
	# A Spear Wayfinder is melee (2.4 m reach) and 0.2 faster.
	var way := _champion(&"wayfinder", 0, FAR + Vector3(0, 0, 82))
	way.set_champion_class(&"spear")
	_check(not way.is_ranged() and _near(way.attack_range, 2.4) and _near(way.move_speed, 6.0)
			and _near(way.projectile_speed, 0.0), "Spear Wayfinder melee 2.4 m, speed 6.0 (%s)" % way.move_speed)


func _check_power() -> void:
	var c := _champion(&"wayfinder", 0, FAR + Vector3(0, 0, 90))
	_check(_near(c.power(), 200.0), "power L1 = 200 (%s)" % c.power())
	c.add_xp(190)
	_check(_near(c.power(), 150.0 + 100.0 + 20.0), "power L2 with class = 270 (%s)" % c.power())
	c.add_xp(500 - 190)
	_check(_near(c.power(), 150.0 + 150.0 + 40.0), "power L3 = 340 (%s)" % c.power())
	c.add_xp(940 - 500)
	_check(_near(c.power(), 150.0 + 200.0 + 40.0), "power L4 = 390 (%s)" % c.power())
	c.add_xp(1500 - 940)
	_check(c.level == 5 and _near(c.power(), 150.0 + 250.0 + 60.0), "power L5 = 150 + 250 + 60 (%s)" % c.power())
	_check(_near(c.power(true), c.power()), "power(with_hp) at full HP")


func _check_save_state() -> void:
	var base := FAR + Vector3(0, 0, 110)
	# Level 3 Wizard Mender with leans: JSON round trip, restored in the tree and before it.
	var s := _champion(&"mender", 0, base, 1)
	s.bounty_leans = {&"escort": 2, &"guard": 1}
	s.class_rng.seed = _seed_for(s, &"wizard")
	s.add_xp(600)
	var d: Dictionary = JSON.parse_string(JSON.stringify(s.get_save_state()))
	_check(str(d.get("class", "?")) == "wizard", "save has class 'wizard' (%s)" % d.get("class", "?"))
	_check(d.get("bounty_leans") is Dictionary and int(d["bounty_leans"].get("escort", 0)) == 2
			and int(d["bounty_leans"].get("guard", 0)) == 1, "save has the leans %s" % d.get("bounty_leans"))
	var fired := [0]
	var r := _champion(&"mender", 0, base + Vector3(0, 0, 4))
	r.class_chosen.connect(func(_c: Champion, _id: StringName) -> void: fired[0] += 1)
	r.apply_save_state(d)
	_same(s, r, "in tree")
	var fresh := Champion.new()
	fresh.class_chosen.connect(func(_c: Champion, _id: StringName) -> void: fired[0] += 1)
	fresh.apply_save_state(d)
	fresh.team = Unit.Team.PLAYER
	main.add_child(fresh)
	fresh.global_position = base + Vector3(0, 0, 8)
	_quiet(fresh)
	_same(s, fresh, "before tree")
	_check(fired[0] == 0, "restoring a class emits no class_chosen (%d)" % fired[0])
	# Level 1 with leans: no class, leans kept; the draw then uses them.
	var l1 := _champion(&"oathwall", 0, base + Vector3(0, 0, 12))
	l1.bounty_leans = {&"guard": 2}
	var d1: Dictionary = JSON.parse_string(JSON.stringify(l1.get_save_state()))
	_check(str(d1.get("class", "?")) == "", "level-1 save: class ''")
	var r1 := _champion(&"oathwall", 0, base + Vector3(0, 0, 16))
	r1.apply_save_state(d1)
	_check(r1.class_id() == &"" and r1.bounty_leans == {&"guard": 2}, "level-1 leans restored (%s)" % r1.bounty_leans)
	# An old step-9 save of a level-3 champion (no "class" key) draws quietly.
	var old := {"id": "coin_cutter", "variant": 0, "level": 3, "xp": 10, "total_xp": 510, "purse": 40,
			"hp_ratio": 1.0, "alive": true, "items": []}
	var o := _champion(&"coin_cutter", 0, base + Vector3(0, 0, 20))
	var old_fired := [0]
	o.class_chosen.connect(func(_c: Champion, _id: StringName) -> void: old_fired[0] += 1)
	o.apply_save_state(old)
	_check(o.level == 3 and o.class_id() != &"" and old_fired[0] == 0, "old save past level 2: class drawn quietly (%s)"
			% o.class_id())


func _same(a: Champion, b: Champion, what: String) -> void:
	_check(b.level == a.level and b.xp == a.xp and b.class_id() == a.class_id(), "%s: level / xp / class %d %d %s"
			% [what, b.level, b.xp, b.class_id()])
	_check(_near(b.max_hp, a.max_hp) and _near(b.attack_damage, a.attack_damage) and _near(b.attack_range, a.attack_range)
			and _near(b.projectile_speed, a.projectile_speed), "%s: class stats %s / %s / %s"
			% [what, b.max_hp, b.attack_damage, b.attack_range])
	_check(b.has_modifier(&"class:wizard") and _near(b.flee_pct, a.flee_pct), "%s: modifier / flee" % what)
	_check(b.bounty_leans == {&"escort": 2, &"guard": 1}, "%s: leans %s" % [what, b.bounty_leans])


# ------------------------------------------------------------------ timed checks

func _setup_timed() -> void:
	var base := FAR + Vector3(-120, 0, 0)
	_wiz = _champion(&"oathwall", 0, base)
	_wiz.set_champion_class(&"wizard")
	_wiz_foe = _unit("shade", 1, base + Vector3(6, 0, 0))
	_wiz_foe.max_hp = 100000.0
	_wiz_foe.hp = 100000.0
	_wiz_foe.command_hold()
	_wiz.command_attack(_wiz_foe)
	var base2 := FAR + Vector3(-120, 0, 60)
	_spear = _champion(&"wayfinder", 0, base2)
	_spear.set_champion_class(&"spear")
	_spear_foe = _unit("shade", 1, base2 + Vector3(1.6, 0, 0))
	_spear_foe.max_hp = 100000.0
	_spear_foe.hp = 100000.0
	_spear_foe.command_hold()
	_spear.command_attack(_spear_foe)


func _watch_bolts() -> void:
	for n in main.get_children():
		var p := n as Projectile
		if p == null:
			continue
		if p.source == _wiz and p.color.is_equal_approx(Color(0.6, 0.75, 1.0)):
			_bolt_seen = true
		if p.source == _spear:
			_spear_bolt = true


func _check_timed() -> void:
	_check(_bolt_seen, "an Oathwall Wizard shoots blue bolts")
	_check(_wiz_foe.hp < _wiz_foe.max_hp, "the Wizard's bolts hit (%s)" % _wiz_foe.hp)
	_check(not _spear_bolt, "a Spear Wayfinder shoots no arrows")
	_check(_spear_foe.hp < _spear_foe.max_hp, "the Spear Wayfinder hits in melee (%s)" % _spear_foe.hp)
