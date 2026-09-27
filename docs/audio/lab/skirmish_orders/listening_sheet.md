# Listening sheet: skirmish_orders

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/skirmish_orders/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

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
| 10 | ab_blood_frenzy | unit | battle | - | -20.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 11 | ab_challenge | unit | battle | - | -23.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 12 | ab_flame_burst | unit | battle | - | -18.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 13 | ab_flashpoint | unit | battle | unit_died -> _on_unit_died | -22.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 14 | ab_frost_needle | unit | battle | - | -20.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 15 | ab_frost_shell | unit | battle | - | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 16 | ab_genie_chain | unit | battle | attack_landed -> _on_attack_landed | -19.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 17 | ab_grave_feast | unit | battle | - | -21.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 18 | ab_grove_oath | unit | battle | - | -21.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 19 | ab_hold_the_line | unit | battle | - | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 20 | ab_piercing_bolt | unit | battle | - | -27.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 21 | ab_sab_armed | unit | battle | - | -21.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 22 | ab_sab_blast | unit | battle | _arm_blast | -18.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 23 | ab_sab_disguise | unit | battle | _poll_ability | -22.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 24 | ab_sab_plant | unit | battle | _poll_ability | -24.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 25 | ab_sab_reveal | unit | battle | _poll_ability | -22.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 26 | ab_seed_storm | unit | battle | - | -21.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 27 | ab_skitter | unit | battle | - | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 28 | ab_snare_lash | unit | battle | - | -18.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 29 | ab_tempest_bolt | unit | battle | - | -18.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 30 | ab_unbroken_vow | unit | battle | - | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 31 | ab_wither_hex | unit | battle | - | -19.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 32 | ability_cast | spell | battle | _hook_champion, ability_cast -> _on_ability_cast, _hook_unit_orders | -23.4 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 33 | alert_caravan_trained | alert | battle | unit_trained -> _on_unit_trained | -16.2 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 34 | alert_helper_arrive | alert | battle | _hook_orders, helper_ready/helper_fallen/helper_revived -> _on_helper_event | -12.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 35 | alert_helper_fall | alert | battle | _hook_orders, helper_ready/helper_fallen/helper_revived -> _on_helper_event | -12.3 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 36 | alert_helper_revive | alert | battle | _hook_orders, helper_ready/helper_fallen/helper_revived -> _on_helper_event | -11.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 37 | alert_path_int | alert | battle | path_chosen -> _on_path_chosen | -13.2 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 38 | alert_path_str | alert | battle | path_chosen -> _on_path_chosen | -12.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 39 | alert_plus_done | alert | battle | _hook_orders, upgrade_started/upgrade_completed -> _on_plus | -13.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 40 | alert_tier_citadel | alert | battle | tier_changed -> _on_keep_tier_changed | -12.8 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 41 | alert_tier_stronghold | alert | battle | tier_changed -> _on_keep_tier_changed | -11.4 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 42 | alert_wizard_fell | alert | battle | wizard_fell/wizard_fell -> _on_wizard_fell | -9.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 43 | atk_beast | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -25.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 44 | atk_blade | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -24.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 45 | atk_bolt | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 46 | atk_bow | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -28.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 47 | atk_heavy | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 48 | atk_magic | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 49 | atk_siege | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 50 | atk_storm | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 51 | atk_whip | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 52 | bolt_impact | unit | battle | attack_landed -> _on_attack_landed | -30.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 53 | bolt_impact_1 | unit | battle | attack_landed -> _on_attack_landed | -30.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 54 | bolt_impact_2 | unit | battle | attack_landed -> _on_attack_landed | -31.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 55 | bolt_shot | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 56 | bolt_shot_1 | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 57 | bolt_shot_2 | unit | battle | _hook_projectile | -31.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 58 | building_collapse | alert | battle | destroyed -> _on_building_destroyed | -12.9 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 59 | building_hit | unit | battle | damaged -> _on_building_damaged | -25.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 60 | building_hit_1 | unit | battle | damaged -> _on_building_damaged | -28.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 61 | building_hit_2 | unit | battle | damaged -> _on_building_damaged | -30.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 62 | construction_done | alert | battle | construction_finished -> _on_construction_finished | -14.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 63 | crown_claimed | alert | battle | artifact_claimed -> _on_artifact_claimed | -8.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 64 | crystals_delivered | ui | ui | changed -> _on_economy_changed | -21.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 65 | death_beast | unit | battle | unit_died -> _on_unit_died | -18.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 66 | death_blade | unit | battle | unit_died -> _on_unit_died | -19.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 67 | death_bolt | unit | battle | unit_died -> _on_unit_died | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 68 | death_bow | unit | battle | unit_died -> _on_unit_died | -20.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 69 | death_fire | unit | battle | unit_died -> _on_unit_died | -19.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 70 | death_heavy | unit | battle | unit_died -> _on_unit_died | -19.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 71 | death_magic | unit | battle | unit_died -> _on_unit_died | -17.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 72 | death_shadow | unit | battle | unit_died -> _on_unit_died | -17.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 73 | death_siege | unit | battle | unit_died -> _on_unit_died | -18.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 74 | death_storm | unit | battle | unit_died -> _on_unit_died | -18.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 75 | death_whip | unit | battle | unit_died -> _on_unit_died | -18.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 76 | defeat | alert | battle | mission_ended -> _on_mission_ended | -7.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 77 | fireball_cast | spell | battle | spell_cast -> _on_spell_cast | -12.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 78 | fireball_explode | spell | battle | tree_exiting -> _on_splash_gone | -14.1 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 79 | fx_bleed | unit | battle | - | -24.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 80 | fx_burn | unit | battle | - | -24.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 81 | fx_chill | unit | battle | - | -23.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 82 | fx_crit | unit | battle | _check_crit | -27.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 83 | helper_cast | unit | battle | ability_cast -> _on_helper_cast | -21.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 84 | hit_beast | unit | battle | attack_landed -> _on_attack_landed | -26.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 85 | hit_blade | unit | battle | attack_landed -> _on_attack_landed | -29.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 86 | hit_bolt | unit | battle | attack_landed -> _on_attack_landed | -27.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 87 | hit_bow | unit | battle | attack_landed -> _on_attack_landed | -28.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 88 | hit_heavy | unit | battle | attack_landed -> _on_attack_landed | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 89 | hit_magic | unit | battle | attack_landed -> _on_attack_landed | -25.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 90 | hit_siege | unit | battle | attack_landed -> _on_attack_landed | -25.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 91 | hit_storm | unit | battle | attack_landed -> _on_attack_landed | -24.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 92 | hit_whip | unit | battle | attack_landed -> _on_attack_landed | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 93 | item_bought | ui | ui | _hook_wizard | -16.1 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 94 | item_pickup | ui | ui | picked_up -> _on_picked_up | -15.0 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 95 | item_used | ui | ui | _hook_wizard | -15.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 96 | level_up | alert | battle | level_changed -> _on_level_changed | -10.4 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 97 | melee_hit | unit | battle | attack_landed -> _on_attack_landed | -26.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 98 | melee_hit_1 | unit | battle | attack_landed -> _on_attack_landed | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 99 | melee_hit_2 | unit | battle | attack_landed -> _on_attack_landed | -27.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 100 | mine_tick | unit | battle | _poll_mining | -34.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 101 | mine_tick_1 | unit | battle | _poll_mining | -34.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 102 | mine_tick_2 | unit | battle | _poll_mining | -34.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 103 | skill_hit | unit | battle | _hook_champion, skill_hit -> _on_skill_hit | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 104 | spell_ember_step | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 105 | spell_kindle | spell | battle | spell_cast -> _on_spell_cast | -12.6 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 106 | spell_shadow_lance | spell | battle | spell_cast -> _on_spell_cast | -15.9 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 107 | spell_snow_shield_off | spell | battle | spell_cast -> _on_spell_cast, ability_started/ability_ended -> _on_path_ability | -16.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 108 | spell_snow_shield_on | spell | battle | spell_cast -> _on_spell_cast, ability_started/ability_ended -> _on_path_ability | -12.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 109 | spell_soul_siphon | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 110 | spell_umbral_shroud | spell | battle | spell_cast -> _on_spell_cast | -12.0 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 111 | spell_vigor_off | spell | battle | spell_cast -> _on_spell_cast, ability_started/ability_ended -> _on_path_ability | -18.0 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 112 | spell_vigor_on | spell | battle | spell_cast -> _on_spell_cast, ability_started/ability_ended -> _on_path_ability | -14.8 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 113 | ui_click | ui | ui | pressed -> _on_button_pressed | -33.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 114 | ui_error | alert | battle | spend_failed/spend_failed -> _on_spend_failed | -13.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 115 | ui_helper_call | ui | ui | helper_called -> _on_helper_called | -18.4 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 116 | ui_hint | ui | ui | _poll_orders | -22.4 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 117 | ui_plus_start | ui | ui | _hook_orders, upgrade_started/upgrade_completed -> _on_plus | -23.0 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 118 | ui_restart | ui | ui | _start_music | -21.4 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 119 | ui_tab | ui | ui | _poll_selection | -28.1 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 120 | ui_tier_start | ui | ui | _poll_orders | -24.2 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 121 | ui_tier_tick | ui | ui | _poll_orders | -28.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 122 | ui_upgrade_cancel | ui | ui | _hook_orders, _poll_orders | -22.4 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 123 | unit_trained | alert | battle | _hook, unit_trained -> _on_unit_trained | -17.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 124 | victory | alert | battle | mission_ended -> _on_mission_ended | -8.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 125 | trade_coin | ui | ui | delivered -> _on_delivered, loot_picked -> _on_loot_picked | -18.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 126 | trade_horn | alert | battle | contract_started -> _on_contract_started | -9.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 127 | trade_whistle | alert | battle | caravan_robbed -> _on_caravan_robbed, workers_raided -> _on_workers_raided | -8.1 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
