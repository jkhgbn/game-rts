extends SceneTree
## forge_citadel kit baker (tech-art tool, not game code). Each script-built building scene is run once in a tree, then
## every visible mesh surface is merged into ONE ArrayMesh with one surface per material, saved as a mesh-only scene
## `parts/kits/<name>.tscn` (a MeshInstance3D, no script) so World Forge `row ... count=1` bakes it into the set's
## Scatter mesh: copies of the same kit then share their surfaces (one draw per material for the whole set).
## Plain StandardMaterial3D (no texture, opaque) are folded into shared vertex-colour materials (matte / metal / glow),
## shader materials are kept (de-localised so copies merge).
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_citadel/tools/bake_kits.gd --quit-after 6000

const OUT := "res://art/cinematics/stage_sets/forge_citadel/parts/kits"
const MATS := "res://art/cinematics/stage_sets/forge_citadel/parts/materials"

const SOURCES := {
	"fire_keep": "res://art/buildings/fire_keep.tscn",
	"ice_keep": "res://art/buildings/ice_keep.tscn",
	"nature_keep": "res://art/buildings/nature_keep.tscn",
	"dusk_keep": "res://art/buildings/dusk_keep.tscn",
	"fire_hall": "res://art/buildings/fire_hall.tscn",
	"ice_hall": "res://art/buildings/ice_hall.tscn",
	"nature_hall": "res://art/buildings/nature_hall.tscn",
	"shadow_hall": "res://art/buildings/shadow_hall.tscn",
	"fire_tower": "res://art/buildings/fire_tower.tscn",
	"shadow_tower": "res://art/buildings/shadow_tower.tscn",
	"ice_spire": "res://art/buildings/ice_spire.tscn",
	"nature_spire": "res://art/buildings/nature_spire.tscn",
	"ice_lodge": "res://art/buildings/ice_lodge.tscn",
	"ice_wall": "res://art/buildings/ice_wall.tscn",
	"nature_hollow": "res://art/buildings/nature_hollow.tscn",
	"hearth": "res://art/buildings/hearth.tscn",
	"hovel": "res://art/buildings/hovel.tscn",
	"essence_well": "res://art/buildings/capture/essence_well/essence_well.tscn",
	"watchtower": "res://art/buildings/capture/watchtower/watchtower.tscn",
	"wayshrine": "res://art/buildings/capture/wayshrine/wayshrine.tscn",
	"ember_crucible": "res://art/buildings/fire/ember_crucible/ember_crucible.tscn",
	"greywater_lodge": "res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn",
	"magpie_den": "res://art/buildings/guilds/magpie_den/magpie_den.tscn",
	"dragon_roost": "res://art/buildings/lair/fire/dragon_roost.tscn",
	"dread_paddock": "res://art/buildings/lair/shadow/dread_paddock.tscn",
	"market_fire": "res://art/buildings/market/fire/market_fire.tscn",
	"market_ice": "res://art/buildings/market/ice/market_ice.tscn",
	"market_nature": "res://art/buildings/market/nature/market_nature.tscn",
	"market_shadow": "res://art/buildings/market/shadow/market_shadow.tscn",
	"bounty_flag": "res://art/buildings/tavern/bounty_flag.tscn",
	"tavern": "res://art/buildings/tavern/tavern_model.tscn",
	"trade_post": "res://art/buildings/trade_post/trade_post.tscn",
	"road_bridge": "res://art/environment/bridges/road_bridge.tscn",
	"lane_bridge": "res://art/environment/bridges/lane_bridge.tscn",
	"crown_steps": "res://art/environment/bridges/crown_steps.tscn",
	"aqueduct": "res://art/environment/landmarks/aqueduct.tscn",
}

var shared := {}  ## "matte" / "metal" / "glow" -> Material (saved once)
var cur_name := ""
## Kits that keep their own (painted shader) materials: the ones seen close in S05 / S30. Every other kit is folded
## onto the 3 shared vertex-colour materials (colour taken from the shader's colour uniforms), so the whole set
## stays far under the draw budget (and under Godot's 256 surfaces per mesh).
const KEEP: Array[String] = ["fire_keep", "ice_keep", "nature_keep", "dusk_keep", "market_ice", "market_fire", "market_nature",
	"market_shadow", "tavern", "trade_post", "dragon_roost", "fire_hall", "ice_hall", "nature_hall", "shadow_hall"]
const DROP_WORDS: Array[String] = ["ground", "beam", "motes", "_fx", "ring", "foam", "mist", "shadow_blob", "decal", "select"]
const GLOW_WORDS: Array[String] = ["glow", "window", "rune", "heart", "lava", "crystal", "flame", "seed", "pool", "ember", "fire_core"]
const COLOR_KEYS: Array[String] = ["base_color", "cloth_color", "neutral_cloth", "neutral_color", "team_color", "albedo",
	"albedo_color", "color", "moss_color", "stone_color", "wood_color", "leaf_color"]
const GLOW_KEYS: Array[String] = ["glow_color", "window_color", "core_color", "flame_color", "hot_color", "pool_color", "heart_color", "fx_color"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MATS))
	_shared_materials()
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	for name: String in SOURCES:
		if only != "" and not only.split(",").has(name):
			continue
		var ps := load(SOURCES[name]) as PackedScene
		if ps == null:
			print("BAKE %s LOAD_FAIL" % name)
			continue
		cur_name = name
		var inst := ps.instantiate()
		root.add_child(inst)
		for i in 4:
			await process_frame
		var buckets := {}
		var order: Array = []
		var own_mats := {}  # source material id -> de-localised copy
		var base := (inst as Node3D).global_transform.affine_inverse() if inst is Node3D else Transform3D.IDENTITY
		for c: Node in inst.find_children("*", "GeometryInstance3D", true, false):
			var gi := c as GeometryInstance3D
			if not gi.is_visible_in_tree():
				continue
			if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
				var mi := gi as MeshInstance3D
				for s in mi.mesh.get_surface_count():
					_add(buckets, order, own_mats, mi.mesh, s, _mat_of(mi, s), base * mi.global_transform)
			elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh:
				var mm := (gi as MultiMeshInstance3D).multimesh
				if mm.mesh == null or mm.transform_format != MultiMesh.TRANSFORM_3D:
					continue
				var cnt := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
				for k in cnt:
					for s in mm.mesh.get_surface_count():
						var m: Material = gi.material_override if gi.material_override else mm.mesh.surface_get_material(s)
						var tint := mm.get_instance_color(k) if mm.use_colors else Color.WHITE
						_add(buckets, order, own_mats, mm.mesh, s, m, base * gi.global_transform * mm.get_instance_transform(k), tint)
		var mesh := ArrayMesh.new()
		var tris := 0
		for key: String in order:
			var b: Dictionary = buckets[key]
			var st: SurfaceTool = b["st"]
			var arr := st.commit_to_arrays()
			tris += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			mesh.surface_set_material(mesh.get_surface_count() - 1, b["mat"])
		inst.queue_free()
		await process_frame
		var mpath := "%s/%s.res" % [OUT, name]
		ResourceSaver.save(mesh, mpath, ResourceSaver.FLAG_COMPRESS)
		mesh.take_over_path(mpath)
		var n := Node3D.new()
		n.name = name
		var mi2 := MeshInstance3D.new()
		mi2.name = "Mesh"
		mi2.mesh = mesh
		n.add_child(mi2)
		mi2.owner = n
		var sc := PackedScene.new()
		sc.pack(n)
		ResourceSaver.save(sc, "%s/%s.tscn" % [OUT, name])
		n.free()
		var ab := mesh.get_aabb()
		print("BAKE %s surfaces=%d tris=%d size=(%.1f,%.1f,%.1f) ymin=%.2f" % [name, mesh.get_surface_count(), tris, ab.size.x, ab.size.y, ab.size.z, ab.position.y])
	quit()


func _mat_of(mi: MeshInstance3D, s: int) -> Material:
	if mi.material_override:
		return mi.material_override
	var m := mi.get_surface_override_material(s)
	return m if m else mi.mesh.surface_get_material(s)


## Adds a surface to the bucket of its (possibly folded) material. Folded plain materials bake their colour into COLOR.
func _add(buckets: Dictionary, order: Array, own: Dictionary, mesh: Mesh, s: int, mat: Material, xf: Transform3D, tint := Color.WHITE) -> void:
	if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
		return
	var key := ""
	var target: Material = null
	var col_mul := tint
	var use_vc := false
	var palette: Array = []
	var sm := mat as StandardMaterial3D
	if mat == null:
		key = "matte"
		target = shared["matte"]
		col_mul = Color(0.7, 0.7, 0.7) * tint
	elif sm and sm.albedo_texture == null and sm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and sm.albedo_color.a > 0.99 and sm.normal_texture == null:
		use_vc = sm.vertex_color_use_as_albedo
		if sm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or (sm.emission_enabled and sm.emission_energy_multiplier > 0.2 and sm.emission.get_luminance() > 0.05):
			key = "glow"
			target = shared["glow"]
			col_mul = (sm.emission if sm.emission_enabled else sm.albedo_color) * tint
		elif sm.metallic > 0.5:
			key = "metal"
			target = shared["metal"]
			col_mul = sm.albedo_color * tint
		else:
			key = "matte"
			target = shared["matte"]
			col_mul = sm.albedo_color * tint
	elif not KEEP.has(cur_name):
		var fd := _fold(mat)
		if fd["drop"]:
			return
		key = fd["key"]
		target = shared[key]
		col_mul = (fd["col"] as Color) * tint
		use_vc = fd["use_vc"]
		palette = fd["palette"]
	else:
		key = "m%d" % mat.get_instance_id()
		if not own.has(key):
			var d: Material = mat.duplicate()
			d.resource_local_to_scene = false
			own[key] = d
		target = own[key]
		col_mul = tint
		use_vc = true
	if not buckets.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		buckets[key] = {"st": st, "mat": target}
		order.append(key)
	var stt: SurfaceTool = buckets[key]["st"]
	var arr := mesh.surface_get_arrays(s)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: Variant = arr[Mesh.ARRAY_NORMAL]
	var c: Variant = arr[Mesh.ARRAY_COLOR]
	var uv: Variant = arr[Mesh.ARRAY_TEX_UV]
	var uv2: Variant = arr[Mesh.ARRAY_TEX_UV2]
	var idx: Variant = arr[Mesh.ARRAY_INDEX]
	var nb := xf.basis.inverse().transposed()
	var flip := xf.basis.determinant() < 0.0
	var has_n := n is PackedVector3Array and (n as PackedVector3Array).size() == v.size()
	var has_c := c is PackedColorArray and (c as PackedColorArray).size() == v.size()
	var has_uv := uv is PackedVector2Array and (uv as PackedVector2Array).size() == v.size()
	var has_uv2 := uv2 is PackedVector2Array and (uv2 as PackedVector2Array).size() == v.size()
	var order_idx: PackedInt32Array
	if idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty():
		order_idx = idx
	else:
		order_idx = PackedInt32Array(range(v.size()))
	for k in range(0, order_idx.size() - 2, 3):
		var tri := [order_idx[k], order_idx[k + 2], order_idx[k + 1]] if flip else [order_idx[k], order_idx[k + 1], order_idx[k + 2]]
		for i: int in tri:
			var vc: Color = (c as PackedColorArray)[i] if (has_c and use_vc) else Color.WHITE
			if not palette.is_empty():
				var slot := clampi(int((uv2 as PackedVector2Array)[i].y + 0.5) if has_uv2 else 0, 0, palette.size() - 1)
				vc = palette[slot]
			stt.set_color(Color(vc.r * col_mul.r, vc.g * col_mul.g, vc.b * col_mul.b, vc.a))
			stt.set_normal((nb * ((n as PackedVector3Array)[i] if has_n else Vector3.UP)).normalized())
			stt.set_uv((uv as PackedVector2Array)[i] if has_uv else Vector2.ZERO)
			stt.set_uv2((uv2 as PackedVector2Array)[i] if has_uv2 else Vector2.ZERO)
			stt.add_vertex(xf * v[i])


func _shared_materials() -> void:
	var paths := {"matte": MATS + "/citadel_matte.tres", "metal": MATS + "/citadel_metal.tres", "glow": MATS + "/citadel_glow.tres"}
	for k: String in paths:
		if ResourceLoader.exists(paths[k]):
			shared[k] = load(paths[k])
			continue
		var m: Material
		if k == "glow":
			var sh := ShaderMaterial.new()
			sh.shader = load(MATS + "/citadel_glow.gdshader")
			m = sh
		else:
			var s := StandardMaterial3D.new()
			s.vertex_color_use_as_albedo = true
			s.roughness = 0.9 if k == "matte" else 0.4
			s.metallic = 0.0 if k == "matte" else 0.7
			m = s
		ResourceSaver.save(m, paths[k])
		shared[k] = load(paths[k])


## Folds a material into matte / metal / glow: {drop, key, col, use_vc, palette}.
func _fold(mat: Material) -> Dictionary:
	var out := {"drop": false, "key": "matte", "col": Color(0.55, 0.52, 0.48), "use_vc": false, "palette": []}
	var sm := mat as StandardMaterial3D
	if sm:
		if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and sm.albedo_color.a < 0.55:
			out["drop"] = true
			return out
		out["col"] = sm.albedo_color
		out["use_vc"] = sm.vertex_color_use_as_albedo
		if sm.emission_enabled and sm.emission.get_luminance() > 0.05:
			out["key"] = "glow"
			out["col"] = sm.emission
		elif sm.metallic > 0.5:
			out["key"] = "metal"
		return out
	var sh := mat as ShaderMaterial
	if sh == null or sh.shader == null:
		return out
	var sname := sh.shader.resource_path.get_file().to_lower()
	var code := sh.shader.code
	for w in DROP_WORDS:
		if sname.contains(w):
			out["drop"] = true
			return out
	if code.contains("blend_add"):
		out["drop"] = true
		return out
	var params := {}
	for u: Dictionary in sh.shader.get_shader_uniform_list():
		var nm: String = u["name"]
		var val: Variant = sh.get_shader_parameter(nm)
		if val == null:
			val = RenderingServer.shader_get_parameter_default(sh.shader.get_rid(), nm)
		params[nm] = val
	var is_glow := false
	for w in GLOW_WORDS:
		if sname.contains(w):
			is_glow = true
	if params.has("base_colors"):
		var arr: Array = []
		for c in params["base_colors"]:
			arr.append(_col(c))
		if not arr.is_empty():
			out["palette"] = arr
			out["col"] = Color.WHITE
			var so: Variant = params.get("slot_override", -1)
			if so != null and int(so) >= 0 and int(so) < arr.size():
				out["palette"] = [arr[int(so)]]
			return out
	var keys := GLOW_KEYS if is_glow else COLOR_KEYS
	var found := false
	for k in keys:
		if params.has(k) and params[k] != null and (params[k] is Color or params[k] is Vector3):
			out["col"] = _col(params[k])
			found = true
			break
	if not found:
		for k: String in params:
			var lk := k.to_lower()
			if (params[k] is Color or params[k] is Vector3) and not (lk.contains("rim") or lk.contains("select") or lk.contains("edge") or lk.contains("stain") or lk.contains("crack") or lk.contains("pos")):
				out["col"] = _col(params[k])
				break
	if is_glow:
		out["key"] = "glow"
	elif sname.contains("gold") or sname.contains("coin") or sname.contains("metal") or sname.contains("brass"):
		out["key"] = "metal"
	out["use_vc"] = code.contains("COLOR.rgb") or code.contains("* COLOR")
	return out


static func _col(v: Variant) -> Color:
	if v is Color:
		return v
	if v is Vector3:
		return Color(v.x, v.y, v.z)
	return Color(0.55, 0.52, 0.48)