extends SceneTree
## Task 12.C4: the 5 camp creature .tres + the 8 epic beast .tres (map-fill.md 5.1 / 5.5) and CreatureAbilities
## (scripts/units/creature_abilities.gd), in a small world: a flat ground, a hand-made navmesh x -60..36 / z -60..60,
## a stub RiverSystem (group "river": deep water for 20 <= x <= 24) and a stub MapFillVfx (group "mapfill_vfx").
## Checks:
## - every .tres carries the numbers of 5.1 / 5.5 (HP, armor, damage, range, cooldown, speed, aggro, sight, radius,
##   height, kill_xp, faction neutral, neutral_leash, model_scene / model_path), Unit.kill_xp_value 25 / 30 / 50 / 12 / 160;
## - defaults (abilities_for, attach once, Mirefang amphibious), the ids 12.C11 passes;
## - Spore Burst: 20 damage r 3 + marked 4 s at the target, 0.46 s after the cast, every 10 s on autocast;
## - Antler Sweep: only with 2+ enemies within 3 m, 35 each, every 8 s; a Bristleback stays in its leash;
## - Gore Charge (6-14 m, 45 + dazed 0.8 on the target, 20 on the path; Scarback 45 + dazed 1.2 on the path), stops
##   before water and at the navmesh edge; Bristle Hide 4 per melee hit only;
## - Gale Swoop (the cluster, 40 r 2.5 + dazed 0.5), Shrieking Dive (marked 5 s), Updraft (once, at 40 %: shroud,
##   +15 % over 4 s, flies to the nest), Pounce (5-10 m, 35 + rooted 0.8, Moonpelt cd 6, refused onto water),
##   Hamstring (-25 % speed 3 s, outlives the wolf), Maul (70 + marked 5 s), Rending Roar (at 50 %: dazed 1.0 / 0.5 on
##   heroes; Elder also taunts non-heroes 3 s), enrage below 30 % (cooldown x0.7).
## Run:  godot --headless --path . -s tests/test_12_c4.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "12.C4"
const AB_PATH := "res://scripts/units/creature_abilities.gd"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const N := 2   # Unit.Team.NEUTRAL
const NAV_X1 := 36.0
const VFX_SRC := "extends Node3D\nvar calls: Array = []\nfunc play(id: StringName, at: Vector3, target: Variant) -> void:\n\tcalls.append([id, at, target])\n"
const RIVER_SRC := "extends Node3D\nfunc is_water(p: Vector3) -> bool:\n\treturn p.x >= 20.0 and p.x <= 24.0\n"
const STAG_PATH := "res://art/units/neutral/hollow_stag/hollow_stag.tscn"

## id: [hp, armor, dmg, range, cd, speed, aggro, sight, radius, height, kill_xp, leash, model path]
const TYPES := {
	&"bristleback": [200.0, 5.0, 11.0, 1.4, 1.2, 4.6, 6.0, 8.0, 0.55, 1.1, 25, true,
			"res://art/units/neutral/bristleback/bristleback.tscn"],
	&"mirefang": [190.0, 0.0, 10.0, 1.3, 0.9, 5.0, 6.0, 8.0, 0.45, 0.8, 30, true,
			"res://art/units/neutral/mirefang/mirefang.tscn"],
	&"gloomcap_elder": [420.0, 5.0, 14.0, 6.0, 1.6, 3.2, 7.0, 9.0, 0.6, 1.9, 50, true,
			"res://art/units/neutral/gloomcap/gloomcap_elder.tscn"],
	&"gloomcap_sprout": [120.0, 0.0, 7.0, 1.2, 1.0, 4.0, 6.0, 7.0, 0.35, 0.7, 12, true,
			"res://art/units/neutral/gloomcap/gloomcap_sprout.tscn"],
	&"hollow_stag": [1400.0, 15.0, 30.0, 2.0, 1.6, 5.0, 8.0, 10.0, 0.9, 2.6, 160, true, STAG_PATH],
	&"ironhide_tusker": [1800.0, 20.0, 34.0, 1.8, 1.5, 5.5, 0.0, -1.0, 1.0, -1.0, 110, false,
			"res://art/units/neutral/beasts/tusker/tusker.tscn"],
	&"old_scarback": [2160.0, 20.0, 34.0, 1.8, 1.5, 5.5, 0.0, -1.0, 1.0, -1.0, 130, false,
			"res://art/units/neutral/beasts/tusker/tusker.tscn"],
	&"stormcrest_roc": [1500.0, 5.0, 24.0, 3.0, 1.2, 6.5, 0.0, -1.0, 0.9, -1.0, 100, false,
			"res://art/units/neutral/beasts/roc/roc.tscn"],
	&"duskwing_roc": [1500.0, 5.0, 24.0, 3.0, 1.2, 6.5, 0.0, -1.0, 0.9, -1.0, 100, false,
			"res://art/units/neutral/beasts/roc/roc.tscn"],
	&"greymane_direwolf": [1300.0, 10.0, 26.0, 1.6, 1.0, 7.0, 0.0, -1.0, 0.8, -1.0, 90, false,
			"res://art/units/neutral/beasts/direwolf/direwolf.tscn"],
	&"moonpelt_direwolf": [1300.0, 10.0, 26.0, 1.6, 1.0, 7.5, 0.0, -1.0, 0.8, -1.0, 105, false,
			"res://art/units/neutral/beasts/direwolf/direwolf.tscn"],
	&"grizzlemaw": [2600.0, 25.0, 42.0, 2.0, 1.8, 5.0, 0.0, -1.0, 1.1, -1.0, 180, false,
			"res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn"],
	&"elder_grizzlemaw": [3000.0, 25.0, 42.0, 2.0, 1.8, 5.0, 0.0, -1.0, 1.1, -1.0, 210, false,
			"res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn"],
}
# 12.C9 plugged the stag and the 8 beasts too: every type now has its model_scene.
const MODELLED: Array[StringName] = [&"bristleback", &"mirefang", &"gloomcap_elder", &"gloomcap_sprout",
		&"hollow_stag", &"ironhide_tusker", &"old_scarback", &"stormcrest_roc", &"duskwing_roc", &"greymane_direwolf",
		&"moonpelt_direwolf", &"grizzlemaw", &"elder_grizzlemaw"]

var world: Node3D
var vfx: Node3D
var river: Node3D
var errors: Array[String] = []
var finished := false
var spawned: Array = []
var hits: Array = []    # [id, target, amount, frame]
var casts: Array = []   # [id, frame, caster]
var checks := 0


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	var nm := NavigationMesh.new()
	nm.vertices = PackedVector3Array([Vector3(-60.0, 0.0, -60.0), Vector3(NAV_X1, 0.0, -60.0),
			Vector3(NAV_X1, 0.0, 60.0), Vector3(-60.0, 0.0, 60.0)])
	nm.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nm
	world.add_child(region)
	vfx = Node3D.new()
	vfx.set_script(_script(VFX_SRC))
	vfx.add_to_group(&"mapfill_vfx")
	world.add_child(vfx)
	river = Node3D.new()
	river.set_script(_script(RIVER_SRC))
	river.add_to_group(&"river")
	world.add_child(river)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	if not ResourceLoader.exists(AB_PATH):
		_fail("missing " + AB_PATH)
		return
	var map := world.get_world_3d().navigation_map
	var tries := 0
	while NavigationServer3D.map_get_iteration_id(map) <= 0 and tries < 120:
		tries += 1
		await _wait(1)
	_test_types()
	await _test_defaults()
	await _clear()
	await _test_spore_burst()
	await _clear()
	await _test_antler_sweep()
	await _clear()
	await _test_leash()
	await _clear()
	await _test_gore_charge()
	await _clear()
	await _test_bristle_hide()
	await _clear()
	await _test_roc()
	await _clear()
	await _test_direwolf()
	await _clear()
	await _test_grizzlemaw()
	await _clear()
	print("%d checks" % checks)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in errors:
			print("  - ", e)
		print("FAIL %s: %d problem(s)" % [TASK_ID, errors.size()])
	finished = true


func _fail(msg: String) -> void:
	errors.append(msg)
	print("FAIL %s: %s" % [TASK_ID, msg])
	finished = true


# ---------------------------------------------------------------- data

func _test_types() -> void:
	for id: StringName in TYPES:
		var row: Array = TYPES[id]
		var path := "res://data/units/%s.tres" % id
		if not ResourceLoader.exists(path):
			errors.append("missing " + path)
			continue
		var t := load(path) as UnitType
		if t == null:
			errors.append(path + " is not a UnitType")
			continue
		_eq(t.id, id, "%s id" % id)
		_eq(t.faction, &"neutral", "%s faction" % id)
		_near(t.max_hp, row[0], "%s max_hp" % id)
		_near(t.armor, row[1], "%s armor" % id)
		_near(t.attack_damage, row[2], "%s damage" % id)
		_near(t.attack_range, row[3], "%s range" % id)
		_near(t.attack_cooldown, row[4], "%s cooldown" % id)
		_near(t.move_speed, row[5], "%s speed" % id)
		_near(t.aggro_range, row[6], "%s aggro" % id)
		if float(row[7]) > 0.0:
			_near(t.sight_radius, row[7], "%s sight" % id)
		else:
			_check(t.sight_radius >= 11.0 and t.sight_radius <= 14.0, "%s sight %.1f not in 11-14" % [id, t.sight_radius])
		_near(t.radius, row[8], "%s radius" % id)
		if float(row[9]) > 0.0:
			_near(t.body_height, row[9], "%s height" % id)
		_eq(t.kill_xp, row[10], "%s kill_xp" % id)
		_eq(t.neutral_leash, row[11], "%s neutral_leash" % id)
		_eq(t.model_path, row[12], "%s model_path" % id)
		_eq(t.cost, 0, "%s cost" % id)
		_eq(t.pop, 0, "%s pop" % id)
		if MODELLED.has(id):
			_check(t.model_scene != null and t.model_scene.resource_path == row[12], "%s model_scene" % id)
		else:
			_check(t.model_scene == null, "%s model_scene must stay empty until its model lands (12.C9)" % id)
	# Beasts: aggro 0 in the .tres, the brain uses BEASTS aggro.
	_near(float(CreatureAbilities.beast_info(&"stormcrest_roc")["aggro"]), 10.0, "roc aggro (BEASTS)")
	_near(CreatureAbilities.strength_of_type(&"hollow_stag"), 700.0, "stag strength")
	_near(CreatureAbilities.strength_of_type(&"old_scarback"), 1080.0, "scarback strength")


func _test_defaults() -> void:
	_eq(CreatureAbilities.abilities_for(&"gloomcap_elder"), [&"spore_burst"] as Array[StringName], "elder ids")
	_eq(CreatureAbilities.abilities_for(&"duskwing_roc"), [&"shrieking_dive", &"updraft"] as Array[StringName],
			"duskwing ids")
	var mf: Array = _creature("mirefang", Vector3(-50.0, 0.0, -50.0))
	var mfu: Unit = mf[0]
	_check(mfu.is_in_group(&"amphibious"), "mirefang in group amphibious")
	_check(mfu.is_in_group(&"creatures"), "mirefang in group creatures")
	_check(CreatureAbilities.attach(mfu) == mf[1], "attach returns the existing node")
	_check(CreatureAbilities.of(mfu) == mf[1], "CreatureAbilities.of")
	_eq(Unit.kill_xp_value(mfu), 30, "kill_xp_value mirefang")
	# The ids 12.C11 passes explicitly (typed array), and a creature model loaded.
	var gz := UnitType.find("grizzlemaw").create_unit()
	gz.team = N
	world.add_child(gz)
	gz.global_position = Vector3(-50.0, 0.0, -44.0)
	spawned.append(gz)
	var ids: Array[StringName] = [&"maul", &"rending_roar", &"enrage"]
	var node := CreatureAbilities.new()
	node.setup(gz, ids)
	gz.add_child(node)
	_eq(node.ability_ids(), ids, "grizzlemaw ids from setup")
	_eq(node.can_cast(&"enrage"), CreatureAbilities.REASON_PASSIVE, "enrage is passive")
	_eq(node.can_cast(&"pounce"), CreatureAbilities.REASON_LOCKED, "pounce locked on a grizzlemaw")
	var el: Array = _creature("gloomcap_elder", Vector3(-50.0, 0.0, -38.0))
	await _wait(2)
	_check((el[0] as Unit).model_has(&"play_cast"), "the Elder model is loaded (play_cast)")
	_eq(Unit.kill_xp_value(el[0]), 50, "kill_xp_value elder")


# ---------------------------------------------------------------- creatures

func _test_spore_burst() -> void:
	var S := Vector3(-20.0, 0.0, -20.0)
	var el: Array = _creature("gloomcap_elder", S)
	var u: Unit = el[0]
	var ab: CreatureAbilities = el[1]
	var v1 := _victim(P, S + Vector3(5.0, 0.0, 0.0))
	var v2 := _victim(E, S + Vector3(5.0, 0.0, 2.0))
	var v3 := _victim(P, S + Vector3(5.0, 0.0, 4.3))
	var near := _victim(P, S + Vector3(12.0, 0.0, 0.0))
	_eq(ab.cast(&"spore_burst", near), CreatureAbilities.REASON_TARGET, "spore burst beyond 9 m")
	ab.reset_cooldowns()
	hits.clear()
	vfx.calls.clear()
	_eq(ab.cast(&"spore_burst", v1), "", "spore burst cast")
	await _wait(24)   # 0.4 s: not yet
	_eq(_hits_of(&"spore_burst").size(), 0, "no spore damage before the 0.46 s burst")
	await _wait(10)   # 0.57 s
	var sp := _hits_of(&"spore_burst")
	_check(_hit_on(sp, v1) and _hit_on(sp, v2), "spore burst hits the target and a unit 2 m away")
	_check(not _hit_on(sp, v3), "spore burst misses a unit 4.3 m away")
	for h: Array in sp:
		_near(float(h[2]), 20.0, "spore burst damage")
	_check(v1.has_status(&"marked") and v2.has_status(&"marked") and not v3.has_status(&"marked"), "spore marks")
	_check(v1.status_time_left(&"marked") > 3.6 and v1.status_time_left(&"marked") <= 4.0, "marked 4 s")
	_check(_vfx_count(&"spore_burst") == 1, "MapFillVfx spore_burst played once")
	_eq(ab.cast(&"spore_burst", v1), CreatureAbilities.REASON_COOLDOWN, "spore burst on cooldown")
	_near(ab.cooldown_total(&"spore_burst"), 10.0, "spore burst cooldown")
	# Autocast every 10 s while fighting (the Elder shoots v1 by itself: aggro 7).
	ab.reset_cooldowns()
	casts.clear()
	ab.autocast_enabled = true
	await _wait(700)   # 11.7 s
	var times := _cast_frames(&"spore_burst")
	_check(times.size() == 2, "spore autocast twice in 11.7 s (got %d)" % times.size())
	if times.size() == 2:
		var gap := float(times[1] - times[0]) / 60.0
		_check(gap >= 9.95 and gap <= 10.6, "spore autocast gap %.2f s (want ~10)" % gap)
	_check(u.is_alive(), "elder alive")


func _test_antler_sweep() -> void:
	var T := Vector3(-20.0, 0.0, 20.0)
	var st: Array = _creature("hollow_stag", T, true)
	var ab: CreatureAbilities = st[1]
	var a := _victim(P, T + Vector3(2.2, 0.0, 0.0))
	casts.clear()
	hits.clear()
	await _wait(150)   # fighting one enemy: no sweep
	_eq(_cast_frames(&"antler_sweep").size(), 0, "no antler sweep with a single enemy")
	var b := _victim(E, T + Vector3(0.0, 0.0, 2.3))
	var far := _victim(P, T + Vector3(0.0, 0.0, -4.5))
	await _wait(80)
	var sw := _hits_of(&"antler_sweep")
	_check(_cast_frames(&"antler_sweep").size() == 1, "antler sweep with 2 enemies within 3 m")
	_check(_hit_on(sw, a) and _hit_on(sw, b) and not _hit_on(sw, far), "sweep hits the 2 near enemies only")
	for h: Array in sw:
		_near(float(h[2]), 35.0, "sweep damage")
	await _wait(470)   # 8.5 s after the first
	var times := _cast_frames(&"antler_sweep")
	_check(times.size() == 2, "antler sweep every 8 s (got %d)" % times.size())
	if times.size() == 2:
		var gap := float(times[1] - times[0]) / 60.0
		_check(gap >= 7.95 and gap <= 8.6, "sweep gap %.2f s (want ~8)" % gap)
	_eq(ab.cast(&"antler_sweep"), CreatureAbilities.REASON_COOLDOWN, "sweep on cooldown")


func _test_leash() -> void:
	var H := Vector3(-30.0, 0.0, 40.0)
	var bb: Array = _creature("bristleback", H, true)
	var u: Unit = bb[0]
	var lure := _victim(P, H + Vector3(4.0, 0.0, 0.0))
	await _wait(60)
	_check(u.attack_target == lure, "bristleback attacks an enemy in aggro")
	lure.command_move(H + Vector3(-25.0, 0.0, 0.0))
	var max_d := 0.0
	for i in 600:
		await physics_frame
		max_d = maxf(max_d, _flat(u.global_position, H))
	_check(max_d <= u.leash_radius() + u.attack_range + 1.0, "bristleback stayed in its leash (%.1f m)" % max_d)
	_check(_flat(u.global_position, H) <= 1.5, "bristleback walked home (%.1f m)" % _flat(u.global_position, H))


# ---------------------------------------------------------------- beasts

func _test_gore_charge() -> void:
	var G := Vector3(0.0, 0.0, -30.0)
	var tk: Array = _creature("ironhide_tusker", G)
	var u: Unit = tk[0]
	var ab: CreatureAbilities = tk[1]
	var close := _victim(P, G + Vector3(-3.0, 0.0, 0.0))
	_eq(ab.cast(&"gore_charge", close), CreatureAbilities.REASON_TARGET, "gore charge at 3 m")
	var t := _victim(P, G + Vector3(10.0, 0.0, 0.0))
	var side := _victim(E, G + Vector3(5.0, 0.0, 1.0))
	var off := _victim(P, G + Vector3(5.0, 0.0, 3.0))
	hits.clear()
	vfx.calls.clear()
	_eq(ab.cast(&"gore_charge", t), "", "gore charge cast")
	_check(ab.is_busy(), "busy while charging")
	_eq(ab.cast(&"gore_charge", t), CreatureAbilities.REASON_BUSY, "busy refusal")
	await _wait(60)
	_check(not ab.is_busy(), "charge over")
	_check(_flat(u.global_position, t.global_position) <= u.radius + t.radius + 0.6, "tusker reached its target")
	var gh := _hits_of(&"gore_charge")
	_check(_amount_on(gh, t) == 45.0, "gore charge 45 on the target (got %s)" % _amount_on(gh, t))
	_check(_amount_on(gh, side) == 20.0, "gore charge 20 on the path (got %s)" % _amount_on(gh, side))
	_check(not _hit_on(gh, off) and not _hit_on(gh, close), "gore charge misses units off the path")
	_check(t.has_status(&"dazed") and not side.has_status(&"dazed"), "gore charge dazes the target only (A)")
	_near(u.move_speed, 5.5, "fight speed back after the charge")
	_check(_vfx_count(&"gore_charge") == 1, "MapFillVfx gore_charge")
	_near(ab.cooldown_total(&"gore_charge"), 12.0, "gore charge cooldown")
	# Variant B: the full hit + daze 1.2 s on the path.
	var G2 := Vector3(0.0, 0.0, 0.0)
	var sb: Array = _creature("old_scarback", G2)
	var t2 := _victim(P, G2 + Vector3(-10.0, 0.0, 0.0))
	var side2 := _victim(P, G2 + Vector3(-5.0, 0.0, 1.0))
	hits.clear()
	_eq((sb[1] as CreatureAbilities).cast(&"gore_charge", t2), "", "scarback charge")
	await _wait(55)
	gh = _hits_of(&"gore_charge")
	_check(_amount_on(gh, side2) == 45.0 and side2.has_status(&"dazed"), "scarback: 45 + daze on the path")
	_check(t2.status_time_left(&"dazed") > 0.6, "scarback: daze 1.2 s on the target")
	# Water: the charge stops on the west bank (river stub 20..24).
	var W := Vector3(14.0, 0.0, 10.0)
	var tw: Array = _creature("ironhide_tusker", W)
	var tu: Unit = tw[0]
	var across := _victim(P, W + Vector3(13.0, 0.0, 0.0))
	hits.clear()
	_eq((tw[1] as CreatureAbilities).cast(&"gore_charge", across), "", "charge toward the river")
	var wet := false
	for i in 90:
		await physics_frame
		if tu.global_position.x >= 20.0:
			wet = true
	_check(not wet, "the charge never enters water (x %.2f)" % tu.global_position.x)
	_check(tu.global_position.x > 16.0, "the charge still went to the bank (x %.2f)" % tu.global_position.x)
	_check(not _hit_on(_hits_of(&"gore_charge"), across), "no hit across the river")
	# Navmesh edge (x 36): the charge ends on the navmesh.
	var M := Vector3(27.0, 0.0, -20.0)
	var tm: Array = _creature("ironhide_tusker", M)
	var mu: Unit = tm[0]
	var outside := _victim(P, M + Vector3(13.0, 0.0, 0.0))
	_eq((tm[1] as CreatureAbilities).cast(&"gore_charge", outside), "", "charge toward the navmesh edge")
	await _wait(90)
	_check(mu.global_position.x <= NAV_X1 + 0.05, "the charge ends on the navmesh (x %.2f)" % mu.global_position.x)
	var q := NavigationServer3D.map_get_closest_point(world.get_world_3d().navigation_map, mu.global_position)
	_check(_flat(q, mu.global_position) < 0.1, "landing point is on the navmesh")


func _test_bristle_hide() -> void:
	var T := Vector3(-40.0, 0.0, -20.0)
	var tk: Array = _creature("ironhide_tusker", T)
	var u: Unit = tk[0]
	var melee := _victim(P, T + Vector3(2.0, 0.0, 0.0), 5.0, 1.6)
	var ranged := _victim(P, T + Vector3(0.0, 0.0, -5.0), 5.0, 6.0)
	melee.command_attack(u)
	ranged.command_attack(u)
	hits.clear()
	await _wait(220)
	var bh := _hits_of(&"bristle_hide")
	var on_melee := 0
	for h: Array in bh:
		if h[1] == melee:
			on_melee += 1
			_near(float(h[2]), 4.0, "bristle hide reflect")
	_check(on_melee >= 3, "bristle hide on each melee hit (got %d)" % on_melee)
	_check(not _hit_on(bh, ranged), "no bristle hide on a ranged attacker")


func _test_roc() -> void:
	var R := Vector3(-40.0, 0.0, 20.0)
	var rc: Array = _creature("stormcrest_roc", R)
	var u: Unit = rc[0]
	var ab: CreatureAbilities = rc[1]
	var lonely := _victim(P, R + Vector3(0.0, 0.0, -6.0))
	var c1 := _victim(P, R + Vector3(10.0, 0.0, 0.0))
	var c2 := _victim(E, R + Vector3(10.0, 0.0, 1.5))
	var c3 := _victim(P, R + Vector3(11.0, 0.0, -1.0))
	_check(ab.find_target(&"gale_swoop") == c1, "gale swoop picks the biggest cluster")
	hits.clear()
	_eq(ab.cast(&"gale_swoop"), "", "gale swoop cast")
	await _wait(40)
	var gs := _hits_of(&"gale_swoop")
	_check(_hit_on(gs, c1) and _hit_on(gs, c2) and _hit_on(gs, c3), "gale swoop hits the cluster")
	_check(not _hit_on(gs, lonely), "gale swoop misses the lone unit")
	for h: Array in gs:
		_near(float(h[2]), 40.0, "gale swoop damage")
	_check(c2.has_status(&"dazed") and not c2.has_status(&"marked"), "gale swoop dazes")
	_check(_flat(u.global_position, c1.global_position) <= u.radius + c1.radius + 0.6, "roc landed beside the cluster")
	# Shrieking Dive: marked 5 s instead of the daze.
	var D := Vector3(-40.0, 0.0, 40.0)
	var dk: Array = _creature("duskwing_roc", D)
	var d1 := _victim(P, D + Vector3(8.0, 0.0, 0.0))
	hits.clear()
	_eq((dk[1] as CreatureAbilities).cast(&"shrieking_dive", d1), "", "shrieking dive cast")
	await _wait(35)
	_check(_amount_on(_hits_of(&"shrieking_dive"), d1) == 40.0, "shrieking dive 40")
	_check(d1.has_status(&"marked") and d1.status_time_left(&"marked") > 4.5 and not d1.has_status(&"dazed"),
			"shrieking dive marks 5 s, no daze")
	var far := _victim(P, D + Vector3(0.0, 0.0, -13.0))
	(dk[1] as CreatureAbilities).reset_cooldowns()
	_eq((dk[1] as CreatureAbilities).cast(&"shrieking_dive", far), CreatureAbilities.REASON_TARGET, "dive beyond 12 m")
	# Updraft: once at 40 %: shroud 4 s, +15 % over 4 s, flies to the nest.
	u.command_stop()
	var nest := u.global_position + Vector3(0.0, 0.0, 8.0)
	u.hp = u.max_hp * 0.5
	_eq(ab.cast(&"updraft", nest), CreatureAbilities.REASON_NOT_READY, "updraft above 40 %")
	u.hp = u.max_hp * 0.39
	var before := _flat(u.global_position, nest)
	_eq(ab.cast(&"updraft", nest), "", "updraft cast")
	_check(u.has_status(&"shroud") and u.status_time_left(&"shroud") > 3.9, "updraft shroud 4 s")
	await _wait(250)
	_near(u.hp / u.max_hp, 0.54, "updraft heals 15 % over 4 s", 0.01)
	_check(_flat(u.global_position, nest) < before - 3.0, "updraft flies toward the nest")
	_eq(ab.cast(&"updraft", nest), CreatureAbilities.REASON_NOT_READY, "updraft once per life")
	_check(ab.updraft_used(), "updraft_used")
	# Autocast Updraft (another roc, damaged below 40 %).
	var rc2: Array = _creature("stormcrest_roc", R + Vector3(-12.0, 0.0, 0.0), true)
	var u2: Unit = rc2[0]
	u2.hp = u2.max_hp * 0.42
	u2.take_damage(60.0, null)
	await _wait(40)
	_check((rc2[1] as CreatureAbilities).updraft_used() and u2.has_status(&"shroud"), "updraft autocast at 40 %")


func _test_direwolf() -> void:
	var L := Vector3(-40.0, 0.0, -5.0)
	var wf: Array = _creature("greymane_direwolf", L)
	var u: Unit = wf[0]
	var ab: CreatureAbilities = wf[1]
	var near := _victim(P, L + Vector3(0.0, 0.0, 3.0))
	_eq(ab.cast(&"pounce", near), CreatureAbilities.REASON_TARGET, "pounce at 3 m")
	var t := _victim(P, L + Vector3(7.0, 0.0, 0.0))
	hits.clear()
	_eq(ab.cast(&"pounce", t), "", "pounce cast")
	await _wait(30)
	_check(_amount_on(_hits_of(&"pounce"), t) == 35.0, "pounce 35")
	_check(t.has_status(&"rooted") and t.status_time_left(&"rooted") <= 0.8, "pounce roots 0.8 s")
	_check(_flat(u.global_position, t.global_position) <= u.radius + t.radius + 0.6, "wolf landed beside its target")
	_near(ab.cooldown_total(&"pounce"), 9.0, "greymane pounce cooldown")
	var mp: Array = _creature("moonpelt_direwolf", L + Vector3(0.0, 0.0, 12.0))
	_near((mp[1] as CreatureAbilities).cooldown_for(&"pounce"), 6.0, "moonpelt pounce cooldown")
	# No leap onto the far bank (the landing spot is in the water).
	var B := Vector3(16.0, 0.0, 25.0)
	var wb: Array = _creature("greymane_direwolf", B)
	var bank := _victim(P, B + Vector3(9.0, 0.0, 0.0))
	_eq((wb[1] as CreatureAbilities).cast(&"pounce", bank), CreatureAbilities.REASON_TARGET, "no pounce into water")
	# Hamstring: -25 % speed 3 s on each hit; the slow outlives the wolf.
	ab.reset_cooldowns()
	var prey := _victim(P, u.global_position + Vector3(0.0, 0.0, -2.0))
	u.command_attack(prey)
	var slowed := false
	for i in 120:
		await physics_frame
		if prey.has_modifier(&"beast:hamstring"):
			slowed = true
			break
	_check(slowed, "hamstring modifier on the victim")
	_near(prey.move_speed, 3.75, "hamstring -25 % speed")
	u.queue_free()
	await _wait(120)
	_check(prey.has_modifier(&"beast:hamstring"), "hamstring still on after 2 s")
	await _wait(80)
	_check(not prey.has_modifier(&"beast:hamstring"), "hamstring gone after 3 s")
	_near(prey.move_speed, 5.0, "speed back after the hamstring")


func _test_grizzlemaw() -> void:
	var Z := Vector3(-10.0, 0.0, 45.0)
	var gz: Array = _creature("grizzlemaw", Z)
	var u: Unit = gz[0]
	var ab: CreatureAbilities = gz[1]
	var t := _victim(P, Z + Vector3(2.5, 0.0, 0.0))
	var far := _victim(P, Z + Vector3(0.0, 0.0, -8.0))
	_eq(ab.cast(&"maul", far), CreatureAbilities.REASON_TARGET, "maul out of reach")
	hits.clear()
	_eq(ab.cast(&"maul", t), "", "maul cast")
	_check(_amount_on(_hits_of(&"maul"), t) == 70.0, "maul 70")
	_check(t.has_status(&"marked") and t.status_time_left(&"marked") > 4.9, "maul marks 5 s")
	# Rending Roar: only from 50 % HP.
	var champ := _victim(E, Z + Vector3(0.0, 0.0, 5.0))
	champ.add_to_group(&"champions")
	u.hp = u.max_hp * 0.6
	_eq(ab.cast(&"rending_roar"), CreatureAbilities.REASON_NOT_READY, "roar above 50 %")
	u.hp = u.max_hp * 0.45
	_eq(ab.cast(&"rending_roar"), "", "roar cast")
	_check(t.has_status(&"dazed") and t.status_time_left(&"dazed") > 0.95, "roar dazes 1 s")
	_check(champ.has_status(&"dazed") and champ.status_time_left(&"dazed") <= 0.5, "roar: half on heroes")
	_check(not far.has_status(&"dazed"), "roar misses a unit 8 m away")
	_check(not t.has_status(&"taunted"), "grizzlemaw A never taunts")
	_near(ab.cooldown_total(&"rending_roar"), 30.0, "roar cooldown")
	# Elder: + taunt 3 s on non-heroes.
	var Y := Vector3(10.0, 0.0, 45.0)
	var eg: Array = _creature("elder_grizzlemaw", Y)
	var eu: Unit = eg[0]
	var s := _victim(P, Y + Vector3(3.0, 0.0, 0.0))
	var h := _victim(P, Y + Vector3(0.0, 0.0, 3.0))
	h.add_to_group(&"champions")
	eu.hp = eu.max_hp * 0.4
	_eq((eg[1] as CreatureAbilities).cast(&"rending_roar"), "", "elder roar")
	_check(s.has_status(&"taunted") and s.taunt_source() == eu and s.status_time_left(&"taunted") > 2.9,
			"elder roar taunts a soldier 3 s")
	_check(not h.has_status(&"taunted"), "elder roar never taunts a hero")
	# Enrage below 30 %.
	u.hp = u.max_hp * 0.25
	u.take_damage(1.0, null)
	_near(u.attack_cooldown, 1.8 * 0.7, "enrage: attack cooldown x0.7")
	_check(ab.is_enraged(), "is_enraged")
	u.heal(99999.0)
	await _wait(40)
	_near(u.attack_cooldown, 1.8, "enrage ends above 30 %")


# ---------------------------------------------------------------- helpers

func _creature(id: String, pos: Vector3, autocast: bool = false) -> Array:
	var u := UnitType.find(id).create_unit()
	u.team = N
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	var ab := CreatureAbilities.attach(u)
	ab.autocast_enabled = autocast
	ab.ability_hit.connect(func(aid: StringName, target: Node3D, amount: float) -> void:
		hits.append([aid, target, amount, Engine.get_physics_frames()]))
	ab.ability_cast.connect(func(aid: StringName, _t: Variant) -> void:
		casts.append([aid, Engine.get_physics_frames(), u]))
	return [u, ab]


## A PLAYER / ENEMY dummy: 5000 HP, armor 0; damage 0 = never attacks, never fights back.
func _victim(team: int, pos: Vector3, dmg: float = 0.0, rng: float = 1.6) -> Unit:
	var t := UnitType.new()
	t.id = &"test_dummy"
	t.display_name = "Dummy"
	t.faction = &"fire"
	t.max_hp = 5000.0
	t.move_speed = 5.0
	t.attack_damage = dmg
	t.attack_range = rng
	t.attack_cooldown = 1.0
	t.aggro_range = 0.0
	t.radius = 0.45
	var u := t.create_unit()
	u.team = team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


func _hits_of(id: StringName) -> Array:
	var out: Array = []
	for h: Array in hits:
		if h[0] == id:
			out.append(h)
	return out


func _hit_on(list: Array, u: Node) -> bool:
	for h: Array in list:
		if h[1] == u:
			return true
	return false


func _amount_on(list: Array, u: Node) -> float:
	var total := 0.0
	for h: Array in list:
		if h[1] == u:
			total += float(h[2])
	return total


func _cast_frames(id: StringName) -> Array:
	var out: Array = []
	for c: Array in casts:
		if c[0] == id:
			out.append(c[1])
	return out


func _vfx_count(id: StringName) -> int:
	var n := 0
	for c: Array in vfx.calls:
		if c[0] == id:
			n += 1
	return n


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	hits.clear()
	casts.clear()
	vfx.calls.clear()
	await _wait(3)


func _script(src: String) -> GDScript:
	var gs := GDScript.new()
	gs.source_code = src
	gs.reload()
	return gs


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		errors.append(msg)


func _eq(got: Variant, want: Variant, msg: String) -> void:
	checks += 1
	if str(got) != str(want):
		errors.append("%s: got '%s', want '%s'" % [msg, str(got), str(want)])


func _near(got: float, want: float, msg: String, tol: float = 0.05) -> void:
	checks += 1
	if absf(got - want) > tol:
		errors.append("%s: got %.3f, want %.3f" % [msg, got, want])
