class_name WatchKeep
extends Keep
## Mission 0's Emberfall watch-keep (docs/design/mission-00.md "Watch-keep", data/buildings/fire_watch_keep.tres):
## a Fire keep that shoots and counts for defeat, but trains nothing (`trains` is empty in its type), is not a
## crystal drop-off and not a shop.


func is_drop_off() -> bool:
	return false


func is_shop() -> bool:
	return false
