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
	map_title.text = "Map: %s" % view.get("name", cur_map)
	
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
	detail_label.text = "Click a node to view info."
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
		btn.custom_minimum_size = Vector2(140, 50)
		
		# Set text and theme color
		if is_revealed:
			btn.text = "%s\n[%s]" % [tile_id, type.capitalize()]
			btn.modulate = Color(0.6, 0.9, 0.6) # Greenish for revealed
		elif is_blocked:
			btn.text = "%s\n🔒 (Cost: %d)" % [tile_id, cost]
			btn.modulate = Color(0.9, 0.5, 0.5) # Reddish for blocked
		else:
			btn.text = "%s\n? (Cost: %d)" % [tile_id, cost]
			btn.modulate = Color(0.5, 0.7, 0.9) # Bluish/yellowish for selectable
			
		# Position button centered on grid screen coordinate
		var center_pos = _get_screen_position(tile.get("position", [0, 0]))
		btn.position = center_pos - Vector2(70, 25)
		
		# Bind press
		btn.pressed.connect(func(): _on_tile_pressed(cur_map, tile))
		
		map_board.add_child(btn)

func _on_tile_pressed(map_id: String, tile: Dictionary) -> void:
	var tile_id = tile.get("id")
	selected_tile_id = tile_id
	var is_revealed = tile.get("revealed", false)
	var is_selectable = tile.get("selectable", false)
	var is_blocked = tile.get("blocked", false)
	var cost = tile.get("cost", 0)
	var type = tile.get("type", "")
	
	var info = "Tile: %s\nType: %s (Cost: %d)\nStatus: " % [tile_id, type.capitalize(), cost]
	if is_revealed:
		info += "Revealed"
		match type:
			"discovery":
				info += "\nFound: %s" % JSON.stringify(tile.get("rewards", {}))
			"resource_point":
				info += "\nResource Point (First: %s, Repeat: %s)" % [
					JSON.stringify(tile.get("first_rewards", {})),
					JSON.stringify(tile.get("collect_rewards", {}))
				]
			"decor":
				info += "\nGrants furniture: %s" % tile.get("reward_id", "")
			"exit":
				info += "\nExit to map(s): %s" % JSON.stringify(tile.get("target_maps", []))
			"event":
				info += "\nCompleted Event: %s" % tile.get("event_id", "")
	elif is_blocked:
		info += "Blocked by unmet requirements: "
		var unmet = tile.get("unmet_requirements", [])
		var unmet_desc = []
		for u in unmet:
			unmet_desc.append("%s:%s" % [u.get("type"), u.get("id")])
		info += ", ".join(unmet_desc)
	else:
		info += "Selectable (Click below to flip)"
		
	detail_label.text = info
	
	# If selectable, show a button or prompt to flip
	if is_selectable and not is_revealed:
		# Add a temporary quick-flip action inside detail label
		detail_label.text += "\n[Press again or click button below to FLIP]"
		var outcome = Exploration.flip_tile(map_id, tile_id)
		if outcome.get("ok", false):
			selected_tile_id = ""
			_on_state_changed()
			detail_label.text = "Flipped %s successfully! Outcome: %s" % [tile_id, outcome.get("type")]
		else:
			detail_label.text += "\nFlip failed: %s" % outcome.get("reason", "")

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
