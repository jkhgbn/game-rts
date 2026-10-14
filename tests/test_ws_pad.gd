extends SceneTree
## WS3.C1 (docs/design/wave-strike.md 15.5 row test_ws_pad): footprints by radius; place / move / swap / box-move
## refusals; auto-place zones (Line, Spearhead); "No room on the pad"; sell frees the cell; 42 blaze_riders at cap 84
## all fit; save round trip of cells + old-save auto-arrange; seat 0 and seat 1 cell (3, 2) map to rot180 images in the
## lane; buy(id) without a cell still auto-places. Pure systems (MusterRoster + MusterPad on a stub level).
## Prints "PASS ws_pad" or "FAIL ws_pad: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_pad.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "ws_pad"

var _fails: Array[String] = []
var _rules: WaveStrikeRules
var _table: WaveCardTable
var _dir: WaveDirector
var _level: Node


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	_rules = WaveStrikeRules.load_default()
	_table = WaveCardTable.load_default()
	_level = Node.new()
	root.add_child(_level)
	_dir = WaveDirector.new()
	_dir.setup(_rules, _level)
	_level.add_child(_dir)
	_footprints()
	_place_rules()
	_auto_zones()
	_roster_rows()
	_capacity()
	_save_rows()
	_world_mapping()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _roster(kingdom: StringName, seat: int = 0) -> MusterRoster:
	var eco := Economy.new()
	eco.team = Unit.Team.PLAYER
	_level.add_child(eco)
	var bank := WaveBank.new()
	bank.setup(seat, Unit.Team.PLAYER, _rules, eco)
	_level.add_child(bank)
	bank.economy.crystals = 1000000
	var r := MusterRoster.new()
	r.setup(seat, Unit.Team.PLAYER, kingdom, _rules, _table, bank, _dir)
	_level.add_child(r)
	return r


func _pad() -> MusterPad:
	var p := MusterPad.new()
	p.setup(0, _table)
	_level.add_child(p)
	return p


func _footprints() -> void:
	var p := _pad()
	var want := {&"flame_guard": 1, &"scorchling": 1, &"ember_archer": 1, &"blaze_rider": 2, &"gloam_rider": 2,
			&"snowdrift_rider": 2, &"stagrunner": 2, &"bramblehorn": 2, &"shadow_knight": 2, &"barrow_knight": 2,
			&"rimehorn_rider": 2, &"sunforge_cataphract": 2, &"frostcrown_juggernaut": 2, &"briar_roc": 2,
			&"glade_outrider": 2, &"veilborn_dreadrider": 2, &"nightblood_reaver": 1, &"shardguard": 1, &"kilnwarden": 1}
	for id: StringName in want:
		_check(p.footprint(id) == int(want[id]), "footprint %s = %d (want %d)" % [id, p.footprint(id), want[id]])
	# every card of every kingdom: 1x1 below radius 0.6, else 2x2
	for k: StringName in [&"fire", &"ice", &"nature", &"shadow"]:
		for id in _table.cards_of(k):
			var t := UnitType.find(String(id))
			_check(p.footprint(id) == (2 if t.radius >= 0.6 else 1), "footprint rule %s" % id)


func _place_rules() -> void:
	var p := _pad()
	_check(p.place(&"flame_guard", Vector2i(0, 0)) == "", "place 1x1 at (0,0)")
	_check(p.place(&"flame_guard", Vector2i(0, 0)) == MusterPad.REASON_TAKEN, "place on a taken cell")
	_check(p.place(&"flame_guard", Vector2i(16, 0)) == MusterPad.REASON_OFF, "place off the pad (col 16)")
	_check(p.place(&"blaze_rider", Vector2i(15, 3)) == MusterPad.REASON_OFF, "2x2 hanging off the right edge")
	_check(p.place(&"blaze_rider", Vector2i(14, 11)) == MusterPad.REASON_OFF, "2x2 hanging off the back edge")
	_check(p.place(&"blaze_rider", Vector2i(1, 0)) == "", "2x2 at (1,0)")
	_check(p.copy_at(Vector2i(2, 1)).get("cell", MusterPad.NONE) == Vector2i(1, 0), "copy_at a 2x2's back-right cell")
	_check(p.place(&"ember_archer", Vector2i(2, 1)) == MusterPad.REASON_TAKEN, "1x1 onto a 2x2 cell")
	_check(p.cells_of(&"blaze_rider").size() == 1 and p.cells_of(&"blaze_rider")[0] == Vector2i(1, 0), "cells_of blaze_rider")
	# move
	_check(p.move(Vector2i(0, 0), Vector2i(1, 1)) == MusterPad.REASON_TAKEN, "move onto a 2x2")
	_check(p.move(Vector2i(5, 5), Vector2i(6, 6)) == MusterPad.REASON_EMPTY, "move an empty cell")
	_check(p.move(Vector2i(2, 1), Vector2i(2, 0)) == "", "a 2x2 moves one cell right over its own cells")
	_check(p.copy_at(Vector2i(1, 0)).is_empty() and p.copy_at(Vector2i(3, 1)).get("id") == &"blaze_rider",
			"2x2 moved: old cell free, new cell covered")
	_check(p.move(Vector2i(0, 0), Vector2i(0, 5)) == "" and p.copy_at(Vector2i(0, 0)).is_empty(), "1x1 move")
	# swap
	p.place(&"ember_archer", Vector2i(8, 8))
	_check(p.swap(Vector2i(0, 5), Vector2i(8, 8)) == "", "swap two 1x1")
	_check(p.copy_at(Vector2i(0, 5)).get("id") == &"ember_archer" and p.copy_at(Vector2i(8, 8)).get("id") == &"flame_guard",
			"swap result")
	_check(p.swap(Vector2i(0, 5), Vector2i(2, 0)) == MusterPad.REASON_SIZE, "swap 1x1 with 2x2 refused")
	# box move: the group keeps its shape, refused when any copy lands blocked or off the pad
	var group: Array = [Vector2i(0, 5), Vector2i(8, 8)]
	_check(p.move_group(group, Vector2i(0, 4)) == MusterPad.REASON_OFF, "box move off the back edge (row 12)")
	_check(p.move_group(group, Vector2i(2, -5)) == MusterPad.REASON_TAKEN, "box move onto the 2x2 (2,0)")
	_check(p.copy_at(Vector2i(0, 5)).get("id") == &"ember_archer", "refused box move moved nothing")
	_check(p.move_group(group, Vector2i(1, 1)) == "", "box move +1,+1")
	_check(p.copy_at(Vector2i(1, 6)).get("id") == &"ember_archer" and p.copy_at(Vector2i(9, 9)).get("id") == &"flame_guard",
			"box move result")
	# a group moving onto its own former cells is fine
	p.place(&"flame_guard", Vector2i(2, 6))
	_check(p.move_group([Vector2i(1, 6), Vector2i(2, 6)], Vector2i(1, 0)) == "", "box move over its own cells")


func _auto_zones() -> void:
	# Line (15.4): melee front row centre, ranged rows 4-7, riders on the wings, heavy rows 0-1 cols 4-11, casters 9-11
	var p := _pad()
	_check(p.auto_cell(&"flame_guard", &"line") == Vector2i(7, 0), "line melee -> (7,0): %s" % p.auto_cell(&"flame_guard", &"line"))
	_check(p.auto_cell(&"ember_archer", &"line") == Vector2i(7, 4), "line ranged -> (7,4): %s" % p.auto_cell(&"ember_archer", &"line"))
	var rc := p.auto_cell(&"blaze_rider", &"line")
	_check(rc.y == 0 and (rc.x <= 2 or rc.x >= 12), "line rider on a wing: %s" % rc)
	var hc := p.auto_cell(&"shadow_knight", &"line")
	_check(hc.y == 0 and hc.x >= 4 and hc.x + 1 <= 11, "line heavy rows 0-1 cols 4-11: %s" % hc)
	var cc := p.auto_cell(&"kilnwarden", &"line")
	_check(cc.y == 9 and cc.x >= 5 and cc.x <= 10, "line caster rows 9-11: %s" % cc)
	var sc := p.auto_cell(&"rime_seer", &"line")
	_check(sc.y == 7 and sc.x >= 5 and sc.x <= 10, "line support rows 7-9: %s" % sc)
	# Spearhead: melee rows 2-5 cols 2-13, ranged rows 5-8, riders rows 0-3 beside the point
	_check(p.auto_cell(&"flame_guard", &"spearhead") == Vector2i(7, 2), "spearhead melee -> (7,2): %s" % p.auto_cell(&"flame_guard", &"spearhead"))
	_check(p.auto_cell(&"ember_archer", &"spearhead").y == 5, "spearhead ranged row 5")
	var sr := p.auto_cell(&"blaze_rider", &"spearhead")
	_check(sr.y == 0 and ((sr.x >= 1 and sr.x + 1 <= 4) or (sr.x >= 11 and sr.x + 1 <= 14)), "spearhead rider: %s" % sr)
	# filling: front row centre outward (7, 8, 6, 9 ...), then the next row
	var seen: Array[Vector2i] = []
	for i in 17:
		var c := p.auto_cell(&"flame_guard", &"line")
		p.place(&"flame_guard", c)
		seen.append(c)
	_check(seen[0] == Vector2i(7, 0) and seen[1] == Vector2i(8, 0) and seen[2] == Vector2i(6, 0) and seen[3] == Vector2i(9, 0),
			"centre outward: %s" % [seen.slice(0, 4)])
	_check(seen[15].y == 0 and seen[16] == Vector2i(7, 1), "row 0 full then row 1: %s %s" % [seen[15], seen[16]])
	# auto_arrange: deterministic, every copy on the pad, front roles in front
	var q := _pad()
	for id: StringName in [&"ember_archer", &"ember_archer", &"kilnwarden", &"flame_guard", &"blaze_rider", &"flame_guard"]:
		q.place(id, q.auto_cell(id, &"spearhead"))
	q.auto_arrange(&"line")
	_check(q.copy_count() == 6, "auto_arrange keeps 6 copies (%d)" % q.copy_count())
	_check(q.copy_at(Vector2i(7, 0)).get("id") == &"flame_guard", "auto_arrange line: melee at (7,0)")
	_check(q.cells_of(&"ember_archer").all(func(c: Vector2i) -> bool: return c.y == 4), "auto_arrange line: archers row 4")
	var snap := q.save_cells()
	q.auto_arrange(&"line")
	_check(q.save_cells() == snap, "auto_arrange is deterministic")


func _roster_rows() -> void:
	var r := _roster(&"fire")
	# buy(id) without a cell auto-places (the WaveBot path)
	_check(r.buy(&"flame_guard") == "" and r.pad.copy_count() == 1 and r.pad.copy_at(Vector2i(7, 0)).get("id") == &"flame_guard",
			"buy(id) auto-places at (7,0)")
	# buy at a cell
	_check(r.buy(&"ember_archer", Vector2i(3, 10)) == "" and r.pad.copy_at(Vector2i(3, 10)).get("id") == &"ember_archer",
			"buy at (3,10)")
	var crystals := r.bank.crystals()
	_check(r.buy(&"ember_archer", Vector2i(3, 10)) == MusterPad.REASON_TAKEN and r.bank.crystals() == crystals,
			"buy on a taken cell refused, nothing paid")
	_check(r.buy(&"blaze_rider", Vector2i(15, 0)) == MusterPad.REASON_OFF, "buy off the pad refused")
	# sell_at frees the cell
	_check(r.sell_at(Vector2i(3, 10)) == "" and r.pad.copy_at(Vector2i(3, 10)).is_empty() and r.count(&"ember_archer") == 0,
			"sell_at frees the cell")
	_check(r.sell_at(Vector2i(3, 10)) == MusterRoster.REASON_NONE, "sell_at an empty cell")
	# sell(id) takes the back-most copy
	r.buy(&"flame_guard", Vector2i(2, 9))
	r.sell(&"flame_guard")
	_check(r.pad.copy_at(Vector2i(2, 9)).is_empty() and r.pad.copy_at(Vector2i(7, 0)).get("id") == &"flame_guard",
			"sell(id) sells the back-most copy")
	_check(r.pad.copy_count() == r.card_total(), "pad copies = roster copies")
	# "No room on the pad": after Supply full, before Not enough crystals
	var full := _roster(&"fire", 1)
	full.tier = 3
	for row in MusterPad.ROWS:
		for col in MusterPad.COLS:
			full.pad.place(&"scorchling", Vector2i(col, row))
	_check(full.can_buy(&"flame_guard") == "No room on the pad", "full pad: '%s'" % full.can_buy(&"flame_guard"))
	full.bank.economy.crystals = 0
	_check(full.can_buy(&"flame_guard") == "No room on the pad", "No room comes before Not enough crystals")


func _capacity() -> void:
	var r := _roster(&"fire", 2)
	r.tier = 3
	var ok := 0
	for i in 42:
		if r.buy(&"blaze_rider") == "":
			ok += 1
	_check(ok == 42, "42 blaze_riders at cap 84 fit (%d)" % ok)
	_check(r.pop_used() == 84 and r.pad.copy_count() == 42, "pop 84 / 42 copies on the pad")
	_check(r.can_buy(&"flame_guard").begins_with("Supply full"), "43rd: %s" % r.can_buy(&"flame_guard"))
	for s: StringName in [&"line", &"spearhead"]:
		r.pad.auto_arrange(s)
		_check(r.pad.copy_count() == 42, "42 riders after auto_arrange %s (%d)" % [s, r.pad.copy_count()])


func _save_rows() -> void:
	var r := _roster(&"fire", 3)
	r.tier = 2
	r.buy(&"flame_guard", Vector2i(0, 0))
	r.buy(&"flame_guard", Vector2i(15, 11))
	r.buy(&"blaze_rider", Vector2i(6, 6))
	r.buy(&"kilnwarden")
	var d: Dictionary = JSON.parse_string(JSON.stringify(r.save_state()))
	var r2 := _roster(&"fire", 4)
	r2.load_state(d)
	_check(r2.pad.save_cells() == r.pad.save_cells() or _same_cells(r2.pad, r.pad), "cells round trip: %s vs %s" % [
			r2.pad.save_cells(), r.pad.save_cells()])
	_check(r2.pad.copy_at(Vector2i(15, 11)).get("id") == &"flame_guard" and r2.pad.copy_at(Vector2i(7, 7)).get("id") == &"blaze_rider",
			"loaded copies on their cells")
	# an older save without cells: auto-arranged in Line
	d.erase("cells")
	var r3 := _roster(&"fire", 5)
	r3.load_state(d)
	_check(r3.pad.copy_count() == 4, "old save: 4 copies on the pad (%d)" % r3.pad.copy_count())
	_check(r3.pad.copy_at(Vector2i(7, 0)).get("id") == &"flame_guard", "old save: Line arrangement (melee at (7,0))")


func _same_cells(a: MusterPad, b: MusterPad) -> bool:
	for c in b.copies():
		if a.copy_at(c["cell"]).get("id") != c["id"] or a.copy_at(c["cell"]).get("cell") != c["cell"]:
			return false
	return a.copy_count() == b.copy_count()


func _world_mapping() -> void:
	var p0 := _pad()
	p0.set_frame_from_gate(Vector3(-71, 0, 0), Vector3.RIGHT)
	var p1 := _pad()
	p1.set_frame_from_gate(Vector3(71, 0, 0), Vector3.LEFT)
	var a := p0.cell_to_lane(Vector2i(3, 2))
	var b := p1.cell_to_lane(Vector2i(3, 2))
	_check(a.is_equal_approx(-b), "seat 0 / seat 1 cell (3,2) rot180: %s vs %s" % [a, b])
	_check(a.is_equal_approx(Vector3(-62.75, 0, -6.75)), "seat 0 cell (3,2) -> %s (want (-62.75, 0, -6.75))" % a)
	_check(p0.pad_center.is_equal_approx(Vector3(-68, 0, -33)), "seat 0 pad centre %s" % p0.pad_center)
	_check(p1.pad_center.is_equal_approx(Vector3(68, 0, 33)), "seat 1 pad centre %s" % p1.pad_center)
	# the spawn box corners (15.1): x -77..-59, z -12..12
	var front_left := p0.cell_to_lane(Vector2i(0, 0)) + Vector3(0.75, 0, -0.75)
	var back_right := p0.cell_to_lane(Vector2i(15, 11)) + Vector3(-0.75, 0, 0.75)
	_check(front_left.is_equal_approx(Vector3(-59, 0, -12)) and back_right.is_equal_approx(Vector3(-77, 0, 12)),
			"spawn box corners %s %s" % [front_left, back_right])
	# pad <-> cell round trip, 2x2 centre
	_check(p0.pad_to_cell(p0.cell_to_pad(Vector2i(3, 2))) == Vector2i(3, 2), "pad_to_cell round trip")
	_check(p0.pad_to_cell(Vector3(0, 0, 0)) == MusterPad.NONE, "pad_to_cell off the pad")
	var c2 := p0.cell_to_lane(Vector2i(0, 0), 2)
	_check(c2.is_equal_approx(Vector3(-71 + 12 - 1.5, 0, -12 + 1.5)), "2x2 centre %s" % c2)
	# the shipped map: the layout's muster slots (WS3.M1) agree with the fallback geometry when present
	var lay := LayoutLevel.load_layout("res://data/maps/ashwind_reach_layout.tres")
	if lay != null:
		for s: Dictionary in lay.spots_of("slot"):
			if str(s.get("sub", "")) == "muster_pad" and (s["pos"] as Vector3).x < 0.0:
				_check((s["pos"] as Vector3).is_equal_approx(p0.pad_center), "layout muster_pad %s = fallback" % s["pos"])
