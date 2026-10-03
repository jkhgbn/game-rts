extends SceneTree
## Tasks M9.S1 / M9.S2 (docs/design/mission-02.md "Acceptance checks"): Glasswater Mere's map and start state, the
## Heartfrost rules, a floe break, the blizzard on both teams, the dig rate / relief, then Vessa's death = defeat.
## Flags: Pell freed, outpost standing (a flag override, the player's save is never read).
## Run:  godot --headless --path . -s tests/test_m9_s1.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "m9.s1"
const SCENE := "res://missions/mission_02.tscn"

var h := MissionHarness.new()
var main: Node
var _shade: Unit
var _fg: Unit
var _wait := 0
var _hp0 := 0.0


func _initialize() -> void:
	h.task_id = TASK_ID
	main = h.open(self, SCENE, {"difficulty": 1, "set": {
		"flag_override": {"m1_peddler_freed": true, "m1_outpost_burned": false},
		"campaign_save_path": "user://test_m9_none.json"}})
	h.steps.add("bake settles", func() -> bool:
		_wait += 1
		return _wait > 30, 100)
	h.steps.add("map", _check_map, 10)
	h.steps.add("start state", _check_start, 10)
	h.steps.add("lane path through the SW gap", _check_lane_path, 10)
	h.steps.add("heartfrost: who may damage it", _check_heartfrost_filter, 10)
	h.steps.add("heartfrost: regen after 5 s", _check_regen, 600)
	h.steps.add("an Ash Hurler's real attack melts it", _hurler_attack, 10)
	h.steps.add("the shots land", _hurler_hits, 900)
	h.steps.add("floe F3 breaks under 4 Fireballs", _break_f3, 10)
	h.steps.add("open water: lane goes around", _check_open_water_path, 600)
	h.steps.add("refreeze", _refreeze_f3, 10)
	h.steps.add("refrozen path", _check_refrozen, 600)
	h.steps.add("blizzard on both teams", _check_blizzard, 10)
	h.steps.add("dig starts at 2:00", _skip_to_dig, 10)
	h.steps.add("dig rate", _check_dig_rate, 400)
	h.steps.add("relief thrall", _relief, 10)
	h.steps.add("relief arrives", func() -> bool: return int(main.get(&"relief_sent")) == 1 and \
			int(main.call(&"living_dig_thralls")) == 4, 300)
	h.steps.add("no relief once the Dusk Keep falls", _keep_falls, 10)
	h.steps.add("no relief after the keep", _no_relief, 200)
	h.steps.add("vessa falls", _vessa_falls, 10)
	h.steps.add("defeat", func() -> bool: return h.ended == 0, 600)


func _process(_d: float) -> bool:
	return h.tick()


func _check_map() -> bool:
	var banks := get_nodes_in_group(&"snowbanks").size()
	h.check(banks == 28, "28 snowbanks (got %d)" % banks)
	var nodes: Dictionary = main.get(&"crystal_nodes")
	var want := {&"m2_fire_a": 1500, &"m2_fire_b": 1500, &"m2_west": 2000, &"m2_south": 1500}
	for id: StringName in want:
		h.check(nodes.has(id) and int((nodes[id] as Node).get(&"crystals_left")) == want[id], "node %s" % id)
	var grid: Object = main.get(&"build_grid")
	var hearth: Resource = BuildingType.find("fire_hearth")
	h.check(String(grid.call(&"check", hearth, Vector3(14.0, 0.0, 14.0), 0)) == GlasswaterLake.MSG_NO_BUILD,
			"no building at r <= 23 (got '%s')" % grid.call(&"check", hearth, Vector3(14.0, 0.0, 14.0), 0))
	var hf: Node3D = main.get(&"heartfrost")
	h.check(int(hf.get(&"team")) == Unit.Team.NEUTRAL and not hf.is_in_group(&"units") \
			and not hf.is_in_group(&"buildings") and hf.is_in_group(&"scripted"), "heartfrost NEUTRAL, scripted only")
	h.check(is_equal_approx(float(hf.get(&"max_hp")), 1500.0), "heartfrost 1 500 HP on normal")
	var dusk: Node = main.get(&"shadow_keep")
	h.check(is_equal_approx(float(dusk.get(&"max_hp")), 1800.0) and int(dusk.get(&"team")) == Unit.Team.ENEMY,
			"Dusk Keep ENEMY 1 800 HP")
	var sentinels: Array = main.get(&"sentinels")
	h.check(sentinels.size() == 2, "2 sentinels on normal")
	for s: Node in sentinels:
		h.check(int(s.get(&"team")) == Unit.Team.NEUTRAL and bool(main.call(&"is_dormant", s)), "sentinel NEUTRAL dormant")
	for n in get_nodes_in_group(&"units") + get_nodes_in_group(&"buildings"):
		var t: Variant = n.get(&"team")
		if t != null and int(t) == Unit.Team.ENEMY:
			var u := n as Unit
			var b := n as Building
			var faction: StringName = u.unit_type.faction if u and u.unit_type else \
					(b.building_type.faction if b and b.building_type else &"")
			h.check(faction != &"ice", "no Ice ENEMY thing (%s)" % n.name)
	h.check(main.get(&"pell") != null, "Pell stands at his cart (flag true)")
	var guards: Dictionary = main.get(&"guard_groups")
	for w: Node in guards[&"G4"]:
		h.check(int(w.get(&"team")) == Unit.Team.NEUTRAL, "G4 wardens NEUTRAL")
	var walkable_check := [Vector3(-36, 0, 36), Vector3(-27, 0, 45), Vector3(-50, 0, 10), Vector3(4, 0, 50),
			Vector3(-46, 0, -14), Vector3(24, 0, 44), Vector3(-14, 0, -46), Vector3(-32, 0, 3), Vector3(-12, 0, 32),
			Vector3(32, 0, 10), Vector3(30, 0, -30), Vector3(-56, 0, -30), Vector3(56, 0, -56)]
	var map := (main as Node3D).get_world_3d().navigation_map
	for p: Vector3 in walkable_check:
		var q := NavigationServer3D.map_get_closest_point(map, p)
		h.check(Vector2(q.x - p.x, q.z - p.z).length() < 3.5, "walkable near %s (closest %s)" % [p, q])
	return true


func _check_start() -> bool:
	var hero: Wizard = main.get(&"hero")
	h.check(hero.level == 2, "Vessa level 2 (got %d)" % hero.level)
	h.check(hero.spell_points == 1, "1 spell point (got %d)" % hero.spell_points)
	var eco := Economy.for_team(Unit.Team.PLAYER)
	h.check(eco.crystals == 300, "300 crystals (got %d)" % eco.crystals)
	print("  pop %d / %d" % [eco.pop_used, eco.pop_cap])
	h.check(eco.pop_used == 15, "pop used 15 (got %d)" % eco.pop_used)
	var inv := ItemDrops.inventory_of(hero) as Inventory
	h.check(inv != null and inv.find_slot(&"ember_crown") == Inventory.ARTIFACT_SLOT, "Ember Crown in artifact slot 1")
	var hall: Node = main.get(&"ember_hall")
	var trains: Array = (hall.get(&"building_type") as BuildingType).trains
	var ids: Array = trains.map(func(t: UnitType) -> StringName: return t.id)
	h.check(ids == [&"flame_guard", &"ember_archer", &"blaze_rider", &"ash_hurler", &"pyre_adept", &"cinder_arbalest"],
			"hall Z X C V B N = %s" % str(ids))
	h.check(main.get(&"tier_system") != null, "tiers on (Stronghold)")
	var malrik: Wizard = main.get(&"shadow_hero")
	h.check(malrik.level == 4 and malrik.is_in_group(&"scripted"), "Malrik L4 scripted (L%d)" % malrik.level)
	h.check(h.dialogue_log.size() >= 2 and h.dialogue_log[0].begins_with("narrator: Glasswater"), "L1 / L2 at E1")
	return true


func _path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var map := (main as Node3D).get_world_3d().navigation_map
	return NavigationServer3D.map_get_path(map, from, to, true)


static func _passes_near(path: PackedVector3Array, p: Vector3, r: float) -> bool:
	for i in range(1, path.size()):
		var a := Vector2(path[i - 1].x, path[i - 1].z)
		var b := Vector2(path[i].x, path[i].z)
		var c := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), a, b)
		if c.distance_to(Vector2(p.x, p.z)) <= r:
			return true
	return false


func _check_lane_path() -> bool:
	var path := _path(Vector3(-40, 0, 40), Vector3(0, 0, 3.5))
	h.check(path.size() > 1 and Vector2(path[-1].x, path[-1].z).distance_to(Vector2(0, 3.5)) < 2.0, "path to the lake")
	h.check(_passes_near(path, Mission02.gap_center(&"sw"), 5.0), "path passes the SW gap")
	return true


func _check_heartfrost_filter() -> bool:
	var hf: Heartfrost = main.get(&"heartfrost")
	_shade = main.call(&"make_unit", "shade")
	main.call(&"_spawn", _shade, Unit.Team.ENEMY, Vector3(-12, 0, 12))
	_fg = main.call(&"make_unit", "flame_guard")
	main.call(&"_spawn", _fg, Unit.Team.PLAYER, Vector3(-30, 0, 30))
	var hp0 := hf.hp
	hf.take_damage(100.0, _shade)
	hf.take_damage(100.0, _fg)
	h.check(is_equal_approx(hf.hp, hp0), "Shade / Flame Guard never damage it")
	main.call(&"order_on_heartfrost", [_fg])
	h.check(_fg.attack_target == null, "a Flame Guard's right-click is a move")
	h.check(bool(main.get(&"_heartfrost_msg_shown")), "the one-time message")
	hf.take_damage(100.0, main.get(&"hero"))
	h.check(is_equal_approx(hf.hp, hp0 - 100.0), "Vessa damages it")
	var hurler: Unit = main.call(&"make_unit", "ash_hurler")
	main.call(&"_spawn", hurler, Unit.Team.PLAYER, Vector3(-30, 0, 31))
	hf.take_damage(50.0, hurler)
	h.check(is_equal_approx(hf.hp, hp0 - 150.0), "an Ash Hurler damages it")
	main.call(&"order_on_heartfrost", [hurler])
	h.check(hurler.attack_target == hf, "an Ash Hurler's right-click attacks it")
	hurler.command_stop()
	hurler.queue_free()
	_hp0 = hf.hp
	return true


func _check_regen() -> bool:
	var hf: Heartfrost = main.get(&"heartfrost")
	if hf.since_fire_damage < 4.8:
		h.check(is_equal_approx(hf.hp, _hp0), "no regen before 5 s (%.1f s)" % hf.since_fire_damage)
		return false
	if hf.since_fire_damage < 6.0:
		return false
	h.check(hf.hp > _hp0 + 10.0, "regen after 5 s (%.0f -> %.0f)" % [_hp0, hf.hp])
	var before := hf.hp
	hf.take_damage(1.0, main.get(&"hero"))
	h.check(hf.since_fire_damage == 0.0 and hf.hp < before, "a hit stops the regen")
	return true


var _hurler: Unit


func _hurler_attack() -> bool:
	var hf: Heartfrost = main.get(&"heartfrost")
	_hurler = main.call(&"make_unit", "ash_hurler")
	main.call(&"_spawn", _hurler, Unit.Team.PLAYER, Vector3(-5.0, 0.0, 9.0))
	MissionHarness.immortal(_hurler)
	main.call(&"order_on_heartfrost", [_hurler])
	_hp0 = hf.hp
	return true


func _hurler_hits() -> bool:
	var hf: Heartfrost = main.get(&"heartfrost")
	if hf.hp > _hp0 - 40.0:
		return false
	_hurler.command_stop()
	_hurler.queue_free()
	return true


func _break_f3() -> bool:
	var lake: GlasswaterLake = main.get(&"lake")
	var at := Vector3(cos(deg_to_rad(135.0)) * 14.0, 0.0, sin(deg_to_rad(135.0)) * 14.0)
	MissionHarness.put(_shade, at)
	_shade.hp = _shade.max_hp
	var hp0 := _shade.hp
	h.check(GlasswaterLake.floe_at(at) == 3, "the Shade stands on F3")
	for i in 3:
		main.call(&"_fireball_lands", at + Vector3(0.5 * i, 0.0, 0.0))
	h.check(not lake.is_open(3) and is_equal_approx(lake.cracks[3], 3.0), "3 Fireballs = 3 cracks")
	main.call(&"_fireball_lands", at)
	h.check(lake.is_open(3), "the 4th Fireball breaks F3")
	h.check(hp0 - _shade.hp >= 60.0, "the Shade takes the break damage (%.0f)" % (hp0 - _shade.hp))
	h.check(GlasswaterLake.floe_at(_shade.global_position) != 3, "the Shade ends outside the hole")
	h.check(_shade.has_status(&"chill"), "chill 4 s")
	h.check(main.call(&"has_fired", &"E7") and h.dialogue_log.any(func(l: String) -> bool: return l.contains("Thin ice")),
			"E7: L7")
	_wait = 0
	return true


func _check_open_water_path() -> bool:
	_wait += 1
	if _wait < 120:   # the rebake runs on a thread
		return false
	var lake: GlasswaterLake = main.get(&"lake")
	h.check(lake.is_open(3), "F3 is open water")
	var path := _path(Vector3(-40, 0, 40), Vector3(0, 0, 3.5))
	var crossing := false
	for p in path:
		if GlasswaterLake.floe_at(p) == 3 and Vector2(p.x, p.z).length() < 20.0:
			crossing = true
	h.check(not crossing, "the lane path goes around open F3")
	return true


func _refreeze_f3() -> bool:
	var lake: GlasswaterLake = main.get(&"lake")
	lake.open_left[3] = 0.05
	_wait = 0
	return true


func _check_refrozen() -> bool:
	_wait += 1
	if _wait < 120:
		return false
	var lake: GlasswaterLake = main.get(&"lake")
	h.check(not lake.is_open(3) and lake.cracks[3] == 0.0, "F3 refrozen, cracks 0")
	var path := _path(Vector3(-25, 0, 25), Vector3(0, 0, 3.5))
	var on_f3 := false
	for p in path:
		if GlasswaterLake.floe_at(p) == 3:
			on_f3 = true
	h.check(on_f3, "the lane crosses F3 again")
	return true


func _check_blizzard() -> bool:
	var bz: MissionBlizzard = main.get(&"blizzard")
	var fog := FogOfWar.find()
	bz.set_blowing(true)
	h.check(fog.sight_scale == [0.5, 0.5], "blizzard: both teams x 0.5 (%s)" % str(fog.sight_scale))
	bz.set_blowing(false)
	h.check(fog.sight_scale == [1.0, 1.0], "blizzard off: x 1")
	return true


func _skip_to_dig() -> bool:
	MissionHarness.skip_time(main, 121.0 - float(main.call(&"mission_time")))
	_wait = 0
	return true


func _check_dig_rate() -> bool:
	if not bool(main.get(&"dig_active")):
		return false
	_wait += 1
	if _wait < 60 * 4:
		return false
	var rate := float(main.call(&"dig_rate", 4))
	h.check(is_equal_approx(rate, 0.08), "0.02 %% / s per Thrall x 4 (got %.3f)" % rate)
	h.check(is_equal_approx(120.0 + 100.0 / rate, 1370.0), "100 %% at 22:50 with 4 Thralls from 2:00")
	var d := float(main.get(&"dig"))
	h.check(d > 0.2 and d < 0.5, "dig after ~4 s = %.3f %%" % d)
	h.check(h.saw("obj_dig", "active") and h.saw("sec_dig", "active"), "obj_dig / sec_dig at E2")
	h.check(h.dialogue_log.any(func(l: String) -> bool: return l.begins_with("torvald: Two children")), "L3 at E2")
	return true


func _relief() -> bool:
	var thralls: Array = main.get(&"dig_thralls")
	MissionHarness.kill([thralls[0]])
	main.set(&"_relief_left", 0.05)
	return true


func _keep_falls() -> bool:
	MissionHarness.kill([main.get(&"shadow_keep")])
	var thralls: Array = main.get(&"dig_thralls")
	MissionHarness.kill([thralls[1]])
	main.set(&"_relief_left", 0.05)
	_wait = 0
	return true


func _no_relief() -> bool:
	_wait += 1
	if _wait < 120:
		return false
	h.check(int(main.get(&"relief_sent")) == 1, "no relief after the Dusk Keep falls")
	h.check(main.call(&"respawn_point", Unit.Team.ENEMY) == Mission02.FALLBACK_SPAWN, "Malrik respawns at (56, -56)")
	return true


func _vessa_falls() -> bool:
	h.protect_hero = false
	MissionHarness.kill([main.get(&"hero")])
	return true
