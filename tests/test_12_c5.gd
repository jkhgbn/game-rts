extends SceneTree
## Task 12.C5: BuildGrid water / crossing / camp rules, BountyBoard Guard on capture points + Claim, Den / Lodge
## "nearer" by navmesh path, towers and keeps never target beasts (docs/design/map-fill.md 2.4, 6, 13, "Done when"
## 12.C5). A small scene: the real RiverSystem (12.C1, load-guarded) with the map-fill river under a baked navmesh,
## a stub CampManager / capture points (the contract through groups), stub champions.
## Run:  godot --headless --path . -s tests/test_12_c5.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "12.C5"
const RIVER_PATH := "res://scripts/world/river_system.gd"

## map-fill.md 2.1 / 2.2 (the same numbers as skirmish.gd; copied so this test does not depend on 12.C1's file).
const POLY_N: Array[Vector2] = [Vector2(-15.0, -62.0), Vector2(-12.0, -48.7), Vector2(-9.0, -38.0),
		Vector2(-8.0, -30.0), Vector2(-5.0, -21.0), Vector2(-2.5, -12.5)]
const MOAT := Vector4(0.0, 0.0, 12.75, 1.75)
const CROSSINGS: Array[Dictionary] = [
	{"id": &"bridge_road_n", "name": "Saltgate Bridge", "kind": &"bridge_road", "center": Vector3(-12.0, 0.0, -48.7),
		"width": 6.0, "length": 9.0, "dir": Vector3(45.0, 0.0, -1.0)},
	{"id": &"bridge_road_s", "name": "Millstone Bridge", "kind": &"bridge_road", "center": Vector3(12.0, 0.0, 48.7),
		"width": 6.0, "length": 9.0, "dir": Vector3(-45.0, 0.0, 1.0)},
	{"id": &"ford_n", "name": "Reed Ford", "kind": &"ford", "center": Vector3(-8.5, 0.0, -34.0), "width": 7.0,
		"length": 7.0, "dir": Vector3(1.0, 0.0, 8.0)},
	{"id": &"ford_s", "name": "Willow Ford", "kind": &"ford", "center": Vector3(8.5, 0.0, 34.0), "width": 7.0,
		"length": 7.0, "dir": Vector3(-1.0, 0.0, -8.0)},
	{"id": &"bridge_crown_w", "name": "West Crown Bridge", "kind": &"bridge_lane", "center": Vector3(-9.02, 0.0, 9.02),
		"width": 8.0, "length": 6.5, "dir": Vector3(-1.0, 0.0, 1.0)},
	{"id": &"bridge_crown_e", "name": "East Crown Bridge", "kind": &"bridge_lane", "center": Vector3(9.02, 0.0, -9.02),
		"width": 8.0, "length": 6.5, "dir": Vector3(1.0, 0.0, -1.0)},
	{"id": &"steps_nw", "name": "North-west Crown Steps", "kind": &"steps", "center": Vector3(-9.02, 0.0, -9.02),
		"width": 6.0, "length": 6.0, "dir": Vector3(1.0, 0.0, -1.0)},
	{"id": &"steps_se", "name": "South-east Crown Steps", "kind": &"steps", "center": Vector3(9.02, 0.0, 9.02),
		"width": 6.0, "length": 6.0, "dir": Vector3(-1.0, 0.0, 1.0)},
]
const CAMP_SPOT := Vector3(-37.0, 0.0, -10.0)   # Stag Glade (5.2)

const CAMPS_SRC := """
extends Node
var spots: Array = []
func _init() -> void:
	add_to_group("camp_manager")
func camps() -> Array:
	return spots
"""

const POINT_SRC := """
extends Node3D
signal owner_changed(point: Node3D, new_team: int, old_team: int)
var kind := &"watchtower"
var display_name := "Rookwatch"
var team := 2
var owner_team := -1
var capture_radius := 7.0
func _init() -> void:
	add_to_group("capture_points")
func is_alive() -> bool:
	return true
func set_owner_team(t: int, emit := true) -> void:
	var old := owner_team
	owner_team = t
	if emit:
		owner_changed.emit(self, t, old)
"""

const HOUSE_SRC := """
extends Node3D
var kind := &"den"
func _init() -> void:
	add_to_group("guilds")
func door_point() -> Vector3:
	return global_position
"""


class StubChampion extends Node3D:
	var team := 0
	var purse := 0
	var xp := 0
	var display_name := "Stub"

	func is_alive() -> bool:
		return true

	func add_purse(n: int) -> void:
		purse += n

	func add_xp(n: int) -> void:
		xp += n


var errors: Array[String] = []
var _done := false
var level: Node3D
var region: NavigationRegion3D
var river: Node3D
var grid: BuildGrid
var camps: Node
var eco: Economy
var board: BountyBoard
var bank: EssenceBank
var ended: Dictionary = {}   # bounty instance id -> reason
var point_script: GDScript


func _initialize() -> void:
	level = Node3D.new()
	level.name = "Level"
	root.add_child(level)
	current_scene = level
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


func _run() -> void:
	await process_frame
	await _build()
	if river == null:
		print("FAIL %s: RiverSystem (12.C1) missing" % TASK_ID)
		_done = true
		return
	_phase_build_grid()
	await _phase_towers()
	await _phase_guard()
	await _phase_claim()
	_phase_guild_paths()
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	_done = true


# ---------------------------------------------------------------- scene

func _build() -> void:
	region = NavigationRegion3D.new()
	region.name = "Nav"
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.agent_radius = 0.5
	nm.agent_height = 2.0
	nm.agent_max_climb = 0.25
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	region.navigation_mesh = nm
	level.add_child(region)
	NavigationServer3D.region_set_use_async_iterations(region.get_rid(), false)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(124.0, 1.0, 124.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	region.add_child(ground)
	if ResourceLoader.exists(RIVER_PATH):
		var rs := load(RIVER_PATH) as GDScript
		if rs:
			river = rs.new() as Node3D
	if river:
		river.set(&"build_visuals", false)
		river.name = "River"
		region.add_child(river)
		# Downstream order: north edge -> moat, moat -> south edge (the point mirror).
		var north := PackedVector2Array(POLY_N)
		var south := PackedVector2Array()
		for i in range(north.size() - 1, -1, -1):
			south.append(-north[i])
		var lines: Array[PackedVector2Array] = [north, south]
		river.call(&"setup", lines, 2.5, MOAT, CROSSINGS)
	region.bake_navigation_mesh(false)
	for i in 4:
		await physics_frame
	var cs := GDScript.new()
	cs.source_code = CAMPS_SRC
	cs.reload()
	camps = Node.new()
	camps.set_script(cs)
	camps.name = "Camps"
	level.add_child(camps)
	var marker := Node3D.new()
	marker.name = "StagGlade"
	level.add_child(marker)
	marker.global_position = CAMP_SPOT
	camps.get(&"spots").append(marker)
	eco = Economy.new()
	eco.team = Unit.Team.PLAYER
	level.add_child(eco)
	eco.crystals = 100000
	grid = BuildGrid.new()
	grid.name = "BuildGrid"
	grid.nav_region = region
	level.add_child(grid)
	point_script = GDScript.new()
	point_script.source_code = POINT_SRC
	point_script.reload()
	bank = EssenceBank.for_team(0)
	bank.trickle_enabled = false
	bank.essence = 5000
	board = BountyBoard.for_team(0)
	board.bounty_ended.connect(func(b: Node, reason: StringName) -> void: ended[b.get_instance_id()] = reason)
	await physics_frame


# ---------------------------------------------------------------- BuildGrid

func _phase_build_grid() -> void:
	var hearth := BuildingType.find(&"fire_hearth")
	var keep := BuildingType.find(&"fire_keep")
	_check(hearth != null and keep != null, "building types found")
	if hearth == null or keep == null:
		return
	_check(BuildGrid.MSG_WATER == "Can't build on water" and BuildGrid.MSG_CROSSING == "Too close to a crossing"
			and BuildGrid.MSG_CAMP == "Too close to a monster camp", "the three messages")
	_check(bool(river.call(&"is_water", Vector3(-6.5, 0, -25.5))), "river: deep water at (-6.5, -25.5)")
	# In deep water (a navmesh hole): the real reason, not "Not on walkable ground".
	var wet := grid.check(hearth, Vector3(-6.5, 0, -25.5), 0)
	_check(wet == BuildGrid.MSG_WATER, "hearth in the river -> '%s' (got '%s')" % [BuildGrid.MSG_WATER, wet])
	var hall := BuildingType.find(&"fire_barracks")
	_check(hall != null and grid.check(hall, Vector3(-12.75, 0, 0), 0) == BuildGrid.MSG_WATER, "hall on the moat -> water")
	# Search the grid around the north river for the three cases (distances measured densely here).
	var found := {"near": Vector3.INF, "clear": Vector3.INF, "crossing": Vector3.INF}
	for i in range(-15, 5):
		for j in range(-28, -6):
			var c := grid.snap(Vector3(i * 2.0, 0.0, j * 2.0), hearth.footprint)
			var rect := _rect(c, hearth.footprint)
			var dw := _dense_water_distance(rect)
			var dc := _crossing_centre_distance(rect)
			var dcamp := _point_rect_distance(rect, CAMP_SPOT)
			if dcamp < 10.0:
				continue
			if dw > 0.15 and dw < 0.85 and dc > 9.0 and found["near"] == Vector3.INF:
				found["near"] = c
			if dw > 1.3 and dc > 8.6 and found["clear"] == Vector3.INF and dw < 4.0:
				found["clear"] = c
			if dw > 1.3 and dc < 7.4 and found["crossing"] == Vector3.INF:
				found["crossing"] = c
	for k: String in found:
		_check(found[k] != Vector3.INF, "a '%s' test spot exists" % k)
	if found["near"] != Vector3.INF:
		var r := grid.check(hearth, found["near"], 0)
		_check(r == BuildGrid.MSG_WATER, "footprint 0.15-0.85 m from water at %s -> water (got '%s')" % [found["near"], r])
	if found["clear"] != Vector3.INF:
		var r := grid.check(hearth, found["clear"], 0)
		_check(r == "", "footprint > 1.3 m from water, > 8.6 m from crossings at %s -> ok (got '%s')"
				% [found["clear"], r])
	if found["crossing"] != Vector3.INF:
		var r := grid.check(hearth, found["crossing"], 0)
		_check(r == BuildGrid.MSG_CROSSING, "footprint < 7.4 m from a crossing centre at %s -> crossing (got '%s')"
				% [found["crossing"], r])
		# Checked before the crystals.
		eco.crystals = 0
		r = grid.check(hearth, found["crossing"], 0)
		_check(r == BuildGrid.MSG_CROSSING, "crossing message comes before 'Not enough crystals' (got '%s')" % r)
		eco.crystals = 100000
		# ... and after "Blocked" by an enemy unit.
		var foe := _unit(Unit.Team.ENEMY, found["crossing"], "Shade")
		r = grid.check(hearth, found["crossing"], 0)
		_check(r == BuildGrid.MSG_BLOCKED, "an enemy unit inside comes first (got '%s')" % r)
		foe.free()
	# Every crossing centre itself: refused (water on the ford / deck, else the crossing rule).
	for c: Dictionary in CROSSINGS:
		var r := grid.check(hearth, c["center"], 0)
		_check(r == BuildGrid.MSG_WATER or r == BuildGrid.MSG_CROSSING, "on %s -> refused (got '%s')" % [c["id"], r])
	# Monster camp spot: 8 m.
	var near_camp := grid.snap(CAMP_SPOT + Vector3(5.0, 0.0, 0.0), hearth.footprint)
	var far_camp := grid.snap(CAMP_SPOT + Vector3(0.0, 0.0, 14.0), hearth.footprint)
	var rc := grid.check(hearth, near_camp, 0)
	_check(rc == BuildGrid.MSG_CAMP, "5 m from a camp spot -> camp (got '%s')" % rc)
	var rf := grid.check(hearth, far_camp, 0)
	_check(rf == "", "12+ m from a camp spot -> ok (got '%s')" % rf)
	_check(grid.map_fill_reason(_rect(far_camp, hearth.footprint)) == "", "map_fill_reason '' far from everything")
	# find_spot never returns a spot the rules refuse.
	var spot := grid.find_spot(hearth, Vector3(-8.0, 0.0, -30.0), 0)
	_check(spot != Vector3.INF and grid.check(hearth, spot, 0) == "", "find_spot near the ford gives a legal spot")


# ---------------------------------------------------------------- towers and keeps

func _phase_towers() -> void:
	var tower_type := BuildingType.find(&"fire_tower")
	var keep_type := BuildingType.find(&"fire_keep")
	var tower := grid.spawn_complete(tower_type, Vector3(41.0, 0.0, 41.0), 0)
	var keep := grid.spawn_complete(keep_type, Vector3(-45.0, 0.0, 45.0), 0)
	var beast := _unit(Unit.Team.NEUTRAL, Vector3(45.0, 0.0, 41.0), "Ironhide Tusker")
	beast.add_to_group(&"beasts")
	var beast2 := _unit(Unit.Team.NEUTRAL, Vector3(-45.0, 0.0, 39.0), "Grizzlemaw")
	beast2.add_to_group(&"beasts")
	var beast_hp := beast.hp
	var beast2_hp := beast2.hp
	await _wait(2.5)
	_check(_bolts() == 0 and beast.hp == beast_hp and beast2.hp == beast2_hp, "no bolt fired at beasts (%d)" % _bolts())
	_check(tower.get(&"attack_target") == null, "tower: a beast alone in range is not a target")
	_check(keep.get(&"attack_target") == null, "keep: a beast alone in range is not a target")
	_check(BuildingGun.is_ignored(beast) and not BuildingGun.is_ignored(tower), "BuildingGun.is_ignored")
	# A normal creature (not a beast) is still shot.
	var boar := _unit(Unit.Team.NEUTRAL, Vector3(41.0, 0.0, 45.0), "Bristleback")
	var boar_hp := boar.hp
	await _wait(1.5)
	_check(tower.get(&"attack_target") == boar, "tower shoots a non-beast neutral creature")
	_check(boar.hp < boar_hp, "the tower's bolts hit it (%.0f -> %.0f)" % [boar_hp, boar.hp])
	for n: Node in [tower, keep, beast, beast2, boar]:
		n.queue_free()
	await _wait(0.2)


# ---------------------------------------------------------------- Guard on a capture point

func _phase_guard() -> void:
	var c := _champ(Vector3(20.0, 0.0, -30.0), "Sable Quint")
	var p := _point(Vector3(30.0, 0.0, -30.0), "Saltwatch")
	_check(board.kind_for(p) == Bounty.EXPLORE, "kind_for a neutral point = EXPLORE (Claim)")
	_check(board.place(Bounty.GUARD, p, p.global_position) == "Invalid target", "Guard on a neutral point refused")
	p.call(&"set_owner_team", 1)
	_check(board.place(Bounty.GUARD, p, p.global_position) == "Invalid target", "Guard on an enemy point refused")
	p.call(&"set_owner_team", 0)
	_check(board.kind_for(p) == Bounty.GUARD, "kind_for an own-held point = GUARD")
	_check(board.can_place(Bounty.GUARD, p, p.global_position) == "", "can_place Guard on an own point")
	var before := bank.essence
	_check(board.place(Bounty.GUARD, p, p.global_position, 90) == "", "Guard on an own-held point placed")
	var g := board.bounty_on(p)
	_check(g != null and g.kind == Bounty.GUARD and bank.essence == before - 90, "Guard costs its stake")
	if g == null:
		return
	var gid := g.get_instance_id()
	await _wait(10.4)
	_check(c.purse == 10 and g.paid == 10, "tick 1 pays 90 / 9 = 10 to the champion 10 m away (%d)" % c.purse)
	c.global_position = Vector3(50.0, 0.0, -30.0)   # 20 m: out of the 14 m
	await _wait(10.2)
	_check(c.purse == 10, "a champion 20 m away is not paid (%d)" % c.purse)
	before = bank.essence
	p.call(&"set_owner_team", 1)
	await _wait(0.1)
	_check(_reason_of(gid) == &"owner_changed", "Guard ends when the point changes owner (%s)" % _reason_of(gid))
	_check(bank.essence == before + 80, "unpaid rest 80 refunded (%d)" % (bank.essence - before))
	# The poll catches a silent owner change too.
	p.call(&"set_owner_team", 0)
	_check(board.place(Bounty.GUARD, p, p.global_position) == "", "Guard placed again")
	var g2 := board.bounty_on(p)
	var g2id := g2.get_instance_id() if g2 else 0
	p.call(&"set_owner_team", -1, false)
	await _wait(0.6)
	_check(_reason_of(g2id) == &"owner_changed", "silent owner change ends the Guard too")
	c.queue_free()
	p.queue_free()
	await _wait(0.1)


# ---------------------------------------------------------------- Claim

func _phase_claim() -> void:
	var p := _point(Vector3(-24.0, 0.0, -41.0), "Rookwatch")
	var own := _point(Vector3(24.0, 0.0, 41.0), "Owlwatch")
	own.call(&"set_owner_team", 0)
	var c := _champ(Vector3(-40.0, 0.0, 30.0), "Oathwall")
	# A plain Explore 10 m away; an Explore next to an own point: plain.
	_check(board.place(Bounty.EXPLORE, null, Vector3(-24.0, 0.0, -51.5)) == "", "Explore 10.5 m from a point placed")
	var plain := board.bounties[board.bounties.size() - 1]
	_check(not plain.is_claim() and plain.kind_name() == "Explore", "10.5 m away = a plain Explore")
	_check(board.place(Bounty.EXPLORE, null, Vector3(28.0, 0.0, 41.0)) == "", "Explore next to an own point placed")
	var plain2 := board.bounties[board.bounties.size() - 1]
	_check(not plain2.is_claim(), "Explore next to an own-held point = plain")
	board.remove(plain)
	board.remove(plain2)
	# The Claim.
	_check(board.claim_point_near(Vector3(-20.0, 0.0, -37.0)) == p, "claim_point_near")
	_check(board.place(Bounty.EXPLORE, null, Vector3(-20.0, 0.0, -37.0), 60) == "", "Explore 5.7 m from Rookwatch")
	var cl := board.bounties[board.bounties.size() - 1]
	_check(cl.is_claim() and cl.claim_point == p and cl.kind_name() == "Claim" and cl.claim_name() == "Rookwatch"
			and cl.target_name() == "Rookwatch", "it is a Claim of Rookwatch")
	var clid := cl.get_instance_id()
	cl.add_pursuer(c)
	c.global_position = Vector3(-20.5, 0.0, -37.0)   # at the flag
	await _wait(1.0)
	_check(not cl.ended and c.purse == 0, "a Claim does not pay on arrival")
	p.call(&"set_owner_team", 1)   # the enemy takes it: still waiting
	await _wait(0.5)
	_check(not cl.ended, "the enemy capturing it does not end the Claim")
	p.call(&"set_owner_team", 0)
	await _wait(0.1)
	_check(_reason_of(clid) == &"paid" and c.purse == 60, "paid 60 on capture (%d)" % c.purse)
	# Nobody near at the capture: refund.
	p.call(&"set_owner_team", -1)
	_check(board.place(Bounty.EXPLORE, null, Vector3(-28.0, 0.0, -45.0)) == "", "second Claim placed")
	var cl2 := board.bounties[board.bounties.size() - 1]
	var cl2id := cl2.get_instance_id()
	c.global_position = Vector3(10.0, 0.0, 10.0)
	var before := bank.essence
	_check(cl2.is_claim(), "second Claim")
	p.call(&"set_owner_team", 0, false)   # silent: the poll pays
	await _wait(0.6)
	_check(_reason_of(cl2id) == &"no_contributor" and bank.essence == before + 25,
			"Claim without a champion near refunds (%s, +%d)" % [_reason_of(cl2id), bank.essence - before])
	# Explore on water refused.
	_check(board.place(Bounty.EXPLORE, null, Vector3(-6.5, 0.0, -25.5)) == "Invalid target"
			and board.can_place(Bounty.EXPLORE, null, Vector3(-6.5, 0.0, -25.5)) == "Invalid target",
			"Explore on deep water refused")
	_check(board.can_place(Bounty.EXPLORE, null, Vector3(-30.0, 0.0, 30.0)) == "", "can_place Explore on land")
	for n: Node in [p, own, c]:
		n.queue_free()
	await _wait(0.1)


# ---------------------------------------------------------------- Den / Lodge by path

func _phase_guild_paths() -> void:
	var west_door := Vector3(-30.0, 0.0, -45.0)
	var east_door := Vector3(-4.0, 0.0, -41.0)
	var spot := Vector3(-16.0, 0.0, -41.0)
	for q: Vector3 in [west_door, east_door, spot]:
		_check(not bool(river.call(&"is_water", q)), "%s is on land" % q)
	_check(int(river.call(&"bank_of", spot)) == int(river.call(&"bank_of", west_door))
			and int(river.call(&"bank_of", spot)) != int(river.call(&"bank_of", east_door)), "banks as planned")
	var hs := GDScript.new()
	hs.source_code = HOUSE_SRC
	hs.reload()
	var dens: Array[Node3D] = []
	var lodges: Array[Node3D] = []
	for door: Vector3 in [west_door, east_door]:
		var d := Node3D.new()
		d.set_script(hs)
		level.add_child(d)
		d.global_position = door
		dens.append(d)
		var l := Node3D.new()
		l.set_script(hs)
		l.set(&"kind", &"lodge")
		level.add_child(l)
		l.global_position = door
		lodges.append(l)
	var tg := ThievesGuild.new()
	level.add_child(tg)
	var hg := HuntersGuild.new()
	level.add_child(hg)
	var straight_e := Vector2(east_door.x - spot.x, east_door.z - spot.z).length()
	var straight_w := Vector2(west_door.x - spot.x, west_door.z - spot.z).length()
	var path_e := tg.path_distance(east_door, spot)
	var path_w := tg.path_distance(west_door, spot)
	print("  den paths: east straight %.1f path %.1f, west straight %.1f path %.1f" % [straight_e, path_e, straight_w,
			path_w])
	_check(straight_e < straight_w and path_e > path_w + 2.0, "across the river the east Den is nearer by line only")
	_check(absf(hg.path_distance(east_door, spot) - path_e) < 0.01, "both guilds measure the same path")
	_check(tg.nearest_den(spot) == dens[0] and tg.nearest_den_door(spot).distance_to(west_door) < 0.01,
			"Magpies walk out of the Den nearer by path")
	_check(hg.nearest_lodge_door(spot).distance_to(west_door) < 0.01, "trackers leave the Lodge nearer by path")
	var east_spot := Vector3(0.0, 0.0, -41.0)
	_check(tg.nearest_den(east_spot) == dens[1] and hg.nearest_lodge_door(east_spot).distance_to(east_door) < 0.01,
			"same bank: the near one")
	for n: Node in dens + lodges:
		n.queue_free()
	tg.queue_free()
	hg.queue_free()


# ---------------------------------------------------------------- helpers

func _rect(center: Vector3, fp: Vector2i) -> Rect2:
	var size := Vector2(fp.x * BuildGrid.CELL, fp.y * BuildGrid.CELL)
	return Rect2(Vector2(center.x, center.z) - size * 0.5, size)


## Distance from the rect to deep water or any crossing shape, sampled every 0.05 m over the rect and its outline.
func _dense_water_distance(rect: Rect2) -> float:
	var c3 := Vector3(rect.get_center().x, 0.0, rect.get_center().y)
	var reach := rect.size.length() * 0.5
	var coarse := minf(float(river.call(&"distance_to_water", c3, 12.0)), float(river.call(&"distance_to_crossing", c3)))
	if coarse > reach + 5.0:
		return coarse - reach   # far: a lower bound is enough here
	var best := INF
	var n := int(ceil(rect.size.x / 0.05))
	var m := int(ceil(rect.size.y / 0.05))
	for i in n + 1:
		for j in m + 1:
			if i != 0 and i != n and j != 0 and j != m and (i % 10 != 0 or j % 10 != 0):
				continue
			var p := Vector3(rect.position.x + rect.size.x * i / n, 0.0, rect.position.y + rect.size.y * j / m)
			best = minf(best, float(river.call(&"distance_to_water", p, 6.0)))
			best = minf(best, float(river.call(&"distance_to_crossing", p)))
	return best


func _crossing_centre_distance(rect: Rect2) -> float:
	var best := INF
	for c: Dictionary in CROSSINGS:
		best = minf(best, _point_rect_distance(rect, c["center"]))
	return best


static func _point_rect_distance(rect: Rect2, p: Vector3) -> float:
	var dx := maxf(0.0, maxf(rect.position.x - p.x, p.x - rect.end.x))
	var dz := maxf(0.0, maxf(rect.position.y - p.z, p.z - rect.end.y))
	return Vector2(dx, dz).length()


func _unit(team: int, pos: Vector3, unit_label: String) -> Unit:
	var u := Unit.new()
	u.team = team as Unit.Team
	u.unit_name = unit_label
	level.add_child(u)
	u.global_position = pos
	u.set_physics_process(false)
	return u


func _champ(pos: Vector3, champ_name: String) -> StubChampion:
	var c := StubChampion.new()
	c.display_name = champ_name
	c.name = champ_name.replace(" ", "")
	c.add_to_group(&"champions")
	level.add_child(c)
	c.global_position = pos
	return c


func _point(pos: Vector3, point_name: String) -> Node3D:
	var p := Node3D.new()
	p.set_script(point_script)
	p.set(&"display_name", point_name)
	p.name = point_name
	level.add_child(p)
	p.global_position = pos
	return p


func _bolts() -> int:
	var n := 0
	for child in level.get_children():
		if child is Projectile:
			n += 1
	return n


## The end reason of the bounty with this instance id (&"" while it runs).
func _reason_of(id: int) -> StringName:
	return ended.get(id, &"")


func _wait(seconds: float) -> void:
	for i in roundi(seconds * 60.0):
		await physics_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		errors.append(what)
		print("  check failed: %s" % what)
