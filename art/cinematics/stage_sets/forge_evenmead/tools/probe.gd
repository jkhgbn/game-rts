extends SceneTree
## Prints terrain heights of forge_evenmead.set at key points (set-only helper).
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_evenmead/tools/probe.gd --quit-after 300

const FSet := preload("res://tools/world_forge/forge_set.gd")
const SPEC := "res://art/cinematics/stage_sets/forge_evenmead/forge_evenmead.set"


func _initialize() -> void:
	var fs := FSet.new()
	fs.compile(SPEC)
	var t = fs.terrain
	var pts := {"malrik": Vector2(0, -36), "torvald": Vector2(-3.4, -37), "ysolde": Vector2(-5, 34), "vessa": Vector2(-1.6, 35),
		"ford": Vector2(4, 0), "river_w": Vector2(-18, 4), "river_e": Vector2(26, -7), "tree": Vector2(-11, 41),
		"shadow_front_w": Vector2(-30, -27), "shadow_front_c": Vector2(-4, -28), "shadow_front_e": Vector2(22, -29),
		"ice": Vector2(35, -29), "nature": Vector2(-20, 25), "fire": Vector2(12, 25), "b01_end": Vector2(40, 14),
		"n05": Vector2(-26, -19), "stones": Vector2(12, 9), "far_n": Vector2(0, -128), "cam_e": Vector2(70, 0), "cam_w": Vector2(-70, 0)}
	for k: String in pts:
		var p: Vector2 = pts[k]
		print("H %s (%.1f, %.1f) = %.2f" % [k, p.x, p.y, t.height_at(p.x, p.y)])
	var line := ""
	for z in range(-60, 61, 4):
		line = "Z %4d:" % z
		for x in range(-75, 76, 10):
			line += " %5.1f" % t.height_at(float(x), float(z))
		print(line)
	quit()
