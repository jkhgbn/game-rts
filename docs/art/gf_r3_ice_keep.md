# G-F review 3, item 1: calm the Ice keep (2026-10-15)

Source: `docs/art/gf_review3.md` top 6, item 1. The Ice keep was the loudest object on any map: a near-white crystal
spire, glowing crack veins at full HP, a strong inner glow and rim. Its 20 % HP damage smoke was a small dark blob.

## What changed (`art/buildings/ice_keep.gd`, run-time overrides; the `.tscn` is unchanged)
- **Team crystal**: `IceKeep.crystal_color(team)` = the team colour paled 40 % toward `CRYSTAL_PALE_COLOR`
  (0.78, 0.84, 0.90), then `MoteCap.cap` at value `CRYSTAL_VALUE` 0.6. The hue is kept, so team colours still read on the
  main palette (0.45, 0.75, 0.95) and the mirror palette (0.5, 0.36, 0.86). Before, it was `team.darkened(0.15)`
  (value ~0.81).
- **Glow x0.5**: `GLOW_BOOST` 0.3 -> 0.15 (core, halo, gate), the crystal's `ip_ice_glow` 1.0 -> 0.5 and `ip_light_rim`
  0.26 -> 0.13, idle rim 0.2 -> 0.1, crown light 1.5 -> 0.75 (flashes scaled the same way).
  The small warm windows keep their bloom (instance `boost` `POINT_BOOST` 3): they are the keep's glow points at 40 m.
  Art Lab R5 asks for 4-12 such points.
- **Crack veins only below 50 % HP** (`VEIN_HP`). `crack_strength` (emissive veins on stone / crystal) is 0 at 50 % HP
  and above. Each material's own value comes back below 50 % HP and on the collapse. The crystal's white fracture lines
  (`damage` on the crystal material) follow the same rule; the stone still shows its cracks from damage.
- **Damage smoke** (Smoke1 / Smoke2, below 50 % HP): now a soft grey column.
  - It uses the keep's own alpha-blended ParticleMix soft dot. No new material.
  - Colour: grey (0.56, 0.59, 0.63) through `MoteCap.ramp`, alpha 0.55, value <= 0.72.
  - Particles: 3.4 m quads (`MoteCap.sized`), 5 s life, about 8 m rise, a small drift.
  - Same 30 particles. Low keeps the old 2.6 m quad, so Low costs no more than before.
  - The process materials are shared, so their values are set, never scaled.

## Numbers (windowed, `--gfx=high`, p98 value per screen band)
| Shot | Before | After |
|---|---|---|
| Row, Ice main keep | 0.820 | 0.722 |
| Row, Ice mirror keep | 0.784 | 0.686 |
| Ice close-up, full HP | 0.847 | 0.780 |

**Art Lab `ice_keep`:**
- Before: 87, PASS, all checks passing.
- After: 86 (86.1), PASS. 0 FAIL, 0 WARN, 21 PASS.
- R5 (glow points) is still PASS: 9 points (windows, crown shards, gatehouse, crystal).
- Two INFO checks went down:
  - P3 "tops light" (+12 -> +5 L*). This is the requested change: the white spire was the bright top.
  - C4 (inner detail): -2, because the veins are hidden at full HP.
- A paler crystal (50 %) gave back 7 on P3, but it made the colour-blind team split (R6cb) worse. I kept 40 %.

## Shots
`docs/art/lab/gf_r3_ice_keep/`:
- `contact_sheet.jpg`: left = before, right = after. Rows:
  1. Fire / Ice main / Ice mirror at RTS height.
  2. Close-up at full HP.
  3. 20 % HP.
  4. Mirror palette at 20 % HP.
- `before_row.png`, `after_row.png`, `after_ice_full.png`, `after_ice_20.png`.

The before 20 % shots were taken about 1.6 s after the damage (an older frame-count wait), so their smoke had not
risen yet. The after shots wait 5.5 s in real time. Only the after smoke column is a fair picture.

## Tests
`tests/test_gf_r3_ice_keep.gd` (headless test; `shots=1 tag=before|after out=<dir>`; `sheet=1 out=<dir>`).

It checks:
- The crystal value is between 0.35 and 0.6 for 10 team colours.
- The crystal hue stays within 0.06 of the team hue, and the main and mirror crystals stay apart.
- The glow caps.
- Veins are off at 100 / 80 / 50 % HP and on at 45 % HP.
- The smoke at 20 % HP: drawn size > 1 m, MIX blend, value 0.4-0.72, rise >= 6 m, at most 30 particles, off at full HP.
