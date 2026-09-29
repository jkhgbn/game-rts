extends SceneTree
## Renders the FaceKit one-call presets (FaceKit.attach with a short spec) on a bare test head, so unit agents can see
## what each preset / hair style / beard / ears gives before tuning. Windowed. Writes <out>/presets.png (rows = specs,
## columns = neutral / smile / fierce / worried / shout / far, front 3/4 view) and prints the vertex count per spec.
## Run: tools\godot_run.ps1 --path . -s res://docs/art/faces/tools/preset_shots.gd --quit-after 60000

const T := 260
const SPECS := [
	["bright_bob", {"preset": &"bright", "skin": Color(0.93, 0.76, 0.62), "hair": Color(0.30, 0.16, 0.08), "eyes": Color(0.25, 0.45, 0.70), "ears": &"round", "hair_style": &"bob"}],
	["gentle_long", {"preset": &"gentle", "skin": Color(0.80, 0.60, 0.46), "hair": Color(0.12, 0.08, 0.06), "eyes": Color(0.35, 0.25, 0.12), "ears": &"round", "hair_style": &"long"}],
	["stern_beard", {"preset": &"stern", "skin": Color(0.85, 0.66, 0.52), "hair": Color(0.55, 0.28, 0.12), "eyes": Color(0.30, 0.50, 0.30), "ears": &"round", "hair_style": &"crop", "beard": &"full"}],
	["elder_bun", {"preset": &"elder", "skin": Color(0.88, 0.78, 0.72), "hair": Color(0.78, 0.78, 0.80), "eyes": Color(0.40, 0.45, 0.55), "ears": &"round", "hair_style": &"bun"}],
	["plain_pointed", {"preset": &"plain", "skin": Color(0.62, 0.45, 0.34), "hair": Color(0.70, 0.62, 0.30), "eyes": Color(0.45, 0.60, 0.20), "ears": &"pointed", "hair_style": &"braid"}],
	["plain_ponytail", {"preset": &"plain", "skin": Color(0.95, 0.82, 0.70), "hair": Color(0.60, 0.20, 0.10), "eyes": Color(0.2, 0.3, 0.5), "ears": &"round", "hair_style": &"ponytail", "beard": &"moustache"}],
	["plain_low_crop", {"preset": &"plain", "detail": &"low", "skin": Color(0.88, 0.70, 0.55), "hair": Color(0.25, 0.20, 0.15), "eyes": Color(0.3, 0.4, 0.3), "ears": &"round", "hair_style": &"crop"}],
]
const IDS: Array[StringName] = [&"neutral", &"smile", &"fierce", &"worried", &"shout", &"far"]

var vp: SubViewport
var cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(T, T)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.5, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.7)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.25
	sun.rotation_degrees = Vector3(-52, -35, 0)
	vp.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 24.0
	cam.current = true
	vp.add_child(cam)
	var sheet := Image.create(T * IDS.size(), T * SPECS.size(), false, Image.FORMAT_RGBA8)
	var skin_mat := load("res://art/units/kit/materials/fire_skin.tres") as Material
	for r: int in SPECS.size():
		var spec: Dictionary = (SPECS[r][1] as Dictionary).duplicate()
		spec["center"] = Vector3(0, 1.75, 0)
		spec["radius"] = 0.22
		var model := Node3D.new()
		vp.add_child(model)
		var head := Node3D.new()
		head.name = "Head"
		head.position = Vector3(0, 1.55, 0)
		model.add_child(head)
		var hs := MeshInstance3D.new()
		hs.mesh = CharacterModel.sphere(0.22, 12, 6)
		var sm := (skin_mat as ShaderMaterial).duplicate() as ShaderMaterial
		sm.set_shader_parameter(&"base_color", spec["skin"])
		hs.material_override = sm
		hs.position = Vector3(0, 0.20, 0)
		head.add_child(hs)
		var body := MeshInstance3D.new()
		body.mesh = CharacterModel.cyl(0.20, 0.34, 0.9, 10)
		body.position = Vector3(0, 1.10, 0)
		model.add_child(body)
		var rig := FaceKit.attach(model, head, "preset_" + String(SPECS[r][0]), spec)
		print("PRESET ", SPECS[r][0], " verts=", rig.mesh.surface_get_array_len(0))
		for c: int in IDS.size():
			if IDS[c] == &"far":
				rig.set_expression(&"neutral")
				rig.far()
			else:
				rig.set_expression(IDS[c])
			var p := deg_to_rad(10.0)
			var y := deg_to_rad(25.0)
			var tgt := Vector3(0, 1.66, 0)
			cam.position = tgt + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * 2.3
			cam.rotation = Vector3(-p, y, 0)
			for i: int in 3:
				await process_frame
			var img := vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(img, Rect2i(0, 0, T, T), Vector2i(c * T, r * T))
		model.queue_free()
		await process_frame
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/faces/presets.png"))
	print("PRESET SHOTS done")
	quit(0)
