extends "res://tests/test_e7m2_sim.gd"
## Mission e7m2 passive check (the Episode 5 lesson: the mission must not win itself): the scripted player of
## tests/test_e7m2_sim.gd does nothing. No barricade falls and no clue reads itself: by 25:00 the run must not have won
## (a defeat or no ending both pass; a victory fails).
## `-- --seed N`. Slow. Run: godot --headless --path . -s tests/test_e7m2_passive_sim.gd --fixed-fps 60 --quit-after 100000


func _initialize() -> void:
	passive = true
	super()
