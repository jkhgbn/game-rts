extends RefCounted
## G-E fixes C (docs/art/ge_fixes_c.md): per-level art moods that need no level code. Reach it with load() (no class_name):
##     (load("res://art/environment/level_looks.gd") as Script).call(&"apply", level)
## Called once per level by GroundDetail._ready (main.gd's ground-detail hook, art-owned; windowed runs only: headless
## and sim runs never create a GroundDetail, so tests and labs are unchanged). Each look decides by itself whether the
## level wants it and is idempotent:
##   ForestMood   (art/environment/sighing_wood/forest_mood.gd)   Sighing Wood (mission 3): forest ground + decor, green-gold
##                light, dappled canopy shade and light shafts at High+, the Oldroot / Warden Gate art.
##   LaneDressing (art/environment/lane_dressing/lane_dressing.gd) Wave Strike lanes (Ashwind Reach): road-edge stones,
##                waystones, fences, banners, a ruined shrine at the ward line, ash at the Bastion plazas, the Muster
##                Pad surrounds (flagstones, corner banners).
##   ForestReplant (art/environment/lane_dressing/forest_replant.gd) Wave Strike forest blocks: the level's grid trees
##                replanted as a treeline + clusters + glades, 3 sizes (every tier: same meshes, same count).
##   ThornwaterLook (art/environment/thornwater/thornwater_look.gd) Thornwater (G-F r2 item 9): wet marsh-meadow ground,
##                peaty water, a cooler light (every tier); reed beds, thickets, a fen wood belt and the moat thorn
##                spires at Medium+ (docs/art/gf_thornwater.md).
##   QuartermeetLook (art/environment/quartermeet/quartermeet_look.gd) Quartermeet (G-F): a harvest highland on top of
##                the autumn swap: straw-gold stubble, granite roads, a heather moor rim, golden birch crowns, a slate-teal
##                river, a crisper sun (every tier); stook fields, drystone walls, hay bales and the moat standing stones
##                at Medium+ (docs/art/gf_quartermeet.md).

const LOOKS: Array[String] = [
	"res://art/environment/sighing_wood/forest_mood.gd",
	"res://art/environment/lane_dressing/lane_dressing.gd",
	"res://art/environment/lane_dressing/forest_replant.gd",
	"res://art/environment/thornwater/thornwater_look.gd",
	"res://art/environment/quartermeet/quartermeet_look.gd",
]


## Runs every look's `ensure_for_level(level)` (load-guarded). Returns how many looks dressed the level.
static func apply(level: Node) -> int:
	if level == null or not level.is_inside_tree():
		return 0
	var n := 0
	for path: String in LOOKS:
		if not ResourceLoader.exists(path):
			continue
		var s := load(path) as Script
		if s == null or not s.has_method(&"ensure_for_level"):
			continue
		if s.call(&"ensure_for_level", level) != null:
			n += 1
	return n
