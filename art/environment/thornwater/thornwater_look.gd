extends RefCounted
## G-F review 2 item 9 (docs/art/gf_thornwater.md): Thornwater's own identity, art-side only (the map data stays as the
## gate approved it). Reach it with load() (no class_name); LevelLooks.apply calls `ensure_for_level(level)` from
## GroundDetail._ready (windowed runs only, before the ground bake):
##     var tl: GDScript = load("res://art/environment/thornwater/thornwater_look.gd")
##     tl.ensure_for_level(level)     # Thornwater only, idempotent, restores the shared materials when the level leaves
## Every tier (a colour change, no extra cost):
##   - the level's ground material: the wet marsh-meadow palette + biome zones (thornwater_palette.gd ground_params)
##   - the SHARED water materials (river / moat / fords / mouth fallback): peaty dark water; the shared nature_mat: no
##     random autumn crowns, wetter moss. Every value is recorded the first time it is touched and put back when the
##     last ThornwaterLook guard leaves the tree (no leak into the next map / the menu), as AutumnSwap does.
##   - a "warm" LightingRig switches to preset_thornwater.tres (cooler sun, stronger blue fill, a damp green vignette;
##     the same Environment as warm, so the fog / tier values are unchanged)
## Medium+ only: ThornwaterDressing (reeds, thickets, the fen wood belt, the moat thorn spires; thornwater_dressing.gd).

const DIR := "res://art/environment/thornwater/"
const PALETTE := DIR + "thornwater_palette.gd"
const DRESSING := DIR + "thornwater_dressing.gd"
const PRESET := DIR + "preset_thornwater.tres"
const MAP_ID := &"thornwater"
const GUARD_NAME := &"ThornwaterLook"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const SIM_MODE := "res://scripts/core/sim_mode.gd"
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const RIG_GROUP := &"lighting_rigs"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const WATER_MATS: Array[String] = [
	"res://art/environment/water/water_mat.tres",
	"res://art/environment/water/water_ford_mat.tres",
	"res://art/environment/river_mouths/mouth_water_fallback_mat.tres",
]

## Shots / labs: true = the look never applies (the "before" frames).
static var disabled := false
## Tests / tools: >= 0 beats the settings for the dressing tier (0 Low .. 3 Ultra).
static var quality_override := -1

## ShaderMaterial -> {param: original value} (null = was unset).
static var _saved: Dictionary = {}
static var _held: Array[Resource] = []
static var _guards: Array[Node] = []


class ThornwaterGuard extends Node:
	var look_script: Script

	func _enter_tree() -> void:
		if look_script:
			look_script.call(&"_guard_enter", self)

	func _exit_tree() -> void:
		if look_script:
			look_script.call(&"_guard_exit", self)


## True when `level` is Thornwater: its MapLayout id (LayoutLevel.map_layout()), else MapInfo.map_id when the level
## owns no layout.
static func wants(level: Node) -> bool:
	if level == null:
		return false
	if level.has_method(&"map_layout"):
		var lay: Variant = level.call(&"map_layout")
		if lay is Resource and &"id" in lay:
			return StringName(String((lay as Resource).get(&"id"))) == MAP_ID
	return false


## The tier for the dressing (--gfx / headless Low / the saved setting; High when the settings script is missing).
static func settings_quality() -> int:
	if quality_override >= 0:
		return clampi(quality_override, 0, 3)
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return 2
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs and gs.has_method(&"effective_graphics_quality"):
		return clampi(int(gs.call(&"effective_graphics_quality")), 0, 3)
	return 2


## Applies the look once. Returns the guard (the existing one when called again) or null (not Thornwater, sim mode,
## disabled, a level not in the tree).
static func ensure_for_level(level: Node) -> Node:
	if disabled or level == null or not level.is_inside_tree() or _sim_enabled() or not wants(level):
		return null
	var old := level.get_node_or_null(NodePath(String(GUARD_NAME)))
	if old:
		return old
	var guard := ThornwaterGuard.new()
	guard.name = GUARD_NAME
	guard.look_script = load(DIR + "thornwater_look.gd") as Script
	level.add_child(guard)   # registers itself before any change: a later exit always restores
	swap_shared_materials()
	apply_ground(level)
	var rig := _rig_of(level)
	if rig and StringName(rig.get(&"preset_id")) == &"warm" and not _preset_set_by_level(rig):
		rig.call(&"apply", load(PRESET))
	if settings_quality() >= 1 and ResourceLoader.exists(DRESSING):
		var ds := load(DRESSING) as Script
		var d := ds.new() as Node3D if ds and ds.can_instantiate() else null
		if d:
			d.name = &"ThornwaterDressing"
			level.add_child(d)
	return guard


## Paints the Thornwater palette on every ground-shader material under `level` (the level's own duplicate: nothing
## shared). Returns the number of materials painted.
static func apply_ground(level: Node) -> int:
	var tp := load(PALETTE) as Script
	var lay: Variant = level.call(&"map_layout") if level and level.has_method(&"map_layout") else null
	var seen := {}
	var n := 0
	for node: Node in level.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		var mats: Array = [gi.material_override]
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				mats.append(mi.get_surface_override_material(s))
		for m: Variant in mats:
			var sm := m as ShaderMaterial
			if sm == null or seen.has(sm) or sm.shader == null or sm.shader.resource_path != GROUND_SHADER:
				continue
			seen[sm] = true
			n += int(int(tp.call(&"apply_ground", sm, lay)) > 0)
	return n


## Recolours the shared water materials and nature_mat (recorded first). Returns the materials changed.
static func swap_shared_materials() -> int:
	var tp := load(PALETTE) as Script
	var consts: Dictionary = tp.get_script_constant_map()
	var n := 0
	for path: String in WATER_MATS:
		n += int(_set_recorded(path, consts["WATER"]))
	n += int(_set_recorded(NATURE_MAT, consts["NATURE"]))
	return n


static func _set_recorded(path: String, values: Dictionary) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var mat := load(path) as ShaderMaterial
	if mat == null or mat.shader == null:
		return false
	var names: Dictionary = GroundParams.uniform_names(mat.shader)
	var rec: Dictionary = _saved.get(mat, {})
	for k: Variant in values:
		if not names.has(String(k)):
			continue
		if not rec.has(k):
			rec[k] = mat.get_shader_parameter(k)
		mat.set_shader_parameter(k, values[k])
	_saved[mat] = rec
	_held.append(mat)
	return true


## True while shared materials carry the look (something to restore).
static func is_swapped() -> bool:
	return not _saved.is_empty()


## Puts every recorded shared value back. Returns the materials restored.
static func restore() -> int:
	var n := 0
	for m: Variant in _saved:
		var sm := m as ShaderMaterial
		if sm == null:
			continue
		var rec: Dictionary = _saved[m]
		for k: Variant in rec:
			sm.set_shader_parameter(k, rec[k])
		n += 1
	_saved.clear()
	_held.clear()
	return n


static func _guard_enter(g: Node) -> void:
	if not _guards.has(g):
		_guards.append(g)


static func _guard_exit(g: Node) -> void:
	_guards.erase(g)
	if _guards.is_empty():
		restore()


static func _rig_of(root: Node) -> Node:
	if root == null or not root.is_inside_tree():
		return null
	for r: Node in root.get_tree().get_nodes_in_group(RIG_GROUP):
		if (r == root or root.is_ancestor_of(r)) and r.has_method(&"apply") and r.get(&"sun") is DirectionalLight3D \
				and &"preset_id" in r:
			return r
	return null


## True when the level gave its rig an explicit preset that is not the default warm one (a mission's own mood wins).
static func _preset_set_by_level(rig: Node) -> bool:
	var p: Variant = rig.get(&"preset")
	if not (p is Resource):
		return false
	var path := (p as Resource).resource_path
	return path != "" and not path.contains("warm") and not path.contains("thornwater")


static func _sim_enabled() -> bool:
	if not ResourceLoader.exists(SIM_MODE):
		return false
	var s := load(SIM_MODE) as Script
	return s != null and bool(s.get(&"enabled"))
