# Audio Lab scorecard: music

- Date: 2026-10-14 10:04:44
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/music kind=music`
- set: `res://assets/audio/music`, kind `music`, 22 cues, 5 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 87 / 100

PASS 124 | WARN 51 | FAIL 0 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Loudness (in game) | 18 | 15 | 7 | 0 | 0 | 84 % |
| Peaks and clipping | 10 | 7 | 16 | 0 | 0 | 65 % |
| Duration, silence, tails | 8 | 45 | 21 | 0 | 0 | 84 % |
| Memory and disk | 5 | 23 | 7 | 0 | 0 | 88 % |
| Bus routing | 12 | 5 | 0 | 0 | 0 | 100 % |
| 3D attenuation | 5 | 1 | 0 | 0 | 0 | 100 % |
| Voice limits | 7 | 1 | 0 | 0 | 0 | 100 % |
| Missing cues | 15 | 27 | 1 | 0 | 14 | not scored |

## Improve next

1. **WARN Loudness (in game)** - Lower the in-game level into the range (volume_db in the player, or re-render the file)  _(boss_drive -4 dB, field_drive -4 dB, fire_drive -4 dB, ice_drive -4 dB, nature_drive -4 dB, shadow_drive -4 dB (+1 more); music: -26..-18 integrated)_
2. **WARN Peaks and clipping** - The source file itself peaks at -1.2 dBFS (the import adds +0.5 dB): normalise the file to -1 dBTP.  _(boss, boss_drive, chant, field, field_drive, fire (+9 more); true peak <= -1 dBTP, no clipping)_
3. **WARN Duration, silence, tails** - Longer track / more tracks: a short loop repeats dozens of times in a match.  _(boss_drive, field_drive, fire_drive, ice_drive, music_match, music_menu (+5 more); music loop >= 60 s)_
4. **WARN Duration, silence, tails** - Cut the loop on a zero crossing / crossfade the loop point (click every loop).  _(boss_drive, chant, fire_drive, ice_drive, music_match, music_menu (+4 more); |last - first sample| <= 0.05)_
5. **WARN Memory and disk** - Wire it up (see Missing cues) or delete it.  _(boss_drive, field_drive, fire_drive, ice_drive, nature_drive, shadow_drive (+1 more); every file in the set is used)_
6. **WARN Peaks and clipping** - Import as PCM or IMA-ADPCM (Import dock, Compress > Mode): the lossy QOA import is distorting this cue.  _(campaign_map; import changes the peak by < 1 dB)_
7. **Replace placeholders** - 2 of 22 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.

## Checks

### Loudness (in game)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | wave_strike_drive | -16.1 LUFS in game (file -16.1, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | boss_drive | -16.2 LUFS in game (file -16.2, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | field_drive | -16.2 LUFS in game (file -16.2, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | fire_drive | -16.2 LUFS in game (file -16.2, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | ice_drive | -16.2 LUFS in game (file -16.2, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | shadow_drive | -16.4 LUFS in game (file -16.4, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | nature_drive | -16.2 LUFS in game (file -16.2, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| PASS | wave_strike | -22.2 LUFS in game (file -12.2, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | theme_main | -22.5 LUFS in game (file -12.5, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | tavern | -22.2 LUFS in game (file -12.2, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | sting_victory | -22.2 LUFS in game (file -12.2, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | sting_defeat | -22.1 LUFS in game (file -12.1, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | shadow | -22.1 LUFS in game (file -12.1, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | nature | -22.3 LUFS in game (file -12.3, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | music_menu | -23.1 LUFS in game (file -13.1, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | music_match | -22.3 LUFS in game (file -12.3, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | ice | -22.3 LUFS in game (file -12.3, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | fire | -22.3 LUFS in game (file -12.3, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | field | -22.2 LUFS in game (file -12.2, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | chant | -22.2 LUFS in game (file -12.2, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | campaign_map | -22.4 LUFS in game (file -12.4, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | boss | -22.3 LUFS in game (file -12.3, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |

### Peaks and clipping

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | sting_defeat | true peak -1.0 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.2 dB): normalise the file to -1 dBTP. |
| WARN | shadow | true peak -0.9 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.3 dB): normalise the file to -1 dBTP. |
| WARN | nature_drive | true peak -0.9 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.3 dB): normalise the file to -1 dBTP. |
| WARN | nature | true peak -0.7 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.4 dB): normalise the file to -1 dBTP. |
| WARN | tavern | true peak -0.8 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.4 dB): normalise the file to -1 dBTP. |
| WARN | theme_main | true peak -0.6 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.5 dB): normalise the file to -1 dBTP. |
| WARN | ice_drive | true peak -0.9 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.3 dB): normalise the file to -1 dBTP. |
| WARN | ice | true peak -0.9 dBTP, 0 clipped runs, source -2.6 dBFS (QOA import +1.6 dB) | true peak <= -1 dBTP, no clipping | The QOA import adds +1.6 dB (source peak -2.6 dBFS): set Compress > Mode to PCM or IMA-ADPCM in the Import dock (.import compress/mode), or leave that much headroom in the file. |
| WARN | wave_strike | true peak -0.8 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.4 dB): normalise the file to -1 dBTP. |
| WARN | fire | true peak -0.5 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.7 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.7 dB): normalise the file to -1 dBTP. |
| WARN | field_drive | true peak -0.9 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.3 dB): normalise the file to -1 dBTP. |
| WARN | field | true peak -0.9 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.3 dB): normalise the file to -1 dBTP. |
| WARN | chant | true peak -0.7 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.5 dB): normalise the file to -1 dBTP. |
| WARN | campaign_map | QOA import raises the peak +1.2 dB (source -2.6 dBFS, decoded -1.4 dBFS) | import changes the peak by < 1 dB | Import as PCM or IMA-ADPCM (Import dock, Compress > Mode): the lossy QOA import is distorting this cue. |
| WARN | boss_drive | true peak -1.0 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.2 dB): normalise the file to -1 dBTP. |
| WARN | boss | true peak -0.7 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.2 dBFS (the import adds +0.5 dB): normalise the file to -1 dBTP. |
| PASS | wave_strike_drive | true peak -1.1 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | sting_victory | true peak -1.0 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | shadow_drive | true peak -1.1 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | music_menu | true peak -4.4 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | music_match | true peak -4.4 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fire_drive | true peak -1.0 dBTP, 0 clipped runs, source -1.2 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | campaign_map | true peak -1.4 dBTP, 0 clipped runs, source -2.6 dBFS (QOA import +1.2 dB) | true peak <= -1 dBTP, no clipping |  |

### Duration, silence, tails

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | nature | loop seam jump 0.075 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | nature_drive | 30.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | nature_drive | loop seam jump 0.230 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | music_menu | loop seam jump 0.310 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | music_menu | 40.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | music_match | loop seam jump 0.265 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | music_match | 48.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | ice_drive | loop seam jump 0.077 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | ice_drive | 40.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | shadow | loop seam jump 0.084 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | shadow_drive | 32.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | fire_drive | loop seam jump 0.146 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | fire_drive | 40.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | sting_defeat | 8.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | sting_victory | 8.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | field_drive | 38.4 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | wave_strike_drive | loop seam jump 0.081 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | wave_strike_drive | 30.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | boss_drive | 21.4 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | boss_drive | loop seam jump 0.201 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | chant | loop seam jump 0.058 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| PASS | wave_strike_drive | lead silence 0 ms | lead <= 500 ms |  |
| PASS | wave_strike | loop seam jump 0.006 | \|last - first sample\| <= 0.05 |  |
| PASS | shadow | lead silence 0 ms | lead <= 500 ms |  |
| PASS | wave_strike | 120.0 s loop | music loop >= 60 s |  |
| PASS | shadow | 160.0 s loop | music loop >= 60 s |  |
| PASS | wave_strike | lead silence 0 ms | lead <= 500 ms |  |
| PASS | theme_main | loop seam jump 0.022 | \|last - first sample\| <= 0.05 |  |
| PASS | theme_main | 148.6 s loop | music loop >= 60 s |  |
| PASS | shadow_drive | lead silence 0 ms | lead <= 500 ms |  |
| PASS | theme_main | lead silence 0 ms | lead <= 500 ms |  |
| PASS | shadow_drive | loop seam jump 0.026 | \|last - first sample\| <= 0.05 |  |
| PASS | tavern | loop seam jump 0.000 | \|last - first sample\| <= 0.05 |  |
| PASS | sting_defeat | lead silence 1 ms | lead <= 500 ms |  |
| PASS | tavern | 90.0 s loop | music loop >= 60 s |  |
| PASS | sting_defeat | loop seam jump 0.000 | \|last - first sample\| <= 0.05 |  |
| PASS | sting_victory | lead silence 8 ms | lead <= 500 ms |  |
| PASS | tavern | lead silence 37 ms | lead <= 500 ms |  |
| PASS | sting_victory | loop seam jump 0.000 | \|last - first sample\| <= 0.05 |  |
| PASS | boss | lead silence 0 ms | lead <= 500 ms |  |
| PASS | boss | 150.0 s loop | music loop >= 60 s |  |
| PASS | boss | loop seam jump 0.001 | \|last - first sample\| <= 0.05 |  |
| PASS | boss_drive | lead silence 0 ms | lead <= 500 ms |  |
| PASS | campaign_map | lead silence 11 ms | lead <= 500 ms |  |
| PASS | campaign_map | 120.0 s loop | music loop >= 60 s |  |
| PASS | campaign_map | loop seam jump 0.000 | \|last - first sample\| <= 0.05 |  |
| PASS | chant | lead silence 0 ms | lead <= 500 ms |  |
| PASS | chant | 96.0 s loop | music loop >= 60 s |  |
| PASS | field | lead silence 0 ms | lead <= 500 ms |  |
| PASS | field | 153.6 s loop | music loop >= 60 s |  |
| PASS | field | loop seam jump 0.004 | \|last - first sample\| <= 0.05 |  |
| PASS | field_drive | lead silence 0 ms | lead <= 500 ms |  |
| PASS | field_drive | loop seam jump 0.030 | \|last - first sample\| <= 0.05 |  |
| PASS | fire | lead silence 66 ms | lead <= 500 ms |  |
| PASS | fire | 160.0 s loop | music loop >= 60 s |  |
| PASS | fire | loop seam jump 0.000 | \|last - first sample\| <= 0.05 |  |
| PASS | fire_drive | lead silence 0 ms | lead <= 500 ms |  |
| PASS | ice | lead silence 0 ms | lead <= 500 ms |  |
| PASS | ice | 160.0 s loop | music loop >= 60 s |  |
| PASS | ice | loop seam jump 0.011 | \|last - first sample\| <= 0.05 |  |
| PASS | ice_drive | lead silence 0 ms | lead <= 500 ms |  |
| PASS | music_match | lead silence 0 ms | lead <= 500 ms |  |
| PASS | music_menu | lead silence 0 ms | lead <= 500 ms |  |
| PASS | nature | lead silence 0 ms | lead <= 500 ms |  |
| PASS | nature | 150.0 s loop | music loop >= 60 s |  |
| PASS | nature_drive | lead silence 0 ms | lead <= 500 ms |  |

### Memory and disk

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | wave_strike_drive | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | boss_drive | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | nature_drive | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | ice_drive | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | field_drive | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | shadow_drive | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | fire_drive | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| PASS | nature_drive | 2584 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | shadow | 13781 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | shadow_drive | 2756 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | sting_defeat | 689 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | sting_victory | 689 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | tavern | 7752 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | theme_main | 12797 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | wave_strike | 10336 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | wave_strike_drive | 2584 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | set | 31.8 MB in memory | set <= 48 MB |  |
| PASS | nature | 12920 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | music_menu | 1723 KB on disk, QOA 22050 Hz mono | file <= 15625 KB |  |
| PASS | music_match | 2067 KB on disk, QOA 22050 Hz mono | file <= 15625 KB |  |
| PASS | ice_drive | 3445 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | ice | 13781 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | fire_drive | 3445 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | fire | 13781 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | field_drive | 3308 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | field | 13230 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | chant | 8269 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | campaign_map | 10336 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | boss_drive | 1846 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |
| PASS | boss | 12920 KB on disk, QOA 22050 Hz stereo | file <= 15625 KB |  |

### Bus routing

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:1173 | AudioStreamPlayer3D on bus SFX | bus in Music, SFX, Voice |  |
| PASS | res://scripts/audio/game_audio.gd:1184 | AudioStreamPlayer on bus SFX | bus in Music, SFX, Voice |  |
| PASS | res://scripts/audio/music_director.gd:162 | AudioStreamPlayer on bus Music | bus in Music, SFX, Voice |  |
| PASS | res://scripts/audio/music_director.gd:164 | AudioStreamPlayer on bus Music | bus in Music, SFX, Voice |  |
| PASS | res://scripts/audio/music_director.gd:171 | AudioStreamPlayer on bus Music | bus in Music, SFX, Voice |  |

### 3D attenuation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:1173 | unit_size 18, max_distance 75, inverse_distance; -4.4 dB @30 m, -9.7 dB @55 m, -12.4 dB @cut | gain >= -15 dB at 30 m, <= -10 dB at the cut-off |  |

### Voice limits

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | players | 5 players (1 3D) (from code) | <= 64 players, 3D pool <= 32 |  |

### Missing cues

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | Base / army under attack (off-screen alert) (core) | not in the game yet (no event to hook) | every key event has a sound | Needs a design (game-designer / ui-designer) + a cue. |
| PASS | UI button click (core) | covered: game_audio.gd (pressed\.connect) | every key event has a sound |  |
| PASS | Victory / defeat (core) | covered: game_audio.gd.mission_ended -> _on_mission_ended | every key event has a sound |  |
| PASS | Your wizard has fallen (alert) (core) | covered: game_audio.gd.wizard_fell -> _on_wizard_fell | every key event has a sound |  |
| PASS | Artifact / crown claimed (core) | covered: game_audio.gd.artifact_claimed -> _on_artifact_claimed | every key event has a sound |  |
| PASS | Item / loot picked up (core) | covered: game_audio.gd.picked_up -> _on_picked_up | every key event has a sound |  |
| PASS | Item used (core) | covered: game_audio.gd.item_used -> (lambda) | every key event has a sound |  |
| PASS | Item / ware bought (core) | covered: game_audio.gd.item_bought -> (lambda) | every key event has a sound |  |
| PASS | Hunters' contract starts (nice) | covered: trade_popups.gd.contract_started -> _on_contract_started | every key event has a sound |  |
| PASS | Caravan robbed / miners raided (core) | covered: trade_popups.gd.caravan_robbed -> _on_caravan_robbed | every key event has a sound |  |
| PASS | Caravan delivery (trade arrival) (core) | covered: trade_popups.gd.delivered -> _on_delivered | every key event has a sound |  |
| PASS | Epic beast spawns (core) | covered: mapfill_popups.gd.beast_spawned -> _on_beast_spawned | every key event has a sound |  |
| PASS | Neutral camp cleared (core) | covered: mapfill_popups.gd.camp_cleared -> _on_camp_cleared | every key event has a sound |  |
| PASS | Wayshrine awakens (nice) | covered: mapfill_popups.gd.shrine_awakened -> _on_shrine_awakened | every key event has a sound |  |
| PASS | Capture point taken (core) | covered: mapfill_popups.gd.point_captured -> _on_point_captured | every key event has a sound |  |
| PASS | Champion ability cast (core) | covered: game_audio.gd.ability_cast -> _on_ability_cast | every key event has a sound |  |
| PASS | Building hit (core) | covered: game_audio.gd.damaged -> _on_building_damaged | every key event has a sound |  |
| PASS | Wizard spell cast (core) | covered: game_audio.gd.spell_cast -> _on_spell_cast | every key event has a sound |  |
| PASS | Ranged shot (projectile) (core) | covered: game_audio.gd (bolt_shot) | every key event has a sound |  |
| PASS | Building destroyed (core) | covered: game_audio.gd.destroyed -> _on_building_destroyed | every key event has a sound |  |
| PASS | Construction finished (core) | covered: game_audio.gd.construction_finished -> _on_construction_finished | every key event has a sound |  |
| PASS | Melee hit (core) | covered: game_audio.gd.attack_landed -> _on_attack_landed | every key event has a sound |  |
| PASS | Unit trained (core) | covered: game_audio.gd.unit_trained -> _on_unit_trained | every key event has a sound |  |
| PASS | Worker mining (nice) | covered: game_audio.gd (mine_tick) | every key event has a sound |  |
| PASS | Crystals delivered (nice) | covered: game_audio.gd (crystals_delivered) | every key event has a sound |  |
| PASS | Unit death (core) | covered: game_audio.gd.unit_died -> _on_unit_died | every key event has a sound |  |
| PASS | Not enough resources (refused) (core) | covered: game_audio.gd.spend_failed -> _on_spend_failed | every key event has a sound |  |
| PASS | Level up (core) | covered: game_audio.gd.level_changed -> _on_level_changed | every key event has a sound |  |
| INFO | Order acknowledged (move / attack click) (nice) | not in the game yet (no event to hook) | every key event has a sound | Needs a design (game-designer / ui-designer) + a cue. |
| INFO | Wizard respawned (nice) | no sound (signal wizard_respawned, respawned exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Crown dropped / lost (nice) | no sound (signal dropped, lost exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Minimap / ally ping (2v2) (nice) | no sound (signal pinged exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Spell impact / zone tick (nice) | partly: game_audio.gd (fireball_explode) | every key event has a sound | Hook the event's signal (spell_hit, spell_effect, hit_target) to a cue. |
| INFO | Creature / beast ability (nice) | no sound (signal ability_hit exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Bounty placed / paid (nice) | no sound (signal bounty_placed, bounty_paid exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Champion class chosen (nice) | no sound (signal class_chosen exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Champion fallen (nice) | no sound (signal champion_fallen exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Champion hired / revived (nice) | no sound (signal champion_hired, champion_revived exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Building placed (order confirmed) (nice) | no sound (signal building_placed exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Epic beast slain (nice) | no sound (signal beast_slain exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Capture point neutralised / lost (nice) | no sound (signal point_neutralised exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Spell learned / ranked up (nice) | no sound (signal spell_learned exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |

## Cue table

| Cue | Cat | Mode | In game | File | Vol dB | 3D dB | TP dBTP | Dur s | Lead / trail ms | Bands L/M/P/A % | Rate /min | Takes | Pitch | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| boss | music | 2d | -22.3 | -12.3 | -10.0 | 0.0 | -0.7 | 150.00 | 0 / 0 | 72/27/1/0 | 0 | 1 | - | file |
| boss_drive | music | - | -16.2 | -16.2 | 0.0 | 0.0 | -1.0 | 21.43 | 0 / 0 | 86/13/1/0 | 0 | 1 | - | file |
| campaign_map | music | 2d | -22.4 | -12.4 | -10.0 | 0.0 | -1.4 | 120.00 | 11 / 4353 | 7/71/17/5 | 0 | 1 | - | file |
| chant | music | 2d | -22.2 | -12.2 | -10.0 | 0.0 | -0.7 | 96.00 | 0 / 0 | 29/64/7/0 | 0 | 1 | - | file |
| field | music | 2d | -22.2 | -12.2 | -10.0 | 0.0 | -0.9 | 153.60 | 0 / 0 | 23/75/2/0 | 0 | 1 | - | file |
| field_drive | music | - | -16.2 | -16.2 | 0.0 | 0.0 | -0.9 | 38.40 | 0 / 0 | 85/14/1/0 | 0 | 1 | - | file |
| fire | music | 2d | -22.3 | -12.3 | -10.0 | 0.0 | -0.5 | 160.00 | 66 / 921 | 33/67/0/0 | 0 | 1 | - | file |
| fire_drive | music | - | -16.2 | -16.2 | 0.0 | 0.0 | -1.0 | 40.00 | 0 / 0 | 82/16/2/0 | 0 | 1 | - | file |
| ice | music | 2d | -22.3 | -12.3 | -10.0 | 0.0 | -0.9 | 160.00 | 0 / 0 | 20/66/12/3 | 0 | 1 | - | file |
| ice_drive | music | - | -16.2 | -16.2 | 0.0 | 0.0 | -0.9 | 40.00 | 0 / 0 | 84/12/2/1 | 0 | 1 | - | file |
| music_match | music | 2d | -22.3 | -12.3 | -10.0 | 0.0 | -4.4 | 48.00 | 0 / 0 | 79/21/0/0 | 0 | 1 | - | generated |
| music_menu | music | 2d | -23.1 | -13.1 | -10.0 | 0.0 | -4.4 | 40.00 | 0 / 0 | 70/30/0/0 | 0 | 1 | - | generated |
| nature | music | 2d | -22.3 | -12.3 | -10.0 | 0.0 | -0.7 | 150.00 | 0 / 0 | 22/77/1/0 | 0 | 1 | - | file |
| nature_drive | music | - | -16.2 | -16.2 | 0.0 | 0.0 | -0.9 | 30.00 | 0 / 0 | 89/8/2/1 | 0 | 1 | - | file |
| shadow | music | 2d | -22.1 | -12.1 | -10.0 | 0.0 | -0.9 | 160.00 | 0 / 0 | 65/35/0/0 | 0 | 1 | - | file |
| shadow_drive | music | - | -16.4 | -16.4 | 0.0 | 0.0 | -1.1 | 32.00 | 0 / 0 | 90/9/0/0 | 0 | 1 | - | file |
| sting_defeat | music | 2d | -22.1 | -12.1 | -10.0 | 0.0 | -1.0 | 8.00 | 1 / 89 | 32/66/2/0 | 0 | 1 | - | file |
| sting_victory | music | 2d | -22.2 | -12.2 | -10.0 | 0.0 | -1.0 | 8.00 | 8 / 835 | 22/72/5/1 | 0 | 1 | - | file |
| tavern | music | 2d | -22.2 | -12.2 | -10.0 | 0.0 | -0.8 | 90.00 | 37 / 874 | 34/65/0/0 | 0 | 1 | - | file |
| theme_main | music | 2d | -22.5 | -12.5 | -10.0 | 0.0 | -0.6 | 148.57 | 0 / 0 | 35/62/2/1 | 0 | 1 | - | file |
| wave_strike | music | 2d | -22.2 | -12.2 | -10.0 | 0.0 | -0.8 | 120.00 | 0 / 0 | 60/38/2/0 | 0 | 1 | - | file |
| wave_strike_drive | music | - | -16.1 | -16.1 | 0.0 | 0.0 | -1.1 | 30.00 | 0 / 0 | 87/11/2/1 | 0 | 1 | - | file |

In game = file loudness (cue: 200 ms max; music / ambience: integrated) + the code's volume_db + 3D loss at 30 m (default zoom), on 0 dB buses. `*` = frequent (>= 20 plays / min). Rates are expected (lab table; `fight=1` measures them).

## Targets (lab_rules.gd LOUDNESS)

| Category | Metric | In-game range LUFS | Frequent range | Why |
|---|---|---|---|---|
| ui | cue | -30..-14 | -36..-20 | clear but polite: never louder than an alert, audible over the music |
| unit | cue | -30..-16 | -36..-22 | combat bed: hits, shots, deaths; many at once, so each one moderate |
| spell | cue | -22..-9 | - | hero actions read above the combat bed |
| alert | cue | -22..-7 | - | must cut through a battle (level up, capture, raid, stingers) |
| ambience | integrated | -36..-26 | - | a bed under everything, well below the music |
| music | integrated | -26..-18 | - | the mix anchor (includes GameAudio.MUSIC_DB) |

## What a real replacement needs

2 / 22 files are generated placeholders (sine / noise tones from a generator script). The numbers above judge the level, timing and routing they give the mix; a real sound must keep those and add:

- **music**: Stereo Ogg Vorbis (q 5-6) 2-4 min per track with clean loop points or intro + loop, integrated about -12 LUFS in the file (the game plays it at MUSIC_DB -10: -22 in game), several tracks per state (menu / build-up / battle).
- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
