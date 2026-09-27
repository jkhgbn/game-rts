class_name CritterHerds
extends Node
## The huntable game critters of a map: 2 deer herds x 3 and 12 rabbits (docs/design/map-fill.md 3.4 / 9, task
## 12.C10; contract section 13). Group "critter_herds"; find it with `CritterHerds.instance(tree)`.
## - setup(herds, rabbit_homes) creates the GameCritters (children of this node, group "game_critters", never
##   in "units").
## - Drives them: think() at 5 Hz, staggered over the frames (one or two critters per frame); movement runs only
##   on moving critters (their own physics process). Cost target < 0.03 ms / frame for the 18.
## - Local-team fog at 5 Hz: each critter is shown / hidden and its click area switched on / off like an enemy
##   unit (fog_of_war.gd does not change); critters outside the camera's ground view are kept hidden without a
##   fog read (FogOfWar.is_visible costs ~6 us in GDScript).
## - Rewards: at the killing blow, grant(team, critter.reward, by) (essence through the team's EssenceBank);
##   deer = venison: the killer heals 40 HP and its team's other units within 6 m heal 20 HP. No XP, no
##   veterancy, no champion loot (no Events.unit_died is emitted). hunted_count(team) for the end screen.
## - Respawn: 1 deer per herd every 120 s while the herd has < 3; each rabbit 90 s after its death at its home.
##   Only in cells no team sees now (else retry every 5 s).
## - Herds drift: every 30-55 s a herd picks another of its graze spots and its deer walk there.

signal critter_hunted(critter: Node3D, team: int, reward: Dictionary)

const REWARDS := {&"deer": {&"essence": 5}, &"rabbit": {&"essence": 1}}
const VENISON_HEAL := 40.0
const VENISON_AREA_HEAL := 20.0
const VENISON_RADIUS := 6.0
const DEER_PER_HERD := 3
const DEER_RESPAWN := 120.0
const RABBIT_RESPAWN := 90.0
const RESPAWN_RETRY := 5.0
const THINK_INTERVAL := 0.2
const HERD_MOVE_MIN := 30.0
const HERD_MOVE_MAX := 55.0
const HERD_RING := 1.6          ## Deer stand on a ring this wide around the herd's spot.
const RNG_SEED := 3413
const VIEW_MARGIN := 14.0       ## Metres around the camera's ground view where visibility is kept exact.
const TEAM_PLAYER := 0
const TEAM_ENEMY := 1

## team -> {reward key (StringName) -> total granted}. Every key is kept (paid or not): step 15 reads `food`.
var granted_totals: Dictionary = {}
var rng := RandomNumberGenerator.new()

var _critters: Array[GameCritter] = []
var _herds: Array[Dictionary] = []     # {id, spots: PackedVector3Array, members: Array of GameCritter, size,
                                       #  spot: int, move_left: float, respawn_left: float (-1 = not running)}
var _rabbit_left := {}                 # dead rabbit (GameCritter) -> seconds before its respawn try
var _hunted := {TEAM_PLAYER: 0, TEAM_ENEMY: 0}
var _fog: FogOfWar
var _fog_search_left := 0.0
var _think_acc := 0.0
var _think_i := 0
var _slow_acc := 0.0


## The CritterHerds of the current level, or null.
static func instance(tree: SceneTree) -> CritterHerds:
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(&"critter_herds"):
		var h := node as CritterHerds
		if h and not h.is_queued_for_deletion():
			return h
	return null


func _init() -> void:
	add_to_group("critter_herds")
	rng.seed = RNG_SEED


func _ready() -> void:
	add_to_group("critter_herds")


## `herds`: one entry per deer herd, a Dictionary `{id, spots}` (also accepted: `graze`, `graze_spots`,
## `points`; optional `count`, default 3, and `respawn`, default 120 s) or directly the spots (Array / PackedVector3Array). Spots and
## `rabbit_homes` may be Vector3 or Vector2 (x, z). Typed arrays (Array[Dictionary], Array[Vector3]) work.
## Calling it again replaces every critter.
func setup(herds: Array, rabbit_homes: Array) -> void:
	for c: GameCritter in _critters:
		if is_instance_valid(c):
			c.queue_free()
	_critters.clear()
	_herds.clear()
	_rabbit_left.clear()
	for i: int in herds.size():
		var h: Variant = herds[i]
		var spots := PackedVector3Array()
		var id := StringName("herd_%d" % i)
		var count := DEER_PER_HERD
		var respawn := DEER_RESPAWN
		if h is Dictionary:
			var d: Dictionary = h
			for key: String in ["spots", "graze", "graze_spots", "points"]:
				if d.has(key) or d.has(StringName(key)):
					spots = _to_points(d.get(key, d.get(StringName(key))))
					break
			id = StringName(str(d.get("id", d.get(&"id", id))))
			count = int(d.get("count", d.get(&"count", count)))
			respawn = float(d.get("respawn", d.get(&"respawn", respawn)))
		else:
			spots = _to_points(h)
		if spots.is_empty():
			continue
		var members: Array = []
		for j: int in count:
			var pos := spots[0] + _ring(j, count)
			members.append(_make(&"deer", pos, spots, id, j == 0, i * 16 + j + 1))
		_herds.append({"id": id, "spots": spots, "members": members, "size": count, "spot": 0, "respawn": respawn,
				"move_left": rng.randf_range(HERD_MOVE_MIN * 0.5, HERD_MOVE_MAX), "respawn_left": -1.0})
	var homes := _to_points(rabbit_homes)
	for i: int in homes.size():
		_make(&"rabbit", homes[i], PackedVector3Array(), &"", false, 1000 + i)
	_think_acc = 0.0
	_think_i = 0


## Living critters, all or of one `kind` (&"deer" / &"rabbit").
func critters(kind: StringName = &"") -> Array:
	var out: Array = []
	for c: GameCritter in _critters:
		if is_instance_valid(c) and c.is_alive() and (kind == &"" or c.kind == kind):
			out.append(c)
	return out


## Every critter node, dead ones included (tests, debug).
func all_critters() -> Array:
	return _critters.duplicate()


## Pays `reward` to `team`: every key it knows (today `essence`, through the team's EssenceBank); every key,
## known or not, is added to granted_totals[team] (step 15 food reads it). `by` = the hunter (may be null).
func grant(team: int, reward: Dictionary, _by: Node) -> void:
	if team != TEAM_PLAYER and team != TEAM_ENEMY:
		return
	var totals: Dictionary = granted_totals.get(team, {})
	granted_totals[team] = totals
	for key: Variant in reward:
		var k := StringName(str(key))
		var amount: Variant = reward[key]
		if not (amount is int or amount is float):
			continue
		totals[k] = totals.get(k, 0) + amount
		if k == &"essence":
			var bank := _essence_bank(team)
			if bank != null:
				bank.call(&"add", roundi(float(amount)))


## Game critters killed by `team` this match (end screen `Game hunted N`).
func hunted_count(team: int) -> int:
	return int(_hunted.get(team, 0))


## Seconds before herd `herd_id`'s next deer respawn try (-1 = the herd is full).
func deer_respawn_left(herd_id: StringName) -> float:
	for h: Dictionary in _herds:
		if h["id"] == herd_id:
			return float(h["respawn_left"])
	return -1.0


## Seconds before this dead rabbit's next respawn try (-1 = alive / not waiting).
func rabbit_respawn_left(rabbit: Node) -> float:
	return float(_rabbit_left.get(rabbit, -1.0))


# ================================================================ internals

func _make(kind: StringName, pos: Vector3, spots: PackedVector3Array, herd_id: StringName, stag: bool,
		seed_value: int) -> GameCritter:
	var c := GameCritter.new()
	c.name = "%s_%d" % [String(kind).capitalize(), _critters.size()]
	c.setup(kind, pos, spots, seed_value * 7919 + RNG_SEED)
	c.herd_id = herd_id
	c.stag = stag
	c.herds = self
	c.reward = (REWARDS.get(kind, {}) as Dictionary).duplicate()
	c.hunted.connect(_on_critter_hunted)
	add_child(c)
	_critters.append(c)
	return c


func _physics_process(delta: float) -> void:
	var n := _critters.size()
	if n == 0:
		return
	# Staggered 5 Hz thinking: n critters spread over 0.2 s.
	_think_acc = minf(_think_acc + delta * float(n) / THINK_INTERVAL, float(n))
	while _think_acc >= 1.0:
		_think_acc -= 1.0
		var c := _critters[_think_i]
		_think_i = (_think_i + 1) % n
		if is_instance_valid(c) and c.is_alive():
			c.think(THINK_INTERVAL)
	_slow_acc += delta
	if _slow_acc >= THINK_INTERVAL:
		_slow_tick(_slow_acc)
		_slow_acc = 0.0


func _slow_tick(dt: float) -> void:
	if _fog == null or not is_instance_valid(_fog):
		_fog = null
		_fog_search_left -= dt
		if _fog_search_left <= 0.0:
			_fog_search_left = 1.0
			_fog = get_tree().get_first_node_in_group(&"fog") as FogOfWar
	_refresh_visibility()
	_tick_herds(dt)
	_tick_rabbits(dt)


## Local-team view at the fog's 5 Hz: shown (and clickable) only where the local team sees now. Critters
## outside the camera's ground view (+ VIEW_MARGIN) are simply kept hidden (they cannot be seen or clicked
## there anyway), which spares the fog reads: `visible` is presentation only, gameplay uses is_visible_to().
func _refresh_visibility() -> void:
	var fog := _fog if _fog != null and is_instance_valid(_fog) else null
	var on := fog != null and fog.enabled
	var local: int = fog.local_team if fog != null else TEAM_PLAYER
	var view := _camera_view()
	var cull := view.size.x > 0.0
	for c: GameCritter in _critters:
		if not is_instance_valid(c):
			continue
		var p := c.global_position
		if cull and not view.has_point(Vector2(p.x, p.z)):
			c.set_seen(false)
		else:
			c.set_seen(not on or fog.is_visible(local, p))


## The camera's ground footprint (y = 0) grown by VIEW_MARGIN, or an empty Rect2 = no culling (no camera,
## or a corner ray above the horizon).
func _camera_view() -> Rect2:
	var vp := get_viewport()
	var cam: Camera3D = vp.get_camera_3d() if vp else null
	if cam == null or not cam.is_inside_tree():
		return Rect2()
	var size := vp.get_visible_rect().size
	var ground := Plane(Vector3.UP, 0.0)
	var rect := Rect2()
	var first := true
	for corner: Vector2 in [Vector2.ZERO, Vector2(size.x, 0.0), Vector2(0.0, size.y), size]:
		var hit: Variant = ground.intersects_ray(cam.project_ray_origin(corner), cam.project_ray_normal(corner))
		if hit == null:
			return Rect2()
		var h := hit as Vector3
		if first:
			rect = Rect2(h.x, h.z, 0.0, 0.0)
			first = false
		else:
			rect = rect.expand(Vector2(h.x, h.z))
	return rect.grow(VIEW_MARGIN)


func _tick_herds(dt: float) -> void:
	for h: Dictionary in _herds:
		var members: Array = h["members"]
		var alive := 0
		for c: Variant in members:
			if is_instance_valid(c) and (c as GameCritter).is_alive():
				alive += 1
		# Respawn: 1 deer every 120 s while the herd is short.
		if alive >= int(h["size"]):
			h["respawn_left"] = -1.0
		else:
			if float(h["respawn_left"]) < 0.0:
				h["respawn_left"] = float(h["respawn"])
			h["respawn_left"] = float(h["respawn_left"]) - dt
			if float(h["respawn_left"]) <= 0.0:
				h["respawn_left"] = -1.0 if _respawn_deer(h) else RESPAWN_RETRY
		# Drift to another graze spot now and then.
		h["move_left"] = float(h["move_left"]) - dt
		var spots: PackedVector3Array = h["spots"]
		if float(h["move_left"]) <= 0.0 and spots.size() > 1:
			h["move_left"] = rng.randf_range(HERD_MOVE_MIN, HERD_MOVE_MAX)
			var next := rng.randi_range(0, spots.size() - 2)
			if next >= int(h["spot"]):
				next += 1
			h["spot"] = next
			for j: int in members.size():
				var c: GameCritter = members[j] as GameCritter if is_instance_valid(members[j]) else null
				if c != null and c.is_alive():
					c.set_graze_center(spots[next] + _ring(j, members.size()), rng.randf_range(0.0, 4.0))


func _respawn_deer(h: Dictionary) -> bool:
	var members: Array = h["members"]
	var spots: PackedVector3Array = h["spots"]
	var dead: GameCritter = null
	for c: Variant in members:
		if is_instance_valid(c) and (c as GameCritter).can_respawn():
			dead = c as GameCritter
			break
	if dead == null:
		return false
	var first := int(h["spot"])
	for k: int in spots.size():
		var spot := spots[(first + k) % spots.size()]
		var pos := spot + _ring(rng.randi_range(0, 5), 6)
		if _seen_by_any(pos) or _seen_by_any(spot):
			continue
		dead.respawn(pos)
		dead.set_graze_center(spot + _ring(members.find(dead), members.size()), rng.randf_range(0.0, 3.0))
		return true
	return false


func _tick_rabbits(dt: float) -> void:
	if _rabbit_left.is_empty():
		return
	for c: Variant in _rabbit_left.keys():
		if not is_instance_valid(c):
			_rabbit_left.erase(c)
			continue
		var r := c as GameCritter
		var left := float(_rabbit_left[r]) - dt
		if left > 0.0:
			_rabbit_left[r] = left
			continue
		if r.can_respawn() and not _seen_by_any(r.home):
			r.respawn(r.home)
			_rabbit_left.erase(r)
		else:
			_rabbit_left[r] = RESPAWN_RETRY


func _on_critter_hunted(critter: Node3D, team: int, by: Node) -> void:
	var c := critter as GameCritter
	if c == null:
		return
	var reward: Dictionary = c.reward.duplicate()
	if team == TEAM_PLAYER or team == TEAM_ENEMY:
		_hunted[team] = int(_hunted.get(team, 0)) + 1
		grant(team, reward, by)
		if c.kind == &"deer":
			_venison(c, team, by)
	if c.kind == &"rabbit":
		_rabbit_left[c] = RABBIT_RESPAWN
	else:
		for h: Dictionary in _herds:
			if (h["members"] as Array).has(c) and float(h["respawn_left"]) < 0.0:
				h["respawn_left"] = float(h["respawn"])
	critter_hunted.emit(c, team, reward)


## Venison: the killer heals 40 HP, its team's other living units within 6 m of the deer heal 20 HP.
func _venison(c: GameCritter, team: int, by: Node) -> void:
	var hunter: Node = by if by != null and is_instance_valid(by) else null
	if hunter != null and hunter.has_method(&"heal") and hunter.get(&"team") != null \
			and int(hunter.get(&"team")) == team \
			and (not hunter.has_method(&"is_alive") or bool(hunter.call(&"is_alive"))):
		hunter.call(&"heal", VENISON_HEAL)
	var at := c.global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or u == hunter or u.team != team or not u.is_alive():
			continue
		var p := u.global_position
		if Vector2(p.x - at.x, p.z - at.z).length() <= VENISON_RADIUS:
			u.heal(VENISON_AREA_HEAL)


func _essence_bank(team: int) -> Node:
	for node in get_tree().get_nodes_in_group(&"essence_banks"):
		if node.get(&"team") != null and int(node.get(&"team")) == team and node.has_method(&"add") \
				and not node.is_queued_for_deletion():
			return node
	return null


## True when a team sees `pos` now (fog off / no fog: false, so respawns never stall).
func _seen_by_any(pos: Vector3) -> bool:
	var fog := _fog if _fog != null and is_instance_valid(_fog) else null
	if fog == null or not fog.enabled:
		return false
	return fog.is_visible(TEAM_PLAYER, pos) or fog.is_visible(TEAM_ENEMY, pos)


static func _ring(j: int, count: int) -> Vector3:
	if count <= 1:
		return Vector3.ZERO
	var a := TAU * float(j) / float(count) + 0.4
	return Vector3(cos(a), 0.0, sin(a)) * HERD_RING


static func _to_points(v: Variant) -> PackedVector3Array:
	var out := PackedVector3Array()
	if v is PackedVector3Array:
		return (v as PackedVector3Array).duplicate()
	if v is PackedVector2Array:
		for p: Vector2 in v:
			out.append(Vector3(p.x, 0.0, p.y))
		return out
	if v is Array:
		for p: Variant in v:
			if p is Vector3:
				out.append(p)
			elif p is Vector2:
				out.append(Vector3((p as Vector2).x, 0.0, (p as Vector2).y))
	return out
