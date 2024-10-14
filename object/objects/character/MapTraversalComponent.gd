extends BaseComponent

class_name MapTraversalComponent

@onready var area = $Area2D


func _ready():
	area.area_entered.connect(on_area_entered)

func on_area_entered(area):
	if !(area is MapExit):
		return
	if get_component(PlayerControlComponent):
		object.world.map_transition.call_deferred(area.map)
		await object.world.changed_active_map
	object.world.move_object.call_deferred(object, area.map, area.entrance)
