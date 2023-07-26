extends ObjectState

func _enter():
		get_component(AreaComponent).area.body_entered.connect(on_collision)

func on_collision(collider: CollisionObject2D):
	if collider is BaseObjectBody2D and collider != body:
		queue_state_change("KnockedOver")
		get_component(AreaComponent).area.body_entered.disconnect(on_collision)
		body.velocity += collider.velocity
		object.set_flip(body.x - collider.x)
