extends BaseComponent

class_name FootstepComponent

signal footstep_taken

@export var footstep_node: AudioStreamPlayer2D

func _on_frame_changed():
	if object is NetworkPlatformerPlayer:
		if object.current_state == "Move":
			footstep_node.stream = object.room.footstep_sound
			#footstep_node.stop()
			footstep_node.play.call_deferred()
			footstep_taken.emit()
