extends Control

@onready var title_label: Label = $VBoxContainer/Header/TitleLabel
@onready var prev_btn: Button = $VBoxContainer/Header/PrevButton
@onready var next_btn: Button = $VBoxContainer/Header/NextButton
@onready var energy_label: Label = $VBoxContainer/ScrollContainer/Body/Stats/EnergyLabel
@onready var tiles_label: Label = $VBoxContainer/ScrollContainer/Body/Stats/TilesLabel
@onready var tasks_container: VBoxContainer = $VBoxContainer/ScrollContainer/Body/TasksContainer
@onready var events_container: VBoxContainer = $VBoxContainer/ScrollContainer/Body/EventsContainer
@onready var mood_edit: TextEdit = $VBoxContainer/ScrollContainer/Body/MoodNoteSection/MoodNoteEdit
@onready var save_mood_btn: Button = $VBoxContainer/ScrollContainer/Body/MoodNoteSection/SaveMoodButton

var viewed_day: int = 1

func _ready() -> void:
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	save_mood_btn.pressed.connect(_on_save_mood_pressed)
	
	GameState.diary_updated.connect(refresh)
	GameState.day_advanced.connect(_on_day_advanced)
	
	viewed_day = GameState.game_day
	refresh()

func _on_day_advanced() -> void:
	viewed_day = GameState.game_day
	refresh()

func _on_prev_pressed() -> void:
	viewed_day = clampi(viewed_day - 1, 1, GameState.game_day)
	refresh()

func _on_next_pressed() -> void:
	viewed_day = clampi(viewed_day + 1, 1, GameState.game_day)
	refresh()

func _on_save_mood_pressed() -> void:
	GameState.write_mood_note(viewed_day, mood_edit.text)

func focus_mood_edit() -> void:
	mood_edit.grab_focus()

func refresh() -> void:
	if not is_inside_tree():
		return
		
	prev_btn.disabled = (viewed_day <= 1)
	next_btn.disabled = (viewed_day >= GameState.game_day)
	
	title_label.text = "Diary - Day %d" % viewed_day
	
	var diary_data = GameState.get_diary(viewed_day)
	
	# Update stats
	var energy_earned = diary_data.get("energy_earned", 0)
	var tiles_revealed = diary_data.get("tiles_revealed", 0)
	energy_label.text = "Energy Earned Today: %d" % energy_earned
	tiles_label.text = "Tiles Flipped Today: %d" % tiles_revealed
	
	# Update Tasks completed
	for child in tasks_container.get_children():
		child.queue_free()
		
	var completed_tasks = diary_data.get("completed_tasks", [])
	if completed_tasks.is_empty():
		var lbl = Label.new()
		lbl.text = "No tasks completed today."
		tasks_container.add_child(lbl)
	else:
		for t_text in completed_tasks:
			var lbl = Label.new()
			# t_text is the task ID or a description, try getting content title
			var t_data = Content.get_task(t_text)
			var display_text = t_data.get("text", t_text)
			lbl.text = "• %s" % display_text
			tasks_container.add_child(lbl)
			
	# Update Events completed
	for child in events_container.get_children():
		child.queue_free()
		
	var events_found = false
	for event_id in GameState.completed_events:
		var entry = GameState.completed_events[event_id]
		if int(entry.get("day", 0)) == viewed_day:
			events_found = true
			var e_data = Content.get_event(event_id)
			var e_title = e_data.get("title", event_id)
			var choice_idx = int(entry.get("choice", -1))
			
			var choice_str = ""
			var choices_list = e_data.get("choices", [])
			if choice_idx >= 0 and choice_idx < choices_list.size():
				choice_str = choices_list[choice_idx].get("text", "")
				
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 15)
			
			var lbl = Label.new()
			lbl.text = "• %s %s" % [e_title, ("(Chosen: " + choice_str + ")") if not choice_str.is_empty() else ""]
			hbox.add_child(lbl)
			
			if e_data.get("replayable", true):
				var replay_btn = Button.new()
				replay_btn.text = "Replay"
				var event_to_replay = event_id
				replay_btn.pressed.connect(func(): EventSystem.replay(event_to_replay))
				hbox.add_child(replay_btn)
				
			events_container.add_child(hbox)
			
	if not events_found:
		var lbl = Label.new()
		lbl.text = "No events resolved today."
		events_container.add_child(lbl)
		
	# Update Mood note
	mood_edit.text = diary_data.get("mood_note", "")
