extends RefCounted
## G-F Quartermeet identity (docs/art/gf_quartermeet.md): Quartermeet's own look, a HARVEST HIGHLAND, art-side only
## (the map data stays as the gate approved it). Quartermeet and Ashwind Reach are both biome "autumn", so AutumnSwap
## gave them one palette; this look layers on top of it for Quartermeet only. Reach it with load() (no class_name);
## LevelLooks.apply calls `ensure_for_level(level)` from GroundDetail._ready (windowed runs only, before the ground
## bake, after main.gd's AutumnSwap hook):
##     var ql: GDScript = load("res://art/environment/quartermeet/quartermeet_look.gd")
##     ql.ensure_for_level(level)     # Quartermeet only, idempotent, restores the shared materials when the level leaves
## Every tier (a colour change, no extra cost):
##   - every ground-shader material under the level (its own ground, the shared plateau): straw-gold stubble, granite
##     gravel roads, a heather moor rim, green infield round the keeps (quartermeet_palette.gd ground_params)
##   - the SHARED water materials: a cold clear slate-teal river; the shared nature_mat (autumn shader while the swap is
##     on): golden-yellow birch crowns instead of orange / russet. Every shared value is recorded the first time it is
##     touched and put back when the last QuartermeetLook guard leaves the tree (no leak into the next map / the menu).
##     The guard is a CHILD of AutumnSwap's AutumnLook guard when there is one, so it always leaves first (children exit
##     before their parent): it puts the autumn values back, then AutumnLook puts the originals back.
##   - an autumn / warm LightingRig switches to preset_quartermeet.tres (a crisper, higher, paler-gold sun; the same
##     Environment as the autumn preset, so the fog / tier values are unchanged)
## Medium+ only: QuartermeetDressing (stook fields, drystone walls, hay bales, heather moor rim, the moat standing
## stones; quartermeet_dressing.gd).

const DIR := "res://art/environment/quartermeet/"
const PALETTE := DIR + "quartermeet_palette.gd"
const DRESSING := DIR + "quartermeet_dressing.gd"
const PRESET := DIR + "preset_quartermeet.tres"
const MAP_ID := &"quartermeet"
const GUARD_NAME := &"QuartermeetLook"
const AUTUMN_GUARD := &"AutumnLook"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const PLATEAU_MAT := "res://art/environment/plateau_mat.tres"
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


class QuartermeetGuard extends Node:
	var look_script: Script

	func _enter_tree() -> void:
		if look_script:
			look_script.call(&"_guard_enter", self)

	func _exit_tree() -> void:
		if look_script:
			look_script.call(&"_guard_exit", self)


## True when `level` is Quartermeet: its MapLayout id (LayoutLevel.map_layout()).
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


## The level's guard, wherever it sits (under the level or under its AutumnLook guard). Null when none.
static func guard_of(level: Node) -> Node:
	if level == null:
		return null
	var g := level.get_node_or_null(NodePath(String(GUARD_NAME)))
	if g == null:
		g = level.get_node_or_null(NodePath("%s/%s" % [AUTUMN_GUARD, GUARD_NAME]))
	return g


## Applies the look once. Returns the guard (the existing one when called again) or null (not Quartermeet, sim mode,
## disabled, a level not in the tree).
static func ensure_for_level(level: Node) -> Node:
	if disabled or level == null or not level.is_inside_tree() or _sim_enabled() or not wants(level):
		return null
	var old := guard_of(level)
	if old:
		return old
	var guard := QuartermeetGuard.new()
	guard.name = GUARD_NAME
	guard.look_script = load(DIR + "quartermeet_look.gd") as Script
	var autumn := level.get_node_or_null(NodePath(String(AUTUMN_GUARD)))
	(autumn if autumn else level).add_child(guard)   # registers itself before any change: a later exit restores
	swap_shared_materials()
	apply_ground(level)
	var rig := _rig_of(level)
	if rig and _rig_takes_preset(rig):
		rig.call(&"apply", load(PRESET))
	if settings_quality() >= 1 and ResourceLoader.exists(DRESSING):
		var ds := load(DRESSING) as Script
		var d := ds.new() as Node3D if ds and ds.can_instantiate() else null
		if d:
			d.name = &"QuartermeetDressing"
			level.add_child(d)
	return guard


## Paints the Quartermeet palette on every ground-shader material under `level`: the level's own ground (its
## duplicate) and any shared one such as the plateau (recorded first, put back on leave). Returns the materials.
static func apply_ground(level: Node) -> int:
	var tp := load(PALETTE) as Script
	var lay: Variant = level.call(&"map_layout") if level and level.has_method(&"map_layout") else null
	var keeps: Array[Vector3] = []
	for key: StringName in [&"keep", &"shadow_keep"]:
		var k: Variant = level.get(key) if key in level else null
		if k is Node3D and is_instance_valid(k):
			keeps.append((k as Node3D).global_position)
	var params: Dictionary = tp.call(&"ground_params", lay, keeps)
	var seen := {}
	var n := 0
	# The cached plateau (AutumnSwap paints it by path too: the plateau meshes may hold their own reference).
	var plateau := load(PLATEAU_MAT) as ShaderMaterial if ResourceLoader.exists(PLATEAU_MAT) else null
	if plateau and plateau.shader and plateau.shader.resource_path == GROUND_SHADER:
		seen[plateau] = true
		n += int(_set_recorded(plateau, params))
	for node: Node in level.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
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
			if _is_shared(sm):
				n += int(_set_recorded(sm, params))
			else:
				n += int(int(tp.call(&"apply_ground", sm, lay, keeps)) > 0)
	return n


## Recolours the shared water materials and nature_mat (recorded first). Returns the materials changed.
static func swap_shared_materials() -> int:
	var tp := load(PALETTE) as Script
	var consts: Dictionary = tp.get_script_constant_map()
	var n := 0
	for path: String in WATER_MATS:
		if ResourceLoader.exists(path):
			n += int(_set_recorded(load(path) as ShaderMaterial, consts["WATER"]))
	if ResourceLoader.exists(NATURE_MAT):
		n += int(_set_recorded(load(NATURE_MAT) as ShaderMaterial, consts["NATURE"]))
	return n


## A material saved as its own file (shared by every level that loads it), not a level's duplicate.
static func _is_shared(mat: Resource) -> bool:
	var p := mat.resource_path
	return p != "" and not p.contains("::")


## Sets the keys the shader declares, recording each original value on first touch. False when nothing was set.
static func _set_recorded(mat: ShaderMaterial, values: Dictionary) -> bool:
	if mat == null or mat.shader == null:
		return false
	var names: Dictionary = GroundParams.uniform_names(mat.shader)
	var rec: Dictionary = _saved.get(mat, {})
	var n := 0
	for k: Variant in values:
		if not names.has(String(k)):
			continue
		var sk := StringName(k)
		if not rec.has(sk):
			rec[sk] = mat.get_shader_parameter(sk)
		mat.set_shader_parameter(sk, values[k])
		n += 1
	if n == 0:
		return false
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


## True when the rig shows the default mood (the warm preset, or the autumn one AutumnSwap put there): a level's own
## explicit preset wins.
static func _rig_takes_preset(rig: Node) -> bool:
	var p: Variant = rig.get(&"preset")
	if not (p is Resource):
		return StringName(rig.get(&"preset_id")) == &"warm"
	var path := (p as Resource).resource_path
	return path == "" or path.contains("warm") or path.contains("autumn") or path.contains("quartermeet")


static func _sim_enabled() -> bool:
	if not ResourceLoader.exists(SIM_MODE):
		return false
	var s := load(SIM_MODE) as Script
	return s != null and bool(s.get(&"enabled"))
