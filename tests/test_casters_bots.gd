extends SceneTree
## Caster units in bot-vs-bot play (docs/design/caster-units.md 9.3 "CU.A1"): one skirmish, a Commander on each side,
## sim mode (no art / VFX / audio), until `limit` game seconds. Per side it reports: when the first caster came out,
## casters trained / lost, casts by rule (autocast, dive_guard, retreat_cover, rune_ahead, rune_blind, retreat_passage,
## home_passage), and the Stronghold time. PASS when every side that reached the Stronghold at least 90 s before the
## limit fielded a caster (normal / hard; unless it had soldiers for less than 90 s there: no soldiers = caster cap 0)
## and its casters cast at least 3 times once they spent 20 s in fights (2 for the mana-limited Bramblesage; 1 cast
## from 8 s: a caster can only cast near enemies); easy sides must never train one. Fights: a caster with an enemy unit
## within 10 m; each new fight prints the casters' mana and the units around them.
## Code review M5 (2026-10-02): only fight casts count (FIGHT_RULES: autocast + fight_* for the Kilnwarden /
## Bramblesage, dive_guard / retreat_cover for the Rimecarver, autocast + passages for the Deacon; never the runes),
## a normal / hard side that misses the Stronghold by BOT_START + 180 s FAILS, and a judged side whose casters never
## fought (< 8 s) without meeting the bar is reported INCONCLUSIVE on the verdict line (never a silent PASS; not a FAIL:
## the Rimecarver stays behind its army by design, so a hard Ice side often logs < 8 s "in fights").
## Run:  godot --headless --path . -s tests/test_casters_bots.gd --fixed-fps 60 --quit-after 90000 -- pair=ice:shadow difficulty=normal limit=720
##   pair=P:E (fire / shadow / ice / nature), difficulty=easy|normal|hard (both sides), limit=<game s> (default 720),
##   log=0|1 (that bot prints its decisions)
##   full (run to the limit even once the verdict is known)
## Early stop (fast CI, 2026-10-02): normal / hard end as soon as each side has trained a caster and its casters cast
##   3+ times (or it is the exempt normal Ice side): trained and casts only grow and the bar is at most 3 casts, so
##   the verdict at the limit could only be PASS. Easy (must NEVER train one) always runs to the limit.
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
var _full := false
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
## Seconds at the Stronghold (or higher) with at least one own soldier: the bot's caster cap is 10 % of its soldier
## pop rounded up (8.1), so a side whose army was wiped out has no caster slot. A side must field a caster only after
## ARMED_FOR such seconds.
const ARMED_FOR := 90.0
var _armed_s := [0.0, 0.0]
## The casts that count (code review M5): per caster kind, the rules that are fight casts. Never rune_blind /
## rune_ahead (a hard Rimecarver could meet the bar with runes alone and hide a broken Slag Rain / Haze autocast).
const FIGHT_RULES := {
	&"kilnwarden": ["autocast", "fight_scald", "fight_slag"],
	&"bramblesage": ["autocast", "fight_haze", "fight_snag"],
	&"rimecarver": ["dive_guard", "retreat_cover"],
	&"gloom_deacon": ["autocast", "retreat_passage", "home_passage"],
}
## A normal / hard side must reach the Stronghold by TierSystem.BOT_START[difficulty][0] + this (save window, the
## upgrade itself, a lost fight or two); later = FAIL (it hid every caster check before, code review M5).
const STRONGHOLD_SLACK := 180.0
var _log_team := -1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.trim_prefix("--") == "full":
			_full = true
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
			"log":   # log=0 / log=1: that bot prints its decisions (Commander.debug_log)
				_log_team = int(kv[1])
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
		bots[team].set(&"debug_log", team == _log_team)
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
			if _stronghold[team] >= 0.0 and bots[team]:
				for s: Variant in bots[team].call(&"own_soldiers"):   # the Commander's list may hold dead ones
					if is_instance_valid(s) and (s as Unit).is_alive():
						_armed_s[team] += 0.5
						break
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
	var early := not _full and t < limit and _verdict_final()
	if early:
		print("  EARLY STOP at %s: every side trained a caster and cast enough, the verdict cannot change (full = run to %s)" % [
				_mmss(t), _mmss(limit)])
	if early or t >= limit or bool(main.get(&"game_over")):
		_report(t)
		_done = true
		return true
	return false


## True when _report at any later time could only PASS: for each side a caster was trained and its fight casts reached
## its top bar (3, the mana-limited Bramblesage 2), or it is the normal Ice side (casts not judged). Easy never stops
## early (no caster ever is the check).
func _verdict_final() -> bool:
	if difficulty == 0:
		return false
	for team in [0, 1]:
		var trained := false
		for k: Variant in _seen:
			if int(_seen[k]) == team:
				trained = true
				break
		if not trained:
			return false
		if kingdoms[team] == "ice" and difficulty < 2:
			continue
		if _fight_casts(team) < _full_bar(team):
			return false
	return true


## The casts of `team`'s casters that count: the rules of FIGHT_RULES for its kingdom's caster.
func _fight_casts(team: int, out_rules: Dictionary = {}) -> int:
	var ai: Variant = bots[team].get(&"casters_ai") if bots[team] else null
	var rules: Dictionary = ai.get(&"casts_by_rule") if ai else {}
	var counted: Array = FIGHT_RULES.get(CasterKit.caster_for(StringName(kingdoms[team])), [])
	var n := 0
	for r: Variant in rules:
		if counted.has(String(r)):
			n += int(rules[r])
			out_rules[r] = int(rules[r])
	return n


# 3 casts once the casters spent FIGHT_FULL s in fights; 2 for a caster whose cheapest spell costs more than 50 mana.
func _full_bar(team: int) -> int:
	return 3 if _cheapest_spell(kingdoms[team]) <= 50.0 else 2


func _report(t: float) -> void:
	var errors: Array[String] = []
	var inconclusive: Array[String] = []   # nothing was tested for that side: reported on the verdict line, not a FAIL
	for team in [0, 1]:
		var ai: Variant = bots[team].get(&"casters_ai") if bots[team] else null
		var rules: Dictionary = ai.get(&"casts_by_rule") if ai else {}
		var all_casts := 0
		for r: Variant in rules:
			all_casts += int(rules[r])
		var supplied := {}
		var casts := _fight_casts(team, supplied)
		var trained := 0
		for k: Variant in _seen:
			if int(_seen[k]) == team:
				trained += 1
		print("  team %d %-6s stronghold %s  first caster %s  trained %d  lost %d  casts %d (all %d %s)  fights %d (%d s)" % [
				team, kingdoms[team], _mmss(_stronghold[team]), _mmss(_first_caster[team]), trained, _lost[team], casts,
				all_casts, str(rules), _fights[team], int(_fight_s[team])])
		print("  team %d counted casts by rule: %s" % [team, str(supplied)])
		if difficulty == 0:
			if trained > 0:
				errors.append("easy team %d trained %d casters" % [team, trained])
			continue
		# The Stronghold by a known time (TierSystem.BOT_START + slack): a bot whose tiering broke used to PASS silently.
		var deadline := float((TierSystem.BOT_START.get(difficulty, TierSystem.BOT_START[1]) as Array)[0]) + STRONGHOLD_SLACK
		if _stronghold[team] < 0.0:
			if t >= deadline:
				errors.append("team %d (%s) never reached the Stronghold (by %s)" % [team, kingdoms[team], _mmss(deadline)])
			else:
				inconclusive.append("team %d (%s): the run ended at %s before its Stronghold (due by %s), no caster check ran"
						% [team, kingdoms[team], _mmss(t), _mmss(deadline)])
			continue
		if _stronghold[team] >= 0.0 and _stronghold[team] <= t - 90.0:
			if trained == 0 and _armed_s[team] < ARMED_FOR:
				print("  team %d: no caster, but only %d s at the Stronghold with an army (caster cap 0 without soldiers)" % [
						team, int(_armed_s[team])])
			elif trained == 0:
				errors.append("team %d (%s) reached the Stronghold at %s but fielded no caster (%d s with an army)" % [
						team, kingdoms[team], _mmss(_stronghold[team]), int(_armed_s[team])])
			elif _first_caster[team] >= 0.0 and _first_caster[team] <= t - 90.0 \
					and not (kingdoms[team] == "ice" and difficulty < 2):   # normal Rimecarver: dive guard only (8.3)
				# A caster can only cast near enemies: 3 casts once its casters spent FIGHT_FULL s in fights, 1 from
				# FIGHT_SOME s (a skirmish with a scout), none when they never met an enemy. A caster whose cheapest
				# spell costs more than 50 mana (the Bramblesage: Snagroot 75, Haze 100 = one cast per 94-125 s of
				# 0.8 / s regen) is mana-limited: 2 casts (caster-units.md 9.3).
				var full := _full_bar(team)
				var need := full if _fight_s[team] >= FIGHT_FULL else (1 if _fight_s[team] >= FIGHT_SOME else 0)
				if casts < need:
					errors.append("team %d (%s) casters cast only %d fight casts in %d s of fights (want %d; %s)" % [team,
							kingdoms[team], casts, int(_fight_s[team]), need, str(supplied)])
				elif _fight_s[team] < FIGHT_SOME and casts < full:
					# Casters that never met an enemy tested no casting at all: not a pass (code review M5).
					inconclusive.append("team %d (%s): its casters spent %d s in fights (want >= %d) and cast %d fight casts"
							% [team, kingdoms[team], int(_fight_s[team]), int(FIGHT_SOME), casts])
	print("  ended at %s%s" % [_mmss(t), " (game over)" if bool(main.get(&"game_over")) else ""])
	for line in inconclusive:
		print("  INCONCLUSIVE %s" % line)
	if errors.is_empty():
		print("PASS %s %s:%s%s" % [TASK_ID, kingdoms[0], kingdoms[1],
				"" if inconclusive.is_empty() else " (INCONCLUSIVE: %s)" % "; ".join(inconclusive)])
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


## The mana cost of the kingdom's caster's cheapest spell.
static func _cheapest_spell(kingdom: String) -> float:
	var best := INF
	for id in CasterKit.spells_of(CasterKit.caster_for(StringName(kingdom))):
		best = minf(best, float(CasterKit.spell_value(id, "mana", 0.0)))
	return best


static func _mmss(s: float) -> String:
	if s < 0.0:
		return "-"
	return "%d:%02d" % [floori(s / 60.0), int(s) % 60]
