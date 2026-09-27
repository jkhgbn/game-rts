class_name BuildingType
extends Resource
## Stats for one kind of building. One .tres per building in data/buildings/, named <id>.tres.
## Numbers: docs/design/buildings.md. BuildGrid.create_building(type) builds the right node for it.

const DIR := "res://data/buildings/"
## Every building id, in build-menu order per faction (hearth, barracks, tower: keys Z X C).
## Ice adds the Ice Wall as a 4th build entry (key V, kingdom-ice.md section 5).
## Step 10 (market-trade.md 4.1): each kingdom's Bazaar (kind &"market", key B) comes last; it is only
## listed by buildable_for() while trade is on (trade_active()).
const ALL_IDS: Array[StringName] = [
	&"fire_keep", &"fire_hearth", &"fire_barracks", &"fire_tower", &"fire_market",
	&"shadow_keep", &"shadow_hovel", &"shadow_barracks", &"shadow_tower", &"shadow_market",
	&"ice_keep", &"ice_lodge", &"ice_barracks", &"ice_tower", &"ice_wall", &"ice_market",
	&"nature_keep", &"nature_hollow", &"nature_barracks", &"nature_tower", &"nature_market",
]
## Kinds that only exist in games with trade (market-trade.md 10: missions have no trade).
const TRADE_KINDS: Array[StringName] = [&"market"]

@export var id: StringName = &""
@export var display_name := ""
@export var faction: StringName = &""          ## &"fire", &"shadow", &"ice" or &"nature".
## &"keep", &"barracks", &"house" (hearth / hovel / lodge), &"tower" or &"wall": picks the script and the look.
@export var kind: StringName = &""
@export var cost := 0                          ## Crystals. 0 = not buildable (keeps).
@export var build_time := 30.0                 ## Seconds for one worker.
@export var max_hp := 500.0
@export var footprint := Vector2i(2, 2)        ## Cells of 2 m (x, z).
@export var height := 3.0                      ## Metres (placeholder look).
@export var pop_bonus := 0                     ## Added to the team's pop cap when completed.
@export var max_count := 0                     ## Per team, built or in construction. 0 = unlimited.
@export var trains: Array[UnitType] = []       ## Units it trains, in card order.
@export var attack_damage := 0.0               ## Towers only.
@export var attack_range := 0.0
@export var attack_cooldown := 1.5
@export var sight_radius := 0.0                ## For the fog of war (fog-of-war.md).
@export var hotkey_label := ""                 ## Build menu key letter ("" = not in the build menu).
@export var color := Color(0.85, 0.3, 0.12)    ## Kingdom colour (roofs, orb, construction outline).
@export var body_color := Color(0.5, 0.45, 0.4)
@export var projectile_color := Color(1.0, 0.75, 0.3)   ## Towers: the kingdom's archer bolt.
@export var model_scene: PackedScene
## Kingdoms Ice / Nature (kingdom-ice.md 2.4). Towers: status put on every unit their bolt hits
## (`apply_status(on_hit_status, on_hit_duration)`, e.g. the Rime Spire's `chill` 2 s).
@export var on_hit_status: StringName = &""
@export var on_hit_duration := 0.0
## Nature: % of max HP per s once completed, after Building.IDLE_REGEN_DELAY (10 s) without damage.
@export var idle_regen_pct := 0.0
## Nature tower: a completed building gives friendly non-worker units within this radius (m) the
## stat modifier `aura:<aura_id>` = `aura_stats` (Unit.receive_aura, refreshed 4 times per second).
@export var aura_radius := 0.0                 ## 0 = no aura.
@export var aura_stats: Dictionary = {}
@export var aura_id: StringName = &""          ## Aura source id ("" = the type id). Bramble Spire: &"bramble".
@export var counts_for_defeat := true          ## False on walls: the 1v1 defeat check ignores them.
## Unit ids for `trains` when that list is empty (types that may be added after this .tres):
## find() fills `trains` from them with UnitType.find.
@export var train_ids: Array[StringName] = []

@export_group("Trade")   # market-trade.md 4.1 / 12 (step 10)
## Placement needs a completed, living own building of this kind (BuildGrid.check): &"barracks" = a Hall
## (message BuildGrid.MSG_NEEDS_HALL). &"" = no rule.
@export var requires_kind: StringName = &""
## Placement centre must be within this many metres (flat, centre to centre) of an own living keep
## (BuildGrid.MSG_KEEP_DISTANCE). 0 = no rule.
@export var max_keep_distance := 0.0
## Where the model scene lives (res://...). Used while `model_scene` is empty and only once the file
## exists (get_model_scene), so a type can name its model before the art lands.
@export var model_path := ""

static var _cache: Dictionary = {}


## Finds a type by id ("fire_barracks") or display name ("Ember Hall"). Returns null if unknown.
static func find(id_or_name: String) -> BuildingType:
	var key := id_or_name.strip_edges().to_lower().replace(" ", "_")
	if _cache.has(key):
		return _cache[key]
	var path := DIR + key + ".tres"
	if ResourceLoader.exists(path):
		var type := load(path) as BuildingType
		if type:
			type._resolve_trains()
			_cache[key] = type
		return type
	# Display name: search the known ids.
	for bid in ALL_IDS:
		var t := find(String(bid))
		if t and t.display_name.to_lower().replace(" ", "_") == key:
			_cache[key] = t
			return t
	return null


## The buildings a worker of `faction` can build, in build-menu order (hearth, barracks, tower
## [, wall], then the Bazaar while trade_active()).
static func buildable_for(faction_id: StringName) -> Array[BuildingType]:
	var out: Array[BuildingType] = []
	var trade := -1   # looked up once, only if a trade building is met
	for bid in ALL_IDS:
		var t := find(String(bid))
		if t == null or t.faction != faction_id or not t.is_buildable():
			continue
		if t.needs_trade():
			if trade < 0:
				trade = 1 if trade_active() else 0
			if trade == 0:
				continue
		out.append(t)
	return out


## True while the current game has trade (a GoldBank or the TradeNetwork exists: market-trade.md 12,
## both are only created when `Skirmish.trade_enabled`). Missions and the step-9 map: false.
static func trade_active() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	return tree.get_first_node_in_group(&"gold_banks") != null \
			or tree.get_first_node_in_group(&"trade_network") != null


## True for the Bazaar (kind &"market"): the build menu hides it while trade_active() is false.
func needs_trade() -> bool:
	return TRADE_KINDS.has(kind)


## Fills `trains` from `train_ids` if it is still empty (a unit type added after the first find(),
## e.g. the caravan). Cheap when already resolved.
func resolve_trains() -> void:
	_resolve_trains()


func _resolve_trains() -> void:
	if not trains.is_empty() or train_ids.is_empty():
		return
	for uid in train_ids:
		var u := UnitType.find(String(uid))
		if u:
			trains.append(u)


## `model_scene`, else the scene at `model_path` when that file exists, else null (placeholder shapes).
func get_model_scene() -> PackedScene:
	if model_scene:
		return model_scene
	if model_path != "" and ResourceLoader.exists(model_path):
		return load(model_path) as PackedScene
	return null


func is_buildable() -> bool:
	return cost > 0 and kind != &"keep"


## Size of the footprint in metres (x, z).
func size_m() -> Vector2:
	return Vector2(footprint.x * 2.0, footprint.y * 2.0)
