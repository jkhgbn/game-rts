extends "res://tests/test_e7m3_sim.gd"
## Mission e7m3 passive check (the Episode 5 lesson: the mission must not win itself): the scripted player of
## tests/test_e7m3_sim.gd does nothing. Dawn always comes (the mission is the clock), so the check is the people: no bell
## rings itself, the press-gangs and raiders take the lanes, and sec_people must fail.
## `-- --seed N`. Slow. Run: godot --headless --path . -s tests/test_e7m3_passive_sim.gd --fixed-fps 60 --quit-after 100000


func _initialize() -> void:
	passive = true
	super()
