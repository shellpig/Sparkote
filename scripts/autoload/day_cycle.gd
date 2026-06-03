extends Node

func advance_day() -> void:
	# 1. Weekly check (before advancing day, at the end of the 7th day of the current week)
	if GameState.game_day % 7 == 0:
		if GameState.all_completed_days_this_week >= Config.get_weekly_super_threshold():
			GameState.add_super_task_credit()
		GameState.all_completed_days_this_week = 0

	# 2. Increment day
	GameState.increment_day()

	# 3. Reset daily candidates / selections and flags
	GameState.reset_today_tasks()
	GameState.reset_daily_flags()

	# 4. Roll candidates for the new day
	TaskSystem.roll_today()
