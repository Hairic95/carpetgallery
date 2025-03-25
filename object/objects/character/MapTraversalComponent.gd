extends BaseComponent

class_name MapTraversalComponent

signal fast_travel_initiated(coords: Vector3i)

@onready var area = $Area2D


func _ready():
	area.area_entered.connect(on_area_entered)

func on_area_entered(area):
	if !(area is MapExit):
		return
	
	GlobalState.world.map_transition.call_deferred(area.map)
	await GlobalState.world.changed_active_map
	GlobalState.world.move_object.call_deferred(object, area.map, area.entrance)
	
