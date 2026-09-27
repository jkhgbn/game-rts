class_name MapLayout
extends Resource
## A skirmish map layout written by World Forge (`tools/world_forge/run_world_forge.ps1 map <id>` from
## `data/maps/<id>.map`): every spot with its mirror twins already placed, the seats and their frames, the river,
## crossings, roads, zones and blocking obstacles. Step 20 map code (and the Map Lab preview) reads it instead of
## hand constants. Plain data: positions are Vector3 on the ground (y = 0).

@export var id: StringName = &""
@export var title: String = ""
## Map edge length in metres (square, x and z in -size/2 .. size/2).
@export var size: float = 120.0
## "none" | "mirror_x" | "mirror_z" | "rot180" | "fourfold" (mirror x + mirror z).
@export var symmetry: String = "none"
## [{team: int, name: String, side: int, frame: Transform3D}]: `frame` maps the canonical seat's points onto this seat.
@export var seats: Array[Dictionary] = []
## [{id: String, kind: String, sub: String, pos: Vector3, team: int, twin_of: String, props: Dictionary}].
## kind: keep, node, point, camp, tavern, post, guild, peddler, cache, lair, crown, start, slot.
@export var spots: Array[Dictionary] = []
## River arms [{poly: PackedVector3Array, half_width: float}] and the moat {center: Vector3, radius, half_width} ({} = none).
@export var river: Array[Dictionary] = []
@export var moat: Dictionary = {}
## Crossings, RiverSystem shape: [{id, name, kind (bridge_road / bridge_lane / ford / steps), center, width, length, dir}].
@export var crossings: Array[Dictionary] = []
## [{id, poly: PackedVector3Array, width}]
@export var roads: Array[Dictionary] = []
## [{id, kind: "circle" | "rect", center, r0, r1, min, max, biome}]
@export var zones: Array[Dictionary] = []
## Blocking obstacles [{id, center: Vector3, half: Vector3, yaw: float (deg)}] (cliffs, rock walls, dense forest).
@export var blocks: Array[Dictionary] = []
## Pre-baked navmeshes used instead of baking the preview [{path: String, xf: Transform3D}] (export-map saves the live
## map's regions here, so preview paths = live paths). Empty = bake from ground + water + keeps + blocks.
@export var navmeshes: Array[Dictionary] = []
## The .map spec it came from and its hash (World Forge report).
@export var source: String = ""
@export var source_hash: String = ""


func spots_of(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in spots:
		if s["kind"] == kind:
			out.append(s)
	return out


func spot(spot_id: String) -> Dictionary:
	for s in spots:
		if s["id"] == spot_id:
			return s
	return {}


func seat_frame(team: int) -> Transform3D:
	for s in seats:
		if int(s["team"]) == team:
			return s["frame"]
	return Transform3D.IDENTITY


func keep_of(team: int) -> Dictionary:
	for s in spots:
		if s["kind"] == "keep" and int(s["team"]) == team:
			return s
	return {}
