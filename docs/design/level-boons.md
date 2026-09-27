# Level boons: a choice of 3 at every wizard level, Luck, rarity Common -> Godly

Owner: game-designer. Written 2026-09-27 (task LB.D1). Source of truth for tasks LB.* (section 12).
User request (JS, 2026-09-27, verbatim): "add skill point system on the game each lvl get a 3 choice ps add it luck
stats and lighting commun up godly".
Builds on `levels.md` (XP, levels 1-8, spell points, F / Q / E ranks), `spells.md`, `items.md` (Stats, caps, tiers),
`grand-market.md` section 2 (rarity colours), `champion-skill-tree.md` (champions already draft 1 of 3 per level),
`art-units.md` (1 staff light per wizard, 0 lights per effect). Every name here is our own. Metres, seconds, `m:ss`.

## 0. Interpretation (lead's defaults; my verdict on each)
| # | Default | Verdict |
|---|---|---|
| D1 | Each wizard level-up offers **3 boons**, the player picks 1 | Kept. Levels 2-8 = **7 picks** per wizard (4-5 in a normal match) |
| D2 | Boons sit next to spell points or replace part of them | **Added next to spell points** (section 1). F / Q / E ranks, their level rules, the AI lists and the tests stay exactly as `levels.md` |
| D3 | Wizard only; soldiers and champions get nothing | Kept. Soldiers keep veterancy (they profit from **army boons** of their wizard); champions keep their class + skill-tree draft (`champion-skill-tree.md`), which already is "1 of 3 per level" |
| D4 | New stat **Luck** through the Stats contract | Kept: `get_stat(&"luck")`, flat, base 0. It raises the rarity odds, adds a Lost Cache bonus roll and drives one Epic proc. **No crits** (a new combat system for 1 stat is not "small and clear") |
| D5 | Tiers Common, Uncommon, Rare, Epic, Legendary, Godly with colour + glow, world VFX with 0 lights | Kept. Colours reuse the item words where they overlap (Common grey, Rare orange, Epic magenta: one word = one colour in the whole game) |
| D6 | Player pick is not timed in an RTS | **No pause, no timeout** for the player (a pick waits like a spell point); bots pick on the next tick |

## 1. Boons vs spell points (recommendation: ADD, do not replace)
| Option | For | Against |
|---|---|---|
| **A. Add** (1 spell point **and** 1 boon per level) - **recommended** | F / Q / E ranks unchanged: "always something to buy" schedule, Ctrl+F / Q / E, rank pips, bot learn lists, 3.G2 / 3.G3 tests all keep working; boons are pure extra flavour | More power per level: budgeted in section 8 (+20-25 % wizard power at level 6, measured by the Balance Lab) |
| B. Replace (each level: "learn a rank" is one of the 3 cards) | Less total power | A bad draw locks spells behind luck; the rank schedule and AI lists break; F / Q / E stop being reliable = the core of the hero |
| C. Replace every other level | Half the problem | Two systems the player must understand per level; still breaks the schedule |
Decision **A**. Nothing in `levels.md` changes. A level-up now gives: stat growth (as today) + 1 spell point + 1 boon pick.

## 2. Player flow
1. **Level-up** (`level_changed`): the existing gold ring / message / badge play (`levels.md`). The wizard gains 1
   **pending pick**. If no offer is open, an offer of 3 cards is rolled at once (section 4) and the **boon panel
   slides in** (section 9). Picks stack: 2 levels in one fight = 2 pending, shown one at a time; the next offer is
   rolled **when the previous one is taken** (so Luck from the first pick counts for the second), with the table of
   the level that granted it.
2. **The game never pauses.** The panel is non-modal: the player keeps playing; units, spells, groups all work. It
   can be hidden (Ctrl+Space) and brought back; hidden, a pulsing chip `Boon  x1` stays in the hero column.
3. **Pick**: click a card or Ctrl+Z / Ctrl+X / Ctrl+C (section 9). Effect applies at once; the world burst plays in
   the tier colour (section 10); message `Vessa gains Heart of the Sun` (Godly / Legendary only; others silent).
4. **No timeout, no auto-pick for the player** (same rule as unspent spell points: banked, kept through death,
   picked while dead). Tooltip on the chip after 60 s pending: `A boon is waiting: Ctrl+Space`.
5. **Reroll**: `Reroll (n)` button / Ctrl+V: 3 new cards from the same level table with the current Luck. Every
   wizard starts a match with **1 reroll**; Clover Knot and Fortune's Favour add 1 each. Unused rerolls are kept.
   No skip, no banish: every pending pick ends as a boon.
6. **Bots** (Malrik and every AI wizard, both seats): pick on the AI tick after `offer_ready` (<= 0.5 s), rules in
   section 7. No UI; the enemy's pick plays its world burst (visible like the level ring).
7. **Offer rules**: 3 distinct boons; each card rolls its tier, then a boon uniformly from the eligible boons of
   that tier (Godly: own kingdom's boon weight 2, universal 1). Not eligible: at max stacks, another kingdom's boon,
   a spell boon whose requirement fails (`radius` / `cooldown` on that slot), a Godly when one is already owned.
   Empty tier -> the next lower tier. Card 3 is never below **Uncommon**; at levels **4 and 7** card 3 is at least
   **Rare** (milestones). Cards are shown sorted left to right by tier (highest right).

## 3. Luck (new stat)
- `get_stat(&"luck")`, **flat only**, base **0** for every unit; only wizards use it. Modifier keys `"luck": 8`.
- **Effect 1, boon odds** (section 4): `L = min(luck + pity, 60)`.
- **Effect 2, Lost Caches** (`items.md`): when a wizard opens a cache, chance `min(luck / 200, 0.30)` of a **second
  roll** of the loot table (both results given). Luck 20 = 10 %, 60 = 30 %.
- **Effect 3, Echo** (Epic boon only): echo chance `15 % + luck / 4 %`, cap 30 %.
- **Pity** (hidden bad-luck protection): every offer with no Epic+ card adds **+6** pity; an offer with an Epic+
  card resets it to 0. Not a stat, never shown; saved with the offers.
- **Sources**: Lucky Pebble (+8, x2), Clover Knot (+12), Fortune's Favour (+20), Apotheosis (+10). Max from boons
  ~58. Later (not in this task, needs `items.md`): one Luck item component and a campaign charm; knobs only.
- Shown: selection stat line `... · Luck 20` when luck > 0 (either wizard); boon card tooltips `Luck 20: better odds`.

## 4. Rarity: tiers, odds, formula
| Tier (index t) | Colour (UI and VFX) | First level it can appear | Tier value (AI strength, crystals) |
|---|---|---|---|
| 0 Common | `(0.85, 0.85, 0.85)` grey (= item Common) | 2 | 15 |
| 1 Uncommon | `(0.40, 0.85, 0.45)` green | 2 | 30 |
| 2 Rare | `(1.00, 0.60, 0.20)` orange (= item Rare) | 2 | 50 |
| 3 Epic | `(1.00, 0.35, 0.90)` magenta (= item Epic, same shimmer) | 2 | 80 |
| 4 Legendary | `(1.00, 0.75, 0.15)` deep gold | 4 | 110 |
| 5 Godly | `(1.00, 0.97, 0.85)` radiant white-gold + prismatic rim (the 4 kingdom colours) | 5 | 160 |
No boon tier is blue (`(0.30, 0.75, 1.00)` stays "Fine item").

**Formula** (one card): `weight_t = BASE[level][t] x (1 + L / 100) ^ t`, pick `t` with probability
`weight_t / sum(weight)`. Luck multiplies high tiers geometrically: Luck 20 = Godly x2.5, Luck 60 = Godly x10.5.
`BASE` (Luck 0; the level is the one that granted the pick):
| Level | Common | Uncommon | Rare | Epic | Legendary | Godly |
|---|---|---|---|---|---|---|
| 2 | 60 | 30 | 9 | 1 | 0 | 0 |
| 3 | 55 | 30 | 12 | 3 | 0 | 0 |
| 4 | 50 | 30 | 14 | 5 | 1 | 0 |
| 5 | 45 | 30 | 16 | 6 | 2.5 | 0.5 |
| 6 | 40 | 30 | 18 | 8 | 3 | 1 |
| 7 | 35 | 30 | 20 | 9 | 4.5 | 1.5 |
| 8 | 30 | 30 | 22 | 10 | 6 | 2 |
Resulting odds per card (%, C / U / R / E / L / G) and the chance that an offer of 3 shows **any Epic+** / **a Godly**
(before the card-3 floor, which only raises them):
| Level | Luck 0 | Luck 20 | Luck 40 | Luck 60 |
|---|---|---|---|---|
| 2 | 60/30/9/1/0/0 · 3 % / 0 | 54/33/12/2/0/0 · 5 % / 0 | 49/34/14/2/0/0 · 7 % / 0 | 44/36/17/3/0/0 · 9 % / 0 |
| 4 | 50/30/14/5/1/0 · 17 % / 0 | 43/31/17/7/2/0 · 25 % / 0 | 37/31/20/10/3/0 · 34 % / 0 | 31/30/22/13/4/0 · 42 % / 0 |
| 5 | 45/30/16/6/2.5/0.5 · 25 % / 1.5 % | 37/30/19/9/4/1 · 36 % / 3 % | 31/29/21/11/7/2 · 48 % / 5 % | 25/27/23/14/9/3 · 59 % / 9 % |
| 6 | 40/30/18/8/3/1 · 32 % / 3 % | 32/29/21/11/5/2 · 45 % / 6 % | 26/27/23/14/7/3 · 58 % / 10 % | 20/24/23/17/10/5 · 68 % / 15 % |
| 8 | 30/30/22/10/6/2 · 45 % / 6 % | 23/27/24/13/9/4 · 60 % / 11 % | 17/24/24/16/13/6 · 72 % / 17 % | 13/20/24/17/17/9 · 81 % / 24 % |
Targets: a Godly is **offered** in ~5 % of normal matches (ending level 5-6) at Luck 0, ~14 % of long ones (level 8),
~20-30 % for a player who builds Luck early. Legendary shows up about once in three normal matches. Pity adds
~+6 Luck per dry offer, so four dry offers in a row are rare.

## 5. The boon pool (40)
Stat boons use modifier `boon:<id>` on the wizard (stats x stacks). Army boons put `boon_army:<id>` on every own
soldier (non-worker, non-champion, non-titan units of the wizard's team, including units trained later). Spell boons
use the new per-slot keys (section 11); the card names the wizard's own spell (`{F}`, `{Q}`, `{E}`). Stack = how
many times the same boon can be taken. All caps of `items.md` hold for the **total** (items + boons).

### Common (9)
| id | Name | Stack | Effect |
|---|---|---|---|
| `sturdy_frame` | Sturdy Frame | 3 | `max_hp` +40 |
| `keen_edge` | Keen Edge | 3 | `attack_damage` +3 |
| `deep_well` | Deep Well | 3 | `max_mana` +20, `mana_regen` +0.25 |
| `quick_feet` | Quick Feet | 2 | `move_speed` +0.3 |
| `thick_hide` | Thick Hide | 3 | `armor` +6 |
| `spark_of_insight` | Spark of Insight | 3 | `spell_power` +6 |
| `steady_breath` | Steady Breath | 3 | `hp_regen` +1.0 |
| `lucky_pebble` | Lucky Pebble | 2 | `luck` +8 |
| `windfall` | Windfall | 3 | +150 crystals to the team, once (instant) |

### Uncommon (8)
| id | Name | Stack | Effect |
|---|---|---|---|
| `warded_robes` | Warded Robes | 2 | `armor` +10, `max_hp` +40 |
| `battle_rhythm` | Battle Rhythm | 2 | `attack_cooldown_pct` -0.08, `attack_damage` +2 |
| `focused_mind` | Focused Mind | 2 | `cooldown_reduction` +8 |
| `arcane_current` | Arcane Current | 2 | `spell_power` +12 |
| `honed_first` | Honed {F} | 2 | `spell1_power_pct` +0.12 |
| `mending_presence` | Mending Presence | 1 | Aura 6 m: own soldiers `hp_regen` +2 (`apply_aura`, source `boon:mending`) |
| `essence_spring` | Essence Spring | 1 | Team essence trickle +0.4 / s (60 % more trickle) |
| `clover_knot` | Clover Knot | 1 | `luck` +12, +1 reroll |

### Rare (8)
| id | Name | Stack | Requires | Effect |
|---|---|---|---|---|
| `quickened_second` | Quickened {Q} | 1 | Q cooldown > 0 | `spell2_cooldown_pct` -0.20 |
| `lingering_third` | Lingering {E} | 1 | E duration > 0 | `spell3_duration_pct` +0.35 (haste, shroud, shield, Sapling life) |
| `widened_first` | Widened {F} | 1 | F radius > 0 (Fireball, Thornburst) | `spell1_radius_pct` +0.20 (ring and disc follow) |
| `sharpened_first` | Sharpened {F} | 1 | F radius = 0 (Shadow Lance, Rime Bolt) | `spell1_power_pct` +0.18 |
| `rally_standard` | Rally Standard | 1 | - | Aura 10 m: own soldiers `attack_damage_pct` +0.08 (source `boon:rally`; stacks with the item Rally, a different name) |
| `spoils_of_war` | Spoils of War | 1 | - | Team kill essence +25 % (on the `items.md` victim value) |
| `fortunes_favour` | Fortune's Favour | 1 | - | `luck` +20, +1 reroll |
| `second_wind` | Second Wind | 1 | - | HP falls below 30 %: shield 25 % of max HP for 4 s (`add_shield`). Once per 90 s |

### Epic (5)
| id | Name | Effect |
|---|---|---|
| `iron_discipline` | Iron Discipline | Army: own soldiers `max_hp_pct` +0.08 |
| `spellweaver` | Spellweaver | `spell_power` +20, `cooldown_reduction` +10 |
| `overflowing_well` | Overflowing Well | `max_mana` +60, `mana_regen` +1.5 |
| `harvester` | Harvester | Each enemy unit dying within 12 m of the wizard: heal 4 % max HP and 4 mana |
| `echo_first` | Echo of {F} | After a spell-1 cast, chance 15 % + Luck / 4 % (cap 30 %) to cast it again 0.4 s later on the same target at **50 % power, free** (no mana, no cooldown). An echo never echoes |

### Legendary (4)
| id | Name | Effect |
|---|---|---|
| `titans_blood` | Titan's Blood | `max_hp` +150, `hp_regen` +3, `armor` +10 |
| `legions_oath` | Legion's Oath | Army: own soldiers `attack_damage_pct` +0.10, `max_hp_pct` +0.06 |
| `unbound_hours` | Unbound Hours | `cooldown_reduction` +15; `spell2_cooldown_pct` and `spell3_cooldown_pct` -0.15 |
| `last_light` | Last Light | Lethal damage sets HP to 30 % instead and gives `shroud` 2 s. Once per 180 s (after Phoenix Plume's Rekindle if both are ready) |

### Godly (6: one per kingdom + 2 universal; max **1 Godly owned** per wizard)
| id | Name | Kingdom | Effect |
|---|---|---|---|
| `heart_of_the_sun` | Heart of the Sun | Fire | Fireball leaves scorched ground at impact (radius x0.6, 4 s, 5 / 0.5 s, Ember Step's look); every **3rd** Fireball is a **Sunfall**: damage and radius x1.5 |
| `eclipse_mantle` | Eclipse Mantle | Shadow | Spell healing above max HP becomes a shield (cap 150, lasts 6 s); Shadow Lance jumps to up to 2 more enemies within 6 m at 60 % |
| `heart_of_winter` | Heart of Winter | Ice | Enemies under `chill` take **+15 % damage** from Torvald's team; Flash Freeze radius +1.0 m |
| `worldroot_bloom` | Worldroot Bloom | Nature | Call the Thicket raises **5** Saplings (not 3) that live 40 s; Thornburst roots 2.5 s (not 1.5) |
| `apotheosis` | Apotheosis | any | `max_hp` +180, `spell_power` +25, `cooldown_reduction` +12, `move_speed` +0.4, `luck` +10 |
| `banner_of_the_firstborn` | Banner of the Firstborn | any | Army: every own Recruit soldier becomes a **Veteran** now (to 100 XP) and new soldiers are trained as Veterans |
Families (for the bot): stat (C1-C7, U1-U4, E2, E3, L1, L3, Apotheosis), spell (Honed, Rare 1-4, Echo, the 4
kingdom Godlies), army (Mending, Rally, Iron Discipline, Legion, Banner), economy (Windfall, Essence Spring, Spoils),
luck (Pebble, Clover, Favour), survival (Second Wind, Harvester, Last Light).

## 6. Save, missions, replays
- **Skirmish**: no mid-match save exists; `BoonBook.get_save_state()` (owned + stacks, pending, current offer ids,
  rerolls, pity, RNG seed + state) is written for replays and a future save. Death keeps everything (levels rule).
- **RNG**: each BoonBook has its own `RandomNumberGenerator` seeded from the match seed + team + seat
  (deterministic for the Replay Lab). The player's **pick index and rerolls are inputs** the replay recorder must
  capture (like orders).
- **Campaign**: levels are not carried (`mission-01.md`, `mission-02.md`), so **boons are not carried**. A mission
  starting at level N gets N-1 pending picks at 0:00 (mission 2: 1 pick, level-2 table). Mission settings:
  `boons_enabled := true` (false = scripted missions: no panel, no picks), `start_boons: Array[StringName]`
  (granted, no VFX). Items / artifacts rules unchanged.
- **2v2** (`ui-2v2.md`): each wizard has its own BoonBook; army boons touch the soldiers owned by that wizard's
  player (fallback: its team).

## 7. The bot picks (ai: extends `ai.md` / `levels.md` 3.A1)
| Difficulty | Pick | Reroll |
|---|---|---|
| Easy | A random card (bot RNG) | Never |
| Normal | Highest tier; tie -> family order spell > stat > survival > army > economy > luck | Never |
| Hard | Highest **score** = tier value (section 4) x family factor x situation | When the best card is Common and a reroll is left |
Hard family factors: army x1.3 when own soldiers >= 15, x0.8 when < 8; economy x1.3 before 8:00, x0.6 after 15:00;
luck x1.2 at levels 2-4, x0.5 from level 6; survival x1.3 if the wizard died in the last 300 s. Spell boons of a slot
the bot has not learned yet: x0.7.
- **Strength** (`ai.md`): wizard = `170 + 30 x level + items / 5 + boons.total_value()` (sum of tier values of owned
  boons, stacks counted). Read for the player's wizard when seen (boons are visible in the selection panel).
- Bot Lab log: each pick `{level, tier, id, offers, luck}` in the match JSON (for section 13).

## 8. Balance targets
Measure: combat power = HP x DPS (`levels.md`). Tier targets, per pick, at level 4 (425 HP, 20 dmg, 130 mana):
| Tier | Power per pick | Example | Crystal equivalent |
|---|---|---|---|
| Common | +3-5 % | Sturdy Frame +40 HP = +9 % HP only | ~15 |
| Uncommon | +5-7 % | Warded Robes | ~30 |
| Rare | +8-10 % | Widened Fireball, Rally Standard (army) | ~50 |
| Epic | +12 % | Spellweaver; Iron Discipline on 20 soldiers | ~80 |
| Legendary | +16 % | Titan's Blood | ~110 |
| Godly | +22-30 % (build-defining) | Heart of the Sun; Banner on 25 soldiers ~+500 army value | ~160 (+ army) |
- **Typical level 6** (5 picks, ~2 C, 2 U, 1 R): **+20-25 %** wizard power, ~+150 crystals: a level-6 wizard is
  worth ~750 (was ~600), below the itemised ~1 000 of `items.md`. Rule kept: **no level is worth more than two
  minutes of income**; with boons a level is worth ~1.3 levels of today.
- **Lucky level 8** (U, U, R, R, E, L, G): ~+70 %; happens in < 5 % of matches, at 25:00+, visible to the enemy.
- No boon changes a mana cost (AI thresholds stay), range, aggro or attack range. Spell-slot cooldown boons stack
  with CDR multiplicatively, floor **50 %** of the rank cooldown.
- Knobs (one at a time): BASE Epic+ columns x0.8; Common stat values -25 %; Godly max-owned 1 -> 0 before level 7;
  pity 6 -> 4; army boon percents -2 pts; start rerolls 1 -> 0.

## 9. UI summary (layout owner: ui-designer may refine in `ui-boons.md`; positions at 1600 x 900)
| Element | Spec |
|---|---|
| Boon panel | 3 cards **150 x 200**, gap 8, docked above the hero column at **(272, 448)** (x 272-738, bottom y 648: never over the bottom panels). Header strip 466 x 22 at (272, 422): left `Level 5 · choose a boon` font 16; right-aligned buttons `Reroll (1)  Ctrl+V` and `Hide  Ctrl+Space` font 12 (no footer: the hero column starts at y 660) |
| Card | Tier name font 12 in the tier colour at the top, icon 64 x 64 (2-letter abbreviation font 28 until art), boon name font 16, effect text font 12 (real numbers: `Fireball: +20 % radius (3.5 -> 4.2)`), stack line `2 / 3`, key hint `Ctrl+Z` bottom. Hover = lift 4 px + tooltip with the family |
| Card lighting (UI glow is fine) | Common: 2 px border, no glow · Uncommon: 2 px, outer glow 6 px alpha 0.35 · Rare: 3 px, glow 10 px 0.5, pulse 2 s · Epic: 3 px, glow 14 px 0.6 + the Grand Market shimmer band every 2 s · Legendary: 4 px, glow 18 px 0.75, shimmer 1.5 s, 12 rising gold motes · Godly: 4 px, glow 24 px 0.9, prismatic rim cycling fire / ice / nature / shadow colours over 6 s, rotating light rays behind the card, 24 motes, 0.3 s screen-edge flash on reveal |
| Reveal | Cards flip left to right 0.12 s apart; audio hooks `boon_reveal_<tier>` (Godly `boon_godly` sting) |
| Chip | While a pick is pending and the panel is hidden: `Boon x1` 76 x 20 at **(412, 784)** (left of the points chip), bg = the best tier colour in the offer, pulses like the points chip |
| Selection panel | Either wizard: a row of up to 12 gems 10 x 10 (tier colour, stacks as a small digit) under the stat line; tooltip lists the boons. Stat line gains `Luck n` when > 0 |
| Messages | Only Legendary / Godly picks: `Vessa gains Heart of the Sun` (both teams see the enemy's) |
**Keys** (physical, checked **before** the training-slot / build-menu keys and only while an offer is pending; no
Alt, so AltGr never triggers them): **Ctrl+Z / Ctrl+X / Ctrl+C** = take card 1 / 2 / 3, **Ctrl+V** = reroll,
**Ctrl+Space** = show / hide the panel. Why: every plain letter, digit, F1-F11, Numpad 1-6, Tab and Space is taken
(`CLAUDE.md` Keys, research K, staffing I / O / P, levels L / N); Ctrl + the left-hand bottom row mirrors the
"Ctrl = spend a point" pattern of Ctrl+F / Q / E. Ctrl+Z with a building selected must never train (the training
branch ignores Ctrl). AZERTY prints Ctrl+W / X / C / V (`KeyLabels`). Help line: `Ctrl+Z/X/C: take boon  Ctrl+V: reroll`.

## 10. World VFX per tier (tech-artist assets, ui-coder `BoonVfx`; **0 new lights**)
Played on the wizard when a boon is **taken** (the `levels.md` gold level ring stays as is at level-up). Both teams
see it. Emission / additive unshaded meshes and particles only; the only "light" allowed is a pulse of the wizard's
**existing** staff `OmniLight3D` energy (x2 for 1 s, Legendary / Godly), like the terrain lightning pulses the sun.
| Tier | Look (all in the tier colour, all gone after <= 2.5 s) | Particles max |
|---|---|---|
| Common | 12 sparks rising 1.5 m | 12 |
| Uncommon | Flat ring r 0 -> 2 in 0.3 s + 20 sparks | 20 |
| Rare | Ring r 3 + 30 sparks + additive column r 0.6, 3 m tall, fades 0.8 s | 30 |
| Epic | Rare + 2 spiral ribbons around the body 1.2 s + shimmer on the column | 50 |
| Legendary | Epic + sky beam r 0.8, 8 m tall, 1.5 s; ground glyph decal r 2.5 fading 2 s; staff light pulse | 80 |
| Godly | Beam 14 m with the prismatic rim, glyph r 5, shockwave ring r 0 -> 8 in 0.5 s, 60 motes, staff light pulse, camera-independent (no shake); then a **permanent faint halo** (emissive ring r 0.5 above the head, alpha 0.35, both teams see it) | 120 |
Perf: at most 2 bursts at once per wizard (a new one ends the old); `PERF OK` with 4 wizards bursting Godly at once.

## 11. Suggested API (the lead freezes it when LB.G1 starts)
- **Stats contract** gains: `luck` (flat, base 0), and per spell slot N = 1..3: `spell<N>_power_pct` (damage, heal,
  shield, tick amounts of that slot's spell; multiplies with `spell_power`), `spell<N>_cooldown_pct` (negative =
  shorter; floor 50 % of the rank cooldown after CDR), `spell<N>_radius_pct`, `spell<N>_duration_pct`. `SpellCaster`
  reads them at cast time (slot = index in `spell_ids()`). `max_hp_pct` on soldiers as already allowed ("_pct").
- **`BoonType`** resource (`data/boons/<id>.tres`, gameplay): `id`, `display_name` (may hold `{F}` / `{Q}` / `{E}`),
  `tier: int` (0 Common .. 5 Godly), `family: StringName`, `kingdom: StringName` (`&""` = any), `max_stacks: int`,
  `stats: Dictionary` (on the wizard), `army_stats: Dictionary` (on own soldiers), `aura_radius: float`,
  `aura_stats: Dictionary`, `passive_id: StringName`, `instant: Dictionary` (`{"crystals": 150}`),
  `requires: StringName` (`&""`, `&"f_radius"`, `&"f_no_radius"`, `&"q_cooldown"`, `&"e_duration"`),
  `rerolls_granted: int`, `icon_abbrev`, `tooltip`, `static find(id) -> BoonType`, `static all() -> Array[BoonType]`.
- **`BoonRarity`** (`scripts/boons/boon_rarity.gd`, static): `NAMES`, `COLORS`, `VALUES`, `BASE` (section 4),
  `LUCK_CAP := 60`, `PITY_STEP := 6`, `static weights(level, luck) -> PackedFloat32Array`,
  `static roll_tier(rng, level, luck, floor_tier) -> int`.
- **`BoonBook`** (`scripts/boons/boon_book.gd`, child `"BoonBook"` of each wizard, created in `_ready` if the script
  exists, `wizard.boons`): `owned: Dictionary` (id -> stacks), `pending: int`, `offer: Array[BoonType]` (0 or 3),
  `offer_level: int`, `rerolls: int`, `pity: int`, `enabled: bool`; `take(index) -> String` (`""`, else
  `"No boon pending"`, `"Invalid choice"`), `reroll() -> String` (`""`, `"No boon pending"`, `"No rerolls"`),
  `grant(id)` (missions / tests, no offer), `stacks_of(id) -> int`, `luck() -> float`, `total_value() -> int`,
  `get_save_state() -> Dictionary`, `load_save_state(d)`; signals `offer_ready(level, offer)`,
  `boon_taken(boon, stacks)`, `pending_changed(n)`, `rerolls_changed(n)`. The roll lives here only.
- Modifier ids: `boon:<id>` (wizard), `boon_army:<id>` (soldiers, applied to units entering the tree via `node_added`),
  auras via `apply_aura(&"boon:<id>", ...)`. Passives via existing hooks (`spell_hit`, `spell_cast`,
  `attack_landed`, `add_shield`, `apply_dot`, `apply_status`, `Events.unit_died`).
- **Events** gains `boon_taken(wizard, boon_id: StringName, tier: int)` (VFX, audio, messages, Bot Lab log).
- `BoonVfx.play(tier, wizard)` (`scripts/vfx/boon_vfx.gd`, group `"boon_vfx"`); Lost Cache reads the opener's
  `get_stat(&"luck")`. Owner row: `scripts/boons/`, `data/boons/` -> gameplay-coder.

## 12. Tasks (step LB)
| Id | Owner | What | Files |
|---|---|---|---|
| LB.L1 | lead | Freeze section 11 in `CLAUDE.md` (Stats names, BoonBook, Events signal, Keys line, owner row) | `CLAUDE.md`, `scripts/core/events.gd` |
| LB.G1 **[H]** | gameplay-coder-high | BoonType + 40 `.tres`, BoonRarity, BoonBook (offer / take / reroll / pity / floors / filters / save state / RNG), `luck` stat, per-slot spell stats in SpellCaster, army modifiers, auras, instants, passives, 6 Godlies | `scripts/boons/`, `data/boons/`, `scripts/units/wizard.gd`, `scripts/spells/spell_caster.gd`, `tests/test_lb_g1.gd` |
| LB.S1 | systems-coder | Lost Cache luck roll; mission `boons_enabled` / `start_boons` / N-1 picks at start; Essence Spring / Spoils hooks in EssenceBank if needed; Windfall via `Economy.add` | `scripts/world/lost_cache.gd`, `scripts/campaign/`, `missions/`, `tests/test_lb_s1.gd` |
| LB.U1 | ui-coder | Boon panel, cards, tier glow / shimmer / rays, chip, keys, selection gems + Luck line, messages, audio hooks, help line | `scripts/ui/boon_panel.gd`, `hud.gd`, `selection_manager.gd`, `selection_panel.gd`, `tests/test_lb_u1.gd` |
| LB.U2 | ui-coder | `BoonVfx` world bursts + Godly halo using LB.V2 assets | `scripts/vfx/boon_vfx.gd`, `tests/test_lb_u2.gd` |
| LB.V1 | tech-artist | Card frames x6, glow / shimmer / light-ray textures, mote sprite, 40 icons (after placeholders) | `art/ui/boons/`, `art/icons/boons/` |
| LB.V2 | tech-artist | World VFX kit per tier (ring, column, ribbons, beam, glyph, shockwave, halo), 0 lights | `art/vfx/boon_*` |
| LB.A1 | ai-coder | Pick policies, Hard reroll, strength term, Bot Lab pick log | `scripts/ai/`, `tests/test_lb_a1.gd` |
| LB.D2 | game-designer | Balance Lab runs (section 13), knob changes here | this file |

## Done when
- [ ] LB.G1: a level-up adds 1 pending pick **and** 1 spell point (3.G2 tests unchanged); an offer has 3 distinct eligible boons, card 3 >= Uncommon, >= Rare at levels 4 / 7; `take(1)` applies `boon:<id>` (test: Sturdy Frame x2 -> `max_hp` +80; Thick Hide + 25 armor items capped by `items.md`); stacks stop at `max_stacks`; kingdom Godlies only for their kingdom, max 1 Godly owned; `BoonRarity.weights(6, 20)` matches section 4 within 0.1 %; 10 000 seeded rolls at level 8 Luck 0 give Godly 2 % +- 0.4; pity +6 per dry offer, 0 after an Epic+; rerolls 1 at start, +1 per Clover / Favour, `"No rerolls"` after; same seed + same picks = same offers; `luck` via `get_stat(&"luck")`; Widened Fireball radius 3.5 -> 4.2, Quickened Soul Siphon 20 -> 16 s, cooldown floor 50 %; Iron Discipline gives +8 % HP to a Shade trained after the pick; Echo never echoes and costs no mana; Heart of the Sun's 3rd Fireball deals x1.5 in radius x1.5; Last Light once per 180 s; F / Q / E ranks and `command_cast` reasons unchanged; `PERF OK`.
- [ ] LB.S1: cache second roll at `luck / 200` (cap 30 %, seeded test); mission 2 starts with 1 pending pick; `boons_enabled = false` shows no panel and gives no picks; `start_boons` granted silently; the smoke test prints `victory=true`.
- [ ] LB.U1: panel slides in on `offer_ready` at (272, 448), never pauses; Ctrl+Z / X / C take cards 1-3, Ctrl+V rerolls, Ctrl+Space hides / shows, by physical keycode, only while pending; Ctrl+Z with a barracks selected does not train; plain Z / X / C / V unchanged; chip at (412, 784) while hidden; tier glows as section 9 (screenshot test per tier); cards show the real numbers of the wizard's own spell; selection gems for both wizards; nothing in `scripts/ui/` calls a `_private` function.
- [ ] LB.U2 / V1 / V2: each tier burst matches section 10 and is freed within 2.5 s; 0 `OmniLight3D` added (test counts lights before / after); staff light energy restored after the pulse; Godly halo persists and is visible to the enemy; `PERF OK` with 4 Godly bursts at once; Art Lab passes the new folders.
- [ ] LB.A1: Easy random, Normal highest tier with the family tie order, Hard score + reroll on an all-Common best (seeded tests); pick within 0.5 s of `offer_ready`; strength includes `total_value()` for both wizards; picks logged in the Bot Lab JSON.

## 13. Balance Lab plan (LB.D2; Balance Lab v1 needs a `"boons"` variant key: ai-coder / labs owner adds it)
Variant JSON: `{"boons": {"enabled": false}}`, `{"boons": {"luck_start": 30}}`, `{"boons": {"no_godly": true}}`,
`{"boons": {"scale": 0.8}}` (all boon numbers x0.8), `{"boons": {"policy": "normal"}}` (both seats).
| Arm | Question | Pairs / seeds | Games |
|---|---|---|---|
| A baseline = boons off | Today's win rates | 12 non-mirror pairs x 8 seeds | 96 |
| B boons on (Normal policy both) | Does any kingdom move > 5 pts vs A? Game length +- 10 %? | same | 96 |
| C boons on, `luck_start` 30 | Does a Luck start snowball (win rate of the luckier seat)? | 4 mirror pairs, one seat lucky, x 12 | 48 |
| D boons on, `no_godly` | How much of B's swing is Godly? | 12 pairs x 8 | 96 |
| E boons on, `scale` 0.8 | Fallback numbers if B is too swingy | 12 pairs x 8 | 96 |
Quick sweep first (`-Tick 30 -Limit 1200`, seeds 1-4, 4 pairs: fire:shadow, shadow:fire, ice:nature, nature:ice),
then B vs A at 60 Hz. ~98 games per arm detect a 20-pt swing (lab note); a 10-pt kingdom check needs ~390 per arm:
run it only if B vs A shows a 10-20 pt hint. Pass: every kingdom 45-55 % in B, |B - A| <= 5 pts per kingdom,
median length change <= 10 %, a wizard owning a Godly wins <= 65 % of those games, Heart of the Sun / Eclipse /
Winter / Worldroot owners within 8 pts of each other. Fail -> the knobs of section 8 in their order, one per run.

## 14. STR / INT path (JS 2026-09-27, `ideas-inbox.md` STR / INT rows; built with `tests/test_str_int.gd`)
JS: "STR give more phy attack and hp and INT magic attack and give mana", "u start the have to chose 1 or the other",
"same for all npc", "str hp regen and int snow shield", "ez to see".
| Rule | Value |
|---|---|
| When | **Mandatory, at 0:00 of a skirmish**, before anything else; **locked** for the match (no respec, kept through death) |
| STR (Strength) | modifier `path:str`: `attack_damage_pct` **+0.15**, `max_hp_pct` **+0.20** (Vessa L1: 350 -> 420 HP, 14 -> 16.1 dmg) |
| INT (Intellect) | modifier `path:int`: `spell_power` **+15** (= +15 % spell damage, counts toward the 60 cap), `max_mana_pct` **+0.25** (100 -> 125) |
| STR ability **Vigor** | `hp_regen` + **2 % max HP / s** (modifier `path:vigor`) for the duration = **40 % max HP** over 20 s |
| INT ability **Snow Shield** | `add_shield(25 % max HP + 2 x spell_power)` for the duration (Vessa L1: 118); **ends early when broken** |
| Timing (both) | **active 20 s, cooldown 60 s** (cooldown starts when the effect ends). `ABILITY_DURATION` / `ABILITY_COOLDOWN` are the two constants at the top of `scripts/units/str_int_path.gd`: JS sets them after the playtest ("2 min ability 1 min cooldown" is unconfirmed; 2 min up / 1 min down would be up 67 % of the time = a stat, not a window to punish) |
| Key | **J** (physical keycode; the only free plain letter after W A S D Q E F Z X C V B G H R T Y U M, reserved I O P K L N) or click the ability button (right edge) |
| Look (0 lights, built once per wizard, shown / hidden) | STR: pulsing red-gold double ground ring r 2.0 m (heartbeat 1.4 Hz) + red-gold fresnel body shell + rising embers. INT: bright frost dome r 1.7 m with moving frost bands + icy ground ring + snow motes. Gone the moment the buff ends: a wizard with no aura is the one to jump (`art/vfx/str_int/str_int_vfx.gd`) |
| Bots | pick by kingdom (`scripts/ai/ai_str_int.gd`): **Fire, Ice -> INT** (nuke / control kits), **Shadow, Nature -> STR** (drain / sustain in long fights). Use: STR when HP < 60 % and hit in the last 3 s; INT when HP < 85 % and hit in the last 1.5 s (0.5 s think) |
| Player UI | a 2-button panel "Choose your path" at 0:00, **game paused until picked**; then the ability button `J  Vigor  ready / ACTIVE n s / n s` |
| Headless runs, tests, bot-vs-bot | both seats auto-pick with the bot rule |
| Missions | **skipped** (no path, no panel, no ability) until a mission setting asks for it; `scenes/main.tscn` unchanged |
| Switch | `StrIntPath.ENABLED` (const, top of `str_int_path.gd`): false = the wizard never creates the node, the game plays as before |
Balance note: STR ~ +38 % combat power (HP x DPS) at L1, INT ~ +15 % spell damage + mana; roughly one Legendary boon
each (section 8). Balance Lab arm to add: `{"str_int": "off"}` vs on, per kingdom and per path.

## Questions for the user
0. STR / INT ability timing: **20 s active / 60 s cooldown** (default now), or literally 2 min / 1 min, or 1 min / 2 min?
1. **Spell points stay and boons come on top** (recommended), or should a boon card replace the spell point on
   some levels?
2. **Godly stays very rare** (~5 % of normal matches see one, ~20-30 % with a Luck build) (recommended), or do you
   want to see Godly about once every 3-4 matches (Godly odds x3)?
3. Keys **Ctrl+Z / Ctrl+X / Ctrl+C** to take card 1 / 2 / 3, **Ctrl+V** reroll, **Ctrl+Space** hide (recommended;
   plain keys are all taken), or clicking only?
4. **No pause** while choosing (recommended, the panel waits for you), or pause the game in the skirmish vs bots
   while the cards are open?
5. **Luck stays small** (boon odds + Lost Cache bonus roll + one Epic proc) (recommended), or should Luck also give
   critical hits to the wizard?
