extends CanvasLayer

class_name DialogueWindow

signal finished()

var temporary_game_states = []
var is_waiting_for_input = false
var resource: DialogueResource

var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		if not next_dialogue_line:
			finished.emit()
			hide()
			return
		blinker.hide()
		dialogue_line = next_dialogue_line
		dialogue_line.text = dialogue_line.text
		dialogue_label.dialogue_line = dialogue_line
		dialogue_label.type_out()

		character_label.visible = dialogue_line.character != ""
		character_panel.visible = character_label.visible
		character_label.text = dialogue_line.character
	
		for child in options_list.get_children():
			child.queue_free()
	
		if dialogue_line.responses.size() > 0:
			for response in dialogue_line.responses:
				# Duplicate the template so we can grab the fonts, sizing, etc
				var item: Button = make_response_button()
				item.name = "Response%d" % options_list.get_child_count()
				if not response.is_allowed:
#					item.name = String(item.name) + "Disallowed"
#					item.modulate.a = 0.4
					continue
				item.text = " " + response.text
				item.show()
				options_list.add_child(item)


		options_list.hide()
		await dialogue_label.finished_typing
		
		# Wait for input
		if dialogue_line.responses.size() > 0:
#			await get_tree().create_timer(0.05).timeout
			options_list.show()
			configure_menu()
		elif dialogue_line.time != null:
			var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			blinker.show()
			blinker.texture.current_frame = 0
			is_waiting_for_input = true

	get:
		return dialogue_line

@onready var blinker = %Blinker
@onready var portrait = %Portrait
@onready var dialogue_label = %DialogueLabel
@onready var panel = %Panel
@onready var character_label = %CharacterLabel
@onready var character_panel = $Control/CharacterPanel
@onready var options_list = %OptionsList

func _ready():
	pass

func _input(event):
	pass

func configure_menu():
	for child in options_list.get_children():
		child.pressed.connect(_on_response_gui_input.bind(child))
	options_list.get_child(0).grab_focus()

func make_response_button():
	var button = Button.new()
	button.theme_type_variation = "DialogueButton"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	return button

func start(dialogue: DialogueResource, title: String="0", extra=[]):
	temporary_game_states = extra
	is_waiting_for_input = false
	resource = dialogue
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)
	show()

func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)

func _on_response_gui_input(item: Control) -> void:
	if "Disallowed" in item.name: return
	
	next(dialogue_line.responses[item.get_index()].next_id)

func _unhandled_input(event):
	if !is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return
	if !visible:
		return
	
	if event.is_action_pressed("ui_accept"):
		next(dialogue_line.next_id)
