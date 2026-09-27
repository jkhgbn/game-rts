extends SceneTree
## Task 12.C3: NeutralCamp + CampManager (docs/design/map-fill.md sections 5.1-5.3, contract 13, "Done when" 12.C3).
## A small scene: a stub level (match clock, wizard_of(team) with settable levels), a flat navmesh, real Units.
## Creature types come from data/units/<id>.tres when 12.C4 has written them, else stubs with the 5.1 numbers.
## Run:  godot --headless --path . -s tests/test_12_c3.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "12.C3"

const LEVEL_SRC := """
extends Node3D
var clock := 0.0
var wiz := {}
func match_time() -> float:
	return clock
func wizard_of(team: int) -> Node:
	return wiz.get(team)
"""

const WIZ_SRC := """
extends Node
var level := 3
var team := 0
"""

## map-fill.md 5.2.
const SPOTS: Array[Dictionary] = [
	{"id": &"camp_wallow_s", "name": "Bristleback Wallow", "kind": &"bristleback", "tier": 1, "pos": Vector3(-14, 0, 57), "first_spawn": 0.0},
	{"id": &"camp_wallow_n", "name": "Bristleback Wallow", "kind": &"bristleback", "tier": 1, "pos": Vector3(14, 0, -57), "first_spawn": 0.0},
	{"id": &"camp_nest_s", "name": "Willow Ford Nest", "kind": &"mirefang", "tier": 2, "pos": Vector3(8.5, 0, 34), "first_spawn": 0.0},
	{"id": &"camp_nest_n", "name": "Reed Ford Nest", "kind": &"mirefang", "tier": 2, "pos": Vector3(-8.5, 0, -34), "first_spawn": 0.0},
	{"id": &"camp_hollow_nw", "name": "Gloomcap Hollow", "kind": &"gloomcap", "tier": 2, "pos": Vector3(-55, 0, -55), "first_spawn": 150.0},
	{"id": &"camp_hollow_se", "name": "Gloomcap Hollow", "kind": &"gloomcap", "tier": 2, "pos": Vector3(55, 0, 55), "first_spawn": 150.0},
	{"id": &"camp_stag_w", "name": "Stag Glade", "kind": &"hollow_stag", "tier": 3, "pos": Vector3(-37, 0, -10), "first_spawn": 210.0},
	{"id": &"camp_stag_e", "name": "Stag Glade", "kind": &"hollow_stag", "tier": 3, "pos": Vector3(37, 0, 10), "first_spawn": 210.0},
]

## 5.1: id -> [hp, armor, dmg, range, cd, speed, aggro, sight, radius, height, kill_xp]
const CREATURES := {
	&"bristleback": [200.0, 5.0, 11.0, 1.4, 1.2, 4.6, 6.0, 8.0, 0.55, 1.1, 25],
	&"mirefang": [190.0, 0.0, 10.0, 1.3, 0.9, 5.0, 6.0, 8.0, 0.45, 0.8, 30],
	&"gloomcap_elder": [420.0, 5.0, 14.0, 6.0, 1.6, 3.2, 7.0, 9.0, 0.6, 1.9, 50],
	&"gloomcap_sprout": [120.0, 0.0, 7.0, 1.2, 1.0, 4.0, 6.0, 7.0, 0.35, 0.7, 12],
	&"hollow_stag": [1400.0, 15.0, 30.0, 2.0, 1.6, 5.0, 8.0, 10.0, 0.9, 2.6, 160],
}

var errors: Array[String] = []
var _done := false
var level
var mgr: CampManager
var p_attacker: Unit
var e_attacker: Unit
var msgs: Array[String] = []
var clears: Array = []        # [camp, team, reward]
var engaged_count := 0
var bank_p
var bank_e
var stubbed: Array[StringName] = []


func _initialize() -> void:
	var ls := GDScript.new()
	ls.source_code = LEVEL_SRC
	ls.reload()
	level = Node3D.new()
	level.set_script(ls)
	level.name = "Level"
	root.add_child(level)
	current_scene = level
	var ws := GDScript.new()
	ws.source_code = WIZ_SRC
	ws.reload()
	for t in 2:
		var w := Node.new()
		w.set_script(ws)
		w.set(&"team", t)
		level.add_child(w)
		level.wiz[t] = w
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(260.0, 1.0, 260.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	level.add_child(ground)
	var nav := NavigationMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(240.0, 240.0)
	nav.create_from_mesh(plane)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	level.add_child(region)
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


func _run() -> void:
	await _frames(3)
	_build()
	await _phase_first_spawns()
	await _phase_clear_and_respawn()
	await _phase_levels()
	await _phase_underdog()
	await _phase_reset_heal()
	await _phase_drops()
	await _phase_missing_type()
	_check_skirmish_spots()
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	_done = true


func _build() -> void:
	mgr = CampManager.new()
	mgr.name = "CampManager"
	for id: StringName in CREATURES:
		if UnitType.find(String(id)) == null:
			mgr.creature_types[id] = _stub_type(id)
			stubbed.append(id)
	if not stubbed.is_empty():
		print("  (12.C4 .tres missing, stubbed: %s)" % [stubbed])
	level.add_child(mgr)
	mgr.message.connect(func(text: String, _s: float) -> void: msgs.append(text))
	mgr.camp_cleared.connect(func(c: Node3D, team: int, reward: Dictionary) -> void:
		clears.append([c, team, reward]))
	mgr.setup(SPOTS)
	for c in mgr.camps():
		c.engaged.connect(func(_c: Node3D) -> void: engaged_count += 1)
	bank_p = EssenceBank.for_team(0)
	bank_e = EssenceBank.for_team(1)
	bank_p.trickle_enabled = false
	bank_e.trickle_enabled = false
	var fg := UnitType.find("flame_guard")
	p_attacker = Worker.make_unit(fg)
	p_attacker.team = Unit.Team.PLAYER
	level.add_child(p_attacker)
	p_attacker.global_position = Vector3(0, 0, 2)
	p_attacker.command_stop()
	p_attacker.set_physics_process(false)
	e_attacker = Worker.make_unit(fg)
	e_attacker.team = Unit.Team.ENEMY
	level.add_child(e_attacker)
	e_attacker.global_position = Vector3(0, 0, -2)
	e_attacker.command_stop()
	e_attacker.set_physics_process(false)


func _stub_type(id: StringName) -> UnitType:
	var v: Array = CREATURES[id]
	var t := UnitType.new()
	t.id = id
	t.display_name = String(id).capitalize()
	t.faction = &"neutral"
	t.neutral_leash = true
	t.max_hp = v[0]
	t.armor = v[1]
	t.attack_damage = v[2]
	t.attack_range = v[3]
	t.attack_cooldown = v[4]
	t.move_speed = v[5]
	t.aggro_range = v[6]
	t.sight_radius = v[7]
	t.radius = v[8]
	t.body_height = v[9]
	t.kill_xp = v[10]
	t.pop = 0
	return t


# ---------------------------------------------------------------- phases

func _phase_first_spawns() -> void:
	_check(CampManager.instance(self) == mgr, "instance(tree) finds the manager")
	_check(mgr.camps().size() == 8, "8 camps (got %d)" % mgr.camps().size())
	for spot: Dictionary in SPOTS:
		var c := mgr.camp(spot["id"]) as NeutralCamp
		if c == null:
			_fail("camp %s missing" % spot["id"])
			continue
		_check(c.position.is_equal_approx(spot["pos"]) and c.tier == int(spot["tier"]) and c.kind == spot["kind"],
				"%s at %s tier %d" % [spot["id"], spot["pos"], spot["tier"]])
		_check(c.is_in_group(&"neutral_camps"), "%s in group neutral_camps" % spot["id"])
	await _at(0.0)
	_check(_alive(&"camp_wallow_s") == 2 and _alive(&"camp_wallow_n") == 2, "wallows spawn 2 Bristlebacks at 0:00")
	_check(_alive(&"camp_nest_s") == 3 and _alive(&"camp_nest_n") == 3, "nests spawn 3 Mirefangs at 0:00")
	_check(_alive(&"camp_hollow_nw") == 0 and _alive(&"camp_stag_w") == 0, "hollow / stag not at 0:00")
	_check(is_equal_approx(_camp(&"camp_hollow_nw").respawn_left(), 150.0), "hollow respawn_left 150 at 0:00")
	for c: NeutralCamp in [_camp(&"camp_wallow_s"), _camp(&"camp_nest_s")]:
		for u: Unit in c.creatures():
			_check(u.team == Unit.Team.NEUTRAL and u.is_in_group(&"creatures") and u.is_in_group(&"units"),
					"creature neutral, in creatures + units")
			var d := Vector2(u.global_position.x - c.position.x, u.global_position.z - c.position.z).length()
			_check(d >= 1.4 and d <= 2.1, "creature in a ring r 1.5-2 (d %.2f)" % d)
			_check(mgr.camp_of(u) == c, "camp_of(creature)")
			_check(u.is_in_group(&"amphibious") == (c.kind == &"mirefang"), "amphibious only for Mirefangs")
			_check(_flat(u.home_position(), u.global_position) < 0.05, "home = spawn spot")
	# Point mirror of the rings.
	var a := _camp(&"camp_nest_s").creatures()
	var b := _camp(&"camp_nest_n").creatures()
	var mirrored := a.size() == b.size()
	for i in mini(a.size(), b.size()):
		mirrored = mirrored and _flat((a[i] as Unit).global_position, -(b[i] as Unit).global_position) < 0.05
	_check(mirrored, "mirrored camps get mirrored rings")
	await _at(149.0)
	_check(_alive(&"camp_hollow_nw") == 0, "no hollow at 2:29")
	await _at(150.0)
	_check(_alive(&"camp_hollow_nw") == 4 and _alive(&"camp_hollow_se") == 4, "hollows spawn 1 Elder + 3 Sprouts at 2:30")
	await _at(209.0)
	_check(_alive(&"camp_stag_w") == 0 and not msgs.has(CampManager.MSG_STAGS), "no stag and no stag message at 3:29")
	await _at(210.0)
	_check(_alive(&"camp_stag_w") == 1 and _alive(&"camp_stag_e") == 1, "stags at 3:30")
	var stag := _camp(&"camp_stag_w").creatures()[0] as Unit
	_check(_flat(stag.global_position, _camp(&"camp_stag_w").position) < 0.1, "the stag stands on the spot")
	_check(msgs.count(CampManager.MSG_STAGS) == 1, "stag message once at 3:30")
	await _at(215.0)
	_check(msgs.count(CampManager.MSG_STAGS) == 1, "stag message only once")
	if ResourceLoader.exists(CampManager.ABILITIES_PATH):
		var elder := _camp(&"camp_hollow_nw").creatures()[0] as Unit
		_check(elder.get_node_or_null(^"CreatureAbilities") != null and stag.get_node_or_null(^"CreatureAbilities") != null,
				"Elder and Stag get a CreatureAbilities child")
	# Previews and strength (camp level 0).
	var pv := _camp(&"camp_hollow_nw").reward_preview()
	_check(int(pv[&"xp"]) == _xp(&"gloomcap_elder") + 3 * _xp(&"gloomcap_sprout") and int(pv[&"essence"]) == 25 \
			and str(pv[&"drop_text"]) == "35 % a component", "hollow preview %s" % [pv])
	pv = _camp(&"camp_stag_w").reward_preview()
	_check(int(pv[&"xp"]) == _xp(&"hollow_stag") and int(pv[&"essence"]) == 50, "stag preview %s" % [pv])
	pv = _camp(&"camp_wallow_s").reward_preview()
	_check(int(pv[&"essence"]) == 10 and str(pv[&"drop_text"]) == "30 % Ember Draught", "wallow preview %s" % [pv])
	_check(is_equal_approx(_camp(&"camp_wallow_s").strength(), 200.0), "wallow strength 200")
	_check(is_equal_approx(_camp(&"camp_hollow_nw").strength(), 370.0), "hollow strength 370")
	_check(is_equal_approx(_camp(&"camp_stag_w").strength(), 700.0), "stag strength 700")
	_check(mgr.underdog_team() == -1, "underdog -1 with equal wizard levels")
	# Idle camp mates answer an attacker inside their leash.
	var w := _camp(&"camp_wallow_n")
	var ws := w.creatures()
	e_attacker.global_position = w.position + Vector3(3, 0, 0)
	(ws[0] as Unit).take_damage(5.0, e_attacker)
	_check((ws[1] as Unit).attack_target == e_attacker, "an idle camp mate answers the attacker")
	e_attacker.global_position = Vector3(0, 0, -2)
	await _frames(2)


## Clear bonus to the last killer's team, respawn after 120 s, blocked within 16 m (retry every 5 s).
func _phase_clear_and_respawn() -> void:
	var c := _camp(&"camp_wallow_s")
	var xp_seen: Array[int] = []
	for u: Unit in c.creatures():
		u.died.connect(func(v: Unit) -> void: xp_seen.append(Unit.kill_xp_value(v)))
	var creatures := c.creatures()
	var e0 := engaged_count
	(creatures[0] as Unit).take_damage(50.0, p_attacker)
	_check(engaged_count == e0 + 1, "engaged on the first hit")
	(creatures[0] as Unit).take_damage(99999.0, e_attacker)   # an enemy kill...
	var before: int = bank_p.essence
	var before_e: int = bank_e.essence
	clears.clear()
	(creatures[1] as Unit).take_damage(99999.0, p_attacker)   # ...but the player lands the last blow
	_check(clears.size() == 1 and clears[0][0] == c and int(clears[0][1]) == 0, "cleared(camp, PLAYER)")
	if clears.size() == 1:
		var reward: Dictionary = clears[0][2]
		_check(int(reward[&"essence"]) == 10 and not bool(reward[&"underdog"]), "clear bonus 10 (%s)" % [reward])
	_check(xp_seen == [_xp(&"bristleback"), _xp(&"bristleback")], "kill_xp unchanged at level 0 (%s)" % [xp_seen])
	await _frames(2)
	var kill_ess := EssenceBank.kill_essence(_xp(&"bristleback")) if root.has_node(^"Events") else 0
	_check(int(bank_p.essence) - before == 10 + kill_ess, "player bank +10 bonus + kill essence (got %d)" % (int(bank_p.essence) - before))
	_check(int(bank_e.essence) - before_e == 0, "no bonus to the team of an earlier kill")
	_check(mgr.cleared_count(0) == 1 and mgr.cleared_count(1) == 0, "cleared_count")
	_check(_has_msg("Bristleback Wallow cleared: +10 essence"), "own clear message (%s)" % [msgs])
	_check(c.is_cleared() and absf(c.respawn_left() - 120.0) < 0.6, "respawn_left 120 after the clear (%.1f)" % c.respawn_left())
	var t0: float = level.clock
	await _at(t0 + 119.0)
	_check(c.is_cleared(), "no respawn at 119 s")
	p_attacker.global_position = c.position + Vector3(10, 0, 0)   # blocks (within 16 m)
	await _at(t0 + 120.0)
	_check(c.is_cleared() and c.respawn_left() == 0.0, "respawn blocked by a unit within 16 m")
	p_attacker.global_position = Vector3(0, 0, 2)
	await _at(t0 + 124.0)
	_check(c.is_cleared(), "blocked respawn waits the 5 s retry")
	await _at(t0 + 125.5)
	_check(_alive(&"camp_wallow_s") == 2, "respawned after the retry")
	_check(c.camp_level == 1, "camp level 1 after a respawn (got %d)" % c.camp_level)
	var bb := mgr.creature_type(&"bristleback")
	var u0 := c.creatures()[0] as Unit
	_check(is_equal_approx(u0.max_hp, bb.max_hp * 1.15) and is_equal_approx(u0.hp, u0.max_hp),
			"level 1: max HP +15 %% (%.1f)" % u0.max_hp)
	_check(is_equal_approx(u0.attack_damage, bb.attack_damage * 1.1), "level 1: damage +10 %% (%.2f)" % u0.attack_damage)
	var pv := c.reward_preview()
	_check(int(pv[&"xp"]) == 2 * roundi(bb.kill_xp * 1.1) and int(pv[&"essence"]) == 11, "level 1 preview %s" % [pv])
	_check(is_equal_approx(c.strength(), 200.0 * 1.15), "level 1 strength x1.15")


## Levels go up once per respawn and stop at 3; kill_xp and bonus scale.
func _phase_levels() -> void:
	var c := _camp(&"camp_wallow_s")
	for i in 3:
		var xp_seen: Array[int] = []
		for u: Unit in c.creatures():
			u.died.connect(func(v: Unit) -> void: xp_seen.append(Unit.kill_xp_value(v)))
		var lvl := c.camp_level
		clears.clear()
		for u: Unit in c.creatures():
			u.take_damage(99999.0, p_attacker)
		var want := roundi(_xp(&"bristleback") * (1.0 + 0.1 * lvl))
		_check(xp_seen.size() == 2 and xp_seen[0] == want, "level %d kill_xp %d (%s)" % [lvl, want, xp_seen])
		_check(clears.size() == 1 and int(clears[0][2][&"essence"]) == roundi(10.0 * (1.0 + 0.1 * lvl)),
				"level %d clear bonus" % lvl)
		await _at(level.clock + 121.0)
		_check(c.camp_level == mini(lvl + 1, 3), "level %d -> %d" % [lvl, c.camp_level])
	_check(c.camp_level == 3, "camp level capped at 3")
	var u0 := c.creatures()[0] as Unit
	_check(is_equal_approx(u0.max_hp, mgr.creature_type(&"bristleback").max_hp * 1.45), "level 3: max HP +45 %")


## Underdog: x1.25 kill XP and x1.5 clear bonus only for the team whose wizard is lower level.
func _phase_underdog() -> void:
	level.wiz[0].level = 2
	level.wiz[1].level = 4
	_check(mgr.underdog_team() == 0, "underdog = the player (L2 vs L4)")
	var c := _camp(&"camp_nest_s")
	var xp_seen: Array[int] = []
	for u: Unit in c.creatures():
		u.died.connect(func(v: Unit) -> void: xp_seen.append(Unit.kill_xp_value(v)))
	var cs := c.creatures()
	msgs.clear()
	clears.clear()
	(cs[0] as Unit).take_damage(99999.0, e_attacker)
	(cs[1] as Unit).take_damage(99999.0, p_attacker)
	(cs[2] as Unit).take_damage(99999.0, p_attacker)
	var mf := _xp(&"mirefang")
	_check(xp_seen == [mf, roundi(mf * 1.25), roundi(mf * 1.25)], "underdog kill XP x1.25 only for the player (%s)" % [xp_seen])
	_check(clears.size() == 1 and int(clears[0][2][&"essence"]) == roundi(25 * 1.5) and bool(clears[0][2][&"underdog"]),
			"underdog clear bonus x1.5 (%s)" % [clears[0][2] if clears.size() > 0 else {}])
	_check(_has_msg("Underdog bonus: +50 % from the Willow Ford Nest"), "underdog message (%s)" % [msgs])
	# The ahead team gets nothing extra; an enemy clear the local team sees gives the enemy line.
	var c2 := _camp(&"camp_nest_n")
	clears.clear()
	msgs.clear()
	for u: Unit in c2.creatures():
		u.take_damage(99999.0, e_attacker)
	_check(clears.size() == 1 and int(clears[0][1]) == 1 and int(clears[0][2][&"essence"]) == 25,
			"no underdog bonus for the team ahead")
	_check(_has_msg("The enemy cleared the Reed Ford Nest"), "enemy clear message (%s)" % [msgs])
	level.wiz[0].level = 3
	level.wiz[1].level = 3


## Reset: 5 % max HP / s after 4 s undamaged at home, full heal after 6 s.
func _phase_reset_heal() -> void:
	var c := _camp(&"camp_hollow_nw")
	var elder := c.creatures()[0] as Unit
	var sprout := c.creatures()[1] as Unit
	var before_engaged := engaged_count
	elder.take_damage(200.0, p_attacker)
	sprout.take_damage(40.0, p_attacker)
	_check(engaged_count == before_engaged + 1, "one engaged per fight")
	sprout.take_damage(10.0, p_attacker)
	_check(engaged_count == before_engaged + 1, "engaged not repeated in the same fight")
	var hp0 := elder.hp
	await _frames(int(3.4 * 60))
	_check(is_equal_approx(elder.hp, hp0), "no heal before 4 s (%.1f vs %.1f)" % [elder.hp, hp0])
	await _frames(int(1.6 * 60))
	_check(elder.hp > hp0 and elder.hp < elder.max_hp, "5 %%/s regen after 4 s (%.1f -> %.1f)" % [hp0, elder.hp])
	await _frames(int(1.6 * 60))
	_check(is_equal_approx(elder.hp, elder.max_hp) and is_equal_approx(sprout.hp, sprout.max_hp),
			"full heal after 6 s (%.1f / %.1f)" % [elder.hp, elder.max_hp])
	sprout.take_damage(10.0, p_attacker)
	_check(engaged_count == before_engaged + 2, "engaged again after the camp reset")


## Drop tables (5.3) and ground items.
func _phase_drops() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 42
	var n := 6000
	var t1 := 0
	var t2c := 0
	var t2p := 0
	var t3r := 0
	var t3ok := true
	for i in n:
		var d1 := CampManager.roll_drops(1, r)
		if d1.size() == 1 and d1[0] == &"ember_draught":
			t1 += 1
		var d2 := CampManager.roll_drops(2, r)
		if d2.size() == 1 and CampManager.DROP_COMPONENTS.has(d2[0]):
			t2c += 1
		elif d2.size() == 1 and (d2[0] == &"ember_draught" or d2[0] == &"dusk_vial"):
			t2p += 1
		var d3 := CampManager.roll_drops(3, r)
		t3ok = t3ok and d3.size() >= 1 and CampManager.DROP_COMPONENTS.has(d3[0])
		if d3.size() == 2 and (d3[1] == &"warden_scale" or d3[1] == &"vital_root"):
			t3r += 1
	_check(absf(float(t1) / n - 0.30) < 0.025, "T1 30 %% Ember Draught (%.3f)" % (float(t1) / n))
	_check(absf(float(t2c) / n - 0.35) < 0.025, "T2 35 %% component (%.3f)" % (float(t2c) / n))
	_check(absf(float(t2p) / n - 0.325) < 0.025, "T2 else 50 %% draught / vial (%.3f)" % (float(t2p) / n))
	_check(t3ok, "T3 always one component")
	_check(absf(float(t3r) / n - 0.40) < 0.025, "T3 40 %% Warden Scale / Vital Root (%.3f)" % (float(t3r) / n))
	for id: StringName in CampManager.DROP_COMPONENTS + [&"ember_draught", &"dusk_vial", &"warden_scale", &"vital_root"]:
		_check(ItemDrops.item_type(id) != null, "item %s exists" % id)
	# The stag always drops a component on the ground at the spot.
	var c := _camp(&"camp_stag_w")
	var pickups_before := get_nodes_in_group(&"item_pickups").size()
	clears.clear()
	msgs.clear()
	for u: Unit in c.creatures():
		u.take_damage(99999.0, p_attacker)
	await _frames(2)
	var items: Array = clears[0][2][&"items"] if clears.size() == 1 else []
	_check(items.size() >= 1, "stag clear drops >= 1 item (%s)" % [items])
	var near := 0
	for node in get_nodes_in_group(&"item_pickups"):
		if (node as Node3D).global_position.distance_to(c.position) < 3.0:
			near += 1
	_check(get_nodes_in_group(&"item_pickups").size() - pickups_before == items.size() and near >= items.size(),
			"ground items at the spot (%d near)" % near)
	_check(_has_msg("Stag Glade cleared: +50 essence + "), "stag message names the drops (%s)" % [msgs])
	_check(absf(c.respawn_left() - 240.0) < 0.6, "T3 respawn 240 s (%.1f)" % c.respawn_left())
	var h := _camp(&"camp_hollow_se")
	for u: Unit in h.creatures():
		u.take_damage(99999.0, e_attacker)
	_check(absf(h.respawn_left() - 180.0) < 0.6, "T2 respawn 180 s (%.1f)" % h.respawn_left())


## A missing creature .tres skips the camp with a warning.
func _phase_missing_type() -> void:
	var m2 := CampManager.new()
	m2.name = "CampManager2"
	m2.creature_types[&"hollow_stag"] = null
	level.add_child(m2)
	var c := m2.add_camp(&"hollow_stag", &"test_stag", "Test Glade", Vector3(0, 0, -20), 0.0) as NeutralCamp
	_check(c != null and c.tier == 3, "add_camp(kind, id, name, pos) with the kind's tier")
	await _frames(40)
	_check(c != null and c.is_disabled() and c.creatures().is_empty(), "missing type: camp skipped")
	_check(CampManager.instance(self) != null, "instance still found")
	m2.queue_free()


## Informational: the skirmish's CAMP_SPOTS (12.C1) against 5.2.
func _check_skirmish_spots() -> void:
	var path := "res://scripts/world/skirmish.gd"
	var s := load(path) as Script if ResourceLoader.exists(path) else null
	if s == null:
		return
	var consts := s.get_script_constant_map()
	if not consts.has("CAMP_SPOTS"):
		print("  (skirmish.gd has no CAMP_SPOTS yet)")
		return
	var spots: Array = consts["CAMP_SPOTS"]
	var ok := spots.size() == 8
	for spot: Variant in spots:
		var d := spot as Dictionary
		var want: Dictionary = {}
		for w: Dictionary in SPOTS:
			if StringName(str(w["id"])) == StringName(str(d.get("id", ""))):
				want = w
		if want.is_empty():
			ok = false
			continue
		var p: Variant = d.get("pos")
		var pv := Vector3((p as Vector2).x, 0, (p as Vector2).y) if p is Vector2 else p as Vector3
		ok = ok and pv.is_equal_approx(want["pos"]) and StringName(str(d.get("kind", ""))) == want["kind"] \
				and is_equal_approx(float(d.get("first_spawn", -1.0)), want["first_spawn"])
	print("  skirmish CAMP_SPOTS match 5.2: %s" % ok)


# ---------------------------------------------------------------- helpers

func _camp(id: StringName) -> NeutralCamp:
	return mgr.camp(id) as NeutralCamp


func _alive(id: StringName) -> int:
	var c := _camp(id)
	return c.creatures().size() if c else -1


func _xp(id: StringName) -> int:
	var t := mgr.creature_type(id)
	return t.kill_xp if t else 0


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _has_msg(part: String) -> bool:
	for m in msgs:
		if m.contains(part):
			return true
	return false


## Sets the match clock and waits past one manager tick (0.5 s).
func _at(t: float) -> void:
	level.clock = t
	await _frames(34)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fail(what)


func _fail(what: String) -> void:
	errors.append(what)
	print("  FAIL: %s" % what)
