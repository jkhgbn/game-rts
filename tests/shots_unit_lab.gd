extends SceneTree
## Windowed shot of the Unit Lab sandbox (docs/plan/unit-lab.md): loads C1's caster arm, runs 4 s, inspects a unit,
## saves user://unit_lab_shots/shot_sandbox.png. Run (windowed):
##   godot --path . -s tests/shots_unit_lab.gd --quit-after 3000

var lab: Node3D
var frame := 0


func _initialize() -> void:
	lab = (load("res://scenes/unit_lab.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(lab)
	current_scene = lab


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 5:
		lab.call(&"load_setup", "c1_kilnwarden")
		lab.call(&"start_fight")
	if frame == 200:
		var us: Array = lab.call(&"living_units", 0)
		if not us.is_empty():
			lab.set(&"inspected", us[us.size() - 1])
		lab.set(&"show_all_rings", true)
	if frame == 260:
		var img := root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://unit_lab_shots/"))
		img.save_png("user://unit_lab_shots/shot_sandbox.png")
		print("SHOT " + ProjectSettings.globalize_path("user://unit_lab_shots/shot_sandbox.png"))
		return true
	return false
