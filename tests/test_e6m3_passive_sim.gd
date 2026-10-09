extends "res://tests/test_e6m3_sim.gd"
## Mission e6m3 passive check (docs/design/mission-e6-03.md acceptance: "a run with no tending keeps <= 2"): the
## scripted player of tests/test_e6m3_sim.gd does nothing (no tending, the army idle at the start). It must end with at
## most 2 gardens (on normal that is a defeat the moment the third falls); a spring with 3+ fails.
## `-- --seed N`. Slow. Run: godot --headless --path . -s tests/test_e6m3_passive_sim.gd --fixed-fps 60 --quit-after 80000


func _initialize() -> void:
	passive = true
	super()
