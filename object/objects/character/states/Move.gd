extends CharacterState

@export var accel_speed = 700

var wall_touch_timer = 0

var last_pos = Vector2()

@onready var timer: Timer = $Timer

func _enter():
	wall_touch_timer = 0
	last_pos = global_position
	timer.start()


func _update(delta):

	
	if intent.move_dir.length_squared() <= 0.01 and timer.is_stopped():
		return "Idle"
	if last_pos.distance_to(global_position) < 0.1:
		wall_touch_timer += 1
	else:
		wall_touch_timer = 0
	
	if wall_touch_timer > 1 or !timer.is_stopped():
		object.sprite.animation = "Idle"
	else:
		object.sprite.animation = "Move"
		
	last_pos = global_position
		
	body.apply_force(accel_speed * intent.move_dir)
