extends Node2D

class_name ComponentContainer

@export var object: BaseObject2D
@export var body: BaseObjectBody2D

var component_names = {}
var component_types = {}

var flip_components = []
var rotate_components = []

var is_setup = false

func _ready():
	if object.auto_setup_components:
		setup()

func _physics_process(delta):
	apply_body_rotation()

func setup():
	cleanup()
	for child in get_children():
		if child is BaseComponent:
			add(child)
	is_setup = true

func cleanup():
	for cname in component_names:
		if !is_instance_valid(component_names[cname]):
			component_names.erase(cname)

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

func add(component: BaseComponent, deferred=true):
	component_names[component.name] = component

	if !component_types.has(component.script):
		component_types[component.script] = [component]
	else:
		component_types[component.script].append(component)

	component.object = object
	component.body = body
	component.container = self
	if deferred:
		if component.get_parent() != self:
			if component.get_parent():
				component.get_parent().remove_child.call_deferred(component)
			add_child.call_deferred(component)
		component.setup.call_deferred()
	else:
		if component.get_parent() != self:
			if component.get_parent():
				component.get_parent().remove_child(component)
			add_child(component)
		component.setup()
	cleanup()

func remove(component):
	if component is BaseComponent:
		if component.get_parent() == self:
			component_names.erase(component.name)
			component_types.erase(component.name)
			component.queue_free()
			if component.apply_flip:
				flip_components.erase(component)
			if component.follow_body_rotation:
				rotate_components.erase(component)
			
	elif component is String:
		if component in component_names:
			remove(component_names[component])
		else:
			print("tried to remove nonexistent component %s from object %s, ignoring." % [component, object])
	cleanup()

func set_flip(dir):
	for component in flip_components:
		component.scale.x = dir

func apply_body_rotation():
	for component in rotate_components:
		component.rotation = body.rotation
