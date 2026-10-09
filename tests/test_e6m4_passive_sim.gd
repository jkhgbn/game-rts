extends "res://tests/test_e6m4_sim.gd"
## Mission e6m4 passive check (the Episode 5 lesson: the mission must not win itself): the scripted player of
## tests/test_e6m4_sim.gd does nothing (Ysolde's army idles at the start; Torvald's ally bot still plays). The Host
## reaches the stone, the hold stalls and the seal breaks: a passive run must lose; a victory fails.
## `-- --seed N`. Slow. Run: godot --headless --path . -s tests/test_e6m4_passive_sim.gd --fixed-fps 60 --quit-after 100000


func _initialize() -> void:
	passive = true
	super()
