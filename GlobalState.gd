extends Node

var player:
	get:
		return get_tree().get_first_node_in_group("Player")
