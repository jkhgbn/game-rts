class_name FacePrewarm
extends RefCounted
## Builds the per-type caches of a kingdom's unit models (faces: FaceKit / CreatureFaceRig meshes for every expression
## + FAR, and the kit's merged pivot meshes) while the level loads, so the first unit of a type that spawns mid-match
## (first T3, first champion, first beast) costs nothing extra on its spawn frame (review-art-faces.md M3).
## One instance of each model scene is added under a hidden node, its _ready builds and caches everything, and it is
## freed right away. Second and later instances of a type always reuse the caches, so this only pays the build once.
##
##   FacePrewarm.warm(get_tree().root, [&"fire", &"shadow", &"neutral"], true)   # at level load (sync, ~ms per type)
##
## Returns {"types": n, "ms": total ms, "slowest": [path, ms]}.

const UNIT_DIR := "res://data/units/"
const CHAMPION_DIR := "res://data/champions/"

static var _done: Dictionary = {}   # scene path -> true (warmed in this process)


## The model scenes of `kingdom` (UnitType.faction; &"neutral" = creatures, beasts, caravans...).
static func scenes_of(kingdom: StringName) -> Array[PackedScene]:
	var out: Array[PackedScene] = []
	for f: String in _tres_in(UNIT_DIR):
		var t := load(UNIT_DIR + f) as UnitType
		if t and t.faction == kingdom and t.model_scene:
			out.append(t.model_scene)
	return out


## The champion model scenes (every skirmish can hire them).
static func champion_scenes() -> Array[PackedScene]:
	var out: Array[PackedScene] = []
	for f: String in _tres_in(CHAMPION_DIR):
		var r: Resource = load(CHAMPION_DIR + f)
		var ps: Variant = r.get(&"model_scene") if r else null
		if ps is PackedScene:
			out.append(ps)
	return out


## Warms every model of `kingdoms` (+ the champions when `champions`) synchronously under `parent`. Each scene once
## per process (later calls skip it).
static func warm(parent: Node, kingdoms: Array, champions: bool = false) -> Dictionary:
	var scenes: Array[PackedScene] = []
	for k: Variant in kingdoms:
		scenes.append_array(scenes_of(StringName(k)))
	if champions:
		scenes.append_array(champion_scenes())
	return warm_scenes(parent, scenes)


static func warm_scenes(parent: Node, scenes: Array[PackedScene]) -> Dictionary:
	var res := {"types": 0, "ms": 0.0, "slowest": ["", 0.0]}
	if parent == null or not parent.is_inside_tree():
		return res
	var hold := Node3D.new()
	hold.name = "FacePrewarm"
	hold.visible = false
	hold.position = Vector3(0, -500, 0)
	parent.add_child(hold)
	for ps: PackedScene in scenes:
		if ps == null or _done.has(ps.resource_path):
			continue
		_done[ps.resource_path] = true
		var t0 := Time.get_ticks_usec()
		var n := ps.instantiate()
		hold.add_child(n)   # _ready: _build_parts (faces) + merge, cached per type
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0
		res["types"] = int(res["types"]) + 1
		res["ms"] = float(res["ms"]) + ms
		if ms > float(res["slowest"][1]):
			res["slowest"] = [ps.resource_path, ms]
		n.queue_free()
	hold.queue_free()
	return res


## Same as warm() spread over frames (await it): at most `ms_per_frame` of building per frame (a type is never split,
## so one frame can take one type's cost: 100-450 ms measured 2026-10-02). For a load screen or the first seconds.
static func warm_async(parent: Node, kingdoms: Array, champions: bool = false, ms_per_frame: float = 50.0) -> Dictionary:
	var scenes: Array[PackedScene] = []
	for k: Variant in kingdoms:
		scenes.append_array(scenes_of(StringName(k)))
	if champions:
		scenes.append_array(champion_scenes())
	var total := {"types": 0, "ms": 0.0, "slowest": ["", 0.0]}
	var frame_ms := 0.0
	for ps: PackedScene in scenes:
		if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
			break
		var one: Array[PackedScene] = [ps]
		var r := warm_scenes(parent, one)
		total["types"] = int(total["types"]) + int(r["types"])
		total["ms"] = float(total["ms"]) + float(r["ms"])
		if float(r["slowest"][1]) > float(total["slowest"][1]):
			total["slowest"] = r["slowest"]
		frame_ms += float(r["ms"])
		if frame_ms >= ms_per_frame:
			frame_ms = 0.0
			await parent.get_tree().process_frame
	return total


## Forget which scenes were warmed (tests).
static func reset() -> void:
	_done.clear()


static func _tres_in(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f: String in DirAccess.get_files_at(dir):
		var g := f.trim_suffix(".remap")
		if g.ends_with(".tres"):
			out.append(g)
	return out
