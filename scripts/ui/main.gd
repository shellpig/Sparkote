extends Node

@onready var task_page: Control = $CanvasLayer/UIRoot/Pages/TaskPage

func _ready() -> void:
	UINavigation.navigation_changed.connect(_on_navigation_changed)
	_on_navigation_changed(UINavigation.active_root_page)
	
	if GameState.today_candidates.get("normal", []).is_empty():
		TaskSystem.roll_today()

func _on_navigation_changed(active_page: String) -> void:
	if is_inside_tree() and task_page:
		task_page.visible = (active_page == "task")
