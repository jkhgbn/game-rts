# Cinematic gap audit (2026-10-08)

Every cinematic beat the specs list for the built missions (m00-m04, e2m1-e2m5, e3m1-e3m4) and the story-film chains
between them, against what exists in the game today. Sources: `campaign-outline.md` 3.1-3.3, `story-episode-1.md` 7.2
(the Ep1 table of 18), the "Cinematic hooks" table of each `mission-*.md`, `t3-helpers.md` 10.3 (Theatre reveals).

Status codes:
- **BUILT .cine**: `data/cinematics/src/<id>.cine` baked to `data/cinematics/<id>.tres` (stage films also have
  `scenes/cinematics/<id>.tscn`) and played by the mission / StoryFlow.
- **BUILT code**: a multi-shot scene built in the mission script on the cinematic runtime (mission 0's pattern).
- **CARD**: only a fallback card (one dolly shot + subtitles, or a text card). Counts as a gap.
- **GAP**: ENGINE beat with no scripted scene.
- **VIDEO-only**: a VIDEO beat (later production, `story-episode-1.md` 7.4); excluded from the gaps. Its fallback card
  stays until the video exists.
- **set-piece**: an in-game moment with no camera takeover (spec says so); not a cinematic, not a gap.

## 1. Table

| Mission / chain | Beat id | Spec kind | Status | Notes |
|---|---|---|---|---|
| Ep1 opening | `ep1_intro` "The Night of Knives" | VIDEO 2:00 | VIDEO-only | Fallback text card before m00 |
| m00 | `m0_fall` | ENGINE PAUSE 0:35 | BUILT code | `Mission00._fall_card` (5 shots) |
| m00 | `m0_dawn` | ENGINE HOLD 0:30 | BUILT code | `Mission00._dawn_card` (4 shots) |
| m01 | `m1_westwatch` (E5) | ENGINE PAUSE | BUILT .cine | |
| m01 | `m1_seal` (E6) | ENGINE PAUSE 0:12 | BUILT .cine | |
| m01 | `m1_crown` (E7) | ENGINE PAUSE | BUILT .cine | |
| m01 | `m1_watchers` (E8) | ENGINE PAUSE | BUILT .cine | |
| m01 -> m02 | `c1_offer` "The Offer" | ENGINE stage 1:20 | **GAP** | Not in `STORY_FILMS`; set 19.V7 (Rime Keep throne hall) not built |
| m02 | `m2_heartfrost` (E10) | ENGINE PAUSE 0:10 | BUILT .cine | |
| m02 | Aldra on the Glass Ridge (E11) | in-world beat | set-piece | No camera takeover (spec) |
| m02 -> m03 | `c2_two_fronts` "One Front, Two Watchers" | ENGINE stage 1:30 (1:20 without Pell) | **GAP** | Pell branch on `m1_peddler_freed`; set 19.V8 not built |
| m03 | `m3_oldroot` (E10) | ENGINE PAUSE 0:12 | BUILT .cine | |
| m03 | `m3_plea` (E11) | ENGINE PAUSE 0:40 | BUILT .cine | |
| m03 | `m3_memory` | VIDEO 1:00 | VIDEO-only | Fallback card after `m3_plea` |
| m03 | `m3_parting` (E13) | ENGINE PAUSE 0:40 | **GAP** (CARD) | `Mission03._parting_card` fallback card only |
| m03 -> m04 | `c3_parley` "The Parley" | ENGINE stage 1:45 | **GAP** | Companion branch; set 19.V9 (Fallen Colossus parley ground) not built |
| m04 | `m4_war` (E1) | ENGINE HOLD 0:30 | BUILT .cine | Played as mode=pause |
| m04 | `m4_rise` (E6) | VIDEO 0:45 | VIDEO-only | Fallback card |
| m04 | `m4_storm` (E12) | VIDEO 1:45 | VIDEO-only | Fallback card |
| m04 | `m4_fall` (E15) | ENGINE PAUSE 0:06 | BUILT .cine | |
| m04 -> Ep1 end | `ep1_ending` "The Keystone" | VIDEO 1:30 | VIDEO-only | Fallback card |
| m04 -> Ep1 end | `ep1_credits` | ENGINE stage 1:30 | **GAP** (CARD) | `Mission04` text card "Episode 1 complete" |
| Ep2 opening | `ep2_opening` | stage film 1:12 | BUILT .cine | |
| e2m1 | `e2m1_arrival` (E1) | ENGINE HOLD 0:20 | BUILT .cine | |
| e2m1 | `e2m1_frostwarden` (E5) | ENGINE PAUSE 0:12 | BUILT .cine | |
| e2m1 | Old Vey's arrival (E11) | in-game set-piece | set-piece | `t3-helpers.md` 10.2 |
| e2m1 | `e2m1_ysolde` (E20) | ENGINE PAUSE 0:30 | BUILT .cine | |
| e2m1 -> e2m2 | `c_e2_ashes` "What the Frost Kept" | ENGINE stage 1:15 | **GAP** | Beats only (no lines); not in `STORY_FILMS` |
| e2m2 | `e2m2_muster` (E1) | ENGINE HOLD 0:18 | BUILT .cine | |
| e2m2 | `e2m2_first_grove` (E3) | ENGINE PAUSE 0:10 | BUILT .cine | |
| e2m2 | `e2m2_heartwood` (E14) | ENGINE PAUSE 0:25 | BUILT .cine | |
| e2m2 | `e2m2_two_banners` (E21) | ENGINE PAUSE 0:20 | BUILT .cine | |
| e2m2 -> e2m3 | `c_e2_lodge` "The Price of the Road" | ENGINE stage 1:00 | **GAP** | Beats + draft lines; not in `STORY_FILMS` |
| e2m3 | `e2m3_road` (E1) | ENGINE HOLD 0:18 | BUILT .cine | |
| e2m3 | `e2m3_lodge` (E10) | ENGINE PAUSE 0:15 | BUILT .cine | |
| e2m3 | `e2m3_paid` (E20) | ENGINE PAUSE 0:25 | BUILT .cine | |
| e2m3 -> e2m4 | `c_e2_stair` "On the Way Down" | ENGINE stage 1:30 | **GAP** | Beats + draft lines; set `forge_watch_keep` exists |
| e2m4 | `e2m4_descent` (E1) | ENGINE HOLD 0:20 | BUILT .cine | |
| e2m4 | `e2m4_first_warden` (E4) | ENGINE PAUSE 0:10 | BUILT .cine | |
| e2m4 | `e2m4_forge` (E9) | ENGINE PAUSE 0:15 | BUILT .cine | |
| e2m4 | `e2m4_hush` (E15) | ENGINE PAUSE 0:10 | BUILT .cine | |
| e2m4 | `e2m4_sunrise` (E20) | ENGINE PAUSE 0:30 | BUILT .cine | |
| e2m5 | `e2m5_cavern` (E1) | ENGINE HOLD 0:24 | BUILT .cine | |
| e2m5 | `e2m5_wake` (E14) | ENGINE PAUSE 0:30 | BUILT .cine | |
| e2m5 | `e2m5_answer` (E18) | ENGINE PAUSE 0:12 | BUILT .cine | |
| e2m5 | `e2m5_fall` (E21) | ENGINE PAUSE 0:20 | BUILT .cine | |
| e2m5 | `e2m5_breach` (E23) | ENGINE PAUSE 0:06 | BUILT .cine | |
| e2m5 -> Ep3 | `ep2_ending` "All Four, or None" | ENGINE stage 1:30 | BUILT .cine | |
| Ep3 opening | `ep3_opening` | stage film 1:31 | BUILT .cine | |
| e3m1 | `e3m1_ford` (E7) | ENGINE HOLD 0:12 | BUILT .cine | |
| e3m1 | `e3m1_standard` (E10) | ENGINE HOLD 0:10 | BUILT .cine | |
| e3m1 | `e3m1_dusk` (E14) | ENGINE 0:30 | BUILT .cine | |
| e3m1 -> e3m2 | `c_e3_knife` | stage film ~1:10 | BUILT .cine | |
| e3m2 | `e3m2_slip` (E1) | ENGINE HOLD 0:15 | BUILT .cine | |
| e3m2 | `e3m2_embers` (E11) | ENGINE PAUSE 0:25 | BUILT .cine | |
| e3m2 | Hush's call (E15) | in-game set-piece | set-piece | |
| e3m2 | `e3m2_dawn` (E16) | ENGINE PAUSE 0:30 | BUILT .cine | |
| e3m2 -> e3m3 | `c_e3_price` | stage film ~1:10 | BUILT .cine | |
| e3m3 | `e3m3_homecoming` (E1) | ENGINE HOLD 0:20 | BUILT .cine | |
| e3m3 | `e3m3_offer` (E3) | ENGINE PAUSE 0:10 | BUILT .cine | |
| e3m3 | `e3m3_sexton` (E13) | ENGINE PAUSE 0:20 | BUILT .cine | |
| e3m3 | `e3m3_rest` (E15) | ENGINE PAUSE 0:30 | BUILT .cine | |
| e3m3 -> e3m4 | `c_e3_doubt` | stage film ~1:10 | BUILT .cine | |
| e3m4 | `e3m4_return` (E1) | ENGINE HOLD 0:20 | BUILT .cine | |
| e3m4 | Vey's arrival / breaks (E4, E6) | in-game set-pieces | set-piece | |
| e3m4 | `e3m4_whisper` (E11) | ENGINE PAUSE 0:15 | BUILT .cine | |
| e3m4 | `e3m4_field` (E15) | ENGINE PAUSE 0:45 | BUILT .cine | |
| e3m4 -> Ep4 | `ep3_ending` "I Will Not Stop" | stage film 1:00 | BUILT .cine | |
| Ep4 opening | `ep4_opening` | stage film 1:28 | BUILT .cine | Chain ends on the menu (e4m1 not built) |
| Theatre | `helper_vey` / `helper_hush` / `helper_aldra` / `helper_maelis` reveals | ENGINE stage <= 0:45 each | **GAP** (outside the missions) | TH.C1; full shot lists (TH.D3) not written; no Theatre screen to play them yet |

## 2. Counts

| | Count |
|---|---|
| Beats listed | 73 (69 cinematics counting the 4 Theatre reveals + 4 set-pieces) |
| ENGINE beats built (.cine or code) | 52 (50 .cine + 2 code-built in m00) |
| ENGINE gaps in the mission chains | **8**: `m3_parting` (in-mission, card only), `c1_offer`, `c2_two_fronts`, `c3_parley`, `ep1_credits` (Ep1 stage films), `c_e2_ashes`, `c_e2_lodge`, `c_e2_stair` (Ep2 stage films) |
| ENGINE gaps outside the missions | 4 Theatre reveals (one row above) |
| VIDEO-only (excluded) | 5: `ep1_intro`, `m3_memory`, `m4_rise`, `m4_storm`, `ep1_ending` |
| Set-pieces (not cinematics) | 4 |

Episode 3 has no gap. Episode 2 lacks its three between-mission films. Episode 1 lacks one in-mission scene and all its
stage films (the three between-mission scenes and the credits).

## 3. Which gaps fit the built missions (fill order for the night of 2026-10-08)
1. `m3_parting`: in-mission, mode=pause, its 5 lines already voiced in `Mission03.CINE_LINES`, French in campaign.po.
   Same pattern as `m3_plea`.
2. `c_e2_ashes`, `c_e2_lodge`, `c_e2_stair`: stage films on existing World Forge sets, wired into `STORY_FILMS` like
   the Ep3 between-scenes. Their lines are written from the spec's beats and draft lines; every line goes to the
   game designer in `film-text-review.md`.
3. `c1_offer`, `c2_two_fronts`, `c3_parley`: full shot lists and lines in `story-episode-1.md` 7.2, but their sets
   (19.V7-19.V9) do not exist. A stand-in set changes the look the spec asks for: built only if time allows, flagged.
4. `ep1_credits`: the credit roll's text is the lead's / JS's call; left as the text card.
5. Theatre reveals: need TH.D3 shot lists and a Theatre screen; not in scope.

## 4. Filled on 2026-10-08 (same night)
| Gap | Now | Commit | Test |
|---|---|---|---|
| `m3_parting` | mode=pause film, 4 orbit shots on the live Vessa / Ysolde (the last gate falls anywhere); Ysolde's story figure is her wizard model and runs during PAUSE films | 63e9981e | `test_cine_m03_parting` |
| `c_e2_ashes`, `c_e2_lodge`, `c_e2_stair` | stage films on `forge_intro_ysolde` / `forge_ep2_feast` / `forge_watch_keep`, in StoryFlow after e2m1 / e2m2 / e2m3; lines written from the beats | 33c811c4 | `test_cine_ep2_between` |
| `c1_offer`, `c2_two_fronts`, `c3_parley` | stage films on stand-in sets (no 19.V7-V9 sets), the spec's lines, in StoryFlow after m01 / m02 / m03; no Pell / companion branch | 0616dc8b | `test_cine_ep1_between` |
Still open: `ep1_credits` (a text card; the credit roll's content is the lead's call), the 4 Theatre reveals (TH.D3 / TH.C1),
the real sets 19.V7-V9 for the Ep1 between-scenes, StoryFlow branches (Pell, companion). Every line written or staged
tonight is in `film-text-review.md` for the game designer.
