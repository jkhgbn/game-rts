# Episodes 3 and 4 openings: two life stories, one battle, one map ("The Battle of Evenmead")

Owner: game-designer. Written 2026-09-27 (task E34.D1). Draft: nothing here is built. Builds on `story-episode-1.md`
("ep1": cast, sections 2 and 10 = Episode 2 direction), `t3-helpers.md` ("th.": the 4 allies), `cinematics.md`,
`prologue-movie-plan.md`, and the tool READMEs `tools/cine/`, `tools/world_forge/`, `tools/lens/`. Every name, line,
cue and place here is our own. Metres, seconds; set coordinates `(x, z)`, +z = south.
User requests (JS, 2026-09-27, verbatim): "have a new main for episode 3 start with the main wizard telling his life story
how he became so strong and it will not stop add the battle is about to start so make it plains hills the paradise i will
let choose who would fit the bill the best" · then: "same for episode 4 same battle same 1 map to make lol".

## 0. Reading and verdicts
| # | Reading | Verdict |
|---|---|---|
| R1 | "A new main for episode 3": Episode 3 stars a new playable wizard, and opens on him narrating his life: how he got so strong, and that he will not stop | Kept. Cinematic `ep3_opening`, ~1:31 (ep1 U1: nothing over 2:00) |
| R2 | A battle is about to start on beautiful plains and hills ("paradise") | Kept: **Evenmead**, "the last green country", the Master's own garden. Two armies form on two facing hills with a river between |
| R3 | Episode 4 does the same: another narrator, **the same battle, the same map** | Kept: `ep4_opening` is **the other side of the same morning** (the opposing commander). One set `forge_evenmead` for both openings and one battle map `evenmead` for both episodes' first mission (section 7) |
| R4 | "Campaign 3" (the earlier note in `th.` R5, read then as mission 3) | Now that Episode 3 exists, "campaign 3" most likely meant **Episode 3**: each episode stars one wizard **with its helper**. Episode 3 = Malrik + Mother Hush, Episode 4 = Ysolde + Maelis. It fits `th.` 1 exactly (Q4) |

### 0.1 Where Episodes 3 and 4 sit in the arc
Ep1 "The Hollow Throne": Fire vs Shadow; Obren's body falls; **Malrik escapes with Obren's heart-stone** (the Keystone
Shard). Ep2 "The Light Below": Ice joins Shadow, **Ysolde's army is destroyed and her Sighing Wood burned and frozen**,
she joins Fire; the war becomes 2v2 (ep1 10). **Episodes 3-4 are the second half of the saga: the 2v2 war's great
open-field battle.** Shadow + Ice (Malrik, Torvald) march on Evenmead, Nature's last green country; Fire + Nature
(Ysolde, Vessa, Old Vey) stand on the facing hill. Ep3 is the **dark chapter** (the player plays the villain's rise);
Ep4 is the **answer** (the same morning from the side that must hold). Both first missions are the same battle on the
same map with different goals (7), so both can "win" their episode's opening: Malrik takes the ford, Ysolde saves the
tree and her people.

## 1. Episode 3 narrator: three candidates
- **★ Malrik, the Hollow Bishop (recommended). Villain protagonist.** He fits every word of the request: male, "the
  main wizard" (one of the four), and the only one whose strength is a story of *taking*. Ep1 ends with him holding
  Obren's beating heart-stone ("Oh, it is not done"); by Ep3 it has made him the strongest wizard on the field, and
  the question the episode asks is whether he uses the stone or the stone uses him. "It will not stop" is his whole
  character: every loss (the knives at Emberfall, the Hollow) left him something. The Ep1 thread "Especially Malrik"
  keeps him redeemable later, so Ep3 plays him as a villain the player understands, not as a monster. Helper: Mother Hush.
- **Torvald, the Ice wizard. Grey ally of the villain.** Old and patient; "a hundred winters" of guarding the Heartfrost
  made him strong, and he will not stop until the Hollow is sealed forever, even beside Malrik. Strong, but his voice is
  weariness, not unstoppable drive, and his defection is Ep2's story, already told.
- **Old Vey, the Storm-Sword. Hero.** "How he became so strong" is literally his mystery (the lightning "since before
  you were born"). But ep1 10 already promises "Vey's story told at last" in Ep2, he is an ally and not one of the four,
  and he has no kingdom or keep to play. Better as Ep2's reveal than Ep3's main.

## 2. Episode 4 narrator: three candidates (the other side of the same morning)
- **★ Ysolde of Nature (recommended). Hero.** Evenmead is hers: she was born on its high hill, the Master planted it,
  and it is all she has left after Ep2 burned her wood. Her story answers Malrik's line for line: his strength is what he
  took, hers is what comes back ("it grows back", ep1 10). JS's words turn with her: Malrik says "I will not stop"; she
  ends on "It will not stop" (the green). Never told yet, the most to lose, and the natural commander of this ground.
  Helper: Maelis Oakenhollow.
- **Vessa of Fire. Hero.** The series' face and the fighter of the other army. Her life story (the first spark, Vey)
  was already the heart of Ep1, so Ep4 would retell known beats; and on Ysolde's land she is the guest, not the keeper.
- **Torvald of Ice. Turning point.** The same morning from Malrik's own hill: the ally who watches the stone whisper,
  and turns at the end. A strong twist, but it breaks JS's "same battle" symmetry (both openings from one hill) and
  spends Torvald's turn before the story earns it.

## 3. The monologues (subtitles: `|` = line break, <= 2 x 48 chars, <= 17 chars/s; `at` / `dur` in the shot)
These tables are the line tracks: E34.C1 / C2 write them as `data/story/ep3_opening.lines.json` /
`ep4_opening.lines.json` (the cine `use lines` format, by hand until Script Desk exists). Voice: subtitles only first.

### 3.1 `ep3_opening` "The Gravedigger's Son" (Malrik; 15 lines, ~78 s of speech in 91 s)
| # | Shot | at / dur | Text |
|---|---|---|---|
| L1 | B01 | 3.0 / 3.4 | Everyone tells my story wrong. Let me try. |
| L2 | N02 | 0.3 / 5.2 | I was a gravedigger's son. I grew up\|among the dead. They were better company. |
| L3 | G03 | 0.4 / 5.2 | The Master found me reading tombstones\|by one candle. He said: this one, too. |
| L4 | G04 | 0.3 / 5.2 | Too. Fourth of four. Fire was his joy,\|ice his patience, the wood his heart. |
| L5 | N05 | 0.3 / 5.0 | And me? He gave me what was left over.\|The dark. As if it were a kindness. |
| L6 | G06 | 0.3 / 5.0 | Then he vanished and left us nothing.\|So I took. That is the whole secret. |
| L7 | N07 | 0.3 / 5.6 | I took the dark and taught it to kneel.\|I took knives, and a woman who never misses. |
| L8 | W02 | 0.3 / 5.3 | She missed. Emberfall. Then the Hollow.\|I lost, and lost, and every time I lost, |
| L9 | G09 | 0.3 / 5.0 | I kept something. A candle. A knife.\|A stone that still beats in my hand. |
| L10 | N10 | 0.5 / 5.2 | It whispers. Let it. I am the one who\|listens, and I am the one who decides. |
| L11 | N11 | 0.3 / 5.2 | That is how a gravedigger's son grows\|strong: he never puts the shovel down. |
| L12 | N12 | 0.3 / 4.8 | Look at it. The last green country.\|Flowers to the knee. The Master's garden. |
| L13 | N12 | 5.3 / 4.5 | They will stand there and tell me to stop.\|Fire. Roots. An old man's storm. |
| L14 | N13 | 0.4 / 2.6 | I have heard "stop" all my life. |
| L15 | N13 | 3.3 / 2.0 | I will not stop. |

### 3.2 `ep4_opening` "What Grows Back" (Ysolde, 1 line Vessa; 15 lines, ~75 s of speech in 88 s)
| # | Shot | at / dur | Speaker | Text |
|---|---|---|---|---|
| L1 | B01 | 3.0 / 4.6 | ysolde | Malrik tells his life as a list of wounds.\|Mine is a list of winters. |
| L2 | S02 | 0.3 / 5.0 | ysolde | I was born on that hill, the year\|nothing grew. Not one blade of grass. |
| L3 | H03 | 0.4 / 5.1 | ysolde | My mother buried seed in the snow.\|The village laughed. I watched it sleep. |
| L4 | H04 | 0.3 / 4.4 | ysolde | In spring it came up green. I have\|never forgotten how that felt. |
| L5 | H05 | 0.3 / 5.1 | ysolde | A tall man with a burning hem found me\|coaxing a sapling through the frost. |
| L6 | S06 | 0.3 / 5.0 | ysolde | He said: show me again. So I did,\|for twenty years, until he was gone. |
| L7 | S07 | 0.3 / 5.0 | ysolde | They call me soft. Neutral. Slow.\|Slow is how an oak outlives an army. |
| L8 | H08 | 0.3 / 5.0 | ysolde | Last winter they burned my wood\|and froze the ashes. My army with it. |
| L9 | H09 | 0.3 / 5.2 | ysolde | I knelt in the black, and I waited.\|Something green came up. It always does. |
| L10 | S10 | 0.3 / 5.3 | ysolde | That is my strength. Not fire. Not knives.\|I come back. Every spring. Every time. |
| L11 | S11 | 0.3 / 5.1 | ysolde | The Master planted this country with his\|own hands. He left it to me to keep. |
| L12 | S12 | 0.3 / 4.6 | ysolde | Malrik stands up there with his candle,\|his stone, and Torvald's winter. |
| L13 | S12 | 5.1 / 3.2 | ysolde | Let them come. Cut it. Burn it. Freeze it. |
| L14 | S13 | 0.3 / 1.8 | vessa | Ysolde. They're moving. |
| L15 | S13 | 2.6 / 2.0 | ysolde | It will not stop. |
The echoes are deliberate: the same first shot (B01), "I will not stop" / "It will not stop", the two ends meeting on
the same horn (4.1), and each monologue naming the other side (L13 / L12).

## 4. The shared World Forge set `forge_evenmead` (both openings; the battle map's centre at 1:1, section 7)
Brief: a wide valley at golden hour. Knee-high grass full of daisies, dandelions and clover; a slow river with reeds
and a stone ford; two gentle hills facing each other across it (north: Malrik's ridge, south: Lark Hill with the
Master's lone golden tree); oak and birch woods on the flanks; snowy mountains far north on the horizon ring; birds,
butterflies and pollen in the low sun. **0 lights, <= 150 draws.** Axis rule: the Malrik - Ysolde line runs north-south;
**Ep3 cameras stay east of it (x > line), Ep4 cameras west**: each film is consistent, and Ep4 reads as the reverse
angle of Ep3. Both wizards face the valley, so "3/4-left" puts the camera on the valley side for both (a true 180-degree
echo). Lines marked NEW need E34.W1 (section 6).
```
set forge_evenmead  size=150x120  ground=grass  light=warm  seed=34  title="Evenmead: the last green country"
budget draws<=150 lights<=0
hill  north_ridge  center=(4,-44)  radius=34  height=7        # NEW: ground height; scatter / actors / paths sit on it
hill  lark_hill    center=(-6,42)  radius=28  height=6        # NEW
hill  west_roll    center=(-52,-6) radius=22  height=3        # NEW
hill  east_roll    center=(50,12)  radius=20  height=2.5      # NEW
path  river  poly=[(-75,6),(-44,-3),(-18,4),(4,0),(26,-7),(50,-2),(75,5)]  width=6  kit=river
row   res://art/environment/biomes/riverbank/rb_reeds.res  poly=[(-75,10),(-44,1),(-18,8),(0,5)]  spacing=4  jitter=2
row   res://art/environment/biomes/riverbank/rb_river_stones.res  from=(4,-4) to=(4,4)  spacing=1.2  jitter=0.6
place kit:standing_stones  at=(12,9)   yaw=25  tag=ford_stones
place kit:gold_tree        at=(-10,37) scale=1.8  tag=master_tree
place res://art/environment/horizon/horizon.tscn  at=(0,0)    # mountain ring; snow peaks to the north
zone  crest_n  circle((0,-36),9)
zone  crest_s  circle((-5,34),9)
scatter res://art/environment/biomes/meadow/meadow_daisies.res     area=rect((-75,-60),(75,60))  count=90  gap=3  seed=1  avoid=cams,crest_n,crest_s
scatter res://art/environment/biomes/meadow/meadow_dandelions.res  area=rect((-75,-60),(75,60))  count=60  gap=3  seed=2  avoid=cams
scatter res://art/environment/biomes/meadow/meadow_clover.res      area=rect((-75,-60),(75,60))  count=50  gap=3  seed=3  avoid=cams
scatter res://art/environment/biomes/glade/glade_flowers.res       area=circle((-6,40),26)       count=50  gap=2  seed=4  avoid=cams,crest_s
scatter res://art/environment/biomes/glade/glade_tall_grass.res    area=rect((-75,-14),(75,14))  count=40  gap=3  seed=5  avoid=cams
scatter kit:broadleaf  area=rect((-75,-60),(-56,60))  count=14  gap=6  seed=6  scale=1.0..1.4
scatter kit:birch      area=rect((56,-60),(75,60))    count=12  gap=5  seed=7
scatter kit:boulder    area=rect((-70,-55),(70,55))   count=10  gap=8  seed=8  avoid=cams  scale=0.6..1.1
row   forge:army_rank  from=(-30,-27) to=(22,-29)  spacing=6.5  kind=shadow  yaw=0     # NEW baked kit, 1-2 draws each
row   forge:army_rank  from=(26,-31)  to=(44,-27)  spacing=6.5  kind=ice     yaw=-10
row   forge:army_rank  from=(-32,26)  to=(-6,24)   spacing=6.5  kind=nature  yaw=180
row   forge:army_rank  from=(0,24)    to=(26,27)   spacing=6.5  kind=fire    yaw=185
place forge:banner  at=(2,-33)  kind=shadow  tag=banner_n                                # NEW
place forge:banner  at=(-2,31)  kind=nature  tag=banner_s                                # NEW
actor malrik   kit:malrik   at=(0,-36)     yaw=0
actor torvald  kit:torvald  at=(-3.4,-37)  yaw=8
actor hush     res://art/units/shadow/shade.tscn  at=(2.8,-37.5)  yaw=-6    # stand-in until 19.V23
actor stone    forge:heart_stone  at=(0.35,-35.6)  y=1.15                    # NEW prop, amber emission
actor ysolde   kit:ysolde   at=(-5,34)     yaw=180
actor vessa    kit:vessa    at=(-1.6,35)   yaw=188
actor vey      res://art/units/fire/flame_guard.tscn  at=(-8.4,35.5)  yaw=176   # stand-in until 19.V20
actor bloom    forge:bloom_patch  at=(-5.8,35.4)                             # NEW: flower patch by Ysolde's hand
# landscape marks (explicit); the close shots are solved by Lens (4.1) and merged as marks N02... S13
mark B01   from=(62,42,24)   to=(40,15,14)   look=(-6,2,-6)   look_to=(-4,4,-18)  fov=46  fov_to=40  subject=ford_stones  dur=8
mark N05   from=(-26,8,-19)  to=(-6,8.5,-20) look=(-20,6,-28) look_to=(0,6,-29)   fov=38  subject=banner_n  dur=6
mark N12   from=(1.4,8.4,-38.5)  look=(-6,8,34)   fov=22  subject=master_tree  dur=10
mark B14   from=(70,40,0)    to=(60,42,-8)   look=(0,2,0)     fov=50  subject=ford_stones  dur=7
mark S06   from=(22,7,19)    to=(2,7.5,20)   look=(16,5,26)   look_to=(-4,5,26)   fov=38  subject=banner_s  dur=6
mark S12   from=(-6.4,7.6,36.4)  look=(0,9,-36)   fov=22  subject=malrik  dur=9
mark B14R  from=(-70,40,0)   to=(-60,42,8)   look=(0,2,0)     fov=50  subject=ford_stones  dur=7
```
Draw estimate: ground + river + paths 4, scatter ~12 (one per material), trees ~6, horizon 3, army ranks 16, banners 2,
puppets ~70 (4 wizards x ~16 + stand-ins), props 4: **~120**. If over: stand-ins out of their far shots (`hide`).
If `hill` is not built in time: build flat, drop every mark's y by 6-7 m, and let the horizon ring carry the hills.

### 4.1 Lens words for the close shots (`tools/lens/specs/ep34_opening.lens`, `bg set=forge_evenmead`)
| Ep3 shot | Words | Ep4 mirror | Words |
|---|---|---|---|
| N02 | `ms on malrik, 3/4-back-left, high, push 0.2` | S02 | `ms on ysolde, 3/4-back-left, high, push 0.2` |
| N07 | `mcu on malrik, 3/4-left, low` | S07 | `mcu on ysolde, 3/4-left, low` |
| N10 | `ecu on stone, front, high` | S10 | `ecu on bloom, 3/4-left, high` |
| N11 | `ms two-shot malrik torvald, 3/4-left, eye` | S11 | `ms two-shot ysolde vessa, 3/4-left, eye` |
| N13 | `cu on malrik, front, eye, push 0.3` | S13 | `cu on ysolde, front, eye, push 0.3` |
`run_lens.ps1 marks ep34_opening set=forge_evenmead` -> `marks.json`; World Forge merges; the `.cine` also names the
words (`cam=lens`) so a reader sees the intent.

### 4.2 Memory sets (one per episode, flashbacks; memories cut in on `fade_white:0.4`, out on `blend:0.3`)
| Set | Size / ground / light | Corners (x offset) and marks | Draws |
|---|---|---|---|
| `forge_ep3_memories` | 70 x 24, `crypt`, `crypt` | **G03** graveyard (x -24): `row kit:slab` gravestones, `forge:candle` (NEW), a boy = `kit:malrik` scale 0.72 (stand-in), mark over the candle toward the boy. **G04 / G06** the orrery (x 0): 4 actors `flame_r/_b/_g/_v` = `forge:brazier color=` (NEW key) in a ring, the boy at the edge; G06 is the same corner, the four flames `hide` one by one (the Master is gone). **G09** Hollow rubble (x 24): `kit:ruin_pillar`, `kit:shards`, actor `stone` | <= 60 |
| `forge_watch_keep` (exists) | as built | **W02** Vessa at the gate at nightfall: "She missed" (she is alive). Reused as is | 118 |
| `forge_ep4_memories` | 80 x 24, `grass`, `dawn` | **H03** winter (x -30): `path kit=snow width=14` as a snow patch, actor `seed` = `res://art/units/nature/sapling.tscn` scale 0.25. **H04** spring (x -10): meadow scatter, the sapling scale 0.8. **H05** the Master (x 10): actor `master` (NEW stand-in: hooded, 4-colour hem) + child `kit:ysolde` scale 0.7 + sapling. **H08 / H09** the burned wood (x 30): `path kit=ash width=16`, `scatter` of the ash-biome meshes, `kit:giant_stump`, `kit:shards` (frozen ash), actor `shoot` = sapling scale 0.15 (H09 = ecu on it) | <= 70 |

## 5. Shot lists as draft `.cine` (`data/cinematics/src/`; `cine check` will judge them)
### 5.1 `ep3_opening.cine` (14 shots, 91 s)
```
cine ep3_opening  title="The Gravedigger's Son"  letterbox=2.39  seed=34  length=80..100
use set forge_evenmead
use lines data/story/ep3_opening.lines.json
use music res://assets/audio/forge/music/ep3_opening.wav
# axis malrik-ysolde (north-south): every Ep3 camera east of it
shot B01 8.0  in=fade_black:1.0                       # golden crane over Evenmead; birds, pollen
  at 0.0  sfx res://assets/audio/forge/sfx/evenmead_amb.wav
shot N02 6.0  cam=lens "ms on malrik, 3/4-back-left, high, push 0.2"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_N02.json
shot G03 6.0  set=forge_ep3_memories  in=fade_white:0.4   # the boy, a candle, the tombstones
  at 0.2  sfx res://assets/audio/forge/sfx/shovel_earth.wav
shot G04 6.0  set=forge_ep3_memories                      # four flames: red, blue, green... violet last
shot N05 6.0  in=blend:0.3                                # Shadow ranks lower their visors
  at 1.0  sfx res://assets/audio/forge/sfx/army_armour.wav
shot G06 6.0  set=forge_ep3_memories  in=fade_white:0.4   # the flames go out: he is gone
  at 1.5  hide flame_r
  at 2.5  hide flame_b
  at 3.5  hide flame_g
  at 4.5  hide flame_v
shot N07 6.5  cam=lens "mcu on malrik, 3/4-left, low"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_N07.json  in=blend:0.3
  at 2.0  clip hush draw_knife                            # falls back to a hook (WARN) until Motion Lab
shot W02 6.0  set=forge_watch_keep  in=fade_white:0.4     # Emberfall at night: Vessa lives
  at 0.4  sfx res://assets/audio/forge/sfx/knife_ring.wav
shot G09 6.0  set=forge_ep3_memories                      # the rubble; the stone pulses amber
  at 0.5  vfx heart_stone_pulse at=stone
shot N10 6.0  cam=lens "ecu on stone, front, high"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_N10.json  in=blend:0.3
  at 0.2  sfx res://assets/audio/forge/sfx/obren_whisper.wav
  at 0.5  vfx heart_stone_pulse at=stone
shot N11 6.0  cam=lens "ms two-shot malrik torvald, 3/4-left, eye"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_N11.json
  at 3.0  clip torvald turn_head_right                    # Torvald glances at the stone
shot N12 10.0                                             # long lens across the valley: Lark Hill, the golden tree
shot N13 5.5  cam=lens "cu on malrik, front, eye, push 0.3"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_N13.json
shot B14 7.0                                              # horns; both armies step off
  at 0.5  sfx res://assets/audio/forge/sfx/evenmead_horns.wav
  at 3.0  title "Episode 3" sub="The Gravedigger's Son" time=3.5
  at 6.2  fade alpha=1 time=0.8
```
### 5.2 `ep4_opening.cine` (14 shots, 88 s): the reverse angles of the same morning
```
cine ep4_opening  title="What Grows Back"  letterbox=2.39  seed=34  length=80..100
use set forge_evenmead
use lines data/story/ep4_opening.lines.json
use music res://assets/audio/forge/music/ep4_opening.wav
# axis malrik-ysolde: every Ep4 camera west of it. B01 is Ep3's shot, frame for frame (same seed): "the same morning"
shot B01 8.0  in=fade_black:1.0
  at 0.0  sfx res://assets/audio/forge/sfx/evenmead_amb.wav
shot S02 6.0  cam=lens "ms on ysolde, 3/4-back-left, high, push 0.2"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_S02.json
shot H03 6.0  set=forge_ep4_memories  in=fade_white:0.4   # seed in the snow
  at 0.3  sfx res://assets/audio/forge/sfx/snow_step.wav
shot H04 5.0  set=forge_ep4_memories                      # the same seed, spring, green
shot H05 6.0  set=forge_ep4_memories                      # a burning hem, a child, a sapling in frost
  at 0.5  vfx four_flame_hem at=master
shot S06 6.0  in=blend:0.3                                # Nature and Fire ranks, marching the other way on screen
  at 1.0  sfx res://assets/audio/forge/sfx/army_armour.wav
shot S07 6.0  cam=lens "mcu on ysolde, 3/4-left, low"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_S07.json
shot H08 6.0  set=forge_ep4_memories  in=fade_white:0.4   # black stumps, frozen ash
  at 0.3  sfx res://assets/audio/forge/sfx/ice_creak.wav
shot H09 6.0  set=forge_ep4_memories                      # ecu: one green shoot in the black
  at 1.0  vfx green_shoot at=shoot
shot S10 6.0  cam=lens "ecu on bloom, 3/4-left, high"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_S10.json  in=blend:0.3
  at 1.0  vfx bloom_open at=bloom                         # the flowers lean toward her hand
shot S11 6.0  cam=lens "ms two-shot ysolde vessa, 3/4-left, eye"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_S11.json
shot S12 9.0                                              # long lens north: Malrik's ridge, an amber glint
  at 2.0  vfx heart_stone_pulse at=stone
shot S13 5.0  cam=lens "cu on ysolde, front, eye, push 0.3"  lens_spec=res://docs/tools/lens/out/ep34_opening/camera_S13.json
shot B14R 7.0                                             # the same horns, from the south
  at 0.5  sfx res://assets/audio/forge/sfx/evenmead_horns.wav
  at 3.0  title "Episode 4" sub="What Grows Back" time=3.5
  at 6.2  fade alpha=1 time=0.8
```
Mirror pairs: B01 = B01, N02/S02, N05/S06 (opposite screen directions: the armies march at each other across the two
films), N07/S07, N10/S10 (stone / flowers), N11/S11, N12/S12 (each sees the other hill), N13/S13, B14/B14R.

## 6. Tools: what works today, what needs building
| Tool | Today | Needs building for these films (fallback until then) |
|---|---|---|
| `cine` (tool 2) | Grammar, `use set` / `use lines`, set switches per shot, fades, titles, check (framing, 180-degree rule, subtitles CPS), stills, build, record | Nothing. A soft **memory grade** (desaturate / warm tint) would be nice; fallback = the memory sets' own light presets |
| Lens (tool 3) | Words -> CameraSpec / set marks, measured framing | Nothing |
| World Forge (tool 6) | Sets, scatter / rows baked, paths (river, snow, ash), actors, marks, checks, sheet | **E34.W1**: `hill` statement (flat ground only today); kits `forge:army_rank kind=` (baked ranks of soldier silhouettes with spear tips, 1-2 draws), `forge:banner kind=`, `forge:candle`, `forge:heart_stone`, `forge:bloom_patch`, `color=` on `forge:brazier`; confirm `scatter` / `row` take biome `.res` meshes (else kit aliases) |
| Motion Lab (tool 5, not built) | - | Gestures: Malrik opens his hand, Torvald turns his head, Hush draws knives, Ysolde kneels and touches the grass, Vessa turns; army ranks shuffle. Fallback: cine's clip -> hook fallback (WARN), still poses, the camera moves carry it |
| VFX Composer (tool 7, not built) | - | `heart_stone_pulse`, `obren_whisper` wisps, `four_flame_hem`, `bloom_open`, `green_shoot`, pollen / butterflies in the sun, snowfall (H03). Fallback: emission props, missing id = WARN |
| Script Desk (tool 10, not built) | - | Line tracks: hand-written JSON from section 3 (same format), CPS checked by `cine check` |
| Sound Forge (tool 9, not built) | - | The cues of section 6.1. Fallback: silent build; `assets/audio/forge/` paths are WARN, not FAIL, in cine |

### 6.1 Music and SFX (Sound Forge spec, original; `assets/audio/forge/specs/evenmead.sound`)
```
music ep3_opening  len=91  bpm=60  key=A minor  xfade=0.5          # 1 bar = 4 s
  stem bed     drone A1 E2  pad=low_choir
  stem candle  notes=[A4 C5 B4 E4]  patch=glass_bell  every=2 bars  # Malrik's motif, falling
  stem heart   pattern="x..x...."  patch=stone_thump  from=bar 13   # the stone (G09 on)
  stem drums   pattern="x...x.x."  patch=war_drum  from=bar 22      # B14: the horns
music ep4_opening  len=88  bpm=60  key=A major  xfade=0.5
  stem bed     drone A1 E2  pad=warm_strings
  stem seed    notes=[E4 A4 G#4 C#5]  patch=wood_flute  every=2 bars # Ysolde's motif, rising (Malrik's, inverted)
  stem birds   grains=12  f=2500..5000  from=bar 1
  stem drums   pattern="x...x.x."  patch=war_drum  from=bar 21      # the same drums at the same horn
sfx evenmead_horns  takes=2  len=6   # a low Shadow horn, answered by a higher Nature horn: shared by both films
sfx evenmead_amb    takes=1  len=20  # wind in grass, larks, the river, far armour (loops)
sfx obren_whisper   takes=3  len=2.5 # breath and stone grit, no words
sfx stone_thump     takes=3  len=0.6 · shovel_earth takes=3 · knife_ring takes=2 · army_armour takes=3
sfx snow_step       takes=4 · ice_creak takes=3 · sapling_creak takes=2 · candle_pinch takes=2
```

## 7. The one map (JS: "same 1 map to make")
`data/maps/evenmead.map` (World Forge map mode): 120 m, `symmetry=mirror_z`, seat 0 south (Lark Hill, Fire + Nature),
seat 1 north (the ridge, Shadow + Ice); river and ford exactly where the set has them (the set is the map's centre at
1:1, so the film shows the ground the player then fights on). **Ep3 mission 1** "Take the Ford" (play Malrik, north
seat) and **Ep4 mission 1** "Hold Lark Hill" (play Ysolde, south seat: save the Master's tree and the villagers until
nightfall) run on this one map with different objectives. Mission specs come after JS's answers.

## 8. Art needs
| Need | Exists? | Owner / task |
|---|---|---|
| Malrik, Torvald, Ysolde, Vessa models | Yes (`art/units/wizards/`) | - |
| Army models, sapling, Shade (Hush stand-in), Flame Guard (Vey stand-in) | Yes | - |
| Meadow / glade / riverbank / ash scatter meshes, broadleaf / birch / gold tree, boulders, standing stones, horizon, water | Yes (`art/environment/`) | - |
| Mother Hush, Old Vey game models | Planned (19.V23, 19.V20), not built | tech-artist (stand-ins meanwhile) |
| Heart-stone prop (fist-sized amber stone, cracked, emission pulse) | New | E34.V1 |
| The Master stand-in for ENGINE (tall hooded figure, face in shadow, beard of light, 4-colour hem; ep1 2 look) | New (video-only in ep1) | E34.V2 |
| Golden-hour light preset (`preset_golden.tres`: low warm sun, long shadows, soft haze) | New (`warm` meanwhile) | E34.V3 |
| Young Malrik / child Ysolde | Stand-ins (scaled models) now; real models later if JS wants | later |
| Banners (4 kingdoms), army ranks, candle, bloom patch | New World Forge kits | E34.W1 |

## 9. Tasks
| Id | Owner | What | Done when |
|---|---|---|---|
| E34.D1 | game-designer | This doc | Written; JS's answers recorded here |
| E34.D2 | game-designer | Episode 3 and 4 outlines (missions, cast, helper moments) + both first-mission specs on `evenmead` | After JS's answers; each mission <= 70 % fight rule (ep1 4.1) |
| **Shared** E34.W1 [H] | four-wizards-high | World Forge: `hill`, the 5 new kits, `color=` on brazier, `.res` scatter check | `run_world_forge.ps1 demo` still PASS; a test set with 2 hills and 4 army ranks builds, D1 deterministic |
| **Shared** E34.W2 | four-wizards-high | `forge_evenmead` (section 4) | `build` 0 FAIL, draws <= 150, 0 lights; `sheet.png` shows every mark with its subject in band |
| **Shared** E34.L1 | four-wizards-high | `ep34_opening.lens` (4.1) + `marks` into the set | 10 shots PASS coverage +-10 %, faces in band |
| **Shared** E34.V1-V3 | tech-artist | Heart-stone, Master stand-in, golden preset | Art Lab pass, 0 lights, contact sheet |
| **Shared** E34.M1 | four-wizards-high | `data/maps/evenmead.map` | Map Lab >= 90, the river / ford / hills match the set within 1 m |
| **Shared** E34.S1 | ui-coder | `evenmead.sound` cues (6.1) once Sound Forge exists | Audio Lab 0 FAIL; lengths +-0.05 s; the horn lands on the same bar in both cues |
| Ep3 E34.W3 | four-wizards-high | `forge_ep3_memories` | `build` 0 FAIL, <= 60 draws |
| Ep3 E34.C1 | four-wizards-high | `ep3_opening.cine` + `ep3_opening.lines.json` | `cine check` 0 FAIL (framing, axis, CPS), length 91 +-1 s, `build` bakes the `.tres` |
| Ep4 E34.W4 | four-wizards-high | `forge_ep4_memories` | `build` 0 FAIL, <= 70 draws |
| Ep4 E34.C2 | four-wizards-high | `ep4_opening.cine` + lines | As C1, 88 +-1 s; B01 stills identical to Ep3's (`cine diff`) |
| Later | four-wizards-high / tech-artist | Motion Lab clips, VFX Composer effects, Sound Forge music re-run through both films | `cine check` WARN count drops to 0 |
| Later | systems / ui | StoryFlow and Story menu for Episodes 3-4 (episode cards, Theatre) | Both openings play from the Story menu and skip cleanly |

## Questions for the user (recommendation first)
1. **Episode 3's narrator**: (a) **Malrik**, the villain's rise, strong from Obren's heart-stone ("I will not stop")
   (b) Torvald (c) Old Vey.
2. **Episode 4's narrator**: (a) **Ysolde**, the other side of the same morning, on her own land ("It will not stop")
   (b) Vessa (c) Torvald, from Malrik's own hill, who turns at the end.
3. **The one map**: (a) **both first missions on the same Evenmead map, opposite sides, different goals (Malrik takes
   the ford; Ysolde saves the tree and her people)** (b) the map only for the two films (c) one mission, played twice
   as a pure mirror.
4. **"Campaign 3"**: (a) **you meant Episode 3: each episode stars one wizard with its helper (Ep3 Malrik + Mother
   Hush, Ep4 Ysolde + Maelis)** (b) you meant mission 3 (the Sighing Wood) as read before.
5. **Flashbacks**: (a) **in-engine now, in small memory sets, same look as the rest** (b) keep them for the later
   pre-rendered video pass.
6. **Names**: (a) **"Evenmead", Episode 3 "The Gravedigger's Son", Episode 4 "What Grows Back"** (b) you name them.
