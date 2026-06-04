## test_economy_sim.gd
## Phase 2-A: dev 工具接線驗證（GUT 自動化）
##
## 涵蓋規格：測試指南 §6.1
##   - 跳日鈕接線：SkipDayButton → DayCycle.advance_day → 正確重置
##   - 廣告鈕接線：AdButton → AdService stub 成功 → 解鎖 1 額外高級任務
##                daily_ad_extra_claimed 防重複領；完成後 +2 能量
##   - 經濟模擬數學：以 GDScript 內嵌跑同一套帳目邏輯，驗輸出合理性
##
## 注意：這是 GUT headless 測試，不開 UI scene。
##       跳日鈕 / 廣告鈕的「按鈕存在於 scene tree」由手動驗收清單涵蓋（測試指南 §4.2）。

extends GutTest

# ─── 常數（對齊 config.json 與 sim_economy.gd，不讀 autoload，保持 headless 穩定）
const ENERGY_CAP: int = 20
const BASE_INCOME: int = 4    # 2×1(normal) + 1×2(advanced)
const AD_BONUS: int = 2       # 廣告額外高級任務
const GIFT_D1: int = 6        # 新手贈點 D1 placeholder（與 sim_economy.gd 同步）

# ─── Setup / Teardown ───────────────────────────────────────

func before_all() -> void:
	Config.load_config("res://tests/fixtures/config.json")
	Content.content_dir = "res://tests/fixtures/"
	Content.load_all()

func before_each() -> void:
	GameState.new_game()
	TaskSystem.roll_today()

func after_each() -> void:
	pass

# ─── 6.1 跳日鈕接線 ──────────────────────────────────────────

func test_skip_day_advances_day_and_resets_flags() -> void:
	# Given: day1，完成一個普通任務
	var norm_candidates = GameState.today_candidates.get("normal", [])
	gut.p("normal candidates: " + str(norm_candidates))
	assert_true(norm_candidates.size() > 0, "should have normal candidates")
	var task_id = norm_candidates[0]
	GameState.choose_task(task_id, false)
	TaskSystem.complete_task(task_id)
	var energy_before_advance = GameState.get_energy()

	# When: advance_day（跳日鈕的效果）
	DayCycle.advance_day()

	# Then: 遊戲日 +1
	assert_eq(GameState.game_day, 2, "game_day should be 2 after advance")

	# Then: 當日任務狀態重置（completed 清空、candidates 重骰）
	var completed = GameState.today_completed
	assert_eq(completed.size(), 0, "today_completed should be empty after advance")
	var new_candidates = GameState.today_candidates.get("normal", [])
	assert_eq(new_candidates.size(), Config.get_daily_candidates("normal"),
		"should have fresh normal candidates after advance")

	# Then: 廣告額外任務旗標重置
	assert_false(GameState.daily_ad_extra_claimed,
		"daily_ad_extra_claimed should reset after advance_day")

	# Then: 能量結轉（不歸零）
	assert_eq(GameState.get_energy(), energy_before_advance,
		"energy should carry over intact (no tasks done on day2 yet)")

func test_skip_day_multiple_times_increments_day() -> void:
	DayCycle.advance_day()
	DayCycle.advance_day()
	assert_eq(GameState.game_day, 3, "game_day should be 3 after two advances from day1")

# ─── 6.1 廣告鈕接線 ──────────────────────────────────────────

func test_ad_button_unlocks_extra_advanced_via_stub() -> void:
	# Given: 先選 1 個高級任務填滿 advanced 槽位
	var adv_candidates = GameState.today_candidates.get("advanced", [])
	assert_true(adv_candidates.size() > 0, "should have advanced candidates")
	var adv_id = adv_candidates[0]
	GameState.choose_task(adv_id, true)

	# Verify pre-condition
	var pre_extra = GameState.today_selected.get("extra_advanced", "")
	assert_true(pre_extra.is_empty(), "no extra advanced before ad")

	# When: 呼叫廣告解鎖（stub 是非同步，await 成功 signal）
	AdService.force_fail = false
	TaskSystem.unlock_extra_advanced_via_ad()
	await AdService.rewarded_ad_succeeded

	# Then: daily_ad_extra_claimed = true
	assert_true(GameState.daily_ad_extra_claimed,
		"daily_ad_extra_claimed should be true after ad unlock")

	# Then: extra_advanced 被設定（從未選高級候選中選 1 個）
	var extra = GameState.today_selected.get("extra_advanced", "")
	assert_false(extra.is_empty(), "extra_advanced should be set after ad unlock")

	# Then: 完成額外高級任務給 advanced 等級能量（+2）
	var e_before = GameState.get_energy()
	TaskSystem.complete_task(extra)
	var e_after = GameState.get_energy()
	assert_eq(e_after - e_before, Config.get_task_energy("advanced"),
		"completing extra advanced should give advanced energy (2)")

func test_ad_button_blocks_second_claim_same_day() -> void:
	# First call（await 成功 signal）
	AdService.force_fail = false
	TaskSystem.unlock_extra_advanced_via_ad()
	await AdService.rewarded_ad_succeeded
	assert_true(GameState.daily_ad_extra_claimed, "first ad claim should succeed")

	# Second call: 記錄 extra 前後，不可再改
	var extra_before = GameState.today_selected.get("extra_advanced", "")
	TaskSystem.unlock_extra_advanced_via_ad()
	# 第二次因 daily_ad_extra_claimed 直接 return，不 await
	var extra_after = GameState.today_selected.get("extra_advanced", "")
	assert_eq(extra_before, extra_after, "second ad claim should not change extra_advanced")

func test_ad_claim_resets_after_advance_day() -> void:
	AdService.force_fail = false
	TaskSystem.unlock_extra_advanced_via_ad()
	await AdService.rewarded_ad_succeeded
	assert_true(GameState.daily_ad_extra_claimed)
	DayCycle.advance_day()
	assert_false(GameState.daily_ad_extra_claimed,
		"daily_ad_extra_claimed should reset after advance_day")

# ─── 6.1 經濟曲線模擬數學驗證 ────────────────────────────────

func test_sim_base_income_math() -> void:
	# 驗 BASE_INCOME = DAILY_NORMAL_SLOTS×1 + DAILY_ADVANCED_SLOTS×2 = 4
	var normal_slots = Config.get_daily_slots("normal")     # 2
	var advanced_slots = Config.get_daily_slots("advanced") # 1
	var normal_energy = Config.get_task_energy("normal")    # 1
	var advanced_energy = Config.get_task_energy("advanced") # 2
	var base = normal_slots * normal_energy + advanced_slots * advanced_energy
	assert_eq(base, BASE_INCOME, "base income should be 4/day")

func test_sim_with_ad_income() -> void:
	var ad_energy = Config.get_task_energy("advanced") # 2
	var total = BASE_INCOME + ad_energy
	assert_eq(total, 6, "with ad: income should be 6/day")

func test_sim_energy_cap_clamping() -> void:
	var cap = Config.get_energy_cap() # 20
	GameState.add_energy(cap + 5, "test")
	assert_eq(GameState.get_energy(), cap, "energy should be clamped at cap")

func test_sim_day6_hard_gate_placeholder() -> void:
	# 以 placeholder 序列驗 D6 邏輯：
	# 每日收入 6（有廣告），贈點 D1~D7 緩降：6,4,3,2,1,1,0
	# 格成本 1，每日 tiles_wanted 序列：3,4,4,5,5,5,6
	# 跑 6 日，看 Day6 tiles_actual
	var gift_seq = [6, 4, 3, 2, 1, 1, 0]
	var tiles_seq = [3, 4, 4, 5, 5, 5, 6]
	var cap: int = Config.get_energy_cap()
	var carryover: float = 0.0

	for day_idx in range(6):
		var gift: int = gift_seq[day_idx] if day_idx < gift_seq.size() else 0
		var income: float = BASE_INCOME + AD_BONUS + gift
		var available: float = minf(carryover + income, cap)
		var tiles_wanted: int = tiles_seq[day_idx] if day_idx < tiles_seq.size() else 6
		var tiles_actual: int = mini(tiles_wanted, int(available))
		var spend: float = tiles_actual * 1.0
		carryover = available - spend
		if day_idx == 5: # Day6
			assert_true(tiles_actual >= 4,
				"Day6 tiles_actual (%d) should be >= 4 (hard gate)" % tiles_actual)

func test_sim_no_energy_goes_negative() -> void:
	# 模擬帳目不會讓 carryover 變負
	var gift_seq = [6, 4, 3, 2, 1, 1, 0]
	var tiles_seq = [3, 4, 4, 5, 5, 5, 6]
	var cap: int = Config.get_energy_cap()
	var carryover: float = 0.0

	for day_idx in range(10):
		var gift: int = gift_seq[day_idx] if day_idx < gift_seq.size() else 0
		var income: float = BASE_INCOME + AD_BONUS + gift
		var available: float = minf(carryover + income, cap)
		var tiles_wanted: int = tiles_seq[day_idx] if day_idx < tiles_seq.size() else 6
		var tiles_actual: int = mini(tiles_wanted, int(available))
		var spend: float = tiles_actual * 1.0
		carryover = available - spend
		assert_true(carryover >= 0.0,
			"carryover on day %d should never go negative (got %.1f)" % [day_idx + 1, carryover])
