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

# ---------------------------------------------------------------- grammar v2 (map-production.md 2.2, MT3)
## Width (x) and depth (z) in metres (`map <id> size=WxD`; a square map has both = size). `size` keeps the larger.
@export var size_x: float = 120.0
@export var size_z: float = 120.0
## The biome kit of the map (`map ... biome=`): look only (ground params, decor), "" = the Crown Hollow grass.
@export var biome: String = ""
## Light mood (`map ... light=` / overlay `light=`): "" (day) / night / dawn / storm / winter.
@export var light: String = ""
## The base map of a mission overlay / variant (`map <id> base=<map> variant=<v>`), "" for a base map.
@export var base: String = ""
@export var variant: String = ""
## The `forest` statement (the main.gd / skirmish.gd tree-and-rock generator as data; MapForest builds it):
## {seed, clusters, trees: Vector2 (count range), spread, cluster_r, tree_size: Vector2, rocks, rock_spread,
## rock_size: Vector2, half ("xz" | "x" | "quad"), pre: [Vector3(x, z, r)] (clearings checked before the size draw),
## lane: PackedVector3Array (a 5 m wide lane kept open, checked before the size draw), clear ("auto" | "none"),
## pillars: Vector3(x, z, ring r) or null, pillar_count, pillar_gap, pillar_h: Vector2, grove_seed,
## willows: {seed, draws, river_draws, arc: Vector2 (deg), spacing, gap: Vector2, crossing_gap}}. {} = no forest.
@export var forest: Dictionary = {}
## Old-wood groves (`grove <id> at= r= trees=`), mirrored: [{id, center, r, trees}] (drawn from forest.grove_seed).
@export var groves: Array[Dictionary] = []
## Landmark props with colliders (`prop <id> scene= at= yaw= clear= colliders=[(x,z,r)...]`), mirrored:
## [{id, scene, pos, yaw (rad), clear, colliders: [Vector3(local x, local z, r)]}].
@export var props: Array[Dictionary] = []
## `rules archetype= tempo= <target>=a..b ...`: {archetype, tempo, targets: {keep_enemy: Vector2, natural, rich,
## third, crown, ally, enemy_ally (ratio band), ...}, contest: float (R3 minimum per seat)}. Map Lab R1 / R3 read it.
@export var rules: Dictionary = {}
## Seats whose district becomes neutral land (`closed_seat <team> becomes=neutral`): no keep, its nodes stay.
@export var closed_seats: Array[int] = []
## Seats driven by a mission script (`seat <team> scripted`).
@export var scripted_seats: Array[int] = []
## Mission overlay data: named points / areas / routes (`mark`, `trigger`, `path`) and the playable bounds
## (`bounds rect(...)`; Rect2() = the whole map).
@export var marks: Dictionary = {}       ## id -> Vector3
@export var triggers: Dictionary = {}    ## id -> area dict (World Forge area: circle / ring / rect)
@export var paths: Dictionary = {}       ## id -> PackedVector3Array
@export var bounds: Rect2 = Rect2()
## Terrain statements (`terrain` / `hill` / `ridge` / `valley` / `pad`, forge_terrain.gd shapes), stored for the
## height-field pass (v2 limit: the runtime level is still flat; the preview and Map Lab ignore heights).
@export var terrain: Array[Dictionary] = []
## Templates expanded into this layout (`use` lines): ["<template> at (x, z)", ...] (report only).
@export var templates_used: Array[String] = []


## A mission mark's position (`mark <id> at=`), or Vector3.INF.
func mark(mark_id: String) -> Vector3:
	return marks.get(mark_id, Vector3.INF)


## A mission trigger area (`trigger <id> <area>`), or {}.
func trigger(trigger_id: String) -> Dictionary:
	return triggers.get(trigger_id, {})


## A mission path (`path <id> poly=`), or an empty array.
func path(path_id: String) -> PackedVector3Array:
	return paths.get(path_id, PackedVector3Array())


## The playable bounds: `bounds` when set, else the whole map.
func play_bounds() -> Rect2:
	return bounds if bounds.has_area() else Rect2(-size_x * 0.5, -size_z * 0.5, size_x, size_z)


## The seats that play (not closed), in file order.
func open_seats() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in seats:
		if not closed_seats.has(int(s["team"])):
			out.append(s)
	return out


## The `rules` target band for a key ("keep_enemy", "natural"...), or Vector2.ZERO when the map sets none.
func target(key: String) -> Vector2:
	return (rules.get("targets", {}) as Dictionary).get(key, Vector2.ZERO)


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
