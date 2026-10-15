extends SceneTree
## G-E fixes B (docs/art/ge_fixes_b.md): night mission fill, Ice mission snow / lake / drifts, depth fog start.
## - EmberfallNight.night(): a moonlit night (moon under AmbientLife's night test, ambient energy < 0.5 for
##   test_g1_lighting, ambient no longer only from the black sky, ground_night 1); dawn() ground_night 0.
## - set_ground_night: flowers dimmed / greyed / fewer at night and the exact day values back at 0; mute_decor only on
##   flower kinds and only on a night level.
## - Depth fog (warm, ice, autumn): ~no fog at the RTS max zoom (top of the screen ~90 m away), aerial perspective far.
## - FrozenLook: snow ground values (lit snow albedo <= 0.7, sparkle 0 at Low), drift / lip meshes face up and fit the
##   collider, dress_level restyles ground / snowbanks / lake / caps once (idempotent).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ge_fixes_b.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "ge_fixes_b"
const ENVS := ["res://art/environment/world_env.tres", "res://art/environment/lighting/world_env_ice.tres",
		"res://art/environment/autumn/world_env_autumn.tres"]
const GROUND_MAT := "res://art/environment/ground_material.tres"
const LAKE_SHADER := "res://art/environment/snow/frozen_lake.gdshader"

var _fails: Array[String] = []
var _frame := 0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_run()
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)] if not _fails.is_empty() else "PASS %s" % TASK_ID)
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _run() -> void:
	_check_night()
	_check_ground_night()
	_check_fog()
	_check_frozen()


func _check_night() -> void:
	var n := EmberfallNight.night()
	_check(n != null, "night() null")
	if n == null:
		return
	_check(n.sun_energy < 0.85 and n.sun_color.b > n.sun_color.r, "moon fails AmbientLife's night test")
	_check(n.environment.ambient_light_energy < 0.5, "night ambient energy >= 0.5 (test_g1_lighting)")
	_check(n.environment.ambient_light_sky_contribution < 0.6, "night ambient still only from the black sky")
	_check(n.environment.tonemap_exposure >= 0.95, "night exposure darker than 0.95")
	_check(n.fill_energy >= 0.3, "night has no moon rim / fill")
	_check(is_equal_approx(n.ground_night, 1.0), "night ground_night not 1")
	var d := EmberfallNight.dawn()
	_check(d != null and is_zero_approx(d.ground_night), "dawn ground_night not 0")
	var warm := load("res://art/environment/lighting/preset_warm.tres") as LightingPreset
	_check(warm != null and is_zero_approx(warm.ground_night), "warm preset ground_night not 0")


func _level_with_ground() -> Array:
	var level := Node3D.new()
	root.add_child(level)
	var mi := MeshInstance3D.new()
	mi.mesh = PlaneMesh.new()
	var mat := (load(GROUND_MAT) as ShaderMaterial).duplicate() as ShaderMaterial
	mi.material_override = mat
	level.add_child(mi)
	return [level, mat]


func _check_ground_night() -> void:
	var lm := _level_with_ground()
	var level := lm[0] as Node3D
	var mat := lm[1] as ShaderMaterial
	var day_a: Variant = mat.get_shader_parameter(&"flower_a")
	if day_a == null:
		day_a = EmberfallNight.FLOWER_DEFAULTS[&"flower_a"]
	var day_b: Variant = mat.get_shader_parameter(&"flower_b")
	if day_b == null:
		day_b = EmberfallNight.FLOWER_DEFAULTS[&"flower_b"]
	var amt0: Variant = mat.get_shader_parameter(&"flower_amount")
	var day_amt := float(amt0) if amt0 != null else 1.0
	var flowers := MultiMeshInstance3D.new()
	flowers.name = "GladeFlowers_3_4"
	level.add_child(flowers)
	var grass := MultiMeshInstance3D.new()
	grass.name = "GladeTallGrass_3_4"
	level.add_child(grass)
	EmberfallNight.set_ground_night(level, 1.0)
	var na: Variant = mat.get_shader_parameter(&"flower_a")
	var nb: Variant = mat.get_shader_parameter(&"flower_b")
	_check(float(mat.get_shader_parameter(&"flower_amount")) < day_amt * 0.5, "night flower_amount not reduced")
	_check(_lum(na) < _lum(day_a) * 0.8, "night flower_a (white) not dimmed")
	_check(_sat(nb) < _sat(day_b) * 0.6 and _lum(nb) < _lum(day_b) * 0.8, "night flower_b (yellow) not greyed / dimmed")
	_check(float(flowers.get_instance_shader_parameter(&"night_mute")) > 0.5, "flower decor not muted at night")
	var gm: Variant = grass.get_instance_shader_parameter(&"night_mute")
	_check(gm == null or is_zero_approx(float(gm)), "grass decor muted (only flower kinds should be)")
	var late := MultiMeshInstance3D.new()
	late.name = "MeadowDaisies_0_0"
	EmberfallNight.mute_decor(late, level)
	_check(float(late.get_instance_shader_parameter(&"night_mute")) > 0.5, "decor built after the night not muted")
	late.free()
	EmberfallNight.set_ground_night(level, 0.0)
	_check(_rgb(mat.get_shader_parameter(&"flower_a")).is_equal_approx(_rgb(day_a)), "day flower_a not restored")
	_check(is_equal_approx(float(mat.get_shader_parameter(&"flower_amount")), day_amt), "day flower_amount not restored")
	_check(is_zero_approx(float(flowers.get_instance_shader_parameter(&"night_mute"))), "flower decor not unmuted")
	level.free()


static func _rgb(v: Variant) -> Vector3:
	if v is Color:
		return Vector3((v as Color).r, (v as Color).g, (v as Color).b)
	return v as Vector3 if v is Vector3 else Vector3.ZERO


static func _sat(v: Variant) -> float:
	var c := _rgb(v)
	var mx := maxf(c.x, maxf(c.y, c.z))
	return 0.0 if mx <= 0.0 else (mx - minf(c.x, minf(c.y, c.z))) / mx


static func _lum(v: Variant) -> float:
	var c := _rgb(v)
	return c.x * 0.3 + c.y * 0.59 + c.z * 0.11


## Godot's depth fog amount at `dist` metres (density x curve of the begin..end smoothstep).
static func _fog_at(env: Environment, dist: float) -> float:
	var t := smoothstep(env.fog_depth_begin, env.fog_depth_end, dist)
	return env.fog_density * pow(t, env.fog_depth_curve)


func _check_fog() -> void:
	for p: String in ENVS:
		var env := load(p) as Environment
		_check(env != null, "%s missing" % p)
		if env == null:
			continue
		# RTS camera at max zoom 55 (pitch 55, fov 50): the top of the screen is ~90 m away.
		_check(_fog_at(env, 90.0) < 0.01, "%s: fog %.3f at 90 m (max zoom top edge)" % [p.get_file(), _fog_at(env, 90.0)])
		_check(_fog_at(env, 65.0) == 0.0, "%s: fog starts before 65 m" % p.get_file())
		_check(_fog_at(env, 220.0) > 0.05, "%s: no aerial perspective left at 220 m" % p.get_file())


func _check_frozen() -> void:
	# Ground values.
	var lm := _level_with_ground()
	var level := lm[0] as Node3D
	var mat := lm[1] as ShaderMaterial
	FrozenLook.apply_ground(mat, 0)
	_check(float(mat.get_shader_parameter(&"snow_mode")) > 0.5, "snow_mode not set")
	_check(is_zero_approx(float(mat.get_shader_parameter(&"snow_sparkle"))), "sparkle on at Low")
	var gl := _rgb(mat.get_shader_parameter(&"grass_light"))
	_check(maxf(gl.x, maxf(gl.y, gl.z)) <= 0.7, "lit snow albedo above 0.7 (glare)")
	FrozenLook.apply_ground(mat, 2)
	_check(float(mat.get_shader_parameter(&"snow_sparkle")) > 0.0, "no sparkle at High")
	var ground_default := load(GROUND_MAT) as ShaderMaterial
	var sm: Variant = ground_default.get_shader_parameter(&"snow_mode")
	_check(sm == null or is_zero_approx(float(sm)), "shared ground material has snow_mode on")
	# Meshes: top faces up, size fits the 5 x 1.8 x 2.5 collider ring.
	for ds: int in [3, 17, 250]:
		var dm := FrozenLook.drift_mesh(ds, 6.5, 3.2, 1.8)
		_check(_up_ratio(dm) > 0.6, "drift %d faces down (winding)" % ds)
		var ab := dm.get_aabb()
		_check(ab.size.y <= 2.3 and ab.size.x >= 5.0 and ab.position.y >= -0.3, "drift %d size %s" % [ds, ab])
	var lip := FrozenLook.shore_lip(22.0)
	_check(_up_ratio(lip) > 0.6, "shore lip faces down")
	_check(lip.get_aabb().size.y < 0.5, "shore lip too tall")
	# dress_level on a stand-in of mission 2's nodes.
	var bank := StaticBody3D.new()
	bank.name = "Snowbank40"
	bank.add_to_group(&"snowbanks")
	level.add_child(bank)
	bank.position = Vector3(10.0, 0.9, 0.0)
	var bmi := MeshInstance3D.new()
	bmi.mesh = SphereMesh.new()
	bank.add_child(bmi)
	var lake := Node3D.new()
	lake.add_to_group(&"glasswater_lake")
	level.add_child(lake)
	var disc := MeshInstance3D.new()
	disc.name = "IceDisc"
	disc.mesh = CylinderMesh.new()
	lake.add_child(disc)
	var cap := MeshInstance3D.new()
	cap.mesh = SphereMesh.new()
	var cm := StandardMaterial3D.new()
	cm.albedo_color = FrozenLook.OLD_BANK_WHITE
	cap.material_override = cm
	level.add_child(cap)
	var fresh := (load(GROUND_MAT) as ShaderMaterial).duplicate() as ShaderMaterial
	(level.get_child(0) as MeshInstance3D).material_override = fresh
	_check(FrozenLook.dress_level(level), "dress_level found no ground")
	_check(float(fresh.get_shader_parameter(&"snow_mode")) > 0.5, "dress_level: ground not snow")
	_check(bmi.mesh is ArrayMesh and is_equal_approx(bmi.position.y, -0.9), "dress_level: snowbank not a grounded drift")
	var dmat := disc.material_override as ShaderMaterial
	_check(dmat != null and dmat.shader.resource_path == LAKE_SHADER, "dress_level: lake ice not applied")
	_check(lake.get_node_or_null(^"ShoreLip") != null, "dress_level: no shore lip")
	_check(cap.material_override is ShaderMaterial, "dress_level: rock cap not restyled")
	FrozenLook.dress_level(level)
	var lips := 0
	for c: Node in lake.get_children():
		if String(c.name).begins_with("ShoreLip"):
			lips += 1
	_check(lips == 1, "dress_level not idempotent (%d lips)" % lips)
	level.free()


## Share of the mesh's area whose face normal points up (generate_normals follows the winding).
static func _up_ratio(m: ArrayMesh) -> float:
	var arr := m.surface_get_arrays(0)
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	if nrm.is_empty():
		return 0.0
	var up := 0
	for n: Vector3 in nrm:
		if n.y > 0.0:
			up += 1
	return float(up) / float(nrm.size())
