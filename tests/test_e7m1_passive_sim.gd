extends "res://tests/test_e7m1_sim.gd"
## Mission e7m1 passive check (the Episode 5 lesson: the mission must not win itself): the scripted player of
## tests/test_e7m1_sim.gd does nothing (no Bazaar, no bid; Malrik's ally bot still plays). Aurivane wins A1 and A2 (or
## the harbour falls): a passive run must lose; a victory fails.
## `-- --seed N`. Slow. Run: godot --headless --path . -s tests/test_e7m1_passive_sim.gd --fixed-fps 60 --quit-after 110000


func _initialize() -> void:
	passive = true
	super()
