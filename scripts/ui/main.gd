extends Node

@onready var task_page: Control = $CanvasLayer/UIRoot/Pages/TaskPage
@onready var map_page: Control = $CanvasLayer/UIRoot/Pages/MapPage
@onready var diary_page: Control = $CanvasLayer/UIRoot/Pages/DiaryPage

@onready var tasks_button: Button = $CanvasLayer/UIRoot/NavBar/TasksButton
@onready var map_button: Button = $CanvasLayer/UIRoot/NavBar/MapButton
@onready var diary_button: Button = $CanvasLayer/UIRoot/NavBar/DiaryButton

@onready var event_player: Control = $CanvasLayer/UIRoot/EventPlayer
@onready var mood_prompt_panel: Control = $CanvasLayer/UIRoot/MoodPromptPanel
@onready var write_now_button: Button = $CanvasLayer/UIRoot/MoodPromptPanel/VBoxContainer/HBoxContainer/WriteNowButton
@onready var later_button: Button = $CanvasLayer/UIRoot/MoodPromptPanel/VBoxContainer/HBoxContainer/LaterButton

func _ready() -> void:
	UINavigation.navigation_changed.connect(_on_navigation_changed)
	_on_navigation_changed(UINavigation.active_root_page)
	
	UINavigation.overlay_opened.connect(_on_overlay_opened)
	UINavigation.overlay_closed.connect(_on_overlay_closed)

	# Connect to task completion signal
	TaskSystem.all_today_tasks_done.connect(_on_all_tasks_completed)

	if GameState.today_candidates.get("normal", []).is_empty():
		TaskSystem.roll_today()

	# Wire up navigation buttons
	tasks_button.pressed.connect(func(): UINavigation.navigate("task"))
	map_button.pressed.connect(func(): UINavigation.navigate("map"))
	diary_button.pressed.connect(func(): UINavigation.navigate("diary"))

	# Wire up mood popup buttons
	write_now_button.pressed.connect(_on_write_mood_now)
	later_button.pressed.connect(_on_later_pressed)

func _on_navigation_changed(active_page: String) -> void:
	if is_inside_tree():
		if task_page:
			task_page.visible = (active_page == "task")
		if map_page:
			map_page.visible = (active_page == "map")
		if diary_page:
			diary_page.visible = (active_page == "diary")
			if diary_page.visible:
				diary_page.viewed_day = GameState.game_day
				diary_page.refresh()

func _on_overlay_opened(kind: String) -> void:
	if kind == "event_player":
		if not UINavigation.overlay_stack.is_empty():
			var overlay_data = UINavigation.overlay_stack.back().get("data", {})
			var e_id = overlay_data.get("event_id", "")
			var e_data = overlay_data.get("data", {})
			var is_rep = overlay_data.get("is_replay", false)
			var choice_idx = overlay_data.get("choice_idx", -1)

			event_player.initialize(e_id, e_data, is_rep, choice_idx)
			event_player.visible = true

func _on_overlay_closed() -> void:
	# Hide overlay when popped
	event_player.visible = false

func _on_all_tasks_completed() -> void:
	mood_prompt_panel.visible = true

func _on_write_mood_now() -> void:
	mood_prompt_panel.visible = false
	UINavigation.navigate("diary")
	if diary_page:
		diary_page.focus_mood_edit()

func _on_later_pressed() -> void:
	mood_prompt_panel.visible = false
