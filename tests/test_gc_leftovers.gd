extends SceneTree
## G-C leftovers (graphics week 2026-10-15, docs/art/gc_leftovers.md): the units the first G-C pass skipped.
## Run:  $GODOT --headless --path . -s tests/test_gc_leftovers.gd --fixed-fps 60 --quit-after 3000
## Checks (headless):
##  - every reshaped scene loads and builds without errors, two instances share their merged meshes;
##  - soldier budget on the reshaped soldiers (Art Lab B4: body + face above its 800 allowance <= 2500; the Frost Mortar
##    and the Frostrune Rifleman were over it before) and no BoxMesh / CapsuleMesh node drawn on them;
##  - cavalry (riders reshaped): <= 20 draw instances, <= 14000 body vertices; the Nature mounts' bodies <= 6000;
##  - the Mender (shaped legs / hands) stays <= 8750 vertices (test_9_v4's cap, unchanged);
##  - the hooks / named nodes the game reads are still there (Muzzle, MaulMesh, MaulRunes, SlabRune, Rifle, Monopod, Jaw,
##    BladeRune, Sigil, VetTrim; glow nodes may stay primitives) and the beam / muzzle origins are finite;
##  - IceUnitShapes / ChampionShapes pieces have outward normals (egg, limb, crystal).
## Prints PASS gc_leftovers / FAIL gc_leftovers: <reason>.

const TASK_ID := "gc_leftovers"
const SOLDIERS: Array[String] = [
	"res://art/units/ice/frost_mortar/frost_mortar.tscn",
	"res://art/units/ice/rimecarver/rimecarver.tscn",
	"res://art/units/ice/rimeling/rimeling.tscn",
	"res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn",
	"res://art/units/shadow/barrow_ghoul/barrow_ghoul.tscn",
	"res://art/units/shadow/hollow_oathsworn/hollow_oathsworn.tscn",
	"res://art/units/shadow/nightblood_reaver/nightblood_reaver.tscn",
	"res://art/units/shadow/bleakbow/bleakbow.tscn",
	"res://art/units/shadow/hexweaver/hexweaver.tscn",
]
const CAVALRY: Array[String] = [
	"res://art/units/fire/blaze_rider.tscn",
	"res://art/units/fire/emberdart_harrier/emberdart_harrier.tscn",
	"res://art/units/fire/pyrehoof_lancer/pyrehoof_lancer.tscn",
	"res://art/units/fire/sunforge_cataphract/sunforge_cataphract.tscn",
	"res://art/units/shadow/barrow_knight/barrow_knight.tscn",
	"res://art/units/shadow/duskbolt_harrier/duskbolt_harrier.tscn",
	"res://art/units/shadow/veilborn_dreadrider/veilborn_dreadrider.tscn",
	"res://art/units/shadow/gloam_rider/gloam_rider.tscn",
	"res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn",
	"res://art/units/ice/rime_harrier/rime_harrier.tscn",
	"res://art/units/ice/snowdrift_rider/snowdrift_rider.tscn",
	"res://art/units/ice/frostcrown_juggernaut/frostcrown_juggernaut.tscn",
	"res://art/units/nature/thornback_charger/thornback_charger.tscn",
	"res://art/units/nature/bramble_harrier/bramble_harrier.tscn",
]
const MENDER := "res://art/units/champions/mender/mender.tscn"
## Named nodes per scene (path relative to the model root).
const HOOKS := {
	"frost_mortar": ["Root/Mount/Muzzle", "Root/Chest/Head/VetTrim"],
	"rimecarver": ["Root/Chest/ArmR/Maul/MaulMesh", "Root/Chest/ArmR/Maul/MaulRunes", "Root/Chest/SlabRune"],
	"frostrune_rifleman": ["Root/Chest/ArmR/Rifle", "Root/Chest/ArmR/Rifle/Monopod"],
	"barrow_ghoul": ["Root/Chest/Head/Jaw/JawBone", "Root/Chest/Head/VetTrim"],
	"hollow_oathsworn": ["Root/Chest/ArmR/BladeRune", "Fx/Sigil"],
}

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  check failed: ", what)


func _frames(n: int) -> void:
	for _i: int in n:
		await process_frame


func _spawn(path: String, at: Vector3) -> Node3D:
	var ps := load(path) as PackedScene
	_check(ps != null, "loads: " + path)
	if ps == null:
		return null
	var m := ps.instantiate() as Node3D
	m.position = at
	_world.add_child(m)
	return m


static func _mesh_verts(mesh: Mesh) -> int:
	var n := 0
	for s: int in mesh.get_surface_count():
		n += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n


## [body vertices, face vertices, mesh draw instances (particles excluded)] of everything visible (blob: no vertices).
static func _measure(m: Node) -> Vector3i:
	var body := 0
	var face := 0
	var draws := 0
	for g: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.is_visible_in_tree() or gi is GPUParticles3D or gi is CPUParticles3D:
			continue
		draws += 1
		if not gi is MeshInstance3D or (gi as MeshInstance3D).mesh == null or gi.name == "Shadow":
			continue
		var c := _mesh_verts((gi as MeshInstance3D).mesh)
		if gi.name == "Face" or gi.get_parent().name == "Face":
			face += c
		else:
			body += c
	return Vector3i(body, face, draws)


static func _prim_drawn(m: Node) -> String:
	for g: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.is_visible_in_tree() and not mi.has_meta(&"own_glow") and (mi.mesh is BoxMesh or mi.mesh is CapsuleMesh):
			return String(m.get_path_to(mi))
	return ""


static func _merged_meshes(m: Node) -> Array:
	var out: Array = []
	for g: Node in m.find_children("Merged", "MeshInstance3D", true, false):
		out.append((g as MeshInstance3D).mesh)
	return out


## Share of vertices whose normal points away from `centre` (a convex piece: should be ~all).
static func _outward(mesh: Mesh, centre: Vector3) -> float:
	var arr := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var good := 0
	for i: int in v.size():
		if nr[i].dot(v[i] - centre) > -0.0001:
			good += 1
	return float(good) / float(maxi(v.size(), 1))


func _shape_checks() -> void:
	var st := ChampionShapes.begin()
	IceUnitShapes.egg(st, Transform3D(Basis.IDENTITY, Vector3(1, 2, 3)), 0.1, 0.2, 7)
	var egg := ChampionShapes.commit(st)
	_check(_outward(egg, Vector3(1, 2, 3) + Vector3(0, 0.01, 0)) > 0.95, "egg normals point outward")
	st = ChampionShapes.begin()
	IceUnitShapes.limb(st, Vector3(0, 1, 0), Vector3(0, 0.5, 0.05), Vector3(0, 0, 0), 0.1, 0.09, 0.08, 7)
	var limb := ChampionShapes.commit(st)
	var ok := 0
	var arr := limb.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for i: int in v.size():
		var axis := Vector3(0, v[i].y, 0.05 * (1.0 - absf(v[i].y - 0.5) * 2.0))
		if nr[i].dot(v[i] - axis) > 0.0:
			ok += 1
	_check(float(ok) / float(maxi(v.size(), 1)) > 0.95, "limb normals point outward")
	st = ChampionShapes.begin()
	IceUnitShapes.crystal(st, Vector3.ZERO, Vector3.UP, 0.05, 0.3)
	_check(_outward(ChampionShapes.commit(st), Vector3(0, 0.1, 0)) > 0.95, "crystal normals point outward")
	var a := IceUnitShapes.mesh("gc_leftovers_test", func(s: SurfaceTool) -> void:
		IceUnitShapes.egg(s, Transform3D.IDENTITY, 0.1, 0.2))
	var b := IceUnitShapes.mesh("gc_leftovers_test", func(_s: SurfaceTool) -> void: pass)
	_check(a == b and _mesh_verts(a) > 0, "IceUnitShapes.mesh caches by key")


func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	_world.add_child(cam)
	cam.position = Vector3(0, 30, 30)
	cam.look_at(Vector3.ZERO)
	cam.make_current()
	_shape_checks()
	var pairs: Array = []
	var i := 0
	for p: String in SOLDIERS:
		pairs.append([p, _spawn(p, Vector3(i * 3.0, 0, 0)), _spawn(p, Vector3(i * 3.0, 0, 4.0))])
		i += 1
	var cav: Array = []
	for p: String in CAVALRY:
		cav.append([p, _spawn(p, Vector3(i * 3.0, 0, 0))])
		i += 1
	var mender := _spawn(MENDER, Vector3(i * 3.0, 0, 0))
	await _frames(6)
	for pr: Array in pairs:
		var nm: String = (pr[0] as String).get_file().get_basename()
		var a: Node3D = pr[1]
		var b: Node3D = pr[2]
		if a == null or b == null:
			continue
		var ms := _measure(a)
		var b4: int = ms.x + maxi(0, ms.y - 800)
		print("%s: body %d, face %d, B4 %d, draws %d" % [nm, ms.x, ms.y, b4, ms.z])
		_check(b4 <= 2500, "%s: B4 %d > 2500 (soldier budget)" % [nm, b4])
		_check(ms.z <= 14, "%s: %d mesh draw instances > 14" % [nm, ms.z])
		var prim := _prim_drawn(a)
		_check(prim == "", "%s: a BoxMesh / CapsuleMesh is drawn (%s)" % [nm, prim])
		var ma := _merged_meshes(a)
		var mb := _merged_meshes(b)
		_check(ma.size() > 0 and ma == mb, "%s: merged meshes shared between instances" % nm)
		for h: String in HOOKS.get(nm, []):
			_check(a.get_node_or_null(h) != null, "%s: node %s" % [nm, h])
		if a.has_method(&"get_beam_origin"):
			var o: Vector3 = a.call(&"get_beam_origin")
			_check(o.is_finite(), "%s: beam origin finite" % nm)
	for pr: Array in cav:
		var nm: String = (pr[0] as String).get_file().get_basename()
		var m: Node3D = pr[1]
		if m == null:
			continue
		var ms := _measure(m)
		print("%s: body %d, face %d, draws %d" % [nm, ms.x, ms.y, ms.z])
		_check(ms.z <= 20, "%s: %d draw instances > 20" % [nm, ms.z])
		_check(ms.x <= 14000, "%s: %d body vertices > 14000" % [nm, ms.x])
		if nm in ["thornback_charger", "bramble_harrier"]:
			var mount := 0
			for g: Node in m.find_children("*", "MeshInstance3D", true, false):
				var mi := g as MeshInstance3D
				if mi.mesh and mi.is_visible_in_tree() and mi.name != "Shadow" and not String(m.get_path_to(mi)).contains("Rider"):
					mount += _mesh_verts(mi.mesh)
			print("  %s mount vertices %d" % [nm, mount])
			_check(mount <= 6000, "%s: mount %d vertices > 6000" % [nm, mount])
	if mender:
		var mm := _measure(mender)
		print("mender: body %d, face %d, draws %d" % [mm.x, mm.y, mm.z])
		_check(mm.x + mm.y <= 8750, "mender: %d vertices > 8750" % (mm.x + mm.y))
		var fr := mender.get_node_or_null("Root/Chest/ArmR/Merged")
		_check(fr != null, "mender: right arm merged")
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	quit(0 if _fails.is_empty() else 1)
