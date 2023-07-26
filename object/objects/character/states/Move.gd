extends CharacterState

@export var accel_speed = 700

func _update(delta):
	if intent.move_dir.length_squared() <= 0.01:
		return "Idle"
	body.apply_force(accel_speed * intent.move_dir)
