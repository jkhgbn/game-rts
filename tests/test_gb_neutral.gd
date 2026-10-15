extends SceneTree
## Task G-B neutral (docs/art/gb_neutral_buildings.md): the neutral / shared buildings' look layer.
## Run: godot --headless --path . -s tests/test_gb_neutral.gd --fixed-fps 60 --quit-after 900
## Checks (headless = Low tier):
##   * every neutral painted shader includes neutral_paint.gdshaderinc, has the gb_detail tier and lights through
##     np_light (one shared light pass);
##   * NeutralBuildingLook.detail() is 0 headless; add_light / add_sparks return null at Low (Low adds no lights or
##     particles), so every model builds exactly what it built before G-B;
##   * every model scene instantiates, keeps its hooks, and has no NeutralFlickerLight / spark node at Low;
##   * the shared .tres materials (watchtower, well, shrine) and the per-instance palettes get gb_detail = 0 at Low;
##   * NeutralFlickerLight: set_level(0) hides it, a level / flash scale its energy.

const TASK_ID := "gb_neutral"
const SHADERS: Array[String] = [
	"res://art/buildings/tavern/tavern_painted.gdshader",
	"res://art/buildings/trade_post/trade_post_painted.gdshader",
	"res://art/buildings/capture/watchtower/watchtower_painted.gdshader",
	"res://art/buildings/capture/essence_well/essence_well_painted.gdshader",
	"res://art/buildings/capture/wayshrine/wayshrine_stone.gdshader",
	"res://art/buildings/guilds/greywater_lodge/greywater_lodge_painted.gdshader",
	"res://art/buildings/guilds/magpie_den/magpie_den_painted.gdshader",
	"res://art/buildings/stables/stables_painted.gdshader",
]
const SCENES: Array[String] = [
	"res://art/buildings/tavern/tavern_model.tscn",
	"res://art/buildings/trade_post/trade_post.tscn",
	"res://art/buildings/capture/watchtower/watchtower.tscn",
	"res://art/buildings/capture/essence_well/essence_well.tscn",
	"res://art/buildings/capture/wayshrine/wayshrine.tscn",
	"res://art/buildings/guilds/magpie_den/magpie_den.tscn",
	"res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn",
	# Kingdom Stables that use the shared stables_painted.gdshader (Ice swaps its own shader).
	"res://art/buildings/stables/fire/fire_stables.tscn",
	"res://art/buildings/stables/shadow/shadow_stables.tscn",
	"res://art/buildings/stables/nature/nature_stables.tscn",
]
const SHARED_MATS: Array[String] = [
	"res://art/buildings/capture/watchtower/watchtower_mat.tres",
	"res://art/buildings/capture/essence_well/essence_well_painted_mat.tres",
	"res://art/buildings/capture/wayshrine/wayshrine_stone_mat.tres",
]

var frame := 0
var _models: Array[Node3D] = []
var _errors: PackedStringArray = PackedStringArray()
var _off_light: NeutralFlickerLight


func _initialize() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	for i: int in SCENES.size():
		var ps := load(SCENES[i]) as PackedScene
		if ps == null:
			_errors.append("scene does not load: %s" % SCENES[i])
			continue
		var m := ps.instantiate() as Node3D
		m.position = Vector3(i * 12.0, 0.0, 0.0)
		world.add_child(m)
		_models.append(m)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 4:
		_check_shaders()
		_check_tier()
		_check_models()
		_check_light()
	if frame == 8:
		if _off_light and _off_light.is_processing():
			_errors.append("flicker light still processing when off")
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for e: String in _errors:
				print("  " + e)
			print("FAIL %s: %d problem(s)" % [TASK_ID, _errors.size()])
		return true
	return false


func _check_shaders() -> void:
	for p: String in SHADERS:
		var f := FileAccess.open(p, FileAccess.READ)
		if f == null:
			_errors.append("missing shader %s" % p)
			continue
		var src := f.get_as_text()
		if not src.contains("#include \"res://art/buildings/tavern/neutral_paint.gdshaderinc\""):
			_errors.append("%s does not include neutral_paint" % p.get_file())
		if not src.contains("np_light(NORMAL, LIGHT, VIEW"):
			_errors.append("%s does not light through np_light" % p.get_file())
		if not src.contains("np_albedo("):
			_errors.append("%s does not call np_albedo" % p.get_file())
	var inc := FileAccess.get_file_as_string("res://art/buildings/tavern/neutral_paint.gdshaderinc")
	for token: String in ["uniform float gb_detail", "vec3 np_albedo(", "void np_light(", "vec3 np_bump("]:
		if not inc.contains(token):
			_errors.append("neutral_paint.gdshaderinc lacks %s" % token)


func _check_tier() -> void:
	if NeutralBuildingLook.detail() != 0:
		_errors.append("headless tier is %d, expected 0 (Low)" % NeutralBuildingLook.detail())
	var holder := Node3D.new()
	root.add_child(holder)
	if NeutralBuildingLook.add_light(holder, "L", Vector3.ZERO, Color.WHITE, 1.0, 4.0) != null:
		_errors.append("add_light made a light at Low")
	if NeutralBuildingLook.add_sparks(holder, "S", Vector3.ZERO) != null:
		_errors.append("add_sparks made particles at Low")
	if holder.get_child_count() != 0:
		_errors.append("Low added %d node(s)" % holder.get_child_count())
	holder.queue_free()
	for p: String in SHARED_MATS:
		var m := load(p) as ShaderMaterial
		if m == null:
			_errors.append("missing material %s" % p)
		elif float(m.get_shader_parameter(&"gb_detail")) != 0.0:
			_errors.append("%s gb_detail = %s at Low" % [p.get_file(), str(m.get_shader_parameter(&"gb_detail"))])


func _check_models() -> void:
	for m: Node3D in _models:
		var lights := m.find_children("*", "Light3D", true, false)
		if not lights.is_empty():
			_errors.append("%s has %d light(s) at Low" % [m.name, lights.size()])
		for n: Node in m.find_children("*Sparks", "GPUParticles3D", true, false):
			_errors.append("%s has spark particles at Low (%s)" % [m.name, n.name])
		for gi: Node in m.find_children("*", "GeometryInstance3D", true, false):
			var sm := (gi as GeometryInstance3D).material_override as ShaderMaterial
			if sm and sm.shader and sm.shader.code.contains("neutral_paint.gdshaderinc") \
					and float(sm.get_shader_parameter(&"gb_detail")) != 0.0:
				_errors.append("%s/%s gb_detail not 0 at Low" % [m.name, gi.name])
	# Hooks still answer (contract).
	for m: Node3D in _models:
		if m.has_method(&"set_selected"):
			m.call(&"set_selected", true)
			m.call(&"set_selected", false)
		if m.has_method(&"set_open"):
			m.call(&"set_open", false)
			m.call(&"set_open", true)
		if m.has_method(&"set_owner_color"):
			m.call(&"set_owner_color", Color(0.45, 0.75, 0.95))
			m.call(&"set_owner_color", null)


func _check_light() -> void:
	var l := NeutralFlickerLight.new()
	l.base_energy = 2.0
	l.flicker = 0.0
	root.add_child(l)
	l.set_level(0.0, true)
	if l.visible:
		_errors.append("flicker light visible at level 0")
	l.set_level(0.5, true)
	if not l.is_processing():
		_errors.append("flicker light did not wake on set_level")
	if absf(l.light_energy - 1.0) > 0.01 or not l.visible:
		_errors.append("flicker light energy %.2f at level 0.5 (want 1.0)" % l.light_energy)
	if l.shadow_enabled:
		_errors.append("flicker light casts shadows")
	l.set_level(0.0, true)
	_off_light = l   # checked a few frames later: an off light stops ticking
