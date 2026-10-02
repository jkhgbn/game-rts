# Campaign mission e4m4: "Winter's End" (Ysolde + Maelis, with Vessa, vs Torvald + Aldra; Episode 4)

Written 2026-10-02 (`campaign-outline.md` 3.4). Episode 4 "What Grows Back", mission 4 of 4 (id `e4m4`, outline D6), the
episode's last battle. On **Torvald's frontier**, the week before the snows close the passes, Ysolde (player) and Vessa
(allied Fire bot) break **the Wall of a Hundred Winters**, the ice wall behind which the Ice-Shadow alliance would feed
Malrik's war all winter, and its two **Wallwarden Colossi**. At Aldra's Glass Spire, Aldra has Ysolde at her mercy and
**Torvald stops her**: the seed of his turn (Ep7). A siege mission and the debut of Nature's titan, the **Elder Treant**.
Target **24-30 min** on normal. Uses `mission-01.md` / `mission-e3-01.md` rules (MissionBase, 2v2 seats, scripted groups,
70 % rule, difficulty multipliers), `walls.md` 5 and 8 (real gates, wall damage factors), `cavalry-mounts.md` (Elder
Treant, Elder Circle), `tiers.md` 6, `t3-helpers.md` 3-4 (Maelis, Aldra), `caster-units.md` 5.3, `kingdom-nature.md`,
`kingdom-ice.md`, `items.md` campaign rules. New scene `missions/mission_e4_04.tscn` + `scripts/campaign/mission_e4_04.gd`
(`MissionE404 extends MissionBase`, mission id `e4m4`). Metres, seconds, `m:ss` since the navmesh was ready; positions
`(x, z)`, `+z` = south. Status: **design only**. Recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | New World Forge map **`data/maps/hundred_winters.map`**, **160 x 140**, `symmetry=none`, seed **44**, snowfield and pine biome; the Wall runs east-west across the whole map between impassable cliffs. Every position below is binding for E4M4.M1 | "Torvald's frontier (ice wall map)" (outline); a full-width wall needs its own map |
| D2 | Seats and sides | **Side 0 = Ysolde (player, south-west) + Vessa (ally bot, south-east)**; **side 1 = Torvald (Ice bot, behind the Wall)**. Shadow appears only as two scripted "tithe" detachments (Malrik's men, no Malrik) | Malrik is busy on Evenmead's ridge (e3m4); the two tithes keep the alliance visible |
| D3 | The Wall | **Scripted `WinterWall` pieces** (team ENEMY, the `walls.md` L3 Ice wall look): 42 pieces of 3 m (4 of them Rime Spire towers) + **3 Winter Gates** (real doors, `walls.md` 5: side 1 passes, side 0 is blocked). Damage to them uses `walls.md` 8 at **L3** (normal units x0.35, siege x1.5, titans x2.0 with their own `building_damage_mult`, spells x1.0). While the **Winterheart** stands, every piece regrows **1 % / s** after 8 s undamaged | Reuse the wall system's numbers and doors; the regrowth makes "break the heart" the real target |
| D4 | The Wallwardens | Two story bosses **`wallwarden`** (a Rime Colossus at 1.6 scale, titan tag): dormant in alcoves behind the West and East Gates; each **wakes** when its gate drops below 50 % HP (or at **14:00** if neither woke). **The Winterheart is invulnerable while a Wallwarden lives** | "Break the Wall and its Rime Colossi" (outline); the order (gates -> wardens -> heart) reads at a glance |
| D5 | The Elder Treant | **Unlocked here**: the **Elder Circle** (Lair, 280 crystals, 60 s, max 1 this mission) from the **Citadel**, Elder Treant **Z** (600, pop 6, 75 s, max 2 trained). Plus a **free Treant** from the secondary "Wake the Sleeping Elder" | Outline: "Elder Treant titan". The titan wall factor (net 1.0 vs 0.35 for soldiers) makes the Treant the wallbreaker the mission is built around |
| D6 | Maelis | **Already called at 0:00** (`helper_start_called`, e4m3 D4). Old Vey does **not** appear: one helper per team (`t3-helpers.md` 3), and the team's is Maelis | Consistent with e4m3; the 2v2 helper rule |
| D7 | Torvald's turn | In the cutscene `e4m4_enough`: Aldra traps Ysolde in glass and raises the chisel; **Torvald stops her** ("Enough"). It plays the instant Ysolde reaches the Glass Spire, whatever her HP (she cannot die inside it) | The outline's "Torvald stops Aldra from finishing Ysolde: the seed of his turn"; a cutscene, so no player is punished for walking in |
| D8 | The ending | Victory ends on the truce: the first blizzard closes the passes (narrator), then StoryFlow plays **`ep4_ending` "Winter's End"** (1:00, beats below) | campaign-outline 3.4: "a winter truce falls on both alliances; the episodes that follow are what the four remember that winter" |
| D9 | Terrain | Snow everywhere (look). If `TerrainSystem` exists: `snow` (Ice +25 % speed) north of the Wall, **packed road** (no bonus) on the old border road south of it | e2m1 D9 rule: look now, rules later |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e4_frontier`)
1. On Torvald's frontier stands a wall older than any of the four: the Wall of a Hundred Winters. When the snows come it
   closes the passes, and behind it the north can feed Malrik's war all winter long.
2. The first blizzard is a week away. Vessa has brought fire and siege. Ysolde has brought something slower and much
   heavier: the elders of the wood, if she can wake them.
3. Break the Wall's two wardens and the Winterheart that feeds it. Then go to Aldra's Glass Spire and end this before the
   snow does.
Briefing objectives: `obj_wall`, the rule `Ysolde must survive`, the line `Soldiers barely scratch the Wall. Siege, titans
and spells break it.`

## Map: "The Hundred Winters" (160 x 140, `data/maps/hundred_winters.map`, seed 44, not mirrored)
Playable bounds x -77..77, z -67..67 (camera bounds 3 m inside); cliffs (impassable rock) beyond |x| 72 north of z 0, so
the Wall is the only way north. South half: snowfields, pine stands at the edges, an old border road from `(0, 60)` north
to the Heart Gate. North half: deep snow, Torvald's camp. Clearings: no tree or rock inside.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| **Heartwood** (player, tier 2 Stronghold, 2 700 HP) | `(-46, 48)` | 16 | `PLAYER_START` = Ysolde at `(-38, 38)` |
| Grove Hall / Seed Hollows (pre-built) | `(-32, 50)` / `(-58, 56)`, `(-44, 62)` | 4 / 3 | 14.1 / 14.4 / 14.1 m from the keep |
| Nodes `e4m4_home_a` / `_b` | `(-55, 42)` / `(-40, 57)` | - | **1 500** each (10.8 m from the keep) |
| Node `e4m4_west` (expansion) | `(-60, 14)` | 7 | **2 000**; hall spot `(-52, 18)`; 22 m south of the Wall: the first thing sorties hit |
| **Fire Keep** (Vessa, ally bot, Stronghold) | `(46, 48)` | 16 | Ember Hall `(32, 50)`, Hearths `(58, 56)`, `(44, 62)`; nodes `(55, 42)` / `(40, 57)` 1 500; expansion `(60, 14)` 2 000 |
| Rallies: player / Vessa | `(-30, 28)` / `(30, 28)` | - | - |
| **The Sleeping Elder** (frozen Elder Treant in an ice shell) | `(-24, 18)` | 10 | 2 Rime Totems `(-30, 14)`, `(-18, 14)`; guard G0; 26 m south of the Wall |
| **The Wall of a Hundred Winters** | line z **-8**, x -72..72 | 6 (both sides) | 2 m thick, 5 m high; pieces 1 200 HP; regrowth D3 |
| Winter Gates (real doors, 6 m opening) | **West** `(-44, -8)`, **Heart** `(0, -8)`, **East** `(44, -8)` | - | 2 400 HP each; locked to side 0 (x0.75 more, `walls.md` 8) |
| Wall Rime Spires (towers on the line) | `(-60, -8)`, `(-24, -8)`, `(24, -8)`, `(60, -8)` | - | 720 HP, range 10, chill 2 s on hit; none covers a gate (16-20 m away) |
| **Winterheart** (a 4 m rime crystal on a rune plinth) | `(0, -16)` | 6 | 3 000 HP, armor 20, team ENEMY, `counts_for_defeat` false; invulnerable while a Wallwarden lives (D4); 8 m behind the Heart Gate |
| Wallwarden alcoves | West `(-44, -16)`, East `(44, -16)` | 6 | Dormant until D4's trigger |
| Gate garrisons (behind the Wall) | West `(-44, -14)`, Heart `(0, -22)`, East `(44, -14)` | - | Groups G1-G3; Frostbows (range 12) reach 6 m south of the Wall |
| **Torvald's camp** (Ice bot) | Rime Keep `(0, -54)` (**Citadel**, 4 200 HP), Frost Halls `(-16, -48)`, `(16, -48)`, Snow Lodges `(-28, -58)`, `(28, -58)` | 18 / 4 / 3 | Nodes `(-8, -62)` / `(10, -62)` 1 500; 5 Rime Haulers; rally `(0, -34)` |
| **Aldra's Glass Spire** | `(30, -36)` | 10 | 2 500 HP, armor 20, range 11, 14 dmg, cooldown 1.4, chill 1.5 s; the goal zone r **8** around it (`obj_spire`) |
| Shadow tithe spawn | east edge north of the Wall `(74, -30)` | - | They come through the East Gate |
| Ice wave spawns | the Frost Hall nearest the target (Rime Keep's door if both gone) | - | Through the nearest gate |
Distances (navmesh): Heartwood -> West Gate 57 m; Heartwood -> Heart Gate 71 m; Fire Keep -> East Gate 56 m; Heart Gate ->
Winterheart 8 m; Heart Gate -> Glass Spire 41 m; Rime Keep -> Heart Gate 46 m; Sleeping Elder -> West Gate 33 m.
Generator check (E4M4.M1): no path from south to north except through the three gates (with the Wall closed) and through
the breaches once pieces fall; paths from `PLAYER_START` to the Sleeping Elder, all three gates and the expansion.

**Look** (E4M4.V1): low white-gold winter sun from the south-west `(0.98, 0.92, 0.85)` energy 1.0, snow `(0.88, 0.90, 0.95)`,
blue shadows; the Wall a cliff of old blue-green ice with rune bands (walls.md L3 glacierglass) and frost smoke at its
top; the Winterheart pulses pale blue through the Heart Gate's bars; Aldra's spire a needle of clear rune-glass that
catches the sun. Snow falls lightly from 20:00 and heavily in the last cutscene.

**`WinterWall` / Winter Gate** (systems): `walls.md` L3 pieces with the `Frostbind` twist (melee attackers chilled 3 s,
ranged / siege within 8 m chilled 1.5 s per hit). Wall factor per `walls.md` 8: soldiers, Ysolde's auto-attacks, Maelis x0.35;
Ash Hurler, Frost Mortar x1.5; **Elder Treant** net **x1.0** (0.5 x 2.0), rooted volley included; spells and helper
abilities x1.0 (Thornburst 40-62 hits a piece). A destroyed piece leaves a 3 m breach (`walls.md` 5.3 breach rule); the
Winterheart's regrowth never rebuilds a destroyed piece.

**`wallwarden`** (gameplay, story boss, team ENEMY): 2 600 HP, armor 25, 45 damage, range 2.2, cooldown 2.0, speed 3.0,
on hit `chill` 2 s, titan tag (CC half, Snagroot immune, knockback immune). **Avalanche Stomp** every 12 s: r 4 around it,
60 damage + `chill` 2 s (red-blue ground telegraph 0.8 s). Brain: walk out of its alcove through its gate (or its breach)
to the nearest side-0 titan, else the largest side-0 group within 30 m of the Wall; never goes farther than 30 m south of
the Wall (returns). Worth 700 (kill essence 300, XP 300 to the killer's team).

## Start state (Ysolde's track, campaign-outline D8)
| Item | Value |
|---|---|
| Ysolde | **Level 6 with 5 unspent points** (Thornburst r1 known), **cap 8** |
| Artifacts / items | From the save: **Heartwood Seed** in slot 1 (e4m3); the 6 slots |
| Essence / crystals | **150** + carried / **450** (easy 550, hard 350); essence +1 / s |
| Buildings | Heartwood (tier 2 Stronghold), Grove Hall, 2 Seed Hollows (complete) |
| Units | 7 Spriglings gathering (4 / 3); 8 Thornlings, 4 Burr Slingers, 2 Bloomtenders, 3 Vinelashers, 2 Greenheart Oathkeepers, 2 Bramblehorns, 1 Bramblesage, **1 Briar Roc** at `(-36, 34)` (**2 530** crystals of army); + 2 Grove-born Bramblehorns (veterancy 2) if `e4m3_groves_unbroken` |
| Maelis | Called at 0:00 (D6), level 6, Escort |
| Population | 7 + 31 + Maelis 4 = **42 / 60** (max 4 Seed Hollows = cap 100) |
| No save | No artifact; empty slots; essence 150 + **700**; no Grove-born |
| Vessa (ally bot, seat 2, Fire) | **Level 6** (Fireball r3, Ember Step r2, Kindle r1) at `(30, 28)`; Fire Keep at Stronghold, Ember Hall, 2 Hearths, 6 Cinder Hands; 6 Flame Guards + 3 Ember Archers + 2 Ash Hurlers + 2 Pyre Adepts + 1 Kilnwarden at her rally (~1 550 crystals) |
| Torvald (enemy bot, seat 1, Ice) | **Level 7** (Rime Bolt r3, Flash Freeze r2, Rime Aegis r2) at the Heart Gate's parapet `(0, -10)` (untargetable there until I2: he watches from the Wall); Rime Keep at the **Citadel**, 2 Frost Halls, 2 Snow Lodges, 5 Rime Haulers; 4 Rimeshields + 2 Shardcasters + 1 Shardguard at `(0, -34)` |
| Aldra (enemy story unit) | `aldra_story` (e4m3) at **Torvald's level** (L7: 890 HP), at the Glass Spire; **-15 % HP for the whole mission** if `e4m3_spire_shattered` |
| Fog | On; the Wall's south face, the three gates, the Sleeping Elder explored for side 0 at 0:00 |
| Champions, trade, camps, beasts, river, points | Off |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Seed Hollow (max 4), Grove Hall, Bramble Spire; **Elder Circle** (from the Citadel, max 1) | Stables, Bazaar |
| Units | Sprigling; Grove Hall: Z Thornling, X Burr Slinger, C Bloomtender, V Bramblehorn, N Thistle Darter, M Vinelasher, `,` Greenheart Oathkeeper; keep: B Bramblesage, C Briar Roc (Citadel); **Elder Circle: Z Elder Treant** (max 2 trained) | Wildwood Archer (skirmish only), the Elder Circle's other slots (Mossback, the Wildcaller call: Maelis already is) |
| Keep | **Citadel** (X, 300 crystals, 90 s, from **5:45**) | - |
| Helper | Maelis (called); Revive at the skirmish price | - |
| Spells | Thornburst, Wild Bloom, Call the Thicket; cap L8 | - |
| Items | Base shop (Heartwood, Grove Halls) | - |

## Tiers, the helper and the titan
| Item | Value |
|---|---|
| Code | `MissionE404._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`, `helper_start_called = true`, **`titans_enabled = true`** (new mission opt-in, read like `t3_enabled`: the kingdom's Lair and titan become buildable / trainable), `lair_max = 1`, `titan_max_trained = 2`; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(2)` |
| Heartwood card | Z Sprigling · X Citadel · C Briar Roc · V `Revive Maelis` · B Bramblesage · Set Rally r3c1 |
| Worker build menu | Seed Hollow, Grove Hall, Bramble Spire, **Elder Circle** (greyed `Requires Citadel`) |
| Citadel hint | Once (12 s): `Your Stronghold can become a Citadel: select the Heartwood and press X (300 crystals, 90 s). It opens the Elder Circle: its Elder Treants break walls.` |
| Elder Circle hint | Completed: `Elder Treant (Z at the Elder Circle): roots into a living tower (V) and hits the Wall far harder than soldiers.` (10 s) |
| Vessa | Bot rules: never upgrades (`bots_upgrade = false`), never calls a helper (D6), trains Ash Hurlers (2-4) for the gates |

### The Bramblesage here (`caster-units.md` 5.3)
**Pollen Haze** on a gate's garrison silences the Shardcasters and Frostbows that shoot over the Wall while the Treants and
Hurlers work. **Snagroot** pulls the Frost Mortar out of the Heart garrison and drags Torvald's Shardguard (pop 3, not
immune) away from the Winterheart in I3. It cannot pull a Wallwarden (titan, immune). Hint at E4.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_wall` | Primary | `Break the Wall of a Hundred Winters` with the lines `Wallwardens 0 / 2` and `Winterheart (frost-bound)` -> `(open)` once both wardens fall | The Winterheart is destroyed |
| `obj_spire` | Primary (after `obj_wall`) | `Bring Ysolde to Aldra's Glass Spire` | Ysolde within **8 m** of `(30, -36)` -> cutscene `e4m4_enough` |
| `obj_ysolde` | Primary, always shown | `Ysolde must survive` | Fails = defeat |
| `sec_elder` | Secondary | `Wake the Sleeping Elder` | Both its totems destroyed, then Ysolde within 4 m of the shell for 4 s (no enemy within 10 m, the e4m3 plant rule) |
| `sec_halls` | Secondary | `Break both Frost Halls` | The Frost Halls at `(-16, -48)` and `(16, -48)` are destroyed |
States through `Events.objective_changed(id, state)`.

## Guards, waves and the bots (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: team ENEMY, group `"scripted"`, never controlled by the Commander; guards hold their spot with a 2x
leash (Wallwardens: the D4 brain); waves attack-move as listed, refreshed every 3 s, through the gate nearest their target
(side 1 passes its own doors).
| Group | Where | Units | Value |
|---|---|---|---|
| G0 Elder watch | `(-24, 12)`, ring r 4 | 3 Rimeshields + 1 Rime Seer (+ 2 totems) | 420 |
| G1 West garrison | `(-44, -14)` | 3 Shardcasters + 2 Frostbows | 610 |
| G2 Heart garrison | `(0, -22)` | 2 Shardcasters + 2 Frostbows + 1 Frost Mortar | 690 |
| G3 East garrison | `(44, -14)` | 3 Shardcasters + 1 Rime Seer + 1 Frostbow | 590 |
| Wallwardens | West / East alcove | 1 `wallwarden` each (dormant) | 700 each |

| Wave | Trigger | Units (spawn) | Order |
|---|---|---|---|
| I1 west sortie | 4:00 | 4 Rimeshields + 2 Shardcasters + 2 Rimelings (West Gate) | The player's west expansion `(-60, 14)` (or its hall), then the Grove Hall |
| S1 Shadow tithe | 7:00 | 4 Shades + 2 Nightbolts + 1 Hexweaver + 1 Gloom Deacon (east edge, East Gate) | Vessa's Ember Hall, then the Fire Keep |
| I2 Torvald's sortie | 10:00 | **Torvald** (leaves the parapet) + 4 Rimeshields + 2 Shardcasters + 1 Frost Mortar + 1 Shardguard (Heart Gate) | The Elder Treant nearest the Wall if any, else the largest side-0 group within 30 m of the Wall; Torvald retreats under 35 % (bot rule 8) and returns to the parapet |
| Wardens wake | Its gate < 50 % HP, or 14:00 | The Wallwarden (D4 brain) | - |
| S2 Shadow tithe | 15:00 | 6 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon (East Gate) | The Fire Keep (Vessa pings `help`, L18) |
| I3 Aldra's glass host | 18:00 | **Aldra** + 4 Rimeshields + 2 Shardguards + 2 Hoarlight Magebows + 1 Frost Mortar (Heart Gate, or the Glass Spire if the Heart Gate is gone) | The side-0 units nearest the Winterheart; Aldra casts Wake the Sentinel on arrival; she flees at 25 % to the Glass Spire, back after 90 s |
| The thaw | `obj_wall` done | No spawn: every Wall piece loses 50 % of max HP, the three gates open for everyone, the wall spires go dark (0 attack), regrowth stops; **Torvald** walks to his keep door and stands (fights only within 8 m); I-waves stop | - |
| Spire guard | `obj_wall` done | **Aldra** (full HP) + 6 Rimeshields + 3 Shardcasters + 2 Shardguards + 1 Rime Colossus at the Glass Spire, ring r 6 (guard, 2x leash) | Hold the spire |
| Withdraw | `e4m4_enough` ends | Every enemy unit | Passive, walk to the Rime Keep |
Rules: `sec_halls` done = later Ice waves (I2 after it, I3, the spire guard) lose 40 % of their soldiers (rounded down; no
wizard / Aldra change) and I3 has no Mortar. Torvald respawns 60 s after a death at his keep (`Torvald has fallen, the
frost will bring him back`) and returns to the parapet.
**Enemy bot** (profile `mission_e4_04_enemy`: Ice normal knobs, `min_attack_pop` 99, `worker_target_home` 5, no
expansion, up to 12 soldiers at `(0, -34)`, `defend_radius` 15 around its buildings, `bots_upgrade = false`) gathers,
trains and defends its camp; it never repairs the Wall (the regrowth does). **Ally bot Vessa** (`ai-2v2.md` ally layer,
profile `mission_e4_04_ally`, Aggressive-supportive): trains up to **18 army pop** incl. 2-4 Ash Hurlers and a
Kilnwarden, answers pings, defends her base; scripted: at **9:00** her army attacks the **East Gate** (Hurlers at 12 m,
Slag Rain on the garrison) and keeps at it until the East Wallwarden is dead, then joins the player at the Heart Gate;
she pings `help` at S2.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cutscene `e4m4_arrival` (HOLD 0:15); L1-L5; `obj_wall` active; hint `The Wall shrugs off soldiers. Ash Hurlers, Elder Treants and spells break it. The Winterheart behind the middle gate makes it heal.` (12 s) |
| E2 | Sleeping Elder seen (explored) | `sec_elder` active (L5 already pointed at it) |
| E3 | Sleeping Elder woken | The ice shell bursts; a **free Elder Treant** (team PLAYER, commandable, pop 6, counts against `titan_max_trained`? **no**: it is extra) stands up; L6; `sec_elder` done |
| E4 | 0:45 | Hint (10 s) `Bramblesage: Pollen Haze over a gate's garrison stops their archers shooting over the Wall.` |
| E5 | I1 spawns (4:00) | L7 |
| E6 | S1 spawns (7:00) | L8-L9 |
| E7 | Citadel complete | L10; the Elder Circle hint |
| E8 | First Elder Treant trained (or woken, whichever first) | L11 (once) |
| E9 | 9:00 | Vessa's East Gate push starts; L12 |
| E10 | I2 spawns (10:00) | L13-L14 |
| E11 | First gate destroyed | L15 |
| E12 | First Wallwarden wakes | Cutscene `e4m4_wardens` (PAUSE 0:08): L16-L17 |
| E13 | First Wallwarden destroyed | L19 |
| E14 | S2 spawns (15:00) | L20; Vessa's L18 help ping |
| E15 | Both Wallwardens destroyed | L21; the Winterheart line reads `(open)` (it loses its frost shell: 1 s crack VFX) |
| E16 | I3 spawns (18:00) | L22 (or L22b with `e4m3_spire_shattered`) |
| E17 | Winterheart destroyed | Cutscene `e4m4_thaw` (HOLD 0:12): L23-L25; the thaw; `obj_wall` done; `obj_spire` active; spire guard; L26 |
| E18 | Frost Halls both destroyed | L27; `sec_halls` done |
| E19 | Ysolde within 8 m of the Glass Spire | Cutscene `e4m4_enough` (PAUSE 0:40): L28-L34; then `Events.mission_ended(true)` 2 s after it; StoryFlow plays `ep4_ending` |
| E20 | Ysolde dies | L35; defeat after 3 s |
| E21 | Heartwood destroyed | L36; defeat after 3 s |
| E22 | Fire Keep destroyed | Nothing (`Vessa falls back to the Heartwood`); her units walk to `(-30, 28)`, she respawns at the Heartwood as a 2v2 wizard |
The gates can be broken in any order; the intended rhythm: the Sleeping Elder ~2:00-4:30, I1 at the expansion, the
Citadel 5:45-7:15 and the Elder Circle by ~8:30, the West Gate with the Treant(s) ~9:00-12:00 while Vessa works on the
East Gate, the West Wallwarden ~11:00-13:00, the East one with Vessa ~14:00-17:00, the Heart Gate and the Winterheart
through I3 ~18:00-22:00, the spire ~22:00-26:00.

## Dialogue (37 lines; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `ysolde`, `vessa`, `maelis`, `torvald`, `aldra`, `shade`
(the tithe captain, shown as **Shadow Captain**). Colours: Ysolde `(0.55, 0.90, 0.35)`, Vessa `(1.0, 0.45, 0.1)`, Maelis
`(0.60, 0.85, 0.50)`, Torvald `(0.55, 0.80, 1.00)`, Aldra `(0.62, 0.95, 0.88)`, Shadow Captain `(0.55, 0.40, 0.70)` (**new
colour**), Narrator `(0.9, 0.85, 0.7)`. Every line <= 96 characters.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Torvald's frontier, a week before the snows. A wall older than any of the four. |
| L2 | E1 | ysolde | The Wall of a Hundred Winters. While it stands, this war never has to stop for weather. |
| L3 | E1 | vessa | So we knock it down. I brought fire. You brought... a tree? |
| L4 | E1 | ysolde | Several. They're very patient, and they hit like a landslide. |
| L5 | E1 | maelis | Under the ice by the west gate, something old is sleeping. Wake it, and it will owe you. |
| L6 | E3 | maelis | Good morning, grandfather. There's a wall that needs leaning on. |
| L7 | E5 | torvald | Ysolde. I warned you about the cold. Turn back while the passes are open. |
| L8 | E6 | shade | The Bishop sends his tithe, Lord Torvald. He asks for nothing in return. Yet. |
| L9 | E6 | torvald | Nothing is what Malrik always asks for. At first. |
| L10 | E7 | ysolde | The Heartwood stands tall again. Let the elders come. |
| L11 | E8 | maelis | Now that is a tree with opinions. |
| L12 | E9 | vessa | I'm taking the east gate. Don't wait for me. I definitely won't wait for you. |
| L13 | E10 | torvald | I built this wall so nobody would ever have to choose. You are making me choose. |
| L14 | E10 | ysolde | No, Torvald. Malrik made you choose. I'm only here to hear the answer. |
| L15 | E11 | vessa | A gate's down! Your trees punch harder than my fire, Ysolde. I hate it. Keep going. |
| L16 | E12 (`e4m4_wardens`) | aldra | Wake, old guards. Somebody is knocking. |
| L17 | E12 (`e4m4_wardens`) | ysolde | Colossi. Tall, slow, and stubborn. So are we. |
| L18 | E14 | vessa | Shadow at my hearths, Ysolde! If your trees can walk, now's the time. |
| L19 | E13 | maelis | One mountain fewer. Mountains are overrated. |
| L20 | E14 | shade | The second tithe, Lord Torvald. The Bishop says: no more excuses. |
| L21 | E15 | narrator | The wardens are rubble. The Winterheart stands alone, and it is cracking. |
| L22 | E16 | aldra | You thawed his wood, Ysolde. You will not thaw his wall. |
| L22b | E16 (`e4m3_spire_shattered`) | aldra | You broke my glass once, Ysolde. Once was enough. |
| L23 | E17 (`e4m4_thaw`) | narrator | A hundred winters, broken in one afternoon. The Wall begins to weep. |
| L24 | E17 | vessa | Look at it melt! Fire always wins in the end. |
| L25 | E17 | ysolde | That was the tree, Vessa. |
| L26 | E17 | maelis | The glass spire. Aldra will be waiting. She always is. |
| L27 | E18 | vessa | Both halls! Torvald's soldiers will have to train in the snow. Good. |
| L28 | E19 (`e4m4_enough`) | aldra | One strike, Torvald, and the green war is over. Let me finish it. |
| L29 | E19 | torvald | Enough, Aldra. |
| L30 | E19 | aldra | She broke your wall! |
| L31 | E19 | torvald | It was only ever ice. Let her up. |
| L32 | E19 | ysolde | Why? |
| L33 | E19 | torvald | Because a hundred winters is long enough. Go home, Ysolde. Spring will keep. (6 s) |
| L34 | E19 | narrator | That night the first blizzard closed the passes. Both sides sat down to wait for spring. |
| L35 | E20 | ysolde | Plant me... somewhere warm... |
| L36 | E21 | maelis | The Heartwood's fallen. Winter wins this one. |
Echoes: L29-L33 are the seed of the turn the outline places here (Torvald's "No" in Ep7 grows from it), and L31 ("only
ever ice") answers his Ep1 C1 "No. For now."; L33's "spring will keep" closes e4m3 L18-L19 (spring) and the episode's title;
L13-L14 name the choice Ep7 completes; L24-L25 are the Vessa / Ysolde joke of the whole episode (fire vs patience); L8 /
L20 keep Malrik in the war without putting him on the field; L16 / L22 are Aldra's voice from e2m1 and e4m3.

## Cinematic hooks
Camera axis: the Ysolde - Torvald line runs south -> north through the Heart Gate; cameras stay on its **west** side
(the Ep4 rule).
| id | Kind | When | Content | Lines | Skip end state |
|---|---|---|---|---|---|
| `e4m4_arrival` | ENGINE, **HOLD** 0:15 | E1 | 3 shots: CRANE along the Wall from the west cliff, frost smoke on its top, rune bands glowing faintly; MS Torvald on the Heart Gate parapet, cloak in the wind, Aldra's spire catching the sun behind him; WS the Nature and Fire camps in the snow, Ysolde and Vessa side by side at the rally | L1 over shot 1 | Camera on Ysolde; `obj_wall` active |
| `e4m4_wardens` | ENGINE, **PAUSE** 0:08 | E12 | 2 shots: low angle at the alcove, the ice face splits and the Wallwarden steps out, rime pouring off it; MS Aldra on the Wall above, chisel raised (she stays on the Wall in this shot only) | L16-L17 | The Wallwarden awake at its alcove door with its brain running; camera back on the gate |
| `e4m4_thaw` | ENGINE, **HOLD** 0:12 | E17 | 2 shots: ECU the Winterheart's last crack, light pouring out, then shatter (12 shards); WS along the Wall: meltwater runs down its face, pieces sag, the three gates swing open, the spires go dark | L23-L25 | The thaw applied (pieces -50 %, gates open, spires off, regrowth off); spire guard spawned; Torvald at his keep door; `obj_spire` active |
| `e4m4_enough` | ENGINE, **PAUSE** 0:40 | E19 | 6 shots: MS Ysolde reaching the spire's foot; glass shards burst from the snow around her and close into a cage to her shoulders (`glass_prison` VFX), Maelis thrown back by a glass wave (she lands, kneels); MCU Aldra above her, chisel raised (L28); **Torvald's hand** catches the chisel's shaft (CU), WS Torvald and Aldra face to face, the Rimeshields lowering their shields one by one (L29-L31); MS Ysolde as the cage cracks and falls away (L32); CU Torvald, front, weary (L33); WIDE crane up and out: the first blizzard rolls over the Wall, both armies standing still in the snow (L34); FADE_BLACK | L28-L34 | Every enemy unit passive and walking home; Ysolde free at full HP; `Events.mission_ended(true)` fired; rewards saved; StoryFlow to `ep4_ending` |
Fallbacks: no cine -> each hook's lines as dialogue + a 2 s pan to its subject; `glass_prison` missing = a plain ice-block
status on Ysolde for the shot; Torvald's catch = a cut on his raised hand. **Episode ending** `ep4_ending` "Winter's End"
(1:00, ENGINE; beats for its writer, campaign-outline 3.4): snow over Evenmead, the golden tree white to its crown and
still glowing; Ysolde and Vessa by a fire at Cinderwatch, the Heartwood Seed glowing in Ysolde's hand ("You'll keep it?"
"Until spring."); Malrik alone in his crypt with one candle, the heart-stone muttering in the dark; Torvald on the broken
Wall at night, Aldra beside him silent, a single green shoot in the snow at his feet; Old Vey dozing in a chair with his
sword across his knees; narrator: `Four wizards, four fires, one long winter. And each of them remembered how it began.`
(hands to Ep5-6, the origins); title card `Episode 4 · What Grows Back` (end).

## Win / lose
| Event | Result |
|---|---|
| `obj_spire` done (`e4m4_enough` plays) | **Victory** |
| Ysolde dies | **Defeat** (instant loss) |
| Heartwood destroyed | **Defeat** |
| Fire Keep destroyed / Vessa dies | Nothing (2v2 respawn; E22) |
| Maelis fallen, Treants dead, all soldiers dead | Nothing |
| Torvald killed / Rime Keep destroyed | Not a win (Torvald's 60 s respawn text; if the keep falls he respawns at a Frost Hall, else at `(0, -60)`); the spire is still the goal |

## Reward carried (Ysolde's track ends its episode; Ep6 origins carry nothing, outline D8; the next use is Ep8's Nature road)
- **Heartwood Seed** stays owned. The 6 item slots at victory; essence 50 %, cap 1 500, **+300 first if `sec_elder`**,
  **+300 first if `sec_halls`**.
- `CampaignState.MISSION_REWARDS[&"e4m4"] = {"flags": {"e4m4_elder_woken": "sec_elder", "e4m4_halls_broken": "sec_halls"},
  "bonus_essence": {"sec_elder": 300, "sec_halls": 300}, "next": &"ep4_ending"}`; always-set flags **`ep4_complete`**,
  **`torvald_stayed_aldra`** (Ep7's turn reads it: Torvald's L-lines in e7m3 / e7m4 remember this day), and
  **`elder_treant_unlocked_nature`** (later Nature missions may enable the titan).
- The Theatre reveal `helper_maelis` (unlocked in e4m2) and the Ep4 films (`ep4_opening`, the four `c_e4_*` scenes,
  `ep4_ending`) are listed in the Theatre.
- Level not carried.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Shardguard / Mortar / Colossus | as written | x 1.4 |
| Start crystals | 550 + 2 extra Bramblehorns | 450 | 350, no Briar Roc |
| Wall pieces / gates / Winterheart | 900 / 1 800 / 2 200 HP | 1 200 / 2 400 / 3 000 | 1 400 / 2 800 / 3 600 |
| Wallwarden | 1 900 HP, wake at 16:00 | 2 600, 14:00 | 3 200, 12:00, Stomp every 10 s |
| Wall regrowth | 0.5 % / s | 1 % / s | 1.5 % / s |
| Wizards / Aldra | Torvald L6, Aldra L6 | L7 | L8 |
| Vessa army cap | 22 pop | 18 | 14 |
| Expected time | 20-24 min | 24-30 min | 28-34 min |
**Fight sizing** (normal; every guarded fight and wave <= 70 % of what the player side can have **at that place** then;
wizard worth `170 + 30 x level`, Aldra / Maelis `200 + 40 x level`, Wallwarden 700, Elder Treant 600; Vessa counted only
where her script puts her).
| Fight | When | Enemy | Player side then | Ratio |
|---|---|---|---|---|
| G0 Elder watch | ~2:00-4:30 | 420 (+ 800 HP of totems) | 2 530 + Ysolde L6 (350) + Maelis L6 (440) | 13 % |
| I1 west sortie | 4:00 | 730 | ~2 900 + the free Treant if woken | 22 % |
| S1 Shadow tithe | 7:00 | 795 | Vessa ~1 550 | 51 % |
| G1 West garrison + West Gate | ~9:00-12:00 | 610 (+ 2 400 HP gate at x0.35 / x1.0) | ~3 300 + 1-2 Treants | 18 % (the fight is the gate's EHP and the regrowth) |
| I2 Torvald's sortie | 10:00 | 1 415 (Torvald L7 380) | ~3 300 | 43 % |
| West Wallwarden + G1 rest | ~11:00-13:00 | ~900 | ~3 300 | 27 % |
| S2 Shadow tithe | 15:00 | 1 230 | Vessa ~1 700 + a ~600 detachment | 53 % |
| East Wallwarden + G3 | ~14:00-17:00 | ~1 290 | Vessa ~1 700 + the player's Treant group ~1 500 | 40 % |
| I3 Aldra's glass host (+ Sentinel 330 for 30 s) | 18:00 | 1 710 (Aldra L7 480) | ~3 800 + Treants + Vessa from the east | 45 % |
| G2 Heart garrison + Winterheart | ~18:00-22:00 | 690 (+ 3 000 HP, no attack) | ~3 800 | 18 % |
| Spire guard (+ Sentinel, + the spire) | ~22:00-26:00 | 2 190 + 330 | ~4 000 + Vessa ~1 700 | 44 % |
- The Wall is the puzzle, not the fights: soldiers do 35 % to it and it regrows, so a soldier-only push on a gate
  stalls. The intended answers: Treants (net x1.0, rooted volley over the Wall onto the garrison), Vessa's Ash Hurlers
  (x1.5), Thornburst on a gate (x1.0, also roots the garrison), Pollen Haze over the garrison; then the army kills the
  Wallwarden away from the gate (its 30 m leash).
- A player who skips the Elder Circle can still win on normal with Vessa's Hurlers and spells (~4 min longer).
- Watch in the first playtest: if the West Gate takes over 4 min with one Treant, drop gate HP to 2 000; if the spire
  guard kills Ysolde before she reaches 8 m, widen the goal zone to 10 m.

## Done when (proposed ids; the lead adds them to `waves.md`)
- [ ] **E4M4.M1** (four-wizards-high): `data/maps/hundred_winters.map` 160 x 140, `symmetry=none`, seed 44, snowfields and
  pines, the cliffs beyond |x| 72 north of z 0, the Wall line, gates, towers, alcoves, the Winterheart plinth, both bases,
  Torvald's camp and the Glass Spire at the table's positions +-0.5 m; no south-north path except the gates; Map Lab >= 90.
- [ ] **E4M4.S1** (systems): `missions/mission_e4_04.tscn` + `MissionE404` load the map; 2v2 seats (side 0 player + Vessa,
  side 1 Torvald); start state via `apply_to_start` (Ysolde L6 + 5 points, cap 8; 450 / 150 + carried; 42 / 60; Heartwood
  Seed in slot 1) and the no-save fallback; `WinterWall` pieces / Winter Gates (real doors, L3 factors, Frostbind) with
  the Winterheart regrowth; the Winterheart (invulnerable while a Wallwarden lives); the Sleeping Elder (2 totems, the
  plant rule, a free Treant); guards G0-G3; the thaw; section "Tiers, the helper and the titan" incl. **`titans_enabled`**,
  `lair_max`, `titan_max_trained`. `tests/test_e4m4_s1.gd`: a Thornling does 35 % of its damage to a piece and an Elder
  Treant 100 %; a piece regrows 1 % / s after 8 s while the Winterheart stands and not after; side 1 walks through a gate,
  side 0 is blocked; the Winterheart takes no damage until both Wallwardens die.
- [ ] **E4M4.S2** (systems-high [H]): objectives and events E1-E22, the 37 lines (L22b by flag), waves I1-I3 / S1-S2 / the
  thaw / spire guard / Withdraw, the `sec_halls` -40 % rule, Torvald on the parapet until I2 and his return, Aldra's
  flee-and-return, the goal zone and `e4m4_enough` hand-off, win / lose and difficulty tables,
  `MISSION_REWARDS[&"e4m4"]` + the always-set flags; `CampaignState.MISSION_SCENES[&"e4m4"]`; StoryFlow -> `ep4_ending`.
  Test `tests/test_e4m4_s2.gd`: a scripted run breaks the Wall and reaches the spire, `victory=true`; the save holds
  `ep4_complete` and `torvald_stayed_aldra`.
- [ ] **E4M4.G1** (gameplay): `wallwarden` (stats, Avalanche Stomp with telegraph, titan tag, the 30 m Wall leash brain);
  `titans_enabled` honoured in a mission scene (Elder Circle buildable from the Citadel, Elder Treant trainable, both caps);
  test: the Wallwarden never walks more than 30 m south of the Wall and is immune to Snagroot.
- [ ] **E4M4.A1** (ai): profiles `mission_e4_04_enemy` (defend, 12 soldiers, `defend_radius` 15, never repairs the Wall)
  and `mission_e4_04_ally` (Vessa: 18 pop with 2-4 Ash Hurlers and a Kilnwarden, the 9:00 East Gate push until the East
  Wallwarden dies, then the Heart Gate, the S2 help ping, no helper call); `AIStoryCaster` for Torvald in I2; scripted
  units never join a Commander. Test: Vessa's Hurlers attack the East Gate from >= 11 m.
- [ ] **E4M4.U1** (ui): objectives panel (`Wallwardens 0 / 2`, `Winterheart (frost-bound)` -> `(open)`, the spire line),
  Wall piece / gate / Winterheart HP bars on hover, the Wallwarden boss bar while awake, the Elder Circle in the worker
  build menu, colours for `shade` (Shadow Captain, new), `aldra`, `torvald`, `vessa`, `maelis`.
- [ ] **E4M4.V1** (tech-artist) **[H]**: the frontier (snowfield ground, pines, cliffs), `WinterWall` pieces and Winter
  Gates in the L3 glacierglass look with damage states and breach rubble, wall Rime Spire towers, the Winterheart (pulse,
  crack, shatter), Wallwarden (Rime Colossus kit at 1.6 scale + rune armour + alcove ice face), the Sleeping Elder (an Elder
  Treant inside a translucent ice shell, burst), Aldra's Glass Spire, the meltwater thaw state, `glass_prison` VFX; 0 lights;
  `PERF OK` with I3 and both bots' armies on the field.
- [ ] **E4M4.C1** (four-wizards-high): `e4m4_arrival`, `e4m4_wardens`, `e4m4_thaw`, `e4m4_enough` as cine timelines on
  the mission scene, `cine check` 0 FAIL; fallbacks and skip end states as listed.
- [ ] **E4M4.O1** (Voice Forge agent): the 37 lines (`data/voice/lines/e4m4.json`); `shade` speaks as the Shadow Captain;
  every WAV fits its slot.
- [ ] **E4M4.D1** (game-designer): read the lines in game once; write `ep4_ending` (1:00) from the beats above in the
  `episode3-4-opening.md` format (script + shot list).
- [ ] **Lead**: a scripted headless run on normal (wake the Elder, Citadel, Elder Circle, West Gate, both wardens, the
  Winterheart, the spire) ends `victory=true` in 24-30 game-minutes in 3 / 3 runs; a run with no Elder Circle still wins
  on normal in 3 / 5; Ysolde survives I2 in 5 / 5 runs with the scripted army.

Dependencies: the 2v2 seat API and ally layer (`ai-2v2.md`, 20.A*), the wall system (`walls.md`: pieces, real doors,
factors; step 18b), the Elder Treant and Elder Circle (`cavalry-mounts.md`, step 13), `aldra_story` and
`helper_start_called` (E4M3.G1), Ysolde's track with the Heartwood Seed (E4M3.S2 / I1), `MissionBase`, World Forge map
mode (tool 6).
