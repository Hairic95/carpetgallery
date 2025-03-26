extends Node

var player:
	get:
		return get_tree().get_first_node_in_group("Player")

var world:
	get:
		return get_tree().get_first_node_in_group("World")

var map:
	get:
		return get_tree().get_first_node_in_group("Map")

func _exit_tree() -> void:
	Config.save_config()
