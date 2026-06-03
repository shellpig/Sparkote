extends Control

@onready var narration_label: Label = $VBoxContainer/NarrationLabel
@onready var continue_btn: Button = $VBoxContainer/ContinueButton
@onready var choices_container: VBoxContainer = $VBoxContainer/ChoicesContainer

var event_id: String = ""
var pages: Array = []
var choices: Array = []
var current_page_idx: int = 0
var is_replay: bool = false
var choice_idx: int = -1

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)

func initialize(event_id: String, event_data: Dictionary, is_replay_mode: bool, selected_choice: int) -> void:
	self.event_id = event_id
	self.pages = event_data.get("pages", [])
	self.choices = event_data.get("choices", [])
	self.is_replay = is_replay_mode
	self.choice_idx = selected_choice
	self.current_page_idx = 0
	
	_show_page()

func _on_continue_pressed() -> void:
	current_page_idx += 1
	_show_page()

func _show_page() -> void:
	if current_page_idx < pages.size():
		narration_label.text = pages[current_page_idx]
		narration_label.visible = true
		continue_btn.visible = true
		choices_container.visible = false
	else:
		narration_label.visible = false
		continue_btn.visible = false
		choices_container.visible = true
		_populate_choices()

func _populate_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()
		
	if choices.is_empty():
		var btn = Button.new()
		if is_replay:
			btn.text = "Close Replay"
			btn.pressed.connect(func(): UINavigation.close_overlay())
		else:
			btn.text = "Complete Event"
			btn.pressed.connect(func(): _on_choice_selected(-1))
		choices_container.add_child(btn)
		return
		
	for i in range(choices.size()):
		var choice = choices[i]
		var btn = Button.new()
		btn.text = choice.get("text", "")
		
		# Make code references clean by creating a copy of the index i
		var index = i
		if is_replay:
			btn.disabled = true
			if index == choice_idx:
				btn.text += " [Chosen]"
				btn.modulate = Color(0.6, 0.9, 0.6) # Highlight choice
		else:
			btn.pressed.connect(func(): _on_choice_selected(index))
			
		choices_container.add_child(btn)
		
	if is_replay:
		var close_btn = Button.new()
		close_btn.text = "Close Replay"
		close_btn.pressed.connect(func(): UINavigation.close_overlay())
		choices_container.add_child(close_btn)

func _on_choice_selected(idx: int) -> void:
	EventSystem.resolve(event_id, idx)
