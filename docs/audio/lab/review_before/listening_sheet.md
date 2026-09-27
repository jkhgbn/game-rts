# Listening sheet: review_before

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/review_before/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

Mark each line: OK / too loud / too quiet / masked / annoying / wrong meaning, and write a note.

| # | Cue | Cat | Context | When it plays | In game LUFS | Listen for | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | mapfill_bubble | ui | ui | _process -> _check_bubble | -27.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 2 | mapfill_chime | alert | battle | point_captured -> _on_point_captured | -17.8 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 3 | mapfill_drum | alert | battle | camp_cleared -> _on_camp_cleared | -20.3 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 4 | mapfill_horn | alert | battle | shrine_awakened -> _on_shrine_awakened | -9.8 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 5 | mapfill_roar | alert | battle | beast_spawned -> _on_beast_spawned | -20.1 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 6 | mapfill_splash | unit | battle | _scan_splashes -> play_splash | -29.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 7 | mapfill_stag | alert | battle | engaged -> _on_camp_engaged | -9.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 8 | music_match | music | ui | set_music | -22.3 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 9 | music_menu | music | ui | set_music | -23.1 | Loop point clean; mood fits; does not mask alerts; 30 minutes without fatigue. | | |
| 10 | ability_cast | unit | battle | _hook_champion, ability_cast -> _on_ability_cast | -23.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 11 | alert_wizard_fell | alert | battle | wizard_fell/wizard_fell -> _on_wizard_fell | -9.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 12 | bolt_impact | unit | battle | attack_landed -> _on_attack_landed | -30.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 13 | bolt_impact_1 | unit | battle | - | -19.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 14 | bolt_impact_2 | unit | battle | - | -19.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 15 | bolt_shot | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 16 | bolt_shot_1 | unit | battle | - | -19.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 17 | bolt_shot_2 | unit | battle | - | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 18 | building_collapse | alert | battle | destroyed -> _on_building_destroyed | -12.9 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 19 | building_hit | unit | battle | damaged -> _on_building_damaged | -25.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 20 | building_hit_1 | unit | battle | - | -19.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 21 | building_hit_2 | unit | battle | - | -20.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 22 | construction_done | alert | battle | construction_finished -> _on_construction_finished | -14.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 23 | crown_claimed | alert | battle | artifact_claimed -> _on_artifact_claimed | -8.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 24 | crystals_delivered | ui | ui | changed -> _on_economy_changed | -21.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 25 | death_fire | unit | battle | unit_died -> _on_unit_died | -19.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 26 | death_shadow | unit | battle | unit_died -> _on_unit_died | -17.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 27 | defeat | alert | battle | mission_ended -> _on_mission_ended | -7.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 28 | fireball_cast | spell | battle | spell_cast -> _on_spell_cast | -12.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 29 | fireball_explode | spell | battle | tree_exiting -> _on_splash_gone | -14.1 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 30 | item_bought | ui | ui | _hook_wizard | -16.1 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 31 | item_pickup | ui | ui | picked_up -> _on_picked_up | -15.0 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 32 | item_used | ui | ui | _hook_wizard | -15.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 33 | level_up | alert | battle | level_changed -> _on_level_changed | -10.4 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 34 | melee_hit | unit | battle | attack_landed -> _on_attack_landed | -26.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 35 | melee_hit_1 | unit | battle | - | -19.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 36 | melee_hit_2 | unit | battle | - | -19.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 37 | mine_tick | unit | battle | _poll_mining | -34.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 38 | mine_tick_1 | unit | battle | - | -22.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 39 | mine_tick_2 | unit | battle | - | -22.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 40 | skill_hit | unit | battle | _hook_champion, skill_hit -> _on_skill_hit | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 41 | spell_ember_step | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 42 | spell_kindle | spell | battle | spell_cast -> _on_spell_cast | -12.6 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 43 | spell_shadow_lance | spell | battle | spell_cast -> _on_spell_cast | -15.9 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 44 | spell_soul_siphon | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 45 | spell_umbral_shroud | spell | battle | spell_cast -> _on_spell_cast | -12.0 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 46 | ui_click | ui | ui | pressed -> _on_button_pressed | -33.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 47 | ui_error | alert | battle | spend_failed/spend_failed -> _on_spend_failed | -13.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 48 | unit_trained | alert | battle | _hook, unit_trained -> _on_unit_trained | -17.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 49 | victory | alert | battle | mission_ended -> _on_mission_ended | -8.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 50 | trade_coin | ui | ui | delivered -> _on_delivered, loot_picked -> _on_loot_picked | -18.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 51 | trade_horn | alert | battle | contract_started -> _on_contract_started | -9.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 52 | trade_whistle | alert | battle | caravan_robbed -> _on_caravan_robbed, workers_raided -> _on_workers_raided | -8.1 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
