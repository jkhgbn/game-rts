extends MeshInstance3D
## Stand-in for the Artifact gem motion in crown_stage.gd (spin 1.5 rad/s, bob 0.15 m at 2 rad/s).

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	rotation.y += delta * 1.5
	position.y = 1.8 + sin(_t * 2.0) * 0.15
