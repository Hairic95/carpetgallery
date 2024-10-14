extends ObjectState

func _enter():
	object.components.remove(get_component(DialogueComponent))
	pass

func _update(delta):
	if body.velocity.length_squared() <= 0.01:
		update = false
