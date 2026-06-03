extends Node

var current_map_id: String = ""

func _ready() -> void:
	# If no maps are unlocked, unlock "map_1" as the starting map
	if GameState.unlocked_maps.is_empty():
		unlock_map("map_1")
	
	# Set default current map
	if current_map_id.is_empty() and not GameState.unlocked_maps.is_empty():
		current_map_id = GameState.unlocked_maps[0]

func can_flip(map_id: String, tile_id: String) -> Dictionary:
	# 1. Check if map is unlocked
	if not GameState.is_map_unlocked(map_id):
		return {"ok": false, "reason": "map_locked"}

	# 2. Check if already revealed
	if GameState.is_tile_revealed(map_id, tile_id):
		return {"ok": false, "reason": "already_revealed"}

	# 3. Retrieve map and tile data
	var map_data = Content.get_map(map_id)
	if map_data.is_empty():
		return {"ok": false, "reason": "invalid_map"}

	var tiles_data = map_data.get("tiles", [])
	var target_tile = null
	for tile in tiles_data:
		if tile.get("id") == tile_id:
			target_tile = tile
			break

	if not target_tile:
		return {"ok": false, "reason": "invalid_tile"}

	# 4. Check adjacency (must be adjacent to a revealed tile on this map)
	if not GameState.is_adjacent_to_revealed(map_id, tile_id):
		return {"ok": false, "reason": "too_far"}

	# 5. Check requirements
	var reqs = target_tile.get("requirements", [])
	if not GameState.meets_requirements(reqs):
		var unmet = GameState.unmet_requirements(reqs)
		return {"ok": false, "reason": "blocked", "unmet": unmet}

	# 6. Check energy
	var cost = int(target_tile.get("cost", 0))
	if not GameState.can_afford(cost):
		return {"ok": false, "reason": "no_energy"}

	return {"ok": true}

func flip_tile(map_id: String, tile_id: String) -> Dictionary:
	var check = can_flip(map_id, tile_id)
	if not check.get("ok", false):
		return check

	# Get tile data
	var map_data = Content.get_map(map_id)
	var tiles_data = map_data.get("tiles", [])
	var target_tile = null
	for tile in tiles_data:
		if tile.get("id") == tile_id:
			target_tile = tile
			break

	if not target_tile:
		return {"ok": false, "reason": "invalid_tile"}

	var cost = int(target_tile.get("cost", 0))
	var tile_type = target_tile.get("type", "")

	# Spend energy
	if not GameState.spend_energy(cost):
		return {"ok": false, "reason": "no_energy"}

	# Mark revealed
	GameState.mark_revealed(map_id, tile_id)

	# Log to diary
	GameState.log_to_diary(GameState.game_day, "tiles_revealed", 1)

	var outcome = {
		"ok": true,
		"type": tile_type,
		"rewards_applied": {}
	}

	# Settle based on tile type
	match tile_type:
		"discovery":
			var rewards = target_tile.get("rewards", {})
			GameState.apply_rewards(rewards)
			outcome["rewards_applied"] = rewards
		"resource_point":
			var first_rewards = target_tile.get("first_rewards", {})
			GameState.apply_rewards(first_rewards)
			outcome["rewards_applied"] = first_rewards
		"decor":
			if target_tile.has("reward_id"):
				var reward_id = target_tile.get("reward_id")
				GameState.add_furniture(reward_id)
				outcome["reward_id"] = reward_id
		"exit":
			var target_maps = target_tile.get("target_maps", [])
			for t_map_id in target_maps:
				unlock_map(t_map_id)
			outcome["unlocked_maps"] = target_maps
		"event":
			var event_id = target_tile.get("event_id", "")
			outcome["event_id"] = event_id
			EventSystem.play(event_id)

	return outcome

func unlock_map(map_id: String) -> void:
	if GameState.is_map_unlocked(map_id):
		return
	GameState.unlock_map(map_id)
	var map_data = Content.get_map(map_id)
	if not map_data.is_empty():
		var start_tile = map_data.get("start_tile", "")
		if not start_tile.is_empty():
			GameState.mark_revealed(map_id, start_tile)

func set_current_map(map_id: String) -> void:
	if GameState.is_map_unlocked(map_id):
		current_map_id = map_id

func get_current_map() -> String:
	return current_map_id

func get_map_view(map_id: String) -> Dictionary:
	var map_data = Content.get_map(map_id)
	if map_data.is_empty():
		return {}

	var view_tiles = []
	var tiles_data = map_data.get("tiles", [])

	for tile in tiles_data:
		var tile_id = tile.get("id", "")
		var is_revealed = GameState.is_tile_revealed(map_id, tile_id)
		var is_adjacent = GameState.is_adjacent_to_revealed(map_id, tile_id)

		# Only visible (revealed or adjacent to revealed) tiles are returned
		if is_revealed or is_adjacent:
			var reqs = tile.get("requirements", [])
			var unmet = GameState.unmet_requirements(reqs)
			var check = can_flip(map_id, tile_id)

			var t_view = {
				"id": tile_id,
				"position": tile.get("position", [0, 0]),
				"type": tile.get("type", ""),
				"cost": int(tile.get("cost", 0)),
				"revealed": is_revealed,
				"selectable": check.get("ok", false),
				"blocked": not unmet.is_empty(),
				"reason": check.get("reason", ""),
				"requirements": reqs,
				"unmet_requirements": unmet,
				"neighbors": tile.get("neighbors", []),
				"text": tile.get("text", ""),
				"rewards": tile.get("rewards", {}),
				"first_rewards": tile.get("first_rewards", {}),
				"collect_rewards": tile.get("collect_rewards", {}),
				"event_id": tile.get("event_id", ""),
				"target_maps": tile.get("target_maps", []),
				"reward_id": tile.get("reward_id", "")
			}
			view_tiles.append(t_view)

	return {
		"id": map_id,
		"name": map_data.get("name", ""),
		"tiles": view_tiles,
		"unlocked_maps": GameState.unlocked_maps.duplicate()
	}
