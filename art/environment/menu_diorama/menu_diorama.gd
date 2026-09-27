class_name MenuDiorama
extends Node3D
## The main menu's 3D background (task A2.10): the Ember Crown's altar at dusk, the four apprentices facing it
## from the four sides with their kingdom glows, three champions chatting at the tavern door in the background,
## a grove, rocks, a far treeline against a painted sunset, embers and fireflies. Its own WorldEnvironment, one
## sun (the only shadow caster), its own current Camera3D that drifts slowly. Not the game map.
##
## Scene: art/environment/menu_diorama/menu_diorama.tscn (hand-dressed: every prop is a node you can move in the
## editor). This script only animates (camera drift, the crown, the glows) and adds the cheap procedural bits
## (kingdom glows, far treeline MultiMeshes, fireflies). The instanced models are used read-only: their own idle
## animations run by themselves, only set_team_color / set_variant are called.
##
## Composition: the focal point (the crown) is drawn at `focus_screen` (0-1 of the screen, lens shift, so verticals
## stay vertical), left of the centred menu column; the tavern sits on the right third. The horizontal field grows
## with the aspect (Camera3D KEEP_HEIGHT), and the focal point moves from focus_screen (16:9) to focus_screen_wide
## (21:9) so it keeps clear of the centred menu panels on an ultrawide screen too.
##
## Public API:
##   set_paused(on: bool)            freezes the camera, the crown, every model and every particle (e.g. while the
##                                   game loads or the menu is hidden). Shader wobbles keep running (no cost).
##   is_paused() -> bool
##   focus_kingdom(kingdom)          &"fire" / &"shadow" / &"ice" / &"nature": the camera glides (2.4 s) to an
##                                   over-the-shoulder shot of that wizard (crown and rivals beyond) and its
##                                   kingdom glow swells; &"" (or an unknown id) = back to the wide shot.
##   get_focus() -> StringName
##   get_camera() -> Camera3D
## Performance: in its own SubViewport (the recommended menu integration) it renders the 3D at ~2 MP and upscales
## with FSR 1 (auto_render_scale); it never touches the root viewport.

const KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
## Glow colours (art-keep.md 0.2 "Glow" column) and team colours per kingdom.
const GLOW := {
	&"fire": Color(1.0, 0.55, 0.15),
	&"shadow": Color(0.70, 0.30, 1.0),
	&"ice": Color(0.75, 0.92, 1.0),
	&"nature": Color(0.75, 1.0, 0.40),
}
const TEAM := {
	&"fire": Color(0.85, 0.30, 0.12),
	&"shadow": Color(0.42, 0.22, 0.60),
	&"ice": Color(0.45, 0.75, 0.95),
	&"nature": Color(0.35, 0.70, 0.25),
}
const WIZARD_PATHS := {
	&"fire": ^"Wizards/Vessa",
	&"shadow": ^"Wizards/Malrik",
	&"ice": ^"Wizards/Torvald",
	&"nature": ^"Wizards/Ysolde",
}
const POOL_SHADER: Shader = preload("res://art/environment/crown/glow_pool.gdshader")
const FAR_TREES: Array[String] = [
	"res://art/environment/meshes/tree_pine_far.res",
	"res://art/environment/meshes/tree_fir_far.res",
	"res://art/environment/meshes/tree_broadleaf_far.res",
	"res://art/environment/meshes/tree_gold_far.res",
	"res://art/environment/meshes/tree_birch_far.res",
]
const TREE_SECTORS := 8          ## Far treeline MultiMeshes per species (frustum culling by sector).
const FOCUS_TIME := 2.4          ## Seconds of a camera glide between two shots.
const REF_ASPECT := 16.0 / 9.0
const WIDE_ASPECT := 21.0 / 9.0

@export_group("Wide shot")
## The point the camera orbits and frames (the crown).
@export var focus_point: Vector3 = Vector3(0.0, 1.7, 0.0)
## Direction from the focus to the camera, degrees (0 = camera on +Z, 90 = on +X).
@export var yaw_deg: float = 45.0
## Camera elevation above the focus, degrees.
@export var pitch_deg: float = 7.0
@export var distance: float = 32.0
## Vertical field of view, degrees.
@export var fov_deg: float = 34.0
## Where the focus point is drawn on a 16:9 screen (0-1, from the top-left).
@export var focus_screen: Vector2 = Vector2(0.2, 0.66)
## Same on a 21:9 screen (lerped by aspect between the two).
@export var focus_screen_wide: Vector2 = Vector2(0.27, 0.66)

@export_group("Altar")
## The Ember Crown altar's look (CrownPedestalArt manual hooks): 0 = awake (gold column of light),
## 1 = sealed (red chains and seal rings), 2 = stirring (the seal flickers, about to break).
@export_enum("Awake", "Sealed", "Stirring") var altar_look: int = 0

@export_group("Drift")
## Slow side-to-side sway of the camera around the focus, degrees (0 = still).
@export var drift_yaw_deg: float = 7.0
## Seconds of one full sway.
@export var drift_period: float = 70.0
## A continuous orbit on top of the sway, degrees per second (0 = none; try 1.5 for a full slow orbit).
@export var orbit_speed_deg: float = 0.0

@export_group("Far treeline")
@export var far_tree_count: int = 150
@export var outer_tree_count: int = 260
@export var far_radius_min: float = 38.0
@export var far_radius_max: float = 85.0

@export_group("Kingdom focus shot")
@export var focus_distance: float = 10.0
@export var focus_pitch_deg: float = 15.0
@export var focus_fov_deg: float = 32.0
## Camera angle from the wizard's facing, degrees. A wizard always faces the crown, so a front view loses the
## crown: 140 = over the shoulder, the wizard large on the left, the crown and the rivals facing us beyond.
@export var focus_side_deg: float = 140.0
@export var focus_shot_screen: Vector2 = Vector2(0.22, 0.6)
@export var focus_shot_screen_wide: Vector2 = Vector2(0.27, 0.6)

@export_group("Performance")
## Only when the diorama sits in its own SubViewport (never the game's root viewport): above `scale_above_megapixels`
## the 3D renders at a scale that keeps about `target_megapixels` of internal pixels (3440x1440 = 4.95 MP -> 0.6;
## 1600x900 and 1920x1080 stay native). The menu UI stays sharp. Keeps the GPU near 4 ms on a GTX 1660.
@export var auto_render_scale: bool = true
@export var target_megapixels: float = 1.8
@export var scale_above_megapixels: float = 2.2
@export var render_scale_min: float = 0.5
## FSR 1 (sharper) or bilinear upscaling of the 3D image.
@export var render_scale_fsr: bool = true

var _camera: Camera3D
var _crown: Node3D
var _crown_light: OmniLight3D
var _paused := false
var _time := 0.0
var _orbit := 0.0
var _focus: StringName = &""
var _from: Dictionary = {}
var _to: Dictionary = {}
var _blend := 1.0
var _pools: Dictionary = {}          # kingdom -> GeometryInstance3D
var _motes: Dictionary = {}          # kingdom -> GPUParticles3D
var _glow_level: Dictionary = {}     # kingdom -> smoothed 0-2
var _particles: Array[GPUParticles3D] = []
var _particle_speed: Array[float] = []
var _soft_tex: Texture2D


func _ready() -> void:
	_camera = get_node_or_null(^"Camera3D") as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		add_child(_camera)
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.projection = Camera3D.PROJECTION_FRUSTUM
	_camera.current = true
	_crown = get_node_or_null(^"Crown") as Node3D
	_crown_light = get_node_or_null(^"CrownLight") as OmniLight3D
	_dress_models()
	_build_kingdom_glows()
	_build_far_treeline()
	_build_fireflies()
	_collect_particles(self)
	_from = _shot_for(&"")
	_to = _from
	_blend = 1.0
	_update_camera(0.0)
	var vp := get_viewport()
	if auto_render_scale and vp is SubViewport:
		vp.size_changed.connect(_apply_render_scale)
		_apply_render_scale()


## 3D resolution scale of the own SubViewport (see auto_render_scale). Returns the scale set (1.0 = native).
func _apply_render_scale() -> float:
	var vp := get_viewport() as SubViewport
	if vp == null or not auto_render_scale:
		return 1.0
	var mp := float(vp.size.x) * float(vp.size.y) / 1000000.0
	var s := 1.0
	if mp > scale_above_megapixels:
		s = clampf(sqrt(target_megapixels / mp), render_scale_min, 1.0)
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if (render_scale_fsr and s < 0.999) \
			else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = s
	return s


# ---------------------------------------------------------------- public

## Freezes (true) or resumes (false) everything that moves: camera, crown, models, particles.
func set_paused(on: bool) -> void:
	if on == _paused:
		return
	_paused = on
	for i: int in _particles.size():
		var p := _particles[i]
		if is_instance_valid(p):
			p.speed_scale = 0.0 if on else _particle_speed[i]
	for n: Node in get_children():
		if n != _camera and not (n is WorldEnvironment) and not (n is Light3D):
			n.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
	set_process(not on)


func is_paused() -> bool:
	return _paused


## Glides the camera to a wizard (&"fire", &"shadow", &"ice", &"nature") or back to the wide shot (&"").
func focus_kingdom(kingdom: StringName) -> void:
	if kingdom != &"" and not WIZARD_PATHS.has(kingdom):
		kingdom = &""
	if kingdom == _focus:
		return
	_from = _current_shot()
	_focus = kingdom
	_to = _shot_for(kingdom)
	_blend = 0.0


func get_focus() -> StringName:
	return _focus


func get_camera() -> Camera3D:
	return _camera


# ---------------------------------------------------------------- frame

func _process(delta: float) -> void:
	if _paused:
		return
	_time += delta
	_orbit += orbit_speed_deg * delta
	if _blend < 1.0:
		_blend = minf(1.0, _blend + delta / FOCUS_TIME)
	_update_camera(delta)
	_animate_crown()
	_animate_glows(delta)


func _animate_crown() -> void:
	if _crown:
		_crown.rotation.y = _time * 0.55
		_crown.position.y = 1.8 + sin(_time * 1.4) * 0.12
	if _crown_light:
		_crown_light.light_energy = 2.2 + 0.25 * sin(_time * 2.3) + 0.15 * sin(_time * 5.1)


func _animate_glows(delta: float) -> void:
	var k := clampf(delta * 2.0, 0.0, 1.0)
	for kd: StringName in _pools:
		var target := 1.0
		if _focus != &"":
			target = 2.1 if kd == _focus else 0.55
		var g: float = lerpf(float(_glow_level.get(kd, 1.0)), target, k)
		_glow_level[kd] = g
		var pulse := 0.92 + 0.08 * sin(_time * 1.7 + float(KINGDOMS.find(kd)) * 1.6)
		(_pools[kd] as GeometryInstance3D).set_instance_shader_parameter(&"intensity", g * pulse)
		var m := _motes.get(kd) as GPUParticles3D
		if m:
			m.amount_ratio = clampf(0.35 + g * 0.45, 0.05, 1.0)


# ---------------------------------------------------------------- camera

## A shot: {target, yaw, pitch, dist, fov, screen, screen_wide} (degrees).
func _shot_for(kingdom: StringName) -> Dictionary:
	if kingdom == &"":
		return {"target": focus_point, "yaw": yaw_deg, "pitch": pitch_deg, "dist": distance, "fov": fov_deg,
				"screen": focus_screen, "screen_wide": focus_screen_wide}
	var w := get_node_or_null(WIZARD_PATHS[kingdom]) as Node3D
	if w == null:
		return _shot_for(&"")
	var face := w.global_transform.basis.z
	face.y = 0.0
	face = face.normalized()
	var face_yaw := rad_to_deg(atan2(face.x, face.z))
	# Of the two 3/4-front sides, take the one that shows the altar (in front of the wizard) on the screen's
	# right, away from the wizard who sits left of the menu column.
	var yaw := face_yaw + focus_side_deg
	var y := deg_to_rad(yaw)
	if face.x * cos(y) - face.z * sin(y) < 0.0:
		yaw = face_yaw - focus_side_deg
	var target := w.global_position + Vector3(0.0, 1.35, 0.0)
	# The camera orbits the wizard: "yaw" is the direction from the wizard to the camera.
	return {"target": target, "yaw": yaw, "pitch": focus_pitch_deg, "dist": focus_distance, "fov": focus_fov_deg,
			"screen": focus_shot_screen, "screen_wide": focus_shot_screen_wide}


func _current_shot() -> Dictionary:
	if _blend >= 1.0:
		return _to.duplicate()
	return _mix_shots(_from, _to, _ease(_blend))


func _mix_shots(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	return {
		"target": (a["target"] as Vector3).lerp(b["target"], t),
		"yaw": rad_to_deg(lerp_angle(deg_to_rad(a["yaw"]), deg_to_rad(b["yaw"]), t)),
		"pitch": lerpf(a["pitch"], b["pitch"], t),
		"dist": lerpf(a["dist"], b["dist"], t),
		"fov": lerpf(a["fov"], b["fov"], t),
		"screen": (a["screen"] as Vector2).lerp(b["screen"], t),
		"screen_wide": (a["screen_wide"] as Vector2).lerp(b["screen_wide"], t),
	}


func _ease(t: float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)   # smootherstep


func _update_camera(_delta: float) -> void:
	if _camera == null:
		return
	var s := _current_shot()
	var sway := sin(_time * TAU / maxf(drift_period, 1.0))
	var sway2 := sin(_time * TAU / maxf(drift_period * 0.63, 1.0) + 1.1)
	var yaw := deg_to_rad(float(s["yaw"]) + _orbit + drift_yaw_deg * sway)
	var pitch := deg_to_rad(float(s["pitch"]) + 1.2 * sway2)
	var dist := float(s["dist"]) * (1.0 + 0.035 * sway2)
	var target: Vector3 = s["target"]
	target.y += 0.12 * sin(_time * TAU / 23.0)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var pos := target + dir * dist
	_camera.global_transform = Transform3D(Basis.looking_at(target - pos, Vector3.UP), pos)
	# Lens shift: the focus point lands at `screen` without tilting the verticals.
	var aspect := REF_ASPECT
	var vp := get_viewport()
	if vp:
		var r := vp.get_visible_rect().size
		if r.y > 0.0:
			aspect = r.x / r.y
	var wide_t := clampf((aspect - REF_ASPECT) / (WIDE_ASPECT - REF_ASPECT), 0.0, 1.0)
	var sp: Vector2 = (s["screen"] as Vector2).lerp(s["screen_wide"], wide_t)
	var near := 0.1
	var h := 2.0 * near * tan(deg_to_rad(float(s["fov"])) * 0.5)
	var w := h * aspect
	_camera.set_frustum(h, Vector2((0.5 - sp.x) * w, (sp.y - 0.5) * h), near, 400.0)


# ---------------------------------------------------------------- dressing

func _dress_models() -> void:
	var altar := get_node_or_null(^"Altar")
	if altar and altar.has_method(&"set_sealed"):
		altar.call(&"set_sealed", altar_look != 0)
		if altar.has_method(&"set_stirring"):
			altar.call(&"set_stirring", altar_look == 2)
	if _crown_light and altar_look != 0:
		_crown_light.light_color = Color(1.0, 0.42, 0.22)
	for kd: StringName in WIZARD_PATHS:
		var w := get_node_or_null(WIZARD_PATHS[kd])
		if w and w.has_method(&"set_team_color"):
			w.call(&"set_team_color", TEAM[kd])
	# Champions: hired by the Fire kingdom (the player's default), each in its own look.
	var champs := get_node_or_null(^"Champions")
	if champs:
		var i := 0
		for c: Node in champs.get_children():
			if c.has_method(&"set_team_color"):
				c.call(&"set_team_color", TEAM[&"fire"])
			if c.has_method(&"set_variant"):
				c.call(&"set_variant", i % 2)
			i += 1
	# A Hunt bounty pinned by the tavern (Fire's gold).
	var flag := get_node_or_null(^"BountyFlag")
	if flag:
		if flag.has_method(&"set_team_color"):
			flag.call(&"set_team_color", TEAM[&"fire"])
		if flag.has_method(&"set_kind"):
			flag.call(&"set_kind", 0)


func _soft_texture() -> Texture2D:
	if _soft_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_soft_tex = t
	return _soft_tex


func _particle_draw_mesh(size: float) -> QuadMesh:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_texture()
	m.disable_receive_shadows = true
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = m
	return q


func _fade_ramp(c: Color) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
	var c0 := c
	c0.a = 0.0
	g.colors = PackedColorArray([c0, c, c, c0])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


## Under each wizard: a soft pool of its kingdom's glow on the ground and a few motes rising around it.
func _build_kingdom_glows() -> void:
	var holder := Node3D.new()
	holder.name = "KingdomGlows"
	add_child(holder)
	for kd: StringName in KINGDOMS:
		var w := get_node_or_null(WIZARD_PATHS[kd]) as Node3D
		if w == null:
			continue
		var c: Color = GLOW[kd]
		var pool := MeshInstance3D.new()
		pool.name = "Pool_%s" % kd
		var pm := PlaneMesh.new()
		pm.size = Vector2(3.6, 3.6)
		var mat := ShaderMaterial.new()
		mat.shader = POOL_SHADER
		mat.set_shader_parameter(&"color", c)
		mat.set_shader_parameter(&"strength", 1.1)
		mat.set_shader_parameter(&"inner", 0.0)
		mat.set_shader_parameter(&"falloff", 1.6)
		pm.material = mat
		pool.mesh = pm
		pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pool.position = Vector3(w.global_position.x, 0.04, w.global_position.z)
		holder.add_child(pool)
		_pools[kd] = pool
		_glow_level[kd] = 1.0

		var p := GPUParticles3D.new()
		p.name = "Motes_%s" % kd
		p.amount = 10
		p.lifetime = 3.2
		p.preprocess = 3.2
		p.randomness = 0.6
		p.visibility_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 4, 4))
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var pr := ParticleProcessMaterial.new()
		pr.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pr.emission_ring_axis = Vector3.UP
		pr.emission_ring_radius = 0.95
		pr.emission_ring_inner_radius = 0.45
		pr.emission_ring_height = 0.1
		pr.direction = Vector3.UP
		pr.spread = 12.0
		pr.initial_velocity_min = 0.25
		pr.initial_velocity_max = 0.6
		pr.gravity = Vector3(0, 0.05, 0)
		pr.tangential_accel_min = 0.15
		pr.tangential_accel_max = 0.35
		pr.scale_min = 0.6
		pr.scale_max = 1.2
		var hc := Color(c.r * 2.6, c.g * 2.6, c.b * 2.6, 1.0)
		pr.color_ramp = _fade_ramp(hc)
		p.process_material = pr
		p.draw_pass_1 = _particle_draw_mesh(0.14)
		p.position = Vector3(w.global_position.x, 0.15, w.global_position.z)
		holder.add_child(p)
		_motes[kd] = p


## A ring of far trees (one MultiMesh per species, no shadows): the dark treeline against the sunset.
## Scaled up with distance so it rises above the horizon line from the menu camera's height.
func _build_far_treeline() -> void:
	if far_tree_count <= 0:
		return
	var holder := Node3D.new()
	holder.name = "FarTreeline"
	add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41017
	# per[species * SECTORS + sector]: one MultiMesh per species and 45-degree sector, so the frustum culls the
	# sectors behind the camera.
	var per: Array[Array] = []
	for i: int in FAR_TREES.size() * TREE_SECTORS:
		per.append([])
	# Inner ring: scattered stands. Outer ring: a dense, taller band that closes the horizon (fully fogged).
	_scatter_ring(rng, per, far_tree_count, far_radius_min, far_radius_max, 1.5, 2.0, 1.6)
	_scatter_ring(rng, per, outer_tree_count, far_radius_max + 8.0, far_radius_max + 50.0, 2.4, 3.2, 1.25)
	for i: int in per.size():
		var species := i / TREE_SECTORS
		if per[i].is_empty() or not ResourceLoader.exists(FAR_TREES[species]):
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = load(FAR_TREES[species]) as Mesh
		mm.instance_count = per[i].size()
		for j: int in per[i].size():
			mm.set_instance_transform(j, per[i][j])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "%s_%d" % [FAR_TREES[species].get_file().get_basename(), i % TREE_SECTORS]
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mmi)
	# Behind the outer ring, a low band in the fog colour hides the horizon seen between far trunks from a low
	# camera (it sits past the fog end, so it reads as the same haze as the fogged ground).
	var wall := MeshInstance3D.new()
	wall.name = "HorizonBand"
	var cyl := CylinderMesh.new()
	cyl.top_radius = far_radius_max + 62.0
	cyl.bottom_radius = far_radius_max + 62.0
	cyl.height = 9.0
	cyl.radial_segments = 48
	cyl.rings = 1
	cyl.cap_top = false
	cyl.cap_bottom = false
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var env := (get_node_or_null(^"WorldEnvironment") as WorldEnvironment)
	wm.albedo_color = env.environment.fog_light_color if env and env.environment else Color(0.46, 0.38, 0.52)
	cyl.material = wm
	wall.mesh = cyl
	wall.position.y = 3.0
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(wall)


func _scatter_ring(rng: RandomNumberGenerator, per: Array[Array], count: int, r_min: float, r_max: float,
		s_min: float, s_max: float, grow: float) -> void:
	var weights: Array[float] = [0.34, 0.26, 0.2, 0.1, 0.1]
	for i: int in count:
		var a := rng.randf() * TAU
		var u := rng.randf()
		var r := lerpf(r_min, r_max, u * u * 0.55 + u * 0.45)
		var pos := Vector3(sin(a) * r, 0.0, cos(a) * r)
		var d := (r - r_min) / maxf(r_max - r_min, 1.0)
		var s := rng.randf_range(s_min, s_max) * lerpf(1.0, grow, d)
		var pick := rng.randf()
		var k := 0
		var acc := 0.0
		for j: int in weights.size():
			acc += weights[j]
			if pick <= acc:
				k = j
				break
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.9, 1.15), s))
		var sector := int(floor(a / TAU * float(TREE_SECTORS))) % TREE_SECTORS
		per[k * TREE_SECTORS + sector].append(Transform3D(b, pos))


## Fireflies / drifting ember motes over the plaza (warm, slow, 36 of them).
func _build_fireflies() -> void:
	var p := GPUParticles3D.new()
	p.name = "Fireflies"
	p.amount = 36
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.randomness = 0.8
	p.position = Vector3(0, 1.4, 0)
	p.visibility_aabb = AABB(Vector3(-16, -2, -16), Vector3(32, 7, 32))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pr := ParticleProcessMaterial.new()
	pr.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pr.emission_box_extents = Vector3(13, 1.1, 13)
	pr.direction = Vector3(0.3, 1, 0.1)
	pr.spread = 70.0
	pr.initial_velocity_min = 0.08
	pr.initial_velocity_max = 0.3
	pr.gravity = Vector3(0, 0.02, 0)
	pr.turbulence_enabled = true
	pr.turbulence_noise_strength = 0.6
	pr.turbulence_noise_scale = 3.0
	pr.turbulence_influence_min = 0.05
	pr.turbulence_influence_max = 0.15
	pr.scale_min = 0.5
	pr.scale_max = 1.1
	pr.color_ramp = _fade_ramp(Color(2.4, 1.35, 0.45, 1.0))
	p.process_material = pr
	p.draw_pass_1 = _particle_draw_mesh(0.11)
	add_child(p)


func _collect_particles(n: Node) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D:
			_particles.append(c as GPUParticles3D)
			_particle_speed.append((c as GPUParticles3D).speed_scale)
		_collect_particles(c)
