extends GutTest

func before_all():
	Config.load_config("res://tests/fixtures/config.json")
	Content.content_dir = "res://tests/fixtures/"
	Content.load_all()

func before_each():
	GameState.new_game()
	Exploration.current_map_id = ""
	GameState.unlocked_maps.clear()
	GameState.revealed_tiles.clear()
	UINavigation.overlay_stack.clear()
	UINavigation.is_input_frozen = false
	
	Exploration.unlock_map("map_1")
	Exploration.set_current_map("map_1")

func test_event_play_overlay():
	assert_true(UINavigation.overlay_stack.is_empty())
	
	EventSystem.play("evt_01")
	
	assert_eq(UINavigation.overlay_stack.size(), 1)
	var active = UINavigation.overlay_stack.back()
	assert_eq(active.get("kind"), "event_player")
	var data = active.get("data", {})
	assert_eq(data.get("event_id"), "evt_01")
	assert_false(data.get("is_replay", false))

func test_event_resolve_rewards_and_effects():
	# Initial
	assert_false(GameState.has_task_item("door_key"))
	assert_false(GameState.is_event_completed("evt_01"))
	
	EventSystem.play("evt_01")
	# Resolve choice 0: Open it gently -> grants door_key: 1
	EventSystem.resolve("evt_01", 0)
	
	# Check rewards applied
	assert_true(GameState.has_task_item("door_key", 1))
	# Check event marked complete
	assert_true(GameState.is_event_completed("evt_01"))
	assert_eq(GameState.get_event_choice("evt_01"), 0)
	
	# Check diary logs
	var diary_data = GameState.get_diary(GameState.game_day)
	assert_true("Opened the mysterious letter gently." in diary_data.get("unlocked_events", []))
	
	# Check overlay closed
	assert_true(UINavigation.overlay_stack.is_empty())

func test_event_branching_distinct_rewards():
	assert_eq(GameState.get_resource("wood"), 0)
	
	EventSystem.play("evt_01")
	# Resolve choice 1: Tear it open -> grants wood: 1
	EventSystem.resolve("evt_01", 1)
	
	assert_eq(GameState.get_resource("wood"), 1)
	assert_false(GameState.has_task_item("door_key"))
	assert_eq(GameState.get_event_choice("evt_01"), 1)
	
	var diary_data = GameState.get_diary(GameState.game_day)
	assert_true("Tore open the mysterious letter." in diary_data.get("unlocked_events", []))

func test_event_replay_mode_safety():
	# Settle initially with choice 0
	EventSystem.play("evt_01")
	EventSystem.resolve("evt_01", 0)
	
	# Reset resources and logs to verify replay doesn't reissue
	GameState.task_items.clear()
	var diary_day = GameState.get_diary(GameState.game_day)
	diary_day["unlocked_events"].clear()
	
	# Replay
	EventSystem.replay("evt_01")
	
	assert_eq(UINavigation.overlay_stack.size(), 1)
	var active = UINavigation.overlay_stack.back()
	assert_eq(active.get("kind"), "event_player")
	var data = active.get("data", {})
	assert_true(data.get("is_replay", true))
	assert_eq(data.get("choice_idx"), 0)
	
	# Close replay overlay
	UINavigation.close_overlay()
	
	# Assert no duplicate rewards
	assert_false(GameState.has_task_item("door_key"))
	# Assert no duplicate diary logs
	assert_true(diary_day["unlocked_events"].is_empty())

func test_diary_aggregation():
	# 1. Complete task
	TaskSystem.roll_today()
	var n1 = GameState.today_candidates["normal"][0]
	GameState.choose_task(n1, false)
	TaskSystem.complete_task(n1)
	
	# 2. Flip tile
	GameState.add_energy(5)
	Exploration.flip_tile("map_1", "tile_discovery")
	
	# 3. Settle event
	EventSystem.play("evt_01")
	EventSystem.resolve("evt_01", 0)
	
	# Verify complete today diary
	var diary_data = GameState.get_diary(GameState.game_day)
	
	# Complete task is logged
	assert_true(n1 in diary_data.get("completed_tasks", []))
	# Tiles flipped is logged
	assert_eq(diary_data.get("tiles_revealed", 0), 1)
	# Event resolved is logged
	assert_true("Opened the mysterious letter gently." in diary_data.get("unlocked_events", []))
	# Energy earned is logged (task gives 1)
	assert_eq(diary_data.get("energy_earned", 0), 1)

func test_mood_note_saving():
	# Initial: mood blank
	var diary_data = GameState.get_diary(1)
	assert_eq(diary_data.get("mood_note", ""), "")
	
	# Write mood note
	GameState.write_mood_note(1, "I feel peaceful today.")
	
	# Verify written
	var diary_after = GameState.get_diary(1)
	assert_eq(diary_after.get("mood_note", ""), "I feel peaceful today.")
	
	# Verify it doesn't advance day
	assert_eq(GameState.game_day, 1)
