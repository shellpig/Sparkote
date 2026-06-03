extends GutTest

func before_all():
	Config.load_config("res://tests/fixtures/config.json")
	Content.content_dir = "res://tests/fixtures/"
	Content.load_all()

func before_each():
	GameState.new_game()

func test_item_requirement():
	var reqs = [{"type": "item", "id": "door_key", "count": 1}]
	
	# Initial: unmet
	assert_false(GameState.meets_requirements(reqs))
	var unmet = GameState.unmet_requirements(reqs)
	assert_eq(unmet.size(), 1)
	assert_eq(unmet[0].get("id"), "door_key")

	# Add item: met
	GameState.add_task_item("door_key", 1)
	assert_true(GameState.meets_requirements(reqs))
	assert_eq(GameState.unmet_requirements(reqs).size(), 0)

func test_resource_requirement():
	var reqs = [{"type": "resource", "id": "wood", "count": 5}]

	# Initial: unmet
	assert_false(GameState.meets_requirements(reqs))
	
	# Add resource: met
	GameState.add_resource("wood", 5)
	assert_true(GameState.meets_requirements(reqs))

func test_map_requirement():
	var reqs = [{"type": "map", "id": "map_2"}]

	# Initial: unmet
	assert_false(GameState.meets_requirements(reqs))

	# Unlock map: met
	GameState.unlock_map("map_2")
	assert_true(GameState.meets_requirements(reqs))

func test_repair_requirement():
	var reqs = [{"type": "repair", "id": "camper_engine", "level": 2}]

	# Initial: unmet
	assert_false(GameState.meets_requirements(reqs))

	# Set repair level: met
	GameState.set_repair_level("camper_engine", 2)
	assert_true(GameState.meets_requirements(reqs))

func test_event_requirement():
	var reqs = [{"type": "event", "id": "evt_01"}]

	# Initial: unmet
	assert_false(GameState.meets_requirements(reqs))

	# Complete event: met
	GameState.mark_event_completed("evt_01", 0)
	assert_true(GameState.meets_requirements(reqs))

func test_multiple_requirements():
	var reqs = [
		{"type": "item", "id": "door_key", "count": 1},
		{"type": "resource", "id": "wood", "count": 5}
	]

	# Initial: both unmet
	assert_false(GameState.meets_requirements(reqs))
	assert_eq(GameState.unmet_requirements(reqs).size(), 2)

	# Met item, resource still unmet
	GameState.add_task_item("door_key", 1)
	assert_false(GameState.meets_requirements(reqs))
	var unmet = GameState.unmet_requirements(reqs)
	assert_eq(unmet.size(), 1)
	assert_eq(unmet[0].get("id"), "wood")

	# Met both
	GameState.add_resource("wood", 5)
	assert_true(GameState.meets_requirements(reqs))
	assert_eq(GameState.unmet_requirements(reqs).size(), 0)
