extends SceneTree
## Task G-B Nature (docs/art/gb_nature_buildings.md): the Nature buildings' graphics pass keeps its contracts.
## - the shared painted layer: every Nature shader includes nature_paint.gdshaderinc and has `gfx_detail`;
##   headless runs are Low, so NatureKit materials and the Heartwood's materials get gfx_detail 0;
## - the Heartwood's tier looks: set_tier / set_upgrading / play_tier_up exist (Keep calls them), tier 1 shows no tier
##   part, tier 2 the menhirs + crown blossoms, tier 3 also the great blossoms + halo, the ground circle follows the
##   tier, the growth vines show only while upgrading, a site hides them, the tier parts stay inside the keep volume;
##   a tier-3 keep still collapses (destroyed_finished) and frees cleanly; still 2 unshadowed lights, no fireflies at Low;
## - Grove Hall / Seed Hollow / Bramble Spire / Grove Stables / Grove Bazaar instantiate and take their hooks.
## Run: godot --headless --path . -s tests/test_gb_nature.gd --fixed-fps 60 --quit-after 1500

const TASK_ID := "gb_nature"
const KEEP := "res://art/buildings/nature_keep.tscn"
const SHADERS: Array[String] = ["res://art/buildings/nature_keep/nature_keep_painted.gdshader",
	"res://art/buildings/nature/nature_vc.gdshader", "res://art/buildings/nature_keep/nature_keep_leaf.gdshader",
	"res://art/buildings/nature/nature_cards_vc.gdshader", "res://art/buildings/nature_keep/nature_keep_seed.gdshader"]
const OTHERS: Array[String] = ["res://art/buildings/nature_hall.tscn", "res://art/buildings/nature_hollow.tscn",
	"res://art/buildings/nature_spire.tscn", "res://art/buildings/stables/nature/nature_stables.tscn",
	"res://art/buildings/market/nature/market_nature.tscn"]
const TIER_NODES: Array[String] = ["Tier2Stones", "Tier2Crown", "Tier3Crown", "Tier3Halo", "GrowthVines"]

var _ok := true
var _frame := 0
var _keep: Node3D
var _others: Array[Node3D] = []
var _finished := 0


func _initialize() -> void:
	for path: String in SHADERS:
		var code: String = (load(path) as Shader).code
		if not code.contains("nature_paint.gdshaderinc"):
			_fail("%s does not include the painted layer" % path)
	var inc := FileAccess.get_file_as_string("res://art/buildings/nature/nature_paint.gdshaderinc")
	if not inc.contains("uniform int gfx_detail"):
		_fail("nature_paint.gdshaderinc lacks gfx_detail")
	var m: Dictionary = NatureKit.make_materials()
	for k: String in NatureKit.PAINTED_KEYS + NatureKit.CARD_KEYS:
		var v: Variant = (m[k] as ShaderMaterial).get_shader_parameter(&"gfx_detail")
		if v == null or int(v) != 0:
			_fail("NatureKit material %s gfx_detail %s (headless = Low = 0)" % [k, v])
	_keep = (load(KEEP) as PackedScene).instantiate() as Node3D
	for h: StringName in [&"set_tier", &"set_upgrading", &"play_tier_up"]:
		if not _keep.has_method(h):
			_fail("keep lacks %s" % h)
	_keep.call(&"set_tier", 2)   # before _ready: cached
	root.add_child(_keep)
	_keep.connect(&"destroyed_finished", func() -> void: _finished += 1)
	var x := 20.0
	for path: String in OTHERS:
		var n: Node3D = (load(path) as PackedScene).instantiate() as Node3D
		n.position = Vector3(x, 0.0, 0.0)
		x += 14.0
		root.add_child(n)
		_others.append(n)


func _process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		3: _check_tier(2)
		5:
			_keep.call(&"set_tier", 1)
			_check_tier(1)
			_keep.call(&"set_tier", 3)
			_keep.call(&"play_tier_up")
		8: _check_tier(3)
		10:
			_keep.call(&"set_upgrading", true)
			if not _vis("GrowthVines"):
				_fail("upgrading: no growth vines")
		40:
			var vines := _keep.get_node("Model/GrowthVines") as Node3D
			if vines.scale.y <= 0.0 or vines.scale.y > 1.05:
				_fail("growth vines scale %s" % vines.scale)
			_keep.call(&"set_upgrading", false)
			if _vis("GrowthVines"):
				_fail("upgrade stopped: vines still shown")
		45:
			_keep.call(&"set_construction_progress", 0.5)
			for nm: String in TIER_NODES:
				if _vis(nm):
					_fail("site: %s shown" % nm)
			_keep.call(&"set_construction_progress", 1.0)
			_check_tier(3)
			_check_contract()
		60:
			for n: Node3D in _others:
				for h: Array in [[&"set_team_color", [Color(0.9, 0.2, 0.2)]], [&"set_selected", [true]],
						[&"set_health_ratio", [0.3]], [&"set_health_ratio", [1.0]], [&"set_construction_progress", [0.4]],
						[&"set_construction_progress", [1.0]]]:
					if n.has_method(h[0]):
						n.callv(h[0], h[1])
		80:
			_keep.call(&"set_health_ratio", 0.2)
			_keep.call(&"play_destroyed")
		400:
			if _finished != 1:
				_fail("tier-3 keep: destroyed_finished %d" % _finished)
			_keep.queue_free()
			for n: Node3D in _others:
				n.queue_free()
		410:
			print("%s %s" % ["PASS" if _ok else "FAIL", TASK_ID])
			return true
	return false


func _vis(nm: String) -> bool:
	var n := _keep.get_node_or_null("Model/" + nm) as Node3D
	if n == null:
		_fail("keep lacks Model/%s" % nm)
		return false
	return n.visible


func _check_tier(t: int) -> void:
	var want: Dictionary = {"Tier2Stones": t >= 2, "Tier2Crown": t >= 2, "Tier3Crown": t >= 3, "Tier3Halo": t >= 3}
	for nm: String in want:
		if _vis(nm) != bool(want[nm]):
			_fail("tier %d: %s visible %s" % [t, nm, _vis(nm)])
	var gm: ShaderMaterial = _keep.get(&"ground_material")
	if gm and absf(float(gm.get_shader_parameter(&"tier")) - float(t)) > 0.01:
		_fail("tier %d: ground circle tier %s" % [t, gm.get_shader_parameter(&"tier")])


func _check_contract() -> void:
	var lights: Array[Node] = _keep.find_children("*", "Light3D", true, false)
	if lights.size() != 2:
		_fail("expected 2 lights, found %d" % lights.size())
	if _keep.find_child("Fireflies", true, false) != null:
		_fail("fireflies at Low")
	for path: String in ["Model/Tier2Stones", "Model/Tier2Crown", "Model/Tier3Crown", "Model/Tier3Halo", "Model/GrowthVines"]:
		var mi := _keep.get_node(path) as MeshInstance3D
		var box: AABB = mi.transform * mi.get_aabb()
		if box.position.x < -4.6 or box.end.x > 4.6 or box.position.z < -4.6 or box.end.z > 4.6 or box.end.y > 19.0:
			_fail("%s exceeds the keep volume: %s" % [path, box])
		for s: int in mi.mesh.get_surface_count():
			if mi.get_surface_override_material(s) == null:
				_fail("%s surface %d has no keep material" % [path, s])
	var pm: ShaderMaterial = _keep.get(&"leaves_material")
	if pm == null or int(pm.get_shader_parameter(&"gfx_detail")) != 0:
		_fail("keep leaves gfx_detail is not Low (0) headless")


func _fail(msg: String) -> void:
	printerr("GB NATURE FAIL: ", msg)
	_ok = false
