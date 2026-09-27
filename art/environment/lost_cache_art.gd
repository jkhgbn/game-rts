class_name LostCacheArt
extends Node3D
## Lost Cache chest look (docs/design/items.md): 1.0 x 0.7 x 0.7 chest, gold bands, glowing lock gem.
## Root = chest centre on the ground. The lid hinges on its -z edge.
## Hook: LostCache calls `set_open(true)` when a wizard opens it (lid swings to -70 deg, gold glow inside)
## and `set_open(false)` when it resets / reappears. Fading the chest out stays in LostCache (hide the node).

const OPEN_ANGLE := -70.0

var _open: bool = false
var _lid: Node3D
var _glow: Node3D
var _tween: Tween


func _ready() -> void:
	_lid = get_node("LidPivot") as Node3D
	_glow = get_node("InnerGlow") as Node3D
	_lid.rotation.x = deg_to_rad(OPEN_ANGLE) if _open else 0.0
	_glow.visible = _open


func set_open(b: bool) -> void:
	_open = b
	if not is_node_ready():
		return
	if _tween:
		_tween.kill()
	_glow.visible = b
	_tween = create_tween()
	var target: float = deg_to_rad(OPEN_ANGLE) if b else 0.0
	_tween.tween_property(_lid, "rotation:x", target, 0.4 if b else 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_open() -> bool:
	return _open
