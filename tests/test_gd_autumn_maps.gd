extends SceneTree
## G-D autumn maps (docs/art/gd_autumn_maps.md): art/environment/autumn/autumn_swap.gd ensure_for_level + restore.
## Run: $GODOT --headless --path . -s tests/test_gd_autumn_maps.gd --fixed-fps 60 --quit-after 30000
## Checks: Crown Hollow (MapCatalog.instantiate_level) is not autumn and gives the reference snapshot of every shared
## material (shader + every uniform of the original and the autumn shader); Quartermeet through the real catalog path,
## ensure_for_level called on the level's `ready` (right after main.gd `_ready`, where the hook runs; the hook itself
## when the lead has added it): guard present, nature / horizon shaders autumn, water colours, plateau + level ground
## autumn, the rig on preset_autumn (and still after set_quality 3), gd_detail follows PropsLook on the autumn shader,
## AmbientLife's mood reads autumn; freed: nothing swapped, the snapshot equals the reference (no leak), Crown Hollow
## again equal; all twice in a row. Plus Bot Lab sim mode = no swap, biome sources (layout / catalog).
## Prints "PASS gd_autumn_maps" or "FAIL gd_autumn_maps: <reasons>".

const TASK_ID := "gd_autumn_maps"
const SWAP_PATH := "res://art/environment/autumn/autumn_swap.gd"
const AUTUMN_DIR := "res://art/environment/autumn/"
const SIM := preload("res://scripts/core/sim_mode.gd")
## Shared material -> the autumn shader whose extra uniforms must be unset again after the restore ("" = none).
const SHARED: Array = [
	["res://art/environment/nature_props/nature_mat.tres", AUTUMN_DIR + "nature_autumn.gdshader"],
	["res://art/environment/horizon/horizon_mat.tres", AUTUMN_DIR + "horizon_autumn.gdshader"],
	["res://art/environment/water/water_mat.tres", ""],
	["res://art/environment/water/water_ford_mat.tres", ""],
	["res://art/environment/river_mouths/mouth_water_fallback_mat.tres", ""],
	["res://art/environment/plateau_mat.tres", ""],
	["res://art/environment/ground_material.tres", ""],
	["res://art/environment/menu_diorama/menu_ground_mat.tres", ""],
]

## The water materials also carry each map's own river data (fords, foam rocks...: written by every level, not the
## swap): right after the autumn level leaves only the shader + these colour keys are compared on them; the Crown
## Hollow reload compares everything (it writes its own data back).
const WATER_KEYS: Array = ["shader", "deep_color", "water_color", "bank_color", "sky_color", "foam_color",
	"glint_color", "film_color", "sand_color", "quality"]

var _fails: PackedStringArray = PackedStringArray()
var _sw: GDScript
var _held: Array[Resource] = []   # keeps the shared materials cached for the whole run (same instances each load)


func _initialize() -> void:
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_sw = load(SWAP_PATH)
	for row: Array in SHARED:
		if ResourceLoader.exists(row[0]):
			_held.append(load(row[0]))
	_check((_sw as Script).has_method(&"ensure_for_level"), "the hook's has_method(ensure_for_level) is false")
	# Biome sources.
	_check(bool(_sw.call(&"is_autumn", "autumn")) and not bool(_sw.call(&"is_autumn", "meadow")), "is_autumn wrong")
	var cat := MapCatalog.load_default()
	_check(String(cat.entry(&"quartermeet").get("biome", "")) == "autumn", "catalog: quartermeet not autumn")
	_check(String(cat.entry(&"ashwind_reach").get("biome", "")) == "autumn", "catalog: ashwind_reach not autumn")
	var ws_layout := LayoutLevel.load_layout("res://data/maps/ashwind_reach_layout.tres")
	_check(ws_layout != null and ws_layout.biome == "autumn", "ashwind_reach layout biome not autumn")
	var holder := Node3D.new()
	holder.set(&"name", "NotALevel")
	root.add_child(holder)
	_check(_sw.call(&"ensure_for_level", holder) == null, "ensure on a biome-less node did something")
	# Sim mode: never.
	SIM.enabled = true
	_check(_sw.call(&"ensure_for_level", holder) == null, "ensure ran in Bot Lab sim mode")
	SIM.enabled = false
	holder.queue_free()
	await process_frame

	# Reference: Crown Hollow.
	var ref := await _crown_hollow("reference")
	await _two_levels(ref)
	for pass_i in 2:
		await _autumn_pass(pass_i, ref)
		var again := await _crown_hollow("after pass %d" % pass_i)
		_diff(ref, again, "Crown Hollow after Quartermeet pass %d" % pass_i)
	if _fails.is_empty():
		print("PASS " + TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


## Loads Crown Hollow through the catalog, checks it is not autumn, snapshots the shared materials, frees it.
func _crown_hollow(tag: String) -> Dictionary:
	var lvl := MapCatalog.load_default().instantiate_level(&"crown_hollow")
	_check(lvl != null, "crown_hollow did not instantiate")
	if lvl == null:
		return {}
	var guard_box: Array = []
	lvl.ready.connect(func() -> void: guard_box.append(_sw.call(&"ensure_for_level", lvl)), CONNECT_ONE_SHOT)
	root.add_child(lvl)
	await _wait_hero(lvl)
	_check(guard_box.size() == 1 and guard_box[0] == null, "Crown Hollow (%s) got the autumn guard" % tag)
	_check(lvl.get_node_or_null(^"AutumnLook") == null, "Crown Hollow (%s) has an AutumnLook node" % tag)
	_check(not bool(_sw.call(&"is_swapped")), "materials swapped during Crown Hollow (%s)" % tag)
	var snap := _snapshot()
	await _free(lvl)
	return snap


func _autumn_pass(i: int, ref: Dictionary) -> void:
	var lvl := MapCatalog.load_default().instantiate_level(&"quartermeet")
	_check(lvl != null, "quartermeet did not instantiate")
	if lvl == null:
		return
	# The hook's moment: right after main.gd _ready (the lead's hook runs inside it; then this returns its guard).
	lvl.ready.connect(func() -> void: _sw.call(&"ensure_for_level", lvl), CONNECT_ONE_SHOT)
	root.add_child(lvl)
	_check(String(_sw.call(&"biome_of", lvl)) == "autumn", "pass %d: biome_of(quartermeet) = '%s'" % [i, _sw.call(&"biome_of", lvl)])
	await _wait_hero(lvl)
	var guard := lvl.get_node_or_null(^"AutumnLook")
	_check(guard != null, "pass %d: no AutumnLook guard" % i)
	_check(_sw.call(&"ensure_for_level", lvl) == guard, "pass %d: ensure not idempotent" % i)
	var nm := load(SHARED[0][0]) as ShaderMaterial
	_check(nm.shader.resource_path.ends_with("nature_autumn.gdshader"), "pass %d: nature_mat not autumn" % i)
	var hm := load(SHARED[1][0]) as ShaderMaterial
	_check(hm.shader.resource_path.ends_with("horizon_autumn.gdshader"), "pass %d: horizon_mat not autumn" % i)
	var wa := load(AUTUMN_DIR + "water_autumn_mat.tres") as ShaderMaterial
	var wm := load(SHARED[2][0]) as ShaderMaterial
	var wc: Variant = wa.get_shader_parameter(&"deep_color")
	_check(wc == null or wm.get_shader_parameter(&"deep_color") == wc, "pass %d: water deep_color not autumn" % i)
	var ap: GDScript = load(AUTUMN_DIR + "autumn_ground_params.gd")
	var gd_aut: Color = ap.call(&"ground_params")[&"grass_dark"]
	var pm := load(SHARED[5][0]) as ShaderMaterial
	_check(_col_eq(pm.get_shader_parameter(&"grass_dark"), gd_aut), "pass %d: plateau not autumn" % i)
	var gm := _level_ground(lvl)
	_check(gm != null and _col_eq(gm.get_shader_parameter(&"grass_dark"), gd_aut), "pass %d: level ground not autumn" % i)
	# Lighting: the autumn preset, kept by the G1 tiers.
	var rig: Node = null
	for r: Node in get_nodes_in_group(&"lighting_rigs"):
		if lvl.is_ancestor_of(r) and r.get(&"sun") is DirectionalLight3D and r.has_method(&"apply"):
			rig = r
	_check(rig != null, "pass %d: no LightingRig" % i)
	if rig:
		_check(_preset_path(rig).ends_with("preset_autumn.tres"), "pass %d: rig preset %s" % [i, _preset_path(rig)])
		rig.call(&"set_quality", 3)
		_check(_preset_path(rig).ends_with("preset_autumn.tres"), "pass %d: set_quality(3) dropped the autumn preset" % i)
		var env := (rig.get(&"world_environment") as WorldEnvironment).environment
		_check(env != null and env.fog_enabled, "pass %d: autumn env (fog) lost at Ultra" % i)
		# PropsLook's tier on the autumn nature shader.
		_check(float(nm.get_shader_parameter(&"gd_detail")) == 3.0, "pass %d: gd_detail not 3 on the autumn shader" % i)
		rig.call(&"set_quality", 0)
		_check(float(nm.get_shader_parameter(&"gd_detail")) == 0.0, "pass %d: gd_detail not back to 0" % i)
		# AmbientLife's mood from this rig.
		var al: Script = load("res://art/environment/ambient/ambient_life.gd")
		var sun := rig.get(&"sun") as DirectionalLight3D
		var mood: Dictionary = al.call(&"mood_from", sun.light_energy, sun.light_color, rig.get(&"preset_id"),
			String(_sw.call(&"biome_of", lvl)), _preset_path(rig))
		_check(bool(mood.get("autumn", false)), "pass %d: AmbientLife mood not autumn" % i)
	await _free(lvl)
	_check(not bool(_sw.call(&"is_swapped")), "pass %d: still swapped after the level left" % i)
	_diff(ref, _snapshot(), "after Quartermeet pass %d freed" % i, true)
	print("  pass %d ok-ish (%d fails so far)" % [i, _fails.size()])


## Two autumn levels alive at once (a restart) share the swap: the first one leaving must not restore, the last must.
func _two_levels(ref: Dictionary) -> void:
	var src := GDScript.new()
	src.source_code = "extends Node3D
var layout: Resource
"
	src.reload()
	var lays: Array[Node] = []
	for k in 2:
		var d := Node3D.new()
		d.set_script(src)
		var ml := MapLayout.new()
		ml.biome = "autumn"
		d.set(&"layout", ml)
		root.add_child(d)
		_check(_sw.call(&"ensure_for_level", d) != null, "dummy autumn level %d: no guard" % k)
		lays.append(d)
	_check(bool(_sw.call(&"is_swapped")), "dummy autumn levels: nothing swapped")
	lays[0].free()
	_check(bool(_sw.call(&"is_swapped")), "first of two autumn levels leaving restored too early")
	lays[1].free()
	_check(not bool(_sw.call(&"is_swapped")), "last autumn level leaving did not restore")
	_diff(ref, _snapshot(), "after two dummy autumn levels")
	await process_frame


## The level's painted ground: the ground-shader material on a plane mesh under its NavigationRegion3D.
func _level_ground(lvl: Node) -> ShaderMaterial:
	for n: Node in lvl.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if mi.mesh is PlaneMesh and sm and sm.shader and sm.shader.resource_path == "res://art/environment/ground.gdshader":
			return sm
	return null


func _wait_hero(lvl: Node) -> void:
	var n := 0
	while lvl.get(&"hero") == null and n < 6000:
		await process_frame
		n += 1
	_check(lvl.get(&"hero") != null, "%s never spawned its hero" % lvl.name)
	for k in 5:
		await process_frame


func _free(lvl: Node) -> void:
	lvl.queue_free()
	for k in 4:
		await process_frame


func _preset_path(rig: Node) -> String:
	var p: Variant = rig.get(&"preset")
	return (p as Resource).resource_path if p is Resource else ""


## Every shared material: shader path + every uniform (original and autumn shader) as text.
func _snapshot() -> Dictionary:
	var out := {}
	for row: Array in SHARED:
		if not ResourceLoader.exists(row[0]):
			continue
		var m := load(row[0]) as ShaderMaterial
		if m == null:
			continue
		var names: Dictionary = GroundParams.uniform_names(m.shader).duplicate()
		if String(row[1]) != "":
			names.merge(GroundParams.uniform_names(load(row[1]) as Shader))
		names.merge(GroundParams.uniform_names(load(AUTUMN_DIR + "water_autumn_mat.tres").shader))
		var d := {"shader": m.shader.resource_path if m.shader else ""}
		for k: String in names:
			d[k] = var_to_str(m.get_shader_parameter(StringName(k)))
		out[row[0]] = d
	return out


func _diff(a: Dictionary, b: Dictionary, what: String, water_colours_only: bool = false) -> void:
	for path: Variant in a:
		var da: Dictionary = a[path]
		var db: Dictionary = b.get(path, {})
		var water := String(path).contains("water")
		for k: Variant in da:
			if water_colours_only and water and not WATER_KEYS.has(k):
				continue
			if not db.has(k) or db[k] != da[k]:
				_check(false, "%s: %s %s = %s (was %s)" % [what, String(path).get_file(), k, db.get(k, "?"), da[k]])
				return


func _col_eq(v: Variant, c: Color) -> bool:
	return v is Color and (v as Color).is_equal_approx(c)
