extends SceneTree
## Task 12.V32 previews: the four lair scenes on the REAL skirmish map (bot off, fog off, HUD hidden) at the lair
## centres of EpicBeasts.default_lairs() (yaw 0 on the west bank, PI on the east bank = the point mirror), the game
## camera (pitch 55). Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/lairs/lairs_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 12000
## User args (after `--`): `only=<shot>,<shot>` limits the shots; `nolairs=1` shoots the bare map (context, saved as
## 12_v32_bare_*); `empty=1` shows the lairs with set_occupied(false).
## Saves docs/art/screens/12_v32_<shot>.png. *_e_* shots are the east-bank mirrors (seen from the player's camera,
## i.e. from their "back"). sil_* = unshaded black silhouettes on white at 40 m.

const LAIR_DIR := "res://art/environment/lairs/"
const SHOT_PREFIX := "res://docs/art/screens/12_v32_"
## Lair id -> scene file (the four kinds; the east lairs reuse the west scene turned by PI).
const SCENES := {
	&"lair_heath_w": "heath_wallow.tscn", &"lair_heath_e": "heath_wallow.tscn",
	&"lair_crag_w": "crag_nest.tscn", &"lair_crag_e": "crag_nest.tscn",
	&"lair_hollow_w": "greymane_hollow.tscn", &"lair_hollow_e": "greymane_hollow.tscn",
	&"lair_den_w": "old_wood_den.tscn", &"lair_den_e": "old_wood_den.tscn",
}
## Scale references (load-guarded): the beast models when they exist, else a stand-in.
const SCALE_UNITS := {
	&"heath": ["res://art/units/neutral/beasts/tusker/tusker.tscn", "res://art/units/neutral/bristleback/bristleback.tscn"],
	&"crag": ["res://art/units/neutral/beasts/roc/roc.tscn", ""],
	&"hollow": ["res://art/units/neutral/beasts/direwolf/direwolf.tscn", "res://art/units/neutral/critters/deer.tscn"],
	&"den": ["res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn", ""],
}

var _only := ""
var _no_lairs := false
var _empty := false
var _beasts := true
var _rig: Node3D
var _main: Node
var _lairs: Array[Node3D] = []
var _env: Environment


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5)
		elif arg == "nolairs=1":
			_no_lairs = true
		elif arg == "empty=1":
			_empty = true
		elif arg == "beasts=0":
			_beasts = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_run()


func _wanted(shot: String) -> bool:
	return _only == "" or _only.split(",").has(shot)


func _run() -> void:
	_main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = _main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(_main)
	current_scene = _main
	var wait := 0
	while _main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	for i in 20:
		await process_frame
	var fog: Node = _main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in _main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = _main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_rig = _main.get(&"camera_rig")
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)
	var we: WorldEnvironment = null
	for n2: Node in _main.find_children("*", "WorldEnvironment", true, false):
		we = n2 as WorldEnvironment
	_env = we.environment if we else null
	var eb: GDScript = load("res://scripts/world/epic_beasts.gd") as GDScript
	var lairs: Array = eb.call(&"default_lairs")
	var centers := {}
	for l: Dictionary in lairs:
		centers[l["id"]] = l["center"]
		if _no_lairs:
			continue
		var path: String = LAIR_DIR + String(SCENES[l["id"]])
		if not ResourceLoader.exists(path):
			print("missing ", path)
			continue
		var lair := (load(path) as PackedScene).instantiate() as Node3D
		_main.add_child(lair)
		lair.position = l["center"]
		lair.rotation.y = PI if String(l["id"]).ends_with("_e") else 0.0
		if lair.has_method(&"set_occupied"):
			lair.call(&"set_occupied", not _empty)
		_lairs.append(lair)
		if _beasts:
			_add_scale_unit(StringName(String(l["id"]).split("_")[1]), lair)
	var pre: String = "bare_" if _no_lairs else ("empty_" if _empty else ("" if _beasts else "nb_"))
	var shots: Array = [
		# [name, zoom, focus offset from the lair centre (in the lair's own frame), lair id, camera yaw]
		["heath_z40", 40.0, Vector3(0, 0, 2), &"lair_heath_w", 0.0],
		["heath_z20", 20.0, Vector3(0, 0, 1), &"lair_heath_w", 0.0],
		["heath_z10", 10.0, Vector3(0, 0, 0.5), &"lair_heath_w", 0.0],
		["heath_e_z20", 20.0, Vector3(0, 0, 1), &"lair_heath_e", 0.0],
		["crag_z40", 40.0, Vector3(-1, 0, 2), &"lair_crag_w", 0.0],
		["crag_z20", 20.0, Vector3(-2, 0, 1), &"lair_crag_w", 0.0],
		["crag_z10", 10.0, Vector3(-3, 0, 1.3), &"lair_crag_w", 0.0],
		["crag_e_z20", 20.0, Vector3(-2, 0, 1), &"lair_crag_e", 0.0],
		["hollow_z40", 40.0, Vector3(0, 0, 2), &"lair_hollow_w", 0.0],
		["hollow_z20", 20.0, Vector3(0, 0, 0), &"lair_hollow_w", 0.0],
		["hollow_z10", 10.0, Vector3(0.2, 0, -0.9), &"lair_hollow_w", 0.0],
		["hollow_e_z20", 20.0, Vector3(0, 0, 1), &"lair_hollow_e", 0.0],
		["den_z40", 40.0, Vector3(1, 0, 0), &"lair_den_w", 0.0],
		["den_z20", 20.0, Vector3(1.8, 0, -1.2), &"lair_den_w", 0.0],
		["den_z10", 10.0, Vector3(2.4, 0, -2.2), &"lair_den_w", 0.0],
		["den_z6", 6.0, Vector3(2.4, 0, -2.6), &"lair_den_w", 0.0],
		["heath_z6", 6.0, Vector3(0.2, 0, -0.1), &"lair_heath_w", 0.0],
		["crag_z6", 6.0, Vector3(-1.0, 0, 1.2), &"lair_crag_w", 0.0],
		["hollow_z6", 6.0, Vector3(0.2, 0, -1.0), &"lair_hollow_w", 0.0],
		["den_e_z20", 20.0, Vector3(1.8, 0, -1.2), &"lair_den_e", 0.0],
		["den_e_z10", 10.0, Vector3(2.4, 0, -2.2), &"lair_den_e", 0.0],
	]
	for s: Array in shots:
		if not _wanted(pre + String(s[0])):
			continue
		var c: Vector3 = centers[s[3]]
		var off: Vector3 = s[2]
		if String(s[3]).ends_with("_e"):
			off = -off
		await _shoot(pre + String(s[0]), s[1], c + off, s[4])
	if not _no_lairs:
		var sil: Array = [["sil_heath_z40", 40.0, &"lair_heath_w"], ["sil_crag_z40", 40.0, &"lair_crag_w"],
			["sil_hollow_z40", 40.0, &"lair_hollow_w"], ["sil_den_z40", 40.0, &"lair_den_w"]]
		var any := false
		for s2: Array in sil:
			any = any or _wanted(s2[0])
		if any:
			await _silhouette_stage(sil, centers)
	print("SHOTS DONE")
	quit()


func _add_scale_unit(kind: StringName, lair: Node3D) -> void:
	var paths: Array = SCALE_UNITS.get(kind, [])
	for p: String in paths:
		if p != "" and ResourceLoader.exists(p):
			var u := (load(p) as PackedScene).instantiate() as Node3D
			_main.add_child(u)
			var spot: Vector3 = lair.get_meta(&"beast_rest", Vector3(0, 0, 0))
			u.global_position = lair.global_transform * spot
			u.rotation.y = lair.rotation.y + 2.3
			if u.has_method(&"set_variant"):
				u.call(&"set_variant", 0)
			return


func _shoot(shot: String, zoom: float, focus: Vector3, yaw: float, frames: int = 50) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.rotation.y = yaw
	_rig.call(&"focus_on", focus)
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(SHOT_PREFIX + shot + ".png"))
	print("shot %-20s draws=%d prims=%d" % [shot, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])


## Silhouettes (art-keep.md 0.1): a bare stage (white background, no ground), each lair black and unshaded at its
## real spot, the Fallen Colossus in pale grey behind the nest for context; the game camera at 40 m.
func _silhouette_stage(sil: Array, centers: Dictionary) -> void:
	_main.queue_free()
	await process_frame
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.WHITE
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env
	stage.add_child(we)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var grey := StandardMaterial3D.new()
	grey.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grey.albedo_color = Color(0.78, 0.78, 0.78)
	var clear := StandardMaterial3D.new()
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.albedo_color = Color(1, 1, 1, 0)
	var colossus_path := "res://art/environment/landmarks/colossus.tscn"
	if ResourceLoader.exists(colossus_path):
		var lm := (load(colossus_path) as PackedScene).instantiate() as Node3D
		stage.add_child(lm)
		lm.position = Vector3(-57.0, 0.0, -16.0)
		var mi0 := lm.get_node_or_null(^"Model") as MeshInstance3D
		if mi0:
			for s in mi0.mesh.get_surface_count():
				var m0: Material = mi0.mesh.surface_get_material(s)
				mi0.set_surface_override_material(s, clear if m0 != null and m0.resource_path.contains("contact") else grey)
	for s3: Array in sil:
		var id: StringName = s3[2]
		var lair := (load(LAIR_DIR + String(SCENES[id])) as PackedScene).instantiate() as Node3D
		stage.add_child(lair)
		lair.position = centers[id]
		for mi: Node in lair.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			if m3.name == "Active":
				m3.visible = true
			if m3.name == "Dormant":
				m3.visible = false
			for s in m3.mesh.get_surface_count():
				var m: Material = m3.mesh.surface_get_material(s)
				var flat: bool = m != null and (m.resource_path.contains("contact") or m.resource_path.contains("web"))
				m3.set_surface_override_material(s, clear if flat else black)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	for s4: Array in sil:
		if _wanted(s4[0]):
			await _shoot(s4[0], s4[1], centers[s4[2]], 0.0)