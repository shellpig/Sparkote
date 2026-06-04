extends Node

# Signals
signal energy_changed(new_val: int)
signal energy_overflow
signal resources_changed
signal tile_revealed(map_id: String, tile_id: String)
signal map_unlocked(map_id: String)
signal today_changed
signal event_completed(event_id: String)
signal system_unlocked(system_id: String)
signal home_changed
signal diary_updated
signal day_advanced
signal state_loaded

# State variables
var game_day: int = 1
var all_completed_days_this_week: int = 0
var super_task_credits: int = 0
var energy: int = 0
var resources: Dictionary = {} # item_id -> count
var task_items: Dictionary = {} # item_id -> count
var unlocked_maps: Array = [] # map_id (String)
var revealed_tiles: Dictionary = {} # map_id -> Array of tile_id (String)
var collected_resource_points: Dictionary = {} # map_id -> { tile_id -> today_collect_count }
var flags: Dictionary = {} # flag_key -> Variant
var completed_events: Dictionary = {} # event_id -> { "day": int, "choice": int }
var repair_levels: Dictionary = {} # repair_id -> level (int)
var slot_furnitures: Dictionary = {} # slot_id -> furniture_id (String)
var owned_furnitures: Array = [] # furniture_id (String)
var owned_skins: Array = [] # skin_id (String)
var applied_skins: Array = [] # skin_id (String)
var collections: Array = [] # collection_id (String)
var purchased_products: Dictionary = {} # product_id -> bool
var daily_free_claimed: bool = false
var daily_ad_supply_claimed: bool = false
var daily_ad_extra_claimed: bool = false

var today_candidates: Dictionary = {
	"normal": [],
	"advanced": []
}
var today_selected: Dictionary = {
	"normal": [],
	"advanced": [],
	"extra_advanced": "" # Empty String means null/none
}
var today_completed: Array = []
var super_task_completed_today: bool = false
var favorite_tasks: Dictionary = {
	"normal": [],
	"advanced": []
}
var diary: Dictionary = {} # day_str -> Dictionary

func _ready() -> void:
	new_game()

func new_game() -> void:
	game_day = 1
	all_completed_days_this_week = 0
	super_task_credits = 0
	energy = 0
	resources = {}
	task_items = {}
	unlocked_maps = []
	revealed_tiles = {}
	collected_resource_points = {}
	flags = {}
	completed_events = {}
	repair_levels = {}
	slot_furnitures = {}
	owned_furnitures = []
	owned_skins = []
	applied_skins = []
	collections = []
	purchased_products = {}
	daily_free_claimed = false
	daily_ad_supply_claimed = false
	daily_ad_extra_claimed = false
	today_candidates = {
		"normal": [],
		"advanced": []
	}
	today_selected = {
		"normal": [],
		"advanced": [],
		"extra_advanced": ""
	}
	today_completed = []
	super_task_completed_today = false
	favorite_tasks = {
		"normal": [],
		"advanced": []
	}
	diary = {}

# Dictionary Serialization
func to_dict() -> Dictionary:
	return {
		"game_day": game_day,
		"all_completed_days_this_week": all_completed_days_this_week,
		"super_task_credits": super_task_credits,
		"energy": energy,
		"resources": resources.duplicate(true),
		"task_items": task_items.duplicate(true),
		"unlocked_maps": unlocked_maps.duplicate(),
		"revealed_tiles": revealed_tiles.duplicate(true),
		"collected_resource_points": collected_resource_points.duplicate(true),
		"flags": flags.duplicate(true),
		"completed_events": completed_events.duplicate(true),
		"repair_levels": repair_levels.duplicate(true),
		"slot_furnitures": slot_furnitures.duplicate(true),
		"owned_furnitures": owned_furnitures.duplicate(),
		"owned_skins": owned_skins.duplicate(),
		"applied_skins": applied_skins.duplicate(),
		"collections": collections.duplicate(),
		"purchased_products": purchased_products.duplicate(true),
		"daily_free_claimed": daily_free_claimed,
		"daily_ad_supply_claimed": daily_ad_supply_claimed,
		"daily_ad_extra_claimed": daily_ad_extra_claimed,
		"today_candidates": today_candidates.duplicate(true),
		"today_selected": today_selected.duplicate(true),
		"today_completed": today_completed.duplicate(),
		"super_task_completed_today": super_task_completed_today,
		"favorite_tasks": favorite_tasks.duplicate(true),
		"diary": diary.duplicate(true)
	}

func from_dict(d: Dictionary) -> void:
	game_day = int(d.get("game_day", 1))
	all_completed_days_this_week = int(d.get("all_completed_days_this_week", 0))
	super_task_credits = int(d.get("super_task_credits", 0))
	energy = int(d.get("energy", 0))
	resources = d.get("resources", {}).duplicate(true)
	task_items = d.get("task_items", {}).duplicate(true)
	unlocked_maps = d.get("unlocked_maps", []).duplicate()
	revealed_tiles = d.get("revealed_tiles", {}).duplicate(true)
	collected_resource_points = d.get("collected_resource_points", {}).duplicate(true)
	flags = d.get("flags", {}).duplicate(true)
	completed_events = d.get("completed_events", {}).duplicate(true)
	repair_levels = d.get("repair_levels", {}).duplicate(true)
	slot_furnitures = d.get("slot_furnitures", {}).duplicate(true)
	owned_furnitures = d.get("owned_furnitures", []).duplicate()
	owned_skins = d.get("owned_skins", []).duplicate()
	applied_skins = d.get("applied_skins", []).duplicate()
	collections = d.get("collections", []).duplicate()
	purchased_products = d.get("purchased_products", {}).duplicate(true)
	daily_free_claimed = bool(d.get("daily_free_claimed", false))
	daily_ad_supply_claimed = bool(d.get("daily_ad_supply_claimed", false))
	daily_ad_extra_claimed = bool(d.get("daily_ad_extra_claimed", false))
	today_candidates = d.get("today_candidates", {}).duplicate(true)
	today_selected = d.get("today_selected", {}).duplicate(true)
	today_completed = d.get("today_completed", []).duplicate()
	super_task_completed_today = bool(d.get("super_task_completed_today", false))
	favorite_tasks = d.get("favorite_tasks", {}).duplicate(true)
	diary = d.get("diary", {}).duplicate(true)
	state_loaded.emit()

# Energy management
func get_energy() -> int:
	return energy

func can_afford(cost: int) -> bool:
	return energy >= cost

func add_energy(amount: int, _source: String = "") -> int:
	var old_energy = energy
	var cap = Config.get_energy_cap()
	energy = clampi(energy + amount, 0, cap)
	
	var gained = energy - old_energy
	if old_energy + amount > cap:
		energy_overflow.emit()
	
	if gained != 0:
		energy_changed.emit(energy)
	return gained

func spend_energy(cost: int) -> bool:
	if energy < cost:
		return false
	energy -= cost
	energy_changed.emit(energy)
	return true

# Tasks management
func set_today_candidates(normal_ids: Array, advanced_ids: Array) -> void:
	today_candidates["normal"] = normal_ids.duplicate()
	today_candidates["advanced"] = advanced_ids.duplicate()
	today_changed.emit()

func choose_task(task_id: String, is_advanced: bool) -> bool:
	var slot_type = "advanced" if is_advanced else "normal"
	var current_selected = today_selected[slot_type]
	var limit = Config.get_daily_slots(slot_type)
	if is_advanced and daily_ad_extra_claimed:
		limit += 1
	if current_selected.size() >= limit:
		return false
	if not (task_id in current_selected):
		current_selected.append(task_id)
		today_changed.emit()
	return true

func unchoose_task(task_id: String, is_advanced: bool) -> bool:
	var slot_type = "advanced" if is_advanced else "normal"
	var current_selected: Array = today_selected[slot_type]
	var idx = current_selected.find(task_id)
	if idx != -1:
		current_selected.remove_at(idx)
		today_changed.emit()
		return true
	return false

func set_extra_advanced(task_id: String) -> void:
	today_selected["extra_advanced"] = task_id
	today_changed.emit()

func mark_task_completed(task_id: String) -> void:
	if not (task_id in today_completed):
		today_completed.append(task_id)
		today_changed.emit()

func is_task_completed(task_id: String) -> bool:
	return task_id in today_completed

func mark_super_task_done() -> void:
	super_task_completed_today = true
	today_changed.emit()

func save_favorite(task_id: String, is_advanced: bool) -> void:
	var slot_type = "advanced" if is_advanced else "normal"
	var limit = 3 if is_advanced else 6
	var favorites: Array = favorite_tasks[slot_type]
	if favorites.size() >= limit:
		return
	if not (task_id in favorites):
		favorites.append(task_id)
		today_changed.emit()

func remove_favorite(task_id: String, is_advanced: bool) -> void:
	var slot_type = "advanced" if is_advanced else "normal"
	var favorites: Array = favorite_tasks[slot_type]
	var idx = favorites.find(task_id)
	if idx != -1:
		favorites.remove_at(idx)
		today_changed.emit()

# Exploration
func is_tile_revealed(map_id: String, tile_id: String) -> bool:
	var tiles: Array = revealed_tiles.get(map_id, [])
	return tile_id in tiles

func is_adjacent_to_revealed(map_id: String, tile_id: String) -> bool:
	var map = Content.get_map(map_id)
	if map.is_empty():
		return false
	var tiles_data = map.get("tiles", [])
	var target_tile = null
	for tile in tiles_data:
		if tile.get("id") == tile_id:
			target_tile = tile
			break
	if not target_tile:
		return false
	var neighbors = target_tile.get("neighbors", [])
	for n_id in neighbors:
		if is_tile_revealed(map_id, n_id):
			return true
	return false

func mark_revealed(map_id: String, tile_id: String) -> void:
	if not (map_id in revealed_tiles):
		revealed_tiles[map_id] = []
	var tiles: Array = revealed_tiles[map_id]
	if not (tile_id in tiles):
		tiles.append(tile_id)
		tile_revealed.emit(map_id, tile_id)

func unlock_map(map_id: String) -> void:
	if not (map_id in unlocked_maps):
		unlocked_maps.append(map_id)
		map_unlocked.emit(map_id)

func is_map_unlocked(map_id: String) -> bool:
	return map_id in unlocked_maps

# Requirements Validation
func meets_requirements(reqs: Array) -> bool:
	return unmet_requirements(reqs).is_empty()

func unmet_requirements(reqs: Array) -> Array:
	var unmet = []
	for req in reqs:
		var type = req.get("type", "")
		var req_id = req.get("id", "")
		match type:
			"item":
				var count = int(req.get("count", 1))
				if not has_task_item(req_id, count):
					unmet.append(req)
			"event":
				if not is_event_completed(req_id):
					unmet.append(req)
			"map":
				if not is_map_unlocked(req_id):
					unmet.append(req)
			"repair":
				var level = int(req.get("level", 1))
				if get_repair_level(req_id) < level:
					unmet.append(req)
			"resource":
				var count = int(req.get("count", 1))
				if get_resource(req_id) < count:
					unmet.append(req)
			_:
				# Unknown requirement type, count as unmet
				unmet.append(req)
	return unmet

# Event State
func is_event_completed(event_id: String) -> bool:
	return event_id in completed_events

func get_event_choice(event_id: String) -> int:
	if event_id in completed_events:
		return int(completed_events[event_id].get("choice", -1))
	return -1

func apply_rewards(rewards: Dictionary) -> void:
	for item_id in rewards:
		var amount = int(rewards[item_id])
		
		# Figure out what kind of item this is from Content metadata
		var metadata = Content.get_item(item_id)
		var kind = metadata.get("kind", "")
		
		match kind:
			"resource":
				add_resource(item_id, amount)
			"task_item":
				add_task_item(item_id, amount)
			"furniture":
				# Standard behavior adds it to owned furniture count
				for i in range(amount):
					add_furniture(item_id)
			"skin":
				add_skin(item_id)
			"collection":
				add_collection(item_id)
			_:
				# Special numeric rewards
				if item_id == "energy":
					add_energy(amount, "event_reward")
				elif item_id == "super_task_credits":
					super_task_credits += amount
					today_changed.emit()
				else:
					# Default fallback: add to resources if unknown
					add_resource(item_id, amount)

func apply_effects(effects: Dictionary) -> void:
	var maps_to_unlock = effects.get("unlocked_maps", [])
	for m_id in maps_to_unlock:
		unlock_map(m_id)
		
	var flags_to_set = effects.get("flags", {})
	for f_key in flags_to_set:
		set_flag(f_key, flags_to_set[f_key])

func mark_event_completed(event_id: String, choice_idx: int) -> void:
	completed_events[event_id] = {
		"day": game_day,
		"choice": choice_idx
	}
	event_completed.emit(event_id)

# Resources
func get_resource(resource_id: String) -> int:
	return int(resources.get(resource_id, 0))

func add_resource(resource_id: String, amount: int) -> void:
	resources[resource_id] = get_resource(resource_id) + amount
	resources_changed.emit()

func spend_resource(resource_id: String, amount: int) -> bool:
	var cur = get_resource(resource_id)
	if cur < amount:
		return false
	resources[resource_id] = cur - amount
	resources_changed.emit()
	return true

func get_point_collect_count(map_id: String, tile_id: String) -> int:
	var map_pts = collected_resource_points.get(map_id, {})
	return int(map_pts.get(tile_id, 0))

func mark_point_collected(map_id: String, tile_id: String) -> void:
	if not (map_id in collected_resource_points):
		collected_resource_points[map_id] = {}
	var map_pts = collected_resource_points[map_id]
	map_pts[tile_id] = int(map_pts.get(tile_id, 0)) + 1
	# Pure record-keeping, does not emit resources_changed signal directly

# Task items
func has_task_item(item_id: String, count: int = 1) -> bool:
	return int(task_items.get(item_id, 0)) >= count

func add_task_item(item_id: String, amount: int) -> void:
	task_items[item_id] = int(task_items.get(item_id, 0)) + amount

func consume_task_item(item_id: String, amount: int) -> bool:
	var cur = int(task_items.get(item_id, 0))
	if cur < amount:
		return false
	task_items[item_id] = cur - amount
	return true

# Home System Pure State APIs
func get_repair_level(repair_id: String) -> int:
	return int(repair_levels.get(repair_id, 0))

func set_repair_level(repair_id: String, level: int) -> void:
	repair_levels[repair_id] = level
	home_changed.emit()

func place_furniture(slot_id: String, furniture_id: String) -> bool:
	# Note: Home slot accepts validation happens in HomeSystem before calling this
	slot_furnitures[slot_id] = furniture_id
	home_changed.emit()
	return true

func remove_furniture(slot_id: String) -> void:
	if slot_id in slot_furnitures:
		slot_furnitures.erase(slot_id)
		home_changed.emit()

# Ownership APIs
func add_furniture(furniture_id: String) -> void:
	owned_furnitures.append(furniture_id)

func has_furniture(furniture_id: String) -> bool:
	return furniture_id in owned_furnitures

func add_skin(skin_id: String) -> void:
	if not (skin_id in owned_skins):
		owned_skins.append(skin_id)

func apply_skin(skin_id: String) -> void:
	if not (skin_id in applied_skins):
		applied_skins.append(skin_id)

func add_collection(collect_id: String) -> void:
	if not (collect_id in collections):
		collections.append(collect_id)

# Monetization APIs
func has_no_ads() -> bool:
	return purchased_products.get("no_ads", false)

func is_purchased(product_id: String) -> bool:
	return purchased_products.get(product_id, false)

func grant_purchase(product_id: String) -> void:
	purchased_products[product_id] = true

func mark_daily_free_claimed() -> void:
	daily_free_claimed = true

func mark_daily_ad_supply_claimed() -> void:
	daily_ad_supply_claimed = true

func mark_daily_ad_extra_claimed() -> void:
	daily_ad_extra_claimed = true

# Flags
func set_flag(flag_id: String, value: Variant) -> void:
	flags[flag_id] = value
	if flag_id.begins_with("system_unlocked_") and value == true:
		var sys_id = flag_id.replace("system_unlocked_", "")
		system_unlocked.emit(sys_id)

func get_flag(flag_id: String, default: Variant = null) -> Variant:
	return flags.get(flag_id, default)

func is_system_unlocked(system_id: String) -> bool:
	return get_flag("system_unlocked_" + system_id, false) == true

# Diary Database
func ensure_diary_day(day: int) -> void:
	var d_key = str(day)
	if not (d_key in diary):
		diary[d_key] = {
			"completed_tasks": [],
			"energy_earned": 0,
			"tiles_revealed": 0,
			"unlocked_events": [],
			"home_changes": [],
			"mood_note": ""
		}

func log_to_diary(day: int, category: String, data: Variant) -> void:
	ensure_diary_day(day)
	var day_log: Dictionary = diary[str(day)]
	match category:
		"completed_tasks":
			if data is String and not (data in day_log["completed_tasks"]):
				day_log["completed_tasks"].append(data)
		"energy_earned":
			day_log["energy_earned"] = int(day_log["energy_earned"]) + int(data)
		"tiles_revealed":
			day_log["tiles_revealed"] = int(day_log["tiles_revealed"]) + int(data)
		"unlocked_events":
			if data is String and not (data in day_log["unlocked_events"]):
				day_log["unlocked_events"].append(data)
		"home_changes":
			if data is String and not (data in day_log["home_changes"]):
				day_log["home_changes"].append(data)
	diary_updated.emit()

func write_mood_note(day: int, note: String) -> void:
	ensure_diary_day(day)
	var day_log: Dictionary = diary[str(day)]
	day_log["mood_note"] = note
	diary_updated.emit()

func get_diary(day: int) -> Dictionary:
	ensure_diary_day(day)
	return diary[str(day)]

func increment_day() -> void:
	game_day += 1
	day_advanced.emit()

func reset_today_tasks() -> void:
	today_candidates = {
		"normal": [],
		"advanced": []
	}
	today_selected = {
		"normal": [],
		"advanced": [],
		"extra_advanced": ""
	}
	today_completed = []
	super_task_completed_today = false
	flags.erase("all_tasks_completed_today")
	today_changed.emit()

func reset_daily_flags() -> void:
	daily_free_claimed = false
	daily_ad_supply_claimed = false
	daily_ad_extra_claimed = false

func add_super_task_credit() -> void:
	super_task_credits += 1
	today_changed.emit()
