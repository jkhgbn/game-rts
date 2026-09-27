# Grand Market: items of tiers 1-5 (heroic and epic) + three new expansion sites per side

Task 17.D1, written 2026-09-26, revised the same day with the user's answers (Q3: three sites per side). Source of truth for step 17 (tasks in section 15). User request: "new town building, a market
with epic items tier 1 to 5 for sale, and add expansions in other places if possible." Every name, item, rule and number here
is our own. Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)` on Crown Hollow, `+x` east, `+z` south.
**Point mirror** as in `market-trade.md`: everything at `(x, z)` on the player (south-west keep, west bank) side exists at
`(-x, -z)` on the enemy side. Builds on `items.md` (tiers, essence, recipes, shops, the frozen item API), `market-trade.md`
(gold, the Bazaar), `champions.md` (purses), `research.md` (Stronghold / Citadel), `map-fill.md` (river, camps, points,
beasts and their reserved trophy ids), `terrain.md`, `skirmish-1v1.md`, `balance-1.md`, `balance-2.md`, `ai.md`, `levels.md`.
**Balance context:** target 15-20 min games; the leader must not snowball; items must stay weaker than armies.

## User decisions (final, 2026-09-26)
| # | Question | Decision |
|---|---|---|
| Q1 | How rare are the 8 epic (tier-5) items? | **Unique per match + a showcase of 4 of the 8** (the same 4 for both sides, drawn at match start): the first wizard to buy one owns it; the other side can no longer get it (section 4) |
| Q2 | Can champions buy tier-4 / tier-5 items with their purse? | **Tier 1-4 yes** (the gold part costs them essence 1:1, max 1 T4), tier 5 **wizards only** |
| Q3 | How many new expansion sites? | **3 per side** (6 new nodes): the **Glade Vein** (west flank, sealed until the Hollow Stag dies), the **Millrace Vein** (by the south river, exposed to the Crown Bridge and Willow Ford) and the **Ford Vein** (beside Reed Ford in the rich corner, the contested one) as a full site with its own hall slot X5; to make room the rich-node hall slot X2 moves to the west side of the rich node (section 6) |

## 0. Decisions in one table (designer decisions, not questions)
| Question | Decision | Why |
|---|---|---|
| Grand Market or Bazaar upgrade? | A **separate building**, not an upgrade. The Bazaar stays the **gold** building (caravans, wares that buff the army, exchange); the Grand Market is the **hero gear** building (items T1-T5, relics, elixirs) and the main late **gold sink** | (1) Trade can be off (missions, "Trade Off"): the gear shop must work without a Bazaar or gold. (2) The Bazaar is a cheap early 175-crystal eco building; tying epics to it would force trade for items. (3) Two buildings = two raid targets and two readable scouting signals ("a Grand Market = epic threat"). (4) `market-trade.md` 11.5 lists "gold piles up unused": item recipes now use gold |
| Tier ladder | **5 tiers**: T1 Common = components, T2 Fine = mid, T3 Rare = top (all existing items keep their tier), **T4 Heroic** (new), **T5 Epic** (new). Relics (T4 colour family) and elixirs are side rows | The existing 36 items fit tiers 1-3 as they are; no rebalance of shipped items |
| New items | 2 T1 + 2 T2 + 2 T3 (Grand Market exclusives), **8 heroic**, **8 epic**, **9 relics** (the 8 beast trophies reserved in `map-fill.md` + the Starforged Relic), 2 elixirs = **33** | Each tier gets something only the Grand Market sells; one heroic and one epic per main build path (attack, spell, mobility, tank, army, and one per new kingdom) |
| Currency | T1-T3: **essence only** (unchanged). T4 recipe **400 essence + 200 gold**, T5 recipe **400 essence + 250 gold**, Starforged Relic **300 essence + 125 gold**. Trade off: every gold part is paid as **essence x 0.5** | Essence stays the fighting currency; gold (trade) opens the top tiers, as research does for tier-2/3 tech |
| Gates | Building: completed Hall + **Stronghold** (research on) / **7:00** (research off). Epics: **Citadel** (research on) / **12:00** (research off) | One tier ladder with research; epics arrive with titans, not before |
| Epic rules | Unique per match + showcase of 4 (Q1); **1 epic per wizard**; **at most 2 items of tier 4-5 per wizard**; announced to both teams; built from its heroic + **any relic** | Rare, visible, one per hero: an identity, not a stack |
| New expansions | 3 per side (Q3): Glade Vein 1 800 crystals (sealed by the Hollow Stag), Millrace Vein 1 500 crystals (exposed river site), Ford Vein 1 600 crystals (contested, beside Reed Ford); ordinary Halls as drop-offs | Income after the home nodes run dry (~10:30) in three new places: one safe-but-guarded, one exposed at home, one contested far away |

## 1. The Grand Market (building; systems 17.S1)
### 1.1 Numbers
| id | Name (UI: `Grand Market · <name>`) | Cost | Build time | max_hp | Footprint | Height | Sight | kill_xp |
|---|---|---|---|---|---|---|---|---|
| `fire_grand_market` | Brasslight Exchange | 275 crystals | 60 | 1400 | 3 x 3 | 6.5 | 12 | 120 |
| `shadow_grand_market` | Duskvault Exchange | 275 | 60 | 1400 | 3 x 3 | 6.5 | 12 | 120 |
| `ice_grand_market` | Hoarglass Exchange | 275 | **72** (x1.2) | **1680** (x1.2) | 3 x 3 | 6.5 | 12 | 120 |
| `nature_grand_market` | Mossgold Exchange | **245** | **51** (x0.85) | **1260** (x0.9) | 3 x 3 | 6.5 | 12 | 120 |
- `kind` `&"grand_market"`, `max_count` **1** (message `"Only one Grand Market"`), `requires_kind` `&"barracks"`
  (`"Needs a completed Hall"`), `required_keep_tier` **2** (`"Needs a Stronghold"`), `min_time` **420** (used only when research
  is off, the Lair's rule of `research.md` 5), `max_keep_distance` **25** (`"Must be within 25 m of your keep"`). Refusal order:
  after `"Blocked by an enemy unit"` and the river / camp messages: Hall, keep tier (or `"Available at 7:00"`), distance, limit,
  crystals. Nature: `idle_regen_pct` 1.0 like every Nature building. The Masons' Charter (x1.15) applies.
- Counts for defeat, **not** a drop-off, trains nothing, **is a shop** (`is_shop() -> true`, radius 12 like keeps / halls).
- Build menu: **I** at **r3c3** (row 3 = Forge J, Sanctum L, Grand Market I; I is free everywhere). Tooltip:
  `Brasslight Exchange  [I]\nCost 275 crystals · 60 s · 1400 HP\nGrand Market: heroic and epic items. Needs a Stronghold.\nWithin 25 m of your keep. One per kingdom.`
- Card: r1c1 **Shop T** (opens the market window; T already opens a shop in range), r1c2 **Showcase** (the window on its Epic
  tab, no key). Panel: HP, `Starforged Relic 1 / 2 · next in 2:14`, `Epics: Needs a Citadel` / `Epics: open`.
- Destroyed: the team loses the shop (items already owned stay); relic stock and the showcase are kept by the ledger
  (section 4) and come back with a rebuilt market.
- Bot / natural slot **GM** `(-53, 29)` / enemy `(53, -29)`: 17.2 m from the keep, west of the M1 Bazaar slot (2 m gap), south
  of T2 Stables (2 m gap), 9.1 m from the Standing Stones, 16 m from the West Heath lair centre (>= 9 m from its edge), 14 m
  west of the hub - west road. Cleared of trees / rocks like `HOUSE_SLOT` (17.S1). Shifts of `ai.md` if refused.

### 1.2 Look (art 17.V1-17.V5, section 10)
One shared structure + a trim kit per kingdom (not 4 separate models): a **domed merchant hall with a tall bell-and-clock tower**
(dominant vertical, ~7.5 m), a **round vault door** in the front face (secondary), two open arcade stalls with display plinths
where the showcase epics glow. Kingdom trims: roof material, banners, lanterns and one signature prop (Fire brass sun-dial
and ember braziers; Shadow obsidian dome, violet lanterns, raven-scale roof; Ice frosted-glass dome, crystal bell; Nature
living-wood dome, moss, glow-fruit lanterns). Placeholder: box 6 x 4 x 6 in the body colour + a dome (half sphere r 2.6) + a
tower 1.2 x 7 x 1.2 with a gold emissive bell.

## 2. The five tiers
| Tier | Name | Border colour | Existing items in it | New (Grand Market only) | Sold at | Total price range |
|---|---|---|---|---|---|---|
| T1 | **Common** | `(0.85, 0.85, 0.85)` (unchanged) | 14 components (12 of `items.md`, Frostglass Shard, Verdant Seed) | 2 | Base shops, peddlers (as today), **Grand Market (all)** | 150-260 |
| T2 | **Fine** | `(0.30, 0.75, 1.00)` (unchanged) | 13 mids (9 + 2 Ice + 2 Nature) | 2 | Combine at any shop; the new ones only at the Grand Market | 580-770 |
| T3 | **Rare** | `(1.00, 0.60, 0.20)` (unchanged) | 9 tops (7 + Winterwall Aegis + Heart of the Grove) | 2 | Same | 1 400-1 950 |
| T4 | **Heroic** | `(0.90, 0.25, 0.35)` crimson | - | 8 | **Grand Market only** | 2 340-2 590 essence + 200 gold |
| T5 | **Epic** | `(1.00, 0.35, 0.90)` magenta + animated shimmer (a light band sweeps the border every 2 s) | - | 8 | **Grand Market only**, showcase, Citadel | 3 040-3 290 essence + 575 gold (with a bought relic) |
| Relic | Relic | `(0.78, 0.60, 0.40)` bronze | - | 9 (8 trophies + Starforged Relic) | Trophies: beast drops only; Starforged: Grand Market stock | 300-450 value |
| Elixir | Consumable | `(0.40, 0.90, 0.40)` (unchanged) | 4 consumables | 2 | Grand Market only | 220 |
Artifacts keep their gold `(1.00, 0.85, 0.30)`. The error flash stays on currency text only, never on item borders.

## 3. The new items (items-coder 17.I1-17.I3; modifier keys of the Stats contract; ids `data/items/<id>.tres`)
### 3.1 T1-T3 Grand Market exclusives
| id | Name | Tier | Parts + recipe = total (essence) | Stats | Passive / active |
|---|---|---|---|---|---|
| `lodestone_bead` | Lodestone Bead | T1 | **240** | `max_hp` +50, `max_mana` +40 | - |
| `quickfire_flint` | Quickfire Flint | T1 | **260** | `attack_cooldown_pct` -0.06, `move_speed` +0.3 | - |
| `gilded_buckler` | Gilded Buckler | T2 | Lodestone Bead + Ironbark Plate + 300 = **720** | `max_hp` +120, `armor` +18, `max_mana` +30 | **Deflect**: the first hit taken every 8 s deals 50 % less (a gold pip on the slot when ready) |
| `stormglass_sling` | Stormglass Sling | T2 | Quickfire Flint + Whetted Fang + 280 = **740** | `attack_cooldown_pct` -0.16, `attack_damage` +8, `move_speed` +0.3 | **Chain Spark**: every 4th auto-attack also hits the nearest other enemy within 4 m for 60 % of the damage |
| `echo_prism` | Echo Prism | T3 | Siphon Idol + Lodestone Bead + 600 = **1 450** | `spell_power` +40, `max_mana` +110, `mana_regen` +1.5, `cooldown_reduction` +10, `max_hp` +50 | Spell Drain; **Resonance**: every 5th spell cast costs no mana (a counter on the slot) |
| `muster_standard` | Muster Standard | T3 | Gilded Buckler + Warlord's Horn + 500 = **1 950** | `max_hp` +250, `armor` +30, `max_mana` +30 | Deflect; **Muster** (aura): soldiers within 10 m `armor` +10 |
Echo Prism and Muster Standard are end items (no heroic above them).

### 3.2 Elixirs (consumables; shared 90 s cooldown between the two; stack 2)
| id | Name | Cost | Effect for 30 s |
|---|---|---|---|
| `titans_draught` | Titan's Draught | 220 | `max_hp` +150 (healed by the gain) and `attack_damage_pct` +0.15 |
| `sages_incense` | Sage's Incense | 220 | `spell_power` +25 and `mana_regen` +4 |

### 3.3 T4 Heroic (recipe **400 essence + 200 gold** unless noted; max 2 T4-T5 per wizard, 1 T4 per champion)
| id | Name | Parts + recipe = total | Stats | Passive / active |
|---|---|---|---|---|
| `dawnsplitter` | Dawnsplitter | Inferno Blade + Quickfire Flint + 400 e + 200 g = **2 560 e + 200 g** | `attack_damage` +55, `attack_cooldown_pct` -0.24, `max_hp` +150, `move_speed` +0.3 | Feed 15 %, Searing Strikes II; **Sunder**: each auto-attack on a unit lowers its `armor` by 4 for 4 s, max 5 stacks (-20), refreshed per hit (modifier `item:sunder` on the target) |
| `pyremasters_codex` | Pyremaster's Codex | Staff of Cinders + Lodestone Bead + 400 e + 200 g = **2 590 e + 200 g** | `spell_power` +75, `cooldown_reduction` +25, `max_mana` +140, `mana_regen` +2.5, `max_hp` +50 | Afterglow, Smoulder; **Wildfire Mind**: a spell that damages 3+ enemies refunds 30 % of its mana cost |
| `duskrunner_mantle` | Duskrunner Mantle | Shadowstride + Quickfire Flint + 400 e + 200 g = **2 340 e + 200 g** | `move_speed` +1.5, `armor` +25, `hp_regen` +4, `attack_cooldown_pct` -0.06 | Quiet Step; **Blink II** (active, point): up to 12 m, then `shroud` 1.5 s; cooldown 35, 0 mana (replaces Blink: same family) |
| `lastwall_aegis` | Lastwall Aegis | Ruinwarden Mantle + Gilded Buckler + 400 e + 200 g = **2 520 e + 200 g** | `max_hp` +420, `armor` +45, `max_mana` +30 | Brace II, Deflect; **Unbroken**: below 30 % HP, `armor` +40 (total cap 150 holds) |
| `oathbound_warbanner` | Oathbound Warbanner | Banner of Embers + Gilded Buckler + 400 e + 200 g = **2 570 e + 200 g** | `max_hp` +330, `armor` +25, `max_mana` +40 | Deflect; **Rally III** (aura 12 m): soldiers `attack_damage_pct` +0.18, `hp_regen` +1.5, `move_speed_pct` +0.05; **Rallying Cry II** (active): soldiers within 12 m heal 100 over 4 s and are `braced` 2 s; cooldown 80 |
| `hoarfrost_regalia` | Hoarfrost Regalia | Winterwall Aegis + Frostglass Shard + 400 e + 200 g = **2 460 e + 200 g** | `armor` +45, `max_hp` +260, `max_mana` +40 | **Frost Ward II** (aura 10 m): soldiers `armor` +14; Glacier Shell; **Rime Skin**: melee attackers that hit the wearer get `chill` 1.5 s |
| `eldergrove_heart` | Eldergrove Heart | Heart of the Grove + Verdant Seed + 400 e + 200 g = **2 490 e + 200 g** | `spell_power` +45, `max_hp` +260, `hp_regen` +5 | Verdant Ward (unchanged, **not** raised: `research.md` Q3); **Overgrowth II** (active): friendly units within 10 m heal 150 over 5 s, cooldown 75; **Rootgrasp**: the first enemy hit by each of the wearer's spells is `rooted` 0.6 s (6 s per-target cooldown) |
| `hungering_reliquary` | Hungering Reliquary | Gravemaw Idol + Lodestone Bead + 400 e + 200 g = **2 500 e + 200 g** | `spell_power` +35, `max_hp` +200, `attack_damage` +25, `max_mana` +100 | Feed 15 %, Spell Drain, Spell Feed 20 %; **Grave Tithe**: +10 `max_hp` for each enemy wizard or champion that dies within 6 s of the wearer damaging it, max +100 (a counter; lost when the item leaves the inventory) |
Flavour: Fire Dawnsplitter / Codex, Shadow Duskrunner / Reliquary, Ice Regalia, Nature Eldergrove, shared Lastwall / Warbanner.
Any wizard may buy any of them.

### 3.4 T5 Epic (recipe **400 essence + 250 gold** + its heroic + **any relic**; wizards only (Q2); unique per match (Q1))
Totals below use the Starforged Relic (300 e + 125 g); with a trophy the cash price is the heroic's missing parts + 400 e + 450 g.
| id | Name | From | Total | Stats | Unique effect |
|---|---|---|---|---|---|
| `sunfall_edge` | Sunfall Edge | Dawnsplitter | **3 260 e + 575 g** | `attack_damage` +70, `attack_cooldown_pct` -0.30, `max_hp` +220, `move_speed` +0.4 | Feed 18 %, Searing Strikes II, Sunder; **Dawnbreak**: every 6th auto-attack calls a lance of light on the target: **120 damage** to enemies within 2.5 m + `dazed` 0.5 s (not a spell: no `spell_power`) |
| `ninth_flame_tome` | Tome of the Ninth Flame | Pyremaster's Codex | **3 290 e + 575 g** | `spell_power` +90, `cooldown_reduction` +30, `max_mana` +180, `mana_regen` +3.5, `max_hp` +80 | Afterglow, Smoulder, Wildfire Mind; **Twincast**: every 3rd spell cast repeats 0.4 s later on the same target / point at **50 %** effect (no mana, no cooldown); movement spells (Ember Step, blinks) never repeat |
| `hundred_doors_veil` | Veil of a Hundred Doors | Duskrunner Mantle | **3 040 e + 575 g** | `move_speed` +1.8, `armor` +30, `hp_regen` +5, `attack_cooldown_pct` -0.10 | Quiet Step; **Phase Door** (active, point, cooldown 28, replaces Blink II): blink up to 14 m; an **Afterimage** (decoy unit: 200 HP, armor 0, no attack, lives 4 s) stays at the start and `taunts` enemy non-hero units within 6 m for 2 s; **Nightstep**: the first auto-attack within 3 s after a Phase Door deals +150 % and `dazed` 0.6 s |
| `unfallen_rampart` | The Unfallen Rampart | Lastwall Aegis | **3 220 e + 575 g** | `max_hp` +550, `armor` +55, `max_mana` +40 | Deflect, Unbroken; **Last Stand** (passive, 180 s cooldown shown on the slot): damage that would kill the wearer leaves 1 HP, then status `unyielding` (no damage taken) **2.5 s**, then heals 20 % max HP; **Bulwark Pulse** (active, self, cooldown 60): shield 300 on the wearer for 6 s and 120 on friendly soldiers within 8 m. With Rekindle (Phoenix Plume) too: at most one cheat-death per 30 s |
| `undying_host_standard` | Standard of the Undying Host | Oathbound Warbanner | **3 270 e + 575 g** | `max_hp` +380, `armor` +30, `max_mana` +50 | Deflect; **Rally IV** (aura 14 m): soldiers `attack_damage_pct` +0.22, `hp_regen` +2, `move_speed_pct` +0.06; **Stand Fast** (active, cooldown 100): soldiers within 14 m are `braced` 4 s and **cannot drop below 1 HP for 3 s** |
| `long_winter_heart` | Heart of the Long Winter | Hoarfrost Regalia | **3 160 e + 575 g** | `armor` +55, `max_hp` +320, `max_mana` +60, `spell_power` +20 | Frost Ward II, Glacier Shell, Rime Skin; **Everwinter** (aura 7 m, refreshed 0.5 s): enemy **units** inside are `chill`ed. It never adds Frostbite stacks (`research.md` 3.3), so it slows, it does not freeze |
| `worldtree_seed` | Seed of the World-Tree | Eldergrove Heart | **3 190 e + 575 g** | `spell_power` +60, `max_hp` +320, `hp_regen` +7 | Verdant Ward, Rootgrasp; **World-Sapling** (active, point within 8 m, cooldown 90): plants a friendly **Warden Sapling** (stationary, 600 HP, armor 20, lives 20 s, pop 0, no XP): every 4 s it `roots` enemy units within 6 m for 1.0 s; friendly **wizards and champions** within 6 m regenerate 20 HP / s (heroes only: no army regen) |
| `whispering_ossuary` | Ossuary of Whispers | Hungering Reliquary | **3 200 e + 575 g** | `spell_power` +50, `max_hp` +260, `attack_damage` +35, `max_mana` +120 | Feed 18 %, Spell Drain, Spell Feed 25 %, Grave Tithe; **Hollow Chorus**: an enemy soldier or worker that dies within 8 m of the wearer rises 1 s later as a friendly **Risen** (`risen.tres` of `research.md` 3.2, 30 s), max **3** from this item at once, counted in the team's Risen cap |
All caps of `items.md` hold (spell power 100, CDR 40, lifesteal 30 %, spell healing 60 %, armor 150, attack cooldown floor 40 %,
move speed +2.5, HP regen +12). Sunfall -0.30 + Blazing / Whetted parts cannot pass the -35 % cap.

### 3.5 Relics (tier `relic`, 1 per slot; any relic completes any epic recipe)
| id | Name | Source | Value (`total_cost`, sale 50 %) | Stats while carried |
|---|---|---|---|---|
| `ironhide_tusk` | Ironhide Tusk | Ironhide Tusker (A) | 300 | `armor` +8, `max_hp` +60 |
| `scarback_tusk` | Scarback's Broken Tusk | Old Scarback (B) | 400 | `armor` +12, `max_hp` +90 |
| `stormcrest_plume` | Stormcrest Plume | Stormcrest Roc (A) | 300 | `move_speed` +0.4, `cooldown_reduction` +5 |
| `duskwing_plume` | Duskwing Plume | Duskwing Roc (B) | 400 | `move_speed` +0.5, `spell_power` +10 |
| `greymane_pelt` | Greymane Pelt | Greymane Direwolf (A) | 300 | `attack_cooldown_pct` -0.06, `hp_regen` +1.5 |
| `moonpelt_pelt` | Moonpelt Hide | Moonpelt Direwolf (B) | 400 | `attack_cooldown_pct` -0.08, `move_speed` +0.3, `hp_regen` +1.5 |
| `grizzlemaw_claw` | Grizzlemaw Claw | Grizzlemaw (A) | 350 | `attack_damage` +14, `max_hp` +60 |
| `elder_grizzlemaw_claw` | Elder Grizzlemaw's Claw | Elder Grizzlemaw (B) | 450 | `attack_damage` +18, `max_hp` +100 |
| `starforged_relic` | Starforged Relic | Grand Market stock | 300 e + 125 g | `max_mana` +30 |
- Trophies are the ids `map-fill.md` 5.5 already reserved: once these `.tres` exist, every beast kill drops its trophy on the
  ground (existing hook, no change in `epic_beasts.gd`). Wizards pick them up (champions never pick up ground items).
- Recipe rule: an epic's parts are `[its heroic, relic_any]`. `relic_any` is a wildcard part: the plan consumes the **cheapest
  carried relic**; with none carried it buys a Starforged Relic from this market's stock in the same click (`"Out of stock"` if
  none). An epic's `total_cost` counts the wildcard at the Starforged price.

## 4. Prices, stock, limits, who buys (items-coder 17.I1, ledger 17.I3)
| Rule | Value |
|---|---|
| Prices | Essence as `items.md`; the **gold part** of T4 / T5 recipes and the Starforged Relic is paid from `GoldBank`. `price_of(type)` = recipe + missing parts, each split into essence and gold. The shop shows `2 560` essence + `200` gold chips |
| No trade (`GoldBank.for_team(team) == null`) | Every gold part is paid in **essence x 0.5** (rounded to 5): a T4 recipe = 500 essence, a T5 recipe = 525, the Starforged Relic = 365. The UI shows the folded price |
| Champions (purse) | May buy **T1-T4** where they shop (a Grand Market within 12 m is a usable shop). The gold part is paid from the purse **in essence 1:1** (no gold in purses); the 20 % tithe applies to the whole price. Never T5 (`"Wizards only"`). Max **1** T4 per champion |
| Wizards | Team essence + team gold. Max **2 items of tier 4-5** (`"Heroic / epic limit"`) and **1 epic** (`"One epic per wizard"`). A recipe that consumes a T4 part to make a T5 counts the result only |
| T1-T3 stock | Unlimited everywhere they are sold. The Grand Market sells **every** T1-T3 item and consumable (it is a full shop), plus its exclusives |
| T4, elixirs | Unlimited; Grand Market only |
| **Showcase (Q1)** | At match start the `MarketLedger` draws **4 of the 8 epics** with the match rng (the same 4 for both teams). A team sees them when its first Grand Market completes (`Epic showcase: Sunfall Edge, ...`). The other 4 do not exist in this match |
| **Unique per match** | Each showcase epic can be owned by one wizard at a time. Buying it = **claim**: message to both teams `Malrik claimed Sunfall Edge!` (big banner + bell), it leaves both markets. Sold: it returns to the showcase **120 s** later (`Sunfall Edge returns to the showcase`). The owner's death changes nothing (items are not dropped, `items.md`) |
| Epic gate | `"Needs a Citadel"` (research on) / `"Available at 12:00"` (research off), checked at purchase |
| Starforged Relic stock | Per team, kept by the ledger: **1** when the team's first Grand Market completes, **+1 every 240 s**, max **2**. `A Starforged Relic arrives at your Grand Market` |
| Underdog discount | When the buyer's team wizard level is **lower** than the enemy wizard's: T4 / T5 **recipe** parts (essence and gold) **-15 %** (rounded to 5). Same test as `CampManager.underdog_team()`. Message once per minute `Underdog discount: heroic and epic recipes -15 %` |
| Epic bounty | Killing a wizard who carries an epic pays the killer's team **+120 essence** on top of the normal kill value (`Epic bounty: +120`) |
| Sell | 50 % of `total_cost` as today, split: essence part back in essence, gold part back in gold (`GoldBank.add(n, &"sale")`). Trophies 50 % of their value. A sold epic re-enters the showcase after 120 s |
| Item auras on soldiers (new rule, all tiers) | **Per stat, the highest value from any item aura applies** (no sum): Rally II +0.15 and Rally III +0.18 give +0.18; Muster and Frost Ward II armor give +14. Names still never stack (existing rule) |
| Actives by family | Blink / Blink II / Phase Door: only the best one is usable; Brace / Brace II / Bulwark Pulse are separate families (shields) but a new shield replaces the old one (existing rule) |
| `can_buy` refusals, in order | `"Dead"`, `"No shop nearby"`, `"Not sold here"`, `"Needs a Citadel"` / `"Available at 12:00"`, `"Wizards only"`, `"Not in the showcase"`, `"Claimed by <name>"`, `"One epic per wizard"`, `"Heroic / epic limit"`, `"Out of stock"`, `"Inventory full"`, `"Not enough essence"`, `"Not enough gold"` |

## 5. Recipe links (one line per path)
```
Blazing Edge (Ember Shard + Whetted Fang) + Grave Pact (Bone Charm + Ember Shard) -> Inferno Blade + Quickfire Flint -> Dawnsplitter + relic -> Sunfall Edge
Duskglass + Mana Thread -> Pyre Staff; Cinder Ring + Duskglass -> Emberwake Band -> Staff of Cinders + Lodestone Bead -> Pyremaster's Codex + relic -> Tome of the Ninth Flame
Swiftsoles + Wisp -> Ashen Greaves; Ironbark + Wisp -> Nightveil Cloak -> Shadowstride + Quickfire Flint -> Duskrunner Mantle + relic -> Veil of a Hundred Doors
Warden Scale + Vital Root -> Bulwark of Ruin -> Ruinwarden Mantle + Gilded Buckler -> Lastwall Aegis + relic -> The Unfallen Rampart
Bone Charm + Ironbark -> Warlord's Horn -> Banner of Embers + Gilded Buckler -> Oathbound Warbanner + relic -> Standard of the Undying Host
Frostglass + Ironbark -> Rimebound Bracers -> Winterwall Aegis + Frostglass Shard -> Hoarfrost Regalia + relic -> Heart of the Long Winter
Verdant Seed + Duskglass -> Bloomcaller Staff -> Heart of the Grove + Verdant Seed -> Eldergrove Heart + relic -> Seed of the World-Tree
Gloom Ink + Mana Thread -> Siphon Idol; + Grave Pact -> Gravemaw Idol + Lodestone Bead -> Hungering Reliquary + relic -> Ossuary of Whispers
Lodestone Bead + Ironbark -> Gilded Buckler; + Warlord's Horn -> Muster Standard (end)
Quickfire Flint + Whetted Fang -> Stormglass Sling (end);  Siphon Idol + Lodestone Bead -> Echo Prism (end)
```
Peddler-only parts (Warden Scale, Vital Root) stay peddler-only; the Grand Market sells them too (it is a full shop), so the
Lastwall path no longer needs the peddler walk once the market exists.

## 6. New expansion sites (systems 17.S2)
### 6.1 The sites (player side; mirror in the last column)
| Site | Node id (key) | Node | Crystals | Hall slot | Tower slot | Magpie worker spot | Mirror (node, hall, tower, spot) |
|---|---|---|---|---|---|---|---|
| **Glade Vein** | `node_fire_glade` (`&"glade"`) | `(-41, -3.5)` | **1 800** | **X3** `(-39, 5)` | **SG** `(-45, -1)` | **W3** `(-51, -9)` | `(41, 3.5)`, `(39, -5)`, `(45, 1)`, `(51, 9)` |
| **Millrace Vein** | `node_fire_millrace` (`&"millrace"`) | `(-3, 23)` | **1 500** | **X4** `(-9, 27)` | **SM** `(-5, 19)` | **W4** `(-2, 36)` | `(3, -23)`, `(9, -27)`, `(5, -19)`, `(2, -36)` |
| **Ford Vein** | `node_fire_ford` (`&"ford"`) | `(-22.5, -30.5)` | **1 600** | **X5** `(-31, -33)` | **SF** `(-17, -23)` | **W5** `(-16, -42)` | `(22.5, 30.5)`, `(31, 33)`, `(17, 23)`, `(16, 42)` |
Enemy-side nodes are `node_shadow_glade` / `node_shadow_millrace` / `node_shadow_ford` (the side naming of `skirmish.gd`). Halls
are the kingdom's ordinary Hall (drop-off by the existing rule); nothing new to build. Nodes use the existing crystal node look +
site dressing (17.V13). Per side the map goes from 9 000 to **13 900** crystals (+1 800 +1 500 +1 600).
The Ford Vein node is the user's `(-22, -30.5)` shifted **0.5 m west** so it keeps the 14 m camp clearance from the Reed Ford
Nest (13.9 -> 14.4 m). X5 takes the spot next to the rich node, so **X2 moves** to the rich node's west side (6.3): the rich
corner becomes one district with two nodes and two halls 4 m apart (X2 7.1 m from the rich node, X5 8.9 m from the Ford node;
X5 also reaches the rich node at 11.4 m, so a player may run both nodes from X5 alone, while X2 is too far, 18.7 m, for
the Ford node).
| Site | Own keep (straight / ~path) | Enemy keep (straight / ~path) | What guards it | What threatens it |
|---|---|---|---|---|
| Glade Vein | 46.5 m / ~52 m | 92.8 m / ~108 m (isle or Saltgate Bridge) | **Sealed** until the West Stag Glade's Hollow Stag `(-37, -10)` dies once (7.6 m away, inside its aggro 8); the stag cannot respawn while workers mine (respawn blocked within 16 m); the Heron Ford road 7.9 m west | The Roc's Colossus Crag territory 16 m south-west; Magpie worker raids from 8:00 (W3); an enemy army must cross the isle or Saltgate Bridge: the safest far flank, but the stag fight comes first |
| Millrace Vein | 44.7 m / ~48 m | 80.4 m / ~88 m (isle) | Your **Millwatch** tower (17.3 m, sight 22) sees raids coming; the **Willow Ford Nest** blocks the ford 15.9 m east until cleared | Right beside the enemy's attack exit: **West Crown Bridge** 15.2 m, Willow Ford 15.9 m (open once the nest dies, so clearing the nest opens your own vein to raids); Magpies at W4 |
| **Ford Vein** (the contested one) | 76.3 m / ~80 m | 66.7 m / **~70 m via Reed Ford** (once its nest is cleared; -35 % speed in the ford) or ~78 m via Saltgate Bridge (21 m from the node) | The **Reed Ford Nest** (14.4 m, in the ford) keeps the short enemy route closed until someone clears it; your X2 / X5 halls 4 m apart and the rich-node workers make it one defended district; whoever holds **Rookwatch** (10.6 m, sight 22) sees it | The enemy's shortest crossing points straight at it: **by path it is nearer to the enemy than to you** (mirror: the enemy's Ford Vein by Willow Ford is nearer to you). Rookwatch is enemy-nearer (`map-fill.md` 4.1), the Grizzlemaw's Old Wood Den lies 22 m north of X5, Magpies at W5. A raid prize for both sides: the natural place for fights at Reed Ford |

### 6.2 Checked distances (the numbers behind the table; 17.S2 test repeats them)
| Object | Glade node / X3 | Millrace node / X4 | Ford node / X5 | Rule |
|---|---|---|---|---|
| Nearest camp | Stag 7.6 / **15.1** | Willow Ford Nest 15.9 / 18.9 | Reed Ford Nest 14.4 / 22.5; SF 13.9 (its tower range 11 never reaches the nest ring) | Camps >= 14 m from nodes and slots (`map-fill.md` 5.2): **the Glade node and SG are the deliberate exception** (sealed guarded vein), SF is 0.1 m short (accepted); the 8 m build ban holds everywhere (SG 12.0 m) |
| Nearest lair edge | Colossus Crag 13.8 / West Heath 12.1 | - | Old Wood Den 18.8 / 16.6 | >= 13 m from nodes, >= 9 m from slots |
| Roads / lane | West road 7.9 / 4.1 (footprint corner) | Lane 14.1 / 12.7 | North road (nw2 - n_door) 18 / 15.3 | Outside the 2.5 m corridor and the 2.5 m lane half-width |
| River / crossings | - | Water edge 5.7 (south river), moat 8.7 / Crown Bridge W 18, Willow Ford 18.8 | Water edge 11.8 / Reed Ford footprint 19.5 | `"Can't build on water"` 1 m, `"Too close to a crossing"` 8 m |
| Points | West Wayshrine 19 / - | Millwatch 17.3 / 13.3 | Rookwatch 10.6 (3.6 m outside its ring), Mossmere Well 9.9 (3.9 m outside) / X5 centre 10.6 and 9.0 m from them: one X5 footprint corner reaches **0.6 m into Rookwatch's ring** (a presence zone, not an obstacle; accepted) | Points >= 8 m from halls (centre); nodes outside capture circles |
| Peddler / tavern | - | - | Peddler 8.5 / 10.0 from X5's footprint; SF 5.1 from the peddler, 8.2 from the tavern (footprint gap 4 m) | Peddler clearing r 5 |
| Terrain patches | West Cinder Scar edge 8.7 (after the move below) | Willow Marsh edge 10.2; Millwatch Terrace 6 m from X4's footprint | Mossmere Frost edge 6.4, Reed Marsh edge 6.7 (after the moves below) / Frost 3.6 from X5 | Patch edge >= 6 m from nodes, >= 3 m from slots |
| Buildings | - | - | X5 footprint 4.0 m from X2's (moved), 3.6 m from Rookwatch's tower, 5.5 m from its node | Hall gaps >= 2 m |
| Other nodes | Natural 26.7 | Natural 21.4 | Rich 19.9 (X5 11.4, X2 7.1), Glade 32.7 | Separate sites (> 18 m) |
| GM slot | - | - | - | Section 1.1 |

### 6.3 What moves (all mirrored; systems 17.S2 unless noted)
| What | Old | New | Why |
|---|---|---|---|
| Lost Cache `CACHE_SPOTS[1]` / `[3]` | `(-6, 27)` / `(6, -27)` | **`(-1, 31)` / `(1, -31)`** | X4 needs the room. New spot: 9.96 m from the Willow Ford Nest (> 9.4 m, no Mirefang wake), keep -> cache 43.7 m (the other pair is 45.6 m: fairer than before) |
| Terrain patch `ash_scar_w` (and its mirror) | centre `(-31, 2)` | **`(-29, 2)`** | 2.5 m between the X3 footprint and the patch edge; the Lost Cache `(-30, 0)` stays inside it. Within the 2 m move allowed by `terrain.md` 4.1 (owner of the patch table: game-designer; code 17.S2) |
| Rabbit home `(-40, 8)` (and mirror) | `(-40, 8)` | **`(-32, 12)`** | Out of the X3 hall; still >= 14 m from every camp |
| **Rich-hall slot X2** (`RICH_HALL_SPOT`, bot slot; `rich_hall_spot(team)`) | `(-33, -33)` / `(33, 33)` | **`(-41, -33)` / `(41, 33)`** | X5 needs the old spot. New X2: 7.1 m from the rich node (footprint 4.0 m from it, the >= 4 rule), 7.2 m from the west road centre (footprint outside the corridor), 11 m from the Greymane Hollow lair edge, 14.2 m from Mossmere Well, 9.5 m from W2. The rich node's drop-off trip gets ~2 m shorter on **both** sides (mirrored, fair) |
| Terrain patch `snow_well_w` (and mirror) | centre `(-31, -24)` | **`(-32.5, -24)`** | Ford node 6.4 m from the patch edge (was 5.2); Mossmere Well's ring stays mostly inside. 1.5 m move (`terrain.md` 4.1 allows 2 m) |
| Terrain patch `mud_reed_w` (and its mirror, the Willow Marsh `(14.5, 33)`) | centre `(-14.5, -33)` | **`(-13.5, -34)`** | Ford node 6.7 m from the patch edge (was 5.4); still the west approach of Reed Ford, 2.6 m from the water. 1.4 m move |
| Deer graze spots `(-30, -32)` and `(-44, -30)` (north-west herd; mirrors in the south-east herd) | as listed | **`(-36, -26)`** and **`(-45, -26)`** | Out of the X5 and new X2 footprints; 16.0 / 17.9 m from the Stag Glade (>= 14) |
Nothing else moves: posts, roads, guild houses, taverns, peddlers, points, camps, lairs, landmarks, H1 / V1-V3 / S1-S4 / M1 /
R1 / R2 / T2 / T3 / X1 / C1 keep their coordinates.

### 6.4 The sealed node (Glade Vein)
- `CrystalNode.sealed_by = &"camp_stag_w"` (mirror `&"camp_stag_e"`). While sealed: `can_mine()` false; a worker ordered on it
  answers `Sealed: the Hollow Stag guards this vein` and stays idle; the node shows pale roots over the crystals
  (`set_sealed(true)` on the site dressing) and a small antler icon on the minimap / hover card.
- Hall X3 can be built while sealed (a player may prepare), but its node gives nothing until the seal breaks.
- The **first clear** of that camp by anyone calls `unseal()` for good (`The Glade Vein is open`: own team when own kill;
  the enemy's clear only if the camp is visible, the `map-fill.md` 5.3 message rule). A later respawned stag attacks workers
  there as any camp does.
- Why: the stag first spawns at 3:30; without the seal an early hall there would block its first spawn and skip the guard.

### 6.5 Magpies, towers, fairness
- All three new nodes are **remote** (> 30 m from the own keep): `TradeNetwork.remote_nodes` lists them; W3 / W4 / W5 are their
  worker spots (`worker_spot(node)`), 11.4 / 13.0 / 13.2 m from the node. Ambush spots keep >= 10 m from camps (W3 14 m from
  the stag, W5 11.0 m from the Reed Ford Nest). W5 `(-16, -42)` sits on the riverbank below Rookwatch (8.1 m, outside its
  ring), 7.8 m from Saltgate Bridge: bands from the north-west Den reach it along the north road.
- Bot tower slots SG / SM / SF (rule 10e of `market-trade.md` extended, section 7). SF `(-17, -23)` covers the Ford node
  (9.3 m, inside range 11) and the peddler road, and stays out of the nest's reach. Tower `max_count` 4 still applies.
- Fairness test (17.S2, the `map-fill.md` 2.5 method): navmesh path length from each keep's drop-off to its own Glade, Millrace
  and Ford nodes, the moved X2 and the other side's three nodes differs by < 1 % between the mirrored pairs; every new or moved
  object has its twin at `-p`; BuildGrid accepts X2 / X3 / X4 / X5 / SG / SM / SF / GM on both sides. The Ford pair is also
  checked for the "contested" intent: each keep's path to the **enemy's** Ford node (over Reed / Willow Ford, nests dead)
  is within 0.85-1.0 x its path to its **own** Ford node.

## 7. The bot (ai 17.A1: new rule **16** of `ai.md` + rule 3 / 10e extensions; knobs in `AIProfile` / `data/ai/*.tres`)
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `market_build` (Grand Market) | after 12:00 | after the Stronghold (research off: 8:00) | after the Stronghold (off: 7:00) |
| `heroic_plan` | the heroic of its last top item, never an epic | kingdom heroic (below), then its epic | kingdom heroic, its epic, then Oathbound Warbanner |
| `epic_race` | - | buys its epic when affordable | also **races**: an enemy wizard seen with the same heroic in the last 90 s -> saves for that epic first (no other item) |
| `third_expansion` (X3 Glade) | never | stag cleared once, and home a + b < 800 or 10:30 | stag cleared once, and 9:30 |
| `fourth_expansion` (X4 Millrace) | never | natural < 800, or X2 impossible for 2 min, or 13:00 | 12:00 |
| `ford_expansion` (X5 Ford) | never | X2 completed, and rich node < 1 200 or 14:00, and `own_strength >= 1.2 x max(seen_strength, 250)`, and no enemy army seen within 25 m of Reed Ford in 60 s | X2 completed and 12:30 (same strength / ford checks, ratio 1.1) |
| Rule | Trigger -> action |
|---|---|
| **16a Grand Market** | `market_build` met, crystals >= 275 + 100, no build waiting, no defence -> place at **GM** `(53, -29)` (player-side bot `(-53, 29)`); build row **10**; a destroyed market is rebuilt after 60 s |
| **16b Shopping** | The `items.md` rule (buy when the wizard is within 12 m of a shop, first affordable entry, one per tick) continues past the end of each difficulty list with the kingdom heroic: Fire **Pyremaster's Codex** (hard: Dawnsplitter), Shadow **Hungering Reliquary**, Ice **Hoarfrost Regalia**, Nature **Eldergrove Heart** (the wish-list helper buys the missing top first). Gold for T4 / T5 is reserved before wares (rule 10g) once the heroic's top item is owned |
| **16c Epic** | Its heroic owned, its epic in the showcase and unclaimed, Citadel (or 12:00), essence and gold enough -> buy it. The relic: a carried trophy first (rule 11b already picks up drops within 12 m), else the Starforged Relic. Its epic claimed by the enemy -> keep the heroic, next target Oathbound Warbanner (hard) or save |
| **16d Elixirs** | Hard only: Titan's Draught (melee / attack wizards) or Sage's Incense (casters) when rule 7 launches an attack with the wizard, if in stock and off cooldown |
| **3 extension** | X3 at `third_expansion`, X4 at `fourth_expansion`, X5 at `ford_expansion` (crystals >= 150, no attack out, the hall slot not seen enemy-held in 30 s). X2 uses its new slot `(41, 33)` / player-side `(-41, -33)`. Worker targets **unchanged** (12 max): a depleted node's workers move to the newest completed expansion's node first (rule 3's "node at 0" line); with X2 and X5 both up, rich and Ford workers deliver to the nearer of the two |
| **3 Ford guard** | X5 completed -> the rally point for defence (rule 1) treats the Ford node as a base node (intrusions within 28 m of X5 fire rule 1, as for any building); while X5 stands, rule 11a never creeps the nest in the ford beside it (Reed Ford for the player side, Willow Ford for the enemy side): that nest is the vein's gate |
| **11a extension** | Normal / hard: while `third_expansion` waits for the seal, the own-bank Hollow Stag gets +0.2 priority in rule 11c ordering (it opens the vein) |
| **10e extension** | Magpie raid on the Glade / Millrace / Ford node -> tower at **SG** / **SM** / **SF** (same rule as S3 / S4) |
| Champion **B2** | The forward-hall list gains the enemy's X3 / X4 / X5 |
| Champion **B12** (normal, hard) | Own X3, X4 or X5 hall under construction or under attack in the last 30 s -> **Guard 50** on it (max 1; X5 first) |
| Strength | Wizard strength stays `170 + 30 x level + items / 5`, **+150 while it carries an epic** (unique effects); champions unchanged |
- Expected (normal, trade on, research on): Stronghold 7:00-7:45, Grand Market 7:45-8:30, kingdom heroic 11:00-13:00, Citadel
  11:00-12:30, epic 13:30-16:00 when the showcase has it (1 in 2 odds for a fixed epic), X3 10:30-12:00, X4 13:00-14:30,
  X5 14:00-16:00 (only when ahead or even), often lost once to a raid through the opened ford.

## 8. UI: what must be shown (layouts, sizes, looks: ui-designer, `docs/design/ui-market.md`, task 17.D2)
| Element | Content | Interaction |
|---|---|---|
| Build menu | **Grand Market I** at r3c3 (tooltip 1.1) + reason when disabled (`Needs a Stronghold`, `Available at 7:00`, `Only one Grand Market`) | B then I = place |
| Grand Market card / panel | r1c1 Shop T, r1c2 Showcase; panel lines of 1.1 | |
| **Shop window** (T in range; the market's buttons) | At a Grand Market: tabs **Common · Fine · Rare · Heroic · Epic · Relics & elixirs**; at a keep / hall / peddler: the existing grid (tiers 1-3 + consumables) unchanged. Item buttons with the tier border; T5 border shimmer; price = essence number + a gold chip when there is a gold part (folded price when trade is off); owned parts green (existing); unaffordable alpha 0.45 | Buy / Combine as today; the details pane shows the recipe tree up to **4 levels** (item, heroic, top, components) and the relic slot as a bronze "any relic" socket |
| **Epic tab** | The 4 showcase cards (large icon, name, effect lines, price) with a state: `Available` / `Claimed by Malrik` (owner portrait, greyed) / `Returns in 1:40` / `Needs a Citadel` (padlock) / `Needs Dawnsplitter` (the heroic) / `One epic per wizard`; the 4 absent epics are not shown | Buy = the full recipe in one click |
| Limits | A line in the Heroic / Epic tabs: `Heroic / epic items 1 / 2 · Epic 0 / 1`; relic stock `Starforged Relic 1 / 2 · next in 2:14` | |
| Rarity borders everywhere | Inventory bar, champion inspect slots, tooltips, ground items (cube colour), shop: the colours of section 2; T5 shimmer everywhere it is drawn | |
| Tooltip | `Sunfall Edge  [Alt+2]  · Epic\n+70 damage · -30 % attack cooldown · +220 HP · +0.4 speed\nDawnbreak: every 6th attack: 120 damage around the target, dazes 0.5 s.\nSell 1 630 essence · 287 gold` | Actives add the `Active:` line (existing format) |
| Claim banner | Both teams: `Malrik claimed Sunfall Edge!` (banner font, 3 s) + bell sound; the owner's HP bar gets a small magenta gem while the enemy can see it | |
| Enemy inspect | The enemy wizard's visible inventory shows its epic (existing inspect rule) | |
| Sealed node | Hover card `Glade Vein · 1 800 crystals · Sealed: the Hollow Stag guards this vein`; antler icon on the minimap node dot | |
| Site names | Node hover cards name the site (`Millrace Vein · 1 500 crystals`, `Ford Vein · 1 600 crystals`), like the rich node's card | |
| Messages | `The Grand Market opens its vault` · `Epic showcase: <4 names>` · `<Wizard> claimed <epic>!` · `<epic> returns to the showcase` · `A Starforged Relic arrives at your Grand Market` · `Underdog discount: heroic and epic recipes -15 %` · `Epic bounty: +120` · `The Glade Vein is open` · `Sealed: the Hollow Stag guards this vein` | `show_message`; claim lines as banners |
| End screen | `Epic: Sunfall Edge (13:42) · Heroic items 2 · Relics found 3` per side | |
| Help text | Adds `B, I: Grand Market (heroic and epic items)` | |
| Audio (ui-coder, SFX bus) | Coin clink per purchase (existing), a deeper chime for T4, a bell + choir swell on an epic claim (both teams), a soft ring on a relic restock (own) | |
**Keys**: build menu **I** = Grand Market. Nothing else new (T, Alt+1-6 / Numpad unchanged).

## 9. Balance
### 9.1 Budget per side (normal, both trading, map fill on)
| By | Essence (items.md + map-fill) | Gold (market-trade 11.1) | Typical wizard gear |
|---|---|---|---|
| 8:00 | ~1 700 | ~300 | 1 mid + components |
| 12:00 | ~3 000 | ~1 200 (minus wares / tech ~700) | 1 top + 1 mid, or a top on the way to a heroic |
| 15:00 | ~4 000 | ~2 000 (minus ~1 200) | **Heroic** + mid, or an **epic** if the side focused one line (~3 200 essence + 575 gold) |
| 18:00 | ~4 800 | ~2 800 | Epic + a top / heroic |
So: heroics from ~11:00, epics **13:30-16:00**, in the last third of a 15-20 min game. The Grand Market (275 crystals, ~2 soldiers
at 8:00) competes with the Stronghold's research; the gold part competes with wares and tech (a real choice).

### 9.2 Fight checks (level 6, as the `items.md` table)
| Setup | Result |
|---|---|
| Vessa L6 + **Sunfall Edge** + Ashen Greaves (~3 860 e + 575 g): 695 HP, 94 damage at cooldown 0.91 (~103 DPS) + burn ~12 + Dawnbreak ~22 AoE + Sunder, 18 % lifesteal, 6.0 m/s | vs 10 Shades (800 crystals): wins with ~450 HP. vs 10 Nightbolts (1 000): **wins with ~15 % HP** (the top-item build of `items.md` dies). vs 3 Shadow Knights: wins with ~30 %. vs 14 ranged + a keep: dies. An epic wizard is worth **~1 300-1 500 crystals** of soldiers (a top build ~1 000) for ~1 100 crystal-equivalent spent |
| Malrik L6 + **The Unfallen Rampart** (1 100 HP, armor 55 = x0.65) vs 10 Flame Guards (~130 DPS) | ~13 s + Last Stand 2.5 s + 20 % heal = **~17 s** to kill (no items ~5 s); he deals ~40 DPS: a wall, not a killer. Once per 180 s |
| **Standard of the Undying Host** on a 30-pop army (~2 400 crystals) | +22 % damage (Banner +15 %): ~+170 crystals of value; Stand Fast saves 4-8 soldiers in one big fight every 100 s (~+400-600 crystals then). Strong in the decisive fight, useless alone |
| **Tome of the Ninth Flame** Vessa (spell power 100 with the cap, CDR 40) | Fireball 85 -> 170, every 3rd cast +85 more: a Shade line (80-90 HP) melts; Knights (420 HP) and keeps still need the army. Mana is the limit (Wildfire refunds only on 3+ hits) |
| Epic vs titan (both Citadel tier) | A titan costs ~600 crystals + the Lair and pop; an epic ~3 200 essence + 575 gold. Similar power band from two different wallets |
Rule of thumb kept: 1 essence spent = 0.2 crystals of army strength; gold at the 100 -> 80 exchange rate. Unique effects add
~+150 (the bot strength bonus).

### 9.3 Match length and anti-snowball
- **Longer, not shorter:** the three new sites keep income flowing after the home nodes empty (~10:30) in places the enemy
  must walk to (more fronts to defend, the Glade needs the stag first); both sides gain alike. Gear power arrives late (epics
  after 13:30, behind the Citadel), when bases are also at their toughest (Citadel keep x1.4).
- **The three sites in numbers** (per side; worker cap 12 unchanged, so peak income stays ~840 / min: the sites add
  **duration**, not a bigger peak):
| | Before step 17 | Glade + Millrace | + Ford Vein (user Q3) |
|---|---|---|---|
| Crystals on the map per side | 9 000 | 12 300 | **13 900** (+54 %) |
| Left after the home nodes run dry (~10:30) | ~3 000 (natural ~1 000 + rich 2 500, minus what is mined) | ~6 300 | **~7 900** |
| Income falls below ~420 / min (6 workers' worth) | ~17:30 (natural empty) | ~21:00 | **~23:00+** |
| Remote fronts to guard (Magpie targets, raid targets) | 2 (natural, rich) | 4 | **5** |
| Expected median length (even pairs, on top of steps 10-14) | - | +0:45 to +1:30 | **+1:00 to +2:00** |
- **Why the Ford Vein does not simply feed the leader:** the bot takes it only when ahead or even (1.2x strength); it is the
  one site whose **enemy path is shorter** than the owner's once the ford nest is dead, so the side behind raids it cheaply
  (a small group through Reed / Willow Ford, 14 m to the workers); Magpies weight worker targets by crystals mined remotely
  (`market-trade.md` 5.2), so the richer side's Ford Vein draws the bands; and it sits beside Rookwatch, the enemy-nearer
  tower, so the owner is often half-blind there. Risk: more total crystals can mean **stalemates past 22:00** when neither side
  breaks the other; the knobs below cut the Ford Vein first.
- Expected overall: even pairs **+1:00 to +2:00** median length on top of steps 10-14 (the Grand Market itself ~0: it costs
  ~2 soldiers at 8:00 and pays back as gear after 11:00).
- **Comeback levers:** underdog -15 % on T4 / T5 recipes; the epic bounty (+120 essence) makes the epic carrier a target;
  uniqueness means the side behind can still claim a different showcase epic; 1 epic and 2 T4-T5 per wizard cap the carry.
- **Not a new snowball:** item power scales with essence earned by fighting, like today; an epic wizard still dies to focus
  fire; epics are sustain / tempo tools more than kill tools; everything stays under the stat caps.

### 9.4 Knobs (one at a time; 17.D3)
| Symptom | Knob |
|---|---|
| Epics never bought before 16:00 (runs or playtest) | T5 recipe 400 e + 250 g -> **300 e + 200 g**; Starforged restock 240 -> **180 s** |
| Epic owner wins > 70 % of games with exactly one epic | Stats of that epic -15 %; Last Stand 2.5 -> **1.5 s**; Stand Fast 3 -> **2 s**; Rally IV +0.22 -> **+0.18** |
| Games shorter than the control | New sites 1 800 / 1 500 / 1 600 -> **2 200 / 1 800 / 2 000**; Grand Market needs a **Citadel** for T4 too |
| Games > 22:00 or stalemates | Ford Vein 1 600 -> **1 000** first; then Glade / Millrace -> **1 400 / 1 200**; X4 bot trigger 13:00 -> **15:00** |
| The side with the Ford Vein wins > 70 % of games where only one side took it | Ford Vein 1 600 -> **1 200**; `ford_expansion` ratio 1.2 -> **1.5**; the Ford Vein sealed by its ford nest like the Glade (unsealed on the nest's first clear) |
| Ford Vein never taken (bot or playtest) | Ratio 1.2 -> **1.0**; crystals 1 600 -> **2 000** |
| Gold still piles up | T4 recipe gold 200 -> **300**; add a gold-only elixir |
| Nobody builds the market | Cost 275 -> **225**; research off time 7:00 -> **6:00** |
| Glade Vein never taken | Seal off (the stag only guards it by aggro); crystals 1 800 -> 2 200 |
| Millrace Vein always lost | Crystals 1 500 -> **1 800** and SM tower +20 % HP; or move node 2 m west (re-run 6.5) |
| Champions too strong with T4 | Champions T1-T3 only (Q2 option C) |

### 9.5 Re-test plan (lead 17.L2, then 17.D3)
Harness: the 9.C11 / 10.L2 / 12.L2 bot-vs-bot run (normal, cap 24:00) + flags `--no-market` (no Grand Market, no new items)
and `--no-new-sites` (no Glade / Millrace / Ford nodes; X2 back at `(-33, -33)` so the control is the step-14 map).
| Round | Pairs (both orders) | Runs | Pass |
|---|---|---|---|
| A | fire-shadow, nature-ice, shadow-nature | 2 with + 2 `--no-market --no-new-sites` each = 12 | Median length with >= control **- 0:30**, inside **15:00-20:00** (+-1:00 tolerated); no run over 24:00 without a winner more than once |
| B | same | - | A Grand Market in >= 80 % of games reaching 10:00; >= 1 heroic per side in >= 60 % of games reaching 14:00; an epic in >= 50 % of games reaching 16:00, first epic 13:00-17:00; the epic owner wins <= 70 % of games with exactly one epic; X3 taken in >= 50 % and X4 in >= 30 % of games reaching 13:00; X5 taken in >= 30 % of games reaching 15:00 and raided (hall or workers damaged) in >= 50 % of those; the Ford Vein owner wins <= 70 % of games where only one side took it; 0 script errors |
| C | ice-ice, nature-nature mirrors | 2 each | Crystals and essence within **1.1x** at 10:00 and 15:00 |
| Perf | perf test + 2 markets, 2 epic carriers with auras, 1 Sapling, 1 Afterimage, 3 item Risen | 1 | `PERF OK`, stuck = 0 |

## 10. Art list (tech-artists, one agent per line; style `art-keep.md` section 0: chunky, hand-painted, readable at 40 m, 2-4 glow points)
| Id | Asset | Look (the 40 m black test) | Budget / hooks |
|---|---|---|---|
| 17.V1 | **Grand Market base** (shared) | Domed merchant hall 6 x 6 m, bell-and-clock tower ~7.5 m (dominant), round vault door (secondary), two arcade stalls with 4 display plinths (the showcase), coin-sack and crate props; construction stages as other buildings | `art/buildings/grand_market/base/`; hall budget; hooks `set_selected`, construction, damage, `set_showcase(icons: Array)` (plinth glows: 4 slots, claimed = dark), `play_purchase(tier: int)` (coin burst; T4 crimson flash; T5 bell swing + light column), `set_relic_stock(n)` (0-2 glowing cores on a rack), `set_team_color(c)` |
| 17.V2-17.V5 | **Kingdom trims** (one agent each: Fire, Shadow, Ice, Nature) | Inherited scene of V1: roof / dome material, banners, lanterns (kingdom glow), signature prop (1.2) | `art/buildings/grand_market/<kingdom>/grand_market_<kingdom>.tscn`; <= 5 extra materials each |
| 17.V6 | **Icons T1-T3 + elixirs** (8) | Lodestone Bead, Quickfire Flint, Gilded Buckler, Stormglass Sling, Echo Prism, Muster Standard, Titan's Draught, Sage's Incense | `art/icons/items/<id>.png`, same renderer / size as the item icon set |
| 17.V7 | **Icons T4 Heroic** (8) | Heavier silhouettes, crimson accents | same |
| 17.V8 | **Icons T5 Epic** (8) | The best icons of the game: each readable as its effect (sun lance, twin flame, doorway, rampart, standard, frost heart, seed, ossuary) | same; plus a 256 px card art per epic for the Epic tab (`art/icons/items/epic_cards/`) |
| 17.V9 | **Icons relics** (9) | 8 trophies (tusks, plumes, pelts, claws; B variants darker / scarred) + the Starforged Relic (a star-metal core in a cage) | same |
| 17.V10 | **Rarity frames** | 5 tier frames + relic frame for slots and shop buttons; the epic shimmer (a small `canvas_item` shader: a light band sweep every 2 s) | `art/ui/rarity/` (frames `.png`, `epic_shimmer.gdshader`) |
| 17.V11 | **Item VFX** | `epic_claim` (magenta-gold column + bell ring on the buyer), `epic_owner` (thin magenta ground ring under an epic carrier, visible to all when visible), `dawnbreak` (sun lance from the sky, r 2.5 flash), `twincast` (a ghost copy of the spell glyph), `phase_door` (dark doorway at both ends), `last_stand` (golden cracked husk 2.5 s), `bulwark_pulse`, `stand_fast` (banner shock ring + sigils over soldiers, one MultiMesh <= 60), `everwinter` (frost ring r 7, looping, cheap), `hollow_chorus` (violet wisps at a corpse), `sunder` (crack decal stacks on the target), `chain_spark` (arc), `deflect` (gold pip flash), `rootgrasp`, `relic_restock` | `art/vfx/item_vfx.gd` (`class_name ItemVfx`, group `"item_vfx"`, `play(id, at, target)`), `art/vfx/item_*`; pooled, no lights |
| 17.V12 | **Warden Sapling + Afterimage** | Sapling: knee-to-chest-high glowing sapling in a root ring, roots that lash out (root pulse anim), wilts at 20 s. Afterimage: the owner's model with a dark-glass shader (`afterimage.gdshader`), fades at 4 s | `art/units/summons/warden_sapling/`, `art/vfx/afterimage.gdshader`; soldier budget |
| 17.V13 | **Expansion site dressing** | Glade Vein: crystals grown through old antler-shaped roots, pale root cage while sealed (`set_sealed(bool)`), moss and a fallen antler; Millrace Vein: an old stone mill-race channel and a broken waterwheel beside the node, reeds; Ford Vein: crystals breaking through a half-buried ferryman's landing (mooring posts, a rotten punt, rope) on the heath above Reed Ford, frost-rimed on the Mossmere side | `art/environment/sites/glade_vein.tscn`, `millrace_vein.tscn`, `ford_vein.tscn`; draw-only (colliders only where the node already has one) |
| 17.V14 | **Misc icons** | Grand Market (4 kingdom crests), Showcase button, relic socket, sealed node antler, underdog discount chip, epic gem | `art/icons/` (new files only) |

## 11. Performance
- Items: all passives through the existing hooks (`attack_landed`, `spell_hit`, `spell_cast`, auras at 0.5 s). Everwinter and
  the army auras reuse `apply_aura` (cached 0.5 s pass). Hollow Chorus listens to `Events.unit_died`. Budget for all new item
  logic **< 0.05 ms / frame** average.
- Units: at most 1 Afterimage + 1 Sapling per epic owner and 3 item Risen: peak unit count +5 (still < 200).
- MarketLedger: timers only. Two more buildings and 4 nodes: nothing measurable. Perf test additions in 9.5.

## 12. Campaign
- `Skirmish.grand_market_enabled` (exported, like `trade_enabled`): true in the skirmish, **false by default in missions**;
  `new_sites_enabled` likewise (the Glade / Millrace / Ford nodes and the moved X2 are Crown Hollow only).
- If a mission enables the market later: heroic items carry between missions like other items; **epics never carry** (removed
  at mission end, refunded 50 % in essence, capped by the 1 500 carry cap). Proposed first use: none before mission 5 (research).

## 13. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 17.L1)
Rule for phase-1 agents (as in steps 9-14): never use another step-17 agent's new `class_name` as a static type; reach it with
`load()` guarded by `ResourceLoader.exists`, groups, `has_method()`, `get()`.
- **ItemType** (items, extends the frozen `items.md` API; enum values appended, never reordered): `tier` gains `HEROIC`, `EPIC`,
  `RELIC`; `rarity() -> int` (component 1, mid 2, top 3, heroic 4, epic 5, relic 4, consumable 1 or `rarity_override`, artifact
  5); `gold_cost: int` (gold part of the recipe / price, 0 default), `total_gold_cost() -> int`, `total_cost()` unchanged (essence);
  `sold_at` gains bit **4** = Grand Market (`SOLD_AT_MARKET := 4`); `wizard_only: bool`; `unique_per_match: bool`;
  `is_relic: bool`; `is_wildcard: bool` + `wildcard_tag: StringName` (`&"relic"`; the part `data/items/relic_any.tres`);
  `aura_stats: Dictionary` stays per item, merged per stat (4, aura rule).
- **Inventory** (items): `price_of(type) -> Dictionary` (`{essence, gold, parts_consumed: Array[int], buys: Array[ItemType]}`
  after fold, underdog and champion rules), `can_buy(type) -> String` (refusals of section 4, in order), `buy` spends essence
  (bank or purse) and gold (`GoldBank.spend`), `legend_count() -> int`, `epic_count() -> int`, `sell(slot) -> int` (essence
  returned; gold returned through `GoldBank.add(n, &"sale")`). Signals unchanged (+ `item_bought(type)` carries epics).
- **Recipes** (items): `plan(inventory, type, shop: Node = null) -> Dictionary` resolves `relic_any` (cheapest carried relic,
  else the shop's Starforged stock) and returns the gold part.
- **MarketLedger** (`scripts/items/market_ledger.gd`, `class_name MarketLedger extends Node`, one per match, group
  `"market_ledger"`, `static func instance(tree: SceneTree) -> MarketLedger`): `SHOWCASE_SIZE := 4`, `setup(rng_seed: int)`,
  `showcase() -> Array[StringName]`, `is_revealed(team: int) -> bool`, `reveal(team)`, `epic_owner(id) -> Node` (null),
  `epic_returns_in(id) -> float`, `can_claim(id, buyer: Node) -> String`, `claim(id, buyer: Node)`, `release(id)` (120 s),
  `relic_stock(team) -> int`, `relic_restock_left(team) -> float`, `start_relics(team)`, `take_relic(team) -> bool`,
  `RELIC_MAX := 2`, `RELIC_INTERVAL := 240.0`, `UNDERDOG_DISCOUNT := 0.15`, `underdog_mult(team) -> float`, `EPIC_BOUNTY := 120`,
  signals `epic_claimed(id: StringName, owner: Node, team: int)`, `epic_returned(id: StringName)`, `relic_restocked(team: int,
  stock: int)`, `showcase_revealed(team: int, ids: Array)`.
- **GrandMarket** (`scripts/buildings/grand_market.gd`, `class_name GrandMarket extends Building`, kind `&"grand_market"`, group
  `"grand_markets"`): `is_shop() -> bool` (true when completed), `sells(type: ItemType) -> bool`, `static func of_team(team: int)
  -> GrandMarket` (completed, alive, or null; not `for_team`), forwards `play_purchase(tier)`, `set_showcase`, `set_relic_stock`
  to its model; on completion calls `MarketLedger.reveal(team)` and `start_relics(team)`.
- **BuildingType / BuildGrid** (systems): 4 `.tres` (`data/buildings/<kingdom>_grand_market.tres`), `ALL_IDS` gains them;
  reuse `requires_kind`, `required_keep_tier` (2), `min_time` (420, research-off only), `max_keep_distance` (25); messages
  `MSG_MARKET2_LIMIT := "Only one Grand Market"`, `"Must be within 25 m of your keep"` (the distance message takes the type's value).
- **Shops**: any node with `is_shop()` keeps working; `Inventory.nearest_shop()` also finds Grand Markets; `sold_at` decides.
- **CrystalNode** (systems): `sealed_by: StringName` (`&""`), `is_sealed() -> bool`, `unseal()`, signal `unsealed(node)`;
  `can_mine` false while sealed; `Worker.command_gather` on a sealed node returns / shows `"Sealed: the Hollow Stag guards this vein"`.
- **CampManager** (systems): on a camp's first `cleared`, `unseal()` every node whose `sealed_by == camp_id`.
- **Skirmish** (systems): `FIRE_NODES` gains `&"node_fire_glade": Vector3(-41, 0, -3.5)`, `&"node_fire_millrace": Vector3(-3, 0,
  23)`, `&"node_fire_ford": Vector3(-22.5, 0, -30.5)`; `NODE_AMOUNTS` gains `&"glade": 1800`, `&"millrace": 1500`,
  `&"ford": 1600`; **`RICH_HALL_SPOT` = `Vector3(-41, 0, -33)`** (was `(-33, 0, -33)`; `rich_hall_spot(team)` follows);
  `expansion_slot(team, which: StringName) -> Vector3` (`&"natural"` X1, `&"rich"` X2, `&"glade"` X3, `&"millrace"` X4,
  `&"ford"` X5 `(-31, -33)`); `grand_market_slot(team) -> Vector3` (GM); `tower_slot(team, which)` gains `&"glade"` SG /
  `&"millrace"` SM / `&"ford"` SF; `WORKER_SPOTS` gains W3 / W4 / W5; `CACHE_SPOTS[1]` / `[3]` = `(-1, 31)` / `(1, -31)`;
  terrain patch centres `ash_scar_w (-29, 2)`, `snow_well_w (-32.5, -24)`, `mud_reed_w (-13.5, -34)` (+ mirrors); deer graze
  spots `(-36, -26)`, `(-45, -26)` (+ mirrors); `@export var grand_market_enabled := true`, `@export var new_sites_enabled :=
  true` (false = no new nodes, X2 back at `(-33, -33)`, no patch / deer / cache moves: the step-14 map); creates the
  `MarketLedger`; end-screen line.
- **Gameplay hooks** (gameplay): status `unyielding` (takes no damage; `Unit.STATUSES`), `add_hp_floor(source_id: StringName,
  duration: float)` (cannot drop below 1 HP), `SpellCaster.echo_cast(spell_id, target, mult: float) -> String` (no mana, no
  cooldown, skips movement spells), `data/units/phase_afterimage.tres` (decoy, `taunted` pulse), `data/units/warden_sapling.tres`
  (stationary support: root pulse, hero regen), Risen spawned with a source id (`item:hollow_chorus`) so the item counts its 3;
  armor debuff stacks through a modifier on the target (`item:sunder`).
- **Events**: no change (claims go through `MarketLedger` signals).
- **Models / VFX paths**: section 10. **Ownership**: `scripts/items/market_ledger.gd`, `data/items/*` = items-coder;
  `scripts/buildings/grand_market.gd`, `data/buildings/*_grand_market.tres`, node / slot changes = systems; `data/units/
  phase_afterimage.tres`, `warden_sapling.tres` = gameplay; `art/buildings/grand_market/`, `art/icons/items/`, `art/ui/rarity/`,
  `art/vfx/item_*`, `art/units/summons/`, `art/environment/sites/` = tech-artists.

## 14. What changes in other specs (17.D3 writes the lines after the build)
- `items.md`: tiers 4-5 + relic, colours of section 2, `sold_at` bit 4, the per-stat aura rule, Blink family, the 33 new items
  (pointer to this file), gold parts, the Grand Market as a shop. `market-trade.md`: gold also buys T4 / T5 recipes and the
  Starforged Relic (3.2 row), the "gold piles up" knob answered. `champions.md`: purse buying T4 (gold part 1:1 in essence),
  max 1 T4, wish-list tails (16b heroics), B12. `research.md`: the Grand Market needs a Stronghold, epics a Citadel.
  `map-fill.md`: the Glade Vein camp exception, the cache move, the rabbit home move, the two deer graze spots, trophies exist
  now (5.5), the fairness pairs (incl. the Ford pair). `terrain.md`: centres `ash_scar_w (-29, 2)`, `snow_well_w (-32.5, -24)`,
  `mud_reed_w (-13.5, -34)` (+ mirrors). `skirmish-1v1.md` / `balance-1.md`: 14 nodes, amounts, X2 moved to `(-41, -33)` /
  `(41, 33)`, X3 / X4 / X5. `for-ai-coder.md` handoff line on `rich_hall_spot` updated by the lead. `ai.md`: rule 16, rule 3 /
  10e / 11a extensions, slots GM / X2 (moved) / X3 / X4 / X5 / SG / SM / SF, build row 10, strength +150 for an epic.
  `levels.md`: victim row Grand Market 120. `buildings.md`: build menu row 3 (J, L, I). `ui-hud.md`: rarity colours.
  `CLAUDE.md` (lead): section 13 contracts, Keys line (build menu I), owner rows.

## 15. Task list (step 17; build after steps 10-14 integrate: shares `inventory.gd`, `skirmish.gd`, `commander.gd`, shop UI)
**Phase 0:** 17.L1 lead, 17.D2 ui-designer. **Phase 1 (in parallel, no shared files):** 17.I1, 17.I3 (ledger part), 17.S1,
17.S2, 17.G1, 17.V1, 17.V6-17.V10, 17.V12, 17.V13. **Phase 2:** 17.I2, 17.I3 (effects), 17.U1 (after 17.D2), 17.A1, 17.V2-17.V5,
17.V11, 17.V14, 17.C1. **Then** 17.L2, the playtest, 17.D3. Phase-1 tests stub the others in `tests/test_17_<id>.gd`.
| Id | Agent | Task | Files |
|---|---|---|---|
| 17.L1 | lead | Freeze section 13 in `CLAUDE.md`, Keys (build menu I), owner rows, step 17 ids in `waves.md`, agent rules | `CLAUDE.md`, `docs/plan/` |
| 17.D2 | ui-designer | Layouts at 1600 x 900 for section 8 (market window tabs, Epic tab cards, limits line, claim banner, rarity frames in every slot) | `docs/design/ui-market.md` |
| 17.I1 | items-coder-high [H] | ItemType fields, the 33 `.tres` + `relic_any`, prices with gold parts, fold, champion rule, limits, underdog, sell split, `can_buy` order, `price_of`, Recipes wildcard + gold | `scripts/items/item_type.gd`, `inventory.gd`, `recipes.gd`, `data/items/*` |
| 17.I2 | items-coder | T1-T4 passives / actives (Deflect, Chain Spark, Resonance, Muster, Sunder, Wildfire Mind, Blink II, Unbroken, Rally III, Rallying Cry II, Frost Ward II, Rime Skin, Overgrowth II, Rootgrasp, Grave Tithe), elixirs, per-stat aura rule, Blink family | `scripts/items/item_actives.gd`, `item_passives.gd` |
| 17.I3 | items-coder-high [H] | MarketLedger (showcase, claims, returns, relic stock, underdog, bounty) + the 8 epic effects | `scripts/items/market_ledger.gd`, `epic_effects.gd` |
| 17.G1 | gameplay-coder | `unyielding`, `add_hp_floor`, `SpellCaster.echo_cast`, Afterimage and Warden Sapling units, sourced Risen, sunder modifier helper | `scripts/units/`, `scripts/spells/spell_caster.gd`, `data/units/phase_afterimage.tres`, `warden_sapling.tres` |
| 17.S1 | systems-coder | GrandMarket building, 4 `.tres`, placement rules / messages, GM slot + clearing, ledger reveal / relic start, rebuild | `scripts/buildings/grand_market.gd`, `build_grid.gd`, `building_type.gd`, `data/buildings/*_grand_market.tres` |
| 17.S2 | systems-coder-high [H] | 6 new nodes + amounts, X2 move, X3 / X4 / X5 / SG / SM / SF / W3 / W4 / W5, cache, rabbit and deer moves, the 3 terrain patch centres, sealed node + CampManager unseal, flags, end-screen line, fairness test (6.5 incl. the Ford "contested" check) | `scripts/world/skirmish.gd`, `scripts/economy/crystal_node.gd`, `worker.gd`, `scripts/world/camp_manager.gd`, `critter_herds.gd`, `terrain` table file |
| 17.U1 | ui-coder | Build menu I, market card / panel, market window tabs + Epic tab, gold chips, fold display, rarity frames + shimmer everywhere, tooltips, claim banner, messages, sealed node card, end-screen line, audio, help | `scripts/ui/shop_window.gd`, `command_card.gd`, `selection_panel.gd`, `inventory_bar.gd`, `hud.gd`, `assets/audio/market_*` |
| 17.A1 | ai-coder | Rule 16, rule 3 / 10e / 11a extensions, B2 / B12, champion wish-list tails, strength +150 | `scripts/ai/commander.gd`, `ai_items.gd`, `ai_profile.gd`, `data/ai/*.tres`, `ai_champions.gd`, `champion_brain.gd` |
| 17.C1 | systems-coder | Plug the market models, hooks (`set_showcase`, `play_purchase`, `set_relic_stock`), site dressing `set_sealed`, ItemVfx calls | `data/buildings/*_grand_market.tres`, `scripts/buildings/grand_market.gd`, `scripts/world/skirmish.gd` |
| 17.V1-17.V14 | tech-artist (one each) | Section 10 | Section 10 paths |
| 17.L2 | lead | Glue (ItemVfx node in scenes, hud wiring), `--no-market` / `--no-new-sites` flags, perf additions, runs of 9.5, CI, playtest build | `tests/`, `scenes/`, `docs/plan/` |
| 17.D3 | game-designer | Balance from the 17.L2 logs and the playtest; knobs of 9.4; the "What changes" lines | `docs/design/*.md` |

## Done when
- [ ] 17.L1: section 13 is in `CLAUDE.md`; Keys has build menu I; owner rows for every new folder and data file; ids in `waves.md`.
- [ ] 17.D2: `ui-market.md` gives positions / sizes / looks at 1600 x 900 for every element of section 8, consistent with `ui-style.md`, `ui-trade.md` and the `items.md` shop window.
- [ ] 17.I1: the 33 items + `relic_any` load with the numbers of section 3; test: Lodestone Bead costs 240 essence at a Grand Market and is `"Not sold here"` at a keep; Dawnsplitter with Inferno Blade + Quickfire Flint carried costs 400 essence + 200 gold, with trade off 500 essence; a champion buying Gilded Buckler from a 1 000 purse pays 720 and tithes 144; a champion is refused a T5 (`"Wizards only"`) and a second T4; a wizard with 2 T4 is refused a third (`"Heroic / epic limit"`), but Dawnsplitter -> Sunfall Edge is allowed; refusal order as section 4; a wizard one level below pays 340 + 170 for the Dawnsplitter recipe; selling Sunfall Edge returns 1 630 essence + 287 gold; an epic with a trophy carried consumes the trophy, without one it takes a Starforged Relic from stock, with neither and stock 0 -> `"Out of stock"`.
- [ ] 17.I2: Deflect halves the first hit then again after 8 s; Chain Spark every 4th attack at 60 %; Resonance every 5th cast free; Sunder -4 armor per hit to -20, gone 4 s later; Wildfire refunds 30 % on 3+ hits only; Blink II 12 m + shroud 1.5 s and Blink is greyed while it is carried; Unbroken +40 armor under 30 % HP with the 150 cap; Rally II + Rally III on the same soldier = +0.18 (per-stat rule); Grave Tithe caps at +100 and is lost on sale; elixirs share 90 s; `PERF OK`.
- [ ] 17.I3: two ledgers with the same seed give the same 4-epic showcase; a claim removes it for both teams with the message; a sale returns it 120 s later; `"Claimed by Malrik"`; relic stock 1 at completion, 2 after 240 s, never 3; Dawnbreak every 6th hit 120 in 2.5 m + daze; Twincast repeats every 3rd cast at 50 % (never Ember Step); Phase Door 14 m + a 200-HP afterimage taunting non-heroes 2 s + Nightstep; Last Stand leaves 1 HP, 2.5 s no damage, +20 % HP, 180 s cooldown, only one cheat-death per 30 s with Rekindle; Stand Fast: no soldier dies for 3 s; Everwinter chills within 7 m and never adds Frostbite; World-Sapling roots every 4 s and heals only heroes; Hollow Chorus max 3 Risen; epic bounty +120 on the carrier's death.
- [ ] 17.G1: `unyielding` blocks all damage; `add_hp_floor` keeps a unit at 1 HP for its duration; `echo_cast` casts without mana / cooldown and refuses movement spells; afterimage and sapling units spawn, expire and give no XP / essence; item Risen count in the team cap.
- [ ] 17.S1: 4 `.tres` with the numbers of 1.1; refusals in order (no Hall, no Stronghold or before 7:00 with research off, 30 m from the keep, a second one); it answers `is_shop()` when completed; the ledger reveals the showcase and starts relics on completion; slot GM accepted on both sides; smoke test `victory=true`.
- [ ] 17.S2: 14 nodes with the amounts of 6.1 (Ford Vein 1 600 at `(-22.5, -30.5)` / `(22.5, 30.5)`); X2 (moved to `(-41, -33)` / `(41, 33)`) / X3 / X4 / X5 / SG / SM / SF / GM / W3 / W4 / W5 accepted by BuildGrid on both sides; path-length pairs of 6.5 within 1 % and each keep's path to the enemy's Ford node 0.85-1.0 x its path to its own; the cache at `(-1, 31)` / `(1, -31)`, the rabbit home, the 2 deer spots and the 3 terrain patch centres moved, nothing else moved; the Ford node is 14.4 m from the Reed Ford Nest and SF never fires at the nest; the Glade node is sealed (worker refused with the message), unsealed for good by the first stag kill, and a worker then mines it into a Hall at X3; `remote_nodes` lists the new nodes and `worker_spot` returns W3 / W4 / W5; flags off = the step-14 map (X2 back at `(-33, -33)`); `PERF OK`.
- [ ] 17.U1: build menu I with tooltip / reasons; the market window has the 6 tabs at a Grand Market and the old grid at a keep; gold chips and folded prices; Epic tab states (available, claimed, returns in, Citadel padlock, needs heroic, one epic); rarity borders and the T5 shimmer in inventory, shop, tooltips, champion inspect and ground items; claim banner for both teams; sealed node card; end-screen line; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 17.A1: headless normal run with research and trade on: Grand Market by ~8:30, kingdom heroic by ~13:00, an epic by ~16:00 when its epic is in the showcase; X2 built at its new slot; X3 only after the own stag died, X4 by the triggers, X5 only when ahead / even with no enemy army near the ford, and the ford nest beside its X5 never crept; SG / SM / SF towers after a raid; hard races an epic the enemy's heroic points to; strength +150 per epic; `PERF OK`.
- [ ] 17.V1-17.V14: each asset at its path with its hooks, passes the 40 m black test (buildings, icons readable at 48 px, epic cards at 256 px), within budget.
- [ ] 17.L2: rounds A-C and Perf of 9.5 pass (or the failing numbers go to 17.D3).
