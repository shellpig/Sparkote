extends GutTest

func before_all():
	Config.load_config("res://tests/fixtures/config.json")

func test_get_task_energy():
	assert_eq(Config.get_task_energy("normal"), 1)
	assert_eq(Config.get_task_energy("advanced"), 2)
	assert_eq(Config.get_task_energy("super"), 3)

func test_get_energy_cap():
	assert_eq(Config.get_energy_cap(), 20)

func test_get_thresholds():
	assert_eq(Config.get_energy_hint_threshold(), 10)
	assert_eq(Config.get_energy_near_cap_threshold(), 18)

func test_slots_and_candidates():
	assert_eq(Config.get_daily_slots("normal"), 2)
	assert_eq(Config.get_daily_slots("advanced"), 1)
	assert_eq(Config.get_daily_candidates("normal"), 6)
	assert_eq(Config.get_daily_candidates("advanced"), 3)

func test_recollect_limits():
	assert_eq(Config.get_recollect_cost(), 1)
	assert_eq(Config.get_recollect_daily_limit(), 1)
	assert_eq(Config.get_weekly_super_threshold(), 4)
