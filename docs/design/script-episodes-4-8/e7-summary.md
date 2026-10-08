# Episode 7 "Gold for Fire": story script summary

Written 2026-10-08. Sources: `campaign-outline.md` 3.7, `mission-e7-01.md`..`mission-e7-04.md`, `episode7-opening.md`.
Template: Episode 4 (`e4m1.md`, `lines/e4m1.json`, `lines/c_e4_refuge.json`). Status: script only; nothing voiced, no
`.cine` written, lines files not yet moved to `data/voice/lines/`.

The four mission scripts, the eight lines files and the French were written by the Episodes 4-8 script pass
(files dated 2026-10-08 06:18). This summary counts them and collects their open questions, plus the points a second
reading of the specs found that those files do not flag yet (section 3).

## 1. Files and counts

| Film / mission | Kind, length | Script (shot list, open questions) | Lines file | Lines | Spec words | New lines |
|---|---|---|---|---|---|---|
| `ep7_opening` "Gold for Fire" | Opening film, 3:26 | `docs/design/episode7-opening.md` 3-4 (**not rewritten**; still titled `ep5_opening`, "Episode 5") | none yet | 34 in the script (21 Ossavar) | - | - |
| `e7m1` "The Dragon Auction" | Mission, 22-28 min | `e7m1.md` | `lines/e7m1.json` | 41 | 41 | 0 |
| `c_e7_ledger` "Clean Coin" | Between-scene, 1:10 | `e7m1.md` | `lines/c_e7_ledger.json` | 10 | 3 | 7 |
| `e7m2` "First Blood, and No Further" | Mission, 18-24 min | `e7m2.md` | `lines/e7m2.json` | 33 | 33 | 0 |
| `c_e7_mask` "Mourning" | Between-scene, 1:10 | `e7m2.md` | `lines/c_e7_mask.json` | 9 | 4 | 5 |
| `e7m3` "The Outwall" | Mission, 20-25 min | `e7m3.md` | `lines/e7m3.json` | 32 | 32 | 0 |
| `c_e7_pits` "The Year Comes Round" | Between-scene, 1:10 (2 Ossavar takes) | `e7m3.md` | `lines/c_e7_pits.json` | 12 | 6 | 6 |
| `e7m4` "The Year of Two Skies" | Mission, 25-30 min | `e7m4.md` | `lines/e7m4.json` | 47 | 47 | 0 |
| `ep7_ending` "No. Not for Now." | Episode ending, 1:10 | `e7m4.md` | `lines/ep7_ending.json` | 6 | 5 | 1 |
| **Total (without `ep7_opening`)** | | | | **190** | **171** | **19** |

- Mission lines: 153 (the specs' dialogue tables word for word, outcome and flag variants included). Film lines: 37.
- In-mission films (mission lines only, shots restated from the specs): `e7m1_arrival`, `e7m1_laurel`, `e7m1_dusk`;
  `e7m2_morning`, `e7m2_herald`, `e7m2_laurel_call`, `e7m2_knives`, `e7m2_mask`; `e7m3_outwall`, `e7m3_boats`,
  `e7m3_unmask`, `e7m3_dawn`; `e7m4_dawn`, `e7m4_two_skies`, `e7m4_turn`, `e7m4_still` (16 films).
- French (`data/i18n/fr/story_e4_e8.po`, appended): 189 of the 190 lines have an entry or a reference there. Two reuse an
  older entry: `e7m4` L22 "No." shares `c_e4_frontier` L4's entry; `c_e7_pits` L11 "Tomorrow." has no entry in this file
  because `dialogue.po` already holds "Tomorrow." (`ep3_ending` L4): when the lines move to `dialogue.po`, skip it.
- Speakers: `torvald`, `aldra`, `malrik`, `hush`, `obren`, `vessa`, `ysolde` (in `cast.json`); **new**: `ossavar`,
  `herald`, `dacian`, `seraphine` (E7M1.O1), `brannet`, `diamond_archon` (E7M3.O1). `ossavar` is the narrator for the
  whole episode (e7m1 D11).
- Voice time (rough): mission lines ~770 s (5 s slots, 4 s / 6 s where the specs say), film lines ~120 s.

## 2. Open questions already flagged in the mission scripts (not decided)

| File | Questions |
|---|---|
| `e7m1.md` | Q1 `ep7_opening` has no lines file, `.cine` or French and still reads "Episode 5" / "last year"; Q2 the 200 coins Aldra stacks were normally spent on the A2 bid; Q3 new ledger lines vs a silent beat; Q4 Ossavar narrates and listens on the roof in the same minute; Q5 no `forge_adamarch` / `forge_tollrock` sets yet; Q6 French terms for the glossary owner; Q7 « au coup de marteau » reads as an auction? |
| `e7m2.md` | Q1 new `c_e7_mask` lines; Q2 "For now" is Malrik's and the narrator's phrase in ep1 C1, not Torvald's; Q3 Ossavar's voice-over says the theme out loud; Q4 stand-in sets; Q5 "the Admiralty" in French; Q6 L26 placement; Q7 L18a "an Adamarch guest" (the first cut was Seraphine, a champion); Q8 the "Hush now" pun; Q9 L17 (96 characters) cannot split into 2 x 48: subtitle-only text proposed |
| `e7m3.md` | Q1 the Year of Two Skies has three dates (war year 612 = ~390 years, "six hundred years ago", "my great-grandmother"); Q2 which outcome gets which Ossavar take; Q3 new lines; Q4 Malrik's spec line split in two; Q5 stand-in sets; Q6 French names and register; Q7 `brannet` / `diamond_archon` not in `cast.json`; Q8 L25 + L26 can stack in `e7m3_dawn` |
| `e7m4.md` | Q1 L23 misquotes ep1 C1; Q2 the ring hand-over placed in the film; Q3 Aldra, Dacian, Seraphine silent; Q4 new opening line; Q5 no French episode title; Q6 FADE_WHITE vs the victory screen; Q7 stand-in set; Q8 the date (see e7m3 Q1); Q9 Brannet speaks off the field; Q10 « efface » |

## 3. Further points from a second reading (new; for the spec / lore owners)

| # | Where | Point |
|---|---|---|
| S1 | `e7m4` L37 | Malrik: "You never said no to anyone in your life. Why start with me?" comes a few minutes after L22-L23, where Torvald says "No." and Malrik answers "You said that once before". The player hears both. A taunt can lie, but the two lines fight each other. Spec words kept. |
| S2 | `c_e7_mask` (spec beat) | "You broke a truce older than both of us": the truce is ~130 years old. True for Malrik; Torvald's age is not fixed anywhere (Ep6 shows him "decades ago" with young Aldra). If he is older than 130, the line is wrong in his mouth. |
| S3 | `c_e7_pits` vs `e7m4` L15 | If the Archon agrees to empty the pits that night (her "Yes." in `c_e7_pits`, the e7m4 briefing's "with Malrik's hand on her pen"), her e7m4 L15 "Empty the pits. All of them." at P2 repeats an order already given. Read L15 as the public proclamation, or keep the night scene short of a decision? |
| S4 | `e7m2_mask` | The spec's shot list puts L24 (shot 2) before L23 (shot 3), but L23 (Dacian: "You knew before you came to the sand") reads as the opener and L24 as Torvald's answer. Cut order to settle when the cine is written. |
| S5 | `e7m4` L29 | "The one price he never tried": "he" is the Master, unnamed on screen; a player may hear Malrik. |
| S6 | `c_e7_ledger` | Ossavar gives Torvald a tip the same night whatever happened at A3, including when he flew for Aurivane (A3 lost, still a 2-of-3 win). The beat does not branch; is that right? |
| S7 | `e7m1` L10, L12 (French) | Kesh's gender is never stated (Morrow-of-Glass and Sunwake are "she"); the French needs one. |
| S8 | `e7m1` L22 (French) | "Where coin usually lies" (lie down / tell lies) has no French pun; translated plainly. |
| S9 | `ep7_opening` | The duel count and the chronicle in `episode7-opening.md` 1 still say "Last year: the Master vanishes" (campaign-outline D5 / C1 want "twelve years ago"), and the D2 rename edits (title, `ep5_opening` -> `ep7_opening`, `E5.*` -> `E7.*`) are still to do. Lead's edit; not touched here. |

## 4. What comes next (proposed, not scheduled)
1. Spec / lore owners answer section 2 and 3 (the date of the Year of Two Skies and the "For now" thread are the two that
   touch several files).
2. Voice Forge: audition and add the 6 new speakers, then render 190 lines (Ossavar at 0.88 speed: his 6 s slots).
3. A French reader reviews the Episode 7 entries in `story_e4_e8.po` (the glossary terms first: Ice-king, the Laurel,
   Sunblade / Diamond Wall, Your Radiance).
4. `ep7_opening` gets its lines file and French from `episode7-opening.md` 4.2 when the D2 rename lands.
