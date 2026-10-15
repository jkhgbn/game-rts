# G3a: the four wizard heroes (graphics pass, 2026-10-15)

Goal (JS: "make the graphics as beautiful as possible"): Vessa, Malrik, Torvald and Ysolde are the player's hero and are
seen up close (HUD portrait, cinematics, zoom 10), so they get a hero-only layer on top of their existing models.
Contract kept: same scenes, pivots (`Root/Hips`, `Root/Chest`, `Head`, `ArmL`, `ArmR`, `Fx`), node names (Staff, Orb /
Shard / Snowflake / Seed, Cape, Face), hooks, attack styles, casts, expressions, LOD tiers. Silhouettes and kingdom
colour reads are unchanged at zoom 30-50 (R1 / R2 / R6 / R11 all still PASS).

## What changed

### Shared hero layer (`art/units/wizards/wizard_model.gd`)
- **Rune bands** (`wizard_runes.gdshader`, new): procedural glyphs (no texture). Each glyph = a spine + 2-6 strokes
  picked by a hash (chevrons, arms, cross bar, a ring), anti-aliased distance strokes on an inlay with two border lines.
  Glyphs breathe with a per-glyph phase and a bright wave runs along the band. `glow_boost` (kit slot 5, like
  `unit_glow`) is driven by the kit (veterancy / haste up, death to 0); the new instance uniform `flare` (slot 13, added to the kit's `INSTANCE_SLOTS` and README slot table) is
  written by `WizardModel._extra_process` from the cast / attack / level-up boost, so the runes blaze on every cast.
  API: `rune_material(key, base, rune, cells, aspect, energy, seed)`, `rune_ring(y0, y1, r0, r1, seg, rot_deg, arc_deg)`
  (matches a faceted robe: same facets, 1.2 cm off), `rune_strip(top, bottom, w, face)`, `add_runes(pivot, key,
  [[arrays, material], ...])` -> one keep_separate `Runes` node, mesh + materials cached per type, shadows off.
- **Kingdom aura** (`add_aura(kind, parent, at)`, node `HeroAura`): fire embers rising from the hem (14), shadow soul
  wisps spiralling up (10), ice snow motes drifting down around him (14), nature fireflies blinking around her (9).
  Looping, world-space (it trails when she walks), shared process / draw resources. It emits only when the camera is
  within `AURA_RANGE` 36 m (zoom 10 = 10-30 m, the HUD portrait, cinematics; off at the usual zoom 30-50) and the
  Graphics quality is Medium or better (`GameSettings.effective_graphics_quality()`, re-read every 60 frames). Below
  Medium the GPUParticles3D is never created (so no aura node in a headless / `-s` run unless `-- --gfx=<tier>`).
  It is driven from `WizardModel._process` after the kit's `_process` (not `_extra_process`, which the kit skips while
  the model is frozen): off while dead or frozen (far tier / off-screen). Test hook:
  `WizardModel.aura_quality_override` (>= 0 forces the tier the aura sees).
- Ruling (lead, 2026-10-15): the shape detail and the rune bands stay on every graphics tier; only the aura is gated.

### Per wizard
| Wizard | Rune band | New shape detail | Aura |
|---|---|---|---|
| Vessa (fire) | gold-ember glyphs round the gown above the flame tongues (16 facets) | a peplum of 11 gold / orange flame tongues under the belt (second skirt layer), two leather belt pouches with bronze flaps and studs, a bronze bead chain with an ember-glass drop, staff leather grip wrap + 3 bronze bands + 2 crimson ribbons with ember beads | embers |
| Malrik (shadow) | violet glyphs round the robe (8 facets, passes behind the stole) + a vertical rune strip down the stole | a chained grimoire on the off hip (leather, bone pages, silver clasp), a bone skull charm on a silver / bone bead chain, staff silver bands + a chain with a silver ring under the claw | soul wisps |
| Torvald (ice) | cyan glyphs round the robe above the frosted hem (10 facets) + a rune strip down the front panel | leather belt pouches with frosted-iron flaps, two hanging iron rune tablets on a silver chain | snow |
| Ysolde (nature) | glowing sap glyphs round the bodice above the bark belt (12 facets) | a bark seed satchel with a leaf flap on its cord, a living vine (10 segments + 3 leaves) wound round her off sleeve | fireflies |

## Measures

Art Lab before / after (`docs/art/lab/g3a_wizards/before|after/<wizard>/`, lab v3.1, meadow, warm light):

| Wizard | Quality before -> after | B4 body verts (budget 3000 soft) | Draw instances (<= 16) | Notes |
|---|---|---|---|---|
| Vessa | 94 -> 93 | 3570 -> 4492 (WARN, was WARN) | 12 -> 13 | R5c 88 -> 83 (the rune band is now her bloom point next to the orb; still PASS) |
| Malrik | 93 -> 90 | 3530 -> 4296 (WARN, was WARN) | 12 -> 13 | new R5c WARN dL -4: his 2 VoidMotes now count as a glow point and the brighter ring sits in their 1 m surround (rune energy already lowered 2.4 -> 1.7) |
| Torvald | 95 -> 94 | 2908 -> 3253 (PASS -> WARN) | 12 -> 13 | |
| Ysolde | 91 -> 91 | 6984 -> 7434 (WARN, was WARN) | 13 -> 14 | R4 heath contrast WARN gone |

Every other check is unchanged (0 FAIL). The quality points lost are the vertex budget (B4) and R5c.
**Budget note (hero exception):** the wizards are the four heroes, one per player on the map, seen at zoom 10 and in
portraits, so the body vertex budget is raised for them by ~350-920 vertices (the wizard row in
`tools/art_lab/lab_budgets.gd` is unchanged: the lead decides whether the `unit/wizard` soft `verts` budget goes to
~4500). Frame cost B13 stays PASS; perf_test PERF OK.

Windowed shots in a 1v1 skirmish (Crown Hollow, `--gfx=high`, the 4 models next to the player's Vessa):
`docs/art/lab/g3a_wizards/skirmish_z10.png`, `skirmish_z40.png`, close-ups `close_vessa|malrik|torvald|ysolde.png`
(own camera 4.6 m away; Malrik and Ysolde mid-cast).
Reproduce: `tools\godot_run.ps1 --path . -s tests/test_g3a_wizards.gd --fixed-fps 60 --quit-after 8000 '--' --shots --gfx=high`
(quote the `'--'` in PowerShell; the shot script unpauses the STR / INT chooser and hides the HUD).

## Tests
- `tests/test_g3a_wizards.gd` (headless): phase A (real tier = Low): pivots, hooks, Staff / Orb nodes, the `Runes`
  node on wizard_runes with shadows off, rune mesh shared per type, no `HeroAura` built, the runes flare on a cast;
  walk / attack / 3 casts / expression / level-up / death / revive on 2 instances of each wizard. Phase B (forced High):
  the `HeroAura` exists (looping, <= 16, material shared per type), emits with the camera 7 m away, stops with the
  camera 110 m away (frozen model), comes back, stops on death, comes back on revive.
- Still PASS: smoke (victory=true), perf (PERF OK), test_9_v4, test_a17, test_a2_10, test_unit_dances, test_13_v1b,
  test_tool_lens, test_6_u1, test_9_c7. test_art_lab FAILs on "v3 stage autumn preset and back" (the lab stage's
  lighting presets: G1 lighting work, not the wizards).

## Ideas left for a next pass
Faces (FaceKit, art/units/kit: G3b's area now), cloth sway on Torvald's merged mantle, per-finger hands, a ground
sigil under the selected hero at close zoom.
