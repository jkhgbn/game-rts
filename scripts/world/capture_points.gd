class_name CapturePoints
extends Node
## The capturable points service (docs/design/map-fill.md 4, contract section 13). One per match, group
## "capture_points_service", found with `CapturePoints.instance(tree)`. It owns the CapturePoint nodes it was given
## (`setup`) or made (`add_point`) and runs their rules:
## - Presence: one loop over "units" every PRESENCE_INTERVAL (= TICK, review W3-7), cached per point and team. Counted: soldiers,
##   wizards (x2), champions of PLAYER / ENEMY; not workers, caravans, trackers, non-combatants, neutrals (Magpies,
##   creatures), buildings. `presence(team, point)` reads the cache.
## - Progress: `CapturePoint.update_capture` 4 times per second with the cached presence (TICK).
## - Wells: from WELL_START (2:30) every WELL_PERIOD (5 s) each owned well pays WELL_INCOME x 5 = 2 essence to its
##   owner's bank (group "essence_banks", `add(n)`), and the owner's wizard within WELL_MANA_RADIUS (8 m) gains
##   WELL_MANA (+3 mana / s) from 2:30 too.
## - Shrines: all wake at SHRINE_FIRST (3:00); then every SHRINE_INTERVAL (180 s) one shrine wakes, alternating banks;
##   the first alternate (6:00) is on the bank of the team that captured a 3:00 shrine later (or never); a tie =
##   seeded coin flip (`coin_seed`). A shrine already awake is not woken again (the slot passes).
## - Blessing: capturing an awake shrine gives the capturing team modifier `blessing:wayshrine` (BLESSING_STATS) for
##   BLESSING_TIME on soldiers, wizards and champions (not workers, caravans, trackers); another capture meanwhile
##   resets the timer (no stack). While a blessing runs, `SceneTree.node_added` is watched and new units of that team
##   get it too (deferred), so unit.gd does not change.
## - Messages (local_team's view) through signal `message(text, seconds)` (the skirmish shows them like the guilds'
##   messages; when nothing is connected, the current scene's `hud.show_message` is used).
## Match time: `match_time_source` (skirmish.match_time), else the parent's match_time(), else this node's age.

signal point_captured(point: Node3D, team: int)
signal point_neutralised(point: Node3D, old_team: int)
signal shrine_awakened(point: Node3D)
signal blessing_started(team: int, seconds: float)
signal blessing_ended(team: int)
## A line for the local player's HUD.
signal message(text: String, seconds: float)

const BLESSING_TIME := 60.0
const BLESSING_STATS := {"move_speed_pct": 0.12, "hp_regen": 1.5}
const BLESSING_MODIFIER := &"blessing:wayshrine"
const WELL_INCOME := 0.4             ## Essence per second per owned well.
const WELL_START := 150.0            ## 2:30.
const WELL_PERIOD := 5.0             ## Paid in steps: +2 every 5 s.
const WELL_MANA := 3.0               ## Mana per second to the owner's wizard near the well.
const WELL_MANA_RADIUS := 8.0
const SHRINE_FIRST := 180.0
const SHRINE_INTERVAL := 180.0
const PRESENCE_INTERVAL := 0.25   ## = TICK: a capture stops on the tick the units leave (review W3-7).
const TICK := 0.25
const WIZARD_PRESENCE := 2
const FOG_REVEAL_RADIUS := 5.0
const MSG_SECONDS := 4.0
const CAPTURING_MSG_COOLDOWN := 60.0
const TAKING_MSG_COOLDOWN := 20.0
const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const POINT_SCRIPT := "res://scripts/world/capture_point.gd"
const ESSENCE_BANK_PATH := "res://scripts/items/essence_bank.gd"

const MSG_CAPTURED_OWN := "Your forces captured %s"
const MSG_CAPTURED_ENEMY := "The enemy captured %s"
const MSG_NEUTRALISED := "%s was neutralised"
const MSG_CAPTURING := "Your forces are capturing %s"
const MSG_TAKING := "The enemy is taking %s!"
const MSG_WELLS := "The essence wells are brimming"
const MSG_SHRINES := "The Wayshrines awaken"
const MSG_SHRINE := "The %s awakens"
const MSG_BLESSING_OWN := "Blessing of the Wayshrine: +12 % speed, +1.5 HP / s for 60 s"
const MSG_BLESSING_ENEMY := "The enemy received the Wayshrine's blessing"

## The team whose point of view the messages use.
@export var local_team: int = PLAYER_TEAM
## Seed of the shrine coin flip (tie at 6:00). Set before setup.
@export var coin_seed: int = 12
## Where add_point puts new points (the NavigationRegion3D, so towers and wells block the bake). null = the parent's
## `nav_region` when it has one, else the parent.
var point_parent: Node
var match_time_source: Callable

var _points: Array = []
var _presence := {}              # point instance id -> [player, enemy]
var _age := 0.0
var _acc := 0.0
var _presence_left := 0.0
var _started := false
var _wells_announced := false
var _well_paid := 0              # well income steps paid so far
var _shrine_wave := 0            # wakings done (0 = before 3:00, 1 = after the 3:00 waking, ...)
var _first_wave: Dictionary = {} # shrine instance id -> true for the shrines woken at 3:00
var _first_capture := {PLAYER_TEAM: INF, ENEMY_TEAM: INF}   # first capture time of a 3:00 shrine per team
var _alt_bank := -1              # bank of the 6:00 shrine once decided
var _coin := 0
var _blessing_left := {PLAYER_TEAM: 0.0, ENEMY_TEAM: 0.0}
var _blessed := {PLAYER_TEAM: [], ENEMY_TEAM: []}   # units carrying the modifier
var _watching := false
var _msg_capturing := {}         # point instance id -> match time of the last "capturing" line
var _loading := false            # load_world_state is putting owners back: no messages / signals
var _msg_taking := {}            # point instance id -> match time of the last "taking" line


func _ready() -> void:
	add_to_group("capture_points_service")
	var rng := RandomNumberGenerator.new()
	rng.seed = coin_seed
	_coin = rng.randi() % 2


func _exit_tree() -> void:
	_set_watching(false)


## The match's service (group "capture_points_service"), or null.
static func instance(tree: SceneTree) -> CapturePoints:
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"capture_points_service") as CapturePoints


## `points`: CapturePoint nodes (already placed) and / or spot Dictionaries `{id, name, kind, pos}` (`pos` may also be
## `position` / `center`; optional `bank` overrides the river). Replaces the current list.
func setup(points: Array) -> void:
	for p in _points:
		_disconnect_point(p)
	_points.clear()
	_presence.clear()
	for entry: Variant in points:
		if entry is Dictionary:
			var d: Dictionary = entry
			var pos: Variant = d.get("pos", d.get(&"pos", d.get("position", d.get("center", Vector3.ZERO))))
			var node := add_point(StringName(str(d.get("kind", d.get(&"kind", &"watchtower")))),
					StringName(str(d.get("id", d.get(&"id", "")))), str(d.get("name", d.get(&"name", ""))), pos)
			if node and d.has("bank"):
				node.set(&"bank", int(d["bank"]))
		elif entry is Node3D and is_instance_valid(entry):
			_register(entry)
	_refresh_banks(points)
	_reveal_all()
	_refresh_schedule()


## Makes one point (kind &"watchtower" / &"well" / &"shrine") at `pos` under `point_parent` and registers it.
func add_point(kind: StringName, id: StringName, point_name: String, pos: Vector3) -> Node3D:
	if not ResourceLoader.exists(POINT_SCRIPT):
		return null
	var script := load(POINT_SCRIPT) as GDScript
	if script == null or not script.can_instantiate():
		return null
	var point := script.new() as Node3D
	point.set(&"kind", kind)
	point.set(&"point_id", id)
	point.set(&"display_name", point_name if point_name != "" else String(id).capitalize())
	point.name = "CapturePoint_%s" % String(id).to_pascal_case()
	var parent := _point_parent()
	if parent == null:
		return null
	parent.add_child(point)
	point.global_position = Vector3(pos.x, 0.0, pos.z)
	_register(point)
	point.set(&"bank", _bank_of(point.global_position))
	_reveal(point)
	_refresh_schedule()
	return point


## Every point, or only those of `kind`.
func points(kind: StringName = &"") -> Array:
	var out: Array = []
	for p in _points:
		if is_instance_valid(p) and (kind == &"" or StringName(p.get(&"kind")) == kind):
			out.append(p)
	return out


## The point with this id, or null.
func point_by_id(id: StringName) -> Node3D:
	for p in points():
		if StringName(p.get(&"point_id")) == id:
			return p
	return null


## The points `team` owns (optionally only one kind).
func held_by(team: int, kind: StringName = &"") -> Array:
	return points(kind).filter(func(p: Node3D) -> bool: return int(p.get(&"owner_team")) == team)


## Cached presence of `team` at `point` (a wizard counts 2), refreshed every PRESENCE_INTERVAL.
func presence(team: int, point: Node3D) -> int:
	team = side_layer(team)   # 2v2: presence is per side (map-2v2.md 4.5)
	if point == null or not is_instance_valid(point):
		return 0
	var counts: Variant = _presence.get(point.get_instance_id())
	if counts == null or (team != PLAYER_TEAM and team != ENEMY_TEAM):
		return 0
	return int((counts as Array)[team])


## Seconds of blessing `team` has left (0 = none).
func blessing_time_left(team: int) -> float:
	return float(_blessing_left.get(side_layer(team), 0.0))


## The next shrine waking: `{point, time, points}` (`time` in match time; `point` null when several wake together or
## none can; `points` = the shrines that will wake). Empty when there are no shrines.
func next_waking() -> Dictionary:
	var shrines := points(&"shrine")
	if shrines.is_empty():
		return {}
	if _shrine_wave == 0:
		var asleep := shrines.filter(func(s: Node3D) -> bool: return not bool(s.call(&"is_awake")))
		return {"point": asleep[0] if asleep.size() == 1 else null, "time": SHRINE_FIRST, "points": asleep}
	var s := _shrine_for_wave(_shrine_wave)
	return {"point": s, "time": _wave_time(_shrine_wave), "points": [s] if s else []}


## Seconds of match time (match_time_source, else the parent's match_time(), else this node's age).
func match_time() -> float:
	if match_time_source.is_valid():
		return float(match_time_source.call())
	var level := get_parent()
	if level and level.has_method(&"match_time"):
		return float(level.call(&"match_time"))
	return _age


## Gives `unit` the blessing when its team is blessed and it is a soldier, wizard or champion (no-op otherwise).
func apply_blessing(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or not unit.is_inside_tree():
		return
	var t: Variant = unit.get(&"team")
	if t == null or blessing_time_left(int(t)) <= 0.0 or not counts_for_capture(unit):
		return
	if not unit.has_method(&"add_modifier"):
		return
	unit.call(&"add_modifier", BLESSING_MODIFIER, BLESSING_STATS)
	var list: Array = _blessed[side_layer(int(t))]
	if not list.has(unit):
		list.append(unit)


## Presence weight of a unit: 0 (does not count), 1 (soldier, champion) or 2 (wizard).
static func presence_weight(u: Node) -> int:
	if not counts_for_capture(u):
		return 0
	if u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes") or u.has_method(&"command_cast"):
		return WIZARD_PRESENCE
	return 1


## True for living soldiers, wizards and champions of PLAYER / ENEMY (not workers, caravans, trackers, Magpies,
## creatures, non-combatants, buildings).
static func counts_for_capture(u: Node) -> bool:
	if u == null or not is_instance_valid(u) or not u.is_in_group(&"units"):
		return false
	var t: Variant = u.get(&"team")
	if t == null:
		return false
	var side_t := side_layer(int(t))   # 2v2: an allied seat counts for its side
	if side_t != PLAYER_TEAM and side_t != ENEMY_TEAM:
		return false
	if u.has_method(&"is_alive") and not bool(u.call(&"is_alive")):
		return false
	if u.has_method(&"is_worker") and bool(u.call(&"is_worker")):
		return false
	if u.is_in_group(&"caravans") or u.is_in_group(&"trackers") or u.is_in_group(&"magpies") \
			or u.is_in_group(&"creatures") or u.is_in_group(&"game_critters"):
		return false
	var type: Variant = u.get(&"unit_type")
	if type is Resource and bool((type as Resource).get(&"is_caravan")):
		return false
	if u.has_method(&"is_non_combatant") and bool(u.call(&"is_non_combatant")):
		return false
	return true


## The side layer of a team (2v2: an allied seat counts for its side; 1v1: the team itself): PLAYER_TEAM for side
## 0, ENEMY_TEAM for side 1, the team itself otherwise (NEUTRAL). Through Teams.side_of (review W3-6).
static func side_layer(team: int) -> int:
	if (team == PLAYER_TEAM or team == ENEMY_TEAM) and not Teams.multi:
		return team
	var side := Teams.side_of(team)
	if side == 0:
		return PLAYER_TEAM
	if side == 1:
		return ENEMY_TEAM
	return team


# ---------------------------------------------------------------- save / load (Skirmish level hooks, review W3-5)

## Every point's owner / progress / waking, the shrine schedule, wells and blessings.
func save_world_state() -> Dictionary:
	var pts := {}
	for p in points():
		pts[String(p.get(&"point_id"))] = {"owner": int(p.get(&"owner_team")), "capture_team": int(p.get(&"capture_team")),
				"progress": float(p.get(&"progress")), "awake": bool(p.call(&"is_awake"))}
	var first: Array = []
	for p in points(&"shrine"):
		if _first_wave.has(p.get_instance_id()):
			first.append(String(p.get(&"point_id")))
	return {"points": pts, "shrine_wave": _shrine_wave, "first_wave": first, "first_capture": _first_capture.duplicate(),
			"alt_bank": _alt_bank, "coin": _coin, "well_paid": _well_paid, "wells_announced": _wells_announced,
			"blessing_left": _blessing_left.duplicate()}


## Puts the saved points and schedule back after the match clock is restored: no burst of shrine wakings, no
## repeated well payments or announcements. A running blessing goes on (units get the modifier on the next scan).
func load_world_state(d: Dictionary) -> void:
	var pts: Dictionary = d.get("points", {})
	_shrine_wave = int(d.get("shrine_wave", _shrine_wave))
	_alt_bank = int(d.get("alt_bank", _alt_bank))
	_coin = int(d.get("coin", _coin))
	_well_paid = int(d.get("well_paid", _well_paid))
	_wells_announced = bool(d.get("wells_announced", _wells_announced))
	var fc: Dictionary = d.get("first_capture", {})
	for t: Variant in fc:
		_first_capture[int(t)] = float(fc[t])
	_first_wave.clear()
	_loading = true
	var first: Array = d.get("first_wave", [])
	for p in points():
		var id := String(p.get(&"point_id"))
		if first.has(id):
			_first_wave[p.get_instance_id()] = true
		if not pts.has(id):
			continue
		var row: Dictionary = pts[id]
		if bool(row.get("awake", true)) and not bool(p.call(&"is_awake")):
			p.call(&"wake")
		elif not bool(row.get("awake", true)) and bool(p.call(&"is_awake")) and p.has_method(&"sleep"):
			p.call(&"sleep")
		if int(row.get("owner", -1)) != int(p.get(&"owner_team")):
			p.call(&"set_owner_team", int(row.get("owner", -1)))
		p.set(&"capture_team", int(row.get("capture_team", -1)))
		p.set(&"progress", float(row.get("progress", 0.0)))
	_loading = false
	var bl: Dictionary = d.get("blessing_left", {})
	for t: Variant in bl:
		if _blessing_left.has(int(t)):
			_blessing_left[int(t)] = float(bl[t])
	if float(_blessing_left[PLAYER_TEAM]) > 0.0 or float(_blessing_left[ENEMY_TEAM]) > 0.0:
		_set_watching(true)
	_refresh_schedule()
	_scan_presence()


## Rebuilds the presence cache now (tests may call it).
func refresh() -> void:
	_scan_presence()


# ---------------------------------------------------------------- loop

func _physics_process(delta: float) -> void:
	_age += delta
	_acc += delta
	if _acc < TICK:
		return
	var dt := _acc
	_acc = 0.0
	if not _started:
		_started = true
		_refresh_banks([])
		_reveal_all()
	_presence_left -= dt
	if _presence_left <= 0.0:
		_presence_left += PRESENCE_INTERVAL
		if _presence_left <= 0.0:
			_presence_left = PRESENCE_INTERVAL
		_scan_presence()
	var now := match_time()
	for p in points():
		var counts: Array = _presence.get(p.get_instance_id(), [0, 0])
		var before_team := int(p.get(&"capture_team"))
		var before := float(p.get(&"progress"))
		p.call(&"update_capture", dt, int(counts[0]), int(counts[1]))
		_progress_messages(p, before_team, before, now)
	_update_wells(dt, now)
	_update_shrines(now)
	_update_blessings(dt)


## One pass over "units": presence per point and team (weighted).
func _scan_presence() -> void:
	var pts := points()
	var pos: Array[Vector2] = []
	var r2: Array[float] = []
	for p in pts:
		_presence[p.get_instance_id()] = [0, 0]
		pos.append(Vector2(p.global_position.x, p.global_position.z))
		var r := float(p.get(&"capture_radius"))
		r2.append(r * r)
	if not is_inside_tree():
		return
	var blessed := [float(_blessing_left[PLAYER_TEAM]) > 0.0, float(_blessing_left[ENEMY_TEAM]) > 0.0]
	if pts.is_empty() and not blessed[0] and not blessed[1]:
		return
	for node in get_tree().get_nodes_in_group(&"units"):
		var w := presence_weight(node)
		if w == 0:
			continue
		var u := node as Node3D
		var q := Vector2(u.global_position.x, u.global_position.z)
		var t := side_layer(int(u.get(&"team")))
		# A blessed team's unit without the modifier (a wizard revived at the keep during the blessing).
		if blessed[t] and u.has_method(&"has_modifier") and not bool(u.call(&"has_modifier", BLESSING_MODIFIER)):
			apply_blessing(u)
		for i in pts.size():
			if q.distance_squared_to(pos[i]) <= r2[i]:
				(_presence[pts[i].get_instance_id()] as Array)[t] += w


# ---------------------------------------------------------------- points

func _register(point: Node3D) -> void:
	if _points.has(point):
		return
	_points.append(point)
	_presence[point.get_instance_id()] = [0, 0]
	if point.has_signal(&"owner_changed") and not point.is_connected(&"owner_changed", _on_owner_changed):
		point.connect(&"owner_changed", _on_owner_changed)
	if point.has_signal(&"blessing_granted") and not point.is_connected(&"blessing_granted", _on_blessing_granted):
		point.connect(&"blessing_granted", _on_blessing_granted)


func _disconnect_point(point: Variant) -> void:
	if not is_instance_valid(point):
		return
	var p := point as Node
	if p.is_connected(&"owner_changed", _on_owner_changed):
		p.disconnect(&"owner_changed", _on_owner_changed)
	if p.is_connected(&"blessing_granted", _on_blessing_granted):
		p.disconnect(&"blessing_granted", _on_blessing_granted)


func _point_parent() -> Node:
	if point_parent and is_instance_valid(point_parent):
		return point_parent
	var level := get_parent()
	if level:
		var nav: Variant = level.get(&"nav_region")
		if nav is Node and is_instance_valid(nav):
			return nav
		return level
	return null


## Banks from the RiverSystem (group "river", `bank_of`); `overrides` = setup entries with a "bank" key. Without a
## river: -1 near the centre (r < 11), else PLAYER west of the x = 0 line, ENEMY east.
func _refresh_banks(overrides: Array) -> void:
	var forced := {}
	for e: Variant in overrides:
		if e is Dictionary and (e as Dictionary).has("bank"):
			forced[StringName(str((e as Dictionary).get("id", "")))] = int((e as Dictionary)["bank"])
	for p in points():
		var id := StringName(p.get(&"point_id"))
		if forced.has(id):
			p.set(&"bank", forced[id])
		elif _river() != null:
			p.set(&"bank", _bank_of(p.global_position))


func _river() -> Node:
	if not is_inside_tree():
		return null
	var r := get_tree().get_first_node_in_group(&"river")
	return r if r and r.has_method(&"bank_of") else null


func _bank_of(pos: Vector3) -> int:
	var river := _river()
	if river:
		return int(river.call(&"bank_of", pos))
	if Vector2(pos.x, pos.z).length() < 11.0:
		return -1
	return PLAYER_TEAM if pos.x < 0.0 else ENEMY_TEAM


## Points are landmarks: explored for both teams from 0:00 (FogOfWar.reveal, group "fog").
func _reveal_all() -> void:
	for p in points():
		_reveal(p)


func _reveal(point: Node3D) -> void:
	if not is_inside_tree():
		return
	var fog := get_tree().get_first_node_in_group(&"fog")
	if fog == null or not fog.has_method(&"reveal"):
		return
	for t: int in [PLAYER_TEAM, ENEMY_TEAM]:
		fog.call(&"reveal", t, point.global_position, FOG_REVEAL_RADIUS)


func _on_owner_changed(point: Node3D, new_team: int, old_team: int) -> void:
	if _loading:
		return
	var shrine := StringName(point.get(&"kind")) == &"shrine"
	var pname := String(point.get(&"display_name"))
	if new_team == PLAYER_TEAM or new_team == ENEMY_TEAM:
		point_captured.emit(point, new_team)
		if shrine:
			var id := point.get_instance_id()
			if _first_wave.has(id) and match_time() < _wave_time(1):
				_first_capture[new_team] = minf(float(_first_capture[new_team]), match_time())
			_refresh_schedule()
		else:
			_say((MSG_CAPTURED_OWN if new_team == local_team else MSG_CAPTURED_ENEMY) % pname)
	elif old_team == PLAYER_TEAM or old_team == ENEMY_TEAM:
		if shrine and bool(point.call(&"is_awake")):
			return   # a waking shrine turns neutral: not a neutralisation
		point_neutralised.emit(point, old_team)
		_say(MSG_NEUTRALISED % pname)


## "Your forces are capturing X" (own, first time per point per 60 s) and "The enemy is taking X!" (own point, max
## once per 20 s).
func _progress_messages(p: Node3D, before_team: int, before: float, now: float) -> void:
	var t := int(p.get(&"capture_team"))
	var ratio := float(p.get(&"progress"))
	if t == -1 or ratio <= 0.0:
		return
	var id := p.get_instance_id()
	var pname := String(p.get(&"display_name"))
	if t == local_team and (before_team != t or before <= 0.0):
		if now - float(_msg_capturing.get(id, -INF)) >= CAPTURING_MSG_COOLDOWN:
			_msg_capturing[id] = now
			_say(MSG_CAPTURING % pname)
	elif t != local_team and int(p.get(&"owner_team")) == local_team and ratio > before:
		if now - float(_msg_taking.get(id, -INF)) >= TAKING_MSG_COOLDOWN:
			_msg_taking[id] = now
			_say(MSG_TAKING % pname)


# ---------------------------------------------------------------- wells

func _update_wells(dt: float, now: float) -> void:
	if now < WELL_START:
		return
	var wells := points(&"well")
	if wells.is_empty():
		return
	if not _wells_announced:
		_wells_announced = true
		_say(MSG_WELLS)
	var due := floori((now - WELL_START) / WELL_PERIOD)
	if due > _well_paid:
		_well_paid = due   # at most one payment per tick, even if the clock jumps
		for w in wells:
			var owner := int(w.get(&"owner_team"))
			if owner != PLAYER_TEAM and owner != ENEMY_TEAM:
				continue
			var bank := _essence_bank(owner)
			if bank:
				bank.call(&"add", roundi(WELL_INCOME * WELL_PERIOD))
			w.call(&"play_pulse")
	for w in wells:
		var owner := int(w.get(&"owner_team"))
		if owner != PLAYER_TEAM and owner != ENEMY_TEAM:
			continue
		for wiz in _wizards(owner):
			var wp := (wiz as Node3D).global_position
			var d := Vector2(wp.x - w.global_position.x, wp.z - w.global_position.z)
			if d.length_squared() > WELL_MANA_RADIUS * WELL_MANA_RADIUS:
				continue
			var mana: Variant = wiz.get(&"mana")
			var max_mana: Variant = wiz.get(&"max_mana")
			if mana != null and max_mana != null:
				wiz.set(&"mana", minf(float(max_mana), float(mana) + WELL_MANA * dt))


func _essence_bank(team: int) -> Node:
	for b in get_tree().get_nodes_in_group(&"essence_banks"):
		if b.get(&"team") != null and int(b.get(&"team")) == team and b.has_method(&"add") \
				and not b.is_queued_for_deletion():
			return b
	# None yet (banks are made on first use): EssenceBank.for_team creates it, load-guarded.
	if ResourceLoader.exists(ESSENCE_BANK_PATH):
		var script := load(ESSENCE_BANK_PATH) as GDScript
		if script:
			var made: Variant = script.call(&"for_team", team)
			return made as Node if made is Node else null
	return null


## Living wizards of `team` (groups "heroes" / "enemy_heroes").
func _wizards(team: int) -> Array:
	var out: Array = []
	for group: StringName in [&"heroes", &"enemy_heroes"]:
		for w in get_tree().get_nodes_in_group(group):
			if w is Node3D and w.get(&"team") != null and int(w.get(&"team")) == team and not out.has(w) \
					and (not w.has_method(&"is_alive") or bool(w.call(&"is_alive"))):
				out.append(w)
	return out


# ---------------------------------------------------------------- shrines

func _wave_time(wave: int) -> float:
	return SHRINE_FIRST + SHRINE_INTERVAL * float(wave)


func _update_shrines(now: float) -> void:
	var shrines := points(&"shrine")
	if shrines.is_empty():
		return
	if _shrine_wave == 0:
		if now >= SHRINE_FIRST:
			_shrine_wave = 1
			var woke := 0
			for s in shrines:
				if not bool(s.call(&"is_awake")):
					_first_wave[s.get_instance_id()] = true
					s.call(&"wake")
					shrine_awakened.emit(s)
					woke += 1
			if woke > 0:
				_say(MSG_SHRINES if woke > 1 else MSG_SHRINE % String(shrines[0].get(&"display_name")))
	elif now >= _wave_time(_shrine_wave):
		if _shrine_wave == 1:
			_alt_bank = _decide_alt_bank()
		var s := _shrine_for_wave(_shrine_wave)
		_shrine_wave += 1
		if s and not bool(s.call(&"is_awake")):
			s.call(&"wake")
			shrine_awakened.emit(s)
			_say(MSG_SHRINE % String(s.get(&"display_name")))
	_refresh_schedule()


## The bank of the 6:00 shrine: the team slower to capture a 3:00 shrine (never = slowest); tie = coin flip.
func _decide_alt_bank() -> int:
	var tp := float(_first_capture[PLAYER_TEAM])
	var te := float(_first_capture[ENEMY_TEAM])
	if tp > te:
		return PLAYER_TEAM
	if te > tp:
		return ENEMY_TEAM
	return _coin


## The shrine that wakes at wave `wave` (>= 1): banks alternate from the 6:00 bank (decided, or provisional before
## 6:00). Falls back to any sleeping shrine when that bank has none asleep; null when none can wake.
func _shrine_for_wave(wave: int) -> Node3D:
	var first := _alt_bank if _alt_bank != -1 else _decide_alt_bank()
	var bank := first if wave % 2 == 1 else 1 - first
	var fallback: Node3D = null
	for s in points(&"shrine"):
		if bool(s.call(&"is_awake")):
			continue
		if int(s.get(&"bank")) == bank:
			return s
		if fallback == null:
			fallback = s
	for s in points(&"shrine"):
		if int(s.get(&"bank")) == bank:
			return s   # awake already: the slot passes
	return fallback


## Tells every sleeping shrine when it wakes next (its time_until_awake()).
func _refresh_schedule() -> void:
	var shrines := points(&"shrine")
	if shrines.is_empty():
		return
	var now := match_time()
	if _shrine_wave == 0:
		for s in shrines:
			s.call(&"set_wake_time", SHRINE_FIRST, now)
		return
	var next := _shrine_for_wave(_shrine_wave)
	var after := _shrine_for_wave(_shrine_wave + 1)
	for s in shrines:
		var at := INF
		if s == next:
			at = _wave_time(_shrine_wave)
		elif s == after:
			at = _wave_time(_shrine_wave + 1)
		s.call(&"set_wake_time", at, now)


# ---------------------------------------------------------------- blessing

func _on_blessing_granted(_point: Node3D, team: int) -> void:
	if team != PLAYER_TEAM and team != ENEMY_TEAM:
		return
	var fresh := float(_blessing_left[team]) <= 0.0
	_blessing_left[team] = BLESSING_TIME
	if fresh:
		for u in get_tree().get_nodes_in_group(&"units"):
			apply_blessing(u)
	_set_watching(true)
	blessing_started.emit(team, BLESSING_TIME)
	_say(MSG_BLESSING_OWN if team == local_team else MSG_BLESSING_ENEMY)


func _update_blessings(dt: float) -> void:
	for team: int in [PLAYER_TEAM, ENEMY_TEAM]:
		var left := float(_blessing_left[team])
		if left <= 0.0:
			continue
		left -= dt
		_blessing_left[team] = maxf(left, 0.0)
		if left <= 0.0:
			_end_blessing(team)
	if _watching and float(_blessing_left[PLAYER_TEAM]) <= 0.0 and float(_blessing_left[ENEMY_TEAM]) <= 0.0:
		_set_watching(false)


func _end_blessing(team: int) -> void:
	for u in _blessed[team]:
		if is_instance_valid(u) and u.has_method(&"remove_modifier"):
			u.call(&"remove_modifier", BLESSING_MODIFIER)
	(_blessed[team] as Array).clear()
	blessing_ended.emit(team)


func _set_watching(on: bool) -> void:
	if not is_inside_tree():
		_watching = false
		return
	var tree := get_tree()
	if on and not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	elif not on and tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)
	_watching = on


## New units while a blessing runs: blessed once they are ready (deferred: team and groups are set by then).
func _on_node_added(node: Node) -> void:
	if node is Unit:
		apply_blessing.call_deferred(node)


# ---------------------------------------------------------------- messages

func _say(text: String) -> void:
	if message.get_connections().is_empty():
		var scene := get_tree().current_scene if is_inside_tree() else null
		var hud: Variant = scene.get(&"hud") if scene else null
		if hud is Node and is_instance_valid(hud) and (hud as Node).has_method(&"show_message"):
			(hud as Node).call(&"show_message", text, MSG_SECONDS)
		return
	message.emit(text, MSG_SECONDS)
