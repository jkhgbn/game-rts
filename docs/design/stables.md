# The Stables: 16 mounted units (Stables16, 2026-09-27)

Request (JS, verbatim): "ajoute une écurie où all 4 wiz have 4 unit each: 1 T1 with upgrade to T3, T2 upgrade with
upgrade to T3, and a true T3 unit". Then: "make sure they have dance".
Reading used (JS said don't ask): every kingdom gets a **Stables** with **4 mounted units**: two tier-1 (the first has a
rank-3 upgrade), one tier-2 (with a rank-3 upgrade) and one true tier-3. The "upgrade to T3" is an **in-place rank-3
research at the Stables, open at the Citadel** (separate from, and stacking with, the Hall's "+" upgrade).
Builds on `cavalry-mounts.md` (Stables numbers 2.1, Blaze / Gloam / Rimehorn / Stagrunner stats 4), `tier3-extras.md`
(the Glade Outrider is the Grove Stables' tier-3) and `tiers.md` (`requires_tier`, `TierSystem.gate_reason`).
Switch: **`Stables16.ENABLED`** (`scripts/units/stables16.gd`). Only the plain skirmish has it (`Stables16.enabled_here()`,
missions: off, like the new-units-12 rule); tests set `Stables16.force_enabled`.

## 1. The building
| id | Name | Cost | Build | HP | Size | Needs | Limit | Key |
|---|---|---|---|---|---|---|---|---|
| `fire_stables` | Ember Stables | 175 | 50 s | 1100 | 3 x 3 | completed Hall | 1 | build menu **N** |
| `shadow_stables` | Gloom Stables | 175 | 50 s | 1100 | 3 x 3 | completed Hall | 1 | N |
| `ice_stables` | Frost Stables | 175 | 60 s | 1320 | 3 x 3 | completed Hall | 1 | N |
| `nature_stables` | Grove Stables | 155 | 43 s | 990 (+1 %/s idle regen) | 3 x 3 | completed Hall | 1 | N |
Kind `&"stables"` -> `StablesBuilding extends TrainingBuilding` (queue of 5, rally, cancel refund). Not a crystal drop-off,
not a shop. No tier needed to build it (its T2 / T3 units are gated one by one). Placeholder look in code (long stable,
roof, hay loft, paddock rail) until `art/buildings/stables/<kingdom>/<kingdom>_stables.tscn` exists (`model_path`).
Card: **Z X C V** = the 4 units, **B** = rank-3 of the Z unit, **N** = rank-3 of the C unit, then Set Rally.

## 2. The 16 units
Slots: **Z** = tier-1 rider (rank-3 path), **X** = tier-1 harrier (mounted ranged, no rank-up), **C** = tier-2 heavy (rank-3
path), **V** = tier-3 elite (`requires_tier` 3). All pop 2 / 3 / 4, all "mounted" (fast, big radius).

| Kingdom | Slot | id | Name | Tier | Cost | Pop | Time | HP | Armor | Dmg | Range | Cd | Speed | Extra | Art |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Fire | Z | `blaze_rider` | Blaze Rider | 1 | 180 | 2 | 30 | 220 | 0 | 18 | 1.7 | 0.9 | 7.5 | (also stays in the Ember Hall) | **done** |
| Fire | X | `emberdart_harrier` | Emberdart Harrier | 1 | 165 | 2 | 28 | 170 | 0 | 14 | 6.5 | 1.2 | 7.2 | javelins | placeholder (Blaze Rider x0.9, tinted) |
| Fire | C | `pyrehoof_lancer` | Pyrehoof Lancer | 2 | 260 | 3 | 40 | 400 | 15 | 28 | 1.9 | 1.2 | 6.6 | | placeholder (x1.15) |
| Fire | V | `sunforge_cataphract` | Sunforge Cataphract | 3 | 400 | 4 | 55 | 700 | 30 | 42 | 2.1 | 1.3 | 6.4 | | placeholder (x1.3, gold) |
| Shadow | Z | `gloam_rider` | Gloam Rider | 1 | 185 | 2 | 30 | 240 | 5 | 16 | 1.8 | 0.9 | 7.2 | (cm. lifesteal 20 % not wired yet) | **done** |
| Shadow | X | `duskbolt_harrier` | Duskbolt Harrier | 1 | 165 | 2 | 28 | 160 | 0 | 15 | 6.5 | 1.2 | 7.2 | crossbow | placeholder (Gloam Rider x0.9) |
| Shadow | C | `barrow_knight` | Barrow Knight | 2 | 255 | 3 | 40 | 380 | 10 | 30 | 1.9 | 1.2 | 6.8 | | placeholder (x1.15) |
| Shadow | V | `veilborn_dreadrider` | Veilborn Dreadrider | 3 | 400 | 4 | 55 | 650 | 25 | 46 | 2.1 | 1.3 | 6.8 | | placeholder (x1.3, dark) |
| Ice | Z | `snowdrift_rider` | Snowdrift Rider | 1 | 170 | 2 | 30 | 240 | 10 | 15 | 1.8 | 1.0 | 6.8 | chill 1 s | placeholder (Rimehorn Rider x0.8) |
| Ice | X | `rime_harrier` | Rime Harrier | 1 | 165 | 2 | 28 | 175 | 5 | 13 | 6.5 | 1.3 | 6.8 | chill 1 s | placeholder (x0.85) |
| Ice | C | `rimehorn_rider` | Rimehorn Rider | 2 | 250 | 3 | 40 | 400 | 20 | 24 | 1.8 | 1.2 | 6.0 | chill 2 s | **done** |
| Ice | V | `frostcrown_juggernaut` | Frostcrown Juggernaut | 3 | 420 | 4 | 58 | 780 | 35 | 40 | 2.2 | 1.4 | 6.0 | chill 2 s | placeholder (x1.3, white) |
| Nature | Z | `stagrunner` | Stagrunner | 1 | 160 | 2 | 26 | 180 | 0 | 14 | 1.7 | 0.8 | 7.8 | regen 1 %/s | **done** |
| Nature | X | `bramble_harrier` | Bramble Harrier | 1 | 155 | 2 | 26 | 165 | 0 | 13 | 6.5 | 1.2 | 7.4 | thorn darts, regen 1 % | placeholder (Glade Outrider x0.85) |
| Nature | C | `thornback_charger` | Thornback Charger | 2 | 245 | 3 | 40 | 420 | 10 | 25 | 1.9 | 1.2 | 6.6 | regen 1.5 % | placeholder (Stagrunner x1.15) |
| Nature | V | `glade_outrider` | Glade Outrider | 3 | 380 | 4 | 52 | 520 | 10 | 34 | 8.0 | 1.1 | 7.6 | horse archer, regen 1 % | **done** |

Kingdom flavour: Fire hits hardest per crystal, Shadow trades HP for damage, Ice has the armor and chills, Nature
regenerates and has the long-range T3. Roles: Z = raider / archer-killer, X = hit-and-run skirmisher (fragile up close),
C = line breaker, V = the army's anchor. Kill XP ~ cost / 2.

## 3. Rank-3 upgrades (the "upgrade to T3")
| Unit | Becomes | Price | Time |
|---|---|---|---|
| Blaze Rider (Z) | Blaze Captain | 175 | 45 s |
| Pyrehoof Lancer (C) | Pyrehoof Warlord | 225 | 60 s |
| Gloam Rider | Gloam Marauder | 175 | 45 s |
| Barrow Knight | Barrow Dreadlord | 225 | 60 s |
| Snowdrift Rider | Snowdrift Captain | 175 | 45 s |
| Rimehorn Rider | Rimehorn Warden | 225 | 60 s |
| Stagrunner | Elder Stagrunner | 175 | 45 s |
| Thornback Charger | Thornback Warden | 225 | 60 s |
Researched at the Stables (card B / N), **needs the Citadel** (refusal `Requires Citadel`). Effect on every living and future
unit of that type of the team: modifier `rank3` = **+25 % max HP, +20 % damage, +10 armor, +0.3 speed**; metas `rank` = 3
and `rank_name`; model hook **`set_rank(3)`** (placeholder: a gold crest ring over the rider; real look = tech-artist).
One research at a time per Stables (`The Stables is busy`), pay on start, Stables destroyed = 75 % back. Stacks with "+".
Knobs: `Stables16.RANK_STATS`, `RANK_PRICE`, `RANK_TIME`.

## 4. Counters
| Unit type | Beats | Loses to |
|---|---|---|
| Z riders | archers, casters, workers, siege (Ash Hurler, Frost Mortar) | spears / guards (Flame Guard, Rimeshield, Thornling, Shadow Knight), towers |
| X harriers | slow melee, other Z riders (kite) | archers, Z riders that catch them, towers |
| C heavies | Hall lines, T1 riders | massed ranged + chill / root (Rime Seer, Vinelasher), T3 units |
| V elites | everything tier 1-2 in a straight fight | focus fire, Hexweaver wither, Frostrune / Cinderlock (T3), heroes' spells |

## 5. Dances ("make sure they have dance")
Every mounted unit dances (`UnitDances` / `play_clip`): the kit now lets a **seated rider** dance from the waist up (the
reins let go, hips and legs stay in the saddle) and **MountModel** has its own 3 clips: `dance_victory` = prance with a
rear every 4 beats (front legs up, head and tail high; the rider rises with the saddle), `dance_surrender` = head low,
body sunk, tail down, slow sway (the rider slumps, hands up), `dance_random` = a trot in place (diagonal pairs).
The two-model roots (Blaze / Gloam / Rimehorn Rider, Stagrunner, Glade Outrider, and every placeholder wrapping them)
forward `play_clip / stop_clip / current_clip / has_clip / can_dance / set_rank` through `MountedDance`
(`art/units/kit/mounted_dance.gd`). Titans built on MountModel (War Mammoth, Nightmare Knight) dance too
(`mount_dances = false` opts a mount out).

## 6. Bot
`Stables16.bot_step` (Commander rule 5, before the Hall): from **10:00 / 7:00 / 5:30** (easy / normal / hard) with a Hall,
it saves up to 30 s and places the Stables ~14 m from its keep toward the centre (one worker); then keeps 2 riders
queued there (mix Z 35 %, X 25 %, C 25 %, V 15 %, tier-gated slots skipped, 100 crystals kept); at the Citadel it
researches the rank-3 of the Stables unit it has most of (>= 2 alive, crystals >= price + 200). Rally = the army rally.

## 7. Art needed (tech-artist; one agent each)
- 11 riders (placeholders today): Emberdart Harrier, Pyrehoof Lancer, Sunforge Cataphract, Duskbolt Harrier, Barrow Knight,
  Veilborn Dreadrider, Snowdrift Rider, Rime Harrier, Frostcrown Juggernaut, Bramble Harrier, Thornback Charger
  (`art/units/<kingdom>/<id>/<id>.tscn`, the path in each `.tres` `model_path`; reuse the kingdom mount + a new rider,
  same two-model root as the Blaze Rider, with the MountedDance forwarders).
- A rank-3 look for the 8 rank units (`set_rank(3)`: plume / banner / barding trim instead of the crest ring).
- 4 Stables buildings (`art/buildings/stables/<kingdom>/`, cavalry-mounts.md 13.V21-24).
- 16 unit icons + 8 rank icons + 4 Stables icons.

## 8. Files
`scripts/units/stables16.gd` (roster, rank research, bot), `scripts/buildings/stables_building.gd`, `data/units/*.tres`
(15 new), `data/buildings/<kingdom>_stables.tres`, placeholders `art/units/<kingdom>/<id>/placeholder/`, one-line hooks in
`BuildGrid.create_building`, `BuildingType.buildable_for`, `CommandCard` (description) and `Commander._rule_train`.
Test: `tests/test_stables.gd` (data, gates, dance, bot).
