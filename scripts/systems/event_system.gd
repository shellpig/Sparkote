extends Node

func play(event_id: String) -> void:
	var event_data = Content.get_event(event_id)
	if event_data.is_empty():
		printerr("EventSystem: Event not found: ", event_id)
		return
	
	UINavigation.open_overlay("event_player", {"event_id": event_id, "data": event_data, "is_replay": false})

func replay(event_id: String) -> void:
	var event_data = Content.get_event(event_id)
	if event_data.is_empty():
		printerr("EventSystem: Event not found: ", event_id)
		return

	var choice_idx = GameState.get_event_choice(event_id)
	UINavigation.open_overlay("event_player", {
		"event_id": event_id,
		"data": event_data,
		"is_replay": true,
		"choice_idx": choice_idx
	})

func resolve(event_id: String, choice_idx: int) -> void:
	var event_data = Content.get_event(event_id)
	if event_data.is_empty():
		printerr("EventSystem: Resolve failed, event not found: ", event_id)
		return

	var choices = event_data.get("choices", [])
	var chosen_rewards = {}
	var chosen_effects = {}
	var choice_diary = ""
	
	if choice_idx >= 0 and choice_idx < choices.size():
		var choice = choices[choice_idx]
		chosen_rewards = choice.get("rewards", {})
		chosen_effects = choice.get("effects", {})
		choice_diary = choice.get("diary", "")
	else:
		# If choice_idx is invalid, fall back to event-level rewards/effects
		chosen_rewards = event_data.get("rewards", {})
		chosen_effects = event_data.get("effects", {})
		choice_diary = event_data.get("diary", "")

	# Apply rewards & effects atomically via GameState
	GameState.apply_rewards(chosen_rewards)
	GameState.apply_effects(chosen_effects)
	GameState.mark_event_completed(event_id, choice_idx)
	
	# Write narrative log to diary
	var record_diary = choice_diary if not choice_diary.is_empty() else event_data.get("title", "Event")
	GameState.log_to_diary(GameState.game_day, "unlocked_events", record_diary)
	
	# Close event overlay
	UINavigation.close_overlay()
