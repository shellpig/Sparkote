extends Node

signal navigation_changed(active_page: String)
signal overlay_opened(kind: String)
signal overlay_closed

const ROOT_PAGES = ["task", "map", "home", "backpack", "diary", "store"]

var active_root_page: String = "task"
var overlay_stack: Array = []
var is_input_frozen: bool = false

func navigate(page: String) -> bool:
	if not (page in ROOT_PAGES):
		printerr("UINavigation: Invalid root page: ", page)
		return false
	
	active_root_page = page
	navigation_changed.emit(active_root_page)
	return true

func open_overlay(kind: String, data: Dictionary = {}) -> void:
	overlay_stack.append({
		"kind": kind,
		"data": data
	})
	is_input_frozen = true
	overlay_opened.emit(kind)

func close_overlay() -> void:
	if overlay_stack.is_empty():
		return
	
	overlay_stack.pop_back()
	if overlay_stack.is_empty():
		is_input_frozen = false
	
	overlay_closed.emit()
