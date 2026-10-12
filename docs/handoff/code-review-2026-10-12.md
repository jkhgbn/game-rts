# Whole-project code review 2026-10-12 (JS: "review all the code in the project")

Read-only reviewers (Opus medium), one area each; `scripts/ai/` was reviewed earlier the same day
(`bot-review-2026-10-12.md`). Findings below are the reviewers' claims until the verify pass marks them.
Fixes go through the owners after the playtest chain (balance re-check -> tag -> nightly CI -> play5), unless a finding is
a crash or game-breaking: those are fixed before the tag.

## Waves
- Wave 1: R1 unit.gd / wizards / spells, R2 champions / helpers / creatures, R3 rest of scripts/units, R4 buildings +
  economy, R5 items + core + audio.
- Wave 2 (planned): world (2), ui (5), campaign / missions (8), vfx + cinematics (1). Tools (`tools/`, ~55k lines): ask JS.

## Findings

### R3: rest of scripts/units (19 files)
1. `new_units_12.gd:298-308` Wither Hex never ends in Blitz: `until` stamped with a frame-count clock, timer on scaled game
   time (time_scale 1.3) -> -20 % attack forever. Fix: remove on the timer unless refreshed (cast serial). (high) **before tag**
2. `support_caster.gd:72-74` + `unit.gd:919-924` Rime Seer shield replaces larger shields (Snow Shield, Vow, Rime Aegis,
   items) and ends Snow Shield early. Fix: skip targets with `shield >= amount`. (high)
3. `save_world.gd:116-128` saves don't keep Stables16 rank-3 / BowmanUpgrades research nor `rank3` / `bowman:*` modifiers
   (not in `SAVE_MODIFIER_PREFIXES`, unit.gd:2462); in-progress research loses its crystals. Fix: save_state / load_state. (high)
4. `t3_unit_ability.gd:218-228` Powder Charge never explodes if the Saboteur dies in the 5 s fuse (lambda bound to the
   freed node). Fix: static fuse with weakrefs or a level-owned node. (high)
5. `t3_kit.gd:311-334` Genie hire timer (SceneTreeTimer) survives F9 / quit to menu: free Genie next match, pop eaten, a
   Genie in the menu scene. Fix: roster-owned Timer or match serial check. (medium-high)
6. `item_passives.gd:281` `_refresh` overwrites `wizard.death_guard` (mission guards, e.g. mission_e7_02.gd:562 duel).
   Fix: only set when empty / ours, only clear when ours. (medium)
7. Frame-count clocks (`CasterKit.now_s`, `T3Kit._now`, `BowmanKit._now`) ignore Blitz speed and run while paused:
   Scrying Rune reveal vs marker drift, Powder Charge pause, Seedcloak cd, Stoke window, Hamstring glow. Fix: one
   pausable scaled match clock. (medium)
8. `caster_ability.gd:658-670` Seedcloak misses after a heal (`_above_half` only updated on damage). (medium-high, minor)
9. `t3_unit_ability.gd:403` Tempest Bolt priority: non-big unit with more max HP replaces a titan / hero. (high, minor)
10. `t3_unit_ability.gd:164` allied Saboteur shown disguised in 2v2 (only team 0 returns). (medium, minor)
11. instance-id tick staggers (t3_unit_ability.gd:48, new_units_12.gd:197, helper.gd:93) break replay determinism. (minor)
12. private calls across files: `HelperAbilities._is_flyer` (caster_ability 1069, caster_haze 77, t3_unit_ability 375/389),
    `CasterAbility._point_of` (caster_kit 494/529). (contract, minor)
13. `rime_bulwark.gd:167-177` pushes flyers out (they never collide with layer 3). (high, minor)
- Clean: CasterKit claims, cast interrupts, mana math, autocast exits, Bulwark melt, modifiers on timeout, projectile
  guards, no `attack_target` writes, Stables refund, StrIntPath save.

### R2: champions, helpers, creatures
1. `helper_abilities.gd:533-539` Glasswater Ward heals inside `take_damage`'s gap (hp <= 0 before the death check): a
   killing hit with overkill < 12 % is survived. Fix: return when `u.hp <= 0` (or defer). (high)
2. `helper_roster.gd:28-41` + `save_world.gd:38-40, 371-375` HelperRoster state not saved: after a load a second helper
   can be called, the restored one can't be revived (`died` not connected), its 4 pop not reserved, stance lost. Fix:
   roster `adopt(helper)` + save stance (lead + gameplay-coder). (high)
3. `helper_abilities.gd:614-618` Mother Hush Smoke / Night of Knives `command_stop()` enemies targeting her: wipes the
   player's / bot's attack-move orders. Fix: drop only the target (Unit API), never `command_stop`. (high)
4. `champion.gd:559-561` champion purse drop goes to a Helper killer (Helper extends Champion) and is lost. Fix: skip
   when killer is in "helpers" so the EssenceBank gets it. (high)
5. `helper_abilities.gd` 328 / 375 / 410 / 466 helper teleports and Stampede push ignore navmesh / water / footprints.
   Fix: `_on_navmesh` / `_safe_end` style snap, `Unit.displace()` for the push. (medium)
6. `champion_abilities.gd:998-1011` Riposte counters non-melee hits (Shield Throw, Lunge, Whirlwind, DoT ticks). (high, minor)
7. `champion_abilities.gd:884` vs 1256 / 1509 Soothing Circle counts allied seats but heals only own team. (high, minor)
- Contract: `champion_abilities.gd:874` Smoke Pouch writes `u.attack_target = null` on enemies (needs a Unit API).
- Clean: XP table, class / ability / helper / spell ids, modifiers, respawn, save round trip, truce in AoEs, credit_kill,
  roster essence flow, creature dashes, Blitz independence.

### R1: unit.gd, wizards, spells
1. `unit.gd:381-391` + `568-571`, trigger `inventory.gd:318-332` swap / `663-690`: moving a max_hp item between slots (or
   drop + pick up) heals the gain every time (exploit, 18 items). Fix: no heal when a modifier only moves. (high)
2. `unit.gd:1111-1116` `kill_xp_value`: 2v2 allied bot wizard (group "ally_heroes" only) gives 0 XP / no credit_kill.
   Fix: `victim is Wizard`. (high)
3. `spell_caster.gd:190-204` a held hero (rooted + `set_cast_lock`, missions e3_03:821 / e3_04:1179) can still cast F/Q/E.
   Fix: refuse while `cast_lock_left() > 0` or a mission gate. (medium, design intent)
4. `unit.gd:2466-2522` / 317 summons' lifetime not saved: full lifetime back after every load. (high, minor)
5. `unit.gd:605-606` re-applying a status overwrites (can shorten: Flash Freeze 3 s chill -> 2 s). Fix: maxf. (medium, minor)
6. `wizard.gd:445-446` "Not learned" before "Frozen" (contract order); duplicate of SpellCaster.can_cast. (high, minor)
7. `spell_caster.gd:285-323` walk-then-cast to an unreachable in-range point waits forever. Fix: cancel when the move
   ended out of range. (medium, minor)
8. `shadow_wizard.gd:114-118` `shadow_lance_cast` emitted for a pending walk that may be cancelled. (high, minor)
9. Contract: `champion_abilities.gd:830, 874` direct `attack_target` writes; `HelperAbilities._is_flyer / _is_big` called
   from unit.gd:296/312 and others. (minor)
- Clean: XP / veterancy arrays, status symmetry, auras, DoTs, shields, death_guard, respawn resets, mana / cd math, target
  validity, Blitz spell factor (projectiles / zones / deal_damage), Events access, signal guards, save of level / ranks / items.

### R5: items, core, audio
1. `save_codec.gd:105` `encode_metas` saves absolute-time metas (`t3_paused_until`, `nu12_withered_until`,
   `bowman_hamstring_at`, helper bond timers) measured from process start: after a relaunch + load a Powder-Charged barracks
   stays paused ~29 min, archers can't Hamstring. Fix: deny-list / `_` prefix / remaining-time metas. (high) game-breaking
   after load
2. `game_audio.gd:43, 446-448` marker meta `game_audio` (no `_`) is saved, so units / buildings rebuilt by a load are never
   hooked: no sounds for them. Same class: `mission_base.gd:952` `mission_truce_hook` restored without its
   `tree_exiting` connection (truce_count never cleared). Fix: `_game_audio`, `_mission_truce_hook`. (high)
3. `save_world.gd:290, 314, 398-404` campaign companion champion loses level / XP / class / items / purse on load (the
   fresh level-1 one spawned by `apply_to_start` stays; saved row dropped). Fix: match rows to the roster by archetype.
   (medium-high)
4. `inventory.gd:311` `reset_consumable_cooldowns()` never called: consumable cooldowns survive respawn (items.md 153).
   (high)
5. Ground items (`item_pickups`) not saved. (high, minor)
6. `item_actives.gd:514-527` Homeward Seal: dropping / selling it mid-channel still teleports, no charge used. (high, minor)
7. `essence_bank.gd:42-47` `for_team` can create two banks before the scene is in the tree (groups register only in
   tree); `save_world.gd:206` restores essence only into existing banks. (medium, latent)
8. `save_game.gd:127-135` `write_file` never checks `get_error()`: on a full disk "Game saved", old save deleted,
   truncated file renamed over it. (medium) — we hit disk-full twice this week
9. `menu_flow.gd:264-266` + `save_game.gd:218-221` F9 / Restart after a load uses the menu's settings (trade, time limit,
   pace) not the loaded match's. (medium, minor)
- Clean: item modifiers re-applied everywhere, buy / combine / refund / tithe, recipes, sell value, shop range, actives,
  income, save versioning / codec / phases, MapInfo / Teams release, Loc, GameSettings, MenuFlow, PlaytestRecorder, audio pools.

### R4: buildings, economy
1. `forge_kit.gd:271-282` Forge upgrades vanish from loaded soldiers: metas `forge_sig` / `forge_range` are saved (no `_`)
   but the `forge` modifier / range are not, so `apply_to` skips them. Fix: `_forge_sig` / `_forge_range` or check
   `has_modifier`. (high) — same bug class as R5-2 (saved marker metas)
2. `build_grid.gd:455-470` `_push_units_out` calls `command_move` on own / allied units in a new footprint: workers stop
   gathering for good, caravans stop trading; also orders non-commandable units and the ally's. Fix: displace (no order
   change) / re-issue gather or trade; skip non-commandable. (high) **before tag**
3. `training_building.gd:363-374` queued helper Call / Revive stubs dropped on load (not .tres), crystals + essence lost.
   (medium-high)
4. `caravan.gd:295-306` after a load, player caravans > 12 m from their Bazaar idle forever, cargo lost. (medium-high)
5. `building.gd:497-500`, `worker.gd:282-285`, `economy.gd:129-141` cached `_economy` / pop by team not refreshed after
   `switch_seat_side` (e7m4): income, spend, house pop, unit pop on the old side. (medium)
6. `crystal_node.gd:134-141` depleted node leaves a navmesh hole (no rebake): "Not on walkable ground" there. (medium-high, minor)
7. `keep.gd:47-54` vs `tier_system.gd:231-238` `set_tier` during an upgrade: the upgrade later lowers the tier. (tests /
   cheats only, minor)
- Clean: training queue pop / refunds, construction 75 % refund, builders, tier refunds / signals, drop-off rules, miner
  slots, economy symmetry, house pop, wares, UnitUpgrades refund, BuildGrid occupancy / rebake on destroy.

### Recurring class across R4-1, R5-1, R5-2: non-`_` metas saved by `SaveCodec.encode_metas` (markers, absolute times).
Root-cause pass wanted: a rule / test that flags metas set from code that are saved but not meant to be.
