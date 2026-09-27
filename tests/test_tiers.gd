extends SceneTree
## Tiers wave (docs/design/tiers.md, docs/plan/tiers-wave.md), scenes/skirmish.tscn.
## Part gates: TierSystem exists (T1), the keep card lists the tier stub right after the worker, a T2 Hall unit is
##   refused "Requires Stronghold" and a requires_tier 3 building "Requires Citadel"; "+" refused before T2; the
##   Stronghold (cost, cancel = full refund, 60 s, keep HP x1.2 +4 dmg) then the Citadel (90 s, x1.4); the gates open;
##   a "+" researched at the Hall applies to a living and a newly trained unit; ScoreKeeper keep_tier = 3.
## Part bot: a normal Shadow bot (attacks off) vs an idle player reaches the Stronghold by 6:00 and the Citadel by 9:30.
## Run:  godot --headless --path . -s tests/test_tiers.gd --fixed-fps 60 --quit-after 60000
##   Options after `--`: --only=gates|bot

const TASK_ID := "tiers"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const BOT_T2_BY := 360.0
const BOT_T3_BY := 570.0

var main: Node
var part := ""
var _queue: Array[String] = []
var _wait := 0
var _gap := 0
var _busy := false
var _errors: Array[String] = []
var _bot: Node
var _t2_at := -1.0
var _t3_at := -1.0


func _initialize() -> void:
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for p in a.trim_prefix("--only=").split(",", false):
				only.append(p)
	for p in ["gates", "bot"]:
		if only.is_empty() or only.has(p):
			_queue.append(p)
	_next_part()


func _next_part() -> void:
	if _queue.is_empty():
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		quit()
		return
	part = _queue.pop_front()
	_wait = 0
	_busy = false
	main = load(SCENE).instantiate()
	main.camps_enabled = false
	main.beasts_enabled = false
	if part == "bot":
		_bot = _bot_for(ENEMY, 1)
	root.add_child(main)
	current_scene = main
	print("---- part %s" % part)


func _bot_for(team: int, difficulty: int) -> Node:
	var b: Node = null
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			b = child
	if b == null:
		b = COMMANDER.new()
		b.team = team
		main.add_child(b)
	b.difficulty = difficulty
	var p := AIProfile.for_difficulty(difficulty)
	p.launch_attacks = false
	b.profile = p
	b.profile_id = &""
	return b


func _end_part() -> void:
	Engine.time_scale = 1.0
	main.queue_free()
	main = null
	_bot = null
	_gap = 3


func _process(_delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_next_part()
		return false
	if main == null:
		return false
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	if part == "gates" and not _busy:
		_busy = true
		_run_gates()
	elif part == "bot":
		_tick_bot()
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append("%s: %s" % [part, what])
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


## Waits `seconds` of game time at 5x speed.
func _game_seconds(seconds: float) -> void:
	Engine.time_scale = 5.0
	var frames := ceili(seconds * 60.0 / 5.0) + 3
	await _frames(frames)
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- part gates

func _run_gates() -> void:
	var ts := TierSystem.instance()
	_check(ts != null, "no TierSystem in the skirmish")
	if ts == null:
		_end_part()
		return
	ts.time_gates = false
	var keep: Keep = main.keep
	var eco: Economy = main.economy
	eco.add(5000)
	eco.add_pop_bonus(100)
	_check(TierSystem.tier_of(PLAYER) == 1 and keep.tier == 1, "start tier %d" % TierSystem.tier_of(PLAYER))
	var types := keep.trainable_types()
	_check(types.size() >= 2 and types[0].is_worker and types[1].id == Keep.TIER_STUB_ID,
			"keep card %s" % str(types.map(func(t: UnitType) -> StringName: return t.id)))
	# Without a Hall the Stronghold is refused.
	_check(keep.can_upgrade() == TierSystem.MSG_NEEDS_HALL, "no Hall: '%s'" % keep.can_upgrade())
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var hall := main.build_grid.spawn_complete(BuildingType.find("fire_barracks"),
			keep.global_position + dir * 16.0, PLAYER) as TrainingBuilding
	await _frames(2)
	var adept := UnitType.find("pyre_adept")
	_check(adept != null and adept.requires_tier == 2, "pyre_adept requires_tier %s" % (adept.requires_tier if adept else -1))
	if adept and hall.trainable_types().has(adept):
		_check(hall.can_queue(adept) == TierSystem.MSG_T2, "T1 pyre_adept: '%s'" % hall.can_queue(adept))
	var t3b := BuildingType.find("fire_tower").duplicate() as BuildingType
	t3b.requires_tier = 3
	_check(BuildGrid.prerequisite_reason(t3b, PLAYER) == TierSystem.MSG_T3,
			"T1 tier-3 building: '%s'" % BuildGrid.prerequisite_reason(t3b, PLAYER))
	_check(TierSystem.gate_reason(3, PLAYER) == TierSystem.MSG_T3, "gate 3 at T1")
	# "+" before the Stronghold.
	var bank := UnitUpgrades.for_team(PLAYER)
	_check(bank.can_buy(&"flame_guard", hall) == TierSystem.MSG_T2, "+ at T1: '%s'" % bank.can_buy(&"flame_guard", hall))
	_check(UnitUpgrades.ids_for_hall(hall).has(&"flame_guard") and UnitUpgrades.ids_for_hall(hall).has(&"scorchbow"),
			"Hall + ids %s" % str(UnitUpgrades.ids_for_hall(hall)))
	# Stronghold: pay, cancel (full refund), pay again, 60 s.
	var hp0 := keep.max_hp
	var c0 := eco.crystals
	var stub: UnitType = keep.trainable_types()[1]
	_check(keep.queue_unit(stub) == "" and keep.is_upgrading() and eco.crystals == c0 - 200,
			"Stronghold start: upgrading %s, crystals %d -> %d" % [keep.is_upgrading(), c0, eco.crystals])
	_check(keep.can_queue(keep.trainable_types()[1]) == "" and keep.trainable_types()[1].display_name.begins_with("Cancel"),
			"cancel button")
	keep.queue_unit(keep.trainable_types()[1])
	_check(not keep.is_upgrading() and eco.crystals == c0, "cancel refund: crystals %d (want %d)" % [eco.crystals, c0])
	_check(keep.upgrade() == "", "Stronghold restart")
	_check(keep.queue_unit(UnitType.find("cinder_hand")) == "", "worker queue beside the upgrade")
	await _game_seconds(30.0)
	_check(keep.is_upgrading() and keep.upgrade_progress() > 0.4 and keep.upgrade_progress() < 0.6,
			"Stronghold half-way progress %.2f" % keep.upgrade_progress())
	await _game_seconds(32.0)
	_check(keep.tier == 2 and TierSystem.tier_of(PLAYER) == 2, "Stronghold done: tier %d" % keep.tier)
	_check(is_equal_approx(keep.max_hp, roundf(hp0 * 1.2)), "Stronghold HP %.0f (want %.0f)" % [keep.max_hp, hp0 * 1.2])
	if adept and hall.trainable_types().has(adept):
		_check(hall.can_queue(adept) == "", "T2 pyre_adept: '%s'" % hall.can_queue(adept))
	_check(BuildGrid.prerequisite_reason(t3b, PLAYER) == TierSystem.MSG_T3, "T2 tier-3 building still refused")
	# "+" at T2: a living Flame Guard and a newly trained one get +10 % HP / damage.
	var guard := UnitType.find("flame_guard").create_unit()
	guard.team = PLAYER as Unit.Team
	main.add_child(guard)
	guard.global_position = keep.global_position + dir * 8.0
	await _frames(2)
	var base_hp := guard.max_hp
	var base_dmg := guard.get_stat(&"attack_damage")
	c0 = eco.crystals
	_check(bank.buy(&"flame_guard", hall) == "", "+ buy: '%s'" % bank.can_buy(&"flame_guard", hall))
	_check(eco.crystals == c0 - UnitUpgrades.price_of(&"flame_guard"), "+ price %d" % (c0 - eco.crystals))
	_check(bank.can_buy(&"ember_archer", hall) == UnitUpgrades.REASON_BUSY, "busy Hall: '%s'" % bank.can_buy(&"ember_archer", hall))
	# Citadel meanwhile (90 s).
	_check(keep.upgrade() == "", "Citadel start: '%s'" % keep.can_upgrade())
	await _game_seconds(UnitUpgrades.time_of(&"flame_guard") + 1.0)
	_check(UnitUpgrades.team_has(PLAYER, &"flame_guard"), "+ not researched")
	_check(is_equal_approx(guard.max_hp, roundf(base_hp * 1.1)) or absf(guard.max_hp - base_hp * 1.1) < 0.6,
			"+ living HP %.1f (want %.1f)" % [guard.max_hp, base_hp * 1.1])
	_check(absf(guard.get_stat(&"attack_damage") - base_dmg * 1.1) < 0.05,
			"+ living dmg %.2f (want %.2f)" % [guard.get_stat(&"attack_damage"), base_dmg * 1.1])
	_check(bool(guard.get_meta(&"plus", false)), "+ meta not set")
	var got: Array = []
	hall.unit_trained.connect(func(u: Unit) -> void: got.append(u))
	_check(hall.queue_unit(UnitType.find("flame_guard")) == "", "train a Flame Guard")
	await _game_seconds(92.0 - UnitUpgrades.time_of(&"flame_guard"))
	_check(not got.is_empty() and absf((got[0] as Unit).max_hp - base_hp * 1.1) < 0.6,
			"+ new unit HP %s" % (str((got[0] as Unit).max_hp) if not got.is_empty() else "none trained"))
	_check(keep.tier == 3 and TierSystem.tier_of(PLAYER) == 3, "Citadel done: tier %d" % keep.tier)
	_check(is_equal_approx(keep.max_hp, roundf(hp0 * 1.4)), "Citadel HP %.0f (want %.0f)" % [keep.max_hp, hp0 * 1.4])
	_check(BuildGrid.prerequisite_reason(t3b, PLAYER) == "", "T3 building gate still closed")
	_check(TierSystem.gate_reason(3, PLAYER) == "", "gate 3 at T3")
	_check(keep.tier_card_type() == null, "Citadel still shows an upgrade button")
	_check(keep.can_upgrade() == Keep.REASON_MAX_TIER, "max: '%s'" % keep.can_upgrade())
	var sk := ScoreKeeper.instance(self)
	if sk:
		sk.sample_now()
		_check(int(sk.stat(PLAYER, &"keep_tier")) == 3, "score keep_tier %s" % sk.stat(PLAYER, &"keep_tier"))
	# Time gates: a fresh team clock at 0 refuses with "Available at 3:30".
	ts.time_gates = true
	_check(ts.upgrade_reason(ENEMY, 2).begins_with("Available at") or main.match_time() >= 210.0,
			"time gate: '%s'" % ts.upgrade_reason(ENEMY, 2))
	print("gates: Stronghold + Citadel + flame_guard+ OK (keep HP %.0f)" % keep.max_hp)
	_end_part()


# ---------------------------------------------------------------- part bot

func _tick_bot() -> void:
	var t: float = main.match_time()
	var tier := TierSystem.tier_of(ENEMY)
	if tier >= 2 and _t2_at < 0.0:
		_t2_at = t
		print("bot Stronghold at %s" % _clock(t))
	if tier >= 3 and _t3_at < 0.0:
		_t3_at = t
		print("bot Citadel at %s" % _clock(t))
	if _t3_at >= 0.0 or t > BOT_T3_BY:
		_check(_t2_at >= 0.0 and _t2_at <= BOT_T2_BY, "Stronghold at %s (want by %s)" % [_clock(_t2_at), _clock(BOT_T2_BY)])
		_check(_t3_at >= 0.0 and _t3_at <= BOT_T3_BY, "Citadel at %s (want by %s)" % [_clock(_t3_at), _clock(BOT_T3_BY)])
		if _bot:
			for l: String in _bot.log_lines:
				if l.contains("KEEP UPGRADE") or l.contains("PLUS UPGRADE"):
					print("  " + l)
		_end_part()


static func _clock(t: float) -> String:
	if t < 0.0:
		return "never"
	return "%d:%02d" % [int(t) / 60, int(t) % 60]
