class_name MusterPad
extends Node
## One Wave Strike seat's Muster Pad (docs/design/wave-strike.md 15): a 16 x 12 board of 1.5 m cells; every copy the
## roster owns sits on its own cell (1x1) or 2x2 block, anchored at its front-left cell. Row 0 = the front (toward the
## enemy), column 0 = the left wing seen from behind. The pad is a 1:1 copy of the spawn box in front of the gate
## (`cell_to_lane`). The roster (MusterRoster) owns one as its child `pad`; buys / sells keep the two in step.
## Placement API returns "" = ok, else the reason (English, shown through Loc.sink).

signal changed

const COLS := 16
const ROWS := 12
const CELL := 1.5
const NONE := Vector2i(-1, -1)
## Spawn box: front edge 12 m ahead of the gate, back edge 6 m behind (15.1). Its centre is 3 m ahead of the gate.
const SPAWN_AHEAD := 3.0
const PAD_LEFT := 33.0             ## m from the spawn box centre to the pad centre, to the left (15.1 fallback)

const REASON_OFF := "Off the pad"
const REASON_TAKEN := "Spot taken"
const REASON_NO_ROOM := "No room on the pad"
const REASON_EMPTY := "No unit there"
const REASON_SIZE := "Swap needs the same size"
const REASON_UNKNOWN := "Unknown card"

const STYLES: Array[StringName] = [&"line", &"spearhead"]
## Auto-formation zones (15.4): role -> [row_from, row_to, [[col_from, col_to], ...]]. Empty column list = all.
const ZONES := {
	&"line": {
		&"heavy": [0, 1, [[4, 11]]],
		&"melee": [0, 3, []],
		&"rider": [0, 5, [[0, 3], [12, 15]]],
		&"ranged": [4, 7, []],
		&"support": [7, 9, [[5, 10]]],
		&"caster": [9, 11, [[5, 10]]],
	},
	&"spearhead": {
		&"heavy": [0, 1, [[5, 10]]],
		&"melee": [2, 5, [[2, 13]]],
		&"rider": [0, 3, [[1, 4], [11, 14]]],
		&"ranged": [5, 8, []],
		&"support": [8, 10, [[5, 10]]],
		&"caster": [9, 11, [[5, 10]]],
	},
}
## auto_arrange order: front roles claim their zones first.
const ROLE_ORDER: Array[StringName] = [&"heavy", &"melee", &"rider", &"ranged", &"support", &"caster"]

var seat := 0
var table: WaveCardTable
## World frame (set by the level; tests may leave the default): spawn box centre, pad centre, walking direction.
var spawn_center := Vector3.ZERO
var pad_center := Vector3(0.0, 0.0, -PAD_LEFT)
var forward := Vector3.RIGHT

var _copies: Array[Dictionary] = []   ## [{id: StringName, cell: Vector2i}] (anchor = front-left cell)
var _occ: Dictionary = {}             ## Vector2i cell -> index in _copies
var _aligned := false                 ## auto_arrange retry: 2x2 anchors on even cells only (no fragmentation)


func setup(p_seat: int, p_table: WaveCardTable) -> void:
	seat = p_seat
	table = p_table
	name = "MusterPad"


## The pad's world frame. `p_forward` = the lane direction at the gate (flattened).
func set_frame(p_spawn_center: Vector3, p_pad_center: Vector3, p_forward: Vector3) -> void:
	spawn_center = p_spawn_center
	pad_center = p_pad_center
	var f := Vector3(p_forward.x, 0.0, p_forward.z)
	forward = f.normalized() if f.length_squared() > 0.0001 else Vector3.RIGHT


## The 15.1 fallback frame from the gate alone: spawn centre 3 m ahead, pad 33 m to the left of it.
func set_frame_from_gate(gate: Vector3, p_forward: Vector3) -> void:
	var f := Vector3(p_forward.x, 0.0, p_forward.z).normalized()
	var spawn := gate + f * SPAWN_AHEAD
	set_frame(spawn, spawn + Vector3.UP.cross(f) * PAD_LEFT, f)


# ---------------------------------------------------------------- cards

## 1 (1x1) or 2 (2x2): WaveCardTable.footprint, else UnitType.radius < 0.6 -> 1.
func footprint(id: StringName) -> int:
	if table != null:
		return table.footprint_of(id)
	var t := UnitType.find(String(id))
	return 2 if t != null and t.radius >= 0.6 else 1


func copy_count() -> int:
	return _copies.size()


## Anchor cells of card `id`'s copies (placement order).
func cells_of(id: StringName) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in _copies:
		if StringName(c["id"]) == id:
			out.append(c["cell"])
	return out


## The copy covering `cell`: {id, cell (anchor), size}, or {} when the cell is empty / off the pad.
func copy_at(cell: Vector2i) -> Dictionary:
	if not _occ.has(cell):
		return {}
	var c: Dictionary = _copies[int(_occ[cell])]
	return {"id": c["id"], "cell": c["cell"], "size": footprint(StringName(c["id"]))}


## Every copy: [{id, cell, size}] (a copy).
func copies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in _copies:
		out.append({"id": c["id"], "cell": c["cell"], "size": footprint(StringName(c["id"]))})
	return out


# ---------------------------------------------------------------- placing

static func in_bounds(cell: Vector2i, size: int = 1) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x + size <= COLS and cell.y + size <= ROWS


## "" = a copy of `id` fits with its anchor at `cell` (cells covered by the copies at indices `ignore` count as free).
func can_place(id: StringName, cell: Vector2i, ignore: Array = []) -> String:
	if UnitType.find(String(id)) == null:
		return REASON_UNKNOWN
	return _can_fit(footprint(id), cell, ignore)


func _can_fit(size: int, cell: Vector2i, ignore: Array = []) -> String:
	if not in_bounds(cell, size):
		return REASON_OFF
	for dx in size:
		for dy in size:
			var k := cell + Vector2i(dx, dy)
			if _occ.has(k) and not ignore.has(int(_occ[k])):
				return REASON_TAKEN
	return ""


## Adds a copy of `id` at `cell` (the roster calls it on a buy; the pad itself never spends).
func place(id: StringName, cell: Vector2i) -> String:
	var why := can_place(id, cell)
	if why != "":
		return why
	_copies.append({"id": id, "cell": cell})
	_rebuild_occ()
	changed.emit()
	return ""


## Moves the copy covering `from` so its anchor is `to`.
func move(from: Vector2i, to: Vector2i) -> String:
	if not _occ.has(from):
		return REASON_EMPTY
	var i := int(_occ[from])
	var why := _can_fit(footprint(StringName(_copies[i]["id"])), to, [i])
	if why != "":
		return why
	_copies[i]["cell"] = to
	_rebuild_occ()
	changed.emit()
	return ""


## Swaps the copies covering `a` and `b` (same footprint only).
func swap(a: Vector2i, b: Vector2i) -> String:
	if not _occ.has(a) or not _occ.has(b):
		return REASON_EMPTY
	var i := int(_occ[a])
	var j := int(_occ[b])
	if i == j:
		return ""
	if footprint(StringName(_copies[i]["id"])) != footprint(StringName(_copies[j]["id"])):
		return REASON_SIZE
	var ci: Vector2i = _copies[i]["cell"]
	_copies[i]["cell"] = _copies[j]["cell"]
	_copies[j]["cell"] = ci
	_rebuild_occ()
	changed.emit()
	return ""


## Moves every copy covering one of `cells` by `delta` keeping the shape; refused (nothing moves) if any lands off the
## pad or on a copy outside the group.
func move_group(cells: Array, delta: Vector2i) -> String:
	var group: Array = []
	for c: Variant in cells:
		var k := c as Vector2i
		if _occ.has(k) and not group.has(int(_occ[k])):
			group.append(int(_occ[k]))
	if group.is_empty():
		return REASON_EMPTY
	for i: int in group:
		var why := _can_fit(footprint(StringName(_copies[i]["id"])), (_copies[i]["cell"] as Vector2i) + delta, group)
		if why != "":
			return why
	for i: int in group:
		_copies[i]["cell"] = (_copies[i]["cell"] as Vector2i) + delta
	_rebuild_occ()
	changed.emit()
	return ""


## Removes the copy covering `cell`; returns its card id (&"" = none).
func remove_at(cell: Vector2i) -> StringName:
	if not _occ.has(cell):
		return &""
	var i := int(_occ[cell])
	var id := StringName(_copies[i]["id"])
	_copies.remove_at(i)
	_rebuild_occ()
	changed.emit()
	return id


## The anchor of `id`'s back-most copy (highest row, then the outermost, then the last placed); NONE = no copy.
func back_most(id: StringName) -> Vector2i:
	var best := NONE
	var best_key := -INF
	for c in _copies:
		if StringName(c["id"]) != id:
			continue
		var cell: Vector2i = c["cell"]
		var key := cell.y * 100.0 + absf(cell.x + footprint(id) * 0.5 - COLS * 0.5)
		if key >= best_key:
			best_key = key
			best = cell
	return best


func clear() -> void:
	_copies.clear()
	_occ.clear()
	changed.emit()


func _rebuild_occ() -> void:
	_occ.clear()
	for i in _copies.size():
		var cell: Vector2i = _copies[i]["cell"]
		var s := footprint(StringName(_copies[i]["id"]))
		for dx in s:
			for dy in s:
				_occ[cell + Vector2i(dx, dy)] = i


# ---------------------------------------------------------------- auto formations (15.4)

## The best free anchor for a new copy of `id` in `style` (&"line" / &"spearhead"); NONE = no room anywhere.
func auto_cell(id: StringName, style: StringName = &"line") -> Vector2i:
	var size := footprint(id)
	var zones: Dictionary = ZONES.get(style, ZONES[&"line"])
	var z: Array = zones.get(_role(id), zones[&"melee"])
	var r0 := int(z[0])
	var r1 := int(z[1])
	var spans: Array = z[2]
	if spans.is_empty():
		spans = [[0, COLS - 1]]
	# the zone, then behind it in the same columns, then anywhere (front first, block-aligned first for 2x2)
	var cell := _scan(size, r0, r1, spans, _aligned)
	if cell == NONE:
		cell = _scan(size, r1 + 1, ROWS - 1, spans, _aligned)
	if cell == NONE:
		cell = _scan(size, 0, ROWS - 1, [[0, COLS - 1]], true)
	if cell == NONE and size > 1 and not _aligned:
		cell = _scan_any(size)
	return cell


## Rows r0..r1 front first; inside a row the anchors in `spans` from the pad centre outward (left first on a tie).
func _scan(size: int, r0: int, r1: int, spans: Array, aligned: bool) -> Vector2i:
	var cols: Array[int] = []
	for s: Variant in spans:
		var a := int(s[0])
		var b := int(s[1])
		var c := a
		if aligned and size > 1 and c % size != 0:
			c += size - c % size
		while c + size - 1 <= b:
			cols.append(c)
			c += size
	cols.sort_custom(func(x: int, y: int) -> bool:
		var dx := absf(x + size * 0.5 - COLS * 0.5)
		var dy := absf(y + size * 0.5 - COLS * 0.5)
		return dx < dy if dx != dy else x < y)
	var r := r0
	if aligned and size > 1 and r % size != 0:
		r += size - r % size
	while r + size - 1 <= r1 and r + size - 1 < ROWS:
		for c in cols:
			if _can_fit(size, Vector2i(c, r)) == "":
				return Vector2i(c, r)
		r += 1 if not aligned else size
	return NONE


func _scan_any(size: int) -> Vector2i:
	for r in ROWS - size + 1:
		for c in COLS - size + 1:
			if _can_fit(size, Vector2i(c, r)) == "":
				return Vector2i(c, r)
	return NONE


## Re-places every copy by `style`'s zones (front roles first, 2x2 before 1x1, then card order). A copy that finds no
## spot (cannot happen while the supply cap binds before the pad, 15.1) is dropped from the pad with a warning.
func auto_arrange(style: StringName = &"line") -> void:
	var ids: Array[StringName] = []
	for c in _copies:
		ids.append(StringName(c["id"]))
	_place_all(ids, style)
	changed.emit()


## Clears the pad and auto-places `ids` (one entry per copy) in `style`.
func _place_all(ids: Array[StringName], style: StringName) -> void:
	var order := ids.duplicate()
	var first: Dictionary = {}
	for i in order.size():
		if not first.has(order[i]):
			first[order[i]] = i
	order.sort_custom(func(a: StringName, b: StringName) -> bool:
		var ra := ROLE_ORDER.find(_role(a))
		var rb := ROLE_ORDER.find(_role(b))
		if ra != rb:
			return ra < rb
		var fa := footprint(a)
		var fb := footprint(b)
		if fa != fb:
			return fa > fb   # 2x2 first inside a role: they need the aligned blocks
		return int(first[a]) < int(first[b]))
	# the zone shapes first; if odd zone edges fragment the pad (many 2x2 copies), again with 2x2 blocks on even cells
	for aligned: bool in [false, true]:
		_aligned = aligned
		_copies.clear()
		_occ.clear()
		var dropped: Array[StringName] = []
		for id in order:
			var cell := auto_cell(id, style)
			if cell == NONE:
				dropped.append(id)
				continue
			_copies.append({"id": id, "cell": cell})
			_rebuild_occ()
		_aligned = false
		if dropped.is_empty():
			return
		if aligned:
			push_warning("MusterPad: no room for %s" % [dropped])


func _role(id: StringName) -> StringName:
	return table.role_of(id) if table != null else &"melee"


# ---------------------------------------------------------------- world mapping (15.1)

func right() -> Vector3:
	return forward.cross(Vector3.UP)


## Lateral (+ = right) and forward (from the gate) offset of a copy anchored at `cell` with footprint `size`.
static func lane_offset(cell: Vector2i, size: int) -> Vector2:
	return Vector2((cell.x + size * 0.5 - COLS * 0.5) * CELL, 12.0 - (cell.y + size * 0.5) * CELL)


## World position in the spawn box of a copy anchored at `cell` (centre of its footprint).
func cell_to_lane(cell: Vector2i, size: int = 1) -> Vector3:
	var o := lane_offset(cell, size)
	return spawn_center + forward * (o.y - SPAWN_AHEAD) + right() * o.x


## World position on the pad plate of a copy anchored at `cell`.
func cell_to_pad(cell: Vector2i, size: int = 1) -> Vector3:
	return cell_to_lane(cell, size) - spawn_center + pad_center


## The pad cell under world point `p` (a ray-plane hit); NONE = off the pad.
func pad_to_cell(p: Vector3) -> Vector2i:
	var d := p - pad_center
	var lat := d.dot(right())
	var fwd := d.dot(forward)
	var c := int(floorf(lat / CELL + COLS * 0.5))
	var r := int(floorf((ROWS * CELL * 0.5 - fwd) / CELL))
	var cell := Vector2i(c, r)
	return cell if in_bounds(cell) else NONE


# ---------------------------------------------------------------- save / load (15.5)

## {id: [[c, r], ...]} (one per copy, JSON-safe).
func save_cells() -> Dictionary:
	var out := {}
	for c in _copies:
		var id := String(c["id"])
		if not out.has(id):
			out[id] = []
		var cell: Vector2i = c["cell"]
		(out[id] as Array).append([cell.x, cell.y])
	return out


## Restores saved cells for exactly `counts` (id -> copies): saved spots that still fit are kept, the rest (and every
## copy of an old save without cells) are auto-placed in `style`.
func load_cells(saved: Variant, counts: Dictionary, style: StringName = &"line") -> void:
	_copies.clear()
	_occ.clear()
	var left := {}
	for k: Variant in counts:
		left[StringName(str(k))] = int(counts[k])
	var rest: Array[StringName] = []
	if saved is Dictionary:
		for k: Variant in saved:
			var id := StringName(str(k))
			for v: Variant in saved[k]:
				if int(left.get(id, 0)) <= 0:
					break
				var cell := Vector2i(int(v[0]), int(v[1]))
				if can_place(id, cell) == "":
					_copies.append({"id": id, "cell": cell})
					_rebuild_occ()
					left[id] = int(left[id]) - 1
	for id: StringName in left:
		for i in int(left[id]):
			rest.append(id)
	if not saved is Dictionary or (saved as Dictionary).is_empty():
		_place_all(rest, style)
	else:
		for id in rest:
			var cell := auto_cell(id, style)
			if cell != NONE:
				_copies.append({"id": id, "cell": cell})
				_rebuild_occ()
	changed.emit()
