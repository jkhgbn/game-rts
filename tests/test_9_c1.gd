extends SceneTree
## 9.C1: Champion, ChampionType, the 4 .tres, levels / XP / loot / death drop / home rest, is_commandable,
## statuses taunted / dazed / braced / marked, Paragon, save state (docs/design/champions.md "Done when").
## Run: godot --headless --path . -s tests/test_9_c1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "9.c1"
const FAR := Vector3(300.0, 2.0, 300.0)   # away from everything on the map (instant checks only)
const REST_FRAMES := 120                  # 2 s of rest

# id: [hp, armor, dmg, range, cooldown, speed, aggro, sight, radius, height, flee,
#      greed, courage, engage, hunt, explore, guard, escort, names A / B]
const TABLE := {
	&"wayfinder": [260.0, 0.0, 13.0, 8.0, 1.1, 5.8, 9.0, 18.0, 0.45, 1.8, 0.40,
			1.0, 0.9, 10.0, 0.6, 2.0, 0.3, 0.5, "Tamsin Farrow", "Tobin Farrow"],
	&"oathwall": [520.0, 20.0, 15.0, 1.8, 1.3, 4.3, 10.0, 11.0, 0.6, 2.0, 0.20,
			0.8, 1.6, 20.0, 0.7, 0.2, 2.0, 1.0, "Garran Stoneward", "Gerda Stoneward"],
	&"coin_cutter": [300.0, 5.0, 17.0, 1.6, 0.9, 5.6, 8.0, 12.0, 0.45, 1.7, 0.35,
			1.5, 0.8, 8.0, 1.8, 0.6, 0.3, 0.3, "Sable Quint", "Silas Quint"],
	&"mender": [280.0, 5.0, 9.0, 7.0, 1.4, 4.8, 9.0, 12.0, 0.45, 1.7, 0.45,
			0.9, 0.7, 9.0, 0.4, 0.3, 0.8, 2.0, "Orla Fenwick", "Osric Fenwick"],
}

## A small self-contained world (floor, a keep, a wizard) so the test does not depend on the HUD / map
## scripts other step-9 agents are editing at the same time.
var main: Node3D
var hero: Wizard
var keep: Building
var frame := 0
var _boot := 0
var _errors: Array[String] = []
var _levels_seen := 0

# Timed checks.
var _taunted: Unit
var _taunter: Champion
var _dazed: Unit
var _rest_home: Champion
var _rest_far: Champion
var _rest_tavern: Champion
var _rest_start := {}
var _revived: Champion


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
	keep = Building.new()
	keep.building_type = BuildingType.find("fire_keep")
	keep.team = Unit.Team.PLAYER
	keep.position = Vector3.ZERO   # _initialize runs before the root is in the tree: local positions
	main.add_child(keep)
	hero = Wizard.new()
	hero.team = Unit.Team.PLAYER
	hero.position = Vector3(-200.0, 0.0, -200.0)
	main.add_child(hero)


func _process(_delta: float) -> bool:
	_boot += 1
	if _boot < 3:
		return false   # let every _ready run first
	frame += 1
	if frame == 1:
		_run_instant()
		_setup_timed()
	elif frame == 6:
		_check_taunt()
	elif frame == 30:
		_check_dazed_end()
	elif frame == 1 + REST_FRAMES:
		_check_rest()
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


# The brain / abilities (other tasks) may exist: keep them quiet so only 9.C1 rules act.
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


# ------------------------------------------------------------------ instant checks

func _run_instant() -> void:
	_check_types()
	_check_spawn_and_levels()
	_check_kill_xp()
	_check_death_drop()
	_check_statuses()
	_check_save_state()
	_check(Unit.VETERANCY_NAMES[3] == "Paragon", "VETERANCY_NAMES[3] = %s" % Unit.VETERANCY_NAMES[3])
	var vet := _unit("flame_guard", 0, FAR + Vector3(0, 0, 400))
	vet.add_xp(5000)
	_check(vet.level == 4 and vet.veterancy_name() == "Paragon", "rank 4 name %s" % vet.veterancy_name())


func _check_types() -> void:
	var all := ChampionType.all()
	_check(all.size() == 4, "ChampionType.all() = %d" % all.size())
	for id: StringName in TABLE:
		var t := ChampionType.find(id)
		if t == null:
			_check(false, "missing data/champions/%s.tres" % id)
			continue
		var r: Array = TABLE[id]
		var got := [t.max_hp, t.armor, t.attack_damage, t.attack_range, t.attack_cooldown, t.move_speed,
				t.aggro_range, t.sight_radius, t.radius, t.body_height, t.flee_pct,
				t.get_trait(&"greed"), t.get_trait(&"courage"), t.get_trait(&"engage_radius"),
				t.affinity_for(&"hunt"), t.affinity_for(&"explore"), t.affinity_for(&"guard"),
				t.affinity_for(&"escort")]
		for i in got.size():
			_check(_near(float(got[i]), float(r[i])), "%s field %d = %s (want %s)" % [id, i, got[i], r[i]])
		_check(t.names.size() == 2 and t.names[0] == r[18] and t.names[1] == r[19], "%s names" % id)
		_check(t.pop == 2 and _near(t.growth_pct, 0.08) and _near(t.bounty_threshold, 10.0), "%s pop/growth" % id)
		_check(t.ability_ids.size() == 3, "%s 3 abilities" % id)
		_check(t.wishlist.size() == 7, "%s wishlist size" % id)
		for item_id in t.wishlist:
			_check(ItemType.find(item_id) != null, "%s wishlist item %s exists" % [id, item_id])
		_check(t.personality_line != "" and t.title.begins_with("the "), "%s texts" % id)
		for trig: StringName in ChampionType.BARK_CHANCES:
			_check(t.bark_for(trig) != "", "%s bark %s" % [id, trig])
		# 9.C10 plugged the models (was: left empty until 9.C10).
		_check(t.model_scene != null and t.model_scene.resource_path == "res://art/units/champions/%s/%s.tscn" % [id, id],
				"%s model_scene = its champion model (9.C10)" % id)
	_check(ChampionType.find("Coin-Cutter") == ChampionType.find(&"coin_cutter"), "find by name")
	_check(ChampionType.find(&"nope") == null, "unknown id -> null")
	var way := ChampionType.find(&"wayfinder")
	_check(way.projectile_color.is_equal_approx(Color(1.0, 0.8, 0.4)), "wayfinder projectile colour")
	_check(ChampionType.find(&"mender").projectile_color.is_equal_approx(Color(0.5, 1.0, 0.6)), "mender projectile colour")
	_check(ChampionType.find(&"coin_cutter").bark_for(&"hired") == "Pay me and I'll love you. Briefly.", "bark text")


func _check_spawn_and_levels() -> void:
	var c := _champion(&"coin_cutter", 0, FAR)
	_check(_near(c.max_hp, 300.0) and _near(c.hp, 300.0), "coin-cutter 300 hp (%s)" % c.max_hp)
	_check(_near(c.get_stat(&"armor"), 5.0), "armor 5 (%s)" % c.get_stat(&"armor"))
	_check(_near(c.attack_damage, 17.0), "17 dmg (%s)" % c.attack_damage)
	_check(_near(c.attack_cooldown, 0.9) and _near(c.attack_range, 1.6) and _near(c.move_speed, 5.6), "cd/range/speed")
	_check(c.display_name == "Sable Quint" and c.unit_name == "Sable Quint", "name A %s" % c.display_name)
	_check(c.full_name() == "Sable Quint, the Coin-Cutter", "full name %s" % c.full_name())
	_check(c.level == 1 and c.xp == 0 and c.purse == 50 and c.intent == &"Idle", "fresh champion state")
	_check(c.is_in_group(&"units") and c.is_in_group(&"champions") and not c.is_in_group(&"heroes"), "groups")
	_check(not c.is_commandable(), "champion is_commandable false")
	_check(c.is_in_group(&"fog_sources") and _near(c.sight_radius, 12.0), "fog source, sight 12")
	var shade := _unit("shade", 1, FAR + Vector3(0, 0, 3))
	_check(shade.is_commandable() and hero.is_commandable(), "soldier / wizard is_commandable true")
	_check(c.inventory != null and c.inventory.name == "Inventory" and c.get_node_or_null(^"Inventory") == c.inventory,
			"Inventory child")
	if c.inventory:
		var sc: Variant = c.inventory.get(&"slot_count")
		var ac: Variant = c.inventory.get(&"artifact_count")
		_check(sc == null or int(sc) == 4, "4 item slots (%s)" % sc)
		_check(ac == null or int(ac) == 0, "0 artifact slots (%s)" % ac)
	_check(_near(c.power(), 200.0), "power L1 = 200 (%s)" % c.power())
	var v_b := _champion(&"coin_cutter", 1, FAR + Vector3(0, 0, 6), 1)
	_check(v_b.display_name == "Silas Quint", "name B %s" % v_b.display_name)

	c.level_changed.connect(func(_u: Unit, _l: int) -> void: _levels_seen += 1)
	c.hp = 200.0
	# Step 11: the level-2 class draw would change the weapon; take Two-Hand up front (24 dmg / 1.55 s, no
	# stat change) so the level numbers stay exact. XP table x1.25 (skills-rework.md 9.2).
	c.set_champion_class(&"two_hand")
	c.add_xp(190)
	_check(c.level == 2, "190 xp -> level 2 (%d)" % c.level)
	_check(_near(c.max_hp, 324.0), "L2 324 hp (%s)" % c.max_hp)
	_check(_near(c.attack_damage, 24.0 * 1.08), "L2 25.9 dmg (%s)" % c.attack_damage)
	_check(_near(c.hp, 224.0), "healed by 24 (%s)" % c.hp)
	_check(c.xp == 0 and c.xp_to_next() == 310 and c.total_xp == 190, "L2 bar %d / %d" % [c.xp, c.xp_to_next()])
	_check(_near(c.get_stat(&"armor"), 5.0) and _near(c.attack_cooldown, 1.55), "armor / cooldown never grow")
	c.add_xp(1999)
	_check(c.level == 5, "2189 xp -> level 5 (%d)" % c.level)
	c.add_xp(1)
	_check(c.level == 6 and c.xp_to_next() == 0 and c.is_max_level(), "2190 xp -> level 6 MAX (%d)" % c.level)
	_check(_near(c.max_hp, 420.0) and _near(c.attack_damage, 24.0 * 1.4), "L6 420 hp / 33.6 dmg (%s / %s)"
			% [c.max_hp, c.attack_damage])
	c.add_xp(500)
	_check(c.level == 6 and c.total_xp == 2190 and c.xp == 0, "no XP past MAX (%d)" % c.total_xp)
	_check(_levels_seen == 5, "level_changed once per level (%d)" % _levels_seen)
	_check(c.get_node_or_null(^"Chevrons") == null, "no veterancy chevrons")
	_check(_near(c.power(), 150.0 + 50.0 * 6.0 + 20.0 * 3.0), "power L6 with 3 class skills (%s)" % c.power())
	_check(_near(c.growth_mult(), 1.4), "growth_mult L6")


func _check_kill_xp() -> void:
	var base := FAR + Vector3(60, 0, 0)
	var k := _champion(&"coin_cutter", 0, base + Vector3(1, 0, 0))
	var victim := _unit("shade", 1, base)
	victim.take_damage(10000.0, k)
	_check(not victim.is_alive(), "shade died")
	_check(k.xp == 40 and k.total_xp == 40, "killing blow on a Shade = 40 XP (%d)" % k.xp)
	_check(k.purse == 60, "loot 10 purse (%d)" % k.purse)
	# Team kill: a Flame Guard kills a Shade; champions at 5 m / 10 m / 13 m.
	var at := base + Vector3(0, 0, 40)
	var near5 := _champion(&"oathwall", 0, at + Vector3(5, 0, 0))
	var near10 := _champion(&"mender", 0, at + Vector3(0, 0, 10))
	var far13 := _champion(&"wayfinder", 0, at + Vector3(-13, 0, 0))
	var enemy_ch := _champion(&"wayfinder", 1, at + Vector3(0, 0, -3))
	var guard := _unit("flame_guard", 0, at + Vector3(1, 0, 0))
	var victim2 := _unit("shade", 1, at)
	victim2.take_damage(10000.0, guard)
	_check(near10.xp == 10, "team kill 10 m -> 10 XP (%d)" % near10.xp)
	_check(far13.xp == 0, "team kill 13 m -> 0 XP (%d)" % far13.xp)
	_check(near5.xp == 10, "5 m -> 10 XP, no extra veterancy share (%d)" % near5.xp)
	_check(enemy_ch.xp == 0, "enemy champion gets nothing (%d)" % enemy_ch.xp)
	_check(near10.purse == 50, "no loot on a team kill")
	_check(guard.xp == 40, "the soldier still gets its 40 (%d)" % guard.xp)


func _check_death_drop() -> void:
	var base := FAR + Vector3(0, 0, 120)
	var bank := EssenceBank.for_team(0)
	bank.trickle_enabled = false
	# Killed by a soldier: 30 % of 200 = 60 to the killer's bank (plus the normal kill essence).
	var v := _champion(&"coin_cutter", 1, base)
	v.add_purse(150)
	_check(v.purse == 200, "purse 200")
	_check(Unit.kill_xp_value(v) == 125 and Wizard.xp_value_of(v) == 125, "L1 champion worth 125 XP")
	var guard := _unit("flame_guard", 0, base + Vector3(1, 0, 0))
	var before := bank.essence
	var events_bonus := EssenceBank.kill_essence(125) if root.has_node(^"Events") else 0
	v.take_damage(100000.0, guard)
	_check(not v.is_alive(), "champion died")
	_check(v.purse == 140, "kept 70 %% of the purse (%d)" % v.purse)
	_check(bank.essence - before == 60 + events_bonus, "bank got %d (want 60 + %d)" % [bank.essence - before, events_bonus])
	_check(guard.xp == 125, "a soldier's killing blow on an L1 champion = 125 XP (%d)" % guard.xp)
	_check(v.intent == &"Fallen" and v.is_in_group(&"champions") and not v.is_in_group(&"units"), "fallen state")
	_check(is_instance_valid(v) and v.is_inside_tree(), "a fallen champion stays in the tree")
	# Killed by a champion: 30 % of the purse to its purse, + loot 25 % of 125.
	var v2 := _champion(&"mender", 1, base + Vector3(0, 0, 10))
	v2.add_purse(50)   # 100
	var k := _champion(&"oathwall", 0, base + Vector3(1, 0, 10))
	v2.take_damage(100000.0, k)
	_check(v2.purse == 70 and k.purse == 50 + 30 + 31, "drop to the killer's purse (%d / %d)" % [v2.purse, k.purse])
	_check(k.xp == 125, "champion kills champion: 125 XP (%d)" % k.xp)
	# Value grows with level: L6 = 250.
	var v6 := _champion(&"mender", 1, base + Vector3(0, 0, 20))
	v6.add_xp(2190)
	_check(Unit.kill_xp_value(v6) == 250 and Wizard.xp_value_of(v6) == 250, "L6 champion worth 250")
	# Revive keeps level / XP / purse, full HP.
	v2.add_xp(200)
	v2.respawn(base + Vector3(0, 0, 30))
	_check(v2.is_alive() and _near(v2.hp, v2.max_hp) and v2.is_in_group(&"units") and v2.visible, "respawned")
	_check(v2.level == 2 and v2.purse == 70 and v2.intent == &"Idle", "respawn keeps level / purse")
	_revived = v2


func _check_statuses() -> void:
	var base := FAR + Vector3(0, 0, 200)
	# marked x1.15, braced x0.7 (Shade: armor 0)
	var s := _unit("shade", 1, base)
	s.apply_status(&"marked", 6.0)
	var hp0 := s.hp
	s.take_damage(10.0, null)
	_check(_near(hp0 - s.hp, 11.5), "marked Shade takes 11.5 (%s)" % (hp0 - s.hp))
	var s2 := _unit("shade", 1, base + Vector3(0, 0, 3))
	s2.apply_status(&"braced", 6.0)
	hp0 = s2.hp
	s2.take_damage(10.0, null)
	_check(_near(hp0 - s2.hp, 7.0), "braced Shade takes 7 (%s)" % (hp0 - s2.hp))
	# dazed: no move, no act; no immunity after
	_dazed = _unit("shade", 1, base + Vector3(0, 0, 6))
	_dazed.apply_status(&"dazed", 0.1)
	_check(_dazed.has_status(&"dazed") and not _dazed.can_move() and not _dazed.can_act(), "dazed: no move / act")
	# heroes: crowd control lasts half as long on champions (and wizards)
	var ch := _champion(&"oathwall", 0, base + Vector3(10, 0, 0))
	ch.apply_status(&"rooted", 1.5)
	_check(_near(ch.status_time_left(&"rooted"), 0.75), "rooted 0.75 s on a champion (%s)" % ch.status_time_left(&"rooted"))
	ch.apply_status(&"dazed", 0.8)
	_check(_near(ch.status_time_left(&"dazed"), 0.4), "dazed 0.4 s on a champion")
	ch.apply_status(&"marked", 6.0)
	_check(_near(ch.status_time_left(&"marked"), 6.0), "marked is not crowd control")
	var s3 := _unit("shade", 1, base + Vector3(0, 0, 9))
	s3.apply_status(&"dazed", 0.8)
	_check(_near(s3.status_time_left(&"dazed"), 0.8), "dazed 0.8 s on a soldier")
	# taunted: a source that is not an enemy refuses it; no source = status only (taunted_by set later);
	# wizards immune
	var s4 := _unit("shade", 1, base + Vector3(0, 0, 12))
	var enemy_shade := _unit("shade", 1, base + Vector3(0, 0, 15))
	s4.apply_status(&"taunted", 3.0, false, enemy_shade)
	_check(not s4.has_status(&"taunted"), "taunt by an ally is refused")
	s4.apply_status(&"taunted", 3.0)
	_check(s4.has_status(&"taunted") and s4.taunt_source() == null, "taunt without a source: status only")
	s4.taunted_by = ch
	_check(s4.taunt_source() == ch, "taunted_by written after apply_status")
	hero.apply_status(&"taunted", 3.0, false, enemy_shade)
	_check(not hero.has_status(&"taunted"), "wizards are immune to taunt")
	var hide := _unit("shade", 1, base + Vector3(0, 0, 18))
	hide.hide_from_auto_target(3.0)
	_check(hide.is_hidden_from_auto_target(), "hide_from_auto_target")


func _check_save_state() -> void:
	var base := FAR + Vector3(0, 0, 260)
	var s := _champion(&"mender", 0, base, 1)
	s.add_xp(600)   # level 3, 100 into the bar (step 11 table: 500 for level 3)
	s.add_purse(73)
	s.inventory.add_item(ItemType.find(&"ember_shard"))
	s.inventory.add_item(ItemType.find(&"ironbark_plate"))
	s.inventory.add_item(ItemType.find(&"ember_draught"), 2)
	s.hp = s.max_hp * 0.5
	var d: Dictionary = JSON.parse_string(JSON.stringify(s.get_save_state()))
	_check(int(d["level"]) == 3 and int(d["xp"]) == 100 and int(d["purse"]) == 123, "save state content %s" % d)
	# Restore on a champion in the tree...
	var r := _champion(&"mender", 0, base + Vector3(0, 0, 4))
	r.apply_save_state(d)
	_same(s, r, "in tree")
	_check(_near(r.hp, r.max_hp * 0.5, 0.6), "hp ratio restored (%s / %s)" % [r.hp, r.max_hp])
	# ... and on one built from nothing before it enters the tree.
	var fresh := Champion.new()
	fresh.apply_save_state(d)
	fresh.team = Unit.Team.PLAYER
	main.add_child(fresh)
	fresh.global_position = base + Vector3(0, 0, 8)
	_quiet(fresh)
	_same(s, fresh, "before tree")
	_check(fresh.type_id() == &"mender" and fresh.display_name == "Osric Fenwick", "type / variant restored")


func _same(a: Champion, b: Champion, what: String) -> void:
	_check(b.level == a.level and b.xp == a.xp and b.total_xp == a.total_xp, "%s: level / xp %d %d %d"
			% [what, b.level, b.xp, b.total_xp])
	_check(b.purse == a.purse, "%s: purse %d" % [what, b.purse])
	_check(_near(b.max_hp, a.max_hp) and _near(b.attack_damage, a.attack_damage), "%s: stats %s / %s"
			% [what, b.max_hp, b.attack_damage])
	_check(_near(b.get_stat(&"armor"), a.get_stat(&"armor")), "%s: item armor" % what)
	var ia: Array = a.get_save_state()["items"]
	var ib: Array = b.get_save_state()["items"]
	_check(ia.size() == 3 and str(ia) == str(ib), "%s: items %s vs %s" % [what, ib, ia])


# ------------------------------------------------------------------ timed checks

func _setup_timed() -> void:
	# Taunt: a Shade next to a Flame Guard is taunted by an Oathwall 4 m away.
	var base := FAR + Vector3(-80, 0, 0)
	_taunter = _champion(&"oathwall", 0, base + Vector3(4, 0, 0))
	_unit("flame_guard", 0, base + Vector3(1, 0, 0))
	_taunted = _unit("shade", 1, base)
	_taunted.apply_status(&"taunted", 3.0, false, _taunter)
	_taunted.command_move(base + Vector3(-20, 0, 0))
	# Rest: 10 m from the keep heals, 25 m does not; 2 m from a tavern door heals.
	_rest_home = _champion(&"coin_cutter", 0, keep.global_position + Vector3(10, 0, 0))
	_rest_far = _champion(&"coin_cutter", 0, keep.global_position + Vector3(20, 0, 15))
	var tavern := Node3D.new()
	tavern.name = "TavernStub"
	tavern.add_to_group(&"taverns")
	main.add_child(tavern)
	tavern.global_position = Vector3(-45, 0, 0)   # door (-36, 0, 0)
	_rest_tavern = _champion(&"oathwall", 1, Vector3(-34, 0, 0))
	for ch: Champion in [_rest_home, _rest_far, _rest_tavern]:
		ch.hp = ch.max_hp * 0.5
		_rest_start[ch] = ch.hp
	_check(_rest_home.is_at_rest_spot() and not _rest_far.is_at_rest_spot() and _rest_tavern.is_at_rest_spot(),
			"is_at_rest_spot")


func _check_taunt() -> void:
	_check(_taunted.has_status(&"taunted") and _taunted.attack_target == _taunter
			and _taunted.taunt_source() == _taunter, "taunted Shade attacks the Oathwall only")


func _check_dazed_end() -> void:
	_check(not _dazed.has_status(&"dazed") and _dazed.can_act() and _dazed.can_move(), "dazed ended")
	_dazed.apply_status(&"dazed", 0.8)
	_check(_dazed.has_status(&"dazed"), "no immunity after dazed")


func _check_rest() -> void:
	var secs := float(REST_FRAMES - 1) / 60.0
	for ch: Champion in [_rest_home, _rest_tavern]:
		var gained := ch.hp - float(_rest_start[ch])
		var want := ch.max_hp * 0.02 * secs
		_check(absf(gained - want) <= ch.max_hp * 0.006, "%s rest gained %.1f (want %.1f)" % [ch.display_name, gained, want])
	_check(_near(_rest_far.hp, float(_rest_start[_rest_far])), "no rest 25 m from the keep (%s)" % _rest_far.hp)
