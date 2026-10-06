# Story mode outline: every episode, every mission, the ending, and what it costs

Owner: story / campaign designer. Written 2026-10-02. Status: **design only, nothing here is built.** Recommended option
taken everywhere (JS: no questions). Builds on `story-episode-1.md` ("ep1"), `prologue-3min.md` ("pro."),
`episode2-opening.md` ("e2o"), `episode3-4-opening.md` ("e34."), `episode5-opening.md` ("e5o", to become Episode 7,
section 1 D1), `mission-01.md`, `mission-02.md`, `tiers.md` 6, `t3-helpers.md` ("th."), `champions.md` 11, `items.md`,
`caster-units.md`, `docs/plan/waves.md`, `docs/plan/ideas-inbox.md`, `docs/ideas/jss_asks.md`. Every name, line and
place here is our own. Minutes are normal difficulty unless marked.

User request (JS, 2026-10-02, verbatim): "work on more mission make the scrip for and a possible ending how long and how
many mission more rts story mode take".

## 0. The three answers, in plain words
**How long is the RTS story mode?** About **13 hours** if you never lose (12 h of missions + 1.4 h of films), about
**16 hours** for a normal first playthrough with retries, and about **18 hours** to see everything (the other three
final roads and the second ending). That is **8 episodes, 33 missions per playthrough** (36 to build, because the
finale has one road per kingdom). Per kingdom: Fire is the longest path (~5.4 h), Shadow, Ice and Nature ~3.5 h each.

**How many missions are still missing?** **35 of 36.** Only mission 1 ("The Crown in the Ashes") is built. Mission 2
has a full build spec (it must be rewritten for the Fire-vs-Shadow story). Missions 0, 3 and 4 have binding outlines in
`story-episode-1.md` but no build spec. Two more (Episode 3/4's Evenmead battles, Episode 7's Dragon Auction) exist as
one paragraph. The other **31 are new in this doc** (one-line briefs in section 3). Building all of it is roughly
**400 agent tasks, ~350-500 agent-hours** (section 5.2); the next 6 scripts to write are in section 6.

**What is the ending?** Episode 8 "The Four Keys". The war has fed Obren until he rises a last time as the Hollow King.
Vessa gives each relic back to its kingdom (the Orb to Torvald, the Signet to Ysolde, the Crown stays hers; Malrik
holds the fourth key, Obren's heart-stone). The player picks a kingdom, walks that wizard's road to Crown Hollow, and
the four kingdoms fight side by side for the first time. Four wizards turn four keys at once; Obren breaks; the Master
climbs out of the deep, old and tired, and admits it: he tried to be the world's policeman for a thousand years, and the
harder he held, the more it slipped. He lets go. The Hollow Throne is offered to the four, and the player chooses:
**break it** (the true ending: four hands keep the peace, not one) or **take the seat** (a short dark ending, a
different one per kingdom). The last scene reveals who the Master was talking to in the prologue ("I know this tale
well, child"): an old man telling the story to a child, whose first spark is white-gold lightning. The storm has
chosen someone new.

## 1. Decisions (recommended option taken)
| # | Question | Decision | Why |
|---|---|---|---|
| D1 | Ep 5/6/7 order (`jss_asks.md` 2026-09-28, todo) | **Ep5 = "The Spark and the Candle"** (Vessa, then Malrik: origins), **Ep6 = "The Lake and the Seed"** (Torvald, then Ysolde: origins), **Ep7 = "Gold for Fire"** (the thousand-year Coinwater war, Torvald + Aldra). Each origin episode opens with a short recap of the prologue | JS's own words (ideas-inbox 2026-09-28): "episode 5 will 7, episode 5 and 6 will be more introduction to wizard 1 at a time ... bigger than the prologue" and players who skipped the prologue must catch up. Ep5 ends on the Master giving Vessa and Malrik the two harbour cities, which is exactly what Ep7's film remembers |
| D2 | File name for the Coinwater doc | Lead runs `git mv docs/design/episode5-opening.md docs/design/episode7-opening.md`, then in that file: title "Episode 7", cine id `ep5_opening` -> `ep7_opening`, task ids `E5.*` -> `E7.*`, lines file `ep7_opening.lines.json`. Only 3 files reference it (`jss_asks.md`, `ideas-inbox.md`, the doc itself). The freed names `episode5-opening.md` / `episode6-opening.md` / `episode8-opening.md` go to the new openings | Same pattern as the other opening docs; one rename, no dangling links. (This designer does not rename files: lead's commit) |
| D3 | How many episodes | **8.** Ep8 "The Four Keys" is the finale | Ep1-7 are written or placed; the relics, the shard, Torvald's turn and Malrik's "especially Malrik" all need one episode to land |
| D4 | Ending shape | 3 finale missions (one **road** per kingdom, 4 variants; then 2 shared), a **3:40 closing film**, a **choice** (break the throne / take the seat) with a kingdom-specific temptation and dark tail, and a bookend that answers the prologue's "child" | A hopeful true ending (ep1 U7 tone) that pays off JS's D1 ruling, and a choice that differs by kingdom without 4 full films |
| D5 | When the Master vanished | **Twelve years before Episode 1** (ep1: Vey was away twelve years). Ep7's chronicle row "Last year: the Master vanishes" becomes "Twelve years ago: he vanishes; his dragons wait in the empty sky; last year they fly home" (section 7, C1) | ep1 is built on the twelve years (Vey's letter, Vessa's grudge); one table row in Ep7 changes, no film shot changes |
| D6 | Mission ids and files | Episode 1 keeps `m00`-`m04` / `mission-00.md`..`mission-04.md`. Later: id `e<E>m<N>` (`e2m1`), spec `docs/design/mission-e2-01.md`, scene `missions/mission_e2_01.tscn`, script `scripts/campaign/mission_e2_01.gd`. Ep8 roads: `e8m1_fire` / `_shadow` / `_ice` / `_nature` | Sorts by episode, no clash with the existing ids |
| D7 | Where the Citadel (tier 3) opens (`tiers.md` 6: "3+ not specified") | Episode 1 stays **Stronghold only** (M0-M4, `max_tier = 2`). **Citadel opens in e2m1** "The Burning Grove", where Old Vey becomes a callable helper (`th.`: the helper is called at the Citadel). Episodes starring another kingdom start at the Stronghold in their mission 1 and open the Citadel in mission 2 | `mission-01.md` Tiers already says "the Citadel (tier-3 unit, Old Vey) belongs to later chapters (Ep2)"; one new tier per episode keeps each episode's first mission readable |
| D8 | Progression across heroes | Each wizard has **their own save track** (artifacts, items, companion) inside the one campaign save: Vessa's from Ep1-2 and Ep5, Malrik's from Ep3 and Ep5, Ysolde's from Ep4 and Ep6, Torvald's from Ep6-7. Ep8 loads the chosen wizard's track. Origin episodes (Ep5-6) carry **nothing** forward (they are the past) | `items.md` carry rules unchanged; a new hero never starts with Vessa's crown |
| D9 | Episode 1 | **Unchanged** (ep1 is the source of truth). This doc only places it | It is the most finished chapter |

## 2. The whole arc in one table
| Ep | Title | Stars (helper) | War shape | Opening film | Missions | Status today |
|---|---|---|---|---|---|---|
| - | Prologue "Once upon a time" | The Master narrates | - | `prologue-3min.md` 3:00 | - | Script, voice, sets, cine **built**; video rendered (re-render pending faces / hair) |
| 1 | The Hollow Throne | Vessa (Old Vey, story ally) | 1v1 Fire vs Shadow; Ice, Nature neutral | `ep1_intro` "The Night of Knives" 2:00 VIDEO (ep1 7.2) | 5 | M1 **built**; M2 spec; M0, M3, M4 outlines; 18 cinematics shot-listed, none built |
| 2 | The Light Below | Vessa (Old Vey) | 2v1, then 2v2 (Fire + Nature vs Shadow + Ice) | `ep2_opening` "The Feast and the Runner" 1:12 (e2o) | 5 | Opening: script, voice, set, cine **built** (render pending); missions: ideas only |
| 3 | The Gravedigger's Son | Malrik (Mother Hush) | 2v2, played from Shadow + Ice | `ep3_opening` 1:31 (e34. 3.1) | 4 | Opening: script, voice, sets, cine baked; render in progress; missions: one line |
| 4 | What Grows Back | Ysolde (Maelis) | 2v2, played from Nature + Fire | `ep4_opening` 1:28 (e34. 3.2) | 4 | As Ep3 |
| 5 | The Spark and the Candle (origins) | young Vessa, young Malrik (Old Vey as teacher) | The past: the apprentices' trials | `ep5_opening` ~3:00 **new** (prologue recap + two big intros) | 4 | Nothing (this doc) |
| 6 | The Lake and the Seed (origins) | Torvald (young Aldra), young Ysolde | The past, ending on the vanishing | `ep6_opening` ~3:00 **new** | 4 | Nothing (this doc) |
| 7 | Gold for Fire | Torvald (Aldra Stillwater) | 2v2 at the Coinwater; Torvald breaks with Malrik | `ep7_opening` 3:26 (e5o, to rename) | 4 | Opening: script, shot list, draft cine in the doc; sets, voice not built; mission 1 one paragraph |
| 8 | The Four Keys (finale) | the player's choice of the four | All four kingdoms vs the Hollow King | `ep8_opening` ~2:00 **new**; ending `ep8_ending` 3:40 (section 4) | 3 per playthrough (6 to build) | This doc |

Story in one breath: **Ep1** Shadow's knives miss Vessa, she takes three relics, the war wakes Obren and Old Vey
returns in a storm. **Ep2** Ice joins Shadow and burns Ysolde's wood; Nature joins Fire; Vessa and Vey go down to the
Master's door, which holds, barely: "All four of you, or none." **Ep3-4** the great field battle of Evenmead from both
hills; Malrik feeds on the heart-stone, Ysolde comes back like spring, and Torvald watches the stone whisper. **Ep5-6**
(a winter truce; the wizards remember) who the four were before the crown, ending on the Master's vanishing seen from
below. **Ep7** gold and dragons at the Coinwater; Torvald sees what Malrik's alliance costs and says no for good.
**Ep8** the four keys, the four roads, the last battle, the empty throne.

## 3. Episode by episode
Status codes: **BUILT** (scene + script + tests), **SPEC** (full build spec in the `mission-01.md` format), **OUTLINE**
(binding outline with numbers in a design doc), **IDEA** (one line or one paragraph in a design doc), **NEW** (this doc,
one-line brief). Lengths: normal difficulty, including the mission's own cutscenes.

### 3.1 Episode 1 "The Hollow Throne" (Fire, Vessa). Source: ep1 (unchanged)
Opening: prologue (3:00) then `ep1_intro` (2:00 VIDEO, later production). Between missions: `c1_offer`,
`c2_two_fronts`, `c3_parley`; in-mission 9 ENGINE cutscenes + 4 VIDEO; ending `ep1_ending` 1:30 + credits 1:30.
| # | Id | Title | Plays | Map | Objective type | Length | New / unlocked | Status | Spotlight (`unit-spotlights.md`) |
|---|---|---|---|---|---|---|---|---|---|
| 0 | `m00` | The Night of Knives | Vessa (L2, wounded) + Old Vey ally | Emberfall at night (M1 corner, sight x 0.6) | Survive until dawn, light 3 braziers | 9-12 | The wizard under pressure; no economy | OUTLINE (ep1 5.0) | Flame Guard |
| 1 | `m01` | The Crown in the Ashes | Vessa | Emberfall | Light 3 braziers, claim, hold 2:00 | 15-20 | T1 Fire, Blaze Rider; **Stronghold** (Pyre Adept, Cinder Arbalest, **Kilnwarden** caster, "+" upgrades); items, shops; **Ember Crown** | **BUILT** (no story patches 19.C3 yet) | Blaze Rider |
| 2 | `m02` | The Orb Beneath the Ice | Vessa | Glasswater Mere (Torvald's lake, neutral) | Break the Heartfrost before the dig, escape | 18-24 | Ash Hurler, thin ice, blizzard; **Stillwater Orb**, Oath of Embers (secondary); Aldra's voice (th. Q1) | SPEC (old Fire-vs-Ice; ep1 5.2 re-skin to write) | Ash Hurler |
| 3 | `m03` | The Signet in the Sighing Wood | Vessa | Sighing Wood (neutral) | Race Malrik to 3 Root Hearts, take the Signet, break 2 gates | 20-25 | **Champions**, tavern, bounty flags, companion; **Master's Signet** | OUTLINE (ep1 5.3) | Wayfinder (champion) |
| 4 | `m04` | The Hollow Throne | Vessa (+ Old Vey from the darkest hour) | Crown Hollow at war (river on) | 3-way battle, Hollow meter, boss (Keystone Colossus) | 22-28 | Boss phases, Turn the Key, Vey's storm | OUTLINE (ep1 5.4, 6) | Kilnwarden |

### 3.2 Episode 2 "The Light Below" (Fire, Vessa + Old Vey; Ysolde allied from e2m2). Source: ep1 10, e2o
Opening: `ep2_opening` (1:12). Between: `c_e2_ashes` "What the Frost Kept" (after e2m1, 1:15: Ysolde in the burnt
grove, she joins Fire), `c_e2_lodge` "The Price of the Road" (after e2m2, 1:00), `c_e2_stair` "On the Way Down" (after
e2m3, 1:30: Vey's story, half of it: he was the Master's sword "before the four"; the lightning is "his storm, not
mine"). Ending `ep2_ending` "All Four, or None" (1:30, ENGINE; VIDEO later if wanted).
| # | Id | Title | Plays | Map | Objective type | Length | New / unlocked | Status | Spotlight (`unit-spotlights.md`) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `e2m1` | The Burning Grove | Vessa | Sighing Wood burnt and frozen (M3 map, seed 1303, ash + snow terrain of step 12b) | Reach Ysolde's last Heartwood by 6:00, then hold it 12:00 vs Shadow + Ice (2v1); Wren and the Nature survivors must live | 20-25 | **Citadel** (tier 3: Ashveil Saboteur), **Old Vey becomes the callable helper** at the Citadel; first mission vs Ice units | IDEA (ep1 10, e2o Q1) | Old Vey (helper) |
| 2 | `e2m2` | Roots and Embers | Vessa + Ysolde (allied bot) | 2v2 map (`map-2v2.md`) | First 2v2: escort seed-carriers to replant 3 groves around Fire's line, destroy Torvald's forward Rime outpost | 22-28 | **Allied wizard bot**, Maelis as the ally's helper; neutral camps + capture points (map-fill) | IDEA (ep1 10) | Ashveil Saboteur |
| 3 | `e2m3` | The Salt Road | Vessa | Trade map (`market-trade.md` 10 proposal, moved to Ep2 by ep1 9) | Run 6 gold caravans to the Hunters' Lodge to buy its help, while Magpies and Shadow raid the road | 18-24 | **Gold, Bazaar, caravans**, Magpies; **Ember Boar** cavalry (`cavalry-mounts.md` 12) | IDEA | Emberdart Harrier |
| 4 | `e2m4` | Sunrise Road | Vessa + Old Vey | The deep under Emberfall (new underground biome, narrow halls, no base until the Warden forge) | Descend 3 Warden halls; Vey's channel wakes Wardens as friends; small army, light against the dark | 17-23 | **Research** (Forge / Sanctum, `research.md` 12 moved here); friendly Ruin Wardens (story unit) | IDEA (ep1 10) | Ember Forge |
| 5 | `e2m5` | The Light Below | Vessa + Ysolde bot vs Malrik + Torvald bots | The Deep Door cavern (the Master's white-gold door) | 3-way race to the door, then boss: **the Doorwarden** (Obren's jailer-statue, woken by Malrik's shard); the door must hold | 25-31 | Fire titan (`titans-2.md`) as the reward unit; boss bar reuse | IDEA (ep1 10) | Cinder Dragon (titan) |
Episode ending: the door holds; through it the Master speaks one line to Vessa ("All four of you, or none."); Malrik
pulls back with the shard and Torvald; both alliances race up toward the last green country: Evenmead.

### 3.3 Episode 3 "The Gravedigger's Son" (Shadow, Malrik + Mother Hush; Torvald allied). Source: e34.
Opening: `ep3_opening` (1:31). Between: 3 ENGINE scenes (~1:10 each: Hush and Malrik after Evenmead, the stone's
first price, Torvald's doubt). Ending `ep3_ending` "I Will Not Stop" (1:00).
| # | Id | Title | Plays | Map | Objective type | Length | New / unlocked | Status | Spotlight (`unit-spotlights.md`) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `e3m1` | Take the Ford | Malrik + Torvald (bot) | `evenmead` (north seat) | 2v2 attack: take and hold the stone ford and the foot of Lark Hill | 22-28 | Shadow kit at the Stronghold, **Gloom Deacon** caster; Keystone Shard in Malrik's artifact slot | IDEA (e34. 7) | Gloom Deacon |
| 2 | `e3m2` | Another Night | Malrik (stays at camp, voice) + Hush's squad | The Fire-Nature camp behind Lark Hill, night | Commando, no base: sabotage 4 supply wagons before dawn; the mirror of M0 ("There is always another night") | 14-18 | **Citadel**; **Hush becomes the callable helper**; Nightblood Reaver T3 | NEW | Mother Hush (helper) |
| 3 | `e3m3` | The Stone's Price | Malrik | Malrik's crypt city (Shadow homeland) | Hold the crypt while Wardens rise from Malrik's own dead; the shard offers power that fills a Hollow meter: use it or not (a flag for Ep8) | 20-25 | Keystone Shard active ability (with its cost); Hollow meter from the inside | NEW | Nightblood Reaver |
| 4 | `e3m4` | The Storm on the Ridge | Malrik + Torvald (bot) | Evenmead ridge, after the battle | Hero-boss: Old Vey + Vessa's army; hold 3 points until Vey withdraws (he cannot die); Malrik wins the field, Torvald sees the stone whisper | 24-30 | Nightmare Knight titan | NEW | Nightmare Knight (titan) |

### 3.4 Episode 4 "What Grows Back" (Nature, Ysolde + Maelis; Vessa allied). Source: e34.
Opening: `ep4_opening` (1:28). Between: 3 ENGINE scenes. Ending `ep4_ending` "Winter's End" (1:00): a winter truce
falls on both alliances; the episodes that follow are what the four remember that winter.
| # | Id | Title | Plays | Map | Objective type | Length | New / unlocked | Status | Spotlight (`unit-spotlights.md`) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `e4m1` | Hold Lark Hill | Ysolde + Vessa (bot) | `evenmead` (south seat) | Survive until nightfall; save the villagers and the Master's golden tree | 22-28 | Nature kit at the Stronghold, **Bramblesage** caster | IDEA (e34. 7) | Bramblesage |
| 2 | `e4m2` | The Green Road | Ysolde | Evenmead's western woods | Escort 40 villagers to the Fire border through ambushes | 18-22 | **Citadel**; **Maelis becomes the callable helper**; Briar Roc T3 | NEW | Maelis (helper) |
| 3 | `e4m3` | The Frozen Ashes | Ysolde | The Sighing Wood (burnt + frozen, e2m1's map) | Thaw and regrow 5 groves while Torvald and Aldra hold the wood | 22-26 | Regrowth objective; **Heartwood Seed** artifact (Ysolde's token, new `items.md` row) | NEW | Briar Roc |
| 4 | `e4m4` | Winter's End | Ysolde + Vessa (bot) | Torvald's frontier (ice wall map) | Break "the Wall of a Hundred Winters" and its Rime Colossi; Torvald stops Aldra from finishing Ysolde: the seed of his turn | 24-30 | Elder Treant titan | NEW | Elder Treant (titan) |

### 3.5 Episode 5 "The Spark and the Candle" (origins: young Vessa, then young Malrik)
Opening `ep5_opening` ~3:00 **new**: 0:00-0:45 recap of the prologue (re-cut from the rendered prologue, the Master's
voice, no new render), 0:45-3:00 a bigger version of the prologue's 4-beat blocks (origin, strength, weakness, love) for
Vessa then Malrik, with new scenes. Present-day frame: the winter truce; Vessa turns Vey's old sword-knot, Malrik his
candle. Ending (0:40): the Master gives them the two harbour cities ("No problem at all!"); straight into Ep7's memory.
Missions are short, small armies, tier 1, low level caps: they double as a refresher for new players.
| # | Id | Title | Plays | Map | Objective type | Length | New / unlocked | Status | Spotlight (`unit-spotlights.md`) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `e5m1` | The First Spark | young Vessa + Old Vey (teacher, in his prime) | The citadel's south valley | Vey's trial: light 5 beacons while border raiders attack (basics refresher) | 12-15 | Nothing new (tutorial-grade) | NEW | Ember Spire |
| 2 | `e5m2` | Burn a Door | young Vessa | A raider fort on the south border | Siege; her weakness as a rule: charging ahead alone springs an ambush, waiting for the army does not | 16-20 | Ember Archer volleys, first siege | NEW | Ember Archer |
| 3 | `e5m3` | Tombstones by Candlelight | young Malrik | A graveyard town | Light and dark: shadows hide his units; find 3 secrets in the crypts before the gravewardens catch him | 12-15 | Stealth-light rule (shadow zones) | NEW | Shade |
| 4 | `e5m4` | Leftovers | young Malrik (vs young Vessa) | The Master's practice field (mirrored) | The Master's trial: a friendly 1v1, first to take 3 banners; Malrik wins by taking | 18-22 | Rivalry 1v1; ends on the cities gift (Ep7 link) | NEW | Grave Hound |

### 3.6 Episode 6 "The Lake and the Seed" (origins: Torvald, then young Ysolde)
Opening `ep6_opening` ~3:00 **new**: 0:30 recap (a different cut), then Torvald's and Ysolde's big intros. Ending
(0:50): from under the earth, the vanishing (pro. S07 seen from below): the four streaks of colour leave the citadel.
This is how Ysolde knew the relics are a lock (ep1 M3) and why Torvald "felt something counting" (ep1 C3).
| # | Id | Title | Plays | Map | Objective type | Length | New / unlocked | Status | Spotlight (`unit-spotlights.md`) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `e6m1` | A Hundred Winters | Torvald + young Aldra | Glasswater Mere, decades ago | Hold the lake through 3 winters (3 waves, blizzards); the Master leaves him the Heartfrost | 16-20 | Aldra (ally, story numbers) | NEW | Rimeshield |
| 2 | `e6m2` | The Rider at the Gate | Torvald | Torvald's ice gate and the town beyond | The weakness scene of pro. S24, played: a rider begs for help; open the gate (costly) or hold (the town burns). Choice saved as a flag for Ep8's Ice road | 18-22 | First story choice flag | NEW | Frostbow |
| 3 | `e6m3` | The Year Nothing Grew | young Ysolde | Evenmead in the famine winter | Keep 4 seed-gardens alive against frost wolves until spring; the Master finds her ("show me again") | 14-18 | Regrowth rule, small army | NEW | Thornling |
| 4 | `e6m4` | The First Crack | young Ysolde + Torvald (ally bot) | Crown Hollow, twelve years ago | The lock fails: amber cracks, Wardens rise; hold the isle while the Master goes down to hold the door | 20-24 | Nature + Ice side by side (the only time before Ep8) | NEW | Wildwood Archer |

### 3.7 Episode 7 "Gold for Fire" (Ice, Torvald + Aldra; Malrik allied until the turn). Source: e5o
Opening `ep7_opening` 3:26 (e5o 3-4). Between: 3 ENGINE scenes. Ending `ep7_ending` "No. Not for Now." (1:10):
Torvald leaves Malrik on the stilled sea; Aldra beside him; Ossavar flies north.
| # | Id | Title | Plays | Map | Objective type | Length | New / unlocked | Status | Spotlight (`unit-spotlights.md`) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `e7m1` | The Dragon Auction | Torvald + Malrik (bot) | `two_harbours` (north shore, 2v2) | Hold the Diamond Harbour, win 2 of 3 Dragon Auctions, keep Seraphine alive | 22-28 | Ice kit at the Stronghold, **Rimecarver** caster; Dragon Auction (gold bids, allied beast) | IDEA (e5o 7) | Rimecarver |
| 2 | `e7m2` | First Blood, and No Further | Torvald | The Tollrock arena island | The Laurel is broken by knives (Hush, sent by Malrik to frame Aurivane): capture and hold the Tollrock, find the truth | 18-24 | **Citadel**; **Aldra becomes the callable helper**; Shardguard T3 | NEW | Aldra (helper) |
| 3 | `e7m3` | The Outwall | Torvald | Adamarch's Outwall quarter | Shelter the dockers from raids by both cities and by Malrik's Shades; choose the people over the diamond pits | 20-25 | Rime Colossus / War Mammoth titan | NEW | War Mammoth (titan) |
| 4 | `e7m4` | The Year of Two Skies | Torvald + Malrik (bot, turns enemy) | `two_harbours`, full strait battle | Full fleets and every dragon; at the turn Malrik's bot becomes the enemy; survive and hold the Tollrock with Ossavar | 25-30 | Side switch mid-mission; Ossavar as an ally | NEW | Shardguard |

### 3.8 Episode 8 "The Four Keys" (finale; the player picks a kingdom). Details: section 4
Opening `ep8_opening` ~2:00 **new** (section 4.1). Between: `c_e8_muster` "Especially Malrik" (1:20). Ending
`ep8_ending` 3:40 + choice + credits 2:00.
| # | Id | Title | Plays | Map | Objective type | Length | New / unlocked | Status | Spotlight (`unit-spotlights.md`) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `e8m1_<k>` | The Four Roads (4 variants, one per playthrough) | The chosen wizard | Their own land, then the road to Crown Hollow | Each wizard's weakness, overcome (4.2) | 18-22 | Everything of that kingdom, its helper | NEW | Fire Pyre Adept · Shadow Hexweaver · Ice Frost Mortar · Nature Greenheart Oathkeeper |
| 2 | `e8m2` | The Last Muster | The chosen wizard + 3 allied wizard bots | Crown Hollow, 4 seats | All four kingdoms vs the Hollow Host: escort the 4 key-bearers to 4 keyholes; every death feeds the King | 25-30 | The 4-wizard alliance; all titans and helpers | NEW | Kingdom's T2 heavy rider (Pyrehoof / Barrow Knight / Rimehorn / Thornback) |
| 3 | `e8m3` | The Hollow King | Same | The Hollow pit | Final boss, "Hold Together" (4 keyholes at once) | 28-35 | - | NEW | Kingdom's T3 elite rider (Cataphract / Dreadrider / Juggernaut / Glade Outrider) |

## 4. The ending
### 4.1 `ep8_opening` "The Four Keys" (~2:00, ENGINE; outline)
Spring after the Coinwater. All over the world, every battle of this war has run down into the Hollow (ep1: "the war
itself is opening the door"). In Malrik's hand the heart-stone cracks and speaks in a full voice; under Crown Hollow the
Master's light flickers. At Emberfall, Old Vey: "He can't hold it. Not alone. Not any more." Vessa does the one thing
nobody expects from her: she **gives the relics back**: the Stillwater Orb to Torvald (it lay in his lake), the Master's
Signet to Ysolde (it slept in her tree), the Ember Crown stays hers. Three keys. "The fourth is in Malrik's pocket."
Vey: "Then we go and ask him. He asked for all four of you. Especially Malrik." Title. The Story menu then asks:
**"Whose road do you walk?"** (four wizard cards).

### 4.2 The finale missions (briefs for the script writers; numbers are design intent)
**e8m1 "The Four Roads"** (18-22 min each; one per kingdom; the others unlock for replay after the ending). Each road is
that wizard's prologue weakness, turned around (pro. S16 / S20 / S24 / S28):
| Road | Weakness (prologue) | Mission |
|---|---|---|
| Fire: "The Spark Waits" | "She never waits" | Vessa holds the west bank of the Hollowmere for 14:00 while the other three keys are still on the road. Charging past the line lights the Hollow meter; waiting (and Old Vey's storm) wins |
| Shadow: "Put Down the Shovel" | "He is never full" | Malrik fights through his own crypt as the stone turns his dead against him. **Mother Hush** (loyal to the stone's power) is the boss; she flees at 25 % and Malrik lets her go. Each time the player uses the stone's power, the final boss gets +5 % HP (flag carried). End: he keeps the stone only to bring it, not to use it |
| Ice: "The Gate Opens" | "He waits too long" | Torvald opens his ice gate to a column of refugees and escorts them south while Shadow remnants hunt them. If `e6m2` saved the town, its people come out to help (2 extra Rimeshield squads) |
| Nature: "Take a Side" | "She will not take a side" | Ysolde marches her regrown army out of her borders for the first time, breaking three root-walls she raised herself, to reach Crown Hollow before the Host closes the bridges |
Shared rule: the chosen wizard's track (D8) loads its artifacts and companion; the Story choice screen equips the key
relic in artifact slot 1 (Crown / Shard / Orb / Signet).

**e8m2 "The Last Muster"** (25-30). Crown Hollow as a 4-seat map (Crown Hollow layout + the 2v2 seat frames). The player
at their kingdom's seat, three allied wizard bots (ai `mission_e8` profile: defend, then follow scripted pushes) at the
others. The Hollow Host (Ruin Wardens, Warden Gates, Keystone Pylons back from M4) pours from the cracked isle and from 4
gates. Objective: each wizard walks their key to one of 4 **keyholes** on the 4 banks (the `MissionBrazier` channel, 5 s
within 3 m); the player escorts their own, the bots theirs on a timer the player can speed up by sending help (ally
call-for-help pings). The **Hollow meter** returns (M4 rule: +1 % per death on the map); at 100 % the King rises early and
the fight starts harder. Win: 4 keyholes lit. Unlocks: all helpers on the field (allies' helpers fight as theirs), titans.

**e8m3 "The Hollow King"** (28-35). The final boss: **Obren's last body**, the Hollow King, built from the whole buried
throne-hall (taller than the Keystone Colossus: 18 m; the Throne in his chest; four chains of amber light from the
keyholes to his limbs). Phases:
| Phase | What happens |
|---|---|
| 1 "Four Chains" | Each keyhole holds one chain; the King tears at the chain whose keyhole is weakest (the player sees which) and sends Wardens there; a chain breaks if its keyhole falls (then the King gains that limb's attacks) |
| 2 "The King Walks" | At 60 % he walks on the weakest keep; Keystone Hurl, Quake Stomp, Relic Pull from M4 return in bigger forms; Old Vey and all four helpers fight |
| 3 "Hold Together" | At 25 % he kneels; the four wizards must channel at their keyholes **at the same time** for 5 s (the M4 Turn the Key rule for four); the player's channel is the one under attack, the three bots hold theirs while their keyholes stand. Each full turn = Exposed 10 s and the Master's light lances up from below (300 damage). 3 turns on normal |
| Fall | `ep8_ending` |
Lose: the player's wizard dies, or two keyholes fall at once. Normal HP ~30 000 (easy 22 000, hard 40 000); scripted
allies cannot die (the M4 Vey rule: they kneel and return).

### 4.3 `ep8_ending` "Four Hands" (3:40 + the choice). Script (times = movie seconds; the choice pauses the film)
Speakers: `master`, `vessa`, `malrik`, `torvald`, `ysolde`, `vey`, `obren`, `child` (**new**). `<W>` = the player's
wizard (four recordings of the same line, 4.4). Subtitles <= 2 x 48 characters, <= 17 characters / s.
```
0:00-0:46  THE LAST TURN (the Hollow pit, storm dusk)
[0:01] VESSA      Now! All four! Together!
[0:09] TORVALD    Together, then.
[0:11] YSOLDE     Together.
[0:14] OBREN      Keep me, Bishop. I made you strong.
[0:17] MALRIK     You made me hungry. Different thing.
[0:27] OBREN      I only wanted... to build something|that would last.
[0:34] MASTER     You did, Obren. It held me twelve years.
0:46-1:40  THE DOOR
[0:53] VEY        There he is. Took his time.
[1:01] VESSA      Master!
[1:04] MASTER     My joy. Still never waits.
[1:09] MASTER     A thousand years I held the world|in one hand.
[1:13] MASTER     The harder I held, the more it slipped.
[1:17] MASTER     Kings. Cities. Even you four.|I gave you kingdoms. You saw gold.
[1:22] MALRIK     In fairness, it was a great deal of gold.
[1:26] MASTER     So I will not hold it again.
[1:29] VEY        So. The lightning.
[1:31] VESSA      FINALLY.
[1:33] VEY        His. Lent to me to keep you four alive.|Now it goes home.
1:40-2:16  THE THRONE
[1:41] MASTER     Whoever sits there holds the world, as I did.
[1:46] MASTER     Someone will always want that seat.|Choose, all four of you.
[1:51] <W>        (the temptation line of the player's wizard, 4.4)
       CHOICE: Break the throne / Take the seat   (canon continues below; the dark tail is 4.5)
[2:00] <W>        Nobody sits. Not ever again.
[2:05] MASTER     Good.
2:16-3:05  THE FATES (the Master, voice-over, past tense)
[2:17] MASTER     Torvald opened his gate, and he kept it open.
[2:25] MASTER     Ysolde planted the Hollow with oaks.|She never closed a road again.
[2:33] MASTER     Malrik kept watch over the deep.|The dark still came when he called.
[2:38] MASTER     It never frightened him.
[2:42] MASTER     Vessa rebuilt my observatory, and taught|children their first spark. She learned to wait.
[2:49] MASTER     Mostly.
[2:51] MASTER     The two harbour cities fought one|more duel, and called it a draw.
[2:58] MASTER     And the throne stayed empty.|That was the peace: four hands, not one.
3:05-3:40  ONCE UPON A TIME (the ruined orrery dome, one candle)
[3:06] MASTER     ...and that, child, is the end of the tale.
[3:10] CHILD      Is it true? Were you really him?
[3:13] MASTER     I know this tale well, child. I was that wizard.   (the prologue's own WAV, pro. L12)
[3:18] CHILD      Were you sad, when they stopped needing you?
[3:21] MASTER     No. That was the whole point.
[3:26] (no line: the child's cupped hands; a spark of white-gold lightning)
[3:29] MASTER     ...Well. So that is where it went.
[3:33] Title: FOUR WIZARDS · The End   sub: "The storm chooses its own."   (fade to black 3:39-3:40, then credits)
```
Echoes: "Together, then" answers Torvald's "No. For now." (ep1 C1). "You made me hungry" answers pro. L19 ("he is never
full"). "It held me twelve years" is the twelve years of ep1. **"The harder I held, the more it slipped"** is JS's D1
ruling in the Master's own mouth (e5o 1: the world's policeman), and "I gave you kingdoms. You saw gold" is Ep7's "They
heard gold, and soldiers, for free", admitted at last. Vey's "Now it goes home" pays off ep1 V5 ("On the way down").
"It never frightened him" is pro. L21. The bookend reuses pro. L12 frame for frame, so the prologue becomes a story the
Master told this child; the white-gold spark is the hook (his storm left him when he let go, and chose someone new).

### 4.4 Shot list (25 shots, 3:40, letterbox 2.39; ENGINE, World Forge sets; VIDEO later if JS wants)
Sets: **`forge_hollow_pit`** (new: Crown Isle's pit after the final battle, storm clearing to sunrise; builds on ep1
19.V4's pit state), `forge_citadel` (ruined dome, pro. S13 marks), `forge_intro_torvald` / `_ysolde` / `_malrik`
(prologue vignettes, reused), `forge_watch_keep` (new `kind=rebuilt` dressing: the observatory as a school),
`forge_tollrock` (Ep7's set). **The fate shots are the reverse angles of each wizard's prologue weakness shot** (S24, S28,
S21, S16): same set, same place, opposite outcome. Axis in the pit: the four keyholes on a ring around the King; the
Master - Vessa line runs north-south; cameras stay on its east side from E07 on.
| Shot | Time | Set | Camera | What we see | Line |
|---|---|---|---|---|---|
| E01 | 0:00-0:08 | hollow_pit | FADE_BLACK 1.0; CRANE down through storm cloud into the pit, fov 50 -> 40 | The kneeling Hollow King, chest cage open, the Throne inside it; four wizards at four keyholes on the rim, each relic blazing (red Crown, blue Orb, green Signet, violet Shard); Old Vey and the four helpers holding the Wardens back | Vessa: Now! All four! |
| E02 | 0:08-0:20 | hollow_pit | 4 CU inserts on hands (2.5 s each), then MS Malrik | Torvald turns the Orb; Ysolde turns the Signet; Vessa the Crown; Malrik's hand hesitates, the stone whispers amber wisps up his arm; he turns it | Torvald / Ysolde / Obren / Malrik |
| E03 | 0:20-0:26 | hollow_pit | TOP-DOWN, crane up | Four beams of colour cross the pit and meet in the King's heart: one white-gold flash | - |
| E04 | 0:26-0:33 | hollow_pit | ECU on the heart, slow push | Obren's stone face inside the heart, crumbling, almost peaceful | Obren: I only wanted... |
| E05 | 0:33-0:40 | hollow_pit | Low angle down into the crack under the King | A white-gold light below, answering | Master (from below): You did, Obren... |
| E06 | 0:40-0:46 | hollow_pit | WS, low; slow motion 0.5 | The King collapses into the pit in a slow cascade; dust wave over the four; silence; the storm breaks open to grey dawn | - |
| E07 | 0:46-0:52 | hollow_pit | MS on Vey at the pit's edge, 3/4 | Vey kneels; lightning crawls from his blade down into the rising light | - |
| E08 | 0:52-1:00 | hollow_pit | Low, behind the four, looking down into the light | **The Master climbs out**, leaning on Vey's offered arm: very tall, robe in rags, the four-colour hem burnt down to embers; backlit, face still unseen (the beard of light) | Vey: There he is. Took his time. |
| E09 | 1:00-1:08 | hollow_pit | MS two-shot Vessa + Master, 3/4, eye | Vessa runs to him and stops one step short, then hugs him; the other three stay back, proud, then bow anyway (Malrik last, barely) | Vessa: Master! / Master: My joy. Still never waits. |
| E10 | 1:08-1:16 | hollow_pit | CU on the Master (silhouette against dawn), slow push | He looks at the four, one by one | Master: A thousand years... / The harder I held... |
| E11 | 1:16-1:25 | hollow_pit | WS of the five, then CU Malrik | The Master's hand opens, empty; Malrik's dry little shrug | Master: Kings. Cities... / Malrik: In fairness... |
| E12 | 1:25-1:40 | hollow_pit | MS two-shot Master + Vey, then ECU on the blade | "So I will not hold it again." He lays his hand on Vey's sword; the lightning runs off the blade up into his arm and is gone; the runes go dark; Vey looks younger and older at once | Master / Vey / Vessa: FINALLY. / Vey: His... |
| E13 | 1:40-1:50 | hollow_pit | Slow push down to the pit floor | The Hollow Throne, cracked but whole, still faintly amber, alone on the pit floor | Master: Whoever sits there... / Someone will always want that seat... |
| E14 | 1:50-1:58 | hollow_pit | MLS on `<W>` (the player's wizard), 3/4, low; the three others soft in the background | `<W>` takes one step toward the throne; its amber glow pulses in their eyes. **Four variants** (same marks, the actor changes). Then the film pauses on the **choice card** | `<W>`: temptation line (below) |
| E15 | 1:58-2:10 | hollow_pit | WS, eye; then CU on the relics | Canon: `<W>` turns back to the others. The four lay their relics on the throne and strike together: fire, frost, roots and shadow crack it into rubble; the relics shatter with it. One ember of the Crown survives; Vessa closes her hand on it | `<W>`: Nobody sits... / Master: Good. |
| E16 | 2:10-2:16 | hollow_pit | CRANE up and out, fov 40 -> 52 | Sunrise breaks over Crown Hollow; the empty pit; birds lift off the moat | - |
| E17 | 2:16-2:24 | intro_torvald | **Reverse of pro. S24** (over the rider's shoulder, looking in) | The ice gate opens; Torvald waves a column of refugees in; Aldra beside him hands out blankets; a signal fire burns, not buried | Master: Torvald opened his gate... |
| E18 | 2:24-2:32 | intro_ysolde | **Reverse of pro. S28** | The root-wall across the border road sinks into the earth; messengers ride in; Wren on her stag; then a cut: Ysolde kneels in the pit planting an oak | Master: Ysolde planted the Hollow... |
| E19 | 2:32-2:41 | intro_malrik | **Reverse of pro. S21** (static CU) | Malrik in a stone room by the sealed deep door; he **lights** his candle instead of pinching it; Hush in the doorway, knives sheathed | Master: Malrik kept watch... / It never frightened him. |
| E20 | 2:41-2:51 | watch_keep (`kind=rebuilt`) | **Reverse of pro. S16** (low, looking up at her) | The observatory rebuilt as a school; Vessa stands in front of a row of children, waiting (visibly impatient, tapping her foot) while a small boy fails to light a spark; the brazier burns with the Crown's last ember; Old Vey dozes in the sun; Ashby drills cadets behind | Master: Vessa rebuilt my observatory... / Mostly. |
| E21 | 2:51-2:58 | tollrock | WS, 3/4 | Dacian and Seraphine, older, sitting on the rim beside the empty stone chair, sharing a jug; Ossavar asleep across the arena wall; Pell's cart below with a sign `GENUINE THRONE RUBBLE` | Master: The two harbour cities... |
| E22 | 2:58-3:05 | hollow_pit | HERO WIDE at full sun, slow push | Four banners (red, violet, blue, green) staked around the pit; oak saplings on the floor where the throne was | Master: And the throne stayed empty... |
| E23 | 3:05-3:14 | citadel (ruined dome, pro. S13 marks) | FADE_BLACK 0.4 in; static, slow push on the candle | **The bookend**: the ruined orrery dome, one candle. An old, very tall man in a plain cloak sits on a step (the Master, the hem fire gone out); a child from the Outwall sits in front of him, chin on knees | Master: ...and that, child... / Child: Is it true? / Master: I know this tale well... |
| E24 | 3:14-3:24 | citadel | MS two-shot, 3/4, eye | The child looks up at him; he smiles (the beard of light is only a white beard now, faintly glowing) | Child: Were you sad... / Master: No. That was the whole point. |
| E25 | 3:24-3:40 | citadel | ECU on the child's cupped hands, then CRANE up and out through the broken roof to the stars; title; FADE_BLACK | The child cups hands, like Vessa in pro. S14: a spark, but **white-gold lightning**, crackling; the old man's eyebrows rise | Master: ...Well. So that is where it went. / Title |

**E14 temptation lines (four recordings, one plays) and the canon line**
| `<W>` | E14 temptation (1:51) | E15 (2:00) |
|---|---|---|
| Vessa | I could stop every war. Keep everyone safe. | Nobody sits. Not ever again. |
| Malrik | Full. At last. Just once, to be full. | (same line, his voice) |
| Torvald | A peace that never melts. Never breaks. | (same) |
| Ysolde | Everything would grow. Everywhere. Always. | (same) |
In the canon branch the fate shots play in the fixed order above, except that the player's own wizard's fate moves to
last (just before E22): a one-line StoryFlow reorder, no new shots.

### 4.5 The choice and the dark tail (`ep8_dark_<k>`, ~45 s each, replaces E15-E22)
Choice card (ui: two buttons, focus on the first, no timer; kingdom text): **Break the throne** ("Four hands keep the
peace, not one.") / **Take the seat** ("Keep the peace yourself."). Both are saved (`ep8_choice`) and both unlock the
Theatre; the true ending is "Break". Dark tail, 4 shots:
| Shot | What we see | Line (Master, voice-over unless marked) |
|---|---|---|
| T1 | `<W>` sits; amber-white light floods up the throne; the other three step back | - |
| T2 | The kingdom's world image: **Fire** a sun that never sets over cities without night · **Shadow** a quiet violet dusk over obedient streets · **Ice** a world frozen still, banners stiff with frost · **Nature** a forest grown over every road and city | Fire: "She burned so bright that night never came again." · Shadow: "And the world grew very quiet. And very obedient." · Ice: "Nothing broke again. Nothing moved, either." · Nature: "And the green covered every road. And every grave." |
| T3 | The three others walk away in three directions; `<W>` alone on the throne | "And for a thousand years, the peace held. In one hand." |
| T4 | The old man closes his eyes | "I know how that tale ends." |
Then the bookend E23-E25 plays with two lines swapped in E24: Child "Is the throne still full?" / Master "For now.
Storms come." The lightning spark (the hook) is the same in both endings.

### 4.6 Fates, in one table
| Who | Fate (true ending) | Set up in |
|---|---|---|
| The Master | Lets go: climbs out of the deep, gives up the seat and his storm, lives out his days as an old storyteller in the ruined dome; the prologue was his tale to a child | pro. "I was that wizard"; e5o D1 ruling; ep1 V5 |
| Obren | Destroyed, with a grace note: he wanted to build something that lasts, and his prison held the Master for twelve years | ep1 V2 (the Mason), M4 L21 |
| Vessa | Keeps the Crown's last ember, rebuilds the observatory as a school, learns to wait ("mostly") | pro. S16 weakness, ep1 Vey's first spark |
| Malrik | Gives the stone up to the keys and keeps watch over the sealed deep; the dark still comes when he calls, and never frightened him | pro. S21, ep1 "Especially Malrik", e34. "I will not stop" (he does) |
| Torvald | Opens his gate and keeps it open | pro. S24, ep1 C1 "No. For now.", Ep7's turn |
| Ysolde | Plants the Hollow with oaks, never closes a road again | pro. S28, ep1 M3 "Nature doesn't take sides" |
| Old Vey | His lent lightning goes home; an old swordsman dozing in the sun at Vessa's school | ep1 "the lightning mystery", V5 "On the way down" |
| The relics, the Ember Crown, the Hollow Throne | The four keys shatter with the throne; the throne stays empty, its pit full of oaks; one ember of the Crown lights the school's brazier | prologue "Four heirs. One empty throne."; ep1 title |
| The thousand-year peace | Not one hand's any more: "four hands, not one" | pro. L02, e5o D1 |
| Hook | A child's white-gold spark: the Master's storm has chosen a new bearer (a future game or a DLC episode) | ep1: lightning is "not one of the four kingdoms' elements" |

### 4.7 Build list for the ending (one task per agent)
| # | Item | Owner | Notes |
|---|---|---|---|
| F1 | `ep8_ending` timeline: `ep8_ending_a` (E01-E13), `ep8_throne_<k>` x4 (E14), `ep8_ending_b` (E15-E22), `ep8_dark_<k>` x4, `ep8_bookend` (E23-E25, two line tracks) | four-wizards-high (cine) | `cine check` 0 FAIL; base 3:40 +-2 s; StoryFlow plays a -> throne_k -> choice -> b or dark_k -> bookend |
| F2 | Set `forge_hollow_pit` [H] (pit, keyhole ring, broken throne, sunrise light ramp, 4 banners, saplings) | four-wizards-high | <= 150 draws, 0 lights |
| F3 | `forge_watch_keep kind=rebuilt` (school dressing) | four-wizards-high | Reuses the set |
| F4 | Hollow King cinematic states (kneel, chest open, collapse) from the e8m3 boss model | tech-artist [H] | Shares the game model |
| F5 | The Master "after" look (plain cloak, embers in the hem, hood back, backlit), the child (Outwall kid, small kit) | tech-artist | Face never shown in full |
| F6 | VFX: four key beams, lightning going home, throne break, white-gold spark in cupped hands, saplings | tech-artist | `art/cinematics/fx/` |
| F7 | Voice: ~33 lines + 8 `<W>` lines + 4 dark tails x 2 + 2 bookend variants; **`child` new** (audition `am_puck` 1.15 / `af_sky` 1.2 / `bf_lily` 1.15; not Wren's `bf_alice`); pro. L12 reused | Voice Forge agent | Every WAV fits its slot |
| F8 | Choice card + Story "Whose road?" picker | ui-coder | Layout by ui-designer |
| F9 | Music cue `ep8_ending` (the prologue's motif returns for E23-E25) | ui-coder (Sound Forge) | - |

## 5. Estimates
### 5.1 Player time (normal difficulty)
Mission time = the midpoint of each range in section 3. Cinematics = openings, between-mission, in-mission and endings.
| Ep | Missions | Mission time | Cinematics | Total |
|---|---|---|---|---|
| 1 | 5 | 96 min | 20 min (incl. prologue 3:00) | 1 h 56 |
| 2 | 5 | 117 min | 9 min | 2 h 06 |
| 3 | 4 | 91 min | 8 min | 1 h 39 |
| 4 | 4 | 96 min | 8 min | 1 h 44 |
| 5 | 4 | 65 min | 8 min | 1 h 13 |
| 6 | 4 | 76 min | 8 min | 1 h 24 |
| 7 | 4 | 96 min | 10 min | 1 h 46 |
| 8 | 3 | 79 min | 13 min | 1 h 32 |
| **All** | **33** | **716 min = 11.9 h** | **84 min = 1.4 h** | **13.3 h** |
| Playthrough | Hours |
|---|---|
| Clean (never fails a mission) | **~13 h** |
| Normal first playthrough (retries, briefings, choice screens: missions x 1.25) | **~16 h** |
| Everything (the other 3 roads + the dark ending: +1.5 h) | **~15 h clean, ~18 h first time** |
| Easy / hard | Easy ~ -20 %, hard ~ +25 % (the ep1 ranges) |
| One kingdom's own missions only (incl. its Ep8 road) | Fire ~5.4 h (Ep1, Ep2, e5m1-2, Ep8) · Shadow ~3.4 h (Ep3, e5m3-4, Ep8) · Nature ~3.5 h (Ep4, e6m3-4, Ep8) · Ice ~3.5 h (Ep7, e6m1-2, Ep8) |
What is playable today: mission 1 (~17 min) and the prologue film.

### 5.2 Build effort
Reference points: **mission 1 took about 8 tasks** (5.D2 spec, M7.S1 / S2 / S3 build, M7.U1 UI, M7.A1 bot, 7.D1 lines,
the 2026-09-30 tier patch) on top of the wave-3/4 framework (campaign save, briefing). **Episode 1's full plan is 52
tasks** for 4 more missions + 18 cinematics + the story tech (ep1 9). Cost: ~0.6 % of the weekly budget per agent task
(`usage-log.md` 2026-09-26). Hours assume Opus 5.5 medium, no time box, ~45-75 min per task (code [H] tasks and boss
missions longer, voice renders shorter); low confidence, re-measure after Episode 1.
| Work | Total | Done | Remaining | Tasks | Agent-hours |
|---|---|---|---|---|---|
| Episode outlines (cast, arc, mission list) | 8 | 1 (ep1) + parts (Ep2-4, Ep7 openings) | Ep2, Ep3+4 (E34.D2), Ep5, Ep6, Ep7 (E5.D2), Ep8 | 6 | ~6 |
| Mission scripts (build specs + dialogue) | 36 | 1 (M1) | 4 from outlines (M0, M2 rev, M3, M4 = 19.D2) + **31 new** | 35 | ~45 |
| Engine builds (map, scripted events [H], bot profile, HUD bits, test) | 36 | 1 | 35 x ~4 tasks + ~15 story units / bosses (Colossus, Vey, Hush, Doorwarden, Hollow King, allied-wizard bots, Dragon Auction...) + Ep1 story tech (19.C1, C2, C10, U1-U4) | ~163 | ~195 |
| Art (map kits, story characters, bosses, cinematic sets, video models) | - | some sets (citadel, intro vignettes, watch keep, Ep2 feast, Evenmead, Ep3/4 memories) | Ep1's 25 (19.V1-V25) + ~11 per later episode | ~102 | ~120 |
| Voice (cast, mission lines ~700, cinematics) | - | prologue, Ep2, Ep3, Ep4 openings | 3 per episode (audition, mission lines, films) | ~24 | ~12 (+ machine time) |
| Cinematics (scripts, cine, renders; ~6 openings / endings + ~58 short scenes) | - | prologue (rendered), Ep2-4 openings (cine) | Ep1 18, Ep2-8 ~40, openings Ep5, Ep6, Ep8, Ep7 sets, ending, renders | ~69 | ~70 |
| Playtest, balance, integration (lead + designer per episode) | 8 | 0 | 8 x 2 | 16 | ~24 |
| **Total** | | | | **~415 tasks** | **~470 agent-hours (range 350-550)** |
In budget terms: ~415 x 0.6 % ≈ **2.5 weeks of full weekly budget** if nothing else is built; realistically **6-8 weeks**
alongside the skirmish work. With 6 agents in parallel, ~80 hours of lead wall-clock.
**Parallel**: all mission scripts of an episode at once (one writer each, after the episode outline); art one agent per
element; maps (Map Lab) and sets beside the scripts. **Serial**: the story tech (19.C1 CinematicPlayer, 19.C2 StoryFlow)
before any mission's cutscenes; a mission's build before its in-mission cutscenes; voice renders and the video renders
one at a time (one Kokoro run, one Godot on the laptop); every headless mission run goes through `tools/godot_run.ps1`
(4 at once). **Cut levers if the budget is tight** (in order): engine-only films (drop Ep1's 5 VIDEOs and their 8
video-model tasks, -~15 tasks), Ep5 and Ep6 at 3 missions each (-2 missions, ~-25 tasks), one Ep8 road built first and the
other three later.

## 6. Production plan
Priorities:
1. **Finish Episode 1 first.** It is the only chapter close to playable, and its story tech (CinematicPlayer, StoryFlow,
   portraits, Story menu) is what every later episode reuses. Scripts now: M0, M2 (rewrite), M3, M4. Then step 19.
2. **Episode 2's first mission** (its opening is already scripted, voiced and staged): e2m1, then the Ep2 outline.
3. **The Evenmead pair** (map and both films exist): e3m1 and e4m1 (one map, two sides; the writers share `evenmead.map`).
4. **Lock the ending now** (this doc) so every episode writes toward it; build Ep8 last.
5. Ep7 after the D2 rename (its film is the furthest along of the later ones); Ep5-6 origins after Ep4. They are short
   and can also ship early as standalone "Origins" chapters, as long as Episode 1 is out first (e6m4 shows the Master
   going down to hold the door, which is Ep1's twist).

**The next 6 scripts to write (one script-writer per mission; game-designer, Opus 5.5)**
1. **`mission-00.md` "The Night of Knives"** (Ep1 prologue mission). Turn ep1 5.0 into a full build spec: the M1 map's
   corner at night (camera bounds, sight x 0.6), the watch-keep that cannot train, Vessa L2 at 45 % HP, Old Vey's fading
   kit (5.0.1) and brain, Mother Hush (5.0.2), the 5 assassin waves aimed at Vessa, 3 watch braziers, Grief's Fire, the
   8:00 dawn countdown, `m0_fall` / `m0_dawn` hooks, the 14 lines, easy / hard table, and every spawn point checked against
   the generator (seed 1101). Done when the A4 fight is sized (survivable with 3 braziers, ~2-4 escort losses on normal).
2. **`mission-02.md` rewrite "The Orb Beneath the Ice"** (Fire vs Shadow on Torvald's neutral lake). Apply ep1 5.2 rows
   1-9 (Malrik's dig camp, Gloom Thralls, NEUTRAL Sentinels, walls and storms, the new lines L2-L15), keep the floes, dig
   rate and Heartfrost numbers, add Aldra's 2-line voice and ridge silhouette (th. Q1), keep `max_tier = 2`, and re-check
   the 70 % fight rule against Shadow units. Done when the spec matches the 1v1 story and nothing in the old numbers moved.
3. **`mission-03.md` "The Signet in the Sighing Wood"**. From ep1 5.3: the map (seed 1303) with every coordinate checked,
   Root Hearts and Ember Stakes, the tavern's first free hire, the drain squads and the race (Malrik carries and drops the
   Signet), the twist cutscenes, the Warden gates, Old Mossjaw, 20 lines, rewards (Signet, companion), the full difficulty
   table. Done when the race is fair on normal (Malrik reaches the tree ~90 s after the barrier falls if ignored).
4. **`mission-04.md` "The Hollow Throne"**. From ep1 5.4 and 6: Crown Hollow at war, the Hollow meter, the isle seat, the
   Rise, 4 pylons (positions cleared against lanes and fords), phases 1-3, Cracked Leg, the darkest-hour trigger and its
   end state, Old Vey's renewed kit, Turn the Key, 22 lines, win / lose, easy / hard. Done when the expected phase times
   add up to 22-28 min on normal.
5. **`mission-e2-01.md` "The Burning Grove"** (Ep2 mission 1, Vessa + Old Vey). The night after `ep2_opening`: the Fire
   army rides into the Sighing Wood burnt and frozen (M3's map, seed 1303, ash and snow terrain, the Oldroot dead). Reach
   Ysolde's last Heartwood (a Root Heart variant, 1 500 HP) before 6:00, then hold it 12:00 against Shadow (Malrik, bot)
   and Ice (Torvald, bot) attacking from two sides (2v1: every wave <= 70 % of the player's army, the waves alternate
   sides so the player learns both enemies). Wren and 12 Nature survivors (NEUTRAL story units, escort to the keep) are a
   secondary. Teaches the **Citadel** (`max_tier = 3`, from 5:45: Ashveil Saboteur) and **Old Vey as the callable helper**
   (th. kit, story numbers). Torvald's first lines as an enemy; Ysolde appears wounded at the Heartwood at the end and joins
   Fire (cutscene `c_e2_ashes`). Target 20-25 min.
6. **`mission-e3-01.md` "Take the Ford"** (Ep3 mission 1, Malrik + Torvald bot). Right after `ep3_opening`, on
   `data/maps/evenmead.map` (north seat; read the map file, do not invent positions). 2v2: the player's Shadow base on the
   ridge plus Torvald's Ice bot beside it, against Ysolde + Vessa bots on Lark Hill. Take the stone ford (a capture zone,
   hold 60 s) and then the foot of Lark Hill (3 points) while the river slows every crossing; the Keystone Shard sits in
   Malrik's artifact slot and whispers (Obren lines) but has no active power yet. Stronghold only, Gloom Deacon caster;
   Mother Hush as a story unit (not callable). Ends on Malrik's "I will not stop" made true: the ford is his, the tree is
   not. Target 22-28 min; the writer of `mission-e4-01.md` "Hold Lark Hill" (next up) must use the same map numbers.

Next up after these six: `mission-e4-01.md` "Hold Lark Hill", the Ep2 outline (e2m2-e2m5 in full), the Ep3+4 outline
(E34.D2), the Ep8 outline with the boss spec of 4.2, and Ep7's E5.D2 (renamed E7.D2).

## 7. Consistency notes (found while reading; fixes for the doc owners)
| # | Where | Issue | Fix (recommended) |
|---|---|---|---|
| C1 | `episode5-opening.md` 1, chronicle "Last year: the Master vanishes" | ep1 says twelve years (Vey's absence, his letter "twelve years later") | Row becomes "Twelve years ago: he vanishes. His dragons wait in the empty sky; last year they fly home". "The 130th Laurel Duel, the first with his chair empty" becomes "the first since the Archons declared him gone" (H17b already says he never sat there again). H19's "young adult" Vessa and Malrik: the cities gift is ~3 years before the vanishing, so Vessa is about 17 there; e5m4 shows the same ages |
| C2 | `tiers.md` 6 "3+ not specified" | - | D7: M0-M4 `max_tier = 2`; Citadel from e2m1; each new kingdom's episode opens the Citadel in its mission 2 |
| C3 | `t3-helpers.md` R5 / Q2 ("campaign 3" = mission 3) | e34. R4 later read it as Episode 3 = Malrik + Hush | This outline follows e34.: helpers become callable in their own episode (Vey e2m1, Hush e3m2, Maelis e4m2, Aldra e7m2); Ep1 keeps them as story units |
| C4 | ep1 M3 / C3: Ysolde already knows the relics are a lock; Torvald "felt something counting" | Never explained | e6m4 "The First Crack": both were at Crown Hollow when the lock failed |
| C5 | `episode2-opening.md` Q1 | "Sunrise Road moves later" | e2m4 (fourth mission) |
| C6 | `waves.md` "Ice, Nature and Shadow campaigns repeat the pattern" | No per-kingdom campaigns exist | Realised as Shadow Ep3, Nature Ep4, Ice Ep7, plus the origins (Ep5-6) and each kingdom's Ep8 road |
| C7 | `items.md` campaign table | Later artifacts missing | items-coder adds rows when their mission specs land: `keystone_shard` (e3m1, with a Hollow cost), `heartwood_seed` (e4m3); Ep8 relics are the existing four |
| C8 | `story-episode-1.md` 3 Story menu | Only 2 episode cards | ui-designer: 8 cards; Ep5-6 marked "Origins"; Ep8 opens the "Whose road?" picker |

## Open points (defaults taken; JS can change them)
- Ep5 and Ep6 at 4 missions each (3 each is the first cut lever).
- The dark ending exists (a short tail); the true ending is "Break the throne".
- Ep8's boss is Obren's last body; Mother Hush lives (she flees in the Shadow road and stands guard with Malrik at the end).
- The finale is ENGINE; a VIDEO version is optional later production, like Episode 1's five.
