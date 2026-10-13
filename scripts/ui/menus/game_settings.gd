class_name GameSettings
extends RefCounted
## Player settings shared by the main menu and the pause menu (task 5.U1): volumes, fullscreen, upscaler,
## edge-pan, UI scale and the control scheme (UX.1). Saved to user://settings.cfg, applied at start (GameSettings.ensure_loaded).
## Audio buses "Music" and "SFX" are created at runtime when the project has none.

const PATH := "user://settings.cfg"
const TEST_PATH := "user://settings_test.cfg"   ## use_test_file(): tests never read or write the player's file.
## The file load / save use (PATH; a test switches it to TEST_PATH so a player's saved map, keys... never leak in).
static var settings_path := PATH
const SECTION := "settings"
const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_VOICE := &"Voice"   ## Unit barks + dialogue voices; sent to SFX.
const UI_SCALE_MIN := 0.75
const UI_SCALE_MAX := 1.5

static var master_volume := 1.0   ## 0-1 (linear).
static var music_volume := 0.8
static var sfx_volume := 1.0
static var fullscreen := false
static var edge_pan := true
static var ui_scale := 1.0
## Skirmish option "Trade and guilds" (market-trade.md 8, ui-trade.md 14.4): posts, Bazaars, caravans, Magpies and
## the Greywater Lodges. Set on the Skirmish before it enters the tree (`apply_trade`); missions ignore it.
static var trade_enabled := true
## Skirmish option "Time limit" (step 16a): 0 = off, else minutes (TIME_LIMIT_CHOICES). At the limit the match ends
## and the higher score wins. Set on the Skirmish as `time_limit_s` before it enters the tree (`apply_time_limit`).
static var time_limit_min := 0
const TIME_LIMIT_CHOICES: Array[int] = [0, 30, 45]
## Skirmish option "Pace" (docs/balance/faster_games_2026-10-06.md, A2): false = Normal (default), true = Fast (test):
## the A2 values applied in memory at match start (PaceSwitch). Set on the Skirmish as `fast_pace` (`apply_pace`).
static var pace_fast := false
## Skirmish option "Pace: Blitz" (docs/balance/blitz_2026-10-10.md, PaceSwitch.BLITZ): 9 workers, quick games
## (8-12 min). Off by default; wins over pace_fast (the menu keeps only one on). Set on the Skirmish as `blitz_pace`.
static var pace_blitz := false
## Skirmish map (MT9, map-production.md 2.8): a MapCatalog id (&"crown_hollow" default) or &"random" (resolved to a
## ready map of the picker's seat filter at start). The menu's map picker sets it; MenuFlow.start_skirmish reads it.
static var map_id: StringName = &"crown_hollow"
## U5-3: the map picker's seat filter (2 = 1v1, 4 = 2v2), saved so a saved "Random 2v2" comes back as 2v2.
static var map_seats := 2
## Control scheme (task UX.1), read live by SelectionManager, WizardControl, the HUD help and the command card:
## - CONTROLS_CLASSIC (default, Warcraft III / LoL style): right click moves the wizard like any unit, no W A S D
##   walk; physical A then left click = attack-move (X too); camera = arrow keys + screen edge.
## - CONTROLS_HERO_WASD: W A S D walk the wizard (camera follows), X then left click = attack-move; A = walk left.
## - CONTROLS_RTS_WASD: like Classic (right click moves the wizard), but W A S D pan the camera (RTSCamera, Shift =
##   faster; arrows / edge still pan) and X then left click = attack-move (A = pan left).
static var control_scheme := CONTROLS_CLASSIC
## Map detail (step 12, ui-mapfill.md 11): &"high" (default) or &"low". Read at match start by MapDressingArt (Low
## halves the decor), CritterSystem (Low = no cosmetic critters; deer and rabbits stay) and the water material (Low =
## simpler water). Changing it mid-match only changes the saved value: it applies from the next match.
const MAP_DETAIL_HIGH := &"high"
const MAP_DETAIL_LOW := &"low"
static var map_detail: StringName = MAP_DETAIL_HIGH
## Settings "Playtest data" (docs/design/health-and-playtests.md): OFF by default. When on, every match (skirmish,
## missions) writes a compact local timeline to user://playtests/ (no personal data; never sent anywhere). Mirrors
## ReplayHooks.playtest_enabled, which the recorder hook reads.
static var playtest_data := false
const _REPLAY_HOOKS := preload("res://scripts/core/replay/replay_hooks.gd")
## Language (docs/design/localization.md): "en" / "fr", or "" = not chosen yet (first run: the OS locale, then saved).
## Applied live by `apply` / `set_language` (Loc.set_language). Scripted runs (tests, labs) stay English (Loc).
static var language := ""
## Upscaler + render scale of the game's 3D (root viewport only; the menu diorama, portraits and labs keep their own
## SubViewport settings). Off = native resolution with the project's MSAA. FSR 1 = cheap spatial upscale (softer).
## FSR 2 = temporal upscale + anti-aliasing (replaces MSAA, sharper than FSR 1; at 100 % it is native-res AA only).
## Both FSR modes need the Forward+ renderer; on another renderer they fall back to bilinear.
## Command-line override for tests and the Perf Lab (not saved):  -- --upscaler=off|fsr1|fsr2 --render-scale=0.67
const UPSCALER_OFF := 0
const UPSCALER_FSR1 := 1
const UPSCALER_FSR2 := 2
const UPSCALER_IDS: Array[String] = ["off", "fsr1", "fsr2"]
const UPSCALER_NAMES: Array[String] = ["Off (native)", "FSR 1 (fast)", "FSR 2 (best quality)"]
const RENDER_SCALE_MIN := 0.5
const RENDER_SCALE_MAX := 1.0
const RENDER_SCALE_DEFAULT := 0.77   ## FSR "Quality" preset is 0.67, "Ultra Quality" 0.77.
static var upscaler := UPSCALER_OFF
static var render_scale := RENDER_SCALE_DEFAULT
static var _loaded := false

const CONTROLS_CLASSIC := 0
const CONTROLS_HERO_WASD := 1
const CONTROLS_RTS_WASD := 2
## Saved values, index = the scheme.
const CONTROL_SCHEME_IDS: Array[String] = ["classic", "hero_wasd", "rts_wasd"]
const CONTROL_SCHEME_NAMES: Array[String] = ["Classic", "Hero WASD", "RTS camera (WASD)"]


## Loads the file once per run and applies it. Safe to call from every menu and level.
static func ensure_loaded(tree: SceneTree) -> void:
	if not _loaded:
		load_settings()
	apply(tree)


## Tests: load / save a throwaway file from now on (deleted first), every setting at its default (map Crown Hollow).
static func use_test_file() -> void:
	settings_path = TEST_PATH
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	reset_defaults()
	unit_priority_order.clear()
	_loaded = true


static func reset_defaults() -> void:
	master_volume = 1.0
	music_volume = 0.8
	sfx_volume = 1.0
	fullscreen = false
	edge_pan = true
	ui_scale = 1.0
	trade_enabled = true
	time_limit_min = 0
	pace_fast = false
	pace_blitz = false
	map_id = &"crown_hollow"
	map_seats = 2
	control_scheme = CONTROLS_CLASSIC
	map_detail = MAP_DETAIL_HIGH
	set_playtest_data(false, false)
	upscaler = UPSCALER_OFF
	render_scale = RENDER_SCALE_DEFAULT
	language = ""


## Sets the Map detail (&"high" / &"low"; anything else = high) and saves the file. Applies from the next match.
static func set_map_detail(value: StringName) -> void:
	if not _loaded:
		load_settings()
	map_detail = map_detail_from_id(String(value))
	save_settings()


## "high" / "low" (saved text) -> the StringName; unknown text = high.
static func map_detail_from_id(id: String) -> StringName:
	return MAP_DETAIL_LOW if id.strip_edges().to_lower() == "low" else MAP_DETAIL_HIGH


## Reads user://settings.cfg once per run without applying anything (the level's input code calls it so the saved
## control scheme is known even when the level is started without the main menu).
static func ensure_read() -> void:
	if not _loaded:
		load_settings()


## Sets the control scheme (CONTROLS_CLASSIC / CONTROLS_HERO_WASD / CONTROLS_RTS_WASD); it applies at once. `save`
## writes the file.
static func set_control_scheme(value: int, save := true) -> void:
	ensure_read()
	control_scheme = clampi(value, CONTROLS_CLASSIC, CONTROLS_RTS_WASD)
	if save:
		save_settings()


## True in the Hero WASD scheme (W A S D walk the wizard).
static func hero_wasd() -> bool:
	return control_scheme == CONTROLS_HERO_WASD


## True in the RTS camera (WASD) scheme (W A S D pan the camera, RTSCamera reads them).
static func rts_wasd() -> bool:
	return control_scheme == CONTROLS_RTS_WASD


## The physical keys that start attack-move targeting: Classic A and X, Hero WASD / RTS WASD X only.
static func attack_move_keys() -> Array[Key]:
	if hero_wasd() or rts_wasd():
		return [KEY_X]
	return [KEY_A, KEY_X]


## The attack-move key shown in the help and on the command card (Classic A, Hero WASD / RTS WASD X).
static func attack_move_key() -> Key:
	return KEY_X if hero_wasd() or rts_wasd() else KEY_A


## "classic" / "hero_wasd" / "rts_wasd" (saved text) -> the scheme; unknown = Classic.
static func control_scheme_from_id(id: String) -> int:
	var i := CONTROL_SCHEME_IDS.find(id)
	return i if i >= 0 else CONTROLS_CLASSIC


## Sets the "Trade and guilds" option and saves the file (the skirmish setup screen's On / Off row).
static func set_trade_enabled(value: bool) -> void:
	if not _loaded:
		load_settings()
	trade_enabled = value
	save_settings()


## Sets `trade_enabled` on a skirmish level when it has that property (before it enters the tree; the restart hook
## calls it again). True if set.
static func apply_trade(level: Node) -> bool:
	if level == null or not (&"trade_enabled" in level):
		return false
	level.set(&"trade_enabled", trade_enabled)
	return true


## Sets the "Time limit" option (minutes: 0 = off, 30, 45; anything else = off) and saves the file.
static func set_time_limit(minutes: int) -> void:
	if not _loaded:
		load_settings()
	time_limit_min = minutes if TIME_LIMIT_CHOICES.has(minutes) else 0
	save_settings()


## Sets the "Pace" option (false = Normal, true = Fast (test)) and saves the file.
static func set_pace_fast(on: bool) -> void:
	if not _loaded:
		load_settings()
	pace_fast = on
	pace_blitz = false
	save_settings()


## Pace choices of the menu row, in order: Normal, Fast (test), Blitz.
const PACE_NORMAL := 0
const PACE_FAST := 1
const PACE_BLITZ := 2


## The current Pace choice (PACE_NORMAL / PACE_FAST / PACE_BLITZ).
static func pace_mode() -> int:
	return PACE_BLITZ if pace_blitz else (PACE_FAST if pace_fast else PACE_NORMAL)


## Sets the Pace choice (one of PACE_*) and saves the file.
static func set_pace_mode(mode: int) -> void:
	if not _loaded:
		load_settings()
	pace_fast = mode == PACE_FAST
	pace_blitz = mode == PACE_BLITZ
	save_settings()


## Sets `fast_pace` on a skirmish level when it has that property (before it enters the tree; the restart hook
## calls it again). True if set.
static func apply_pace(level: Node) -> bool:
	if level == null or not (&"fast_pace" in level):
		return false
	level.set(&"fast_pace", pace_fast and not pace_blitz)
	if &"blitz_pace" in level:
		level.set(&"blitz_pace", pace_blitz)
	return true


## Sets the skirmish map (a MapCatalog id or &"random"; empty = Crown Hollow) and saves the file.
## `seats` > 0 also sets the seat filter (2 = 1v1, 4 = 2v2; U5-3).
static func set_map_id(value: StringName, save := true, seats := 0) -> void:
	if not _loaded:
		load_settings()
	map_id = value if value != &"" else &"crown_hollow"
	if seats > 0:
		map_seats = 4 if seats >= 4 else 2
	if save:
		save_settings()


## Sets `time_limit_s` on a skirmish level when it has that property (before it enters the tree; the restart hook
## calls it again). True if set.
static func apply_time_limit(level: Node) -> bool:
	if level == null or not (&"time_limit_s" in level):
		return false
	level.set(&"time_limit_s", float(time_limit_min) * 60.0)
	return true


## Reads user://settings.cfg (missing file or keys = defaults).
## Settings "Playtest data": on = record each match to user://playtests/ (applies from the next match start).
static func set_playtest_data(on: bool, save := true) -> void:
	playtest_data = on
	_REPLAY_HOOKS.playtest_enabled = on
	if save:
		save_settings()


static func load_settings() -> void:
	reset_defaults()
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) != OK:
		return
	master_volume = clampf(float(cfg.get_value(SECTION, "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value(SECTION, "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value(SECTION, "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value(SECTION, "fullscreen", fullscreen))
	edge_pan = bool(cfg.get_value(SECTION, "edge_pan", edge_pan))
	ui_scale = clampf(float(cfg.get_value(SECTION, "ui_scale", ui_scale)), UI_SCALE_MIN, UI_SCALE_MAX)
	trade_enabled = bool(cfg.get_value(SECTION, "trade_enabled", trade_enabled))
	var limit := int(cfg.get_value(SECTION, "time_limit_min", time_limit_min))
	time_limit_min = limit if TIME_LIMIT_CHOICES.has(limit) else 0
	pace_fast = bool(cfg.get_value(SECTION, "pace_fast", false))
	pace_blitz = bool(cfg.get_value(SECTION, "pace_blitz", false))
	var saved_map := str(cfg.get_value(SECTION, "map_id", String(map_id))).strip_edges()
	map_id = StringName(saved_map) if saved_map != "" else &"crown_hollow"
	map_seats = 4 if int(cfg.get_value(SECTION, "map_seats", 2)) >= 4 else 2
	control_scheme = control_scheme_from_id(str(cfg.get_value(SECTION, "control_scheme",
			CONTROL_SCHEME_IDS[CONTROLS_CLASSIC])))
	map_detail = map_detail_from_id(str(cfg.get_value(SECTION, "map_detail", String(MAP_DETAIL_HIGH))))
	set_playtest_data(bool(cfg.get_value(SECTION, "playtest_data", false)), false)
	upscaler = upscaler_from_id(str(cfg.get_value(SECTION, "upscaler", UPSCALER_IDS[UPSCALER_OFF])))
	render_scale = clampf(float(cfg.get_value(SECTION, "render_scale", render_scale)), RENDER_SCALE_MIN,
			RENDER_SCALE_MAX)
	var lang := str(cfg.get_value(SECTION, "language", "")).strip_edges().to_lower()
	language = lang if Loc.LANGS.has(lang) else ""
	unit_priority_order.clear()
	var order: Variant = cfg.get_value(SECTION, "unit_priority", [])
	if order is Array:
		for k in order:
			unit_priority_order.append(StringName(str(k)))


## Settings > Controls "Unit priority": the saved Tab / active-subgroup order of unit type keys ("wizard" or a
## UnitType id). Empty = the default (wizard, heroes, dearer soldiers first, workers last; SelectionManager).
static var unit_priority_order: Array[StringName] = []


static func unit_priority() -> Array[StringName]:
	ensure_read()
	return unit_priority_order


## Stores a full order (the settings list after + / -); `save` writes the file.
static func set_unit_priority(order: Array, save := true) -> void:
	ensure_read()
	unit_priority_order.clear()
	for k in order:
		unit_priority_order.append(StringName(str(k)))
	if save:
		save_settings()


## Moves `key` one place up (`step` -1, the "+" button) or down (+1, "−") in `order` (the list as shown) and saves.
## Returns the new order.
static func move_unit_priority(order: Array, key: StringName, step: int, save := true) -> Array[StringName]:
	var out: Array[StringName] = []
	for k in order:
		out.append(StringName(str(k)))
	var i := out.find(key)
	var j := i + step
	if i >= 0 and j >= 0 and j < out.size():
		out[i] = out[j]
		out[j] = key
	set_unit_priority(out, save)
	return out


## "Reset": back to the default order.
static func reset_unit_priority(save := true) -> void:
	set_unit_priority([], save)


static func save_settings() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "master_volume", master_volume)
	cfg.set_value(SECTION, "music_volume", music_volume)
	cfg.set_value(SECTION, "sfx_volume", sfx_volume)
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	cfg.set_value(SECTION, "edge_pan", edge_pan)
	cfg.set_value(SECTION, "ui_scale", ui_scale)
	cfg.set_value(SECTION, "trade_enabled", trade_enabled)
	cfg.set_value(SECTION, "time_limit_min", time_limit_min)
	cfg.set_value(SECTION, "pace_fast", pace_fast)
	cfg.set_value(SECTION, "pace_blitz", pace_blitz)
	cfg.set_value(SECTION, "map_id", String(map_id))
	cfg.set_value(SECTION, "map_seats", map_seats)
	cfg.set_value(SECTION, "control_scheme", CONTROL_SCHEME_IDS[clampi(control_scheme, 0, CONTROL_SCHEME_IDS.size() - 1)])
	cfg.set_value(SECTION, "map_detail", String(map_detail_from_id(String(map_detail))))
	cfg.set_value(SECTION, "playtest_data", playtest_data)
	cfg.set_value(SECTION, "upscaler", UPSCALER_IDS[clampi(upscaler, UPSCALER_OFF, UPSCALER_FSR2)])
	cfg.set_value(SECTION, "render_scale", render_scale)
	cfg.set_value(SECTION, "language", language)
	var order: Array[String] = []
	for k in unit_priority_order:
		order.append(String(k))
	cfg.set_value(SECTION, "unit_priority", order)
	return cfg.save(settings_path)


static func apply(tree: SceneTree) -> void:
	apply_language()
	apply_audio()
	apply_window(tree)
	apply_edge_pan(tree.root if tree else null)
	if tree and tree.root:
		var o := render_overrides()
		apply_render(tree.root, int(o.get("upscaler", upscaler)), float(o.get("render_scale", render_scale)))


## Sets the game language ("en" / "fr"; it switches live: auto-translated text redraws, screens refresh on
## NOTIFICATION_TRANSLATION_CHANGED). `save` writes the file.
static func set_language(lang: String, save := true) -> void:
	ensure_read()
	language = lang if Loc.LANGS.has(lang) else Loc.DEFAULT_LANG
	_language_applied = true
	if Loc.language != language:
		Loc.set_language(language)
	if save:
		save_settings()


static var _language_applied := false


## Applies the saved language once per run (set_language switches it later). First run (language ""): the OS locale is
## chosen and saved, so the game keeps it.
static func apply_language() -> void:
	var lang := Loc.resolve_setting(language)
	if _language_applied:
		return
	_language_applied = true
	Loc.set_language(lang)
	if language == "" and not Loc.is_scripted_run() and settings_path == PATH:
		language = lang
		save_settings()


## "off" / "fsr1" / "fsr2" (saved or command-line text) -> the mode; unknown = Off.
static func upscaler_from_id(id: String) -> int:
	var i := UPSCALER_IDS.find(id.strip_edges().to_lower())
	return i if i >= 0 else UPSCALER_OFF


## The --upscaler= / --render-scale= command-line values (after `--`), only the keys given.
static func render_overrides() -> Dictionary:
	var o := {}
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--upscaler="):
			o["upscaler"] = upscaler_from_id(a.get_slice("=", 1))
		elif a.begins_with("--render-scale="):
			o["render_scale"] = clampf(a.get_slice("=", 1).to_float(), RENDER_SCALE_MIN, RENDER_SCALE_MAX)
	return o


## The 3D render scale the root viewport gets for these settings (Off = 1.0).
static func effective_render_scale(mode: int, scale: float) -> float:
	return 1.0 if mode == UPSCALER_OFF else clampf(scale, RENDER_SCALE_MIN, RENDER_SCALE_MAX)


## Sets the upscaler, render scale and MSAA of one viewport. FSR 2 does its own anti-aliasing, so MSAA is turned
## off with it (MSAA + FSR 2 is not supported); Off and FSR 1 keep the project's MSAA.
static func apply_render(vp: Viewport, mode: int, scale: float) -> void:
	if vp == null:
		return
	mode = clampi(mode, UPSCALER_OFF, UPSCALER_FSR2)
	var s := effective_render_scale(mode, scale)
	var forward_plus := RenderingServer.get_current_rendering_method() == "forward_plus"
	var project_msaa := int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", 0))
	if mode == UPSCALER_OFF or not forward_plus:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	elif mode == UPSCALER_FSR1:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	else:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	vp.scaling_3d_scale = s
	if mode == UPSCALER_FSR2 and forward_plus:
		vp.msaa_3d = Viewport.MSAA_DISABLED
	else:
		vp.msaa_3d = project_msaa as Viewport.MSAA


## Creates the Music / SFX buses (sent to Master) if the project has none.
static func ensure_buses() -> void:
	for bus_name: StringName in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, BUS_MASTER)
	# Unit voice barks (UnitVoice) + dialogue voices (VoicePlayer): their own bus, sent through SFX so the SFX slider
	# scales them too.
	if AudioServer.get_bus_index(BUS_VOICE) == -1:
		AudioServer.add_bus()
		var vidx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(vidx, BUS_VOICE)
		AudioServer.set_bus_send(vidx, BUS_SFX)


static func apply_audio() -> void:
	ensure_buses()
	_set_bus_volume(BUS_MASTER, master_volume)
	_set_bus_volume(BUS_MUSIC, music_volume)
	_set_bus_volume(BUS_SFX, sfx_volume)


static func apply_window(tree: SceneTree) -> void:
	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen and not is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if tree and tree.root:
		tree.root.content_scale_factor = ui_scale


## Sets edge-pan on every RTSCamera under `node` (or on `node` itself).
static func apply_edge_pan(node: Node) -> void:
	if node == null:
		return
	if node is RTSCamera:
		(node as RTSCamera).edge_pan_enabled = edge_pan
	for child in node.get_children():
		apply_edge_pan(child)


static func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)
