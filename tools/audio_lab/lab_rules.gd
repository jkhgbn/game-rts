extends RefCounted
## Audio Lab (docs/plan/audio-lab.md): every number the lab judges against, in one place. Tune here, never in the
## checks. Levels are "in game": the file's loudness + the player's volume_db from the code + 3D distance loss at the
## default camera distance, on 0 dB buses (the settings sliders scale everything after this).
## Loudness metrics (tools/audio_lab/lab_signal.gd): "cue" = max K-weighted loudness over 200 ms windows (short
## sounds), "integrated" = BS.1770 gated integrated loudness (music, ambience loops). Units are LUFS (approx.).

const CATEGORIES: Array[String] = ["ui", "unit", "spell", "alert", "ambience", "music"]

## THE per-category target table. lo / hi = in-game range; outside by <= LOUDNESS_TOL = WARN, more = FAIL.
## Frequent cues (>= FREQUENT_PER_MIN plays per minute in a busy fight) of ui / unit use lo / hi + FREQUENT_SHIFT:
## many play at once, so each one sits lower. Reference point: match music around -22 LUFS integrated in game.
const LOUDNESS := {
	"ui": {"metric": "cue", "lo": -30.0, "hi": -14.0, "target": -22.0,
		"why": "clear but polite: never louder than an alert, audible over the music"},
	"unit": {"metric": "cue", "lo": -30.0, "hi": -16.0, "target": -23.0,
		"why": "combat bed: hits, shots, deaths; many at once, so each one moderate"},
	"spell": {"metric": "cue", "lo": -22.0, "hi": -9.0, "target": -14.0,
		"why": "hero actions read above the combat bed"},
	"alert": {"metric": "cue", "lo": -22.0, "hi": -7.0, "target": -13.0,
		"why": "must cut through a battle (level up, capture, raid, stingers)"},
	"ambience": {"metric": "integrated", "lo": -36.0, "hi": -26.0, "target": -30.0,
		"why": "a bed under everything, well below the music"},
	"music": {"metric": "integrated", "lo": -26.0, "hi": -18.0, "target": -22.0,
		"why": "the mix anchor (includes GameAudio.MUSIC_DB)"},
}
const LOUDNESS_TOL := 6.0
const LOUDNESS_AIM := 2.0      ## Fix hints aim this far inside the range, not at its middle.
const FAIL_PENALTY := 2.0       ## Score points off per FAIL (max MAX_PENALTY): a few real problems must show.
const MAX_PENALTY := 20.0
const FREQUENT_SHIFT := -6.0
const FREQUENT_PER_MIN := 20.0
## Default listener distance for 3D cues = RTSCamera default zoom (30 m; the wheel goes 10-55 m).
const REF_DISTANCE := 30.0
const CAMERA_RANGE := Vector2(10.0, 55.0)

## Peaks (file, sample and 4x true peak).
const TP_WARN := -1.0          ## dBTP above this = WARN (no headroom for the lossy QOA / Vorbis decoders).
const TP_FAIL := -0.1          ## dBTP above this, or any clipped run = FAIL.
const DC_WARN := 0.01

## Duration / silence (ms unless named _s).
const LEAD_WARN_MS := {"ui": 10.0, "unit": 15.0, "spell": 20.0, "alert": 15.0, "ambience": 500.0, "music": 500.0}
const LEAD_FAIL_MS := 60.0     ## SFX only (music / ambience: 2 s).
const TRAIL_WARN_MS := 150.0   ## GameAudio keeps a voice busy for the whole stream: silence wastes voices.
const TRAIL_FAIL_MS := 600.0
const MAX_DURATION_S := {"ui": 0.8, "unit": 1.5, "spell": 2.5, "alert": 3.5}
const MIN_DURATION_S := 0.03
const MIN_LOOP_S := {"ambience": 20.0, "music": 60.0}   ## Shorter loops repeat too often in a 20-40 min match.
const FREQUENT_DECAY_MS := 500.0   ## Frequent cues with a longer tail smear in a fight.
const END_DB_WARN := -45.0     ## RMS of the last 10 ms above this (and last sample > END_SAMPLE) = abrupt end.
const END_SAMPLE := 0.02
const START_SAMPLE := 0.1      ## First sample above this = start pop (fade in 1-2 ms).
const SEAM_WARN := 0.05        ## Loop (music / ambience): |last - first| sample above this = click at the loop point.

## Spectral balance (energy shares of <250 / 250-2k / 2k-6k / >6k Hz).
const ALL_BASS := 0.85
const ALL_HISS_AIR := 0.6
const UI_THIN := 0.02          ## ui cues with less than 2 % energy above 2 kHz vanish on laptop speakers.
## Masking: an alert must beat the battle bed by MASK_PASS dB in at least one band that holds >= MASK_MIN_SHARE of
## its energy. Battle bed = the unit cues at their in-game level, BED_VOICES of them at once (energy sum).
const MASK_PASS := 3.0
const MASK_FAIL := -6.0
const MASK_MIN_SHARE := 0.15
const BED_VOICES := 6

## Memory / disk.
const SFX_FILE_WARN := 1_000_000
const SFX_FILE_FAIL := 4_000_000
const MUSIC_FILE_WARN := 16_000_000
const SET_MEMORY_WARN := 48_000_000
const RATE_FAIL := 22050       ## Below = FAIL (muffled).
const RATE_FULL := 44100       ## Below = fine for placeholders, listed in "real replacement needs".

## 3D players.
const MIN_UNIT_SIZE := 5.0
const MAX_DISTANCE_RANGE := Vector2(20.0, 150.0)
const CUTOFF_GAIN_MAX := -10.0   ## dB at max_distance: louder = the hard cut-off is audible.
const REF_GAIN_MIN := -15.0      ## dB at REF_DISTANCE: quieter = the cue is lost at the default zoom.

## Voices.
const POOL_3D_MAX := 32
const PLAYERS_WARN := 64
const MIN_RATE_LIMIT_S := 0.03   ## Frequent cues need a per-cue cooldown at least this long.
const SATURATION_WARN := 0.2     ## Fight: share of frames with every 3D voice busy.
const DROP_WARN := 0.25          ## Fight: dropped / (played + dropped).

## Variation (takes = files <id>_1.. / <id>_a.. or AudioStreamRandomizer streams).
const TAKES_GOOD := 3
const PITCH_MIN := 0.03          ## +-3 % pitch randomisation counts as variation.

## Buses: allowed = the ones GameSettings creates (parsed from scripts/ui/menus/game_settings.gd), minus Master.
const SETTINGS_SCRIPT := "res://scripts/ui/menus/game_settings.gd"
const FALLBACK_BUSES: Array[String] = ["SFX", "Music"]

## Where the lab looks for code that plays audio (tools/ and tests/ are skipped).
const CODE_ROOTS: Array[String] = ["res://scripts", "res://art", "res://missions", "res://scenes", "res://assets"]
const GENERATOR_HINTS: Array[String] = ["res://tools/generate_sfx.gd"]   ## + any *_generator.gd next to the files.

## Score weights per check group (the score = weighted mean, PASS 1 / WARN 0.5 / FAIL 0, INFO not scored).
const GROUPS: Array[String] = ["loudness", "peaks", "duration", "spectral", "memory", "bus", "variation", "3d",
	"voices", "missing", "speech"]
const WEIGHTS := {"loudness": 18.0, "peaks": 10.0, "duration": 8.0, "spectral": 10.0, "memory": 5.0, "bus": 12.0,
	"variation": 10.0, "3d": 5.0, "voices": 7.0, "missing": 15.0, "speech": 10.0}
const GROUP_TITLES := {"loudness": "Loudness (in game)", "peaks": "Peaks and clipping", "duration":
	"Duration, silence, tails", "spectral": "Spectral balance and masking", "memory": "Memory and disk",
	"bus": "Bus routing", "variation": "Variation", "3d": "3D attenuation", "voices": "Voice limits",
	"missing": "Missing cues", "speech": "Spoken lines (Voice Forge, per speaker)"}

## Spoken lines (Voice Forge WAVs, tools/voice_forge/README.md): judged apart from the SFX cues, per speaker, from
## data/voice/manifest.json (the speaker of each line; files not in the manifest use their folder name).
## `voice=1` turns it on (default: on for set=res://assets/audio and set=res://assets/audio/voice...).
## Speech loudness = BS.1770 integrated per line (file, no volume_db: VoicePlayer plays at 0 dB).
const VOICE_DIR := "res://assets/audio/voice"
const VOICE_MANIFEST := "res://data/voice/manifest.json"
const SPEECH_LUFS := Vector2(-24.0, -14.0)   ## Every speaker's median line in this range (dialogue over music -22).
const SPEECH_SPEAKER_TOL := 3.0   ## Speaker median vs the median of all speakers: more = one character is louder.
const SPEECH_LINE_TOL := 4.0      ## A line vs its speaker's median: more = WARN (the line jumps out / drops away).
const SPEECH_LINE_FAIL := 8.0     ## More = FAIL (a broken render: whisper-quiet or shouting).
const SPEECH_TP_WARN := -0.5      ## dBTP (Voice Forge normalises the peak to -1 dBFS; QOA import may add a little).

## Category of a cue id when kind=auto: exact ids first, then prefixes, then the folder, else "unit".
const CATEGORY_BY_ID := {
	"ui_error": "alert", "level_up": "alert", "construction_done": "alert", "unit_trained": "alert",
	"crown_claimed": "alert", "victory": "alert", "defeat": "alert", "building_collapse": "alert",
	"crystals_delivered": "ui", "mine_tick": "unit", "mapfill_chime": "alert", "mapfill_horn": "alert",
	"mapfill_drum": "alert", "mapfill_roar": "alert", "mapfill_stag": "alert", "mapfill_bubble": "ui",
	"mapfill_splash": "unit", "trade_coin": "ui", "trade_whistle": "alert", "trade_horn": "alert",
	"alert_wizard_fell": "alert", "wizard_fell": "alert", "ability_cast": "spell", "skill_hit": "unit",
}
## Takes (<id>_1.wav ... next to <id>.wav) inherit their parent's category, volume, 3D and play rate; their levels
## must stay within TAKE_TOL of each other (a random pick must not jump out).
const TAKE_TOL := 2.0
## Decoded peak minus source .wav peak above this = the lossy import (QOA) distorts the cue: WARN + import hint.
const IMPORT_OVERSHOOT_DB := 1.0
const CATEGORY_PREFIXES := [["music_", "music"], ["amb_", "ambience"], ["ambience_", "ambience"], ["ui_", "ui"],
	["item_", "ui"], ["ping_", "ui"], ["spell_", "spell"], ["fireball_", "spell"], ["alert_", "alert"],
	["ally_", "alert"], ["stinger_", "alert"]]

## Expected plays per minute in a busy mid-game fight (used when no fight was measured; fight=1 measures them).
const EXPECTED_RATE := {
	"melee_hit": 120.0, "bolt_shot": 120.0, "bolt_impact": 120.0, "building_hit": 40.0, "death_fire": 12.0,
	"death_shadow": 12.0, "mine_tick": 60.0, "crystals_delivered": 20.0, "ui_click": 30.0, "mapfill_splash": 20.0,
	"fireball_cast": 6.0, "fireball_explode": 6.0, "trade_coin": 3.0, "item_used": 3.0, "unit_trained": 4.0,
}
## Cues whose loudness must match within FAMILY_TOL (same role, different faction / variant).
const FAMILIES: Array[String] = ["death_", "ping_"]
const FAMILY_TOL := 3.0

## Gameplay events that should make a sound. `signals`: any of these connected in an audio script to a handler
## that plays a sound = covered. `evidence`: regex found in an audio script = covered (no signal to hook) or, when
## `signals` exist too, partly covered. core = FAIL when missing (WARN if the game has no such event yet: design
## gap); not core = INFO (nice to have). Events whose signals exist nowhere in the code are INFO "not in game yet".
const KEY_EVENTS := [
	{"id": "unit_death", "label": "Unit death", "signals": ["unit_died", "died"], "core": true},
	{"id": "melee_hit", "label": "Melee hit", "signals": ["attack_landed"], "core": true},
	{"id": "ranged_shot", "label": "Ranged shot (projectile)", "evidence": "bolt_shot", "core": true},
	{"id": "spell_cast", "label": "Wizard spell cast", "signals": ["spell_cast"], "core": true},
	{"id": "spell_impact", "label": "Spell impact / zone tick", "signals": ["spell_hit", "spell_effect", "hit_target"],
		"evidence": "fireball_explode", "core": false},
	{"id": "champion_ability", "label": "Champion ability cast", "signals": ["ability_cast", "skill_hit"], "core": true},
	{"id": "creature_ability", "label": "Creature / beast ability", "signals": ["ability_hit"], "core": false},
	{"id": "building_hit", "label": "Building hit", "signals": ["damaged"], "core": true},
	{"id": "building_destroyed", "label": "Building destroyed", "signals": ["destroyed"], "core": true},
	{"id": "construction_done", "label": "Construction finished", "signals": ["construction_finished",
		"building_completed"], "core": true},
	{"id": "build_placed", "label": "Building placed (order confirmed)", "signals": ["building_placed"], "core": false},
	{"id": "unit_trained", "label": "Unit trained", "signals": ["unit_trained"], "core": true},
	{"id": "worker_mining", "label": "Worker mining", "evidence": "mine_tick", "core": false},
	{"id": "resources_delivered", "label": "Crystals delivered", "evidence": "crystals_delivered", "core": false},
	{"id": "cannot_afford", "label": "Not enough resources (refused)", "signals": ["spend_failed"], "core": true},
	{"id": "level_up", "label": "Level up", "signals": ["level_changed"], "core": true},
	{"id": "spell_learned", "label": "Spell learned / ranked up", "signals": ["spell_learned"], "core": false},
	{"id": "capture", "label": "Capture point taken", "signals": ["point_captured", "owner_changed"], "core": true},
	{"id": "point_lost", "label": "Capture point neutralised / lost", "signals": ["point_neutralised"], "core": false},
	{"id": "shrine_awakened", "label": "Wayshrine awakens", "signals": ["shrine_awakened", "awakened"], "core": false},
	{"id": "camp_cleared", "label": "Neutral camp cleared", "signals": ["camp_cleared", "cleared"], "core": true},
	{"id": "beast_spawn", "label": "Epic beast spawns", "signals": ["beast_spawned"], "core": true},
	{"id": "beast_slain", "label": "Epic beast slain", "signals": ["beast_slain"], "core": false},
	{"id": "trade_arrival", "label": "Caravan delivery (trade arrival)", "signals": ["delivered"], "core": true},
	{"id": "caravan_robbed", "label": "Caravan robbed / miners raided", "signals": ["caravan_robbed", "robbed",
		"workers_raided"], "core": true},
	{"id": "contract_started", "label": "Hunters' contract starts", "signals": ["contract_started"], "core": false},
	{"id": "champion_hired", "label": "Champion hired / revived", "signals": ["champion_hired", "champion_revived"],
		"core": false},
	{"id": "champion_fallen", "label": "Champion fallen", "signals": ["champion_fallen"], "core": false},
	{"id": "class_chosen", "label": "Champion class chosen", "signals": ["class_chosen"], "core": false},
	{"id": "bounty", "label": "Bounty placed / paid", "signals": ["bounty_placed", "bounty_paid"], "core": false},
	{"id": "item_bought", "label": "Item / ware bought", "signals": ["item_bought", "ware_bought"], "core": true},
	{"id": "item_used", "label": "Item used", "signals": ["item_used"], "core": true},
	{"id": "item_pickup", "label": "Item / loot picked up", "signals": ["picked_up", "picked", "loot_picked"],
		"core": true},
	{"id": "artifact_claimed", "label": "Artifact / crown claimed", "signals": ["artifact_claimed", "claimed"],
		"core": true},
	{"id": "crown_dropped", "label": "Crown dropped / lost", "signals": ["dropped", "lost"], "core": false},
	{"id": "wizard_fell", "label": "Your wizard has fallen (alert)", "signals": ["wizard_fell"], "core": true},
	{"id": "wizard_respawned", "label": "Wizard respawned", "signals": ["wizard_respawned", "respawned"],
		"core": false},
	{"id": "match_end", "label": "Victory / defeat", "signals": ["mission_ended", "match_ended"], "core": true},
	{"id": "ui_click", "label": "UI button click", "evidence": "pressed\\.connect", "core": true},
	{"id": "order_ack", "label": "Order acknowledged (move / attack click)", "evidence": "order_ack|command_ack",
		"core": false, "design_gap": true},
	{"id": "under_attack", "label": "Base / army under attack (off-screen alert)",
		"evidence": "under_attack|attack_alert", "core": true, "design_gap": true},
	{"id": "ping", "label": "Minimap / ally ping (2v2)", "signals": ["pinged", "ping_placed"], "core": false},
]

## Listening sheet: what a human should listen for, per category.
const LISTEN_FOR := {
	"ui": "Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks.",
	"unit": "Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom.",
	"spell": "Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX.",
	"alert": "You notice it during the loudest fight without looking; meaning is obvious (good news vs danger).",
	"ambience": "Loop seam inaudible; no distracting events; sits well under the music.",
	"music": "Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue.",
}
## Context the preview plays a category over (tools/audio_lab/audio_lab_preview.gd).
const CONTEXT := {"ui": "ui", "unit": "battle", "spell": "battle", "alert": "battle", "ambience": "map",
	"music": "ui"}

## What a real (non-placeholder) replacement must deliver, per category (the scorecard's "Real replacement" part).
const REPLACEMENT_SPEC := {
	"ui": "44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.",
	"unit": "44.1/48 kHz mono WAV, 3-5 takes per frequent cue (<id>_1.wav ... or an AudioStreamRandomizer .tres), 80-600 ms, transient in the first 5 ms, tail <= 400 ms for hits, peak <= -1 dBTP; recorded / layered foley, not synth.",
	"spell": "44.1/48 kHz mono WAV, one cast + one impact per spell, 0.3-2 s, a faction signature (fire = crackle / roar, shadow = breathy whoosh / reverse swell, ice = crystalline, nature = wood / leaves), tail matched to the VFX.",
	"alert": "44.1/48 kHz mono (stereo only for 2D stingers), 0.3-3 s, strong 1-5 kHz content so it cuts through the fight, a distinct pitch contour per meaning (rising = good, falling = danger), peak <= -1 dBTP.",
	"ambience": "Stereo Ogg Vorbis loops of 60-180 s, seamless loop point, integrated about -30 LUFS, no stand-out events (those are separate one-shots).",
	"music": "Stereo Ogg Vorbis (q 5-6) 2-4 min per track with clean loop points or intro + loop, integrated about -12 LUFS in the file (the game plays it at MUSIC_DB -10: -22 in game), several tracks per state (menu / build-up / battle).",
}
