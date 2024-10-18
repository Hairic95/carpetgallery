extends BaseComponent

class_name FootstepComponent

signal footstep_taken

@export var sprite: AnimatedSprite2D

@export var footstep_node: AudioStreamPlayer2D

func _ready():
	sprite.frame_changed.connect(_on_frame_changed)
	
func _on_frame_changed():
	if sprite.animation == "Move" and sprite.frame == 1:
		footstep_node.stream = object.room.footstep_sound

		#footstep_node.stop()
		footstep_node.play.call_deferred()
		footstep_taken.emit()
