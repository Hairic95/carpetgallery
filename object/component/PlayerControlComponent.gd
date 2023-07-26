extends BaseComponent

class_name PlayerControlComponent

var intent: CharacterIntentComponent

func setup():
	intent = get_component(CharacterIntentComponent)

func _physics_process(delta):
	if intent == null:
		return
	intent.move_dir = GlobalInput.move_dir.normalized()
	intent.aim_global = get_global_mouse_position()
