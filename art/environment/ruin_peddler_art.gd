class_name RuinPeddlerArt
extends Node3D
## Ruin Peddler stand look (docs/design/items.md): hooded peddler at x -0.8, cart (2 x 1 x 1.5) at x 0.6 under
## a striped canopy, lantern orb at (0.6, 1.9, 0). Root = RuinPeddler body origin. Idle only (no hooks):
## the lantern sways and the peddler breathes.

var _t: float = 0.0
var _lantern: Node3D
var _figure: Node3D


func _ready() -> void:
	_lantern = get_node("LanternPivot") as Node3D
	_figure = get_node("Peddler") as Node3D
	_t = randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	_lantern.rotation.z = sin(_t * 1.4) * 0.12
	_lantern.rotation.x = sin(_t * 1.1 + 1.0) * 0.06
	_figure.scale.y = 1.0 + sin(_t * 1.8) * 0.015
