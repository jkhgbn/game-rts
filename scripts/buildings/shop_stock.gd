class_name ShopStock
extends RefCounted
## What the shops sell (docs/design/items.md "Where items come from"). Base shops = completed keeps
## and barracks (TrainingBuilding.is_shop()); Ruin Peddlers (RuinPeddler) sell PEDDLER. Every shop,
## peddlers included, also combines any mid / top recipe (those ids are not listed here).

const SHOP_RADIUS := 12.0   ## A wizard within this many metres of a shop can buy, sell, combine, exchange.

## The 12 base components (also the Lost Cache "random base component" pool): the 10 of items.md,
## then Frostglass Shard (kingdom-ice.md 6) and Verdant Seed (kingdom-nature.md 5), sold at every base shop.
const BASE_COMPONENTS: Array[StringName] = [&"ember_shard", &"whetted_fang", &"ironbark_plate",
		&"wisp_lantern", &"duskglass", &"mana_thread", &"swiftsoles", &"bone_charm", &"cinder_ring",
		&"gloom_ink", &"frostglass_shard", &"verdant_seed"]
const BASE_CONSUMABLES: Array[StringName] = [&"ember_draught", &"dusk_vial", &"homeward_seal"]
## Owl Stone joins the peddler in wave 5 (needs fog of war).
const PEDDLER: Array[StringName] = [&"warden_scale", &"vital_root", &"ember_draught", &"dusk_vial",
		&"homeward_seal"]

## Exchange at a base shop (items.md "Essence"): 100 crystals -> 40 essence, no cap.
const EXCHANGE_CRYSTALS := 100
const EXCHANGE_ESSENCE := 40


## Base shop stock: the 12 components then the 3 consumables.
static func base() -> Array[StringName]:
	var out: Array[StringName] = []
	out.append_array(BASE_COMPONENTS)
	out.append_array(BASE_CONSUMABLES)
	return out


static func peddler() -> Array[StringName]:
	var out: Array[StringName] = []
	out.append_array(PEDDLER)
	return out
