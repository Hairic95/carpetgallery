extends Node2D

class_name ComponentContainer

@export var host: BaseObject2D
@export var body: BaseObjectBody2D

var component_names = {}
var component_types = {}

var is_setup = false

func _ready():
	setup()
	is_setup = true

func setup():
	for cname in component_names:
		if !is_instance_valid(component_names[cname]):
			component_names.erase(cname)
	for child in get_children():
		if child is BaseComponent:
			add(child)

func get_component(type) -> BaseComponent:
	# will get the component with the specified name if `type` is String, else
	# the first component with the matching type.
	assert(type is Script or type is String)
	if type is String:
		return component_names.get(type)
	var components = component_types.get(type)
	if components:
		return components[0]
	return null

func get_components(type: Script=null) -> Array[BaseComponent]:
	var cs: Array[BaseComponent] = []
	if type == null:
		for child in get_children():
			if child is BaseComponent:
				cs.append(type)
		return cs
	if component_types.has(type):
		for component in component_types[type]:
			cs.append(component)
	return cs

func add(component: BaseComponent):
	component_names[component.name] = component

	if !component_types.has(component.script):
		component_types[component.script] = [component]
	else:
		component_types[component.script].append(component)

	component.host = host
	component.body = body
	component.container = self
	if component.get_parent() != self:
		component.get_parent().remove_child.call_deferred(component)
		add_child.call_deferred(component)
	component.setup.call_deferred()

func set_flip(dir):
	for component in get_components():
		if component.can_apply_flip:
			component.scale.x = dir

func remove(component):
	if component is BaseComponent:
		if component.get_parent() == self:
			component_names.erase(component.name)
			component.queue_free()
	elif component is String:
		if component in component_names:
			remove(component_names[component])
		else:
			print("tried to remove nonexistent component %s from object %s, ignoring." % [component, host])
