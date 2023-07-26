extends BaseComponent

class_name CameraComponent

const MOVE_OFFSET_AMOUNT = 4

@export var move_offset = true
@onready var camera: GoodCamera = $GoodCamera

var intent: CharacterIntentComponent

func setup():
	intent = get_component(CharacterIntentComponent)

func _process(delta):
	if move_offset:
		if intent.move_dir:
			position = position.lerp(intent.move_dir * MOVE_OFFSET_AMOUNT, 1 - pow(0.0005, delta))
