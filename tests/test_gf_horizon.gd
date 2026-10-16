extends SceneTree
## G-F per-map horizon (docs/art/gf_horizon.md, art/environment/horizon/horizon_variant.gd): Crown Hollow keeps the
## baked ring and its landmarks (watchtower, shrine, aqueduct, stone ring, pond); Thornwater (fen), Quartermeet
## (autumn), Kinhearth Vale (neutral) and Ashwind Reach (autumn, 192 x 96) drop them, get their own dressing, and no
## horizon vertex sits inside the map; the Low tier draws no more triangles than the baked ring. Then one real level
## (Quartermeet through MapCatalog, AutumnSwap included) gets its variant from the deferred fit.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gf_horizon.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "gf_horizon"
const SCENE := "res://art/environment/horizon/horizon.tscn"
const MARGIN := 2.0    ## every horizon vertex at least this far outside the map rectangle

var fails: Array[String] = []
var base_tris := 0


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	_check_tags()
	# [map id, size, expected variant]
	var cases: Array = [
		[&"crown_hollow", Vector2(120, 120), HorizonVariant.CROWN_HOLLOW],
		[&"thornwater", Vector2(120, 120), HorizonVariant.FEN],
		[&"quartermeet", Vector2(176, 176), HorizonVariant.AUTUMN],
		[&"kinhearth_vale", Vector2(176, 176), HorizonVariant.NEUTRAL],
		[&"ashwind_reach", Vector2(192, 96), HorizonVariant.AUTUMN],
	]
	for row: Array in cases:
		for tier: int in [0, 2]:
			await _check_map(row[0], row[1], row[2], tier)
	await _check_real_level(&"quartermeet", HorizonVariant.AUTUMN, true)
	await _check_real_level(&"ashwind_reach", HorizonVariant.AUTUMN, false)
	MapInfo.reset()
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
	quit(0 if fails.is_empty() else 1)


## The baked meshes carry the landmark tags (horizon_tag_bake.gd).
func _check_tags() -> void:
	var hz := (load(SCENE) as PackedScene).instantiate() as Node3D
	var seen: Dictionary = {}
	for c: Node in hz.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var arr: Array = mi.mesh.surface_get_arrays(0)
		base_tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		for u: Vector2 in (arr[Mesh.ARRAY_TEX_UV] as PackedVector2Array):
			seen[int(u.y)] = true
	hz.free()
	for t: int in HorizonVariant.LANDMARK_TAGS + [HorizonVariant.TAG_CRAG]:
		if not seen.has(t):
			fails.append("baked meshes miss tag %d (re-run horizon_tag_bake.gd)" % t)
	print("baked ring: %d tris, tags %s" % [base_tris, str(seen.keys())])


func _check_map(map_id: StringName, size: Vector2, want: StringName, tier: int) -> void:
	MapInfo.setup(size.x, size.y, map_id)
	var holder := Node3D.new()
	root.add_child(holder)
	var hz := (load(SCENE) as PackedScene).instantiate() as Node3D
	var t0 := Time.get_ticks_usec()
	holder.add_child(hz)   # headless = Low tier: the deferred fit builds the Low variant
	await process_frame
	await process_frame
	if tier > 0 and want != HorizonVariant.CROWN_HOLLOW:
		hz.call(&"apply_variant", want, size.x * 0.5, size.y * 0.5, tier)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	var got := StringName(hz.get(&"variant"))
	if got != want:
		fails.append("%s: variant %s, want %s" % [map_id, got, want])
	var tags: Dictionary = {}
	var tris := 0
	var inside := 0
	var worst := INF
	var hx := size.x * 0.5
	var hzz := size.y * 0.5
	for c: Node in hz.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
			continue
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		tris += idx.size() / 3
		var shader_fit := want == HorizonVariant.CROWN_HOLLOW
		for i: int in idx:
			tags[int(uv[i].y)] = true
			var p := Vector2(v[i].x, v[i].z)
			if shader_fit:
				p += HorizonFit.fit_point(uv2[i], Vector2(hx, hzz)) - uv2[i]
			var out := maxf(absf(p.x) - hx, absf(p.y) - hzz)
			worst = minf(worst, out)
			if out < MARGIN:
				inside += 1
	if inside > 0:
		fails.append("%s tier %d: %d horizon vertices inside the map (closest %.1f m outside)" % [map_id, tier, inside, worst])
	var lm := 0
	for t: int in HorizonVariant.LANDMARK_TAGS:
		if tags.has(t):
			lm += 1
	if want == HorizonVariant.CROWN_HOLLOW:
		if lm != HorizonVariant.LANDMARK_TAGS.size():
			fails.append("%s: Crown Hollow lost landmarks (%d of %d tags drawn)" % [map_id, lm, HorizonVariant.LANDMARK_TAGS.size()])
		if tags.has(HorizonVariant.TAG_DRESSING):
			fails.append("%s: Crown Hollow got variant dressing" % map_id)
		if tris != base_tris:
			fails.append("%s: Crown Hollow tris %d != baked %d" % [map_id, tris, base_tris])
	else:
		if lm > 0:
			fails.append("%s tier %d: %d Crown Hollow landmark kinds still drawn" % [map_id, tier, lm])
		if want == HorizonVariant.FEN and tags.has(HorizonVariant.TAG_CRAG):
			fails.append("%s: fen keeps the granite crags" % map_id)
		if not tags.has(HorizonVariant.TAG_DRESSING):
			fails.append("%s tier %d: no dressing of its own" % [map_id, tier])
		if tier == 0 and tris > base_tris:
			fails.append("%s Low: %d tris > baked %d" % [map_id, tris, base_tris])
		for c: Node in hz.get_children():
			var mi := c as MeshInstance3D
			if mi != null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
				var mat := mi.mesh.surface_get_material(0)
				if mat == null or not mat.resource_path.ends_with("horizon_mat.tres"):
					fails.append("%s: %s does not draw with horizon_mat.tres" % [map_id, mi.name])
					break
	print("%s %s tier %d: variant %s, %d tris (baked %d), closest %.1f m outside, %.1f ms" % [map_id, str(size), tier,
		got, tris, base_tris, worst, ms])
	holder.queue_free()
	await process_frame


## A real level: the deferred fit after main.gd's MapInfo.setup picks the variant.
func _check_real_level(map_id: StringName, want: StringName, own_palette: bool) -> void:
	var cat := MapCatalog.load_default()
	var level := cat.instantiate_level(map_id)
	if level == null:
		fails.append("%s: no level" % map_id)
		return
	root.add_child(level)
	current_scene = level
	for f: int in 10:
		await process_frame
	var hz: Node = level.get_node_or_null(^"Horizon")
	if hz == null:
		fails.append("%s: level has no Horizon" % map_id)
	elif StringName(hz.get(&"variant")) != want:
		fails.append("%s level: variant %s, want %s" % [map_id, hz.get(&"variant"), want])
	else:
		print("%s level: variant %s, map %s x %s, palette %s" % [map_id, hz.get(&"variant"), MapInfo.size_x,
			MapInfo.size_z, str(hz.get(&"palette"))])
		_check_palette(map_id, hz, own_palette)
	level.queue_free()
	for f: int in 3:
		await process_frame


## Quartermeet draws its horizon with its own golden palette (a material override on every sector); Ashwind Reach
## keeps the shared material (AutumnSwap's tones) untouched.
func _check_palette(map_id: StringName, hz: Node, own_palette: bool) -> void:
	var shared := load("res://art/environment/autumn/horizon_autumn_mat.tres") as ShaderMaterial
	for c: Node in hz.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		var ov := mi.material_override as ShaderMaterial
		if not own_palette:
			if ov != null:
				fails.append("%s: %s has a palette override (must keep the shared horizon material)" % [map_id, mi.name])
			continue
		if ov == null or ov.shader == null or not ov.shader.resource_path.ends_with("horizon_autumn.gdshader"):
			fails.append("%s: %s has no Quartermeet palette override" % [map_id, mi.name])
			continue
		var gold: Color = ov.get_shader_parameter(&"far_gold")
		var russet: Color = ov.get_shader_parameter(&"far_russet")
		if gold.is_equal_approx(shared.get_shader_parameter(&"far_gold")) or russet.g < 0.3:
			fails.append("%s: palette override keeps the shared orange tones" % map_id)
	if StringName(hz.get(&"palette")) != (map_id if own_palette else &""):
		fails.append("%s: palette %s" % [map_id, hz.get(&"palette")])
	if shared.get_shader_parameter(&"far_gold") != Color(0.76, 0.6, 0.22, 1):
		fails.append("%s: the shared horizon_autumn_mat was changed" % map_id)
