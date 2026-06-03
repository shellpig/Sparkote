extends GutTest

func before_each():
	UINavigation.overlay_stack.clear()
	UINavigation.is_input_frozen = false
	UINavigation.active_root_page = "task"

func test_root_page_switching():
	# Switch to valid pages
	assert_true(UINavigation.navigate("map"))
	assert_eq(UINavigation.active_root_page, "map")

	assert_true(UINavigation.navigate("home"))
	assert_eq(UINavigation.active_root_page, "home")

	# Switch to invalid page
	assert_false(UINavigation.navigate("invalid_page_name"))
	assert_eq(UINavigation.active_root_page, "home") # unchanged

func test_overlay_stack_freeze_input():
	assert_false(UINavigation.is_input_frozen)

	# Open first overlay
	UINavigation.open_overlay("event_player")
	assert_eq(UINavigation.overlay_stack.size(), 1)
	assert_true(UINavigation.is_input_frozen)

	# Close it
	UINavigation.close_overlay()
	assert_eq(UINavigation.overlay_stack.size(), 0)
	assert_false(UINavigation.is_input_frozen)

func test_nested_overlays():
	assert_false(UINavigation.is_input_frozen)

	# Open level 1
	UINavigation.open_overlay("event_player")
	assert_eq(UINavigation.overlay_stack.size(), 1)
	assert_true(UINavigation.is_input_frozen)

	# Open level 2 (confirm dialog)
	UINavigation.open_overlay("confirm_dialog")
	assert_eq(UINavigation.overlay_stack.size(), 2)
	assert_true(UINavigation.is_input_frozen)

	# Close level 2 (pop back to level 1)
	UINavigation.close_overlay()
	assert_eq(UINavigation.overlay_stack.size(), 1)
	assert_true(UINavigation.is_input_frozen) # Still frozen because level 1 is open

	# Close level 1 (back to base)
	UINavigation.close_overlay()
	assert_eq(UINavigation.overlay_stack.size(), 0)
	assert_false(UINavigation.is_input_frozen) # Unfrozen
