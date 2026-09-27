class_name BuildGhost
extends Node3D
## The placement ghost of the build menu (docs/design/buildings.md, "Ghost"): the building's
## placeholder shape at alpha 0.5, green (0.3, 1.0, 0.4) when the spot is valid, red (1.0, 0.3, 0.3)
## when not, plus a flat quad on every footprint cell. SelectionManager moves it (snapped with
## BuildGrid.snap) and shows the refusal message above it.

const VALID_COLOR := Color(0.3, 1.0, 0.4, 0.5)
const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.5)
const CELL := 2.0

var type: BuildingType = null   ## Read only: the building shown.
var valid := true               ## Read only.

var _mat: StandardMaterial3D
var _cell_mat: StandardMaterial3D
var _shape: Node3D


func _init() -> void:
	_mat = _material(0.5)
	_cell_mat = _material(0.3)
	visible = false


## Shows the ghost of `building_type` (rebuilds the shape when the type changes).
func show_type(building_type: BuildingType) -> void:
	if building_type != type:
		type = building_type
		_rebuild()
	visible = type != null


func set_valid(value: bool) -> void:
	valid = value
	var c := VALID_COLOR if value else INVALID_COLOR
	_mat.albedo_color = c
	_cell_mat.albedo_color = Color(c.r, c.g, c.b, 0.3)


## The top of the shape (metres above the ground), for the message above it.
func top_height() -> float:
	if type == null:
		return 2.0
	return type.height + (1.5 if type.kind == &"barracks" or type.kind == &"house" else 0.5)


func _rebuild() -> void:
	if _shape:
		_shape.queue_free()
		_shape = null
	if type == null:
		return
	_shape = Node3D.new()
	add_child(_shape)
	var s := type.size_m()
	var h := type.height
	match type.kind:
		&"tower":
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.9
			cyl.bottom_radius = 0.9
			cyl.height = h
			_add(cyl, _mat, h * 0.5)
			var orb := SphereMesh.new()
			orb.radius = 0.25
			orb.height = 0.5
			_add(orb, _mat, h + 0.25)
		&"house":
			var box := BoxMesh.new()
			box.size = Vector3(s.x, h, s.y)
			_add(box, _mat, h * 0.5)
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = s.length() * 0.5 + 0.1
			cone.height = 1.5
			cone.radial_segments = 4
			_add(cone, _mat, h + 0.75).rotation.y = PI / 4.0
		&"barracks":
			var box := BoxMesh.new()
			box.size = Vector3(s.x, h, s.y)
			_add(box, _mat, h * 0.5)
			var roof := PrismMesh.new()
			roof.size = Vector3(s.x, 1.5, s.y)
			_add(roof, _mat, h + 0.75)
		_:
			var box := BoxMesh.new()
			box.size = Vector3(s.x, h, s.y)
			_add(box, _mat, h * 0.5)
	# One flat quad per footprint cell (a small gap between them shows the grid).
	for i in type.footprint.x:
		for j in type.footprint.y:
			var quad := PlaneMesh.new()
			quad.size = Vector2(CELL - 0.12, CELL - 0.12)
			var cell := _add(quad, _cell_mat, 0.04)
			cell.position.x = (float(i) - (type.footprint.x - 1) * 0.5) * CELL
			cell.position.z = (float(j) - (type.footprint.y - 1) * 0.5) * CELL


func _add(mesh: Mesh, mat: Material, y: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = y
	_shape.add_child(mi)
	return mi


func _material(alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(VALID_COLOR.r, VALID_COLOR.g, VALID_COLOR.b, alpha)
	return m
