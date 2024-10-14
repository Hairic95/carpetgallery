extends CanvasLayer

class_name PauseScreenLayer

@export var player: BaseObject2D
@export var camera: GoodCamera
@export var world: InfiniteWorld
#@onready var pause_screen: PauseScreen = %PauseScreen


@onready var animation_player: AnimationPlayer = $AnimationPlayer

var menu_open = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and !world.transitioning:
		if !menu_open:
			menu_open = true
			player.get_component(PlayerControlComponent).busy = true
			
			animation_player.play("Pause")
		else:
			menu_open = false
			player.get_component(PlayerControlComponent).busy = false
			animation_player.play("Unpause")
