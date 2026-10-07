# Wave Strike: a wave-fighting second mode (design, 2026-10-05)

JS (2026-10-05): "can u add a game similar to desert strike", then "no it's a SC2 game in Battle.net, wave fighting".
That is a StarCraft II **arcade custom map** of the "sending" / tug-of-war family: two teams on a long map, each player
buys units that walk down a lane in timed waves and fight on their own; income grows; the enemy's main building dies =
the match is won. This spec turns that *genre* into a Four Wizards mode. Nothing is copied from the original map: no names,
no lines, no art, no layout, no numbers. Working title **Wave Strike** (in-game name can change; "Strike" alone is fine).

Status: **M1 BUILT (2026-10-06)**, see section 13 "M1 as built"; balance pass 13.1 (4 kingdoms, matrix prices, pacing). Q1-Q7 answered with the recommendations (table below).
M2 / M3 not started. Numbers are first guesses, tuned by the labs (section 9).
Short names used below: **horn** = one wave tick; **card** = one bought unit line in a player's roster; **Bastion** = a
team's core building; **lane** = the walkable path between the two Bastions.

---

## 0. Decisions for JS (recommendation first; the rest of the spec assumes the recommendations)

**Answered 2026-10-06 (M1 start): every question takes its "Recommended" column** (Q1 second mode in this project,
Q2 shared 40 s horn, Q3 leashed avatar, Q4 one kingdom per player, Q5 split banks, Q6 full vision, Q7 30:00 cap).

| # | Question | Recommended | Other options |
|---|---|---|---|
| Q1 | Where does it live? | **A second mode in this project**: main menu `Wave Strike` beside `Skirmish` and `Story`, own maps, reuses every unit, model, VFX, sound, UI piece, map tool and lab (section 1) | New repo / standalone game; a lane-push MOBA mode; a faithful "sending" clone (section 12) |
| Q2 | Wave rhythm | **Shared horn every 40 s**: every card you own spawns one copy at each horn and the whole wave marches (persistent roster). Buying is open all the time; a buy joins the *next* horn | Build phase then wave (turn-like, slower, dead time); continuous production + "Send" button (no shared rhythm, harder to read, harder for bots and perf) |
| Q3 | The wizard | **Avatar on a leash**: you control your kingdom's wizard (F / Q / E spells, items), but only in your own half of the lane (the Ward Line at the middle). Respawns, never a loss | Hands-off commander with 3 global "edicts" on cooldown (simpler, less Four Wizards); full free hero (snowballs: one hero solos a lane) |
| Q4 | Kingdom per player | **One kingdom per player** (its T1-T3 units, caster, titans) + neutral mercenaries shared by all | Draft from all four kingdoms (more combos, much harder to balance and to read) |
| Q5 | Team income | **Split**: each player has their own bank and roster; the team shares the Bastion HP, the tower and wall slots (paid by whoever builds) and the kill bounty (split evenly) | Fully shared bank (one rich player decides; idle allies) |
| Q6 | Vision | **Full vision** (no fog in Wave Strike): spectator friendly, bots read the enemy roster fairly, saves the fog cost on 300-600 units | Fog on the enemy half (hides the enemy roster; the roster panel would need a "scout" rule) |
| Q7 | Time limit | **30:00** cap; from **24:00 "Last Horns"**: horn every 30 s, Bastions lose 25 % armour; at 30:00 the higher Bastion HP % wins (ties: score) | No cap (risk of 45-min stalemates); 20-min cap (too short for titans) |

---

## 1. The recommendation: a second mode in the same project

**Why here**: every hard part of the genre is already built and tested in this repo: 80+ units with real combat,
autocast casters, champions with their own brain, titans, towers, walls, levels, "+" upgrades, tiers, items, the map
tools (MapLayout, World Forge templates and `gen`, the map gate, the balance predictor), the Bot Lab, the Balance Lab,
the Unit Lab (the cost-efficiency matrix *is* the price list of a wave game), the Replay / Perf / UI / Art Labs, the
menu kit, the HUD skin, audio and VFX. A wave game is mostly **rules on top**: a horn, a lane, a buy menu, a bank and
units that walk by themselves. A new repo would rebuild or fork all of that.

What Wave Strike reuses, piece by piece:

| Existing piece | How Wave Strike uses it | Change needed |
|---|---|---|
| `UnitType` / `data/units/*.tres` (all four kingdoms) | Every card is a `UnitType` id; `cost`, `pop`, `requires_tier` read as-is | None (prices scaled by a per-mode table, 4.4) |
| `Unit` combat, aggro, attack-move, avoidance, statuses | Spawned units get an attack-move along the lane | New `LaneMarch` child node (7.1), no change to `Unit` itself except one flag (`Unit.lane_owned`) |
| `CasterAbility` + autocast, `AICasters` rules | Casters march with autocast **all on** (the bot rules of caster-units.md 8.3), behind the front | `AICasters` behind a stand-in commander, as the Unit Lab already does |
| `T3Kit`, `NewUnits12`, `BowmanKit`, support casters | Work unchanged (they attach in `Unit._ready`) | None |
| Levels (`levels.md`), "+" upgrades (`tiers.md` 5) | Card ranks spawn units at level 1 / 2 / 3 with or without "+" | None (reuse `add_xp` / the `plus` modifier) |
| Keep models + `set_tier` | The **Bastion** is the kingdom's keep model at Citadel look, scaled 1.3 | Art: one dressing pass (banners, lane brazier) |
| Towers (`*_tower.tres`), walls (`walls.md`), building levels | Tower slots and wall sockets on the map (6) | Slot rule only (no workers: buying places it, 4.6) |
| Champions (`Champion`, `ChampionBrain`) | A **champion card**: the champion marches with the waves (brain intent `lane`), revives at the horn | One new brain intent (`lane`), ai-coder |
| Titans (step 13 / 13c) | Late one-shot buys (4.5) | None to the titans |
| Wizards, spells, items, essence | The player avatar (section 5) | A leash rule; shop at the Bastion |
| Neutral camps (`map-fill.md`) | **Mercenary camps**: hire neutral creatures as one-shot sends (4.7) | Hire API on `CampManager` (systems) |
| CapturePoint (`map-fill.md`) | The **Relay Shrine** in the middle (+income) | New kind `relay` (systems) |
| MapLayout / LayoutLevel / World Forge / templates / `gen` | Lane maps are `.map` files with new spot kinds (3.1) | New kinds + one `lane` template |
| Map gate + balance predictor | Symmetry, spacing, perf, bot fairness on WS maps | A `-Mode wave_strike` switch (7.9) |
| Bot Lab / Balance Lab | WS bot vs WS bot batches, 16 kingdom pairs | A WS match driver (7.9) |
| Unit Lab | Card prices and the bots' counter table | Lane terrain + "wave" spec type (9.1) |
| ScoreKeeper, end screen, Replay Lab | Score tab, replays | WS weights (7.6) |
| Menu kit, HUD skin, KeyLabels, UI Lab | Lobby, buy panel, HUD | New panels in `scripts/ui/wave_strike/` |

---

## 2. The match in one paragraph

Two teams (1v1, 2v2, 3v3 or 4v4) stand at the two ends of a long lane. Each player starts with **400 crystals** and
their kingdom's wizard beside their **Bastion**. Every **40 s** a **horn** sounds: every player gets their income, and every
card in their **roster** spawns one unit at their **gate**. The units walk the lane by themselves, fight what they meet,
smash towers and walls, and hit the enemy Bastion. Between horns the player buys cards (or ranks them up), raises their
income with **Coffers**, buys team towers, unlocks tiers, hires mercenaries for a one-time punch, and fights with their
wizard in their own half. A Bastion at 0 HP = that team loses. Target length **18-25 min**; 30:00 hard cap.

---

## 3. Map layout

### 3.1 Shape and spot kinds
- **One wide lane is the default** (Q-free: it is the mode's identity: big readable clashes, one front line to watch).
  A second map has **two lanes** for variety (3.3). No three-lane map in v1 (thin waves, too much to watch).
- Size: **280 m x 100 m** (1v1 / 2v2), **320 m x 140 m** (3v3 / 4v4). `MapInfo.setup` already takes any size.
- Full mirror symmetry (point mirror through the centre), checked by the map gate.

New `MapLayout` spot kinds (World Forge `.map` → `_layout.tres`; owner four-wizards-high):

| Kind | `sub` / props | Meaning |
|---|---|---|
| `bastion` | team | The core building position |
| `gate` | team, `seat` | A player's spawn pad (one per seat, 6 m apart, in front of the Bastion) |
| `lane` (a `path`) | `lane_a`, `lane_b` | Ordered waypoints from team 0's gates to team 1's Bastion; team 1 walks it backwards |
| `tower_slot` | team, `ring` 1-3 | Where a tower can be bought (ring 1 = by the Bastion, 3 = forward) |
| `wall_socket` | team, `width` | A chokepoint plinth where a barricade can be bought (6) |
| `merc_camp` | `kind` (bristleback / mirefang / gloomcap / hollow_stag) | A mercenary camp on the flank (4.7) |
| `relay` | - | The Relay Shrine in the middle (4.3) |
| `ward_line` | - | The leash line for wizards (the mirror line) |
| `shop` | team | The Bastion's item counter (items.md shop rule, 12 m) |

### 3.2 Map 1: "Ashwind Reach" (1v1 / 2v2, one lane)
```
 T0 base           own half                 middle                 own half            T1 base
[Bastion]=gates= ring1 towers == socket == ring2 == [Relay] == ring2 == socket == ring1 == gates=[Bastion]
                  \__ merc camp (flank)                                    merc camp (flank) __/
```
- Lane 40 m wide, **220 m gate to gate**. A unit at speed 3.5 walks it in ~63 s: two waves are on the lane at once,
  the first clash happens near the Relay ~25-30 s after the first horns.
- Each side: 3 tower rings (2 slots each = 6 tower slots), 2 wall sockets (one per narrowing at ring 2), 1 mercenary
  camp on its own flank (reachable only by its side's mercenaries, never by marching units), the Bastion at the far end
  in a 30 m plaza.
- Look: dry autumn plains (reuses the Crown Hollow kit + Fourfold Hollow's golden palette); a dusty road down the lane.

### 3.3 Map 2: "Twin Ribbons" (1v1 / 2v2, two lanes)
- Two 24 m lanes separated by a river (the step-12 `RiverSystem`, no crossings except **one ford at the Relay**).
- Every card has a lane toggle (**A / B / Split**, Split = alternate each horn); default Split.
- Teaches choices: stack one lane to break it, or defend both. Towers: 2 rings per lane.

### 3.4 Map 3: "Fourfold Causeway" (3v3 / 4v4, one wide lane, M3)
- 320 x 140, lane 60 m wide, 4 gates per side, Bastion with 1.5x HP, 8 tower slots per side, 2 Relays (left and right
  of the middle; each gives its holder half of the 1v1 Relay income).

---

## 4. Rules

### 4.1 Round and wave timing (Q2: shared horn)
| Item | Value |
|---|---|
| First horn | **0:30** (time to buy the first cards) |
| Horn interval | **40 s** (24:00+: 30 s "Last Horns") |
| At each horn | 1) income paid; 2) every card spawns its copies at the owner's gate, staggered 0.15 s per unit to spread the cost; 3) the wave gets its lane order |
| Buying | Always open; a card bought now first spawns at the next horn. Cancel within 5 s = full refund |
| Spawn order | Melee cards first, ranged next, casters last (the formation forms itself on the lane) |
| Pre-horn warning | 5 s countdown on the HUD, a soft drum at 3 s |

**Why a shared horn over the two others.** (1) Readable and spectator friendly: everyone knows when the next clash
comes; waves meet as waves. (2) Bots decide on a clock: one decision pass per horn, deterministic, cheap. (3) Perf: spawns
come in scheduled bursts we can stagger and budget, instead of a continuous trickle. (4) Team play: allies' waves leave
together and fight together. (5) Persistent roster = long-term planning (the genre's core). A build phase then wave
leaves dead time; a free "Send" button makes waves trickle (no clash moment) and gives the faster clicker the edge.

### 4.2 Economy
One resource, **crystals** (`Economy` per player, existing contract). Essence stays the wizard's item currency
(`EssenceBank`, items.md rules: +1/s, kill income by the wizard). No gold, no workers, no nodes.

| Source | Value | Notes |
|---|---|---|
| Start | **400** | |
| Base income per horn | **100** | |
| **Coffer** levels (personal) | +**15** per level per horn, 8 levels | Prices 150, 200, 250, 300, 350, 400, 450, 500 (payback 10 → 33 horns: early Coffers pay, late ones do not; no runaway). Bought from the buy panel; the Bastion grows a small coffer prop per level |
| Kill bounty (team) | **12 %** of the killed unit's card price, split evenly among the team's players | x**1.5** when the kill is in the team's own third of the lane (defender bonus) |
| Tower / barricade destroyed | 25 % of its price to the killing team | |
| Relay Shrine | +**25** per horn per player of the holding team (4.3) | |
| Underdog tithe | +**8 %** income per full 15 % of Bastion HP gap, max +**24 %** | Comeback (4.10) |
| No interest | - | Interest rewards hoarding and snowballs; excluded on purpose |

Expected curve (1v1, a sound player): horn 10 ≈ 190 / horn, horn 20 ≈ 260, horn 30 ≈ 300; ≈ 6 500 crystals over a
20-min match. The Balance Lab tunes base income and the Coffer step first (two knobs, `WaveStrikeRules`).

### 4.3 The Relay Shrine (neutral middle)
- A `CapturePoint` of kind `relay` in the lane centre, radius 9 m. Held by the team with more unit **pop** inside for
  4 s (contested = nobody). Pays at each horn. Holding it 3 horns in a row also gives **+1 level of XP** to every unit
  spawned by that team at the next horn (a short "war banner" glow).
- It never moves the front by itself; it rewards winning the middle without paying the leader too much (25 per horn is
  ~10 % of a mid-game income).

### 4.4 The buy panel: cards, tiers, caps
**Card sets per kingdom** (ids from `data/units/`; T = `requires_tier`):

| Kingdom | T1 cards | T2 cards (Stronghold) | Caster (Stronghold) | T3 cards (Citadel) |
|---|---|---|---|---|
| Fire | flame_guard, scorchling, ember_archer, scorchbow, ash_hurler, blaze_rider, emberdart_harrier | pyre_adept, cinder_arbalest, pyrehoof_lancer | kilnwarden | ashveil_saboteur, sunforge_cataphract |
| Ice | rimeling, rimeshield, frostbow, shardcaster, rime_seer, rime_colossus, rime_harrier, snowdrift_rider | hoarlight_magebow, frost_mortar, rimehorn_rider | rimecarver | shardguard, frostcrown_juggernaut |
| Nature | sprigling, thornling, burr_slinger, thistle_darter, wildwood_archer, bloomtender, bramblehorn, bramble_harrier, stagrunner | vinelasher, greenheart_oathkeeper, thornback_charger | bramblesage | briar_roc, glade_outrider |
| Shadow | gloom_thrall, grave_hound, shade, nightbolt, bleakbow, shadow_knight, duskbolt_harrier, gloam_rider | hexweaver, hollow_oathsworn, barrow_knight | gloom_deacon | nightblood_reaver, veilborn_dreadrider |
Plus per kingdom: the helper (stormbottle_genie etc., Citadel, one card max), the champion card (4.5), the titans (4.5).
Workers, caravans and summons are never cards. M1 uses **8 cards** (2 kingdoms x 4: Fire flame_guard, ember_archer,
scorchbow, blaze_rider; Shadow gloom_thrall, grave_hound, bleakbow, shade).

**Card price** = `UnitType.cost x mode_mult[id]` rounded to 5, `mode_mult` default **1.0**, set per unit from the
Unit Lab matrix (9.1) in `data/wave_strike/card_prices.tres`. Persistent cards are worth far more than one unit; the
income table (4.2) is sized for that, not the prices.

**Supply cap (the per-wave cap)**: the sum of `pop` of a player's cards (all ranks) is capped:
| Mode | Keep | Stronghold | Citadel |
|---|---|---|---|
| 1v1 | 24 | 40 | 56 |
| 2v2 | 20 | 32 | 44 |
| 3v3 / 4v4 | 14 | 22 | 30 |
The cap is the main **anti-snowball and perf** rule: a rich player cannot field infinite waves; extra money goes to
ranks, towers, Coffers, mercenaries, titans. **Sell a card**: 50 % refund, frees its pop at the next horn.

**Tiers (per player)**: the War Hall in the buy panel: **Stronghold 250 crystals, 45 s, from horn 6 (4:00)**,
**Citadel 450 crystals, 60 s, from horn 14 (9:20)** (reuses `TierSystem` gates with mode values; the keep model on
the Bastion shows the *team's* highest tier).

**Card ranks (unit upgrade tiers)** per card:
| Rank | Price | Spawned unit |
|---|---|---|
| 1 | card price | level 1 |
| 2 "Drilled" | +60 % of card price (Stronghold) | level 2 + the "+" modifier (+10 % HP / damage) |
| 3 "Elite" | +100 % of card price (Citadel) | level 3 + "+" + `elite` modifier (+10 % HP / damage, +1 armour) |
Ranks raise power without raising pop: the late game gets stronger, not bigger (perf).

**Armoury (personal, team-wide effect on own units)**: Weapons I-III (+6 % damage each; 200 / 350 / 500), Armour I-III
(+1 armour each; 200 / 350 / 500), Arcana I-II (casters +15 % spell power, +20 % mana regen; 250 / 450). Modifiers via
`add_modifier("ws_armoury", ...)` on spawn.

**No micro, by design**: units are not commandable (`Unit.is_commandable()` false for lane units: selecting one = inspect).
Casters autocast **every** spell with the bot rules; spells that need a player decision are off or re-ruled:
| Spell | In Wave Strike |
|---|---|
| Umbral Passage (Gloom Deacon recall) | Off (no retreat in the lane) |
| Scrying Rune (Rimecarver) | Off (full vision) |
| Rime Bulwark | Autocast on the bot rule (a dive onto the back line) |
| All others | Autocast, bot rules (caster-units.md 8.3) |

### 4.5 Champions and titans
- **Champion card** (Stronghold, **one per player**): hire price 275 crystals + 100 essence (the class-era table),
  pop 2 of the cap. The champion marches with the waves (brain intent `lane`: stays inside the wave, never leaves the lane,
  shops at its own Bastion when its purse allows, between waves). Dies = revives at the **second** horn after its death,
  free. Levels, classes and items persist (champions.md, skills-rework.md).
- **Titans**: one-shot buys at **Citadel and horn 18 (12:00)**, price = their skirmish cost x 1.2, **one alive per
  player**, pop counted while alive, spawns at the next horn in front of the wave. No respawn. The 4 step-13 titans and
  the 13c options (Frost Dragon, Barrow Giant) are all listed for their kingdoms; the Ember Crucible's Fire version is a
  mode-specific card: "forge a free Flame Guard each horn for 8 horns" (Citadel, 400).

### 4.6 Defences: towers and barricades
- **Towers**: the kingdom tower type (`*_tower.tres`: Ember Spire, Night Spire, ...), bought into a free `tower_slot`
  of the own side (no workers: it rises over 15 s). Price 150 / 200 / 260 for rings 1 / 2 / 3 (forward is pricier,
  it dies more). Tower levels (building-levels.md) as an upgrade button: +40 % HP / +30 % damage, 180 crystals.
  Team slots: any player of the team may build into any team slot; the builder gets the refund / bounty share.
- **Free towers**: each team starts with ring 1 built (2 towers): the Bastion is never naked at horn 1.
- **Barricades** at `wall_socket`s (M2, cut-first if time runs short): the kingdom wall look of `walls.md` (Fire burning
  palisade, Ice wall, Nature hedge, Shadow bone wall, with their twists), 300 crystals, 2 500 HP. A socket is a raised
  plinth that is **always off the navmesh**: the lane narrows around it, a barricade **never changes pathing** (no
  runtime rebake). Built, it **taunts** enemy units within 7 m (they hit it before walking past) and gives own units
  within 6 m +2 armour. Siege bonus rules of walls.md apply (rams / titans / catapult units).
- **Bastion**: HP = the kingdom's Citadel keep HP x **2.5** (Fire / Shadow 8 750, Ice 10 500, Nature 7 875; Nature's
  regrowth keeps its HP lower, as in skirmish), attack as the Citadel keep, armour 3. 4v4: x1.5 again.

### 4.7 Mercenaries (one-shot sends)
- Each side's flank `merc_camp` sells **one-shot packs** of neutral creatures (map-fill kinds) that spawn at the next
  horn in front of the wave and march; they do not persist. Each pack has a 3-horn restock per player.
| Pack | Price | What | Role |
|---|---|---|---|
| Bristleback Charge | 180 | 3 bristlebacks | Tanky front, early |
| Mirefang Pack | 220 | 4 mirefangs | Fast flankers, dive ranged |
| Gloomcap Ring | 260 | 1 gloomcap elder + 3 sprouts | Area denial |
| Hollow Stag | 400 (Stronghold) | 1 hollow stag | A mini-boss push |
- Mercenaries count no pop (one-shot) but at most **one pack alive per player**. They give the rich player a way to
  spend over the cap without the snowball being permanent.

### 4.8 The wizard (Q3: avatar on a leash)
- Each player's kingdom wizard (Vessa, Malrik, Torvald, Ysolde) stands at their Bastion. Normal controls (Classic /
  RTS camera / Hero WASD settings all work), F / Q / E spells, levels, items bought at the Bastion `shop` with essence.
- **Leash**: the wizard cannot cross the **Ward Line** (the lane's mirror line); at the line it stops (the move order
  clamps; a soft rune wall shows). Rationale: the wizard defends and supports, it cannot solo-push the enemy Bastion.
- XP: from kills near the wizard (levels.md radius) and **+40 XP per horn** (everyone levels; nobody gets locked out).
- Death: respawn at the Bastion after **15 s + 2 s x level**; never a loss. Kill bounty for an enemy wizard: 100
  crystals to the team.
- Damage rule: wizard spells and attacks deal **x0.75 to Bastions and towers** (they help waves, they do not siege).
- STR / INT path: on (the J ability works).
- Bots: the existing wizard autocast (`ai_auto_cast`) + a small leash brain (stay 8-14 m behind the own front, retreat
  under 30 % HP to the Bastion's healing ring).

### 4.9 Win, lose, time limit
- Enemy **Bastion destroyed** = victory for the team (all its players). Concede = gg for that player: in team modes
  the conceding player's cards keep spawning on autopilot (the bot takes over at Easy; ai-2v2 rule "a conceding bot's
  kingdom crumbles" does not apply: there is no base to crumble).
- **Last Horns** (24:00): horn every 30 s, Bastion armour -25 %.
- **30:00**: higher Bastion HP % wins; equal (within 1 %) = higher score (7.6).

### 4.10 Comeback and anti-snowball rules (all in `WaveStrikeRules`, each with an on / off knob for the labs)
| Rule | Effect | Type |
|---|---|---|
| Supply cap (4.4) | A lead cannot become an endless army | anti-snowball |
| Flat base income, Coffers with rising prices, no interest | Most income is not tied to winning fights | anti-snowball |
| Bounty only 12 %; defender bonus x1.5 in own third | The defending side earns more per kill | comeback |
| Underdog tithe (+8 % per 15 % HP gap, max +24 %) | The losing team out-earns slowly | comeback |
| **Bastion Rally** at 66 % and 33 % HP (once each) | A free shockwave (300 damage, 3 s daze, 14 m) + ring 1 towers rebuilt free + every own unit on the own half healed 30 % | comeback |
| Forward towers cost more | Pushing deep needs value, defending is cheap | comeback |
| Wizard leash | No hero can solo a broken lane | anti-snowball |
| Relay pays a little (25 / horn) | Winning the middle is good, not decisive | anti-snowball |
Lab target (9.2): a team that is 20 % Bastion HP behind at 10:00 still wins **25-35 %** of bot games (no lock-in, no
random coin flip either).

### 4.11 Spectator-friendly pacing
- Full vision; the **front-line marker** (a gold tick on the lane strip where the two waves meet) and **wave power bars**
  (sum of card value alive per side) on the HUD.
- Horn countdown visible to all; the horn is a short, distinctive sound per kingdom (Audio Lab budget).
- Observer mode (M3): watch bot games with a free camera, the roster of every player, income graphs (ScoreKeeper
  history). Replays (Replay Lab): the command stream is tiny (buys, ranks, wizard inputs).
- Camera: Space centres on the wizard, **Tab** jumps to the front line, the lane strip minimap is clickable.

### 4.12 Team play
- 2v2 / 3v3 / 4v4: each player one gate, own roster, own bank, own wizard; the team shares the Bastion, tower and wall
  slots, the Relay income (paid to each player), the bounty (split). Allies see each other's rosters; pings reuse the
  20.D2 ping keys (Alt+click, F4).
- Mixed kingdoms on a team are allowed (mirrors too).
- An "Ally assist" button lets a player pay for a card rank of an ally's card (gifts in a controlled form: one per horn).

### 4.13 Bots and difficulty
**WaveBot** (ai-coder): one decision pass **3 s before each horn** (+ a reaction pass when its Bastion drops below a
Rally threshold). It reads only what a player sees (full vision is the rule for everyone).

Budget split per personality (share of available crystals per pass, after a 0-100 reserve):
| Personality | Cards | Ranks / Armoury | Coffers | Towers / walls | Mercs / titans | Signature |
|---|---|---|---|---|---|---|
| **Steward** (eco) | 35 % | 15 % | 40 % until Coffer 6 | 10 % | 0 | Weak until 8:00, strong late |
| **Hammer** (aggro) | 60 % | 20 % | 10 % | 0 | 10 % | Pushes the Relay early |
| **Warden** (defence) | 40 % | 20 % | 15 % | 25 % | 0 | Towers, barricades, then a late titan |
| **Gambler** | 40 % | 10 % | 15 % | 5 % | 30 % | Mercenary packs, earliest titan |
| **Tactician** (counter) | 50 % | 20 % | 20 % | 10 % | 0 | Buys the best counter to the enemy roster (Unit Lab counter table, 9.1) |
Every personality also counter-picks with a weight (Tactician 0.8, others 0.3) and keeps a melee / ranged / caster mix
(at least 40 % of its pop melee). Default in the lobby: Random personality.

| Difficulty | Decision delay | Counter knowledge | Income |
|---|---|---|---|
| Easy | spends 10 s late, keeps 150 unspent | none (random from its mix) | 100 % |
| Normal | on time | top-3 counters, 50 % of passes | 100 % |
| Hard | on time + reaction pass | full counter table | 100 % |
| Brutal | as Hard | as Hard | **+15 %** (shown in the lobby as "cheats: +15 % income") |

### 4.14 Ladder of match types
| Entry (lobby "Match type") | Players | Map | Notes |
|---|---|---|---|
| **Practice** | 1v1 vs Easy Steward | Ashwind Reach | Hints on (first horn, Coffer, tier) |
| **Duel** | 1v1 | any 1v1 map | Standard |
| **Quick Strike** | 1v1 / 2v2 | any | Start 800, horn 30 s, Last Horns at 12:00, cap 15:00 |
| **Allies** | 2v2 with an ally bot | any 2v2 | |
| **War Host** | 3v3 / 4v4 (M3) | Fourfold Causeway | The big one; Perf "low" detail auto-on |
| **Bot Arena** | any, all bots | any | Observer mode, speed x1-x4 |
| **Gauntlet** (M3) | 8 rungs, local progress | rotating | Easy Steward → Normal Hammer → Normal Warden 2v2 → Hard Tactician → Hard 1v2 handicap → Hard Gambler 2v2 → Brutal Tactician → Brutal 4v4 War Host; stars for time / Bastion HP left; saved in `user://wave_strike.cfg` |
No online play (the project has none); "ladder" = this local list.

---

## 5. The wizard role in short
Avatar on a leash (4.8). It keeps the Four Wizards identity (your wizard is the face of your kingdom), gives the player
something skilled to do between horns (genre weakness: the wait), and the leash + x0.75 siege rule keep the waves the
real win condition. The hands-off option (edicts) stays a fallback switch: `WaveStrikeRules.wizard_mode = &"avatar" |
&"edicts" | &"none"` (`edicts` = 3 global spells: a heal pulse on own wave, a slow field on the enemy wave, a haste banner,
on 90 s cooldowns; specified only if the avatar fails playtests).

---

## 6. Numbers in one block (the `WaveStrikeRules` defaults)
```
horn_first 30 s · horn_interval 40 s · last_horns_at 900 s · last_horns_interval 20 s · time_limit 1800 s   (13.1: was 1440 / 30)
start_crystals 400 · base_income 100 · coffer_step 15 · coffer_prices [150..500 step 50] · bounty_pct 0.12
defender_bounty_mult 1.5 · relay_income 25 · underdog_pct_per_step 0.08 (step 15 % HP, max 0.24)
supply_cap {1v1: [24,40,56], 2v2: [20,32,44], big: [14,22,30]} · stronghold 250 / 45 s / horn 6 · citadel 450 / 60 s / horn 14
rank2 +60 % · rank3 +100 % · sell refund 50 % · tower prices [150,200,260] · barricade 300 / 2500 HP
bastion_hp_mult 2.0 (13.1: was 2.5) · rally_at [0.66, 0.33] · titan_from_horn 18 · titan_price_mult 1.2 · merc restock 3 horns
wizard_leash ward_line · wizard_siege_mult 0.75 · wizard_horn_xp 40 · wizard_respawn 15 + 2 x level
```

---

## 7. What changes in the engine

### 7.1 Auto-march and auto-fight (`LaneMarch`, gameplay-coder-high [H])
A child node `"LaneMarch"` added by the director to every spawned lane unit; `Unit` itself only gains
`var lane_owned := false` (makes `is_commandable()` false; lead contract change).
- **Waypoints**: the lane `path` as a list of points; the unit attack-moves to the next point; within 5 m (or past its
  plane) it advances. Lane offset: each unit keeps a lateral offset (-0.4..0.4 of lane width, from its spawn slot) so
  waves spread across the lane instead of a conga line.
- **Target priority** (score, highest wins; re-evaluated every 0.25 s, staggered by unit index):
  units in attack range 100 > titans in range 90 > units in aggro range 80 (casters +10 when `prefer_casters`) >
  taunting barricade 75 > towers 60 > walls 40 > Bastion 30. Ranged units never chase past 6 m off the lane.
- **Leash**: a unit pulled more than **12 m** off the lane line drops its target and returns (re-aggro after 1.5 s).
- **No stall**: idle (no target, no movement) for 2 s = re-issue the next waypoint; stuck (moved < 0.5 m in 4 s) =
  side-step 2 m then resume (Perf / Bot Lab stuck counter must stay 0).
- **Flyers** follow the same waypoints at their height; towers and Bastions target them as today.
- Uses `set_auto_target` (contract) and `command_attack_move`; never writes `attack_target`.

### 7.2 Mode ruleset resource
`WaveStrikeRules extends Resource` (`scripts/world/wave_strike/wave_strike_rules.gd`, data
`data/wave_strike/rules_default.tres`, `rules_quick.tres`, `rules_warhost.tres`, `card_prices.tres`). Every number of
section 6. Labs read and override it like Balance Lab variants (in memory).

### 7.3 The level, director, spawners, economy, roster (systems-coder; `scripts/world/wave_strike/`)
| File / class | Job |
|---|---|
| `wave_strike_level.gd` `WaveStrikeLevel extends LayoutLevel` | Loads a WS layout; turns OFF every skirmish feature (workers, nodes, river slow, camps' wild behaviour, beasts, trade, taverns, crown, fog, tiers-as-skirmish); builds Bastions, gates, free towers, Relay, merc camps; owns the win / time-limit rules (overrides the "no living building" defeat) |
| `wave_director.gd` `WaveDirector` (group `"wave_director"`) | Horn clock (on `mission_time`-style held-time-safe clock), pays income, spawns cards (staggered), Last Horns, signals `horn(index)`, `horn_soon(seconds)` |
| `lane_spawner.gd` `LaneSpawner` | One per `gate`: spawn slots, the spawn order, attaches `LaneMarch`, applies rank level / "+" / armoury modifiers |
| `wave_bank.gd` `WaveBank` | Per player: wraps `Economy` (crystals), Coffers, the income formula, underdog tithe, bounty split (listens to `Events.unit_died`) |
| `muster_roster.gd` `MusterRoster` (group `"rosters"`, `for_player(seat)`) | Cards (id, rank, lane), `can_buy(id) -> String`, `buy(id)`, `rank_up(id)`, `sell(id)`, `pop_used()`, `cap()`, `cards()`, signal `changed` |
| `bastion.gd` `Bastion extends Building` | Core HP / attack / Rally pulses; `counts_for_defeat` |
| `relay_shrine.gd` | `CapturePoint` subclass, kind `relay` |
| Merc hire | `CampManager.hire_pack(team, seat, pack_id) -> String` |
Seats: one **seat** per player (team + gate index); `Economy` per seat (the 2v2 seat model of map-2v2.md / ai-2v2.md).

### 7.4 Buy / send UI (ui-coder; `scripts/ui/wave_strike/`, layout spec from ui-designer: `docs/design/ui-wave-strike.md`)
- **Buy panel** (bottom, replaces the command card): tabs **Units / Upgrades / Defences / Mercenaries**; Units = a grid of
  card buttons by tier rows (icons from the existing 109+ icons), price, pop, rank pips, greyed reasons
  (`Requires Stronghold`, `Supply full (40/40)`, `Not enough crystals`). Keys: physical **Z X C V B** / **N M , .** per row,
  **1-3** tab switch (no W A S D Q E F, per CLAUDE.md). Left-click buy, Ctrl+click rank up, Alt+click sell (confirm).
- **Roster strip**: own cards with counts, pop bar `32 / 40`, next-horn preview ("next wave: 14 units, 1 250 value").
- **Top bar**: crystals, income per horn (+ breakdown tooltip), essence, **horn countdown**, match clock.
- **Lane strip** (replaces the minimap): both Bastion HP bars, towers, front-line marker, Relay owner, waves as dots.
- **Enemy roster** (hover the enemy Bastion bar or press **I**): their cards and ranks (full vision rule).
- **Lobby**: main menu `Wave Strike` → match type, map (MapCatalog filtered `mode = wave_strike`), seats with kingdom
  tiles, bot difficulty + personality per seat; reuses `lobby_2v2.gd` / `kingdom_tile.gd`.
- End screen: Score tab (ScoreKeeper) + a WS tab (income graph, best cards by value traded, Bastion HP over time).

### 7.5 Per-team income system
Covered by `WaveBank` (7.3). `EssenceBank` unchanged. `GoldBank` absent (null; trade off).

### 7.6 Scoring / HUD
`ScoreKeeper` gets a WS weight set (military value traded 40 %, Bastion damage dealt 30 %, economy (income earned)
20 %, Relay horns held 10 %), selected by the level. HUD pieces in 7.4.

### 7.7 Replay / determinism
- Seeded RNG per match (spawn jitter, bot choices, `pick` calls); bots decide on the horn clock only.
- Replay Lab: record buys / ranks / sells / tower builds / wizard commands with the horn index and tick; replay = same
  result (test: two replays of a 6-horn bot match give the same Bastion HP and roster, as the Bot Lab determinism
  check).

### 7.8 Performance budget (300-600 units)
Today (quiet PC): 100 units ~6-7 ms, 200 units ~13 ms per frame (Perf Lab). A WS 1v1 peaks at ~200-300 alive units;
a 4v4 at 400-600. Budgets and measures:
| Scenario (Perf Lab) | Units | Target (desktop GTX 1660, 1600x900 high / laptop) |
|---|---|---|
| `ws300` (1v1 late) | 300 | **≤ 16.7 ms** p95 (60 fps), stuck 0 |
| `ws600` (4v4 late, `map_detail` low auto) | 600 | **≤ 33 ms** p95 (30 fps floor), stuck 0 |
Measures (in this order, each measured by the Perf Lab before the next): (1) no fog in WS (fog stamping per unit gone);
(2) **think staggering**: target scans every 0.25 s split over 4 frame buckets via a uniform spatial hash on the lane
(`LaneGrid`, systems), instead of per-unit group scans; (3) avoidance only for units within 30 m of an enemy (the rest
walk on the path with avoidance off); (4) far LOD: units > 60 m from the camera skip animation blending and use the
kit's low LOD; (5) projectiles and hit VFX pooled with hard caps (existing pool rules), no particles beyond 45 m;
(6) quick corpse cleanup (2 s) in WS; (7) the supply cap tables (4.4) are the final valve: if `ws600` misses, the big-mode
cap drops (14/22/30 → 12/18/26), never the gameplay rules. A spawn burst (up to 60 units at a horn) is staggered 0.15 s
per unit.

### 7.9 Tests and labs
| Test / lab | What it proves |
|---|---|
| `tests/test_ws_director.gd` | Horn at 0:30 / every 40 s / 30 s after 24:00; income paid; card spawns = roster; buys join the next horn; cancel refund |
| `tests/test_ws_bank_roster.gd` | Coffer math, bounty split, defender bonus, underdog tithe, supply cap per tier / mode, rank / sell rules |
| `tests/test_lane_march.gd` | Headless scripted waves: 10 flame_guard on an empty lane reach the enemy Bastion within 75 s; two mirrored waves clash within 6 m of the centre; leash returns; stuck counter 0 over 3 waves; flyers follow |
| `tests/test_ws_win.gd` | Bastion death = win for all team seats; 30:00 rule; Rally fires once at 66 / 33 % |
| `tests/test_ws_ui.gd` | Buy panel keys, greyed reasons, roster strip, horn countdown (UI Lab shots `ws_buy`, `ws_lane_strip`) |
| `tests/test_ws_bot.gd` | Normal vs Normal bot match on Ashwind Reach ends < 30:00 (early stop when the verdict is final) |
| Unit Lab `-Wave` spec | Lane terrain arena, roster-vs-roster "waves" (9.1) |
| Bot Lab `-Mode wave_strike` | 16 kingdom pairs x seeds, sim mode, win rate + length (9.2) |
| Map gate `-Mode wave_strike` | Symmetry, spot spacing, lane length parity, perf `ws300`, bot fairness 40 games (point mirror makes the balance predictor nearly trivial; keep it as a sanity check on lane length / width parity) |
| Perf Lab `ws300`, `ws600` | 7.8 |
| Replay Lab | 7.7 determinism |

### 7.10 File layout and owners
| Path | Owner |
|---|---|
| `scripts/world/wave_strike/` (level, director, spawner, bank, roster, bastion, relay, rules, lane_grid) + `scenes/wave_strike.tscn` + `data/wave_strike/` | systems-coder (`-high` for the director / level) |
| `scripts/units/lane_march.gd` + the `Unit.lane_owned` flag | gameplay-coder-high |
| `scripts/ai/wave_bot.gd`, `scripts/ai/wave_wizard_brain.gd`, champion brain intent `lane` | ai-coder |
| `scripts/ui/wave_strike/` (buy panel, roster strip, lane strip, lobby page, end tab), main menu entry | ui-coder; layout spec `docs/design/ui-wave-strike.md` by ui-designer |
| `data/maps/ashwind_reach.map`, `twin_ribbons.map`, `fourfold_causeway.map`, World Forge `lane` template, spot kinds, catalog `mode` tag | four-wizards-high (map tools owner) |
| `art/buildings/bastion/` (dressing), `art/environment/lane/` (relay shrine, gate pads, ward-line runes, banners) | tech-artist |
| `assets/audio/` horn per kingdom, Rally, "supply full" | ui-coder (audio), Audio Lab |
| `tools/unit_lab/` lane terrain + wave spec; `tools/bot_lab/` WS driver; Perf Lab scenarios | owner of each lab (lead assigns) |
| `CLAUDE.md` contracts (WaveStrikeRules, MusterRoster, WaveDirector signals, `Unit.lane_owned`, keys), `docs/plan/waves.md` step | lead |

---

## 8. Estimate, milestones, risks

Agent-hours are Opus 5.5 **medium** (the current effort rule), one task = one agent; wall time assumes 4-6 agents in
parallel and the one-Godot-at-a-time laptop rule for long lab runs.

### M1: one lane, 1v1, 8 cards, simple bot (playtest 1)
| Task | Owner | Agent-h |
|---|---|---|
| WS.L1 contracts + menu stub + owners rows + waves.md step | lead | 1 |
| WS.D2 UI layout spec (`ui-wave-strike.md`, M1 part) | ui-designer | 1.5 |
| WS.M1 lane template + spot kinds + Ashwind Reach `.map` / layout + catalog `mode` tag | four-wizards-high | 3 |
| WS.C1 `WaveStrikeLevel`, `WaveDirector`, `LaneSpawner`, `Bastion`, rules resource, win / time rules [H] | systems-coder-high | 4 |
| WS.C2 `WaveBank`, `MusterRoster` (cards, cap, sell; no ranks yet) | systems-coder | 2.5 |
| WS.G1 `LaneMarch` (waypoints, priority, leash, no-stall) [H] | gameplay-coder-high | 3.5 |
| WS.U1 buy panel (8 cards), top bar horn / income, lane strip with Bastion bars, lobby 1v1 | ui-coder | 3.5 |
| WS.A1 simple bot (weighted mix + Coffers, Normal only) | ai-coder | 2 |
| WS.T1 integration fixes, Perf Lab `ws150`, CI, playtest build | lead + fix agent | 2 |
| **M1 total** | 9 tasks | **~23 h** (1 long day) |
Done when: a 1v1 Fire vs Shadow match vs the bot ends by a Bastion kill in 12-25 min; tests 7.9 rows 1-4 + bot PASS;
`ws150` ≤ 16.7 ms; stuck 0.

### M2: full buy menu, ranks, armoury, towers, mercs, wizard, 2 maps, bots (playtest 2)
| Task | Owner | Agent-h |
|---|---|---|
| WS.C3 all 4 kingdoms' cards, tiers, ranks, armoury, champion card, titans, Crucible card | systems-coder | 4 |
| WS.C4 towers + slots + levels, barricades (taunt, no rebake), Relay Shrine, merc packs (`hire_pack`), Rally pulses, underdog | systems-coder | 4 |
| WS.G2 wizard leash + siege mult + horn XP; caster spell re-rules (4.4); champion `lane` intent hook | gameplay-coder | 3 |
| WS.A2 WaveBot personalities x5 + 4 difficulties + wizard brain + champion `lane` brain | ai-coder-high | 5 |
| WS.U2 full buy panel (tabs, ranks, sell), roster strip, enemy roster, lane toggle, shop, end-screen WS tab | ui-coder | 5 |
| WS.M2 Twin Ribbons (2 lanes, river ford) + map gate `-Mode wave_strike` | four-wizards-high | 3 |
| WS.L2 Unit Lab lane terrain + `-Wave` spec + card price pass (9.1) | lab owner | 3 |
| WS.L3 Bot Lab WS driver + first 16-pair batch (9.2) | lab owner | 3 |
| WS.P1 perf pass to `ws300` (LaneGrid, think stagger, avoidance gating, LOD) [H] | systems-coder-high + gameplay | 4 |
| WS.V1-V3 Bastion dressing x4 kingdoms, lane props, horn / Rally VFX | tech-artist (3 agents) | 4.5 |
| WS.S1 horns x4, Rally, UI cues (Audio Lab) | ui-coder (audio) | 1.5 |
| **M2 total** | 13 tasks | **~40 h** (2 days) |
Done when: all cards buyable; bots of every personality finish matches; 16-pair Bot Lab inside 40-60 % (first pass);
`ws300` PASS; both maps gate PASS / PARTIAL; UI Lab and Art Lab no FAIL.

### M3: team modes, polish, balance (playtest 3 = release candidate of the mode)
| Task | Owner | Agent-h |
|---|---|---|
| WS.C5 seats 2v2 / 3v3 / 4v4, shared Bastion, team slots, bounty split, ally assist, concede autopilot | systems-coder | 3.5 |
| WS.M3 Fourfold Causeway (4v4) + gate | four-wizards-high | 3 |
| WS.A3 ally / team bot rules (shared front, no double-buy of slots), Brutal | ai-coder | 2.5 |
| WS.U3 team lobby (2-8 seats), ally pings reuse, observer mode (free cam, all rosters, x1-x4), Gauntlet screen | ui-coder | 4.5 |
| WS.P2 `ws600` pass (low detail auto, cap fallback) | systems-coder-high | 3 |
| WS.R1 Replay Lab WS commands + determinism test | lab owner | 2 |
| WS.B1 balance pass: Unit Lab matrix at 3 budgets → `card_prices.tres`; Bot Lab 16 pairs x 20 seeds → income / cap knobs; comeback check (4.10 target) | game-designer + lab runs | 5 |
| WS.D3 Practice hints + Unit Guide "Wave Strike" page + Gauntlet text | game-designer + ui-coder | 1.5 |
| WS.T3 full CI, Build Lab export, playtest notes | lead | 1.5 |
| **M3 total** | 9 tasks | **~27 h** (1.5 days) |

**Grand total: ~31 tasks, ~90 agent-hours** at Opus 5.5 medium (± 30 %), plus ~10-15 h of unattended lab compute
(Bot Lab / Unit Lab matrix runs on the laptop, which JS allows to run flat out). Calendar: **~4-5 working days** at
the current pace, M1 playable after day 1.

### Risks
| Risk | Likelihood | Mitigation |
|---|---|---|
| **Perf at 400-600 units** (today 200 units = 13 ms) | High | Measures 7.8 in order; supply cap valve; 4v4 ships only when `ws600` passes, else 3v3 is the biggest mode |
| `LayoutLevel` / `Skirmish` carry too many skirmish systems to switch off cleanly | Medium | WS.C1 first checks every feature flag; fallback: a slim `MatchBase` extracted from main.gd (lead, +4 h) |
| Units stall / conga on the lane (avoidance, flyers, big titans) | Medium | Lateral offsets, no-stall rule, stuck counter in every test and Bot Lab report |
| Balance: persistent cards snowball, or games stall at the middle | Medium | Flat income, cap, ranks over bodies, Rally, Last Horns; Bot Lab length + comeback metrics as gates |
| Caster autocast too strong / too weak without micro | Medium | Unit Lab C1-C7 re-run in `-Wave` mode; per-spell mode overrides in `WaveStrikeRules` |
| Champion brain does odd things in a lane | Low-Med | `lane` intent is the only intent in WS; R1-R9 rules except Explore / Hunt off |
| Scope creep (walls, Gauntlet, observer) | Medium | Cut order: barricades → Gauntlet → observer → 4v4 map |
| Contract churn with ongoing steps (2v2 seats, map tools) | Medium | Reuse the 2v2 seat model; only 4 new contracts, all additive |

---

## 9. Balance method (how the labs set the numbers)

### 9.1 Unit Lab: card prices and the counter table
- Add the lane terrain (Unit Lab next step 1: the arena with the lane width and a Bastion-less end) and a **wave spec**:
  `"wave": {"a_roster": [...], "b_roster": [...], "horns": 6}` = both rosters spawn at a 40 s rhythm, survivors carry
  over; score = front position + value traded after N horns.
- **Price pass**: the existing `-Matrix` at budgets **360 / 720 / 1440** (early / mid / late waves). For each card,
  `mode_mult = clamp(1 + 0.6 x (mean_score - 0.5), 0.8, 1.3)` averaged over the 3 budgets (score 70 % → x1.12).
  Support units (Rime Seer, Bloomtender) and casters are judged in their "+ line unit" entries, as the matrix does.
- The **counter table** (3 best counters / prey per unit) is exported to `data/wave_strike/counters.json` for the
  Tactician bot.

### 9.2 Bot Lab: fairness and pacing
- 16 kingdom pairs (mirrors included) x 20 seeds, Normal Tactician vs Normal Tactician, then Random personalities.
- Gates: every pair **45-55 %** (first pass 40-60 %); median length **18-25 min**; < 10 % of games reach the 30:00 rule;
  comeback target of 4.10; stuck 0.
- Knob order (one at a time, Balance Lab variants): base income → Coffer step → supply caps → Bastion HP → per-card
  `mode_mult`. Never change a `UnitType` for Wave Strike: the skirmish balance stays untouched.

---

## 10. How it fits plan v2 (`docs/plan/waves.md`)

- New entry **Step 22: Wave Strike (second mode)** after the current work in flight (map tools / map gate, Unit Lab,
  caster balance CU.D3) and **after the next playtest build**: it reuses those tools, so it should start once they are
  green.
- It **depends on**: step 20's seat model (for M3 team modes only), the Unit Lab (M2), map tools MT1-MT10 (M1).
  It does **not** depend on steps 14 (research), 15 (food), 17 (Grand Market), 18 / 18b (building levels, walls): it
  uses towers and walls as they are today and reads building levels only if present.
- **What it displaces** (≈ 4-5 working days): it takes the slot of **Step 15 Food and supply** (future, no spec yet;
  move it after Wave Strike) and pushes the "more skirmish maps" backlog item by the same days. Story Episode 2 work and
  balance passes of the main mode keep their place if JS prefers; then Wave Strike moves after them instead (the spec
  stands either way).
- **Side benefits to the main game**: the perf work for 300-600 units (LaneGrid, think staggering, avoidance gating,
  LOD) speeds up big skirmish / 2v2 battles; the Unit Lab lane terrain and wave spec, the price pass and the counter
  table feed the skirmish bots; the 4v4 seat work is the first real 4-seat runtime (`FOUR_SEAT_RUNTIME`).
- Main-mode rules are never changed by Wave Strike: all its numbers live in `WaveStrikeRules` / `card_prices.tres`.

---

## 11. Content checklist (nothing new to model, little to draw)
New art only: Bastion dressing (4 kingdoms; the Citadel keep + banners and a lane brazier), the Relay Shrine, gate pads,
ward-line runes, merc camp signposts, three map biomes from existing kits. New audio: 4 horns, Rally, supply-full.
New text: card tooltips are generated from `UnitGuideData` (no new JSON blocks: no new units), the lobby, hints, Gauntlet.

---

## 12. Alternatives considered

1. **A standalone game in a new repo** ("Four Wizards: Strike"). Clean code base and its own identity, but it forks or
   rebuilds units, combat, art, labs and tools; two repos to keep in sync, roughly 3-4x the effort. Loses: everything.
2. **A lane-push / MOBA-like mode** (each player controls only their wizard; creep waves are automatic and identical).
   Fun with our heroes and items, but it drops the buy-and-send core JS asked for and needs real hero balance (PvP MOBA).
3. **A faithful clone of the original's sending mechanics** (its exact building grid, spawn layout, numbers, names).
   Fastest to describe, but it breaks the project's "everything original" rule and does not use our kingdoms' identity.

**Why the recommendation wins**: it is the genre JS asked for (buy, send, watch waves fight, win by the base), built
from parts that already exist and are balanced and tested, so most effort goes to rules, UI and bots; it keeps the
wizard and kingdom identity; it is original by construction; and its perf and lab work pays back into the main game.


---

## 13. M1 as built (2026-10-06)

**Plays**: main menu > **Wave Strike** (lobby: Ashwind Reach preview, your kingdom Fire / Shadow (all 4 + the enemy
kingdom since 13.2), bot Steward / Hammer, Start). 1v1 vs the WaveBot on Ashwind Reach; F9 / Restart keep the choices.

| M1 item | Built | Files |
|---|---|---|
| Map "Ashwind Reach" | `.map` hand-written, World Forge `map` PASS quality 100, **Map Lab WARN 97 / 0 FAIL** (14 N3 WARNs = navmesh on top of the forest blocks), spacing L3 PASS, lobby preview (mapsheet). **192 x 96 m, lane 40 m wide, 144 m gate to gate** (not 280 x 100: Map Lab R5 caps a map side at 192 m; a longer lane needs a bend, M2) | `data/maps/ashwind_reach.map`, `_layout.tres`, `previews/ashwind_reach.png`, catalog entry `mode: "wave_strike"` |
| `LaneMarch` | waypoints (5 m / past-the-plane advance), lateral offsets (+-8 m), units-first auto-aggro + the Bastion at the lane's end, leash 12 m melee / 6 m ranged (1.5 s walk back, no aggro), no-stall (2 s idle = re-issue, 4 s stuck = 2 m side-step), `stall_events` counter (10 s) | `scripts/units/lane_march.gd` |
| `WaveStrikeRules` | every M1 number of section 6 (+ ranks, Last Horns armour) | `scripts/world/wave_strike/wave_strike_rules.gd`, `data/wave_strike/rules_default.tres` |
| Card prices from data | `WaveCardTable`: cards per kingdom + `mode_mult` (default 1.0) + `price_override`; re-price from the Unit Lab here, never in `data/units/` | `wave_card_table.gd`, `data/wave_strike/card_prices.tres` |
| Level | `WaveStrikeLevel` on **main.gd** (the "slim base" fallback of section 8: Skirmish / LayoutLevel would need workers, nodes, taverns, trade, map fill, tiers and the "no living building" defeat switched off); reads the MapLayout (keep = Bastion, start, `slot sub=gate`, `path lane_a`); forest blocks drawn as trees; full vision | `wave_strike_level.gd`, `scenes/wave_strike.tscn` |
| Horn director | first horn 0:30, every 40 s, 30 s from 24:00 (Last Horns, Bastion armour -25 %), income then spawns, buys join the next horn, `horn` / `horn_soon` signals | `wave_director.gd` |
| Lane spawners | 8 across the lane, rows behind, 0.15 s stagger, melee -> ranged -> casters | `lane_spawner.gd` |
| Bank and income | start 400, +100 per horn, Coffers 8 levels (+15, 150-500), bounty 12 % (x1.5 in the killer's own third), underdog tithe (+8 % per 15 % HP gap, max 24 %) | `wave_bank.gd` |
| Roster | cards, supply cap 24 / 40 / 56, buy, sell (100 % within 5 s, else 50 % with the pop locked until the horn), Stronghold 250 / 45 s / horn 6, **Citadel 450 / 60 s / horn 14**, **card ranks** (Drilled +60 % / Elite +100 % per copy: level 2 / 3 + "+" modifiers) | `muster_roster.gd` |
| Bastion | the kingdom keep at Citadel look and attack, HP x 2.5 (Fire / Shadow 8 750), armour 3; destroyed = defeat; 30:00 = higher HP % (then value killed) | `bastion.gd` |
| Buy panel + HUD | top strip (both Bastion bars, "Horn N in m:ss", clock, Last Horns), bank line, Muster panel (4 cards, Coffer, Stronghold / Citadel, next-wave size). Keys **Z X C V** cards, **Ctrl+** = rank up, **Alt+** / right-click = sell, **B** Coffer, **N** next tier (the buy keys win over the unit keys X / C: lane units take no orders; attack-move with A) | `scripts/ui/wave_strike/wave_strike_hud.gd` |
| Menu | main menu button + lobby page, `MenuFlow.start_wave_strike` | `wave_strike_lobby.gd`, `main_menu.gd`, `menu_flow.gd` |
| Wizard | **built (cheap)**: the kingdom wizard as a leashed avatar (cannot cross the Ward Line x = 0), +40 XP per horn, respawn 15 s + 2 s x level; bot wizards guard 24 m in front of their gate, autocast and learn spells. Not built: siege x0.75, shop rule, wizard kill bounty (M2) | `wave_strike_level.gd` |
| Bot | `WaveBot`, 2 personalities (steward: Coffers to 6 first, Stronghold horn 6, Citadel 14; hammer: cards first, 2 late Coffers, Stronghold 9, Citadel 17), fixed weight table per kingdom, >= 40 % melee pop, ranks the biggest line with leftovers, decides 3 s before each horn; labs jitter the weights +-20 % by seed | `scripts/ai/wave_bot.gd` |

Lane units are not commandable through a `commandable = false` copy of their UnitType (no `Unit.lane_owned` flag was
needed, so no Unit contract change).

**Not in M1 (M2)**: towers / tower slots (the slots are in the map), barricades, Relay Shrine, mercenaries, champion card,
titans, armoury, T3 cards, Ice / Nature cards, Rally pulses, wizard siege rule and shop, the lane strip / enemy roster
panels, ScoreKeeper weights, end-screen WS tab, horn sounds, Bastion dressing, team modes, map gate `-Mode wave_strike`.

**M1 tests and lab numbers (2026-10-06)**
- `tests/test_ws_director.gd` PASS: horn 1 at 30 s / every 40 s / +30 s after 24:00, income 100 (+15 per Coffer, Coffer
  prices), underdog tithe steps and cap, buys join the next horn, spawns = roster, cancel (100 %) / late sell (50 %, pop
  locked to the horn), cap 24 / 40, T2 gate, Stronghold horn 6 / 45 s, ranks (prices, Elite gate), spawn order, bot buys.
- `tests/test_ws_match.gd` (headless bot vs bot, sim mode): PASS, 0 script errors, 0 stalls; a 30-min match = ~6 min wall.
- `tests/test_ws_perf.gd` (headless, 200 lane units, models on, PC shared with 4 Balance Lab runs): march avg 11.4 ms,
  p95 14.7 ms; clash avg 10.4 ms, p95 12.8 ms. PASS (<= 16.7 ms). Same order as the 13 ms / 200 units baseline: the
  per-unit O(n^2) target scan (`Unit._find_nearest_enemy`) is the cost; spawning 200 units on one frame aligned their
  0.25 s scans (p95 50 ms) -> the 0.15 s spawn stagger matters. 300+ units need 7.8 measure 2 (LaneGrid / think stagger).
- Batch `tools\wave_strike\run_ws_batch.ps1 -Games 20` (hammer vs hammer, Fire west on even seeds):
  **seat split west 9 / east 11** (fair), **kingdom split Fire 19 / Shadow 1** (Fire's cards are too strong for their
  price: the first `mode_mult` pass should raise Fire / lower Shadow), 18 Bastion kills + 2 on time, **median 27.9 min**
  (above the 12-25 target: ends come in Last Horns; knobs: Bastion HP mult, Citadel / rank timing), peak 206 lane units.
  Scorecard: `docs/tools/wave_strike/batch_m1_hammer/summary.md`. Shots: `docs/tools/wave_strike/shots/`.

### 13.1 Balance pass (2026-10-06, after M1)

Batches: `tools\wave_strike\run_ws_batch.ps1 -Kingdoms fire,shadow,ice,nature -SeedsPerPair 2` = the 12 ordered pairs
(every matchup on both seats), hammer vs hammer, wizards on; scorecards in `docs/tools/wave_strike/balance_2026-10-06/`.
New batch options: `-Kingdoms`, `-SeedsPerPair`, `-Mirrors`, `-Rules "field=v;..."` (WaveStrikeRules in memory),
`-Cards res://...tres` (a candidate price table); `test_ws_match` gains `--east=`, `--rule.<field>=`, `--cards=` and
writes a per-minute `timeline` (Bastion HP %, alive per side, front x) plus `wizard_casts` / `wizard_deaths` per seat.

**What changed**
| Change | Where | Why |
|---|---|---|
| **Ice and Nature cards** (4 per kingdom: line, archer, rider, T2) so the batches cover all 4 kingdoms; Shadow's set is now shade, bleakbow, **gloam_rider** (was grave_hound), hollow_oathsworn; Ice rimeshield, shardcaster, snowdrift_rider, hoarlight_magebow; Nature bramblehorn, wildwood_archer, stagrunner, greenheart_oathkeeper. Bot mixes follow (4 / 3 / 2 / 3) | `data/wave_strike/card_prices.tres`, `wave_bot.gd` MIX, `wave_strike_level.gd` KINGDOMS | the lobby still offers Fire / Shadow only (UI) |
| **Card prices derived from the Unit Lab matrices** (reproducible): `tools/wave_strike/reprice_cards.gd` | `card_prices.tres` `mode_mult` | JS: prices from the matrix now that unit balance is good |
| **Last Horns at 15:00, every 20 s** (was 24:00 / 30 s); **Bastion HP x2.0** (was x2.5: Fire / Shadow 7 000) | `rules_default.tres`, `wave_strike_rules.gd` defaults | median 27.9 min -> 19.6 |
| **Bot wizards cast**: Vessa (any seat) and the autopilot seat 0 never cast (the wizard scripts' own AI runs only for `team != PLAYER`, and Vessa has none). The level now casts for them every 0.5 s (`SpellCaster.suggest_cast`, Vessa: `AICasts.suggest_vessa` without the engage dive) | `wave_strike_level.gd` `_cast_for_bot_wizards` | **the seat bias** (east won 49 of 72 games in b0-b2; mirror test without wizards was even) and a spell-less Fire bot in real games |
| Playtest Recorder hook: `ReplayHooks.start_playtest(level, "wave_strike")` when Settings "Playtest data" is on (never under autopilot) | `wave_strike_level.gd` | health-and-playtests.md |
| Perf: `Unit._find_nearest_enemy` does the cheap typed checks and the squared distance first (same result) | `scripts/units/unit.gd` | see the perf row below |

**The price formula** (`reprice_cards.gd`, defaults = the shipped table): per card and per matrix basis b (equal crystals
`final_matrix_t1t2`, equal pop `_pop`, both `_both`), `rel_b = score_b - mean(score_b of the card's ROLE) + 0.5` (role =
melee / ranged by attack range: the matrix is head-on, archers lose by construction), `s = 0.25 rel_crystals + 0.5 rel_pop
+ 0.25 rel_both`, `mode_mult = clamp(1 + 1.2 (s - 0.5), 0.75, 1.35)`, price = cost x mode_mult rounded to 5. Pop weighs
most because the mode is supply-capped (every bot sits at 56 / 56 from ~11:00). The tool also prints a **kingdom index**
(the bot-mix-weighted raw score): the POP index predicted the first batch's order (Ice 71 / Fire 62 / Shadow 54 / Nature 39
-> 92 / 58 / 25 / 25 % wins), which is why the card SETS were re-chosen (index now 60-64 for all four).
| Card | mult | price | Card | mult | price |
|---|---|---|---|---|---|
| flame_guard | 1.08 | 95 | shade | 1.09 | 85 |
| ember_archer | 0.92 | 90 | bleakbow | 0.90 | 105 |
| blaze_rider | 1.05 | 190 | gloam_rider | 1.08 | 200 |
| cinder_arbalest | 1.31 | 175 | hollow_oathsworn | 0.92 | 165 |
| rimeshield | 1.27 | 120 | bramblehorn | 1.25 | 250 |
| shardcaster | 0.93 | 100 | wildwood_archer | 0.82 | 70 |
| snowdrift_rider | 1.14 | 195 | stagrunner | 0.79 | 125 |
| hoarlight_magebow | 1.18 | 110 | greenheart_oathkeeper | 1.16 | 195 |
Full table: `docs/tools/wave_strike/balance_2026-10-06/prices/card_prices_table.md`.

**Before / after** (24 games each unless noted; kingdom = wins / games)
| Batch | Fire | Shadow | Ice | Nature | Seat W / E | Median | Time rule | Peak units |
|---|---|---|---|---|---|---|---|---|
| M1 (20 games, Fire vs Shadow only, M1 prices) | 19 / 20 | 1 / 20 | - | - | 9 / 11 | 27.9 min | 10 % | 206 |
| b0 baseline (prices 1.0, M1 rules) | 7 / 12 | 3 / 12 | 11 / 12 | 3 / 12 | 7 / 17 | 27.9 min | 25 % | 248 |
| b1 matrix prices + Last Horns 16:00 + Bastion x2.0 | 10 / 12 | 1 / 12 | 9 / 12 | 4 / 12 | 9 / 15 | 21.2 min | 4 % | 219 |
| b2 b1 + new card sets | 4 / 12 | 4 / 12 | 7 / 12 | 9 / 12 | 7 / 17 | 21.8 min | 8 % | 251 |
| b3 b2 + wizard cast fix (stopped after 5 games) | | | | | 0 / 5 | 30 min (4 of 5 on time) | 80 % | |
| **b4 final** (b3 + Last Horns 15:00 / 20 s; 22 games) | **10 / 11** | **1 / 10** | **2 / 11** | **9 / 12** | **10 / 12** | **19.6 min** (18.2-22.8) | **0 %** | **404** |
Every batch: 0 stalls, 0 script errors. Mirror check (12 min, 4 games): without wizards 2 / 2 by seat; with the cast fix
Fire / Ice mirrors 3 / 1, casts per seat 52/44, 46/39, 51/56, 41/52 (both seats cast alike).

**Reading.** Pacing and seat fairness are fixed. Kingdom balance is NOT: with every wizard casting, **Fire wins 10 / 11**
(Vessa's Fireball on the clustered waves + cinder arbalest) and **Shadow 1 / 10**. Card prices barely move it: both bots are
at the 56 supply cap from ~11:00 with all 8 Coffers, so crystals stop binding and prices only change the early fill and
how fast ranks come. Next levers, in order: (1) a per-card **supply** override (pop is the real price in a capped mode;
half-pop steps need the cap table doubled), (2) the wizard: Vessa's AoE in a 40 m lane (a WS spell-power or cooldown rule,
4.4 "re-ruled" spells), (3) Shadow's set (hollow_oathsworn -> barrow_knight raises its pop index 60 -> 62).
**Perf watch**: 20 s Last Horns push the peak to 290-404 lane units in the last 1-2 minutes (over the `ws300` budget in
half the games); if the Perf Lab confirms, use the cap valve of 7.8 (7) or 25 s horns.

**Perf** (`test_ws_perf`, 200 lane units, headless, models on): the M1 p95 ~18 ms (march 18.04, clash 18.41) was NOT
thermal: the same on a quiet PC. Profile: each 0.25 s target scan cost ~300 us (`Unit._find_nearest_enemy`: Variant
`get(&"team")` in `is_enemy_of` and `global_position` per candidate before any distance check), ~13 scans a frame = ~4 ms.
Reordered (typed team / dead checks and squared distance first): 300 -> 48 us per scan; **march p95 18.0 -> 12.0 ms,
clash 18.4 -> 12.4 ms** (quiet PC); 14.4 / 14.0 ms with the new Shadow set while 4 other Godot runs were going. PASS.
Avoidance (RVO, ~5 ms) and the model kits (~2 ms) are the next costs; `neighbor_distance` / `max_neighbors` did nothing.

### 13.2 Balance pass 2 (2026-10-06/07): wizard re-rules, per-card supply, field cap, 4 kingdoms in the lobby

Batches: `tools\wave_strike\run_ws_batch.ps1 -Kingdoms fire,shadow,ice,nature -SeedsPerPair 1|2` (the 12 ordered pairs,
hammer vs hammer, wizards on), scorecards in `docs/tools/wave_strike/balance2_2026-10-06/`. The target "every kingdom
20-35 %" is read as **its share of all decided games** (25 % = even; 4 kingdoms, no mirrors), the seat split 40-60 %.
New batch / test knobs: `-Extra "pop.<card>=N;kcards.<kingdom>=a,b,c,d;wizards=0"`, `--rule.<dict>.<key>[.<stat>]=N`
(Dictionary rules), the summary prints the win share and the units held by the field cap.

**What changed**
| Change | Where | Why |
|---|---|---|
| **Per-card supply**: `WaveCardTable.pop_override` + `pop(id)`; `MusterRoster.pop_of` and the WaveBot read it. Data: cinder_arbalest **2** (was 1: the best ranged card per pop by far, pop index 76 vs ranged mean 33), barrow_knight **2** (was 3) | `wave_card_table.gd`, `card_prices.tres`, `muster_roster.gd`, `wave_bot.gd` | pop is the real price in a capped mode (13.1) |
| **Shadow set**: shade, **nightbolt** (was bleakbow: 6.2 -> 7.7 dps), gloam_rider, **barrow_knight** (was hollow_oathsworn; T2). Bot mix shade 4 / nightbolt 3 / gloam 2 / barrow 3 | `card_prices.tres`, `wave_bot.gd` MIX | Shadow won 0 of 24 with wizards in batches a-b |
| **Wizard re-rule** (4.4 "re-ruled" spells): `WaveStrikeRules.wizard_spell_power` (kingdom -> flat spell_power) and `wizard_stats` (kingdom -> any stat modifier), applied as the wizard modifier `ws_rule`. Data: **Fire** spell power -20; **Nature** -80, mana regen -60 %; **Ice** +60, mana regen +30 %; **Shadow** +30, max HP +30 % | `wave_strike_rules.gd`, `wave_strike_level.gd` `_apply_wizard_rule`, `rules_default.tres` | see "Reading" |
| **One Bastion HP** for every kingdom: `bastion_base_hp` 2 500 (the keeps differ: Ice 3 000, Nature 2 250), `bastion_hp_mult` 2.0 -> **1.6** | `bastion.gd`, rules | fairness; length |
| **Field cap** (the perf valve of 7.8 (7)): `field_cap` **150** living lane units per seat; a horn's copies past it stay home that horn (`stats.held`). So at most 300 on the field in a 1v1 | `wave_strike_level.gd` `spawn_lane_unit` / `field_count`, rules | peaks of 290-404 in 13.1 |
| **Last Horns at 14:00** (was 15:00), still every 20 s | rules | the field cap lengthened the games (median 22-23 min) |
| **Autopilot wizard retreat**: the level's cast loop (seat 0 under autopilot, and Vessa on any seat) now walks the wizard home on a "retreat" rule, like the wizards' own loops do on the bot seat | `wave_strike_level.gd` `_cast_for_bot_wizards` | lab seat bias: in batches f-i the east seat won 61 % (Malrik / Torvald / Ysolde never retreated on the west seat) |
| **Lobby: all 4 kingdoms** (Fire / Ice / Nature / Shadow with their wizards) + **Enemy kingdom** (Random = another kingdom, or one of the 4; F9 / Restart keep the drawn matchup); French via `Loc.t` + `data/i18n/fr/ui_wave_strike.po` | `wave_strike_lobby.gd`, `menu_flow.gd` (`ws_enemy_kingdom`, `ws_enemy_resolved`, `resolve_ws_enemy`) | 13.1 open issue |

**Reading.** A no-wizard batch (`diag_nowiz_cards`, same cards) was already fair: Fire 17 / Ice 25 / Nature 25 / Shadow
33 % of the wins, median 18.8 min. So the kingdom spread of 13.1 came from the **wizards**, not the cards: Vessa
(Fireball every 3 s on bunched waves **and Kindle**: +43 % attack speed to every soldier near her, which spell power does
not touch, hence the mana-regen cut) and Ysolde (Thornburst + Call the Thicket) won their home fights; Malrik
(single-target Lance, often dead: 9-12 deaths a game) and Torvald lost them. Spell power alone (Fire -70) did not stop
Fire (batch e). Batches f-i were also seat-biased by the autopilot wizards not retreating (above); once fixed (j) the Fire
nerf was too big and was eased to spell power -20 with no mana cut (k). Card prices still barely matter late (everyone
sits at the cap with 8 Coffers). A 12-game batch gives each kingdom 6 games: one game moves a share by ~8 points, so
every step was confirmed on 24 games (h-k).

**Batches** (kingdom = share of all wins; 12 games unless noted)
| Batch | Fire | Ice | Nature | Shadow | Seat W / E | Median | Peak units |
|---|---|---|---|---|---|---|---|
| 13.1 b4 (before) | 10 / 11 won | 2 / 11 | 9 / 12 | 1 / 10 | 10 / 12 | 19.6 | 404 |
| a: Fire sp -40, Nature -30, arbalest pop 2, field cap 145 | 17 % | 33 % | 50 % | 0 % | 6 / 6 | 22.1 | 200 |
| b: + Shadow T2 barrow, Shadow +25, Nature -50, Fire -25 | 42 % | 17 % | 42 % | 0 % | 5 / 7 | 23.1 | 205 |
| c: + nightbolt, barrow pop 2, Fire -40, Nature -70, cap 150 | 42 % | 17 % | 25 % | 17 % | 6 / 6 | 22.5 | 210 |
| d: + one Bastion HP, Fire -60, Ice +20, Bastion x1.8 | 33 % | 25 % | 42 % | 0 % | 8 / 4 | 20.7 | 203 |
| diag: no wizards | 17 % | 25 % | 25 % | 33 % | 5 / 7 | 18.8 | 200 |
| e: Fire -70, Nature -80, Shadow +50 / HP +30 % | 25 % | 8 % | 42 % | 25 % | 9 / 3 | 22.8 | 202 |
| f: + mana regen Fire -30 % / Nature -50 %, Ice +40, Bastion x1.6 | 17 % | 17 % | 33 % | 33 % | 6 / 6 | 22.5 | 203 |
| g: Fire -45 / -20 %, Ice +60, Last Horns 14:00 | 8 % | 33 % | 25 % | 33 % | 4 / 8 | 19.8 | 214 |
| h: shipped data v1 (Fire -40 / -20 %, Ice +50, Nature -60, Shadow +50), 24 games | 21 % | 12 % | 33 % | 33 % | 11 / 13 | 20.2 | 208 |
| i: Ice +60 / mana +30 %, Nature -65, Shadow +40, Fire -30 / -10 %, 24 games | 8 % | 29 % | 29 % | 33 % | 7 / 17 | 20.8 | 204 |
| j: i + the autopilot retreat fix, 24 games | 12 % | 21 % | 38 % | 29 % | 12 / 12 | 20.5 | 204 |
| **k: shipped data** (Fire -20, Nature -80 / mana -60 %, Ice +60 / +30 %, Shadow +30 / HP +30 %), 24 games | **25 %** | **21 %** | **25 %** | **29 %** | **13 / 11** | **20.5** | **207** |
Batch k (`k_final`): win rates Fire 6 / 12, Ice 5 / 12, Nature 6 / 12, Shadow 7 / 12; 22 Bastion kills + 2 on time (8 %);
0 stalls, 0 script errors; 5 083 copies held by the field cap over the 24 games (it binds for the winning side late).
Every target of the pass is met (each kingdom 20-35 % of the wins, seat 54 / 46, median 15-22 min, peak < 300).

**Perf** (`test_ws_perf -- --per-side=150` = both seats AT the field cap, 300 lane units, headless, models on, the
PC otherwise idle): march p95 **16.65 ms**, clash p95 17.7 ms (avg 12.8 / 13.3 ms), 0 stalls: PASS (the gate is the march
p95 <= 16.7 ms; it is at the edge, so 300 is the real 1v1 ceiling until LaneGrid / avoidance gating, 7.8 (2)-(3)). The
test now also checks the valve (one spawn past `field_cap` is refused). In real matches the field peaked at 200-214.
