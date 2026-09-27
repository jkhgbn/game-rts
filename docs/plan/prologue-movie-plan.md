# Prologue movie: production plan for ONE 5-hour window

Written 2026-09-26 by the production planner for the lead. Step 19, user requests ~19:30 / ~19:35 (`waves.md` step 19).
Specs it builds on: `docs/design/story-episode-1.md` (sections 1, 2, 7), `docs/design/cinematics.md` (the player, the
overlay, the video pipeline). Everything is original: no names, lines, music or art from existing works.

**What exists today (checked in the repo):** no `scripts/cinematics/`, `data/cinematics/`, `missions/cinematics/` or
`art/cinematics/` yet (19.C1 / 19.U1 / 19.L1 not built); no Old Vey, Mother Hush, Master or Obren model; no `mission_00`
(the campaign starts at `m01`, `missions/mission_01.tscn`, from the main menu's Campaign panel). What we can stage with:
the 4 wizard models (`art/units/wizards/{vessa,malrik,torvald,ysolde}.tscn`, hooks `set_moving`, `play_cast(id)`,
`play_attack`, `play_hit`, `set_seated(on, mount)`, 1 staff `OmniLight3D` each), every army model (`art/units/fire|ice|
nature|shadow/`), the 5 mounts, the titans (`cinder_dragon`, `frost_dragon`, `war_mammoth`, `elder_treant`,
`nightmare_knight`, `barrow_giant`), neutral creatures (deer, Ruin Warden, Rime Colossus...), the caravan, every keep /
hall / tower, the environment kits (`horizon.tscn`, biome sets glade / heath / meadow / old_wood / riverbank / ruins,
`river_mouths` waterfall meshes, landmarks `colossus` / `aqueduct` / `standing_stones` / `giant_stump`, `crown_pedestal`,
critters), `LightingRig` + `LightingPreset` (`apply(preset)` switches the mood at runtime), and the **menu diorama**
(`art/environment/menu_diorama/menu_diorama.tscn`: the four apprentices around the Ember Crown altar at dusk). VFX hubs
with a public `play()`: `TitanVfx`, `UnitVfx`, `MapFillVfx`, `ChampionVfx`; `SpellVfx` / `IceVfx` / `NatureVfx` hook
any Node3D in group `"heroes"` that has a child `SpellCaster` (signals `spell_cast(id)`, `spell_effect(id, pos)`),
`get_model()`, `body_height` (so a small cast proxy can drive the real spell effects on puppets, task 19.P7).

**"Reuse Episode 1 footage" in practice:** none of the 5 Episode 1 videos or stage sets exists yet. So the prologue
reuses the Episode 1 **shot designs and lines** (`ep1_intro` shots 1-3, 4, 6, 9, 10-11; `c2_two_fronts` shot 8) and
the models already built, and **builds the first version of the Episode 1 sets it needs** (observatory, Malrik's
crypt, Ysolde's oak, Emberfall at night, the Master stand-in) in the `cinematics.md` folders, so Episode 1 reuses them
later instead of the other way round. Nothing is built twice (ledger in section 1.3).

---

## 0. Decisions in one table
| Question | Decision | Why / fallback |
|---|---|---|
| Structure | **3:00 = 1:00 world building + 4 x 0:30 wizard intros** (Torvald, Ysolde, Malrik, **Vessa last**), 26 shots, then straight into the first mission | Vessa last so her block ends on the night of knives and cuts into M0 |
| Engine | One **deterministic in-engine timeline**: the `CinematicScript` data format of `cinematics.md` 2 + a STAGE-only `CinematicPlayer` ("19.C1-lite", same files, extended later by 19.C1) driving 7 stage sets | Nothing throw-away: Episode 1 uses the same player, overlay, story flow and sets |
| **Shipping format** | **Live in-engine playback** (`missions/cinematics/prologue.tscn`) is what the game plays. The `.ogv` is recorded from the same timeline in wave 3 as a **trailer / Theatre copy / pipeline proof**, kept outside `res://` unless the user picks video (Q2) | Live = 0 MB, full width and native resolution on the user's 3440 x 1440 (a 16:9 video would be pillarboxed to 2560 x 1440 and upscaled from 1080p), no ffmpeg dependency, and it updates for free when Vey / Hush / the Master get real models. The recording can slip without blocking the ship |
| Fallback | If live playback misses 60 fps on the GTX 1660 after the perf pass: ship the `.ogv` (task 19.P18 player) | Both come from one timeline; switching is one constant in StoryFlow |
| Skip | **Locked for the first 30.0 s**: Esc / Space do nothing and show nothing. From 0:30 the `cinematics.md` 6.4 rule: first press shows `Esc / Space: skip`, second press skips; one press when already seen | User rule ~19:35. New field `CinematicScript.skip_locked_until = 30.0` |
| Hand-off | End or skip -> `StoryFlow` marks `prologue` seen -> starts **`m00` if its scene exists, else `m01`** (today: `m01`) through `MenuFlow.start_mission` | Never breaks the campaign start: the smoke test (`scenes/main.tscn`) and `MenuFlow` are untouched |
| When it plays | Campaign Start on the **first mission** while `prologue` is not in `cinematics_seen`; afterwards a **Prologue** replay button in the campaign panel (Theatre-lite, returns to the menu) | |
| Lights (live) | The `LightingRig` of the stage (one sun, the only shadow caster, + its shadowless fill) with one `LightingPreset` per set, applied at each set switch. **0 new real lights**; allowed only what reused models / scenes already ship with (1 staff light per wizard, the diorama's). Fire, candles, windows = emission + particles | `cinematics.md` 10 "ENGINE stages" rule |
| Lights (recording only) | Each set may add a `RecordingExtras` node (omni / spot lights with shadows, SSAO, SSIL, volumetric fog). The set frees it in `_ready` unless `Engine.get_write_movie_path() != ""` | Video pays its cost offline (`cinematics.md` 1 row "Lights"); never rendered in the game |
| Live render | Native window size, letterbox 2.39:1 (`bar = max((H - W/2.39)/2, 0.03 H)`: 43 px at 3440 x 1440, 115 px at 1600 x 900), 3D resolution scaled like the menu diorama (target ~2 MP, FSR 1, min 0.5, restored on exit), **60 fps on the GTX 1660**, <= 150 extra draw calls per set, one set visible at a time | Same method the menu already ships |
| Recording | **1920 x 804 (2.39:1, the `cinematics.md` 8.6 "scope" knob), 30 fps**, `.ogv` (Theora + Vorbis), keyframe <= 64 frames, subtitles **not** burnt in (drawn by the game), the title card **burnt in** (the V1 rule) | Framed for 2.39 anyway; full width on 21:9, ~25 % smaller than 1080p |
| Size | Live: 0 MB of video (sets are primitives, a few MB of meshes). Video: **target <= 35 MB** (3:00 at ~11-12 MB/min), hard cap 45 MB. If shipped it takes the `ep1_intro` line of the <= 115 MB episode budget (30 MB) + 5-15 MB | `cinematics.md` 9 |
| Audio | Generated placeholder music bed (5 cues) + 5 stingers, `Music` / `SFX` buses (the volume sliders work). **No voice this window**: subtitles carry the narration (Q1) | No copyrighted audio. Voice later: a `CinematicLine.voice` path is already optional in the data |

---

## 1. The shot list (3:00, 26 shots)
Sets (section 2.3): **WORLD** `prologue_world` · **OBS** `prologue_observatory` · **CROWN** `prologue_crown` · **ICE**
`prologue_ice` · **NAT** `prologue_nature` · **SHD** `prologue_shadow` · **FIRE** `prologue_fire` (two sub-locations:
`keep` at golden hour, `emberfall` at nightfall). Camera modes are the `CinematicShot` modes (`cinematics.md` 3); every
shot's camera comes from markers `<shot>_from`, `_to`, `_look_from`, `_look_to` (`_pivot`, `_rail`) placed by the set
artist. Subtitles: 2 lines max, <= 48 characters per line (`|` = line break). Speaker colours from
`story-episode-1.md` 2. Cuts are hard cuts unless a fade is named. **Skip unlocks at 0:30 (inside P05).**

### 1.1 Shot table
| # | Time | Set | Subjects (models) | Camera | VFX / action | Narration / line | Subtitle | Source |
|---|---|---|---|---|---|---|---|---|
| P01 | 0:00-0:07 | WORLD | Dusk sky, `horizon.tscn` far canopy, a single ember | FADE_BLACK in (1.0 s, prewarm under it), then CRANE down from 60 m to 14 m, fov 40 -> 34 | One ember drifts up past the lens | Narrator: Once upon a time, a peaceful world... | `Once upon a time, a peaceful world...` | NEW line (the user's sentence), REUSED `ep1_intro` 1 crane idea |
| P02 | 0:07-0:14 | WORLD | Riverbank + meadow biome sets, `mouth_falls` waterfall, 3 `deer`, birds (critters), the `caravan` crossing `road_bridge`, `aqueduct` on the skyline | RAIL low along the river, 1.5 m above the water | Waterfall mist, birds lift off | Narrator: ...was about to have its first world war, between four strong wizards. | `...was about to have its first world war,` \| `between four strong wizards.` | NEW |
| P03 | 0:14-0:21 | OBS | The observatory as it was: brass dome on its crag (`rock_spire` / `rock_slab`), lanterns (emission) | DOLLY in from 40 m to 15 m, slight crane up | Lantern glow, star field | Narrator: Before the kingdoms, there was the Master. | `Before the kingdoms, there was the Master.` | REUSED `ep1_intro` 1 (line and shot) |
| P04 | 0:21-0:29 | OBS | Interior: the Master stand-in (back to camera) at a giant brass orrery, 4 small flames orbiting (red, blue, green, violet); a swordsman silhouette at the door, back to camera (`oathwall` champion model, `set_weapon_class(&"two_hand")`, dark team colour) | DOLLY in behind the Master | Orbiting flames (emission + trails, `MenuDiorama.GLOW` colours) | Narrator: He raised four apprentices, and gave each of them a kingdom. | `He raised four apprentices,` \| `and gave each of them a kingdom.` | REUSED `ep1_intro` 2 (line split; the swordsman = the first Vey hint) |
| P05 | 0:29-0:35 | OBS | The Master; the regalia (crown from `art/environment/crown/`, orb, signet placeholders) | STATIC low angle, then FADE_WHITE (0.6 s) at 0:34.4 | The orrery stops, a hairline amber crack glows in the floor, the robe falls empty, the regalia burst up through the dome as sparks. Stinger `gone` | Narrator: Then, between one breath and the next, he was gone. | `Then, between one breath and the next,` \| `he was gone.` | REUSED `ep1_intro` 2 action; line from `story-episode-1.md` 1 |
| P06 | 0:35-0:42 | WORLD | The land at dusk, high | CRANE up and wide, 30 -> 70 m | 3 amber meteor ribbons fall toward 3 horizons (emission ribbons, set anim). Stinger `regalia` | Narrator: His regalia fell across the world, and a rumour fell with them: | `His regalia fell across the world,` \| `and a rumour fell with them:` | NEW |
| P07 | 0:42-0:48 | CROWN | `crown_pedestal` in the **Sealed** look, 4 dormant `ruin_warden`s, ruins biome set, `ruin_pillar`s | ORBIT 40 degrees around the altar, radius 9 m | Seal runes pulse | Narrator: whoever gathers them becomes the next god. | `Whoever gathers them becomes the next god.` | REUSED the M1 crown altar (built) |
| P08 | 0:48-0:54 | CROWN | The menu diorama: Vessa, Malrik, Torvald, Ysolde facing the altar from the four sides, the tavern in the back | STATIC wide (the diorama's own wide framing, drift off) | Kingdom glows at rest | Narrator: Fire. Ice. Nature. Shadow. | `Fire. Ice. Nature. Shadow.` | REUSED `ep1_intro` 3 line + the built menu diorama |
| P09 | 0:54-1:00 | CROWN | Same, altar in the **Stirring** look | DOLLY slow push toward the empty altar between them | The 4 kingdom glows swell one after the other; the seal flickers | Narrator: Four heirs, one empty throne. And the peace was running out. | `Four heirs, one empty throne.` \| `And the peace was running out.` | REUSED `ep1_intro` 3 (first half) |
| P10 | 1:00-1:07 | ICE | Frozen lake at dawn, `ice_keep`, `ice_wall`, `ice_spire`, `rimeshield`s on the walls | CRANE down over the lake toward the keep | Snowfall (1 particle system), ice sheet (`icebound_sheet` shader) | Narrator: In the north, Torvald of Ice. The eldest, and the most patient. | `In the north, Torvald of Ice.` \| `The eldest, and the most patient.` | NEW (cue `ice`) |
| P11 | 1:07-1:14 | ICE | `torvald` alone on the ice (cast proxy) | ORBIT 70 degrees, radius 6 m, height 1.8 m | `flash_freeze` through the proxy: IceVfx frost circle + shards erupting around him | Narrator: He trusts slow ice more than quick friends. | `He trusts slow ice more than quick friends.` | NEW |
| P12 | 1:14-1:22 | ICE | `frost_dragon` gliding low over the lake, `war_mammoth` with howdah on the shore, `rime_colossus` sentinel | CRANE from the dragon down to the ice | TitanVfx frost breath trail over the ice; frost spreads under its shadow | Narrator: His lake has kept a secret for a hundred winters. | `His lake has kept a secret` \| `for a hundred winters.` | NEW (echoes M2 L8) |
| P13 | 1:22-1:30 | ICE | `torvald` close-up | STATIC close-up, fov 30 | He turns his head south (`turn_head_left` if 19.P15 lands, else camera-only) | Torvald: Let the young ones quarrel. Ice can wait. | `Let the young ones quarrel. Ice can wait.` | NEW (sets up C1 "No. For now.") |
| P14 | 1:30-1:37 | NAT | Old Wood + glade biome sets, `nature_keep` grown into the trees, `nature_hollow`, fireflies | CRANE down through the canopy | Fireflies, leaf fall | Narrator: In the west, Ysolde of Nature, who keeps her wood out of every quarrel. | `In the west, Ysolde of Nature,` \| `who keeps her wood out of every quarrel.` | NEW (cue `nature`) |
| P15 | 1:37-1:44 | NAT | `ysolde` (cast proxy) on a burnt patch; `sapling` / `sprigling` puppets | DOLLY around her, low | `wild_bloom` through the proxy: NatureVfx blooming circle; the saplings grow in (scale tween); the burnt patch greens | Narrator: Burn her forest down, and it grows back. Usually angrier. | `Burn her forest down, and it grows back.` \| `Usually angrier.` | REUSED `ep1_intro` 3 (Ysolde coaxing a sapling) |
| P16 | 1:44-1:52 | NAT | `elder_treant` stepping out of the trees, a `grove_stag`; an old oak (scaled `tree_broadleaf` / `giant_stump`) | Over Ysolde's shoulder, slow DOLLY | Ysolde lays her hand on the oak; roots close over a glowing white-gold ring deep in the trunk (set anim) | Narrator: Some say she guards more than trees. | `Some say she guards more than trees.` | REUSED `c2_two_fronts` 8 (the hidden Signet) |
| P17 | 1:52-2:00 | NAT | `ysolde` close-up | STATIC close-up, fov 30 | Leaves drift through the frame | Ysolde: Fight if you must. Not in my wood. | `Fight if you must. Not in my wood.` | NEW (her Episode 1 stance) |
| P18 | 2:00-2:07 | SHD | `dusk_keep`, `shadow_hall`, `shadow_tower` in violet mist at night; `shade`s on the walls, `grave_hound`s, a `barrow_giant` silhouette | RAIL along the wall at night | Violet mist (fog preset), motes | Narrator: In the east, Malrik of Shadow. Clever, patient, and never satisfied. | `In the east, Malrik of Shadow.` \| `Clever, patient, and never satisfied.` | NEW (cue `shadow`) |
| P19 | 2:07-2:14 | SHD | Crypt corner: `malrik` reading a letter with a red wax seal by one violet candle | STATIC mid shot, slow push | Candle = emission + 1 small flame particle (no light live; a shadowed omni in `RecordingExtras`) | Narrator: He reads every letter in the world, especially the ones not meant for him. | `He reads every letter in the world,` \| `especially the ones not meant for him.` | REUSED `ep1_intro` 9 (set and action) |
| P20 | 2:14-2:22 | SHD | `malrik` standing (cast proxy); `shadow_knight` + 3 `shade`s melting out of the dark; `nightmare_knight` eyes opening in the dark | Low angle DOLLY back | `umbral_shroud` through the proxy (SpellVfx), the soldiers fade in (dissolve tween) | Narrator: What he cannot win in the light, he takes in the dark. | `What he cannot win in the light,` \| `he takes in the dark.` | NEW |
| P21 | 2:22-2:30 | SHD | `malrik` close-up with the candle | STATIC close-up | He pinches the flame out (`pinch` gesture or a hand tween); the frame dims. Stinger `candle_out` | Malrik: Pity. She always did burn too bright. | `Pity. She always did burn too bright.` | REUSED `ep1_intro` 9 (line and action) |
| P22 | 2:30-2:36 | FIRE `keep` | `fire_keep`, `fire_hall`, `fire_tower`, `hearth`; `flame_guard`s drilling (`play_attack` loop), `ember_archer`s, `blaze_rider`s; `cinder_dragon` gliding over | CRANE down at golden hour | Embers in the air, banners | Narrator: And in the south, Vessa of Fire. The youngest, the proudest, the loudest. | `And in the south, Vessa of Fire.` \| `The youngest, the proudest, the loudest.` | NEW (cue `fire`) |
| P23 | 2:36-2:43 | FIRE `keep` | `vessa` (cast proxy) laughing among sparks, a straw practice target (new prop), guards watching | ORBIT 50 degrees, radius 5 m | `fireball` through the proxy: wind-up, a streak, SpellVfx impact + scorch; the target bursts | Vessa: Problem? Fire. Bigger problem? More fire. | `Problem? Fire. Bigger problem? More fire.` | REUSED `ep1_intro` 3 (Vessa laughing among sparks) |
| P24 | 2:43-2:51 | FIRE `keep` -> `emberfall` | Vessa reads a letter by the hearth, then rides out: `vessa` seated on an `ember_boar` (`set_seated(true, boar)`) with 4 `flame_guard`s up a crag road at dusk | 0:00-0:03 STATIC on the letter, then FOLLOW the ride (cut inside the shot = 2 sub-shots in the data) | Dust at the hooves, the sky turns dusk | Narrator: Then an old friend wrote to her: the crown at Emberfall was waking. | `Then an old friend wrote to her:` \| `the crown at Emberfall was waking.` | REUSED `ep1_intro` 4 (the ride) + story 1 (the letter) |
| P25 | 2:51-2:56 | FIRE `emberfall` | The ruined watch-keep on the crag at nightfall (ruins set + `fire_tower` as the keep, watch-fire), Vessa's party small in frame; a `shade` detaching from the wall | Slow push past the wall toward the fire | Watch-fire (emission + embers); a knife glint. Stinger `knife` | Narrator: Vessa rode out that same night. So did Malrik's knives. | `Vessa rode out that same night.` \| `So did Malrik's knives.` | REUSED `ep1_intro` 6 (the shadow with a knife) |
| P26 | 2:56-3:00 | (black) | - | FADE_BLACK 0.3 s | Title card `FOUR WIZARDS` then `Episode 1 · The Hollow Throne` (overlay title, burnt into the recording). Stinger `title`. Hard cut to the mission at 3:00 | Narrator: And so the war began. | `And so the war began.` | REUSED `ep1_intro` 10-11 (line variant + title) |
Durations: world 60 s (7+7+7+8+6+7+6+6+6), Torvald 30 s (7+7+8+8), Ysolde 30 s (7+7+8+8), Malrik 30 s (7+7+8+8), Vessa
30 s (6+7+8+5+4) = **180 s**. Shot count **26** (27 data shots: P24 is split in two).

### 1.2 Narration script (one block; speaker in brackets when not the Narrator)
```
[0:00] Once upon a time, a peaceful world...
[0:07] ...was about to have its first world war, between four strong wizards.
[0:14] Before the kingdoms, there was the Master.
[0:21] He raised four apprentices, and gave each of them a kingdom.
[0:29] Then, between one breath and the next, he was gone.
[0:35] His regalia fell across the world, and a rumour fell with them:
[0:42] whoever gathers them becomes the next god.
[0:48] Fire. Ice. Nature. Shadow.
[0:54] Four heirs, one empty throne. And the peace was running out.
[1:00] In the north, Torvald of Ice. The eldest, and the most patient.
[1:07] He trusts slow ice more than quick friends.
[1:14] His lake has kept a secret for a hundred winters.
[1:22] [Torvald] Let the young ones quarrel. Ice can wait.
[1:30] In the west, Ysolde of Nature, who keeps her wood out of every quarrel.
[1:37] Burn her forest down, and it grows back. Usually angrier.
[1:44] Some say she guards more than trees.
[1:52] [Ysolde] Fight if you must. Not in my wood.
[2:00] In the east, Malrik of Shadow. Clever, patient, and never satisfied.
[2:07] He reads every letter in the world, especially the ones not meant for him.
[2:14] What he cannot win in the light, he takes in the dark.
[2:22] [Malrik] Pity. She always did burn too bright.
[2:30] And in the south, Vessa of Fire. The youngest, the proudest, the loudest.
[2:36] [Vessa] Problem? Fire. Bigger problem? More fire.
[2:43] Then an old friend wrote to her: the crown at Emberfall was waking.
[2:51] Vessa rode out that same night. So did Malrik's knives.
[2:56] And so the war began.
       FOUR WIZARDS · Episode 1 · The Hollow Throne
```
Each line starts 0.5 s after its shot starts; auto duration `max(2.5, 0.9 + 0.055 x chars)`, cut at the shot end.
Continuity: no Obren, no twist, no Vey lightning on screen (M0 and Episode 1 keep their reveals); Vey appears only as
the letter and the swordsman silhouette.

### 1.3 Reuse ledger (what the prologue borrows, what Episode 1 later borrows back)
| Prologue | Borrows | Episode 1 reuses later |
|---|---|---|
| P03-P05 observatory + Master stand-in | `ep1_intro` 1-2 design, crown mesh kit | `ep1_intro` / `m3_memory` 7 (19.V15, 19.V14 start from this set and stand-in) |
| P07-P09 crown | Menu diorama, `crown_pedestal` looks | - (already shipping) |
| P16 Ysolde's oak | `c2_two_fronts` 8 design | `c2_two_fronts` 8 (19.V8 grove corner) |
| P19-P21 crypt | `ep1_intro` 9 design + line | `ep1_intro` 9 |
| P24-P25 Emberfall at nightfall | `ep1_intro` 4 and 6 | `ep1_intro` 4-8 / the M0 night kit (19.V24 reference) |
| P22-P23 Fire keep | built keep and army | `c2_two_fronts` camp dressing ideas |
| All | - | The player, overlay, StoryFlow, cast proxy, set contract, recording path |
`ep1_intro` itself: **the prologue replaces it as the episode opener.** Its shots 4-8 and 10 (the reunion with Vey, the
knife, the lightning, back to back) become a short M0 opening cutscene `m0_knives` (ENGINE, <= 1:00, built with M0 and
the Vey / Hush models; 19.P6 writes it into the story doc). Until M0 exists the prologue hands off to M1.

---

## 2. Technical approach

### 2.1 Pieces (all new files except where marked)
| Piece | Path | Task |
|---|---|---|
| Resources `CinematicScript` (+ `skip_locked_until`), `CinematicShot` (+ `stage_set`, `marker_prefix`), `CinematicLine`, `CinematicAction` | `scripts/cinematics/cinematic_{script,shot,line,action}.gd` | 19.P1 |
| `CinematicPlayer` STAGE mode (timeline clock, 6 camera modes, lines, actions `fade` / `music` / `sfx` / `title` / `visible` / `anim` / `vfx` / `set_shot`, skip lock, pause, `play_from(shot_index)` for previews) | `scripts/cinematics/cinematic_player.gd` | 19.P1 |
| `CinematicStage` (root of stage scenes; recording mode `cinematics.md` 8.3) + `CinematicInput` (Input Map actions, runtime fallback) | `scripts/cinematics/cinematic_stage.gd`, `cinematic_input.gd` | 19.P1 |
| `CinematicOverlay` (letterbox, subtitles, skip prompt with lock, paused view, full-screen fades, title card) + `Speakers` | `scripts/ui/cinematic/cinematic_overlay.gd`, `speakers.gd` | 19.P2 |
| `CastProxy` (puppet wrapper that makes SpellVfx / IceVfx / NatureVfx play real spell effects) | `scripts/cinematics/cast_proxy.gd` | 19.P7 |
| `StoryFlow` lite + `CampaignState` keys `cinematics_seen`, `mark_seen`, `is_seen` | `scripts/campaign/story_flow.gd` (new), `campaign_state.gd` (edit) | 19.P3 |
| Menu hook + Prologue replay button | `scripts/ui/menus/main_menu.gd` (edit) | 19.P4 |
| 7 stage sets | `art/cinematics/stage_sets/prologue_<set>/` | 19.P8-P14 |
| Stage scene + shot data + contact-sheet tool + baker | `missions/cinematics/prologue.tscn`, `prologue_stage.gd`, `data/cinematics/prologue_shots.gd` -> `prologue.tres`, `scripts/cinematics/cinematic_contact_sheet.gd`, `scripts/cinematics/cinematic_bake.gd` | 19.P16 |
| Music / stingers | `assets/audio/cinematic/prologue_audio_generator.gd` + `prologue_*.wav` | 19.P5 |
| Video player (only if Q2 = video) | `scripts/ui/cinematic/video_cinematic.gd` | 19.P18 |

### 2.2 The timeline (how one scene plays 3:00 deterministically)
- `missions/cinematics/prologue.tscn`: root `PrologueStage extends CinematicStage`; children: `LightingRig`, the 7 set
  scenes (all at the origin, all hidden but the active one), one `Camera3D` (near 0.1, far 250), the VFX hubs
  (`SpellVfx`, `IceVfx`, `NatureVfx`, `TitanVfx`, `UnitVfx`, `CombatVfx`), two `AudioStreamPlayer`s (music on `Music`,
  stingers on `SFX`), the overlay. `autoplay_script = prologue`.
- Clock: `t += delta` in `_process` (frozen while paused). Under Movie Maker (`--fixed-fps 30`) and in tests
  (`--fixed-fps 60`) `delta` is exact, so every run is frame-identical. The camera is a pure function of `t`; the
  shake RNG is seeded; set particles use fixed seeds / `preprocess` where available; set acting is an
  `AnimationPlayer` animation named after the shot (`P11`), started by the set's `begin_shot` at the shot's first
  frame, never free-running timers.
- Shot data is authored as readable GDScript (`data/cinematics/prologue_shots.gd`, `static func build() ->
  CinematicScript`, one block per shot copied from 1.1) and baked headless to `data/cinematics/prologue.tres` (the
  `CinematicScript.find(id)` contract). Coordinates never appear in it: each shot names `stage_set` and
  `marker_prefix` and the player reads the set's markers.
- Set switches happen only on cuts or under fades. **Prewarm**: during the first 1.0 s (black, before P01 fades in)
  every set is shown for 2 frames behind the black overlay so its pipelines compile; the menu -> prologue scene load
  happens behind a black screen too.
- Render scale: the stage applies the menu diorama method to the root viewport (target ~2 MP, FSR 1, min 0.5) and
  restores the previous values in `_exit_tree`.
- End (or skip): `Events.cinematic_finished(&"prologue", skipped)` (when the signal exists) -> `StoryFlow` hand-off.
  Launched on its own (F6 in the editor, no StoryFlow context) it returns to the main menu.
- **Recording mode** (`Engine.get_write_movie_path() != ""`): no input, no skip, **no focus-loss pause**, subtitles
  off, title card on, `RecordingExtras` kept, 0.5 s black head and tail, then `get_tree().quit()` instead of the
  hand-off.

### 2.3 Set contract (duck-typed: sets reach the player only through groups / `has_method`)
Frozen by the lead in 19.P0 (CLAUDE.md "Cinematics (prologue subset)" bullet):
- Root `Node3D` in group `"cinematic_sets"`, `@export var set_id: StringName`, `@export var lighting: LightingPreset`
  (own `.tres` in the set folder); optional `lighting_for(shot_id: StringName) -> LightingPreset` for sets with two
  moods (FIRE `keep` / `emberfall`).
- `Shots` child with `Marker3D`s `<shot>_from`, `<shot>_to`, `<shot>_look_from`, `<shot>_look_to`, optional
  `<shot>_pivot` (ORBIT: angles and radius are read from `_from` / `_to` around it) and `Path3D <shot>_rail`; optional
  metadata `fov` on `_from` / `_to` (degrees).
- Methods: `begin_shot(shot_id: StringName) -> void` (reset props to the shot's start state, play the shot's
  animation if any), `end_shot(shot_id: StringName) -> void`, `set_active(on: bool) -> void` (visible + process),
  `puppet(tag: StringName) -> Node3D` (`&"vessa"`, `&"torvald"`...).
- 0 lights except inside reused models / scenes and under `RecordingExtras`. Every model hook call behind
  `has_method`. Every `CastProxy` use behind `ResourceLoader.exists("res://scripts/cinematics/cast_proxy.gd")`, with a
  fallback (`play_cast` pose + the set's own emissive flash).
- Keep faces and key action inside the central 2.39:1 band.
- Self-preview (tech-artist pattern): `art/cinematics/stage_sets/<set>/tools/<set>_preview.gd` (windowed `-s` script)
  lerps a camera between its own markers and saves the first / middle / last frame of each of its shots at 1600 x 900
  and 3440 x 1440 with the 2.39 bars drawn -> `docs/art/screens/prologue_<shot>_<a|b|c>_<W>.png`, plus the GPU ms of
  the set.

### 2.4 CastProxy (19.P7)
`class_name CastProxy extends Node3D`, group `"heroes"`: `setup(model: Node3D, kingdom: StringName)`, `get_model() ->
Node3D`, `body_height`, `radius`, a child `SpellCaster` (plain `Node` with the signals `spell_cast(id)`,
`spell_effect(id, position)`, `healed(amount)`, `cooldown_started(id, seconds)` and `radius_of(id) -> float`),
`cast(spell_id: StringName, at: Vector3, travel_time: float = 0.6)`: plays `model.play_cast(spell_id)`, emits
`spell_cast` now, draws a simple emissive streak for projectile ids (`fireball`, `rime_bolt`, `shadow_lance`) and
emits `spell_effect(id, at)` after `travel_time`. Ids used: `flash_freeze` (P11), `wild_bloom` (P15), `umbral_shroud`
(P20), `fireball` (P23). Test: each hub hooks a proxy within one rescan and plays its effect with no error.

### 2.5 Skip, pause, input
- Input Map (lead, 19.P0, physical keycodes): `cinematic_skip` (Escape, Space), `cinematic_advance` (Enter, Keypad
  Enter), `cinematic_pause` (P). Handled in the overlay's `_input`, then `set_input_as_handled()`.
- `t < skip_locked_until` (30.0): skip presses are consumed and do nothing (no prompt). From 30.0: the two-press rule;
  one press when `CampaignState.is_seen(&"prologue")` or when played from the replay button.
- P pauses at any time (also before 0:30); window focus lost = pause (not in recording mode). Enter ends a subtitle.

### 2.6 Hand-off and campaign safety (19.P3 / 19.P4)
- `StoryFlow` (static): `PROLOGUE_ID := &"prologue"`, `PROLOGUE_SCENE := "res://missions/cinematics/prologue.tscn"`,
  `start_campaign_mission(tree, mission_id, difficulty)`: if `mission_id` is the first mission of the order and the
  prologue is not seen and its scene exists -> play the prologue with `next = first_playable()` (`m00` when
  `CampaignState.mission_available(&"m00")`, else `m01`), else `MenuFlow.start_mission` directly. `play_prologue(tree,
  next_mission := &"", difficulty := -1)`; `first_playable() -> StringName`. Missing scene or load error -> straight to
  the mission (never blocks).
- `main_menu.gd`: Campaign Start calls `StoryFlow.start_campaign_mission` when the script exists (load-guard), else the
  old path. A **Prologue** button appears in the campaign panel once seen.
- `CampaignState`: `cinematics_seen` (Array of StringName, default empty), `mark_seen(id)` (load, append, save; touches
  only that key), `is_seen(id)`; VERSION stays 1; old `campaign.json` files load with the default.
- Untouched: `scenes/main.tscn`, `MenuFlow`, `mission_01.*`, `MISSION_ORDER` (the stage is not a mission).

### 2.7 Audio (19.P5; no copyrighted audio)
Generated in GDScript like `assets/audio/mapfill_sfx_generator.gd`: 5 music cues (`prologue_world` 60 s, `_ice`,
`_nature`, `_shadow`, `_fire` 30 s each: a slow drone + a 4-note kingdom motif, 44.1 kHz mono, cross-fade 0.5 s at the
block boundaries) and 5 stingers (`gone` swell, `regalia` sparkle, `candle_out`, `knife` glint, `title` boom). WAV,
together <= 25 MB (or 22 kHz if larger). **What the user provides later (optional):** a narration voice (Q1) and/or a
real score; both drop in without code changes (`CinematicLine.voice`, the cue paths).

### 2.8 Recording (wave 3, 19.P19; windowed on the user's PC, never headless)
```powershell
$GODOT = "C:\Users\elzzo\Downloads\game gadot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
New-Item -ItemType Directory -Force "$env:USERPROFILE\Videos\four-wizards-rec" | Out-Null
& $GODOT --path . --windowed --resolution 1920x804 --fixed-fps 30 `
  --write-movie "$env:USERPROFILE\Videos\four-wizards-rec\prologue.ogv" `
  --quit-after 5700 "res://missions/cinematics/prologue.tscn"
```
(181 s x 30 = 5 430 frames + margin.) Needs the `.ogv` writer confirmed by the 19.P17 probe. If `.ogv` is not
available: record `.avi` and **stop**: converting needs ffmpeg, which is downloaded only with the user's yes (Q3);
without it the live version ships and the video waits. The output stays outside `res://`; it is copied to
`art/cinematics/video/prologue.ogv` only if the user picks video as the shipping format (Q2).

---

## 3. Agent tasks for the window
Owner types map to the project's agents (`systems-coder-high` for [H] code; [H] art = the tech-artist agent run
with high effort, since no `tech-artist-high` agent exists). No two tasks share a file; each task also owns its
`tests/test_19_p<N>.gd`. Agents never run git. Wave 1 art agents render windowed previews while ~14 Godot processes
run: their GPU numbers are indicative only (the real perf check is G3 on a quiet PC).

| Id | Task | Owner | Owns (exact files / folders) | Inputs | Done when | Est. | Wave |
|---|---|---|---|---|---|---|---|
| 19.P0 | Budget check, contract freeze, launch | lead | `CLAUDE.md` (Cinematics prologue-subset bullet + owner rows for `scripts/cinematics/`, `data/cinematics/`, `missions/cinematics/` -> systems, `scripts/ui/cinematic/`, `assets/audio/cinematic/` -> ui, `art/cinematics/` -> tech-artist), `project.godot` (3 Input Map actions), `scripts/core/events.gd` (`cinematic_started(id)`, `cinematic_finished(id, skipped)`), `export_presets.cfg` (exclude `art/cinematics/sets/*, art/cinematics/hires/*`), `docs/plan/prologue-agent-rules.md` | This plan, `cinematics.md` 11 | `get_usage` read (5-hour <= 10 %), contracts in CLAUDE.md, `--import` clean, 14 agents launched | 15-20 min | 0 (t=0) |
| 19.P1 [H] | Cinematic core, STAGE mode | systems-coder-high | `scripts/cinematics/cinematic_script.gd`, `cinematic_shot.gd`, `cinematic_line.gd`, `cinematic_action.gd`, `cinematic_player.gd`, `cinematic_stage.gd`, `cinematic_input.gd` | 2.1, 2.2, 2.5, `cinematics.md` 2-4, 8.3, 11 | `test_19_p1`: a synthetic 3-shot script (2.0 + 1.5 + 1.0 s) finishes after 270 frames +- 1; DOLLY ends on `to_pos` +- 0.01 m; markers override positions; ORBIT from markers; skip ignored at t < `skip_locked_until`, works after (two presses; one when seen); pause adds 0 to `elapsed()`; `play_from(2)` starts at shot 3; recording mode path covered by a flag | 50-60 min | 1 |
| 19.P2 | Overlay + speakers | ui-coder | `scripts/ui/cinematic/cinematic_overlay.gd`, `scripts/ui/cinematic/speakers.gd` | 2.5, `cinematics.md` 6.1-6.2, 6.4, speaker table `story-episode-1.md` 2 | `test_19_p2`: `bar_height` 115 at 1600 x 900, 43 at 3440 x 1440, 32 at 2560 x 1080; subtitles 2 lines, speaker colour; no prompt while locked; prompt then skip after; `show_title(lines, duration)`; fades | 40-50 min | 1 |
| 19.P3 | StoryFlow lite + seen keys | systems-coder | `scripts/campaign/story_flow.gd`, `scripts/campaign/campaign_state.gd` | 2.6, `cinematics.md` 7 | `test_19_p3`: unseen -> prologue requested with next `m01` (and `m00` when a fake scene path exists); seen -> mission directly; missing prologue scene -> mission; old `campaign.json` without the key loads and saves it; mission 1 tests still pass | 30-40 min | 1 |
| 19.P5 | Placeholder music + stingers | ui-coder | `assets/audio/cinematic/` (generator + `prologue_*.wav`) | 2.7, shot times 1.1 | 5 cues + 5 stingers generated, lengths match, <= 25 MB, `Music` / `SFX` bus names documented in the generator header | 30-45 min | 1 |
| 19.P6 | Story + spec update, line check | game-designer | `docs/design/story-episode-1.md` (7.1 row, 7.2 `prologue` shot list from 1.1, 7.4 fallback text, `ep1_intro` -> `m0_knives` <= 1:00 rewrite), `docs/design/cinematics.md` (skip lock, set contract, live-vs-video note) | This plan | Every subtitle <= 2 x 48 chars, lines fit their shot at the auto duration, continuity with M0 / M1 checked (M1 briefing mismatch noted for 19.C3) | 30-40 min | 1 |
| 19.P7 | Cast proxy | systems-coder | `scripts/cinematics/cast_proxy.gd` | 2.4, `art/vfx/spell_vfx.gd`, `ice_vfx.gd`, `nature_vfx.gd` (read only) | `test_19_p7`: SpellVfx / IceVfx / NatureVfx hook a proxy within one rescan; `cast` emits `spell_cast` then `spell_effect` after `travel_time`; the 4 ids play with no error; no group other than `"heroes"` | 30-40 min | 1 |
| 19.P8 [H] | Set WORLD (P01, P02, P06) | tech-artist (high effort) | `art/cinematics/stage_sets/prologue_world/` | 1.1, 2.3, horizon / biome / river mouth / landmark / critter kits, caravan, deer | Markers for its 3 shots, dusk preset, meteor ribbons anim, `test_19_p8` (loads headless, markers exist, `begin_shot` runs, no light outside models), preview stills | 50-60 min | 1 |
| 19.P9 [H] | Set OBS + Master stand-in (P03-P05) | tech-artist (high effort) | `art/cinematics/stage_sets/prologue_observatory/` (incl. `master_standin.gd` / `.tscn`, orrery, dome, regalia placeholders) | 1.1, `story-episode-1.md` 2 (the Master's look), crown mesh kit | Exterior + interior, the robe-falls-empty / regalia-burst animation `P05`, swordsman silhouette, test + stills | 55-60 min | 1 |
| 19.P10 | Set CROWN (P07-P09) | tech-artist | `art/cinematics/stage_sets/prologue_crown/` | Menu diorama (instanced read-only; its camera made non-current at runtime, drift paused), `crown_pedestal` looks | Sealed / stirring looks per shot, glow swell anim `P09`, test + stills | 35-45 min | 1 |
| 19.P11 | Set ICE (P10-P13) | tech-artist | `art/cinematics/stage_sets/prologue_ice/` | Ice buildings, Rimeshield, Rime Colossus, Frost Dragon, War Mammoth, `preset_ice`, CastProxy (guarded) | 4 shots staged, flash-freeze moment, dragon pass anim, test + stills | 45-60 min | 1 |
| 19.P12 | Set NAT (P14-P17) | tech-artist | `art/cinematics/stage_sets/prologue_nature/` | Old Wood / glade sets, Nature buildings, Sapling / Sprigling, Elder Treant, Grove Stag, CastProxy (guarded) | Regrowth moment, the oak with the hidden ring, test + stills | 45-60 min | 1 |
| 19.P13 | Set SHD (P18-P21) | tech-artist | `art/cinematics/stage_sets/prologue_shadow/` | Shadow buildings and army, Barrow Giant, Nightmare Knight, CastProxy (guarded) | Night keep, crypt corner with candle + letter, fade-in soldiers, candle-out anim, test + stills | 45-60 min | 1 |
| 19.P14 [H] | Set FIRE: keep + Emberfall (P22-P26) | tech-artist (high effort) | `art/cinematics/stage_sets/prologue_fire/` (incl. practice target, letter prop) | Fire buildings and army, Cinder Dragon, Ember Boar + `set_seated`, ruins set, CastProxy (guarded) | Two moods (`lighting_for`), fireball moment, the ride rail, the watch-keep at nightfall with the Shade and knife glint, test + stills | 55-60 min | 1 |
| 19.P15 | Cinematic gestures (subset of 19.V10) | tech-artist | `art/units/wizards/wizard_model.gd`, `vessa.gd`, `malrik.gd`, `torvald.gd`, `ysolde.gd` | `cinematics.md` 4, `unit_model.gd` style | `play_gesture(id)` for `turn_head_left`, `turn_head_right`, `nod`, `laugh`, `read`, `pinch`, `raise_staff` (0.3-0.8 s), additive only; existing model tests + `PERF OK` unchanged; `test_19_p15` | 40-60 min | 1 |
| 19.P4 | Menu hook + Prologue button | ui-coder | `scripts/ui/menus/main_menu.gd` | 19.P3 API | `test_19_p4`: Start on the first mission with an unseen save requests the prologue scene; seen -> the mission; the button shows only when seen; skirmish path untouched | 25-35 min | 2 |
| 19.P16 [H] | Assembly: stage, shot data, contact sheet | systems-coder-high | `missions/cinematics/prologue.tscn`, `missions/cinematics/prologue_stage.gd`, `data/cinematics/prologue_shots.gd`, `data/cinematics/prologue.tres`, `scripts/cinematics/cinematic_bake.gd`, `scripts/cinematics/cinematic_contact_sheet.gd` | 1.1, 2.2, P1, P2, P5, P7 and the sets that are in (missing set -> a grey card with the shot id, logged) | `test_19_p16` (`--fixed-fps 60 --quit-after 11500`): finished at frame 10 800 +- 2; 27 `shot_started`; every `stage_set` found; skip at 29 s ignored, at 31 s two presses skip and the hand-off stub is called; no OmniLight / SpotLight outside wizard models, reused scenes and `RecordingExtras`; two runs give the same camera transform at 5 sample times. Windowed contact sheet (27 shots x 3 frames, 1600 x 900) saved | 50-60 min | 2 |
| 19.P17 | Movie Maker probe | tech-artist | `art/cinematics/sets/probe/` (stage + a tone), `art/cinematics/tools/record.ps1` | `cinematics.md` 8.2-8.3 | 5 s windowed recordings `.ogv` and `.avi` outside `res://`; report: writer support in 4.7.2, file sizes, the exact `editor/movie_writer/*` setting names, playback OK in a `VideoStreamPlayer` scene | 20-30 min | 2 |
| 19.P18 | Video player lite (**only if Q2 = video**) | ui-coder | `scripts/ui/cinematic/video_cinematic.gd` | `cinematics.md` 8.5 | `test_19_p18` fake-stream mode: finish, skip lock, pause, missing file -> straight hand-off | 30 min | 2 (cut first) |
| 19.P19 | Record the prologue `.ogv` | tech-artist | Output in `%USERPROFILE%\Videos\four-wizards-rec\`; `art/cinematics/video/prologue.ogv` only if Q2 = video | 2.8, the P17 result, PC quiet | 3:00 (+- 0.5 s) file plays with sound in a `VideoStreamPlayer`, <= 35 MB (cap 45), a frame grab per block checked | 30-45 min (mostly render time) | 3 |
| 19.P20 | Final: tests, commit, export, playtest copy | lead | `docs/plan/waves.md`, `docs/plan/usage-log.md`, `docs/plan/playtest-notes.md` | All reports | Section 3.2 | 30-40 min | final |

**Count:** 19 agent tasks (19.P1-P19) + 2 lead steps. **Wave 1: 14** (P1, P2, P3, P5, P6, P7, P8-P15) · **wave 2: 4**
new (P4, P16, P17, P18 if Q2 = video) + the 7 set agents continued by `SendMessage` for one fix round · **wave 3: 1**
(P19) + a final fix round on the continued agents · **final: lead**.

### 3.1 Schedule (window clock)
| Time | What |
|---|---|
| 0:00-0:20 | 19.P0 (lead). Launch wave 1 (14 agents) |
| 0:45-1:15 | Wave 1 returns. The lead runs each task test as it lands. **Gate G1**: P1 + P2 green -> launch P16; P3 green -> P4; P17 when a slot frees |
| ~2:00 | P16 first full play headless green + contact sheet. **Gate G2**: the lead reviews the 81 stills (framing in the 2.39 band, lighting per block, subtitle timing) and sends each set agent its notes (`SendMessage`, 15-25 min fix round) |
| ~2:45 | All Godot agents stopped. **Gate G3 (quiet PC)**: windowed live run at 3440 x 1440 and 1600 x 900 (fps log per set), the campaign start by hand (menu -> Start -> prologue -> skip at 0:31 -> M1 loads) |
| 3:00-3:45 | Wave 3: P19 records (the window must stay open and in focus-independent recording mode; nothing else runs) |
| 3:45-4:30 | 19.P20 (lead). 4:30-5:00 reserve (retries, the 95 % save rule) |

### 3.2 Final lead step (19.P20)
1. `--import`, smoke test (`victory=true`), perf test (`PERF OK`), every `tests/test_19_p*.gd` (+ the existing mission 1
   and campaign tests). A failure goes back to its agent once; then stop and tell the user.
2. Tick the tasks in `waves.md` step 19, add the prologue line to `usage-log.md` (usage before / after).
3. Commit per finished task folder; tag `prologue-green`.
4. Save rule: git bundle in `Documents\four-wizards-backup`, OneDrive source zip. CI copy at the tag -> export
   `build/FourWizards.exe`; check the build has `missions/cinematics/prologue.tscn` and no `art/cinematics/sets/`;
   zip to the Desktop `FourWizards-<date>.zip`; OneDrive playtest copy (ask first, standing rule in
   `lead-status.md`); `prologue.ogv` next to it as a trailer if recorded.
5. `playtest-notes.md` + 3-5 lines in Québec French: Campaign -> Start plays the prologue, Esc does nothing before 0:30,
   the 21:9 framing, the Prologue button, the hand-off into the mission.

---

## 4. Budget (5-hour window)
Rule of thumb: ~20 agents running for an hour ~ 35-45 % of the 5-hour window, so ~2 % per agent-hour.
| Part | Agents x time | Share of the window |
|---|---|---|
| Wave 1 | 14 x ~0.85 h | **~25-30 %** |
| Wave 2 | 4 new x ~0.7 h + 7 fix rounds x ~0.3 h | **~10-13 %** |
| Wave 3 | 1 recorder (mostly render wait) + 3-4 last fixes | **~3-5 %** |
| Lead (P0, gates, tests, merges, P20) | whole window | **~10-12 %** |
| **Expected total** | | **~50-60 %**; worst case (every agent 60 min + one retry each) ~75-80 % |
Start the window with the 5-hour meter near 0 %. Stop launching at 80 %; the save + test rule at ~95 % as usual.
**Precondition:** `CLAUDE.md`'s lead playbook caps parallel agents at 6 (under 50 % of the meter). This plan needs 14 at
once; the lead confirms the user's OK for this window (the 2026-09-26 usage log shows 20 at once), otherwise the plan
becomes two windows (wave 1 split in halves of 6-7).

**Cut first if the window runs short** (keep the timeline playable in-engine above everything):
1. 19.P19 recording and every `RecordingExtras` (the live version is the ship).
2. 19.P18 video player (not needed for live).
3. 19.P17 probe (moves to Episode 1's 19.L2).
4. 19.P15 gestures (the sets fall back to `play_cast` / camera-only acting).
5. The G2 fix round for sets that already read well; then the WORLD set dressing (fewer biome items, reuse CROWN and
   OBS shots longer).
6. Merge each wizard block from 4 to 3 shots (hold longer), same 3:00.
Never cut: P1, P2, P3 + P4 (the hand-off), P16, the skip lock, the subtitles.

---

## 5. Risks and checks
| Risk | Check / plan |
|---|---|
| Movie Maker cannot run headless | Recording only in wave 3, windowed on the user's PC, nothing else running; the stage's recording mode ignores focus loss and input, quits by itself; `--quit-after` 5700 as the safety net |
| No `.ogv` writer in 4.7.2 | P17 probe in wave 2. If missing: `.avi` only, ffmpeg only with the user's yes (Q3); otherwise the live version ships alone (no loss for the game) |
| Determinism | Camera = f(t), seeded shake, shot animations started by the timeline, fixed particle seeds; `test_19_p16` compares two runs; the recording uses `--fixed-fps 30` |
| Missing model hooks / models | All hook calls `has_method`-guarded; P15 is optional; no Vey / Hush / Master models: Vey = the letter + a silhouette, Hush = a plain Shade, the Master = the P9 stand-in |
| Sets not ready at assembly | P16 draws a grey card with the shot id for a missing set, so the timeline always plays 3:00 |
| Hitches at set switches | Prewarm under the opening black; switches only on cuts / fades; checked at G3 on the quiet PC |
| Live perf on the GTX 1660 at 3440 x 1440 | Diorama render-scale method, one set visible, <= 150 extra draw calls per set, 0 new lights; G3 fps log per set; fallback = ship the `.ogv` |
| 21:9 letterbox and framing | Overlay bar formula tested at 3 sizes; set previews draw the 2.39 band at 1600 x 900 and 3440 x 1440; G2 review of every still |
| Skip rule | Tested at 29 s (ignored, no prompt) and 31 s (prompt, then skip); P (pause) allowed at any time; recording mode ignores input |
| Campaign start breaks | Gate lives in StoryFlow + the menu only; `MenuFlow`, `scenes/main.tscn`, `mission_01.*`, `MISSION_ORDER` untouched; tests for unseen / seen / missing scene / old saves; smoke + mission 1 tests in P20; G3 manual run |
| Story mismatch until M0 exists | The prologue ends on the knives, then M1's current briefing starts at dawn; 19.P6 notes the 19.C3 briefing patch; acceptable for this playtest |
| Perf numbers during wave 1 | Meaningless with ~14 Godot processes (lead-status note): only G3 numbers count |
| Subtitle overflow | All 26 lines pre-checked here (<= 2 x 48); P6 re-checks |
| Export | P0 adds the `sets/` / `hires/` exclusions; P20 checks the exe contains the stage and not the probe |

---

## Questions for the user (recommendation first)
1. **Narration voice?** (a) **Subtitles only this window, with placeholder music; a real voice later** (b) You record the
   26 lines yourself (we hand you the script with times; WAV files drop in without code) (c) A Windows text-to-speech
   placeholder for timing only (never shipped).
2. **Which one ships in the game?** (a) **The live in-engine prologue (full width on your 21:9, 0 MB), with the `.ogv`
   kept as a trailer** (b) The `.ogv` video as the default (~35 MB, identical on every PC, softer on the ultrawide)
   (c) Live only, skip the recording (saves ~5-10 % of the window).
3. **If Godot 4.7.2 cannot write `.ogv` directly:** (a) **Skip the video this window and ship the live version (no
   download)** (b) Download ffmpeg (official Windows build, ~100 MB) to convert the `.avi` recording.
Without answers the plan runs on the recommendations (1a, 2a, 3a).

> **User answers (2026-09-26 ~19:50):** narration = subtitles only this window (1a); ship the LIVE in-engine version, .ogv kept as a trailer (2a); if Godot can't write .ogv, no video and no download (3a). Agent cap: the user has asked for max parallel agents all day (up to 20) — run the 14 of wave 1 in one window.
