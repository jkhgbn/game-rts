extends SceneTree
## Tool 6 World Forge (docs/plan/tools-wave.md 7): spec errors teach, a set builds with the set contract / budgets /
## marks in the band / deterministic scatter, the demo set spec compiles, Fourfold Hollow mirrors 4 ways, and a small
## map bakes a navmesh and passes the Map Lab. Prints "PASS tool_world_forge" or "FAIL tool_world_forge: <reason>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_tool_world_forge.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "tool_world_forge"
const FSet := preload("res://tools/world_forge/forge_set.gd")
const Checks := preload("res://tools/world_forge/forge_set_checks.gd")
const FMap := preload("res://tools/world_forge/forge_map.gd")
const MapLab := preload("res://tools/map_lab/map_lab.gd")

const SET_TEXT := """set forge_test_corner  size=24x20  ground=crypt  light=crypt  seed=3
budget draws<=40 lights<=0
wall  back  poly=[(-10,-8),(10,-8)]  height=3  thick=1
place forge:brazier  at=(-3,-3)
place kit:ruin_pillar  at=(4,-4)  tag=pillar
scatter kit:boulder  area=rect((-11,0),(11,9))  count=8  gap=2.5  seed=4  avoid=cams
actor keeper  kit:flame_guard  at=(0,-2)  yaw=0
mark C01  from=(0,1.7,7)  to=(1,1.7,6)  look=(0,1.4,-2)  subject=keeper  fov=38
mark C02  from=(-6,2.5,4)  look=(4,1.5,-4)  subject=pillar  fov=42
"""
const BAD_TEXT := """set forge_bad  size=20x20  ground=crpyt
scatter kit:pnie  area=rect((-5,-5),(5,5))  cuont=4
mark M1  lens="mcu on keeper"
"""
const MAP_TEXT := """map test_mini  size=60  symmetry=rot180  title="Test Mini"
seat 0  name="south-west"  side=0  frame=identity
seat 1  name="north-east"  side=1  frame=rot180
keep  keep   at=(-20,20)
node  n1     at=(-12,6)
camp  c1     at=(-6,-15)
lair  l1     at=(-22,-4)
crown crown  at=(0,0)
block rocks  at=(-10,14)  size=(4,2)  yaw=30
river mid  poly=[(-31,-31),(31,31)]  half_width=1.5
crossing ford_c  kind=ford  at=(0,0)  width=8  dir=(1,1)
"""

var frame := 0
var fails: Array[String] = []
var holder: Node3D
var fs: FSet
var level: Node3D
var fm: FMap
var ready_at := -1


func _write(path: String, text: String) -> String:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return path


func _initialize() -> void:
	holder = Node3D.new()
	root.add_child(holder)
	# 1. errors teach
	var bad := FSet.new()
	var ok := bad.compile(_write("user://wf_bad.set", BAD_TEXT))
	var all := "\n".join(bad.spec.error_lines())
	if ok:
		fails.append("a bad spec compiled")
	for want in ["did you mean \"crypt\"", "did you mean \"pine\"", "did you mean \"count\"", "Lens (tool 3) is not installed", ":2:"]:
		if not all.contains(want):
			fails.append("bad-spec errors lack '%s' (got: %s)" % [want, all.replace("\n", " / ")])
	# 2. the demo set spec compiles
	var demo := FSet.new()
	if not demo.compile("res://art/cinematics/stage_sets/forge_watch_keep/forge_watch_keep.set"):
		fails.append("demo set spec: " + " / ".join(demo.spec.error_lines()))
	elif demo.plan["marks"].size() < 4:
		fails.append("demo set has %d marks, want 4" % demo.plan["marks"].size())
	# 3. a set builds (in memory)
	fs = FSet.new()
	if not fs.compile(_write("user://wf_test.set", SET_TEXT)):
		fails.append("test set: " + " / ".join(fs.spec.error_lines()))
		return
	fs.build(holder)
	# 4. maps: Fourfold Hollow mirrors, a small map builds a preview
	var ff := FMap.new()
	if not ff.compile("res://data/maps/fourfold_hollow.map"):
		fails.append("fourfold_hollow.map: " + " / ".join(ff.spec.error_lines()))
	else:
		var counts := {}
		for s: Dictionary in ff.layout.spots:
			counts[s["kind"]] = int(counts.get(s["kind"], 0)) + 1
		for want: Array in [["keep", 4], ["point", 10], ["camp", 12], ["post", 8], ["lair", 8], ["cache", 6], ["crown", 1]]:
			if int(counts.get(want[0], 0)) != int(want[1]):
				fails.append("fourfold %s count %d, want %d (map-2v2.md 2.8)" % [want[0], counts.get(want[0], 0), want[1]])
		var teams := []
		for k in ff.layout.spots_of("keep"):
			teams.append(int(k["team"]))
		teams.sort()
		if teams != [0, 1, 3, 4]:
			fails.append("fourfold keep teams %s, want [0, 1, 3, 4]" % str(teams))
		if ff.layout.keep_of(4).get("pos", Vector3.ZERO) != Vector3(66, 0, 66):
			fails.append("ENEMY_2 keep at %s, want (66, 66)" % str(ff.layout.keep_of(4).get("pos")))
		var ff2 := FMap.new()
		ff2.compile("res://data/maps/fourfold_hollow.map")
		if ff._layout_hash() != ff2._layout_hash():
			fails.append("fourfold layout not deterministic")
	fm = FMap.new()
	fm.map_id = "test_mini"
	if not fm.compile(_write("user://wf_mini.map", MAP_TEXT)):
		fails.append("mini map: " + " / ".join(fm.spec.error_lines()))
		return
	if fm.layout.spots.size() != 9:
		fails.append("mini map has %d spots, want 9 (4 pairs + the crown)" % fm.layout.spots.size())
	var scr := GDScript.new()
	scr.source_code = "extends \"res://tools/world_forge/forge_map_level.gd\"\nconst LAIR_SPOTS: Array[Dictionary] = [{\"id\": \"l1\", \"center\": Vector3(-22, 0, -4)}, {\"id\": \"l1b\", \"center\": Vector3(22, 0, 4)}]\n"
	scr.reload()
	level = Node3D.new()
	level.set_script(scr)
	level.set(&"layout", fm.layout)
	root.add_child(level)


func _process(_delta: float) -> bool:
	frame += 1
	if not fails.is_empty() and fs == null:
		return _end()
	if frame == 5 and fs:
		var set_root: Node3D = holder.get_child(0)
		Checks.run(fs, set_root)
		for c: Dictionary in fs.report.checks:
			if c["id"] in ["K1", "B1", "B2", "M1", "M2"] and c["status"] != "PASS":
				fails.append("set check %s %s: %s" % [c["id"], c["status"], c["value"]])
		if int(fs.plan["scatters"][0].get("placed", 0)) != 8:
			fails.append("scatter placed %d / 8" % fs.plan["scatters"][0].get("placed", 0))
		if set_root.call(&"puppet", &"keeper") == null or not set_root.is_in_group(&"cinematic_sets"):
			fails.append("set contract: puppet / group missing")
		var fs2 := FSet.new()
		fs2.compile("user://wf_test.set")
		var h2 := Node3D.new()
		holder.add_child(h2)
		fs2.build(h2)
		if fs.layout_hash() != fs2.layout_hash():
			fails.append("set layout not deterministic (%s vs %s)" % [fs.layout_hash(), fs2.layout_hash()])
		var img := Checks.plan_image(fs)
		if img.get_width() < 100:
			fails.append("plan image not drawn")
	if level == null:
		return _end() if frame > 6 else false
	if level.get(&"match_started") != true:
		if frame > 1500:
			fails.append("mini map navmesh never synced")
			return _end()
		return false
	if ready_at < 0:
		ready_at = frame
	if frame < ready_at + 10:
		return false
	var lab = MapLab.run_on(level, fm.profile_dict(), {"out": "user://wf_mini_lab", "run": "wf_test", "log": "0", "heat": "0"})
	if lab.result() == "FAIL" or lab.quality() < 90.0:
		var bad: Array[String] = []
		for c: Dictionary in lab.checks:
			if c["status"] == "FAIL" or c["status"] == "WARN":
				bad.append("%s %s %s" % [c["id"], c["status"], c.get("value", "")])
		fails.append("mini map Map Lab %s %.0f: %s" % [lab.result(), lab.quality(), "; ".join(bad)])
	return _end()


func _end() -> bool:
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	return true
