extends Area2D
class_name PushBox

@export var object : NetworkBody
var pushboxes = []

func _physics_process(delta):
	if object:
		var force_direction = Vector2.ZERO
		
		for area in pushboxes:
			force_direction += (global_position - area.global_position).normalized()
		
		force_direction.normalized()
		
		object.velocity = force_direction * 20
		object.move_and_slide() 

func _on_area_entered(area):
	if area is PushBox:
		pushboxes.append(area)


func _on_area_exited(area):
	if pushboxes.has(area):
		pushboxes.erase(area)
