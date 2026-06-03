extends Node

var _data: Dictionary = {}

func _ready() -> void:
	# Load default config on startup
	var err = load_config("res://data/config.json")
	if err != OK:
		printerr("Config: Failed to load default config.json")

func load_config(path: String) -> Error:
	if not FileAccess.file_exists(path):
		printerr("Config: File does not exist: ", path)
		return ERR_FILE_NOT_FOUND

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		var err = FileAccess.get_open_error()
		printerr("Config: Failed to open file: ", path, " Error: ", err)
		return err

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed == null or not (parsed is Dictionary):
		printerr("Config: Invalid JSON format in: ", path)
		return ERR_PARSE_ERROR

	_data = parsed
	return OK

func get_task_energy(kind: String) -> int:
	var task_energy = _data.get("task_energy", {})
	return int(task_energy.get(kind, 0))

func get_energy_cap() -> int:
	return int(_data.get("energy_cap", 20))

func get_energy_hint_threshold() -> int:
	return int(_data.get("energy_hint_threshold", 10))

func get_energy_near_cap_threshold() -> int:
	return int(_data.get("energy_near_cap_threshold", 18))

func get_daily_slots(kind: String) -> int:
	var slots = _data.get("daily_slots", {})
	return int(slots.get(kind, 0))

func get_daily_candidates(kind: String) -> int:
	var candidates = _data.get("daily_candidates", {})
	return int(candidates.get(kind, 0))

func get_recollect_cost() -> int:
	return int(_data.get("resource_point_recollect_cost", 1))

func get_recollect_daily_limit() -> int:
	return int(_data.get("resource_point_daily_limit", 1))

func get_weekly_super_threshold() -> int:
	return int(_data.get("weekly_super_threshold", 4))
