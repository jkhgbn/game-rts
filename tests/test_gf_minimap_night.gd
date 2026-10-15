extends SceneTree
## G-F (docs/art/ge_review.md item 6): the minimap stays readable in the night prologue (mission_00).
## The minimap paints flat ground / river / fog colours (no 3D light): its CPU composite must be the same under the
## night and the dawn lighting, and the prologue (camera bounds = a 50 m corner of the 120 m map) opens the minimap
## framed on its play area so it is not a dot in black unexplored fog.
## Run:  godot --headless --path . -s tests/test_gf_minimap_night.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "gf_minimap_night"
const MISSION := "res://missions/mission_00.tscn"
const SETTLE_FRAMES := 30
const RES := 50

var h := MissionHarness.new()
var main: Node
var frame := 0
var _settle := 0


func _initialize() -> void:
	main = h.open(self, MISSION, {"task_id": TASK_ID, "difficulty": 1})


func _process(_delta: float) -> bool:
	frame += 1
	if frame > 3500:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	if not h.is_ready():
		return false
	_settle += 1
	if _settle < SETTLE_FRAMES:
		return false
	_check()
	return true


static func _mean_lum(img: Image) -> float:
	var total := 0.0
	for j in img.get_height():
		for i in img.get_width():
			total += img.get_pixel(i, j).get_luminance()
	return total / float(img.get_width() * img.get_height())


func _check() -> void:
	var errors: Array[String] = []
	var hud: Node = main.get(&"hud")
	var mm: Minimap = hud.get(&"minimap") if hud != null else null
	if mm == null:
		print("FAIL %s: no minimap" % TASK_ID)
		return
	var night := _mean_lum(mm.composite_image(RES))
	var ground_lum := Minimap.GROUND_COLOR.get_luminance()
	# Unframed (the old whole-map view) for the before / after numbers.
	var zoom_framed := mm.zoom
	var center_framed := mm.view_center
	mm.set_zoom(1.0)
	var whole := _mean_lum(mm.composite_image(RES))
	mm.zoom = zoom_framed
	mm.view_center = center_framed
	# Day lighting on the same level: the composite must not change (regression guard: today the minimap reads no
	# lighting at all, so this only fails if a future change lets the scene light into it).
	EmberfallNight.apply_to(main, EmberfallNight.dawn())
	var day := _mean_lum(mm.composite_image(RES))
	print("%s: night %.3f day %.3f whole-map %.3f ground %.3f zoom %.2f framed %s" % [TASK_ID, night, day, whole,
			ground_lum, mm.zoom, mm.framed_bounds])
	if absf(night - day) > 0.05 * maxf(day, 0.01):
		errors.append("night %.3f vs day %.3f" % [night, day])
	# At the start most of the play area is unexplored (black by fog-of-war.md, the braziers reveal it): the lit part
	# must still be a real share of the view, not a dot (before G-F: 0.015, about 6 % of the ground's luminance).
	if night < 0.15 * ground_lum:
		errors.append("night minimap too dark (%.3f < %.3f)" % [night, 0.15 * ground_lum])
	if mm.framed_bounds == Rect2() or mm.zoom <= 1.0:
		errors.append("the prologue's play area is not framed (zoom %.2f)" % mm.zoom)
	if night < 2.5 * whole:
		errors.append("framing did not brighten the view (%.3f <= %.3f)" % [night, whole])
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
