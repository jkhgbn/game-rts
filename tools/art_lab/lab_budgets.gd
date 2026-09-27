class_name ArtLabBudgets
extends RefCounted
## Art Lab (docs/plan/art-lab.md): every number the lab judges against, in one place.
## Budgets come from the specs (the `src` column); a key in a row's `soft` dictionary is a lab default (no spec number,
## or a guideline): going over it is a WARN, never a FAIL. Keys:
##   meshes   MeshInstance3D / MultiMeshInstance3D drawn at rest AFTER the kit merge (render cost; user decision
##            2026-09-26 23:20). The authored build parts (before the merge) are reported as INFO (B1a).
##   draw     draw instances at rest after the merge (visible meshes, multimeshes, particle systems, decals)
##   separate keep_separate parts (art-units 2.3)
##   verts    vertices of everything drawn at rest     tris   triangles (critters)
##   lights   Light3D nodes                            looping   looping particle systems   systems  all systems
##   particles  particles alive at rest (sum of the looping systems' amounts)
##   casters  shadow-casting geometry instances       materials  unique materials   runtime_mats  materials built
##            per instance (not shared by a 2nd instance)
##   frame_ms process time per instance (ms) with `n` instances animated in view at zoom 40
## Readability rules (READ) are per kind; the lab tunes them on finished assets (art-lab.md "Validation").

const KINDS: Array[StringName] = [&"unit", &"mount", &"titan", &"building", &"beast", &"critter", &"decor_set", &"vfx",
	&"landmark"]
const KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature", &"neutral"]
## Kingdom colours handed to set_team_color (art-keep 0.2 "team" column; ice / nature as the units use them).
const KINGDOM_COLORS := {
	&"fire": Color(0.85, 0.30, 0.12),
	&"shadow": Color(0.42, 0.22, 0.60),
	&"ice": Color(0.45, 0.75, 0.95),
	&"nature": Color(0.35, 0.70, 0.25),
}

const DEFAULT_TIER := {
	&"unit": &"soldier", &"mount": &"mount", &"titan": &"titan", &"building": &"hall", &"beast": &"hero",
	&"critter": &"deer", &"decor_set": &"set", &"vfx": &"family", &"landmark": &"landmark",
}

const BUDGETS := {
	"unit/worker": {"src": "art-units.md 8", "meshes": 22, "draw": 14, "verts": 2500, "lights": 0, "runtime_mats": 0,
		"frame_ms": 0.005, "n": 100, "soft": {"separate": 6, "looping": 0, "casters": 4}},
	"unit/soldier": {"src": "art-units.md 8, tier3-extras.md 12", "meshes": 26, "draw": 14, "verts": 2500, "lights": 0,
		"runtime_mats": 0, "frame_ms": 0.005, "n": 100, "soft": {"separate": 6, "looping": 1, "particles": 10, "casters": 4}},
	"unit/heavy": {"src": "art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units",
		"meshes": 30, "draw": 16, "lights": 0, "looping": 1, "runtime_mats": 0, "frame_ms": 0.005, "n": 100,
		"soft": {"verts": 6000, "separate": 6, "particles": 16, "casters": 6}},
	"unit/rider": {"src": "art-units.md 8 (rider = mount + rider)", "meshes": 36, "draw": 16, "lights": 0, "looping": 1,
		"particles": 10, "runtime_mats": 0, "frame_ms": 0.005, "n": 100, "soft": {"verts": 5000, "separate": 6, "casters": 5}},
	"unit/cavalry": {"src": "cavalry-mounts.md 10 (cavalry rider, mount separate)", "meshes": 20, "draw": 12, "lights": 0,
		"systems": 1, "particles": 10, "runtime_mats": 0, "frame_ms": 0.005, "n": 100,
		"soft": {"verts": 2500, "separate": 6, "casters": 4}},
	"unit/wizard": {"src": "art-units.md 8 (wizard)", "meshes": 26, "draw": 16, "lights": 1, "runtime_mats": 0,
		"frame_ms": 0.005, "n": 100, "soft": {"verts": 3000, "separate": 6, "looping": 1, "particles": 8, "casters": 4}},
	"unit/champion": {"src": "champions.md 4 / 13, tier3-extras.md 12", "meshes": 26, "draw": 16, "lights": 0,
		"materials": 5, "runtime_mats": 0, "frame_ms": 0.005, "n": 100,
		"soft": {"verts": 3000, "separate": 6, "looping": 1, "particles": 8, "casters": 4}},
	"unit/creature": {"src": "map-fill.md 10 (camp creature = soldier: 18 / 10)", "meshes": 18, "draw": 10, "lights": 0,
		"runtime_mats": 0, "frame_ms": 0.005, "n": 100, "soft": {"verts": 2500, "separate": 6, "looping": 1, "casters": 4}},
	"beast/hero": {"src": "map-fill.md 10 (epic beast hero budget)", "meshes": 26, "draw": 16, "lights": 0,
		"runtime_mats": 0, "frame_ms": 0.01, "n": 12, "soft": {"verts": 8000, "looping": 2, "casters": 6}},
	"beast/titan": {"src": "titans-2.md 11 (Frost Wyrm uses the titan budget)", "meshes": 36, "draw": 20, "lights": 0,
		"looping": 2, "runtime_mats": 0, "frame_ms": 0.02, "n": 12, "soft": {"verts": 12000, "casters": 8}},
	"mount/mount": {"src": "cavalry-mounts.md 10 (mount)", "meshes": 12, "draw": 8, "lights": 0, "runtime_mats": 0,
		"frame_ms": 0.005, "n": 50, "soft": {"verts": 6000, "looping": 1, "casters": 2}},
	"titan/titan": {"src": "cavalry-mounts.md 10, titans-2.md 11", "meshes": 36, "draw": 20, "lights": 0, "looping": 2,
		"runtime_mats": 0, "n": 12, "soft": {"verts": 12000, "casters": 12, "frame_ms": 0.02}},
	"building/keep": {"src": "art-keep.md 9", "draw": 32, "materials": 8, "verts": 12000, "lights": 2, "particles": 90,
		"frame_ms": 0.05, "n": 8, "soft": {"runtime_mats": 0}},
	"building/hall": {"src": "art-keep.md 9 numbers, step-12/13 rules: 0 lights", "draw": 32, "materials": 8,
		"verts": 12000, "lights": 0, "particles": 90, "frame_ms": 0.05, "n": 8, "soft": {"runtime_mats": 0}},
	"building/small": {"src": "lab default (towers, walls, posts): half a keep", "lights": 0, "frame_ms": 0.05, "n": 8,
		"soft": {"draw": 16, "materials": 6, "verts": 6000, "particles": 40, "runtime_mats": 0}},
	"critter/deer": {"src": "map-fill.md 9 (game critter deer)", "tris": 1200, "materials": 1, "lights": 0, "n": 30,
		"soft": {"draw": 6, "frame_ms": 0.005, "runtime_mats": 0}},
	"critter/rabbit": {"src": "map-fill.md 9 (game critter rabbit)", "tris": 300, "materials": 1, "lights": 0, "n": 30,
		"soft": {"draw": 6, "frame_ms": 0.005, "runtime_mats": 0}},
	"critter/cosmetic": {"src": "map-fill.md 9 (cosmetic critter)", "tris": 300, "lights": 0, "n": 30,
		"soft": {"draw": 2, "frame_ms": 0.003}},
	"decor_set/set": {"src": "map-fill.md 9 / 10 (biome sets)", "lights": 0,
		"soft": {"kinds": 6, "tris_per_mesh": 1200, "range": 90.0, "frame_ms_patch": 0.1}},
	"vfx/family": {"src": "art-units.md 6.10 / 8, cavalry-mounts.md 11 (pooled, no runtime instancing)", "lights": 0,
		"soft": {"nodes_per_play": 0, "leak": 0, "mats_per_play": 0, "particles": 200, "draw": 40, "frame_ms": 0.02}},
	"landmark/landmark": {"src": "map-fill.md 9 (emission only, shadows allowed); counts = lab defaults", "lights": 0,
		"n": 4, "soft": {"draw": 24, "verts": 20000, "materials": 6, "looping": 2, "frame_ms": 0.05}},
	"landmark/objective": {"src": "map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12",
		"lights": 0, "n": 4, "soft": {"draw": 32, "verts": 24000, "materials": 10, "looping": 3, "frame_ms": 0.05}},
}

## Glow-point ranges per tier (win over READ[kind].glow): keeps and objective landmarks carry many lit windows / runes.
const GLOW_TIER := {
	"building/keep": Vector2i(4, 12),
	"landmark/objective": Vector2i(4, 12),
	"unit/wizard": Vector2i(1, 4),
	"unit/champion": Vector2i(1, 4),
}
## Readability tolerances per tier (win over READ[kind]): wizards / champions wear an identity crest (hat, antlers,
## staff head) above the HP-bar line.
const TIER_READ := {
	"unit/wizard": {"head_max": 1.45, "top_width": 0.7, "crest": true},
	"unit/champion": {"head_max": 1.35, "top_width": 0.6, "crest": true},
	"titan/titan": {"top_width": 99.0},
}
## Emission above this (linear HDR) triggers the bloom: the lab's glow-point threshold (lighting presets use 1.0-1.2).
const GLOW_HDR := 1.1
## A kingdom's home ground (R4 names it on its own line): where its units stand most.
const KINGDOM_GROUND := {&"fire": &"ash", &"ice": &"snow", &"nature": &"old_wood", &"shadow": &"marsh"}

## Instance budgets of the biome sets (map-fill.md 10 "Instance budget per set").
const SET_INSTANCES := {&"riverbank": 1800, &"meadow": 1800, &"heath": 1600, &"old_wood": 900, &"glade": 1800,
	&"ruins": 300}

## Readability rules per kind. area_*: silhouette pixels at zoom 40 (1600 x 900, fov 50); glow: points at 40 m
## (min, max); de_*: CIE76 dE between the model and the ground behind it (mean over the body) on the main ground;
## team: min share of body pixels that change between kingdom colours; iou: silhouette overlap that "reads like X";
## bar: HP bar share of the body it may hide; motion: attack pose change at 40 m (1 - IoU idle vs strike).
const READ := {
	&"unit": {"area_warn": 120, "area_fail": 45, "glow": Vector2i(1, 3), "de_warn": 20.0, "de_fail": 10.0,
		"team": 0.03, "iou": 0.8, "bar_warn": 0.08, "bar_fail": 0.25, "motion": 0.12, "head": true, "feet": &"ground"},
	&"mount": {"area_warn": 150, "area_fail": 60, "glow": Vector2i(0, 2), "de_warn": 20.0, "de_fail": 10.0,
		"team": 0.02, "iou": 0.8, "motion": 0.0, "head": false, "feet": &"ground"},
	&"titan": {"area_warn": 900, "area_fail": 350, "glow": Vector2i(1, 5), "de_warn": 20.0, "de_fail": 10.0,
		"team": 0.03, "iou": 0.8, "bar_warn": 0.06, "bar_fail": 0.2, "motion": 0.08, "head": false, "feet": &"ground"},
	&"beast": {"area_warn": 350, "area_fail": 150, "glow": Vector2i(0, 3), "de_warn": 20.0, "de_fail": 10.0,
		"team": 0.0, "iou": 0.8, "bar_warn": 0.08, "bar_fail": 0.25, "motion": 0.1, "head": false, "feet": &"ground"},
	&"critter": {"area_warn": 25, "area_fail": 8, "glow": Vector2i(0, 1), "de_warn": 14.0, "de_fail": 7.0,
		"team": 0.0, "iou": 0.85, "motion": 0.0, "head": false, "feet": &"ground"},
	&"building": {"area_warn": 5000, "area_fail": 2000, "glow": Vector2i(2, 4), "de_warn": 14.0, "de_fail": 8.0,
		"team": 0.03, "iou": 0.8, "motion": 0.0, "head": false, "feet": &"base"},
	&"landmark": {"area_warn": 3000, "area_fail": 800, "glow": Vector2i(0, 3), "de_warn": 10.0, "de_fail": 5.0, "melt_warn": 0.6, "melt_fail": 0.9,
		"team": 0.0, "iou": 0.85, "motion": 0.0, "head": false, "feet": &"base"},
	&"decor_set": {"glow": Vector2i(0, 12), "occlude_warn": 0.2, "occlude_fail": 0.4, "unit_de_warn": 20.0,
		"unit_de_fail": 10.0, "cover_warn": 0.55},
	&"vfx": {"area_warn": 200, "area_fail": 40},
}


static func key(kind: StringName, tier: StringName) -> String:
	return "%s/%s" % [kind, tier]


static func has_tier(kind: StringName, tier: StringName) -> bool:
	return BUDGETS.has(key(kind, tier))


static func tiers_of(kind: StringName) -> Array[String]:
	var out: Array[String] = []
	for k: String in BUDGETS:
		if k.begins_with(String(kind) + "/"):
			out.append(k.get_slice("/", 1))
	return out


## The budget row (hard keys at the top level, lab defaults under "soft").
static func row(kind: StringName, tier: StringName) -> Dictionary:
	return BUDGETS.get(key(kind, tier), {})


## Limit of `k` in a row: {limit, hard} or {} when the row does not budget it.
static func limit(r: Dictionary, k: String) -> Dictionary:
	if r.has(k):
		return {"limit": r[k], "hard": true}
	var soft: Dictionary = r.get("soft", {})
	if soft.has(k):
		return {"limit": soft[k], "hard": false}
	return {}


static func read_rules(kind: StringName, tier: StringName = &"") -> Dictionary:
	var r: Dictionary = (READ.get(kind, {}) as Dictionary).duplicate()
	var k := key(kind, tier)
	if GLOW_TIER.has(k):
		r["glow"] = GLOW_TIER[k]
	if TIER_READ.has(k):
		r.merge(TIER_READ[k], true)
	return r


## Picks the tier when none was given: from the scene path, the unit's data (UnitType fields) and the kind.
static func guess_tier(kind: StringName, scene_path: String, unit_data: Dictionary) -> StringName:
	var p := scene_path.to_lower()
	match kind:
		&"unit":
			if "/wizards/" in p:
				return &"wizard"
			if "/champions/" in p:
				return &"champion"
			if "/neutral/" in p:
				return &"creature"
			if bool(unit_data.get("is_worker", false)):
				return &"worker"
			if p.ends_with("_rider.tscn"):
				return &"cavalry"
			var h: float = float(unit_data.get("body_height", 0.0))
			if h >= 2.2:
				return &"heavy"
			return &"soldier"
		&"beast":
			if "frost_wyrm" in p:
				return &"titan"
			return &"hero"
		&"building":
			if "keep" in p:
				return &"keep"
			if "tower" in p or "wall" in p or "spire" in p or "post" in p or "flag" in p:
				return &"small"
			return &"hall"
		&"landmark":
			if "crown" in p or "altar" in p or "objective" in p or "/capture/" in p:
				return &"objective"
			return &"landmark"
		&"critter":
			if "rabbit" in p:
				return &"rabbit"
			if "/critters/" in p and not "deer" in p:
				return &"cosmetic"
			return &"deer"
	return DEFAULT_TIER.get(kind, &"")


## The budget table as Markdown (art-lab.md keeps a copy; `-- table` prints it).
static func markdown_table() -> String:
	var cols: Array[String] = ["meshes", "draw", "separate", "verts", "tris", "lights", "systems", "looping", "particles",
		"casters", "materials", "runtime_mats", "frame_ms", "n"]
	var s := "| kind/tier | " + " | ".join(cols) + " | source |\n|---|" + "---|".repeat(cols.size()) + "---|\n"
	for k: String in BUDGETS:
		var r: Dictionary = BUDGETS[k]
		var cells: Array[String] = []
		for c: String in cols:
			var l := limit(r, c)
			if l.is_empty():
				cells.append("")
			else:
				cells.append(("%s" % str(l["limit"])) + ("" if bool(l["hard"]) else " (soft)"))
		s += "| %s | %s | %s |\n" % [k, " | ".join(cells), r.get("src", "")]
	return s
