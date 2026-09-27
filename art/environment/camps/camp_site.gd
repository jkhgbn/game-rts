class_name CampSite
extends Node3D
## Task 12.V24 (docs/design/map-fill.md 5.2 and 10): the dressing of a neutral monster camp spot. Draw-only (no
## collider, no light, no click), baked by art/environment/camps/build_camps.gd into
## art/environment/camps/<kind>_site.tscn for the 4 CampManager kinds:
##   &"bristleback"  Bristleback Wallow: mud pit (camp_mud_mat, dries out when cleared), churned clods, a ribcage and
##                   skull, gnawed logs, a mud-smeared rubbing snag
##   &"mirefang"     Ford Nest: three woven reed-and-mud nest mounds in the ford film with amber eggs (glow), reed
##                   beds at the channel edges (cleared: reeds flattened, eggs smashed)
##   &"gloomcap"     Gloomcap Hollow: a glowing fairy ring of blue-grey toadstools, a tall Mother Cap, a rotten log
##                   with shelf fungus (cleared: the ring goes dark, the Mother Cap lies snapped)
##   &"hollow_stag"  Stag Glade: an antler cairn with glowing leaf buds, a moss-covered altar stone with a glowing
##                   leaf groove (cleared: the glow dies)
## Nodes: "Ground" (the painted trodden apron, shared site_ground_mat; not on the nest), "Base" (always shown),
## "Active" (only while the camp is alive), "Cleared" (only while it is cleared). Every mesh is indexed and uses
## shared materials only: nature_props/nature_mat.tres, nature_contact_mat.tres, camps/camp_glow_mat.tres,
## camps/camp_mud_mat.tres. The glow / wetness live in INSTANCE uniforms (`lit`, `wet`) listed in each mesh node's
## metadata `camp_params`, so set_cleared never builds a material.
##
## Placement (CampManager / NeutralCamp glue, task 12.C8): instance scene_path(kind) as a child of the map (or of the
## NeutralCamp node with a zero local transform) and call place_at(spot) once:
##   - the origin IS the camp spot (map-fill.md 5.2), y 0;
##   - bristleback / gloomcap / hollow_stag: local -Z faces the map centre, so the point-mirrored spot gets the
##     point-mirrored dressing (NeutralCamp.ring_offset puts creature 0 on that side too; the creature ring r 1.5-2.0
##     and the stag's spot are kept clear of anything taller than 0.3 m);
##   - mirefang: origin = the ford centre, local +Z DOWNSTREAM like ford_stones.tscn (both fords flow north -> south,
##     so both nests take the SAME yaw: pass the crossing's `dir`, default FORD_FLOW). The nest keeps inside the
##     r 1.6 hole the ford stones leave in the middle, reeds stand at the channel edges.
## Then call set_cleared(camp.is_cleared()) on spawn (`respawned` / first spawn) and on `cleared`.

## The ford flow of both Crown Hollow fords (skirmish.gd CROSSINGS ford_n / ford_s `dir`).
const FORD_FLOW := Vector3(1.0, 0.0, 8.0)
const KINDS: Array[StringName] = [&"bristleback", &"mirefang", &"gloomcap", &"hollow_stag"]
const DIR := "res://art/environment/camps/"
## Seconds for the glow to die / come back, and for the wallow to dry out / soak again.
const GLOW_OFF_TIME := 1.4
const GLOW_ON_TIME := 0.8
const DRY_TIME := 6.0
const SOAK_TIME := 1.2

## Which CampManager kind this site dresses.
@export var kind: StringName = &"bristleback"
## State at _ready (camps whose first spawn is later, like the Gloomcap Hollow at 2:30, may start cleared).
@export var start_cleared := false

var _cleared := false
var _tweens: Array[Tween] = []


## The scene of a camp kind (map-fill.md 13: res://art/environment/camps/<kind>_site.tscn).
static func scene_path(camp_kind: StringName) -> String:
	return DIR + "%s_site.tscn" % camp_kind


## Basis for a site of `camp_kind` at `pos`: mirefang = local +Z along `dir` (the downstream flow, FORD_FLOW when
## zero); the others = local +Z pointing away from the map centre (local -Z faces it).
static func basis_for(camp_kind: StringName, pos: Vector3, dir: Vector3 = Vector3.ZERO) -> Basis:
	var z := Vector3.ZERO
	if camp_kind == &"mirefang":
		z = Vector3(dir.x, 0.0, dir.z)
		if z.length_squared() < 1e-6:
			z = FORD_FLOW
	else:
		z = Vector3(pos.x, 0.0, pos.z)
	if z.length_squared() < 1e-6:
		return Basis.IDENTITY
	z = z.normalized()
	return Basis(Vector3.UP.cross(z), Vector3.UP, z)


func _ready() -> void:
	_cleared = start_cleared
	_apply(true)


## Puts the site on its camp spot (y forced to 0), turned as basis_for() says.
func place_at(pos: Vector3, dir: Vector3 = Vector3.ZERO) -> void:
	transform = Transform3D(basis_for(kind, pos, dir), Vector3(pos.x, 0.0, pos.z))
	if is_inside_tree():
		reset_physics_interpolation()


## Alive (false) or cleared (true) look. Animated (glow fades, the wallow dries) unless `instant` or not in the tree.
func set_cleared(cleared: bool, instant: bool = false) -> void:
	if cleared == _cleared and not instant:
		return
	_cleared = cleared
	if is_inside_tree():
		_apply(instant)
	else:
		start_cleared = cleared   # _ready applies it (instantly)


func is_cleared() -> bool:
	return _cleared


## Radius (m) the map decor keeps clear around the spot (also in the root metadata `decor_clear_radius`).
func clear_radius() -> float:
	return float(get_meta(&"decor_clear_radius", 4.5))


func _apply(instant: bool) -> void:
	for t: Tween in _tweens:
		if t and t.is_valid():
			t.kill()
	_tweens.clear()
	var active := get_node_or_null(^"Active") as Node3D
	var gone := get_node_or_null(^"Cleared") as Node3D
	if active:
		active.visible = not _cleared
	if gone:
		gone.visible = _cleared
	var target := 0.0 if _cleared else 1.0
	for child: Node in get_children():
		var gi := child as GeometryInstance3D
		if gi == null:
			continue
		var params: PackedStringArray = gi.get_meta(&"camp_params", PackedStringArray())
		for p: String in params:
			var from := float(gi.get_instance_shader_parameter(p)) if gi.get_instance_shader_parameter(p) != null else 1.0
			if instant or not is_inside_tree():
				gi.set_instance_shader_parameter(p, target)
				continue
			var time := 0.0
			if p == "wet":
				time = DRY_TIME if _cleared else SOAK_TIME
			else:
				time = GLOW_OFF_TIME if _cleared else GLOW_ON_TIME
			var tw := create_tween()
			tw.tween_method(_set_param.bind(gi, p), from, target, time).set_trans(Tween.TRANS_SINE)
			_tweens.append(tw)


func _set_param(value: float, gi: GeometryInstance3D, param: String) -> void:
	if is_instance_valid(gi):
		gi.set_instance_shader_parameter(param, value)
