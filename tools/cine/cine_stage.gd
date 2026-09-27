class_name CineStage
extends Node3D
## The stage a `.cine` plays on, built in code from the doc: a tool 6 set (`use set <id>`, set contract of prologue 2.3)
## and / or the doc's own `prop` / `cast` / `env` lines. Animatic mode swaps every model for a grey proxy (capsules named
## after the actors, boxes for props and sets) so a movie can be judged before any art exists.
## Also the runtime `context`: `cinematic_actor(tag)` / `puppet(tag)` (cinematics.md 11, prologue 2.3).

const SET_DIR := "res://art/cinematics/stage_sets/"
const DEFAULT_HEAD := 1.6

var doc: CineDoc
var animatic := false
var set_node: Node3D = null
var set_path: String = ""
var set_found := false
var actors: Dictionary = {}        # tag -> Node3D (puppet root)
var actor_start: Dictionary = {}   # tag -> {pos: Vector3, yaw: float, head: float, visible: bool}
var set_marks: Dictionary = {}     # marker name -> Vector3 (set Shots markers + marks.json)
var set_mark_fov: Dictionary = {}
var problems: Array[Dictionary] = []   # {status, name, value, hint, line}
var light_count := 0


## Builds everything under this node. Safe headless (no pixels needed: positions, heads, markers, methods).
func build(p_doc: CineDoc, p_animatic: bool = false) -> void:
	doc = p_doc
	animatic = p_animatic
	name = "CineStage_" + doc.id
	_load_set()
	if not _set_has_env():
		_build_env()
	for p: Dictionary in doc.props:
		_add_prop(p)
	for tag: String in doc.cast_order:
		_add_cast(doc.cast[tag])
	if set_node != null:
		var puppets := set_node.get_node_or_null(^"Puppets")
		if puppets != null:
			for p2: Node in puppets.get_children():
				var tag2 := String(p2.name).to_lower()
				if p2 is Node3D and not actors.has(tag2):
					_register(tag2, p2 as Node3D, (p2 as Node3D).global_position, rad_to_deg((p2 as Node3D).global_rotation.y), true)
	for l: Light3D in find_children("*", "Light3D", true, false):
		if l.visible:
			light_count += 1


func actor_tags() -> Array[String]:
	var out: Array[String] = []
	for k: String in actors:
		out.append(k)
	out.sort()
	return out


## Runtime context API (cinematics.md 11): the actor node for a tag.
func cinematic_actor(tag: StringName) -> Node3D:
	return actors.get(String(tag).to_lower(), null)


func puppet(tag: StringName) -> Node3D:
	return cinematic_actor(tag)


## Sets an actor's pose (used by cine's own preview player and the stills).
func pose_actor(tag: String, pos: Vector3, yaw_deg: float, visible_on: bool) -> void:
	var n: Node3D = actors.get(tag, null)
	if n == null:
		return
	n.global_position = pos
	n.global_rotation = Vector3(0.0, deg_to_rad(yaw_deg), 0.0)
	n.visible = visible_on


# ---------------------------------------------------------------- set

func _load_set() -> void:
	if doc.set_id == "":
		return
	var dir := SET_DIR + doc.set_id
	for cand: String in [dir.path_join(doc.set_id + ".tscn"), dir.path_join("set.tscn"), dir.path_join(doc.set_id + "_set.tscn")]:
		if ResourceLoader.exists(cand):
			set_path = cand
			break
	if set_path == "":
		var known: Array = []
		var d := DirAccess.open(SET_DIR)
		if d != null:
			for sub: String in d.get_directories():
				known.append(sub)
		var n := ToolSpec.nearest(doc.set_id, known)
		problems.append({"status": "WARN", "name": "set " + doc.set_id, "value": "not found in " + dir,
			"hint": ("did you mean \"%s\"? " % n if n != "" else "") + "build it with World Forge (tool 6); animatic boxes are used meanwhile",
			"line": doc.set_line})
		return
	var ps := load(set_path) as PackedScene
	if ps == null:
		problems.append({"status": "FAIL", "name": "set " + doc.set_id, "value": "does not load: " + set_path,
			"hint": "rebuild the set", "line": doc.set_line})
		return
	var inst := ps.instantiate()
	if not inst is Node3D:
		inst.free()
		return
	set_found = true
	set_node = inst as Node3D
	if animatic:
		var proxy := Node3D.new()
		proxy.name = "SetProxy"
		add_child(proxy)
		add_child(set_node)
		_boxes_of(set_node, proxy, true)
		set_node.visible = false
	else:
		add_child(set_node)
	if set_node.has_method(&"set_active"):
		set_node.call(&"set_active", true)
	var shots_node := set_node.get_node_or_null(^"Shots")
	if shots_node != null:
		for m: Node in shots_node.get_children():
			if m is Node3D:
				set_marks[String(m.name)] = (m as Node3D).global_position
				if m.has_meta(&"fov"):
					set_mark_fov[String(m.name)] = float(m.get_meta(&"fov"))
	var mj := set_path.get_base_dir().path_join("marks.json")
	if FileAccess.file_exists(mj):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(mj))
		if data is Dictionary:
			for shot: String in data:
				var e: Variant = data[shot]
				if not e is Dictionary:
					continue
				for k: String in ["from", "to", "look_from", "look_to", "pivot"]:
					var v: Variant = (e as Dictionary).get(k, null)
					if v is Array and (v as Array).size() == 3 and not set_marks.has(shot + "_" + k):
						set_marks[shot + "_" + k] = set_node.global_transform * Vector3(float(v[0]), float(v[1]), float(v[2]))
				if (e as Dictionary).has("fov_from"):
					set_mark_fov[shot + "_from"] = float(e["fov_from"])
				if (e as Dictionary).has("fov_to"):
					set_mark_fov[shot + "_to"] = float(e["fov_to"])


func _set_has_env() -> bool:
	return set_node != null and not set_node.find_children("*", "WorldEnvironment", true, false).is_empty()


# ---------------------------------------------------------------- env

func _build_env() -> void:
	var preset: String = doc.env.get("preset", "night")
	if preset == "none":
		return
	var we := WorldEnvironment.new()
	we.name = "Env"
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	var tops := {"night": Color(0.05, 0.07, 0.16), "dusk": Color(0.16, 0.14, 0.3), "day": Color(0.35, 0.5, 0.8)}
	var hors := {"night": Color(0.28, 0.2, 0.3), "dusk": Color(0.75, 0.4, 0.28), "day": Color(0.7, 0.75, 0.8)}
	sm.sky_top_color = tops.get(preset, tops["night"])
	sm.sky_horizon_color = hors.get(preset, hors["night"])
	sm.ground_bottom_color = Color(0.03, 0.03, 0.04)
	sm.ground_horizon_color = hors.get(preset, hors["night"]).darkened(0.4)
	sm.sun_angle_max = 8.0
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.55 if preset == "night" else 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = hors.get(preset, hors["night"]).darkened(0.3)
	e.fog_density = 0.008
	e.glow_enabled = true
	e.glow_intensity = 0.6
	we.environment = e
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = doc.env.get("color", Color(0.62, 0.7, 1.0))
	moon.light_energy = float(doc.env.get("energy", 0.6))
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(float(doc.env.get("moon_pitch", -38.0)), float(doc.env.get("moon_yaw", 35.0)), 0.0)
	add_child(moon)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.13, 0.11, 0.1) if preset != "day" else Color(0.3, 0.33, 0.22)
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)


# ---------------------------------------------------------------- props / cast

func _add_prop(p: Dictionary) -> void:
	var scene_path: String = p["scene"]
	if not ResourceLoader.exists(scene_path):
		problems.append({"status": "FAIL", "name": "prop " + String(p["name"]), "value": "missing scene " + scene_path,
			"hint": "fix the res:// path", "line": p["line"]})
		return
	var inst := (load(scene_path) as PackedScene).instantiate() as Node3D
	if inst == null:
		return
	inst.name = String(p["name"])
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(p["yaw"]))).scaled(Vector3.ONE * float(p["scale"])), p["pos"])
	if animatic:
		var holder := Node3D.new()
		holder.name = String(p["name"]) + "_proxy"
		add_child(holder)
		add_child(inst)
		inst.transform = xf
		_boxes_of(inst, holder, false)
		inst.queue_free()
	else:
		add_child(inst)
		inst.transform = xf


func _add_cast(c: Dictionary) -> void:
	var tag: String = c["tag"]
	var scene_path: String = c["scene"]
	var node: Node3D = null
	var head := DEFAULT_HEAD
	if scene_path != "capsule":
		if ResourceLoader.exists(scene_path):
			node = (load(scene_path) as PackedScene).instantiate() as Node3D
		else:
			problems.append({"status": "FAIL", "name": "cast " + tag, "value": "missing model " + scene_path,
				"hint": "fix the res:// path (or use `capsule` as a stand-in)", "line": c["line"]})
	if node != null:
		node.name = tag.capitalize().replace(" ", "")
		add_child(node)
		head = face_height(node)
		if animatic:
			var cap := _capsule(tag, head)
			node.queue_free()
			node = cap
			add_child(node)
	else:
		node = _capsule(tag, head)
		add_child(node)
	_register(tag, node, c["pos"], float(c["yaw"]), not bool(c["hidden"]), head)


## Height of the face above the model origin: the centre of the meshes under its `Head` node (the Head pivot itself is
## the neck), else Head + 0.15 m, else DEFAULT_HEAD. Hats taller than 0.45 m above the pivot are ignored.
static func face_height(node: Node3D) -> float:
	var h := node.find_child("Head", true, false) as Node3D
	if h == null or not node.is_inside_tree():
		return DEFAULT_HEAD
	var pivot := h.global_position.y - node.global_position.y
	var lo := INF
	var hi := -INF
	for mi: Node in h.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		lo = minf(lo, a.position.y)
		hi = minf(maxf(hi, a.end.y), h.global_position.y + 0.45)
	if lo == INF:
		return pivot + 0.15
	return clampf((lo + hi) * 0.5 - node.global_position.y, pivot, pivot + 0.35)


func _register(tag: String, node: Node3D, pos: Vector3, yaw: float, vis: bool, head: float = -1.0) -> void:
	if head < 0.0:
		head = face_height(node)
	actors[tag] = node
	actor_start[tag] = {"pos": pos, "yaw": yaw, "head": head, "visible": vis}
	pose_actor(tag, pos, yaw, vis)


## Grey capsule + name label + a nose showing where it faces (animatic proxy of an actor).
func _capsule(tag: String, head: float) -> Node3D:
	var root := Node3D.new()
	root.name = tag.capitalize().replace(" ", "")
	var h := maxf(1.0, head + 0.3)
	var m := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.32
	cm.height = h
	m.mesh = cm
	m.position.y = h * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.62, 0.64)
	m.material_override = mat
	root.add_child(m)
	var nose := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 0.3)
	nose.mesh = bm
	nose.position = Vector3(0, head, 0.33)
	var nm := StandardMaterial3D.new()
	nm.albedo_color = Color(0.9, 0.5, 0.2)
	nose.material_override = nm
	root.add_child(nose)
	var lab := Label3D.new()
	lab.text = tag.to_upper()
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 48
	lab.pixel_size = 0.006
	lab.position.y = h + 0.3
	lab.no_depth_test = true
	root.add_child(lab)
	return root


## Grey boxes for every mesh under `src` (per top-level child when `per_child`), added to `dst` in world space.
func _boxes_of(src: Node3D, dst: Node3D, per_child: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.45, 0.48)
	var groups: Array[Node] = []
	if per_child:
		for c: Node in src.get_children():
			if c is Node3D and not String(c.name) in ["Shots", "Puppets"]:
				groups.append(c)
	else:
		groups.append(src)
	for g: Node in groups:
		var box := AABB()
		var first := true
		var nodes: Array[Node] = [g]
		nodes.append_array(g.find_children("*", "VisualInstance3D", true, false))
		for vi: Node in nodes:
			if not vi is VisualInstance3D or vi is Light3D:
				continue
			var a: AABB = (vi as VisualInstance3D).global_transform * (vi as VisualInstance3D).get_aabb()
			if a.size.length() < 0.01:
				continue
			box = a if first else box.merge(a)
			first = false
		if first:
			continue
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = box.size
		mi.mesh = bm
		mi.material_override = mat
		dst.add_child(mi)
		mi.global_position = box.get_center()
