extends SceneTree
## Exports the prologue castle (World Forge stage set `forge_citadel`) and the two titan dragons to glTF for the
## Blender film (art/blender/prologue_castle/, build_castle.py). Read-only on the game: it only loads scenes and
## writes into the output folder. Usage (one Godot at a time, through the gate):
##   tools\godot_run.ps1 --headless --path . -s tools/blender_export_citadel.gd --quit-after 6000 '--' [out=<dir>] [probe=1]
## (quote the '--' in PowerShell, which otherwise swallows it; no user arguments = the default output folder)
## Default out = res://art/blender/prologue_castle/export. Files:
##   citadel.glb        the whole set (Ground, Masonry, Scatter, Puppets: the Master + the swordsman, Shots marks)
##   dragon_cinder.glb  the Cinder Dragon model (pivot hierarchy Root/Body/WingL/WingL2/... kept as nodes)
##   dragon_frost.glb   the Frost Dragon model
##   materials.json     every material by the name it has in the glTF: class, source path, shader, parameters
##   nodes.json         lights, particle emitters and marks with global transforms (Godot space, Y up)
##   export_report.txt  counts per mesh / surface
## probe=1 prints the surfaces and materials without writing anything.

const SET_SCENE := "res://art/cinematics/stage_sets/forge_citadel/forge_citadel.tscn"
const DRAGONS := {
	"dragon_cinder": "res://art/units/titans/cinder_dragon/cinder_dragon.tscn",
	"dragon_frost": "res://art/units/titans/frost_dragon/frost_dragon.tscn",
}

var _out_dir := "res://art/blender/prologue_castle/export"
var _probe := false
var _frames := 0
var _materials := {}        # material instance id -> name
var _mat_info := {}         # name -> Dictionary
var _report: PackedStringArray = []
var _roots: Array[Node] = []


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			_out_dir = a.substr(4)
			if not _out_dir.begins_with("res://") and not _out_dir.is_absolute_path():
				_out_dir = "res://" + _out_dir
		elif a == "probe=1":
			_probe = true
	var set_scene := load(SET_SCENE) as PackedScene
	if set_scene == null:
		push_error("BLENDER_EXPORT: cannot load " + SET_SCENE)
		quit(2)
		return
	var s := set_scene.instantiate()
	s.name = "forge_citadel"
	root.add_child(s)
	_roots.append(s)
	for id: String in DRAGONS:
		var ps := load(DRAGONS[id]) as PackedScene
		if ps == null:
			push_error("BLENDER_EXPORT: cannot load " + String(DRAGONS[id]))
			continue
		var d := ps.instantiate()
		d.name = id
		d.set_process(false)   # keep the modelled rest pose (wings spread), no flap / idle animation
		root.add_child(d)
		_roots.append(d)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:   # let every _ready build its procedural meshes
		return false
	for r: Node in _roots:
		r.set_process(false)
	var code := _run()
	quit(code)
	return true


func _run() -> int:
	if not _probe:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	var ok := true
	var nodes_info := {"lights": [], "particles": [], "markers": []}
	for r: Node in _roots:
		_strip_non_mesh(r, nodes_info)
		_name_materials(r)
	if _probe:
		print("\n".join(_report))
		return 0
	for r: Node in _roots:
		var fname := "citadel.glb" if r.name == &"forge_citadel" else String(r.name) + ".glb"
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_scene(r, state)
		if err != OK:
			push_error("BLENDER_EXPORT: append_from_scene %s failed (%d)" % [r.name, err])
			ok = false
			continue
		var path := _out_dir.path_join(fname)
		err = doc.write_to_filesystem(state, path)
		if err != OK:
			push_error("BLENDER_EXPORT: write %s failed (%d)" % [path, err])
			ok = false
			continue
		_report.append("WROTE %s (%d bytes)" % [path, FileAccess.get_file_as_bytes(path).size()])
	_write_json(_out_dir.path_join("materials.json"), _mat_info)
	_write_json(_out_dir.path_join("nodes.json"), nodes_info)
	var f := FileAccess.open(_out_dir.path_join("export_report.txt"), FileAccess.WRITE)
	f.store_string("\n".join(_report) + "\n")
	f.close()
	print("\n".join(_report))
	print("BLENDER_EXPORT %s -> %s" % ["OK" if ok else "FAIL", ProjectSettings.globalize_path(_out_dir)])
	return 0 if ok else 1


## Lights, particles and markers are listed in nodes.json (Blender rebuilds its own) and hidden so the glTF holds meshes.
func _strip_non_mesh(r: Node, info: Dictionary) -> void:
	for n: Node in r.find_children("*", "", true, false):
		if n is Light3D:
			var l := n as Light3D
			(info["lights"] as Array).append({"path": String(r.get_path_to(n)), "type": n.get_class(),
				"xform": _xf(l.global_transform), "color": _col(l.light_color), "energy": l.light_energy,
				"range": (l as OmniLight3D).omni_range if l is OmniLight3D else ((l as SpotLight3D).spot_range if l is SpotLight3D else 0.0),
				"visible": l.visible})
		elif n is GPUParticles3D or n is CPUParticles3D:
			(info["particles"] as Array).append({"path": String(r.get_path_to(n)), "type": n.get_class(),
				"xform": _xf((n as Node3D).global_transform)})
		elif n is Marker3D:
			(info["markers"] as Array).append({"path": String(r.get_path_to(n)), "xform": _xf((n as Node3D).global_transform),
				"fov": n.get_meta("fov", 0.0)})
	for n: Node in r.find_children("*", "GPUParticles3D", true, false):
		n.queue_free()
	for n: Node in r.find_children("*", "CPUParticles3D", true, false):
		n.queue_free()


func _name_materials(r: Node) -> void:
	for n: Node in r.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var line := "%s/%s  mesh=%s  surfaces=%d  visible=%s" % [r.name, r.get_path_to(mi), mi.mesh.resource_path.get_file(),
			mi.mesh.get_surface_count(), mi.is_visible_in_tree()]
		_report.append(line)
		for i: int in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			var arrays := mi.mesh.surface_get_arrays(i)
			var nv := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() if arrays.size() > 0 and arrays[Mesh.ARRAY_VERTEX] != null else -1
			var has_col := arrays.size() > Mesh.ARRAY_COLOR and arrays[Mesh.ARRAY_COLOR] != null
			var has_uv := arrays.size() > Mesh.ARRAY_TEX_UV and arrays[Mesh.ARRAY_TEX_UV] != null
			var mname := _material_name(m)
			if m != null and mi.get_surface_override_material(i) == null and mi.material_override == null:
				# the glTF exporter reads the mesh surface material: make sure it carries the name
				var sm := mi.mesh.surface_get_material(i)
				if sm != null:
					sm.resource_name = mname
			_report.append("    surface %d: verts=%d color=%s uv=%s material=%s" % [i, nv, has_col, has_uv, mname])


func _material_name(m: Material) -> String:
	if m == null:
		return "none"
	var key := m.get_instance_id()
	if _materials.has(key):
		return _materials[key]
	var base := ""
	var p := m.resource_path
	if p != "" and not p.contains("::"):
		base = p.get_file().get_basename()
	elif p.contains("::"):
		base = p.get_slice("::", 0).get_file().get_basename() + "_" + p.get_slice("::", 1)
	elif m is ShaderMaterial and (m as ShaderMaterial).shader != null:
		base = (m as ShaderMaterial).shader.resource_path.get_file().get_basename()
	else:
		base = m.get_class().to_lower()
	var name := base
	var k := 2
	while _mat_info.has(name):
		name = "%s_%d" % [base, k]
		k += 1
	m.resource_name = name
	_materials[key] = name
	_mat_info[name] = _describe(m)
	return name


func _describe(m: Material) -> Dictionary:
	var d := {"class": m.get_class(), "path": m.resource_path}
	if m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		d["albedo"] = _col(b.albedo_color)
		d["vertex_color_albedo"] = b.vertex_color_use_as_albedo
		d["metallic"] = b.metallic
		d["roughness"] = b.roughness
		d["emission_enabled"] = b.emission_enabled
		d["emission"] = _col(b.emission)
		d["emission_energy"] = b.emission_energy_multiplier
		d["transparency"] = b.transparency
		d["shading_mode"] = b.shading_mode
		d["cull_mode"] = b.cull_mode
		d["billboard"] = b.billboard_mode
	elif m is ShaderMaterial:
		var sm := m as ShaderMaterial
		d["shader"] = sm.shader.resource_path if sm.shader else ""
		var params := {}
		if sm.shader:
			for u: Dictionary in sm.shader.get_shader_uniform_list():
				var v: Variant = sm.get_shader_parameter(u["name"])
				params[u["name"]] = _jsonable(v)
		d["params"] = params
	return d


func _jsonable(v: Variant) -> Variant:
	if v is Color:
		return _col(v)
	if v is Vector2 or v is Vector3 or v is Vector4:
		return str(v)
	if v is Resource:
		return (v as Resource).resource_path
	if v == null:
		return null
	if v is float or v is int or v is bool or v is String:
		return v
	return str(v)


func _col(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]


func _xf(t: Transform3D) -> Array:
	return [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z,
		t.basis.z.x, t.basis.z.y, t.basis.z.z, t.origin.x, t.origin.y, t.origin.z]


func _write_json(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
