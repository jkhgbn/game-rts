class_name GroundDetail
extends Node3D
## G2a ground detail (docs/art/g2a_ground.md): the per-quality-tier extras of the painted ground. Draw-only, no
## colliders, no gameplay. One per level (group "ground_detail"): `GroundDetail.ensure(level)`.
## - Painted relief on the ground (ground.gdshader `relief`): High 0.22, Ultra 0.28, else 0 (today's flat light).
## - 3D grass field (grass_blades.gdshader): wind-swept grass clumps in MultiMesh rings that follow the camera.
##   At start the level's ground material is rendered top-down twice (ground.gdshader bake_mode 1 = grass colour,
##   2 = grass mask) into images, so blades grow only where the ground paints grass and take its exact colour.
##   Units the player can see flatten the blades round them, buildings / crystal nodes clear them.
##   Tiers: Low = nothing (no bake, no node cost), Medium = one ring, High / Ultra = a dense near ring + a sparser
##   far ring of bigger clumps (shown only when the camera is high enough to see it).
## Tier = GameSettings.effective_graphics_quality() (load-guarded; default High), then `set_quality(q)` whenever the
## settings apply a tier (this node is in GameSettings' "lighting_rigs" group for that broadcast).
## Headless runs and the sim mode never build anything.

const GROUND_SHADER := "res://art/environment/ground.gdshader"
const BLADE_SHADER := preload("res://art/environment/grass/grass_blades.gdshader")
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const GROUP := &"ground_detail"
const RIG_GROUP := &"lighting_rigs"
const RELIEF: Array[float] = [0.0, 0.0, 0.22, 0.28]
## Per tier: [near spacing, near radius, far radius (0 = no far ring), blade height, camera fade start, fade end].
## Measured (docs/art/g2a_ground.md): a far ring of bigger clumps cost +18 ms GPU at zoom 50 for 1-2 px blades
## (micro-triangles under MSAA), so blades now fade out with the camera distance and no tier has a far ring.
const RINGS: Array = [
	[0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	[0.40, 18.0, 0.0, 0.36, 30.0, 42.0],
	[0.32, 24.0, 0.0, 0.42, 36.0, 50.0],
	[0.29, 28.0, 0.0, 0.42, 38.0, 52.0],
]
const FAR_SHOW_HEIGHT := 14.0       ## camera height (m) above which the far ring is drawn
const BAKE_TEXEL := 0.12            ## metres per texel of the colour / mask bake (capped at 2048 px)
const MAX_PUSHERS := 48
const MAX_CLEARS := 32
const CLEAR_INTERVAL := 0.5
const PUSH_INTERVAL := 0.1          ## pushers refresh (s): a unit moves < 0.6 m between two, inside its 0.95 m+ radius

## Tests / tools: >= 0 beats the settings (0 Low .. 3 Ultra).
static var quality_override := -1

var quality := -1
var _level: Node = null
var _ground: ShaderMaterial = null
var _mat: ShaderMaterial = null
var _near: MultiMeshInstance3D = null
var _far: MultiMeshInstance3D = null
var _baked := false
var _baking := false
var _bake_ms := 0.0
var _bake_stats := {}
var _clear_t := 0.0
var _far_radius := 0.0
var _near_radius := 0.0
var _snap := 0.64
var _push_t := 0.0
# Nearest-K buffers, reused (no per-refresh allocation): xz + radius, squared distance, how many are used.
var _push_buf := PackedVector4Array()
var _push_d := PackedFloat32Array()
var _push_n := 0
var _clear_buf := PackedVector4Array()
var _clear_d := PackedFloat32Array()
var _clear_n := 0
var _seen := {}                      # instance id -> true: buildings / crystal nodes the player has seen once


## The level's GroundDetail, created (as a child of `level`) when it has none. Null in headless / sim runs.
static func ensure(level: Node) -> GroundDetail:
	if level == null or not level.is_inside_tree():
		return null
	for n in level.get_tree().get_nodes_in_group(GROUP):
		if is_instance_valid(n) and level.is_ancestor_of(n):
			return n as GroundDetail
	if DisplayServer.get_name() == "headless":
		return null
	var gd := GroundDetail.new()
	gd.name = "GroundDetail"
	level.add_child(gd)
	return gd


## The tier the settings ask for (load-guarded): --gfx, else Low in quiet runs, else the saved setting; High when the
## settings script does not exist.
static func settings_quality() -> int:
	if quality_override >= 0:
		return clampi(quality_override, 0, 3)
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return 2
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs == null:
		return 2
	if gs.has_method(&"effective_graphics_quality"):
		return clampi(int(gs.call(&"effective_graphics_quality")), 0, 3)
	var v: Variant = gs.get(&"graphics_quality")
	return clampi(int(v), 0, 3) if v != null else 2


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(RIG_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS   # the camera can move while the game is paused (path pick, menus)
	_level = get_parent()
	set_quality.call_deferred(settings_quality())


## Applies a tier (0 Low .. 3 Ultra): ground relief + the grass rings. Safe to call any time.
func set_quality(q: int) -> void:
	q = clampi(q, 0, 3)
	if q == quality and (_baked or q <= 0):
		return
	quality = q
	if _ground == null:
		_ground = _find_ground()
	if _ground:
		_ground.set_shader_parameter(&"relief", RELIEF[q])
	_free_rings()
	if q <= 0 or _ground == null or DisplayServer.get_name() == "headless":
		set_process(false)
		return
	if not _baked:
		if not _baking:
			_bake_and_build()
		return
	_build_rings()


## Milliseconds the top-down bake took (0 before / without it).
func bake_msec() -> float:
	return _bake_ms


## The bake's cost: {total_ms (wall, frames included), readback_ms (blocking GPU readbacks), res, vram_mb kept}.
func bake_stats() -> Dictionary:
	return _bake_stats.duplicate()


## Clump instances drawn per ring: {near, far}.
func instance_counts() -> Dictionary:
	return {"near": _near.multimesh.instance_count if _near else 0,
		"far": _far.multimesh.instance_count if _far else 0}


func is_baked() -> bool:
	return _baked


# ---------------------------------------------------------------- bake

func _find_ground() -> ShaderMaterial:
	if _level == null:
		return null
	for mi: Node in _level.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var sm := m.material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == GROUND_SHADER and m.mesh is PlaneMesh:
			return sm
	return null


func _half_extents() -> Vector2:
	# MapInfo is the running map's size (MT1); the ground's own uniforms only when it was never set up.
	var h := Vector2(MapInfo.half_x(), MapInfo.half_z())
	if h.x <= 0.0 and _ground:
		var hx: Variant = _ground.get_shader_parameter(&"map_half_xz")
		var mh: Variant = _ground.get_shader_parameter(&"map_half")
		if hx is Vector2 and (hx as Vector2).x > 0.0:
			h = hx
		elif mh is float and float(mh) > 0.0:
			h = Vector2(float(mh), float(mh))
	return h


func _bake_and_build() -> void:
	_baking = true
	var t0 := Time.get_ticks_msec()
	# Wait until the level has written the river / roads / biome uniforms (they are set while the map builds).
	for i in 3:
		await get_tree().process_frame
	if not is_inside_tree():
		return
	var half := _half_extents()
	var res := Vector2i(clampi(int(ceil(half.x * 2.0 / BAKE_TEXEL)), 64, 2048),
		clampi(int(ceil(half.y * 2.0 / BAKE_TEXEL)), 64, 2048))
	var vp := SubViewport.new()
	vp.size = res
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = half.y * 2.0
	cam.near = 0.5
	cam.far = 200.0
	cam.position = Vector3(0.0, 100.0, 0.0)
	cam.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	cam.environment = env
	vp.add_child(cam)
	var plane := PlaneMesh.new()
	plane.size = half * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	var bm := _ground.duplicate() as ShaderMaterial
	bm.set_shader_parameter(&"expand_edge", false)
	bm.set_shader_parameter(&"relief", 0.0)
	bm.set_shader_parameter(&"skip_sun_shadow", false)
	mi.material_override = bm
	vp.add_child(mi)
	add_child(vp)
	var imgs: Array[Image] = []
	for mode: int in [1, 2]:
		bm.set_shader_parameter(&"bake_mode", mode)
		for i in 2:
			await RenderingServer.frame_post_draw
		if not is_inside_tree():
			return
		var tr := Time.get_ticks_usec()
		var img := vp.get_texture().get_image()   # GPU readback: the only blocking step (measured in _bake_stats)
		_bake_stats["readback_ms"] = float(_bake_stats.get("readback_ms", 0.0)) + (Time.get_ticks_usec() - tr) / 1000.0
		if img == null:
			break
		imgs.append(img)   # no mipmaps: the blade shader reads LOD 0 only
	vp.queue_free()
	_baking = false
	if imgs.size() < 2:
		push_warning("GroundDetail: the ground bake failed, no grass field")
		return
	_mat = ShaderMaterial.new()
	_mat.shader = BLADE_SHADER
	_mat.set_shader_parameter(&"ground_col", ImageTexture.create_from_image(imgs[0]))
	_mat.set_shader_parameter(&"ground_mask", ImageTexture.create_from_image(imgs[1]))
	_mat.set_shader_parameter(&"map_half", half)
	for key: StringName in [&"flower_a", &"flower_b", &"flower_c"]:
		var c: Variant = _ground.get_shader_parameter(key)
		if c is Color or c is Vector3:
			_mat.set_shader_parameter(key, c)
	_baked = true
	_bake_ms = float(Time.get_ticks_msec() - t0)
	_bake_stats["total_ms"] = _bake_ms
	_bake_stats["res"] = res
	_bake_stats["vram_mb"] = float(res.x * res.y * 4 * 2) / 1048576.0
	if quality > 0:
		_build_rings()


## The bake images (tests / tools): [colour, mask], empty before the bake.
func bake_images() -> Array[Image]:
	var out: Array[Image] = []
	if _mat == null:
		return out
	for key: StringName in [&"ground_col", &"ground_mask"]:
		var t := _mat.get_shader_parameter(key) as Texture2D
		if t:
			out.append(t.get_image())
	return out


# ---------------------------------------------------------------- rings

func _free_rings() -> void:
	for r: MultiMeshInstance3D in [_near, _far]:
		if r and is_instance_valid(r):
			r.queue_free()
	_near = null
	_far = null


func _build_rings() -> void:
	_free_rings()
	var cfg: Array = RINGS[quality]
	var s: float = cfg[0]
	_near_radius = cfg[1]
	_far_radius = cfg[2]
	_mat.set_shader_parameter(&"blade_height", float(cfg[3]))
	_mat.set_shader_parameter(&"cam_fade", Vector2(float(cfg[4]), float(cfg[5])))
	var clump := GrassClump.build()
	var near_out := _near_radius
	if _far_radius > 0.0:
		_near = _ring(clump, s, 0.0, _near_radius, -1.0, 0.0, _near_radius * 0.72, _near_radius, 1.0)
		_far = _ring(clump, s * 2.0, _near_radius * 0.62, _far_radius, _near_radius * 0.62, _near_radius * 0.92,
			_far_radius * 0.72, _far_radius, 1.55)
		_snap = s * 2.0
	else:
		_near = _ring(clump, s, 0.0, near_out, -1.0, 0.0, near_out * 0.72, near_out, 1.0)
		_snap = s
	_clear_t = 0.0
	set_process(true)


func _ring(mesh: Mesh, spacing: float, r_in: float, r_out: float, f0: float, f1: float, f2: float, f3: float,
		scale: float) -> MultiMeshInstance3D:
	var xf: Array[Vector3] = []
	var n := int(ceil(r_out / spacing))
	for iz in range(-n, n + 1):
		for ix in range(-n, n + 1):
			var p := Vector2(ix, iz) * spacing
			var l := p.length()
			if l <= r_out + spacing and l >= r_in - spacing:
				xf.append(Vector3(p.x, 0.0, p.y))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xf.size()
	var buf := PackedFloat32Array()
	buf.resize(xf.size() * 12)
	for i in xf.size():
		var o := i * 12
		buf[o] = 1.0
		buf[o + 5] = 1.0
		buf[o + 10] = 1.0
		buf[o + 3] = xf[i].x
		buf[o + 7] = xf[i].y
		buf[o + 11] = xf[i].z
	mm.buffer = buf
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GrassNear" if r_in <= 0.0 else "GrassFar"
	mmi.multimesh = mm
	mmi.material_override = _mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mmi.custom_aabb = AABB(Vector3(-r_out - 2.0, -1.0, -r_out - 2.0), Vector3(r_out * 2.0 + 4.0, 3.0, r_out * 2.0 + 4.0))
	mmi.set_instance_shader_parameter(&"spacing", spacing)
	mmi.set_instance_shader_parameter(&"lod_scale", scale)
	mmi.set_instance_shader_parameter(&"lod_band", Vector4(f0, f1, f2, f3))
	add_child(mmi)
	return mmi


# ---------------------------------------------------------------- per frame

func _process(delta: float) -> void:
	if _near == null or _mat == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	# Field centre: where the screen centre's ray meets the ground.
	var vs := get_viewport().get_visible_rect().size
	var o := cam.project_ray_origin(vs * 0.5)
	var d := cam.project_ray_normal(vs * 0.5)
	var c := Vector3(o.x, 0.0, o.z)
	if d.y < -0.05:
		var t := -o.y / d.y
		c = o + d * t
		c.y = 0.0
	global_position = Vector3(snappedf(c.x, _snap), 0.0, snappedf(c.z, _snap))
	_mat.set_shader_parameter(&"field_center", c)
	if _far:
		_far.visible = cam.global_position.y > FAR_SHOW_HEIGHT
	var reach := (_far_radius if _far and _far.visible else _near_radius) + 2.0
	_push_t -= delta
	if _push_t <= 0.0:
		_push_t = PUSH_INTERVAL
		_update_pushers(c, reach)
	_clear_t -= delta
	if _clear_t <= 0.0:
		_clear_t = CLEAR_INTERVAL
		refresh_clears(c, reach)


## Keeps the nearest entries in the reused buffers of `pushers` (true) or `clears` (false): fills free slots, then
## replaces the farthest when `d2` is closer. (Packed arrays are values in GDScript: members are written directly.)
func _keep_nearest(pushers: bool, d2: float, v: Vector4) -> void:
	var k := MAX_PUSHERS if pushers else MAX_CLEARS
	var n := _push_n if pushers else _clear_n
	if n < k:
		if pushers:
			_push_buf[n] = v
			_push_d[n] = d2
			_push_n += 1
		else:
			_clear_buf[n] = v
			_clear_d[n] = d2
			_clear_n += 1
		return
	var worst := 0
	for i in range(1, k):
		if (_push_d[i] if pushers else _clear_d[i]) > (_push_d[worst] if pushers else _clear_d[worst]):
			worst = i
	if pushers and d2 < _push_d[worst]:
		_push_buf[worst] = v
		_push_d[worst] = d2
	elif not pushers and d2 < _clear_d[worst]:
		_clear_buf[worst] = v
		_clear_d[worst] = d2

## Units that flatten the grass. Only units the local player can see: FogOfWar hides (visible = false) every enemy /
## neutral unit outside the player's sight, so is_visible_in_tree() is the fog filter (no trampled grass betrays a
## hidden army). Runs every PUSH_INTERVAL; one pass over the group, nearest MAX_PUSHERS kept in reused buffers.
func _update_pushers(c: Vector3, reach: float) -> void:
	if _push_buf.size() != MAX_PUSHERS:
		_push_buf.resize(MAX_PUSHERS)
		_push_d.resize(MAX_PUSHERS)
	_push_n = 0
	var r2 := reach * reach
	for u in get_tree().get_nodes_in_group(&"units"):
		var n3 := u as Node3D
		if n3 == null:
			continue
		var p := n3.global_position
		var dx := p.x - c.x
		var dz := p.z - c.z
		var dd := dx * dx + dz * dz
		if dd > r2 or not n3.is_visible_in_tree():
			continue
		var r: Variant = n3.get(&"radius")
		var rad := (float(r) if (r is float or r is int) else 0.5) + 0.45
		_keep_nearest(true, dd, Vector4(p.x, p.z, rad, 0.0))
	if _mat:
		_mat.set_shader_parameter(&"pushers", _push_buf)
		_mat.set_shader_parameter(&"pusher_count", _push_n)


## True when the player may know this building / crystal node is there: shown now (FogOfWar hides enemy buildings
## outside sight and crystal nodes never explored), or seen once before (its fog ghost shows it anyway).
func _clear_known(n3: Node3D) -> bool:
	var id := n3.get_instance_id()
	if n3.is_visible_in_tree():
		_seen[id] = true
		return true
	return _seen.has(id)


## Recomputes the grass-free circles round buildings and crystal nodes near `c` (every CLEAR_INTERVAL; public for
## tests). Never one the player has not seen (fog: no bald patch betrays an unseen enemy building).
func refresh_clears(c: Vector3, reach: float) -> void:
	if _clear_buf.size() != MAX_CLEARS:
		_clear_buf.resize(MAX_CLEARS)
		_clear_d.resize(MAX_CLEARS)
	_clear_n = 0
	for g: StringName in [&"buildings", &"crystal_nodes"]:
		for b in get_tree().get_nodes_in_group(g):
			var n3 := b as Node3D
			if n3 == null or not n3.is_inside_tree():
				continue
			var rad := 2.0
			if n3.has_method(&"target_radius"):
				rad = float(n3.call(&"target_radius"))
			rad += 0.3
			var p := n3.global_position
			var dd := Vector2(p.x - c.x, p.z - c.z).length()
			if dd > reach + rad or not _clear_known(n3):
				continue
			_keep_nearest(false, dd * dd, Vector4(p.x, p.z, rad, 0.0))
	if _mat:
		_mat.set_shader_parameter(&"clears", _clear_buf)
		_mat.set_shader_parameter(&"clear_count", _clear_n)


## The grass-free circles in use (x, z, radius, 0) (tests / tools).
func clear_list() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for i in _clear_n:
		out.append(_clear_buf[i])
	return out