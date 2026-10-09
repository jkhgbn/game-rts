extends "res://tests/test_e5m2_sim.gd"
## Mission e5m2 rush check (the e4m3 lesson: guard objectives properly): the scripted player of tests/test_e5m2_sim.gd
## sends Vessa, Ashby and whatever army she has down the Causeway from 0:00 (no waiting: the bands spring on her), then
## straight at the Rook Gate and the Nest. It must not win faster than RUSH_MIN (14:00 play time, the spec's easy lower
## bound); a lost rush passes. `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s
## tests/test_e5m2_rush_sim.gd --fixed-fps 60 --quit-after 110000


func _initialize() -> void:
	rush = true
	super()