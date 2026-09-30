# "The Citadel of the Master" - 30-second film (Blender), script and shot list

Owner: tech-artist (Blender showpiece). Written 2026-09-29. Set: the prologue castle `forge_citadel`
(`art/cinematics/stage_sets/forge_citadel/`), exported from Godot to Blender. Narrator: **the Master** (speaker
`master`, `data/voice/cast.json`: Kokoro blend `bm_lewis 0.4 + bm_george 0.35 + bm_fable 0.25`, cast speed 0.82,
about 13 characters / s = 2.3 words / s). Original lines; they sit inside the existing prologue story (the Master's
citadel above the clouds, 1000 years of peace, kings bring their quarrels, four apprentices, four kingdoms, gone
"in one breath", the empty throne) without repeating its lines.

Tone: a fast trailer. 14 cuts in 30 s (average 2.1 s), one idea per shot, every shot lit so it reads in one glance.
Light arc: **golden sunset (0-19 s) -> the four colours (19-23 s) -> the sun dies with the Master (25 s) -> blue
dusk, only fires and windows (26-30 s).**

## Format
| Item | Value |
|---|---|
| Length | 30.00 s = 720 frames at **24 fps** (frames 1-720) |
| Frame | **2.39:1 scope**, 1920 x 804 final, 1280 x 536 preview |
| Camera | Blender camera, sensor width 36 mm (fit horizontal); lens in mm below |
| Motion blur | on, shutter 0.5 frame (180 degrees) |
| DOF | f-stop per shot below (wide shots f/8 = practically none) |
| Engine | EEVEE (raytraced reflections, volumetric fog + volumetric shadows = god rays), AgX view, "Medium High Contrast" look |
| Audio | `narration.wav` (the Master, 30.0 s, placed at frame 1) in the Video Sequencer |

**Coordinates are Blender world metres, Z up** (= Godot `(x, y, z)` -> Blender `(x, -z, y)`; glTF import does this).
The citadel centre is (0, 0); **-Y is south** (the gate, the Great Bridge, the statue). Levels: cloud sea z 0, city
ring z 30, tier 2 (the four keeps) z 38, summit (throne hall, orrery dome, the Master's tower) z 48.
Landmarks: statue (0, -106, 30-52) · bridge deck z 30, y -66 .. -160 · gatehouse (0, -64.7, 30) · braziers
(+-5, -60, 30) · feast table (-12.5, -47.2, 30) · belfries (+-9.5, -36.2, 38) · keeps: Fire (17.2, -24.6, 38),
Ice (-17.2, -24.6, 38), Nature (17.2, 24.6, 38), Shadow (-17.2, 24.6, 38) · throne (0, -6.8, 48), hall windows
red (-6, -9.25), violet (-6, -12.75), blue (6, -9.25), green (6, -12.75) at z 48-55 · orrery (-13, 5, 48), dome
top z 57 · the Master figure (-13, 1.4, 48) · the Master's tower (12, 7, 48) · army fires on the horizon
(+-128, 45, 14), (42, 112, 14), (-48, 110, 14).

## Narration (the Master, 8 lines, 57 words)
| Line | Start (s) | Text | Chars | Words | Target length | Words / s |
|---|---|---|---|---|---|---|
| L1 | 0.40 | Above the clouds stood the citadel of the Master. | 49 | 9 | 3.8 s | 2.4 |
| L2 | 4.70 | For a thousand years, its bells rang peace. | 43 | 8 | 3.3 s | 2.4 |
| L3 | 8.60 | Kings climbed his bridge with drawn swords, | 43 | 7 | 3.3 s | 2.1 |
| L4 | 12.20 | and walked home as brothers. | 28 | 5 | 2.2 s | 2.3 |
| L5 | 15.20 | Four wizards he raised. Four crowns he gave them. | 49 | 9 | 3.8 s | 2.4 |
| L6 | 19.35 / 20.20 / 21.05 / 21.95 | Fire. / Ice. / Nature. / Shadow. (4 words rendered one by one, one per cut) | 26 | 4 | 4 x 0.6 s | 1.2 (on the cuts) |
| L7 | 23.10 | Then, in one breath, the throne stood empty. | 44 | 8 | 3.4 s | 2.4 |
| L8 | 27.00 | And the bells fell silent. | 26 | 5 | 2.0 s | 2.5 |

Rules: rendered at cast speed; a line longer than its slot may be sped up to x1.12 at most (the Voice Forge fit rule,
tighter than its x1.25 cap so the voice stays kingly). The build script reads the real lengths and the final start
times are written back at the end of this file ("As built").

## Shot list
Sun = a Blender sun lamp matched to a physical sky (Sky Texture). **Sun direction (towards the sun) is WSW:
azimuth 243 degrees from +Y clockwise, i.e. vector (-0.87, -0.45, e)**, so every south-facing (camera-facing)
wall is raked warm from the left and shadows fall to the right. Elevation: 8.5 degrees at 0 s -> 3 degrees at 22.75 s
-> -2 degrees at 26 s (blue hour). Colour 2600 K (#FFB070), strength 4.0 -> 2.5 -> 0.

| # | Frames | Time (s) | Line (over the shot) | Camera: lens, move, from -> to (metres), look target from -> to | Lighting | In frame |
|---|---|---|---|---|---|---|
| SH01 | 1-108 | 0.00-4.50 | L1 "Above the clouds stood the citadel of the Master." | 24 -> 28 mm, f/8. **Descending crane through a cloud veil**, ease in-out. Cam (-70, -215, 135) -> (-48, -165, 78); look (0, 0, 96) -> (0, -10, 62). Fade from black 0-0.6 s | Sunset 8.5 degrees, sun left of frame; volumetric haze gold near the horizon; cloud sea lit pink-gold on top, violet in the troughs | Cloud veils slide past the lens (0-1.5 s), then the whole citadel on its mountain rises out of the cloud sea: 3 tiers, curtain wall with 8 great towers, the Master's tower as the tallest spire catching the last sun, waterfalls into the clouds; 3 dragons cross the sky (one big, two small) |
| SH02 | 109-150 | 4.50-6.25 | L2 "For a thousand years," | 24 mm, f/2.8, focus 26 m (the statue). **Fast low rail** along the bridge deck. Cam (-6, -150, 33) -> (-5, -132, 34.5); look (0, -106, 46) -> (0, -106, 49) | Statue lit from the left (warm), right side in cool sky fill; god rays between it and the gatehouse behind | The colossal hooded statue of the Master, moss on its shoulders, fills the frame centre-right; bridge banners (4 colours) and flag poles whip past both sides of the lens (motion blur); braziers and offerings at its feet |
| SH03 | 151-204 | 6.25-8.50 | L2 "...its bells rang peace." | 50 mm, f/2.0, focus the bell (~15 m). **Slow low arc**. Cam (18, -52, 36.5) -> (14, -51, 38); look (9.5, -36.2, 44) | Backlit: the sun sits just left of the belfry; volumetric god rays through the belfry arches; bronze bell with a hot rim | One open belfry on tier 2 fills the right two-thirds; the great bronze bell **swings** (+-20 degrees, 1.6 s period) and its clapper strikes at 7.0 s; a small dragon flies through the rays behind |
| SH04 | 205-252 | 8.50-10.50 | L3 "Kings climbed his bridge..." | 35 mm, f/8. **High tracking shot** beside the bridge, moving towards the city. Cam (38, -150, 62) -> (34, -112, 58); look (0, -135, 32) -> (0, -95, 34) | Side sun, long shadows of the flag poles across the deck; cloud sea glowing below | The Great Bridge from above-right: rows of four-colour banners, crowds of pilgrims on the deck, the statue passing, the gatehouse and curtain wall ahead; a waterfall falling into the clouds in the background |
| SH05 | 253-300 | 10.50-12.50 | L3 "...with drawn swords," | 40 mm, f/4, focus the gate (22 m). **Push in** on the axis. Cam (0, -92, 33) -> (0, -81, 34); look (0, -64.7, 40) -> (0, -62, 42) | Braziers flare (2 point lights #FF7A2A, flicker); gate interior warm; sun on the wall's left face | The gatehouse head-on: the two braziers either side of the steps, the four-colour banners on the wall above the gate (fire, shadow, ice, nature), the city beyond the arch |
| SH06 | 301-360 | 12.50-15.00 | L4 "and walked home as brothers." | 35 -> 40 mm, f/2.8 -> focus the table. **Crane down** into the market. Cam (-22, -79, 62) -> (-9, -57, 34); look (-12.5, -47.2, 31) | Lantern strings glow warm (#FFC070) over the table; low sun rakes the awnings; smoke haze in the market | The market terrace: the long feast table with its benches, stalls, awnings, bunting and crowds; the table ends centre-frame at the end of the move |
| SH07 | 361-414 | 15.00-17.25 | L5 "Four wizards he raised." | 32 mm, f/1.8, focus the Master's back (4 m). **Dolly in** behind the Master. Cam (-13, -4.4, 50.5) -> (-13, -2.6, 50.3); look (-13, 4, 50.2) | Inside the orrery dome: warm window light, the dome glass above shows the orange sky; the four orbiting flames light the Master's hood in four colours | The Master (tall, hooded, back to camera) at the brass orrery; **four little flames (red, blue, green, violet) orbit above his open hand**, one full turn over the shot |
| SH08 | 415-462 | 17.25-19.25 | L5 "Four crowns he gave them." | 28 mm, f/8. **High orbit** round the summit. Cam (48, -62, 80) -> (62, -34, 82); look (0, 0, 44) | Sun 4 degrees: tops of towers gold, tier 2 in rose shadow; the four keeps each carry a faint coloured beacon | Tier 2 from above: the four apprentice keeps at the four corners around the summit, the throne hall, orrery dome and the Master's tower in the middle |
| SH09a | 463-483 | 19.25-20.125 | L6 "Fire." | 35 mm, f/2.8. Low push. Cam (34, -50, 44) -> (32, -47, 44.5); look (17.2, -24.6, 52) | A **red beam** (#FF4018) ignites from the Fire keep into the sky at 19.35 s: volumetric column + red spot light up | The Fire keep, red light on its walls, the beam rising out of frame |
| SH09b | 484-504 | 20.125-21.00 | L6 "Ice." | 35 mm, f/2.8. Cam (-34, -50, 44) -> (-32, -47, 44.5); look (-17.2, -24.6, 52) | **Blue beam** (#3A9CFF) ignites at 20.20 s | The Ice keep, frost-blue light |
| SH09c | 505-525 | 21.00-21.875 | L6 "Nature." | 35 mm, f/2.8. Cam (34, 50, 44) -> (32, 47, 44.5); look (17.2, 24.6, 52) | **Green beam** (#44E060) ignites at 21.05 s | The Nature keep, gardens and vines lit green |
| SH09d | 526-546 | 21.875-22.75 | L6 "Shadow." | 35 mm, f/2.8. Cam (-34, 50, 44) -> (-32, 47, 44.5); look (-17.2, 24.6, 52) | **Violet beam** (#9A40FF) ignites at 21.95 s | The Shadow keep, violet light |
| SH10 | 547-642 | 22.75-26.75 | L7 "Then, in one breath, the throne stood empty." | 40 mm, f/2.0, focus the throne. **Slow push** down the hall axis. Cam (0, -24, 51.5) -> (0, -16, 50.4); look (0, -6.8, 49.6) | The four coloured window shafts (red, violet, blue, green spot lights, 25 degrees, volumetric) cross on the empty throne. At **25.3 s ("empty") the four shafts die one by one (0.15 s apart) and the sun drops**: the hall goes cold blue-violet | The empty throne between two rows of columns, the four coloured pools of light on the floor, then darkness; one ember of the brazier left |
| SH11 | 643-720 | 26.75-30.00 | L8 "And the bells fell silent." | 30 -> 22 mm, f/8. **Crane up and out**, ease out. Cam (0, -34, 62) -> (0, -160, 128); look (0, 0, 52) -> (0, 0, 64). Fade to black 29.2-30.0 s. Title "FOUR WIZARDS" 28.2-29.6 s | Blue hour: sky deep indigo, a last violet band on the horizon; every window glows warm (#FFB060), lanterns, braziers; the four army fires burn on the horizons | The whole citadel small in the blue dusk, lit from inside; the dragons fly away from it in silhouette; the cloud sea darkens |

## Sound
Narration only (`narration.wav`, 24 kHz mono, peak -1 dBFS), the 8 lines placed at the start times above. A
synthesised bell toll (`bell.wav`, additive partials, 4 s tail) is mixed low at 7.0 s (the clapper strike in
SH03) and stops at 26.75 s ("the bells fell silent" = silence under L8).

## As built (2026-09-29)
The film follows the script; what changed after looking at the stills is listed here and is the truth for the .blend
(`build_castle.py` SHOTS table). Frames at 24 fps (frame = t x 24 + 1).

### Narration as rendered (the Master, cast voice, speed 0.82, no speed-up needed)
| Line | Speech (s) | Text | Length | Words / s |
|---|---|---|---|---|
| L1 | 0.42-3.82 | Above the clouds stood the citadel of the Master. | 3.4 s | 2.6 |
| L2 | 4.71-8.05 | For a thousand years, its bells rang peace. | 3.3 s | 2.4 |
| L3 | 8.59-11.68 | Kings climbed his bridge with drawn swords, | 3.1 s | 2.3 |
| L4 | 12.20-14.22 | and walked home as brothers. | 2.0 s | 2.5 |
| L5 | 15.20-18.90 | Four wizards he raised. Four crowns he gave them. | 3.7 s | 2.4 |
| L6 | 19.30 / 20.22 / 21.12 / 22.19 | Fire. / Ice. / Nature. / Shadow. | 0.7-0.9 s each | one word per cut |
| L7 | 23.36-26.51 | Then, in one breath, the throne stood empty. ("empty" at 26.09 s) | 3.2 s | 2.5 |
| L8 | 27.09-29.07 | And the bells fell silent. | 2.0 s | 2.5 |

Bell (`bell.wav`, synthesised, volume 0.32 in the mix): tolls at 7.0 s (the clapper strike in SH03), 10.6, 15.05 and
23.12 s; the last one is cut dead at 26.09 s ("empty"); nothing under L8. Under everything a wind bed (`wind.wav`,
volume 0.13) that swells a little when the light dies. No music (none was asked; the prologue's music cue can be laid
under the Film scene later).

### Shots as built
| # | Frames | Time (s) | Camera (lens, from -> to, look from -> to) | Changed from the script, and why |
|---|---|---|---|---|
| SH01 | 1-108 | 0.00-4.50 | 24 -> 27 mm; (95, -190, 150) -> (62, -140, 86); look (0, 0, 95) -> (0, 0, 62) | From the south-east (side light, the sun's glow on the left) instead of the south; the camera falls through two slabs of volumetric mist (0-1.6 s) = the cloud veils; fade in 0.6 s |
| SH02 | 109-151 | 4.50-6.30 | 22 mm f/2.8; (46, -78, 34) -> (40, -95, 35.5); look (0, -106, 44 -> 45) | The statue is shot **from the east-north-east against the sun** (silhouette, the sun comes out beside its head) instead of a rail along the deck: the game's statue is blocky up close, its silhouette is not |
| SH03 | 152-204 | 6.30-8.50 | 28 -> 30 mm f/2.8; (19.6, -30.8, 44.5) -> (18.5, -32.6, 45.0); look (9.5, -36.2, 48.3 -> 47.9) | (pass 2) The whole rebuilt belfry from the east-north-east, low, against the sun (was: under a plain box looking up); the bell swings across the east arch and strikes at 7.0 s; the frost dragon now crosses the sky behind it |
| SH04 | 205-248 | 8.50-10.33 | 28 mm; (-58, -172, 74) -> (-46, -126, 66); look (0, -120, 33) -> (0, -88, 37) | From the **west**, sun behind the camera: gold light, the citadel's shadow thrown across the cloud sea; an elder cinder dragon glides beside the bridge below the deck |
| SH05 | 249-288 | 10.33-12.00 | 28 mm f/4; (0, -84, 31.8) -> (0, -77, 32.2); look (0, -64, 35.6 -> 36.2) | The set's braziers stand inside the gate (y -60), so two iron brazier stands with fire were added on the bridge in front of it (x +-3.3, y -69.2); frontal low push. (pass 2) Each fire: 6 flame cards + 2 hot core tongues with HDR emission (orange-gold ramp, no deep reds: AgX turns them salmon) flickering per card, a glowing volume of hot air, live coals in the bowls, 70-120 rising sparks (Geometry Nodes); the sun is dimmed to 3.0 for this shot and the exposure is -0.25 so the fires own the frame |
| SH06 | 289-360 | 12.00-15.00 | 35 -> 38 mm f/2.8; (-24, -76, 54) -> (-8.5, -62, 37.8); look the feast table (-12.5, -47.2, 31.4) | Ends higher than scripted. (pass 2) The game's 124 capsule figures are found in the scatter mesh and replaced one for one by robed people (oval draped robe, belt, sleeves, hands, head under a hood / cap / hair, some raising a gold cup), in the game's own robe colours, facing the table; the lanterns are lit (glow cue 2.0 in this shot + 56 warm 60 W point lights on the lanterns nearest the table) |
| SH07 | 361-408 | 15.00-17.00 | 32 mm f/1.8; (-13, -4.4, 50.5) -> (-13, -2.6, 50.3); look (-13, 4, 50.8) | As scripted; the Master's robe is deep violet cloth with sheen; four flames orbit (radius 0.95 m, one turn / 2.1 s) |
| SH08 | 409-462 | 17.00-19.25 | 30 -> 32 mm; (12.5, -3, 150) -> (12.5, 3, 140); look (0, 0, 40) | (pass 2) Near-vertical top-down on the summit, the frame turning ~27 degrees and sinking: the four keeps sit at the four corners of the frame round the throne hall, dome and tower (was: a busy 3/4 view). Each keep lights its crown-fire at 17.25 s: bigger coloured core, a 6.5 m glowing volume of its colour and a 36 kW coloured light (shadow x1.6) that pools on the keep and terrace; two dragons cross between camera and city |
| SH09a-d | 463-484 / 485-506 / 507-532 / 533-554 | 19.25-23.10 | 28 mm, low (z 42), 33 m from each keep, looking up at z 62 | 28 mm instead of 35 (room for the pillar of light); beams = hot core + soft sheath + a 38 kW light on the keep; the earlier beams stay up in the background |
| SH10 | 555-646 | 23.10-26.90 | 35 mm f/2.0; (0, -25, 51) -> (0, -17.5, 50.2); look the throne (0, -6.8, 50 -> 49.8) | (pass 2) The shafts are volumes now: soft round edge, bright at the window fading to the floor, drifting 4-D noise dust, self-emitting in their colour (EEVEE lights a thin haze too weakly); 5200 dust motes (Geometry Nodes, drifting) sparkle only inside the shafts; four 9 kW spots with soft blend, each aimed at its own patch of the dais (soft coloured pools instead of one white disc). The sun drops to 2.2 in this shot; shafts, motes and pools die at 26.09 / 26.24 / 26.39 / 26.54 s, then a cold blue sky light |
| SH11 | 647-720 | 26.90-30.00 | 30 -> 22 mm; (0, -34, 62) -> (0, -165, 122); look (0, -2, 50) -> (0, 10, 92) | The look target ends higher so the dusk horizon is in frame; six dragons fly away north (one elder passes over the citadel); stars come out; title "F O U R  W I Z A R D S" 28.2-29.6 s (Film scene / encode); fade to black 29.2-30.0 s |

### Light as built
* Sky: an art-directed sunset gradient (Blender's physical sky gave a flat white-pink haze): zenith deep blue, gold
  towards the sun, blue-lavender away from it, a two-lobe sun glow + disc, a painted alto-cumulus layer, stars at blue
  hour. The sky seen by the camera is full strength; the light it gives the scene is scaled per shot (`sky_light`).
* Sun lamp at azimuth 243 degrees (WSW), angle 1.2 degrees; elevation 8 -> 5.2 (19.25 s) -> 3.6 (26.05 s) -> -2.5
  (26.5 s) -> -4; strength 8.5 -> 7.6 -> 7.0, 2.2 inside SH10, 0 from 26.45 s; colour (1.0, 0.71, 0.44) -> (1.0, 0.58,
  0.33). The scene cue `dusk` (0 -> 1 between 26.05 and 27.3 s) turns every sky colour to blue hour; `glow_gain`
  (0.7 -> 9) lights the windows, lanterns and the glass.
* Atmosphere: one volume box (12 x 12 km): forward-scattering haze thinning with height (density per shot 0 -
  0.0022, the god rays of SH02-SH04) + a wispy mist sitting on the cloud sea. No world volume (it renders black in
  EEVEE 5.2).
* Practicals: 4 fires (2 in the gate, 2 on the bridge) with flickering 1.0-1.5 kW lights (pass 2: the fire itself
  carries the brightness); 4 orrery flames (45 W); 4 crown-fires / beams (36 kW in SH08, then 6 kW, flash 120 kW,
  38 kW); 4 coloured throne shafts (9 kW spots, 19 degrees, soft blend); 56 lantern lights (60 W, SH06 only).
* Materials (all procedural, world-space triplanar, from the game's vertex colours): ashlar stone, slate roof tiles,
  strata rock, flagstone paving, weathered statue limestone with moss, snow, cloth / banners (the game's banner
  pattern rebuilt, waving with Geometry Nodes), gold, iron, glass, foliage, wood, waterfalls, emissive windows,
  dragons (black cinder scales + lava, pale frost scales, translucent membranes).
* Clouds: a 12 km Geometry-Nodes sea of cumulus (domain-warped smooth Voronoi, 4 octaves) + 9 towering cumulus 3.5-5 km
  out; the game's low-poly puffs, far peaks, the S13 ruin crag and the S30 army camps are hidden (the peaks stay in the
  file, hide_render off to see them).
* Render: EEVEE, ray-traced reflections, fast GI, volumetric shadows (log volume slices), motion blur 0.5 frame
  (shutter opens on the frame, so cuts never blend two cameras), per-shot depth of field, AgX "High Contrast",
  compositor: bloom, 1.2 % lens dispersion, lift / gain grade, S-curve, vignette, fades.

### Render log (2026-09-29, RTX 3070 Laptop)
* Film pass: 1920 x 804, EEVEE 32 samples, JPEG frames -> H.264 (CRF high) + AAC 192 kb/s stereo 48 kHz:
  720 frames in 142 min. The first 150 frames took about 5 s each; after that an unrelated Windows service held the
  CPU at 100 % and frames took 10-30 s. On a free machine the pass is about 60 min. Encode 51 s. `prologue_castle_film.mp4`
  = 22.3 MB, 30.0 s, 720 frames.
* Stills: 14 x 1920 x 804 at 64 samples in 2.7 min (`stills/SHxx.png`, each at the shot's key moment).
* Mix (measured on the mp4): narration about -20 dB RMS (peaks -4 dBFS), bell under L2 -22 dB, wind bed -38 dB in the
  gaps, rising to -33 dB after "empty".

### Weakest shots (first pass, 2026-09-29) and what pass 2 did
1. SH08 was busy from a 3/4 angle -> now a turning top-down with the four keeps at the four corners, each in a pool
   and glow of its colour. Still dense at the frame edges (the market ring), but the four colours read at a glance.
2. SH06 capsule crowd -> replaced by 124 procedural robed figures + lit lanterns (`build_crowd`, `build_lanterns`).
3. SH10 "stage light" cones -> dusty volumetric shafts + drifting motes + soft pools (`mat_sunbeam`, `build_motes`).
4. SH05 pale card fires -> hot flickering cards, hot-air glow, coals, sparks, dimmer sun (`build_braziers`,
   `build_embers`). Still cards: seen head-on in a 1.7 s shot they hold up; a close-up would want a simulated fire.
5. SH03 box belfry -> both belfries rebuilt (`build_belfry`): corner piers with round ribs, 15-voussoir arches with a
   keystone and hood moulding on colonettes, balustrades, dentil cornice, a slate spire with four gablets and oculi,
   lead hip ribs, gilt finial and cross; inside an oak bell frame, a bronze bell with a true section (sound bow, lip,
   bands, crown loop, verdigris), headstock with iron straps and gudgeons, a bell wheel with the rope in its groove and
   the rope paying out through the floor as the bell swings. New camera (see the table).

Pass 2 build notes: `Kit` (build_castle.py) is a small mesh kit (prism, box, beam, tube, lathe) that paints the set's
own vertex colours (sampled from the faces it replaces), so the new geometry takes the film's stone / slate / gold
materials. Geometry-Nodes-generated geometry (motes, sparks) needs a Set Material node: it carries no material slot.

### Files and how to re-render
| File | What |
|---|---|
| `script.md` | this script + the as-built notes |
| `narration.wav` (+ `lines/*.wav`, `narration_timing.json`) | the Master's narration, 30.0 s, 24 kHz mono; `make_narration.py` re-renders it (Kokoro venv) |
| `bell.wav` | the synthesised bell tolls, 30.0 s (also from `make_narration.py`) |
| `wind.wav` | a high-altitude wind bed, 30.0 s (also from `make_narration.py`), mixed low |
| `export/` | the castle + the two dragons exported from Godot (`tools/blender_export_citadel.gd`) |
| `build_castle.py` | builds `prologue_castle.blend` from `export/` (about 20 s) |
| `prologue_castle.blend` | scene **Citadel** (the 3D film, cameras bound to markers, light cues keyed) and scene **Film** (the edit: picture + narration + bell + title) |
| `render_castle.py` | renders stills of every shot or the film (frames -> mp4 with sound) |
| `stills/` | one still per shot (1920 x 804) |
| `prologue_castle_film.mp4` | the film, 1920 x 804, 24 fps, H.264 + AAC |
| `.gdignore` | keeps Godot from importing this folder (the .blend, .glb and .wav files are not game assets) |

```bat
set B="C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
cd C:\Users\elzzo\Documents\four-wizards-rts
rem 1. (only if the Godot set changed) re-export the castle, one Godot at a time:
powershell -File tools\godot_run.ps1 --headless --path . -s tools/blender_export_citadel.gd --quit-after 6000
rem 2. (only if a line changed) the narration:
..\four-wizards-voice\venv\Scripts\python.exe art\blender\prologue_castle\make_narration.py
rem 3. rebuild the .blend:
%B% --background --factory-startup --python art\blender\prologue_castle\build_castle.py
rem 4. stills of every shot:
%B% -b art\blender\prologue_castle\prologue_castle.blend -P art\blender\prologue_castle\render_castle.py -- stills res=1920 samples=64
rem 5. the film (frames go to %TEMP%, a stopped render resumes where it stopped):
%B% -b art\blender\prologue_castle\prologue_castle.blend -P art\blender\prologue_castle\render_castle.py -- film res=1920 samples=32
rem    final master quality (PNG frames, 128 samples, ~4x longer); the CRF encode is large -> _hq_big.mp4:
%B% -b art\blender\prologue_castle\prologue_castle.blend -P art\blender\prologue_castle\render_castle.py -- film res=1920 samples=128 fmt=PNG frames=%TEMP%\castle_frames_hq out=art\blender\prologue_castle\prologue_castle_film_hq_big.mp4
rem    the library copy (under 19 MB: constant 4.2 Mb/s video + 192 kb/s audio) from the same PNG frames:
%B% -b art\blender\prologue_castle\prologue_castle.blend -P art\blender\prologue_castle\render_castle.py -- encode frames=%TEMP%\castle_frames_hq ext=png bitrate=4200 out=art\blender\prologue_castle\prologue_castle_film_hq.mp4
```
In the Blender UI: open `prologue_castle.blend`, scene **Citadel** to look through the shot cameras (the markers switch
them), scene **Film** + Render Animation for the edit with sound.
