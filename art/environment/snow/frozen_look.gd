class_name FrozenLook
extends RefCounted
## G-E fixes B (docs/art/ge_fixes_b.md, review item 8): the frozen-map look, built in code, draw-only.
## - `GROUND`: the painted ground (art/environment/ground.gdshader) in snow at a readable value (~0.78 lit, not paper
##   white), packed-snow paths, snow-laden firs on the border canopy (no more pale "fish scales"), `snow_mode` on =
##   sastrugi + drift shading + no 3D grass blades; `snow_sparkle` per graphics tier (0 at Low = no glints).
## - `drift_mesh(rseed, length, depth, height)`: an irregular wind drift (gentle windward side, steeper lee, lumpy crest,
##   sunk skirt) to replace capsule snowbanks; `snow_material()` (snow_drift.gdshader, shared).
## - `lake_material(radius, old_ice)`: frozen lake ice (frozen_lake.gdshader: depth, plates, fractures, bubbles, snow
##   dust, frosted rim); `shore_lip(radius)`: a low noisy snow lip round a lake so the ice sits in the snow.
## - `dress_level(level)`: restyles a built frozen level once (idempotent, meta `_frozen_look`): the ground, every node in
##   group "snowbanks" (its MeshInstance3D child gets a drift), the rock snow caps (level children with a SphereMesh in
##   the old bank white), the lake in group "glasswater_lake" (its "IceDisc" + a ShoreLip), then GroundDetail.refresh().
##   Mission 2 calls it at the end of `_build_map` (docs/handoff/for-systems-coder.md); no colliders, nav or gameplay change.

const GROUND_SHADER := "res://art/environment/ground.gdshader"
const DRIFT_SHADER := preload("res://art/environment/snow/snow_drift.gdshader")
const LAKE_SHADER := preload("res://art/environment/snow/frozen_lake.gdshader")
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const META := &"_frozen_look"
const OLD_BANK_WHITE := Color(0.92, 0.94, 0.98)   ## mission_02.gd BANK_COLOR (the placeholder caps to restyle)
const SPARKLE: Array[float] = [0.0, 0.7, 1.0, 1.0]   ## glint strength per tier (Low = none)

## Ground values (ground.gdshader uniforms). Lit snow lands at ~0.78 on screen under the ice preset (measured in
## docs/art/ge_fixes_b.md), shade ~0.6 blue.
const GROUND := {
	&"grass_dark": Color(0.47, 0.50, 0.55), &"grass_light": Color(0.59, 0.61, 0.64),
	&"grass_warm": Color(0.60, 0.60, 0.61), &"grass_cool": Color(0.46, 0.50, 0.58),
	&"grass_dry": Color(0.57, 0.58, 0.60), &"clover_color": Color(0.50, 0.53, 0.59),
	&"patch_contrast": 0.7,
	&"dirt_color": Color(0.48, 0.49, 0.53), &"dirt_dark": Color(0.36, 0.38, 0.43),
	&"pebble_color": Color(0.40, 0.42, 0.46), &"paving_color": Color(0.52, 0.53, 0.56),
	&"canopy_dark": Color(0.09, 0.16, 0.17), &"canopy_light": Color(0.70, 0.75, 0.82),
	&"rock_color": Color(0.40, 0.43, 0.50), &"haze_color": Color(0.66, 0.73, 0.83),
	&"tuft_density": 0.0, &"flower_amount": 0.0, &"groove_energy": 0.0,
	&"snow_mode": 1.0, &"snow_shade": Color(0.60, 0.68, 0.84), &"snow_wind": Vector2(0.82, 0.57),
}

static var _snow_mat: ShaderMaterial = null


## The graphics tier (0 Low .. 3 Ultra): GameSettings.effective_graphics_quality(), load-guarded (High without it).
static func tier() -> int:
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return 2
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs and gs.has_method(&"effective_graphics_quality"):
		return clampi(int(gs.call(&"effective_graphics_quality")), 0, 3)
	return 2


## Puts the snow look on a painted ground material (any ShaderMaterial on ground.gdshader).
static func apply_ground(mat: ShaderMaterial, q: int = -1) -> void:
	if mat == null:
		return
	for k: StringName in GROUND:
		mat.set_shader_parameter(k, GROUND[k])
	mat.set_shader_parameter(&"snow_sparkle", SPARKLE[clampi(tier() if q < 0 else q, 0, 3)])


## The shared wind-packed snow material (drifts, caps, shore lip). Glints follow the tier of the first call.
static func snow_material() -> ShaderMaterial:
	if _snow_mat == null:
		_snow_mat = ShaderMaterial.new()
		_snow_mat.shader = DRIFT_SHADER
	_snow_mat.set_shader_parameter(&"sparkle", SPARKLE[tier()] * 0.8)
	return _snow_mat


## Frozen lake ice for a disc of `radius` centred on its node.
static func lake_material(radius: float = 22.0, old_ice: float = 7.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = LAKE_SHADER
	m.set_shader_parameter(&"lake_radius", radius)
	m.set_shader_parameter(&"old_ice", old_ice)
	return m


## An irregular snow drift, local x = along the drift (length), z = across (depth), y up, base at y = 0 with a skirt
## sunk to -0.25. Windward side = -z (gentle), lee = +z (steeper, a slight cornice). Vertex COLOR.r = height 0..1.
static func drift_mesh(rseed: int, length: float = 6.5, depth: float = 3.2, height: float = 1.6) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rseed
	var nx := 22
	var nz := 12
	# A crest line along x: 2-3 humps of different heights, never a constant tube.
	var humps: Array[Vector3] = []   # (x centre -1..1, width, height factor)
	for i in rng.randi_range(2, 3):
		humps.append(Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(0.35, 0.7), rng.randf_range(0.55, 1.0)))
	var crest_z := rng.randf_range(0.05, 0.3)   # crest toward the lee
	var lean := rng.randf_range(-0.12, 0.12)   # the crest drifts across the length
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts: Array[Vector3] = []
	var hs: Array[float] = []
	for j in nz + 1:
		var v := float(j) / float(nz) * 2.0 - 1.0          # -1 windward .. 1 lee
		for i in nx + 1:
			var u := float(i) / float(nx) * 2.0 - 1.0      # -1 .. 1 along
			# Footprint: an ellipse with a wobbly outline; outside it the skirt drops below the ground.
			var wob := 1.0 + 0.12 * sin(u * 5.1 + float(rseed)) + 0.08 * sin(v * 4.3 + float(rseed) * 0.7)
			var cz := crest_z + lean * u
			var along := 0.0
			for h: Vector3 in humps:
				along = maxf(along, h.z * exp(-pow((u - h.x) / h.y, 2.0)))
			along = maxf(along, 0.35 * (1.0 - u * u))
			var across := 0.0
			if v < cz:
				across = pow(clampf((v + 1.0) / (cz + 1.0), 0.0, 1.0), 1.6)        # long gentle windward slope
			else:
				across = pow(clampf(1.0 - (v - cz) / (1.0 - cz + 0.001), 0.0, 1.0), 0.55)   # short steep lee
			var edge := clampf(1.0 - pow(absf(u) * wob, 3.0), 0.0, 1.0)
			var h01 := clampf(along * across * edge, 0.0, 1.0)
			h01 *= 1.0 + 0.06 * sin(u * 13.0 + v * 7.0 + float(rseed))
			var y := h01 * height - 0.25 * (1.0 - smoothstep(0.0, 0.08, h01))
			var x := u * length * 0.5
			var z := v * depth * 0.5 + (0.12 * height * h01 * smoothstep(0.6, 1.0, h01) if v > cz else 0.0)
			verts.append(Vector3(x, y, z))
			hs.append(h01)
	for j in nz:
		for i in nx:
			var a := j * (nx + 1) + i
			var b := a + 1
			var c := a + nx + 1
			var d := c + 1
			for k: int in [a, b, c, b, d, c]:
				st.set_color(Color(hs[k], 0.0, 0.0))
				st.add_vertex(verts[k])
	st.index()
	st.generate_normals()
	return st.commit()


## A low snow lip (inner radius - 0.6 .. + 1.6 m, ~0.3 m high, noisy) round a lake of `radius`, base at y = 0.
static func shore_lip(radius: float, rseed: int = 1202) -> ArrayMesh:
	var segs := 128
	var rings := 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts: Array[Vector3] = []
	var hs: Array[float] = []
	for s in segs:
		var a := TAU * float(s) / float(segs)
		var n := 0.5 + 0.3 * sin(a * 7.0 + float(rseed)) + 0.2 * sin(a * 17.0 + float(rseed) * 0.3)
		for k in rings + 1:
			var t := float(k) / float(rings)          # 0 lake side .. 1 land side
			var r := radius - 0.6 + t * (2.2 + n * 0.8)
			var h01 := sin(t * PI) * (0.6 + 0.4 * n)
			var y := h01 * 0.32 - 0.06
			verts.append(Vector3(cos(a) * r, y, sin(a) * r))
			hs.append(h01)
	for s in segs:
		var s2 := (s + 1) % segs
		for k in rings:
			var a := s * (rings + 1) + k
			var b := a + 1
			var c := s2 * (rings + 1) + k
			var d := c + 1
			for idx: int in [a, b, c, c, b, d]:
				st.set_color(Color(hs[idx], 0.0, 0.0))
				st.add_vertex(verts[idx])
	st.index()
	st.generate_normals()
	return st.commit()


## Restyles a built frozen level once (see the header). True when the ground was found.
static func dress_level(level: Node) -> bool:
	if level == null or not is_instance_valid(level):
		return false
	if level.has_meta(META):
		return true
	level.set_meta(META, true)
	var q := tier()
	var found := false
	for n: Node in level.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == GROUND_SHADER and mi.mesh is PlaneMesh:
			apply_ground(sm, q)
			found = true
	var snow := snow_material()
	var tree := level.get_tree() if level.is_inside_tree() else null
	if tree:
		for b: Node in tree.get_nodes_in_group(&"snowbanks"):
			if b is Node3D and level.is_ancestor_of(b):
				_dress_bank(b as Node3D, snow)
		for lake: Node in tree.get_nodes_in_group(&"glasswater_lake"):
			if lake is Node3D and level.is_ancestor_of(lake):
				_dress_lake(lake as Node3D, snow)
	for c: Node in level.get_children():
		var cap := c as MeshInstance3D
		if cap and cap.mesh is SphereMesh and cap.material_override is StandardMaterial3D \
				and (cap.material_override as StandardMaterial3D).albedo_color.is_equal_approx(OLD_BANK_WHITE):
			cap.material_override = snow
			cap.scale = Vector3(cap.scale.x * 1.1, cap.scale.y * 0.7, cap.scale.z * 1.1)   # a flatter cap, less "ball"
	for gd: Node in level.find_children("GroundDetail", "", false, false):
		if gd.has_method(&"refresh"):
			gd.call(&"refresh")
	return found


static func _dress_bank(body: Node3D, snow: ShaderMaterial) -> void:
	var rseed := absi(hash(String(body.name)))
	var rng := RandomNumberGenerator.new()
	rng.seed = rseed
	for c: Node in body.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		# The collider is 5 x 1.8 x 2.5; neighbours sit 4.45 m apart on the ring, so 6-7.4 m drifts merge into one
		# uneven wall with gaps of height, not a row of pills.
		mi.mesh = drift_mesh(rseed, rng.randf_range(6.0, 7.4), rng.randf_range(3.0, 3.8), rng.randf_range(1.25, 2.05))
		mi.material_override = snow
		mi.scale = Vector3.ONE
		mi.rotation = Vector3(0.0, rng.randf_range(-0.12, 0.12), 0.0)
		mi.position = Vector3(rng.randf_range(-0.4, 0.4), -body.global_position.y, rng.randf_range(-0.3, 0.3))
		if rng.randf() < 0.5:
			mi.rotation.y += PI   # lee side out or in: the wall does not repeat one profile


static func _dress_lake(lake: Node3D, snow: ShaderMaterial) -> void:
	var disc := lake.get_node_or_null(^"IceDisc") as MeshInstance3D
	var consts: Dictionary = (lake.get_script() as Script).get_script_constant_map() if lake.get_script() else {}
	var radius := float(consts.get("LAKE_RADIUS", 22.0))
	var old_ice := float(consts.get("OLD_ICE", 7.0))
	if disc:
		disc.material_override = lake_material(radius, old_ice)
	if lake.get_node_or_null(^"ShoreLip") == null:
		var lip := MeshInstance3D.new()
		lip.name = "ShoreLip"
		lip.mesh = shore_lip(radius)
		lip.material_override = snow
		lip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lake.add_child(lip)
