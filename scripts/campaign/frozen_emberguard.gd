class_name MissionFrozenEmberguard
extends MissionBrazier
## A Frozen Emberguard block of mission 2 (docs/design/mission-02.md "Frozen Emberguard"): Fire scouts caught in
## Torvald's ice. The MissionBrazier rule (the `lighter` within 3 m for 3 s, a progress ring, leaving resets) thaws it:
## `lit_up` fires, the block fades in 1 s and a low ice stump stays. The mission spawns the squad.
## Placeholder art (M9.V1): a 2.4 x 2.0 x 2.4 translucent block with 3 dim silhouettes inside; no brazier bowl.

const BLOCK_SIZE := Vector3(2.4, 2.0, 2.4)
const BLOCK_COLOR := Color(0.70, 0.88, 1.0, 0.55)
const BODY_RADIUS := 1.2

var _block: Node3D
var _block_mat: StandardMaterial3D


func _ready() -> void:
	super()
	for c in get_children():
		var col := c as CollisionShape3D
		if col and col.shape is CylinderShape3D:
			var s := CylinderShape3D.new()
			s.radius = BODY_RADIUS
			s.height = BLOCK_SIZE.y
			col.shape = s
			col.position.y = BLOCK_SIZE.y * 0.5
	lit_up.connect(_on_thawed)


func _build_look() -> void:
	super()
	# Hide the brazier stone (stem + bowl, the first two meshes) and the fire: a thaw, not a flame.
	var hidden := 0
	for c in get_children():
		if c is MeshInstance3D and hidden < 2:
			(c as MeshInstance3D).visible = false
			hidden += 1
	_ring_mat.albedo_color = Color(0.55, 0.85, 1.0, 0.55)
	_block = Node3D.new()
	_block.name = "IceBlock"
	add_child(_block)
	_block_mat = StandardMaterial3D.new()
	_block_mat.albedo_color = BLOCK_COLOR
	_block_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_block_mat.roughness = 0.1
	_block_mat.rim_enabled = true
	_block_mat.rim = 0.5
	var box := BoxMesh.new()
	box.size = BLOCK_SIZE
	var bmi := MeshInstance3D.new()
	bmi.mesh = box
	bmi.material_override = _block_mat
	bmi.position.y = BLOCK_SIZE.y * 0.5
	_block.add_child(bmi)
	var sil := StandardMaterial3D.new()
	sil.albedo_color = Color(0.25, 0.18, 0.15, 0.7)
	sil.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 3:
		var cap := CapsuleMesh.new()
		cap.radius = 0.22
		cap.height = 1.5
		var mi := MeshInstance3D.new()
		mi.mesh = cap
		mi.material_override = sil
		mi.position = Vector3(-0.6 + i * 0.6, 0.8, -0.2 + (i % 2) * 0.4)
		_block.add_child(mi)
	var stump := CylinderMesh.new()
	stump.top_radius = BODY_RADIUS * 0.9
	stump.bottom_radius = BODY_RADIUS
	stump.height = 0.3
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.78, 0.9, 1.0)
	var smi := MeshInstance3D.new()
	smi.name = "Stump"
	smi.mesh = stump
	smi.material_override = smat
	smi.position.y = 0.15
	add_child(smi)


func _on_thawed(_b: MissionBrazier) -> void:
	# The brazier's flame / light do not belong to a thaw: off at once.
	if _flame:
		_flame.emitting = false
		_flame.visible = false
	if _light:
		_light.visible = false
	if _block and is_inside_tree():
		var tw := create_tween()
		tw.tween_property(_block_mat, "albedo_color:a", 0.0, 1.0)
		tw.tween_callback(_block.hide)
