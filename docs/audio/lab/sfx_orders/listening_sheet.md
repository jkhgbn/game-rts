# Listening sheet: sfx_orders

Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/sfx_orders/preview_cues.json` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience).

Mark each line: OK / too loud / too quiet / masked / annoying / wrong meaning, and write a note.

| # | Cue | Cat | Context | When it plays | In game LUFS | Listen for | Verdict | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | ab_blood_frenzy | unit | battle | - | -20.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 2 | ab_challenge | unit | battle | - | -23.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 3 | ab_flame_burst | unit | battle | - | -18.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 4 | ab_flashpoint | unit | battle | unit_died -> _on_unit_died | -22.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 5 | ab_frost_needle | unit | battle | - | -20.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 6 | ab_frost_shell | unit | battle | - | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 7 | ab_frost_shell_1 | unit | battle | - | -22.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 8 | ab_frost_shell_2 | unit | battle | - | -23.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 9 | ab_genie_chain | unit | battle | attack_landed -> _on_attack_landed | -19.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 10 | ab_genie_chain_1 | unit | battle | attack_landed -> _on_attack_landed | -20.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 11 | ab_genie_chain_2 | unit | battle | attack_landed -> _on_attack_landed | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 12 | ab_grave_feast | unit | battle | - | -21.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 13 | ab_grove_oath | unit | battle | - | -21.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 14 | ab_hold_the_line | unit | battle | - | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 15 | ab_piercing_bolt | unit | battle | - | -27.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 16 | ab_piercing_bolt_1 | unit | battle | - | -27.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 17 | ab_piercing_bolt_2 | unit | battle | - | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 18 | ab_sab_armed | unit | battle | - | -21.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 19 | ab_sab_blast | unit | battle | _arm_blast | -18.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 20 | ab_sab_disguise | unit | battle | _poll_ability | -22.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 21 | ab_sab_plant | unit | battle | _poll_ability | -24.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 22 | ab_sab_reveal | unit | battle | _poll_ability | -22.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 23 | ab_seed_storm | unit | battle | - | -21.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 24 | ab_skitter | unit | battle | - | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 25 | ab_skitter_1 | unit | battle | - | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 26 | ab_skitter_2 | unit | battle | - | -27.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 27 | ab_snare_lash | unit | battle | - | -18.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 28 | ab_tempest_bolt | unit | battle | - | -18.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 29 | ab_unbroken_vow | unit | battle | - | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 30 | ab_wither_hex | unit | battle | - | -19.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 31 | ability_cast | spell | battle | _hook_champion, ability_cast -> _on_ability_cast, _hook_unit_orders | -23.4 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 32 | alert_caravan_trained | alert | battle | unit_trained -> _on_unit_trained | -16.2 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 33 | alert_helper_arrive | alert | battle | _hook_orders, helper_ready/helper_fallen/helper_revived -> _on_helper_event | -12.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 34 | alert_helper_fall | alert | battle | _hook_orders, helper_ready/helper_fallen/helper_revived -> _on_helper_event | -12.3 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 35 | alert_helper_revive | alert | battle | _hook_orders, helper_ready/helper_fallen/helper_revived -> _on_helper_event | -11.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 36 | alert_path_int | alert | battle | path_chosen -> _on_path_chosen | -13.2 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 37 | alert_path_str | alert | battle | path_chosen -> _on_path_chosen | -12.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 38 | alert_plus_done | alert | battle | _hook_orders, upgrade_started/upgrade_completed -> _on_plus | -13.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 39 | alert_tier_citadel | alert | battle | tier_changed -> _on_keep_tier_changed | -12.8 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 40 | alert_tier_stronghold | alert | battle | tier_changed -> _on_keep_tier_changed | -11.4 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 41 | alert_wizard_fell | alert | battle | wizard_fell/wizard_fell -> _on_wizard_fell | -9.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 42 | atk_beast | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -25.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 43 | atk_beast_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -25.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 44 | atk_beast_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -25.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 45 | atk_blade | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -24.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 46 | atk_blade_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -24.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 47 | atk_blade_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -24.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 48 | atk_bolt | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 49 | atk_bolt_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 50 | atk_bolt_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -27.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 51 | atk_bow | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -28.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 52 | atk_bow_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -28.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 53 | atk_bow_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -29.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 54 | atk_heavy | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 55 | atk_heavy_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 56 | atk_heavy_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 57 | atk_magic | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 58 | atk_magic_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 59 | atk_magic_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 60 | atk_siege | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 61 | atk_siege_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 62 | atk_siege_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 63 | atk_storm | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 64 | atk_storm_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 65 | atk_storm_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -21.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 66 | atk_whip | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 67 | atk_whip_1 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 68 | atk_whip_2 | unit | battle | _hook_projectile, attack_landed -> _on_attack_landed | -23.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 69 | bolt_impact | unit | battle | attack_landed -> _on_attack_landed | -30.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 70 | bolt_impact_1 | unit | battle | attack_landed -> _on_attack_landed | -30.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 71 | bolt_impact_2 | unit | battle | attack_landed -> _on_attack_landed | -31.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 72 | bolt_shot | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 73 | bolt_shot_1 | unit | battle | _hook_projectile | -31.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 74 | bolt_shot_2 | unit | battle | _hook_projectile | -31.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 75 | building_collapse | alert | battle | destroyed -> _on_building_destroyed | -12.9 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 76 | building_hit | unit | battle | damaged -> _on_building_damaged | -25.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 77 | building_hit_1 | unit | battle | damaged -> _on_building_damaged | -28.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 78 | building_hit_2 | unit | battle | damaged -> _on_building_damaged | -30.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 79 | construction_done | alert | battle | construction_finished -> _on_construction_finished | -14.5 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 80 | crown_claimed | alert | battle | artifact_claimed -> _on_artifact_claimed | -8.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 81 | crystals_delivered | ui | ui | changed -> _on_economy_changed | -21.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 82 | death_beast | unit | battle | unit_died -> _on_unit_died | -18.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 83 | death_beast_1 | unit | battle | unit_died -> _on_unit_died | -18.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 84 | death_beast_2 | unit | battle | unit_died -> _on_unit_died | -18.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 85 | death_blade | unit | battle | unit_died -> _on_unit_died | -19.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 86 | death_blade_1 | unit | battle | unit_died -> _on_unit_died | -19.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 87 | death_blade_2 | unit | battle | unit_died -> _on_unit_died | -19.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 88 | death_bolt | unit | battle | unit_died -> _on_unit_died | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 89 | death_bolt_1 | unit | battle | unit_died -> _on_unit_died | -19.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 90 | death_bolt_2 | unit | battle | unit_died -> _on_unit_died | -19.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 91 | death_bow | unit | battle | unit_died -> _on_unit_died | -20.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 92 | death_bow_1 | unit | battle | unit_died -> _on_unit_died | -20.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 93 | death_bow_2 | unit | battle | unit_died -> _on_unit_died | -20.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 94 | death_fire | unit | battle | unit_died -> _on_unit_died | -19.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 95 | death_heavy | unit | battle | unit_died -> _on_unit_died | -19.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 96 | death_heavy_1 | unit | battle | unit_died -> _on_unit_died | -19.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 97 | death_heavy_2 | unit | battle | unit_died -> _on_unit_died | -19.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 98 | death_magic | unit | battle | unit_died -> _on_unit_died | -17.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 99 | death_magic_1 | unit | battle | unit_died -> _on_unit_died | -17.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 100 | death_magic_2 | unit | battle | unit_died -> _on_unit_died | -17.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 101 | death_shadow | unit | battle | unit_died -> _on_unit_died | -17.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 102 | death_siege | unit | battle | unit_died -> _on_unit_died | -18.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 103 | death_siege_1 | unit | battle | unit_died -> _on_unit_died | -18.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 104 | death_siege_2 | unit | battle | unit_died -> _on_unit_died | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 105 | death_storm | unit | battle | unit_died -> _on_unit_died | -18.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 106 | death_storm_1 | unit | battle | unit_died -> _on_unit_died | -18.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 107 | death_storm_2 | unit | battle | unit_died -> _on_unit_died | -18.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 108 | death_whip | unit | battle | unit_died -> _on_unit_died | -18.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 109 | death_whip_1 | unit | battle | unit_died -> _on_unit_died | -19.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 110 | death_whip_2 | unit | battle | unit_died -> _on_unit_died | -18.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 111 | defeat | alert | battle | mission_ended -> _on_mission_ended | -7.6 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 112 | fireball_cast | spell | battle | spell_cast -> _on_spell_cast | -12.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 113 | fireball_explode | spell | battle | tree_exiting -> _on_splash_gone | -14.1 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 114 | fx_bleed | unit | battle | - | -24.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 115 | fx_bleed_1 | unit | battle | - | -24.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 116 | fx_bleed_2 | unit | battle | - | -24.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 117 | fx_burn | unit | battle | - | -24.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 118 | fx_burn_1 | unit | battle | - | -24.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 119 | fx_burn_2 | unit | battle | - | -25.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 120 | fx_chill | unit | battle | - | -23.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 121 | fx_chill_1 | unit | battle | - | -24.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 122 | fx_chill_2 | unit | battle | - | -23.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 123 | fx_crit | unit | battle | _check_crit | -27.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 124 | fx_crit_1 | unit | battle | _check_crit | -27.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 125 | fx_crit_2 | unit | battle | _check_crit | -27.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 126 | helper_cast | unit | battle | ability_cast -> _on_helper_cast | -21.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 127 | helper_cast_1 | unit | battle | ability_cast -> _on_helper_cast | -22.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 128 | helper_cast_2 | unit | battle | ability_cast -> _on_helper_cast | -21.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 129 | hit_beast | unit | battle | attack_landed -> _on_attack_landed | -26.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 130 | hit_beast_1 | unit | battle | attack_landed -> _on_attack_landed | -26.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 131 | hit_beast_2 | unit | battle | attack_landed -> _on_attack_landed | -26.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 132 | hit_blade | unit | battle | attack_landed -> _on_attack_landed | -29.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 133 | hit_blade_1 | unit | battle | attack_landed -> _on_attack_landed | -29.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 134 | hit_blade_2 | unit | battle | attack_landed -> _on_attack_landed | -29.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 135 | hit_bolt | unit | battle | attack_landed -> _on_attack_landed | -27.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 136 | hit_bolt_1 | unit | battle | attack_landed -> _on_attack_landed | -27.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 137 | hit_bolt_2 | unit | battle | attack_landed -> _on_attack_landed | -27.0 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 138 | hit_bow | unit | battle | attack_landed -> _on_attack_landed | -28.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 139 | hit_bow_1 | unit | battle | attack_landed -> _on_attack_landed | -28.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 140 | hit_bow_2 | unit | battle | attack_landed -> _on_attack_landed | -28.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 141 | hit_heavy | unit | battle | attack_landed -> _on_attack_landed | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 142 | hit_heavy_1 | unit | battle | attack_landed -> _on_attack_landed | -27.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 143 | hit_heavy_2 | unit | battle | attack_landed -> _on_attack_landed | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 144 | hit_magic | unit | battle | attack_landed -> _on_attack_landed | -25.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 145 | hit_magic_1 | unit | battle | attack_landed -> _on_attack_landed | -26.1 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 146 | hit_magic_2 | unit | battle | attack_landed -> _on_attack_landed | -26.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 147 | hit_siege | unit | battle | attack_landed -> _on_attack_landed | -25.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 148 | hit_siege_1 | unit | battle | attack_landed -> _on_attack_landed | -25.8 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 149 | hit_siege_2 | unit | battle | attack_landed -> _on_attack_landed | -25.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 150 | hit_storm | unit | battle | attack_landed -> _on_attack_landed | -24.2 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 151 | hit_storm_1 | unit | battle | attack_landed -> _on_attack_landed | -24.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 152 | hit_storm_2 | unit | battle | attack_landed -> _on_attack_landed | -24.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 153 | hit_whip | unit | battle | attack_landed -> _on_attack_landed | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 154 | hit_whip_1 | unit | battle | attack_landed -> _on_attack_landed | -28.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 155 | hit_whip_2 | unit | battle | attack_landed -> _on_attack_landed | -27.3 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 156 | item_bought | ui | ui | _hook_wizard | -16.1 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 157 | item_pickup | ui | ui | picked_up -> _on_picked_up | -15.0 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 158 | item_used | ui | ui | _hook_wizard | -15.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 159 | level_up | alert | battle | level_changed -> _on_level_changed | -10.4 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 160 | melee_hit | unit | battle | attack_landed -> _on_attack_landed | -26.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 161 | melee_hit_1 | unit | battle | attack_landed -> _on_attack_landed | -27.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 162 | melee_hit_2 | unit | battle | attack_landed -> _on_attack_landed | -27.4 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 163 | mine_tick | unit | battle | _poll_mining | -34.9 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 164 | mine_tick_1 | unit | battle | _poll_mining | -34.5 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 165 | mine_tick_2 | unit | battle | _poll_mining | -34.6 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 166 | skill_hit | unit | battle | _hook_champion, skill_hit -> _on_skill_hit | -27.7 | Reads as the action (hit / shot / death); 10 in a row don't sound like a machine gun; no boom. | | |
| 167 | spell_ember_step | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 168 | spell_kindle | spell | battle | spell_cast -> _on_spell_cast | -12.6 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 169 | spell_shadow_lance | spell | battle | spell_cast -> _on_spell_cast | -15.9 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 170 | spell_snow_shield_off | spell | battle | spell_cast -> _on_spell_cast, ability_started/ability_ended -> _on_path_ability | -16.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 171 | spell_snow_shield_on | spell | battle | spell_cast -> _on_spell_cast, ability_started/ability_ended -> _on_path_ability | -12.7 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 172 | spell_soul_siphon | spell | battle | spell_cast -> _on_spell_cast | -11.3 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 173 | spell_umbral_shroud | spell | battle | spell_cast -> _on_spell_cast | -12.0 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 174 | spell_vigor_off | spell | battle | spell_cast -> _on_spell_cast, ability_started/ability_ended -> _on_path_ability | -18.0 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 175 | spell_vigor_on | spell | battle | spell_cast -> _on_spell_cast, ability_started/ability_ended -> _on_path_ability | -14.8 | Faction flavour (fire crackle / shadow whoosh); rises above the fight; tail not longer than the VFX. | | |
| 176 | ui_click | ui | ui | pressed -> _on_button_pressed | -33.7 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 177 | ui_error | alert | battle | spend_failed/spend_failed -> _on_spend_failed | -13.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 178 | ui_helper_call | ui | ui | helper_called -> _on_helper_called | -18.4 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 179 | ui_hint | ui | ui | _poll_orders | -22.4 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 180 | ui_plus_start | ui | ui | _hook_orders, upgrade_started/upgrade_completed -> _on_plus | -23.0 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 181 | ui_restart | ui | ui | _start_music | -21.4 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 182 | ui_tab | ui | ui | _poll_selection | -28.1 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 183 | ui_tab_1 | ui | ui | _poll_selection | -28.5 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 184 | ui_tab_2 | ui | ui | _poll_selection | -27.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 185 | ui_tier_start | ui | ui | _poll_orders | -24.2 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 186 | ui_tier_tick | ui | ui | _poll_orders | -28.8 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 187 | ui_upgrade_cancel | ui | ui | _hook_orders, _poll_orders | -22.4 | Crisp, short, no low thump; same feel as the other UI cues; not tiring after 50 clicks. | | |
| 188 | unit_trained | alert | battle | _hook, unit_trained -> _on_unit_trained | -17.0 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
| 189 | victory | alert | battle | mission_ended -> _on_mission_ended | -8.7 | You notice it during the loudest fight without looking; meaning is obvious (good news vs danger). | | |
