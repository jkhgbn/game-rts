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

### Root-cause pass: saved plain-named metas
- Guard: `tests/test_save_metas.gd` (uncommitted until the renames land: it FAILS by design on 15 names). Scans
  `scripts/**/*.gd` `set_meta` names (literals, constants up the extends chain, Class.CONST); only `Unit` / `Building`
  metas are encoded (unit.gd:2494, building.gd:792). SAVE allowlist (truce, loot, plus, rank, mission_* ...) and an
  OFF_SAVE list (level node / UnitType stubs / UI controls) with reasons. Add to the CI core list once green.
- Renames (fix batch):
  - gameplay-coder: `t3_paused_until` (t3_kit:174, better: time left), `bowman_hamstring_at` / `bowman_hamstring_target`
    (bowman_kit:93-95), `t3_hush_bond_until` / `t3_maelis_bond_until` (helper_abilities:555/564).
  - systems-coder: `forge_sig` / `forge_range` (forge_kit:274/282, re-derive on load), `mission_truce_hook`
    (mission_base:952), `mission_held` (539; check a save during hold_world), `neutral_camp` (neutral_camp:284),
    `tracker_contract` (hunters_guild:214) — camp / guild must re-link their units on load.
  - ai-coder: `ai_casters_hits` (ai_casters:972), `contract` (tracker_contract:115).
  - lead: `game_audio` const META + `game_audio_crit` (game_audio:448, 910).

### V1: vfx, cinematics (16 files)
1. `cinematic_player.gd:97-103, 1446` + `pause_menu.gd:182-186` + `save_game.gd:182-229`: Ctrl+F12 during an in-mission
   film keeps the film playing over the loaded match (letterbox, voice, input eaten, saves refused, the loaded mission's
   intro film refused "Already playing", camera may stay). Fix: stop on the context's `tree_exiting` and / or refuse a
   load while a film plays. (high) game-breaking [save/load]
2. `cinematic_player.gd:493-494, 1446-1468` vs `skip()` 206-208: a film watched to the end doesn't apply the end state of
   actions still running (unit left mid-walk, despawned actor visible); skip does. Fix: run `_end_state` for `_running`
   in `_finish(false)`. (high)
3. `cinematic_player.gd:1213-1225, 1450, 240-246, 1294`: voice / SFX players never stopped on skip nor paused (804 voiced
   lines): actor keeps talking over gameplay / next film. Fix: track and stop / pause them. (high)
4. `cinematic_overlay.gd:251-272` + `cinematic_player.gd:816` subtitle / title timers run while paused; line not re-sent.
   (high, minor)
5. Untranslated player text: `trade_popups.gd:205, 216, 233, 247`, `route_line.gd:497-505`, `mapfill_popups.gd:41`. Fix:
   Loc.t whole sentences, extract, translate. (high, minor)
6. `mapfill_popups.gd:92` `_splash_at`, `champion_barks.gd:85` `_known` never pruned. (minor)
- Clean: skip runs the end state once; play_cutscene refusal paths; HUD / pause / camera / cursor restore; stage
  soft-lock guard; CinematicInput; Blitz not involved; Events access; no VFX leaks / crashes.

### U2: selection panel, command card, portrait, spell info, inventory bar, item tooltip
1. `command_card.gd:904-905` train button reason from the active building only; with 2 Barracks (active full) the button
   is grey and the click refused while Z trains in the other. Fix: reason from `sel.train_target(type)`. (high)
2. `spell_info.gd:147-156` `cast_reason` misses "Frozen" (buttons look ready on a frozen wizard). (high)
3. `spell_info.gd:171-183, 208-214` tooltip damage / cooldown from raw .tres (no spell power / CDR): disagrees with the
   real numbers and the sweep. (high, minor)
4. `command_card.gd:914-925` + `keep.gd:194-200` "Cancel Stronghold" stub shows "Cost 0 · Pop 0". (high, minor)
5. `inventory_bar.gd:193-211` right-click on a campaign_only item: silent no-op near a shop, drops it away from one.
   (medium, minor)
6. `selection_panel.gd:2601-2615` `_was_cooling` not reset when switching champion: false ready flash. (high, minor)
7. Loc misuse: selection_panel 1902 / 799 ("HP / XP %d / %d" without Loc.t), command_card 917 fragment, 914 / 994
   untranslated display names, spell_info 248 `n + "s"` plural and 208 concatenation, item_tooltip 176-178
   `active_id.capitalize()`. (high, minor)
8. `portrait.gd:131-134` portrait model keyed by type only (finished site / new keep tier keep the old model). (medium, minor)
- Clean: freed / dead handling order, own-only selection, `orderable_units()` filter, queue display = cancel(slot), site
  refund, sell value, physical hotkeys + KeyLabels, Numpad vs Alt+N, tier pulse, refresh rates.

### U1: selection manager, camera, build ghost, keys, groups, wizard control
1. `selection_manager.gd:2852-2871` (+2129) the wizard is pruned from control groups when she dies and never re-added
   after respawn (same node). Fix: keep the hero while valid. (high)
2. `selection_manager.gd:2206-2212` F2 "army" includes caravans (commandable): F2 + right-click sends them into fights /
   off their route. Fix: skip caravans. (high)
3. `selection_manager.gd:971` Shift-placing several buildings gives every worker each new site in turn: only the last is
   built, the others stay paid and unattended. Fix: give new sites to free / nearest workers or a build queue. (high)
4. `selection_manager.gd:2087-2125` Ctrl+N / Alt+N with nothing selected wipes the group. (high, minor)
5. `selection_manager.gd:2417-2453` aiming an item and clicking the minimap cancels it silently (no ORDER_ITEM branch).
   (high, minor)
6. `selection_manager.gd:2181-2182` double-tap on a mixed group centres between army and base. (high, minor)
7. `wizard_control.gd:58-79` hero swap during a held WASD key: the old hero walks forever. (medium, minor)
- Clean: physical keycodes everywhere (arrows / Home logical, fine), W A S D Q E F reserved in all schemes, group
  semantics (Alt before Ctrl), non-commandable units never ordered (`orderable_units()`), box / Tab / ghost / camera
  MapInfo bounds, no double input handling, perf.

### U3: champion bar, tavern, bounty mode, flag card, point panel, map-fill bar
1. `bounty_mode.gd:279-299` `pick_at` never picks a capture point (not in "buildings"): Guard on your own point is
   impossible from the UI (promised by point_panel hint and map-fill.md). Fix: `selection.point_at()` before the ground. (high)
2. `bounty_mode.gd:290-292` (via selection_manager 2466) picks fogged enemy units: leaks info, refuses the intended
   Explore. (medium)
3. Bounty raises made by bounty-mode clicks are not recorded in the replay (`raise_selected_bounty` does); doc comment
   10-11 wrong. (high, minor)
4. `bounty_mode.gd:285-289` + `bounty_board.gd:181-192` clicking a game critter places a 25-essence Explore flag on it
   (comment says it should be refused). (high, minor)
5. `tavern_window.gd:515-528` "Enemies hold both taverns" hidden while the player is also short of money. Fix: ask the
   guild. (high)
6. `flag_card.gd:189-191, 236-240` Claims shown as "EXPLORE BOUNTY / explored ground". (high, minor)
7. Ally seats treated as enemies in the UI: bounty_mode 291 / 730, flag_card 227, selection_manager 748 (PLAYER
   hard-coded), point_panel 319 / 387, MapfillBar `GameColors.relation` 979 (ALLY / ENEMY_2 points read "Neutral"). (high, minor)
8. `bounty_mode.gd:196` cross cursor stays after F9 / quit (no `_exit_tree`); selection_manager targeting modes same. (medium, minor)
9. Perf: tavern refresh 4 Hz compiles a RegEx per tooltip (`champion_bar.gd:812`) + StyleBoxFlat per row (988);
   ChampionBar.refresh 10 Hz rebuilds all tooltips (1463-1465). (high, minor)
- Clean: freed / dead guards, no orders to non-commandable units, all prices / refunds match the guild and board,
  button states, physical keys, Loc use, bars.

### U4: trade / shop windows, post panel, minimap, HUD, top bar, hints, tier chip, score, STR/INT, chat
1. `hud.gd:591-595` `show_banner` doesn't close the shop window: at match end it covers the banner / Score tab /
   Restart / Main menu buttons and eats their clicks. Fix: `shop_window.close()`. (high)
2. `minimap.gd:370-372, 393` zoomed view clamped with `size_max` on both axes: on 192 x 96 maps the view scrolls half off
   the map; GroundLayer (559-560) paints the whole square green. Fix: per-axis `half_x / half_z`, paint `bounds()`. (high)
3. Loc: `trade_window.gd:1179-1181, 1337-1338` English ware / contract names in Loc placeholders; `post_panel.gd:284-287,
   356-357` sentences built from fragments. (high, minor)
4. `top_bar.gd:210-221` repeated shake drifts the label up to 4 px. (medium, minor)
5. Perf: `shop_window.gd:750-781` 4 Hz refresh runs Recipes.plan + `nearest_shop()` (O(n²)) per item (~80 plans / 40
   building scans x 4 / s); `trade_window.gd:842` walks the global class list 4 / s. (medium, minor)
6. `tier_chip.gd:132` `is Keep` on a possibly freed keep (debug script error). (medium, minor)
7. `str_int_panel.gd:116-133` refusal reason dropped; ability names untranslated; hard-coded "J" label. (high, minor)
8. `chat_line.gd:189-198` vs shop / trade windows: Esc closes the window first, chat stays open. (medium, minor)
- Clean: trade rates / ware prices / x5, buttons from can_* reasons, null GoldBank, window exclusivity, physical keys,
  shop range / death close, sell ratio, post panel guards, minimap MapInfo click mapping + fog + redraw rates, HUD
  setup dedupe, score keys, STR/INT pause pairing, chat focus.

### C2: Ep1 missions (mission_00..04 + helpers)
Key fact: no Ep1 mission overrides `save_state` / `load_state` / `save_block_reason` nor sets `save_supported = false`:
F12 is allowed mid-mission but mission props are rebuilt fresh (braziers, Heartfrost, RootHeart, WardenGates, thorns,
M04Keystone, crown seal). `test_save_load_missions.gd` saves only 10-60 s in, so it never reaches these steps.
1. `mission_04.gd:787` / `m04_keystone.gd`: any save after the Rise soft-locks (pylons / Colossus not rebuilt; can't win).
   (high) soft-lock
2. `mission_03.gd:645, 1274`: save after E10 (barrier down): thorn colliders rebuilt, Signet unreachable. (high) soft-lock
3. `mission_03.gd:1479-1480`: save after E11: WardenGates closed again, `take_damage` ignored, obj_gates impossible.
   Fix: save / load rows like MissionE6Base. (high) soft-lock
4. `mission_01.gd:639-644`: save after the 3rd brazier but before E7: crown seal re-armed, refuses Vessa forever. (high) soft-lock
5. `mission_04.gd:870` `var p: Unit = keystone.pylons[i]` on a freed pylon: script error every strike call. (medium-high) crash-class
6. `mission_03.gd:1067 / 1202` `after(30, _fire_stake_raid.bind(s))` typed `stake: Building` freed before 30 s: script
   error, raid lost. (medium)
7. `mission_01.gd:490 / 628-631` Blaze Riders untrainable after a load past Westwatch (`_apply_hall_unlocks` not re-run). (high)
8. `mission_00/01` brazier state not saved: cold bowls next to 3/3; re-lighting re-fires lines / extra riders. (high)
9. `mission_00.gd:668-670` / `m00_cast.gd:155` Hush loses her kit after a load past A3; `sec_hush` never resolves. (medium)
10. `mission_02.gd:984-997` / heartfrost: Frozen Emberguard re-thaw exploit (+3 veterans each), Heartfrost HP not saved,
    post-E10 monolith stands again. (medium)
11. `mission_03.gd:1406-1414` Signet carry slowdown, stakes, Root Heart HP lost on load. (medium)
- Clean: win / lose double-fire guards, hero-death rules per spec, after() / waves after the end, cutscene end states
  with dead actors, Colossus death floor, scaled, no private calls / attack_target writes, node_added cleanup.
- Design option (lead / JS): block F12 at the risky mission steps (`save_block_reason`) where restoring props is costly,
  instead of saving every prop.

### U5: menus, mission UI, Wave Strike UI
1. `main_menu.gd:855-866` campaign list: 37 buttons x 44 px in a plain VBox (no ScrollContainer): missions after ~10th
   and Back / Watch / Start are off-screen at 900-1440 p. Fix: ScrollContainer with capped height. (high) game-breaking (menu)
2. `unit_guide_data.gd:135-142, 215-223` static stats cache: Blitz numbers (train time, worker HP) shown in normal games or
   the reverse. Fix: reset on open or on PaceSwitch apply / restore. (high)
3. `main_menu.gd:513-517` saved "Random 2v2" restored as "Random 1v1" (seat filter not saved). (high)
4. `spotlight_card.gd:118-122` + `unit_guide.gd:173-179` spotlight opens the reused guide in compare mode / with stale
   filters. (high)
5. `dialogue_box.gd:148-157` skipping the last voiced line leaves the voice playing. (high)
6. `pause_menu.gd:182-187, 227-234` Ctrl+F12 with Settings open: unsaved settings never written. (medium)
7. Wave Strike lobby (67-96) / HUD (79) text not rebuilt on language switch; map size line not via Loc.sink. (high, minor)
8. `unit_guide.gd:590` "/" shortcut uses logical KEY_SLASH: never fires on AZERTY. (medium, minor)
9. `unit_guide_data.gd:513-522` claim checker skips summaries (doc says it checks them). (high, minor)
- Outside: `chat_line.gd:87-91` BriefingScreen is a CanvasLayer, so `find_children(..., "Control")` never finds it (harmless
  while the tree is paused). (minor)
- Clean: MenuFlow start / restart / quit (paused reset, time_scale restored), random map resolution, settings apply /
  defaults, pause menu Esc order, briefing, objectives, Wave Strike keys, guide compare safety, voice manifest.

### C1: campaign framework (mission_base, campaign_state, story films, shared actors)
1. `mission_base.gd:1803` load_state + `SaveCodec.decode_metas` only ADDS metas: metas the rebuilt start sets
   (`mission_dormant`, `mission_locked`, truce) survive when the save lacks them. e3m2 dawn save: Vessa / Malrik stay
   dormant + immortal (HP-refill guard), base locked for good; truce metas set without `set_truce_id` -> `truce_count`
   wrong. Fix: load_state undoes META_DORMANT / META_LOCKED / TRUCE_META absent from the save, recounts truces. (high) game-breaking
2. `mission_base.gd:869, 1008, 1753` `set_player_hero` / `set_resources_hidden` not saved (`hero` is a main.gd var):
   e3m2 after dawn, `hero` points at a freed node (F1 / spells / loss rule). Fix: save hero save id + resources_hidden. (medium-high) game-breaking
3. `mission_base.gd:326` + `save_restorer.gd:26` no MissionHud after ANY mid-mission load (show_briefing false never
   reset): silent say(), no objectives panel, no spotlight. Fix: skip only the briefing while restoring. (high)
4. `mission_heartwood.gd:61` kindle state and `GlasswaterLake` floes have no save row: e2m1 load after kindle = Heartwood
   invulnerable, in truce, no aura. Fix: save_row / load_row like WardenGate. (medium-high)
5. `story_films.gd:23` + `menu_flow.gd:161` branched film (c_e6_gate_shut, c_e7_pits_pits) replays every menu start:
   is_seen checks the main id, only the alternate is marked. (high)
6. `mission_base.gd:1148-1233` seats (`_seats`, `_tagged_seats`, `_withdraw_watch`) not saved (latent: e7m4 blocks saves
   during the turn). (high, minor)
7. `mission_base.gd:529 / 1483` hold_world keeps units attacking; a pending win/lose(delay) freezes if a hold starts
   after it (latent: e8m3 only). (high, minor)
8. `mission_base.gd:259 / 1075` spotlight ring fires before `show_spotlight()` for "unlock" / "manual" triggers, and on
   a rebuilt unit after a load. (medium, minor)
9. `ember_crown.gd:110-113` wearer freed without `died` (leave_map, load) -> crown stuck invisible. (medium, latent)
- Clean: objectives, fire_once / E-list, after() + held time + load shift, lambda timers block saves, win / lose / _finish,
  play_cutscene end states, truce hooks, seat switch / withdraw / activate, lock_base bookkeeping, spawn / order waves,
  config knobs, CampaignState rewards / flags / FILM_BRANCHES / crash-safe save, CampaignItems round trip, StoryFilms
  chain, WardenGate and the other shared actors.

### C3: Ep2 missions (mission_e2_01..05)
Root cause for 1-3, 6: no e2 mission overrides save_state / load_state, so signal hookups, seat activation and kit
hookups made mid-mission are lost on load.
1. `mission_e2_02.gd:1583-1613, 2058` load after E14 (Nature seat): no ALLY seat_keeps / economy / Commander,
   `heartwood.destroyed` and `ysolde.died` lost, code-built groves dropped by SaveWorld -> the Vice never completes,
   Nature keep death never loses. (high) game-breaking
2. `mission_e2_04.gd:1121-1124, 1338` load after the forge claim with < 2 researches: `research_completed` not
   reconnected -> gate never opens; `keep.destroyed` and E10 also lost. (high) game-breaking
3. `mission_e2_05.gd:939, 1182` load after the wake: `boss.died` (only win path) / `damage_taken` lost; saved boss is
   ENEMY, rebuilt statue NEUTRAL -> respawned as a typeless Unit (`doorwarden` not in data/units). Killing it never wins.
   (high / medium) game-breaking
4. `mission_e2_01.gd:980` `after(t, _fire_wave.bind(id))` = custom Callable -> saving refused for most of the 10-13.5 min
   hold; after the last wave a load leaves the Heartwood invulnerable + in truce (kindle not re-applied). Same in e2m2 W6
   (1577) and VH hard (2044). Fix: named no-arg methods or one schedule tick. (high)
5. Mission-local UnitTypes (`wood_folk` e2m1:1179, `seed_carrier` e2m2:899, `splinter_acolyte` e2m4:925, `cinder_dragon`
   e2m5:405) respawn typeless on load (no `save_spawn_unit`, MissionE5Base has one) and lose their died handlers
   (sec_folk / sec_carriers counts). (high / medium)
6. `mission_e2_03.gd:898` `tollgate.destroyed` lost on load -> sec_toll never completes. (high, minor)
7. `mission_e2_05.gd:1383-1457` boss killed during B2 -> `obj_tether` left active on the victory screen. (medium, minor)
- Clean: first ending wins, no waves after victory, hero-death rules, after() during hold_world, difficulty scaling,
  clear-area checks, e2m4 helper revive, truce bookkeeping on withdraw, story units, no private calls / attack_target writes,
  objective texts match their conditions.
- Lead note: C1-1..4 + C2 + C3 + R/W save findings = one "mission save/load hardening" design: (a) framework fixes
  (meta strip on load, hero / resources_hidden / seats saved, HUD after load, actor save rows, `save_spawn_unit` for local
  types), (b) a per-mission `_after_load()` hook that re-runs hookups, (c) `save_block_reason` for steps too costly to restore.

### C4: Ep3 + Ep4 missions (mission_e3_01..04, mission_e4_01..04)
Same two framework roots as C1-1 / C3: (a) SaveWorld drops code-built types spawned mid-mission (`sexton`,
`grave_warden`, `meadow_folk`, `ysolde_grove`, `elder_treant`; no e3/e4 `save_spawn_unit`), (b) `decode_metas` only adds.
Not caught: `tests/test_save_load_missions.gd:38` skips every `mission_e4_*` and saves only 10-60 s in.
1. `mission_e3_03.gd:863-869` load after the Sexton rises: Sexton not rebuilt, `sexton_phase` stuck 1-2 -> 4 candles lit,
   no victory. (high) game-breaking
2. `mission_e4_01.gd:1384` load after any bell: villagers (`meadow_folk`) dropped, folk_saved reset, roused bells can't
   ring -> guaranteed defeat at nightfall; folk died hooks lost. (high) game-breaking
3. `mission_e4_04.gd:653, 566` woken Wallwarden comes back dormant + immortal (wardens_down never 2); Winterheart stays in
   TRUCE_ALL after `_try_open_heart` -> obj_wall stuck. Also Torvald truce after I2, e4_02 A1/A3 + Hush immortal, e3_02
   Vessa asleep. (medium-high) game-breaking
4. `mission_e3_02.gd:1161-1240` load in phase 2 (dawn, saves open ~100 s in): `_dawn()` not re-run -> hero = freed Hush,
   Malrik dormant / not hero, base locked, resources hidden, essence trickle off, sec_call hook lost. (high) game-breaking
5. `mission_e4_03.gd:1039-1046` grove hearts dropped (grove "grown" with null heart, never lost again);
   `mission_e4_04.gd:1099` Elder Treants vanish. (high)
6. MissionZone state not saved in `mission_e3_01.gd:648` / `mission_e4_01.gd:813` (e5_04 does it): standards / ford revert,
   ford cutscene replays. (high)
7. `mission_e4_01.gd:962, 1704` first horn call at 12:00, spec 6:00 (`_horn_call_left` starts 360 behind a time gate). (high)
8. `mission_e4_02.gd:712, 1204` first brook relief at 10:00, spec 5:00 (same pattern). (high)
9. `mission_e3_03.gd:631` per-Warden died lambdas (door_kills) lost on load (slows a gate only). (high, minor)
10. `mission_e4_03.gd:716` `add_event(&"frost_late")` added mid-mission, dropped on load. (high, minor)
- Clean: first ending wins, no waves after victory, after() during hold, hero-death rules, objective fail paths, e3_04
  assault bookkeeping, e4_03 grove machine, e4_04 sequence without a load, ally seat / truce at start, scaling, no private
  calls / attack_target writes.

### C5: Ep5 + Ep6 missions (mission_e5_base/01-04, mission_e6_base/01-04)
No crash / soft-lock. e5 / e6 already have save_spawn_unit and load_state, so fewer load gaps.
1. `mission_e6_04.gd:711, 383` Torvald (ally wizard) never respawns: `_on_torvald_died` never arms
   `_respawn_left[ALLY_SEAT]` (spec says he respawns; e5_04:866 / e2_02:1622 do it). (high)
2. `mission_e6_02.gd:192-205, 853` open Frostgate still `is_alive()` but ignores damage -> attackers freeze at the gap
   (exploit). Fix: is_alive false while open, or re-target. (medium-high)
3. `mission_e5_04.gd:884-888` load after 6:00: yards keep the start's truce (load_state never lifts it). (high)
4. `mission_e6_base.gd:146-158` + `mission_e5_base.gd:98` Warden Breakers lose x2 vs buildings and their scale after any
   load (`arm_enemy` not called from save_spawn_unit). Fix: e6 save_spawn_unit calls arm_enemy for ENEMY. (high)
5. `mission_e6_02.gd:1039` `enforce_max(&"ice_lodge", 2)` counts the pre-built lodge: 2 lodges, spec / message say 3. (high)
6. `mission_e6_02.gd:686-707` townsfolk escort each other (+20 % speed; spec: only Torvald's soldiers). (high, minor)
7. `mission_e5_02.gd:1115` `_drilled.clear()` on load leaves saved `mission:drill` modifiers on archers. (medium-high, minor)
8. `mission_e5_03.gd:163` "Seen!" hint says 6 s; real value 3 / 4 / 6 by difficulty. (high, minor)
9. `mission_e6_03.gd:790-794` load re-emits `lost` for lost gardens -> gardens_lost counted twice. (high, minor)
10. `mission_e6_04.gd:784` `_push = {}` on load drops Torvald's push / hold order. (medium, minor)
- Clean: first ending wins, PAUSE films, hero-death rules, Vessa yield e5m4, guard / dormant handling incl. after load,
  only named intro timers, all counters reachable, e5m1 / e5m3 / e6m1 save-load, scaling, no attack_target writes /
  private calls.

## Verify pass (adversarial, 2026-10-12)
- C1-C4: all CONFIRMED except C1-7 PLAUSIBLE; design + per-mission batches in `mission-save-hardening-2026-10-12.md`.
- R1-R5 + root-cause metas (43 rows): 33 CONFIRMED, 7 PLAUSIBLE, 3 REFUTED.
  - REFUTED: RC `neutral_camp` (value is a node, SKIPped; real issue W3-2), RC `tracker_contract` / `contract` (trackers
    not saved, values SKIPped): rename for hygiene only.
  - PLAUSIBLE: R3-6 (item_passives overwrites a mission death_guard), R3-10 (allied Saboteur swap), R1-3 (held hero can
    cast: design intent, kept as is), R1-7 (no cancel when the walk ends out of range), R5-2b (truce meta decoded
    without truce_count), R5-7 (EssenceBank double before in-tree), R4-6 (crystal hole until next rebake), RC
    `mission_held`.
  - New detail: R2-4 helper killers swallow champion purses; R2-6 counter triggers on ability / DoT hits; R2-7 `team ==`
    vs `_allies`; R3-8 `_above_half` stale after heals; R3-9 big-target tuple; R3-11 instance-id staggers (5 files);
    R3-12 private calls (`_is_flyer`, `_is_big`, `_point_of`); R3-13 Rime Bulwark pushes flyers, writes position;
    R1-2 allied wizard death not seen as a hero; R1-4 summon lifetime restarts on load; R1-5 status shortened;
    R1-6 "Not learned" before "Frozen"; R5-3 companion level lost on load; R5-4 consumable cooldowns kept on respawn;
    R5-5 item pickups not saved; R5-6 recall seal teleports after the seal is gone; R5-8 save file error unchecked
    before replacing; R5-9 reload re-applies menu settings over the saved match; R4-3 helper / stables stub queue rows
    dropped unrefunded on load; R4-4 caravan home / cargo lost; R4-5 seat switch keeps old Economy pop; R4-7 set_tier
    leaves `_up_to`.
- Owner note: `scripts/units/item_passives.gd` = gameplay-coder; `scripts/audio/game_audio.gd` = lead.
- W / V / U (66 rows): 52 CONFIRMED, 13 PLAUSIBLE, U2-8 mostly REFUTED (portrait uses the finished model; optional
  set_tier), W2-7 partly refuted (skirmish taverns flag saved; thieves / trade / tavern / post / cache flags not),
  U3-7 partly refuted (`selection_manager.gd:748` right; flag_card shows ally flags as ENEMY). New detail: W1-4 lost-cache
  timers / seeds repeat; W2-2 bounty kinds use `team ==`; W2-3 revive timer, W2-4 hires_made, W2-5 `_pending` not
  saved; W2-6 load re-kills fallen champions (re-fires died); W2-8 hire spends crystals before essence; W3-3 Wave Strike
  rank lost on load; W3-5 shrine waves all wake on load; W3-6 `FogOfWar._layer` private call; V1-2..4 film end state /
  voice / paused overlay; V1-5 trade / mapfill popups untranslated; V1-6 popup dicts never pruned; U1-4..U1-7, U2-2..U2-7,
  U3-2..U3-9, U4-3..U4-8 (see verify table in the session; batches in `fix-batches-2026-10-12.md`).

### C6: Ep7 + Ep8 missions (mission_e7_*, mission_e8_*)
1. `mission_e7_base.gd:856`, `mission_e7_01.gd:517` load_state sets `auction = {}` over the restored one, no bid panel; the
   `A%d` event is fired -> auction never hammered, e7m1 never ends (same for e7m4 Sunwake, minor). Fix: keep auction +
   rebuild panel, or block saves while `auction_open()`. (high) game-breaking
2. `mission_e7_04.gd:688, 1057` "Pay {dragon} home" panel not rebuilt on load in phase 4 -> sec_dragons impossible. (high)
3. `mission_e8_01_shadow.gd:175` Stone's Gift panel built only in the intro end -> gone after any load. (high)
4. `mission_e7_04.gd:351, 1073` Seraphine keeps truce "all" + dormant after a phase-4 load (decode_metas add-only; F1
   reconcile); e8m1_shadow Hush same if saved in her fight. (medium-high)
5. `mission_e7_03.gd:1008` load clears `_gangs`: restored press-gangs park on a Dock Bell forever (foe_near counts
   NEUTRAL in truce) -> obj_bells impossible. (medium)
6. Difficulty / wound modifiers not saved (`e7_difficulty`, `wounded`: no `mission:` prefix): e7m1 Seraphine (693/695),
   e7m2 Dacian (514), e7m3 Mask Captain (746); e8m1_ice refugee type HP set only in `_spawn_column` (276). (high)
7. `mission_e7_base.gd:503` bound dragons (team changed) respawn without the "rest at 15 %" death guard -> can die for
   good; e7m4 `pay_home` then refuses. Fix: re-install the guard for every `dragons` entry on load. (medium-high)
8. `mission_e7_03.gd:835-843` masks attack-move to `Vector3.INF` when every row is rung / taken. Fix: KEEP_POS. (medium)
9. `mission_e7_04.gd:318, 646` Malrik's ally Commander re-enabled after a phase-4 load (C1-6). (medium, minor)
10. `mission_e8_01_shadow.gd:139` reads `e3m3_stone_used`, Ep3 writes `shadow_stone_uses` -> "+2 Shades" never applies. (high, minor)
11. `mission_e7_03.gd:421` briefing says "Do not lose 30", real limit 34 / 30 / 26 by difficulty. (high, minor)
12. Visual state not rebuilt on load: e7m4 crimson galleys visible, e7m2 opened strongboxes, e8m1_ice gate block, e8m2
    lit keyhole pillars / hand prop. (high, minor)
- Clean: first ending wins, wizard death rules, Ep8 FILM_BRANCHES / STORY_SCREENS / E8Lines, no private calls /
  attack_target writes, save blocks around e7m2 Laurel, e7m4 turn, road / e8m2 / e8m3 endings, e8m2 / e8m3 can't stall,
  e8m1 Heartwood regrow, Ep8 Warden Gates saved via MissionE6Base.
- Not separately verified: the mission fix batches re-check each C6 item before fixing.

### Verify C5
42 / 46 C1-C5 confirmed, 4 plausible (C1-7, C5-6, C5-10, C1-4 floes), none refuted. C1-6 narrower but real (e7m4 phase
4 saves open). Extra: X1 a unit dormant in the save but rebuilt awake gets the meta without `_sleep`; X2 e2m4 Ashby code
type. Design additions: post-spawn hook `save_spawned(u, row)` (C5-4 class), actor `load_row` must be quiet (C5-9),
phase transitions split into one-shot `_enter_X()` and idempotent `_apply_X()`; `_after_load` calls `_apply_X` for
every reached phase.
