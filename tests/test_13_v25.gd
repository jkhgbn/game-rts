extends SceneTree
## Task 13.V25: the Dragon Roost model (art/buildings/lair/fire/dragon_roost.tscn) + the Ember Crucible annex on it.
## Run: godot --headless --path . -s tests/test_13_v25.gd --fixed-fps 60 --quit-after 900
## Checks: the scene instantiates headless; every building hook + play_raise + the crucible hooks exist and are safe
## before _ready (cached values applied); 0 lights; footprint 6 x 6 (below 2.45 m nothing beyond 3.3 m from the centre,
## above it nothing beyond 4.0 m); the nest crown is the top (9-10.5 m) and the widest mass above 7 m; the spire foot
## leaves the annex bounds free (no Roost vertex between 1.2 and 6.5 m inside them); draw nodes / materials within the
## hall budget; merged meshes shared, materials per instance; team colour reaches the banners and lashings; construction
## hides / shows parts (the annex hidden on a site); damage states revert when healed; play_raise flares the lava (> 2)
## and settles; the annex is a separate root child at ROOST_ANCHOR (not merged), lights, forges (crucible_poured relayed)
## and is seen from both cameras (ray test against the Roost's triangles); play_destroyed emits destroyed_finished after
## ~3 s, shows the wreck, puts the crucible out at once and hides it; a turned model keeps its gate on the right side;
## instance-uniform slot audit (KITFIX rules) on the Roost + annex.

const TASK_ID := "13.v25"
const PATH := "res://art/buildings/lair/fire/dragon_roost.tscn"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const BLUE := Color(0.2, 0.45, 0.95)
const ANCHOR := Vector3(1.85, 0.5, -1.85)
const ANNEX_RECT := Rect2(0.55, -3.18, 2.6, 2.7)

var frame := 0
var _errors: PackedStringArray = PackedStringArray()
var _world: Node3D
var _m: Node3D          # idle, built
var _early: Node3D      # hooks called before _ready
var _site: Node3D       # construction
var _dead: Node3D       # crucible lit, then destroyed
var _annexed: Node3D    # crucible installed and lit at frame 3
var _turned: Node3D     # under a -90 degree holder (player side)
var _destroyed_at: int = -1
var _max_flare: float = 0.0
var _poured: int = 0


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
	_early.call(&"set_team_color", BLUE)
	_early.call(&"set_construction_progress", 1.0)
	_early.call(&"set_health_ratio", 0.4)
	_early.call(&"set_selected", true)
	_early.call(&"play_raise")
	_early.call(&"play_forge")
	_early.call(&"play_training_pulse")
	_early.call(&"set_crucible", true)
	_early.position = Vector3(14, 0, 0)
	_world.add_child(_early)
	_site = scene.instantiate() as Node3D
	_site.call(&"set_construction_progress", 0.0)
	_site.position = Vector3(-14, 0, 0)
	_world.add_child(_site)
	_dead = scene.instantiate() as Node3D
	_dead.call(&"set_crucible", true, true)
	_dead.position = Vector3(0, 0, 14)
	_world.add_child(_dead)
	_dead.connect(&"destroyed_finished", func() -> void: _destroyed_at = frame)
	_annexed = scene.instantiate() as Node3D
	_annexed.position = Vector3(0, 0, -14)
	_world.add_child(_annexed)
	_annexed.connect(&"crucible_poured", func(_at: Vector3) -> void: _poured += 1)
	var holder := Node3D.new()
	holder.position = Vector3(-33, 0, 55)
	holder.rotation.y = -PI * 0.5
	_world.add_child(holder)
	_turned = scene.instantiate() as Node3D
	holder.add_child(_turned)


func _process(_delta: float) -> bool:
	if not _errors.is_empty() and frame < 2:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	frame += 1
	if frame == 3:
		_check_static()
		_check_states()
		_annexed.call(&"set_crucible", true)
		_dead.call(&"play_destroyed")
	if frame == 60:
		_check(float(_m.call(&"get_lava_flare")) == 0.0, "idle lava flare should be 0")
		_m.call(&"play_raise")
		_check(bool(_m.call(&"is_raising")), "play_raise did not start")
	if frame > 60 and frame < 140:
		_max_flare = maxf(_max_flare, float(_m.call(&"get_lava_flare")))
	if frame == 100:
		_check_annex_lit()
		_annexed.call(&"play_forge")
		var c: Node3D = _annexed.call(&"get_crucible")
		_check(c != null and bool(c.call(&"is_forging")), "play_forge not forwarded to the annex")
	if frame == 240:
		_check_raise()
		_check_destroyed()
		_check(_poured == 1, "crucible_poured relayed %d times (want 1)" % _poured)
		_check_occlusion()
		_check_audit()
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


func _is_annex(model: Node3D, n: Node) -> bool:
	var a: Node = model.get_node_or_null(^"CrucibleAnnex")
	return a != null and (a == n or a.is_ancestor_of(n))


## Mesh instances of the Roost itself (no annex, decals, light pool, rubble ring), visible ones only if asked.
func _roost_meshes(model: Node3D, visible_only: bool) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for n: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.name.contains("Decal") or mi.name == "LightPool" or mi.name == "TerraceProps" or mi.mesh == null \
				or _is_annex(model, mi):
			continue
		if visible_only and not mi.is_visible_in_tree():
			continue
		out.append(mi)
	return out


func _vertices(model: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var inv: Transform3D = model.global_transform.affine_inverse()
	for mi: MeshInstance3D in _roost_meshes(model, true):
		var xf: Transform3D = inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v: Vector3 in verts:
				var w: Vector3 = xf * v
				out.append(w)
				var r: float = maxf(absf(w.x), absf(w.z))
				if (w.y < 2.45 and r > 3.3) or (w.y >= 2.45 and r > 4.0) \
						or (w.y > 1.2 and w.y < 6.5 and ANNEX_RECT.has_point(Vector2(w.x, w.z))):
					if not _reported.has(mi.name):
						_reported[mi.name] = true
						print("  out of bounds: %s surface %d at %s" % [model.get_path_to(mi), s, w])
	return out


var _reported: Dictionary = {}


func _check_static() -> void:
	_check(_count_lights(root) == 0, "expected 0 lights, found %d" % _count_lights(root))
	for meth: StringName in [&"set_team_color", &"set_construction_progress", &"set_health_ratio", &"set_selected",
			&"play_training_pulse", &"play_destroyed", &"play_raise", &"is_raising", &"get_lava_flare", &"set_crucible",
			&"play_forge", &"has_crucible", &"is_crucible_lit", &"get_crucible"]:
		_check(_m.has_method(meth), "model lacks %s" % meth)
	_check(_m.has_signal(&"destroyed_finished"), "model lacks signal destroyed_finished")
	_check(_m.has_signal(&"crucible_poured"), "model lacks signal crucible_poured")
	# Footprint and heights (built, idle).
	var verts := _vertices(_m)
	_check(verts.size() > 1500, "too few vertices (%d)" % verts.size())
	var worst_low: float = 0.0
	var worst_high: float = 0.0
	var top: float = 0.0
	var nest_min := Vector2(INF, INF)
	var nest_max := Vector2(-INF, -INF)
	var in_annex: int = 0
	for v: Vector3 in verts:
		var r: float = maxf(absf(v.x), absf(v.z))
		if v.y < 2.45:
			worst_low = maxf(worst_low, r - 3.0)
		else:
			worst_high = maxf(worst_high, r - 3.0)
		top = maxf(top, v.y)
		if v.y > 7.0:
			nest_min = Vector2(minf(nest_min.x, v.x), minf(nest_min.y, v.z))
			nest_max = Vector2(maxf(nest_max.x, v.x), maxf(nest_max.y, v.z))
		if v.y > 1.2 and v.y < 6.5 and ANNEX_RECT.has_point(Vector2(v.x, v.z)):
			in_annex += 1   # (TerraceProps, the pre-annex dressing, is left out by _vertices)
	_check(worst_low <= 0.3, "ground-level overhang %.2f m > 0.3" % worst_low)
	_check(worst_high <= 1.0, "overhang above 2.5 m %.2f m > 1.0" % worst_high)
	_check(top > 9.0 and top < 10.5, "top of the nest at %.2f m (want 9-10.5)" % top)
	var nest_w: Vector2 = nest_max - nest_min
	_check(nest_w.x > 4.6 and nest_w.y > 4.6, "nest crown only %.1f x %.1f m wide (want > 4.6: the dominant)" % [nest_w.x,
		nest_w.y])
	_check(in_annex == 0, "%d spire vertices inside the annex bounds between 1.2 and 6.5 m" % in_annex)
	for p: String in ["Body/PlinthBase", "Body/PlinthBase/TerraceProps", "Body/Spire", "Body/Gatehouse", "Body/Lava",
			"Body/Perch/PerchParts", "Body/Nest/NestBowl", "Body/Nest/NestSpikes", "Body/Nest/NestSpikesFront",
			"Body/Nest/BannerPlayer", "Body/Nest/BannerEnemy", "Body/Nest/NestFire", "LightPool", "ContactDecal",
			"Scaffold", "Wreck"]:
		_check(_m.get_node_or_null(p) != null, "missing node %s" % p)
	# Budget: visible draw nodes and unique materials (the Roost alone).
	var draws: int = 0
	var mats: Dictionary = {}
	for n: Node in _m.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		draws += 1
		for mat: Material in _materials_of(gi):
			mats[mat] = true
	_check(draws <= 32, "%d visible draw nodes (budget 32)" % draws)
	var shader_mats: int = 0
	for mat: Material in mats.keys():
		if mat is ShaderMaterial:
			shader_mats += 1
	_check(shader_mats <= 10, "%d shader materials (budget 10)" % shader_mats)
	var particles: int = 0
	for n: Node in _m.find_children("*", "GPUParticles3D", true, false):
		if (n as GPUParticles3D).emitting:
			particles += (n as GPUParticles3D).amount
	_check(particles <= 90, "%d idle particles (budget 90)" % particles)
	print("13.v25 budget: %d visible draw nodes, %d shader materials, %d vertices, %d idle particles, top %.2f m, nest %.1f x %.1f m, 0 lights"
		% [draws, shader_mats, verts.size(), particles, top, nest_w.x, nest_w.y])
	# Shared meshes between instances, materials per instance.
	var s1 := _m.get_node(^"Body/Spire") as MeshInstance3D
	var s2 := _site.get_node(^"Body/Spire") as MeshInstance3D
	_check(s1.mesh == s2.mesh, "the merged spire mesh is not shared between instances")
	_check(s1.get_surface_override_material(0) != s2.get_surface_override_material(0),
		"materials must be per instance (selection rim)")
	# Early hooks kept.
	var team_mat: ShaderMaterial = _early.get(&"mat_team")
	_check(team_mat != null and (team_mat.get_shader_parameter(&"base_color") as Color).is_equal_approx(BLUE),
		"team colour set before _ready not applied")
	var banner_mat: ShaderMaterial = _early.get(&"mat_banner")
	_check(banner_mat != null and (banner_mat.get_shader_parameter(&"cloth_color") as Color).is_equal_approx(BLUE),
		"team colour not on the banners")
	_check(not (_early.get_node(^"Body/Nest/NestSpikesFront") as Node3D).visible, "early 40 % HP: front spikes still shown")
	_check(not bool(_early.call(&"is_raising")), "play_raise before _ready must be ignored")
	var ec: Node3D = _early.call(&"get_crucible")
	_check(ec != null and ec.visible and bool(ec.call(&"is_crucible_on")) and float(ec.call(&"heat")) >= 1.0,
		"crucible lit before _ready: annex missing / hidden / not at full heat")
	_check(not (_early.get_node(^"Body/PlinthBase/TerraceProps") as Node3D).visible, "terrace props shown under the annex")
	_check(_m.call(&"get_crucible") == null and (_m.get_node(^"Body/PlinthBase/TerraceProps") as Node3D).visible,
		"no crucible yet: the annex must not exist and the terrace props must show")
	# The turned model (player side): gate (-Z local) faces world +X.
	var gate_dir: Vector3 = _turned.global_transform.basis * Vector3.FORWARD
	_check(gate_dir.dot(Vector3.RIGHT) > 0.99, "turned model gate faces %s" % gate_dir)


func _check_states() -> void:
	# Construction: at 0 only the outline shows; mid-way some parts rise; 1 = all. The annex stays hidden on a site.
	var outline := _site.get_node_or_null(^"BuildOutline") as Node3D
	_check(outline != null and outline.visible, "site: no glowing outline")
	for p: String in ["Body/Nest", "Body/Perch", "Body/Spire", "Body/Gatehouse"]:
		_check(not (_site.get_node(p) as Node3D).visible, "site at 0 %%: %s visible" % p)
	_check(not (_site.get_node(^"LightPool") as Node3D).visible, "site: light pool should be off")
	_site.call(&"set_crucible", true)
	var sc: Node3D = _site.call(&"get_crucible")
	_check(sc != null and not sc.visible, "site: the annex must be hidden")
	_site.call(&"set_construction_progress", 0.3)
	_check((_site.get_node(^"Body/PlinthBase") as Node3D).visible and not (_site.get_node(^"Body/Nest") as Node3D).visible,
		"site at 30 %: plinth up, nest not yet")
	_check((_site.get_node(^"Scaffold") as Node3D).visible, "site at 30 %: no scaffolding")
	_site.call(&"play_raise")
	_check(not bool(_site.call(&"is_raising")), "play_raise must be ignored on a site")
	_site.call(&"set_construction_progress", 1.0)
	_check((_site.get_node(^"Body/Nest") as Node3D).visible and (_site.get_node(^"Body/Perch") as Node3D).visible,
		"site at 100 %: parts missing")
	_check(sc != null and sc.visible, "built: the installed annex should show")
	_check((_site.get_node(^"LightPool") as Node3D).visible, "built: light pool should be on")
	# Damage on the idle one, then heal.
	var front := _m.get_node(^"Body/Nest/NestSpikesFront") as Node3D
	var stubs := _m.get_node(^"Body/Nest/NestStubs") as Node3D
	var burn := _m.get_node(^"Body/Nest/NestBowl/NestBurn") as Node3D
	var banner := _m.get_node(^"Body/Nest/BannerPlayer") as Node3D
	_m.call(&"set_health_ratio", 0.4)
	_check(not front.visible and stubs.visible and banner.visible and not burn.visible, "40 %: spikes / stubs / banner wrong")
	_m.call(&"set_health_ratio", 0.2)
	_check(not banner.visible and burn.visible, "20 %: banner should be lost, burnt patch shown")
	var smoke := _m.get_node_or_null(^"Body/Smoke1") as GPUParticles3D
	var blaze := _m.get_node_or_null(^"Body/Blaze1") as GPUParticles3D
	_check(smoke != null and smoke.emitting and blaze != null and blaze.emitting, "20 %: smoke / fire not emitting")
	_m.call(&"set_health_ratio", 1.0)
	_check(front.visible and not stubs.visible and banner.visible and not burn.visible and not smoke.emitting,
		"healed: damage did not revert")
	_m.call(&"set_selected", true)
	_m.call(&"set_selected", false)
	_m.call(&"set_team_color", Color(0.85, 0.30, 0.12))


func _check_annex_lit() -> void:
	var c: Node3D = _annexed.call(&"get_crucible")
	_check(c != null, "set_crucible(true) did not install the annex")
	if c == null:
		return
	_check(c.get_parent() == _annexed, "the annex must be a direct child of the Roost model (not merged, not in Body)")
	_check(c.position.is_equal_approx(ANCHOR), "annex at %s (want %s)" % [c.position, ANCHOR])
	_check(c.visible and bool(c.call(&"is_crucible_on")) and float(c.call(&"heat")) >= 0.99, "annex not lit after 1.6 s")
	_check(bool(_annexed.call(&"has_crucible")) and bool(_annexed.call(&"is_crucible_lit")), "has_crucible / is_crucible_lit")
	# Not merged: none of the annex meshes is one of the Roost's.
	var roost_meshes: Dictionary = {}
	for mi: MeshInstance3D in _roost_meshes(_annexed, false):
		roost_meshes[mi.mesh] = true
	for n: Node in c.find_children("*", "MeshInstance3D", true, false):
		_check(not roost_meshes.has((n as MeshInstance3D).mesh), "annex mesh %s merged into the Roost" % n.name)


func _check_raise() -> void:
	_check(_max_flare > 2.0, "play_raise flared only %.2f (want > 2)" % _max_flare)
	_check(not bool(_m.call(&"is_raising")) and float(_m.call(&"get_lava_flare")) == 0.0, "the raise did not settle")
	var lava: ShaderMaterial = _m.get(&"mat_lava")
	_check(lava != null and absf(float(lava.get_shader_parameter(&"boost")) - 1.0) < 0.01, "lava boost not back to 1")


func _check_destroyed() -> void:
	# play_destroyed at frame 3, 3.0 s at 60 fps -> frame ~183.
	_check(_destroyed_at > 150 and _destroyed_at < 200, "destroyed_finished at frame %d (want ~183)" % _destroyed_at)
	var wreck := _dead.get_node_or_null(^"Wreck") as Node3D
	_check(wreck != null and wreck.visible, "wreck not shown")
	_check(wreck != null and wreck.get_node_or_null(^"WreckExtra") != null, "fallen nest / beams missing")
	_check(not (_dead.get_node(^"Body/Nest") as Node3D).visible, "the nest should have fallen and vanished")
	var c: Node3D = _dead.call(&"get_crucible")
	_check(c != null and not c.visible, "the annex must be hidden on the wreck")
	_check(c != null and not bool(c.call(&"is_crucible_on")) and float(c.call(&"heat")) == 0.0,
		"the crucible must go out at once with the Roost")
	_dead.call(&"set_crucible", true)   # a dead Roost never relights
	_check(c != null and not bool(c.call(&"is_crucible_on")) and not c.visible, "a wreck relit its crucible")
	_dead.call(&"play_raise")            # ignored on a wreck, must not error
	_dead.call(&"play_forge")


## The annex must stay readable from both cameras: rays from its key points toward each camera against the Roost's
## triangles (the player's camera looks from local +X, the enemy's from local -X, pitch 55 degrees).
func _check_occlusion() -> void:
	var tris := PackedVector3Array()
	var owners: Array[String] = []
	var inv: Transform3D = _annexed.global_transform.affine_inverse()
	for mi: MeshInstance3D in _roost_meshes(_annexed, true):
		var xf: Transform3D = inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if idx.is_empty():
				for i: int in v.size():
					tris.append(xf * v[i])
					owners.append(mi.name)
			else:
				for i: int in idx:
					tris.append(xf * v[i])
					owners.append(mi.name)
	# Annex points (annex space): molten bowl centre and rims, the -X fire mouth, the +X fire mouth, the chimney top.
	var pts: Array[Vector3] = [Vector3(0, 1.95, 0.35), Vector3(0.45, 1.95, 0.35), Vector3(-0.45, 1.95, 0.35),
		Vector3(0, 1.95, -0.1), Vector3(-0.72, 0.73, 0.35), Vector3(0.72, 0.73, 0.35), Vector3(0, 2.6, 1.02)]
	var result: Dictionary = {}
	for cam: String in ["player", "enemy"]:
		var dir := Vector3(0.574 if cam == "player" else -0.574, 0.819, 0.0)
		var seen: int = 0
		for p: Vector3 in pts:
			var from: Vector3 = ANCHOR + p + dir * 0.05
			var hit := false
			for i: int in range(0, tris.size(), 3):
				if Geometry3D.ray_intersects_triangle(from, dir, tris[i], tris[i + 1], tris[i + 2]) != null:
					hit = true
					print("    by ", owners[i])
					break
			if not hit:
				seen += 1
			else:
				print("  %s camera: annex point %s hidden" % [cam, p])
		result[cam] = seen
	print("annex points seen: player %d / %d, enemy %d / %d (%d Roost triangles)" % [result["player"], pts.size(),
		result["enemy"], pts.size(), tris.size() / 3])
	_check(int(result["player"]) == pts.size(), "the player camera loses part of the annex")
	_check(int(result["enemy"]) >= pts.size() - 2, "the enemy camera sees only %d / %d annex points" % [result["enemy"],
		pts.size()])


func _materials_of(gi: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if gi.material_override:
		out.append(gi.material_override)
	var mi := gi as MeshInstance3D
	if mi and mi.mesh:
		for s: int in mi.mesh.get_surface_count():
			var m: Material = mi.get_surface_override_material(s)
			if m == null:
				m = mi.mesh.surface_get_material(s)
			if m and not out.has(m):
				out.append(m)
	var mmi := gi as MultiMeshInstance3D
	if mmi and mmi.multimesh and mmi.multimesh.mesh:
		for s: int in mmi.multimesh.mesh.get_surface_count():
			var m: Material = mmi.multimesh.mesh.surface_get_material(s)
			if m and not out.has(m):
				out.append(m)
	return out


## KITFIX rules: on every geometry, two different instance uniforms must never share a slot.
func _check_audit() -> void:
	var K: GDScript = load(KITFIX)
	if K == null:
		_check(false, "kitfix script missing")
		return
	var collisions: int = 0
	var geos: int = 0
	for m: Node3D in [_annexed, _dead]:
		for g: Node in m.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if gi is GPUParticles3D:
				continue
			geos += 1
			var by_slot: Dictionary = {}
			for mat: Material in _materials_of(gi):
				if not mat is ShaderMaterial or (mat as ShaderMaterial).shader == null:
					continue
				for u: Array in K.call(&"_instance_uniforms", (mat as ShaderMaterial).shader):
					if by_slot.has(u[1]) and by_slot[u[1]] != u[0]:
						collisions += 1
						_check(false, "%s: %s and %s on slot %d" % [m.get_path_to(gi), by_slot[u[1]], u[0], u[1]])
					by_slot[u[1]] = u[0]
	print("slot audit: %d geometries, %d collisions" % [geos, collisions])
	if collisions == 0:
		print("KITFIX AUDIT OK (dragon_roost + crucible annex: no instance-uniform slot collision)")
