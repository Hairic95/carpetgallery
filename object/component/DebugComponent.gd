extends BaseComponent

class_name DebugComponent

func _process(delta: float) -> void:
	if !Debug.enabled:
		return
		
	#Debug.dbg("room_coords", object.room.room_coords)
