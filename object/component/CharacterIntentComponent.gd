extends BaseComponent

class_name CharacterIntentComponent

var move_dir = Vector2()
var aim_global = Vector2()
var aim_local: Vector2:
	get:
		return to_local(aim_global).normalized()

var aim_dir: Vector2:
	get:
		return aim_local.normalized()

var interact = false

func reset():
	interact = false
	move_dir = Vector2()
	aim_global = Vector2()
