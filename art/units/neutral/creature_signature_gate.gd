extends GPUParticles3D
## G-D creature signature gate (CreatureSignature). Lives on the "Signature" particle node, which exists only at
## High / Ultra. The owning model's _process stops while it is frozen off-screen or far, so the gate cannot live in its
## _extra_process: this node polls the model 5x / s and emits only while `model.signature_should_emit()` (near tier,
## not frozen, alive) and the model is on-screen within 30 m (CreatureSignature.on_screen). Never in a kit _loop_fx
## list (a tier change there would turn it back on).

const CHECK := 0.2

var model: Node3D
var _left: float = 0.0


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = CHECK
	var on: bool = model != null and is_instance_valid(model) and bool(model.call(&"signature_should_emit")) \
		and CreatureSignature.on_screen(model)
	if on != emitting:
		emitting = on
