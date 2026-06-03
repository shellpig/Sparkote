extends GutTest

func before_all():
	Config.load_config("res://tests/fixtures/config.json")

func before_each():
	GameState.new_game()

func test_new_game_state():
	assert_eq(GameState.game_day, 1)
	assert_eq(GameState.energy, 0)
	assert_eq(GameState.resources.size(), 0)
	assert_eq(GameState.task_items.size(), 0)
	assert_eq(GameState.unlocked_maps.size(), 0)
	assert_eq(GameState.revealed_tiles.size(), 0)
	assert_eq(GameState.completed_events.size(), 0)

func test_energy_atomic_operations():
	# Test add energy (initial 0, Config cap is 20)
	var context = {
		"changed_emitted": false,
		"changed_val": -1,
		"overflow_emitted": false
	}
	
	GameState.energy_changed.connect(func(v):
		context["changed_emitted"] = true
		context["changed_val"] = v
	)
	
	GameState.energy_overflow.connect(func():
		context["overflow_emitted"] = true
	)

	var gained = GameState.add_energy(5)
	assert_eq(gained, 5)
	assert_eq(GameState.get_energy(), 5)
	assert_true(context["changed_emitted"])
	assert_eq(context["changed_val"], 5)
	assert_false(context["overflow_emitted"])

	# Spend energy
	context["changed_emitted"] = false
	var spent = GameState.spend_energy(3)
	assert_true(spent)
	assert_eq(GameState.get_energy(), 2)
	assert_true(context["changed_emitted"])
	assert_eq(context["changed_val"], 2)

	# Spend too much
	context["changed_emitted"] = false
	spent = GameState.spend_energy(10)
	assert_false(spent)
	assert_eq(GameState.get_energy(), 2) # unchanged
	assert_false(context["changed_emitted"])

	# Clamping and overflow
	context["overflow_emitted"] = false
	gained = GameState.add_energy(25) # 2 + 25 = 27, capped at 20
	assert_eq(gained, 18)
	assert_eq(GameState.get_energy(), 20)
	assert_true(context["overflow_emitted"])

func test_resources_atomic_operations():
	var context = {
		"resources_changed_emitted": false
	}
	
	GameState.resources_changed.connect(func():
		context["resources_changed_emitted"] = true
	)

	GameState.add_resource("wood", 10)
	assert_eq(GameState.get_resource("wood"), 10)
	assert_true(context["resources_changed_emitted"])

	context["resources_changed_emitted"] = false
	var spent = GameState.spend_resource("wood", 4)
	assert_true(spent)
	assert_eq(GameState.get_resource("wood"), 6)
	assert_true(context["resources_changed_emitted"])

	# Spend too much
	context["resources_changed_emitted"] = false
	spent = GameState.spend_resource("wood", 10)
	assert_false(spent)
	assert_eq(GameState.get_resource("wood"), 6)
	assert_false(context["resources_changed_emitted"])

func test_serialization_round_trip():
	# Setup some state
	GameState.game_day = 5
	GameState.add_energy(15)
	GameState.add_resource("wood", 8)
	GameState.add_task_item("door_key", 1)
	GameState.unlock_map("map_1")
	GameState.mark_revealed("map_1", "tile_start")
	GameState.set_flag("test_flag", 42)
	GameState.mark_event_completed("evt_01", 0)
	GameState.set_repair_level("van_engine", 1)
	GameState.place_furniture("slot_1", "chair_1")
	GameState.log_to_diary(1, "completed_tasks", "n1")

	var dict = GameState.to_dict()
	
	# Reset
	GameState.new_game()
	assert_eq(GameState.game_day, 1)
	assert_eq(GameState.energy, 0)
	
	# Load back
	var context = {
		"state_loaded_emitted": false
	}
	GameState.state_loaded.connect(func():
		context["state_loaded_emitted"] = true
	)
	GameState.from_dict(dict)
	
	assert_true(context["state_loaded_emitted"])
	assert_eq(GameState.game_day, 5)
	assert_eq(GameState.energy, 15)
	assert_eq(GameState.get_resource("wood"), 8)
	assert_true(GameState.has_task_item("door_key"))
	assert_true(GameState.is_map_unlocked("map_1"))
	assert_true(GameState.is_tile_revealed("map_1", "tile_start"))
	assert_eq(GameState.get_flag("test_flag"), 42)
	assert_true(GameState.is_event_completed("evt_01"))
	assert_eq(GameState.get_event_choice("evt_01"), 0)
	assert_eq(GameState.get_repair_level("van_engine"), 1)
	assert_eq(GameState.slot_furnitures.get("slot_1"), "chair_1")
	assert_eq(GameState.get_diary(1).get("completed_tasks"), ["n1"])
