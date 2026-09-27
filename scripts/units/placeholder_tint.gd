class_name PlaceholderTint
extends Node
## PLACEHOLDER marker for a unit model that has no art yet (docs/design/new-units-12.md 6): a child of a wrapper scene
## that instances another unit's model. It lays a translucent kingdom-tinted overlay on every mesh of its parent so the
## stand-in reads as "not the real unit". Delete the wrapper scene once the real model lands.

@export var tint := Color(1.0, 0.5, 0.2, 0.35)

static var _mats: Dictionary = {}   # Color -> StandardMaterial3D (shared)


func _ready() -> void:
	# Models build (and merge) their meshes in their own _ready, which runs after this child's.
	_apply.call_deferred()


func _apply() -> void:
	var host := get_parent()
	if host == null:
		return
	var mat: StandardMaterial3D = _mats.get(tint)
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mats[tint] = mat
	_tint(host, mat)


func _tint(n: Node, mat: Material) -> void:
	var g := n as GeometryInstance3D
	if g and not String(g.name).to_lower().contains("shadow"):
		g.material_overlay = mat
	for c in n.get_children():
		_tint(c, mat)
