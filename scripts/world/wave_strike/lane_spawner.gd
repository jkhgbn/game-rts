class_name LaneSpawner
extends Node
## One seat's spawner (docs/design/wave-strike.md 7.3, 15.3): at each horn it takes the Muster Pad snapshot
## (`queue_horn`) and spawns the copies one every rules.spawn_stagger s, row by row front to back, inside a row from the
## centre outward (left first), each at its cell's mirrored spot in the spawn box (`MusterPad.cell_to_lane`) with the
## matching lateral offset that it keeps along the lane (LaneMarch). The field cap holds the back-most copies (the
## level refuses them). Every horn's copies form one WaveFormation (hold, march lock, release); the upgrades of each
## card are snapshot at the horn too (wave-strike.md 16: they count from the next horn). The level makes the unit
## (WaveStrikeLevel.spawn_lane_unit).

var seat := 0
var team: int = Unit.Team.PLAYER
var gate := Vector3.ZERO
var forward := Vector3.RIGHT        ## the walking direction at the gate
var level: Node                     ## WaveStrikeLevel
var rules: WaveStrikeRules
var stagger := 0.15
var spawned_total := 0
## The current horn's formation (null before the first horn) and every formation still marching.
var formation: WaveFormation
var formations: Array[WaveFormation] = []

## [{id: StringName, cell: Vector2i, pos: Vector3}] in spawn order.
var _queue: Array[Dictionary] = []
var _left := 0.0
var _hold_left := -1.0              ## >= 0: the last copy is out, the formation stands this long
var _horn := 0
## card id -> {"mask": int (bought slots), "arm": {stat: v}}: the upgrades snapshot of the last horn.
var _ups: Dictionary = {}
var _roster: MusterRoster


func setup(p_seat: int, p_team: int, p_gate: Vector3, p_forward: Vector3, p_level: Node, p_rules: WaveStrikeRules) -> void:
	seat = p_seat
	team = p_team
	gate = p_gate
	forward = Vector3(p_forward.x, 0.0, p_forward.z).normalized()
	level = p_level
	rules = p_rules
	stagger = p_rules.spawn_stagger
	name = "LaneSpawner%d" % seat


## The horn: the roster's pad snapshot (every copy at its cell) + its upgrades, as one new formation.
func queue_horn(roster: MusterRoster) -> void:
	_roster = roster
	_horn += 1
	_snapshot_upgrades(roster)
	var pad := roster.pad if roster != null else null
	if pad == null or pad.copy_count() == 0:
		if roster != null and pad == null:
			queue_wave(roster.spawn_list())
		return
	var list: Array[Dictionary] = []
	for c in pad.copies():
		var cell: Vector2i = c["cell"]
		list.append({"id": c["id"], "cell": cell, "pos": pad.cell_to_lane(cell, int(c["size"])),
				"key": spawn_key(cell, int(c["size"]))})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["key"]) < float(b["key"]))
	for e in list:
		e.erase("key")
	_start_wave(list)


## Spawn order key of a copy anchored at `cell` (15.3 step 1): rows front to back, then from the centre outward, left
## before right on a tie.
static func spawn_key(cell: Vector2i, size: int) -> float:
	var off := cell.x + size * 0.5 - MusterPad.COLS * 0.5
	return cell.y * 1000.0 + absf(off) * 10.0 + (0.0 if off < 0.0 else 1.0)


## A horn's units without a pad (labs / tests / older callers): auto-placed on a scratch pad in the Line style.
func queue_wave(ids: Array[StringName]) -> void:
	var pad := MusterPad.new()
	pad.setup(seat, WaveCardTable.load_default())
	pad.set_frame_from_gate(gate, forward)
	var list: Array[Dictionary] = []
	for id in ids:
		var cell := pad.auto_cell(id, &"line")
		var size := pad.footprint(id)
		if cell != MusterPad.NONE and pad.place(id, cell) == "":
			list.append({"id": id, "cell": cell, "pos": pad.cell_to_lane(cell, size), "key": spawn_key(cell, size)})
		else:
			list.append({"id": id, "cell": MusterPad.NONE, "pos": pad.spawn_center, "key": 1.0e9})
	pad.free()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["key"]) < float(b["key"]))
	for e in list:
		e.erase("key")
	_start_wave(list)


func _start_wave(list: Array[Dictionary]) -> void:
	if formation != null and not formation.is_released() and formation.state == WaveFormation.State.MUSTER:
		formation.start_march()   # the last horn's wave was still mustering (cannot happen at 40 s horns)
	formation = WaveFormation.new(seat, _horn, rules)
	formations.append(formation)
	_queue.append_array(list)
	_hold_left = -1.0


func pending() -> int:
	return _queue.size()


## The card's upgrades at the last horn: {"mask": bought slots (1 = A, 2 = B), "arm": Armoury stats}. Before any horn
## (tests, lab spawns) the roster's live state.
func upgrades_for(id: StringName) -> Dictionary:
	if _ups.has(id):
		return _ups[id]
	var r := _get_roster()
	if r == null:
		return {}
	return _card_ups(r, id)


func _get_roster() -> MusterRoster:
	if _roster == null and is_inside_tree():
		_roster = MusterRoster.for_seat(get_tree(), seat)
	return _roster


static func _card_ups(r: MusterRoster, id: StringName) -> Dictionary:
	var mask := 0
	for slot in 2:
		if r.has_upgrade(id, slot):
			mask |= 1 << slot
	return {"mask": mask, "arm": r.armoury_mods(id)}


func _snapshot_upgrades(r: MusterRoster) -> void:
	_ups.clear()
	if r == null:
		return
	for id in r.card_ids():
		_ups[id] = _card_ups(r, id)


## Save (review W3-4): the copies of a horn still waiting, the upgrades snapshot. Formations are not saved: a load
## releases every marching wave (15.3 step 4).
func save_state() -> Dictionary:
	var q: Array = []
	for e in _queue:
		var cell: Vector2i = e["cell"]
		var p: Vector3 = e["pos"]
		q.append({"id": String(e["id"]), "cell": [cell.x, cell.y], "pos": [p.x, p.y, p.z]})
	var ups := {}
	for id: StringName in _ups:
		ups[String(id)] = {"mask": int(_ups[id]["mask"]), "arm": (_ups[id]["arm"] as Dictionary).duplicate()}
	return {"queue": q, "left": _left, "spawned_total": spawned_total, "horn": _horn, "ups": ups}


func load_state(d: Dictionary) -> void:
	for f in formations:
		f.release("load")
	formations.clear()
	formation = null
	_queue.clear()
	var q: Array = d.get("queue", [])
	var old: Array[StringName] = []
	var list: Array[Dictionary] = []
	for v: Variant in q:
		if v is Dictionary:
			var c: Array = v.get("cell", [-1, -1])
			var p: Array = v.get("pos", [gate.x, gate.y, gate.z])
			list.append({"id": StringName(str(v["id"])), "cell": Vector2i(int(c[0]), int(c[1])),
					"pos": Vector3(float(p[0]), float(p[1]), float(p[2]))})
		else:
			old.append(StringName(str(v)))   # a save from before the pad: ids only
	_horn = int(d.get("horn", _horn))
	_ups.clear()
	var ups: Dictionary = d.get("ups", {})
	for k: Variant in ups:
		_ups[StringName(str(k))] = {"mask": int(ups[k].get("mask", 0)), "arm": (ups[k].get("arm", {}) as Dictionary).duplicate()}
	if not list.is_empty():
		_start_wave(list)
	if not old.is_empty():
		queue_wave(old)
	_left = float(d.get("left", _left))
	spawned_total = int(d.get("spawned_total", spawned_total))


## Advances the spawn clock and the formations (called by the director with its own delta).
func tick(delta: float) -> void:
	if not _queue.is_empty():
		_left -= delta
		while _left <= 0.0 and not _queue.is_empty():
			_left += stagger
			_spawn_one(_queue.pop_front())
		if _queue.is_empty():
			_left = 0.0
			_hold_left = rules.muster_hold_extra if rules else 0.5
	elif _hold_left >= 0.0:
		_hold_left -= delta
		if _hold_left < 0.0 and formation != null:
			formation.start_march()
	if not formations.is_empty():
		for i in range(formations.size() - 1, -1, -1):
			if formations[i].tick(delta):
				formations.remove_at(i)


func _spawn_one(e: Dictionary) -> void:
	var id: StringName = e["id"]
	var pos: Vector3 = e["pos"]
	var side := Vector3(-forward.z, 0.0, forward.x)
	var lat := (pos - gate).dot(side)
	if level == null or not level.has_method(&"spawn_lane_unit"):
		return
	var u: Variant = level.call(&"spawn_lane_unit", seat, id, pos, lat)
	if u == null or not u is Unit:
		return
	spawned_total += 1
	if formation != null:
		formation.add_member(u as Unit, release_effects(id))


## The release effects (wave-strike.md 16.2 `release`) of card `id`'s upgrades at the last horn.
func release_effects(id: StringName) -> Array:
	var up := upgrades_for(id)
	var mask := int(up.get("mask", 0))
	if mask == 0:
		return []
	var r := _get_roster()
	if r == null:
		return []
	var out: Array = []
	for slot in 2:
		if mask & (1 << slot):
			out.append_array(r.upgrade_info(id, slot).get("release", []))
	return out
