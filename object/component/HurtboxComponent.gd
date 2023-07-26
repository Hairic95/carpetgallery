extends AreaComponent

class_name HurtboxComponent

func _init():
	apply_flip = false
	follow_body_rotation = false

func damage(amount):
	var health_component: HealthComponent = get_component(HealthComponent)
	if health_component:
		health_component.damage(amount)
