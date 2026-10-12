# Decisions

One line per decision, newest at the top of each section. **Who:** `JS` (JS decided), `lead` (lead default, JS can
change it), `lead -> JS` (lead proposed, JS approved). Never re-ask what is here. Game-design answers per feature also
live in each spec's "User decisions" section (`docs/design/*.md`) and in `docs/plan/waves.md` (steps 9-19).

## How we work
| Date | Decision | Who | Source |
|---|---|---|---|
| 2026-10-12 | Fix the verified bot bugs (docs/handoff/bot-review-2026-10-12.md) after the Shadow / Fire balance study, then re-check balance | JS | lead session 2026-10-12 |
| 2026-10-12 | Remove playtest worktree play3 (disk; lab outputs only). play and casters kept | JS | lead session 2026-10-12 |
| 2026-10-12 | Remove playtest worktrees play2 and play4 (disk space; only lab outputs inside) | JS | lead session 2026-10-12 |
| 2026-10-12 | Claude setup: hooks (Godot gate, no git in agents, ownership, GDScript check), skills /wave /ci-suite /playtest-release, reviewer agent, status split in 3 files, nightly CI on the laptop | lead -> JS | project thread 2026-10-12 |
| 2026-10-12 | Not doing: one worktree per agent (slow --import), cloud sessions (no Godot there), secrets in .env, GDScript LSP (needs the editor open) | lead -> JS | same |
| 2026-10-10 | Push to GitHub only when JS says so | JS | restart notes 10-10 |
| 2026-10-03 | Nothing is deleted without JS's word | JS | restart notes 10-03 |
| 2026-09-30 | All agents Opus 5.5 MEDIUM (`fw-art-medium` or the owner agent); labs catch quality | JS | CLAUDE.md effort rule |
| 2026-09-27 | Never Haiku; art at MEDIUM effort (blind trial winner) | JS | effort trial |
| 2026-09-26 | No Fable for UI specs any more; keep the existing Fable-made specs | JS | CLAUDE.md |
| 2026-09-26 | No time box for agents: quality first, especially art; art split into small pieces | JS | CLAUDE.md |
| 2026-09-26 | Godot runs through `tools/godot_run.ps1` (max 4 at once) | lead | 20-30 parallel runs made tests slow |
| 2026-09-25 | Talk to JS in Québec French; code, docs and game text in English | JS | CLAUDE.md |

## Game
| Date | Decision | Who | Source |
|---|---|---|---|
| 2026-10-11 | T3 units are game changers: far above T1/T2; balance T3s against each other only | JS | jss_asks.md |
| 2026-10-10 | Blitz mode: 9 starting workers, 8-12 min average games | JS | jss_asks.md |
| 2026-10-06 | Multiplayer dropped (no design, no build) | JS | restart notes 10-06 |
| 2026-10-06 | Per-kingdom upgrade building (Forge) with attack / armor / range lines | lead -> JS | jss_asks.md |
| 2026-09-28 | STR / INT path picked at match start, locked | JS | jss_asks.md, level-boons.md 14 |
| 2026-09-28 | LimboAI and Dialogue Manager removed (parked zip) | JS | jss_asks.md |
| 2026-09-27 | Every kingdom pop cap 200 (keep +20, 9 houses x +20) | lead -> JS | CLAUDE.md Kingdoms |
| 2026-09-26 | Frost Wyrm stays a wingless serpent | JS | waves.md 779 |
| 2026-09-26 | Art Lab B1 counts meshes after the kit merge (render cost) | JS | old lead-status |
| 2026-09-26 | Gold is a 3rd resource; thieves neutral, raid caravans and remote workers after 8:00; hunters = autonomous contracts | JS | market-trade.md 0 |
| 2026-09-26 | Champions pick a class at L2 (Spear / Sword & Shield / Two-Hand / Wizard); class skills add to the 3 archetype abilities | JS | skills-rework.md |
| 2026-09-26 | Champions are never directly controlled (bounties, layout, essence only); the wizard stays under direct control | JS | champions.md |
| 2026-09-26 | Silkroad-style classes to 110 = a future game, not Four Wizards | JS | waves.md 498 |
| 2026-09-26 | Titans: no max count (cost, pop, time and counters limit them) | JS | cavalry-mounts.md |
| 2026-09-25 | Lose the wizard = lose the mission (skirmish: respawn at the keep) | JS | gdd.md |
