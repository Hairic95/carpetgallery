extends BaseComponent

class_name InteractableComponent

@onready var area = $Area2D
@onready var shape = $Area2D/CollisionShape2D

var callables: Array[Callable] = []

func _ready():
	for component in get_components(InteractableComponent):
		if component != self:
			container.remove(component)

func add_method(callable: Callable):
	callables.append(callable)

func be_interacted_with(object: BaseObject2D):
	for callable in callables:
		callable.call(object)
	
func get_interact_texture():
	return preload("res://ui/interact.png")
