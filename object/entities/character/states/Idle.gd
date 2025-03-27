extends CharacterState

func _update(delta):
	if intent.move_dir:
		return "Move"
