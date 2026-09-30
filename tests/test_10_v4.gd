extends SceneTree
## Task 10.V4: the Grove Bazaar model (art/buildings/market/nature/market_nature.tscn).
## Headless check:  $GODOT --headless --path . -s tests/test_10_v4.gd --fixed-fps 60 --quit-after 1500
##   instantiation, hooks (incl. play_delivery) and calls before _ready, 0 lights, indexed meshes, budgets (vertices,
##   draw surfaces, own materials), footprint and height, construction stages, delivery tip (pans stay level),
##   damage states and healing back, selection rim, collapse -> destroyed_finished + wreck, the bake is not stale,
##   the second instance reuses the cached meshes. Prints PASS 10.v4 / FAIL 10.v4.
## Shots (windowed):  Godot_v4.7.2-stable_win64_console.exe --path . -s tests/test_10_v4.gd --fixed-fps 60 --quit-after 6000 -- --shots
##   docs/art/screens/market_nature_*.png (RTS camera at zoom 12 / 18 / 30 / 45 beside the Grove Hall and Seed Hollow,
##   the four sides, states sheet, silhouette), and docs/art/screens/bazaars_silhouette.png with every Bazaar that
##   exists (fire, shadow, ice, nature; each seen from the player's side then the enemy's), black on white at 40 m.

const TASK_ID := "10.v4"
const SCENE := "res://art/buildings/market/nature/market_nature.tscn"
const OWN_DIR := "res://art/buildings/market/nature/"
const HOOKS: Array[String] = ["set_team_color", "set_construction_progress", "set_health_ratio", "play_training_pulse",
	"play_destroyed", "set_selected", "play_delivery"]
const RED := Color(0.85, 0.22, 0.18)
const BAZAARS: Array[String] = ["fire", "shadow", "ice", "nature"]

var _fails: PackedStringArray = []
var _world: Node3D
var _cam: Camera3D
var _ground: MeshInstance3D
var _zoom: float = 30.0
var _focus := Vector3.ZERO


func _initialize() -> void:
	if "--shots" in OS.get_cmdline_user_args():
		_shots.call_deferred()
	else:
		_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAIL: ", what)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


# ================================================================ headless test

func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var packed := load(SCENE) as PackedScene
	_check(packed != null, "scene loads")
	if packed == null:
		_finish()
		return
	var t0: int = Time.get_ticks_usec()
	var a: Node3D = packed.instantiate()
	_world.add_child(a)
	var first_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	# Hooks before _ready are cached (art-keep 8.8): a red, half-built, hurt Bazaar.
	var b: Node3D = packed.instantiate()
	for h: String in HOOKS:
		_check(b.has_method(h), "hook %s exists" % h)
	_check(b.has_signal(&"destroyed_finished"), "signal destroyed_finished")
	b.call(&"set_team_color", RED)
	b.call(&"set_construction_progress", 0.5)
	b.call(&"set_health_ratio", 0.3)
	b.call(&"set_selected", true)
	b.call(&"play_delivery")
	b.position = Vector3(12, 0, 0)
	t0 = Time.get_ticks_usec()
	_world.add_child(b)
	var next_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	print("build: first instance %.1f ms, next %.1f ms" % [first_ms, next_ms])
	await _frames(3)

	# ---- team colour before _ready
	var trunk_b := b.get_node_or_null(^"Body/Tree/Mast") as MeshInstance3D
	_check(trunk_b != null, "Body/Tree/Mast exists")
	var leaves_col := Color.BLACK
	var card_col := Color.BLACK
	if trunk_b:
		for s: int in trunk_b.mesh.get_surface_count():
			var m := trunk_b.get_surface_override_material(s) as ShaderMaterial
			if m and m.resource_name == "Leaves":
				leaves_col = m.get_shader_parameter(&"base_color")
			elif m and m.resource_name == "LeafCard":
				card_col = m.get_shader_parameter(&"base_color")
			elif m and (m.resource_name == "NaturePainted" or m.resource_name == "NatureCards"):
				# B8 merge (2026-09-30, NatureVC): one merged painted and one merged card material; the team colour
				# lives in the Leaves / LeafCard source materials and in the merged arrays (linear).
				var srcs: Dictionary = b.get(&"_mats")
				var key: String = "Leaves" if m.resource_name == "NaturePainted" else "LeafCard"
				var col: Color = (srcs[key] as ShaderMaterial).get_shader_parameter(&"base_color")
				var arr: PackedVector3Array = m.get_shader_parameter(&"base_colors" if key == "Leaves" else &"base_color_c")
				var lin: Color = col.srgb_to_linear()
				var slot: int = 5 if key == "Leaves" else 0
				if arr.size() > slot and Vector3(lin.r, lin.g, lin.b).distance_to(arr[slot]) < 0.002:
					if key == "Leaves":
						leaves_col = col
					else:
						card_col = col
	_check(leaves_col.is_equal_approx(RED), "set_team_color before _ready recolours the crown (%s)" % leaves_col)
	_check(card_col.is_equal_approx(RED), "set_team_color recolours the leaf cards (%s)" % card_col)
	var banner_b := b.get_node_or_null(^"Body/BannerA") as MeshInstance3D
	_check(banner_b != null and (banner_b.get_surface_override_material(0) as ShaderMaterial).get_shader_parameter(&"cloth_color") == RED,
		"banner cloth is the team colour")
	var stall_b := b.get_node(^"Body/Stall") as Node3D
	_check(stall_b.visible, "a half-built Bazaar shows its lower parts")
	_check((b.get_node(^"Scaffold") as Node3D).visible, "scaffold visible while building")

	# ---- no lights, indexed meshes, budgets
	_check(a.find_children("*", "Light3D", true, false).is_empty(), "0 lights in the tree")
	var unindexed: PackedStringArray = []
	for n: Node in a.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh is ArrayMesh:
			for s: int in mi.mesh.get_surface_count():
				var idx: Variant = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX]
				if idx == null or (idx as PackedInt32Array).is_empty():
					unindexed.append("%s/%d" % [a.get_path_to(mi), s])
	_check(unindexed.is_empty(), "every mesh is indexed %s" % unindexed)
	var c: Dictionary = _count(a)
	print("idle: meshes=%d surfaces=%d multimesh=%d particles(emitting)=%d systems=%d verts=%d" % [c.meshes, c.surfaces,
		c.multimesh, c.particles, c.systems, c.verts])
	_check(c.verts <= 12000, "vertices <= 12000 (%d)" % c.verts)
	var draws: int = c.surfaces + c.multimesh + c.systems
	print("draw surfaces idle (meshes + multimesh + emitting particle systems): ", draws)
	_check(draws <= 36, "draw surfaces <= 36 idle, under the Grove Hall's 37 (%d)" % draws)
	_check(c.particles <= 90, "idle particles <= 90 (%d)" % c.particles)
	var own: PackedStringArray = []
	for n: Node in a.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var m: Material = mi.get_surface_override_material(s)
			if m == null:
				m = mi.material_override
			if m and not own.has(m.resource_name):
				own.append(m.resource_name)
	print("materials used: ", own)
	_check(own.size() <= 16, "materials per Bazaar <= 16 (%d)" % own.size())

	# ---- footprint and height (Body space). The roof, banners, lanterns and the sign stay within ~0.45 m of the 6 x 6
	# footprint; the crown and the roots poured on the ground may reach further, like the Grove Hall's.
	var body := a.get_node(^"Body") as Node3D
	var top: float = 0.0
	var reach_low: float = 0.0
	var reach_all: float = 0.0
	for n: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.mesh == null:
			continue
		var xf: Transform3D = body.global_transform.affine_inverse() * mi.global_transform
		var box: AABB = xf * mi.get_aabb()
		top = maxf(top, box.end.y)
		var r: float = maxf(maxf(absf(box.position.x), absf(box.end.x)), maxf(absf(box.position.z), absf(box.end.z)))
		reach_all = maxf(reach_all, r)
		if mi.name in [&"Roof", &"RoofLost", &"BannerA", &"BannerB", &"Lantern", &"PanParts", &"BeamParts"]:
			reach_low = maxf(reach_low, r)
	var plinth := body.get_node(^"PlinthBase") as MeshInstance3D
	var pm := plinth.mesh as ArrayMesh
	var plinth_half: float = 0.0
	for s: int in pm.get_surface_count():
		var sname: String = (plinth.get_surface_override_material(s) as ShaderMaterial).resource_name
		if sname != "Stone" and sname != "NaturePainted":
			continue
		var arrs: Array = pm.surface_get_arrays(s)
		var ids: Variant = arrs[Mesh.ARRAY_CUSTOM0]   # B8 merge (NatureVC): the painted index per vertex, 0 = Stone
		var verts: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
		for vi: int in verts.size():
			if sname == "NaturePainted" and ids is PackedFloat32Array and absf((ids as PackedFloat32Array)[vi]) > 0.5:
				continue
			plinth_half = maxf(plinth_half, maxf(absf(verts[vi].x), absf(verts[vi].z)))
	print("top %.2f m, plinth top tier half %.2f m, roof / banners / sign reach %.2f m, everything %.2f m" % [top, plinth_half,
		reach_low, reach_all])
	_check(top >= 7.0 and top <= 10.0, "height 7-10 m, the sibling Bazaars' masts are 9-10 m (%.2f)" % top)
	_check(plinth_half <= 3.0, "plinth inside the 6 x 6 footprint (%.2f)" % plinth_half)
	_check(reach_low <= 3.45, "roof, banners and sign overhang the footprint by <= 0.45 m (%.2f)" % reach_low)
	_check(reach_all <= 4.3, "crown and roots within 1.3 m of the footprint (%.2f)" % reach_all)

	# ---- construction stages
	var parts: Array[Node3D] = []
	parts.assign(a.get(&"_parts"))   # the base class's construction parts (test-only peek)
	_check(parts.size() >= 6, "at least 6 construction tiers (%d)" % parts.size())
	a.call(&"set_construction_progress", 0.0)
	var shown: int = 0
	for p: Node3D in parts:
		shown += 1 if p.visible else 0
	_check(shown == 0, "progress 0: only the outline (%d parts shown)" % shown)
	_check((a.get_node(^"BuildOutline") as Node3D).visible, "progress 0: glowing outline")
	a.call(&"set_construction_progress", 0.35)
	shown = 0
	for p: Node3D in parts:
		shown += 1 if p.visible else 0
	_check(shown > 0, "progress 0.35: parts rising (%d / %d)" % [shown, parts.size()])
	_check((a.get_node(^"Scaffold") as Node3D).visible, "progress 0.35: scaffold")
	var mast_sy: float = (body.get_node(^"Tree") as Node3D).transform.basis.y.length()
	_check(mast_sy < 0.5, "progress 0.35: the mast is only partly grown (scale %.2f)" % mast_sy)
	print("progress 0.35: %d / %d tiers shown" % [shown, parts.size()])
	a.call(&"set_construction_progress", 1.0)
	shown = 0
	for p: Node3D in parts:
		shown += 1 if p.visible else 0
	_check(shown == parts.size(), "progress 1: every part (%d / %d)" % [shown, parts.size()])
	_check(not (a.get_node(^"Scaffold") as Node3D).visible, "progress 1: scaffold gone")
	await _frames(40)

	# ---- delivery: the scale tips toward the gold pan and swings back, the pans hang level
	var beam := a.get_node(^"Body/Tree/Beam") as Node3D
	var pan_gold := a.get_node(^"Body/Tree/PanGold") as Node3D
	var pan_seed := a.get_node(^"Body/Tree/PanSeed") as Node3D
	var idle_max: float = 0.0
	for i: int in 30:
		await process_frame
		idle_max = maxf(idle_max, absf(rad_to_deg(beam.rotation.z)))
	a.call(&"play_delivery")
	var burst := a.get_node(^"Body/CoinGlint") as GPUParticles3D
	_check(burst != null and burst.emitting, "delivery fires the gold glint burst")
	var peak: float = 0.0
	var gold_y_min: float = INF
	var level_ok: bool = true
	for i: int in 30:
		await process_frame
		peak = maxf(peak, rad_to_deg(beam.rotation.z))
		gold_y_min = minf(gold_y_min, pan_gold.global_position.y)
		for pan: Node3D in [pan_gold, pan_seed]:
			if pan.global_transform.basis.y.normalized().dot(Vector3.UP) < 0.99:
				level_ok = false
	print("scale: idle sway <= %.1f deg, delivery peak %.1f deg" % [idle_max, peak])
	_check(idle_max < 3.0, "idle sway is gentle (%.1f)" % idle_max)
	_check(peak > 6.0, "delivery tips the scale toward the gold pan (%.1f deg)" % peak)
	_check(level_ok, "the pans hang level while the beam tips")
	var hub_y: float = beam.global_position.y
	_check(gold_y_min < hub_y, "the gold end of the beam dips below the hub")
	await _frames(150)
	_check(absf(rad_to_deg(beam.rotation.z)) < 3.0, "the scale settles after the delivery (%.1f)" % rad_to_deg(beam.rotation.z))

	# ---- training pulse, selection
	a.call(&"play_training_pulse")
	await _frames(4)
	var trunk := a.get_node(^"Body/Tree/Mast") as MeshInstance3D
	var bark: ShaderMaterial = null
	for s: int in trunk.mesh.get_surface_count():
		var m := trunk.get_surface_override_material(s) as ShaderMaterial
		if m and m.resource_name == "Bark":
			bark = m
	if bark == null:   # B8 merge (NatureVC): the Bark source material still takes the rim (mirrored into the merged one)
		bark = (a.get(&"_mats") as Dictionary)["Bark"]
	var rim0: float = bark.get_shader_parameter(&"rim_strength")
	a.call(&"set_selected", true)
	await _frames(20)
	var rim1: float = bark.get_shader_parameter(&"rim_strength")
	_check(rim1 > 0.8 and rim0 < 0.4, "selection rim %.2f -> %.2f" % [rim0, rim1])
	a.call(&"set_selected", false)
	await _frames(20)

	# ---- damage states and healing back
	var lost := a.get_node(^"Body/Canopy/RoofLost") as Node3D
	var fallen := a.get_node(^"Body/FallenLeaves") as Node3D
	var banner := a.get_node(^"Body/BannerB") as Node3D
	var smoke := a.get_node(^"Body/Smoke1") as GPUParticles3D
	var blaze := a.get_node(^"Body/Blaze1") as GPUParticles3D
	a.call(&"set_health_ratio", 0.4)
	await _frames(2)
	_check(not lost.visible and fallen.visible and smoke.emitting and banner.visible, "< 50 %: roof corner torn off, smoke")
	a.call(&"set_health_ratio", 0.2)
	await _frames(2)
	_check(not banner.visible and blaze.emitting, "< 25 %: a banner lost, withering leaves")
	var c25: Dictionary = _count(a)
	print("25 %%: draw surfaces %d, particles %d" % [c25.surfaces + c25.multimesh + c25.systems, c25.particles])
	_check(c25.particles <= 200, "particles at 25 %% <= 200 (%d)" % c25.particles)
	a.call(&"set_health_ratio", 1.0)
	await _frames(2)
	_check(lost.visible and not fallen.visible and banner.visible and not smoke.emitting and not blaze.emitting,
		"healed: everything back")

	# ---- collapse
	var done: Array = [false]
	a.connect(&"destroyed_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	a.call(&"play_destroyed")
	a.call(&"play_delivery")   # ignored once destroyed
	await _frames(60)
	_check(not (body.get_node(^"Tree") as Node3D).visible or (body.get_node(^"Tree") as Node3D).rotation.length() > 0.1,
		"the mast falls")
	await _frames(130)
	_check(done[0], "destroyed_finished within 3.2 s")
	_check((a.get_node(^"Wreck") as Node3D).visible, "wreck shown")
	_check(not (body.get_node(^"Stall") as Node3D).visible and not (body.get_node(^"Canopy") as Node3D).visible,
		"stall and roof swapped for the wreck")
	_check(not (body.get_node(^"Tree") as Node3D).visible, "the fallen mast is gone")

	# ---- the bake is present and not stale
	var stale: PackedStringArray = []
	var missing: PackedStringArray = []
	for key: String in NatureMarketModel.cached_keys():
		if not ResourceLoader.exists(NatureMarketModel.baked_path(key)):
			missing.append(key)
			continue
		var baked: ArrayMesh = NatureMarketModel.cached_mesh(key)
		var build: Callable = NatureMarketModel.builder_of(key)
		if not build.is_valid():
			continue
		var fresh: ArrayMesh = NatureKit.build_fresh(build)[0]
		if fresh.get_surface_count() != baked.get_surface_count():
			stale.append(key)
			continue
		for s: int in fresh.get_surface_count():
			var nf: int = (fresh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var nb: int = (baked.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			if nf != nb or fresh.surface_get_name(s) != baked.surface_get_name(s):
				stale.append("%s/%d" % [key, s])
				break
	print("baked meshes: %d keys, missing %s, stale %s" % [NatureMarketModel.cached_keys().size(), missing, stale])
	_check(missing.is_empty(), "every mesh is baked (run market_nature_bake.gd windowed) %s" % missing)
	_check(stale.is_empty(), "the bake is not stale (rerun market_nature_bake.gd) %s" % stale)
	b.call(&"play_destroyed")
	await _frames(10)
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## Visible geometry (mesh instances, their surfaces, multimeshes with instances), emitting particle systems and
## their particles, vertices of the visible meshes.
func _count(n: Node) -> Dictionary:
	var c: Dictionary = {"meshes": 0, "surfaces": 0, "multimesh": 0, "systems": 0, "particles": 0, "verts": 0}
	_count_into(n, c)
	return c


func _count_into(n: Node, c: Dictionary) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var m: Mesh = (n as MeshInstance3D).mesh
		c.meshes += 1
		c.surfaces += m.get_surface_count()
		for s: int in m.get_surface_count():
			c.verts += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	elif n is MultiMeshInstance3D:
		var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
		if mm and mm.instance_count > 0:
			c.multimesh += 1
	elif n is GPUParticles3D and (n as GPUParticles3D).emitting:
		c.systems += 1
		c.particles += (n as GPUParticles3D).amount
	for ch: Node in n.get_children():
		_count_into(ch, c)


# ================================================================ shots (windowed)

func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_world = Node3D.new()
	root.add_child(_world)
	var rig_path := "res://art/environment/lighting/lighting_rig.gd"
	if ResourceLoader.exists(rig_path):
		var rig: Node = (load(rig_path) as GDScript).new()
		rig.set(&"preset_id", &"warm")
		_world.add_child(rig)
	else:
		var we := WorldEnvironment.new()
		we.environment = load("res://art/environment/world_env.tres")
		_world.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.light_color = Color(1.00, 0.93, 0.82)
		sun.light_energy = 1.3
		sun.rotation_degrees = Vector3(-50, 35, 0)
		sun.shadow_enabled = true
		_world.add_child(sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(300, 300)
	_ground.mesh = pm
	_ground.material_override = load("res://art/environment/ground_material.tres")
	_world.add_child(_ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	_world.add_child(_cam)
	# Scale reference: a 1.8 m worker at the caravan gate.
	var cap := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	cap.mesh = cm
	var capm := StandardMaterial3D.new()
	capm.albedo_color = Color(0.8, 0.7, 0.5)
	cap.material_override = capm
	cap.position = Vector3(-2.3, 0.9, 4.2)
	_world.add_child(cap)
	var baz: Node3D = _spawn(SCENE, Vector3.ZERO, -PI * 0.5)   # the player's side: the gate toward +X, local +X faces the camera
	var hall: Node3D = _spawn("res://art/buildings/nature_hall.tscn", Vector3(-9.0, 0, 0), -PI * 0.5)
	var hollow: Node3D = _spawn("res://art/buildings/nature_hollow.tscn", Vector3(7.5, 0, 0.5), -PI * 0.5)
	await _wait(1.5)
	# Game camera views.
	await _shot("z12", 12.0, Vector3(0.0, 2.6, 0.0), 1.2)
	await _shot("z18", 18.0, Vector3(0.0, 2.2, 0.0))
	await _shot("row_z30", 30.0, Vector3(-1.0, 1.5, 0.0))
	await _shot("row_z45", 45.0, Vector3(-1.0, 0.0, 0.0))
	# The four sides: player view (local +X to the camera), enemy view (-X), gate side, back.
	var sides: Array[Image] = []
	for yaw: float in [-PI * 0.5, PI * 0.5, PI, 0.0]:
		baz.rotation.y = yaw
		sides.append(await _shot("side_%d" % int(rad_to_deg(yaw)), 16.0, Vector3(0.0, 2.4, 0.0), 0.5))
	_sheet(sides, "market_nature_sides", 2)
	baz.rotation.y = -PI * 0.5
	# States.
	var sheet: Array[Image] = []
	var sf := Vector3(0.0, 2.2, 0.0)
	_zoom = 20.0
	_focus = sf
	_apply()
	baz.call(&"set_construction_progress", 0.0)
	await _wait(0.4)
	sheet.append(_grab("state_construct00"))
	baz.call(&"set_construction_progress", 0.35)
	await _wait(0.4)
	sheet.append(_grab("state_construct35"))
	baz.call(&"set_construction_progress", 0.75)
	await _wait(0.4)
	sheet.append(_grab("state_construct75"))
	baz.call(&"set_construction_progress", 1.0)
	await _wait(1.8)
	baz.call(&"set_selected", true)
	baz.call(&"play_training_pulse")
	await _wait(0.12)
	sheet.append(_grab("state_selected_pulse"))
	baz.call(&"set_selected", false)
	await _wait(1.0)
	baz.call(&"play_delivery")
	await _wait(0.3)
	sheet.append(_grab("state_delivery"))
	await _shot("delivery_z10", 10.0, Vector3(1.2, 4.8, -0.35), 0.05)
	_zoom = 20.0
	_focus = sf
	_apply()
	await _wait(2.5)
	baz.call(&"set_health_ratio", 0.4)
	await _wait(2.5)
	sheet.append(_grab("state_hp40"))
	baz.call(&"set_health_ratio", 0.2)
	await _wait(2.0)
	sheet.append(_grab("state_hp20"))
	baz.call(&"play_destroyed")
	await _wait(0.6)
	sheet.append(_grab("state_destroyed_0s6"))
	await _wait(0.8)
	sheet.append(_grab("state_destroyed_1s4"))
	await _wait(1.9)
	sheet.append(_grab("state_destroyed_3s3"))
	baz.queue_free()
	baz = _spawn(SCENE, Vector3.ZERO, -PI * 0.5)
	baz.call(&"set_team_color", RED)
	await _wait(1.5)
	sheet.append(_grab("state_red"))
	_sheet(sheet, "market_nature_states", 4)
	await _shot("red_z14", 14.0, Vector3(0.0, 2.6, 0.0), 0.3)
	# Silhouettes: the Grove Bazaar with the Hall and Hollow, then every Bazaar that exists.
	hall.queue_free()
	hollow.queue_free()
	cap.queue_free()
	await _silhouettes(baz)
	print("10.V4 SHOTS DONE")
	quit()


func _spawn(path: String, pos: Vector3, yaw: float) -> Node3D:
	var b := (load(path) as PackedScene).instantiate() as Node3D
	b.position = pos
	b.rotation.y = yaw
	_world.add_child(b)
	return b


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = _focus + Vector3(0.0, sin(p) * _zoom, cos(p) * _zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _grab(nm: String) -> Image:
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/market_nature_%s.png" % nm))
	print("saved market_nature_%s.png draw_calls=%d prims=%d" % [nm,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	return img


func _shot(nm: String, zoom: float, focus: Vector3, settle: float = 0.8) -> Image:
	_zoom = zoom
	_focus = focus
	_apply()
	await _wait(settle)
	await RenderingServer.frame_post_draw
	return _grab(nm)


func _sheet(imgs: Array[Image], nm: String, cols: int) -> void:
	var w: int = 640
	var h: int = 360
	var rows: int = ceili(float(imgs.size()) / cols)
	var out := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	for i: int in imgs.size():
		var img: Image = imgs[i].duplicate()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(w, h, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(ProjectSettings.globalize_path("res://docs/art/screens/%s.png" % nm))
	print("saved ", nm)


func _blacken(n: Node, black: Material) -> void:
	for ch: Node in n.find_children("*", "", true, false):
		if ch is GPUParticles3D:
			(ch as Node3D).visible = false
		elif ch is GeometryInstance3D:
			var g := ch as GeometryInstance3D
			if g.name.contains("Decal") or g.name.contains("Outline") or g.name.contains("Dressing") or g.name.contains("Rubble"):
				g.visible = false
			else:
				g.material_override = black
				g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Black on white at the 40 m game camera: this Bazaar from the player's side, the enemy's side and the gate, then
## every Bazaar that exists in a row (player view, then enemy view), saved as bazaars_silhouette.png.
func _silhouettes(baz: Node3D) -> void:
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ground.material_override = white
	var env := _find_env(_world)
	if env:
		env.glow_enabled = false
		env.fog_enabled = false
	baz.queue_free()
	var own: Array[Node3D] = []
	var xs: Array[float] = [-9.0, 0.0, 9.0]
	var yaws: Array[float] = [-PI * 0.5, PI * 0.5, PI]
	for i: int in 3:
		own.append(_spawn(SCENE, Vector3(xs[i], 0, 0), yaws[i]))
	await _wait(1.0)
	for o: Node3D in own:
		_blacken(o, black)
	await _shot("silhouette_z40", 40.0, Vector3(0.0, 0.0, 0.0), 0.4)
	for o: Node3D in own:
		o.queue_free()
	# The contact sheet of the four Bazaars.
	var row: Array[Node3D] = []
	var present: PackedStringArray = []
	var k: int = 0
	for id: String in BAZAARS:
		var path: String = "res://art/buildings/market/%s/market_%s.tscn" % [id, id]
		if not ResourceLoader.exists(path):
			continue
		present.append(id)
		for side: int in 2:
			row.append(_spawn(path, Vector3(-24.0 + 7.5 * float(k), 0, 0), -PI * 0.5 if side == 0 else PI * 0.5))
			k += 1
	await _wait(1.0)
	for o: Node3D in row:
		_blacken(o, black)
	var center: float = -24.0 + 7.5 * float(k - 1) * 0.5
	_zoom = 40.0 + maxf(0.0, float(k) - 6.0) * 5.0
	_focus = Vector3(center, 0.0, 0.0)
	_apply()
	await _wait(0.4)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/bazaars_silhouette.png"))
	print("saved bazaars_silhouette.png (player view then enemy view of: %s)" % ", ".join(present))


func _find_env(n: Node) -> Environment:
	for ch: Node in n.find_children("*", "WorldEnvironment", true, false):
		return (ch as WorldEnvironment).environment
	return null
