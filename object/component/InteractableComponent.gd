extends BaseComponent

class_name InteractableComponent

@onready var area = $Area2D
@onready var shape = $Area2D/CollisionShape2D

func be_interacted_with(object: BaseObject2D):
	pass
	
func get_interact_texture():
	return preload("res://ui/interact.png")
