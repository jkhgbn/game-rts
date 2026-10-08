# Script: `c_e3_doubt_refused` "Torvald's Doubt (the stone refused)", the second take of `c_e3_doubt` (Episode 3)

Written 2026-10-08 on JS's call (index: `docs/design/script-episodes-4-8.md`, decision Q7b). Spec:
`docs/design/mission-e3-03.md` Cinematic hooks, `c_e3_doubt`: "If `e3m3_refused`: Aldra instead: 'It didn't glow at all.
That frightens me more.'" The built film `c_e3_doubt` (`data/cinematics/src/c_e3_doubt.cine`, lines
`data/voice/lines/c_e3_doubt.json`) is the default telling only; its header notes the refused variant "needs a
branching film (not supported)". This file is that second film, **script only**: no `.cine`, no stage baked or
exported, nothing voiced. Plays after e3m3's victory instead of `c_e3_doubt` when `e3m3_refused` is true (the player won
e3m3 with `sec_refuse`, 0 uses of the Heart of the Hollow); StoryFlow then continues to e3m4's briefing as before.

What this file holds:
- **Film `c_e3_doubt_refused`** (1:05, 9 shots, **7 lines**): the same shots and cuts as `c_e3_doubt` (B01, D2-D8, N12),
  with three shots changed (D5, D7, D8: the stone stays dark). Lines file
  `docs/design/script-episodes-4-8/lines/c_e3_doubt_refused.json`; French: L1-L5 are the same text as `c_e3_doubt` and
  already translated in `data/i18n/fr/dialogue.po` (build.py skips them); L6-L7 are in `data/i18n/fr/story_e4_e8.po`.
- Lines L1-L5 are `c_e3_doubt` L1-L5 word for word (same timing); the existing WAVs can be reused. L6 is the spec's
  refused line; L7 is new.

## 1. What changes against `c_e3_doubt`
| Shot | `c_e3_doubt` | `c_e3_doubt_refused` |
|---|---|---|
| D5 | CU on the stone: the heart pulse VFX at 0.6, two stone thumps | The coat stays dark: no pulse, no thump at first; one faint thump (vol -24) late in the shot |
| D7 | The `lie` pulse at 1.4 as Malrik says "A little." | No pulse: the stone stays dark while he speaks |
| D8 | Aldra "It glowed when he lied." / Torvald "I know. I saw." | Aldra "It didn't glow at all. That frightens me more." (L6) / Torvald "Then it is waiting." (L7) |

To build it later: copy `c_e3_doubt.cine` to `c_e3_doubt_refused.cine`, drop the D5 / D7 pulse and thump cues (keep one
thump at D5 + 4.0, vol -24), swap the D8 lines, add a `STORY_FILMS` branch on `e3m3_refused`.

## 2. Open questions (story, flagged, not decided)
| # | Where | Point |
|---|---|---|
| Q1 | Who refuses | JS's brief says "the variant where Torvald refuses"; in the specs the flag `e3m3_refused` is set by the **player** (Malrik) winning e3m3 without the stone (`sec_refuse`). Torvald refuses nothing on screen here: the film is his reading of a stone that stayed dark. If JS meant a Torvald refusal (for example Torvald refusing Malrik's company after the talk), it needs a new beat. |
| Q2 | L7 | New line. "Then it is waiting." (the stone did not glow because Malrik never fed it; Torvald reads that as patience, not peace). Alternative: no answer at all, Torvald silent on the push. |
| Q3 | L5 | "A little. Less than you would think." is now true (he paid nothing): the line is kept so both takes share D7, and the dark stone is what tells the player he did not lie. |
| Q4 | Wiring | The game has no branching film: StoryFlow must pick the film id by flag (`e3m3_refused` -> `c_e3_doubt_refused`, else `c_e3_doubt`). Code change, not part of this script. |
| Q5 | French | L6 « Elle n'a pas brillé du tout. Ça me fait encore plus peur. » and L7 « Alors elle attend. » keep the stone feminine, as `c_e3_doubt` L6 « Elle a brillé quand il a menti. ». |

<!-- LINES:BEGIN (generated from the script sources; edit the sources, not this block) -->

### Lines: `c_e3_doubt_refused` (7 lines, `docs/design/script-episodes-4-8/lines/c_e3_doubt_refused.json`)

**Film `c_e3_doubt_refused` "Torvald's Doubt (the stone refused)"**: ENGINE stage (second take of `c_e3_doubt`, played instead of it when `e3m3_refused`), 1:05 (the same 9 shots and cuts as `c_e3_doubt`), set `forge_evenmead` (marks B01 N12, puppets malrik / hush / torvald / stone; Aldra off screen as in `c_e3_doubt`), night = the ep3_ending dark-blue grade; axis: the Ep3 rule (every camera east of the Malrik - Ysolde line). Source: docs/design/mission-e3-03.md Cinematic hooks (`c_e3_doubt`, the `e3m3_refused` variant: Aldra "It didn't glow at all. That frightens me more."); shots mirror data/cinematics/src/c_e3_doubt.cine.

| Shot | Time | Camera | Setting, who, what they do | Lines |
|---|---|---|---|---|
| B01 | 0:00-0:09 | FADE_BLACK 1.2 in; the B01 mark, WIDE | The Evenmead ridge at night, dark-blue grade; two small fire pillars on the far bank. Same as `c_e3_doubt` B01 | - |
| D2 | 0:09-0:17 | MS on Torvald, 3/4 left, eye, slow push | Torvald's pavilion: Torvald listens, neutral; Aldra (off screen) sets down her report; ice creak | L1, L2 |
| D3 | 0:17-0:22 | MCU on Torvald, 3/4 left, eye | Torvald, worried, looks across the river | L3 |
| D4 | 0:22-0:29 | MS on Malrik and Hush, 3/4 left, eye | Malrik comes back up the ridge, Hush a step behind him; snow steps, armour. The stone is under his coat as in `c_e3_doubt` | - |
| D5 | 0:29-0:35 | CU on the stone, high, blend in 0.3 | **Changed**: the coat over the stone stays dark. No pulse VFX, no thump: two seconds of wind only, then one faint thump far under the sound (vol -24) as if it waits | - |
| D6 | 0:35-0:41 | MS on Torvald, 3/4 left, eye | Torvald watches the coat, not Malrik's face, and asks | L4 |
| D7 | 0:41-0:47 | MCU on Malrik, 3/4 left, eye | Malrik smiles and answers. **Changed**: no `lie` pulse at 1.4; the stone stays dark while he speaks | L5 |
| D8 | 0:47-0:55 | MS on Torvald, 3/4 left, eye, push 0.2 | Malrik and Hush are gone. **Changed**: Aldra's line is the spec's refused line; Torvald does not turn to her, he keeps looking at where the stone was, worried | L6, L7 |
| N12 | 0:55-1:05 | N12 mark, long lens across the valley to Lark Hill, blend in 0.4; fade out 1.2 at 8.8 | Same as `c_e3_doubt` N12: one storm flicker on Lark Hill, then black | - |

Review sheet (the `film-text-review.md` 3 format; `at` / `s` in the shot; sub `/` = line break):

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c_e3_doubt_refused.1 | aldra | The old storm-sword crossed the river twice today. | La vieille épée-tempête a traversé la rivière deux fois aujourd'hui. | D2: Torvald's pavilion: Torvald listens, neutral; Aldra (off screen) sets down her report;... (at 0.6, 3.6 s; sub: The old storm-sword crossed / the river twice today.) | yes |
| c_e3_doubt_refused.2 | aldra | He only looked at the ridge. Then he went back. | Il a seulement regardé la crête. Puis il est reparti. | D2: Torvald's pavilion: Torvald listens, neutral; Aldra (off screen) sets down her report;... (at 4.2, 3.5 s; sub: He only looked at the ridge. Then he went back.) | yes |
| c_e3_doubt_refused.3 | torvald | He is counting us. | Il nous compte. | D3: Torvald, worried, looks across the river (at 0.6, 2.5 s; sub: He is counting us.) | yes |
| c_e3_doubt_refused.4 | torvald | What did it cost you, Malrik? In Duskbarrow. | Combien ça t'a coûté, Malrik ? À Duskbarrow. | D6: Torvald watches the coat, not Malrik's face, and asks (at 0.4, 3.3 s; sub: What did it cost you, Malrik? In Duskbarrow.) | yes |
| c_e3_doubt_refused.5 | malrik | A little. Less than you would think. | Un peu. Moins que tu le penses. | D7: Malrik smiles and answers. **Changed**: no `lie` pulse at 1.4; the stone stays dark... (at 0.5, 2.9 s; sub: A little. Less than you would think.) | yes |
| c_e3_doubt_refused.6 | aldra | It didn't glow at all. That frightens me more. | Elle n'a pas brillé du tout. Ça me fait encore plus peur. | D8: Malrik and Hush are gone. **Changed**: Aldra's line is the spec's refused line;... (at 1.6, 3.4 s; sub: It didn't glow at all. That frightens me more.) | yes |
| c_e3_doubt_refused.7 | torvald | Then it is waiting. | Alors elle attend. | D8: Malrik and Hush are gone. **Changed**: Aldra's line is the spec's refused line;... (at 5.4, 2 s; sub: Then it is waiting.) | **no** |

<!-- LINES:END -->
