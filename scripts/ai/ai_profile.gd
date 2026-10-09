class_name AIProfile
extends Resource
## The knobs of one bot difficulty (docs/design/ai.md "Difficulty"). The three presets are built in
## code (easy(), normal(), hard(), for_difficulty()); a .tres with these fields can replace one through
## Commander.profile. No knob gives free crystals: every difficulty mines and pays like the player
## (the spec's income_mult is 1.0 at every level, so it does not exist here).

enum MalrikJoins { NEVER, SECOND_ATTACK_OR_STRENGTH, EVERY_ATTACK }

@export var id: StringName = &"normal"
@export var decision_interval := 1.0        ## Seconds between two think ticks.
@export var reaction_delay := 1.5           ## Seconds before acting on an intrusion.
@export var build_delay := 3.0              ## Seconds between a build trigger and the placement.
@export var worker_target_home := 6
@export var worker_target_expanded := 9
## balance-1.md 2f: workers once the second forward hall (X2, rich node) stands (normal / hard 12).
@export var worker_target_x2 := 12
@export var second_expansion := true        ## balance-1.md 2f: X2 on normal and hard only.
@export var camp_strength := 900.0          ## balance-1.md 2f: rule 7 crown-camp attack from this strength...
@export var camp_time := 330.0              ## ...and from this match time (5:30).
@export var queue_depth := 2                ## Units queued at once per training building.
@export var attack_ratio := 1.3             ## Attack when own strength >= this x max(seen, 250).
@export var min_attack_pop := 6
## 20.A3 (rule 7 patience): once the army is gathered at the rally, the ratio falls from attack_ratio to this...
@export var attack_ratio_floor := 0.8
@export var attack_patience := 90.0         ## ...over this many seconds (0 = never).
@export var attack_full_pop := 20           ## Launch anyway with this army pop gathered (0 = never).
@export var first_attack_by := 600.0        ## No attack yet at this match time: the floor ratio at once (0 = never).
@export var memory_seconds := 120.0         ## Seen enemy units are forgotten after this.
@export var scout_interval := 120.0
@export var malrik_joins: MalrikJoins = MalrikJoins.SECOND_ATTACK_OR_STRENGTH
@export var malrik_join_strength := 800.0   ## SECOND_ATTACK_OR_STRENGTH: also joins from this strength.
@export var no_reserve_at_cap := false      ## Hard: no home reserve when pop_used >= pop_cap - 2.
@export var malrik_join_level := 4          ## SECOND_ATTACK_OR_STRENGTH: also joins from this wizard level.
## levels.md "The bot": spell point spending order, "<slot><rank>" with slot F / Q / E = spell 1 / 2 / 3.
@export var spell_order := PackedStringArray(["Q1", "F2", "E1", "F3", "Q2", "Q3", "E2"])
## items.md "The bot" (4.A1): item ids bought in this order (recipe parts first, as listed).
@export var item_build := PackedStringArray(["ember_shard", "bone_charm", "grave_pact", "ember_draught",
		"gloom_ink", "mana_thread", "siphon_idol", "gravemaw_idol", "ironbark_plate", "wisp_lantern",
		"nightveil_cloak", "swiftsoles", "wisp_lantern", "ashen_greaves", "shadowstride"])
## Ember Draughts kept in stock (refilled up to the number the list has bought, at most this).
@export var potion_stock := 1

## 7.A1: the kingdom knobs (kingdom-ice.md section 7). Defaults = the Shadow / Fire bot of ai.md.
@export var profile_id: StringName = &"shadow_default"   ## shadow_default / ice_default / mission_01.
@export var defend_radius := 28.0            ## Rule 1: intruders this close to a building start the defence.
@export var retreat_hp := 0.4                ## Rule 2: the group retreats below this share of its launch HP.
@export var tower1_time := 300.0             ## S1 at this time (or at the first intrusion).
@export var tower2_time := 480.0             ## S2 at this time.
@export var expand_time := 300.0             ## X1 at this time...
@export var expand_home_below := 0           ## ...or when the home nodes hold fewer crystals (0 = half of the start).
## 2026-10-09 (Ice income fix): extra home Halls (rows H2 / H3, 0 = none). Each is placed when every own Hall's queue
## is full and the bank holds extra_hall_bank crystals (the slow Frost Hall floated 400-1 300 crystals by 3:00).
@export var extra_halls := 0
@export var extra_hall_bank := 300
@export var build_walls := false             ## Ice hard: 2 walls beside S1 (kingdom-ice.md 7 "Walls").
@export var wall_path_ratio := 1.5           ## Walls only while keep -> rally path < this x the straight line.
## Target share of soldier pop per barracks slot (card order), default / vs ranged / vs melee.
@export var mix_default := PackedFloat32Array([0.40, 0.30, 0.15, 0.15])
@export var mix_vs_ranged := PackedFloat32Array([0.30, 0.15, 0.40, 0.15])
@export var mix_vs_melee := PackedFloat32Array([0.25, 0.45, 0.10, 0.20])
@export var scout_worker_before := 150.0     ## A worker may scout before this time.
@export var scout_fast := true               ## Prefer the fastest soldier type as scout; false: the cheapest soldier.
@export var retreat_spell: StringName = &""  ## Cast (if ready) when the wizard goes home hurt (Ice: Rime Aegis).
## Mission knobs (mission-01.md "The bot").
@export var launch_attacks := true           ## False: never sends an attack group (not even capped / all-in).
@export var max_soldiers := 0                ## Soldiers kept (trained + queued); 0 = no limit.
@export var build_rows := PackedStringArray()   ## Build rows allowed (H1, V1, S1...); empty = all.
@export var rebuild := true                  ## False: a slot's building that fell is never rebuilt.
@export var hero_stays_home := false         ## True: the wizard never joins attacks or goes for the crown.
## 8.A1: the Nature knobs (kingdom-nature.md section 6). Defaults = the behaviour before 8.A1.
@export var opening_workers := 0             ## Workers the keep may queue at once until this many were queued.
@export var heavy_crystals := 300            ## The heavy slot (3) only from these crystals...
@export var heavy_soldier_pop := 8           ## ...and this soldier pop (Nature: 200 / 6).
@export var regrow_hp := 0.0                 ## After a retreat, the next attack needs this average HP share...
@export var regrow_wait := 30.0              ## ...or this many seconds back at the rally (0 regrow_hp = off).
@export var first_scout_time := -1.0         ## First scout at this match time (-1 = scout_interval).
## 9.C9: champions (champions.md 10, rule 9). Defaults = normal; easy() / hard() and the .tres set their own.
@export var champion_max := 2                ## Champions hired at most (0 = never hires).
## Archetype ids hired in this order (ChampionGuild.ARCHETYPES ids).
@export var champion_order := PackedStringArray(["coin_cutter", "oathwall"])
@export var champion_earliest := 180.0       ## No hire before this match time (normal 3:00).
@export var revive_before_items := true      ## True: a revive holds the essence items would use (easy: after items).
@export var bounty_budget_pct := 0.25        ## Stakes of active flags <= this x (essence above the next item price).
@export var bounty_max_flags := 2            ## Active bounty flags at most.
@export var bounty_guard_only := false       ## Easy: only rule B1 (Guard flags).
@export var explore_unseen := 120.0          ## B4: the enemy hall spot unseen this long gets an Explore flag.
## 10.A3: trade (market-trade.md 7, rule 10). Defaults = normal; easy() / hard() and the .tres set their own.
@export var trade := true                    ## False: the bot never builds a Bazaar or spends gold (missions).
@export var trade_start := 330.0             ## 10a: earliest Bazaar (match time; 10b "behind" ignores it).
@export var caravan_target := 4              ## 10c: caravans kept (alive + queued)...
@export var caravan_target_late := 6         ## ...once home nodes a and b are both empty.
@export var far_route_caravans := 2          ## 10d: caravans sent to the far post when ahead (0 = never).
@export var far_route_ratio := 1.5           ## 10d: far only while own_strength >= this x max(seen, 250).
## 10g: wares bought in this order (GoldBank.WARES ids).
@export var ware_order := PackedStringArray(["iron_axles", "masons_charter", "tempered_steel", "gambesons"])
@export var axles_min_caravans := 3          ## 10g: Iron-shod Axles only with this many caravans (0 = any).
@export var hire_outriders := true           ## 10f: Outriders after a robbery.
@export var hire_sweep := false              ## 10f (hard): Sweep when Magpies lurk on an unguarded spot.
@export var gold_revive := true              ## 10h: revive a fallen champion in gold when essence is short.
@export var gold_hire := false               ## 10h (hard): pay a hire's crystal part in gold.
@export var gold_exchange_above := 450       ## 10i: gold above this is exchanged in steps of 100.
## Champion bounty rules of market-trade.md 7 this profile uses (B5 Escort far caravans, B6 Hunt looters,
## B7 Guard a raided forward hall).
@export var trade_flags := PackedStringArray(["B5"])
## 12.A1: map fill (map-fill.md 7, rules 11-13, AIMapFill). Defaults = normal; easy() / hard() and the .tres set their
## own. Every rule is a no-op while its system (river, points, camps, beasts) is absent.
@export var map_fill := true                 ## False: rules 11-13 off (missions).
@export var creep_start := 120.0             ## 11a: no creep before this match time.
@export var creep_ratio := 1.5               ## 11a: creep when own_strength >= this x the camp's strength.
@export var creep_tiers := PackedInt32Array([1, 2, 3])   ## 11a: camp tiers the bot creeps.
@export var creep_hollow := false            ## 11a (hard): also the contested Gloomcap hollow (own bank).
@export var creep_pickup := true             ## 11b: the wizard picks up drops within 12 m after a creep.
@export var capture_squad := 2               ## 12a: soldiers per capture squad (0 = the wizard, on its path).
@export var steal_points_ratio := 1.5        ## 12a: enemy-bank points when own_strength >= this x max(seen, 250) (0 = never).
@export var shrine_lead := 0.0               ## 12c: stand in the own shrine this many seconds before it wakes.
@export var shrine_contest := true           ## 12c: an awake enemy-bank shrine becomes rule 7's first target row.
@export var beast_ratio := 1.4               ## 11e: creep an epic beast when own_strength >= this x its strength (0 = never).
@export var beast_far := false               ## 11e (hard): also the Grizzlemaw across the road bridge.
@export var beast_hunt_stake := 100          ## B11: Hunt stake on a beast the army goes for.
@export var hunt_deer := false               ## 11d (hard): a returning squad's ranged unit may shoot a deer within 10 m.
@export var attack_reroute := false          ## 13b (hard): attacks avoid a held enemy Crown Bridge.
## Champion bounty rules of map-fill.md 7 this profile uses (B8 Claim own-bank towers, B9 Hunt the stag / hollow
## creature, B10 Guard a threatened well, B11 Hunt the beast the army goes for).
@export var mapfill_flags := PackedStringArray(["B8", "B10", "B11"])

const PROFILE_IDS: Array[StringName] = [&"shadow_default", &"ice_default", &"nature_default", &"mission_01"]
const DATA_PATH := "res://data/ai/%s.tres"
const DIFFICULTY_NAMES: Array[String] = ["easy", "normal", "hard"]


## The profile `id` at `difficulty` (0 easy, 1 normal, 2 hard): `data/ai/<kingdom>_<difficulty>.tres`
## (or `data/ai/<id>.tres`) when it exists, else built in code. Unknown ids = shadow_default.
static func for_id(id: StringName, difficulty: int) -> AIProfile:
	var d := DIFFICULTY_NAMES[clampi(difficulty, 0, 2)]
	var paths: Array[String] = [DATA_PATH % String(id)]
	if String(id).ends_with("_default"):
		paths.push_front(DATA_PATH % (String(id).trim_suffix("_default") + "_" + d))
	for path in paths:
		if ResourceLoader.exists(path):
			var p := load(path) as AIProfile
			if p:
				return p.duplicate() as AIProfile
	match id:
		&"ice_default":
			return ice(difficulty)
		&"nature_default":
			return nature(difficulty)
		&"mission_01":
			return mission_01()
		&"mission_04":
			return mission_04()
	return for_difficulty(difficulty)


## The default profile id of a kingdom (`&"ice"` -> `&"ice_default"`, `&"nature"` -> `&"nature_default"`);
## Fire / Shadow / unknown: shadow_default (ai.md: Fire plays the Shadow bot on the mirrored slots).
static func id_for_faction(faction: StringName) -> StringName:
	match faction:
		&"ice":
			return &"ice_default"
		&"nature":
			return &"nature_default"
	return &"shadow_default"


## kingdom-nature.md section 6 + balance-2 2a: the difficulty preset + attack_ratio -0.1, one more home worker
## (normal 7 / 9 / 12), Grove Hall at 0:00 with 3 Spriglings queued, X1 at 4:30, Nature mix, Bramblehorn from 200
## crystals and 6 soldier pop, retreat at 50 % and re-attack at 85 % average HP (or 45 s at the rally), a Thornling
## scouts from 1:30 (no worker scout), Wild Bloom before the wizard's retreat, Ysolde's items (section 5).
static func nature(difficulty: int) -> AIProfile:
	var p := for_difficulty(difficulty)
	p.profile_id = &"nature_default"
	p.id = StringName("nature_" + DIFFICULTY_NAMES[clampi(difficulty, 0, 2)])
	p.attack_ratio -= 0.1
	p.worker_target_home += 1   # balance-2 2a: only the home count; expanded / X2 = every kingdom's
	p.opening_workers = 3
	p.expand_time = 270.0
	# Thornling / Burr Slinger / Bloomtender / Bramblehorn (Grove Hall card order Z X C V).
	p.mix_default = PackedFloat32Array([0.45, 0.25, 0.15, 0.15])
	p.mix_vs_ranged = PackedFloat32Array([0.55, 0.10, 0.10, 0.25])
	p.mix_vs_melee = PackedFloat32Array([0.30, 0.40, 0.15, 0.15])
	p.heavy_crystals = 200
	p.heavy_soldier_pop = 6
	p.retreat_hp = 0.5
	p.regrow_hp = 0.85
	p.regrow_wait = 45.0   # balance-2 2a
	p.first_scout_time = 90.0
	p.scout_worker_before = 0.0
	p.scout_fast = true
	p.retreat_spell = &"wild_bloom"
	var normal_items := PackedStringArray(["verdant_seed", "duskglass", "bloomcaller_staff", "ember_draught",
			"bone_charm", "ironbark_plate", "warlords_horn", "heart_of_the_grove", "swiftsoles", "wisp_lantern",
			"ashen_greaves"])
	match difficulty:
		0:
			p.item_build = normal_items.slice(0, 4)
		2:
			var hard_items := normal_items.duplicate()
			hard_items.insert(hard_items.find("heart_of_the_grove") + 1, "ember_draught")
			p.item_build = hard_items
		_:
			p.item_build = normal_items
	return p


## kingdom-ice.md section 7 + balance-2 2b: the difficulty preset + attack_ratio +0.2, min_attack_pop +2, defend
## 32 m, retreat 40 %, S1 3:30, S2 7:00, X1 5:30 or home nodes < half, Ice mix, walls on hard, Torvald's items.
static func ice(difficulty: int) -> AIProfile:
	var p := for_difficulty(difficulty)
	p.profile_id = &"ice_default"
	p.id = StringName("ice_" + DIFFICULTY_NAMES[clampi(difficulty, 0, 2)])
	p.attack_ratio += 0.1 if difficulty == 1 else 0.2   # balance-2 section 5 (8.B4): normal 1.5 -> 1.4
	p.min_attack_pop += 2
	p.defend_radius = 32.0
	p.retreat_hp = 0.4        # balance-2 2b (was 0.3)
	p.tower1_time = 210.0
	p.tower2_time = 420.0
	p.expand_time = 330.0     # balance-2 2b: X1 at 5:30 (was 7:00)...
	p.expand_home_below = 0   # ...or home nodes under half of the start (the stale 700 is gone)
	p.build_walls = difficulty >= 2
	p.extra_halls = 2 if difficulty >= 1 else 0   # 2026-10-09: turn a floating bank into more Frost Halls
	# Rimeshield / Shardcaster / Rime Seer / Rime Colossus (Frost Hall card order Z X C V).
	p.mix_default = PackedFloat32Array([0.40, 0.30, 0.10, 0.20])
	p.mix_vs_ranged = PackedFloat32Array([0.50, 0.20, 0.10, 0.20])
	p.mix_vs_melee = PackedFloat32Array([0.30, 0.40, 0.15, 0.15])
	p.scout_worker_before = 90.0
	p.scout_fast = false
	p.retreat_spell = &"rime_aegis"
	var normal_items := PackedStringArray(["frostglass_shard", "ironbark_plate", "rimebound_bracers",
			"ember_draught", "frostglass_shard", "mana_thread", "glacier_heart", "bone_charm", "ironbark_plate",
			"warlords_horn", "winterwall_aegis"])
	match difficulty:
		0:
			p.item_build = normal_items.slice(0, 5)
		2:
			var hard_items := normal_items.duplicate()
			hard_items.insert(hard_items.find("glacier_heart") + 1, "ember_draught")
			p.item_build = hard_items
		_:
			p.item_build = normal_items
	return p


## mission-01.md "The bot": the easy knobs, never attacks, 4 workers, no expansion, no tower beyond S1,
## at most 8 soldiers at the rally, never rebuilds a building that fell (the Gloom Hall), Malrik stays home.
static func mission_01() -> AIProfile:
	var p := easy()
	p.profile_id = &"mission_01"
	p.id = &"mission_01"
	p.min_attack_pop = 99
	p.attack_full_pop = 0      # 20.A3: never attacks anyway (launch_attacks false)
	p.first_attack_by = 0.0
	p.launch_attacks = false
	p.worker_target_home = 4
	p.worker_target_expanded = 4
	p.worker_target_x2 = 4
	p.second_expansion = false
	p.max_soldiers = 8
	p.build_rows = PackedStringArray(["H1", "V1", "S1", "V2"])
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = MalrikJoins.NEVER
	p.champion_max = 0   # mission 1 has no taverns (champions.md 11)
	p.trade = false      # no trade in missions 1-3 (market-trade.md 10)
	p.map_fill = false   # missions: no river, points or camps (map-fill.md 11)
	return p


## docs/design/mission-04.md 19.A1: Shadow normal knobs, the first attack at ~6:00 (min_attack_pop 14), 6 workers, no
## expansion past X1, at most 20 soldiers, the Gloom Hall never rebuilt, Malrik with every attack. Mission04 itself
## overrides the army for the pylon strike (group "scripted") and sets min_attack_pop 99 / launch_attacks false for the
## phase-3 pull-back.
static func mission_04() -> AIProfile:
	var p := normal()
	p.profile_id = &"mission_04"
	p.id = &"mission_04"
	p.min_attack_pop = 14
	p.attack_full_pop = 18
	p.first_attack_by = 360.0
	p.worker_target_home = 6
	p.worker_target_expanded = 6
	p.worker_target_x2 = 6
	p.second_expansion = false
	p.max_soldiers = 20
	p.rebuild = false
	p.malrik_joins = MalrikJoins.EVERY_ATTACK
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	return p


## map-fill.md 7: the map-fill knobs of a difficulty (0 easy, 1 normal, 2 hard).
static func apply_mapfill_knobs(p: AIProfile, difficulty: int) -> void:
	p.map_fill = true
	match difficulty:
		0:
			p.creep_start = 240.0
			p.creep_ratio = 2.0
			p.creep_tiers = PackedInt32Array([1])
			p.creep_hollow = false
			p.creep_pickup = false
			p.capture_squad = 0
			p.steal_points_ratio = 0.0
			p.shrine_lead = 0.0
			p.shrine_contest = false
			p.beast_ratio = 0.0
			p.beast_far = false
			p.beast_hunt_stake = 100
			p.hunt_deer = false
			p.attack_reroute = false
			p.mapfill_flags = PackedStringArray()
		2:
			p.creep_start = 90.0
			p.creep_ratio = 1.3
			p.creep_tiers = PackedInt32Array([1, 2, 3])
			p.creep_hollow = true
			p.creep_pickup = true
			p.capture_squad = 3
			p.steal_points_ratio = 1.2
			p.shrine_lead = 15.0
			p.shrine_contest = true
			p.beast_ratio = 1.2
			p.beast_far = true
			p.beast_hunt_stake = 150
			p.hunt_deer = true
			p.attack_reroute = true
			p.mapfill_flags = PackedStringArray(["B8", "B9", "B10", "B11"])
		_:
			p.creep_start = 120.0
			p.creep_ratio = 1.5
			p.creep_tiers = PackedInt32Array([1, 2, 3])
			p.creep_hollow = false
			p.creep_pickup = true
			p.capture_squad = 2
			p.steal_points_ratio = 1.5
			p.shrine_lead = 0.0
			p.shrine_contest = true
			p.beast_ratio = 1.4
			p.beast_far = false
			p.beast_hunt_stake = 100
			p.hunt_deer = false
			p.attack_reroute = false
			p.mapfill_flags = PackedStringArray(["B8", "B10", "B11"])


## market-trade.md 7: the trade knobs of a difficulty (0 easy, 1 normal, 2 hard).
static func apply_trade_knobs(p: AIProfile, difficulty: int) -> void:
	p.trade = true
	match difficulty:
		0:
			p.trade_start = 480.0
			p.caravan_target = 2
			p.caravan_target_late = 3
			p.far_route_caravans = 0
			p.far_route_ratio = 0.0
			p.ware_order = PackedStringArray(["masons_charter"])
			p.axles_min_caravans = 0
			p.hire_outriders = false
			p.hire_sweep = false
			p.gold_revive = false
			p.gold_hire = false
			p.gold_exchange_above = 200
			p.trade_flags = PackedStringArray()
		2:
			p.trade_start = 270.0
			p.caravan_target = 6
			p.caravan_target_late = 6
			p.far_route_caravans = 3
			p.far_route_ratio = 1.2
			p.ware_order = PackedStringArray(["tempered_steel", "iron_axles", "gambesons", "masons_charter"])
			p.axles_min_caravans = 0
			p.hire_outriders = true
			p.hire_sweep = true
			p.gold_revive = true
			p.gold_hire = true
			p.gold_exchange_above = 600
			p.trade_flags = PackedStringArray(["B5", "B6", "B7"])
		_:
			p.trade_start = 330.0
			p.caravan_target = 4
			p.caravan_target_late = 6
			p.far_route_caravans = 2
			p.far_route_ratio = 1.5
			p.ware_order = PackedStringArray(["iron_axles", "masons_charter", "tempered_steel", "gambesons"])
			p.axles_min_caravans = 3
			p.hire_outriders = true
			p.hire_sweep = false
			p.gold_revive = true
			p.gold_hire = false
			p.gold_exchange_above = 450
			p.trade_flags = PackedStringArray(["B5"])


## champions.md 10: the champion knobs of a difficulty (0 easy, 1 normal, 2 hard).
static func apply_champion_knobs(p: AIProfile, difficulty: int) -> void:
	match difficulty:
		0:
			p.champion_max = 1
			p.champion_order = PackedStringArray(["oathwall"])
			p.champion_earliest = 360.0
			p.revive_before_items = false
			p.bounty_budget_pct = 1.0     # "Guard flags only": one Guard 50 from the essence above the next item
			p.bounty_max_flags = 1
			p.bounty_guard_only = true
			p.explore_unseen = 120.0
		2:
			p.champion_max = 3
			p.champion_order = PackedStringArray(["coin_cutter", "mender", "wayfinder"])
			p.champion_earliest = 120.0
			p.revive_before_items = true
			p.bounty_budget_pct = 0.4
			p.bounty_max_flags = 3
			p.bounty_guard_only = false
			p.explore_unseen = 90.0
		_:
			p.champion_max = 2
			p.champion_order = PackedStringArray(["coin_cutter", "oathwall"])
			p.champion_earliest = 180.0
			p.revive_before_items = true
			p.bounty_budget_pct = 0.25
			p.bounty_max_flags = 2
			p.bounty_guard_only = false
			p.explore_unseen = 120.0


static func easy() -> AIProfile:
	var p := AIProfile.new()
	p.id = &"easy"
	p.decision_interval = 2.0
	p.reaction_delay = 4.0
	p.build_delay = 15.0
	p.worker_target_home = 4
	p.worker_target_expanded = 6
	p.worker_target_x2 = 6
	p.second_expansion = false
	p.queue_depth = 1
	p.attack_ratio = 1.8
	p.min_attack_pop = 8
	p.attack_ratio_floor = 1.2
	p.attack_patience = 180.0
	p.attack_full_pop = 24
	p.first_attack_by = 900.0
	p.memory_seconds = 60.0
	p.scout_interval = 240.0
	p.malrik_joins = MalrikJoins.NEVER
	p.spell_order = PackedStringArray(["F2", "F3", "Q1", "Q2", "Q3", "E1", "E2"])
	p.item_build = PackedStringArray(["wisp_lantern", "ironbark_plate", "nightveil_cloak", "bone_charm",
			"ember_shard", "grave_pact", "ember_draught", "ironbark_plate"])
	apply_champion_knobs(p, 0)
	apply_trade_knobs(p, 0)
	apply_mapfill_knobs(p, 0)
	return p


static func normal() -> AIProfile:
	return AIProfile.new()


static func hard() -> AIProfile:
	var p := AIProfile.new()
	p.id = &"hard"
	p.decision_interval = 0.5
	p.reaction_delay = 0.5
	p.build_delay = 0.0
	p.attack_ratio = 1.1
	p.min_attack_pop = 5
	p.attack_ratio_floor = 0.7
	p.attack_patience = 60.0
	p.attack_full_pop = 16
	p.first_attack_by = 480.0
	p.memory_seconds = 180.0
	p.scout_interval = 90.0
	p.malrik_joins = MalrikJoins.EVERY_ATTACK
	p.no_reserve_at_cap = true
	p.spell_order = PackedStringArray(["Q1", "F2", "E1", "Q2", "F3", "Q3", "E2"])
	p.item_build = PackedStringArray(["ember_shard", "whetted_fang", "blazing_edge", "ember_draught",
			"bone_charm", "ember_shard", "grave_pact", "inferno_blade", "ironbark_plate", "wisp_lantern",
			"nightveil_cloak", "swiftsoles", "wisp_lantern", "ashen_greaves", "shadowstride", "ember_draught"])
	p.potion_stock = 2
	apply_champion_knobs(p, 2)
	apply_trade_knobs(p, 2)
	apply_mapfill_knobs(p, 2)
	return p


## 0 = easy, 1 = normal, 2 = hard (Commander.Difficulty).
static func for_difficulty(difficulty: int) -> AIProfile:
	match difficulty:
		0:
			return easy()
		2:
			return hard()
	return normal()
