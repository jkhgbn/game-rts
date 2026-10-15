class_name CrossingArt
extends Node3D
## Root of the road bridge, ford and Crown Steps models (task 12.V4, map-fill.md 2.2 / section 10). Draw-only: no
## collider (the river carve leaves the crossing walkable), 0 lights, two MeshInstance3D children: "Body" (shared
## env_painted_mat, + lantern_glow_mat on the bridge) and "Foam" (crossing_foam_mat, transparent white water).
## Meshes are baked by art/environment/bridges/build_crossings.gd. Origin = the crossing centre at ground level.
## Local frames (use place_crossing() or basis_for(), the meshes are not symmetric):
##   &"bridge_road"  +Z along the road, pointing east (basis_for flips `dir` if needed). The piers / abutments are
##                   skewed 12.8 deg for the river under Saltgate Bridge and the foam wakes trail south (the flow);
##                   Millstone Bridge has the same road and river axes (point mirror of lines), so it gets the SAME
##                   yaw, not a 180 deg turn.
##   &"ford"         +Z DOWNSTREAM (the flow: north -> south in both rivers, so both fords get the same yaw).
##   &"steps"        +Z AWAY from the isle centre (same as the lane bridge); the moat curvature is baked in.

## Which crossing this model dresses: &"bridge_road", &"ford" or &"steps" (the RiverSystem crossing kinds).
@export var kind: StringName = &"bridge_road"


const WATER_Y := -0.35          ## RiverSystem.WATER_Y (bridge piers, Crown Steps)
const FORD_WET_Y := -0.15       ## ford stones: the film is at 0.02, but only their feet should look wet


## G2b: the wet-stone waterline overlay on the body (water_quality.gd, load-guarded; off on Low).
func _ready() -> void:
	const WQ := "res://art/environment/water/water_quality.gd"
	var body := get_node_or_null(^"Body") as GeometryInstance3D
	if body and ResourceLoader.exists(WQ):
		(load(WQ) as Script).call(&"register_overlay", body, FORD_WET_Y if kind == &"ford" else WATER_Y)


## Basis for a crossing model of `kind` at `center`. `dir`: the road direction (bridge_road), the downstream flow
## direction (ford); ignored for steps (turned away from `isle_center`).
static func basis_for(crossing_kind: StringName, center: Vector3, dir: Vector3,
		isle_center: Vector3 = Vector3.ZERO) -> Basis:
	var z := Vector3(dir.x, 0.0, dir.z)
	if crossing_kind == &"steps":
		z = Vector3(center.x - isle_center.x, 0.0, center.z - isle_center.z)
	if z.length_squared() < 1e-6:
		return Basis.IDENTITY
	z = z.normalized()
	# The bridge's pier wakes are baked for Crown Hollow's rivers, which flow south under both road bridges (and the
	# road / river axes are the same at Saltgate and Millstone): +Z always points east, whichever way `dir` runs.
	if crossing_kind == &"bridge_road" and z.x < 0.0:
		z = -z
	return Basis(Vector3.UP.cross(z), Vector3.UP, z)


## Puts the model on its crossing: `center` (y forced to 0) and `dir` as in basis_for().
func place_crossing(center: Vector3, dir: Vector3 = Vector3.FORWARD, isle_center: Vector3 = Vector3.ZERO) -> void:
	transform = Transform3D(basis_for(kind, center, dir, isle_center), Vector3(center.x, 0.0, center.z))
	if is_inside_tree():
		reset_physics_interpolation()
