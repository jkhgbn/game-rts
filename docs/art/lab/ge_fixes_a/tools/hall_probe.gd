extends SceneTree
## G-E fixes A: lists the Fire Hall's visible geometry near the ground (finds stray quads / cubes). Headless ok.
func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	var path := "res://art/buildings/fire_hall.tscn"
	var n: Node3D = (load(path) as PackedScene).instantiate()
	root.add_child(n)
	for i in 10:
		await process_frame
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var bb: AABB = gi.global_transform * gi.get_aabb()
		print("%-60s pos=%s aabb=%s %s" % [str(n.get_path_to(gi)), str(gi.global_position.snapped(Vector3.ONE * 0.01)),
			str(bb.position.snapped(Vector3.ONE * 0.01)), str(bb.size.snapped(Vector3.ONE * 0.01))])
	quit(0)
