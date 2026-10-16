extends SceneTree
## G-F round 3 leftovers (docs/art/gf_r3_leftovers.md; gf_review3 "black square pit" + gf_r3_sites follow-ups).
## Run: godot --headless --path . -s tests/test_gf_r3_leftovers.gd --fixed-fps 60 --quit-after 2400
## Checks:
## - Ember Hall chimney: seen from straight above, most of the mouth (r < 0.85 m) shows a glow surface (the dark
##   ember-red floor / coal bed), not a dark cap; the floor glow stays dark ember red (peak value well under 0.72);
##   a rounded lip (torus, > 60 vertices) and a collar of >= 8 sides.
## - Cold site: the body's crack / lava-line emission is 0 at 30 % and the chimney mouth hidden, both back when built.
## - Grass: every site pad carries `_grass_clear_rect` covering its mesh; GroundDetail.site_pad_box gives the world box
##   (rotated model too), refresh_clears pushes it as a box clear (w > 0) while a site and drops it once built; the
##   blade shader reads box clears.

const TASK_ID := "gf_r3_leftovers"
const FIRE_HALL := "res://art/buildings/fire_hall.tscn"
const HEARTH := "res://art/buildings/hearth.tscn"
const BLADES := "res://art/environment/grass/grass_blades.gdshader"
const GLOW_SHADERS := ["rune_glow.gdshader", "rune_glow_vc.gdshader"]

var frame := 0
var world: Node3D
var _built: Node3D
var _site: Node3D
var _house: Node3D
var _fake: Node3D
var _gd: GroundDetail
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	world = Node3D.new()
	root.add_child(world)
	_built = _spawn(FIRE_HALL, Vector3(0, 0, 0), 0.0)
	_site = _spawn(FIRE_HALL, Vector3(30, 0, 0), 90.0)
	_house = _spawn(HEARTH, Vector3(60, 0, 0), 0.0)
	_built.call(&"set_construction_progress", 1.0)
	_site.call(&"set_construction_progress", 0.3)
	_house.call(&"set_construction_progress", 0.0)


func _spawn(path: String, at: Vector3, yaw: float) -> Node3D:
	var m := (load(path) as PackedScene).instantiate() as Node3D
	m.position = at
	m.rotation_degrees = Vector3(0, yaw, 0)
	world.add_child(m)
	return m


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 4:
		_check_chimney()
		_check_cold_site()
		_check_pad_rects()
		_setup_grass()
	if frame == 8:
		_gd.refresh_clears(Vector3(30, 0, 0), 30.0)
		var boxes := _gd.clear_list().filter(func(v: Vector4) -> bool: return v.w > 0.0)
		_check(boxes.size() == 1, "site: %d box clears (want 1)" % boxes.size())
		_site.call(&"set_construction_progress", 1.0)
	if frame == 12:
		_gd.refresh_clears(Vector3(30, 0, 0), 30.0)
		var boxes := _gd.clear_list().filter(func(v: Vector4) -> bool: return v.w > 0.0)
		_check(boxes.is_empty(), "built: still %d box clears" % boxes.size())
		_check(not _gd.clear_list().is_empty(), "built: no circle clear left")
		_check(absf(float((_site.get(&"mat_team") as ShaderMaterial).get_shader_parameter(&"crack_energy"))
			- float(_site.get(&"crack_glow"))) < 0.001, "built: crack emission not restored")
		_check((_site.find_child("ChimneyTop", true, false) as Node3D).visible, "built: chimney mouth hidden")
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		quit(0)
	return false


func _is_glow(m: Material) -> bool:
	if not (m is ShaderMaterial) or (m as ShaderMaterial).shader == null:
		return false
	var p: String = (m as ShaderMaterial).shader.resource_path
	for s: String in GLOW_SHADERS:
		if p.ends_with(s):
			return true
	return false


func _check_chimney() -> void:
	var top := _built.find_child("ChimneyTop", true, false) as MeshInstance3D
	_check(top != null, "no ChimneyTop")
	if top == null:
		return
	# Triangles in chimney space with their surface material.
	var tris: Array = []   # [a, b, c, glow]
	var mesh: Mesh = top.mesh
	var verts := 0
	for s: int in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		verts += vs.size()
		var mat: Material = top.get_surface_override_material(s)
		if mat == null:
			mat = top.material_override
		if mat == null:
			mat = mesh.surface_get_material(s)
		var glow: bool = _is_glow(mat)
		var ids: PackedInt32Array = idx if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0 \
			else PackedInt32Array(range(vs.size()))
		for t: int in range(0, ids.size() - 2, 3):
			tris.append([top.transform * vs[ids[t]], top.transform * vs[ids[t + 1]], top.transform * vs[ids[t + 2]], glow])
	_check(verts > 150, "chimney crown too simple (%d verts): no rounded lip" % verts)
	var hits := 0
	var glow_hits := 0
	for i: int in 9:
		for j: int in 9:
			var p := Vector2(-0.8 + 0.2 * i, -0.8 + 0.2 * j)
			if p.length() > 0.85:
				continue
			var best: float = -INF
			var best_glow := false
			for t: Array in tris:
				var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3(p.x, 20.0, p.y), Vector3.DOWN, t[0], t[1], t[2])
				if hit is Vector3 and (hit as Vector3).y > best:
					best = (hit as Vector3).y
					best_glow = t[3]
			if best > -INF:
				hits += 1
				if best_glow:
					glow_hits += 1
	_check(hits > 0, "chimney mouth: no surface under the mouth")
	_check(hits > 0 and float(glow_hits) / float(hits) >= 0.6,
		"chimney mouth: only %d / %d top samples see the ember floor / coals (a dark cap over the mouth)" % [glow_hits, hits])
	var pit := _built.get(&"_chimney_pit") as ShaderMaterial
	_check(pit != null, "no chimney pit material")
	if pit:
		var c: Color = pit.get_shader_parameter(&"glow_color")
		var e: float = float(pit.get_shader_parameter(&"energy"))
		var peak: float = maxf(c.r, maxf(c.g, c.b)) * (0.4 + e * 1.0)
		_check(peak <= 0.45 and c.r > c.g * 2.0 and c.r > c.b * 2.0, "chimney pit not a dark ember red (peak %.2f, %s)" % [peak, c])


func _check_cold_site() -> void:
	var mt := _site.get(&"mat_team") as ShaderMaterial
	var ce: float = float(mt.get_shader_parameter(&"crack_energy"))
	_check(ce <= 0.001, "30 %% site: body crack emission %.2f (want 0)" % ce)
	_check(float(_site.call(&"site_glow_k")) <= 0.001, "30 % site: site_glow_k not 0")
	var crown := _site.find_child("ChimneyTop", true, false) as Node3D
	_check(crown != null and not crown.visible, "30 % site: chimney mouth shown near the ground")
	var mb := _built.get(&"mat_team") as ShaderMaterial
	_check(absf(float(mb.get_shader_parameter(&"crack_energy")) - float(_built.get(&"crack_glow"))) < 0.001,
		"built hall: crack emission changed")


func _check_pad_rects() -> void:
	for m: Node3D in [_site, _house]:
		var pad := m.get_node_or_null(^"SitePad") as MeshInstance3D
		_check(pad != null and pad.visible, "%s: no visible SitePad" % m.name)
		if pad == null:
			continue
		_check(pad.has_meta(&"_grass_clear_rect"), "%s: pad without _grass_clear_rect" % m.name)
		if not pad.has_meta(&"_grass_clear_rect"):
			continue
		var r: Vector4 = pad.get_meta(&"_grass_clear_rect")
		var ab: AABB = pad.mesh.get_aabb()
		_check(r.x <= ab.position.x and r.y <= ab.position.z and r.z >= ab.end.x and r.w >= ab.end.z,
			"%s: grass rect %s does not cover the pad %s" % [m.name, r, ab])
		_check(r.z - r.x < ab.size.x + 1.0 and r.w - r.y < ab.size.z + 1.0, "%s: grass rect %s far bigger than the pad" % [m.name, r])


func _setup_grass() -> void:
	var src := GDScript.new()
	src.source_code = "extends Node3D\nvar m: Node3D\nfunc model() -> Node3D:\n\treturn m\nfunc target_radius() -> float:\n\treturn 3.2\n"
	src.reload()
	_fake = Node3D.new()
	_fake.set_script(src)
	_fake.position = _site.position
	world.add_child(_fake)
	_fake.set(&"m", _site)
	_fake.add_to_group(&"buildings")
	var box: Vector4 = GroundDetail.site_pad_box(_fake)
	_check(box.w > 0.0, "site_pad_box: no box for a shown pad")
	var pad := _site.get_node(^"SitePad") as MeshInstance3D
	var wab: AABB = pad.global_transform * pad.mesh.get_aabb()
	_check(box.x - box.z <= wab.position.x + 0.01 and box.x + box.z >= wab.end.x - 0.01
		and box.y - box.w <= wab.position.z + 0.01 and box.y + box.w >= wab.end.z - 0.01,
		"site_pad_box %s does not cover the rotated pad %s" % [box, wab])
	var code: String = (load(BLADES) as Shader).code
	_check(code.contains("c.w > 0.0"), "grass shader has no box clear")
	_gd = GroundDetail.new()
	world.add_child(_gd)
