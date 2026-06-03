extends GutTest

# 涵蓋 Phase 1-E：HomeSystem 修復 + 插槽，ResourcePoint 重採 + 集中採集頁
# 測試指南 §4.5

func before_all():
	Config.load_config("res://tests/fixtures/config.json")
	Content.content_dir = "res://tests/fixtures/"
	Content.load_all()

func before_each():
	GameState.new_game()
	# 清理探索狀態
	Exploration.current_map_id = ""
	GameState.unlocked_maps.clear()
	GameState.revealed_tiles.clear()
	# 解鎖 map_1 並設為當前（首採 tile_resource 用）
	Exploration.unlock_map("map_1")
	Exploration.set_current_map("map_1")

# ═══════════════════════════════════════════════════════════
# HomeSystem — 修復
# ═══════════════════════════════════════════════════════════

func test_repair_success_spend_resource_and_advance_level():
	# 確保持有足夠資源（camper_engine lv1 cost: wood:5, stone:2）
	GameState.add_resource("wood", 5)
	GameState.add_resource("stone", 2)
	assert_eq(GameState.get_repair_level("camper_engine"), 0)

	var ok = HomeSystem.repair("camper_engine")

	assert_true(ok)
	assert_eq(GameState.get_repair_level("camper_engine"), 1)
	# 資源精準扣除
	assert_eq(GameState.get_resource("wood"), 0)
	assert_eq(GameState.get_resource("stone"), 0)

func test_repair_logs_to_diary():
	GameState.add_resource("wood", 5)
	GameState.add_resource("stone", 2)

	HomeSystem.repair("camper_engine")

	var diary = GameState.get_diary(GameState.game_day)
	assert_false(diary.get("home_changes", []).is_empty(),
		"diary home_changes should have repair entry")

func test_repair_insufficient_resource_returns_false_and_no_deduct():
	# 只給部份資源（少木材）
	GameState.add_resource("wood", 2)
	GameState.add_resource("stone", 2)

	var ok = HomeSystem.repair("camper_engine")

	assert_false(ok)
	assert_eq(GameState.get_repair_level("camper_engine"), 0, "level must not change")
	# 資源不動
	assert_eq(GameState.get_resource("wood"), 2)
	assert_eq(GameState.get_resource("stone"), 2)

func test_repair_at_max_level_returns_false():
	# 把 camper_engine 推到 max (=2)
	GameState.add_resource("wood", 15)
	GameState.add_resource("stone", 7)
	HomeSystem.repair("camper_engine")  # lv0 -> lv1
	HomeSystem.repair("camper_engine")  # lv1 -> lv2
	assert_eq(GameState.get_repair_level("camper_engine"), 2)

	# 再修一次應被拒
	GameState.add_resource("wood", 99)
	GameState.add_resource("stone", 99)
	var ok = HomeSystem.repair("camper_engine")

	assert_false(ok)
	assert_eq(GameState.get_repair_level("camper_engine"), 2, "level must remain at max")

func test_repair_second_level_uses_correct_cost():
	# lv1: wood:5, stone:2
	GameState.add_resource("wood", 5)
	GameState.add_resource("stone", 2)
	HomeSystem.repair("camper_engine")
	assert_eq(GameState.get_repair_level("camper_engine"), 1)

	# lv2: wood:10, stone:5
	GameState.add_resource("wood", 10)
	GameState.add_resource("stone", 5)
	var ok = HomeSystem.repair("camper_engine")

	assert_true(ok)
	assert_eq(GameState.get_repair_level("camper_engine"), 2)
	assert_eq(GameState.get_resource("wood"), 0)
	assert_eq(GameState.get_resource("stone"), 0)

func test_repair_emits_home_changed_signal():
	GameState.add_resource("wood", 5)
	GameState.add_resource("stone", 2)

	watch_signals(GameState)
	HomeSystem.repair("camper_engine")

	assert_signal_emitted(GameState, "home_changed", "home_changed should fire after repair")

# ═══════════════════════════════════════════════════════════
# HomeSystem — 插槽佈置
# ═══════════════════════════════════════════════════════════

func test_place_furniture_correct_type_succeeds():
	# slot_van_chair accepts: ["chair"]，chair_1 furniture_type: "chair"
	GameState.add_furniture("chair_1")
	var ok = HomeSystem.place_furniture("slot_van_chair", "chair_1")

	assert_true(ok)
	assert_eq(GameState.slot_furnitures.get("slot_van_chair", ""), "chair_1")

func test_place_furniture_wrong_type_fails():
	# slot_van_chair accepts: ["chair"]，table_1 furniture_type: "table" → 不符
	GameState.add_furniture("table_1")
	var ok = HomeSystem.place_furniture("slot_van_chair", "table_1")

	assert_false(ok)
	assert_eq(GameState.slot_furnitures.get("slot_van_chair", ""), "",
		"slot must remain empty on wrong type")

func test_place_furniture_correct_type_table_slot():
	# slot_van_table accepts: ["table"]，table_1 furniture_type: "table"
	GameState.add_furniture("table_1")
	var ok = HomeSystem.place_furniture("slot_van_table", "table_1")

	assert_true(ok)
	assert_eq(GameState.slot_furnitures.get("slot_van_table", ""), "table_1")

func test_place_furniture_does_not_change_energy():
	GameState.add_energy(10)
	GameState.add_furniture("chair_1")
	HomeSystem.place_furniture("slot_van_chair", "chair_1")

	assert_eq(GameState.get_energy(), 10, "energy must not change after place_furniture")

func test_place_furniture_does_not_change_maps():
	var maps_before = GameState.unlocked_maps.duplicate()
	GameState.add_furniture("chair_1")
	HomeSystem.place_furniture("slot_van_chair", "chair_1")

	assert_eq(GameState.unlocked_maps, maps_before, "unlocked_maps must not change")

func test_remove_furniture_clears_slot():
	GameState.add_furniture("chair_1")
	HomeSystem.place_furniture("slot_van_chair", "chair_1")
	assert_eq(GameState.slot_furnitures.get("slot_van_chair", ""), "chair_1")

	HomeSystem.remove_furniture("slot_van_chair")

	assert_eq(GameState.slot_furnitures.get("slot_van_chair", ""), "")

func test_place_replace_furniture_in_slot():
	# 先放 chair_1 再換 chair_1（同類型，替換）
	GameState.add_furniture("chair_1")
	HomeSystem.place_furniture("slot_van_chair", "chair_1")

	# 再放同類型（重覆放視為替換，直接覆寫）
	GameState.add_furniture("chair_1")
	var ok = HomeSystem.place_furniture("slot_van_chair", "chair_1")
	assert_true(ok)
	assert_eq(GameState.slot_furnitures.get("slot_van_chair", ""), "chair_1")

# ═══════════════════════════════════════════════════════════
# ResourcePoint — 重採
# ═══════════════════════════════════════════════════════════

func test_collect_success_spends_energy_and_gives_rewards():
	# 先翻開 tile_resource
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")  # 翻開前置
	Exploration.flip_tile("map_1", "tile_resource")   # 首採拿 stone:5

	var stone_after_first = GameState.get_resource("stone")
	# 補充能量供重採（成本 1）
	GameState.add_energy(5)
	var energy_before = GameState.get_energy()

	var outcome = ResourcePoint.collect("map_1", "tile_resource")

	assert_true(outcome.get("ok", false), "collect should succeed")
	# 能量扣 1（recollect_cost）
	assert_eq(GameState.get_energy(), energy_before - 1)
	# collect_rewards: stone:2
	assert_eq(GameState.get_resource("stone"), stone_after_first + 2)

func test_collect_marks_collect_count():
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")
	GameState.add_energy(5)

	assert_eq(GameState.get_point_collect_count("map_1", "tile_resource"), 0)
	ResourcePoint.collect("map_1", "tile_resource")
	assert_eq(GameState.get_point_collect_count("map_1", "tile_resource"), 1)

func test_collect_count_exceeded_returns_false():
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")
	GameState.add_energy(10)

	# daily_limit = 1（fixture config）
	ResourcePoint.collect("map_1", "tile_resource")  # 第一次 OK

	var energy_before = GameState.get_energy()
	var stone_before = GameState.get_resource("stone")

	var outcome = ResourcePoint.collect("map_1", "tile_resource")  # 第二次 → 被拒

	assert_false(outcome.get("ok", true))
	assert_eq(outcome.get("reason"), "count_exceeded")
	assert_eq(GameState.get_energy(), energy_before, "energy must not change")
	assert_eq(GameState.get_resource("stone"), stone_before, "stone must not change")

func test_collect_no_energy_returns_false():
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")
	# 把能量清光（consume all）
	GameState.spend_energy(GameState.get_energy())
	assert_eq(GameState.get_energy(), 0)

	var outcome = ResourcePoint.collect("map_1", "tile_resource")

	assert_false(outcome.get("ok", true))
	assert_eq(outcome.get("reason"), "no_energy")

func test_collect_unrevealed_tile_returns_false():
	# tile_resource 未翻開
	var outcome = ResourcePoint.collect("map_1", "tile_resource")
	assert_false(outcome.get("ok", true))
	assert_eq(outcome.get("reason"), "tile_not_revealed")

func test_collect_non_resource_point_tile_returns_false():
	# tile_discovery 是 discovery 類型，不是 resource_point
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")
	GameState.add_energy(5)

	var outcome = ResourcePoint.collect("map_1", "tile_discovery")
	assert_false(outcome.get("ok", true))
	assert_eq(outcome.get("reason"), "not_resource_point")

func test_collect_restores_after_advance_day():
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")
	GameState.add_energy(5)
	ResourcePoint.collect("map_1", "tile_resource")  # 今日次數用完

	# 跳日重置 collected_resource_points（DayCycle.advance_day 清零）
	# 手動模擬 advance_day 對 collected_resource_points 的效果
	GameState.collected_resource_points.clear()
	assert_eq(GameState.get_point_collect_count("map_1", "tile_resource"), 0)

	GameState.add_energy(5)
	var outcome = ResourcePoint.collect("map_1", "tile_resource")
	assert_true(outcome.get("ok", false), "collect should work again after day reset")

# ═══════════════════════════════════════════════════════════
# ResourcePoint — get_collectable_points
# ═══════════════════════════════════════════════════════════

func test_get_collectable_points_lists_revealed_resource_points():
	# 翻開 map_1 tile_resource
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")

	var points = ResourcePoint.get_collectable_points()

	var found = false
	for p in points:
		if p.get("map_id") == "map_1" and p.get("tile_id") == "tile_resource":
			found = true
			break
	assert_true(found, "tile_resource should be in collectable points")

func test_get_collectable_points_excludes_unrevealed():
	# tile_resource 未翻，不應出現
	var points = ResourcePoint.get_collectable_points()

	var found = false
	for p in points:
		if p.get("tile_id") == "tile_resource":
			found = true
	assert_false(found, "unrevealed tile must not appear in collectable points")

func test_get_collectable_points_multi_map():
	# 解鎖 map_2 並翻開 tile_sky_resource
	Exploration.unlock_map("map_2")
	GameState.mark_revealed("map_2", "tile_sky_start")
	GameState.add_energy(5)
	Exploration.flip_tile("map_2", "tile_sky_resource")

	# 也翻開 map_1 tile_resource
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")

	var points = ResourcePoint.get_collectable_points()

	var map1_found = false
	var map2_found = false
	for p in points:
		if p.get("map_id") == "map_1" and p.get("tile_id") == "tile_resource":
			map1_found = true
		if p.get("map_id") == "map_2" and p.get("tile_id") == "tile_sky_resource":
			map2_found = true

	assert_true(map1_found, "map_1 resource point should appear")
	assert_true(map2_found, "map_2 resource point should appear")

func test_get_collectable_points_unlocked_but_unrevealed_map_not_included():
	# 解鎖 map_2 但不翻 tile_sky_resource
	Exploration.unlock_map("map_2")

	var points = ResourcePoint.get_collectable_points()

	var found = false
	for p in points:
		if p.get("map_id") == "map_2" and p.get("tile_id") == "tile_sky_resource":
			found = true
	assert_false(found, "unrevealed tile on unlocked map must not appear")

func test_get_collectable_points_shows_correct_today_count():
	GameState.add_energy(10)
	Exploration.flip_tile("map_1", "tile_discovery")
	Exploration.flip_tile("map_1", "tile_resource")
	GameState.add_energy(5)

	ResourcePoint.collect("map_1", "tile_resource")  # count -> 1

	var points = ResourcePoint.get_collectable_points()
	for p in points:
		if p.get("tile_id") == "tile_resource":
			assert_eq(p.get("today_count"), 1)
			assert_eq(p.get("daily_limit"), Config.get_recollect_daily_limit())
			assert_eq(p.get("cost"), Config.get_recollect_cost())

# ═══════════════════════════════════════════════════════════
# HomeSystem — get_home_state
# ═══════════════════════════════════════════════════════════

func test_get_home_state_returns_repairs_and_slots():
	var state = HomeSystem.get_home_state()

	assert_true(state.has("repairs"), "state must have repairs")
	assert_true(state.has("slots"), "state must have slots")
	assert_false(state["repairs"].is_empty(), "repairs must not be empty")
	assert_false(state["slots"].is_empty(), "slots must not be empty")

func test_get_home_state_repair_level_reflects_game_state():
	# 修復前
	var state_before = HomeSystem.get_home_state()
	var repair_entry_before = _find_repair_in_state(state_before, "camper_engine")
	assert_eq(repair_entry_before.get("level"), 0)

	# 修復
	GameState.add_resource("wood", 5)
	GameState.add_resource("stone", 2)
	HomeSystem.repair("camper_engine")

	var state_after = HomeSystem.get_home_state()
	var repair_entry_after = _find_repair_in_state(state_after, "camper_engine")
	assert_eq(repair_entry_after.get("level"), 1)

func test_get_home_state_slot_reflects_placed_furniture():
	GameState.add_furniture("chair_1")
	HomeSystem.place_furniture("slot_van_chair", "chair_1")

	var state = HomeSystem.get_home_state()
	var slot = _find_slot_in_state(state, "slot_van_chair")
	assert_eq(slot.get("current_furniture"), "chair_1")

# ─── helpers ───
func _find_repair_in_state(state: Dictionary, repair_id: String) -> Dictionary:
	for r in state.get("repairs", []):
		if r.get("id") == repair_id:
			return r
	return {}

func _find_slot_in_state(state: Dictionary, slot_id: String) -> Dictionary:
	for s in state.get("slots", []):
		if s.get("id") == slot_id:
			return s
	return {}
