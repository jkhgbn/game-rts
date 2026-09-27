extends SceneTree
## Task 10.V1: the Ember Bazaar model (art/buildings/market/fire/market_fire.tscn).
## Run: godot --headless --path . -s tests/test_10_v1.gd --fixed-fps 60 --quit-after 900
## Checks: the scene instantiates headless; every hook (building contract + play_delivery) exists and is safe before
## _ready (cached values applied); 0 lights in the tree; footprint 6 x 6 (below 2.45 m nothing beyond 3.3 m from the
## centre, above it nothing beyond 4.0 m); the scale beam hangs at ~6.9 m and the mast is the tallest part (8.5-10.5 m);
## draw nodes / materials within the hall budget; team colour reaches the awning, roof and banner; construction
## hides / shows parts; damage states (< 50 %: medallion + awning flap lost, torn flap shown, scale jammed; < 25 %:
## banner lost, burnt hole shown) revert when healed; play_delivery tips the scale > 12 degrees then settles;
## play_destroyed emits destroyed_finished after ~3 s and shows the wreck; a model under a turned holder (Building's
## gate yaw) keeps the gate on the right side.

const TASK_ID := "10.v1"
const PATH := "res://art/buildings/market/fire/market_fire.tscn"
const BLUE := Color(0.2, 0.45, 0.95)

var frame := 0
var _errors: PackedStringArray = PackedStringArray()
var _world: Node3D
var _m: Node3D          # idle, built
var _early: Node3D      # hooks called before _ready
var _site: Node3D       # construction
var _dead: Node3D       # destroyed
var _turned: Node3D     # under a -90 degree holder (player side)
var _destroyed_at: int = -1
var _max_tilt: float = -999.0
var _delivery_frame: int = -1


func _initialize() -> void:
	_world = Node3D.new()
	_world.name = "World"
	root.add_child(_world)
	var scene := load(PATH) as PackedScene
	if scene == null:
		_fail("scene does not load")
		return
	_m = scene.instantiate() as Node3D
	_world.add_child(_m)
	_early = scene.instantiate() as Node3D
	# Hooks before _ready must be safe and kept.
	_early.call(&"set_team_color", BLUE)
	_early.call(&"set_construction_progress", 1.0)
	_early.call(&"set_health_ratio", 0.4)
	_early.call(&"set_selected", true)
	_early.call(&"play_delivery")
	_early.call(&"play_training_pulse")
	_early.position = Vector3(12, 0, 0)
	_world.add_child(_early)
	_site = scene.instantiate() as Node3D
	_site.call(&"set_construction_progress", 0.0)
	_site.position = Vector3(-12, 0, 0)
	_world.add_child(_site)
	_dead = scene.instantiate() as Node3D
	_dead.position = Vector3(0, 0, 12)
	_world.add_child(_dead)
	_dead.connect(&"destroyed_finished", func() -> void: _destroyed_at = frame)
	var holder := Node3D.new()
	holder.position = Vector3(-45, 0, 27)
	holder.rotation.y = -PI * 0.5
	_world.add_child(holder)
	_turned = scene.instantiate() as Node3D
	holder.add_child(_turned)


func _process(_delta: float) -> bool:
	if not _errors.is_empty():
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	frame += 1
	if frame == 3:
		_check_static()
		_check_states()
		_dead.call(&"play_destroyed")
	if frame == 60:
		_check_idle_tilt()
		_m.call(&"play_delivery")
		_delivery_frame = frame
	if _delivery_frame > 0 and frame > _delivery_frame and frame < _delivery_frame + 60:
		_max_tilt = maxf(_max_tilt, float(_m.call(&"get_scale_tilt")))
	if frame == 240:
		_check_delivery()
		_check_destroyed()
		_check(_count_lights(root) == 0, "lights appeared")
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _fail(msg: String) -> void:
	_errors.append(msg)
	print("FAIL %s: %s" % [TASK_ID, msg])


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_errors.append(msg)


func _count_lights(n: Node) -> int:
	var c: int = 1 if n is Light3D else 0
	for ch: Node in n.get_children():
		c += _count_lights(ch)
	return c


## All mesh vertices of the model in its root space (skips decals, the light pool, particles and the rubble ring).
func _vertices(model: Node3D, visible_only: bool) -> PackedVector3Array:
	var out := PackedVector3Array()
	var inv: Transform3D = model.global_transform.affine_inverse()
	for n: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.name.ends_with("Decal") or mi.name == "LightPool" or mi.mesh == null:
			continue
		if visible_only and not mi.is_visible_in_tree():
			continue
		var xf: Transform3D = inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v: Vector3 in verts:
				out.append(xf * v)
	return out


func _check_static() -> void:
	_check(_count_lights(root) == 0, "expected 0 lights, found %d" % _count_lights(root))
	for meth: StringName in [&"set_team_color", &"set_construction_progress", &"set_health_ratio", &"set_selected",
			&"play_training_pulse", &"play_destroyed", &"play_delivery", &"get_scale_tilt"]:
		_check(_m.has_method(meth), "model lacks %s" % meth)
	_check(_m.has_signal(&"destroyed_finished"), "model lacks signal destroyed_finished")
	# Footprint and heights (built, idle).
	var verts := _vertices(_m, true)
	_check(verts.size() > 500, "too few vertices (%d)" % verts.size())
	var worst_low: float = 0.0
	var worst_high: float = 0.0
	var top: float = 0.0
	for v: Vector3 in verts:
		var r: float = maxf(absf(v.x), absf(v.z))
		if v.y < 2.45:
			worst_low = maxf(worst_low, r - 3.0)
		else:
			worst_high = maxf(worst_high, r - 3.0)
		top = maxf(top, v.y)
	_check(worst_low <= 0.3, "ground-level overhang %.2f m > 0.3" % worst_low)
	_check(worst_high <= 1.0, "overhang above 2.5 m %.2f m > 1.0" % worst_high)
	_check(top > 8.5 and top < 10.5, "top of the mast at %.2f m (want 8.5-10.5)" % top)
	var beam := _m.get_node_or_null(^"Body/Mast/ScalePivot/Beam") as Node3D
	_check(beam != null, "no scale beam")
	if beam:
		var y: float = beam.global_position.y - _m.global_position.y
		_check(absf(y - 6.9) < 0.4, "scale beam at %.2f m (want ~6.9)" % y)
	for p: String in ["Body/Mast/ScalePivot/PanA", "Body/Mast/ScalePivot/PanB", "Body/Mast/MastTop",
			"Body/Mast/Medallion", "Body/Mast/MastBanner", "Body/Awning", "Body/Awning/AwningFlap", "Body/Crates",
			"Body/House", "Body/Roof", "Body/Stall", "Body/Brazier", "LightPool", "ContactDecal"]:
		_check(_m.get_node_or_null(p) != null, "missing node %s" % p)
	# Budget: visible draw nodes and unique materials.
	var draws: int = 0
	var mats: Dictionary = {}
	for n: Node in _m.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		draws += 1
		if gi.material_override:
			mats[gi.material_override] = true
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				var sm: Material = mi.get_surface_override_material(s)
				if sm:
					mats[sm] = true
	_check(draws <= 32, "%d visible draw nodes (budget 32)" % draws)
	var opaque: int = 0
	for mat: Material in mats.keys():
		if mat is ShaderMaterial:
			opaque += 1
	_check(opaque <= 10, "%d shader materials (budget 10)" % opaque)
	print("10.v1 budget: %d visible draw nodes, %d shader materials, %d vertices, top %.2f m, 0 lights" % [draws,
		opaque, verts.size(), top])
	# Shared meshes between instances (BuildingMerge cache).
	var h1 := _m.get_node(^"Body/House") as MeshInstance3D
	var h2 := _site.get_node(^"Body/House") as MeshInstance3D
	_check(h1.mesh == h2.mesh, "the merged house mesh is not shared between instances")
	_check(h1.get_surface_override_material(0) != h2.get_surface_override_material(0),
		"materials must be per instance (selection rim)")
	# Early hooks kept: team colour on the roof / awning, damage state applied.
	var team_mat: ShaderMaterial = _early.get(&"mat_team")
	_check(team_mat != null and (team_mat.get_shader_parameter(&"base_color") as Color).is_equal_approx(BLUE),
		"team colour set before _ready not applied")
	var banner_mat: ShaderMaterial = _early.get(&"mat_banner")
	_check(banner_mat != null and (banner_mat.get_shader_parameter(&"cloth_color") as Color).is_equal_approx(BLUE),
		"team colour not on the banner")
	var stripe: ShaderMaterial = _early.get(&"mat_stripe")
	_check(stripe != null and (stripe.get_shader_parameter(&"base_color") as Color).is_equal_approx(
		Color(0.93, 0.83, 0.62)), "the awning's canvas stripe must stay cream for every team")
	_check(not (_early.get_node(^"Body/Mast/Medallion") as Node3D).visible, "early 40 % HP: medallion still shown")
	# The turned model (player side): gate (-Z local) faces world +X.
	var gate_dir: Vector3 = _turned.global_transform.basis * Vector3.FORWARD
	_check(gate_dir.dot(Vector3.RIGHT) > 0.99, "turned model gate faces %s" % gate_dir)


func _check_states() -> void:
	# Construction: at 0 only the outline shows; mid-way some parts rise; 1 = all.
	var outline := _site.get_node_or_null(^"BuildOutline") as Node3D
	_check(outline != null and outline.visible, "site: no glowing outline")
	var roof := _site.get_node(^"Body/Roof") as Node3D
	var plinth := _site.get_node(^"Body/PlinthBase") as Node3D
	for p: String in ["Body/Roof", "Body/Mast", "Body/House", "Body/Awning", "Body/Crates"]:
		_check(not (_site.get_node(p) as Node3D).visible, "site at 0 %%: %s visible" % p)
	_check(not (_site.get_node(^"LightPool") as Node3D).visible, "site: light pool should be off")
	_site.call(&"set_construction_progress", 0.3)
	_check(plinth.visible and not roof.visible, "site at 30 %: plinth up, roof not yet")
	_check((_site.get_node(^"Scaffold") as Node3D).visible, "site at 30 %: no scaffolding")
	_site.call(&"set_construction_progress", 1.0)
	_check(roof.visible and (_site.get_node(^"Body/Mast") as Node3D).visible, "site at 100 %: parts missing")
	_check((_site.get_node(^"LightPool") as Node3D).visible, "built: light pool should be on")
	# Damage on the idle one, then heal.
	var flap := _m.get_node(^"Body/Awning/AwningFlap") as Node3D
	var torn := _m.get_node(^"Body/Awning/AwningTorn") as Node3D
	var burn := _m.get_node(^"Body/Awning/AwningBurn") as Node3D
	var medal := _m.get_node(^"Body/Mast/Medallion") as Node3D
	var banner := _m.get_node(^"Body/Mast/MastBanner") as Node3D
	_m.call(&"set_health_ratio", 0.4)
	_check(not flap.visible and torn.visible and not medal.visible and banner.visible and not burn.visible,
		"40 %: flap/torn/medallion/banner/burn wrong")
	_m.call(&"set_health_ratio", 0.2)
	_check(not banner.visible and burn.visible, "20 %: banner should be lost, burnt hole shown")
	var smoke := _m.get_node_or_null(^"Body/Smoke1") as GPUParticles3D
	var blaze := _m.get_node_or_null(^"Body/Blaze1") as GPUParticles3D
	_check(smoke != null and smoke.emitting and blaze != null and blaze.emitting, "20 %: smoke / fire not emitting")
	_m.call(&"set_health_ratio", 1.0)
	_check(flap.visible and not torn.visible and medal.visible and banner.visible and not burn.visible
		and not smoke.emitting, "healed: damage did not revert")
	_m.call(&"set_selected", true)
	_m.call(&"set_selected", false)
	_m.call(&"set_team_color", Color(0.85, 0.30, 0.12))


func _check_idle_tilt() -> void:
	var t: float = float(_m.call(&"get_scale_tilt"))
	_check(t > 0.0 and t < 6.0, "idle tilt %.1f (want a small lean toward the gold)" % t)
	var jam: float = float(_early.call(&"get_scale_tilt"))
	_check(jam > 9.0, "the 40 %% HP scale should hang jammed (%.1f)" % jam)


func _check_delivery() -> void:
	_check(_max_tilt > 12.0, "play_delivery tipped only %.1f degrees" % _max_tilt)
	var t: float = float(_m.call(&"get_scale_tilt"))
	_check(t < 6.0, "the scale did not settle after the delivery (%.1f)" % t)


func _check_destroyed() -> void:
	# play_destroyed at frame 3, 3.0 s at 60 fps -> frame ~183.
	_check(_destroyed_at > 150 and _destroyed_at < 200, "destroyed_finished at frame %d (want ~183)" % _destroyed_at)
	var wreck := _dead.get_node_or_null(^"Wreck") as Node3D
	_check(wreck != null and wreck.visible, "wreck not shown")
	_check(wreck != null and wreck.get_node_or_null(^"WreckExtra") != null, "fallen scale / gold spill missing")
	var mast := _dead.get_node(^"Body/Mast") as Node3D
	_check(not mast.visible, "the mast should have toppled and vanished")
	_dead.call(&"play_delivery")   # ignored on a wreck, must not error
