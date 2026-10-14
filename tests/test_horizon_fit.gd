extends SceneTree
## Horizon fit (art/environment/horizon/horizon_fit.gd): the ring baked around the 120 m map follows MapInfo.
## Checks: every sector mesh carries UV2 anchors; the mapping is identity at 60 x 60 and keeps the 15 m gap outside
## a 192 x 96 map; the scene root fits itself to MapInfo on the frame after it enters the tree.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_horizon_fit.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "horizon_fit"

var hz: Node3D
var frame := 0
var fails: Array[String] = []


func _initialize() -> void:
	var baked := Vector2(60.0, 60.0)
	for p: Vector2 in [Vector2(10.0, 75.0), Vector2(-75.0, 30.0), Vector2(80.0, -90.0), Vector2(-59.9, 60.1)]:
		if HorizonFit.fit_point(p, baked).distance_to(p) > 0.0001:
			fails.append("fit at 60 x 60 moves %s" % p)
	var ws := Vector2(96.0, 48.0)
	# North band point 15 m outside the edge stays 15 m outside; the east band point 15 m past x stays 15 m past x.
	if absf(HorizonFit.fit_point(Vector2(10.0, -75.0), ws).y - (-63.0)) > 0.001:
		fails.append("north band gap: %s" % HorizonFit.fit_point(Vector2(10.0, -75.0), ws))
	if absf(HorizonFit.fit_point(Vector2(75.0, 20.0), ws).x - 111.0) > 0.001:
		fails.append("east band gap: %s" % HorizonFit.fit_point(Vector2(75.0, 20.0), ws))
	MapInfo.setup(192.0, 96.0)
	hz = (load("res://art/environment/horizon/horizon.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(hz)
	for c: Node in hz.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var uv2: Variant = arr[Mesh.ARRAY_TEX_UV2]
		if uv2 == null or (uv2 as PackedVector2Array).size() != (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
			fails.append("%s has no UV2 anchors" % mi.name)


func _process(_delta: float) -> bool:
	frame += 1
	if frame < 3:
		return false
	var got: Vector2 = hz.get(&"fitted_half")
	if got.distance_to(Vector2(96.0, 48.0)) > 0.001:
		fails.append("fitted_half %s, want (96, 48)" % got)
	for c: Node in hz.get_children():
		var mi := c as MeshInstance3D
		if mi != null and mi.extra_cull_margin < 36.0:
			fails.append("%s cull margin %.1f" % [mi.name, mi.extra_cull_margin])
	MapInfo.reset()
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
	return true
