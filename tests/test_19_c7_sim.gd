extends SceneTree
## Mission 0 balance check (docs/design/mission-00.md "Done when", the lead's line): a scripted headless run on normal
## with real fights (no hero protection, no kills by the test) must reach victory at mission time 8:00 (+ 2 s) with
## Vessa alive; it reports the escort losses of A4 (target 2-4 on most seeds). The scripted player: lights the three
## fires by 3:00 (walks there), then holds by the Gate brazier; Fireball on the biggest clump in range when
## ready, Ember Step 6 m out of a Blink Strike ring on her; the escort attacks knives near Vessa. The player holds in
## the Gate brazier's warmth (HOLD_SPOT).
## Slow (8 min of game per seed). Seeds: `-- --seeds N` (default 1; 5 for the full check).
## Run:  godot --headless --path . -s tests/test_19_c7_sim.gd --fixed-fps 60 --quit-after 200000 -- --seeds 5

const TASK_ID := "19_c7_sim"
const MISSION := "res://missions/mission_00.tscn"
## Where the scripted player holds once the fires burn: in the Gate brazier's warmth (6 m), facing the lane, the
## courtyard and the escort 8 m behind (warmth is "the way back up between waves", mission-00.md difficulty notes).
const HOLD_SPOT := Vector3(-33.5, 0.0, 33.5)
const ROUTE: Array[StringName] = [&"gate", &"crag", &"bell"]

var seeds := 1
var seed_i := 0
var verbose := false   ## `-- --verbose`: Vessa / knives / escort / Vey / Hush every 10 s
var h: MissionHarness
var main: Mission00
var errors: Array[String] = []
var results: Array[String] = []
var _gap := 0
var _tick := 0.0
var _route_i := 0
var _a4_alive := -1
var _a4_after := -1
var _dodges := 0
var _last_print := -1
var _dodged_blink := -1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--seeds")
	if i >= 0 and i + 1 < args.size():
		seeds = maxi(1, int(args[i + 1]))
	verbose = args.has("--verbose")
	_open()


func _open() -> void:
	seed(1000 + seed_i * 7919)
	h = MissionHarness.new()
	h.task_id = "%s/seed%d" % [TASK_ID, seed_i]
	h.protect_hero = false
	h.timeout_frames = 40000
	main = h.open(self, MISSION, {"difficulty": 1}) as Mission00
	_route_i = 0
	_a4_alive = -1
	_a4_after = -1
	_dodges = 0
	h.steps.add("play", _play, 39000)


func _process(delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_open()
		return false
	if h.tick():
		for e in h.errors:
			errors.append("seed %d: %s" % [seed_i, e])
		var m := main
		results.append("seed %d: %s at %.1f, escort %d / 8 (A4 lost %d), Vessa %.0f HP, level %d, dodges %d / %d blinks" % [
				seed_i, "victory" if h.ended == 1 else ("defeat" if h.ended == 0 else "unfinished"), m.mission_time(),
				m.escort_alive(), maxi(0, _a4_alive - _a4_after), m.hero.hp if m.hero_alive() else 0.0, m.hero.level,
				_dodges, m.cast.blinks])
		main.queue_free()
		seed_i += 1
		if seed_i >= seeds:
			for r in results:
				print("  ", r)
			if errors.is_empty():
				print("PASS %s (%d seeds)" % [TASK_ID, seeds])
			else:
				print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
			return true
		_gap = 3
	return false


func _play() -> bool:
	if not h.is_ready():
		return false
	var m := main
	if h.ended >= 0:
		h.check(h.ended == 1, "defeat at %.1f" % m.mission_time())
		if h.ended == 1:
			h.check(m.mission_time() >= 481.0 and m.mission_time() <= 484.0, "victory at %.1f" % m.mission_time())
		return true
	_tick -= 1.0 / 60.0
	if _tick > 0.0:
		return false
	_tick = 0.25
	if not m.hero_alive():
		return false
	_track_a4()
	if verbose and int(m.mission_time() / 10.0) != _last_print:
		_last_print = int(m.mission_time() / 10.0)
		var hu := m.cast.hush
		print("    t=%5.1f vessa %3.0f/%3.0f mana %3.0f lvl %d | knives %2d | escort %d | vey %s | hush %s %s | lit %d" % [
				m.mission_time(), m.hero.hp, m.hero.max_hp, m.hero.mana, m.hero.level, m.assassins().size(),
				m.escort_alive(), ("%.0f" % m.vey.hp) if m.cast.vey_alive() else "-",
				m.cast.hush_state, ("%.0f" % hu.hp) if hu and is_instance_valid(hu) else "-", m.lit_count])
	_dodge()
	_fireball()
	_move()
	_escort()
	return false


func _track_a4() -> void:
	var m := main
	if _a4_alive < 0 and m.waves_fired.has(&"A4"):
		_a4_alive = m.escort_alive()
	if _a4_alive >= 0 and _a4_after < 0 and m.mission_time() >= Mission00.FALL_TIME - 1.0:
		_a4_after = m.escort_alive()


## A Blink ring on Vessa: Ember Step 6 m away from it (toward the courtyard centre).
func _dodge() -> void:
	var m := main
	var c := m.cast
	if c == null or c.hush == null or not is_instance_valid(c.hush):
		return
	if not c.get(&"_blink_pending") or c.blink_target != m.hero or _dodged_blink == c.blinks:
		return
	_dodged_blink = c.blinks
	var hero := m.hero
	var away := hero.global_position - c.hush.global_position
	away.y = 0.0
	if away.length() < 0.1:
		away = Vector3(-1.0, 0.0, 1.0)
	var to := m.clamp_to_play_area(hero.global_position + away.normalized() * 6.0)
	if hero.command_cast(&"ember_step", to) == "":
		_dodges += 1
	else:
		hero.command_move(to)


func _fireball() -> void:
	var m := main
	var hero := m.hero
	var best: Unit = null
	var best_n := 0
	for u in m.assassins():
		if not u.is_alive() or u.is_hidden_from_auto_target():
			continue
		if Mission00._flat(u.global_position, hero.global_position) > 11.0:
			continue
		var n := 0
		for o in m.assassins():
			if Mission00._flat(o.global_position, u.global_position) <= 3.0:
				n += 1
		if n > best_n:
			best_n = n
			best = u
	if best:
		hero.command_cast(&"fireball", best.global_position)


func _move() -> void:
	var m := main
	var hero := m.hero
	if _route_i < ROUTE.size():
		var b := m.brazier(ROUTE[_route_i])
		if b.lit:
			_route_i += 1
			return
		if Mission00._flat(hero.global_position, b.global_position) > 2.0 and not hero.has_move_order():
			hero.command_move(b.global_position + Vector3(1.2, 0.0, 0.0))
		return
	if Mission00._flat(hero.global_position, HOLD_SPOT) > 3.0 and not hero.has_move_order() \
			and not main.cast.get(&"_blink_pending"):
		hero.command_move(HOLD_SPOT)


func _escort() -> void:
	var m := main
	for u in m.escort:
		if not is_instance_valid(u) or not u.is_alive():
			continue
		if u.attack_target != null:
			continue
		var near: Unit = null
		var nd := INF
		for e in m.assassins():
			var d := Mission00._flat(e.global_position, m.hero.global_position)
			if d <= 12.0 and d < nd and not e.is_hidden_from_auto_target():
				nd = d
				near = e
		if near:
			u.command_attack(near)
		elif Mission00._flat(u.global_position, m.hero.global_position) > 9.0:
			u.command_move(m.hero.global_position + Vector3(randf_range(-3, 3), 0.0, randf_range(-3, 3)))
