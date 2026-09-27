extends SceneTree
## Task A2.10: the main menu 3D diorama (art/environment/menu_diorama/menu_diorama.tscn).
## Run:  godot --headless --path . -s tests/test_a2_10.gd --fixed-fps 60 --quit-after 1200
## Checks: the scene instantiates headless (directly and inside a SubViewport) without script errors, its root is
## a Node3D with a current Camera3D that the viewport uses, the four wizards / crown / altar / tavern exist, the
## camera drifts, set_paused(true) freezes camera + crown + particles and set_paused(false) resumes them,
## focus_kingdom() glides the camera, and inside a SubViewport the auto render scale kicks in.

const TASK_ID := "a2.10"
const SCENE := "res://art/environment/menu_diorama/menu_diorama.tscn"

var _dio: Node3D
var _vp: SubViewport
var _dio2: Node3D
var _frame := 0
var _fail := ""
var _cam_a: Transform3D
var _crown_a: float
var _paused_cam: Transform3D
var _paused_crown: float


func _initialize() -> void:
	if not ResourceLoader.exists(SCENE):
		_fail = "scene missing"
		return
	_dio = (load(SCENE) as PackedScene).instantiate() as Node3D
	if _dio == null:
		_fail = "root is not a Node3D"
		return
	root.add_child(_dio)
	# Same scene inside a big SubViewport (the recommended menu integration).
	_vp = SubViewport.new()
	_vp.size = Vector2i(3440, 1440)
	_vp.own_world_3d = true
	root.add_child(_vp)
	_dio2 = (load(SCENE) as PackedScene).instantiate() as Node3D
	_vp.add_child(_dio2)


func _process(_delta: float) -> bool:
	if _fail != "":
		print("FAIL %s: %s" % [TASK_ID, _fail])
		return true
	_frame += 1
	match _frame:
		5:
			_check_structure()
			_cam_a = _cam().global_transform
			_crown_a = _crown_rot()
		125:
			if _cam().global_transform.origin.distance_to(_cam_a.origin) < 0.01:
				_fail = "camera does not drift"
			elif absf(_crown_rot() - _crown_a) < 0.01:
				_fail = "crown does not turn"
			else:
				_dio.call(&"set_paused", true)
				if not bool(_dio.call(&"is_paused")):
					_fail = "is_paused() false after set_paused(true)"
				_paused_cam = _cam().global_transform
				_paused_crown = _crown_rot()
		245:
			if not _cam().global_transform.is_equal_approx(_paused_cam):
				_fail = "camera moved while paused"
			elif absf(_crown_rot() - _paused_crown) > 0.0001:
				_fail = "crown turned while paused"
			else:
				for p: Node in _dio.find_children("*", "GPUParticles3D", true, false):
					if (p as GPUParticles3D).speed_scale != 0.0:
						_fail = "particles %s still running while paused" % p.name
						break
			if _fail == "":
				_dio.call(&"set_paused", false)
				if bool(_dio.call(&"is_paused")):
					_fail = "still paused after set_paused(false)"
		305:
			if _cam().global_transform.is_equal_approx(_paused_cam):
				_fail = "camera did not resume"
			else:
				_paused_cam = _cam().global_transform
				_dio.call(&"focus_kingdom", &"ice")
				if _dio.call(&"get_focus") != &"ice":
					_fail = "focus_kingdom(&\"ice\") not taken"
		500:
			var torvald := _dio.get_node(^"Wizards/Torvald") as Node3D
			var d := _cam().global_position.distance_to(torvald.global_position)
			if d > 16.0:
				_fail = "focus shot did not move the camera to Torvald (%.1f m away)" % d
			else:
				_dio.call(&"focus_kingdom", &"")
				_dio.call(&"focus_kingdom", &"bogus")   # unknown = wide shot, no error
		520:
			var s := _vp.scaling_3d_scale
			if s > 0.9 or s < 0.5:
				_fail = "auto render scale in a 3440x1440 SubViewport is %.2f (expected ~0.64)" % s
			elif root.scaling_3d_scale != 1.0:
				_fail = "the root viewport's render scale was touched"
		540:
			print("PASS %s" % TASK_ID)
			return true
	return false


func _cam() -> Camera3D:
	return _dio.call(&"get_camera") as Camera3D


func _crown_rot() -> float:
	return (_dio.get_node(^"Crown") as Node3D).rotation.y


func _check_structure() -> void:
	var cam := _cam()
	if cam == null:
		_fail = "no Camera3D"
	elif not cam.current:
		_fail = "Camera3D is not current"
	elif root.get_camera_3d() != cam:
		_fail = "the viewport does not use the diorama camera"
	elif (_dio2.call(&"get_camera") as Camera3D) != _vp.get_camera_3d():
		_fail = "the SubViewport does not use its diorama camera"
	elif _dio.find_children("*", "WorldEnvironment", true, false).size() != 1:
		_fail = "expected exactly one WorldEnvironment"
	else:
		var suns := _dio.find_children("*", "DirectionalLight3D", true, false)
		var shadowed := 0
		for s: Node in suns:
			if (s as DirectionalLight3D).shadow_enabled:
				shadowed += 1
		if suns.size() != 1 or shadowed != 1:
			_fail = "expected one shadowed sun, found %d lights (%d with shadows)" % [suns.size(), shadowed]
		for l: Node in _dio.find_children("*", "OmniLight3D", true, false):
			if (l as OmniLight3D).shadow_enabled:
				_fail = "omni light %s casts shadows" % l.name
		for p: String in ["Wizards/Vessa", "Wizards/Malrik", "Wizards/Torvald", "Wizards/Ysolde", "Altar", "Crown",
				"Tavern/TavernModel", "Champions"]:
			if _dio.get_node_or_null(NodePath(p)) == null:
				_fail = "missing node %s" % p
		# Live particles (looping emitters; the models' one-shot cast / death bursts never fire in the menu).
		var n := 0
		for p: Node in _dio.find_children("*", "GPUParticles3D", true, false):
			var g := p as GPUParticles3D
			if g.emitting and not g.one_shot:
				n += g.amount
		if n > 200:
			_fail = "too many live particles (%d)" % n
