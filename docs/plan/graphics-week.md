# Graphics week (JS 2026-10-15: "use the rest of the week's usage on the graphics")

Goal: the most beautiful game possible in Godot on JS's RTX 3070 laptop, painted and readable, with
Low = the look before G1 (headless tests / labs unchanged). Every piece: before / after shots, fps at High / Ultra
(1080p targets: High >= 90, Ultra >= 60), Art Lab scorecard when it is a model, smoke + perf + its own test, contract
review, lead commit.

## Budget
- Weekly meter 57 % on 2026-10-15 13:20 UTC, resets 2026-10-18 05:00 UTC. Measured cost ~0.6 % weekly per agent task.
- Keep 8 % in reserve (lead, balance batch, the playtest build). Spend up to ~92 %: ~35 points = **~50 agent tasks**.
- Up to 6 agents at once while the 5-hour meter is under 50 % (3 above, 0 above 80 %). The real limit is the Godot gate
  (4 runs at once, windowed GPU shots): the balance batch runs 1 game at a time during the graphics week.
- Checkpoints: before each wave read the meters; at 85 % weekly stop launching new waves and finish with G-F.

- Shots (2026-10-15, after G-A put ~290 MB of PNGs in docs/art/lab): every shot folder gets an empty `.gdignore` first;
  git gets one contact sheet JPG + at most 4 key PNGs, the rest stays local (`.git/info/exclude`). C: had 9.5 GB free.

## Waves
| Wave | When | Agents | Pieces |
|---|---|---|---|
| **G-A** foundations | 10-15 (running) | 5 + 1 UI done | G1 lighting tiers (SSAO / SSIL / soft shadows / volumetric light / SSR / animated sky), G1 setting (done 97e10f6f), G2a ground + foliage, G2b water, G3a 4 wizards, G3b shared unit materials |
| **G-B** buildings + spells | 10-15 evening | 6 | Fire buildings, Ice buildings, Nature buildings, Shadow buildings (keep + tiers, Hall, houses, towers, Stables, walls), neutral buildings (tavern, Bazaar, trade posts, capture points, guilds), spell VFX pass (the 4 wizards' F / Q / E + caster spells) |
| **G-C** units | 10-16 morning | 6 | Hall units per kingdom (x4), champions (shapes + class weapons), mounts + titans |
| **G-D** world life | 10-16 afternoon | 6 | creatures / camps / beasts, map props (crown, crystals, lairs, landmarks), ambient life (birds, butterflies, leaves, dust, fireflies at night), combat feedback (hits, deaths, building collapse, debris), fog of war + selection rings + health bars in 3D (ui-coder), menu diorama + loading screens |
| **G-E** maps + consistency | 10-16 evening / 10-17 | 4-6 | per-map dressing (Crown Hollow, Thornwater, the other ready maps), art-direction review (one agent compares every kingdom side by side, lists clashes), fixes from the review, mission look check (one Ice, one night, one Nature mission) |
| **G-F** ship | 10-17 | lead + 1-2 | perf at Ultra with 200 units + Wave Strike, Art Lab census, full CI, playtest build `playtest-2026-10-17` (zip on the Desktop, OneDrive after JS's OK), notes in French |

Each wave starts only after the previous wave's review (the shared-material and lighting changes of G-A change how
every later model looks, so G-B / G-C build on them). G-B to G-E use the same brief shape as G-A: owner folder,
"never touch" list, tiers via `GameSettings.effective_graphics_quality()`, procedural / original only, no downloads.

## Progress (lead, 2026-10-15 ~16:20 local; weekly 62 %)
- Committed: G1 setting 97e10f6f + Ultra AA a787667b, G1 lighting e694aa3e, G3a+G3b 1f61a0ea, G2b water 09c78776, G2a grass
  3dfd52e5 + hook b91f5ed1, G-B Shadow 868fcc1a, fog ghost no_ghost cc860e32, G-B Fire 371f5844, spell VFX e6112f6f,
  neutral fd4f6dac, Nature 6683e181, forge model fallback bc47e251, i18n stable 3ee5a6aa.
- Also committed: G-B Ice 9d6c449e, G-C Fire units 160823cf, fog leaks (VfxFog + tests/test_fog_leak.gd) 4bb1ca8c.
- Running: G-C Shadow / Ice / Nature units, champions, mounts / titans; shader-lint fixes (then commit
  tests/test_shader_lint.gd); balance fs7-r5 (1 game at a time).
- Next: G-D world life (also: the white puffs on freshly built buildings,
  a no-grass mask under Shadow dead ground, Fire stables shader, forge models for Fire / Nature / Shadow); G-E; G-F build.
- Follow-ups: ui-coder `GameSettings.gfx_test_override` (handoff for-ui-coder.md); Art Lab B5 exception for Ultra-only
  building lights; hero vertex budget 4500; stagrunner garbled .tres lines; balance batch fs7-r5 runs 1 game at a time.

## Not in this week
Downloaded asset packs or textures (downloads need JS's OK and "everything original"), real-time GI (SDFGI) unless G1
proves it stable, a renderer change, Unreal.
