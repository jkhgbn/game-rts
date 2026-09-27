# Four Wizards RTS (prototype)

The God Wizard gave each of his four apprentices a kingdom, then vanished.
Now they race to collect his lost artifacts.

This is a playable prototype of Mission 1, "Ruins of the Ember Crown". You play the Fire Wizard.
Fight through the Shadow kingdom's army and reach the Ember Crown in the north-east. If your wizard dies, you lose.

## Open it
1. Desktop shortcuts: "Four Wizards - Play" runs the game, "Four Wizards - Editor" opens it in Godot 4.7.
2. Or: Godot 4.7 Project Manager > Import > pick this folder's `project.godot`, then press F5.

## Controls
| Action | Input |
|---|---|
| Select | Left click, or drag a box |
| Add to selection | Shift + click / drag |
| Select all of one type on screen | Double-click a unit |
| Move / attack | Right click ground / enemy |
| Fireball | F, then left click (right click cancels) |
| Stop | S |
| Select wizard / find wizard | F1 / Space |
| Pan camera | Arrow keys or mouse at screen edge |
| Zoom / rotate | Mouse wheel / hold middle mouse and drag |
| Restart | R |

## Files
- `scripts/units/`: Unit, Wizard (hero), Projectile
- `scripts/ui/`: RTS camera, selection and orders, HUD
- `scripts/world/main.gd`: builds the map, spawns armies, unit stat table, victory/defeat
- `scripts/campaign/artifact.gd`: the artifact pickup
- `tests/smoke_test.gd`: automatic play-through (see CLAUDE.md)

## Working with Claude agents
See `CLAUDE.md` and `docs/plan/waves.md`. Start `claude` in this folder and say: "run wave 1 day 1 design".
