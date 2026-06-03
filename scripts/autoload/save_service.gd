extends Node

func save_to_file(path: String = "user://savegame.json") -> Error:
	var state_dict = GameState.to_dict()
	var envelope = {
		"version": 1,
		"state": state_dict
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var err = FileAccess.get_open_error()
		printerr("SaveService: Failed to open save file for writing: ", path, " Error: ", err)
		return err
		
	var json_str = JSON.stringify(envelope)
	file.store_string(json_str)
	file.close()
	return OK

func load_from_file(path: String = "user://savegame.json") -> Error:
	if not FileAccess.file_exists(path):
		print("SaveService: Save file not found, initializing new game: ", path)
		GameState.new_game()
		return ERR_FILE_NOT_FOUND
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		var err = FileAccess.get_open_error()
		printerr("SaveService: Failed to open save file for reading: ", path, " Error: ", err)
		GameState.new_game()
		return err
		
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		printerr("SaveService: Failed to parse save file: ", path, " Error: ", err)
		GameState.new_game()
		return ERR_PARSE_ERROR
		
	var envelope = json.data
	if envelope == null or not (envelope is Dictionary):
		printerr("SaveService: Invalid JSON format: ", path)
		GameState.new_game()
		return ERR_PARSE_ERROR
		
	# Check versioning and extract state
	var version = int(envelope.get("version", 0))
	var state = envelope.get("state", {})
	if version != 1 or not (state is Dictionary) or state.is_empty():
		printerr("SaveService: Unsupported save file version or invalid state format in: ", path)
		GameState.new_game()
		return ERR_INVALID_DATA
		
	GameState.from_dict(state)
	return OK
