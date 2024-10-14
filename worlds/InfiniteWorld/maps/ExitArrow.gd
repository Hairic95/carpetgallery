extends Node2D

@onready var startup_timer: Timer = $StartupTimer

@export var flash_offset = 0

var i = 0

func _physics_process(delta: float) -> void:
	visible = (startup_timer.is_stopped() and global_position.distance_squared_to(GlobalState.player.global_position) < 1000)

	i += 1
	
