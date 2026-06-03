extends GutTest

func test_load_all_success():
	Content.content_dir = "res://tests/fixtures/"
	var err = Content.load_all()
	assert_eq(err, OK)

	# Test queries
	var tasks = Content.get_task_pool()
	assert_gt(tasks.get("normal", []).size(), 0)
	assert_gt(tasks.get("advanced", []).size(), 0)

	var map = Content.get_map("map_1")
	assert_eq(map.get("id"), "map_1")
	assert_eq(map.get("name"), "Mist Forest")

	var event = Content.get_event("evt_01")
	assert_eq(event.get("id"), "evt_01")
	assert_eq(event.get("title"), "A Mysterious Letter")

	var item = Content.get_item("wood")
	assert_eq(item.get("id"), "wood")
	assert_eq(item.get("kind"), "resource")

	var slots = Content.get_home_slots()
	assert_gt(slots.size(), 0)

	var repairs = Content.get_home_repairs()
	assert_gt(repairs.size(), 0)

func test_load_all_validation_failure():
	# Use directory containing bad map (non-existent start_tile)
	Content.content_dir = "res://tests/fixtures/bad/"
	var err = Content.load_all()
	assert_ne(err, OK)
