class_name RiverMouthsArt
extends Node3D
## River mouths of Crown Hollow (task 12.V5, map-fill.md 3.2 `lm_mouths`): the "RiverMouths" child of
## art/environment/map_dressing.tscn, built by art/environment/build_env.gd.
## - North: the Hollowmere comes down a stream on the plateau, tips over a notch cut in the tall cliffs and falls
##   ~7 m into a plunge pool (foam, mist cards) that feeds the river where N0 enters the map.
## - South: the river leaves the map through a rocky gorge cut in the low south cliffs, down four rapid steps, and
##   vanishes under a natural stone arch.
## The ring of cliffs exists twice: meshes/map_cliffs.res + meshes/map_plateau.res have the two gaps (the scene's
## default), river_mouths/map_cliffs_closed.res + map_plateau_closed.res are the closed ring (the pre-12.V5 look) for
## maps without the river. On _ready the mouths open when the level has `river_enabled == true` (Skirmish, map-fill.md
## 11); otherwise the closed ring is swapped in and this node hides. Border trees / crest rocks that only fit one ring
## are hidden per instance (their MultiMesh transforms collapsed; originals read back from MapDressingArt.border_sets),
## so switching costs no extra draw call.
## While open, the level's ground plane skirt is turned off (ground.gdshader `expand_edge` = false on the map's own
## ground material: the 120 m plane is otherwise stretched to +-260 m at y 0 and covers the plunge pool and the gorge);
## the open cliff ring carries its own scree apron at the cliff foot instead. Closing restores the previous value.
## Public: `set_open(open: bool)`, `is_open() -> bool`, `hidden_count() -> int` (border instances hidden right now).
## Draw-only: no collider, no light, no particles.
## The water mesh gets res://art/environment/water/water_mat.tres (12.V1) when it exists, else the plain painted
## fallback river_mouths/mouth_water_fallback_mat.tres. No material is created at runtime.

const WATER_MAT := "res://art/environment/water/water_mat.tres"
const FALLBACK_MAT := "res://art/environment/river_mouths/mouth_water_fallback_mat.tres"
const OPEN_CLIFFS := "res://art/environment/meshes/map_cliffs.res"
const OPEN_PLATEAU := "res://art/environment/meshes/map_plateau.res"
const CLOSED_CLIFFS := "res://art/environment/river_mouths/map_cliffs_closed.res"
const CLOSED_PLATEAU := "res://art/environment/river_mouths/map_plateau_closed.res"
const GROUND_SHADER := "res://art/environment/ground.gdshader"

## Border-forest / crest-rock instances (BorderForest set name -> PackedInt32Array of instance indices) that only
## exist on the closed ring (they stand where the gorge and the notch valley are) and only on the open ring (replanted
## around the stream, on the stone arch). Written by build_env.gd.
@export var closed_only: Dictionary = {}
@export var open_only: Dictionary = {}

var _open := false
var _forced := -1                  # -1 = follow the level's river_enabled, 0 / 1 = set_open() was called
var _hidden := 0
var _grounds: Array = []           # [ShaderMaterial, its expand_edge before we touched it (null = shader default)]


func _ready() -> void:
	var water := get_node_or_null(^"Water") as MeshInstance3D
	if water:
		var path: String = WATER_MAT if ResourceLoader.exists(WATER_MAT) else FALLBACK_MAT
		water.material_override = load(path) as Material
	if _forced < 0:
		var dressing: Node = get_parent()
		var level: Node = dressing.get_parent() if dressing else null
		_open = level != null and level.get(&"river_enabled") == true
	visible = _open
	_apply.call_deferred()   # after MapDressingArt._ready has built the border forest


## Opens (river mouths, cliffs with the two gaps) or closes (the plain ring of cliffs) the map edge.
func set_open(open: bool) -> void:
	_open = open
	_forced = 1 if open else 0
	if is_inside_tree():
		_apply()


func is_open() -> bool:
	return _open


func _apply() -> void:
	visible = _open
	var dressing: Node = get_parent()
	if dressing == null:
		return
	_swap_mesh(dressing.get_node_or_null(^"Cliffs") as MeshInstance3D, OPEN_CLIFFS if _open else CLOSED_CLIFFS)
	_swap_mesh(dressing.get_node_or_null(^"Plateau") as MeshInstance3D, OPEN_PLATEAU if _open else CLOSED_PLATEAU)
	_filter_border(dressing)
	_ground_skirt(dressing.get_parent())


## The map's ground plane(s): a PlaneMesh with ground.gdshader (the plateau mesh is not a PlaneMesh).
func _ground_skirt(level: Node) -> void:
	if _grounds.is_empty() and level != null:
		for n: Node in level.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			var sm := mi.material_override as ShaderMaterial
			if mi.mesh is PlaneMesh and (mi.mesh as PlaneMesh).size.x >= 119.0 and sm != null and sm.shader != null \
					and sm.shader.resource_path == GROUND_SHADER:
				_grounds.append([sm, sm.get_shader_parameter(&"expand_edge")])
	for g: Array in _grounds:
		var sm := g[0] as ShaderMaterial
		if _open:
			sm.set_shader_parameter(&"expand_edge", false)
		else:
			sm.set_shader_parameter(&"expand_edge", g[1])


func _swap_mesh(mi: MeshInstance3D, path: String) -> void:
	if mi == null or not ResourceLoader.exists(path):
		return
	if mi.mesh != null and mi.mesh.resource_path == path:
		return
	mi.mesh = load(path) as Mesh


## Border instances hidden by the last switch (the other ring's trees / crest rocks).
func hidden_count() -> int:
	return _hidden


## Hides (collapses) the border instances of the other ring and puts this ring's back, from the saved data.
func _filter_border(dressing: Node) -> void:
	var forest: Node = dressing.get_node_or_null(^"BorderForest")
	var sets: Variant = dressing.get(&"border_sets")
	if forest == null or not (sets is Array):
		return
	var data: Dictionary = {}   # set name -> PackedFloat32Array (12 floats per instance)
	for s: Variant in sets:
		if s is Array and (s as Array).size() >= 3:
			data[String(s[1])] = s[2]
	var hide: Dictionary = closed_only if _open else open_only
	var show: Dictionary = open_only if _open else closed_only
	_hidden = 0
	for c: Node in forest.get_children():
		var mmi := c as MultiMeshInstance3D
		var nm: String = String(c.name)
		if mmi == null or mmi.multimesh == null or not data.has(nm):
			continue
		var mm: MultiMesh = mmi.multimesh
		var buf: PackedFloat32Array = data[nm]
		for i: int in PackedInt32Array(show.get(nm, PackedInt32Array())):
			if i < mm.instance_count:
				mm.set_instance_transform(i, _xf(buf, i))
		for i: int in PackedInt32Array(hide.get(nm, PackedInt32Array())):
			if i < mm.instance_count:
				var xf: Transform3D = _xf(buf, i)
				mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001), xf.origin + Vector3(0.0, -40.0, 0.0)))
				_hidden += 1


static func _xf(d: PackedFloat32Array, i: int) -> Transform3D:
	var o: int = i * 12
	return Transform3D(Vector3(d[o], d[o + 1], d[o + 2]), Vector3(d[o + 3], d[o + 4], d[o + 5]),
			Vector3(d[o + 6], d[o + 7], d[o + 8]), Vector3(d[o + 9], d[o + 10], d[o + 11]))
