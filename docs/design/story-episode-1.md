# Story mode, Episode 1: "The Hollow Throne"

Task 19.D1, written 2026-09-26. Source of truth for step 19 (story side): the Story menu entry, the mission arc, every
cinematic's shot list and every new line of dialogue. The tech of the cinematics (player, camera, letterbox, skip,
video pipeline) is in `docs/design/cinematics.md`. Builds on `mission-01.md` and `mission-02.md` (kept as the opening,
changes listed exactly), `champions.md`, `map-fill.md`, `titans-2.md`, `kingdom-ice.md`, `kingdom-nature.md`,
`items.md`. Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `y = 0`, `+z` = south.
Everything here is original: no names, characters or plots from existing games, books or films.
**This is future work** (step 19, built after steps 12-18). The spec is complete, but nothing here assumes it is built
soon. The **VIDEO cinematics are later production**: they are recorded last (phase 3); until a video exists, the game
shows its fallback text card (section 7.4), so the story always plays start to end.

## 0. User decisions (2026-09-26) and defaults
| # | Question | Decision |
|---|---|---|
| U1 | Length of one cinematic | **1 to 2 minutes max**, short ones are fine. Nothing over 2:00 (every shot list below respects it) |
| U2 | Which kingdom stars | Designer's pick: **Fire / Vessa**. Why, in one line: she is the spark: the most impatient apprentice is the one an enemy fears enough to try to kill first, missions 1-2 already star her, and fire reads best on screen |
| U3 | Premise / tone | **"A war has just begun"**: the opening of the war (the spark, the first battles, the stakes rising), ending on a boss and a hook for Episode 2. War epic with Vessa's humour as the release valve; the jokes thin out as the stakes rise |
| U4 | War shape | **1v1: Shadow against Fire.** Ice (Torvald) and Nature (Ysolde) appear only as set-up: mentions, messages, neutral or uneasy stances. The 2v1 -> 2v2 turn belongs to Episode 2 (section 10) |
| U5 | How the war starts | An **assassination attempt on Vessa**: Malrik's knives strike in the night; it fails, barely; that starts the war. The opening mission (M0) and the intro cinematic (V1) are built around surviving it |
| U6 | The old friend | An **old wizard who fights with a sword**, very strong, with **lightning** attacks (lightning is not one of the four kingdoms' elements: that is his mystery and the reason he was away). Original: **Torren Vey, "Old Vey"**, the Master's old sword (section 2). Set up early, thought lost at the end of M0, he **arrives near the end and saves the day** (M4, VIDEO `m4_storm`), then becomes Episode 2's key ally |
| U7 | How it ends | **Hopeful**: a win that matters (Obren's body is destroyed), the old friend back, a way forward (the Master is alive below; the relics point the way). Episode 2 opens on hope |
| D1 | Episode size (default, see Questions) | **5 missions**: a short prologue M0 (the assassination night, ~10 min), M1, M2 (re-skinned to Shadow), a new M3, a boss M4. Play ~85-110 min + ~17 min of cinematics |
| D2 | Video vs engine (default) | **Hybrid** with **5** videos (later production): the assassination attempt, the twist memory, the boss reveal, the rescue (Torren's return), the ending. Everything else in-engine |

## 1. Premise and stakes
**One paragraph.** The God Wizard (always just "the Master") raised four apprentices, gave each a kingdom, then
vanished between one breath and the next. His regalia fell across the world, and a rumour spread with them: whoever
gathers them becomes the next god. Long before the four, the Master had a sword: **Torren Vey**, an old wizard who
fights with a blade and, strangely, with **lightning**, a power no kingdom has. He taught a girl called Vessa to strike
her first spark, then left without a word to search for the vanished Master. Twelve years later, keeping the old watch
at Emberfall, he writes to her: the crown sealed in the ruins is waking. Vessa rides out. Malrik of Shadow has read the
letter too. That night his knives come for Vessa. **The attempt fails, barely**: Old Vey's sword and a crack of
lightning save her, and before dawn he falls into an amber crack under the ruins and is counted among the dead. Vessa
survives, takes the crown out from under Malrik's nose, and the war between Fire and Shadow begins. She wins her first
battles, but the relics hum, and the hum becomes a voice that keeps telling her where to go next. In the Sighing Wood,
neutral Ysolde shows her the truth: the relics are not a prize but the **lock** of the **Hollow Throne** under Crown
Hollow, where the Master sealed his forgotten first apprentice, **Obren the Mason**. Every battle fought over the
relics near the Master's ruins feeds the Hollow. The war itself is opening the door. At Crown Hollow the door opens,
the Keystone Colossus rises, and just as Vessa's army breaks, a storm tears open the sky: Old Vey, alive, his lightning
renewed by the Master himself, comes back up out of the dark.

| Level | Stake |
|---|---|
| Personal | Vessa never forgave Vey for leaving; he saves her life anyway and is lost. She fights for the crown, for revenge and to prove herself; by the end she learns the voice she trusted was using her, and gets her old teacher back |
| Kingdom | Fire alone against Shadow, which strikes first and without honour; Ice and Nature refuse to take sides |
| World | Obren's return. The war feeds him, and nobody will stop the war |
| Hook (hopeful) | The boss falls: a real win. Malrik slips away with Obren's heart-stone, and Ice and Nature still stand aside, but Vey brings word from below: **the Master is alive, holding the deep door, and the relics now show the way down to him**. "He asked for all four of you." And Vey still owes Vessa an explanation for the lightning |

Episode arc in 4 beats: **Spark** (the assassination attempt: V1, M0; the counter-strike: M1) -> **First battles**
(M2 on Torvald's lake) -> **Twist** (M3, the relics are a lock) -> **Boss and rescue** (M4, the first great battle wakes
the Hollow; Old Vey returns in a storm; hope).

## 2. Cast (original characters)
Speaker ids (used by `Events.dialogue`, `DialogueBox.SPEAKER_COLORS` and the cinematic subtitles). Colours are the
name colour in the dialogue box and subtitles.
| Speaker id | Name shown | Who | Look (existing or new) | Colour | Appears |
|---|---|---|---|---|---|
| `vessa` | Vessa | Fire wizard, the player. Youngest, proud, impatient, funny; throws fire at all her problems | Existing ("the Ember Queen", `art-units.md` 3.1) | `(1.0, 0.45, 0.1)` | All |
| `torren` | Vey | **New. Torren Vey, "Old Vey": the old friend.** An old wizard who fights with a long sword and lightning; the Master's sword and bodyguard since before the four apprentices; Vessa's first teacher ("The spark first, then the storm"). When the Master vanished he left without a word to search for him (twelve years away: Vessa never forgave him), then came back quietly to keep the Emberfall watch. **His lightning is the mystery**: no kingdom has it; he will only say "since before you were born". Saves Vessa from the assassins (V1, M0) with a storm that is fading with age, falls into the Hollow at the end of M0 (thought dead), finds the Master alive below, who renews his storm; returns in M4 (VIDEO `m4_storm`) and turns the battle. Key ally of Episode 2 | New model (19.V20 game, 19.V21 video): about 2.0 m, lean but broad-shouldered, **old and weathered** (seventies), long white beard in one braid, a scar across a milky left eye, a storm-grey long coat over old dented pauldrons, a long straight sword with a blackened blade veined with runes. **M0 look**: the runes flicker weak blue-white, sparks only. **M4 look**: coat torn and frost-rimed from the deep, the blade blazing **white-gold** lightning (the Master's storm), a faint crackle around his shoulders | `(0.95, 0.95, 0.55)` (pale lightning yellow) | V1, M0, M1 (memory), C2 (mention), C3 (hint), M4, V4, V5 |
| `malrik` | Malrik | Shadow wizard ("the Hollow Bishop"). Dry, ambitious; orders the assassination; the enemy of Episode 1; ends it holding Obren's heart-stone | Existing (3.2) | `(0.7, 0.3, 1.0)` | V1, M1-M4, C1, C3, V3, V4, V5 |
| `hush` | Mother Hush | **New.** Malrik's chief assassin, "the knife that never misses" (until tonight). Leads the attempt; flees at the end of M0 (a recurring threat for Episode 2) | New model (19.V23): a tall Shade elite, porcelain-white mask with no mouth, two sickle knives, a cloak that trails smoke | `(0.60, 0.50, 0.75)` | V1, M0 |
| `torvald` | Torvald | Ice wizard. Old, patient; suspects what sleeps under Crown Hollow. **Neutral in Episode 1**: refuses Malrik's offer "for now" (C1), guards his lake against both armies (M2), refuses to take sides (C3), watches the last battle and turns away (V5). In Episode 2 he joins Shadow | Existing (`kingdom-ice.md` 8.2) | `(0.55, 0.80, 1.00)` | C1, M2 (voice), C3, V5 |
| `ysolde` | Ysolde | Nature wizard. **Neutral in Episode 1**: keeps her kingdom out of every quarrel, guards the Signet, tells Vessa the truth, and still refuses to take sides ("when your war comes for my wood, remember I warned you"). In Episode 2 her army is destroyed first and she joins Fire | Existing (`kingdom-nature.md` 7.2) | `(0.55, 0.90, 0.35)` | C2, M3, V2 (voice), C3, V5 |
| `whisper` -> `obren` | `???` until the reveal, then **Obren** | **New.** Obren the Mason, the Master's forgotten first apprentice. Built the Master's towers, the Ruin Wardens and the Hollow Throne; wanted the Master's seat; sealed in the throne a hundred years ago. Speaks to Vessa through the relics | Voice first; in video as a young stonemason-wizard (V2); in play as the **Keystone Colossus** (section 6) | `(1.0, 0.80, 0.25)` (the Ruin Wardens' eye amber: a clue) | M1-M4 (voice), C2, V2, V3, V4, V5 |
| `master` | The Master | The God Wizard. Never named. Seen only in the videos; alive below at the end | **New (video only)**: very tall, hooded, face in shadow except a white-gold beard of light; robe hem burning in four colours (red, blue, green, violet) | `(0.95, 0.93, 0.85)` | V1, V2 |
| `narrator` | Narrator | The chronicle's voice | - | `(0.9, 0.85, 0.7)` | All |
| `ashby` | Captain Ashby | **New.** Corwen Ashby, captain of the Emberguard; Vessa's blunt, loyal officer; arrives with the army at dawn | New model (19.V11): Flame Guard officer, plumed helm, scorched tabard, grey moustache | `(0.95, 0.60, 0.35)` | M0, C2 |
| `pell` | Pell | The Ruin Peddler (comic merchant) | Existing | `(0.85, 0.75, 0.5)` | M1, M2 (flag), C2 (flag), M3 (flag) |
| `bettany` | Bettany Crook | **New.** Keeper of the Crooked Lantern tavern; teaches the champions | Portrait only (19.V6) | `(0.80, 0.65, 0.45)` | M3 |
| `maelis` | Maelis | Maelis Oakenhollow, the Wildcaller (`titans-2.md` 5), Ysolde's warden (neutral here) | Existing design | `(0.60, 0.85, 0.50)` | M3 |
| (barks) | Tamsin, Garran, Sable, Orla (+ siblings) | The four champions (`champions.md` 4) | Existing | - | M3, M4 (their own barks) |

**How Old Vey is set up before he returns** (so the rescue lands): V1 = the letter, the bitter reunion, his motto, a
swordsman standing guard behind the Master (a young Vey, face unseen: the first hint of who he was), the first crack of
lightning; M0 = he fights beside Vessa all night ("You're going to explain the lightning." "Later. Duck."), then falls
(seen, not dead); M1 = Vessa's memory line at the first brazier; C2 = Vessa turns Vey's old sword-knot in her fingers,
"Vey would have laughed at me" (mention); C3 = Ysolde: "something down there is still fighting him" (hint); M4 V3 = a
few frames of white-gold light deep in the split isle (hint). His motto "The spark first, then the storm" is said in V1
and M1 and paid off in V4 and in M4's last exposure. **The lightning mystery** is raised in V1 and M0 and deliberately
left open (V5: "You're going to explain the lightning." "On the way down.").
**How the neutral two are set up for Episode 2**: Torvald says "No. For now." to Malrik (C1), seals his lake against
both armies (M2), refuses again at the parley (C3) and turns away in V5; Ysolde hides the Signet from both (C2), pleads
and warns (M3), refuses at the parley and says her wood will be next (M3, C3), and watches from the treeline in V5.

## 3. The Story menu entry
Main menu: the **Campaign** button becomes **Story**. It opens the Story screen (layout by the ui-designer, 19.U0):
| Element | Content |
|---|---|
| Episode card 1 | Key art (19.V19), `Episode 1 · The Hollow Throne`, one line `Shadow struck first. It missed.`, progress `Mission 2 of 5`, difficulty toggle (Easy / Normal / Hard, shared with the old campaign panel) |
| Buttons | **Continue** (from the save's `resume` point, `cinematics.md` 7), **New episode** (confirm: `Start over? Your Episode 1 progress will be lost.`), **Missions** (the old campaign list: replay a completed mission), **Theatre** (replay seen VIDEO and between-mission cinematics) |
| Episode card 2 | Locked: `Episode 2 · The Light Below`, `Coming later`, greyed. Once Episode 1 is complete it shows the teaser line `The Master is alive. The way down is open.` |
| First start | New episode -> V1 `ep1_intro` -> M0 (no briefing screen: V1 is its briefing; the objectives appear in the panel) |
Under the hood it is still `CampaignState` (`user://campaign.json`); new optional keys in `cinematics.md` 7.

## 4. Mission list
| # | Id | Title | Map | Against | New thing taught | Length (normal) | Difficulty |
|---|---|---|---|---|---|---|---|
| 0 | `m00` | The Night of Knives (prologue) | Emberfall watch, at night | Mother Hush and Malrik's assassins | The wizard under pressure (walk, Fireball, Ember Step away from knives), light against the dark, an ally at your side | 9-12 min | 1 / 5 |
| 1 | `m01` | The Crown in the Ashes | Emberfall, dawn | Malrik (Shadow) | Channelling (braziers), army basics, a timed hold | 15-20 min | 1.5 / 5 |
| 2 | `m02` | The Orb Beneath the Ice | Glasswater Mere (Torvald's lake, neutral) | Malrik's dig expedition (Shadow); Torvald's lake itself | Terrain as a weapon (thin ice), artillery, an escape | 18-24 min | 2.5 / 5 |
| 3 | `m03` | The Signet in the Sighing Wood | Sighing Wood (Ysolde's wood, neutral) | Malrik's forward camp (Shadow) racing you; the wood's neutral guardians; then the Warden tide | **Champions and bounty flags** (Explore, Hunt, Guard), a race | 20-25 min | 3 / 5 |
| 4 | `m04` | The Hollow Throne | Crown Hollow at war | Malrik (Shadow bot) + Obren's Warden host + **the Keystone Colossus** | A 3-way battle, the **Hollow meter** (war feeds the boss), boss phases and telegraphs, the **rescue** (Old Vey's storm) and "Turn the Key" | 22-28 min | 4 / 5 |

### 4.1 Difficulty curve and hero growth
| | M0 | M1 | M2 | M3 | M4 |
|---|---|---|---|---|---|
| Vessa start / cap | **L2 (Fireball r1, Ember Step r1), 45 % HP** / 3 | L1 / 5 | L2 (+1 point) / 6 | **L3 (+2 points) / 7** | **L4 (+3 points) / 8** |
| Artifacts owned | 0 | 0 -> Ember Crown | Crown -> + Stillwater Orb | 2 -> + Master's Signet | 3 (the "key") |
| Player force at the first big fight | 4 Flame Guards + 4 watch archers + Old Vey | ~12 soldiers | ~13 | ~16 + 1-2 champions | ~26 + champions (+ Old Vey in phase 3) |
| Enemy peak | Mother Hush + ~10 assassins | Malrik L4 + 12 | Malrik L5 + 14 + the lake | Malrik L5 + 12 (race), then Warden tide | Malrik L5 base + Colossus 10 000 HP + Wardens |
| New pressure | Survive until dawn, wounded | A timed hold | A timer (the dig) + blizzard | Malrik racing you to the tree | Every death fills the Hollow meter; the Colossus marches on the keep |
Rule kept from M1 / M2: every guarded fight is <= 70 % of the army the player can have at that time on normal; easy
x 0.6 and hard x 1.4 of every count (min 1). M4's phase 2 is meant to feel lost on purpose: the rescue turns it.

### 4.2 Episode flow (what plays in which order; `cinematics.md` 7 has the save points)
`New episode` -> **V1** `ep1_intro` (2:00) -> M0 (**m0_fall**, **m0_dawn**) -> victory -> M1 briefing -> M1 (**m1_seal** at
E6) -> victory -> **C1** `c1_offer` (1:20) -> choice screen -> M2 briefing -> M2 (**m2_heartfrost** at E10) -> victory ->
**C2** (1:30) -> choice screen -> M3 briefing -> M3 (**m3_oldroot**, **m3_plea**, **V2** `m3_memory` 1:00,
**m3_parting**) -> victory -> **C3** (1:45) -> choice screen -> M4 (**m4_war** at 0:00, **V3** `m4_rise` 0:45 at the
Rise, **V4** `m4_storm` 1:45 at the darkest hour, **m4_fall**) -> **V5** `ep1_ending` (1:30) -> credits (1:30) ->
Story menu, Episode 1 complete.

## 5. The missions
### 5.0 M0 "The Night of Knives" (new prologue): surviving the assassination
New scene `missions/mission_00.tscn` + `scripts/campaign/mission_00.gd` (`Mission00 extends MissionBase`, id `m00`).
Target **9-12 min** incl. its cutscenes. 19.D2 writes the full `mission-00.md` build spec from this outline.
- **Map / setting**: Emberfall (the M1 map, `MAP_SEED := 1101`, same generator) the night before M1, played only in
  the player's corner: camera bounds x -58..-8, z 8..58. The Fire keep at `(-43, 43)` is **the Emberfall watch-keep**
  (Vey's post; 2 000 HP; it cannot train). Night: player sight x **0.6** (`FogOfWar.sight_scale`, the M2 blizzard
  hook), moonlight preset (19.V24). No crystals, no shops, `items_locked = true`, essence 0 and no income (nothing is
  carried to M1). An amber crack runs under the keep's courtyard (closed; it opens at `m0_fall`).
- **Start state** (right after V1): Vessa **L2** (Fireball r1, Ember Step r1), **45 % HP**, full mana, level cap 3;
  **Old Vey** (ally, 5.0.1) at her side; Vessa's escort of 4 Flame Guards + 4 watch archers (Ember Archers) in the
  courtyard. Assassins already on the walls.
- **New mechanic taught**: the wizard under pressure. Assassins always go for Vessa, so the player learns to walk her,
  Fireball groups and **Ember Step away** from knives, while lighting 3 **watch braziers** (the `MissionBrazier` rule,
  3 s within 3 m) whose light (sight r 14) shows where the next knives come from. It previews M1's braziers.

#### 5.0.1 Old Vey in M0 (ally, team PLAYER, not commandable): the fading storm
| Stat / ability | Value |
|---|---|
| HP / armor / speed / sight | 1 200 / 25 / 4.8 / 12 |
| **Thunder-edged Blade** (attack) | 30 melee, cooldown 1.2; every 3rd strike a spark jumps to 1 more enemy within 3 m for 20 |
| **Intercept** | Every 8 s, when an enemy that targets Vessa is within 10 m of him: he flickers next to it (a 0.2 s crackle blink) and `taunted` it 3 s |
| Cannot die before the fall | At 1 HP he drops to one knee 5 s, then stands at 40 % HP |
Brain (19.A2): stay 2-5 m from Vessa, between her and the nearest assassin.

#### 5.0.2 Mother Hush (mini-boss, team ENEMY)
| HP | Armor | Attack | Speed | Abilities |
|---|---|---|---|---|
| 900 (easy 700, hard 1 200) | 10 | 28 melee, cooldown 1.0 | 5.2 | **Blink Strike**: every 10 s (hard 8 s) she vanishes and reappears behind the hero with the lowest HP % within 14 m (almost always Vessa): 50 damage, 0.5 s telegraph (a violet ring at the target's feet). **Smoke**: at 50 % HP, `shroud` 4 s and she withdraws 10 m. **Flees** at 25 % HP (walks off the map; never dies in M0; `sec_hush` done) |

**Objectives**
| id | Type | Text | Done when |
|---|---|---|---|
| `obj_dawn` | Primary | `Survive until dawn (8:00)` | The countdown ends (then `m0_dawn`) |
| `obj_vessa` | Primary, always | `Vessa must survive` | Fails = defeat |
| `obj_braziers` | Primary | `Light the watch braziers (0 / 3)` | 3 lit (ring r 10 around the keep, facing the north-east) |
| `sec_hush` | Secondary (from 3:00) | `Drive off Mother Hush` | Hush below 25 % HP |
| `sec_guards` | Secondary | `Keep your escort alive (8)` | At dawn, all 8 still alive |

**Assassin waves** (team ENEMY, scripted, no bot; spawned at the dark map edges north-east / east / north; every wave
attack-moves to **Vessa**, refreshed every 3 s)
| Wave | Time | Units |
|---|---|---|
| A1 | 0:15 | 4 Shades |
| A2 | 1:30 | 3 Grave Hounds + 2 Shades (from two sides) |
| A3 | 3:00 | **Mother Hush** + 4 Shades |
| A4 | 5:00 | 6 Shades + 2 Nightbolts + 2 Grave Hounds (the big push) |
| The fall | 6:40 | `m0_fall` (Old Vey is lost); then **Grief's Fire**: Vessa gets `spell_power` +50 and `mana_regen` +2 for 80 s (modifier `story:grief`) |
| A5 | 7:00 | 5 Shades + 2 Nightbolts |
| Dawn | 8:00 | `m0_dawn`: the Emberguard arrives; living assassins flee; victory 2 s after |

**Scripted events**: E1 0:00 L1-L2, hint `Keep Vessa behind Old Vey's sword. Light the watch braziers to see the knives
coming.` · E1b Vey's first chained spark: L13-L14 · E2 first brazier lit: L3 · E3 A2: L4 · E4 A3: L5-L6 · E5 Hush at
50 %: L7 · E6 Hush flees: L8 · E7 A4: L9 · E8 6:00: L10 · E9 6:40: `m0_fall` then L11 · E10 8:00: `m0_dawn`, victory ·
E11 Vessa dies: L12, defeat.

**Dialogue** (14 lines; 5 s each unless listed)
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | Vey | Stay behind my sword, girl. Knives hate a long reach. |
| L2 | E1 | Vessa | I've been stabbed ONE time and I already hate it. |
| L3 | E2 | Vey | Good. Light pushes back the dark. Always has. |
| L4 | E3 | Vessa | Dogs! Why is it always dogs? |
| L5 | E4 | Hush | Hold still, little queen. It's kinder. |
| L6 | E4 | Vey | Over my dead body, knife-woman. |
| L7 | E5 | Hush | The old man bites. How charming. |
| L8 | E6 | Hush | Another night, little queen. There is always another night. |
| L9 | E7 | Vessa | How many knives does one Bishop OWN? |
| L10 | E8 | Vey | Two more hours, girl. Dawn always comes. It's the one thing it's good at. |
| L11 | E9 (after `m0_fall`) | Vessa | You want me? Come and get me. ALL of you. |
| L12 | E11 | Vessa | Vey... I'm sorry... |
| L13 | E1b | Vessa | You're going to explain the lightning. (4 s) |
| L14 | E1b | Vey | Later. Duck. (3 s) |

**Rewards**: none carried (no items, no essence). `MISSION_REWARDS[&"m00"] = {"flags": {"m0_hush_driven": "sec_hush",
"m0_escort_saved": "sec_guards"}, "next": &"m01"}`. M1 may greet the escort (`m0_escort_saved`: 2 extra Flame Guards
at M1's start, "the ones who stood with you").
**Difficulty**: easy waves x 0.6, Vessa starts at 60 %; hard x 1.4, 35 %, Hush 1 200 HP. Expected 9-12 min on all
(the timer is fixed). Fight sizing: A4 (~780 crystals of Shadow) vs the escort + Vessa + Vey must be survivable with
the 3 braziers lit and Ember Step used well; on normal ~2-4 escort losses.

### 5.1 M1 "The Crown in the Ashes" (existing, `mission-01.md`): the counter-strike
- **Map / setting**: Emberfall at dawn, the morning after the attempt (unchanged map). Vessa's army has arrived; the
  keep is the watch-keep of M0.
- **Objectives / enemies / set piece / reward**: unchanged (3 braziers, the crown, the 2:00 hold vs Malrik; the seal
  breaking is now framed by `m1_seal`; reward the Ember Crown).
- **Story role**: Vessa strikes back the same day and takes the first relic from under Malrik's nose. His vow (L13)
  makes the war official.
- **Exact changes to `mission-01.md`** (task 19.C3):
| # | Where | Change |
|---|---|---|
| 1 | Story flow | M1 now follows M0 (no pre-mission cinematic of its own; V1 plays before M0). Retries and the Missions list play M1 as today |
| 2 | Briefing paragraph 3 | Was `Vessa, the youngest and least patient apprentice, rides out the night she hears of it. Malrik of Shadow got there first and is camped at the far end of the ruins. He cannot light a brazier. She can.` -> **`Malrik of Shadow sent knives in the night. Vessa lived; Old Vey, who saved her, did not come back. At dawn the Emberguard reached Emberfall. Malrik is camped at the far end of the ruins. He cannot light a brazier. Vessa can.`** |
| 3 | Start state | If `m0_escort_saved`: + 2 Flame Guards at `PLAYER_START + (4, -4)` (pop 13 / 20) |
| 4 | E3, after L5 | **New L17**: `vessa`: `Vey taught me to strike my first spark. "The spark first, then the storm," he said. Sorry, old man. Storm first today.` (6 s) |
| 5 | E6 | The seal break plays inside the in-mission cutscene `m1_seal` (0:12, PAUSE mode, section 7.3); `_seal_flash`, L9, L10 unchanged, fired by the cutscene's actions |
| 6 | E7, after L12 | **New L16**: `whisper`: `One.` (3 s) |
| 7 | L14 text | Was `Far away, three apprentices feel the crown wake up, and begin to worry.` -> **`By nightfall every kingdom knew: Malrik had tried to murder Vessa, and failed. The war had begun.`** |
| 8 | After victory (Story mode) | C1 `c1_offer` plays after the victory screen, then the choice screen for mission 2 |
Nothing else changes (objectives, waves, numbers, rewards, flags).

### 5.2 M2 "The Orb Beneath the Ice" (existing spec, re-skinned for the 1v1): First battles
- **Map / setting**: Glasswater Mere (unchanged map, lake, floes, snowbanks, blizzard): **Torvald's** lake, but Torvald
  stays out of the war. **Malrik's dig expedition** camps on the north-east shore and cuts down through the ice for the
  orb; Torvald's ice, sentinels, walls and storms punish both armies.
- **Story role**: the first real battle of the war away from home; Torvald's neutral, uneasy voice sets up Episode 2.
- **Exact changes to `mission-02.md`** (19.D2 rewrites the spec; if M2 is already built from the old spec, 19.C13
  re-skins it; if not, M9.S1-S3 build the revised spec directly). Everything not listed stays (map, floes, thin ice,
  blizzard timing, Heartfrost HP, dig rate, Emberguard blocks, Pell branch, rewards):
| # | Where | Change |
|---|---|---|
| 1 | Enemy side | The Ice base (Rime Keep, Frost Hall, Rime Spire, Snow Lodge) becomes **Malrik's expedition camp**: Dusk Keep (1 800 HP), Gloom Hall, Night Spire, Hovel in the same slots; bot profile `mission_02` = Shadow normal knobs, `min_attack_pop` 99, workers 4, max 8 soldiers at `(30, -30)`. `enemy_kingdom = &"shadow"` |
| 2 | Dig | The 4 dig haulers are **Gloom Thralls**; relief Thralls every 40 s (same numbers) |
| 3 | Guards | G1 2 Shades + 1 Nightbolt · G2 2 Shades + 2 Nightbolts · G3 dig guard 3 Shades + 2 Nightbolts + 1 Shadow Knight, **Malrik** L4 (Lance r2, Siphon r1, Shroud r1) holds `(4, -4)` · G4 3 Ruin Wardens (unchanged) · G5 1 Night Spire (750 HP) + 2 Shades |
| 4 | Heartfrost | Team NEUTRAL (Torvald's old ice); damaged only by Vessa and Ash Hurlers (unchanged); **regenerates 15 HP / s whenever no Fire unit has damaged it for 5 s** (the ice heals itself; was "while Ice units are near") |
| 5 | Waves | W1 5:00 3 Shades + 2 Nightbolts · the Dusk raid branch becomes **reinforcements**: at 8:00, if `m1_outpost_burned` is false, + 3 Shades + 2 Nightbolts + 1 Grave Hound (L6a); if true, nothing (L6b) · W2 9:00 4 Shades + 2 Nightbolts + 2 Grave Hounds · W3 15:00 or Heartfrost < 50 % 3 Shades + 2 Nightbolts + 1 Shadow Knight · Pursuit (E11) 4 Shades + 3 Nightbolts + 1 Shadow Knight + Malrik (L5), at 40 s 2 Shades + 2 Grave Hounds |
| 6 | Torvald's lake (neutral) | The **Sleeping Sentinels** (2 Rime Colossi) are **NEUTRAL** (Torvald's), wake at E11 and fight anything within their 2x leash. The **shore walls** at E11 are raised by Torvald from afar: team **NEUTRAL** Ice Walls (enemy of both; same rows, HP and path test). The **blizzards** are Torvald's storms: sight x 0.5 for **both** teams |
| 7 | Dialogue | L2, L3, L6a, L6b, L8, L10, L11, L12, L14 rewritten below; new L15 (whisper) |
| 8 | Cinematic | E10: the Heartfrost burst plays inside `m2_heartfrost` (0:10, PAUSE); after victory: C2 `c2_two_fronts` |
| 9 | `CampaignState` | `MISSION_ORDER` = `[m00, m01, m02, m03, m04]` (19.C2); `MISSION_REWARDS[&"m02"].next` is already `m03` |
M2 lines after the change (others unchanged):
| Line | Speaker | Text |
|---|---|---|
| L2 | Vessa | Malrik's diggers on Torvald's lake. Torvald must be thrilled. |
| L3 | Torvald | Two children, fighting on my lake. Finish it quickly, and leave my ice alone. |
| L6a | Malrik | More diggers, more knives. You should have burned my hall when you had the chance. |
| L6b | Malrik | Someone burned my barracks, so I brought fewer friends. Very petty. I respect it. |
| L8 | Torvald | That ice has kept a secret for a hundred winters, ember. Think before you melt it. |
| L10 | Torvald | So be it. My lake will see you out. Slowly. |
| L11 | Torvald | Run, little ember. Every relic you carry makes the Hollow hungrier. You will see. |
| L12 | Narrator | Two relics answer to fire. In the north, Ice watches, and says nothing. |
| L14 | Malrik | Patience was never my virtue. Luckily, I brought shovels. |
| L15 (new, E11 after L10) | Whisper | Two. You're doing so well. (3 s) |

### 5.3 M3 "The Signet in the Sighing Wood" (new): the Twist
New scene `missions/mission_03.tscn` + `scripts/campaign/mission_03.gd` (`Mission03 extends MissionBase`, id `m03`).
Target **20-25 min** normal. 19.D2 turns this outline into the full `mission-03.md` build spec (every coordinate
checked against the generator, full difficulty table); the numbers below are the design intent and are binding.

**Map "Sighing Wood"** (120 x 120, the `main.gd` generator, not mirrored, `MAP_SEED := 1303`): Ysolde's border forest,
**neutral ground**. Old Wood biome almost everywhere (`map-fill.md` 3.1), glades around the camps, fireflies, only
broadleaf and old oaks, ruins of the Master's era in the moss. Malrik got here first and built a forward camp.
| Thing | Position | Notes |
|---|---|---|
| Fire keep / Ember Hall / Hearth | `(-43, 43)` / `(-27, 45)` / `(-36, 50)` | Pre-built, complete (M1 layout) |
| Nodes `m3_fire_a` / `m3_fire_b` | `(-46, 34)` / `(-34, 46)` | 1 500 each; expansions `(-50, 8)` 2 000 and `(4, 50)` 1 500 |
| **The Crooked Lantern** (tavern) | `(-15, -15)` | The only tavern. Opens at **0:30**. First hire **0 crystals** + 75 essence ("first drink's on the house"); then the normal 2nd / 3rd prices |
| Pell's stall (flag `m1_peddler_freed`) | `(-21, -9)` | Pell as a `RuinPeddler`; else a Lost Cache there, openable at once |
| **The Oldroot** (the Signet tree) | `(0, 0)`, clearing r 12 | A colossal oak; a **thorn barrier** ring r 7 blocks it (navigation geometry, invulnerable) until the 3 Root Hearts are down |
| **Root Heart RH1 "Mossgate"** | `(-44, -18)` | Wood guardians: 3 Thornlings + 2 Burr Slingers (NEUTRAL) |
| **Root Heart RH2 "Hollowfen"** | `(18, 44)` | Wood guardians: 1 Bramble Spire (540 HP) + 2 Bloomtenders + 4 Thornlings (NEUTRAL); Old Mossjaw roams nearby from 6:00 |
| **Root Heart RH3 "Stagwatch"** | `(44, 14)` | **Maelis Oakenhollow** (Wildcaller, L3) + her 2 Spirit Wolves + 4 Thornlings (NEUTRAL). Fallback if 13c is not built: 2 Bramblehorns + 1 Bloomtender |
| Hint circles | r 15 on the minimap, centred 8 m off each heart | The hearts start unexplored; the circles say "somewhere here" |
| Old Mossjaw's territory | centre `(10, 36)`, r 12 | An Elder Grizzlemaw (`map-fill.md` 5.5 variant B) named "Old Mossjaw", spawns at 6:00, never respawns. Fallback: a Hollow Stag |
| Warden Gate WG1 / WG2 (after the twist) | `(-30, -36)` / `(32, 32)` | Ruins that crack open at E11 (19.V2 look) |
| **Malrik's forward camp** | Dusk Keep `(43, -43)`, Gloom Hall `(27, -45)`, Night Spire `(37, -29)`, Hovel `(50, -46)` | Bot slots H1 / S1 / V1; rally `(30, -30)`; Malrik L4 (Lance r2, Siphon r1, Shroud r1) at his rally |
The wood guardians are **NEUTRAL** (Ysolde's; enemy of both, they fight inside their 2x leash like the M1 wardens):
Malrik's army has to cut through them too.

**Root Heart** (new prop, systems): a pulsing seed-pod 2.4 m tall in a root cradle; team NEUTRAL, a `Building`-like
target (900 HP, armor 0, regen 1 % / s after 10 s undamaged, `counts_for_defeat` false), fog-hidden until explored.
Anyone can bring it down: Vessa's army burns it, **Malrik's drain squads** (Gloom Thralls, 4 damage / s each) drain
it. When the player destroys one, an **Ember Stake** (team PLAYER, 400 HP, pre-built, sight 10, `counts_for_defeat`
false, a Guard-flag target) is planted on the ashes and gives vision over that glade. The barrier withers when all 3
hearts are down (by anyone).

**The race**: when the barrier falls, **Malrik** (L5) and his army march on the Oldroot. If Malrik reaches the Signet
first he **carries** it (the Ember Crown carry rule: dropped where he dies) and walks home; if he reaches the Dusk Keep
with it = **defeat**. Kill him on the way and the Signet drops for Vessa. Why: the race makes the Explore / Hunt /
Guard tools matter (find the hearts on your side first, hunt his drain squads, guard your stakes so you see him come).

**Start state**: Vessa L3 (+2 points), cap 7; crystals 300 (easy 400, hard 250); essence 150 + carried; Keep, Ember
Hall, Hearth; 5 Cinder Hands gathering, 4 Flame Guards, 2 Ember Archers, 2 Blaze Riders, 2 Ash Hurlers at `(-32, 32)`;
pop 19 / 30. Artifacts from the save (crown + orb equipped). `tavern_enabled = true`; trade, camps, beasts (except
Mossjaw), river, research off. No-save fallback: crown + orb owned and equipped, essence 150 + 400.

**Objectives**
| id | Type | Text | Done when |
|---|---|---|---|
| `obj_hearts` | Primary | `Bring down the Root Hearts before Malrik (0 / 3)` | All 3 down (any side); the counter shows who took each (flame or shadow icon) |
| `obj_signet` | Primary (after E10) | `Take the Master's Signet (Malrik is racing you)` | Vessa within 2.2 m of the Signet (or of the dropped Signet) |
| `obj_gates` | Primary (after E11) | `Break the Warden Gates (0 / 2)` | Both gates destroyed |
| `obj_vessa` | Primary, always | `Vessa must survive` | Fails = defeat |
| `sec_champion` | Secondary | `Hire a champion at the Crooked Lantern` | First hire |
| `sec_mossjaw` | Secondary (from 6:00) | `Put down Old Mossjaw` | Mossjaw dies (any credit) |
| `sec_stakes` | Secondary (from the first stake) | `Keep every Ember Stake standing` | Done at E10 if none fell; **failed** when one falls |

**Enemies and waves** (Shadow bot `mission_03`: gathers, trains, defends, `min_attack_pop` 99; scripted waves only)
| Wave | Trigger | Units | Order |
|---|---|---|---|
| Drain squads | 3:00, 7:00, 11:00 | 3 Gloom Thralls + 3 Shades | To the living heart nearest the Shadow camp (RH3, then RH2, then RH1); the Thralls attack the heart, the Shades fight the guardians |
| W1 | 4:30 | 5 Shades + 2 Nightbolts | Attack-move to the Ember Hall |
| Stake raids | 30 s after each Ember Stake is planted | 3 Grave Hounds + 2 Shades | Attack-move to that stake |
| W2 | 2nd heart down (any side) | 6 Shades + 3 Nightbolts + 1 Shadow Knight | Attack-move to the Fire keep |
| The race | E10 (barrier down) | **Malrik (L5)** + 8 Shades + 3 Nightbolts + 1 Shadow Knight | Malrik walks to the Signet, his army attack-moves beside him; with the Signet he walks home |
| Warden tide | E11 until each gate falls | Each gate: 2 Ruin Wardens every 25 s (max 8 alive per gate), team NEUTRAL, `neutral_leash` false | Attack-move to Vessa, refreshed every 3 s; they fight anything on the way (Shadow too) |
Warden gate: 1 800 HP, armor 20, team NEUTRAL, not in `"buildings"`, always visible once the twist plays. Easy 1 400 /
30 s; hard 2 200 / 20 s. After E11 Malrik and his army pull back to their camp (bot defends only; Wardens still attack it).

**Scripted events**
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Briefing (C2 already played); L1-L3 (+ L20 if Pell is there); hint `Hire champions at the Crooked Lantern. Find the Root Hearts in the fog before Malrik does.` |
| E2 | 0:30 | Tavern opens; L4-L5; hint `Y: hire a champion. Champions choose their own jobs; bounty flags (R) pay them to do yours.` (10 s) |
| E3 | First hire | L6; `sec_champion` done; hint `R, then click the fog: an Explore flag. Explorers find the Root Hearts.` |
| E4 | First heart revealed (explored) | L7 |
| E5 | First drain squad seen | L21; hint `Put a Hunt bounty on the drain squad (R, then click a Thrall).` |
| E6 | A heart burned by the player | Ember Stake planted; `obj_hearts` count; first time: L8 + hint `Guard your Ember Stake (R, then click it): it shows you who is coming.`; a stake raid in 30 s. 2nd heart down (any side): W2 |
| E7 | 6:00 | Old Mossjaw spawns; L10; `sec_mossjaw` active |
| E8 | Mossjaw dies | L11; drops a Warden Scale + Vital Root; +150 essence |
| E9 | A Fire unit within 18 m of RH3 (first time) | L12 |
| E10 | All 3 hearts down | L13-L14; `sec_stakes` resolves; cutscene **m3_oldroot**; barrier gone; `obj_signet` active; the race starts |
| E10b | Malrik takes the Signet | L19; objective text `Kill Malrik before he gets home` |
| E11 | Vessa reaches the Signet | Cutscene **m3_plea** (Ysolde steps out of the roots: a neutral, invulnerable story unit) -> **V2** `m3_memory` -> the Signet goes to Vessa's artifact slot 2 for this mission (the M2 rule); L15-L16; Malrik's army pulls back; WG1 / WG2 crack open; `obj_gates` active |
| E12 | First gate destroyed | L17 |
| E13 | Second gate destroyed | Remaining Wardens crumble (1 s); cutscene **m3_parting**; `Events.mission_ended(true)` 3 s after it |
| E14 | Vessa dies | L18; defeat after 3 s |
| E15 | Fire keep destroyed, or Malrik brings the Signet home | Defeat |

**Dialogue** (20 lines; 5 s each unless listed)
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | Narrator | The Sighing Wood has kept out of every quarrel for a hundred years. Today two armies walked in. |
| L2 | E1 | Vessa | Malrik's already here. Of course he is. Then I'll borrow a forest. |
| L3 | E1 | Whisper | The third one sleeps in the old tree. Wake it before he does. |
| L4 | E2 | Bettany | The Crooked Lantern is open! Sellswords, cheap ale, no questions. First hire's on the house. |
| L5 | E2 | Vessa | Sellswords who won't take orders. Perfect. I'll pay them to want what I want. |
| L6 | E3 | Bettany | Mind the flags, Firelady. Coin on a flag is the only order that lot understands. |
| L7 | E4 | Vessa | A heart made of roots, pumping green. That's the most Nature thing I have ever seen. |
| L8 | E6 (first) | Ysolde | Fire and Shadow, burning my wood for a trinket. I will remember you both. |
| L10 | E7 | Narrator | Old Mossjaw wakes in the Hollowfen, and he is hungry. |
| L11 | E8 | Vessa | Somebody tell the sellswords their bounty's ready. And tell the bear I'm sorry. |
| L12 | E9 | Maelis | Turn back, fire-child. The wolves already have your scent. |
| L13 | E10 | Ysolde | Stop, both of you! You don't know what you're opening! |
| L14 | E10 | Vessa | A tree. I'm opening a tree. Before HE does. |
| L15 | E11 | Obren | Three. Thank you, little ember. I'll take it from here. (6 s; first line under the name **Obren**) |
| L16 | E11 | Malrik | Rubble with eyes. Your mess, Vessa. I'll be at my camp, enjoying the view. |
| L17 | E12 | Vessa | One gate down. Stone breaks. Good to know. |
| L18 | E14 | Vessa | Tell Malrik... he still dresses like a funeral. |
| L19 | E10b | Malrik | Mine. Thank you for the escort, little ember. |
| L20 | E1, `m1_peddler_freed` | Pell | A war! Terrible. Wonderful for business. Terrible. (after L3 when Pell is there) |
| L21 | E5 | Vessa | His Thralls are draining the hearts. If he opens that tree first, I lose it. |
(L9 is not used.)

**Rewards / carry-over to M4**
- **Master's Signet** (`masters_signet`, `items.md` Campaign table: `max_hp` +100, `spell_power` +20,
  `cooldown_reduction` +10) owned; equipped in slot 1 by default (crown moves to slot 2, the orb stays owned).
- **Companion** (`champions.md` 11): the choice screen lists the champions hired here: the first real companion.
- `MISSION_REWARDS[&"m03"] = {"artifact": "masters_signet", "flags": {"m3_mossjaw_slain": "sec_mossjaw",
  "m3_stakes_held": "sec_stakes"}, "bonus_essence": {"sec_stakes": 300, "sec_mossjaw": 150}, "next": &"m04"}`.
- The 6 slots, essence 50 % cap 1 500 (the existing rules). Level not carried.

**Difficulty**: easy counts x 0.6, Mossjaw variant A, gates 1 400 HP, drain squads 2 Thralls; hard x 1.4, Maelis L5,
the race army + 1 Knight. Expected: easy 16-20, normal 20-25, hard 24-30 min. Skill check = RH3 (Maelis + wolves): two
champions on a Hunt flag on Maelis plus the army, or Ash Hurlers from outside her 8 m pounce reach; or let Malrik's
drain squad soften her first and take the heart after (the 3-way fight rewards timing).

### 5.4 M4 "The Hollow Throne" (new): the Boss and the rescue
New scene `missions/mission_04.tscn` + `scripts/campaign/mission_04.gd` (`Mission04 extends MissionBase`, id `m04`).
Target **22-28 min** normal. 19.D2 writes `mission-04.md` from this outline (numbers below are binding).

**Map "Crown Hollow at war"**: the skirmish map (`skirmish-1v1.md` layout + `map-fill.md` river Hollowmere, Crown Isle,
crossings, biomes, landmarks) with `river_enabled` true; points, camps, beasts, trade, research, cavalry, titans off;
only the **west tavern** `(-15, -15)` (the companion walks in; hiring stays open). Light: a storm dusk (low sun
`(1.0, 0.72, 0.45)`, violet-grey sky, amber glow from the moat after the Rise; real storm clouds after `m4_storm`).
| Thing | Position | Notes |
|---|---|---|
| Fire keep / Ember Hall / 2 Hearths / Ember Spire | `(-43, 43)` / `(-27, 45)` / slots V1 V2 / S1 | Pre-built |
| Malrik's base | Dusk Keep `(43, -43)`, Gloom Hall, Night Spire, 2 Hovels (bot slots) | Full, bot `mission_04` |
| **The Throne stone** | `(0, 0)` on Crown Isle | Replaces the crown pedestal; channel spot for the isle objective |
| **Keystone Pylons** P1-P4 | P1 west bank 8 m beyond the West Crown Bridge, beside the lane; P2 player bank at Reed Ford's west side `(-13, -34)`; P3 / P4 = point mirrors (east bank) | Rise from the ground at the Rise. 19.D2 checks lane / ford clearance (>= 2 m from the lane edge, >= 6 m from a crossing centre) |

**Start state**: Vessa L4 (+3 points), cap 8; crystals 400; essence 150 + carried; 6 Cinder Hands, 8 Flame Guards,
5 Ember Archers, 2 Blaze Riders, 3 Ash Hurlers; pop 26 / 40; companion from M3 beside Vessa. Shadow: Malrik L5,
6 Thralls, 8 Shades + 4 Nightbolts + 2 Shadow Knights at his rally; the **isle guard** 6 Shades + 3 Nightbolts holding
Crown Isle until 5:00 (then they join the bot). No-save fallback: 3 relics owned (Signet + Crown equipped), essence
150 + 600, no companion. No allied wizard (the 1v1 rule).

#### 5.4.1 Old Vey returns (arrives in V4; ally, team PLAYER, not commandable): the renewed storm
His kit for the rescue and phase 3. Numbers are level-free (a story unit); `spell_power` does not apply.
| Stat / ability | Value |
|---|---|
| HP / armor / speed / sight | 1 600 / 25 / 5.0 / 14 |
| **Thunder-edged Blade** (attack) | 40 melee, cooldown 1.2; every 3rd strike **chains** to 2 more enemies within 5 m for 25 each |
| **Lightning Lunge** | Every 12 s: dashes up to 10 m through enemies to a target (the Warden nearest Vessa, else the biggest threat): 60 to the target, 30 + `dazed` 0.5 s to every enemy on the path |
| **Chain Lightning** | Every 8 s: a bolt that jumps 5 times between enemies within 8 m of each other: 45, 38, 32, 27, 23 (x 0.85 per jump); **x 2 against Ruin Wardens** (lightning shatters bound stone) |
| **Charged Ground** (aura r 10, always on) | Ruin Wardens inside take **20 damage / s** and **cannot rise** inside it; own units inside attack 15 % faster (`attack_cooldown_pct` -0.15, modifier `aura:charged`). Look: a crackling white-gold ring on the ground (emission, 0 lights, 19.V25) |
| **Ground the Pulse** | While Vey is within **8 m** of Vessa, the Colossus's Hollow Pulse no longer resets Turn the Key (he takes the pulse into his blade) |
| **Stormcall** (ultimate) | Every 45 s, autocast when 6+ enemies are within 14 m or the moment the Colossus becomes Exposed: 8 bolts fall over 3 s on enemies within 14 m, 60 each (x 2 on Wardens), and if the Colossus is Exposed, **one great bolt of 300** on it. In V4 the same storm, at full scale, is the rescue itself |
| Cannot die | At 1 HP he drops to one knee 10 s (the blade dims, L23, message `Old Vey is down! The storm will return.`), then stands at 50 % HP. A scripted saviour never causes a defeat |
Brain (19.A2): stay 3-6 m from Vessa, lunge at whatever threatens her, move with her to the Colossus in phase 3.
Why: the rescue must be felt in play, not only seen. Before he comes, phase 3's mechanic (Turn the Key) would be near
impossible under the Warden flood; with him, it becomes a tense but fair dance, and Stormcall on every exposure makes
each turn of the key a thunderclap.

#### 5.4.2 The Hollow meter (the war feeds the boss)
`hollow` 0-100 %, shown from 0:00 in the objectives panel (`The Hollow stirs: 37 %`). +**1 %** per unit death on the
map (soldiers, workers, champions, any team; not Wardens, not Saplings), +**8 %** per Malrik death, +**0.1 % / s**.
Messages at 25 / 50 / 75 % (L5 at 50 %, L6 at 75 %). **The Rise** happens at 100 %, or at once when Vessa takes the
Master's seat (the isle objective), whichever comes first. Expected Rise: 8:00-11:00. The meter is hidden after the Rise.

#### 5.4.3 Phases and objectives
| Phase | Objective shown | What happens |
|---|---|---|
| 0 "The War" (0:00 - Rise) | `obj_isle` `Take the Master's seat on Crown Isle` (Vessa within 3 m of the Throne stone for 3 s, no Shadow unit on the isle; the brazier channel rule) · `obj_vessa` · `obj_keep` `The Fire keep must stand` | A normal battle vs Malrik (bot attacks from ~6:00, `min_attack_pop` 14); the isle guard holds until 5:00. The Hollow meter climbs |
| The Rise | - | **V3** `m4_rise` (0:45). End state: the isle guard is gone (buried), Vessa stands at the West Crown Bridge `(-11, 11)`, the 4 pylons stand, the Colossus stands at `(0, 0)`, Warden spawns start |
| 1 "The Ward" | `obj_pylons` `Break the Keystone Pylons (0 / 4)` | The Colossus is invulnerable (Keystone Ward, golden tethers) and stays on the isle, throwing Keystone Hurls. Each pylon spawns Wardens. Malrik's army attacks P3 / P4 (scripted, 19.A1: he wants the giant gone too) and still raids the player every 180 s (4 Grave Hounds) |
| 2 "The Hollow Walks" (100 % -> 40 % HP) | `obj_colossus` `Stop the Keystone Colossus` (boss bar) | The ward breaks: the Colossus walks to the Fire keep (West Crown Bridge, then the lane), crushing whatever blocks it. At 70 %: **Cracked Leg** (section 6). At phase start: a Shadow push (6 Shades + 2 Knights) attack-moves on the Fire keep from the north. Rubble Call every 30 s. This phase is built to feel like the battle is being lost |
| **The darkest hour** | - | Trigger: Colossus HP <= 40 % **or** Fire keep HP <= 50 %, whichever comes first (phase 2 only). L14 (3 s), then **V4** `m4_storm` (1:45). End state: the Colossus kneels where it stands with its chest open (HP set to `min(current, 40 %)`: Vey's great bolt deals the rest), every Ruin Warden within 25 m of Vessa is destroyed, Old Vey stands 3 m from Vessa, Vessa's mana is refilled to 50 %, storm clouds hang over the map for the rest of the mission (19.V25) |
| 3 "The Spark and the Storm" (<= 40 % -> 0) | `obj_key` `Turn the key: Vessa by the Colossus's heart, with Old Vey beside her` | Stone Skin; Vessa's channel exposes the heart; Vey's storm holds back the Wardens, grounds the pulse and strikes every exposure (5.4.1). L15 on start; hint `Stand within 4 m of the Colossus for 3 s with Vessa. Keep Old Vey close: the Hollow Pulse can't break the key while he grounds it.` (10 s) |
| Victory | - | HP 0: `m4_fall` (0:06) -> **V5** `ep1_ending` -> credits |

**Win / lose**: Colossus destroyed = **victory**. Vessa dies = defeat (instant). Fire keep destroyed = defeat (the
darkest-hour trigger at 50 % keep HP gives one rescue first). Old Vey cannot die. Malrik dies = respawns at the Dusk
Keep after 60 s (`Malrik has fallen back into the shadows`). Destroying Malrik's base is allowed but not required.

**Dialogue** (22 lines; 5 s each unless listed)
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | `m4_war` | Narrator | Crown Hollow. Where the Master once sat, two armies wait for the sun. |
| L2 | `m4_war` | Malrik | Three relics, little ember. Hand them over and I'll let you keep the hat. |
| L3 | `m4_war` | Vessa | Come and take them, Bishop. You owe me for Emberfall. And for Vey. |
| L4 | `m4_war` | Whisper | Yes. Come, both of you. Fight on my roof. |
| L5 | Hollow 50 % | Obren | Yes. Fight. Every fallen soldier is a step on my stair. |
| L6 | Hollow 75 % | Vessa | The ground is breathing. That can't be good. |
| L7 | After V3 | Obren | A hundred years in the dark. I had time to practise my entrance. |
| L8 | After V3 | Vessa | I had ten minutes to practise running. Those pillars feed it. Break them all! |
| L9 | Phase 1, 20 s in | Malrik | A giant made of rubble, in MY war? Shades, kill the pillars. Then kill Vessa. |
| L10 | 2nd pylon down | Vessa | Two down. Keep hitting the glowing parts. It's always the glowing parts. |
| L11 | Phase 2 start | Obren | Enough. I will walk to your little fire and put it out myself. |
| L12 | 70 % (Cracked Leg) | Obren | This body... cracks... No matter. Stone is patient. |
| L13 | Fire keep under 30 % | Vessa | Not the keep! I JUST had it redecorated! (4 s, once) |
| L14 | Darkest hour (before V4) | Vessa | Everyone, back to the keep! BACK! (3 s) |
| L15 | After V4 | Vey | Stay close, girl. Whatever it throws at you, I'll ground it. |
| L16 | First exposure | Vessa | Crown, orb, signet. Let's see what you do together. |
| L17 | Second exposure | Obren | His storm? Impossible! That light should have faded a hundred years ago! |
| L18 | Second exposure | Vessa | Nobody stays faded around here. Ask Vey. |
| L19 | Third exposure | Vey | The spark was yours, Vessa. NOW the storm! |
| L20 | Vessa dies | Vessa | Somebody... finish my war... |
| L21 | `m4_fall` | Obren | The Hollow... remembers... (3 s) |
| L23 | Vey kneels | Vey | Just resting my knees. Keep turning that key! (4 s) |
(L22 is not used. The companion speaks through its own `champions.md` 4.5 barks.)

**Rewards / Episode 2 carry-over**: flag `ep1_complete`; the 3 relics stay owned; the 6 slots, companion, essence
(the usual rules) are saved for Episode 2; flags `m4_malrik_pylons` (Malrik's army broke P3 or P4),
`ep1_vey_returned` (always true: Episode 2 starts with Old Vey). The Theatre unlocks everything seen; Episode card 2
shows its teaser. No new artifact: Obren's heart-stone (the **Keystone Shard**) goes to Malrik in V5 (Episode 2's
rival thread), while the three relics wake to the Master's light (Episode 2's goal).

**Difficulty**: easy counts x 0.6, Colossus 7 500 HP, Hurl 55, the Rise at Hollow 120 %; hard x 1.4, 12 500 HP, Hurl 85,
Malrik L6, pylons 1 700 HP, Vey's Stormcall every 60 s. Expected: easy 18-22, normal 22-28, hard 26-34 min.

## 6. The boss: Obren, the Keystone Colossus
**Who**: Obren the Mason, sealed a hundred years in the Hollow Throne, rises in a body built from the Master's ruins:
the 8 pillars of Crown Isle fused into ribs, the Throne itself as the chest cage, his amber **Heart-Keystone** inside.
He wants the relics Vessa carries (the key), so he always goes for her and for her keep. Unit: team **NEUTRAL** (enemy of
both Fire and Shadow: a true 3-way fight), `neutral_leash` false, group `"units"` + `"boss"`, titan tags
(`cavalry-mounts.md` 3.4: crowd control half, taunt and knockback immune, no veterancy), never counts for victory.

### 6.1 Stats (normal; easy / hard in 5.4)
| HP | Armor | Attack "Crush" | Speed | Radius / height | Sight | Kill XP |
|---|---|---|---|---|---|---|
| **10 000** | 25 | 60 to its target + 50 % splash r 2, every 2.4 s; x 2 vs buildings | 1.4 m/s (phase 2 only) | 3.0 / 12 m | 20 | none (the episode ends) |

### 6.2 Abilities (every one has a readable ground telegraph: red-amber fill, 19.V3)
| Ability | Phases | Rule |
|---|---|---|
| **Keystone Ward** | 1 | Invulnerable while any pylon stands; golden tether from each pylon to its chest. Pylon: 1 400 HP, armor 20, NEUTRAL, spawns 2 Ruin Wardens every 35 s (max 6 alive each) |
| **Keystone Hurl** | 1, 2, 3 | Every 9 s (phase 2: 12 s, phase 3: 10 s): lobs a boulder at the biggest clump of PLAYER or ENEMY units within 30 m (Vessa's clump wins ties); **1.6 s telegraph circle r 3.5**, then 70 damage in the circle (buildings x 1) |
| **Quake Stomp** | 2 | Every 11 s when 3+ enemies are within 7 m: **1.2 s telegraph ring r 7**, then 55 damage + `dazed` 1.0 s (heroes 0.5 s) |
| **Relic Pull** | 2 | Every 20 s if Vessa is within 22 m: an amber tether pulls her toward it at 1.5 m/s for 3 s (her orders are held; she can still cast); **Ember Step breaks it**. Message first time `Obren pulls at the relics! Ember Step breaks the tether.` |
| **Rubble Call** | 2, 3 | Phase 2: every 30 s, 3 Ruin Wardens rise within 6 m. Phase 3: every 20 s, 4 (never inside Vey's Charged Ground) |
| **Cracked Leg** | 2, at 70 % | Staggered 8 s (no move, no attack), takes x 1.25 damage; message `The Colossus staggers!`; L12 |
| **Stone Skin** | 3 | Kneeling, immobile; takes **x 0.1** damage except while Exposed |
| **Turn the Key** (Vessa) | 3 | Vessa within 4 m of the Colossus for 3 s (progress ring; the `MissionBrazier` rule: leaving 4 m resets it) -> **Exposed** 10 s (normal damage, the heart glows, message `The heart is open!`), then 6 s before the next turn can start |
| **Hollow Pulse** | 3 | Every 7 s: 40 damage r 5 around it and **resets any Turn the Key in progress, unless Old Vey is within 8 m of Vessa** (Ground the Pulse) |
| **Old Vey's storm** | 3 | 5.4.1: Charged Ground holds the Wardens back; Stormcall's great bolt (300) lands on each exposure when ready |
Expected normal fight: phase 1 ~4-6 min (pylons), phase 2 ~2-3 min until the darkest hour, phase 3 ~2-3 min (4 000 HP,
about **3 turns** at ~150 army DPS during 10 s windows plus Vey's bolts).

### 6.3 Arena and look
Crown Isle (r 11) and its moat are the pit of the Hollow Throne after the Rise: the pedestal and pillar ring are gone,
a cross-shaped crack glows amber, the moat water glows (19.V4). Phase 2 happens along the West Crown Bridge and the
lane to the Fire base (61 m): the base itself is the phase 3 arena on most runs, so Vey's storm breaks over the
player's own home. The Colossus model (19.V1): a 12 m stooped giant of mossy ruin blocks held by amber light (the Ruin
Warden language scaled up: floating head over a gap of amber light), pillar ribs, the Throne as a chest cage with the
Heart-Keystone behind it, one arm ending in a broken capital (the Warden's mace, huge). States: walk, hurl, stomp,
crush, stagger, kneel (chest cage opens), exposed (heart flares), collapse. Warden Gate and Keystone Pylon: 19.V2.

## 7. Cinematics
Tech, formats, skip, save points and the video pipeline: `cinematics.md`. Here: the content. Every cinematic is
<= 2:00. Kinds: **VIDEO** = pre-rendered `.ogv` (staged in-engine at max quality, recorded with Movie Maker; **later
production**, section 7.4); **ENGINE** = played live by the `CinematicPlayer` (between-mission ones on a small stage
scene, in-mission ones in the mission world with a world hold: PAUSE = camera-only, HOLD = actors walk).

### 7.1 List
| # | Id | Title | Kind | Where / trigger | Length | Stage / set |
|---|---|---|---|---|---|---|
| 1 | `ep1_intro` | The Night of Knives (the assassination attempt) | **VIDEO** (later) | New episode, before M0 | 2:00 | Observatory backstory, Emberfall watch at night, Malrik's crypt (19.V15) |
| 2 | `m0_fall` | The Old Man Falls | ENGINE (PAUSE) | M0 6:40 | 0:35 | Emberfall watch, night |
| 3 | `m0_dawn` | Dawn at Emberfall | ENGINE (HOLD) | M0 8:00 | 0:30 | Emberfall watch, dawn |
| 4 | `m1_seal` | The Seal Breaks | ENGINE (PAUSE) | M1 E6 | 0:12 | Emberfall |
| 5 | `c1_offer` | The Offer | ENGINE (stage) | After M1 | 1:20 | Rime Keep throne hall (19.V7) |
| 6 | `m2_heartfrost` | A Hundred Winters | ENGINE (PAUSE) | M2 E10 | 0:10 | Glasswater Mere |
| 7 | `c2_two_fronts` | One Front, Two Watchers | ENGINE (stage) | After M2 | 1:30 (1:20 without Pell) | Fire war camp + Ysolde's grove (19.V8) |
| 8 | `m3_oldroot` | The Oldroot Opens | ENGINE (PAUSE) | M3 E10 | 0:12 | Sighing Wood |
| 9 | `m3_plea` | Ysolde's Plea | ENGINE (PAUSE) | M3 E11 | 0:40 | Sighing Wood |
| 10 | `m3_memory` | The Signet's Memory | **VIDEO** (later) | Right after `m3_plea` | 1:00 | The Hollow, past (19.V16) |
| 11 | `m3_parting` | The Wood Will Remember | ENGINE (PAUSE) | M3 E13 | 0:40 | Sighing Wood |
| 12 | `c3_parley` | The Parley | ENGINE (stage) | After M3 | 1:45 | Fallen Colossus parley ground (19.V9) |
| 13 | `m4_war` | Dawn at Crown Hollow | ENGINE (HOLD) | M4 0:00, after the briefing | 0:30 | Crown Hollow |
| 14 | `m4_rise` | The Hollow Throne Opens | **VIDEO** (later) | M4 the Rise | 0:45 | Crown Isle hi-res (19.V17) |
| 15 | `m4_storm` | The Storm Returns (the rescue) | **VIDEO** (later) | M4 the darkest hour | 1:45 | Fire keep under siege, the storm, the bridge (19.V22) |
| 16 | `m4_fall` | The Fall | ENGINE (PAUSE) | M4 HP 0 | 0:06 | Crown Hollow |
| 17 | `ep1_ending` | The Keystone | **VIDEO** (later) | After `m4_fall` | 1:30 | Crown Isle ruins, grey dawn to sunrise (19.V22) |
| 18 | `ep1_credits` | Credits | ENGINE (stage) | After `ep1_ending` | 1:30 | Crown Hollow flyover, empty map |
**Totals: 5 VIDEO = 7:00 (~105 MB at 15 MB/min; 70-175 MB over the 10-25 MB/min range). 13 ENGINE = 9:40.**

### 7.2 Shot lists
Columns: time in the cinematic, camera (the `CinematicShot` camera mode of `cinematics.md` 3: STATIC, DOLLY, ORBIT,
RAIL, FOLLOW, CRANE), action, lines (speaker: text), shot length. Subtitles are drawn by the game over videos too.

#### `ep1_intro` "The Night of Knives" (VIDEO, later production, 2:00): backstory in 26 s, then the attempt
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | CRANE down from the stars to the Emberfall observatory as it once was | A brass dome, lanterns, the tower on its crag | Narrator: Before the kingdoms, there was the Master. | 8 s |
| 2 | 0:08 | DOLLY in behind the Master at a giant brass orrery; four small flames orbit it (red, blue, green, violet); a tall swordsman stands guard at the door, back to camera, a faint crackle on his blade | The Master stops the orrery; a hairline amber crack glows in the floor; the robe falls empty and the regalia burst up through the dome as sparks | Narrator: He raised four apprentices, gave each a kingdom, and one day he was gone. | 10 s |
| 3 | 0:18 | 4 cuts, 2 s each, STATIC mid shots | Vessa laughing among sparks; Torvald breathing frost over a still lake; Ysolde coaxing a sapling up through snow; Malrik reading by one violet candle | Narrator: Fire. Ice. Nature. Shadow. Four heirs, one empty throne. | 8 s |
| 4 | 0:26 | FOLLOW Vessa riding up the crag at dusk with 4 Flame Guards; the observatory is now a burnt ruin with a small watch-keep | **Old Vey** waits at the gate, leaning on his long sword | Vey: Twelve years, girl. Not one letter. / Vessa: You left first, old man. | 10 s |
| 5 | 0:36 | Night, STATIC two-shot by the watch-fire | Vey points his sword at the ruins, where the ground hums | Vey: I went looking for him. Found this instead: the crown in these ruins is waking. / Vessa: Then I'll find it first. / Vey: The spark first, Vessa. Then the storm. Remember that. | 12 s |
| 6 | 0:48 | Slow push past the two toward a dark window | Vessa laughs at something; behind her, a shadow detaches from the wall with a knife | - | 10 s |
| 7 | 0:58 | Fast cuts, low angle | Vey's sword rings free and a crack of **blue-white lightning** leaps from the blade: the knife is knocked aside and only grazes Vessa's side; she falls. A white mask in the smoke: **Mother Hush** | Hush: Malrik sends his regrets. | 10 s |
| 8 | 1:08 | Handheld-style FOLLOW along the wall | Shadows pour over the walls: Shades, Grave Hounds; the watch-bell rings; Vey hauls Vessa up | Vessa: LIGHTNING? Since when do you- / Vey: Up, girl! They came for YOU. | 10 s |
| 9 | 1:18 | STATIC, a crypt far away | Malrik reads Vey's letter by one violet candle, then pinches the flame out | Malrik: Pity. She always did burn too bright. / Narrator: It was not a declaration of war. It was a murder, and it was about to fail. | 12 s |
| 10 | 1:30 | Low angle ORBIT on Vessa and Vey, back to back | Vessa on her feet, blood on her hand, flames rising around her staff; Vey's blade crackling, weaker than it should be; the assassins circle | Vessa: Malrik wants me dead? Then he just started a war. / Narrator: And so it began. | 14 s |
| 11 | 1:44 | CRANE up and away over the burning watch | Title burns in: `FOUR WIZARDS` then `Episode 1 · The Hollow Throne` (the only burnt-in text besides the end card). Cut straight into M0 | - | 16 s |

#### `m0_fall` "The Old Man Falls" (ENGINE, PAUSE, 0:35). Actors: Vessa, Vey, 3 Shades (teleported into the courtyard before the pause)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Wide, high over the courtyard | Amber light cracks up through the flagstones under the fight (the Hollow stirring from the violence: first sign) | - | 6 s |
| 2 | 0:06 | Close-up Vey | He sees the crack widen under Vessa's feet | Vey: Vessa, MOVE! | 8 s |
| 3 | 0:14 | Slow push, low angle | Vey shoves Vessa clear (`play_gesture` push); the floor gives way under him instead; his blade sparks against the edge | - | 8 s |
| 4 | 0:22 | High angle straight down | Vey falls into the amber dark, a last thread of lightning crawling up the walls after him; the crack slams shut | Vessa: VEY! | 7 s |
| 5 | 0:29 | Close-up Vessa on her knees, then blend back to the RTS camera | Fire rises around her hands (Grief's Fire starts when control returns) | Vessa: ...Malrik. | 6 s |

#### `m0_dawn` "Dawn at Emberfall" (ENGINE, HOLD, 0:30). Actors: Vessa, Captain Ashby + 4 Blaze Riders (spawned at the south-west edge), the living assassins
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Wide, the sun breaks over the eastern hills | Horns in the distance | Narrator: Dawn came to Emberfall, and so did the Emberguard. | 8 s |
| 2 | 0:08 | FOLLOW the Blaze Riders charging through the gate | The assassins scatter north-east (actor moves, then despawn) | - | 8 s |
| 3 | 0:16 | Two-shot, Ashby reins in beside Vessa | - | Ashby: My queen! You're hurt- / Vessa: I'm not the one who's hurt, Captain. | 8 s |
| 4 | 0:24 | Close-up Vessa looking east toward Malrik's camp in the ruins | - | Vessa: Get the army up. We take the crown today. | 6 s |

#### `m1_seal` "The Seal Breaks" (ENGINE, PAUSE, 0:12)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | DOLLY from Vessa (4 m high, behind) toward the pedestal | Flame lines race from the 3 braziers to the crown (the minimap lines, now 3D ground streaks) | L9 (Narrator) starts | 4 s |
| 2 | 0:04 | ORBIT the pedestal at 9 m, 60 degrees in 5 s | `_seal_flash` plays; the 4 wardens lift their heads (eyes flare amber) | L10 (Vessa) | 5 s |
| 3 | 0:09 | Blend back to the RTS camera centred on Vessa | - | - | 3 s |

#### `c1_offer` "The Offer" (ENGINE stage, 1:20). Actors: Torvald, Malrik, 2 Rimeshield door guards (puppets)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | DOLLY along the Rime Keep's outer wall in falling snow | Guards at the gate; wind | Narrator: Two days after Emberfall, the Bishop of Shadow went north. | 6 s |
| 2 | 0:06 | STATIC from behind Torvald's ice throne, down the hall | Violet mist gathers at the far door; Malrik steps out of it | Malrik: Cold in here. You should let Vessa redecorate. She's very keen on fire. | 8 s |
| 3 | 0:14 | Close-up Torvald | Torvald does not move | Torvald: You sent knives after her in the night, and missed. You call that a visit? | 8 s |
| 4 | 0:22 | RAIL beside Malrik as he walks 6 m to a map table | He drops a violet shard marker on Glasswater Mere | Malrik: Your lake holds the second relic. She'll come for it. Help me stop her. | 10 s |
| 5 | 0:32 | Two-shot over the table | - | Torvald: Ice does not march for your mistakes, Bishop. / Malrik: Not mistakes. Opportunities. Just until the relics are in sensible hands. | 10 s |
| 6 | 0:42 | Close-up Torvald, 3 s silence first | - | Torvald: Sensible hands. Yours. / Malrik: Ours, if you like. | 10 s |
| 7 | 0:52 | Low angle as Torvald stands (`play_cast`) | Frost crawls over the table and seals the shard marker in ice | Torvald: No. My lake stays out of your war. And hear me: some doors under Crown Hollow are closed for a reason. | 12 s |
| 8 | 1:04 | Over Torvald's shoulder on Malrik, half-turned | Malrik melts into mist | Malrik: For now, then. Doors are only closed until someone opens them. | 10 s |
| 9 | 1:14 | Wide of the hall, Torvald alone | The sealed marker glows through the ice | Narrator: Ice said no. For now. | 6 s |

#### `m2_heartfrost` "A Hundred Winters" (ENGINE, PAUSE, 0:10)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Low angle 6 m from the Heartfrost | It bursts (existing flash, colour `(0.75, 0.92, 1.00)`), ice chunks fly | L9 (Vessa) | 5 s |
| 2 | 0:05 | Close-up rising with the orb to `(0, 1, 0)` | The orb floats, snow swirling around it | - | 3 s |
| 3 | 0:08 | Blend back to the RTS camera | - | - | 2 s |

#### `c2_two_fronts` "One Front, Two Watchers" (ENGINE stage, 1:30; shot 4 only if `m1_peddler_freed`). Actors: Vessa, Captain Ashby, Pell, Ysolde
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | CRANE down over a hillside war camp at night | Tents with glowing flaps, Ember Hall banners, a campfire | Narrator: Two relics. One enemy. One very tired army. | 6 s |
| 2 | 0:06 | STATIC over a war table inside the command tent | Red tokens in the south-west, violet tokens massing in the east; blue and green tokens standing apart | Ashby: Shadow is massing on the Dusk road. Ice keeps to its lakes. Nature has closed its borders. | 10 s |
| 3 | 0:16 | Close-up Vessa, then Ashby | - | Vessa: So it's me and Malrik. / Ashby: And whatever he sends in the night, my queen. | 8 s |
| 4 | 0:24 | The tent flap: Pell pokes his head in (branch; skipped when the flag is false) | Pell's cart bell jingles | Pell: Sorry! Wrong tent! Unless you're buying? ...You're not buying. | 10 s |
| 5 | 0:34 | DOLLY around the table | Vessa taps the forest between the fronts | Vessa: His scouts are already in Ysolde's wood. The third relic sleeps there. I go before he gets it. / Ashby: Ysolde doesn't take sides. / Vessa: Then she won't mind. I'll ask nicely. / Ashby: With fire? / Vessa: Nicely. With fire. | 14 s |
| 6 | 0:48 | Late night, STATIC by the campfire | Vessa alone, turning Vey's old sword-knot in her fingers; the crown and orb on a cloth beside her pulse in time; the subtitle is amber | Whisper: The third sleeps in the old tree. Bring them together, and you'll never need a friend again. | 10 s |
| 7 | 0:58 | Close-up Vessa looking around | The fire pops; nobody there | Vessa: Who's there? ...Great. Now the jewellery talks. Vey would have laughed at me. | 10 s |
| 8 | 1:08 | CRANE down into Ysolde's grove | Ysolde lays her hand on an old oak; roots close over a glowing ring deep in the trunk | Ysolde: Not you, Vessa. Not Malrik. Not ever. | 12 s |
| 9 | 1:20 | Wide on the moonlit forest | Wind through the canopy | Narrator: The war was coming to the Sighing Wood, invited or not. | 10 s |

#### `m3_oldroot` "The Oldroot Opens" (ENGINE, PAUSE, 0:12)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Wide, 20 m high, on the Oldroot | The thorn barrier browns and sinks into the ground in 5 s (19.V5) | - | 6 s |
| 2 | 0:06 | DOLLY in to the trunk | A split opens in the bark: the Signet's white-gold glow inside | - | 4 s |
| 3 | 0:10 | Blend back to the RTS camera | - | - | 2 s |

#### `m3_plea` "Ysolde's Plea" (ENGINE, PAUSE, 0:40). Actors: Vessa (at the Signet), Ysolde (a neutral, invulnerable story unit spawned at `(3, 0, -3)` before the pause)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Low angle on the roots beside the tree | Ysolde rises out of the roots (grow-in VFX) | Ysolde: Vessa. Stop. Please. | 6 s |
| 2 | 0:06 | Over Ysolde's shoulder on Vessa | - | Vessa: NOW you want to talk? Your wood tried to eat me. / Ysolde: My wood tries to eat everyone. It's very fair. | 8 s |
| 3 | 0:14 | Close-up Ysolde | - | Ysolde: Those relics aren't a prize. They're a lock. Put three together near the Hollow and the door opens. | 10 s |
| 4 | 0:24 | Two-shot, slow push | Vessa turns to the glowing split | Vessa: Everyone says that about the things I want. And if I leave it, Malrik takes it. | 8 s |
| 5 | 0:32 | Close-up on Vessa's hand | Her hand closes on the Signet; the crown and orb flare amber | - | 8 s |
Then V2 at once (same black frame).

#### `m3_memory` "The Signet's Memory" (VIDEO, later production, 1:00). Amber-sepia grade for the past, normal grade for shots 1 and 8
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Extreme close-up of the Signet in Vessa's palm | Crown and orb pulse with it; a low chord | - | 4 s |
| 2 | 0:04 | White-out into the past; CRANE over a tower being built | Masons and fresh, un-mossed Ruin Wardens carrying blocks | Ysolde (voice): The Master had a first apprentice. Before any of us. | 6 s |
| 3 | 0:10 | DOLLY around young Obren | A broad stonemason-wizard with amber-veined hands shapes a Warden from a block with a chisel-staff; the Master's hand on his shoulder; in the background a younger swordsman (Vey) watches, arms crossed | Ysolde: Obren. The Mason. He built the Wardens, the towers... and the Throne. | 8 s |
| 4 | 0:18 | STATIC, night, candlelight | Obren alone, palm pressed on the Master's regalia laid on a table; his eyes hungry | Ysolde: He wanted more than a kingdom. He wanted the Master's seat. | 8 s |
| 5 | 0:26 | Wide, a vast hollow throne-room under the earth | Obren on a stone throne, drinking light from the regalia; the Master enters; a white flash; stone grows over Obren and seals him into the throne | Master: Sit, then. Sit until the world forgets you. | 10 s |
| 6 | 0:36 | Time-lapse CRANE up through the rock | The hall sinks; water fills the hollow (Hollowmere); an isle with a pedestal forms on top | Ysolde: He sealed him with the regalia as the lock. And when the lock began to fail... | 8 s |
| 7 | 0:44 | From below the observatory floor (the V1 moment seen from under it) | The Master steps down through the amber crack into the dark and pulls the door shut from inside; the regalia burst away | Ysolde: ...he went down to hold the door himself, and threw away the keys. | 8 s |
| 8 | 0:52 | Present; close-up Vessa's face lit amber | Amber cracks race across the forest floor toward the camera | Obren: And you picked them up. All three. Thank you, little ember. | 8 s |

#### `m3_parting` "The Wood Will Remember" (ENGINE, PAUSE, 0:40). Actors: Vessa, Ysolde (the neutral story unit, teleported beside Vessa before the pause)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Wide, the last gate's rubble settling | Ysolde steps out of the roots near Vessa | Ysolde: I warned you. You didn't listen. Neither did he. | 8 s |
| 2 | 0:08 | Over Ysolde's shoulder | - | Vessa: Then help me stop it. Please. / Ysolde: Nature doesn't take sides, Vessa. | 10 s |
| 3 | 0:18 | Close-up Ysolde | - | Ysolde: But when your war comes for my wood, and it will, remember that I warned you both. | 12 s |
| 4 | 0:30 | CRANE up as she sinks into the roots; Vessa alone with the glowing Signet | - | Narrator: Fire at war with Shadow. Ice and Nature watching. And under the world, something counting. | 10 s |

#### `c3_parley` "The Parley" (ENGINE stage, 1:45). Actors: Vessa, Malrik, Torvald and Ysolde (neutral witnesses), 4 banner bearers, the companion (optional)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | CRANE down past the Fallen Colossus's stone face | Four banners (red, green, violet, blue) staked around a flat stone at grey dawn | Narrator: For the first time since the Master left, the four apprentices stood in one place. | 8 s |
| 2 | 0:08 | Wide, high | The four walk in from four directions and stop around the stone; the player's M3 companion (if one was chosen) stands 2 m behind Vessa as her bodyguard | Malrik: Look at us. The Master would weep. Mostly at your outfits. | 10 s |
| 3 | 0:18 | Close-up Vessa | - | Vessa: The relics aren't a prize. They're a lock. Someone is under Crown Hollow, and he's been whispering to me since Emberfall. | 12 s |
| 4 | 0:30 | Close-up Ysolde | - | Ysolde: Obren. The first apprentice. Every battle over the relics feeds him. / Ysolde: And something down there is still fighting him. I feel it through the roots. | 12 s |
| 5 | 0:42 | Close-up Malrik, amused | - | Malrik: A secret apprentice under the lake. And the cure is that I stop the war I'm winning. How convenient. | 10 s |
| 6 | 0:52 | Two-shot Torvald / Malrik | - | Torvald: She is not lying, Bishop. I have felt it under the ice. Something counting. / Malrik: Then let it count. Whoever holds the Hollow holds the Master's seat. I intend to sit in it. | 12 s |
| 7 | 1:04 | Profile two-shot, Vessa steps nose to nose with Malrik | - | Vessa: You sent knives in the night. You took Vey from me. You'll have to go through me. / Malrik: That was always the plan, little ember. | 12 s |
| 8 | 1:16 | Vessa turns to the other two | - | Vessa: Help me stop him. / Torvald: Ice stays out of this war. / Ysolde: Nature too. Win it or lose it without us. | 10 s |
| 9 | 1:26 | Wide as the four walk apart; banners pulled up | - | Malrik: Crown Hollow. At dawn. / Vessa: Bring your army. I'll bring mine. | 12 s |
| 10 | 1:38 | Night wide over the valley | Camp fires on both banks of the Hollowmere; under the isle an amber glow pulses once | Narrator: At dawn, the war would come home to where it started. | 7 s |

#### `m4_war` "Dawn at Crown Hollow" (ENGINE, HOLD, 0:30). Actors: Vessa, the companion, Malrik (at his rally)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | CRANE from 40 m high over the isle down toward the west bank | Both armies facing each other across the moat at dawn | L1 | 8 s |
| 2 | 0:08 | Close-up Malrik at the east bank | - | L2 | 8 s |
| 3 | 0:16 | Close-up Vessa | - | L3 | 6 s |
| 4 | 0:22 | FOLLOW Vessa walking along her front line (actor move, 10 m), the companion behind her | The moat water shivers amber for a beat | L4 | 8 s |
End state: HOLD released, the RTS camera on Vessa.

#### `m4_rise` "The Hollow Throne Opens" (VIDEO, later production, 0:45)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Low angle at the Throne stone | Vessa's boots step onto it; the three relics flare | - | 4 s |
| 2 | 0:04 | Wide on the whole isle | The moat boils amber; the 8 pillars crack; on the bridges both armies stop fighting | - | 6 s |
| 3 | 0:10 | Close then wide | The isle splits in a cross (deep in the split, for a few frames, a tiny white-gold flicker: the hint); a huge stone hand grips the edge; Vessa Ember-Steps back to the West Crown Bridge | - | 8 s |
| 4 | 0:18 | TILT up from the pit, low angle | The Keystone Colossus rises: pillar ribs, the Throne as its chest cage, the amber heart behind stone, the head floating over a gap of light | Obren: Stand up, all of you. Your master is home. | 10 s |
| 5 | 0:28 | 3 quick cuts | Ruin Wardens climb out of the moat; their eyes flare | - | 5 s |
| 6 | 0:33 | CRANE up | Four stone pylons burst from the banks; golden tethers snap to the Colossus's chest | - | 6 s |
| 7 | 0:39 | Two quick close-ups | Malrik on the East Crown Bridge; Vessa on the West | Malrik: Well. That's new. / Vessa: Ysolde said it'd be big. She undersold it. | 6 s |

#### `m4_storm` "The Storm Returns" (VIDEO, later production, 1:45): the rescue, the episode's high point
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Wide, low, from inside the Fire base | The Colossus looms over the burning keep; Wardens swarm the walls; Vessa's soldiers fall back | Obren: Your little fire goes out now. | 8 s |
| 2 | 0:08 | Close-up Vessa on one knee | Staff cracked, mana gone; she tries a Fireball: a fizzle of sparks | Vessa: Not... yet... | 8 s |
| 3 | 0:16 | Wide, the sky | Storm clouds boil in from nowhere over Crown Hollow, white-gold lightning crawling inside them; everyone, Shadow on the far bank too, looks up | Malrik (far off): That is not my weather. | 10 s |
| 4 | 0:26 | Low angle on the West Crown Bridge | A white-gold bolt strikes the bridge; flash, thunder; when it clears an old man stands in the scorch mark, sword drawn, beard-braid smoking: **Old Vey** | - | 8 s |
| 5 | 0:34 | FOLLOW Vey striding up the lane | Every Warden that comes at him: one stroke, and chain lightning leaps from stone body to stone body; they burst like pots | - (the music turns) | 12 s |
| 6 | 0:46 | Low angle past Vey's shoulder up to the Colossus | It turns its head and recoils from the crackling light | Obren: That storm... HE sent you? / Vey: He did. He says: sit down. | 10 s |
| 7 | 0:56 | Wide, then close | **Lightning Lunge**: Vey dashes up the Colossus's back and drives his sword into the stone between its shoulders; he raises his free hand: **Stormcall**. The sky splits; a great bolt runs down through sword and body; the Colossus drops to its knees; its chest cage cracks open, the amber heart visible behind stone | - | 12 s |
| 8 | 1:08 | Close two-shot | Vey lands beside Vessa and holds out a hand | Vessa: Vey?! I saw you fall! / Vey: And I kept falling, girl. Long way down. Good company at the bottom. | 14 s |
| 9 | 1:22 | Two-shot, slow push; Vessa stands with his help | - | Vey: Up. The spark first. / Vessa: ...Then the storm. | 12 s |
| 10 | 1:34 | CRANE up and wide | Vessa's surviving soldiers and the companion rally around the two; the storm rumbles overhead, lightning crawling around the kneeling giant | - | 11 s |
End state: section 5.4.3 "The darkest hour".

#### `m4_fall` "The Fall" (ENGINE, PAUSE, 0:06)
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Close-up the heart, VFX at 0.3 speed (slow motion look) | Cracks race across the heart | L21 | 4 s |
| 2 | 0:04 | Fade to white | - | - | 2 s |
Then V5 at once.

#### `ep1_ending` "The Keystone" (VIDEO, later production, 1:30). A dark beat, then **hope**
| # | Time | Camera | Action | Lines | Dur |
|---|---|---|---|---|---|
| 1 | 0:00 | Slow motion, low angle | Vessa's fire and Vey's white-gold lightning strike the exposed heart together | - | 8 s |
| 2 | 0:08 | Wide | The heart shatters; the stone body crumbles in a slow cascade; a dust wave rolls over the Fire and Shadow armies | - | 8 s |
| 3 | 0:16 | Close-up in the rubble, grey pre-dawn light, the storm clearing | A fist-sized amber stone still pulses; a silver-clawed staff and a gaunt hand pick it up; Malrik melts into mist with it and the Shadow army withdraws | Malrik: Oh, it is not done. / Obren (faint, from the stone): ...yes... | 10 s |
| 4 | 0:26 | CRANE across the valley | On the northern ridge Torvald watches, alone on his mount; at the western treeline Ysolde stands half-hidden among the trunks. Both saw everything; neither moved. Torvald turns away; Ysolde sinks into the trees | Narrator: Two apprentices watched. Neither moved. Not yet. | 10 s |
| 5 | 0:36 | Vessa and Vey at the edge of the open pit | The Hollow Throne below is cracked open and empty | Vessa: I thought I'd lost you. Again. / Vey: I was down there. With him. / Vessa: Him? The Master? | 14 s |
| 6 | 0:50 | Vey raises his sword over the pit; push down into the dark, then close-up on Vessa's hands | Far below, a white-gold light answers his blade. The crown, orb and signet turn from amber to **white-gold** and hum one clean note, all tilting down like a compass | Vey: He's alive. Tired of holding that door alone. He asked for all four of you. | 14 s |
| 7 | 1:04 | Two-shot; the sun breaks over the valley rim behind them | Vessa laughs, eyes wet | Vessa: All four. Even Malrik? / Vey: Especially Malrik. / Vessa: And you're explaining the lightning. / Vey: On the way down. | 12 s |
| 8 | 1:16 | CRANE up and wide, full sunrise over Crown Hollow | Fire soldiers raise their banners and cheer; birds lift off the moat | Narrator: The war had begun. But the way to end it had just come back out of the dark. | 6 s |
| 9 | 1:22 | Sunrise fades to warm white | Text: `END OF EPISODE 1`, then `Episode 2 · The Light Below` (burnt-in) | - | 8 s |

#### `ep1_credits` "Credits" (ENGINE stage, 1:30)
One RAIL shot: a slow flyover of Crown Hollow at sunrise (the M4 map, no units, the isle in ruins, birds), credits roll
(designer: the user, "Built with the Godot Engine", the agent roles, CC0 sources list from `assets/`), last 10 s:
the Episode 2 teaser card `The Master is alive. The way down is open.` Skippable.

### 7.3 In-mission talking heads
Every mission line (sections 5.0-5.4) shows in the `DialogueBox` with the speaker's **portrait** (96 x 96, left of the
text, 19.U3 / 19.V6). The Whisper shows a dark silhouette with two amber eyes; from L15 of M3 it shows Obren's stone
face. Lines never pause the game; cinematics do.

### 7.4 Later production and fallback cards
The 5 VIDEOs are recorded last (19.V18 / 19.L3), after every art pass, so they match the final look. Until a file
exists (or if the user declines video), the game shows its `fallback_text` card (10 s, skippable, `cinematics.md` 8.5):
| Video | Fallback text |
|---|---|
| `ep1_intro` | `The Master vanished and left four apprentices. Years later, Vessa of Fire answered her old teacher's letter and rode to Emberfall. That night Malrik of Shadow sent assassins to kill her. Old Vey's sword, and a crack of lightning no kingdom can explain, saved her life. Now they must survive until dawn.` |
| `m3_memory` | `The Signet shows Vessa a memory. The Master's first apprentice, Obren the Mason, tried to take the Master's seat. The Master sealed him in the Hollow Throne with the regalia as the lock, then went down to hold the door himself. The voice in the relics was Obren all along.` |
| `m4_rise` | `Vessa steps onto the Throne stone. Crown Isle splits open, and Obren rises in a giant body of ruin stone: the Keystone Colossus. Four stone pylons burst from the banks to shield him.` |
| `m4_storm` | `The Colossus smashes into Vessa's base and her army breaks. Then a storm tears open the sky, and lightning strikes the bridge: Old Vey, alive, his storm renewed by the Master himself. One great bolt brings the Colossus to its knees.` |
| `ep1_ending` | `The Colossus falls. Malrik escapes with its amber heart; Ice and Nature watched and did nothing. But Old Vey brings news from below: the Master is alive, and the three relics now point the way down to him.` |

## 8. Art needs (one task per agent; `art-keep.md` 0 style, `art-units.md` rules, 0 real lights in anything played in-game)
| Id | Element | Content | In game or video only |
|---|---|---|---|
| 19.V1 **[H]** | Keystone Colossus (gameplay model) | 12 m boss per 6.3; hooks `set_moving`, `play_attack` (crush), `play_hurl`, `play_stomp`, `play_stagger`, `play_kneel`, `set_exposed(bool)`, `set_stone_skin(bool)`, `play_death` (collapse 3 s); budget <= 48 meshes / <= 24 draw instances, 0 lights, <= 3 particle systems (stopped beyond 45 m) | Game |
| 19.V2 | Keystone Pylon + Warden Gate + tether beam | Pylon: 5 m cracked obelisk with an amber core (rise 1.5 s, break 1 s); Warden Gate: a ruined arch whose inner stone glows amber, rubble state; tether = one scrolling beam mesh (shader), no light | Game |
| 19.V3 | Boss and story VFX family | Telegraph circle and ring (amber fill over time), Hurl boulder + impact, Stomp dust, Relic Pull tether, Hollow Pulse ring, heart exposed flare, Stone Skin shimmer, Turn the Key ring (the brazier ring recoloured), Hush's Blink Strike ring and smoke, Grief's Fire hands | Game |
| 19.V4 | Crown Isle "Hollow Throne" state | Cracked isle, the pit with the empty throne, amber moat glow, rubble; 4 Hollow-meter stages of amber cracks spreading from the isle | Game |
| 19.V5 | Sighing Wood kit | The Oldroot (colossal oak with a split trunk + Signet glow), thorn barrier (wither animation), Root Heart (3 states, drained look for Shadow), Ember Stake, forest light and fog preset | Game |
| 19.V6 | Portraits | 12 painted portraits 512 x 512: Vessa, Old Vey, Malrik, Hush, Torvald, Ysolde, Pell, Whisper silhouette, Obren (stone face), Ashby, Bettany, Maelis; rendered from the models in a portrait stage, painted overpaint shader | Game |
| 19.V7 | Stage set C1 | Rime Keep throne hall interior: ice throne, map table, pillars, door | Game (stage) |
| 19.V8 | Stage set C2 | Fire war camp at night (command tent open front, war table + map texture, campfire with emission), and Ysolde's grove corner | Game (stage) |
| 19.V9 | Stage set C3 | Parley ground under the Fallen Colossus's face (reuse the landmark mesh), flat stone, 4 banners, camp fires in the valley | Game (stage) |
| 19.V10 | Cinematic gestures | `play_gesture(id)` on the 4 wizard models + Pell (+ Ashby, Old Vey, Hush): `point`, `shrug`, `arms_crossed`, `hand_on_hip`, `turn_head_left/right`, `nod`, `kneel`, `stand_up`, `offer_hand`, `push`, `raise_sword` (Vey); 0.3-0.8 s pivot animations in `unit_model.gd` style | Game |
| 19.V11 | Captain Ashby model | Flame Guard officer (plumed helm, scorched tabard, grey moustache), wizard-level detail budget, standard hooks, a mounted variant for `m0_dawn` | Game |
| 19.V12 **[H]** | Video hero models A | Vessa and Malrik at video detail (3-5x polycount, cloth folds, hair cards, higher-res painted textures); not exported | Video |
| 19.V13 **[H]** | Video hero models B | Torvald and Ysolde at video detail | Video |
| 19.V14 **[H]** | Video characters | The Master (4-colour flame hem, beard of light) and young Obren (stonemason-wizard, chisel-staff, amber-veined hands); a younger Vey silhouette for V1 / V2 | Video |
| 19.V15 | Video set V1 | The observatory as it was (exterior + orrery interior), 4 vignette corners, the burnt ruin with Vey's watch-keep at dusk and night (watch-fire, bell, gate, walls), the assassins (Shades, Hounds, Hush hi-res), Malrik's crypt, Ember Boars | Video |
| 19.V16 | Video set V2 | The tower under construction, Obren's night room, the Hollow throne-room (past), the time-lapse rock section | Video |
| 19.V17 **[H]** | Video set V3 | Crown Isle at hi-res (pillars, moat, bridges), the Colossus hi-res (from 19.V1's design) rising from the split isle, pylons erupting | Video |
| 19.V18 | Record + encode | Stage each VIDEO shot list in its set, record with Movie Maker (`cinematics.md` 8), check size and quality, deliver the 5 `.ogv` (last, phase 3) | Video |
| 19.V19 | Key art and thumbnails | Episode 1 card art (Vessa and Old Vey, fire and lightning, before the Colossus), Episode 2 locked card, 18 Theatre thumbnails; stills rendered from the sets | Game (UI) |
| 19.V20 **[H]** | **Old Vey model (game)** | About 2.0 m, lean but broad-shouldered, old and weathered (seventies), long white beard in one braid, scar across a milky left eye, storm-grey long coat over old dented pauldrons, a long straight sword with a blackened, rune-veined blade. Two looks (`set_look(id)`): `m0` (clean coat, runes flicker weak blue-white) and `m4` (torn, frost-rimed coat, blade blazing white-gold, faint crackle at the shoulders). **0 lights** (emission only: blade runes 2.0 / 3.5, eye glint). Wizard-level budget (<= 26 meshes, <= 16 draw instances). Hooks: standard + `play_attack` (`sword_slash`, `sword_thrust`), `play_lunge`, `play_stormcall` (sword raised, free hand up, 1.2 s), `set_blade_charge(0..1)`, `play_kneel` / `stand_up` | Game |
| 19.V21 **[H]** | Old Vey hi-res (video) | Vey at video detail in the same two looks, plus the younger silhouette | Video |
| 19.V22 **[H]** | Video set V4 / V5 | The Fire keep under siege at hi-res (burning walls, Warden swarm), the storm sky (clouds with lightning inside), the West Crown Bridge strike and scorch, the Colossus kneeling and collapsing (baked), dust wave, Torvald alone on the northern ridge, Ysolde at the treeline, the empty pit with the white-gold light far below, the relics' amber-to-white-gold change, a grey-dawn to full-sunrise lighting ramp | Video |
| 19.V23 | Mother Hush model (game) | A tall Shade elite: porcelain-white mouthless mask, two sickle knives, a cloak that trails smoke (<= 1 particle system); Shade kit extended, standard hooks | Game |
| 19.V24 | Emberfall night kit | M0: moonlight preset (the sun as a cold moon, no extra lights), the watch-keep dressing (bell tower, watch-fire with emission), 3 watch braziers (the brazier model), the courtyard amber crack (closed, opening, sealed), a dawn preset for `m0_dawn` | Game |
| 19.V25 | **Old Vey's lightning VFX** | `art/vfx/storm_*` + `StormVfx.play(id, from, to)`: blade arcs on each swing (weak blue-white sparks in `m0`, white-gold in `m4`), the 3rd-strike chain jump, Chain Lightning (a jagged beam mesh re-drawn per jump, 0.12 s each, impact spark), Lightning Lunge trail, Intercept crackle-blink, Charged Ground ring (crackling white-gold ground ring r 10), Stormcall (8 bolts from a local cloud card + the great bolt), a map-wide storm-cloud layer and rare sky flicker for M4 after the rescue (emission and sky modulation only, **no lights**); <= 2 particle systems alive per effect, pooled | Game |

## 9. Tasks
Phases: **0** (contracts and specs) -> **1** (systems, UI, models, sets; parallel) -> **2** (missions and content) ->
**3** (recording, integration). Playtests: after M0 + M1 in Story mode, after M3, after M4, and the full episode at the
end. Build step 19 after steps 12-18, or earlier if the user wants the story first (then M3 / M4 use their fallbacks).
| Id | Task | Owner | Size | Phase | Done when |
|---|---|---|---|---|---|
| 19.L1 | Contracts from `cinematics.md` 11 in `CLAUDE.md`; Input Map actions `cinematic_skip` / `cinematic_advance` / `cinematic_pause` in `project.godot`; export filter excluding `art/cinematics/sets/*` and `art/cinematics/hires/*`; ownership rows for `scripts/cinematics/`, `data/cinematics/`, `missions/cinematics/`, `art/cinematics/`, `art/portraits/` | lead | S | 0 | Contracts frozen; `--import` clean; an export test build has no `sets/` files |
| 19.L2 | Movie Maker probe (`cinematics.md` 8.2): 5 s test to `.ogv` on the user's PC; if it fails, ask the user about ffmpeg | lead | S | 0 | Probe result written in `docs/plan/waves.md`; decision on ffmpeg recorded |
| 19.U0 | UI spec `docs/design/ui-story.md`: Story screen, Theatre, cinematic overlay (letterbox, subtitles, skip / pause prompts), fallback text card, portrait dialogue box, boss bar + Hollow meter, Vey's ally card (read-only inspect) | ui-designer (Fable) | M | 0 | Spec with sizes at 1600 x 900 and 3440 x 1440 |
| 19.D2 | Mission build specs in the `mission-01.md` format: **new** `mission-00.md`, `mission-03.md`, `mission-04.md`; **revised** `mission-02.md` (the 1v1 re-skin of 5.2) | game-designer | L | 0 | All four written; positions pass the clearance rules; M2's floes / dig / Heartfrost numbers unchanged |
| 19.C1 **[H]** | CinematicPlayer core: resources, camera modes, timeline, actions with end states, PAUSE / HOLD world modes, skip / advance / pause, signals (`cinematics.md` 2-6) | systems-high | L | 1 | `tests/test_19_c1.gd` passes (`cinematics.md` 12) |
| 19.C2 | Story flow: `CampaignState` order `[m00 .. m04]` (m00 and m01 both unlocked by default, so old saves and the smoke test keep m01), scenes and rewards, `cinematics_seen`, `resume`, `episode`; `StoryFlow` sequencer; `MissionBase` (extract from `Mission01` if M9.S1 did not) with `hold_world()` and the mission clock pause | systems | M | 1 | `tests/test_19_c2.gd`: the resume points, old saves still load, mission 1 tests pass |
| 19.C3 | M1 story patches (5.1) and M2 text / branch patches (5.2 rows 7-8) | systems | S | 2 | Headless M1 run logs L16, L17 and the new L14; `m1_seal` fires at E6; `m0_escort_saved` adds 2 Flame Guards |
| 19.C4 **[H]** | Mission 3 build (`mission-03.md`) | systems-high | L | 2 | Scripted headless run on normal ends `victory=true` in 20-25 game-minutes; hearts (both sides), stakes, the race (Malrik carries and drops the Signet), twist, gates in order |
| 19.C5 **[H]** | Mission 4 build (`mission-04.md`): the map at war, Hollow meter, isle objective, the Rise, pylons, phases, Cracked Leg, the darkest-hour trigger and its end state, Turn the Key, Old Vey's arrival, win / lose | systems-high | L | 2 | Scripted headless run on normal ends `victory=true` in 22-28 game-minutes; the Rise at 100 % or on the isle channel; the darkest hour fires on 40 % boss HP or 50 % keep HP, whichever first |
| 19.C6 **[H]** | Keystone Colossus boss unit, Keystone Pylon, Warden Gate (gameplay): stats and abilities of section 6 with telegraph hooks for VFX, phase API `set_phase(n)`, signals `phase_changed`, `exposed_changed`, `pylon_destroyed` | gameplay-high | L | 1 | `tests/test_19_c6.gd`: ward blocks damage while a pylon stands; Hurl lands after exactly 1.6 s in r 3.5; Stone Skin x 0.1; a 3 s channel exposes for 10 s; a pulse resets the channel except with Vey within 8 m |
| 19.C7 | Mission 0 build (`mission-00.md`): the night map corner, sight x 0.6, watch braziers, assassin waves on Vessa, Grief's Fire, the countdown, `m0_fall` / `m0_dawn` hooks, no economy | systems | M | 2 | Scripted headless run on normal survives to dawn in 8:00 of game time with Vessa alive; Hush flees at 25 % |
| 19.C8 | ENGINE content A: `c1_offer`, `c2_two_fronts` (Pell branch), `c3_parley` (companion branch), `ep1_credits` as `data/cinematics/*.tres` + stage scenes `missions/cinematics/*.tscn` using 19.V7-19.V11 | systems | M | 2 | Each plays start to end and skips cleanly in the game; durations within 0.5 s of section 7.2 |
| 19.C9 | ENGINE content B: the 9 in-mission cutscenes wired to their events (`m0_fall` ... `m4_fall`) with correct end states; the VIDEO end states of `m3_memory`, `m4_rise`, `m4_storm` applied by the missions | systems | M | 2 | Each skip leaves the mission in the same state as a full play (test per mission) |
| 19.C10 | Recording mode of `CinematicStage` (`cinematics.md` 8.3): a staging scene plays its shot list by itself under Movie Maker, overlay off, and quits at the end | systems | S | 1 | A 5 s staged test records to the probe format and quits by itself |
| 19.C11 **[H]** | **Old Vey ally unit**: `UnitType` `torren_vey` with the two kits (M0 fading storm: Blade + spark, Intercept; M4 renewed storm: Blade + chain, Lightning Lunge, Chain Lightning x 2 on Wardens, Charged Ground, Ground the Pulse hook for 19.C6, Stormcall), not commandable, the kneel-instead-of-death rule | gameplay-high | M | 1 | Test: every 3rd strike chains; Chain Lightning deals 45 / 38 / 32 / 27 / 23; a 200 HP Warden in Charged Ground dies in 10 s; no Warden spawns inside r 10; Stormcall hits an Exposed Colossus for 300; at 1 HP he kneels and returns (M0 40 % after 5 s, M4 50 % after 10 s) |
| 19.C12 | Mother Hush unit: Blink Strike (telegraph, lowest-HP-% hero within 14 m), Smoke at 50 %, flee at 25 % | gameplay | S | 1 | Test: Blink Strike lands behind Vessa 0.5 s after its ring; she flees at 25 % and never dies |
| 19.C13 | M2 re-skin (only if M2 was already built from the old spec): 5.2 rows 1-6 | systems | M | 2 | M2 headless run ends `victory=true` in 18-24 game-minutes vs Shadow; walls, Sentinels and Heartfrost are NEUTRAL |
| 19.U1 | Cinematic overlay: letterbox, subtitles (speaker colours, 2 lines max), skip prompt (two-press), pause overlay, HUD / mission HUD hidden and restored; the pause menu ignores Esc while a cinematic plays | ui | M | 1 | `tests/test_19_u1.gd`: bars at 1600 x 900 and 3440 x 1440 as `cinematics.md` 6.1; HUD restored after skip |
| 19.U2 | Video cinematic screen: `VideoStreamPlayer` in a 16:9 `AspectRatioContainer` on black, subtitle track, skip / pause, fallback text card, audio bus | ui | M | 1 | `tests/test_19_u2.gd` (fake stream mode): skip, pause, missing file = fallback card, then `finished` |
| 19.U3 | Portrait dialogue: portraits in `DialogueBox`, speaker registry (the new speakers and colours of section 2), Whisper -> Obren switch | ui | S | 1 | New speakers show their names, colours and portraits; old missions unchanged |
| 19.U4 | Story menu: Story button, Episode cards, Continue / New / Missions / Theatre, Episode 2 locked card and teaser | ui | M | 2 | Continue resumes at every resume point of `test_19_c2`; Theatre lists only seen cinematics |
| 19.U5 | Boss and story HUD: boss bar with phase marks (100 / 70 / 40), pylon counter, Hollow meter line (orange at 50 %, red at 75 %), Turn the Key prompt and progress ring, Vey's Charged Ground radius as a faint ring on the minimap and his Stormcall cooldown on his inspect card; M0's dawn countdown | ui | S | 2 | Visible and readable at 1600 x 900 and 3440 x 1440; hidden during cinematics |
| 19.U6 | Cinematic audio: CC0 placeholder music cues per cinematic, stingers (the knife, the fall, the Rise, the storm, the Fall), thunder one-shots for Vey, a `Cinematic` audio bus | ui | S | 2 | Every ENGINE cinematic has a cue; the volume setting reaches the bus |
| 19.A1 | Bot profiles `mission_02` (Shadow re-skin), `mission_03` (Shadow forward camp, pulls back at E11) and `mission_04` (Shadow attacks from ~6:00, then scripted pylon strike on P3 / P4 + raids every 180 s; ignores `"boss"` targets unless attacked) | ai | M | 2 | Headless: M3 Shadow never attacks after E11; M4 Shadow units attack P3 / P4 within 60 s of the Rise |
| 19.A2 | Old Vey's brain (M0 and M4): stay 2-6 m from Vessa, Intercept / Lightning Lunge the nearest threat to her, go with her to the Colossus in phase 3, Stormcall triggers | ai | S | 1 | Test: Vey stays within 8 m of a walking Vessa, intercepts an assassin aimed at her, and fires Stormcall within 0.5 s of an exposure when ready |
| 19.V1-19.V25 | Art (section 8) | tech-artist (one agent each) | V1, V12, V13, V14, V17, V20, V21, V22 L [H]; others M | 1 (V18 in 3) | Each: `PERF OK` for game items, contact sheet in `docs/art/screens/`, video items render in their set without errors |
| 19.D3 | Read every line in game, trim anything over 2 lines; M0 survival and boss / Vey balance pass from playtest numbers | game-designer | S | 3 | Changes written back into this doc and the mission specs |
| 19.L3 | Integration: record the 5 videos with 19.V18, check the size budget (`cinematics.md` 9), full-episode run, playtest build | lead | M | 3 | Episode 1 plays start to end from the Story menu; video total within budget |
**Count: 52 tasks** (13 code 19.C1-C13, 7 UI 19.U0-U6, 2 AI, 25 art 19.V1-V25, 2 design 19.D2-D3, 3 lead 19.L1-L3).

### What changes in other specs (the owners apply them in step 19)
- `mission-01.md`: section 5.1 table. `mission-02.md`: section 5.2 (the 1v1 re-skin; 19.D2 rewrites it).
- `items.md`: none (the Master's Signet already lists mission 3).
- `champions.md` 11: mission 3 is the first with taverns (unchanged); M4 has only the west tavern.
- `market-trade.md` 10 ("The Salt Road" as mission 4), `cavalry-mounts.md` 12 (Ember Boar mission 4), `map-fill.md` 11
  (mission 3 camps and Wayshrine, mission 4 river road), `research.md` 12 (mission 5): these proposals move to
  **Episode 2**. Episode 1 uses from them only: the river on Crown Hollow (M4) and one epic beast (M3).

## 10. Episode 2 direction ("The Light Below": starts hopeful)
Episode 2 opens at sunrise on the win: Old Vey is back, the Master is alive below, and the three relics point the way
down. Then the war turns: **Ice joins Shadow**, and the new alliance's first victim is **Ysolde: her army is
destroyed** and the Sighing Wood burns and freezes (2v1). Vessa goes to her aid; Ysolde, the one who warned her,
joins Fire, and the war becomes **2v2**, Fire and Nature against Shadow and Ice. Why these two: Torvald is the
pragmatist who watched Vessa carry three relics toward the Hollow and fears her more than Malrik (he said "no, for
now" in C1 and turned away in V5; Malrik's heart-stone gives him the argument); Ysolde refused both sides and her wood
lies between the fronts (C2), so she is the first target, and Nature's "it grows back" is the hopeful turn: her army
regrows with Fire's help. Tone: hope first, then a hard middle, then a turn to hope. Old Vey is the guide, and his
lightning, the one power no kingdom has, is the thread to pull: it is the Master's own storm, and it answers only near
him (a strong candidate for a second playable hero). Malrik and the shard remain the rival who might still be redeemed
("Especially Malrik"). Mission ideas:
- **Sunrise Road**: Vey leads the first descent under Emberfall; Ruin Wardens that feel the Master's storm wake as friends; a hopeful, strange mission of light and lightning.
- **The Burning Grove**: news that Shadow and Ice struck the Sighing Wood together; rescue Ysolde and hold her last Heartwood (the 2v1 at its worst).
- **Roots and Embers**: the first joint mission; Nature's army regrows around Fire's line; the war becomes 2v2.
- **The Light Below**: the race down toward the Master against Malrik, Torvald and the shard; Vey's story told at last; the Episode 2 boss.

## Questions for the user (recommendation first)
1. **How to open the war?** (a) **A short prologue M0 "The Night of Knives" (~10 min) + M1-M4 = 5 missions** (b) Fold
   the assassination into the first 3 minutes of M1 (4 missions, M1 changes more) (c) The prologue plus "The Salt
   Road" between M3 and M4 (6 missions).
2. **M2 was Fire vs Ice; the 1v1 rule makes Torvald neutral.** (a) **Re-skin M2: Malrik's dig expedition on Torvald's
   lake, Torvald's walls, sentinels and storms neutral (same map and mechanics)** (b) Keep M2 vs Ice as written
   (Torvald fights in Episode 1) (c) Move M2 to Episode 2 as its first mission against the new Shadow-Ice alliance and
   give Episode 1 a new Shadow mission instead.
3. **Video or engine?** (a) **Hybrid with 5 videos, recorded last (7:00, ~105 MB)** (b) Hybrid with 4 (the twist memory
   in-engine; 6:00, ~90 MB) (c) Engine only (no video, no download size; the Master and young Obren become simple
   in-game models).
4. **If Godot 4.7.2's Movie Maker cannot write `.ogv` directly**, may we download ffmpeg (the official Windows build,
   ~100 MB) to convert the recordings? (a) **Yes, download ffmpeg** (b) No download: the videos become ENGINE
   cinematics instead.
5. **Old Vey in M0 and in M4's phase 3?** (a) **An autonomous ally (like the champions: he fights beside Vessa with his
   own kit, you can't order him)** (b) A second hero you control in those two moments (his kit on the command card)
   (c) Cinematic only (his storm works as a scripted aura around Vessa, no unit).
