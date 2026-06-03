extends Node

# ResourcePoint — 資源點重採邏輯系統（autoload 單例，無狀態）
# 依賴：Content（讀 tile collect_rewards）、Config（重採成本 / 每日上限）、GameState（原子 API）
# 規格書 §11（資源點）；設計方針 §7.4

# ─────────────────────────────────────────
# 重採
# ─────────────────────────────────────────

## 對已開的資源點執行一次重採。
## 回傳 outcome dict：
##   { ok: true,  rewards: {...} }       成功
##   { ok: false, reason: "..." }        失敗（count_exceeded / no_energy / invalid）
func collect(map_id: String, tile_id: String) -> Dictionary:
	# 1. 確認 map 已解鎖、tile 已翻
	if not GameState.is_map_unlocked(map_id):
		return {"ok": false, "reason": "map_not_unlocked"}
	if not GameState.is_tile_revealed(map_id, tile_id):
		return {"ok": false, "reason": "tile_not_revealed"}

	# 2. 確認 tile 是 resource_point 類型
	var tile_def = _get_tile(map_id, tile_id)
	if tile_def.is_empty() or tile_def.get("type", "") != "resource_point":
		return {"ok": false, "reason": "not_resource_point"}

	# 3. 今日次數檢查
	var today_count = GameState.get_point_collect_count(map_id, tile_id)
	var daily_limit = Config.get_recollect_daily_limit()
	if today_count >= daily_limit:
		return {"ok": false, "reason": "count_exceeded"}

	# 4. 能量檢查 & 扣
	var cost = Config.get_recollect_cost()
	if not GameState.spend_energy(cost):
		return {"ok": false, "reason": "no_energy"}

	# 5. 發 collect_rewards
	var collect_rewards: Dictionary = tile_def.get("collect_rewards", {})
	GameState.apply_rewards(collect_rewards)

	# 6. 標記採集
	GameState.mark_point_collected(map_id, tile_id)

	return {"ok": true, "rewards": collect_rewards.duplicate()}

# ─────────────────────────────────────────
# 集中採集頁資料
# ─────────────────────────────────────────

## 掃描所有已解鎖地圖上已翻開的資源點，回傳採集資訊陣列。
## 每筆：{ map_id, tile_id, today_count, daily_limit, cost, collect_rewards, can_collect }
func get_collectable_points() -> Array:
	var result: Array = []
	var daily_limit = Config.get_recollect_daily_limit()
	var cost = Config.get_recollect_cost()

	for m_id in GameState.unlocked_maps:
		var map_data = Content.get_map(m_id)
		if map_data.is_empty():
			continue
		var tiles_data: Array = map_data.get("tiles", [])
		for tile in tiles_data:
			var t_id = tile.get("id", "")
			if tile.get("type", "") != "resource_point":
				continue
			if not GameState.is_tile_revealed(m_id, t_id):
				continue

			var today_count = GameState.get_point_collect_count(m_id, t_id)
			var can_collect = (today_count < daily_limit) and GameState.can_afford(cost)

			result.append({
				"map_id": m_id,
				"tile_id": t_id,
				"today_count": today_count,
				"daily_limit": daily_limit,
				"cost": cost,
				"collect_rewards": tile.get("collect_rewards", {}).duplicate(),
				"can_collect": can_collect
			})

	return result

# ─────────────────────────────────────────
# 內部輔助
# ─────────────────────────────────────────

func _get_tile(map_id: String, tile_id: String) -> Dictionary:
	var map_data = Content.get_map(map_id)
	if map_data.is_empty():
		return {}
	for tile in map_data.get("tiles", []):
		if tile.get("id") == tile_id:
			return tile
	return {}
