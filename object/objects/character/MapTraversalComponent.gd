extends BaseComponent

class_name MapTraversalComponent

signal fast_travel_initiated(coords: Vector3i)

@onready var area = $Area2D


func _ready():
	area.area_entered.connect(on_area_entered)

func on_area_entered(area):
	if !(area is MapExit):
		return
	
	object.set_process(false)
	GlobalState.world.map_transition.call_deferred(area.map)
	await GlobalState.world.changed_active_map
	GlobalState.world.move_object.call_deferred(object, area.map, area.entrance)
	
	var map_x = int(area.map.split("_")[0])
	var map_y = int(area.map.split("_")[1])
	object.change_map_coordinates(Vector2(map_x, map_y))
	object.set_process(true)
