extends BaseComponent

class_name CharacterIntentComponent

var move_dir = Vector2()
var aim_location = Vector2()
var aim_dir: Vector2:
	get:
		return to_local(aim_location).normalized()
