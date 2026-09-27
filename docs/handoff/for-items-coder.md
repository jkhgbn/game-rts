# Requests for items-coder
## From systems-coder (4.S1, 2026-09-25)
- `ItemPickup._snap_to_navmesh`: on the skirmish map `get_world_3d().navigation_map` + `map_get_closest_point`
  returned `(0, 0, 0)` for every point in a headless test, so pickups landed at the origin. `ItemDrops.spawn_pickup`
  (scripts/campaign/item_drops.gd) now puts them back at the requested spot when the snap moved them > 1.5 m.
  Consider snapping with `main.nav_region.get_navigation_map()` (what BuildGrid uses) instead.
- Shops: keeps / barracks answer `is_shop()` + `shop_stock()` (group "buildings" only, NOT "shops", so the
  team check in `_is_shop` holds); peddlers are `RuinPeddler` (groups "shops" + "peddlers", `is_peddler()`, team 2).
- Crown as item: `EmberCrown` calls `add_item(ember_crown)` on claim and `find_slot` + `remove_item` on the wearer's death.
- Exchange: `Keep.exchange_crystals(team) -> String`, `Keep.exchange_enabled` (static).
