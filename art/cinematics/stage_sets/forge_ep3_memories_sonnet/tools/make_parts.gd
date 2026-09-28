extends "res://art/cinematics/stage_sets/forge_ep3_memories_sonnet/tools/make_g09.gd"
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_ep3_memories_sonnet/tools/make_parts.gd --quit-after 3000


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_materials()
	_light_preset()
	_part("corner_g03", _g03)
	_part("corner_g04", _g04)
	_part("corner_g09", _g09)
	_part("candle", _candle)
	_part("flame_r", func() -> void: _flame(Color(1.0, 0.2, 0.08)))
	_part("flame_b", func() -> void: _flame(Color(0.22, 0.52, 1.0)))
	_part("flame_g", func() -> void: _flame(Color(0.3, 1.0, 0.32)))
	_part("flame_v", func() -> void: _flame(Color(0.68, 0.28, 1.0)))
	_part("stone", _stone_actor)
	var pin := Node3D.new()
	pin.name = "subject_pin"
	var ps := PackedScene.new()
	ps.pack(pin)
	ResourceSaver.save(ps, PARTS + "/subject_pin.tscn")
	pin.free()
	quit()
