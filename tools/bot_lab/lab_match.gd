extends SceneTree
## Bot Lab (docs/plan/bot-lab.md): ONE bot-vs-bot match on scenes/skirmish.tscn, both sides normal Commanders, run
## headless as fast as the CPU allows, then one JSON line: printed as "LAB_RESULT {...}" and written to --out.
## Launched by tools/bot_lab/run_lab.ps1 (many in parallel); runnable alone:
##   godot --headless --path <dir> -s tools/bot_lab/lab_match.gd --fixed-fps 60 --quit-after 118000 -- \
##       --pair=fire:shadow --seed=1 --difficulty=normal --style=balanced --sim=1 --out=C:/tmp/m.json
## User args (after "--", all optional):
##   --pair=P:E            player (south-west) and enemy kingdoms: fire / shadow / ice / nature (default fire:shadow)
##   --seed=N              seeds the match's random systems (global rng, camp / beast / thief / critter rngs, champions)
##   --difficulty=D        easy / normal / hard, or per side "player:hard,enemy:normal"
##   --style=S             balanced / rusher / random, or per side (applied only if the bot supports styles)
##   --sim=1               sim mode (scripts/core/sim_mode.gd): no art, VFX, audio, decor; gameplay unchanged
##                         (--sim-hooks=0: only the per-frame part done here, as on a commit without sim_mode.gd)
##   --limit=1800          time limit in game seconds: the match ends there on score ("time-score")
##   --early=1             early stop on a clear score lead: --early-ratio=1.5 --early-margin=3000 (ScoreKeeper points;
##                         1500 with the fallback score) --early-hold=180 --early-min=480 (game seconds)
##   --stall=300           ends as "stall" after this many game seconds with no kill and no crystal mined (0 = off)
##   --tick=60             physics ticks per second (the runner passes the same --fixed-fps); 60 = the game's rate
##   --ui=off              HUD, camera, selection and pause menu stop processing (they still exist; lab experiment)
##   --bake=real           (default) while a navmesh rebake runs, frames are paced at real time, so the rebake lands
##                         after as much game time as in a real game; --bake=fast = no pacing (docs/plan/bot-lab.md)
##   --out=PATH            the JSON line is written there (one file per match)
##   --profile=1           one perf line per game minute;  --log=1  the bots' decision logs
##   --commit=ID           copied into the JSON (the runner reads the lab worktree's HEAD)
## End reasons: kill (every enemy building down), concede (the bot surrendered), early-score, time-score, stall, cap
## (frame cap reached: should not happen). Winner on score = the higher ScoreKeeper total (group "score",
## scripts/world/score_keeper.gd, load-guarded; created here if the skirmish has none), else the fallback score:
## army value + economy value (bank + buildings + workers + half the crystals gathered).
## Test-script rules (CLAUDE.md): compiled before autoloads; untyped access to anything newer than the lab's commit.

const SCENE := "res://scenes/skirmish.tscn"
const LAYOUT_SCENE := "res://scenes/layout_level.tscn"
const COMMANDER_PATH := "res://scripts/ai/commander.gd"
const SIM_MODE_PATH := "res://scripts/core/sim_mode.gd"
const SCORE_KEEPER_PATH := "res://scripts/world/score_keeper.gd"
const AI_PROFILE_PATH := "res://scripts/ai/ai_profile.gd"
const KINGDOMS: Array[String] = ["fire", "shadow", "ice", "nature"]
const DIFFICULTIES := {"easy": 0, "normal": 1, "hard": 2}
const PLAYER := 0
const ENEMY := 1
const SIDES := ["player", "enemy"]
## Level children that only draw or play sound (found by the game through groups, never required).
const SIM_STRIP_NAMES: Array[String] = ["SpellVfx", "CombatVfx", "IceVfx", "NatureVfx", "ChampionVfx", "TradeVfx",
		"MapFillVfx", "TitanVfx", "UnitVfx", "GameAudio", "Horizon"]
const SNAPSHOT_TIMES: Array[int] = [180, 300, 420, 600, 900, 1200]
const DEAD_HOLD := 120.0         ## Both sides without a worker or a soldier this long: "stall" (flag both_dead).
const WORKER_VALUE := 50
const KEEP_VALUE := 400

var args := {}
var main: Node
var bots: Array = [null, null]
var kingdoms: Array[String] = ["fire", "shadow"]
var seed_value := 1
var difficulty: Array[String] = ["normal", "normal"]
var style: Array[String] = ["balanced", "balanced"]
var style_applied := [false, false]
var sim := false
var sim_supported := false
var tick := 60
var limit := 1800.0
var early := true
var early_ratio := 1.5
var early_margin := -1.0
var early_hold := 180.0
var early_min := 480.0
var stall_s := 300.0
var ui_off := false
var bake_real := false
var profile := false
var out_path := ""

var _t_init := 0
var _t_loaded := 0            # usec: scene loaded and instanced
var _t_built := 0             # usec: level _ready done (map built, navmesh bake started)
var _t_start := 0             # usec at match start (navmesh ready)
var _frames := 0
var _frames_at_start := 0
var _wait_frames := 0
var _started := false
var _finished := false
var _cap_frames := 0
var _next_sample := 0.0
var _score_node: Node = null
var _score_source := "fallback"
var _stats := [{}, {}]        # per team: peaks and running values
var _snapshots := {}
var _lead_team := -1
var _lead_since := -1.0
var _early_call := {}
var _last_activity := 0.0     # game time of the last kill / crystal mined
var _max_quiet := 0.0
var _gathered_last := [0, 0]
var _kills_seen := 0
var _flags := {}
var _workerless_since := [-1.0, -1.0]
var _dead_since := -1.0
var _float_since := [-1.0, -1.0]
var _rng_counter := 0
var _bake_count := 0
var _bake_usec := 0
var _bake_start := 0
var _baking := false
var _perf_acc := {"frames": 0, "usec": 0}
var _frame_usec := 0
var _frozen := 0
var _ablate_at := -1.0
var _ablate_items: Array = []   # [label, Callable(off: bool)]
var _ablate_i := -1
var _ablate_frames := 0
var _ablate_usec := 0
var _ablate_rows: Array[String] = []
var _ablate_base: Array[float] = []


func _initialize() -> void:
	_t_init = Time.get_ticks_usec()
	_parse_args()
	seed(seed_value * 7919 + 17)
	Engine.physics_ticks_per_second = tick
	if sim:
		var sm: Script = load(SIM_MODE_PATH) as Script \
				if ResourceLoader.exists(SIM_MODE_PATH) and _flag("sim-hooks", true) else null
		if sm != null:
			sm.set(&"enabled", true)
			sim_supported = true   # "full": the build-time hooks too; else "partial" (per-frame savings only)
		if not args.has("ui"):
			ui_off = true
	# --layout=<_layout.tres or .map> (map-production.md MT2 / MT8): the match runs on scenes/layout_level.tscn with
	# that layout (--scene= overrides the scene). Default: Crown Hollow (scenes/skirmish.tscn).
	var scene_path := String(args.get("scene", LAYOUT_SCENE if args.has("layout") else SCENE))
	var packed := load(scene_path) as PackedScene
	main = packed.instantiate()
	if args.has("layout") and &"layout_path" in main:
		main.set(&"layout_path", String(args["layout"]))
	main.set(&"player_kingdom", StringName(kingdoms[PLAYER]))
	main.set(&"enemy_kingdom", StringName(kingdoms[ENEMY]))
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)   # the lab decides the end itself (same rule on every commit)
	if sim:
		for child in main.get_children():
			if SIM_STRIP_NAMES.has(String(child.name)):
				main.remove_child(child)
				child.free()
	# Both bots: the scene's own (ENEMY) and one more for the PLAYER, set up before they enter the tree.
	var commander_script := load(COMMANDER_PATH) as Script
	for child in main.get_children():
		if child.get_script() == commander_script:
			bots[int(child.get(&"team"))] = child
	for team in [PLAYER, ENEMY]:
		if bots[team] == null:
			var b: Node = commander_script.new()
			b.name = "LabBot%d" % team
			b.set(&"team", team)
			main.add_child(b)
			bots[team] = b
		_setup_bot(bots[team], team)
	node_added.connect(_on_node_added)
	_t_loaded = Time.get_ticks_usec()
	root.add_child(main)
	current_scene = main
	_t_built = Time.get_ticks_usec()
	if ui_off:
		_quiet_ui()
	_cap_frames = String(args.get("cap-frames", str(int((limit + 240.0) * tick) + 6000))).to_int()
	print("LAB start %s:%s seed %d difficulty %s/%s style %s/%s sim %s tick %d ui %s" % [kingdoms[0], kingdoms[1],
			seed_value, difficulty[0], difficulty[1], style[0], style[1], _sim_text(), tick, "off" if ui_off else "on"])


func _sim_text() -> String:
	if not sim:
		return "off"
	return "full" if sim_supported else "partial"


## HUD, camera, selection and every other CanvasLayer stop processing and drawing (they still get their calls).
func _quiet_ui() -> void:
	for key: StringName in [&"hud", &"camera_rig", &"selection"]:
		var n: Variant = main.get(key)
		if n is Node and is_instance_valid(n):
			(n as Node).process_mode = Node.PROCESS_MODE_DISABLED
	for n in main.get_children():
		if n is CanvasLayer:
			n.process_mode = Node.PROCESS_MODE_DISABLED
			(n as CanvasLayer).visible = false


func _parse_args() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		if eq < 0:
			args[s] = "1"
		else:
			args[s.substr(0, eq)] = s.substr(eq + 1)
	var pair := String(args.get("pair", "fire:shadow")).to_lower().split(":")
	if pair.size() == 2 and KINGDOMS.has(pair[0]) and KINGDOMS.has(pair[1]):
		kingdoms = [pair[0], pair[1]]
	else:
		push_error("LAB: bad --pair=%s, using fire:shadow" % args.get("pair", ""))
	seed_value = String(args.get("seed", "1")).to_int()
	difficulty = _per_side(String(args.get("difficulty", "normal")), "normal")
	style = _per_side(String(args.get("style", "balanced")), "balanced")
	sim = _flag("sim", false)
	tick = clampi(String(args.get("tick", "60")).to_int(), 10, 240)
	limit = String(args.get("limit", "1800")).to_float()
	early = _flag("early", true)
	early_ratio = String(args.get("early-ratio", "1.5")).to_float()
	early_margin = String(args.get("early-margin", "-1")).to_float()
	early_hold = String(args.get("early-hold", "180")).to_float()
	early_min = String(args.get("early-min", "480")).to_float()
	stall_s = String(args.get("stall", "300")).to_float()
	ui_off = String(args.get("ui", "on")) == "off"
	bake_real = String(args.get("bake", "real")) == "real"
	profile = _flag("profile", false)
	out_path = String(args.get("out", ""))
	_ablate_at = String(args.get("ablate", "-1")).to_float()


func _flag(key: String, default: bool) -> bool:
	if not args.has(key):
		return default
	return ["1", "true", "on", "yes"].has(String(args[key]).to_lower())


## "hard" -> [hard, hard]; "player:hard,enemy:easy" -> [hard, easy].
func _per_side(text: String, default: String) -> Array[String]:
	var out: Array[String] = [default, default]
	text = text.to_lower()
	if not text.contains(":"):
		return [text, text]
	for part in text.split(","):
		var kv := part.split(":")
		if kv.size() == 2:
			out[PLAYER if kv[0] == "player" else ENEMY] = kv[1]
	return out


func _setup_bot(bot: Node, team: int) -> void:
	bot.set(&"difficulty", int(DIFFICULTIES.get(difficulty[team], 1)))
	bot.set(&"debug_log", _flag("log", false))
	var st := style[team]
	if st == "" or st == "balanced":
		style_applied[team] = true   # today's bot IS the balanced style
		return
	if &"style" in bot:   # a future Commander export
		bot.set(&"style", StringName(st))
		style_applied[team] = true
		return
	# rush-balance.md 6.1: AIProfile.apply_style(p, style, faction) on the kingdom preset, handed over as `profile`.
	var prof_script: Script = load(AI_PROFILE_PATH) as Script if ResourceLoader.exists(AI_PROFILE_PATH) else null
	if prof_script == null or not _has_static(prof_script, "apply_style"):
		push_warning("LAB: the bot has no styles yet, team %d plays balanced" % team)
		return
	var faction := StringName(kingdoms[team])
	var prof: Variant = prof_script.call(&"for_id", prof_script.call(&"id_for_faction", faction), bot.get(&"difficulty"))
	if prof == null:
		return
	var styled: Variant = prof_script.call(&"apply_style", prof, StringName(st), faction)
	bot.set(&"profile", styled if styled is Resource else prof)
	style_applied[team] = true


static func _has_static(script: Script, method: String) -> bool:
	for m: Dictionary in script.get_script_method_list():
		if String(m.get("name", "")) == method:
			return true
	return false


# ---------------------------------------------------------------- seeding

## Seeds every per-node RandomNumberGenerator the match creates (champions randomize theirs in _init / _ready);
## in sim mode, freezes the art scripts.
func _on_node_added(node: Node) -> void:
	if &"class_rng" in node or &"_rng" in node:
		node.ready.connect(_seed_node_rngs.bind(node), CONNECT_ONE_SHOT)
	if sim:
		_sim_freeze(node)


## Sim mode: nodes running an art script (res://art/, res://scripts/vfx/) stop processing. Their _ready and every
## hook call still run (same hooks, attack_windup, signals), only the per-frame animation stops. A model inside a
## Unit (signal died) or a Building (signal destroyed) wakes up when its owner dies, so death_finished /
## destroyed_finished (which free the corpse / ruin and its pop) come at their normal time. Art with signals of its
## own and no such owner keeps running (nothing is guessed).
func _sim_freeze(node: Node) -> void:
	var script := node.get_script() as Script
	if script == null:
		return
	var path := script.resource_path
	if not (path.begins_with("res://art/") or path.begins_with("res://scripts/vfx/")):
		return
	var owner_node: Node = null
	var p := node.get_parent()
	for i in 8:
		if p == null or p == main:
			break
		var ps := p.get_script() as Script
		if ps != null and not ps.resource_path.begins_with("res://art/") \
				and (p.has_signal(&"died") or p.has_signal(&"destroyed")):
			owner_node = p
			break
		p = p.get_parent()
	if owner_node == null:
		if not script.get_script_signal_list().is_empty():
			return
		node.process_mode = Node.PROCESS_MODE_DISABLED
		_frozen += 1
		return
	node.process_mode = Node.PROCESS_MODE_DISABLED
	_frozen += 1
	var sig := &"died" if owner_node.has_signal(&"died") else &"destroyed"
	owner_node.connect(sig, _wake.bind(node), CONNECT_ONE_SHOT)


func _wake(_who: Variant, node: Node) -> void:
	if is_instance_valid(node):
		node.process_mode = Node.PROCESS_MODE_INHERIT


func _seed_node_rngs(node: Node) -> void:
	for key: StringName in [&"class_rng", &"_rng", &"rng"]:
		if key in node:
			var r: Variant = node.get(key)
			if r is RandomNumberGenerator:
				_rng_counter += 1
				(r as RandomNumberGenerator).seed = hash([seed_value, _rng_counter, String(key)])


func _seed_services() -> void:
	for group: StringName in [&"thieves_guild", &"camp_manager", &"epic_beasts", &"critter_herds"]:
		for n in get_nodes_in_group(group):
			var r: Variant = n.get(&"rng")
			if r is RandomNumberGenerator:
				(r as RandomNumberGenerator).seed = hash([seed_value, String(group)])
	for n in main.get_children():
		if &"rng" in n and n.get(&"rng") is RandomNumberGenerator and n.has_signal(&"opened"):   # Lost Caches
			(n.get(&"rng") as RandomNumberGenerator).seed = hash([seed_value, String(n.name)])


# ---------------------------------------------------------------- frames

func _physics_process(_delta: float) -> bool:
	if main == null or not is_instance_valid(main) or not _started:
		return false
	var region: Variant = main.get(&"nav_region")
	if region == null or not is_instance_valid(region):
		return false
	var baking: bool = (region as NavigationRegion3D).is_baking()
	if baking and not _baking:
		_bake_start = Time.get_ticks_usec()
		_bake_count += 1
	elif not baking and _baking:
		_bake_usec += Time.get_ticks_usec() - _bake_start
	_baking = baking
	if baking and bake_real:   # real-time pace: the rebake lands after as much game time as in a real game
		var frame_len := 1000000 / tick
		var spent := Time.get_ticks_usec() - _frame_usec
		if spent < frame_len:
			OS.delay_usec(frame_len - spent)
	return false


func _process(_delta: float) -> bool:
	var now_usec := Time.get_ticks_usec()
	var frame_usec := now_usec - _frame_usec
	if profile and _started:
		_perf_acc["frames"] += 1
		_perf_acc["usec"] += frame_usec
	_frame_usec = now_usec
	_frames += 1
	if _finished:
		return true
	if main == null or not is_instance_valid(main):
		return true
	if not bool(main.get(&"match_started")):
		_wait_frames += 1
		if _wait_frames > 6000:
			return _finish("error", -1, "navigation never finished baking")
		return false
	if not _started:
		_on_match_started()
	var t: float = float(main.call(&"match_time"))
	if bool(main.get(&"game_over")):
		return _finish_game_over(t)
	if _frames >= _cap_frames:
		return _finish("cap", _score_leader(), "")
	if _ablate_at > 0.0 and t >= _ablate_at:
		return _ablate_step(frame_usec)
	if t >= _next_sample:
		_next_sample += 1.0
		var ended := _sample(t)
		if ended:
			return true
	if t >= limit:
		return _finish("time-score", _score_leader(), "")
	return false


func _on_match_started() -> void:
	_started = true
	_t_start = Time.get_ticks_usec()
	_frames_at_start = _frames
	_seed_services()
	_find_or_create_score()
	if early_margin < 0.0:
		early_margin = 3000.0 if _score_source == "score_keeper" else 1500.0
	for team in [PLAYER, ENEMY]:
		_stats[team] = {"peak_army_pop": 0, "peak_workers": 0, "peak_army_value": 0}


func _find_or_create_score() -> void:
	for n in get_nodes_in_group(&"score"):
		if n.has_method(&"score"):
			_score_node = n
	if _score_node == null and ResourceLoader.exists(SCORE_KEEPER_PATH):
		var script := load(SCORE_KEEPER_PATH) as GDScript
		if script != null and script.can_instantiate():
			_score_node = script.new() as Node
			if _score_node != null:
				_score_node.name = "LabScoreKeeper"
				if &"match_time_source" in _score_node:
					_score_node.set(&"match_time_source", Callable(main, &"match_time"))
				if &"level" in _score_node:
					_score_node.set(&"level", main)
				main.add_child(_score_node)
	_score_source = "score_keeper" if _score_node != null else "fallback"


# ---------------------------------------------------------------- sampling (once per game second)

func _sample(t: float) -> bool:
	var s := [_team_sample(PLAYER), _team_sample(ENEMY)]
	for team in [PLAYER, ENEMY]:
		var st: Dictionary = _stats[team]
		st["peak_army_pop"] = maxi(int(st["peak_army_pop"]), int(s[team]["army_pop"]))
		st["peak_army_value"] = maxi(int(st["peak_army_value"]), int(s[team]["army_value"]))
		st["peak_workers"] = maxi(int(st["peak_workers"]), int(s[team]["workers"]))
		# Stall flags: a side alive with no worker for 60 s; crystals floating above 1500 for 180 s.
		if int(s[team]["workers"]) == 0 and int(s[team]["buildings"]) > 0:
			if _workerless_since[team] < 0.0:
				_workerless_since[team] = t
			elif t - _workerless_since[team] >= 60.0:
				_flags["%s_no_workers" % SIDES[team]] = true
		else:
			_workerless_since[team] = -1.0
		if int(s[team]["crystals"]) > 1500:
			if _float_since[team] < 0.0:
				_float_since[team] = t
			elif t - _float_since[team] >= 180.0:
				_flags["%s_floating_crystals" % SIDES[team]] = true
		else:
			_float_since[team] = -1.0
	for snap in SNAPSHOT_TIMES:
		if int(t) == snap and not _snapshots.has(str(snap)):
			_snapshots[str(snap)] = {"player": _snap_of(s[PLAYER]), "enemy": _snap_of(s[ENEMY])}
	# Activity: a kill (units lost / buildings lost on either side) or a crystal mined.
	var kills := 0
	var gathered := [int(s[PLAYER]["gathered"]), int(s[ENEMY]["gathered"])]
	for team in [PLAYER, ENEMY]:
		kills += int(s[team]["lost"]) + int(s[team]["buildings_lost"])
	if kills != _kills_seen or gathered[0] != _gathered_last[0] or gathered[1] != _gathered_last[1]:
		_last_activity = t
	_kills_seen = kills
	_gathered_last = gathered
	_max_quiet = maxf(_max_quiet, t - _last_activity)
	if stall_s > 0.0 and t - _last_activity >= stall_s:
		_flags["stall"] = true
		return _finish("stall", _score_leader(), "")
	# Dead economies: neither side has a worker or a soldier for DEAD_HOLD s (the map is mined out, both armies
	# gone): nothing can change any more, the score decides now instead of at the limit.
	var dead := true
	for team in [PLAYER, ENEMY]:
		if int(s[team]["workers"]) > 0 or int(s[team]["army_pop"]) > 0:
			dead = false
	if not dead:
		_dead_since = -1.0
	elif _dead_since < 0.0:
		_dead_since = t
	elif stall_s > 0.0 and t - _dead_since >= DEAD_HOLD:
		_flags["both_dead"] = true
		return _finish("stall", _score_leader(), "")
	# Early stop: one side leads the score by early_ratio and early_margin for early_hold seconds.
	var sc := [_score_of(PLAYER), _score_of(ENEMY)]
	var lead := PLAYER if sc[PLAYER] > sc[ENEMY] else (ENEMY if sc[ENEMY] > sc[PLAYER] else -1)
	var clear := false
	if lead >= 0 and t >= early_min:
		var hi: float = sc[lead]
		var lo: float = sc[1 - lead]
		clear = hi - lo >= early_margin and hi >= early_ratio * maxf(lo, 1.0)
	if clear and lead == _lead_team:
		if t - _lead_since >= early_hold:
			if _early_call.is_empty():
				_early_call = {"t": snappedf(t, 0.1), "winner_team": lead, "winner": kingdoms[lead],
						"score": [int(sc[PLAYER]), int(sc[ENEMY])]}
			if early:
				return _finish("early-score", lead, "")
	elif clear:
		_lead_team = lead
		_lead_since = t
	else:
		_lead_team = -1
		_lead_since = -1.0
	if profile and int(t) % 60 == 0 and _perf_acc["frames"] > 0:
		var f: int = _perf_acc["frames"]
		var ms := float(_perf_acc["usec"]) / f / 1000.0
		print("LAB perf %s: %.2f ms/frame, %d nodes, %d units, speed x%.1f" % [_clock(t), ms,
				int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), get_nodes_in_group(&"units").size(),
				(1000.0 / tick) / maxf(ms, 0.001)])
		_perf_acc = {"frames": 0, "usec": 0}
	if int(t) % 300 == 0 and int(t) > 0:
		print("LAB %s  %s %d army %d workers %d  |  %s %d army %d workers %d  (x%.1f)" % [_clock(t),
				kingdoms[0], int(sc[0]), int(s[0]["army_pop"]), int(s[0]["workers"]),
				kingdoms[1], int(sc[1]), int(s[1]["army_pop"]), int(s[1]["workers"]), t / _real_match_s()])
	return false


func _team_sample(team: int) -> Dictionary:
	var army_pop := 0
	var army_value := 0
	var workers := 0
	for u in get_nodes_in_group(&"units"):
		if u.get(&"team") == null or int(u.get(&"team")) != team or not u.has_method(&"is_alive") or not u.call(&"is_alive"):
			continue
		var ut: Variant = u.get(&"unit_type")
		if ut == null:
			continue
		if bool(ut.get(&"is_worker")):
			workers += 1
			continue
		if u.is_in_group(&"champions") or u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes") \
				or u.is_in_group(&"caravans") or (&"is_caravan" in ut and bool(ut.get(&"is_caravan"))):
			continue
		army_pop += int(ut.get(&"pop"))
		army_value += int(ut.get(&"cost"))
	var buildings := 0
	var building_value := 0
	for b in get_nodes_in_group(&"buildings"):
		if b.get(&"team") == null or int(b.get(&"team")) != team or not b.call(&"is_alive"):
			continue
		buildings += 1
		var bt: Variant = b.get(&"building_type")
		var kind: StringName = bt.get(&"kind") if bt != null else &""
		building_value += KEEP_VALUE if kind == &"keep" else (int(bt.get(&"cost")) if bt != null else 0)
	var eco: Variant = _economy(team)
	var st: Dictionary = main.call(&"stats_of", team) if main.has_method(&"stats_of") else {}
	return {"army_pop": army_pop, "army_value": army_value, "workers": workers, "buildings": buildings,
			"building_value": building_value,
			"crystals": int(eco.get(&"crystals")) if eco else 0,
			"gathered": int(eco.get(&"gathered_total")) if eco else 0,
			"lost": int(st.get("lost", 0)), "buildings_lost": _buildings_lost(team),
			"killed": int(st.get("killed", 0))}


func _snap_of(s: Dictionary) -> Dictionary:
	return {"army_pop": s["army_pop"], "workers": s["workers"], "gathered": s["gathered"], "buildings": s["buildings"],
			"worth": int(s["crystals"]) + int(s["army_value"]) + int(s["workers"]) * WORKER_VALUE + int(s["building_value"])}


func _buildings_lost(team: int) -> int:
	var enemy_stats: Dictionary = main.call(&"stats_of", 1 - team) if main.has_method(&"stats_of") else {}
	return int(enemy_stats.get("buildings_destroyed", 0))


func _economy(team: int) -> Node:
	for n in get_nodes_in_group(&"economies"):
		if n.get(&"team") != null and int(n.get(&"team")) == team:
			return n
	return null


# ---------------------------------------------------------------- score

func _score_of(team: int) -> float:
	if _score_node != null and is_instance_valid(_score_node):
		return float(_score_node.call(&"score", team))
	var s := _team_sample(team)
	return float(s["army_value"]) + float(s["crystals"]) + float(s["building_value"]) \
			+ float(s["workers"]) * WORKER_VALUE + 0.5 * float(s["gathered"])


func _score_leader() -> int:
	var a := _score_of(PLAYER)
	var b := _score_of(ENEMY)
	return PLAYER if a > b else (ENEMY if b > a else -1)


func _score_table() -> Dictionary:
	var out := {"source": _score_source}
	for team in [PLAYER, ENEMY]:
		var row := {"total": int(_score_of(team))}
		if _score_node != null and is_instance_valid(_score_node) and _score_node.has_method(&"breakdown"):
			var bd: Dictionary = _score_node.call(&"breakdown", team)
			for k in ["military", "economy", "map", "growth", "total"]:
				if bd.has(k):
					row[k] = int(bd[k])
		else:
			var s := _team_sample(team)
			row["army"] = int(s["army_value"])
			row["economy"] = int(row["total"]) - int(s["army_value"])
		out[SIDES[team]] = row
	out["margin"] = absi(int(out["player"]["total"]) - int(out["enemy"]["total"]))
	return out


# ---------------------------------------------------------------- profiling (--ablate=<game seconds>)

## A rough profile for finding hot spots (not a result: the match is disturbed). From --ablate=T on, each system is
## switched off for ABLATE_FRAMES frames between two baseline windows; its cost = baseline ms/frame - "off" ms/frame.
## Prints a table and quits.
const ABLATE_FRAMES := 300


func _ablate_step(frame_usec: int) -> bool:
	if _ablate_i < 0:
		_build_ablate_items()
		_ablate_i = 0
		_ablate_frames = -10   # a few settling frames per window
		_ablate_usec = 0
		print("LAB ablate at %s: %d systems, %d frames each" % [_clock(float(main.call(&"match_time"))),
				_ablate_items.size(), ABLATE_FRAMES])
		return false
	_ablate_frames += 1
	if _ablate_frames > 0:
		_ablate_usec += frame_usec
	if _ablate_frames < ABLATE_FRAMES:
		return false
	var ms := float(_ablate_usec) / float(ABLATE_FRAMES) / 1000.0
	# Windows alternate: even = baseline, odd = item (i - 1) / 2 off.
	var window := _ablate_i
	if window % 2 == 0:
		_ablate_base.append(ms)
		if window / 2 < _ablate_items.size():
			(_ablate_items[window / 2][1] as Callable).call(true)
	else:
		var k := window / 2
		(_ablate_items[k][1] as Callable).call(false)
		var base := _ablate_base[-1]
		_ablate_rows.append("%-28s off %6.2f ms  (baseline %6.2f)  cost %6.2f ms/frame" % [_ablate_items[k][0], ms, base,
				base - ms])
	_ablate_i += 1
	_ablate_frames = -10
	_ablate_usec = 0
	if _ablate_i > _ablate_items.size() * 2:
		print("LAB ablate results (%d units alive):" % get_nodes_in_group(&"units").size())
		for r in _ablate_rows:
			print("  " + r)
		_finished = true
		return true
	return false


func _build_ablate_items() -> void:
	var toggle_nodes := func(off: bool, nodes: Array) -> void:   # bind() appends `nodes` after `off`
		for n: Variant in nodes:
			if is_instance_valid(n) and n is Node:
				(n as Node).process_mode = Node.PROCESS_MODE_DISABLED if off else Node.PROCESS_MODE_INHERIT
	var units := get_nodes_in_group(&"units")
	var critters := get_nodes_in_group(&"game_critters")
	var buildings := get_nodes_in_group(&"buildings")
	var art: Array = []
	var projectiles: Array = []
	var singles: Array[Node] = []
	var skip := {}
	for n in units + critters + buildings:
		skip[n] = true
	for n in main.find_children("*", "", true, false):
		var s := n.get_script() as Script
		if s == null:
			continue
		var path := s.resource_path
		if path.begins_with("res://art/") or path.begins_with("res://scripts/vfx/"):
			art.append(n)
		elif path.ends_with("projectile.gd"):
			projectiles.append(n)
	for n in main.get_children():
		if not skip.has(n) and not projectiles.has(n) and n.get_script() != null:
			singles.append(n)
	_ablate_items.append(["all units", toggle_nodes.bind(units)])
	_ablate_items.append(["all buildings", toggle_nodes.bind(buildings)])
	_ablate_items.append(["game critters", toggle_nodes.bind(critters)])
	_ablate_items.append(["art / vfx scripts (%d)" % art.size(), toggle_nodes.bind(art)])
	_ablate_items.append(["projectiles", toggle_nodes.bind(projectiles)])
	for n in singles:
		_ablate_items.append([String(n.name), toggle_nodes.bind([n])])
	var region: Variant = main.get(&"nav_region")
	if region is Node:
		for n in (region as Node).get_children():
			if not skip.has(n) and n.get_script() != null and not (n is StaticBody3D):
				_ablate_items.append(["nav/" + String(n.name), toggle_nodes.bind([n])])
	_ablate_items.append(["NavigationServer3D", func(off: bool) -> void: NavigationServer3D.set_active(not off)])
	_ablate_items.append(["PhysicsServer3D", func(off: bool) -> void: PhysicsServer3D.set_active(not off)])


# ---------------------------------------------------------------- the end

func _finish_game_over(t: float) -> bool:
	var winner: int = int(main.get(&"winner_team"))
	var reason := "kill"
	if main.get(&"ended_on_score") == true:
		reason = "time-score"
	elif winner == PLAYER or winner == ENEMY:
		if _defeat_buildings(1 - winner) > 0:
			reason = "concede"
	return _finish(reason, winner, "")


func _defeat_buildings(team: int) -> int:
	var n := 0
	for b in get_nodes_in_group(&"buildings"):
		if b.get(&"team") == null or int(b.get(&"team")) != team or not b.call(&"is_alive"):
			continue
		var bt: Variant = b.get(&"building_type")
		if bt != null and &"counts_for_defeat" in bt and not bool(bt.get(&"counts_for_defeat")):
			continue
		n += 1
	return n


func _finish(reason: String, winner: int, error: String) -> bool:
	if _finished:
		return true
	_finished = true
	var t: float = float(main.call(&"match_time")) if main and is_instance_valid(main) and _started else 0.0
	if _baking:
		_bake_usec += Time.get_ticks_usec() - _bake_start
	var real_total := (Time.get_ticks_usec() - _t_init) / 1.0e6
	var real_match := _real_match_s()
	var frames_match := _frames - _frames_at_start
	var result := {
		"v": 1, "pair": "%s:%s" % [kingdoms[0], kingdoms[1]], "player": kingdoms[0], "enemy": kingdoms[1],
		"seed": seed_value, "difficulty": _side_text(difficulty), "style": _side_text(style),
		"style_applied": style_applied[0] and style_applied[1],
		"sim": _sim_text(), "frozen_art": _frozen, "tick": tick, "ui": "off" if ui_off else "on", "bake": "real" if bake_real else "fast",
		"commit": String(args.get("commit", "")), "map": String(args.get("layout", "crown_hollow")),
		"winner_team": winner, "winner": kingdoms[winner] if winner == PLAYER or winner == ENEMY else "none",
		"winner_side": SIDES[winner] if winner == PLAYER or winner == ENEMY else "none",
		"end_reason": reason, "end_time": snappedf(t, 0.1), "end_clock": _clock(t),
		"limit": limit, "early": early, "early_call": _early_call,
		"stall_flags": _flags.keys(), "max_quiet_s": snappedf(_max_quiet, 1.0),
		"real_s": snappedf(real_total, 0.01), "real_match_s": snappedf(real_match, 0.01),
		"startup_s": snappedf(real_total - real_match, 0.01), "frames": frames_match,
		"startup_parts": {"load_s": snappedf((_t_loaded - _t_init) / 1.0e6, 0.01),
				"build_s": snappedf((_t_built - _t_loaded) / 1.0e6, 0.01),
				"bake_s": snappedf((_t_start - _t_built) / 1.0e6, 0.01) if _t_start > 0 else -1.0},
		"fps": snappedf(frames_match / maxf(real_match, 0.001), 0.1),
		"speed": snappedf(t / maxf(real_match, 0.001), 0.01),
		"bakes": _bake_count, "bake_s": snappedf(_bake_usec / 1.0e6, 0.01),
	}
	if error != "":
		result["error"] = error
	if _started:
		result["score"] = _score_table()
		result["stats"] = {"player": _final_stats(PLAYER), "enemy": _final_stats(ENEMY)}
		result["at"] = _snapshots
	var line := JSON.stringify(result)
	print("LAB_RESULT " + line)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f:
			f.store_line(line)
			f.close()
		else:
			push_error("LAB: can't write %s" % out_path)
	return true


func _final_stats(team: int) -> Dictionary:
	var s := _team_sample(team)
	var st: Dictionary = _stats[team]
	var out := {"peak_army_pop": st.get("peak_army_pop", 0), "peak_army_value": st.get("peak_army_value", 0),
			"peak_workers": st.get("peak_workers", 0), "army_pop": s["army_pop"], "workers": s["workers"],
			"buildings": s["buildings"], "crystals": s["crystals"], "gathered": s["gathered"],
			"units_lost": s["lost"], "units_killed": s["killed"], "buildings_lost": s["buildings_lost"]}
	var ms: Dictionary = main.call(&"stats_of", team) if main.has_method(&"stats_of") else {}
	out["units_trained"] = int(ms.get("trained", 0))
	out["gold_earned"] = int(ms.get("gold_earned", 0))
	out["camps"] = int(ms.get("camps_cleared", 0))
	out["points_held"] = int(ms.get("points_held", 0))
	if _score_node != null and is_instance_valid(_score_node) and _score_node.has_method(&"stat"):
		out["point_seconds"] = int(float(_score_node.call(&"stat", team, &"point_seconds"))) \
				if _has_stat(&"point_seconds") else 0
	var wiz: Variant = main.call(&"wizard_of", team) if main.has_method(&"wizard_of") else null
	out["wizard_level"] = int(wiz.get(&"level")) if wiz != null and is_instance_valid(wiz) else 0
	var bot: Node = bots[team]
	if bot != null and is_instance_valid(bot):
		out["attacks"] = int(bot.get(&"attacks_launched"))
		out["first_attack"] = snappedf(float(bot.get(&"first_attack_time")), 1.0)
		out["bot_tick_ms"] = snappedf(float(bot.call(&"tick_usec_average")) / 1000.0, 0.001) \
				if bot.has_method(&"tick_usec_average") else 0.0
	return out


func _has_stat(stat_id: StringName) -> bool:
	var script := _score_node.get_script() as Script
	if script == null:
		return false
	var c := script.get_script_constant_map()
	return c.has("WEIGHTS") and c["WEIGHTS"] is Dictionary and (c["WEIGHTS"] as Dictionary).has(stat_id)


func _real_match_s() -> float:
	if _t_start == 0:
		return 0.0
	return (Time.get_ticks_usec() - _t_start) / 1.0e6


func _side_text(v: Array[String]) -> String:
	return v[0] if v[0] == v[1] else "player:%s,enemy:%s" % [v[0], v[1]]


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
