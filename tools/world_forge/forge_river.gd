extends Node3D
## World Forge map preview: the river's crossing list in RiverSystem shape (group "river", `crossings()`), so the Map
## Lab measures crossing widths on the preview navmesh. The water itself is a set of layer-1 obstacles.

var _crossings: Array[Dictionary] = []


func setup(list: Array[Dictionary]) -> void:
	_crossings = list
	add_to_group(&"river")


func crossings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in _crossings:
		out.append(c.duplicate())
	return out
