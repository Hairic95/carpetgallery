extends Node2D

class_name LookupDialogue

signal coords_selected(s)

var text_edit: LineEdit
var is_open := false

const ALLOWED_CHARACTERS = "1234567890 -"

func open(placeholder: String):
	text_edit = preload("res://ui/room browser/lookup_dialogue_text_edit.tscn").instantiate()
	add_child(text_edit)
	text_edit.clear()
	text_edit.placeholder_text = placeholder
	is_open = true
	text_edit.grab_focus.call_deferred()
	text_edit.grab_click_focus.call_deferred()
	text_edit.text_submitted.connect(_on_text_edit_text_submitted)
	show()
	pass

func close():
	hide()
	is_open = false
	text_edit.queue_free()
	pass

func _process(delta: float) -> void:
	position.y = Math.splerp(position.y, get_parent().offset.y + (300 if !is_open else 60), delta, 2.0)
	position.x = get_parent().offset.x

	if is_open:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_down"):
			coords_selected.emit(null)
			close()
			return

		if text_edit.is_inside_tree():
	
			text_edit.grab_focus.call_deferred()
			text_edit.grab_click_focus.call_deferred()
			remove_invalid_characters()
			
			text_edit.modulate = Color.WHITE if is_valid_coordinate(text_edit.text) or text_edit.text.strip_edges() == "" else Color.RED
			

func remove_invalid_characters():
	var cursor_position = text_edit.caret_column
	for character in text_edit.text:
		if not (character in ALLOWED_CHARACTERS):
			text_edit.text = text_edit.text.replace(character, "")
	text_edit.caret_column = cursor_position

func is_valid_coordinate(text: String):
	var coords = try_get_coords(text)
	if coords is Vector3i:
		return true
	return false

func try_get_coords(text: String):
	for character in text:
		if not (character in ALLOWED_CHARACTERS):
			return null
	var coords = text.strip_edges().split(" ", false)
	if coords.size() != 2: # TODO: update for 3d
		return null
	if coords[0].is_valid_int() and coords[1].is_valid_int():
		return Vector3i(coords[0].to_int(), coords[1].to_int(), 0) # TODO: update for 3d

func _on_text_edit_text_submitted(new_text: String) -> void:
	var coords = try_get_coords(new_text)
	if text_edit.text == "":
		coords = try_get_coords(text_edit.placeholder_text)
	if coords is Vector3i:
		coords_selected.emit(coords)
		close()
