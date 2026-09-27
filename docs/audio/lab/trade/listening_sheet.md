# Listening sheet: trade

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/trade/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

Mark each line: OK / too loud / too quiet / masked / annoying / wrong meaning, and write a note.

| # | Cue | Cat | Context | When it plays | In game LUFS | Listen for | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | trade_coin | ui | ui | delivered -> _on_delivered, loot_picked -> _on_loot_picked | -18.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 2 | trade_horn | alert | battle | contract_started -> _on_contract_started | -9.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 3 | trade_whistle | alert | battle | caravan_robbed -> _on_caravan_robbed, workers_raided -> _on_workers_raided | -8.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
