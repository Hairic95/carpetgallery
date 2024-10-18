extends Node

var player:
	get:
		return get_tree().get_first_node_in_group("Player")

func _exit_tree() -> void:
	Config.save_config()
