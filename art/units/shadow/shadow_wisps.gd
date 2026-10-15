extends GPUParticles3D
## G-C soul wisps gate (knight blade, thrall lantern). Lives on the SoulWisps particle node, which exists only at
## High+ on Shadow Knights and Gloom Thralls, so the 200-unit perf scenes pay nothing. The owning ShadowModel's own
## _process stops early while it is frozen (off-screen or far), so the gate cannot live in _extra_process: this node
## polls ShadowModel.wisps_should_emit() 5x / s and turns emitting off as soon as the unit goes off-screen, far,
## frozen or dead. The wisps are never in the kit's _loop_fx list (its tier update would turn them back on).

const CHECK := 0.2

var model: ShadowModel
var _left: float = 0.0


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = CHECK
	var on: bool = model != null and is_instance_valid(model) and model.wisps_should_emit()
	if on != emitting:
		emitting = on
