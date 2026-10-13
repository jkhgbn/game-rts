extends SceneTree
## Fix batch F3a (code review 2026-10-12, world / skirmish save). A skirmish is saved and rebuilt from the file:
##  - ScoreKeeper stats come back (W1-2), restored essence is not counted as gained, no history burst;
##  - a placed bounty comes back with its stake (W2-1); the guild's hires_made and a paid revive come back (W2-3/4);
##  - an epic beast spawned before the save comes back once, owned by its lair (W3-1);
##  - camps keep their level, a late camp spawned before the save does not spawn a second time (W3-2);
##  - a captured point keeps its owner (W3-5), a Lost Cache keeps its loot roll state (W1-4);
##  - BountyBoard.kind_for: a game critter is refused, an allied seat's (team 3, 2v2 sides) building / unit is
##    GUARD / ESCORT, never HUNT (U3-4, W2-2); levelled camp creatures keep their HP through the load (W3-2);
##  - EnvProps.fit_roads merges 28 segments into 16 slots (W1-6);
## then the respawn retry (W1-1): the enemy wizard dies with no keep / barracks (a hovel keeps the side alive), stays
## dead past its timer, and comes back once a barracks stands.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_f3a_world_save.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "f3a_world_save"
const TEST_PATH := "user://saves/_test_f3a_world_save.save"
const LAIR := &"lair_heath_w"

var errors: Array[String] = []
var level: Node
var step := "start"
var frames := 0
var total := 0
var data: Dictionary = {}
var expect := {}
var restorer_done := false


func _initialize() -> void:
	level = load("res://scenes/skirmish.tscn").instantiate()
	level.set(&"time_limit_s", 0.0)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	total += 1
	frames += 1
	if total > 8500:
		_fail("timed out at step %s" % step)
		return _finish()
	match step:
		"start":
			if level.get(&"hero") != null and bool(level.get(&"match_started")):
				_bots_off()
				_static_checks()
				_goto("play")
		"play":
			if frames >= 240:
				_change()
				_goto("settle")
		"settle":
			if frames >= 30:
				_save()
				_reload()
				_goto("wait")
		"wait":
			if restorer_done:
				_goto("after")
		"after":
			if frames >= 10:
				_bots_off()
				_compare()
				_respawn_setup()
				_goto("respawn_dead")
		"respawn_dead":
			if frames >= 2100:   # 35 s: past the 30 s timer
				_respawn_check_dead()
				_goto("respawn_back")
		"respawn_back":
			var w: Wizard = level.get(&"shadow_hero")
			if w and w.is_alive():
				print("  respawn: back %d frames after the barracks" % frames)
				return _finish()
			if frames > 240:
				_fail("W1-1: the wizard did not come back after a barracks was built")
				return _finish()
	return false


func _goto(s: String) -> void:
	step = s
	frames = 0


func _fail(msg: String) -> void:
	errors.append(msg)
	print("  x ", msg)


func _finish() -> bool:
	DirAccess.remove_absolute(TEST_PATH)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true


func _bots_off() -> void:
	for n in level.find_children("*", "Commander", true, false):
		n.set(&"enabled", false)


func _static_checks() -> void:
	var board := BountyBoard.for_team(0)
	var critter := Node3D.new()
	critter.add_to_group(&"game_critters")
	level.add_child(critter)
	if board.kind_for(critter) != -1:
		_fail("U3-4: kind_for(game critter) = %d, expected -1" % board.kind_for(critter))
	critter.queue_free()
	var roads := PackedVector4Array()
	for i in 28:   # a 28-segment ring
		var a := TAU * float(i) / 28.0
		var b := TAU * float(i + 1) / 28.0
		roads.append(Vector4(cos(a) * 40.0, sin(a) * 40.0, cos(b) * 40.0, sin(b) * 40.0))
	var fitted := EnvProps.fit_roads(roads, 16)
	if fitted.size() != 16:
		_fail("W1-6: fit_roads gave %d segments for 16 slots" % fitted.size())
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nuniform vec4 road_segs[24];\n"
	if EnvProps.road_slots(sh) != 24:
		_fail("W1-6: road_slots read %d, expected 24" % EnvProps.road_slots(sh))


func _change() -> void:
	var keep: Keep = level.get(&"keep")
	EssenceBank.for_team(0).add(600)
	# score
	var sk: ScoreKeeper = ScoreKeeper.instance(self)
	sk.add_stat(0, &"value_killed", 1234.0)
	# guild: a champion, two hires counted, the champion fallen and paid to revive
	var guild: ChampionGuild = level.call(&"guild_of", 0)
	var ch: Unit = guild.add_companion({"id": String(ChampionGuild.ARCHETYPES[0]), "variant": 0},
			keep.global_position + Vector3(4, 0, 4))
	if ch == null:
		_fail("could not add a champion")
		return
	guild.hires_made = 2
	ch.take_damage(ch.max_hp * 100.0, null)
	var why := guild.revive(ch)
	if why != "":
		_fail("revive refused: %s" % why)
	# a bounty (Explore near the keep)
	var at := keep.global_position + Vector3(12.0, 0.0, 12.0)
	why = BountyBoard.for_team(0).place(Bounty.EXPLORE, null, at, 60)
	if why != "":
		_fail("bounty refused: %s" % why)
	# a beast
	var eb: EpicBeasts = EpicBeasts.instance(self)
	if eb.spawn_now(LAIR) == null:
		_fail("spawn_now(%s) gave no beast" % LAIR)
	# camps: one levelled, the late one spawned early
	var cm: CampManager = CampManager.instance(self)
	var late: NeutralCamp = null
	for c: NeutralCamp in cm.camps():
		if not c.has_spawned() and late == null:
			late = c
		elif c.has_spawned():
			c.camp_level = 2
			for u: Unit in c.creatures():   # what a level-2 respawn gives them, then a wound
				u.add_modifier(NeutralCamp.LEVEL_MODIFIER, {&"max_hp_pct": CampManager.LEVEL_HP * 2.0,
						&"attack_damage_pct": CampManager.LEVEL_DAMAGE * 2.0})
				u.take_damage(u.max_hp * 0.05, null)   # HP stays above the level-0 max
	if late == null:
		_fail("no late camp found")
	else:
		late.spawn()
		expect["late"] = String(late.camp_id)
	# a point held by the player
	var cp: CapturePoints = CapturePoints.instance(self)
	var p: Node3D = cp.points()[0]
	p.call(&"set_owner_team", 0)
	expect["point"] = String(p.get(&"point_id"))
	# a Lost Cache's loot rolls advanced
	var cache: LostCache = (level.get(&"caches") as Array)[0]
	for i in 5:
		cache.rng.randi()


func _creature_count() -> int:
	var n := 0
	for u in get_nodes_in_group(&"creatures"):
		if u is Unit and (u as Unit).is_alive() and not u.is_queued_for_deletion():
			n += 1
	return n


func _beast_count() -> int:
	var n := 0
	for u in get_nodes_in_group(&"beasts"):
		if u is Unit and (u as Unit).is_alive() and not u.is_queued_for_deletion():
			n += 1
	return n


func _save() -> void:
	var sk: ScoreKeeper = ScoreKeeper.instance(self)
	expect["value_killed"] = sk.stat(0, &"value_killed")
	expect["essence_stat"] = sk.stat(0, &"essence")
	expect["history"] = sk.history(0).size()
	expect["creatures"] = _creature_count()
	expect["beasts"] = _beast_count()
	var levels := {}
	for c: NeutralCamp in CampManager.instance(self).camps():
		levels[String(c.camp_id)] = c.camp_level
	expect["levels"] = levels
	expect["camp_hp"] = _camp_hp()
	expect["cache_rng"] = ((level.get(&"caches") as Array)[0] as LostCache).rng.state
	var why := SaveGame.write_file(TEST_PATH, SaveGame.capture(level))
	if why != "":
		_fail("write_file: %s" % why)
	data = SaveGame.read_file(TEST_PATH)
	if data.has("error"):
		_fail("read_file: %s" % data["error"])
	print("  saved: creatures %d, beasts %d, value_killed %.0f, essence stat %.0f" % [expect["creatures"],
			expect["beasts"], expect["value_killed"], expect["essence_stat"]])


func _reload() -> void:
	var old := level
	root.remove_child(old)
	old.queue_free()
	level = SaveGame.instantiate_level(data)
	if level == null:
		_fail("instantiate_level returned null")
		return
	restorer_done = false
	var r := level.get_node(NodePath(SaveGame.RESTORER_NAME))
	r.connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		if not ok:
			_fail("the restorer reported a failure"))
	root.add_child(level)
	current_scene = level


func _compare() -> void:
	# W1-2 score
	var sk: ScoreKeeper = ScoreKeeper.instance(self)
	if absf(sk.stat(0, &"value_killed") - float(expect["value_killed"])) > 1.0:
		_fail("W1-2: value_killed %.0f, saved %.0f" % [sk.stat(0, &"value_killed"), expect["value_killed"]])
	if sk.stat(0, &"essence") > float(expect["essence_stat"]) + 30.0:
		_fail("W1-2: essence stat %.0f after the load, saved %.0f (restored essence counted)" % [
				sk.stat(0, &"essence"), expect["essence_stat"]])
	if sk.history(0).size() > int(expect["history"]) + 2:
		_fail("W1-2: history %d points, saved %d (burst)" % [sk.history(0).size(), expect["history"]])
	# W2-1 bounty
	var board := BountyBoard.for_team(0)
	if board.bounties.size() != 1 or board.bounties[0].stake != 60:
		_fail("W2-1: %d bounties after the load (stake %s), expected one of 60" % [board.bounties.size(),
				str(board.bounties[0].stake) if not board.bounties.is_empty() else "-"])
	# W2-3 / W2-4 guild
	var guild: ChampionGuild = level.call(&"guild_of", 0)
	if guild.hires_made != 2:
		_fail("W2-4: hires_made %d, saved 2" % guild.hires_made)
	var reviving := false
	for ch: Variant in guild.champions:
		if guild.is_reviving(ch):
			reviving = true
	if not reviving:
		_fail("W2-3: the paid revive was lost (%d champions)" % guild.champions.size())
	# W3-1 beasts
	var eb: EpicBeasts = EpicBeasts.instance(self)
	if _beast_count() != int(expect["beasts"]):
		_fail("W3-1: %d beasts after the load, saved %d" % [_beast_count(), expect["beasts"]])
	var beast := eb.beast_of(LAIR)
	if beast == null:
		_fail("W3-1: lair %s holds no beast after the load" % LAIR)
	elif not beast.is_in_group(&"beasts"):
		_fail("W3-1: the restored beast is not in group beasts")
	# W3-2 camps
	if _creature_count() != int(expect["creatures"]):
		_fail("W3-2: %d creatures after the load, saved %d" % [_creature_count(), expect["creatures"]])
	var cm: CampManager = CampManager.instance(self)
	var levels: Dictionary = expect["levels"]
	for c: NeutralCamp in cm.camps():
		if int(levels.get(String(c.camp_id), -1)) != c.camp_level:
			_fail("W3-2: camp %s level %d, saved %d" % [c.camp_id, c.camp_level, int(levels.get(String(c.camp_id), -1))])
		for u: Unit in c.creatures():
			if cm.camp_of(u) != c:
				_fail("W3-2: a creature of %s is not re-adopted" % c.camp_id)
				break
	var late := cm.camp(StringName(str(expect.get("late", ""))))
	if late:
		if not (late as NeutralCamp).has_spawned():
			_fail("W3-2: the late camp forgot its spawn")
	var hp_now := _camp_hp()
	var hp_saved: Dictionary = expect["camp_hp"]
	for id: Variant in hp_saved:
		if absf(float(hp_now.get(id, 0.0)) - float(hp_saved[id])) > 1.0:
			_fail("W3-2: camp %s creatures HP %.0f after the load, saved %.0f" % [id, float(hp_now.get(id, 0.0)), hp_saved[id]])
	# W3-5 points
	var cp: CapturePoints = CapturePoints.instance(self)
	var p := cp.point_by_id(StringName(str(expect["point"])))
	if p == null or int(p.get(&"owner_team")) != 0:
		_fail("W3-5: point %s owner %s after the load, saved 0" % [expect["point"], str(p.get(&"owner_team")) if p else "?"])
	# W1-4 caches
	var cache: LostCache = (level.get(&"caches") as Array)[0]
	if cache.rng.state != int(expect["cache_rng"]):
		_fail("W1-4: Lost Cache rng state not restored")
	_ally_checks(board)
	print("  compare done: %d creatures, %d beasts, %d bounties" % [_creature_count(), _beast_count(), board.bounties.size()])


func _respawn_setup() -> void:
	var grid: BuildGrid = level.get(&"build_grid")
	var ekeep: Keep = level.call(&"keep_of", 1)
	var hovel := BuildingType.find("shadow_hovel")
	var spot := grid.find_spot(hovel, ekeep.global_position + Vector3(-10, 0, 10), 1)
	if grid.spawn_complete(hovel, spot, 1) == null:
		_fail("W1-1: could not build an enemy hovel")
	ekeep.take_damage(ekeep.max_hp * 100.0, null)
	var w: Wizard = level.get(&"shadow_hero")
	w.take_damage(w.max_hp * 100.0, null)
	expect["ekeep_pos"] = ekeep.global_position


func _respawn_check_dead() -> void:
	var w: Wizard = level.get(&"shadow_hero")
	if bool(level.get(&"game_over")):
		_fail("W1-1: the match ended (the hovel should keep the enemy alive)")
		return
	if w.is_alive():
		_fail("W1-1: the wizard came back without a respawn point")
	var grid: BuildGrid = level.get(&"build_grid")
	var rax := BuildingType.find("shadow_barracks")
	var spot := grid.find_spot(rax, expect["ekeep_pos"], 1)
	if grid.spawn_complete(rax, spot, 1) == null:
		_fail("W1-1: could not build an enemy barracks")


## Camp id -> summed HP of its living creatures.
func _camp_hp() -> Dictionary:
	var out := {}
	for c: NeutralCamp in CampManager.instance(self).camps():
		var sum := 0.0
		for u: Unit in c.creatures():
			sum += u.hp
		out[String(c.camp_id)] = sum
	return out


## W2-2: with ALLY (3) on the player's side, an ally's building is GUARD and its unit ESCORT (never HUNT); the
## enemy's stay HUNT. The player keep and a soldier are lent to team 3 for the check, then given back.
func _ally_checks(board: BountyBoard) -> void:
	Teams.configure({0: 0, 1: 1, 3: 0}, 0, {}, level)
	var keep: Keep = level.get(&"keep")
	var ally_unit := Worker.make_unit(UnitType.find("flame_guard"))
	ally_unit.team = 3 as Unit.Team
	level.add_child(ally_unit)
	ally_unit.global_position = keep.global_position + Vector3(8.0, 0.0, 8.0)
	keep.team = 3 as Unit.Team
	var kb := board.kind_for(keep)
	var ku := board.kind_for(ally_unit)
	keep.team = 0 as Unit.Team
	var ek: Keep = level.call(&"keep_of", 1)
	var ke := board.kind_for(ek)
	Teams.configure({0: 0, 1: 1}, 0, {}, level)
	ally_unit.queue_free()
	if kb != Bounty.GUARD:
		_fail("W2-2: kind_for(allied building) = %d, expected GUARD" % kb)
	if ku != Bounty.ESCORT:
		_fail("W2-2: kind_for(allied unit) = %d, expected ESCORT" % ku)
	if ke != Bounty.HUNT:
		_fail("W2-2: kind_for(enemy keep) = %d, expected HUNT" % ke)
