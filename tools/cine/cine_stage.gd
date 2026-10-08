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
## Multi-set movies (per-shot `set=`, e.g. the prologue): every set referenced is loaded at the origin, one shown at a
## time (`set_active_set`, the runtime's context API). set id -> {node, path, lighting, marks, mark_fov}; a missing set
## has no entry (its shots get the proxy camera + the fallback env).
var sets: Dictionary = {}
var set_order: Array[String] = []
var multi := false
var actor_set: Dictionary = {}     # tag -> set id of a set puppet ("" = cine cast / prop: every set)
var active_set := "-"
var rig: Node3D = null             # LightingRig (multi-set): the active set's LightingPreset
var _fallback_env: Array[Node] = []   # cine env nodes (shown for shots whose set is missing)
var _fallback_preset: Resource = null


## Builds everything under this node. Safe headless (no pixels needed: positions, heads, markers, methods).
func build(p_doc: CineDoc, p_animatic: bool = false) -> void:
	doc = p_doc
	animatic = p_animatic
	name = "CineStage_" + doc.id
	var ids: Array[String] = []
	if doc.set_id != "":
		ids.append(doc.set_id)
	for s: Dictionary in doc.shots:
		var sid := String((s["kv"] as Dictionary).get("set", ""))
		if sid != "" and not sid in ids:
			ids.append(sid)
	multi = ids.size() > 1
	if multi:
		for id: String in ids:
			_load_one_set(id, doc.set_line if id == doc.set_id else _first_shot_line(id))
		if sets.has(doc.set_id):
			set_node = sets[doc.set_id]["node"]
			set_path = sets[doc.set_id]["path"]
			set_found = true
		_build_env()
		for n: Node in get_children():
			if n.name in ["Env", "Moon", "Ground"]:
				_fallback_env.append(n)
		_setup_rig()
	else:
		_load_set()
		if not _set_has_env():
			_build_env()
	for p: Dictionary in doc.props:
		_add_prop(p)
	for tag: String in doc.cast_order:
		_add_cast(doc.cast[tag])
	var set_list: Array = [[doc.set_id, set_node]] if not multi else []
	for id2: String in set_order:
		set_list.append([id2, sets[id2]["node"]])
	for pair: Array in set_list:
		var sn: Node3D = pair[1]
		if sn == null:
			continue
		var puppets := sn.get_node_or_null(^"Puppets")
		if puppets != null:
			for p2: Node in puppets.get_children():
				var tag2 := String(p2.name).to_lower()
				if p2 is Node3D and actors.has(tag2) and multi:
					tag2 = String(pair[0]).trim_prefix("forge_").trim_prefix("intro_") + "_" + tag2
				if p2 is Node3D and not actors.has(tag2):
					actor_set[tag2] = String(pair[0]) if multi else ""
					_register(tag2, p2 as Node3D, (p2 as Node3D).global_position, rad_to_deg((p2 as Node3D).global_rotation.y), true)
	for l: Light3D in find_children("*", "Light3D", true, false):
		if l.visible:
			light_count += 1
	if multi:
		set_active_set(StringName(doc.set_id if doc.set_id != "" else (ids[0] if not ids.is_empty() else "")))


func _first_shot_line(id: String) -> ToolSpecLine:
	for s: Dictionary in doc.shots:
		if String((s["kv"] as Dictionary).get("set", "")) == id:
			return s["line"]
	return doc.set_line


func has_set(id: String) -> bool:
	return sets.has(id) if multi else (id == doc.set_id and set_found)


## Markers of one set (multi-set) or the merged markers.
func marks_of(id: String) -> Dictionary:
	if multi and sets.has(id):
		return sets[id]["marks"]
	return set_marks


## The subject a set's marks keep in frame for a shot (marks.json "subject"), "" if none.
func subject_of(id: String, shot: String) -> String:
	if multi and sets.has(id):
		return String((sets[id].get("subjects", {}) as Dictionary).get(shot, ""))
	return ""


func mark_fov_of(id: String) -> Dictionary:
	if multi and sets.has(id):
		return sets[id]["mark_fov"]
	return set_mark_fov


## Runtime context API (CinematicPlayer._find_set / _switch_set) + cine's own preview.
func find_set(id: StringName) -> Node:
	if multi:
		return (sets.get(String(id), {}) as Dictionary).get("node", null)
	return set_node if String(id) == doc.set_id else null


func set_active_set(id: StringName) -> void:
	if not multi or String(id) == active_set:
		return
	active_set = String(id)
	for sid: String in sets:
		var n: Node3D = sets[sid]["node"]
		var on := sid == active_set
		if animatic:
			var px: Node = sets[sid].get("proxy", null)
			if px != null:
				(px as Node3D).visible = on
			n.visible = false
			n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		elif n.has_method(&"set_active"):
			n.call(&"set_active", on)
		else:
			n.visible = on
	var found := sets.has(active_set)
	for e: Node in _fallback_env:
		if e is Node3D:
			(e as Node3D).visible = not found
	if rig != null and rig.is_inside_tree():
		var lp: Resource = sets[active_set]["lighting"] if found and sets[active_set]["lighting"] != null else _fallback_preset
		rig.call(&"apply", lp)


func _setup_rig() -> void:
	if not ResourceLoader.exists("res://art/environment/lighting/lighting_rig.gd"):
		return
	var rs: Script = load("res://art/environment/lighting/lighting_rig.gd")
	var ps: Script = load("res://art/environment/lighting/lighting_preset.gd")
	if rs == null or ps == null:
		return
	# the fallback preset = the cine env (shots whose set is not built yet)
	_fallback_preset = ps.new()
	for e: Node in _fallback_env:
		if e is WorldEnvironment:
			_fallback_preset.set(&"environment", (e as WorldEnvironment).environment)
		elif e is DirectionalLight3D:
			_fallback_preset.set(&"sun_color", (e as DirectionalLight3D).light_color)
			_fallback_preset.set(&"sun_energy", (e as DirectionalLight3D).light_energy)
			_fallback_preset.set(&"sun_rotation_degrees", (e as DirectionalLight3D).rotation_degrees)
	_fallback_preset.set(&"vignette_strength", 0.0)
	# only the rig's environment and sun: the cine env's own WorldEnvironment / moon go away
	for e2: Node in _fallback_env.duplicate():
		if e2 is WorldEnvironment or e2 is DirectionalLight3D:
			_fallback_env.erase(e2)
			remove_child(e2)
			e2.free()
	rig = rs.new() as Node3D
	rig.set(&"preset", _fallback_preset)
	add_child(rig)


func _load_one_set(id: String, line: ToolSpecLine) -> void:
	var dir := SET_DIR + id
	var path := ""
	for cand: String in [dir.path_join(id + ".tscn"), dir.path_join("set.tscn"), dir.path_join(id + "_set.tscn")]:
		if ResourceLoader.exists(cand):
			path = cand
			break
	if path == "":
		problems.append({"status": "WARN", "name": "set " + id, "value": "not built yet (" + dir + ")",
			"hint": "its shots use the proxy camera + grey boxes until World Forge builds it", "line": line})
		return
	var ps := load(path) as PackedScene
	var inst: Node = ps.instantiate() if ps != null else null
	if not inst is Node3D:
		if inst != null:
			inst.free()
		problems.append({"status": "FAIL", "name": "set " + id, "value": "does not load: " + path, "hint": "rebuild the set", "line": line})
		return
	var n := inst as Node3D
	var e := {"node": n, "path": path, "lighting": n.get(&"lighting"), "marks": {}, "mark_fov": {}}
	add_child(n)
	if animatic:
		var proxy := Node3D.new()
		proxy.name = "SetProxy_" + id
		add_child(proxy)
		_boxes_of(n, proxy, true)
		e["proxy"] = proxy
	var shots_node := n.get_node_or_null(^"Shots")
	if shots_node != null:
		for m: Node in shots_node.get_children():
			if m is Node3D:
				e["marks"][String(m.name)] = (m as Node3D).global_position
				if m.has_meta(&"fov"):
					e["mark_fov"][String(m.name)] = float(m.get_meta(&"fov"))
	var mj := path.get_base_dir().path_join("marks.json")
	if FileAccess.file_exists(mj):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(mj))
		if data is Dictionary:
			for shot: String in data:
				var ed: Variant = data[shot]
				if not ed is Dictionary:
					continue
				for k: String in ["from", "to", "look_from", "look_to", "pivot"]:
					var v: Variant = (ed as Dictionary).get(k, null)
					if v is Array and (v as Array).size() == 3 and not e["marks"].has(shot + "_" + k):
						e["marks"][shot + "_" + k] = n.global_transform * Vector3(float(v[0]), float(v[1]), float(v[2]))
				if String((ed as Dictionary).get("subject", "")) != "":
					if not e.has("subjects"):
						e["subjects"] = {}
					e["subjects"][shot] = String(ed["subject"]).to_lower()
				if (ed as Dictionary).has("fov_from") and not e["mark_fov"].has(shot + "_from"):
					e["mark_fov"][shot + "_from"] = float(ed["fov_from"])
				if (ed as Dictionary).has("fov_to") and not e["mark_fov"].has(shot + "_to"):
					e["mark_fov"][shot + "_to"] = float(ed["fov_to"])
	for k2: String in e["marks"]:
		if not set_marks.has(k2):
			set_marks[k2] = e["marks"][k2]
	for k3: String in e["mark_fov"]:
		if not set_mark_fov.has(k3):
			set_mark_fov[k3] = e["mark_fov"][k3]
	sets[id] = e
	set_order.append(id)


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
	# `set=<id>`: the prop belongs to that set (shown / hidden with it); a set not built yet = no prop
	var owner_set := String(p.get("set", ""))
	if owner_set != "" and multi and not sets.has(owner_set):
		return
	var inst := (load(scene_path) as PackedScene).instantiate() as Node3D
	if inst == null:
		return
	inst.name = String(p["name"])
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(p["yaw"]))).scaled(Vector3.ONE * float(p["scale"])), p["pos"])
	if owner_set != "" and multi and not animatic:
		(sets[owner_set]["node"] as Node3D).add_child(inst)
		inst.global_transform = xf
		return
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
	var owner_set := String(c.get("set", ""))
	if owner_set != "" and multi:
		actor_set[tag] = owner_set
	var parent: Node = self
	if owner_set != "" and multi and sets.has(owner_set) and not animatic:
		parent = sets[owner_set]["node"]
	if node != null:
		node.name = tag.capitalize().replace(" ", "")
		parent.add_child(node)
		var sc := float(c.get("scale", 1.0))
		if sc != 1.0:
			node.scale = Vector3.ONE * sc
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


## Height of the face above the model origin. A character-kit model with a FaceKit face (FaceRig) gives its exact
## anchor (face_anchor). Else the centre of the meshes under its `Head` node (the Head pivot itself is the neck), else
## Head + 0.15 m, else DEFAULT_HEAD. Hats taller than 0.45 m above the pivot are ignored.
## 2026-10-08: the FaceRig mesh (face + hair + beard in one surface) used to be averaged with the Head meshes: beards
## and long hair pulled the result 0.2-0.4 m under the eyes (Torvald 1.60, Vessa 1.88), so the framer and
## look=<actor> shots aimed at the chest.
static func face_height(node: Node3D) -> float:
	if not node.is_inside_tree():
		return DEFAULT_HEAD
	var anchor := face_anchor(node)
	if anchor != Vector3.INF:
		return anchor.y - node.global_position.y
	var h := node.find_child("Head", true, false) as Node3D
	if h == null:
		return DEFAULT_HEAD
	var pivot := h.global_position.y - node.global_position.y
	var lo := INF
	var hi := -INF
	for mi: Node in h.find_children("*", "MeshInstance3D", true, false):
		if mi is FaceRig:
			continue
		var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		lo = minf(lo, a.position.y)
		hi = minf(maxf(hi, a.end.y), h.global_position.y + 0.45)
	if lo == INF:
		return pivot + 0.15
	return clampf((lo + hi) * 0.5 - node.global_position.y, pivot, pivot + 0.35)


## World position of the model's face centre from its FaceKit face: the style's model-space centre (`canvas.c`, the
## head sphere's centre) through the FaceRig's transform (the rig sits at the model origin, so the model's scale and
## pose count). The rig under the `Head` node wins (a mounted rider's horse may have its own). Vector3.INF = none.
static func face_anchor(node: Node3D) -> Vector3:
	var best: FaceRig = null
	for mi: Node in node.find_children("*", "MeshInstance3D", true, false):
		if not mi is FaceRig:
			continue
		var st: Variant = mi.get("_style")
		if not (st is Dictionary and (st as Dictionary).get("canvas") is Dictionary):
			continue
		if best == null or String(mi.get_parent().name) == "Head":
			best = mi as FaceRig
			if String(mi.get_parent().name) == "Head":
				break
	if best == null:
		return Vector3.INF
	var c: Variant = ((best.get("_style") as Dictionary)["canvas"] as Dictionary).get("c")
	if not c is Vector3:
		return Vector3.INF
	return best.global_transform * (c as Vector3)


func _register(tag: String, node: Node3D, pos: Vector3, yaw: float, vis: bool, head: float = -1.0) -> void:
	if head < 0.0:
		head = face_height(node)
	actors[tag] = node
	actor_start[tag] = {"pos": pos, "yaw": yaw, "head": head, "visible": vis}
	if String(actor_set.get(tag, "")) != "":
		actor_start[tag]["set"] = String(actor_set[tag])
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
