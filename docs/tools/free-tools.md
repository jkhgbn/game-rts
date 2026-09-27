# Free-tools pack (U7, 2026-09-27)

Installed for later tool passes; nothing in the game or the tools uses the addons yet.

| Item | Where | For | Licence |
|---|---|---|---|
| Phantom Camera v0.11.0.3 | `addons/phantom_camera/` | Cine camera driver: an optional `PhantomCamera3D` / `PhantomCameraHost` rig for `tools/cine` shots (follow, look-at, tweened blends, noise). | MIT (Marcus Skov), `addons/phantom_camera/LICENSE` |
| Proton Scatter 4.0 | `addons/proton_scatter/` | World Forge scatter engine: a future `scatter engine=proton` option (props / foliage scattered in shapes, with exclusion areas). | MIT (HungryProton), `addons/proton_scatter/LICENSE` |
| Cinzel, Alegreya (variable) | `assets/fonts/` | Game UI Theme `assets/ui/four_wizards_theme.tres`: Cinzel titles / headers, Alegreya body text (through `UIStyle.game_theme()`). | SIL OFL 1.1, `assets/fonts/*_OFL.txt` |
| game-icons.net SVGs | `assets/icons/game-icons/<author>/*.svg` | Source pool to fill missing icon slots. | CC BY 3.0 (a few CC0), `assets/icons/game-icons/license.txt` |

Status (2026-09-27)
- **Phantom Camera: enabled** (`[editor_plugins]` in project.godot). Enabling it by hand in project.godot skips the
  plugin's `_enable_plugin`, so its runtime autoload `PhantomCameraManager` was added to `[autoload]` too (PCam nodes
  fail without it). `phantom_camera/updater/updater_mode=0` turns off its GitHub update check in the editor.
- **Proton Scatter: installed, NOT enabled.** Under Godot 4.7.2 `addons/proton_scatter/src/scatter.gd:240`
  (`func _get(property)`) fails to parse ("Not all code paths return a value"), which breaks every Scatter script
  that depends on it. Fix before enabling: add `return null` at the end of that `_get`, re-run import + smoke + perf.

Notes
- The icon folder has a `.gdignore` (4,239 SVGs would slow every import): copy the icons you use into a normal
  folder (e.g. `assets/icons/`) so Godot imports only those. Credit the author folder in `CREDITS.md`.
- `addons/proton_scatter/demos/assets/source.blend` was removed on install: with no Blender path set, a `.blend`
  in the project makes every headless `--import` skip the whole reimport.
- Attribution for everything above lives in `CREDITS.md` at the repo root.
