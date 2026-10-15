extends SceneTree
## Task G-D creatures (docs/art/gd_creatures.md): the neutral camp creatures, epic beasts, hired neutrals and the
## Frost Wyrm get a High / Ultra "signature" emitter (CreatureSignature) and shape / material passes.
## Run: $GODOT --headless --path . -s tests/test_gd_creatures.gd --fixed-fps 60 --quit-after 9000
## Checks:
##  A Low (the real headless tier): no "Signature" node on any scene (no new particles at Low).
##  B forced High (CreatureSignature.quality_override = 2), per scene on its own: exactly one Signature
##    GPUParticles3D, a child of the model (FogOfWar hides it with the unit), off at spawn; emitting with a camera 6 m
##    away looking at it; off with the camera 80 m away; off with the camera 6 m away looking away (off-screen);
##    on again when it looks back; off once the model is dead. Its process material / quad are shared by a second
##    instance (no runtime material per instance). Direwolf / Roc variant B restyle the emitter (another material).
##  C shapes: the direwolf fur locks lean toward the coat normal (soft fur), the tusker plates carry horn scutes and
##    use the horn surface kind (7), the grizzlemaw moss is a cushion of lumps (more moss vertices on A than B),
##    the gloomcap warts are raised domes.
## Prints "PASS gd_creatures" or "FAIL gd_creatures: <reasons>".

const TASK_ID := "gd_creatures"
const N := "res://art/units/neutral/"
## [scene, variant, expected parent pivot name]
const SCENES: Array = [
	["bristleback/bristleback.tscn", 0, "Head"],
	["mirefang/mirefang.tscn", 0, "Mount"],
	["gloomcap/gloomcap_sprout.tscn", 0, "Head"],
	["gloomcap/gloomcap_elder.tscn", 0, "Root"],
	["hollow_stag/hollow_stag.tscn", 0, "Crown"],
	["stormbottle_genie/stormbottle_genie.tscn", 0, "Chest"],
	["magpie/magpie.tscn", 0, "Hips"],
	["beasts/tusker/tusker.tscn", 1, "Head"],
	["beasts/roc/roc.tscn", 1, "Body"],
	["beasts/direwolf/direwolf.tscn", 1, "Skull"],
	["beasts/grizzlemaw/grizzlemaw.tscn", 1, "Mount"],
	["beasts/frost_wyrm/frost_wyrm.tscn", 0, "Body"],
]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _cam: Camera3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_cam = Camera3D.new()
	_world.add_child(_cam)
	_cam.make_current()
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAIL ", what)


func _wait(sec: float) -> void:
	for i: int in int(sec * 60.0):
		await process_frame


func _spawn(rel: String, variant: int, at: Vector3) -> Node3D:
	var m := (load(N + rel) as PackedScene).instantiate() as Node3D
	m.position = at
	if m.get(&"offscreen_freeze") != null:
		m.set(&"offscreen_freeze", true)   # as Unit sets it
	_world.add_child(m)
	if variant != 0 and m.has_method(&"set_variant"):
		m.call(&"set_variant", variant)
	return m


func _sig(m: Node) -> GPUParticles3D:
	return m.find_child("Signature", true, false) as GPUParticles3D


func _look(at: Vector3, dist: float, away: bool = false) -> void:
	_cam.global_position = at + Vector3(0.0, dist * 0.6, dist * 0.8)
	_cam.look_at(at + Vector3(0, 1.0, 0) if not away else at + Vector3(0.0, dist * 0.6 + 3.0, dist * 0.8 + 10.0))


func _run() -> void:
	# ---- A: Low (headless default) builds no signature.
	CreatureSignature.quality_override = -1
	var x := 0.0
	for e: Array in SCENES:
		var m := _spawn(e[0], e[1], Vector3(x, 0.0, 0.0))
		x += 30.0
		await _wait(0.1)
		_check(_sig(m) == null, "%s: no signature at Low" % e[0])
		m.queue_free()
	await _wait(0.1)
	# ---- B: forced High, one scene at a time far from the others.
	CreatureSignature.quality_override = 2
	x = 0.0
	for e: Array in SCENES:
		var rel: String = e[0]
		var at := Vector3(x, 0.0, 0.0)
		x += 60.0
		_look(at, 60.0)
		var m := _spawn(rel, e[1], at)
		var m2 := _spawn(rel, e[1], at + Vector3(0.0, 0.0, -12.0))
		await _wait(0.1)
		var s := _sig(m)
		var s2 := _sig(m2)
		_check(s != null, "%s: one Signature emitter at High" % rel)
		if s == null:
			m.queue_free()
			m2.queue_free()
			continue
		var count := 0
		for n: Node in m.find_children("Signature", "GPUParticles3D", true, false):
			count += 1
		_check(count == 1, "%s: exactly one Signature (got %d)" % [rel, count])
		_check(m.is_ancestor_of(s), "%s: the signature is a child of the model (fog hides it)" % rel)
		_check(String(s.get_parent().name) == String(e[2]), "%s: signature under %s (got %s)" % [rel, e[2],
			s.get_parent().name])
		_check(s2 != null and s.process_material == s2.process_material and s.draw_pass_1 == s2.draw_pass_1,
			"%s: process material / quad shared by a second instance" % rel)
		_check(not s.emitting, "%s: off while the camera is far" % rel)
		_look(at, 6.0)
		await _wait(1.2)
		_check(s.emitting, "%s: emitting with the camera 6 m away" % rel)
		_look(at, 80.0)
		await _wait(1.2)
		_check(not s.emitting, "%s: off with the camera 80 m away" % rel)
		_look(at, 6.0, true)
		await _wait(1.2)
		_check(not s.emitting, "%s: off when the camera looks away" % rel)
		_look(at, 6.0)
		await _wait(1.2)
		_check(s.emitting, "%s: back on when the camera looks back" % rel)
		if rel.contains("direwolf") or rel.contains("roc"):
			var before := s.process_material
			m.call(&"set_variant", 0)
			await _wait(0.1)
			_check(s.process_material != before, "%s: variant A restyles the signature" % rel)
		m.call(&"play_death")
		await _wait(1.2)
		_check(not is_instance_valid(s) or not s.emitting, "%s: off once dead" % rel)
		m.queue_free()
		m2.queue_free()
		await _wait(0.1)
	CreatureSignature.quality_override = -1
	_shapes()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _shapes() -> void:
	# Direwolf: fur lock normals soften toward the coat normal.
	var dm: GDScript = load("res://art/units/neutral/beasts/direwolf/direwolf_mesh.gd")
	var acc: Array = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	dm.call(&"_lock", acc, Vector3.ZERO, Vector3.UP, Vector3(0, 0.3, -1), 0.3, 0.1)
	var ok := true
	for nr: Vector3 in (acc[1] as PackedVector3Array):
		if nr.dot(Vector3.UP) < 0.3:
			ok = false
	_check(ok and (acc[1] as PackedVector3Array).size() > 0, "direwolf: fur lock normals lean to the coat normal")
	# Tusker plates: horn kind and scutes (the plate surface has many more vertices than the 6 bands alone).
	var tm: GDScript = load("res://art/units/neutral/beasts/tusker/tusker_mesh.gd")
	var plate := tm.call(&"mat", "tusker_plate") as ShaderMaterial
	_check(plate != null and int(plate.get_shader_parameter(&"surface_kind")) == 7, "tusker: plate surface kind = horn (7)")
	var body := tm.call(&"body_mesh") as ArrayMesh
	var pv := 0
	for i: int in body.get_surface_count():
		if body.surface_get_material(i) == plate:
			pv = (body.surface_get_arrays(i)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_check(pv > 1200, "tusker: plate surface carries the scutes (%d vertices)" % pv)
	# Grizzlemaw moss: cushions, A much mossier than B.
	var gm: GDScript = load("res://art/units/neutral/beasts/grizzlemaw/grizzlemaw_mesh.gd")
	var moss_mat: Material = gm.call(&"mat", "moss")
	var mv: Array[int] = [0, 0]
	for v: int in 2:
		var bm := gm.call(&"body_mesh", v) as ArrayMesh
		for i: int in bm.get_surface_count():
			if bm.surface_get_material(i) == moss_mat:
				mv[v] = (bm.surface_get_arrays(i)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_check(mv[0] > 900 and mv[0] > mv[1] * 2, "grizzlemaw: moss cushions (A %d, B %d vertices)" % [mv[0], mv[1]])
	# Gloomcap warts: raised (taller than the old 0.026 m flat spots).
	var gc: GDScript = load("res://art/units/neutral/gloomcap/gloomcap_mesh.gd")
	var wa: Array = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	gc.call(&"warts", wa, Vector3.ZERO, Vector3.UP, 0.12, 1.0)
	var top := -1.0
	for p: Vector3 in (wa[0] as PackedVector3Array):
		top = maxf(top, p.y)
	_check(top > 0.035, "gloomcap: warts are raised domes (top %.3f m)" % top)
