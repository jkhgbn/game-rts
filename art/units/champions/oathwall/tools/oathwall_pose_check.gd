extends SceneTree
## Headless pose check for the Oathwall (task 9.V2): prints where the hammer head and the shield edges are (model
## space, feet at the origin) at the key frames of each animation, so the strike / plant numbers can be tuned.
##   Godot_console.exe --headless --path . -s res://art/units/champions/oathwall/tools/oathwall_pose_check.gd --fixed-fps 60 --quit-after 600

const SCENE := "res://art/units/champions/oathwall/oathwall.tscn"

var m: Node3D
var rest: Dictionary = {}


func _initialize() -> void:
	m = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(m)


func _process(_d: float) -> bool:
	m.set_process(false)
	var s: Script = m.get_script()
	var consts: Dictionary = s.get_script_constant_map()
	var fist: Vector3 = consts["FIST_R"]
	var d: Vector3 = consts["HAFT_DIR"]
	var at: float = consts["HEAD_AT"]
	var sc: Vector3 = consts["SHIELD_C"]
	var sb := Basis.from_euler(consts["SHIELD_ROT"] * (PI / 180.0))
	var arm_r := m.get_node(^"Root/Chest/ArmR") as Node3D
	var arm_l := m.get_node(^"Root/Chest/ArmL") as Node3D
	var ro := _origin(arm_r)
	var lo := _origin(arm_l)
	var p := Vector3(1, 0, 0).cross(d).normalized()
	var marks: Dictionary = {
		"hammer_head": [arm_r, fist + d * at - ro],
		"hammer_face_lo": [arm_r, fist + d * at + p * 0.29 - ro],
		"hammer_face_hi": [arm_r, fist + d * at - p * 0.29 - ro],
		"shield_bottom": [arm_l, sc + sb * Vector3(0, -0.8, 0) - lo],
		"shield_bot_l": [arm_l, sc + sb * Vector3(-0.6, -0.8, 0) - lo],
		"shield_bot_r": [arm_l, sc + sb * Vector3(0.6, -0.8, 0) - lo],
		"shield_top": [arm_l, sc + sb * Vector3(0, 0.8, 0) - lo],
	}
	_report("rest", marks)
	m.call(&"play_attack")
	var ta: float = 0.0
	for t: float in [0.07, 0.12, 0.2]:
		_step_to(t - ta)
		ta = t
		_report("slam %.2f" % t, marks)
	_step_to(0.9)
	for id: StringName in [&"oath_of_iron", &"shield_bash", &"bulwark_stand"]:
		m.call(&"play_cast", id)
		var keys: Array = {&"oath_of_iron": [0.28, 0.34, 0.5], &"shield_bash": [0.10, 0.16],
			&"bulwark_stand": [0.30, 0.42, 3.0]}[id]
		var t0: float = 0.0
		for t: float in keys:
			_step_to(t - t0)
			t0 = t
			_report("%s %.2f" % [id, t], marks)
		_step_to(7.0)
	m.call(&"play_death")
	_step_to(1.0)
	_report("dead 1.0", marks)
	m.call(&"revive")
	_step_to(0.1)
	_report("revived", marks)
	return true


func _origin(n: Node3D) -> Vector3:
	var p := Vector3.ZERO
	var c: Node = n
	while c and c != m:
		p += (c as Node3D).position
		c = c.get_parent()
	return p


func _step_to(dt_total: float) -> void:
	var n: int = int(round(dt_total * 60.0))
	for i: int in n:
		m.call(&"_animate", 1.0 / 60.0)


func _report(label: String, marks: Dictionary) -> void:
	var parts: PackedStringArray = []
	for k: String in marks:
		var e: Array = marks[k]
		var w: Vector3 = (e[0] as Node3D).global_transform * (e[1] as Vector3)
		parts.append("%s=(%.2f, %.2f, %.2f)" % [k, w.x, w.y, w.z])
	print("POSE %-18s %s" % [label, "  ".join(parts)])
