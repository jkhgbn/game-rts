extends Node3D
## Young Ysolde for the Episode 4 memories (H03 / H04 baked, H05 live): the Ysolde kit model (child_ysolde_model: no
## antler crown, a flower wreath), but a CHILD, not a scaled adult: a bigger head (child proportions), no staff (her living staff comes later; it also holds
## the model's only light), and a held pose set as the model's rest pose (the kit reads its rest rotations from the
## pivots at _ready), so stills, the bake and the in-game idle all show the same gesture.
## Poses: "stand" (arms down, head level), "coax" (kneeling reach: both hands forward and down over a sapling, head
## bowed), "watch" (hands a little forward, head bowed to the seed at her feet: watching it sleep).

const YSOLDE := "res://art/cinematics/stage_sets/forge_ep4_memories/props/child_ysolde_model.tscn"

@export var pose: StringName = &"stand"
## Overall size: give it as the actor / bake scale (0.55), so World Forge's head estimate (1.6 m x scale) holds.
@export var body_scale: float = 1.0
@export var head_scale: float = 1.3

var model: Node3D = null


func _ready() -> void:
	var ps := load(YSOLDE) as PackedScene
	if ps == null:
		return
	model = ps.instantiate() as Node3D
	model.name = "Ysolde"
	model.scale = Vector3.ONE * body_scale
	var head := model.get_node_or_null(^"Root/Chest/Head") as Node3D
	var chest := model.get_node_or_null(^"Root/Chest") as Node3D
	var arm_l := model.get_node_or_null(^"Root/Chest/ArmL") as Node3D
	var arm_r := model.get_node_or_null(^"Root/Chest/ArmR") as Node3D
	if head:
		head.scale = Vector3.ONE * head_scale
		# a child's head sits a little lower on a shorter neck
		head.position.y -= 0.06
	match pose:
		&"coax":
			if chest:
				chest.rotation_degrees = Vector3(12, 0, 0)
			if head:
				head.rotation_degrees = Vector3(14, 0, 0)
			if arm_l:
				arm_l.rotation_degrees = Vector3(-38, -18, 10)
			if arm_r:
				arm_r.rotation_degrees = Vector3(-32, 20, -10)
		&"watch":
			if head:
				head.rotation_degrees = Vector3(20, 0, 0)
			if arm_l:
				arm_l.rotation_degrees = Vector3(-26, 0, 5)
			if arm_r:
				arm_r.rotation_degrees = Vector3(-26, 0, -5)
		_:
			if head:
				head.rotation_degrees = Vector3(6, 0, 0)
	add_child(model)
	var staff := model.find_child("Staff", true, false) as Node3D
	if staff:
		staff.visible = false
	for l: Node in model.find_children("*", "Light3D", true, false):
		(l as Light3D).visible = false
	# one idle phase for every run (stills / diff / bake agree)
	for k: StringName in [&"_phase_off", &"_tier_timer"]:
		if k in model:
			model.set(k, 0.0)


## The face kit's expression on the wrapped Ysolde model (cine cue `anim y_child set_expression arg=smile`).
func set_expression(id: StringName) -> void:
	if model != null and model.has_method(&"set_expression"):
		model.call(&"set_expression", id)
