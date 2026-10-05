extends SceneTree
## Skewed layout variants for the balance model's dataset (docs/tools/map_gate/balance_model.md): copies a MapLayout,
## applies a few deliberate asymmetries to ONE seat's image, saves tools/map_lab/balance/variants/<name>_layout.tres.
## The variant is a test map only (never in the catalog); the Bot Lab plays it with --layout=<that path>.
##   & tools/godot_run.ps1 --headless --path . -s res://tools/map_lab/balance/make_variant.gd --quit-after 600 '--' base=thornwater name=tw_skew_eco1 "ops=away:node:1:3"
##   ... '--' base=thornwater list=1      (spot ids per image: node / slot / camp / point)
## ops (comma separated):
##   move:<spot_id>:<dx>:<dz>          move one spot (world metres)
##   away:<kind>:<side>:<m>[:<sub>]    every <kind> spot of the seat on layout side <side> (its image) moves <m> metres
##                                     farther from that seat's keep (negative = closer); <sub> filters slot subs / roles
##   block:<x>:<z>:<sx>:<sz>           an extra rock block (collider before the bake), size sx x sz m
## No class_name on purpose (tool script).

const SEARCH := ["res://data/maps/%s_layout.tres", "res://data/maps/gen/%s_layout.tres", "res://tools/map_lab/balance/variants/%s_layout.tres"]
const OUT_DIR := "res://tools/map_lab/balance/variants/"


func _initialize() -> void:
	var opts := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var base := String(opts.get("base", "thornwater"))
	var path := ""
	for pat: String in SEARCH:
		if ResourceLoader.exists(pat % base):
			path = pat % base
			break
	if path == "":
		print("VARIANT: FAIL no layout %s" % base)
		quit(2)
		return
	var lay: MapLayout = (load(path) as MapLayout).duplicate(true)
	if opts.has("list"):
		for s: Dictionary in lay.spots:
			if String(s["kind"]) in ["node", "slot", "keep", "point", "camp"]:
				print("  %-6s %-28s image %-10s team %s sub %-14s pos (%.1f, %.1f) props %s" % [s["kind"], s["id"], s.get("image", "identity"),
					str(s.get("team", "-")), String(s.get("sub", "")), (s["pos"] as Vector3).x, (s["pos"] as Vector3).z, str(s.get("props", {}))])
		for st: Dictionary in lay.seats:
			print("  seat team %s side %s frame %s" % [str(st["team"]), str(st["side"]), String(st.get("frame_name", ""))])
		quit(0)
		return
	var name := String(opts.get("name", base + "_variant"))
	var log: Array[String] = []
	for op: String in String(opts.get("ops", "")).split(",", false):
		var p := op.split(":")
		match p[0]:
			"move":
				for i in lay.spots.size():
					var s: Dictionary = lay.spots[i]
					if String(s["id"]) == p[1]:
						s["pos"] = (s["pos"] as Vector3) + Vector3(p[2].to_float(), 0.0, p[3].to_float())
						log.append("moved %s by (%s, %s)" % [p[1], p[2], p[3]])
			"away":
				var side := p[2].to_int()
				var seat := {}
				for st: Dictionary in lay.seats:
					if int(st["side"]) == side and not lay.closed_seats.has(int(st["team"])):
						seat = st
						break
				var img := String(seat.get("frame_name", "identity"))
				var keep := lay.keep_of(int(seat.get("team", 0)))
				var kp: Vector3 = keep.get("pos", Vector3.ZERO)
				for i in lay.spots.size():
					var s: Dictionary = lay.spots[i]
					if String(s["kind"]) != p[1] or String(s.get("image", "identity")) != img:
						continue
					if p.size() > 4 and p[4] != "" and String(s.get("sub", "")) != p[4] and not String(s["id"]).ends_with("_" + p[4]) \
							and String((s.get("props", {}) as Dictionary).get("role", "")) != p[4]:
						continue
					var d := Vector3((s["pos"] as Vector3).x - kp.x, 0.0, (s["pos"] as Vector3).z - kp.z)
					if d.length() < 0.1:
						continue
					s["pos"] = (s["pos"] as Vector3) + d.normalized() * p[3].to_float()
					log.append("%s %s %+.1f m from the side-%d keep" % [p[1], s["id"], p[3].to_float(), side])
			"block":
				lay.blocks.append({"id": "variant_block_%d" % lay.blocks.size(), "kind": "rock", "height": 4.0, "yaw": 0.0,
					"center": Vector3(p[1].to_float(), 0.0, p[2].to_float()), "half": Vector3(p[3].to_float() * 0.5, 2.0, p[4].to_float() * 0.5)})
				log.append("block at (%s, %s) %s x %s m" % [p[1], p[2], p[3], p[4]])
	lay.id = StringName(name)
	lay.title = name
	lay.source = "variant of %s: %s" % [base, "; ".join(log)]
	lay.source_hash = ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var out := OUT_DIR + name + "_layout.tres"
	var err := ResourceSaver.save(lay, out)
	print("VARIANT %s -> %s (%s): %s" % [name, out, error_string(err), "; ".join(log)])
	quit(0 if err == OK else 1)
