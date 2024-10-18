extends Node2D

class_name World

signal changed_active_map(old, new)
signal started_map_transition(old, new)

@onready var active_map_node = $ActiveMap
@onready var inactive_map_node = $InactiveMaps
@onready var transition_screen = %TransitionScreen
@onready var player_object = $PlayerObject

var active_map: BaseMap:
	get:
		return active_map_node.get_child(0)

var maps = {}

var transitioning := false

func _ready() -> void:
	var maps = active_map_node.get_children() + inactive_map_node.get_children()
	for map in maps:
		if map is BaseMap:
			add_map(map)
	finalize_init.call_deferred()
	spawn_player.call_deferred()

func finalize_init():
	active_map.show()

func add_map(map: BaseMap) -> void:
	if !map.is_inside_tree():
		if active_map_node.get_child_count() == 0:
			active_map_node.add_child(map)
		else:
			inactive_map_node.add_child(map)
	self.maps[map.name] = map

func remove_map(map: String):
	if map in maps:
		var instance: BaseMap = maps[map]
		maps.erase(map)
		instance.queue_free()

func spawn_player() -> void:
	if player_object.get_parent() != active_map and player_object.get_parent():
		player_object.get_parent().remove_child(player_object)
	active_map.add_child(player_object)
	player_object.xy = active_map.player_start.global_position
	#if player_object:
		#player_object.get_component(CameraComponent).on_entered_map()

func activate_map(map: String) -> void:
	if map in maps:

		var new_map = maps[map]
		var old_map = active_map
		if new_map != old_map:
			new_map.get_parent().remove_child(new_map)
			active_map_node.add_child(new_map)
			if old_map:
				old_map.get_parent().remove_child(old_map)
				inactive_map_node.add_child(old_map)
			changed_active_map.emit(old_map, new_map)
	active_map.on_player_entered()


func map_transition(map: String, fade=true) -> void:
	transitioning = true
	transition_screen.color = Color("00000000")
	active_map_node.process_mode = Node.PROCESS_MODE_DISABLED
	var tween = create_tween()
	var new_map = maps[map]
	var old_map = active_map
	started_map_transition.emit(old_map, new_map)
	#tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel(false)
	tween.tween_property(transition_screen, "color", Color("000000ff" if fade else "00000000"), 0.1)
	await tween.finished

	await activate_map(map)
	await get_tree().physics_frame
	active_map_node.process_mode = Node.PROCESS_MODE_INHERIT
	
	tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(transition_screen, "color", Color("00000000"), 0.05).set_delay(0.1)
	await tween.finished
	transitioning = false

func move_object(object: BaseObject2D, map: String = "", entrance: String="") -> void:
	if map in maps:
		var map_node: BaseMap = maps[map]
		if entrance in map_node.entrances:
			object.map.remove_child(object)
			map_node.add_child(object)
			object.xy = map_node.entrances[entrance].global_position
