extends Node

# HomeSystem — 家園修復 + 插槽式佈置邏輯系統（autoload 單例，無狀態）
# 依賴：Content（讀家園定義）、Config（無直接需求）、GameState（原子 API）
# 規格書 §12；設計方針 §7.4

# ─────────────────────────────────────────
# 修復
# ─────────────────────────────────────────

## 對 repair_id 執行下一等級修復。
## 回 true 表成功；false 表資源不足或已達上限。
func repair(repair_id: String) -> bool:
	var repair_def = _find_repair(repair_id)
	if repair_def.is_empty():
		printerr("HomeSystem.repair: repair_id not found: ", repair_id)
		return false

	var current_level = GameState.get_repair_level(repair_id)
	var max_level = int(repair_def.get("max_level", 0))

	if current_level >= max_level:
		# 已達上限
		return false

	# 找出下一等級的 cost（levels 陣列 index = level - 1）
	var levels: Array = repair_def.get("levels", [])
	var next_level = current_level + 1
	var level_def = _find_level_def(levels, next_level)
	if level_def.is_empty():
		printerr("HomeSystem.repair: level def not found for level ", next_level)
		return false

	var cost: Dictionary = level_def.get("cost", {})

	# 先確認全部資源夠，避免部分扣後失敗
	for resource_id in cost:
		var needed = int(cost[resource_id])
		if GameState.get_resource(resource_id) < needed:
			return false

	# 原子扣資源
	for resource_id in cost:
		var needed = int(cost[resource_id])
		if not GameState.spend_resource(resource_id, needed):
			# 理論上此時不應失敗，但保險起見中止
			printerr("HomeSystem.repair: spend_resource failed mid-repair for ", resource_id)
			return false

	# 推進等級
	GameState.set_repair_level(repair_id, next_level)

	# 記日記
	var visual_state = level_def.get("visual_state", repair_id + "_lv" + str(next_level))
	GameState.log_to_diary(GameState.game_day, "home_changes", repair_id + " -> " + visual_state)

	return true

# ─────────────────────────────────────────
# 插槽佈置
# ─────────────────────────────────────────

## 放置 furniture_id 到 slot_id。
## 回 true 成功；false 表類型不符或家具不存在。
## 不改任何能量 / 探索數值。
func place_furniture(slot_id: String, furniture_id: String) -> bool:
	# 查插槽接受類型（從 Content）
	var slot_def = _find_slot(slot_id)
	if slot_def.is_empty():
		printerr("HomeSystem.place_furniture: slot_id not found: ", slot_id)
		return false

	var accepts: Array = slot_def.get("accepts", [])

	# 查家具類型（從 Content items）
	var item_def = Content.get_item(furniture_id)
	if item_def.is_empty():
		printerr("HomeSystem.place_furniture: furniture_id not found in items: ", furniture_id)
		return false

	var furniture_type = item_def.get("furniture_type", "")
	if furniture_type.is_empty() or not (furniture_type in accepts):
		return false

	# 委託 GameState 純狀態操作
	GameState.place_furniture(slot_id, furniture_id)
	return true

## 收納 slot_id 的家具（回到背包）。
func remove_furniture(slot_id: String) -> void:
	GameState.remove_furniture(slot_id)

# ─────────────────────────────────────────
# 狀態查詢（給 UI 渲染）
# ─────────────────────────────────────────

## 回傳家園完整狀態，給 HomPage 渲染。
## {
##   "repairs": [ { id, level, max_level, visual_state, next_cost, at_max } ],
##   "slots":   [ { id, position, accepts, current_furniture } ]
## }
func get_home_state() -> Dictionary:
	var repairs_out: Array = []
	for repair_def in Content.get_home_repairs():
		var r_id = repair_def.get("id", "")
		var current_level = GameState.get_repair_level(r_id)
		var max_level = int(repair_def.get("max_level", 0))
		var levels: Array = repair_def.get("levels", [])

		var visual_state = ""
		var next_cost: Dictionary = {}
		var at_max = current_level >= max_level

		# 目前等級的 visual_state
		if current_level > 0:
			var cur_def = _find_level_def(levels, current_level)
			visual_state = cur_def.get("visual_state", "")

		# 下一等級 cost（如果還沒滿）
		if not at_max:
			var next_def = _find_level_def(levels, current_level + 1)
			next_cost = next_def.get("cost", {}).duplicate()

		repairs_out.append({
			"id": r_id,
			"level": current_level,
			"max_level": max_level,
			"visual_state": visual_state,
			"next_cost": next_cost,
			"at_max": at_max
		})

	var slots_out: Array = []
	for slot_def in Content.get_home_slots():
		var s_id = slot_def.get("id", "")
		slots_out.append({
			"id": s_id,
			"position": slot_def.get("position", [0.0, 0.0]),
			"accepts": slot_def.get("accepts", []),
			"current_furniture": GameState.slot_furnitures.get(s_id, "")
		})

	return {
		"repairs": repairs_out,
		"slots": slots_out
	}

# ─────────────────────────────────────────
# 內部輔助
# ─────────────────────────────────────────

func _find_repair(repair_id: String) -> Dictionary:
	for rep in Content.get_home_repairs():
		if rep.get("id") == repair_id:
			return rep
	return {}

func _find_slot(slot_id: String) -> Dictionary:
	for slot in Content.get_home_slots():
		if slot.get("id") == slot_id:
			return slot
	return {}

func _find_level_def(levels: Array, level: int) -> Dictionary:
	for lvl in levels:
		if int(lvl.get("level", -1)) == level:
			return lvl
	return {}
