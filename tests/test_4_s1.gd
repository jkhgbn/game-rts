extends SceneTree
## Task 4.S1: shops, Ruin Peddlers, Lost Caches, the camp drop, the crystal exchange and the campaign
## item save (docs/design/items.md). Skirmish map with the Shadow bot switched off.
## Run:  godot --headless --path . -s tests/test_4_s1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "4.S1"
const TIMEOUT_FRAMES := 900
const SCENE := "res://scenes/skirmish.tscn"

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _notes: Array[String] = []
var _cache: LostCache
var _opened: Array = []
var _open_frame := -1
var _reappeared := false


func _initialize() -> void:
	main = load(SCENE).instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 3000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 2:
		_check_static()
		_start_cache()
	if frame > 2 and _open_frame < 0:
		main.hero.global_position = _cache.global_position   # walk in
	if frame > 2 and _open_frame >= 0 and not _reappeared and _cache.is_available():
		_reappeared = true
		var dt := float(frame - _open_frame) / 60.0
		if dt < 0.9 or dt > 1.3:
			_errors.append("cache reopened after %.2f s, expected 1.0" % dt)
	if _reappeared or frame > TIMEOUT_FRAMES:
		if not _reappeared:
			_errors.append("test cache never opened / reopened (opened %d)" % _opened.size())
		for n in _notes:
			print("  note: ", n)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check_static() -> void:
	var fire := 0   # Unit.Team.PLAYER
	var shadow := 1
	# --- base shops
	var keep: Node = main.keep
	if not keep.is_shop() or keep.is_in_group("shops"):   # "shops" = neutral shops only (Inventory)
		_errors.append("keep is not a shop")
	var stock: Array = keep.shop_stock()
	# 10 items.md components + Frostglass Shard (step 7) + Verdant Seed (step 8) + 3 consumables.
	if stock.size() != 15 or not stock.has(&"ember_shard") or not stock.has(&"verdant_seed") or not stock.has(&"homeward_seal") or stock.has(&"warden_scale"):
		_errors.append("keep stock wrong: %s" % [stock])
	var barracks: Node = main.build_grid.spawn_complete(BuildingType.find("fire_barracks"), Vector3(-44, 0, 20), fire)
	if barracks == null or not barracks.is_shop():
		_errors.append("barracks is not a shop")
	# --- peddlers
	var peddlers: Array = []
	for n in get_nodes_in_group("shops"):
		if n is RuinPeddler:
			peddlers.append(n)
	if peddlers.size() != 2:
		_errors.append("%d peddlers" % peddlers.size())
	for p in peddlers:
		var pos: Vector3 = p.global_position
		if not (Vector2(absf(pos.x), absf(pos.z)).is_equal_approx(Vector2(22, 22)) and signf(pos.x) == signf(pos.z)):
			_errors.append("peddler at %s" % pos)
		if not p.is_shop() or int(p.team) != 2 or not p.shop_stock().has(&"vital_root"):
			_errors.append("peddler shop / team / stock wrong")
		if p.is_in_group("units") or p.is_in_group("buildings"):
			_errors.append("peddler is targetable")
		_check_clear(pos, 5.0, p)
	# --- caches
	var caches: Array = main.caches
	if caches.size() != 4:
		_errors.append("%d caches" % caches.size())
	for c: LostCache in caches:
		_check_clear(c.global_position, 3.0, null)
		if c.is_available() or absf(c.time_until_available() - 120.0) > 1.0:
			_errors.append("cache %s not waiting for 2:00 (%.1f)" % [c.name, c.time_until_available()])
		if not Skirmish.CACHE_SPOTS.has(Vector3(c.global_position.x, 0.0, c.global_position.z)):
			_errors.append("cache at %s" % c.global_position)
	# --- loot table
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var counts := {}
	for i in 10000:
		var loot: Dictionary = ItemDrops.roll_cache_loot(rng, 0.0)
		var key := "essence" if loot.has("essence") else String(loot["item"])
		if ShopStock.BASE_COMPONENTS.has(StringName(key)):
			key = "component"
		counts[key] = int(counts.get(key, 0)) + 1
	var want := {"essence": 0.40, "ember_draught": 0.20, "component": 0.15, "dusk_vial": 0.15, "warden_scale": 0.10}
	for k in want:
		if absf(float(counts.get(k, 0)) / 10000.0 - float(want[k])) > 0.02:
			_errors.append("loot %s %.3f, want %.2f" % [k, float(counts.get(k, 0)) / 10000.0, want[k]])
	if ItemDrops.cache_essence(0.0) != 80 or ItemDrops.cache_essence(300.0) != 100 or ItemDrops.cache_essence(1500.0) != 120:
		_errors.append("cache essence scaling wrong")
	# --- the 4th warden drops the camp items

	var wardens: Array = main.wardens.duplicate()
	for w in wardens:
		w.take_damage(1.0e6, main.hero)
	if main.wardens_killed != 4:
		_errors.append("wardens_killed = %d" % main.wardens_killed)
	if ResourceLoader.exists(ItemDrops.PICKUP_PATH) and ResourceLoader.exists("res://data/items/warden_scale.tres"):
		var near := 0
		for n in get_nodes_in_group("item_pickups"):
			if not n is Node3D:
				continue
			for spot: Vector3 in Skirmish.CAMP_DROP_SPOTS:  # step 12 split the drop: (2, 2) / (-2, -2)
				if (n as Node3D).global_position.distance_to(spot) < 2.0:
					near += 1
					break
		if near != 2:
			var where := []
			for n in get_nodes_in_group("item_pickups"):
				where.append((n as Node3D).global_position)
			_errors.append("camp drop: %d pickups at CAMP_DROP_SPOTS (all: %s)" % [near, where])
	else:
		_notes.append("items system not there yet: camp drop logged, nothing spawned")
	# --- exchange
	var eco: Economy = Economy.for_team(fire)
	eco.add(500)
	var before := eco.crystals
	var bank: Object = Keep.essence_bank_for(fire)
	var ess_before := int(bank.get(&"essence")) if bank else 0
	var r: String = keep.exchange_crystals(fire)
	if bank:
		if r != "" or eco.crystals != before - 100 or int(bank.get(&"essence")) != ess_before + 40:
			_errors.append("exchange: '%s', crystals %d -> %d" % [r, before, eco.crystals])
	elif r != "Essence not available" or eco.crystals != before:
		_errors.append("exchange without a bank: '%s'" % r)
	else:
		_notes.append("no EssenceBank yet: exchange refused cleanly")
	if keep.exchange_crystals(shadow) != "Not your shop":
		_errors.append("shadow exchanged at the Fire keep")
	# --- campaign save / load with a fake inventory
	var fake := {
		"slots": [{"type": &"blazing_edge", "count": 1, "cooldown_left": 0.0}, null,
				{"type": "ember_draught", "count": 2, "cooldown_left": 5.0}, null, null,
				{"type": &"vital_root", "count": 1, "cooldown_left": 0.0}],
		"artifacts": [{"type": &"ember_crown", "count": 1}, null],
	}
	var snap := CampaignItems.snapshot(fake, 3500, [&"masters_signet"])
	if CampaignItems.save_file(snap, "user://test_4_s1_items.json") != OK:
		_errors.append("campaign save failed")
	var loaded := CampaignItems.load_file("user://test_4_s1_items.json")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_4_s1_items.json"))
	var restored := {}
	var ess := CampaignItems.restore(loaded, restored)
	var rs: Array = restored.get("slots", [])
	if ess != 1500 or CampaignItems.carried_essence(1000) != 500:
		_errors.append("carried essence %d" % ess)
	if rs.size() != 6 or rs[1] != null or rs[0]["type"] != &"blazing_edge" or rs[2]["count"] != 2 \
			or rs[5]["type"] != &"vital_root":
		_errors.append("slots restored wrong: %s" % [rs])
	var ra: Array = restored.get("artifacts", [])
	if ra.size() != 2 or ra[0]["type"] != &"ember_crown" or ra[1] != null:
		_errors.append("artifacts restored wrong: %s" % [ra])
	var owned: Array = loaded.get("artifacts_owned", [])
	if not (owned.has("masters_signet") and owned.has("ember_crown")) or owned.size() != 2:
		_errors.append("owned artifacts %s" % [owned])
	# --- inventory glue
	if ResourceLoader.exists(ItemDrops.INVENTORY_PATH):
		if ItemDrops.inventory_of(main.hero) == null:
			_notes.append("inventory.gd exists but the hero has no inventory (ensure_for missing?)")
	else:
		_notes.append("no inventory.gd yet: ensure_for skipped")


func _start_cache() -> void:
	_cache = LostCache.new()
	_cache.first_delay = 0.2
	_cache.reopen_delay = 1.0
	_cache.rng.seed = 3
	main.add_child(_cache)
	_cache.global_position = Vector3(-40.0, 0.0, 40.0)
	_cache.opened.connect(func(_c: LostCache, w: Node, loot: Dictionary) -> void:
		_opened.append(loot)
		_open_frame = frame
		if w != main.hero:
			_errors.append("opened by %s" % w.name)
		if not (loot.has("essence") or loot.has("item")):
			_errors.append("empty loot"))


## No tree / rock / pillar (static bodies under the nav region) within `radius` of `pos`.
func _check_clear(pos: Vector3, radius: float, except: Node) -> void:
	for n in main.nav_region.get_children():
		if n == except or not n is StaticBody3D or n is Building or n is RuinPeddler:
			continue
		var p: Vector3 = (n as Node3D).global_position
		if p.length() < 0.5:
			continue   # the ground
		if Vector2(p.x - pos.x, p.z - pos.z).length() < radius:
			_errors.append("obstacle %s at %s inside the clearing of %s" % [n.name, p, pos])
