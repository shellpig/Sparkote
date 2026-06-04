## sim_economy.gd
## Phase 2-A: Headless 純經濟曲線模擬（dev-only，不走 UI 也不走真地圖 graph）
##
## 用途：跑出 D1~D10 的逐日 產/耗/結轉/cap溢出/可翻格數，供調參和閘門判定。
## 邊界：這是抽象帳目模型；真地圖手感靠 2-C 跳日實玩。
##
## 執行方式（在專案根目錄）：
##   C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/sim_economy.gd
## 可加參數（命令列 -- 後）：
##   -- --days 10 --ad 1 --tile_cost 1
##
## 輸出到 stdout，可 pipe 存檔。

extends SceneTree

# ─── 預設輸入參數（可由命令列覆寫） ───────────────────────────
## 模擬天數（建議 10，看新手贈點退場後的穩態）
var sim_days: int = 10

## 是否假設每日看廣告（1=看廣告 6/天, 0=不看廣告 4/天）
var use_ad: int = 1

## 平均格成本（暫定 1；2-C 可跑 cost=2 比較）
var tile_cost: float = 1.0

# ─── 能量參數（對齊 config.json §8.3，不從 Config autoload 讀，保持 headless 獨立）
const TASK_ENERGY_NORMAL: int = 1   # 普通任務
const TASK_ENERGY_ADVANCED: int = 2  # 高級任務
const TASK_ENERGY_SUPER: int = 3    # 超級任務（不計入基準）
const ENERGY_CAP: int = 20
const DAILY_NORMAL_SLOTS: int = 2
const DAILY_ADVANCED_SLOTS: int = 1
const AD_EXTRA_ENERGY: int = 2  # 看廣告額外高級任務產出

## 基準每日收入（不含廣告、不含贈點）：2×1 + 1×2 = 4
const BASE_INCOME_PER_DAY: int = DAILY_NORMAL_SLOTS * TASK_ENERGY_NORMAL + DAILY_ADVANCED_SLOTS * TASK_ENERGY_ADVANCED

# ─── 新手贈點序列（D1–D7 緩降；Phase 2-B 真內容落定後由 gate_d1_d7 更新）
## 格式：index 0 = Day1, index 6 = Day7, index 7+ = 0（無贈點）
## 暫定值：D1 +6, D2 +4, D3 +3, D4 +2, D5 +1, D6 +1, D7 +0 → 穩態落回 6/天
## 注意：這只是 placeholder；2-C 閘門調參時會依 gate_d1_d7 真實事件更新這份序列
var gift_sequence: Array = [6, 4, 3, 2, 1, 1, 0]

# ─── 每日可翻格數序列（來自 gate_d1_d7 地圖鋪法；placeholder 先用固定值）
## index 0 = Day1, … 格數代表「今天最多想翻幾格」（供給上限）
## 規格要求 Day6 可翻 ≥ 4 為硬指標
## Placeholder：D1=3, D2=4, D3=4, D4=5, D5=5, D6=5, D7=6（之後由 subdocs 更新）
var tiles_per_day_seq: Array = [3, 4, 4, 5, 5, 5, 6]

# ─── 執行入口 ───────────────────────────────────────────────
func _init() -> void:
	_parse_args()
	_run_simulation()
	quit()

func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--days":
				if i + 1 < args.size():
					sim_days = int(args[i + 1])
					i += 2
					continue
			"--ad":
				if i + 1 < args.size():
					use_ad = int(args[i + 1])
					i += 2
					continue
			"--tile_cost":
				if i + 1 < args.size():
					tile_cost = float(args[i + 1])
					i += 2
					continue
		i += 1

func _run_simulation() -> void:
	print("=== Sparkote Economy Simulation (Phase 2-A) ===")
	print("Config: days=%d  ad=%s  tile_cost=%.1f  energy_cap=%d" % [
		sim_days,
		("yes(+%d)" % AD_EXTRA_ENERGY) if use_ad else "no",
		tile_cost,
		ENERGY_CAP,
	])
	print("Base income/day: %d  Ad bonus: %d  Total if ad: %d" % [
		BASE_INCOME_PER_DAY,
		AD_EXTRA_ENERGY if use_ad else 0,
		BASE_INCOME_PER_DAY + (AD_EXTRA_ENERGY if use_ad else 0),
	])
	print("")
	print("%-5s %-8s %-8s %-8s %-8s %-10s %-10s %-8s" % [
		"Day", "Gift", "Income", "Spend", "Carryover", "Cap_Overflow", "Tiles_Can", "Tiles_Actual"
	])
	print("-".repeat(72))

	var carryover: float = 0.0
	var hard_gate_pass: bool = true
	var cap_overflow_days: Array = []

	for day_idx in range(sim_days):
		var day_num: int = day_idx + 1

		# 今日收入
		var gift: int = gift_sequence[day_idx] if day_idx < gift_sequence.size() else 0
		var ad_bonus: int = AD_EXTRA_ENERGY if use_ad else 0
		var income: float = BASE_INCOME_PER_DAY + ad_bonus + gift

		# 今日可用能量（昨日結轉 + 今日收入，cap 限制）
		var available: float = minf(carryover + income, ENERGY_CAP)
		var cap_overflow: float = maxf(0.0, (carryover + income) - ENERGY_CAP)

		# 今日可翻格數（需求端：content 供給）
		var tiles_wanted: int = tiles_per_day_seq[day_idx] if day_idx < tiles_per_day_seq.size() else 6

		# 今日實際可翻格數（受能量限制）
		var tiles_affordable: int = int(available / tile_cost)
		var tiles_actual: int = mini(tiles_wanted, tiles_affordable)

		# 實際消耗
		var spend: float = tiles_actual * tile_cost

		# 結轉
		carryover = available - spend

		# 硬閘門判定：Day6 可翻 ≥ 4
		if day_num == 6 and tiles_actual < 4:
			hard_gate_pass = false

		if cap_overflow > 0:
			cap_overflow_days.append(day_num)

		print("%-5d %-8d %-8d %-8.0f %-8.0f %-10.0f %-10d %-8d" % [
			day_num, gift, int(income), spend, carryover, cap_overflow, tiles_wanted, tiles_actual
		])

	print("-".repeat(72))
	print("")
	_print_gate_result(hard_gate_pass, cap_overflow_days)

func _print_gate_result(hard_gate_pass: bool, cap_overflow_days: Array) -> void:
	print("=== 2-C Hard Gate Check ===")
	if hard_gate_pass:
		print("[PASS] Day6 tiles_actual >= 4")
	else:
		print("[FAIL] Day6 tiles_actual < 4  ← 需回調內容/贈點序列")

	if cap_overflow_days.is_empty():
		print("[PASS] No cap overflow days (energy is spent properly)")
	else:
		print("[WARN] Cap overflow on days: %s  ← 能量囤積過多，檢查 tiles_per_day_seq" % str(cap_overflow_days))

	print("")
	print("Note: Soft gate (2-C) requires manual playtest. This sim only covers hard gate.")
	print("      Stable-state (post D7) should drop to %d/day income; check sanity read." % (BASE_INCOME_PER_DAY + (AD_EXTRA_ENERGY if use_ad else 0)))
