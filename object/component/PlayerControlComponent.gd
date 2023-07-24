extends BaseComponent

var intent: CharacterIntentComponent

func setup():
	intent = get_component(CharacterIntentComponent)

func _physics_process(delta):
	if intent == null:
		return
	intent.move_dir = GlobalInput.move_dir
