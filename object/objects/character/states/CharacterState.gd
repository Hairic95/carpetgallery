extends ObjectState

class_name CharacterState

@export var aim = true

var intent: CharacterIntentComponent

func init():
	intent = object.get_component(CharacterIntentComponent)
