extends SceneTree
## G-C Ice units (docs/art/gc_ice_units.md): the Ice army's shape pass (lathed helms / torsos / robes, tapered limbs,
## soft-edged plates, jagged fur rings, curved team capes, fur caps) and the High-only snow motes.
## Checks:
##  A. IceModel shape builders: vertex counts, unit normals, every triangle wound front-out (Godot: clockwise front),
##     cloak UV.y 0 at the top edge, meshes cached (one per shape).
##  B. Every Ice army scene (headless = Low tier): instantiates twice with the merge cache shared, the pivots / Fx /
##     Shadow contract, body vertices (minus the FaceKit face up to its allowance) within the tier budget, draw
##     instances within the budget, no SnowMotes node, hooks (walk / attack / hit / cast / level-up / death_finished /
##     revive) run without errors, the Rimeshield's team cape takes the team colour.
##  C. Snow motes forced to High (IceModel.snow_quality_override = 2): one SnowMotes system (world space, <= 10,
##     one-shot false), emitting with the camera 7 m away, off with it 40 m away, off while the model is off-screen
##     (close camera looking away, offscreen_freeze on), off while dead, back on revive.
## Run: $GODOT --headless --path . -s tests/test_gc_ice.gd --fixed-fps 60 --quit-after 6000
## Prints "PASS gc_ice" or "FAIL gc_ice: <reasons>".

const TASK_ID := "gc_ice"
const SCENES := {
	"res://art/units/ice/rime_hauler.tscn": [2500, 14],
	"res://art/units/ice/rimeshield.tscn": [2500, 14],
	"res://art/units/ice/shardcaster.tscn": [2500, 14],
	"res://art/units/ice/rime_seer.tscn": [2500, 14],
	"res://art/units/ice/rime_colossus.tscn": [6000, 16],
	"res://art/units/ice/frostbow/frostbow.tscn": [2500, 14],
	"res://art/units/ice/hoarlight_magebow/hoarlight_magebow.tscn": [2500, 14],
	"res://art/units/ice/shardguard/shardguard.tscn": [6000, 16],
	"res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn": [5000, 15],
}
const FACE_ALLOWANCE := 800
## Riders (their plates became soft-edged boxes in G-C): build twice, run the hooks, death_finished.
const RIDERS: Array[String] = [
	"res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn",
	"res://art/units/ice/rime_harrier/rime_harrier.tscn",
	"res://art/units/ice/snowdrift_rider/snowdrift_rider.tscn",
	"res://art/units/ice/frostcrown_juggernaut/frostcrown_juggernaut.tscn",
]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _cam: Camera3D


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 6, 120)
	_world.add_child(_cam)
	_run()


func _run() -> void:
	_check_builders()
	await _check_scenes()
	await _check_riders()
	await _check_snow()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# ---------------------------------------------------------------- A. builders

func _check_builders() -> void:
	var prof := PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.35, 0.5), Vector2(0.2, 0.9), Vector2(0.0, 1.0)])
	var l := IceModel.lathe(prof, 10)
	_check(l == IceModel.lathe(prof, 10), "lathe cached")
	_check(_verts(l) == 11 * 4, "lathe vertices %d (11 x 4)" % _verts(l))
	_check_winding(l, Vector3(0, 0.5, 0), "lathe")
	var rev := prof.duplicate()
	rev.reverse()
	_check_winding(IceModel.lathe(rev, 10), Vector3(0, 0.5, 0), "lathe from a top -> bottom profile")
	var t := IceModel.taper(0.5, 0.1, 0.08)
	_check(_verts(t) == 54, "taper vertices %d (54, a capsule_lo is 81)" % _verts(t))
	_check_winding(t, Vector3(0, 0.25, 0), "taper")
	var sb := IceModel.soft_box(Vector3(0.3, 0.2, 0.4))
	_check(_verts(sb) == 24, "soft_box vertices %d (24)" % _verts(sb))
	_check_winding(sb, Vector3.ZERO, "soft_box")
	var fr := IceModel.fur_ring(0.2, 0.3, 0.12, 7, 0.04)
	_check(_verts(fr) == 15 * 4, "fur_ring vertices %d (15 x 4)" % _verts(fr))
	_check_winding(fr, Vector3(0, 0.06, 0), "fur_ring")
	var fc := IceModel.fur_cap(0.5, -15.0, 6, 20.0, 230.0)
	_check(_verts(fc) == 13 * 5, "fur_cap vertices %d (13 x 5)" % _verts(fc))
	_check_winding(fc, Vector3.ZERO, "fur_cap")
	var ck := IceModel.cloak(0.25, 0.4, 0.8, 150.0, 4, 5)
	var arr := ck.surface_get_arrays(0)
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var top_ok := true
	for i: int in vv.size():
		if absf(vv[i].y) < 0.001 and uv[i].y > 0.001:
			top_ok = false
	_check(top_ok and vv.size() == 30, "cloak: UV.y 0 on the top edge, 30 vertices (%d)" % vv.size())
	_check(_verts(IceModel.boot(0.12, 0.15)) == 36, "boot vertices 36")
	var arc := IceModel.lathe(prof, 6, 1.0, 1.0, 120.0)
	var amin := INF
	var amax := -INF
	for p: Vector3 in arc.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		if Vector2(p.x, p.z).length() > 0.01:
			var a := atan2(p.x, p.z)
			amin = minf(amin, a)
			amax = maxf(amax, a)
	_check(absf(amin + deg_to_rad(60.0)) < 0.01 and absf(amax - deg_to_rad(60.0)) < 0.01,
		"lathe arc 120 centred on +Z (%.1f .. %.1f deg)" % [rad_to_deg(amin), rad_to_deg(amax)])


## Every triangle's geometric normal points away from `inside` (front face out), and normals are unit length.
func _check_winding(m: Mesh, inside: Vector3, what: String) -> void:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var bad := 0
	for nn: Vector3 in n:
		if absf(nn.length() - 1.0) > 0.01:
			bad += 1
	_check(bad == 0, "%s: %d normals not unit length" % [what, bad])
	var wrong := 0
	for k: int in range(0, ix.size(), 3):
		var a := v[ix[k]]
		var b := v[ix[k + 1]]
		var c := v[ix[k + 2]]
		# Godot front faces are clockwise: cross(b - a, c - a) points INTO the surface for a front face seen from outside.
		var cr := (b - a).cross(c - a)
		var mid := (a + b + c) / 3.0
		if cr.dot(mid - inside) > 0.0:
			wrong += 1
	_check(ix.size() > 0 and wrong == 0, "%s: %d of %d triangles wound inside-out" % [what, wrong, ix.size() / 3])


# ---------------------------------------------------------------- B. scenes

func _check_scenes() -> void:
	for path: String in SCENES:
		if not ResourceLoader.exists(path):
			_fails.append("missing " + path)
			continue
		var budget: Array = SCENES[path]
		var ps := load(path) as PackedScene
		var a := ps.instantiate() as Node3D
		var b := ps.instantiate() as Node3D
		a.position = Vector3(-2, 0, 0)
		b.position = Vector3(2, 0, 0)
		_world.add_child(a)
		_world.add_child(b)
		await process_frame
		var nm := path.get_file().get_basename()
		_check(a is IceModel, "%s is an IceModel" % nm)
		for pv: String in ["Root", "Root/Chest", "Root/Chest/Head", "Root/Chest/ArmL", "Root/Chest/ArmR", "Fx"]:
			_check(a.get_node_or_null(pv) != null, "%s keeps %s" % [nm, pv])
		var ca := a.get_node_or_null("Root/Chest/Merged") as MeshInstance3D
		var cb := b.get_node_or_null("Root/Chest/Merged") as MeshInstance3D
		_check(ca != null and cb != null and ca.mesh == cb.mesh, "%s chest merge shared" % nm)
		_check(a.find_child("SnowMotes", true, false) == null, "%s: no snow motes at Low" % nm)
		var body := 0
		var face := 0
		var draws := 0
		for n: Node in a.find_children("*", "GeometryInstance3D", true, false):
			if not (n as GeometryInstance3D).visible:
				continue
			if n is GPUParticles3D:
				continue
			draws += 1
			if n is MeshInstance3D and (n as MeshInstance3D).mesh:
				var vc := _verts((n as MeshInstance3D).mesh)
				if n.name == "Face":
					face += vc
				else:
					body += vc
		var counted: int = body + maxi(0, face - FACE_ALLOWANCE)
		print("%s: body %d verts (+ face %d), %d mesh draws" % [nm, body, face, draws])
		_check(counted <= int(budget[0]), "%s vertices %d > %d" % [nm, counted, budget[0]])
		_check(draws <= int(budget[1]), "%s mesh draws %d > %d" % [nm, draws, budget[1]])
		# hooks
		a.call(&"set_moving", 3.0)
		for i: int in 10:
			await process_frame
		a.call(&"set_moving", 0.0)
		a.call(&"play_attack")
		a.call(&"play_hit")
		a.call(&"play_cast", &"support")
		a.call(&"play_level_up")
		for i: int in 40:
			await process_frame
		var done := [false]
		a.connect(&"death_finished", func() -> void: done[0] = true)
		a.call(&"play_death")
		for i: int in 150:
			await process_frame
			if done[0]:
				break
		_check(done[0], "%s death_finished" % nm)
		a.call(&"revive")
		await process_frame
		if nm == "rimeshield":
			_check(_has_team_cape(a, Color(0.85, 0.30, 0.12)) == false, "rimeshield cape not red before recolour")
			a.call(&"set_team_color", Color(0.85, 0.30, 0.12))
			await process_frame
			_check(_has_team_cape(a, Color(0.85, 0.30, 0.12)), "rimeshield team cape takes the team colour")
		a.queue_free()
		b.queue_free()
		await process_frame


func _check_riders() -> void:
	for path: String in RIDERS:
		if not ResourceLoader.exists(path):
			_fails.append("missing " + path)
			continue
		var ps := load(path) as PackedScene
		var a := ps.instantiate() as Node3D
		var b := ps.instantiate() as Node3D
		_world.add_child(a)
		_world.add_child(b)
		b.position = Vector3(4, 0, 0)
		await process_frame
		var nm := path.get_file().get_basename()
		var meshes := 0
		for n: Node in a.find_children("*", "MeshInstance3D", true, false):
			if (n as MeshInstance3D).mesh and (n as MeshInstance3D).visible:
				meshes += 1
		_check(meshes > 0, "%s draws meshes" % nm)
		for hk: StringName in [&"set_moving", &"play_attack", &"play_hit", &"play_death", &"revive"]:
			_check(a.has_method(hk), "%s hook %s" % [nm, hk])
		a.call(&"set_team_color", Color(0.85, 0.30, 0.12))
		a.call(&"set_moving", 5.0)
		for i: int in 10:
			await process_frame
		a.call(&"play_attack")
		a.call(&"play_hit")
		for i: int in 30:
			await process_frame
		var done := [false]
		if a.has_signal(&"death_finished"):
			a.connect(&"death_finished", func() -> void: done[0] = true)
		else:
			done[0] = true
		a.call(&"play_death")
		for i: int in 200:
			await process_frame
			if done[0]:
				break
		_check(done[0], "%s death_finished" % nm)
		a.call(&"revive")
		await process_frame
		print("%s: %d mesh nodes" % [nm, meshes])
		a.queue_free()
		b.queue_free()
		await process_frame


## True when a surface of the chest merge draws a banner cape in colour c.
func _has_team_cape(m: Node, c: Color) -> bool:
	var mi := m.get_node_or_null("Root/Chest/Merged") as MeshInstance3D
	if mi == null:
		return false
	for s: int in mi.mesh.get_surface_count():
		var mat := mi.get_surface_override_material(s)
		if mat == null:
			mat = mi.mesh.surface_get_material(s)
		if mat is ShaderMaterial and (mat as ShaderMaterial).shader \
				and (mat as ShaderMaterial).shader.resource_path.ends_with("banner.gdshader"):
			var cc: Variant = (mat as ShaderMaterial).get_shader_parameter(&"cloth_color")
			if cc is Color and (cc as Color).is_equal_approx(c):
				return true
	return false


# ---------------------------------------------------------------- C. snow motes (forced High)

func _check_snow() -> void:
	IceModel.snow_quality_override = 2
	var m := (load("res://art/units/ice/rimeshield.tscn") as PackedScene).instantiate() as Node3D
	_world.add_child(m)
	_cam.position = Vector3(0, 4, 6)
	_cam.look_at(Vector3(0, 1, 0))
	for i: int in 45:
		await process_frame
	var s := m.find_child("SnowMotes", true, false) as GPUParticles3D
	_check(s != null, "snow motes built at High")
	if s:
		_check(s.amount <= 10 and not s.one_shot and not s.local_coords, "snow motes: <= 10, looping, world space")
		_check(s.emitting, "snow motes emit with the camera 7 m away")
		_cam.position = Vector3(0, 20, 36)
		for i: int in 60:
			await process_frame
		_check(not s.emitting, "snow motes off with the camera 40 m away")
		_cam.position = Vector3(0, 4, 6)
		for i: int in 60:
			await process_frame
		_check(s.emitting, "snow motes back with the camera close")
		# Off-screen but close (tier 0): the kit freezes the model; the motes must stop too.
		m.set(&"offscreen_freeze", true)
		_cam.position = Vector3(0, 4, 10)
		_cam.look_at(Vector3(0, 4, 40))
		for i: int in 30:
			await process_frame
		_check(bool(m.get(&"_offscreen")), "test setup: the model is off-screen")
		_check(not s.emitting, "snow motes off while the model is off-screen")
		_cam.position = Vector3(0, 4, 6)
		_cam.look_at(Vector3(0, 1, 0))
		for i: int in 30:
			await process_frame
		_check(s.emitting, "snow motes back on screen")
		m.set(&"offscreen_freeze", false)
		m.call(&"play_death")
		for i: int in 20:
			await process_frame
		_check(not s.emitting, "snow motes off while dead")
		m.call(&"revive")
		for i: int in 20:
			await process_frame
		_check(s.emitting, "snow motes back on revive")
	var c := (load("res://art/units/ice/rime_colossus.tscn") as PackedScene).instantiate() as Node3D
	_world.add_child(c)
	await process_frame
	var cs := c.find_child("SnowMotes", true, false) as GPUParticles3D
	_check(cs != null and cs.amount == 10, "colossus: 10 snow motes")
	IceModel.snow_quality_override = -1
	m.queue_free()
	c.queue_free()
	await process_frame


static func _verts(m: Mesh) -> int:
	var n := 0
	for s: int in m.get_surface_count():
		n += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n
