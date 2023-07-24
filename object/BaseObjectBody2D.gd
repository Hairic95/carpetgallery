@tool

extends KinematicObject2D

class_name BaseObjectBody2D

@export var host: BaseObject2D

func _ready():
	if host == null:
		host = get_parent()
