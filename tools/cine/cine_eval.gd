class_name CineEval
extends RefCounted
## Pure evaluation of a baked cinematic: the camera and every actor as a function of the global time t, exactly the
## formulas of docs/design/cinematics.md 3 (+ the runtime's move / teleport / face end states). Headless, no nodes: the
## checks, the determinism hash and the stills all read it. (The runtime player is cross-checked against it when present.)

const REF_SIZE := Vector2(1600.0, 900.0)   # framing is judged on 16:9 (the narrowest band the user sees)

var shots: Array[Dictionary] = []
var starts: PackedFloat64Array = []
var total := 0.0
var actor_start: Dictionary = {}          # tag -> {pos, yaw, head, visible}
var _events: Dictionary = {}              # tag -> [{t, kind, target, params}] sorted


static func create(baked: Array[Dictionary], p_actor_start: Dictionary) -> CineEval:
	var e := CineEval.new()
	e.shots = baked
	e.actor_start = p_actor_start
	var t := 0.0
	for s: Dictionary in baked:
		e.starts.append(t)
		t += float(s["duration"])
	e.total = t
	for i: int in baked.size():
		for a: Dictionary in baked[i]["actions"]:
			var tag: String = a["actor"]
			if tag == "" or not String(a["kind"]) in ["move", "teleport", "face", "visible"]:
				continue
			if not e._events.has(tag):
				e._events[tag] = []
			e._events[tag].append({"t": e.starts[i] + float(a["at"]), "kind": a["kind"], "target": a["target"], "params": a["params"]})
	for tag2: String in e._events:
		(e._events[tag2] as Array).sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["t"]) < float(y["t"]))
	return e


## [shot index, local time] at global t (t >= total -> last shot, its end).
func shot_at(t: float) -> Array:
	for i: int in range(shots.size() - 1, -1, -1):
		if t >= starts[i] - 0.000001:
			return [i, minf(t - starts[i], float(shots[i]["duration"]))]
	return [0, 0.0]


## {pos: Vector3, yaw: float (deg), visible: bool, head: float} of an actor at global t.
func actor(tag: String, t: float) -> Dictionary:
	var st: Dictionary = actor_start.get(tag, {"pos": Vector3.ZERO, "yaw": 0.0, "head": 1.6, "visible": true})
	var pos: Vector3 = st["pos"]
	var yaw: float = st["yaw"]
	var vis: bool = st["visible"]
	for ev: Dictionary in _events.get(tag, []):
		var t0: float = ev["t"]
		if t < t0:
			break
		var p: Dictionary = ev["params"]
		match String(ev["kind"]):
			"teleport":
				pos = ev["target"]
				if p.has("yaw_deg"):
					yaw = float(p["yaw_deg"])
			"move":
				var target: Vector3 = ev["target"]
				var d := target - pos
				var dist := d.length()
				var dur := dist / maxf(0.05, float(p.get("speed", 2.0)))
				if Vector2(d.x, d.z).length() > 0.01:
					yaw = rad_to_deg(atan2(d.x, d.z))
				pos = target if t >= t0 + dur or dur <= 0.0 else pos.lerp(target, (t - t0) / dur)
			"face":
				if p.has("yaw_deg"):
					var ft := maxf(0.001, float(p.get("time", 0.3)))
					var k := clampf((t - t0) / ft, 0.0, 1.0)
					yaw = rad_to_deg(lerp_angle(deg_to_rad(yaw), deg_to_rad(float(p["yaw_deg"])), k))
			"visible":
				vis = bool(p.get("on", true))
	return {"pos": pos, "yaw": yaw, "visible": vis, "head": float(st.get("head", 1.6))}


func head_point(tag: String, t: float) -> Vector3:
	var a := actor(tag, t)
	return (a["pos"] as Vector3) + Vector3(0, float(a["head"]), 0)


## {xform: Transform3D, fov: float, pos, look, shot: int, local: float} at global t.
func camera(t: float) -> Dictionary:
	var sl := shot_at(t)
	var i: int = sl[0]
	var lt: float = sl[1]
	var s: Dictionary = shots[i]
	var dur := maxf(0.0001, float(s["duration"]))
	var trans: int = int(s["trans_type"])
	if int(s["camera_mode"]) == 2 and trans == Tween.TRANS_SINE:
		trans = Tween.TRANS_CUBIC
	var k: float = Tween.interpolate_value(0.0, 1.0, clampf(lt, 0.0, dur), dur, trans, int(s["ease_type"]))
	var pos: Vector3
	var look: Vector3
	var mode := int(s["camera_mode"])
	match mode:
		3:  # ORBIT
			var c: Vector3 = s["pivot"]
			if String(s["pivot_actor"]) != "":
				c = actor(String(s["pivot_actor"]), t)["pos"]
			var a := deg_to_rad(lerpf(float(s["orbit_from_deg"]), float(s["orbit_to_deg"]), k))
			pos = c + Vector3(cos(a) * float(s["orbit_radius"]), float(s["orbit_height"]), sin(a) * float(s["orbit_radius"]))
			look = c + (s["look_offset"] as Vector3)
		5:  # FOLLOW
			var fa := actor(String(s["follow_actor"]), t)
			pos = (fa["pos"] as Vector3) + Basis(Vector3.UP, deg_to_rad(float(fa["yaw"]))) * (s["follow_offset"] as Vector3)
			look = (fa["pos"] as Vector3) + (s["look_offset"] as Vector3)
		_:
			pos = (s["from_pos"] as Vector3).lerp(s["to_pos"], k) if mode != 0 else s["from_pos"]
			look = (s["look_from"] as Vector3).lerp(s["look_to"], k) if mode != 0 else s["look_from"]
			if String(s["look_actor"]) != "":
				look = (actor(String(s["look_actor"]), t)["pos"] as Vector3) + (s["look_offset"] as Vector3)
	var xf := Transform3D(Basis.IDENTITY, pos)
	if not pos.is_equal_approx(look):
		var up := Vector3.UP
		if absf((look - pos).normalized().dot(Vector3.UP)) > 0.999:
			up = Vector3.FORWARD
		xf = xf.looking_at(look, up)
	if float(s["roll_deg"]) != 0.0:
		xf.basis = xf.basis * Basis(Vector3(0, 0, 1), deg_to_rad(float(s["roll_deg"])))
	var fov := lerpf(float(s["fov_from"]), float(s["fov_to"]), k)
	return {"xform": xf, "fov": fov, "pos": pos, "look": look, "shot": i, "local": lt}


## Screen position of a world point: Vector3(u, v, depth) with u, v in 0..1 of a `size` frame (keep-height fov);
## depth <= 0 = behind the camera.
static func project(xf: Transform3D, fov_deg: float, p: Vector3, size: Vector2 = REF_SIZE) -> Vector3:
	var pc := xf.affine_inverse() * p
	var depth := -pc.z
	if depth <= 0.01:
		return Vector3(0.5, 0.5, depth)
	var th := tan(deg_to_rad(fov_deg) * 0.5)
	var aspect := size.x / size.y
	var nx := pc.x / (depth * th * aspect)
	var ny := pc.y / (depth * th)
	return Vector3(0.5 + 0.5 * nx, 0.5 - 0.5 * ny, depth)


## Determinism hash: camera + every actor at every frame of `fps` (the bytes a recording would depend on).
func hash_frames(fps: int = 60) -> String:
	var n := int(ceil(total * fps)) + 1
	var parts := PackedStringArray()
	var tags: Array = actor_start.keys()
	tags.sort()
	for f: int in n:
		var t := float(f) / float(fps)
		var c := camera(t)
		var xf: Transform3D = c["xform"]
		var row := "%d|%.4f,%.4f,%.4f|%.4f,%.4f,%.4f|%.3f" % [f, xf.origin.x, xf.origin.y, xf.origin.z,
			-xf.basis.z.x, -xf.basis.z.y, -xf.basis.z.z, float(c["fov"])]
		for tag: String in tags:
			var a := actor(tag, t)
			var ap: Vector3 = a["pos"]
			row += "|%s:%.3f,%.3f,%.3f,%.1f,%d" % [tag, ap.x, ap.y, ap.z, float(a["yaw"]), int(a["visible"])]
		parts.append(row)
	return ToolCli.hash_of("\n".join(parts))
