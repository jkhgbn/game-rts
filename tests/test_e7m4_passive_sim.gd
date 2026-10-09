extends "res://tests/test_e7m4_sim.gd"
## Mission e7m4 passive check (the Episode 5 lesson: the mission must not win itself): the scripted player of
## tests/test_e7m4_sim.gd does nothing. Nobody channels the lighthouse, so by 28:00 the run must not have won (the rock
## falls to Malrik after the turn: a defeat, or no ending, both pass; a victory fails).
## `-- --seed N`. Slow. Run: godot --headless --path . -s tests/test_e7m4_passive_sim.gd --fixed-fps 60 --quit-after 120000


func _initialize() -> void:
	passive = true
	super()
