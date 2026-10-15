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
##   face_verts  face-kit vertices allowed on top of `verts` (army units and mounts; not a limit of its own)
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

## Face allowance (face kit 2026-09-28, art/units/kit/face/): every army unit and mount carries a face (eyes, lips,
## ears, hair, beard: one cached surface). Rows with `face_verts` budget it ON TOP of `verts`: B4 counts the body plus
## only the face vertices above the allowance, so the body budget is unchanged and a bloated face still shows.
## Measured 2026-09-30 (census of art/units/, 105 scenes with a face): soldiers 352-1184 (avg 636; Shade 497), champions
## 590-812, creatures up to 592, mounts ~500, riders / cavalry (rider + mount faces) 880-1082, wizards 1297-2136
## (full hair). Allowances: one soldier face 800, champion 900, creature / mount 600, rider / cavalry 1200, wizard 2200.

const BUDGETS := {
	"unit/worker": {"src": "art-units.md 8", "face_verts": 800, "meshes": 22, "draw": 14, "verts": 2500, "lights": 0, "runtime_mats": 0,
		"frame_ms": 0.005, "n": 100, "soft": {"separate": 6, "looping": 0, "casters": 4}},
	"unit/soldier": {"src": "art-units.md 8, tier3-extras.md 12", "face_verts": 800, "meshes": 26, "draw": 14, "verts": 2500, "lights": 0,
		"runtime_mats": 0, "frame_ms": 0.005, "n": 100, "soft": {"separate": 6, "looping": 1, "particles": 10, "casters": 4}},
	"unit/heavy": {"src": "art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units", "face_verts": 800,
		"meshes": 30, "draw": 16, "lights": 0, "looping": 1, "runtime_mats": 0, "frame_ms": 0.005, "n": 100,
		"soft": {"verts": 6000, "separate": 6, "particles": 16, "casters": 6}},
	"unit/rider": {"src": "art-units.md 8 (rider = mount + rider)", "face_verts": 1200, "meshes": 36, "draw": 16, "lights": 0, "looping": 1,
		"particles": 10, "runtime_mats": 0, "frame_ms": 0.005, "n": 100, "soft": {"verts": 5000, "separate": 6, "casters": 5}},
	"unit/cavalry": {"src": "cavalry-mounts.md 10 (cavalry rider, mount separate)", "face_verts": 1200, "meshes": 20, "draw": 12, "lights": 0,
		"systems": 1, "particles": 10, "runtime_mats": 0, "frame_ms": 0.005, "n": 100,
		"soft": {"verts": 2500, "separate": 6, "casters": 4}},
	## G-F (2026-10-15, docs/art/gf_cavalry_tier.md): a cavalry scene that instances its mount AND its rider (Blaze Rider =
	## Boar + Rider) is judged on cavalry + mount summed: meshes 20 + 12, draws 12 + 8 (cavalry-mounts.md 10), frame 2 x
	## 0.005; soft verts 2500 + 6000, casters 4 + 2, separate 6 + 6 (the mount's animated legs / head / tail). Particle
	## systems stay at the cavalry's 1 (the spec gives mounts none), faces at 1200 (the census already measured rider +
	## mount faces under it).
	"unit/cavalry_mounted": {"src": "cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)", "face_verts": 1200,
		"meshes": 32, "draw": 20, "lights": 0, "systems": 1, "particles": 10, "runtime_mats": 0, "frame_ms": 0.01, "n": 100,
		"soft": {"verts": 8500, "separate": 12, "casters": 6}},
	"unit/wizard": {"src": "art-units.md 8 (wizard)", "face_verts": 2200, "meshes": 26, "draw": 16, "lights": 1, "runtime_mats": 0,
		"frame_ms": 0.005, "n": 100, "soft": {"verts": 3000, "separate": 6, "looping": 1, "particles": 8, "casters": 4}},
	"unit/champion": {"src": "champions.md 4 / 13, tier3-extras.md 12", "face_verts": 900, "meshes": 26, "draw": 16, "lights": 0,
		"materials": 5, "runtime_mats": 0, "frame_ms": 0.005, "n": 100,
		"soft": {"verts": 3000, "separate": 6, "looping": 1, "particles": 8, "casters": 4}},
	"unit/creature": {"src": "map-fill.md 10 (camp creature = soldier: 18 / 10)", "face_verts": 600, "meshes": 18, "draw": 10, "lights": 0,
		"runtime_mats": 0, "frame_ms": 0.005, "n": 100, "soft": {"verts": 2500, "separate": 6, "looping": 1, "casters": 4}},
	"beast/hero": {"src": "map-fill.md 10 (epic beast hero budget)", "meshes": 26, "draw": 16, "lights": 0,
		"runtime_mats": 0, "frame_ms": 0.01, "n": 12, "soft": {"verts": 8000, "looping": 2, "casters": 6}},
	"beast/titan": {"src": "titans-2.md 11 (Frost Wyrm uses the titan budget)", "meshes": 36, "draw": 20, "lights": 0,
		"looping": 2, "runtime_mats": 0, "frame_ms": 0.02, "n": 12, "soft": {"verts": 12000, "casters": 8}},
	"mount/mount": {"src": "cavalry-mounts.md 10 (mount)", "face_verts": 600, "meshes": 12, "draw": 8, "lights": 0, "runtime_mats": 0,
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

## Art Lab v3.1 craft checks (checks/craft.gd, C1-C4): bad / good ends of each measure and the check weights (x the
## "craft" group weight in lab_score.gd). Calibrated on the effort-trial Vinelashers + the good calibration set (see
## art-lab.md "Calibration" for the measured values). Measured 2026-09-27 (quick batch, laptop), per part / plain /
## normal variety / vertex use / colour steps / value steps / edges close / edges 25 m:
##   Vinelasher low    3.4 / 57 % / 0.864 / 38 % / 10 /  9 / 1.44 / 1.16   (the plain, blocky one: box limbs, 969 verts)
##   Vinelasher medium 11.3 / 61 % / 0.926 / 88 % / 12 / 10 / 1.74 / 1.15
##   Vinelasher high   8.6 / 38 % / 0.933 / 97 % / 14 / 11 / 1.97 / 1.29
##   Vinelasher xhigh  8.3 / 56 % / 0.920 / 83 % / 16 / 11 / 1.71 / 1.36
##   Shade             3.4 / 38 % / 0.839 / 52 % / 14 /  9 / 1.76 / 1.35   (a plain early unit: its band moved, art-lab.md)
##   Dusk Steed       21.3 / 25 % / 0.880 / 96 % / 10 /  6 / 2.41 / 1.88
##   Frost Dragon      8.8 / 16 % / 0.903 / 71 % / 17 /  9 / 4.35 / 5.66
## With these ends and weights (4 checks x 1 x group 2.0 = 8 of ~45-55 weight) low lands ~7-10 points under the other
## three (86 vs 94-96 in the quick batch); C1-C4 are INFO (scored, never WARN / FAIL).
const CRAFT := {
	"per_part_bad": 3.0, "per_part_good": 7.0, "w_per_part": 1.0,
	"plain_bad": 0.65, "plain_good": 0.35, "w_plain": 1.0,
	"entropy_bad": 0.84, "entropy_good": 0.92, "w_entropy": 1.0,
	"use_bad": 0.3, "use_good": 0.65,
	"palette_bad": 8, "palette_good": 13, "values_bad": 5, "values_good": 9,
	"edges_bad": 1.3, "edges_good": 1.8, "edges25_bad": 1.0, "edges25_good": 1.4,
	"weight_c1": 1.0, "weight_c2": 1.0, "weight_c3": 1.0, "weight_c4": 1.0,
}

## U1 (2026-09-27): C1-C4 graded for critters / buildings / landmarks too (v3.1: values only). Overrides of CRAFT per
## kind (the rest of CRAFT applies). Measured on the known-good calibration assets (quick batch, laptop):
##   Deer (critter)        per part 28 (1 pivot) / plain 3 % / variety 0.872 / use 94 % / 13 colour / 9 value steps /
##                         edges 0.80 close / 0.97 at 25 m (one smooth imported mesh: few inner edges is its style)
##   Aqueduct (landmark)   per part 232 (1 pivot) / plain 88 % / variety 0.841 / use 38 % / 14 / 9 / 3.7 / 4.89
## Single-root assets have no body parts (one pivot), so "shapes per body part" is not graded for them (weight 0);
## masonry is boxes by nature, so a building's plain-prism share is not graded either. Ends are provisional (one known
## asset per kind + lenient bad ends) until a building set is calibrated; the known-good pair lands at >= 0.9.
const CRAFT_KIND := {
	&"critter": {"w_per_part": 0.0, "plain_bad": 0.6, "plain_good": 0.3, "entropy_bad": 0.8, "entropy_good": 0.86,
		"use_bad": 0.4, "use_good": 0.8, "palette_bad": 5, "palette_good": 10, "values_bad": 4, "values_good": 8,
		"edges_bad": 0.3, "edges_good": 0.7, "edges25_bad": 0.3, "edges25_good": 0.7},
	&"building": {"w_per_part": 0.0, "w_plain": 0.0, "entropy_bad": 0.76, "entropy_good": 0.83,
		"use_bad": 0.15, "use_good": 0.4, "palette_bad": 7, "palette_good": 12, "values_bad": 5, "values_good": 8,
		"edges_bad": 1.2, "edges_good": 2.5, "edges25_bad": 1.2, "edges25_good": 2.5},
	&"landmark": {"w_per_part": 0.0, "w_plain": 0.0, "entropy_bad": 0.76, "entropy_good": 0.83,
		"use_bad": 0.15, "use_good": 0.4, "palette_bad": 7, "palette_good": 12, "values_bad": 5, "values_good": 8,
		"edges_bad": 1.2, "edges_good": 2.5, "edges25_bad": 1.2, "edges25_good": 2.5},
}


## CRAFT with the kind's overrides (CRAFT_KIND) merged in.
static func craft_for(kind: StringName) -> Dictionary:
	var cf: Dictionary = CRAFT.duplicate()
	cf.merge(CRAFT_KIND.get(kind, {}), true)
	return cf

## Art Lab v3 checks of task 1.D (checks/read_v3.gd: R11 walk, R5w flicker, R5c glow local contrast, R6cb colour-blind
## team colours, R12 light presets, S1 style bible), moved here as one block (docs/handoff/for-art-lab-1c.md).
## Calibrated by task 1.C on the calibration set (docs/plan/art-lab.md "Calibration", 2 windowed runs 2026-09-27):
##   flicker_range_warn 1 -> 2, flicker_drop_warn 0 -> 4: known-good Shade (2/2/2/0/1/0/2/2), Dusk Steed (1/1/1/1/0/0/0/1)
##     and Frost Dragon (range 2) flicker because the head turns / bobs in the gait (a small eye glow hides for 1-3 of 8
##     frames); a glow gone for more than half the cycle still WARNs, and the planted 40-bead dragon (17..27 points,
##     range 8-10) still WARNs.
##   glow_dl_warn 18 -> 0, glow_dl_bad 5 -> -10: the same Shade eye measured dL +2 / +6 / +11 / +14 over four runs (1 m
##     ring at 40 m = 24 px, mostly ground), so 18 flagged every good dark-bodied unit; 0 keeps only "a glow darker
##     than its surround" until R5c samples the ring on body pixels. Open false alarm: Dusk Steed dL -4 / +0 (dark head,
##     the ring is mostly bright grass).
##   cb_pair_warn 12 -> 6, cb_pair_bad 4 -> 3: fire / nature under deutan is the worst pair on every asset (Shade 9.2-9.5,
##     Frost Dragon 7.6, Sapling 13.7: the KINGDOM_COLORS palette, not the asset); the planted frozen-team Dusk Steed
##     measures 4.7 and still WARNs.
const V3 := {
	# R11 reads while walking (40 m black masks over the walk cycle vs the rest mask)
	"walk_samples": 8, "walk_dt": 0.09, "walk_ramp": 0.5,
	"walk_iou_warn": 0.55, "walk_iou_bad": 0.3, "walk_iou_good": 0.85,
	"walk_area_warn": 0.7, "walk_area_bad": 0.45, "walk_area_good": 0.95,
	# R5w glow flicker over the walk cycle (points above the bloom level per frame)
	"flicker_range_warn": 2, "flicker_drop_warn": 4,
	# R5c glow-point local contrast (lit 40 m frame, core vs the ring out to 1 m)
	"glow_ring_m": 1.0, "glow_dl_warn": 0.0, "glow_dl_bad": -10.0, "glow_dl_good": 45.0,
	# R6cb colour-blind team colours (deutan / protan simulation): worst kingdom pair on the team-colour area
	"cb_pair_warn": 6.0, "cb_pair_bad": 3.0, "cb_pair_good": 30.0,
	# R12 light-preset sweep (worst preset below de_fail = WARN, like R4)
	"preset_ids": [&"warm", &"ice", &"night", &"autumn"],
	"preset_kinds": [&"unit", &"mount", &"titan", &"beast", &"critter"],
	# S1 style bible (style-autumn.md 3): INFO; body vs the rendered autumn floor
	"style_de_bad": 8.0, "style_de_good": 40.0,
	"style_ground_L": Vector2(25.0, 55.0), "style_ground_C": 35.0, "style_team_de": 20.0,
	# weight of every new check in the quality score (low until calibrated)
	"weight": 0.5,
}

## Instance budgets of the biome sets (map-fill.md 10 "Instance budget per set").
const SET_INSTANCES := {&"riverbank": 1800, &"meadow": 1800, &"heath": 1600, &"old_wood": 900, &"glade": 1800,
	&"ruins": 300}

## Readability rules per kind. area_*: silhouette pixels at zoom 40 (1600 x 900, fov 50); glow: points at 40 m
## (min, max); de_*: CIE76 dE between the model and the ground behind it (mean over the body) on the main ground;
## team: min share of body pixels that change between kingdom colours; iou: silhouette overlap that "reads like X";
## bar: HP bar share of the body it may hide; motion: attack pose change at 40 m (1 - IoU idle vs strike).
## team (1.C calibration 2026-09-27): unit / titan / building 0.03 -> 0.08, mount 0.02 -> 0.06. A Dusk Steed whose
## team cloth is frozen (set_team_color changes nothing) still measures 1-2 % (pose / edge pixels), a frozen Shade 5 %
## (its smoke particles differ per instance), so 0.02-0.03 sat inside the noise; the lowest real asset is 11 % (Mossback).
const READ := {
	&"unit": {"area_warn": 120, "area_fail": 45, "glow": Vector2i(1, 3), "de_warn": 20.0, "de_fail": 10.0,
		"team": 0.08, "iou": 0.8, "bar_warn": 0.08, "bar_fail": 0.25, "motion": 0.12, "head": true, "feet": &"ground"},
	&"mount": {"area_warn": 150, "area_fail": 60, "glow": Vector2i(0, 2), "de_warn": 20.0, "de_fail": 10.0,
		"team": 0.06, "iou": 0.8, "motion": 0.0, "head": false, "feet": &"ground"},
	&"titan": {"area_warn": 900, "area_fail": 350, "glow": Vector2i(1, 5), "de_warn": 20.0, "de_fail": 10.0,
		"team": 0.08, "iou": 0.8, "bar_warn": 0.06, "bar_fail": 0.2, "motion": 0.08, "head": false, "feet": &"ground"},
	&"beast": {"area_warn": 350, "area_fail": 150, "glow": Vector2i(0, 3), "de_warn": 20.0, "de_fail": 10.0,
		"team": 0.0, "iou": 0.8, "bar_warn": 0.08, "bar_fail": 0.25, "motion": 0.1, "head": false, "feet": &"ground"},
	&"critter": {"area_warn": 25, "area_fail": 8, "glow": Vector2i(0, 1), "de_warn": 14.0, "de_fail": 7.0,
		"team": 0.0, "iou": 0.85, "motion": 0.0, "head": false, "feet": &"ground"},
	&"building": {"area_warn": 5000, "area_fail": 2000, "glow": Vector2i(2, 4), "de_warn": 14.0, "de_fail": 8.0,
		"team": 0.08, "iou": 0.8, "motion": 0.0, "head": false, "feet": &"base"},
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
			# G-F: mount + rider in one scene (blaze_rider.tscn also ends with "_rider.tscn") = the summed budget
			var mounted: bool = bool(unit_data["mounted"]) if unit_data.has("mounted") else is_mounted_scene(scene_path)
			if mounted:
				return &"cavalry_mounted"
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


## True when the saved scene's root has an instanced child named "Rider" next to another instanced child (the mount):
## the cavalry layout of every `art/units/<kingdom>/<cavalry>.tscn` (G-F 2026-10-15). A .tscn is read as text (no
## script is compiled, so it works before the class cache is ready); other formats read the PackedScene state.
static func is_mounted_scene(scene_path: String) -> bool:
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return false
	if scene_path.get_extension() == "tscn":
		var text := FileAccess.get_file_as_string(scene_path)
		var re := RegEx.create_from_string("(?m)^\\[node name=\"([^\"]+)\" parent=\"\\.\" [^\\]]*instance=")
		var has_rider := false
		var has_mount := false
		for m: RegExMatch in re.search_all(text):
			if m.get_string(1) == "Rider":
				has_rider = true
			else:
				has_mount = true
		return has_rider and has_mount
	var ps := load(scene_path) as PackedScene
	if ps == null:
		return false
	var st := ps.get_state()
	var rider := false
	var mount := false
	for i: int in range(1, st.get_node_count()):   # node 0 = the root (an inherited root is not a mount)
		if String(st.get_node_path(i, true)) != ".":
			continue
		if st.get_node_instance(i) == null:
			continue
		if String(st.get_node_name(i)) == "Rider":
			rider = true
		else:
			mount = true
	return rider and mount


## The budget table as Markdown (art-lab.md keeps a copy; `-- table` prints it).
static func markdown_table() -> String:
	var cols: Array[String] = ["meshes", "draw", "separate", "verts", "face_verts", "tris", "lights", "systems", "looping", "particles",
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
