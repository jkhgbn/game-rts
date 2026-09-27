# Listening sheet: skirmish

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/skirmish/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

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
| 8 | music_match | music | ui | set_music | -22.3 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 9 | music_menu | music | ui | set_music | -23.1 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 10 | bolt_impact | unit | battle | attack_landed -> _on_attack_landed | -30.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 11 | bolt_shot | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 12 | building_collapse | alert | battle | destroyed -> _on_building_destroyed | -12.9 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 13 | building_hit | unit | battle | damaged -> _on_building_damaged | -25.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 14 | construction_done | alert | battle | construction_finished -> _on_construction_finished | -14.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 15 | crown_claimed | alert | battle | artifact_claimed -> _on_artifact_claimed | -8.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 16 | crystals_delivered | ui | ui | changed -> _on_economy_changed | -19.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 17 | death_fire | unit | battle | unit_died -> _on_unit_died | -19.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 18 | death_shadow | unit | battle | unit_died -> _on_unit_died | -15.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 19 | defeat | alert | battle | mission_ended -> _on_mission_ended | -7.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 20 | fireball_cast | spell | battle | spell_cast -> _on_spell_cast | -12.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 21 | fireball_explode | spell | battle | tree_exiting -> _on_splash_gone | -14.1 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 22 | item_bought | ui | ui | _hook_wizard | -12.1 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 23 | item_pickup | ui | ui | picked_up -> _on_picked_up | -15.0 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 24 | item_used | ui | ui | _hook_wizard | -9.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 25 | level_up | alert | battle | level_changed -> _on_level_changed | -10.4 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 26 | melee_hit | unit | battle | attack_landed -> _on_attack_landed | -26.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 27 | mine_tick | unit | battle | _poll_mining | -38.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 28 | spell_ember_step | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 29 | spell_kindle | spell | battle | spell_cast -> _on_spell_cast | -12.6 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 30 | spell_shadow_lance | spell | battle | spell_cast -> _on_spell_cast | -15.9 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 31 | spell_soul_siphon | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 32 | spell_umbral_shroud | spell | battle | spell_cast -> _on_spell_cast | -12.0 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 33 | ui_click | ui | ui | pressed -> _on_button_pressed | -33.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 34 | ui_error | alert | battle | spend_failed/spend_failed -> _on_spend_failed | -13.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 35 | unit_trained | alert | battle | _hook, unit_trained -> _on_unit_trained | -17.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 36 | victory | alert | battle | mission_ended -> _on_mission_ended | -8.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 37 | trade_coin | ui | ui | delivered -> _on_delivered, loot_picked -> _on_loot_picked | -18.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 38 | trade_horn | alert | battle | contract_started -> _on_contract_started | -9.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 39 | trade_whistle | alert | battle | caravan_robbed -> _on_caravan_robbed, workers_raided -> _on_workers_raided | -8.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
