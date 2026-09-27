# Listening sheet: unit_sfx

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/unit_sfx/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

Mark each line: OK / too loud / too quiet / masked / annoying / wrong meaning, and write a note.

| # | Cue | Cat | Context | When it plays | In game LUFS | Listen for | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | ability_cast | spell | battle | _hook_champion, ability_cast -> _on_ability_cast | -23.4 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 2 | alert_wizard_fell | alert | battle | wizard_fell/wizard_fell -> _on_wizard_fell | -9.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 3 | atk_beast | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -25.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 4 | atk_blade | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -24.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 5 | atk_bolt | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 6 | atk_bow | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -28.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 7 | atk_heavy | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 8 | atk_magic | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 9 | atk_siege | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 10 | atk_storm | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 11 | atk_whip | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 12 | bolt_impact | unit | battle | attack_landed -> _on_attack_landed | -30.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 13 | bolt_impact_1 | unit | battle | attack_landed -> _on_attack_landed | -30.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 14 | bolt_impact_2 | unit | battle | attack_landed -> _on_attack_landed | -31.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 15 | bolt_shot | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 16 | bolt_shot_1 | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 17 | bolt_shot_2 | unit | battle | _hook_projectile | -31.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 18 | building_collapse | alert | battle | destroyed -> _on_building_destroyed | -12.9 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 19 | building_hit | unit | battle | damaged -> _on_building_damaged | -25.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 20 | building_hit_1 | unit | battle | damaged -> _on_building_damaged | -28.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 21 | building_hit_2 | unit | battle | damaged -> _on_building_damaged | -30.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 22 | construction_done | alert | battle | construction_finished -> _on_construction_finished | -14.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 23 | crown_claimed | alert | battle | artifact_claimed -> _on_artifact_claimed | -8.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 24 | crystals_delivered | ui | ui | changed -> _on_economy_changed | -21.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 25 | death_beast | unit | battle | unit_died -> _on_unit_died | -18.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 26 | death_blade | unit | battle | unit_died -> _on_unit_died | -19.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 27 | death_bolt | unit | battle | unit_died -> _on_unit_died | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 28 | death_bow | unit | battle | unit_died -> _on_unit_died | -20.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 29 | death_fire | unit | battle | unit_died -> _on_unit_died | -19.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 30 | death_heavy | unit | battle | unit_died -> _on_unit_died | -19.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 31 | death_magic | unit | battle | unit_died -> _on_unit_died | -17.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 32 | death_shadow | unit | battle | unit_died -> _on_unit_died | -17.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 33 | death_siege | unit | battle | unit_died -> _on_unit_died | -18.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 34 | death_storm | unit | battle | unit_died -> _on_unit_died | -18.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 35 | death_whip | unit | battle | unit_died -> _on_unit_died | -18.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 36 | defeat | alert | battle | mission_ended -> _on_mission_ended | -7.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 37 | fireball_cast | spell | battle | spell_cast -> _on_spell_cast | -12.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 38 | fireball_explode | spell | battle | tree_exiting -> _on_splash_gone | -14.1 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 39 | hit_beast | unit | battle | attack_landed -> _on_attack_landed | -26.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 40 | hit_blade | unit | battle | attack_landed -> _on_attack_landed | -29.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 41 | hit_bolt | unit | battle | attack_landed -> _on_attack_landed | -27.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 42 | hit_bow | unit | battle | attack_landed -> _on_attack_landed | -28.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 43 | hit_heavy | unit | battle | attack_landed -> _on_attack_landed | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 44 | hit_magic | unit | battle | attack_landed -> _on_attack_landed | -25.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 45 | hit_siege | unit | battle | attack_landed -> _on_attack_landed | -25.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 46 | hit_storm | unit | battle | attack_landed -> _on_attack_landed | -24.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 47 | hit_whip | unit | battle | attack_landed -> _on_attack_landed | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 48 | item_bought | ui | ui | _hook_wizard | -16.1 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 49 | item_pickup | ui | ui | picked_up -> _on_picked_up | -15.0 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 50 | item_used | ui | ui | _hook_wizard | -15.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 51 | level_up | alert | battle | level_changed -> _on_level_changed | -10.4 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 52 | melee_hit | unit | battle | attack_landed -> _on_attack_landed | -26.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 53 | melee_hit_1 | unit | battle | attack_landed -> _on_attack_landed | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 54 | melee_hit_2 | unit | battle | attack_landed -> _on_attack_landed | -27.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 55 | mine_tick | unit | battle | _poll_mining | -34.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 56 | mine_tick_1 | unit | battle | _poll_mining | -34.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 57 | mine_tick_2 | unit | battle | _poll_mining | -34.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 58 | skill_hit | unit | battle | _hook_champion, skill_hit -> _on_skill_hit | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 59 | spell_ember_step | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 60 | spell_kindle | spell | battle | spell_cast -> _on_spell_cast | -12.6 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 61 | spell_shadow_lance | spell | battle | spell_cast -> _on_spell_cast | -15.9 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 62 | spell_soul_siphon | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 63 | spell_umbral_shroud | spell | battle | spell_cast -> _on_spell_cast | -12.0 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 64 | ui_click | ui | ui | pressed -> _on_button_pressed | -33.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 65 | ui_error | alert | battle | spend_failed/spend_failed -> _on_spend_failed | -13.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 66 | unit_trained | alert | battle | _hook, unit_trained -> _on_unit_trained | -17.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 67 | victory | alert | battle | mission_ended -> _on_mission_ended | -8.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
