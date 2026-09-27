class_name UnitType
extends Resource
## Stats for one kind of trainable unit. One .tres per unit in data/units/, named <id>.tres.
## Build a unit with UnitType.find("flame_guard").create_unit() (main.make_unit does this).

const DIR := "res://data/units/"

@export var id: StringName = &""
@export var display_name := ""
@export var faction: StringName = &""        ## &"fire", &"shadow", &"ice", &"nature" or &"neutral" (camps).
@export var is_worker := false               ## Workers gather crystals (economy, task 1.S1).
@export var cost := 0                        ## Crystals.
@export var pop := 1
## XP the killing side gets for this unit (levels.md victim table; soldiers ~ cost / 2).
@export var kill_xp := 0
@export var train_time := 10.0               ## Seconds.
@export var card_key := ""                   ## Command card hotkey letter at the keep ("" = none).
@export var max_hp := 100.0
@export var move_speed := 5.0
@export var attack_damage := 10.0
@export var attack_range := 1.6              ## More than 3.0 means the unit shoots projectiles.
@export var attack_cooldown := 1.0
@export var aggro_range := 8.0               ## 0 = never picks fights by itself.
@export var radius := 0.45
@export var body_height := 1.6
@export var body_color := Color(0.85, 0.3, 0.12)
@export var projectile_color := Color(1.0, 0.7, 0.3)
## Ranged units: flight speed of the auto-attack bolt in m/s (Unit._spawn_shot; 25 = the old fixed speed).
@export var projectile_speed := 25.0
@export var eye_color := Color(0.95, 0.9, 0.8)   ## The visor on the placeholder capsule.
@export var model_scene: PackedScene
## Keep tier needed to train it (tiers.md): 1 = always, 2 = Stronghold, 3 = Citadel (TierSystem.tier_of).
@export var requires_tier := 1

@export_group("Kingdom mechanics")   # kingdom-ice.md 2.2 (step 7, shared with Nature)
## Base `armor` stat (damage x 100 / (100 + armor)); items add on top.
@export var armor := 0.0
## Percent of max HP regenerated per second after 4 s without taking damage (1.5 = 1.5 %/s).
@export var idle_regen_pct := 0.0
## Status put on the target by each auto-attack that lands (melee or projectile), e.g. &"chill".
@export var on_hit_status: StringName = &""
@export var on_hit_duration := 0.0
## Support autocast (SupportCaster): &"shield" or &"heal"; &"" = none.
@export var support_kind: StringName = &""
@export var support_amount := 0.0      ## Shield points or HP healed.
@export var support_interval := 0.0    ## Seconds between casts.
@export var support_range := 0.0       ## Metres.
@export var support_duration := 0.0    ## Shield duration (s); unused by heal.
## Summons: seconds before the unit withers (dies); 0 = permanent.
@export var lifetime := 0.0

@export_group("Trade")   # market-trade.md 12 (step 10)
## Caravans: Worker.make_unit builds a Caravan (scripts/economy/caravan.gd). Caravans never level up and never
## get the soldier wares.
@export var is_caravan := false
## False = the player never orders it (Greywater Trackers): selection, groups, F2, right-click and the
## command card skip it; clicking it only inspects. Unit.is_commandable() returns this.
@export var commandable := true
## NEUTRAL units only: true = camp guardian (fights only inside its leash, walks home); false = roams like a
## normal unit and keeps its orders (Magpies: the band brain moves them).
@export var neutral_leash := true
## Fog sight in metres; 0 = FogOfWar's table by id (FogOfWar.sight_of reads this first).
@export var sight_radius := 0.0
## Where this type's model scene lives (market-trade.md 12), recorded before the art landed. Never loaded
## automatically (a half-built scene must not break the game): `model_scene` points at it once the model is
## finished (done for caravan / magpie / greywater_tracker in task 10.C10).
@export var model_path := ""

static var _cache: Dictionary = {}


## Finds a type by id ("flame_guard") or display name ("Flame Guard"). Returns null if unknown.
static func find(id_or_name: String) -> UnitType:
	var key := id_or_name.strip_edges().to_lower().replace(" ", "_")
	if _cache.has(key):
		return _cache[key]
	var path := DIR + key + ".tres"
	if not ResourceLoader.exists(path):
		return null
	var type := load(path) as UnitType
	if type:
		_cache[key] = type
	return type


## Creates a new Unit with these stats. Set its team, then add it to the scene.
func create_unit() -> Unit:
	var unit := Unit.new()
	unit.apply_type(self)
	return unit
