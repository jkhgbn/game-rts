# Listening sheet: music

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/music/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

Mark each line: OK / too loud / too quiet / masked / annoying / wrong meaning, and write a note.

| # | Cue | Cat | Context | When it plays | In game LUFS | Listen for | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | boss | music | ui | - | -22.3 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 2 | boss_drive | music | ui | not played by code | -16.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 3 | campaign_map | music | ui | - | -22.4 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 4 | chant | music | ui | apply_scene | -22.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 5 | field | music | ui | _weighted_pool | -22.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 6 | field_drive | music | ui | not played by code | -16.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 7 | fire | music | ui | apply_scene, _own | -22.3 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 8 | fire_drive | music | ui | not played by code | -16.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 9 | ice | music | ui | - | -22.3 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 10 | ice_drive | music | ui | not played by code | -16.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 11 | music_match | music | ui | _start_track | -22.3 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 12 | music_menu | music | ui | _start_track | -23.1 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 13 | nature | music | ui | - | -22.3 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 14 | nature_drive | music | ui | not played by code | -16.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 15 | shadow | music | ui | _is_shadow | -22.1 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 16 | shadow_drive | music | ui | not played by code | -16.4 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 17 | sting_defeat | music | ui | mission_ended -> _on_mission_ended | -22.1 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 18 | sting_victory | music | ui | mission_ended -> _on_mission_ended | -22.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 19 | tavern | music | ui | _pick_next | -22.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 20 | theme_main | music | ui | _update_phase | -22.5 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 21 | wave_strike | music | ui | apply_scene, _first_track, _weighted_pool | -22.2 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 22 | wave_strike_drive | music | ui | not played by code | -16.1 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
