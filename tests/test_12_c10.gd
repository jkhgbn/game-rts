extends SceneTree
## Task 12.C10 (docs/design/map-fill.md 3.4 / 9 / 13 + "Done when" 12.C10): GameCritter + CritterHerds.
## Mission 1 map (no river there; a stub "river" node is added for the water phase). The test picks an open,
## unexplored area T far from every unit and runs:
##  1. contract: groups (game_critters, never units), team NEUTRAL, HP 60 / 12, radius 0.5 / 0.25, rewards, consts;
##     hidden + unclickable while no team sees the cell;
##  2. a soldier idling 5-6 m from the herd never attacks it and a tower in range never shoots it; the visible deer
##     is hit by a layer-2 area ray, the hidden rabbit is not;
##  3. an attack-move through the herd passes it (no damage), the deer flee from the visible soldier;
##  4. command_attack chases and kills a deer: +5 essence, venison +40 HP to the killer, no XP, hunted_count 1;
##  5. venison area heal 20 HP within 6 m (not at 9 m); rabbit +1 essence; grant() stores `food`, pays essence;
##  6. hidden-attacker rule: a SightMarker r 2 / 1 s reveals a hidden hunter to the team that sees the critter;
##  7. flee rule: no flee from a unit hidden from a team that sees the critter; flee once it is visible;
##  8. respawns wait while a team sees the spot / home, then happen in unseen cells (deer herd timer restarts at 120);
##  9. water: a rabbit bolting toward a (stub) river never enters the water nor leaves its bank;
## 10. the full map set (6 deer, 12 rabbits at 3.4) and the perf budget (< 0.03 ms / frame, 18 critters).
## Run:  godot --headless --path . -s tests/test_12_c10.gd --fixed-fps 60 --quit-after 12000

const TASK_ID := "12.C10"
const TIMEOUT_FRAMES := 11000
const HERDS_PATH := "res://scripts/world/critter_herds.gd"
const PERF_FRAMES := 600
const PERF_BUDGET_MS := 0.03
const NW_DEER := [Vector3(-36, 0, -53), Vector3(-52, 0, -36), Vector3(-44, 0, -30), Vector3(-30, 0, -32),
		Vector3(-56, 0, -22), Vector3(-40, 0, -50)]
const W_RABBITS := [Vector3(-30, 0, 52), Vector3(-52, 0, 22), Vector3(-24, 0, 30), Vector3(-40, 0, 8),
		Vector3(-10, 0, 47), Vector3(-54, 0, -8)]
const AREA_CANDIDATES := [Vector3(-40, 0, -40), Vector3(-44, 0, -12), Vector3(-20, 0, -44), Vector3(12, 0, 42),
		Vector3(42, 0, 10), Vector3(-48, 0, -48), Vector3(20, 0, 20), Vector3(-15, 0, -20), Vector3(45, 0, 45),
		Vector3(-50, 0, 10), Vector3(0, 0, -45), Vector3(48, 0, -10)]

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _phase := 0
var _pt := 0
var _done := false

var herds: Node
var fog: Node
var bank: Node
var T := Vector3.ZERO
var S: Unit
var W2: Unit
var W3: Unit
var E: Unit
var tower: Node3D
var deer0: Node3D
var deer1: Node3D
var deer2: Node3D
var rabbit: Node3D
var river: Node
var _fled := {}          # critter -> count
var _hunted: Array = []  # [critter, team, by]
var _essence0 := 0
var _s_xp := 0
var _s_level := 1
var _hit_seen := false
var _flee_after_hit := false
var _marker_pos := Vector3.ZERO
var _dir := Vector3.RIGHT
var _deer2_fled0 := 0
var _alive0 := 0
var _perf_on := false
var _perf_frames := 0
var _perf_usec := 0
var _perf_moves := 0
var _perf_think_usec := 0
var _window_usec := 0
var _windows: Array[float] = []
const PERF_WINDOW := 100
var _perf_queries := 0


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
	frame += 1
	if frame < 5:
		return false   # let the navmesh sync
	_pt += 1
	_step()
	if _done:
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for e in _errors:
				print("  - " + e)
			print("FAIL %s: %d problem(s)" % [TASK_ID, _errors.size()])
		return true
	if frame > TIMEOUT_FRAMES:
		for e in _errors:
			print("  - " + e)
		print("FAIL %s: timed out in phase %d" % [TASK_ID, _phase])
		return true
	return false


func _physics_process(delta: float) -> bool:
	if not _perf_on or herds == null or not is_instance_valid(herds):
		return false
	# Drive the herds by hand to time exactly its per-frame work (think + moves).
	# The movers (what the critters' own physics process would advance) are picked outside the timing.
	herds.set_physics_process(false)
	var all: Array = herds.all_critters()
	var movers: Array = []
	for c in all:
		var st: StringName = c.state()
		if st == &"move" or st == &"flee":
			movers.append(c)
	_perf_moves += movers.size()
	var t0 := Time.get_ticks_usec()
	herds._physics_process(delta)
	_perf_think_usec += Time.get_ticks_usec() - t0
	for c in movers:
		c.advance(delta)
	var spent := Time.get_ticks_usec() - t0
	_perf_usec += spent
	_window_usec += spent
	if (_perf_frames + 1) % PERF_WINDOW == 0:
		_windows.append(float(_window_usec) / 1000.0 / float(PERF_WINDOW))
		_window_usec = 0
	for c in all:
		c.set_physics_process(false)
	_perf_frames += 1
	return false


func _next(p: int) -> void:
	_phase = p
	_pt = 0


func _err(msg: String) -> void:
	_errors.append("[phase %d] %s" % [_phase, msg])


func _step() -> void:
	match _phase:
		0:
			_setup_area()
		1:
			if _pt == 30:
				_check_hidden_start()
				_next(2)
		2:
			_phase_idle()
		3:
			_phase_attack_move()
		4:
			_phase_hunt()
		5:
			_phase_rewards()
		6:
			_phase_reveal()
		7:
			_phase_flee_hidden()
		8:
			_phase_flee_visible()
		9:
			_phase_respawn()
		10:
			_phase_water()
		11:
			_phase_full_map()
		12:
			_phase_perf()


# ================================================================ helpers

func _spawn_unit(id: String, pos: Vector3, team: int) -> Unit:
	var u: Unit = main.make_unit(id)
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _open(center: Vector3, r: float) -> bool:
	var map: RID = main.get_world_3d().navigation_map
	var total := 0
	var ok := 0
	var x := -r
	while x <= r:
		var z := -r
		while z <= r:
			if x * x + z * z <= r * r:
				total += 1
				var p := center + Vector3(x, 0.0, z)
				if _flat(NavigationServer3D.map_get_closest_point(map, p), p) < 0.3:
					ok += 1
			z += 2.0
		x += 2.0
	return total > 0 and float(ok) / float(total) >= 0.92


func _nearest_unit_distance(p: Vector3) -> float:
	var best := INF
	for n in get_nodes_in_group("units"):
		var u := n as Unit
		if u:
			best = minf(best, _flat(u.global_position, p))
	for n in get_nodes_in_group("buildings"):
		var b := n as Node3D
		if b:
			best = minf(best, _flat(b.global_position, p))
	return best


func _on_fled(c: Node3D) -> void:
	_fled[c] = int(_fled.get(c, 0)) + 1


func _on_hunted(c: Node3D, team: int, reward: Dictionary) -> void:
	_hunted.append([c, team, reward])


func _new_herds(herd_list: Array, homes: Array) -> Node:
	var h: Node = load(HERDS_PATH).new()
	h.name = "CritterHerds"
	main.add_child(h)
	h.setup(herd_list, homes)
	h.critter_hunted.connect(_on_hunted)
	for c in h.all_critters():
		c.fled.connect(_on_fled)
	return h


func _alive_deer() -> Array:
	return herds.critters(&"deer")


func _markers(team: int) -> Array:
	var out: Array = []
	for n in get_nodes_in_group("fog_sources"):
		if n.name.begins_with("CritterRevealMarker") and int(n.get(&"team")) == team and n.is_inside_tree():
			out.append(n)
	return out


func _essence() -> int:
	return int(bank.get(&"essence"))


func _area_of(c: Node3D) -> Area3D:
	return c.get_node_or_null(^"ClickArea") as Area3D


func _ray_hits(c: Node3D) -> bool:
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	var p := c.global_position
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 12, 0), p + Vector3(0, -1, 0), 2)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return false
	var n: Node = hit.get("collider") as Node
	return n != null and n.get_parent() == c


# ================================================================ phases

func _setup_area() -> void:
	fog = get_first_node_in_group("fog")
	bank = EssenceBank.for_team(0)
	bank.trickle_enabled = false
	EssenceBank.for_team(1).trickle_enabled = false
	for cand: Vector3 in AREA_CANDIDATES:
		if _nearest_unit_distance(cand) < 32.0 or not _open(cand, 11.0) or not _open(cand + Vector3(22, 0, 0), 3.0):
			continue
		if fog.is_explored(0, cand) or fog.is_explored(0, cand + Vector3(22, 0, 0)):
			continue
		T = cand
		break
	if T == Vector3.ZERO:
		_err("no open unexplored test area found")
		_done = true
		return
	print("test area T = %s" % T)
	main.camera_rig.edge_pan_enabled = false   # the headless mouse sits in a corner
	main.camera_rig.focus_on(T)   # critters away from the camera view stay hidden (CritterHerds culls them)
	herds = _new_herds([{"id": &"h1", "spots": [T, T + Vector3(10, 0, 0), T + Vector3(0, 0, 10)]}],
			[T + Vector3(22, 0, 0)])
	var cls: GDScript = load(HERDS_PATH)
	if herds.get_script() != cls or cls.instance(self) != herds:
		_err("CritterHerds.instance(tree) does not find the herds")
	if not herds.is_in_group(&"critter_herds"):
		_err("herds not in group critter_herds")
	if cls.REWARDS != {&"deer": {&"essence": 5}, &"rabbit": {&"essence": 1}}:
		_err("REWARDS %s" % str(cls.REWARDS))
	if cls.VENISON_HEAL != 40.0 or cls.VENISON_AREA_HEAL != 20.0:
		_err("venison consts %s / %s" % [cls.VENISON_HEAL, cls.VENISON_AREA_HEAL])
	var deer: Array = herds.critters(&"deer")
	var rabbits: Array = herds.critters(&"rabbit")
	if deer.size() != 3 or rabbits.size() != 1 or herds.critters().size() != 4:
		_err("counts deer %d rabbits %d" % [deer.size(), rabbits.size()])
		_done = true
		return
	rabbit = rabbits[0]
	for c in herds.all_critters():
		if c.is_in_group(&"units") or c.is_in_group(&"buildings") or not c.is_in_group(&"game_critters"):
			_err("%s groups wrong" % c.name)
		if int(c.team) != Unit.Team.NEUTRAL or not c.is_alive() or not c.is_game_critter():
			_err("%s team / alive / is_game_critter" % c.name)
		var is_deer: bool = c.kind == &"deer"
		if not is_equal_approx(c.max_hp, 60.0 if is_deer else 12.0) or not is_equal_approx(c.hp, c.max_hp):
			_err("%s hp %s / %s" % [c.name, c.hp, c.max_hp])
		if not is_equal_approx(c.target_radius(), 0.5 if is_deer else 0.25):
			_err("%s target_radius %s" % [c.name, c.target_radius()])
		if c.reward != ({&"essence": 5} if is_deer else {&"essence": 1}):
			_err("%s reward %s" % [c.name, str(c.reward)])
		if c.is_fleeing():
			_err("%s fleeing at start" % c.name)
		var model: Node = c.get_node_or_null(^"Model")
		if model == null or not model.has_method(&"play_flee"):
			_err("%s has no CritterModel child 'Model'" % c.name)
		var area := _area_of(c)
		if area == null or area.collision_mask != 0:
			_err("%s click area missing / mask not 0" % c.name)
	var stags := 0
	for d in deer:
		if bool(d.get_node(^"Model").get(&"antlers")):
			stags += 1
	if stags != 1:
		_err("herd stags %d (want 1 stag + 2 hinds)" % stags)
	_next(1)


func _check_hidden_start() -> void:
	for c in herds.all_critters():
		if c.visible:
			_err("%s visible in an unexplored cell" % c.name)
		if _area_of(c).collision_layer != 0:
			_err("%s clickable while hidden (layer %d)" % [c.name, _area_of(c).collision_layer])
	# A soldier idling 5-6 m from the herd, and a tower 7 m away.
	S = _spawn_unit("flame_guard", T + Vector3(0, 0, 6.5), 0)
	S.command_stop()
	var tt: Resource = BuildingType.find("fire_tower")
	tower = main.build_grid.spawn_complete(tt, T + Vector3(-7, 0, 0), 0)


func _phase_idle() -> void:
	if S.attack_target != null:
		_err("an idle soldier targeted %s" % S.attack_target.name)
		S.command_stop()
	if tower != null and is_instance_valid(tower) and tower.get(&"attack_target") != null:
		_err("the tower targeted %s" % tower.get(&"attack_target").name)
	for d in _alive_deer():
		if d.hp < d.max_hp:
			_err("%s was hurt by an idle soldier / tower" % d.name)
	if _pt < 180:
		return
	var seen := 0
	for d in _alive_deer():
		if d.visible:
			seen += 1
			if _area_of(d).collision_layer != 2:
				_err("%s visible but its click area is off" % d.name)
			if not _ray_hits(d):
				_err("a layer-2 area ray misses the visible %s" % d.name)
	if seen == 0:
		_err("no deer visible next to the soldier (camera view %s, fog %s)" % [herds._camera_view(),
				fog.is_visible(0, _alive_deer()[0].global_position)])
	if rabbit.visible or _ray_hits(rabbit):
		_err("the hidden rabbit is visible / clickable")
	if tower != null and is_instance_valid(tower):
		tower.queue_free()
	S.command_attack_move(T + Vector3(0, 0, -12))
	_next(3)


func _phase_attack_move() -> void:
	if S.attack_target != null and S.attack_target.has_method(&"is_game_critter"):
		_err("the attack-move targeted a critter")
	for d in herds.all_critters():
		if d.hp < d.max_hp:
			_err("%s hurt during the attack-move" % d.name)
	if _flat(S.global_position, T + Vector3(0, 0, -12)) > 1.5 and _pt < 600:
		return
	if _pt >= 600:
		_err("the attack-move never arrived")
	var fled := 0
	for d in _fled:
		fled += int(_fled[d])
	if fled == 0:
		_err("no deer fled from the visible soldier walking through the herd")
	# Hunt: an explicit attack order.
	S.hp = 50.0
	_s_xp = S.xp
	_s_level = S.level
	_essence0 = _essence()
	var best := INF
	for d in _alive_deer():
		var dist := _flat(d.global_position, S.global_position)
		if dist < best:
			best = dist
			deer0 = d
	S.command_attack(deer0)
	if S.attack_target != deer0:
		_err("command_attack(deer) was refused")
	_next(4)


func _phase_hunt() -> void:
	if not _hit_seen and deer0.hp < deer0.max_hp:
		_hit_seen = true
		_flee_after_hit = deer0.is_fleeing()
		if not _flee_after_hit:
			_err("the deer did not flee when hit")
	if deer0.is_alive() and _pt < 2400:
		return
	if deer0.is_alive():
		_err("command_attack never killed the deer (hp %s)" % deer0.hp)
		_done = true
		return
	print("deer hunted in %.1f s" % (_pt / 60.0))
	for d in herds.all_critters():
		var y: float = d.global_position.y
		if y < -0.1 or y > 0.35:
			_err("%s floats / sinks after moving: y %.2f" % [d.name, y])
	if _hunted.size() != 1 or _hunted[0][0] != deer0 or int(_hunted[0][1]) != 0:
		_err("critter_hunted %s" % str(_hunted))
	if _essence() != _essence0 + 5:
		_err("deer essence %d -> %d (want +5)" % [_essence0, _essence()])
	if not is_equal_approx(S.hp, 90.0):
		_err("venison: killer hp %s (want 50 + 40)" % S.hp)
	if S.xp != _s_xp or S.level != _s_level:
		_err("the hunter gained XP / levels (%d -> %d)" % [_s_xp, S.xp])
	if int(herds.hunted_count(0)) != 1 or int(herds.hunted_count(1)) != 0:
		_err("hunted_count %d / %d" % [herds.hunted_count(0), herds.hunted_count(1)])
	if deer0.killer != S or int(deer0.killer_team) != 0:
		_err("killer / killer_team")
	if _area_of(deer0).collision_layer != 0 or herds.critters(&"deer").has(deer0):
		_err("a dead deer is still clickable / listed")
	var left: float = herds.deer_respawn_left(&"h1")
	if left <= 100.0 or left > 120.0:
		_err("deer respawn timer %s (want ~120)" % left)
	_next(5)


func _phase_rewards() -> void:
	if _pt == 1:
		deer1 = _alive_deer()[0]
		S.hp = 50.0
		W2 = _spawn_unit("flame_guard", deer1.global_position + Vector3(1.5, 0, 0), 0)
		W3 = _spawn_unit("flame_guard", deer1.global_position + Vector3(9.0, 0, 0), 0)
		W2.hp = 60.0
		W3.hp = 60.0
		_essence0 = _essence()
		deer1.take_damage(999.0, S)
		if deer1.is_alive():
			_err("deer1 survived 999 damage")
		if not is_equal_approx(S.hp, 90.0) or not is_equal_approx(W2.hp, 80.0) or not is_equal_approx(W3.hp, 60.0):
			_err("venison heals: killer %s (90) / 1.5 m %s (80) / 9 m %s (60)" % [S.hp, W2.hp, W3.hp])
		if _essence() != _essence0 + 5:
			_err("deer1 essence +%d" % (_essence() - _essence0))
		# Rabbit: +1.
		_essence0 = _essence()
		rabbit.take_damage(999.0, S)
		if _essence() != _essence0 + 1:
			_err("rabbit essence +%d (want 1)" % (_essence() - _essence0))
		if int(herds.hunted_count(0)) != 3:
			_err("hunted_count %d (want 3)" % herds.hunted_count(0))
		if not is_equal_approx(float(herds.rabbit_respawn_left(rabbit)), 90.0):
			_err("rabbit respawn timer %s (want 90)" % herds.rabbit_respawn_left(rabbit))
		# grant(): known keys paid, every key stored (step 15 food).
		_essence0 = _essence()
		herds.grant(0, {&"essence": 5, &"food": 10}, S)
		herds.grant(2, {&"essence": 50}, null)
		if _essence() != _essence0 + 5:
			_err("grant essence +%d" % (_essence() - _essence0))
		var totals: Dictionary = herds.granted_totals.get(0, {})
		if int(totals.get(&"food", 0)) != 10 or int(totals.get(&"essence", 0)) != 16:
			_err("granted_totals %s (want food 10, essence 16)" % str(totals))
		if herds.granted_totals.has(2):
			_err("grant paid the neutral team")
		W3.queue_free()
		return
	if _pt == 30:
		# 6. Hidden hunter: an enemy shade 16 m beyond the deer, the soldier on the near side.
		deer2 = _alive_deer()[0]
		_dir = Vector3.RIGHT
		S.global_position = deer2.global_position - _dir * 3.0
		W2.global_position = deer2.global_position - _dir * 4.5
		S.command_hold()
		W2.command_hold()
		E = _spawn_unit("shade", deer2.global_position + _dir * 16.0, 1)
		E.command_hold()
		_next(6)


func _phase_reveal() -> void:
	if _pt == 20:
		if not fog.is_visible(0, deer2.global_position) or fog.is_visible(0, E.global_position):
			_err("reveal setup: deer seen %s, shade seen %s" % [fog.is_visible(0, deer2.global_position),
					fog.is_visible(0, E.global_position)])
		var before := _markers(0).size()
		_marker_pos = E.global_position
		deer2.take_damage(5.0, E)
		var after := _markers(0)
		if after.size() != before + 1:
			_err("hidden hunter: %d new markers for the player (want 1)" % (after.size() - before))
		else:
			var m: Node3D = after[after.size() - 1]
			if _flat(m.global_position, _marker_pos) > 0.1 or not is_equal_approx(float(m.get(&"sight_radius")), 2.0) \
					or not is_equal_approx(float(m.get(&"lifetime")), 1.0):
				_err("marker at %s r %s t %s" % [m.global_position, m.get(&"sight_radius"), m.get(&"lifetime")])
		if not _markers(1).is_empty():
			_err("a marker for the attacker's own team")
		# A visible attacker never makes a marker.
		var n0 := _markers(0).size() + _markers(1).size()
		deer2.take_damage(1.0, S)
		if _markers(0).size() + _markers(1).size() != n0:
			_err("a visible attacker created a marker")
		return
	if _pt == 34:
		if not fog.is_visible(0, _marker_pos):
			_err("the hidden hunter's spot was not revealed")
		return
	if _pt == 110:
		if not _markers(0).is_empty():
			_err("the reveal marker outlived 1 s")
		_deer2_fled0 = int(_fled.get(deer2, 0))
		_next(7)


func _place_flee_test(soldier_gap: float) -> void:
	var p := deer2.global_position
	E.global_position = p + _dir * 3.2
	S.global_position = p - _dir * soldier_gap
	W2.global_position = p - _dir * (soldier_gap + 1.5)


var _settled := 0
var _window := -1   # frames since the hidden-shade window opened (-1 = still settling)


func _phase_flee_hidden() -> void:
	if _window < 0:
		# Settle: the soldier 9 m on one side, the shade 25 m away, until deer2 stood still for 0.5 s.
		_place_flee_test(9.0)
		E.global_position = deer2.global_position + _dir * 25.0
		# > RESTARTLE_TIME (3 s) since its last sprint, so the window really tests the visibility rule.
		_settled = _settled + 1 if not deer2.is_fleeing() else 0
		if _settled >= 200:
			_window = 0
			_deer2_fled0 = int(_fled.get(deer2, 0))
		elif _pt > 1500:
			_err("deer2 never calmed down")
			_next(8)
		return
	# Window: the shade 3.2 m from the deer, hidden from the player who sees the deer (soldier 9 m away).
	_window += 1
	_place_flee_test(9.0)
	if deer2.is_fleeing() or int(_fled.get(deer2, 0)) != _deer2_fled0:
		_err("deer2 fled from a shade the player cannot see (deer seen %s, shade seen %s)"
				% [fog.is_visible(0, deer2.global_position), fog.is_visible(0, E.global_position)])
		_deer2_fled0 = int(_fled.get(deer2, 0))
		_next(8)
		return
	if _window == 80:
		if not fog.is_visible(0, deer2.global_position) or fog.is_visible(0, E.global_position):
			_err("hidden-flee setup: deer seen %s, shade seen %s" % [fog.is_visible(0, deer2.global_position),
					fog.is_visible(0, E.global_position)])
		_deer2_fled0 = int(_fled.get(deer2, 0))
		_next(8)


func _phase_flee_visible() -> void:
	if int(_fled.get(deer2, 0)) > _deer2_fled0:
		_start_respawn_phase()
		return
	_place_flee_test(5.0)
	if _pt > 300:   # up to RESTARTLE_TIME (3 s) after its last sprint, + one 5 Hz think
		_err("deer2 never fled from a visible shade within 3.2 m")
		_start_respawn_phase()


func _start_respawn_phase() -> void:
	E.queue_free()
	E = null
	S.global_position = T + Vector3(3, 0, 3)
	W2.global_position = rabbit.home + Vector3(2, 0, 0)
	_next(9)


func _phase_respawn() -> void:
	if _pt == 30:
		_alive0 = _alive_deer().size()
		herds._herds[0]["respawn_left"] = 0.3
		herds._rabbit_left[rabbit] = 0.3
		return
	if _pt == 60:
		if _alive_deer().size() != _alive0:
			_err("a deer respawned in a seen cell")
		var left: float = herds.deer_respawn_left(&"h1")
		if left < 3.0 or left > 5.0:
			_err("seen spots: deer retry timer %s (want ~5)" % left)
		if rabbit.is_alive():
			_err("the rabbit respawned in a seen cell")
		elif float(herds.rabbit_respawn_left(rabbit)) < 3.0:
			_err("seen home: rabbit retry %s" % herds.rabbit_respawn_left(rabbit))
		S.global_position = Vector3(-36, 0, 36)
		W2.global_position = Vector3(-34, 0, 36)
		S.command_stop()
		W2.command_stop()
		return
	if _pt == 90:
		herds._herds[0]["respawn_left"] = 0.3
		herds._rabbit_left[rabbit] = 0.3
		return
	if _pt == 140:
		var alive := _alive_deer()
		if alive.size() != _alive0 + 1:
			_err("no deer respawn in unseen spots (%d alive, was %d)" % [alive.size(), _alive0])
		for d in alive:
			if d.hp != d.max_hp:
				continue
			if d != deer2 and fog.is_visible(0, d.global_position):
				_err("a respawned deer stands in a visible cell")
		var left: float = herds.deer_respawn_left(&"h1")
		if left < 100.0 or left > 120.0:
			_err("herd still short: next deer timer %s (want ~120)" % left)
		if not rabbit.is_alive() or _flat(rabbit.global_position, rabbit.home) > 0.5 or rabbit.hp != 12.0:
			_err("rabbit respawn at home: alive %s pos %s" % [rabbit.is_alive(), rabbit.global_position])
		_setup_water()


func _setup_water() -> void:
	herds.queue_free()
	herds = null
	var src := GDScript.new()
	src.source_code = """extends Node
var x0 := 0.0
var x1 := 0.0
func is_water(p: Vector3) -> bool:
	return p.x > x0 and p.x < x1
func is_ford(_p: Vector3) -> bool:
	return false
func is_bridge(_p: Vector3) -> bool:
	return false
func bank_of(p: Vector3) -> int:
	if p.x <= x0:
		return 0
	if p.x >= x1:
		return 1
	return -1
"""
	src.reload()
	river = Node.new()
	river.set_script(src)
	river.set(&"x0", T.x + 2.0)
	river.set(&"x1", T.x + 6.0)
	river.add_to_group(&"river")
	main.add_child(river)
	_next(10)


func _phase_water() -> void:
	if _pt == 2:
		herds = _new_herds([], [T])
		rabbit = herds.critters(&"rabbit")[0]
		S.global_position = T - Vector3(3, 0, 0)
		return
	if _pt == 8:
		rabbit.take_damage(1.0, S)
		if not rabbit.is_fleeing():
			_err("water: the rabbit did not bolt")
		return
	if _pt > 8:
		var p: Vector3 = rabbit.global_position
		if river.is_water(p) or river.bank_of(p) != 0:
			_err("water: the rabbit entered the water / left its bank at %s" % p)
			_pt = 200
	if _pt == 150:
		if _flat(rabbit.global_position, T) < 2.0:
			_err("water: the rabbit barely moved (%s)" % rabbit.global_position)
	if _pt >= 150:
		herds.queue_free()
		herds = null
		river.queue_free()
		S.global_position = Vector3(-36, 0, 36)
		_next(11)


func _phase_full_map() -> void:
	if _pt < 3:
		return
	var se: Array = []
	for p: Vector3 in NW_DEER:
		se.append(-p)
	var homes: Array[Vector3] = []
	for p: Vector3 in W_RABBITS:
		homes.append(p)
	for p: Vector3 in W_RABBITS:
		homes.append(-p)
	var herd_list: Array[Dictionary] = [{"id": &"deer_nw", "spots": NW_DEER}, {"id": &"deer_se", "spots": se}]
	herds = _new_herds(herd_list, homes)
	var deer: Array = herds.critters(&"deer")
	var rabbits: Array = herds.critters(&"rabbit")
	if deer.size() != 6 or rabbits.size() != 12:
		_err("full map: %d deer / %d rabbits (want 6 / 12)" % [deer.size(), rabbits.size()])
	var in_units := 0
	for n in get_nodes_in_group("units"):
		if n.has_method(&"is_game_critter"):
			in_units += 1
	if in_units != 0:
		_err("%d critters in 'units'" % in_units)
	for i: int in 12:
		if _flat(rabbits[i].global_position, homes[i]) > 1.0:   # snapped to the navmesh (mission-1 trees)
			_err("rabbit %d at %s (home %s)" % [i, rabbits[i].global_position, homes[i]])
	for d in deer:
		var spot0: Vector3 = NW_DEER[0] if d.herd_id == &"deer_nw" else -NW_DEER[0]
		if _flat(d.global_position, spot0) > 2.0:
			_err("%s starts %.1f m from its herd's first spot" % [d.name, _flat(d.global_position, spot0)])
	main.camera_rig.focus_on(Vector3(-36, 0, 36))   # over the player's base: its meadow rabbits are in view
	_perf_on = true
	_next(12)


func _phase_perf() -> void:
	if _perf_frames < PERF_FRAMES:
		return
	_perf_on = false
	var ms := float(_perf_usec) / 1000.0 / float(_perf_frames)
	print("perf: think+herds %.4f ms / frame" % (float(_perf_think_usec) / 1000.0 / float(_perf_frames)))
	print("perf: %.4f ms / frame for %d critters over %d frames (%d critter-move frames)"
			% [ms, herds.all_critters().size(), _perf_frames, _perf_moves])
	# Similar work in every window (a deterministic run): the quietest window is the cost without the
	# CPU contention of other Godot processes running in parallel.
	var best := INF
	for w: float in _windows:
		best = minf(best, w)
	print("perf: 100-frame windows %s -> best %.4f ms / frame" % [str(_windows), best])
	if best >= PERF_BUDGET_MS:
		_err("perf %.4f ms / frame in the best window (budget %.2f)" % [best, PERF_BUDGET_MS])
	_done = true
