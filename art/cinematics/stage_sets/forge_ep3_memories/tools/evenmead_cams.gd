extends SceneTree
## E34-B helper: solves the Lens words of docs/design/episode3-4-opening.md 4.1 on forge_evenmead's live puppets and
## prints ready-to-paste `cam=dolly` keys for the .cine files (only the named subjects are handed to Lens, so the cine
## check frames exactly those faces). Temporary: once E34-A merges the Lens marks N02... S13 into forge_evenmead, the
## shots drop `cam=` and use the set marks.
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_ep3_memories/tools/evenmead_cams.gd --quit-after 3000

const SET := "res://art/cinematics/stage_sets/forge_evenmead/forge_evenmead.tscn"
const SHOTS := [
	["N02", "ms on malrik, 3/4-back-left, high, push 0.2", ["malrik"]],
	["N07", "mcu on malrik, 3/4-left, low", ["malrik"]],
	["N10", "ecu on stone, front, high", ["stone"]],
	["N11", "ms two-shot malrik torvald, 3/4-left, eye", ["malrik", "torvald"]],
	["N13", "cu on malrik, front, eye, push 0.3", ["malrik"]],
	["S02", "ms on ysolde, 3/4-back-left, high, push 0.2", ["ysolde"]],
	["S07", "mcu on ysolde, 3/4-left, low", ["ysolde"]],
	["S10", "ecu on bloom, 3/4-left, high", ["bloom"]],
	["S11", "ms two-shot ysolde vessa, 3/4-left, eye", ["ysolde", "vessa"]],
	["S13", "cu on ysolde, front, eye, push 0.3", ["ysolde"]],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var ls: Script = load("res://tools/lens/lens_solver.gd")
	var set_node := (load(SET) as PackedScene).instantiate() as Node3D
	root.add_child(set_node)
	for k in 20:
		await process_frame
	for s: Array in SHOTS:
		var subs := {}
		for tag: String in s[2]:
			var p: Node3D = set_node.call(&"puppet", StringName(tag))
			if p == null:
				push_warning("no puppet " + tag)
				continue
			subs[tag] = ls.call(&"subject_of", p)
		var cam: Dictionary = ls.call(&"solve_words", s[1], subs, {"res": Vector2i(1600, 900), "band": 2.39, "fov": 40.0})
		if not bool(cam.get("ok", false)):
			print("%s FAIL %s" % [s[0], str(cam.get("errors", []))])
			continue
		var a: Dictionary = cam["a"]
		var b: Dictionary = cam["b"]
		print("%s  cam=dolly  from=%s  to=%s  look=%s>%s  fov=%.1f>%.1f   # lens \"%s\"" % [s[0], _v(a["pos"]), _v(b["pos"]),
			_v(a["look"]), _v(b["look"]), float(a["fov"]), float(b["fov"]), s[1]])
	quit(0)


static func _v(p: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
