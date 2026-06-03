extends Node

var content_dir: String = "res://data/"

var _tasks: Dictionary = {}
var _items: Dictionary = {}
var _home: Dictionary = {}
var _maps: Dictionary = {}
var _events: Dictionary = {}

func _ready() -> void:
	if FileAccess.file_exists(content_dir + "tasks.json"):
		var err = load_all()
		if err != OK:
			print("Content: Default content load returned ", err)

func load_all() -> Error:
	_tasks.clear()
	_items.clear()
	_home.clear()
	_maps.clear()
	_events.clear()

	# Read tasks.json
	var tasks_data = _load_json_file(content_dir + "tasks.json")
	if tasks_data == null: 
		return ERR_FILE_NOT_FOUND
	_tasks = tasks_data

	# Read items.json
	var items_data = _load_json_file(content_dir + "items.json")
	if items_data == null: 
		return ERR_FILE_NOT_FOUND
	for item in items_data.get("items", []):
		_items[item.get("id")] = item

	# Read home.json
	var home_data = _load_json_file(content_dir + "home.json")
	if home_data == null: 
		return ERR_FILE_NOT_FOUND
	_home = home_data

	# Read maps/
	var maps_path = content_dir + "maps"
	var map_files = _get_files_in_dir(maps_path)
	for file_name in map_files:
		if file_name.ends_with(".json"):
			var map_data = _load_json_file(maps_path + "/" + file_name)
			if map_data == null:
				return ERR_PARSE_ERROR
			_maps[map_data.get("id")] = map_data

	# Read events/
	var events_path = content_dir + "events"
	var event_files = _get_files_in_dir(events_path)
	for file_name in event_files:
		if file_name.ends_with(".json"):
			var event_group_data = _load_json_file(events_path + "/" + file_name)
			if event_group_data == null:
				return ERR_PARSE_ERROR
			for event in event_group_data.get("events", []):
				_events[event.get("id")] = event

	# Perform validation checks
	return _validate_references()

func _load_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		printerr("Content: File not found: ", path)
		return null

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		printerr("Content: Failed to parse JSON file: ", path, " Error: ", err)
		return null

	return json.data

func _get_files_in_dir(dir_path: String) -> Array:
	var files = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return files
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and not file_name.ends_with(".import"):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return files

func _validate_references() -> Error:
	# 1. Validate home config
	var repairs = _home.get("repairs", [])
	for repair in repairs:
		var repair_id = repair.get("id")
		var levels = repair.get("levels", [])
		for lvl in levels:
			var cost = lvl.get("cost", {})
			for item_id in cost:
				if not _items.has(item_id):
					printerr("Content Validation: Repair '", repair_id, "' level ", lvl.get("level"), " refers to non-existent item '", item_id, "'")
					return ERR_INVALID_DATA

	# 2. Validate events
	for event_id in _events:
		var event = _events[event_id]
		var choices = event.get("choices", [])
		for choice in choices:
			var rewards = choice.get("rewards", {})
			for r_id in rewards:
				if r_id != "energy" and r_id != "super_task_credits" and not _items.has(r_id):
					printerr("Content Validation: Event '", event_id, "' choice refers to non-existent item reward '", r_id, "'")
					return ERR_INVALID_DATA
			var effects = choice.get("effects", {})
			var unlocked_maps_list = effects.get("unlocked_maps", [])
			for m_id in unlocked_maps_list:
				if not _maps.has(m_id):
					printerr("Content Validation: Event '", event_id, "' choice unlocks non-existent map '", m_id, "'")
					return ERR_INVALID_DATA

	# 3. Validate maps
	for map_id in _maps:
		var map = _maps[map_id]
		var start_tile = map.get("start_tile")
		var tiles = map.get("tiles", [])
		
		var tile_ids = {}
		for tile in tiles:
			tile_ids[tile.get("id")] = tile

		if not tile_ids.has(start_tile):
			printerr("Content Validation: Map '", map_id, "' start_tile '", start_tile, "' does not exist in tiles.")
			return ERR_INVALID_DATA

		for tile in tiles:
			var tile_id = tile.get("id")
			var neighbors = tile.get("neighbors", [])
			for neighbor_id in neighbors:
				if not tile_ids.has(neighbor_id):
					printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' has non-existent neighbor '", neighbor_id, "'")
					return ERR_INVALID_DATA
			
			var tile_type = tile.get("type")
			match tile_type:
				"event":
					var evt_id = tile.get("event_id")
					if not _events.has(evt_id):
						printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' refers to non-existent event '", evt_id, "'")
						return ERR_INVALID_DATA
				"exit":
					var target_maps_list = tile.get("target_maps", [])
					for t_map_id in target_maps_list:
						if not _maps.has(t_map_id):
							printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' refers to non-existent target map '", t_map_id, "'")
							return ERR_INVALID_DATA
				"decor":
					var reward_id = tile.get("reward_id")
					if not _items.has(reward_id):
						printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' refers to non-existent decor reward item '", reward_id, "'")
						return ERR_INVALID_DATA
				"resource_point":
					var first_rewards = tile.get("first_rewards", {})
					for r_id in first_rewards:
						if not _items.has(r_id):
							printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' refers to non-existent resource item '", r_id, "'")
							return ERR_INVALID_DATA
					var collect_rewards = tile.get("collect_rewards", {})
					for r_id in collect_rewards:
						if not _items.has(r_id):
							printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' refers to non-existent resource item '", r_id, "'")
							return ERR_INVALID_DATA

			# Validate requirements
			var requirements = tile.get("requirements", [])
			for req in requirements:
				var req_type = req.get("type")
				var req_id = req.get("id")
				match req_type:
					"item", "resource":
						if not _items.has(req_id):
							printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' requirement refers to non-existent item '", req_id, "'")
							return ERR_INVALID_DATA
					"event":
						if not _events.has(req_id):
							printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' requirement refers to non-existent event '", req_id, "'")
							return ERR_INVALID_DATA
					"map":
						if not _maps.has(req_id):
							printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' requirement refers to non-existent map '", req_id, "'")
							return ERR_INVALID_DATA
					"repair":
						var repair_exists = false
						for rep in repairs:
							if rep.get("id") == req_id:
								repair_exists = true
								break
						if not repair_exists:
							printerr("Content Validation: Map '", map_id, "' tile '", tile_id, "' requirement refers to non-existent repair '", req_id, "'")
							return ERR_INVALID_DATA

	return OK

# Queries
func get_task_pool() -> Dictionary:
	return _tasks

func get_map(map_id: String) -> Dictionary:
	return _maps.get(map_id, {}).duplicate(true)

func get_event(event_id: String) -> Dictionary:
	return _events.get(event_id, {}).duplicate(true)

func get_item(item_id: String) -> Dictionary:
	return _items.get(item_id, {}).duplicate(true)

func get_home_slots() -> Array:
	return _home.get("slots", [])

func get_home_repairs() -> Array:
	return _home.get("repairs", [])
