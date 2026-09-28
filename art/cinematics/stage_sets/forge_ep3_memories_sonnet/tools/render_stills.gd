extends SceneTree
## Windowed: tools\godot_run.ps1 --path . -s res://art/cinematics/stage_sets/forge_ep3_memories_sonnet/tools/render_stills.gd
const ID := "forge_ep3_memories_sonnet"
const OUT := "res://docs/art/trials/sonnet_ep3"
const ALL := ["boy", "boy_hall", "flame_r", "flame_b", "flame_g", "flame_v", "stone"]
# shot: [from, look, fov, visible actors]
const SHOTS := {
	"G03": [Vector3(-22.9, 0.55, 3.7), Vector3(-24.4, 1.05, -1.4), 34.0, ["boy"]],
	"G04": [Vector3(-4.6, 1.25, 4.0), Vector3(-0.2, 1.6, -5.0), 40.0, ["boy_hall", "flame_r", "flame_b", "flame_g", "flame_v"]],
	"G06": [Vector3(-4.6, 1.25, 4.0), Vector3(-0.2, 1.6, -5.0), 40.0, ["boy_hall"]],
	"G09": [Vector3(26.3, 1.0, 4.4), Vector3(24.3, 1.0, -2.0), 36.0, ["stone"]],
}

func _initialize() -> void:
	_run.call_deferred()

func _find(n: Node, nm: String) -> Node:
	if n.name == nm:
		return n
	for c in n.get_children():
		var r := _find(c, nm)
		if r:
			return r
	return null

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	root.size = Vector2i(1600, 900)
	var inst: Node = (load("res://art/cinematics/stage_sets/%s/%s.tscn" % [ID, ID]) as PackedScene).instantiate()
	root.add_child(inst)
	var rig: Node = LightingRig.new()
	rig.set(&"preset", inst.get(&"lighting"))
	root.add_child(rig)
	var cam := Camera3D.new()
	cam.far = 400.0
	root.add_child(cam)
	cam.current = true
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	var bh := int((900.0 - 1600.0 / 2.39) * 0.5)
	for y in [0, 1]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, 0 if y == 0 else 900 - bh)
		bar.size = Vector2(1600, bh)
		layer.add_child(bar)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for shot: String in SHOTS:
		var s: Array = SHOTS[shot]
		for a: String in ALL:
			var n := _find(inst, a)
			if n is Node3D:
				(n as Node3D).visible = a in s[3]
		cam.fov = s[2]
		cam.global_transform = Transform3D.IDENTITY.translated(s[0]).looking_at(s[1], Vector3.UP)
		for i in 15:
			await process_frame
		var img := root.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, shot]))
		print("saved ", shot)
	quit()
