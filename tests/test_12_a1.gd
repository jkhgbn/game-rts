extends SceneTree
## Task 12.A1 (bot rules 11-13 for the filled map; docs/design/map-fill.md section 7 and "Done when" 12.A1).
## The step-12 systems are STUBBED here (inner classes below, reached by the bot only through their groups):
## a river (bank_of / crossings), 8 capture points with a simple 2 Hz capture pass and shrines waking at 3:00, 8 camps
## (Ruin Wardens with 60 HP stand in for the creatures), one epic beast (a stand-in in group "beasts", spawned at 6:00
## on the enemy's West Heath mirror), and a deer (group "game_critters", not a Unit). The skirmish's own map-fill
## flags are switched off (when they exist) so only the stubs are there.
## Part static: the knobs of map-fill.md 7 (code presets, ice() / nature(), data/ai/*.tres), mission_01 map_fill off;
##   an AIMapFill with no services is inert (active false, no creep, no squad, no wizard job).
## Part units (in the normal scene, stubs present): creep_target rules (creep_start, ratio, tiers, own bank only, the
##   own-near nest, the stag from 900, the hollow on hard only, beasts by beast_ratio, never easy), 13a scout_via /
##   scout_point_ok, 13b attack_waypoint (hard only; the side with fewer seen towers), B8 / B10 candidates.
## Part normal: a Shadow bot (ENEMY, normal, attack_ratio 50 so rule 7 never launches "ready") vs an idle player:
##   CREEP of its wallow by 3:15 (cleared by 3:45) and of its ford nest (cleared by 6:30); never a player-side camp
##   or the hollow; a 2-soldier squad to its well first, then its home tower; a bot unit at its own shrine at 3:00
##   (+-6 s) and the shrine captured; the scout takes the river loop ((12, 22) after (16, -6)) and never comes within
##   11 m of the crown while the wardens live; the deer is never attacked; two player soldiers taking the bot's well
##   are fought (DEFEND or POINT defence) and the well stays / becomes the bot's; the beast is crept (11e, B11
##   candidate while it runs); PERF: the map-fill rules' median decision cost <= PERF_LIMIT_CAL calibration loops per
##   think tick (see below; the old line was 0.1 ms).
## Calibration (2026-10-02, as test_20_a3 in 394f88c3): the same map-fill code measured a 0.068 ms median on a quiet
##   laptop and 0.130 ms on a saturated one (every number of that run, the whole bot tick included, about 2x), so the
##   fixed 0.1 ms line flipped. The test times a fixed GDScript loop (_calib_once, the same workload as test_20_a3's)
##   every CAL_EVERY frames of each part, best of CAL_REPEAT, and judges the map-fill median as a RATIO of that loop's
##   median in the same part: same machine, same moment. The ms numbers stay in the log.
## Part hard: 3-soldier squads, a bot unit at its shrine >= 10 s before it wakes, the own-bank hollow crept.
## Part real (only with --only=real): the same normal bot against the REAL step-12 systems of the skirmish (no stubs,
##   notes only): prints its creeps, squad / wizard jobs and captures to 7:00.
## Run:  godot --headless --path . -s tests/test_12_a1.gd --fixed-fps 60 --quit-after 60000
##   (the default parts end after about 46 800 frames: 7:15 + 5:45 of match time plus two navmesh bakes)
##   Options after `--`: --only=static|normal|hard|real (comma list; default static, normal, hard)

const TASK_ID := "12.A1"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const NEUTRAL := 2
const PERF_LIMIT_MS := 0.1   ## info only now (the old absolute line, printed next to the ratio verdict)
## Map-fill median <= this many calibration-loop medians. Quiet laptop 2026-10-02: loop 0.232 ms (test_20_a3's quiet
## runs), map-fill median 0.068 / 0.080 ms (normal / hard, CI 14:38) = 0.29 / 0.34 loops; 0.43 loops = the old 0.1 ms
## line on that quiet machine (~1.3x headroom, as before). A saturated run (a background service on 13 of 16 threads):
## loop 0.75 ms, map-fill 0.132 / 0.118 ms = 0.175 / 0.157 loops (the old ms line failed it).
const PERF_LIMIT_CAL := 0.43
const CAL_EVERY := 30
const CAL_REPEAT := 3
const PART_LIMIT := {"normal": 435.0, "hard": 345.0, "real": 420.0}
const SHRINE_E := Vector3(22.0, 0.0, 6.0)
const WELL_E := Vector3(30.0, 0.0, 24.0)
const DEER_POS := Vector3(30.0, 0.0, -22.0)
const BEAST_POS := Vector3(53.0, 0.0, -13.0)
const BEAST_TIME := 360.0
const RAID_TIME := 300.0
## id, name, kind, tier, pos, creatures, strength each
const CAMPS := [
	["camp_wallow_n", "Bristleback Wallow N", &"bristleback", 1, Vector3(14.0, 0.0, -57.0), 2, 100.0],
	["camp_wallow_s", "Bristleback Wallow S", &"bristleback", 1, Vector3(-14.0, 0.0, 57.0), 2, 100.0],
	["camp_nest_n", "Reed Ford Nest", &"mirefang", 2, Vector3(-8.5, 0.0, -34.0), 3, 110.0],
	["camp_nest_s", "Willow Ford Nest", &"mirefang", 2, Vector3(8.5, 0.0, 34.0), 3, 110.0],
	["camp_hollow_nw", "Gloomcap Hollow NW", &"gloomcap", 2, Vector3(-55.0, 0.0, -55.0), 2, 60.0],
	["camp_hollow_se", "Gloomcap Hollow SE", &"gloomcap", 2, Vector3(55.0, 0.0, 55.0), 2, 60.0],
	["camp_stag_w", "Stag Glade W", &"hollow_stag", 3, Vector3(-37.0, 0.0, -10.0), 1, 700.0],
	["camp_stag_e", "Stag Glade E", &"hollow_stag", 3, Vector3(37.0, 0.0, 10.0), 1, 700.0],
]
const PLAYER_CAMPS := ["Bristleback Wallow S", "Willow Ford Nest", "Gloomcap Hollow NW", "Stag Glade W"]
## id, name, kind, pos, radius, time
const POINTS := [
	["tower_nw", "Rookwatch", &"watchtower", Vector3(-24.0, 0.0, -41.0), 7.0, 12.0],
	["tower_se", "Owlwatch", &"watchtower", Vector3(24.0, 0.0, 41.0), 7.0, 12.0],
	["tower_s", "Millwatch", &"watchtower", Vector3(-6.0, 0.0, 40.0), 7.0, 12.0],
	["tower_n", "Saltwatch", &"watchtower", Vector3(6.0, 0.0, -40.0), 7.0, 12.0],
	["well_w", "Mossmere Well", &"well", Vector3(-30.0, 0.0, -24.0), 6.0, 15.0],
	["well_e", "Stonemere Well", &"well", Vector3(30.0, 0.0, 24.0), 6.0, 15.0],
	["shrine_w", "West Wayshrine", &"shrine", Vector3(-22.0, 0.0, -6.0), 6.0, 8.0],
	["shrine_e", "East Wayshrine", &"shrine", Vector3(22.0, 0.0, 6.0), 6.0, 8.0],
]


# ---------------------------------------------------------------- stubs (the frozen contract's shapes only)

class StubRiver extends Node:
	func _ready() -> void:
		add_to_group("river")

	## West bank = PLAYER, east = ENEMY along the map-fill.md 2.1 polylines (straight fits), -1 on the isle.
	func bank_of(pos: Vector3) -> int:
		if Vector2(pos.x, pos.z).length() < 14.5:
			return -1
		var bx := 0.0
		if pos.z < -12.5:
			bx = -2.5 + 0.2525 * (pos.z + 12.5)
		elif pos.z > 12.5:
			bx = 2.5 + 0.2525 * (pos.z - 12.5)
		return 1 if pos.x > bx else 0

	func is_water(_pos: Vector3) -> bool:
		return false

	func crossings() -> Array:
		return [
			{"id": &"bridge_road_n", "kind": &"bridge_road", "center": Vector3(-12.0, 0.0, -48.7), "length": 9.0},
			{"id": &"bridge_road_s", "kind": &"bridge_road", "center": Vector3(12.0, 0.0, 48.7), "length": 9.0},
			{"id": &"ford_n", "kind": &"ford", "center": Vector3(-8.5, 0.0, -34.0), "length": 7.0},
			{"id": &"ford_s", "kind": &"ford", "center": Vector3(8.5, 0.0, 34.0), "length": 7.0},
			{"id": &"bridge_crown_w", "kind": &"bridge_lane", "center": Vector3(-9.02, 0.0, 9.02), "length": 6.5},
			{"id": &"bridge_crown_e", "kind": &"bridge_lane", "center": Vector3(9.02, 0.0, -9.02), "length": 6.5},
			{"id": &"steps_nw", "kind": &"steps", "center": Vector3(-9.02, 0.0, -9.02), "length": 6.0},
			{"id": &"steps_se", "kind": &"steps", "center": Vector3(9.02, 0.0, 9.02), "length": 6.0},
		]


class StubPoint extends Node3D:
	var point_id: StringName = &""
	var kind: StringName = &""
	var display_name := ""
	var owner_team := -1
	var capture_team := -1
	var progress := 0.0
	var capture_radius := 6.0
	var capture_time := 12.0
	var state: StringName = &"idle"
	var bank := -1
	var wake_at := INF
	var level: Node = null
	var captures: Array = []          # [team, time] of every capture

	func _ready() -> void:
		add_to_group("capture_points")

	func time_until_awake() -> float:
		if state == &"awake":
			return INF
		return maxf(0.0, wake_at - float(level.call(&"match_time")))

	func is_alive() -> bool:
		return true

	## A simplified 4.3 capture pass (presence, contest, neutralise, far bank x1.25, decay 10 % / s).
	func step(dt: float, n: Array) -> void:
		var now := float(level.call(&"match_time"))
		if kind == &"shrine" and state != &"awake":
			if now >= wake_at:
				state = &"awake"
			else:
				return
		if n[0] > 0 and n[1] > 0:
			state = &"contested"
			return
		var t := 0 if n[0] > 0 else (1 if n[1] > 0 else -1)
		var idle: StringName = &"awake" if kind == &"shrine" else &"idle"
		if t < 0:
			progress = maxf(0.0, progress - 0.1 * dt)
			if progress <= 0.0:
				capture_team = -1
			state = idle
			return
		if owner_team == t:
			progress = 0.0
			capture_team = -1
			state = idle
			return
		if capture_team != t:
			progress = 0.0
		capture_team = t
		state = &"neutralising" if owner_team >= 0 else &"capturing"
		var mult := 1.25 if bank >= 0 and bank != t else 1.0
		progress += dt * minf(1.0 + 0.25 * float(n[t] - 1), 1.75) / (capture_time * mult)
		if progress < 1.0:
			return
		progress = 0.0
		capture_team = -1
		if owner_team >= 0:
			owner_team = -1
			state = idle
			return
		owner_team = t
		captures.append([t, now])
		state = idle
		if kind == &"shrine":
			state = &"asleep"
			wake_at = INF


class StubPoints extends Node:
	var list: Array = []
	var _acc := 0.0

	func _ready() -> void:
		add_to_group("capture_points_service")

	func points(kind: StringName = &"") -> Array:
		var out: Array = []
		for p in list:
			if kind == &"" or p.kind == kind:
				out.append(p)
		return out

	func _physics_process(delta: float) -> void:
		_acc += delta
		if _acc < 0.5:
			return
		var dt := _acc
		_acc = 0.0
		for p in list:
			var n := [0, 0]
			for node in get_tree().get_nodes_in_group("units"):
				var u := node as Unit
				if u == null or not u.is_alive() or int(u.team) > 1 or u.is_worker():
					continue
				if Vector2(u.global_position.x - p.global_position.x, u.global_position.z - p.global_position.z).length() \
						<= p.capture_radius:
					n[int(u.team)] += 2 if u is Wizard else 1
			p.step(dt, n)


class StubCamp extends Node3D:
	var camp_id: StringName = &""
	var kind: StringName = &""
	var tier := 1
	var camp_level := 0
	var display_name := ""
	var each := 100.0
	var units: Array = []
	var cleared_at := -1.0

	func _ready() -> void:
		add_to_group("neutral_camps")

	func creatures() -> Array:
		var out: Array = []
		for u in units:
			if is_instance_valid(u) and (u as Unit).is_alive():
				out.append(u)
		return out

	func is_cleared() -> bool:
		return creatures().is_empty()

	func strength() -> float:
		return each * float(creatures().size())


class StubCamps extends Node:
	var list: Array = []

	func _ready() -> void:
		add_to_group("camp_manager")

	func camps() -> Array:
		return list


class StubBeasts extends Node:
	var list: Array = []
	var lairs := {}

	func _ready() -> void:
		add_to_group("epic_beasts")

	func beasts() -> Array:
		var out: Array = []
		for b in list:
			if is_instance_valid(b) and (b as Unit).is_alive():
				out.append(b)
		return out

	func lair_of(beast: Node) -> Dictionary:
		return lairs.get(beast.get_instance_id(), {})

	func strength_of(_beast: Node) -> float:
		return 300.0


class StubDeer extends Node3D:
	var kind: StringName = &"deer"
	var team := 2
	var max_hp := 60.0
	var hp := 60.0
	var hit_by: Array = []

	func _ready() -> void:
		add_to_group("game_critters")

	func is_alive() -> bool:
		return hp > 0.0

	func take_damage(amount: float, attacker: Node3D = null) -> void:
		hp -= amount
		hit_by.append(attacker)

	func target_radius() -> float:
		return 0.5

	func is_game_critter() -> bool:
		return true


# ---------------------------------------------------------------- runner

var main: Node
var bot: Node
var part := ""
var _queue: Array[String] = []
var _wait := 0
var _gap := 0
var _t := 0.0
var _frame := 0
var _errors: Array[String] = []
var _notes: Array[String] = []
var _s := {}
var _points_svc: StubPoints
var _camps_svc: StubCamps
var _beasts_svc: StubBeasts
var _deer: StubDeer
var _cal_pts: Array[Vector3] = []
var _cal_dict := {}
var _cal_samples: Array[int] = []
var _cal_sink := 0.0


func _initialize() -> void:
	# 20.A3: the Replay Lab's auto recorder off (docs/plan/replay-lab.md: tests turn it off; its session froze the
	# skirmish economy on 2026-09-26 22:00).
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for p in a.trim_prefix("--only=").split(",", false):
				only.append(p)
	for i in 256:
		_cal_pts.append(Vector3(float((i * 37) % 101) - 50.0, 0.0, float((i * 53) % 97) - 48.0))
	for i in 64:
		_cal_dict[i] = i * 0.5
	if only.is_empty() or only.has("static"):
		_static_checks()
	for p in ["normal", "hard", "real"]:
		if (only.is_empty() and p != "real") or only.has(p):
			_queue.append(p)
	_next_part()


# ---------------------------------------------------------------- static

func _static_checks() -> void:
	var want := {
		0: {"start": 240.0, "ratio": 2.0, "tiers": [1], "hollow": false, "pickup": false, "squad": 0, "steal": 0.0,
				"lead": 0.0, "contest": false, "beast": 0.0, "far": false, "stake": 100, "deer": false, "reroute": false,
				"flags": []},
		1: {"start": 120.0, "ratio": 1.5, "tiers": [1, 2, 3], "hollow": false, "pickup": true, "squad": 2, "steal": 1.5,
				"lead": 0.0, "contest": true, "beast": 1.4, "far": false, "stake": 100, "deer": false, "reroute": false,
				"flags": ["B8", "B10", "B11"]},
		2: {"start": 90.0, "ratio": 1.3, "tiers": [1, 2, 3], "hollow": true, "pickup": true, "squad": 3, "steal": 1.2,
				"lead": 15.0, "contest": true, "beast": 1.2, "far": true, "stake": 150, "deer": true, "reroute": true,
				"flags": ["B8", "B9", "B10", "B11"]},
	}
	for d in 3:
		var profiles: Array = [AIProfile.for_difficulty(d), AIProfile.ice(d), AIProfile.nature(d)]
		for k in ["ice", "nature"]:
			var path := "res://data/ai/%s_%s.tres" % [k, AIProfile.DIFFICULTY_NAMES[d]]
			if ResourceLoader.exists(path):
				profiles.append(load(path))
			else:
				_errors.append("missing %s" % path)
		var w: Dictionary = want[d]
		for p: AIProfile in profiles:
			var tag := "%s (%s)" % [p.id, p.resource_path.get_file() if p.resource_path != "" else "code"]
			var bad: Array[String] = []
			if not p.map_fill:
				bad.append("map_fill off")
			if not is_equal_approx(p.creep_start, float(w["start"])) or not is_equal_approx(p.creep_ratio, float(w["ratio"])):
				bad.append("creep %.0f x%.1f" % [p.creep_start, p.creep_ratio])
			if Array(p.creep_tiers) != w["tiers"] or p.creep_hollow != bool(w["hollow"]) or p.creep_pickup != bool(w["pickup"]):
				bad.append("tiers %s hollow %s pickup %s" % [str(p.creep_tiers), str(p.creep_hollow), str(p.creep_pickup)])
			if p.capture_squad != int(w["squad"]) or not is_equal_approx(p.steal_points_ratio, float(w["steal"])):
				bad.append("squad %d steal %.1f" % [p.capture_squad, p.steal_points_ratio])
			if not is_equal_approx(p.shrine_lead, float(w["lead"])) or p.shrine_contest != bool(w["contest"]):
				bad.append("shrine lead %.0f contest %s" % [p.shrine_lead, str(p.shrine_contest)])
			if not is_equal_approx(p.beast_ratio, float(w["beast"])) or p.beast_far != bool(w["far"]) \
					or p.beast_hunt_stake != int(w["stake"]):
				bad.append("beast %.1f far %s stake %d" % [p.beast_ratio, str(p.beast_far), p.beast_hunt_stake])
			if p.hunt_deer != bool(w["deer"]) or p.attack_reroute != bool(w["reroute"]) or Array(p.mapfill_flags) != w["flags"]:
				bad.append("deer %s reroute %s flags %s" % [str(p.hunt_deer), str(p.attack_reroute), str(p.mapfill_flags)])
			if not bad.is_empty():
				_errors.append("%s map-fill knobs: %s" % [tag, ", ".join(bad)])
	if AIProfile.mission_01().map_fill or (load("res://data/ai/mission_01.tres") as AIProfile).map_fill:
		_errors.append("mission_01 must have map_fill off")
	# No services, no tree: inert.
	var m := AIMapFill.new(ENEMY, PLAYER, AIProfile.normal())
	var ue: Array[Unit] = []
	if m.active() or not m.creep_target(600.0, 5000.0, Vector3.ZERO).is_empty() \
			or not m.squad_tick(600.0, Vector3.ZERO, ue, null, true, false).is_empty() \
			or m.wizard_goal(600.0, null, false) != Vector3.INF or m.has_river() \
			or not m.flag_candidates(600.0, null).is_empty() or m.attack_waypoint(AIMemory.new(), 600.0) != Vector3.INF:
		_errors.append("AIMapFill without services is not inert")
	print("part static: map-fill knobs and the inert AIMapFill checked")


# ---------------------------------------------------------------- unit checks (stubs in the tree)

func _unit_checks() -> void:
	var ue: Array[Unit] = []
	var ub: Array[Building] = []
	var mem := AIMemory.new()
	var mk := func(p: AIProfile) -> AIMapFill:
		var m := AIMapFill.new(ENEMY, PLAYER, p)
		m.setup(self, main)
		m.sense(10.0, null, mem, 0.0, 0.0, ue, ub)
		return m
	var normal: AIMapFill = mk.call(AIProfile.normal())
	var easy: AIMapFill = mk.call(AIProfile.easy())
	var hard: AIMapFill = mk.call(AIProfile.hard())
	var rally := Vector3(30.0, 0.0, -30.0)
	if not normal.active() or not normal.has_river():
		_errors.append("units: AIMapFill does not find the stub services")
		return
	var name_of := func(t: Dictionary) -> String: return str(t.get("name", "none"))
	# creep_start / ratio
	if not normal.creep_target(100.0, 5000.0, rally).is_empty():
		_errors.append("units: normal creeps before creep_start (2:00)")
	if not normal.creep_target(150.0, 250.0, rally).is_empty():
		_errors.append("units: normal creeps the wallow with 250 < 1.5 x 200")
	var t1: Dictionary = normal.creep_target(150.0, 300.0, rally)
	if name_of.call(t1) != "Bristleback Wallow N":
		_errors.append("units: normal with 300 from the rally -> %s (want the own wallow)" % name_of.call(t1))
	# the own-near nest (495 = 1.5 x 330), never the player's nest
	var t2: Dictionary = normal.creep_target(200.0, 500.0, Vector3(-8.0, 0.0, -30.0))
	if name_of.call(t2) != "Reed Ford Nest":
		_errors.append("units: normal next to the own-near nest -> %s" % name_of.call(t2))
	# the stag: only from 900 and 1.5 x 700 = 1050
	var stag := Vector3(37.0, 0.0, 10.0)
	if name_of.call(normal.creep_target(300.0, 1000.0, stag)) == "Stag Glade E":
		_errors.append("units: the stag with own_strength 1000 < 1.5 x 700")
	if name_of.call(normal.creep_target(300.0, 1060.0, stag)) != "Stag Glade E":
		_errors.append("units: no stag with 1060 next to it")
	# player-side camps and the hollow never on normal; the own-bank hollow on hard
	for from: Vector3 in [Vector3(-14.0, 0.0, 57.0), Vector3(8.5, 0.0, 34.0), Vector3(-37.0, 0.0, -10.0),
			Vector3(-55.0, 0.0, -55.0), Vector3(55.0, 0.0, 55.0)]:
		var t: Dictionary = normal.creep_target(300.0, 5000.0, from)
		if PLAYER_CAMPS.has(name_of.call(t)) or str(name_of.call(t)).begins_with("Gloomcap"):
			_errors.append("units: normal from %s creeps %s" % [str(from), name_of.call(t)])
	var th: Dictionary = hard.creep_target(300.0, 5000.0, Vector3(55.0, 0.0, 55.0))
	if name_of.call(th) != "Gloomcap Hollow SE":
		_errors.append("units: hard from the own hollow -> %s (want Gloomcap Hollow SE)" % name_of.call(th))
	# easy: tier 1 only, from 4:00, x2.0
	if not easy.creep_target(200.0, 5000.0, rally).is_empty():
		_errors.append("units: easy creeps before 4:00")
	var te: Dictionary = easy.creep_target(300.0, 5000.0, Vector3(-8.0, 0.0, -30.0))
	if int(te.get("tier", 0)) != 1:
		_errors.append("units: easy creeps tier %d (%s)" % [int(te.get("tier", 0)), name_of.call(te)])
	# 13a
	var via := normal.scout_via(rally, Vector3(-27.0, 0.0, 27.0))
	if not (via.is_equal_approx(Vector3(-12.0, 0.0, -48.7)) or via.is_equal_approx(Vector3(12.0, 0.0, 48.7))):
		_errors.append("units: scout_via across the river = %s (want a road bridge)" % str(via))
	if normal.scout_via(rally, Vector3(16.0, 0.0, -6.0)) != Vector3.INF:
		_errors.append("units: scout_via on the same bank is not INF")
	if normal.scout_point_ok(Vector3(0.0, 0.0, 5.0), true) or not normal.scout_point_ok(Vector3(0.0, 0.0, 5.0), false):
		_errors.append("units: scout_point_ok on the isle (wardens alive / dead) wrong")
	if normal.scout_point_ok(Vector3(14.0, 0.0, -52.0), false):
		_errors.append("units: scout_point_ok next to a living camp")
	# 13b (hard only)
	var hold := AIMemory.new()
	if hard.attack_waypoint(hold, 10.0) != Vector3.INF:
		_errors.append("units: attack_waypoint with nothing seen is not INF")
	for i in 5:
		hold.units[900000 + i] = {"soldier": true, "time": 10.0, "pos": Vector3(-11.0, 0.0, 11.0), "strength": 0.0}
	if normal.attack_waypoint(hold, 10.0) != Vector3.INF:
		_errors.append("units: normal reroutes (13b is hard only)")
	hold.buildings[900100] = {"kind": &"tower", "pos": Vector3(-9.0, 0.0, -38.0), "strength": 150.0}
	var wp := hard.attack_waypoint(hold, 10.0)
	if not wp.is_equal_approx(Vector3(12.0, 0.0, 48.7)):
		_errors.append("units: hard reroute with a tower on the north side -> %s (want Millstone Bridge)" % str(wp))
	hold.buildings.erase(900100)
	hold.buildings[900101] = {"kind": &"tower", "pos": Vector3(10.0, 0.0, 40.0), "strength": 150.0}
	wp = hard.attack_waypoint(hold, 10.0)
	if not wp.is_equal_approx(Vector3(-12.0, 0.0, -48.7)):
		_errors.append("units: hard reroute with a tower on the south side -> %s (want Saltgate Bridge)" % str(wp))
	if hard.attack_waypoint(hold, 80.0) != Vector3.INF:
		_errors.append("units: 5 holders seen 70 s ago still reroute")
	# B8: the own-bank towers are neutral at the start
	var rules: Array[String] = []
	for c: Dictionary in normal.flag_candidates(10.0, mem):
		rules.append(str(c["rule"]))
	if not rules.has("B8") or rules.has("B10") or rules.has("B11"):
		_errors.append("units: flag candidates at the start %s (want B8 only)" % str(rules))
	print("part units: creep targets, scout via, attack reroute and flag candidates checked")


# ---------------------------------------------------------------- scene handling

func _next_part() -> void:
	if _queue.is_empty():
		_finish()
		return
	part = _queue.pop_front()
	_wait = 0
	_frame = 0
	_cal_samples.clear()
	_s = {"shrine_at": -1.0, "scout_near_crown": false, "deer_hit": false, "raid_at": -1.0, "raiders": [],
			"b10": false, "b11": false, "beast_at": -1.0, "cleared": {}, "squad_max": 0}
	main = load(SCENE).instantiate()
	if part != "real":
		for f: StringName in [&"river_enabled", &"points_enabled", &"camps_enabled", &"beasts_enabled"]:
			if f in main:
				main.set(f, false)   # the real step-12 systems off: only the stubs
	var d := {"normal": 1, "hard": 2, "real": 1}[part] as int
	bot = _bot_for(ENEMY, d)
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
	p.attack_ratio = 50.0   # rule 7 never "ready": the army creeps (11a replaces weak attacks)
	b.profile = p
	b.profile_id = &""
	b.debug_log = false
	return b


func _add_stubs() -> void:
	var river := StubRiver.new()
	river.name = "StubRiver"
	main.add_child(river)
	_points_svc = StubPoints.new()
	_points_svc.name = "StubPoints"
	main.add_child(_points_svc)
	for row: Array in POINTS:
		var p := StubPoint.new()
		p.point_id = row[0]
		p.display_name = row[1]
		p.kind = row[2]
		p.capture_radius = row[4]
		p.capture_time = row[5]
		p.level = main
		p.name = "Point_%s" % row[0]
		main.add_child(p)
		p.global_position = row[3]
		p.bank = river.bank_of(row[3])
		if p.kind == &"shrine":
			p.state = &"asleep"
			p.wake_at = 180.0
		_points_svc.list.append(p)
	_camps_svc = StubCamps.new()
	_camps_svc.name = "StubCamps"
	main.add_child(_camps_svc)
	for row: Array in CAMPS:
		var c := StubCamp.new()
		c.camp_id = row[0]
		c.display_name = row[1]
		c.kind = row[2]
		c.tier = row[3]
		c.each = row[6]
		c.name = "Camp_%s" % row[0]
		main.add_child(c)
		c.global_position = row[4]
		for i in int(row[5]):
			var a := TAU * float(i) / float(row[5])
			c.units.append(_spawn_creature(row[4] + Vector3(cos(a), 0.0, sin(a)) * (1.5 if int(row[5]) > 1 else 0.0), 60.0))
		_camps_svc.list.append(c)
	_beasts_svc = StubBeasts.new()
	_beasts_svc.name = "StubBeasts"
	main.add_child(_beasts_svc)
	_deer = StubDeer.new()
	_deer.name = "StubDeer"
	main.add_child(_deer)
	_deer.global_position = DEER_POS


func _spawn_creature(pos: Vector3, hp: float) -> Unit:
	var u: Unit = main.make_unit("ruin_warden")
	u.team = Unit.Team.NEUTRAL
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	u.hp = hp
	return u


func _end_part() -> void:
	var mf: Variant = bot.get(&"mapfill_ai") if bot else null
	if mf != null:
		var ms: float = mf.median_ms()
		print("%s: map-fill median %.4f ms over %d ticks (totals usec %s); bot tick avg %.3f ms (max %.3f ms)" % [part,
				ms, mf.tick_count, str(mf.usec_parts), bot.tick_usec_average() / 1000.0, bot.tick_usec_max / 1000.0])
		var cal_ms := _cal_median_usec() / 1000.0
		var ratio := ms / cal_ms if cal_ms > 0.0 else INF
		print("%s: calibration loop median %.3f ms over %d samples (best of %d); map-fill median = %.3f loops (budget %.2f; the old %.2f ms line %s)" % [
				part, cal_ms, _cal_samples.size(), CAL_REPEAT, ratio, PERF_LIMIT_CAL, PERF_LIMIT_MS,
				"over" if ms > PERF_LIMIT_MS else "under"])
		if cal_ms <= 0.0:
			_errors.append("%s: no calibration sample (the match never started?)" % part)
		elif ratio > PERF_LIMIT_CAL:
			_errors.append("%s: map-fill median %.3f calibration loops per tick > %.2f (%.3f ms, loop %.3f ms)" % [part,
					ratio, PERF_LIMIT_CAL, ms, cal_ms])
		else:
			print("PERF OK (%s)" % part)
		_part_checks(mf)
	if bot:
		print("%s bot log (map fill):" % part)
		for l: String in bot.log_lines:
			if l.contains("CREEP") or l.contains("SQUAD") or l.contains("POINT") or l.contains("SHRINE") \
					or l.contains("WIZARD job") or l.contains("WIZARD goes") or l.contains("WIZARD picks") \
					or l.contains("SCOUT") or l.contains("DEFEND") or l.contains("ATTACK") or l.contains("BOUNTY B") \
					or l.contains("RETREAT"):
				print("  " + l)
	main.queue_free()
	main = null
	bot = null
	_gap = 3


func _process(_delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_next_part()
		return false
	if main == null:
		return true
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_frame += 1
	_t = main.match_time()
	if _frame % CAL_EVERY == 0:
		var best := 1 << 30
		for r in CAL_REPEAT:
			best = mini(best, _calib_once())
		_cal_samples.append(best)
	if _frame == 1:
		if part != "real":
			_add_stubs()
		return false
	if not bot.get(&"_ready_done"):
		return false
	if _frame == 3 and part == "normal":
		_unit_checks()
	if part != "real":
		_sample()
	if main.game_over:
		_errors.append("%s: the match ended at %s (winner %d)" % [part, _clock(_t), int(main.winner_team)])
		_end_part()
		return false
	if main != null and _t > float(PART_LIMIT[part]):
		_end_part()
	return false


## The calibration workload (usec), test_20_a3's: a fixed loop of Vector3 math, typed-array reads and Dictionary
## lookups, the kind of work a bot decision is made of.
func _calib_once() -> int:
	var t0 := Time.get_ticks_usec()
	var acc := 0.0
	var n := _cal_pts.size()
	for r in 8:
		for i in n:
			var p := _cal_pts[i]
			var d := p.distance_squared_to(_cal_pts[(i * 7 + r) % n])
			if d < 400.0:
				acc += sqrt(d)
			acc += float(_cal_dict.get(i & 63, 0.0))
	_cal_sink += acc
	return Time.get_ticks_usec() - t0


func _cal_median_usec() -> float:
	if _cal_samples.is_empty():
		return 0.0
	var s := _cal_samples.duplicate()
	s.sort()
	return float(s[s.size() / 2])


## Every few frames: the scout near the crown, the deer, the shrine presence, camps cleared, the raid, flags.
func _sample() -> void:
	if _frame % 6 != 0:
		return
	var mf: AIMapFill = bot.mapfill_ai
	var units := _bot_units()
	# the scout never within 11 m of the crown while the wardens live (13a)
	var sc: Variant = bot.get(&"_scout")
	if sc != null and is_instance_valid(sc) and not (main.wardens as Array).is_empty():
		var p: Vector3 = (sc as Node3D).global_position
		if Vector2(p.x, p.z).length() < 11.0 and not _s["scout_near_crown"]:
			_s["scout_near_crown"] = true
			_errors.append("%s: the scout walked onto the isle at %s while the wardens live" % [part, _clock(_t)])
	# the deer (11d): never on normal; hard only a squad member
	for u: Unit in units:
		if u.attack_target == _deer and _deer != null:
			if part == "normal" or not mf.is_busy(u):
				if not _s["deer_hit"]:
					_errors.append("%s: %s targets the deer at %s" % [part, u.unit_name, _clock(_t)])
				_s["deer_hit"] = true
	if part == "normal" and _deer != null and _deer.hp < _deer.max_hp and not _s["deer_hit"]:
		_s["deer_hit"] = true
		_errors.append("normal: the deer was hurt at %s" % _clock(_t))
	# own shrine presence (from 2:30: earlier passers-by do not count)
	if float(_s["shrine_at"]) < 0.0 and _t >= 150.0:
		for u: Unit in units:
			if Vector2(u.global_position.x - SHRINE_E.x, u.global_position.z - SHRINE_E.z).length() <= 7.0:
				_s["shrine_at"] = _t
				break
	# camps cleared
	for c: StubCamp in _camps_svc.list:
		if c.cleared_at < 0.0 and c.is_cleared():
			c.cleared_at = _t
			_s["cleared"][c.display_name] = _t
	_s["squad_max"] = maxi(int(_s["squad_max"]), mf.squad.size())
	# the raid on the bot's well (12b) at 5:00 once it owns it
	var well := _point("well_e")
	if part == "normal" and float(_s["raid_at"]) < 0.0 and _t >= RAID_TIME and well.owner_team == ENEMY:
		_s["raid_at"] = _t
		for i in 2:
			var u: Unit = main.make_unit("flame_guard")
			if u == null:
				continue
			u.team = Unit.Team.PLAYER
			main.add_child(u)
			u.global_position = WELL_E + Vector3(1.5 * i, 0.0, 1.5)
			u.command_stop()
			(_s["raiders"] as Array).append(u)
		print("normal: 2 player soldiers take the bot's well at %s" % _clock(_t))
	# the beast (11e) at 6:00
	if part == "normal" and float(_s["beast_at"]) < 0.0 and _t >= BEAST_TIME:
		_s["beast_at"] = _t
		var b := _spawn_creature(BEAST_POS, 150.0)
		b.add_to_group("beasts")
		_beasts_svc.list.append(b)
		_beasts_svc.lairs[b.get_instance_id()] = {"id": &"lair_heath_e", "kind": &"tusker", "center": BEAST_POS,
				"radius": 4.0}
	# flag candidates
	for c: Dictionary in mf.flag_candidates(_t, bot.memory):
		if c["rule"] == "B10":
			_s["b10"] = true
		elif c["rule"] == "B11":
			_s["b11"] = true


func _bot_units() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ENEMY and not u.is_worker():
			out.append(u)
	return out


func _point(id: String) -> StubPoint:
	for p: StubPoint in _points_svc.list:
		if String(p.point_id) == id:
			return p
	return null


func _creep_time(mf: AIMapFill, name_part: String) -> float:
	for c: Dictionary in mf.creeps:
		if str(c["name"]).contains(name_part):
			return float(c["time"])
	return -1.0


func _part_checks(mf: AIMapFill) -> void:
	if part == "real":
		# Integration smoke with the real step-12 systems (notes only: they are still being built in parallel).
		var names: Array[String] = []
		for c: Dictionary in mf.creeps:
			names.append("%s@%s" % [c["name"], _clock(float(c["time"]))])
		var jobs: Array[String] = []
		for j: Dictionary in mf.jobs:
			jobs.append("%s %s@%s" % [j["by"], j["name"], _clock(float(j["time"]))])
		print("real: map fill active %s, river %s; creeps %s; jobs %s; captured %s" % [str(mf.active()),
				str(mf.has_river()), str(names), str(jobs), str(mf.captured)])
		if not mf.active():
			_notes.append("real: no step-12 system found in the skirmish")
		elif mf.creeps.is_empty() or mf.jobs.is_empty():
			_notes.append("real: %d creeps, %d squad / wizard jobs by 7:00" % [mf.creeps.size(), mf.jobs.size()])
		return
	var cleared: Dictionary = _s["cleared"]
	var squad_jobs: Array[String] = []
	for j: Dictionary in mf.jobs:
		if j["by"] == "squad" and j["kind"] == &"point":
			squad_jobs.append(str(j["name"]))
	var creep_names: Array[String] = []
	for c: Dictionary in mf.creeps:
		creep_names.append("%s@%s" % [c["name"], _clock(float(c["time"]))])
	print("%s: creeps %s; cleared %s; squad point jobs %s; shrine presence %s; squad max %d; deer shots %d" % [part,
			str(creep_names), str(cleared), str(squad_jobs), _clock(float(_s["shrine_at"])), int(_s["squad_max"]),
			mf.deer_shots])
	for c: Dictionary in mf.creeps:
		if PLAYER_CAMPS.has(str(c["name"])):
			_errors.append("%s: crept a player-side camp %s" % [part, c["name"]])
	var shrine := _point("shrine_e")
	match part:
		"normal":
			var w := _creep_time(mf, "Wallow N")
			if w < 120.0 or w > 195.0:
				_errors.append("normal: wallow creep at %s (want 2:00-3:15)" % _clock(w))
			if float(cleared.get("Bristleback Wallow N", INF)) > 225.0:
				_errors.append("normal: the wallow not cleared by 3:45")
			if float(cleared.get("Reed Ford Nest", INF)) > 390.0:
				_errors.append("normal: the own ford nest not cleared by 6:30 (creep %s)" % _clock(_creep_time(mf, "Nest")))
			if _creep_time(mf, "Hollow") >= 0.0:
				_errors.append("normal: crept the hollow")
			if squad_jobs.size() < 2 or squad_jobs[0] != "Stonemere Well" or squad_jobs[1] != "Saltwatch":
				_errors.append("normal: squad point order %s (want the well, then Saltwatch)" % str(squad_jobs))
			if int(_s["squad_max"]) != 2:
				_errors.append("normal: squads of %d (want 2)" % int(_s["squad_max"]))
			if _point("well_e").captures.is_empty():
				_errors.append("normal: the well was never captured")
			var at := float(_s["shrine_at"])
			if at < 0.0 or at > 186.0:
				_errors.append("normal: first bot unit at the own shrine at %s (want by 3:06)" % _clock(at))
			if shrine.captures.is_empty() or int(shrine.captures[0][0]) != ENEMY or float(shrine.captures[0][1]) > 220.0:
				_errors.append("normal: the own shrine not captured by 3:40 (%s)" % str(shrine.captures))
			# 13a: the river loop's unexplored points in order ((16, -6) may already be explored from the base).
			var sg: Array = bot.scout_goals
			var idx: Array[int] = []
			for want: Vector3 in [Vector3(12.0, 0.0, 22.0), Vector3(17.0, 0.0, 47.0), Vector3(-2.0, 0.0, 44.0)]:
				var found := -1
				for i in sg.size():
					if (sg[i] as Vector3).is_equal_approx(want):
						found = i
						break
				idx.append(found)
			if idx.has(-1) or idx[0] > idx[1] or idx[1] > idx[2]:
				_errors.append("normal: the scout did not take the river loop (goals %s)" % str(sg.slice(0, 6)))
			if float(_s["raid_at"]) < 0.0:
				_errors.append("normal: the bot never owned its well at 5:00 (no raid test)")
			else:
				var reacted := false
				for l: String in bot.log_lines:
					if (l.contains("POINT defence") or l.contains("DEFEND")) and _log_time(l) >= float(_s["raid_at"]):
						reacted = true
				var alive := 0
				for r: Variant in _s["raiders"]:
					if is_instance_valid(r) and (r as Unit).is_alive():
						alive += 1
				if not reacted:
					_errors.append("normal: no DEFEND / POINT defence after the raid on the well")
				if alive > 0 and _point("well_e").owner_team != ENEMY:
					_errors.append("normal: the raiders (%d alive) kept the well" % alive)
				if not _s["b10"]:
					_notes.append("normal: no B10 candidate seen (the raiders were not seen near the well)")
			if _creep_beast(mf) < 0.0:
				_errors.append("normal: the beast was never crept (11e)")
			elif not _s["b11"]:
				_errors.append("normal: no B11 candidate while the army went for the beast")
			if int(bot.attacks_launched) > 0:
				_notes.append("normal: %d rule-7 attacks (pop capped)" % int(bot.attacks_launched))
		"hard":
			if int(_s["squad_max"]) != 3:
				_errors.append("hard: squads of %d (want 3)" % int(_s["squad_max"]))
			var at := float(_s["shrine_at"])
			if at < 0.0 or at > 170.0:
				_errors.append("hard: first bot unit at the own shrine at %s (want >= 10 s before 3:00)" % _clock(at))
			if _creep_time(mf, "Hollow SE") < 0.0:
				_errors.append("hard: the own-bank hollow was never crept")
			_notes.append("hard: deer shots %d" % mf.deer_shots)


func _creep_beast(mf: AIMapFill) -> float:
	for c: Dictionary in mf.creeps:
		if c["kind"] == &"beast":
			return float(c["time"])
	return -1.0


static func _log_time(line: String) -> float:
	var a := line.find("[")
	var b := line.find("]")
	if a < 0 or b < 0:
		return -1.0
	var parts := line.substr(a + 1, b - a - 1).split(":")
	return float(parts[0].to_int() * 60 + parts[1].to_int())


func _finish() -> void:
	print("finished after %d frames" % Engine.get_process_frames())
	for n in _notes:
		print("NOTE " + n)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in _errors:
			print("ERROR " + e)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _errors.size()])
	quit()


static func _clock(t: float) -> String:
	if t < 0.0 or t == INF:
		return "never"
	return "%d:%02d" % [int(t) / 60, int(t) % 60]
