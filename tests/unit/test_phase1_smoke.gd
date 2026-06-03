extends GutTest

# Phase 1 整合煙霧測試
# 對應：測試指南 §5；規格書 §2 核心循環
# 端到端驗：new_game → 完成任務 → 翻格 → 事件 → 修復家園 → 採集資源點 → advance_day → 存讀檔

func before_all():
	Config.load_config("res://tests/fixtures/config.json")
	Content.content_dir = "res://tests/fixtures/"
	Content.load_all()

func before_each():
	GameState.new_game()
	Exploration.current_map_id = ""
	GameState.unlocked_maps.clear()
	GameState.revealed_tiles.clear()
	UINavigation.overlay_stack.clear()
	UINavigation.is_input_frozen = false
	Exploration.unlock_map("map_1")
	Exploration.set_current_map("map_1")

# ═══════════════════════════════════════════════════════════
# 端到端一日煙霧（自動）
# ═══════════════════════════════════════════════════════════

func test_phase1_full_day_chain():
	# ── 1. 骰任務 ──
	TaskSystem.roll_today()
	assert_eq(GameState.today_candidates["normal"].size(), 6)
	assert_eq(GameState.today_candidates["advanced"].size(), 3)

	# ── 2. 選 1 普通任務並完成 → 得能量 ──
	var n1 = GameState.today_candidates["normal"][0]
	GameState.choose_task(n1, false)
	var energy_before_task = GameState.get_energy()
	TaskSystem.complete_task(n1)
	var energy_after_task = GameState.get_energy()
	assert_eq(energy_after_task, energy_before_task + Config.get_task_energy("normal"),
		"normal task should give correct energy")

	# ── 3. 翻格（discovery → resource_point → event） ──
	# 確保有足夠能量翻三格
	GameState.add_energy(10)

	var energy_before_flip = GameState.get_energy()

	# tile_discovery（cost 1, type discovery, rewards wood:2）
	var outcome_disc = Exploration.flip_tile("map_1", "tile_discovery")
	assert_true(outcome_disc.get("ok", false), "flip tile_discovery should succeed")
	assert_eq(GameState.get_resource("wood"), 2, "discovery tile should give wood:2")

	# tile_resource（cost 2, type resource_point, first_rewards stone:5）
	var outcome_res = Exploration.flip_tile("map_1", "tile_resource")
	assert_true(outcome_res.get("ok", false), "flip tile_resource should succeed")
	assert_eq(GameState.get_resource("stone"), 5, "resource_point first flip should give stone:5")

	# 能量帳：扣 1 + 2 = 3
	assert_eq(GameState.get_energy(), energy_before_flip - 3,
		"energy should be reduced by flip costs")

	# 日記翻格數
	var diary_mid = GameState.get_diary(GameState.game_day)
	assert_eq(diary_mid.get("tiles_revealed", 0), 2, "diary should log 2 tiles flipped")

	# ── 4. 翻事件格 → resolve ──
	GameState.add_energy(3)
	Exploration.flip_tile("map_1", "tile_event")
	# EventSystem.play 已被 flip_tile 呼叫；手動 resolve（choice 0 → door_key:1）
	EventSystem.resolve("evt_01", 0)
	assert_true(GameState.is_event_completed("evt_01"),
		"event should be marked completed after resolve")
	assert_true(GameState.has_task_item("door_key", 1),
		"resolve choice 0 should grant door_key")

	# 日記事件紀錄
	var diary_after_event = GameState.get_diary(GameState.game_day)
	assert_false(diary_after_event.get("unlocked_events", []).is_empty(),
		"diary should log resolved event")

	# ── 5. 修復家園 ──
	# camper_engine lv0→1 需要 wood:5, stone:2
	GameState.add_resource("wood", 5)
	GameState.add_resource("stone", 2)
	var repair_ok = HomeSystem.repair("camper_engine")
	assert_true(repair_ok, "repair should succeed with enough resources")
	assert_eq(GameState.get_repair_level("camper_engine"), 1,
		"repair level should advance to 1")

	var diary_after_repair = GameState.get_diary(GameState.game_day)
	assert_false(diary_after_repair.get("home_changes", []).is_empty(),
		"diary should log home repair")

	# ── 6. 資源點重採 ──
	GameState.add_energy(5)
	var energy_before_collect = GameState.get_energy()
	var stone_before_collect = GameState.get_resource("stone")

	var collect_outcome = ResourcePoint.collect("map_1", "tile_resource")
	assert_true(collect_outcome.get("ok", false), "collect should succeed")
	assert_eq(GameState.get_energy(), energy_before_collect - Config.get_recollect_cost(),
		"collect should spend recollect_cost energy")
	# collect_rewards stone:2
	assert_eq(GameState.get_resource("stone"), stone_before_collect + 2,
		"collect should give stone:2")

	# ── 7. 能量帳目驗證（整日） ──
	# 此處只確認能量非負、未超上限
	assert_true(GameState.get_energy() >= 0, "energy must never be negative")
	assert_true(GameState.get_energy() <= Config.get_energy_cap(),
		"energy must not exceed cap")

	# ── 8. advance_day ──
	var energy_eod = GameState.get_energy()
	DayCycle.advance_day()

	assert_eq(GameState.game_day, 2, "day should advance to 2")
	assert_eq(GameState.get_energy(), energy_eod, "energy should carry over across day")
	assert_eq(GameState.today_candidates["normal"].size(), 6,
		"candidates should be re-rolled for day 2")
	# resource_point 採集計數應被清零（advance_day 清 collected_resource_points）
	assert_eq(GameState.get_point_collect_count("map_1", "tile_resource"), 0,
		"collect count should reset after advance_day")

	# ── 9. 存檔 round-trip ──
	SaveService.save_to_file()
	var energy_pre_load = GameState.get_energy()
	var repair_level_pre = GameState.get_repair_level("camper_engine")
	var day_pre = GameState.game_day
	var event_completed_pre = GameState.is_event_completed("evt_01")

	# 模擬讀取（from_dict of to_dict）
	var saved_dict = GameState.to_dict()
	GameState.new_game()
	GameState.from_dict(saved_dict)

	assert_eq(GameState.get_energy(), energy_pre_load, "energy must survive round-trip")
	assert_eq(GameState.get_repair_level("camper_engine"), repair_level_pre,
		"repair level must survive round-trip")
	assert_eq(GameState.game_day, day_pre, "game_day must survive round-trip")
	assert_eq(GameState.is_event_completed("evt_01"), event_completed_pre,
		"event completion must survive round-trip")

# ═══════════════════════════════════════════════════════════
# 能量帳目守恆（產出 − 消耗 = 結餘）
# ═══════════════════════════════════════════════════════════

func test_energy_accounting_invariant():
	# 用 fixture 跑一個受控序列（before_each 已初始化 map_1）
	assert_eq(GameState.get_energy(), 0)

	# 產：完成 1 普通任務（+1）
	TaskSystem.roll_today()
	var n1 = GameState.today_candidates["normal"][0]
	GameState.choose_task(n1, false)
	TaskSystem.complete_task(n1)
	assert_eq(GameState.get_energy(), 1)

	# 加能量到足夠翻格
	GameState.add_energy(5)  # 現在 6
	var e_before = GameState.get_energy()  # 6

	# 耗：翻 tile_discovery（cost 1）
	Exploration.flip_tile("map_1", "tile_discovery")
	assert_eq(GameState.get_energy(), e_before - 1, "flip should cost exactly 1")

	# 耗：翻 tile_resource（cost 2）
	Exploration.flip_tile("map_1", "tile_resource")
	assert_eq(GameState.get_energy(), e_before - 3, "two flips should cost 1+2=3 total")

	# 永不負值
	GameState.spend_energy(GameState.get_energy())  # 清光
	assert_eq(GameState.get_energy(), 0)
	var ok = GameState.spend_energy(1)
	assert_false(ok, "spending more than available should fail")
	assert_eq(GameState.get_energy(), 0, "energy must not go negative")
