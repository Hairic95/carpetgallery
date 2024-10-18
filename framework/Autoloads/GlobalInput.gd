extends Node

var keyboard = true

func _input(event):
	if event is InputEventJoypadButton or  event is InputEventJoypadMotion:
		keyboard = false
	elif event is InputEventKey:
	#elif event is InputEventMouse or event is InputEventKey:
		keyboard = true
		if event.pressed and event.keycode == KEY_F11:
			Config.fullscreen = !Config.fullscreen

func can_process_input(node: Node) -> bool:
	return node.get_meta("input_enabled", true)

func is_action_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action)

func is_action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action)

func toggle_mouse_mode():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _notification(what):
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			pass
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
			pass
