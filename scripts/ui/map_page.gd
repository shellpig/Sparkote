extends Control

@onready var map_title: Label = $VBoxContainer/Header/MapTitle
@onready var map_switcher: OptionButton = $VBoxContainer/Header/MapSwitcher
@onready var map_board: Control = $VBoxContainer/ScrollContainer/MapBoard
@onready var detail_label: Label = $VBoxContainer/DetailPanel/DetailLabel

var selected_tile_id: String = ""

func _ready() -> void:
	GameState.tile_revealed.connect(_on_state_changed)
	GameState.map_unlocked.connect(_on_state_changed)
	GameState.energy_changed.connect(_on_state_changed)
	GameState.resources_changed.connect(_on_state_changed)
	
	map_switcher.item_selected.connect(_on_map_selected)
	map_board.draw.connect(_on_map_board_draw)
	
	# Create Energy Label dynamically
	var energy_label = Label.new()
	energy_label.name = "EnergyLabel"
	$VBoxContainer/Header.add_child(energy_label)
	
	UINavigation.overlay_closed.connect(_on_overlay_closed)
	
	_on_state_changed()

func _on_state_changed(_v = null, _v2 = null) -> void:
	if not is_inside_tree():
		return
		
	var cur_map = Exploration.get_current_map()
	if cur_map.is_empty():
		return
		
	var view = Exploration.get_map_view(cur_map)
	if view.is_empty():
		return
		
	# Update Title
	map_title.text = "地圖: %s" % view.get("name", cur_map)
	
	# Update energy display
	var energy_lbl = $VBoxContainer/Header.get_node_or_null("EnergyLabel")
	if energy_lbl:
		var energy = GameState.get_energy()
		var cap = Config.get_energy_cap()
		energy_lbl.text = "能量: %d/%d" % [energy, cap]
	
	# Update map switcher dropdown
	map_switcher.clear()
	var unlocked_maps = view.get("unlocked_maps", [])
	var select_idx = -1
	for idx in range(unlocked_maps.size()):
		var m_id = unlocked_maps[idx]
		var m_data = Content.get_map(m_id)
		var m_name = m_data.get("name", m_id)
		map_switcher.add_item(m_name)
		map_switcher.set_item_metadata(idx, m_id)
		if m_id == cur_map:
			select_idx = idx
	
	if select_idx != -1:
		map_switcher.select(select_idx)
		
	# Rebuild nodes
	_populate_nodes(view)
	
	# Redraw lines
	map_board.queue_redraw()

func _on_map_selected(idx: int) -> void:
	var m_id = map_switcher.get_item_metadata(idx)
	Exploration.set_current_map(m_id)
	selected_tile_id = ""
	detail_label.text = "請點擊節點以查看資訊。"
	_on_state_changed()

func _get_screen_position(grid_pos: Array) -> Vector2:
	var scale_factor = Vector2(180, 140)
	var offset = Vector2(100, 100)
	return Vector2(grid_pos[0], grid_pos[1]) * scale_factor + offset

func _populate_nodes(view: Dictionary) -> void:
	# Clear old nodes
	for child in map_board.get_children():
		child.queue_free()
		
	var tiles = view.get("tiles", [])
	var cur_map = view.get("id")
	
	for tile in tiles:
		var tile_id = tile.get("id")
		var is_revealed = tile.get("revealed", false)
		var is_selectable = tile.get("selectable", false)
		var is_blocked = tile.get("blocked", false)
		var cost = tile.get("cost", 0)
		var type = tile.get("type", "")
		
		# Define button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(140, 70)
		
		# Set text and theme color
		if is_revealed:
			var display_text = ""
			match type:
				"start":
					display_text = "起點"
				"exit":
					display_text = "出口"
				"resource_point":
					display_text = "資源點"
				"decor":
					var item_data = Content.get_item(tile.get("reward_id", ""))
					display_text = item_data.get("display_name", "裝飾")
				"event":
					var evt_data = Content.get_event(tile.get("event_id", ""))
					display_text = evt_data.get("title", "事件")
				"discovery":
					display_text = "已探索"
				_:
					display_text = type.capitalize()
			
			var tile_name = tile.get("name", "")
			if tile_name.is_empty():
				tile_name = display_text
				
			btn.text = "%s\n%s" % [tile_id, tile_name]
			btn.modulate = Color(0.6, 0.9, 0.6) # Greenish for revealed
		elif is_blocked:
			btn.text = "%s\n被迷霧壟罩\n🔒 (消耗: %d)" % [tile_id, cost]
			btn.modulate = Color(0.9, 0.5, 0.5) # Reddish for blocked
		else:
			btn.text = "%s\n被迷霧壟罩\n? (消耗: %d)" % [tile_id, cost]
			btn.modulate = Color(0.5, 0.7, 0.9) # Bluish/yellowish for selectable
			
		# Position button centered on grid screen coordinate
		var center_pos = _get_screen_position(tile.get("position", [0, 0]))
		btn.position = center_pos - Vector2(70, 35)
		
		# Bind press
		btn.pressed.connect(func(): _on_tile_pressed(cur_map, tile))
		
		map_board.add_child(btn)

func _on_tile_pressed(map_id: String, tile: Dictionary) -> void:
	var tile_id = tile.get("id")
	var is_double_click = (selected_tile_id == tile_id)
	selected_tile_id = tile_id
	var is_revealed = tile.get("revealed", false)
	var is_selectable = tile.get("selectable", false)
	var is_blocked = tile.get("blocked", false)
	var cost = tile.get("cost", 0)
	var type = tile.get("type", "")
	
	var ch_type = ""
	match type:
		"start": ch_type = "起點"
		"exit": ch_type = "出口"
		"resource_point": ch_type = "資源點"
		"decor": ch_type = "裝飾"
		"event": ch_type = "事件"
		"discovery": ch_type = "探索"
		_: ch_type = type.capitalize()

	var tile_name = tile.get("name", "")
	if tile_name.is_empty():
		tile_name = ch_type
	var label_title = "%s / %s" % [tile_id, tile_name]
	
	var info = "格子: %s\n類型: %s (消耗: %d)\n狀態: " % [label_title, ch_type, cost]
	if is_revealed:
		info += "已翻開"
		match type:
			"discovery":
				info += "\n獲得發現: %s" % _format_rewards(tile.get("rewards", {}))
				var txt = tile.get("text", "")
				if not txt.is_empty():
					info += "\n描述: \"%s\"" % txt
			"resource_point":
				info += "\n資源點 (首採: %s, 重採: %s)" % [
					_format_rewards(tile.get("first_rewards", {})),
					_format_rewards(tile.get("collect_rewards", {}))
				]
			"decor":
				var item_data = Content.get_item(tile.get("reward_id", ""))
				info += "\n獲得家具: %s" % item_data.get("display_name", tile.get("reward_id", ""))
			"exit":
				var target_maps = tile.get("target_maps", [])
				var names = []
				for t_map_id in target_maps:
					var m_data = Content.get_map(t_map_id)
					names.append(m_data.get("name", t_map_id))
				info += "\n通往地圖: %s" % ", ".join(names)
			"event":
				var evt_data = Content.get_event(tile.get("event_id", ""))
				info += "\n觸發事件: 「%s」" % evt_data.get("title", tile.get("event_id", ""))
	elif is_blocked:
		info += "未解鎖 (被未滿足的條件阻擋)"
		var unmet = tile.get("unmet_requirements", [])
		var unmet_desc = []
		for u in unmet:
			unmet_desc.append(_format_requirement(u))
		info += "\n需要滿足：\n- " + "\n- ".join(unmet_desc)
	else:
		info += "可開拓 (再次點擊以開拓)"
		
	detail_label.text = info
	
	# If selectable, show a button or prompt to flip
	if is_selectable and not is_revealed:
		detail_label.text += "\n[再次點擊以進行開拓]"
		var outcome = Exploration.flip_tile(map_id, tile_id)
		if outcome.get("ok", false):
			selected_tile_id = ""
			_on_state_changed()
			
			var ch_outcome_type = ""
			match outcome.get("type"):
				"start": ch_outcome_type = "起點"
				"exit": ch_outcome_type = "出口"
				"resource_point": ch_outcome_type = "資源點"
				"decor": ch_outcome_type = "裝飾"
				"event": ch_outcome_type = "事件"
				"discovery": ch_outcome_type = "探索"
				_: ch_outcome_type = str(outcome.get("type"))
			
			detail_label.text = "成功開拓 %s！結果：%s" % [label_title, ch_outcome_type]
		else:
			detail_label.text += "\n開拓失敗：%s" % outcome.get("reason", "")
	elif is_revealed and type == "exit":
		detail_label.text += "\n[再次點擊以穿梭至此地圖]"
		if is_double_click:
			var target_maps = tile.get("target_maps", [])
			if not target_maps.is_empty():
				var target = target_maps[0]
				Exploration.set_current_map(target)
				selected_tile_id = ""
				detail_label.text = "請點擊節點以查看資訊。"
				_on_state_changed()

func _on_overlay_closed() -> void:
	if not Exploration.pending_exit_map_id.is_empty():
		var target = Exploration.pending_exit_map_id
		Exploration.pending_exit_map_id = ""
		Exploration.set_current_map(target)
		selected_tile_id = ""
		detail_label.text = "請點擊節點以查看資訊。"
		_on_state_changed()

func _format_rewards(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return "無"
	var parts = []
	for item_id in rewards:
		var metadata = Content.get_item(item_id)
		var display_name = metadata.get("display_name", item_id)
		parts.append("%s x%d" % [display_name, int(rewards[item_id])])
	return ", ".join(parts)

func _format_requirement(req: Dictionary) -> String:
	var type = req.get("type", "")
	var req_id = req.get("id", "")
	match type:
		"item", "resource":
			var count = int(req.get("count", 1))
			var item_data = Content.get_item(req_id)
			var item_name = item_data.get("display_name", req_id)
			return "持有 %s x%d" % [item_name, count]
		"event":
			var evt_data = Content.get_event(req_id)
			var evt_title = evt_data.get("title", req_id)
			return "完成事件「%s」" % [evt_title]
		"map":
			var map_data = Content.get_map(req_id)
			var map_name = map_data.get("name", req_id)
			return "解鎖地圖「%s」" % [map_name]
		"repair":
			var level = int(req.get("level", 1))
			var repair_name = req_id
			for r in Content.get_home_repairs():
				if r.get("id") == req_id:
					match req_id:
						"repair_engine": repair_name = "修復引擎"
						"repair_window": repair_name = "修復車窗"
						"repair_mailbox": repair_name = "修復郵箱"
			return "%s 達到等級 %d" % [repair_name, level]
		_:
			return "%s:%s" % [type, req_id]

func _on_map_board_draw() -> void:
	var cur_map = Exploration.get_current_map()
	if cur_map.is_empty():
		return
		
	var view = Exploration.get_map_view(cur_map)
	if view.is_empty():
		return
		
	var tiles = view.get("tiles", [])
	
	# Draw connection lines between visible tiles
	for tile in tiles:
		var tile_id = tile.get("id")
		var tile_pos = _get_screen_position(tile.get("position", [0, 0]))
		var neighbors = tile.get("neighbors", [])
		
		for neighbor_id in neighbors:
			var neighbor_tile = null
			for t in tiles:
				if t.get("id") == neighbor_id:
					neighbor_tile = t
					break
					
			if neighbor_tile:
				var neighbor_pos = _get_screen_position(neighbor_tile.get("position", [0, 0]))
				# Draw line only once per pair
				if tile_id < neighbor_id:
					map_board.draw_line(tile_pos, neighbor_pos, Color(0.45, 0.45, 0.5, 0.8), 4.0)
