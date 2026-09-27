extends SceneTree
## Task 12.C6 (docs/design/ui-mapfill.md 3, 3.1, 4.1, 7.1, 9 + "Done when" 12.C6) on the real skirmish (map fill on,
## bot off):
##  1. minimap: water / fords / bridges texture from mask_image(), the 8 points (held counts), own tower sight rings,
##     lairs once explored + the known-alive paw, the BEAST ping on beast_spawned, visible beasts as paws, camps in
##     their tier colours with the cleared outline from the camp memory, the awake-shrine count;
##  2. capture rings: one per point at y 0.20 with the quad 2 (r + 0.6), the looks of section 3 (neutral dashes, held
##     solid + glow, the arc and the contested flash only where visible, asleep / awake shrines, selected width x 1.5);
##  3. camp memory (unknown / alive / cleared, known_cleared on camp_cleared, reset on respawned) and the floating
##     `m:ss` Label3D (visible spot only);
##  4. clicks: a watchtower body, a shrine click area, the ground near a well -> selected_neutral +
##     neutral_building_clicked; Esc clears; right click on a point = a ground move;
##  5. critters: left click = selected_neutral + signal (dropped when it dies); right click / X-click with a soldier,
##     a worker and a caravan selected: only the soldier gets command_attack on the deer; can_hunt refuses
##     workers / caravans / trackers; the hunt cursor + red ring while hovering with hunters, not with workers only;
##  6. nothing in scripts/ui (nor capture_rings.gd) calls a `_private` function of another object.
## Run:  godot --headless --path . -s tests/test_12_c6.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "12.C6"
const TIMEOUT_FRAMES := 8500
const SCENE := "res://scenes/skirmish.tscn"
const RINGS_PATH := "res://scripts/vfx/capture_rings.gd"
const FLAGS := ["river_enabled", "points_enabled", "camps_enabled", "beasts_enabled"]
const OWN := Color(0.3, 1.0, 0.4)
const ENEMY := Color(1.0, 0.3, 0.3)
const GOLD := Color(1.0, 0.85, 0.4)

var main: Node
var sel: Node
var hud: Node
var minimap: Node
var fog: Node
var svc: Node
var rings: Node
var total := 0
var _done := false
var _errors: Array[String] = []
var _clicked: Array = []


func _initialize() -> void:
	_run()


func _process(_delta: float) -> bool:
	total += 1
	if total > TIMEOUT_FRAMES and not _done:
		_errors.append("timed out at frame %d" % total)
		return _finish()
	return _done


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in _errors:
			print("  - ", e)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _errors.size()])
	_done = true
	return true


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if bool(cond.call()):
			return true
		await process_frame
	return bool(cond.call())


func _near_c(a: Color, b: Color, eps := 0.02) -> bool:
	return absf(a.r - b.r) < eps and absf(a.g - b.g) < eps and absf(a.b - b.b) < eps and absf(a.a - b.a) < eps


func _point(id: StringName) -> Node3D:
	return svc.call(&"point_by_id", id)


func _on_neutral_clicked(n: Node3D) -> void:
	_clicked.append(n)


# ---------------------------------------------------------------- the run

func _run() -> void:
	await _frames(1)
	main = load(SCENE).instantiate()
	for f in FLAGS:
		main.set(f, true)
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	if not await _until(func() -> bool: return main.hero != null, 5000):
		_errors.append("navigation never finished baking")
		_finish()
		return
	root.size = Vector2i(1600, 900)   # headless starts at 64 x 64: the HUD would cover every click
	await _frames(5)
	sel = main.selection
	hud = main.hud
	minimap = hud.minimap
	fog = main.fog
	svc = get_first_node_in_group(&"capture_points_service")
	main.camera_rig.edge_pan_enabled = false
	if svc == null or svc.call(&"points").size() != 8:
		_errors.append("no CapturePoints with 8 points on the skirmish")
		_finish()
		return
	svc.set_physics_process(false)   # the test drives the point fields itself
	sel.neutral_building_clicked.connect(_on_neutral_clicked)
	_attach_rings()
	await _test_minimap()
	await _test_rings()
	await _test_camps()
	await _test_point_clicks()
	await _test_critters()
	_test_no_private_calls()
	_finish()


func _attach_rings() -> void:
	var script: GDScript = load(RINGS_PATH)
	rings = script.attach(hud, sel)
	_check(rings != null and rings.is_inside_tree() and rings.is_in_group(&"capture_rings"),
			"CaptureRings.attach made no node in group capture_rings")
	_check(rings != null and rings.get_parent() == main, "CaptureRings is not a child of the level")
	var again: Node = script.attach(hud, sel)
	_check(again == rings and get_nodes_in_group(&"capture_rings").size() == 1, "a second attach made a second node")


# ---------------------------------------------------------------- 1. minimap

func _test_minimap() -> void:
	await _frames(12)
	_check(bool(minimap.water_drawn), "minimap: the river mask texture was never drawn")
	_check(minimap.drawn_points == 8, "minimap: %d points drawn (want 8, explored from 0:00)" % minimap.drawn_points)
	_check(minimap.drawn_held_points == 0 and minimap.drawn_sight_rings == 0, "minimap: held points / sight rings at start")
	var rook := _point(&"tower_nw")
	var salt := _point(&"tower_n")
	rook.call(&"set_owner_team", 0)
	salt.call(&"set_owner_team", 1)
	await _frames(8)
	_check(minimap.drawn_held_points == 2, "minimap: held points %d (want 2)" % minimap.drawn_held_points)
	_check(minimap.drawn_sight_rings == 1, "minimap: sight rings %d (want 1: own towers only)" % minimap.drawn_sight_rings)
	# Lairs and camps once explored.
	var eb: Node = get_first_node_in_group(&"epic_beasts")
	var lairs: Array = eb.call(&"lairs")
	for l: Dictionary in lairs:
		fog.reveal(0, l["center"], 3.0)
	for c in get_nodes_in_group(&"neutral_camps"):
		fog.reveal(0, (c as Node3D).global_position, 3.0)
	await _frames(8)
	_check(minimap.drawn_lairs == lairs.size() and lairs.size() == 8, "minimap: lairs %d of %d" % [minimap.drawn_lairs, lairs.size()])
	_check(minimap.drawn_lair_paws == 0, "minimap: lair paw before any beast")
	var ncamps := get_nodes_in_group(&"neutral_camps").size()
	_check(ncamps == 8 and minimap.drawn_camps == ncamps, "minimap: camps %d of %d" % [minimap.drawn_camps, ncamps])
	# A beast spawns: ping + known-alive paw; hidden by the fog = no beast paw; fog off = the paw.
	var lair_id: StringName = lairs[0]["id"]
	var pings0: int = minimap.beast_pings
	var beast: Node = eb.call(&"spawn_now", lair_id)
	_check(beast != null, "spawn_now returned no beast")
	await _frames(8)
	_check(minimap.beast_pings == pings0 + 1, "minimap: no BEAST ping on beast_spawned")
	_check(minimap.lair_known_alive(lair_id) and minimap.drawn_lair_paws == 1, "minimap: known-alive lair paw missing")
	if beast != null and not (beast as Node3D).is_visible_in_tree():
		_check(minimap.drawn_beasts == 0, "minimap: a fogged beast drawn")
	fog.enabled = false
	await _frames(8)
	_check(minimap.drawn_beasts == 1, "minimap: visible beast paws %d (want 1)" % minimap.drawn_beasts)
	# Awake shrine.
	_point(&"shrine_w").call(&"wake")
	await _frames(8)
	_check(minimap.drawn_awake_shrines == 1, "minimap: awake shrines %d (want 1)" % minimap.drawn_awake_shrines)
	# The beast dies: the paw goes.
	if beast != null:
		var killer: Unit = main.make_unit("flame_guard")
		killer.team = 0
		main.add_child(killer)
		killer.global_position = Vector3(0, 0, 58)
		killer.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
		killer.process_mode = Node.PROCESS_MODE_DISABLED
		beast.call(&"take_damage", 999999.0, killer)
		await _frames(8)
		_check(not minimap.lair_known_alive(lair_id) and minimap.drawn_lair_paws == 0, "minimap: lair paw after beast_slain")
		killer.queue_free()
	fog.enabled = true
	await _frames(4)


# ---------------------------------------------------------------- 2. rings

func _test_rings() -> void:
	rings.call(&"refresh_now")
	_check(int(rings.call(&"ring_count")) == 8, "rings: %d (want 8)" % rings.call(&"ring_count"))
	for p: Node3D in svc.call(&"points"):
		var mesh: MeshInstance3D = rings.call(&"ring_of", p)
		if mesh == null:
			_check(false, "rings: no ring for %s" % p.name)
			continue
		var r := float(p.get(&"capture_radius"))
		_check(absf(mesh.global_position.y - 0.20) < 0.01 and Vector2(mesh.global_position.x - p.global_position.x,
				mesh.global_position.z - p.global_position.z).length() < 0.01, "rings: %s ring position" % p.name)
		var q := mesh.mesh as QuadMesh
		_check(q != null and absf(q.size.x - 2.0 * (r + 0.6)) < 0.01, "rings: %s quad size" % p.name)
		_check(mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "rings: %s casts shadows" % p.name)
	var mill := _point(&"tower_s")
	var look: Dictionary = rings.call(&"ring_look", mill)
	_check(_near_c(look["color"], Color(0.85, 0.85, 0.85, 0.40)) and float(look["dashes"]) == 24.0 and float(look["glow"]) == 0.0,
			"rings: neutral look %s" % look)
	var rook := _point(&"tower_nw")
	look = rings.call(&"ring_look", rook)
	_check(_near_c(look["color"], Color(OWN, 0.70)) and float(look["dashes"]) == 0.0 and float(look["glow"]) == 1.0,
			"rings: own-held look %s" % look)
	look = rings.call(&"ring_look", _point(&"tower_n"))
	_check(_near_c(look["color"], Color(ENEMY, 0.70)), "rings: enemy-held look %s" % look)
	# The arc and the flash only where the player sees the point.
	var hidden_pt: Node3D = null
	for p: Node3D in svc.call(&"points"):
		if StringName(p.get(&"kind")) == &"watchtower" and not fog.is_visible(0, p.global_position) and p != rook:
			hidden_pt = p
			break
	_check(hidden_pt != null, "rings: no fogged watchtower to test the arc rule")
	if hidden_pt != null:
		hidden_pt.set(&"capture_team", 1)
		hidden_pt.set(&"progress", 0.5)
		hidden_pt.set(&"state", &"contested")
		rings.call(&"refresh_now")
		look = rings.call(&"ring_look", hidden_pt)
		_check(float(look["progress"]) == 0.0 and float(look["flash_hz"]) == 0.0, "rings: arc / flash shown in the fog %s" % look)
		fog.enabled = false
		rings.call(&"refresh_now")
		look = rings.call(&"ring_look", hidden_pt)
		_check(absf(float(look["progress"]) - 0.5) < 0.001 and _near_c(look["arc_color"], Color(ENEMY, 0.9)),
				"rings: visible enemy capture arc %s" % look)
		_check(float(look["flash_hz"]) == 3.0 and absf((look["color"] as Color).a - 0.9) < 0.01,
				"rings: contested flash %s" % look)
		hidden_pt.set(&"state", &"capturing")
		hidden_pt.set(&"capture_team", 0)
		rings.call(&"refresh_now")
		look = rings.call(&"ring_look", hidden_pt)
		_check(_near_c(look["arc_color"], Color(OWN, 0.9)) and float(look["flash_hz"]) == 0.0, "rings: own capture arc %s" % look)
		hidden_pt.set(&"capture_team", -1)
		hidden_pt.set(&"progress", 0.0)
		hidden_pt.set(&"state", &"idle")
		fog.enabled = true
	# Shrines: asleep neutral, asleep held (solid, alpha 0.40), awake (gold, pulse, spin).
	var east := _point(&"shrine_e")
	rings.call(&"refresh_now")
	look = rings.call(&"ring_look", east)
	_check(_near_c(look["color"], Color(0.60, 0.60, 0.65, 0.25)) and float(look["dashes"]) == 24.0, "rings: asleep shrine %s" % look)
	east.call(&"set_owner_team", 1)
	rings.call(&"refresh_now")
	look = rings.call(&"ring_look", east)
	_check(_near_c(look["color"], Color(ENEMY, 0.40)) and float(look["dashes"]) == 0.0, "rings: asleep enemy-held shrine %s" % look)
	var west := _point(&"shrine_w")   # woken in the minimap part
	look = rings.call(&"ring_look", west)
	_check(_near_c(look["color"], Color(GOLD, 0.7)) and float(look["pulse"]) > 0.0 and float(look["dash_spin"]) > 0.0 \
			and float(look["glow"]) == 1.0, "rings: awake shrine %s" % look)
	# Selected: width x 1.5, alpha + 0.2.
	sel.select_neutral(rook)
	rings.call(&"refresh_now")
	look = rings.call(&"ring_look", rook)
	_check(absf(float(look["width"]) - 0.30) < 0.001 and absf((look["color"] as Color).a - 0.90) < 0.01, "rings: selected look %s" % look)
	sel.select_units([])
	rings.call(&"refresh_now")
	var ups: int = rings.uniform_updates
	rings.call(&"refresh_now")
	_check(rings.uniform_updates == ups, "rings: uniforms re-sent without a change")
	# The selected point on the minimap gets its gold outline without breaking the count.
	await _frames(4)


# ---------------------------------------------------------------- 3. camps

func _camp_with_creatures() -> Node3D:
	for c in get_nodes_in_group(&"neutral_camps"):
		if not (c.call(&"creatures") as Array).is_empty():
			return c
	return null


func _test_camps() -> void:
	var camp := _camp_with_creatures()
	_check(camp != null, "camps: no spawned camp on the map")
	if camp == null:
		return
	var unseen: Node3D = null
	for c in get_nodes_in_group(&"neutral_camps"):
		if c != camp and not fog.is_explored(0, (c as Node3D).global_position):
			unseen = c
	# Explored-but-never-seen camps read "alive"; a camp never explored is "unknown".
	rings.call(&"refresh_now")
	_check(StringName(rings.call(&"camp_state", camp)) != &"unknown", "camps: an explored camp still unknown")
	if unseen != null:
		_check(StringName(rings.call(&"camp_state", unseen)) == &"unknown", "camps: an unexplored camp is not unknown")
	fog.enabled = false
	rings.call(&"refresh_now")
	_check(StringName(rings.call(&"camp_state", camp)) == &"alive", "camps: a seen camp with creatures is not alive")
	# Clear it with a player soldier: known_cleared, the floating timer.
	var killer: Unit = main.make_unit("flame_guard")
	killer.team = 0
	main.add_child(killer)
	killer.global_position = Vector3(0, 0, 58)
	killer.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	killer.process_mode = Node.PROCESS_MODE_DISABLED
	for u in camp.call(&"creatures"):
		u.take_damage(99999.0, killer)
	await _frames(3)
	_check(bool(camp.call(&"is_cleared")), "camps: the camp is not cleared")
	_check(bool(rings.call(&"is_known_cleared", camp)), "camps: not known cleared after the player's clear")
	rings.call(&"refresh_now")
	_check(StringName(rings.call(&"camp_state", camp)) == &"cleared", "camps: state after the clear")
	var label: Label3D = rings.call(&"timer_label", camp)
	_check(label != null and label.visible, "camps: no floating respawn timer over the seen cleared camp")
	if label != null:
		var left := float(camp.call(&"respawn_left"))
		_check(label.text == rings.call(&"time_text", left) and label.text.contains(":"), "camps: timer text %s (left %.1f)" % [label.text, left])
		_check(label.font_size == 40 and absf(label.pixel_size - 0.006) < 0.0001 and label.no_depth_test \
				and label.billboard == BaseMaterial3D.BILLBOARD_ENABLED and label.outline_size == 8,
				"camps: timer label style")
		_check(absf(label.global_position.y - (camp.global_position.y + 1.0)) < 0.01, "camps: timer height")
	_check(rings.call(&"time_text", 80.0) == "1:20" and rings.call(&"time_text", 9.2) == "0:10", "camps: time_text")
	await _frames(8)
	_check(minimap.drawn_cleared_camps >= 1, "minimap: no cleared-camp outline")
	# The fog comes back: the timer hides, the memory stays.
	fog.enabled = true
	await _frames(2)
	if not fog.is_visible(0, camp.global_position):
		rings.call(&"refresh_now")
		_check(label == null or not label.visible, "camps: timer shown over a fogged camp")
		_check(StringName(rings.call(&"camp_state", camp)) == &"cleared", "camps: fogged camp forgot it was cleared")
	# Respawn: known_cleared resets.
	camp.call(&"spawn")
	await _frames(2)
	_check(not bool(rings.call(&"is_known_cleared", camp)), "camps: still known cleared after respawned")
	killer.queue_free()


# ---------------------------------------------------------------- 4. point clicks

func _screen(world: Vector3) -> Vector2:
	return main.camera_rig.camera.unproject_position(world)


func _focus(world: Vector3) -> void:
	main.camera_rig.focus_on(world)
	await _frames(4)


func _test_point_clicks() -> void:
	fog.enabled = false
	var mill := _point(&"tower_s")
	await _focus(mill.global_position)
	_clicked.clear()
	_click(_screen(mill.global_position + Vector3(0, 1.2, 0)))
	await _frames(1)
	_check(sel.selected_neutral == mill and _clicked.has(mill), "click: the watchtower body did not select it (%s)" % sel.selected_neutral)
	_key(KEY_ESCAPE, KEY_ESCAPE)
	await _frames(1)
	_check(sel.selected_neutral == null, "click: Esc did not clear the selected point")
	var shrine := _point(&"shrine_w")
	await _focus(shrine.global_position)
	_clicked.clear()
	_click(_screen(shrine.global_position + Vector3(0, 1.4, 0)))
	await _frames(1)
	_check(sel.selected_neutral == shrine and _clicked.has(shrine), "click: the shrine click area did not select it")
	_check(sel.point_at(_screen(shrine.global_position + Vector3(0, 1.4, 0))) == shrine, "point_at(shrine)")
	var well := _point(&"well_w")
	await _focus(well.global_position)
	_clicked.clear()
	_click(_screen(well.global_position + Vector3(2.5, 0, 0)))
	await _frames(1)
	_check(sel.selected_neutral == well and _clicked.has(well), "click: the ground 2.5 m from the well did not select it")
	_click(_screen(well.global_position + Vector3(5.5, 0, 0)))
	await _frames(1)
	_check(sel.selected_neutral == null, "click: the ground 5.5 m from the well still selects it")
	# Right click on a point with a soldier selected = a ground move (never a target).
	var s: Unit = main.make_unit("flame_guard")
	s.team = 0
	main.add_child(s)
	s.global_position = mill.global_position + Vector3(12, 0, 0)
	sel.select_units([s])
	await _focus(mill.global_position)
	_right_click(_screen(mill.global_position + Vector3(0, 1.2, 0)))
	await _frames(1)
	_check(s.attack_target == null and sel.selected_neutral == null, "right click on a point: not a plain move")
	s.queue_free()
	sel.select_units([])
	fog.enabled = true


# ---------------------------------------------------------------- 5. critters

func _unit(id: String, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(id)
	u.team = 0
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _test_critters() -> void:
	var herds: Node = get_first_node_in_group(&"critter_herds")
	_check(herds != null, "critters: no CritterHerds")
	if herds == null:
		return
	fog.enabled = false
	var deer: Array = herds.call(&"critters", &"deer")
	_check(deer.size() >= 2, "critters: fewer than 2 deer")
	if deer.size() < 2:
		return
	var d0: Node3D = deer[0]
	await _focus(d0.global_position)
	await _frames(20)   # the herds' fog / camera pass shows it
	_check(d0.is_visible_in_tree(), "critters: the deer under the camera is hidden")
	# Units 14 m away (no flee), frozen so they don't chase during the test.
	var base := d0.global_position + Vector3(0, 0, 14)
	var soldier := _unit("flame_guard", base)
	var worker := _unit("cinder_hand", base + Vector3(1.5, 0, 0))
	var caravan := _unit("caravan", base + Vector3(-1.5, 0, 0))
	var tracker := _unit("greywater_tracker", base + Vector3(0, 0, 1.5))
	tracker.add_to_group(&"trackers")
	for u in [soldier, worker, caravan, tracker]:
		u.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
		u.process_mode = Node.PROCESS_MODE_DISABLED
	_check(sel.can_hunt(soldier) and not sel.can_hunt(worker) and not sel.can_hunt(caravan) and not sel.can_hunt(tracker),
			"can_hunt: soldier %s worker %s caravan %s tracker %s" % [sel.can_hunt(soldier), sel.can_hunt(worker),
			sel.can_hunt(caravan), sel.can_hunt(tracker)])
	# Left click: the read-only card (selected_neutral + signal).
	await _focus(d0.global_position)
	_clicked.clear()
	var at := _screen(d0.global_position + Vector3(0, 0.9, 0))
	_check(sel.critter_at(at) == d0, "critter_at does not find the visible deer")
	_click(at)
	await _frames(1)
	_check(sel.selected_neutral == d0 and _clicked.has(d0), "critters: left click did not select the deer")
	# Right click with soldier + worker + caravan: only the soldier attacks it.
	sel.select_units([soldier, worker, caravan])
	await _focus(d0.global_position)
	_right_click(_screen(d0.global_position + Vector3(0, 0.9, 0)))
	await _frames(1)
	_check(soldier.attack_target == d0, "right click: the soldier does not attack the deer (%s)" % soldier.attack_target)
	_check(worker.attack_target != d0 and caravan.attack_target != d0, "right click: a worker / caravan got the deer as a target")
	_check(tracker.attack_target != d0, "right click: the tracker got the deer as a target")
	# X then left click (attack-move targeting): the same split.
	soldier.command_stop()
	worker.command_stop()
	var d1: Node3D = deer[1]
	await _focus(d1.global_position)
	await _frames(10)
	if d1.is_visible_in_tree():
		sel.begin_attack_move_targeting()
		_click(_screen(d1.global_position + Vector3(0, 0.9, 0)))
		await _frames(1)
		_check(soldier.attack_target == d1, "X-click: the soldier does not attack the deer")
		_check(worker.attack_target != d1 and caravan.attack_target != d1, "X-click: a worker / caravan got the deer")
	else:
		_check(false, "critters: the second deer is hidden")
	# Hunt cursor: over the deer with hunters selected; not with a worker only.
	await _focus(d0.global_position)
	await _frames(6)
	_move(_screen(d0.global_position + Vector3(0, 0.9, 0)))
	await _frames(6)
	_check(sel.hovered_critter == d0 and sel.is_hunt_cursor(), "cursor: no hunt cursor over the deer with a soldier selected")
	var ring: MeshInstance3D = sel.get(&"_target_ring")
	if ring != null:
		_check(ring.visible, "cursor: the red ring is not shown")
	_move(_screen(d0.global_position + Vector3(9, 0, 9)))
	await _frames(6)
	_check(sel.hovered_critter == null and not sel.is_hunt_cursor(), "cursor: the hunt cursor stayed after leaving")
	if ring != null:
		_check(not ring.visible, "cursor: the red ring stayed after leaving")
	sel.select_units([worker])
	_move(_screen(d0.global_position + Vector3(0, 0.9, 0)))
	await _frames(6)
	_check(sel.hovered_critter == null and not sel.is_hunt_cursor(), "cursor: hunt cursor with only a worker selected")
	# The selected critter is dropped when it dies.
	sel.select_neutral(d0)
	d0.call(&"take_damage", 999.0, soldier)
	await _frames(20)
	_check(sel.selected_neutral == null, "critters: a dead deer stays selected")
	for u in [soldier, worker, caravan, tracker]:
		u.queue_free()
	sel.select_units([])
	fog.enabled = true


# ---------------------------------------------------------------- 6. code rule

func _test_no_private_calls() -> void:
	var files := [RINGS_PATH]
	for f in DirAccess.get_files_at("res://scripts/ui"):
		if f.ends_with(".gd"):
			files.append("res://scripts/ui/" + f)
	var re := RegEx.create_from_string("[A-Za-z0-9_\\]\\)]\\._[a-z]\\w*\\(|call\\(&?\"_")
	for path: String in files:
		var text := FileAccess.get_file_as_string(path)
		var n := 0
		for l in text.split("\n"):
			n += 1
			var code := l.get_slice("#", 0)
			var m := re.search(code)
			if m != null and not code.contains("super."):
				_errors.append("%s:%d calls a private function: %s" % [path.get_file(), n, l.strip_edges()])


# ---------------------------------------------------------------- input helpers

func _key(physical: Key, printed: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = printed
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _move(pos: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	root.push_input(move)


func _click(pos: Vector2) -> void:
	_move(pos)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)


func _right_click(pos: Vector2) -> void:
	_move(pos)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)
