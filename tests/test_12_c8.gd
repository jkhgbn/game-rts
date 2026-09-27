extends SceneTree
## Task 12.C8: the finished map-fill models plugged into the step-12 systems (docs/design/map-fill.md section 15 row
## 12.C8 + "Done when" 12.C8 / 12.C9), on the real skirmish:
## - water / bridges / fords / Crown Steps (RiverSystem), landmarks (skirmish), watchtower / well / shrine
##   (CapturePoint) are the art scenes, not the placeholders; the capture hooks reach the model;
## - every NeutralCamp has its CampSite (Site): alive look on the 0:00 camps, cleared look on the later ones,
##   set_cleared(true) on the clear and false on the respawn; the Ford Nests follow their ford's flow;
## - every lair has its LairArt at the lair centre (yaw 0 / PI), empty at the start, occupied while its beast lives,
##   empty again when it dies or leaves the tree; no decor inside the lair circles;
## - the cosmetic CritterSystem is in the level (main.gd glue).
## Run:  godot --headless --path . -s tests/test_12_c8.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "12.C8"

var errors: Array[String] = []
var _done := false
var main: Node


func _initialize() -> void:
	main = load("res://scenes/skirmish.tscn").instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


func _run() -> void:
	var map_ok := false
	for i in 4000:
		await process_frame
		if main.get(&"hero") != null and get_first_node_in_group(&"camp_manager") != null \
				and get_first_node_in_group(&"epic_beasts") != null:
			map_ok = true
			break
	if not map_ok:
		_finish("the skirmish never had a hero, a CampManager and EpicBeasts")
		return
	await _frames(20)
	_check_critter_system()
	_check_river()
	_check_landmarks()
	_check_capture_points()
	await _check_camps()
	await _check_lairs()
	_check_lair_decor()
	_finish("")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _fail(text: String) -> void:
	errors.append(text)


func _finish(fatal: String) -> void:
	if fatal != "":
		errors.append(fatal)
	var sites := get_nodes_in_group(&"camp_sites").size()
	var lair_arts := get_nodes_in_group(&"lairs").size()
	var cs: Node = main.get_node_or_null("CritterSystem") if is_instance_valid(main) else null
	print("12.C8: camp sites %d, lair arts %d, critters built %s (%s)" % [sites, lair_arts,
			cs.call(&"is_built") if cs else false, cs.call(&"critter_count") if cs else 0])
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	_done = true


# ---------------------------------------------------------------- critters (main.gd glue)

func _check_critter_system() -> void:
	var cs: Node = main.get_node_or_null("CritterSystem")
	if cs == null:
		_fail("no CritterSystem child in the level")
		return
	if cs.get_script() == null or (cs.get_script() as Script).resource_path != "res://art/environment/critters/critter_system.gd":
		_fail("CritterSystem has the wrong script")
	var count := 0
	for n in main.get_children():
		if n.name.begins_with("CritterSystem"):
			count += 1
	if count != 1:
		_fail("%d CritterSystem nodes (want 1)" % count)


# ---------------------------------------------------------------- river, landmarks, points

func _check_river() -> void:
	var river := get_first_node_in_group(&"river")
	if river == null:
		_fail("no RiverSystem")
		return
	var visuals: Node = river.get_node_or_null("Visuals")
	if visuals == null:
		_fail("RiverSystem has no Visuals")
		return
	var crossings: Array = river.call(&"crossings")
	for c: Dictionary in crossings:
		var model: Node = visuals.get_node_or_null("Model" + String(c["id"]).to_pascal_case())
		if model == null or model.get_script() == null:
			_fail("crossing %s has no model scene" % c["id"])
	var water_mat := load("res://art/environment/water/water_mat.tres")
	var found := false
	for mi in visuals.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.material_override == water_mat or (m.mesh and m.mesh.get_surface_count() > 0 and m.mesh.surface_get_material(0) == water_mat):
			found = true
			break
	if not found:
		_fail("no river mesh uses water_mat.tres")


func _check_landmarks() -> void:
	var lms: Array = main.get(&"landmarks")
	if lms.size() != 10:
		_fail("%d landmarks (want 10)" % lms.size())
	for lm: Node in lms:
		if not is_instance_valid(lm) or lm.get_node_or_null("Model") == null:
			_fail("landmark %s has no Model (placeholder colliders?)" % (lm.name if is_instance_valid(lm) else "?"))


func _check_capture_points() -> void:
	var points := get_nodes_in_group(&"capture_points")
	if points.size() < 8:
		_fail("only %d capture points" % points.size())
	var scripts := {&"watchtower": "watchtower_model.gd", &"well": "essence_well.gd", &"shrine": "wayshrine.gd"}
	for p in points:
		var art: Node = p.call(&"model")
		var want: String = scripts.get(p.get(&"kind"), "")
		if art == null or art.get_script() == null or not (art.get_script() as Script).resource_path.ends_with(want):
			_fail("point %s shows no %s model" % [p.get(&"point_id"), want])
	# The owner hook reaches the model (the well has a getter): team colour on capture, null when neutral.
	for p in points:
		if p.get(&"kind") != &"well":
			continue
		var art: Node = p.call(&"model")
		if art == null or not art.has_method(&"get_owner_color"):
			continue
		p.call(&"set_owner_team", 0)
		var c: Variant = art.call(&"get_owner_color")
		if not (c is Color) or not (c as Color).is_equal_approx(Unit.team_color(0)):
			_fail("well model owner colour %s after a capture (want the player colour)" % str(c))
		p.call(&"set_owner_team", -1)
		if art.call(&"get_owner_color") != null:
			_fail("well model still coloured after turning neutral")
		break


# ---------------------------------------------------------------- camps

func _check_camps() -> void:
	var mgr := get_first_node_in_group(&"camp_manager")
	var camps: Array = mgr.call(&"camps")
	if camps.size() != 8:
		_fail("%d camps (want 8)" % camps.size())
	await _frames(40)   # the 0:00 spawns (manager ticks every 0.5 s)
	var bristle: Node = null
	for camp: Node in camps:
		var site: Node = camp.call(&"site")
		if site == null:
			_fail("camp %s has no site dressing" % camp.get(&"camp_id"))
			continue
		var kind: StringName = camp.get(&"kind")
		if not (site.get_script() as Script).resource_path.ends_with("camp_site.gd") or site.get(&"kind") != kind:
			_fail("camp %s: wrong site scene" % camp.get(&"camp_id"))
		if (site as Node3D).global_position.distance_to((camp as Node3D).global_position) > 0.01:
			_fail("camp %s: site not on the spot" % camp.get(&"camp_id"))
		var late: bool = float(camp.get(&"first_spawn")) > 0.0
		if bool(site.call(&"is_cleared")) != late:
			_fail("camp %s (%s): site cleared=%s at 0:00+" % [camp.get(&"camp_id"), kind, site.call(&"is_cleared")])
		if bool(camp.call(&"is_cleared")) != late:
			_fail("camp %s: creatures alive=%s, first spawn %s" % [camp.get(&"camp_id"), not camp.call(&"is_cleared"),
					camp.get(&"first_spawn")])
		if kind == &"mirefang":
			var z: Vector3 = (site as Node3D).global_transform.basis.z.normalized()
			if absf(z.dot(Vector3(1.0, 0.0, 8.0).normalized())) < 0.99:
				_fail("camp %s: the Ford Nest is not along the ford flow (z %s)" % [camp.get(&"camp_id"), z])
		elif Vector2((site as Node3D).global_transform.basis.z.x, (site as Node3D).global_transform.basis.z.z).dot(
				Vector2((camp as Node3D).position.x, (camp as Node3D).position.z).normalized()) < 0.99:
			_fail("camp %s: the site's -Z does not face the map centre" % camp.get(&"camp_id"))
		if kind == &"bristleback" and bristle == null:
			bristle = camp
	if bristle == null:
		return
	# Clear it: the site turns cleared; a respawn brings the alive look back.
	var hero: Node = main.get(&"hero")
	for u: Node in bristle.call(&"creatures"):
		u.call(&"take_damage", 1.0e6, hero)
	await _frames(10)
	var site: Node = bristle.call(&"site")
	if not bool(bristle.call(&"is_cleared")):
		_fail("the bristleback camp did not clear")
	elif not bool(site.call(&"is_cleared")):
		_fail("site not cleared after the camp was cleared")
	await _frames(5)
	bristle.call(&"spawn")
	await _frames(5)
	if bool(bristle.call(&"is_cleared")):
		_fail("the bristleback camp did not respawn")
	elif bool(site.call(&"is_cleared")):
		_fail("site still cleared after the respawn")


# ---------------------------------------------------------------- lairs

func _check_lairs() -> void:
	var eb := get_first_node_in_group(&"epic_beasts")
	var lairs: Array = eb.call(&"lairs")
	if lairs.size() != 8:
		_fail("%d lairs (want 8)" % lairs.size())
	for lair: Dictionary in lairs:
		var art: Node3D = eb.call(&"lair_art", lair["id"])
		if art == null:
			_fail("lair %s has no LairArt" % lair["id"])
			continue
		if not art.is_in_group(&"lairs"):
			_fail("lair %s art not in group lairs" % lair["id"])
		var c: Vector3 = lair["center"]
		if Vector2(art.global_position.x - c.x, art.global_position.z - c.z).length() > 0.01:
			_fail("lair %s art not at the centre" % lair["id"])
		var want_yaw := PI if String(lair["id"]).ends_with("_e") else 0.0
		if absf(angle_difference(art.global_rotation.y, want_yaw)) > 0.01:
			_fail("lair %s art yaw %.2f (want %.2f)" % [lair["id"], art.global_rotation.y, want_yaw])
		if bool(art.call(&"is_occupied")):
			_fail("lair %s occupied before any beast" % lair["id"])
	# A beast spawns: occupied; it dies: empty.
	var hero: Node = main.get(&"hero")
	var heath: Node3D = eb.call(&"lair_art", &"lair_heath_w")
	var beast: Node = eb.call(&"spawn_now", &"lair_heath_w")
	if beast == null or heath == null:
		_fail("spawn_now(lair_heath_w) gave no beast")
	else:
		if not bool(heath.call(&"is_occupied")):
			_fail("West Heath lair not occupied after its beast spawned")
		await _frames(5)
		beast.call(&"take_damage", 1.0e7, hero)
		await _frames(5)
		if bool(beast.call(&"is_alive")):
			_fail("the Tusker did not die")
		elif bool(heath.call(&"is_occupied")):
			_fail("West Heath lair still occupied after its beast died")
	# A beast leaves the tree (a mission, a test): empty.
	var crag: Node3D = eb.call(&"lair_art", &"lair_crag_e")
	var roc: Node = eb.call(&"spawn_now", &"lair_crag_e")
	if roc == null or crag == null:
		_fail("spawn_now(lair_crag_e) gave no beast")
	else:
		if not bool(crag.call(&"is_occupied")):
			_fail("East Crag lair not occupied after its beast spawned")
		roc.queue_free()
		await _frames(3)
		if bool(crag.call(&"is_occupied")):
			_fail("East Crag lair still occupied after its beast left the tree")


func _check_lair_decor() -> void:
	var dressing: Node = null
	for n in main.get_children():
		if n.has_method(&"clear_area") and n.has_method(&"instance_positions"):
			dressing = n
			break
	if dressing == null:
		print("no map dressing: lair decor check skipped")
		return
	var pos: PackedVector3Array = dressing.call(&"instance_positions", "")
	var eb := get_first_node_in_group(&"epic_beasts")
	var bad := 0
	for lair: Dictionary in eb.call(&"lairs"):
		var art: Node = eb.call(&"lair_art", lair["id"])
		if art == null:
			continue
		for circle: Vector3 in (art.call(&"decor_clear_circles") as PackedVector3Array):
			for p in pos:
				if Vector2(p.x - circle.x, p.z - circle.y).length() < circle.z - 0.05:
					bad += 1
	if bad > 0:
		_fail("%d decor instances inside lair circles" % bad)
