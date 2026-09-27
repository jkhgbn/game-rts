extends SceneTree
## Task 2.S2: the start camera shows the keep and the workers above the bottom HUD panels
## (~250 px of a 900 px window), on 1600 x 900 and on the user's 3440 x 1440 ultrawide, and the
## start hint is shown. The keep, its roof and the 3 workers must project inside the screen and
## in the top 70 % of it. The camera keeps its height (vertical FOV), so the check is done with the
## camera's own projection for both window sizes, plus unproject_position on the real viewport.
## Run:  godot --headless --path . -s tests/test_2_s2.gd --fixed-fps 60 --quit-after 5200

const TASK_ID := "2.S2"
const CHECK_FRAME := 3
const MAX_Y := 0.70
const SIZES: Array[Vector2] = [Vector2(1600, 900), Vector2(3440, 1440), Vector2(1280, 720)]

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	# Headless, the window is 64 x 64, reports focus, and the mouse sits at (0, 0), inside the
	# edge-pan margin, so RTSCamera edge-pans to the map corner while the navmesh bakes. There is
	# no real mouse here: keep edge pan off (every frame, since the pause menu re-applies the saved
	# setting; this runs before the nodes' _process) so the start camera stays where main.gd put it.
	var rig = main.get("camera_rig")
	if rig != null:
		rig.edge_pan_enabled = false
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame < CHECK_FRAME:
		return false
	_run()
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	return true


func _run() -> void:
	var cam: Camera3D = main.camera_rig.camera
	var keep: Node3D = main.keep
	var want_focus: Vector3 = keep.position + main.START_FOCUS_FROM_KEEP
	var rig_pos: Vector3 = main.camera_rig.position
	if Vector2(rig_pos.x - want_focus.x, rig_pos.z - want_focus.z).length() > 0.5:
		_errors.append("camera rig at %s, want the start focus %s" % [rig_pos, want_focus])
	var points := {
		"keep": keep.global_position,
		"keep roof": keep.global_position + Vector3.UP * 9.0,
		"keep drop-off": keep.call("drop_off_point"),
	}
	var n := 0
	for u in get_nodes_in_group("units"):
		if u.team == 0 and u.has_method("command_gather"):
			n += 1
			points["worker %d" % n] = u.global_position
	if n != 3:
		_errors.append("%d workers at the start" % n)
	for node_id in [&"node_home_a", &"node_home_b"]:
		points[String(node_id)] = main.crystal_nodes[node_id].global_position

	for size in SIZES:
		for label in points:
			var s := _project(cam, points[label], size)
			if s.x < 0.03 * size.x or s.x > 0.97 * size.x or s.y < 0.0 or s.y > MAX_Y * size.y:
				_errors.append("%dx%d: %s at (%d, %d), want x inside and y < %d" % [
						size.x, size.y, label, s.x, s.y, MAX_Y * size.y])
		var k := _project(cam, keep.global_position, size)
		print("  %dx%d: keep at (%d, %d) = %.0f %% down, %.0f %% across" % [
				size.x, size.y, k.x, k.y, 100.0 * k.y / size.y, 100.0 * k.x / size.x])
	# The real (headless) viewport too, through the engine's own projection.
	var vp := cam.get_viewport().get_visible_rect().size
	var p := cam.unproject_position(keep.global_position)
	if cam.is_position_behind(keep.global_position) or p.y > MAX_Y * vp.y or p.y < 0.0 \
			or p.x < 0.0 or p.x > vp.x:
		_errors.append("unproject_position: keep at %s in a %s viewport" % [p, vp])

	# The start hint.
	var msg: Label = main.hud.get("_message")
	if msg == null or not msg.text.begins_with("Click your Keep (bottom-left) to train workers") \
			or not msg.text.contains("press B to build"):
		_errors.append("start message is '%s'" % (msg.text if msg else "<none>"))


## Screen position of `world` for a window of `size` (the camera keeps its vertical FOV).
func _project(cam: Camera3D, world: Vector3, size: Vector2) -> Vector2:
	var proj := Projection.create_perspective(cam.fov, size.x / size.y, cam.near, cam.far)
	var v := cam.global_transform.affine_inverse() * world
	var clip := proj * Vector4(v.x, v.y, v.z, 1.0)
	if clip.w <= 0.0:
		return Vector2(-1.0, -1.0)
	var ndc := Vector2(clip.x / clip.w, clip.y / clip.w)
	return Vector2((ndc.x + 1.0) * 0.5 * size.x, (1.0 - ndc.y) * 0.5 * size.y)
