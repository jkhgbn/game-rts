extends SceneTree
## G-D map props (docs/art/gd_props.md): the prop graphics tier stays out of Low and reaches every shared material.
## - the shaders declare `gd_detail` with default 0 (Low = the look before G-D);
## - a headless run applies tier 0 (crystal node art calls PropsLook.ensure in _ready);
## - PropsLook.apply(q) writes q into nature / crystal / crown gold materials, and the crystal art (group
##   "lighting_rigs") follows GameSettings.apply_graphics through set_quality;
## - at Low the crown pedestal adds nothing (no BeaconCore, no CrownLight, no stone override); the node contract stays.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gd_props.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "gd_props"
const SHADERS: Array[String] = [
	"res://art/environment/nature_props/nature_painted.gdshader",
	"res://art/environment/crystal/crystal_cluster.gdshader",
	"res://art/environment/crown/crown_gold.gdshader",
]
const MATS: Array[String] = [
	"res://art/environment/nature_props/nature_mat.tres",
	"res://art/environment/crystal/crystal_cluster_mat.tres",
	"res://art/environment/crown/crown_gold_mat.tres",
]

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _stone_override(stone: MeshInstance3D) -> bool:
	for i in stone.get_surface_override_material_count():
		var m := stone.get_surface_override_material(i)
		if m != null and m.resource_path.ends_with("crown_stone_mat.tres"):
			return true
	return false


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)


func _run() -> void:
	var re := RegEx.create_from_string(r"uniform\s+float\s+gd_detail\s*=\s*([0-9.]+)")
	for p in SHADERS:
		var code := (load(p) as Shader).code
		var m := re.search(code)
		_check(m != null, "%s has no gd_detail uniform" % p)
		if m:
			_check(m.get_string(1).to_float() == 0.0, "%s gd_detail default is not 0" % p)
	var pl := load("res://art/environment/nature_props/props_look.gd") as Script
	# Held for the whole test, as a level's meshes (and its LightingRig) hold them: PropsLook keeps no reference.
	var held: Array[Resource] = []
	for mp in MATS:
		held.append(load(mp))
	# Crystal node art: ensure() in _ready (headless = Low), joins the lighting rigs.
	var crystal := (load("res://art/environment/crystal_node.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(crystal)
	await process_frame
	_check(int(pl.call(&"applied")) == 0, "headless run did not apply tier 0 (applied %d)" % int(pl.call(&"applied")))
	_check(crystal.is_in_group(&"lighting_rigs"), "crystal art not in lighting_rigs")
	for mp in MATS:
		_check(float((load(mp) as ShaderMaterial).get_shader_parameter(&"gd_detail")) == 0.0, "%s not Low" % mp)
	# A Settings change (apply_graphics -> lighting_rigs.set_quality) reaches the shared materials.
	call_group(&"lighting_rigs", &"set_quality", 3)
	for mp in MATS:
		_check(float((load(mp) as ShaderMaterial).get_shader_parameter(&"gd_detail")) == 3.0, "%s missed tier 3" % mp)
	crystal.call(&"set_fill_ratio", 0.3)
	_check(is_equal_approx(float(crystal.call(&"get_fill_ratio")), 0.3), "crystal fill hook broken")
	pl.call(&"apply", 0)
	# Crown pedestal at Low: the old node set only.
	var ped := (load("res://art/environment/crown_pedestal.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(ped)
	await process_frame
	for n in ["Stone", "Runes", "SealRings", "SealChains", "Beacon", "GroundGlow", "Embers", "SealBurst"]:
		_check(ped.get_node_or_null(NodePath(n)) != null, "pedestal lost node %s" % n)
	_check(ped.get_node_or_null(^"BeaconCore") == null, "BeaconCore added at Low")
	_check(ped.get_node_or_null(^"CrownLight") == null, "CrownLight added at Low")
	var stone := ped.get_node(^"Stone") as MeshInstance3D
	for i in stone.get_surface_override_material_count():
		_check(stone.get_surface_override_material(i) == null, "stone override at Low")
	var lights := ped.find_children("*", "Light3D", true, false)
	_check(lights.is_empty(), "a light on the pedestal at Low")
	_check(ped.is_in_group(&"lighting_rigs"), "pedestal not in lighting_rigs")
	# High: the beacon core and the crown-lit stone, no light.
	ped.call(&"set_detail_tier", 2)
	_check(ped.get_node_or_null(^"BeaconCore") != null, "no BeaconCore at High")
	_check(ped.get_node_or_null(^"CrownLight") == null, "CrownLight at High")
	_check(_stone_override(stone), "no stone override at High")
	# Ultra (through the Settings broadcast): + the crown light, no shadow.
	ped.call(&"set_quality", 3)
	var cl := ped.get_node_or_null(^"CrownLight") as OmniLight3D
	_check(cl != null, "no CrownLight at Ultra")
	_check(cl == null or not cl.shadow_enabled, "CrownLight casts shadows")
	_check(ped.get_node_or_null(^"BeaconCore") != null, "no BeaconCore at Ultra")
	await process_frame
	# Back to Low: everything goes.
	ped.call(&"set_detail_tier", 0)
	await process_frame
	_check(ped.get_node_or_null(^"BeaconCore") == null and ped.get_node_or_null(^"CrownLight") == null,
			"tier pieces left after going back to Low")
	_check(not _stone_override(stone), "stone override left at Low")
	# The rig hook: PropsLook.apply returns the materials it wrote (the rig keeps them), no static strong refs.
	var got: Array = pl.call(&"apply", 2)
	_check(got.size() == MATS.size(), "apply wrote %d of %d materials" % [got.size(), MATS.size()])
	pl.call(&"apply", 0)
	crystal.queue_free()
	ped.queue_free()
	await process_frame
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)
