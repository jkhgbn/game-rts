class_name MapCatalog
extends Resource
## The skirmish map catalog (docs/design/map-production.md 2.8 / MT9): every map the skirmish menu can offer, one
## Dictionary per map in `data/maps/catalog.tres`. The menu's map picker (scripts/ui/menus/main_menu.gd) lists the
## `ready` maps, filtered by seat count (2 = 1v1, 4 = 2v2), and MenuFlow.start_skirmish builds the level with
## `instantiate_level(id)`:
## - a `scene` entry (Crown Hollow: res://scenes/skirmish.tscn, the hand-built map) is instanced as it is;
## - a `layout` entry is scenes/layout_level.tscn with `layout_path` set before it enters the tree (LayoutLevel maps
##   the layout's seats: the first open seat of side 0 is the player, the first of side 1 the bot).
## Until the 4-seat runtime exists (FOUR_SEAT_RUNTIME false), a 4-seat (2v2) map plays as a 1v1 on one seat per side;
## `plays_as(entry)` says so and the picker shows the note.
## Entry keys: id (StringName), title, scene or layout (res:// path), size (Vector2, metres x / z), seats (int),
## biome (look only), kingdom (the look: "neutral" or a kingdom id), preview (res:// PNG, the World Forge `mapsheet`
## top-down render, 512 x 512, data/maps/previews/<id>.png), hook (one line for the menu), tags (Array of String),
## ready (bool: playable and gated; only ready maps are listed and drawn by Random), note (why not ready, optional),
## mode (optional: "skirmish" when absent; "wave_strike" maps are listed only with mode = "wave_strike", never in the
## skirmish picker or its Random draw; docs/design/wave-strike.md 7.4).

const PATH := "res://data/maps/catalog.tres"
const DEFAULT_ID := &"crown_hollow"     ## The menu's default map (the scene-built Crown Hollow).
const RANDOM_ID := &"random"            ## The picker's "Random" entry: resolved to a ready map at start.
const LAYOUT_SCENE := "res://scenes/layout_level.tscn"
## False until Skirmish2v2 on a layout exists (map-production.md MT2 open point): 4-seat maps play 1v1.
const FOUR_SEAT_RUNTIME := false
const SEATS_1V1 := 2
const SEATS_2V2 := 4

@export var maps: Array[Dictionary] = []

static var _cached: MapCatalog = null


## The catalog of data/maps/catalog.tres (loaded once; an empty catalog with Crown Hollow alone when the file is
## missing, so the menu always has its default).
static func load_default() -> MapCatalog:
	if _cached != null:
		return _cached
	if ResourceLoader.exists(PATH):
		_cached = load(PATH) as MapCatalog
	if _cached == null:
		_cached = MapCatalog.new()
		_cached.maps = [{"id": DEFAULT_ID, "title": "Crown Hollow", "scene": "res://scenes/skirmish.tscn",
			"size": Vector2(120, 120), "seats": 2, "biome": "grass", "kingdom": "neutral", "preview": "", "hook": "",
			"tags": [], "ready": true}]
	return _cached


## Every map id in catalog order.
func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in maps:
		out.append(StringName(e.get("id", "")))
	return out


func has_map(map_id: StringName) -> bool:
	return not entry(map_id).is_empty()


## The entry of `map_id`, or {}.
func entry(map_id: StringName) -> Dictionary:
	for e in maps:
		if StringName(e.get("id", "")) == map_id:
			return e
	return {}


## The entries with `seats` players (0 = any), in catalog order; `ready_only` drops the maps that are not ready;
## `mode` keeps the maps of that game mode ("skirmish" = entries without a mode).
func list(seats: int = 0, ready_only: bool = true, mode: String = "skirmish") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in maps:
		if mode_tag(e) != mode:
			continue
		if seats > 0 and int(e.get("seats", 2)) != seats:
			continue
		if ready_only and not bool(e.get("ready", false)):
			continue
		out.append(e)
	return out


## True when `map_id` is a ready skirmish map (Random never draws anything else; Wave Strike maps are not).
func is_ready(map_id: StringName) -> bool:
	var e := entry(map_id)
	return bool(e.get("ready", false)) and mode_tag(e) == "skirmish"


## The entry's game mode: "skirmish" (no `mode` key) or e.g. "wave_strike".
static func mode_tag(e: Dictionary) -> String:
	return String(e.get("mode", "skirmish"))


## A ready map with `seats` players (0 = any), drawn with `rng` (a fresh randomized one when null). &"" if none.
func pick_random(seats: int = 0, rng: RandomNumberGenerator = null) -> StringName:
	var pool := list(seats, true)
	if pool.is_empty():
		return &""
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	return StringName(pool[rng.randi_range(0, pool.size() - 1)]["id"])


## `map_id` itself when it is a ready map, a ready map with the same seat filter for RANDOM_ID, else the default.
func resolve(map_id: StringName, seats: int = 0, rng: RandomNumberGenerator = null) -> StringName:
	if map_id == RANDOM_ID:
		var r := pick_random(seats, rng)
		return r if r != &"" else DEFAULT_ID
	return map_id if is_ready(map_id) else DEFAULT_ID


## "1v1" or "2v2" from the seat count.
static func mode_of(e: Dictionary) -> String:
	return "2v2" if int(e.get("seats", 2)) >= SEATS_2V2 else "1v1"


## How the map plays today: "1v1", or "2v2" once FOUR_SEAT_RUNTIME is true.
static func plays_as(e: Dictionary) -> String:
	return "2v2" if mode_of(e) == "2v2" and FOUR_SEAT_RUNTIME else "1v1"


## The picker's line under the preview for a map that does not play its own mode yet ("" = none).
static func mode_note(e: Dictionary) -> String:
	if mode_of(e) == "2v2" and not FOUR_SEAT_RUNTIME:
		return "2v2 map: plays as a 1v1 for now (one seat per side; 2v2 skirmish comes later)."
	return ""


## "120 m · 2 players" (non-square: "150 x 120 m").
static func size_text(e: Dictionary) -> String:
	var s: Vector2 = e.get("size", Vector2(120, 120))
	var dims := "%d m" % int(s.x) if is_equal_approx(s.x, s.y) else "%d x %d m" % [int(s.x), int(s.y)]
	return "%s · %d players" % [dims, int(e.get("seats", 2))]


## The lobby preview of `map_id` (the mapsheet render), or null when it has none.
func preview_texture(map_id: StringName) -> Texture2D:
	var p := String(entry(map_id).get("preview", ""))
	if p == "":
		return null
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
	if FileAccess.file_exists(p):   # not imported yet (a fresh preview): read the PNG itself
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


## The level of `map_id`, not yet in the tree (the caller sets kingdoms / difficulty, then adds it): the entry's
## scene, or LayoutLevel with `layout_path` set. Null for an unknown map or a missing file.
func instantiate_level(map_id: StringName) -> Node:
	var e := entry(map_id)
	if e.is_empty():
		return null
	var scene_path := String(e.get("scene", ""))
	var layout_path := String(e.get("layout", ""))
	if scene_path == "" and layout_path != "":
		scene_path = LAYOUT_SCENE
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return null
	var level := (load(scene_path) as PackedScene).instantiate()
	if layout_path != "" and &"layout_path" in level:
		level.set(&"layout_path", layout_path)
	return level


## The layout path of `map_id` ("" for a scene map).
func layout_path_of(map_id: StringName) -> String:
	return String(entry(map_id).get("layout", ""))
