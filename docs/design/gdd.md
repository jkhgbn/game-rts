# Four Wizards RTS: game design document (one page)

Rewritten 2026-09-25 after the design-day docs were lost. Facts marked **(decided)** were agreed with the user.

## Story
- The God Wizard raised four apprentices, gave each a kingdom, then vanished.
- His regalia (the artifacts) lie scattered in ruins. Whoever gathers them becomes the next god.
- Each wizard leads their army in person as a hero unit. Lose the wizard, lose the mission **(decided)**.
- Vertical slice: **Vessa of Fire** goes after the **Ember Crown**, guarded by **Malrik's** Shadow forces **(decided)**.

## The four kingdoms
| Kingdom | Wizard | School | Play style (one line) | Colour (`Color`) |
|---|---|---|---|---|
| Fire | Vessa | Pyromancy: burst, area damage, speed | Hit hard and fast, fragile ranged units, a fast rider | `(0.85, 0.30, 0.12)` |
| Ice | Torvald | Cryomancy: slow, freeze, walls | Tough slow units, control the field | `(0.45, 0.75, 0.95)` |
| Nature | Ysolde | Verdancy: growth, healing, swarm | Cheap units that regrow, many bodies | `(0.35, 0.70, 0.25)` |
| Shadow | Malrik | Umbramancy: life drain, ambush | Elite heavy units, hero that heals by hurting | `(0.42, 0.22, 0.60)` |

Only Fire and Shadow exist before wave 5. The other two are names and colours only.

## Core loop (one mission)
1. Workers mine mana crystals from crystal nodes and carry them to the keep (`economy.md`).
2. The keep trains units (5 per kingdom, `units-fire-shadow.md`) up to the population cap.
3. The player leads the army with attack-move, hold, control groups and the wizard's spell.
4. Reach and claim the artifact.

## Win / lose rules (decided)
| Event | Result |
|---|---|
| Player's wizard reaches the artifact (`pickup_radius` 2.2 m) | **Victory**, `Events.mission_ended(true)` |
| Player's wizard dies | **Defeat immediately**, no revive, `Events.mission_ended(false)` |
| Enemy wizard dies | Not a win. Message "Malrik has fallen back into the shadows"; his units stay and fight |
| All player units dead but wizard alive | Nothing; the wizard can still walk to the artifact |

## Resources and population (decided)
- One resource: **mana crystals**. Start: **250 crystals, 3 workers**.
- Population: basic units 1, Blaze Rider 2, Shadow Knight 3, wizards 0. Cap 20 from the keep. Mission 1 starts at **12 / 20**.

## Controls
| Input | Action |
|---|---|
| Left click / drag | Select. Shift adds. Double-click selects all of that type on screen |
| Right click ground / enemy / crystal node | Move / attack / gather (workers). With the keep selected: set rally point |
| A, H, S, M, G | Attack-move, hold position, stop, move, gather (then click) |
| F | Fireball (then click a point). Also a button in the command card |
| Ctrl+1..9 / 1..9 / double-tap 1..9 | Set group / select group / centre camera on group |
| F1, Space | Select the wizard / centre camera on the wizard |
| Esc | Cancel a pending targeted order |
| Arrows or screen edge, wheel, middle drag | Pan, zoom, rotate camera |

Keys use **physical keycodes** (AZERTY keyboard): a hotkey is a QWERTY position, and the command card shows the letter
printed on that key of the player's own keyboard (UX.1 `KeyLabels`: W on the Z-position key on AZERTY). Every unit,
building, upgrade and spell button shows its own key (2026-09-29, `ui-hud.md` "Every button shows its own key").

## Vertical-slice scope (waves 1-3)
| Wave | Adds |
|---|---|
| 1 | Economy (nodes, workers, keep training, pop cap), attack-move, hold, control groups, Malrik + Shadow Lance, top bar, command card, minimap. No buildings other than the keep, no enemy economy; Shadow forces are pre-placed |
| 2 | Spell framework, 3 spells per wizard, building placement, fog of war |
| 3 | Mission 1 script, enemy AI that gathers, builds, trains and attacks |

Out of scope for the slice: Ice and Nature, multiplayer, campaign map, hero levelling.

## Done when (wave 1, whole team)
- [ ] Mission starts with Vessa, 250 crystals, 3 workers, 12 / 20 pop, at `PLAYER_START`.
- [ ] Workers mine, the keep trains all 5 Fire units, the cap blocks at 20.
- [ ] Vessa dying ends the mission at once with DEFEAT; claiming the Ember Crown gives VICTORY; killing Malrik does neither.
- [ ] Every hotkey in the table above works on the user's AZERTY keyboard by position.
