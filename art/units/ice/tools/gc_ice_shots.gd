extends SceneTree
## G-C Ice units (docs/art/gc_ice_units.md): windowed shots of the Ice army on the Art Lab stage (game lighting rig,
## skirmish ground, game camera pitch 55 / fov 50). WINDOWED only (headless renders nothing):
##   tools\godot_run.ps1 --path . -s res://art/units/ice/tools/gc_ice_shots.gd --quit-after 30000 '--' --gfx=high
##   ... '--' --gfx=high --perf      (240 Ice units in the zoom-30 view, mean GPU / CPU ms over 120 frames: GC ICE PERF)
## Shots -> docs/art/lab/gc_ice/shots/<tag>_<view>.png (tag = gfx id, or --tag=x):
##   g3b_close_ice / g3b_portrait_ice / g3b_army_z30_crop2x: the G3b shot layout (6 rows, the Ice row 2nd) so they
##     compare 1:1 with docs/art/lab/g3b_materials/shots/after_*.png (= the Ice units before G-C);
##   army_meadow_z30 / army_meadow_z10 / army_snow_z30 / army_snow_z10: an Ice army (3 ranks: Hall units + worker,
##     Lodge / Stables / T3 units, red-team opponents for the team-colour read) on the meadow and on the snow patch.

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/gc_ice/shots/"
const G3B_ROWS: Array = [
	["fire/flame_guard", "fire/ember_archer", "fire/blaze_rider", "fire/ash_hurler", "fire/cinder_hand"],
	["ice/rimeshield", "ice/shardcaster", "ice/rime_seer", "ice/rime_colossus", "ice/rime_hauler"],
	["nature/thornling", "nature/burr_slinger", "nature/bloomtender", "nature/bramblehorn", "nature/sprigling"],
	["shadow/shade", "shadow/nightbolt", "shadow/grave_hound", "shadow/shadow_knight", "shadow/gloom_thrall"],
	["champions/oathwall/oathwall", "champions/wayfinder/wayfinder", "champions/coin_cutter/coin_cutter",
		"champions/mender/mender", "champions/mage_archer/mage_archer"],
	[],   # mounts row left empty: the mount scripts are being reworked in parallel (G-C mounts)
]
const ARMY: Array = [
	["ice/rimeshield", "ice/rimeshield", "ice/rime_colossus", "ice/rimeshield", "ice/rimeshield", "ice/shardguard/shardguard"],
	["ice/shardcaster", "ice/rime_seer", "ice/shardcaster", "ice/frostbow/frostbow", "ice/hoarlight_magebow/hoarlight_magebow",
		"ice/rimecarver/rimecarver"],
	["ice/rime_hauler", "ice/rime_hauler", "ice/rimeling/rimeling", "ice/frostrune_rifleman/frostrune_rifleman",
		"ice/rime_hauler", "ice/frostbow/frostbow"],
]
const RED := Color(0.85, 0.30, 0.12)
const SPACING := 2.4
const ROW_GAP := 3.2

var stage: Node
var center := Vector3(-18.0, 0.0, 36.0)   # the lab's meadow point (the G3b shots' centre)
var snow := Vector3(140.0, 0.0, 140.0)    # the lab's snow patch
var tag := ""
var perf := false


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a.begins_with("--gfx=") and tag == "":
			tag = a.substr(6)
		elif a == "--perf":
			perf = true
	if tag == "":
		tag = "default"
	if DisplayServer.get_name() == "headless":
		print("GC ICE SHOTS: windowed only")
		quit(2)
		return
	_run.call_deferred()


func _spawn(path: String, pos: Vector3, yaw: float, team: Variant = null) -> Node3D:
	var p := "res://art/units/%s.tscn" % path
	if not ResourceLoader.exists(p):
		push_warning("gc_ice_shots: missing " + p)
		return null
	var m := (load(p) as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation.y = yaw
	stage.world.add_child(m)
	if team != null and m.has_method(&"set_team_color"):
		m.call(&"set_team_color", team)
	return m


func _clear() -> void:
	for c: Node in stage.world.get_children():
		if c is Node3D and c.has_method(&"set_team_color"):
			c.queue_free()


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
	# 1. The G3b layout (1:1 with docs/art/lab/g3b_materials/shots/after_*): six rows, the Ice row second.
	var row_z: Array[float] = []
	for r: int in G3B_ROWS.size():
		var ids: Array = G3B_ROWS[r]
		var z := center.z + (r - (G3B_ROWS.size() - 1) * 0.5) * ROW_GAP
		row_z.append(z)
		for i: int in ids.size():
			_spawn(ids[i], Vector3(center.x + (i - (ids.size() - 1) * 0.5) * SPACING, 0.0, z), deg_to_rad(-20.0 + 8.0 * i))
	await _frames(40)
	stage.game_cam(center, 30.0)
	var img: Image = await stage.grab()
	var crop := img.get_region(Rect2i(400, 225, 800, 450))
	crop.resize(1600, 900, Image.INTERPOLATE_LANCZOS)
	_save(crop, "g3b_army_z30_crop2x")
	stage.game_cam(Vector3(center.x, 0.8, row_z[1]), 9.0, 40.0)
	_save(await stage.grab(), "g3b_close_ice")
	stage.game_cam(Vector3(center.x - 2.0 * SPACING, 0.9, row_z[1]), 4.0, 30.0, 20.0)
	_save(await stage.grab(), "g3b_portrait_ice")
	_clear()
	await _frames(4)
	# 2. An Ice army in 3 ranks facing a few red-team Ice units, on the meadow then on the snow patch.
	for spot: Array in [["meadow", center], ["snow", snow]]:
		var c: Vector3 = spot[1]
		for r: int in ARMY.size():
			var ids: Array = ARMY[r]
			for i: int in ids.size():
				var p := c + Vector3((i - (ids.size() - 1) * 0.5) * 1.9, 0.0, 1.2 - r * 2.2)
				_spawn(ids[i], p, deg_to_rad(-10.0 + 4.0 * i))
		for i: int in 4:
			var ids2: Array = ["ice/rimeshield", "ice/shardcaster", "ice/rime_colossus", "ice/rimeshield"]
			_spawn(ids2[i], c + Vector3((i - 1.5) * 2.4, 0.0, 5.6), PI + deg_to_rad(10.0 * i - 15.0), RED)
		await _frames(40)
		stage.game_cam(c + Vector3(0, 0, 0.6), 30.0)
		_save(await stage.grab(), "army_%s_z30" % spot[0])
		stage.game_cam(c + Vector3(0, 0.6, 0.4), 10.0)
		await _frames(20)   # snow motes fade in once the camera is close (tier 0)
		_save(await stage.grab(), "army_%s_z10" % spot[0])
		_clear()
		await _frames(4)
	print("GC ICE SHOTS done: %s (%s)" % [OUT, tag])
	quit(0)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _perf() -> void:
	# 240 Ice units (Hall roster + worker, 20 x 12 grid) filling the zoom-30 view.
	var ids: Array = G3B_ROWS[1]
	var k := 0
	for gx: int in 20:
		for gz: int in 12:
			_spawn(ids[k % ids.size()], center + Vector3((gx - 9.5) * 1.5, 0.0, (gz - 5.5) * 1.5), 0.0)
			k += 1
	await _frames(60)
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
	print("GC ICE PERF %s: %d units, gpu %.3f ms, cpu %.3f ms (mean of %d frames, 1600x900 MSAA 4x)" % [tag, k, gpu / n,
		cpu / n, n])


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("GC ICE SHOT ", p)
