extends Control

# CollectPanel — 集中採集子面板（Phase 1-E）
# 列出所有已開資源點 + 今日狀態 + 單點採集鈕

@onready var points_container: VBoxContainer = $VBoxContainer/PointsContainer
@onready var back_button: Button = $VBoxContainer/Header/BackButton
@onready var energy_label: Label = $VBoxContainer/Header/EnergyLabel

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	GameState.energy_changed.connect(_on_state_changed)
	GameState.resources_changed.connect(_on_state_changed)
	GameState.day_advanced.connect(_on_state_changed)

func refresh() -> void:
	_on_state_changed()

func _on_state_changed(_v = null) -> void:
	if not is_inside_tree() or not visible:
		return
	_refresh_energy()
	_refresh_points()

func _refresh_energy() -> void:
	energy_label.text = "Energy: %d/%d" % [GameState.get_energy(), Config.get_energy_cap()]

func _refresh_points() -> void:
	for child in points_container.get_children():
		child.queue_free()

	var points = ResourcePoint.get_collectable_points()
	if points.is_empty():
		var lbl = Label.new()
		lbl.text = "(No resource points unlocked yet)"
		points_container.add_child(lbl)
		return

	for pt in points:
		var map_id = pt.get("map_id", "")
		var tile_id = pt.get("tile_id", "")
		var today_count = pt.get("today_count", 0)
		var daily_limit = pt.get("daily_limit", 1)
		var cost = pt.get("cost", 1)
		var collect_rewards: Dictionary = pt.get("collect_rewards", {})
		var can_collect = pt.get("can_collect", false)

		var rewards_str = ""
		for r_id in collect_rewards:
			rewards_str += "%s×%d " % [r_id, int(collect_rewards[r_id])]

		var hbox = HBoxContainer.new()

		var lbl = Label.new()
		lbl.text = "[%s / %s]  %d/%d used  Cost:%d  Yield: %s" % [
			map_id, tile_id, today_count, daily_limit, cost, rewards_str.strip_edges()
		]
		hbox.add_child(lbl)

		var collect_btn = Button.new()
		collect_btn.text = "Collect"
		collect_btn.disabled = not can_collect
		collect_btn.pressed.connect(func(): _on_collect_point(map_id, tile_id))
		hbox.add_child(collect_btn)

		points_container.add_child(hbox)

func _on_collect_point(map_id: String, tile_id: String) -> void:
	var outcome = ResourcePoint.collect(map_id, tile_id)
	if outcome.get("ok", false):
		_refresh_energy()
		_refresh_points()

func _on_back_pressed() -> void:
	visible = false
