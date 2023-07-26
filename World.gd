extends Node2D

class_name World

signal changed_active_map(map)

@onready var active_map_node = $ActiveMap
@onready var inactive_map_node = $InactiveMaps
@onready var transition_screen = %TransitionScreen

var active_map: BaseMap:
	get:
		return active_map_node.get_child(0)

var maps = {}

func _ready():
	var maps = active_map_node.get_children() + inactive_map_node.get_children()
	for map in maps:
		if map is BaseMap:
			self.maps[map.name] = map

func activate_map(map: String):
	if map in maps:
		var new_map = maps[map]
		var old_map = active_map
		if new_map == old_map:
			return
		new_map.get_parent().remove_child(new_map)
		old_map.get_parent().remove_child(old_map)
		active_map_node.add_child(new_map)
		inactive_map_node.add_child(old_map)
		changed_active_map.emit(new_map)

func map_transition(map: String):
	transition_screen.color = Color("00000000")
	active_map_node.process_mode = Node.PROCESS_MODE_DISABLED
	var tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(transition_screen, "color", Color("000000ff"), 0.05)
	tween.tween_callback(activate_map.bind(map)).set_delay(0.05)
	tween.tween_callback(active_map_node.set.bind("process_mode", Node.PROCESS_MODE_INHERIT))
	tween.tween_property(transition_screen, "color", Color("00000000"), 0.05).set_delay(0.05)
	await tween.finished

func move_object(object: BaseObject2D, map: String = "", entrance: String=""):
	if map in maps:
		var map_node: BaseMap = maps[map]
		if entrance in map_node.entrances:
			object.map.remove_child(object)
			map_node.add_child(object)
			object.xy = map_node.entrances[entrance].global_position
