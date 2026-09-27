# Keep tiers: Keep -> Stronghold -> Citadel (tiers wave, 2026-09-27)

Written by the tier agent (systems-coder) for `docs/plan/tiers-wave.md`. Takes `research.md` 2.2 prices and effects;
research (Forge / Sanctum) does not exist yet, so its "needs" are replaced by a completed Hall + an earliest start time
that matches the research floors (`t3-helpers.md` 6). Switch: `TierSystem.ENABLED`; `Skirmish.tiers_enabled` (missions
false: no TierSystem node = nothing is tier-gated).

## 1. Tiers
| Tier | Name | Upgrade | Needs (when it starts) | Keep effect |
|---|---|---|---|---|
| 1 | Keep (Dusk Keep, Rime Keep, Heartwood) | - | - | today's numbers |
| 2 | **Stronghold** | **200 crystals, 60 s** | a completed own Hall, match time >= **3:30** | max HP x **1.2**, attack **+4** (12 -> 16) |
| 3 | **Citadel** | **300 crystals, 90 s** | the Stronghold, a completed own Hall, match time >= **5:45** | max HP x **1.4**, attack **+8** (20) |

Same price and time for all four kingdoms (research.md: no kingdom multiplier on upgrades). Keep HP per kingdom:
| Kingdom | T1 | Stronghold | Citadel |
|---|---|---|---|
| Fire (Keep) | 2 500 | 3 000 | 3 500 |
| Shadow (Dusk Keep) | 2 500 | 3 000 | 3 500 |
| Ice (Rime Keep) | 3 000 | 3 600 | 4 200 |
| Nature (Heartwood) | 2 250 | 2 700 | 3 150 |
(Masons' Charter x1.15 multiplies on top.) The HP gained is healed.

Rules: the upgrade runs beside the worker queue; cancel = full refund; the keep dies = the upgrade is lost. Team tier =
highest tier of its living keeps. Timing check: a good rusher's Stronghold ~4:40 -> 5:40 and Citadel ~7:15 -> 8:45
(t3-helpers 6); the floor is 3:30 -> 4:30 / 5:45 -> 7:15.

## 2. What each tier unlocks
| Tier | Unlocks |
|---|---|
| 2 Stronghold | The Hall's tier-2 units (`requires_tier = 2`: Pyre Adept, Cinder Arbalest, Hexweaver, Hollow Oathsworn, Hoarlight Magebow, Frost Mortar, Vinelasher, Greenheart Oathkeeper) · the "+" upgrades (section 5) |
| 3 Citadel | The tier-3 units (`requires_tier = 3`, t3-helpers: Ashveil Saboteur, Nightblood Reaver, Shardguard, Briar Roc, Stormbottle Genie) · the kingdom's helper (called at the Citadel keep) |
Any UnitType / BuildingType can set `requires_tier`; refusals `"Requires Stronghold"` / `"Requires Citadel"`.

## 3. UI
Keep card slot 2 (key **X**, right after the worker): `Stronghold` / `Citadel` with cost and time; while upgrading
`Cancel Stronghold` (tooltip: progress %, seconds left, refund). Refusals in the tooltip (`Available at 3:30`,
`Needs a completed Hall`, `Not enough crystals`). Message `The Keep is now a Stronghold`. Keep look: model
`set_tier(t)` / `play_tier_up()` if present, else placeholder gold rings over the roof (1 = Stronghold, 2 = Citadel).
Hall card r3c4 **+** opens the "+" page (one button per unit, Back at r3c4; click only for now).

## 4. Bots
Commander rule 5 (`TierSystem.bot_try_upgrade`): from the start time below the bot saves crystals (no soldiers, at most
45 s, then 20 s of normal play before saving again) and starts the upgrade as soon as it can.
| Difficulty | Stronghold start (done) | Citadel start (done) |
|---|---|---|
| Easy | 7:00 (8:00) | 12:00 (13:30) |
| Normal | 4:00 (5:00) | 6:40 (~8:30, it saves ~25 s) |
| Hard | 3:30 (4:30) | 5:45 (7:15) |

## 5. "+" upgrades
One per tier-1 / tier-2 soldier of the 4 kingdoms plus the bowmen (32 units; workers and caravans excluded), researched
at a Hall that trains the unit, from the Stronghold. `<Unit>+` = modifier `plus` = **+10 % max HP, +10 % attack damage**
on every living and future unit of that type of the team, and the model hook `set_plus(true)` if the model has it.
Price `50 + cost / 2` rounded to 5, within 75-200 crystals; time `30 s + cost / 10`, within 30-60 s (Flame Guard+: 95,
39 s; Shadow Knight+: 180, 56 s). One research at a time per Hall; Hall destroyed = 75 % refund. Bots: every 6 s at
tier 2+, the "+" of the unit they have most of (>= 3 alive) when crystals >= price + 200.
Knobs: `UnitUpgrades.STATS` / `STATS_OVERRIDE` (per unit), `TierSystem.UPGRADES`, `HP_MULT`, `DAMAGE_BONUS`, `BOT_START`.
