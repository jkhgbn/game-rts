class_name ForestMood
extends Node3D
## G-E fixes C, review item 9 (docs/art/ge_review.md, docs/art/ge_fixes_c.md): turns mission 3's map (the Sighing Wood)
## from Crown Hollow's meadow into an old wood. Draw-only: no collider, no navmesh effect, no gameplay.
##   ground   the level's own ground material (a per-level copy, nothing shared) paints the Old Wood biome over the wood
##            (dark moss / needle floor, ground.gdshader biome zones), Hearth Meadow round the two bases; MapDressingArt
##            then scatters the Old Wood set there (ferns, glowcaps, moss boulders, fallen trunks) instead of glade
##            flowers, at `DECOR_DENSITY`. Every tier (colours + decor kinds; Map detail Low halves the decor as before).
##   light    the level's LightingRig gets preset_forest.tres (green-gold sun through leaves, a cool green fill, a mossy
##            vignette; same Environment as the warm preset). Every tier.
##   shade    High+: a ceiling of shadow-only leaf masses (one MultiMesh, SHADOWS_ONLY) dapples the wood with canopy
##            shade; placed from the sun's direction so the shade lands where it is meant to. Never over a clearing.
##   shafts   High+: ~12 sun shafts (light_shaft.gdshader: additive, unshaded, fog_disabled, depth_draw_never) leaning
##            toward the sun in the gaps of the canopy. Fog of war: a shaft draws only where the local player sees now
##            (VfxFog.ok, re-checked 4 x a second, faded), like every transparent effect over the fog overlay.
##   props    Oldroot / Warden Gate: until mission_03.gd / warden_gate.gd load the art scenes themselves (the request in
##            docs/handoff/for-systems-coder.md), this hides their placeholder meshes and adds art/environment/ge_props/
##            oldroot.tscn and warden_gate_art.tscn (draw-only). A body that already has the art is left alone.
## Low = the cost before G1 at every tier where it matters: no shade, no shafts below High.
## Which levels: `LEVELS` (the level script's MISSION_ID), or any level with a `forest_mood() -> bool` method that
## returns true. Hook: LevelLooks.apply (art/environment/level_looks.gd) from GroundDetail._ready, before the map
## dressing populates and before GroundDetail bakes the ground; `ensure_for_level(level)` is idempotent.

const LEVELS: Array[StringName] = [&"m03"]
const NODE_NAME := &"ForestMood"
const DIR := "res://art/environment/sighing_wood/"
const PRESET := DIR + "preset_forest.tres"
const SHAFT_SHADER := DIR + "light_shaft.gdshader"
const OLDROOT_SCENE := "res://art/environment/ge_props/oldroot.tscn"
const GATE_SCENE := "res://art/environment/ge_props/warden_gate_art.tscn"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const GROUND_PARAMS := "res://art/environment/ground_params.gd"
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
## Old Wood zones (ground.gdshader biome_woods: two centres + one radius) and the two base hubs (Hearth Meadow).
const WOODS := Vector4(-26.0, -26.0, 26.0, 26.0)
const WOOD_RADIUS := 46.0
const HUBS := Vector4(-36.0, 36.0, 36.0, -36.0)
const HUB_RADIUS := 20.0
const DECOR_DENSITY := 0.8          ## MapDressingArt.density_scale on this map (the wood is ~4x Crown Hollow's woods)
const SHADE_HEIGHT := 17.0
const SHADE_STEP := 7.5             ## grid of the canopy masses (m)
const SHADE_KEEP := 0.55            ## share of grid cells that get a leaf mass (the rest = sun gaps)
const SHAFTS := 12
const SHAFT_LEN := 10.0
const FOG_RECHECK := 0.25

## Tests / tools: >= 0 beats the settings (0 Low .. 3 Ultra).
static var quality_override := -1

var quality := 2
var shade: MultiMeshInstance3D
var shafts: MultiMeshInstance3D
var _level: Node
var _shaft_pos := PackedVector3Array()
var _shaft_alpha := PackedFloat32Array()
var _shaft_target := PackedFloat32Array()
var _shaft_custom := PackedColorArray()   # CPU copy of each shaft's custom data (seed, width, length, fade)
var _fog_t := 0.0
var _rng := RandomNumberGenerator.new()


## True when `level` should look like a forest (MISSION_ID in LEVELS, or its `forest_mood()` says so).
static func wants(level: Node) -> bool:
	if level == null:
		return false
	if level.has_method(&"forest_mood"):
		return bool(level.call(&"forest_mood"))
	var s := level.get_script() as Script
	if s == null:
		return false
	var id: Variant = s.get_script_constant_map().get("MISSION_ID")
	return id != null and StringName(str(id)) in LEVELS


## The level's ForestMood (created as its child when the level wants one), or null.
static func ensure_for_level(level: Node) -> ForestMood:
	if level == null or not level.is_inside_tree() or not wants(level):
		return null
	var old := level.get_node_or_null(NodePath(String(NODE_NAME))) as ForestMood
	if old:
		return old
	var fm := ForestMood.new()
	fm.name = NODE_NAME
	level.add_child(fm)
	return fm


## The tier this look uses (--gfx / headless Low / the saved setting; High when the settings script is missing).
static func settings_quality() -> int:
	if quality_override >= 0:
		return clampi(quality_override, 0, 3)
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return 2
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs and gs.has_method(&"effective_graphics_quality"):
		return clampi(int(gs.call(&"effective_graphics_quality")), 0, 3)
	return 2


## The biome uniforms of the forest ground (GroundParams.apply keys).
static func ground_params() -> Dictionary:
	var tints := PackedColorArray()
	if ResourceLoader.exists(GROUND_PARAMS):
		var gp := load(GROUND_PARAMS) as Script
		if gp and gp.has_method(&"biome_tints"):
			tints = gp.call(&"biome_tints")
	var ruins := PackedVector4Array()
	ruins.resize(8)
	var out := {
		&"biome_amount": 1.0,
		&"biome_hubs": HUBS,
		&"biome_hub_radius": HUB_RADIUS,
		&"biome_woods": WOODS,
		&"biome_wood_radius": WOOD_RADIUS,
		&"biome_heath_edge": 63.0,          # = MAP_HALF + blend / 2: no heath (BiomeMap.domain needs <= this)
		&"biome_blend": 6.0,
		&"biome_ruins": ruins,
		&"biome_ruin_count": 0,
	}
	if not tints.is_empty():
		out[&"biome_tints"] = tints
	return out


func _ready() -> void:
	_level = get_parent()
	_rng.seed = 1303
	quality = settings_quality()
	paint_ground()
	_tune_dressing()
	apply_lighting()
	dress_placeholders()
	if quality >= 2:
		_build_shade.call_deferred()   # after the rig is lit (sun direction) and EnvProps committed its trees
	set_process(false)


func _process(delta: float) -> void:
	if shafts == null or _shaft_pos.is_empty():
		return
	_fog_t -= delta
	if _fog_t <= 0.0:
		_fog_t = FOG_RECHECK
		for i: int in _shaft_pos.size():
			_shaft_target[i] = 1.0 if VfxFog.ok(-1, _shaft_pos[i]) else 0.0
	var mm := shafts.multimesh
	for i: int in _shaft_pos.size():
		var a := move_toward(_shaft_alpha[i], _shaft_target[i], delta * 1.5)
		if a != _shaft_alpha[i]:
			_shaft_alpha[i] = a
			var c := _shaft_custom[i]
			mm.set_instance_custom_data(i, Color(c.r, c.g, c.b, a))


## Shaft `i`'s fog fade (0 hidden .. 1 shown), the CPU copy of its custom data alpha (tests: headless keeps no MultiMesh data).
func shaft_fade(i: int) -> float:
	return _shaft_alpha[i] if i >= 0 and i < _shaft_alpha.size() else -1.0


## The level's painted ground material (the PlaneMesh with ground.gdshader), or null.
func ground_material() -> ShaderMaterial:
	if _level == null:
		return null
	for mi: Node in _level.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var sm := m.material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == GROUND_SHADER and m.mesh is PlaneMesh:
			return sm
	return null


## Paints the Old Wood biome on the level's ground (its own copy: nothing to restore). Returns false without a ground.
func paint_ground() -> bool:
	var g := ground_material()
	if g == null or not ResourceLoader.exists(GROUND_PARAMS):
		return false
	var gp := load(GROUND_PARAMS) as Script
	if gp == null or not gp.has_method(&"apply"):
		return false
	return bool(gp.call(&"apply", g, ground_params()))


func _tune_dressing() -> void:
	for n: Node in _level.get_children():
		if n is MapDressingArt:
			(n as MapDressingArt).density_scale = DECOR_DENSITY


## The forest preset on the level's LightingRig. Returns false without a rig / preset.
func apply_lighting() -> bool:
	if not ResourceLoader.exists(PRESET):
		return false
	for n: Node in _level.get_children():
		if n.is_in_group(&"lighting_rigs") and n.has_method(&"apply") and &"sun" in n:
			n.call(&"apply", load(PRESET))
			return true
	return false


## Interim: swaps the mission's placeholder Oldroot and Warden Gate meshes for the art scenes (see the header).
## Returns how many props were dressed.
func dress_placeholders() -> int:
	var n := 0
	var oldroot := _level.find_child("Oldroot", true, false) as Node3D
	if oldroot and oldroot.get_node_or_null(^"OldrootArt") == null and ResourceLoader.exists(OLDROOT_SCENE):
		for c: Node in oldroot.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false
		var art := (load(OLDROOT_SCENE) as PackedScene).instantiate()
		oldroot.add_child(art)
		n += 1
	for g: Node in get_tree().get_nodes_in_group(&"warden_gates"):
		var look := g.get_node_or_null(^"Look") as Node3D
		if look == null or look.get_node_or_null(^"WardenGateArt") or not ResourceLoader.exists(GATE_SCENE):
			continue
		for c: Node in look.get_children():
			var mi := c as MeshInstance3D
			if mi and mi.mesh is BoxMesh:
				mi.visible = false
		look.add_child((load(GATE_SCENE) as PackedScene).instantiate())
		n += 1
	return n


## [centre, radius] circles kept free of shade and shafts: the level's clearings (Mission03.map_clearings) or the bases.
func _clearings() -> Array:
	if _level and _level.has_method(&"map_clearings"):
		return _level.call(&"map_clearings")
	return [[Vector3(HUBS.x, 0, HUBS.y), HUB_RADIUS], [Vector3(HUBS.z, 0, HUBS.w), HUB_RADIUS]]


static func _in_circles(p: Vector3, circles: Array, pad: float) -> bool:
	for c: Array in circles:
		var cp: Vector3 = c[0]
		if Vector2(p.x - cp.x, p.z - cp.z).length() < float(c[1]) + pad:
			return true
	return false


## Unit vector from the ground toward the sun (the rig's sun shines along its -Z).
func sun_dir() -> Vector3:
	for n: Node in _level.get_children():
		if n.is_in_group(&"lighting_rigs") and &"sun" in n:
			var sun := n.get(&"sun") as DirectionalLight3D
			if sun:
				var d := sun.global_transform.basis.z.normalized()
				if d.y > 0.2:
					return d
	return Vector3(0.35, 0.8, 0.45).normalized()


func _in_wood(p: Vector3) -> bool:
	var d := minf(Vector2(p.x - WOODS.x, p.z - WOODS.y).length(), Vector2(p.x - WOODS.z, p.z - WOODS.w).length())
	var hub := minf(Vector2(p.x - HUBS.x, p.z - HUBS.y).length(), Vector2(p.x - HUBS.z, p.z - HUBS.w).length())
	return d < WOOD_RADIUS - 4.0 and hub > HUB_RADIUS + 2.0 and absf(p.x) < MapInfo.half_x() - 3.0 \
		and absf(p.z) < MapInfo.half_z() - 3.0


## High+: the shadow-only canopy masses and the sun shafts in their gaps.
func _build_shade() -> void:
	if not is_inside_tree():
		return
	var sun := sun_dir()
	var lift := sun / maxf(sun.y, 0.2)          # ground point -> where a caster at height h must sit: + lift * h
	var circles := _clearings()
	var mass := SphereMesh.new()
	mass.radius = 1.0
	mass.height = 2.0
	mass.radial_segments = 6
	mass.rings = 3
	var shade_xf: Array[Transform3D] = []
	var gaps: Array[Vector3] = []
	var hx := MapInfo.half_x()
	var hz := MapInfo.half_z()
	var x := -hx
	while x <= hx:
		var z := -hz
		while z <= hz:
			var t := Vector3(x + _rng.randf_range(-2.0, 2.0), 0.0, z + _rng.randf_range(-2.0, 2.0))
			if _in_wood(t) and not _in_circles(t, circles, 2.0):
				if _rng.randf() < SHADE_KEEP:
					# A leaf mass = a loose cluster of small blobs: its shadow is dappled, not one dark pancake.
					var h := SHADE_HEIGHT + _rng.randf_range(-2.0, 2.0)
					for k: int in _rng.randi_range(3, 5):
						var o := Vector3(_rng.randf_range(-2.6, 2.6), _rng.randf_range(-0.8, 0.8), _rng.randf_range(-2.6, 2.6))
						var s := _rng.randf_range(0.9, 1.7)
						var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s * _rng.randf_range(1.0, 1.5), 0.5, s))
						shade_xf.append(Transform3D(b, t + o + lift * (h + o.y)))
				else:
					gaps.append(t)
			z += SHADE_STEP
		x += SHADE_STEP
	if not shade_xf.is_empty():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mass
		mm.instance_count = shade_xf.size()
		for i: int in shade_xf.size():
			mm.set_instance_transform(i, shade_xf[i])
		shade = MultiMeshInstance3D.new()
		shade.name = "CanopyShade"
		shade.multimesh = mm
		shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		shade.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		add_child(shade)
	_build_shafts(gaps, sun)


func _build_shafts(gaps: Array[Vector3], sun: Vector3) -> void:
	if gaps.is_empty() or not ResourceLoader.exists(SHAFT_SHADER):
		return
	# Spread the shafts: farthest-point picks from the sun gaps.
	var picks: Array[Vector3] = []
	var pool := gaps.duplicate()
	for i: int in range(pool.size() - 1, 0, -1):   # Fisher-Yates with the seeded RNG: same shafts every run
		var j := _rng.randi_range(0, i)
		var tmp: Vector3 = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	for p: Vector3 in pool:
		if picks.size() >= SHAFTS:
			break
		var ok := true
		for q: Vector3 in picks:
			if Vector2(p.x - q.x, p.z - q.z).length() < 15.0:
				ok = false
				break
		if ok:
			picks.append(p)
	if picks.is_empty():
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	quad.center_offset = Vector3(0.0, 0.5, 0.0)   # from the ground up
	var sm := ShaderMaterial.new()
	sm.shader = load(SHAFT_SHADER) as Shader
	quad.material = sm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = picks.size()
	# Shafts lean up and AWAY from the RTS camera (north), sideways like the sun: seen from the camera they read as
	# long diagonal streaks. Leaning toward the real sun (behind the camera) would foreshorten them into blobs.
	var up := Vector3(sun.x * 0.45, 1.0, -0.5).normalized()
	for i: int in picks.size():
		var w := _rng.randf_range(2.4, 4.0)
		var length := SHAFT_LEN * _rng.randf_range(0.8, 1.15)
		var side := up.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.01:
			side = Vector3.RIGHT
		var fwd := side.cross(up).normalized()
		var b := Basis(side * w, up * length, fwd)
		mm.set_instance_transform(i, Transform3D(b, picks[i]))
		var cd := Color(_rng.randf(), w, length, 0.0)   # a = fog fade (0 until seen)
		mm.set_instance_custom_data(i, cd)
		_shaft_custom.append(cd)
		_shaft_pos.append(picks[i])
		_shaft_alpha.append(0.0)
		_shaft_target.append(0.0)
	shafts = MultiMeshInstance3D.new()
	shafts.name = "LightShafts"
	shafts.multimesh = mm
	shafts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shafts.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	shafts.set_meta(&"no_ghost", true)
	add_child(shafts)
	set_process(true)
