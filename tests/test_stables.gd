extends SceneTree
## The Stables (docs/design/stables.md, Stables16), scenes/skirmish.tscn.
## Part data: 16 units (4 per kingdom: T1 + T1 + T2 + T3), 8 rank-3 upgrades, 4 Stables types, the build menu lists
##   the Stables (N) after a Hall exists, the card is Z X C V + the 2 rank buttons.
## Part gates: a Stables spawned complete trains its T1 at T1, refuses the T2 "Requires Stronghold" / T3 "Requires
##   Citadel", opens them with the tier; rank-3 refused before the Citadel, then bought (price, one at a time), a
##   living and a newly trained rider get +25 % HP / rank meta / the model's rank crest; not a drop-off.
## Part dance: every Stables model (16) and the mounts dance: play_clip(victory / surrender / random) on the unit's
##   model, the rider (arms) AND the mount (legs / head) move, stop_clip stops.
## Part bot: a hard Fire bot (attacks off) builds its Stables and trains at least one rider by 10:00 (BOT_BY).
## Run:  godot --headless --path . -s tests/test_stables.gd --fixed-fps 60 --quit-after 60000
##   Options after `--`: --only=data|gates|dance|bot

const TASK_ID := "stables"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
## First Stables rider by 10:00 (was 9:00). Since 2026-09-30 a due champion hire comes before Stables riders
## (champions.md 10: a hire keeps price + 150 from training; the hard bot's 3 hires now land by ~7:20 instead of
## starving), builds still come first, and the Stables saves 30 s for its rider: measured 7:17 to ~9:02 over 4 runs.
const BOT_BY := 600.0
const CLIPS: Array[StringName] = [&"dance_victory", &"dance_surrender", &"dance_random"]

var main: Node
var part := ""
var _queue: Array[String] = []
var _wait := 0
var _gap := 0
var _busy := false
var _errors: Array[String] = []
var _bot: Node
var _bot_trained := false


func _initialize() -> void:
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for p in a.trim_prefix("--only=").split(",", false):
				only.append(p)
	for p in ["data", "gates", "dance", "bot"]:
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
		main.set(&"enemy_kingdom", &"fire")
		_bot = _bot_for(ENEMY, 2)
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
	if not _busy:
		match part:
			"data":
				_busy = true
				_run_data()
			"gates":
				_busy = true
				_run_gates()
			"dance":
				_busy = true
				_run_dance()
			"bot":
				_tick_bot()
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append("%s: %s" % [part, what])
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _game_seconds(seconds: float) -> void:
	Engine.time_scale = 5.0
	await _frames(ceili(seconds * 60.0 / 5.0) + 3)
	Engine.time_scale = 1.0


func _hall_spot(keep: Node3D, side: float) -> Vector3:
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	return keep.global_position + dir * 16.0 + Vector3(dir.z, 0, -dir.x) * side


# ---------------------------------------------------------------- part data

func _run_data() -> void:
	_check(Stables16.ENABLED, "switch off")
	_check(Stables16.enabled_here(), "not enabled in the skirmish")
	var n := 0
	var ranks := 0
	for f: StringName in [&"fire", &"shadow", &"ice", &"nature"]:
		var st := Stables16.stables_type(f)
		_check(st != null and st.kind == &"stables" and st.max_count == 1 and st.requires_kind == &"barracks"
				and st.hotkey_label == "N", "%s stables type" % f)
		var types := Stables16.roster_types(f)
		_check(types.size() == 4, "%s roster %d" % [f, types.size()])
		if types.size() != 4:
			continue
		var tiers := types.map(func(t: UnitType) -> int: return t.requires_tier)
		_check(tiers == [1, 1, 2, 3], "%s tiers %s" % [f, str(tiers)])
		for t in types:
			n += 1
			_check(t.faction == f and not t.is_worker and t.model_scene != null and t.pop >= 2,
					"%s unit data (faction %s, model %s)" % [t.id, t.faction, t.model_scene])
			_check(Stables16.description(t.id) != "", "%s description" % t.id)
		var rid := Stables16.rank_ids(f)
		ranks += rid.size()
		_check(rid.size() == 2 and rid[0] == types[0].id and rid[1] == types[2].id, "%s rank ids %s" % [f, str(rid)])
		_check(types[1].attack_range > 3.0, "%s X slot is ranged" % f)
	_check(n == 16 and ranks == 8, "%d units, %d rank-ups" % [n, ranks])
	# Build menu: the Stables is listed (last), refused without a Hall.
	var keep: Keep = main.keep
	var kingdom: StringName = keep.building_type.faction
	var menu := BuildingType.buildable_for(kingdom)
	var st := Stables16.stables_type(kingdom)
	_check(menu.has(st), "build menu %s" % str(menu.map(func(t: BuildingType) -> StringName: return t.id)))
	_check(BuildGrid.prerequisite_reason(st, PLAYER) == BuildGrid.MSG_NEEDS_HALL,
			"no Hall: '%s'" % BuildGrid.prerequisite_reason(st, PLAYER))
	main.build_grid.spawn_complete(BuildingType.find("%s_barracks" % kingdom), _hall_spot(keep, 0.0), PLAYER)
	await _frames(2)
	_check(BuildGrid.prerequisite_reason(st, PLAYER) == "", "Hall built: '%s'" % BuildGrid.prerequisite_reason(st, PLAYER))
	var b := BuildGrid.create_building(st)
	_check(b is StablesBuilding, "create_building gives %s" % b.get_class())
	b.free()
	print("data: 16 units, 8 rank-ups, 4 Stables OK")
	_end_part()


# ---------------------------------------------------------------- part gates

func _run_gates() -> void:
	var ts := TierSystem.instance()
	var keep: Keep = main.keep
	var eco: Economy = main.economy
	eco.add(8000)
	eco.add_pop_bonus(100)
	var kingdom: StringName = keep.building_type.faction
	main.build_grid.spawn_complete(BuildingType.find("%s_barracks" % kingdom), _hall_spot(keep, 0.0), PLAYER)
	var st := main.build_grid.spawn_complete(Stables16.stables_type(kingdom), _hall_spot(keep, 12.0), PLAYER) as StablesBuilding
	await _frames(2)
	_check(st != null and st.is_constructed(), "Stables not spawned")
	if st == null:
		_end_part()
		return
	_check(not st.is_drop_off() and not st.is_shop(), "Stables is a drop-off / shop")
	var types := st.trainable_types()
	_check(types.size() == 6 and Stables16.is_rank_stub(types[4]) and Stables16.is_rank_stub(types[5]),
			"card %s" % str(types.map(func(t: UnitType) -> StringName: return t.id)))
	var z: UnitType = types[0]
	var c: UnitType = types[2]
	var v: UnitType = types[3]
	if ts:
		ts.time_gates = false
		ts.set_tier(PLAYER, 1)
	_check(st.can_queue(z) == "", "T1 %s: '%s'" % [z.id, st.can_queue(z)])
	_check(st.can_queue(types[1]) == "", "T1 %s: '%s'" % [types[1].id, st.can_queue(types[1])])
	_check(ts == null or st.can_queue(c) == TierSystem.MSG_T2, "T2 at T1: '%s'" % st.can_queue(c))
	_check(ts == null or st.can_queue(v) == TierSystem.MSG_T3, "T3 at T1: '%s'" % st.can_queue(v))
	_check(ts == null or st.can_queue(types[4]) == TierSystem.MSG_T3, "rank at T1: '%s'" % st.can_queue(types[4]))
	if ts:
		ts.set_tier(PLAYER, 2)
	_check(st.can_queue(c) == "", "T2 at T2: '%s'" % st.can_queue(c))
	_check(ts == null or st.can_queue(v) == TierSystem.MSG_T3, "T3 at T2: '%s'" % st.can_queue(v))
	if ts:
		ts.set_tier(PLAYER, 3)
	_check(st.can_queue(v) == "", "T3 at T3: '%s'" % st.can_queue(v))
	# A living rider, then the rank-3 research at the Stables.
	var rider := z.create_unit()
	rider.team = PLAYER as Unit.Team
	main.add_child(rider)
	rider.global_position = st.global_position + Vector3(6, 0, 6)
	await _frames(2)
	var hp0 := rider.max_hp
	var c0 := eco.crystals
	_check(st.queue_unit(types[4]) == "", "rank start: '%s'" % st.can_queue(types[4]))
	_check(eco.crystals == c0 - Stables16.rank_price(z.id), "rank price %d" % (c0 - eco.crystals))
	_check(st.can_queue(types[5]) == "The Stables is busy", "busy: '%s'" % st.can_queue(types[5]))
	_check(st.rank_progress() >= 0.0, "no rank progress")
	var got: Array = []
	st.unit_trained.connect(func(u: Unit) -> void: got.append(u))
	_check(st.queue_unit(z) == "", "train %s" % z.id)
	await _game_seconds(Stables16.rank_time(z.id) + 1.0)
	_check(Stables16.team_has_rank(PLAYER, z.id), "rank not researched")
	_check(absf(rider.max_hp - hp0 * 1.25) < 0.6, "rank HP %.1f (want %.1f)" % [rider.max_hp, hp0 * 1.25])
	_check(int(rider.get_meta(&"rank", 0)) == 3 and str(rider.get_meta(&"rank_name", "")) == Stables16.rank_name(z.id),
			"rank meta")
	if rider.model_has(&"set_rank"):
		var crest_found := false
		for n in rider.find_children("RankCrest", "", true, false):
			crest_found = crest_found or (n as Node3D).visible
		_check(crest_found, "no rank crest on the model")
	_check(st.can_queue(types[4]) == "Already researched", "done: '%s'" % st.can_queue(types[4]))
	await _game_seconds(z.train_time)
	_check(not got.is_empty() and int((got[0] as Unit).get_meta(&"rank", 0)) == 3, "new rider not ranked")
	# Destroyed during a research: 75 % back. The player's workers stop first: a crystal delivery (10 per trip) inside
	# the frames below made the balance 10-20 off in some runs.
	for n in get_nodes_in_group(&"units"):
		var wu := n as Unit
		if wu and int(wu.team) == PLAYER and wu.has_method(&"command_gather") and wu.is_alive():
			wu.command_stop()
	await _frames(2)
	c0 = eco.crystals
	_check(st.queue_unit(types[5]) == "", "rank 2 start: '%s'" % st.can_queue(types[5]))
	var price := Stables16.rank_price(c.id)
	st.take_damage(99999.0, null)
	await _frames(3)
	_check(eco.crystals == c0 - price + floori(price * 0.75), "refund: crystals %d (want %d)" % [eco.crystals,
			c0 - price + floori(price * 0.75)])
	print("gates: tiers + rank-3 + refund OK")
	_end_part()


# ---------------------------------------------------------------- part dance

func _snap(n: Node) -> Dictionary:
	var d := {}
	if n == null:
		return d
	for c in n.find_children("*", "Node3D", true, false):
		var c3 := c as Node3D
		if not c3 is GeometryInstance3D:
			d[c3.get_path()] = c3.rotation
	return d


func _moved(a: Dictionary, n: Node) -> float:
	var best := 0.0
	for c in n.find_children("*", "Node3D", true, false):
		var c3 := c as Node3D
		if a.has(c3.get_path()):
			var r: Vector3 = a[c3.get_path()]
			best = maxf(best, (c3.rotation - r).abs().length())
	return best


func _run_dance() -> void:
	var cam := root.get_viewport().get_camera_3d()
	var c0 := Vector3.ZERO
	if cam:
		var f := -cam.global_transform.basis.z
		c0 = cam.global_position + f * (cam.global_position.y / maxf(-f.y, 0.2))
		c0.y = 0.0
	var entries: Array = []   # [label, root, clip]
	var x := c0.x - 16.0
	var i := 0
	for id in Stables16.all_unit_ids():
		var t := UnitType.find(String(id))
		var m: Node3D = t.model_scene.instantiate()
		m.position = Vector3(x, 0, c0.z + (i % 2) * 4.0)
		x += 2.2
		main.add_child(m)
		entries.append([String(id), m, CLIPS[i % 3]])
		i += 1
	for p in ["ember_boar", "dusk_steed", "rimehorn", "grove_stag", "roan_courser"]:
		var m: Node3D = (load("res://art/units/mounts/%s/%s.tscn" % [p, p]) as PackedScene).instantiate()
		m.position = Vector3(x, 0, c0.z - 4.0)
		x += 2.5
		main.add_child(m)
		entries.append([p, m, CLIPS[i % 3]])
		i += 1
	await _frames(4)
	var snaps := {}
	for e in entries:
		var m: Node = e[1]
		for h in [&"play_clip", &"stop_clip", &"current_clip", &"has_clip"]:
			_check(m.has_method(h), "%s has no %s" % [e[0], h])
		if not m.has_method(&"play_clip"):
			continue
		for c in CLIPS:
			_check(bool(m.call(&"has_clip", c)), "%s has no clip %s" % [e[0], c])
		_check(bool(m.call(&"play_clip", e[2])), "%s refused %s" % [e[0], e[2]])
		var rider: Node = m.call(&"rider_model") if m.has_method(&"rider_model") else null
		var mount: Node = m.call(&"mount_model") if m.has_method(&"mount_model") else m
		snaps[e[0]] = [_snap(rider), _snap(mount), rider, mount]
	_check(not bool(entries[0][1].call(&"play_clip", &"dance_moonwalk")), "unknown clip accepted")
	# Max joint change over 2 s (the victory rear comes every 4 beats).
	var best := {}
	for k in 8:
		await _frames(15)
		for e in entries:
			var s: Array = snaps.get(e[0], [])
			if s.is_empty():
				continue
			var r := _moved(s[0], s[2]) if s[2] != null else 1.0
			var mo := _moved(s[1], s[3])
			var old: Vector2 = best.get(e[0], Vector2.ZERO)
			best[e[0]] = Vector2(maxf(old.x, r), maxf(old.y, mo))
	for e in entries:
		var m: Node = e[1]
		if not snaps.has(e[0]):
			continue
		_check(StringName(m.call(&"current_clip")) == e[2], "%s stopped dancing (%s)" % [e[0], m.call(&"current_clip")])
		var mv: Vector2 = best[e[0]]
		_check(mv.x > 0.25, "%s rider barely moves dancing %s (%.2f rad)" % [e[0], e[2], mv.x])
		_check(mv.y > 0.2, "%s mount barely moves dancing %s (%.2f rad)" % [e[0], e[2], mv.y])
		print("  %s dances %s: rider %.2f rad, mount %.2f rad" % [e[0], e[2], mv.x, mv.y])
	# UnitDances on a real Stables unit.
	var u := UnitType.find("gloam_rider").create_unit()
	u.team = PLAYER as Unit.Team
	main.add_child(u)
	u.global_position = c0 + Vector3(0, 0, 8)
	await _frames(3)
	_check(UnitDances.play(u, &"dance_victory"), "UnitDances.play refused on a Gloam Rider")
	_check(UnitDances.current(u) == &"dance_victory", "UnitDances.current '%s'" % UnitDances.current(u))
	var m0: Node = entries[0][1]
	m0.call(&"stop_clip")
	_check(StringName(m0.call(&"current_clip")) == &"", "stop_clip did not stop")
	print("dance: %d models dance (rider + mount)" % entries.size())
	_end_part()


# ---------------------------------------------------------------- part bot

func _tick_bot() -> void:
	Engine.time_scale = 5.0
	var t: float = main.match_time()
	for b in Building.for_team(ENEMY):   # a rider out of the Stables (the Ember Hall also trains Blaze Riders)
		if b is StablesBuilding and not b.has_meta(&"test_hooked"):
			b.set_meta(&"test_hooked", true)
			(b as StablesBuilding).unit_trained.connect(func(_u: Unit) -> void: _bot_trained = true)
	if _bot_trained:
		var built := false
		for b in Building.for_team(ENEMY):
			built = built or b is StablesBuilding
		_check(built, "a rider but no Stables")
		print("bot: Stables + first rider at %d:%02d" % [int(t) / 60, int(t) % 60])
		_end_part()
		return
	if t > BOT_BY:
		var has_st := false
		for b in Building.for_team(ENEMY):
			has_st = has_st or b is StablesBuilding
		_check(false, "no Stables rider by %d s (Stables %s)" % [int(BOT_BY), has_st])
		_end_part()
