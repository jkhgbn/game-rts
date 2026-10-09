class_name StoryFilms
extends RefCounted
## Story films between missions (the StoryFlow part a reward's `"next"` needs; mission-framework.md 6 lists the full
## StoryFlow as not built): a film id in `CampaignState.STORY_FILMS` plays its stage scene
## (`scenes/cinematics/<id>.tscn`, a CinematicStage written by tools/cine/cine_stage_export.gd), then the film or mission
## that follows it. A film whose stage does not exist yet is skipped (the chain goes on). Watched films are marked seen.
## e2m5's victory "Continue" -> `ep2_ending` -> `ep3_opening` -> e3m1.

const STAGE_DIR := "res://scenes/cinematics/"


static func stage_of(id: StringName) -> String:
	return "%s%s.tscn" % [STAGE_DIR, id]


## True when the film's stage scene exists.
static func available(id: StringName) -> bool:
	return ResourceLoader.exists(stage_of(id))


## The episode opening film that plays right before `mission_id` (a STORY_FILMS entry whose next is that mission:
## ep3_opening -> e3m1), &"" when none. The campaign menu plays it before the mission until it is seen.
static func opening_of(mission_id: StringName) -> StringName:
	for f: StringName in CampaignState.STORY_FILMS:
		if CampaignState.film_next(f) == StringName(mission_id):
			return f
	return &""


## The film the campaign's flags pick in place of `id` (CampaignState.FILM_BRANCHES: c_e6_gate -> c_e6_gate_shut when
## e6m2_gate_opened is false), else `id` itself. A flag missing from the save keeps `id`.
static func branch_of(id: StringName) -> StringName:
	var row: Variant = CampaignState.FILM_BRANCHES.get(StringName(id))
	if not row is Array:
		return id
	var flags := CampaignState.open().flags
	var key := String((row as Array)[0])
	if flags.has(key) and flags[key] == (row as Array)[1]:
		return StringName((row as Array)[2])
	return id


## Plays the film `id` alone (Campaign menu "Watch opening"), marks it seen, then back to the main menu.
static func play_only(tree: SceneTree, id: StringName) -> Node:
	return play_chain(tree, id, 1, true)


## Plays the film `id` full screen, then what follows it (CampaignState.film_next): another film, a mission (started
## with `bot_difficulty`), or the main menu (always the menu when `menu_after`). Returns the new current scene (null
## when nothing could start).
static func play_chain(tree: SceneTree, id: StringName, bot_difficulty: int = 1, menu_after := false) -> Node:
	id = branch_of(id)
	var next := &"" if menu_after else CampaignState.film_next(id)
	if not available(id):
		return continue_to(tree, next, bot_difficulty)
	var stage := (load(stage_of(id)) as PackedScene).instantiate()
	if &"quit_when_done" in stage:
		stage.set(&"quit_when_done", false)
	if stage.has_signal(&"cinematic_done"):
		stage.connect(&"cinematic_done", func(fid: StringName, _skipped: bool) -> void:
			CampaignState.open().mark_seen(fid)
			continue_to(tree, next, bot_difficulty), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	tree.paused = false
	MenuFlow.set_scene(tree, stage)   # the old scene leaves the tree first (review 2026-10-08)
	return stage


## The next step of a chain: a film (played), a mission id (its scene started), else back to the main menu.
static func continue_to(tree: SceneTree, id: StringName, bot_difficulty: int = 1) -> Node:
	if id != &"" and CampaignState.is_film(id):
		return play_chain(tree, id, bot_difficulty)
	var path := CampaignState.mission_scene(id) if id != &"" else ""
	if path != "" and ResourceLoader.exists(path):
		return MenuFlow.start_mission(tree, path, bot_difficulty)
	MenuFlow.quit_to_menu(tree)
	return null
