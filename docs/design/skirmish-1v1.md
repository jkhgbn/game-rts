# Skirmish 1v1: Fire (Vessa, player) vs Shadow (Malrik, bot)

Source of truth for 2.S3 (mirrored map, win / lose, wizard respawn), 2.S2 (start camera) and the map facts
used by `ai.md` (2.A1). Written 2026-09-25 (task 2.D1) after playtest 1. Replaces the "mission 1" layout of
`units-fire-shadow.md`, the node table of `economy.md` and the win / lose table of `gdd.md`.
Both sides are **identical** except kingdom, colour and start corner, so the same map becomes PvP later:
the bot only uses public APIs (`command_*`, `Economy`, `Building` queues, `BuildGrid.place`).
Metres, seconds; positions are `(x, z)`, `y = 0`. World `+x` = east, `+z` = south (down on the minimap).

## Map: "Crown Hollow" (120 x 120, same size as today)
Point-mirrored through the centre: everything at `(x, z)` on the Fire side exists at `(-x, -z)` on the Shadow side.
| Constant (`main.gd`) | Value | Note |
|---|---|---|
| `PLAYER_START` | `(-36, 36)` | Unchanged. Vessa spawns here, Fire keep at `PLAYER_START + (-7, 7)` = `(-43, 43)` |
| `SHADOW_START` (new) | `(36, -36)` | Malrik spawns here, Dusk Keep at `(43, -43)` |
| `ARTIFACT_POS` | `(0, 0)` | The Ember Crown, dead centre (was `(34, -34)`) |
| `MID_CAMP` | `(0, 0)` | The neutral camp ring is around the crown (was `(-2, 2)`) |

### Crystal nodes (replaces the table in `economy.md`; same look, same 3-workers-per-node rule)
| id | Position | Crystals | Note |
|---|---|---|---|
| `node_fire_a` | `(-46, 34)` | 900 | = old `node_home_a`; 9.5 m from the Fire keep |
| `node_fire_b` | `(-34, 46)` | 900 | = old `node_home_b` |
| `node_fire_mid` | `(-16, 6)` | 900 | Fire's natural expansion: 46 m from the Fire keep, 77 m from the Dusk Keep |
| `node_shadow_a` | `(46, -34)` | 900 | Mirror |
| `node_shadow_b` | `(34, -46)` | 900 | Mirror |
| `node_shadow_mid` | `(16, -6)` | 900 | Shadow's natural expansion |
`node_mid` and `node_ruins` are removed. Home nodes go from 600 to 900 so a 6-worker base lasts ~5 min.
**Drop-off**: workers deliver to the nearest **completed keep or barracks** of their team (was: the keep only).
A barracks' drop-off point is its spawn corner (`buildings.md`). This is what makes the natural expansion
worth taking: build an Ember Hall / Gloom Hall next to your mid node.

### Middle: the crown and its guards
- The Ember Crown sits at `(0, 0)` on the existing pedestal. Ruined pillars: 10 in a ring of radius 8 around it,
  gaps at `i = 4` (facing Fire) and `i = 9` (facing Shadow); the old ring around the old artifact spot goes.
- **Neutral camp: 4 Ruin Wardens** on team `NEUTRAL` (hostile to both), at `(cos(a) * 4, sin(a) * 4)`,
  `a = TAU / 8 + i * TAU / 4`, idle with the normal auto-aggro and 2x leash to their spot. They never respawn.
| id | Display name | max_hp | dmg | range | cooldown | speed | aggro | radius | height | Colour | Cost / pop | faction |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `ruin_warden` | Ruin Warden | 150 | 12 | 1.6 | 1.0 | 4.0 | 7 | 0.5 | 1.8 | `(0.45, 0.50, 0.40)`, eyes `(1.0, 0.85, 0.3)` | 0 / 0 | `neutral` |
  Needs `Unit.Team.NEUTRAL` (a third enum value; `is_enemy_of` already treats any other team as an enemy) and
  one `data/units/ruin_warden.tres` (gameplay's folder: one-time permission for 2.S3, as in wave 1 session A).
  The camp is worth ~600 HP: 5-6 soldiers plus a wizard clear it around 4:00-6:00 with a loss or two.
- **Ember Crown** (bonus objective, first wizard within `pickup_radius` 2.2 takes it):
| Effect | Value |
|---|---|
| Wearer | **+100 max HP** (healed by 100 on pickup) and **+50 max mana**. Existing `claim_artifact` is reused with `bonus_fireball_damage` = 0 |
| On the wearer's death | The crown **drops** at the death spot (nearest navmesh point) after 3 s and can be taken again by either wizard; the bonus is removed from the dead wizard |
| Message | `Vessa wears the Ember Crown` / `Malrik wears the Ember Crown` / `The Ember Crown lies unclaimed`; `Events.artifact_claimed(artifact, wizard)` each time it is taken |
| Objective line | `Ember Crown: unclaimed` / `worn by Vessa` / `worn by Malrik` (replaces the wave 1 objective text) |

### Forest and rocks (the generator in `main.gd`)
- Keep the generator, but every tree and rock placed at `p` is **also placed at `-p`** (perfect mirror), and
  only positions with `x + z < 0` (the Fire half) are drawn from the rng; the mirror covers the other half.
- Keep the lane: `_in_path_lane` now runs from `PLAYER_START` to `SHADOW_START`, width **5** (unchanged).
- Clearings (no trees or rocks), Fire half, mirrored automatically: `PLAYER_START` r 18 (was 12; the base
  needs room for 6 buildings), `(-16, 6)` r 7 (natural node + forward hall), `(0, 0)` r 12 (the crown).
- Scattered rocks: 11 drawn, 22 after the mirror (same count as today).

## Start state (identical for both sides)
| Item | Fire | Shadow |
|---|---|---|
| Crystals | 250 | 250 |
| Keep | `(-43, 43)`, 1500 HP, trains only workers | `(43, -43)` |
| Wizard | Vessa at `PLAYER_START`, full HP and mana | Malrik at `SHADOW_START` |
| Workers | 3 Cinder Hands at `PLAYER_START + (-4 + i*1.2, 4 - i*1.2)`, already gathering (2 on node a, 1 on node b) | 3 Gloom Thralls, mirrored positions and nodes |
| Soldiers | **None** | None |
| Population | 3 / 20 | 3 / 20 |
| Buildings | Keep only | Keep only |
Nothing else is pre-placed for either kingdom. The natural opening for both is Ember Hall / Gloom Hall (150)
at once, then workers to 6. Vessa can bully enemy workers early; so can Malrik.

## Wizard death and respawn (replaces "wizard death = instant loss")
| Rule | Value |
|---|---|
| Respawn delay | **30 s + 15 s per previous death**, max 90 s (30, 45, 60, 75, 90, 90...) |
| Where | The team's keep spawn point; if the keep is gone, the spawn corner of its oldest living barracks; no building = the team has already lost |
| State on return | Full HP and mana, no crown, spells off cooldown, selected automatically (player side) |
| While dead | Hero column: name greyed, bars at 0, text `Vessa returns in 24 s`; F1 / Space centre on the keep; no spells. The team keeps playing |
| Home healing | Wizards regenerate **1 % of max HP per second** while within **15 m** of their own keep (Vessa 3.5 / s, Malrik 4 / s). Nothing else heals wizards |
| Messages | `Vessa has fallen! She returns in 30 s` / `Malrik has fallen back into the shadows` (existing line) |
Why change the old rule: a 15-minute match should not end on one over-extended Fireball; the rule must be
symmetric for PvP, and "instant loss" would make sniping Malrik the only strategy against the bot. The
growing timer and the dropped crown keep the wizard precious without sudden death. Campaign missions may still
use instant loss later; it is a per-mission flag, default off.

## Win / lose
| Event | Result |
|---|---|
| A team has **no living building** (keep, halls, hearths / hovels, spires; construction sites count as living) | That team loses: `Events.mission_ended(victory)` with `victory = true` for the other team |
| Surrender | **F10 twice within 3 s** (first press shows `Press F10 again to surrender`) = defeat |
| Bot concedes | The bot surrenders when it has no barracks, no workers, fewer than 100 crystals and no soldiers (nothing can recover). Message: `Malrik: "Keep the crown. I will be back for it."` |
| Wizard dies | Not a loss (respawn table above) |
| Crown taken | Not a win, only the bonus |
Checked every 0.5 s by `main.gd`; the first team to hit the rule loses (both in the same tick = the player loses,
never a draw). After the end: unit orders and the bot stop, the camera stays free, the simulation keeps running
so the scene reads as a battlefield.

## Match timer and end screen
- Top bar gains a third item: elapsed time `m:ss` (font 20, white), 48 px after the pop item; the panel widens
  to 400 x 40 at `(600, 8)`. Time starts when the navmesh is ready.
- End screen (wave 2 minimum, `show_banner` + one block; 3.U2 makes it pretty):
```
VICTORY / DEFEAT
Match time 12:34
Units trained 28 · Units lost 19 · Enemy units killed 31 · Buildings destroyed 5
Crystals gathered 2 640
F9: play again
```
- Stats come from `Events.unit_died` (by team), `Building.destroyed` (by team), keep / barracks spawns and
  `Economy.add` totals, counted by `main.gd` from the start of the match.

## Start camera and hint (2.S2, unchanged intent)
The camera starts framing the Fire keep and the 3 workers above the HUD (keep in the upper half of the screen);
hint `Click your Keep to train workers, then B with a worker selected to build an Ember Hall`. The Shadow side
uses the mirrored camera position (for PvP later).

## What changed from the wave 1 map
- Artifact and mid camp move to `(0, 0)`; the camp becomes 4 neutral Ruin Wardens instead of Shadow units.
- No pre-placed soldiers on either side; the Shadow side is a mirrored, playable base.
- Nodes: 6 (3 per side, 900 each); drop-off at keep **or** barracks.
- Wizard death = respawn, not defeat; defeat = no buildings left.
- The old `MID_CAMP` guards, `ARTIFACT_POS + ...` spawns, `node_mid`, `node_ruins` and the artifact ring at
  the old spot are removed. The smoke test (lead) must change to the new win rule.

## Done when
- [ ] 2.S3: the map is point-symmetric (keeps at `(-43, 43)` / `(43, -43)`, the 6 nodes above, trees and rocks mirrored, lane kept, clearings as listed); both teams start with 250 crystals, keep, wizard, 3 gathering workers, 3 / 20 pop, no soldiers.
- [ ] 2.S3: 4 Ruin Wardens on team `NEUTRAL` at the crown attack both teams; the crown gives +100 HP / +50 mana, drops on the wearer's death and can be retaken.
- [ ] 2.S3: a dead wizard respawns at the keep after 30 / 45 / 60 / 75 / 90 s with full HP; the hero column counts down; wizards heal 1 % / s within 15 m of their keep.
- [ ] 2.S3: losing every building ends the match (`mission_ended`), F10 x2 surrenders, the top bar shows `m:ss`, the end banner shows the 5 stats.
- [ ] 2.S3 test: headless, kill Vessa -> she is back at the keep spawn point 30 s later; destroy every Shadow building -> `victory=true`; destroy every Fire building -> `victory=false`; a worker on `node_fire_mid` with a completed Ember Hall at `(-23, 9)` delivers there, not at the keep.
- [ ] 2.A1: the bot plays the Shadow side of this map with no extra pre-placed units (`ai.md`).
