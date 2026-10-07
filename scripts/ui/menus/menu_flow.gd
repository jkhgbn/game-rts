class_name MenuFlow
extends RefCounted
## Scene flow between the menus and the 1v1 (task 5.U1): start a skirmish with a bot difficulty,
## restart it, go back to the main menu. The chosen difficulty survives restarts (pause menu or F9):
## a SceneTree.node_added hook sets it on the "ShadowBot" Commander before its _ready, and sets
## the edge-pan setting on every RTSCamera that enters the tree.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const SKIRMISH := "res://scenes/skirmish.tscn"
const WAVE_STRIKE := "res://scenes/wave_strike.tscn"   ## Wave Strike (docs/design/wave-strike.md M1).
const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"   ## Skirmish.kingdom_available(k) (8.S2).
const BOT_NODE := &"ShadowBot"
## The campaign prologue (tools/cine bake of data/cinematics/src/prologue_3min.cine + its runtime stage).
const PROLOGUE_ID := &"prologue_3min"
const PROLOGUE_STAGE := "res://scenes/cinematics/prologue_3min.tscn"
const PROLOGUE_SCRIPT := "res://data/cinematics/prologue_3min.tres"

static var difficulty := -1                  ## Commander.Difficulty chosen in the menu (-1 = none yet).
## The player's kingdom (8.U1): &"fire" / &"shadow" / &"ice" / &"nature". Set on the Skirmish node as
## `player_kingdom` before it enters the tree (and again by the hook on restarts).
static var player_kingdom: StringName = &"fire"
static var kingdom: StringName = &"fire"     ## Legacy alias of player_kingdom (kept in sync).
## The skirmish opponent (7.U1, any of the 4 kingdoms since 8.U1, mirror allowed). Set on the Skirmish
## node before it enters the tree (and again by the hook on restarts).
static var enemy_kingdom: StringName = &"shadow"
## MT9: the map of the running skirmish (a ready MapCatalog id; &"random" is resolved at start, so restarts replay the
## same map) and its layout path ("" = a scene map: Crown Hollow). The restart hook puts the layout back on the
## reloaded LayoutLevel before its _ready.
static var map_id: StringName = &"crown_hollow"
static var map_layout_path := ""
static var ws_kingdom: StringName = &"fire"     ## Wave Strike: the player's kingdom (any of the 4).
static var ws_personality := "steward"            ## Wave Strike: the bot's personality (WaveBot.PERSONALITIES).
## Wave Strike: the bot's kingdom as chosen (&"random" = another kingdom than the player's, drawn at start) and as
## resolved for the running match (F9 / Restart replay the same matchup).
static var ws_enemy_kingdom: StringName = &"random"
static var ws_enemy_resolved: StringName = &"shadow"
const WS_KINGDOMS: Array[StringName] = [&"fire", &"ice", &"nature", &"shadow"]
static var _enemy_chosen := false             ## True once the menu picked the kingdoms.
static var _hooked_tree: SceneTree = null


## Instances the skirmish level of `map` (MT9: a MapCatalog id or &"random"; &"" = GameSettings.map_id; unknown or
## not ready = Crown Hollow, scenes/skirmish.tscn), sets the bot's difficulty and both kingdoms before it enters the
## tree, and makes it the current scene (the old one is freed). `seats` filters Random (2 = 1v1 maps, 4 = 2v2 maps,
## 0 = any). Returns the new level.
static func start_skirmish(tree: SceneTree, bot_difficulty: int, enemy: StringName = &"",
		player: StringName = &"", map: StringName = &"", seats: int = 0) -> Node:
	difficulty = bot_difficulty
	if enemy != &"":
		enemy_kingdom = enemy
		_enemy_chosen = true
	if player != &"":
		player_kingdom = player
		kingdom = player
		_enemy_chosen = true
	install_hooks(tree)
	var level := instantiate_map(map if map != &"" else GameSettings.map_id, seats)
	apply_kingdoms(level)
	GameSettings.apply_trade(level)
	GameSettings.apply_time_limit(level)
	return _launch(tree, level, bot_difficulty)


## Starts a Wave Strike 1v1 (Ashwind Reach, any of the 4 kingdoms; enemy &"random" = another kingdom) against the
## WaveBot. Returns the new level.
static func start_wave_strike(tree: SceneTree, kingdom: StringName = &"fire", personality: String = "steward",
		enemy: StringName = &"random") -> Node:
	ws_kingdom = kingdom if WS_KINGDOMS.has(kingdom) else &"fire"
	ws_personality = personality
	ws_enemy_kingdom = enemy
	ws_enemy_resolved = resolve_ws_enemy(ws_kingdom, enemy)
	install_hooks(tree)
	var level := (load(WAVE_STRIKE) as PackedScene).instantiate()
	_apply_wave_strike(level)
	return _launch(tree, level, 1)


static func _apply_wave_strike(level: Node) -> void:
	level.set(&"player_kingdom", ws_kingdom)
	level.set(&"enemy_kingdom", ws_enemy_resolved)
	var p: Array[String] = ["hammer", ws_personality]
	level.set(&"personalities", p)


## The bot's kingdom: `enemy` when it is one of the 4, else (&"random") another kingdom than the player's.
static func resolve_ws_enemy(player: StringName, enemy: StringName) -> StringName:
	if WS_KINGDOMS.has(enemy):
		return enemy
	var others: Array[StringName] = []
	for k in WS_KINGDOMS:
		if k != player:
			others.append(k)
	return others[randi() % others.size()]


## The level of a catalog map, not in the tree yet (Random resolved now); remembers it in `map_id` / `map_layout_path`.
## Falls back to scenes/skirmish.tscn (Crown Hollow) when the catalog cannot build it.
static func instantiate_map(map: StringName, seats: int = 0) -> Node:
	var cat := MapCatalog.load_default()
	var id := cat.resolve(map, seats)
	var level := cat.instantiate_level(id)
	if level == null:
		id = MapCatalog.DEFAULT_ID
		level = (load(SKIRMISH) as PackedScene).instantiate()
	map_id = id
	map_layout_path = cat.layout_path_of(id)
	return level


## Sets `player_kingdom` and `enemy_kingdom` on a skirmish level (each only when it has that
## property, systems 7.S2 / 8.S2). True if `player_kingdom` was set.
static func apply_kingdoms(level: Node) -> bool:
	apply_enemy_kingdom(level)
	return apply_player_kingdom(level)


## Sets `player_kingdom` on a skirmish level when it has that property (systems 8.S2). True if set.
static func apply_player_kingdom(level: Node) -> bool:
	if level == null or not (&"player_kingdom" in level):
		return false
	level.set(&"player_kingdom", player_kingdom)
	return true


## Starts a campaign mission scene with the chosen bot difficulty. Returns the new level (null = no scene).
static func start_mission(tree: SceneTree, scene_path: String, bot_difficulty: int) -> Node:
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return null
	difficulty = bot_difficulty
	install_hooks(tree)
	var level := (load(scene_path) as PackedScene).instantiate()
	return _launch(tree, level, bot_difficulty)


## Campaign start (2026-09-27): mission 1 is preceded by the 3-minute prologue (in-engine, the baked cine movie on its
## stage scene) the first time; the campaign save remembers it ("seen"). The Campaign menu's "Watch prologue" replays it.
## Since mission 0 (2026-10-03, mission-00.md): a new campaign opens on M0 (prologue -> M0, whose ep1_intro card is its
## briefing); the prologue also precedes M1 if the player starts there first.
static func start_campaign_mission(tree: SceneTree, mission_id: StringName, scene_path: String, bot_difficulty: int) -> Node:
	if (mission_id == CampaignState.FIRST_MISSION or mission_id == CampaignState.OPENING_MISSION) and prologue_available():
		var cs := CampaignState.open()
		if not cs.is_seen(PROLOGUE_ID):
			return play_prologue(tree, scene_path, bot_difficulty)
	return start_mission(tree, scene_path, bot_difficulty)


## True when the prologue's stage scene and baked script exist.
static func prologue_available() -> bool:
	return ResourceLoader.exists(PROLOGUE_STAGE) and ResourceLoader.exists(PROLOGUE_SCRIPT)


## Plays the prologue full screen (its CinematicStage autoplays; Esc / Space skip per the runtime). When it ends or is
## skipped it is marked seen, then `then_scene` starts as a mission ("" = back to the main menu). Returns the stage.
static func play_prologue(tree: SceneTree, then_scene: String = "", bot_difficulty: int = 1) -> Node:
	if not prologue_available():
		if then_scene != "":
			return start_mission(tree, then_scene, bot_difficulty)
		return null
	difficulty = bot_difficulty
	var stage := (load(PROLOGUE_STAGE) as PackedScene).instantiate()
	stage.set(&"quit_when_done", false)
	var after := func(id: StringName, _skipped: bool) -> void:
		CampaignState.open().mark_seen(id)
		if then_scene != "":
			start_mission(tree, then_scene, bot_difficulty)
		else:
			quit_to_menu(tree)
	if stage.has_signal(&"cinematic_done"):
		stage.connect(&"cinematic_done", after, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	return _launch(tree, stage, bot_difficulty)


## Sets `enemy_kingdom` on a skirmish level when it has that property (systems 7.S2). True if set.
static func apply_enemy_kingdom(level: Node) -> bool:
	if level == null or not (&"enemy_kingdom" in level):
		return false
	level.set(&"enemy_kingdom", enemy_kingdom)
	return true


static func _launch(tree: SceneTree, level: Node, bot_difficulty: int) -> Node:
	var bot := level.get_node_or_null(NodePath(BOT_NODE))
	if bot != null:
		bot.set(&"difficulty", bot_difficulty)
	tree.paused = false
	var old := tree.current_scene
	tree.root.add_child(level)
	tree.current_scene = level
	if old != null and old != level:
		old.queue_free()
	return level


## Reloads the current level (the hook re-applies the chosen difficulty).
static func restart(tree: SceneTree) -> void:
	install_hooks(tree)
	tree.paused = false
	tree.reload_current_scene()


static func quit_to_menu(tree: SceneTree) -> void:
	tree.paused = false
	tree.change_scene_to_file(MAIN_MENU)


static func install_hooks(tree: SceneTree) -> void:
	if tree == null or _hooked_tree == tree:
		return
	_hooked_tree = tree
	tree.node_added.connect(_on_node_added)


static func _on_node_added(node: Node) -> void:
	if node is RTSCamera:
		(node as RTSCamera).edge_pan_enabled = GameSettings.edge_pan
	elif (node.name == &"Skirmish" or node.name == &"LayoutLevel") and node.get_parent() == node.get_tree().root:
		# MT9: a reloaded LayoutLevel (restart / F9) gets its map back before its _ready
		if node.name == &"LayoutLevel" and map_layout_path != "" and &"layout_path" in node \
				and String(node.get(&"layout_path")) == "" and node.get(&"layout") == null:
			node.set(&"layout_path", map_layout_path)
		GameSettings.apply_trade(node)   # restart / reload: keep the trade setting
		GameSettings.apply_time_limit(node)   # and the time limit (16a)
		if _enemy_chosen:
			apply_kingdoms(node)   # restart / reload: keep the chosen kingdoms
	elif node.name == &"WaveStrike" and node.get_parent() == node.get_tree().root and &"autopilot_player" in node:
		_apply_wave_strike(node)   # F9 / Restart: same kingdom and bot
	elif difficulty >= 0 and node is Commander and node.name == BOT_NODE:
		(node as Commander).difficulty = difficulty as Commander.Difficulty
