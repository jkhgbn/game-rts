extends "res://tests/test_e5m3_sim.gd"
## Mission e5m3 rush check (the e4m3 lesson: guard objectives properly): the scripted player of tests/test_e5m3_sim.gd
## takes the direct route (the three crypts in order, no graves, no tombstones, no waiting for patrols) and goes for the
## bell. The bell only rings at midnight (10:00 on normal): the rush must not win faster than RUSH_MIN (11:00 play
## time); a lost rush passes. `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s
## tests/test_e5m3_rush_sim.gd --fixed-fps 60 --quit-after 80000


func _initialize() -> void:
	rush = true
	super()