class_name ArtLabStage
extends Node
## Art Lab (docs/plan/art-lab.md): the render stage. A 1600 x 900 SubViewport (own world, MSAA 2x) with the skirmish
## ground (EnvProps ground material + Crown Hollow river / biome uniforms, like skirmish.gd), the lighting rig
## (preset "warm" like every map, or "ice"), a water plane under the river cut and the game camera (pitch 55, fov 50,
## rts_camera.gd). No gameplay. Three render modes:
##   lit   the game look (rig environment, sun, fill light, vignette, ground)
##   sil   black-on-white silhouettes (unshaded black override, white background, no ground / lights)
##   dark  emission only (black world, no lights, ambient 0, glow / bloom kept): what glows at 40 m

const W := 1600
const H := 900
const FOV := 50.0
const PITCH := 55.0
const RIG_PATH := "res://art/environment/lighting/lighting_rig.gd"
const WORLD_ENV_PATH := "res://art/environment/world_env.tres"
const GROUND_PARAMS_PATH := "res://art/environment/ground_params.gd"
const WATER_MAT_PATH := "res://art/environment/water/water_mat.tres"
## Skirmish (Crown Hollow) values used by skirmish.gd for the ground paint.
const PLAYER_START := Vector3(-36.0, 0.0, 36.0)
const SHADOW_START := Vector3(36.0, 0.0, -36.0)
const PILLAR_RING := 8.0
## Where each ground look is on the Crown Hollow map (map-fill.md 3.1 zones; checked away from roads, spots, water).
const GROUND_POINTS := {
	&"meadow": Vector3(-18.0, 0.0, 36.0),      # Hearth Meadow hub, west base, outside the dirt spot
	&"heath": Vector3(0.0, 0.0, 51.0),          # |z| > 44
	&"old_wood": Vector3(-40.0, 0.0, -40.0),   # Old Wood centre (-50, -50) r 28
	&"riverbank": Vector3(-14.5, 0.0, -30.0),  # 4 m from the north river's water edge
	&"dirt": Vector3(-29.0, 0.0, 36.0),        # the trodden base spot
	# step-12b terrains: flat stand-in patches off the Crown Hollow map, tinted with the biome set's GROUND_TINT
	&"snow": Vector3(140.0, 0.0, 140.0),
	&"ash": Vector3(140.0, 0.0, -140.0),
	&"sand": Vector3(-140.0, 0.0, 140.0),
	&"marsh": Vector3(-140.0, 0.0, -140.0),
}
## Stand-in terrain patches: ground id -> biome set script (its GROUND_TINT paints the patch).
const PATCH_SETS := {
	&"snow": "res://art/environment/biomes/snow/snow_set.gd",
	&"ash": "res://art/environment/biomes/ash/ash_set.gd",
	&"sand": "res://art/environment/biomes/sand/sand_set.gd",
	&"marsh": "res://art/environment/biomes/marsh/marsh_set.gd",
}
const PATCH_FALLBACK := {&"snow": Color(0.90, 0.93, 0.98), &"ash": Color(0.26, 0.235, 0.22),
	&"sand": Color(0.78, 0.66, 0.43), &"marsh": Color(0.24, 0.18, 0.11)}
var patches: Array[MeshInstance3D] = []

var vp: SubViewport
var world: Node3D
var cam: Camera3D
var rig: Node
var ground: MeshInstance3D
var water: MeshInstance3D
var env_node: WorldEnvironment
var env_lit: Environment
var env_sil: Environment
var env_dark: Environment
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var vignette: CanvasLayer
var mode: StringName = &"lit"
var black_mat: StandardMaterial3D
var white_mat: StandardMaterial3D
var _fill_on: bool = false
var env_hot: Environment
var glow_level: float = 1.1
var height_mat: ShaderMaterial
var preset_id: StringName = &"warm"   # the light preset this stage was built with
var _own: Array[Node] = []   # the stage's own world nodes (rig, ground, water, patches, camera): kept by reset()
## v3 1.D (a): how snow / ash / sand / marsh are painted: "terrain" = the step-12b TerrainSystem layers of
## ground.gdshader (terrain.md 7.1 `terrain_mask`) fed with a lab mask over the patch spots; "stand-in" = flat patches
## tinted with each biome set's GROUND_TINT (the ground shader has no terrain layers yet).
var terrain_mode: String = "stand-in"
const TERRAIN_ORIGIN := Vector2(-200.0, -200.0)
const TERRAIN_SIZE := 400.0
const TERRAIN_MASK_PX := 240
## terrain.md 7.1 mask channels: R snow, G sand, B ash, A marsh.
const TERRAIN_CHANNEL := {&"snow": 0, &"sand": 1, &"ash": 2, &"marsh": 3}
## v3 1.D (g): light presets the lab can switch to on a built stage (LightingRig presets + the autumn preset of
## style-autumn.md; "night" is a lab stand-in built from warm, see night_preset()).
const PRESET_PATHS := {
	&"warm": "res://art/environment/lighting/preset_warm.tres",
	&"ice": "res://art/environment/lighting/preset_ice.tres",
	&"autumn": "res://art/environment/autumn/preset_autumn.tres",
}
const AUTUMN_GROUND_PATH := "res://art/environment/autumn/autumn_ground_params.gd"
var light_now: StringName = &"warm"
var ground_look: StringName = &""
var _ground_mat_base: Material
var _ground_looks: Dictionary = {}   # look id -> material (built once)
var _night: Resource
## World height pass (P3 / P5 judge by world height, not screen rows): grey = (world y - y0) / span, unshaded.
const HEIGHT_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float y0 = 0.0;
uniform float span = 2.0;
varying float wy;
void vertex() { wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y; }
void fragment() { ALBEDO = vec3(clamp((wy - y0) / span, 0.0, 1.0)); }
"""


func setup(light_preset: StringName = &"warm") -> void:
	vp = SubViewport.new()
	vp.name = "LabViewport"
	vp.size = Vector2i(W, H)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	add_child(vp)
	world = Node3D.new()
	world.name = "World"
	vp.add_child(world)
	_build_lights(light_preset)
	_build_ground()
	cam = Camera3D.new()
	cam.name = "LabCamera"
	cam.fov = FOV
	cam.near = 0.2
	cam.far = 800.0
	world.add_child(cam)
	cam.current = true
	black_mat = _flat(Color.BLACK)
	white_mat = _flat(Color.WHITE)
	env_sil = Environment.new()
	env_sil.background_mode = Environment.BG_COLOR
	env_sil.background_color = Color.WHITE
	env_sil.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_sil.ambient_light_color = Color.WHITE
	env_sil.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env_dark = env_lit.duplicate() as Environment if env_lit else Environment.new()
	env_dark.background_mode = Environment.BG_COLOR
	env_dark.background_color = Color.BLACK
	env_dark.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_dark.ambient_light_color = Color.BLACK
	env_dark.ambient_light_energy = 0.0
	env_dark.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env_dark.fog_enabled = false
	env_dark.volumetric_fog_enabled = false
	# "hot": emission only, no bloom, linear tonemap scaled so a pixel saturates (255) exactly at the bloom level
	env_hot = env_dark.duplicate() as Environment
	env_hot.glow_enabled = false
	env_hot.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env_hot.tonemap_white = 1.0
	env_hot.adjustment_enabled = false
	glow_level = ArtLabBudgets.GLOW_HDR
	if env_lit and env_lit.glow_enabled and env_lit.glow_hdr_threshold > 0.5:
		glow_level = env_lit.glow_hdr_threshold   # the preset's own bloom level
	env_hot.tonemap_exposure = 1.0 / glow_level
	var hs := Shader.new()
	hs.code = HEIGHT_SHADER
	height_mat = ShaderMaterial.new()
	height_mat.shader = hs
	RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	preset_id = light_preset
	light_now = light_preset
	_own.assign(world.get_children())


## v3 batch: the render pipelines of the 4 modes compiled once (the first asset of a batch is not the one that pays).
func warm() -> void:
	for md: StringName in [&"lit", &"sil", &"hot", &"dark", &"lit"]:
		set_mode(md)
		await grab()


## v3 batch: back to a clean stage between two assets. Frees everything the last run added to the world (target,
## references, decor patch, VFX family...), lit mode, default camera. The ground, lights and shaders stay built.
func reset() -> void:
	var extra := false
	for c: Node in world.get_children():
		if not c in _own:
			world.remove_child(c)
			c.queue_free()
			extra = true
	if light_now != preset_id:
		set_light(preset_id)
	if ground_look != &"":
		set_ground_look(&"")
	set_mode(&"lit")
	game_cam(Vector3.ZERO, 40.0)
	if extra:
		await get_tree().process_frame


func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _build_lights(preset: StringName) -> void:
	if ResourceLoader.exists(RIG_PATH):
		rig = (load(RIG_PATH) as GDScript).new()
		rig.set(&"preset_id", preset)
		world.add_child(rig)
		env_node = rig.get(&"world_environment")
		sun = rig.get(&"sun")
		fill = rig.get(&"fill")
		vignette = rig.get(&"vignette")
		env_lit = env_node.environment
		_fill_on = fill != null and fill.visible
		return
	env_node = WorldEnvironment.new()
	env_lit = load(WORLD_ENV_PATH) as Environment if ResourceLoader.exists(WORLD_ENV_PATH) else Environment.new()
	env_node.environment = env_lit
	world.add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = true
	world.add_child(sun)


func _build_ground() -> void:
	ground = MeshInstance3D.new()
	ground.name = "Ground"
	var pm := PlaneMesh.new()
	pm.size = Vector2(400.0, 400.0)
	ground.mesh = pm
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var spots: Array[Vector4] = [Vector4(PLAYER_START.x, PLAYER_START.z, 13.0, 0.0),
		Vector4(SHADOW_START.x, SHADOW_START.z, 13.0, 0.0), Vector4(0.0, 0.0, PILLAR_RING + 1.5, 1.0)]
	var mat: ShaderMaterial = EnvProps.ground_material(PLAYER_START, SHADOW_START, spots)
	if mat and ResourceLoader.exists(GROUND_PARAMS_PATH):
		var gp: GDScript = load(GROUND_PARAMS_PATH)
		gp.call(&"apply", mat, gp.call(&"skirmish_river"))
		gp.call(&"apply", mat, gp.call(&"skirmish_biomes"))
	if mat:
		ground.material_override = mat
	else:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.32, 0.43, 0.20)
		ground.material_override = sm
	world.add_child(ground)
	water = MeshInstance3D.new()
	water.name = "Water"
	var wm := PlaneMesh.new()
	wm.size = Vector2(400.0, 400.0)
	water.mesh = wm
	water.position.y = -0.35
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if ResourceLoader.exists(WATER_MAT_PATH):
		water.material_override = load(WATER_MAT_PATH) as Material
	world.add_child(water)
	_ground_mat_base = ground.material_override
	if apply_terrain(ground.material_override as ShaderMaterial):
		terrain_mode = "terrain"
		return   # the real terrain layers paint snow / ash / sand / marsh: no stand-in patches
	for gid: StringName in PATCH_SETS:
		var tint: Color = PATCH_FALLBACK[gid]
		var sp: String = PATCH_SETS[gid]
		if ResourceLoader.exists(sp):
			var scr := load(sp) as GDScript
			if scr and scr.get_script_constant_map().has("GROUND_TINT"):
				tint = scr.get_script_constant_map()["GROUND_TINT"]
		var pmi := MeshInstance3D.new()
		pmi.name = "Patch_" + String(gid)
		var pm2 := PlaneMesh.new()
		pm2.size = Vector2(120.0, 120.0)
		pmi.mesh = pm2
		pmi.position = GROUND_POINTS[gid] + Vector3(0.0, 0.01, 0.0)
		pmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var sm2 := StandardMaterial3D.new()
		sm2.albedo_color = tint
		sm2.roughness = 1.0
		pmi.material_override = sm2
		world.add_child(pmi)
		patches.append(pmi)


## v3 1.D (a): when ground.gdshader has the step-12b terrain layers (terrain.md 7.1: `terrain_enabled`,
## `terrain_mask`, `terrain_origin`, `terrain_size`), paint the snow / sand / ash / marsh spots of GROUND_POINTS into a
## lab mask (120 m squares, like the stand-in patches) and turn the layers on. False = no terrain layers (stand-ins).
func apply_terrain(mat: ShaderMaterial) -> bool:
	if mat == null or mat.shader == null:
		return false
	var names := {}
	for u: Dictionary in mat.shader.get_shader_uniform_list():
		names[String(u.get("name", ""))] = true
	if not (names.has("terrain_mask") and names.has("terrain_enabled")):
		return false
	mat.set_shader_parameter(&"terrain_mask", ImageTexture.create_from_image(terrain_mask_image()))
	mat.set_shader_parameter(&"terrain_enabled", true)
	if names.has("terrain_origin"):
		mat.set_shader_parameter(&"terrain_origin", TERRAIN_ORIGIN)
	if names.has("terrain_size"):
		mat.set_shader_parameter(&"terrain_size", TERRAIN_SIZE)
	return true


## The lab's terrain mask (terrain.md 7.1 layout: R snow, G sand, B ash, A marsh) over TERRAIN_ORIGIN / TERRAIN_SIZE:
## a 120 m square of full weight at each stand-in spot of GROUND_POINTS.
static func terrain_mask_image() -> Image:
	var n := TERRAIN_MASK_PX
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for gid: StringName in TERRAIN_CHANNEL:
		var p: Vector3 = GROUND_POINTS[gid]
		var ch: int = TERRAIN_CHANNEL[gid]
		var x0 := int((p.x - 60.0 - TERRAIN_ORIGIN.x) / TERRAIN_SIZE * float(n))
		var y0 := int((p.z - 60.0 - TERRAIN_ORIGIN.y) / TERRAIN_SIZE * float(n))
		var s := int(120.0 / TERRAIN_SIZE * float(n))
		for y: int in range(maxi(y0, 0), mini(y0 + s, n)):
			for x: int in range(maxi(x0, 0), mini(x0 + s, n)):
				var c := img.get_pixel(x, y)
				c[ch] = 1.0
				img.set_pixel(x, y, c)
	return img


## One line for the scorecard notes: what paints snow / ash / sand / marsh in this stage.
func terrain_note() -> String:
	if terrain_mode == "terrain":
		return "terrain: snow / ash / sand / marsh painted by the step-12b ground-shader terrain layers (lab mask, 120 m per spot)"
	return "terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no " + \
		"step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist"


## A light preset resource by id (&"warm", &"ice", &"autumn" from PRESET_PATHS; &"night" = night_preset()); null if
## missing.
func light_preset(id: StringName) -> Resource:
	if id == &"night":
		return night_preset()
	var path: String = PRESET_PATHS.get(id, "")
	return load(path) if path != "" and ResourceLoader.exists(path) else null


## Lab stand-in for a night mood (no night preset in art/environment/lighting yet): the warm preset with a dim cool
## moon sun, a low cool ambient, a darker sky and a stronger dark vignette.
func night_preset() -> Resource:
	if _night != null:
		return _night
	var base: Resource = light_preset(&"warm")
	if base == null:
		return null
	var p := base.duplicate() as Resource
	var env0: Environment = base.get(&"environment")
	if env0:
		var env := env0.duplicate() as Environment
		env.ambient_light_color = Color(0.42, 0.50, 0.78)
		env.ambient_light_energy = env0.ambient_light_energy * 0.45
		env.background_energy_multiplier = env0.background_energy_multiplier * 0.3
		if env.fog_enabled:
			env.fog_light_color = Color(0.16, 0.20, 0.32)
			env.fog_light_energy = env0.fog_light_energy * 0.5
		p.set(&"environment", env)
	p.set(&"sun_color", Color(0.62, 0.72, 1.0))
	p.set(&"sun_energy", 0.5)
	p.set(&"fill_color", Color(0.35, 0.45, 0.9))
	p.set(&"fill_energy", 0.3)
	p.set(&"vignette_color", Color(0.02, 0.03, 0.08))
	p.set(&"vignette_strength", 0.55)
	p.set(&"haze_strength", 0.0)
	_night = p
	return p


## v3 1.D (g): switches the built stage to another light preset (the rig's apply()). The dark / hot / sil passes keep
## the build preset's settings. reset() switches back. False when the preset or the rig is missing.
func set_light(id: StringName) -> bool:
	if rig == null or not rig.has_method(&"apply"):
		return false
	var p := light_preset(id)
	if p == null:
		return false
	rig.call(&"apply", p)
	env_lit = env_node.environment
	_fill_on = fill != null and fill.visible
	light_now = id
	set_mode(mode)
	return true


## v3 1.D (f): a ground colour look on the same zones: &"autumn" = the autumn_ground_params.gd colours
## (style-autumn.md 1.1) on a copy of the ground material; &"" = back to the skirmish ground.
func set_ground_look(look: StringName) -> bool:
	if look == &"":
		ground.material_override = _ground_mat_base
		ground_look = &""
		return true
	if not _ground_looks.has(look):
		if look != &"autumn" or not ResourceLoader.exists(AUTUMN_GROUND_PATH) or not (_ground_mat_base is ShaderMaterial):
			return false
		var mat := (_ground_mat_base as ShaderMaterial).duplicate() as ShaderMaterial
		var ap := load(AUTUMN_GROUND_PATH) as GDScript
		if ap == null or int(ap.call(&"apply", mat)) == 0:
			return false
		_ground_looks[look] = mat
	ground.material_override = _ground_looks[look]
	ground_look = look
	return true


## Switches the render mode (lit / sil / dark). Model overrides are separate (override_black / restore).
func set_mode(m: StringName) -> void:
	mode = m
	var lit := m == &"lit"
	env_node.environment = env_lit if lit else (env_sil if m == &"sil" else (env_hot if m == &"hot" else env_dark))
	ground.visible = lit
	water.visible = lit
	for p: MeshInstance3D in patches:
		p.visible = lit
	if sun:
		sun.visible = lit
	if fill:
		fill.visible = lit and _fill_on
	if vignette:
		vignette.visible = lit


## The game camera (rts_camera.gd): pitch 55, fov 50, `zoom` metres from the focus point along the view axis.
func game_cam(focus: Vector3, zoom: float, pitch_deg: float = PITCH, yaw_deg: float = 0.0) -> void:
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	cam.position = focus + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * zoom
	cam.rotation = Vector3(-p, y, 0.0)


## A camera that frames `box` (world AABB) from pitch / yaw, the box filling `fill` of the frame height.
func fit_cam(box: AABB, pitch_deg: float, yaw_deg: float, fill: float = 0.8) -> void:
	var r := maxf(box.size.length() * 0.5, 0.3)
	var d := r / tan(deg_to_rad(FOV * 0.5)) / fill
	game_cam(box.get_center(), d, pitch_deg, yaw_deg)


## Screen rect (viewport px) of a world AABB, grown by `margin`, clamped to the frame.
func roi_of(box: AABB, margin: int = 12) -> Rect2i:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i: int in 8:
		var c := box.get_endpoint(i)
		if cam.is_position_behind(c):
			continue
		var s := cam.unproject_position(c)
		lo = lo.min(s)
		hi = hi.max(s)
	if lo.x == INF:
		return Rect2i(0, 0, W, H)
	var r := Rect2i(Vector2i(int(floor(lo.x)), int(floor(lo.y))), Vector2i(int(ceil(hi.x - lo.x)) + 1, int(ceil(hi.y - lo.y)) + 1))
	return ArtLabImage.clamp_rect(r, margin, W, H)


## Renders the next frames and returns the viewport image (RGBA8).
func grab() -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


## Measured render time of the lab viewport (ms): Vector2(cpu, gpu).
func render_ms() -> Vector2:
	var rid := vp.get_viewport_rid()
	return Vector2(RenderingServer.viewport_get_measured_render_time_cpu(rid),
		RenderingServer.viewport_get_measured_render_time_gpu(rid))


## Puts `mat` on every drawn part under `root` (null = hide it); particles and flat decals are hidden. Returns the
## records for restore(). `ground_y` = world y of the ground (flat-decal test).
func override(root: Node, mat: Material, ground_y: float, hide_particles: bool = true) -> Array:
	var rec: Array = []
	for gi: GeometryInstance3D in ArtLabCensus.geometry(root):
		rec.append([gi, gi.material_override, gi.visible, gi.material_overlay])
		if (hide_particles and ArtLabCensus.is_particles(gi)) or ArtLabCensus.is_flat_decal(gi, ground_y):
			gi.visible = false
			continue
		if mat == null:
			gi.visible = false
		elif not ArtLabCensus.is_particles(gi):
			gi.material_override = mat
			gi.material_overlay = null
	for d: Node in root.find_children("*", "Decal", true, false):
		rec.append([d, null, (d as Decal).visible, null])
		(d as Decal).visible = false
	return rec


func restore(rec: Array) -> void:
	for r: Array in rec:
		var n: Object = r[0]
		if not is_instance_valid(n):
			continue
		if n is GeometryInstance3D:
			(n as GeometryInstance3D).material_override = r[1]
			(n as GeometryInstance3D).material_overlay = r[3]
		(n as Node3D).visible = r[2]


## Freezes / thaws a model's animation (its _process), so several passes see the same pose.
static func freeze(n: Node, on: bool) -> void:
	if is_instance_valid(n):
		n.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
