extends "res://tests/test_e6m2_sim.gd"
## Mission e6m2 shut-branch check (docs/design/mission-e6-02.md acceptance "Timing": the shut branch survives to 20:00):
## the scripted player of tests/test_e6m2_sim.gd never answers the rider (the fire dies = shut), holds the army behind
## the Frostgate and sends the detachment to the mere at each telegraph. It must win at dawn, never earlier.
## `-- --seed N`, `-- --verbose`. Slow. Run: godot --headless --path . -s tests/test_e6m2_shut_sim.gd --fixed-fps 60
## --quit-after 90000


func _initialize() -> void:
	shut = true
	super()
