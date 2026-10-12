# Bot code review 2026-10-12 (JS: "review all game bot program and look for possible error")

4 read-only reviewers (Opus medium) over `scripts/ai/` (~15k lines). Findings are the reviewers' claims, NOT yet verified.
Next: verify pass, then fixes through the owners (ai-coder for scripts/ai; systems-coder / lead where noted).

## D: trade, Magpies, trackers, Wave Strike bot
1. `ai_trade.gd:531-541` + `is_unsafe` 506-512 — route to a post "Held by the enemy" is never treated as unsafe; a lone
   enemy (<150 strength) at the door makes every caravan wait 45 s and come back empty forever. Fix: `route_reason ==
   MSG_HELD` counts as unsafe; the alternative near post must have `route_reason == ""`. (medium-high)
2. `scripts/core/save_world.gd:67-79` + no save hooks in thieves_guild / hunters_guild / thief_band / tracker_contract —
   after F12 / Ctrl+F12 Magpies and trackers come back as orphans (bands / contracts not saved), `magpies_alive()` stays at
   MAX_ALIVE so no new band ever leaves. Fix: drop them on load (loot back as LootSacks) or save the bands / contracts.
   Owners: lead (core) + systems-coder (world). (medium)
3. `thief_band.gd:439-457`, sack runs 1020-1035 — `fleeing` has no time cap; a Magpie that can't reach the door within 3 m
   keeps the band alive forever and throttles later bands. Fix: flee timeout ~60 s then `leave_map()`. (medium)
4. `thief_band.gd:790`, 822-830 — fleeing band picks its Den by straight line, not `guild.nearest_den_door` (navmesh);
   long detours across the river. (medium)
5. `wave_bot.gd:74-81` — compares tier schedule with `horn_index + 1` while `MusterRoster.can_upgrade()` checks
   `horn_index`; Steward "saves" for an upgrade not yet allowed and buys no cards that horn (horn 6 and 14). (high)

## B: champions
1. `champion_brain.gd:1480` `_nearest_shop` (R7 1413, R2 668) — champions walk to Ruin Peddlers that can't sell their
   next wish (first wishes are base-only), buy nothing, repeat every 60 s; purse piles up. Fix: only shops that sell the
   next wish, else nearest own base shop. (high)
2. `champion_brain.gd:317-321` `choose_flag` hysteresis — a L1-3 champion keeps a Hunt flag whose utility dropped to 0
   (target under an enemy tower) and dies in tower fire. Fix: drop a current flag with utility 0. (high)
3. `ai_champions.gd:241-260` `chosen_tavern`, `_hire` 338-341, `plan()` 141-161 — bot picks the nearest tavern even when
   held, refuses to hire, but `plan()` still reserves price + 150 crystals and 2 pop and blocks wizard items. Fix: nearest
   free tavern; `plan()` returns 0 when none is free. (high)
4. `champion_brain.gd:107`, 462 `MAP_LIMIT := 56.0` — ignores MapInfo; on 176 m maps no exploring past ±56, on 192x96 it
   picks points off the map. Fix: `MapInfo.contains` / `half_x` / `half_z`. (high)
5. `ai_champions.gd:412` — any Guard flag (B7 forward hall, B10 well, up to 180 s) blocks the base-defence Guard flag B1.
   Fix: track B1's own flag. (high)
6. `champion_brain.gd:786-825` + `champion_sense.gd:472-503` — fight target can be an uninvolved NEUTRAL camp creature;
   pulls camps. Fix: only attackers or non-neutral candidates. (medium)
7. `champion_brain.gd:880-896` `_mender_keep_distance` — no distance cap on the anchor (walks across the map) and with no
   soldier it backs off forever; each `command_move` cancels its auto-attack. Fix: cap ~15 m, stop moving once at range.
   (medium)
8. `champion_sense.gd:480-482` — ignores mission truces: truce units counted as enemies / danger / Hunt targets; champion
   shows "Fighting" and re-sends a refused order every 0.5 s. Fix: skip `not champion.is_enemy_of(u)`. (medium)
- Clean: ability ids, Bounty kinds, dismiss / revive, purse / tithe math, `ai_items.gd`.

## C: casters, map fill, beasts, wizard casts
1. `ai_casters.gd:1081-1085` hard dive — fast units get an unleashed `command_attack(best)`; `commander.gd:3489` never
   re-orders a unit with an `attack_target`, so divers chase a retreating caster into enemy towers; the loop also takes
   the scout and capture-squad members. Fix: `set_auto_target`, or drop the dive past ~1.5 x DIVE_RADIUS; skip scout /
   `mapfill_ai.is_busy` units. (high)
2. `ai_mapfill.gd:904-919` `_shrine_due` (used 626-638) — never checks `_given_up()`; a squad that gave up a shrine is sent
   straight back (or the wizard is), GIVE_UP_COOLDOWN never applies to shrines. Fix: skip `_given_up(p)`. (high)
3. `ai_mapfill.gd:562-573`, 1229-1257 + `commander.gd:1242-1243` — `current_creep` not cleared when the creep group is
   wiped (`_end_attack("group lost")` -> `_clear_group()` never calls `note_creep_end`); AIChampions keeps placing Hunt
   bounties (B11 / B9) on the beast that just won. Fix: `note_creep_end` in `_end_attack` when stage == CREEP. (high)
4. `ai_casters.gd:399`, 744-746, 850-856 `_with_creeps` — every neutral within 20 m joins the cast / fight candidates; a
   caster throws Slag Rain on a camp the army only walks past and aggroes it. Fix: neutrals only while stage is CREEP /
   CAMP and only the current target, or only neutrals already fighting the bot. (medium)
5. `ai_casters.gd:902-921` Rimecarver retreat cover — caster goes to the rally first, wall spot is out of range 10, cast
   fails "Out of range" every tick. Fix: keep within ~8 m of the last member or use `order_cast`. (medium, minor)
6. `ai_casters.gd:814-845` Snagroot pick skips the `_engaged` check (header rule); pulls camp creatures. Fix: add
   `or not _engaged(e, soldiers)` at 830. (high, minor)
7. `ai_casters.gd:322` `_find_training_keep` uses `k.tier >= 2`; without a TierSystem `Keep.tier` stays 1 while
   `TierSystem.tier_of` returns 3, so the bot never trains casters there (human can). Fix: `TierSystem.tier_of(team) >= 2`.
   (medium, minor)
- Clean: `ai_casts.gd`, `beast_brain.gd`.

## A: Commander
1. `commander.gd:1813` (+1531-1533, 1588-1594) — one unbuilt site blocks `_next_row()`; `_maintain_sites` won't send a
   builder while `_path_camp(site)` (strong camp near the walk); X1 trigger lacks the `_path_camp(mid)` check X2 has
   (:1600); `_blocking_camp_target` (:3349) only clears the natural camp after X1. Bot never builds again, pop-capped.
   Fix: `_path_camp` check on X1; cancel / skip an empty blocked site. (medium)
2. `commander.gd:2440-2452`, `_next_hunt` 2514-2529 — Stage.HUNT has no timeout; an explore point in water / forest /
   cliff on a LayoutLevel is never reached within 8 m, army waits forever, rule 7 never relaunches. Fix: HUNT timeout ->
   `_next_hunt`. (medium)
3. `commander.gd:666` `_adopt_buildings` skips rows with `pos == Vector3.INF` (= X1); after a quickload the natural Hall
   isn't adopted, `_x1_done()` false, bot builds a second Hall; `attacks_launched` also resets. Fix: drop the INF skip.
   (high)
4. `commander.gd:889-897` (+2230-2235, 3427) — `all_in` only resets via the trade-gold branch; with crystals from a beast
   reward / refund the economy never restarts and `_check_concede` can concede while able to train. Fix: off whenever
   `not _out_of_crystals() and _node_left()`. (medium)
5. `commander.gd:1242-1244` — same as C3 (found independently): "group lost" in CREEP skips `note_creep_end` and
   `_creep_retry_at`; next army sent straight back. Fix: both before `_end_attack`. (high)
6. `commander.gd:3303`, 3308 — sorties use constant RESERVE 2, not `ai.attack_reserve` (Blitz Ice = 1). (high, minor)
7. `commander.gd:2034-2043` — fog-less scout path has no leg timeout; scout stuck at an enemy Hall spot forever. Fix:
   SCOUT_LEG_TIME there too. (medium, minor; only without fog)
- Clean: no direct `attack_target` writes, no `_private` calls, non-commandable units not ordered, ids, `data/ai` profiles,
  AIStrInt.

## Verification B + D (adversarial, read-only)
| ID | Verdict | Fix (corrected where noted) | Owner | Test to extend |
|---|---|---|---|---|
| D1 | CONFIRMED (one parked enemy unit empties the near route) | in `_routes`: default unsafe when `route_reason == MSG_HELD`; other near post only if `route_reason == ""` and not unsafe | ai-coder | test_10_a3 |
| D2 | CONFIRMED (human F12 in skirmish) | lead: `SaveWorld.capture` skips groups "magpies" / "trackers" (optional: Magpie loot -> LootSack row) | lead | test_save_load |
| D3 | PLAUSIBLE (low; door blocked) | flee cap ~90 s of `_state_time` (60 s too short on 176 m maps), then `_leave(u)` for each thief | ai-coder | test_10_a1 |
| D4 | PLAUSIBLE (longer walk, no stall) | `guild.nearest_den_door(_centroid())` when valid / finite, else `_nearest_door` | ai-coder | test_10_a1 |
| D5 | REJECTED as a bug | saving at horn 6 is what pays the Stronghold at horn 7 (first legal); the reviewer's fix would delay it to horn 8. Optional: keep only `next_tier_price - income` as reserve | — | test_ws_director |
| B1 | CONFIRMED (every Crown Hollow match: peddlers 10 m from taverns) | `_nearest_shop` skips peddlers / neutral shops unless the next wish is buyable there; else null | ai-coder | test_9_c5 |
| B2 | CONFIRMED | `if cur_u <= 0: return best if best_u >= threshold() else null` before the hysteresis | ai-coder | test_9_c5 |
| B3 | CONFIRMED | drop the `chosen_tavern` held check (the guild picks a free tavern); `plan()` clears `hire_due` when every tavern is held | ai-coder | test_9_c9 |
| B4 | CONFIRMED (Ashwind Reach, Quartermeet) | `if not MapInfo.contains(p, 4.0): continue` | ai-coder | test_9_c5 |
| B5 | CONFIRMED (hard profiles) | track B1's own `_defend_flag` instead of `_has_kind(GUARD)` | ai-coder | test_9_c9 |
| B6 | PLAUSIBLE (fight within ~14 m of a camp) | skip NEUTRAL entries unless they target an own unit / building or are in `attackers` (keep test_12_a2 part 1 behaviour) | ai-coder | test_12_a2 |
| B7 | CONFIRMED | anchor only within ~15 m; else point = `enemy + dir(me-enemy) * (attack_range-1)`; once there, `_order_attack(_fight_target)` (not "stop moving") | ai-coder | test_11_a1 |
| B8 | PLAUSIBLE (campaign) | sense skips `truce_count > 0` and TRUCE_ALL meta units; `_order_attack` guards `is_enemy_of(t)` | ai-coder | test_9_c5 |

## Verification A + C (adversarial, read-only)
| ID | Verdict | Fix (corrected where noted) | Test to extend |
|---|---|---|---|
| C1 | CONFIRMED (hard, 2+ enemy casters seen) | NOT a plain `set_auto_target` swap (it would override a plain move order). (a) drop the dive exception at 1065: a unit on a plain move order never dives; (b) skip the scout and `mapfill_ai.is_busy(u)` units via a new public Commander accessor (e.g. `is_army_unit(u)`); (c) `set_auto_target(best)` with reach capped at 2 x aggro_range | test_casters_ai (new dive case) |
| C2 | CONFIRMED | `if _given_up(p): continue` in `_shrine_due` (optional: skip when `fighter_near`) | test_12_a1 |
| C3 = A5 | PLAUSIBLE (burst wipe / all_in mid-creep) | before `_end_attack` ("group lost"): `if stage == CREEP and mapfill_ai: note_creep_end(_sortie, false, null); _creep_retry_at = _now + CREEP_RETRY` | test_12_a1 (~:746) |
| C4 | PLAUSIBLE (army passes 10-12 m from a camp) | keep a neutral only if it already fights the bot (`attack_target.team == team`) or belongs to `current_creep`'s node while stage is CREEP (no neutral "CAMP" stage) | test_casters_ai |
| C5 | PLAUSIBLE (minor) | not `order_cast`: pick the rearmost chased member whose wall spot is within range, else skip | test_casters_ai (`_ice_hard`) |
| C6 | PLAUSIBLE (minor, Nature) | add `or not _engaged(e, soldiers)` at 830 (real fix is C4) | test_casters_ai |
| C7 | REJECTED (latent: TierSystem.ENABLED is const true; every casters level has tiers) | optional hardening `TierSystem.tier_of(team) >= 2` | — |
| A1 | PLAUSIBLE (map-dependent) | the reviewer's fix alone deadlocks. (1) `_blocking_camp_target` takes `mid` even when X1 isn't done; (2) gate X1 on `_path_camp(mid) == null`; (3) a site with no builder blocked > ~90 s stops blocking `_next_row` or is cancelled | test_mt10_layout_bots / new commander test |
| A2 | PLAUSIBLE | per-point HUNT timeout ~60 s -> `_next_hunt`; remember an unreachable building target as skipped | test_mt10_layout_bots |
| A3 | CONFIRMED (every quickload vs a bot) | drop the INF skip; ADOPT_RADIUS 4 m also misses shifted buildings: widen (~10 m nearest unadopted) or save `_slot_building` / `attacks_launched` | test_save_load |
| A4 | PLAUSIBLE (mined out + far node unsafe) | `elif all_in and not _out_of_crystals() and _node_left(): all_in = false` with a >= 20 s hold | test_20_a2 |
| A6 | CONFIRMED (minor, Blitz Ice) | extract rule 7's pop-based reserve split (2242-2254) into a helper used by both | test_pace_switch |
| A7 | PLAUSIBLE (low; fog off only in tests) | SCOUT_LEG_TIME on the fog-less path too | test_6_a1 |

## Added to the bug-fix phase (from the balance study)
- E1 (gameplay-coder): projectile spells (Fireball, Shadow Lance, Rime Bolt) deal damage in `scripts/units/projectile.gd`
  `_impact()` (119-136) and skip `SpellCaster.deal_damage`, so `PaceSwitch.spell_damage_x` / `worker_spell_x` never apply
  to them. Fixing it makes Blitz `worker_spell_x 0.5` hit them on workers: re-run the balance arm D afterwards
  (`docs/balance/shadow_fire_2026-10-12/report.md` item 8).

## Order of work
Verify pass (read-only) first. Fixes wait until the Shadow / Fire balance study ends (it plays bot games from this tree;
bot code changes mid-batch would mix its numbers); the balance numbers must be re-checked after the fixes.
