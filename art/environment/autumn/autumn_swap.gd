extends RefCounted
## Task 20.V0: turns an already-built map GOLDEN AUTUMN at runtime without new meshes (docs/art/style-autumn.md 4).
## Used by autumn_preview.gd today; the 2v2 level (20.C4 / 20.V3) can call the same functions until it swaps the
## materials in its own tables. Reach it with `load()` (no class_name):
##     var sw: GDScript = load("res://art/environment/autumn/autumn_swap.gd")
##     sw.swap_shared_materials()        # BEFORE or after the map is built: edits the cached shared materials in memory
##     sw.apply_ground(level_root)       # after the ground material exists (colours only, zones kept)
##     sw.apply_lighting(level_root)     # the LightingRig of main.gd -> preset_autumn.tres
## Nothing is saved to disk: the shared .tres files keep their look for every other map. There is no restore: the
## swap lasts while the cached materials live (call release() when the level is freed so the cache can reload them).
## CAUTION: the shared materials are process-wide; do not call swap_shared_materials() in a process that later builds
## a non-autumn map (tests, labs) without restarting.

const DIR := "res://art/environment/autumn/"
const GROUND_PARAMS := DIR + "autumn_ground_params.gd"
const PRESET := DIR + "preset_autumn.tres"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
## Shared material -> its autumn variant. `true` = take the variant's shader too (a shader variant), `false` = copy
## only the parameters the variant sets (same shader, new colours).
const SWAPS: Array = [
	["res://art/environment/nature_props/nature_mat.tres", DIR + "nature_autumn_mat.tres", true],
	["res://art/environment/horizon/horizon_mat.tres", DIR + "horizon_autumn_mat.tres", true],
	["res://art/environment/water/water_mat.tres", DIR + "water_autumn_mat.tres", false],
	["res://art/environment/water/water_ford_mat.tres", DIR + "water_autumn_mat.tres", false],
	["res://art/environment/river_mouths/mouth_water_fallback_mat.tres", DIR + "water_autumn_mat.tres", false],
]
## Colour-only keys copied onto the water materials (their flow / shallow settings stay).
const WATER_COLOUR_KEYS: Array[StringName] = [&"deep_color", &"water_color", &"bank_color", &"sky_color",
	&"foam_color", &"glint_color", &"film_color", &"sand_color"]

## Keeps the swapped materials referenced so the resource cache cannot drop them before the map loads them.
static var _held: Array[Resource] = []


## Edits the cached shared materials of SWAPS in memory. Returns the number of materials changed.
static func swap_shared_materials() -> int:
	var n := 0
	for row: Array in SWAPS:
		if not ResourceLoader.exists(row[0]) or not ResourceLoader.exists(row[1]):
			continue
		var base := load(row[0]) as ShaderMaterial
		var variant := load(row[1]) as ShaderMaterial
		if base == null or variant == null:
			continue
		if bool(row[2]):
			base.shader = variant.shader
			for k: String in GroundParams.uniform_names(variant.shader):
				var v: Variant = variant.get_shader_parameter(StringName(k))
				if v != null:
					base.set_shader_parameter(StringName(k), v)
		else:
			var names: Dictionary = GroundParams.uniform_names(base.shader)
			for k: StringName in WATER_COLOUR_KEYS:
				var v: Variant = variant.get_shader_parameter(k)
				if v != null and names.has(String(k)):
					base.set_shader_parameter(k, v)
		_held.append(base)
		n += 1
	return n


## Applies the autumn ground colours to every ground-shader material under `root` (material_override or surface
## override: the map's ground, the plateau) and to the cached plateau_mat.tres. Returns the number of materials.
static func apply_ground(root: Node) -> int:
	var ap: GDScript = load(GROUND_PARAMS)
	var seen := {}
	var n := 0
	var plateau := load("res://art/environment/plateau_mat.tres") as ShaderMaterial
	if plateau:
		seen[plateau] = true
		n += int(ap.call(&"apply", plateau) > 0)
		_held.append(plateau)
	for node: Node in _walk(root):
		var gi := node as GeometryInstance3D
		if gi == null:
			continue
		var mats: Array = [gi.material_override]
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				mats.append(mi.get_surface_override_material(s))
				mats.append(mi.mesh.surface_get_material(s))
		for m: Variant in mats:
			var sm := m as ShaderMaterial
			if sm == null or seen.has(sm) or sm.shader == null or sm.shader.resource_path != GROUND_SHADER:
				continue
			seen[sm] = true
			n += int(ap.call(&"apply", sm) > 0)
	return n


## Switches the LightingRig found under `root` (main.gd adds one) to preset_autumn.tres. False when there is none.
static func apply_lighting(root: Node) -> bool:
	for node: Node in _walk(root):
		if node.has_method(&"apply") and node.get(&"sun") is DirectionalLight3D:
			node.call(&"apply", load(PRESET))
			return true
	return false


## Drops the references kept by swap_shared_materials() / apply_ground() (level freed, process quitting).
static func release() -> void:
	_held.clear()


static func _walk(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		for c: Node in n.get_children():
			stack.append(c)
	return out
