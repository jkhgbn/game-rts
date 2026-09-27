extends Keep
## World Forge map preview: a keep spot the Map Lab recognises (`b is Keep`, group "buildings", `team`) without the
## real building's economy, training, model or HP bar. Its footprint obstacle is a separate layer-1 body.

func _ready() -> void:
	add_to_group(&"buildings")
	process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(_delta: float) -> void:
	pass


func is_alive() -> bool:
	return true
