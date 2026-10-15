extends SceneTree
## G-E fixes C (docs/art/ge_fixes_c.md): review items 9 (Sighing Wood), 10 (Ashwind lane), 12 (thatch), 13 (Nature leaves).
## Headless, no level load: the art scenes / scripts with stand-in levels.
##   props      ge_props meshes + scenes load; NO collider anywhere (draw-only); the Oldroot's gap keeps the Signet spot
##              (0, 2.1, 1.15) free of mesh; roots stay inside the thorn ring (r 7); the Warden Gate's tall parts sit
##              inside the gate's own footprint; the hollow glow stays under the bloom cap
##   forest     ForestMood.wants (MISSION_ID m03 only), the forest ground params give a sane BiomeMap (no negative
##              domain rect), paint_ground on a stand-in ground, the placeholder swap (meshes hidden, colliders kept),
##              High: shade = SHADOWS_ONLY, shafts additive + fog_disabled + no_ghost + hidden until the fog says seen;
##              Low: no shade, no shafts; no collider under ForestMood
##   lane       LaneDressing on the real Ashwind layout: enough pieces of every family, deterministic, nothing tall on the
##              road / in the spawn box / on a tower slot / near a Bastion / in a rock block, no collider, <= 18 draws
##   looks      LevelLooks.apply on a plain node does nothing
##   thatch     TavernModel.C_THATCH value <= 0.56, saturation <= 0.46 (G-E 12)
##   leaves     CombatFxG Nature death: leaf size <= 0.12 m, life <= 2.6 s (G-E 13, source guard)
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ge_fixes_c.gd --quit-after 3000

const TASK_ID := "ge_fixes_c"
const OLDROOT := "res://art/environment/ge_props/oldroot.tscn"
const GATE := "res://art/environment/ge_props/warden_gate_art.tscn"
const MESHES: Array[String] = ["oldroot", "warden_gate", "lane_fence", "lane_banner"]
const ASHWIND := "res://data/maps/ashwind_reach_layout.tres"
const SIGNET := Vector3(0.0, 2.1, 1.15)

var _fails: Array[String] = []
var _notes: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_props()
	await _check_forest()
	_check_lane()
	_check_looks()
	_check_thatch()
	_check_leaves()
	for n: String in _notes:
		print("  ", n)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _colliders(n: Node) -> int:
	var c := 0
	if n is CollisionObject3D or n is CollisionShape3D:
		c += 1
	for ch: Node in n.get_children():
		c += _colliders(ch)
	return c


func _verts(mesh: Mesh) -> PackedVector3Array:
	var arr: Array = mesh.surface_get_arrays(0)
	return arr[Mesh.ARRAY_VERTEX]


# ---------------------------------------------------------------- props

func _check_props() -> void:
	for m: String in MESHES:
		var p := "res://art/environment/ge_props/meshes/%s.res" % m
		var mesh := load(p) as Mesh if ResourceLoader.exists(p) else null
		if mesh == null:
			_fails.append("missing mesh %s" % p)
			continue
		var mat := mesh.surface_get_material(0)
		if mat == null or mat.resource_path != "res://art/environment/nature_props/nature_mat.tres":
			_fails.append("%s: surface 0 is not nature_mat" % m)
	for sp: String in [OLDROOT, GATE]:
		if not ResourceLoader.exists(sp):
			_fails.append("missing scene %s" % sp)
			return
		var inst := (load(sp) as PackedScene).instantiate()
		if _colliders(inst) > 0:
			_fails.append("%s has colliders (must be draw-only)" % sp)
		inst.free()
	var o := load("res://art/environment/ge_props/meshes/oldroot.res") as Mesh
	if o:
		var near := 0
		var far_low := 0
		for v: Vector3 in _verts(o):
			if v.distance_to(SIGNET) < 0.3:
				near += 1
			if v.y < 1.2 and Vector2(v.x, v.z).length() > 6.2:
				far_low += 1
		if near > 0:
			_fails.append("Oldroot: %d vertices within 0.3 m of the Signet spot (the gap must stay open)" % near)
		if far_low > 0:
			_fails.append("Oldroot: %d low vertices beyond r 6.2 (roots must stay inside the thorn ring)" % far_low)
		_notes.append("oldroot: %d verts, aabb %s" % [_verts(o).size(), o.get_aabb()])
	var g := load("res://art/environment/ge_props/meshes/warden_gate.res") as Mesh
	if g:
		var out := 0
		for v: Vector3 in _verts(g):
			if v.y > 0.75 and (absf(v.x) > 2.15 or absf(v.z) > 1.1):
				out += 1
		if out > 0:
			_fails.append("Warden Gate: %d tall vertices outside the gate footprint" % out)
	var inst2 := (load(OLDROOT) as PackedScene).instantiate()
	var glow := inst2.get_node_or_null(^"HollowGlow") as MeshInstance3D
	if glow == null:
		_fails.append("Oldroot: no HollowGlow")
	else:
		var gm := glow.material_override as StandardMaterial3D
		if gm == null or gm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or gm.emission_energy_multiplier > 1.6:
			_fails.append("Oldroot glow: must be opaque, emission <= 1.6 (bloom cap)")
	inst2.free()


# ---------------------------------------------------------------- forest

func _stand_in(source: String) -> Node:
	var s := GDScript.new()
	s.source_code = source
	s.reload()
	var n: Node = Node3D.new() if source.begins_with("extends Node3D") else Node.new()
	n.set_script(s)
	return n


func _check_forest() -> void:
	var m03 := _stand_in("extends Node3D\nconst MISSION_ID := &\"m03\"\n")
	var m02 := _stand_in("extends Node3D\nconst MISSION_ID := &\"m02\"\n")
	if not ForestMood.wants(m03) or ForestMood.wants(m02) or ForestMood.wants(Node3D.new()):
		_fails.append("ForestMood.wants: m03 only")
	m02.free()
	# BiomeMap from the forest params: no negative domain rect (a Rect2 with a negative size errors in the engine).
	var bm := BiomeMap.new()
	bm.setup(ForestMood.ground_params())
	for b: StringName in BiomeMap.BIOMES:
		for r: Rect2 in bm.domain(b):
			if r.size.x < 0.0 or r.size.y < 0.0:
				_fails.append("forest BiomeMap domain %s has a negative rect %s" % [b, r])
	if bm.biome_at(Vector2(0.0, 30.0)) != &"old_wood" or bm.biome_at(Vector2(-36.0, 36.0)) != &"meadow":
		_fails.append("forest zones: (0, 30) should be old_wood, the player base meadow (got %s / %s)" % [
			bm.biome_at(Vector2(0.0, 30.0)), bm.biome_at(Vector2(-36.0, 36.0))])
	# A stand-in level: painted ground, a placeholder Oldroot (collider + mesh), a Warden Gate look.
	var ground := MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	var gmat := ShaderMaterial.new()
	gmat.shader = load("res://art/environment/ground.gdshader") as Shader
	ground.material_override = gmat
	m03.add_child(ground)
	var body := StaticBody3D.new()
	body.name = "Oldroot"
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	cs.shape = CylinderShape3D.new()
	body.add_child(cs)
	var ph := MeshInstance3D.new()
	ph.mesh = CylinderMesh.new()
	body.add_child(ph)
	m03.add_child(body)
	var gate := Node3D.new()
	gate.add_to_group(&"warden_gates")
	var look := Node3D.new()
	look.name = "Look"
	gate.add_child(look)
	var foot := MeshInstance3D.new()
	foot.mesh = BoxMesh.new()
	look.add_child(foot)
	var crack := MeshInstance3D.new()
	crack.mesh = QuadMesh.new()
	look.add_child(crack)
	m03.add_child(gate)
	root.add_child(m03)
	# A duck-typed fog (VfxFog's test path) that sees nothing at first (the shafts must stay hidden), then sees all.
	var fog := _stand_in("extends Node\nvar enabled := true\nvar local_team := 0\n" +
		"var see := false\nfunc is_visible(_t: int, _p: Vector3) -> bool:\n\treturn see\n")
	fog.add_to_group(&"fog")
	root.add_child(fog)
	ForestMood.quality_override = 3
	var fm := ForestMood.ensure_for_level(m03)
	if fm == null or ForestMood.ensure_for_level(m03) != fm:
		_fails.append("ForestMood.ensure_for_level: not created / not idempotent")
		return
	for i in 4:
		await process_frame
	if float(gmat.get_shader_parameter(&"biome_amount")) <= 0.0:
		_fails.append("ForestMood: the ground has no biome_amount")
	if ph.visible or body.get_node_or_null(^"OldrootArt") == null or body.collision_layer != 1 or cs.disabled:
		_fails.append("ForestMood: Oldroot swap (placeholder hidden, art added, collider untouched)")
	if foot.visible or not crack.visible or look.get_node_or_null(^"WardenGateArt") == null:
		_fails.append("ForestMood: gate swap (boxes hidden, crack kept, art added)")
	if fm.dress_placeholders() != 0:
		_fails.append("ForestMood: dress_placeholders is not idempotent")
	if fm.shade == null or fm.shade.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
		_fails.append("ForestMood High: no SHADOWS_ONLY canopy shade")
	if fm.shafts == null:
		_fails.append("ForestMood High: no light shafts")
	else:
		if not fm.shafts.get_meta(&"no_ghost", false):
			_fails.append("shafts: no no_ghost meta")
		var code := ((fm.shafts.multimesh.mesh as QuadMesh).material as ShaderMaterial).shader.code
		for need: String in ["blend_add", "fog_disabled", "depth_draw_never", "unshaded"]:
			if code.find(need) < 0:
				_fails.append("light_shaft.gdshader: render_mode lacks %s" % need)
		if fm.shaft_fade(0) != 0.0:
			_fails.append("shafts: shown although the fog sees nothing (VfxFog gate; fade %.2f)" % fm.shaft_fade(0))
		fog.set(&"see", true)   # now the player sees the spot: the shaft fades in
		await create_timer(1.0).timeout
		if fm.shaft_fade(0) <= 0.0:
			_fails.append("shafts: still hidden 1 s after the fog sees them (fade %.2f)" % fm.shaft_fade(0))
	if _colliders(fm) > 0:
		_fails.append("ForestMood: colliders under it")
	_notes.append("forest: shade %d masses, shafts %d" % [fm.shade.multimesh.instance_count if fm.shade else 0,
		fm.shafts.multimesh.instance_count if fm.shafts else 0])
	m03.queue_free()
	fog.queue_free()
	await process_frame
	# Low: no shade, no shafts.
	var low := _stand_in("extends Node3D\nconst MISSION_ID := &\"m03\"\n")
	root.add_child(low)
	ForestMood.quality_override = 0
	var fl := ForestMood.ensure_for_level(low)
	await process_frame
	await process_frame
	if fl == null or fl.shade != null or fl.shafts != null:
		_fails.append("ForestMood Low: shade / shafts must not exist")
	ForestMood.quality_override = -1
	low.queue_free()
	await process_frame


# ---------------------------------------------------------------- lane

func _check_lane() -> void:
	var layout := load(ASHWIND) as Resource
	if layout == null:
		_fails.append("no Ashwind layout")
		return
	var lvl := _stand_in("extends Node3D\nvar layout: Resource\nfunc lane_for(_t: int) -> PackedVector3Array:\n\treturn PackedVector3Array()\n")
	lvl.set(&"layout", layout)
	if not LaneDressing.wants(lvl) or LaneDressing.wants(Node3D.new()):
		_fails.append("LaneDressing.wants")
	MapInfo.setup(float(layout.get(&"size_x")), float(layout.get(&"size_z")), &"ashwind_reach", lvl)
	root.add_child(lvl)
	LaneDressing.quality_override = 0
	if LaneDressing.ensure_for_level(lvl) != null:
		_fails.append("lane: built at Low (must keep the cost before G1)")
	LaneDressing.quality_override = 2
	MapDressingArt.map_detail_override = &"high"
	var d := LaneDressing.ensure_for_level(lvl)
	if d == null:
		_fails.append("LaneDressing not created")
		MapInfo.release(lvl)
		lvl.free()
		return
	var total := 0
	for k: String in d.counts:
		total += int(d.counts[k])
	for need: String in [LaneDressing.KERB, LaneDressing.WAYSTONE, LaneDressing.BANNER, LaneDressing.FENCE,
			LaneDressing.MONUMENT, LaneDressing.BURNT, LaneDressing.GRASS]:
		if int(d.counts.get(need, 0)) < 2:
			_fails.append("lane: too few %s (%d)" % [need.get_file(), int(d.counts.get(need, 0))])
	var again := d.build()
	if again != total:
		_fails.append("lane: not deterministic (%d then %d)" % [total, again])
	if d.get_child_count() > 18:
		_fails.append("lane: %d draws (> 18)" % d.get_child_count())
	if _colliders(d) > 0:
		_fails.append("lane: colliders")
	# Tall pieces: never on the road band, the spawn boxes, tower slots, near a Bastion or in a rock block.
	var tall: Array[String] = [LaneDressing.FENCE, LaneDressing.BANNER, LaneDressing.TRUNK, LaneDressing.BOULDER,
		LaneDressing.MONUMENT, LaneDressing.PILLAR, LaneDressing.WAYSTONE, LaneDressing.CHARRED]
	var bad := 0
	var bad_list: Array[String] = []
	for path: String in tall:
		for xf: Transform3D in d.instance_transforms(path):
			var p := xf.origin
			var hit := false
			if absf(p.z) < 4.6 and absf(p.x) < 72.0:
				hit = true
			elif absf(absf(p.x) - 68.0) < 9.0 and absf(p.z) < 12.0:
				hit = true
			elif Vector2(absf(p.x) - 84.0, p.z).length() < 9.0:
				hit = true
			for s: Vector2 in [Vector2(64, 16), Vector2(46, 11), Vector2(24, 13)]:
				if Vector2(absf(p.x) - s.x, absf(p.z) - s.y).length() < 4.0:
					hit = true
			if hit:
				bad += 1
				if bad_list.size() < 6:
					bad_list.append("%s@%s" % [path.get_file(), p.round()])
	if bad > 0:
		_fails.append("lane: %d tall pieces on the road / spawn box / slot / Bastion (%s)" % [bad, ", ".join(bad_list)])
	# Map detail Low: about half of the small scatter, the landmarks whole.
	MapDressingArt.map_detail_override = &"low"
	var low_total := d.build()
	if low_total >= total or int(d.counts.get(LaneDressing.MONUMENT, 0)) < 2 or low_total > total * 0.85:
		_fails.append("lane: Map detail Low did not thin the scatter (%d vs %d)" % [low_total, total])
	MapDressingArt.map_detail_override = &""
	LaneDressing.quality_override = -1
	_notes.append("lane: %d pieces (%d at Map detail Low), %d draws" % [total, low_total, d.get_child_count()])
	MapInfo.release(lvl)
	lvl.queue_free()


func _check_looks() -> void:
	var n := Node3D.new()
	root.add_child(n)
	var looks := load("res://art/environment/level_looks.gd") as Script
	if looks == null or int(looks.call(&"apply", n)) != 0 or n.get_child_count() != 0:
		_fails.append("LevelLooks.apply dressed a plain node")
	n.queue_free()


func _check_thatch() -> void:
	var c: Variant = (load("res://art/buildings/tavern/tavern_model.gd") as Script).get_script_constant_map().get("C_THATCH")
	if not (c is Color):
		_fails.append("no TavernModel.C_THATCH")
		return
	var col := c as Color
	if col.v > 0.56 or col.s > 0.46:
		_fails.append("thatch too loud: v %.2f s %.2f" % [col.v, col.s])


func _check_leaves() -> void:
	var f := FileAccess.open("res://art/vfx/combat_g/combat_fx_g.gd", FileAccess.READ)
	if f == null:
		_fails.append("no combat_fx_g.gd")
		return
	var src := f.get_as_text()
	var a := src.find("# Nature: a burst of small leaves")
	var b := src.find("_:   # Neutral", a)
	if a < 0 or b < 0:
		_fails.append("leaves: Nature death block not found")
		return
	var block := src.substr(a, b - a)
	if block.find("randf_range(0.08, 0.12) * s") < 0 or block.find("randf_range(1.8, 2.6)") < 0:
		_fails.append("leaves: Nature death leaves are not the G-E 13 size / life (0.08-0.12 m, 1.8-2.6 s)")
