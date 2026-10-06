# Unit spotlights: one unit per mission, shown at its best

Written 2026-10-06. Status: **design only** (no game code, no test). Owner: game-designer.

JS asked (2026-10-06): does each mission introduce a unit, "Fire episode 3: this is unit X", and show that unit's best
case or close to it? **Answer: today it is only partly true.** The specs teach units mostly in blocks. A whole kingdom's
Stronghold opens in its mission 1, and only the casters, the helpers, the titans and the tier-3 units get a mission
built around them. This doc gives each of the 36 missions **one spotlight**: a unit, building, Forge line, caster,
helper or titan. It also says why that mission is the spotlight's best case, the scripted beat and intro card that make
it shine, and what the player already knows by then.

Sources: `campaign-outline.md` (the "New / unlocked" column), the 33 mission specs (`mission-0*.md`, `mission-e*-*.md`),
`unit-guide.md` + `data/ui/unit_guide.json` (strong / weak / good-with tags), `docs/balance/unit_lab/balance_pass_2026-10-06.md`
(final matrices, cited as **Lab c / p / b** = mean score at equal crystals / equal pop / both; 50 = even; "exempt" =
a role unit judged only in mixes), `caster-units.md`, `unit-upgrades.md` (the Forge), `titans-2.md` 8.2.

## 0. Rules used
| # | Rule | Why |
|---|---|---|
| S1 | **One spotlight per mission; no unit is spotlit twice.** Ep8 missions 2 and 3 are played by the kingdom picked in the "Whose road?" screen, so their spotlight is a **kingdom variant**: 4 units, only one of them seen per playthrough | The player meets 33 missions; each kingdom then gets 3 Ep8 spotlights |
| S2 | The spotlight need not be **new** in that mission. It is the mission where the unit **wins hardest** (Unit Guide "strong against", Unit Lab cell, terrain). "Unlocked in" and "spotlit in" can differ (Kilnwarden: unlocked m01, spotlit m04) | Several missions unlock 3-8 units at once (a kingdom's Stronghold) |
| S3 | The spotlight is a **player** unit (trained, called, or given). Enemy units are taught as foes, never spotlit | The card says "this is yours, here is why" |
| S4 | The scripted moment is **one encounter or objective beat**, built from the spec's own waves where possible (wave ids below). No new big systems | Specs stay as they are; the beat is a hint, a camera ping and at most a small spawn change |
| S5 | Intro card text: English, <= 110 characters, name first, then what it is for, said as an order. French goes through `Loc` like any mission text | `localization.md` |
| S6 | Lab numbers are level 0 / no Forge / no veterancy; a spotlight never changes a unit's numbers | The Unit Lab is the balance truth; spotlights are staging |

## 1. Coverage at a glance
| Kingdom | Played missions | Spotlights | Roster items (units + caster + helper + titan + Forge / tower) | Covered |
|---|---|---|---|---|
| Fire | m00-m04, e2m1-e2m5, e5m1, e5m2, e8m1_fire (+ e8m2 / e8m3 variant) | 15 | 13 units + Vey + Cinder Dragon + Forge + Spire + Crucible = 18 | 15 (gaps: Cinder Arbalest, Scorchbow, Scorchling; Crucible is a building) |
| Shadow | e3m1-e3m4, e5m3, e5m4, e8m1_shadow (+ variants) | 9 | 14 units + Hush + Nightmare Knight = 16 | 9 (7 gaps) |
| Ice | e6m1, e6m2, e7m1-e7m4, e8m1_ice (+ variants) | 9 | 14 units + Aldra + War Mammoth = 16 | 9 (7 gaps) |
| Nature | e4m1-e4m4, e6m3, e6m4, e8m1_nature (+ variants) | 9 | 14 units + Maelis + Elder Treant = 16 | 9 (7 gaps) |
| Neutral | m03 (champions) | 1 | 4 champions + Genie + Caravan + Tracker | 1 |
**Total: 36 missions, 36 different spotlights.** Fire is covered because it plays 13 missions. The other three
kingdoms play 7 missions each, plus 2 Ep8 variants, against a roster of 16. **One spotlight per mission cannot cover
them all.** Section 4 lists the gaps, where each gap unit would shine, and two cheap ways to show them anyway.

## 2. The 36 spotlights
Grouped by kingdom (story order inside each group). Format per mission: **Spotlight** (tier, where it comes from) · **Best case** (why this mission) · **Moment** (the
scripted beat) · **Card** (intro text) · **Taught before** (what the player already knows).

### 2.1 Episode 1 "The Hollow Throne" (Fire, Vessa)
**m00 The Night of Knives: Flame Guard** (T1, given: 4 escorts).
- **Best case:** no economy, 4 Guards + 4 watch archers around a wounded Vessa. The enemy is Shades and **Grave
  Hounds that always dive Vessa within 14 m**. The Unit Guide lists the Grave Hound as weak against line infantry, and
  the Guards fight beside braziers that heal +2 HP/s. Lab c / p / b **72 / 74 / 81**: the strongest Fire T1 line, even
  after the 2026-10-06 cut.
- **Moment:** A2 (1:30, 3 Grave Hounds + 2 Shades). A hint and a ring on the courtyard gate: "Stand the Guards between
  Vessa and the gate." The hounds hit the shields, not her.
- **Card:** `Flame Guard. Shields first, spark second: a Guard wall keeps the knives off Vessa.`
- **Taught before:** the prologue film only; this is the first unit the player commands.

**m01 The Crown in the Ashes: Blaze Rider** (T1, Ember Hall; 2 free riders when Brazier 2 is lit).
- **Best case:** the unlock is already staged. Westwatch (Brazier 2) hides **Nightbolts behind Shades**, and W2 brings
  4 Shades + 2 Nightbolts + 2 Grave Hounds. The rider is strong against archers and casters, and Nightbolts are weak
  against cavalry. The lane is open ground. Lab **68 / 72 / 81**, a light rider that is strong per pop.
- **Moment:** the 2 free riders spawn at Westwatch; W2 is the first fight with them. Hint: "Blaze Riders: go around the
  Shades and ride down the Nightbolts." A second hint if a rider stands in Night Spire range: "Not the tower."
- **Card:** `Blaze Rider. Fast and fierce: ride past the shields and catch the archers.`
- **Taught before:** m00 (Guards, Fireball, Ember Step). The economy and the Stronghold are new in this mission too,
  but the rider is the unit beat.

**m02 The Orb Beneath the Ice: Ash Hurler** (T1, new, Ember Hall V).
- **Best case:** the mission is built for it. **Only Vessa and Ash Hurlers damage the Heartfrost.** Hurler hits crack
  the floes (4 cracks drop the Shades on them into the water). Its range of 12 beats a Night Spire's 11. Malrik's dig
  camp is static. Lab **8 / 41 / 4, exempt** (siege): it loses head-on by design and needs exactly this kind of job.
- **Moment:** W1 (5:00). 3 Shades + 2 Nightbolts cross floe F2; a hint pings it: "Ash Hurlers crack the ice: shell the
  floe under them." Then the first Hurler volley on the Heartfrost (L-line "Thin ice!").
- **Card:** `Ash Hurler. Slow, far, and it melts what swords can't: ice, towers, camps.`
- **Taught before:** m01 (Guards, Archers, Riders, the Stronghold units).

**m03 The Signet in the Sighing Wood: Wayfinder** (champion, tavern hire; the champions system's first mission).
- **Best case:** the Root Hearts are hidden in fog in a dense wood, and Malrik's drain squads reach them first. The
  Wayfinder is a ranged scout, strong against hidden and fleeing units and good on Explore bounties. Every other
  champion is a fighter that the player's army can stand in for. Here the job is **finding**.
- **Moment:** E3, the first Explore flag (R) on the fog. The Wayfinder walks it and reveals Root Heart 2 about 60 s
  before the second drain squad (D2, 7:00).
- **Card:** `Wayfinder. A champion you don't command: flag the fog, and she finds what hides in it.`
- **Taught before:** the whole Fire T1 card, the Stronghold, items. Champions are new.

**m04 The Hollow Throne: Kilnwarden** (caster, keep B; unlocked m01, spotlit here, S2).
- **Best case:** the Keystone Colossus is a titan with armor 25. Slag Rain makes it **armor 5** and adds x1.10 damage
  taken (5 s on titans). Its autocast fires on a titan. Malrik is a mana-heavy wizard, so Mana Scald burns up to 60.
  Shadow Knights bring armor to the push. Kilnwarden best-case tags: armoured units, casters, wizards. The caster
  balance pass (`caster-units.md` 7.2b) put it at about parity per crystal; this fight is where it pays.
- **Moment:** phase 2, the Colossus walks (Cracked Leg at 70 %). Hint with a ring on the boss: "Kilnwarden: Slag Rain
  the Colossus. Its stone armour melts from 25 to 5."
- **Card:** `Kilnwarden. Melts armour, burns mana: it makes big things soft and casters empty.`
- **Taught before:** trained since m01, but no earlier mission needs it. Champions (m03).

### 2.2 Episode 2 "The Light Below" (Fire, Vessa + Old Vey)
**e2m1 The Burning Grove: Old Vey** (helper, keep V at the Citadel; first call).
- **Best case:** a 12-minute hold of the Heartglade (r14) against waves that clump on two sides. H2 brings
  Shardcasters + Torvald, and H3 brings Nightbolts + a Gloom Deacon. Vey is strong against clumps, casters and ranged
  units, and Stormcall hits groups.
- **Moment:** the call hint at Citadel complete; his first Stormcall on H3's Nightbolt line (L19 "The spark first. Then
  the storm!").
- **Card:** `Old Vey. Your old teacher, sword and storm: call him at the Citadel and point him at the crowd.`
- **Taught before:** all of Episode 1; Vey as a story ally (m00, m04).

**e2m2 Roots and Embers: Ashveil Saboteur** (T3, keep C; unlocked e2m1).
- **Best case:** Torvald's **Rimehold** fort sits on the player's own bank: a Frost Hall + 3 Rime Spires behind
  5 Rimeshields. The Saboteur is disguised out of combat, and its Powder Charge (250) **pauses training for 10 s**.
  Strong against undefended bases and production buildings. The spec's intended answer already says "Saboteur charges on
  R1 / R3".
- **Moment:** before the Rimehold assault (9:00-13:00). A hint: "A Saboteur looks like a Rime Hauler. Walk it past
  the spires and charge the Frost Hall." The relief stops for 10 s and the Vice timer shows it.
- **Card:** `Ashveil Saboteur. Looks like their worker, works for you: blow the hall, stop the army before it's born.`
- **Taught before:** the Citadel (e2m1).

**e2m3 The Salt Road: Emberdart Harrier** (T1 Stables, Fire Stables card; **spec change: add it at Stables V**,
because X is the Ember Boar in this mission).
- **Best case:** a trade road raided by **Magpie bands** (melee, 140 HP) and slow Shade raids, with 6 caravans to
  protect. The harrier hits and runs: strong against slow melee and workers, good with Blaze Riders. Along the road it
  kites the raiders off the wagons.
- **Moment:** the first Magpie band (3:00) on caravan 1. Hint: "Emberdarts: throw and fall back. The Magpies chase
  you, not the wagon."
- **Card:** `Emberdart Harrier. Javelins on a gallop: throw, turn, throw. Nothing on foot catches it.`
- **Taught before:** Blaze Riders (m01); the Stables and gold are new here too.

**e2m4 Sunrise Road: the Ember Forge** (building + its research lines; first base built underground).
- **Best case:** a small army with no reinforcement wave of its own, a long descent, and **galleries 4-8 m wide**.
  Every fight is a narrow line fight, which is where +armour on the front Guard and +damage on few units count most.
- **Moment:** the research hint after the forge claim. The first Armor level lands before W2 (9:00), and a ping on the
  front Guard reads "Ember Mail: your Guards take less".
- **Card:** `Ember Forge. Make every soldier better, for good: armour and steel for the long road down.`
- **Taught before:** the "+" per-unit upgrades at the Hall (Ep1).
- **Consistency:** e2m4 uses the `research.md` lines (Quenched Blades, Ember Mail...). The built Forge is
  `unit-upgrades.md` (`ForgeKit`: Weapons / Armor / Kindled Fury + Ember Bowstrings / Lance Drill / Kiln Focus), and
  it is skirmish-only. Recommended: e2m4 uses the ForgeKit lines (Armor = "Ember Mail") through a mission knob
  `forge_enabled` (section 5).

**e2m5 The Light Below: Cinder Dragon** (Fire titan, Dragon Roost Z, from 8:00).
- **Best case:** the **Rift** is impassable for ground units, and **flyers cross it**. The Doorwarden's Wardens and
  Malrik's Shades cannot hit air well. The 8:00 message already sells it. It is a titan in a titan-boss fight.
- **Moment:** the first Dragon flies straight over the Rift onto Malrik's seal runners (L13 "I have a DRAGON").
- **Card:** `Cinder Dragon. Fire from the sky: it flies over the Rift and burns what walks below.`
- **Taught before:** Stables (e2m3), Forge (e2m4), every Fire soldier.

### 2.3 Shadow: Episode 3, then e5m3, e5m4 (origins) and e8m1_shadow
**e3m1 Take the Ford: Gloom Deacon** (caster, keep B; the spec already has a Deacon subsection).
- **Best case:** **fords slow by 35 % and fighting in them loses.** Umbral Passage carries up to 10 pop across the
  river **with no ford slow**. Blood Tithe keeps the Knights alive in the slow ford grind. The Deacon is strong in long
  fights and with trapped armies. Lab, Deacon + Shade **82 / 51 / 58**: fair at pop and strong with a Shade line.
- **Moment:** E7 at the ford fight (9:00-12:00): "Umbral Passage: bring the army over the water." A rift ring appears
  behind G1.
- **Card:** `Gloom Deacon. Heals your soldiers with their enemies' blood, and opens a road through the dark.`
- **Taught before:** the whole Shadow T1 card at once (this is Shadow's first mission), the Stronghold, 2v2.

**e3m2 Another Night: Mother Hush** (helper; played as a hero in phase 1, callable from phase 2).
- **Best case:** a night raid on a sleeping camp, enemy sight x0.6, 10 snuffable watch-fires. She is strong against
  casters, heroes and archers. The wagon guards are Ember Archers and Wildwood Archers, with Old Vey's vigil.
- **Moment:** WG2, the veiled wagon. Hush blinks past Vey's vigil, and a hint shows the veil ring.
- **Card:** `Mother Hush. The knife in the dark: call her, and the enemy's archers and casters stop sleeping well.`
- **Taught before:** e3m1 (Shadow kit, Deacon).

**e3m3 The Stone's Price: Nightblood Reaver** (T3, keep C; first trained e3m2).
- **Best case:** **an all-undead, all-melee enemy with no fire damage at all.** Ruin Wardens come 2 every 30 s per
  door, and the Gravewardens have 900 HP. The Reaver heals 35 % of its damage, halved only by fire. Blood Frenzy
  triggers under 40 %. Unit Guide: strong against heavy melee and long fights, weak against fire. Here there is none.
- **Moment:** B3 / B4 open (6:00). 2 Reavers hold a barrow lane alone. Hint: "Nightblood Reavers drink: in a long
  fight with no fire, they never fall."
- **Card:** `Nightblood Reaver. A duelist that drinks: the longer the fight, the stronger it stands. Fear fire.`
- **Taught before:** e3m2 (Citadel, Hush; the Reaver's Sunburn taught by e3m2's Ember Archers).

**e3m4 The Storm on the Ridge: Nightmare Knight** (Shadow titan, Dread Paddock Z, from 4:00).
- **Best case:** the spec is built around it: a fast melee boss who lunges (Old Vey). The charge (+90, knockback,
  daze) is the intended answer, and `sec_knight` rewards it.
- **Moment:** A1 (5:30), Vey's first storm. Hint E7: "The old man can't stop a horse."
- **Card:** `Nightmare Knight. A titan at a gallop: its charge breaks a line, or a storm.`
- **Taught before:** the Shard power (e3m3), Reaver, Hush.

**e5m3 Tombstones by Candlelight: Shade** (T1; here `shade_wild`, called 2 per old grave).
- **Best case:** a churchyard of **shadow zones**. A hidden unit is seen only within 2.5 m, and snuffed lamps make
  more dark. The Shade is cheap, many and strong in reach. Lab **88 / 70 / 78** (Shadow's strongest line per crystal).
  This is the dark it was made for, with one honest cost: it burns in light.
- **Moment:** E4, the first grave called ("You came when I called"). 2 Shades take a lone Gravewarden out of a yew
  shadow, while a lamp-lit patrol walks past without seeing.
- **Card:** `Shade. Cheap, quiet, many: in the dark they are everywhere. In the light they burn.`
- **Taught before:** Shadow's whole Ep3 kit (Shades trained since e3m1; the spotlight is the dark).

**e5m4 Leftovers: Grave Hound** (T1, Gloom Hall C).
- **Best case:** a 1v1 for **5 banners**. Malrik neutralises Vessa's banners x2 faster and gets +100 Spoils per
  steal. Vessa's half is open lawn, and her side is Flame Guard, Ember Archer, Blaze Rider, Ash Hurler. The hound is a
  fast harasser, strong against archers, workers and casters. The steal squad (6-8 units) rides on its speed.
- **Moment:** V4, the Charge (9:00). 70 % of Vessa's army leaves home, and hint E6 points at the Old Orchard shade 11 m
  from her banner. 4 hounds steal it while her army is away.
- **Card:** `Grave Hound. Fast teeth: go where her army isn't, take the banner, be gone.`
- **Taught before:** the Shade and the dark (e5m3).

**e8m1_shadow Put Down the Shovel: Hexweaver** (T2, Gloom Hall M).
- **Best case:** a boss **hero** (Mother Hush, 3 200 HP) and Risen **Barrow Knights**. The Hexweaver is strong
  against elite units, heroes and heavy cavalry. The spec's intended answer: "Hexweavers and Nightbolts behind
  Knights... Grave Mark on Hush". Lab **3 / 27 / 6, exempt** (debuff): it loses alone, so it needs exactly a boss.
- **Moment:** Hush at 75 % calls 4 Shades. Hint: "Hexweavers: hex Hush, not the Shades."
- **Card:** `Hexweaver. A curse for the big ones: heroes, knights and anything worth more than its friends.`
- **Taught before:** Episodes 3 and 5 for Malrik.

### 2.4 Nature: Episode 4, then e6m3, e6m4 (origins) and e8m1_nature
**e4m1 Hold Lark Hill: Bramblesage** (caster, keep B; the spec already has a Bramblesage subsection).
- **Best case:** ranged lines cross the ford behind melee (W3's 3 Nightbolts, W4's Shardcasters). Pollen Haze blinds
  4+ ranged units for 6 s. Snagroot drags the **Gloom Deacon** out of its channel and the Frost Mortars into the
  Oathkeepers. Lab, Bramblesage + Thornling **43 / 9 / 14**: the weakest caster entry, which is why it needs a ranged
  enemy to show anything.
- **Moment:** W3 ford fight (9:30). Hint E9: "Pollen Haze his archers, Snagroot his Deacon."
- **Card:** `Bramblesage. Pull the caster in, blind the archers: the forest reaches out.`
- **Taught before:** the whole Nature card at once (Nature's first mission).

**e4m2 The Green Road: Maelis** (helper, keep V, first call).
- **Best case:** a convoy through woods full of **dormant ambushes** (A1, A3: Hush + Shades). Maelis is strong
  against clumps and melee rushes, and Thornsnare roots a mounted or charge-ready enemy near Ysolde. The spec names
  Thornsnare on Hush.
- **Moment:** A3 at Crowstone Clearing. Hush blinks onto the convoy; Maelis's Thornsnare roots her and her Shades.
- **Card:** `Maelis. The Wildcaller of the wood: roots, wolves, and an ambush that ambushes back.`
- **Taught before:** e4m1, the Citadel (5:45 in this mission).

**e4m3 The Frozen Ashes: Briar Roc** (T3 flyer, keep C; first trained e4m2).
- **Best case:** an **Ice** enemy of totems, Rime Spires, Aldra's Glass Spire and Rimeshield clumps across 5
  far-apart glades. Seed Storm (30 + root 1 s) "roots from the air, out of the totems' reach". The Roc is strong
  against melee clumps, walls and chokes, and its sight finds what sits in the snow.
- **Moment:** Mossgate (15-18), the grove under Torvald's Rime Spire. Hint: "Rocs fly over the ice. Root the
  Rimeshields from above."
- **Card:** `Briar Roc. A thorn bird: walls don't stop it, and its seed storm roots the crowd below.`
- **Taught before:** Maelis, the Citadel.

**e4m4 Winter's End: Elder Treant** (Nature titan, Elder Circle Z).
- **Best case:** the spec calls it "the wallbreaker the mission is built around". There is a full-width ice Wall
  (1 200 HP pieces), soldiers deal x0.35 to it, and the Treant deals x1.0 net (rooted volley over the Wall).
- **Moment:** the first Treant at the West Gate (9-12), line E8.
- **Card:** `Elder Treant. A walking forest: root it, and it breaks walls that armies can't scratch.`
- **Taught before:** all of Ep4.

**e6m3 The Year Nothing Grew: Thornling** (T1, Grove Hall Z).
- **Best case:** frost wolves (120 HP, 6.2 m/s) **attack gardens only**. They never pick a fight with a unit, so a
  Thornling standing on a garden kills them while they chew. The Thornling is cheap, pop 1, and the line unit of
  Nature. Lab **68 / 24 / 35**: cheap bodies priced by supply. Here bodies are exactly what is needed.
- **Moment:** N1 (3:30), the first night. Hint: "Thornlings on the gardens: the wolves bite the seeds, your
  Thornlings bite the wolves."
- **Card:** `Thornling. Small, cheap, stubborn: plant them where it matters and they never move.`
- **Taught before:** Ep4 (Thornlings in every Ysolde army). The spotlight teaches **why**.

**e6m4 The First Crack: Wildwood Archer** (T1 bowman, Grove Hall B; the first mission that lets the player train it).
- **Best case:** the Hollow Host is **all slow melee** (Ruin Wardens, Breakers). The Throne seal hold pauses while
  any enemy is within 6 m, so killing at range is the win condition. The archer is strong against slow melee and in
  late mass fights. Lab **18 / 10 / 23, exempt**: it needs a line in front, and Torvald's Rimeshields stand there.
- **Moment:** the First Crack at 50 % (2 Breakers + 6 Wardens inside the ring). 6 Wildwood Archers on the isle
  pillars kill them before they reach the seal.
- **Card:** `Wildwood Archer. The long bow of the wood: behind a wall of shields, nothing slow comes through.`
- **Taught before:** Ep4 and e6m3.

**e8m1_nature Take a Side: Greenheart Oathkeeper** (T2, Grove Hall `,`).
- **Best case:** hamlets with a burn bar are raided by Stone-sworn **Shades + Grave Hounds** (Raid P), and Warden
  tides hit the road. The Oathkeeper is strong against divers, cavalry and melee rushes, and its taunt keeps the hounds
  off the archers. Lab **87 / 78 / 86** (a "next candidate" for a cut: it is strong).
- **Moment:** Raid P on Pipwell after K1. Hint: "Greenheart Oathkeepers: the oath holds the hounds."
- **Card:** `Greenheart Oathkeeper. A sworn blade: it calls the divers to itself and doesn't let them pass.`
- **Taught before:** Episodes 4 and 6 for Ysolde.

### 2.5 Fire origins: e5m1, e5m2 (Episode 5)
**e5m1 The First Spark: Ember Spire** (tower, worker build C).
- **Best case:** Reiver farm raids (2 Reivers every 120 s) and a valley mouth. Every rider and raider in the Unit
  Guide is weak against towers. It is a tier-1 refresher with no tier 2, so the tower is a real tool.
- **Moment:** the first farm raid. Hint: "Build an Ember Spire by the Millrace farms (worker, B then C)." The next raid
  breaks on it.
- **Card:** `Ember Spire. A tower that watches while you're away: raiders hate it.`
- **Taught before:** nothing (a refresher for new players: Ep5 can be a first chapter).

**e5m2 Burn a Door: Ember Archer** (T1, Ember Hall X).
- **Best case:** Sergeant Ashby's **Drill**: 4+ archers within 10 m fire one volley for **+25 %** with burning arrows.
  Wood takes x2 from fire, and Reivers are slow melee. Strong against slow melee. Lab **18 / 25 / 26, exempt**: alone
  it loses; drilled behind Guards it wins.
- **Moment:** S1, the sally from the Rook Gate. Ashby calls the volley (E6) and 6 archers burn the sally.
- **Card:** `Ember Archer. Alone, a bow. Drilled, a volley: keep four together behind the Guards.`
- **Taught before:** e5m1 (and Ep1-2 for veterans).

### 2.6 Ice origins: e6m1, e6m2 (Episode 6; Ice is first played here, before Episode 7)
**e6m1 A Hundred Winters: Rimeshield** (T1, Frost Hall Z; Ice's first mission).
- **Best case:** the snowbank ring has **4 gaps** that Wardens must come through. Floes break under enemy weight
  only. Blizzards slow the enemy -0.4. The Rimeshield is strong against archers in reach and light melee. Lab
  **90 / 93 / 92**: the strongest line unit alone. A gap of 8 m is a Rimeshield's dream.
- **Moment:** W1b (4:30), 4 Wardens at the SW gap. Hint: "Rimeshields in the gap. Nothing gets past armour and
  patience."
- **Card:** `Rimeshield. Armour and patience: put it in a gap and the gap is closed.`
- **Taught before:** nothing Ice (Torvald's first mission).

**e6m2 The Rider at the Gate: Frostbow** (T1 bowman, Frost Hall B; opens here).
- **Best case:** road columns of slow Wardens come through **the only gap in the Long Ice**, and the Frostbow's long
  chill slows them on the road. The spec's hint already names "Frostbows (long chill) on the columns". Strong against
  slow melee and fleeing units. Lab **16 / 62 / 23, exempt** (a good bowman per pop).
- **Moment:** the first road column after the choice. Frostbows on the gate spires' line chill it short of the town.
- **Card:** `Frostbow. Every arrow chills: what walks toward it walks slower, and slower.`
- **Taught before:** e6m1 (Rimeshield, Ice Walls, Aldra's Sentinels).

### 2.7 Ice: Episode 7, then e8m1_ice
**e7m1 The Dragon Auction: Rimecarver** (caster, keep B; the spec already has a Rimecarver subsection).
- **Best case:** "a map of doors": two 6 m causeways, two 9 m fords and two 5 m bridges. Rime Bulwark (4 m wall, 8 s)
  closes a causeway with 2 casts or cuts Blaze Riders off a caravan, and Scrying Rune watches a ford. Strong against
  melee rushes, divers and hidden units. The 7.2b sweep ranks it lowest per crystal head-on; doors are where it pays.
- **Moment:** W1 (4:30), 3 Blaze Riders on a caravan. Hint E8: "Bulwark the causeway: the riders stop, the caravan
  doesn't."
- **Card:** `Rimecarver. The wall comes to you: close a door in front of the charge, see what hides behind it.`
- **Taught before:** Ep6 (Ice T1, Ice Walls).

**e7m2 First Blood, and No Further: Aldra** (helper, keep V, first call).
- **Best case:** a siege of the Sun Barricade and the Tollrock's archer garrison (Gilded Spears + Ember Archers). Aldra
  is strong against archer armies, casters and lines; Glass Aegis and Shatterglass.
- **Moment:** the rock assault (~9:30) right after her first call. Glasswater Ward on the climbing column under the G2
  archers.
- **Card:** `Aldra. The Glass Warden: she shields the army's walk and shatters the line at the end of it.`
- **Taught before:** e7m1, the Citadel (5:45 here).

**e7m3 The Outwall: War Mammoth** (Ice titan, freed in the mission; 2 000 HP, armor 30).
- **Best case:** a press of Aurivane landings (Flame Guards, Gilded Spears) and masked Shades on the pit headland,
  45-60 m from the docks. The Mammoth grinds lines and buildings (titans-2 8.2 "the Mammoth grinds bases"), and its
  armor 30 shrugs off the Shade swarm.
- **Moment:** the mammoths are freed (~14:00), and the Night Tide's pit front (17:00) breaks on them.
- **Card:** `War Mammoth. A titan of the far north: it walks through a line like snow through a fence.`
- **Taught before:** Aldra, the Citadel, the Shardguard (trained since e7m2).

**e7m4 The Year of Two Skies: Shardguard** (T3, keep C; first trained e7m2).
- **Best case:** W1 (Vessa + **4 Blaze Riders**), M2 (**6 Grave Hounds** + 4 Barrow Ghouls) and M6 (4 Grave Hounds)
  are every kind of charge and dive. Hold the Line stops a charge and freezes the rider 1 s, and taunts divers off the
  archers. Strong against cavalry, divers and heavy melee.
- **Moment:** M2 after the Turn: 6 hounds dive the Shardcasters on the rock. Hint: "Shardguards beside the
  Shardcasters: Hold the Line."
- **Card:** `Shardguard. The halberd that says no: charges stop, divers turn, archers live.`
- **Taught before:** all of Ep7 (the Shardguard's Hush beat in e7m2 is a preview).

**e8m1_ice The Gate Opens: Frost Mortar** (T2, Frost Hall `,`).
- **Best case:** a refugee column with a **240 s rest at the Hearth Camp** (static: the Mortar sets up), the H3 hound
  pack, and 8 Wardens + a Sentinel at the Southway Crack. The Mortar is strong against clumps and static lines. The
  spec says "Frost Mortars at the camp kill the H3 hound pack". Lab **76 / 76 / 78**: a T2 ranged unit that wins.
- **Moment:** H3 at the camp (6:30-8:00). The hounds clump on the refugees and one Mortar shell lands.
- **Card:** `Frost Mortar. Far and heavy: when they bunch up, one shell freezes the lot.`
- **Taught before:** Episodes 6 and 7 for Torvald.

### 2.8 Episode 8: e8m1_fire, then e8m2 and e8m3 (variants by the chosen kingdom)
**e8m1_fire The Spark Waits: Pyre Adept** (T2, Ember Hall B).
- **Best case:** hold the west bank for 14:00. The Host comes in tides of 6-14 Wardens, which **clump in fords that
  slow them 35 %**, and waiting (the Gathering Storm) pays. The Adept is strong against swarms and clumped units. Lab
  **76 / 93 / 77**: a T2 ranged unit that wins head-on, at its best behind a line.
- **Moment:** H6 (12 Wardens + 2 Sentinels) at Reed Ford. Hint: "Pyre Adepts behind the Guards: the ford is a
  furnace."
- **Card:** `Pyre Adept. A battle mage for crowds: let them bunch up in the water, then burn the bunch.`
- **Taught before:** everything Fire.

**e8m2 The Last Muster: the kingdom's T2 heavy rider** (S1 variant; Stables C): **Pyrehoof Lancer** (Fire) /
**Barrow Knight** (Shadow) / **Rimehorn Rider** (Ice) / **Thornback Charger** (Nature).
- **Best case:** escorting a key-bearer across a 168 m map with 10 crossings, against Ruin Warden infantry lines.
  Heavy riders are strong against line infantry, archers and siege. Lab after the 2026-10-06 pass: Pyrehoof
  **55 / 73**, Barrow Knight **61 / 74**, Rimehorn **65 / 73**, Thornback **60 / 70** (all <= 75, fair and still
  strong).
- **Moment:** the Keyhole Rush (A1 pylon dies: 8 Wardens + 2 Sentinels). A hint pings the Stables: "Heavy riders:
  break the Rush before it reaches the keyhole."
- **Card (Fire):** `Pyrehoof Lancer. A boar and a lance: lines break where it hits.` Shadow: `Barrow Knight. Grave
  steel on a dead horse: it hits the line and the line forgets it was one.` Ice: `Rimehorn Rider. Armour that charges:
  every hit chills.` Nature: `Thornback Charger. A stag of thorns: through the line, then turn and do it again.`
- **Taught before:** the kingdom's light rider (Fire: Blaze Rider, m01). **Spec change:** e8m2's unlocks must list the
  Stables (cavalry on).

**e8m3 The Hollow King: the kingdom's T3 elite rider** (S1 variant; Stables V): **Sunforge Cataphract** /
**Veilborn Dreadrider** / **Frostcrown Juggernaut** / **Glade Outrider**.
- **Best case:** phase 1 "Four Chains". The King tears at the **weakest** Key-Ward and sends Wardens there, and the four
  keyholes are far apart. An elite rider squad is the fast reserve that saves a ward in time. Rubble Sentinels are heavy
  melee; the heavy elites are strong against heavy melee. The Glade Outrider is a horse archer that hits from the pit's
  lip.
- **Moment:** the first Rubble Call on a ward at < 60 %. Hint: "Your elite riders: the King's tearing at that chain.
  Ride."
- **Card (Fire):** `Sunforge Cataphract. The best of the Stables: armour, speed, and a hit that ends arguments.`
  Shadow: `Veilborn Dreadrider. The hardest hitter of the Stables: it arrives, and something falls.` Ice: `Frostcrown
  Juggernaut. The toughest rider there is: it chills what it doesn't break.` Nature: `Glade Outrider. Arrows at a
  gallop: ride the rim and never stop shooting.`
- **Taught before:** the heavy rider (e8m2). **Spec change:** as e8m2 (Stables).

## 3. The shared beat (how every spotlight plays)
1. **Card.** When the spotlight is first **available** (at start, or at its unlock event), a small card slides in at
   the left of the objectives panel. It shows the portrait (`art/icons/units/<id>.png`, else the Unit Guide's
   abbreviation), the name, the card line, the Unit Guide's **Strong against** tags, and a key hint
   (`Ember Hall: V`). It stays 12 s or until clicked, and never holds the world. Clicking it opens the Unit Guide on
   that unit (pause menu screen).
2. **First train.** The first time a player unit of that type appears, it gets a `flash_ring` and a gold outline for
   6 s, plus one voice line from the mission (most specs already have one).
3. **The moment.** The beat in section 2 is a normal E-list event in the mission: a hint, a ping, sometimes a spawn
   tweak. It is no new system.
4. **Seen once.** The campaign save remembers `spotlight_seen_<id>`. A replay shows the card small (one line, 4 s).
   The Unit Guide shows "Spotlight: <mission title>" on that unit.

## 4. Gaps: units no mission spotlights
| Kingdom | Unit | Where it would shine (its best case in the existing specs) | Why it has no slot |
|---|---|---|---|
| Fire | Cinder Arbalest (T2) | e2m2's Rimehold (5 Rimeshields; strong against infantry lines and heavy melee); Lab 30 / 76 / 40 | e2m2 is the Saboteur's (buildings); e2m1 is Vey's |
| Fire | Scorchbow (T1 bowman) | e8m1_fire's slow Warden tides (strong against slow melee) | **No spec unlocks it** ("skirmish only", or "if the card has it" in e8m1_fire) |
| Fire | Scorchling (T1) | Only as the enemy (e5m4, young Vessa's bot) | No spec unlocks it for the player |
| Fire | Ember Crucible (Lair C) | e2m5's slow option (a free Guard every 40 s) | It is a building mode, not a unit; e2m5 is the Dragon's |
| Shadow | Nightbolt | e3m1's north bank, shooting into the ford (cover stones) | Shadow's first mission is the Deacon's |
| Shadow | Shadow Knight | e3m1's ford grind under Blood Tithe | Same |
| Shadow | Barrow Ghoul | e8m1_shadow (the Stone's Gift raises them: the moral trap) | e8m1_shadow is the Hexweaver's |
| Shadow | Hollow Oathsworn (T2) | Any long line fight; Lab 53 / 64 after the cut | No mission needs it more than another unit |
| Shadow | Bleakbow (T1 bowman) | A boss hero (e8m1_shadow: Hush); strong against tanks, heroes | No spec unlocks it ("if on the card") |
| Shadow | Gloam Rider, Duskbolt Harrier (Stables T1) | e5m4's banner raids | Stables are off in every Shadow mission before Ep8 |
| Ice | Shardcaster | e7m4's galleys ("Shardcasters on the bank... melee cannot") | e7m4 is the Shardguard's |
| Ice | Rime Seer | e7m2's archer garrison (strong against archer volleys) | e7m2 is Aldra's |
| Ice | Rimeling | Cheap pop-1 body; no clear best case | - |
| Ice | Rime Colossus | e6m1 / e6m2 (Aldra's carved Sentinels are Rime Colossi: **shown, not trained**) | e6m1 is the Rimeshield's |
| Ice | Hoarlight Magebow (T2) | e7m1's Blaze Rider raids (strong against cavalry, casters) | e7m1 is the Rimecarver's |
| Ice | Snowdrift Rider, Rime Harrier (Stables T1) | - | Stables off in every Ice mission before Ep8; **Frostbow** is also listed "locked" in all of e7 but is in e8m1_ice's start army (fix in e7 specs) |
| Nature | Burr Slinger, Thistle Darter | e6m3's frost wolves (strong against slow melee: wolves are fast, so no) | No fair best case in the Nature missions |
| Nature | Bloomtender | e6m3's long nights (long fights, chip damage) | e6m3 is the Thornling's (the wolves ignore units, so healing has little to do) |
| Nature | Bramblehorn | e4m4's Wall garrisons (ranged in reach) | e4m4 is the Treant's |
| Nature | Vinelasher (T2) | e4m1's Birchwater picket (armour 15; the spec suggests Vinelashers) | e4m1 is the Bramblesage's |
| Nature | Stagrunner, Bramble Harrier (Stables T1) | - | Stables off in every Nature mission before Ep8 |
| Neutral | Oathwall, Coin-Cutter, Mender (champions) | m04 / Ep2 bounties | m03 spotlights the Wayfinder only |
| Neutral | Stormbottle Genie | **e8m3** (x1.5 on titans; the Hollow King has titan tags) | Taverns are off in e8m3; the slot goes to the kingdom's elite rider |
| Neutral | Caravan, Greywater Tracker | e2m3 (taught as the mission's objective) | e2m3 spotlights the Emberdart Harrier |
**Unfair to spotlight at all** (no mission gives it a best case): Rimeling, Burr Slinger, Thistle Darter (cheap fillers
whose best case is "priced by supply"), the three **unlocked-nowhere** units Scorchbow, Scorchling and Bleakbow, and the
T1 Stables riders of Shadow / Ice / Nature (no Stables in their episodes).

Two cheap ways to show the gaps anyway (pick one, both optional):
- **Field notes** (recommended): a second, smaller hint per mission (no card, one line + a ping), using the "where it
  would shine" column. For example, e3m1: "Nightbolts behind the ford stones: they shoot, the river slows the enemy."
  Cost: one E-list event per mission.
- **Open the locked units**: Scorchbow on the Ember Hall in e2m1+ and Bleakbow on the Gloom Hall in e3m2+, plus the
  Stables for each kingdom in its episode's mission 3. This is a design change for the spec owners and a bot / balance
  check. Not done here.

## 5. Framework hook (design only; for `mission-framework.md`)
See `mission-framework.md` section 7. In short: `MissionConfig.spotlight` (data), `MissionBase.show_spotlight()` /
first-train highlight (systems-coder), `Events.spotlight_shown` (lead, core), a `SpotlightCard` in the MissionHud
(ui-coder), a `spotlight_seen_<id>` flag (CampaignState), and a test part `spotlight` in `test_mission_framework.gd`. Plus
`forge_enabled` (a mission knob that lets `ForgeKit.enabled_here()` say yes) for e2m4.

## 6. Spec changes this doc asks for (spec owners; nothing edited here except each spec's Spotlight section)
| # | Spec | Change |
|---|---|---|
| X1 | `mission-e2-03.md` | Stables card: V Emberdart Harrier (X stays the Boar) |
| X2 | `mission-e2-04.md` | Research = the `ForgeKit` lines through `forge_enabled` (or keep `research.md` and rename the spotlight "research") |
| X3 | `mission-e8-02.md`, `mission-e8-03.md` | Unlocks list the kingdom's Stables (heavy C, elite V) |
| X4 | `mission-e7-0x.md` | Frostbow "locked" vs `mission-e8-01.md` C start army with Frostbows: open it from e7m1 or drop it from e8m1_ice |
| X5 | `campaign-outline.md` 3.x | Spotlight column added (done) |
