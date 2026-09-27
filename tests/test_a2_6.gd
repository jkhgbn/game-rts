extends SceneTree
## Task A2.6 (Nature hall / hollow / spire epic pass): the Grove Hall, Seed Hollow and Bramble Spire models
## - instantiate headless (hooks before _ready are cached; a recoloured copy keeps its own materials);
## - keep their contract: class names, hooks, `destroyed_finished`, node names (Body, ContactDecal, Scaffold, Wreck,
##   spire Orb / AuraRing), BuildingType data still pointing at them;
## - take every hook: construction 0 -> 1 (outline, scaffold, parts hidden at 0), HP 40 / 20 / 100 % (the damage looks
##   show and revert), selection, team colour, training pulse / shot (the spire's bud flares), destroy ->
##   destroyed_finished with the wreck shown, a copy freed mid-collapse;
## - stay in budget like the Ice buildings: no active light, few merged mesh nodes / surfaces, vertices, idle
##   particles, footprint and height.
## Run:  godot --headless --path . -s tests/test_a2_6.gd --fixed-fps 60 --quit-after 900

const TASK_ID := "A2.6"
const MODELS: Array[String] = ["res://art/buildings/nature_hall.tscn", "res://art/buildings/nature_hollow.tscn",
	"res://art/buildings/nature_spire.tscn"]
const CLASSES: Array[StringName] = [&"NatureHallModel", &"NatureHollowModel", &"NatureSpireModel"]
const DATA: Array[String] = ["res://data/buildings/nature_barracks.tres", "res://data/buildings/nature_hollow.tres",
	"res://data/buildings/nature_tower.tres"]
const HOOKS: Array[StringName] = [&"set_team_color", &"set_construction_progress", &"set_health_ratio",
	&"set_selected", &"play_destroyed"]
## Budgets per model (visible when built and idle): mesh nodes, surfaces (~draw calls), vertices, idle particles.
const MAX_MESHES: Array[int] = [16, 10, 10]
const MAX_SURFACES: Array[int] = [36, 24, 18]
const MAX_VERTS: Array[int] = [40000, 16000, 12000]
const MAX_PARTICLES: Array[int] = [40, 24, 20]
## Half footprint + allowed overhang below 2.5 m (roots may crawl a little past the plinth), max height.
const MAX_REACH: Array[float] = [3.95, 2.75, 1.75]
const MAX_HEIGHT: Array[float] = [12.0, 7.0, 8.0]
const NODES: Array = [["Body", "ContactDecal", "Scaffold", "Wreck", "Body/Hedge", "Body/HedgeLost", "Body/Tree",
		"Body/BannersGate", "Body/BannersSide"],
	["Body", "ContactDecal", "Scaffold", "Wreck", "Body/LeafRoof", "Body/LeafRoofLost", "Body/Banner"],
	["Body", "ContactDecal", "Scaffold", "Wreck", "Body/Orb", "AuraRing", "Body/Crown", "Body/CrownLost"]]
## (node that hides below 50 %, node that hides below 25 %) per model.
const LOST: Array = [["Body/HedgeLost", "Body/BannersSide"], ["Body/LeafRoofLost", ""], ["Body/CrownLost", ""]]

var _models: Array[Node3D] = []
var _red: Array[Node3D] = []
var _finished: int = 0
var _frame: int = 0
var _errors: Array[String] = []
var _early: Node3D


func _initialize() -> void:
	for i: int in MODELS.size():
		var ps := load(MODELS[i]) as PackedScene
		if ps == null:
			_errors.append("cannot load " + MODELS[i])
			continue
		var m := ps.instantiate() as Node3D
		var scr := m.get_script() as Script
		if scr == null or scr.get_global_name() != CLASSES[i]:
			_errors.append("%s: script class is not %s" % [MODELS[i], CLASSES[i]])
		for h: StringName in HOOKS:
			if not m.has_method(h):
				_errors.append("%s lacks hook %s" % [MODELS[i], h])
		if not m.has_signal(&"destroyed_finished"):
			_errors.append("%s lacks signal destroyed_finished" % MODELS[i])
		if i == 0 and not m.has_method(&"play_training_pulse"):
			_errors.append("hall lacks play_training_pulse")
		if i == 2 and not m.has_method(&"play_shot"):
			_errors.append("spire lacks play_shot")
		m.call(&"set_construction_progress", 0.0)   # before _ready: cached
		m.position = Vector3(i * 12.0, 0, 0)
		root.add_child(m)
		m.connect(&"destroyed_finished", func() -> void: _finished += 1)
		_models.append(m)
		var r := ps.instantiate() as Node3D
		r.call(&"set_team_color", Color(0.9, 0.2, 0.2))
		r.position = Vector3(i * 12.0, 0, 20)
		root.add_child(r)
		_red.append(r)
		var bt: Resource = load(DATA[i])
		if bt == null or bt.get(&"model_scene") == null or (bt.get(&"model_scene") as PackedScene).resource_path != MODELS[i]:
			_errors.append("%s does not point at %s" % [DATA[i], MODELS[i]])


func _process(_delta: float) -> bool:
	_frame += 1
	if _models.size() != MODELS.size():
		print("FAIL %s: %s" % [TASK_ID, _errors[0] if _errors.size() > 0 else "models missing"])
		return true
	var p: float = clampf((_frame - 2) / 60.0, 0.0, 1.0)
	if _frame == 1:
		for i: int in _models.size():
			for n: String in NODES[i]:
				if _models[i].get_node_or_null(n) == null:
					_errors.append("%s lacks node %s" % [_name(i), n])
		_check_bake()
	if _frame == 2:
		_check_site()
	if _frame >= 2 and _frame <= 63:
		for m: Node3D in _models:
			m.call(&"set_construction_progress", p)
	if _frame == 30:
		for i: int in _models.size():
			var s := _models[i].get_node_or_null(^"Scaffold") as Node3D
			if s == null or not s.visible:
				_errors.append("%s: no scaffold while half built" % _name(i))
	if _frame == 70:
		_check_built()
		_check_materials()
		for m: Node3D in _models:
			m.call(&"set_selected", true)
			if m.has_method(&"play_training_pulse"):
				m.call(&"play_training_pulse")
	if _frame == 98:   # the floaters finished scaling in (0.5 s after completion)
		_models[2].call(&"play_shot")
	if _frame == 100:
		var bud := _models[2].get_node(^"Body/Orb") as MeshInstance3D
		if bud.scale.x < 1.1:
			_errors.append("spire: the bud does not flare on a shot (scale %.2f)" % bud.scale.x)
	if _frame == 80:
		for m: Node3D in _models:
			m.call(&"set_health_ratio", 0.4)
	if _frame == 84:
		_check_health(0.4)
	if _frame == 90:
		for m: Node3D in _models:
			m.call(&"set_health_ratio", 0.2)
	if _frame == 94:
		_check_health(0.2)
	if _frame == 102:
		for m: Node3D in _models:
			m.call(&"set_health_ratio", 1.0)
			m.call(&"set_selected", false)
	if _frame == 106:
		_check_health(1.0)
	if _frame == 110:
		_early = (load(MODELS[0]) as PackedScene).instantiate() as Node3D
		_early.position = Vector3(0, 0, -20)
		root.add_child(_early)
	if _frame == 114:
		_early.call(&"play_destroyed")
	if _frame == 150:
		_early.queue_free()   # freed mid-collapse: must not error
	if _frame == 130:
		for m: Node3D in _models:
			m.call(&"play_destroyed")
	if _frame == 130 + 60 * 4:
		if _finished != _models.size():
			_errors.append("destroyed_finished %d / %d" % [_finished, _models.size()])
		for i: int in _models.size():
			var w := _models[i].get_node_or_null(^"Wreck") as Node3D
			if w == null or not w.visible:
				_errors.append("%s wreck hidden after the collapse" % _name(i))
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for e: String in _errors:
				print("  ", e)
			print("FAIL %s: %s" % [TASK_ID, _errors[0]])
		return true
	return false


func _name(i: int) -> String:
	return MODELS[i].get_file().get_basename()


## Every mesh is baked (art/buildings/nature/nature_bake.gd) and the bake matches what the code builds today.
func _check_bake() -> void:
	var keys: Array = NatureKit.cached_keys()
	if keys.size() < 20:
		_errors.append("only %d Nature meshes in use" % keys.size())
	for key: String in keys:
		if not ResourceLoader.exists(NatureKit.baked_path(key)):
			_errors.append("mesh %s is not baked: run art/buildings/nature/nature_bake.gd (windowed)" % key)
			continue
		var baked: ArrayMesh = NatureKit.cached_mesh(key)
		var build: Callable = NatureKit.builder_of(key)
		if not build.is_valid():
			_errors.append("mesh %s has no builder" % key)
			continue
		var fresh: ArrayMesh = NatureKit.build_fresh(build)[0]
		var same: bool = baked.get_surface_count() == fresh.get_surface_count()
		if same:
			for s: int in fresh.get_surface_count():
				var a: int = (baked.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				var b: int = (fresh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				if a != b or baked.surface_get_name(s) != fresh.surface_get_name(s):
					same = false
		if not same:
			_errors.append("baked mesh %s is stale: re-run art/buildings/nature/nature_bake.gd (windowed)" % key)


## Progress 0: the glowing outline shows, every part of Body is hidden, no idle particles.
func _check_site() -> void:
	for i: int in _models.size():
		var m: Node3D = _models[i]
		var outline := m.get_node_or_null(^"BuildOutline") as Node3D
		if outline == null or not outline.visible:
			_errors.append("%s: no construction outline at 0 %%" % _name(i))
		var c: Array[int] = _count(m.get_node(^"Body"))
		if c[0] > 0:
			_errors.append("%s: %d body meshes visible at 0 %% (want 0)" % [_name(i), c[0]])


func _check_built() -> void:
	for i: int in _models.size():
		var m: Node3D = _models[i]
		var c: Array[int] = _count(m)
		print("  %s: meshes %d, surfaces %d, lights %d, particles %d, verts %d" % [_name(i), c[0], c[1], c[2], c[3], c[4]])
		if c[0] > MAX_MESHES[i]:
			_errors.append("%s has %d visible mesh nodes (max %d)" % [_name(i), c[0], MAX_MESHES[i]])
		if c[1] > MAX_SURFACES[i]:
			_errors.append("%s has %d visible surfaces (max %d)" % [_name(i), c[1], MAX_SURFACES[i]])
		if c[2] > 0:
			_errors.append("%s has %d visible lights (want 0)" % [_name(i), c[2]])
		if c[3] > MAX_PARTICLES[i]:
			_errors.append("%s idle particles %d (max %d)" % [_name(i), c[3], MAX_PARTICLES[i]])
		if c[4] > MAX_VERTS[i]:
			_errors.append("%s has %d vertices (max %d)" % [_name(i), c[4], MAX_VERTS[i]])
		var s := m.get_node_or_null(^"Scaffold") as Node3D
		if s and s.visible:
			_errors.append("%s scaffold still visible when built" % _name(i))
		# Footprint and height of the body (model space).
		var body := m.get_node(^"Body") as Node3D
		var reach: float = 0.0
		var top: float = 0.0
		for mi: MeshInstance3D in _meshes(body):
			var xf: Transform3D = m.global_transform.affine_inverse() * mi.global_transform
			var box: AABB = xf * mi.get_aabb()
			top = maxf(top, box.end.y)
			var verts: PackedVector3Array = PackedVector3Array()
			for sidx: int in mi.mesh.get_surface_count():
				verts.append_array(mi.mesh.surface_get_arrays(sidx)[Mesh.ARRAY_VERTEX])
			for v: Vector3 in verts:
				var w: Vector3 = xf * v
				if w.y < 2.5:
					reach = maxf(reach, maxf(absf(w.x), absf(w.z)))
		if reach > MAX_REACH[i]:
			_errors.append("%s reaches %.2f m from the centre below 2.5 m (max %.2f)" % [_name(i), reach, MAX_REACH[i]])
		if top > MAX_HEIGHT[i] or top < MAX_HEIGHT[i] * 0.45:
			_errors.append("%s is %.2f m tall (want %.1f .. %.1f)" % [_name(i), top, MAX_HEIGHT[i] * 0.45, MAX_HEIGHT[i]])


## The red copy (recoloured before _ready) and the default one never share a material.
func _check_materials() -> void:
	for i: int in _models.size():
		var a: Array[Material] = _materials(_models[i])
		var b: Array[Material] = _materials(_red[i])
		for m: Material in a:
			if m in b and m is ShaderMaterial:
				_errors.append("%s shares material %s between instances" % [_name(i), m.resource_name])
				break
		var leaves_a: Variant = _find_param(a, &"LeafCard")
		var leaves_b: Variant = _find_param(b, &"LeafCard")
		if leaves_a == null or leaves_b == null:
			_errors.append("%s: no LeafCard material" % _name(i))
		elif not (leaves_b as Color).is_equal_approx(Color(0.9, 0.2, 0.2)) or (leaves_a as Color).is_equal_approx(leaves_b):
			_errors.append("%s: team colour not applied per instance (%s / %s)" % [_name(i), leaves_a, leaves_b])


func _find_param(mats: Array[Material], nm: StringName) -> Variant:
	for m: Material in mats:
		if m is ShaderMaterial and m.resource_name == String(nm):
			return (m as ShaderMaterial).get_shader_parameter(&"base_color")
	return null


func _materials(n: Node) -> Array[Material]:
	var out: Array[Material] = []
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override:
			out.append(mi.material_override)
		for s: int in mi.get_surface_override_material_count():
			var m: Material = mi.get_surface_override_material(s)
			if m and not out.has(m):
				out.append(m)
	for c: Node in n.get_children():
		for m: Material in _materials(c):
			if not out.has(m):
				out.append(m)
	return out


func _check_health(r: float) -> void:
	for i: int in _models.size():
		var m: Node3D = _models[i]
		var lost50 := m.get_node_or_null(NodePath(LOST[i][0])) as Node3D
		var hurt: bool = r < 0.5
		if lost50 and lost50.visible == hurt:
			_errors.append("%s at %d %% HP: %s visible=%s" % [_name(i), int(r * 100), LOST[i][0], lost50.visible])
		if LOST[i][1] != "":
			var lost25 := m.get_node_or_null(NodePath(LOST[i][1])) as Node3D
			if lost25 and lost25.visible == (r < 0.25):
				_errors.append("%s at %d %% HP: %s visible=%s" % [_name(i), int(r * 100), LOST[i][1], lost25.visible])
		var smoke := m.find_child("Smoke1", true, false) as GPUParticles3D
		if smoke == null or smoke.emitting != hurt:
			_errors.append("%s at %d %% HP: smoke emitting=%s" % [_name(i), int(r * 100), smoke.emitting if smoke else "missing"])


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D and (n as MeshInstance3D).visible and (n as MeshInstance3D).mesh:
		out.append(n)
	for c: Node in n.get_children():
		if c is Node3D and not (c as Node3D).visible:
			continue
		out.append_array(_meshes(c))
	return out


## [visible mesh nodes, surfaces, visible lights, emitting particles, vertices], recursive through visible nodes.
func _count(n: Node) -> Array[int]:
	var c: Array[int] = [0, 0, 0, 0, 0]
	if n is MeshInstance3D and (n as MeshInstance3D).visible and (n as MeshInstance3D).mesh:
		var mesh: Mesh = (n as MeshInstance3D).mesh
		c[0] += 1
		c[1] += mesh.get_surface_count()
		for s: int in mesh.get_surface_count():
			c[4] += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).visible:
		var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
		if mm and mm.instance_count > 0 and mm.visible_instance_count != 0:
			c[0] += 1
			c[1] += 1
	elif n is Light3D and (n as Light3D).visible:
		c[2] += 1
	elif n is GPUParticles3D and (n as GPUParticles3D).emitting and not (n as GPUParticles3D).one_shot:
		c[3] += (n as GPUParticles3D).amount
	for ch: Node in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		var cc: Array[int] = _count(ch)
		for k: int in 5:
			c[k] += cc[k]
	return c
