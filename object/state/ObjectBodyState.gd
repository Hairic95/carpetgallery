extends StateInterface

class_name ObjectBodyState

var object: BaseObject2D:
	get:
		return body.host

var body: BaseObjectBody2D:
	get:
		return host

#@export var apply_gravity = false
#@export var apply_friction = false
