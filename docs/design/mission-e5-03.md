# Campaign mission e5m3: "Tombstones by Candlelight" (young Malrik; Episode 5)

Written 2026-10-02 (`campaign-outline.md` 3.5, row 3). Episode 5 "The Spark and the Candle", mission 3 of 4, a
flashback, and the hand-over from Vessa to Malrik. Malrik at thirteen, the gravedigger's son of **Wickmoor**: the
town's Reeve is selling the dead to grave-robbers and has put the blame on Malrik's father, who hangs at dawn. In one
night, with a candle, two dogs and whatever shadows will answer him, Malrik reads three secrets out of the crypts
before the gravewardens catch him. At the end the tall man with the burning hem finds him: "This one, too." The
mission teaches **light and dark**: shadow zones hide his units, lamps and lanterns reveal them, his own candle is a
toggle (see and read, or hide). Target **12-15 min** on normal. Episode rules F1-F11 of `mission-e5-01.md` apply
unchanged. Format `mission-01.md` / `mission-00.md`; numbers `levels.md`, `spells.md`, `fog-of-war.md`,
`market-trade.md` (Magpies). New scene `missions/mission_e5_03.tscn` + `scripts/campaign/mission_e5_03.gd`
(`MissionE503 extends MissionBase`, id `e5m3`). Metres, seconds, `m:ss` of `mission_time()`; `(x, z)`, `+z` = south.
Status: **design only**. Recommended option taken.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | **"Wickmoor"**: a walled churchyard town at night, the `main.gd` generator at 120 x 120 with `MAP_SEED := 5103`, played inside camera bounds x -42..42, z -42..42 (a churchyard wall = baked bound walls, `mission-00.md` pattern); moonlight preset; `FogOfWar.sight_scale[PLAYER] = 0.6` (M0 hook) | Small, dense, readable; reuses M0's night tech |
| D2 | Stealth rule | **Hidden** = a player unit inside a **shadow zone** and **not lit**. Hidden units are seen by enemies only within **2.5 m**; everything else is seen at the enemy's normal sight. **Lit** = inside a lit lamp (r 7), a gravewarden's lantern (r 5), the Reeve's lantern (r 7) or Malrik's own candle (r 4) | One rule, two states, all visible on the ground (dark-violet zone decal vs warm light pools) |
| D3 | Malrik's candle | A toggle on **J** (physical; the STR / INT key, unused in missions) and a button on Malrik's card: **lit** = sight 10, Malrik is lit (r 4), he can **read**; **pinched** = sight 6, he can hide, **snuff lamps** and **call the dark** | Pro. S18 / S21: he reads by one candle, and the dark comes when he pinches it out |
| D4 | No killing | Gravewardens are townsfolk: at 0 HP they are **Out cold** for 45 s (lie down, no death event), then stand at 50 % and walk back to the Lantern House. XP once per warden (first knock-out). Magpies (the robbers) die normally | A 13-year-old's mission stays light; the stealth stays a stealth (the town does not run out of wardens) |
| D5 | Lose | **Malrik caught** = Malrik at 0 HP = defeat (gdd rule; the message is `Malrik was caught`) | The outline's "before the gravewardens catch him" |
| D6 | His army | **Soot and Bramble** (2 Grave Hounds, his father's dogs) and up to **6 Shades** called from 3 old graves (`shade_wild`: Shade numbers that **burn in light**, 8 HP / s) | "The dark itself comes when he calls" (pro. L17), with a cost that keeps the light rule alive |
| D7 | Greed | 6 **grave gifts** (rings, wine, coins in open tombs): useful consumables, but each one taken makes every lantern **+1 m** and counts `e5m3_pocketed`; `sec_hands` fails on the first | Pro. L19 "he is never full", as a choice the player makes |
| D8 | Items | `items_locked = true` (no shop) with the inventory bar **shown** (grave gifts are items); start with 1 Dusk Vial | Consumables without a shop |
| D9 | The finding | Ends with `e5m3_found`: the Master, face unseen, behind the boy among the graves; his line is `ep3_opening` L3's "This one, too." | Canon (ep3 L3, pro. S18) |

## Story setup (briefing text, 3 short paragraphs; after `c_e5_turn`)
1. *Winter, the truce. In the crypt city, Malrik lights a candle and lets it burn longer than he needs to.*
2. Wickmoor buried its dead with their rings on, and lately someone had been taking them back. Reeve Aldous Pike,
   keeper of the lanterns, named the gravedigger, and locked him in the stocks to hang at dawn.
3. The gravedigger's son was thirteen. He knew every grave in Wickmoor by heart, and every dark corner between them.
   He took a candle and his father's two dogs, and went to ask the dead who was lying.

## Map: "Wickmoor" (generator 120 x 120, seed 5103, played inside x -42..42, z -42..42)
Night (moonlight preset of 19.V24, `wick_night`). The churchyard wall (2.5 m stone, baked collider) is the bound.
Clearings: no trees / rocks inside (the generator's trees outside the wall stay as silhouettes).
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Malrik; Soot and Bramble 1.5 m each side) | `(-28, 28)` | - | In the hut's yard (a shadow zone) |
| Gravedigger's hut (decor building) | `(-32, 32)` | 6 | Not targetable; nothing attacks it |
| **Lantern House** (watch-house + bell tower) | `(0, 0)` | 8 | Not targetable; the wardens' home and spawn |
| **The Bell** (read spot) | `(0, 5)` | - | South porch; `obj_bell` |
| The stocks (Malrik's father, actor) | `(4, 7)` | - | Decor actor, no line; freed in `e5m3_found` |
| **C1 Weeping Crypt** | interior centre `(-26, -24)`, door `(-22, -20)` | 7 | Shadow zone r 7; **secret S1** at `(-28, -27)` |
| **C2 Old Ossuary** | interior centre `(24, -26)`, door `(20, -22)` | 8 | Shadow zone r 8; Magpies (G3); **secret S2** at `(27, -29)` |
| **C3 Reeve's Vault** | interior centre `(26, 22)`, door `(22, 18)` | 7 | Shadow zone r 7, under the Reeve's chapel; **secret S3** at `(28, 25)` |
| Street lamps La-Lh (lit, r 7) | `(-14,-12)` `(14,-12)` `(-14,12)` `(14,12)` `(0,-22)` `(0,22)` `(-24,0)` `(24,0)` | 2 | `wick_lamp` props (not targetable); snuff / relight rule below |
| Porch lamps P1 / P2 (lit, r 7) | `(-5, 8)` / `(5, 8)` | 2 | Light the Bell and the stocks |
| Static shadow zones | yews Y1 `(-34,-4)` r 6, Y2 `(34,-6)` r 6, Y3 `(-8,32)` r 6, Y4 `(10,-34)` r 5; mausoleum row `(-14, 24)` r 5; the hut yard `(-30, 30)` r 6; plus C1-C3 interiors | - | Dark-violet ground decal, readable at zoom-out |
| **Old graves** (call the dark) G-W1 / G-W2 / G-W3 | `(-36, 14)` / `(14, -36)` / `(36, 10)` | 3 | Each inside or touching a shadow zone (Y1, Y4, Y2 edges) |
| Tombstones of note T1-T6 (read, +30 XP) | `(-20, 26)` `(-30, -8)` `(-6, -30)` `(10, 30)` `(30, -14)` `(34, 30)` | 2 | Optional lore; epitaph pop-up |
| Grave gifts R1-R6 (D7) | `(-24, 12)` `(-38, -20)` `(8, -26)` `(30, -32)` `(38, 20)` `(12, 34)` | 2 | Gold ring decal r 1 |
Distances (path): hut -> C1 door 49 m, C1 -> C2 door 44 m, C2 -> C3 door 41 m, C3 -> Bell 27 m, hut -> Bell 41 m.

**Lamps.** Snuff: Malrik **pinched** within 3 m for 2 s, or a Shade within 2 m for 2 s (it breathes the flame out).
A snuffed lamp's r 7 ring becomes a **shadow zone**. Relight: a gravewarden passing within 4 m of a dark lamp stops and
relights it in 3 s (the patrol resumes). At "Wickmoor wakes" every lamp relights at once.
**Reading** (`MissionReadSpot`, a `MissionBrazier` variant): Malrik with the candle **lit** within 2 m for **4 s**
(secrets) or **3 s** (tombstones); leaving 2 m or pinching resets it. Only Malrik reads.
**Calling the dark**: Malrik **pinched** within 3 m of an old grave for 3 s: 2 `shade_wild` rise (each grave once).

## Start state
| Item | Value |
|---|---|
| Malrik | **Level 1** (Shadow Lance r1), full HP / mana, **level cap 3**, look `&"young"` (13, F2), candle **lit**; inventory: 1 Dusk Vial |
| Soot and Bramble | 2 Grave Hounds (`grave_hound` numbers, named), commandable, at his sides |
| Crystals / essence | None (no economy, no top-bar resources) |
| Enemy | Patrols, house guard, Magpies (below); Reeve Pike inside the Lantern House |
| Fog | On; sight x 0.6; the 3 crypt doors, the Bell and the 3 old graves explored from 0:00 (`reveal`, r 4) |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | None | All |
| Units | Soot and Bramble; up to 6 `shade_wild` (3 graves x 2) | Training |
| Spells | Shadow Lance (L1), **Soul Siphon (L2+)**; the **Candle** (J) | Umbral Shroud (L4; cap 3) |
| Items | The inventory; grave gifts (D7) | Shops |

### Units in this mission (gameplay)
| Unit | Team | HP / armor / damage / speed / sight | Rules | Value |
|---|---|---|---|---|
| `shade_wild` (Shade numbers) | PLAYER | 110 / 0 / 11 / 4.8 / 8 | **Burns in light**: -8 HP / s while lit (lamp, lantern, candle); a burning Shade trails embers. Hidden in shadow like any unit | 80 |
| `gravewarden` (new) | ENEMY | **150** / 5 / 10 melee (cd 1.2) / 4.6 (patrol 3.2) / **8** | Carries a lantern: lights r **5** around himself (moves with him). **Out cold** at 0 HP (D4). Raises the cry (below) | 80 |
| `reeve_pike` (new, Reeve Aldous Pike) | ENEMY | **600** / 10 / 18 melee (cd 1.2) / 4.8 / 10 | Lantern r **7**. **Bell Lantern** (10 s): raises it, r **9** for 3 s; Shades inside take x2 burn. Out cold at 0 HP = `obj_reeve` | 300 |
| `magpie` (existing) | NEUTRAL (hostile to both) | 140 / 0 / 9 / 5.2 / 10 | Obeys the hidden rule (sees hidden units only within 2.5 m); leash 2x around C2; dies normally | 80 |

### The cry and the alarm ("Hue and Cry", systems)
| Rule | Value |
|---|---|
| Seen | A warden (or the Reeve) has a player unit inside his sight that is **not hidden** (or a hidden one within 2.5 m) |
| Cry | He stops 1 s, bark `"Hoy!"` (Label3D, red), then he and every warden within **20 m** attack-move to the unit's position; alarm **+1** (one cry per warden per 15 s; at most +1 per 10 s for the town) |
| Meter | 0-3, shown as 3 bell icons on the objectives panel; **-1** every 90 s without a cry |
| Wickmoor wakes (meter 3) | Every lamp relights; **Reeve Pike + 4 wardens** leave the Lantern House and attack-move to Malrik's last seen position, refreshed every 5 s, for **90 s**; then the meter drops to 2, the extra wardens go home, the Reeve returns inside. Once per 4 min at most |
| Lose the hunters | Units that become hidden and stay so for 6 s are lost: wardens walk to the last seen spot, search 8 s, resume patrol |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_secrets` | Primary | `Read the Reeve's secrets in the crypts (0 / 3)` | S1, S2, S3 read |
| `obj_bell` | Primary (after `obj_secrets`) | `Ring the Lantern House bell` | Malrik, candle lit, within 3 m of the Bell for 3 s |
| `obj_reeve` | Primary (after `obj_bell`) | `Stand up to Reeve Pike` | The Reeve is out cold |
| `obj_malrik` | Primary, always shown | `Malrik must not be caught` | Malrik at 0 HP = defeat |
| `sec_quiet` | Secondary | `Never wake Wickmoor` | At `obj_bell`, the alarm has never reached 3 (fails at "Wickmoor wakes") |
| `sec_hands` | Secondary | `Take nothing from the dead` | At victory, no grave gift taken (fails at the first) |
The panel also shows a grey counter `Tombstones read n / 6` (no objective).

## Guards, patrols and the AI (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted (no Commander). Patrols walk their loop at 3.2 m/s, stop 2 s at each corner, relight dark lamps on the way.
| Group | Units | Route / spot |
|---|---|---|
| PA north | 2 wardens | `(-14,-12)` -> `(0,-22)` -> `(14,-12)` -> `(0,-6)` -> loop (~70 m, ~25 s) |
| PB west | 2 wardens | `(-24,0)` -> `(-14,12)` -> `(-20,22)` -> `(-30,-8)` -> loop |
| PC east | 2 wardens | `(24,0)` -> `(14,12)` -> `(22,18)` (vault door) -> `(34,-6)` -> loop |
| PD crypts | 2 wardens | Lantern House `(0,-6)` -> C1 door `(-22,-20)` -> C2 door `(20,-22)` -> back (~95 m) |
| G1 house guard | 2 wardens | The porch `(-2, 6)` / `(2, 6)` (static, turn every 6 s) |
| G2 vault guard | 1 warden | Inside C3 at `(24, 21)` (static, lantern lights the vault's door half) |
| G3 robbers | 3 Magpies | Digging in C2 around `(25, -27)` (NEUTRAL, leash 2x) |
| Final | Reeve Pike + G1 (if standing) + 1 Magpie (from the vault) | E12: attack-move to Malrik, refreshed every 3 s |

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E0 | Before the scene | `c_e5_turn` (bridge, 0:30), then the briefing |
| E1 | 0:00 | Cutscene `e5m3_wickmoor` (HOLD 0:12); L1-L4; hint `Malrik's candle: J (or the button on his card). Lit, he sees far and can read. Pinched, he hides in the dark.` |
| E2 | 0:20 | Hint `Violet ground is shadow: there your units are hidden unless a light touches them. Lamps and lanterns show you to the wardens.` |
| E3 | First lamp snuffed | L5; hint `A snuffed lamp leaves a pool of shadow. Wardens relight lamps they pass.` |
| E4 | First old grave called | L6-L7; hint `Shades burn in any light. Keep them in the dark; send them to breathe out lamps.` |
| E5 | First tombstone read | L8 |
| E6 | First cry (alarm 1) | L9; hint `Seen! Get back into the dark and stay there: the wardens lose you after 6 seconds.` |
| E7 | Wickmoor wakes (first) | L10; `sec_quiet` failed |
| E8 | First grave gift taken | L11-L12; `sec_hands` failed; every lantern +1 m (and per gift after) |
| E9 | S1 read | L13; counter |
| E10 | Malrik within 10 m of the Magpies the first time | L14 |
| E11 | S2 read | L15; counter |
| E12 | S3 read | L16; counter; at 3 / 3: L17, `obj_bell` active, hint `The Bell is on the Lantern House porch, between two lamps and two wardens.` |
| E13 | Bell rung | L18-L19; `obj_reeve` active; every window in town lights (decor); the Final group attacks |
| E14 | Malrik reaches level 2 | Hint `Ctrl+Q learns Soul Siphon: Q, then click a crowd. It heals Malrik for half of what it drains.` |
| E15 | A Shade burns in light (first) | L26 |
| E16 | Reeve out cold | Cutscene `e5m3_found` (PAUSE 0:45) with L20-L24; victory at its end |
| E17 | Malrik caught | L25; `obj_malrik` failed; defeat after 3 s |
Secrets in any order; E12's last part fires on whichever is third.

## Dialogue (26 lines + the bridge; 5 s each unless listed; <= 96 characters)
Colours: Malrik `(0.7, 0.3, 1.0)`, Reeve `(0.80, 0.70, 0.45)` (new), Master `(1.0, 0.92, 0.70)`, Narrator
`(0.9, 0.85, 0.7)`. Voice files `data/voice/lines/c_e5_turn.json`, `data/voice/lines/e5m3.json`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Wickmoor buried its dead with their rings on. Lately, someone had been taking them back. |
| L2 | E1 | malrik | They say my father robs graves. My father can't rob a pie off a windowsill. |
| L3 | E1 | malrik | The Reeve hangs him at dawn. So tonight I ask the dead. The dead don't lie to me. |
| L4 | E1 | reeve | Lanterns up, lads! If the gravedigger's brat comes sniffing, bring him to me. |
| L5 | E3 | malrik | There. Dark again. The dark never asks me what I'm doing here. |
| L6 | E4 | malrik | ...Hello. You came when I called. Nobody comes when I call. |
| L7 | E4 | narrator | The shadows of the old graves stood up, and waited for him to speak. |
| L8 | E5 | malrik | "Here lies Edda Brack. She was right about the roof." I believe you, Edda. |
| L9 | E6 | reeve | There! Something in the yews! Hoy! Hoy! |
| L10 | E7 | reeve | Every lantern in Wickmoor, up! Find me that boy! |
| L11 | E8 | malrik | They don't need it any more. I do. That isn't stealing. It's... inheritance. |
| L12 | E8 | narrator | He told himself it was only one ring. It was never only one. |
| L13 | E9 | malrik | A thief's purse, sealed with the Reeve's own seal. You pay robbers, Reeve? |
| L14 | E10 | malrik | Magpies. In my father's ossuary. Digging up my father's work. |
| L15 | E11 | malrik | Every ring in Wickmoor, in one sack. With a receipt. Thieves are so tidy. |
| L16 | E12 | malrik | A ledger. Graves, rings and prices. He sold the dead by the pound. |
| L17 | E12 | malrik | Three secrets. Now the whole town can hear them. Where's that bell? |
| L18 | E13 | narrator | At midnight the bell of Wickmoor rang, and every window in the town lit. |
| L19 | E13 | reeve | Clever boy. Clever boys have accidents in graveyards. |
| L20 | E16 | malrik | You're not one of the Reeve's. Who are you? ...You're very tall. |
| L21 | E16 | master | Reading tombstones by one candle, at midnight. And they told you everything. |
| L22 | E16 | malrik | The dead don't lie. They've got nothing left to want. |
| L23 | E16 | master | This one, too. (3 s) |
| L24 | E16 | narrator | He pinched out his candle. In the dark, he was not afraid. He never had been. |
| L25 | E17 | malrik | Let go! He's lying! He's the one- let GO! |
| L26 | E15 | malrik | Back! Out of the light! It eats you. |
**Bridge `c_e5_turn`** (present day, before the briefing):
| Line | Shot | Speaker | Text |
|---|---|---|---|
| C1 | 1 | narrator | The same winter, far to the east, the other apprentice remembered too. |
| C2 | 3 | malrik | Everyone thinks the dark found me. I found it. By one candle. Let me show you. |
Echoes: L23 is `ep3_opening` L3 ("He said: this one, too."); L21 is pro. L16 ("I found him reading tombstones by the light
of one candle"); L24 is pro. S21 / L20 ("the dark ... could not frighten"); L11-L12 are pro. L19 ("he is never full")
made a choice; L5 is Malrik's love of the dark before he had a word for it; L22 is the root of Ep8's "You made me
hungry" (he says the dead want nothing; he will want everything).

## Cinematic hooks (ENGINE, CinematicPlayer 19.C1; skippable; the mission clock stops while they play)
| Id | Kind | When | Length | Shots | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `c_e5_turn` | ENGINE (bridge, its own scene), **PAUSE** | Before e5m3's briefing | 0:30 | 1) WIDE snow on the crypt city (the `forge_intro_malrik` crypt hall, winter dressing): C1; 2) CU grown Malrik's claw hand pinching a violet candle's wick, then **not** pinching it; the heart-stone on the table pulses amber once; 3) STATIC CU Malrik (present day): C2; match-cut on the candle flame to 4) the same flame in a boy's hand among the Wickmoor graves | - (a film; StoryFlow goes on to the briefing) |
| `e5m3_wickmoor` | ENGINE, **HOLD** | E1 | 0:12 | 1) CRANE down the bell tower past the moon to the lamps and the patrols' lantern pools; 2) LOW on the hut yard: the boy with the candle, two dogs at his heels. L1 | Malrik at `PLAYER_START`, hounds at his sides, candle lit, no orders; patrols at their 0:00 points |
| `e5m3_found` | ENGINE, **PAUSE** | E16 | 0:45 | 1) MS the Reeve on his knees on the porch, lantern rolling away; townsfolk with lamps fill the square (decor actors); the father freed from the stocks; 2) WIDE: the boy turns from the crowd to the dark graves; 3) WS among the graves (the pro. S18 framing at Wickmoor's yew Y3): a very tall shadow with a burning four-colour hem stands behind the boy; face unseen, beard of light; L20-L22; 4) CU the boy looking up: L23; 5) STATIC CU (pro. S21 framing): the boy pinches out his candle; in the dark he is calm, almost smiling. L24; FADE_BLACK | Victory (the scene ends the mission) |
Camera axis for `e5m3_found`: the boy - Master line north-south; cameras on its east side (the `ep3_opening` rule for
Malrik's scenes). Fallbacks: the Master is the prologue's B6 stand-in; townsfolk are 6 `kit:villager` actors.

## Win / lose
| Event | Result |
|---|---|
| `obj_reeve` done | **Victory** after `e5m3_found` |
| Malrik at 0 HP ("caught") | **Defeat** (instant loss rule; message `Malrik was caught`) |
| Soot / Bramble / Shades all dead | Nothing; Malrik can still read and ring |
| Wickmoor wakes | Nothing but danger; `sec_quiet` failed |

## Reward (F1: flags only)
`MISSION_REWARDS[&"e5m3"] = {"flags": {"e5m3_quiet": "sec_quiet", "e5m3_hands_clean": "sec_hands"}, "next": &"e5m4"}`
plus `e5m3_pocketed` (0-6) and `e5m3_tombstones` (0-6). Ep8's Shadow road ("Put Down the Shovel", outline 4.2) may
greet `e5m3_hands_clean` with one Malrik line ("I took nothing from the dead once. Once."); no other effect.

## Economy
None (no crystals, no essence, no training). Progress is XP (patrol knock-outs ~20 each once, Magpies 40 each,
tombstones 30 each, Reeve 150): a careful run reaches **level 2 by ~5:00** (3 tombstones + 2 knock-outs) and **level 3
by the Bell** (S2's Magpies). Grave gifts (D7) give: R1 Dusk Vial, R2 Ember Draught ("grave wine"), R3 Dusk Vial, R4
Ember Draught, R5 Homeward Seal (to the hut), R6 Ember Draught.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Patrol / guard counts | x 0.6 (patrols of 1) | as written | x 1.4 (patrols of 3) |
| Hidden seen within | 2.0 m | 2.5 m | 3.0 m |
| Warden sight / lantern | 7 / 4 | 8 / 5 | 9 / 6 |
| Wardens lose you after | 4 s hidden | 6 s | 8 s |
| Shade burn in light | 5 HP / s | 8 HP / s | 10 HP / s |
| Reeve HP | 450 | 600 | 800 |
| Expected time | 10-13 min | 12-15 min | 14-18 min |
Fight sizing (normal, F10; player: Malrik `170 + 30 x level` + hounds 140 + Shades 80 each):
| Fight | Enemy | Player then | Ratio |
|---|---|---|---|
| A patrol pair (any time) | 160 | 200 + 140 = 340 (+160 per grave called) | 47 % at 0:00, 32 % with 2 Shades |
| G3 Magpies (~7:00) | 240 | ~660 (L2, 4 Shades) | 36 % |
| G2 vault guard + PC passing | 240 | ~740 | 32 % |
| Wickmoor wakes hunt | 300 + 320 = 620 | ~740 | 84 %: **above the rule on purpose**: it is the punishment for being seen three times; the answer is to hide (the 6 s rule), not to fight |
| Final (Reeve + G1 + 1 Magpie) | 540 | ~880 (L3, 6 Shades) | 61 % |
- The Final is fought between two lit porch lamps: Shades burn there unless the player snuffed P1 / P2 first (a Shade
  breathing them out is the cheap answer; the G1 guard sees it unless the hounds pull him off). The Reeve's Bell
  Lantern punishes Shades that stay in his ring. Soul Siphon on the Reeve with the hounds tanking is the intended fight.
- A pure-stealth run (no cry) is possible on all difficulties: every crypt door can be reached through shadow zones and
  snuffed lamps; PD's crypt round is the timing puzzle.
- Watch in the first playtest: if Wickmoor wakes in most first runs, raise the "lose you" time cut to 4 s on normal; if
  the Final is trivial, give the Reeve 2 extra wardens on hard only.

## Target length (normal)
| Part | Time |
|---|---|
| `c_e5_turn` + `e5m3_wickmoor` | 0:42 |
| Three crypts (`mission_time`) | 0:00-10:30 |
| Bell and the Reeve | 10:30-13:00 |
| `e5m3_found` | 0:45 |
| **Total** | **~12-15 min** (outline 3.5: 12-15) |

## Implementation tasks (proposed ids; the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| **E5M3.S1** | systems | Scene + script map part: seed 5103 inside the bound walls, camera bounds, night preset, `sight_scale` 0.6; hut, Lantern House, Bell, stocks; 3 crypts (interior zones + doors); 10 lamps with snuff / relight and the "snuffed ring = shadow zone" rule; 6 static shadow zones (+ decals); 3 old graves (call the dark); 3 secrets + 6 tombstones as `MissionReadSpot`s; 6 grave gifts; `items_locked` with the inventory shown; no economy UI; start state | MissionBase, M0's night tech (19.C7a) | Test `tests/test_e5m3_s1.gd`: table positions within 1.5 m; a Flame Guard stand-in inside Y1 is `hidden` and turns not hidden inside a lit lamp's 7 m; a snuffed lamp's ring reads as shadow; a read spot completes in 4 s with the candle lit and resets when pinched |
| **E5M3.S2 [H]** | systems-high | The hidden rule (D2) as a team-side visibility filter (enemy sight sees hidden units only within 2.5 m); the cry, alarm meter, decay, Wickmoor wakes, lose-the-hunters; patrol routes with lamp relights; guards; objectives and events E1-E17; Final; flags; difficulty | E5M3.S1, E5M3.G1 | Scripted headless runs on normal: (a) a pure-stealth route reads 3 secrets with 0 cries; (b) a direct route triggers wakes and still wins; both `victory=true` in 12-15 game-minutes; Malrik at 0 HP = defeat after 3 s |
| **E5M3.G1** | gameplay | Malrik's **Candle** toggle (J + card button r2c4: lit sight 10 / light r 4 / can read; pinched sight 6 / can snuff and call; 0.5 s pinch animation hook); `shade_wild` (burn 8 HP / s while lit); `gravewarden` (lantern light r 5, Out cold 45 s -> 50 %, XP once); `reeve_pike` (lantern r 7, Bell Lantern 10 s, out cold = objective); Magpies obey the hidden rule | `Unit` statuses, the lit-area query (a `LightPool` group: lamps, lanterns, candle) | Test: a `shade_wild` in a lamp ring loses 8 HP in 1 s and none in shadow; a warden at 0 HP lies down 45 s then stands at 75 HP; J toggles the candle and the reading refuses `"Candle out"` when pinched |
| **E5M3.U1** | ui | Candle button + key label (J through `KeyLabels`), lit / pinched state on Malrik's portrait (a small flame icon), the 3-bell alarm meter, `Tombstones read` counter, epitaph pop-up (2 lines, 4 s), `reeve` name / colour / portrait slot, `Malrik was caught` defeat text | 19.U1 / 19.U3 | Readable at 1600 x 900 and 3440 x 1440; the shadow decal reads against the night ground in a screenshot check |
| **E5M3.C1** | systems-high | `c_e5_turn` (bridge in StoryFlow), `e5m3_wickmoor`, `e5m3_found` with the end states above | 19.C1 / 19.C2 | Skips leave the end states; StoryFlow e5m2 -> `c_e5_turn` -> briefing -> e5m3 |
| **E5M3.V1** | tech-artist | Wickmoor kit: churchyard wall, crypt fronts and interiors (3), Lantern House with bell tower, stocks, gravedigger's hut, yews, mausoleum row, gravestone rows, 6 notable tombstones, `wick_lamp` (lit / snuffed), shadow-zone decal (dark violet, soft edge), grave-gift glint, old open graves with a dark-pool shader; `wick_night` preset | 19.V24 moonlight | 0 dynamic lights except lamps as baked-look emissive pools (no per-lamp `OmniLight3D`; the lit areas are decals + emissive); `PERF OK` at night with 20 units |
| **E5M3.V2** | tech-artist | Characters: young Malrik (E5.V1), the candle in hand (lit / pinched), Soot and Bramble (Grave Hound recolours: one black, one brindle), `gravewarden` (lantern, cudgel, oilskin cloak), Reeve Pike (chain of office, big brass lantern), `shade_wild` burn VFX (ember trail), the Shades rising from a grave, warden "out cold" pose | E5.V1 | Art Lab pass |
| **E5M3.O1** | Voice Forge agent | Render `c_e5_turn.json` (C1-C2) and `e5m3.json` (L1-L26) | E5.O1 (`reeve`), lines frozen | Every WAV fits its slot |
| **E5M3.D1** | game-designer | Read the lines in game; check the wakes rate and the Final from the first playtest | Playtest | Changes written back here |

## Done when (acceptance checks)
- [ ] E5M3.S1: Wickmoor builds inside the wall; every table row within 1.5 m; the hidden / lit rule reads on the ground (violet zones, warm pools) and in tests.
- [ ] E5M3.S2: patrols loop and relight; a cry fires only on a not-hidden unit in sight (or a hidden one within 2.5 m); meter 3 wakes the town for 90 s; the hunters lose a unit hidden for 6 s; E1-E17 in order; victory after `e5m3_found`; defeat when Malrik is caught.
- [ ] E5M3.G1: candle toggle on J (physical) and on the card; Shades burn only in light; wardens never die; the Reeve's lantern doubles the burn.
- [ ] E5M3.U1 / C1 / V1 / V2 / O1: meter, counters, pop-ups, the bridge and two cutscenes with their skip end states, the Wickmoor kit at night, the lines in game.
- [ ] Lead: a scripted stealth run and a scripted loud run on normal both end `victory=true` in 12-15 game-minutes in 3 / 3 seeds; smoke and perf tests pass.
