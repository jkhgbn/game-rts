class_name Teams
extends RefCounted
## Seats and sides (docs/design/map-2v2.md 4.1 / 5, the 2v2 runtime built 2026-10-06 for e2m2). `team` IS the seat
## (`Unit.Team` PLAYER 0, ENEMY 1, NEUTRAL 2, ALLY 3, ENEMY_2 4); a side is a team of seats (0 = PLAYER's, 1 = the
## other). Static state like MapInfo: one configuration per running level. main.gd configures it at the start of its
## `_ready` from the level's `seat_sides` (empty = the 1v1 {PLAYER: 0, ENEMY: 1}), so every 1v1 level, mission and
## test keeps the old rules exactly: with 2 seats `is_hostile(a, b) == (a != b)`.
## NEUTRAL is never a seat: side -1, hostile to every seat, allied only with itself (creatures never fight each other).

const NEUTRAL := 2
const PLAYER := 0
const ENEMY := 1
const ALLY := 3
const ENEMY_2 := 4
const DEFAULT_SIDES := {0: 0, 1: 1}

static var _sides: Dictionary = {0: 0, 1: 1}   ## seat -> side
static var _human := 0
static var _opponent: Dictionary = {}           ## seat -> the seat its bot plays against (lane opponent)
## True when more than one seat shares a side (the hot paths take the 1v1 shortcut `a != b` otherwise).
static var multi := false
static var _owner_id := 0


## Seat -> side table (`{PLAYER: 0, ALLY: 0, ENEMY: 1, ENEMY_2: 1}`); `human` = the local player's seat; `opponents`
## = seat -> lane opponent (the Commander's `_enemy_team`; default: the first seat of the other side). `by` = the level
## that owns the setup (`release(by)` puts the 1v1 back when it leaves the tree).
static func configure(sides: Dictionary, human := PLAYER, opponents: Dictionary = {}, by: Object = null) -> void:
	_sides = {}
	for s: Variant in sides:
		_sides[int(s)] = int(sides[s])
	if _sides.is_empty():
		_sides = DEFAULT_SIDES.duplicate()
	_human = human
	_opponent = {}
	for s: Variant in opponents:
		_opponent[int(s)] = int(opponents[s])
	var per_side := {}
	multi = false
	for s: int in _sides:
		var side: int = _sides[s]
		per_side[side] = int(per_side.get(side, 0)) + 1
		if int(per_side[side]) > 1:
			multi = true
	_owner_id = by.get_instance_id() if by != null else 0


## Back to the 1v1 (tests, a level without seats).
static func reset() -> void:
	configure(DEFAULT_SIDES)


## The level `by` leaves the tree: if it still owns the setup, the 1v1 comes back (a later level / tool / test never
## inherits a 2v2 table).
static func release(by: Object) -> void:
	if by != null and _owner_id == by.get_instance_id():
		reset()


## Every seat, sorted by team value.
static func seats() -> Array[int]:
	var out: Array[int] = []
	for s: int in _sides:
		out.append(s)
	out.sort()
	return out


static func has_seat(team: int) -> bool:
	return _sides.has(team)


## The side of a seat; -1 for NEUTRAL or an unknown team. Unknown seats 0 / 1 still map to their 1v1 side.
static func side_of(team: int) -> int:
	if _sides.has(team):
		return int(_sides[team])
	if team == PLAYER or team == ALLY:
		return 0
	if team == ENEMY or team == ENEMY_2:
		return 1
	return -1


static func seats_of_side(side: int) -> Array[int]:
	var out: Array[int] = []
	for s in seats():
		if int(_sides[s]) == side:
			out.append(s)
	return out


## Same side (a seat is its own ally; NEUTRAL with NEUTRAL true, NEUTRAL with any seat false).
static func is_ally(a: int, b: int) -> bool:
	if a == b:
		return true
	if not multi:
		return false
	var sa := side_of(a)
	return sa >= 0 and sa == side_of(b)


static func is_hostile(a: int, b: int) -> bool:
	return not is_allied_fast(a, b)


## The hot-path form of is_ally (the 1v1 shortcut without a dictionary lookup).
static func is_allied_fast(a: int, b: int) -> bool:
	if a == b:
		return true
	if not multi:
		return false
	var sa := side_of(a)
	return sa >= 0 and sa == side_of(b)


## The other seats of `seat`'s side.
static func allies_of(seat: int) -> Array[int]:
	var out: Array[int] = []
	for s in seats():
		if s != seat and is_ally(s, seat):
			out.append(s)
	return out


static func hostile_seats(seat: int) -> Array[int]:
	var out: Array[int] = []
	for s in seats():
		if is_hostile(s, seat):
			out.append(s)
	return out


static func is_human(seat: int) -> bool:
	return seat == _human


static func human_seat() -> int:
	return _human


static func opposing_side(side: int) -> int:
	return 1 - side if side == 0 or side == 1 else -1


## The seat a bot of `seat` plays against (Skirmish.enemy_team_of): the configured lane opponent, else the first seat
## of the other side, else the 1v1 answer.
static func opponent_of(seat: int) -> int:
	if _opponent.has(seat):
		return int(_opponent[seat])
	var other := seats_of_side(opposing_side(side_of(seat)))
	if not other.is_empty():
		return other[0]
	return ENEMY if seat == PLAYER else PLAYER


## `&"self"`, `&"ally"`, `&"enemy"` or `&"neutral"` of `team` seen from `local` (colours, labels).
static func relation(local: int, team: int) -> StringName:
	if team == local:
		return &"self"
	if team == NEUTRAL:
		return &"neutral"
	return &"ally" if is_ally(local, team) else &"enemy"
