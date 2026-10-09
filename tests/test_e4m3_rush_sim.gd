extends "res://tests/test_e4m3_sim.gd"
## Mission e4m3 rush check (JS 2026-10-08): the scripted player of tests/test_e4m3_sim.gd pushes every grove at once
## from 0:00; it must still win on normal and take at least RUSH_MIN (16:00) game-minutes (the sturdier guards and
## totems, the 30 s rooting hold). `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s
## tests/test_e4m3_rush_sim.gd --fixed-fps 60 --quit-after 130000


func _initialize() -> void:
	rush = true
	super()
