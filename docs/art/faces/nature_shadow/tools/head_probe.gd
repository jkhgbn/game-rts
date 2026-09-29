extends SceneTree
## Dumps the head pivots' parts (model-space, pre-merge) of the nature / shadow models.

const SCENES := [
	"res://art/units/nature/sprigling.tscn", "res://art/units/nature/sapling.tscn", "res://art/units/nature/bloomtender.tscn",
	"res://art/units/nature/thornling.tscn", "res://art/units/nature/bramblehorn.tscn", "res://art/units/nature/burr_slinger.tscn",
	"res://art/units/nature/vinelasher/vinelasher.tscn", "res://art/units/nature/wildwood_archer/wildwood_archer.tscn",
	"res://art/units/nature/thistle_darter/thistle_darter.tscn", "res://art/units/nature/greenheart_oathkeeper/greenheart_oathkeeper.tscn",
	"res://art/units/nature/glade_outrider/glade_outrider.tscn", "res://art/units/nature/stagrunner/stagrunner.tscn",
	"res://art/units/nature/briar_roc/briar_roc.tscn", "res://art/units/nature/mossback/mossback.tscn",
	"res://art/units/shadow/gloom_thrall.tscn", "res://art/units/shadow/shade.tscn", "res://art/units/shadow/shadow_knight.tscn",
	"res://art/units/shadow/nightbolt.tscn", "res://art/units/shadow/grave_hound.tscn", "res://art/units/shadow/barrow_ghoul/barrow_ghoul.tscn",
	"res://art/units/shadow/bleakbow/bleakbow.tscn", "res://art/units/shadow/hexweaver/hexweaver.tscn",
	"res://art/units/shadow/hollow_oathsworn/hollow_oathsworn.tscn", "res://art/units/shadow/nightblood_reaver/nightblood_reaver.tscn",
	"res://art/units/shadow/gloam_rider/gloam_rider.tscn", "res://art/units/shadow/barrow_giant/barrow_giant.tscn",
]

var only := ""


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	_run.call_deferred()


func _run() -> void:
	for p: String in SCENES:
		if only != "" and not p.contains(only):
			continue
		var ps := load(p) as PackedScene
		var m := ps.instantiate() as Node3D
		print("##### ", p, "  body_height=", m.get(&"body_height"), "  (authored, before _ready)")
		_dump(m, m, 0)
		root.add_child(m)
		await process_frame
		print("  ---- after _ready")
		_dump(m, m, 0)
		m.queue_free()
		await process_frame
	quit(0)


func _dump(model: Node3D, n: Node, depth: int) -> void:
	for c: Node in n.get_children():
		if not c is Node3D:
			continue
		var nm := String(c.name)
		var path := String(model.get_path_to(c))
		var head_ish := path.contains("Head") or path.contains("Mount") or path.contains("Rider") or path.contains("Canopy") or path.contains("Hat") or path.contains("Hood")
		if c is MeshInstance3D and head_ish:
			var mi := c as MeshInstance3D
			var xf := _mx(model, mi)
			var aabb := xf * mi.get_aabb() if mi.mesh else AABB()
			var cnt := 0
			if mi.mesh:
				for s: int in mi.mesh.get_surface_count():
					cnt += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			print("  %s  mesh=%s verts=%d  aabb_c=%s size=%s  mat=%s" % [path, mi.mesh.get_class() if mi.mesh else "-", cnt,
				str(aabb.get_center()).replace(" ", ""), str(aabb.size).replace(" ", ""), _matname(mi)])
		elif c is Node3D and (nm.contains("Head") or nm == "Mount" or nm.contains("Rider") or nm == "Seat"):
			var xf := _mx(model, c as Node3D)
			print("  [pivot] %s at %s  script=%s" % [path, str(xf.origin).replace(" ", ""), c.get_script().resource_path if c.get_script() else ""])
		_dump(model, c, depth + 1)


func _matname(mi: MeshInstance3D) -> String:
	var m := mi.material_override
	if m == null and mi.mesh and mi.mesh.get_surface_count() > 0:
		m = mi.mesh.surface_get_material(0)
	if m == null:
		return "-"
	var s := m.resource_path.get_file() if m.resource_path != "" else m.resource_name
	if m is ShaderMaterial:
		var bc: Variant = (m as ShaderMaterial).get_shader_parameter(&"base_color")
		if bc is Color:
			s += " " + (bc as Color).to_html(false)
	elif m is StandardMaterial3D:
		s += " " + (m as StandardMaterial3D).albedo_color.to_html(false)
	if mi.mesh and mi.mesh.get_surface_count() > 1:
		s += " (+%d surf)" % (mi.mesh.get_surface_count() - 1)
	return s


func _mx(model: Node3D, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var c: Node = n
	while c and c != model:
		xf = (c as Node3D).transform * xf
		c = c.get_parent()
	return xf
