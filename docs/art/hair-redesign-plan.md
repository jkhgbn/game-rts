# Hair redesign plan (tech-artist / art director, 2026-09-27)

User request (JS): a plan for a hair redesign plus screenshots of each kingdom's first unit. Refinement: **start only with
the character that has the lowest hair score, and don't redesign the others unless their screenshot is not green.**

## 0. Hair score table (read this first)

Sheets: `docs/art/hair/before/sheet.png` (the 4 wizards + each kingdom's first unit = keep slot 1),
`docs/art/hair/before/others/sheet_others.png` (champions + caravan drover), `docs/art/hair/after/sheet.png`
(Vessa before / mock-up). Single PNGs are next to each sheet (`<name>_{head,body,z25,z40}.png`).

| Character | Hair today | Score | Status | Action |
|---|---|---|---|---|
| **Vessa** (Fire wizard) | near-black cap sphere + 2 flat 6-sided slabs | **26** | RED (lowest) | **Redesigned first**: mock-up **70 GREEN** (`docs/art/hair/mock/`) |
| Caravan drover | ginger beard sphere under a wide hat | 46 | RED | later (low priority: hidden under the hat at 25 m) |
| Cinder Hand (Fire worker) | beard = one dark sphere | 46 | RED | later (worker, low priority) |
| Wayfinder A (Tamsin) | back hair + braid | 43 | RED | later (hidden by the hat brim at 25 m) |
| Wayfinder B (Tobin) | beard + back hair | 44 | RED | later (**B render looked like A: check set_variant in the rig first**) |
| Oathwall A (Garran) | forked beard | 53 | YELLOW | later |
| Mage Archer B (Vesper) | silver-lilac hair + braid | 53 | YELLOW | later (pale hair on pale skin) |
| Oathwall B (Gerda) | 2 flaxen braids | 58 | YELLOW | later |
| Ysolde (Nature wizard) | baked auburn cap + fall | 59 | YELLOW | later |
| Coin Cutter A (Sable) | wine braid | 60 | YELLOW | later |
| Torvald (Ice wizard) | white beard spheres + spade cone | 61 | YELLOW | later |
| Wildcaller B (Corwen) | grey mane + braided beard | 61 | YELLOW | later |
| Mender A (Orla) | chestnut cap + bun under kerchief | 70 | GREEN | leave alone |
| Mender B (Osric) | bushy ginger beard | 74 | GREEN | leave alone |
| Coin Cutter B (Silas) | golden forked beard | 75 | GREEN | leave alone |
| Malrik, Gloom Thrall, Rime Hauler, Sprigling, Mage Archer A, Wildcaller A | no visible hair (hoods, void faces, sprout) | - | n/a | nothing to do |

Not shot yet (hair seen in code: `blaze_rider_rider` beard + crest, `scorchbow`, `cinderlock`, `rime_seer`,
`rimehorn_rider_axeman`, `bramblehorn`, `wildwood_archer`, `mossback`): score them with the same tool before planning
them (task H5).

### Rubric (100 points; judged by eye on the four shots, same light and cameras for everyone)
| Criterion | Points | What earns it |
|---|---|---|
| 25 m read | 25 | the hair is visible as its own shape / colour patch from the game camera (pitch 55, fov 50, 1080p) |
| Silhouette hook | 20 | one memorable hair shape (a swept lock, braid, beard spade) that changes the outline or the chest read |
| Shape craft | 25 | chunky locks / strands (3-7 swept, tapered shapes) instead of spheres and slabs; no blunt cut ends in view |
| Palette / contrast | 15 | value contrast against skin and the clothes behind it; ties into the kingdom palette |
| Fit / clipping | 15 | sits under hats / hoods / crowns, no clipping at rest, idle, cast, attack |
Green >= 70, yellow 50-69, red < 50. The scores are an art-director call, not a measurement: the Art Lab check in
section 6 (H4) will make the 25 m part measured.

## 1. Current state (what it is made of, how it reads)
- **Vessa** (`art/units/wizards/vessa.gd` `_build_parts`, Head): `sphere(0.27)` cap + `sphere(0.24)` back mass + two
  `cyl(0.07, 0.08, 0.38, 6)` slabs beside the face, all `fire_hair` (0.20, 0.06, 0.04: near black). Close-up: two
  flat dark boards with a cut top, a bald-looking temple once the brim hides the cap. 25 m / 40 m: **nothing**: the brim
  hides the cap from above, the tall dark collar fan hides the back mass, the slabs are the same value as the shadow
  under the brim.
- **Torvald**: beard spheres + a tapering `cyl` spade in `torvald_beard` over the fur stole; hair under the ice crown.
  Reads at 25 m as a white mass, but white on white fur: it looks like part of the stole.
- **Ysolde**: one baked mesh `ys14_hair` (cap, side locks, fall) in `ysolde_hair` (auburn). Best palette of the four
  (auburn vs green), but it reads as one block; the antlers make her silhouette, the hair adds nothing to it.
- **Malrik**: no hair (void face in a hood). By design, keep.
- **Workers**: only the Cinder Hand has hair (beard sphere); the others wear hoods / are a sprout.
- **Champions**: already richer (braids, forked beards, bun, mane built from lobes / tubes / grids, each in its own
  script: `_tube`, `_grid`, `_frustum_into`, lathe `_cap_profile`). The problem there is not craft but **read at 25 m**
  (hats and helms hide it) and **contrast** (pale hair on pale skin / grey armour).
- **Note for every wizard**: `WizardModel.add_part` batches static parts per pivot (`_part_batch`) before the kit
  merge, so a variant has to edit `_part_batch[head]`, not the Head's children (see the mock).

## 2. Style rules for hair (painted low-poly look)
1. **Locks, not blobs**: 3-7 swept, tapered locks per head (a flattened 5-sided section along a curve, widest at 30 %,
   pointed tip). A cap sphere may stay as the underlayer, hidden under the hat / hood.
2. **One hook per character** that survives 25 m: a lock pulled over the chest, a braid, a beard spade, a top-knot.
   It must land where the game camera sees it (the chest / shoulders, not the back: capes and collars hide the back).
3. **Kingdom palettes**: Fire = dark ember brown with gold / ember tips; Ice = silver-blue white with a darker blue-grey
   underside (so it separates from white fur); Nature = auburn / moss, leaf or blossom ties; Shadow = ink violet with
   pale lilac tips. Hair never uses a team-recoloured material (`*_cloth`, `*_cape`, `*_pennon`); team colour may appear
   only as a tie / ribbon (already done on champion braids).
4. **Value contrast**: hair at least ~25 % value away from the skin and from the cloth right behind it.
5. **No transparency, no cards, no textures**: solid flat-shaded strands, toon ramp from the unit shader.
6. **Budget**: <= ~400-600 unique vertices (~900 flat-shaded) and <= 2 palette materials (hair + tip), merged into the
   Head pivot (0 extra draw instances). Animated locks (a braid swing) are optional and cost 1 keep_separate node.
7. **Fit**: locks start under the brim / hood lip (roots hidden), clear the arms in the cast / attack poses.

## 3. One direction per wizard
- **Vessa (done as a mock-up)**: ember-tipped swept locks under the hat. 2 long front locks from under the brim beside
  the cheeks, over the collar, lying on the mantle and curling out with ember-gold tips (the 25 m hook: dark strands
  and gold points on the orange mantle); 2 temple locks that frame the face; 2 short side locks for 3/4 volume; one
  fringe swept to her off side like the hat tip. Final: a new palette entry `fire_hair_ember` (a warmer copper-brown,
  ~0.36, 0.10, 0.05) instead of the near-black, tips `fire_sec_archer` or a small `fire_glow` point.
- **Malrik**: no hair (the void face is his identity). Optional: 2-3 ink-violet strands escaping the hood lip over the
  chest with pale lilac tips, only if a later sheet shows he needs a chest read. Not planned.
- **Torvald**: keep the long beard (his hook), split it into 5 frost locks (spade = 3 long locks + 2 moustache locks
  curling up), add a **blue-grey underside** (`torvald_beard` top, a darker frost entry below) so it separates from the
  white stole; 2 swept side locks under the crown.
- **Ysolde**: replace the baked block with 5-6 auburn locks falling over the leaf mantle in front of the shoulders,
  one lock tied with a blossom (her pink), tips a lighter copper; keep the leaf wreath.

## 4. Kit piece: the hair builder
Prototype: `docs/art/hair/mock/hair_kit.gd` (used by the Vessa mock). API:
`lock(st_body, st_tip, pts: [4 Bezier points], face: Vector3, width, thick, rings = 4, tip_from = 1.0, twist = 0.0)`,
`begin()`, `finish(st_body, body_mat, st_tip, tip_mat) -> ArrayMesh`, `lock_verts(rings)`; flattened pentagon section,
swell-then-taper profile, twist, flat normals, model-space output added with `add_part(head, mesh, null, ZERO)`.
Task H0 moves it to `art/units/kit/hair_kit.gd` (`class_name HairKit`) and adds: `braid(pts, lobes)` (alternating
lobes, for champions), `beard(...)` (spade of locks), a cached mesh per key (like the kit primitives), and a
`HAIR_PRESETS` dictionary (fire / ice / nature / shadow material pairs). Every unit calls it; nobody hand-builds hair.

## 5. Task list (only the non-green, lowest first; stop when the next is green)
| Id | Task | Agent | Effort |
|---|---|---|---|
| H0 | Kit hair builder (`art/units/kit/hair_kit.gd`, from the prototype) + `fire_hair_ember` palette entry (`tools/make_materials.gd`) + test `tests/test_hair_kit.gd` | tech-artist | medium |
| H1 | **Vessa**: apply the mock in `vessa.gd` (replace the 2 slabs + back mass), Art Lab + face shots, before / after | tech-artist | medium |
| H2 | Torvald + Ysolde (yellow) | tech-artist (one per character) | medium |
| H3 | Red champions / allies: Wayfinder A / B (check the variant bug), caravan drover, Cinder Hand | tech-artist per group | medium |
| H4 | Art Lab checks (section 6) | Art Lab owner (1.C numbers, 1.D checks) | medium |
| H5 | Score the not-yet-shot units (riders, archers, seers), add them to the table | tech-artist | medium |
| H6 | Yellow champions (Oathwall A / B, Mage Archer B, Coin Cutter A, Wildcaller B) | tech-artist per champion | medium |
Each task re-renders with `docs/art/hair/tools/hair_shots.gd` and ends with a new score (green = done).

## 6. Art Lab checks to add
- **HR1 hair reads at 25 m** (WARN < 70 % of the target): render the model with the hair surfaces flat-coloured (ID pass)
  from the 25 m game camera; hair pixels >= ~40 px at 1080p for a wizard, >= 15 for a unit, and >= 25 % visible (not
  covered by the hat / brim).
- **HR2 hair contrast**: mean value difference hair vs skin and hair vs the neighbouring cloth >= 0.2.
- **HR3 hat / hood clipping**: hair vertices inside the hat, hood or crown meshes, and inside the arm capsules at the
  cast / attack strike frames (A3 frames): FAIL above 3 % of the hair vertices.
- **HR4 budget**: hair vertices and materials against section 2 rule 6.

## 7. Budget estimate
Per character: ~1 medium tech-artist session (build + 2-3 render loops + Art Lab), about the size of a champion variant
piece. H0 ~1 session, H1 ~0.5 (the mock is most of it), H2 2 sessions, H3 3-4, H4 1, H5 1, H6 5. **Minimum step asked by
JS: H0 + H1 (~1.5 sessions)**; the rest only if JS wants the yellow / red ones done after seeing Vessa in game.
Run cost: 1 Godot window at a time, ~1 min per 8 characters (`hair_shots.gd`).

## 8. Tools and files
- `docs/art/hair/tools/hair_shots.gd` (windowed): head 3/4, body 3/4, game camera 25 m / 40 m per subject;
  `-- out=res://... list=name=res://scene.tscn,...` (a name ending in `_b` calls `set_variant(1)`).
- `docs/art/hair/tools/make_sheet.ps1`: the labelled sheet (+ `scores.csv`: name, label, score, status, note).
- Mock-up (never the real model): `docs/art/hair/mock/vessa_hair_mock.tscn` (inherits `vessa.tscn`) +
  `vessa_hair_mock.gd` (extends `vessa.gd`) + `hair_kit.gd`. Mock locks: 7 locks, 858 flat-shaded vertices, materials
  `fire_hair` + `fire_sec_archer`. Not checked yet: clipping in the cast / attack poses (H1 does it with the Art Lab).

## Decision (JS, 2026-09-27 16:33): after the playtest, bring EVERY character with hair to a hair score >= 70 (green)
Order: kit hair builder first (budget ~600 verts), then Vessa (apply the mock + clipping check in cast / attack), then the reds (Cinder Hand, caravan driver, Wayfinder x2), then the yellows (Ysolde, Torvald, Oathwall x2, Mage Archer B, Coin Cutter A, Wildcaller B). Medium-effort tech-artist agents, one per group; score each after.

