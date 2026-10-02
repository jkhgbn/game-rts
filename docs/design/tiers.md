# Keep tiers: Keep -> Stronghold -> Citadel (tiers wave, 2026-09-27)

Written by the tier agent (systems-coder) for `docs/plan/tiers-wave.md`. Takes `research.md` 2.2 prices and effects;
research (Forge / Sanctum) does not exist yet, so its "needs" are replaced by a completed Hall + an earliest start time
that matches the research floors (`t3-helpers.md` 6). Switch: `TierSystem.ENABLED`; `Skirmish.tiers_enabled` (missions
false by default: no TierSystem node = nothing is tier-gated; a mission turns it on in its `_init`, section 6).

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
| 2 Stronghold | The Hall's tier-2 units (`requires_tier = 2`: Pyre Adept, Cinder Arbalest, Hexweaver, Hollow Oathsworn, Hoarlight Magebow, Frost Mortar, Vinelasher, Greenheart Oathkeeper) · the "+" upgrades (section 5) · the kingdom's **caster** at the keep (B): Kilnwarden, Rimecarver, Bramblesage, Gloom Deacon (`caster-units.md`) |
| 3 Citadel | The tier-3 units (`requires_tier = 3`, t3-helpers: Ashveil Saboteur, Nightblood Reaver, Shardguard, Briar Roc, Stormbottle Genie) · the kingdom's helper (called at the Citadel keep) |
Any UnitType / BuildingType can set `requires_tier`; refusals `"Requires Stronghold"` / `"Requires Citadel"`.

## 3. UI
Keep card slot 2 (key **X**, right after the worker): `Stronghold` / `Citadel` with cost and time; while upgrading
`Cancel Stronghold` (tooltip: progress %, seconds left, refund). Refusals in the tooltip (`Available at 3:30`,
`Needs a completed Hall`, `Not enough crystals`). Keep look: model
`set_tier(t)` / `play_tier_up()` if present, else placeholder gold rings over the roof (1 = Stronghold, 2 = Citadel).

**Making the way up obvious (2026-09-30, JS: "not sure there is a way to tier up / get better units").** The audit
(`tools/ui_lab/tier_path_audit.gd`, shots in `docs/ui/tier_audit/`) found the upgrade worked but nothing pointed at it:
the Next hint never named it, nothing showed the keep's tier, the X button looked like any other and the completion
message did not say what opened. Now (`TierSystem.status(team)` / `unlocks(team, tier)` / `unlock_text` feed all of it):
| Where | What the player sees |
|---|---|
| Keep button X tooltip | `Upgrade the keep: +20 % HP, +4 damage.` / `Opens: Pyre Adept, Cinder Arbalest (Ember Hall) · Kilnwarden (Keep) · the "+" upgrades at the Hall` / `Needs from 3:30, a completed Hall.` (Citadel: `Needs the Stronghold, from 5:45, a completed Hall.`) |
| Keep button X | a thick gold border breathing once a second while the upgrade can start now (not while greyed) |
| Tier chip (`scripts/ui/tier_chip.gd`) | always on: `Tier 1 Keep · next: Stronghold at 3:30` / `... (needs a Hall)` / `Tier 1 Keep · Stronghold ready: X` (gold text, breathing gold border) / `Upgrading to Stronghold 45 % · 33 s` (gold progress line) / `Tier 2 Stronghold · next: Citadel at 5:45` / `Tier 3 Citadel`. Under the top bar's left end; in the skirmish (the map-fill strip sits there) in the top-left column under the Next hint. Click = select the keep + centre the camera |
| Next hint (skirmish) | 60 s before: a second line `Soon: Stronghold at 3:30 (in 0:40): 200 crystals, X on your Keep`; then (after Hall / train / houses) `Next: upgrade your Keep to a Stronghold: select it, press X (200 crystals, 60 s)` + `it opens Pyre Adept, Cinder Arbalest, Kilnwarden` (`save 200 crystals` when short); after it `Next: train your new Stronghold units: select the Ember Hall: M Pyre Adept, , Cinder Arbalest; the Keep: B Kilnwarden` until one is queued (90 s max). Same for the Citadel (tier-3 unit, helper) |
| Hall unit greyed `Requires Stronghold` | tooltip line `Upgrade your Keep to a Stronghold: select it, press X (from 3:30)` (or the upgrade's progress) |
| Completion message (7 s) | `The Keep is now a Stronghold. New: Pyre Adept, Cinder Arbalest (Ember Hall) · Kilnwarden (Keep)`; Citadel: `... New: Ashveil Saboteur, Old Vey (helper) (Keep)` |
| Selection panel, keep | info line starts with `Tier 2 Stronghold` (or `Upgrading to Citadel 40 %`) |
Keep card (caster-units.md 3.3): slot 5 = r2c1, key **B** = the kingdom's caster (greyed `Requires Stronghold` before);
**Set Rally moves to r3c1** (it has no key). Keys on the keep card: Z X C V B, all different.
Hall card r3c4 **+** opens the "+" page (one button per unit, Back at r3c4). Keys (2026-09-29): the `=/+` key (or numpad
+) opens / closes it; on the page each unit's "+" sits on its unit's slot and uses the unit's own training key (Flame
Guard+ = Z); Back = Esc. While the page is open the unit keys buy, never train.

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

## 6. Campaign missions (2026-09-30)
A mission opts in by setting `tiers_enabled = true` in its `_init` (after `super()`), then sets on its `tier_system`:
`max_tier` (the keep card shows no button past it; `can_upgrade` = `Not in this mission`) and `bots_upgrade = false`
(the scripted enemy keeps its numbers). Same prices, times and floors as the skirmish (every mission is longer than
the 3:30 / 5:45 floors, so nothing is rescaled). Units the mission gives at a tier are listed in its own Hall type
copy (`requires_tier` greys them until then); `casters_enabled = true` on the mission lists the kingdom's caster on
the keep (`CasterKit.enabled_here`). The skirmish Next hint stays off in missions (they have objectives); the tier
chip, the X pulse, the tooltips and the completion message work the same, and the mission adds its own one-time
message when the upgrade opens.
| Mission | Tiers | Why |
|---|---|---|
| 1 "The Crown in the Ashes" (`mission-01.md` "Tiers") | **Stronghold only** (`max_tier = 2`): Pyre Adept + Cinder Arbalest at the Ember Hall, the Kilnwarden at the keep (B), the "+" upgrades; Malrik's keep never upgrades | 15-20 min mission, the Hall is pre-built: the player meets the way up at 3:30. The Citadel (tier-3 unit, Old Vey) belongs to later chapters (`episode2-opening.md`: Old Vey comes back in episode 2) |
| 2 "Glasswater Mere" (spec only, `mission-02.md` "Tiers") | Stronghold only, same rule | Not built yet; the spec now says so |
| 3+ (not specified) | Citadel from the first mission that lets the helper join the story | To decide in `mission-03.md` / `-04.md` |
