class_name MenuFlow
extends RefCounted
## Scene flow between the menus and the 1v1 (task 5.U1): start a skirmish with a bot difficulty,
## restart it, go back to the main menu. The chosen difficulty survives restarts (pause menu or F9):
## a SceneTree.node_added hook sets it on the "ShadowBot" Commander before its _ready, and sets
## the edge-pan setting on every RTSCamera that enters the tree.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const SKIRMISH := "res://scenes/skirmish.tscn"
const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"   ## Skirmish.kingdom_available(k) (8.S2).
const BOT_NODE := &"ShadowBot"

static var difficulty := -1                  ## Commander.Difficulty chosen in the menu (-1 = none yet).
## The player's kingdom (8.U1): &"fire" / &"shadow" / &"ice" / &"nature". Set on the Skirmish node as
## `player_kingdom` before it enters the tree (and again by the hook on restarts).
static var player_kingdom: StringName = &"fire"
static var kingdom: StringName = &"fire"     ## Legacy alias of player_kingdom (kept in sync).
## The skirmish opponent (7.U1, any of the 4 kingdoms since 8.U1, mirror allowed). Set on the Skirmish
## node before it enters the tree (and again by the hook on restarts).
static var enemy_kingdom: StringName = &"shadow"
static var _enemy_chosen := false             ## True once the menu picked the kingdoms.
static var _hooked_tree: SceneTree = null


## Instances skirmish.tscn, sets the bot's difficulty and both kingdoms before it enters the tree,
## and makes it the current scene (the old one is freed). Returns the new level.
static func start_skirmish(tree: SceneTree, bot_difficulty: int, enemy: StringName = &"",
		player: StringName = &"") -> Node:
	difficulty = bot_difficulty
	if enemy != &"":
		enemy_kingdom = enemy
		_enemy_chosen = true
	if player != &"":
		player_kingdom = player
		kingdom = player
		_enemy_chosen = true
	install_hooks(tree)
	var level := (load(SKIRMISH) as PackedScene).instantiate()
	apply_kingdoms(level)
	GameSettings.apply_trade(level)
	GameSettings.apply_time_limit(level)
	return _launch(tree, level, bot_difficulty)


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
	elif node.name == &"Skirmish" and node.get_parent() == node.get_tree().root:
		GameSettings.apply_trade(node)   # restart / reload: keep the trade setting
		GameSettings.apply_time_limit(node)   # and the time limit (16a)
		if _enemy_chosen:
			apply_kingdoms(node)   # restart / reload: keep the chosen kingdoms
	elif difficulty >= 0 and node is Commander and node.name == BOT_NODE:
		(node as Commander).difficulty = difficulty as Commander.Difficulty
