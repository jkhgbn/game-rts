class_name MissionCagedPeddler
extends RuinPeddler
## Pell, the Ruin Peddler of mission 1, locked in a cage (docs/design/mission-01.md E4). While caged
## he is not a shop (is_shop() false); open_cage() fades the cage bars out over 1 s and opens the shop.

signal freed(peddler: MissionCagedPeddler)

const CAGE_SIZE := Vector3(4.2, 2.6, 3.0)
const BAR_COLOR := Color(0.18, 0.16, 0.2)

var caged := true   ## Read only.

var _cage: Node3D
var _bar_mat: StandardMaterial3D


func _ready() -> void:
	super()
	display_name = "Pell, Ruin Peddler"
	_build_cage()


func is_shop() -> bool:
	return not caged


## Opens the cage (once): bars fade out in 1 s, the shop works from now on.
func open_cage() -> void:
	if not caged:
		return
	caged = false
	if _cage and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_bar_mat, "albedo_color:a", 0.0, 1.0)
		tween.tween_callback(_cage.queue_free)
	freed.emit(self)


func _build_cage() -> void:
	_cage = Node3D.new()
	_cage.name = "Cage"
	add_child(_cage)
	_cage.position = Vector3(0.0, 0.0, 0.0)
	_bar_mat = StandardMaterial3D.new()
	_bar_mat.albedo_color = BAR_COLOR
	_bar_mat.metallic = 0.6
	_bar_mat.roughness = 0.5
	_bar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var half := CAGE_SIZE * 0.5
	var bar := CylinderMesh.new()
	bar.top_radius = 0.05
	bar.bottom_radius = 0.05
	bar.height = CAGE_SIZE.y
	bar.radial_segments = 6
	# Vertical bars every ~0.6 m around the rectangle.
	var step := 0.6
	var xs := int(CAGE_SIZE.x / step)
	var zs := int(CAGE_SIZE.z / step)
	for i in xs + 1:
		var x := -half.x + i * CAGE_SIZE.x / xs
		for z in [-half.z, half.z]:
			_bar(bar, Vector3(x, half.y, z))
	for j in range(1, zs):
		var z := -half.z + j * CAGE_SIZE.z / zs
		for x in [-half.x, half.x]:
			_bar(bar, Vector3(x, half.y, z))
	var roof := BoxMesh.new()
	roof.size = Vector3(CAGE_SIZE.x + 0.2, 0.12, CAGE_SIZE.z + 0.2)
	var mi := MeshInstance3D.new()
	mi.mesh = roof
	mi.material_override = _bar_mat
	mi.position = Vector3(0.0, CAGE_SIZE.y, 0.0)
	_cage.add_child(mi)


func _bar(mesh: Mesh, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _bar_mat
	mi.position = pos
	_cage.add_child(mi)
