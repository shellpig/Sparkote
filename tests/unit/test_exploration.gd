extends GutTest

func before_all():
	Config.load_config("res://tests/fixtures/config.json")
	Content.content_dir = "res://tests/fixtures/"
	Content.load_all()

func before_each():
	GameState.new_game()
	# GameState.new_game resets unlocked maps, but Exploration._ready unlocks map_1 at startup.
	# To ensure clean state, we explicitly set up Exploration for each test.
	Exploration.current_map_id = ""
	GameState.unlocked_maps.clear()
	GameState.revealed_tiles.clear()
	
	# Explicitly unlock starting map
	Exploration.unlock_map("map_1")
	Exploration.set_current_map("map_1")

func test_starting_map_and_tile_revealed():
	assert_true(GameState.is_map_unlocked("map_1"))
	assert_true(GameState.is_tile_revealed("map_1", "tile_start"))
	assert_eq(Exploration.get_current_map(), "map_1")

func test_can_flip_adjacency():
	GameState.add_energy(10)
	# Neighbors of tile_start is tile_discovery. It should be selectable.
	var check_disc = Exploration.can_flip("map_1", "tile_discovery")
	assert_true(check_disc.get("ok"))

	# tile_resource is not adjacent to tile_start (needs tile_discovery first).
	var check_res = Exploration.can_flip("map_1", "tile_resource")
	assert_false(check_res.get("ok"))
	assert_eq(check_res.get("reason"), "too_far")

	# Already revealed starting tile
	var check_start = Exploration.can_flip("map_1", "tile_start")
	assert_false(check_start.get("ok"))
	assert_eq(check_start.get("reason"), "already_revealed")

func test_insufficient_energy():
	# Set energy to 0 (default on new game is 0)
	GameState.energy = 0
	
	# tile_discovery costs 1.
	var check = Exploration.can_flip("map_1", "tile_discovery")
	assert_false(check.get("ok"))
	assert_eq(check.get("reason"), "no_energy")
	
	# Try flipping, should fail and not change energy/state
	var outcome = Exploration.flip_tile("map_1", "tile_discovery")
	assert_false(outcome.get("ok"))
	assert_eq(outcome.get("reason"), "no_energy")
	assert_eq(GameState.get_energy(), 0)
	assert_false(GameState.is_tile_revealed("map_1", "tile_discovery"))

func test_successful_flip_discovery():
	# Give energy
	GameState.add_energy(5)
	
	# Flip discovery tile (cost 1)
	var outcome = Exploration.flip_tile("map_1", "tile_discovery")
	assert_true(outcome.get("ok"))
	assert_eq(outcome.get("type"), "discovery")
	
	# Energy should be deducted: 5 - 1 = 4
	assert_eq(GameState.get_energy(), 4)
	assert_true(GameState.is_tile_revealed("map_1", "tile_discovery"))
	
	# Reward should be applied: discovery gives 2 wood (res://tests/fixtures/maps/map_1.json line 22)
	assert_eq(GameState.get_resource("wood"), 2)
	
	# Diary check
	var diary_data = GameState.get_diary(GameState.game_day)
	assert_eq(diary_data.get("tiles_revealed", 0), 1)

func test_successful_flip_resource_point():
	GameState.add_energy(10)
	
	# Progress to tile_discovery
	Exploration.flip_tile("map_1", "tile_discovery")
	
	# Flip resource point tile (cost 2)
	var outcome = Exploration.flip_tile("map_1", "tile_resource")
	assert_true(outcome.get("ok"))
	assert_eq(outcome.get("type"), "resource_point")
	
	# Energy deducted: 10 - 1 (discovery) - 2 (resource) = 7
	assert_eq(GameState.get_energy(), 7)
	assert_true(GameState.is_tile_revealed("map_1", "tile_resource"))
	
	# Resource point first_rewards should be applied: 5 stone
	assert_eq(GameState.get_resource("stone"), 5)

func test_requirements_blocking_and_unlock():
	GameState.add_energy(15)
	
	# Progress to tile_resource
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")
	
	# tile_blocked is next, cost 1, requires item "door_key"
	var check = Exploration.can_flip("map_1", "tile_blocked")
	assert_false(check.get("ok"))
	assert_eq(check.get("reason"), "blocked")
	
	# Add the requirement item to GameState
	GameState.add_task_item("door_key", 1)
	
	# Now it should be selectable
	var check_after = Exploration.can_flip("map_1", "tile_blocked")
	assert_true(check_after.get("ok"))
	
	# Flip it (cost 1)
	var outcome = Exploration.flip_tile("map_1", "tile_blocked")
	assert_true(outcome.get("ok"))
	assert_eq(outcome.get("type"), "decor")
	
	# Grants furniture: chair_1
	assert_true(GameState.has_furniture("chair_1"))

func test_exit_unlocks_new_map_and_reveals_start():
	GameState.add_energy(20)
	
	# Progress to tile_exit
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")
	
	# Give key so we can open tile_blocked
	GameState.add_task_item("door_key", 1)
	Exploration.flip_tile("map_1", "tile_blocked")
	
	# tile_exit targets map_2 (cost 3)
	assert_false(GameState.is_map_unlocked("map_2"))
	
	var outcome = Exploration.flip_tile("map_1", "tile_exit")
	assert_true(outcome.get("ok"))
	assert_eq(outcome.get("type"), "exit")
	
	# map_2 should now be unlocked
	assert_true(GameState.is_map_unlocked("map_2"))
	# map_2 start tile (tile_sky_start) should be automatically revealed
	assert_true(GameState.is_tile_revealed("map_2", "tile_sky_start"))
	
	# map_2 next progression tile should be selectable (not a dead map)
	var check_next = Exploration.can_flip("map_2", "tile_sky_discovery")
	assert_true(check_next.get("ok"))

func test_forking_choices_and_bypassing():
	GameState.add_energy(15)
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")
	
	# From tile_resource, we have two paths: tile_blocked (blocked by key) and tile_event.
	# tile_event is adjacent and has no requirements. It should be flip-able.
	var check_event = Exploration.can_flip("map_1", "tile_event")
	assert_true(check_event.get("ok"))
	
	# Flip tile_event
	var outcome = Exploration.flip_tile("map_1", "tile_event")
	assert_true(outcome.get("ok"))
	assert_eq(outcome.get("type"), "event")
	
	# Bypassed path tile_blocked should still be adjacent and evaluate to blocked (not vanished)
	var check_blocked = Exploration.can_flip("map_1", "tile_blocked")
	assert_false(check_blocked.get("ok"))
	assert_eq(check_blocked.get("reason"), "blocked")
	
	# Grant key and we should be able to flip tile_blocked later
	GameState.add_task_item("door_key", 1)
	var check_blocked_after = Exploration.can_flip("map_1", "tile_blocked")
	assert_true(check_blocked_after.get("ok"))
	
	var outcome_blocked = Exploration.flip_tile("map_1", "tile_blocked")
	assert_true(outcome_blocked.get("ok"))
	assert_true(GameState.is_tile_revealed("map_1", "tile_blocked"))

func test_get_map_view_fog_rule():
	# Initially, map_1 only has tile_start revealed.
	# Neighbors of tile_start is tile_discovery.
	# So only tile_start (revealed) and tile_discovery (adjacent/selectable) should be visible.
	# All other tiles (tile_resource, tile_blocked, tile_event, tile_exit) should be hidden by fog.
	var view = Exploration.get_map_view("map_1")
	assert_eq(view.get("id"), "map_1")
	
	var visible_tiles = view.get("tiles", [])
	assert_eq(visible_tiles.size(), 2)
	
	var visible_ids = []
	for t in visible_tiles:
		visible_ids.append(t.get("id"))
		
	assert_true("tile_start" in visible_ids)
	assert_true("tile_discovery" in visible_ids)
	assert_false("tile_resource" in visible_ids)
	
	# Now flip tile_discovery. tile_resource should become visible.
	GameState.add_energy(5)
	Exploration.flip_tile("map_1", "tile_discovery")
	
	var view_after = Exploration.get_map_view("map_1")
	var visible_tiles_after = view_after.get("tiles", [])
	assert_eq(visible_tiles_after.size(), 3)
	
	var visible_ids_after = []
	for t in visible_tiles_after:
		visible_ids_after.append(t.get("id"))
		
	assert_true("tile_start" in visible_ids_after)
	assert_true("tile_discovery" in visible_ids_after)
	assert_true("tile_resource" in visible_ids_after)
	assert_false("tile_blocked" in visible_ids_after)
