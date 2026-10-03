extends SceneTree
## Tasks 19.C7a + 19.C7b (+ the 19.C9 skip parity of m0_fall / m0_dawn): mission 0 "The Night of Knives"
## (docs/design/mission-00.md "Implementation tasks" / "Done when"). One fresh mission per phase:
## - map:      spawn points resolve within 1.5 m; no navmesh path from the courtyard reaches x > -7 or z < 7; start
##             state (Vessa 169 / 375, L2, cap 3, Ember Step, no points, no economy, items hidden, 8 escort, Vey,
##             watch-keep 2 000 HP / no training / no shop); a brazier lit by Vessa in 3 s (reset on leaving) heals a
##             Flame Guard at 5 m by 2 HP / s and not at 7 m; a Shade 13 m from a lit brazier is seen, one 9 m from
##             Vessa alone is not (night x 0.6).
## - victory:  scripted normal run (the 3 fires by 3:00, the courtyard, waves killed as they come): E1-E10 in order,
##             wave counts and sides, side warnings, Hush Smoke / flee, m0_fall end state, Grief's Fire, dawn at 8:00,
##             victory 2 s after m0_dawn, the saved flags (own save file).
## - dark:     hard; only 2 fires: Dark hold waves (4 Shades) every 30 s after 8:00 at the unlit side, victory 2 s
##             after the 3rd fire; hard counts (A1 6, Hush 1 200 HP).
## - defeat:   easy; Vessa 60 % HP, A1 = 2 Shades; Vessa killed = L12, obj_vessa failed, defeat 3 s later.
## - skip:     cinematics on: m0_fall and m0_dawn fallback cards play (tree paused, clock frozen) and a skip leaves the
##             same end states as the cinematics-off run.
## - m01:      mission 1 started with `m0_escort_saved` in the save has 2 more Flame Guards.
## Run:  godot --headless --path . -s tests/test_19_c7.gd --fixed-fps 60 --quit-after 40000

const TASK_ID := "19_c7"
const MISSION := "res://missions/mission_00.tscn"
const MISSION_1 := "res://missions/mission_01.tscn"
const SAVE := "user://test_19_c7_campaign.json"
const PHASES: Array[StringName] = [&"map", &"victory", &"dark", &"defeat", &"skip", &"m01"]

var h: MissionHarness
var main: Node
var phase := -1
var errors: Array[String] = []
var _gap := 0
var _events: Array[StringName] = []
var _vey_died := false
var _t0 := 0
var _mark := 0.0
var _hp_mark := 0.0
var _probe: Unit
var _probe_far: Unit
var _counts := {}


func _initialize() -> void:
	_remove_save()
	_next_phase()


func _process(_delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_open_phase()
		return false
	if h == null:
		return _finish()
	if h.tick():
		for e in h.errors:
			errors.append("%s: %s" % [PHASES[phase], e])
		_next_phase()
		return phase >= PHASES.size() and _finish()
	return false


func _next_phase() -> void:
	if main != null and is_instance_valid(main):
		paused = false
		var player := _player()
		if player and bool(player.call(&"is_playing")):
			player.call(&"stop")
		main.queue_free()
	main = null
	h = null
	phase += 1
	if phase < PHASES.size():
		_gap = 3


func _finish() -> bool:
	_remove_save()
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true


func _open_phase() -> void:
	h = MissionHarness.new()
	h.task_id = "%s/%s" % [TASK_ID, PHASES[phase]]
	h.timeout_frames = 30000
	_events.clear()
	_vey_died = false
	_counts.clear()
	match PHASES[phase]:
		&"map":
			h.protect_hero = false
			main = h.open(self, MISSION, {"difficulty": 1})
			h.steps.add("ready", _ready_m, 600)
			h.steps.add("start state", _check_start, 10)
			h.steps.add("bounds", _check_bounds, 10)
			h.steps.add("brazier resets", _brazier_reset, 400)
			h.steps.add("brazier lights", _brazier_light, 400)
			h.steps.add("warmth", _warmth, 300)
			h.steps.add("night sight", _night_sight, 30)
		&"victory":
			main = h.open(self, MISSION, {"difficulty": 1,
					"set": {"save_campaign_on_victory": true, "campaign_save_path": SAVE}})
			h.steps.add("ready", _ready_m, 600)
			h.steps.add("light bell", _light.bind(&"bell"), 600)
			h.steps.add("light gate", _light.bind(&"gate"), 600)
			h.steps.add("light crag", _light.bind(&"crag"), 600)
			h.steps.add("back home", _home, 10)
			for w: Array in Mission00.WAVES:
				h.steps.add("to %s" % w[0], _skip_to.bind(float(w[1]) - 11.0), 10)
				h.steps.add("wave %s" % w[0], _wave_up.bind(StringName(w[0])), 1200)
				h.steps.add("fight %s" % w[0], _fight.bind(StringName(w[0])), 3600)
			h.steps.add("dawn", _to_dawn, 600)
			h.steps.add("victory", _victory, 600)
			h.steps.add("saved", _saved, 10)
		&"dark":
			main = h.open(self, MISSION, {"difficulty": 2})
			h.steps.add("ready", _ready_m, 600)
			h.steps.add("2 fires", _two_fires, 10)
			h.steps.add("A1 hard", _a1_count.bind(6), 1200)
			h.steps.add("Hush hard", _hush_hard, 20000)
			h.steps.add("to 8:00", _dark_skip, 20000)
			h.steps.add("dark waves", _dark_waves, 3000)
			h.steps.add("3rd fire", _third_fire, 600)
		&"defeat":
			h.protect_hero = false
			main = h.open(self, MISSION, {"difficulty": 0})
			h.steps.add("ready", _ready_m, 600)
			h.steps.add("easy start", _easy_start, 10)
			h.steps.add("A1 easy", _a1_count.bind(2), 1200)
			h.steps.add("Vessa falls", _kill_vessa, 10)
			h.steps.add("defeat", _defeat, 400)
		&"skip":
			main = h.open(self, MISSION, {"difficulty": 1, "set": {"cinematics_enabled": true}})
			h.steps.add("ready", _ready_m, 600)
			h.steps.add("fires", _all_fires, 10)
			h.steps.add("to the fall", _skip_fall, 30000)
			h.steps.add("fall card", _fall_card, 600)
			h.steps.add("fall skipped", _fall_skipped, 60)
			h.steps.add("to dawn", _skip_dawn, 30000)
			h.steps.add("dawn card", _dawn_card, 600)
			h.steps.add("dawn skipped", _dawn_skipped, 400)
		&"m01":
			var cs := CampaignState.open(SAVE)
			cs.set_flags({"m0_escort_saved": true}, true)
			main = h.open(self, MISSION_1, {"difficulty": 1,
					"set": {"save_campaign_on_victory": true, "campaign_save_path": SAVE}})
			h.steps.add("ready", func() -> bool: return h.is_ready(), 600)
			h.steps.add("escort bonus", _m01_bonus, 10)
	if main and main.has_signal(&"event_fired"):
		main.connect(&"event_fired", func(id: StringName) -> void: _events.append(id))


# ---------------------------------------------------------------- shared

func _m() -> Mission00:
	return main as Mission00


func _ready_m() -> bool:
	if not h.is_ready():
		return false
	if _m() and _m().vey and not _m().vey.died.is_connected(_on_vey_died):
		_m().vey.died.connect(_on_vey_died)
	return true


func _on_vey_died(_u: Unit) -> void:
	_vey_died = true


func _skip_to(t: float) -> bool:
	var now := _m().mission_time()
	if t > now:
		MissionHarness.skip_time(main, t - now)
	return true


func _kill_assassins(keep_hush := false) -> void:
	for u in _m().assassins():
		if keep_hush and u == _m().hush():
			continue
		MissionHarness.kill([u])


func _player() -> Node:
	for n in get_nodes_in_group(&"cinematic_player"):
		return n
	return null


func _near(a: Vector3, b: Vector3, tol: float) -> bool:
	return Vector2(a.x - b.x, a.z - b.z).length() <= tol


# ---------------------------------------------------------------- map phase

func _check_start() -> bool:
	var m := _m()
	var hero := m.hero
	h.check(is_equal_approx(hero.max_hp, 375.0) and is_equal_approx(hero.hp, 169.0),
			"Vessa %.0f / %.0f HP (want 169 / 375)" % [hero.hp, hero.max_hp])
	h.check(hero.level == 2 and hero.level_cap == 3, "Vessa level %d cap %d" % [hero.level, hero.level_cap])
	h.check(hero.spell_rank(&"fireball") == 1 and hero.spell_rank(&"ember_step") == 1 and hero.spell_points == 0,
			"spells fireball %d ember_step %d points %d" % [hero.spell_rank(&"fireball"), hero.spell_rank(&"ember_step"),
			hero.spell_points])
	h.check(is_equal_approx(hero.mana, hero.max_mana), "mana not full")
	h.check(m.escort.size() == 8 and m.escort_alive() == 8, "escort %d" % m.escort_alive())
	var guards := 0
	var archers := 0
	for u in m.escort:
		guards += 1 if u.unit_type.id == &"flame_guard" else 0
		archers += 1 if u.unit_type.id == &"ember_archer" else 0
	h.check(guards == 4 and archers == 4, "escort %d guards %d archers" % [guards, archers])
	h.check(m.vey != null and m.vey.is_alive() and not m.vey.is_commandable() and is_equal_approx(m.vey.max_hp, 1200.0),
			"Old Vey missing / commandable / HP")
	h.check(m.vey.get_model() != null, "Old Vey has no model (helper_vey)")
	var k := m.keep
	h.check(k != null and k is WatchKeep and is_equal_approx(k.max_hp, 2000.0) and k.trainable_types().is_empty()
			and not k.is_shop() and not k.is_drop_off(), "watch-keep wrong")
	h.check(m.economy.crystals == 0, "crystals %d" % m.economy.crystals)
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	h.check(bank == null or (bank.essence == 0 and not bank.trickle_enabled), "essence / trickle on")
	h.check(m.hud.inventory_bar == null or not m.hud.inventory_bar.visible, "inventory shown")
	h.check(m.hud.top_bar == null or not m.hud.top_bar.visible, "resource bar shown")
	h.check(m.assassins().is_empty(), "assassins at 0:00")
	h.check(h.saw("obj_dawn", "active") and h.saw("obj_braziers", "active") and h.saw("obj_vessa", "active")
			and h.saw("sec_guards", "active") and not h.saw("sec_hush", "active"), "start objectives %s" % [h.objective_log])
	h.check(h.dialogue_log.size() >= 2 and h.dialogue_log[0].begins_with("vey:") and h.dialogue_log[1].begins_with("vessa:"),
			"E1 lines %s" % [h.dialogue_log])
	h.check(m.camera_rig.bounds == Mission00.CAMERA_BOUNDS, "camera bounds %s" % m.camera_rig.bounds)
	h.check(is_equal_approx(float((m.fog.get(&"sight_scale") as Array)[0]), 0.6), "night sight scale")
	h.check(m.lighting_mood == &"night", "lighting")
	m._timers.clear()   # this phase checks the map: no waves
	return true


func _check_bounds() -> bool:
	var m := _m()
	for side: StringName in Mission00.SPAWN_POINTS:
		var p: Vector3 = Mission00.SPAWN_POINTS[side]
		var q := m.resolve_on_navmesh(p)
		h.check(_near(p, q, Mission00.SPAWN_TOLERANCE), "spawn %s resolves to %s (%.2f m)" % [side, q,
				Vector2(p.x - q.x, p.z - q.z).length()])
	var map := m.nav_region.get_navigation_map()
	var from := Vector3(-38.0, 0.0, 40.0)
	for to: Vector3 in [Vector3(-2.0, 0.0, 40.0), Vector3(-38.0, 0.0, 2.0), Vector3(20.0, 0.0, -20.0), Vector3(-2.0, 0.0, 2.0)]:
		var path := NavigationServer3D.map_get_path(map, from, to, true)
		for p in path:
			if p.x > Mission00.WALL_EAST_X or p.z < Mission00.WALL_NORTH_Z:
				h.check(false, "a path to %s crosses the bound walls at %s" % [to, p])
				break
	return true


func _brazier_reset() -> bool:
	var m := _m()
	var b := m.brazier(&"gate")
	if _t0 == 0:
		_t0 = 1
		MissionHarness.put(m.hero, b.global_position + Vector3(2.0, 0.0, 0.0))
		return false
	_t0 += 1
	if _t0 == 100:   # 1.6 s in: progress, then she walks off
		h.check(b.progress > 0.3 and not b.lit, "no lighting progress (%.2f)" % b.progress)
		MissionHarness.put(m.hero, b.global_position + Vector3(5.0, 0.0, 0.0))
	if _t0 == 104:
		h.check(is_zero_approx(b.progress) and not b.lit, "progress did not reset on leaving (%.2f)" % b.progress)
		_t0 = 0
		return true
	return false


func _brazier_light() -> bool:
	var m := _m()
	var b := m.brazier(&"gate")
	if _t0 == 0:
		_t0 = 1
		MissionHarness.put(m.hero, b.global_position + Vector3(2.0, 0.0, 0.0))
		return false
	_t0 += 1
	if b.lit:
		h.check(_t0 >= 170 and _t0 <= 200, "lit after %d frames (want ~180 = 3 s)" % _t0)
		h.check(m.lit_count == 1 and h.saw("obj_braziers", "active"), "lit count %d" % m.lit_count)
		h.check(m.has_fired(&"E2") and h.dialogue_log.any(func(l: String) -> bool: return l.contains("Light pushes back")),
				"E2 / L3 missing")
		MissionHarness.put(m.hero, Vector3(-55.0, 0.0, 15.0))
		_t0 = 0
		return true
	return false


func _warmth() -> bool:
	var m := _m()
	var b := m.brazier(&"gate")
	if _probe == null:
		_probe = m.escort[0]
		_probe_far = m.escort[1]
		var dir := Vector3(1.0, 0.0, 1.0).normalized()
		MissionHarness.put(_probe, b.global_position + dir * 5.0)
		MissionHarness.put(_probe_far, b.global_position + dir * 7.0 + Vector3(0.0, 0.0, 0.0))
		_probe_far.global_position = b.global_position + Vector3(-7.0, 0.0, 0.0)
		_probe.hp = 50.0
		_probe_far.hp = 50.0
		_t0 = 0
		return false
	_t0 += 1
	if _t0 == 30:   # settle: start measuring on a tick boundary
		_hp_mark = _probe.hp
		_mark = _probe_far.hp
	if _t0 == 30 + 240:   # 4 s
		var gained := _probe.hp - _hp_mark
		h.check(gained >= 7.0 and gained <= 9.0, "warmth at 5 m gave %.1f HP in 4 s (want 8)" % gained)
		h.check(is_equal_approx(_probe_far.hp, _mark), "warmth reached 7 m (%.1f -> %.1f)" % [_mark, _probe_far.hp])
		_t0 = 0
		return true
	return false


func _night_sight() -> bool:
	var m := _m()
	var b := m.brazier(&"gate")
	if _t0 == 0:
		_t0 = 1
		MissionHarness.immortal(m.hero)
		MissionHarness.put(m.hero, Vector3(-55.0, 0.0, 15.0))
		for u in m.escort:   # out of the way (their own sight would see the probes)
			MissionHarness.put(u, Vector3(-55.0, 0.0, 56.0))
		MissionHarness.put(m.vey, Vector3(-52.0, 0.0, 56.0))
		var lit_probe := m.make_unit("shade")
		m._spawn(lit_probe, Unit.Team.ENEMY, b.global_position + Vector3(13.0, 0.0, 0.0))   # (-19, 32): 13 m
		m.set_dormant(lit_probe, true)
		_probe = lit_probe
		var dark_probe := m.make_unit("shade")
		m._spawn(dark_probe, Unit.Team.ENEMY, m.hero.global_position + Vector3(9.0, 0.0, 0.0))
		m.set_dormant(dark_probe, true)
		_probe_far = dark_probe
		return false
	_t0 += 1
	if _t0 < 3:
		return false
	m.fog.update_team(Unit.Team.PLAYER)
	h.check(m.fog.is_visible(Unit.Team.PLAYER, _probe.global_position),
			"a Shade 13 m from the lit brazier is not seen")
	h.check(not m.fog.is_visible(Unit.Team.PLAYER, _probe_far.global_position),
			"a Shade 9 m from Vessa alone is seen (night sight not applied)")
	return true


# ---------------------------------------------------------------- victory phase

func _light(id: StringName) -> bool:
	var m := _m()
	var b := m.brazier(id)
	if b.lit:
		return true
	if not _near(m.hero.global_position, b.global_position, 2.5):
		MissionHarness.put(m.hero, b.global_position + Vector3(1.5, 0.0, 0.0))
	return false


func _home() -> bool:
	var m := _m()
	h.check(m.lit_count == 3 and h.saw("obj_braziers", "done") and m.has_fired(&"E2b"), "3 fires: obj_braziers")
	h.check(m.mission_time() < 180.0, "fires lit after 3:00")
	MissionHarness.put(m.hero, Mission00.VESSA_START)
	return true


func _wave_up(id: StringName) -> bool:
	var m := _m()
	if not m.waves_fired.has(id):
		return false
	var n := 0
	for u in m.assassins():
		if not m.fall_units.has(u):   # the Fall Shades (6:40) are still up when A5 comes
			n += 1
	var want := {&"A1": 4, &"A2": 5, &"A3": 5, &"A4": 10, &"A5": 7}
	h.check(n == int(want[id]), "%s: %d assassins (want %d)" % [id, n, want[id]])
	match id:
		&"A2":
			h.check(m.warnings.has("A2:e") and m.warnings.has("A2:n"), "A2 warnings %s" % [m.warnings])
			h.check(m.has_fired(&"E3"), "E3")
		&"A3":
			var hush := m.hush()
			h.check(hush != null and hush.is_alive() and is_equal_approx(hush.max_hp, 900.0), "Hush 900 HP")
			h.check(_near(hush.global_position, Mission00.SPAWN_POINTS[&"n"], 4.0), "Hush not at SP_N")
			h.check(h.saw("sec_hush", "active") and m.has_fired(&"E4"), "E4 / sec_hush")
		&"A4":
			h.check(m.has_fired(&"E7"), "E7")
	return true


func _fight(id: StringName) -> bool:
	var m := _m()
	_t0 += 1
	if id == &"A3":
		var hush := m.hush()
		if not _counts.has("blink_t"):
			# Blink Strike: Vessa (wounded: the lowest HP % hero) Ember Steps 6 m out of the ring while it closes ->
			# the strike misses (0 damage).
			if not _counts.has("setup"):
				_counts["setup"] = true
				h.protect_hero = false
				MissionHarness.immortal(m.hero)
				m.hero.hp = m.hero.max_hp * 0.3
			if bool(m.cast.get(&"_blink_pending")) and m.cast.blink_target == m.hero and not _counts.has("dodging"):
				_counts["dodging"] = true
				_counts["hp"] = m.hero.hp
				_counts["hits"] = m.cast.blink_hits
				var away := (m.hero.global_position - hush.global_position) * Vector3(1, 0, 1)
				var to := m.clamp_to_play_area(m.hero.global_position + away.normalized() * 6.0)
				if m.hero.command_cast(&"ember_step", to) != "":
					MissionHarness.put(m.hero, to)
			if _counts.has("dodging") and not bool(m.cast.get(&"_blink_pending")):
				h.check(m.cast.blink_hits == int(_counts["hits"]) and m.hero.hp >= float(_counts["hp"]) - 30.0,
						"a dodged Blink Strike hit (HP %.0f -> %.0f)" % [_counts["hp"], m.hero.hp])
				_counts["blink_t"] = _t0
				h.protect_hero = true
			elif _t0 > 1300:
				h.check(false, "Hush never used Blink Strike")
				_counts["blink_t"] = _t0
			return false
		var bt := int(_counts["blink_t"])
		if _t0 == bt + 60 and hush and hush.is_alive():
			hush.hp = hush.max_hp * 0.49
			hush.take_damage(1.0, m.hero)
			h.check(m.has_fired(&"E5") and m.cast.hush_state == &"smoke", "Hush did not Smoke at 50 %")
		if _t0 == bt + 160 and hush and hush.is_alive():
			hush.hp = hush.max_hp * 0.24
			hush.take_damage(1.0, m.hero)
			h.check(m.has_fired(&"E6") and h.saw("sec_hush", "done") and m.cast.hush_state == &"flee",
					"Hush did not flee at 25 %")
		if _t0 < bt + 300 or (m.cast.hush_on_field() and _t0 < bt + 1900):
			return false
		h.check(m.cast.hush_state == &"gone" and not m.cast.hush_on_field(), "Hush still on the field (%s)" % m.cast.hush_state)
	elif _t0 < 600:
		return false
	_kill_assassins()
	_t0 = 0
	return true


func _to_dawn() -> bool:
	var m := _m()
	if _t0 == 0:
		_t0 = 1
		h.check(m.has_fired(&"E8") and h.dialogue_log.any(func(l: String) -> bool: return l.contains("Two more hours")), "E8 / L10")
		h.check(m.fall_done and not m.cast.vey_alive() and not _vey_died, "m0_fall: Vey removed (no death event)")
		h.check(m.vey.has_left_map() if is_instance_valid(m.vey) else true, "Vey did not leave the map")
		h.check(m.hero.has_modifier(Mission00.GRIEF_MOD), "no Grief's Fire after the fall")
		h.check(h.dialogue_log.any(func(l: String) -> bool: return l.contains("ALL of you")), "L11")
		h.check(m.seam == null or StringName(m.seam.get(&"state")) == &"sealed", "seam not sealed")
		_skip_to(Mission00.DAWN_TIME - 1.0)
		return false
	return m.has_fired(&"E10")


func _victory() -> bool:
	var m := _m()
	if h.ended < 0:
		return false
	h.check(h.ended == 1, "defeat instead of victory")
	h.check(m.mission_time() >= 481.5 and m.mission_time() <= 483.0, "victory at %.2f (want 482)" % m.mission_time())
	h.check(m.dawn_done and m.assassins().is_empty() and m.lighting_mood == &"dawn", "m0_dawn end state")
	h.check(m.emberguard.size() == 5 and _near((m.emberguard[0] as Unit).global_position, Mission00.DAWN_ASHBY, 1.0),
			"Ashby and the riders")
	h.check(m.hero.is_alive(), "Vessa dead")
	var order: Array[StringName] = [&"E1", &"E2", &"E2b", &"E3", &"E4", &"E5", &"E6", &"E7", &"E8", &"E9", &"E10"]
	var seen: Array[StringName] = []
	for e in _events:
		if order.has(e):
			seen.append(e)
	h.check(seen == order, "event order %s" % [seen])
	return true


func _saved() -> bool:
	var m := _m()
	var cs := CampaignState.open(SAVE)
	h.check(cs.is_completed(&"m00") and cs.unlocked_missions().has(&"m01"), "m00 not saved / m01 locked")
	h.check(cs.flag("m0_hush_driven") == (m.objective_state("sec_hush") == "done"), "m0_hush_driven flag")
	h.check(cs.flag("m0_hush_driven"), "Hush was driven off but the flag is false")
	h.check(cs.flag("m0_escort_saved") == (m.objective_state("sec_guards") == "done"), "m0_escort_saved flag")
	h.check(not cs.flag("m0_escort_saved") or m.escort_alive() == 8, "escort flag with losses")
	return true


# ---------------------------------------------------------------- dark hold phase (hard)

func _two_fires() -> bool:
	var m := _m()
	MissionHarness.immortal(m.hero)
	m.brazier(&"bell").light()
	m.brazier(&"gate").light()
	return m.lit_count == 2


func _a1_count(want: int) -> bool:
	var m := _m()
	if not m.waves_fired.has(&"A1"):
		return false
	h.check(m.assassins().size() == want, "A1: %d Shades (want %d)" % [m.assassins().size(), want])
	h.check(m.warnings.has("A1:ne") == m.side_watched(&"ne"), "A1 warning %s" % [m.warnings])
	_kill_assassins()
	return true


func _hush_hard() -> bool:
	var m := _m()
	if m.mission_time() < 179.0:
		_skip_to(179.0)
		_kill_assassins()
		return false
	if not m.waves_fired.has(&"A3"):
		return false
	h.check(m.hush() != null and is_equal_approx(m.hush().max_hp, 1200.0), "Hush hard HP")
	return true


func _dark_skip() -> bool:
	var m := _m()
	if m.dark_hold:
		return true
	_kill_assassins()
	if m.mission_time() < Mission00.DAWN_TIME - 2.0:
		_skip_to(minf(Mission00.DAWN_TIME - 2.0, m.mission_time() + 40.0))
		return false
	return m.dark_hold


func _dark_waves() -> bool:
	var m := _m()
	if _t0 == 0:
		_t0 = 1
		_counts.clear()
		h.check(m.dark_hold and m.objective_text(&"obj_dawn").begins_with("Light the last watch-fires"), "Dark hold text")
		h.check(not m.has_fired(&"E10") and h.ended < 0, "dawn came without the third fire")
	if m.dark_waves < 2:
		if m.dark_waves == 1 and _counts.is_empty():
			var n := 0
			for u in m.assassins():
				if _near(u.global_position, Mission00.SPAWN_POINTS[&"e"], 4.0):
					n += 1
			_counts["first"] = n
			_counts["t"] = m.mission_time()
		return false
	h.check(int(_counts.get("first", 0)) == 4, "first Dark hold wave: %d Shades at SP_E (want 4 on hard)" % int(_counts.get("first", 0)))
	h.check(absf(m.mission_time() - float(_counts.get("t", 0.0)) - Mission00.DARK_HOLD_EVERY) < 1.5,
			"Dark hold every %.1f s" % (m.mission_time() - float(_counts.get("t", 0.0))))
	_t0 = 0
	return true


func _third_fire() -> bool:
	var m := _m()
	if not m.brazier(&"crag").lit:
		m.brazier(&"crag").light()
		_mark = m.mission_time()
		h.check(m.has_fired(&"E10"), "the third fire after 8:00 did not bring dawn at once")
		return false
	if h.ended < 0:
		return false
	h.check(h.ended == 1, "dark hold: defeat")
	h.check(absf(m.mission_time() - _mark - 2.0) < 0.3, "victory %.2f s after the third fire (want 2)" % (m.mission_time() - _mark))
	h.check(not m.dark_hold and m.assassins().is_empty(), "dark hold after dawn")
	return true


# ---------------------------------------------------------------- defeat phase (easy)

func _easy_start() -> bool:
	var m := _m()
	h.check(is_equal_approx(m.hero.hp, 225.0), "easy start HP %.0f (want 225 = 60 %%)" % m.hero.hp)
	return true


func _kill_vessa() -> bool:
	var m := _m()
	_mark = m.mission_time()
	m.hero.take_damage(1.0e6, null)
	return true


func _defeat() -> bool:
	var m := _m()
	if h.ended < 0:
		return false
	h.check(h.ended == 0, "not a defeat")
	h.check(absf(m.mission_time() - _mark - 3.0) < 0.3, "defeat %.2f s after Vessa fell (want 3)" % (m.mission_time() - _mark))
	h.check(h.saw("obj_vessa", "failed") and m.has_fired(&"E11"), "obj_vessa / E11")
	h.check(h.dialogue_log.any(func(l: String) -> bool: return l.contains("I'm sorry")), "L12")
	return true


# ---------------------------------------------------------------- skip parity (cinematics on)

func _all_fires() -> bool:
	var m := _m()
	for b in m.braziers:
		b.light()
	return m.lit_count == 3


func _skip_fall() -> bool:
	var m := _m()
	_kill_assassins()
	var hush := m.hush()
	if hush and hush.is_alive():
		m.cast.hush_leave()
	if m.mission_time() < Mission00.FALL_TIME - 1.0:
		_skip_to(minf(Mission00.FALL_TIME - 1.0, m.mission_time() + 40.0))
		return false
	return true


func _fall_card() -> bool:
	var m := _m()
	if not m.has_fired(&"E9"):
		return false
	var player := _player()
	h.check(player != null and bool(player.call(&"is_playing")), "m0_fall: no card playing")
	h.check(paused, "m0_fall card: the tree is not paused (PAUSE)")
	h.check(not m.fall_done and m.cast.vey_alive(), "m0_fall end state ran before the card ended")
	_mark = m.mission_time()
	if player:
		player.call(&"skip")
	return true


func _fall_skipped() -> bool:
	var m := _m()
	if not m.fall_done:
		return false
	h.check(absf(m.mission_time() - _mark) < 0.1, "the clock ran during the card")
	h.check(not m.cast.vey_alive() and not _vey_died, "skip: Vey not removed cleanly")
	h.check(_near(m.hero.global_position, Mission00.FALL_VESSA_END, 0.3), "skip: Vessa at %s" % m.hero.global_position)
	var alive := 0
	for u: Variant in m.fall_units:
		if is_instance_valid(u) and (u as Unit).is_alive():
			alive += 1
			h.check((u as Unit).attack_target == m.hero, "a Fall Shade does not attack Vessa")
	h.check(alive == 3, "skip: %d Fall Shades alive (want 3)" % alive)
	h.check(m.hero.has_modifier(Mission00.GRIEF_MOD) and is_equal_approx(m.hero.get_stat(&"spell_power")
			- m.hero.get_base_stat(&"spell_power"), 50.0), "skip: Grief's Fire")
	h.check(m.seam == null or StringName(m.seam.get(&"state")) == &"sealed", "skip: seam")
	h.check(h.dialogue_log.any(func(l: String) -> bool: return l.contains("ALL of you")), "skip: L11")
	return true


func _skip_dawn() -> bool:
	var m := _m()
	_kill_assassins()
	if m.mission_time() < Mission00.DAWN_TIME - 1.0:
		_skip_to(minf(Mission00.DAWN_TIME - 1.0, m.mission_time() + 40.0))
		return false
	return true


func _dawn_card() -> bool:
	var m := _m()
	if not m.has_fired(&"E10"):
		return false
	var player := _player()
	h.check(player != null and bool(player.call(&"is_playing")), "m0_dawn: no card playing")
	h.check(not m.dawn_done and h.ended < 0, "dawn end state before the card ended")
	if player:
		player.call(&"skip")
	_mark = m.mission_time()
	return true


func _dawn_skipped() -> bool:
	var m := _m()
	if h.ended < 0:
		return false
	h.check(h.ended == 1 and m.dawn_done, "skip: no victory")
	h.check(absf(m.mission_time() - _mark - 2.0) < 0.3, "skip: victory %.2f s after the card" % (m.mission_time() - _mark))
	h.check(m.assassins().is_empty() and m.lighting_mood == &"dawn", "skip: dawn end state")
	return true


# ---------------------------------------------------------------- mission 1 bonus

func _m01_bonus() -> bool:
	var bonus := 0
	var guards := 0
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == Unit.Team.PLAYER and u.unit_type and u.unit_type.id == &"flame_guard":
			guards += 1
			if u.has_meta(&"m0_escort"):
				bonus += 1
	h.check(bonus == 2, "mission 1: %d escort Flame Guards (want 2)" % bonus)
	h.check(guards == 6, "mission 1 normal: %d Flame Guards (want 4 + 2)" % guards)
	return true


func _remove_save() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
