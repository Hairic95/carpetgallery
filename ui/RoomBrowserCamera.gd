@tool

extends Camera3D

class_name RoomBrowserCamera

@export var target: Node3D

var t := 0.0

func _process(delta: float) -> void:
	t += delta * 1.0
	position = Math.splerp_vec3(position, target.position + Vector3(sin(t) * 0.25, cos(t / 1.26), cos(t / 1.5)) * 0.025, delta, 1.0)
	basis = Math.splerp_slerp(basis, target.basis, delta, 1.0)

func reset_smoothing():
	position = target.position
