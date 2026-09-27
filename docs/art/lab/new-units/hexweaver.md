# Hexweaver (Shadow T2 caster) - new unit art (Art Lab v3 phase 4.2, medium effort)

Start 11:29 · end 11:45 (laptop time, 2026-09-27) · ~16 min · 9 lab runs (1 broken by the concurrent `tools/art_lab/` fix round)

Files: `art/units/shadow/hexweaver/hexweaver.tscn`, `hexweaver.gd` (extends `ShadowModel`: Shadow dissolve death,
`glow_gain`). Lab output: `docs/art/lab/new-units/hexweaver/` (scorecard.md, contact_sheet.png, fixes.json).

## Runs
Command (all runs): `.\tools\art_lab\run_art_lab.ps1 art/units/shadow/hexweaver/hexweaver.tscn unit shadow -Extra 'out=docs/art/lab/new-units/hexweaver','ref=nightbolt,shade,shadow_knight'` (+ `'compare=prev'` from run 2)

| # | Wall s | Quality | FAIL / WARN | Change before the run |
|---|---|---|---|---|
| 1 | 36 | 93 | FAIL B4 (2 764 verts) · WARN R5 (0 glow points) | first build |
| 2 | 38 | 95 | FAIL B4 (2 667) | cage 6 -> 5 ribs, soul on `shadow_glow_mid` + `glow_gain` 1.4 (R5 PASS), left shoulder fetish (P2) |
| 3 | 39 | 96 | none | hood / torso / staff tubes without hidden caps, smaller skull |
| 4 | 7 | (92) | lab script errors (another agent editing `tools/art_lab/`), B4 2 595 | eye dots, hunch pushed, 10-12 sided robe / sleeves |
| 5 | 39 (+60 wait) | 96 | none | trims (legs 5 sides no caps, face 8x5, cage ribs 3 sides) |
| 6 | 53 | 95 | none | skirt gap fixed (two cones + team band) |
| 7 | 40 | 96 | none | band removed (single skirt cone), head moved low / forward (hunch) |
| 8 | 44 | 95 | none | tilted skirt / hump / shawl / sleeve drapes (C1 +6) |
| 9 | 47 | 95 (95.4) | none | silver staff bands (colour step), longer fetish horn |

**Final: PASS, quality 95 (95.4), 0 FAIL, 0 WARN, 32 PASS.** Quality plateaued at 95-96 from run 3 (the swings are the
noisy INFO checks P4 / C3 / S1), so I stopped.

## Budget (final run)
10 meshes after merge (HexCage 2, root blob 1, 7 pivots) · 11 draw instances at rest (<= 14) · 2 keep_separate ·
2 394 vertices (<= 2 500) · 0 lights · 1 looping particle system (5 wisps) · 1 glow point at 40 m (the caged soul +
its wisps) · 3 shadow casters · 0 runtime materials / 0 allocations after _ready · 0.0024 ms per instance ·
death_finished 1.02 s · IoU max 0.59 vs shade (nightbolt 0.51, shadow_knight 0.34).

## What I built
- A hunched witch, 1.6 m: team-violet robe torso leaning forward over a dark hump, dark ankle-length robe, pointed shoes.
- Deep team hood with a drooping point (bone charm on the tip) over a pale hook-nosed face with sunken dark eyes.
- Long bell sleeves hanging past the wrists, a pale three-claw left hand; a beast skull + hooked bone horn on the left
  shoulder as the asymmetry opposite the cage.
- The hook: a crooked dark staff (silver bands) whose crook dangles a bone cage (5 ribs, cap, ring, skull) holding a
  violet soul (`shadow_glow_mid`, the only glow), thin violet wisps rising; the cage hangs by gravity with a pendulum lag.
- Hooks: `hex_bolt` attack (0.55 s, release event at 0.12: claw stab, staff jab, soul flare + burst), `play_cast`
  (Wither Hex, 1.0 s: staff raised, claw grasps, burst at 0.55 s), hunched shuffle walk, Shadow dissolve death + motes.

## Next steps
- Gameplay (step 16 code): `hexweaver.tres` with `model_scene` = this scene, `attack_windup` 0.12; call
  `play_cast(&"wither_hex")`. The "smoke threads to the hexed target" (5.4) need a target-aware VFX (not in the model).
- Icon `art/icons/units/hexweaver*` (16.V4) not made here (outside my paths).
- Optional polish: C1 normal variety 0.89 (target 0.92) and C3 colour steps; play_cast is not exercised by the lab.

## Art Lab notes
- Run 4 hit parse errors in `tools/art_lab/` (the concurrent fix round); waiting 60 s and re-running fixed it.
- R5 counts the cage soul via its looping wisp ("CageWisp") rather than the soul mesh; either way 1 point.
- P4 / C3 / S1 move by 10-30 points between near-identical builds; the quality moved 95 <-> 96 on those alone.
- fixes.json B4 recipe (drop verts on the biggest mesh) was exact and useful; R5 recipe (energy >= 1.7) worked as stated.
