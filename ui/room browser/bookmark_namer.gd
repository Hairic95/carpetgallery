extends Node2D

class_name BookmarkNamer

signal name_selected(s)
var text_edit: LineEdit

var is_open := false

func open(placeholder: String):
	text_edit = preload("res://ui/room browser/bookmark_namer_text_edit.tscn").instantiate()
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
		if text_edit.is_inside_tree():
	
			text_edit.grab_focus.call_deferred()
			text_edit.grab_click_focus.call_deferred()
		
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_down"):
			name_selected.emit(null)

func _on_text_edit_text_submitted(new_text: String) -> void:
	name_selected.emit(new_text)
	close()
