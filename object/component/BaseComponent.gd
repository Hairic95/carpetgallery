extends Node2D

class_name BaseComponent

var can_apply_flip = true

var container: ComponentContainer

var host: 
var body: BaseObjectBody2D

func get_component(type) -> BaseComponent:
	return container.get_component(type)

func get_components(type) -> Array[BaseComponent]:
	return container.get_components(type)

func setup():
	pass
