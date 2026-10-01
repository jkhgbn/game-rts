extends SceneTree
## Caster units in bot-vs-bot play (docs/design/caster-units.md 9.3 "CU.A1"): one skirmish, a Commander on each side,
## sim mode (no art / VFX / audio), until `limit` game seconds. Per side it reports: when the first caster came out,
## casters trained / lost, casts by rule (autocast, dive_guard, retreat_cover, rune_ahead, rune_blind, retreat_passage,
## home_passage), and the Stronghold time. PASS when every side that reached the Stronghold at least 90 s before the
## limit fielded a caster (normal / hard) and its casters cast at least 3 times once they spent 20 s in fights (1 cast
## from 8 s: a caster can only cast near enemies); easy sides must never train one. Fights: a caster with an enemy unit
## within 10 m; each new fight prints the casters' mana and the units around them.
## Run:  godot --headless --path . -s tests/test_casters_bots.gd --fixed-fps 60 --quit-after 90000 -- pair=ice:shadow difficulty=normal limit=720
##   pair=P:E (fire / shadow / ice / nature), difficulty=easy|normal|hard (both sides), limit=<game s> (default 720)
# error_lab: quit-after=90000

const TASK_ID := "casters_bots"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER_PATH := "res://scripts/ai/commander.gd"
const SIM_MODE_PATH := "res://scripts/core/sim_mode.gd"
const SIM_STRIP_NAMES: Array[String] = ["SpellVfx", "CombatVfx", "IceVfx", "NatureVfx", "ChampionVfx", "TradeVfx",
		"MapFillVfx", "TitanVfx", "UnitVfx", "GameAudio", "Horizon"]
const DIFFICULTIES := {"easy": 0, "normal": 1, "hard": 2}

var main: Node
var bots: Array = [null, null]
var kingdoms: Array[String] = ["ice", "shadow"]
var difficulty := 1
var limit := 720.0
var _first_caster := [-1.0, -1.0]
var _stronghold := [-1.0, -1.0]
var _lost := [0, 0]
var _seen := {}          # caster instance id -> team
var _done := false
var _last_log := -1
## Fights: a caster with an enemy unit within FIGHT_NEAR m. Seconds in fights and fight count per team (a new fight
## starts after FIGHT_GAP s without one), sampled every 0.5 s of match time.
const FIGHT_NEAR := 10.0
const FIGHT_GAP := 15.0
const FIGHT_FULL := 20.0
const FIGHT_SOME := 8.0
var _fight_s := [0.0, 0.0]
var _fights := [0, 0]
var _fight_last := [-INF, -INF]
var _sample_t := -1.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() < 2:
			continue
		match kv[0]:
			"pair":
				var p := kv[1].split(":")
				kingdoms = [p[0], p[1]]
			"difficulty":
				difficulty = int(DIFFICULTIES.get(kv[1], 1))
			"limit":
				limit = float(kv[1])
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	if ResourceLoader.exists(SIM_MODE_PATH):
		(load(SIM_MODE_PATH) as Script).set(&"enabled", true)
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", StringName(kingdoms[0]))
	main.set(&"enemy_kingdom", StringName(kingdoms[1]))
	main.set(&"time_limit_s", 0.0)
	for child in main.get_children():
		if SIM_STRIP_NAMES.has(String(child.name)):
			main.remove_child(child)
			child.free()
	var commander_script := load(COMMANDER_PATH) as Script
	for child in main.get_children():
		if child.get_script() == commander_script:
			bots[int(child.get(&"team"))] = child
	for team in [0, 1]:
		if bots[team] == null:
			var b: Node = commander_script.new()
			b.name = "CasterBot%d" % team
			b.set(&"team", team)
			main.add_child(b)
			bots[team] = b
		bots[team].set(&"difficulty", difficulty)
	root.add_child(main)
	current_scene = main
	for key: StringName in [&"hud", &"camera_rig", &"selection"]:
		var n: Variant = main.get(key)
		if n is Node and is_instance_valid(n):
			(n as Node).process_mode = Node.PROCESS_MODE_DISABLED
	print("---- %s:%s difficulty %d limit %.0f s" % [kingdoms[0], kingdoms[1], difficulty, limit])


func _process(_delta: float) -> bool:
	if _done:
		return true
	if main == null or not bool(main.get(&"match_started")):
		return false
	paused = false
	var t: float = main.call(&"match_time")
	for team in [0, 1]:
		if _stronghold[team] < 0.0 and TierSystem.tier_of(team) >= 2:
			_stronghold[team] = t
		for c in CasterKit.casters_of(team):
			var key := c.get_instance_id()
			if not _seen.has(key):
				_seen[key] = team
				if _first_caster[team] < 0.0:
					_first_caster[team] = t
				c.died.connect(func(_u: Unit) -> void: _lost[team] += 1)
	if t - _sample_t >= 0.5:
		_sample_t = t
		for team in [0, 1]:
			var fighting := false
			for c in CasterKit.casters_of(team):
				for u in get_nodes_in_group(&"units"):
					if u is Unit and (u as Unit).is_alive() and c.is_enemy_of(u) \
							and c.global_position.distance_to((u as Unit).global_position) <= FIGHT_NEAR:
						fighting = true
						break
				if fighting:
					break
			if fighting:
				if t - float(_fight_last[team]) > FIGHT_GAP:
					_fights[team] += 1
					_print_fight(team, t)
				_fight_last[team] = t
				_fight_s[team] += 0.5
	if int(t) / 30 != _last_log:   # every 30 s: where the casters stand, what the army does
		_last_log = int(t) / 30
		for team in [0, 1]:
			var ai: Variant = bots[team].get(&"casters_ai") if bots[team] else null
			if ai and TierSystem.tier_of(team) >= 2 and CasterKit.casters_of(team).is_empty() \
					and String(ai.get(&"train_block")) != "":
				print("  %s t%d caster training waits: %s" % [_mmss(t), team, ai.get(&"train_block")])
			for c in CasterKit.casters_of(team):
				var ab := CasterKit.ability_of(c)
				var group: Array = bots[team].call(&"army_group")
				var foes := 0
				for u in get_nodes_in_group(&"units"):
					if u is Unit and (u as Unit).is_alive() and c.is_enemy_of(u) \
							and c.global_position.distance_to((u as Unit).global_position) <= 12.0:
						foes += 1
				print("  %s t%d %s mana %d pos %s stage %s group %d foes<12m %d casts %s" % [_mmss(t), team,
						c.unit_type.id, int(ab.mana), c.global_position.snapped(Vector3.ONE), bots[team].get(&"stage"),
						group.size(), foes, ab.casts])
	if t >= limit or bool(main.get(&"game_over")):
		_report(t)
		_done = true
		return true
	return false


func _report(t: float) -> void:
	var errors: Array[String] = []
	for team in [0, 1]:
		var ai: Variant = bots[team].get(&"casters_ai") if bots[team] else null
		var rules: Dictionary = ai.get(&"casts_by_rule") if ai else {}
		var casts := 0
		for r: Variant in rules:
			casts += int(rules[r])
		var trained := 0
		for k: Variant in _seen:
			if int(_seen[k]) == team:
				trained += 1
		print("  team %d %-6s stronghold %s  first caster %s  trained %d  lost %d  casts %d %s  fights %d (%d s)" % [team,
				kingdoms[team], _mmss(_stronghold[team]), _mmss(_first_caster[team]), trained, _lost[team], casts,
				str(rules), _fights[team], int(_fight_s[team])])
		if difficulty == 0:
			if trained > 0:
				errors.append("easy team %d trained %d casters" % [team, trained])
			continue
		if _stronghold[team] >= 0.0 and _stronghold[team] <= t - 90.0:
			if trained == 0:
				errors.append("team %d (%s) reached the Stronghold at %s but fielded no caster" % [team, kingdoms[team],
						_mmss(_stronghold[team])])
			elif _first_caster[team] >= 0.0 and _first_caster[team] <= t - 90.0 \
					and not (kingdoms[team] == "ice" and difficulty < 2):   # normal Rimecarver: dive guard only (8.3)
				# A caster can only cast near enemies: 3 casts once its casters spent FIGHT_FULL s in fights, 1 from
				# FIGHT_SOME s (a skirmish with a scout), none when they never met an enemy.
				var need := 3 if _fight_s[team] >= FIGHT_FULL else (1 if _fight_s[team] >= FIGHT_SOME else 0)
				if casts < need:
					errors.append("team %d (%s) casters cast only %d times in %d s of fights (want %d)" % [team,
							kingdoms[team], casts, int(_fight_s[team]), need])
	print("  ended at %s%s" % [_mmss(t), " (game over)" if bool(main.get(&"game_over")) else ""])
	if errors.is_empty():
		print("PASS %s %s:%s" % [TASK_ID, kingdoms[0], kingdoms[1]])
	else:
		print("FAIL %s %s:%s: %s" % [TASK_ID, kingdoms[0], kingdoms[1], "; ".join(errors)])
	quit(0 if errors.is_empty() else 1)


# A new fight: each caster's mana and the units around it (enemies within 12 m by type, own soldiers within 8 m).
func _print_fight(team: int, t: float) -> void:
	for c in CasterKit.casters_of(team):
		var foes := {}
		var own := 0
		for u in get_nodes_in_group(&"units"):
			var v := u as Unit
			if v == null or not v.is_alive() or v == c:
				continue
			var d := c.global_position.distance_to(v.global_position)
			if c.is_enemy_of(v) and d <= 12.0:
				var k := String(v.unit_type.id) if v.unit_type else "wizard"
				if v is Wizard:
					k = "wizard(mana %d, %.1f m)" % [int((v as Wizard).mana), d]
				foes[k] = int(foes.get(k, 0)) + 1
			elif int(v.team) == team and d <= 8.0:
				own += 1
		print("  %s t%d FIGHT %d %s mana %d, own units <8m %d, foes <12m %s" % [_mmss(t), team, _fights[team],
				c.unit_type.id, int(CasterKit.ability_of(c).mana), own, foes])


static func _mmss(s: float) -> String:
	if s < 0.0:
		return "-"
	return "%d:%02d" % [floori(s / 60.0), int(s) % 60]
