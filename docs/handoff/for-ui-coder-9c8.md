# For ui-coder 9.C8 (from ui-coder 9.C7, step 9)

What 9.C7 built and how it meets your files (layout: `docs/design/ui-champions.md`).

## Champion view (selection_panel.gd, 9.C7)
- `SelectionPanel.refresh()` reads `selection.get("inspected")` first (your `var inspected: Unit`); when it is a
  champion (group `"champions"`, or `is_commandable() == false` with a `purse`) it shows the champion view and
  `current_view()` returns `"champion"`. Own champions stay shown while fallen; enemy ones are dropped when they die
  or `is_visible_in_tree()` turns false. A lone champion in `selection.selected` is shown the same way (fallback).
- Alternative push API (no need if you set `inspected`): `hud.selection_panel.inspect(champion)`; it is cleared on
  the next `selection_changed`, so call it after your own selection change.
- The command card's `Champions act on their own.` block (yours, done) is what shows the hint; my panel does not
  repeat it. `tests/test_9_c7.gd` checks it through `selection.inspect_unit(champion)`.

## Keys
- **Y** (tavern) and **F5 / F6 / F7** (find champion) are handled in `ChampionBar._unhandled_key_input`
  (physical keycodes, no modifiers). Please don't bind them in `selection_manager.gd`.

## Tavern click
- `hud.gd` already opens the tavern window on a left click on a node in group `"taverns"` (its `_unhandled_input`,
  the click is **not** consumed). It skips the click while `selection.get_pending_order() != &""` or while a node in
  group `"bounty_mode"` answers `is_active() == true` (your BountyMode does). If you also call
  `hud.tavern_window.open()` from the selection manager, that is harmless (opening twice just refreshes).

## HUD glue for your pieces (hud.gd, done)
- `GameHUD.setup` calls `FlagCard.attach(hud, selection)` and `BountyMode.attach(hud)` through guarded loads
  (`attach_optional(path, args)`), so the flag card and the chip exist in every level with a HUD.

## Shared helpers you may reuse (ChampionBar, static, duck-typed)
`ChampionBar.intent_text(ch, guild)`, `intent_color(text)` (13.1 table), `display_name_of(ch)`, `champion_id(ch)`,
`icon_of(id)` (`art/icons/units/<id>.png` or null), `initials(name)`, `draw_flame(ci, at, h)`, `draw_crystal(ci, at, h)`.
