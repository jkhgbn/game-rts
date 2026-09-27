class_name LaneBridgeArt
extends Node3D
## West / East Crown Bridge (task 12.V3, docs/design/map-fill.md 2.2 and section 10). One scene, used twice.
## Draw-only: no collider (the deck gap in the river carve is ordinary navmesh), 0 lights, 1 MeshInstance3D
## with 3 surfaces (nature_mat stone / moss / ivy, crown_gold_mat trims, lane_bridge_ember_mat coals).
## Local space: metres, y up, origin = the crossing centre on the moat centre line (r 12.75), deck top at
## y 0.0-0.03 (walkable 8 m along X, 6.5 m along Z). **Local +Z points AWAY from the isle** (the isle centre
## is at local (0, 0, -12.75)): the moat's curvature is baked into the arches, piers and abutments, so place it
## with `place_on_moat()` (or `basis_for()`), never by the lane direction alone (a 180 deg turn bends the arches
## the wrong way). Rebuild the mesh with art/environment/bridges/build_lane_bridge.gd.

const MOAT_RADIUS := 12.75     ## Moat centre-line radius the mesh is built for (water r 11.0-14.5).
const DECK_WIDTH := 8.0        ## Walkable deck, local X (tangential).
const DECK_LENGTH := 6.5       ## Along the lane, local Z (radial).
const DECK_TOP_Y := 0.03       ## Highest point of the paving (units stand at y 0).
## Stones standing in the moat, local (x, z, radius): the two cutwaters and the fallen coping stone.
const WATER_STONES: Array[Vector3] = [Vector3(4.75, -0.95, 0.65), Vector3(-4.75, -0.95, 0.65), Vector3(4.9, 0.42, 0.4)]


## World (x, z, radius, 0) of WATER_STONES for a bridge at `center`: feed them to the water material's
## `foam_rocks` (12.V1) so the moat foams around the cutwaters.
static func foam_rocks(center: Vector3, isle_center: Vector3 = Vector3.ZERO) -> PackedVector4Array:
	var b: Basis = basis_for(center, isle_center)
	var out := PackedVector4Array()
	for s: Vector3 in WATER_STONES:
		var p: Vector3 = Vector3(center.x, 0.0, center.z) + b * Vector3(s.x, 0.0, s.y)
		out.append(Vector4(p.x, p.z, s.z, 0.0))
	return out


## Basis that turns local +Z away from `isle_center` (horizontal), +Y up.
static func basis_for(center: Vector3, isle_center: Vector3 = Vector3.ZERO) -> Basis:
	var out := Vector3(center.x - isle_center.x, 0.0, center.z - isle_center.z)
	if out.length_squared() < 1e-6:
		return Basis.IDENTITY
	out = out.normalized()
	return Basis(Vector3.UP.cross(out), Vector3.UP, out)


## Puts the bridge on the moat: `center` = the crossing centre (e.g. (-9.02, 0, 9.02)), y forced to 0.
func place_on_moat(center: Vector3, isle_center: Vector3 = Vector3.ZERO) -> void:
	transform = Transform3D(basis_for(center, isle_center), Vector3(center.x, 0.0, center.z))
	if is_inside_tree():
		reset_physics_interpolation()
