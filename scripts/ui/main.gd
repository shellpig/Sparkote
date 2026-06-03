extends Node

@onready var task_page: Control = $CanvasLayer/UIRoot/Pages/TaskPage
@onready var map_page: Control = $CanvasLayer/UIRoot/Pages/MapPage
@onready var tasks_button: Button = $CanvasLayer/UIRoot/NavBar/TasksButton
@onready var map_button: Button = $CanvasLayer/UIRoot/NavBar/MapButton

func _ready() -> void:
	UINavigation.navigation_changed.connect(_on_navigation_changed)
	_on_navigation_changed(UINavigation.active_root_page)
	
	if GameState.today_candidates.get("normal", []).is_empty():
		TaskSystem.roll_today()

	# Wire up navigation buttons
	tasks_button.pressed.connect(func(): UINavigation.navigate("task"))
	map_button.pressed.connect(func(): UINavigation.navigate("map"))

func _on_navigation_changed(active_page: String) -> void:
	if is_inside_tree():
		if task_page:
			task_page.visible = (active_page == "task")
		if map_page:
			map_page.visible = (active_page == "map")
