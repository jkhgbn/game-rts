extends "res://tests/test_e6m1_sim.gd"
## Mission e6m1 passive check (the Episode 5 rush / passive lesson: the mission must not win itself): the scripted player
## of tests/test_e6m1_sim.gd does nothing at all (the start army idles by the keep, Torvald stands at his start). The
## Wardens walk onto the Heartfrost from 3:00: a passive run must lose; a victory fails.
## `-- --seed N`. Slow. Run: godot --headless --path . -s tests/test_e6m1_passive_sim.gd --fixed-fps 60 --quit-after 90000


func _initialize() -> void:
	passive = true
	super()
