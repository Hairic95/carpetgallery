extends BaseComponent

class_name HurtboxComponent

@onready var area = $HurtboxArea
@onready var shape = $HurtboxArea/Shape

func _init():
	can_apply_flip = false

func damage(amount):
	var health_component: HealthComponent = get_component(HealthComponent)
	if health_component:
		health_component.damage(amount)
