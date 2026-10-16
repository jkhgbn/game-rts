extends SceneTree
## G-F root-cause pass (CLAUDE.md "Recurring bugs", docs/art/gf_billboard.md): a billboard particle material
## (StandardMaterial3D billboard_mode PARTICLES / ENABLED, or a ShaderMaterial that billboards in vertex()) rebuilds
## the model matrix from normalised camera axes, so the particle's scale (ParticleProcessMaterial scale_min / scale_max /
## scale_curve, CPUParticles3D scale_amount_*) is dropped unless `billboard_keep_scale` is set: every particle drew at
## the full quad size (motes meant 0.06 m drew 0.7 m, smoke, flames, build dust...).
##  A  runtime: every building / unit model scene under art/buildings, art/units (+ art/vfx scenes) is instanced in
##     several states (built + tier 3 + damaged, construction site, destroyed, unit death) and every GPUParticles3D /
##     CPUParticles3D is checked: a billboard draw material without keep scale whose process scale is not ~1 (or that
##     has a scale curve) is a FAIL. A sized quad (MoteCap style: the size in the quad, scale ~1) is OK.
##  B  source: every `billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES` in art/ and scripts/vfx/ GDScript (static
##     VFX makers too) sets `billboard_keep_scale = true` on the same material within the next lines, and every
##     scene / resource under art/ with billboard_mode 3 has keep scale. art/environment and art/cinematics are
##     printed as notes (other owners), not failed.
## The High-only emitters exist only at High: run with `-- --gfx=high` for the full list (CI runs it at Low; the
## per-model quality overrides below force the High unit emitters either way).
## Run: $GODOT --headless --path . -s tests/test_gf_billboard_scale.gd --fixed-fps 60 --quit-after 4000 [-- --gfx=high]
## Prints "PASS gf_billboard_scale (N scenes, M emitters)" or "FAIL gf_billboard_scale: <list>".

const TASK_ID := "gf_billboard_scale"
const SCENE_ROOTS: Array[String] = ["res://art/buildings", "res://art/units", "res://art/vfx"]
const SKIP_DIRS: Array[String] = ["_effort_trial", "tools", "parts", "preview", "materials", "shots", "combat_g",
		"spells_g", "textures", "meshes"]
const SRC_ROOTS: Array[String] = ["res://art", "res://scripts/vfx"]
const NOTE_ONLY: Array[String] = ["res://art/environment", "res://art/cinematics"]
## How far below a billboard_mode line keep_scale must appear (same material variable).
const SRC_WINDOW := 14
const SCALE_TOL := 0.15
const SPACING := 30.0

var _fails: PackedStringArray = PackedStringArray()
var _notes: PackedStringArray = PackedStringArray()
var _world: Node3D
var _models: Array[Node] = []
var _names: PackedStringArray = PackedStringArray()
var _checked := 0
var _seen := {}


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_run()


func _force_quality(q: int) -> void:
	IceModel.snow_quality_override = q
	ShadowModel.wisp_quality_override = q
	WizardModel.aura_quality_override = q
	CreatureSignature.quality_override = q


func _skip(dir: String) -> bool:
	return SKIP_DIRS.has(dir) or dir.begins_with(".")


func _walk(dir: String, ext: Array[String], out: PackedStringArray) -> void:
	for f: String in DirAccess.get_files_at(dir):
		for e: String in ext:
			if f.ends_with(e):
				out.append(dir + "/" + f)
	for d: String in DirAccess.get_directories_at(dir):
		if not _skip(d):
			_walk(dir + "/" + d, ext, out)


func _is_preview(path: String) -> bool:
	return path.get_file().ends_with("_preview.tscn") or path.get_file().begins_with("preview_")


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _add(path: String, i: int, tag: String) -> Node3D:
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var n := ps.instantiate()
	var m := n as Node3D
	if m == null:
		n.free()
		return null
	m.position = Vector3(float(i % 12) * SPACING, 0, floorf(float(i) / 12.0) * SPACING)
	_world.add_child(m)
	_models.append(m)
	_names.append("%s%s" % [path.get_file().get_basename(), tag])
	return m


func _run() -> void:
	_force_quality(3)
	_check_sources()
	var paths := PackedStringArray()
	for r: String in SCENE_ROOTS:
		_walk(r, [".tscn"], paths)
	var i := 0
	var states: Array = []   # [node, kind]
	for p: String in paths:
		if _is_preview(p):
			continue
		var m := _add(p, i, "")
		i += 1
		if m == null:
			continue
		var is_building: bool = m.has_method(&"set_construction_progress")
		if is_building:
			var site := _add(p, i, "@site")
			i += 1
			var dead := _add(p, i, "@destroyed")
			i += 1
			states.append([m, &"built"])
			states.append([site, &"site"])
			states.append([dead, &"destroyed"])
		elif m.has_method(&"play_death"):
			var corpse := _add(p, i, "@death")
			i += 1
			states.append([corpse, &"death"])
	await _frames(3)
	for s: Array in states:
		var n: Node = s[0]
		if n == null or not is_instance_valid(n):
			continue
		match s[1]:
			&"built":
				if n.has_method(&"set_tier"):
					n.call(&"set_tier", 3)
				if n.has_method(&"set_health_ratio"):
					n.call(&"set_health_ratio", 0.2)
			&"site":
				n.call(&"set_construction_progress", 0.3)
			&"destroyed":
				if n.has_method(&"set_health_ratio"):
					n.call(&"set_health_ratio", 0.1)
				if n.has_method(&"play_destroyed"):
					n.call(&"play_destroyed")
			&"death":
				n.call(&"play_death")
	await _frames(20)
	for k: int in _models.size():
		if is_instance_valid(_models[k]):
			_check_tree(_models[k], _names[k])
	for f: String in _notes:
		print("  note: ", f)
	if _fails.is_empty():
		print("PASS %s (%d scenes, %d emitters, tier %d)" % [TASK_ID, paths.size(), _checked,
				GameSettings.effective_graphics_quality()])
	else:
		for f: String in _fails:
			print("  ", f)
		print("FAIL %s: %d billboard emitters drop their scale (first: %s)" % [TASK_ID, _fails.size(), _fails[0]])
	quit(0)


# --- A: runtime

func _check_tree(n: Node, model: String) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D:
			_check_gpu(c as GPUParticles3D, model, n)
		elif c is CPUParticles3D:
			_check_cpu(c as CPUParticles3D, model)
		_check_tree(c, model)


func _materials_of_mesh(mesh: Mesh, out: Array[Material]) -> void:
	if mesh == null:
		return
	if mesh is PrimitiveMesh and (mesh as PrimitiveMesh).material != null:
		out.append((mesh as PrimitiveMesh).material)
	for s: int in mesh.get_surface_count():
		var m := mesh.surface_get_material(s)
		if m != null:
			out.append(m)


## "" = scale kept (or not a billboard); else how the material billboards.
func _drops_scale(m: Material) -> String:
	var bm := m as BaseMaterial3D
	if bm != null:
		if bm.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED or bm.billboard_mode == BaseMaterial3D.BILLBOARD_FIXED_Y:
			return ""
		return "" if bm.billboard_keep_scale else "billboard %d" % bm.billboard_mode
	var sm := m as ShaderMaterial
	if sm != null and sm.shader != null:
		var code: String = sm.shader.code
		if code.contains("INV_VIEW_MATRIX") and code.contains("MODELVIEW_MATRIX") and not code.contains("length(MODEL_MATRIX"):
			return "shader billboard (%s)" % sm.shader.resource_path.get_file()
	return ""


func _scale_off(lo: float, hi: float, curve: bool) -> String:
	if curve:
		return "scale curve"
	if absf(hi - 1.0) > SCALE_TOL or absf(lo - 1.0) > maxf(SCALE_TOL, 0.5):
		return "scale %.2f-%.2f" % [lo, hi]
	return ""


func _check_gpu(p: GPUParticles3D, model: String, owner_root: Node) -> void:
	_checked += 1
	var pm := p.process_material as ParticleProcessMaterial
	if pm == null:
		return
	var off := _scale_off(pm.scale_min, pm.scale_max, pm.scale_curve != null)
	if off == "":
		return
	var mats: Array[Material] = []
	if p.material_override != null:
		mats.append(p.material_override)
	else:
		for k: int in p.draw_passes:
			_materials_of_mesh(p.get(StringName("draw_pass_%d" % (k + 1))) as Mesh, mats)
	for m: Material in mats:
		var why := _drops_scale(m)
		if why != "":
			var q := _quad_size(p.draw_pass_1)
			var peak := _curve_peak(pm.scale_curve)
			_report(model, String(_path_of(p)), "%s, %s | quad %.2f drew %.2f m, meant %.2f-%.2f m (curve peak %.2f)" % [
					why, off, q, q, q * pm.scale_min * peak, q * pm.scale_max * peak, peak])
			return


func _check_cpu(p: CPUParticles3D, model: String) -> void:
	_checked += 1
	var off := _scale_off(p.scale_amount_min, p.scale_amount_max, p.scale_amount_curve != null)
	if off == "":
		return
	var mats: Array[Material] = []
	if p.material_override != null:
		mats.append(p.material_override)
	else:
		_materials_of_mesh(p.mesh, mats)
	for m: Material in mats:
		var why := _drops_scale(m)
		if why != "":
			_report(model, String(_path_of(p)), "CPU %s, %s" % [why, off])
			return


func _path_of(n: Node) -> NodePath:
	var r: Node = n
	while r.get_parent() != _world and r.get_parent() != null:
		r = r.get_parent()
	return r.get_path_to(n)


## Peak of a scale curve (1 without one).
func _curve_peak(t: Texture2D) -> float:
	var ct := t as CurveTexture
	if ct == null or ct.curve == null:
		return 1.0
	var mx := 0.0
	for k: int in 21:
		mx = maxf(mx, ct.curve.sample(float(k) / 20.0))
	return mx


func _quad_size(mesh: Mesh) -> float:
	if mesh == null:
		return 0.0
	var a := mesh.get_aabb().size
	return maxf(a.x, a.y)


func _report(model: String, node: String, what: String) -> void:
	# one line per scene / emitter name (instances of the same scene in other states repeat it)
	var key := "%s|%s" % [model.get_slice("@", 0), node]
	if _seen.has(key):
		return
	_seen[key] = true
	_fails.append("%s: %s (%s)" % [model, node, what])


# --- B: source

func _note_only(path: String) -> bool:
	for r: String in NOTE_ONLY:
		if path.begins_with(r):
			return true
	return false


func _check_sources() -> void:
	var files := PackedStringArray()
	for r: String in SRC_ROOTS:
		_walk_all(r, [".gd"], files)
	for f: String in files:
		_check_gd(f)
	var res := PackedStringArray()
	_walk_all("res://art", [".tscn", ".tres"], res)
	for f: String in res:
		_check_res(f)


func _walk_all(dir: String, ext: Array[String], out: PackedStringArray) -> void:
	for f: String in DirAccess.get_files_at(dir):
		for e: String in ext:
			if f.ends_with(e):
				out.append(dir + "/" + f)
	for d: String in DirAccess.get_directories_at(dir):
		if not d.begins_with(".") and d != "_effort_trial":
			_walk_all(dir + "/" + d, ext, out)


func _check_gd(path: String) -> void:
	var lines := FileAccess.get_file_as_string(path).split("\n")
	for i: int in lines.size():
		var l: String = lines[i]
		var at := l.find(".billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES")
		if at < 0 or l.strip_edges().begins_with("#"):
			continue
		var v: String = l.substr(0, at).strip_edges()
		var ok := false
		for j: int in range(i + 1, mini(i + 1 + SRC_WINDOW, lines.size())):
			if lines[j].contains(v + ".billboard_keep_scale = true"):
				ok = true
				break
		if not ok:
			var msg := "%s:%d %s billboard particles without keep_scale" % [path.trim_prefix("res://"), i + 1, v]
			if _note_only(path):
				_notes.append(msg)
			else:
				_fails.append(msg)


func _check_res(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if not text.contains("billboard_mode = 3"):
		return
	# per sub-resource block: billboard_mode = 3 needs billboard_keep_scale = true in the same block
	var blocks := text.split("\n[")
	for b: String in blocks:
		if b.contains("billboard_mode = 3") and not b.contains("billboard_keep_scale = true"):
			var head: String = b.get_slice("\n", 0)
			var msg := "%s [%s billboard particles without keep_scale" % [path.trim_prefix("res://"), head.left(70)]
			if _note_only(path):
				_notes.append(msg)
			else:
				_fails.append(msg)
