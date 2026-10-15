# G-F round 2: ground rings, road grass, butterflies, the m00 disc (2026-10-15)

Review items 5, 14 and 15 of `docs/art/gf_review2.md`. Look only: no gameplay radius, timer or rule changed.

Shots (windowed, `--gfx=high`, 1600x900): `docs/art/lab/gf_r2_ground/` (`.gdignore`)
- `gfr2_contact_sheet.jpg`: before / after pairs
- key PNGs: `key_spire_before_after.png`, `key_mammoth_before_after.png`, `key_road_before_after.png`, `key_m00_disc.png`
- tool: `docs/art/lab/gf_r2_ground/tools/gfr2_ground_shots.gd` (`--mode=rings | road | m00`, `--tag=before|after`;
  m00 mode also logs every wide disc-like mesh added in the first seconds) and `tools/sheet.py` / `tools/grid.py`.

## Item 5: big pale ground rings

| What | Cause | Fix |
|---|---|---|
| Bramble Spire ring (r 8) | Drawn **twice**: the spire model's own AuraRing (4 s, alpha 0.6, a texture with a faint fill) and NatureVfx's pulse (4 s, lime, fill 0.04), because the model had no `draws_aura_pulse()`. | `nature_spire.gd`: `draws_aura_pulse() -> true` (one ring), period 7 s (grow 2.8 s, then nothing for 4.2 s), a rim-only texture (`rim_texture()`, nothing inside 90 % of the radius), peak alpha 0.3 that thins out as it grows, colour = team / kingdom glow capped at saturation 0.55, value 0.78 (`aura_color`). |
| NatureVfx fallback spire pulse | lime LEAF ring + fill | 7 s, `SPIRE_RIM` moss-lime, ring alpha 0.5, no fill (`_ring(..., ring_a)` optional arg). Only runs for a Nature aura building whose model does not draw its own. |
| War Mammoth frost aura (r 5) | the "pale glass disc" was mostly the rime-mist emitter (14 puffs 0.9-1.5 m, HDR white, alpha 0.26 at the rim) plus the shader's wide fringe and inner wash | `titan_mark.gdshader` pattern 0: no wash, fringe within 0.5 m, a faint thin rime line, 12 crystal ticks (was ~50 teeth), the rim brightens once every 7 s with a short chill ripple (was a ripple every 2 s). Mist puffs 0.5-0.85 m, alpha 0.12, not HDR. Never a filled disc. |
| Elder Treant grove pulse (r 8) | bright LEAF_GLOW band + wide trail wash | thinner band, trail 0.9 m (was 1.6), about half the alpha / emission, `GROVE_RIM` moss-lime. **Cadence kept at 4 s**: `tests/test_13_v19.gd` (not mine) needs 2 pulses within ~5 s of rooting; moving it to 7 s needs that test's frame window widened first. |
| "Unit heal / support pulse" | none found: the Bloomtender heal (NatureVfx / IceVfx) is a beam + pollen + `+`, no ground ring. The big lime ring in review tile 24 is the Bramble Spire built next to the lineup. | nothing to change. The Mossback canopy pulse (`unit_nature_t3_vfx.gd`) has no unit using its model in game, left as is. |

## Item 14: road grass and butterflies

- `art/environment/ground.gdshader`: the grassy crown between the wheel ruts (trade roads and the lane) was the plain
  meadow green at 75-80 %, thresholded on a low-res noise (blocky blobs). Now `worn_grass()`: darker, about 30 %
  greyer and mixed 26-48 % with the road dirt, with a ragged soft edge (micro noise on the lateral distance, a wider
  ramp). The trodden spots' grass islands get a softer, raggeder edge and 36 % grass (was 45 %). No new texture reads
  (shader lint B), no branches; autumn / biome params untouched.
- Butterflies about 60 %: `ambient_life.gd` wings 0.8-1.0 (was 1.3-1.7), `critters/critter_system.gd` flower-patch
  butterflies 0.72-0.88 (was 1.2-1.45).

## Item 15: the m00 grey disc

It is `MissionBase.flash_ring` (scripts/campaign/mission_base.gd, not art): when the first Flame Guard appears (m00's
spotlight, trigger `start`) it adds a flat white `CylinderMesh` r 2.5 (5 m) at alpha 0.7 fading in 1 s, with fog on, so
the night fog greys it. Logged at t ~6.8 s of the m00 start by the shot tool. Art fix ready: `art/vfx/mission_flash_ring.gd`
(`MissionFlashRing.play(parent, pos, radius)`: a thin warm-gold additive rim, fog disabled, grows 0.7 -> 1 r, fades in 1 s,
a soft warm light). Request in `docs/handoff/for-lead.md` (swap the flash_ring body for that call, and
`disable_fog = true` on `_gold_ring`'s material). The m00 after shot still shows the old disc until that lands.

## Tests

`tests/test_gf_r2_ground.gd` (spire: one ring, 6-8 s, rim-only, peak alpha <= 0.3, off >= 45 % of the time, capped colour;
NatureVfx fallback; frost aura source; worn-grass crowns; butterfly scales; MissionFlashRing additive / no fog / no fill /
frees itself). Also green: test_shader_lint, test_ge_additive_fog, test_gf_death_fx, test_gd_ambient, test_gd_combat,
test_13_v19, test_12_v16, test_a2_6, smoke (victory=true).
