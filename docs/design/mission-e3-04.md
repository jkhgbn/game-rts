# Campaign mission e3m4: "The Storm on the Ridge" (Malrik + Mother Hush, with Torvald, vs Old Vey and Vessa; Episode 3)

Written 2026-10-02 (`campaign-outline.md` 3.3 row 4). Episode 3 "The Gravedigger's Son", mission 4 of 4: the finale of
the Shadow episode. Three days after "Another Night", Malrik comes back from Duskbarrow (`mission-e3-03.md`) to the
Evenmead ridge, and Vessa, with Ysolde gone south with the villagers, throws everything she has left at it, led by
**Old Vey**, the Master's storm-sword. Vey is a **hero-boss who cannot die**: the player breaks his storm three times and
he withdraws. Malrik wins the field; Torvald hears the stone speak his own name. Ends on `ep3_ending` "I Will Not Stop".
2v2: Malrik (player) and Torvald (allied Ice bot) on the north ridge against Vessa (Fire bot) and the scripted Vey.
Unlocks the Shadow titan, the **Nightmare Knight**. Target **24-30 min** on normal. Uses `mission-e3-01.md` (the Evenmead
Map table, binding; standards, the 2v2 frame), `mission-04.md` and `mission-00.md` (Old Vey's kit lines, the "cannot die"
kneel), `mission-e3-03.md` (the Shard's power and the stone's hold, unchanged), `t3-helpers.md` (Vey's and Hush's kits),
`cavalry-mounts.md` (Dread Paddock, Nightmare Knight), `tiers.md` 6, `caster-units.md` 5.4 and the format of
`mission-01.md`. New scene `missions/mission_e3_04.tscn` + `scripts/campaign/mission_e3_04.gd` (`MissionE304 extends
MissionBase`, mission id `e3m4`). Metres, seconds, `m:ss` of `mission_time()`; positions `(x, z)`, `+z` = south (the
`forge_evenmead` frame). Status: **design only**; nothing here is built. Recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | **`data/maps/evenmead.map`** (e3m1's table unchanged), daylight, "after the battle" dressing: trampled meadow, blackened fords, the spoiled wagons on Lark Hill, the Nature camp struck (no Heartwood, no Grove Hall) | The outline: "Evenmead ridge, after the battle". Ysolde left with the villagers at the end of e3m2 (L26) |
| D2 | What the player holds | **Three ridge watch points** on the north bank (`CapturePoint` kind `&"standard"` of e3m1): the Bishop's Crest, Reed Watch, Birch Watch, owned by side 0 at 0:00. The ridge falls (defeat) if side 1 holds **all three for 30 s** | "Hold 3 points" (outline). Losing one or two is a setback, not a loss, so the fight can swing |
| D3 | Old Vey | **Hero-boss `vey_storm`** (team ENEMY, scripted): the `helper_vey` model in the `m4` look, story numbers. At 0 HP his **storm breaks**: he kneels 3 s, a bolt carries him to Lark Hill's crest, he rests 75 s and comes back with the next assault. **Three breaks = he withdraws = victory** | "He cannot die" (outline). He is the Master's sword and Ep8's living cast; breaking, not killing, is also kinder to Vessa's story (Ep4 follows) |
| D4 | Assaults | Three scripted assaults (5:30, 13:00, 20:00, or 75 s after the previous break if later), each led by Vey and Vessa through more fords; Fire raids between them; the bots never launch their own | The M4 / e3m1 rhythm: scripted pressure on a timer, the bot only defends |
| D5 | The titan | **Nightmare Knight** (`cavalry-mounts.md` 3, 400 crystals, pop 4, 50 s) from the **Dread Paddock** (Shadow Lair, 300, 70 s), allowed from **4:00** in this mission (the skirmish floor is 8:00) | The Knight's charge is the intended answer to a fast melee boss who lunges; it must exist for the second assault |
| D6 | Start tier and Hush | The Dusk Keep is a **Citadel** at 0:00 (e3m2); **Mother Hush on the field at 0:00** (alive, Escort, Malrik's level); revive at the skirmish price | Both were earned in e3m2-e3m3; the finale should not re-teach them |
| D7 | The stone | The Shard's power and **the stone's hold** exactly as `mission-e3-03.md` (fresh meter at 0 %). New: **Torvald reacts** (L16) and the second break plays `e3m4_whisper`, where the stone speaks **aloud** for the first time | Outline: "Torvald sees the stone whisper" (the seed of Ep7's turn) |
| D8 | Nature | **Absent** (no Ysolde, no Nature base). The Fire bot alone holds the south; the old standards at the foot are Fire-owned decor | Vessa fights "with everything she has left"; Ysolde's road is Ep4's `e4m2` |
| D9 | Torvald | Ally bot (`mission_e3_04_ally`, Supportive, **16 pop**) who **holds Birch Watch** by default, answers pings, and returns to Birch Watch 60 s after a ping | A 2v2 ally with a job; the player owns two watches, he owns one |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e3_doubt`)
1. Three days Malrik spent laying his dead back down in Duskbarrow. Three evenings an old man with a burning sword
   walked down to the river and looked at Torvald's winter on the ridge, and walked away again.
2. Ysolde has taken her people south, out of the war. Vessa has stayed, with every soldier she has left and the one ally
   who has never lost a duel: Old Vey, the Master's storm-sword. Today they cross.
3. Hold the ridge. You cannot kill a storm, but you can wear one out. And Torvald is watching the stone in your pocket
   more closely than he watches the river.
Briefing objectives: `obj_storm`, `obj_ridge`, `obj_malrik`, and the line `Old Vey cannot die. Break his storm three
times and he will leave the field.`

## Map: "Evenmead, after the battle" (`data/maps/evenmead.map`, 150 x 120; e3m1's Map table + the changes below)
Daylight: the golden preset of e3m1 at mid-afternoon (`preset_golden` without the dusk ramp). Dressing: trampled-grass
decals along the three ford tracks, scorched fords, the four spoiled wagons of e3m2 on Lark Hill (decor), the Nature
pavilions struck (empty tent frames at `(-32, 48)` and `(-44, 40)`: decor, no buildings), a storm-cloud card that grows
over Lark Hill before each assault (19.V25 storm layer, cosmetic). The river, fords, nodes, the north bases, the Fire base
and the golden tree are e3m1's.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Malrik) / Hush | `(-6, -40)` / `(-4, -41)` | - | At the Dusk Keep door |
| **Dusk Keep** (player, Citadel) | `(-12, -48)` | 16 | Tier 3 at 0:00 (3 500 HP, attack 20) |
| Gloom Hall / Hovels / Night Spire (pre-built) | `(1, -48)` / `(-14, -38)`, `(-24, -52)` / `(-8, -32)` | - | Hovels as e3m2; the Night Spire covers the crest's west side |
| Dread Paddock spot (suggested) | `(-28, -44)` | - | 3 x 3; 9 m from node `e3_dusk_a`; any legal spot works |
| **Watch point W1 "Bishop's Crest"** | `(0, -36)` (`crest_n`) | 5 | `CapturePoint` `&"standard"`, r 6; 36 m from Stone Ford |
| **Watch point W2 "Reed Watch"** | `(-34, -22)` | 5 | r 6; 21.5 m from Reed Ford; 12.8 m from node `e3_reedfield` |
| **Watch point W3 "Birch Watch"** | `(40, -22)` | 5 | r 6; 22.4 m from Birch Ford; Torvald's post |
| Shadow rally / Ice rally | `(-4, -28)` / `(35, -28)` | - | As e3m1 |
| Torvald's Rime Keep / Rime Hall | `(28, -48)` / `(16, -45)` | as e3m1 | Stronghold |
| Fire Keep / Ember Hall / 2 Hearths | `(20, 50)` / `(32, 42)` / the bot's own e3m1 slots | as e3m1 | Vessa's base, Stronghold; the Ember Spires on the crest `(6, 31)`, `(20, 34)` stand; the Bramble Spires are gone |
| **Vey's rest** | Lark Hill crest `(-4, 34.8)` (`crest_s`) | - | Where each break carries him |
| Fire rally | `(12, 26)` | - | The bot's defenders |
| Assault spawns | West column: Reed Ford south bank `(-44, 8)`; centre: Stone Ford south landing `(6, 8)`; east: Birch Ford south bank `(50, 8)` | - | Scripted units appear at the Ember Hall and walk there first (their path is visible) |
Distances (path): Dusk Keep -> W1 15 m, -> W2 33 m, -> W3 58 m; W1 -> W2 37 m, W1 -> W3 42 m; each ford -> its watch
point 21-36 m. Crossing still slows (`terrain:ford` -0.35); no bridge. Fog: the fords, the watch points and Lark Hill's
crest explored for everyone from 0:00.

**Watch points** (`CapturePoint` `&"standard"`, e3m1 rules): radius 6, capture 12 s, x 1.25 for side 1 on this bank
(15 s), rate up to x 1.75 with more units, neutralise first, contested = frozen, decay 10 % / s when abandoned. Owner
effect: `SightMarker` 14. Side 0 (Malrik + Torvald) owns all three at 0:00. **The ridge falls**: side 1 owns all three
at once -> a 30 s countdown (`The ridge is falling: retake a watch point! 0:30`, red); any watch point back to neutral
or side 0 stops it (it restarts from 30 s next time).

## Start state (Malrik's track)
Order in `_on_navigation_ready`: spawn Malrik -> `apply_to_start` -> Hush -> props.
| Item | Value |
|---|---|
| Malrik | **Level 6** (Lance r2, Siphon r2, Shroud r1, **1 unspent point**), **cap 8**; Keystone Shard in slot 1 (power on J), slot 2 empty |
| Items / essence | The 6 slots from the save; essence **150** + carried (50 %, cap 1 500, + the e3m3 bonuses); +1 / s |
| Crystals | **450** (easy 600, hard 350) |
| Buildings | Dusk Keep (Citadel), Gloom Hall, 2 Hovels, Night Spire, all complete |
| Units | 7 Gloom Thralls (4 on `e3_dusk_a`, 3 on `e3_dusk_b`); at `(-4, -28)`: **6 Shades, 3 Nightbolts, 2 Shadow Knights, 2 Hexweavers, 1 Gloom Deacon, 2 Nightblood Reavers** (2 220 crystals of army) |
| Mother Hush | `helper_hush` at L6 (x 1.20: 695 HP, 39 damage, Night of Knives on), Escort, beside Malrik |
| Population | 7 + 6 + 3 + 6 + 2 + 2 + 6 + Hush 4 = **36 / 60** (keep 20 + 2 Hovels; Hovels max 4 = cap 100) |
| Torvald (ally bot, Ice) | **Level 6** (Rime Bolt r2, Flash Freeze r2, Rime Aegis r1); Rime Keep (Stronghold), Rime Hall, 5 Rime Haulers; **5 Rimeshields, 3 Shardcasters, 1 Frost Mortar, 1 Rimecarver** at Birch Watch (16 pop, ~1 300) |
| Vessa (enemy bot, Fire) | **Level 6** (Fireball r2, Ember Step r2, Kindle r1) at the Fire rally; Fire Keep (Stronghold), Ember Hall, 2 Hearths, 6 Cinder Hands; **8 Flame Guards + 4 Ember Archers** at the rally (defenders, not the assaults) |
| Old Vey | Off the field until A1 (he arrives by lightning on Lark Hill's crest at 5:30) |
| Stone's hold | **0 %** (fresh), shown from 0:00 |
| Off | Tavern, trade, camps, beasts, wells / shrines, research, STR / INT (J is the Shard), Bazaar |
| No save / e3m3 not won | Shard equipped, 6 empty slots, essence 150 + **900**, `shadow_stone_uses` 0 |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hovel, Gloom Hall, Night Spire, **Dread Paddock** (worker build menu, from **4:00**: `"Not yet (4:00)"` before) | Gloom Stables, Bazaar, research |
| Units | Everything of e3m3 + **Nightmare Knight** (Dread Paddock Z: 400, pop 4, 50 s; `cavalry-mounts.md` 3 numbers, Charge after a 6 m run: +90, knockback 3 m, `dazed` 0.6 s) | Barrow Giant, Mage Archer (skirmish only) |
| Keep | Citadel; V Revive Mother Hush (skirmish price) | - |
| Spells | Shadow Lance, Soul Siphon, Umbral Shroud; cap L8 | - |
| Artifact power | Heart of the Hollow (J), the stone's hold (e3m3 rules) | - |
| Items | Base shop (Dusk Keep, Gloom Halls) | - |

## Old Vey, the storm on the ridge (`vey_storm`, hero-boss; gameplay, reusing `helper_vey` code, 19.C11 numbers raised)
Team ENEMY, groups `"units"` + `"boss"`, titan tags (CC half, taunt and knockback immune; a Knight's Charge still deals
its +90 and dazes 0.3 s), not commandable, never counts for victory, `AIStoryCaster` brain (below). Speaker `vey`.
| Stat | Storm 1 | Storm 2 | Storm 3 |
|---|---|---|---|
| HP (per storm, refilled at each return) | **3 600** | 3 600 | 3 600 |
| Damage bonus | - | +10 % | +20 % |
| Armor / speed / sight | 25 / 5.0 / 14 | same | same |
| Stormcall cooldown | 45 s | 45 s | **35 s** |
| Thunderhead | off | **on** | on |
| Ability | Rule |
|---|---|
| **Thunder-edged Blade** (attack) | 40 melee, range 2.0, cooldown 1.2; every 3rd strike chains to 2 enemies within 5 m for 25 |
| **Lightning Lunge** | Every 12 s: dash up to 10 m to an enemy hero, caster or ranged unit (Malrik first if within 10 m): **80** to it, **40** + `dazed` 0.5 s to each enemy on the path |
| **Chain Lightning** | Every 9 s: 5 jumps within 8 m: **55, 47, 40, 34, 29** |
| **Charged Ground** (aura) | r 10: own Fire units `attack_cooldown_pct` -0.15 (`aura:charged`) |
| **Stormcall** | 8 bolts over 3 s on enemies within 12 m, **60** each, x 1.5 on titans (Nightmare Knights) |
| **Thunderhead** (storm 2-3) | Every 30 s: the side-0 watch point with the most side-0 units within 6 m (ties: W1) gets a black cloud and a crackling ring r 6 for **3 s** (telegraph), then **10 s** of bolts: **25 / s** to every side-0 unit inside (heroes too, not buildings). Forces the army off the point, which the Fire column then takes |
| **The spark first** (bond) | Each Vessa Fireball landing within 14 m of him takes 2 s off Chain Lightning (max once per 2 s) |
| **Storm Broken** | At 0 HP: kneels 3 s (invulnerable, untargetable, white-gold sparks pouring off the blade), message `Old Vey's storm breaks! He will be back.` (4 s), then a bolt carries him to Lark Hill's crest `(-4, 34.8)`; he rests **75 s** there (invulnerable, untargetable, visible, sitting on a stone) and returns with the next assault, or, if one is running, walks to its target. Each break: Malrik's team **+200 essence**, Malrik **+250 XP**, `obj_storm` +1 |
| **Withdraw** | The third break: E15, victory |
Brain (`AIStoryCaster`, Vey rules): follow his assault's column; Lunge at the threat to Vessa first (an enemy targeting her
within 10 m), else at Malrik, else a caster; Chain on clumps of 3+; Stormcall at 6+ enemies or a Knight within 8 m;
Thunderhead by the rule above. If his column is wiped and he still stands, he walks to the nearest Fire unit group; if
none, he goes back to the crest and waits for the next assault (no break counted).

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_storm` | Primary | `Break Old Vey's storm (0 / 3)` | Three breaks (E15) |
| `obj_ridge` | Primary, always shown | `Hold the ridge watch points (3 / 3)` (the count of side-0 points; the 30 s countdown when it reaches 0) | Fails when the countdown ends = defeat |
| `obj_malrik` | Primary, always shown | `Malrik must survive` | Fails = defeat |
| `sec_knight` | Secondary (appears at E3) | `Ride down the storm: hit Old Vey with a Nightmare Knight's charge` | A Nightmare Knight's Charge lands on Vey |
| `sec_refuse` | Secondary (from 0:00) | `Refuse the stone again: win without its power` | Victory with 0 uses; **failed** at the first use |
The Dusk Keep's fall is a defeat (win / lose table) without its own objective line (the e3m1 rule).

## Assaults, raids and the bots (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: team ENEMY, group `"scripted"`, spawned at the Ember Hall, walking to their ford, then attack-moving to
their watch point, then to the nearest side-0 unit within 20 m, refreshed every 4 s. Vessa (the bot's wizard) is lent to
each assault as listed and goes back to her rally after it.
| Wave | Trigger | Units | Route |
|---|---|---|---|
| Raids | Every **150 s** from 3:00 until E15 | 3 Blaze Riders (alternately Reed Ford and Birch Ford) | The nearest Shadow or Ice worker, then the nearest watch point |
| **A1 "First Storm"** | **5:30** | **Vey (storm 1)** + **Vessa** + 5 Flame Guards + 3 Ember Archers + 2 Blaze Riders (1 110) | Centre: Stone Ford -> W1 |
| **A2 "Second Storm"** | **13:00**, or 75 s after the first break if later | **Vey (storm 2)** with the west column: 4 Flame Guards + 2 Ember Archers + 2 Pyre Adepts + 1 Kilnwarden (970); **Vessa** with the east column: 3 Flame Guards + 2 Ember Archers + 2 Cinder Arbalests (740) | West: Reed Ford -> W2; East: Birch Ford -> W3 (the pincer) |
| **A3 "Last Storm"** | **20:00**, or 75 s after the second break if later | **Vey (storm 3)** with the centre: 4 Flame Guards + 2 Ash Hurlers + 2 Cinder Arbalests + 1 Kilnwarden (1 060); west: 4 Flame Guards + 2 Ember Archers + 1 Pyre Adept + 2 Blaze Riders (1 050); **Vessa (L7)** with the east: 3 Flame Guards + 2 Ember Archers + 1 Blaze Rider (650) | All three fords at once |
| Pull-back | An assault 6:00 old with Vey unbroken | Its survivors and Vey walk back to the Fire rally / the crest | The next assault keeps its clock (no break counted) |
| Withdraw | E15 | Every Fire unit and Vessa | Back to the Fire base; no fighting unless attacked |
If **Vey is broken** while his assault still has units, those units keep attacking (they do not flee); Vessa's
lines change (L11 / L24). A break **before** the next assault's clock only means he rests, then waits on the crest.
**Enemy bot** (`mission_e3_04_enemy`, Fire normal knobs): `min_attack_pop` 99 (no own attacks), workers 6, no expansion,
up to **12 soldiers** at its rally, `bots_upgrade = false`; rebuilds nothing of the crest.
**Ally bot Torvald** (`mission_e3_04_ally`, `ai-2v2.md` ally layer, Supportive): gathers, trains up to **16 pop**, holds
**Birch Watch** (attack-move to W3 whenever it is not there; hold position around `(40, -24)`), answers the player's
pings and goes back to W3 60 s after the ping ends; never steals the player's nodes. His wizard casts with the Ice rules.
At A3 he holds W3 with everything. Torvald dying is never a loss (60 s respawn, message `Torvald falls back to the
ridge`); his Rime Keep falling is never a loss (his army falls back to the Dusk Keep).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`c_e3_doubt` and the briefing played before.) Cutscene `e3m4_return` (HOLD 0:20); camera on Malrik; L1-L4; `obj_storm`, `obj_ridge`, `obj_malrik`, `sec_refuse` active; hint (10 s) `Hold the three watch points. Old Vey cannot die: break his storm three times and he will leave.` |
| E2 | 3:00 (first raid) | L5 |
| E3 | 4:00 | Dread Paddock unlocked; hint (12 s) `A Thrall can now raise a Dread Paddock (B menu): it trains the Nightmare Knight, a titan whose charge can break a storm.`; `sec_knight` active |
| E4 | 5:30 | A1; Vey's arrival on the crest (a white-gold bolt, the helper arrival set-piece, no camera move); L6 (L6b if `e3m2_alarms == 0`), L7, L8 |
| E5 | Vey within 12 m of Hush (first time) | L9-L10 |
| E6 | First break | L11-L12; `obj_storm` 1 / 3 |
| E7 | First Nightmare Knight trained | Hint (8 s) `Nightmare Knight: it charges after a 6 m run. Lunge as he likes, the old man can't stop a horse.` |
| E8 | First Thunderhead | L13; hint (8 s) `A storm cloud over a watch point: get off it for 10 s, then take it back.` |
| E9 | A2 launches | L14-L15 |
| E10 | First Heart of the Hollow within 30 m of Torvald | L16; `sec_refuse` failed (any use fails it, near Torvald or not) |
| E11 | Second break | World held; cutscene `e3m4_whisper` (PAUSE 0:15): L17-L19; `obj_storm` 2 / 3 |
| E12 | A3 launches | L20-L21 |
| E13 | A side-0 watch point lost (first time) | L22 |
| E14 | Side 1 holds all three | The 30 s ridge countdown (once per occurrence) |
| E15 | Third break | Withdraw; world held; cutscene `e3m4_field` (PAUSE 0:45): L23-L28; `Events.mission_ended(true)` 2 s after; save with `resume = &"ep3_ending"`; StoryFlow plays `ep3_ending` |
| E16 | Malrik dies | L29; defeat after 3 s |
| E17 | Dusk Keep destroyed | Defeat after 3 s (no line) |
| E18 | The ridge countdown ends | L30; `obj_ridge` failed; defeat after 3 s |
| E19 | Vessa dies (first time) | L31; she respawns at the Fire Keep after 60 s and rejoins the running assault or her rally |
| E20 | `sec_knight` done | L32 |

## Dialogue (32 lines; speaker colours: Malrik `(0.7, 0.3, 1.0)`, Hush `(0.60, 0.50, 0.75)`, Torvald `(0.55, 0.80, 1.00)`, Old Vey `(0.95, 0.95, 0.55)`, Vessa `(1.0, 0.45, 0.1)`, Obren `(1.0, 0.80, 0.25)`, Narrator `(0.9, 0.85, 0.7)`; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `malrik`, `hush`, `torvald`, `vey` (`torren` alias),
`vessa`, `obren` (alias of `whisper`). Every line <= 2 lines of the box.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Three days later. Malrik came back from Duskbarrow to a ridge that smelled of thunder. |
| L2 | E1 | torvald | Every dusk the old man walks down to the river and looks at us. Then he walks away. |
| L3 | E1 | malrik | Looks. Not crosses? |
| L4 | E1 | torvald | Not yet. I think he was waiting for you. He is polite like that. |
| L5 | E2 | hush | Riders at the reeds. Quick little sparks. |
| L6 | E4 | vey | Bishop! You sent your knife into my girl's camp twice now. I've come to return the favour. (6 s) |
| L6b | E4, `e3m2_alarms == 0` | vey | Bishop! Not one alarm, that night. Your knife is getting better. So am I. |
| L7 | E4 | malrik | Old man. They told me you were dead. I was almost sad. |
| L8 | E4 | vessa | He's not dead, he's LATE. There's a difference! |
| L9 | E5 | hush | Old man. You still owe me a night. |
| L10 | E5 | vey | And you still miss, knife-woman. Every single time. |
| L11 | E6 | vey | Hah! Good. Again! |
| L12 | E6 | malrik | He is laughing. Why is he laughing? |
| L13 | E8 | vey | Off my hill. Well. Your hill. For now. |
| L14 | E9 | vessa | Both fords, Vey! We pinch him! |
| L15 | E9 | vey | The spark first. Then the storm! (4 s) |
| L16 | E10 | torvald | Malrik. That light in your hand. It moved before you did. |
| L17 | E11 (`e3m4_whisper`) | obren | Torvald. Old frost. You feel it too. Join us, and nothing will ever melt. (6 s) |
| L18 | E11 (`e3m4_whisper`) | torvald | ...It knows my name. |
| L19 | E11 (`e3m4_whisper`) | malrik | It knows everyone's name. It is a stone with nothing else to do. |
| L20 | E12 | vey | Last storm I've got, Bishop. Let's see what you've got. |
| L21 | E12 | malrik | Everything, old man. I took it all. That is the whole secret. |
| L22 | E13 | torvald | They have a watch. Take it back, or the ridge goes with it. |
| L23 | E15 (`e3m4_field`) | vey | That's enough. My storm is borrowed, and I've spent the loan. |
| L24 | E15 (`e3m4_field`) | vessa | Vey! Get up! We're not done! |
| L25 | E15 (`e3m4_field`) | vey | We are today, girl. Today the ridge is his. |
| L26 | E15 (`e3m4_field`) | malrik | The ridge is mine. The valley next. I will not stop. |
| L27 | E15 (`e3m4_field`) | torvald | No. I don't think you can. (4 s) |
| L28 | E15 (`e3m4_field`) | narrator | The ridge fell to Shadow. Torvald had heard the stone say his name. He did not forget it. (6 s) |
| L29 | E16 | malrik | Struck down... by an old man's weather. |
| L30 | E18 | narrator | Fire and thunder took the ridge, and the Bishop's winter melted away. |
| L31 | E19 | vessa | Ow! Fine! Back in a minute! |
| L32 | E20 | malrik | Even thunder falls off a horse, old man. |
Old Vey's barks (Lunge `Duck.`, Stormcall, low HP) are the `helper_vey_<event>` hooks in the `vey` voice; Hush's are
hers. Echoes: L15 is Vey's motto (V1, M1, e2m1 L19); L21 is `ep3_opening` L6 ("So I took. That is the whole secret."); L26
closes `ep3_opening` L15 and e3m1 L23; L27 is the first crack of Torvald's turn (Ep7: "No. Not for now."); L17 shows the
stone wants Torvald too (Ep7's alliance cost); L10 answers M0 ("the knife that never misses").

## Cinematic hooks (ENGINE on the live scene unless marked; CinematicPlayer 19.C1; skippable; units frozen while they play)
| Id | When | Mode / length | Shots (camera, what we see) | Lines | End state (a skip leaves exactly this) |
|---|---|---|---|---|---|
| `c_e3_doubt` | Before the briefing | Stage film ~1:10 | Written by E3M3.D1 (beats in `mission-e3-03.md`) | - | Briefing |
| `e3m4_return` | E1 | HOLD 0:20 | 1) WIDE crane from the east bank (the `B14` mark): the trampled valley, black fords, the spoiled wagons on Lark Hill; 2) MS two-shot Torvald and Malrik at the Dusk Keep door, 3/4-left (east of the axis, the Ep3 rule) (L2-L4); 3) long lens south (the `N12` mark): on Lark Hill's crest a lone old figure sits on a stone with a long sword across his knees; a storm cloud forms above him | L1-L4 | Malrik and Hush at their start marks; mission clock 0:00 |
| Vey's arrival / breaks | E4, E6 | In-game set-pieces (no camera move): a white-gold bolt on the crest, he stands out of the flash (`t3-helpers.md` 10.2 Vey row); a break = kneel 3 s, sparks pour off the blade, a bolt lifts him away | Barks | - |
| `e3m4_whisper` | E11 | PAUSE 0:15 | 1) MS Vey kneeling, the bolt taking him (frozen at its first frame); 2) CU Malrik's coat: amber light through the cloth, a low voice that everyone can hear; 3) MS Torvald, 3/4-left, frost on his beard, turning his head toward the voice (the `N11` gesture of `ep3_opening`) | L17-L19 | Vey at the crest, resting 75 s; everything else where it was |
| `e3m4_field` | E15 | PAUSE 0:45 | 1) MS Vey on one knee in the trampled grass, the blade's runes going dark one by one; 2) Vessa runs to him (L24); he lays a hand on her shoulder (L25) and they walk back across the ford together, slowly; 3) WIDE from the crest: the Fire army withdrawing over all three fords; 4) MS Malrik on the Bishop's Crest, 3/4-left, the stone glowing in his hand (L26); 5) MS Torvald at Birch Watch, apart from his Rimeshields, looking at Malrik, not at the enemy (L27); 6) long lens across the valley: the golden tree, untouched; FADE_BLACK | L23-L28 | Victory 2 s later; save with `resume = &"ep3_ending"` |
| `ep3_ending` "I Will Not Stop" | After `e3m4_field` (StoryFlow) | Stage film 1:00 (`campaign-outline.md` 3.3) | Beats for its writer (E3M4.D1), on `forge_evenmead` at night: the ridge lit by Shadow torches; Hush lights them one by one, Malrik walks behind her pinching nothing; Torvald and Aldra by the Ice pavilion (Aldra: "You heard it." Torvald: "I heard it ask. I did not hear him say no."); Malrik alone on the crest, the stone whispering "Now the tree."; he closes his fist on it: "Tomorrow." Across the valley, one white-gold flicker on Lark Hill: the old man is still there. Malrik's voice-over closes the episode: "I have heard 'stop' all my life." (the `ep3_opening` L14 WAV reused) Title: `Episode 3 · The Gravedigger's Son · Complete` | - | Story menu: Episode 3 complete; the Episode 4 card |
Fallbacks: `e3m4_return` = camera on Malrik + L1-L4; `e3m4_whisper` = L17-L19 as dialogue with a 1 s amber pulse on
Malrik; `e3m4_field` = L23-L28 as dialogue over a slow camera pan to the crest, then victory; `ep3_ending` = the
campaign fallback card (ep1 7.4 pattern).

## Tiers, titans and the helper
| Item | Value |
|---|---|
| Code | `MissionE304._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`, **`titans_enabled = true`** (Lair only, no Barrow Giant / Mage Archer: the Dread Paddock card shows Z Nightmare Knight only); `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(3)`, **`lair_min_time = 240`** (the 8:00 floor lowered for this mission; a new export the systems owner adds if missing) |
| Dusk Keep card | Z Gloom Thrall · X empty · C Nightblood Reaver · V Revive Mother Hush (when fallen) · B Gloom Deacon · Set Rally r3c1 |
| Worker build menu | Hovel, Gloom Hall, Night Spire, **Dread Paddock** (greyed `Not yet (4:00)` before 4:00) |
| Dread Paddock card | Z Nightmare Knight (400, pop 4, 50 s) |
| Bots | Torvald and Vessa at the Stronghold, never upgrade, no titans; assaults are spawned, not trained |
Timing: Paddock 4:00 -> 5:10 (300 crystals), first Knight 6:00 at the earliest (400), realistically 7:00-8:00 after A1;
two Knights by A2 (13:00), three or four by A3 on a strong economy.

## Economy
| Item | Value |
|---|---|
| Start | 450 crystals, essence 150 + carried, 36 / 60 pop, 7 Thralls |
| Nodes | e3m1's: home 2 x 1 500 (`e3_dusk_a`, `e3_dusk_b`), west expansion `e3_ridge_w` 2 000 (raided via Reed Ford), the rich `e3_reedfield` 2 500 north of the river (12.8 m from W2: the west fights happen on it) |
| Expected income (normal) | ~10 Thralls by 5:00; ~5 000 crystals mined by 24:00 (the home nodes dry around 17:00) |
| Essence (expected by 24:00) | 150 + carried (~1 000) + trickle ~1 400 + kills ~1 800 + 3 breaks x 200 = **~4 900**: one or two tops for Malrik (suggested: a defence item for Vey's Lunge, then Gravemaw Idol) |
| The spend | Dread Paddock 300 + 2-4 Knights (800-1 600), Reavers vs Fire's line, a second Deacon; Hush revives (~240 essence each) |

## Win / lose
| Event | Result |
|---|---|
| Third break of Vey's storm | **Victory** (after `e3m4_field`; then `ep3_ending`) |
| Malrik dies | **Defeat** (instant loss) |
| Dusk Keep destroyed | **Defeat** |
| Side 1 holds all three watch points for 30 s | **Defeat** |
| Torvald dies / his keep falls | Nothing (respawn 60 s; his army falls back) |
| Hush falls | Nothing; revive at the keep |
| Vessa dies | Not a win; L31; 60 s respawn |
| The Fire Keep destroyed | Allowed, not needed: `Vessa's camp burns, but the storm still walks` (4 s); later assaults spawn at the Fire rally |
| Vey at 0 HP | A break, never a death |

## Reward: end of Episode 3 (Malrik's track, saved for Ep8; campaign-outline D8)
- The Keystone Shard (with its power), the 6 slots at victory, essence 50 % (cap 1 500) after the bonuses: **+300 first if
  `sec_knight`**, **+300 first if `sec_refuse`**. Mother Hush stays unlocked on the track; the Nightmare Knight stays
  unlocked for Malrik's later missions.
- `CampaignState.MISSION_REWARDS[&"e3m4"] = {"flags": {"e3m4_knight_charge": "sec_knight", "e3m4_refused": "sec_refuse"},
  "bonus_essence": {"sec_knight": 300, "sec_refuse": 300}, "set_flags": {"ep3_complete": true, "torvald_heard_stone":
  true}, "next": &"e4m1"}`; mission-computed at E15: `e3m4_shard_uses`, `e3m4_seizures`, `shadow_stone_uses` +=
  `e3m4_shard_uses`, `e3m4_time`.
- Hooks: Ep7 (`episode7-opening.md`, E7.*) reads `torvald_heard_stone` (always true: the line in his turn scene "I heard it
  say my name, at Evenmead"); Ep8's Shadow road reads `shadow_stone_uses` (`mission-e3-03.md` "Reward"); `e3m3_refused`
  **and** `e3m4_refused` together set `shadow_never_used` (Ep8's Hush hesitation line and Malrik's fate shot, outline 4.4
  E19, gets one extra second of the candle).
- Story flow: victory -> save (`resume = ep3_ending`) -> `ep3_ending` -> Story menu (Episode 3 complete, Episode 4 card).
  A replay from the Missions list ends on the normal victory screen after `e3m4_field` and skips `ep3_ending` (Theatre).
- Level not carried.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Assault / raid counts | x 0.6, no Ash Hurlers or Kilnwarden | as written | x 1.4 |
| Vey HP per storm / rest | 2 600 / 90 s | 3 600 / 75 s | 4 600 / 60 s |
| Vey Stormcall (storm 3) / Thunderhead | 45 s / off in storm 2 | 35 s / storm 2-3 | 30 s / storm 2-3, every 25 s |
| Vessa level | L5 (L6 at A3) | L6 (L7 at A3) | L7 (L8 at A3) |
| Ridge countdown | 45 s | 30 s | 20 s |
| Dread Paddock from | 3:00 | 4:00 | 5:00 |
| Torvald army cap | 20 pop | 16 | 12 |
| Start crystals | 600 | 450 | 350 |
| Expected time | 20-25 min | 24-30 min | 28-36 min |
**Fight sizing** (normal; army value: units at cost, wizards `170 + 30 x level`, Hush `200 + 40 x level`, Vey **~1 200 /
1 300 / 1 400** per storm (3 600 HP, armor 25, ~45 DPS + Lunge / Chain / Stormcall); every assault <= 70 % of the side-0
force able to reach it then; Torvald counted only where he stands).
| Fight | When | Enemy | Side 0 then | Ratio |
|---|---|---|---|---|
| Raid (3 Riders) | 3:00, every 150 s | 540 | the workers' guard: ~600 + the Night Spire, or the army | <= 45 % at the nodes |
| A1 at W1 | 5:30 | 1 110 + Vessa L6 (350) + Vey 1 200 = **2 660** | army ~2 800 + Malrik L6 (350) + Hush L6 (440) + keep / spire = ~3 900 (Torvald 42 m away) | **68 %** |
| A2 west at W2 (Vey) | ~13:00 | 970 + 1 300 = **2 270** | ~3 600 west (2 Knights) + Malrik + Hush | 52 % |
| A2 east at W3 (Vessa) | ~13:00 | 740 + 350 = 1 090 | Torvald ~1 300 + the Birch Watch ring | 84 % alone: **the player must send help** (the pincer's lesson); with 1 Knight + 4 Shades ~60 % |
| A3 (three fronts) | ~20:00 | 2 760 + Vessa L7 (380) + Vey 1 400 = **4 540** | ~5 500 army (3-4 Knights) + Malrik L7 + Hush L7 + Torvald ~1 300 = ~7 600 | **60 %** |
- **The skill check is Vey's mobility**: Lunge goes for Malrik and the casters; chasing him on foot fails. Intended
  answers: a Nightmare Knight's Charge (+90 and a 0.3 s daze each 6 s), Hush's Night of Knives (x 1.5 on heroes,
  `marked`), Blood Tithe on the Knights, Soul Siphon under him while he lunges; and the stone's Heart of the Hollow,
  which **does** daze him (60 + 0.5 s): the temptation returns at the hardest moment.
- **Thunderhead** makes holding a point by standing on it wrong: the army steps out of the ring for 10 s and fights the
  column at its edge. Losing a watch for 20 s is fine; losing all three is the loss.
- Vey does not regenerate between storms except at a break; a player who does 2 000 damage to him in A1 and lets him walk
  away still faces a full storm 2 at A2 only if he broke. Unbroken, he keeps his damage until the pull-back (6:00), then
  heals on the crest (no break counted). Watch in the first playtest: if A1 rarely ends in a break on normal, drop storm 1
  to 3 000 HP before touching the assault sizes.

## Target length (normal)
| Part | Time |
|---|---|
| `c_e3_doubt` + briefing (outside) | ~1:30 (not counted) |
| `e3m4_return` | 0:20 |
| To the first break (A1 5:30 -> ~8:00) | 8:00 |
| To the second break (A2 13:00 -> ~16:00) + `e3m4_whisper` | 8:15 |
| To the third break (A3 20:00 -> ~23:30) | 7:30 |
| `e3m4_field` + 2 s | 0:47 |
| **Total** | **~24:50 clean, 24-30 with a lost watch or a missed break** (`ep3_ending` 1:00 after, not counted) |

## Implementation tasks (the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| E3M4.S1 | systems | `missions/mission_e3_04.tscn` + `MissionE304`: `evenmead.map` with the after-battle dressing (no Nature base, no Horn / Bramble Spires, Fire-owned standards as decor, spoiled wagons), `RiverSystem.setup` as e3m1; 3 watch points (`&"standard"`, side 0 at 0:00); the ridge countdown; start state (Citadel, Hush on the field, 450 / 150 + carried, 36 / 60, Torvald and Vessa as listed, the no-save fallback); `titans_enabled` Lair-only + `lair_min_time = 240`; Dread Paddock card Z only | E34.M1, E3M1.S1, 13.* (Lair) | `tests/test_e3m4_s1.gd`: the 3 points are side 0 at 0:00; side 1 owning all 3 starts a 30 s countdown that a neutralised point stops; the Paddock is refused before 4:00 and builds after; the Nature base is absent |
| E3M4.S2 [H] | systems-high | Objectives and events E1-E20; raids, A1-A3 (clock or break + 75 s, whichever later), pull-back at 6:00, withdraw; Vey's break / rest / return cycle and its rewards (+200 essence, +250 XP); the stone's hold (the e3m3 code reused) and Torvald's 30 m reaction; win / lose; difficulty table; `MISSION_REWARDS[&"e3m4"]`, `shadow_stone_uses`, `shadow_never_used`; the `resume = ep3_ending` save; the Missions-list replay path | E3M4.S1, E3M4.G1, E3M3.S2 | `tests/test_e3m4_s2.gd`: a scripted run breaks Vey in A1, A2 and A3 and ends `victory=true`; A2 starts at 13:00 when the first break came at 8:00 and at 14:15 when it came at 13:00; Vey at 0 HP never dies and is at the crest 3 s later; the ridge countdown reaching 0 is a defeat; the save holds the counters and `torvald_heard_stone` |
| E3M4.G1 [H] | gameplay-high | `vey_storm` (the `helper_vey` code with the story numbers: Blade, Lunge 80 / 40, Chain 55-29, Charged Ground, Stormcall 60 x 8, **Thunderhead**, the bond, storm levels, Storm Broken kneel + carry + rest, titan tags); the Knight's Charge on a titan-tagged boss deals +90 and dazes 0.3 s | TH.G1, 19.C11, 13.* | `tests/test_e3m4_g1.gd`: Thunderhead picks the watch point with the most side-0 units and deals 25 / s for 10 s after a 3 s telegraph; a break at 0 HP makes him invulnerable 3 s then moves him to `(-4, 34.8)`; storm 2 deals +10 %; a Fireball within 14 m cuts Chain by 2 s, not twice within 2 s |
| E3M4.A1 | ai | `AIStoryCaster` Vey rules (Lunge priorities, Chain, Stormcall, Thunderhead); profiles `mission_e3_04_enemy` (Fire, 12 at the rally, no attacks, lends Vessa to the assaults) and `mission_e3_04_ally` (Torvald: 16 pop, holds W3, pings, back to W3 60 s after) | E3M4.G1, 20.A* | Test: Vey lunges at Malrik within 10 m before a Shade; Torvald's army is back on W3 within 70 s of a ping ending; the Fire Commander never orders a scripted unit |
| E3M4.U1 | ui | Watch-point counter `(3 / 3)` + the red ridge countdown; `obj_storm` counter; Vey's boss bar with **three storm pips** and a `Resting 0:52` label while he sits on the crest; the J power button and the stone's hold (e3m3's); Thunderhead ring on the minimap; the Paddock's `Not yet (4:00)` | E3M4.S2 | Readable at 1600 x 900 and 3440 x 1440; hidden during cinematics |
| E3M4.C1 | four-wizards-high (cine) | `e3m4_return`, `e3m4_whisper`, `e3m4_field` on the mission scene; `ep3_ending` (1:00, stage film on `forge_evenmead` at night: the night preset of E3M2.V1, torches, the Ice pavilion) with its line track | 19.C1, 19.C2, E3M4.D1 | `cine check` 0 FAIL; `ep3_ending` 60 +- 1 s; every skip leaves its end state; StoryFlow plays e3m4 -> `ep3_ending` -> Story menu |
| E3M4.V1 | tech-artist | After-battle Evenmead: trampled-grass and scorched-ford decals, struck Nature pavilion frames, the storm-cloud card over Lark Hill, Vey's rest stone; the `vey_storm` break VFX (sparks pouring off the blade, the carry bolt) and **Thunderhead** (cloud card + crackle ring + bolts) on the 19.V25 kit; 0 lights | TH.V1, 19.V25 | Art Lab pass; `PERF OK` with A3 (three columns), 4 Knights, Torvald's army and Thunderhead on screen |
| E3M4.O1 | Voice Forge agent | `data/voice/lines/e3m4.json` (L1-L32 + L6b) and `ep3_ending.lines.json` (the E3M4.D1 script); no new speaker | E3M4.D1 | Every WAV fits its slot (L6 / L17 / L28 6 s) |
| E3M4.D1 | game-designer | Read the 33 lines in game, trim over-long ones; write `ep3_ending` (1:00, `episode3-4-opening.md` 3 format: shots and line track) from the beats above | Playtest | Script written; changes back in this doc |

## Acceptance checks
- [ ] E3M4.S1: the after-battle Evenmead loads with e3m1's positions unchanged (+-0.5 m) and the three watch points at
  `(0, -36)`, `(-34, -22)`, `(40, -22)`; no Nature base; the Paddock opens at 4:00.
- [ ] E3M4.S2 / G1: a scripted normal run (Paddock at 4:00, 2 Knights by 13:00, help sent to W3 at A2) breaks Vey three
  times and ends `victory=true` in 24-30 game-minutes in 3 / 5 seeds, with Malrik alive in 5 / 5; Vey never dies in any
  run; the ridge never falls in the scripted run.
- [ ] A run that leaves W3 to Torvald alone at A2 loses Birch Watch (the pincer lesson) but not the mission.
- [ ] Thunderhead, the Storm Broken cycle, the 75 s rest and the assault clocks behave as tabled; the Knight's charge on
  Vey completes `sec_knight`.
- [ ] Victory saves the Episode 3 flags (`ep3_complete`, `torvald_heard_stone`, `shadow_stone_uses`,
  `shadow_never_used` when both refusals are done) with `resume = ep3_ending`; the Story menu then shows Episode 3
  complete and the Episode 4 card.
- [ ] `PERF OK` with A3 on screen; every cutscene skip leaves its end state.
- [ ] Lead: one human playtest on normal (length, breaks per assault, whether a watch fell, stone uses) logged in
  `docs/plan/usage-log.md`.

Dependencies: E34.M1 map and e3m1's build, E3M3.S2 (the stone's hold code, reused), `MissionBase` (M9.S1), the helper
code (TH.G1, TH.S1) and Old Vey's kit (19.C11), the Dread Paddock and Nightmare Knight (step 13), the 2v2 ally layer
(`ai-2v2.md`, 20.A*), `AIStoryCaster` (E2M1.A1), 19.C1 / 19.C2 for the cutscenes (fallbacks otherwise).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Nightmare Knight (Shadow titan).
- **Why here:** the spec's own design: the charge answers a fast lunging boss (Old Vey); `sec_knight`.
- **Moment:** A1 (5:30), Vey's first storm; hint E7 "The old man can't stop a horse.".
- **Intro card:** `Nightmare Knight. A titan at a gallop: its charge breaks a line, or a storm.`

## Built (2026-10-07)
`missions/mission_e3_04.tscn` + `scripts/campaign/mission_e3_04.gd` (`MissionE3_04`), tests `tests/test_e3m4.gd` (start,
storm, ridge, knight) and `tests/test_e3m4_sim.gd` (slow list). Deviations:
- The Evenmead map of e3m1 in code (3 seats: Shadow + Ice vs Fire; no Nature base), the watch points are `MissionZone`s
  (side 0 owns all three at 0:00; side 1 x 1.25 time), the ridge-falls countdown as specified.
- Old Vey = a Helper (`helper_vey` at level 8: Lightning Lunge / Chain / Stormcall from HelperAbilities) on team ENEMY,
  bonded to Vessa: he walks with her column in every assault (A2's west column goes without him); 3 600 HP per storm,
  +10 % damage per storm after the first; a death guard turns 0 HP into a break (dormant 3 s, then he rests on the crest
  until the next assault); +200 essence and +250 XP per break. Thunderhead (storms 2-3) is mission-side; no Charged
  Ground aura, no "spark first" bond, no 35 s Stormcall in storm 3.
- An assault that runs 6:00 without a break pulls back and a 4th+ assault repeats A3 (the spec has only three
  assaults; victory still needs three breaks).
- The Dread Paddock is a mission building (button, from 4:00, 300) training a code-built Nightmare Knight (shadow_knight
  base, the `titans/nightmare_knight` model; 400, pop 4, 50 s); Charge = +90 and dazed 0.6 s (bosses 0.3 s) on the first
  hit after a 6 m run (no knockback).
- Heart of the Hollow / the stone's hold: the e3m3 rules (J / button), Torvald's L16 within 30 m.
- No cine timelines; no `ep3_ending` film (rewards `next` = `e4m1`, not built yet).
- **Tuning (2026-10-07)**: Vey's helper kit at level 5 (at 8 his Chain / Stormcall cut a 40-unit army to 4 in A1);
  crystal nodes as e3m1.
- **Scripted runs (normal): not green.** `tests/test_e3m4_sim.gd` holds the three watch points to A1 with ~40 soldiers
  and raises the Paddock and 2-3 Knights (the Knight's charge lands on Vey: `sec_knight`), but A1 wipes the army:
  Vessa's Fireball (mana-limited, no cooldown) and Vey's chain take ~30 soldiers in ~20 s, and Malrik falls in storm 1
  or 2 (6:12-13:36). Open: Vessa's Fireball rank / mana for this mission, or a scripted player that splits the army.
