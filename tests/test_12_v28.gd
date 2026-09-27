extends SceneTree
## Task 12.V28: the Roc epic beast model, both variants in one scene (art/units/neutral/beasts/roc/roc.tscn).
## Run: $GODOT --headless --path . -s tests/test_12_v28.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (2 instances: the first builds and caches the meshes, the second reuses them; the
## second gets set_variant(1) BEFORE _ready), hero budget of map-fill.md 10 (<= 26 authored meshes, <= 16 draw
## instances, 0 lights; vertices <= 6 000), materials (own folder only: 3 Stormcrest + 3 Duskwing; storm-blue vs
## near-black with a violet sheen, the Duskwing's eyes red glow >= 2.5), set_variant swaps every surface and the feather
## burst both ways, size (span 6-7.4 m, gliding: body centre 2.5 m up, nothing below 1.2 m while idle, the ground blob on
## the ground under it), set_team_color is a no-op, the kit hooks + set_variant / get_variant, idle beats then glides,
## banking in turns, attack `talon_rake` (drop + talons forward at the 0.16 s strike, one strike, ends), casts
## `gale_swoop` (climb, dive to ~1.4 m, impact burst at 0.5 s, ends), `shrieking_dive` (beak wide, eyes flare),
## `updraft` (climbs > 2 m, holds while shrouded, comes back down, the blob shrinks), hit flash, statuses, death (falls to
## the ground, not through it, eyes dark, death_finished before Unit's 2.0 s fallback), revive resets.
## Prints "PASS 12.v28" or "FAIL 12.v28: <reasons>".

const TASK_ID := "12.v28"
const SCENE := "res://art/units/neutral/beasts/roc/roc.tscn"
const OWN_DIR := "res://art/units/neutral/beasts/roc/"
const DATA: Array[String] = ["res://data/units/stormcrest_roc.tres", "res://data/units/duskwing_roc.tres"]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	var n := int(ceil(sec * 60.0))
	for i: int in n:
		await process_frame


func _spawn(at: Vector3, variant: int = -1) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	if variant >= 0:
		m.call(&"set_variant", variant)       # before _ready: kept and applied
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	for p: String in DATA:
		var ut: Resource = load(p)
		_check(ut != null and String(ut.get(&"model_path")) == SCENE, "%s model_path points at the scene" % p.get_file())
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(12, 0, 0), 1)
	await _wait(0.2)
	_check(a is FlyerModel, "extends FlyerModel (the flying rig)")
	_check(int(a.call(&"get_variant")) == 0 and int(b.call(&"get_variant")) == 1, "variants 0 / 1 (b set before _ready)")
	# ---- structure / budgets
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored >= 10 and authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	for m: Node3D in [a, b]:
		var inst := _draw_instances(m)
		var verts := _vertices(m)
		var tris := _triangles(m)
		var lights := m.find_children("*", "Light3D", true, false).size()
		print("%s: draw instances %d, vertices %d, triangles %d, lights %d" % [m.name, inst, verts, tris, lights])
		_check(inst <= 16, "draw instances <= 16 (got %d)" % inst)
		_check(verts <= 6000, "vertices <= 6000 (got %d)" % verts)
		_check(lights == 0, "0 lights")
	for n: String in ["Root/Body/BodyMesh", "Root/Body/Neck1/Neck2/Head/HeadMesh", "Root/Body/WingR/WingR2/WingR2Mesh",
			"Root/Body/WingL/WingLMesh", "Root/Body/Tail1/Tail1Mesh", "Root/Body/LegFR/LegFRMesh", "Fx/Feathers", "Shadow"]:
		_check(a.get_node_or_null(n) != null and b.get_node_or_null(n) != null, "part %s on every instance" % n)
	for g: Node in a.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		print("  %s (%s): %d vertices, shadow %d" % [a.get_path_to(g), g.get_class(), _vertices_of(gi), gi.cast_shadow])
	# ---- materials: A storm, B dusk, all in the own folder
	var ma := _materials(a)
	var mb := _materials(b)
	print("A materials: ", _names(ma))
	print("B materials: ", _names(mb))
	_check(ma.size() == 3 and mb.size() == 3, "3 materials per variant (feather, horn, eye)")
	for mat: Material in ma + mb:
		_check(mat.resource_path.begins_with(OWN_DIR), "own material only (%s)" % mat.resource_path)
	for mat: Material in ma:
		_check(mat.resource_path.get_file().begins_with("roc_storm_"), "A wears the Stormcrest set (%s)" % mat.resource_path.get_file())
	for mat: Material in mb:
		_check(mat.resource_path.get_file().begins_with("roc_dusk_"), "B wears the Duskwing set (%s)" % mat.resource_path.get_file())
	var sf: ShaderMaterial = load(OWN_DIR + "materials/roc_storm_feather.tres")
	var df: ShaderMaterial = load(OWN_DIR + "materials/roc_dusk_feather.tres")
	var sc: Color = sf.get_shader_parameter(&"base_color")
	var dc: Color = df.get_shader_parameter(&"base_color")
	var dsh: Color = df.get_shader_parameter(&"sheen_color")
	print("storm %s (h %.2f s %.2f v %.2f), dusk %s (v %.2f), dusk sheen %s x %.2f" % [sc, sc.h, sc.s, sc.v, dc, dc.v, dsh,
		float(df.get_shader_parameter(&"sheen_strength"))])
	_check(sc.b > sc.r + 0.25 and sc.s > 0.45 and sc.v > 0.45, "Stormcrest plumage storm-blue")
	_check(dc.v < 0.1, "Duskwing plumage near-black")
	_check(dsh.b > dsh.g + 0.4 and dsh.r > dsh.g + 0.15 and float(df.get_shader_parameter(&"sheen_strength")) >= 0.6,
		"Duskwing violet sheen")
	var se: ShaderMaterial = load(OWN_DIR + "materials/roc_storm_eye.tres")
	var de: ShaderMaterial = load(OWN_DIR + "materials/roc_dusk_eye.tres")
	var dec: Color = de.get_shader_parameter(&"glow_color")
	_check(se.shader.resource_path.ends_with("unit_glow.gdshader") and de.shader.resource_path.ends_with("unit_glow.gdshader"),
		"eyes use unit_glow (glow_boost slot 5)")
	_check(dec.r > 0.9 and dec.g < 0.3 and float(de.get_shader_parameter(&"energy")) >= 2.5, "Duskwing red eye glow >= 2.5")
	# ---- set_variant swaps both ways (a: 0 -> 1 -> 0)
	a.call(&"set_variant", 1)
	var swapped := _materials(a)
	_check(_names(swapped) == _names(mb), "set_variant(1) swaps every surface to the Duskwing set")
	var fe: GPUParticles3D = a.get_node("Fx/Feathers")
	var pm_b: Material = fe.process_material
	a.call(&"set_variant", 0)
	_check(_names(_materials(a)) == _names(ma), "set_variant(0) swaps back")
	_check(fe.process_material != pm_b, "the feather burst colour follows the variant")
	# ---- team colour: none
	var before := _materials(b)
	b.call(&"set_team_color", Color(0.85, 0.30, 0.12))
	await process_frame
	_check(_names(_materials(b)) == _names(before), "set_team_color is a no-op (neutral)")
	# ---- hooks
	for m: Node3D in [a, b]:
		for h: String in ["set_team_color", "set_moving", "play_attack", "play_cast", "play_hit", "play_death",
				"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "set_variant",
				"get_variant"]:
			_check(m.has_method(h), "hook %s" % h)
		_check(m.has_signal(&"death_finished"), "signal death_finished")
	_check(float(a.get(&"attack_windup")) == 0.0, "melee: attack_windup 0")
	# ---- size and the glide height (idle, 2 s)
	var root_n: Node3D = a.get_node("Root")
	var body: Node3D = a.get_node("Root/Body")
	var wing: Node3D = a.get_node("Root/Body/WingR")
	var leg: Node3D = a.get_node("Root/Body/LegFR")
	var jaw: Node3D = a.get_node("Root/Body/Neck1/Neck2/Head/Jaw")
	var shadow: Node3D = a.get_node("Shadow")
	# Span / length: the widest AABB over the idle window (the wings pass level every beat and in the hover-glide; a
	# single frame can catch them at the top of a beat, and the beat phase comes from the instance id).
	var span := 0.0
	var length := 0.0
	var alt_min := INF
	var alt_max := -INF
	var low_min := INF
	var wmin := INF
	var wmax := -INF
	var glided := false
	for i: int in 240:
		await process_frame
		var alt := float(a.call(&"body_altitude"))
		alt_min = minf(alt_min, alt)
		alt_max = maxf(alt_max, alt)
		if i % 20 == 0:
			low_min = minf(low_min, _lowest_vertex(a))
		if i % 4 == 0:
			var box := _aabb(a)
			span = maxf(span, box.size.x)
			length = maxf(length, box.size.z)
		wmin = minf(wmin, wing.rotation.z)
		wmax = maxf(wmax, wing.rotation.z)
		glided = glided or bool(a.get(&"_gliding"))
	print("idle: body %.2f .. %.2f m, lowest %.2f m, wing roll %.1f .. %.1f deg, glided %s, blob y %.3f" % [alt_min,
		alt_max, low_min, rad_to_deg(wmin), rad_to_deg(wmax), glided, shadow.position.y])
	print("widest idle AABB: span %.2f m, length %.2f m" % [span, length])
	_check(span >= 6.0 and span <= 7.4, "wingspan 6-7.4 m (got %.2f)" % span)
	_check(length >= 3.0 and length <= 4.2, "length 3-4.2 m (got %.2f)" % length)
	_check(alt_min > 2.2 and alt_max < 2.8, "glides low: body centre ~2.5 m (%.2f .. %.2f)" % [alt_min, alt_max])
	_check(low_min > 1.2, "nothing below 1.2 m while gliding (%.2f)" % low_min)
	_check(wmax - wmin > deg_to_rad(20.0), "the wings beat (%.1f deg)" % rad_to_deg(wmax - wmin))
	_check(glided, "idle: beats then hangs on spread wings")
	_check(absf(shadow.position.y - 0.02) < 0.01 and Vector2(shadow.position.x, shadow.position.z).length() < 0.05,
		"ground blob on the ground under the body")
	# ---- moving + turning: banks
	a.call(&"set_moving", 6.5)
	var holder: Node3D = a.get_parent()
	var bank := 0.0
	for i: int in 90:
		holder.rotation.y += deg_to_rad(1.6)
		await process_frame
		bank = maxf(bank, absf(body.rotation.z))
	print("turning: bank %.1f deg" % rad_to_deg(bank))
	_check(bank > deg_to_rad(10.0), "banks into turns (%.1f deg)" % rad_to_deg(bank))
	a.call(&"set_moving", 0.0)
	await _wait(0.8)
	# ---- attack: drop + talons forward at the strike
	var s0: int = int(a.call(&"strike_count"))
	var y_rest: float = float(a.call(&"body_altitude"))
	a.call(&"play_attack")
	await _until_t(a, 0.2)
	var y_hit: float = float(a.call(&"body_altitude"))
	var foot := leg.transform.basis * Vector3(0.0, -0.42, -0.52)   # hip -> ankle, authored tucked back
	print("attack: body %.2f -> %.2f, hip -> ankle %s" % [y_rest, y_hit, foot])
	_check(y_hit < y_rest - 0.3, "attack: drops onto the target")
	_check(foot.z > 0.3, "attack: talons thrown forward (ankle z %.2f)" % foot.z)
	_check(int(a.call(&"strike_count")) == s0 + 1, "one strike per attack")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "attack finished")
	# ---- gale swoop
	var bursts0: int = int(a.call(&"burst_count"))
	a.call(&"play_cast", &"gale_swoop")
	await _until_t(a, 0.14)
	var y_up: float = float(a.call(&"body_altitude"))
	await _until_t(a, 0.47)
	var y_dive: float = float(a.call(&"body_altitude"))
	await _until_t(a, 0.56)
	print("gale swoop: up %.2f, dive %.2f, swoops %d, bursts %d -> %d" % [y_up, y_dive, int(a.call(&"swoop_count")),
		bursts0, int(a.call(&"burst_count"))])
	_check(y_up > 2.9, "swoop: beats up first (%.2f)" % y_up)
	_check(y_dive < 1.7, "swoop: dives low onto the target (%.2f)" % y_dive)
	_check(int(a.call(&"swoop_count")) == 1 and int(a.call(&"burst_count")) == bursts0 + 1, "swoop: one impact burst")
	await _wait(0.9)
	_check(a.get(&"_action") == &"", "swoop finished")
	# ---- shrieking dive (b): beak wide, red eyes flare
	await _wait(0.3)
	var bjaw: Node3D = b.get_node("Root/Body/Neck1/Neck2/Head/Jaw")
	var g_rest: float = float(b.call(&"eye_glow"))
	b.call(&"play_cast", &"shrieking_dive")
	await _until_t(b, 0.47)
	var g_sh: float = float(b.call(&"eye_glow"))
	print("shriek: jaw %.1f deg, eye glow %.2f -> %.2f" % [rad_to_deg(bjaw.rotation.x), g_rest, g_sh])
	_check(bjaw.rotation.x > deg_to_rad(30.0), "shriek: beak wide open")
	_check(g_rest > 0.5 and g_sh > g_rest * 1.8, "shriek: the red eyes flare")
	await _wait(1.0)
	# ---- updraft: climbs, holds while shrouded, comes back down; the blob shrinks
	var blob_rest := shadow.scale.x
	a.call(&"play_cast", &"updraft")
	_check(bool(a.call(&"set_status", &"shroud", true)), "set_status shroud handled by the model")
	await _wait(2.0)
	var hi := float(a.call(&"altitude"))
	var blob_hi := shadow.scale.x
	await _wait(3.0)
	var still := float(a.call(&"altitude"))
	a.call(&"set_status", &"shroud", false)
	await _wait(2.6)
	var back := float(a.call(&"altitude"))
	print("updraft: %.2f after 2 s, %.2f after 5 s (shrouded), %.2f 2.6 s after; blob %.2f -> %.2f; count %d" % [hi,
		still, back, blob_rest, blob_hi, int(a.call(&"updraft_count"))])
	_check(hi > 2.0, "updraft climbs > 2 m")
	_check(still > 2.0, "updraft holds while shrouded")
	_check(back < 0.3, "back down after the shroud")
	_check(blob_hi < blob_rest * 0.85, "the blob shrinks while it climbs")
	_check(int(a.call(&"updraft_count")) == 1, "one updraft")
	# ---- hit, statuses, kit no-ops
	var bm: GeometryInstance3D = a.get_node("Root/Body/BodyMesh")
	a.call(&"play_hit")
	await _wait(0.05)
	_check(float(bm.get_instance_shader_parameter(&"hit_flash")) > 0.1, "hit flash on the body")
	a.call(&"play_level_up")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	_check(not bool(a.call(&"set_status", &"rooted", true)), "set_status rooted left to the placeholder")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_veterancy", 2)
	a.call(&"set_carrying", true)
	a.call(&"play_mine")
	await _wait(0.4)
	a.call(&"set_veterancy", 0)
	# ---- death mid-attack + revive
	a.call(&"play_attack")
	await _wait(0.1)
	var got: Array = [false, 0.0]
	var on_done := func() -> void:
		got[0] = true
		got[1] = float(a.get(&"_death_t"))
	a.connect(&"death_finished", on_done, CONNECT_ONE_SHOT)
	a.call(&"play_death")
	await _until_death(a, 1.15)
	var low := _lowest_vertex(a)
	var dalt := float(a.call(&"body_altitude"))
	for g: Node in a.find_children("*", "MeshInstance3D", true, false):
		if g.name != "Shadow":
			print("  lowest %s %.3f" % [g.name, _lowest_vertex_of(a, g as MeshInstance3D)])
	print("death 1.15 s: body %.2f m, lowest %.3f, eyes %.2f, bursts %d" % [dalt, low, float(a.call(&"eye_glow")),
		int(a.call(&"burst_count"))])
	_check(dalt < 0.8, "fell to the ground (%.2f)" % dalt)
	_check(low > -0.15 and low < 0.35, "lying on the ground, not through it (lowest %.3f)" % low)
	_check(float(a.call(&"eye_glow")) == 0.0, "eyes dark once dead")
	await _wait(1.0)
	print("death_finished at %.2f s" % float(got[1]))
	_check(got[0], "death_finished emitted")
	_check(float(got[1]) < 1.95, "death shorter than Unit's 2.0 s fallback (%.2f)" % float(got[1]))
	a.call(&"revive")
	await _wait(0.4)
	var ralt := float(a.call(&"body_altitude"))
	print("revived: body %.2f, eyes %.2f" % [ralt, float(a.call(&"eye_glow"))])
	_check(ralt > 2.2 and ralt < 2.8, "revive: back in the air")
	_check(absf(root_n.rotation.y) < 0.05 and absf(body.rotation.z) < 0.2, "revive resets the pose")
	_check(float(a.call(&"eye_glow")) > 0.5, "revive: eyes glow again")
	_check(jaw.rotation.x < deg_to_rad(10.0), "revive: beak closed")
	# ---- transparency (Unit.leave_map fade) is tolerated on every part
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## Waits (max 1.5 s) until the model's action clock reaches t (headless: no camera, tier 1, half rate).
func _until_t(m: Node, t: float) -> void:
	for i: int in 90:
		if float(m.get(&"_action_t")) >= t:
			return
		await process_frame


func _until_death(m: Node, t: float) -> void:
	for i: int in 150:
		if float(m.get(&"_death_t")) >= t:
			return
		await process_frame


func _lowest_vertex_of(model: Node3D, mi: MeshInstance3D) -> float:
	var xf := model.global_transform.affine_inverse() * mi.global_transform
	var low := INF
	for s: int in mi.mesh.get_surface_count():
		for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			low = minf(low, (xf * v).y)
	return low


## Lowest vertex (model space) of every mesh but the ground blob.
func _lowest_vertex(model: Node3D) -> float:
	var inv := model.global_transform.affine_inverse()
	var low := INF
	for g: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				low = minf(low, (xf * v).y)
	return low


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _vertices_of(gi: GeometryInstance3D) -> int:
	var c := 0
	if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
		var mesh := (gi as MeshInstance3D).mesh
		for s: int in mesh.get_surface_count():
			c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


func _vertices(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		c += _vertices_of(g as GeometryInstance3D)
	return c


func _triangles(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (g as MeshInstance3D).mesh
		if mesh:
			for s: int in mesh.get_surface_count():
				c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return c


## Unique materials on the model's meshes (surface overrides > material_override > mesh surfaces); the blob skipped.
func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if mi.material_override:
			if not (mi.material_override in out):
				out.append(mi.material_override)
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


func _names(mats: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for m: Material in mats:
		out.append(m.resource_path.get_file())
	out.sort()
	return out


## AABB of every mesh but the blob, in the model's frame.
func _aabb(model: Node3D) -> AABB:
	var inv := model.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for g: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var bx := (inv * mi.global_transform) * mi.mesh.get_aabb()
		box = bx if first else box.merge(bx)
		first = false
	return box
