extends BaseComponent

class_name CameraComponent

const MOVE_OFFSET_AMOUNT = 4

@export var move_offset = true
@export var follow = true
@onready var camera: GoodCamera = $GoodCamera

var intent: CharacterIntentComponent

func setup():
	intent = get_component(CharacterIntentComponent)

func _process(delta):
	if move_offset:
		if intent.move_dir:
			position = Math.splerp_vec(position, intent.move_dir * MOVE_OFFSET_AMOUNT, delta, 10.01)

func on_entered_map() -> void:
		camera.reset_smoothing.call_deferred()
		#camera.set_bounds(object.map.camera_bounds_start, object.map.camera_bounds_end)
