# JS's asks and ideas to make the game better

One place for every prompt and extra idea JS gives. Newest at the top of each section. Status: `todo`, `doing`, `done`, `parked`.
When JS asks for something new, add a line here first, then work on it.

## Open

| Date | Ask (JS's words, short) | Status | Where |
|---|---|---|---|
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
