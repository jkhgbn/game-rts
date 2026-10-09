extends "res://tests/test_e5m1_sim.gd"
## Mission e5m1 rush check (the e4m3 lesson: guard objectives properly): the scripted player of tests/test_e5m1_sim.gd
## walks Vessa, Vey and whatever army she has to every beacon at once from 0:00 (no waiting, no home defence). A beacon
## does not catch while its guard stands within 8 m, the hold is 1:30 and Gannet only comes with the +40 s group: the
## rush must not win faster than RUSH_MIN (10:00 play time, the spec's easy lower bound); a lost rush passes.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e5m1_rush_sim.gd --fixed-fps 60
## --quit-after 80000


func _initialize() -> void:
	rush = true
	super()
