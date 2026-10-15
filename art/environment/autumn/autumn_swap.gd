extends RefCounted
## Task 20.V0 + G-D autumn maps (docs/art/gd_autumn_maps.md): turns an already-built map GOLDEN AUTUMN at runtime
## without new meshes (docs/art/style-autumn.md 4), and puts every shared material back when the map leaves.
## Reach it with `load()` (no class_name):
##     var sw: GDScript = load("res://art/environment/autumn/autumn_swap.gd")
##     sw.ensure_for_level(level)        # the game: main.gd `_ready` hook; autumn biome only, idempotent, restores itself
## Lower level (previews, labs):
##     sw.swap_shared_materials()        # edits the cached shared materials in memory (in place: the meshes that
##                                       # already use them change too, so before or after the map is built)
##     sw.apply_ground(level_root)       # after the ground material exists (colours only, zones kept)
##     sw.apply_lighting(level_root)     # the LightingRig of main.gd -> preset_autumn.tres
##     sw.restore()                      # every shared material back to its original shader + parameters
## Every material the swap or apply_ground changes is recorded the first time it is touched (original shader and the
## original value of each parameter it sets; unset = null, put back as unset), so restore() is exact. `gd_detail`
## (PropsLook's tier, written by the LightingRig) is never recorded nor copied: it follows the tier through the swap
## and the restore. ensure_for_level() adds an "AutumnLook" child to the level: the last such node leaving the tree
## calls restore(), so the next map / the menu never sees the autumn materials (two autumn levels alive at once, e.g.
## a restart, share the swap).

const DIR := "res://art/environment/autumn/"
const GROUND_PARAMS := DIR + "autumn_ground_params.gd"
const PRESET := DIR + "preset_autumn.tres"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const PLATEAU_MAT := "res://art/environment/plateau_mat.tres"
const SIM_MODE := "res://scripts/core/sim_mode.gd"
const GUARD_NAME := &"AutumnLook"
const RIG_GROUP := &"lighting_rigs"
## Never copied by the swap nor put back by restore(): written by other systems (PropsLook tier, WaterQuality tier).
const OWNED_ELSEWHERE: Array[StringName] = [&"gd_detail", &"quality"]
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
## ShaderMaterial -> {"shader": original Shader (only when the swap changed it), "params": {name: original value}}.
static var _saved: Dictionary = {}
## The live AutumnLook guards (one per autumn level in the tree).
static var _guards: Array[Node] = []


## The guard node: lives as long as the level; the last one to leave restores the shared materials.
class AutumnLook extends Node:
	var swap_script: Script

	func _enter_tree() -> void:
		if swap_script:
			swap_script.call(&"_guard_enter", self)

	func _exit_tree() -> void:
		if swap_script:
			swap_script.call(&"_guard_exit", self)


## The game hook (main.gd `_ready`, after the map, its ground and the LightingRig exist, before GroundDetail bakes the
## ground): when the level's biome is autumn, swaps the shared materials, paints the ground, switches a "warm" rig to
## the autumn preset and adds the AutumnLook guard. Returns the guard (the existing one when called again), or null
## (not autumn, Bot Lab sim mode, null level). Headless runs get it too (a look change, no extra cost).
static func ensure_for_level(level: Node) -> Node:
	if level == null or not level.is_inside_tree() or _sim_enabled():
		return null
	var old := level.get_node_or_null(NodePath(String(GUARD_NAME)))
	if old:
		return old
	if not is_autumn(biome_of(level)):
		return null
	var guard := AutumnLook.new()
	guard.name = GUARD_NAME
	guard.swap_script = load(DIR + "autumn_swap.gd") as Script
	level.add_child(guard)   # registers itself before any swap: a later exit always restores
	swap_shared_materials()
	apply_ground(level)
	var rig := _rig_of(level)
	if rig and StringName(rig.get(&"preset_id")) == &"warm" and not _preset_set_by_level(rig):
		rig.call(&"apply", load(PRESET))
	return guard


## The level's look biome: its MapLayout's `biome` (LayoutLevel.map_layout(), or a level's `layout` such as Wave
## Strike's), else the MapCatalog entry of MapInfo.map_id. "" when neither knows.
static func biome_of(level: Node) -> String:
	var lay: Variant = null
	if level and level.has_method(&"map_layout"):
		lay = level.call(&"map_layout")
	elif level and &"layout" in level:
		lay = level.get(&"layout")
	if lay is Resource and &"biome" in lay:
		var b := String((lay as Resource).get(&"biome"))
		if b != "":
			return b
	if MapInfo.map_id != &"":
		var cat := MapCatalog.load_default()
		if cat:
			return String(cat.entry(MapInfo.map_id).get("biome", ""))
	return ""


static func is_autumn(biome: String) -> bool:
	return biome.to_lower().contains("autumn")


## True while shared materials are swapped (something to restore).
static func is_swapped() -> bool:
	return not _saved.is_empty()


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
			var keys: Array[StringName] = []
			for k: String in GroundParams.uniform_names(variant.shader):
				var sk := StringName(k)
				if not OWNED_ELSEWHERE.has(sk) and variant.get_shader_parameter(sk) != null:
					keys.append(sk)
			_record(base, keys, base.shader != variant.shader)
			var kept: Dictionary = _owned_values(base)
			base.shader = variant.shader
			for sk: StringName in keys:
				base.set_shader_parameter(sk, variant.get_shader_parameter(sk))
			for sk: Variant in kept:
				base.set_shader_parameter(sk, kept[sk])
		else:
			var names: Dictionary = GroundParams.uniform_names(base.shader)
			var keys: Array[StringName] = []
			for k: StringName in WATER_COLOUR_KEYS:
				if variant.get_shader_parameter(k) != null and names.has(String(k)):
					keys.append(k)
			_record(base, keys, false)
			for k: StringName in keys:
				base.set_shader_parameter(k, variant.get_shader_parameter(k))
		_held.append(base)
		n += 1
	return n


## Applies the autumn ground colours to every ground-shader material under `root` (material_override or surface
## override: the map's ground, the plateau) and to the cached plateau_mat.tres. Returns the number of materials.
## Every material is recorded first, so restore() puts the shared plateau back.
static func apply_ground(root: Node) -> int:
	var ap: GDScript = load(GROUND_PARAMS)
	var keys: Array[StringName] = []
	for k: Variant in ap.call(&"ground_params"):
		keys.append(StringName(k))
	var seen := {}
	var n := 0
	var plateau := load(PLATEAU_MAT) as ShaderMaterial if ResourceLoader.exists(PLATEAU_MAT) else null
	if plateau:
		seen[plateau] = true
		_record(plateau, _declared(plateau, keys), false)
		n += int(ap.call(&"apply", plateau) > 0)
		_held.append(plateau)
	if root == null:
		return n
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
			_record(sm, _declared(sm, keys), false)
			n += int(ap.call(&"apply", sm) > 0)
	return n


## Switches the LightingRig found under `root` (main.gd adds one) to preset_autumn.tres. False when there is none.
static func apply_lighting(root: Node) -> bool:
	var rig := _rig_of(root)
	if rig == null:
		return false
	rig.call(&"apply", load(PRESET))
	return true


## Puts every recorded material back: its original shader, then each changed parameter's original value (unset ones
## unset again). The tier parameters (gd_detail, quality) keep their current value. Returns the materials restored.
static func restore() -> int:
	var n := 0
	for m: Variant in _saved:
		var sm := m as ShaderMaterial
		if sm == null:
			continue
		var rec: Dictionary = _saved[m]
		if rec.has("shader"):
			var kept: Dictionary = _owned_values(sm)
			sm.shader = rec["shader"] as Shader
			for sk: Variant in kept:
				sm.set_shader_parameter(sk, kept[sk])
		var params: Dictionary = rec["params"]
		for k: Variant in params:
			sm.set_shader_parameter(k, params[k])
		n += 1
	_saved.clear()
	_held.clear()
	return n


## Drops the references kept by swap_shared_materials() / apply_ground() WITHOUT restoring (old API, previews that
## quit right after). Prefer restore().
static func release() -> void:
	_held.clear()


static func _guard_enter(g: Node) -> void:
	if not _guards.has(g):
		_guards.append(g)


static func _guard_exit(g: Node) -> void:
	_guards.erase(g)
	if _guards.is_empty():
		restore()


## Records `keys`' original values (and the shader when `shader_changes`) the first time `mat` is touched; later
## touches only add keys not seen yet (their value now is still the original: nothing else of ours wrote them).
static func _record(mat: ShaderMaterial, keys: Array[StringName], shader_changes: bool) -> void:
	var rec: Dictionary = _saved.get(mat, {})
	if rec.is_empty():
		rec["params"] = {}
		_saved[mat] = rec
	if shader_changes and not rec.has("shader"):
		rec["shader"] = mat.shader
	var params: Dictionary = rec["params"]
	for k: StringName in keys:
		if not params.has(k):
			params[k] = mat.get_shader_parameter(k)


static func _owned_values(mat: ShaderMaterial) -> Dictionary:
	var out := {}
	for k: StringName in OWNED_ELSEWHERE:
		var v: Variant = mat.get_shader_parameter(k)
		if v != null:
			out[k] = v
	return out


static func _declared(mat: ShaderMaterial, keys: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	if mat == null or mat.shader == null:
		return out
	var names: Dictionary = GroundParams.uniform_names(mat.shader)
	for k: StringName in keys:
		if names.has(String(k)):
			out.append(k)
	return out


## The LightingRig under `root`: a node with apply() and a DirectionalLight3D `sun` (the group "lighting_rigs" also
## holds crystal / crown art, the menu diorama and the combat FX, which only take set_quality).
static func _rig_of(root: Node) -> Node:
	if root == null:
		return null
	var pool: Array[Node] = []
	if root.is_inside_tree():
		for r: Node in root.get_tree().get_nodes_in_group(RIG_GROUP):
			if r == root or root.is_ancestor_of(r):
				pool.append(r)
	else:
		pool = _walk(root)
	for node: Node in pool:
		if node.has_method(&"apply") and node.get(&"sun") is DirectionalLight3D and &"preset_id" in node:
			return node
	return null


## True when the level gave its rig an explicit preset that is not the default warm one (a mission's own mood wins).
static func _preset_set_by_level(rig: Node) -> bool:
	var p: Variant = rig.get(&"preset")
	if not (p is Resource):
		return false
	var path := (p as Resource).resource_path
	return path != "" and not path.contains("warm") and not path.contains("autumn")


static func _sim_enabled() -> bool:
	if not ResourceLoader.exists(SIM_MODE):
		return false
	var s := load(SIM_MODE) as Script
	return s != null and bool(s.get(&"enabled"))


static func _walk(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		for c: Node in n.get_children():
			stack.append(c)
	return out
