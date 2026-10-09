extends "res://tests/test_e8_sim.gd"
## e8m1_nature timing check (tests/test_e8_sim.gd; the spec's target, scripted run on normal). Slow.
## Run: godot --headless --path . -s tests/test_e8m1_nature_sim.gd --fixed-fps 60 --quit-after 150000


func _initialize() -> void:
	mission = "e8m1_nature"
	super()
