extends Control

# HomePag — 佔位家園頁（Phase 1-E）
# 顯示修復項 + 插槽 + 資源；含集中採集子面板切換

@onready var resources_label: Label = $VBoxContainer/ResourcesLabel
@onready var repairs_container: VBoxContainer = $VBoxContainer/RepairsContainer
@onready var slots_container: VBoxContainer = $VBoxContainer/SlotsContainer
@onready var collect_button: Button = $VBoxContainer/Footer/CollectButton
@onready var collect_panel: Control = $CollectPanel

func _ready() -> void:
	GameState.home_changed.connect(_on_state_changed)
	GameState.resources_changed.connect(_on_state_changed)
	GameState.day_advanced.connect(_on_state_changed)
	collect_button.pressed.connect(_on_collect_pressed)
	collect_panel.visible = false
	_on_state_changed()

func _on_state_changed(_v = null) -> void:
	if not is_inside_tree():
		return
	_refresh_resources()
	_refresh_repairs()
	_refresh_slots()

func _refresh_resources() -> void:
	var wood = GameState.get_resource("wood")
	var stone = GameState.get_resource("stone")
	var spore = GameState.get_resource("magic_spore")
	resources_label.text = "Resources — Wood: %d  Stone: %d  Spore: %d" % [wood, stone, spore]

func _refresh_repairs() -> void:
	for child in repairs_container.get_children():
		child.queue_free()

	var state = HomeSystem.get_home_state()
	for rep in state.get("repairs", []):
		var r_id = rep.get("id", "")
		var level = rep.get("level", 0)
		var max_level = rep.get("max_level", 0)
		var at_max = rep.get("at_max", false)
		var next_cost: Dictionary = rep.get("next_cost", {})
		var visual = rep.get("visual_state", "")

		var hbox = HBoxContainer.new()

		var lbl = Label.new()
		var cost_str = ""
		if not at_max:
			var parts = []
			for res_id in next_cost:
				parts.append("%s:%d" % [res_id, int(next_cost[res_id])])
			cost_str = " [Cost: %s]" % ", ".join(parts)
		var visual_str = (" (%s)" % visual) if not visual.is_empty() else ""
		lbl.text = "[%s] Lv.%d/%d%s%s" % [r_id, level, max_level, visual_str, cost_str]
		hbox.add_child(lbl)

		if not at_max:
			var btn = Button.new()
			btn.text = "Repair"
			btn.pressed.connect(func(): _on_repair_pressed(r_id))
			# Disable if not enough resources
			btn.disabled = not _can_afford_repair(next_cost)
			hbox.add_child(btn)
		else:
			var done_lbl = Label.new()
			done_lbl.text = " ✓ Max"
			hbox.add_child(done_lbl)

		repairs_container.add_child(hbox)

func _refresh_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	var state = HomeSystem.get_home_state()
	for slot in state.get("slots", []):
		var s_id = slot.get("id", "")
		var accepts: Array = slot.get("accepts", [])
		var current = slot.get("current_furniture", "")

		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = "[%s] (accepts: %s) → %s" % [s_id, ", ".join(accepts),
			current if not current.is_empty() else "empty"]
		hbox.add_child(lbl)

		if not current.is_empty():
			var remove_btn = Button.new()
			remove_btn.text = "Remove"
			remove_btn.pressed.connect(func(): HomeSystem.remove_furniture(s_id))
			hbox.add_child(remove_btn)

		slots_container.add_child(hbox)

func _can_afford_repair(cost: Dictionary) -> bool:
	for res_id in cost:
		if GameState.get_resource(res_id) < int(cost[res_id]):
			return false
	return true

func _on_repair_pressed(repair_id: String) -> void:
	var ok = HomeSystem.repair(repair_id)
	if not ok:
		# 簡單回饋：顯示一下資源不足（佔位）
		pass

func _on_collect_pressed() -> void:
	collect_panel.visible = true
	collect_panel.refresh()
