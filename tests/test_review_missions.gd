extends SceneTree
## Regression checks for the mission findings of docs/reviews/review-2026-10-08.md (missions m00-m04, e2m1-e2m5,
## e3m1-e3m4), scripted through MissionHarness. Parts:
##   m00     a 3rd brazier lit during a pending defeat (dawn reached) stays a defeat (no forced dawn victory).
##   m02     the Heartfrost melting during a pending defeat plays no E10 film; the defeat stands.
##   e2m1    the hold ends, then a defeat comes in the 4 s before the Ysolde film: no film (L27), defeat.
##   e2m2v   the Heartwood keep lost after E14 while other ALLY buildings stand = E24 defeat (no Vice soft-lock).
##   e2m2s   every seed-carrier dead before the groves: a new carrier comes 60 s later (the seed never runs out).
##   e2m3    a robbed (short) tribute is refused, a full one counts and closes obj_bazaar.
##   e3m2    a wagon spoiled during a pending defeat changes nothing (no dawn switch).
##   e3m3    the Heart of the Hollow is refused while the mission is ending.
## Run: godot --headless --path . -s tests/test_review_missions.gd --fixed-fps 60 --quit-after 60000 [-- --only=m00|...]

const TASK_ID := "review_missions"
const GAP_FRAMES := 3
const SCENES := {
	"m00": "res://missions/mission_00.tscn",
	"m02": "res://missions/mission_02.tscn",
	"e2m1": "res://missions/mission_e2_01.tscn",
	"e2m2v": "res://missions/mission_e2_02.tscn",
	"e2m2s": "res://missions/mission_e2_02.tscn",
	"e2m3": "res://missions/mission_e2_03.tscn",
	"e3m2": "res://missions/mission_e3_02.tscn",
	"e3m3": "res://missions/mission_e3_03.tscn",
}

var _parts: Array[String] = ["m00", "m02", "e2m1", "e2m2v", "e2m2s", "e2m3", "e3m2", "e3m3"]
var _part := ""
var h: MissionHarness
var main: Node
var _errors: Array[String] = []
var _v := {}
var _gap := 0
var _finished := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_parts = [a.trim_prefix("--only=")]
	_open_next()


func _process(_delta: float) -> bool:
	if _finished:
		return true
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_open_next()
		return _finished
	if h == null or main == null:
		return _finished
	if h.tick():
		for e in h.errors:
			_errors.append("%s: %s" % [_part, e])
		main.queue_free()
		main = null
		h = null
		_gap = GAP_FRAMES
	return _finished


func _open_next() -> void:
	if _parts.is_empty():
		_finished = true
		print("PASS %s" % TASK_ID if _errors.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return
	_part = _parts.pop_front()
	_v = {}
	h = MissionHarness.new()
	h.task_id = "%s/%s" % [TASK_ID, _part]
	h.timeout_frames = 20000
	main = h.open(self, SCENES[_part], {"difficulty": 1,
			"set": {"campaign_save_path": "user://test_review_missions_none.json"}})
	match _part:
		"m00":
			h.steps.add("pending defeat + 3rd brazier = defeat", _m00, 600)
		"m02":
			h.steps.add("pending defeat + Heartfrost melt = defeat", _m02, 600)
		"e2m1":
			h.steps.add("hold done, then a defeat: no Ysolde film", _e2m1, 900)
		"e2m2v":
			h.steps.add("Heartwood lost after E14 = defeat", _e2m2_heartwood, 900)
		"e2m2s":
			h.steps.add("no carrier left: a new one comes", _e2m2_seed, 900)
		"e2m3":
			h.steps.add("short tribute refused, full one counts", _e2m3, 60)
		"e3m2":
			h.steps.add("pending defeat + spoiled wagon = nothing", _e3m2, 600)
		"e3m3":
			h.steps.add("no Heart while ending", _e3m3, 60)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


# ---------------------------------------------------------------- defeat vs victory races

func _m00() -> bool:
	var m := main as Mission00
	if not _v.has("go"):
		_v["go"] = true
		m.dawn_reached = true
		m.lit_count = 2
		m.lose(3.0)   # the keep-lost / Vessa-fell defeat, pending
		m._on_brazier_lit(m.braziers[2])
		_ok(not m.has_fired(&"E10"), "no dawn (E10) over the pending defeat")
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0, "the defeat stands (ended %d)" % h.ended)
	return true


func _m02() -> bool:
	var m := main as Mission02
	if not _v.has("go"):
		_v["go"] = true
		m.lose(3.0)
		m._on_heartfrost_melted(null)
		_ok(not m.has_fired(&"E10"), "no Heartfrost film (E10) over the pending defeat")
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0, "the defeat stands (ended %d)" % h.ended)
	return true


func _e2m1() -> bool:
	var m := main as MissionE2_01
	if not _v.has("go"):
		_v["go"] = true
		m._e20_hold_done()
		m.lose(6.0)   # lands after the 4 s film delay
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0, "the defeat stands (ended %d)" % h.ended)
	_ok(not m.said.has(27), "no Ysolde film lines (L27) over the pending defeat")
	return true


func _e3m2() -> bool:
	var m := main as MissionE3_02
	if not _v.has("go"):
		_v["go"] = true
		m.lose(3.0)
		var id: StringName = m.wagons.keys()[0]
		m._spoil(id, true)
		_ok(m.wagons_spoiled() == 0 and m.phase == 1, "no spoil over the pending defeat")
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0, "the defeat stands (ended %d)" % h.ended)
	return true


func _e3m3() -> bool:
	var m := main as MissionE3_03
	m.heart_enabled = true
	m.win(2.0)
	_ok(m.use_heart() == MissionE3_03.REFUSE_ENDING, "Heart refused while ending")
	_ok(m.shard_uses == 0, "no shard use recorded")
	return true


# ---------------------------------------------------------------- e2m2 soft-locks

func _e2m2_heartwood() -> bool:
	var m := main as MissionE2_02
	if not _v.has("p"):
		_v["p"] = true
		for id: StringName in [&"A", &"B", &"C"]:
			m._plant(id, [])
		return false
	if m.ally_active and not _v.has("k"):
		_v["k"] = true
		m.heartwood.take_damage(1.0e7, null)   # only the keep: the Grove Hall and Hollows still stand
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0, "defeat (ended %d)" % h.ended)
	_ok(m.has_fired(&"E24") and h.saw("obj_ally", "failed"), "E24: obj_ally failed")
	return true


func _e2m2_seed() -> bool:
	var m := main as MissionE2_02
	if not _v.has("k"):
		_v["k"] = true
		MissionHarness.kill(m.carriers.duplicate())
		_v["f"] = h.frame
		return false
	if not _v.has("skip") and h.frame - int(_v["f"]) > 60:   # the 0.5 s column tick saw them gone: resupply armed
		_v["skip"] = true
		_ok(m.carriers.is_empty(), "every carrier dead (%d)" % m.carriers.size())
		MissionHarness.skip_time(m, MissionE2_02.SEED_RESUPPLY + 1.0)
		return false
	if not _v.has("skip"):
		return false
	if m.carriers.is_empty():
		return false
	_ok(m.carriers.size() == 1, "one new carrier (%d)" % m.carriers.size())
	return true


# ---------------------------------------------------------------- e2m3 tribute cargo

func _e2m3() -> bool:
	var m := main as MissionE2_03
	m._tribute_amount = m.tribute_gold()
	var c := m._spawn(m.make_unit("caravan"), Unit.Team.PLAYER, MissionE2_03.LODGE_DOOR)
	c.set(&"cargo", m._tribute_amount / 2)   # robbed on the road
	c.set_meta(&"e2m3_tribute", true)
	m.tribute_caravan = c
	m._pay_tribute()
	_ok(m.tributes_paid == 0, "short tribute not counted (%d)" % m.tributes_paid)
	var c2 := m._spawn(m.make_unit("caravan"), Unit.Team.PLAYER, MissionE2_03.LODGE_DOOR)
	c2.set(&"cargo", m._tribute_amount)
	c2.set_meta(&"e2m3_tribute", true)
	m.tribute_caravan = c2
	m._pay_tribute()
	_ok(m.tributes_paid == 1, "full tribute counted (%d)" % m.tributes_paid)
	_ok(m.objective_state("obj_bazaar") == "done", "obj_bazaar closed by the first tribute")
	return true
