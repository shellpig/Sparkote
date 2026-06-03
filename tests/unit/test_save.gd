extends GutTest

const TEST_SAVE_PATH = "user://test_savegame.json"

func before_all():
	Config.load_config("res://tests/fixtures/config.json")

func before_each():
	GameState.new_game()
	# Clean up any leftover test save file
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)

func after_all():
	# Final cleanup of test save file
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)

func test_save_load_round_trip():
	# Modify state
	GameState.game_day = 3
	GameState.add_energy(10)
	GameState.add_resource("wood", 5)
	
	# Save
	var err = SaveService.save_to_file(TEST_SAVE_PATH)
	assert_eq(err, OK)
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH))

	# Modify state again
	GameState.game_day = 9
	GameState.add_energy(5) # 15 now
	
	# Load back
	err = SaveService.load_from_file(TEST_SAVE_PATH)
	assert_eq(err, OK)
	
	# Verify state was restored to what it was when saved
	assert_eq(GameState.game_day, 3)
	assert_eq(GameState.energy, 10)
	assert_eq(GameState.get_resource("wood"), 5)

func test_load_non_existent_file():
	var err = SaveService.load_from_file("user://non_existent_save_file.json")
	assert_eq(err, ERR_FILE_NOT_FOUND)
	# Should reset state to new game defaults
	assert_eq(GameState.game_day, 1)
	assert_eq(GameState.energy, 0)

func test_load_corrupted_json():
	# Write invalid JSON content
	var file = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ invalid_json : [1, 2, }")
	file.close()

	# Load corrupted file
	var err = SaveService.load_from_file(TEST_SAVE_PATH)
	assert_eq(err, ERR_PARSE_ERROR)
	# Should reset state to default new game
	assert_eq(GameState.game_day, 1)
	assert_eq(GameState.energy, 0)
