class_name VfxText
extends RefCounted
## Player text shown by the VFX listeners (scripts/vfx: trade popups, route line chip, map-fill popups), review V1-5.
## Whole sentences through Loc (localization.md), kept here in scripts/ui so the string extractor finds them (it does
## not scan scripts/vfx). English output is unchanged.

## The map-fill hint at 0:40 (MapfillPopups.HINT_TEXT is the same English text).
static func capture_hint() -> String:
	return Loc.t("Stand near a watchtower, well or shrine with soldiers to capture it")


## `Magpies raid your miners at <where>!`: `where` = &"natural" / &"rich" / &"remote" (no name), else `node_name`.
static func raid(where: StringName, node_name: String = "") -> String:
	match where:
		&"natural":
			return Loc.t("Magpies raid your miners at the natural node!")
		&"rich":
			return Loc.t("Magpies raid your miners at the rich node!")
		&"remote":
			return Loc.t("Magpies raid your miners at a remote node!")
	return Loc.t("Magpies raid your miners at {node}!", {"node": Loc.sink(node_name)})


static func loot_picked(amount: int) -> String:
	return Loc.t("Picked up a loot sack: {n} gold", {"n": amount})


## `Bought Masons' Charter` (the ware name is data: shown through the sink).
static func ware_bought(ware_name: String) -> String:
	return Loc.t("Bought {name}", {"name": Loc.sink(ware_name)})


## The route chip's parts (RouteLine.RouteChip.parts_for): `far` / `near`...
static func route_distance(far: bool) -> String:
	return Loc.t("far") if far else Loc.t("near")


## ...`119 gold / trip · ~104 / min`...
static func route_value(gold: int, per_min: int) -> String:
	return Loc.t("{gold} gold / trip · ~{per_min} / min", {"gold": gold, "per_min": per_min})


## ...and `Current route`.
static func current_route() -> String:
	return Loc.t("Current route")
