# JS's asks and ideas to make the game better

One place for every prompt and extra idea JS gives. Newest at the top of each section. Status: `todo`, `doing`, `done`, `parked`.
When JS asks for something new, add a line here first, then work on it.

## Open

| Date | Ask (JS's words, short) | Status | Where |
|---|---|---|---|
| 2026-10-12 | "review all the code in the project" | done (all verified fixes committed 2026-10-12 night) | `scripts/` (~135k lines outside scripts/ai): ~22 read-only reviewers in waves, verify pass, fixes via owners; findings in `docs/handoff/code-review-2026-10-12.md` |
| 2026-10-12 | "can u review all game bot program and look for possible error" | done | `scripts/ai/` (4 read-only reviewers, fixes via ai-coder) |
| 2026-09-28 | Rework the faces of the 5 main wizards: eyes, smile, facial expressions | doing | `art/units/wizards/`, Aldra assumed as the 5th |
| 2026-09-28 | Rework the hair of the 5 wizards too, then put faces and hair in both films (re-render Ep 3, Ep 4 and the prologue; JS watches when finished) | doing | `docs/art/hair-redesign-plan.md` |
| 2026-09-29 | Prologue: when the king gives the laurel (or similar) a character looks like he is flying, fix it | doing | `data/cinematics/src/prologue_3min.cine` |
| 2026-09-29 | Blender file of the prologue castle, epic quality, after a 30 s fast script voiced by the Master (Kokoro) | doing | `art/blender/prologue_castle/` |
| 2026-09-29 | Hotkey should show on the unit or building it belongs to (JS, garbled: "hotkey should the unit or building it its") | doing | `scripts/ui/command_card.gd`, `docs/design/ui-hud.md` |
| 2026-09-30 | Caster-only support units like SC2 Medivac or Infestor: list them and add 1 per kingdom (4 wizards) | doing | `docs/design/caster-units.md` |
| 2026-10-01 | Not sure units can get better (tier up) in the last build: make sure there is a clear way to upgrade to better units, ASAP (JS, garbled) | doing | `docs/design/tiers.md`, keep card |
| 2026-10-02 | More story missions: write the scripts, a possible ending, and say how long the RTS story mode is and how many missions remain | doing | `docs/design/campaign-outline.md` |
| 2026-10-02 | More maps, easy to make; I pick the number and technique (30+ maps) | doing | `docs/design/map-production.md` |
| 2026-09-28 | Basic eyes, lips, expression, ears and hair on ALL units, then remake the movies | doing | face kit first (`art/units/kit/`), then one wave per faction, champions, helpers, neutrals |
| 2026-09-28 | Render Ep 3 and Ep 4 films to video, cutscene art at 90 or more | doing | `art/cinematics/`, `docs/tools/cine/` |
| 2026-09-28 | List of in-game art under 90 and what it needs | todo (list written, work not started) | `docs/art/ingame_grade/under_90.md` |
| 2026-09-27 | Skill points / level boons with Luck and rarity | todo (design only) | `docs/design/level-boons.md` |
| 2026-09-28 | Confirm Ep 5/6/7 order, rename `episode5-opening.md` to Ep 7 | todo | `docs/design/episode5-opening.md` |

## Done

| Date | Ask | Result |
|---|---|---|
| 2026-09-28 | Remove LimboAI and Dialogue Manager | Parked in `Documents\four-wizards-parked\parked_addons.zip`, out of the repo |
| 2026-09-28 | STR and INT in the game? | Yes, shipped (`scripts/units/str_int_path.gd`) |

## Loose ideas (not asked yet, worth keeping)

- Silkroad-style classes and skills to level 110 for a future game (in Four Wizards only champions pick classes).

- 2026-10-06: 'if we dont have we should have upgrade building where u upgrade unit' -> no unit-upgrade building exists (only Bazaar wares like Tempered Steel). Plan: per-kingdom Forge/Armory with attack/armor/range upgrade lines, researched with crystals, bots use them. Design + build agent launched; plan unchanged otherwise (new item after localization).

- 2026-10-06: 'does the mission introduce a unit per level if possible, like fire episode 3 this is X unit, show the best case for the unit or close to it' -> outline has a New/unlocked column (kits, casters, T3, titans) but no designed showcase moments. Plan: unit-spotlight pass over all mission specs (each introduces 1 unit with a best-case encounter, derived from Unit Lab matchups) + intro card; docs first, built missions 1-4 patched after.

- 2026-10-06: 'try to optimize to have like 4 mission per wizzard' -> read as: restructure the campaign so each of the 4 wizards plays about 4 missions (16 core + Episode 8 finale), merging/cutting the rest, keeping the best beats and unit spotlights. Design proposal only (docs/design/campaign-4-per-wizard.md), current outline untouched until JS approves.

- 2026-10-06: 'try to buff or nerf unit or add siege unit to give huge position advantage and finish game faster, try both' -> two experiments measured on bot-vs-bot match length (variant A: stat/pacing buff-nerf; variant B: new/stronger siege units), then recommend.

- 2026-10-08: 'try to make most of them when u can ... u can work on it all night' -> build scripted cinematics (timelines) for most missions (e2m1-e2m5, e3m1-e3m4, m01-m04 gaps, ep3_opening wiring, ep3/ep4 endings), Opus medium agents, commit per block, stop at ~95 % of the 5-hour meter. Plan unchanged (campaign-outline sections 3.2-3.4 already call for ENGINE scenes).

- 2026-10-08: "maybe sometime it zoom and its not on the item they say" -> framing audit of all films: shots that zoom on the wrong subject vs the line spoken; fix camera targets. Plan unchanged.

- 2026-10-08: "pour les parties plus courtes, pourquoi ne pas commencer avec plus de recolteurs" -> faster-games experiment C: more starting workers (and combo with A2), measured like A/B; nothing enabled by default.

- 2026-10-10: "maybe in the future add a blitz mode where game and all is faster" -> future idea: Blitz mode (whole game faster: economy, production, movement, timers, maybe game speed x1.25-1.5), building on the Pace Fast (test) switch (f4d9d4a0). Not started.

- 2026-10-10: "work on blitz for the rest, i want like 9 worker start and 8 to 12 min game avg" -> Blitz mode started: 9 starting workers, tuned so bot-vs-bot median is 8-12 min with fair kingdoms; built on the Pace switch.

- 2026-10-11: "i think t3 should be game changer so maybe make according and run new test" -> T3 design rule: T3 units stay far above T1/T2 (game changers); balance T3s against each other (weak ones Shardguard, Briar Roc up; Juggernaut down within T3); T1/T2 untouched.

- 2026-10-13: "ok continue working on the game i will playtest when i can" -> doing: (1) Shadow / Mother Hush compensation for the normal-pace Fire > Shadow drift (keeps fix R2-3), (2) Ice weak (Blitz 29 %, normal 39 %), (3) mission sims that still fail (e3m1, e5m4, e6m2), measured before / after.
- 2026-10-13: "i just play wave stike and it need more caster unit and way unit not sure if its a game limitation but we need more unit and more on the screen" -> doing: Wave Strike M2 roster (wave-strike.md 4.4 full card sets: T1 / T2 / caster / T3 per kingdom, tiers) + bigger waves on screen (supply caps / field cap within the perf budget). M1 shipped only 4 cards per kingdom and a 24-56 pop cap.
- 2026-10-13: "add more music and song" -> doing: music plan (docs/design/music.md: ~12-16 original code-synthesised tracks, kingdom themes, combat layer, stingers, playlists; sung songs = question for JS) then a music generator tool + GameAudio contexts.
- 2026-10-13: "try to have a ui more like sc2" (reference: StarCraft II LotV in-game HUD) -> doing: ui-sc2-console.md (one continuous bottom console: minimap, selection, portrait, 5x3 command card with hotkeys; compact resources top-right; keys help off-screen), layout conventions only, original art.
- 2026-10-13: "make it so i can play and place unit like u can in the real desert stike" -> doing: Wave Strike deployment pad (wave-strike.md 15): each bought copy placed on a personal grid by the gate, every horn re-spawns the army in that formation; bot auto-formations; then UI / systems / ai tasks.
- 2026-10-13 night: "ok je vais sleep essais de travailler sur le jeu et si possible de ajouter des upgrade pour le unie" -> doing overnight: Wave Strike unit upgrades (wave-strike.md 16: the 4.4 Armoury + per-card Desert-Strike-style upgrades, bot buys them) on top of the deployment pad (15); B13 round 2 balance screens; icons. Read as Wave Strike (skirmish already has forge upgrades).
