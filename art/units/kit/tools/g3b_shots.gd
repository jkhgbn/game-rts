extends SceneTree
## G3b (docs/art/g3b_materials.md): before / after army shots and a GPU timing of the unit materials, on the Art Lab
## stage (game lighting rig, skirmish ground, game camera pitch 55 / fov 50). WINDOWED only (headless renders nothing):
##   tools\godot_run.ps1 --path . -s res://art/units/kit/tools/g3b_shots.gd --quit-after 20000 -- --gfx=high --tag=after
##   ... -- --gfx=high --tag=before --legacy     (the pre-G3b unit shaders swapped in at runtime, same scene)
##   ... -- --gfx=high --perf [--legacy]         (240 units in view, mean GPU ms over 120 frames; prints G3B PERF)
## Shots -> docs/art/lab/g3b_materials/shots/<tag>_<view>.png: army_z30 (the 4 Hall rosters + champions + mounts, zoom 30),
## army_z40, close_<row> (each row at zoom 9, details), and a 2 x zoom crop of the zoom-30 shot.

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/g3b_materials/shots/"
const PAINTED := "res://art/units/kit/unit_painted.gdshader"
const CHAMP := "res://art/units/champions/champion_palette.gdshader"
const BANNER := "res://art/shaders/banner.gdshader"
const LEGACY_PAINTED := "res://art/units/kit/tools/unit_painted_pre_g3b.gdshader.txt"
const LEGACY_CHAMP := "res://art/units/kit/tools/champion_palette_pre_g3b.gdshader.txt"
const ROWS: Array = [
	["fire", ["fire/flame_guard", "fire/ember_archer", "fire/blaze_rider", "fire/ash_hurler", "fire/cinder_hand"]],
	["ice", ["ice/rimeshield", "ice/shardcaster", "ice/rime_seer", "ice/rime_colossus", "ice/rime_hauler"]],
	["nature", ["nature/thornling", "nature/burr_slinger", "nature/bloomtender", "nature/bramblehorn", "nature/sprigling"]],
	["shadow", ["shadow/shade", "shadow/nightbolt", "shadow/grave_hound", "shadow/shadow_knight", "shadow/gloom_thrall"]],
	["champions", ["champions/oathwall/oathwall", "champions/wayfinder/wayfinder", "champions/coin_cutter/coin_cutter",
		"champions/mender/mender", "champions/mage_archer/mage_archer"]],
	["mounts", ["mounts/dusk_steed/dusk_steed", "mounts/roan_courser/roan_courser", "mounts/rimehorn/rimehorn",
		"mounts/grove_stag/grove_stag", "mounts/ember_boar/ember_boar"]],
]
const SPACING := 2.4
const ROW_GAP := 3.2

var stage: Node
var center := Vector3(-18.0, 0.0, 36.0)   # the lab's meadow point
var tag := "after"
var legacy := false
var perf := false
var _held: Array[Shader] = []   # keeps the swapped shaders in the resource cache (a freed one reloads from disk)


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a == "--legacy":
			legacy = true
		elif a == "--perf":
			perf = true
	if DisplayServer.get_name() == "headless":
		print("G3B SHOTS: windowed only")
		quit(2)
		return
	if legacy:
		_swap_legacy()
	_run.call_deferred()


func _swap_legacy() -> void:
	var lp := FileAccess.get_file_as_string(ProjectSettings.globalize_path(LEGACY_PAINTED))
	var lc := FileAccess.get_file_as_string(ProjectSettings.globalize_path(LEGACY_CHAMP))
	print("G3B legacy files: %d / %d chars" % [lp.length(), lc.length()])
	var sp := load(PAINTED) as Shader
	var sc := load(CHAMP) as Shader
	var b := load(BANNER) as Shader
	_held.assign([sp, sc, b])
	sp.code = lp
	sc.code = lc
	b.code = b.code.replace("uniform float unit_cloth : hint_range(0.0, 1.0) = 0.0;", "const float unit_cloth = 0.0;")
	print("G3B legacy shaders: painted %d chars (g3b layer: %s), champion %d chars" % [(load(PAINTED) as Shader).code.length(),
		(load(PAINTED) as Shader).code.contains("up_light"), (load(CHAMP) as Shader).code.length()])


func _spawn(path: String, pos: Vector3, yaw: float) -> Node3D:
	var p := "res://art/units/%s.tscn" % path
	if not ResourceLoader.exists(p):
		push_warning("g3b_shots: missing " + p)
		return null
	var m := (load(p) as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation.y = yaw
	stage.world.add_child(m)
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
	var row_z: Array[float] = []
	for r: int in ROWS.size():
		var ids: Array = ROWS[r][1]
		var z := center.z + (r - (ROWS.size() - 1) * 0.5) * ROW_GAP
		row_z.append(z)
		for i: int in ids.size():
			_spawn(ids[i], Vector3(center.x + (i - (ids.size() - 1) * 0.5) * SPACING, 0.0, z), deg_to_rad(-20.0 + 8.0 * i))
	for i: int in 30:
		await process_frame
	stage.game_cam(center, 30.0)
	var img: Image = await stage.grab()
	_save(img, "army_z30")
	var crop := img.get_region(Rect2i(400, 225, 800, 450))
	crop.resize(1600, 900, Image.INTERPOLATE_LANCZOS)
	_save(crop, "army_z30_crop2x")
	stage.game_cam(center, 40.0)
	_save(await stage.grab(), "army_z40")
	for r: int in ROWS.size():
		stage.game_cam(Vector3(center.x, 0.8, row_z[r]), 9.0, 40.0)
		_save(await stage.grab(), "close_" + String(ROWS[r][0]))
	# Portrait close-ups (zoom 4): the fine detail layer (weave, grain, brushing, bump) only shows this close.
	for r: int in ROWS.size():
		var ids: Array = ROWS[r][1]
		stage.game_cam(Vector3(center.x - (ids.size() - 1) * 0.5 * SPACING, 0.9, row_z[r]), 4.0, 30.0, 20.0)
		_save(await stage.grab(), "portrait_" + String(ROWS[r][0]))
	print("G3B SHOTS done: %s (%s)" % [OUT, tag])
	quit(0)


func _perf() -> void:
	# 240 soldiers (the 4 Hall rosters, 12 x 20 grid) filling the zoom-30 view.
	var ids: Array = []
	for r: int in 4:
		ids.append_array(ROWS[r][1])
	var k := 0
	for gx: int in 20:
		for gz: int in 12:
			_spawn(ids[k % ids.size()], center + Vector3((gx - 9.5) * 1.5, 0.0, (gz - 5.5) * 1.5), 0.0)
			k += 1
	for i: int in 60:
		await process_frame
	stage.game_cam(center, 30.0)
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
	_save(await stage.grab(), "perf_240")
	print("G3B PERF %s: %d units, gpu %.3f ms, cpu %.3f ms (mean of %d frames, 1600x900 MSAA 4x)" % [
		"legacy" if legacy else "g3b", k, gpu / n, cpu / n, n])


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("G3B SHOT ", p)
