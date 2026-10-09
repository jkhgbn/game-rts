extends "res://tests/test_e5m4_sim.gd"
## Mission e5m4 passive check (docs/design/mission-e5-04.md E5M4.S2 (b)): the scripted player of tests/test_e5m4_sim.gd
## keeps the whole army at home; Vessa's banner plan must win on her bell (a defeat, after 5:00 and not before the
## counting bell opens). `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s
## tests/test_e5m4_passive_sim.gd --fixed-fps 60 --quit-after 110000


func _initialize() -> void:
	passive = true
	super()