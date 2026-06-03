extends GutTest

func before_all():
	Config.load_config("res://tests/fixtures/config.json")
	Content.content_dir = "res://tests/fixtures/"
	Content.load_all()

func before_each():
	GameState.new_game()

func test_roll_candidates():
	# Initial: candidates empty
	assert_eq(GameState.today_candidates["normal"].size(), 0)
	assert_eq(GameState.today_candidates["advanced"].size(), 0)

	TaskSystem.roll_today()
	
	# Default config has normal slots 2 candidates 6, advanced slots 1 candidates 3
	# Normal fixture has 7 tasks, advanced fixture has 4 tasks
	assert_eq(GameState.today_candidates["normal"].size(), 6)
	assert_eq(GameState.today_candidates["advanced"].size(), 3)

func test_favorite_tasks_overwrite():
	# Set favorite tasks
	GameState.save_favorite("n7", false) # normal favorite
	GameState.save_favorite("a4", true)  # advanced favorite
	
	TaskSystem.roll_today()
	
	# The first candidates should be the favorites
	assert_eq(GameState.today_candidates["normal"][0], "n7")
	assert_eq(GameState.today_candidates["advanced"][0], "a4")

func test_task_selection_limits():
	TaskSystem.roll_today()
	
	# Select 2 normal tasks (limit is 2)
	var n1 = GameState.today_candidates["normal"][0]
	var n2 = GameState.today_candidates["normal"][1]
	var n3 = GameState.today_candidates["normal"][2]
	
	assert_true(GameState.choose_task(n1, false))
	assert_true(GameState.choose_task(n2, false))
	# Attempt to select a 3rd should fail
	assert_false(GameState.choose_task(n3, false))

	# Select 1 advanced task (limit is 1)
	var a1 = GameState.today_candidates["advanced"][0]
	var a2 = GameState.today_candidates["advanced"][1]
	
	assert_true(GameState.choose_task(a1, true))
	assert_false(GameState.choose_task(a2, true))

func test_task_completion_rewards():
	TaskSystem.roll_today()
	var n1 = GameState.today_candidates["normal"][0]
	GameState.choose_task(n1, false)

	# Initial energy is 0
	assert_eq(GameState.get_energy(), 0)

	var context = {
		"task_completed_fired": false,
		"task_completed_id": ""
	}
	TaskSystem.task_completed.connect(func(task_id):
		context["task_completed_fired"] = true
		context["task_completed_id"] = task_id
	)

	# Complete task
	TaskSystem.complete_task(n1)
	
	assert_eq(GameState.get_energy(), 1) # Normal task energy is 1
	assert_true(GameState.is_task_completed(n1))
	assert_true(context["task_completed_fired"])
	assert_eq(context["task_completed_id"], n1)
	
	# Verify diary
	var diary_data = GameState.get_diary(GameState.game_day)
	assert_true(n1 in diary_data.get("completed_tasks", []))
	assert_eq(diary_data.get("energy_earned", 0), 1)

func test_ad_extra_advanced_unlock():
	TaskSystem.roll_today()
	
	# Pre-conditions
	assert_eq(GameState.today_selected["extra_advanced"], "")
	assert_false(GameState.daily_ad_extra_claimed)

	# Mock successful ad
	AdService.force_fail = false
	TaskSystem.unlock_extra_advanced_via_ad()
	
	await AdService.rewarded_ad_succeeded
	# Extra advanced should be set
	assert_ne(GameState.today_selected["extra_advanced"], "")
	assert_true(GameState.daily_ad_extra_claimed)

func test_super_tasks():
	# Initial: no credits
	assert_false(TaskSystem.complete_super_task("Test Super Task"))
	
	# Add credit
	GameState.add_super_task_credit()
	assert_eq(GameState.super_task_credits, 1)

	# Complete super task
	assert_true(TaskSystem.complete_super_task("Test Super Task"))
	assert_eq(GameState.get_energy(), 3) # Super task gives 3 energy
	assert_true(GameState.super_task_completed_today)
	assert_eq(GameState.super_task_credits, 0)

	# Attempt second super task on the same day should fail
	GameState.add_super_task_credit()
	assert_false(TaskSystem.complete_super_task("Another Super Task"))

func test_advance_day_cycles():
	TaskSystem.roll_today()
	GameState.add_energy(5)
	
	# Advance day
	DayCycle.advance_day()
	
	# Energy should carry forward
	assert_eq(GameState.get_energy(), 5)
	# Day should increment
	assert_eq(GameState.game_day, 2)
	# Candidates should be rolled for the new day
	assert_eq(GameState.today_candidates["normal"].size(), 6)

func test_weekly_progression_super_reward():
	# Threshold is 4 days full completion
	# Loop day 1-7
	for day in range(1, 8):
		GameState.game_day = day
		# Select and complete tasks for today
		TaskSystem.roll_today()
		var n1 = GameState.today_candidates["normal"][0]
		var a1 = GameState.today_candidates["advanced"][0]
		GameState.choose_task(n1, false)
		GameState.choose_task(a1, true)
		
		TaskSystem.complete_task(n1)
		TaskSystem.complete_task(a1) # Completes all selected today
		
		assert_eq(GameState.all_completed_days_this_week, day)
		
		if day < 7:
			# Advance day to transition
			DayCycle.advance_day()

	# Currently on day 7. Triggering advance_day() will transition to day 8 and perform weekly check
	assert_eq(GameState.super_task_credits, 0)
	DayCycle.advance_day()
	
	# Week has completed. Check if super credit was awarded (threshold 4 met since we did 7 days)
	assert_eq(GameState.super_task_credits, 1)
	assert_eq(GameState.all_completed_days_this_week, 0) # reset
	assert_eq(GameState.game_day, 8)
