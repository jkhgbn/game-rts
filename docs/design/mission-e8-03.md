# Campaign mission e8m3: "The Hollow King" (the final battle; Episode 8, the end of the story)

Written 2026-10-02 (`campaign-outline.md` 3.8, 4.2-4.7). Episode 8 "The Four Keys", mission 3 of 3 per playthrough (id
`e8m3`, spec `docs/design/mission-e8-03.md`, scene `missions/mission_e8_03.tscn`, script
`scripts/campaign/mission_e8_03.gd`, `MissionE803 extends MissionBase`). The last mission of the campaign: the four
kingdoms on **Fourfold Hollow** around the **Hollow pit** fight **Obren's last body, the Hollow King** (18 m, the Throne in
his chest, four chains of amber light from the four keyholes to his limbs). Phases **"Four Chains" -> "The King Walks" ->
"Hold Together"**: the four wizards turn their keys **at the same moment**, the Master's light lances up from below, the
King falls, and the closing film `ep8_ending` plays: the last turn, the Master climbs out and lets go, the **player's
choice** (break the throne / take the seat, with a dark tail per kingdom), the fates, and the bookend with the child.
Target **28-35 min** on normal including the mission's own cutscenes (the ending film, 3:40 + choice + credits, is not
counted). Uses `mission-e8-02.md` (seats, `Teams`, Key-Wards, allied safety, `mission_e8` bots), `mission-04.md` (the
Keystone Colossus: Hurl, Quake Stomp, Relic Pull, Rubble Call, Stone Skin, Turn the Key, Hollow Pulse, Vey's grounding),
`mission-e8-01.md` 1.4 (Host types), `t3-helpers.md`, `titans-2.md`, `tiers.md` 6, `cinematics.md`, the outline's 4.3-4.7
(ending script, shot list, choice, dark tails, build list F1-F9). Metres, seconds, `m:ss`; positions `(x, z)`, `+z` =
south. Status: **design only**; nothing here is built. Recommended option taken everywhere (no questions).

## 0. Decisions (recommended option taken)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | **Fourfold Hollow in its pit state**: the isle and moat (r < 14.5) become the **Hollow pit**, a walkable sunken arena (floor 2 m below the banks, a cosmetic lip; the Crown Bridges and Steps become the four ramps and two stairs; no water inside r 14.5). The arms of the Hollowmere stay (`RiverSystem.setup` with the two arms, **no moat**); the four keyholes are where e8m2 lit them | The King must stand where Obren fell; the keyhole ring is already 24.8 m from the centre |
| D2 | Fresh scene, not e8m2's state | e8m3 loads its own start (section 3): bases at the Citadel, armies, **one titan per seat**, helpers, the four Key-Wards lit. Only the **track** (items, key, essence, companion) and the e8m2 flags carry | A crash-safe save point before the finale; e8m2's end state (armies scattered across 168 m) would make the boss unreadable |
| D3 | Seats and sides | As e8m2 (seat table 2.1 from `ep8_road`, all four on side 0, the King and the Host **NEUTRAL**) | Same muster, same colours |
| D4 | The King's HP | **30 000** normal (easy 22 000, hard 40 000), x **(1 + 0.05 x min(`e8_stone_uses`, 5))**, x **1.10** if `e8m2_early_rise` | Outline 4.2 numbers; the stone and the Hollow meter pay off here |
| D5 | How phase 1 is hurt | **Only during Chain Surges** (the four keyholes pull the chains tight together): the King is invulnerable outside them; a Surge fires every **110 s** and lasts **10 s**, and **only while all four Key-Wards stand at >= 50 % HP** | The outline's phase 1 is about the chains; this makes "keep every keyhole healthy, even an ally's" the whole phase and gives one tuning knob |
| D6 | The weakest | "Weakest keyhole" = the lowest HP % Key-Ward; "weakest keep" = the lowest HP % keep of the four (allied keeps keep their 20 % floor); ties -> the player's. Both are shown (a red chain / a red keep marker on the minimap) | The outline: "the player sees which" |
| D7 | The four-key turn | **Hold Together**: one shared ring of four segments; it fills (5 s) only while **all four wizards** stand within 3 m of their own keyholes. Bots stand in their rings through phase 3 unless kneeling. The **Hollow Pulse** resets it unless **every wizard's helper** is within 8 m of its wizard (M4's Vey rule, generalised) | Outline 4.2 phase 3; the player's channel is the one under attack |
| D8 | Allies | Wizards and helpers cannot die (kneel 10 s, return at 50 %); keeps floor 20 %; **Key-Wards can fall** (that is the danger). Bot profile **`mission_e8_king`** (section 6) | Outline: "scripted allies cannot die (the M4 Vey rule)"; the lose rule is about keyholes |
| D9 | Mother Hush | Returns at phase 3 as a **story unit** at the Shadow keyhole (`hush_story` kit at L7, not commandable, cannot die), the promise of `mission-e8-01.md` B L17 | Her arc ends at Malrik's side (ending E19) |
| D10 | Old Vey | Fire's helper as in e8m2 (helper kit); the Fire road's Gathering Storm does not run here | The last turn's lightning belongs to the Master (ending E12) |
| D11 | The last hit | The King at 0 HP does **not** play a death in the mission: the world holds and `ep8_ending` opens on him kneeling with the four keys blazing (its E01 "Now! All four! Together!") | The outline's film starts with the last turn; a second collapse in-engine would repeat it |
| D12 | The choice | Made on the **choice card** inside `ep8_ending` (outline 4.5): `Break the throne` (true ending) / `Take the seat` (dark tail `ep8_dark_<k>`). Both saved (`ep8_choice`), both unlock the Theatre and the other roads; the menu marks the true ending | Outline 4.5 |

## 1. Story setup (briefing; 3 short paragraphs)
1. The four keys turned, and Crown Hollow fell in on itself. Out of the dust climbed the last thing Obren ever built: a
   king of rubble eighteen metres tall, with the Hollow Throne for a heart and four chains of light dragging at his limbs.
2. The chains hold only while the keyholes hold. Every time the four pull together, the King is bound and can be hurt.
   Let one keyhole weaken and the chains go slack; let two fall at once and he is free.
3. Somewhere under the pit, a white-gold light is climbing toward the surface. The Master is coming up. Hold the King
   until he gets there, and then, all four of you, turn the keys together.
Briefing objectives: `obj_rise`, `obj_keys` (`Never let two keyholes fall at once`), `<Wizard> must survive`, `Your keep
must stand`; the line `Every death near the King feeds him.`

## 2. Map: "The Hollow pit" (`data/maps/fourfold_hollow.map` + the `pit` variant layer, 168 x 168)
Fourfold Hollow (`map-2v2.md` 2) with these changes (E8M3.S1 applies them as a layer on the map; the e8m2 objects not
listed are gone):
| Thing | Position | Notes |
|---|---|---|
| **Hollow pit** | Disc r **14.5** at `(0, 0)` | Walkable floor at -2 m; lip and rubble cosmetic; four **ramps** at the Crown Bridge angles 45 / 135 / 225 / 315 deg (8 m wide) and two **stairs** at the Steps `(+-12.75, 0)` (r 3): the only ways in or out for ground units larger than radius 1 (the King uses the ramps) |
| **The Hollow King** | `(0, 0)` | Section 4 |
| **Key-Wards K-A1 / A2 / B1 / B2** | `(-12.75, 21.25)` / `(-12.75, -21.25)` / `(12.75, -21.25)` / `(12.75, 21.25)` | Lit at start (team = seat), **3 000 HP**, armor 20, regen 0.5 % / s with no Host within 12 m; **ring r 3** for the wizard; chain beam to the King's limb (A1 right arm, A2 left arm, B1 left leg, B2 right leg) |
| Host spawn points | The four ramp heads `(+-11, +-11)` and the two stairs | Wardens climb out of the pit; no Hollow Gates in e8m3 |
| River | Arms only: north `(0, -86)`..`(0, -14.5)`, south `(0, 14.5)`..`(0, 86)`, half width 2.5; Saltgate / Millstone Bridges and Reed / Willow Fords as `map-2v2.md` 2.3 | The banks stay two sides of a river for movement only |
| Seats, nodes, houses, halls, taverns, caches | As e8m2 / `map-2v2.md` | Taverns **off** (no hiring in the finale); caches on; Pell at `(-30, 50)` |
| Light | Storm dusk (19.V25 full), the pit's amber glow; at each Chain Surge the four beams flare white-gold; in phase 3 a white-gold glow climbs from the pit floor with each turn | - |
Distances: each keyhole -> the pit rim 10.3 m; keyhole -> King centre 24.8 m (his body radius 4.5: melee must enter the
pit; ranged 9+ can hit him from the lip); A1 hub -> K-A1 62 m; between neighbouring keyholes across the pit 25.5 m
(K-A1 <-> K-B2) / 42.5 m (K-A1 <-> K-A2, along the bank).

## 3. Start state (every seat; the player's from the track)
| Item | Value |
|---|---|
| Player's wizard | **L7 with 6 unspent points** (spell 1 r1), cap 8; slot 1 the key relic (forced); slot 2 as saved; 6 slots; essence 150 + carried; the companion (re-chosen after e8m2) |
| Crystals / pop | **700**; houses as e8m2 (3 built, max 6) |
| Buildings (each seat, complete) | Citadel, 2 Halls, 2 towers, 3 houses, the Lair |
| Army (each seat) | `mission-e8-02.md` 3.1 **+ 25 %** (rounded; ~3 700 crystals) **+ the kingdom's titan** (Cinder Dragon / Nightmare Knight / War Mammoth / Elder Treant, pop counted for the player, pop 0 for allies) at the seat's rally |
| Helpers | All four beside their wizards, at the wizard's level (Vey, Veyra, Aldra, Maelis) |
| Allies | Wizards L7 (`AIStoryCaster` ranks: r3 / r3 / r2), the same army table |
| e8m2 hooks | `e8m2_helped_all`: all Key-Wards start at **100 %** (else **85 %**); `e8m2_early_rise`: King x 1.10 HP |
| Road hooks (player's seat only) | `e8m1_fire_scouts`, Kettlewick Guard (`e8m1_ice_saved >= 30`), hamlet militias (`e8m1_nature_saved`) return as in e8m2 3.2; `e8_stone_uses` -> King HP (D4) |
No save: Vessa's row, key relic only, essence 150 + 1 200, no flags (Key-Wards 85 %, King 30 000).

## 4. The boss: the Hollow King (gameplay, E8M3.G1 [H])
### 4.1 Stats (normal)
| HP | Armor | Crush | Speed | Radius / height | Sight | Team / tags |
|---|---|---|---|---|---|---|
| **30 000** x D4 | 25 | **90** + 50 % splash r 3, every 2.6 s, reach 6 m, x 2 vs buildings | 1.6 m/s (phase 2 only; 2.1 if the right leg is free) | 4.5 / **18 m** | 26 | NEUTRAL, groups `"units"` + `"boss"`, titan tags (CC half, taunt / knockback immune), no kill XP, never counts for victory |
Look (E8M3.V1, shared with the film's F4): the Keystone Colossus language at 1.5x: a giant of the buried throne-hall's
stone (vaults for shoulders, pillars for ribs, a broken rose window for a face over a gap of amber light), the **Hollow
Throne** inside the open chest cage with the heart-stone's twin glowing behind it, four amber chains from wrist and ankle
shackles to the keyholes. States: rise (phase 0), bound (Surge), tear, walk, hurl, stomp, sweep, stagger, kneel (chest
open), exposed (the throne blazes), and the film's kneel / collapse (F4).
### 4.2 Phases
| Phase | From - to | Damage taken | Abilities |
|---|---|---|---|
| **0 "The Stair"** | 0:00 - 4:30 | None (untargetable; he rises from the pit floor, 0.6 -> 1.0 scale) | None; the Host climbs out (5.1) |
| **1 "Four Chains"** | 4:30 - HP 60 % | **x 0** outside Chain Surges; **x 1.0** during a Surge (10 s; one every **110 s** while all four Key-Wards are >= 50 % HP; otherwise it waits and the panel says why) | **Tear** (a beam on the weakest Key-Ward: **40 / s**); **Keystone Hurl** every 10 s (the biggest clump within 32 m of him, 1.6 s telegraph r 4, **90**; the player's clump wins ties); **Rubble Call** every 30 s (4 Wardens at the weakest keyhole's ramp) + 1 Rubble Sentinel every 90 s; **limb attacks** of broken chains (4.3) |
| **2 "The King Walks"** | HP 60 % - 25 % | **x 0.3** (Throne-plate); **Cracked Limb** at 50 % and 35 %: stagger 8 s (no move, no attack), **x 1.0** | Climbs out by the ramp facing the **weakest keep** and walks on it (re-chosen every 60 s); Hurl every 12 s; **Quake Stomp** (3+ enemies within 9 m, every 11 s, 1.2 s ring r 9, **70** + `dazed` 1.0 s / heroes 0.5 s); **Relic Pull** (every 20 s, the nearest wizard within 26 m, the player's on a tie: 1.5 m/s toward him for 3 s; **any spell the pulled wizard casts breaks it**); **Rubble Call** every 25 s (4 Wardens around him) + 1 Sentinel every 75 s; **Hollow Feeding**: every seat unit dying within 20 m heals him **75 HP**; Tear stops; broken-chain limb attacks stay |
| **3 "Hold Together"** | HP 25 % - 0 | **x 0.1** (Stone Skin) except **Exposed** (x 1.0, 10 s) | Kneels at `(0, 0)` (dragged back, E10); **Hold Together** (4.4); **Hollow Pulse** every 8 s (40, r 6 around each keyhole); Hurl at the player's wizard every 10 s; Rubble Call every 20 s: **4 Wardens at the player's keyhole**, 2 at each other keyhole every 30 s; **the Master's lance** on each Exposed (300, ignores armor) |
| Fall | HP 0 | - | World held; the film (D11) |
### 4.3 Chains and limbs
Each Key-Ward holds one chain. A Key-Ward at **0 HP** breaks its chain (snap VFX, message `The <kingdom> chain is broken!
The King's <limb> is free!`) until it is **relit**: after **30 s**, that seat's wizard channels **5 s within 3 m** (no
Host within 8 m) -> the Key-Ward returns at **50 %** and the chain rebinds. While a chain is broken:
| Chain (seat) | Limb | Free-limb attack |
|---|---|---|
| A1 (player) | Right arm | **Throne Sweep**: frontal 120 deg, r 9, **80**, every 14 s |
| A2 | Left arm | Keystone Hurl throws **two** boulders per cast (second at the next-biggest clump) |
| B1 | Left leg | Quake Stomp radius **12** (phase 1 too: every 14 s at the weakest keyhole's ramp) |
| B2 | Right leg | Speed 2.1 in phase 2; in phase 1 he **lurches** 6 m toward the weakest keyhole every 30 s (still inside the pit) |
**Two Key-Wards at 0 HP at the same moment = defeat** (`obj_keys`). One broken chain never ends the mission.
### 4.4 Hold Together (phase 3)
| Rule | Value |
|---|---|
| The ring | Each keyhole shows its own 3 m ring; one **shared** four-segment progress ring under the boss bar |
| Fill | **5 s** while **all four** wizards stand in their own rings (dead / kneeling / pulled out = not standing); leaving resets the shared fill to 0 |
| Pulse | Every 8 s; resets the fill unless **every** wizard's helper is within **8 m** of its wizard (the bots keep theirs at their side; a fallen helper means that wizard cannot ground it: revive it, or start the fill right after a pulse: 5 s < 8 s) |
| A turn | Fill complete -> **Exposed 10 s** (the throne blazes, message `The King is open!`), the **Master's lance** (white-gold beam from the pit floor, **300**), then **6 s** before the next fill can start |
| Bots | Stand in their rings from E10 on; their armies hold their keyholes, and on each Exposed attack-move into the pit and return when it ends |
| Turns needed (normal) | **3-4**: 7 500 HP + Feeding heals, ~2 000-2 400 per exposure (four armies in the pit for 10 s) + 300 lance |

## 5. Host, bots, objectives, events
### 5.1 The Host (team NEUTRAL; normal; easy x 0.6, hard x 1.4)
| Source | When | Units | Target |
|---|---|---|---|
| **Pit tides** | Phase 0, every **60 s** from 0:30 | 8 Wardens + 1 Rubble Sentinel from the ramp facing the target seat | Rotates A1 -> A2 -> B1 -> B2: that seat's Key-Ward, then its hub |
| Rubble Call | Phases 1-3 (4.2) | 4.2 | 4.2 |
| **Last tide** | Phase 2 start | 12 Wardens + 2 Sentinels from all four ramps (3 + 0-1 each) | The nearest Key-Ward |
| Stone-sworn remnant | 9:00 | 4 Shades, 2 Nightbolts, 1 Shadow Knight, 1 Gloom Deacon (Stone-sworn, NEUTRAL) from the Shadow seat's corner | The Shadow Key-Ward |
Host units count nothing on the Hollow meter (there is none in e8m3; Feeding replaces it in phase 2).
### 5.2 Bots (`mission_e8_king`; ai-coder)
| Phase | Behaviour |
|---|---|
| 0 | Defend their quarter and their Key-Ward (35 m); train to 40 pop; their titan guards the Key-Ward |
| 1 | Half the army (and the titan) at the Key-Ward; during a Chain Surge every army within 30 m of the pit attacks the King from the lip / ramps; the wizard **repairs** its Key-Ward by standing at it (Key-Ward regen x 2 within 6 m of its own wizard: 1 % / s, no Host within 12 m); relights its broken Key-Ward at once after the 30 s |
| 2 | The army of the targeted keep's seat + every army within 40 m of the King engages; the others hold their Key-Wards; wizards cast (Thornburst / Flash Freeze / Shroud / Fireball by `AIStoryCaster`); a pulled bot wizard casts its spell 1 to break the Pull |
| 3 | Wizards in their rings (they move only to dodge a telegraph and step back within 2 s); helpers within 6 m; armies on the Key-Wards; on Exposed, attack-move into the pit, back when it ends |
| Pings | Help when its Key-Ward drops under 60 % (max one per 60 s), and when it is the weakest keep in phase 2 |

### 5.3 Objectives
| id | Type | Text | Done when |
|---|---|---|---|
| `obj_rise` | Primary (phase 0) | `The King is climbing: hold the four keyholes (4:30)` | Countdown ends |
| `obj_chains` | Primary (phase 1) | `Strike when the chains pull together (boss bar 100 -> 60 %)` + the Surge timer `Next Chain Surge 0:42` or `waiting: the Ice keyhole is below half` | HP 60 % |
| `obj_walk` | Primary (phase 2) | `Stop the King before he reaches a keep (60 -> 25 %)` | HP 25 % |
| `obj_together` | Primary (phase 3) | `Hold together: all four at your keyholes` + the four-segment ring | HP 0 |
| `obj_keys` | Primary, always | `Never let two keyholes fall at once` | Fails = defeat |
| `obj_wizard` / `obj_keep` | Primary, always | `<Wizard> must survive` / `Your keep must stand` | Fail = defeat |
| `sec_chains` | Secondary | `Keep every chain bound` | No Key-Ward reached 0 HP all mission |
| `sec_fed` | Secondary (phase 2) | `Feed him nothing: he heals less than 1 500 while he walks` | Phase 2 ends with < 1 500 healed by Feeding |
| `sec_titan` | Secondary | `Your titan stands at the end` | The player's start titan (or any titan of the player's) is alive at HP 0 |

### 5.4 Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (StoryFlow: e8m2 -> e8m3 briefing.) Cutscene `e8m3_king` (HOLD 0:40): L1-L6; hint `The King climbs for 4:30. Hold your keyhole. When the chains pull together, strike.` (10 s); `obj_rise` |
| E2 | 0:30 | First pit tide; L7 |
| E3 | 4:30 | **Phase 1**: the King stands, chains taut; boss bar (marks 100 / 60 / 25); L8-L9 |
| E4 | Each Chain Surge (first) | L10 (first only); the four beams flare; message `The chains pull! Strike now!` (3 s) |
| E5 | A Surge waits (first time) | L11 (the wizard whose keyhole is low: by kingdom, or Vey if it is the player's) |
| E6 | A chain breaks (first) / relit (first) | L12 / L13 |
| E7 | 9:00 | Stone-sworn remnant; L14 |
| E8 | HP 60 % | **Phase 2**: cutscene `e8m3_walk` (PAUSE 0:08): L15; Last tide; L16 |
| E9 | Cracked Limb (50 % / 35 %) | Message `The King staggers!`; L17 at 50 % |
| E10 | HP 25 % | **Phase 3**: cutscene `e8m3_chains` (PAUSE 0:12): L18-L19. End state (also on skip): the King at `(0, 0)` kneeling; every Warden and Sentinel within 12 m of a Key-Ward removed (no XP); **every Key-Ward relit / raised to >= 50 %**; every wizard and helper teleported into its own ring's edge; **Mother Hush** spawned at the Shadow keyhole; bots set to phase-3 rules. Then L20-L21 (Hush, Malrik); hint `All four stand at your keyholes. Keep <Helper> beside you: the Hollow Pulse breaks the turn unless every helper grounds it.` (10 s) |
| E11 | 1st / 2nd / 3rd Exposed | L22 (Master) / L23-L24 / L25 (Master) |
| E12 | A Pulse resets a fill (first) | L26 (Vey, or the player's helper's bark if not Fire) |
| E13 | Player's helper falls in phase 3 | L27 |
| E14 | **HP 0** | World held, Commanders paused; `Events.mission_ended(true)`; save with `resume = &"ep8_ending_a"`; StoryFlow -> section 8 |
| E15 | Player's wizard dies | L28 (`<W>`); defeat after 3 s |
| E16 | Two Key-Wards at 0 HP | L29; defeat after 3 s |
| E17 | Player's keep destroyed | Defeat after 3 s |
| E18 | Player's keep the weakest when phase 2 picks (first) | L30 |
Order rule: phase 3 can only start by E10 (HP 25 %), so Hush, the relit Key-Wards and the bots' rings are always there for
the turn.

## 6. Units, tiers, economy
| Item | Value |
|---|---|
| Code | `MissionE803._init`: `tiers_enabled`, `casters_enabled`, `t3_enabled`, `helpers_enabled`, `titans_enabled = true`, `tavern_enabled = false`, `river_enabled = true` (arms only, no moat), camps / beasts / points / trade / research false; `Teams.configure` as e8m2; `_ready`: `max_tier = 3`, all keeps `set_start_tier(3)` |
| Player | The whole kingdom (as e8m2 7); Lair titans from 8:00 (the step-13 floor; the start titan is already there); spells cap 8 |
| Crystals | 700 start; Fourfold nodes (home 2 x 2 000, natural 2 500, Mouth 2 500); ~350 / min |
| Essence (by 30:00) | 150 + carried + trickle ~1 800 + kills ~2 000 = **~4 500-5 500** |
| Expected player army | ~3 700 + titan at 0:00 -> ~6 000 at 15:00 -> ~7 500 at 25:00 |
Items: base shop, Pell, caches; no hiring (D: taverns off), the companion only.

## 7. Dialogue (32 lines + `<W>` sets; 5 s each unless listed)
Speakers (all in `data/voice/cast.json`): `narrator`, `obren`, `master`, `vey`, `vessa`, `malrik`, `torvald`, `ysolde`,
`hush`, `aldra`, `maelis`. `<W>` = the player's wizard (four recordings); kingdom lines marked "(bot)" are said only by an
allied bot wizard. Every line <= 96 characters.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | The last thing Obren ever built climbed out of the dark, and it was wearing his throne. |
| L2 | E1 | obren | A thousand years he held it. A hundred I lay under it. Now I hold everything. |
| L3 | E1 | vey | Chains on every limb. The keys are holding him. Keep the keys standing, and he stays bound. |
| L4 | E1 | vessa | So we hit him when the chains pull. And we don't let go. I can do that. Probably. |
| L5 | E1 | torvald | Hold the line. Ice knows how. The rest of you, copy me. |
| L6 | E1 | malrik | Four people who hate each other, holding one rope. What could possibly go wrong. |
| L7 | E2 | ysolde | They're coming up the ramps. Every keyhole, every side. Hold yours! |
| L8 | E3 | obren | Pull, little keys. Pull all you like. Chains are stone, and stone is mine. |
| L9 | E3 | vey | Watch the chains! When all four pull, he's bound. That's your window. |
| L10 | E4 | `<W>` | Vessa: `NOW! Hit him while he's tied!` · Malrik: `There. Bound. Make it count.` · Torvald: `He is held. Strike, all of you.` · Ysolde: `The roots have him! Now!` |
| L11 | E5 | vey / (bot) wizard | Vey: `A keyhole's below half! The chains won't pull until it's healed!` · Vessa (bot): `My keyhole's cracking! No surge till you help!` · Malrik (bot): `My lock is wobbling. Assistance would be... efficient.` · Torvald (bot): `My ward is failing. Help me hold it.` · Ysolde (bot): `My keyhole's bleeding sap! Please!` |
| L12 | E6 break | obren | One chain gone. One limb free. Feel how much stronger I am already? |
| L13 | E6 relit | `<W>` | Vessa: `Back on! Sorry, chain.` · Malrik: `Relit. Nobody saw that.` · Torvald: `Mended. Slowly. But mended.` · Ysolde: `It grew back. They always do.` |
| L14 | E7 | malrik | More of mine, wearing amber. I'm running out of ways to say I'm sorry about them. |
| L15 | E8 | obren | Enough of your little ring. I will walk to the weakest of you and sit on it. |
| L16 | E8 | vey | He's out! Don't feed him: whatever dies near him, he eats. Fight from range! |
| L17 | E9 | aldra | His leg is cracking! The glass sees it. Again, there! |
| L18 | E10 | maelis | The chains! They're dragging him back! The keys remember who they belong to! |
| L19 | E10 | master | Hold him there. I am almost with you. (from below) |
| L20 | E10 | hush | I said you'd want me back, Bishop. The dark got very loud. |
| L21 | E10 | malrik | It did. Take my keyhole's left side. And Hush... thank you. |
| L22 | E11 1st | master | Again. All four. I am right beneath you. |
| L23 | E11 2nd | obren | His light? HIS? Through MY throne? You'll break it! You'll break everything! |
| L24 | E11 2nd | torvald | Some things should break. Once. Properly. |
| L25 | E11 3rd | master | One more turn, my four. Then I will come up, and we will talk. |
| L26 | E12 | vey | Keep your helpers close! If one of them's away, the pulse breaks the turn! |
| L27 | E13 | vey | Your helper's down! Bring them back, or time the turn right after the pulse! |
| L28 | E15 | `<W>` | Vessa: `Hold... hold it... without me...` · Malrik: `Carry the stone... somebody...` · Torvald: `Too slow... at the end...` · Ysolde: `It grows back... it has to...` |
| L29 | E16 | obren | Two chains, two limbs. I'm free. I was always going to be free. |
| L30 | E18 | vey | He's coming for YOUR keep! Pull back and meet him at the walls! |
| L31 | Cracked Limb 35 % | ysolde | He's bending! Everyone, everything you have! |
| L32 | E3, `e8_stone_uses` >= 3 | obren | You fed me, Bishop. Every time you used me, I grew. Thank you. |
Echoes: L19 / L22 / L25 lead into the ending's E05 ("You did, Obren. It held me twelve years.") and E08 (the climb);
L20-L21 close Hush's arc (`mission-e8-01.md` B L17); L23-L24 seed E15 (the four break the throne); L6 is Malrik's "great
deal of gold" voice; L32 is the Shadow road's cost said out loud.

## 8. Cinematic hooks and the closing film (outline 4.3-4.5 is the script; this section is the wiring)
### 8.1 In the mission (ENGINE on the live scene; skippable; units frozen while they play)
| id | When | Mode / length | Shots | Lines | End state (identical on skip) |
|---|---|---|---|---|---|
| `e8m3_king` | E1 | HOLD 0:40 | 1) CRANE down through storm cloud into the pit; the King's head of rubble rising out of the floor; 2) four quick inserts: each keyhole pillar blazing, its chain snapping taut (2 s each); 3) MS the King's open chest: the Hollow Throne inside; 4) MS the player's wizard at K-A1, 3/4, the relic glowing | L1-L6 | Phase 0, countdown 4:30 at 0:00, camera on the player's wizard |
| `e8m3_walk` | E8 | PAUSE 0:08 | LOW: the King tears his feet out of the pit floor and steps up the ramp facing the weakest keep | L15 | Phase 2, the King on that ramp head |
| `e8m3_chains` | E10 | PAUSE 0:12 | 1) WIDE: the four chains go taut at once and drag the King backwards into the pit; 2) he falls to his knees at the centre; 3) Hush steps out of smoke beside the Shadow keyhole | L18-L19 | E10 end state (5.4) |
| Master's lance | Each Exposed | In-game VFX (no camera) | A white-gold beam from the pit floor through the King's chest, 0.6 s | - | 300 damage applied |
Fallbacks: missing marks or VFX -> the camera on the player's wizard, the lines as dialogue, the King teleported to the
end-state position.

### 8.2 The closing film `ep8_ending` (StoryFlow; content = outline 4.3-4.6; build = outline 4.7 F1-F9)
| Part | Content | Plays when | Skip goes to | Save point (`resume`) |
|---|---|---|---|---|
| `ep8_ending_a` | E01-E13 (0:00-1:50): the last turn, Obren's grace note, the Master climbs out on Vey's arm, "The harder I held, the more it slipped", the lightning goes home, the throne alone on the pit floor | After E14 | `ep8_throne_<k>` | `ep8_ending_a` (set by the mission's save) |
| `ep8_throne_<k>` | E14 (1:50-1:58): `<W>` steps toward the throne, the **temptation line** of the player's kingdom (outline 4.4 table) | After `a` | The choice card | - |
| **Choice card** | `Break the throne` ("Four hands keep the peace, not one.") / `Take the seat` ("Keep the peace yourself."); focus on the first; **no timer, not skippable**; kingdom flavour line under the title from `ep8_throne_<k>` | After the throne shot | - | Writes `ep8_choice` = `&"break"` / `&"take"` at once; `resume` = `ep8_ending_b` or `ep8_dark_<k>` |
| `ep8_ending_b` (canon) | E15-E22 (2:00-3:05): `<W>` "Nobody sits. Not ever again." / Master "Good."; the four break the throne, the relics shatter, Vessa keeps one ember; the fates E17-E21 with **the player's own wizard's fate moved last** (just before E22; a StoryFlow reorder, no new shots); E22 the empty pit with four banners and saplings | `break` | `ep8_bookend` (canon track) | `ep8_bookend` |
| `ep8_dark_<k>` | T1-T4 (~0:45): `<W>` sits; the kingdom's world image (Fire: a sun that never sets; Shadow: quiet obedient streets; Ice: a world frozen still; Nature: green over every road and grave); the three others walk away; the old man closes his eyes, "I know how that tale ends." | `take` | `ep8_bookend` (dark track) | `ep8_bookend` |
| `ep8_bookend` | E23-E25 (3:05-3:40): the ruined orrery dome, one candle, the old storyteller and the child; canon lines (Child: "Were you sad, when they stopped needing you?" / Master: "No. That was the whole point.") or dark lines (Child: "Is the throne still full?" / Master: "For now. Storms come."); in both: the child's **white-gold spark** ("...Well. So that is where it went."), title `FOUR WIZARDS · The End`, sub "The storm chooses its own." | After `b` or the dark tail | `ep8_credits` | `ep8_credits` |
| `ep8_credits` | Credits 2:00 (the prologue's motif, F9) | After the bookend | The end panel (skippable only after a first full viewing, the `ep1_credits` rule) | Cleared at the end |
| End panel | `Episode 8 complete. The story is told.` + mission time, units lost, secondaries, `ep8_choice` (`The throne is broken` / `The throne is full`); buttons `Story menu`, `Theatre` | After the credits | - | - |
End-state rules: the choice card always shows (a skip of `a` or of `ep8_throne_<k>` lands on it); a crash after the
choice resumes on the chosen branch; a Missions-list replay of e8m3 ends on the normal victory screen after E14 (the
film stays in the Theatre, the choice is not asked again). Speakers in the film: `master`, `vessa`, `malrik`, `torvald`,
`ysolde`, `vey`, `obren`, **`child`** (new, outline F7), with the prologue's own L12 WAV reused at E23.

## 9. Win / lose, and the end of the campaign
| Event | Result |
|---|---|
| King HP 0 (phase 3) | **Victory** -> the closing film (8.2) |
| Player's wizard dies | **Defeat** (instant) |
| Two Key-Wards at 0 HP at the same moment | **Defeat** |
| Player's keep destroyed | **Defeat** (phase 2 can walk on it: the darkest risk) |
| An allied wizard / helper kneels, an allied keep at 20 % | Nothing (D8) |
| One Key-Ward at 0 HP | Its chain breaks (4.3); relight after 30 s |
Saved on victory (`CampaignState`, the end of every track): `MISSION_REWARDS[&"e8m3"] = {"flags": {"e8m3_chains_held":
"sec_chains", "e8m3_unfed": "sec_fed", "e8m3_titan": "sec_titan"}, "set_flags": {"ep8_complete": true,
"campaign_complete": true}, "unlock": [&"e8m1_fire", &"e8m1_shadow", &"e8m1_ice", &"e8m1_nature"], "next": &""}`; the choice
card writes `ep8_choice`; the Theatre unlocks `ep8_ending` (both branches once seen, plus `ep8_dark_<k>` for each kingdom
whose dark tail was chosen) and the Story menu marks the true ending (`Break the throne`) with a gold border. No item,
essence or companion carries further (the story ends; the track stays for road replays).

## 10. Difficulty and sizing
| | Easy | Normal | Hard |
|---|---|---|---|
| King HP (before D4 multipliers) | 22 000 | 30 000 | 40 000 |
| Chain Surge every / length | 100 s / 12 s | 110 s / 10 s | 120 s / 9 s |
| Key-Ward HP | 3 600 | 3 000 | 2 600 |
| Tear | 30 / s | 40 / s | 50 / s |
| Hollow Pulse | 9 s | 8 s | 7 s |
| Host counts | x 0.6 | as written | x 1.4 |
| Phase 0 | 3:30 | 4:30 | 4:30 |
| Expected time | 22-27 min | 28-35 min | 33-40 min |
**Expected run on normal** (cutscenes included):
| Phase | Expected | Why |
|---|---|---|
| `e8m3_king` + phase 0 | 0:40 + 4:30 | Fixed; the pit tides teach the four ramps |
| Phase 1 (12 000 HP) | **12-15 min** | ~1 800-2 400 per Surge (four armies and titans at the lip for 10 s) = 5-7 Surges x 110 s, plus waits while a keyhole is below half (~1-3 min on a normal run) |
| `e8m3_walk` + phase 2 (10 500 HP + Feeding) | 0:08 + **3-5 min** | ~40 s to reach a keep; x 0.3 plate with ~500 raw army DPS engaged = ~120 DPS; two staggers at x 1.0 = ~6 000 of the 10 500 |
| `e8m3_chains` + phase 3 (7 500 HP) | 0:12 + **4-6 min** | 3-4 turns at ~70-90 s each (fill, Exposed, 6 s, pulse timing, Rubble Call at the player's keyhole) |
| **Total** | **~25-31**, 35 with a lost chain or a bad phase 2 | The outline's 28-35 |
Fight sizing (normal; the player's own fights; allies hold theirs):
| Fight | When | Enemy | Player then | Ratio |
|---|---|---|---|---|
| Pit tide on A1 | 0:30, 4:30 | 8 Wardens + 1 Sentinel = 1 600 | 3 700 + titan (~700) + wizard L7 + helper | 36 % |
| Rubble Call at K-A1 when it is the weakest + Tear | phase 1 | 600 / 30 s + 40 DPS on the Ward + Hurls | ~4 500-5 500 | ~15-25 % per call, the danger is attrition |
| The King's walk on the player's keep (worst case) | phase 2 | Boss (~120 DPS effective at its target) + 4 Wardens / 25 s | ~6 000 + keep 4 200 HP (Fire Citadel 3 500) + allies within 40 m | Built to feel lost if fought in melee: the answer is range, Pull-breaking spells and staggers |
| Phase 3 at K-A1 | phase 3 | 4 Wardens / 20 s + Hurl 90 / 10 s on the wizard + Pulse 40 / 8 s | ~6 500 | The skill check is staying in the ring with the helper beside, not the damage |
- The intended answers: phase 1 = keep every Key-Ward above half (send a squad to the weakest, even an ally's: the
  Surge waits for all four), save burst spells for the Surge; phase 2 = range and staggers, never a melee ball under him
  (Feeding); phase 3 = helper on Escort, Ember Step / Shroud / Rime Aegis / Thornburst timed against Hurls, never leaving
  the ring.
- Watch in the first playtest: phase 1 is the long one; if it drags past 15 min on normal, shorten the Surge interval to
  95 s before touching the HP; if two-keyholes-down defeats happen in 2 of 5 runs, raise Key-Ward HP to 3 400.

## 11. Acceptance checks
- A scripted headless run on normal for each of the four player kingdoms ends with E14 (`victory=true`) in **28-35
  game-minutes** (cutscenes on fallback cards) in 3 / 3 runs; a fifth run with `e8_stone_uses = 5` and `e8m2_early_rise`
  has a King of 30 000 x 1.25 x 1.10 = **41 250** HP and still wins on normal in <= 38 minutes.
- Phase rules: no damage outside Surges in phase 1; no Surge while a Key-Ward is under 50 %; a broken chain gives exactly
  its limb's attack and loses it on relight; two Key-Wards at 0 HP in the same tick = defeat; one = no defeat.
- Phase 2 walks on the lowest HP % keep (ties: the player's), re-chosen every 60 s; Feeding heals 75 per seat death within
  20 m; any spell cast by a pulled wizard breaks Relic Pull.
- Phase 3: the shared fill needs all four wizards in their rings; a pulse resets it unless every helper is within 8 m of
  its wizard; each completed fill gives Exposed 10 s + 300 lance + 6 s; the E10 end state is identical on skip (King
  position, Key-Wards >= 50 %, Hush present, wizards in rings).
- Allied wizards and helpers never die; allied keeps stop at 20 %; the player's wizard and keep can be lost.
- The film chain plays a -> throne_<k> -> choice -> b or dark_<k> -> bookend (matching track) -> credits -> end panel;
  the choice card cannot be skipped; `ep8_choice` is saved before the branch plays; a forced quit after the choice resumes
  on that branch; the four roads unlock in the Missions list.
- `PERF OK` with the King, 4 x 40-pop armies, 4 titans, 5 story units / helpers and ~40 Host units on screen.

## 12. Implementation tasks (proposed ids; the lead adds them to `waves.md`)
- [ ] **E8M3.S1** (systems): `missions/mission_e8_03.tscn` + `MissionE803`: the pit layer on Fourfold Hollow (pit disc,
  ramps, stairs, arms-only river), seats from `ep8_road`, start state 3 (Citadels, +25 % armies, titans, helpers, Key-Wards
  at 100 / 85 %), the D4 HP multipliers, no-save fallback; test `tests/test_e8m3_s1.gd` (positions, Key-Ward HP, King HP
  formula, no hostility between seats).
- [ ] **E8M3.S2** (systems-high [H]): phases 0-3 driver (`phase_changed`, `exposed_changed`, `chain_broken(seat)`,
  `chain_relit(seat)`), Chain Surge gate, the weakest keyhole / keep pickers, Hold Together (shared ring, pulse rule with
  helpers, turns, lance), Host sources 5.1, E1-E18, Hush's spawn, defeat on two Key-Wards, rewards and the
  `resume = ep8_ending_a` save; test `tests/test_e8m3_s2.gd` for section 11.
- [ ] **E8M3.G1** (gameplay-high [H]): `hollow_king` boss unit (stats 4.1; Tear, Hurl incl. double, Quake Stomp incl.
  r 12, Relic Pull with the any-spell break, Throne Sweep, lurch, Rubble Call, Feeding, Stone Skin, Cracked Limb, kneel,
  Exposed; telegraph hooks for VFX), `KeyWard` building (seat team, HP floor 0 here, regen rules, relight channel); test.
- [ ] **E8M3.A1** (ai-high [H]): profile `mission_e8_king` (5.2): Key-Ward defence and repair-by-standing, Surge
  engagement, phase-2 engage / hold split, Pull-breaking casts, phase-3 ring discipline and Exposed sorties, pings.
- [ ] **E8M3.U1** (ui): boss bar (100 / 60 / 25 marks, phase name), Surge timer or its waiting reason, the four Key-Ward
  HP strip (seat colours, weakest in red), chain-state icons, the shared four-segment ring, Exposed banner, Feeding
  counter for `sec_fed`; `<W>` and bot-only line routing; the **choice card** and end panel (outline F8, layout by
  ui-designer).
- [ ] **E8M3.V1** (tech-artist [H]): the Hollow King game model and states (4.1), shared with the film (outline F4);
  0 lights; Art Lab at 40 m and 15 m.
- [ ] **E8M3.V2** (tech-artist): pit layer (floor, lip, ramps, rubble), chain beams (taut / slack / snap / Surge flare),
  Key-Ward pillar states, the Master's lance, Hollow Pulse rings, Hush's smoke entrance; storm-dusk light.
- [ ] **E8M3.C1** (four-wizards-high, after 19.C1 / 19.C2 and outline F1): `e8m3_king`, `e8m3_walk`, `e8m3_chains`; the
  StoryFlow wiring of 8.2 (a -> throne_k -> choice -> b / dark_k -> bookend track -> credits -> end panel; fates reorder;
  skip and resume rules).
- [ ] **E8M3.VO** (Voice Forge agent): 32 lines + the `<W>` / bot-only sets (`data/voice/lines/e8m3.json`); the film's
  lines are outline F7.
- [ ] **E8M3.D1** (game-designer): read the lines in game; time the phases in the first playtest against section 10 and
  move only the listed knobs.
- [ ] **Lead**: the four kingdom runs, the stone / early-rise run, the film chain, section 11.

Dependencies: `mission-e8-02.md` (seats on one side, Key-Wards, `mission_e8` bots, allied safety), E8M1.G1 (Host types),
step 20 (2v2 seats), steps 13 / 13c (titans), TH (helpers), 19.C1 / 19.C2 (cutscenes), the outline's F1-F9 (the film, the
pit set, the King's film states, the Master "after" and the child, the VFX, the voice incl. `child`, the choice card,
the music cue).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** the kingdom's T3 elite rider: Sunforge Cataphract / Veilborn Dreadrider / Frostcrown Juggernaut / Glade Outrider (spec change: the Stables).
- **Why here:** phase 1 Four Chains: the King tears at the weakest of four far-apart Key-Wards, so elites are the fast reserve; Rubble Sentinels are heavy melee. (The Stormbottle Genie, x1.5 on titans, would also shine here, but taverns are off).
- **Moment:** the first Rubble Call on a ward under 60 %: "Your elite riders: the King's tearing at that chain. Ride.".
- **Intro card:** `Sunforge Cataphract. The best of the Stables: armour, speed, and a hit that ends arguments.` (Fire; the others: `unit-spotlights.md` 2.8)
