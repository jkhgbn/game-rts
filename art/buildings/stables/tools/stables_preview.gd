extends SceneTree
## Quick windowed preview of the four Stables (tech-artist iteration tool, not the grade: the grade is the Art Lab +
## stables_capture.gd in a real skirmish). One row per kingdom on the skirmish ground material, RTS camera (pitch 55,
## fov 50): player side (yaw -90), enemy side (yaw +90, another team colour), back (yaw 0 = the lab's view), then the
## states: site 15 %, site 50 %, 40 % HP, 20 % HP, collapse at 1.2 s and 2.8 s, a training pulse (gate open).
## Run: tools\godot_run.ps1 --path . -s res://art/buildings/stables/tools/stables_preview.gd --quit-after 60000
##   -- --only=fire,ice   (default all)   --tag=v1
## Shots: docs/art/lab/stables_preview/<tag>_<kingdom>_<shot>.png and <tag>_sheet_*.png

const OUT := "res://docs/art/lab/stables_preview"
const KINGDOMS: Array[String] = ["fire", "shadow", "ice", "nature"]
const TEAM := {"fire": Color(0.85, 0.30, 0.12), "shadow": Color(0.42, 0.22, 0.60), "ice": Color(0.45, 0.75, 0.95),
	"nature": Color(0.35, 0.70, 0.25)}
const ENEMY := {"fire": Color(0.42, 0.22, 0.60), "shadow": Color(0.85, 0.30, 0.12), "ice": Color(0.35, 0.70, 0.25),
	"nature": Color(0.45, 0.75, 0.95)}
const COLS := ["player", "enemy", "back", "site15", "site50", "hp40", "hp20", "dead", "pulse"]
const STEP := 11.0
const ORIGIN := Vector3(-50, 0, 24)

var cam: Camera3D
var tag := "v1"
var cells: Dictionary = {}


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var args := {}
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	tag = String(args.get("tag", "v1"))
	var only: Array = String(args.get("only", ",".join(KINGDOMS))).split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DisplayServer.window_set_size(Vector2i(1600, 900))
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = load("res://art/environment/world_env.tres")
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.transform = Transform3D(Basis(Vector3(0.819152, 0, -0.573576), Vector3(-0.4393, 0.642788, -0.627399),
		Vector3(0.368688, 0.766044, 0.526541)), Vector3(0, 20, 0))
	sun.light_color = Color(1, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 120.0
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 120)
	ground.mesh = pm
	ground.material_override = load("res://art/environment/ground_material.tres")
	ground.position = Vector3(-30, 0, 30)
	world.add_child(ground)
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.far = 400.0
	world.add_child(cam)
	var row: int = 0
	for k: String in KINGDOMS:
		if not only.has(k):
			continue
		var path := "res://art/buildings/stables/%s/%s_stables.tscn" % [k, k]
		if not ResourceLoader.exists(path):
			continue
		var scene := load(path) as PackedScene
		for c: int in COLS.size():
			var col: String = COLS[c]
			var yaw: float = -PI * 0.5
			if col == "enemy":
				yaw = PI * 0.5
			elif col == "back":
				yaw = 0.0
			var h := Node3D.new()
			h.position = ORIGIN + Vector3(STEP * c, 0, STEP * row)
			world.add_child(h)
			var m := scene.instantiate() as Node3D
			m.rotation.y = yaw
			m.call(&"set_team_color", ENEMY[k] if col == "enemy" else TEAM[k])
			h.add_child(m)
			cells["%s_%s" % [k, col]] = m
		row += 1
	for i in 10:
		await process_frame
	for key: String in cells:
		var m: Node3D = cells[key]
		if key.ends_with("site15"):
			m.call(&"set_construction_progress", 0.15)
		elif key.ends_with("site50"):
			m.call(&"set_construction_progress", 0.5)
		elif key.ends_with("hp40"):
			m.call(&"set_health_ratio", 0.4)
		elif key.ends_with("hp20"):
			m.call(&"set_health_ratio", 0.2)
	await _wait(1.0)
	row = 0
	for k: String in KINGDOMS:
		if not cells.has("%s_player" % k):
			continue
		var z0: float = STEP * row
		await _shot("%s_z30" % k, Vector3(0, 1.5, z0), 30.0)
		await _shot("%s_z16" % k, Vector3(0, 2.0, z0), 16.0)
		await _shot("%s_z16_enemy" % k, Vector3(STEP, 2.0, z0), 16.0)
		await _shot("%s_z16_back" % k, Vector3(STEP * 2, 2.0, z0), 16.0)
		await _shot("%s_low" % k, Vector3(0, 2.5, z0), 13.0, 25.0)
		await _shot("%s_states" % k, Vector3(STEP * 5, 1.0, z0), 40.0)
		row += 1
	# Collapse + pulse (all rows at once).
	for key: String in cells:
		if key.ends_with("_dead"):
			(cells[key] as Node).call(&"play_destroyed")
		elif key.ends_with("_pulse"):
			(cells[key] as Node).call(&"play_training_pulse")
	await _wait(0.5)
	row = 0
	for k: String in KINGDOMS:
		if cells.has("%s_player" % k):
			await _shot("%s_pulse" % k, Vector3(STEP * 8, 2.0, STEP * row), 16.0, 55.0, 0.0)
			row += 1
	await _wait(0.4)
	row = 0
	for k: String in KINGDOMS:
		if cells.has("%s_player" % k):
			await _shot("%s_dead12" % k, Vector3(STEP * 7, 1.5, STEP * row), 18.0, 55.0, 0.0)
			row += 1
	await _wait(1.6)
	row = 0
	for k: String in KINGDOMS:
		if cells.has("%s_player" % k):
			await _shot("%s_dead28" % k, Vector3(STEP * 7, 1.5, STEP * row), 18.0, 55.0, 0.0)
			row += 1
	print("PREVIEW done")
	quit(0)


func _wait(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(sec * 1000.0):
		await process_frame


func _shot(nm: String, focus: Vector3, zoom: float, pitch: float = 55.0, wait: float = 0.3) -> void:
	var p: float = deg_to_rad(pitch)
	cam.position = ORIGIN + focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	cam.rotation = Vector3(-p, 0.0, 0.0)
	await _wait(wait)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s_%s.png" % [OUT, tag, nm])
	img.save_png(path)
	print("PREVIEW shot ", path)
