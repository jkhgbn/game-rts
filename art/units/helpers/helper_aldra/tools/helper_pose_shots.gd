extends SceneTree
## Pose / expression contact sheet of the T3 helper models (windowed; the tool stage has its own sun, the models have 0
## lights). For each model: the 3 abilities at their key frame, the attack strike, arrival (crouched / tap / proud),
## the 5 gestures, fall, revive, and face close-ups of the 3 expressions. Writes <out>/<id>_poses.png.
## Run: tools\godot_run.ps1 --path . -s res://art/units/helpers/helper_aldra/tools/helper_pose_shots.gd --fixed-fps 60 --quit-after 20000 -- [only=aldra]

const OUT := "res://docs/art/lab/helper_poses"
const TILE := Vector2i(420, 520)
const COLS := 6
const MODELS := {
	"aldra": ["res://art/units/helpers/helper_aldra/helper_aldra.tscn", [
		["idle", "", "", 0.1], ["attack", "play_attack", "", 0.14], ["shatter", "play_cast", "aldra_shatter", 0.45],
		["aegis", "play_cast", "aldra_aegis", 0.5], ["sentinel up", "play_cast", "aldra_sentinel", 0.55],
		["sentinel slam", "play_cast", "aldra_sentinel", 0.85], ["arrival 0.2", "play_arrival", "", 0.2],
		["arrival tap", "play_arrival", "", 2.4], ["arrival proud", "play_arrival", "", 3.0], ["point", "play_gesture", "point", 0.7],
		["nod", "play_gesture", "nod", 0.25], ["kneel", "play_gesture", "kneel", 1.2], ["raise", "play_gesture", "raise_weapon", 0.8],
		["fall 0.4", "play_fall", "", 0.4], ["revive 0.4", "play_revive", "", 0.4], ["charge 1", "set_charge", "1", 0.2]]],
	"maelis": ["res://art/units/helpers/helper_maelis/helper_maelis.tscn", [
		["idle", "", "", 0.1], ["attack", "play_attack", "", 0.16], ["thornsnare", "play_cast", "thornsnare", 0.55],
		["call the pack", "play_cast", "call_the_pack", 0.7], ["stampede", "play_cast", "wild_stampede", 0.7],
		["opinions", "play_cast", "maelis_opinions", 0.4], ["arrival 0.2", "play_arrival", "", 0.2],
		["arrival plant", "play_arrival", "", 2.2], ["arrival proud", "play_arrival", "", 3.0], ["point", "play_gesture", "point", 0.7],
		["nod", "play_gesture", "nod", 0.25], ["kneel", "play_gesture", "kneel", 1.2], ["raise", "play_gesture", "raise_weapon", 0.8],
		["fall 0.4", "play_fall", "", 0.4], ["revive 0.4", "play_revive", "", 0.4], ["charge 1", "set_charge", "1", 0.2]]],
}

var vp: SubViewport
var cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_stage()
	for id: String in MODELS:
		if only != "" and id != only:
			continue
		var ps: PackedScene = load(MODELS[id][0])
		var shots: Array = MODELS[id][1]
		var tiles: Array[Image] = []
		var labels: PackedStringArray = []
		for s: Array in shots:
			var m: Node3D = ps.instantiate()
			vp.add_child(m)
			await _frames(20)
			if String(s[1]) != "":
				if String(s[1]) == "set_charge":
					m.call(&"set_charge", float(s[2]))
				elif String(s[2]) != "":
					m.call(StringName(s[1]), StringName(s[2]))
				else:
					m.call(StringName(s[1]))
			await _frames(int(float(s[3]) * 60.0))
			m.process_mode = Node.PROCESS_MODE_DISABLED
			vp.size = TILE
			cam.fov = 34.0
			_look(Vector3(0, 1.25, 0), 4.9, 12.0, -28.0)
			await _frames(3)
			tiles.append(vp.get_texture().get_image())
			labels.append(String(s[0]))
			m.queue_free()
			await _frames(2)
		for e: StringName in [&"neutral", &"smile", &"fierce"]:
			var m: Node3D = ps.instantiate()
			vp.add_child(m)
			await _frames(10)
			m.call(&"set_expression", e)
			await _frames(3)
			m.process_mode = Node.PROCESS_MODE_DISABLED
			var head := m.get_node(^"Root/Chest/Head") as Node3D
			vp.size = TILE
			cam.fov = 20.0
			_look(head.global_position + Vector3(0, 0.2, 0.05), 1.25, 6.0, -18.0)
			await _frames(3)
			tiles.append(vp.get_texture().get_image())
			labels.append("face " + String(e))
			m.queue_free()
			await _frames(2)
		var rows := int(ceil(float(tiles.size()) / float(COLS)))
		var sheet := Image.create(TILE.x * COLS, TILE.y * rows, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.1, 0.1, 0.1))
		for i: int in tiles.size():
			var t := tiles[i]
			t.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(t, Rect2i(Vector2i.ZERO, TILE), Vector2i((i % COLS) * TILE.x, (i / COLS) * TILE.y))
		sheet.save_png(ProjectSettings.globalize_path(OUT.path_join(id + "_poses.png")))
		print("POSE SHOTS ", id, ": ", ", ".join(labels))
	print("POSE SHOTS done -> ", OUT)
	quit(0)


func _look(target: Vector3, dist: float, pitch_deg: float, yaw_deg: float) -> void:
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	cam.position = target + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * dist
	cam.rotation = Vector3(-p, y, 0.0)


func _stage() -> void:
	vp = SubViewport.new()
	vp.size = TILE
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
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-52, -35, 0)
	vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.40, 0.47, 0.27)
	gm.roughness = 1.0
	ground.material_override = gm
	vp.add_child(ground)
	cam = Camera3D.new()
	cam.current = true
	vp.add_child(cam)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame
