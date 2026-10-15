extends SceneTree
## G-D creatures (docs/art/gd_creatures.md): before / after shots of the neutral creatures, epic beasts, hired
## neutrals and game critters on the Art Lab stage (game lighting rig, skirmish ground, game camera pitch).
## WINDOWED only:
##   tools\godot_run.ps1 --path . -s res://art/units/neutral/tools/gd_creature_shots.gd --quit-after 30000 '--' --gfx=high --tag=after
## Shots -> docs/art/lab/gd_creatures/shots/<tag>_<view>.png: camps_z35 / camps_z10 (camp creatures + hired neutrals
## + critters), beasts_z35 / beasts_z10a / beasts_z10b (the 8 beasts = 4 models x 2 variants), wyrm_z35,
## portrait_<id> (zoom ~5) for each camp creature and beast.
##   ... '--' --gfx=high --perf   (60 camp creatures + 8 beasts at zoom 30, mean GPU / CPU ms; GD PERF line)

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/gd_creatures/shots/"
const N := "res://art/units/neutral/"
const CAMP: Array = [
	["bristleback/bristleback.tscn", 0], ["bristleback/bristleback.tscn", 0], ["mirefang/mirefang.tscn", 0],
	["mirefang/mirefang.tscn", 0], ["gloomcap/gloomcap_sprout.tscn", 0], ["gloomcap/gloomcap_elder.tscn", 0],
	["gloomcap/gloomcap_sprout.tscn", 0], ["hollow_stag/hollow_stag.tscn", 0], ["stormbottle_genie/stormbottle_genie.tscn", 0],
	["magpie/magpie.tscn", 0], ["tracker/tracker.tscn", 0], ["critters/deer.tscn", 0], ["critters/rabbit.tscn", 0],
]
const BEASTS: Array = [
	["beasts/tusker/tusker.tscn", 0], ["beasts/tusker/tusker.tscn", 1], ["beasts/roc/roc.tscn", 0],
	["beasts/roc/roc.tscn", 1], ["beasts/direwolf/direwolf.tscn", 0], ["beasts/direwolf/direwolf.tscn", 1],
	["beasts/grizzlemaw/grizzlemaw.tscn", 0], ["beasts/grizzlemaw/grizzlemaw.tscn", 1],
]
const TEAM := Color(0.78, 0.16, 0.12)

var stage: Node
var center := Vector3(-18.0, 0.0, 36.0)   # the lab's meadow point
var tag := "after"
var perf := false
var models: Array[Node3D] = []


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a == "--perf":
			perf = true
	if DisplayServer.get_name() == "headless":
		print("GD SHOTS: windowed only")
		quit(2)
		return
	_run.call_deferred()


func _spawn(rel: String, variant: int, pos: Vector3, yaw: float) -> Node3D:
	var m := (load(N + rel) as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation.y = yaw
	stage.world.add_child(m)
	if m.has_method(&"set_variant"):
		m.call(&"set_variant", variant)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", TEAM)
	models.append(m)
	return m


func _run() -> void:
	stage = STAGE.new()
	root.add_child(stage)
	stage.setup(&"warm")
	stage.vp.msaa_3d = Viewport.MSAA_4X
	await stage.warm()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if perf:
		await _perf()
		quit(0)
		return
	# Camp row (z = 0) in two lines, beasts (z = +14) 5.5 m apart, the wyrm far off.
	var camp_at: Array[Vector3] = []
	for i: int in CAMP.size():
		var row: int = i / 7
		var p := center + Vector3((i % 7 - 3.0) * 2.6 + row * 1.3, 0.0, -row * 3.2)
		camp_at.append(p)
		var m := _spawn(CAMP[i][0], CAMP[i][1], p, deg_to_rad(-25.0 + 11.0 * i))
		if i % 4 == 1 and m.has_method(&"set_moving"):
			m.call(&"set_moving", float(m.get(&"stride_speed")) if m.get(&"stride_speed") != null else 2.0)
	var beast_at: Array[Vector3] = []
	for i: int in BEASTS.size():
		var p := center + Vector3((i - 3.5) * 5.6, 0.0, 14.0)
		beast_at.append(p)
		_spawn(BEASTS[i][0], BEASTS[i][1], p, deg_to_rad(-30.0 + 8.0 * i))
	var wyrm_at := center + Vector3(0.0, 0.0, 44.0)
	_spawn("beasts/frost_wyrm/frost_wyrm.tscn", 0, wyrm_at, deg_to_rad(70.0))
	for i: int in 60:
		await process_frame
	stage.game_cam(center + Vector3(0, 0, -1.2), 35.0)
	_save(await stage.grab(), "camps_z35")
	stage.game_cam(center + Vector3(-4.0, 0.4, -1.0), 10.0)
	await _settle(2.5)
	_save(await stage.grab(), "camps_z10")
	stage.game_cam(center + Vector3(5.0, 0.4, -2.0), 10.0)
	await _settle(2.5)
	_save(await stage.grab(), "camps_z10b")
	stage.game_cam(center + Vector3(0, 0, 14.0), 35.0)
	_save(await stage.grab(), "beasts_z35")
	stage.game_cam(center + Vector3(-11.0, 1.0, 14.0), 11.0)
	await _settle(2.5)
	_save(await stage.grab(), "beasts_z10a")
	stage.game_cam(center + Vector3(11.0, 1.0, 14.0), 11.0)
	await _settle(2.5)
	_save(await stage.grab(), "beasts_z10b")
	stage.game_cam(wyrm_at, 35.0)
	_save(await stage.grab(), "wyrm_z35")
	for i: int in CAMP.size():
		var id := String(CAMP[i][0]).get_file().get_basename()
		if i in [1, 3, 6]:
			continue
		stage.game_cam(camp_at[i] + Vector3(0, 0.8, 0), 4.6, 26.0, 0.0)
		await _settle(1.6)
		_save(await stage.grab(), "portrait_%s" % id)
	for i: int in BEASTS.size():
		var id := "%s_%s" % [String(BEASTS[i][0]).get_file().get_basename(), "ab"[BEASTS[i][1]]]
		stage.game_cam(beast_at[i] + Vector3(0, 1.4, 0), 8.5, 26.0, 0.0)
		await _settle(1.6)
		_save(await stage.grab(), "portrait_%s" % id)
	print("GD SHOTS done: %s (%s)" % [OUT, tag])
	quit(0)


func _perf() -> void:
	var k := 0
	for gx: int in 10:
		for gz: int in 6:
			var e: Array = CAMP[k % 8]
			_spawn(e[0], 0, center + Vector3((gx - 4.5) * 2.4, 0.0, (gz - 2.5) * 2.4), 0.3 * k)
			k += 1
	for i: int in BEASTS.size():
		_spawn(BEASTS[i][0], BEASTS[i][1], center + Vector3((i - 3.5) * 5.0, 0.0, 10.0), 0.0)
		k += 1
	for i: int in 60:
		await process_frame
	stage.game_cam(center + Vector3(0, 0, 3.0), 30.0)
	var gpu := 0.0
	var cpu := 0.0
	var n := 0
	for i: int in 150:
		await RenderingServer.frame_post_draw
		if i >= 30:
			var ms: Vector2 = stage.render_ms()
			cpu += ms.x
			gpu += ms.y
			n += 1
	_save(await stage.grab(), "perf")
	print("GD PERF %s: %d models, gpu %.3f ms, cpu %.3f ms (mean of %d frames, MSAA 4x)" % [tag, k, gpu / n, cpu / n, n])


## Lets near-camera models leave their frozen tier and the High+ signature emitters fill up before a grab.
func _settle(sec: float) -> void:
	await create_timer(sec).timeout


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("GD SHOT ", p)
