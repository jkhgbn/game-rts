# Bowmen: four kingdom archers with upgrades (user request 2026-09-27)

User (JS, verbatim): "add plan for 4 unique bowmen 1 ice slow enemy down 1 fire dmg + strong base attack upgrade where u
recruit them 1 bleeding make enemy lose hp over time and last is normal archer but u can upgrade to have crit dmg and more
of them" + "make it now on medium use all u can reuse".
Built by gameplay-coder (medium effort) in one pass: spec + data + code + test. Numbers follow the `rush-balance.md` 2.1
method (EHP, DPS, CE, PE). Status: **playable in skirmish**, upgrade buttons need UI glue (section 7).

## 1. Defaults taken (JS said "no more questions")
| Question | Default |
|---|---|
| Which kingdom gets which bowman | Ice = slow (the **Frostbow** of `rush-balance.md` 5, extended), Fire = burn + strong shot, Shadow = bleed, Nature = plain archer with crit / "more of them" upgrades |
| Where they are recruited | The kingdom's **Hall**, new slot 5 (key **B**, after the 4 existing units). Skirmish only: missions (`Skirmish` subclasses such as mission 1) and the main.tscn map do not list them |
| Where upgrades are bought | At the **same Hall** ("where u recruit them"), research style: pay on start, one upgrade at a time per Hall, permanent, living + future units |
| Tiers | No keep-tier system exists yet (step 14): every bowman is trainable from a completed Hall. When step 14 lands, the Frostbow moves to T2 as `rush-balance.md` 5 says |
| One switch | `BowmanKit.BOWMEN_ENABLED` (`scripts/units/bowman_kit.gd`). `false` = no Hall lists a bowman, bots never pick one, all hooks are no-ops |
| "More of them" | Nature's top upgrade **Hunting Party**: every Wildwood Archer trained brings a second one for free (needs 1 free pop) |
| Crits | Deterministic: a per-archer chance accumulator (15 % = exactly 3 crits in 20 arrows), so replays / tests repeat. A crit arrow is drawn bigger |

## 2. The four units (`data/units/<id>.tres`, level 1, no items)
| id | Name | Kingdom | HP | Armor | Dmg | Range | CD | Speed | Aggro | Sight | Cost | Pop | Train | kill_xp |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `frostbow` | Frostbow | Ice | 90 | 5 | 22 | 12.0 | 2.4 | 4.4 | 12 | 13 | 140 | 1 | 28 | 70 |
| `scorchbow` | Scorchbow | Fire | 75 | 0 | 14 | 9.5 | 1.6 | 4.8 | 10.5 | 11 | 125 | 1 | 24 | 60 |
| `bleakbow` | Bleakbow | Shadow | 70 | 0 | 8 | 9.0 | 1.2 | 5.0 | 10 | 11 | 115 | 1 | 22 | 55 |
| `wildwood_archer` | Wildwood Archer | Nature | 60 | 0 | 8 | 9.0 | 1.2 | 5.0 | 10 | 11 | 85 | 1 | 16 | 40 |
Bolt speed 30 / 26 / 26 / 25 m/s. `card_key` "B". No idle regen (research Q3 rule for new Nature units).

### 2.1 Combat value (CE = EHP x DPS / cost² x 100, PE = EHP x DPS / pop² / 100)
| Unit | EHP | DPS | CE | PE | Note |
|---|---|---|---|---|---|
| Ember Archer (reference) | 70 | 7.5 | 5.3 | 5.3 | Nightbolt 5.0, Shardcaster 4.5 (+ chill), Burr Slinger 6.0 |
| Frostbow | 94.5 | 9.2 | 4.4 | 8.7 | + chill on every arrow; the spec's number, unchanged |
| Scorchbow | 75 | 8.75 + burn 2.0 = 10.75 | 5.2 | 8.1 | burn is one DoT per target (refresh, never stacks) |
| Scorchbow, both upgrades | 75 | 10.6 + 3.5 = 14.1 | 6.8 | 10.6 | + 225 crystals of upgrades |
| Bleakbow (alone on a target) | 70 | 6.7 + bleed 4.5 = 11.2 (ramp ~10.2 over 20 s) | 5.4 | 7.1 | the bleed cap is **per target**: 5 Bleakbows on one target share 4.5 DPS (~7.6 DPS each, CE 4.0) |
| Wildwood Archer | 60 | 6.7 | 5.5 | 4.0 | cheapest archer, lowest PE: a mass unit |
| Wildwood, Keen Eye / Heartseeker | 60 | 7.7 / 9.0 | 6.4 / 7.5 | 4.6 / 5.4 | |
| Wildwood + Hunting Party | 60 | 9.0 | ~2x per crystal | 5.4 | pop-bound: at the cap it is an Ember Archer |
All four sit in the ranged band (CE ~5) at level 1 and pass it only after paid upgrades.

## 3. Abilities (all passive on-hit; `BowmanKit`, reusing `apply_status` / `apply_dot`)
| Unit | Rule |
|---|---|
| Frostbow | Every arrow: `chill` **1.5 s** (never shortens a longer chill). **Hamstring Shot** (autocast, cooldown **12 s**): the next arrow at a unit moving >= 1.5 m/s chills **3.5 s**. Model hook `set_hamstring_ready(on)` (the Frostbow art has it) |
| Scorchbow | Every arrow: DoT `burn` **2 damage / 1 s for 3 s** (refresh; the stronger burn wins, items' burns included). Armor applies to ticks |
| Bleakbow | Every arrow adds a **bleed stack** on the target: DoT `bleed` = **1.5 DPS per stack**, ticks every 0.5 s, **5 s** refreshed by each hit, cap **3 stacks** (4.5 DPS). Stacks reset when the bleed runs out. Mark colour dark red |
| Wildwood Archer | None at first. Crits and twins come from its upgrades |
Buildings never burn, bleed or chill (units only, like `on_hit_status`).

## 4. Upgrades (bought at the Hall; `BowmanUpgrades`, modifiers `bowman:<id>`)
| Hall | id | Name | Price | Time | Needs | Effect |
|---|---|---|---|---|---|---|
| Frost Hall | `frostbow_rimed_shafts` | Rimed Shafts | 100 c | 40 s | - | chill per arrow 1.5 -> **2.5 s**; Hamstring cooldown 12 -> **8 s** |
| Ember Hall | `scorchbow_heavy_draw` | Heavy Draw | 100 c | 35 s | - | **+3 attack damage** (17): the "strong base attack" upgrade |
| Ember Hall | `scorchbow_pitch_arrows` | Pitch Arrows | 125 c | 45 s | Heavy Draw | burn **3.5 / s for 4 s** |
| Gloom Hall | `bleakbow_serrated_barbs` | Serrated Barbs | 100 c | 40 s | - | bleed cap 3 -> **5 stacks** (7.5 DPS) |
| Grove Hall | `wildwood_keen_eye` | Keen Eye | 75 c | 30 s | - | **15 % crit, x2** damage |
| Grove Hall | `wildwood_heartseeker` | Heartseeker Points | 100 c | 40 s | Keen Eye | **20 % crit, x2.75** |
| Grove Hall | `wildwood_hunting_party` | Hunting Party | 200 c | 60 s | Heartseeker | every Wildwood Archer trained brings **a second one** (free, needs 1 free pop) |
Rules (as `research.md` 2.3): paid when started; one upgrade in progress per Hall; a Hall destroyed mid-upgrade refunds
75 %; done = permanent, applied at once to living bowmen and to every later one. Refusals (first that applies):
`"Unknown upgrade"`, `"Already researched"`, `"Already in progress"`, `"Needs a completed Hall of your kingdom"`,
`"Needs <name>"`, `"The Hall is busy with another upgrade"`, `"Not enough crystals"` (flashes the top bar).
When step 14's ResearchBank exists, these 7 rows can become `ResearchType`s with `unit_mods` (same shape).

## 5. Counters and roles
| Unit | Beats | Loses to |
|---|---|---|
| Frostbow | Raiders, cavalry, anything that must close in (long chill, range 12) | Swarms (slow shot), divers once in range |
| Scorchbow | Heavy single targets, regenerating units (burn keeps ticking), long fights | Cavalry / hounds (75 HP), spread swarms (one burn each) |
| Bleakbow | Tanks, heroes, champions (bleed ignores the fight ending: they keep losing HP) | Many small units (stacks spread thin), burst |
| Wildwood Archer | Mass fights late (upgraded crits, twins) | Everything early (60 HP), area damage, cavalry |

## 6. Bots
- Mix: a Hall slot past `AIProfile.mix_*` (only the 4 old slots have entries) now uses `BowmanKit.BOT_SHARE`: **0.08**
  (Frostbow, Scorchbow, Bleakbow), **0.10** (Wildwood). Same rule 5 "slot furthest below its share" as the rest.
- Upgrades: rule 5 buys the Hall bowman's next upgrade every 5 s when the bot has **>= 3 living bowmen** of that kind and
  **crystals >= price + 250** (`BowmanUpgrades.bot_try_buy`). It never waits for them.
- No micro: all effects are passive or autocast.

## 7. Glue the lead / ui-coder owes (not built here)
**2026-10-14:** superseded by `unit-upgrades.md` 7-14: the 7 rows join `UnitResearch` (same ids and numbers) and are
bought on the Hall's unit page (`+`, the bowman's key, then X C V); the bot rule moves to `ai_research.gd`.
- **Upgrade buttons** on a selected own Hall: rows from `BowmanUpgrades.options_for(hall)` (`id, name, text, crystals, time,
  state (&"ready" / &"working" / &"done" / &"locked"), progress, reason`) -> `BowmanUpgrades.for_team(team).buy(id, hall)`.
  Suggested: card row 2 after Set Rally, keys free on the Hall card (N, M). Tooltip = `text`.
- `TRAIN_DESCRIPTIONS` lines in `command_card.gd` for the 4 ids; icons `art/icons/units/<id>.png`.
- Models: done (Art Lab PASS); `model_scene` = `art/units/<kingdom>/<id>/<id>.tscn`. Arrows leave from the model's
  `get_bow_tip_position()`. `play_cast()` (the bigger shot) is not used yet: a candidate for crits / Hamstring Shot.

## 8. Open points
- Hunting Party halves the Wildwood's price: watch the lab; knobs in order: price 200 -> 250, then twin needs 2 free pop.
- Scorchbow is Fire's; Fire is already the strongest kingdom (`balance-2.md`): first knob if Fire rises is Heavy Draw +3 -> +2.
- Frostbow T2 gating and `bonus_vs_mounted` wait for steps 13 / 14 (no tier system, no mounted tag yet).
- Replay: crits are deterministic; Hamstring uses the physics frame clock.
