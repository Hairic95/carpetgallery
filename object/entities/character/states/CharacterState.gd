extends ObjectState

class_name CharacterState

@export var update_flip = true

var intent: CharacterIntentComponent

func init():
	intent = get_component(CharacterIntentComponent)

func _update_shared(delta):
	super._update_shared(delta)
	if update_flip:
		object.set_flip(sign(body.velocity.x))
