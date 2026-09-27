# Lead status (overnight 2026-09-26) — read this first after a context reset

## Where things are
- Main repo: `Documents\four-wizards-rts` (git, branch main). CI copy: `Documents\four-wizards-rts-ci` (worktree,
  detached; run `scratchpad\ci.ps1` style suite there: checkout a tag, `--import`, smoke x3, perf 100/200, all tests).
  Playtest copy: `Documents\four-wizards-rts-play` (worktree, detached at `step7-candidate`; desktop shortcut
  "Four Wizards - Playtest 1v1"). Only move it to a tag that passed the CI suite.
- Git: `C:\Program Files\Git\cmd\git.exe` (add to PATH). If `index.lock` is stale and no git process runs, delete it.
- Perf numbers measured by agents while ~20 Godot processes run are meaningless; measure on a quiet machine
  (quiet: 100 units ~6-7 ms, 200 units ~13 ms, stuck=0).

## Done tonight (all committed)
Steps 5-7 complete (fog, menus, balance, character/building/env art, icons, audio, HUD skin, Ice kingdom, mission 1,
campaign save). Step 8 (Nature): units, spells, buildings, items, kingdom select any-vs-any, Nature HUD, Nature art +
VFX (NatureVfx in both scenes). Polish done: Vessa, Malrik, Torvald, Ice army, Shadow army, Dusk + Rime keeps.
Mission 2 spec written (`docs/design/mission-02.md`, not built yet).

## Update (later in the night)
Committed since: 8.S1, 8.S2, 8.U1(+follow-up), 8.U2, 8.V1-V5, 8.G1, 8.G2, 8.I1, 8.A1 (matrix: Nature dominates, Ice weakest,
Fire bot never cast), A.1-A.9, A.11 (lighting rig applied in main.gd), mission-02 spec, export_presets.cfg.
**Windows export verified**: CI copy at tag `export-test` → `build\FourWizards.exe` (115 MB) starts OK headless.
Running now: A.10 terrain · A.12 combat VFX · A.13 spell VFX · A.14 Ysolde · A.15 icons · A.16 kit glow fix ·
8.D1 balance-2 spec · 8.A2 Vessa bot casts. After them: apply balance-2 (data), final CI suite on a tag, move the
playtest copy, export + zip to Desktop, playtest-notes.md, ask about OneDrive.

## Update 2 (~00:45 Quebec, 5-hour meter 65 %, week 18 %)
Also committed: A.4 Fire army, A.12 combat VFX, A.13 spell VFX, A.14 Ysolde, A.15 icons (109), A.16 kit glow slot map,
A.17 white squares + gold level-up, 8.D1 balance-2 spec, 8.B1 balance-2 data. **Still running: A.10 terrain,
8.A2 Vessa bot casts + balance-2 bot knobs + re-test table.** When both are done → final CI suite (tag `night-final`),
move playtest copy, export exe from the CI copy, zip to Desktop, write playtest-notes.md, tell the user (French).

## Still running when this was written (first list, now mostly done)
8.A1 Nature bot + any-kingdom matrix · A.4 Fire army polish · A.7 Fire Keep polish · A.9 halls/houses/towers ·
A.10 terrain · A.11 lighting (writes `docs/art/lighting.md` with main.gd lines for the lead) · A.12 combat VFX ·
A.13 spell VFX · A.14 Ysolde polish · A.15 icons re-render.

## Next for the lead
1. Commit each finished agent's files; apply glue from their reports (lighting lines in main.gd, kit fix
   `glow_boost : instance_index(4)` from the Vessa artist, IceVfx `billboard_keep_scale = true`).
2. Full CI suite on a new tag in the CI copy; fix/route failures; then move the playtest copy to that tag.
3. Write `docs/plan/playtest-notes.md` (French summary for the user: what's new, how to play, known issues).
4. **Windows export for the user's other laptop** (user approved the templates download; installed in
   `%APPDATA%\Godot\export_templates\4.7.2.stable`): create `export_presets.cfg` (Windows Desktop, x86_64,
   embed pck, include filter `*.json`), export from the playtest copy with
   `--headless --path <play> --export-release "Windows Desktop" <out>\FourWizards.exe`, smoke-run the exe,
   zip it to the Desktop `FourWizards-<date>.zip`. **Ask the user before copying it into OneDrive**
   (`%USERPROFILE%\OneDrive` exists) — then they share the link themselves.
5. Budget: 5-hour window resets ~1:10 AM; in window 2 stop launching at ~80 % (user wants ~20 % left at 6 AM).
   Don't exceed 20 concurrent agents (app limit).
6. Open user decisions: rename "Shade"? Fireball 3 s cooldown OK? Mission 1 instant loss on Vessa's death?
   Nature cap 50 / Ice walls OK? Rooted workers keep mining (only frozen pauses) OK? Mission 2: start level 2 / cap 6,
   MissionBase extraction, dig timer defeat ~22:50.

## Update 3
A.10 terrain committed; map_dressing plug-in DISABLED in main.gd (it left all units stuck: must be added after the bake, no colliders on nav layers). Smoke regressed to TIMEOUT player=13 enemy=15 after 838e559: agent F.2 is bisecting in the CI copy. 8.B4 (balance backup knobs + retest) running. Playtest copy still at step7-candidate (known good). Next: when F.2 + 8.B4 done -> CI suite on a tag -> playtest + export.

## Update 4 (2026-09-26 morning): step 9 Champions
9.L1 committed (d25f8e8). 15 agents running: 9.D3 (Fable), 9.C1-9.C8, 9.V1-9.V6. Rules for them: docs/plan/step9-agent-rules.md. Next: commit each as it lands, then phase 2 (9.C9 bot, 9.C10 plug models+VFX, lead glue: ChampionVfx node in both scenes, hud wiring from docs/handoff/for-lead.md), then 9.C11 headless bot-vs-bot run, CI on a tag, playtest copy, notes.

## Update 5 (2026-09-26 afternoon): step 9 + art day DONE
Tag step9-final: CI 98/99 (only old test_m7_u1), smoke 3/3, perf 6.0 / 10.7 ms stuck=0, 8 champion bot-vs-bot runs with 0 script errors. Playtest copy at step9-final; exe exported (build_step9 in the CI copy), zip replaced on Desktop + OneDrive. Weekly 32 %. Next: user playtest on the laptop, then 9.D4 balance (champions shorten games to ~9-11 min; Fire strong; notes in docs/handoff/for-game-designer.md), mission 2 build, test_m7_u1.

## Update 6 (2026-09-26 ~15:00): specs ready, builds waiting for the user
- Step 10 spec docs/design/market-trade.md (user answers: gold = 3rd resource; thieves raid caravans + remote workers after 8:00; thieves neutral; hunters = autonomous gold contracts; Den + Lodge at both corners).
- Step 11 spec docs/design/skills-rework.md (champions pick a class at L2: Spear / Sword & Shield / Two-Hand / Wizard; class skills ADD to the 3 archetype abilities = 6 max; odd pairs rare; compensation knobs). Silkroad full system = future game (appendix).
- Weekly 33 % at 15:00; weekly resets Sat ~1 AM. Launch builds only when the user says (PC loud at night). Order: 10.L1 contracts then ~12 agents; then 11.L1 then ~12 agents.

## Update 7 (2026-09-26 ~12:35): 'use the max' day
Step 10 trade: all tasks committed except 10.A3 (bot, running); 10.L2 (lead integration: --no-trade control, CI, playtest) next. Step 11 classes: C1-C5, D2, V1, V6, V7 committed; running 11.V2-V5; 11.A1 after 10.A3; then 11.L2. Specs done: 12 map-fill (user answers: river+isle yes, shrines in turn, underdog yes, critters HUNTABLE; revision running: epic animals 4-8 kinds x 2 variants, food hook), 13 cavalry-mounts (answers in waves.md), 14 research (running). Step 15 food/supply = future. Running 12.V1, V3, V4, V7, V13, V17, V18 (art, rules docs/plan/step12-agent-rules.md). Stray 0-byte file C:\Users\elzzo\Documents\nouveau-projet-de-jeu\market_shadow.gd: user must delete (agent blocked). Weekly 47 % at 12:35 (target ~90-95 % by 00:59); 5-hour window resets 15:50 (53 % now).

## Update 8 (2026-09-26 ~13:55)
Steps 10 + 11 fully built and committed (tag step11-candidate; CI suite running in the CI copy -> result in the bg task / scratchpad ci_result.txt). User testing rule: no big tests until weekly ~75 %; then full integration pass (10.L2 + 11.L2: CI, --no-trade control, bot matches, playtest copy, export, OneDrive zip). Specs done + user answers in waves.md: 11b champion skill tree (11b.D1 running), 12 map-fill (art done: V1 V3 V4 V7 V8 V13 V14 V17 V18 V19 V20), 12b terrain (Ice snow, Fire ash/sand, Nature riverbanks/water, Shadow neutral; design to launch at the 15:50 5-hour reset), 13 cavalry/titans/mounts (running 13.V13 dragon, 13.V1a mount base + Rimehorn), 14 research, 15 food (future), 16 rush + 10 new units (user: normal building damage, Muster Bell, Random 25 % Rusher, keep 10 units). 5-hour window 79 % at 13:55 (reset 15:50): no launches until then. Weekly 53 %. Backups: bundle in Documents\four-wizards-backup, source zip in OneDrive (refresh after big steps). GitHub push still needs the user's sign-in.

## Update 9 (2026-09-26 ~15:00, before a likely context compaction)
CI on step11-candidate: 135/139 (fixed test_7_s1; test_10_a3 / test_11_a1 were harness artefacts, ci.ps1 fixed; test_m7_u1 old). Tag step11-playtest; export running in the CI copy -> build_step11\FourWizards.exe (bg task); then: smoke-run exe, zip to Desktop + OneDrive (replace FourWizards-2026-09-26.zip), move the playtest worktree to step11-playtest, update playtest-notes.md (trade + gold + caravans + Magpies + Lodges + champion classes), tell the user (French). Running: 13c.D1 titans-2 (last titan = base upgrade, balance first), 17.D1 grand market. At the 15:50 5-hour reset: Wave A of waves.md (12.L1 then step-12 code + art). Weekly 55 %, target build to 80 % then save + test; bedtime midnight-1 AM.

## Update 10 (~15:25)
Playtest build with UX.1 controls (tag playtest-controls) is in OneDrive + playtest copy. Running: MAP.P1 (ground / cliffs / lighting polish), MAP.P2 (neutral sites polish), 17.D1 revision (3 expansions). 5-hour window 88 % -> at ~93-95 % do save + test (bundle, OneDrive source zip, CI on a tag). At the 15:50 reset: Wave A of waves.md. User answers so far are all in waves.md (steps 11b, 12, 12b, 13, 13b, 13c, 14, 16, 17, 18).

## Update 11 (15:27, 5-hour window 96 %)
All finished work committed (HEAD 482a453). In flight at the limit: 12.V2 ground river cut, 12.V15 deer/rabbit, 12.V21 Mirefang, 12.V22 Gloomcap, 13c.V1 Frost Dragon, 19.D1 story Episode 1 + cinematics (user directions in waves.md step 19), 17b.D1 key-clash revision (Auto key vs step-18 O). Uncommitted agent files are snapshotted in refs/wip/latest (not merged; working tree untouched). If an agent was cut by the limit: after the 15:50 reset, SendMessage it to resume (its transcript is kept), else relaunch it on the same files. CI on tag map-polish running in four-wizards-rts-ci. Pending user questions: 18.D1 (5) and 17b.D1 (4).

CI on tag map-polish (15:45): 150/154 PASS, smoke x3 OK, perf 6.35 / 11.03 ms OK. Fails: test_2_a1_bot_vs_bot (no winner in 1500 s — long games since trade), test_9_c9 (hard: no B4 Explore flag), test_a_8 and test_a_9 (no PASS/FAIL line: timeout at 40000 frames or quit early). Triage after 15:52 with one agent (tests + cause, no gameplay changes without the lead).

12.C4 open points for 12.L2 / 12.C9: Elder bolt speed 14 needs UnitType.projectile_speed (Unit._spawn_shot uses 25); Unit.MAX_UNIT_RADIUS 0.7 < beast radius 0.8-1.1; dash facing (Unit private); CreatureAbilities.ready(id) shadows Node.ready signal (never await it).

12.V11 notes for 12.V6: set materials live on mesh surfaces (never use as material_override; bush contact disc is surface 1). Decor kinds: six biome sets = 28 kinds vs budget 24 -> 12.V6 / designer decide (merge kinds or raise the budget).

12.V23 Hollow Stag done: 12.C9 sets hollow_stag.tres model_scene res://art/units/neutral/hollow_stag/hollow_stag.tscn (model_path already points there) and body_height 2.6.

12.V12 notes for 12.V6: isle is kind-1 paving (0,0,9.5,1) so MapDressingArt._blocked() blocks all decor there - let paving_ok ruins items onto kind-1 paving, flat kinds 2.6 m from the lane there (ruins_preview.gd _scatter/_blocked is the model). Only an item's own material is safe as material_override (variant collapse).

CI triage (16:45): test_a_8 / test_a_9 / test_9_c9 fixed (test-only). test_2_a1 = real stall: (1) commander.gd _check_concede (~2305) never concedes with a caravan or Bazaar alive even at 0 workers/0 soldiers -> require real trade income in last N s or a timeout; (2) ai_trade.gd exchange_tick/_exchange_keep (~347-383) keeps gold for wares at 0 workers instead of exchanging for crystals to rebuild; (3) Fire at pop cap can't finish (12 workers + 6 caravans). Also commander.gd _can_spend (~1417) lets 2 trainings through in 2 s under the hire reserve (easy hire slips to 10-11 min). Assign to ai-coder after 12.A1 lands.

12.L2 glue list: CritterSystem in main.gd _ready after the map dressing add_child (load-guarded, setup(self)); GameSettings.map_detail static var for ui-coder; MapFillVfx node in skirmish; 12.C9 model_scene/body_height for beasts + stag; selection ray collide_with_areas layer 2 (12.C6); Cutpurse must not pay loot on critter kills.

MAP.P3 horizon glued in skirmish.tscn. It is baked against meshes/map_plateau.res: after 12.V5 finishes, re-run horizon_builder.gd (test_map_p3 fails with 're-run horizon_builder.gd' if the bake no longer fits).

12.C9: UnitType never loads model_path on its own -> set model_scene in every beast .tres + hollow_stag.tres. Tusker: res://art/units/neutral/beasts/tusker/tusker.tscn, body_height 2.1 (ironhide) / 2.4 (old_scarback).

12.C9: Roc model_scene res://art/units/neutral/beasts/roc/roc.tscn, body_height 3.6 (stormcrest + duskwing). Direwolf res://art/units/neutral/beasts/direwolf/direwolf.tscn (body_height 1.8).

12.C9: Grizzlemaw model_scene res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn (grizzlemaw + elder_grizzlemaw).

12.C1 done (smoke victory, PERF OK 7.60 ms). Test fixes for the big pass: test_4_s1 crown drops -> use Skirmish.CAMP_DROP_SPOTS ((2,2)/(-2,-2)); test_9_c5 Coin-Cutter spawn (-30,20) is inside the Giant's Stump collider -> move spawn; test_9_c3 tavern spots now answer 'Too close to a crossing' (relayed to 12.C5). Watchtower roofs leave a tiny unreachable navmesh area (12.C2 note). Not run by C1: test_9_c9, test_9_c11, test_2_a1_rules, test_8_b3.

13 code glue: Nightmare Knight UnitType body_height ~3.6 (not 2.8); call set_gallop_smoke(on) when the TitanAbilities gallop modifier toggles; charge_struck(at) signal for 13.V19 impact VFX.

13 code glue: War Mammoth play_trample() per trample tick (signal trample_stomped(at) at 0.2 s); howdah bolt delayed HOWDAH_RELEASE 0.12 s, spawned at get_howdah_muzzle().

13 code glue: Elder Treant model_scene res://art/units/titans/elder_treant/elder_treant.tscn; V order -> set_rooted(on) (3 s, root_changed); volley_released at 0.15 s + get_volley_origins() for 13.V19; set_regen(on). Kit README slot table: add slots 7 root_morph / 8 heal_glow / 9 team_tint (treant-only).

13.V1b seated rider in CharacterModel (additive). Smoke victory=false (player=0 enemy=5 @3600) seen during a busy run -> check in the quiet CI. Rimehorn Seat sits behind the hump (move the marker in rimehorn.tscn if it looks wrong).

12.V6 done: 24 kinds (merged clover/dandelion, dropped cobwebs/roots), ~2700 decor. GPU +16 % isle z30, +20-24 % at z55 (still >=160 fps on the 1660); ground river +15 % on top. Decide in 12.L2 frame check: density_scale 0.6-0.8 default or accept. test_map_p1 shadow allowlist should include Biomes casters.

13.C3 TitanAbilities must call TitanVfx.play(&'burning_ground' / &'hoarfrost', centre, dragon_unit) when it creates a patch. TitanVfx glued in main.tscn + skirmish.tscn.

12.C8 done (camp sites + lairs plugged, CritterSystem in main.gd; perf OK 6.7 ms on a quiet run). test_12_v16 Part A: call gs.call(&'ensure_read') before setting GameSettings.map_detail (~l.268) once 12.C7 lands; Part B could check main's own CritterSystem node.

13c code glue: Barrow Giant boulder_throw lob must start from the model (get_throw_release() 0.6 s / boulder_released(origin), get_throw_origin()), since Unit caps attack_windup at 0.15.

13c.V8 Frost Wyrm built WINGLESS (lead prompt error; titans-2.md 7.1 / sec 11 say winged, 8.5 m ice-feather wings). Ask the user: keep the serpent or add wings. Posing ~0.14 ms per wyrm close up.

13c.V7 Ember Crucible annex is standalone (art/buildings/fire/ember_crucible) for the future Roost (13.V25): keep the spire foot slim near ROOST_ANCHOR (1.85,0,-1.85) or scale 0.85; hide on construction/wreck, keep out of the Roost mesh merge, set_crucible(false, true) on Roost death.

13b.V3 Glade Outrider: new hook set_aim_target(target) + signal arrow_released(from, dir) (add to the 13b contracts at 13b.L1); fallback reads the unit's attack_target. Pattern for 13.V9 Stagrunner.

20.A2 bot stall fix done: 12/12 bot_vs_bot with a winner since the last design change (final gated version not bvb-tested yet: ScorePanel parse break). test_10_a3 hard part flaky (B1 Guard on the forward hall blocks B7; once no Bazaar by 6:00) — baseline run needed to rule out the F5 hire-reserve change. Balance note: games past 20 min when both bots turtle until mined out; Fire bot rarely attacks before all-in.

TODO lead: when the running agents (score, Bot Lab, 14 art) are done -> re-run CI (auto-fix failures), then give the user a ranked 'what to build next' menu (13 code to make cavalry/titans playable, 12b terrain code+integration, prologue movie window, 2v2 build, 14 research, 16 balance via Bot Lab, 17 Grand Market, 18 building levels, 18b walls, icons pass).

13b.C glue: frost_tracer is a separate visual from the 50 m/s Projectile bolt (hide / skip the bolt when playing it); call rifle_impact on hit or pass {impact: true}; Rime Lock: rime_lock_aim(shooter, target) -> rime_lock_hit(victim, victim) or rime_lock_cancel(shooter); brace(unit) on bracing.

12b.V2 snow set notes for 12b.V6: place &'snow' / &'snow_edge' (EDGE_BAND 1 m) rows; thin grass/flowers/heather on snow. For 12b.V1: snow base (0.90,0.93,0.98), drift shade steps may need to be stronger under warm light.

13.V26 Dread Paddock: 159 draw calls alone (Gloom Hall 101) - cut the two heads' 4 materials if needed; Mage Archer call point get_call_point() is inside the collider (gameplay: rise visually then walk out, or spawn at the door). 13.C8: lair colliders from BuildingType.height (<=1.8 m rule).

13.C3 TitanAbilities glue: with play_howdah_shot(target) also TitanVfx.play(&'howdah_bolt', target, mammoth); treant volley &'thorn_volley'; &'sapling_sprout' on sprout; &'knight_knockback' per knocked unit.

12b.L2 glue: add TerrainVfx node (art/vfx/terrain_vfx.gd) to skirmish.tscn next to MapFillVfx once TerrainSystem exists; 12b.V6 calls AshSet.scar_fx(center, 4.5) per static ash patch.

Art Lab v1 done (22:12). Findings to fix next week: Fire Keep FAIL (14,775 verts > 12,000, 18 materials > 8); Mossback green-on-grass (dE 18, 4 glow points, 17.5k verts); Colossus 7 glow points; heath gorse 2,080 tris; kit CharacterModel.set_team_color only reliable once at spawn (mirror / mid-game recolour broken). Art Lab notes collection until 2026-09-27 evening -> 'Art Lab v2'.

Perf Lab v1 first (noisy) hot list -> fix next week: (1) Commander think spikes 144-188 ms (scout / attack / champions) — agent running; (2) HUD 3.9-4.5 ms/frame: selection_panel.gd _update_hero() string formatting every frame, command_card.gd, selection_manager.gd; (3) unit.gd _update_hp_bar() writes shader params every frame (4.4 ms @200); (4) unit model scripts 4.5 ms vs 0.7 budget (fire_model _set_ball_heat, blaze rider, ember boar, shadow_model); (5) idle pooled GPUParticles cost 1.5-2.2 ms CPU; (6) VFX managers create nodes at runtime incl. 3 OmniLight3D (breaks pooling / 0-light rules): mapfill_wyrm, titan_ground, mapfill_beast, spell_vfx; (7) GPU: biome decor 25 %, sun shadows 15 %. Quiet baseline needed: run_perf_lab.ps1 -WaitQuietS 600 -Repeats 3.

Audio Lab notes for v2: fold <id>_N takes into the parent cue (volume / 3D / category); QOA import overshoots ~+7 dB on harmonic tones (hint: import as PCM/ADPCM); CATEGORY_BY_ID lacks wizard_fell / ability_cast / skill_hit.

Art Lab notes (Mossback): R5 counts painted-shader rim light as glow (ignore <=4 px edge clusters / drop rim in dark pass); R3 hue gap misleading at low chroma (only when C*>25); P1/P2 thin hooks (<0.25 m) don't register at 40 m -> say so in the hint; add emission crop with marked clusters + per-mesh vertex breakdown. Design change to confirm with user: Mossback eyes no longer glow.

Art Lab notes (Fire Keep): R5 glow threshold 0.4 << bloom 1.1 -> use bloom level, skip flat decals, keep tier 4-12 points; B9 should accept art-keep 8.6 per-keep copies; add surfaces-per-instance count + downward-facing-face waste hint. Unused shaders left: fire_keep_window/heart/crystal/lava.gdshader (delete in a cleanup).

Data Lab v1: 98/100, 0 FAIL. Findings: Fire units carry stale card_key (W/Q/E/R/T) — clear or remove the field; balance: grave_hound DPS/100 x2.2 slot median, ash_hurler EHP/100 x0.23, blaze_rider stats vs slot C; slots C/V mix roles across kingdoms (AI army mixes assume same roles) -> designer. 244 hard-coded UI strings (no tr()) for the French pass.

Replay Lab v1: works end to end; full determinism needs project.godot [navigation] avoidance/thread_model/avoidance_use_multiple_threads=false (PASS on a scratch copy with it) -> apply after a QUIET perf-lab A/B (late200) next session. Open items in docs/plan/replay-lab.md 'Progress / next steps'. Stray user://replays/replay_2026-09-26_22-3x_* files can be deleted.

Bot Lab v1 done: sim x1.1-1.9, sim + Tick 30 x3.3 (kept 60 Hz default: attack cooldown loses ~4 % DPS at 30 Hz); 13 matches/h on the loaded PC. First batch (at fb2166f, before 20.A2): Fire/Nature 5-1, Shadow/Ice 1-5, median 14:22, 12/16 games had a side with no workers >1 min (pre-recovery-mode build) -> rerun on the current HEAD after moving the lab worktree. Next: 8 seeds x 2 pairs sim-vs-normal validation; navmesh cache decision from logged start-up parts.

Art Lab notes (wizards): B1 counts first-instance build parts, not render cost (PartBatch pattern in wizard_model.gd fixes it; kit rule 'authoring detail is cheap' vs B1 26 conflicts); R5 unstable with drifting particles (median over 2-3 phases); B10 false alarm on swapping cached process materials; P5 ignores glowing surfaces; R8 wizard hooks need a tier tolerance; add B1 per-pivot breakdown + R3 variant with enemy team colour.

20.A3: think median -35 % (still ~1.1-1.3 ms vs 0.3 target, next: AIWorldCache 20.A6); attacks fixed (rule 1 no isle / camp chasing, rule 7 ratio floor + patience + first_attack_by + full_pop knobs). Balance: Fire won 3/3 bvb; hire reserve caps army 3:00-7:00. Replay recorder froze economies while auto_record was on (21:46-22:37) — now off by default; tests force it off too.

Map art pass: Colossus 86->91, gorse 2080->1186 tris, Frost Dragon blob cached (move the cache into flyer_model.gd ensure_shadow_blob later), Mirefang tail curl 87->90, standing stones dimmer. Crown altar 87 WARN (11 glow points, 10 materials) needs a build_crown.gd rebuild task (test_a2_3) or accept. Art Lab notes: ref= short names, glow averaged over phases, objective vs decor landmark budgets, per-variant tris for decor sets, screen-space P3/P5 wrong for flat creatures.

Ice/Nature soldiers: Sapling 86->93, Sprigling 86->88, Burr Slinger 89->90, Bramblehorn 87->89, Rime Colossus 89->90 (green-on-grass fixed). DECISION NEEDED: Art Lab B1 'authored meshes' FAILs 10/12 soldiers while draws pass -> either apply the wizards' PartBatch pre-merge to the soldier kit, or make B1 count post-merge meshes (Art Lab v2). Art Lab v2 notes also: skip spawn animation / spawn effects before shots, glow-point local contrast, R3 top-third contrast, identity-crest exemption, army batch runner.

USER DECISION (23:20): Art Lab B1 counts meshes AFTER the kit merge (post-merge / render cost), not authored build parts -> part of 'Art Lab v2' (first thing next session, four-wizards-high).

Art Lab v2 DONE (c48d59c, 00:01): B1 post-merge (B1a authored = INFO), R5 glow points vs bloom threshold (median of 3 phases, names the part), skip spawn anims, B10 second-cycle only, R3 top third + R3t (4 team colours) + R4k (home ground), P3/P5 world-height, R8 crest tolerance, B13 noise band, army sweep (sweep=<kingdom>), run_art_lab.ps1. Sapling WARN 92, Ember Archer FAIL 91 (B13 frame cost, re-run QUIET), Fire Keep WARN 90 (32 glow points vs 4-12; braziers/banners). v1 scores not comparable. Next: windowed sweep Ice + Nature first; real terrain paint for snow/ash/sand/marsh grounds. Unlocks the 20.V0 autumn Art Lab runs (style-autumn.md sect. 6).

UI Lab v1 DONE (c48d59c): FAIL 96/100 (3 FAIL contrast on empty ChampionBar slots 2.1-3.0:1; WARN F5-F7 badges 10 px, G listed twice in help). Menus/pause/end screen pass at 1600x900 / 1080p / 3440x1440. Seen not measured: HUD keeps 1600 px layout at 3440 (bottom bar gap ~1500 px), selection text shows through end panel, Fullscreen switch invisible when off, setup panel 5 px from bottom at 900p -> ui-coder task.

Map Lab v1 DONE (c48d59c): Crown Hollow WARN 98 — map geometry fair (812/812 path pairs within 2 %), all constants mirror; F2 WARN: unit NavigationServer paths differ by side (42/870 pairs >5 %, worst 15 %) because navmesh polys aren't mirrored -> Bot Lab compare, then maybe finer bake. Fords = hottest metres. 2v2 needs scenes/skirmish_2v2.tscn, keeps in group buildings team=seat, LAIR_SPOTS. Paste map-lab.md sect. 5 rule into next map task rules.

NOTE all labs: quote '--' and comma lists when calling through godot_run.ps1 (PowerShell drops bare -- and splits a,b).

Balance Lab v1 DONE: variant JSON overrides .tres in memory (units/buildings, x1.15 / +50 / value), live proof per unit, Fisher + Wilson + games-needed (~98/arm for 20 pts). Validation 4/4 ok (smoke only, low N). Suggest (low confidence, 6 games/kingdom): don't nerf grave_hound now (Shadow already weak) — only power-neutral dmg 8->6 + cost 70->61; ash_hurler only power-neutral trades; blaze_rider cost 180->212 top knob. Next: move lab worktree to a tag with bot_lab + balance_lab, then A/B Fire/Shadow seeds 1-8 -Tick 30 (~2-3 h machine time).

Visual Diff Lab v1 DONE: 9 golden shots (menu, 4 map cams, 4 kingdom lineups) PASS 100; deterministic via time_scale 0 + TIME reset + path-seeded RNG; known noise = neutral creatures' idle pose near Crown isle (map shots PASS up to 0.35 %). Run after each wave: tools\visual_diff_lab\run_visual_diff_lab.ps1 ; re-record intended changes with -Golden -Shots <id>. Stale docs/visual/*.png.import files can be deleted by the user.

Error Lab day-end baseline: 230/235 PASS. FAIL: test_10_a3 (no B7 Guard flag after raid), test_20_a2 / test_20_a3 / test_9_c11 (no PASS line, probably cap), test_replay_lab. Fix agent launched 00:12 (stop 00:40).

Fix agent (00:30, d9d464a): Error Lab caps 20_a2 60000 / 20_a3 80000 / 9_c11 95000 (also in scratchpad ci.ps1); RID leaks INFO; $ExpectedRx for art_lab nope.tscn. test_20_a2 PASS on rerun. Reruns of 20_a3 / 9_c11 / replay_lab / 10_a3 logged in %TEMP%\claude\t*.log. OPEN: test_10_a3 B7 Guard flag needs a forward hall within 14 m of the natural (test places none; 20.A3 changed expansion timing) -> make _raid_stage ensure a barracks or skip B7. test_replay_lab non-deterministic (diverges frame 600) -> check rerun alone; determinism owner task either way.

test_10_a3 rerun (00:34): FAIL again, 2 errors -> 'normal: the Coin-Cutter ignored a looting Magpie 8 s (intent Raiding)' + 'hard: no B7 Guard flag after a raid'. test_20_a3 rerun PASS. Fix agent for 10_a3 first thing next session (log: %TEMP%\claude\t10a3.log, copy it before temp cleanup).
