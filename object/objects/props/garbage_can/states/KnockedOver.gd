extends ObjectState

func _enter():
#	body.shape.disabled = true
	pass

func _update(delta):
	if body.velocity.length_squared() == 0:
		update = false
