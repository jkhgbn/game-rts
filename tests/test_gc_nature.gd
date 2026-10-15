extends SceneTree
## G-C Nature units (docs/art/gc_nature_units.md): the Nature army's look pass keeps every contract.
## - nature_living.gdshader (the Nature palette's shader) keeps the kit slot map (ao 1 / 2, hit_flash 3, flash_color 4,
##   kit_detail 12), includes the G3b paint layer, keeps the hit flash, its tier uniform kit_detail defaults to 0 (Low),
##   and takes derivatives (fwidth / dFdx / dFdy) only at the top of fragment() or inside the uniform bump branch.
## - Every unit_painted / nature_living material under art/units/nature/ parses (no garbled value line, e.g. the old
##   stagrunner `rim_strength = 0.95, 1.0, 0.8S`) and carries a surface_kind in 0..7; the Nature palette sits on
##   nature_living; the team-colour materials still recolour.
## - The UV tags: NatureModel.leaf_mesh (UV.x -3..-2), thorn_cone / thorn_tagged (-5..-4), and cluster_mesh /
##   GroveKinModel.bake keep them; kit primitives never fall in a tag range.
## - Hall units + worker: exported contract values, pivots and named nodes the game / tests read, body vertices and draw
##   instances inside the Art Lab budgets (face apart), hit flash lands, set_team_color recolours, kit_detail written.
## - Every Nature roster scene instantiates and stays in budget.
## Run: $GODOT --headless --path . -s tests/test_gc_nature.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS gc_nature" or "FAIL gc_nature: <reasons>".

const TASK_ID := "gc_nature"
const DIR := "res://art/units/nature/"
const SHADER := "res://art/units/nature/nature_living.gdshader"
const INC := "res://art/units/kit/unit_paint.gdshaderinc"
const HALL := {
	"sprigling": {"body_height": 1.2, "attack_style": &"worker_pick"},
	"thornling": {"body_height": 1.4, "attack_style": &"claw_frenzy"},
	"burr_slinger": {"body_height": 1.5, "attack_style": &"pod_shot", "attack_windup": 0.12},
	"bloomtender": {"body_height": 1.6, "attack_style": &"censer_fling", "attack_windup": 0.12},
	"bramblehorn": {"body_height": 2.2, "attack_style": &"horn_gore"},
}
const NODES := {
	"sprigling": ["Root/Hips/LegL", "Root/Hips/LegR", "Root/Chest/Head", "Root/Chest/ArmL", "Root/Chest/ArmR", "Fx",
		"Shadow", "Root/Chest/Head/Sprout", "Root/Chest/Crystals", "Root/Chest/ArmR/MineSparks"],
	"thornling": ["Root/Hips/LegL", "Root/Hips/LegR", "Root/Chest/Head", "Root/Chest/ArmL", "Root/Chest/ArmR", "Fx",
		"Shadow", "Root/Chest/Head/VetTrim"],
	"burr_slinger": ["Root/Chest/ArmR/Tip", "Root/Chest/ArmR/Seeds", "Root/Chest/ArmR/Burr", "Fx", "Shadow"],
	"bloomtender": ["Root/Chest/Head/Hat", "Root/Chest/Head/Hat/HatMesh", "Root/Chest/ArmR/Censer", "Fx", "Shadow"],
	"bramblehorn": ["Root/Mount", "Root/Mount/Head", "Root/Mount/LegFL", "Root/Mount/LegBR", "Fx", "Shadow"],
}
## [scene, body vertex budget, draw budget] (tools/art_lab/lab_budgets.gd: soldier / worker 2500 + 14, heavy soft
## 6000 + 16). The two stag riders (grove_stag mount + rider, the mount is not art/units/nature) were already 20 draw
## instances / ~11 k vertices before G-C (Art Lab B2 FAIL, docs/art/gc_nature_units.md): capped at that, no regression.
const ROSTER: Array = [
	["sprigling", 2500, 14], ["thornling", 2500, 14], ["burr_slinger", 2500, 14], ["bloomtender", 2500, 14],
	["bramblehorn", 6000, 16], ["sapling", 2500, 14], ["vinelasher/vinelasher", 2500, 14],
	["wildwood_archer/wildwood_archer", 2500, 14], ["bramblesage/bramblesage", 2500, 14],
	["thistle_darter/thistle_darter", 2500, 14], ["greenheart_oathkeeper/greenheart_oathkeeper", 6000, 16],
	["spirit_wolf/spirit_wolf", 2500, 14], ["stagrunner/stagrunner", 12500, 20], ["glade_outrider/glade_outrider", 12500, 20],
	["thornback_charger/thornback_charger", 6000, 16], ["bramble_harrier/bramble_harrier", 6000, 16],
]
const FACE_ALLOWANCE := 800

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	_world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 9, 12), Vector3.ZERO)   # close: the models stay on LOD tier 0
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_shader_checks()
	_material_checks()
	_tag_checks()
	for id: String in HALL:
		await _hall(id)
	await _ysolde()
	var x := -14.0
	for r: Array in ROSTER:
		await _budget(r[0], r[1], r[2], x)
		x += 2.0
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _shader_checks() -> void:
	var code := FileAccess.get_file_as_string(SHADER)
	_check(code.contains('#include "%s"' % INC), "nature_living includes the G3b paint layer")
	for want: String in ["instance uniform float ao_bottom : instance_index(1)", "instance uniform float ao_height : instance_index(2)",
			"instance uniform float hit_flash : instance_index(3)", "instance uniform vec3 flash_color : instance_index(4)",
			"instance uniform float kit_detail : instance_index(12) = 0.0;", "flash_color * hit_flash * 2.0"]:
		_check(code.contains(want), "nature_living keeps `%s`" % want)
	_check(code.count("instance uniform ") == 5, "nature_living declares only the kit's 5 instance uniforms")
	# Derivatives: fwidth once and dFdx / dFdy once (bark textureGrad), all before the first branch; up_bump is in the include.
	var frag := code.substr(code.find("void fragment()"))
	var first_if := frag.find("if (")
	var fw := frag.find("fwidth(")
	_check(frag.count("fwidth(") == 1 and fw >= 0 and fw < first_if, "fwidth taken once at the top of fragment()")
	for fn: String in ["dFdx(", "dFdy("]:
		var at := frag.find(fn)
		_check(at >= 0 and at < first_if and frag.count(fn) == 1, "%s only at the top of fragment() (bark textureGrad)" % fn)
	_check(frag.contains("textureGrad(noise_tex, buv, bark_gx, bark_gy)"), "bark reads use textureGrad (no atan mip seam)")
	# Every `uniform float` that names a tier defaults to 0.
	for line: String in code.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("uniform") and (l.contains("tier") or l.contains("quality")):
			_check(l.contains("= 0.0") or l.contains("= 0;"), "tier uniform defaults to 0: %s" % l)
	var sh := load(SHADER) as Shader
	_check(sh != null, "nature_living.gdshader loads")
	var names := CharacterModel.instance_uniforms_of(load(DIR + "materials/nature_bark.tres"))
	_check(names.has("hit_flash") and names.has("kit_detail"), "the kit sees hit_flash / kit_detail on nature_bark (%s)" % names)


func _material_checks() -> void:
	var garbled := RegEx.create_from_string("(?m)^shader_parameter/\\w+ = [-\\d.]+, ")
	var n := 0
	for f: String in _files(DIR, "tres"):
		var text := FileAccess.get_file_as_string(f)
		_check(garbled.search(text) == null, "%s: no garbled value line" % f)
		if not (text.contains("unit_painted.gdshader") or text.contains("nature_living.gdshader")):
			continue
		n += 1
		var m := load(f) as ShaderMaterial
		_check(m != null, "%s loads" % f)
		if m == null:
			continue
		var k: Variant = m.get_shader_parameter(&"surface_kind")
		_check(k != null and int(k) >= 0 and int(k) <= 7, "%s surface_kind in 0..7 (got %s)" % [f, k])
		if text.contains("shader_parameter/rim_strength"):
			_check(m.get_shader_parameter(&"rim_strength") is float, "%s rim_strength is a float" % f)
	print("  painted Nature materials: ", n)
	for f: String in ["nature_bark", "nature_bark_dark", "nature_cloth", "nature_cloth_dark", "nature_leaf", "nature_thorn"]:
		var m := load(DIR + "materials/%s.tres" % f) as ShaderMaterial
		_check(m != null and m.shader.resource_path == SHADER, "%s on nature_living" % f)
	for f: String in ["stagrunner_blade", "stagrunner_leaf_amber", "stagrunner_leaf_gold"]:
		var m := load(DIR + "stagrunner/materials/%s.tres" % f) as ShaderMaterial
		_check(m != null and is_equal_approx(float(m.get_shader_parameter(&"rim_strength")), 0.5),
			"%s rim_strength fixed to 0.5" % f)
	var tv := CharacterModel._team_variant(load(DIR + "materials/nature_cloth.tres"), Color(0.2, 0.4, 0.9)) as ShaderMaterial
	_check(tv != null and tv.shader.resource_path == SHADER and tv.get_shader_parameter(&"base_color") == Color(0.2, 0.4, 0.9),
		"nature_cloth team variant recolours on nature_living")


func _tag_checks() -> void:
	var lu: PackedVector2Array = NatureModel.leaf_mesh().surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	_check(_all_in(lu, -3.0, -2.0), "leaf_mesh UV.x in -3..-2")
	var tu: PackedVector2Array = NatureModel.thorn_cone(0.05, 0.2).surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	_check(_all_in(tu, -5.0, -4.0), "thorn_cone UV.x in -5..-4")
	var xs: Array[Transform3D] = [Transform3D.IDENTITY, Transform3D(Basis(), Vector3(1, 0, 0))]
	var cm := NatureModel.cluster_mesh("gc_test_cluster", NatureModel.leaf_mesh(), xs)
	_check(_all_in(cm.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV], -3.0, -2.0), "cluster_mesh keeps the leaf tag")
	var bk := GroveKinModel.bake("gc_test_bake", [[NatureModel.leaf_mesh(), Transform3D.IDENTITY, null]])
	_check(_all_in(bk.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV], -3.0, -2.0), "GroveKinModel.bake keeps the leaf tag")
	var tt := NatureModel.thorn_tagged("gc_test_tt", CharacterModel.cyl(0.0, 0.1, 0.5, 6), Vector3(0, -0.25, 0), Vector3(0, 0.25, 0))
	_check(_all_in(tt.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV], -5.0, -4.0), "thorn_tagged UV.x in -5..-4")
	for prim: Mesh in [CharacterModel.sphere(0.2), CharacterModel.cyl(0.1, 0.2, 0.3, 8), CharacterModel.capsule(0.1, 0.5)]:
		var pu: PackedVector2Array = prim.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		var bad := false
		for u: Vector2 in pu:
			bad = bad or u.x < -1.0
		_check(not bad, "kit primitive %s never falls in a tag range" % prim)


func _all_in(uv: PackedVector2Array, lo: float, hi: float) -> bool:
	if uv.is_empty():
		return false
	for u: Vector2 in uv:
		if u.x < lo - 0.001 or u.x > hi + 0.001:
			return false
	return true


func _files(dir: String, ext: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.get_extension() == ext:
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		out.append_array(_files(dir.path_join(sub), ext))
	return out


func _hall(id: String) -> void:
	var p := DIR + id + ".tscn"
	var ps := load(p) as PackedScene
	_check(ps != null, "%s loads" % p)
	if ps == null:
		return
	var m := ps.instantiate() as Node3D
	_world.add_child(m)
	await process_frame
	await process_frame
	var want: Dictionary = HALL[id]
	for k: String in want:
		var got: Variant = m.get(k)
		var ok: bool = is_equal_approx(float(got), float(want[k])) if want[k] is float else got == want[k]
		_check(ok, "%s %s = %s (want %s)" % [id, k, got, want[k]])
	for path: String in NODES[id]:
		_check(m.get_node_or_null(NodePath(path)) != null, "%s has %s" % [id, path])
	# The Nature palette reaches the merged body, with leaf-tagged surfaces on it.
	var living := false
	var tagged := false
	for gi: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := gi as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var mt := mi.mesh.surface_get_material(s) as ShaderMaterial
			if mt and mt.shader and mt.shader.resource_path == SHADER:
				living = true
				var uv: Variant = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_TEX_UV]
				if uv is PackedVector2Array:
					for u: Vector2 in uv:
						if u.x < -1.5:
							tagged = true
							break
	_check(living, "%s draws nature_living surfaces" % id)
	_check(tagged, "%s has leaf / thorn UV-tagged surfaces" % id)
	m.call(&"play_hit")
	await process_frame
	var flashed := false
	for gi: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var v: Variant = (gi as GeometryInstance3D).get_instance_shader_parameter(&"hit_flash")
		if v != null and float(v) > 0.0:
			flashed = true
			break
	_check(flashed, "%s play_hit flashes the body" % id)
	var detail_ok := true
	for gi: GeometryInstance3D in (m as CharacterModel)._flash_all_targets:
		var dv: Variant = gi.get_instance_shader_parameter(&"kit_detail")
		detail_ok = detail_ok and dv != null and is_equal_approx(float(dv), CharacterModel.detail_tier())
	_check(detail_ok, "%s kit_detail written on every painted draw instance" % id)
	m.queue_free()
	await process_frame


## Ysolde (G3a hero) borrows nature_bark / nature_leaf / nature_leaf_dark (belt, satchel, vine, head leaf ring): they are
## on nature_living now (accepted after hero shots, docs/art/gc_nature_units.md); her glow and hit flash must still work.
func _ysolde() -> void:
	var ps := load("res://art/units/wizards/ysolde.tscn") as PackedScene
	_check(ps != null, "ysolde.tscn loads")
	if ps == null:
		return
	var m := ps.instantiate() as Node3D
	_world.add_child(m)
	await process_frame
	await process_frame
	var living := false
	var glow := false
	for gi: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var g := gi as GeometryInstance3D
		var gb: Variant = g.get_instance_shader_parameter(&"glow_boost")
		glow = glow or (gb != null and float(gb) > 0.0 and g.visible)
		if g is MeshInstance3D and (g as MeshInstance3D).mesh:
			var mesh := (g as MeshInstance3D).mesh
			for s: int in mesh.get_surface_count():
				var mt := mesh.surface_get_material(s) as ShaderMaterial
				living = living or (mt != null and mt.shader != null and mt.shader.resource_path == SHADER)
	_check(living, "Ysolde draws her borrowed Nature palette parts on nature_living")
	_check(glow, "Ysolde keeps a visible glow (glow_boost > 0)")
	m.call(&"play_hit")
	await process_frame
	var flashed := false
	for gi: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var v: Variant = (gi as GeometryInstance3D).get_instance_shader_parameter(&"hit_flash")
		flashed = flashed or (v != null and float(v) > 0.0)
	_check(flashed, "Ysolde play_hit flashes her body")
	m.queue_free()
	await process_frame


func _budget(id: String, vert_budget: int, draw_budget: int, x: float) -> void:
	var ps := load(DIR + id + ".tscn") as PackedScene
	_check(ps != null, "%s loads" % id)
	if ps == null:
		return
	var m := ps.instantiate() as Node3D
	m.position = Vector3(x, 0, 0)
	_world.add_child(m)
	await process_frame
	await process_frame
	var c: Array[int] = [0, 0, 0]
	_count(m, c)
	var body: int = c[1] + maxi(c[2] - FACE_ALLOWANCE, 0)
	print("  %s: body %d verts (face %d), %d draw instances" % [id, c[1], c[2], c[0]])
	_check(body <= vert_budget, "%s body vertices %d <= %d" % [id, body, vert_budget])
	_check(c[0] <= draw_budget, "%s draw instances %d <= %d" % [id, c[0], draw_budget])
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", Color(0.2, 0.4, 0.9))
		await process_frame
		var blue := false
		for gi: Node in m.find_children("*", "MeshInstance3D", true, false):
			var mi := gi as MeshInstance3D
			var mats: Array[Material] = [mi.material_override]
			if mi.mesh:
				for s: int in mi.mesh.get_surface_count():
					mats.append(mi.get_surface_override_material(s))
			for mt: Material in mats:
				if mt is ShaderMaterial and mt.has_meta(&"team_base"):
					blue = true
		_check(blue, "%s set_team_color recolours its cloth" % id)
	m.queue_free()
	await process_frame


## c = [draw instances, body vertices, face vertices] of what is visible at rest.
func _count(n: Node, c: Array[int]) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is GPUParticles3D and (n as GPUParticles3D).emitting:
		c[0] += 1
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		var v := 0
		for s: int in mi.mesh.get_surface_count():
			v += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if String(n.name).containsn("face"):
			c[2] += v
		else:
			c[1] += v
		c[0] += 1
	for ch: Node in n.get_children():
		_count(ch, c)
