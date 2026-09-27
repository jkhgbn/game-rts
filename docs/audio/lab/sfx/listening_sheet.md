# Listening sheet: sfx

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/sfx/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

Mark each line: OK / too loud / too quiet / masked / annoying / wrong meaning, and write a note.

| # | Cue | Cat | Context | When it plays | In game LUFS | Listen for | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | bolt_impact | unit | battle | attack_landed -> _on_attack_landed | -30.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 2 | bolt_shot | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 3 | building_collapse | alert | battle | destroyed -> _on_building_destroyed | -12.9 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 4 | building_hit | unit | battle | damaged -> _on_building_damaged | -25.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 5 | construction_done | alert | battle | construction_finished -> _on_construction_finished | -14.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 6 | crown_claimed | alert | battle | artifact_claimed -> _on_artifact_claimed | -8.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 7 | crystals_delivered | ui | ui | changed -> _on_economy_changed | -19.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 8 | death_fire | unit | battle | unit_died -> _on_unit_died | -19.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 9 | death_shadow | unit | battle | unit_died -> _on_unit_died | -15.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 10 | defeat | alert | battle | mission_ended -> _on_mission_ended | -7.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 11 | fireball_cast | spell | battle | spell_cast -> _on_spell_cast | -12.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 12 | fireball_explode | spell | battle | tree_exiting -> _on_splash_gone | -14.1 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 13 | item_bought | ui | ui | _hook_wizard | -12.1 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 14 | item_pickup | ui | ui | picked_up -> _on_picked_up | -15.0 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 15 | item_used | ui | ui | _hook_wizard | -9.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 16 | level_up | alert | battle | level_changed -> _on_level_changed | -10.4 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 17 | melee_hit | unit | battle | attack_landed -> _on_attack_landed | -26.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 18 | mine_tick | unit | battle | _poll_mining | -38.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 19 | spell_ember_step | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 20 | spell_kindle | spell | battle | spell_cast -> _on_spell_cast | -12.6 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 21 | spell_shadow_lance | spell | battle | spell_cast -> _on_spell_cast | -15.9 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 22 | spell_soul_siphon | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 23 | spell_umbral_shroud | spell | battle | spell_cast -> _on_spell_cast | -12.0 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 24 | ui_click | ui | ui | pressed -> _on_button_pressed | -33.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 25 | ui_error | alert | battle | spend_failed/spend_failed -> _on_spend_failed | -13.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 26 | unit_trained | alert | battle | _hook, unit_trained -> _on_unit_trained | -17.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 27 | victory | alert | battle | mission_ended -> _on_mission_ended | -8.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
