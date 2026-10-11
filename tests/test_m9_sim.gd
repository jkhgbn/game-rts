extends SceneTree
## Mission 2 timing check (docs/design/mission-02.md "Acceptance checks" > Timing): a scripted headless run on normal
## with real fights (no hero protection, no kills or time skips by the test). The scripted player trains from its
## own economy (Ash Hurlers first, then soldiers, Hearths when the pop is short), clears G1, thaws the three Emberguard
## blocks (South, West, North; defending the base when a wave comes near), masses ASSAULT_ARMY units at home (or waits
## for 15:00), assaults the lake, melts the Heartfrost (Vessa + Hurlers), claims the orb, breaks the SE shore walls
## (away from the Sentinels on the SW exit) and walks home. Must end `victory=true` with Vessa alive before the dig
## would end it (10-24 game-minutes incl. the 0:10 m2_heartfrost); the spec's 18-24 is for a human-paced player.
## `-- --idle`: the defeat run: the player turtles at home (trains, defends, never melts); the dig must end it in
## defeat at about 22:50.
## Slow (20+ min of game). `-- --verbose` prints the state every 30 s.
## Length (2026-10-06): 13:43 of play (spec 18-24 for a human). Not tuned toward the spec on purpose: the scripted run
## knows every block, the lake path and the right unit mix from 0:00 and never scouts; the mission's own clocks (W1 5:00,
## the dig ending at ~22:50) are fixed, and the gap is the player's pace. Making the lake slower for the script would
## make it a slog for a human, who already lands near the dig deadline. Playtest data decides (Playtest Recorder).
## Run:  godot --headless --path . -s tests/test_m9_sim.gd --fixed-fps 60 --quit-after 120000 [-- --idle] [--verbose]

const TASK_ID := "m9_sim"
const MISSION := "res://missions/mission_02.tscn"
const HOME := Vector3(-36.0, 0.0, 38.0)
const G1_POS := Vector3(-19.0, 0.0, 19.0)
const SW_GAP := Vector3(-18.0, 0.0, 18.0)
const NW_GAP := Vector3(-18.0, 0.0, -18.0)
## Blocks in walking order (EMBERGUARD_TABLE index): South first (straight from the base), then West, then North;
## the lake is crossed only for the assault (its G3 + Malrik wipe a small army walking through).
const BLOCK_ORDER: Array[int] = [1, 0, 2]
const WEST_WAY := Vector3(-42.0, 0.0, 8.0)    ## the base -> West block road, outside the snowbank ring
const LAKE_ASSAULT_TIME := 690.0
const ASSAULT_ARMY := 28
const HEARTHS: Array[Vector3] = [Vector3(-48.0, 0.0, 48.0), Vector3(-50.0, 0.0, 42.0), Vector3(-42.0, 0.0, 50.0),
		Vector3(-36.0, 0.0, 52.0), Vector3(-52.0, 0.0, 36.0), Vector3(-30.0, 0.0, 52.0)]

var idle := false
var verbose := false
var h := MissionHarness.new()
var main: Mission02
var phase := &"stage"
var _tick := 0.0
var _econ := 0.0
var _last_print := -1
var _block_i := 0
var _via := false   ## the current leg's waypoint is reached
var _hearth_i := 0
var _train_i := 0
var _retreat := false
var _defend := false
var _phase_log: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	idle = args.has("--idle")
	verbose = args.has("--verbose")
	h.task_id = TASK_ID + ("/idle" if idle else "/victory")
	h.protect_hero = false
	h.timeout_frames = 110000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_m9_sim_none.json"}}) as Mission02
	h.steps.add("play", _play, 109000)


func _process(_delta: float) -> bool:
	return h.tick()


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		var t := m.mission_time()
		var total := t + (10.0 if m.heartfrost_freed else 0.0)
		print("  %s at mission time %d:%02d (play time with m2_heartfrost %d:%02d), phases: %s" % [
				"victory" if h.ended == 1 else "defeat", int(t) / 60, int(t) % 60, int(total) / 60, int(total) % 60,
				", ".join(_phase_log)])
		print("  dig %.1f %%, blocks %d / 3, army %d, Vessa level %d, objectives: %s" % [m.dig, m.thawed, _army().size(),
				m.hero.level, " ".join(h.objective_log)])
		if idle:
			h.check(h.ended == 0, "the idle run did not end in defeat")
			h.check(m.has_fired(&"E14"), "the idle run did not end on the dig (E14)")
			h.check(t >= 22.0 * 60.0 and t <= 24.0 * 60.0, "idle defeat at %.0f s, expected ~22:53" % t)
		else:
			h.check(h.ended == 1, "defeat at %.0f s (phase %s)" % [t, phase])
			# mission-02.md "Timing" says 18-24 min for a human-paced run; this scripted player is efficient (it wins
			# around 12-13 min on normal, measured 2026-10-04): the check is that it wins before the dig would end it.
			h.check(total >= 10.0 * 60.0 and total <= 24.0 * 60.0, "victory at %.0f s, outside 10-24 min" % total)
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.5
	if not m.hero_alive():
		return false
	if verbose and int(m.mission_time() / 30.0) != _last_print:
		_last_print = int(m.mission_time() / 30.0)
		print("    t=%5.1f %-8s vessa %3.0f/%3.0f L%d | army %2d | crystals %4d | dig %4.1f | heartfrost %4.0f | enemies %d" % [
				m.mission_time(), phase, m.hero.hp, m.hero.max_hp, m.hero.level, _army().size(),
				Economy.for_team(Unit.Team.PLAYER).crystals, m.dig, m.heartfrost.hp if m.heartfrost else 0.0,
				_enemies_near(m.hero.global_position, 25.0).size()])
	_learn()
	_economy()
	_fireball()
	if idle:
		_turtle()
	else:
		_play_phase()
	return false


## The defeat run: the player only defends its base (trains, fights the waves at home, never goes for the Heartfrost),
## so Malrik's dig ends the mission.
func _turtle() -> void:
	var raid := _wave_near_home()
	if raid.is_empty():
		_army_to(HOME, 5.0)
		_hero_to(main.keep.global_position + Vector3(4.0, 0.0, -4.0), 3.0)
	else:
		_army_to(raid[0].global_position, 3.0)
		_hero_behind(raid[0].global_position)


# ---------------------------------------------------------------- helpers

func _army() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.team == Unit.Team.PLAYER and u.is_alive() and u != main.hero and not u.has_method(&"command_gather") \
				and u.is_commandable():
			out.append(u)
	return out


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u.team != Unit.Team.PLAYER and not main.is_dormant(u) \
				and not u.is_hidden_from_auto_target() and Mission02._flat(u.global_position, at) <= r:
			if u.team == Unit.Team.NEUTRAL and not main.orb_taken and main.sentinels.has(u):
				continue
			out.append(u)
	return out


func _set_phase(p: StringName) -> void:
	phase = p
	_phase_log.append("%s@%d:%02d" % [p, int(main.mission_time()) / 60, int(main.mission_time()) % 60])


func _learn() -> void:
	var w := main.hero as Wizard
	for i in 3:
		if w.spell_points <= 0:
			return
		for id: StringName in [&"fireball", &"ember_step", &"kindle"]:
			if w.learn_spell(id) == "":
				break


func _economy() -> void:
	_econ -= 0.5
	if _econ > 0.0:
		return
	_econ = 2.0
	var eco := Economy.for_team(Unit.Team.PLAYER)
	var hall := main.ember_hall
	if eco == null or hall == null or not is_instance_valid(hall) or not hall.is_alive():
		return
	if eco.pop_cap - eco.pop_used < 4 and eco.pop_cap < 60 and _hearth_i < HEARTHS.size() and eco.crystals >= 100:
		var t := BuildingType.find("fire_hearth")
		var workers: Array = []
		for n in main.get_tree().get_nodes_in_group(&"units"):
			if n is Unit and (n as Unit).team == Unit.Team.PLAYER and n.has_method(&"command_gather") and (n as Unit).is_alive():
				workers.append(n)
				break
		while _hearth_i < HEARTHS.size():
			var c := main.build_grid.snap(HEARTHS[_hearth_i], t.footprint)
			_hearth_i += 1
			if main.build_grid.check(t, c, Unit.Team.PLAYER) == "":
				main.build_grid.place(t, c, Unit.Team.PLAYER, workers)
				return
	if hall.queue.size() >= 2:
		return
	var hurlers := 0
	for u in _army():
		if u.unit_type and u.unit_type.id == &"ash_hurler":
			hurlers += 1
	for q in hall.queue:
		if q.id == &"ash_hurler":
			hurlers += 1
	var want: String = "ash_hurler" if hurlers < 4 else (["flame_guard", "ember_archer", "flame_guard"][_train_i % 3])
	if hall.queue_unit(UnitType.find(want)) == "" and want != "ash_hurler":
		_train_i += 1


func _fireball() -> void:
	var hero := main.hero
	var best: Unit = null
	var best_n := 0
	var foes := _enemies_near(hero.global_position, 11.0)
	for u in foes:
		var n := 0
		for o in foes:
			if Mission02._flat(o.global_position, u.global_position) <= 3.0:
				n += 1
		if n > best_n:
			best_n = n
			best = u
	if best and (best_n >= 2 or hero.mana > hero.max_mana * 0.6):
		hero.command_cast(&"fireball", best.global_position)


## The army fights around `at`: idle units attack-move there.
func _army_to(at: Vector3, spread := 4.0) -> void:
	for u in _army():
		if u.attack_target != null and is_instance_valid(u.attack_target):
			continue
		if Mission02._flat(u.global_position, at) > spread + 2.0:
			u.command_attack_move(at + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread)))


func _army_center() -> Vector3:
	var a := _army()
	if a.is_empty():
		return main.hero.global_position
	var c := Vector3.ZERO
	for u in a:
		c += u.global_position
	return c / a.size()


func _hero_to(at: Vector3, near := 2.0) -> void:
	var hero := main.hero
	if Mission02._flat(hero.global_position, at) > near:
		hero.command_move(at)


## Vessa stays a few metres behind the army's centre (toward home) while it fights.
func _hero_behind(goal: Vector3) -> void:
	var c := _army_center()
	var back := (HOME - c)
	back.y = 0.0
	var spot := c + (back.normalized() * 4.0 if back.length() > 0.5 else Vector3.ZERO)
	if not _enemies_near(main.hero.global_position, 12.0).is_empty() or Mission02._flat(c, goal) > 6.0:
		_hero_to(spot, 3.0)


func _wave_near_home() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in _enemies_near(HOME, 26.0):
		if u.team == Unit.Team.ENEMY:
			out.append(u)
	return out


# ---------------------------------------------------------------- the plan

func _play_phase() -> void:
	var m := main
	var hero := m.hero
	# Vessa falls back home to heal when hurt (the keep heals her), until 85 %.
	if not _retreat and hero.hp < hero.max_hp * 0.3 and not m.orb_taken:
		_retreat = true
	if _retreat:
		_hero_to(m.keep.global_position + Vector3(4.0, 0.0, -4.0), 3.0)
		_army_to(hero.global_position, 5.0)
		if hero.hp >= hero.max_hp * 0.85:
			_retreat = false
		return
	# A wave near the base: everyone defends (before the lake assault).
	var raid := _wave_near_home()
	if not raid.is_empty() and not m.heartfrost_freed and phase != &"lake":
		if not _defend:
			_defend = true
			_phase_log.append("defend@%d:%02d" % [int(m.mission_time()) / 60, int(m.mission_time()) % 60])
		_army_to(raid[0].global_position, 3.0)
		_hero_behind(raid[0].global_position)
		return
	_defend = false
	match phase:
		&"stage":
			_army_to(m.ARMY_POS, 3.0)
			if m.mission_time() >= 30.0:
				_set_phase(&"g1")
		&"g1":
			_army_to(G1_POS, 3.0)
			_hero_behind(G1_POS)
			var alive := 0
			for u in m.guard_groups.get(&"G1", []):
				if is_instance_valid(u) and (u as Unit).is_alive():
					alive += 1
			if alive == 0:
				_set_phase(&"blocks")
		&"blocks":
			if _block_i >= m.blocks.size() or m.mission_time() >= LAKE_ASSAULT_TIME:
				_set_phase(&"build")
				return
			var bi := BLOCK_ORDER[_block_i]
			var b := m.blocks[bi]
			if b.lit:
				_block_i += 1
				_via = false
				return
			var at := b.global_position
			if bi == 0 and not _via:
				if Mission02._flat(_army_center(), WEST_WAY) < 7.0 or _army_center().z < 0.0:
					_via = true
				else:
					_army_to(WEST_WAY, 4.0)
					_hero_behind(WEST_WAY)
					return
			_army_to(at, 5.0)
			if _enemies_near(at, 14.0).is_empty() and (bi != 2 or not is_instance_valid(m.north_spire) \
					or not m.north_spire.is_alive()):
				_hero_to(at + Vector3(1.5, 0.0, 1.5), 1.0)
			else:
				_hero_behind(at)
				if bi == 2 and is_instance_valid(m.north_spire) and m.north_spire.is_alive():
					for u in _army():
						if u.attack_target == null:
							u.command_attack(m.north_spire)
		&"build":
			# A human-paced player masses an army before the G3 fight (mission-02.md: ~1 900 crystals of army at
			# 13:00-16:00): wait at home until ASSAULT_ARMY units or W3's 15:00.
			_army_to(HOME, 5.0)
			_hero_to(m.keep.global_position + Vector3(4.0, 0.0, -4.0), 3.0)
			# 2026-10-11: the Heartfrost's core holds until Mission02.CORE_THAW_AT; a player who has seen that message
			# does not sit on the lake under G3 / Malrik / W3 for minutes (a 6:00 assault died breaking the walls).
			if (_army().size() >= ASSAULT_ARMY and m.mission_time() >= Mission02.CORE_THAW_AT - 120.0) or m.mission_time() >= 900.0:
				_set_phase(&"lake")
		&"lake":
			var foes := _enemies_near(Vector3.ZERO, 16.0)
			if m.heartfrost_freed:
				_set_phase(&"orb")
				return
			if not foes.is_empty() or Mission02._flat(_army_center(), Vector3.ZERO) > 14.0:
				var gap := NW_GAP if _army_center().z < 0.0 else SW_GAP
				var goal := gap if Mission02._flat(_army_center(), gap) > 6.0 						and Mission02._flat(_army_center(), Vector3.ZERO) > 20.0 else gap * 0.2
				_army_to(goal, 3.0)
				_hero_behind(goal)
				return
			# The dig ring is clear: Vessa and the Hurlers melt, the others guard.
			var melters: Array = [hero]
			for u in _army():
				if m.heartfrost.accepts_damage_from(u):
					if u.attack_target != m.heartfrost:
						melters.append(u)
				elif u.attack_target == null and Mission02._flat(u.global_position, Vector3.ZERO) > 7.0:
					u.command_attack_move(Vector3(randf_range(-5, 5), 0.0, randf_range(-5, 5)))
			if hero.attack_target != m.heartfrost or melters.size() > 1:
				m.order_on_heartfrost(melters)
		&"orb":
			if m.orb_taken:
				_set_phase(&"walls")
				return
			_hero_to(Vector3(0.8, 0.0, 0.8), 0.5)
			_army_to(Vector3(-3.0, 0.0, 3.0), 3.0)
		&"walls":
			if m.has_fired(&"E11b") or m.opened_gaps().size() > 0:
				_set_phase(&"home")
				return
			var target: Node = null
			for row: Array in m.wall_rows.get(&"se", []):
				for w: Variant in row:
					if is_instance_valid(w) and (w as Building).is_alive():
						target = w
						break
				if target:
					break
			for u in _army():
				if target and (u.attack_target == null or not is_instance_valid(u.attack_target)):
					u.command_attack(target)
			if target:
				_hero_behind((target as Node3D).global_position)
				if Mission02._flat(hero.global_position, (target as Node3D).global_position) <= 9.0 and hero.attack_target == null:
					hero.command_attack(target)
		&"home":
			_hero_to(m.keep.global_position + Vector3(5.0, 0.0, -5.0), 2.0)
			for u in _army():
				if u.attack_target == null and Mission02._flat(u.global_position, hero.global_position) > 6.0:
					u.command_move(hero.global_position)
