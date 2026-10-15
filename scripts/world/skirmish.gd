class_name Skirmish
extends "res://scripts/world/main.gd"
## The 1v1 match on "Crown Hollow": the player's kingdom (`player_kingdom`, default Fire / Vessa) vs the
## bot's (`enemy_kingdom`, default Shadow / Malrik); any of Fire, Shadow, Ice, Nature on each side, mirror
## allowed (kingdom-nature.md 8.S2). The player always starts on the south-west side (PLAYER_START), the bot
## on the north-east (SHADOW_START); the map and its node ids (node_fire_* / node_shadow_*) are per SIDE,
## not per kingdom. Source of truth:
## docs/design/skirmish-1v1.md. Reuses main.gd (world building, camera, HUD, make_unit / _spawn) and
## overrides its map, start state and win / lose rules:
## - point-mirrored map (keeps, 8 crystal nodes, trees, rocks, pillars), the Ember Crown (EmberCrown)
##   and 4 neutral Ruin Wardens in the centre;
## - a side with no living building loses (checked every 0.5 s; both at once = the player loses);
##   F10 twice within 3 s surrenders; surrender(team) for the bot;
## - a dead wizard respawns at its keep after 30 s + 15 s per earlier death (max 90 s);
##   wizards heal 1 % max HP / s within 15 m of their own keep;
## - match timer and end-screen stats;
## - champions (docs/design/champions.md 2-3): two neutral taverns (TAVERN_SPOTS, clearing 6, explored for
##   both teams from 0:00, open at 2:00) and one ChampionGuild per team (`guild_of(team)`);
## - trade (docs/design/market-trade.md 2, `trade_enabled`): the ring road (ROAD_NODES / ROAD_SEGMENTS, 2.5 m
##   corridors cleared after the rng draws, painted on the ground), 4 neutral TradePosts, 2 Magpie Dens and
##   2 Greywater Lodges (GuildHouse), all explored for both teams from 0:00; the TradeNetwork (posts open at
##   4:00 with a message); one GoldBank per team and the ThievesGuild / HuntersGuild services (each loaded only
##   if its script exists); bot slots M1 (market_slot) and S3 / S4 (tower_slot); the end-screen gold line.
## - map fill (docs/design/map-fill.md, step 12; flags `river_enabled`, `points_enabled`, `camps_enabled`,
##   `beasts_enabled`): the river Hollowmere (RiverSystem under the NavigationRegion3D before the bake: carve, water,
##   bridges, fords; the ground cut through EnvProps.set_river), its corridors (no tree / rock within 1.2 m of deep
##   water or 2 m of a crossing, after the rng draws), willows (seed 17) and two Old Wood clusters (seed 13) per bank,
##   the landmarks (colliders before the bake), moved Lost Caches and crown drops, and the step-12 services created
##   by path (load-guarded): CapturePoints (before the bake, its points under the NavigationRegion3D), CampManager,
##   EpicBeasts, CritterHerds (after the bake); points and landmarks explored for both teams from 0:00; the
##   end-screen map-fill line. `river_enabled = false` (and points / camps off) = the step-11 map, same forest.
## Public helpers for the bot (scripts/ai/) and the UI: see docs/handoff/for-ai-coder.md.

signal match_ended(winner_team: int)
signal wizard_fell(wizard: Wizard, respawn_in: float)
signal wizard_respawned(wizard: Wizard)

const SHADOW_START := Vector3(36.0, 0.0, -36.0)
const KEEP_OFFSET := Vector3(-7.0, 0.0, 7.0)          ## Fire keep = PLAYER_START + this; Shadow: mirror.
const NATURAL_HALL_SPOT := Vector3(-23.0, 0.0, 9.0)    ## Fire's forward hall by node_fire_mid; Shadow: mirror.
## Hearth / Hovel slot V1 of ai.md (Fire side; Shadow: (50, -46)): kept free of rocks and trees.
const HOUSE_SLOT := Vector3(-50.0, 0.0, 46.0)
## Fire's forward hall by the contested node_fire_rich (9.9 m from it); Shadow: mirror (balance-1).
const RICH_HALL_SPOT := Vector3(-33.0, 0.0, -33.0)
## Crystals per node, by the suffix after node_fire_ / node_shadow_ (docs/design/balance-1.md 2a).
const NODE_AMOUNTS := {&"a": 2000, &"b": 2000, &"mid": 2500, &"rich": 2500}
## Fire side nodes; each is mirrored to (-x, -z) as node_shadow_<suffix>. "rich" is contested
## (~83 m from both keeps).
const FIRE_NODES := {
	&"node_fire_a": Vector3(-46.0, 0.0, 34.0),
	&"node_fire_b": Vector3(-34.0, 0.0, 46.0),
	&"node_fire_mid": Vector3(-16.0, 0.0, 6.0),
	&"node_fire_rich": Vector3(-40.0, 0.0, -40.0),
}
const RICH_CLEARING := 7.0
const RICH_HALL_CLEARING := 5.0
const WARDEN_TYPE := "ruin_warden"
const WARDEN_COUNT := 4
const WARDEN_RING := 4.0
const PILLAR_RING := 8.0
const PILLAR_GAP := 4            ## Pillar i = 4 (facing Fire) and its mirror i = 9 are left out.

## Items on the map (docs/design/items.md "Where items come from").
const PEDDLER_SPOTS: Array[Vector3] = [Vector3(-22.0, 0.0, -22.0), Vector3(22.0, 0.0, 22.0)]
const PEDDLER_CLEARING := 5.0
## With the river (map-fill.md 2.3): [1] / [3] moved from (0, 30) / (0, -30), 9.4 m from the ford nests.
const CACHE_SPOTS: Array[Vector3] = [Vector3(-30.0, 0.0, 0.0), Vector3(-6.0, 0.0, 27.0),
		Vector3(30.0, 0.0, 0.0), Vector3(6.0, 0.0, -27.0)]
## Without the river (river_enabled false): the step-4 spots.
const CACHE_SPOTS_NO_RIVER: Array[Vector3] = [Vector3(-30.0, 0.0, 0.0), Vector3(0.0, 0.0, 30.0),
		Vector3(30.0, 0.0, 0.0), Vector3(0.0, 0.0, -30.0)]
const CACHE_CLEARING := 3.0
## Where the 4th warden's drops lie, one per CAMP_DROP_ITEMS entry (map-fill.md 2.3 fairness fix: Warden Scale at
## (2, 2), Ember Draught at (-2, -2); they were both near (0, 3)).
const CAMP_DROP_SPOTS: Array[Vector3] = [Vector3(2.0, 0.0, 2.0), Vector3(-2.0, 0.0, -2.0)]
const CAMP_DROP_POS := Vector3.ZERO   ## The centre of CAMP_DROP_SPOTS (kept for callers).
const CAMP_DROP_ITEMS: Array[StringName] = [&"warden_scale", &"ember_draught"]

## Champions (docs/design/champions.md section 2): the two neutral taverns, mirrored on the neutral diagonal.
const TAVERN_SPOTS: Array[Vector3] = [Vector3(-15.0, 0.0, -15.0), Vector3(15.0, 0.0, 15.0)]
const TAVERN_CLEARING := 6.0
const TAVERN_REVEAL := 6.0       ## Both taverns are explored for both teams from 0:00.

## Trade (docs/design/market-trade.md 2). Everything is point-mirrored: (x, z) on the player's side, (-x, -z) on
## the enemy's. Road nodes whose id starts with "hub" are the base hubs (TradeNetwork).
const ROAD_NODES := {
	&"hub": Vector3(-36.0, 0.0, 36.0), &"w_door": Vector3(-49.0, 0.0, 1.0), &"nw1": Vector3(-48.0, 0.0, -44.0),
	&"nw2": Vector3(-44.0, 0.0, -48.0), &"s_door": Vector3(-1.0, 0.0, 49.0),
	&"hub_e": Vector3(36.0, 0.0, -36.0), &"e_door": Vector3(49.0, 0.0, -1.0), &"se1": Vector3(48.0, 0.0, 44.0),
	&"se2": Vector3(44.0, 0.0, 48.0), &"n_door": Vector3(1.0, 0.0, -49.0),
}
## The ring: hub, w_door, nw1, nw2, n_door, hub_e, e_door, se1, se2, s_door, back to hub.
const ROAD_SEGMENTS := [[&"hub", &"w_door"], [&"w_door", &"nw1"], [&"nw1", &"nw2"], [&"nw2", &"n_door"],
		[&"n_door", &"hub_e"], [&"hub_e", &"e_door"], [&"e_door", &"se1"], [&"se1", &"se2"], [&"se2", &"s_door"],
		[&"s_door", &"hub"]]
## The 4 trading posts (2.2): id, name, centre, door (on the road node), model sign.
const POST_SPOTS: Array[Dictionary] = [
	{"id": &"heron_ford", "name": "Heron Ford", "center": Vector3(-53.0, 0.0, 1.0), "door": Vector3(-49.0, 0.0, 1.0), "sign": 0},
	{"id": &"millstone_cross", "name": "Millstone Cross", "center": Vector3(-1.0, 0.0, 53.0), "door": Vector3(-1.0, 0.0, 49.0), "sign": 1},
	{"id": &"lantern_wharf", "name": "Lantern Wharf", "center": Vector3(53.0, 0.0, -1.0), "door": Vector3(49.0, 0.0, -1.0), "sign": 2},
	{"id": &"saltgate", "name": "Saltgate", "center": Vector3(1.0, 0.0, -53.0), "door": Vector3(1.0, 0.0, -49.0), "sign": 3},
]
## The guild houses (2.3): north-west corner first, then its south-east mirror.
const DEN_SPOTS: Array[Dictionary] = [
	{"center": Vector3(-55.0, 0.0, -45.0), "door": Vector3(-51.0, 0.0, -45.0)},
	{"center": Vector3(55.0, 0.0, 45.0), "door": Vector3(51.0, 0.0, 45.0)},
]
const LODGE_SPOTS: Array[Dictionary] = [
	{"center": Vector3(-45.0, 0.0, -55.0), "door": Vector3(-45.0, 0.0, -51.0)},
	{"center": Vector3(45.0, 0.0, 55.0), "door": Vector3(45.0, 0.0, 51.0)},
]
## Magpie ambush spots on the roads (2.4) and beside the remote nodes (W1: naturals, W2: rich nodes).
const AMBUSH_SPOTS := {
	&"A1": Vector3(-44.0, 0.0, 15.0), &"A2": Vector3(-15.0, 0.0, 44.0), &"A3": Vector3(-48.0, 0.0, -22.0),
	&"A4": Vector3(-22.0, 0.0, -48.0), &"A1m": Vector3(44.0, 0.0, -15.0), &"A2m": Vector3(15.0, 0.0, -44.0),
	&"A3m": Vector3(48.0, 0.0, 22.0), &"A4m": Vector3(22.0, 0.0, 48.0),
}
const WORKER_SPOTS := {
	&"W1": Vector3(-8.0, 0.0, 16.0), &"W2": Vector3(-50.0, 0.0, -30.0),
	&"W1m": Vector3(8.0, 0.0, -16.0), &"W2m": Vector3(50.0, 0.0, 30.0),
}
## Bot slot M1 for the Bazaar (4.1) and the Spire slots S3 (natural) / S4 (rich) of the bot's rule 10e; player side.
const MARKET_SLOT := Vector3(-45.0, 0.0, 27.0)
const TOWER_SLOTS := {&"natural": Vector3(-19.0, 0.0, 1.0), &"rich": Vector3(-37.0, 0.0, -45.0)}
const POST_CLEARING := 5.0
const GUILD_CLEARING := 6.0
const ROAD_CORRIDOR := 2.5       ## No tree / rock this close to a road segment (collider edge).
const LANDMARK_REVEAL := 6.0     ## Posts and guild houses are explored for both teams from 0:00.
const MSG_POSTS_OPEN := "The trading posts open their gates"
const HINT_BAZAAR := "Build a Bazaar (B then B with a worker) to send caravans"
## Other step-10 parts, loaded only when their script exists (market-trade.md 12).
const GOLD_BANK_PATH := "res://scripts/economy/gold_bank.gd"
const THIEVES_GUILD_PATH := "res://scripts/world/thieves_guild.gd"
const HUNTERS_GUILD_PATH := "res://scripts/world/hunters_guild.gd"

## Map fill (docs/design/map-fill.md, step 12). Point-mirrored like the rest: (x, z) on the player's (west) bank,
## (-x, -z) on the enemy's. The river centre line N0-N5 (N0 2 m outside the map, N5 on the moat centre line), in
## downstream order; the south river is its point mirror, flowing S5 -> S0 (river_polylines()).
const RIVER_POLYLINE_N: Array[Vector2] = [Vector2(-15.0, -62.0), Vector2(-12.0, -48.7), Vector2(-9.0, -38.0),
		Vector2(-8.0, -30.0), Vector2(-5.0, -21.0), Vector2(-2.5, -12.5)]
const RIVER_HALF_WIDTH := 2.5
## The Crown Isle moat: centre x, centre z, centre-line radius, half width (water from r 11.0 to r 14.5).
const MOAT := Vector4(0.0, 0.0, 12.75, 1.75)
## The 8 crossings (2.2), RiverSystem shape: bridges are rectangles (`length` along `dir`, `width` across), fords and
## Crown Steps circles of radius width / 2. Ford `dir` = the downstream flow (north -> south in both rivers).
const CROSSINGS: Array[Dictionary] = [
	{"id": &"bridge_road_n", "name": "Saltgate Bridge", "kind": &"bridge_road", "center": Vector3(-12.0, 0.0, -48.7),
		"width": 6.0, "length": 9.0, "dir": Vector3(45.0, 0.0, -1.0)},
	{"id": &"bridge_road_s", "name": "Millstone Bridge", "kind": &"bridge_road", "center": Vector3(12.0, 0.0, 48.7),
		"width": 6.0, "length": 9.0, "dir": Vector3(-45.0, 0.0, 1.0)},
	{"id": &"ford_n", "name": "Reed Ford", "kind": &"ford", "center": Vector3(-8.5, 0.0, -34.0),
		"width": 7.0, "length": 7.0, "dir": Vector3(1.0, 0.0, 8.0)},
	{"id": &"ford_s", "name": "Willow Ford", "kind": &"ford", "center": Vector3(8.5, 0.0, 34.0),
		"width": 7.0, "length": 7.0, "dir": Vector3(1.0, 0.0, 8.0)},
	{"id": &"bridge_crown_w", "name": "West Crown Bridge", "kind": &"bridge_lane", "center": Vector3(-9.02, 0.0, 9.02),
		"width": 8.0, "length": 6.5, "dir": Vector3(-1.0, 0.0, 1.0)},
	{"id": &"bridge_crown_e", "name": "East Crown Bridge", "kind": &"bridge_lane", "center": Vector3(9.02, 0.0, -9.02),
		"width": 8.0, "length": 6.5, "dir": Vector3(1.0, 0.0, -1.0)},
	{"id": &"steps_nw", "name": "North-west Crown Steps", "kind": &"steps", "center": Vector3(-9.02, 0.0, -9.02),
		"width": 6.0, "length": 6.0, "dir": Vector3(-1.0, 0.0, -1.0)},
	{"id": &"steps_se", "name": "South-east Crown Steps", "kind": &"steps", "center": Vector3(9.02, 0.0, 9.02),
		"width": 6.0, "length": 6.0, "dir": Vector3(1.0, 0.0, 1.0)},
]
## The 8 capturable points (4.1), CapturePoints.setup shape {id, name, kind, pos}.
const POINT_SPOTS: Array[Dictionary] = [
	{"id": &"tower_nw", "name": "Rookwatch", "kind": &"watchtower", "pos": Vector3(-24.0, 0.0, -41.0)},
	{"id": &"tower_se", "name": "Owlwatch", "kind": &"watchtower", "pos": Vector3(24.0, 0.0, 41.0)},
	{"id": &"tower_s", "name": "Millwatch", "kind": &"watchtower", "pos": Vector3(-6.0, 0.0, 40.0)},
	{"id": &"tower_n", "name": "Saltwatch", "kind": &"watchtower", "pos": Vector3(6.0, 0.0, -40.0)},
	{"id": &"well_w", "name": "Mossmere Well", "kind": &"well", "pos": Vector3(-30.0, 0.0, -24.0)},
	{"id": &"well_e", "name": "Stonemere Well", "kind": &"well", "pos": Vector3(30.0, 0.0, 24.0)},
	{"id": &"shrine_w", "name": "West Wayshrine", "kind": &"shrine", "pos": Vector3(-22.0, 0.0, -6.0)},
	{"id": &"shrine_e", "name": "East Wayshrine", "kind": &"shrine", "pos": Vector3(22.0, 0.0, 6.0)},
]
## Tree / rock clearing per point kind (4.2), checked after the rng draws.
const POINT_CLEARING := {&"watchtower": 4.0, &"well": 3.5, &"shrine": 3.0}
## The 8 neutral camps (5.2), CampManager.setup shape {id, name, kind, tier, pos, first_spawn (s)}.
const CAMP_SPOTS: Array[Dictionary] = [
	{"id": &"camp_wallow_s", "name": "Bristleback Wallow", "kind": &"bristleback", "tier": 1,
		"pos": Vector3(-14.0, 0.0, 57.0), "first_spawn": 0.0},
	{"id": &"camp_wallow_n", "name": "Bristleback Wallow", "kind": &"bristleback", "tier": 1,
		"pos": Vector3(14.0, 0.0, -57.0), "first_spawn": 0.0},
	{"id": &"camp_nest_s", "name": "Willow Ford Nest", "kind": &"mirefang", "tier": 2,
		"pos": Vector3(8.5, 0.0, 34.0), "first_spawn": 0.0},
	{"id": &"camp_nest_n", "name": "Reed Ford Nest", "kind": &"mirefang", "tier": 2,
		"pos": Vector3(-8.5, 0.0, -34.0), "first_spawn": 0.0},
	{"id": &"camp_hollow_nw", "name": "Gloomcap Hollow", "kind": &"gloomcap", "tier": 2,
		"pos": Vector3(-55.0, 0.0, -55.0), "first_spawn": 150.0},
	{"id": &"camp_hollow_se", "name": "Gloomcap Hollow", "kind": &"gloomcap", "tier": 2,
		"pos": Vector3(55.0, 0.0, 55.0), "first_spawn": 150.0},
	{"id": &"camp_stag_w", "name": "Stag Glade", "kind": &"hollow_stag", "tier": 3,
		"pos": Vector3(-37.0, 0.0, -10.0), "first_spawn": 210.0},
	{"id": &"camp_stag_e", "name": "Stag Glade", "kind": &"hollow_stag", "tier": 3,
		"pos": Vector3(37.0, 0.0, 10.0), "first_spawn": 210.0},
]
const CAMP_CLEARING := 3.5
## The 8 epic-beast lairs (5.5), EpicBeasts.setup shape {id, name, kind, center, radius, patrol, first_spawn, respawn}.
const LAIR_SPOTS: Array[Dictionary] = [
	{"id": &"lair_heath_w", "name": "West Heath", "kind": &"tusker", "center": Vector3(-53.0, 0.0, 13.0), "radius": 4.0,
		"patrol": [Vector3(-53, 0, 9), Vector3(-57, 0, 13), Vector3(-52, 0, 17), Vector3(-49, 0, 13)],
		"first_spawn": 390.0, "respawn": 600.0},
	{"id": &"lair_heath_e", "name": "East Heath", "kind": &"tusker", "center": Vector3(53.0, 0.0, -13.0), "radius": 4.0,
		"patrol": [Vector3(53, 0, -9), Vector3(57, 0, -13), Vector3(52, 0, -17), Vector3(49, 0, -13)],
		"first_spawn": 390.0, "respawn": 600.0},
	{"id": &"lair_crag_w", "name": "Colossus Crag", "kind": &"roc", "center": Vector3(-53.0, 0.0, -18.0), "radius": 5.0,
		"patrol": [Vector3(-53, 0, -13), Vector3(-48, 0, -18), Vector3(-53, 0, -23), Vector3(-57, 0, -21)],
		"first_spawn": 510.0, "respawn": 600.0},
	{"id": &"lair_crag_e", "name": "Colossus Crag", "kind": &"roc", "center": Vector3(53.0, 0.0, 18.0), "radius": 5.0,
		"patrol": [Vector3(53, 0, 13), Vector3(48, 0, 18), Vector3(53, 0, 23), Vector3(57, 0, 21)],
		"first_spawn": 510.0, "respawn": 600.0},
	{"id": &"lair_hollow_w", "name": "Greymane Hollow", "kind": &"direwolf", "center": Vector3(-56.0, 0.0, -34.0),
		"radius": 4.0, "patrol": [Vector3(-57, 0, -38), Vector3(-56, 0, -30), Vector3(-53, 0, -34)],
		"first_spawn": 450.0, "respawn": 600.0},
	{"id": &"lair_hollow_e", "name": "Greymane Hollow", "kind": &"direwolf", "center": Vector3(56.0, 0.0, 34.0),
		"radius": 4.0, "patrol": [Vector3(57, 0, 38), Vector3(56, 0, 30), Vector3(53, 0, 34)],
		"first_spawn": 450.0, "respawn": 600.0},
	{"id": &"lair_den_w", "name": "Old Wood Den", "kind": &"grizzlemaw", "center": Vector3(-26.0, 0.0, -54.0), "radius": 5.0,
		"patrol": [Vector3(-26, 0, -49), Vector3(-31, 0, -54), Vector3(-26, 0, -59), Vector3(-21, 0, -54)],
		"first_spawn": 600.0, "respawn": 720.0},
	{"id": &"lair_den_e", "name": "Old Wood Den", "kind": &"grizzlemaw", "center": Vector3(26.0, 0.0, 54.0), "radius": 5.0,
		"patrol": [Vector3(26, 0, 49), Vector3(31, 0, 54), Vector3(26, 0, 59), Vector3(21, 0, 54)],
		"first_spawn": 600.0, "respawn": 720.0},
]
## Huntable red deer (3.4): 2 herds of 3, graze spots (north-west herd; the south-east herd = the mirrors), 1 deer per
## herd every 120 s while it has < 3. CritterHerds.setup shape {id, name, spots, count, respawn}.
const DEER_HERDS: Array[Dictionary] = [
	{"id": &"herd_nw", "name": "North-west herd", "count": 3, "respawn": 120.0,
		"spots": [Vector3(-36, 0, -53), Vector3(-52, 0, -36), Vector3(-44, 0, -30), Vector3(-30, 0, -32),
			Vector3(-56, 0, -22), Vector3(-40, 0, -50)]},
	{"id": &"herd_se", "name": "South-east herd", "count": 3, "respawn": 120.0,
		"spots": [Vector3(36, 0, 53), Vector3(52, 0, 36), Vector3(44, 0, 30), Vector3(30, 0, 32),
			Vector3(56, 0, 22), Vector3(40, 0, 50)]},
]
## Rabbit homes (3.4): 6 per half, each rabbit wanders r 6 around its home (player half first, then the mirrors).
const RABBIT_HOMES: Array[Vector3] = [Vector3(-30, 0, 52), Vector3(-52, 0, 22), Vector3(-24, 0, 30),
		Vector3(-40, 0, 8), Vector3(-10, 0, 47), Vector3(-54, 0, -8), Vector3(30, 0, -52), Vector3(52, 0, -22),
		Vector3(24, 0, -30), Vector3(40, 0, -8), Vector3(10, 0, -47), Vector3(54, 0, 8)]
## Landmarks with colliders (3.2), player bank; each gets its point mirror (yaw + PI). `scene` in
## art/environment/landmarks/ (colliders inside, <= 1.8 m); `colliders` = the fallback cylinders [local x, local z, r]
## when the scene is missing; `clear` = no tree / rock within this radius (after the rng draws).
const LANDMARK_SPOTS: Array[Dictionary] = [
	{"id": &"lm_colossus", "scene": "colossus.tscn", "pos": Vector3(-57.0, 0.0, -16.0), "clear": 4.5,
		"colliders": [[1.0, -0.7, 2.2], [-1.0, 1.6, 1.0]]},
	{"id": &"lm_stump", "scene": "giant_stump.tscn", "pos": Vector3(-30.0, 0.0, 20.0), "clear": 4.0,
		"colliders": [[0.0, 0.0, 2.0]]},
	{"id": &"lm_stones", "scene": "standing_stones.tscn", "pos": Vector3(-54.0, 0.0, 20.0), "clear": 4.5,
		"colliders": [[3.0, 0.0, 0.5], [1.5, 2.6, 0.5], [-1.5, 2.6, 0.5], [-1.5, -2.6, 0.5], [1.5, -2.6, 0.5]]},
	{"id": &"lm_aqueduct", "scene": "aqueduct.tscn", "pos": Vector3(-13.4, 0.0, -55.0), "clear": 0.0,
		"colliders": [[-4.1, 0.0, 0.9], [4.1, 0.0, 0.9]]},
	{"id": &"lm_barge", "scene": "barge.tscn", "pos": Vector3(-6.2, 0.0, -24.5), "clear": 0.0, "colliders": []},
]
const LANDMARK_DIR := "res://art/environment/landmarks/"
## Two extra Old Wood tree clusters per bank (2.5 / 3.1): [centre, radius, trees]; mirrored. Drawn from OLD_WOOD_SEED.
const OLD_WOOD_CLUSTERS := [[Vector3(-30.0, 0.0, -56.0), 4.0, 7], [Vector3(-57.0, 0.0, -32.0), 3.5, 6]]
const OLD_WOOD_SEED := 13
## Willows along the banks (12.V7): trunk foot 1.5-4 m from the water, scale 0.95-1.2, mirrored. Drawn from WILLOW_SEED.
const WILLOW_SEED := 17
const WILLOW_DRAWS := 40         ## Candidate draws on the player bank: WILLOW_RIVER_DRAWS along the north river...
const WILLOW_RIVER_DRAWS := 30   ## ...the rest on the moat's outer bank.
const WILLOW_SPACING := 4.0
const WILLOW_CROSSING_GAP := 3.5 ## Willow trunks keep this far from a crossing (their crowns reach ~2.5 m).
const RIVER_CORRIDOR := 1.2      ## No tree / rock collider this close to deep water...
const CROSSING_CORRIDOR := 2.0   ## ...or to a crossing (ford / steps circle, bridge deck).
const MAPFILL_REVEAL := 5.0      ## Points and landmarks are explored for both teams from 0:00.
const WAYSTONE_BRIDGE_GAP := 7.0 ## The waystone row skips this much around each road bridge.
## Step-12 services, each created only if its script exists (map-fill.md 13).
const CAPTURE_POINTS_PATH := "res://scripts/world/capture_points.gd"
const CAMP_MANAGER_PATH := "res://scripts/world/camp_manager.gd"
const EPIC_BEASTS_PATH := "res://scripts/world/epic_beasts.gd"
const CRITTER_HERDS_PATH := "res://scripts/world/critter_herds.gd"
const GROUND_PARAMS_PATH := "res://art/environment/ground_params.gd"

const CHECK_INTERVAL := 0.5
const RESPAWN_BASE := 30.0
const RESPAWN_STEP := 15.0
const RESPAWN_MAX := 90.0
const HOME_HEAL_RADIUS := 15.0
const HOME_HEAL_RATIO := 0.01    ## Of max HP per second.
const SURRENDER_WINDOW := 3.0

## %s = the player's kingdom's barracks name (Ember Hall, ...).
const SKIRMISH_HINT := "Click your Keep to train workers, then B with a worker selected to build %s"
const MALRIK_CONCEDES := "Malrik: \"Keep the crown. I will be back for it.\""

## Per kingdom: its keep, starting worker (used when the keep's `trains` names none), wizard script
## (loaded by path: a script still being written can't break this file), names and messages.
## A kingdom whose keep, worker or wizard script is missing is replaced as a whole by the side's default
## (Fire for the player, Shadow for the bot), with a warning: never a mixed start.
const KINGDOMS := {
	&"fire": {"keep": "fire_keep", "worker": "cinder_hand",
			"wizard": "res://scripts/units/wizard.gd", "name": "Fire", "hero": "Vessa", "pronoun": "She",
			"fallen": "Vessa has fallen, the embers will bring her back"},
	&"shadow": {"keep": "shadow_keep", "worker": "gloom_thrall",
			"wizard": "res://scripts/units/shadow_wizard.gd", "name": "Shadow", "hero": "Malrik", "pronoun": "He",
			"fallen": "Malrik has fallen back into the shadows"},
	&"ice": {"keep": "ice_keep", "worker": "rime_hauler",
			"wizard": "res://scripts/units/ice_wizard.gd", "name": "Ice", "hero": "Torvald", "pronoun": "He",
			"fallen": "Torvald has fallen, the frost will bring him back"},
	&"nature": {"keep": "nature_keep", "worker": "sprigling",
			"wizard": "res://scripts/units/nature_wizard.gd", "name": "Nature", "hero": "Ysolde", "pronoun": "She",
			"fallen": "Ysolde has fallen, the forest will regrow her"},
}
const DEFAULT_PLAYER_KINGDOM := &"fire"
const DEFAULT_ENEMY_KINGDOM := &"shadow"

## The player's kingdom: &"fire" (default), &"shadow", &"ice" or &"nature". Set it before the node
## enters the tree (the menu does it). An unavailable kingdom becomes Fire in _ready (warning).
@export var player_kingdom: StringName = DEFAULT_PLAYER_KINGDOM
## The bot's kingdom: &"shadow" (default), &"fire", &"ice" or &"nature" (the same as the player's is fine).
## Set it before the node enters the tree. An unavailable kingdom becomes Shadow in _ready (warning).
@export var enemy_kingdom: StringName = DEFAULT_ENEMY_KINGDOM
## Taverns + champion guilds on the map (champions.md 2 / 11). True for the skirmish itself; campaign
## missions (scripts extending this one) default to false and turn it on (and call _add_taverns /
## _setup_champions from their own map hooks) when they want champions.
@export var tavern_enabled := true
## Trade and guilds on the map (market-trade.md 2, 10): posts, roads, guild houses, gold, caravans, Magpies,
## hunters. True for the skirmish itself (the settings toggle sets it before the node enters the tree);
## campaign missions (scripts extending this one) default to false. False = the step-9 map, no GoldBank.
@export var trade_enabled := true
## Map fill (map-fill.md 11): the river with its crossings, landmarks, willows and Old Wood clusters. True for the
## skirmish; missions (scripts extending this one) default to false. False = the step-11 map (same forest).
@export var river_enabled := true
## The 8 capturable points (CapturePoints, if its script exists). Skirmish true, missions false.
@export var points_enabled := true
## The 8 neutral camps (CampManager, if its script exists). Skirmish true, missions false.
@export var camps_enabled := true
## The epic beasts (EpicBeasts) and the huntable deer / rabbits (CritterHerds), each if its script exists.
## Skirmish true, missions false.
@export var beasts_enabled := true
## Step 16a: match time limit in seconds (0 = off; the menu's "Time limit" 30 / 45 min, the bot-vs-bot test 1800).
## At the limit the match ends and the higher ScoreKeeper score wins (a tie goes to the enemy, like "both at once").
@export var time_limit_s := 0.0
## Pace "Fast (test)" (A2 of docs/balance/faster_games_2026-10-06.md, PaceSwitch): the menu's Pace row sets it before
## the node enters the tree (off by default; missions never set it). Saved with the match (SaveGame.LEVEL_PROPS).
@export var fast_pace := false
## Pace "Blitz" (docs/balance/blitz_2026-10-10.md, PaceSwitch.BLITZ): more start workers, stronger A2-like values,
## faster keep tiers, earlier bot attacks. Set by the menu before the node enters the tree (off by default; missions
## never set it; wins over fast_pace). Saved with the match (SaveGame.LEVEL_PROPS).
@export var blitz_pace := false
## Keep tiers T1 -> Stronghold -> Citadel (docs/design/tiers.md, TierSystem). Skirmish true, missions false (no
## TierSystem node = nothing is tier-gated).
@export var tiers_enabled := true
var tier_system: TierSystem      ## Null when tiers are off.

## Step 16a: the match's ScoreKeeper (created at match start), or null.
var score_keeper: Node
## True when the match ended at the time limit (decided on score).
var ended_on_score := false
const SCORE_KEEPER_PATH := "res://scripts/world/score_keeper.gd"
const REPLAY_HOOKS_PATH := "res://scripts/core/replay/replay_hooks.gd"

var shadow_keep: Keep            ## The ENEMY team's keep (whatever its kingdom). Name kept for callers.
var shadow_hero: Wizard          ## The ENEMY wizard (whatever its kingdom). Name kept for callers.
var crown: EmberCrown            ## Also `artifact` (the minimap shows it).
var wardens: Array[Unit] = []    ## Living Ruin Wardens (a dead one is removed when it dies).
var wardens_killed := 0          ## The 4th one drops CAMP_DROP_ITEMS at CAMP_DROP_POS (once).
var peddlers: Array[Node] = []   ## The two RuinPeddler shops.
var caches: Array[LostCache] = []
var taverns: Array[Tavern] = []  ## The two neutral taverns (empty when tavern_enabled is false).
var guilds := {}                 ## Unit.Team -> ChampionGuild (PLAYER and ENEMY; empty without taverns).
var trade_network: TradeNetwork  ## Null when trade_enabled is false.
var trade_posts: Array[TradePost] = []
var guild_houses: Array[GuildHouse] = []   ## Dens and Lodges (group "guilds").
var gold_banks := {}             ## Unit.Team -> GoldBank node (empty when trade is off or the script is missing).
var thieves_guild: Node          ## ThievesGuild service (null when trade is off or the script is missing).
var hunters_guild: Node          ## HuntersGuild service (idem).
var river: RiverSystem           ## Null when river_enabled is false.
var capture_points: Node         ## CapturePoints service (null when points are off or the script is missing).
var camp_manager: Node           ## CampManager service (idem, camps).
var epic_beasts: Node            ## EpicBeasts service (idem, beasts).
var critter_herds: Node          ## CritterHerds service (idem, beasts_enabled: the deer and rabbits).
var landmarks: Array[Node3D] = []   ## The landmark roots (scenes, or plain collider bodies without art).
var match_started := false       ## True from the navmesh bake (the timer runs) until...
var winner_team := -1            ## ...the end: the winning Unit.Team, -1 while playing.

var _match_time := 0.0
var _check_left := CHECK_INTERVAL
var _deaths := {}                # team -> wizard deaths so far
var _respawn_left := {}          # team -> seconds until the wizard comes back (absent = alive)
var _surrender_left := 0.0       # > 0: a second F10 now surrenders
var _stats := {}                 # team -> {trained, lost, buildings_lost}
var _taverns_announced := false
var _mapfill_clearings := []     # [Vector3, radius] of points / camps / landmarks (checked after the rng draws)
var _blessings := {}             # team -> Wayshrine blessings received (end screen)
var _camps_cleared := {}         # team -> camps cleared (end screen, when the CampManager has no cleared_count)


func _init() -> void:
	MID_CAMP = Vector3.ZERO
	ARTIFACT_POS = Vector3.ZERO
	# Missions extend Skirmish: no taverns unless they ask (a scene's exported value is applied after this).
	var s := get_script() as Script
	tavern_enabled = s == null or s.resource_path == "res://scripts/world/skirmish.gd"
	trade_enabled = tavern_enabled   # missions: no trade unless they ask (market-trade.md 10)
	river_enabled = tavern_enabled   # missions: no map fill unless they ask (map-fill.md 11)
	points_enabled = tavern_enabled
	camps_enabled = tavern_enabled
	beasts_enabled = tavern_enabled
	tiers_enabled = tavern_enabled


func _ready() -> void:
	# Before main.gd builds anything: every later step reads the checked kingdoms.
	player_kingdom = _resolve_kingdom(player_kingdom, DEFAULT_PLAYER_KINGDOM)
	enemy_kingdom = _resolve_kingdom(enemy_kingdom, DEFAULT_ENEMY_KINGDOM)
	UIStyle.set_kingdom(player_kingdom)   # the HUD skin (GameHUD.setup confirms it from the wizard)
	PaceSwitch.setup(self, fast_pace and not blitz_pace, blitz_pace)   # before any unit or building: edits the types in memory
	if trade_enabled:
		_create_gold_banks()   # before any unit or building: Unit._ready applies the team's wares through them
	if tiers_enabled and TierSystem.ENABLED:   # before any building: the gates read it (tiers.md)
		tier_system = TierSystem.new()
		tier_system.name = "TierSystem"
		tier_system.match_time_source = match_time
		tier_system.pace_time_x = PaceSwitch.tier_time_x(blitz_pace)
		add_child(tier_system)
	super()


# ---------------------------------------------------------------- public helpers (bot, UI, tests)

## Blitz start bank: PaceSwitch.start_crystals_add(kingdom) more crystals per side (nothing outside Blitz).
func _add_pace_start_crystals() -> void:
	if not blitz_pace:
		return
	for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		var extra := PaceSwitch.start_crystals_add(true, kingdom_of(team))
		var eco := Economy.for_team(team)
		if eco and extra != 0:
			eco.add(extra)


## The other kingdom (PLAYER <-> ENEMY).
## 2v2 (scripts/core/teams.gd): the seat's lane opponent (`Teams.opponent_of`); 1v1 unchanged.
static func enemy_team_of(team: int) -> int:
	if Teams.multi:
		return Teams.opponent_of(team)
	return Unit.Team.ENEMY if team == Unit.Team.PLAYER else Unit.Team.PLAYER


## 2v2: seat -> kingdom for the extra seats (ALLY, ENEMY_2), set by the level before the seat plays.
var seat_kingdoms: Dictionary = {}


## The kingdom the team plays (&"fire", &"shadow", &"ice", &"nature"), after the availability check.
func kingdom_of(team: int) -> StringName:
	if seat_kingdoms.has(team):
		return seat_kingdoms[team]
	return enemy_kingdom if team == Unit.Team.ENEMY else player_kingdom


## Unit._team_kingdom reads it (2v2 seats' faction colours).
func seat_kingdom(team: int) -> StringName:
	return kingdom_of(team)


## True when `kingdom` can start a skirmish now: it is known and its keep, a worker and its wizard script exist.
static func kingdom_available(kingdom: StringName) -> bool:
	if not KINGDOMS.has(kingdom):
		return false
	var info: Dictionary = KINGDOMS[kingdom]
	var keep_type := BuildingType.find(String(info["keep"]))
	return keep_type != null and _worker_type_for(kingdom, keep_type) != null \
			and ResourceLoader.exists(String(info["wizard"]))


## Where the team's wizard starts (PLAYER_START / SHADOW_START).
func start_position(team: int) -> Vector3:
	if seat_starts.has(team):
		return seat_starts[team]
	return SHADOW_START if team == Unit.Team.ENEMY else PLAYER_START


## 2v2 seats (scripts/core/teams.gd): the extra seats' keep / wizard / base centre / start, set by the level (a mission's
## activate_seat). The 1v1 PLAYER / ENEMY entries stay `keep` / `shadow_keep` / `hero` / `shadow_hero`.
var seat_keeps: Dictionary = {}
var seat_heroes: Dictionary = {}
var seat_bases: Dictionary = {}
var seat_starts: Dictionary = {}


## The team's living keep, or null.
func keep_of(team: int) -> Keep:
	var k: Keep = null
	if seat_keeps.has(team):
		var v: Variant = seat_keeps[team]
		# (a fallen seat keep is freed: casting it spammed "Trying to cast a freed object" every physics frame, e3m1 2026-10-14)
		k = v as Keep if v != null and is_instance_valid(v) else null
	else:
		k = keep if team == Unit.Team.PLAYER else (null if team > Unit.Team.NEUTRAL else shadow_keep)
	return k if k != null and is_instance_valid(k) and k.is_alive() else null


## The base centre: the keep's position (also after it falls: its start spot).
func base_center(team: int) -> Vector3:
	if seat_bases.has(team):
		return seat_bases[team]
	return _mirror(PLAYER_START + KEEP_OFFSET, team)


## The team's two home nodes (a, b) that still have crystals.
func home_nodes(team: int) -> Array[CrystalNode]:
	var out: Array[CrystalNode] = []
	for suffix in ["a", "b"]:
		var n := node_of(team, suffix)
		if n:
			out.append(n)
	return out


## The team's natural expansion node (node_<side>_mid), or null once it is gone.
func natural_node(team: int) -> CrystalNode:
	return node_of(team, "mid")


## The team's contested rich node (node_<side>_rich), or null once it is gone.
func rich_node(team: int) -> CrystalNode:
	return node_of(team, "rich")


## Where a forward hall fits by the team's rich node (snap / check it first).
func rich_hall_spot(team: int) -> Vector3:
	return _mirror(RICH_HALL_SPOT, team)


## Crystals a node with this suffix ("a", "b", "mid", "rich") starts with.
static func node_amount(suffix: String) -> int:
	return int(NODE_AMOUNTS.get(StringName(suffix), 0))


## A crystal node by side and suffix ("a", "b", "mid", "rich"); null if depleted / gone.
func node_of(team: int, suffix: String) -> CrystalNode:
	var id := StringName("node_%s_%s" % ["shadow" if team == Unit.Team.ENEMY else "fire", suffix])
	var v: Variant = crystal_nodes.get(id)   # may hold a freed node once it ran out
	if v == null or not is_instance_valid(v):
		crystal_nodes.erase(id)
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


## Where the spec puts the forward barracks next to the natural node (snap / check it first).
func natural_hall_spot(team: int) -> Vector3:
	return _mirror(NATURAL_HALL_SPOT, team)


## Bot slot M1 for the team's Bazaar (market-trade.md 4.1): (-45, 27) / enemy (45, -27). Snap / check it first.
func market_slot(team: int) -> Vector3:
	return _mirror(MARKET_SLOT, team)


## The bot's Spire slots of rule 10e (market-trade.md 7): `which` = &"natural" or &"S3" -> (-19, 1),
## &"rich" or &"S4" -> (-37, -45); mirrored for the enemy. Vector3.INF for an unknown slot.
func tower_slot(team: int, which: StringName) -> Vector3:
	var key := which
	if which == &"S3":
		key = &"natural"
	elif which == &"S4":
		key = &"rich"
	if not TOWER_SLOTS.has(key):
		return Vector3.INF
	return _mirror(TOWER_SLOTS[key], team)


## The ring road as one Vector4(a.x, a.z, b.x, b.z) per segment (EnvProps.set_roads: the ground paint).
static func road_param() -> PackedVector4Array:
	var out := PackedVector4Array()
	for seg in ROAD_SEGMENTS:
		var a: Vector3 = ROAD_NODES[seg[0]]
		var b: Vector3 = ROAD_NODES[seg[1]]
		out.append(Vector4(a.x, a.z, b.x, b.z))
	return out


## The river centre lines in downstream order: N0 -> N5 (into the moat) and S5 -> S0 (its point mirror, out).
static func river_polylines() -> Array[PackedVector2Array]:
	var north := PackedVector2Array(RIVER_POLYLINE_N)
	var south := PackedVector2Array()
	for i in range(north.size() - 1, -1, -1):
		south.append(-north[i])
	var out: Array[PackedVector2Array] = [north, south]
	return out


## PLAYER / ENEMY: the bank `pos` is on (the west bank is the player's); -1 in deep water and on the Crown Isle.
## Without the river: the west half (x < 0) is the player's, -1 within 11 m of the centre.
func bank_of(pos: Vector3) -> int:
	if river and is_instance_valid(river):
		return river.bank_of(pos)
	if Vector2(pos.x, pos.z).length() < 11.0:
		return -1
	return Unit.Team.PLAYER if pos.x < 0.0 else Unit.Team.ENEMY


## Where the Lost Caches lie on this map: CACHE_SPOTS with the river, CACHE_SPOTS_NO_RIVER without.
func cache_spots() -> Array[Vector3]:
	return CACHE_SPOTS if river_enabled else CACHE_SPOTS_NO_RIVER


## The team's GoldBank node, or null (trade off, or gold_bank.gd missing).
func gold_bank_of(team: int) -> Node:
	var b: Variant = gold_banks.get(team)
	return b if b is Node and is_instance_valid(b) else null


## The team's wizard (alive or dead; check is_alive()).
func wizard_of(team: int) -> Wizard:
	if seat_heroes.has(team):
		var w: Variant = seat_heroes[team]
		return w as Wizard if w != null and is_instance_valid(w) else null
	return shadow_hero if team == Unit.Team.ENEMY else hero


## The team's living workers.
func workers_of(team: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u and int(u.team) == team and u.is_alive() and u.has_method(&"command_gather"):
			out.append(u)
	return out


## Seconds until the team's dead wizard respawns; 0 while she is alive (or can't come back).
func respawn_time_left(team: int) -> float:
	return maxf(0.0, float(_respawn_left.get(team, 0.0)))


## The delay the team's next wizard death will get (30, 45, 60, 75, 90, 90...).
func next_respawn_delay(team: int) -> float:
	return minf(RESPAWN_BASE + RESPAWN_STEP * float(_deaths.get(team, 0)), RESPAWN_MAX)


## Where the team's wizard comes back: the keep's spawn point, else the spawn corner of its oldest
## living barracks; Vector3.INF when it has neither.
func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	for node in get_tree().get_nodes_in_group("buildings"):   # tree order = oldest first
		var b := node as TrainingBuilding
		if b and not b is Keep and int(b.team) == team and b.is_alive():
			return b.spawn_point()
	return Vector3.INF


## Seconds since the match started (the navmesh bake). The top bar shows it as m:ss.
func match_time() -> float:
	return _match_time


## Seconds until the Ember Crown can be claimed (0 once unsealed or when there is no crown).
## The UI shows it as a timer; the bot waits for 0 (balance-1 2e).
func crown_unseal_time_left() -> float:
	return crown.crown_unseal_time_left() if crown else 0.0


## "m:ss" of match_time().
func match_time_text() -> String:
	return _clock(_match_time)


## `team` gives up: it loses at once. The bot passes MALRIK_CONCEDES as `message`.
func surrender(team: int, message: String = "") -> void:
	if game_over or not match_started:
		return
	if message != "":
		hud.show_message(message, 6.0)
	_end_game(team != Unit.Team.PLAYER)


## End-screen stats of `team`: trained, lost, killed, buildings_destroyed, gathered.
func stats_of(team: int) -> Dictionary:
	var mine: Dictionary = _stats.get(team, {})
	var theirs: Dictionary = _stats.get(enemy_team_of(team), {})
	var eco := Economy.for_team(team)
	var out := {
		"trained": int(mine.get("trained", 0)),
		"lost": int(mine.get("lost", 0)),
		"killed": int(theirs.get("lost", 0)),
		"buildings_destroyed": int(theirs.get("buildings_lost", 0)),
		"gathered": eco.gathered_total if eco else 0,
	}
	if trade_enabled:
		out.merge(trade_stats_of(team))
	out.merge(mapfill_stats_of(team))
	return out


## Map-fill stats of `team` (map-fill.md 8 end screen), only for the services that exist: points_held and
## points_total (CapturePoints), blessings (Wayshrine blessings received), camps_cleared (CampManager),
## game_hunted (CritterHerds).
func mapfill_stats_of(team: int) -> Dictionary:
	var out := {}
	var cp := _service(capture_points)
	if cp:
		out["points_held"] = (cp.call(&"held_by", team) as Array).size() if cp.has_method(&"held_by") else 0
		out["points_total"] = (cp.call(&"points") as Array).size() if cp.has_method(&"points") else POINT_SPOTS.size()
		out["blessings"] = int(_blessings.get(team, 0))
	var cm := _service(camp_manager)
	if cm:
		out["camps_cleared"] = int(cm.call(&"cleared_count", team)) if cm.has_method(&"cleared_count") \
				else int(_camps_cleared.get(team, 0))
	var ch := _service(critter_herds)
	if ch:
		out["game_hunted"] = int(ch.call(&"hunted_count", team)) if ch.has_method(&"hunted_count") else 0
	return out


## Trade stats of `team` (market-trade.md 8 end screen): gold_earned (all sources), gold_trade (caravans),
## caravans_lost, workers_lost_to_magpies, magpies_slain. Zeros for what does not exist yet.
func trade_stats_of(team: int) -> Dictionary:
	var net: TradeNetwork = trade_network if trade_network != null and is_instance_valid(trade_network) else null
	var bank := gold_bank_of(team)
	var trade_gold: int = net.traded_total(team) if net else 0
	var earned: int = trade_gold + (net.loot_total(team) if net else 0)
	if bank and bank.has_method(&"earned"):
		earned = int(bank.call(&"earned"))
		trade_gold = int(bank.call(&"earned", &"trade"))
	return {
		"gold_earned": earned,
		"gold_trade": trade_gold,
		"caravans_lost": net.caravans_lost(team) if net else 0,
		"workers_lost_to_magpies": net.workers_lost_to_magpies(team) if net else 0,
		"magpies_slain": net.magpies_slain(team) if net else 0,
	}


## The end-screen block for the player (below the VICTORY / DEFEAT banner).
func end_screen_text() -> String:
	var s := stats_of(Unit.Team.PLAYER)
	var text := "Match time %s\nUnits trained %d · Units lost %d · Enemy units killed %d · Buildings destroyed %d\nCrystals gathered %s\n" % [
			match_time_text(), s["trained"], s["lost"], s["killed"], s["buildings_destroyed"],
			_thousands(int(s["gathered"]))]
	if trade_enabled:
		text += "Gold earned %s (trade %s) · Caravans lost %d · Workers lost to Magpies %d · Magpies slain %d\n" % [
				_thousands(int(s["gold_earned"])), _thousands(int(s["gold_trade"])), s["caravans_lost"],
				s["workers_lost_to_magpies"], s["magpies_slain"]]
	var parts: Array[String] = []
	if s.has("points_held"):
		parts.append("Points held at the end %d / %d" % [s["points_held"], s["points_total"]])
	if s.has("camps_cleared"):
		parts.append("Camps cleared %d" % s["camps_cleared"])
	if s.has("blessings"):
		parts.append("Blessings %d" % s["blessings"])
	if s.has("game_hunted"):
		parts.append("Game hunted %d" % s["game_hunted"])
	if not parts.is_empty():
		text += " · ".join(parts) + "\n"
	return text + "F9: play again"


# ---------------------------------------------------------------- map (overrides main.gd)

func _objective_text() -> String:
	var line := "Ember Crown: unclaimed"
	if crown and crown.is_sealed():
		line = "Ember Crown: sealed until 6:00"
	elif crown and crown.is_worn():
		line = "Ember Crown: worn by %s" % crown.wearer_name()
	return "Skirmish: Crown Hollow\nDestroy every %s building. Keep one of yours standing.\n" \
			% _kingdom_info(Unit.Team.ENEMY, "name") + line


func _lane_end() -> Vector3:
	return SHADOW_START


## Both bases trodden dirt, broken flagstones inside the crown's pillar ring.
func _ground_spots() -> Array[Vector4]:
	return [Vector4(PLAYER_START.x, PLAYER_START.z, 13.0, 0.0), Vector4(SHADOW_START.x, SHADOW_START.z, 13.0, 0.0),
			Vector4(ARTIFACT_POS.x, ARTIFACT_POS.z, PILLAR_RING + 1.5, 1.0)]


## main.gd's ground, plus the trade roads painted on it when the ground shader has the road uniforms (10.V10).
func _build_ground() -> void:
	super()
	if not trade_enabled:
		return
	for i in range(nav_region.get_child_count() - 1, -1, -1):
		var body := nav_region.get_child(i) as StaticBody3D
		if body == null:
			continue
		for c in body.get_children():
			var mesh := c as MeshInstance3D
			if mesh and mesh.material_override is ShaderMaterial:
				EnvProps.set_roads(mesh.material_override as ShaderMaterial, road_param())
				return
		return


func _build_map() -> void:
	# Map fill first: the river (its carve joins the first bake) and the clearings the forest checks after its draws.
	if river_enabled:
		_add_river()
	_mapfill_clearings = _map_fill_clearings()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Fire-half clearings; their mirrors are added below.
	var clearings := [[PLAYER_START, 18.0], [FIRE_NODES[&"node_fire_mid"], 7.0], [ARTIFACT_POS, 12.0],
			[HOUSE_SLOT, 4.0]]
	for c in clearings.duplicate():
		clearings.append([-(c[0] as Vector3), c[1]])
	# Items (items.md): peddler clearing 5, cache clearing 3 (both lists are already mirrored).
	var item_clearings := []
	for p: Vector3 in PEDDLER_SPOTS:
		item_clearings.append([p, PEDDLER_CLEARING])
	for p: Vector3 in cache_spots():
		item_clearings.append([p, CACHE_CLEARING])
	# Champions: tavern clearing 6 (TAVERN_SPOTS is already mirrored).
	if tavern_enabled:
		for p: Vector3 in TAVERN_SPOTS:
			item_clearings.append([p, TAVERN_CLEARING])
	# Balance-1: the rich node (r 7) and its hall spot (r 5), both sides; checked after the draws too.
	for c in [[FIRE_NODES[&"node_fire_rich"], RICH_CLEARING], [RICH_HALL_SPOT, RICH_HALL_CLEARING]]:
		item_clearings.append(c)
		item_clearings.append([-(c[0] as Vector3), c[1]])
	# Trade (market-trade.md 2): post clearings r 5, guild house clearings r 6 (both lists are already mirrored),
	# checked after the draws like the item clearings; the road corridors are checked with the obstacle's size.
	if trade_enabled:
		for spot: Dictionary in POST_SPOTS:
			item_clearings.append([spot["center"], POST_CLEARING])
		for spot: Dictionary in DEN_SPOTS + LODGE_SPOTS:
			item_clearings.append([spot["center"], GUILD_CLEARING])

	# Forest: only Fire-half positions (x + z < 0) come from the rng; each is mirrored.
	var tree_spots: Array[Vector3] = []
	for cluster in 9:
		var center := Vector3(rng.randf_range(-50, 50), 0.0, rng.randf_range(-50, 50))
		for i in rng.randi_range(5, 9):
			var p := center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
			if p.x + p.z >= 0.0 or _in_clearing(p, clearings) or _in_path_lane(p):
				continue
			var s := rng.randf_range(0.8, 1.3)
			if _in_clearing(p, item_clearings):   # after the draws: the rng sequence stays as before
				continue
			if trade_enabled and _in_road_corridor(p, 0.45 * s):   # tree collider r 0.45 s
				continue
			if _in_map_fill_corridor(p, 0.45 * s):
				continue
			_add_tree(p, s)
			_add_tree(-p, s)
			tree_spots.append(p)
			tree_spots.append(-p)

	# Scattered rocks: 11 drawn in the Fire half, 22 after the mirror.
	for i in 11:
		var p := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		if p.x + p.z >= 0.0:
			p = -p
		if _in_clearing(p, clearings) or _in_path_lane(p):
			continue
		var s := rng.randf_range(0.8, 2.2)
		var rot := rng.randf() * TAU
		if _in_clearing(p, item_clearings):
			continue
		if trade_enabled and _in_road_corridor(p, 0.8 * s):   # rock collider: 1.6 x 1.3 s box
			continue
		if _in_map_fill_corridor(p, 0.8 * s):
			continue
		_add_rock(p, s, rot)
		_add_rock(-p, s, rot + PI)

	# Map fill: landmarks (colliders before the bake), the Old Wood clusters and the willows (own seeds).
	if river_enabled:
		_add_landmarks()
		var blocked := func(p: Vector3, extra: float) -> bool:
			return _in_clearing(p, clearings) or _in_path_lane(p) or _in_clearing(p, item_clearings) \
					or (trade_enabled and _in_road_corridor(p, extra)) or _in_map_fill_corridor(p, extra)
		_add_old_wood(blocked, tree_spots)
		_add_willows(blocked, tree_spots)

	# Ruined pillars: a ring of 10 around the crown, pillar i and i + 5 are mirrors (same height).
	for i in 5:
		var h := rng.randf_range(2.0, 4.5)
		if i == PILLAR_GAP:
			continue
		for k in [i, i + 5]:
			var a := float(k) * TAU / 10.0
			_add_pillar(ARTIFACT_POS + Vector3(cos(a) * PILLAR_RING, 0.0, sin(a) * PILLAR_RING), h)

	# Keeps (finished, navmesh obstacles before the bake) and the 8 crystal nodes.
	keep = build_grid.spawn_complete(_keep_type(Unit.Team.PLAYER), PLAYER_START + KEEP_OFFSET,
			Unit.Team.PLAYER) as Keep
	shadow_keep = build_grid.spawn_complete(_keep_type(Unit.Team.ENEMY), SHADOW_START - KEEP_OFFSET,
			Unit.Team.ENEMY) as Keep
	for id in FIRE_NODES:
		var pos: Vector3 = FIRE_NODES[id]
		var amount := node_amount(String(id).trim_prefix("node_fire_"))
		_add_crystal_node(id, pos, amount)
		_add_crystal_node(StringName(String(id).replace("fire", "shadow")), -pos, amount)
	# The two neutral shops (obstacles in the navmesh bake).
	for p: Vector3 in PEDDLER_SPOTS:
		var peddler := RuinPeddler.new()
		peddler.name = "RuinPeddler%s" % ("Fire" if p.x < 0.0 else "Shadow")
		nav_region.add_child(peddler)
		peddler.position = p
		peddler.rotation.y = atan2(-p.x, -p.z)   # the counter (local +Z) faces the map centre
		peddlers.append(peddler)
	if tavern_enabled:
		_add_taverns(TAVERN_SPOTS)
	if trade_enabled:
		_add_trade_map()
	if points_enabled:
		_add_capture_points()   # before the bake: towers and wells are navmesh obstacles


# ---------------------------------------------------------------- map fill (map-fill.md, step 12)

## The river (RiverSystem under the NavigationRegion3D, before the first bake) and its cut in the ground.
func _add_river() -> void:
	river = RiverSystem.new()
	river.name = "River"
	river.player_bank_point = PLAYER_START
	nav_region.add_child(river)
	river.setup(river_polylines(), RIVER_HALF_WIDTH, MOAT, CROSSINGS)
	var mat := _ground_material()
	if mat:
		EnvProps.set_river(mat, river.shader_params())
		if ResourceLoader.exists(GROUND_PARAMS_PATH):   # the biome tints (12.V2), Crown Hollow's zones
			var gp: Script = load(GROUND_PARAMS_PATH)
			var names := {}
			if gp:
				for m: Dictionary in gp.get_script_method_list():
					names[String(m.get("name", ""))] = true
			if names.has("skirmish_biomes") and names.has("apply"):
				gp.call(&"apply", mat, gp.call(&"skirmish_biomes"))


## The skirmish ground's ShaderMaterial (the 120 m plane under the NavigationRegion3D), or null.
func _ground_material() -> ShaderMaterial:
	for c in nav_region.get_children():
		var body := c as StaticBody3D
		if body == null or body.get_script() != null:
			continue
		for m in body.get_children():
			var mesh := m as MeshInstance3D
			if mesh and mesh.mesh is PlaneMesh and mesh.material_override is ShaderMaterial:
				return mesh.material_override as ShaderMaterial
	return null


## [pos, radius] clearings of the map-fill spots (points, camps, landmarks and their mirrors), for the forest checks.
func _map_fill_clearings() -> Array:
	var out := []
	if points_enabled:
		for spot: Dictionary in POINT_SPOTS:
			out.append([spot["pos"], float(POINT_CLEARING.get(spot["kind"], 3.0))])
	if camps_enabled:
		for spot: Dictionary in CAMP_SPOTS:
			out.append([spot["pos"], CAMP_CLEARING])
	if river_enabled:
		for spot: Dictionary in LANDMARK_SPOTS:
			if float(spot["clear"]) > 0.0:
				out.append([spot["pos"], float(spot["clear"])])
				out.append([-(spot["pos"] as Vector3), float(spot["clear"])])
	return out


## True when an obstacle at `p` (footprint reaching `extra` m from its centre) would stand within RIVER_CORRIDOR of
## deep water, CROSSING_CORRIDOR of a crossing, or in a map-fill clearing. Everything checked is point-mirrored.
func _in_map_fill_corridor(p: Vector3, extra: float) -> bool:
	for c in _mapfill_clearings:
		if Vector2(p.x - c[0].x, p.z - c[0].z).length() < float(c[1]) + extra:
			return true
	if river == null:
		return false
	if river.distance_to_crossing(p) < CROSSING_CORRIDOR + extra:
		return true
	return river.distance_to_water(p, RIVER_CORRIDOR + extra) < RIVER_CORRIDOR + extra


## The landmarks of LANDMARK_SPOTS and their point mirrors (yaw + PI) under the NavigationRegion3D: the art scene
## (its colliders cut the navmesh) or, without it, plain cylinder colliders (<= 1.8 m). Their foam circles go to the
## water materials.
func _add_landmarks() -> void:
	var foam := PackedVector4Array()
	for spot: Dictionary in LANDMARK_SPOTS:
		for mirror: bool in [false, true]:
			var pos: Vector3 = -(spot["pos"] as Vector3) if mirror else spot["pos"]
			var yaw := PI if mirror else 0.0
			var path := LANDMARK_DIR + String(spot["scene"])
			var root: Node3D = null
			if ResourceLoader.exists(path):
				var scene := load(path) as PackedScene
				root = scene.instantiate() as Node3D if scene else null
			if root == null:
				root = Node3D.new()
				root.add_to_group(&"landmarks")
				root.set_meta(&"landmark_id", spot["id"])
				for col: Array in spot["colliders"]:
					var shape := CylinderShape3D.new()
					shape.radius = float(col[2])
					shape.height = 1.8
					var body := StaticBody3D.new()
					body.collision_layer = 1
					body.collision_mask = 0
					var cs := CollisionShape3D.new()
					cs.shape = shape
					cs.position = Vector3(float(col[0]), 0.9, float(col[1]))
					body.add_child(cs)
					root.add_child(body)
			root.name = "%s%s" % [String(spot["id"]).to_pascal_case(), "East" if mirror else "West"]
			nav_region.add_child(root)
			root.position = Vector3(pos.x, 0.0, pos.z)
			root.rotation.y = yaw
			landmarks.append(root)
			var circles: Variant = root.get_meta(&"foam_rocks") if root.has_meta(&"foam_rocks") else null
			if circles is PackedVector3Array:
				var take := 1 if spot["id"] == &"lm_aqueduct" else (circles as PackedVector3Array).size()   # 16 slots
				for k in mini(take, (circles as PackedVector3Array).size()):
					var c: Vector3 = (circles as PackedVector3Array)[k]
					var w := root.transform * Vector3(c.x, 0.0, c.y)
					foam.append(Vector4(w.x, w.z, c.z, 0.0))
	if river and not foam.is_empty():
		river.add_foam_rocks(foam)


## The two extra Old Wood clusters per bank (OLD_WOOD_CLUSTERS, seed OLD_WOOD_SEED), mirrored. `blocked(p, extra)`
## = the forest's clearing / corridor checks; trees also keep 1.4 m from each other and inside the map.
func _add_old_wood(blocked: Callable, tree_spots: Array[Vector3]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = OLD_WOOD_SEED
	for cluster: Array in OLD_WOOD_CLUSTERS:
		var center: Vector3 = cluster[0]
		for i in int(cluster[2]):
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * float(cluster[1])
			var s := rng.randf_range(0.8, 1.3)
			var p := center + Vector3(cos(a) * r, 0.0, sin(a) * r)
			if absf(p.x) > MAP_SIZE * 0.5 - 2.5 or absf(p.z) > MAP_SIZE * 0.5 - 2.5 or bool(blocked.call(p, 0.45 * s)):
				continue
			if _near_any(p, tree_spots, 1.4):
				continue
			_add_tree(p, s)
			_add_tree(-p, s)
			tree_spots.append(p)
			tree_spots.append(-p)


## Willows on the player's banks (seed WILLOW_SEED): trunk foot 1.5-4 m from the water edge along the north river
## and the moat's outer bank (WILLOW_DRAWS candidates), scale 0.95-1.2, leaning (+X) toward the water; each mirrored
## (yaw + PI). Same checks as the forest, >= WILLOW_SPACING apart, 1.5 m from other trees, WILLOW_CROSSING_GAP from
## crossings.
func _add_willows(blocked: Callable, tree_spots: Array[Vector3]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = WILLOW_SEED
	var line := PackedVector2Array(RIVER_POLYLINE_N)
	var total := 0.0
	for i in line.size() - 1:
		total += line[i].distance_to(line[i + 1])
	var willows: Array[Vector3] = []
	for draw in WILLOW_DRAWS:
		var s := rng.randf_range(0.95, 1.2)
		var gap := rng.randf_range(1.5, 4.0)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var t := rng.randf()
		var p := Vector3.ZERO
		var water := Vector2.ZERO   # the nearest centre-line point (the lean direction)
		if draw < WILLOW_RIVER_DRAWS:
			var along := t * total
			for i in line.size() - 1:
				var l := line[i].distance_to(line[i + 1])
				if along <= l or i == line.size() - 2:
					var c := line[i].lerp(line[i + 1], clampf(along / l, 0.0, 1.0))
					var d := (line[i + 1] - line[i]).normalized()
					var q := c + Vector2(-d.y, d.x) * side * (RIVER_HALF_WIDTH + gap)
					p = Vector3(q.x, 0.0, q.y)
					water = c
					break
				along -= l
		else:
			var a := deg_to_rad(lerpf(140.0, 310.0, t))
			var q := Vector2(MOAT.x, MOAT.y) + Vector2.from_angle(a) * (MOAT.z + MOAT.w + gap)
			p = Vector3(q.x, 0.0, q.y)
			water = Vector2(MOAT.x, MOAT.y) + Vector2.from_angle(a) * MOAT.z
		if p.x + p.z >= 0.0 or absf(p.x) > MAP_SIZE * 0.5 - 2.5 or absf(p.z) > MAP_SIZE * 0.5 - 2.5:
			continue
		if bool(blocked.call(p, 0.45 * s)) or _near_any(p, willows, WILLOW_SPACING) or _near_any(p, tree_spots, 1.5):
			continue
		if river and river.distance_to_crossing(p) < WILLOW_CROSSING_GAP + 0.45 * s:
			continue   # the drooping crown must not hide a bridge / ford entrance
		var dir := Vector2(water.x - p.x, water.y - p.z)
		var yaw := atan2(-dir.y, dir.x)
		_add_willow(p, s, yaw)
		_add_willow(-p, s, yaw + PI)
		willows.append(p)
		willows.append(-p)
		tree_spots.append(p)
		tree_spots.append(-p)


## A willow: the usual tree collider (r 0.45 s, 2 m) drawn with EnvProps' tree_willow mesh (a normal tree without it).
func _add_willow(pos: Vector3, s: float, yaw: float) -> void:
	if env_props == null:
		_add_tree(pos, s)
		return
	var shape := CylinderShape3D.new()
	shape.radius = 0.45 * s
	shape.height = 2.0
	_static_obstacle(pos, shape, 1.0)
	env_props.add_tree_kind("tree_willow", pos, s, yaw)


static func _near_any(p: Vector3, spots: Array[Vector3], radius: float) -> bool:
	for q in spots:
		if Vector2(p.x - q.x, p.z - q.z).length() < radius:
			return true
	return false


## CapturePoints (12.C2, load-guarded) with the 8 POINT_SPOTS, a child of the level created before the bake (its
## towers and wells go under the NavigationRegion3D and cut the navmesh).
func _add_capture_points() -> void:
	capture_points = _add_mapfill_service(CAPTURE_POINTS_PATH, "CapturePoints", &"capture_points_service")
	if capture_points == null:
		return
	if capture_points.has_method(&"setup"):
		capture_points.call(&"setup", POINT_SPOTS)
	if capture_points.has_signal(&"blessing_started"):
		capture_points.connect(&"blessing_started", _on_blessing_started)


## A step-12 service (CapturePoints, CampManager, EpicBeasts, CritterHerds) as a child of the level: loaded by path
## (a missing or broken script can't break the skirmish), `match_time_source` / `local_team` set when it has them.
## Reuses one already in `group`. Its `message(text, seconds)` is connected to the HUD in _setup_map_fill.
func _add_mapfill_service(path: String, node_name: String, group: StringName) -> Node:
	var existing := _live_in_group(group)
	if existing:
		return existing
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("Skirmish: %s can't be instantiated, no %s" % [path, node_name])
		return null
	var service := script.new() as Node
	if service == null:
		return null
	service.name = node_name
	if &"match_time_source" in service:
		service.set(&"match_time_source", match_time)
	if &"local_team" in service:
		service.set(&"local_team", Unit.Team.PLAYER)
	add_child(service)
	return service


## After the bake: CampManager, EpicBeasts and CritterHerds (each load-guarded), the fog reveals of the points and
## landmarks, the HUD messages of every map-fill service.
func _setup_map_fill() -> void:
	if camps_enabled and _service(camp_manager) == null:
		camp_manager = _add_mapfill_service(CAMP_MANAGER_PATH, "CampManager", &"camp_manager")
		if camp_manager and camp_manager.has_method(&"setup"):
			camp_manager.call(&"setup", CAMP_SPOTS)
	if beasts_enabled and _service(epic_beasts) == null:
		epic_beasts = _add_mapfill_service(EPIC_BEASTS_PATH, "EpicBeasts", &"epic_beasts")
		if epic_beasts and epic_beasts.has_method(&"setup"):
			epic_beasts.call(&"setup", LAIR_SPOTS)
	if beasts_enabled and _service(critter_herds) == null:
		critter_herds = _add_mapfill_service(CRITTER_HERDS_PATH, "CritterHerds", &"critter_herds")
		if critter_herds and critter_herds.has_method(&"setup"):
			critter_herds.call(&"setup", DEER_HERDS, RABBIT_HOMES)
	var cm := _service(camp_manager)
	if cm and not cm.has_method(&"cleared_count") and cm.has_signal(&"camp_cleared"):
		cm.connect(&"camp_cleared", _on_camp_cleared)
	# Points and landmarks are explored for both teams from 0:00 (like posts and taverns).
	var reveal: Array[Vector3] = []
	if _service(capture_points):
		for spot: Dictionary in POINT_SPOTS:
			reveal.append(spot["pos"])
	for lm in landmarks:
		if is_instance_valid(lm):
			reveal.append(lm.global_position)
	for p in reveal:
		for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
			fog.reveal(team, p, MAPFILL_REVEAL)
	for s: Node in [_service(capture_points), cm, _service(epic_beasts), _service(critter_herds)]:
		if s and s.has_signal(&"message") and not s.is_connected(&"message", _on_guild_message):
			s.connect(&"message", _on_guild_message)


## `node` if it is a live node, else null.
## Untyped argument: a freed object must not hit a typed argument.
static func _service(node: Variant) -> Node:
	return node as Node if is_instance_valid(node) and not (node as Node).is_queued_for_deletion() else null


## The first node of `group` that is not being deleted (a level freed the same frame leaves its services there).
func _live_in_group(group: StringName) -> Node:
	if is_inside_tree():
		for n: Node in get_tree().get_nodes_in_group(group):
			if not n.is_queued_for_deletion():
				return n
	return null


func _on_blessing_started(team: int, _seconds: float) -> void:
	if not game_over:
		_blessings[team] = int(_blessings.get(team, 0)) + 1


func _on_camp_cleared(_camp: Node, team: int, _reward: Dictionary) -> void:
	if not game_over and team >= 0:
		_camps_cleared[team] = int(_camps_cleared.get(team, 0)) + 1


## Trade (market-trade.md 2): the 4 trading posts and the 4 guild houses under the NavigationRegion3D (obstacles
## in the first bake, fronts toward their doors on the road), then the TradeNetwork. The ring road itself is
## ground paint (_build_ground) and corridors (_build_map).
func _add_trade_map() -> void:
	for spot: Dictionary in POST_SPOTS:
		var post := TradePost.new()
		post.post_id = spot["id"]
		post.display_name = spot["name"]
		post.sign_index = int(spot["sign"])
		post.name = "TradePost_%s" % String(spot["id"]).to_pascal_case()
		_place_facing(post, spot["center"], spot["door"])
		trade_posts.append(post)
	for i in DEN_SPOTS.size() + LODGE_SPOTS.size():
		var den := i < DEN_SPOTS.size()
		var spot: Dictionary = DEN_SPOTS[i] if den else LODGE_SPOTS[i - DEN_SPOTS.size()]
		var house := GuildHouse.new()
		house.kind = GuildHouse.DEN if den else GuildHouse.LODGE
		var center: Vector3 = spot["center"]
		house.name = "%s%s" % ["MagpieDen" if den else "GreywaterLodge", "NorthWest" if center.x < 0.0 else "SouthEast"]
		_place_facing(house, center, spot["door"])
		guild_houses.append(house)
	trade_network = TradeNetwork.new()
	trade_network.name = "TradeNetwork"
	trade_network.match_time_source = match_time
	trade_network.base_positions = {Unit.Team.PLAYER: base_center(Unit.Team.PLAYER),
			Unit.Team.ENEMY: base_center(Unit.Team.ENEMY)}
	add_child(trade_network)
	trade_network.setup(trade_posts, ROAD_NODES, ROAD_SEGMENTS, {&"road": AMBUSH_SPOTS, &"worker": WORKER_SPOTS})
	trade_network.posts_opened.connect(_on_posts_opened)
	_add_waystones()


## Lead glue (10.V10): a draw-only MultiMesh of waystones along the ring road (no collider, no navmesh effect),
## clear of the base hubs (14 m) and of every post / guild house (7 m).
func _add_waystones() -> void:
	const WAYSTONE_ROW_PATH := "res://art/environment/meshes/waystone_row.gd"
	if not ResourceLoader.exists(WAYSTONE_ROW_PATH):
		return
	var clear := PackedVector3Array([base_center(Unit.Team.PLAYER), base_center(Unit.Team.ENEMY)])
	var radii := PackedFloat32Array([14.0, 14.0])
	for spot: Dictionary in POST_SPOTS + DEN_SPOTS + LODGE_SPOTS:
		clear.append(spot["center"])
		radii.append(7.0)
	if river:   # map-fill.md 2.3: the row skips 7 m around each road bridge
		for c: Dictionary in river.crossings():
			if c["kind"] == RiverSystem.KIND_BRIDGE_ROAD:
				clear.append(c["center"])
				radii.append(WAYSTONE_BRIDGE_GAP)
	var row: Script = load(WAYSTONE_ROW_PATH)
	var stones: Variant = row.call(&"build", road_param(), 10.0, 2.2, 5.0, clear, radii, 6.0)
	if stones is Node3D:
		add_child(stones)


## Adds a post / guild house under the NavigationRegion3D at `center`, turned so its front (local +Z) faces `door`.
func _place_facing(node: Node3D, center: Vector3, door: Vector3) -> void:
	nav_region.add_child(node)
	node.position = Vector3(center.x, 0.0, center.z)
	node.rotation.y = atan2(door.x - center.x, door.z - center.z)


## True when `p` (an obstacle whose footprint reaches `extra` metres from its centre) comes within
## ROAD_CORRIDOR of a road segment.
func _in_road_corridor(p: Vector3, extra: float) -> bool:
	var q := Vector2(p.x, p.z)
	for seg in ROAD_SEGMENTS:
		var a: Vector3 = ROAD_NODES[seg[0]]
		var b: Vector3 = ROAD_NODES[seg[1]]
		var c := Geometry2D.get_closest_point_to_segment(q, Vector2(a.x, a.z), Vector2(b.x, b.z))
		if q.distance_to(c) < ROAD_CORRIDOR + extra:
			return true
	return false


## The neutral taverns at `spots` (champions.md 2): under the NavigationRegion3D (obstacles in the bake),
## door side toward the map centre. Missions with champions call it from their _build_map.
func _add_taverns(spots: Array[Vector3]) -> void:
	for p: Vector3 in spots:
		var tavern := Tavern.new()
		tavern.name = "Tavern%s" % ("Fire" if p.x + p.z < 0.0 else "Shadow")
		tavern.match_time_source = match_time
		nav_region.add_child(tavern)
		tavern.position = p
		tavern.rotation.y = atan2(-p.x, -p.z)   # local +Z (the door) toward the centre
		tavern.opened.connect(_on_tavern_opened)
		taverns.append(tavern)


# ---------------------------------------------------------------- start (override)

func _on_navigation_ready() -> void:
	# Identical start for both sides (spec "Start state"): the bot's side is the point mirror of the player's.
	# The player's fog reveal is main.gd's (PLAYER_START); the bot's is here.
	fog.reveal(Unit.Team.ENEMY, SHADOW_START, FogOfWar.START_REVEAL)
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	shadow_hero = _make_wizard(Unit.Team.ENEMY)
	_spawn(shadow_hero, Unit.Team.ENEMY, SHADOW_START)
	_claim_wizard(shadow_hero, Unit.Team.ENEMY)
	var workers := {}
	for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		workers[team] = _worker_type_for(kingdom_of(team), _keep_type(team))
	for i in PaceSwitch.start_workers(blitz_pace):   # 3; Blitz more (the extras go on in the same line, a / b 2:1)
		var offset := Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2)
		var suffix := "a" if i % 3 < 2 else "b"
		var mine := _spawn(Worker.make_unit(workers[Unit.Team.PLAYER]), Unit.Team.PLAYER, PLAYER_START + offset)
		mine.call(&"command_gather", node_of(Unit.Team.PLAYER, suffix))
		var theirs := _spawn(Worker.make_unit(workers[Unit.Team.ENEMY]), Unit.Team.ENEMY, SHADOW_START - offset)
		theirs.call(&"command_gather", node_of(Unit.Team.ENEMY, suffix))
	_add_pace_start_crystals()
	_spawn_wardens()

	crown = EmberCrown.new()
	crown.name = "EmberCrown"
	crown.match_time_source = match_time   # sealed until 6:00 of match time (balance-1)
	add_child(crown)
	crown.global_position = ARTIFACT_POS
	artifact = crown
	crown.claimed.connect(_on_crown_claimed)
	crown.dropped.connect(_on_crown_dropped)
	crown.seal_refused.connect(_on_crown_seal_refused)
	crown.stirring.connect(_on_crown_stirring)
	crown.unsealed.connect(_on_crown_unsealed)

	for wiz: Wizard in [hero, shadow_hero]:
		wiz.died.connect(_on_wizard_died)
		ItemDrops.ensure_inventory(wiz)
	_spawn_caches()
	_setup_map_fill()
	if tavern_enabled:
		_setup_champions()
	if trade_enabled:
		_setup_trade()

	_setup_hud()
	hud.set_objective(_objective_text())
	hud.show_message(SKIRMISH_HINT % _barracks_name(Unit.Team.PLAYER), 10.0)
	_start_match()


## 4 Ruin Wardens (team NEUTRAL) around the crown, at a = TAU / 8 + i * TAU / 4, radius 4.
func _spawn_wardens() -> void:
	if UnitType.find(WARDEN_TYPE) == null:
		push_warning("Skirmish: no data/units/%s.tres, the crown is unguarded" % WARDEN_TYPE)
		return
	for i in WARDEN_COUNT:
		var a := TAU / 8.0 + i * TAU / 4.0
		var warden := _spawn(make_unit(WARDEN_TYPE), Unit.Team.NEUTRAL,
				ARTIFACT_POS + Vector3(cos(a) * WARDEN_RING, 0.0, sin(a) * WARDEN_RING))
		wardens.append(warden)
		warden.died.connect(_on_warden_died)


## Dead wardens leave `wardens` at once (it only ever holds living ones). The 4th death drops
## Warden Scale at (2, 2) and Ember Draught at (-2, -2) (CAMP_DROP_SPOTS).
func _on_warden_died(unit: Unit) -> void:
	wardens.erase(unit)
	wardens_killed += 1
	if wardens_killed == WARDEN_COUNT:
		for i in CAMP_DROP_ITEMS.size():
			ItemDrops.spawn_pickup(self, CAMP_DROP_ITEMS[i], CAMP_DROP_SPOTS[i % CAMP_DROP_SPOTS.size()])


## The 4 Lost Caches (they appear at 2:00 match time, i.e. 120 s after this) at cache_spots().
func _spawn_caches() -> void:
	var spots := cache_spots()
	for i in spots.size():
		var cache := LostCache.new()
		cache.name = "LostCache%d" % i
		cache.rng.seed = 11 + i
		cache.match_time_source = match_time
		add_child(cache)
		cache.global_position = spots[i]
		cache.opened.connect(_on_cache_opened)
		caches.append(cache)


## Champions (champions.md 2-3): both taverns explored for both teams, one ChampionGuild per team whose
## messages go to the HUD. Missions with champions call it from their _on_navigation_ready.
func _setup_champions() -> void:
	for t in taverns:
		for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
			fog.reveal(team, t.global_position, TAVERN_REVEAL)
	for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		if ChampionGuild.for_team(team):
			guilds[team] = ChampionGuild.for_team(team)
			continue
		var guild := ChampionGuild.new()
		guild.name = "ChampionGuild%s" % ("Player" if team == Unit.Team.PLAYER else "Enemy")
		guild.team = team
		guild.local_team = Unit.Team.PLAYER
		add_child(guild)
		guild.message.connect(_on_guild_message)
		guilds[team] = guild


## Trade at match start (market-trade.md 2.5, 12): the 4 posts and 4 guild houses are explored for both teams
## (landmarks), then the Thieves' and Hunters' guild services start (each only if its script exists).
func _setup_trade() -> void:
	var landmarks: Array[Node3D] = []
	landmarks.append_array(trade_posts)
	landmarks.append_array(guild_houses)
	for n in landmarks:
		for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
			fog.reveal(team, n.global_position, LANDMARK_REVEAL)
	if thieves_guild == null or not is_instance_valid(thieves_guild):
		thieves_guild = _add_trade_service(THIEVES_GUILD_PATH, "ThievesGuild", &"thieves_guild")
	if hunters_guild == null or not is_instance_valid(hunters_guild):
		hunters_guild = _add_trade_service(HUNTERS_GUILD_PATH, "HuntersGuild", &"hunters_guild")


## A guild service (ThievesGuild / HuntersGuild, 10.C4 / 10.C5) as a child of the level: loaded by path (a
## missing or broken script can't break the skirmish), `match_time_source` and `local_team` set when it has
## them, its `message(text, seconds)` shown on the HUD. Reuses one already in `group`.
func _add_trade_service(path: String, node_name: String, group: StringName) -> Node:
	var existing := _live_in_group(group)
	if existing:
		return existing
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("Skirmish: %s can't be instantiated, no %s" % [path, node_name])
		return null
	var service := script.new() as Node
	if service == null:
		return null
	service.name = node_name
	if &"match_time_source" in service:
		service.set(&"match_time_source", match_time)
	if &"local_team" in service:
		service.set(&"local_team", Unit.Team.PLAYER)
	add_child(service)
	if service.has_signal(&"message"):
		service.connect(&"message", _on_guild_message)
	return service


## One GoldBank per team (scripts/economy/gold_bank.gd, 10.C11), created before anything else so every unit
## finds its team's bank in _ready. Nothing when the script does not exist yet.
func _create_gold_banks() -> void:
	if not ResourceLoader.exists(GOLD_BANK_PATH):
		return
	var script := load(GOLD_BANK_PATH) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("Skirmish: %s can't be instantiated, no gold" % GOLD_BANK_PATH)
		return
	for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		var bank: Node = null
		for n in get_tree().get_nodes_in_group(&"gold_banks"):
			if n.get(&"team") != null and int(n.get(&"team")) == team:
				bank = n
		if bank == null:
			bank = script.new() as Node
			if bank == null:
				continue
			bank.name = "GoldBank%s" % ("Player" if team == Unit.Team.PLAYER else "Enemy")
			bank.set(&"team", team)
			if &"local_team" in bank:
				bank.set(&"local_team", Unit.Team.PLAYER)
			add_child(bank)
			if not bank.is_in_group(&"gold_banks"):
				bank.add_to_group(&"gold_banks")
			if bank.has_signal(&"message"):
				bank.connect(&"message", _on_guild_message)
		gold_banks[team] = bank


## 4:00: the posts open; one message with the one-time Bazaar hint.
func _on_posts_opened() -> void:
	if not game_over and hud:
		hud.show_message("%s\n%s" % [MSG_POSTS_OPEN, HINT_BAZAAR], 6.0)


## The team's ChampionGuild, or null (no taverns on this map).
func guild_of(team: int) -> ChampionGuild:
	var g: Variant = guilds.get(team)
	return g if g is ChampionGuild and is_instance_valid(g) else null


func _on_guild_message(text: String, seconds: float) -> void:
	if not game_over:
		hud.show_message(text, seconds)


## 2:00: both taverns open together; one message with the one-time hint.
func _on_tavern_opened(_tavern: Tavern) -> void:
	if _taverns_announced or game_over:
		return
	_taverns_announced = true
	hud.show_message("%s\n%s" % [Tavern.MSG_OPEN, Tavern.HINT_HIRE], 6.0)


func _on_cache_opened(_cache: LostCache, wizard: Node, loot: Dictionary) -> void:
	if game_over:
		return
	# One of the player's champions opened it (9.C4: essence goes to its purse).
	if wizard != hero and wizard != null and wizard.is_in_group(&"champions") and int(wizard.get(&"team")) == Unit.Team.PLAYER:
		var who: Variant = wizard.get(&"display_name")
		if loot.has("essence") and who is String and who != "":
			hud.show_message("%s found %d essence" % [who, int(loot["essence"])], 3.0)
		return
	if wizard != hero:
		return
	if loot.has("essence"):
		hud.show_message("The Lost Cache holds %d essence" % int(loot["essence"]), 3.0)
	else:
		var type := ItemDrops.item_type(StringName(loot["item"]))
		var item_name: String = String(type.get(&"display_name")) if type and &"display_name" in type else String(loot["item"])
		hud.show_message("The Lost Cache holds %s" % item_name, 3.0)


func _start_match() -> void:
	match_started = true
	_match_time = 0.0
	for team in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		_stats[team] = {"trained": 0, "lost": 0, "buildings_lost": 0}
		_deaths[team] = 0
	for node in get_tree().get_nodes_in_group("units"):
		_watch(node)
	for node in get_tree().get_nodes_in_group("buildings"):
		_watch(node)
	get_tree().node_added.connect(_watch)
	_create_score_keeper()
	# Replay Lab (docs/plan/replay-lab.md): the replay session (recorder / player), loaded by path so a broken
	# replay script can't break the skirmish.
	var replay_hooks: Script = load(REPLAY_HOOKS_PATH) as Script if ResourceLoader.exists(REPLAY_HOOKS_PATH) else null
	if replay_hooks != null:
		replay_hooks.call(&"match_started", self)


## Step 16a: the ScoreKeeper (loaded by path, so a broken score script can't break the skirmish).
func _create_score_keeper() -> void:
	if score_keeper != null and is_instance_valid(score_keeper):
		return
	if not ResourceLoader.exists(SCORE_KEEPER_PATH):
		return
	var script := load(SCORE_KEEPER_PATH) as GDScript
	if script == null or not script.can_instantiate():
		push_warning("Skirmish: %s can't be instantiated, no score" % SCORE_KEEPER_PATH)
		return
	score_keeper = script.new() as Node
	score_keeper.name = "ScoreKeeper"
	score_keeper.set(&"match_time_source", match_time)
	score_keeper.set(&"level", self)
	add_child(score_keeper)


## Step 16a: the time limit was reached: the higher score wins (a tie = the player loses).
func _end_on_score() -> void:
	if game_over:
		return
	ended_on_score = true
	var lead := -1
	if score_keeper != null and is_instance_valid(score_keeper):
		score_keeper.call(&"finish")
		lead = int(score_keeper.call(&"leader"))
	_end_game(lead == Unit.Team.PLAYER)


## Step 16a: the end screen's Score tab (every end: victory, defeat, concede, time limit).
func _show_score_screen(victory: bool) -> void:
	if hud == null or not hud.has_method(&"show_score"):
		return
	var sk: Node = score_keeper if score_keeper != null and is_instance_valid(score_keeper) else null
	if sk:
		sk.call(&"finish")
	var subtitle := ""
	if ended_on_score and sk:
		var mine := int(sk.call(&"score", Unit.Team.PLAYER))
		var theirs := int(sk.call(&"score", Unit.Team.ENEMY))
		subtitle = "%s on score  %s to %s" % ["Won" if victory else "Lost", _thousands(mine), _thousands(theirs)]
	var teams := [Unit.Team.PLAYER, Unit.Team.ENEMY]
	var names := ["You (%s)" % _kingdom_info(Unit.Team.PLAYER, "name"),
			"%s (%s)" % [_kingdom_info(Unit.Team.ENEMY, "hero"), _kingdom_info(Unit.Team.ENEMY, "name")]]
	var colors := [UIStyle.kingdom_color(kingdom_of(Unit.Team.PLAYER)), UIStyle.kingdom_color(kingdom_of(Unit.Team.ENEMY))]
	if colors[0] == colors[1]:
		colors[1] = UIStyle.DEFEAT   # mirror match: the enemy line in red
	hud.call(&"show_score", sk, teams, names, colors, subtitle)


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	if not match_started:
		return
	_surrender_left = maxf(0.0, _surrender_left - delta)
	if game_over:
		return
	_match_time += delta
	_tick_respawns(delta)
	_home_healing(delta)
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = CHECK_INTERVAL
		_check_end()
	if not game_over and time_limit_s > 0.0 and _match_time >= time_limit_s:
		_end_on_score()


func _check_end() -> void:
	# The first team with no living building (sites count, walls don't) loses; both at once = the player loses.
	if Building.defeat_relevant(Unit.Team.PLAYER).is_empty():
		_end_game(false)
	elif Building.defeat_relevant(Unit.Team.ENEMY).is_empty():
		_end_game(true)


func _tick_respawns(delta: float) -> void:
	for team: int in _respawn_left.keys():
		_respawn_left[team] = float(_respawn_left[team]) - delta
		if _respawn_left[team] <= 0.0:
			_respawn_left[team] = 0.0
			if _respawn_wizard(team):
				_respawn_left.erase(team)


func _home_healing(delta: float) -> void:
	for team in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		var wiz := wizard_of(team)
		var k := keep_of(team)
		if wiz == null or k == null or not is_instance_valid(wiz) or not wiz.is_alive() or wiz.hp >= wiz.max_hp:
			continue
		var d := Vector2(wiz.global_position.x - k.global_position.x, wiz.global_position.z - k.global_position.z)
		if d.length() <= HOME_HEAL_RADIUS:
			wiz.heal(wiz.max_hp * HOME_HEAL_RATIO * delta)


# ---------------------------------------------------------------- wizards

func _on_wizard_died(unit: Unit) -> void:
	var wiz := unit as Wizard
	var team := int(unit.team)
	if game_over or wiz == null:
		return
	var delay := next_respawn_delay(team)
	_deaths[team] = int(_deaths.get(team, 0)) + 1
	_respawn_left[team] = delay
	wizard_fell.emit(wiz, delay)
	if team == Unit.Team.PLAYER:
		hud.show_message("%s has fallen! %s returns in %d s" % [EmberCrown.short_name(wiz),
				_kingdom_info(team, "pronoun"), int(delay)], 4.0)
	else:
		hud.show_message(_kingdom_info(team, "fallen"), 4.0)


## True when the timer is done with (she came back, or there is nobody to bring back); false while the team has no
## respawn point: the timer stays at 0 and retries every frame until a keep / barracks stands again (review W1-1).
func _respawn_wizard(team: int) -> bool:
	var wiz := wizard_of(team)
	if wiz == null or not is_instance_valid(wiz) or wiz.is_alive():
		return true
	var at := respawn_point(team)
	if at == Vector3.INF:
		return false
	if not wiz.has_method(&"respawn"):
		push_warning("Skirmish: Wizard.respawn() is missing, %s can't come back" % wiz.unit_name)
		return true
	wiz.call(&"respawn", at)
	wizard_respawned.emit(wiz)
	if team == Unit.Team.PLAYER:
		selection.select_units([wiz])
		hud.show_message("%s returns!" % EmberCrown.short_name(wiz), 3.0)
	return true


# ---------------------------------------------------------------- the crown

func _on_crown_claimed(claimed: Artifact, by: Wizard) -> void:
	hud.show_message("%s wears the %s" % [EmberCrown.short_name(by), claimed.artifact_name], 4.0)
	hud.set_objective(_objective_text())
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.artifact_claimed.emit(claimed, by)
		events.objective_changed.emit(&"ember_crown",
				&"worn_by_player" if int(by.team) == Unit.Team.PLAYER else &"worn_by_enemy")


func _on_crown_seal_refused(_crown: EmberCrown, wizard: Wizard) -> void:
	if not game_over and wizard == hero:
		hud.show_message(EmberCrown.MSG_SEALED, 3.0)


func _on_crown_stirring(_crown: EmberCrown) -> void:
	if not game_over:
		hud.show_message(EmberCrown.MSG_STIRS, 4.0)


func _on_crown_unsealed(_crown: EmberCrown) -> void:
	if not game_over:
		hud.show_message(EmberCrown.MSG_AWAKENS, 4.0)
	hud.set_objective(_objective_text())


func _on_crown_dropped(dropped: EmberCrown, _at: Vector3) -> void:
	if not game_over:
		hud.show_message("The %s lies unclaimed" % dropped.artifact_name, 4.0)
	hud.set_objective(_objective_text())
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.objective_changed.emit(&"ember_crown", &"unclaimed")


# ---------------------------------------------------------------- end of the match

func _end_game(victory: bool) -> void:
	if game_over:
		return
	game_over = true
	winner_team = Unit.Team.PLAYER if victory else Unit.Team.ENEMY
	_respawn_left.clear()
	# Orders stop; the simulation keeps running (units still defend themselves).
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) != Unit.Team.NEUTRAL:
			u.command_stop()
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.mission_ended.emit(victory)
	match_ended.emit(winner_team)
	if victory:
		hud.show_banner("VICTORY", Color(1.0, 0.85, 0.3))
	else:
		hud.show_banner("DEFEAT", Color(0.9, 0.3, 0.3))
	hud.show_message(end_screen_text(), 1.0e9)
	_show_score_screen(victory)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		if code == KEY_F10:
			if game_over or not match_started:
				return
			if _surrender_left > 0.0:
				surrender(Unit.Team.PLAYER)
			else:
				_surrender_left = SURRENDER_WINDOW
				hud.show_message("Press F10 again to surrender", SURRENDER_WINDOW)
			get_viewport().set_input_as_handled()
			return
	super(event)


# ---------------------------------------------------------------- stats

func _watch(node: Node) -> void:
	var unit := node as Unit
	if unit:
		if not unit.died.is_connected(_on_unit_died):
			unit.died.connect(_on_unit_died)
		return
	var trainer := node as TrainingBuilding
	if trainer and not trainer.unit_trained.is_connected(_on_unit_trained):
		trainer.unit_trained.connect(_on_unit_trained.bind(trainer))
	var building := node as Building
	if building and not building.destroyed.is_connected(_on_building_destroyed):
		building.destroyed.connect(_on_building_destroyed)


func _on_unit_died(unit: Unit) -> void:
	if not game_over:
		_count(int(unit.team), "lost")


func _on_unit_trained(_unit: Unit, trainer: TrainingBuilding) -> void:
	if not game_over:
		_count(int(trainer.team), "trained")


func _on_building_destroyed(building: Building) -> void:
	if not game_over and not building.cancelled:
		_count(int(building.team), "buildings_lost")


func _count(team: int, key: String) -> void:
	if _stats.has(team):
		_stats[team][key] = int(_stats[team][key]) + 1


# ---------------------------------------------------------------- helpers

## `kingdom` if kingdom_available(), else `fallback` (with a warning).
static func _resolve_kingdom(kingdom: StringName, fallback: StringName) -> StringName:
	if kingdom_available(kingdom):
		return kingdom
	push_warning("Skirmish: kingdom '%s' is not available yet (keep, worker or wizard missing), using %s"
			% [kingdom, fallback])
	return fallback


## A field of KINGDOMS for the team's kingdom (an unknown kingdom reads as the side's default).
func _kingdom_info(team: int, key: String) -> String:
	var fallback := DEFAULT_ENEMY_KINGDOM if team == Unit.Team.ENEMY else DEFAULT_PLAYER_KINGDOM
	var info: Dictionary = KINGDOMS.get(kingdom_of(team), KINGDOMS[fallback])
	return String(info[key])


## The team's keep type (checked in _ready, so never null for a known kingdom).
func _keep_type(team: int) -> BuildingType:
	return BuildingType.find(_kingdom_info(team, "keep"))


## The kingdom's starting worker: the first worker its keep trains, else KINGDOMS' "worker"; null if neither exists.
static func _worker_type_for(kingdom: StringName, keep_type: BuildingType) -> UnitType:
	if keep_type:
		for t in keep_type.trains:
			if t and t.is_worker:
				return t
	var info: Dictionary = KINGDOMS.get(kingdom, {})
	return UnitType.find(String(info.get("worker", ""))) if info.has("worker") else null


## "an Ember Hall" style name of the team's barracks for the start hint ("a barracks" if unknown).
func _barracks_name(team: int) -> String:
	var t := BuildingType.find("%s_barracks" % kingdom_of(team))
	if t == null or t.display_name == "":
		return "a barracks"
	return ("an " if "aeiou".contains(t.display_name.left(1).to_lower()) else "a ") + t.display_name


## The team's wizard for its kingdom (script loaded by path, so a wizard script still being written can't
## break this file); the side's default wizard if the script can't be instantiated.
func _make_wizard(team: int) -> Wizard:
	var path := _kingdom_info(team, "wizard")
	var wiz: Wizard = null
	if ResourceLoader.exists(path):
		var script := load(path) as GDScript
		if script and script.can_instantiate():
			wiz = script.new() as Wizard
	if wiz == null:
		push_warning("Skirmish: no wizard script %s, using the default wizard" % path)
		wiz = ShadowWizard.new() if team == Unit.Team.ENEMY else Wizard.new()
	return wiz


## After _spawn (the wizard's _ready ran): the player's wizard is in "heroes" (claims artifacts, the HUD's
## level-up lines) and never casts by itself (the player casts; no ai_auto_cast); the bot's is in
## "enemy_heroes" (its Commander turns ai_auto_cast off when it owns the casts).
func _claim_wizard(wiz: Wizard, team: int) -> void:
	var mine := team == Unit.Team.PLAYER
	if mine:
		wiz.remove_from_group(&"enemy_heroes")
		wiz.add_to_group(&"heroes")
		if &"ai_auto_cast" in wiz:
			wiz.set(&"ai_auto_cast", false)
	elif Teams.multi and Teams.is_ally(team, Unit.Team.PLAYER):   # 2v2: an allied bot's wizard
		wiz.remove_from_group(&"heroes")
		wiz.remove_from_group(&"enemy_heroes")
		wiz.add_to_group(&"ally_heroes")
	else:
		wiz.remove_from_group(&"heroes")
		wiz.add_to_group(&"enemy_heroes")


## `p` for the Fire side, its point mirror for the Shadow side.
static func _mirror(p: Vector3, team: int) -> Vector3:
	return -p if team == Unit.Team.ENEMY else p


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


## 2640 -> "2 640" (the spec's end screen).
static func _thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

## The match clock, wizard deaths and respawn timers, end-screen stats (SaveWorld; MissionBase adds its own state).
## The map services save through `save_world_state` / `load_world_state` (review 2026-10-12 F3a): the score, Lost
## Caches, champion guilds, bounty boards, capture points, camps, epic beasts, the thieves' guild.
func save_level_state(ids: Dictionary) -> Dictionary:
	return {"time": _match_time, "deaths": _deaths.duplicate(), "respawn": _respawn_left.duplicate(),
			"stats": _stats.duplicate(true), "wardens_killed": wardens_killed, "blessings": _blessings.duplicate(),
			"camps_cleared": _camps_cleared.duplicate(), "taverns_announced": _taverns_announced,
			"services": _save_services(ids)}


func _save_services(ids: Dictionary) -> Dictionary:
	var out := {}
	var caches_d: Array = []
	for c in caches:
		caches_d.append(c.save_world_state() if is_instance_valid(c) else {})
	out["caches"] = caches_d
	var guilds_d := {}
	for team: Variant in guilds:
		var g := guild_of(int(team))
		if g and g.has_method(&"save_world_state"):
			guilds_d[int(team)] = g.save_world_state(ids)
	out["guilds"] = guilds_d
	var boards := {}
	for n in get_tree().get_nodes_in_group(&"bounty_boards"):
		var b := n as BountyBoard
		if b and not b.is_queued_for_deletion() and not b.bounties.is_empty():
			boards[b.team] = b.save_world_state(ids)
	out["bounties"] = boards
	for key: String in ["capture_points", "thieves_guild", "score_keeper"]:
		var s := _service(get(key))
		if s and s.has_method(&"save_world_state"):
			out[key] = s.call(&"save_world_state")
	for key: String in ["camp_manager", "epic_beasts"]:
		var s := _service(get(key))
		if s and s.has_method(&"save_world_state"):
			out[key] = s.call(&"save_world_state", ids)
	return out


## After the match clock: points first (bounties guard them), then camps / beasts / guilds / bounties, the score last
## (it re-reads the restored banks without counting them as gained).
func _load_services(sv: Dictionary, nodes: Dictionary) -> void:
	var caches_d: Array = sv.get("caches", [])
	for i in mini(caches_d.size(), caches.size()):
		if is_instance_valid(caches[i]) and not (caches_d[i] as Dictionary).is_empty():
			caches[i].load_world_state(caches_d[i])
	for key: String in ["capture_points", "thieves_guild"]:
		var s := _service(get(key))
		if s and s.has_method(&"load_world_state") and sv.has(key):
			s.call(&"load_world_state", sv[key])
	for key: String in ["camp_manager", "epic_beasts"]:
		var s := _service(get(key))
		if s and s.has_method(&"load_world_state") and sv.has(key):
			s.call(&"load_world_state", sv[key], nodes)
	var guilds_d: Dictionary = sv.get("guilds", {})
	for team: Variant in guilds_d:
		var g := guild_of(int(team))
		if g and g.has_method(&"load_world_state"):
			g.load_world_state(guilds_d[team], nodes)
	var boards: Dictionary = sv.get("bounties", {})
	for team: Variant in boards:
		var b := BountyBoard.for_team(int(team))
		if b:
			b.load_world_state(boards[team], nodes)
	if trade_network != null and is_instance_valid(trade_network):
		trade_network.sync_announcements()
	var sk := _service(score_keeper)
	if sk and sk.has_method(&"load_world_state"):
		sk.call(&"load_world_state", sv.get("score_keeper", {}))


func load_level_state(d: Dictionary, nodes: Dictionary) -> void:
	_match_time = float(d.get("time", _match_time))
	_deaths = (d.get("deaths", _deaths) as Dictionary).duplicate()
	_respawn_left = (d.get("respawn", {}) as Dictionary).duplicate()
	_stats = (d.get("stats", _stats) as Dictionary).duplicate(true)
	wardens_killed = int(d.get("wardens_killed", wardens_killed))
	_blessings = (d.get("blessings", {}) as Dictionary).duplicate()
	_camps_cleared = (d.get("camps_cleared", {}) as Dictionary).duplicate()
	_taverns_announced = bool(d.get("taverns_announced", _taverns_announced))
	var alive: Array[Unit] = []
	for w: Variant in wardens:
		if is_instance_valid(w) and (w as Unit).is_alive():
			alive.append(w)
	wardens = alive
	_load_services(d.get("services", {}), nodes)
