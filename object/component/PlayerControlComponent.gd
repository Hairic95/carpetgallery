extends BaseComponent

class_name PlayerControlComponent

var intent: CharacterIntentComponent
var dialogue_box: DialogueBoxComponent

var busy := false

func setup():
	intent = get_component(CharacterIntentComponent)
	dialogue_box = get_component(DialogueBoxComponent)

func _physics_process(delta):
	if intent == null:
		return
	if dialogue_box.active:
		intent.reset()
		return

	intent.move_dir = Utils.bools_to_vector2(Input.is_action_pressed("move_left"), Input.is_action_pressed("move_right"), Input.is_action_pressed("move_up"), Input.is_action_pressed("move_down")).normalized()
	intent.aim_global = get_global_mouse_position()

	Debug.dbg("interact", intent.interact)
	
	if busy:
		intent.reset()

func _unhandled_input(event: InputEvent):
	if intent == null:
		return

	if event is InputEventAction:
		if event.is_action("primary"):
			intent.interact = event.pressed

	if busy:
		intent.reset()
