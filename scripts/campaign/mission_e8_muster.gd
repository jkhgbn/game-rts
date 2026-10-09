class_name MissionE8Muster
extends MissionE8Base
## The four-seat field of e8m2 "The Last Muster" and e8m3 "The Hollow King" (docs/design/mission-e8-02.md 2 / 3,
## mission-e8-03.md 2 / 3): the player's kingdom at A1 (south-west), the other three as allied seats A2 (north-west,
## Teams.ALLY), B1 (north-east, the ENEMY slot) and B2 (south-east, ENEMY_2) in the prologue's order after the player's
## kingdom (table 2.1). All four seats are side 0; the Hollow Host is team NEUTRAL (hostile to all four).
##
## Built deviations (2026-10-09, from the spec): Fourfold Hollow (168 m) is not loaded: the field is the generator map
## at 120 x 120 with the four corners as seats, the isle at (0, 0) and the keyholes 24.8 m from it on the diagonals.
## The allied seats have no Commander: their armies are scripted (guard their quarter within 35 m, marches by the
## mission) and kept up to 70 % of their start count by reinforcements at their keep every 2:00 ("they train to 40
## pop"). Allied wizards kneel instead of dying (10 s); allied keeps never drop under 20 %. No taverns, Lairs, titans
## or Pell (the companion still walks in through the track).

const SEATS: Array[int] = [Unit.Team.PLAYER, Teams.ALLY, Unit.Team.ENEMY, Teams.ENEMY_2]
const SEAT_NAMES := {Unit.Team.PLAYER: "A1", Teams.ALLY: "A2", Unit.Team.ENEMY: "B1", Teams.ENEMY_2: "B2"}
## Seat frame signs (x, z): A1 south-west, A2 north-west, B1 north-east, B2 south-east.
const FRAME := {Unit.Team.PLAYER: Vector2(-1.0, 1.0), Teams.ALLY: Vector2(-1.0, -1.0), Unit.Team.ENEMY: Vector2(1.0, -1.0),
		Teams.ENEMY_2: Vector2(1.0, 1.0)}
const KEYHOLE_D := 17.5          ## 24.7 m from (0, 0) on the diagonal
const CRACK := Vector3.ZERO
const ALLY_KNEEL := 10.0
const ALLY_KEEP_FLOOR := 0.2
const DEFEND_R := 35.0
const REINFORCE_EVERY := 120.0
const REINFORCE_KEEP := 0.7
const ALLY_LEVEL := 6

## Read only.
var seat_kind := {}            ## seat -> kingdom
var seat_wizard := {}             ## seat -> Wizard
var ally_army := {}               ## seat -> Array of its scripted soldiers
var ally_start := {}              ## seat -> [[type, count], ...] (the reinforcement target)
var ally_busy := {}               ## seat -> &"" / &"push" / &"march" / &"sortie"

var _reinforce_t := REINFORCE_EVERY
var _defend_t := 0.0


## Seat `seat`'s point: the A1 frame point `p` (x < 0, z > 0) mirrored into its corner.
static func at_seat(seat: int, p: Vector3) -> Vector3:
	var f: Vector2 = FRAME[seat]
	return Vector3(absf(p.x) * f.x, p.y, absf(p.z) * f.y)


static func keyhole_of(seat: int) -> Vector3:
	return at_seat(seat, Vector3(-KEYHOLE_D, 0.0, KEYHOLE_D))


static func keep_pos(seat: int) -> Vector3:
	return at_seat(seat, Vector3(-43.0, 0.0, 43.0))


static func rally_of(seat: int) -> Vector3:
	return at_seat(seat, Vector3(-30.0, 0.0, 30.0))


## The seat order of table 2.1: the player's kingdom, then the next three in the prologue's order.
static func seat_table(player: StringName) -> Dictionary:
	var i := E8_KINGDOMS.find(player)
	var out := {}
	for j in 4:
		out[SEATS[j]] = E8_KINGDOMS[(i + j) % 4]
	return out


func seat_of_kingdom(k: StringName) -> int:
	for s: int in seat_kind:
		if seat_kind[s] == k:
			return s
	return -1


func allies() -> Array[int]:
	return [Teams.ALLY, Unit.Team.ENEMY, Teams.ENEMY_2]


func muster_config(c: MissionConfig) -> void:
	road = saved_road(campaign_save_path)
	seat_kind = seat_table(road)
	e8_config(c)
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "Your keep has fallen."
	c.start_tiers = {Unit.Team.PLAYER: 3, Teams.ALLY: 3, Unit.Team.ENEMY: 3, Teams.ENEMY_2: 3}
	c.helper_start_called = true
	c.seat_sides = {Unit.Team.PLAYER: 0, Teams.ALLY: 0, Unit.Team.ENEMY: 0, Teams.ENEMY_2: 0}
	c.seat_opponents = {}
	c.seat_kingdoms = seat_kind.duplicate()
	c.victory_banner = "VICTORY"
	c.defeat_banner = "DEFEAT"


func _init() -> void:
	super()
	host_team = Unit.Team.NEUTRAL


func _map_size() -> Vector2:
	return Vector2(120.0, 120.0)


func _player_start() -> Vector3:
	return at_seat(Unit.Team.PLAYER, Vector3(-36.0, 0.0, 36.0))


func _ground_spots() -> Array[Vector4]:
	var out: Array[Vector4] = [Vector4(0.0, 0.0, 12.0, 1.0)]
	for s: int in SEATS:
		var k := keep_pos(s)
		out.append(Vector4(k.x, k.z, 12.0, 0.0))
	return out


func _ready() -> void:
	player_kingdom = road
	super()
	if camera_rig:
		camera_rig.focus_on(_player_start())


func start_position(team: int) -> Vector3:
	return at_seat(team if FRAME.has(team) else Unit.Team.PLAYER, Vector3(-36.0, 0.0, 36.0))


func base_center(team: int) -> Vector3:
	return keep_pos(team if FRAME.has(team) else Unit.Team.PLAYER)


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	return k.spawn_point() if k else base_center(team) + Vector3(4.0, 0.0, 4.0)


func node_of(team: int, suffix: String) -> CrystalNode:
	var v: Variant = crystal_nodes.get(StringName("e8s%d_%s" % [team, suffix]))
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func bot_point(team: int, p: Vector3) -> Vector3:
	return at_seat(team if FRAME.has(team) else Unit.Team.ENEMY, p)


func bot_vector(team: int, v: Vector3) -> Vector3:
	var f: Vector2 = FRAME.get(team, Vector2(1.0, -1.0))
	return Vector3(v.x * f.x, v.y, -v.z * f.y)


func natural_hall_spot(team: int) -> Vector3:
	return at_seat(team if FRAME.has(team) else Unit.Team.PLAYER, Vector3(-28.0, 0.0, 14.0))


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


# ---------------------------------------------------------------- the map

## The four bases, nodes and the prop scatter (call from _build_map).
func build_field(map_seed: int, extra_clearings: Array) -> void:
	var clearings: Array = [[CRACK, 14.0]]
	var lanes: Array = []
	for s: int in SEATS:
		clearings.append([keep_pos(s), 18.0])
		clearings.append([rally_of(s), 8.0])
		clearings.append([keyhole_of(s), 6.0])
		clearings.append([natural_hall_spot(s), 6.0])
		lanes.append([keep_pos(s), CRACK, 6.0])
		for suf: String in ["a", "b", "mid"]:
			clearings.append([_node_pos(s, suf), 7.0])
	clearings.append_array(extra_clearings)
	scatter_props(map_seed, clearings, lanes, 8, 12)
	for s: int in SEATS:
		for suf: String in ["a", "b", "mid"]:
			_add_crystal_node(StringName("e8s%d_%s" % [s, suf]), _node_pos(s, suf), 2500 if suf == "mid" else 2000)
		var k := build_base(s, seat_kind[s], keep_pos(s), at_seat(s, Vector3(-27.0, 0.0, 45.0)),
				at_seat(s, Vector3(-37.0, 0.0, 29.0)), [at_seat(s, Vector3(-50.0, 0.0, 46.0)), at_seat(s, Vector3(-50.0, 0.0, 53.0)),
				at_seat(s, Vector3(-43.0, 0.0, 55.0))], 3)
		seat_starts[s] = start_position(s)
		if s == Unit.Team.PLAYER:
			keep = k
		elif k:
			k.name = "Keep%s" % SEAT_NAMES[s]
	ground_disc(CRACK, 6.0, Color(1.0, 0.70, 0.25, 0.45), 0.05)


func _node_pos(s: int, suf: String) -> Vector3:
	match suf:
		"a":
			return at_seat(s, Vector3(-46.0, 0.0, 34.0))
		"b":
			return at_seat(s, Vector3(-34.0, 0.0, 46.0))
	return at_seat(s, Vector3(-24.0, 0.0, 10.0))


# ---------------------------------------------------------------- the seats at 0:00

## The player's start (the track, workers, army, wizard) and the three allied seats (keep already built by
## build_field; wizard, workers, scripted army). `army_mult` scales every count (e8m3: + 25 %).
func start_seats(level: int, army_mult: float, prev_mission: StringName) -> void:
	_setup_champions()
	spawn_player_wizard(_player_start())
	load_track(true, prev_mission)
	spawn_workers(Unit.Team.PLAYER, road, 8, keep_pos(Unit.Team.PLAYER) + Vector3(4.0, 0.0, -4.0),
			[node_of(0, "a"), node_of(0, "b")])
	spawn_army(_scaled_rows(MUSTER_ARMY[road], army_mult), rally_of(Unit.Team.PLAYER))
	var diff := clampi(mission_difficulty, 0, 2)
	for s: int in allies():
		var k: StringName = seat_kind[s]
		var spells: Array = []
		for sp: Variant in SPELLS_OF[k]:
			spells.append(sp)
		spells.append(SPELLS_OF[k][0])
		spells.append(SPELLS_OF[k][0])
		spells.append(SPELLS_OF[k][1])
		var out := activate_seat(s, k, {"crystals": 0, "wizard": {"level": level + (1 if diff == 0 else 0), "spells": spells,
				"pos": start_position(s)}})
		var w := out.get("wizard") as Wizard
		if w:
			seat_wizard[s] = w
			mark_scripted(w)
			w.set_meta(META_HOME, rally_of(s))
			kneel_guard(w, ALLY_KNEEL, _on_ally_kneel)
		spawn_workers(s, k, 6, keep_pos(s), [node_of(s, "a"), node_of(s, "b")])
		var rows := _scaled_rows(MUSTER_ARMY[k], army_mult)
		ally_start[s] = rows
		ally_army[s] = []
		ally_busy[s] = &""
		for v: Variant in spawn_army(rows, rally_of(s), s):
			_enlist(s, v as Unit)
	seat_wizard[Unit.Team.PLAYER] = hero


static func _scaled_rows(rows: Array, mult: float) -> Array:
	var out: Array = []
	for r: Array in rows:
		out.append([r[0], maxi(1, roundi(float(r[1]) * mult))])
	return out


func _enlist(s: int, u: Unit) -> void:
	if u == null:
		return
	mark_scripted(u)
	u.set_meta(META_HOME, rally_of(s) + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
	_guards.append(u)
	(ally_army[s] as Array).append(u)


## Override: an allied wizard knelt (e8m2: +3 % Hollow).
func _on_ally_kneel(_u: Unit) -> void:
	pass


func ally_soldiers(s: int) -> Array:
	var alive := (ally_army.get(s, []) as Array).filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	ally_army[s] = alive
	return alive


## Allied quarter defence, reinforcements, kneeling wizards, keep floors (call every 0.5 s).
func tick_allies(dt: float) -> void:
	_reinforce_t -= dt
	var reinforce := _reinforce_t <= 0.0
	if reinforce:
		_reinforce_t = REINFORCE_EVERY
	_defend_t -= dt
	var defend := _defend_t <= 0.0
	if defend:
		_defend_t = 3.0
	var kneelers: Array = []
	for s: int in allies():
		var k := keep_of(s)
		keep_floor(k, ALLY_KEEP_FLOOR)
		kneelers.append(seat_wizard.get(s))
		var w: Wizard = seat_wizard.get(s)
		if w and is_instance_valid(w) and w.global_position.y < -3.0:   # pushed off the ground: back to its rally
			w.global_position = rally_of(s)
			w.velocity = Vector3.ZERO
		if reinforce:
			_reinforce(s)
		if defend and ally_busy.get(s, &"") == &"":
			_defend(s)
	tick_kneelers(kneelers)


func _reinforce(s: int) -> void:
	var have := {}
	for v: Variant in ally_soldiers(s):
		var id := String((v as Unit).unit_type.id)
		have[id] = int(have.get(id, 0)) + 1
	var made := 0
	for r: Array in ally_start[s]:
		var want := int(ceil(float(r[1]) * REINFORCE_KEEP))
		var n := want - int(have.get(String(r[0]), 0))
		for i in mini(n, 6 - made):
			var u := _spawn(make_unit(String(r[0])), s as Unit.Team, keep_pos(s).lerp(rally_of(s), 0.4) + Vector3(i * 0.8, 0.0, 0.0))
			_enlist(s, u)
			made += 1
		if made >= 6:
			return


## The seat's soldiers answer Host units inside its quarter (keep, rally, keyhole within 35 m).
func _defend(s: int) -> void:
	var foe: Unit = null
	for p: Vector3 in [keyhole_of(s), rally_of(s), keep_pos(s)]:
		var near := host_near(p, DEFEND_R)
		if not near.is_empty():
			foe = near[0]
			break
	if foe == null:
		return
	for v: Variant in ally_soldiers(s):
		var u := v as Unit
		if u.attack_target == null and not u.is_attack_moving():
			u.command_attack_move(foe.global_position)
	var w: Wizard = seat_wizard.get(s)
	if w and w.is_alive() and not w.has_meta(&"kneeling") and w.attack_target == null and _flat(w.global_position, foe.global_position) < 20.0:
		w.command_attack_move(foe.global_position)


## Sends the seat's soldiers (and wizard) to `at` (attack-move); `busy` marks them as out of the quarter defence.
func ally_order(s: int, at: Vector3, busy: StringName) -> void:
	ally_busy[s] = busy
	for v: Variant in ally_soldiers(s):
		var u := v as Unit
		u.set_meta(META_HOME, at + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
		u.command_attack_move(at)
	var w: Wizard = seat_wizard.get(s)
	if w and w.is_alive():
		w.set_meta(META_HOME, at)
		w.command_attack_move(at)


## The seat's soldiers go back to their rally.
func ally_home(s: int) -> void:
	ally_busy[s] = &""
	for v: Variant in ally_soldiers(s):
		var u := v as Unit
		u.set_meta(META_HOME, rally_of(s) + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
		u.command_move(u.get_meta(META_HOME))
	var w: Wizard = seat_wizard.get(s)
	if w and w.is_alive():
		w.set_meta(META_HOME, rally_of(s))


## Living soldiers of the seat (any unit not a worker / wizard) — the player's from its team.
func seat_army_value(s: int) -> int:
	var n := 0
	for u: Unit in units_of(s, true):
		if not u is Wizard and u.unit_type:
			n += int(u.unit_type.cost)
	return n


func say_ally(s: int, lines_by_kingdom: Dictionary) -> void:
	if s == Unit.Team.PLAYER:
		return
	var id: Variant = lines_by_kingdom.get(seat_kind.get(s, &""))
	if id != null:
		say_l(String(id))


## Wardens rising at the isle toward seat `s`'s keyhole (route through the keyhole, then its hub).
func crack_toward(s: int, rows: Array) -> Array:
	var from := CRACK + keyhole_of(s).normalized() * 5.0
	return host_wave(rows, from, [keyhole_of(s)], rally_of(s))


## A Host wave that reached its goal stays in that quarter (E7Base would send it on to the player's keep: on the
## four-seat field every tide would end on A1).
func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	if mode != &"route" or not (u.get_meta(&"e7_route", []) as Array).is_empty():
		return super(u, mode, hero_at)
	var goal: Vector3 = u.get_meta(META_TARGET, u.global_position)
	if u.attack_target == null and not u.is_attack_moving():
		var foe := _player_near(goal, 30.0)
		u.command_attack_move(foe.global_position if foe else goal)
	return true
