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

### W3: map fill, river, Wave Strike
1. `epic_beasts.gd:243-248, 436` + `save_world.gd:304-306, 361-382` beasts duplicated after a load (saved beasts come
   back as plain NEUTRAL units without brain / group; then all 8 lairs spawn again): up to 16, towers shoot the orphans.
   Fix: EpicBeasts load hook (adopt by type + lair, restore spawns / next_at). (high)
2. `neutral_camp.gd:256-270` late camps (Gloomcap 2:30, Stag 3:30) duplicated after a load; `camp_level` lost for all.
   Fix: save camp level / alive / respawn; re-attach creature rows. (high)
3. `wave_strike_level.gd:354-359, 652-663` + `save_world.gd:150 / 181` Wave Strike lane units rebuilt at rank 1 (rosters
   restored after units); `ws_rank` modifier not saved. (high)
4. Wave Strike `LaneSpawner._queue` and Last Horns bastion armour not saved. (high, minor)
5. `capture_points.gd:523-548` all shrines wake in a burst after a load (`_shrine_wave` = 0 vs restored clock). (high, minor)
6. Contract: `capture_points.gd:182, 193, 229, 251, 326` call private `FogOfWar._layer(team)`. (minor)
7. `capture_points.gd:287-299` presence cached 1 s vs 4 Hz progress (capture moves up to 1 s after units leave). (medium, minor)
- Clean: river math / ford modifier / amphibious, capture rules / blessing, camp rewards / underdog / respawn, beasts 1 per
  lair, critters, Wave Strike horns / income / roster refunds / pop / tiers / lane units / bastion end, no attack_target writes.

### Theme so far: save / load of a skirmish is the weakest area (R2-2, R3-3, R4-1/3/4, R5-1/2/3/5, R1-4, W3-1..5, meta
class). One owner pass ("save/load hardening", systems-coder + lead for scripts/core) rather than scattered fixes.

### W2: guilds, trade, bounties
1. `bounty_board.gd` (place 217 / raise 314): active bounties never saved: stakes lost on load (no refund), pursuers /
   GUARD ticks lost. Fix: save / rebuild, or refund `unpaid()` into the saved essence. (high) [save/load]
2. `bounty_board.gd:185-191` `kind_for` compares raw team ids: in missions with an ALLY seat (team 3: e2_02, e2_05, e3_01,
   e3_02, e3_04, e4_01, e4_04, e6_04, e7_01, e7_04) R on the ally places a HUNT flag (75+ essence locked; champions may
   be paid for an ally's death); ally can't get ESCORT / GUARD. Fix: `Teams.is_ally` / `is_hostile`. (high)
3. `champion_guild.gd:416-417` revive in progress (`reviving` / `revive_left`) not saved: paid revive lost on load. (high) [save/load]
4. `champion_guild.gd:107, 191` `hires_made` not saved: mission 3's free first hire is free again after a load
   (mission_03.gd:674). (medium-high) [save/load]
5. `champion_guild.gd:120, 255` hire waiting at the tavern door (3 s `_pending`) lost on load with its payment. (minor) [save/load]
6. `save_world.gd:409-410` loading a fallen champion re-runs the death path (`died`, `Events.unit_died`, "X has fallen",
   "X joins you"): death counters +1 per load. Fix: restore as already fallen. (medium, minor) [save/load]
7. Announcements / timers restart after a load (tavern `_open`, trade_network announced flags, thieves_guild `_announced`,
   lost_cache `_wait_left`, skirmish `_taverns_announced`). Fix: seed from `match_time()`. (medium, minor) [save/load]
8. `champion_guild.gd:244-249` hire spends crystals / gold before essence: partial charge if essence fails (not reachable
   today). (medium, minor)
- Clean: hire / revive / dismiss costs, max 3 / pop 2, taverns 2:00, bounty raise / refund / ticks, Magpie timing (no pay
  API), Hunters' Guild, trade ledger, loot sacks, no private calls / attack_target writes.

### Lead decisions during the review
- R4-2 follow-up: new public `Unit.set_down(pos)` (gameplay-coder) resetting `_last_nav_target` / `_anchor`; BuildGrid
  uses it instead of writing `global_position` (TODO(set_down) left there). CLAUDE.md Unit contract gets the line.

### W1: skirmish, levels, fog, pace
1. `skirmish.gd:1614-1619, 1651-1655` (+ `respawn_point` 633-641): the respawn timer is erased before `_respawn_wizard`;
   if every keep / Hall died during the timer (side alive through towers / houses), the wizard never comes back, even
   after a new Hall. Fix: keep the team in `_respawn_left` and retry while the point is INF. (high) near game-breaking
2. `skirmish.gd:1879-1898` + `score_keeper.gd:80-124`: score not saved; after a load most counted stats restart at 0, the
   time-limit end can pick the wrong winner; restored essence counted as "gained"; history burst (one point / frame up to
   now). Fix: ScoreKeeper save / load state. (high) [save/load]
3. `menu_flow.gd:259-268` (ui-coder) + main.gd:208 + save_game.gd:190-230: F9 after loading a save from the menu replays
   the scene defaults (`_enemy_chosen` never set) and current settings (pace / trade / time limit) instead of the save's.
   (high) — same as R5-9 [save/load]
4. Lost Caches not saved (`lost_cache.gd:22-45`): save / load re-arms all 4 and replays the same loot rolls. (high, minor) [save/load]
5. = part of 2 (history burst). 
6. `env_props.gd:14, 57-61` 16 road slots: Kinhearth Vale's 28 segments get cut (map not ready yet). (high, minor, latent)
- Clean: win / loss rules, double end, concede, time-limit end, one respawn timer per team, PaceSwitch symmetry and
  Engine.time_scale restore, Fireball edit restore, MapInfo / Teams release, CasterKit reset, layout_error gating, bot
  points, fog layers, map catalog, forest.
