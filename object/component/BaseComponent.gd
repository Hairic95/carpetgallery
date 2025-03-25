extends Node2D

class_name BaseComponent

var apply_flip = true
var follow_body_rotation = false

var container: ComponentContainer

var object: NetworkBody
var body: NetworkBody

func get_component(type) -> BaseComponent:
	return container.get_component(type)

func get_components(type) -> Array[BaseComponent]:
	return container.get_components(type)

func setup():
	pass
