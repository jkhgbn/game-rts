# Listening sheet: mapfill

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/mapfill/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

Mark each line: OK / too loud / too quiet / masked / annoying / wrong meaning, and write a note.

| # | Cue | Cat | Context | When it plays | In game LUFS | Listen for | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | mapfill_bubble | ui | ui | _process -> _check_bubble | -27.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 2 | mapfill_chime | alert | battle | point_captured -> _on_point_captured | -17.8 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 3 | mapfill_drum | alert | battle | camp_cleared -> _on_camp_cleared | -20.3 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 4 | mapfill_horn | alert | battle | shrine_awakened -> _on_shrine_awakened | -9.8 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 5 | mapfill_roar | alert | battle | beast_spawned -> _on_beast_spawned | -20.1 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 6 | mapfill_splash | unit | battle | _scan_splashes -> play_splash | -43.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 7 | mapfill_stag | alert | battle | engaged -> _on_camp_engaged | -9.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
