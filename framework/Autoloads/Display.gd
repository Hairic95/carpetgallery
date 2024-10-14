extends Node

signal window_mode_changed

@onready var viewport_size := Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		)

var focused := true
#
func _ready():
	#RenderingServer.set_default_clear_color(Color("000000"))
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	#focused = true
	pass
	
func toggle_fullscreen():
	var mode = DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if mode == DisplayServer.WINDOW_MODE_WINDOWED else DisplayServer.WINDOW_MODE_WINDOWED)
	window_mode_changed.emit()

func _notification(what):
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			focused = false
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			focused = true
