extends Node

signal task_completed(task_id: String)
signal all_today_tasks_done

var _ad_request_in_progress: bool = false

func _ready() -> void:
	AdService.rewarded_ad_succeeded.connect(_on_ad_success)
	AdService.rewarded_ad_failed.connect(_on_ad_fail)

func roll_today() -> void:
	# 1. Normal Candidates
	var normal_pool = Content.get_task_pool().get("normal", [])
	var normal_ids = []
	for t in normal_pool:
		normal_ids.append(t.get("id"))
	# Select unique random normal tasks
	normal_ids.shuffle()
	var chosen_normal = normal_ids.slice(0, min(Config.get_daily_candidates("normal"), normal_ids.size()))

	# Overwrite normal candidates with favorite tasks up to favorited count
	var normal_favs = GameState.favorite_tasks.get("normal", [])
	for i in range(min(normal_favs.size(), chosen_normal.size())):
		chosen_normal[i] = normal_favs[i]

	# 2. Advanced Candidates
	var advanced_pool = Content.get_task_pool().get("advanced", [])
	var advanced_ids = []
	for t in advanced_pool:
		advanced_ids.append(t.get("id"))
	# Select unique random advanced tasks
	advanced_ids.shuffle()
	var chosen_advanced = advanced_ids.slice(0, min(Config.get_daily_candidates("advanced"), advanced_ids.size()))

	# Overwrite advanced candidates with favorite tasks up to favorited count
	var advanced_favs = GameState.favorite_tasks.get("advanced", [])
	for i in range(min(advanced_favs.size(), chosen_advanced.size())):
		chosen_advanced[i] = advanced_favs[i]

	# 3. Save in GameState
	GameState.set_today_candidates(chosen_normal, chosen_advanced)

func complete_task(task_id: String) -> void:
	var sel_normal = GameState.today_selected.get("normal", [])
	var sel_advanced = GameState.today_selected.get("advanced", [])
	var extra_advanced = GameState.today_selected.get("extra_advanced", "")
	var completed = GameState.today_completed

	var is_normal = task_id in sel_normal
	var is_advanced = (task_id in sel_advanced) or (task_id == extra_advanced and not extra_advanced.is_empty())
	
	if not (is_normal or is_advanced):
		printerr("TaskSystem: Task not selected: ", task_id)
		return
	if task_id in completed:
		printerr("TaskSystem: Task already completed: ", task_id)
		return

	# Determine category and reward energy
	var kind = "normal" if is_normal else "advanced"
	var energy_reward = Config.get_task_energy(kind)
	
	GameState.add_energy(energy_reward, "task")
	GameState.mark_task_completed(task_id)

	# Log to diary
	GameState.log_to_diary(GameState.game_day, "completed_tasks", task_id)
	GameState.log_to_diary(GameState.game_day, "energy_earned", energy_reward)

	# Check if all selected tasks are completed today
	var selected_tasks = sel_normal.duplicate()
	for t_id in sel_advanced:
		if not (t_id in selected_tasks):
			selected_tasks.append(t_id)
	if not extra_advanced.is_empty() and not (extra_advanced in selected_tasks):
		selected_tasks.append(extra_advanced)

	var all_done = true
	for t_id in selected_tasks:
		if not (t_id in GameState.today_completed):
			all_done = false
			break

	if all_done and not selected_tasks.is_empty():
		var recorded = GameState.get_flag("all_tasks_completed_today", false)
		if not recorded:
			GameState.all_completed_days_this_week += 1
			GameState.set_flag("all_tasks_completed_today", true)
			all_today_tasks_done.emit()

	task_completed.emit(task_id)

func unlock_extra_advanced_via_ad() -> void:
	if GameState.daily_ad_extra_claimed:
		printerr("TaskSystem: Extra ad task already claimed today.")
		return
	if _ad_request_in_progress:
		return
	
	_ad_request_in_progress = true
	AdService.request_rewarded()

func complete_super_task(text: String) -> bool:
	if GameState.super_task_credits <= 0:
		printerr("TaskSystem: No super task credits available.")
		return false
	if GameState.super_task_completed_today:
		printerr("TaskSystem: Already completed a super task today.")
		return false

	GameState.super_task_credits -= 1
	var energy_reward = Config.get_task_energy("super")
	GameState.add_energy(energy_reward, "super_task")
	GameState.mark_super_task_done()

	# Log to diary
	var record_str = "Super Task: " + text
	GameState.log_to_diary(GameState.game_day, "completed_tasks", record_str)
	GameState.log_to_diary(GameState.game_day, "energy_earned", energy_reward)
	return true

func _on_ad_success() -> void:
	if not _ad_request_in_progress:
		return
	_ad_request_in_progress = false

	# Select 1 unselected advanced candidate
	var candidates = GameState.today_candidates.get("advanced", [])
	var selected = GameState.today_selected.get("advanced", [])
	var unselected = []
	for t_id in candidates:
		if not (t_id in selected):
			unselected.append(t_id)

	if not unselected.is_empty():
		GameState.set_extra_advanced(unselected[0])
		GameState.mark_daily_ad_extra_claimed()
	else:
		printerr("TaskSystem: No unselected advanced candidates available to unlock.")

func _on_ad_fail(reason: String) -> void:
	if not _ad_request_in_progress:
		return
	_ad_request_in_progress = false
	printerr("TaskSystem: Ad request failed: ", reason)
