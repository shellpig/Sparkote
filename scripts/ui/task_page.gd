extends Control

@onready var energy_label: Label = $VBoxContainer/Header/EnergyLabel
@onready var warning_label: Label = $VBoxContainer/Header/WarningLabel
@onready var normal_container: VBoxContainer = $VBoxContainer/NormalCandidates
@onready var advanced_container: VBoxContainer = $VBoxContainer/AdvancedCandidates
@onready var super_task_button: Button = $VBoxContainer/Footer/SuperTaskButton
@onready var super_credits_label: Label = $VBoxContainer/Footer/SuperCreditsLabel
@onready var ad_button: Button = $VBoxContainer/Footer/AdButton
@onready var skip_day_button: Button = $VBoxContainer/Footer/SkipDayButton

func _ready() -> void:
	# Add directory configuration in case it is loaded
	GameState.energy_changed.connect(_on_state_changed)
	GameState.today_changed.connect(_on_state_changed)
	GameState.day_advanced.connect(_on_state_changed)
	
	super_task_button.pressed.connect(_on_super_task_pressed)
	ad_button.pressed.connect(_on_ad_pressed)
	skip_day_button.pressed.connect(_on_skip_day_pressed)

	_on_state_changed()

func _on_state_changed(_v = null) -> void:
	if not is_inside_tree():
		return
		
	# Update energy
	var energy = GameState.get_energy()
	var cap = Config.get_energy_cap()
	energy_label.text = "Energy: %d/%d" % [energy, cap]
	
	# Update thresholds warning
	if energy >= Config.get_energy_near_cap_threshold():
		warning_label.text = "Warm warning: Energy is close to cap! Time for exploration!"
		warning_label.visible = true
	elif energy >= Config.get_energy_hint_threshold():
		warning_label.text = "Gentle reminder: You have enough energy to explore."
		warning_label.visible = true
	else:
		warning_label.visible = false

	# Update super task
	super_credits_label.text = "Super task credits: %d" % GameState.super_task_credits
	super_task_button.disabled = GameState.super_task_credits <= 0 or GameState.super_task_completed_today

	# Update ad button
	ad_button.disabled = GameState.daily_ad_extra_claimed

	# Re-populate candidates
	_populate_candidates()

func _populate_candidates() -> void:
	# Clean containers
	for child in normal_container.get_children():
		child.queue_free()
	for child in advanced_container.get_children():
		child.queue_free()

	# Normal candidates
	var norm_candidates = GameState.today_candidates.get("normal", [])
	var norm_selected = GameState.today_selected.get("normal", [])
	for task_id in norm_candidates:
		var task_data = Content.get_task(task_id)
		var text = task_data.get("text", task_id)
		var is_selected = task_id in norm_selected
		var is_completed = GameState.is_task_completed(task_id)
		
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = "[Normal] " + text + (" (Done)" if is_completed else "")
		hbox.add_child(label)
		
		if not is_completed:
			var select_btn = Button.new()
			select_btn.text = "Deselect" if is_selected else "Select"
			select_btn.add_theme_color_override("font_color", Color.YELLOW)
			select_btn.add_theme_color_override("font_hover_color", Color.YELLOW)
			select_btn.add_theme_color_override("font_pressed_color", Color.YELLOW)
			select_btn.add_theme_color_override("font_focus_color", Color.YELLOW)
			select_btn.pressed.connect(func():
				if is_selected:
					GameState.unchoose_task(task_id, false)
				else:
					GameState.choose_task(task_id, false)
			)
			hbox.add_child(select_btn)
			
			if is_selected:
				var complete_btn = Button.new()
				complete_btn.text = "Complete"
				complete_btn.add_theme_color_override("font_color", Color.YELLOW)
				complete_btn.add_theme_color_override("font_hover_color", Color.YELLOW)
				complete_btn.add_theme_color_override("font_pressed_color", Color.YELLOW)
				complete_btn.add_theme_color_override("font_focus_color", Color.YELLOW)
				complete_btn.pressed.connect(func():
					TaskSystem.complete_task(task_id)
				)
				hbox.add_child(complete_btn)

		normal_container.add_child(hbox)

	# Advanced candidates
	var adv_candidates = GameState.today_candidates.get("advanced", [])
	var adv_selected = GameState.today_selected.get("advanced", [])
	var extra_advanced = GameState.today_selected.get("extra_advanced", "")
	
	for task_id in adv_candidates:
		var task_data = Content.get_task(task_id)
		var text = task_data.get("text", task_id)
		var is_selected = (task_id in adv_selected) or (task_id == extra_advanced and not extra_advanced.is_empty())
		var is_extra = task_id == extra_advanced
		var is_completed = GameState.is_task_completed(task_id)
		
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = "[Advanced" + (" ad" if is_extra else "") + "] " + text + (" (Done)" if is_completed else "")
		hbox.add_child(label)
		
		if not is_completed:
			var select_btn = Button.new()
			select_btn.text = "Deselect" if is_selected else "Select"
			select_btn.add_theme_color_override("font_color", Color.YELLOW)
			select_btn.add_theme_color_override("font_hover_color", Color.YELLOW)
			select_btn.add_theme_color_override("font_pressed_color", Color.YELLOW)
			select_btn.add_theme_color_override("font_focus_color", Color.YELLOW)
			select_btn.pressed.connect(func():
				if is_selected:
					# Extra advanced can't be deselected in first version or can be? Let's allow unchoose
					if is_extra:
						GameState.set_extra_advanced("")
					else:
						GameState.unchoose_task(task_id, true)
				else:
					if is_extra:
						GameState.set_extra_advanced(task_id)
					else:
						GameState.choose_task(task_id, true)
			)
			# If daily normal advanced cap reached, disable advanced select button (unless it is extra advanced)
			if not is_selected and not is_extra and adv_selected.size() >= Config.get_daily_slots("advanced"):
				select_btn.disabled = true
			hbox.add_child(select_btn)
			
			if is_selected:
				var complete_btn = Button.new()
				complete_btn.text = "Complete"
				complete_btn.add_theme_color_override("font_color", Color.YELLOW)
				complete_btn.add_theme_color_override("font_hover_color", Color.YELLOW)
				complete_btn.add_theme_color_override("font_pressed_color", Color.YELLOW)
				complete_btn.add_theme_color_override("font_focus_color", Color.YELLOW)
				complete_btn.pressed.connect(func():
					TaskSystem.complete_task(task_id)
				)
				hbox.add_child(complete_btn)

		advanced_container.add_child(hbox)

func _on_super_task_pressed() -> void:
	# Mock text for super task
	TaskSystem.complete_super_task("Did a self-care super task!")

func _on_ad_pressed() -> void:
	TaskSystem.unlock_extra_advanced_via_ad()

func _on_skip_day_pressed() -> void:
	DayCycle.advance_day()
