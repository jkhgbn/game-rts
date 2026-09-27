# Spells: Fire and Shadow (wave 2)

Source of truth for 2.G1 (framework), 2.G2 (the 6 spells), 2.G3 (Malrik casts by himself), 2.U2 (icons,
cooldowns, tooltips) and 2.U3 (effects). Written 2026-09-25 (task 1.D1).
Ranges and radii in metres, times in seconds. Fireball and Shadow Lance keep their wave 1 numbers.

## Wizard mana (unchanged)
| Wizard | Mana | Regen / s | Start of mission |
|---|---|---|---|
| Vessa | 100 | 4 | Full |
| Malrik | 100 | 4 | Full |

## Framework rules (2.G1)
- `Wizard.command_cast(spell_id, target) -> String`. Reasons, in this order: `"Dead"`, `"Unknown spell"`,
  `"Not learned"` (wave 3, `levels.md`), `"On cooldown"`, `"Not enough mana"`, `"Invalid target"`. `""` = accepted.
- **Wave 3 (`levels.md`)**: the tables below are **rank 1**; ranks 2-3, level requirements, spell points and the
  Ctrl+F / Q / E learn flow are in `levels.md`. Mana costs never change with rank. Malrik's AI rules below skip
  a spell he has not learned.
- Target types and what `target` is: **point** = `Vector3` on the ground; **unit** = a `Unit`; **self** = ignored
  (pass `null`); **area** = `Vector3` centre (the spell applies in a circle there).
- Out of range is not a refusal: the wizard walks toward the target and casts when in range (today's Fireball
  behaviour). Cancelled by any new order. A unit target that dies on the way cancels the cast, no cost.
- Mana and cooldown are paid **at the moment of the cast**, not when ordered. Cast is instant (no cast time).
- Point / area targets must be on an **explored or visible** fog cell; unit targets must be **visible**
  (see `fog-of-war.md`). Otherwise `"Invalid target"`.
- Spell data lives in `data/spells/<id>.tres` (`SpellType`: `id`, `display_name`, `hotkey_label`, `target_type`,
  `mana_cost`, `cooldown`, `range`, `radius`, `damage`, `duration`, `icon_abbrev`, `tooltip`). Numbers from the
  tables below.
- Statuses (timed stat modifiers, needed by Kindle and Umbral Shroud). Unit gets `apply_status(id, duration)`;
  re-applying refreshes the timer, never stacks. Only two ids exist in wave 2:
| id | attack cooldown x | move speed + | damage taken x | Shown as |
|---|---|---|---|---|
| `haste` | 0.70 | +1.5 m/s | 1.0 | Small flame above the head |
| `shroud` | 1.0 | +2.0 m/s | 0.5 | Body alpha 0.4 + purple smoke |
  The lead adds `apply_status` to the Unit contract.

## Hotkeys and card slots (both wizards use the same three keys)
Physical keycodes; letters printed are QWERTY positions (`KEY_F`, `KEY_Q`, `KEY_E`), per the Keys line in
`CLAUDE.md` (spells 1 / 2 / 3 = F / Q / E; W A S D walk the wizard, so no spell ever uses those letters).
| Slot on the wizard's card | Key | Vessa | Malrik |
|---|---|---|---|
| r2c1 | F | Fireball | Shadow Lance |
| r2c2 | Q | Ember Step | Soul Siphon |
| r2c3 | E | Kindle | Umbral Shroud |
Mixed selection with a wizard: the three spell buttons take r2c1-r2c3 and **Gather G moves to r2c4** (this
replaces the "Mixed units" row of `ui-hud.md` from wave 2). Point / area / unit spells use the cross cursor
(left-click confirms, right-click or Esc cancels); a self spell casts on key press. Area spells draw the
radius as a flat ring under the cursor while targeting.

## Vessa (Fire)
| id | Name | Key | Target | Mana | Cooldown | Range | Radius | Effect |
|---|---|---|---|---|---|---|---|---|
| `fireball` | Fireball | F | point | 40 | 0 (mana-limited) | 16 | 3.5 | 60 damage to every enemy unit and building in the circle. Unchanged from wave 1 |
| `ember_step` | Ember Step | Q | point | 30 | 12 | 12 | 2.5 (scorch) | Vessa is moved instantly to the closest navmesh point to the target (`NavigationServer3D.map_get_closest_point`). The spot she left becomes **scorched ground** for 4 s: enemies inside take 5 damage every 0.5 s (10 / s). Her current order is cleared (she stops) |
| `kindle` | Kindle | E | self | 50 | 30 | - | 8 | Vessa and every friendly **non-worker** unit within 8 m get `haste` for 8 s |

Ember Step is not a refusal when the point is off the navmesh: it uses the closest navmesh point, clamped to
12 m from Vessa. It never crosses fog rules (point must be explored).

## Malrik (Shadow)
| id | Name | Key | Target | Mana | Cooldown | Range | Radius | Effect |
|---|---|---|---|---|---|---|---|---|
| `shadow_lance` | Shadow Lance | F | unit | 35 | 8 | 12 | - | Bolt, 50 damage; Malrik heals **50 % of the damage actually dealt**. Unchanged from wave 1 |
| `soul_siphon` | Soul Siphon | Q | area | 45 | 20 | 12 | 4 | Dark circle for 5 s: enemies inside take 4 damage every 0.5 s (8 / s, 40 total). Malrik heals 50 % of all damage dealt by the circle, on each tick, even if he walks away |
| `umbral_shroud` | Umbral Shroud | E | self | 40 | 25 | - | - | Malrik gets `shroud` for 5 s (takes half damage, +2 m/s) |

## AI casting rules for Malrik (2.G3)
Checked every 0.5 s while alive. `P` = player units within 12 m of Malrik. First rule that applies casts; at
most one cast per check.
1. **Umbral Shroud** if HP < 35 % of max and it is ready and mana >= 40. Then, if not already doing so, Malrik
   walks to his anchor (his spawn position; the AI in wave 3 replaces the anchor with his keep).
2. **Soul Siphon** if ready, mana >= 45, and some unit `u` in `P` has **at least 3** player units within 4 m of it
   (count includes `u`). Centre = position of the `u` with the highest count (ties: nearest to Malrik).
3. **Shadow Lance** with the wave 1 rules (unit with HP <= 50 and the highest HP among those; else if Malrik
   HP < 60 % the highest-HP unit; else Vessa; else nearest), if ready and mana >= 35.
4. Nothing.
Rules 2 and 3 also run while Malrik is shrouded.

## Icons, cooldowns, tooltips (2.U2)
- Button icon (wave 2 placeholder): 2-letter abbreviation at font 18: `FB`, `ES`, `KI`, `SL`, `SS`, `US`.
- On cooldown: a dark overlay `(0, 0, 0, 0.6)` that shrinks from the bottom as it recharges (height =
  remaining / cooldown x 64 px) and the remaining seconds (rounded up, font 16, white) in the centre.
  Not enough mana: `disabled`, alpha 0.45, tooltip line `Not enough mana`.
- Tooltip format (same as `ui-hud.md`): `Ember Step  [Q]\n30 mana · 12 s cooldown · range 12\nBlink to a point. The ground you leave burns for 4 s.`
  Lines for the others: Fireball `40 mana · 60 damage · radius 3.5` / `Burns everything in the circle.` ·
  Kindle `50 mana · 30 s cooldown · 8 s` / `Nearby soldiers strike faster and run faster.` ·
  Shadow Lance `35 mana · 50 damage · range 12` / `Heals Malrik for half the damage.` ·
  Soul Siphon `45 mana · 20 s cooldown · radius 4` / `Drains everyone in the circle for 5 s.` ·
  Umbral Shroud `40 mana · 25 s cooldown · 5 s` / `Half damage taken, faster movement.`
- Hero column mana bar already exists; add the 3 cooldown overlays only on the command card.

## Effects, one line each, primitives + `GPUParticles3D` (2.U3)
| Spell | Look |
|---|---|
| Fireball | Existing: orange sphere projectile, burst of 24 orange sparks on impact, flat scorch disc radius 3.5 fading over 1.5 s |
| Ember Step | Vessa's mesh alpha 1 -> 0 in 0.15 s at the origin and 0 -> 1 in 0.15 s at the destination; 20 `(1.0, 0.6, 0.2)` sparks at both spots; scorch = flat disc radius 2.5 `(0.15, 0.05, 0.02)` with an emissive orange ring `(1.0, 0.45, 0.1)` and 30 low flame particles, all fading over the last 1 s |
| Kindle | A flat ring `(1.0, 0.6, 0.2, 0.6)` at Vessa's feet scales from radius 0 to 8 in 0.4 s then fades in 0.3 s; each hasted unit shows a 0.3 m flame billboard above its head for 8 s |
| Shadow Lance | Existing: straight purple bolt `(0.7, 0.3, 1.0)`, Malrik flashes purple `(0.7, 0.3, 1.0)` for 0.2 s when healed |
| Soul Siphon | Flat disc radius 4 `(0.15, 0.05, 0.25, 0.7)` with a slowly rotating darker ring; 40 purple particles rise from the disc and drift toward Malrik; every tick Malrik flashes as for Shadow Lance |
| Umbral Shroud | Malrik's body alpha 0.4, 40 purple smoke particles `(0.4, 0.2, 0.6)` in a 1.2 m cylinder around him, a translucent sphere radius 1.4 `(0.2, 0.05, 0.35, 0.25)`; all removed when the status ends |

## What changed from wave 1
- New: Ember Step, Kindle, Soul Siphon, Umbral Shroud, statuses `haste` and `shroud`, `SpellType` resources.
- Malrik's cast rules gain rules 1 and 2 above; rule 3 is the wave 1 rule set.
- Mixed-selection card: spells in r2c1-r2c3, Gather in r2c4.

## Done when
- [ ] 2.G1: `command_cast` returns the reasons in the order above; mana and cooldown paid at cast; walks into range; point/unit/self/area handled; `apply_status(haste|shroud)` changes cooldown, speed, damage taken and expires; re-apply refreshes.
- [ ] 2.G2: the 6 spells use exactly the numbers in the two tables (test: Fireball 60 in radius 3.5; Ember Step moves Vessa 12 m and the scorch deals 40 over 4 s to a unit standing in it; Kindle halves-ish cooldowns (x0.70) for 8 s; Soul Siphon deals 40 over 5 s and heals Malrik 20; Umbral Shroud halves damage taken for 5 s).
- [ ] 2.G3: Malrik casts Umbral Shroud under 35 % HP, Soul Siphon on a cluster of 3, otherwise Shadow Lance; never two casts in one 0.5 s check.
- [ ] 2.U2: three spell buttons at r2c1-r2c3 with keys F Q E, cooldown overlay + seconds, mana-disabled tooltip, Gather at r2c4 in mixed selection.
- [ ] 2.U1 (wave 2, before the spells exist): the Fireball button at r2c1 answers F; Q and E do nothing yet and never trigger another order.
- [ ] 2.U3: every row of the effects table is visible in play and removed when its spell or status ends; nothing in `scripts/ui/` or `scripts/vfx/` calls a `_private` function.
