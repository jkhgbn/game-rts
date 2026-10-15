extends SceneTree
## G-E fixes D (docs/art/ge_fixes_d.md):
##  1  Nature units off the meadow: dark bark bodies (value <= 0.3), team cloth without a yellow-gold top (top colour
##     saturation <= 0.25), the riders' / mounts' straw on its own `nature_straw` material (never team-recoloured)
##  2  Thornback warden / Bramble dartcaster: draped cloth panels (NatureDrape), both faces, cheap grid
##  3  Nature war death leaves small (DEATH_LEAF_SIZE <= 0.1)
##  4  Dusk Keep: the dusk_keep_glow parts are accents (energies, thin rune ring, ground cracks)
##  5  Hovel: the tip shard core is paler than the base glow colour (R5c dL 0 fix)
##  6  the 4 Nature rider roots forward `offscreen_freeze` (G-F)
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_ge_fixes_d.gd --quit-after 3000

const TASK_ID := "ge_fixes_d"
const NAT := "res://art/units/nature/materials/"

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _src(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f else ""


func _p(path: String, key: StringName) -> Variant:
	var m := load(path) as ShaderMaterial
	return m.get_shader_parameter(key) if m else null


func _run() -> void:
	# 1 Nature value
	var bark: Variant = _p(NAT + "nature_bark.tres", &"base_color")
	_check(bark is Color and (bark as Color).v <= 0.3 and (bark as Color).r > (bark as Color).g, "nature_bark %s" % bark)
	var top: Variant = _p(NAT + "nature_cloth.tres", &"top_color")
	_check(top is Color and (top as Color).s <= 0.25, "nature_cloth top colour too saturated: %s" % top)
	var straw := load(NAT + "nature_straw.tres") as Material
	_check(straw != null, "nature_straw.tres missing")
	if straw:
		_check(CharacterModel._team_variant(straw, Color(0.9, 0.1, 0.1)) == null, "nature_straw gets team-recoloured")
	for f: String in ["res://art/units/nature/thornback_charger/parts/thornback_warden.gd",
			"res://art/units/nature/thornback_charger/parts/thornback_elk.gd",
			"res://art/units/nature/bramble_harrier/parts/bramble_dartcaster.gd",
			"res://art/units/nature/bramble_harrier/parts/bramble_hare.gd"]:
		var s := _src(f)
		_check(s.contains("nature_straw") and not s.contains("nature_bell_cloth"), f.get_file() + ": straw material")
	# 2 draped panels
	var drape: GDScript = load("res://art/units/nature/nature_drape.gd")
	var mesh: Mesh = drape.call(&"panel", "test_gfd_panel", 0.4, 0.5, 0.4, 0.05, 0.0, 3.0, 0.03, 0.05, 0.03, 0.02)
	_check(mesh != null and mesh.get_surface_count() == 1, "NatureDrape.panel mesh")
	if mesh:
		var arr := mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		_check(verts.size() <= 64, "drape vertex count %d (box class: <= 64)" % verts.size())
		var front := 0
		var back := 0
		for n: Vector3 in nrm:
			if n.z > 0.3:
				front += 1
			elif n.z < -0.3:
				back += 1
		_check(front > 0 and back > 0, "drape needs both faces (front %d, back %d)" % [front, back])
	for f: String in ["res://art/units/nature/thornback_charger/parts/thornback_warden.gd",
			"res://art/units/nature/bramble_harrier/parts/bramble_dartcaster.gd"]:
		_check(_src(f).count("DRAPE.panel(") >= 3, f.get_file() + ": draped panels")
	for sc: String in ["res://art/units/nature/thornback_charger/thornback_charger.tscn",
			"res://art/units/nature/bramble_harrier/bramble_harrier.tscn"]:
		var ps := load(sc) as PackedScene
		_check(ps != null, sc + " loads")
		if ps:
			var n: Node3D = ps.instantiate()
			root.add_child(n)
			for i in 3:
				await process_frame
			_check(n.find_children("*", "MeshInstance3D", true, false).size() > 4, sc.get_file() + " builds its meshes")
			_check(&"offscreen_freeze" in n, sc.get_file() + " offscreen_freeze")
			n.queue_free()
			await process_frame
	# 3 death leaves
	_check(NatureWarModel.DEATH_LEAF_SIZE <= 0.1, "Nature death leaves %s m" % NatureWarModel.DEATH_LEAF_SIZE)
	# 4 Dusk Keep accents
	var ks := load("res://art/buildings/dusk_keep.tscn") as PackedScene
	var keep: Node3D = ks.instantiate() if ks else null
	_check(keep != null, "dusk_keep.tscn")
	if keep:
		for nm: String in ["Windows", "FinTips", "RuneRing", "GateSlits", "LanternOrb1", "LanternOrb2", "LanternOrb3"]:
			var gi := keep.get_node_or_null("Model/" + nm) as GeometryInstance3D
			_check(gi != null, "Dusk Keep " + nm)
			if gi:
				var e: Variant = gi.get_instance_shader_parameter(&"energy")
				_check(e != null and float(e) <= 2.0, "Dusk Keep %s energy %s (accent <= 2.0)" % [nm, e])
		var ring := keep.get_node_or_null("Model/RuneRing") as MeshInstance3D
		if ring and ring.mesh is TorusMesh:
			var t := ring.mesh as TorusMesh
			_check(t.outer_radius - t.inner_radius <= 0.2, "Dusk Keep rune ring band %.2f m" % (t.outer_radius - t.inner_radius))
		keep.free()
	var dk: GDScript = load("res://art/buildings/dusk_keep.gd")
	_check(float(dk.get_script_constant_map().get("RING_ENERGY", 9.0)) <= 2.0, "DuskKeep.RING_ENERGY")
	var gm := RegEx.create_from_string("uniform float glow_energy = ([0-9.]+);").search(
		_src("res://art/buildings/dusk_keep_ground.gdshader"))
	_check(gm != null and float(gm.get_string(1)) <= 1.6, "dusk_keep_ground glow_energy")
	# 5 Hovel tip shard (the hut merges its glows into one material at run time: read the build source)
	var hv := _src("res://art/buildings/hovel.gd")
	var tip_ok := false
	for line: String in hv.split("\n"):
		if line.contains("_part(\"TipShard\"") and line.contains("glow_color.lerp(Color.WHITE, 0."):
			var k := line.find("Color.WHITE, ") + 13
			tip_ok = float(line.substr(k, 4)) >= 0.4
	_check(tip_ok, "hovel tip shard core not pale")
	# 6 offscreen_freeze on the other two Nature rider roots
	for f: String in ["res://art/units/nature/glade_outrider/glade_outrider.gd", "res://art/units/nature/stagrunner/stagrunner.gd"]:
		_check(_src(f).contains("OffscreenEmitters.forward_freeze(self, v)"), f.get_file() + " offscreen_freeze")
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0)
