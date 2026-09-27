class_name LensStage
extends RefCounted
## Stages Lens subjects (model scenes, optional stage set), poses them, lights them and runs the ID passes used for the
## pixel metrics. Headless-safe except the captures (ToolCapture returns null headless).

const KINGDOM := {"fire": Color(0.85, 0.30, 0.12), "ice": Color(0.45, 0.75, 0.95), "nature": Color(0.35, 0.70, 0.25),
	"shadow": Color(0.50, 0.28, 0.70), "neutral": Color(0.62, 0.52, 0.34)}
const PRESETS := {"warm": "res://art/environment/lighting/preset_warm.tres", "ice": "res://art/environment/lighting/preset_ice.tres"}

var root: Node3D                       # everything Lens adds (lights, ground, models, set)
var models := {}                       # tag -> Node3D
var set_node: Node3D = null            # the stage set instance (bg set:<id>)
var env: Environment                   # beauty environment
var world_env: WorldEnvironment
var lights: Array[Light3D] = []
var _id_env: Environment
var _saved: Array = []


static func create(parent: Node) -> LensStage:
	var s := LensStage.new()
	s.root = Node3D.new()
	s.root.name = "LensStage"
	parent.add_child(s.root)
	s.world_env = WorldEnvironment.new()
	s.env = Environment.new()
	s.env.background_mode = Environment.BG_COLOR
	s.env.background_color = Color(0.1, 0.1, 0.12)
	s.env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	s.env.ambient_light_color = Color(0.45, 0.52, 0.70)
	s.env.ambient_light_energy = 0.6
	s.env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	s.env.tonemap_white = 6.0
	s.world_env.environment = s.env
	s.root.add_child(s.world_env)
	s._id_env = Environment.new()
	s._id_env.background_mode = Environment.BG_COLOR
	s._id_env.background_color = Color.BLACK
	s._id_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	s._id_env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	return s


## Instances a stage set (art/cinematics/stage_sets/<id>/<id>.tscn); its puppets become subjects by tag.
func add_set(set_id: String) -> bool:
	var p := LensDoc.set_scene_path(set_id)
	if not ResourceLoader.exists(p):
		return false
	set_node = (load(p) as PackedScene).instantiate() as Node3D
	root.add_child(set_node)
	var puppets := set_node.get_node_or_null(^"Puppets")
	if puppets:
		for c: Node in puppets.get_children():
			if c is Node3D:
				models[String(c.name).to_lower()] = c
	return true


## Adds subject models ({tag, res, at, yaw, scale}); a tag already given by the set is moved only when at= was written.
func add_subjects(subs: Array) -> void:
	for s: Dictionary in subs:
		var tag: String = s["tag"]
		if models.has(tag):
			continue
		var m := (load(String(s["res"])) as PackedScene).instantiate() as Node3D
		m.name = tag
		root.add_child(m)
		m.position = s["at"]
		m.rotation.y = deg_to_rad(float(s["yaw"]))
		var k := float(s.get("scale", 1.0))
		if k != 1.0:
			m.scale = Vector3.ONE * k
		models[tag] = m


## Stops every model's own animation (idle sway, flapping wings): stills and pixel refinement see one frozen pose.
func freeze() -> void:
	for m: Node in models.values():
		m.process_mode = Node.PROCESS_MODE_DISABLED


func hide_particles() -> void:
	for m: Node in models.values():
		for c: Node in m.find_children("*", "GPUParticles3D", true, false):
			(c as GPUParticles3D).visible = false
		for c2: Node in m.find_children("*", "CPUParticles3D", true, false):
			(c2 as CPUParticles3D).visible = false


## Lets spawn animations settle, then applies the poses (pose=<hook>:<arg>@<t>) and waits their time.
func settle_and_pose(tree: SceneTree, subs: Array, settle: float = 0.9) -> void:
	await tree.create_timer(settle).timeout
	var wait := 0.0
	for s: Dictionary in subs:
		var hook: String = s.get("pose", "")
		if hook == "" or not models.has(s["tag"]):
			continue
		var m: Node = models[s["tag"]]
		var target: Node = m if m.has_method(hook) else m.find_child("Model", true, false)
		if target == null or not target.has_method(hook):
			continue
		var arg: String = s.get("pose_arg", "")
		if arg != "":
			target.call(hook, StringName(arg))
		else:
			target.call(hook)
		wait = maxf(wait, float(s.get("pose_t", 0.0)))
	if wait > 0.0:
		await tree.create_timer(wait).timeout


## Like measure(), but the mean of `samples` measures `gap` frames apart (~4 s, a whole idle cycle), so two stagings
## solve the same camera (idle animations phase-shift with the frame parity). Posed subjects are measured once.
func measure_stable(tree: SceneTree, subs: Array, samples: int = 13, gap: int = 20) -> Dictionary:
	var acc := measure(subs)
	for s: Dictionary in subs:
		if String(s.get("pose", "")) != "":
			return acc
	for i: int in samples - 1:
		for f: int in gap:
			await tree.process_frame
		var m := measure(subs)
		for tag: String in m:
			var a: Dictionary = acc[tag]
			var n := float(i + 2)
			a["aabb"] = _mean(a["aabb"], m[tag]["aabb"], n)
			a["head"] = _mean(a["head"], m[tag]["head"], n)
			var hp: PackedVector3Array = a.get("head_pts", PackedVector3Array())
			var hp2: PackedVector3Array = m[tag].get("head_pts", PackedVector3Array())
			if hp.size() == hp2.size():
				for q: int in hp.size():
					hp[q] = hp[q] + (hp2[q] - hp[q]) / n
				a["head_pts"] = hp
			var bp: PackedVector3Array = a.get("body_pts", PackedVector3Array())
			var bp2: PackedVector3Array = m[tag].get("body_pts", PackedVector3Array())
			if bp.size() == bp2.size():
				for q2: int in bp.size():
					bp[q2] = bp[q2] + (bp2[q2] - bp[q2]) / n
				a["body_pts"] = bp
			var parts: Array = a.get("head_parts", [])
			var p2: Array = m[tag].get("head_parts", [])
			if parts.size() == p2.size():
				for k: int in parts.size():
					parts[k] = _mean(parts[k], p2[k], float(i + 2))
	return acc


static func _mean(a: AABB, b: AABB, k: float) -> AABB:
	return AABB(a.position + (b.position - a.position) / k, a.size + (b.size - a.size) / k)


## Subject dictionaries (LensSolver.subject_of) for every staged model, with the declared yaw.
func measure(subs: Array) -> Dictionary:
	var out := {}
	var yaws := {}
	for s: Dictionary in subs:
		yaws[s["tag"]] = float(s["yaw"])
	for tag: String in models:
		var m: Node3D = models[tag]
		out[tag] = LensSolver.subject_of(m, yaws.get(tag, rad_to_deg(m.global_rotation.y)))
	return out


# ---------------------------------------------------------------- light and background

## Lights: studio (key / fill / rim relative to the camera), warm / ice (LightingPreset sun + fill), dusk, night,
## set (the stage set's own LightingPreset). rim: warm / cool / off. bg: {kind: flat | ground | set | kingdom | none, value}.
func light(preset: String, rim: String, bg: Dictionary, cam: Transform3D, subject_center: Vector3) -> void:
	for l: Light3D in lights:
		l.queue_free()
	lights.clear()
	var bgc := Color(0.1, 0.1, 0.12)
	var kind: String = bg.get("kind", "flat")
	if kind in ["flat", "ground"] and String(bg.get("value", "")).begins_with("#"):
		bgc = Color.html(String(bg["value"]))
	env.background_mode = Environment.BG_COLOR
	env.background_color = bgc
	if kind == "ground" and root.get_node_or_null(^"LensGround") == null:
		var g := MeshInstance3D.new()
		g.name = "LensGround"
		var pm := PlaneMesh.new()
		pm.size = Vector2(400, 400)
		g.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = bgc
		mat.roughness = 1.0
		g.material_override = mat
		root.add_child(g)
		env.background_color = bgc.lightened(0.25)
	var p: LightingPreset = null
	if preset == "set" and set_node != null and set_node.get("lighting") is LightingPreset:
		p = set_node.get("lighting")
	elif PRESETS.has(preset):
		p = load(PRESETS[preset]) as LightingPreset
	if kind == "set" and p == null and set_node != null and set_node.get("lighting") is LightingPreset:
		p = set_node.get("lighting")
	var fwd := -cam.basis.z
	var cam_yaw := rad_to_deg(atan2(-fwd.x, -fwd.z))
	if p != null:
		if p.environment != null:
			env = p.environment.duplicate() as Environment
			if kind != "set":
				env.background_mode = Environment.BG_COLOR
				env.background_color = bgc
			world_env.environment = env
		_dir(p.sun_color, p.sun_energy, p.sun_rotation_degrees, true)
		if p.fill_energy > 0.0:
			_dir(p.fill_color, p.fill_energy, p.fill_rotation_degrees, false)
	else:
		match preset:
			"dusk":
				_dir(Color(1.0, 0.62, 0.42), 1.0, Vector3(-14, cam_yaw + 60.0, 0), true)
				_dir(Color(0.45, 0.5, 0.85), 0.35, Vector3(-30, cam_yaw - 120.0, 0), false)
				env.ambient_light_color = Color(0.5, 0.42, 0.55)
			"night":
				_dir(Color(0.55, 0.65, 1.0), 0.55, Vector3(-40, cam_yaw + 45.0, 0), true)
				env.ambient_light_color = Color(0.25, 0.3, 0.5)
				env.ambient_light_energy = 0.5
			_:
				# studio: key 40 deg left of the camera and 35 deg up, a soft fill from the right
				_dir(Color(1.0, 0.93, 0.82), 1.3, Vector3(-35, cam_yaw + 40.0, 0), true)
				_dir(Color(0.6, 0.7, 1.0), 0.3, Vector3(-15, cam_yaw - 70.0, 0), false)
	if rim != "off":
		# rim: from behind the subject toward the camera, a pale edge light
		var c := Color(1.0, 0.8, 0.55) if rim == "warm" else Color(0.75, 0.88, 1.0)
		_dir(c, 1.1, Vector3(-25, cam_yaw + 180.0 + 35.0, 0), false)


func _dir(c: Color, e: float, rot: Vector3, shadow: bool) -> void:
	var l := DirectionalLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.rotation_degrees = rot
	l.shadow_enabled = shadow
	root.add_child(l)
	lights.append(l)


# ---------------------------------------------------------------- ID passes

## Starts an ID pass: meshes under `white` nodes draw unshaded white, meshes under `black` nodes (or everything else
## when black_rest) draw black, the rest is hidden. Call id_end() after the snap.
func id_begin(viewport: SubViewport, white: Array, black: Array, black_rest: bool) -> void:
	_saved.clear()
	var wmat := StandardMaterial3D.new()
	wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wmat.albedo_color = Color.WHITE
	wmat.cull_mode = BaseMaterial3D.CULL_DISABLED      # single-sided cards (hair, capes) must still count
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.albedo_color = Color.BLACK
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for gi: Node in root.find_children("*", "GeometryInstance3D", true, false):
		var g := gi as GeometryInstance3D
		_saved.append([g, g.material_override, g.visible])
		var mode := 2 if black_rest else 0
		for w: Node in white:
			if w == g or w.is_ancestor_of(g):
				mode = 1
		if mode != 1:
			for b: Node in black:
				if b == g or b.is_ancestor_of(g):
					mode = 2
		if g is GPUParticles3D or g is CPUParticles3D:
			mode = 0
		match mode:
			1:
				g.material_override = wmat
			2:
				g.material_override = bmat
			_:
				g.visible = false
	for l: Node in root.find_children("*", "Light3D", true, false):
		_saved.append([l, null, (l as Light3D).visible])
		(l as Light3D).visible = false
	_saved.append([world_env, world_env.environment, true])
	world_env.environment = _id_env
	_saved.append([viewport, viewport.msaa_3d, true])
	viewport.msaa_3d = Viewport.MSAA_DISABLED


func id_end() -> void:
	for s: Array in _saved:
		var n: Object = s[0]
		if n is GeometryInstance3D:
			(n as GeometryInstance3D).material_override = s[1]
			(n as GeometryInstance3D).visible = s[2]
		elif n is Light3D:
			(n as Light3D).visible = s[2]
		elif n is WorldEnvironment:
			(n as WorldEnvironment).environment = s[1]
		elif n is SubViewport:
			(n as SubViewport).msaa_3d = s[1]
	_saved.clear()


## Head nodes of a model ("Head" pivot), else the model itself.
func head_node(tag: String) -> Node:
	var m: Node = models.get(tag)
	if m == null:
		return null
	var h := m.find_child("Head", true, false)
	return h if h != null else m


func free_stage() -> void:
	if is_instance_valid(root):
		root.queue_free()


# ---------------------------------------------------------------- backgrounds (images)

## Radial kingdom gradient (portraits), deterministic.
static func gradient_bg(size: int, faction: String) -> Image:
	var c: Color = KINGDOM.get(faction, KINGDOM["neutral"])
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var inner := c.darkened(0.35)
	var outer := Color(0.06, 0.05, 0.07)
	var ctr := Vector2(size * 0.5, size * 0.42)
	var rad := float(size) * 0.72
	for y: int in size:
		for x: int in size:
			var t := clampf(Vector2(x, y).distance_to(ctr) / rad, 0.0, 1.0)
			img.set_pixel(x, y, inner.lerp(outer, t * t))
	return img
