extends "res://tests/test_e8_sim.gd"
## e8m2 passive check (the Episode 5 lesson: the mission must not win itself; tests/test_e8_sim.gd -- --passive). Slow.
## Run: godot --headless --path . -s tests/test_e8m2_passive_sim.gd --fixed-fps 60 --quit-after 150000


func _initialize() -> void:
	mission = "e8m2"
	passive = true
	super()
