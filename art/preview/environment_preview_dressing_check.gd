extends SceneTree
## A.10 check: the map dressing plugs into the skirmish the way main.gd should do it, scatters its decor away
## from the lane / crystal nodes, builds the border forest, and clears the decor under a new building.
## Windowed (MultiMesh transforms are not kept by the headless renderer):
##   $GODOT --path . -s res://art/preview/environment_preview_dressing_check.gd --fixed-fps 60 --quit-after 3000

var main: Node
var dressing: Node
var _frames := 0
var _started := false
var _finished := false
var _exit_wait := 0


func _initialize() -> void:
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	dressing = (load("res://art/environment/map_dressing.tscn") as PackedScene).instantiate()
	main.add_child(dressing)   # what main.gd will do right after env_props.commit()


func _process(_delta: float) -> bool:
	if _finished:
		_exit_wait += 1
		return _exit_wait > 240   # let the navmesh rebake started by the test site finish first
	_frames += 1
	if main.get(&"hero") == null:
		if _frames > 2500:
			print("FAIL A.10: map never ready")
			return true
		return false
	if _frames > 5 and not _started:
		_started = true
		_run()
	return false


func _done(msg: String) -> bool:
	print(msg)
	_finished = true
	return true


func _run():
	var count: int = int(dressing.call(&"decor_count"))
	if count < 1000:
		return _done("FAIL A.10: only %d decor instances" % count)
	var trees := 0
	for c: Node in dressing.get_node(^"BorderForest").get_children():
		trees += (c as MultiMeshInstance3D).multimesh.instance_count
	if trees < 500:
		return _done("FAIL A.10: only %d border trees" % trees)
	# Nothing off the map, on the lane or on a crystal node.
	var lane_a := Vector2(-36.0, 36.0)
	var lane_b := Vector2(36.0, -36.0)
	var nodes: Array = main.get_tree().get_nodes_in_group(&"crystal_nodes")
	for mmi: Node in dressing.get_node(^"Decor").get_children():
		var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
		for i: int in mm.instance_count:
			var p: Vector3 = mm.get_instance_transform(i).origin
			var q := Vector2(p.x, p.z)
			if absf(p.x) > 60.0 or absf(p.z) > 60.0:
				return _done("FAIL A.10: decor off the map at %s" % p)
			if q.distance_to(Geometry2D.get_closest_point_to_segment(q, lane_a, lane_b)) < 5.0:
				return _done("FAIL A.10: decor on the lane at %s (%s)" % [p, mmi.name])
			for n: Node in nodes:
				if (n as Node3D).global_position.distance_to(Vector3(p.x, 0.0, p.z)) < 2.0:
					return _done("FAIL A.10: decor on a crystal node at %s" % p)
	# A building placed later clears the decor under it (construction sites included).
	var spot := Vector3(-8.0, 0.0, 24.0)
	var before: int = _visible_near(spot, 2.5)
	var site: Node = main.build_grid.call(&"create_building", BuildingType.find("fire_hearth"))
	site.set(&"team", 0)
	site.call(&"make_site")
	site.set(&"position", spot)
	main.nav_region.add_child(site)
	await process_frame
	await process_frame
	var after: int = _visible_near(spot, 2.5)
	if after > 0:
		return _done("FAIL A.10: %d decor instances still under the new site (was %d)" % [after, before])
	_done("PASS A.10 decor=%d border_trees=%d cleared_under_site=%d" % [count, trees, before])


func _visible_near(c: Vector3, r: float) -> int:
	var n := 0
	for mmi: Node in dressing.get_node(^"Decor").get_children():
		var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
		for i: int in mm.instance_count:
			var xf: Transform3D = mm.get_instance_transform(i)
			if xf.origin.y > -1.0 and Vector2(xf.origin.x - c.x, xf.origin.z - c.z).length() < r:
				n += 1
	return n
